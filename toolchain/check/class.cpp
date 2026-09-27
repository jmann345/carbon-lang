// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/class.h"

#include <algorithm>
#include <tuple>

#include "llvm/ADT/STLExtras.h"
#include "toolchain/base/kind_switch.h"
#include "toolchain/check/context.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/cpp/export.h"
#include "toolchain/check/custom_witness.h"
#include "toolchain/check/decl_name_stack.h"
#include "toolchain/check/diagnostic_helpers.h"
#include "toolchain/check/eval.h"
#include "toolchain/check/function.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/impl.h"
#include "toolchain/check/import_ref.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/merge.h"
#include "toolchain/check/modifiers.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/pattern.h"
#include "toolchain/check/pattern_match.h"
#include "toolchain/check/thunk.h"
#include "toolchain/check/type.h"
#include "toolchain/diagnostics/format_providers.h"
#include "toolchain/parse/node_ids.h"
#include "toolchain/sem_ir/builtin_function_kind.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// Tries to merge new_class into prev_class_id. Since new_class won't have a
// definition even if one is upcoming, set is_definition to indicate the planned
// result.
//
// If merging is successful, returns true and may update the previous class.
// Otherwise, returns false. Prints a diagnostic when appropriate.
static auto MergeClassRedecl(Context& context, Parse::AnyClassDeclId node_id,
                             Lex::TokenKind decl_kind, SemIR::Class& new_class,
                             bool new_is_definition,
                             SemIR::ClassId prev_class_id,
                             SemIR::ImportIRId prev_import_ir_id) -> bool {
  auto& prev_class = context.classes().Get(prev_class_id);
  SemIR::LocId prev_loc_id(prev_class.latest_decl_id());

  // Check the generic parameters match, if they were specified.
  if (!CheckRedeclParamsMatch(context, DeclParams(new_class),
                              DeclParams(prev_class))) {
    return false;
  }

  DiagnoseIfInvalidRedecl(
      context, decl_kind, prev_class.name_id,
      RedeclInfo(new_class, node_id, new_is_definition),
      RedeclInfo(prev_class, prev_loc_id, prev_class.has_definition_started()),
      prev_import_ir_id);

  if (new_is_definition && prev_class.has_definition_started()) {
    // Don't attempt to merge multiple definitions.
    return false;
  }

  if (new_is_definition) {
    prev_class.MergeDefinition(new_class);
  }

  if (prev_import_ir_id.has_value() ||
      (prev_class.is_extern && !new_class.is_extern)) {
    prev_class.first_owning_decl_id = new_class.first_owning_decl_id;
    ReplacePrevInstForMerge(context, new_class.parent_scope_id,
                            prev_class.name_id, new_class.first_owning_decl_id);
  }
  return true;
}

// Adds the name to name lookup. If there's a conflict, tries to merge. May
// update class_decl and class_info when merging.
static auto MergeOrAddName(Context& context, Parse::AnyClassDeclId node_id,
                           Lex::TokenKind decl_kind,
                           const DeclNameStack::NameContext& name_context,
                           SemIR::InstId class_decl_id,
                           SemIR::ClassDecl& class_decl,
                           SemIR::Class& class_info, bool is_definition,
                           SemIR::AccessKind access_kind) -> void {
  SemIR::ScopeLookupResult lookup_result =
      context.decl_name_stack().LookupOrAddName(name_context, class_decl_id,
                                                access_kind);
  if (lookup_result.is_poisoned()) {
    // This is a declaration of a poisoned name.
    DiagnosePoisonedName(context, name_context.name_id_for_new_inst(),
                         lookup_result.poisoning_loc_id(), name_context.loc_id);
    return;
  }

  if (!lookup_result.is_found()) {
    return;
  }

  SemIR::InstId prev_id = lookup_result.target_inst_id();

  auto prev_class_id = SemIR::ClassId::None;
  auto prev_import_ir_id = SemIR::ImportIRId::None;
  auto prev = context.insts().Get(prev_id);
  CARBON_KIND_SWITCH(prev) {
    case CARBON_KIND(SemIR::ClassDecl class_decl): {
      prev_class_id = class_decl.class_id;
      break;
    }
    case CARBON_KIND(SemIR::ImportRefLoaded import_ref): {
      auto import_ir_inst =
          context.import_ir_insts().Get(import_ref.import_ir_inst_id);

      // Verify the decl so that things like aliases are name conflicts.
      const auto* import_ir =
          context.import_irs().Get(import_ir_inst.ir_id()).sem_ir;
      if (!import_ir->insts().Is<SemIR::ClassDecl>(import_ir_inst.inst_id())) {
        break;
      }

      // Use the constant value to get the ID.
      auto decl_value = context.insts().Get(
          context.constant_values().GetConstantInstId(prev_id));
      if (auto class_type = decl_value.TryAs<SemIR::ClassType>()) {
        prev_class_id = class_type->class_id;
        prev_import_ir_id = import_ir_inst.ir_id();
      } else if (auto generic_class_type =
                     context.types().TryGetAs<SemIR::GenericClassType>(
                         decl_value.type_id())) {
        prev_class_id = generic_class_type->class_id;
        prev_import_ir_id = import_ir_inst.ir_id();
      }
      break;
    }
    default:
      break;
  }

  if (!prev_class_id.has_value() ||
      context.classes().Get(prev_class_id).is_union != class_info.is_union) {
    // This is a redeclaration of something other than a class, or a
    // redeclaration that changes between `class` and `union`.
    DiagnoseDuplicateName(context, name_context.name_id, name_context.loc_id,
                          SemIR::LocId(prev_id));
    return;
  }

  // TODO: Fix `extern` logic. It doesn't work correctly, but doesn't seem worth
  // ripping out because existing code may incrementally help.
  if (MergeClassRedecl(context, node_id, decl_kind, class_info, is_definition,
                       prev_class_id, prev_import_ir_id)) {
    // When merging, use the existing entity rather than adding a new one.
    class_decl.class_id = prev_class_id;
    class_decl.type_id = prev.type_id();
    // TODO: Validate that the redeclaration doesn't set an access modifier.
  }
}

