// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/custom_witness.h"

#include <utility>

#include "llvm/ADT/APFloat.h"
#include "llvm/Support/SaveAndRestore.h"
#include "toolchain/base/kind_switch.h"
#include "toolchain/check/call.h"
#include "toolchain/check/class.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/eval.h"
#include "toolchain/check/facet_type.h"
#include "toolchain/check/function.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/impl.h"
#include "toolchain/check/impl_lookup.h"
#include "toolchain/check/import_ref.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/member_access.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/operator.h"
#include "toolchain/check/return.h"
#include "toolchain/check/type.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/diagnostics/format_providers.h"
#include "toolchain/sem_ir/associated_constant.h"
#include "toolchain/sem_ir/builtin_function_kind.h"
#include "toolchain/sem_ir/constant.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/generic.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/import_ir.h"
#include "toolchain/sem_ir/type_info.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// Make the CanonicalKey for a generated function `op_name_id` in the interface
// `core_specific_interface`.
static auto MakeGeneratedFunctionKey(
    Context& context, SemIR::SpecificInterface core_specific_interface,
    SemIR::TypeId self_type_id, SemIR::NameId op_name_id)
    -> SemIR::GeneratedFunction::CanonicalKey {
  // TODO: We'd like to build an Interface-with-Self specific here for the key,
  // via MakeSpecificWithInnerSelf. But we are unable to make a facet value for
  // Self with GetConstantFacetValueForTypeAndInterface() as we have no witness
  // for the interface, because we don't have a CustomWitness instruction yet.
  // To do so, we need to move the witness table out of the CustomWitness
  // instruction, so that we can reorder things. Then we can make the
  // CustomWitness inst first, and mutate the table as we build up the entries
  // for it. For now, we use the InterfaceId and Interface-without-Self
  // specific, and store the self TypeId separately instead.
  auto specific_interface_id =
      context.specific_interfaces().Add(core_specific_interface);

  return SemIR::GeneratedFunction::CanonicalKey{specific_interface_id,
                                                self_type_id, op_name_id};
}
// Attempts to return the canonical Function for a generated function.
//
// On success, returns the Decl and Function IDs of the canonical Function.
// Otherwise, it returns None for those IDs.
static auto TryGetGeneratedFunction(Context& context,
                                    SemIR::GeneratedFunction::CanonicalKey key)
    -> std::pair<SemIR::InstId, SemIR::FunctionId> {
  if (auto generated_id = context.generated_functions().Lookup(key);
      generated_id.has_value()) {
    const auto& generated = context.generated_functions().Get(generated_id);
    return {generated.decl_id, generated.function_id};
  }
  return {SemIR::InstId::None, SemIR::FunctionId::None};
}

static auto MakeCoreSpecificInterface(
    Context& context, SemIR::LocId loc_id, SemIR::InterfaceId interface_id,
    SemIR::GenericId interface_generic_id,
    llvm::ArrayRef<SemIR::TypeId> param_types_without_self)
    -> SemIR::SpecificInterface {
  llvm::SmallVector<SemIR::InstId> params_without_self(
      llvm::map_range(param_types_without_self, [&](SemIR::TypeId type_id) {
        return context.types().GetTypeInstId(type_id);
      }));
  CARBON_CHECK(!params_without_self.empty() ==
               interface_generic_id.has_value());
  auto specific_id = SemIR::SpecificId::None;
  if (!params_without_self.empty()) {
    specific_id = MakeSpecific(context, loc_id, interface_generic_id,
                               params_without_self);
  }
  return {interface_id, specific_id};
}

// Returns a manufactured operator function.
auto MakeBuiltinOperatorFunction(Context& context, SemIR::LocId loc_id,
                                 llvm::ArrayRef<SemIR::TypeId> param_types,
                                 SemIR::TypeId return_type_id,
                                 CoreIdentifier op_name,
                                 SemIR::BuiltinFunctionKind builtin_kind,
                                 SemIR::InterfaceId interface_id)
    -> SemIR::InstId {
  CARBON_CHECK(!param_types.empty());
  auto self_type_id = param_types.consume_front();
  auto name_id = context.core_identifiers().AddNameId(op_name);
  const auto& interface = context.interfaces().Get(interface_id);
  auto specific_interface = MakeCoreSpecificInterface(
      context, loc_id, interface_id, interface.generic_id, param_types);
  auto canonical_key = MakeGeneratedFunctionKey(context, specific_interface,
                                                self_type_id, name_id);
  auto [decl_id, function_id] = TryGetGeneratedFunction(context, canonical_key);
  if (!decl_id.has_value()) {
    llvm::SmallVector<ParamPatternKind> param_kinds(param_types.size(),
                                                    ParamPatternKind::Value);
    std::tie(decl_id, function_id) = MakeGeneratedFunctionDecl(
        context, SemIR::LocId::None,
        {.parent_scope_id = interface.scope_with_self_id,
         .name_id = name_id,
         .self_type_id = self_type_id,
         .self_kind = ParamPatternKind::Value,
         .param_type_ids = param_types,
         .param_kinds = param_kinds,
         .return_form =
             ReturnExprAsForm(context, SemIR::LocId::None,
                              context.types().GetTypeInstId(return_type_id))});
    auto& function = context.functions().Get(function_id);
    function.SetGenerated(context.generated_functions().Add(
        {.canonical_key = canonical_key,
         .function_id = function_id,
         .decl_id = decl_id,
         .builtin_function_kind = builtin_kind}));
  }

  return decl_id;
}

// Returns a FacetType that contains only the query interface.
static auto GetFacetTypeForQuerySpecificInterface(
    Context& context, SemIR::LocId loc_id,
    SemIR::SpecificInterface query_specific_interface) -> SemIR::ConstantId {
  // The Self facet will have type FacetType, for the query interface.
  auto const_id = EvalOrAddInst<SemIR::FacetType>(
      context, loc_id,
      FacetTypeFromInterface(context, query_specific_interface.interface_id,
                             query_specific_interface.specific_id));
  return const_id;
}

// Starts a block for lookup-related instructions, and returns the `FacetType`
// for lookups in `HasWitnessForRepeatedField`.
static auto PrepareForHasWitness(
    Context& context, SemIR::LocId loc_id,
    SemIR::SpecificInterface query_specific_interface) -> SemIR::ConstantId {
  context.inst_block_stack().Push();
  StartGenericDecl(context);

  return GetFacetTypeForQuerySpecificInterface(context, loc_id,
                                               query_specific_interface);
}

// Cleans up state `PrepareForHasWitness`.
static auto CleanupAfterHasWitness(Context& context) -> void {
  DiscardGenericDecl(context);
  context.inst_block_stack().PopAndDiscard();
}

// Returns true if `type_inst_id` has a witness for the query interface, which
// comes from `PrepareForHasWitness`.
static auto HasWitnessForRepeatedField(
    Context& context, SemIR::LocId loc_id, SemIR::InstId type_inst_id,
    SemIR::ConstantId query_facet_type_const_id) -> bool {
  auto type_const_id = context.constant_values().Get(type_inst_id);
  auto block_or_err = LookupImplWitness(context, loc_id, type_const_id,
                                        query_facet_type_const_id);
  return block_or_err.has_value();
}

// The format for `Destroy.Op`.
enum class DestroyFormat {
  NoDestroy,
  Trivial,
  NonTrivial,
};

// Returns true if the type is known to have trivial destruction.
static auto IsBuiltinWithTrivialDestruction(Context& context,
                                            SemIR::InstId inst_id) -> bool {
  CARBON_KIND_SWITCH(context.insts().Get(inst_id)) {
    case SemIR::BoolType::Kind:
    case SemIR::CppFunctionPointerType::Kind:
    case SemIR::FacetType::Kind:
    case SemIR::FloatType::Kind:
    case SemIR::FormType::Kind:
    case SemIR::FunctionType::Kind:
    case SemIR::IntLiteralType::Kind:
    case SemIR::IntType::Kind:
    case SemIR::PointerType::Kind:
      // Trivially destructible.
      return true;
    default:
      return false;
  }
}

// Similar to `HasWitnessForRepeatedField`, but for cases where there's only one
// field, this can handle the call to `PrepareForHasWitness`.
static auto HasWitnessForOneField(
    Context& context, SemIR::LocId loc_id, SemIR::InstId field_inst_id,
    SemIR::SpecificInterface query_specific_interface) -> DestroyFormat {
  if (IsBuiltinWithTrivialDestruction(context, field_inst_id)) {
    return DestroyFormat::Trivial;
  }

  auto query_facet_type_const_id =
      PrepareForHasWitness(context, loc_id, query_specific_interface);
  auto has_witness = HasWitnessForRepeatedField(context, loc_id, field_inst_id,
                                                query_facet_type_const_id);
  CleanupAfterHasWitness(context);
  return has_witness ? DestroyFormat::NonTrivial : DestroyFormat::NoDestroy;
}

// Defined below with the other impl-population scans.
static auto HasClassKeyedImpl(Context& context, SemIR::ClassType class_type,
                              SemIR::CoreInterface core_interface,
                              bool outside_core_only) -> bool;

