// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <optional>
#include <utility>

#include "toolchain/base/kind_switch.h"
#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/decl_introducer_state.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/import_ref.h"
#include "toolchain/check/interface.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/merge.h"
#include "toolchain/check/modifiers.h"
#include "toolchain/check/name_component.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/return.h"
#include "toolchain/check/type.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/check/unused.h"
#include "toolchain/lex/token_kind.h"
#include "toolchain/parse/node_ids.h"
#include "toolchain/sem_ir/builtin_function_kind.h"
#include "toolchain/sem_ir/entry_point.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/pattern.h"
#include "toolchain/sem_ir/type_info.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

auto HandleParseNode(Context& context, Parse::FunctionIntroducerId node_id)
    -> bool {
  // The function is potentially generic.
  StartGenericDecl(context);
  // Create an instruction block to hold the instructions created as part of the
  // function signature, such as parameter and return types.
  context.inst_block_stack().Push();
  // Push the bracketing node.
  context.node_stack().Push(node_id);
  // Optional modifiers and the name follow.
  context.decl_introducer_state_stack().Push<Lex::TokenKind::Fn>();
  context.decl_name_stack().PushScopeAndStartName();
  return true;
}

// Handles a `->` or `->?` return declaration.
static auto HandleReturnDecl(Context& context, Parse::AnyReturnDeclId node_id)
    -> bool {
  auto [expr_node_id, expr_inst_id] = context.node_stack().PopExprWithNodeId();
  Context::FormExpr form_expr = [&]() {
    if (context.parse_tree().node_kind(node_id) == Parse::ReturnTypeId::Kind) {
      return ReturnExprAsForm(context, expr_node_id, expr_inst_id);
    } else {
      return FormExprAsForm(context, expr_node_id, expr_inst_id);
    }
  }();
  context.PushReturnForm(form_expr);
  context.node_stack().Push(node_id,
                            AddReturnPattern(context, node_id, form_expr));
  return true;
}

auto HandleParseNode(Context& context, Parse::ReturnTypeId node_id) -> bool {
  return HandleReturnDecl(context, node_id);
}

auto HandleParseNode(Context& context, Parse::ReturnFormId node_id) -> bool {
  return HandleReturnDecl(context, node_id);
}

// Diagnoses issues with the modifiers, removing modifiers that shouldn't be
// present.
static auto DiagnoseModifiers(Context& context,
                              Parse::AnyFunctionDeclId node_id,
                              DeclIntroducerState& introducer,
                              bool is_definition,
                              SemIR::NameScopeId parent_scope_id,
                              SemIR::InstId parent_scope_inst_id,
                              std::optional<SemIR::Inst> parent_scope_inst,
                              SemIR::InstId self_param_id) -> void {
  CheckAccessModifiersOnDecl(context, introducer, parent_scope_inst);
  LimitModifiersOnDecl(
      context, introducer,
      KeywordModifierSet::Access | KeywordModifierSet::Extern |
          KeywordModifierSet::Export | KeywordModifierSet::Method |
          KeywordModifierSet::Interface | KeywordModifierSet::Evaluation |
          KeywordModifierSet::Overload);
  RestrictExternModifierOnDecl(context, introducer, parent_scope_inst,
                               is_definition);
  CheckMethodModifiersOnFunction(context, introducer, parent_scope_inst_id,
                                 parent_scope_inst);
  RequireDefaultFinalOnlyInInterfaces(context, introducer, parent_scope_id,
                                      is_definition);
  // TODO: add check that functions in interfaces may only be defined if they
  // are marked `default` or `final`.

  if (!self_param_id.has_value() &&
      introducer.modifier_set.HasAnyOf(KeywordModifierSet::Method)) {
    CARBON_DIAGNOSTIC(VirtualWithoutSelf, Error, "virtual class function");
    context.emitter().Emit(node_id, VirtualWithoutSelf);
    introducer.modifier_set.Remove(KeywordModifierSet::Method);
  }
}

// Returns the virtual-family modifier as an enum.
static auto GetVirtualModifier(const KeywordModifierSet& modifier_set)
    -> SemIR::Function::VirtualModifier {
  return modifier_set.ToEnum<SemIR::Function::VirtualModifier>()
      .Case(KeywordModifierSet::Virtual,
            SemIR::Function::VirtualModifier::Virtual)
      .Case(KeywordModifierSet::Abstract,
            SemIR::Function::VirtualModifier::Abstract)
      .Case(KeywordModifierSet::Override,
            SemIR::Function::VirtualModifier::Override)
      .Default(SemIR::Function::VirtualModifier::None);
}

// Returns the evaluation modifier as an enum.
static auto GetEvaluationMode(const KeywordModifierSet& modifier_set)
    -> SemIR::Function::EvaluationMode {
  return modifier_set.ToEnum<SemIR::Function::EvaluationMode>()
      .Case(KeywordModifierSet::Eval, SemIR::Function::EvaluationMode::Eval)
      .Case(KeywordModifierSet::MustEval,
            SemIR::Function::EvaluationMode::MustEval)
      .Default(SemIR::Function::EvaluationMode::None);
}

// Returns the implementation modifier as an enum.
static auto GetInterfaceModifier(const KeywordModifierSet& modifier_set)
    -> SemIR::Function::InterfaceModifier {
  using enum SemIR::Function::InterfaceModifier;
  return modifier_set.ToEnum<SemIR::Function::InterfaceModifier>()
      .Case(KeywordModifierSet::Default, Default)
      .Case(KeywordModifierSet::Final, Final)
      .Default(None);
}

