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
  // CHECK:STDERR: fail_todo_qualified_alternative.carbon:[[@LINE+7]]:9: error: C++ type `std::optional<const int>` has no Carbon sum type [CppSumTypeNotMapped]
  // CHECK:STDERR:   match (Cpp.MakeConst()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_todo_qualified_alternative.carbon:[[@LINE+4]]:9: note: alternative 0 has qualified or reference type `const int` [CppSumTypeQualifiedAlternative]
  // CHECK:STDERR:   match (Cpp.MakeConst()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  match (Cpp.MakeConst()) {
    default => {}
  }
}

// --- fail_todo_non_trivial.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A class with a non-trivial destructor (§1.3 rule 1).
fn N() {
  // CHECK:STDERR: fail_todo_non_trivial.carbon:[[@LINE+7]]:9: error: C++ type `std::optional<NonTrivial>` has no Carbon sum type [CppSumTypeNotMapped]
  // CHECK:STDERR:   match (Cpp.MakeNonTrivial()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_todo_non_trivial.carbon:[[@LINE+4]]:9: note: `std::optional<NonTrivial>` is not trivially copyable and trivially destructible [CppSumTypeNotTriviallyCopyable]
  // CHECK:STDERR:   match (Cpp.MakeNonTrivial()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  match (Cpp.MakeNonTrivial()) {
    default => {}
  }
}

// --- fail_conversion_mismatch.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A C++ sum type converts only to its own Carbon sum type.
fn G() {
  // CHECK:STDERR: fail_conversion_mismatch.carbon:[[@LINE+8]]:51: error: C++ type `std::optional<int>` converts only to its own Carbon sum type `Core.CppCompat.StdOptional(i32)` or to the `Core.Optional` of its payload, not to `Core.CppCompat.StdOptional(i64)` [CppSumTypeMismatch]
  // CHECK:STDERR:   let unused s: Core.CppCompat.StdOptional(i64) = Cpp.MakeOptional(1);
  // CHECK:STDERR:                                                   ^~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  // CHECK:STDERR: {{.*}}/prelude/types/cpp/sum.carbon:30:1: error: semantics TODO: `interop with non-identifier package name` [SemanticsTodo]
  // CHECK:STDERR: choice CppCompat.StdOptional(T: type) {
  // CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  let unused s: Core.CppCompat.StdOptional(i64) = Cpp.MakeOptional(1);
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
// CHECK:STDERR: fail_todo_export_sum_type.carbon:[[@LINE+4]]:1: error: semantics TODO: `failed to map Carbon return type to C++ type` [SemanticsTodo]
// CHECK:STDERR: fn MakeView(x: i32) -> Core.CppCompat.StdOptional(i32) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn MakeView(x: i32) -> Core.CppCompat.StdOptional(i32) {
  return Core.CppCompat.StdOptional(i32).Some(x);
}

inline Cpp '''
// CHECK:STDERR: fail_todo_export_sum_type.carbon:[[@LINE+4]]:28: error: no member named 'MakeView' in namespace 'Carbon' [CppInteropParseError]
// CHECK:STDERR:    21 | inline int Use() { Carbon::MakeView(3); return 1; }
// CHECK:STDERR:       |                            ^~~~~~~~
// CHECK:STDERR:
inline int Use() { Carbon::MakeView(3); return 1; }
''';

// --- fail_reverse_other_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A Carbon sum value converts only to the C++ class whose sum type it is, not
// to another specialization through C++'s converting constructor, which would
// narrow or widen the payload silently (§1.5).
fn L() -> i64 {
  // CHECK:STDERR: fail_reverse_other_specialization.carbon:[[@LINE+8]]:23: error: `Core.CppCompat.StdOptional(i32)` converts to C++ only as the `std::optional` or `std::variant` whose Carbon sum type it is, not to `std::optional<long>` [CppSumTypeReverseMismatch]
  // CHECK:STDERR:   return Cpp.TakeLong(Core.CppCompat.StdOptional(i32).Some(3));
  // CHECK:STDERR:                       ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_reverse_other_specialization.carbon:[[@LINE-9]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./sum.h:80:42: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: inline auto TakeLong(std::optional<long> o) -> long {
  // CHECK:STDERR:                                          ^
  // CHECK:STDERR:
  return Cpp.TakeLong(Core.CppCompat.StdOptional(i32).Some(3));
}