auto BuildClassOrUnionDecl(Context& context, Parse::AnyClassDeclId node_id,
                           bool is_definition, NameComponent name,
                           DeclIntroducerState introducer,
                           Lex::TokenKind decl_kind)
    -> std::tuple<SemIR::ClassId, SemIR::InstId> {
  CARBON_CHECK(
      decl_kind == Lex::TokenKind::Class || decl_kind == Lex::TokenKind::Union,
      "Unexpected declaration kind {0}", decl_kind);
  const bool is_union = decl_kind == Lex::TokenKind::Union;
  auto name_context = context.decl_name_stack().FinishName(name);

  // Process modifiers. A union is implicitly final, so it takes neither
  // `abstract` nor `base` (docs/design/unions.md, "Union members").
  auto [_, parent_scope_inst] =
      context.name_scopes().GetInstIfValid(name_context.parent_scope_id);
  CheckAccessModifiersOnDecl(context, introducer, parent_scope_inst);
  auto always_acceptable_modifiers =
      KeywordModifierSet::Access | KeywordModifierSet::Extern;
  LimitModifiersOnDecl(
      context, introducer,
      is_union ? always_acceptable_modifiers
               : always_acceptable_modifiers | KeywordModifierSet::Class);
  if (!is_definition) {
    LimitModifiersOnNotDefinition(context, introducer,
                                  always_acceptable_modifiers);
  }
  RestrictExternModifierOnDecl(context, introducer, parent_scope_inst,
                               is_definition);

  bool is_extern = introducer.modifier_set.HasAnyOf(KeywordModifierSet::Extern);
  if (introducer.extern_library.has_value()) {
    context.TODO(node_id, "extern library");
  }
  auto inheritance_kind =
      is_union ? SemIR::Class::Final
               : introducer.modifier_set.ToEnum<SemIR::Class::InheritanceKind>()
                     .Case(KeywordModifierSet::Abstract, SemIR::Class::Abstract)
                     .Case(KeywordModifierSet::Base, SemIR::Class::Base)
                     .Default(SemIR::Class::Final);

  auto decl_block_id = context.inst_block_stack().Pop();

  // Add the class declaration.
  auto class_decl = SemIR::ClassDecl{.type_id = SemIR::TypeType::TypeId,
                                     .class_id = SemIR::ClassId::None,
                                     .decl_block_id = decl_block_id};
  auto class_decl_id = AddPlaceholderInst(context, node_id, class_decl);

  // TODO: Store state regarding is_extern.
  SemIR::Class class_info = {
      name_context.MakeEntityWithParamsBase(name, class_decl_id, is_extern,
                                            SemIR::LibraryNameId::None),
      {// `.self_type_id` depends on the ClassType, so is set below.
       .self_type_id = SemIR::TypeId::None,
       .inheritance_kind = inheritance_kind,
       .is_union = is_union}};

  DiagnoseIfGenericMissingExplicitParameters(context, class_info);

  MergeOrAddName(context, node_id, decl_kind, name_context, class_decl_id,
                 class_decl, class_info, is_definition,
                 introducer.modifier_set.GetAccessKind());

  // Create a new class if this isn't a valid redeclaration.
  bool is_new_class = !class_decl.class_id.has_value();
  if (is_new_class) {
    // TODO: If this is an invalid redeclaration of a non-class entity or there
    // was an error in the qualifier, we will have lost track of the class name
    // here. We should keep track of it even if the name is invalid.
    class_info.generic_id = BuildGenericDecl(context, class_decl_id);
    class_decl.class_id = context.classes().Add(class_info);
    if (class_info.has_parameters()) {
      class_decl.type_id = GetGenericClassType(
          context, class_decl.class_id, context.scope_stack().PeekSpecificId());
    }
  } else {
    auto prev_decl_generic_id =
        context.classes().Get(class_decl.class_id).generic_id;
    FinishGenericRedecl(context, prev_decl_generic_id);
  }

  // Write the class ID into the ClassDecl.
  ReplaceInstBeforeConstantUse(context, class_decl_id, class_decl);

  if (is_new_class) {
    // TODO: Form this as part of building the definition, not as part of the
    // declaration.
    SetClassSelfType(context, class_decl.class_id);
  }

  if (!is_definition && context.sem_ir().is_impl() && !is_extern) {
    context.definitions_required_by_decl().push_back(class_decl_id);
  }

  return {class_decl.class_id, class_decl_id};
}