// Tries to merge new_function into prev_function_id. Since new_function won't
// have a definition even if one is upcoming, set is_definition to indicate the
// planned result.
//
// When the previous declaration was imported, `replace_prev_inst` says whether
// the name's scope entry is replaced by the new declaration. That is the rule
// for a plain function; a member of an `overload fn` set is reached through
// the set value, never through the name, so the entry stays the set value.
//
// If merging is successful, returns true and may update the previous function.
// Otherwise, returns false. Prints a diagnostic when appropriate.
static auto MergeFunctionRedecl(Context& context,
                                Parse::AnyFunctionDeclId node_id,
                                SemIR::Function& new_function,
                                bool new_is_definition,
                                SemIR::FunctionId prev_function_id,
                                SemIR::ImportIRId prev_import_ir_id,
                                bool replace_prev_inst) -> bool {
  auto& prev_function = context.functions().Get(prev_function_id);

  if (!CheckFunctionTypeMatches(context, new_function, prev_function)) {
    return false;
  }

  DiagnoseIfInvalidRedecl(
      context, Lex::TokenKind::Fn, prev_function.name_id,
      RedeclInfo(new_function, node_id, new_is_definition),
      RedeclInfo(prev_function, SemIR::LocId(prev_function.latest_decl_id()),
                 prev_function.has_definition_started()),
      prev_import_ir_id);
  if (new_is_definition && prev_function.has_definition_started()) {
    return false;
  }

  if (!prev_function.first_owning_decl_id.has_value()) {
    prev_function.first_owning_decl_id = new_function.first_owning_decl_id;
  }
  if (new_is_definition) {
    // Track the signature from the definition, so that IDs in the body
    // match IDs in the signature.
    prev_function.MergeDefinition(new_function);
  }
  if (replace_prev_inst && prev_import_ir_id.has_value()) {
    ReplacePrevInstForMerge(context, new_function.parent_scope_id,
                            prev_function.name_id,
                            new_function.first_owning_decl_id);
  }
  return true;
}

// Diagnoses a declaration of `name_id` that disagrees with a previous
// declaration on whether it carries the `overload` marker (D-OV-3: the marker
// must be on every declaration of the name or on none).
static auto DiagnoseOverloadMarkerMismatch(Context& context,
                                           Parse::AnyFunctionDeclId node_id,
                                           SemIR::NameId name_id,
                                           SemIR::LocId prev_loc_id) -> void {
  CARBON_DIAGNOSTIC(
      OverloadMarkerMismatch, Error,
      "`overload` must appear on every declaration of `{0}` or on none",
      SemIR::NameId);
  CARBON_DIAGNOSTIC(OverloadMarkerPrevious, Note,
                    "previous declaration of `{0}` here", SemIR::NameId);
  context.emitter()
      .Build(node_id, OverloadMarkerMismatch, name_id)
      .Note(prev_loc_id, OverloadMarkerPrevious, name_id)
      .Emit();
}

// Handles a function declaration whose name resolves to an `overload fn` set
// (D-OV-3). Member identity is parameter-type equality: the first type-equal
// member is the one being redeclared and is merged into through the ordinary
// redeclaration path. Otherwise, for a set declared in this file, the
// declaration is a new member, recorded by setting
// `function_info.overload_set_id` (the caller appends the declaration once the
// function exists); for a set reached through an import
// (`prev_import_ir_id` has a value: the API file seen from its implementation
// file, or an importing library), the set is closed and the declaration is
// diagnosed (fork/overload/plan.md §1.B.2: implementation files may only
// define members, and no library may add to another's set).
static auto TryMergeIntoOverloadSet(
    Context& context, Parse::AnyFunctionDeclId node_id,
    const DeclNameStack::NameContext& name_context, bool is_overload,
    SemIR::OverloadSetId overload_set_id, SemIR::FunctionDecl& function_decl,
    SemIR::Function& function_info, bool is_definition,
    SemIR::ImportIRId prev_import_ir_id) -> void {
  const auto& overload_set = context.overload_sets().Get(overload_set_id);
  CARBON_CHECK(!overload_set.member_decl_ids.empty());
  auto first_member_decl_id = overload_set.member_decl_ids.front();

  if (!is_overload) {
    // Diagnose once, then recover as if the marker were present so that a
    // definition still merges into its member and calls still resolve.
    DiagnoseOverloadMarkerMismatch(context, node_id, name_context.name_id,
                                   SemIR::LocId(first_member_decl_id));
  }

  DeclParams new_params(function_info);
  for (auto member_decl_id : overload_set.member_decl_ids) {
    auto member_function_id =
        context.insts().GetAs<SemIR::FunctionDecl>(member_decl_id).function_id;
    const auto& member_function = context.functions().Get(member_function_id);
    if (!CheckRedeclParamsMatch(context, new_params,
                                DeclParams(member_function),
                                SemIR::SpecificId::None, /*diagnose=*/false,
                                /*check_syntax=*/false)) {
      continue;
    }
    // This is a redeclaration of `member_function`. The ordinary path
    // diagnoses differing binding names, return types, and redefinitions, and
    // for an imported member applies the api/impl and cross-library rules
    // (incl. the `extern` ownership rules, §1.B.3). The name's scope entry is
    // never replaced: the member is reached through the set.
    if (MergeFunctionRedecl(context, node_id, function_info, is_definition,
                            member_function_id, prev_import_ir_id,
                            /*replace_prev_inst=*/false)) {
      function_decl.function_id = member_function_id;
      function_decl.type_id = context.insts().Get(member_decl_id).type_id();
    }
    return;
  }

  if (prev_import_ir_id.has_value()) {
    // No type-equal member of an imported set: the set is closed. The
    // declaration continues as a plain function that is not added to name
    // lookup, so nothing cascades.
    CARBON_DIAGNOSTIC(OverloadSetFrozen, Error,
                      "overload set `{0}` is closed; new members may only be "
                      "declared in the API file of its library",
                      SemIR::NameId);
    CARBON_DIAGNOSTIC(OverloadSetDeclaredHere, Note,
                      "overload set declared here");
    context.emitter()
        .Build(node_id, OverloadSetFrozen, name_context.name_id)
        .Note(SemIR::LocId(first_member_decl_id), OverloadSetDeclaredHere)
        .Emit();
    return;
  }

  // No type-equal member: this declaration is a new member.
  const auto& first_member_function = context.functions().Get(
      context.insts()
          .GetAs<SemIR::FunctionDecl>(first_member_decl_id)
          .function_id);
  if (function_info.self_param_id.has_value() !=
      first_member_function.self_param_id.has_value()) {
    // D-OV-6 gate (x).
    context.TODO(node_id, "`overload fn` members that disagree on `self`");
  } else if (function_info.self_param_id.has_value()) {
    // D-OV-3: members distinguished only by their `self` pattern (`self` vs
    // `ref self`) are not supported; the explicit parameters after `self`
    // decide.
    for (auto member_decl_id : overload_set.member_decl_ids) {
      const auto& member_function = context.functions().Get(
          context.insts()
              .GetAs<SemIR::FunctionDecl>(member_decl_id)
              .function_id);
      if (CheckRedeclExplicitParamsAfterSelfMatch(
              context, new_params, DeclParams(member_function))) {
        context.TODO(node_id,
                     "`overload fn` members distinguished only by `self`");
        break;
      }
    }
  }
  function_info.overload_set_id = overload_set_id;
  // The caller appends the declaration once the function exists (D-OV-3), so
  // the new member's index is the current size.
  function_info.overload_index =
      static_cast<int32_t>(overload_set.member_decl_ids.size());
}

