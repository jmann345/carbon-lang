// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <string>

#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
#include "llvm/Support/Casting.h"
#include "toolchain/lower/function_context.h"
#include "toolchain/lower/type.h"
#include "toolchain/sem_ir/builtin_function_kind.h"
#include "toolchain/sem_ir/entry_point.h"
#include "toolchain/sem_ir/expr_info.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/stringify.h"
#include "toolchain/sem_ir/type_info.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Lower {

// Returns whether this instruction names a namespace.
static auto IsNamespace(FunctionContext& context, SemIR::InstId inst_id)
    -> bool {
  // Note, we don't use context.GetTypeOfInst here. An instruction can't change
  // from being a non-namespace in a generic to being a namespace in a specific,
  // because namespace names are not first-class.
  auto type_inst_id = context.sem_ir().types().GetTypeInstId(
      context.sem_ir().insts().Get(inst_id).type_id());
  return type_inst_id == SemIR::NamespaceType::TypeInstId;
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::AddrOf inst) -> void {
  context.SetLocal(inst_id, context.GetValue(inst.lvalue_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::ArrayIndex inst) -> void {
  auto* array_value = context.GetValue(inst.array_id);
  auto* llvm_type = context.GetTypeOfInst(inst.array_id);

  // The index in an `ArrayIndex` can be of any integer type, including
  // IntLiteral. If it is an IntLiteral, its value representation is empty, so
  // create a ConstantInt from its SemIR value directly.
  llvm::Value* index;
  auto index_type = context.GetTypeIdOfInst(inst.index_id);
  if (index_type.file->types().GetTypeInstId(index_type.type_id) ==
      SemIR::IntLiteralType::TypeInstId) {
    auto value = context.sem_ir().insts().GetAs<SemIR::IntValue>(
        context.sem_ir().constant_values().GetConstantInstId(inst.index_id));
    const auto& apint_value = context.sem_ir().ints().Get(value.int_id);
    context.AddIntToCurrentFingerprint(apint_value.getSExtValue());
    index = llvm::ConstantInt::get(context.llvm_context(), apint_value);
  } else {
    context.AddIntToCurrentFingerprint(-1);
    index = context.GetValue(inst.index_id);
  }

  llvm::Value* indexes[2] = {
      llvm::ConstantInt::get(llvm::Type::getInt32Ty(context.llvm_context()), 0),
      index};
  context.SetLocal(inst_id,
                   context.builder().CreateInBoundsGEP(llvm_type, array_value,
                                                       indexes, "array.index"));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::ArrayInit inst) -> void {
  // The result of initialization is the return slot of the initializer.
  context.SetLocal(inst_id, context.GetValue(inst.dest_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::AsCompatible inst) -> void {
  context.SetLocal(inst_id, context.GetValue(inst.source_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::Assign inst) -> void {
  if (SemIR::GetExprCategory(context.sem_ir(), inst.rhs_id) !=
      SemIR::ExprCategory::InPlaceInitializing) {
    context.InitializeStorage(context.GetTypeIdOfInst(inst.lhs_id), inst.lhs_id,
                              inst.rhs_id);
  }
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::AliasBinding inst) -> void {
  if (IsNamespace(context, inst_id)) {
    return;
  }

  context.SetLocal(inst_id, context.GetValue(inst.value_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::ExportDecl inst) -> void {
  if (IsNamespace(context, inst_id)) {
    return;
  }

  context.SetLocal(inst_id, context.GetValue(inst.value_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::SymbolicBinding inst) -> void {
  context.SetLocal(inst_id, context.GetValue(inst.value_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::WrapperBinding inst) -> void {
  context.SetLocal(inst_id, context.GetValue(inst.value_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::BlockArg inst) -> void {
  context.SetLocal(
      inst_id,
      context.GetBlockArg(inst.block_id, context.GetTypeIdOfInst(inst_id)));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::BoundMethod inst) -> void {
  // Propagate just the function; the object is separately provided to the
  // enclosing call as an implicit argument.
  context.SetLocal(inst_id, context.GetValue(inst.function_decl_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::Branch inst) -> void {
  // Opportunistically avoid creating a BasicBlock that contains just a branch.
  // TODO: Don't do this if it would remove a loop preheader block.
  llvm::BasicBlock* block = context.builder().GetInsertBlock();
  if (block->empty() && context.TryToReuseBlock(inst.target_id, block)) {
    // Reuse this block as the branch target.
  } else {
    context.builder().CreateBr(context.GetBlock(inst.target_id));
  }

  context.builder().ClearInsertionPoint();
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::BranchIf inst) -> void {
  llvm::Value* cond = context.GetValue(inst.cond_id);
  llvm::BasicBlock* then_block = context.GetBlock(inst.target_id);
  llvm::BasicBlock* else_block = context.MakeSyntheticBlock();
  context.builder().CreateCondBr(cond, then_block, else_block);
  context.builder().SetInsertPoint(else_block);
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::BranchWithArg inst) -> void {
  llvm::Value* arg = context.GetValue(inst.arg_id);
  auto arg_type = context.GetTypeIdOfInst(inst.arg_id);

  // Opportunistically avoid creating a BasicBlock that contains just a branch.
  // We only do this for a block that we know will only have a single
  // predecessor, so that we can correctly populate the predecessors of the
  // PHINode.
  llvm::BasicBlock* block = context.builder().GetInsertBlock();
  llvm::BasicBlock* phi_predecessor = block;
  if (block->empty() && context.IsCurrentSyntheticBlock(block) &&
      context.TryToReuseBlock(inst.target_id, block)) {
    // Reuse this block as the branch target.
    phi_predecessor = block->getSinglePredecessor();
    CARBON_CHECK(phi_predecessor,
                 "Synthetic block did not have a single predecessor");
  } else {
    context.builder().CreateBr(context.GetBlock(inst.target_id));
  }

  context.GetBlockArg(inst.target_id, arg_type)
      ->addIncoming(arg, phi_predecessor);
  context.builder().ClearInsertionPoint();
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::Converted inst) -> void {
  context.SetLocal(inst_id, context.GetValue(inst.result_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::Deref inst) -> void {
  context.SetLocal(inst_id, context.GetValue(inst.pointer_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::FacetAccessType /*inst*/) -> void {
  context.SetLocal(inst_id, context.GetTypeAsValue());
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::FacetValue /*inst*/) -> void {
  context.SetLocal(inst_id, context.GetTypeAsValue());
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::InPlaceInit inst) -> void {
  context.InitializeStorage(context.GetTypeIdOfInst(inst.dest_id), inst.dest_id,
                            inst.src_id);
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::NameBindingDecl /*inst*/) -> void {
  // A NameBindingDecl is lowered by pattern matching.
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::NameRef inst) -> void {
  if (IsNamespace(context, inst_id)) {
    return;
  }

  auto inner_inst_id = inst.value_id;

  // `GetValue` has no direct value for package-scope value bindings because
  // they aren't constants, and they aren't global variables, so we peek
  // through bindings here to directly access the bound value. When the bound
  // value isn't a global variable or constant either — a file-scope `let`
  // bound to a runtime value — `GetValue` serves the reference from the
  // binding's promoted backing global, for PACKAGE-scope bindings whose
  // value representation is a copy of the object representation (loaded) or
  // a pointer to it (the global's address served as the value) (W-069;
  // `FunctionContext::TryEmitGlobalLetValue`). Class-scope `static` bindings
  // (out of W-069's scope) and namespace-scope bindings (excluded by the
  // registry's Package-scope test) still ride the old path here and hit
  // `GetValue`'s missing-value CHECK if referenced.
  if (auto bind_name =
          context.sem_ir().insts().TryGetAs<SemIR::AnyBinding>(inner_inst_id)) {
    inner_inst_id = bind_name->value_id;
  }

  context.SetLocal(inst_id, context.GetValue(inner_inst_id));
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::OutParam /*inst*/) -> void {
  // Parameters are lowered by `BuildFunctionDefinition`.
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::RefParam /*inst*/) -> void {
  // Parameters are lowered by `BuildFunctionDefinition`.
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::ValueParam /*inst*/) -> void {
  // Parameters are lowered by `BuildFunctionDefinition`.
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::RefTagExpr inst) -> void {
  context.SetLocal(inst_id, context.GetValue(inst.expr_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::ReturnSlot inst) -> void {
  context.SetLocal(inst_id, context.GetValue(inst.storage_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::Return /*inst*/) -> void {
  // The 'Run()' entry point does not need to specify a return type, but
  // the C runtime and system ABI expects the entry point to return an `int`.
  // In this situation we modify the lowered IR to return `0`
  // with the expected LLVM type that corresponds to the `int` type.
  if (SemIR::IsEntryPoint(context.specific_sem_ir(),
                          context.specific_sem_ir_function_id())) {
    context.builder().CreateRet(context.builder().getInt32(0));
    return;
  }
  context.builder().CreateRetVoid();
}

// Emits the exit-code epilogue of a `Main.Run` declared `-> Core.Result(T, E)`
// (decision D10 of docs/design/error_handling.md, "Entry point") in place of
// an in-place return's `ret void`: `.Ok(())` exits 0, `.Ok(code)` exits
// `code`, and `.Err(e)` writes a diagnostic naming `E` to stderr and exits 1.
// `result_slot` is the local alloca the return slot was bound to
// (`FileContext::BuildFunctionBody`), already initialized with the returned
// value. A choice lowers as `<{ <{ disc, pad }>, [P x i8] }>` with the
// discriminant stored as an `i8` (`Ok` = 0, `Err` = 1: the declaration order in
// core/prelude/types/result.carbon) and every payload tuple at offset 0 of the
// region, so the `Ok(i32)` payload is an `i32` load from the region.
static auto EmitEntryPointResultEpilogue(
    FunctionContext& context, FunctionContext::TypeInFile result_type,
    llvm::Value* result_slot) -> void {
  const auto& sem_ir = *result_type.file;
  auto class_type = sem_ir.types().GetAs<SemIR::ClassType>(result_type.type_id);
  auto type_info = SemIR::RecognizedTypeInfo::ForType(sem_ir, class_type);
  CARBON_CHECK(type_info.kind == SemIR::RecognizedTypeInfo::Result);
  auto args = sem_ir.inst_blocks().Get(type_info.args_id);
  CARBON_CHECK(args.size() == 2);
  auto type_arg = [&](SemIR::InstId arg_id) -> SemIR::InstId {
    if (auto facet = sem_ir.insts().TryGetAs<SemIR::FacetValue>(arg_id)) {
      return facet->type_inst_id;
    }
    return arg_id;
  };
  auto success_type_id =
      sem_ir.types().GetTypeIdForTypeInstId(type_arg(args[0]));
  auto error_type_inst_id = type_arg(args[1]);

  auto& builder = context.builder();
  auto* llvm_result_type = context.GetType(result_type);
  auto* i8_type = builder.getInt8Ty();
  auto* i32_type = builder.getInt32Ty();
  auto* i64_type = builder.getInt64Ty();

  auto* discriminant =
      builder.CreateLoad(i8_type,
                         builder.CreateStructGEP(llvm_result_type, result_slot,
                                                 0, "run.result.discriminant"),
                         "run.result.disc");
  auto* is_ok = builder.CreateICmpEQ(
      discriminant, llvm::ConstantInt::get(i8_type, 0), "run.result.is_ok");
  auto* ok_block = llvm::BasicBlock::Create(
      context.llvm_context(), "run.result.ok", &context.llvm_function());
  auto* err_block = llvm::BasicBlock::Create(
      context.llvm_context(), "run.result.err", &context.llvm_function());
  builder.CreateCondBr(is_ok, ok_block, err_block);

  // `.Ok(())` exits 0; `.Ok(code)` exits `code`. The checker admits exactly
  // these two success types (`IsValidEntryPointReturnType`).
  builder.SetInsertPoint(ok_block);
  if (sem_ir.types().Is<SemIR::TupleType>(success_type_id)) {
    builder.CreateRet(builder.getInt32(0));
  } else {
    auto* payload = builder.CreateStructGEP(llvm_result_type, result_slot, 1,
                                            "run.result.payload");
    builder.CreateRet(builder.CreateLoad(i32_type, payload, "run.result.code"));
  }

  // `.Err(e)`: `write(2, message, length)` — stderr is unbuffered, and no
  // linkable Carbon runtime object exists to call — then exit 1. The message
  // names `E`; `Cpp.Exception`'s own message is not printed in 0.1.
  builder.SetInsertPoint(err_block);
  auto* ptr_type = llvm::PointerType::get(context.llvm_context(), 0);
  llvm::FunctionCallee write = context.llvm_module().getOrInsertFunction(
      "write", i64_type, i32_type, ptr_type, i64_type);
  std::string message =
      "carbon: `Main.Run` returned `.Err` of type `" +
      SemIR::StringifyConstantInst(sem_ir, error_type_inst_id) +
      "`; exiting with code 1\n";
  builder.CreateCall(write, {builder.getInt32(2),
                             context.entry_point_result_err_message(message),
                             llvm::ConstantInt::get(i64_type, message.size())});
  builder.CreateRet(builder.getInt32(1));
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::ReturnExpr inst) -> void {
  auto expr_cat = SemIR::GetExprCategory(context.sem_ir(), inst.expr_id);
  switch (expr_cat) {
    case SemIR::ExprCategory::EphemeralRef:
    case SemIR::ExprCategory::DurableRef:
      // Reference return.
      context.builder().CreateRet(context.GetValue(inst.expr_id));
      return;

    case SemIR::ExprCategory::Value:
      // Return of a `returned var`.
    case SemIR::ExprCategory::ReprInitializing:
    case SemIR::ExprCategory::InPlaceInitializing:
      // Initializing return.
      break;

    case SemIR::ExprCategory::Mixed:
    case SemIR::ExprCategory::RefTagged:
    case SemIR::ExprCategory::NotExpr:
    case SemIR::ExprCategory::Error:
    case SemIR::ExprCategory::Pattern:
    case SemIR::ExprCategory::Dependent:
      CARBON_FATAL("Unexpected category for `return` expression");
  }

  auto result_type = context.GetTypeIdOfInst(inst.expr_id);
  switch (context.GetInitRepr(result_type).kind) {
    case SemIR::InitRepr::None:
      // Nothing to return.
      context.builder().CreateRetVoid();
      return;
    case SemIR::InitRepr::InPlace:
      CARBON_CHECK(context.GetValueRepr(result_type).repr.kind ==
                       SemIR::ValueRepr::Pointer,
                   "TODO: Add support for ReturnExpr with custom value repr");
      // TODO: find a way to avoid the redundant call to GetInitRepr inside
      // InitializeStorage.
      context.InitializeStorage(result_type, inst.dest_id, inst.expr_id);
      // A `Result`-returning `Main.Run` returns its exit code instead (D10).
      if (GetEntryPointResultTypeId(context.specific_sem_ir(),
                                    context.specific_sem_ir_function_id())
              .has_value()) {
        EmitEntryPointResultEpilogue(context, result_type,
                                     context.GetValue(inst.dest_id));
        return;
      }
      context.builder().CreateRetVoid();
      return;
    case SemIR::InitRepr::ByCopy: {
      auto* value = context.GetValue(inst.expr_id);
      if (expr_cat == SemIR::ExprCategory::InPlaceInitializing) {
        value =
            context.builder().CreateLoad(context.GetType(result_type), value);
      }
      context.builder().CreateRet(value);
      return;
    }
    case SemIR::InitRepr::Abstract:
      CARBON_FATAL("Lowering return of abstract type {0}",
                   result_type.file->types().GetAsInst(result_type.type_id));
    case SemIR::InitRepr::Incomplete:
      CARBON_FATAL("Lowering return of incomplete type {0}",
                   result_type.file->types().GetAsInst(result_type.type_id));
    case SemIR::InitRepr::Dependent:
      CARBON_FATAL("Lowering return of dependent type {0}",
                   result_type.file->types().GetAsInst(result_type.type_id));
  }
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::RefReturn /*inst*/) -> void {
  // A `RefReturn` is a placeholder that represents the absence of a storage
  // location, so it should never actually be used, but in some cases it will
  // be propagated, so we poison it.
  context.SetLocal(inst_id,
                   llvm::PoisonValue::get(context.GetTypeOfInst(inst_id)));
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::SpecificFunction /*inst*/) -> void {
  // Nothing to do. This value should never be consumed.
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::SpecificImplFunction /*inst*/) -> void {
  // Nothing to do. This value should never be consumed.
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::SpliceBlock inst) -> void {
  context.LowerBlockContents(inst.block_id);
  context.SetLocal(inst_id, context.GetValue(inst.result_id));
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::SpliceInst /*inst*/) -> void {
  // TODO: Get the constant value of the spliced instruction from the current
  // specific, and lower the instruction in that constant value.
  CARBON_FATAL("Template lowering not implemented yet");
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::TypeLiteral inst) -> void {
  context.SetLocal(inst_id, context.GetValue(inst.value_id));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::UnaryOperatorNot inst) -> void {
  context.SetLocal(
      inst_id, context.builder().CreateNot(context.GetValue(inst.operand_id)));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::UpdateInit inst) -> void {
  // Ensure that our subordinate initializations have been performed. They may
  // have been skipped if they were constant.
  context.InitializeStorage(inst.base_init_id);
  context.InitializeStorage(inst.update_init_id);

  // TODO: Add a helper to poison a value slot.
  context.SetLocal(inst_id,
                   llvm::PoisonValue::get(context.GetTypeOfInst(inst_id)));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::ValueReturn /*inst*/) -> void {
  // A `ValueReturn` is a placeholder that represents the absence of a storage
  // location, so it should never actually be used, but in some cases it will
  // be propagated, so we poison it.
  context.SetLocal(inst_id,
                   llvm::PoisonValue::get(context.GetTypeOfInst(inst_id)));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::VarStorage /* inst */) -> void {
  context.SetLocal(inst_id,
                   context.CreateAlloca(context.GetTypeIdOfInst(inst_id)));
}

}  // namespace Carbon::Lower
