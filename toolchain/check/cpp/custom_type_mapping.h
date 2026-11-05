// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_CPP_CUSTOM_TYPE_MAPPING_H_
#define CARBON_TOOLCHAIN_CHECK_CPP_CUSTOM_TYPE_MAPPING_H_

#include "clang/AST/DeclCXX.h"
#include "clang/AST/Type.h"
#include "llvm/ADT/SmallVector.h"

namespace Carbon::Check {

// A Carbon type that has a custom mapping from C++, together with the payload
// the mapping needs. A struct rather than a bare enum so that a mapping can
// carry a type argument (fork/slices/plan.md §1.B.1: `std::span<T>` maps to
// `Core.Slice(T')`, which needs `T`).
struct CustomCppTypeMapping {
  enum Kind : uint8_t {
    // None.
    None,

    // The Carbon `Str` type, which maps to `std::string_view`.
    Str,

    // The Carbon `Core.Slice(T')` type, which maps to the dynamic-extent
    // `std::span<T>`. `element_type` is `T`.
    Span,
  };

  Kind kind = None;
  // For `Span`: the C++ element type `T` of `std::span<T>`.
  clang::QualType element_type;
};

// Determines whether record_decl is a C++ class that has a custom mapping into
// Carbon, and if so, returns the corresponding Carbon type. Otherwise returns
// a mapping whose kind is `None`.
auto GetCustomCppTypeMapping(const clang::CXXRecordDecl* record_decl)
    -> CustomCppTypeMapping;

// A C++ sum type that maps by value to a Carbon `choice`
// (docs/design/sum_types.md, "C++ `std::optional` and `std::variant`"): the
// C++ class stays imported as a class, and its alternatives are listed here in
// C++ order -- `std::optional<T>` has the single `T` (its `Some` alternative;
// `None` carries nothing), `std::variant<Ts...>` has `Ts...`.
struct CppSumTypeMapping {
  enum Kind : uint8_t {
    None,
    // A `std::optional<T>` specialization.
    Optional,
    // A `std::variant<Ts...>` specialization.
    Variant,
  };

  Kind kind = None;
  // The C++ alternative types, in C++ order.
  llvm::SmallVector<clang::QualType, 4> alternative_types;
};

// Determines whether `record_decl` is a `std::optional` or `std::variant`
// specialization, and if so returns its alternatives.
auto GetCppSumTypeMapping(const clang::CXXRecordDecl* record_decl)
    -> CppSumTypeMapping;

// Returns whether `type` is the unqualified `std::monostate`.
auto IsStdMonostate(clang::QualType type) -> bool;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_CPP_CUSTOM_TYPE_MAPPING_H_