// --- fail_reverse_converting_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Nor to a class with a converting constructor from that class.
fn W() -> i32 {
  // CHECK:STDERR: fail_reverse_converting_class.carbon:[[@LINE+8]]:26: error: `Core.CppCompat.StdOptional(i32)` converts to C++ only as the `std::optional` or `std::variant` whose Carbon sum type it is, not to `Wrapper` [CppSumTypeReverseMismatch]
  // CHECK:STDERR:   return Cpp.TakeWrapper(Core.CppCompat.StdOptional(i32).Some(3));
  // CHECK:STDERR:                          ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_reverse_converting_class.carbon:[[@LINE-7]]:10: in file included here [InCppInclude]
  // CHECK:STDERR: ./sum.h:89:33: note: initializing function parameter [InCallToFunctionParam]
  // CHECK:STDERR: inline auto TakeWrapper(Wrapper w) -> int { return w.n; }
  // CHECK:STDERR:                                 ^
  // CHECK:STDERR:
  return Cpp.TakeWrapper(Core.CppCompat.StdOptional(i32).Some(3));
}

// --- fail_todo_tuple_scrutinee.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A C++ sum class inside a tuple scrutinee is not converted (§1.11).
fn T() {
  let t: (Cpp.std.optional(i32), i32) = (Cpp.MakeOptional(1), 2);
  // CHECK:STDERR: fail_todo_tuple_scrutinee.carbon:[[@LINE+4]]:9: error: semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]
  // CHECK:STDERR:   match (t) {
  // CHECK:STDERR:         ^~~
  // CHECK:STDERR:
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
      // CHECK:STDERR: fail_todo_if_arm.carbon:[[@LINE+4]]:12: error: semantics TODO: `destroying temporaries of a conditionally evaluated operand whose value is not passed by copy` [SemanticsTodo]
      // CHECK:STDERR:       if c then Cpp.MakeOptional(1) else Cpp.MakeOptional(0);
      // CHECK:STDERR:            ^~~~~~~~~~~~~~~~~~~~~~~~
      // CHECK:STDERR:
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
  // CHECK:STDERR: fail_todo_template_conversion.carbon:[[@LINE+7]]:51: error: unable to monomorphize specific `Pass(Cpp.std.__1.optional)` [ResolvingSpecificHere]
  // CHECK:STDERR:   let unused s: Core.CppCompat.StdOptional(i32) = Pass(Cpp.MakeOptional(1));
  // CHECK:STDERR:                                                   ^~~~
  // CHECK:STDERR: fail_todo_template_conversion.carbon:[[@LINE-7]]:3: note: semantics TODO: `conversion of a C++ `std::optional` or `std::variant` outside a function body (at file scope, or deferred to a template's instantiation)` [SemanticsTodo]
  // CHECK:STDERR:   return x;
  // CHECK:STDERR:   ^~~~~~~~~
  // CHECK:STDERR:
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

// CHECK:STDERR: fail_todo_rvalue_ref_param.carbon:[[@LINE+13]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./sink.h:4:45: error: semantics TODO: `conversion of a C++ `std::optional` or `std::variant` with no source expression` [SemanticsTodo]
// CHECK:STDERR: inline auto TakeRvalue(std::optional<int>&& o) -> int {
// CHECK:STDERR:                                             ^
// CHECK:STDERR: fail_todo_rvalue_ref_param.carbon:[[@LINE+9]]:10: in file included here [InCppInclude]
// CHECK:STDERR: ./sink.h:4:45: note: initializing function parameter [InCallToFunctionParam]
// CHECK:STDERR: inline auto TakeRvalue(std::optional<int>&& o) -> int {
// CHECK:STDERR:                                             ^
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/optional.carbon:30:1: error: semantics TODO: `interop with non-identifier package name` [SemanticsTodo]
// CHECK:STDERR: class Optional(T: OptionalStorage) {
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import Cpp library "sink.h";

// A sum value or `Core.Optional` passed to a C++ `T&&` parameter, alone or the
// member C++ selects from a `const T&` and `T&&` pair, initializes the
// parameter at its C++ declaration, which gives the conversion no parse node
// for its branches (§1.5, §1.11).
fn R() -> i32 {
  return Cpp.TakeRvalue(Core.CppCompat.StdOptional(i32).Some(5));
}

fn P() -> i32 {
  // CHECK:STDERR: fail_todo_rvalue_ref_param.carbon:[[@LINE+4]]:18: error: call argument of type `Core.Optional(i32 as Core.OptionalStorage)` is not supported [CppCallArgTypeNotSupported]
  // CHECK:STDERR:   return Cpp.Put(Core.Optional(i32).Some(6));
  // CHECK:STDERR:                  ^~~~~~~~~~~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
  return Cpp.Put(Core.Optional(i32).Some(6));
}

// A value, such as a parameter, selects the `const&` member, which converts.
fn V(o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return Cpp.Put(o);
}
