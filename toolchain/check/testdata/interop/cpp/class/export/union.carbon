// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/union.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/union.carbon

// A Carbon `union` exports to C++ as a genuine union (docs/design/unions.md,
// "Exporting Carbon unions to C++"; fork/unions/plan.md UN-2, D-UN-8): the
// record is created with `TagTypeKind::Union`, Carbon supplies the layout
// (size and alignment from the `CustomLayoutType` block, offset zero for every
// field), no `final` attribute and no destructor declaration are attached, and
// methods export as for classes. The `static_assert`s are the layout arbiter:
// they run in the embedded Clang, so a wrong tag kind fails `__is_union` and a
// layout disagreement fails `sizeof`/`alignof`, both as compile failures of
// this test. Passing an exported union by value INTO C++ is probed separately
// in union_by_value.carbon.

// --- exported.carbon
library "[[@TEST_NAME]]";
import Cpp;

union Wide {
  var lo: i32;
  var both: i64;
  fn Low(self) -> i32 { return self.lo; }
}

inline Cpp '''
static_assert(__is_union(Carbon::Wide), "kind");
static_assert(sizeof(Carbon::Wide) == 8 && alignof(Carbon::Wide) == 8,
              "layout");

int Use(Carbon::Wide* w) {
  w->lo = 3;
  return w->Low();
}

Carbon::Wide MakeWide(int v) {
  Carbon::Wide w;
  w.lo = v;
  return w;
}
''';

fn F() -> i32 {
  //@dump-sem-ir-begin
  var w: Wide = Cpp.MakeWide(1);
  return Cpp.Use(&w);
  //@dump-sem-ir-end
}

// --- static_method.carbon
library "[[@TEST_NAME]]";
import Cpp;

// The union as a C++ name scope (`Carbon::Wide::Zero`), the entry the UN-1
// placeholder guarded in `ExportNameScopeToCpp`.
union Wide {
  var lo: i32;
  var both: i64;
  fn Zero() -> i32 { return 0; }
}

inline Cpp '''
int CallZero() { return Carbon::Wide::Zero(); }
''';

fn F() -> i32 {
  //@dump-sem-ir-begin
  return Cpp.CallZero();
  //@dump-sem-ir-end
}
