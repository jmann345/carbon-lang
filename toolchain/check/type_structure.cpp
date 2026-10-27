// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/type_structure.h"

#include <concepts>
#include <utility>
#include <variant>

#include "toolchain/base/kind_switch.h"
#include "toolchain/check/context.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/type_iterator.h"

namespace Carbon::Check {

auto TypeStructure::CompareStructure(CompareTest test,
                                     const TypeStructure& other,
                                     llvm::SmallVectorImpl<int>* ranking) const
    -> bool {
  if (test != CompareTest::IsEqualToOrMoreSpecificThan) {
    ranking = nullptr;
  }
  if (ranking) {
    ranking->clear();
  }
  const auto& lhs = structure_;
  const auto& rhs = other.structure_;

  const auto* lhs_cursor = lhs.begin();
  const auto* rhs_cursor = rhs.begin();

  const auto* lhs_concrete_cursor = concrete_types_.begin();
  const auto* rhs_concrete_cursor = other.concrete_types_.begin();

  while (true) {
    // If both structures end at the same time, they match.
    if (lhs_cursor == lhs.end() && rhs_cursor == rhs.end()) {
      return true;
    }
    // If one structure ends sooner than the other, they don't match.
    if (lhs_cursor == lhs.end() || rhs_cursor == rhs.end()) {
      return false;
    }
    // Fork (VA-2, D-VA2-8): a pack segment matches a run of the other side's
    // elements, including the other side's own segment.
    if (*rhs_cursor == Structural::SymbolicRun) {
      if (!ConsumeSymbolicRun(lhs_cursor, lhs.end(), lhs_concrete_cursor,
                              rhs_cursor, rhs.end(), lhs.begin(), ranking)) {
        return false;
      }
      continue;
    }
    if (*lhs_cursor == Structural::SymbolicRun) {
      // A query with a pack segment is less specific than an impl with
      // elements in its place.
      if (test == CompareTest::IsEqualToOrMoreSpecificThan) {
        return false;
      }
      if (!ConsumeSymbolicRun(rhs_cursor, rhs.end(), rhs_concrete_cursor,
                              lhs_cursor, lhs.end())) {
        return false;
      }
      continue;
    }
    // Same structural element on both sides. Compare concrete values if
    // possible to ensure they match. Both will be consumed.
    if (*lhs_cursor == *rhs_cursor) {
      if (ranking && *rhs_cursor == Structural::Symbolic) {
        ranking->push_back(4 * (lhs_cursor - lhs.begin()) + 2);
      }
      // Each Concrete and ConcreteOpenParen shape entry has a paired concrete
      // value.
      if (*lhs_cursor == Structural::Concrete ||
          *lhs_cursor == Structural::ConcreteOpenParen) {
        if (*lhs_concrete_cursor != *rhs_concrete_cursor) {
          return false;
        }

        // Move past the shape and concrete value together.
        ++lhs_concrete_cursor;
        ++rhs_concrete_cursor;
      }
      ++lhs_cursor;
      ++rhs_cursor;
      continue;
    }
    // If the element on each side is concrete but they not the same structural
    // shape, then the structures don't match.
    if (*lhs_cursor != Structural::Symbolic &&
        *rhs_cursor != Structural::Symbolic) {
      return false;
    }

    // From here we know one side is a Symbolic and the other is not. We can
    // match the Symbolic against either a single Concrete or a larger bracketed
    // set of Concrete structural elements.
    switch (test) {
      case CompareTest::IsEqualToOrMoreSpecificThan:
        // If the symbolic is on the LHS, then the RHS structure is more
        // specific and we return false. If the symbolic is on the RHS, we
        // consume it and match it against the structure on the LHS.
        if (*lhs_cursor == Structural::Symbolic) {
          return false;
        }
        if (ranking) {
          ranking->push_back(4 * (lhs_cursor - lhs.begin()) + 2);
        }
        if (!ConsumeRhsSymbolic(lhs_cursor, lhs_concrete_cursor, rhs_cursor)) {
          return false;
        }
        break;
      case CompareTest::HasOverlap:
        // The symbolic can be on either side, and whichever side it is on, we
        // consume it and match it against the structure on the other side.
        if (*lhs_cursor == Structural::Symbolic) {
          if (!ConsumeRhsSymbolic(rhs_cursor, rhs_concrete_cursor,
                                  lhs_cursor)) {
            return false;
          }
        } else {
          if (!ConsumeRhsSymbolic(lhs_cursor, lhs_concrete_cursor,
                                  rhs_cursor)) {
            return false;
          }
        }
        break;
    }
  }

  return true;
}

auto TypeStructure::CountElementsInGroup(
    llvm::SmallVector<Structural>::const_iterator cursor,
    llvm::SmallVector<Structural>::const_iterator end) -> int {
  int count = 0;
  int depth = 0;
  for (; cursor != end; ++cursor) {
    if (*cursor == Structural::ConcreteCloseParen) {
      if (depth == 0) {
        break;
      }
      --depth;
      continue;
    }
    if (depth == 0) {
      ++count;
    }
    if (*cursor == Structural::ConcreteOpenParen) {
      ++depth;
    }
  }
  return count;
}

auto TypeStructure::ConsumeSymbolicRun(
    llvm::SmallVector<Structural>::const_iterator& elements_cursor,
    llvm::SmallVector<Structural>::const_iterator elements_end,
    llvm::SmallVector<ConcreteType>::const_iterator& elements_concrete_cursor,
    llvm::SmallVector<Structural>::const_iterator& run_cursor,
    llvm::SmallVector<Structural>::const_iterator run_end,
    llvm::SmallVector<Structural>::const_iterator elements_begin,
    llvm::SmallVectorImpl<int>* ranking) -> bool {
  // Consume the run.
  ++run_cursor;
  // The run takes every element of its tuple except as many as follow it.
  int after = CountElementsInGroup(run_cursor, run_end);
  int available = CountElementsInGroup(elements_cursor, elements_end);
  if (available < after) {
    return false;
  }
  int to_skip = available - after;
  if (ranking && to_skip == 0) {
    ranking->push_back(4 * (elements_cursor - elements_begin) + 3);
  }
  int depth = 0;
  while (to_skip > 0) {
    if (ranking && depth == 0 &&
        *elements_cursor != Structural::ConcreteCloseParen) {
      ranking->push_back(4 * (elements_cursor - elements_begin) + 1);
    }
    switch (*elements_cursor) {
      case Structural::ConcreteOpenParen:
        ++elements_concrete_cursor;
        ++depth;
        break;
      case Structural::ConcreteCloseParen:
        --depth;
        if (depth == 0) {
          --to_skip;
        }
        break;
      case Structural::Concrete:
        ++elements_concrete_cursor;
        if (depth == 0) {
          --to_skip;
        }
        break;
      case Structural::Symbolic:
      case Structural::SymbolicRun:
        if (depth == 0) {
          --to_skip;
        }
        break;
    }
    ++elements_cursor;
  }
  return true;
}

// Returns false if the lhs and rhs can not match, true if we should
// continue checking for compatibility.
auto TypeStructure::ConsumeRhsSymbolic(
    llvm::SmallVector<Structural>::const_iterator& lhs_cursor,
    llvm::SmallVector<ConcreteType>::const_iterator& lhs_concrete_cursor,
    llvm::SmallVector<Structural>::const_iterator& rhs_cursor) -> bool {
  // Consume the symbolic on the RHS.
  ++rhs_cursor;

  // The symbolic on the RHS is in the same position as a close paren on the
  // LHS, which means the structures can not match.
  //
  // Example:
  // - ((c))
  // - ((c?))
  if (*lhs_cursor == TypeStructure::Structural::ConcreteCloseParen) {
    return false;
  }

  // There's either a Concrete element or an open paren on the LHS. If it's
  // the former, the Symbolic just matches with it. If it's the latter, the
  // Symbolic matches with everything on the LHS up to the matching closing
  // paren.
  CARBON_CHECK(*lhs_cursor == Structural::Concrete ||
               *lhs_cursor == Structural::ConcreteOpenParen);
  int depth = 0;
  do {
    switch (*lhs_cursor) {
      case Structural::ConcreteOpenParen:
        depth += 1;
        // Each Concrete and ConcreteOpenParen shape entry has a paired
        // concrete value. Skip the shape and concrete value together.
        ++lhs_concrete_cursor;
        break;
      case Structural::ConcreteCloseParen:
        depth -= 1;
        break;
      case Structural::Concrete:
        // Each Concrete and ConcreteOpenParen shape entry has a paired
        // concrete value. Skip the shape and concrete value together.
        ++lhs_concrete_cursor;
        break;
      case Structural::Symbolic:
      case Structural::SymbolicRun:
        break;
    }
    ++lhs_cursor;
  } while (depth > 0);
  return true;
}

// A class that builds a `TypeStructure` for an `Impl`, or an impl lookup query,
// that represents its self type and interface.
class TypeStructureBuilder {
 public:
  // `context` must not be null.
  explicit TypeStructureBuilder(Context* context) : context_(context) {}

