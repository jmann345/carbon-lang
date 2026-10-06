// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_CPP_CUSTOM_TYPE_MAPPING_H_
#define CARBON_TOOLCHAIN_CHECK_CPP_CUSTOM_TYPE_MAPPING_H_

#include "clang/AST/DeclCXX.h"
#include "clang/AST/Type.h"

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

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_CPP_CUSTOM_TYPE_MAPPING_H_