auto SetClassSelfType(Context& context, SemIR::ClassId class_id) -> void {
  auto& class_info = context.classes().Get(class_id);
  auto specific_id = context.generics().GetSelfSpecific(class_info.generic_id);
  class_info.self_type_id = GetClassType(context, class_id, specific_id);
}

auto StartClassDefinition(Context& context, SemIR::Class& class_info,
                          SemIR::InstId definition_id) -> void {
  // Track that this declaration is the definition.
  CARBON_CHECK(!class_info.has_definition_started());
  class_info.definition_id = definition_id;
  class_info.scope_id = context.name_scopes().Add(
      definition_id, SemIR::NameId::None, class_info.parent_scope_id);

  // Introduce `Self`.
  auto self_type_inst_id =
      context.types().GetTypeInstId(class_info.self_type_id);
  context.name_scopes().AddRequiredName(
      class_info.scope_id, SemIR::NameId::SelfType, self_type_inst_id);
  context.name_scopes()
      .Get(class_info.scope_id)
      .set_self_type_id(self_type_inst_id);
}

// Checks that the specified finished adapter definition is valid and builds and
// returns a corresponding complete type witness instruction.
static auto CheckCompleteAdapterClassType(
    Context& context, Parse::NodeId node_id, SemIR::ClassId class_id,
    llvm::ArrayRef<SemIR::InstId> field_decls,
    llvm::ArrayRef<SemIR::InstId> body) -> SemIR::InstId {
  const auto& class_info = context.classes().Get(class_id);
  if (class_info.base_id.has_value()) {
    CARBON_DIAGNOSTIC(AdaptWithBase, Error, "adapter with base class");
    CARBON_DIAGNOSTIC(AdaptWithBaseHere, Note, "`base` declaration is here");
    context.emitter()
        .Build(class_info.adapt_id, AdaptWithBase)
        .Note(class_info.base_id, AdaptWithBaseHere)
        .Emit();
    return SemIR::ErrorInst::InstId;
  }

  if (!field_decls.empty()) {
    CARBON_DIAGNOSTIC(AdaptWithFields, Error, "adapter with fields");
    CARBON_DIAGNOSTIC(AdaptWithFieldHere, Note,
                      "first field declaration is here");
    context.emitter()
        .Build(class_info.adapt_id, AdaptWithFields)
        .Note(field_decls.front(), AdaptWithFieldHere)
        .Emit();
    return SemIR::ErrorInst::InstId;
  }

  for (auto inst_id : body) {
    if (auto function_decl =
            context.insts().TryGetAs<SemIR::FunctionDecl>(inst_id)) {
      auto& function = context.functions().Get(function_decl->function_id);
      if (function.virtual_modifier ==
          SemIR::Function::VirtualModifier::Virtual) {
        CARBON_DIAGNOSTIC(AdaptWithVirtual, Error,
                          "adapter with virtual function");
        CARBON_DIAGNOSTIC(AdaptWithVirtualHere, Note,
                          "first virtual function declaration is here");
        context.emitter()
            .Build(class_info.adapt_id, AdaptWithVirtual)
            .Note(inst_id, AdaptWithVirtualHere)
            .Emit();
        return SemIR::ErrorInst::InstId;
      }
    }
  }

  // The object representation of the adapter is the object representation
  // of the adapted type.
  auto adapted_type_id =
      class_info.GetAdaptedType(context.sem_ir(), SemIR::SpecificId::None);
  auto object_repr_id = context.types().GetObjectRepr(adapted_type_id);

  return AddInst<SemIR::CompleteTypeWitness>(
      context, node_id,
      {.type_id = GetSingletonType(context, SemIR::WitnessType::TypeInstId),
       // TODO: Use InstId from the adapt declaration.
       .object_repr_type_inst_id =
           context.types().GetTypeInstId(object_repr_id)});
}