// Check whether this is a redeclaration, merging if needed.
static auto TryMergeRedecl(Context& context, Parse::AnyFunctionDeclId node_id,
                           const DeclNameStack::NameContext& name_context,
                           bool is_overload, SemIR::FunctionDecl& function_decl,
                           SemIR::Function& function_info, bool is_definition)
    -> void {
  // Diagnose if we are declaring a poisoned name. However, don't diagnose at
  // impl scope: if the name was referenced before being declared, we will have
  // produced an error already.
  if (name_context.state == DeclNameStack::NameContext::State::Poisoned) {
    if (!context.name_scopes().InstIs<SemIR::ImplDecl>(
            name_context.parent_scope_id)) {
      DiagnosePoisonedName(context, name_context.name_id_for_new_inst(),
                           name_context.poisoning_loc_id, name_context.loc_id);
    }
    return;
  }

  auto prev_id = name_context.prev_inst_id();
  if (!prev_id.has_value()) {
    return;
  }

  // A previous declaration that is an `overload fn` set declared in this file.
  if (auto overload_set_value =
          context.insts().TryGetAs<SemIR::OverloadSetValue>(prev_id)) {
    TryMergeIntoOverloadSet(context, node_id, name_context, is_overload,
                            overload_set_value->overload_set_id, function_decl,
                            function_info, is_definition,
                            SemIR::ImportIRId::None);
    return;
  }

  auto prev_function_id = SemIR::FunctionId::None;
  auto prev_type_id = SemIR::TypeId::None;
  auto prev_import_ir_id = SemIR::ImportIRId::None;
  CARBON_KIND_SWITCH(context.insts().Get(prev_id)) {
    case CARBON_KIND(SemIR::AssociatedEntity assoc_entity): {
      // This is a function in an interface definition scope.
      auto function_decl =
          context.insts().GetAs<SemIR::FunctionDecl>(assoc_entity.decl_id);
      prev_function_id = function_decl.function_id;
      prev_type_id = function_decl.type_id;
      break;
    }
    case CARBON_KIND(SemIR::FunctionDecl function_decl): {
      prev_function_id = function_decl.function_id;
      prev_type_id = function_decl.type_id;
      break;
    }
    case SemIR::ImportRefLoaded::Kind: {
      auto import_ir_inst = GetCanonicalImportIRInst(context, prev_id);
      const auto* import_ir =
          context.import_irs().Get(import_ir_inst.ir_id()).sem_ir;

      // An `overload fn` set reached through an import (not through an
      // alias, which is a name conflict like any other): the import resolver
      // localized it whole, so its constant is the local set value (§1.B.2).
      if (import_ir->insts().Is<SemIR::OverloadSetValue>(
              import_ir_inst.inst_id())) {
        auto const_inst_id =
            context.constant_values().GetConstantInstId(prev_id);
        if (auto overload_set_value =
                const_inst_id.has_value()
                    ? context.insts().TryGetAs<SemIR::OverloadSetValue>(
                          const_inst_id)
                    : std::nullopt) {
          TryMergeIntoOverloadSet(context, node_id, name_context, is_overload,
                                  overload_set_value->overload_set_id,
                                  function_decl, function_info, is_definition,
                                  import_ir_inst.ir_id());
          return;
        }
        break;
      }

      // Verify the decl so that things like aliases are name conflicts.
      if (!import_ir->insts().Is<SemIR::FunctionDecl>(
              import_ir_inst.inst_id())) {
        break;
      }

      // Use the type to get the ID.
      if (auto struct_value = context.insts().TryGetAs<SemIR::StructValue>(
              context.constant_values().GetConstantInstId(prev_id))) {
        if (auto function_type = context.types().TryGetAs<SemIR::FunctionType>(
                struct_value->type_id)) {
          prev_function_id = function_type->function_id;
          prev_type_id = struct_value->type_id;
          prev_import_ir_id = import_ir_inst.ir_id();
        }
      }
      break;
    }
    default:
      break;
  }

  if (!prev_function_id.has_value()) {
    DiagnoseDuplicateName(context, name_context.name_id, name_context.loc_id,
                          SemIR::LocId(prev_id));
    return;
  }

  if (is_overload) {
    // D-OV-3: a marked declaration against a plain function. Diagnose and do
    // not merge; the declaration gets its own function and is not added to
    // name lookup, so no redeclaration diagnostics are emitted on top.
    DiagnoseOverloadMarkerMismatch(context, node_id, name_context.name_id,
                                   SemIR::LocId(prev_id));
    return;
  }

  if (MergeFunctionRedecl(context, node_id, function_info, is_definition,
                          prev_function_id, prev_import_ir_id,
                          /*replace_prev_inst=*/true)) {
    // When merging, use the existing function rather than adding a new one.
    function_decl.function_id = prev_function_id;
    function_decl.type_id = prev_type_id;
  }
}

