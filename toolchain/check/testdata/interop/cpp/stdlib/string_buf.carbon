// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/string_buf.carbon
// CHECK:STDERR: {{.*}}/prelude/types/string.carbon:141:1: error: semantics TODO: `interop with non-identifier package name` [SemanticsTodo]
// CHECK:STDERR: class StringBuf {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// Fork (ST-1, fork/string/plan.md §4): a `Core.StringBuf` reaches a C++
// `std::string_view` parameter through its explicit view `AsStr()` (D-ST-12),
// bound to a `let` first: a call result passed straight to a parameter of this
// mock `basic_string_view` crashes Clang, with or without ST-1 (W-165);
// passed directly, C++ overload resolution cannot see the Carbon
// `ImplicitAs(str)` conversion and the argument's type cannot be exported, so
// the call is diagnosed instead of crashing the compiler (D-ST-12).

// --- string_view.h

namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template<typename T> struct char_traits {};

    template<typename CharT, typename Traits = char_traits<CharT>>
    class basic_string_view {
     public:
      basic_string_view() = default;
      size_t size() const { return size_; }

     private:
      const CharT* data_;
      size_t size_;
    };

    using string_view = basic_string_view<char>;
  }
}

auto Consume(std::string_view sv) -> void;

// --- as_str.carbon

library "[[@TEST_NAME]]";

import Cpp library "string_view.h";

//@dump-sem-ir-begin
fn F(b: Core.StringBuf) {
  let v: str = b.AsStr();
  Cpp.Consume(v);
}
//@dump-sem-ir-end

// --- fail_buf_arg.carbon

library "[[@TEST_NAME]]";

import Cpp library "string_view.h";

fn G(b: Core.StringBuf) {
  // CHECK:STDERR: fail_buf_arg.carbon:[[@LINE+4]]:15: error: call argument of type `Core.StringBuf` is not supported [CppCallArgTypeNotSupported]
  // CHECK:STDERR:   Cpp.Consume(b);
  // CHECK:STDERR:               ^
  // CHECK:STDERR:
  Cpp.Consume(b);
}