static auto AddStructTypeFields(
    Context& context,
    llvm::SmallVector<SemIR::StructTypeField>& struct_type_fields,
    llvm::ArrayRef<SemIR::InstId> field_decls) -> SemIR::StructTypeFieldsId {
  for (auto field_decl_id : field_decls) {
    auto field_decl = context.insts().GetAs<SemIR::FieldDecl>(field_decl_id);
    auto& field = context.fields().Get(field_decl.field_id);
    field.index =
        SemIR::ElementIndex{static_cast<int>(struct_type_fields.size())};
    if (field_decl.type_id == SemIR::ErrorInst::TypeId) {
      struct_type_fields.push_back(
          {.name_id = field_decl.name_id,
           .type_inst_id = SemIR::ErrorInst::TypeInstId});
      continue;
    }
    auto unbound_element_type =
        context.sem_ir().types().GetAs<SemIR::UnboundElementType>(
            field_decl.type_id);
    struct_type_fields.push_back(
        {.name_id = field_decl.name_id,
         .type_inst_id = unbound_element_type.element_type_inst_id});
  }
  auto fields_id =
      context.struct_type_fields().AddCanonical(struct_type_fields);
  return fields_id;
}

// Result of comparing a virtual function in a base class with a potential
// overrider in a derived class.
enum class OverrideMatchResult : uint8_t {
  // The functions match.
  Match,
  // The potential overrider is not marked `override`.
  NotAnOverride,
  // The names do not match.
  NameMismatch,
  // The arity (number of explicit parameters) does not match.
  ArityMismatch,
};

// Compares a virtual function in a base class with a potential overrider in a
// derived class.
static auto CompareVirtualWithOverrider(const SemIR::Function& base_fn,
                                        const SemIR::Function& derived_fn)
    -> OverrideMatchResult {
  if (derived_fn.virtual_modifier !=
      SemIR::FunctionFields::VirtualModifier::Override) {
    return OverrideMatchResult::NotAnOverride;
  }
  if (derived_fn.name_id != base_fn.name_id) {
    return OverrideMatchResult::NameMismatch;
  }
  if (derived_fn.call_param_ranges.explicit_size() !=
      base_fn.call_param_ranges.explicit_size()) {
    return OverrideMatchResult::ArityMismatch;
  }
  // TODO: We should check more thoroughly for compatibility between the two
  // functions here, so that we can determine which function is being overridden
  // if the base function is in a C++ overload set.
  return OverrideMatchResult::Match;
}

