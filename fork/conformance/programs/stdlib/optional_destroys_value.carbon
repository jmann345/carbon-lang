// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// SKIP: known-missing slice of this PARTIAL bullet (W-170): an Optional never destroys the value it holds, because `DefaultOptionalStorage(T)` holds it as a `MaybeUnformed(T)` (core/prelude/types/optional.carbon:140-143), which runs no destructor (core/prelude/types/maybe_unformed.carbon:12-15), and no `Destroy` impl for `Core.Optional` exists; compiled with OP-1 (and on trunk) this program exits 0 printing 2, 1, 1, 0, 3, 2 where EXPECT is 2, 0, 1, 0, 3, 0
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   0
//   1
//   0
//   3
//   0
//
// Write-tests-first program for the ownership rule of fork design F-015
// (docs/design/optional.md): an Optional owns the value it holds, and
// destroying a non-empty Optional destroys that value. `Tracked` counts its
// live objects through a pointer: `Make` and `Copy` add one, `Destroy`
// removes one. Each helper prints the count while its locals are alive, then
// returns, which destroys them. Expected, from F-015's rules: `Some(t)` holds a
// copy of `t`, so `HoldOne` has two live objects (2) and none once it returns
// (0); an empty Optional holds nothing, so `HoldNone` has one (1) and none
// after (0); copying an Optional copies its value, so `HoldCopy` has three (3)
// and none after (0). Each helper has its own counter, so a miss in one does
// not carry into the next. Un-SKIP when W-170 lands; the body then needs no
// change.

import Core library "io";

class Tracked {
  var live: i32*;
  impl as Core.Copy {
    fn Op(self) -> Self {
      ++*self.live;
      return {.live = self.live};
    }
  }
  impl as Core.Destroy {
    fn Op(ref self) {
      --*self.live;
    }
  }
}

fn Make(live: i32*) -> Tracked {
  ++*live;
  return {.live = live};
}

fn HoldOne(live: i32*) {
  var t: Tracked = Make(live);
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  Core.Print(*live);
}

fn HoldNone(live: i32*) {
  var unused t: Tracked = Make(live);
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).None();
  Core.Print(*live);
}

fn HoldCopy(live: i32*) {
  var t: Tracked = Make(live);
  var o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  var unused p: Core.Optional(Tracked) = o;
  Core.Print(*live);
}

fn Run() -> i32 {
  var one: i32 = 0;
  HoldOne(&one);
  Core.Print(one);
  var none: i32 = 0;
  HoldNone(&none);
  Core.Print(none);
  var copied: i32 = 0;
  HoldCopy(&copied);
  Core.Print(copied);
  return 0;
}
