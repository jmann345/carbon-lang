// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_TYPE_STRUCTURE_H_
#define CARBON_TOOLCHAIN_CHECK_TYPE_STRUCTURE_H_

#include <algorithm>

#include "common/ostream.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "toolchain/check/context.h"
#include "toolchain/check/scope_index.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Check {

// The "type structure" for an impl declaration.
//
// See
// https://docs.carbon-lang.dev/docs/design/generics/overview.html#parameterized-impl-declarations.
//
// Type structures are ordered, and a type structure that is ordered higher is a
// better, more specified, match.
class TypeStructure : public Printable<TypeStructure> {
 public:
  // TypeStructure is a pretty heavy data structure, avoid accidental copies.
  // TODO: Add a Clone() method if we want to make a copy of this in the future.
  TypeStructure(TypeStructure&&) noexcept = default;
  auto operator=(TypeStructure&&) noexcept -> TypeStructure& = default;

  enum class CompareTest {
    // Test whether `this` has the same structure as `other`, or `this` is
    // strictly more specific (has more concrete values) than `other` while
    // maintaining a compatible structure.
    //
    // If false, they can not possibly match with `this` being a lookup query
    // and `other` being an `impl`.
    IsEqualToOrMoreSpecificThan,

    // Tests whether there is a possible query that could match both `this` and
    // `other`, in which case we say `this` has overlap with `other`.
    HasOverlap,
  };

  // Compares the structure of `this` and `other`, and returns whether the
  // structures match according to the specified test.
  //
  // Fork (VA-2, D-VA2-8): with `IsEqualToOrMoreSpecificThan` and a non-null
  // `ranking`, `this` is a query and `other` an impl, and a match also
  // computes the impl's ranking against the query (see `IsBetterRanking`).
  auto CompareStructure(CompareTest test, const TypeStructure& other,
                        llvm::SmallVectorImpl<int>* ranking = nullptr) const
      -> bool;

  // Fork (VA-2, D-VA2-8): whether the impl ranked `lhs` against a query is a
  // better, more specific, match than the impl ranked `rhs` against the same
  // query. A ranking lists, in order, a key for each position `p` in the
  // query's structure that the impl does not match by a concrete element:
  // `4p + 2` for an element matched by a `?`, `4p + 1` for an element covered
  // by a pack segment, and `4p + 3` for a pack segment that covers no element
  // and sits before position `p`. The rule is the overlap rule ("We pick the
  // type structure with a non-`?` at the first difference as most specific",
  // docs/design/generics/details.md) taken position by position along the
  // query, so that impls whose segments cover different runs of the query
  // are compared where their coverage first differs; at one position, a
  // segment that covers nothing is the most specific choice after a concrete
  // element, and a `?`, which matches that element alone, is a more specific
  // choice than a segment that covers it, which matches any run. Without pack
  // segments, this orders impls as `operator<` does.
  static auto IsBetterRanking(llvm::ArrayRef<int> lhs, llvm::ArrayRef<int> rhs)
      -> bool {
    return std::lexicographical_compare(
        lhs.begin(), lhs.end(), rhs.begin(), rhs.end(),
        [](int lhs_index, int rhs_index) { return rhs_index < lhs_index; });
  }

  // Ordering of type structures. A lower value is a better match.
  // TODO: switch to operator<=> once we can depend on
  // std::lexicographical_compare_three_way (in particular, once we can
  // require clang-17 or newer, including in places like the GitHub test
  // runners).
  friend auto operator<(const TypeStructure& lhs, const TypeStructure& rhs)
      -> bool {
    return std::lexicographical_compare(
        lhs.symbolic_type_indices_.begin(), lhs.symbolic_type_indices_.end(),
        rhs.symbolic_type_indices_.begin(), rhs.symbolic_type_indices_.end(),
        [](int lhs_index, int rhs_index) {
          // A higher symbolic type index is a better match, so we need to
          // reverse the order.
          return rhs_index < lhs_index;
        });
  }

  // Equality of type structures. This compares that the structures are
  // identical, which is a stronger requirement than that they are ordered the
  // same.
  friend auto operator==(const TypeStructure& lhs, const TypeStructure& rhs)
      -> bool {
    return lhs.structure_ == rhs.structure_ &&
           lhs.concrete_types_ == rhs.concrete_types_;
  }

  auto Print(llvm::raw_ostream& out) const -> void {
    out << "TypeStructure = ";
    for (auto s : structure_) {
      switch (s) {
        case Structural::Concrete:
          out << 'c';
          break;
        case Structural::Symbolic:
          out << '?';
          break;
        case Structural::ConcreteOpenParen:
          out << "(";
          break;
        case Structural::ConcreteCloseParen:
          out << ')';
          break;
        case Structural::SymbolicRun:
          out << "...";
          break;
      }
    }
  }

 private:
  friend class TypeStructureBuilder;

  // Elements of the type structure, indicating the presence of a concrete or
  // symbolic element, and for aggregate concrete types (such as generic types),
  // nesting for the types inside.
  enum class Structural : uint8_t {
    // A concrete element in the type structure, such as `bool`.
    Concrete,

