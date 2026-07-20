// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: C++ interop — open overload sets as extension points (swap etc.)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   1
// SKIP: feature gap, the missing slice of this PARTIAL bullet: only the `begin`/`end` overload set gets extension-point treatment — BuildCppRangeForIterateWitness in toolchain/check/cpp/impl_lookup.cpp special-cases exactly the identifiers "begin" and "end" (member lookup, then ADL via AddArgumentDependentLookupCandidates) into the prelude's private CppRangeForIterate interface, and LookupCppImpl's switch covers only that plus operator interfaces (Inc/EqWith/AddWith/...). There is no swap-style heuristic import: no Swap interface exists anywhere in the arbiter's shipped prelude (grep -ri swap over carbon_toolchain-0.0.0-0.nightly.2026.07.19/lib/carbon/core/ finds nothing), so the `Core.Swap` bound and `.(Core.Swap.Op)` call below have no real spelling to compile against. ADL coverage is itself partial: on this arbiter a mutable-reference ADL range (`friend auto begin(MutRange&)`) fails to iterate with `error: facet type ... can not be identified` / `note: value expression passed to reference parameter` while building the thunk for `fn Begin(self)` (matches fail_todo_adl_returns_same_types_mutable.carbon in check/testdata/interop/cpp/impls/cpp_range_for_iterate.carbon). Verified by hand on this arbiter: the direct qualified call `Cpp.ext.swap(ref a, ref b)` on this exact Box type compiles, links, runs and prints 2 then 1 — but that is plain imported-function overload resolution (the importing/calling bullet), not the overload set surfaced as an extension point for Carbon generic code. Promote out of SKIP when a swap-style synthesized interface lands; the working begin/end slice is arbitrated by the two PASSing cpp_range_*_iterate.carbon siblings.
//
// Intended test once the feature exists: Carbon generic code, constrained
// only by a swap interface, swaps two values of a C++ type through a
// synthesized impl backed by the type's ADL `swap` overload — the same
// heuristic-import treatment `begin`/`end` already get via
// CppRangeForIterate -> Core.Iterate (core/prelude/iterate.carbon).

import Core library "io";
import Cpp inline '''c++
namespace ext {
struct Box {
  int n;
  static auto Make(int v) -> Box { return Box{v}; }
};
inline auto swap(Box& a, Box& b) -> void {
  int t = a.n;
  a.n = b.n;
  b.n = t;
}
}  // namespace ext
''';

// Hypothetical spelling: no `Core.Swap` interface exists today (see SKIP).
fn SwapThroughExtensionPoint[T:! Core.Swap](a: T*, b: T*) {
  (*a).(Core.Swap.Op)(b);
}

fn Run() -> i32 {
  var a: Cpp.ext.Box = Cpp.ext.Box.Make(1);
  var b: Cpp.ext.Box = Cpp.ext.Box.Make(2);
  SwapThroughExtensionPoint(&a, &b);
  Core.Print(a.n);
  Core.Print(b.n);
  return 0;
}
