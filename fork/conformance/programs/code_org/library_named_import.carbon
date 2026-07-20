// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Code organization: Libraries
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   ok
//
// The single-file-executable slice of the Libraries bullet: importing a
// *named* library (`import Core library "io"`) and using the names its api
// file declares. Core//io is itself a real api/impl pair (core/io.carbon
// `package Core library "io";` + core/io.impl.carbon `impl package Core
// library "io";`) and both files are compiled as units of every conformance
// compile via the default `--include-carbon-core`
// (toolchain/driver/compile_driver.cpp), so the api/impl pairing is
// exercised on every run of this program. The file-scope `alias` of an
// imported library member follows toolchain/check/testdata/alias/
// import.carbon (`alias c_alias_alias = c_alias;` after `import library`).
// Only builtin-bound api names (Core.Print/Core.PrintChar, which lower
// inline per toolchain/lower/handle_call.cpp) are called: names whose
// bodies live in io.impl.carbon (Core.PrintStr, Core.EOF) do not link under
// `carbon link` (see fork/conformance/README.md).

import Core library "io";

alias PrintNum = Core.Print;

fn Run() -> i32 {
  // A name declared in the Core//io api file, called via its local alias.
  PrintNum(42);
  // Api names called through the package qualifier.
  Core.PrintChar('o');
  Core.PrintChar('k');
  Core.PrintChar('\n');
  return 0;
}