// Adds the declaration to name lookup when appropriate.
static auto MaybeAddToNameLookup(Context& context,
                                 const DeclNameStack::NameContext& name_context,
                                 const KeywordModifierSet& modifier_set,
                                 SemIR::NameScopeId parent_scope_id,
                                 SemIR::InstId decl_id) -> void {
  if (name_context.state != DeclNameStack::NameContext::State::Poisoned &&
      name_context.prev_inst_id().has_value()) {
    return;
  }

  // At interface scope, a function declaration introduces an associated
  // function.
  auto lookup_result_id = decl_id;
  if (parent_scope_id.has_value() && !name_context.has_qualifiers) {
    if (auto interface_decl =
            context.name_scopes().TryGetInstAs<SemIR::InterfaceWithSelfDecl>(
                parent_scope_id)) {
      lookup_result_id =
          BuildAssociatedEntity(context, interface_decl->interface_id, decl_id);
    }
  }

  context.decl_name_stack().AddName(name_context, lookup_result_id,
                                    modifier_set.GetAccessKind());
}

// Returns whether the given type is `i32`.
static auto IsI32(Context& context, Parse::NodeId node_id,
                  SemIR::TypeId type_id) -> bool {
  return type_id == MakeIntType(context, node_id, SemIR::IntKind::Signed,
                                context.ints().Add(32));
}

// Returns whether the given parameter list is valid for the entry point
// function `Main.Run`.
static auto IsValidEntryPointParamList(Context& context, Parse::NodeId node_id,
                                       SemIR::InstBlockId param_patterns_id)
    -> bool {
  if (!param_patterns_id.has_value()) {
    // Positional parameters for are not supported.
    return false;
  }

  for (auto [index, param_pattern_id] :
       llvm::enumerate(context.inst_blocks().Get(param_patterns_id))) {
    if (param_pattern_id == SemIR::ErrorInst::InstId) {
      // Ignore erroneous parameters.
      continue;
    }

    // Validate that this is a by-value parameter, which is represented as an
    // WrapperBindingPattern wrapping a ValueParamPattern.
    auto type_id = SemIR::TypeId::None;
    if (auto binding = context.insts().TryGetAs<SemIR::WrapperBindingPattern>(
            param_pattern_id)) {
      if (auto param_pattern =
              context.insts().TryGetAs<SemIR::ValueParamPattern>(
                  binding->subpattern_id)) {
        type_id = param_pattern->type_id;
      }
    }
    if (!type_id.has_value()) {
      return false;
    }

    if (type_id == SemIR::ErrorInst::TypeId) {
      // Ignore parameters with erroneous types.
      continue;
    }

    auto param_type_inst_id = context.types()
                                  .GetAs<SemIR::PatternType>(type_id)
                                  .scrutinee_type_inst_id;
    switch (index) {
      case 0: {
        // `argc` should be a 32-bit integer.
        if (!IsI32(
                context, node_id,
                context.types().GetTypeIdForTypeInstId(param_type_inst_id))) {
          return false;
        }
        break;
      }
      case 1: {
        // `argv` should be a pointer.
        // TODO: Consider checking the pointee type also.
        if (!context.insts().Is<SemIR::PointerType>(param_type_inst_id)) {
          return false;
        }
        break;
      }
      default: {
        // TODO: Decide whether to allow a third `envp` parameter.
        return false;
      }
    }
  }

  return true;
}

// Returns whether the given type is a `Core.Result(T, E)` specific whose
// success type `T` is exactly `()` or `i32` — the two `Result` entry-point
// shapes of decision D10 (docs/design/error_handling.md, "Entry point"); `E`
// is unconstrained. `T` is matched by `TypeId` equality like the plain
// `-> i32` shape, so an adapter over `i32` is rejected in both positions
// alike. Lowering gives such a `Run` the C ABI `i32 main()` and derives the
// exit code from the returned alternative (toolchain/lower/handle.cpp).
static auto IsEntryPointResultReturnType(Context& context,
                                         Parse::NodeId node_id,
                                         SemIR::TypeId return_type_id) -> bool {
  auto class_type = context.types().TryGetAs<SemIR::ClassType>(return_type_id);
  if (!class_type) {
    return false;
  }
  auto type_info =
      SemIR::RecognizedTypeInfo::ForType(context.sem_ir(), *class_type);
  if (type_info.kind != SemIR::RecognizedTypeInfo::Result) {
    return false;
  }
  auto args = context.inst_blocks().GetOrEmpty(type_info.args_id);
  if (args.size() != 2) {
    return false;
  }
  auto success_inst_id = args[0];
  if (auto facet =
          context.insts().TryGetAs<SemIR::FacetValue>(success_inst_id)) {
    success_inst_id = facet->type_inst_id;
  }
  auto success_type_id =
      context.types().GetTypeIdForTypeInstId(success_inst_id);
  return success_type_id == GetTupleType(context, {}) ||
         IsI32(context, node_id, success_type_id);
}

// Returns whether the given return type is valid for the entry point
// function `Main.Run`.
static auto IsValidEntryPointReturnType(Context& context, Parse::NodeId node_id,
                                        SemIR::TypeId return_type_id) -> bool {
  // An implicit or explicit return type of `()` is OK.
  // TODO: Translate this to returning an `i32` with value `0` in lowering.
  if (!return_type_id.has_value()) {
    return true;
  }
  if (return_type_id == GetTupleType(context, {})) {
    return true;
  }

  if (IsI32(context, node_id, return_type_id)) {
    // Explicit return type of `i32` or an adapter for it is OK.
    return true;
  }

  // `Core.Result((), E)` and `Core.Result(i32, E)` are OK (D10).
  if (IsEntryPointResultReturnType(context, node_id, return_type_id)) {
    return true;
  }

  // For now, disallow anything else.
  // TODO: Decide on valid return types for `Main.Run`. Perhaps we should
  // have an interface for this.
  return false;
}

