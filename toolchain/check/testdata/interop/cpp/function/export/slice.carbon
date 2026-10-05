// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/slice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/slice.carbon

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-8): exporting a Carbon function
// whose parameter is `Core.Slice(const i32)` to C++ maps the parameter to
// `std::span<const int>`, the class template found BY NAME in the TU and
// instantiated on the recursively mapped element type (the `Core.Result` ->
// `Carbon::expected` shape, result_expected.carbon). The inline C++ mocks
// `std::span` (D-SL-14) with the pointer-then-size layout and a `(T*, size_t)`
// constructor. Predicted: no diagnostics; the exported declaration's parameter
// type is `std::span<const int>`, and `Cpp.F` calls `Carbon::Sum` through the
// export-side thunk.

// --- slice.carbon

library "[[@TEST_NAME]]";

import Cpp;

fn Sum(s: Core.Slice(const i32)) -> i32 {
  var total: i32 = 0;
  var i: i64 = 0;
  while (i < s.Size()) {
    total += s[i];
    ++i;
  }
  return total;
}

inline Cpp '''
namespace std {
  using size_t = __SIZE_TYPE__;
  inline namespace __1 {
    inline constexpr size_t dynamic_extent = static_cast<size_t>(-1);
    template <typename T, size_t Extent = dynamic_extent>
    class span {
     public:
      span(T* p, size_t n) : data_(p), size_(n) {}
      T* data() const { return data_; }
      size_t size() const { return size_; }
     private:
      T* data_;
      size_t size_;
    };
  }
}

inline int F() {
  int a[2] = {1, 2};
  return Carbon::Sum(std::span<const int>(a, 2));
}
''';

//@dump-sem-ir-begin
fn G() -> i32 { return Cpp.F(); }
//@dump-sem-ir-end

// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:[[@LINE+61]]:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:[[@LINE+57]]:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:[[@LINE+53]]:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDOUT: --- slice.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %F.cpp_overload_set.type: type = cpp_overload_set_type @F.cpp_overload_set [concrete]
// CHECK:STDOUT:   %F.cpp_overload_set.value: %F.cpp_overload_set.type = cpp_overload_set_value @F.cpp_overload_set [concrete]
// CHECK:STDOUT:   %F__carbon_thunk.type: type = fn_type @F__carbon_thunk [concrete]
// CHECK:STDOUT:   %F__carbon_thunk: %F__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .F = %F.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %F.cpp_overload_set.value: %F.cpp_overload_set.type = cpp_overload_set_value @F.cpp_overload_set [concrete = constants.%F.cpp_overload_set.value]
// CHECK:STDOUT:   %F__carbon_thunk.decl: %F__carbon_thunk.type = fn_decl @F__carbon_thunk [concrete = constants.%F__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc41: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %F.ref: %F.cpp_overload_set.type = name_ref F, imports.%F.cpp_overload_set.value [concrete = constants.%F.cpp_overload_set.value]
// CHECK:STDOUT:   %F__carbon_thunk.call: init %i32 = call imports.%F__carbon_thunk.decl()
// CHECK:STDOUT:   return %F__carbon_thunk.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
