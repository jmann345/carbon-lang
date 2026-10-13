// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
// SKIP: harness limitation, not a documentation gap: this sample links a separately compiled C++ unit (rectangle.cpp, built by `carbon clang -- -c`) beside the Carbon object, and this trunk's runner.py builds only Carbon units (execute_program issues `carbon compile` at runner.py:516-524 and `carbon link` over those objects at :546-551; a multi-unit directory takes *.carbon only, :321) and runs every command without a working directory (run_cmd, :453-462); and `import Cpp library "rectangle.h"` resolves the quoted header against the working directory, not the importing file's directory (measured: the same compile run from another directory fails with `'rectangle.h' file not found`), so no COMPILE-ARGS include path is independent of where the runner is started. The tutorial's commands print 42 and exit 0 by hand on 0.0.0-0.dev+0bdce60a5 and on 0.0.0-0.nightly.2026.10.12+62f1cc6 (fork/evaluator/plan.md section 0.1 row 11), and fork/evaluator/cpp_library/build.sh, which runs them, PASSes under CM-1's BUILD-SCRIPT channel (PR 52; plan section 0.1 row 25). Un-SKIP mechanically once PR 52 is on trunk: add `// BUILD-SCRIPT: fork/evaluator/cpp_library/build.sh` under the bullet line and delete this SKIP line (W-154, reserved, is filed only if this program must merge before PR 52).
//
// Transcribed from docs/guides/tutorial.md, section "Linking your own C++ library": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on the upstream nightly and this fork's toolchain.
// fork/evaluator/cpp_library/build.sh builds this body's
// byte-identical copy fork/evaluator/cpp_library/main.carbon with
// rectangle.cpp by the section's commands; the runner never
// compiles this file itself.

import Core library "io";
import Cpp library "rectangle.h";

fn Run() -> i32 {
  Core.Print(Cpp.RectangleArea(6, 7));
  return 0;
}