// If the function is the entry point, do corresponding validation.
static auto ValidateForEntryPoint(Context& context,
                                  Parse::AnyFunctionDeclId node_id,
                                  SemIR::FunctionId function_id,
                                  const SemIR::Function& function_info)
    -> void {
  if (!SemIR::IsEntryPoint(context.sem_ir(), function_id)) {
    return;
  }

  // TODO: Update this once valid signatures for the entry point are decided.
  // See https://github.com/carbon-language/carbon-lang/issues/6735
  if (function_info.implicit_param_patterns_id.has_value() ||
      !IsValidEntryPointParamList(context, node_id,
                                  function_info.param_patterns_id)) {
    CARBON_DIAGNOSTIC(InvalidMainRunParameters, Error,
                      "invalid parameters for `Main.Run` function; expected "
                      "`()` or `(argc: i32, argv: Core.Optional(char*)*)`");
    context.emitter().Emit(node_id, InvalidMainRunParameters);
  } else if (!IsValidEntryPointReturnType(
                 context, node_id,
                 function_info.GetDeclaredReturnType(context.sem_ir()))) {
    CARBON_DIAGNOSTIC(InvalidMainRunReturnType, Error,
                      "invalid return type for `Main.Run` function; expected "
                      "`fn (...)`, `fn (...) -> i32`, "
                      "`fn (...) -> Core.Result((), E)`, or "
                      "`fn (...) -> Core.Result(i32, E)`");
    context.emitter().Emit(node_id, InvalidMainRunReturnType);
  }
}

static auto IsGenericFunction(Context& context,
                              SemIR::GenericId function_generic_id,
                              SemIR::GenericId class_generic_id) -> bool {
  if (function_generic_id == SemIR::GenericId::None) {
    return false;
  }

  if (class_generic_id == SemIR::GenericId::None) {
    return true;
  }

  const auto& function_generic = context.generics().Get(function_generic_id);
  const auto& class_generic = context.generics().Get(class_generic_id);

  auto function_bindings =
      context.inst_blocks().Get(function_generic.bindings_id);
  auto class_bindings = context.inst_blocks().Get(class_generic.bindings_id);

  // If the function's bindings are the same size as the class's bindings,
  // then there are no extra bindings for the function, so it is effectively
  // non-generic within the scope of a specific of the class.
  return class_bindings.size() != function_bindings.size();
}

// Requests a vtable be created when processing a virtual function.
static auto RequestVtableIfVirtual(
    Context& context, Parse::AnyFunctionDeclId node_id,
    SemIR::Function::VirtualModifier& virtual_modifier,
    const std::optional<SemIR::Inst>& parent_scope_inst, SemIR::InstId decl_id,
    SemIR::GenericId generic_id) -> void {
  // In order to request a vtable, the function must be virtual, and in a class
  // scope.
  if (virtual_modifier == SemIR::Function::VirtualModifier::None ||
      !parent_scope_inst) {
    return;
  }
  auto class_decl = parent_scope_inst->TryAs<SemIR::ClassDecl>();
  if (!class_decl) {
    return;
  }

  auto& class_info = context.classes().Get(class_decl->class_id);
  if (virtual_modifier == SemIR::Function::VirtualModifier::Override &&
      !class_info.base_id.has_value()) {
    CARBON_DIAGNOSTIC(OverrideWithoutBase, Error,
                      "override without base class");
    context.emitter().Emit(node_id, OverrideWithoutBase);
    virtual_modifier = SemIR::Function::VirtualModifier::None;
    return;
  }

  if (IsGenericFunction(context, generic_id, class_info.generic_id)) {
    CARBON_DIAGNOSTIC(GenericVirtual, Error, "generic virtual function");
    context.emitter().Emit(node_id, GenericVirtual);
    virtual_modifier = SemIR::Function::VirtualModifier::None;
    return;
  }

  // TODO: If this is an `impl` function, check there's a matching base
  // function that's impl or virtual.
  class_info.is_dynamic = true;
  context.vtable_stack().AddInstId(decl_id);
}

// Diagnoses when positional params aren't supported. Reassigns the pattern
// block if needed.
static auto DiagnosePositionalParams(Context& context,
                                     SemIR::Function& function_info) -> void {
  if (function_info.param_patterns_id.has_value()) {
    return;
  }

  context.TODO(function_info.latest_decl_id(),
               "function with positional parameters");
  function_info.param_patterns_id = SemIR::InstBlockId::Empty;
}

// D-OV-6 gates (ix) and (xiii): returns whether `parent_scope_id` is an
// interface or an `impl` body, where an `overload fn` set is not supported in
// 0.1, diagnosing the gate if so.
static auto DiagnoseOverloadInInterfaceOrImpl(
    Context& context, Parse::AnyFunctionDeclId node_id,
    SemIR::NameScopeId parent_scope_id) -> bool {
  if (context.name_scopes().InstIs<SemIR::InterfaceWithSelfDecl>(
          parent_scope_id)) {
    context.TODO(node_id, "`overload fn` in an interface");
    return true;
  }
  if (context.name_scopes().InstIs<SemIR::ImplDecl>(parent_scope_id)) {
    context.TODO(node_id, "`overload fn` in an `impl` body");
    return true;
  }
  return false;
}

