// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Code organization: Implementation files
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   -1
// SKIP: needs `carbon link` to link core-library impl objects (explicit TODO in toolchain/driver/link_driver.cpp, which links only prelude objects): Core.EOF is declared in core/io.carbon and defined in core/io.impl.carbon, and this program compiles but link-fails with `ld.lld: error: undefined symbol: _CEOF.Core` on carbon_toolchain-0.0.0-0.nightly.2026.07.19.
//
// The runtime-observable slice of the Implementation files bullet: calling
// a function whose declaration lives in an api file and whose body lives
// in the paired `.impl.carbon` file, and observing the body's result.
// `fn EOF() -> i32;` is forward-declared in core/io.carbon and defined as
// `fn EOF() -> i32 { return -1; }` in core/io.impl.carbon; both files are
// units of every conformance compile (core_library_manifest.txt +
// `--include-carbon-core`, toolchain/driver/compile_driver.cpp), so the
// call below type-checks today — only the impl file's *object* is missing
// at link. Unblock: link core impl objects (or run under `carbon build` /
// the bazel carbon_binary rule, which do link them), then drop the SKIP.
//
// The feature itself works end-to-end on this exact toolchain when the
// harness's one-file-per-program shape is lifted; verified manually
// (2026-07-19) with a Main-package pair:
//   widget.carbon        `library "widget";` + `fn Get() -> i32;`
//   widget.impl.carbon   `impl library "widget";` + `fn Get() -> i32 { return 7; }`
//   main.carbon          `import library "widget";` + `fn Run() { Core.Print(Get()); }`
// compiled to three objects (all three files as units of each compile,
// `--output-last-input-only`), linked, and run: prints `7`, exit 0. A
// standalone impl file compiled alone fails as designed: "error:
// corresponding API for 'Main//widget' not found" [LibraryApiNotFound].
// Upstream unit coverage: toolchain/check/testdata/packages/ (pairing,
// implicit imports, fail_api_not_found.carbon).

import Core library "io";

fn Run() -> i32 {
  // Declared in the api file, defined in the impl file: prints -1 once the
  // impl object is linked.
  Core.Print(Core.EOF());
  return 0;
}
