// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_MEMBER_ACCESS_H_
#define CARBON_TOOLCHAIN_CHECK_MEMBER_ACCESS_H_

#include <optional>

#include "llvm/ADT/ArrayRef.h"
#include "toolchain/check/context.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/name_scope.h"

namespace Carbon::Check {

// Returns the highest allowed access for members of `name_scope_const_id`. For
// example, if this returns `Protected` then only `Public` and `Protected`
// accesses are allowed -- not `Private`.
auto GetHighestAllowedAccess(Context& context,
                             SemIR::ConstantId name_scope_const_id)
    -> SemIR::AccessKind;

// Fork (SC-1): what a member-name lookup through `LookupMemberNameInTypeScopes`
// found, before any access decision is applied.
struct MemberLookupInfo {
  // Whether the name was found in one of the scopes (an error scope does not
  // count as found).
  bool found = false;
  // Whether the name was found only as a member whose access is prohibited
  // (a private member of a base class, which lookup through an extended scope
  // prohibits regardless of `access_info`). `found` is false in that case.
  bool found_but_prohibited = false;
  // The declared access of the found member, or of the last prohibited member
  // when `found_but_prohibited`.
  SemIR::AccessKind access_kind = SemIR::AccessKind::Public;
};

// Fork (SC-1, fork/structural/plan.md D-SC-5(b)): the member-access lookup
// path, exposed for the structural-conformance check. Performs a member name
// lookup for `name_id` in `lookup_scopes` (the scopes of
// `name_scope_const_id`), including impl lookup through an alias of an
// associated entity and the on-demand import of C++ members, and returns the
// `NameRef` for the member (or `ErrorInst` if nothing was found).
//
// `access_info` is the access context to check against, or `nullopt` to find
// members regardless of their access (the caller then applies
// `IsAccessProhibited` to `out_info->access_kind`). With `diagnose` false,
// nothing is emitted for a missing name, a prohibited access or a missing
// `impl`. `base_id` is only used when `lookup_in_type_of_base` is true.
auto LookupMemberNameInTypeScopes(
    Context& context, SemIR::LocId loc_id, SemIR::InstId base_id,
    SemIR::NameId name_id, SemIR::ConstantId name_scope_const_id,
    llvm::ArrayRef<LookupScope> lookup_scopes, bool lookup_in_type_of_base,
    bool required, std::optional<AccessInfo> access_info, bool diagnose,
    MemberLookupInfo* out_info = nullptr) -> SemIR::InstId;

// Creates SemIR to perform a member access with base expression `base_id` and
// member name `name_id`. When `required`, failing to find the name is a
// diagnosed error; otherwise, `None` is returned. Returns the result of the
// access.
auto PerformMemberAccess(Context& context, SemIR::LocId loc_id,
                         SemIR::InstId base_id, SemIR::NameId name_id,
                         bool required = true) -> SemIR::InstId;

// Creates SemIR to perform a compound member access with base expression
// `base_id` and member name expression `member_expr_id`. Returns the result of
// the access. If specified, `missing_impl_diagnostic_context()` is used to
// provide context for the error diagnostic when impl binding fails due to a
// missing `impl`.
//
// On failure, an ErrorInst is returned and a diagnostic is produced unless
// `diagnose` is false. It is incorrect to specify `diagnose` as false if the
// resulting ErrorInst may appear in the produced SemIR.
auto PerformCompoundMemberAccess(
    Context& context, SemIR::LocId loc_id, SemIR::InstId base_id,
    SemIR::InstId member_expr_id, bool diagnose = true,
    DiagnosticContextFn missing_impl_diagnostic_context = nullptr)
    -> SemIR::InstId;

// Finds the value of an associated entity (given by assoc_entity_inst_id, a
// member of the interface given by interface_type_id) associated with a type or
// facet (given by base_id). Never does instance binding.
auto GetAssociatedValue(Context& context, SemIR::LocId loc_id,
                        SemIR::InstId base_id,
                        SemIR::ConstantId assoc_entity_const_id,
                        SemIR::SpecificInterface interface) -> SemIR::InstId;

// Creates SemIR to perform a tuple index with base expression `tuple_inst_id`
// and index expression `index_inst_id`. Returns the result of the access.
auto PerformTupleAccess(Context& context, SemIR::LocId loc_id,
                        SemIR::InstId tuple_inst_id,
                        SemIR::InstId index_inst_id) -> SemIR::InstId;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_MEMBER_ACCESS_H_