// CHECK:STDOUT: --- as_str.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %StringBuf: type = class_type @StringBuf [concrete]
// CHECK:STDOUT:   %int_64: Core.IntLiteral = int_value 64 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %i64: type = class_type @Int, @Int(%int_64) [concrete]
// CHECK:STDOUT:   %char: type = class_type @Char [concrete]
// CHECK:STDOUT:   %ptr.b46: type = ptr_type %char [concrete]
// CHECK:STDOUT:   %struct_type.ptr.size: type = struct_type {.ptr: %ptr.b46, .size: %i64} [concrete]
// CHECK:STDOUT:   %pattern_type.5d2: type = pattern_type %StringBuf [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.5d2 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.5d2 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %str: type = class_type @String [concrete]
// CHECK:STDOUT:   %pattern_type.adf: type = pattern_type %str [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.adf = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %StringBuf.AsStr.type: type = fn_type @StringBuf.AsStr [concrete]
// CHECK:STDOUT:   %StringBuf.AsStr: %StringBuf.AsStr.type = struct_value () [concrete]
// CHECK:STDOUT:   %Consume.cpp_overload_set.type: type = cpp_overload_set_type @Consume.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Consume.cpp_overload_set.value: %Consume.cpp_overload_set.type = cpp_overload_set_value @Consume.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ptr.e6f: type = ptr_type %str [concrete]
// CHECK:STDOUT:   %Consume__carbon_thunk.type: type = fn_type @Consume__carbon_thunk [concrete]
// CHECK:STDOUT:   %Consume__carbon_thunk: %Consume__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %pattern_type.854: type = pattern_type %ptr.b46 [concrete]
// CHECK:STDOUT:   %self.param_patt.b83: %pattern_type.854 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.f58: %pattern_type.854 = wrapper_binding_pattern self, %self.param_patt.b83 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_24.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc8_24.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_24.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.f57: type = pattern_type %i64 [concrete]
// CHECK:STDOUT:   %self.param_patt.108: %pattern_type.f57 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.5f4: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt.108 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_24.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc8_24.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_24.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.8af: type = pattern_type %struct_type.ptr.size [concrete]
// CHECK:STDOUT:   %self.param_patt.9fd: %pattern_type.8af = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.95d: %pattern_type.8af = wrapper_binding_pattern self, %self.param_patt.9fd [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_24.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc8_24.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.dc5: %pattern_type.adf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.939: %pattern_type.adf = wrapper_binding_pattern self, %self.param_patt.dc5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc8_24.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %String.elem.f15: type = unbound_element_type %str, %i64 [concrete]
// CHECK:STDOUT:   %String.elem.0b2: type = unbound_element_type %str, %ptr.b46 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc8_24.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc8_24.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .StringBuf = %Core.StringBuf
// CHECK:STDOUT:     .String = %Core.String
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .Consume = %Consume.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StringBuf: type = import_ref Core//prelude/types/string, StringBuf, loaded [concrete = constants.%StringBuf]
// CHECK:STDOUT:   %Core.import_ref.ea4: %StringBuf.AsStr.type = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = constants.%StringBuf.AsStr]
// CHECK:STDOUT:   %Core.String: type = import_ref Core//prelude/types/string, String, loaded [concrete = constants.%str]
// CHECK:STDOUT:   %Core.import_ref.c9c: %String.elem.0b2 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = %field_decl.b1e]
// CHECK:STDOUT:   %Core.import_ref.704: %String.elem.f15 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, loaded [concrete = %field_decl.e70]
// CHECK:STDOUT:   %Consume.cpp_overload_set.value: %Consume.cpp_overload_set.type = cpp_overload_set_value @Consume.cpp_overload_set [concrete = constants.%Consume.cpp_overload_set.value]
// CHECK:STDOUT:   %Consume__carbon_thunk.decl: %Consume__carbon_thunk.type = fn_decl @Consume__carbon_thunk [concrete = constants.%Consume__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.import_ref.9cc = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %field_decl.e70: %String.elem.f15 = field_decl size, element1, %Core.import_ref.9cc in [concrete] {}
// CHECK:STDOUT:   %Core.import_ref.be6 = import_ref Core//prelude/types/string, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %field_decl.b1e: %String.elem.0b2 = field_decl ptr, element0, %Core.import_ref.be6 in [concrete] {}
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_24.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.854 = ref_param_pattern [concrete = constants.%self.param_patt.b83]
// CHECK:STDOUT:     %self.patt: %pattern_type.854 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.f58]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ptr.b46 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ptr.b46 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc8_24.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.854 = ref_param_pattern [concrete = constants.%self.param_patt.b83]
// CHECK:STDOUT:     %self.patt: %pattern_type.854 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.f58]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %ptr.b46 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %ptr.b46 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_24.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc8_24.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.f57 = ref_param_pattern [concrete = constants.%self.param_patt.108]
// CHECK:STDOUT:     %self.patt: %pattern_type.f57 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.5f4]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i64 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i64 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_24.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.8af = ref_param_pattern [concrete = constants.%self.param_patt.9fd]
// CHECK:STDOUT:     %self.patt: %pattern_type.8af = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.95d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.ptr.size = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.ptr.size = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc8_24.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.8af = ref_param_pattern [concrete = constants.%self.param_patt.9fd]
// CHECK:STDOUT:     %self.patt: %pattern_type.8af = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.95d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.ptr.size = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.ptr.size = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc8_24.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.adf = ref_param_pattern [concrete = constants.%self.param_patt.dc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.adf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.939]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %str = ref_param call_param0
// CHECK:STDOUT:     %self: ref %str = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc8_24.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.adf = ref_param_pattern [concrete = constants.%self.param_patt.dc5]
// CHECK:STDOUT:     %self.patt: %pattern_type.adf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.939]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %str = ref_param call_param0
// CHECK:STDOUT:     %self: ref %str = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.5d2 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.5d2 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %b.param: %StringBuf = value_param call_param0
// CHECK:STDOUT:     %.loc7: type = splice_block %StringBuf.ref [concrete = constants.%StringBuf] {
// CHECK:STDOUT:       %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:       %StringBuf.ref: type = name_ref StringBuf, imports.%Core.StringBuf [concrete = constants.%StringBuf]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %b: %StringBuf = wrapper_binding b, %b.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%b.param: %StringBuf) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: %StringBuf = name_ref b, %b
// CHECK:STDOUT:   %AsStr.ref: %StringBuf.AsStr.type = name_ref AsStr, imports.%Core.import_ref.ea4 [concrete = constants.%StringBuf.AsStr]
// CHECK:STDOUT:   %StringBuf.AsStr.bound: <bound method> = bound_method %b.ref, %AsStr.ref
// CHECK:STDOUT:   %.loc8_24.1: ref %str = temporary_storage
// CHECK:STDOUT:   %StringBuf.AsStr.call: init %str to %.loc8_24.1 = call %StringBuf.AsStr.bound(%b.ref)
// CHECK:STDOUT:   %.loc8_24.2: ref %str = temporary %.loc8_24.1, %StringBuf.AsStr.call
// CHECK:STDOUT:   %.loc8_24.3: %str = acquire_value %.loc8_24.2
// CHECK:STDOUT:   %str: type = type_literal constants.%str [concrete = constants.%str]
// CHECK:STDOUT:   %v: %str = wrapper_binding v, %.loc8_24.3
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.adf = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Consume.ref: %Consume.cpp_overload_set.type = name_ref Consume, imports.%Consume.cpp_overload_set.value [concrete = constants.%Consume.cpp_overload_set.value]
// CHECK:STDOUT:   %v.ref: %str = name_ref v, %v
// CHECK:STDOUT:   %.loc9: ref %str = value_as_ref %v.ref
// CHECK:STDOUT:   %addr: %ptr.e6f = addr_of %.loc9
// CHECK:STDOUT:   %Consume__carbon_thunk.call: init %empty_tuple.type = call imports.%Consume__carbon_thunk.decl(%addr)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc8_24.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc8_24.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_24.1(%self.param: ref %ptr.b46) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_24.1(%self.param: ref %ptr.b46) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_24.1(%self.param: ref %ptr.b46) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_24.2(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_24.2(%self.param: ref %i64) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_24.2(%self.param: ref %i64) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_24.3(%self.param: ref %struct_type.ptr.size) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc8_24.1: ref %i64 = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_24.1: <bound method> = bound_method %.loc8_24.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_24.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_24.1(%.loc8_24.1)
// CHECK:STDOUT:   %.loc8_24.2: ref %ptr.b46 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_24.2: <bound method> = bound_method %.loc8_24.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_24.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_24.2(%.loc8_24.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_24.3(%self.param: ref %struct_type.ptr.size) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_24.3(%self.param: ref %struct_type.ptr.size) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc8_24.4(%self.param: ref %str) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %size.ref: %String.elem.f15 = name_ref size, imports.%Core.import_ref.704 [concrete = imports.%field_decl.e70]
// CHECK:STDOUT:   %.loc8_24.1: ref %i64 = class_element_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_24.1: <bound method> = bound_method %.loc8_24.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_24.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_24.1(%.loc8_24.1)
// CHECK:STDOUT:   %ptr.ref: %String.elem.0b2 = name_ref ptr, imports.%Core.import_ref.c9c [concrete = imports.%field_decl.b1e]
// CHECK:STDOUT:   %.loc8_24.2: ref %ptr.b46 = class_element_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc8_24.2: <bound method> = bound_method %.loc8_24.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc8_24.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc8_24.2(%.loc8_24.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc8_24.4(%self.param: ref %str) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc8_24.4(%self.param: ref %str) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
