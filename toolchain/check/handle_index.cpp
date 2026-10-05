// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <optional>

#include "toolchain/base/kind_switch.h"
#include "toolchain/check/context.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/facet_type.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/impl_lookup.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/operator.h"
#include "toolchain/check/type.h"
#include "toolchain/diagnostics/diagnostic.h"
#include "toolchain/sem_ir/expr_info.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

auto HandleParseNode(Context& /*context*/, Parse::IndexExprStartId /*node_id*/)
    -> bool {
  // Leave the expression on the stack for IndexExpr.
  return true;
}

// Performs an index with base expression `operand_inst_id` and
// `operand_type_id` for types that are not an array. This checks if
// the base expression implements the `IndexWith` interface; if so, uses the
// `At` associative method, otherwise prints a diagnostic.
static auto PerformIndexWith(Context& context, Parse::NodeId node_id,
                             SemIR::InstId operand_inst_id,
                             SemIR::InstId index_inst_id) -> SemIR::InstId {
  SemIR::InstId args[] = {context.types().GetTypeInstId(
      context.insts().Get(index_inst_id).type_id())};
  Operator op{.interface_name = CoreIdentifier::IndexWith,
              .interface_args_ref = args,
              .op_name = CoreIdentifier::At};
  return BuildBinaryOperator(context, node_id, op, operand_inst_id,
                             index_inst_id);
}

// Fork (SL-1, fork/slices/plan.md R-5, amended 2026-10-05). Returns whether
// `operand_type_id` implements `Core.IndexWith(subscript_type_id)`, from a
// non-diagnosing impl lookup, or `nullopt` when the question cannot be asked
// without diagnosing: no `Core.IndexWith`, or one that is not a generic
// interface over a single `type` parameter (the shapes
// operators/overloaded/index.carbon pins), which the ordinary dispatch then
// reports exactly once. The probe emits nothing and leaves no instructions:
// the facet type is built from the interface and a specific (a constant), and
// the lookup's scratch instructions are discarded. It does share the
// dispatch's file-level footprint — the `Core.IndexWith` name lookup loads
// (or poisons) that name in the `Core` scope exactly as `GetOperatorOpFunction`
// does — so callers probe only where the dispatch itself would look the name
// up (never for an erroneous operand, which `BuildBinaryOperator` rejects
// before any lookup).
static auto HasIndexWithImpl(Context& context, SemIR::LocId loc_id,
                             SemIR::TypeId operand_type_id,
                             SemIR::TypeId subscript_type_id)
    -> std::optional<bool> {
  auto interface_inst_id =
      TryLookupNameInCore(context, loc_id, CoreIdentifier::IndexWith);
  if (!interface_inst_id.has_value()) {
    return std::nullopt;
  }
  auto generic_interface =
      context.types().TryGetAs<SemIR::GenericInterfaceType>(
          context.insts().Get(interface_inst_id).type_id());
  if (!generic_interface ||
      generic_interface->enclosing_specific_id.has_value()) {
    return std::nullopt;
  }
  const auto& interface =
      context.interfaces().Get(generic_interface->interface_id);
  if (!interface.generic_id.has_value()) {
    return std::nullopt;
  }
  auto bindings = context.inst_blocks().Get(
      context.generics().Get(interface.generic_id).bindings_id);
  if (bindings.size() != 1 ||
      context.insts().Get(bindings[0]).type_id() != SemIR::TypeType::TypeId) {
    return std::nullopt;
  }

  context.inst_block_stack().Push();
  SemIR::InstId args[] = {context.types().GetTypeInstId(subscript_type_id)};
  auto specific_id = MakeSpecific(context, loc_id, interface.generic_id, args);
  auto facet_type_const_id = EvalOrAddInst<SemIR::FacetType>(
      context, loc_id,
      FacetTypeFromInterface(context, generic_interface->interface_id,
                             specific_id));
  auto result = LookupImplWitness(
      context, loc_id, context.types().GetConstantId(operand_type_id),
      facet_type_const_id, /*diagnose=*/false);
  context.inst_block_stack().PopAndDiscard();
  return result.has_value() && !result.has_error_value();
}

