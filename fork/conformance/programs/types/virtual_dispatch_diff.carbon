// CONFORMANCE-BULLET: Type system: Virtual dispatch
// EXPECT-EXIT: 0
//
// Differential pair: virtual_dispatch_diff.diff.cpp is the equivalent C++17
// program (virtual member functions called through a base pointer); the
// runner requires byte-identical exit code and stdout, so real C++ vtable
// dispatch is the oracle — no hand-authored EXPECT-STDOUT. Carbon shapes
// verbatim from types/virtual_dispatch.carbon / toolchain/lower/testdata/
// class/virtual.carbon (`virtual fn`/`override fn`, `{.base = {}}`
// construction, derived-to-base pointer conversion, `v->Fn()`).

import Core library "io";

base class Instrument {
  virtual fn Strings(self) -> i32 { return 0; }
}

class Guitar {
  extend base: Instrument;
  override fn Strings(self) -> i32 { return 6; }
}

class Cello {
  extend base: Instrument;
  override fn Strings(self) -> i32 { return 4; }
}

fn PrintStrings(inst: Instrument*) {
  Core.Print(inst->Strings());
}

fn Run() -> i32 {
  var plain: Instrument = {};
  var guitar: Guitar = {.base = {}};
  var cello: Cello = {.base = {}};
  PrintStrings(&plain);
  PrintStrings(&guitar);
  PrintStrings(&cello);
  return 0;
}