// Returns true if `class_type` should impl `Destroy`. `query_is_symbolic` is
// whether the QUERY constant is symbolic — the same
// `query_self_const_id.is_symbolic()` fact `LookupDestroyWitness` branches on
// to defer witness BUILDING, threaded down from the `CanDestroyType` entry so
// that yes/no and build/defer key on one predicate (fork/b2/plan.md §2.2).
static auto CanDestroyClass(Context& context, SemIR::LocId loc_id,
                            SemIR::ClassType class_type,
                            const SemIR::CompleteTypeInfo& complete_info,
                            SemIR::SpecificInterface query_specific_interface,
                            bool is_partial, bool query_is_symbolic)
    -> DestroyFormat {
  // Abstract classes can't be destroyed.
  if (!is_partial && complete_info.IsAbstract()) {
    return DestroyFormat::NoDestroy;
  }

  auto class_info = context.classes().Get(class_type.class_id);

  // `LookupCppImpl` handles C++ types.
  if (context.name_scopes().Get(class_info.scope_id).is_cpp_scope()) {
    return DestroyFormat::NoDestroy;
  }

  // Fork (SL-1, fork/slices/plan.md R-12): a class that declares its own
  // `Destroy` impl — in its body or out of class, concrete or `forall` over
  // its own parameters, in this file or in its defining library — is
  // destroyed by that impl, never by the synthesized witness. Impl lookup
  // consults the custom witness FIRST and considers declared impls only when
  // it declines (impl_lookup.cpp, `EvalLookupSingleFinalWitness`), so the
  // yield is this `NoDestroy`: `LookupDestroyWitness` then answers `nullopt`
  // and lookup selects the declared impl (`impl forall [T: Copy & Destroy]
  // Buf(T) as Destroy` for `Buf(i32)`). The scan is keyed on the CLASS, not
  // on `HasUserDestroyImpl`'s symbolic-self shortcut: a blanket `impl forall
  // [T: type] T as Destroy` in scope must not disable the witness for every
  // class. A `partial` self is excepted — the declared impl's self is the
  // class type, which a `partial` query never matches, so a base subobject
  // keeps the synthesized witness. An impl declared textually AFTER a
  // concrete lookup in the same file is not seen by that lookup (the
  // custom-witness result is not poison-tracked); the design's in-class
  // spelling (classes.md) never hits this.
  if (!is_partial &&
      HasClassKeyedImpl(context, class_type, SemIR::CoreInterface::Destroy,
                        /*outside_core_only=*/false)) {
    return DestroyFormat::NoDestroy;
  }

  // Fork (W-071 discharge, fork/b2/plan.md §2.2): a `choice` specific under a
  // symbolic query is destroyable, answered STRUCTURALLY rather than by the
  // object-repr field walk below. The justification is SF-6's per-specific
  // payload guarantee: every INSTANTIABLE specific of a payload-carrying
  // choice passes the scalar payload allowlist (`IsInSliceChoicePayloadType`),
  // enforced at monomorphization by the `CustomLayoutType` eval hook
  // (`ChoicePayloadNotTrivialInSpecific`), so the elements the field walk
  // would check are guaranteed destroyable in every specific that can
  // actually exist. The walk itself cannot run here: under symbolic arguments
  // the repr is the dependent-layout sentinel (or a partially substituted
  // `CustomLayoutType`), which is exactly the walk that fails. The answer is
  // `NonTrivial`, never `Trivial`: it is only ever consumed as a yes/no —
  // `LookupDestroyWitness` declines to BUILD a witness for symbolic selves,
  // and each concrete monomorphization re-derives the real format from its
  // concrete fields (the S1 admitted-exception adapter shape — a payload
  // adapter with a user `Core.Destroy` impl — makes the concrete choice
  // genuinely `NonTrivial`: the field walk finds the adapter's DECLARED
  // witness through impl lookup, so a cached `Trivial` would be wrong for
  // it). Concrete choice specifics take the unchanged field walk below.
  //
  // W-071 revisit note: this structural trust is valid exactly while SF-6's
  // per-specific allowlist holds and choice-payload destroy synthesis stays a
  // placeholder (the `is_choice` and `CustomLayoutType` clauses of
  // `MakeSubobjectDestroyOpBody`, D-UA-9). When SF-6 widens past trivially
  // destructible payloads or real destroy synthesis lands, this clause must
  // become a real per-element witness check under the symbolic arguments — and
  // note the predicate keys on the ORIGINAL query constant while the class
  // dispatch keys on the canonical facet-or-type value: unobservable while the
  // answer is a bare yes/no, but the spot where yes/no and a real per-element
  // walk could diverge once this clause does structural work.
  if (class_info.is_choice && query_is_symbolic) {
    return DestroyFormat::NonTrivial;
  }

  auto object_repr_id =
      class_info.GetAdaptedType(context.sem_ir(), class_type.specific_id);
  if (!object_repr_id.has_value()) {
    object_repr_id =
        class_info.GetObjectRepr(context.sem_ir(), class_type.specific_id);
  }

  auto has_witness = HasWitnessForOneField(
      context, loc_id, context.types().GetTypeInstId(object_repr_id),
      query_specific_interface);
  if (has_witness == DestroyFormat::NoDestroy) {
    return DestroyFormat::NoDestroy;
  }

  if (class_info.GetStructTypeFields(context.sem_ir(), class_type.specific_id)
          .empty()) {
    return DestroyFormat::Trivial;
  }

  // TODO: check that a class' base has trivial destruction.
  // TODO: check that a class' subobjects have trivial destruction.

  return DestroyFormat::NonTrivial;
}

// Returns true if the `Self` should impl `Destroy`. This will recurse into impl
// lookup of `Destroy` for members, similar to `where .Self.members each impls
// Destroy`.
static auto CanDestroyType(Context& context, SemIR::LocId loc_id,
                           SemIR::ConstantId query_self_const_id,
                           SemIR::SpecificInterface query_specific_interface)
    -> DestroyFormat {
  auto inst_id = context.constant_values().GetInstId(
      GetCanonicalFacet(context, query_self_const_id));

  if (IsBuiltinWithTrivialDestruction(context, inst_id)) {
    return DestroyFormat::Trivial;
  }

  auto inst = context.insts().Get(inst_id);
  if (context.types().IsConstrainedFacetType(inst.type_id())) {
    // The value's type is a symbolic constrained facet. We don't provide a
    // custom witness for constrained facets. The witness must be found in the
    // constraints by impl lookup.
    CARBON_CHECK(query_self_const_id.is_symbolic());
    return DestroyFormat::NoDestroy;
  }

  // Incomplete types can not be destroyed.
  auto type_id = context.types().GetTypeIdForTypeInstId(inst_id);
  if (!TryToCompleteType(context, type_id, loc_id)) {
    return DestroyFormat::NoDestroy;
  }

  CARBON_KIND_SWITCH(inst) {
    case SemIR::ImplWitnessAccess::Kind:
    case SemIR::SymbolicBinding::Kind: {
      // A symbolic facet of type `type`. Such symbolic values can't be
      // destroyed.
      return DestroyFormat::NoDestroy;
    }

    case CARBON_KIND(SemIR::ArrayType array_type): {
      // A zero element array is always trivially destructible.
      if (auto int_bound =
              context.sem_ir().GetZExtIntValue(array_type.bound_id);
          !int_bound || *int_bound == 0) {
        return DestroyFormat::Trivial;
      }

      // Verify the element can be destroyed.
      return HasWitnessForOneField(context, loc_id,
                                   array_type.element_type_inst_id,
                                   query_specific_interface);
    }

    case SemIR::Call::Kind:
      // Dependent type constructor calls that cannot be resolved under the
      // generic context.
      return DestroyFormat::NoDestroy;

    case CARBON_KIND(SemIR::ClassType class_type): {
      return CanDestroyClass(context, loc_id, class_type,
                             context.types().GetCompleteTypeInfo(type_id),
                             query_specific_interface,
                             /*is_partial=*/false,
                             query_self_const_id.is_symbolic());
    }

    case CARBON_KIND(SemIR::ConstType const_type): {
      return HasWitnessForOneField(context, loc_id, const_type.inner_id,
                                   query_specific_interface);
    }

    case CARBON_KIND(SemIR::MaybeUnformedType maybe_unformed_type): {
      return HasWitnessForOneField(context, loc_id,
                                   maybe_unformed_type.inner_id,
                                   query_specific_interface);
    }

    case CARBON_KIND(SemIR::PartialType partial_type): {
      // In contrast with something like `const`, need to treat the inner
      // class differently based on the `partial` modifier.
      auto class_type =
          context.insts().GetAs<SemIR::ClassType>(partial_type.inner_id);
      return CanDestroyClass(context, loc_id, class_type,
                             context.types().GetCompleteTypeInfo(type_id),
                             query_specific_interface,
                             /*is_partial=*/true,
                             query_self_const_id.is_symbolic());
    }

    case CARBON_KIND(SemIR::StructType struct_type): {
      auto fields = context.struct_type_fields().Get(struct_type.fields_id);
      if (fields.empty()) {
        return DestroyFormat::Trivial;
      }
      auto query_facet_type_const_id =
          PrepareForHasWitness(context, loc_id, query_specific_interface);
      bool has_witness = true;
      for (const auto& field : fields) {
        if (!HasWitnessForRepeatedField(context, loc_id, field.type_inst_id,
                                        query_facet_type_const_id)) {
          has_witness = false;
          break;
        }
      }
      CleanupAfterHasWitness(context);
      return has_witness ? DestroyFormat::NonTrivial : DestroyFormat::NoDestroy;
    }

    case CARBON_KIND(SemIR::CustomLayoutType custom_layout_type): {
      // A native custom-layout type is the payload region of a
      // payload-carrying choice, whose fields are restricted to trivially
      // destructible payload tuples at completion time, or the object
      // representation of a native `union`, whose fields are restricted to
      // trivially destructible and copyable types; mirror the struct handling
      // over the overlapping fields. (C++ imported classes don't get here:
      // `CanDestroyClass` returns early for C++ scopes.)
      auto fields =
          context.struct_type_fields().Get(custom_layout_type.fields_id);
      if (fields.empty()) {
        return DestroyFormat::Trivial;
      }
      auto query_facet_type_const_id =
          PrepareForHasWitness(context, loc_id, query_specific_interface);
      bool has_witness = true;
      for (const auto& field : fields) {
        if (!HasWitnessForRepeatedField(context, loc_id, field.type_inst_id,
                                        query_facet_type_const_id)) {
          has_witness = false;
          break;
        }
      }
      CleanupAfterHasWitness(context);
      return has_witness ? DestroyFormat::NonTrivial : DestroyFormat::NoDestroy;
    }

    case CARBON_KIND(SemIR::TupleType tuple_type): {
      auto block = context.inst_blocks().Get(tuple_type.type_elements_id);
      if (block.empty()) {
        return DestroyFormat::Trivial;
      }
      auto query_facet_type_const_id =
          PrepareForHasWitness(context, loc_id, query_specific_interface);
      bool has_witness = true;
      for (const auto& element_id : block) {
        if (!HasWitnessForRepeatedField(context, loc_id, element_id,
                                        query_facet_type_const_id)) {
          has_witness = false;
          break;
        }
      }
      CleanupAfterHasWitness(context);
      return has_witness ? DestroyFormat::NonTrivial : DestroyFormat::NoDestroy;
    }

    default:
      CARBON_FATAL("Unexpected type for CanDestroyType: {0}", inst.kind());
  }
}

