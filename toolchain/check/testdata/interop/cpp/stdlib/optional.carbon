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
  // CHECK:STDERR: fail_todo_struct_payload.carbon:[[@LINE+7]]:9: error: C++ type `std::optional<Point>` has no Carbon sum type [CppSumTypeNotMapped]
  // CHECK:STDERR:   match (Cpp.MakePoint()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR: fail_todo_struct_payload.carbon:[[@LINE+4]]:9: note: alternative 0 has type `Point`, which is not a choice payload type in 0.1 [CppSumTypeAlternativeNotAdmitted]
  // CHECK:STDERR:   match (Cpp.MakePoint()) {
  // CHECK:STDERR:         ^~~~~~~~~~~~~~~~~
  // CHECK:STDERR:
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
    // CHECK:STDERR: fail_dead_default.carbon:[[@LINE+7]]:5: error: `default` arm never matches; every value of the scrutinee is matched by prior arms [MatchDefaultNeverMatches]
    // CHECK:STDERR:     default => {
    // CHECK:STDERR:     ^~~~~~~
    // CHECK:STDERR: fail_dead_default.carbon:[[@LINE-10]]:9: note: all alternatives of `Core.CppCompat.StdOptional(i32)` are matched by prior arms [MatchDefaultNeverMatchesFullCoverage]
    // CHECK:STDERR:   match (Cpp.MakeOptional(n)) {
    // CHECK:STDERR:         ^~~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR:
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
    // CHECK:STDERR: fail_unknown_alternative.carbon:[[@LINE+4]]:10: error: member name `Ok` not found in `Core.CppCompat.StdOptional(i32)` [MemberNameNotFoundInSpecificScope]
    // CHECK:STDERR:     case .Ok(v: i32) => {
    // CHECK:STDERR:          ^~~~~~~~~~~
    // CHECK:STDERR:
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
// CHECK:STDERR: fail_todo_outside_function.carbon:[[@LINE+4]]:47: error: semantics TODO: `conversion of a C++ `std::optional` or `std::variant` outside a function body (at file scope, or deferred to a template's instantiation)` [SemanticsTodo]
// CHECK:STDERR: let global: Core.CppCompat.StdOptional(i32) = Cpp.MakeOptional(1);
// CHECK:STDERR:                                               ^~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
let global: Core.CppCompat.StdOptional(i32) = Cpp.MakeOptional(1);

// --- fail_todo_ref_binding.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The scrutinee is the by-value conversion of the C++ object, not the object,
// so a `ref` payload binding has no durable reference to bind (§1.6).
fn R() {
  var o: Cpp.std.optional(i32) = Cpp.MakeOptional(1);
  match (o) {
    // CHECK:STDERR: fail_todo_ref_binding.carbon:[[@LINE+4]]:5: error: cannot bind durable reference to non-reference value of type `i32` [ConversionFailureNonRefToRef]
    // CHECK:STDERR:     case .Some(ref n: i32) => {
    // CHECK:STDERR:     ^~~~~~~~~~~~~~~~~~~~~~~~~
    // CHECK:STDERR:
    case .Some(ref n: i32) => {
      n = 2;
    }
    case .None => {}
  }
}

