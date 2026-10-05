// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
// EXTRA-ARGS: --share-cpp-ast
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/basics/import/indirect.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/basics/import/indirect.carbon

// --- shared.h

namespace A {
  struct X {
    X(int);
    int g();
    int x;
  };

  template<typename T>
  struct Y {
    T y;
  };

  struct Z {
    int z;
  };
}

// --- direct_import.carbon

library "[[@TEST_NAME]]";

import Cpp library "shared.h";

fn F() -> Cpp.A.X { return 1; }

fn G() -> Cpp.A.Y(i32);

fn H() -> Cpp.A.Y(Cpp.A.Z);

alias AX = Cpp.A.X;

// --- indirect_import_via_function.carbon

library "[[@TEST_NAME]]";

// TODO: Should be `export import Cpp ...`.
import Cpp library "shared.h";
import library "direct_import";

fn Field() -> i32 {
  //@dump-sem-ir-begin
  return F().x;
  //@dump-sem-ir-end
}

fn Function() -> i32 {
  //@dump-sem-ir-begin
  return F().g();
  //@dump-sem-ir-end
}

// --- not_included.carbon

library "[[@TEST_NAME]]";

import Cpp;
import library "direct_import";

fn Field() -> i32 {
  return F().x;
}

// --- fail_not_leaked.carbon

library "[[@TEST_NAME]]";

import Cpp;
inline Cpp '''
namespace A {
  struct X;
}
''';

fn TryToUseNotLeaked() {
  // TODO: Clang's diagnostic for using a class whose definition is not
  // reachable is confusing.
  var unused x: Cpp.A.X = 0;
}

// --- no_cpp_import.carbon

library "[[@TEST_NAME]]";

import library "direct_import";

fn Field() -> i32 {
  return F().x;
}

// --- indirect_import_via_alias.carbon

library "[[@TEST_NAME]]";

import Cpp library "shared.h";
import library "direct_import";

fn Use() -> (i32, i32) {
  //@dump-sem-ir-begin
  var ax: AX = 1;
  return (ax.x, ax.g());
  //@dump-sem-ir-end
}

// --- import_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "shared.h";
import library "direct_import";

fn Use() -> i32 {
  //@dump-sem-ir-begin
  return G().y;
  //@dump-sem-ir-end
}

fn UseZ() -> Cpp.A.Z {
  //@dump-sem-ir-begin
  return H().y;
  //@dump-sem-ir-end
}