// Returns true if the interface is the given core interface (such as
// `Core.Destroy`) in the given (possibly imported) IR: the read-only, per-file
// mirror of `GetCoreInterface` — the `core_interface` tag is assigned only to
// interfaces declared in package Core (handle_interface.cpp) and propagates
// through import (import_ref.cpp), and the Core-package parent-scope and
// identifier checks match `GetCoreInterface`'s.
static auto IsCoreInterfaceInFile(const SemIR::File& sem_ir,
                                  SemIR::InterfaceId interface_id,
                                  SemIR::CoreInterface core_interface) -> bool {
  if (!interface_id.has_value()) {
    // An error occurred when type-checking the impl (the same skip
    // `ImportImplFilter::IsRelevantImpl` applies).
    return false;
  }
  const auto& interface = sem_ir.interfaces().Get(interface_id);
  return interface.core_interface == core_interface &&
         sem_ir.name_scopes().IsCorePackage(interface.parent_scope_id) &&
         interface.name_id.AsIdentifierId().has_value();
}

// Returns true if a user-declared `impl` of `Core.Destroy` covers the given
// class (`self_const_id` is the class type's constant in this file). This
// mirrors, read-only, the impl population the destroy lookup's candidate
// collection draws from (`CollectCandidateImplsForQuery`,
// check/impl_lookup.cpp): the local impl store PLUS every imported IR's impl
// store. The collection materializes relevant imported impls with
// `ImportImpl` and then matches them through the local store's canonical
// constants; this scan needs only existence — no witness — so it matches
// each imported store in place and materializes nothing:
//   - interface identity across IRs by `IsCoreInterfaceInFile` above;
//   - self identity across IRs by canonical defining declaration: two class
//     types in different IRs denote the same class iff their defining decls
//     canonicalize to the same (file, inst) pair (`GetCanonicalFileAndInstId`,
//     sem_ir/import_ir.cpp) — the identity import deduplication itself
//     verifies (`VerifySameCanonicalImportIRInst`).
// Divergences from the collection, both in the conservative (non-trivial)
// direction: ALL import IRs are walked, a superset of its
// orphan-rule-filtered `FindAssociatedImportIRs` set; and a symbolic impl
// self that is NOT a class type (a blanket `impl forall [T: type] T as
// Destroy`, local or imported) is treated as covering without a structure
// match. A symbolic self that IS a class type — `impl forall [T] MyBox(T) as
// Destroy`, or the prelude's in-class `impl as Destroy` of `Core.Buf(T)` —
// is keyed on its class exactly like a concrete self: a specific of another
// class is never this class, so it does not cover it. (Amended 2026-10-05,
// SL-1 round 4: with the shortcut applied to EVERY symbolic self, `Buf(T)`'s
// impl — in every file's import set through the prelude — put every class
// outside the trivially-destructible set, `i32` included since it is the
// class `Int(32)`, breaking the union field rule and the C++ export
// predicate.) Known same-file ordering hole: an impl textually after the
// class's first clang completion is not yet in the local store when this
// scan runs, where real lookup would poison and diagnose the
// use-before-declaration.
//
// This is the EXPORT predicate's scan, deliberately broader than the destroy
// lookup's own yield (`CanDestroyClass` → `HasClassKeyedImpl`, which keys on
// the class and ignores blanket impls): a class covered by any user `Destroy`
// impl, blanket or class-keyed, declares destruction work and stays out of
// the trivially-destructible set, so the exported record's triviality is
// identical across the defining and importing TUs. Since SL-1 a class-keyed
// user impl is selected by destroy lookup and its `Op` runs at scope exit;
// the synthesized `SubobjectDestroy.Op` of a choice or union holding such a
// class is still a placeholder (D-UA-9's clauses in
// `MakeSubobjectDestroyOpBody`), which runs no member destructors.
static auto HasUserDestroyImpl(Context& context, SemIR::ClassType class_type,
                               const SemIR::Class& class_info) -> bool {
  // The local store: impls declared in this file, plus any already
  // materialized here from imports (whose classes are deduplicated into this
  // file's class store, so `class_id` identity holds for them too).
  for (auto [_, impl] : context.impls().enumerate()) {
    if (!impl.interface.interface_id.has_value() ||
        GetCoreInterface(context, impl.interface.interface_id) !=
            SemIR::CoreInterface::Destroy) {
      continue;
    }
    auto impl_self_const_id = context.constant_values().Get(impl.self_id);
    if (!impl_self_const_id.has_value()) {
      continue;
    }
    if (auto impl_self_class_type = context.insts().TryGetAs<SemIR::ClassType>(
            context.constant_values().GetInstId(impl_self_const_id))) {
      // Class-keyed: concrete, or a symbolic specific of the class.
      if (impl_self_class_type->class_id == class_type.class_id) {
        return true;
      }
      continue;
    }
    if (impl_self_const_id.is_symbolic()) {
      // A blanket impl covers every class.
      return true;
    }
  }

  // The imported stores, matched in place. The queried class's canonical
  // identity is its defining file and declaration.
  std::pair<const SemIR::File*, SemIR::InstId> class_canonical = {
      nullptr, SemIR::InstId::None};
  if (class_info.first_owning_decl_id.has_value()) {
    class_canonical = SemIR::GetCanonicalFileAndInstId(
        &context.sem_ir(), class_info.first_owning_decl_id);
  }
  for (const auto& import_ir : context.import_irs().values()) {
    // Skips the `None` and `Cpp` slots; C++ code cannot declare a
    // `Core.Destroy` impl.
    if (import_ir.sem_ir == nullptr) {
      continue;
    }
    const auto& import_sem_ir = *import_ir.sem_ir;
    for (auto [_, impl] : import_sem_ir.impls().enumerate()) {
      if (!IsCoreInterfaceInFile(import_sem_ir, impl.interface.interface_id,
                                 SemIR::CoreInterface::Destroy)) {
        continue;
      }
      auto impl_self_const_id =
          import_sem_ir.constant_values().Get(impl.self_id);
      if (!impl_self_const_id.has_value()) {
        continue;
      }
      auto self_inst_id =
          import_sem_ir.constant_values().GetInstId(impl_self_const_id);
      auto self_class_type =
          import_sem_ir.insts().TryGetAs<SemIR::ClassType>(self_inst_id);
      if (!self_class_type) {
        if (impl_self_const_id.is_symbolic()) {
          // A blanket impl covers every class.
          return true;
        }
        // A concrete non-class self (a tuple, a pointer, ...) is not a class.
        continue;
      }
      if (class_canonical.first == nullptr) {
        // A class without an owning declaration cannot be named by an
        // imported impl; only the blanket case above can cover it.
        continue;
      }
      // A class-typed impl self — concrete or a symbolic specific — covers
      // the class iff its defining declaration canonicalizes to the queried
      // class's.
      const auto& impl_class =
          import_sem_ir.classes().Get(self_class_type->class_id);
      if (!impl_class.first_owning_decl_id.has_value()) {
        continue;
      }
      if (SemIR::GetCanonicalFileAndInstId(&import_sem_ir,
                                           impl_class.first_owning_decl_id) ==
          class_canonical) {
        return true;
      }
    }
  }
  return false;
}

// Returns true if a declared `impl` of the given core interface covers the
// given class: an impl whose self is a `ClassType` of the same class —
// concrete, or a symbolic specific of it (`impl forall [T] MyBox(T) as Copy`
// covers a `MyBox(i32)` field; `impl as Destroy` inside `class Buf(T)` covers
// `Buf(i32)`). Class-keyed, deliberately NOT `HasUserDestroyImpl`'s
// symbolic-self shortcut: the prelude declares several blanket `Core.Copy`
// impls (`T*`, `const T`, `Int(N)`, `Optional(T)`, ...), so "any
// symbolic-self impl in scope" would disqualify every class.
//
// With `outside_core_only`, impls declared in package `Core` do not count —
// the package of the DECLARING file is the trust boundary of the union field
// rule (docs/design/unions.md, "Trivially destructible and trivially copyable
// types", 0.1 note): the prelude's `Copy` impls over trivially destructible
// shapes are bitwise by construction, so only impls declared by the program
// count as user-provided, bodied or builtin alike. The destroy lookup's
// yield (`CanDestroyClass`) passes false: the prelude's own `Core.Buf(T)`
// frees its block through its declared impl. Walks the same two impl
// populations as `HasUserDestroyImpl`: the local store, where an impl that
// import materialized here (its first declaration has an import source; its
// `parent_scope_id` is `None`, so a scope-based test would misclassify it)
// is skipped because its defining file classifies it in the imported leg; and
// every imported IR's store, matched in place by canonical defining
// declaration — read-only, materializing nothing (`ImportImpl` would add
// `import_ref`s to every file that destroys a class).
static auto HasClassKeyedImpl(Context& context, SemIR::ClassType class_type,
                              SemIR::CoreInterface core_interface,
                              bool outside_core_only) -> bool {
  const auto& class_info = context.classes().Get(class_type.class_id);

  // The local store: impls declared in this file.
  if (!outside_core_only ||
      context.sem_ir().package_id() != PackageNameId::Core) {
    for (auto [_, impl] : context.impls().enumerate()) {
      if (!impl.interface.interface_id.has_value() ||
          GetCoreInterface(context, impl.interface.interface_id) !=
              core_interface) {
        continue;
      }
      if (context.insts().GetImportSource(impl.first_decl_id()).has_value()) {
        // Materialized from an import; classified by its defining file below.
        continue;
      }
      auto impl_self_const_id = context.constant_values().Get(impl.self_id);
      if (!impl_self_const_id.has_value()) {
        continue;
      }
      auto impl_self_class_type = context.insts().TryGetAs<SemIR::ClassType>(
          context.constant_values().GetInstId(impl_self_const_id));
      if (impl_self_class_type &&
          impl_self_class_type->class_id == class_type.class_id) {
        return true;
      }
    }
  }

  // The imported stores, matched in place. The queried class's canonical
  // identity is its defining file and declaration.
  if (!class_info.first_owning_decl_id.has_value()) {
    // A class without an owning declaration cannot be named by an imported
    // impl.
    return false;
  }
  auto class_canonical = SemIR::GetCanonicalFileAndInstId(
      &context.sem_ir(), class_info.first_owning_decl_id);
  for (const auto& import_ir : context.import_irs().values()) {
    // Skips the `None` and `Cpp` slots; C++ code cannot declare an impl of a
    // `Core` interface.
    if (import_ir.sem_ir == nullptr) {
      continue;
    }
    const auto& import_sem_ir = *import_ir.sem_ir;
    if (outside_core_only &&
        import_sem_ir.package_id() == PackageNameId::Core) {
      // The prelude's impls are inside the trust boundary.
      continue;
    }
    for (auto [_, impl] : import_sem_ir.impls().enumerate()) {
      if (!IsCoreInterfaceInFile(import_sem_ir, impl.interface.interface_id,
                                 core_interface)) {
        continue;
      }
      auto impl_self_const_id =
          import_sem_ir.constant_values().Get(impl.self_id);
      if (!impl_self_const_id.has_value()) {
        continue;
      }
      auto self_class_type = import_sem_ir.insts().TryGetAs<SemIR::ClassType>(
          import_sem_ir.constant_values().GetInstId(impl_self_const_id));
      if (!self_class_type) {
        continue;
      }
      const auto& impl_class =
          import_sem_ir.classes().Get(self_class_type->class_id);
      if (!impl_class.first_owning_decl_id.has_value()) {
        continue;
      }
      if (SemIR::GetCanonicalFileAndInstId(&import_sem_ir,
                                           impl_class.first_owning_decl_id) ==
          class_canonical) {
        return true;
      }
    }
  }
  return false;
}