// Diagnoses the 0.1 restrictions on `overload fn` members (D-OV-6 gates
// (i)-(vi)) as semantics TODOs at the declaration, so that overload resolution
// only ever sees supported members. The declaration is still a member.
static auto DiagnoseOverloadGates(
    Context& context, Parse::AnyFunctionDeclId node_id,
    const KeywordModifierSet& modifier_set,
    const DeclNameStack::NameContext& name_context,
    SemIR::FunctionId function_id) -> void {
  const auto& function = context.functions().Get(function_id);
  // (ii) Sets declared inside a generic scope (lifted at OV-2). A member
  // function of a generic class has its own `generic_id`, so this takes
  // precedence over (i) to diagnose once.
  if (context.scope_stack().PeekSpecificId().has_value()) {
    context.TODO(node_id, "`overload fn` in a generic scope");
  } else if (function.generic_id.has_value()) {
    // (i) Generic members (lifted at OV-2).
    context.TODO(node_id, "`overload fn` with generic parameters");
  }
  // (iii) Explicit parameters after `self` must be by-value binding patterns:
  // the resolution probe is a value conversion, so `ref` and `var` members
  // would be accepted by the probe and rejected by the commit. This also gates
  // destructuring tuple and struct parameter patterns, whose leaf is not a
  // single `ValueParamPattern`.
  for (auto param_pattern_id :
       context.inst_blocks().GetOrEmpty(function.param_patterns_id)) {
    if (param_pattern_id == function.self_param_id ||
        param_pattern_id == SemIR::ErrorInst::InstId) {
      continue;
    }
    bool is_value_param = false;
    if (auto binding = context.insts().TryGetAs<SemIR::WrapperBindingPattern>(
            param_pattern_id)) {
      is_value_param =
          context.insts().Is<SemIR::ValueParamPattern>(binding->subpattern_id);
    }
    if (!is_value_param) {
      context.TODO(param_pattern_id,
                   "`overload fn` with a non-value explicit parameter");
      break;
    }
  }
  // (iv) `extern` members belong to another library's set (OV-2).
  if (modifier_set.HasAnyOf(KeywordModifierSet::Extern)) {
    context.TODO(node_id, "`extern overload fn`");
  }
  // (v) The entry point mangles to `main`, so every member would alias it.
  if (SemIR::IsEntryPoint(context.sem_ir(), function_id)) {
    context.TODO(node_id, "`overload` on the entry point");
  }
  // (vi) Every member shares the set's name-scope entry, so the access kind
  // is fixed by the first member. Block scopes have no entry.
  if (name_context.parent_scope_id.has_value()) {
    const auto& name_scope =
        context.name_scopes().Get(name_context.parent_scope_id);
    if (auto entry_id = name_scope.Lookup(name_context.name_id)) {
      if (name_scope.GetEntry(*entry_id).result.access_kind() !=
          modifier_set.GetAccessKind()) {
        context.TODO(node_id, "`overload fn` members with differing access");
      }
    }
  }
}

// Build a FunctionDecl describing the signature of a function. This
// handles the common logic shared by function declaration syntax and function
// definition syntax.
static auto BuildFunctionDecl(Context& context,
                              Parse::AnyFunctionDeclId node_id,
                              bool is_definition)
    -> std::pair<SemIR::FunctionId, SemIR::InstId> {
  auto return_pattern_id = SemIR::InstId::None;
  auto return_type_inst_id = SemIR::TypeInstId::None;
  auto return_form_inst_id = SemIR::InstId::None;
  if (auto [return_node, maybe_return_pattern_id] =
          context.node_stack()
              .PopWithNodeIdIf<Parse::NodeCategory::ReturnDecl>();
      maybe_return_pattern_id) {
    return_pattern_id = *maybe_return_pattern_id;
    auto return_form = context.PopReturnForm();
    return_type_inst_id = return_form.type_component_inst_id;
    return_form_inst_id = return_form.form_inst_id;
  }

  auto name = PopNameComponent(context, return_pattern_id);
  auto name_context = context.decl_name_stack().FinishName(name);

  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::FunctionIntroducer>();

  auto self_param_id = FindSelfPattern(context, name.implicit_param_patterns_id,
                                       name.param_patterns_id);

  // `self` must be the first explicit parameter. (Declaring it in the implicit
  // parameter list or outside any parameter list is diagnosed earlier.)
  if (self_param_id.has_value()) {
    auto explicit_params =
        context.inst_blocks().GetOrEmpty(name.param_patterns_id);
    if (!explicit_params.empty() && explicit_params.front() != self_param_id &&
        llvm::is_contained(explicit_params, self_param_id)) {
      CARBON_DIAGNOSTIC(SelfNotFirstParam, Error,
                        "`self` must be the first explicit parameter");
      context.emitter().Emit(SemIR::LocId(self_param_id), SelfNotFirstParam);
    }
  }

  // Process modifiers.
  auto [parent_scope_inst_id, parent_scope_inst] =
      context.name_scopes().GetInstIfValid(name_context.parent_scope_id);
  auto introducer =
      context.decl_introducer_state_stack().Pop<Lex::TokenKind::Fn>();
  DiagnoseModifiers(context, node_id, introducer, is_definition,
                    name_context.parent_scope_id, parent_scope_inst_id,
                    parent_scope_inst, self_param_id);
  bool is_extern = introducer.modifier_set.HasAnyOf(KeywordModifierSet::Extern);
  bool is_overload =
      introducer.modifier_set.HasAnyOf(KeywordModifierSet::Overload);
  auto virtual_modifier = GetVirtualModifier(introducer.modifier_set);
  auto evaluation_mode = GetEvaluationMode(introducer.modifier_set);
  auto interface_modifier = GetInterfaceModifier(introducer.modifier_set);

  // Add the function declaration.
  SemIR::FunctionDecl function_decl = {SemIR::TypeId::None,
                                       SemIR::FunctionId::None,
                                       context.inst_block_stack().Pop()};
  auto decl_id = AddPlaceholderInst(context, node_id, function_decl);

  // Build the function entity. This will be merged into an existing function if
  // there is one, or otherwise added to the function store.
  auto function_info =
      SemIR::Function{name_context.MakeEntityWithParamsBase(
                          name, decl_id, is_extern, introducer.extern_library),
                      {.call_param_patterns_id = name.call_param_patterns_id,
                       .call_params_id = name.call_params_id,
                       .call_param_ranges = name.param_ranges,
                       .return_type_inst_id = return_type_inst_id,
                       .return_form_inst_id = return_form_inst_id,
                       .return_pattern_id = return_pattern_id,
                       .virtual_modifier = virtual_modifier,
                       .evaluation_mode = evaluation_mode,
                       .interface_modifier = interface_modifier,
                       .self_param_id = self_param_id}};
  if (is_definition) {
    function_info.definition_id = decl_id;
  }

  DiagnosePositionalParams(context, function_info);

  // D-OV-6 gates (ix) and (xiii): a marked declaration directly in an
  // interface or `impl` body. The marker is diagnosed and then ignored, so the
  // declaration is checked as a plain function.
  if (is_overload && DiagnoseOverloadInInterfaceOrImpl(
                         context, node_id, name_context.parent_scope_id)) {
    is_overload = false;
  }

  TryMergeRedecl(context, node_id, name_context, is_overload, function_decl,
                 function_info, is_definition);

  // Create a new function if this isn't a valid redeclaration.
  if (!function_decl.function_id.has_value()) {
    if (function_info.is_extern && context.sem_ir().is_impl()) {
      DiagnoseExternRequiresDeclInApiFile(context, node_id);
    }
    function_info.generic_id = BuildGenericDecl(context, decl_id);
    function_decl.function_id = context.functions().Add(function_info);
    function_decl.type_id =
        GetFunctionType(context, function_decl.function_id,
                        context.scope_stack().PeekSpecificId());
    if (function_info.overload_set_id.has_value()) {
      // A new member of an existing set (D-OV-3).
      context.overload_sets()
          .Get(function_info.overload_set_id)
          .member_decl_ids.push_back(decl_id);
    }
  } else {
    auto prev_decl_generic_id =
        context.functions().Get(function_decl.function_id).generic_id;
    FinishGenericRedecl(context, prev_decl_generic_id);
    // TODO: Validate that the redeclaration doesn't set an access modifier.
  }

  RequestVtableIfVirtual(context, node_id, function_info.virtual_modifier,
                         parent_scope_inst, decl_id, function_info.generic_id);

  // Write the function ID into the FunctionDecl.
  ReplaceInstBeforeConstantUse(context, decl_id, function_decl);

  // Diagnose 'definition of `abstract` function' using the canonical Function's
  // modifiers.
  if (is_definition &&
      context.functions().Get(function_decl.function_id).virtual_modifier ==
          SemIR::Function::VirtualModifier::Abstract) {
    CARBON_DIAGNOSTIC(DefinedAbstractFunction, Error,
                      "definition of `abstract` function");
    context.emitter().Emit(LocIdForDiagnostics::TokenOnly(node_id),
                           DefinedAbstractFunction);
  }

  // A first marked declaration of a name creates its `overload fn` set
  // (D-OV-2, D-OV-3). The set value is added to the current block right after
  // the member's `FunctionDecl`, and it — not the member — is the name lookup
  // result.
  auto lookup_result_id = decl_id;
  if (is_overload &&
      name_context.state != DeclNameStack::NameContext::State::Error &&
      !function_info.overload_set_id.has_value() &&
      (name_context.state == DeclNameStack::NameContext::State::Poisoned ||
       !name_context.prev_inst_id().has_value())) {
    auto overload_set_id = context.overload_sets().Add(
        {.name_id = name_context.name_id,
         .parent_scope_id = name_context.parent_scope_id,
         .member_decl_ids = {decl_id}});
    auto& first_member = context.functions().Get(function_decl.function_id);
    first_member.overload_set_id = overload_set_id;
    first_member.overload_index = 0;
    lookup_result_id = AddInst<SemIR::OverloadSetValue>(
        context, node_id,
        {.type_id = GetOverloadSetType(context, overload_set_id,
                                       context.scope_stack().PeekSpecificId()),
         .overload_set_id = overload_set_id});
  }

  // Add to name lookup if needed, now that the decl is built.
  MaybeAddToNameLookup(context, name_context, introducer.modifier_set,
                       name_context.parent_scope_id, lookup_result_id);

  if (is_overload) {
    DiagnoseOverloadGates(context, node_id, introducer.modifier_set,
                          name_context, function_decl.function_id);
  }

  ValidateForEntryPoint(context, node_id, function_decl.function_id,
                        function_info);

  if (!is_definition && context.sem_ir().is_impl() && !is_extern) {
    context.definitions_required_by_decl().push_back(decl_id);
  }

  return {function_decl.function_id, decl_id};
}

