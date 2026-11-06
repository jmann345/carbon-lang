// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Type.h"
#include "toolchain/lower/aggregate.h"
#include "toolchain/lower/function_context.h"
#include "toolchain/sem_ir/expr_info.h"
#include "toolchain/sem_ir/generic.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Lower {

// Fork (VA-1): a pack expansion's body is lowered once per element, the
// compile-time loop of docs/design/variadics.md, "Execution Semantics", run at
// monomorphization: each specific of a variadic function knows its arity. A
// value of a pack type is the address of its elements' value representations
// (D-VA-3), which `PackValue` and `PackExpansionExpr` write where they are
// evaluated and `PackElement` reads.

// Returns the address of the element at `index` of the pack value `storage`,
// of type `pack_type`.
static auto GetPackElementAddr(FunctionContext& context,
                               FunctionContext::TypeInFile pack_type,
                               llvm::Value* storage, uint64_t index)
    -> llvm::Value* {
  auto value_repr = context.GetValueRepr(pack_type);
  CARBON_CHECK(value_repr.repr.kind == SemIR::ValueRepr::Pointer,
               "Pack value not passed by address");
  // Fork (VA-2): the index is a constant in each iteration, so this also
  // indexes the tuple-like storage of a pack of different types.
  return context.builder().CreateConstInBoundsGEP2_32(
      context.GetType(value_repr.type().GetPointeeType()), storage, 0, index,
      "pack.elem");
}

// Allocates the storage of a value of the pack type `pack_type`.
static auto CreatePackStorage(FunctionContext& context,
                              FunctionContext::TypeInFile pack_type)
    -> llvm::Value* {
  return context.CreateAlloca(
      context.GetValueRepr(pack_type).type().GetPointeeType(), "pack");
}