// Builds and returns a vtable for the current class. Assumes that the virtual
// functions for the class are listed as the top element of the `vtable_stack`.
static auto BuildVtable(Context& context, Parse::ClassDefinitionId node_id,
                        SemIR::ClassId class_id,
                        std::optional<SemIR::ClassType> base_class_type,
                        llvm::ArrayRef<SemIR::InstId> vtable_contents)
    -> SemIR::VtableId {
  auto base_vtable_id = SemIR::VtableId::None;
  auto base_class_specific_id = SemIR::SpecificId::None;

  // Get some base class/type/specific info.
  if (base_class_type) {
    auto& base_class_info = context.classes().Get(base_class_type->class_id);
    auto base_vtable_decl_inst_id = base_class_info.vtable_decl_id;
    if (base_vtable_decl_inst_id.has_value()) {
      LoadImportRef(context, base_vtable_decl_inst_id);
      auto canonical_base_vtable_inst_id =
          context.constant_values().GetConstantInstId(base_vtable_decl_inst_id);
      const auto& base_vtable_decl_inst =
          context.insts().GetAs<SemIR::VtableDecl>(
              canonical_base_vtable_inst_id);
      base_vtable_id = base_vtable_decl_inst.vtable_id;
      base_class_specific_id = base_class_type->specific_id;
    }
  }

  const auto& class_info = context.classes().Get(class_id);
  auto class_generic_id = class_info.generic_id;

  // Wrap vtable entries in SpecificFunctions as needed/in generic classes.
  auto build_specific_function =
      [&](SemIR::InstId fn_decl_id) -> SemIR::InstId {
    if (!class_generic_id.has_value()) {
      return fn_decl_id;
    }
    const auto& fn_decl =
        context.insts().GetAs<SemIR::FunctionDecl>(fn_decl_id);
    const auto& function = context.functions().Get(fn_decl.function_id);
    return GetOrAddInst<SemIR::SpecificFunction>(
        context, node_id,
        {.type_id =
             GetSingletonType(context, SemIR::SpecificFunctionType::TypeInstId),
         .callee_id = fn_decl_id,
         .specific_id =
             context.generics().GetSelfSpecific(function.generic_id)});
  };

  llvm::SmallVector<SemIR::InstId> vtable;
  Set<SemIR::FunctionId> implemented_impls;
  bool carbon_native_vtable = true;

  // Add vtable entries from the base class, updating them to point to a derived
  // class overrider if there is one.
  if (base_vtable_id.has_value()) {
    const auto& base_vtable = context.vtables().Get(base_vtable_id);
    carbon_native_vtable = base_vtable.carbon_native_vtable;
    auto base_vtable_inst_block =
        context.inst_blocks().Get(base_vtable.virtual_functions_id);
    // TODO: Avoid quadratic search. Perhaps build a map from `NameId` to the
    // elements of the top of `vtable_stack`.
    for (auto base_vtable_entry_id : base_vtable_inst_block) {
      if (!base_vtable_entry_id.has_value()) {
        // Foreign vtables may have holes in them for information that we don't
        // use. Just skip those entries.
        CARBON_CHECK(
            !context.vtables().Get(base_vtable_id).carbon_native_vtable);
        vtable.push_back(SemIR::InstId::None);
        continue;
      }

      auto [derived_vtable_entry_id, derived_vtable_entry_const_id, fn_id,
            specific_id] =
          DecomposeVirtualFunction(context.sem_ir(), base_vtable_entry_id,
                                   base_class_specific_id);
      const auto& fn = context.sem_ir().functions().Get(fn_id);
      const auto* i = llvm::find_if(
          vtable_contents, [&](SemIR::InstId override_fn_decl_id) -> bool {
            const auto& override_fn = context.functions().Get(
                context.insts()
                    .GetAs<SemIR::FunctionDecl>(override_fn_decl_id)
                    .function_id);
            return CompareVirtualWithOverrider(fn, override_fn) ==
                   OverrideMatchResult::Match;
          });
      if (i != vtable_contents.end()) {
        auto override_fn_id =
            context.insts().GetAs<SemIR::FunctionDecl>(*i).function_id;
        implemented_impls.Insert(override_fn_id);

        // TODO: When the base class is a C++ class, we could have multiple
        // potential functions to override. Check against each of them rather
        // than trying to override them all.
        auto override_or_thunk_id =
            BuildThunk(context, fn_id, specific_id, class_info.self_type_id, *i,
                       /*defer_definition=*/true);
        if (override_or_thunk_id != SemIR::ErrorInst::InstId) {
          auto override_or_thunk_fn_id =
              context.insts()
                  .GetAs<SemIR::FunctionDecl>(override_or_thunk_id)
                  .function_id;
          auto& override_or_thunk_fn =
              context.functions().Get(override_or_thunk_fn_id);
          derived_vtable_entry_id =
              build_specific_function(override_or_thunk_id);
          override_or_thunk_fn.virtual_index = vtable.size();
          CARBON_CHECK(override_or_thunk_fn.virtual_index == fn.virtual_index);
        }
      } else if (auto base_vtable_specific_function =
                     context.insts().TryGetAs<SemIR::SpecificFunction>(
                         derived_vtable_entry_id)) {
        if (derived_vtable_entry_const_id.is_symbolic()) {
          // Create a new instruction here that is otherwise identical to
          // `derived_vtable_entry_id` but is dependent within the derived
          // class. This ensures we can `GetConstantValueInSpecific` for it
          // with the derived class's specific (when forming further derived
          // classes, lowering the vtable, etc).
          derived_vtable_entry_id = GetOrAddInst<SemIR::SpecificFunction>(
              context, node_id,
              {.type_id = GetSingletonType(
                   context, SemIR::SpecificFunctionType::TypeInstId),
               .callee_id = base_vtable_specific_function->callee_id,
               .specific_id = base_vtable_specific_function->specific_id});
        }
      }
      vtable.push_back(derived_vtable_entry_id);
    }
  }

  // Add any remaining virtual functions from the derived class to the vtable,
  // and diagnose any `override fn`s that didn't override anything.
  for (auto inst_id : vtable_contents) {
    auto fn_decl = context.insts().GetAs<SemIR::FunctionDecl>(inst_id);
    auto& fn = context.functions().Get(fn_decl.function_id);
    if (fn.virtual_modifier !=
        SemIR::FunctionFields::VirtualModifier::Override) {
      fn.virtual_index = vtable.size();
      vtable.push_back(build_specific_function(inst_id));
    } else if (!implemented_impls.Lookup(fn_decl.function_id)) {
      CARBON_DIAGNOSTIC(OverrideWithoutVirtualInBase, Error,
                        "override without compatible virtual in base class");
      CARBON_DIAGNOSTIC(OverrideCandidateArityMismatch, Note,
                        "base class function has {2:more|fewer} parameters "
                        "({0} vs {1} excluding `self`)",
                        Diagnostics::IntAsSelect, Diagnostics::IntAsSelect,
                        Diagnostics::BoolAsSelect);
      auto builder = context.emitter().Build(SemIR::LocId(inst_id),
                                             OverrideWithoutVirtualInBase);
      if (base_vtable_id.has_value()) {
        const auto& base_vtable = context.vtables().Get(base_vtable_id);
        auto base_vtable_inst_block =
            context.inst_blocks().Get(base_vtable.virtual_functions_id);
        for (auto base_vtable_entry_id : base_vtable_inst_block) {
          if (!base_vtable_entry_id.has_value()) {
            continue;
          }
          auto [derived_vtable_entry_id, derived_vtable_entry_const_id, fn_id,
                specific_id] =
              DecomposeVirtualFunction(context.sem_ir(), base_vtable_entry_id,
                                       base_class_specific_id);
          const auto& base_fn = context.sem_ir().functions().Get(fn_id);
          switch (CompareVirtualWithOverrider(base_fn, fn)) {
            case OverrideMatchResult::ArityMismatch:
              builder.Note(base_fn.first_owning_decl_id,
                           OverrideCandidateArityMismatch,
                           base_fn.call_param_ranges.explicit_size() - 1,
                           fn.call_param_ranges.explicit_size() - 1,
                           base_fn.call_param_ranges.explicit_size() >
                               fn.call_param_ranges.explicit_size());
              break;
            case OverrideMatchResult::NameMismatch:
              // TODO: If the name is similar enough and the overrider otherwise
              // matches, emit a note about the potential misspelling.
              break;
            case OverrideMatchResult::Match:
              CARBON_FATAL("Unexpectedly found a matching overrider");
            case OverrideMatchResult::NotAnOverride:
              CARBON_FATAL("Should only consider `override fn`s here");
          }
        }
      }
      builder.Emit();
    }
  }

  return context.vtables().Add(
      {{.class_id = class_id,
        .virtual_functions_id = context.inst_blocks().Add(vtable),
        .carbon_native_vtable = carbon_native_vtable}});
}

