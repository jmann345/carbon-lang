// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/action.h"

#include "toolchain/base/kind_switch.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/generic_region_stack.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/subst.h"
#include "toolchain/check/type.h"
#include "toolchain/sem_ir/constant.h"
#include "toolchain/sem_ir/copy_on_write_block.h"
#include "toolchain/sem_ir/generic.h"
#include "toolchain/sem_ir/id_kind.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId /*specific_id*/,
                                        SemIR::ConstantId const_id)
    -> SemIR::ConstantDependence {
  // A type operand makes the instruction dependent if it is a
  // template-dependent constant.
  if (!const_id.is_symbolic()) {
    return SemIR::ConstantDependence::None;
  }
  return context.constant_values().GetSymbolicConstant(const_id).dependence;
}

static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::TypeId type_id)
    -> SemIR::ConstantDependence {
  // A type operand makes the instruction dependent if it is a
  // template-dependent type.
  return OperandDependenceInSpecific(context, specific_id,
                                     context.types().GetConstantId(type_id));
}

auto OperandDependence(Context& context, SemIR::TypeId type_id)
    -> SemIR::ConstantDependence {
  return OperandDependenceInSpecific(context, SemIR::SpecificId::None, type_id);
}

static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::InstId inst_id)
    -> SemIR::ConstantDependence {
  // An instruction operand makes the instruction dependent if its type or
  // constant value is dependent.
  return std::max(
      OperandDependenceInSpecific(context, specific_id,
                                  context.insts().Get(inst_id).type_id()),
      OperandDependenceInSpecific(context, specific_id,
                                  context.constant_values().Get(inst_id)));
}

auto OperandDependence(Context& context, SemIR::InstId inst_id)
    -> SemIR::ConstantDependence {
  return OperandDependenceInSpecific(context, SemIR::SpecificId::None, inst_id);
}

static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::MetaInstId inst_id)
    -> SemIR::ConstantDependence {
  // A meta-instruction operand makes the instruction dependent if its type or
  // constant value is dependent in this specific.
  return std::max(
      OperandDependenceInSpecific(
          context, specific_id,
          GetTypeOfInstInSpecific(context.sem_ir(), specific_id, inst_id)),
      OperandDependenceInSpecific(context, specific_id,
                                  SemIR::GetConstantValueInSpecific(
                                      context.sem_ir(), specific_id, inst_id)));
}

auto OperandDependence(Context& context, SemIR::MetaInstId inst_id)
    -> SemIR::ConstantDependence {
  return OperandDependenceInSpecific(context, SemIR::SpecificId::None, inst_id);
}

static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::TypeInstId inst_id)
    -> SemIR::ConstantDependence {
  // An instruction operand makes the instruction dependent if its type or
  // constant value is dependent. TypeInstId has type `TypeType` which is
  // concrete, so we only need to look at the constant value.
  return OperandDependenceInSpecific(context, specific_id,
                                     context.constant_values().Get(inst_id));
}

auto OperandDependence(Context& context, SemIR::TypeInstId inst_id)
    -> SemIR::ConstantDependence {
  return OperandDependenceInSpecific(context, SemIR::SpecificId::None, inst_id);
}

template <typename IdT>
  requires SemIR::Internal::IsIdKindType<IdT> &&
           SameAsOneOf<IdT, SemIR::IdAndKind::NoneType, SemIR::AbsoluteInstId,
                       SemIR::BoolValue, SemIR::CallParamIndex,
                       SemIR::ClangDeclId, SemIR::ElementIndex, SemIR::NameId>
static auto OperandDependenceInSpecific(Context& /*context*/,
                                        SemIR::SpecificId /*specific_id*/,
                                        IdT /*id*/)
    -> SemIR::ConstantDependence {
  return SemIR::ConstantDependence::None;
}

template <typename BundleT>
static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::BundleId<BundleT> bundle_id)
    -> SemIR::ConstantDependence {
  return std::apply(
      [&](auto... ids) {
        return std::max(
            {OperandDependenceInSpecific(context, specific_id, ids)...});
      },
      context.bundles().GetAsTuple(bundle_id));
}

static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::InstBlockId inst_block_id)
    -> SemIR::ConstantDependence {
  auto result = SemIR::ConstantDependence::None;
  for (auto arg_id : context.inst_blocks().Get(inst_block_id)) {
    result = std::max(
        result, OperandDependenceInSpecific(context, specific_id, arg_id));
  }
  return result;
}