    // A concrete element in the type structure that contains nested types
    // within, such as `C(D)` for some classes C and D. It marks the start of
    // the nested and is paired with a ConcreteCloseParen at the end of the
    // nested types.
    ConcreteOpenParen,

    // Closes a ConcreteOpenParen for a concrete type with nested types.
    // Does not have its own concrete type.
    ConcreteCloseParen,

    // A symbolic element in the type structure. When matching type structures,
    // it represents a wildcard that matches against either a single `Concrete`
    // or `Symbolic`, or everything from a `ConcreteOpenParen` to its paired
    // `ConcreteCloseParen`.
    Symbolic,

    // Fork (VA-2, D-VA2-8): a tuple's pack segment, `... each T`, whose type
    // parameter the type structure replaces by `?` ("replacing type
    // parameters by a `?`", generics/details.md) inside the tuple, `(...?)`.
    // When matching type structures, it matches a run of zero or more
    // elements of the enclosing tuple: as many as leave the elements after it
    // to match the tuple's last elements. It ranks below a `Symbolic` at the
    // same position, which matches exactly one element.
    SymbolicRun,
  };

  // Marks a type of the named kind.
  enum class ConcreteTypeStart {
    // The type and bound will appear as other entries.
    Array,

    // The inner type will appear as another entry.
    Const,

    // The inner type will appear as another entry.
    MaybeUnformed,

    // The class type will appear as another entry.
    Partial,

    // The pointee type will appear as another entry.
    Pointer,

    // The field names and types will appear as other entries.
    Struct,

    // The type members (if any) will appear as other entries.
    Tuple,
  };

  // The `concrete_types_` tracks the specific concrete type for each
  // `Structural::Concrete` or `Structural::ConcreteOpenParen` in the type
  // structure.
  //
  // `ConstantId` is used strictly for non-type values. For types, `TypeId` is
  // used.
  //
  // `NameId` is used strictly for struct fields, as the field names are part of
  // the struct type.
  using ConcreteType =
      std::variant<ConcreteTypeStart, SemIR::ClassId, SemIR::ConstantId,
                   SemIR::InterfaceId, SemIR::NamedConstraintId, SemIR::NameId,
                   SemIR::TypeId>;

  TypeStructure(llvm::SmallVector<Structural> structure,
                llvm::SmallVector<int> symbolic_type_indices,
                llvm::SmallVector<ConcreteType> concrete_types)
      : structure_(std::move(structure)),
        symbolic_type_indices_(std::move(symbolic_type_indices)),
        concrete_types_(std::move(concrete_types)) {}

  // A helper for ConsumeSymbolicRun: counts the elements from `cursor` to the
  // end of the enclosing tuple (or of the structure).
  static auto CountElementsInGroup(
      llvm::SmallVector<Structural>::const_iterator cursor,
      llvm::SmallVector<Structural>::const_iterator end) -> int;

  // A helper for CompareStructure: consumes the `SymbolicRun` at
  // `run_cursor` and the run of elements at `elements_cursor` that it
  // matches. Returns false if too few elements remain.
  // If `ranking` is not null, the elements are the query's, starting at
  // `elements_begin`, and the run's coverage is appended to it.
  static auto ConsumeSymbolicRun(
      llvm::SmallVector<Structural>::const_iterator& elements_cursor,
      llvm::SmallVector<Structural>::const_iterator elements_end,
      llvm::SmallVector<ConcreteType>::const_iterator& elements_concrete_cursor,
      llvm::SmallVector<Structural>::const_iterator& run_cursor,
      llvm::SmallVector<Structural>::const_iterator run_end,
      llvm::SmallVector<Structural>::const_iterator elements_begin = {},
      llvm::SmallVectorImpl<int>* ranking = nullptr) -> bool;

  // A helper for CompareStructure.
  static auto ConsumeRhsSymbolic(
      llvm::SmallVector<Structural>::const_iterator& lhs_cursor,
      llvm::SmallVector<ConcreteType>::const_iterator& lhs_concrete_cursor,
      llvm::SmallVector<Structural>::const_iterator& rhs_cursor) -> bool;

  // The structural position of concrete and symbolic constants in the type.
  llvm::SmallVector<Structural> structure_;

  // Indices of the symbolic entries in structure_.
  llvm::SmallVector<int> symbolic_type_indices_;

  // The related value for each `Concrete` and `ConcreteOpenParen` entry in
  // the type `structure_`, in the same order. See `ConcreteType`.
  llvm::SmallVector<ConcreteType> concrete_types_;
};

// Constructs the TypeStructure for a self facet value and an interface
// constraint (e.g. `Iface(A, B(C))`), which represents the location of unknown
// symbolic constants in the combined signature and which is ordered by them.
//
// Given `impl C as Z {}` the `self_const_id` would be a `C` and the interface
// constraint would be `Z`.
//
// Returns nullopt if an ErrorInst is encountered in the self facet.
auto BuildTypeStructure(Context& context, SemIR::InstId self_inst_id,
                        SemIR::SpecificInterface interface)
    -> std::optional<TypeStructure>;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_TYPE_STRUCTURE_H_
