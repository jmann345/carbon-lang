// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/guarded_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/guarded_default.carbon

// Guards on `default` clauses (`default if (E) => ...`, W-067): `default`
// is equivalent to `case _: auto`, and "this facility is also available for
// `default` clauses" (docs/design/pattern_matching.md, "Guards";
// p2188:552-553). A guarded `default` arm reuses the case-guard
// capture-splice-branch shape with no pattern test and no bindings: a
// constant-true condition enters the arm, the spliced guard branches into
// the arm's body or on to the else block, and a failed guard falls through
// to a following arm or `default` — so, unlike an unguarded `default`,
// arms after it are reachable and permitted.

// --- basic.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A guarded `default` between other arms, its guard referencing the
// enclosing scope. Expected SemIR shape per arm: the guarded `default`'s
// test block holds a constant-`true` `BranchIf` into the arm-entry block,
// where the guard's converted-to-`bool` region is spliced
// (`splice_block`), followed by `BranchIf` into the body and a branch to
// the else block — the guarded-irrefutable-arm CFG from guard.carbon's
// `Binding`, minus the `NameBindingDecl`'s bindings and the bind pass.
// A failed guard falls through to `case 1`, then to the trailing guarded
// `default`, then to the final unguarded `default`.
fn Classify(x: i32) -> i32 {
  match (x) {
    case 0 => { return 0; }
    default if (x < 0) => { return 1; }
    case 1 => { return 2; }
    default if (x > 10) => { return 3; }
    default => { return 4; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- compound_guard.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
// A short-circuiting guard on a `default`: the captured region is
// multi-block, so the splice is a branch into the region's blocks rather
// than a `splice_block` (guard.carbon's `Compound` shape, on the
// `default` path).
fn InRange(x: i32) -> i32 {
  match (x) {
    default if (x > 0 and x < 10) => { return 1; }
    default => { return 0; }
  }
  return -1;
}
//@dump-sem-ir-end

// --- choice_coverage.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Flag {
  Off,
  On
}

// A guarded `default` records nothing toward exhaustiveness (guarded arms
// never count toward coverage), but it also does not interrupt it: the
// unguarded `.Off` and `.On` arms around it cover the choice, so no
// unguarded `default` is required even though the guarded `default` can
// fail (S2e; the negative pin is fail_guarded_default.carbon).
fn Classify(f: Flag, x: i32) -> i32 {
  match (f) {
    case .Off => { return 0; }
    default if (x > 0) => { return 2; }
    case .On => { return 1; }
  }
  return -1;
}
//@dump-sem-ir-end