static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::MetaInstBlockId inst_block_id)
    -> SemIR::ConstantDependence {
  auto result = SemIR::ConstantDependence::None;
  for (auto arg_id : context.inst_blocks().Get(inst_block_id)) {
    result =
        std::max(result, OperandDependenceInSpecific(
                             context, specific_id, SemIR::MetaInstId(arg_id)));
  }
  return result;
}

static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::SpecificId inner_specific_id)
    -> SemIR::ConstantDependence {
  auto specific = context.specifics().Get(inner_specific_id);
  return OperandDependenceInSpecific(context, specific_id, specific.args_id);
}

template <typename IdT>
  requires SemIR::Internal::IsIdKindType<IdT>
static auto OperandDependenceInSpecific(Context& /*context*/,
                                        SemIR::SpecificId /*specific_id*/,
                                        IdT /*id*/)
    -> SemIR::ConstantDependence {
  // TODO: Properly handle different argument kinds.
  CARBON_FATAL("Unexpected argument kind for action: {}", IdT::Label);
}

static auto OperandDependenceInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::IdAndKind arg)
    -> SemIR::ConstantDependence {
  return arg.Dispatch<SemIR::ConstantDependence>([&](auto id) {
    return OperandDependenceInSpecific(context, specific_id, id);
  });
}

auto ActionIsPerformable(Context& context, SemIR::Inst action_inst,
                         SemIR::SpecificId specific_id) -> bool {
  // A form-parameterized action is performable if we can see at least the top
  // level of its form's structure (i.e. it is not an action or a splice).
  // TODO: Can we represent this as a different operand type instead?
  if (auto form_parameterized_action =
          action_inst.TryAs<SemIR::AnyFormParamAction>()) {
    auto form_const_id =
        context.constant_values().Get(form_parameterized_action->form_id);
    auto form_id = context.constant_values().GetInstIdIfValid(form_const_id);
    if (!form_id.has_value()) {
      // This is an error which will be diagnosed elsewhere, so we should just
      // get out of its way.
      return true;
    }
    auto form_inst = context.insts().Get(form_id);
    switch (form_inst.kind()) {
      case SemIR::InitForm::Kind:
      case SemIR::RefForm::Kind:
      case SemIR::ValueForm::Kind:
      case SemIR::ErrorInst::Kind:
        return true;
      default:
        return false;
    }
  }

  return OperandDependenceInSpecific(context, specific_id,
                                     action_inst.type_id()) <
             SemIR::ConstantDependence::Template &&
         OperandDependenceInSpecific(context, specific_id,
                                     action_inst.arg0_and_kind()) <
             SemIR::ConstantDependence::Template &&
         OperandDependenceInSpecific(context, specific_id,
                                     action_inst.arg1_and_kind()) <
             SemIR::ConstantDependence::Template;
}

auto AddSpliceInst(Context& context, SemIR::InstId inst_value_id,
                   SemIR::TypeInstId result_type_inst_id) -> SemIR::InstId {
  if (!result_type_inst_id.has_value()) {
    result_type_inst_id = AddTypeInst<SemIR::TypeOfInst>(
        context, SemIR::LocId(inst_value_id),
        {.type_id = SemIR::TypeType::TypeId, .inst_id = inst_value_id});
  }
  return AddInst<SemIR::SpliceInst>(
      context, SemIR::LocId(inst_value_id),
      {.type_id = context.types().GetTypeIdForTypeInstId(result_type_inst_id),
       .inst_id = inst_value_id});
}

// Refine one operand of an action. Given an argument from a template, this
// produces an argument that has the template-dependent parts replaced with
// their concrete values, so that the action doesn't need to know which specific
// it is operating on.
//
// This is the default case, for ID kinds that can't be refined.
template <typename IdT>
  requires SemIR::Internal::IsIdKindType<IdT>
static auto RefineTypedOperand(Context& /*context*/, SemIR::LocId /*loc_id*/,
                               IdT id) -> IdT {
  return id;
}