  auto Run(SemIR::InstId self_inst_id,
           SemIR::SpecificInterface interface_constraint)
      -> std::optional<TypeStructure> {
    structure_.clear();
    symbolic_type_indices_.clear();
    concrete_types_.clear();

    SemIR::TypeIterator type_iter(&context_->sem_ir());

    // The self type comes first in the type structure, so we push it last, as
    // the iterator starts with the last thing added.
    type_iter.Add(interface_constraint);
    if (self_inst_id.has_value()) {
      type_iter.Add(self_inst_id);
    }
    return Build(std::move(type_iter));
  }

 private:
  auto Build(SemIR::TypeIterator type_iter) -> std::optional<TypeStructure>;

  // Append a structural element to the TypeStructure being built.
  auto AppendStructuralConcrete(TypeStructure::ConcreteType type) -> void {
    concrete_types_.push_back(type);
    structure_.push_back(TypeStructure::Structural::Concrete);
  }
  auto AppendStructuralConcreteOpenParen(TypeStructure::ConcreteType type)
      -> void {
    concrete_types_.push_back(type);
    structure_.push_back(TypeStructure::Structural::ConcreteOpenParen);
  }
  auto AppendStructuralConcreteCloseParen() -> void {
    structure_.push_back(TypeStructure::Structural::ConcreteCloseParen);
  }
  auto AppendStructuralSymbolic() -> void {
    symbolic_type_indices_.push_back(structure_.size());
    structure_.push_back(TypeStructure::Structural::Symbolic);
  }
  // Fork (VA-2, D-VA2-8): a tuple's pack segment.
  auto AppendStructuralSymbolicRun() -> void {
    symbolic_type_indices_.push_back(structure_.size());
    structure_.push_back(TypeStructure::Structural::SymbolicRun);
  }

