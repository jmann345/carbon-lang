// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/sum_type_overload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/sum_type_overload.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1.4): an `overload fn` set probes
// each member by converting the arguments without diagnosing, then discards
// the probe; a sum-type conversion there builds no control flow and emits
// nothing, so a member that does not accept the argument is skipped and the
// member that does is called, in either direction and for a generic member.
// The element conversions of a tuple, struct or array argument are probed the
// same way, scalar elements included. A member whose parameter the argument
// converts to is accepted even where the call cannot build the conversion (at
// file scope, or at a template's instantiation), and the call reports that
// limit, so the member a call selects does not depend on where the call is.

// --- sum.h

// Mocks of libc++'s `std::optional` and `std::variant`, as string_view.carbon
// and span.carbon mock theirs, so the goldens are hermetic: the members the
// conversions call (`has_value`, `value`, `emplace`, `index`, `std::get`),
// libc++'s inline namespace, and `size_t` pinned by `--target`.
namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template <typename T>
    class optional {
     public:
      optional() : value_(), engaged_(false) {}
      optional(T value) : value_(value), engaged_(true) {}
      bool has_value() const { return engaged_; }
      const T& value() const { return value_; }
      template <typename... A>
      T& emplace(A... args) {
        value_ = T(args...);
        engaged_ = true;
        return value_;
      }

     private:
      T value_;
      bool engaged_;
    };

    struct monostate {};

    template <typename... Ts>
    class variant {
     public:
      variant() : index_(0) { emplace<0>(); }
      size_t index() const { return index_; }
      template <size_t I, typename... A>
      __type_pack_element<I, Ts...>& emplace(A... args) {
        index_ = I;
        auto* p = reinterpret_cast<__type_pack_element<I, Ts...>*>(storage_);
        *p = __type_pack_element<I, Ts...>(args...);
        return *p;
      }
      alignas(8) unsigned char storage_[8];
      size_t index_;
    };

    template <size_t I, typename... Ts>
    const __type_pack_element<I, Ts...>& get(const variant<Ts...>& v) {
      return *reinterpret_cast<const __type_pack_element<I, Ts...>*>(
          v.storage_);
    }
  }
}

struct Point {
  int x;
  int y;
};

inline auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) return std::optional<int>(n);
  return std::optional<int>();
}

inline int cell = 0;

inline auto MakePointer(int n) -> std::optional<int*> {
  if (n > 0) return std::optional<int*>(&cell);
  return std::optional<int*>();
}

inline auto MakePoint() -> std::optional<Point> {
  return std::optional<Point>(Point{1, 2});
}

inline auto Take(std::optional<int> o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto TakeRef(const std::optional<int>& o) -> int {
  return o.has_value() ? o.value() : -2;
}

inline auto MakeMono(int n) -> std::optional<std::monostate> {
  if (n > 0) return std::optional<std::monostate>(std::monostate());
  return std::optional<std::monostate>();
}

inline auto TakeMono(std::optional<std::monostate> o) -> bool {
  return o.has_value();
}

// --- convert_first.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(o: Core.CppCompat.StdOptional(i32)) -> i32 {
  match (o) {
    case .Some(n: i32) => {
      return n;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick(Cpp.MakeOptional(7));
}

// --- convert_second.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused b: bool) -> i32 { return 100; }
overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 1;
}

fn F() -> i32 {
  return Pick(Cpp.MakeOptional(7));
}

// --- mismatch_first.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused o: Core.CppCompat.StdOptional(i64)) -> i32 {
  return 1;
}
overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 2;
}

fn F() -> i32 {
  return Pick(Cpp.MakeOptional(7));
}

// --- not_mapped_first.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 1;
}
overload fn Pick(o: Cpp.std.optional(Cpp.Point)) -> i32 {
  return o.value().x;
}

fn F() -> i32 {
  return Pick(Cpp.MakePoint());
}

// --- reverse.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused b: bool) -> i32 { return 100; }
overload fn Pick(o: Cpp.std.optional(i32)) -> i32 {
  return o.value();
}

fn F() -> i32 {
  return Pick(Core.CppCompat.StdOptional(i32).Some(3));
}

// --- generic_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick[T: Core.Copy & Core.Destroy](unused x: T,
                                              o: Core.CppCompat.StdOptional(i32))
    -> i32 {
  match (o) {
    case .Some(n: i32) => {
      return n;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}
overload fn Pick(unused x: bool, unused y: bool) -> i32 { return 0; }

fn F() -> i32 {
  return Pick(1 as i32, Cpp.MakeOptional(7));
}

// --- tuple_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused t: (Core.CppCompat.StdOptional(i32), i32)) -> i32 {
  return 1;
}
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick((Cpp.MakeOptional(7), 1));
}

// --- tuple_mismatch_first.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused t: (Core.CppCompat.StdOptional(i64), i32)) -> i32 {
  return 1;
}
overload fn Pick(unused t: (Core.CppCompat.StdOptional(i32), i32)) -> i32 {
  return 2;
}

fn F() -> i32 {
  return Pick((Cpp.MakeOptional(7), 1));
}

// --- struct_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused b: bool) -> i32 { return 100; }
overload fn Pick(unused s: {.a: Core.CppCompat.StdOptional(i32), .b: i32})
    -> i32 {
  return 1;
}

fn F() -> i32 {
  return Pick({.a = Cpp.MakeOptional(7), .b = 1});
}

// --- array_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused a: array(Core.CppCompat.StdOptional(i32), 1)) -> i32 {
  return 1;
}
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick((Cpp.MakeOptional(7),));
}

// --- tuple_reverse.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(t: (Cpp.std.optional(i32), i32)) -> i32 {
  return Cpp.Take(t.0) + t.1;
}
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick((Core.CppCompat.StdOptional(i32).Some(4), 1));
}

// --- tuple_core_optional.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused t: (Core.Optional(i32), i32)) -> i32 { return 1; }
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick((Cpp.MakeOptional(7), 1));
}

// --- generic_tuple_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick[T: Core.Copy & Core.Destroy](
    unused x: T, unused t: (Core.Optional(i32), i32)) -> i32 {
  return 1;
}
overload fn Pick(unused x: bool, unused y: bool) -> i32 { return 0; }

fn F() -> i32 {
  return Pick(1 as i32, (Cpp.MakeOptional(7), 1));
}

// --- scalar_tuple_mismatch_first.carbon

library "[[@TEST_NAME]]";

// No sum type: the first member's tuple elements are probed without
// diagnosing, so it is skipped with no error, and the second is called, as the
// return type shows.
overload fn Pick(unused t: (i32, i32)) -> i32 { return 1; }
overload fn Pick(unused t: (bool, bool)) -> bool { return true; }

fn F() -> bool {
  return Pick((true, false));
}

// --- fail_todo_file_scope.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 1;
}
overload fn Pick(unused o: Cpp.std.optional(i32)) -> i32 { return 2; }

// At file scope the sum-type conversion cannot be built (W-036). The argument
// converts to the first member's parameter, so the probe accepts that member,
// and the call reports the limit rather than calling the second member.
let x: i32 = Pick(Cpp.MakeOptional(7));

// --- fail_todo_template_overload.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 1;
}
overload fn Pick[T: Core.Copy & Core.Destroy](unused x: T) -> i32 {
  return 2;
}

// A template performs the call's conversion at its instantiation, where the
// sum-type conversion cannot be built either (§1.10): the probe accepts the
// first member, and the instantiation reports the limit rather than calling
// the generic member.
fn Call[template T: type](x: T) -> i32 {
  return Pick(x);
}

fn F() -> i32 {
  return Call(Cpp.MakeOptional(7));
}
