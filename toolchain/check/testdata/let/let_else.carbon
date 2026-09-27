// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/let/let_else.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/let/let_else.carbon

// `let`-`else` (W-012, fork/design-sprint/if-let.md Option A): the pattern's
// test branches `let.then`/`let.else`; the else block is emitted first and
// must not complete normally (F-011a: its end is unreachable); the bind pass
// runs in the success block, and the bindings are ordinary bindings of the
// ENCLOSING scope.

// --- alternative_payload.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(e: OptInt) -> i32 {
  let .Some(port: i32) = e else { return -1; }
  return port;
}
//@dump-sem-ir-end

// --- alternative_bare.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(e: OptInt) -> i32 {
  let .None = e else { return -1; }
  return 0;
}
//@dump-sem-ir-end

// --- tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(pair: (i32, i32)) -> i32 {
  let (0, n: i32) = pair else { return -1; }
  return n;
}
//@dump-sem-ir-end

// --- var_else.carbon
library "[[@TEST_NAME]]";

// The var-alternative lane: mutable on-demand storage in the success block,
// mutated after the declaration.
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(o: OptInt) -> i32 {
  var .Some(v: i32) = o else { return 0; }
  v = v + 1;
  return v;
}
//@dump-sem-ir-end

// --- break_in_loop.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(o: OptInt) -> i32 {
  var total: i32 = 0;
  while (true) {
    let .Some(n: i32) = o else { break; }
    total = total + n;
    if (total > 10) {
      break;
    }
  }
  return total;
}
//@dump-sem-ir-end

// --- continue_in_loop.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}
fn Next(n: i32) -> OptInt {
  if (n > 0) {
    return OptInt.Some(n - 1);
  }
  return OptInt.None;
}

//@dump-sem-ir-begin
fn F() -> i32 {
  var i: i32 = 0;
  var total: i32 = 0;
  while (i < 3) {
    i = i + 1;
    let .Some(n: i32) = Next(i) else { continue; }
    total = total + n;
  }
  return total;
}
//@dump-sem-ir-end

// --- nested_all_paths_return.carbon
library "[[@TEST_NAME]]";

// Accepted under F-011a: every path through the else block diverges, so its
// end is unreachable.
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(o: OptInt, c: bool) -> i32 {
  let .Some(n: i32) = o else {
    if (c) {
      return 1;
    } else {
      return 2;
    }
  }
  return n;
}
//@dump-sem-ir-end

// --- let_else_in_match_arm_body.carbon
library "[[@TEST_NAME]]";

// Nested refutable contexts push and pop their own state (LIFO).
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(x: i32, o: OptInt) -> i32 {
  match (x) {
    case 0 => {
      let .Some(n: i32) = o else { return -1; }
      return n;
    }
    default => { return 0; }
  }
  return -2;
}
//@dump-sem-ir-end

// --- two_in_sequence.carbon
library "[[@TEST_NAME]]";

// The second declaration's initializer uses the first's binding.
choice OptInt {
  Some(x: i32),
  None
}

fn Wrap(n: i32) -> OptInt { return OptInt.Some(n); }

//@dump-sem-ir-begin
fn F(o: OptInt) -> i32 {
  let .Some(a: i32) = o else { return -1; }
  let .Some(b: i32) = Wrap(a) else { return -2; }
  return b;
}
//@dump-sem-ir-end
