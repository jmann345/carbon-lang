// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Type.h"
#include "toolchain/lower/function_context.h"
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
