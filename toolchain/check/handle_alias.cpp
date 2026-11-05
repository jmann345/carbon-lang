// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/context.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/eval.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/modifiers.h"
#include "toolchain/check/name_component.h"
#include "toolchain/parse/node_ids.h"
#include "toolchain/sem_ir/expr_info.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

auto HandleParseNode(Context& context, Parse::AliasIntroducerId /*node_id*/)
    -> bool {
  // Aliases can't be generic, but we might have parsed a generic parameter in
  // their name, so enter a generic scope just in case.
  StartGenericDecl(context);
  // Optional modifiers and the name follow.
  context.decl_introducer_state_stack().Push<Lex::TokenKind::Alias>();
  context.decl_name_stack().PushScopeAndStartName();
  return true;
}

auto HandleParseNode(Context& /*context*/,
                     Parse::AliasInitializerId /*node_id*/) -> bool {
  return true;
}

auto HandleParseNode(Context& context, Parse::AliasId /*node_id*/) -> bool {
  auto [expr_node, expr_id] = context.node_stack().PopExprWithNodeId();

  bool diagnosed_params = false;
  auto name_context =
      context.decl_name_stack().FinishName(PopNameComponentWithoutParams(
          context, Lex::TokenKind::Alias, &diagnosed_params));
  if (diagnosed_params) {
    // If the alias had generic parameters, they could be SymbolicBindings which
    // then appear in the `expr_id`. Using those elsewhere is then invalid and
    // creates invalid states in the toolchain.
    expr_id = SemIR::ErrorInst::InstId;
  }

  // An alias is never generic, but in a generic its value is part of that
  // generic: `alias B = T.Inner;` in `class C(template T: type)` is evaluated
  // for each specific of `C`. With diagnosed parameters, the value is an error
  // and the parameters' bindings stay out of the enclosing generic.
  if (diagnosed_params) {
    DiscardGenericDecl(context);
  } else {
    DiscardGenericDeclIntoEnclosingGeneric(context);
  }

  auto introducer =
      context.decl_introducer_state_stack().Pop<Lex::TokenKind::Alias>();
  LimitModifiersOnDecl(context, introducer, KeywordModifierSet::Access);

  auto entity_name_id = context.entity_names().Add(
      {.name_id = name_context.name_id_for_new_inst(),
       .parent_scope_id = name_context.parent_scope_id});

  // Whether the value's category and constant value are known only for each
  // specific of the enclosing generic.
  bool check_in_specific = false;
  switch (SemIR::GetExprCategory(context.sem_ir(), expr_id)) {
    case SemIR::ExprCategory::Value:
    case SemIR::ExprCategory::EphemeralRef:
    case SemIR::ExprCategory::DurableRef:
    case SemIR::ExprCategory::NotExpr:
    case SemIR::ExprCategory::Error:
      // An alias can refer to a value, a reference, or a non-expression name
      // such as a function or namespace.
      break;
    case SemIR::ExprCategory::Dependent:
      // A template-dependent value, such as `T.Inner` or `T.Make()` for a
      // template parameter `T`, or a C++ call deferred to each specific. It is
      // not converted here: a conversion would be performed for each specific
      // outside any function, where the value of `T.Make()` would be
      // materialized in a temporary. Whether the value is a constant is
      // checked in each specific instead (`AddAliasCheckToCurrentGeneric`).
      if (!context.generic_region_stack().Empty()) {
        check_in_specific = true;
        break;
      }
      [[fallthrough]];
    case SemIR::ExprCategory::ReprInitializing:
    case SemIR::ExprCategory::InPlaceInitializing:
    case SemIR::ExprCategory::Mixed:
    case SemIR::ExprCategory::RefTagged:
    case SemIR::ExprCategory::Pattern:
      // For any other kind of expression, convert to a value or reference.
      // TODO: Should we allow or require `ref` tagging for reference aliases?
      expr_id = ConvertToValueOrRefExpr(context, expr_id);
      break;
  }

  if (!check_in_specific &&
      !context.constant_values().Get(expr_id).is_constant()) {
    DiagnoseAliasRequiresConstantValue(context, SemIR::LocId(expr_node));
  }
  SemIR::AliasBinding alias = {
      .type_id = context.insts().Get(expr_id).type_id(),
      .entity_name_id = entity_name_id,
      .value_id = expr_id};
  auto alias_id = AddInst(context, name_context.loc_id, alias);
  if (check_in_specific) {
    AddAliasCheckToCurrentGeneric(context, name_context.loc_id, alias);
  }

  // Add the name of the binding to the current scope.
  context.decl_name_stack().PopScope();
  context.decl_name_stack().AddNameOrDiagnose(
      name_context, alias_id, introducer.modifier_set.GetAccessKind());
  return true;
}

}  // namespace Carbon::Check
