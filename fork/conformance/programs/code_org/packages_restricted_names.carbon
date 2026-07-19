// CONFORMANCE-BULLET: Code organization: Packages
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// Restricted package names: `Core` is reserved for the Core package, but the
// raw-identifier spelling `r#Core` declares an ordinary user class with that
// name in Main//default. Both coexist: plain `Core` keeps resolving to the
// imported package (`Core.Print`) while `r#Core` names the class. Shape from
// toolchain/check/testdata/packages/raw_core.carbon (class_raw_core file:
// `class r#Core { var n: Core.Int(32); }` + `var c: r#Core = {.n = ...}`).

import Core library "io";

class r#Core {
  var n: i32;

  fn Get(self) -> i32 {
    return self.n;
  }
}

fn Run() -> i32 {
  var c: r#Core = {.n = 42};
  Core.Print(c.Get());
  return 0;
}