// Checks that the `unused` modifier is only used when there is a definition,
// and emits a diagnostic for every binding that is marked `unused`.
static auto CheckUnusedBindingsInPattern(Context& context,
                                         SemIR::InstId pattern_id) -> void {
  llvm::SmallVector<SemIR::InstId> work_list;
  work_list.push_back(pattern_id);

  while (!work_list.empty()) {
    auto current_id = work_list.pop_back_val();
    auto inst = context.insts().Get(current_id);
    CARBON_KIND_SWITCH(inst) {
      case CARBON_KIND_ANY(SemIR::AnyLeafParamPattern, _): {
        break;
      }
      case CARBON_KIND_ANY(SemIR::AnyBindingPattern, bind): {
        auto& entity_name = context.entity_names().Get(bind.entity_name_id);
        // We need special treatment for the name "_" which is implicitly
        // unused but actually permitted without a definition.
        if (entity_name.is_unused &&
            entity_name.name_id != SemIR::NameId::Underscore) {
          CARBON_DIAGNOSTIC(UnusedModifierWithoutDefinition, Error,
                            "`unused` modifier without a definition");
          context.emitter().Emit(current_id, UnusedModifierWithoutDefinition);
        }
        if (bind.kind == SemIR::WrapperBindingPattern::Kind) {
          work_list.push_back(bind.subpattern_id);
        }
        break;
      }
      case CARBON_KIND_ANY(SemIR::AnyVarPattern, var_pattern): {
        work_list.push_back(var_pattern.subpattern_id);
        break;
      }
      case CARBON_KIND(SemIR::TuplePattern tuple_pattern): {
        auto elements = context.inst_blocks().Get(tuple_pattern.elements_id);
        for (auto element_id : llvm::reverse(elements)) {
          work_list.push_back(element_id);
        }
        break;
      }
      default:
        break;
    }
  }
}

static auto DiagnoseUnusedMarkersWithoutDefinition(
    Context& context, SemIR::FunctionId function_id) -> void {
  const auto& function = context.functions().Get(function_id);
  // The `unused` modifier requires a definition, so it is not valid on any
  // parameter when there is none. This applies to implicit parameters (such as
  // `T: type` introduced by `[...]`) too, so check the implicit parameter list
  // as well as the explicit one.
  for (auto param_patterns_id :
       {function.implicit_param_patterns_id, function.param_patterns_id}) {
    if (param_patterns_id.has_value()) {
      for (auto pattern_id : context.inst_blocks().Get(param_patterns_id)) {
        CheckUnusedBindingsInPattern(context, pattern_id);
      }
    }
  }
}

