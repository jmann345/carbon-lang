// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/pointer_dereference.h"

#include "toolchain/check/action.h"
#include "toolchain/check/context.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/diagnostic_helpers.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/type.h"
#include "toolchain/sem_ir/expr_info.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

auto IsOpaqueTemplateDependentType(Context& context, SemIR::TypeId type_id)
    -> bool {
  // A qualifier does not tell what kind of type is qualified: `const T` is as
  // opaque as `T`.
  type_id = context.types().GetUnqualifiedType(type_id);
  if (OperandDependence(context, type_id) !=
      SemIR::ConstantDependence::Template) {
    return false;
  }
  // A template parameter, the type of a dependent operation's result, or a
  // type that a dependent operation produces, such as `T.Elem`.
  return context.types()
      .IsOneOf<SemIR::SymbolicBinding, SemIR::FacetAccessType,
               SemIR::TypeOfInst, SemIR::SpliceInst>(type_id);
}

// Diagnoses a dereference of a value of a non-pointer type.
static auto DiagnoseNotPointer(Context& context, SemIR::LocId loc_id,
                               PointerDereferenceKind kind,
                               SemIR::TypeId not_pointer_type_id) -> void {
  // TODO: Pass in the expression we're trying to dereference to produce a
  // better diagnostic.
  if (kind == PointerDereferenceKind::Arrow) {
    CARBON_DIAGNOSTIC(ArrowOperatorOfNonPointer, Error,
                      "cannot apply `->` operator to non-pointer type {0}",
                      SemIR::TypeId);
    context.emitter().Emit(LocIdForDiagnostics::TokenOnly(loc_id),
                           ArrowOperatorOfNonPointer, not_pointer_type_id);
    return;
  }
  CARBON_DIAGNOSTIC(DerefOfNonPointer, Error,
                    "cannot dereference operand of non-pointer type {0}",
                    SemIR::TypeId);
  auto builder =
      context.emitter().Build(LocIdForDiagnostics::TokenOnly(loc_id),
                              DerefOfNonPointer, not_pointer_type_id);
  // TODO: Check for any facet here, rather than only a type.
  if (not_pointer_type_id == SemIR::TypeType::TypeId) {
    CARBON_DIAGNOSTIC(
        DerefOfType, Note,
        "to form a pointer type, write the `*` after the pointee type");
    builder.Note(LocIdForDiagnostics::TokenOnly(loc_id), DerefOfType);
  }
  builder.Emit();
}

auto PerformPointerDereference(Context& context, SemIR::LocId loc_id,
                               SemIR::InstId base_id,
                               PointerDereferenceKind kind) -> SemIR::InstId {
  // Proposal 2200: a dereference of a template-dependent operand whose type's
  // kind is not known yet is checked when the template is instantiated.
  if (IsOpaqueTemplateDependentType(context,
                                    context.insts().Get(base_id).type_id())) {
    return AddDependentActionSplice<SemIR::PointerDereferenceAction>(
        context, loc_id,
        {.type_id = SemIR::InstType::TypeId,
         .pointer_id = base_id,
         .is_arrow =
             SemIR::BoolValue::From(kind == PointerDereferenceKind::Arrow)},
        SemIR::TypeInstId::None);
  }
  // TODO: Once we have a finalized design for a pointer interface, use
  //
  //   HandleUnaryOperator(context, loc_id, {"Pointer", "Dereference"});
  //
  // to convert to a pointer value.
  base_id = ConvertToValueExpr(context, base_id);
  auto type_id = context.types().GetUnqualifiedType(
      context.insts().Get(base_id).type_id());
  auto result_type_id = SemIR::ErrorInst::TypeId;
  if (auto pointer_type =
          context.types().TryGetAs<SemIR::PointerType>(type_id)) {
    result_type_id =
        context.types().GetTypeIdForTypeInstId(pointer_type->pointee_id);
  } else if (type_id != SemIR::ErrorInst::TypeId) {
    DiagnoseNotPointer(context, loc_id, kind, type_id);
  }
  return AddInst<SemIR::Deref>(
      context, loc_id, {.type_id = result_type_id, .pointer_id = base_id});
}

auto PerformAction(Context& context, SemIR::LocId loc_id,
                   SemIR::PointerDereferenceAction action) -> SemIR::InstId {
  return PerformPointerDereference(context, loc_id, action.pointer_id,
                                   action.is_arrow.ToBool()
                                       ? PointerDereferenceKind::Arrow
                                       : PointerDereferenceKind::Star);
}

auto PerformAddrOf(Context& context, SemIR::LocId loc_id,
                   SemIR::InstId operand_id) -> SemIR::InstId {
  auto category = SemIR::GetExprCategory(context.sem_ir(), operand_id);
  // Proposal 2200: whether a template-dependent operand is a durable
  // reference is known when the template is instantiated.
  if (category == SemIR::ExprCategory::Dependent &&
      IsOpaqueTemplateDependentType(
          context, context.insts().Get(operand_id).type_id())) {
    return AddDependentActionSplice<SemIR::AddrOfAction>(
        context, loc_id,
        {.type_id = SemIR::InstType::TypeId, .lvalue_id = operand_id},
        SemIR::TypeInstId::None);
  }
  auto type_id = context.insts().Get(operand_id).type_id();
  // Only durable reference expressions can have their address taken.
  switch (category) {
    case SemIR::ExprCategory::DurableRef:
    case SemIR::ExprCategory::Error:
      break;
    default:
      CARBON_DIAGNOSTIC(AddrOfNonRef, Error,
                        "cannot take the address of non-reference expression");
      context.emitter().Emit(LocIdForDiagnostics::TokenOnly(loc_id),
                             AddrOfNonRef);
      operand_id = SemIR::ErrorInst::InstId;
      break;
  }
  // TODO: Preserve spelling of type of operand where possible.
  auto type_inst_id = context.types().GetTypeInstId(type_id);
  return AddInst<SemIR::AddrOf>(
      context, loc_id,
      SemIR::AddrOf{.type_id = GetPointerType(context, type_inst_id),
                    .lvalue_id = operand_id});
}

auto PerformAction(Context& context, SemIR::LocId loc_id,
                   SemIR::AddrOfAction action) -> SemIR::InstId {
  return PerformAddrOf(context, loc_id, action.lvalue_id);
}

}  // namespace Carbon::Check