// Stores the value of `value_id` as the element at `index` of the pack value
// `storage`, of type `pack_type`.
static auto StorePackElement(FunctionContext& context,
                             FunctionContext::TypeInFile pack_type,
                             llvm::Value* storage, uint64_t index,
                             SemIR::InstId value_id) -> void {
  context.StoreObject(
      context.GetValueRepr(context.GetTypeIdOfInst(value_id)).type(),
      context.GetValue(value_id),
      GetPackElementAddr(context, pack_type, storage, index));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackElement inst) -> void {
  // Fork (VA-2, D-VA2-9): an element of a tuple of one pack segment is read
  // or addressed as a `TupleAccess` is, at the pack index.
  auto aggregate_type = context.GetTypeIdOfInst(inst.pack_id);
  if (aggregate_type.file->types().Is<SemIR::TupleType>(
          aggregate_type.type_id)) {
    auto index = context.pack_index();
    if (auto* storage = context.pack_segment_storage(inst.pack_id)) {
      context.SetLocal(inst_id, context.builder().CreateStructGEP(
                                    context.GetType(aggregate_type), storage,
                                    index, "tuple.elem"));
      return;
    }
    context.SetLocal(inst_id, GetAggregateElement(context, inst.pack_id,
                                                  SemIR::ElementIndex(index),
                                                  inst_id, "tuple.elem"));
    return;
  }

  // The element is always the one at the current pack index.
  auto* addr =
      GetPackElementAddr(context, context.GetTypeIdOfInst(inst.pack_id),
                         context.GetValue(inst.pack_id), context.pack_index());
  context.SetLocal(
      inst_id,
      context.LoadObject(
          context.GetValueRepr(context.GetTypeIdOfInst(inst_id)).type(), addr,
          "pack.elem.load"));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackExpansionExpr inst) -> void {
  // Fork (VA-2, D-VA2-9): a pack of the elements of a value of a tuple of one
  // segment, as a `let` binds, is that value: both are the address of the
  // elements' value representations, so no element is copied. A 1-tuple's
  // value, held by copy, is stored element by element below.
  if (auto element = context.sem_ir().insts().TryGetAs<SemIR::PackElement>(
          inst.result_id)) {
    auto source_type = context.GetTypeIdOfInst(element->pack_id);
    if (source_type.file->types().Is<SemIR::TupleType>(source_type.type_id) &&
        SemIR::GetExprCategory(context.sem_ir(), element->pack_id) ==
            SemIR::ExprCategory::Value &&
        context.GetValueRepr(source_type).repr.kind ==
            SemIR::ValueRepr::Pointer) {
      context.SetLocal(inst_id, context.GetValue(element->pack_id));
      return;
    }
  }

  // The pack has one element per iteration, each the iteration's result.
  auto pack_type = context.GetTypeIdOfInst(inst_id);
  auto arity = pack_type.file->GetZExtIntValue(
      pack_type.file->types()
          .GetAs<SemIR::PackType>(pack_type.type_id)
          .arity_id);
  CARBON_CHECK(arity, "Pack of unknown arity");
  auto* storage = CreatePackStorage(context, pack_type);
  context.LowerPackExpansionBody(
      *arity, inst.body_block_id, [&](uint64_t index) {
        StorePackElement(context, pack_type, storage, index, inst.result_id);
      });
  context.SetLocal(inst_id, storage);
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::PackExpansionStatement inst) -> void {
  auto [arity_ir, arity_const_id] = GetConstantValueInSpecific(
      context.specific_sem_ir(), context.specific_id(), context.sem_ir(),
      inst.arity_id);
  CARBON_CHECK(arity_const_id.is_concrete(), "Pack arity {0} in {1}",
               inst.arity_id, context.specific_id());
  auto arity = arity_ir->GetZExtIntValue(
      arity_ir->constant_values().GetInstId(arity_const_id));
  CARBON_CHECK(arity, "Pack arity {0} is not an integer", inst.arity_id);
  context.LowerPackExpansionBody(*arity, inst.body_block_id);
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::PackExpansionNext /*inst*/) -> void {
  // Fork (VA-2, D-VA2-11): the iteration ends, and control continues where the
  // next one starts, or after the expansion.
  context.builder().CreateBr(context.pack_expansion_next_block());
  context.builder().ClearInsertionPoint();
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackSegmentInit inst) -> void {
  // Fork (VA-2, D-VA2-9): the body initializes the destination's element at
  // the pack index, once per element of the specific's tuple, as a
  // `TupleInit` initializes its elements.
  auto tuple_type = context.GetTypeIdOfInst(inst_id);
  auto elements = tuple_type.file->inst_blocks().Get(
      tuple_type.file->types()
          .GetAs<SemIR::TupleType>(tuple_type.type_id)
          .type_elements_id);
  auto init_repr = context.GetInitRepr(tuple_type);
  if (init_repr.kind == SemIR::InitRepr::InPlace) {
    context.LowerPackExpansionBody(elements.size(), inst.body_block_id);
    context.SetLocal(inst_id,
                     llvm::PoisonValue::get(context.GetType(tuple_type)));
    return;
  }
  // A tuple initialized by copy, a 1-tuple, or one with nothing to
  // initialize has no storage of its own: its element is initialized in a
  // temporary, which is the result's object representation.
  CARBON_CHECK(init_repr.kind == SemIR::InitRepr::ByCopy ||
                   init_repr.kind == SemIR::InitRepr::None,
               "Pack segment initialization of {0}",
               tuple_type.file->types().GetAsInst(tuple_type.type_id));
  auto* storage = context.CreateAlloca(tuple_type, "tuple.init");
  context.set_pack_segment_storage(inst.dest_id, storage);
  context.LowerPackExpansionBody(elements.size(), inst.body_block_id);
  context.set_pack_segment_storage(SemIR::InstId::None, nullptr);
  context.SetLocal(inst_id,
                   init_repr.kind == SemIR::InitRepr::ByCopy
                       ? context.LoadObject(tuple_type, storage, "tuple.init")
                       : llvm::PoisonValue::get(context.GetType(tuple_type)));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackIndex /*inst*/) -> void {
  context.SetLocal(inst_id, llvm::ConstantInt::get(
                                llvm::Type::getInt64Ty(context.llvm_context()),
                                context.pack_index()));
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackLiteral /*inst*/) -> void {
  // A PackLiteral is always converted to a PackValue, element by element.
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackValue inst) -> void {
  auto pack_type = context.GetTypeIdOfInst(inst_id);
  auto* storage = CreatePackStorage(context, pack_type);
  for (auto [index, element_id] :
       llvm::enumerate(context.sem_ir().inst_blocks().Get(inst.elements_id))) {
    StorePackElement(context, pack_type, storage, index, element_id);
  }
  context.SetLocal(inst_id, storage);
}

}  // namespace Carbon::Lower
