// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/variant.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/variant.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1, F-020): a
// `std::variant<Ts...>` specialization of one to eight alternatives
// converts by value to `Core.CppCompat.StdVariant<N>(Ts'...)`, whose
// alternative `.Alt<I>` is the C++ alternative `I`: `index()`, then
// `std::get<I>`; back through the default constructor and `emplace<I>`.

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

inline auto IntOrHalf(int n) -> std::variant<int, double> {
  std::variant<int, double> v;
  if (n > 0) {
    v.emplace<0>(n);
  } else {
    v.emplace<1>(n * 0.5);
  }
  return v;
}

inline auto MaybeEmpty(int n) -> std::variant<std::monostate, int> {
  std::variant<std::monostate, int> v;
  if (n > 0) v.emplace<1>(n);
  return v;
}

inline auto LeftOrRight(int n) -> std::variant<int, int> {
  std::variant<int, int> v;
  v.emplace<1>(n);
  return v;
}

inline auto TakePair(const std::variant<int, int>& v) -> int {
  return static_cast<int>(v.index());
}

using Nine = std::variant<int, int, int, int, int, int, int, int, int>;
inline auto MakeNine() -> Nine { return Nine(); }

inline auto Nested() -> std::variant<std::optional<int>, int> {
  return std::variant<std::optional<int>, int>();
}

// --- match.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Predicted: one `index` thunk call, one equality test per alternative but
// the last, a `std::get<I>` thunk call per alternative, and
// `StdVariant2(i32, f64).Alt<I>` into one `temporary_storage`.
//@dump-sem-ir-begin
fn F(n: i32) -> i32 {
  match (Cpp.IntOrHalf(n)) {
    case .Alt0(i: i32) => {
      return i;
    }
    case .Alt1(unused d: f64) => {
      return -1;
    }
  }
  return -2;
}
//@dump-sem-ir-end

// --- monostate.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::monostate` alternative has the payload `()`; no `std::get` call.
//@dump-sem-ir-begin
fn M(n: i32) -> i32 {
  match (Cpp.MaybeEmpty(n)) {
    case .Alt0(unused empty: ()) => {
      return 0;
    }
    case .Alt1(i: i32) => {
      return i;
    }
  }
  return -1;
}
//@dump-sem-ir-end

// --- duplicate.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Duplicate alternative types are told apart by index, both ways.
//@dump-sem-ir-begin
fn D(n: i32) -> i32 {
  match (Cpp.LeftOrRight(n)) {
    case .Alt0(unused left: i32) => {
      return 0;
    }
    case .Alt1(right: i32) => {
      return Cpp.TakePair(Core.CppCompat.StdVariant2(i32, i32).Alt1(right));
    }
  }
  return -1;
}
//@dump-sem-ir-end

// --- fail_todo_too_many_alternatives.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// `Core.CppCompat` declares `StdVariant1` to `StdVariant8` (plan §1.2).
fn N() -> i32 {
  match (Cpp.MakeNine()) {
    default => {
      return 0;
    }
  }
  return 1;
}

// --- fail_todo_nested_by_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::optional` held by value in a `std::variant` is a class payload
// (SF-6, plan §1.3); held by pointer it is a pointer payload.
fn V() -> i32 {
  match (Cpp.Nested()) {
    default => {
      return 0;
    }
  }
  return 1;
}

// --- fail_index_out_of_range.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn R(n: i32) -> i32 {
  match (Cpp.IntOrHalf(n)) {
    case .Alt2(i: i32) => {
      return i;
    }
    default => {
      return -1;
    }
  }
  return -2;
}

