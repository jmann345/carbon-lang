// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_TYPE_H_
#define CARBON_TOOLCHAIN_CHECK_TYPE_H_

#include "llvm/ADT/ArrayRef.h"
#include "toolchain/check/context.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Check {

// Enforces that an integer type has a valid bit width.
auto ValidateIntType(Context& context, SemIR::LocId loc_id,
                     SemIR::IntType result) -> bool;

// Enforces that a float type has a valid bit width. If the `float_kind` field
// is `None`, sets it to a suitable kind for the bit width.
auto ValidateFloatTypeAndSetKind(Context& context, SemIR::LocId loc_id,
                                 SemIR::FloatType& result) -> bool;

// Gets the type to use for an unbound associated entity declared in this
// interface. For example, this is the type of `I.T` after
// `interface I { let T: type; }`. The name of the interface is used for
// diagnostics.
// TODO: Should we use a different type for each such entity, or the same type
// for all associated entities?
auto GetAssociatedEntityType(Context& context, SemIR::InterfaceId interface_id,
                             SemIR::SpecificId interface_specific_id)
    -> SemIR::TypeId;

// Gets a singleton type. The returned type will be complete. Requires that
// `singleton_id` is already validated to be a singleton.
auto GetSingletonType(Context& context, SemIR::TypeInstId singleton_id)
    -> SemIR::TypeId;

// Gets a const-qualified version of a type.
auto GetConstType(Context& context, SemIR::TypeInstId inner_type_id)
    -> SemIR::TypeId;

// Gets a qualified version of a type.
auto GetQualifiedType(Context& context, SemIR::TypeId type_id,
                      SemIR::TypeQualifiers quals) -> SemIR::TypeId;

// Gets a class type.
auto GetClassType(Context& context, SemIR::ClassId class_id,
                  SemIR::SpecificId specific_id) -> SemIR::TypeId;

// Gets a C++ function pointer type. The returned type will be complete.
auto GetCppFunctionPointerType(Context& context,
                               SemIR::ClangFunctionPointerTypeId clang_type_id)
    -> SemIR::TypeId;

// Gets a C++ overload set type. The returned type will be complete.
auto GetCppOverloadSetType(Context& context,
                           SemIR::CppOverloadSetId overload_set_id,
                           SemIR::SpecificId specific_id) -> SemIR::TypeId;

// Gets the type of a Carbon `overload fn` set. The returned type will be
// complete.
auto GetOverloadSetType(Context& context, SemIR::OverloadSetId overload_set_id,
                        SemIR::SpecificId specific_id) -> SemIR::TypeId;

// Gets a C++ template name type. The returned type will be complete.
auto GetCppTemplateNameType(Context& context, SemIR::EntityNameId name_id,
                            SemIR::ClangDeclId decl_id) -> SemIR::TypeId;

// Gets a function type. The returned type will be complete.
auto GetFunctionType(Context& context, SemIR::FunctionId fn_id,
                     SemIR::SpecificId specific_id) -> SemIR::TypeId;

auto GetVtableType(Context& context, SemIR::VtableId vtable_id)
    -> SemIR::TypeId;

// Gets the type of an associated function with the `Self` parameter bound to
// a particular value. The returned type will be complete.
auto GetFunctionTypeWithSelfType(Context& context,
                                 SemIR::TypeInstId interface_function_type_id,
                                 SemIR::InstId self_id) -> SemIR::TypeId;

// Gets a generic class type, which is the type of a name of a generic class,
// such as the type of `Vector` given `class Vector(T: type)`. The returned
// type will be complete.
auto GetGenericClassType(Context& context, SemIR::ClassId class_id,
                         SemIR::SpecificId enclosing_specific_id)
    -> SemIR::TypeId;

// Gets a generic interface type, which is the type of a name of a generic
// interface, such as the type of `AddWith` given
// `interface AddWith(T: type)`. The returned type will be complete.
auto GetGenericInterfaceType(Context& context, SemIR::InterfaceId interface_id,
                             SemIR::SpecificId enclosing_specific_id)
    -> SemIR::TypeId;

// Gets a generic named constraint type, which is the type of a name of a
// generic named constraint, such as the type of `AddWith` given `constraint
// AddWith(T: type)`. The returned type will be complete.
auto GetGenericNamedConstraintType(Context& context,
                                   SemIR::NamedConstraintId named_constraint_id,
                                   SemIR::SpecificId enclosing_specific_id)
    -> SemIR::TypeId;

// Gets the facet type corresponding to a particular interface.
auto GetInterfaceType(Context& context, SemIR::InterfaceId interface_id,
                      SemIR::SpecificId specific_id) -> SemIR::TypeId;