static auto RefineTypedOperand(Context& context, SemIR::LocId /*loc_id*/,
                               SemIR::MetaInstId inst_id) -> SemIR::MetaInstId {
  // TODO: Can we delete this check?
  if (context.insts().Is<SemIR::SpliceInst>(inst_id)) {
    // The argument will evaluate to the spliced instruction, which is already
    // refined.
    return inst_id;
  }

  // If the constant value of the instruction is template-dependent and
  // unattached, replace it with a corresponding attached constant value.
  auto const_id = context.constant_values().GetAttached(inst_id);
  if (const_id.is_symbolic() &&
      !context.constant_values().IsAttached(const_id)) {
    return GetOrAddInstWithSpecificConstantValue(context, inst_id);
  }

  // If the type or constant value of the operand is template-dependent, it will
  // be refined when the action is performed, once we know which specific we're
  // performing it in.
  return inst_id;
}

template <typename DerivedInstIdT>
  requires SemIR::Internal::IsIdKindType<DerivedInstIdT> &&
           std::derived_from<DerivedInstIdT, SemIR::InstId>
static auto RefineTypedOperand(Context& context, SemIR::LocId /*loc_id*/,
                               DerivedInstIdT inst_id) -> DerivedInstIdT {
  // Refine an instruction that refers to a value within the current generic to
  // refer to the corresponding value within the specific. This is analogous to
  // the work we do to rebuild generic constants in the eval block, but is done
  // as refinement rather than rebuilding since action instructions *only* live
  // in the eval block.
  auto result = GetOrAddInstWithSpecificConstantValue(context, inst_id);
  if constexpr (requires { DerivedInstIdT(result); }) {
    return DerivedInstIdT(result);
  } else {
    return DerivedInstIdT::UnsafeMake(result);
  }
}

template <typename DerivedInstBlockIdT>
  requires SemIR::Internal::IsIdKindType<DerivedInstBlockIdT> &&
           std::derived_from<DerivedInstBlockIdT, SemIR::InstBlockId>
static auto RefineTypedOperand(Context& context, SemIR::LocId loc_id,
                               DerivedInstBlockIdT inst_block_id)
    -> DerivedInstBlockIdT {
  auto block = context.inst_blocks().Get(inst_block_id);

  llvm::SmallVector<SemIR::InstId> new_block;
  new_block.reserve(block.size());
  bool any_changed = false;
  for (auto inst_id : block) {
    new_block.push_back(RefineTypedOperand(
        context, loc_id, typename DerivedInstBlockIdT::InstIdT(inst_id)));
    any_changed |= new_block.back() != inst_id;
  }
  if (!any_changed) {
    return inst_block_id;
  }
  return DerivedInstBlockIdT(context.inst_blocks().AddCanonical(new_block));
}

template <typename BundleT>
static auto RefineTypedOperand(Context& context, SemIR::LocId loc_id,
                               SemIR::BundleId<BundleT> bundle_id)
    -> SemIR::BundleId<BundleT> {
  auto bundle_tuple = context.bundles().GetAsTuple(bundle_id);
  BundleT refined_bundle = std::apply(
      [&](auto... bundle_fields) {
        // This can't actually recurse, because bundles can't contain bundle
        // IDs.
        return BundleT{RefineTypedOperand(context, loc_id, bundle_fields)...};
      },
      bundle_tuple);
  return context.bundles().AddCanonical(refined_bundle);
}

// Dynamically dispatched wrapper for RefineTypedOperand.
static auto RefineOperand(Context& context, SemIR::LocId loc_id,
                          SemIR::IdAndKind arg) -> int32_t {
  return arg.Dispatch<int32_t>([&](auto id) {
    return SemIR::ToRaw(RefineTypedOperand(context, loc_id, id));
  });
}

// Refine the operands of an action, ensuring that they will refer to concrete
// instructions that don't have template-dependent types.
static auto RefineOperands(Context& context, SemIR::LocId loc_id,
                           SemIR::Inst action) -> SemIR::Inst {
  auto arg0 = RefineOperand(context, loc_id, action.arg0_and_kind());
  auto arg1 = RefineOperand(context, loc_id, action.arg1_and_kind());
  action.SetArgs(arg0, arg1);
  return action;
}

namespace {
// Fork (VA-2, D-VA2-14): finds the pack index in a constant, without
// substituting into it.
class FindPackIndexCallbacks final : public SubstInstCallbacks {
 public:
  explicit FindPackIndexCallbacks(Context* context)
      : SubstInstCallbacks(context) {}

