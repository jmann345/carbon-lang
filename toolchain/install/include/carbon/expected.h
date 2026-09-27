// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// `Carbon::expected<T, E>`: the C++ view of an exported Carbon function's
// `Core.Result(T, E)` return type, and `Carbon::Exception`: the C++ view of
// `Cpp.Exception` (docs/design/error_handling.md, "Exporting fallible Carbon
// functions: `Carbon::expected`"; decisions F-006h, D7, D8).
//
// This header requires only C++17 and is installed at
// `<install root>/include/carbon/expected.h`, which the Carbon toolchain adds
// to the system include path of every C++ translation unit it compiles. A C++
// consumer of an exported `fn F(...) -> Core.Result(T, E)` writes
//
//   #include <carbon/expected.h>
//   Carbon::expected<T', E'> r = Carbon::F(...);
//   if (r) { use(r.value()); } else { handle(r.error()); }
//
// LAYOUT CONTRACT. The class mirrors the object representation of the Carbon
// choice `Result(T, E)` byte for byte, so the Carbon side writes its `Result`
// object straight into a `Carbon::expected` return object: no conversion runs
// at the boundary. Carbon lowers a two-alternative choice as
//
//   <{ <{ i1, [A-1 x i8] }>, [P x i8] }>
//
// (toolchain/lower/testdata/choice/payload_layout.carbon): a one-byte
// discriminant, 0 for `Ok` and 1 for `Err` (the declaration order in
// core/prelude/types/result.carbon), padded to the payload alignment A, then
// the max-of-fields payload region of size P with every alternative's payload
// at offset zero. Here `disc_` is that byte and `payload_` — a union of `T` and
// `E` at offset `alignof(union)` — is the region. Every payload type Carbon
// admits in 0.1 is a scalar (int, float, bool, pointer, or an adapter over one;
// the SF-6 choice-payload bound), for which P == sizeof(union) and A ==
// alignof(union); the static assertions in `expected` pin exactly that, and
// fail loudly if a future payload widening breaks the mirror.
//
// `Carbon::Exception` wraps the Itanium primary exception object pointer that
// `Cpp.Exception` holds (captured by `__cxa_current_primary_exception` inside
// the catching thunk, with its refcount incremented; libc++abi's
// `std::exception_ptr` is exactly that pointer). `ptr()` reconstitutes a real
// `std::exception_ptr` losslessly and `rethrow()` rethrows the original object
// with its dynamic type. A FOREIGN exception (one not thrown by the C++
// runtime) has no primary object: `__cxa_current_primary_exception` returns
// NULL for it, so `ptr()` returns an EMPTY `std::exception_ptr` and `rethrow()`
// calls `std::terminate()`; `has_value()` on the `expected` is unaffected (the
// discriminant is `Err` regardless).
//
// LINKING NOTE (Apple platforms): libc++ on Apple platforms does not re-export
// `__cxa_rethrow_primary_exception` (libcxxabi/lib/symbols-not-reexported.exp),
// so a C++ translation unit that calls `Exception::ptr()` or
// `Exception::rethrow()` must be linked with `-lc++abi` there. On Linux the
// symbol comes with libc++.
//
// The `ptr()`/`rethrow()` members exist only when the including translation
// unit is compiled with exceptions enabled; the class layout and the rest of
// the API are available in `-fno-exceptions` builds too, which is what keeps
// the export mapping identical under `--cpp-exceptions=none`.

#ifndef CARBON_TOOLCHAIN_INSTALL_INCLUDE_CARBON_EXPECTED_H_
#define CARBON_TOOLCHAIN_INSTALL_INCLUDE_CARBON_EXPECTED_H_

#include <cstddef>
#include <exception>
#include <type_traits>
#include <utility>

#if defined(__cpp_exceptions) || defined(__EXCEPTIONS)
#include <cxxabi.h>
#define CARBON_EXPECTED_HAS_EXCEPTIONS 1
#else
#define CARBON_EXPECTED_HAS_EXCEPTIONS 0
#endif

#if __cplusplus >= 202302L && defined(__has_include)
#if __has_include(<expected>)
#include <expected>
#endif
#endif

namespace Carbon {

// The C++ view of `Cpp.Exception`: the primary exception object pointer, or
// null for a foreign exception (see the header comment).
struct Exception {
  void* primary_;