auto HasNonTrivialUserCopyImpl(Context& context, SemIR::TypeId type_id)
    -> bool {
  // Iterative worklist, mirroring `IsTriviallyDestructible`'s walk through
  // arrays, adapters, object representations and aggregates; a class found
  // anywhere in the shape is checked for a user `Core.Copy` impl.
  llvm::SmallVector<SemIR::TypeId> worklist = {type_id};
  while (!worklist.empty()) {
    auto current_id = worklist.pop_back_val();
    auto inst = context.types().GetAsInst(current_id);
    CARBON_KIND_SWITCH(inst) {
      case CARBON_KIND(SemIR::ArrayType array_type): {
        worklist.push_back(context.types().GetTypeIdForTypeInstId(
            array_type.element_type_inst_id));
        continue;
      }

      case CARBON_KIND(SemIR::ClassType class_type): {
        if (HasClassKeyedImpl(context, class_type, SemIR::CoreInterface::Copy,
                              /*outside_core_only=*/true)) {
          return true;
        }
        const auto& class_info = context.classes().Get(class_type.class_id);
        auto object_repr_id =
            class_info.GetAdaptedType(context.sem_ir(), class_type.specific_id);
        if (!object_repr_id.has_value()) {
          object_repr_id = class_info.GetObjectRepr(context.sem_ir(),
                                                    class_type.specific_id);
        }
        if (!object_repr_id.has_value() || !object_repr_id.is_concrete()) {
          // Not a shape this walk knows; the destructible half rejects it.
          continue;
        }
        worklist.push_back(object_repr_id);
        continue;
      }

      case CARBON_KIND(SemIR::ConstType const_type): {
        worklist.push_back(
            context.types().GetTypeIdForTypeInstId(const_type.inner_id));
        continue;
      }

      case CARBON_KIND(SemIR::MaybeUnformedType maybe_unformed_type): {
        worklist.push_back(context.types().GetTypeIdForTypeInstId(
            maybe_unformed_type.inner_id));
        continue;
      }

      case CARBON_KIND(SemIR::StructType struct_type): {
        for (const auto& field :
             context.struct_type_fields().Get(struct_type.fields_id)) {
          worklist.push_back(
              context.types().GetTypeIdForTypeInstId(field.type_inst_id));
        }
        continue;
      }

      case CARBON_KIND(SemIR::CustomLayoutType custom_layout_type): {
        for (const auto& field :
             context.struct_type_fields().Get(custom_layout_type.fields_id)) {
          worklist.push_back(
              context.types().GetTypeIdForTypeInstId(field.type_inst_id));
        }
        continue;
      }

      case CARBON_KIND(SemIR::TupleType tuple_type): {
        llvm::ArrayRef<SemIR::InstId> element_inst_ids =
            context.inst_blocks().Get(tuple_type.type_elements_id);
        for (auto element_type_id :
             context.types().GetBlockAsTypeIds(element_inst_ids)) {
          worklist.push_back(element_type_id);
        }
        continue;
      }

      default:
        // Scalars, pointers and everything else contain no class.
        continue;
    }
  }
  return false;
}

auto HasTrivialClassShapeForExport(const SemIR::Class& class_info) -> bool {
  return !class_info.base_id.has_value() &&
         !class_info.vtable_decl_id.has_value() && !class_info.is_dynamic &&
         class_info.inheritance_kind != SemIR::Class::InheritanceKind::Abstract;
}

auto IsTriviallyDestructible(Context& context, SemIR::TypeId type_id) -> bool {
  // Iterative worklist (upstream lint forbids recursive call chains,
  // misc-no-recursion). Every type popped must itself be trivially
  // destructible; aggregate arms push their element types. Value types are
  // finite, so the walk terminates without a visited set.
  llvm::SmallVector<SemIR::TypeId> worklist = {type_id};
  while (!worklist.empty()) {
    auto current_id = worklist.pop_back_val();
    auto inst = context.types().GetAsInst(current_id);
    CARBON_KIND_SWITCH(inst) {
      case CARBON_KIND(SemIR::ArrayType array_type): {
        // A zero element array is always trivially destructible, matching
        // `CanDestroyType`.
        if (auto int_bound =
                context.sem_ir().GetZExtIntValue(array_type.bound_id);
            int_bound && *int_bound == 0) {
          continue;
        }
        worklist.push_back(context.types().GetTypeIdForTypeInstId(
            array_type.element_type_inst_id));
        continue;
      }

      case CARBON_KIND(SemIR::ClassType class_type): {
        const auto& class_info = context.classes().Get(class_type.class_id);
        // A C++-owned class is destroyed by its imported C++ destructor
        // (`BuildDestroyWitness` in cpp/impl_lookup.cpp); never assume
        // triviality for it.
        if (context.name_scopes().Get(class_info.scope_id).is_cpp_scope()) {
          return false;
        }
        // Choice types have their own destroy handling (`CanDestroyClass`'s
        // choice clause); leave them non-trivial here.
        if (class_info.is_choice) {
          return false;
        }
        // A nested class field passes the same shape gate as the exported
        // class itself (fork/f008/plan.md §2.2: nested classes qualify "under
        // the same predicate"): a base, a vtable, or a dynamic/abstract class
        // is not admitted here even where its destruction would reduce to its
        // members'.
        if (!HasTrivialClassShapeForExport(class_info)) {
          return false;
        }
        if (HasUserDestroyImpl(context, class_type, class_info)) {
          return false;
        }
        // Walk into the adapted type or the object representation — the
        // same dispatch `CanDestroyClass` uses for its member walk.
        auto object_repr_id =
            class_info.GetAdaptedType(context.sem_ir(), class_type.specific_id);
        if (!object_repr_id.has_value()) {
          object_repr_id = class_info.GetObjectRepr(context.sem_ir(),
                                                    class_type.specific_id);
        }
        if (!object_repr_id.has_value() || !object_repr_id.is_concrete()) {
          return false;
        }
        worklist.push_back(object_repr_id);
        continue;
      }

      case CARBON_KIND(SemIR::ConstType const_type): {
        worklist.push_back(
            context.types().GetTypeIdForTypeInstId(const_type.inner_id));
        continue;
      }

      case CARBON_KIND(SemIR::MaybeUnformedType maybe_unformed_type): {
        worklist.push_back(context.types().GetTypeIdForTypeInstId(
            maybe_unformed_type.inner_id));
        continue;
      }

      case CARBON_KIND(SemIR::StructType struct_type): {
        for (const auto& field :
             context.struct_type_fields().Get(struct_type.fields_id)) {
          worklist.push_back(
              context.types().GetTypeIdForTypeInstId(field.type_inst_id));
        }
        continue;
      }

      case CARBON_KIND(SemIR::CustomLayoutType custom_layout_type): {
        // The object representation of a native `union` (or a choice payload
        // region): trivially destructible iff every overlapping field is.
        for (const auto& field :
             context.struct_type_fields().Get(custom_layout_type.fields_id)) {
          worklist.push_back(
              context.types().GetTypeIdForTypeInstId(field.type_inst_id));
        }
        continue;
      }

      case CARBON_KIND(SemIR::TupleType tuple_type): {
        llvm::ArrayRef<SemIR::InstId> element_inst_ids =
            context.inst_blocks().Get(tuple_type.type_elements_id);
        for (auto element_type_id :
             context.types().GetBlockAsTypeIds(element_inst_ids)) {
          worklist.push_back(element_type_id);
        }
        continue;
      }

      case SemIR::BoolType::Kind:
      case SemIR::FloatType::Kind:
      case SemIR::IntLiteralType::Kind:
      case SemIR::IntType::Kind:
      case SemIR::PointerType::Kind:
        // `CanDestroyType`'s scalar `DestroyFormat::Trivial` arm.
        continue;

      default:
        // Everything else (facet types, symbolic types, function types, ...)
        // is not known to be trivially destructible; callers keep their
        // conservative path. Deliberately narrower than `CanDestroyType`'s
        // `Trivial` arm: the non-object types it also classifies (`type`,
        // facet types, `FormType`) cannot be object fields of an exported
        // class.
        return false;
    }
  }
  return true;
}

