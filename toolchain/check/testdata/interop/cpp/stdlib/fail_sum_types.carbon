// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_sum_types.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_sum_types.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1.11): the shapes outside the
// `std::optional`/`std::variant` mapping, each diagnosed, none a crash.

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
      template <typename U>
      optional(const optional<U>& other) : value_(), engaged_(false) {
        if (other.has_value()) emplace(other.value());
      }
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
inline auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) return std::optional<int>(n);
  return std::optional<int>();
}

inline auto MakeConst() -> std::optional<const int> {
  return std::optional<const int>();
}

struct NonTrivial {
  ~NonTrivial() {}
  int n;
};

inline auto MakeNonTrivial() -> std::optional<NonTrivial> {
  return std::optional<NonTrivial>();
}

inline auto Take(std::optional<int> o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto TakeLong(std::optional<long> o) -> long {
  return o.has_value() ? o.value() : -1;
}

struct Wrapper {
  Wrapper(std::optional<int> o) : n(o.has_value() ? o.value() : -1) {}
  int n;
};

inline auto TakeWrapper(Wrapper w) -> int { return w.n; }

// --- fail_todo_qualified_alternative.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The mock `optional<const int>` is trivially copyable, so the qualified
// alternative is the rule that fails (§1.3 rule 3).
fn F() {
  match (Cpp.MakeConst()) {
    default => {}
  }
}

// --- fail_todo_non_trivial.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A class with a non-trivial destructor (§1.3 rule 1).
fn N() {
  match (Cpp.MakeNonTrivial()) {
    default => {}
  }
}

// --- fail_conversion_mismatch.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A C++ sum type converts only to its own Carbon sum type.
fn G() {
  let unused s: Core.CppCompat.StdOptional(i64) = Cpp.MakeOptional(1);
}

// --- fail_core_optional_mismatch.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::optional<int>` converts in one step to `Core.Optional(i32)` only.
fn H() {
  let unused o: Core.Optional(i64) = Cpp.MakeOptional(1);
}

// --- core_optional_argument_as.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn K() -> i32 {
  return Cpp.Take(Core.Optional(i32).Some(3) as Core.CppCompat.StdOptional(i32));
}

// --- fail_todo_export_sum_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `Core.CppCompat` sum type in a signature that C++ calls is not exported;
// the C++ class is the exportable spelling.
fn MakeView(x: i32) -> Core.CppCompat.StdOptional(i32) {
  return Core.CppCompat.StdOptional(i32).Some(x);
}

inline Cpp '''
inline int Use() { Carbon::MakeView(3); return 1; }
''';

// --- fail_reverse_other_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A Carbon sum value converts only to the C++ class whose sum type it is, not
// to another specialization through C++'s converting constructor, which would
// narrow or widen the payload silently (§1.5).
fn L() -> i64 {
  return Cpp.TakeLong(Core.CppCompat.StdOptional(i32).Some(3));
}

// --- fail_reverse_converting_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Nor to a class with a converting constructor from that class.
fn W() -> i32 {
  return Cpp.TakeWrapper(Core.CppCompat.StdOptional(i32).Some(3));
}

// --- fail_todo_tuple_scrutinee.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A C++ sum class inside a tuple scrutinee is not converted (§1.11).
fn T() {
  let t: (Cpp.std.optional(i32), i32) = (Cpp.MakeOptional(1), 2);
  match (t) {
    default => {}
  }
}

// --- fail_todo_if_arm.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A conversion inside an `if`-expression arm makes temporaries that the arm
// must destroy before yielding a value whose representation is not a copy: the
// existing conditional-operand cleanup TODO (§1.11).
fn I(c: bool) {
  let unused s: Core.CppCompat.StdOptional(i32) =
      if c then Cpp.MakeOptional(1) else Cpp.MakeOptional(0);
}

// --- fail_todo_template_conversion.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A template defers the conversion of its dependent value to instantiation,
// where no control flow can be built (§1.10).
fn Pass[template T: type](x: T) -> Core.CppCompat.StdOptional(i32) {
  return x;
}

fn U() {
  let unused s: Core.CppCompat.StdOptional(i32) = Pass(Cpp.MakeOptional(1));
}

// --- sink.h

#include "sum.h"

inline auto TakeRvalue(std::optional<int>&& o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto Put(const std::optional<int>& o) -> int {
  return o.has_value() ? 100 + o.value() : -100;
}

inline auto Put(std::optional<int>&& o) -> int {
  return o.has_value() ? 200 + o.value() : -200;
}

// --- fail_todo_rvalue_ref_param.carbon

library "[[@TEST_NAME]]";

import Cpp library "sink.h";

// A sum value or `Core.Optional` passed to a C++ `T&&` parameter, alone or the
// member C++ selects from a `const T&` and `T&&` pair, initializes the
// parameter at its C++ declaration, which gives the conversion no parse node
// for its branches (§1.5, §1.11).
fn R() -> i32 {
  return Cpp.TakeRvalue(Core.CppCompat.StdOptional(i32).Some(5));
}

fn P() -> i32 {
  return Cpp.Put(Core.Optional(i32).Some(6));
}

// A value, such as a parameter, selects the `const&` member, which converts.
fn V(o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return Cpp.Put(o);
}
