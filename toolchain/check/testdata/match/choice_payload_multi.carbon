// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/choice_payload_multi.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/choice_payload_multi.carbon

// Multi-element payload destructuring (one subpattern per declared
// parameter, positionally), a zero-payload function-like alternative
// matched with its empty parentheses (`case .On()`, SF-3), and a binding
// whose declared type implicitly converts from the payload element type
// (`n: i64` from an `i32` payload — the bind pass converts per element, and
// the conversion's temporaries defer to the arm scope's cleanups).
//@dump-sem-ir-begin
choice Event {
  Move(dx: i32, dy: i32),
  Set(value: i32),
  On(),
  Off
}

fn Total(e: Event) -> i64 {
  match (e) {
    case .Move(dx: i32, dy: i64) => { return dy; }
    case .Set(n: i64) => { return n; }
    case .On() => { return 1; }
    case .Off => { return 0; }
    default => { return -1; }
  }
  return -2;
}
//@dump-sem-ir-end