auto HandleParseNode(Context& context, Parse::FunctionDeclId node_id) -> bool {
  auto [function_id, decl_id] =
      BuildFunctionDecl(context, node_id, /*is_definition=*/false);
  DiagnoseUnusedMarkersWithoutDefinition(context, function_id);
  context.decl_name_stack().PopScope();
  return true;
}

// Processes a function definition after a signature for which we have already
// built a function ID. This logic is shared between processing regular function
// definitions and delayed parsing of inline method definitions.
static auto HandleFunctionDefinitionAfterSignature(
    Context& context, Parse::FunctionDefinitionStartId node_id,
    SemIR::FunctionId function_id, SemIR::InstId decl_id) -> void {
  StartFunctionDefinition(context, decl_id, function_id);
  context.node_stack().Push(node_id, function_id);
}

auto HandleFunctionDefinitionSuspend(Context& context,
                                     Parse::FunctionDefinitionStartId node_id)
    -> DeferredDefinitionWorklist::SuspendedFunction {
  // Process the declaration portion of the function.
  auto [function_id, decl_id] =
      BuildFunctionDecl(context, node_id, /*is_definition=*/true);
  return {.function_id = function_id,
          .decl_id = decl_id,
          .saved_name_state = context.decl_name_stack().Suspend()};
}

auto HandleFunctionDefinitionResume(
    Context& context, Parse::FunctionDefinitionStartId node_id,
    DeferredDefinitionWorklist::SuspendedFunction&& suspended_fn) -> void {
  context.decl_name_stack().Restore(std::move(suspended_fn.saved_name_state));
  HandleFunctionDefinitionAfterSignature(
      context, node_id, suspended_fn.function_id, suspended_fn.decl_id);
}

auto HandleParseNode(Context& context, Parse::FunctionDefinitionStartId node_id)
    -> bool {
  // Process the declaration portion of the function.
  auto [function_id, decl_id] =
      BuildFunctionDecl(context, node_id, /*is_definition=*/true);
  HandleFunctionDefinitionAfterSignature(context, node_id, function_id,
                                         decl_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::FunctionDefinitionId node_id)
    -> bool {
  SemIR::FunctionId function_id =
      context.node_stack().Pop<Parse::NodeKind::FunctionDefinitionStart>();

  // If the `}` of the function is reachable, reject if we need a return value
  // and otherwise add an implicit `return;`.
  if (IsCurrentPositionReachable(context)) {
    if (context.functions().Get(function_id).return_form_inst_id.has_value()) {
      CARBON_DIAGNOSTIC(
          MissingReturnStatement, Error,
          "missing `return` at end of function with declared return type");
      context.emitter().Emit(LocIdForDiagnostics::TokenOnly(node_id),
                             MissingReturnStatement);
    } else {
      AddReturnInstWithCleanups(context, node_id);
    }
  }

  FinishFunctionDefinition(context, function_id);
  context.decl_name_stack().PopScope(/*check_unused=*/true);

  return true;
}

auto HandleParseNode(Context& context,
                     Parse::BuiltinFunctionDefinitionStartId node_id) -> bool {
  // Process the declaration portion of the function.
  auto [function_id, _] =
      BuildFunctionDecl(context, node_id, /*is_definition=*/true);
  context.node_stack().Push(node_id, function_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::BuiltinNameId node_id) -> bool {
  context.node_stack().Push(node_id);
  return true;
}

// Looks up a builtin function kind given its name as a string.
// TODO: Move this out to another file.
static auto LookupBuiltinFunctionKind(Context& context,
                                      Parse::BuiltinNameId name_id)
    -> SemIR::BuiltinFunctionKind {
  auto builtin_name = context.string_literal_values().Get(
      context.tokens().GetStringLiteralValue(
          context.parse_tree().node_token(name_id)));
  auto kind = SemIR::BuiltinFunctionKind::ForBuiltinName(builtin_name);
  if (kind == SemIR::BuiltinFunctionKind::None) {
    CARBON_DIAGNOSTIC(UnknownBuiltinFunctionName, Error,
                      "unknown builtin function name \"{0}\"", std::string);
    context.emitter().Emit(name_id, UnknownBuiltinFunctionName,
                           builtin_name.str());
  }
  return kind;
}

auto HandleParseNode(Context& context,
                     Parse::BuiltinFunctionDefinitionId /*node_id*/) -> bool {
  auto name_id =
      context.node_stack().PopForSoloNodeId<Parse::NodeKind::BuiltinName>();
  auto [fn_node_id, function_id] =
      context.node_stack()
          .PopWithNodeId<Parse::NodeKind::BuiltinFunctionDefinitionStart>();

  auto builtin_kind = LookupBuiltinFunctionKind(context, name_id);
  if (builtin_kind != SemIR::BuiltinFunctionKind::None) {
    CheckFunctionDefinitionSignature(context, function_id);

    auto& function = context.functions().Get(function_id);
    if (IsValidBuiltinDeclaration(context, function, builtin_kind)) {
      function.SetBuiltinFunction(builtin_kind);
      // Build an empty generic definition if this is a generic builtin.
      StartGenericDefinition(context, function.generic_id);
      FinishGenericDefinition(context, function.generic_id);
    } else {
      CARBON_DIAGNOSTIC(InvalidBuiltinSignature, Error,
                        "invalid signature for builtin function \"{0}\"",
                        std::string);
      context.emitter().Emit(fn_node_id, InvalidBuiltinSignature,
                             builtin_kind.name().str());
    }
  }
  context.decl_name_stack().PopScope();
  return true;
}

auto HandleParseNode(Context& context, Parse::FunctionTerseDefinitionId node_id)
    -> bool {
  return context.TODO(node_id, "HandleFunctionTerseDefinition");
}

}  // namespace Carbon::Check