// Checks that the specified finished class definition is valid and builds and
// returns a corresponding complete type witness instruction.
static auto CheckCompleteClassType(
    Context& context, Parse::ClassDefinitionId node_id, SemIR::ClassId class_id,
    llvm::ArrayRef<SemIR::InstId> field_decls,
    llvm::ArrayRef<SemIR::InstId> vtable_contents,
    llvm::ArrayRef<SemIR::InstId> body) -> SemIR::InstId {
  auto& class_info = context.classes().Get(class_id);
  if (class_info.adapt_id.has_value()) {
    return CheckCompleteAdapterClassType(context, node_id, class_id,
                                         field_decls, body);
  }

  bool defining_vptr = class_info.is_dynamic;
  auto base_type_id =
      class_info.GetBaseType(context.sem_ir(), SemIR::SpecificId::None);
  // TODO: Use InstId from base declaration.
  auto base_type_inst_id = context.types().GetTypeInstId(base_type_id);
  std::optional<SemIR::ClassType> base_class_type;
  if (base_type_id.has_value()) {
    // TODO: If the base class is template dependent, we will need to decide
    // whether to add a vptr as part of instantiation.
    base_class_type = context.types().TryGetAs<SemIR::ClassType>(base_type_id);
    if (base_class_type &&
        context.classes().Get(base_class_type->class_id).is_dynamic) {
      defining_vptr = false;
    }
  }

  llvm::SmallVector<SemIR::StructTypeField> struct_type_fields;
  struct_type_fields.reserve(defining_vptr + class_info.base_id.has_value() +
                             field_decls.size());
  if (defining_vptr) {
    struct_type_fields.push_back(
        {.name_id = SemIR::NameId::Vptr,
         .type_inst_id = context.types().GetTypeInstId(
             GetPointerType(context, SemIR::VtableType::TypeInstId))});
  }
  if (base_type_id.has_value()) {
    auto base_decl = context.insts().GetAs<SemIR::BaseDecl>(class_info.base_id);
    base_decl.index =
        SemIR::ElementIndex{static_cast<int>(struct_type_fields.size())};
    ReplaceInstPreservingConstantValue(context, class_info.base_id, base_decl);
    struct_type_fields.push_back(
        {.name_id = SemIR::NameId::Base, .type_inst_id = base_type_inst_id});
  }

  if (class_info.is_dynamic) {
    auto vtable_id = BuildVtable(context, node_id, class_id, base_class_type,
                                 vtable_contents);
    auto vptr_type_id = GetPointerType(context, SemIR::VtableType::TypeInstId);
    class_info.vtable_decl_id = AddInst<SemIR::VtableDecl>(
        context, node_id, {.type_id = vptr_type_id, .vtable_id = vtable_id});
  }

  auto struct_type_id = GetStructType(
      context, AddStructTypeFields(context, struct_type_fields, field_decls));

  return AddInst<SemIR::CompleteTypeWitness>(
      context, node_id,
      {.type_id = GetSingletonType(context, SemIR::WitnessType::TypeInstId),
       .object_repr_type_inst_id =
           context.types().GetTypeInstId(struct_type_id)});
}

