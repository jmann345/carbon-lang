// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <optional>
#include <utility>

#include "llvm/ADT/STLExtras.h"
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
#include "toolchain/sem_ir/file.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/overload_set.h"
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
  Context::FormExpr form_expr = [&] {
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

// Tries to merge new_function into the `overload fn` set MEMBER
// prev_function_id. Since new_function won't have a definition even if one is
// upcoming, set is_definition to indicate the planned result.
//
// Fork (D-UA-6): this mirrors `TryMergeRedecl<SemIR::Function>`'s body
// (merge.cpp: `CheckFunctionTypeMatches` → `DiagnoseIfInvalidRedecl` →
// `MergeDefinition`) for a set member merged against a SPECIFIC member, not
// the name's prev inst. The template derives its previous entity from
// `name_context.prev_inst_id()` and its import IR from an `ImportRefLoaded`
// prev inst; a set member needs the member's own function id, the member's
// own import IR id and, for a member the API file redeclared, the API file's
// declaration facts (`prev_decl_override`) — so it is called only from
// `TryMergeIntoOverloadSet`. A plain function goes through the template.
//
// The name's scope entry is never replaced: a member of an `overload fn` set
// is reached through the set value, never through the name, so the entry stays
// the set value (the template's `ReplacePrevInstForMerge` step is absent).
//
// The redeclaration rules are applied to the previous declaration's facts:
// `prev_function`'s own, unless `prev_decl_override` carries them. A member
// of an imported `overload fn` set that the API file redeclared is localized
// here from the set's library, so whatever the API file did to it (defined it
// inline, in particular) is visible only in the API IR; the caller passes
// those facts, and the rules then see the API file's declaration, as they do
// for a plain function (fork/overload/plan.md §1.B.2-3).
//
// If merging is successful, returns true and may update the previous function.
// Otherwise, returns false. Prints a diagnostic when appropriate.
static auto MergeOverloadMemberRedecl(
    Context& context, Parse::AnyFunctionDeclId node_id,
    SemIR::Function& new_function, bool new_is_definition,
    SemIR::FunctionId prev_function_id, SemIR::ImportIRId prev_import_ir_id,
    std::optional<RedeclInfo> prev_decl_override) -> bool {
  auto& prev_function = context.functions().Get(prev_function_id);

  if (!CheckFunctionTypeMatches(context, new_function, prev_function)) {
    return false;
  }

  RedeclInfo prev_decl =
      prev_decl_override
          ? *prev_decl_override
          : RedeclInfo(prev_function,
                       SemIR::LocId(prev_function.latest_decl_id()),
                       prev_function.has_definition_started());
  DiagnoseIfInvalidRedecl(context, Lex::TokenKind::Fn, prev_function.name_id,
                          RedeclInfo(new_function, node_id, new_is_definition),
                          prev_decl, prev_import_ir_id);
  if (new_is_definition && prev_decl.is_definition) {
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

namespace {
// Where the members of an `overload fn` set reached through an import were
// previously declared, which selects the api/impl or cross-library rules of
// `DiagnoseIfInvalidRedecl` per member (fork/overload/plan.md §1.B.2-3).
struct ImportedOverloadSetSource {
  // The previous declaration of one member.
  struct Member {
    // The IR that previously declared the member.
    SemIR::ImportIRId import_ir_id;
    // When that is the API file (`ApiForImpl`) and the API file redeclared a
    // member of a set it imported: the API IR's `Function` for the member,
    // whose state is what the API file declared. Null otherwise.
    const SemIR::Function* api_function = nullptr;
  };

  // Returns the previous declaration of member `index`.
  auto GetMember(size_t index) const -> Member {
    if (api_overload_set) {
      CARBON_CHECK(index < api_overload_set->member_decl_ids.size());
      const auto& api_function = api_ir->functions().Get(
          api_ir->insts()
              .GetAs<SemIR::FunctionDecl>(
                  api_overload_set->member_decl_ids[index])
              .function_id);
      if (api_function.first_owning_decl_id.has_value()) {
        return {.import_ir_id = SemIR::ImportIRId::ApiForImpl,
                .api_function = &api_function};
      }
    }
    return {.import_ir_id = canonical_ir_id};
  }

  // The IR that declares the set: the canonical import of the set value.
  SemIR::ImportIRId canonical_ir_id;
  // In an implementation file whose API file imported the set from another
  // library: the API file's IR and its localized copy of the set, so that a
  // member the API file redeclared — an owning `extern overload fn`
  // declaration, §1.B.3 — is treated as previously declared by the API file
  // rather than by the set's library. Null otherwise.
  const SemIR::File* api_ir = nullptr;
  const SemIR::OverloadSet* api_overload_set = nullptr;
};
}  // namespace

// Returns the previous-declaration facts of a member of an imported `overload
// fn` set that the API file redeclared (an owning `extern overload fn`,
// §1.B.3), for `DiagnoseIfInvalidRedecl`'s api/impl rules: whether the API
// file defined the member, and its latest API declaration for the note. The
// member's local `Function` cannot supply them: it was localized from the
// set's library, whose declaration has no body. The API file's own
// redeclaration names no `extern library` (it is the owner), so that field is
// `None`, as for a plain function's owning declaration; the set library's
// value carried on the API `Function` lives in the API IR's string store.
static auto MakeApiMemberRedeclInfo(Context& context,
                                    const SemIR::Function& api_function)
    -> RedeclInfo {
  RedeclInfo prev_decl(
      api_function,
      SemIR::LocId(context.import_ir_insts().Add(SemIR::ImportIRInst(
          SemIR::ImportIRId::ApiForImpl, api_function.latest_decl_id()))),
      api_function.has_definition_started());
  prev_decl.extern_library_id = SemIR::LibraryNameId::None;
  return prev_decl;
}

// Returns where the members of the imported `overload fn` set named by
// `prev_id` (an `ImportRefLoaded`) were previously declared; `canonical_ir_id`
// is the IR that declares the set. In an implementation file the import ref
// comes from the API file; when the API file itself imported the set from
// another library, its own redeclarations of members are not in name lookup
// (the entry stays the set value), so they are found through the API IR's
// localized set: the member at the same index whose API `Function` has an
// owning declaration. A set the API file never loaded has no such members.
static auto GetImportedOverloadSetSource(Context& context,
                                         SemIR::InstId prev_id,
                                         SemIR::ImportIRId canonical_ir_id)
    -> ImportedOverloadSetSource {
  ImportedOverloadSetSource source = {.canonical_ir_id = canonical_ir_id};
  if (canonical_ir_id == SemIR::ImportIRId::ApiForImpl) {
    return source;
  }
  auto import_ir_inst = context.import_ir_insts().Get(
      context.insts().GetAs<SemIR::ImportRefLoaded>(prev_id).import_ir_inst_id);
  if (import_ir_inst.ir_id() != SemIR::ImportIRId::ApiForImpl) {
    return source;
  }
  const auto* api_ir =
      context.import_irs().Get(SemIR::ImportIRId::ApiForImpl).sem_ir;
  auto api_const_id = api_ir->constant_values().Get(import_ir_inst.inst_id());
  if (!api_const_id.has_value() || !api_const_id.is_constant()) {
    return source;
  }
  if (auto api_set_value = api_ir->insts().TryGetAs<SemIR::OverloadSetValue>(
          api_ir->constant_values().GetInstId(api_const_id))) {
    source.api_ir = api_ir;
    source.api_overload_set =
        &api_ir->overload_sets().Get(api_set_value->overload_set_id);
  }
  return source;
}

// Handles a function declaration whose name resolves to an `overload fn` set
// (D-OV-3). Member identity is parameter-type equality: the first type-equal
// member is the one being redeclared and is merged into through the ordinary
// redeclaration path. Otherwise, for a set declared in this file, the
// declaration is a new member, recorded by setting
// `function_info.overload_set_id` (the caller appends the declaration once the
// function exists); for a set reached through an import (`import_source` has
// a value: the API file seen from its implementation file, or an importing
// library), the set is closed and the declaration is diagnosed
// (fork/overload/plan.md §1.B.2: implementation files may only define
// members, and no library may add to another's set).
static auto TryMergeIntoOverloadSet(
    Context& context, Parse::AnyFunctionDeclId node_id,
    const DeclNameStack::NameContext& name_context, bool is_overload,
    SemIR::OverloadSetId overload_set_id, SemIR::FunctionDecl& function_decl,
    SemIR::Function& function_info, bool is_definition,
    std::optional<ImportedOverloadSetSource> import_source) -> void {
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
  for (auto [index, member_decl_id] :
       llvm::enumerate(overload_set.member_decl_ids)) {
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
    // (incl. the `extern` ownership rules, §1.B.3) according to where THIS
    // member was previously declared, to THAT declaration's facts: a member
    // the API file redeclared is judged against the API file's declaration,
    // not against the local member localized from the set's library. The
    // name's scope entry is never replaced: the member is reached through the
    // set.
    auto prev_import_ir_id = SemIR::ImportIRId::None;
    std::optional<RedeclInfo> prev_decl_override;
    if (import_source) {
      auto member_source = import_source->GetMember(index);
      prev_import_ir_id = member_source.import_ir_id;
      if (member_source.api_function) {
        prev_decl_override =
            MakeApiMemberRedeclInfo(context, *member_source.api_function);
      }
    }
    if (MergeOverloadMemberRedecl(context, node_id, function_info,
                                  is_definition, member_function_id,
                                  prev_import_ir_id, prev_decl_override)) {
      function_decl.function_id = member_function_id;
      function_decl.type_id = context.insts().Get(member_decl_id).type_id();
    }
    return;
  }

  if (import_source) {
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

// Fork (D-UA-6): the `overload fn` set half of redeclaration handling, run
// BEFORE upstream's `TryMergeRedecl<SemIR::Function>`. Returns true when this
// declaration was handled here (merged into a set member, recorded as a new
// member, or diagnosed), so the caller skips the template; false hands the
// declaration to the template unchanged. The poisoned-name check is the
// template's. In order:
//   (1) the previous inst is an `overload fn` set declared in this file;
//   (2) the previous inst is an import ref whose import-IR inst is a set —
//       the import resolver localized it whole, so its constant is the local
//       set value (fork/overload/plan.md §1.B.2), or `ErrorInst` when a
//       member could not be localized (already diagnosed: nothing is said);
//   (3) a marked declaration against a previous inst that resolves to a plain
//       FUNCTION (D-OV-3: the marker must be on every declaration or none);
//   (4) otherwise the template decides — including a previous inst that is
//       not a function at all, which it diagnoses as a duplicate name.
static auto TryMergeOverloadDecl(Context& context,
                                 Parse::AnyFunctionDeclId node_id,
                                 const DeclNameStack::NameContext& name_context,
                                 bool is_overload,
                                 SemIR::FunctionDecl& function_decl,
                                 SemIR::Function& function_info,
                                 bool is_definition) -> bool {
  // A poisoned name has no previous instruction to merge into (and
  // `prev_inst_id()` is a fatal error for it); upstream's `TryMergeRedecl`
  // diagnoses the poisoning.
  if (name_context.state == DeclNameStack::NameContext::State::Poisoned) {
    return false;
  }
  auto prev_id = name_context.prev_inst_id();
  if (!prev_id.has_value()) {
    return false;
  }

  // (1) A previous declaration that is an `overload fn` set declared in this
  // file.
  if (auto overload_set_value =
          context.insts().TryGetAs<SemIR::OverloadSetValue>(prev_id)) {
    TryMergeIntoOverloadSet(context, node_id, name_context, is_overload,
                            overload_set_value->overload_set_id, function_decl,
                            function_info, is_definition,
                            /*import_source=*/std::nullopt);
    return true;
  }

  bool prev_is_function = false;
  CARBON_KIND_SWITCH(context.insts().Get(prev_id)) {
    case SemIR::AssociatedEntity::Kind:
    case SemIR::FunctionDecl::Kind: {
      // A function, in an interface definition scope or elsewhere.
      prev_is_function = true;
      break;
    }
    case SemIR::ImportRefLoaded::Kind: {
      auto import_ir_inst = GetCanonicalImportIRInst(context, prev_id);
      const auto* import_ir =
          context.import_irs().Get(import_ir_inst.ir_id()).sem_ir;

      // (2) An `overload fn` set reached through an import (not through an
      // alias, which is a name conflict like any other).
      if (import_ir->insts().Is<SemIR::OverloadSetValue>(
              import_ir_inst.inst_id())) {
        auto const_inst_id =
            context.constant_values().GetConstantInstId(prev_id);
        auto overload_set_value =
            const_inst_id.has_value()
                ? context.insts().TryGetAs<SemIR::OverloadSetValue>(
                      const_inst_id)
                : std::nullopt;
        if (overload_set_value) {
          TryMergeIntoOverloadSet(
              context, node_id, name_context, is_overload,
              overload_set_value->overload_set_id, function_decl, function_info,
              is_definition,
              GetImportedOverloadSetSource(context, prev_id,
                                           import_ir_inst.ir_id()));
        }
        return true;
      }

      // Verify the decl so that things like aliases are name conflicts.
      prev_is_function =
          import_ir->insts().Is<SemIR::FunctionDecl>(import_ir_inst.inst_id());
      break;
    }
    default:
      break;
  }

  // (3) D-OV-3: a marked declaration against a plain function. Diagnose and
  // do not merge; the declaration gets its own function and is not added to
  // name lookup, so no redeclaration diagnostics are emitted on top.
  if (prev_is_function && is_overload) {
    DiagnoseOverloadMarkerMismatch(context, node_id, name_context.name_id,
                                   SemIR::LocId(prev_id));
    return true;
  }

  // (4) The template's business: a plain redeclaration, or a duplicate name.
  return false;
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
// (iii), (v) and (vi); OV-2 lifted (i) generic members, (ii) sets in generic
// scopes and (iv) `extern` members) as semantics TODOs at the declaration, so
// that overload resolution only ever sees supported members. The declaration
// is still a member.
//
// `function_info` is the declaration being checked and `function_id` the
// function it declares or redeclares; the two differ when the declaration
// merged into a previous one.
static auto DiagnoseOverloadGates(
    Context& context, Parse::AnyFunctionDeclId node_id,
    const KeywordModifierSet& modifier_set,
    const DeclNameStack::NameContext& name_context,
    const SemIR::Function& function_info, SemIR::FunctionId function_id)
    -> void {
  // (iii) Explicit parameters after `self` must be by-value binding patterns:
  // the resolution probe is a value conversion, so `ref` and `var` members
  // would be accepted by the probe and rejected by the commit. This also gates
  // destructuring tuple and struct parameter patterns, whose leaf is not a
  // single `ValueParamPattern`. The patterns are this declaration's own: a
  // redeclaration of an imported member merges into a `Function` whose
  // pattern block holds import refs to the declaring file's patterns, which
  // say nothing about the parameter kind here.
  for (auto param_pattern_id :
       context.inst_blocks().GetOrEmpty(function_info.param_patterns_id)) {
    if (param_pattern_id == function_info.self_param_id ||
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

// For the top-level parameter patterns list, and for any level of nested tuple
// patterns, ensure that if a subpattern provides a default value, all
// subsequent patterns at that level of nesting must provide a default value as
// well. Returns the number of default values provided at the top level of the
// function parameter, useful for efficient arity checking in callers later on.
//
// TODO: per https://github.com/carbon-language/carbon-lang/issues/7529, this
// should also consider automatically supplied defaults for fully-specified
// tuple subpatterns, and consider them as having a default for the purposes
// of the out-of-order detection. It will also need to detect the error
// condition when a default is also specified for those fully-specified tuple
// subpatterns.
static auto CheckDefaults(Context& context, SemIR::Function& function)
    -> int32_t {
  if (!function.param_patterns_id.has_value()) {
    return 0;
  }

  struct PatternLevelState {
    // The inst ids of the subpatterns on this level of tuple subpattern
    // nesting, treated as a work list, so in reverse order of declaration.
    llvm::SmallVector<SemIR::InstId> subpattern_ids;

    // If patterns at this level of nesting have default values, this refers
    // to the first instruction to specify a default, useful for diagnostics.
    SemIR::InstId first_pattern_with_default = SemIR::InstId::None;

    // If we encounter a tuple-pattern during processing, we suspend processing
    // of this pattern level, in the middle of processing a single pattern from
    // root to leaves. So we record the current state of processing of a single
    // pattern to return to it after processing any tuple subpatterns.

    // True if the current pattern being processed has a default value
    // specified.
    bool current_pattern_has_default = false;

    // The current pattern we are processing, stored separately since it's been
    // popped from the `pattern_work_list` and already processed, just may need
    // subsequent processing.
    SemIR::InstId current_id = SemIR::InstId::None;

    // A work list of patterns to be processed at this level of nesting.
    llvm::SmallVector<SemIR::InstId> pattern_work_list;

    // A list of subpatterns missing required defaults, to coalesce error
    // reporting into a single diagnostic.
    llvm::SmallVector<SemIR::InstId> patterns_missing_defaults;

    // A count of the number of patterns on this level that have defaults.
    int32_t default_count = 0;
  };

  llvm::SmallVector<PatternLevelState> level_state_stack;
  size_t default_count = 0;
  level_state_stack.push_back({});
  llvm::append_range(
      level_state_stack.back().subpattern_ids,
      llvm::reverse(context.inst_blocks().Get(function.param_patterns_id)));

  while (!level_state_stack.empty()) {
    PatternLevelState* state = &level_state_stack.back();
    while (!state->subpattern_ids.empty() ||
           !state->pattern_work_list.empty() || state->current_id.has_value()) {
      // If we're not resuming processing a pattern from a nested state, start
      // processing the next subpattern.
      if (!state->current_id.has_value()) {
        state->pattern_work_list.push_back(
            state->subpattern_ids.pop_back_val());
        state->current_pattern_has_default = false;
      }
      while (!state->pattern_work_list.empty()) {
        state->current_id = state->pattern_work_list.pop_back_val();
        auto inst = context.insts().Get(state->current_id);
        CARBON_KIND_SWITCH(inst) {
          case CARBON_KIND(SemIR::DefaultValuePattern default_value_pattern): {
            state->current_pattern_has_default = true;
            state->default_count += 1;
            state->pattern_work_list.push_back(
                default_value_pattern.subpattern_id);
            break;
          }
          case CARBON_KIND(
              SemIR::WrapperBindingPattern wrapper_binding_pattern): {
            state->pattern_work_list.push_back(
                wrapper_binding_pattern.subpattern_id);
            break;
          }
          case CARBON_KIND(SemIR::TuplePattern tuple_pattern): {
            auto elements =
                context.inst_blocks().Get(tuple_pattern.elements_id);
            if (!elements.empty()) {
              // Start a new state for the nested tuple pattern elements.
              level_state_stack.push_back({});
              state = &level_state_stack.back();
              llvm::append_range(state->subpattern_ids,
                                 llvm::reverse(elements));
            }
            break;
          }
          default:
            // We only process patterns containing subpatterns, so this is an
            // intentional no-op.
            break;
        }
      }
      // Finished processing this subpattern, detect a missing default if
      // required.
      if (state->current_pattern_has_default &&
          !state->first_pattern_with_default.has_value()) {
        state->first_pattern_with_default = state->current_id;
      } else if (!state->current_pattern_has_default &&
                 state->first_pattern_with_default.has_value()) {
        state->patterns_missing_defaults.push_back(state->current_id);
      }
      state->current_id = SemIR::InstId::None;
    }
    // Finished processing this tuple-pattern, emit diagnostics if any.
    if (!state->patterns_missing_defaults.empty()) {
      CARBON_DIAGNOSTIC(RequiredPatternDefaultValueMissing, Error,
                        "this pattern is missing a required default value.");
      CARBON_DIAGNOSTIC(RequiredPatternDefaultValueFirstDefault, Note,
                        "all patterns to the right of this first pattern with "
                        "a default value must also specify a default value.");
      CARBON_DIAGNOSTIC(
          RequiredPatternDefaultValueMissingAdditional, Note,
          "this pattern is also missing a required default value.");
      auto inst_ref = llvm::ArrayRef(state->patterns_missing_defaults);
      auto builder = context.emitter().Build(
          inst_ref.consume_front(), RequiredPatternDefaultValueMissing);
      for (auto inst_id : inst_ref) {
        builder.Note(inst_id, RequiredPatternDefaultValueMissingAdditional);
      }
      builder.Note(state->first_pattern_with_default,
                   RequiredPatternDefaultValueFirstDefault);
      builder.Emit();
    }

    // Extract the count from the level we just completed, overwriting any
    // nested level value extracted previously.
    default_count = level_state_stack.back().default_count;
    level_state_stack.pop_back();
  }

  return default_count;
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
                      {
                          .call_param_patterns_id = name.call_param_patterns_id,
                          .call_params_id = name.call_params_id,
                          .call_param_ranges = name.param_ranges,
                          .return_type_inst_id = return_type_inst_id,
                          .return_form_inst_id = return_form_inst_id,
                          .return_pattern_id = return_pattern_id,
                          .virtual_modifier = virtual_modifier,
                          .evaluation_mode = evaluation_mode,
                          .interface_modifier = interface_modifier,
                          .self_param_id = self_param_id,
                      }};
  if (is_definition) {
    function_info.definition_id = decl_id;
  }

  function_info.default_value_arity = CheckDefaults(context, function_info);

  DiagnosePositionalParams(context, function_info);

  // D-OV-6 gates (ix) and (xiii): a marked declaration directly in an
  // interface or `impl` body. The marker is diagnosed and then ignored, so the
  // declaration is checked as a plain function.
  if (is_overload && DiagnoseOverloadInInterfaceOrImpl(
                         context, node_id, name_context.parent_scope_id)) {
    is_overload = false;
  }

  // Fork (D-UA-6): the `overload fn` set decision runs first; a declaration it
  // does not claim is a plain redeclaration for upstream's template.
  if (!TryMergeOverloadDecl(context, node_id, name_context, is_overload,
                            function_decl, function_info, is_definition)) {
    TryMergeRedecl(
        context, name_context, std::nullopt,
        MergeRedeclEntityInfo<SemIR::Function>{.new_entity_decl = function_decl,
                                               .new_entity = function_info},
        is_definition);
  }

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
                          name_context, function_info,
                          function_decl.function_id);
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
      case CARBON_KIND(SemIR::DefaultValuePattern default_value_pattern): {
        work_list.push_back(default_value_pattern.subpattern_id);
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