// Gets the facet type corresponding to a particular named constraint.
auto GetNamedConstraintType(Context& context,
                            SemIR::NamedConstraintId named_constraint_id,
                            SemIR::SpecificId specific_id) -> SemIR::TypeId;

// Gets the facet type for the given `declared_facet_type`.
auto GetFacetType(Context& context,
                  const SemIR::DeclaredFacetType& declared_facet_type)
    -> SemIR::TypeId;

// Gets the type contained within the given facet value.
auto GetFacetAccessType(Context& context, SemIR::InstId facet_value_inst_id)
    -> SemIR::TypeId;

// Returns a pointer type whose pointee type is `pointee_type_id`. The returned
// type will be complete.
auto GetPointerType(Context& context, SemIR::TypeInstId pointee_type_id)
    -> SemIR::TypeId;

// Returns an array type with the given `bound_id` and `element_type_inst_id`.
auto GetArrayType(Context& context, SemIR::InstId bound_id,
                  SemIR::TypeInstId element_type_inst_id) -> SemIR::TypeId;

// Returns a struct type with the given fields.
auto GetStructType(Context& context, SemIR::StructTypeFieldsId fields_id)
    -> SemIR::TypeId;

// Returns a tuple type with the given element types.
auto GetTupleType(Context& context, llvm::ArrayRef<SemIR::InstId> type_inst_ids)
    -> SemIR::TypeId;

// Returns a pattern type with the given scrutinee type.
auto GetPatternType(Context& context, SemIR::TypeId scrutinee_type_id)
    -> SemIR::TypeId;

// Returns the type component of the given form value.
auto GetTypeComponent(Context& context, SemIR::InstId form_inst_id)
    -> SemIR::TypeId;

// Returns an unbound element type.
auto GetUnboundElementType(Context& context, SemIR::TypeInstId class_type_id,
                           SemIR::TypeInstId element_type_id) -> SemIR::TypeId;

// Given a facet, returns its canonical facet representation.
//
// Facet values can be converted to `type` by wrapping them in an `as type`
// conversion. While this wraps the facet in an additional instruction, it does
// not destroy access to the underlying facet. This operation unwraps the
// `as type` conversion if present so that there's only one (canonical) way to
// represent the underlying facet, and returns the canonical inst from the
// facet's constant value.
//
// This extra canonicalization step of unwrapping `as type` is important for
// constant comparison of facet values, when the `as type` conversion is not
// required to compare as a different value.
//
// For all facets other than `<facet> as type`, the canonical inst from the
// facet's constant value is returned.
auto GetCanonicalFacet(Context& context, SemIR::InstId inst_id)
    -> SemIR::InstId;
auto GetCanonicalFacet(Context& context, SemIR::ConstantId const_id)
    -> SemIR::ConstantId;

// If `inst_id` is a `facet as type`, return that canonical facet inside the
// conversion. Otherwise, return None.
//
// In particular, this returns None for non-canonical instructions if no
// conversion was unwrapped, to preserve source locations in the caller.
auto TryGetCanonicalFacet(Context& context, SemIR::InstId inst_id)
    -> SemIR::InstId;

// The slice-1 choice-payload restriction (decision-log W5 SF-6): payload types
// must be trivially copyable and trivially destructible. This accepts the
// scalar types for which that property is structural — integer, float, bool,
// and pointer types, including adapters over them such as `i32` — and rejects
// everything else; callers diagnose. Deliberately conservative: relaxing it is
// recorded post-0.1 work, and the match scrutinee gate relies on completed
// choices having only trivial payloads (a type property, not a syntactic
// test). Checked at the choice definition for concrete payload types
// (handle_choice.cpp) and at monomorphization for symbolic ones
// (`EvalConstantInst` for `CustomLayoutType`, eval_inst.cpp). `type_id` must
// be concrete; completeness is needed only to classify THROUGH an adapter
// (the foundation walk reads the specific's resolved values) — non-class
// kinds and non-adapter classes classify without completion, which the
// eval hook's recursion pre-filter relies on.
//
// Admitted exception, recorded in decision-log W5-S1: a user-declared adapter
// over a scalar with its own `Core.Destroy` impl passes this gate without a
// witness query. Harmless while destroy-op synthesis is a placeholder no-op;
// when it lands, this must become a destroy-witness triviality check (it rides
// SF-6's post-0.1 work item).
auto IsInSliceChoicePayloadType(Context& context, SemIR::TypeId type_id)
    -> bool;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_TYPE_H_
