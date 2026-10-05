// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/generic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/generic.carbon

// --- generic_type_impls_interface.carbon
library "[[@TEST_NAME]]";
import Cpp;

//@dump-sem-ir-begin
interface I {
  fn Doit(self) -> Self;
}

class A {
  impl as I {
    fn Doit(unused self) -> Self {
      return {};
    }
  }
}
class B {
  impl as I {
    fn Doit(unused self) -> Self {
      return {};
    }
  }
}

fn F[T: I](t: T) -> T {
  return t.Doit();
}

inline Cpp '''
Carbon::B CallInterfaceF() {
  Carbon::A a;
  Carbon::B b;
  Carbon::F(a);
  return Carbon::F(b);
}
''';
//@dump-sem-ir-end

// --- fail_todo_non_type_generic.carbon
library "[[@TEST_NAME]]";
import Cpp;

fn NonTypeF[unused N: i32]() {}

inline Cpp '''
void CallNonTypeF() {
  Carbon::NonTypeF<3>();
}
''';

// --- generic_pointer.carbon
library "[[@TEST_NAME]]";
import Cpp;

fn PointerF[T: type](unused t: T*) {}

inline Cpp '''
void CallPointerF() {
  int x = 0;
  int* _Nonnull p = &x;
  Carbon::PointerF(p);
}
''';

// --- fail_todo_enclosing_generic.carbon
library "[[@TEST_NAME]]";
import Cpp;

class EnclosingA(T: type) {
  fn MemberF[U: type](x: T, y: U);
}
alias EnclosingB = EnclosingA(i32);

inline Cpp '''
void CallEnclosingF() {
  // TODO: this currently fails because `EnclosingB` can't be imported, but the intent
  // is to test a generic function within an enclosing generic scope.
  //
  Carbon::EnclosingB b;
  b.MemberF(1, 2);
}
''';

// --- fail_generic_unsupported_type.carbon
library "[[@TEST_NAME]]";
import Cpp;

fn UnsupportedF[T: type](unused t: T) {}

inline Cpp '''
void CallUnsupportedF() {
  volatile int x;
  Carbon::UnsupportedF(x);
}
''';