  Context* context_;

  // In-progress state for the equivalent `TypeStructure` fields.
  llvm::SmallVector<TypeStructure::Structural> structure_;
  llvm::SmallVector<int> symbolic_type_indices_;
  llvm::SmallVector<TypeStructure::ConcreteType> concrete_types_;
};

// Builds the type structure and returns it.
auto TypeStructureBuilder::Build(SemIR::TypeIterator type_iter)
    -> std::optional<TypeStructure> {
  while (true) {
    using Step = SemIR::TypeIterator::Step;
    CARBON_KIND_SWITCH(type_iter.Next().any) {
      case CARBON_KIND(Step::Done _): {
        // TODO: This requires 4 SmallVector moves (two here and two in the
        // constructor). Find a way to reduce that.
        return TypeStructure(std::exchange(structure_, {}),
                             std::exchange(symbolic_type_indices_, {}),
                             std::exchange(concrete_types_, {}));
      }
      case CARBON_KIND(Step::End _): {
        AppendStructuralConcreteCloseParen();
        break;
      }
      case CARBON_KIND(Step::Error _): {
        return std::nullopt;
      }
      case CARBON_KIND(Step::ConcreteType concrete): {
        AppendStructuralConcrete(concrete.type_id);
        break;
      }
      case CARBON_KIND(Step::SymbolicType symbolic): {
        // Fork (VA-2): a tuple's pack segment.
        if (symbolic.facet.has_value() &&
            context_->insts().Is<SemIR::PackType>(symbolic.facet)) {
          AppendStructuralSymbolicRun();
        } else {
          AppendStructuralSymbolic();
        }
        break;
      }
      case CARBON_KIND(Step::TemplateType _): {
        AppendStructuralSymbolic();
        break;
      }
      case CARBON_KIND(Step::TypeWrapper _): {
        // Ignored, as it may be concrete or symbolic. We will recurse into it.
        break;
      }
      case CARBON_KIND(Step::ConcreteValue value): {
        AppendStructuralConcrete(
            context_->constant_values().Get(value.inst_id));
        break;
      }
      case CARBON_KIND(Step::SymbolicValue _): {
        AppendStructuralSymbolic();
        break;
      }
      case CARBON_KIND(Step::StructFieldName field_name): {
        AppendStructuralConcrete(field_name.name_id);
        break;
      }
      case CARBON_KIND(Step::ClassStartOnly class_start): {
        AppendStructuralConcrete(class_start.class_id);
        break;
      }
      case CARBON_KIND(Step::ClassStart class_start): {
        AppendStructuralConcreteOpenParen(class_start.class_id);
        break;
      }
      case CARBON_KIND(Step::StructStartOnly _): {
        AppendStructuralConcrete(TypeStructure::ConcreteTypeStart::Struct);
        break;
      }
      case CARBON_KIND(Step::StructStart _): {
        AppendStructuralConcreteOpenParen(
            TypeStructure::ConcreteTypeStart::Struct);
        break;
      }
      case CARBON_KIND(Step::TupleStartOnly _): {
        // Fork (VA-2, D-VA2-8): the empty tuple is an empty group, as a
        // tuple of elements is a group of them, so that a pack segment
        // `(...?)` matches it with an empty run.
        AppendStructuralConcreteOpenParen(
            TypeStructure::ConcreteTypeStart::Tuple);
        AppendStructuralConcreteCloseParen();
        break;
      }
      case CARBON_KIND(Step::TupleStart _): {
        AppendStructuralConcreteOpenParen(
            TypeStructure::ConcreteTypeStart::Tuple);
        break;
      }
      case CARBON_KIND(Step::InterfaceStartOnly interface_start): {
        AppendStructuralConcrete(interface_start.interface_id);
        break;
      }
      case CARBON_KIND(Step::InterfaceStart interface_start): {
        AppendStructuralConcreteOpenParen(interface_start.interface_id);
        break;
      }
      case CARBON_KIND(Step::NamedConstraintStartOnly named_constraint_start): {
        AppendStructuralConcrete(named_constraint_start.named_constraint_id);
        break;
      }
      case CARBON_KIND(Step::NamedConstraintStart named_constraint_start): {
        AppendStructuralConcreteOpenParen(
            named_constraint_start.named_constraint_id);
        break;
      }
      case CARBON_KIND(Step::IntStart int_start): {
        AppendStructuralConcreteOpenParen(int_start.type_id);
        break;
      }

      // Types which only have an `OpenParen` shape.
      case CARBON_KIND(Step::ArrayStart _): {
        AppendStructuralConcreteOpenParen(
            TypeStructure::ConcreteTypeStart::Array);
        break;
      }
      case CARBON_KIND(Step::ConstStart _): {
        AppendStructuralConcreteOpenParen(
            TypeStructure::ConcreteTypeStart::Const);
        break;
      }
      case CARBON_KIND(Step::MaybeUnformedStart _): {
        AppendStructuralConcreteOpenParen(
            TypeStructure::ConcreteTypeStart::MaybeUnformed);
        break;
      }
      case CARBON_KIND(Step::PartialStart _): {
        AppendStructuralConcreteOpenParen(
            TypeStructure::ConcreteTypeStart::Partial);
        break;
      }
      case CARBON_KIND(Step::PointerStart _): {
        AppendStructuralConcreteOpenParen(
            TypeStructure::ConcreteTypeStart::Pointer);
        break;
      }
    }
  }
}

auto BuildTypeStructure(Context& context, SemIR::InstId self_inst_id,
                        SemIR::SpecificInterface interface)
    -> std::optional<TypeStructure> {
  TypeStructureBuilder builder(&context);
  return builder.Run(self_inst_id, interface);
}

}  // namespace Carbon::Check
