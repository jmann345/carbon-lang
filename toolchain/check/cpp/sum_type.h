// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_CPP_SUM_TYPE_H_
#define CARBON_TOOLCHAIN_CHECK_CPP_SUM_TYPE_H_

#include "clang/AST/Type.h"
#include "toolchain/check/context.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Check {

// The Carbon sum type that a C++ `std::optional` or `std::variant`
// specialization maps to by value (fork decision F-020): the `Core.CppCompat`
// choice `StdOptional(T')` or `StdVariant<N>(T0', ..., T<N-1>')`.
struct CppSumType {
  enum Status : uint8_t {
    // The type is not a `std::optional` or `std::variant` specialization.
    NotSumType,
    // The type is one, and `carbon_type_id` is its Carbon sum type.
    Mapped,
    // The type is one, but it has no Carbon sum type in 0.1; diagnosed by
    // `DiagnoseCppSumTypeNotMapped`.
    NotMapped,
  };
  Status status = NotSumType;
  // The C++ class type.
  SemIR::TypeId cpp_type_id = SemIR::TypeId::None;
  // For `Mapped`: the Carbon choice type.
  SemIR::TypeId carbon_type_id = SemIR::TypeId::None;
  // True for `std::optional`, false for `std::variant`.
  bool is_optional = false;
  // For `NotMapped`: why, and the index of the first alternative that is not
  // admitted (-1 when the reason is not about one alternative).
  enum Reason : uint8_t {
    // The `Core.CppCompat` choice could not be completed; diagnosed with no
    // note.
    NoReason,
    // Forming the `Core.CppCompat` choice failed, and that failure was
    // diagnosed where it happened; nothing more is emitted.
    AlreadyDiagnosed,
    TooManyAlternatives,
    NotTriviallyCopyable,
    QualifiedAlternative,
    AlternativeNotAdmitted,
  };
  Reason reason = NoReason;
  // For `TooManyAlternatives`: how many.
  int num_alternatives = 0;
  int bad_alternative = -1;
  // For `AlternativeNotAdmitted` and `QualifiedAlternative`: the C++ type of
  // that alternative.
  clang::QualType bad_alternative_type;
};

// Classifies `type_id`, completing the C++ class of a specialization first.
// Forms and completes the Carbon sum type when the C++ type is mapped. Emits no
// diagnostic, except where the prelude itself is broken (no `Core.CppCompat`):
// see `CppSumType::AlreadyDiagnosed`.
auto GetCppSumType(Context& context, SemIR::LocId loc_id, SemIR::TypeId type_id)
    -> CppSumType;

// Returns the C++ class that `carbon_type_id` maps to when it is offered to
// C++ overload resolution: for a `Core.CppCompat.StdOptional` or
// `StdVariant<N>` specific, the `std::optional` or `std::variant`
// specialization of the mapped argument types; for a `Core.Optional(T)` whose
// payload is a concrete 0.1 choice payload type and not a pointer type,
// `std::optional<T'>`. The specialization is instantiated. A null type
// otherwise, or if the TU has no matching C++ template or the specialization
// cannot be instantiated.
auto MapCarbonSumTypeToCpp(Context& context, SemIR::LocId loc_id,
                           SemIR::TypeId carbon_type_id) -> clang::QualType;

// Diagnoses a `NotMapped` sum type at `loc_id`.
auto DiagnoseCppSumTypeNotMapped(Context& context, SemIR::LocId loc_id,
                                 const CppSumType& sum_type) -> void;

// Converts `value_id`, of the C++ class type of the `Mapped` `sum_type`, to a
// value of its Carbon sum type, through the C++ accessors. Branches, so it
// needs a function body and a source expression; elsewhere it emits a TODO and
// returns `ErrorInst`.
auto ConvertCppSumToCarbon(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId;

// Converts `value_id`, of the Carbon sum type of the `Mapped` `sum_type`, to a
// value of its C++ class type, through the C++ constructors. Branches, as
// `ConvertCppSumToCarbon` does.
auto ConvertCarbonSumToCpp(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId;

// The conversion hook of `PerformBuiltinConversion`. Converts `value_id` by
// value when it is a C++ `std::optional`/`std::variant` and the target is its
// Carbon sum type or, for `std::optional<T>`, a `Core.Optional(T')` whose
// payload is mapped (a concrete 0.1 choice payload type); or when it is a
// `Core.CppCompat` sum type or such a `Core.Optional(T')` and the target is a
// C++ class. Returns `None` when neither side is involved, or either side is
// template-dependent (the conversion is then deferred to instantiation), and
// `ErrorInst` for a mismatch, which is diagnosed when `diagnose` is true. When
// `diagnose` is false -- a conversion that the caller only tests: an
// `overload fn` candidate probe, the element conversions of an aggregate
// argument included, or deduction -- it decides from the types alone, emits
// nothing and builds no control flow; its result is never a constant. Where the
// committed conversion cannot be built (at file scope, at a template's
// instantiation), that conversion emits the TODO.
auto TryConvertCppSumType(Context& context, SemIR::LocId loc_id,
                          SemIR::InstId value_id, SemIR::TypeId target_type_id,
                          bool diagnose) -> SemIR::InstId;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_CPP_SUM_TYPE_H_
