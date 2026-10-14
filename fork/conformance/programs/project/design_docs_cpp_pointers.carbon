// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: pointer types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   2
//   0
//   12
//   12
//   8
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P13 code block of
// docs/design/interoperability/README.md, section "Advanced type mapping:
// pointers, references, and `const`", byte for byte
// (fork/designdocs/check_samples.py, rulebook R27). Expected output derived by
// hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on this fork's
// toolchain and on the upstream nightly. A PASS shows that the documented
// sample runs as documented; the design-docs bullet itself is arbitrated by
// document review.
//
// Why this bullet: the sample maps C++ pointers to Carbon pointer types and
// `Core.Optional(T*)` (proposal 6357), and C++ references to `ref` parameters.
// A FAIL here is first a regression in that mapping (the interoperability
// README's "Advanced type mapping: pointers, references, and `const`"), not in
// Carbon's own pointer types.

import Core library "io";

import Cpp inline '''c++
inline void Bump(int* _Nonnull p) { *p += 1; }
inline int* Find(bool found, int* p) { return found ? p : nullptr; }
inline void AddTen(int& r) { r += 10; }
inline int Read(const int& r) { return r; }
inline int ReadThrough(const int* _Nonnull p) { return *p; }

struct Holder {
  int v = 3;
  int& Ref() { return v; }
  int Get() const { return v; }
};
''';

fn Run() -> i32 {
  var n: i32 = 1;
  // `int* _Nonnull` is `i32*`.
  Cpp.Bump(&n);
  Core.Print(n);
  // A pointer that may be null is `Core.Optional(i32*)`.
  let found: Core.Optional(i32*) = Cpp.Find(true, &n);
  if (found.HasValue()) {
    Core.Print(*found.Get());
  }
  let missing: Core.Optional(i32*) = Cpp.Find(false, &n);
  if (not missing.HasValue()) {
    Core.Print(0);
  }
  // A non-`const` reference parameter takes a `ref` argument; a `const`
  // reference parameter takes a value.
  Cpp.AddTen(ref n);
  Core.Print(Cpp.Read(n));
  // `const int* _Nonnull` is `const i32*`, and `i32*` converts to it.
  Core.Print(Cpp.ReadThrough(&n));
  // A returned non-`const` reference is a durable reference expression.
  var h: Cpp.Holder = Cpp.Holder.Holder();
  h.Ref() = 8;
  Core.Print(h.Get());
  return 0;
}
