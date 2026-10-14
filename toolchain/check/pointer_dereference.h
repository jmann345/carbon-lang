// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_POINTER_DEREFERENCE_H_
#define CARBON_TOOLCHAIN_CHECK_POINTER_DEREFERENCE_H_

#include "toolchain/check/context.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Check {

// Which operator a pointer dereference is for, which selects its diagnostic.
enum class PointerDereferenceKind : bool { Star, Arrow };

// Returns whether `type_id` is a template-dependent type whose kind is not
// known where the template is defined: a template type parameter, its facet
// access type, or the type of a template-dependent expression. Every other
// type, including a template-dependent class type such as `C(T)`, has a kind
// that the eager code can act on.
auto IsOpaqueTemplateDependentType(Context& context, SemIR::TypeId type_id)
    -> bool;

// Creates SemIR to perform a pointer dereference with base expression
// `base_id`, for `*` or for the base of `->`. A template-dependent operand of
// opaque type is dereferenced when the template is instantiated. Returns the
// result of the access.
auto PerformPointerDereference(Context& context, SemIR::LocId loc_id,
                               SemIR::InstId base_id,
                               PointerDereferenceKind kind) -> SemIR::InstId;

// Creates SemIR to take the address of `operand_id`, `&operand`.
auto PerformAddrOf(Context& context, SemIR::LocId loc_id,
                   SemIR::InstId operand_id) -> SemIR::InstId;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_POINTER_DEREFERENCE_H_
