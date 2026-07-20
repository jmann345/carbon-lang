// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Code organization: Importing
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   7
//
// The import declaration itself, in its plain Carbon form: `import Core
// library "io"` makes the imported package's api names visible behind lazy
// cross-IR import refs (check/import_ref.cpp) that are only resolved when a
// name is first used. `Core.Print`/`Core.PrintChar` resolve from the
// explicitly imported Core//io IR while `Core.Int` resolves from the
// implicitly imported Core//prelude IR; both merge into the single `Core`
// package scope. A file-scope `alias` re-exports an imported name locally
// (shape from toolchain/check/testdata/alias/import.carbon), and an
// imported generic type (`Core.Int(32)`) is usable in a local signature.
// Import shape verbatim from every examples/advent2024/ file.

import Core library "io";

alias Emit = Core.Print;

fn Answer() -> Core.Int(32) { return 42; }

fn Run() -> i32 {
  // Imported function, called through its local alias.
  Emit(Answer());
  // Imported function, called through the package qualifier.
  Core.Print(7);
  return 0;
}
