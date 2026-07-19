// CONFORMANCE-BULLET: Code organization: Implementation files
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   impl
//   1
//
// The single-file-executable slice of the Implementation files bullet. The
// harness compiles exactly one program file per program, so a Main-package
// api/impl pair cannot appear here (see impl_files_impl_defined_fn.carbon
// for the encoded remainder). Instead this program leans on the api/impl
// pair that IS a part of every conformance compile: core/io.carbon
// (`package Core library "io";`) + core/io.impl.carbon (`impl package Core
// library "io";`), both listed in the install tree's
// core_library_manifest.txt and compiled as units of this same invocation
// by the default `--include-carbon-core`
// (toolchain/driver/compile_driver.cpp). This compile therefore succeeds
// only if impl-file semantics hold for that pair
// (toolchain/check/check.cpp; upstream unit coverage in
// toolchain/check/testdata/packages/):
// - pairing: the impl unit must find its api, else "corresponding API for
//   '...' not found" [LibraryApiNotFound];
// - implicit api import: io.impl.carbon's `PrintStr` body calls
//   `PrintChar`, visible there only through the impl file's implicit
//   import of its own api;
// - cross-file merge: the impl file *defines* `fn PrintStr` and `fn EOF`,
//   which the api file only forward-declares.
// At runtime only builtin-bound api names are called (Core.Print /
// Core.PrintChar lower inline to printf/putchar,
// toolchain/lower/handle_call.cpp); names whose bodies live in
// io.impl.carbon do not link under `carbon link` (fork/conformance/
// README.md).

import Core library "io";

fn Run() -> i32 {
  // Names declared in the Core//io api file, whose sibling .impl.carbon
  // file was type-checked as a unit of this same compile.
  Core.PrintChar('i');
  Core.PrintChar('m');
  Core.PrintChar('p');
  Core.PrintChar('l');
  Core.PrintChar('\n');
  Core.Print(1);
  return 0;
}