  auto Subst(SemIR::InstId& inst_id) -> SubstResult override {
    if (found_ || !context().constant_values().Get(inst_id).is_symbolic()) {
      return FullySubstituted;
    }
    if (context().insts().Is<SemIR::PackIndex>(inst_id)) {
      found_ = true;
      return FullySubstituted;
    }
    return SubstOperands;
  }

  auto Rebuild(SemIR::InstId orig_inst_id, SemIR::Inst /*new_inst*/)
      -> SemIR::InstId override {
    return orig_inst_id;
  }

  auto found() const -> bool { return found_; }

 private:
  bool found_ = false;
};
}  // namespace

// Fork (VA-2, D-VA2-14): returns whether the value of `inst_id`, or its type,
// depends on the pack index of an enclosing pack expansion, as an element of a
// pack of different types does: `each T`, or `each x` of type `each T`, is a
// different type or value in each iteration (docs/design/variadics.md,
// "Iterative typechecking of pack expansions").
static auto DependsOnPackIndex(Context& context, SemIR::InstId inst_id)
    -> bool {
  if (!inst_id.has_value()) {
    return false;
  }
  auto uses_pack_index = [&](SemIR::ConstantId const_id) {
    if (!const_id.is_symbolic()) {
      return false;
    }
    FindPackIndexCallbacks callbacks(&context);
    SubstInst(context, context.constant_values().GetInstId(const_id),
              callbacks);
    return callbacks.found();
  };
  auto type_id = context.insts().Get(inst_id).type_id();
  return uses_pack_index(context.constant_values().Get(inst_id)) ||
         (type_id.has_value() &&
          uses_pack_index(context.types().GetConstantId(type_id)));
}

// Fork (VA-2, D-VA2-14): returns whether `pred` holds for an instruction
// operand of `action` or for an instruction in an operand block.
static auto AnyOperand(Context& context, SemIR::Inst action,
                       llvm::function_ref<auto(SemIR::InstId)->bool> pred)
    -> bool {
  auto any = [&](SemIR::IdAndKind arg) {
    return arg.Dispatch<bool>([&](auto id) {
      using IdT = decltype(id);
      if constexpr (std::derived_from<IdT, SemIR::InstId>) {
        return pred(id);
      } else if constexpr (std::derived_from<IdT, SemIR::InstBlockId>) {
        return id.has_value() &&
               llvm::any_of(context.inst_blocks().Get(id), pred);
      } else {
        return false;
      }
    });
  };
  return any(action.arg0_and_kind()) || any(action.arg1_and_kind());
}

// Fork (VA-2, D-VA2-14): returns whether an operand of `action` depends on the
// pack index of an enclosing pack expansion. A dependent action is performed
// once for each specific, but such an operand differs between the
// expansion's iterations.
static auto ActionDependsOnPackIndex(Context& context, SemIR::Inst action)
    -> bool {
  if (context.pack_expansion_stack().empty()) {
    return false;
  }
  return AnyOperand(context, action, [&](SemIR::InstId inst_id) {
    return DependsOnPackIndex(context, inst_id);
  });
}

// Fork (VA-2, D-VA2-14): returns whether `inst_id` is a run-time tuple or
// struct literal with a pack segment, such as `(... each x)`, directly or in a
// nested literal. The segment is one element of the literal, of pack type,
// but stands for the pack's elements in the tuple's type, so a specific that
// performs an action on the literal as formed would find one element where
// its tuple type has the segment's (docs/design/variadics.md, "Iterative
// typechecking of pack expansions").
static auto IsLiteralWithPackSegment(Context& context, SemIR::InstId inst_id)
    -> bool {
  llvm::SmallVector<SemIR::InstId> worklist = {inst_id};
  while (!worklist.empty()) {
    auto literal_id = worklist.pop_back_val();
    if (!literal_id.has_value() ||
        context.constant_values().Get(literal_id).is_constant()) {
      continue;
    }
    auto literal = context.insts().Get(literal_id);
    auto elements_id = SemIR::InstBlockId::None;
    if (auto tuple_literal = literal.TryAs<SemIR::TupleLiteral>()) {
      elements_id = tuple_literal->elements_id;
    } else if (auto struct_literal = literal.TryAs<SemIR::StructLiteral>()) {
      elements_id = struct_literal->elements_id;
    } else {
      continue;
    }
    for (auto element_id : context.inst_blocks().Get(elements_id)) {
      if (context.types().Is<SemIR::PackType>(
              context.insts().Get(element_id).type_id())) {
        return true;
      }
      worklist.push_back(element_id);
    }
  }
  return false;
}

