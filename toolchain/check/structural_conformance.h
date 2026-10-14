// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_STRUCTURAL_CONFORMANCE_H_
#define CARBON_TOOLCHAIN_CHECK_STRUCTURAL_CONFORMANCE_H_

#include "toolchain/check/context.h"
#include "toolchain/check/diagnostic_helpers.h"
#include "toolchain/sem_ir/ids.h"

// Fork (SC-1, fork/structural/plan.md, fork decision F-010 B1): structural
// satisfaction of `template constraint` member requirements. A facet type
// whose `IdentifiedFacetType` lists structural requirements (D-SC-15) is
// satisfied by a type when, for every requirement `fn` of every such
// constraint, the type's own member of that name is a single function whose
// signature matches the requirement modulo `Self` (D-SC-5). The check is a
// boolean inside `LookupImplWitness` (D-SC-3); there is no witness (D-SC-4).

namespace Carbon::Check {

// The result of checking the structural requirements of a facet type.
enum class StructuralCheckResult : uint8_t {
  // Every structural requirement is satisfied, or the check is deferred
  // because the self is a template-phase binding (D-SC-19).
  Satisfied,
  // Some requirement is not satisfied. Nothing was diagnosed; the caller
  // reports lookup failure and may explain it with
  // `NoteStructuralConformanceFailure`.
  Unsatisfied,
  // The program is invalid and a diagnostic was emitted (an incomplete self
  // type, D-SC-5(a)). Only possible with `diagnose`.
  Error,
};

// Checks the structural requirements of the identified facet type
// `identified_id` (D-SC-5, D-SC-6, D-SC-19). With `diagnose` false nothing is
// emitted; with `diagnose` true only an incomplete self type is diagnosed
// (the unsatisfied case is the caller's conversion error, D-SC-9).
auto CheckStructuralRequirements(Context& context, SemIR::LocId loc_id,
                                 SemIR::IdentifiedFacetTypeId identified_id,
                                 bool diagnose) -> StructuralCheckResult;

// Explain mode (D-SC-9): re-runs the structural check of `query_self_const_id`
// against the facet type `facet_type_id` and attaches notes describing the
// first unsatisfied requirement, in declaration order, to `builder`. Emits
// nothing itself and adds no notes when every requirement is satisfied.
auto NoteStructuralConformanceFailure(Context& context, SemIR::LocId loc_id,
                                      SemIR::ConstantId query_self_const_id,
                                      SemIR::TypeId facet_type_id,
                                      DiagnosticBuilder& builder) -> void;

// Returns the first `template constraint` that the facet type `type_id`
// mentions, directly or through the `require impls` blocks of its complete
// named constraints, or `None` if there is none or `type_id` is not a facet
// type (D-SC-8(i)). Reads only `is_template`, so a forward-declared template
// constraint is found; an incomplete constraint's body is not walked.
auto FacetTypeHasStructuralRequirements(Context& context, SemIR::TypeId type_id)
    -> SemIR::NamedConstraintId;

// Returns the `template constraint` that declares the function `function_id`
// as a structural requirement, or `None` if it is any other function.
auto GetStructuralRequirementConstraint(Context& context,
                                        SemIR::FunctionId function_id)
    -> SemIR::NamedConstraintId;

// Attaches the note "requirement declared here" at a requirement `fn`'s
// declaration `requirement_decl_id` to `builder`.
auto NoteStructuralRequirementHere(DiagnosticBuilder& builder,
                                   SemIR::InstId requirement_decl_id) -> void;

// D-SC-4: a requirement `fn` has no body and is never itself called; a call
// through a type that satisfies the constraint targets the type's own member
// (`LookupMemberNameInTypeScopes`, the compound redirect). If `function_id` is
// a requirement, diagnoses the call at `loc_id` and returns false.
auto CheckCalleeIsNotStructuralRequirement(Context& context,
                                           SemIR::LocId loc_id,
                                           SemIR::FunctionId function_id)
    -> bool;

// D-SC-20 as amended at fill round 5: if `member_id`, found by a lookup in the
// constraint-with-self specific `with_self_specific_id`, is a requirement `fn`
// and that specific's `Self` is the constraint's own `Self` (a lookup with no
// self type, `HasN.N`), returns a name reference at `loc_id` to the
// requirement's value: an empty struct value of the concrete
// `StructuralRequirementType`, so that no expression has a type that depends
// on that `Self`, as an interface's `I.F` is an associated entity of a
// concrete type. Otherwise returns `None`.
auto MakeStructuralRequirementName(Context& context, SemIR::LocId loc_id,
                                   SemIR::NameId name_id,
                                   SemIR::InstId member_id,
                                   SemIR::SpecificId with_self_specific_id)
    -> SemIR::InstId;

// Returns the requirement `fn` that values of `type_id` name or hold: a
// `StructuralRequirementType`, the `FunctionType` of a requirement, a tuple,
// struct or array type with such an element type, or such a type under
// `const`. Otherwise returns `None`. A class with such a field, an adapter of
// such a type and `MaybeUnformed` of it are not looked into: a value of one is
// not converted element by element.
auto GetStructuralRequirementOfType(Context& context, SemIR::TypeId type_id)
    -> SemIR::FunctionId;

// D-SC-20 as amended at fill rounds 4 to 7: a value or an initializer that
// names or holds a requirement `fn` named with no type that satisfies it is
// refused. If the value `expr_id` names or holds a requirement
// (`GetStructuralRequirementOfType`, or a bound method of one), diagnoses it
// when `diagnose` and returns false. The error is at the innermost tuple or
// struct literal element that holds it, or at `loc_id` when that value has no
// location of its own.
auto CheckValueIsNotStructuralRequirement(Context& context, SemIR::LocId loc_id,
                                          SemIR::InstId expr_id, bool diagnose)
    -> bool;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_STRUCTURAL_CONFORMANCE_H_
