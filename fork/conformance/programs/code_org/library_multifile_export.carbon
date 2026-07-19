// CONFORMANCE-BULLET: Code organization: Libraries
// SKIP: harness limitation, not a feature gap: user-written named libraries (`library "x";` api + `impl library "x";`), `export C;`, and `export import library "x";` need multiple compilation units, but runner.py compiles exactly one file per program; this slice is arbitrated by golden checks in toolchain/check/testdata/packages/ (export_name.carbon, export_import.carbon, fail_duplicate_api.carbon, fail_api_not_found.carbon).
//
// This file encodes the library slice a single Main//default compilation
// unit cannot reach. When the harness grows multi-file program support,
// replace this body with the sketch below (library/export declarations from
// toolchain/check/testdata/packages/export_name.carbon and
// export_import.carbon, which use split-file `// --- <name>.carbon` tests;
// the Run body verified to compile, link, run, and print 42 with the
// arbiter toolchain when the four files are built as separate units):
//
//   // --- base.carbon
//   library "base";
//   class C { var x: i32; }
//
//   // --- export.carbon
//   library "export";
//   import library "base";
//   export C;
//
//   // --- reexport.carbon
//   library "reexport";
//   export import library "export";
//
//   // --- main.carbon
//   import library "reexport";
//   import Core library "io";
//   fn Run() -> i32 {
//     var c: C = {.x = 42};
//     Core.Print(c.x);
//     return 0;
//   }
//
// Until then this file is intentionally code-free: if the SKIP directive is
// ever dropped without adding real multi-file coverage, the empty unit has
// no `Run` entry point and the program fails rather than silently passing.