auto AddDependentActionInst(Context& context, SemIR::LocIdAndInst action)
    -> SemIR::InstId {
  // Fork (VA-2, D-VA2-14): an action on an element of a pack of different
  // types would need to be performed once per iteration of the expansion.
  if (ActionDependsOnPackIndex(context, action.inst)) {
    context.TODO(action.loc_id,
                 "C++ or template-dependent action on an element of a pack "
                 "of different types");
    return SemIR::ErrorInst::InstId;
  }
  // Fork (VA-2, D-VA2-14): so would an action on a literal with a pack
  // segment, once per element of the segment.
  if (AnyOperand(context, action.inst, [&](SemIR::InstId inst_id) {
        return IsLiteralWithPackSegment(context, inst_id);
      })) {
    context.TODO(action.loc_id,
                 "C++ or template-dependent action on a tuple literal with a "
                 "pack segment");
    return SemIR::ErrorInst::InstId;
  }
  action.inst = RefineOperands(context, action.loc_id, action.inst);
  return AddTemplateConstantInstToEvalBlock(context, action);
}

auto AddDependentActionSplice(Context& context, SemIR::LocIdAndInst action,
                              SemIR::TypeInstId result_type_inst_id)
    -> SemIR::InstId {
  action.inst = RefineOperands(context, action.loc_id, action.inst);

  auto inst_id = AddDependentActionInst(context, action);
  // Fork (VA-2, D-VA2-14): the action was refused.
  if (inst_id == SemIR::ErrorInst::InstId) {
    return inst_id;
  }
  return AddSpliceInst(context, inst_id, result_type_inst_id);
}

// Refine one operand of an action that is being performed within a specific.
// Given an operand of an action from a generic, this produces an operand that
// refers to the corresponding instruction within the specific, so that the
// action doesn't need to know which specific it is operating on.
//
// This is the default case, for ID kinds that never need to be refined.
template <typename IdT>
  requires SemIR::Internal::IsIdKindType<IdT>
static auto RefineTypedOperandInSpecific(Context& /*context*/,
                                         SemIR::SpecificId /*specific_id*/,
                                         IdT id) -> IdT {
  return id;
}

// Returns whether `inst_id`, which is an instruction within a generic, needs a
// `SpecificInst` in order to be referred to from within a specific. If the
// instruction isn't symbolic within the generic, then either it doesn't depend
// on the specific at all, or evaluation has already replaced it with the
// corresponding instruction from the specific.
static auto NeedsSpecificInst(Context& context, SemIR::InstId inst_id) -> bool {
  return context.insts().Get(inst_id).type_id().is_symbolic() ||
         context.constant_values().Get(inst_id).is_symbolic();
}

auto AddSpecificInst(Context& context, SemIR::InstId inst_id,
                     SemIR::SpecificId specific_id) -> SemIR::InstId {
  if (!NeedsSpecificInst(context, inst_id)) {
    return inst_id;
  }

  return AddInst<SemIR::SpecificInst>(
      context, SemIR::LocId(inst_id),
      {.type_id =
           GetTypeOfInstInSpecific(context.sem_ir(), specific_id, inst_id),
       .inst_id = inst_id,
       .specific_id = specific_id});
}

auto AddSpecificInstToPendingBlock(PendingBlock& block, SemIR::InstId inst_id,
                                   SemIR::SpecificId specific_id)
    -> SemIR::InstId {
  if (!NeedsSpecificInst(block.context(), inst_id)) {
    return inst_id;
  }

  return block.AddInst<SemIR::SpecificInst>(
      SemIR::LocId(inst_id),
      {.type_id = GetTypeOfInstInSpecific(block.context().sem_ir(), specific_id,
                                          inst_id),
       .inst_id = inst_id,
       .specific_id = specific_id});
}

static auto RefineTypedOperandInSpecific(Context& context,
                                         SemIR::SpecificId specific_id,
                                         SemIR::MetaInstId inst_id)
    -> SemIR::MetaInstId {
  return AddSpecificInst(context, inst_id, specific_id);
}

