// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/optional.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/optional.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1, F-020): a `std::optional<T>`
// specialization stays an imported C++ class; where a Carbon sum type is
// expected -- a `match`, `if`-`let` or `let`-`else` scrutinee, or a
// conversion to `Core.CppCompat.StdOptional(T)` -- it converts by value
// through `has_value()` and `value()`, and a `StdOptional(T)` converts back
// through the class's default constructor and `emplace`.

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

// --- match.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Predicted: the scrutinee converts once, before the arms: a call of
// `has_value`'s thunk, a branch, `value`'s thunk call and
// `StdOptional(i32).Some` in one block, the `None` constant's copy in the
// other, each assigned to one `temporary_storage` of the sum type; the arms
// then test its `.discriminant` as for any `choice`. Exhaustive without
// `default` (SF-7).
//@dump-sem-ir-begin
fn F(n: i32) -> i32 {
  match (Cpp.MakeOptional(n)) {
    case .Some(v: i32) => {
      return v;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}
//@dump-sem-ir-end

// --- if_let.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// `if`-`let` shares the scrutinee gate (refutable_binding.cpp).
//@dump-sem-ir-begin
fn G(n: i32) -> i32 {
  if (let .Some(v: i32) = Cpp.MakeOptional(n)) {
    return v;
  }
  return 0;
}
//@dump-sem-ir-end

// --- convert.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Both directions as implicit conversions: the C++ class to the sum type, and
// the sum type -- computed or the `None` constant -- to a by-value and a
// `const&` parameter. Overload resolution sees a `StdOptional(i32)` argument
// as the C++ class.
//@dump-sem-ir-begin
fn H(n: i32) -> i32 {
  let s: Core.CppCompat.StdOptional(i32) = Cpp.MakeOptional(n);
  let none: Core.CppCompat.StdOptional(i32) =
      Core.CppCompat.StdOptional(i32).None;
  return Cpp.Take(s) + Cpp.TakeRef(s) + Cpp.Take(none);
}
//@dump-sem-ir-end

// --- pointer_payload.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A nullable C++ `int*` payload is `Core.Optional(i32*)`, which D-SV-8
// admits as a choice payload, so an engaged null pointer is
// `.Some(<None pointer>)`, distinct from `.None`.
//@dump-sem-ir-begin
fn P(n: i32) -> bool {
  match (Cpp.MakePointer(n)) {
    case .Some(p: Core.Optional(i32*)) => {
      return p.HasValue();
    }
    case .None => {
      return false;
    }
  }
  return false;
}
//@dump-sem-ir-end

// --- bridge.carbon

library "[[@TEST_NAME]]";

// `StdOptional(T)` and `Core.Optional(T)` convert to each other implicitly,
// through `Optional`'s public API.
fn B(s: Core.CppCompat.StdOptional(i32)) -> Core.CppCompat.StdOptional(i32) {
  let o: Core.Optional(i32) = s;
  return o;
}

// --- one_step_core_optional.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::optional<T>` converts to `Core.Optional(T')` in one implicit step,
// through its sum type and the bridge; a `Core.Optional(T')` whose payload is
// not a pointer is offered to C++ as `std::optional<T>` and converted back the
// same way (fork/sumtype-interop/plan.md §1.7).
//@dump-sem-ir-begin
fn O(n: i32) -> i32 {
  let o: Core.Optional(i32) = Cpp.MakeOptional(n);
  return Cpp.Take(o) + Cpp.TakeRef(o);
}
//@dump-sem-ir-end

// --- monostate_payload.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// `std::optional<std::monostate>`'s `Some` carries `()`, in both directions.
fn M(n: i32) -> bool {
  match (Cpp.MakeMono(n)) {
    case .Some(_: ()) => {
      return Cpp.TakeMono(Core.CppCompat.StdOptional(()).Some(()));
    }
    case .None => {
      return false;
    }
  }
  return false;
}

// --- fail_todo_struct_payload.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// SF-6: a class payload has no Carbon sum type in 0.1 (plan §1.3); the class
// import is unaffected, only the `match` is diagnosed.
fn S() -> i32 {
  match (Cpp.MakePoint()) {
    case .None => {
      return 0;
    }
    default => {
      return 1;
    }
  }
  return 2;
}

// --- fail_dead_default.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The sum type's closed alternative set makes a trailing `default` dead
// (`MatchDefaultNeverMatches`), as for any `choice`.
fn D(n: i32) -> i32 {
  match (Cpp.MakeOptional(n)) {
    case .Some(v: i32) => {
      return v;
    }
    case .None => {
      return -1;
    }
    default => {
      return -2;
    }
  }
  return -3;
}

// --- fail_unknown_alternative.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The alternatives are the sum type's, `Some` and `None`.
fn U(n: i32) -> i32 {
  match (Cpp.MakeOptional(n)) {
    case .Ok(v: i32) => {
      return v;
    }
    default => {
      return -1;
    }
  }
  return -2;
}

// --- fail_todo_outside_function.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The conversion branches, and control flow outside a function is not
// supported in 0.1 (plan §1.4).
let global: Core.CppCompat.StdOptional(i32) = Cpp.MakeOptional(1);

// --- fail_todo_ref_binding.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The scrutinee is the by-value conversion of the C++ object, not the object,
// so a `ref` payload binding has no durable reference to bind (§1.6).
fn R() {
  var o: Cpp.std.optional(i32) = Cpp.MakeOptional(1);
  match (o) {
    case .Some(ref n: i32) => {
      n = 2;
    }
    case .None => {}
  }
}