  // Whether a C++ exception object is held.
  constexpr bool has_exception() const { return primary_ != nullptr; }

#if CARBON_EXPECTED_HAS_EXCEPTIONS
  // The held exception as a `std::exception_ptr`, or an empty pointer for a
  // foreign exception. Rethrowing the primary object and catching it is the
  // documented way to obtain an `exception_ptr` for it; libc++abi increments
  // the object's refcount on rethrow, so the pointer held here stays valid.
  std::exception_ptr ptr() const {
    if (primary_ == nullptr) {
      return std::exception_ptr();
    }
    try {
      __cxxabiv1::__cxa_rethrow_primary_exception(primary_);
    } catch (...) {
      return std::current_exception();
    }
    // Not reached: a non-null primary object is always rethrown above.
    return std::exception_ptr();
  }

  // Rethrows the held exception object with its original dynamic type.
  // `std::terminate()` for a foreign exception, which has no object to
  // rethrow (`__cxa_rethrow_primary_exception(nullptr)` is a no-op).
  [[noreturn]] void rethrow() const {
    if (primary_ != nullptr) {
      __cxxabiv1::__cxa_rethrow_primary_exception(primary_);
    }
    std::terminate();
  }
#endif

  friend constexpr bool operator==(Exception lhs, Exception rhs) {
    return lhs.primary_ == rhs.primary_;
  }
  friend constexpr bool operator!=(Exception lhs, Exception rhs) {
    return !(lhs == rhs);
  }
};

static_assert(std::is_trivially_copyable<Exception>::value &&
                  sizeof(Exception) == sizeof(void*),
              "Carbon::Exception must mirror `Cpp.Exception`'s pointer");

// An error value for constructing an `expected` in its `Err` alternative from
// C++: `Carbon::expected<int, int> r = Carbon::unexpected<int>(-1);`.
template <typename E>
class unexpected {
 public:
  constexpr explicit unexpected(E error) : error_(error) {}
  constexpr const E& error() const { return error_; }

 private:
  E error_;
};

namespace expected_internal {

// The payload region: `Ok` and `Err` payloads at offset zero, sized and
// aligned by the wider alternative, exactly as Carbon's max-of-fields region.
template <typename T, typename E>
union Payload {
  // Trivial: leaves the region indeterminate, as a Carbon return slot is
  // before the callee writes it.
  Payload() = default;
  constexpr explicit Payload(T value) : ok(value) {}
  constexpr Payload(unexpected<E> error, int /*tag*/) : err(error.error()) {}
  T ok;
  E err;
};

template <typename E>
union Payload<void, E> {
  Payload() = default;
  constexpr Payload(unexpected<E> error, int /*tag*/) : err(error.error()) {}
  E err;
};

template <typename T>
struct PayloadTypeCheck {
  static_assert(std::is_trivially_copyable<T>::value &&
                    std::is_trivially_destructible<T>::value,
                "a Carbon::expected payload type must be trivially copyable "
                "and trivially destructible in 0.1 (docs/design/"
                "error_handling.md, \"Exporting fallible Carbon functions\")");
  static constexpr bool value = true;
};

template <>
struct PayloadTypeCheck<void> {
  static constexpr bool value = true;
};

}  // namespace expected_internal

// The C++ view of `Core.Result(T, E)`. `T` is `void` for `Core.Result((), E)`.
template <typename T, typename E>
class expected {
  static_assert(expected_internal::PayloadTypeCheck<T>::value &&
                    expected_internal::PayloadTypeCheck<E>::value,
                "unsupported Carbon::expected payload types");
  using Payload = expected_internal::Payload<T, E>;

 public:
  using value_type = T;
  using error_type = E;
  using unexpected_type = unexpected<E>;

  // Leaves the object indeterminate: this is the return slot shape the Carbon
  // thunk writes into.
  expected() = default;

  // `Ok(value)`.
  constexpr expected(T value) : disc_(0), payload_(value) { CheckLayout(); }
  // `Err(error)`.
  constexpr expected(unexpected<E> error) : disc_(1), payload_(error, 0) {
    CheckLayout();
  }

  constexpr bool has_value() const {
    CheckLayout();
    return disc_ == 0;
  }
  constexpr explicit operator bool() const { return has_value(); }

  // Precondition: `has_value()`. Unlike `std::expected::value()`, this never
  // throws: the header is usable with exceptions disabled.
  constexpr const T& value() const { return payload_.ok; }
  constexpr T& value() { return payload_.ok; }
  constexpr const T& operator*() const { return payload_.ok; }
  constexpr T& operator*() { return payload_.ok; }

