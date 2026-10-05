// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/globals.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/globals.carbon

// ============================================================================
// Global variables
// ============================================================================

// --- global.h

class C {};
C global;

// --- import_global.carbon

library "[[@TEST_NAME]]";

import Cpp library "global.h";

fn MyF() {
  let _: Cpp.C = Cpp.global;
}

// ============================================================================
// Inline variable
// ============================================================================

// --- inline.h

struct InlineC {
  InlineC();
  ~InlineC();
  void f();
};
inline InlineC inline_global;

// --- import_inline.carbon

library "[[@TEST_NAME]]";

import Cpp library "inline.h";

fn CallF() {
  Cpp.inline_global.f();
}

// ============================================================================
// Thread-local variable
// ============================================================================

// --- thread_local.h

thread_local int thread_local_global;

int init();
thread_local int thread_local_global_with_init = init();

// --- todo_import_thread_local.carbon

library "[[@TEST_NAME]]";

import Cpp library "thread_local.h";

// TODO: We should call the C++ thread wrapper function here instead of directly
// accessing the global. We fail to trigger the initialization of the global.

fn ThreadLocalStore() {
  Cpp.thread_local_global = 42;
}

fn ThreadLocalTriggerInit() -> i32 {
  return Cpp.thread_local_global_with_init;
}

// ============================================================================
// Static data members
// ============================================================================

// --- static.h

struct X {
  static inline int n = 42;
};

// --- import_static.carbon

library "[[@TEST_NAME]]";

import Cpp library "static.h";

fn ReadStatic() -> i32 {
  return Cpp.X.n;
}

// ============================================================================
// Variable templates
// ============================================================================

// --- var_template.h

template<typename T> T tmpl = T();

struct Y {
  Y();
};

// --- import_var_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "var_template.h";

fn ReadVarTemplate() -> i32 {
  return Cpp.tmpl(i32);
}

fn ReadVarTemplateWithConstructor() -> Cpp.Y* {
  return &Cpp.tmpl(Cpp.Y);
}

// ============================================================================
// Static data member templates
// ============================================================================

// --- static_template.h

struct StaticTmplX {
  template<typename T> static T static_tmpl = T();
};

struct Y {
  Y();
};

// --- import_static_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "static_template.h";

fn ReadStaticVarTemplate() -> i32 {
  return Cpp.StaticTmplX.static_tmpl(i32);
}

fn ReadStaticVarTemplateWithConstructor() -> Cpp.Y* {
  return &Cpp.StaticTmplX.static_tmpl(Cpp.Y);
}