// Calls `self.<field>.(Destroy.SelfDestruct)` for a field in a `StructType`.
static auto DestroyStructFields(
    Context& context, SemIR::LocId loc_id, SemIR::InstId callee_self_param_id,
    llvm::ArrayRef<SemIR::StructTypeField> struct_fields) -> void {
  for (auto i = static_cast<std::int64_t>(struct_fields.size()) - 1; i >= 0;
       --i) {
    auto member_id = PerformMemberAccess(context, loc_id, callee_self_param_id,
                                         struct_fields[i].name_id);
    auto self_destruct_call = BuildSelfDestructCall(context, member_id);
    DiscardExpr(context, self_destruct_call);
  }
}

// Returns the body for `SubobjectDestroy.Op`.
//
// TODO: This is a placeholder still not actually destroying things, intended to
// maintain mostly-consistent behavior with current logic while working. That
// also means using `self`.
static auto MakeSubobjectDestroyOpBody(Context& context, SemIR::LocId loc_id,
                                       SemIR::InstId callee_self_param_id,
                                       SemIR::TypeId self_type_id) -> void {
  while (self_type_id.has_value()) {
    auto inst = context.types().GetAsInst(self_type_id);
    CARBON_KIND_SWITCH(inst) {
      case CARBON_KIND(SemIR::ArrayType array_type): {
        auto size = context.ints()
                        .Get(context.insts()
                                 .GetAs<SemIR::IntValue>(array_type.bound_id)
                                 .int_id)
                        .getSExtValue();
        auto index_type_id =
            GetSingletonType(context, SemIR::IntLiteralType::TypeInstId);

        // TODO: Significantly reduce how much SemIR we output by replacing O(N)
        // calls to `Destroy.SelfDestruct` loop over the array that calls the
        // method in its body.
        //
        // We probably need to use `StartLoopHeader`, `BranchAndStartLoopBody`,
        // and `FinishLoopBody`, which are currently private functions in
        // `/toolchain/check/handle_loop_statement.cpp`.
        while (--size >= 0) {
          auto int_id = context.ints().Add(size);
          auto index_id = AddInst(
              context, loc_id,
              SemIR::IntValue{.type_id = index_type_id, .int_id = int_id});
          auto element_id = AddInst<SemIR::ArrayIndex>(
              context, loc_id,
              {.type_id = context.types().GetTypeIdForTypeInstId(
                   array_type.element_type_inst_id),
               .array_id = callee_self_param_id,
               .index_id = index_id});
          BuildSelfDestructCall(context, element_id);
        }
        return;
      }
      case CARBON_KIND(SemIR::ClassType class_type): {
        auto class_info = context.classes().Get(class_type.class_id);
        if (class_info.is_choice) {
          // Fork (D-UA-9, W-083): a choice's repr fields
          // (`ChoiceDiscriminant`, `ChoicePayload`) are not scope members, so
          // the field walk below cannot name them; payload destructors do not
          // run — placeholder semantics preserved. TODO: choice-payload
          // destroy synthesis (D-UA-15 residue).
          return;
        }
        auto access_context =
            llvm::SaveAndRestore(context.access_context(),
                                 SemIR::NameScopeId::AllowHighestAccessLevel);

        DestroyStructFields(
            context, loc_id, callee_self_param_id,
            class_info
                .GetStructTypeFields(context.sem_ir(), class_type.specific_id)
                .drop_while([](SemIR::StructTypeField struct_field) {
                  return struct_field.name_id == SemIR::NameId::Vptr;
                }));
        return;
      }
      case CARBON_KIND(SemIR::ConstType const_type): {
        self_type_id =
            context.types().GetTypeIdForTypeInstId(const_type.inner_id);
        break;
      }
      case CARBON_KIND(SemIR::CustomLayoutType custom_layout_type): {
        // Fork (D-UA-9, W-083): a native custom-layout type is a choice
        // payload region or a union representation; its fields are restricted
        // to trivially destructible types (SF-6 allowlist, D-UN-2), so nothing
        // runs — placeholder semantics preserved. TODO: choice-payload destroy
        // synthesis (D-UA-15).
        (void)custom_layout_type;
        return;
      }
      case CARBON_KIND(SemIR::MaybeUnformedType maybe_unformed_type): {
        // TODO: implement destruction for `Core.MaybeUnformed(T)`.
        (void)maybe_unformed_type;
        return;
      }
      case CARBON_KIND(SemIR::PartialType partial_type): {
        // TODO: implement destruction for partial types.
        (void)partial_type;
        return;
      }
      case CARBON_KIND(SemIR::StructType struct_type): {
        DestroyStructFields(
            context, loc_id, callee_self_param_id,
            context.struct_type_fields().Get(struct_type.fields_id));
        return;
      }
      case CARBON_KIND(SemIR::TupleType tuple_type): {
        auto tuple_elements =
            context.inst_blocks().Get(tuple_type.type_elements_id);
        CARBON_CHECK(!tuple_elements.empty(),
                     "empty tuples should be trivially destructible");

        for (auto i = static_cast<std::int64_t>(tuple_elements.size()) - 1;
             i >= 0; --i) {
          auto int_id = context.ints().Add(i);
          BuildSelfDestructCall(
              context,
              PerformTupleAccess(
                  context, loc_id, callee_self_param_id,
                  AddInst(context, loc_id,
                          SemIR::IntValue{
                              .type_id = GetSingletonType(
                                  context, SemIR::IntLiteralType::TypeInstId),
                              .int_id = int_id})));
        }
        return;
      }
      default: {
        CARBON_FATAL("Unexpected type for MakeSubobjectDestroyOpBody: {0}",
                     inst);
      }
    }
  }
}

// Returns a manufactured `Destroy.Op` function with the `self` parameter typed
// to `self_type_id`.
static auto MakeDestroyOpFunction(Context& context, SemIR::LocId loc_id,
                                  SemIR::TypeId self_type_id,
                                  SemIR::InterfaceId interface_id)
    -> SemIR::InstId {
  auto name_id = context.core_identifiers().AddNameId(CoreIdentifier::Op);

  const auto& interface = context.interfaces().Get(interface_id);
  auto specific_interface = MakeCoreSpecificInterface(
      context, loc_id, interface_id, interface.generic_id, {});
  auto canonical_key = MakeGeneratedFunctionKey(context, specific_interface,
                                                self_type_id, name_id);
  auto [decl_id, function_id] = TryGetGeneratedFunction(context, canonical_key);
  if (!decl_id.has_value()) {
    std::tie(decl_id, function_id) = MakeGeneratedFunctionDecl(
        context, loc_id,
        {.parent_scope_id = interface.scope_with_self_id,
         .name_id = name_id,
         .self_type_id = self_type_id,
         .self_kind = ParamPatternKind::Ref});
    auto& function = context.functions().Get(function_id);
    function.SetGenerated(context.generated_functions().Add(
        {.canonical_key = canonical_key,
         .function_id = function_id,
         .decl_id = decl_id,
         .builtin_function_kind = SemIR::BuiltinFunctionKind::NoOp}));
  }

  return decl_id;
}

static auto MakeSubobjectDestroyOpFunction(
    Context& context, SemIR::LocId loc_id, SemIR::TypeId self_type_id,
    SemIR::InterfaceId interface_id, DestroyFormat format) -> SemIR::InstId {
  // TODO: replace with `CoreIdentifier::Op` when `require impls` adds a witness
  // table entry.
  auto name_id =
      context.core_identifiers().AddNameId(CoreIdentifier::SubobjectDestroy);
  const auto& interface = context.interfaces().Get(interface_id);
  auto specific_interface = MakeCoreSpecificInterface(
      context, loc_id, interface_id, interface.generic_id, {});
  auto canonical_key = MakeGeneratedFunctionKey(context, specific_interface,
                                                self_type_id, name_id);

  auto [decl_id, function_id] = TryGetGeneratedFunction(context, canonical_key);
  if (!decl_id.has_value()) {
    std::tie(decl_id, function_id) = MakeGeneratedFunctionDecl(
        context, loc_id,
        {.parent_scope_id = interface.scope_with_self_id,
         .name_id = name_id,
         .self_type_id = self_type_id,
         .self_kind = ParamPatternKind::Ref});

    auto& function = context.functions().Get(function_id);

    auto builtin_kind = SemIR::BuiltinFunctionKind::None;
    switch (format) {
      case DestroyFormat::Trivial:
        builtin_kind = SemIR::BuiltinFunctionKind::NoOp;
        break;
      case DestroyFormat::NonTrivial: {
        // TODO: should we make a NameRef for `self`?
        auto call_params = context.inst_blocks().Get(function.call_params_id);
        CARBON_CHECK(
            call_params.size() == 1,
            "`Core.SubobjectDestroy.Op` should only have `ref self` as its "
            "parameter");
        context.inst_block_stack().Push();
        StartFunctionDefinition(context, decl_id, function_id);
        MakeSubobjectDestroyOpBody(context, loc_id, call_params[0],
                                   self_type_id);
        BuildReturnWithNoExpr(context, loc_id);
        FinishFunctionDefinition(context, function_id);
        context.inst_block_stack().Pop();
        break;
      }
      case DestroyFormat::NoDestroy:
        CARBON_FATAL("unexpected DestroyFormat::NoDestroy");
    }

    function.SetGenerated(context.generated_functions().Add(
        {.canonical_key = canonical_key,
         .function_id = function_id,
         .decl_id = decl_id,
         .builtin_function_kind = builtin_kind}));
  }
  return decl_id;
}