static auto RefineTypedOperandInSpecific(Context& context,
                                         SemIR::SpecificId specific_id,
                                         SemIR::MetaInstBlockId inst_block_id)
    -> SemIR::MetaInstBlockId {
  auto block = context.inst_blocks().Get(inst_block_id);

  llvm::SmallVector<SemIR::InstId> new_block;
  new_block.reserve(block.size());
  bool any_changed = false;
  for (auto inst_id : block) {
    new_block.push_back(RefineTypedOperandInSpecific(
        context, specific_id, SemIR::MetaInstId(inst_id)));
    any_changed |= new_block.back() != inst_id;
  }
  if (!any_changed) {
    return inst_block_id;
  }
  return SemIR::MetaInstBlockId(context.inst_blocks().AddCanonical(new_block));
}

template <typename BundleT>
static auto RefineTypedOperandInSpecific(Context& context,
                                         SemIR::SpecificId specific_id,
                                         SemIR::BundleId<BundleT> bundle_id)
    -> SemIR::BundleId<BundleT> {
  auto bundle_tuple = context.bundles().GetAsTuple(bundle_id);
  BundleT refined_bundle = std::apply(
      [&](auto... bundle_fields) {
        // This can't actually recurse, because bundles can't contain bundle
        // IDs.
        return BundleT{RefineTypedOperandInSpecific(context, specific_id,
                                                    bundle_fields)...};
      },
      bundle_tuple);
  return context.bundles().AddCanonical(refined_bundle);
}

// Dynamically dispatched wrapper for RefineTypedOperandInSpecific.
static auto RefineOperandInSpecific(Context& context,
                                    SemIR::SpecificId specific_id,
                                    SemIR::IdAndKind arg) -> int32_t {
  return arg.Dispatch<int32_t>([&](auto id) {
    return SemIR::ToRaw(RefineTypedOperandInSpecific(context, specific_id, id));
  });
}

auto Internal::RefineOperandsInSpecific(Context& context,
                                        SemIR::SpecificId specific_id,
                                        SemIR::Inst action) -> SemIR::Inst {
  auto arg0 =
      RefineOperandInSpecific(context, specific_id, action.arg0_and_kind());
  auto arg1 =
      RefineOperandInSpecific(context, specific_id, action.arg1_and_kind());
  action.SetArgs(arg0, arg1);
  return action;
}

auto Internal::BeginPerformDelayedAction(Context& context) -> void {
  // Push an `InstBlock` to hold any instructions created by the action.
  // Note that we assume that actions don't need to create multiple blocks. If
  // this changes, we should push a region too.
  context.inst_block_stack().Push();
  context.pattern_block_stack().Push();
}

auto Internal::EndPerformDelayedAction(Context& context,
                                       SemIR::InstId result_id)
    -> SemIR::InstId {
  // If the only created instruction is the result, then we can use it directly.
  auto contents = context.inst_block_stack().PeekCurrentBlockContents();
  auto pattern_contents =
      context.pattern_block_stack().PeekCurrentBlockContents();
  if ((contents == llvm::ArrayRef(result_id) && pattern_contents.empty()) ||
      (pattern_contents == llvm::ArrayRef(result_id) && contents.empty())) {
    context.inst_block_stack().PopAndDiscard();
    context.pattern_block_stack().PopAndDiscard();
    return result_id;
  }

  // Otherwise, create a splice_block to represent the sequence of instructions
  // created by the action.
  auto block_id = SemIR::InstBlockId::None;
  if (pattern_contents.empty()) {
    block_id = context.inst_block_stack().Pop();
    context.pattern_block_stack().PopAndDiscard();
  } else {
    // TODO: pattern insts can depend on non-pattern insts, so we'll probably
    // eventually need to support actions that produce both.
    CARBON_CHECK(contents.empty());
    block_id = context.pattern_block_stack().Pop();
    context.inst_block_stack().PopAndDiscard();
  }
  auto result = context.insts().GetWithLocId(result_id);
  return AddInstInNoBlock(context, result.loc_id,
                          SemIR::SpliceBlock{.type_id = result.inst.type_id(),
                                             .block_id = block_id,
                                             .result_id = result_id});
}

}  // namespace Carbon::Check