auto ComputeClassObjectRepr(Context& context, Parse::ClassDefinitionId node_id,
                            SemIR::ClassId class_id,
                            llvm::ArrayRef<SemIR::InstId> field_decls,
                            llvm::ArrayRef<SemIR::InstId> vtable_contents,
                            llvm::ArrayRef<SemIR::InstId> body) -> void {
  auto complete_type_witness_id = CheckCompleteClassType(
      context, node_id, class_id, field_decls, vtable_contents, body);
  auto& class_info = context.classes().Get(class_id);
  class_info.complete_type_witness_id = complete_type_witness_id;
}

// Checks that the specified finished union definition is valid and builds and
// returns a corresponding complete type witness instruction, or the error
// witness after diagnosing.
static auto CheckCompleteUnionType(
    Context& context, Parse::UnionDefinitionId node_id, SemIR::ClassId class_id,
    llvm::ArrayRef<SemIR::InstId> field_decls,
    llvm::ArrayRef<SemIR::InstId> vtable_contents) -> SemIR::InstId {
  // Copied out: the class store is not held across the field walks below.
  const auto class_info = context.classes().Get(class_id);
  CARBON_CHECK(class_info.is_union);
  // The parser admits neither `adapt` nor `base` in a union body, and
  // `virtual` is stripped from every method of a final class before it could
  // reach the vtable.
  CARBON_CHECK(!class_info.adapt_id.has_value() &&
               !class_info.base_id.has_value() && vtable_contents.empty());

  // This also assigns each field's element index, which `ClassElementAccess`
  // and the lowered byte-offset access index by; it runs before any early
  // return below so that no field is left with a `None` element index, even
  // in a union that completes with the error witness.
  llvm::SmallVector<SemIR::StructTypeField> struct_type_fields;
  struct_type_fields.reserve(field_decls.size());
  auto fields_id =
      AddStructTypeFields(context, struct_type_fields, field_decls);

  // TODO: A union with its own parameters or inside a generic scope has a
  // layout that depends on its arguments; the only symbolic-layout recompute
  // today is the choice payload hook (`EvalConstantInst` for
  // `CustomLayoutType`), which asserts tuple fields and the choice payload
  // allowlist. Concrete unions only in 0.1 (docs/design/unions.md,
  // "Declaring a union"; fork/unions/plan.md D-UN-3).
  if (class_info.generic_id.has_value()) {
    context.TODO(class_info.definition_id, "generic union");
    return SemIR::ErrorInst::InstId;
  }

  if (field_decls.empty()) {
    CARBON_DIAGNOSTIC(UnionWithoutFields, Error,
                      "union `{0}` must declare at least one field",
                      SemIR::NameId);
    context.emitter().Emit(class_info.definition_id, UnionWithoutFields,
                           class_info.name_id);
    return SemIR::ErrorInst::InstId;
  }

  // Every field must be trivially destructible and trivially copyable
  // (docs/design/unions.md, "Field rules in 0.1"): the destructible half is
  // `IsTriviallyDestructible`, the copyable half rejects any `Core.Copy` impl
  // declared outside package `Core` anywhere in the field's type. All
  // offending fields are reported.
  bool has_error = false;
  auto size = SemIR::ObjectSize::Zero();
  auto align = SemIR::ObjectSize::Bytes(1);
  for (auto [i, field] : llvm::enumerate(struct_type_fields)) {
    if (field.type_inst_id == SemIR::ErrorInst::TypeInstId) {
      // Already diagnosed at the field declaration.
      has_error = true;
      continue;
    }
    auto field_type_id =
        context.types().GetTypeIdForTypeInstId(field.type_inst_id);
    if (!IsTriviallyDestructible(context, field_type_id) ||
        HasNonTrivialUserCopyImpl(context, field_type_id)) {
      CARBON_DIAGNOSTIC(UnionFieldNotTriviallyCopyable, Error,
                        "union field `{0}` has type {1}, which is not "
                        "trivially copyable and destructible",
                        SemIR::NameId, InstIdAsType);
      context.emitter().Emit(field_decls[i], UnionFieldNotTriviallyCopyable,
                             field.name_id, field.type_inst_id);
      has_error = true;
      continue;
    }
    // Fields are complete at their declaration and the union is concrete, so
    // every field has a concrete layout.
    auto layout =
        context.types().GetCompleteTypeInfo(field_type_id).object_layout;
    CARBON_CHECK(layout.has_value(), "Dependent layout for union field {0}",
                 context.types().GetAsInst(field_type_id));
    size = std::max(size, layout.size);
    align = std::max(align, layout.alignment);
  }
  if (has_error) {
    return SemIR::ErrorInst::InstId;
  }

  // The layout rule, literally: every field at offset 0, `align(U)` the
  // maximum field alignment, `size(U)` the maximum field size rounded up to
  // `align(U)` (docs/design/unions.md, "Layout").
  llvm::SmallVector<SemIR::ObjectSize> layout;
  static_assert(SemIR::CustomLayoutId::SizeIndex == 0);
  layout.push_back(size.AlignedTo(align));
  static_assert(SemIR::CustomLayoutId::AlignIndex == 1);
  layout.push_back(align);
  static_assert(SemIR::CustomLayoutId::FirstFieldIndex == 2);
  layout.append(struct_type_fields.size(), SemIR::ObjectSize::Zero());

  auto object_repr_type_inst_id = AddTypeInst(
      context, node_id,
      SemIR::CustomLayoutType{
          .type_id = SemIR::TypeType::TypeId,
          .fields_id = fields_id,
          .layout_id = context.custom_layouts().AddCanonical(layout)});
  return AddInst<SemIR::CompleteTypeWitness>(
      context, node_id,
      {.type_id = GetSingletonType(context, SemIR::WitnessType::TypeInstId),
       .object_repr_type_inst_id = object_repr_type_inst_id});
}

auto ComputeUnionObjectRepr(Context& context, Parse::UnionDefinitionId node_id,
                            SemIR::ClassId class_id,
                            llvm::ArrayRef<SemIR::InstId> field_decls,
                            llvm::ArrayRef<SemIR::InstId> vtable_contents)
    -> void {
  auto complete_type_witness_id = CheckCompleteUnionType(
      context, node_id, class_id, field_decls, vtable_contents);
  auto& class_info = context.classes().Get(class_id);
  class_info.complete_type_witness_id = complete_type_witness_id;
}

auto InNonStaticFieldDecl(Context& context) -> bool {
  return context.full_pattern_stack().IsCurrentKindClassScopeVarDecl() &&
         !context.decl_introducer_state_stack()
              .innermost()
              .modifier_set.HasAnyOf(KeywordModifierSet::Static);
}

auto InStaticClassScopeVar(Context& context) -> bool {
  return context.full_pattern_stack().IsCurrentKindClassScopeVarDecl() &&
         context.decl_introducer_state_stack()
             .innermost()
             .modifier_set.HasAnyOf(KeywordModifierSet::Static);
}

}  // namespace Carbon::Check
