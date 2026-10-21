// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/std_sum_types.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/std_sum_types.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1, F-020): the conversions as
// LLVM IR: the C++ object keeps libc++'s layout in its own alloca and is read
// only through the accessor thunks; the Carbon sum type is a separate alloca
// of the `choice` layout (`<{ <{ i1, [3 x i8] }>, [4 x i8] }>` for
// `StdOptional(i32)`), written by `Some`'s constructor or the `None`
// constant's copy; the reverse builds the C++ object by its default
// constructor and `emplace`.

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

inline auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) return std::optional<int>(n);
  return std::optional<int>();
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

inline auto Take(std::optional<int> o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto TakeVariant(std::variant<int, double> v) -> int {
  return static_cast<int>(v.index());
}

// --- optional.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

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

fn G(n: i32) -> i32 {
  return Cpp.Take(Core.CppCompat.StdOptional(i32).Some(n));
}

// --- variant.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn H(n: i32) -> i32 {
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

fn K(d: f64) -> i32 {
  return Cpp.TakeVariant(Core.CppCompat.StdVariant2(i32, f64).Alt1(d));
}