// Fork (SL-1, fork/slices/plan.md R-5, amended 2026-10-05): the
// literal-subscript rule. An integer literal subscript on an operand that
// implements `IndexWith(i64)` and has no `IndexWith(Core.IntLiteral)` impl
// converts to `i64` before dispatch — the array arm's hardcoded subscript
// conversion below, decided by impl lookup. Returns the target type, or
// `nullopt` to dispatch the literal as written. A blanket `impl forall [U:
// ImplicitAs(i64)] ... as IndexWith(U)` cannot serve literals instead:
// `IntLiteral`'s `ImplicitAs(Int(To)).Convert` is compile-time only
// (`int.convert_checked`), and a runtime `subscript: U` has no constant in
// the `U = IntLiteral` specific, so that specific cannot lower
// (lower/handle_call.cpp, "Missing constant value for call to comptime-only
// function"); `Core.String`'s blanket impl lowers only because its `At` is
// itself a builtin, lowered at the call site. An operand with its own
// `IndexWith(Core.IntLiteral)` impl, and one with neither impl, dispatch as
// written, so their results and diagnostics are unchanged.
static auto LiteralSubscriptTargetType(Context& context, Parse::NodeId node_id,
                                       SemIR::TypeId operand_type_id,
                                       SemIR::TypeId literal_type_id)
    -> std::optional<SemIR::TypeId> {
  auto loc_id = SemIR::LocId(node_id);
  auto has_literal_impl =
      HasIndexWithImpl(context, loc_id, operand_type_id, literal_type_id);
  if (!has_literal_impl || *has_literal_impl) {
    return std::nullopt;
  }
  // `i64` is the class `Core.Int(64)`; forming it needs `Core.Int`. Probe
  // for the name first so a `Core` without it gets no spurious
  // `CoreNameNotFound` (the diagnosing dispatch then reports as before).
  if (!TryLookupNameInCore(context, loc_id, CoreIdentifier::Int).has_value()) {
    return std::nullopt;
  }
  // Only the type is needed; the `i64` type expression's instruction is
  // discarded. What cannot be discarded is the `Core.Int` import_ref the
  // name lookup loads into this file (and the `Int` generic's constants): a
  // file whose only integer-typed expression is a literal subscript on a
  // type with neither `IndexWith` impl gains exactly that import_ref in its
  // SemIR dump (`import_ref Core//prelude/types/int, Int, loaded`). Its
  // semantics are unchanged — the dispatch still diagnoses
  // `Core.IndexWith(Core.IntLiteral)` — and there is no way to name `i64`
  // without it; disclosed in fork/slices/plan.md R-5 (round 4).
  context.inst_block_stack().Push();
  auto i64_type_id = MakeIntType(context, node_id, SemIR::IntKind::Signed,
                                 context.ints().Add(64));
  context.inst_block_stack().PopAndDiscard();
  auto has_i64_impl =
      HasIndexWithImpl(context, loc_id, operand_type_id, i64_type_id);
  if (!has_i64_impl || !*has_i64_impl) {
    return std::nullopt;
  }
  return i64_type_id;
}

auto HandleParseNode(Context& context, Parse::IndexExprId node_id) -> bool {
  auto index_inst_id = context.node_stack().PopExpr();
  auto operand_inst_id = context.node_stack().PopExpr();
  operand_inst_id = ConvertToValueOrRefExpr(context, operand_inst_id);
  auto operand_inst = context.insts().Get(operand_inst_id);
  auto operand_type_id = operand_inst.type_id();

  CARBON_KIND_SWITCH(context.types().GetAsInst(operand_type_id)) {
    case CARBON_KIND(SemIR::ArrayType array_type): {
      auto cast_index_id = ConvertToValueOfType(
          context, SemIR::LocId(index_inst_id), index_inst_id,
          // TODO: Replace this with impl lookup rather than hardcoding `i32`.
          MakeIntType(context, node_id, SemIR::IntKind::Signed,
                      context.ints().Add(32)));
      auto array_cat =
          SemIR::GetExprCategory(context.sem_ir(), operand_inst_id);
      if (array_cat == SemIR::ExprCategory::Value) {
        // If the operand is an array value, convert it to an ephemeral
        // reference to an array so we can perform a primitive indexing into it.
        operand_inst_id = AddInst<SemIR::ValueAsRef>(
            context, node_id,
            {.type_id = operand_type_id, .value_id = operand_inst_id});
      }
      // Constant evaluation will perform a bounds check on this array indexing
      // if the index is constant.
      auto elem_id = AddInst<SemIR::ArrayIndex>(
          context, node_id,
          {.type_id = context.types().GetTypeIdForTypeInstId(
               array_type.element_type_inst_id),
           .array_id = operand_inst_id,
           .index_id = cast_index_id});
      if (array_cat != SemIR::ExprCategory::DurableRef) {
        // Indexing a durable reference gives a durable reference expression.
        // Indexing anything else gives a value expression.
        // TODO: This should be replaced by a choice between using `IndexWith`
        // and `IndirectIndexWith`.
        elem_id = ConvertToValueExpr(context, elem_id);
      }
      context.node_stack().Push(node_id, elem_id);
      return true;
    }

    default: {
      // The literal-subscript probe runs only where `PerformIndexWith` would
      // itself look `Core.IndexWith` up: `BuildBinaryOperator` exits before
      // any lookup for an erroneous operand (a namespace or function used as
      // a value, an unresolved name), and probing there would load or poison
      // the name in the `Core` scope where the dispatch never does.
      auto index_type_id = context.insts().Get(index_inst_id).type_id();
      if (operand_inst_id != SemIR::ErrorInst::InstId &&
          context.types().Is<SemIR::IntLiteralType>(index_type_id)) {
        if (auto target_type_id = LiteralSubscriptTargetType(
                context, node_id, operand_type_id, index_type_id)) {
          index_inst_id =
              ConvertToValueOfType(context, SemIR::LocId(index_inst_id),
                                   index_inst_id, *target_type_id);
        }
      }
      auto elem_id =
          PerformIndexWith(context, node_id, operand_inst_id, index_inst_id);
      context.node_stack().Push(node_id, elem_id);
      return true;
    }
  }
}

}  // namespace Carbon::Check
