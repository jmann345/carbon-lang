// CONFORMANCE-BULLET: Code organization: Packages
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   100
//
// The `package.` expression names the current package's file scope
// (Main//default here) explicitly. A local binding shadows a file-scope
// function of the same name, and `package.Seven` still reaches the
// file-scope one; `package.NS.Six` walks a namespace path from the package
// root. Shapes from toolchain/check/testdata/package_expr/syntax.carbon
// (local `x` shadowing package `x`, `package.NS.C.Foo()`) and
// toolchain/check/testdata/namespace/imported.carbon (`package.NS.A()`).

import Core library "io";

fn Seven() -> i32 { return 7; }

namespace NS;

fn NS.Six() -> i32 { return 6; }

fn Run() -> i32 {
  var Seven: i32 = 100;
  Core.Print(package.Seven() * package.NS.Six());
  Core.Print(Seven);
  return 0;
}