  // Precondition: `!has_value()`.
  constexpr const E& error() const { return payload_.err; }
  constexpr E& error() { return payload_.err; }

  template <typename U>
  constexpr T value_or(U&& default_value) const {
    return has_value() ? payload_.ok
                       : static_cast<T>(std::forward<U>(default_value));
  }

  friend constexpr bool operator==(const expected& lhs, const expected& rhs) {
    if (lhs.disc_ != rhs.disc_) {
      return false;
    }
    return lhs.has_value() ? lhs.payload_.ok == rhs.payload_.ok
                           : lhs.payload_.err == rhs.payload_.err;
  }
  friend constexpr bool operator!=(const expected& lhs, const expected& rhs) {
    return !(lhs == rhs);
  }

#if defined(__cpp_lib_expected)
  // Conversions to and from the C++23 standard type.
  expected(const std::expected<T, E>& other)
      : disc_(other.has_value() ? 0 : 1), payload_() {
    if (other.has_value()) {
      payload_.ok = *other;
    } else {
      payload_.err = other.error();
    }
  }
  operator std::expected<T, E>() const {
    if (has_value()) {
      return std::expected<T, E>(payload_.ok);
    }
    return std::expected<T, E>(std::unexpected<E>(payload_.err));
  }
#endif

 private:
  // Pins the layout mirror described in the header comment.
  static constexpr void CheckLayout() {
    static_assert(offsetof(expected, payload_) == alignof(Payload),
                  "payload region must follow the discriminant byte padded to "
                  "the payload alignment");
    static_assert(sizeof(expected) == alignof(Payload) + sizeof(Payload),
                  "Carbon::expected must be exactly the discriminant padding "
                  "plus the payload region");
    static_assert(std::is_trivially_copyable<expected>::value,
                  "Carbon::expected must be trivially copyable");
  }

  // 0 = Ok, 1 = Err: Carbon's alternative declaration order.
  unsigned char disc_;
  Payload payload_;
};

// The `Core.Result((), E)` view: no `Ok` payload.
template <typename E>
class expected<void, E> {
  static_assert(expected_internal::PayloadTypeCheck<E>::value,
                "unsupported Carbon::expected payload types");
  using Payload = expected_internal::Payload<void, E>;

 public:
  using value_type = void;
  using error_type = E;
  using unexpected_type = unexpected<E>;

  expected() = default;

  // `Ok(())`.
  static expected ok() {
    expected result;
    result.disc_ = 0;
    return result;
  }
  // `Err(error)`.
  constexpr expected(unexpected<E> error) : disc_(1), payload_(error, 0) {
    CheckLayout();
  }

  constexpr bool has_value() const {
    CheckLayout();
    return disc_ == 0;
  }
  constexpr explicit operator bool() const { return has_value(); }
  constexpr void value() const {}

  // Precondition: `!has_value()`.
  constexpr const E& error() const { return payload_.err; }
  constexpr E& error() { return payload_.err; }

  friend constexpr bool operator==(const expected& lhs, const expected& rhs) {
    if (lhs.disc_ != rhs.disc_) {
      return false;
    }
    return lhs.has_value() || lhs.payload_.err == rhs.payload_.err;
  }
  friend constexpr bool operator!=(const expected& lhs, const expected& rhs) {
    return !(lhs == rhs);
  }

#if defined(__cpp_lib_expected)
  expected(const std::expected<void, E>& other)
      : disc_(other.has_value() ? 0 : 1), payload_() {
    if (!other.has_value()) {
      payload_.err = other.error();
    }
  }
  operator std::expected<void, E>() const {
    if (has_value()) {
      return std::expected<void, E>();
    }
    return std::expected<void, E>(std::unexpected<E>(payload_.err));
  }
#endif

 private:
  static constexpr void CheckLayout() {
    static_assert(offsetof(expected, payload_) == alignof(Payload),
                  "payload region must follow the discriminant byte padded to "
                  "the payload alignment");
    static_assert(sizeof(expected) == alignof(Payload) + sizeof(Payload),
                  "Carbon::expected must be exactly the discriminant padding "
                  "plus the payload region");
    static_assert(std::is_trivially_copyable<expected>::value,
                  "Carbon::expected must be trivially copyable");
  }

  unsigned char disc_;
  Payload payload_;
};

}  // namespace Carbon

#endif  // CARBON_TOOLCHAIN_INSTALL_INCLUDE_CARBON_EXPECTED_H_
