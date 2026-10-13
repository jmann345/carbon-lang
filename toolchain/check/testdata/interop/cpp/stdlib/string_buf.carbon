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
  Cpp.Consume(b);
}
