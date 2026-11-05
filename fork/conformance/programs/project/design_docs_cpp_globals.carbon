// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — importing C++ types / exporting Carbon types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   107
//   3
//
// Documentation-sync program (fork/designdocs/plan.md D-DD-5): the code after
// this comment block is the P11 code block of
// docs/design/interoperability/README.md, section "Accessing global variables",
// byte for byte (fork/designdocs/check_samples.py, rulebook R27). Expected
// output derived by hand in fork/designdocs/plan.md section 4 (R16(d)). Runs on
// this fork's toolchain and on the upstream nightly. A PASS shows that the
// documented sample runs as documented; the design-docs bullet itself is
// arbitrated by document review.
//
// Why this bullet: the sample reads and assigns C++ variables of imported types
// through the `Cpp` package. A FAIL here is first a regression in the import of
// C++ variables (the interoperability README's "Accessing global variables"),
// not in the import of C++ class types.

import Core library "io";

import Cpp inline '''c++
inline int counter = 40;
inline const int kLimit = 100;
extern int total;
int total = 7;
namespace config {
inline int verbosity = 1;
}
''';

fn Run() -> i32 {
  // A C++ variable is a durable reference: it can be read, assigned, and
  // updated in place.
  Cpp.counter += 2;
  Core.Print(Cpp.counter);
  Core.Print(Cpp.kLimit + Cpp.total);
  Cpp.config.verbosity = 3;
  Core.Print(Cpp.config.verbosity);
  return 0;
}