// Returns a manufactured `Destroy.SelfDestruct` function with the `self`
// parameter typed to `self_type_id`.
static auto MakeDestroySelfDestructFunction(
    Context& context, SemIR::LocId loc_id, SemIR::TypeId self_type_id,
    SemIR::InterfaceId interface_id, SemIR::InstId op_id,
    [[maybe_unused]] SemIR::InstId subobject_destroy_id) -> SemIR::InstId {
  auto name_id =
      context.core_identifiers().AddNameId(CoreIdentifier::SelfDestruct);
  const auto& interface = context.interfaces().Get(interface_id);
  auto specific_interface = MakeCoreSpecificInterface(
      context, loc_id, interface_id, interface.generic_id, {});
  auto canonical_key = MakeGeneratedFunctionKey(context, specific_interface,
                                                self_type_id, name_id);

  auto [decl_id, function_id] = TryGetGeneratedFunction(context, canonical_key);
  if (!decl_id.has_value()) {
    std::tie(decl_id, function_id) = MakeGeneratedFunctionDecl(
        context, loc_id,
        {.parent_scope_id = interface.scope_with_self_id,
         .name_id = name_id,
         .self_type_id = self_type_id,
         .self_kind = ParamPatternKind::Ref});

    auto& function = context.functions().Get(function_id);
    context.inst_block_stack().Push();
    StartFunctionDefinition(context, decl_id, function_id);
    auto params = context.inst_blocks().Get(function.call_params_id);
    CARBON_CHECK(
        params.size() == 1,
        "`Core.Destroy.SelfDestruct` should only have `ref self` as its "
        "parameter");
    op_id = PerformCall(context, loc_id, op_id, {params[0]}, true);
    DiscardExpr(context, op_id);
    subobject_destroy_id =
        PerformCall(context, loc_id, subobject_destroy_id, {params[0]}, true);
    DiscardExpr(context, subobject_destroy_id);
    BuildReturnWithNoExpr(context, loc_id);
    FinishFunctionDefinition(context, function_id);
    context.inst_block_stack().Pop();
    function.SetGenerated(context.generated_functions().Add(
        {.canonical_key = canonical_key,
         .function_id = function_id,
         .decl_id = decl_id,
         .builtin_function_kind = SemIR::BuiltinFunctionKind::None}));
  }
  return decl_id;
}

static auto MakeCustomWitnessConstantInst(
    Context& context, SemIR::LocId loc_id,
    SemIR::SpecificInterface query_specific_interface,
    SemIR::InstBlockId associated_entities_block_id) -> SemIR::InstId {
  // The witness is a CustomWitness of the query interface with a table that
  // contains each associated entity.
  auto const_id = EvalOrAddInst<SemIR::CustomWitness>(
      context, loc_id,
      {.type_id = GetSingletonType(context, SemIR::WitnessType::TypeInstId),
       .elements_id = associated_entities_block_id,
       .query_specific_interface_id =
           context.specific_interfaces().Add(query_specific_interface)});
  return context.constant_values().GetInstId(const_id);
}

struct TypesForSelfFacet {
  // A FacetType that contains only the query interface.
  SemIR::TypeId facet_type_for_query_specific_interface;
  // The query self as a type, which involves a conversion if it was a facet.
  SemIR::TypeId query_self_as_type_id;
};

static auto GetTypesForSelfFacet(
    Context& context, SemIR::LocId loc_id,
    SemIR::ConstantId query_self_const_id,
    SemIR::SpecificInterface query_specific_interface) -> TypesForSelfFacet {
  // The Self facet will have type FacetType, for the query interface.
  auto facet_type_for_query_specific_interface =
      context.types().GetTypeIdForTypeConstantId(
          GetFacetTypeForQuerySpecificInterface(context, loc_id,
                                                query_specific_interface));
  // The Self facet needs to point to a type value. If it's not one already,
  // convert to type.
  auto query_self_as_type_id = GetFacetAccessType(
      context, context.constant_values().GetInstId(query_self_const_id));
  return {facet_type_for_query_specific_interface, query_self_as_type_id};
}

// Build a new facet from the query self, using a CustomWitness for the query
// interface with an entry for each associated entity so far.
static auto MakeSelfFacetWithCustomWitness(
    Context& context, SemIR::LocId loc_id, TypesForSelfFacet query_types,
    SemIR::SpecificInterface query_specific_interface,
    SemIR::InstBlockId associated_entities_block_id) -> SemIR::ConstantId {
  // We are building a facet value for a single interface, so the witness block
  // is a single witness for that interface.
  auto witnesses_block_id = context.inst_blocks().Add(
      {MakeCustomWitnessConstantInst(context, loc_id, query_specific_interface,
                                     associated_entities_block_id)});

  return EvalOrAddInst<SemIR::FacetValue>(
      context, loc_id,
      {.type_id = query_types.facet_type_for_query_specific_interface,
       .type_inst_id =
           context.types().GetTypeInstId(query_types.query_self_as_type_id),
       .witnesses_block_id = witnesses_block_id});
}

auto BuildCustomWitness(Context& context, SemIR::LocId loc_id,
                        SemIR::ConstantId query_self_const_id,
                        SemIR::SpecificInterface query_specific_interface,
                        llvm::ArrayRef<SemIR::InstId> values) -> SemIR::InstId {
  const auto& interface =
      context.interfaces().Get(query_specific_interface.interface_id);
  auto assoc_entities =
      context.inst_blocks().GetOrEmpty(interface.associated_entities_id);
  if (assoc_entities.size() != values.size()) {
    context.TODO(loc_id, ("Unsupported definition of interface " +
                          context.names().GetFormatted(interface.name_id))
                             .str());
    return SemIR::ErrorInst::InstId;
  }

  auto query_types_for_self_facet = GetTypesForSelfFacet(
      context, loc_id, query_self_const_id, query_specific_interface);

  // The values that will go in the witness table.
  llvm::SmallVector<SemIR::InstId> entries;

  auto interface_with_self_specific_id = SemIR::SpecificId::None;

  enum class AssociatedEntityState {
    None,
    AssociatedConstant,
    AssociatedFunction
  };
  auto associated_entity_state = AssociatedEntityState::None;
  // Build a witness with the current contents of the witness table. Each
  // specific interface has at most two witness tables: an optional table
  // for associated constants and a table for associated functions.
  //
  // We need to separate associated constants and associated functions since
  // associated entities can't depend on other entities in their own witness
  // table. To ensure that we don't end up with n^2 witness tables, and so
  // that we don't need to loop over the associated entities more than once,
  // we require that interfaces with a custom witness specify all of their
  // associated constants before their associated functions. Interfaces with
  // custom witness tables are hardcoded in the compiler, so this
  // restriction doesn't impact whether or not a type is definable.
  auto update_interface_with_self_specific_id =
      [&](SemIR::InstId assoc_entity_id) {
        auto decl_id =
            context.constant_values().GetConstantInstId(assoc_entity_id);
        CARBON_CHECK(decl_id.has_value(), "Non-constant associated entity");
        auto decl = context.insts().Get(decl_id);
        auto new_associated_entity_state =
            decl.kind() == SemIR::AssociatedConstantDecl::Kind
                ? AssociatedEntityState::AssociatedConstant
                : AssociatedEntityState::AssociatedFunction;
        CARBON_CHECK(new_associated_entity_state >= associated_entity_state,
                     "Implementation restriction: associated constants must be "
                     "defined before associated functions");
        if (associated_entity_state < new_associated_entity_state) {
          auto self_facet = MakeSelfFacetWithCustomWitness(
              context, loc_id, query_types_for_self_facet,
              query_specific_interface, context.inst_blocks().Add(entries));
          interface_with_self_specific_id = MakeSpecificWithInnerSelf(
              context, loc_id, interface.generic_id,
              interface.generic_with_self_id,
              query_specific_interface.specific_id, self_facet);
          associated_entity_state = new_associated_entity_state;
        }
      };

  // Fill in the witness table.
  for (const auto& [assoc_entity_id, value_id] :
       llvm::zip_equal(assoc_entities, values)) {
    LoadImportRef(context, assoc_entity_id);
    update_interface_with_self_specific_id(assoc_entity_id);
    CARBON_CHECK(
        !context.specifics().Get(interface_with_self_specific_id).HasError());
    auto decl_id =
        context.constant_values().GetInstId(SemIR::GetConstantValueInSpecific(
            context.sem_ir(), interface_with_self_specific_id,
            assoc_entity_id));
    CARBON_CHECK(decl_id.has_value(), "Non-constant associated entity");
    auto decl = context.insts().Get(decl_id);
    CARBON_KIND_SWITCH(decl) {
      case CARBON_KIND(SemIR::StructValue struct_value): {
        if (struct_value.type_id == SemIR::ErrorInst::TypeId) {
          return SemIR::ErrorInst::InstId;
        }
        // TODO: If a thunk is needed, this will build a different value each
        // time it's called, so we won't properly deduplicate repeated
        // witnesses.
        entries.push_back(CheckAssociatedFunctionImplementation(
            context,
            context.types().GetAs<SemIR::FunctionType>(struct_value.type_id),
            query_specific_interface.specific_id, value_id,
            /*defer_thunk_definition=*/false));
        break;
      }
      case CARBON_KIND(SemIR::AssociatedConstantDecl decl): {
        if (decl.type_id == SemIR::ErrorInst::TypeId) {
          return SemIR::ErrorInst::InstId;
        }

        // TODO: remove once we have a test-case for all associated constants.
        // Special-case the ones we want to support in this if-statement, until
        // we're able to account for everything.
        if (decl.type_id != SemIR::TypeType::TypeId) {
          context.TODO(loc_id,
                       "Associated constant of type other than `TypeType` in "
                       "synthesized impl");
          return SemIR::ErrorInst::InstId;
        }

        auto type_id = context.insts().Get(value_id).type_id();
        CARBON_CHECK(type_id == SemIR::TypeType::TypeId ||
                     type_id == SemIR::ErrorInst::TypeId);
        auto impl_witness_associated_constant =
            AddInst<SemIR::ImplWitnessAssociatedConstant>(
                context, loc_id, {.type_id = type_id, .inst_id = value_id});
        entries.push_back(impl_witness_associated_constant);
        break;
      }
      default:
        CARBON_CHECK(decl_id == SemIR::ErrorInst::InstId,
                     "Unexpected kind of associated entity {0}", decl);
        return SemIR::ErrorInst::InstId;
    }
  }

  return MakeCustomWitnessConstantInst(context, loc_id,
                                       query_specific_interface,
                                       context.inst_blocks().Add(entries));
}

