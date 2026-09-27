// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/operators/question_optional.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/operators/question_optional.carbon

// Postfix `?` over `Core.Optional(T)` (fork/eh/plan.md §4.A; decision D9 of
// docs/design/error_handling.md): the prelude's `final impl forall [T:
// OptionalStorage] Optional(T) as Try where .ContinueType = T and .BreakType
// = ()` in core/prelude/types/optional.carbon, over the placeholder
// `HasValue()`/`Get()` API (D-EH-1). The carrier is `Core.ControlFlow(T,
// ())`, whose `()` payload is admitted by D-EH-2. The two `fail_*_in_*`
// subfiles pin D9's "no implicit bridge": absence does not become an error
// value and an error does not become absence — each direction is the
// ordinary `()`/`E` conversion failure at the prelude `FromBreak` call.
// `fail_class_element` pins the SF-6 bound on the carrier specific:
// `Optional(i32)` and `Optional(T*)` are the 0.1 `?` surface.

// --- some_none.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(o: Core.Optional(i32)) -> Core.Optional(i32) {
  return Core.Optional(i32).Some(o? + 1);
}
//@dump-sem-ir-end

// --- pointer_niche.carbon
library "[[@TEST_NAME]]";

// The pointer storage (null is `None`): `p?` is the held `i32*`.
//@dump-sem-ir-begin
fn Deref(p: Core.Optional(i32*)) -> Core.Optional(i32) {
  return Core.Optional(i32).Some(*(p?));
}
//@dump-sem-ir-end

// --- fail_optional_in_result.carbon
library "[[@TEST_NAME]]";

// D9: `Optional?` inside a `Result`-returning function is a `()`-to-`E`
// conversion failure at `Core.Result(i32, i32).(Core.Try.FromBreak)`.
fn Bridge(o: Core.Optional(i32)) -> Core.Result(i32, i32) {
  return Core.Result(i32, i32).Ok(o?);
}

// --- fail_result_in_optional.carbon
library "[[@TEST_NAME]]";

// D9, the converse: `Result?` inside an `Optional`-returning function is an
// `E`-to-`()` conversion failure at `Core.Optional(i32).(Core.Try.FromBreak)`.
fn Swallow(r: Core.Result(i32, i32)) -> Core.Optional(i32) {
  return Core.Optional(i32).Some(r?);
}

// --- fail_class_element.carbon
library "[[@TEST_NAME]]";

// `Core.Optional(str)` is a fine type (`str` is `Copy & Destroy`), but its
// `Branch` forms the `Core.ControlFlow(str, ())` specific, whose `str`
// payload fails SF-6 (toolchain/check/type.cpp `IsInSliceChoicePayloadType`).
fn Element(s: Core.Optional(str)) -> Core.Optional(str) {
  return Core.Optional(str).Some(s?);
}
