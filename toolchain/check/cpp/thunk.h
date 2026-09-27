// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_CPP_THUNK_H_
#define CARBON_TOOLCHAIN_CHECK_CPP_THUNK_H_

#include "toolchain/check/context.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Check {

// Returns whether, with C++ exceptions enabled, `decl` is a
// potentially-throwing callee whose calls must cross the language boundary
// through a fenced thunk
// (docs/design/error_handling.md#the-fenced-boundary-terminate-semantics).
// Resolves the callee's exception specification if it is still unevaluated.
auto IsCppThunkFenceRequired(Context& context, const clang::FunctionDecl* decl)
    -> bool;

// Returns whether the given C++ imported function requires a C++ thunk to be
// used to call it. A C++ thunk is required for functions whose ABI uses any
// type except void, pointer and reference types, and signed 32-bit and 64-bit
// integers.
auto IsCppThunkRequired(Context& context, const SemIR::Function& function)
    -> bool;

// Given a function signature and a callee function, builds a C++ thunk with
// simple ABI (pointers, i32 and i64 types) that calls the specified callee.
// Assumes `IsCppThunkRequired()` return true for `callee_function`. Returns
// `nullptr` on failure.
auto BuildCppThunk(Context& context, const SemIR::Function& callee_function)
    -> clang::FunctionDecl*;

// Given a callee function, builds the CATCHING C++ thunk for it
// (docs/design/error_handling.md, "Catching imports"; fork/eh/plan.md §1.B.2):
// a `noexcept` thunk that calls the callee inside `try`, stores the return
// value through an out-pointer, and on `catch (...)` stores the primary
// exception object pointer through a trailing `void**` out-parameter,
// returning the `int` discriminant 0 (Ok) or 1 (Err). Returns `nullptr` on
// failure.
auto BuildCppCatchingThunk(Context& context,
                           const SemIR::Function& callee_function)
    -> clang::FunctionDecl*;

// Returns the imported declaration of the catching thunk for
// `callee_function_id`, building and importing it on first use and caching it
// per file. On failure, diagnoses the fail-closed `Unsupported: catching thunk`
// TODO and returns `None`; the caller then uses the FENCED thunk.
auto GetOrBuildCppCatchingThunkDecl(Context& context, SemIR::LocId loc_id,
                                    SemIR::FunctionId callee_function_id)
    -> SemIR::InstId;

// Builds a call to a thunk function that forwards a call argument list built
// for `callee_function_id` to a call to `thunk_callee_id`, for use when
// building a call from a C++ thunk to its target. This is like `PerformCall`,
// except that it takes a list of call arguments for `callee_function_id`, not a
// syntactic argument list.
//
// When the call is the direct operand of a postfix `?`, the callee is
// fence-required, and its mapped return type does not implement `Core.Try`,
// the call is emitted through the CATCHING thunk instead and has type
// `Core.Result(S, Cpp.Exception)` (fork/eh/plan.md D-EH-4, §1.B.1).
auto PerformCppThunkCall(Context& context, SemIR::LocId loc_id,
                         SemIR::FunctionId callee_function_id,
                         llvm::ArrayRef<SemIR::InstId> callee_arg_ids,
                         SemIR::InstId thunk_callee_id) -> SemIR::InstId;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_CPP_THUNK_H_