auto AsCoreIdentifier(SemIR::CoreInterface core_interface) -> CoreIdentifier {
  switch (core_interface) {
#define CARBON_SEM_IR_CORE_INTERFACE_EXCLUDE_UNKNOWN
#define CARBON_SEM_IR_CORE_INTERFACE_KIND(Name) \
  case SemIR::CoreInterface::Name:              \
    return CoreIdentifier::Name;
#include "toolchain/sem_ir/core_interface_kind.def"
    case SemIR::CoreInterface::Unknown:
      CARBON_FATAL("{0} doesn't have a `CoreIdentifier` mapping",
                   core_interface);
  }
}

auto GetCoreInterface(Context& context, SemIR::InterfaceId interface_id)
    -> SemIR::CoreInterface {
  const auto& interface = context.interfaces().Get(interface_id);
  if (!context.name_scopes().IsCorePackage(interface.parent_scope_id) ||
      !interface.name_id.AsIdentifierId().has_value()) {
    return SemIR::CoreInterface::Unknown;
  }

  return interface.core_interface;
}

auto BuildPrimitiveCopyWitness(
    Context& context, SemIR::LocId loc_id,
    SemIR::ConstantId query_self_const_id,
    SemIR::SpecificInterface query_specific_interface) -> SemIR::InstId {
  auto self_type_id = GetFacetAccessType(
      context, context.constant_values().GetInstId(query_self_const_id));

  auto op_id = MakeBuiltinOperatorFunction(
      context, loc_id, {self_type_id}, self_type_id, CoreIdentifier::Op,
      SemIR::BuiltinFunctionKind::PrimitiveCopy,
      query_specific_interface.interface_id);
  return BuildCustomWitness(context, loc_id, query_self_const_id,
                            query_specific_interface, {op_id});
}

auto BuildDestroyWitness(Context& context, SemIR::LocId loc_id,
                         SemIR::TypeId self_type_id,
                         SemIR::ConstantId query_self_const_id,
                         SemIR::SpecificInterface query_specific_interface,
                         SemIR::InstId subobject_destroy_fn_id)
    -> SemIR::InstId {
  auto interface =
      context.interfaces().Get(query_specific_interface.interface_id);
  auto assoc_entities =
      context.inst_blocks().Get(interface.associated_entities_id);
  CARBON_CHECK(assoc_entities.size() == 3,
               "{} only has {} associated functions",
               context.names().GetAsStringIfIdentifier(interface.name_id),
               assoc_entities.size());

  auto op_id = MakeDestroyOpFunction(context, loc_id, self_type_id,
                                     query_specific_interface.interface_id);

  auto self_destruct_fn_id = MakeDestroySelfDestructFunction(
      context, loc_id, self_type_id, query_specific_interface.interface_id,
      op_id, subobject_destroy_fn_id);

  return BuildCustomWitness(
      context, loc_id, query_self_const_id, query_specific_interface,
      {op_id, subobject_destroy_fn_id, self_destruct_fn_id});
}

