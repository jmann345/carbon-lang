// CONFORMANCE-BULLET: Code organization: Namespaces
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   42
//
// Namespace declaration, nested namespaces, defining functions into a
// namespace with qualified names, and calling them. Shapes verbatim from
// toolchain/lower/testdata/namespace/namespace_run.carbon (`namespace Foo;`
// + `fn Foo.Run() {}` alongside a Main `fn Run`) and toolchain/check/
// testdata/namespace/nested.carbon (`namespace Foo.Bar;` +
// `fn Foo.Bar.Wiz() {}` called as `Foo.Bar.Wiz()`).

import Core library "io";

namespace Math;

fn Math.Add(a: i32, b: i32) -> i32 { return a + b; }

namespace Math.Inner;

fn Math.Inner.Double(n: i32) -> i32 { return n * 2; }

fn Run() -> i32 {
  Core.Print(Math.Add(40, 2));
  Core.Print(Math.Inner.Double(21));
  return 0;
}