// CHECK:STDOUT: --- match.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %MakeOptional.cpp_overload_set.type: type = cpp_overload_set_type @MakeOptional.cpp_overload_set [concrete]
// CHECK:STDOUT:   %MakeOptional.cpp_overload_set.value: %MakeOptional.cpp_overload_set.type = cpp_overload_set_value @MakeOptional.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional: type = class_type @optional [concrete]
// CHECK:STDOUT:   %pattern_type.88c: type = pattern_type %optional [concrete]
// CHECK:STDOUT:   %ptr.e48: type = ptr_type %optional [concrete]
// CHECK:STDOUT:   %MakeOptional__carbon_thunk.type: type = fn_type @MakeOptional__carbon_thunk [concrete]
// CHECK:STDOUT:   %MakeOptional__carbon_thunk: %MakeOptional__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %StdOptional.type: type = generic_class_type @StdOptional [concrete]
// CHECK:STDOUT:   %StdOptional.generic: %StdOptional.type = struct_value () [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %tuple.type.026: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %.a2d: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %StdOptional.05d: type = class_type @StdOptional, @StdOptional(%T.67d) [symbolic]
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %StdOptional.val.551: %StdOptional.05d = struct_value (%int_1.233, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %StdOptional.Some.type.a04: type = fn_type @StdOptional.Some, @StdOptional(%T.67d) [symbolic]
// CHECK:STDOUT:   %StdOptional.Some.391: %StdOptional.Some.type.a04 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %StdOptional.4c3: type = class_type @StdOptional, @StdOptional(%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %StdOptional.Some.type.389: type = fn_type @StdOptional.Some, @StdOptional(%i32) [concrete]
// CHECK:STDOUT:   %StdOptional.Some.6b6: %StdOptional.Some.type.389 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.060: %.e8e = uninitialized_value [concrete]
// CHECK:STDOUT:   %StdOptional.val.f8e: %StdOptional.4c3 = struct_value (%int_1.233, %uninit.060) [concrete]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.type: type = cpp_overload_set_type @optional.has_value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.value: %optional.has_value.cpp_overload_set.type = cpp_overload_set_value @optional.has_value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %ptr.bb2: type = ptr_type bool [concrete]
// CHECK:STDOUT:   %has_value__carbon_thunk.type: type = fn_type @has_value__carbon_thunk [concrete]
// CHECK:STDOUT:   %has_value__carbon_thunk: %has_value__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %optional.value.cpp_overload_set.type: type = cpp_overload_set_type @optional.value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.value.cpp_overload_set.value: %optional.value.cpp_overload_set.type = cpp_overload_set_value @optional.value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %value__carbon_thunk.type: type = fn_type @value__carbon_thunk [concrete]
// CHECK:STDOUT:   %value__carbon_thunk: %value__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.7c0: type = pattern_type %StdOptional.4c3 [concrete]
// CHECK:STDOUT:   %StdOptional.Some.specific_fn: <specific function> = specific_function %StdOptional.Some.6b6, @StdOptional.Some(%i32) [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f5: type = fn_type @Copy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.416: %Copy.WithSelf.Op.type.7f5 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.bab: <witness> = custom_witness (%Copy.WithSelf.Op.416), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.209: %Copy.type = facet_value %StdOptional.4c3, (%custom_witness.bab) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.159: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.209) [concrete]
// CHECK:STDOUT:   %.252: type = fn_type_with_self_type %Copy.WithSelf.Op.type.159, %Copy.facet.209 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.bound: <bound method> = bound_method %StdOptional.val.f8e, %Copy.WithSelf.Op.416 [concrete]
// CHECK:STDOUT:   %self.param_patt.40d: %pattern_type.831 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.560: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt.40d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc14_29 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_29 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.9d2: %pattern_type.88c = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d48: %pattern_type.88c = wrapper_binding_pattern self, %self.param_patt.9d2 [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor.type: type = fn_type @optional.cpp_destructor [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor: %optional.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc14_28 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_28 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.13b: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.e21: <bound method> = bound_method %int_2, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-2.962: Core.IntLiteral = int_value -2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.33f: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-2.c83: %i32 = int_value -2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .MakeOptional = %MakeOptional.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MakeOptional.cpp_overload_set.value: %MakeOptional.cpp_overload_set.type = cpp_overload_set_value @MakeOptional.cpp_overload_set [concrete = constants.%MakeOptional.cpp_overload_set.value]
// CHECK:STDOUT:   %MakeOptional__carbon_thunk.decl: %MakeOptional__carbon_thunk.type = fn_decl @MakeOptional__carbon_thunk [concrete = constants.%MakeOptional__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StdOptional: %StdOptional.type = import_ref Core//prelude/types/cpp/sum, StdOptional, loaded [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %Core.import_ref.b1b: @StdOptional.%StdOptional.Some.type (%StdOptional.Some.type.a04) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdOptional.%StdOptional.Some (constants.%StdOptional.Some.391)]
// CHECK:STDOUT:   %Core.import_ref.e46: @StdOptional.%StdOptional (%StdOptional.05d) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdOptional.%StdOptional.val (constants.%StdOptional.val.551)]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.value: %optional.has_value.cpp_overload_set.type = cpp_overload_set_value @optional.has_value.cpp_overload_set [concrete = constants.%optional.has_value.cpp_overload_set.value]
// CHECK:STDOUT:   %has_value__carbon_thunk.decl: %has_value__carbon_thunk.type = fn_decl @has_value__carbon_thunk [concrete = constants.%has_value__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %optional.value.cpp_overload_set.value: %optional.value.cpp_overload_set.type = cpp_overload_set_value @optional.value.cpp_overload_set [concrete = constants.%optional.value.cpp_overload_set.value]
// CHECK:STDOUT:   %value__carbon_thunk.decl: %value__carbon_thunk.type = fn_decl @value__carbon_thunk [concrete = constants.%value__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor.decl: %optional.cpp_destructor.type = fn_decl @optional.cpp_destructor [concrete = constants.%optional.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc14_29 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc14_28 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.88c = ref_param_pattern [concrete = constants.%self.param_patt.9d2]
// CHECK:STDOUT:     %self.patt: %pattern_type.88c = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d48]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %optional = ref_param call_param0
// CHECK:STDOUT:     %self: ref %optional = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc13_17 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc13_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc13: Core.Form = init_form %i32.loc13_17 [concrete = constants.%.795f]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc13_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%n.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %MakeOptional.ref: %MakeOptional.cpp_overload_set.type = name_ref MakeOptional, imports.%MakeOptional.cpp_overload_set.value [concrete = constants.%MakeOptional.cpp_overload_set.value]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc14_28.1: ref %optional = temporary_storage
// CHECK:STDOUT:   %addr.loc14_28: %ptr.e48 = addr_of %.loc14_28.1
// CHECK:STDOUT:   %MakeOptional__carbon_thunk.call: init %empty_tuple.type = call imports.%MakeOptional__carbon_thunk.decl(%n.ref, %addr.loc14_28)
// CHECK:STDOUT:   %.loc14_28.2: init %optional to %.loc14_28.1 = mark_in_place_init %MakeOptional__carbon_thunk.call
// CHECK:STDOUT:   %.loc14_28.3: ref %optional = temporary %.loc14_28.1, %.loc14_28.2
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdOptional.ref: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %StdOptional: type = class_type @StdOptional, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.4c3]
// CHECK:STDOUT:   %.loc14_28.4: %optional = acquire_value %.loc14_28.3
// CHECK:STDOUT:   %.loc14_29.1: ref %StdOptional.4c3 = temporary_storage
// CHECK:STDOUT:   %has_value.ref: %optional.has_value.cpp_overload_set.type = name_ref has_value, imports.%optional.has_value.cpp_overload_set.value [concrete = constants.%optional.has_value.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc14_29.1: <bound method> = bound_method %.loc14_28.4, %has_value.ref
// CHECK:STDOUT:   %.loc14_29.2: ref bool = temporary_storage
// CHECK:STDOUT:   %addr.loc14_29: %ptr.bb2 = addr_of %.loc14_29.2
// CHECK:STDOUT:   %has_value__carbon_thunk.call: init %empty_tuple.type = call imports.%has_value__carbon_thunk.decl(%.loc14_28.4, %addr.loc14_29)
// CHECK:STDOUT:   %.loc14_29.3: init bool to %.loc14_29.2 = mark_in_place_init %has_value__carbon_thunk.call
// CHECK:STDOUT:   %.loc14_29.4: ref bool = temporary %.loc14_29.2, %.loc14_29.3
// CHECK:STDOUT:   %.loc14_29.5: bool = acquire_value %.loc14_29.4
// CHECK:STDOUT:   if %.loc14_29.5 br !.loc14_29.1 else br !.loc14_29.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_29.1:
// CHECK:STDOUT:   %value.ref: %optional.value.cpp_overload_set.type = name_ref value, imports.%optional.value.cpp_overload_set.value [concrete = constants.%optional.value.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc14_29.2: <bound method> = bound_method %.loc14_28.4, %value.ref
// CHECK:STDOUT:   %value__carbon_thunk.call: ref %const.6a8 = call imports.%value__carbon_thunk.decl(%.loc14_28.4)
// CHECK:STDOUT:   %.loc14_29.6: %StdOptional.Some.type.389 = specific_constant imports.%Core.import_ref.b1b, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.Some.6b6]
// CHECK:STDOUT:   %Some.ref: %StdOptional.Some.type.389 = name_ref Some, %.loc14_29.6 [concrete = constants.%StdOptional.Some.6b6]
// CHECK:STDOUT:   %StdOptional.Some.specific_fn: <specific function> = specific_function %Some.ref, @StdOptional.Some(constants.%i32) [concrete = constants.%StdOptional.Some.specific_fn]
// CHECK:STDOUT:   %.loc14_29.7: ref %StdOptional.4c3 = splice_block %.loc14_29.1 {}
// CHECK:STDOUT:   %.loc14_29.8: ref %i32 = as_compatible %value__carbon_thunk.call
// CHECK:STDOUT:   %.loc14_29.9: ref %i32 = converted %value__carbon_thunk.call, %.loc14_29.8
// CHECK:STDOUT:   %.loc14_29.10: %i32 = acquire_value %.loc14_29.9
// CHECK:STDOUT:   %StdOptional.Some.call: init %StdOptional.4c3 to %.loc14_29.7 = call %StdOptional.Some.specific_fn(%.loc14_29.10)
// CHECK:STDOUT:   assign %.loc14_29.1, %StdOptional.Some.call
// CHECK:STDOUT:   br !.loc14_29.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_29.2:
// CHECK:STDOUT:   %.loc14_29.11: %StdOptional.4c3 = specific_constant imports.%Core.import_ref.e46, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   %None.ref.loc14: %StdOptional.4c3 = name_ref None, %.loc14_29.11 [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc14: %.252 = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc14_29.3: <bound method> = bound_method %None.ref.loc14, %impl.elem0.loc14 [concrete = constants.%Copy.WithSelf.Op.bound]
// CHECK:STDOUT:   %.loc14_29.12: ref %StdOptional.4c3 = splice_block %.loc14_29.1 {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call: init %StdOptional.4c3 to %.loc14_29.12 = call %bound_method.loc14_29.3(%None.ref.loc14) [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   assign %.loc14_29.1, %Copy.WithSelf.Op.call
// CHECK:STDOUT:   br !.loc14_29.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc14_29.3:
// CHECK:STDOUT:   %.loc14_29.13: %StdOptional.4c3 = acquire_value %.loc14_29.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_29: <bound method> = bound_method %.loc14_29.4, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_29: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_29(%.loc14_29.4)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_28: <bound method> = bound_method %.loc14_28.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_28: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_28(%.loc14_28.3)
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc15_17: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_24.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_24.1: <bound method> = bound_method %int_0, %impl.elem0.loc15_24.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc15_24.1: <specific function> = specific_function %impl.elem0.loc15_24.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc15_24.2: <bound method> = bound_method %int_0, %specific_fn.loc15_24.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %u1 = call %bound_method.loc15_24.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_24.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_24.2: %u1 = converted %int_0, %.loc15_24.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_24.3: ref %u1 = class_element_access %.loc14_29.13, element0
// CHECK:STDOUT:   %impl.elem0.loc15_24.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_24.3: <bound method> = bound_method %.loc15_24.2, %impl.elem0.loc15_24.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc15_24.2: <specific function> = specific_function %impl.elem0.loc15_24.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_24.4: <bound method> = bound_method %.loc15_24.2, %specific_fn.loc15_24.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc15_24.4: %u1 = acquire_value %.loc15_24.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_24.4(%.loc15_24.2, %.loc15_24.4)
// CHECK:STDOUT:   %.loc15_24.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_24.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_24.5
// CHECK:STDOUT:   if %.loc15_24.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %.loc15_24.7: ref %.e8e = class_element_access %.loc14_29.13, element1
// CHECK:STDOUT:   %.loc15_24.8: ref %tuple.type.a8a = class_element_access %.loc15_24.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc15_24.8, element0
// CHECK:STDOUT:   %.loc15_24.9: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc15_24.9
// CHECK:STDOUT:   %v.ref: %i32 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc16: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc16_14.1: <bound method> = bound_method %v.ref, %impl.elem0.loc16
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc16_14.2: <bound method> = bound_method %v.ref, %specific_fn.loc16
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc16_14.2(%v.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.7c0 = expr_pattern %None.ref.loc18 in [concrete] {
// CHECK:STDOUT:       %.loc18_10.2: %StdOptional.4c3 = specific_constant imports.%Core.import_ref.e46, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:       %None.ref.loc18: %StdOptional.4c3 = name_ref None, %.loc18_10.2 [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc18_10.1: %StdOptional.4c3 = splice_block %None.ref.loc18 [concrete = constants.%StdOptional.val.f8e] {
// CHECK:STDOUT:     %.loc18_10.2: %StdOptional.4c3 = specific_constant imports.%Core.import_ref.e46, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:     %None.ref.loc18: %StdOptional.4c3 = name_ref None, %.loc18_10.2 [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc18: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc18_16.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc18_16.1: <bound method> = bound_method %int_1.loc18, %impl.elem0.loc18_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc18_16.1: <specific function> = specific_function %impl.elem0.loc18_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc18_16.2: <bound method> = bound_method %int_1.loc18, %specific_fn.loc18_16.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18: init %u1 = call %bound_method.loc18_16.2(%int_1.loc18) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_16.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_16.2: %u1 = converted %int_1.loc18, %.loc18_16.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc18_16.3: ref %u1 = class_element_access %.loc14_29.13, element0
// CHECK:STDOUT:   %impl.elem0.loc18_16.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc18_16.3: <bound method> = bound_method %.loc18_16.2, %impl.elem0.loc18_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc18_16.2: <specific function> = specific_function %impl.elem0.loc18_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc18_16.4: <bound method> = bound_method %.loc18_16.2, %specific_fn.loc18_16.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc18_16.4: %u1 = acquire_value %.loc18_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc18: init bool = call %bound_method.loc18_16.4(%.loc18_16.2, %.loc18_16.4)
// CHECK:STDOUT:   %.loc18_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc18
// CHECK:STDOUT:   %.loc18_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc18, %.loc18_16.5
// CHECK:STDOUT:   if %.loc18_16.6 br !match.case.then.loc18 else br !match.case.else.loc18
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc18:
// CHECK:STDOUT:   %int_1.loc19: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc19: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc19_14: <bound method> = bound_method %int_1.loc19, %impl.elem1.loc19 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc19: init Core.IntLiteral = call %bound_method.loc19_14(%int_1.loc19) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc19: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_16.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_16.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %specific_fn.loc19 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc19_14.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc19 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc19_14.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %.loc19_14.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_16.2(%.loc19_14.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc19_16: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc19, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc19_16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc18:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1.loc22: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc22_10: <bound method> = bound_method %int_2, %impl.elem1.loc22 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc22: init Core.IntLiteral = call %bound_method.loc22_10(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc22: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc22_12.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc22, %impl.elem0.loc22 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc22: <specific function> = specific_function %impl.elem0.loc22, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc22_12.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc22, %specific_fn.loc22 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc22_10.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc22 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc22_10.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc22, %.loc22_10.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22: init %i32 = call %bound_method.loc22_12.2(%.loc22_10.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc22_12: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc22, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc22 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   return %.loc22_12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_29(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_29(%self.param: ref bool) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_28(%self.param: ref %optional) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_28(%self.param: ref %optional) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %optional.cpp_destructor.call: init %empty_tuple.type = call imports.%optional.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- if_let.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type: type = fn_type @G [concrete]
// CHECK:STDOUT:   %G: %G.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.13b: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete]
// CHECK:STDOUT:   %MakeOptional.cpp_overload_set.type: type = cpp_overload_set_type @MakeOptional.cpp_overload_set [concrete]
// CHECK:STDOUT:   %MakeOptional.cpp_overload_set.value: %MakeOptional.cpp_overload_set.type = cpp_overload_set_value @MakeOptional.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional: type = class_type @optional [concrete]
// CHECK:STDOUT:   %pattern_type.88c: type = pattern_type %optional [concrete]
// CHECK:STDOUT:   %ptr.e48: type = ptr_type %optional [concrete]
// CHECK:STDOUT:   %MakeOptional__carbon_thunk.type: type = fn_type @MakeOptional__carbon_thunk [concrete]
// CHECK:STDOUT:   %MakeOptional__carbon_thunk: %MakeOptional__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %StdOptional.type: type = generic_class_type @StdOptional [concrete]
// CHECK:STDOUT:   %StdOptional.generic: %StdOptional.type = struct_value () [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %tuple.type.026: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %.a2d: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %StdOptional.05d: type = class_type @StdOptional, @StdOptional(%T.67d) [symbolic]
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %StdOptional.val.551: %StdOptional.05d = struct_value (%int_1.233, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %StdOptional.Some.type.a04: type = fn_type @StdOptional.Some, @StdOptional(%T.67d) [symbolic]
// CHECK:STDOUT:   %StdOptional.Some.391: %StdOptional.Some.type.a04 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %StdOptional.4c3: type = class_type @StdOptional, @StdOptional(%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %StdOptional.Some.type.389: type = fn_type @StdOptional.Some, @StdOptional(%i32) [concrete]
// CHECK:STDOUT:   %StdOptional.Some.6b6: %StdOptional.Some.type.389 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.060: %.e8e = uninitialized_value [concrete]
// CHECK:STDOUT:   %StdOptional.val.f8e: %StdOptional.4c3 = struct_value (%int_1.233, %uninit.060) [concrete]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.type: type = cpp_overload_set_type @optional.has_value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.value: %optional.has_value.cpp_overload_set.type = cpp_overload_set_value @optional.has_value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %ptr.bb2: type = ptr_type bool [concrete]
// CHECK:STDOUT:   %has_value__carbon_thunk.type: type = fn_type @has_value__carbon_thunk [concrete]
// CHECK:STDOUT:   %has_value__carbon_thunk: %has_value__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %optional.value.cpp_overload_set.type: type = cpp_overload_set_type @optional.value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.value.cpp_overload_set.value: %optional.value.cpp_overload_set.type = cpp_overload_set_value @optional.value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %value__carbon_thunk.type: type = fn_type @value__carbon_thunk [concrete]
// CHECK:STDOUT:   %value__carbon_thunk: %value__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %StdOptional.Some.specific_fn: <specific function> = specific_function %StdOptional.Some.6b6, @StdOptional.Some(%i32) [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f5: type = fn_type @Copy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.416: %Copy.WithSelf.Op.type.7f5 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.bab: <witness> = custom_witness (%Copy.WithSelf.Op.416), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.209: %Copy.type = facet_value %StdOptional.4c3, (%custom_witness.bab) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.159: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.209) [concrete]
// CHECK:STDOUT:   %.252: type = fn_type_with_self_type %Copy.WithSelf.Op.type.159, %Copy.facet.209 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.bound: <bound method> = bound_method %StdOptional.val.f8e, %Copy.WithSelf.Op.416 [concrete]
// CHECK:STDOUT:   %self.param_patt.40d: %pattern_type.831 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.560: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt.40d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc9 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc9_45.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9_45.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.9d2: %pattern_type.88c = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d48: %pattern_type.88c = wrapper_binding_pattern self, %self.param_patt.9d2 [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor.type: type = fn_type @optional.cpp_destructor [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor: %optional.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc9_45.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc9_45.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .MakeOptional = %MakeOptional.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %MakeOptional.cpp_overload_set.value: %MakeOptional.cpp_overload_set.type = cpp_overload_set_value @MakeOptional.cpp_overload_set [concrete = constants.%MakeOptional.cpp_overload_set.value]
// CHECK:STDOUT:   %MakeOptional__carbon_thunk.decl: %MakeOptional__carbon_thunk.type = fn_decl @MakeOptional__carbon_thunk [concrete = constants.%MakeOptional__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StdOptional: %StdOptional.type = import_ref Core//prelude/types/cpp/sum, StdOptional, loaded [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %Core.import_ref.b1b: @StdOptional.%StdOptional.Some.type (%StdOptional.Some.type.a04) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdOptional.%StdOptional.Some (constants.%StdOptional.Some.391)]
// CHECK:STDOUT:   %Core.import_ref.e46: @StdOptional.%StdOptional (%StdOptional.05d) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdOptional.%StdOptional.val (constants.%StdOptional.val.551)]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.value: %optional.has_value.cpp_overload_set.type = cpp_overload_set_value @optional.has_value.cpp_overload_set [concrete = constants.%optional.has_value.cpp_overload_set.value]
// CHECK:STDOUT:   %has_value__carbon_thunk.decl: %has_value__carbon_thunk.type = fn_decl @has_value__carbon_thunk [concrete = constants.%has_value__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %optional.value.cpp_overload_set.value: %optional.value.cpp_overload_set.type = cpp_overload_set_value @optional.value.cpp_overload_set [concrete = constants.%optional.value.cpp_overload_set.value]
// CHECK:STDOUT:   %value__carbon_thunk.decl: %value__carbon_thunk.type = fn_decl @value__carbon_thunk [concrete = constants.%value__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor.decl: %optional.cpp_destructor.type = fn_decl @optional.cpp_destructor [concrete = constants.%optional.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc9 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc9_45.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc9_45.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.88c = ref_param_pattern [concrete = constants.%self.param_patt.9d2]
// CHECK:STDOUT:     %self.patt: %pattern_type.88c = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d48]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %optional = ref_param call_param0
// CHECK:STDOUT:     %self: ref %optional = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl: %G.type = fn_decl @G [concrete = constants.%G] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_17 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8: Core.Form = init_form %i32.loc8_17 [concrete = constants.%.795f]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc8_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G(%n.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %MakeOptional.ref: %MakeOptional.cpp_overload_set.type = name_ref MakeOptional, imports.%MakeOptional.cpp_overload_set.value [concrete = constants.%MakeOptional.cpp_overload_set.value]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc9_45.1: ref %optional = temporary_storage
// CHECK:STDOUT:   %addr.loc9_45.1: %ptr.e48 = addr_of %.loc9_45.1
// CHECK:STDOUT:   %MakeOptional__carbon_thunk.call: init %empty_tuple.type = call imports.%MakeOptional__carbon_thunk.decl(%n.ref, %addr.loc9_45.1)
// CHECK:STDOUT:   %.loc9_45.2: init %optional to %.loc9_45.1 = mark_in_place_init %MakeOptional__carbon_thunk.call
// CHECK:STDOUT:   %.loc9_45.3: ref %optional = temporary %.loc9_45.1, %.loc9_45.2
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdOptional.ref: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %StdOptional: type = class_type @StdOptional, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.4c3]
// CHECK:STDOUT:   %.loc9_45.4: %optional = acquire_value %.loc9_45.3
// CHECK:STDOUT:   %.loc9_45.5: ref %StdOptional.4c3 = temporary_storage
// CHECK:STDOUT:   %has_value.ref: %optional.has_value.cpp_overload_set.type = name_ref has_value, imports.%optional.has_value.cpp_overload_set.value [concrete = constants.%optional.has_value.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc9_45.1: <bound method> = bound_method %.loc9_45.4, %has_value.ref
// CHECK:STDOUT:   %.loc9_45.6: ref bool = temporary_storage
// CHECK:STDOUT:   %addr.loc9_45.2: %ptr.bb2 = addr_of %.loc9_45.6
// CHECK:STDOUT:   %has_value__carbon_thunk.call: init %empty_tuple.type = call imports.%has_value__carbon_thunk.decl(%.loc9_45.4, %addr.loc9_45.2)
// CHECK:STDOUT:   %.loc9_45.7: init bool to %.loc9_45.6 = mark_in_place_init %has_value__carbon_thunk.call
// CHECK:STDOUT:   %.loc9_45.8: ref bool = temporary %.loc9_45.6, %.loc9_45.7
// CHECK:STDOUT:   %.loc9_45.9: bool = acquire_value %.loc9_45.8
// CHECK:STDOUT:   if %.loc9_45.9 br !.loc9_45.1 else br !.loc9_45.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_45.1:
// CHECK:STDOUT:   %value.ref: %optional.value.cpp_overload_set.type = name_ref value, imports.%optional.value.cpp_overload_set.value [concrete = constants.%optional.value.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc9_45.2: <bound method> = bound_method %.loc9_45.4, %value.ref
// CHECK:STDOUT:   %value__carbon_thunk.call: ref %const.6a8 = call imports.%value__carbon_thunk.decl(%.loc9_45.4)
// CHECK:STDOUT:   %.loc9_45.10: %StdOptional.Some.type.389 = specific_constant imports.%Core.import_ref.b1b, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.Some.6b6]
// CHECK:STDOUT:   %Some.ref: %StdOptional.Some.type.389 = name_ref Some, %.loc9_45.10 [concrete = constants.%StdOptional.Some.6b6]
// CHECK:STDOUT:   %StdOptional.Some.specific_fn: <specific function> = specific_function %Some.ref, @StdOptional.Some(constants.%i32) [concrete = constants.%StdOptional.Some.specific_fn]
// CHECK:STDOUT:   %.loc9_45.11: ref %StdOptional.4c3 = splice_block %.loc9_45.5 {}
// CHECK:STDOUT:   %.loc9_45.12: ref %i32 = as_compatible %value__carbon_thunk.call
// CHECK:STDOUT:   %.loc9_45.13: ref %i32 = converted %value__carbon_thunk.call, %.loc9_45.12
// CHECK:STDOUT:   %.loc9_45.14: %i32 = acquire_value %.loc9_45.13
// CHECK:STDOUT:   %StdOptional.Some.call: init %StdOptional.4c3 to %.loc9_45.11 = call %StdOptional.Some.specific_fn(%.loc9_45.14)
// CHECK:STDOUT:   assign %.loc9_45.5, %StdOptional.Some.call
// CHECK:STDOUT:   br !.loc9_45.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_45.2:
// CHECK:STDOUT:   %.loc9_45.15: %StdOptional.4c3 = specific_constant imports.%Core.import_ref.e46, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   %None.ref: %StdOptional.4c3 = name_ref None, %.loc9_45.15 [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc9_45: %.252 = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc9_45.3: <bound method> = bound_method %None.ref, %impl.elem0.loc9_45 [concrete = constants.%Copy.WithSelf.Op.bound]
// CHECK:STDOUT:   %.loc9_45.16: ref %StdOptional.4c3 = splice_block %.loc9_45.5 {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call: init %StdOptional.4c3 to %.loc9_45.16 = call %bound_method.loc9_45.3(%None.ref) [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   assign %.loc9_45.5, %Copy.WithSelf.Op.call
// CHECK:STDOUT:   br !.loc9_45.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc9_45.3:
// CHECK:STDOUT:   %.loc9_45.17: %StdOptional.4c3 = acquire_value %.loc9_45.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_45.1: <bound method> = bound_method %.loc9_45.8, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_45.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_45.1(%.loc9_45.8)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc9_45.2: <bound method> = bound_method %.loc9_45.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc9_45.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc9_45.2(%.loc9_45.3)
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = value_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc9_18: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.13b]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc9: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9_46.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc9_46.1: <bound method> = bound_method %int_0.loc9, %impl.elem0.loc9_46.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc9_46.1: <specific function> = specific_function %impl.elem0.loc9_46.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc9_46.2: <bound method> = bound_method %int_0.loc9, %specific_fn.loc9_46.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9: init %u1 = call %bound_method.loc9_46.2(%int_0.loc9) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc9_46.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc9_46.2: %u1 = converted %int_0.loc9, %.loc9_46.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc9_46.3: ref %u1 = class_element_access %.loc9_45.17, element0
// CHECK:STDOUT:   %impl.elem0.loc9_46.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc9_46.3: <bound method> = bound_method %.loc9_46.2, %impl.elem0.loc9_46.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc9_46.2: <specific function> = specific_function %impl.elem0.loc9_46.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc9_46.4: <bound method> = bound_method %.loc9_46.2, %specific_fn.loc9_46.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc9_46.4: %u1 = acquire_value %.loc9_46.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc9_46.4(%.loc9_46.2, %.loc9_46.4)
// CHECK:STDOUT:   %.loc9_46.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc9_46.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc9_46.5
// CHECK:STDOUT:   if %.loc9_46.6 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %.loc9_46.7: ref %.e8e = class_element_access %.loc9_45.17, element1
// CHECK:STDOUT:   %.loc9_46.8: ref %tuple.type.a8a = class_element_access %.loc9_46.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc9_46.8, element0
// CHECK:STDOUT:   %.loc9_46.9: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: %i32 = wrapper_binding v, %.loc9_46.9
// CHECK:STDOUT:   %v.ref: %i32 = name_ref v, %v
// CHECK:STDOUT:   %impl.elem0.loc10: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc10_12.1: <bound method> = bound_method %v.ref, %impl.elem0.loc10
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc10_12.2: <bound method> = bound_method %v.ref, %specific_fn.loc10
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc10_12.2(%v.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %int_0.loc12: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_11.1: <bound method> = bound_method %int_0.loc12, %impl.elem0.loc12 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc12: <specific function> = specific_function %impl.elem0.loc12, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc12_11.2: <bound method> = bound_method %int_0.loc12, %specific_fn.loc12 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %i32 = call %bound_method.loc12_11.2(%int_0.loc12) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc12: init %i32 = converted %int_0.loc12, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc9(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_45.1(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_45.1(%self.param: ref bool) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc9_45.2(%self.param: ref %optional) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc9_45.2(%self.param: ref %optional) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %optional.cpp_destructor.call: init %empty_tuple.type = call imports.%optional.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- convert.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %.795: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %H.type: type = fn_type @H [concrete]
// CHECK:STDOUT:   %H: %H.type = struct_value () [concrete]
// CHECK:STDOUT:   %StdOptional.type: type = generic_class_type @StdOptional [concrete]
// CHECK:STDOUT:   %StdOptional.generic: %StdOptional.type = struct_value () [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %tuple.type.026: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %.a2d: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %StdOptional.05d: type = class_type @StdOptional, @StdOptional(%T.67d) [symbolic]
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %StdOptional.val.551: %StdOptional.05d = struct_value (%int_1.233, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %StdOptional.Some.type.a04: type = fn_type @StdOptional.Some, @StdOptional(%T.67d) [symbolic]
// CHECK:STDOUT:   %StdOptional.Some.391: %StdOptional.Some.type.a04 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %StdOptional.4c3: type = class_type @StdOptional, @StdOptional(%i32) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %StdOptional.Some.type.389: type = fn_type @StdOptional.Some, @StdOptional(%i32) [concrete]
// CHECK:STDOUT:   %StdOptional.Some.6b6: %StdOptional.Some.type.389 = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.060: %.e8e = uninitialized_value [concrete]
// CHECK:STDOUT:   %StdOptional.val.f8e: %StdOptional.4c3 = struct_value (%int_1.233, %uninit.060) [concrete]
// CHECK:STDOUT:   %pattern_type.7c0: type = pattern_type %StdOptional.4c3 [concrete]
// CHECK:STDOUT:   %s.patt: %pattern_type.7c0 = value_binding_pattern s [concrete]
// CHECK:STDOUT:   %MakeOptional.cpp_overload_set.type: type = cpp_overload_set_type @MakeOptional.cpp_overload_set [concrete]
// CHECK:STDOUT:   %MakeOptional.cpp_overload_set.value: %MakeOptional.cpp_overload_set.type = cpp_overload_set_value @MakeOptional.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional: type = class_type @optional [concrete]
// CHECK:STDOUT:   %pattern_type.88c: type = pattern_type %optional [concrete]
// CHECK:STDOUT:   %ptr.e48: type = ptr_type %optional [concrete]
// CHECK:STDOUT:   %MakeOptional__carbon_thunk.type: type = fn_type @MakeOptional__carbon_thunk [concrete]
// CHECK:STDOUT:   %MakeOptional__carbon_thunk: %MakeOptional__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.type: type = cpp_overload_set_type @optional.has_value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.value: %optional.has_value.cpp_overload_set.type = cpp_overload_set_value @optional.has_value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %ptr.bb2: type = ptr_type bool [concrete]
// CHECK:STDOUT:   %has_value__carbon_thunk.type: type = fn_type @has_value__carbon_thunk [concrete]
// CHECK:STDOUT:   %has_value__carbon_thunk: %has_value__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %optional.value.cpp_overload_set.type: type = cpp_overload_set_type @optional.value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.value.cpp_overload_set.value: %optional.value.cpp_overload_set.type = cpp_overload_set_value @optional.value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %const.6a8: type = const_type %i32 [concrete]
// CHECK:STDOUT:   %value__carbon_thunk.type: type = fn_type @value__carbon_thunk [concrete]
// CHECK:STDOUT:   %value__carbon_thunk: %value__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %StdOptional.Some.specific_fn: <specific function> = specific_function %StdOptional.Some.6b6, @StdOptional.Some(%i32) [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f5: type = fn_type @Copy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.416: %Copy.WithSelf.Op.type.7f5 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.bab: <witness> = custom_witness (%Copy.WithSelf.Op.416), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.209: %Copy.type = facet_value %StdOptional.4c3, (%custom_witness.bab) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.159: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.209) [concrete]
// CHECK:STDOUT:   %.252: type = fn_type_with_self_type %Copy.WithSelf.Op.type.159, %Copy.facet.209 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.bound: <bound method> = bound_method %StdOptional.val.f8e, %Copy.WithSelf.Op.416 [concrete]
// CHECK:STDOUT:   %none.patt: %pattern_type.7c0 = value_binding_pattern none [concrete]
// CHECK:STDOUT:   %Take.cpp_overload_set.type: type = cpp_overload_set_type @Take.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Take.cpp_overload_set.value: %Take.cpp_overload_set.type = cpp_overload_set_value @Take.cpp_overload_set [concrete]
// CHECK:STDOUT:   %Take__carbon_thunk.type: type = fn_type @Take__carbon_thunk [concrete]
// CHECK:STDOUT:   %Take__carbon_thunk: %Take__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %optional.optional.cpp_overload_set.type: type = cpp_overload_set_type @optional.optional.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.optional.cpp_overload_set.value: %optional.optional.cpp_overload_set.type = cpp_overload_set_value @optional.optional.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional__carbon_thunk.type: type = fn_type @optional__carbon_thunk [concrete]
// CHECK:STDOUT:   %optional__carbon_thunk: %optional__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %optional.emplace.cpp_overload_set.type: type = cpp_overload_set_type @optional.emplace.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.emplace.cpp_overload_set.value: %optional.emplace.cpp_overload_set.type = cpp_overload_set_value @optional.emplace.cpp_overload_set [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk.type: type = fn_type @emplace__carbon_thunk [concrete]
// CHECK:STDOUT:   %emplace__carbon_thunk: %emplace__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %TakeRef.cpp_overload_set.type: type = cpp_overload_set_type @TakeRef.cpp_overload_set [concrete]
// CHECK:STDOUT:   %TakeRef.cpp_overload_set.value: %TakeRef.cpp_overload_set.type = cpp_overload_set_value @TakeRef.cpp_overload_set [concrete]
// CHECK:STDOUT:   %const.333: type = const_type %optional [concrete]
// CHECK:STDOUT:   %ptr.39a: type = ptr_type %const.333 [concrete]
// CHECK:STDOUT:   %TakeRef__carbon_thunk.type: type = fn_type @TakeRef__carbon_thunk [concrete]
// CHECK:STDOUT:   %TakeRef__carbon_thunk: %TakeRef__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.2ef: type = generic_interface_type @AddWith [concrete]
// CHECK:STDOUT:   %AddWith.generic: %AddWith.type.2ef = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %self.param_patt.40d: %pattern_type.831 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.560: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt.40d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc12_62.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12_62.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.9d2: %pattern_type.88c = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.d48: %pattern_type.88c = wrapper_binding_pattern self, %self.param_patt.9d2 [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor.type: type = fn_type @optional.cpp_destructor [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor: %optional.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc12_62.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12_62.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .Copy = %Core.Copy
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     .AddWith = %Core.AddWith
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .MakeOptional = %MakeOptional.cpp_overload_set.value
// CHECK:STDOUT:     .Take = %Take.cpp_overload_set.value
// CHECK:STDOUT:     .TakeRef = %TakeRef.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .StdOptional = %Core.StdOptional
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StdOptional: %StdOptional.type = import_ref Core//prelude/types/cpp/sum, StdOptional, loaded [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %Core.import_ref.b1b: @StdOptional.%StdOptional.Some.type (%StdOptional.Some.type.a04) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdOptional.%StdOptional.Some (constants.%StdOptional.Some.391)]
// CHECK:STDOUT:   %Core.import_ref.e46: @StdOptional.%StdOptional (%StdOptional.05d) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdOptional.%StdOptional.val (constants.%StdOptional.val.551)]
// CHECK:STDOUT:   %MakeOptional.cpp_overload_set.value: %MakeOptional.cpp_overload_set.type = cpp_overload_set_value @MakeOptional.cpp_overload_set [concrete = constants.%MakeOptional.cpp_overload_set.value]
// CHECK:STDOUT:   %MakeOptional__carbon_thunk.decl: %MakeOptional__carbon_thunk.type = fn_decl @MakeOptional__carbon_thunk [concrete = constants.%MakeOptional__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.value: %optional.has_value.cpp_overload_set.type = cpp_overload_set_value @optional.has_value.cpp_overload_set [concrete = constants.%optional.has_value.cpp_overload_set.value]
// CHECK:STDOUT:   %has_value__carbon_thunk.decl: %has_value__carbon_thunk.type = fn_decl @has_value__carbon_thunk [concrete = constants.%has_value__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %optional.value.cpp_overload_set.value: %optional.value.cpp_overload_set.type = cpp_overload_set_value @optional.value.cpp_overload_set [concrete = constants.%optional.value.cpp_overload_set.value]
// CHECK:STDOUT:   %value__carbon_thunk.decl: %value__carbon_thunk.type = fn_decl @value__carbon_thunk [concrete = constants.%value__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Copy: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %Take.cpp_overload_set.value: %Take.cpp_overload_set.type = cpp_overload_set_value @Take.cpp_overload_set [concrete = constants.%Take.cpp_overload_set.value]
// CHECK:STDOUT:   %Take__carbon_thunk.decl: %Take__carbon_thunk.type = fn_decl @Take__carbon_thunk [concrete = constants.%Take__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %optional.optional.cpp_overload_set.value: %optional.optional.cpp_overload_set.type = cpp_overload_set_value @optional.optional.cpp_overload_set [concrete = constants.%optional.optional.cpp_overload_set.value]
// CHECK:STDOUT:   %optional__carbon_thunk.decl: %optional__carbon_thunk.type = fn_decl @optional__carbon_thunk [concrete = constants.%optional__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %optional.emplace.cpp_overload_set.value: %optional.emplace.cpp_overload_set.type = cpp_overload_set_value @optional.emplace.cpp_overload_set [concrete = constants.%optional.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %emplace__carbon_thunk.decl: %emplace__carbon_thunk.type = fn_decl @emplace__carbon_thunk [concrete = constants.%emplace__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %TakeRef.cpp_overload_set.value: %TakeRef.cpp_overload_set.type = cpp_overload_set_value @TakeRef.cpp_overload_set [concrete = constants.%TakeRef.cpp_overload_set.value]
// CHECK:STDOUT:   %TakeRef__carbon_thunk.decl: %TakeRef__carbon_thunk.type = fn_decl @TakeRef__carbon_thunk [concrete = constants.%TakeRef__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.AddWith: %AddWith.type.2ef = import_ref Core//prelude/operators/arithmetic, AddWith, loaded [concrete = constants.%AddWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %optional.cpp_destructor.decl: %optional.cpp_destructor.type = fn_decl @optional.cpp_destructor [concrete = constants.%optional.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc12_62.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc12_62.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.88c = ref_param_pattern [concrete = constants.%self.param_patt.9d2]
// CHECK:STDOUT:     %self.patt: %pattern_type.88c = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.d48]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %optional = ref_param call_param0
// CHECK:STDOUT:     %self: ref %optional = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %H.decl: %H.type = fn_decl @H [concrete = constants.%H] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc11_17 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc11_17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11: Core.Form = init_form %i32.loc11_17 [concrete = constants.%.795]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc11_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @H(%n.param: %i32) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref.loc12: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %MakeOptional.ref: %MakeOptional.cpp_overload_set.type = name_ref MakeOptional, imports.%MakeOptional.cpp_overload_set.value [concrete = constants.%MakeOptional.cpp_overload_set.value]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc12_62.1: ref %optional = temporary_storage
// CHECK:STDOUT:   %addr.loc12_62.1: %ptr.e48 = addr_of %.loc12_62.1
// CHECK:STDOUT:   %MakeOptional__carbon_thunk.call: init %empty_tuple.type = call imports.%MakeOptional__carbon_thunk.decl(%n.ref, %addr.loc12_62.1)
// CHECK:STDOUT:   %.loc12_62.2: init %optional to %.loc12_62.1 = mark_in_place_init %MakeOptional__carbon_thunk.call
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdOptional.ref.loc12_62: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %StdOptional.loc12_62: type = class_type @StdOptional, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.4c3]
// CHECK:STDOUT:   %.loc12_62.3: ref %optional = temporary %.loc12_62.1, %.loc12_62.2
// CHECK:STDOUT:   %.loc12_62.4: %optional = acquire_value %.loc12_62.3
// CHECK:STDOUT:   %.loc12_62.5: ref %StdOptional.4c3 = temporary_storage
// CHECK:STDOUT:   %has_value.ref: %optional.has_value.cpp_overload_set.type = name_ref has_value, imports.%optional.has_value.cpp_overload_set.value [concrete = constants.%optional.has_value.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc12_62.1: <bound method> = bound_method %.loc12_62.4, %has_value.ref
// CHECK:STDOUT:   %.loc12_62.6: ref bool = temporary_storage
// CHECK:STDOUT:   %addr.loc12_62.2: %ptr.bb2 = addr_of %.loc12_62.6
// CHECK:STDOUT:   %has_value__carbon_thunk.call: init %empty_tuple.type = call imports.%has_value__carbon_thunk.decl(%.loc12_62.4, %addr.loc12_62.2)
// CHECK:STDOUT:   %.loc12_62.7: init bool to %.loc12_62.6 = mark_in_place_init %has_value__carbon_thunk.call
// CHECK:STDOUT:   %.loc12_62.8: ref bool = temporary %.loc12_62.6, %.loc12_62.7
// CHECK:STDOUT:   %.loc12_62.9: bool = acquire_value %.loc12_62.8
// CHECK:STDOUT:   if %.loc12_62.9 br !.loc12_62.1 else br !.loc12_62.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc12_62.1:
// CHECK:STDOUT:   %value.ref: %optional.value.cpp_overload_set.type = name_ref value, imports.%optional.value.cpp_overload_set.value [concrete = constants.%optional.value.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc12_62.2: <bound method> = bound_method %.loc12_62.4, %value.ref
// CHECK:STDOUT:   %value__carbon_thunk.call: ref %const.6a8 = call imports.%value__carbon_thunk.decl(%.loc12_62.4)
// CHECK:STDOUT:   %.loc12_62.10: %StdOptional.Some.type.389 = specific_constant imports.%Core.import_ref.b1b, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.Some.6b6]
// CHECK:STDOUT:   %Some.ref: %StdOptional.Some.type.389 = name_ref Some, %.loc12_62.10 [concrete = constants.%StdOptional.Some.6b6]
// CHECK:STDOUT:   %StdOptional.Some.specific_fn: <specific function> = specific_function %Some.ref, @StdOptional.Some(constants.%i32) [concrete = constants.%StdOptional.Some.specific_fn]
// CHECK:STDOUT:   %.loc12_62.11: ref %StdOptional.4c3 = splice_block %.loc12_62.5 {}
// CHECK:STDOUT:   %.loc12_62.12: ref %i32 = as_compatible %value__carbon_thunk.call
// CHECK:STDOUT:   %.loc12_62.13: ref %i32 = converted %value__carbon_thunk.call, %.loc12_62.12
// CHECK:STDOUT:   %.loc12_62.14: %i32 = acquire_value %.loc12_62.13
// CHECK:STDOUT:   %StdOptional.Some.call: init %StdOptional.4c3 to %.loc12_62.11 = call %StdOptional.Some.specific_fn(%.loc12_62.14)
// CHECK:STDOUT:   assign %.loc12_62.5, %StdOptional.Some.call
// CHECK:STDOUT:   br !.loc12_62.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc12_62.2:
// CHECK:STDOUT:   %.loc12_62.15: %StdOptional.4c3 = specific_constant imports.%Core.import_ref.e46, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   %None.ref.loc12: %StdOptional.4c3 = name_ref None, %.loc12_62.15 [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc12: %.252 = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc12_62.3: <bound method> = bound_method %None.ref.loc12, %impl.elem0.loc12 [concrete = constants.%Copy.WithSelf.Op.bound]
// CHECK:STDOUT:   %.loc12_62.16: ref %StdOptional.4c3 = splice_block %.loc12_62.5 {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call: init %StdOptional.4c3 to %.loc12_62.16 = call %bound_method.loc12_62.3(%None.ref.loc12) [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   assign %.loc12_62.5, %Copy.WithSelf.Op.call
// CHECK:STDOUT:   br !.loc12_62.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc12_62.3:
// CHECK:STDOUT:   %.loc12_62.17: %StdOptional.4c3 = acquire_value %.loc12_62.5
// CHECK:STDOUT:   %.loc12_62.18: %StdOptional.4c3 = converted %.loc12_62.2, %.loc12_62.17
// CHECK:STDOUT:   %.loc12_40: type = splice_block %StdOptional.loc12_40 [concrete = constants.%StdOptional.4c3] {
// CHECK:STDOUT:     %Core.ref.loc12: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %CppCompat.ref.loc12: <namespace> = name_ref CppCompat, imports.%CppCompat.f0dbf9.1 [concrete = imports.%CppCompat.f0dbf9.1]
// CHECK:STDOUT:     %StdOptional.ref.loc12_24: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %StdOptional.loc12_40: type = class_type @StdOptional, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.4c3]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %s: %StdOptional.4c3 = wrapper_binding s, %.loc12_62.18
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %s.patt: %pattern_type.7c0 = value_binding_pattern s [concrete = constants.%s.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ref.loc14: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:   %CppCompat.ref.loc14: <namespace> = name_ref CppCompat, imports.%CppCompat.f0dbf9.1 [concrete = imports.%CppCompat.f0dbf9.1]
// CHECK:STDOUT:   %StdOptional.ref.loc14: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %i32.loc14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %StdOptional.loc14: type = class_type @StdOptional, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.4c3]
// CHECK:STDOUT:   %.loc14: %StdOptional.4c3 = specific_constant imports.%Core.import_ref.e46, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   %None.ref.loc14: %StdOptional.4c3 = name_ref None, %.loc14 [concrete = constants.%StdOptional.val.f8e]
// CHECK:STDOUT:   %.loc13: type = splice_block %StdOptional.loc13 [concrete = constants.%StdOptional.4c3] {
// CHECK:STDOUT:     %Core.ref.loc13: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %CppCompat.ref.loc13: <namespace> = name_ref CppCompat, imports.%CppCompat.f0dbf9.1 [concrete = imports.%CppCompat.f0dbf9.1]
// CHECK:STDOUT:     %StdOptional.ref.loc13: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:     %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %StdOptional.loc13: type = class_type @StdOptional, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.4c3]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %none: %StdOptional.4c3 = wrapper_binding none, %None.ref.loc14
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %none.patt: %pattern_type.7c0 = value_binding_pattern none [concrete = constants.%none.patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp.ref.loc15_10: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Take.ref.loc15_13: %Take.cpp_overload_set.type = name_ref Take, imports.%Take.cpp_overload_set.value [concrete = constants.%Take.cpp_overload_set.value]
// CHECK:STDOUT:   %s.ref.loc15_19: %StdOptional.4c3 = name_ref s, %s
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdOptional.ref.loc15_19: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %StdOptional.loc15_19: type = class_type @StdOptional, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.4c3]
// CHECK:STDOUT:   %.loc15_19.1: ref %optional = temporary_storage
// CHECK:STDOUT:   %optional.ref.loc15_19: %optional.optional.cpp_overload_set.type = name_ref optional, imports.%optional.optional.cpp_overload_set.value [concrete = constants.%optional.optional.cpp_overload_set.value]
// CHECK:STDOUT:   %.loc15_19.2: ref %optional = splice_block %.loc15_19.1 {}
// CHECK:STDOUT:   %addr.loc15_19: %ptr.e48 = addr_of %.loc15_19.2
// CHECK:STDOUT:   %optional__carbon_thunk.call.loc15_19: init %empty_tuple.type = call imports.%optional__carbon_thunk.decl(%addr.loc15_19)
// CHECK:STDOUT:   %.loc15_19.3: init %optional to %.loc15_19.2 = mark_in_place_init %optional__carbon_thunk.call.loc15_19
// CHECK:STDOUT:   assign %.loc15_19.1, %.loc15_19.3
// CHECK:STDOUT:   %int_0.loc15_19: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_19.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_19.1: <bound method> = bound_method %int_0.loc15_19, %impl.elem0.loc15_19.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc15_19.1: <specific function> = specific_function %impl.elem0.loc15_19.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_19.2: <bound method> = bound_method %int_0.loc15_19, %specific_fn.loc15_19.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_19: init %u1 = call %bound_method.loc15_19.2(%int_0.loc15_19) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_19.4: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_19 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_19.5: %u1 = converted %int_0.loc15_19, %.loc15_19.4 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_19.6: ref %u1 = class_element_access %s.ref.loc15_19, element0
// CHECK:STDOUT:   %impl.elem0.loc15_19.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_19.3: <bound method> = bound_method %.loc15_19.5, %impl.elem0.loc15_19.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc15_19.2: <specific function> = specific_function %impl.elem0.loc15_19.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_19.4: <bound method> = bound_method %.loc15_19.5, %specific_fn.loc15_19.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc15_19.7: %u1 = acquire_value %.loc15_19.6
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15_19: init bool = call %bound_method.loc15_19.4(%.loc15_19.5, %.loc15_19.7)
// CHECK:STDOUT:   %.loc15_19.8: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15_19
// CHECK:STDOUT:   %.loc15_19.9: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15_19, %.loc15_19.8
// CHECK:STDOUT:   if %.loc15_19.9 br !.loc15_19.1 else br !.loc15_19.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_19.1:
// CHECK:STDOUT:   %.loc15_19.10: ref %.e8e = class_element_access %s.ref.loc15_19, element1
// CHECK:STDOUT:   %.loc15_19.11: ref %tuple.type.a8a = class_element_access %.loc15_19.10, element0
// CHECK:STDOUT:   %tuple.elem0.loc15_19: ref %i32 = tuple_access %.loc15_19.11, element0
// CHECK:STDOUT:   %.loc15_19.12: %i32 = acquire_value %tuple.elem0.loc15_19
// CHECK:STDOUT:   %emplace.ref.loc15_19: %optional.emplace.cpp_overload_set.type = name_ref emplace, imports.%optional.emplace.cpp_overload_set.value [concrete = constants.%optional.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc15_19.5: <bound method> = bound_method %.loc15_19.1, %emplace.ref.loc15_19
// CHECK:STDOUT:   %.loc15_19.13: %optional = acquire_value %.loc15_19.1
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc15_19: ref %i32 = call imports.%emplace__carbon_thunk.decl(%.loc15_19.13, %.loc15_19.12)
// CHECK:STDOUT:   br !.loc15_19.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_19.2:
// CHECK:STDOUT:   br !.loc15_19.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_19.3:
// CHECK:STDOUT:   %.loc15_19.14: %optional = acquire_value %.loc15_19.1
// CHECK:STDOUT:   %.loc15_19.15: %optional = converted %s.ref.loc15_19, %.loc15_19.14
// CHECK:STDOUT:   %.loc15_19.16: ref %optional = value_as_ref %.loc15_19.15
// CHECK:STDOUT:   %addr.loc15_20: %ptr.e48 = addr_of %.loc15_19.16
// CHECK:STDOUT:   %Take__carbon_thunk.call.loc15_20: init %i32 = call imports.%Take__carbon_thunk.decl(%addr.loc15_20)
// CHECK:STDOUT:   %Cpp.ref.loc15_24: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %TakeRef.ref: %TakeRef.cpp_overload_set.type = name_ref TakeRef, imports.%TakeRef.cpp_overload_set.value [concrete = constants.%TakeRef.cpp_overload_set.value]
// CHECK:STDOUT:   %s.ref.loc15_36: %StdOptional.4c3 = name_ref s, %s
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdOptional.ref.loc15_36: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %StdOptional.loc15_36: type = class_type @StdOptional, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.4c3]
// CHECK:STDOUT:   %.loc15_36.1: ref %optional = temporary_storage
// CHECK:STDOUT:   %optional.ref.loc15_36: %optional.optional.cpp_overload_set.type = name_ref optional, imports.%optional.optional.cpp_overload_set.value [concrete = constants.%optional.optional.cpp_overload_set.value]
// CHECK:STDOUT:   %.loc15_36.2: ref %optional = splice_block %.loc15_36.1 {}
// CHECK:STDOUT:   %addr.loc15_36: %ptr.e48 = addr_of %.loc15_36.2
// CHECK:STDOUT:   %optional__carbon_thunk.call.loc15_36: init %empty_tuple.type = call imports.%optional__carbon_thunk.decl(%addr.loc15_36)
// CHECK:STDOUT:   %.loc15_36.3: init %optional to %.loc15_36.2 = mark_in_place_init %optional__carbon_thunk.call.loc15_36
// CHECK:STDOUT:   assign %.loc15_36.1, %.loc15_36.3
// CHECK:STDOUT:   %int_0.loc15_36: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_36.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_36.1: <bound method> = bound_method %int_0.loc15_36, %impl.elem0.loc15_36.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc15_36.1: <specific function> = specific_function %impl.elem0.loc15_36.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_36.2: <bound method> = bound_method %int_0.loc15_36, %specific_fn.loc15_36.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_36: init %u1 = call %bound_method.loc15_36.2(%int_0.loc15_36) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_36.4: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_36 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_36.5: %u1 = converted %int_0.loc15_36, %.loc15_36.4 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_36.6: ref %u1 = class_element_access %s.ref.loc15_36, element0
// CHECK:STDOUT:   %impl.elem0.loc15_36.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_36.3: <bound method> = bound_method %.loc15_36.5, %impl.elem0.loc15_36.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc15_36.2: <specific function> = specific_function %impl.elem0.loc15_36.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_36.4: <bound method> = bound_method %.loc15_36.5, %specific_fn.loc15_36.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc15_36.7: %u1 = acquire_value %.loc15_36.6
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15_36: init bool = call %bound_method.loc15_36.4(%.loc15_36.5, %.loc15_36.7)
// CHECK:STDOUT:   %.loc15_36.8: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15_36
// CHECK:STDOUT:   %.loc15_36.9: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15_36, %.loc15_36.8
// CHECK:STDOUT:   if %.loc15_36.9 br !.loc15_36.1 else br !.loc15_36.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_36.1:
// CHECK:STDOUT:   %.loc15_36.10: ref %.e8e = class_element_access %s.ref.loc15_36, element1
// CHECK:STDOUT:   %.loc15_36.11: ref %tuple.type.a8a = class_element_access %.loc15_36.10, element0
// CHECK:STDOUT:   %tuple.elem0.loc15_36: ref %i32 = tuple_access %.loc15_36.11, element0
// CHECK:STDOUT:   %.loc15_36.12: %i32 = acquire_value %tuple.elem0.loc15_36
// CHECK:STDOUT:   %emplace.ref.loc15_36: %optional.emplace.cpp_overload_set.type = name_ref emplace, imports.%optional.emplace.cpp_overload_set.value [concrete = constants.%optional.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc15_36.5: <bound method> = bound_method %.loc15_36.1, %emplace.ref.loc15_36
// CHECK:STDOUT:   %.loc15_36.13: %optional = acquire_value %.loc15_36.1
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc15_36: ref %i32 = call imports.%emplace__carbon_thunk.decl(%.loc15_36.13, %.loc15_36.12)
// CHECK:STDOUT:   br !.loc15_36.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_36.2:
// CHECK:STDOUT:   br !.loc15_36.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_36.3:
// CHECK:STDOUT:   %.loc15_36.14: %optional = acquire_value %.loc15_36.1
// CHECK:STDOUT:   %.loc15_36.15: %optional = converted %s.ref.loc15_36, %.loc15_36.14
// CHECK:STDOUT:   %.loc15_36.16: ref %optional = value_as_ref %.loc15_36.15
// CHECK:STDOUT:   %addr.loc15_37: %ptr.e48 = addr_of %.loc15_36.16
// CHECK:STDOUT:   %.loc15_37.1: %ptr.39a = as_compatible %addr.loc15_37
// CHECK:STDOUT:   %.loc15_37.2: %ptr.39a = converted %addr.loc15_37, %.loc15_37.1
// CHECK:STDOUT:   %TakeRef__carbon_thunk.call: init %i32 = call imports.%TakeRef__carbon_thunk.decl(%.loc15_37.2)
// CHECK:STDOUT:   %impl.elem1.loc15_22: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc15_22.1: <bound method> = bound_method %Take__carbon_thunk.call.loc15_20, %impl.elem1.loc15_22
// CHECK:STDOUT:   %specific_fn.loc15_22: <specific function> = specific_function %impl.elem1.loc15_22, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc15_22.2: <bound method> = bound_method %Take__carbon_thunk.call.loc15_20, %specific_fn.loc15_22
// CHECK:STDOUT:   %.loc15_20.1: %i32 = value_of_initializer %Take__carbon_thunk.call.loc15_20
// CHECK:STDOUT:   %.loc15_20.2: %i32 = converted %Take__carbon_thunk.call.loc15_20, %.loc15_20.1
// CHECK:STDOUT:   %.loc15_37.3: %i32 = value_of_initializer %TakeRef__carbon_thunk.call
// CHECK:STDOUT:   %.loc15_37.4: %i32 = converted %TakeRef__carbon_thunk.call, %.loc15_37.3
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc15_22: init %i32 = call %bound_method.loc15_22.2(%.loc15_20.2, %.loc15_37.4)
// CHECK:STDOUT:   %Cpp.ref.loc15_41: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %Take.ref.loc15_44: %Take.cpp_overload_set.type = name_ref Take, imports.%Take.cpp_overload_set.value [concrete = constants.%Take.cpp_overload_set.value]
// CHECK:STDOUT:   %none.ref: %StdOptional.4c3 = name_ref none, %none
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %StdOptional.ref.loc15_50: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %StdOptional.loc15_50: type = class_type @StdOptional, @StdOptional(constants.%i32) [concrete = constants.%StdOptional.4c3]
// CHECK:STDOUT:   %.loc15_50.1: ref %optional = temporary_storage
// CHECK:STDOUT:   %optional.ref.loc15_50: %optional.optional.cpp_overload_set.type = name_ref optional, imports.%optional.optional.cpp_overload_set.value [concrete = constants.%optional.optional.cpp_overload_set.value]
// CHECK:STDOUT:   %.loc15_50.2: ref %optional = splice_block %.loc15_50.1 {}
// CHECK:STDOUT:   %addr.loc15_50: %ptr.e48 = addr_of %.loc15_50.2
// CHECK:STDOUT:   %optional__carbon_thunk.call.loc15_50: init %empty_tuple.type = call imports.%optional__carbon_thunk.decl(%addr.loc15_50)
// CHECK:STDOUT:   %.loc15_50.3: init %optional to %.loc15_50.2 = mark_in_place_init %optional__carbon_thunk.call.loc15_50
// CHECK:STDOUT:   assign %.loc15_50.1, %.loc15_50.3
// CHECK:STDOUT:   %int_0.loc15_50: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc15_50.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_50.1: <bound method> = bound_method %int_0.loc15_50, %impl.elem0.loc15_50.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc15_50.1: <specific function> = specific_function %impl.elem0.loc15_50.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_50.2: <bound method> = bound_method %int_0.loc15_50, %specific_fn.loc15_50.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_50: init %u1 = call %bound_method.loc15_50.2(%int_0.loc15_50) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_50.4: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15_50 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_50.5: %u1 = converted %int_0.loc15_50, %.loc15_50.4 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc15_50.6: ref %u1 = class_element_access %none.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc15_50.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_50.3: <bound method> = bound_method %.loc15_50.5, %impl.elem0.loc15_50.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc15_50.2: <specific function> = specific_function %impl.elem0.loc15_50.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_50.4: <bound method> = bound_method %.loc15_50.5, %specific_fn.loc15_50.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc15_50.7: %u1 = acquire_value %.loc15_50.6
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15_50: init bool = call %bound_method.loc15_50.4(%.loc15_50.5, %.loc15_50.7)
// CHECK:STDOUT:   %.loc15_50.8: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15_50
// CHECK:STDOUT:   %.loc15_50.9: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15_50, %.loc15_50.8
// CHECK:STDOUT:   if %.loc15_50.9 br !.loc15_50.1 else br !.loc15_50.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_50.1:
// CHECK:STDOUT:   %.loc15_50.10: ref %.e8e = class_element_access %none.ref, element1
// CHECK:STDOUT:   %.loc15_50.11: ref %tuple.type.a8a = class_element_access %.loc15_50.10, element0
// CHECK:STDOUT:   %tuple.elem0.loc15_50: ref %i32 = tuple_access %.loc15_50.11, element0
// CHECK:STDOUT:   %.loc15_50.12: %i32 = acquire_value %tuple.elem0.loc15_50
// CHECK:STDOUT:   %emplace.ref.loc15_50: %optional.emplace.cpp_overload_set.type = name_ref emplace, imports.%optional.emplace.cpp_overload_set.value [concrete = constants.%optional.emplace.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc15_50.5: <bound method> = bound_method %.loc15_50.1, %emplace.ref.loc15_50
// CHECK:STDOUT:   %.loc15_50.13: %optional = acquire_value %.loc15_50.1
// CHECK:STDOUT:   %emplace__carbon_thunk.call.loc15_50: ref %i32 = call imports.%emplace__carbon_thunk.decl(%.loc15_50.13, %.loc15_50.12)
// CHECK:STDOUT:   br !.loc15_50.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_50.2:
// CHECK:STDOUT:   br !.loc15_50.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc15_50.3:
// CHECK:STDOUT:   %.loc15_50.14: %optional = acquire_value %.loc15_50.1
// CHECK:STDOUT:   %.loc15_50.15: %optional = converted %none.ref, %.loc15_50.14
// CHECK:STDOUT:   %.loc15_50.16: ref %optional = value_as_ref %.loc15_50.15
// CHECK:STDOUT:   %addr.loc15_54: %ptr.e48 = addr_of %.loc15_50.16
// CHECK:STDOUT:   %Take__carbon_thunk.call.loc15_54: init %i32 = call imports.%Take__carbon_thunk.decl(%addr.loc15_54)
// CHECK:STDOUT:   %impl.elem1.loc15_39: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc15_39.1: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc15_22, %impl.elem1.loc15_39
// CHECK:STDOUT:   %specific_fn.loc15_39: <specific function> = specific_function %impl.elem1.loc15_39, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc15_39.2: <bound method> = bound_method %Int.as.AddWith.impl.Op.call.loc15_22, %specific_fn.loc15_39
// CHECK:STDOUT:   %.loc15_22.1: %i32 = value_of_initializer %Int.as.AddWith.impl.Op.call.loc15_22
// CHECK:STDOUT:   %.loc15_22.2: %i32 = converted %Int.as.AddWith.impl.Op.call.loc15_22, %.loc15_22.1
// CHECK:STDOUT:   %.loc15_54.1: %i32 = value_of_initializer %Take__carbon_thunk.call.loc15_54
// CHECK:STDOUT:   %.loc15_54.2: %i32 = converted %Take__carbon_thunk.call.loc15_54, %.loc15_54.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc15_39: init %i32 = call %bound_method.loc15_39.2(%.loc15_22.2, %.loc15_54.2)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc12_62.1: <bound method> = bound_method %.loc12_62.8, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc12_62.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc12_62.1(%.loc12_62.8)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc12_62.2: <bound method> = bound_method %.loc12_62.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc12_62.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc12_62.2(%.loc12_62.3)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call.loc15_39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_62.1(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_62.1(%self.param: ref bool) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_62.2(%self.param: ref %optional) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_62.2(%self.param: ref %optional) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %optional.cpp_destructor.call: init %empty_tuple.type = call imports.%optional.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- pointer_payload.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %Int.type: type = generic_class_type @Int [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %Int.generic: %Int.type = struct_value () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete]
// CHECK:STDOUT:   %.f34: Core.Form = init_form bool [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %return.param_patt.5a1: %pattern_type.831 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.c0c: %pattern_type.831 = return_slot_pattern %return.param_patt.5a1, bool [concrete]
// CHECK:STDOUT:   %P.type: type = fn_type @P [concrete]
// CHECK:STDOUT:   %P: %P.type = struct_value () [concrete]
// CHECK:STDOUT:   %MakePointer.cpp_overload_set.type: type = cpp_overload_set_type @MakePointer.cpp_overload_set [concrete]
// CHECK:STDOUT:   %MakePointer.cpp_overload_set.value: %MakePointer.cpp_overload_set.type = cpp_overload_set_value @MakePointer.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional: type = class_type @optional [concrete]
// CHECK:STDOUT:   %pattern_type.dd2: type = pattern_type %optional [concrete]
// CHECK:STDOUT:   %ptr.f7e: type = ptr_type %optional [concrete]
// CHECK:STDOUT:   %MakePointer__carbon_thunk.type: type = fn_type @MakePointer__carbon_thunk [concrete]
// CHECK:STDOUT:   %MakePointer__carbon_thunk: %MakePointer__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %ptr.d08: type = ptr_type %i32 [concrete]
// CHECK:STDOUT:   %Optional.type: type = generic_class_type @Optional [concrete]
// CHECK:STDOUT:   %Optional.generic: %Optional.type = struct_value () [concrete]
// CHECK:STDOUT:   %OptionalStorage.type: type = facet_type <@OptionalStorage> [concrete]
// CHECK:STDOUT:   %T.220: %OptionalStorage.type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.type.e9e: type = fn_type @Optional.HasValue, @Optional(%T.220) [symbolic]
// CHECK:STDOUT:   %Optional.HasValue.6cd: %Optional.HasValue.type.e9e = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.type: type = facet_type <@Destroy> [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %T.67d: type = symbolic_binding T, 0 [symbolic]
// CHECK:STDOUT:   %ptr.e8f: type = ptr_type %T.67d [symbolic]
// CHECK:STDOUT:   %Destroy.lookup_impl_witness.781: <witness> = lookup_impl_witness %ptr.e8f, @Destroy [symbolic]
// CHECK:STDOUT:   %Destroy.facet.e46: %Destroy.type = facet_value %ptr.e8f, (%Destroy.lookup_impl_witness.781) [symbolic]
// CHECK:STDOUT:   %MaybeUnformed.ddb: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.e46) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.type.0e1: type = fn_type @ptr.as.OptionalStorage.impl.Has, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Has.05c: %ptr.as.OptionalStorage.impl.Has.type.0e1 = struct_value () [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Some.type.71e: type = fn_type @ptr.as.OptionalStorage.impl.Some, @ptr.as.OptionalStorage.impl(%T.67d) [symbolic]
// CHECK:STDOUT:   %ptr.as.OptionalStorage.impl.Some.caa: %ptr.as.OptionalStorage.impl.Some.type.71e = struct_value () [symbolic]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.f8f19d.1: <witness> = custom_witness (%Destroy.WithSelf.Op.403171.1, %Destroy.WithSelf.SubobjectDestroy.d01daf.1, %Destroy.WithSelf.SelfDestruct.db3fdb.1), @Destroy [concrete]
// CHECK:STDOUT:   %Destroy.facet.4ee: %Destroy.type = facet_value %ptr.d08, (%custom_witness.f8f19d.1) [concrete]
// CHECK:STDOUT:   %MaybeUnformed.729: type = class_type @MaybeUnformed, @MaybeUnformed(%Destroy.facet.4ee) [concrete]
// CHECK:STDOUT:   %OptionalStorage.impl_witness.0ce: <witness> = impl_witness imports.%OptionalStorage.impl_witness_table.110, @ptr.as.OptionalStorage.impl(%i32) [concrete]
// CHECK:STDOUT:   %.0f8: type = maybe_unformed_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %OptionalStorage.facet.f91: %OptionalStorage.type = facet_value %ptr.d08, (%OptionalStorage.impl_witness.0ce) [concrete]
// CHECK:STDOUT:   %Optional.5b3: type = class_type @Optional, @Optional(%OptionalStorage.facet.f91) [concrete]
// CHECK:STDOUT:   %Optional.HasValue.type.c62: type = fn_type @Optional.HasValue, @Optional(%OptionalStorage.facet.f91) [concrete]
// CHECK:STDOUT:   %Optional.HasValue.84d: %Optional.HasValue.type.c62 = struct_value () [concrete]
// CHECK:STDOUT:   %StdOptional.type: type = generic_class_type @StdOptional [concrete]
// CHECK:STDOUT:   %StdOptional.generic: %StdOptional.type = struct_value () [concrete]
// CHECK:STDOUT:   %tuple.type.026: type = tuple_type (%T.67d) [symbolic]
// CHECK:STDOUT:   %.a2d: type = custom_layout_type {size=0, align=0, .Some@0: %tuple.type.026} [symbolic]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %StdOptional.05d: type = class_type @StdOptional, @StdOptional(%T.67d) [symbolic]
// CHECK:STDOUT:   %uninit.37a: %.a2d = uninitialized_value [symbolic]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %StdOptional.val.551: %StdOptional.05d = struct_value (%int_1.233, %uninit.37a) [symbolic]
// CHECK:STDOUT:   %StdOptional.Some.type.a04: type = fn_type @StdOptional.Some, @StdOptional(%T.67d) [symbolic]
// CHECK:STDOUT:   %StdOptional.Some.391: %StdOptional.Some.type.a04 = struct_value () [symbolic]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %StdOptional.0b2: type = class_type @StdOptional, @StdOptional(%Optional.5b3) [concrete]
// CHECK:STDOUT:   %pattern_type.ef8: type = pattern_type %Optional.5b3 [concrete]
// CHECK:STDOUT:   %tuple.type.e2f: type = tuple_type (%Optional.5b3) [concrete]
// CHECK:STDOUT:   %.851: type = custom_layout_type {size=8, align=8, .Some@0: %tuple.type.e2f} [concrete]
// CHECK:STDOUT:   %StdOptional.Some.type.27e: type = fn_type @StdOptional.Some, @StdOptional(%Optional.5b3) [concrete]
// CHECK:STDOUT:   %StdOptional.Some.dee: %StdOptional.Some.type.27e = struct_value () [concrete]
// CHECK:STDOUT:   %uninit.6c5: %.851 = uninitialized_value [concrete]
// CHECK:STDOUT:   %StdOptional.val.d23: %StdOptional.0b2 = struct_value (%int_1.233, %uninit.6c5) [concrete]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.type: type = cpp_overload_set_type @optional.has_value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.value: %optional.has_value.cpp_overload_set.type = cpp_overload_set_value @optional.has_value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %ptr.bb2: type = ptr_type bool [concrete]
// CHECK:STDOUT:   %has_value__carbon_thunk.type: type = fn_type @has_value__carbon_thunk [concrete]
// CHECK:STDOUT:   %has_value__carbon_thunk: %has_value__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %optional.value.cpp_overload_set.type: type = cpp_overload_set_type @optional.value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %optional.value.cpp_overload_set.value: %optional.value.cpp_overload_set.type = cpp_overload_set_value @optional.value.cpp_overload_set [concrete]
// CHECK:STDOUT:   %const.e2a: type = const_type %ptr.d08 [concrete]
// CHECK:STDOUT:   %value__carbon_thunk.type: type = fn_type @value__carbon_thunk [concrete]
// CHECK:STDOUT:   %value__carbon_thunk: %value__carbon_thunk.type = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.f20: type = pattern_type %StdOptional.0b2 [concrete]
// CHECK:STDOUT:   %StdOptional.Some.specific_fn: <specific function> = specific_function %StdOptional.Some.dee, @StdOptional.Some(%Optional.5b3) [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.0ff: type = generic_interface_type @ImplicitAs [concrete]
// CHECK:STDOUT:   %ImplicitAs.generic: %ImplicitAs.type.0ff = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.429: type = facet_type <@ImplicitAs, @ImplicitAs(%Optional.5b3)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.3aa489.2: type = facet_type <@ImplicitAs, @ImplicitAs(%T.67d)> [symbolic]
// CHECK:STDOUT:   %U.294: %ImplicitAs.type.3aa489.2 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %const.as.ImplicitAs.impl.Convert.type.f7e: type = fn_type @const.as.ImplicitAs.impl.Convert, @const.as.ImplicitAs.impl(%T.67d, %U.294) [symbolic]
// CHECK:STDOUT:   %const.as.ImplicitAs.impl.Convert.2f7: %const.as.ImplicitAs.impl.Convert.type.f7e = struct_value () [symbolic]
// CHECK:STDOUT:   %OptionalAs.type.3b8: type = facet_type <@OptionalAs, @OptionalAs(%T.220)> [symbolic]
// CHECK:STDOUT:   %U.042: %OptionalAs.type.3b8 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.type.ad5: type = fn_type @U.as_type.as.ImplicitAs.impl.Convert.2, @U.as_type.as.ImplicitAs.impl.167(%T.220, %U.042) [symbolic]
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.331: %U.as_type.as.ImplicitAs.impl.Convert.type.ad5 = struct_value () [symbolic]
// CHECK:STDOUT:   %OptionalAs.type.313: type = facet_type <@OptionalAs, @OptionalAs(%OptionalStorage.facet.f91)> [concrete]
// CHECK:STDOUT:   %T.as_type.as.OptionalAs.impl.Convert.type.774: type = fn_type @T.as_type.as.OptionalAs.impl.Convert, @T.as_type.as.OptionalAs.impl(%T.220) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.OptionalAs.impl.Convert.5f9: %T.as_type.as.OptionalAs.impl.Convert.type.774 = struct_value () [symbolic]
// CHECK:STDOUT:   %OptionalAs.impl_witness.fc9: <witness> = impl_witness imports.%OptionalAs.impl_witness_table.2e9, @T.as_type.as.OptionalAs.impl(%OptionalStorage.facet.f91) [concrete]
// CHECK:STDOUT:   %OptionalAs.facet: %OptionalAs.type.313 = facet_value %ptr.d08, (%OptionalAs.impl_witness.fc9) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.66f: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.bb5, @U.as_type.as.ImplicitAs.impl.167(%OptionalStorage.facet.f91, %OptionalAs.facet) [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.ea2: %ImplicitAs.type.429 = facet_value %ptr.d08, (%ImplicitAs.impl_witness.66f) [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.c34: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.5de, @const.as.ImplicitAs.impl(%Optional.5b3, %ImplicitAs.facet.ea2) [concrete]
// CHECK:STDOUT:   %const.as.ImplicitAs.impl.Convert.type.b3c: type = fn_type @const.as.ImplicitAs.impl.Convert, @const.as.ImplicitAs.impl(%Optional.5b3, %ImplicitAs.facet.ea2) [concrete]
// CHECK:STDOUT:   %const.as.ImplicitAs.impl.Convert.1e3: %const.as.ImplicitAs.impl.Convert.type.b3c = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.6b4: %ImplicitAs.type.429 = facet_value %const.e2a, (%ImplicitAs.impl_witness.c34) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.940: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%Optional.5b3, %ImplicitAs.facet.6b4) [concrete]
// CHECK:STDOUT:   %.4a8: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.940, %ImplicitAs.facet.6b4 [concrete]
// CHECK:STDOUT:   %const.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %const.as.ImplicitAs.impl.Convert.1e3, @const.as.ImplicitAs.impl.Convert(%Optional.5b3, %ImplicitAs.facet.ea2) [concrete]
// CHECK:STDOUT:   %pattern_type.59d: type = pattern_type %.0f8 [concrete]
// CHECK:STDOUT:   %self.param_patt.9e1: %pattern_type.59d = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.8da: %pattern_type.59d = wrapper_binding_pattern self, %self.param_patt.9e1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc11_28.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc11_28.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6db: type = pattern_type %MaybeUnformed.729 [concrete]
// CHECK:STDOUT:   %self.param_patt.e99: %pattern_type.6db = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.e88: %pattern_type.6db = wrapper_binding_pattern self, %self.param_patt.e99 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc11_28.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc11_28.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.d96: %pattern_type.ef8 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.77d: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt.d96 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc11_28.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc11_28.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc11_28.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.7f5: type = fn_type @Copy.WithSelf.Op.2 [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.416: %Copy.WithSelf.Op.type.7f5 = struct_value () [concrete]
// CHECK:STDOUT:   %custom_witness.bab: <witness> = custom_witness (%Copy.WithSelf.Op.416), @Copy [concrete]
// CHECK:STDOUT:   %Copy.facet.87e: %Copy.type = facet_value %StdOptional.0b2, (%custom_witness.bab) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.5e7: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.87e) [concrete]
// CHECK:STDOUT:   %.119: type = fn_type_with_self_type %Copy.WithSelf.Op.type.5e7, %Copy.facet.87e [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.bound: <bound method> = bound_method %StdOptional.val.d23, %Copy.WithSelf.Op.416 [concrete]
// CHECK:STDOUT:   %self.param_patt.40d: %pattern_type.831 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.560: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt.40d [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc11_28.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc11_28.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.5: type = fn_type @Destroy.WithSelf.SelfDestruct.loc11_28.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.5: %Destroy.WithSelf.SelfDestruct.type.fbceb5.5 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.09e: %pattern_type.dd2 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.f07: %pattern_type.dd2 = wrapper_binding_pattern self, %self.param_patt.09e [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor.type: type = fn_type @optional.cpp_destructor [concrete]
// CHECK:STDOUT:   %optional.cpp_destructor: %optional.cpp_destructor.type = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc11_27 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.6: type = fn_type @Destroy.WithSelf.SelfDestruct.loc11_27 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.6: %Destroy.WithSelf.SelfDestruct.type.fbceb5.6 = struct_value () [concrete]
// CHECK:STDOUT:   %p.patt: %pattern_type.ef8 = value_binding_pattern p [concrete]
// CHECK:STDOUT:   %pattern_type.26e: type = pattern_type %tuple.type.e2f [concrete]
// CHECK:STDOUT:   %.f12: %pattern_type.26e = tuple_pattern (%p.patt) [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %EqWith.type.f77: type = generic_interface_type @EqWith [concrete]
// CHECK:STDOUT:   %EqWith.generic: %EqWith.type.f77 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.f34: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Optional.HasValue.specific_fn.3e1: <specific function> = specific_function %Optional.HasValue.84d, @Optional.HasValue(%OptionalStorage.facet.f91) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound.22c: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %false: bool = bool_literal false [concrete]
// CHECK:STDOUT:   %Copy.impl_witness.5e1: <witness> = impl_witness imports.%Copy.impl_witness_table.bda [concrete]
// CHECK:STDOUT:   %Copy.facet.7af: %Copy.type = facet_value bool, (%Copy.impl_witness.5e1) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.d02: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.7af) [concrete]
// CHECK:STDOUT:   %.e28: type = fn_type_with_self_type %Copy.WithSelf.Op.type.d02, %Copy.facet.7af [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.type: type = fn_type @bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op: %bool.as.Copy.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.bound: <bound method> = bound_method %false, %bool.as.Copy.impl.Op [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core: <namespace> = namespace file.%Core.import, [concrete] {
// CHECK:STDOUT:     .Int = %Core.Int
// CHECK:STDOUT:     .Bool = %Core.Bool
// CHECK:STDOUT:     .Optional = %Core.Optional
// CHECK:STDOUT:     .CppCompat = %CppCompat.f0dbf9.1
// CHECK:STDOUT:     .ImplicitAs = %Core.ImplicitAs
// CHECK:STDOUT:     .Destroy = %Core.Destroy
// CHECK:STDOUT:     .Copy = %Core.Copy.e5d
// CHECK:STDOUT:     .EqWith = %Core.EqWith
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Cpp: <namespace> = namespace file.%Cpp.import_cpp, [concrete] {
// CHECK:STDOUT:     .MakePointer = %MakePointer.cpp_overload_set.value
// CHECK:STDOUT:     import Cpp//...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Int: %Int.type = import_ref Core//prelude/types/int, Int, loaded [concrete = constants.%Int.generic]
// CHECK:STDOUT:   %Core.Bool: type = import_ref Core//prelude/types/bool, Bool, loaded [concrete = bool]
// CHECK:STDOUT:   %MakePointer.cpp_overload_set.value: %MakePointer.cpp_overload_set.type = cpp_overload_set_value @MakePointer.cpp_overload_set [concrete = constants.%MakePointer.cpp_overload_set.value]
// CHECK:STDOUT:   %MakePointer__carbon_thunk.decl: %MakePointer__carbon_thunk.type = fn_decl @MakePointer__carbon_thunk [concrete = constants.%MakePointer__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.Optional: %Optional.type = import_ref Core//prelude/types/optional, Optional, loaded [concrete = constants.%Optional.generic]
// CHECK:STDOUT:   %Core.import_ref.729: @Optional.%Optional.HasValue.type (%Optional.HasValue.type.e9e) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @Optional.%Optional.HasValue (constants.%Optional.HasValue.6cd)]
// CHECK:STDOUT:   %Core.import_ref.509: type = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%MaybeUnformed (constants.%MaybeUnformed.ddb)]
// CHECK:STDOUT:   %Core.import_ref.105 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.fa7: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Some.type (%ptr.as.OptionalStorage.impl.Some.type.71e) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Some (constants.%ptr.as.OptionalStorage.impl.Some.caa)]
// CHECK:STDOUT:   %Core.import_ref.575: @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has.type (%ptr.as.OptionalStorage.impl.Has.type.0e1) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @ptr.as.OptionalStorage.impl.%ptr.as.OptionalStorage.impl.Has (constants.%ptr.as.OptionalStorage.impl.Has.05c)]
// CHECK:STDOUT:   %Core.import_ref.306 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.3e3 = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OptionalStorage.impl_witness_table.110 = impl_witness_table (%Core.import_ref.509, %Core.import_ref.105, %Core.import_ref.fa7, %Core.import_ref.575, %Core.import_ref.306, %Core.import_ref.3e3), @ptr.as.OptionalStorage.impl [concrete]
// CHECK:STDOUT:   %Core.CppCompat: <namespace> = import_ref Core//prelude, CppCompat, loaded
// CHECK:STDOUT:   %CppCompat.f0dbf9.1: <namespace> = namespace %Core.CppCompat, [concrete] {
// CHECK:STDOUT:     .StdOptional = %Core.StdOptional
// CHECK:STDOUT:     import Core//prelude
// CHECK:STDOUT:     import Core//prelude/...
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.StdOptional: %StdOptional.type = import_ref Core//prelude/types/cpp/sum, StdOptional, loaded [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %Core.import_ref.b1b: @StdOptional.%StdOptional.Some.type (%StdOptional.Some.type.a04) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdOptional.%StdOptional.Some (constants.%StdOptional.Some.391)]
// CHECK:STDOUT:   %Core.import_ref.e46: @StdOptional.%StdOptional (%StdOptional.05d) = import_ref Core//prelude/types/cpp/sum, loc{{\d+_\d+}}, loaded [symbolic = @StdOptional.%StdOptional.val (constants.%StdOptional.val.551)]
// CHECK:STDOUT:   %optional.has_value.cpp_overload_set.value: %optional.has_value.cpp_overload_set.type = cpp_overload_set_value @optional.has_value.cpp_overload_set [concrete = constants.%optional.has_value.cpp_overload_set.value]
// CHECK:STDOUT:   %has_value__carbon_thunk.decl: %has_value__carbon_thunk.type = fn_decl @has_value__carbon_thunk [concrete = constants.%has_value__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %optional.value.cpp_overload_set.value: %optional.value.cpp_overload_set.type = cpp_overload_set_value @optional.value.cpp_overload_set [concrete = constants.%optional.value.cpp_overload_set.value]
// CHECK:STDOUT:   %value__carbon_thunk.decl: %value__carbon_thunk.type = fn_decl @value__carbon_thunk [concrete = constants.%value__carbon_thunk] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.ImplicitAs: %ImplicitAs.type.0ff = import_ref Core//prelude/operators/as, ImplicitAs, loaded [concrete = constants.%ImplicitAs.generic]
// CHECK:STDOUT:   %Core.import_ref.a74: @const.as.ImplicitAs.impl.%const.as.ImplicitAs.impl.Convert.type (%const.as.ImplicitAs.impl.Convert.type.f7e) = import_ref Core//prelude/types/int, inst{{[0-9A-F]+}} [indirect], loaded [symbolic = @const.as.ImplicitAs.impl.%const.as.ImplicitAs.impl.Convert (constants.%const.as.ImplicitAs.impl.Convert.2f7)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.5de = impl_witness_table (%Core.import_ref.a74), @const.as.ImplicitAs.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.eb9: @U.as_type.as.ImplicitAs.impl.167.%U.as_type.as.ImplicitAs.impl.Convert.type (%U.as_type.as.ImplicitAs.impl.Convert.type.ad5) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @U.as_type.as.ImplicitAs.impl.167.%U.as_type.as.ImplicitAs.impl.Convert (constants.%U.as_type.as.ImplicitAs.impl.Convert.331)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.bb5 = impl_witness_table (%Core.import_ref.eb9), @U.as_type.as.ImplicitAs.impl.167 [concrete]
// CHECK:STDOUT:   %Core.import_ref.017d8: @T.as_type.as.OptionalAs.impl.%T.as_type.as.OptionalAs.impl.Convert.type (%T.as_type.as.OptionalAs.impl.Convert.type.774) = import_ref Core//prelude/types/optional, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.OptionalAs.impl.%T.as_type.as.OptionalAs.impl.Convert (constants.%T.as_type.as.OptionalAs.impl.Convert.5f9)]
// CHECK:STDOUT:   %OptionalAs.impl_witness_table.2e9 = impl_witness_table (%Core.import_ref.017d8), @T.as_type.as.OptionalAs.impl [concrete]
// CHECK:STDOUT:   %Core.Destroy: type = import_ref Core//prelude/destroy, Destroy, loaded [concrete = constants.%Destroy.type]
// CHECK:STDOUT:   %Core.Copy.e5d: type = import_ref Core//prelude/copy, Copy, loaded [concrete = constants.%Copy.type]
// CHECK:STDOUT:   %optional.cpp_destructor.decl: %optional.cpp_destructor.type = fn_decl @optional.cpp_destructor [concrete = constants.%optional.cpp_destructor] {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.EqWith: %EqWith.type.f77 = import_ref Core//prelude/operators/comparison, EqWith, loaded [concrete = constants.%EqWith.generic]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.9c34: %bool.as.Copy.impl.Op.type = import_ref Core//prelude/copy, loc{{\d+_\d+}}, loaded [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %Copy.impl_witness_table.bda = impl_witness_table (%Core.import_ref.9c34), @bool.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc11_28.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.59d = ref_param_pattern [concrete = constants.%self.param_patt.9e1]
// CHECK:STDOUT:     %self.patt: %pattern_type.59d = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.8da]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.0f8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.0f8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc11_28.1 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.59d = ref_param_pattern [concrete = constants.%self.param_patt.9e1]
// CHECK:STDOUT:     %self.patt: %pattern_type.59d = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.8da]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.0f8 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.0f8 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc11_28.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6db = ref_param_pattern [concrete = constants.%self.param_patt.e99]
// CHECK:STDOUT:     %self.patt: %pattern_type.6db = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e88]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %MaybeUnformed.729 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %MaybeUnformed.729 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc11_28.2 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6db = ref_param_pattern [concrete = constants.%self.param_patt.e99]
// CHECK:STDOUT:     %self.patt: %pattern_type.6db = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.e88]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %MaybeUnformed.729 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %MaybeUnformed.729 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc11_28.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc11_28.3 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.ef8 = ref_param_pattern [concrete = constants.%self.param_patt.d96]
// CHECK:STDOUT:     %self.patt: %pattern_type.ef8 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.77d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %Optional.5b3 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %Optional.5b3 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc11_28.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc11_28.4 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.831 = ref_param_pattern [concrete = constants.%self.param_patt.40d]
// CHECK:STDOUT:     %self.patt: %pattern_type.831 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.560]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref bool = ref_param call_param0
// CHECK:STDOUT:     %self: ref bool = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc11_27 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.dd2 = ref_param_pattern [concrete = constants.%self.param_patt.09e]
// CHECK:STDOUT:     %self.patt: %pattern_type.dd2 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.f07]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %optional = ref_param call_param0
// CHECK:STDOUT:     %self: ref %optional = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %P.decl: %P.type = fn_decl @P [concrete = constants.%P] {
// CHECK:STDOUT:     %n.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%n.param_patt]
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = wrapper_binding_pattern n, %n.param_patt [concrete = constants.%n.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.831 = out_param_pattern [concrete = constants.%return.param_patt.5a1]
// CHECK:STDOUT:     %return.patt: %pattern_type.831 = return_slot_pattern %return.param_patt, %.loc10_17.1 [concrete = constants.%return.patt.c0c]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %.loc10_17.1: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %.loc10_17.2: Core.Form = init_form %.loc10_17.1 [concrete = constants.%.f34]
// CHECK:STDOUT:     %n.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %n: %i32 = wrapper_binding n, %n.param
// CHECK:STDOUT:     %return.param: ref bool = out_param call_param1
// CHECK:STDOUT:     %return: ref bool = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @P(%n.param: %i32) -> out %return.param: bool {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Cpp.ref: <namespace> = name_ref Cpp, imports.%Cpp [concrete = imports.%Cpp]
// CHECK:STDOUT:   %MakePointer.ref: %MakePointer.cpp_overload_set.type = name_ref MakePointer, imports.%MakePointer.cpp_overload_set.value [concrete = constants.%MakePointer.cpp_overload_set.value]
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %.loc11_27.1: ref %optional = temporary_storage
// CHECK:STDOUT:   %addr.loc11_27: %ptr.f7e = addr_of %.loc11_27.1
// CHECK:STDOUT:   %MakePointer__carbon_thunk.call: init %empty_tuple.type = call imports.%MakePointer__carbon_thunk.decl(%n.ref, %addr.loc11_27)
// CHECK:STDOUT:   %.loc11_27.2: init %optional to %.loc11_27.1 = mark_in_place_init %MakePointer__carbon_thunk.call
// CHECK:STDOUT:   %.loc11_27.3: ref %optional = temporary %.loc11_27.1, %.loc11_27.2
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %OptionalStorage.facet.loc11: %OptionalStorage.type = facet_value constants.%ptr.d08, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet.f91]
// CHECK:STDOUT:   %.loc11_28.1: %OptionalStorage.type = converted constants.%ptr.d08, %OptionalStorage.facet.loc11 [concrete = constants.%OptionalStorage.facet.f91]
// CHECK:STDOUT:   %Optional.loc11: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.f91) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   %StdOptional.ref: %StdOptional.type = name_ref StdOptional, imports.%Core.StdOptional [concrete = constants.%StdOptional.generic]
// CHECK:STDOUT:   %StdOptional: type = class_type @StdOptional, @StdOptional(constants.%Optional.5b3) [concrete = constants.%StdOptional.0b2]
// CHECK:STDOUT:   %.loc11_27.4: %optional = acquire_value %.loc11_27.3
// CHECK:STDOUT:   %.loc11_28.2: ref %StdOptional.0b2 = temporary_storage
// CHECK:STDOUT:   %has_value.ref: %optional.has_value.cpp_overload_set.type = name_ref has_value, imports.%optional.has_value.cpp_overload_set.value [concrete = constants.%optional.has_value.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc11_28.1: <bound method> = bound_method %.loc11_27.4, %has_value.ref
// CHECK:STDOUT:   %.loc11_28.3: ref bool = temporary_storage
// CHECK:STDOUT:   %addr.loc11_28: %ptr.bb2 = addr_of %.loc11_28.3
// CHECK:STDOUT:   %has_value__carbon_thunk.call: init %empty_tuple.type = call imports.%has_value__carbon_thunk.decl(%.loc11_27.4, %addr.loc11_28)
// CHECK:STDOUT:   %.loc11_28.4: init bool to %.loc11_28.3 = mark_in_place_init %has_value__carbon_thunk.call
// CHECK:STDOUT:   %.loc11_28.5: ref bool = temporary %.loc11_28.3, %.loc11_28.4
// CHECK:STDOUT:   %.loc11_28.6: bool = acquire_value %.loc11_28.5
// CHECK:STDOUT:   if %.loc11_28.6 br !.loc11_28.1 else br !.loc11_28.2
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc11_28.1:
// CHECK:STDOUT:   %value.ref: %optional.value.cpp_overload_set.type = name_ref value, imports.%optional.value.cpp_overload_set.value [concrete = constants.%optional.value.cpp_overload_set.value]
// CHECK:STDOUT:   %bound_method.loc11_28.2: <bound method> = bound_method %.loc11_27.4, %value.ref
// CHECK:STDOUT:   %value__carbon_thunk.call: ref %const.e2a = call imports.%value__carbon_thunk.decl(%.loc11_27.4)
// CHECK:STDOUT:   %.loc11_28.7: %StdOptional.Some.type.27e = specific_constant imports.%Core.import_ref.b1b, @StdOptional(constants.%Optional.5b3) [concrete = constants.%StdOptional.Some.dee]
// CHECK:STDOUT:   %Some.ref: %StdOptional.Some.type.27e = name_ref Some, %.loc11_28.7 [concrete = constants.%StdOptional.Some.dee]
// CHECK:STDOUT:   %StdOptional.Some.specific_fn: <specific function> = specific_function %Some.ref, @StdOptional.Some(constants.%Optional.5b3) [concrete = constants.%StdOptional.Some.specific_fn]
// CHECK:STDOUT:   %.loc11_28.8: ref %StdOptional.0b2 = splice_block %.loc11_28.2 {}
// CHECK:STDOUT:   %impl.elem0.loc11_28.1: %.4a8 = impl_witness_access constants.%ImplicitAs.impl_witness.c34, element0 [concrete = constants.%const.as.ImplicitAs.impl.Convert.1e3]
// CHECK:STDOUT:   %bound_method.loc11_28.3: <bound method> = bound_method %value__carbon_thunk.call, %impl.elem0.loc11_28.1
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11_28.1, @const.as.ImplicitAs.impl.Convert(constants.%Optional.5b3, constants.%ImplicitAs.facet.ea2) [concrete = constants.%const.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_28.4: <bound method> = bound_method %value__carbon_thunk.call, %specific_fn.loc11
// CHECK:STDOUT:   %.loc11_28.9: %const.e2a = acquire_value %value__carbon_thunk.call
// CHECK:STDOUT:   %const.as.ImplicitAs.impl.Convert.call: init %Optional.5b3 = call %bound_method.loc11_28.4(%.loc11_28.9)
// CHECK:STDOUT:   %.loc11_28.10: init %Optional.5b3 = converted %value__carbon_thunk.call, %const.as.ImplicitAs.impl.Convert.call
// CHECK:STDOUT:   %.loc11_28.11: ref %Optional.5b3 = temporary_storage
// CHECK:STDOUT:   %.loc11_28.12: ref %Optional.5b3 = temporary %.loc11_28.11, %.loc11_28.10
// CHECK:STDOUT:   %.loc11_28.13: %Optional.5b3 = acquire_value %.loc11_28.12
// CHECK:STDOUT:   %StdOptional.Some.call: init %StdOptional.0b2 to %.loc11_28.8 = call %StdOptional.Some.specific_fn(%.loc11_28.13)
// CHECK:STDOUT:   assign %.loc11_28.2, %StdOptional.Some.call
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc11_28.1: <bound method> = bound_method %.loc11_28.12, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc11_28.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc11_28.1(%.loc11_28.12)
// CHECK:STDOUT:   br !.loc11_28.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc11_28.2:
// CHECK:STDOUT:   %.loc11_28.14: %StdOptional.0b2 = specific_constant imports.%Core.import_ref.e46, @StdOptional(constants.%Optional.5b3) [concrete = constants.%StdOptional.val.d23]
// CHECK:STDOUT:   %None.ref.loc11: %StdOptional.0b2 = name_ref None, %.loc11_28.14 [concrete = constants.%StdOptional.val.d23]
// CHECK:STDOUT:   <elided>
// CHECK:STDOUT:   %impl.elem0.loc11_28.2: %.119 = impl_witness_access constants.%custom_witness.bab, element0 [concrete = constants.%Copy.WithSelf.Op.416]
// CHECK:STDOUT:   %bound_method.loc11_28.5: <bound method> = bound_method %None.ref.loc11, %impl.elem0.loc11_28.2 [concrete = constants.%Copy.WithSelf.Op.bound]
// CHECK:STDOUT:   %.loc11_28.15: ref %StdOptional.0b2 = splice_block %.loc11_28.2 {}
// CHECK:STDOUT:   %Copy.WithSelf.Op.call: init %StdOptional.0b2 to %.loc11_28.15 = call %bound_method.loc11_28.5(%None.ref.loc11) [concrete = constants.%StdOptional.val.d23]
// CHECK:STDOUT:   assign %.loc11_28.2, %Copy.WithSelf.Op.call
// CHECK:STDOUT:   br !.loc11_28.3
// CHECK:STDOUT:
// CHECK:STDOUT: !.loc11_28.3:
// CHECK:STDOUT:   %.loc11_28.16: %StdOptional.0b2 = acquire_value %.loc11_28.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc11_28.2: <bound method> = bound_method %.loc11_28.5, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.5
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc11_28.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc11_28.2(%.loc11_28.5)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc11_27: <bound method> = bound_method %.loc11_27.3, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc11_27: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc11_27(%.loc11_27.3)
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %p.patt: %pattern_type.ef8 = value_binding_pattern p [concrete = constants.%p.patt]
// CHECK:STDOUT:     %.loc12_17: %pattern_type.26e = tuple_pattern (%p.patt) [concrete = constants.%.f12]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_40.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc12_40.1: <bound method> = bound_method %int_0, %impl.elem0.loc12_40.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc12_40.1: <specific function> = specific_function %impl.elem0.loc12_40.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_40.2: <bound method> = bound_method %int_0, %specific_fn.loc12_40.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %u1 = call %bound_method.loc12_40.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_40.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_40.2: %u1 = converted %int_0, %.loc12_40.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_40.3: ref %u1 = class_element_access %.loc11_28.16, element0
// CHECK:STDOUT:   %impl.elem0.loc12_40.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc12_40.3: <bound method> = bound_method %.loc12_40.2, %impl.elem0.loc12_40.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.f34]
// CHECK:STDOUT:   %specific_fn.loc12_40.2: <specific function> = specific_function %impl.elem0.loc12_40.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc12_40.4: <bound method> = bound_method %.loc12_40.2, %specific_fn.loc12_40.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc12_40.4: %u1 = acquire_value %.loc12_40.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc12: init bool = call %bound_method.loc12_40.4(%.loc12_40.2, %.loc12_40.4)
// CHECK:STDOUT:   %.loc12_40.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc12
// CHECK:STDOUT:   %.loc12_40.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc12, %.loc12_40.5
// CHECK:STDOUT:   if %.loc12_40.6 br !match.case.then.loc12 else br !match.case.else.loc12
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc12:
// CHECK:STDOUT:   %.loc12_40.7: ref %.851 = class_element_access %.loc11_28.16, element1
// CHECK:STDOUT:   %.loc12_40.8: ref %tuple.type.e2f = class_element_access %.loc12_40.7, element0
// CHECK:STDOUT:   %tuple.elem0: ref %Optional.5b3 = tuple_access %.loc12_40.8, element0
// CHECK:STDOUT:   %.loc12_40.9: %Optional.5b3 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %.loc12_37.1: type = splice_block %Optional.loc12 [concrete = constants.%Optional.5b3] {
// CHECK:STDOUT:     %Core.ref: <namespace> = name_ref Core, imports.%Core [concrete = imports.%Core]
// CHECK:STDOUT:     %Optional.ref: %Optional.type = name_ref Optional, imports.%Core.Optional [concrete = constants.%Optional.generic]
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %ptr: type = ptr_type %i32.loc12 [concrete = constants.%ptr.d08]
// CHECK:STDOUT:     %OptionalStorage.facet.loc12: %OptionalStorage.type = facet_value %ptr, (constants.%OptionalStorage.impl_witness.0ce) [concrete = constants.%OptionalStorage.facet.f91]
// CHECK:STDOUT:     %.loc12_37.2: %OptionalStorage.type = converted %ptr, %OptionalStorage.facet.loc12 [concrete = constants.%OptionalStorage.facet.f91]
// CHECK:STDOUT:     %Optional.loc12: type = class_type @Optional, @Optional(constants.%OptionalStorage.facet.f91) [concrete = constants.%Optional.5b3]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %p: %Optional.5b3 = wrapper_binding p, %.loc12_40.9
// CHECK:STDOUT:   %p.ref: %Optional.5b3 = name_ref p, %p
// CHECK:STDOUT:   %.loc13: %Optional.HasValue.type.c62 = specific_constant imports.%Core.import_ref.729, @Optional(constants.%OptionalStorage.facet.f91) [concrete = constants.%Optional.HasValue.84d]
// CHECK:STDOUT:   %HasValue.ref: %Optional.HasValue.type.c62 = name_ref HasValue, %.loc13 [concrete = constants.%Optional.HasValue.84d]
// CHECK:STDOUT:   %Optional.HasValue.bound: <bound method> = bound_method %p.ref, %HasValue.ref
// CHECK:STDOUT:   %Optional.HasValue.specific_fn: <specific function> = specific_function %HasValue.ref, @Optional.HasValue(constants.%OptionalStorage.facet.f91) [concrete = constants.%Optional.HasValue.specific_fn.3e1]
// CHECK:STDOUT:   %bound_method.loc13: <bound method> = bound_method %p.ref, %Optional.HasValue.specific_fn
// CHECK:STDOUT:   %Optional.HasValue.call: init bool = call %bound_method.loc13(%p.ref)
// CHECK:STDOUT:   return %Optional.HasValue.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc12:
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.f20 = expr_pattern %None.ref.loc15 in [concrete] {
// CHECK:STDOUT:       %.loc15_10.2: %StdOptional.0b2 = specific_constant imports.%Core.import_ref.e46, @StdOptional(constants.%Optional.5b3) [concrete = constants.%StdOptional.val.d23]
// CHECK:STDOUT:       %None.ref.loc15: %StdOptional.0b2 = name_ref None, %.loc15_10.2 [concrete = constants.%StdOptional.val.d23]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %.loc15_10.1: %StdOptional.0b2 = splice_block %None.ref.loc15 [concrete = constants.%StdOptional.val.d23] {
// CHECK:STDOUT:     %.loc15_10.2: %StdOptional.0b2 = specific_constant imports.%Core.import_ref.e46, @StdOptional(constants.%Optional.5b3) [concrete = constants.%StdOptional.val.d23]
// CHECK:STDOUT:     %None.ref.loc15: %StdOptional.0b2 = name_ref None, %.loc15_10.2 [concrete = constants.%StdOptional.val.d23]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc15_16.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc15_16.1: <bound method> = bound_method %int_1, %impl.elem0.loc15_16.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc15_16.1: <specific function> = specific_function %impl.elem0.loc15_16.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_16.2: <bound method> = bound_method %int_1, %specific_fn.loc15_16.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15: init %u1 = call %bound_method.loc15_16.2(%int_1) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_16.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc15 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_16.2: %u1 = converted %int_1, %.loc15_16.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc15_16.3: ref %u1 = class_element_access %.loc11_28.16, element0
// CHECK:STDOUT:   %impl.elem0.loc15_16.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc15_16.3: <bound method> = bound_method %.loc15_16.2, %impl.elem0.loc15_16.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound.22c]
// CHECK:STDOUT:   %specific_fn.loc15_16.2: <specific function> = specific_function %impl.elem0.loc15_16.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc15_16.4: <bound method> = bound_method %.loc15_16.2, %specific_fn.loc15_16.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc15_16.4: %u1 = acquire_value %.loc15_16.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc15: init bool = call %bound_method.loc15_16.4(%.loc15_16.2, %.loc15_16.4)
// CHECK:STDOUT:   %.loc15_16.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc15
// CHECK:STDOUT:   %.loc15_16.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc15, %.loc15_16.5
// CHECK:STDOUT:   if %.loc15_16.6 br !match.case.then.loc15 else br !match.case.else.loc15
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then.loc15:
// CHECK:STDOUT:   %false.loc16: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc16: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc16: <bound method> = bound_method %false.loc16, %impl.elem0.loc16 [concrete = constants.%bool.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call.loc16: init bool = call %bound_method.loc16(%false.loc16) [concrete = constants.%false]
// CHECK:STDOUT:   return %bool.as.Copy.impl.Op.call.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else.loc15:
// CHECK:STDOUT:   br !match.done
// CHECK:STDOUT:
// CHECK:STDOUT: !match.done:
// CHECK:STDOUT:   %false.loc19: bool = bool_literal false [concrete = constants.%false]
// CHECK:STDOUT:   %impl.elem0.loc19: %.e28 = impl_witness_access constants.%Copy.impl_witness.5e1, element0 [concrete = constants.%bool.as.Copy.impl.Op]
// CHECK:STDOUT:   %bound_method.loc19: <bound method> = bound_method %false.loc19, %impl.elem0.loc19 [concrete = constants.%bool.as.Copy.impl.Op.bound]
// CHECK:STDOUT:   %bool.as.Copy.impl.Op.call.loc19: init bool = call %bound_method.loc19(%false.loc19) [concrete = constants.%false]
// CHECK:STDOUT:   return %bool.as.Copy.impl.Op.call.loc19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc11_28.1(%self.param: ref %.0f8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc11_28.1(%self.param: ref %.0f8) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc11_28.1(%self.param: ref %.0f8) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc11_28.2(%self.param: ref %MaybeUnformed.729) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc11_28.2(%self.param: ref %MaybeUnformed.729) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc11_28.2(%self.param: ref %MaybeUnformed.729) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc11_28.3(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc11_28.3(%self.param: ref %Optional.5b3) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc11_28.3(%self.param: ref %Optional.5b3) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc11_28.4(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc11_28.4(%self.param: ref bool) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc11_28.4(%self.param: ref bool) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc11_27(%self.param: ref %optional) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc11_27(%self.param: ref %optional) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %optional.cpp_destructor.call: init %empty_tuple.type = call imports.%optional.cpp_destructor.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