// Returns the custom witness to use for copying a choice type or a native
// `union`, or nullopt for every other self so that classes, tuples, and
// primitives keep their landed behavior. See `LookupCustomWitness`. Mirrors
// `LookupDestroyWitness` below.
//
// Unions (docs/design/unions.md, "Initialization and assignment"): because
// every field is trivially copyable, "every union is itself trivially
// copyable: copy initialization and assignment ... copy the union's full
// object representation — all `size(U)` bytes", the same per-field triviality
// argument as for choices. Only NATIVE unions take this witness: an imported
// C++ union keeps Clang's determination and copies through the C++ copy
// constructor (cpp/impl_lookup.cpp `BuildCopyWitness`), where a non-trivial
// member deletes it. As for choices, this witness shadows a user `impl as
// Core.Copy` written inside a union body (the custom-witness dispatch
// precedes candidate-impl iteration).
//
// Fork (W-075, fork/w075/plan.md §2): every definable choice is trivially
// copyable — the SF-6 slice-1 fence rejects any payload "that is not
// trivially copyable and destructible"
// (check/testdata/choice/fail_todo_nontrivial_payload.carbon) and enforces
// the same allowlist per specific at monomorphization — so a choice self is
// answered with a primitive-copy witness, the sanctioned C++-enum pattern
// (cpp/impl_lookup.cpp `BuildCopyWitness`: "it's an enum ... Perform a
// primitive copy"). Classes stay fenced behind the `is_choice` predicate:
// upstream is undecided on class copyability
// (check/testdata/var/fail_not_copyable.carbon).
//
// Because the custom-witness dispatch precedes candidate-impl iteration at
// both call sites (impl_lookup.cpp: "Only consider candidates when a custom
// witness didn't apply"), this witness SHADOWS a user out-of-line
// `impl <choice> as Core.Copy` — the declared SF-1 consequence, the same
// posture `Destroy` already has for choices; pinned by
// check/testdata/choice/alternative_copy.carbon.
//
// W-071-style revisit note (plan §5 R-3): the triviality argument — concrete
// and symbolic alike — is valid exactly while the SF-6 fence holds. When
// SF-6 widens past trivially copyable payloads, this must become a real
// per-payload Copy walk, like destroy's field walk.
static auto LookupChoiceCopyWitness(
    Context& context, SemIR::LocId loc_id,
    SemIR::ConstantId query_self_const_id,
    SemIR::SpecificInterface query_specific_interface, bool build_witness)
    -> std::optional<SemIR::InstId> {
  auto self_inst_id = context.constant_values().GetInstId(
      GetCanonicalFacet(context, query_self_const_id));
  auto class_type = context.insts().TryGetAs<SemIR::ClassType>(self_inst_id);
  if (!class_type) {
    return std::nullopt;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  bool is_native_union =
      class_info.is_union && class_info.scope_id.has_value() &&
      !context.name_scopes().Get(class_info.scope_id).is_cpp_scope();
  if (!class_info.is_choice && !is_native_union) {
    return std::nullopt;
  }

  if (!build_witness || query_self_const_id.is_symbolic()) {
    // The choice can be copied, but we shouldn't make a witness right now: a
    // symbolic self defers building to each concrete monomorphization — the
    // same posture as `LookupDestroyWitness` and `CanDestroyClass`'s choice
    // clause, justified by the same SF-6 per-specific payload guarantee.
    return SemIR::InstId::None;
  }

  // The generated `Op` is canonicalized per (interface, self) by
  // `MakeBuiltinOperatorFunction` (upstream #7729), so no mangling-hint scope
  // is passed any more.
  return BuildPrimitiveCopyWitness(context, loc_id, query_self_const_id,
                                   query_specific_interface);
}

// Returns the custom witness that a native `union` implements
// `Core.UnformedInit`, or nullopt for every other self. See
// `LookupCustomWitness`. Mirrors `LookupChoiceCopyWitness` above.
//
// A union variable declared without an initializer is in the unformed state
// (docs/design/unions.md, "Initialization and assignment"): every union is
// trivially destructible and trivially copyable under the 0.1 field rules, so
// any in-memory representation satisfies the unformed-state requirements,
// exactly as for `i32`. `UnformedInit` declares no associated entities, so
// the witness table is empty; the prelude's blanket `impl forall [T:
// UnformedInit] T as DefaultOrUnformed` then makes `var u: U;` a
// `make_uninitialized` call. A synthesized `Default` witness would instead
// declare the variable formed, contradicting the design. Imported C++ unions
// are unaffected: they reach `DefaultOrUnformed` through `Default` (the C++
// default constructor, cpp/impl_lookup.cpp).
static auto LookupUnionUnformedInitWitness(
    Context& context, SemIR::LocId loc_id,
    SemIR::ConstantId query_self_const_id,
    SemIR::SpecificInterface query_specific_interface, bool build_witness)
    -> std::optional<SemIR::InstId> {
  auto self_inst_id = context.constant_values().GetInstId(
      GetCanonicalFacet(context, query_self_const_id));
  auto class_type = context.insts().TryGetAs<SemIR::ClassType>(self_inst_id);
  if (!class_type) {
    return std::nullopt;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (!class_info.is_union || !class_info.scope_id.has_value() ||
      context.name_scopes().Get(class_info.scope_id).is_cpp_scope()) {
    return std::nullopt;
  }

  if (!build_witness || query_self_const_id.is_symbolic()) {
    // The union permits unformed initialization, but we shouldn't make a
    // witness right now; a symbolic self (unreachable for a 0.1 union, which
    // is never generic) would defer to each concrete monomorphization, the
    // `LookupChoiceCopyWitness` posture.
    return SemIR::InstId::None;
  }

  return BuildCustomWitness(context, loc_id, query_self_const_id,
                            query_specific_interface, /*values=*/{});
}

// Builds and returns a custom witness that performs the specified kind of
// destruction for the given type.
static auto BuildCarbonDestroyWitness(
    Context& context, SemIR::LocId loc_id,
    SemIR::ConstantId query_self_const_id,
    SemIR::SpecificInterface query_specific_interface, DestroyFormat format)
    -> SemIR::InstId {
  CARBON_CHECK(format != DestroyFormat::NoDestroy);

  auto self_type_id = GetFacetAccessType(
      context, context.constant_values().GetInstId(query_self_const_id));
  auto subobject_destroy_op_id = MakeSubobjectDestroyOpFunction(
      context, loc_id, self_type_id, query_specific_interface.interface_id,
      format);
  return BuildDestroyWitness(context, loc_id, self_type_id, query_self_const_id,
                             query_specific_interface, subobject_destroy_op_id);
}

// Returns the custom witness to use for destruction of the given type. See
// `LookupCustomWitness`.
static auto LookupDestroyWitness(
    Context& context, SemIR::LocId loc_id,
    SemIR::ConstantId query_self_const_id,
    SemIR::SpecificInterface query_specific_interface, bool build_witness)
    -> std::optional<SemIR::InstId> {
  auto format = CanDestroyType(context, loc_id, query_self_const_id,
                               query_specific_interface);
  if (format == DestroyFormat::NoDestroy) {
    return std::nullopt;
  }

  if (!build_witness || query_self_const_id.is_symbolic()) {
    // The type can be destroyed, but we shouldn't make a witness right now.
    return SemIR::InstId::None;
  }

  return BuildCarbonDestroyWitness(context, loc_id, query_self_const_id,
                                   query_specific_interface, format);
}

auto BuildTrivialDestroyWitness(
    Context& context, SemIR::LocId loc_id,
    SemIR::ConstantId query_self_const_id,
    SemIR::SpecificInterface query_specific_interface) -> SemIR::InstId {
  return BuildCarbonDestroyWitness(context, loc_id, query_self_const_id,
                                   query_specific_interface,
                                   DestroyFormat::Trivial);
}

static auto MakeIntFitsInWitness(
    Context& context, SemIR::LocId loc_id,
    SemIR::ConstantId query_self_const_id,
    SemIR::SpecificInterface query_specific_interface, bool build_witness)
    -> std::optional<SemIR::InstId> {
  auto args_id = query_specific_interface.specific_id;
  if (!args_id.has_value()) {
    return std::nullopt;
  }
  auto args_block_id = context.specifics().Get(args_id).args_id;
  auto args_block = context.inst_blocks().Get(args_block_id);
  if (args_block.size() != 1) {
    return std::nullopt;
  }

  auto dest_const_id = context.constant_values().Get(args_block[0]);
  if (!dest_const_id.is_constant()) {
    return std::nullopt;
  }

  auto src_type_id = GetFacetAccessType(
      context, context.constant_values().GetInstId(query_self_const_id));
  auto dest_type_id = GetFacetAccessType(
      context, context.constant_values().GetInstId(dest_const_id));

  auto context_fn = [](DiagnosticContextBuilder& /*builder*/) -> void {};
  if (!RequireCompleteType(context, src_type_id, loc_id, context_fn) ||
      !RequireCompleteType(context, dest_type_id, loc_id, context_fn)) {
    return std::nullopt;
  }

  auto src_info = context.types().TryGetIntTypeInfo(src_type_id);
  if (!src_info) {
    return std::nullopt;
  }

  auto dest_info = context.types().TryGetIntTypeInfo(dest_type_id);
  if (!dest_info) {
    if (src_info->bit_width == IntId::None) {
      return std::nullopt;
    }
    // Check if the destination is a floating-point type.
    auto dest_object_rep_id = context.types().GetObjectRepr(dest_type_id);
    if (auto dest_float_type =
            context.types().TryGetAs<SemIR::FloatType>(dest_object_rep_id)) {
      const auto& src_width = context.ints().Get(src_info->bit_width);
      unsigned int float_precision = llvm::APFloat::semanticsPrecision(
          dest_float_type->float_kind.Semantics());
      // For iN we need one fewer bit. We don't need to worry about the value
      // -2^(N-1) needing all N bits, as it can always be represented exactly.
      if (src_width.sgt(src_info->is_signed ? float_precision + 1
                                            : float_precision)) {
        return std::nullopt;
      }
      if (!build_witness) {
        return SemIR::InstId::None;
      }
      return BuildCustomWitness(context, loc_id, query_self_const_id,
                                query_specific_interface, {});
    }
    return std::nullopt;
  }

  // If the bit width is unknown (e.g., due to symbolic evaluation), we cannot
  // determine whether it fits yet.
  if (src_info->bit_width == IntId::None ||
      dest_info->bit_width == IntId::None) {
    return std::nullopt;
  }

  const auto& src_width = context.ints().Get(src_info->bit_width);
  const auto& dest_width = context.ints().Get(dest_info->bit_width);

  bool fits = false;
  if (src_info->is_signed && !dest_info->is_signed) {
    // Signed -> unsigned: would truncate the sign bit.
    fits = false;
  } else if (src_info->is_signed == dest_info->is_signed) {
    // Signed -> signed or unsigned -> unsigned: allow widening or preserving
    // width.
    fits = src_width.sle(dest_width);
  } else {
    // Unsigned -> signed: strict widening required.
    fits = src_width.slt(dest_width);
  }

  if (!fits) {
    return std::nullopt;
  }

  if (!build_witness) {
    return SemIR::InstId::None;
  }

  return BuildCustomWitness(context, loc_id, query_self_const_id,
                            query_specific_interface, {});
}

static auto MakeFloatFitsInWitness(
    Context& context, SemIR::LocId loc_id,
    SemIR::ConstantId query_self_const_id,
    SemIR::SpecificInterface query_specific_interface, bool build_witness)
    -> std::optional<SemIR::InstId> {
  auto args_id = query_specific_interface.specific_id;
  if (!args_id.has_value()) {
    return std::nullopt;
  }
  auto args_block_id = context.specifics().Get(args_id).args_id;
  auto args_block = context.inst_blocks().Get(args_block_id);
  if (args_block.size() != 1) {
    return std::nullopt;
  }

  auto dest_const_id = context.constant_values().Get(args_block[0]);
  if (!dest_const_id.is_constant()) {
    return std::nullopt;
  }

  auto src_type_id = GetFacetAccessType(
      context, context.constant_values().GetInstId(query_self_const_id));
  auto dest_type_id = GetFacetAccessType(
      context, context.constant_values().GetInstId(dest_const_id));

  auto context_fn = [](DiagnosticContextBuilder& /*builder*/) -> void {};
  if (!RequireCompleteType(context, src_type_id, loc_id, context_fn) ||
      !RequireCompleteType(context, dest_type_id, loc_id, context_fn)) {
    return std::nullopt;
  }

  // Ensure both are actually floating-point types.
  auto src_object_rep_id = context.types().GetObjectRepr(src_type_id);
  auto src_float_type =
      context.types().TryGetAs<SemIR::FloatType>(src_object_rep_id);
  if (!src_float_type) {
    return std::nullopt;
  }

  auto dest_object_rep_id = context.types().GetObjectRepr(dest_type_id);
  auto dest_float_type =
      context.types().TryGetAs<SemIR::FloatType>(dest_object_rep_id);
  if (!dest_float_type) {
    return std::nullopt;
  }

  // Get their bit widths.
  auto src_width_opt =
      context.sem_ir().GetZExtIntValue(src_float_type->bit_width_id);
  auto dest_width_opt =
      context.sem_ir().GetZExtIntValue(dest_float_type->bit_width_id);

  if (!src_width_opt || !dest_width_opt) {
    // If the bit width is unknown (e.g. symbolic), we can't decide yet.
    return std::nullopt;
  }

  const auto& src_semantics = src_float_type->float_kind.Semantics();
  const auto& dest_semantics = dest_float_type->float_kind.Semantics();
  if (!llvm::APFloat::isRepresentableBy(src_semantics, dest_semantics)) {
    return std::nullopt;
  }

  if (!build_witness) {
    return SemIR::InstId::None;
  }

  return BuildCustomWitness(context, loc_id, query_self_const_id,
                            query_specific_interface, {});
}

auto LookupCustomWitness(Context& context, SemIR::LocId loc_id,
                         SemIR::CoreInterface core_interface,
                         SemIR::ConstantId query_self_const_id,
                         SemIR::SpecificInterface query_specific_interface,
                         bool build_witness) -> std::optional<SemIR::InstId> {
  switch (core_interface) {
    case SemIR::CoreInterface::Copy:
      // Fork (W-075, W-009): choice types and native unions take a
      // synthesized primitive-copy witness; every other self answers nullopt,
      // leaving the TODO below in place for upstream's own
      // copy/move/conversion work.
      return LookupChoiceCopyWitness(context, loc_id, query_self_const_id,
                                     query_specific_interface, build_witness);
    case SemIR::CoreInterface::UnformedInit:
      // Fork (W-009): native unions implement `UnformedInit` through an
      // empty custom witness; every other self answers nullopt, so the
      // prelude's own `UnformedInit` impls keep their landed behavior.
      return LookupUnionUnformedInitWitness(
          context, loc_id, query_self_const_id, query_specific_interface,
          build_witness);
    case SemIR::CoreInterface::Destroy:
      return LookupDestroyWitness(context, loc_id, query_self_const_id,
                                  query_specific_interface, build_witness);
    case SemIR::CoreInterface::FloatFitsIn:
      return MakeFloatFitsInWitness(context, loc_id, query_self_const_id,
                                    query_specific_interface, build_witness);
    case SemIR::CoreInterface::IntFitsIn:
      return MakeIntFitsInWitness(context, loc_id, query_self_const_id,
                                  query_specific_interface, build_witness);
    case SemIR::CoreInterface::AddAssignWith:
    case SemIR::CoreInterface::AddWith:
    case SemIR::CoreInterface::CppContiguousRange:
    case SemIR::CoreInterface::CppRangeForIterate:
    case SemIR::CoreInterface::CppUnsafeDeref:
    case SemIR::CoreInterface::Dec:
    case SemIR::CoreInterface::Default:
    case SemIR::CoreInterface::DivAssignWith:
    case SemIR::CoreInterface::DivWith:
    case SemIR::CoreInterface::EqWith:
    case SemIR::CoreInterface::Inc:
    case SemIR::CoreInterface::ModAssignWith:
    case SemIR::CoreInterface::ModWith:
    case SemIR::CoreInterface::MulAssignWith:
    case SemIR::CoreInterface::MulWith:
    case SemIR::CoreInterface::Negate:
    case SemIR::CoreInterface::OrderedWith:
    case SemIR::CoreInterface::SubAssignWith:
    case SemIR::CoreInterface::SubWith:
    case SemIR::CoreInterface::Unknown:
      // TODO: Handle more interfaces, particularly copy, move, and conversion.
      return std::nullopt;
  }
}

}  // namespace Carbon::Check
