// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/exceptions/catching_thunk.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/exceptions/catching_thunk.carbon

// Catching imports (docs/design/error_handling.md, "Catching imports:
// `Result(T, Cpp.Exception)`"; fork/eh/plan.md §1.B.1-1.B.3, §4.B): under the
// default `--cpp-exceptions=auto` (resolving to `catch` here), applying `?`
// DIRECTLY to a call of a potentially-throwing C++ function selects the
// CATCHING thunk — a second, distinctly named thunk (`__carbon_catching_thunk`,
// asm label `.carbon_thunk_catch`) built lazily at the first such call — and
// the call has type `Core.Result(S, Cpp.Exception)`. The SemIR shows the
// return-slot and error temporaries, the `i32` discriminant call, the `EqWith`
// test against 0, the two alternative-constructor calls and the convergence.
// The FENCED thunk is built eagerly at import, so a callee used both ways has
// BOTH thunk declarations in `imports`. The full prelude is needed for
// `Core.Result`.

// --- question_select.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
''';

//@dump-sem-ir-begin
fn F() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
}
//@dump-sem-ir-end

// --- void_callee.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
void may_throw();
''';

// A `void` callee: `S` is `()`, so the catching thunk has no return
// out-parameter and no return-slot temporary is minted.
//@dump-sem-ir-begin
fn G() -> Core.Result((), Cpp.Exception) {
  Cpp.may_throw()?;
  return Core.Result((), Cpp.Exception).Ok(());
}
//@dump-sem-ir-end

// --- nested_argument.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int f(int n);
int g();
''';

// Only the call `?` is applied to is catching: the argument call `Cpp.g()` is
// followed by `f`'s `CallExpr` node in postorder, never directly by `?`, so it
// stays fenced.
//@dump-sem-ir-begin
fn H() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.f(Cpp.g())?);
}
//@dump-sem-ir-end

// --- same_callee_both_ways.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
''';

// Selection is per call site: the same callee is called fenced once and
// catching once, and `imports` carries both thunk declarations with distinct
// identifiers.
//@dump-sem-ir-begin
fn Both() -> Core.Result(i32, Cpp.Exception) {
  var plain: i32 = Cpp.may_throw_int();
  var caught: i32 = Cpp.may_throw_int()?;
  return Core.Result(i32, Cpp.Exception).Ok(plain + caught);
}
//@dump-sem-ir-end

// --- paren_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
int may_throw_int();
''';

// The adjacency test walks up through `ParenExpr` nodes: `?` binds to the
// value, not the spelling.
//@dump-sem-ir-begin
fn P() -> Core.Result(i32, Cpp.Exception) {
  var one: i32 = (Cpp.may_throw_int())?;
  var two: i32 = ((Cpp.may_throw_int()))?;
  return Core.Result(i32, Cpp.Exception).Ok(one + two);
}
//@dump-sem-ir-end

// --- reserved_name.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Exception {};
int may_throw_int();
''';

// `Exception` is reserved at the top of the `Cpp` package: `Cpp.Exception`
// still names the Carbon built-in type (the `Result` specific below is the
// same `Core.Result(i32, Cpp.Exception)` as in `question_select`), and the
// header's global `struct Exception` is reported unreachable under that
// name.
//@dump-sem-ir-begin
fn R() -> Core.Result(i32, Cpp.Exception) {
  return Core.Result(i32, Cpp.Exception).Ok(Cpp.may_throw_int()?);
}
//@dump-sem-ir-end
