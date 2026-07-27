// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <optional>

#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/core_identifier.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/operator.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// A `match` statement with an integer scrutinee, integer-literal `case`
// patterns, and a `default` arm is checked as an `if`/`else if`/`else` chain:
// each `case <literal>` becomes a `<literal> == scrutinee` test with a
// conditional branch to the arm's body block, falling through to the next test
// otherwise, with the `default` body as the final `else` block and all arm
// bodies converging on a single resumption block.
//
// A choice-typed scrutinee is additionally admitted, with leading-dot
// payload-free alternative patterns (`case .Err`): the alternative's index is
// compared against the scrutinee's `.discriminant` field with the same `==`
// chain. Everything outside that subset produces a "semantics TODO"
// diagnostic.
//
// TODO: Support other pattern kinds, guards, other scrutinee types, payload
// destructuring in alternative patterns, and exhaustiveness checking without
// a `default` arm. Diagnose cases that can never match, per
// docs/design/pattern_matching.md.

// Returns the scrutinee value, which is on the `MatchHandler` entry after an
// earlier case arm, or otherwise on the `MatchStatementStart` entry.
static auto PeekScrutinee(Context& context) -> SemIR::InstId {
  if (context.node_stack().PeekIs(Parse::NodeKind::MatchHandler)) {
    return context.node_stack().Peek<Parse::NodeKind::MatchHandler>();
  }
  return context.node_stack().Peek<Parse::NodeKind::MatchStatementStart>();
}

// If `type_id` is a complete, non-generic choice type whose discriminant is
// an integer field, returns the discriminant's type; returns nullopt
// otherwise. This is the in-slice choice scrutinee shape: choices with fewer
// than two alternatives have an empty-tuple discriminant, and specifics of
// generic choices are out of slice 1 (alternative name-to-index metadata is
// scoped to concrete choices, plan section 2.2c), so both stay behind the
// scrutinee TODO. Uses the `Class::is_choice` entity flag, never the
// representation's spelling.
static auto GetChoiceDiscriminantType(Context& context, SemIR::TypeId type_id)
    -> std::optional<SemIR::TypeId> {
  auto unqualified_type_id = context.types().GetUnqualifiedType(type_id);
  auto class_type =
      context.types().TryGetAsIfValid<SemIR::ClassType>(unqualified_type_id);
  if (!class_type || class_type->specific_id.has_value()) {
    return std::nullopt;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (!class_info.is_choice || !class_info.is_complete()) {
    return std::nullopt;
  }
  auto object_repr_id =
      class_info.GetObjectRepr(context.sem_ir(), class_type->specific_id);
  auto struct_type =
      context.types().TryGetAsIfValid<SemIR::StructType>(object_repr_id);
  if (!struct_type) {
    return std::nullopt;
  }
  auto fields = context.struct_type_fields().Get(struct_type->fields_id);
  if (fields.empty() ||
      fields.front().name_id != SemIR::NameId::ChoiceDiscriminant) {
    return std::nullopt;
  }
  auto disc_type_id =
      context.types().GetTypeIdForTypeInstId(fields.front().type_inst_id);
  if (!context.types().TryGetIntTypeInfo(disc_type_id)) {
    return std::nullopt;
  }
  return disc_type_id;
}

auto HandleParseNode(Context& /*context*/,
                     Parse::MatchConditionStartId /*node_id*/) -> bool {
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchConditionId node_id)
    -> bool {
  auto scrutinee_id = context.node_stack().PopExpr();

  // Convert the scrutinee to a value or reference expression so that we can
  // use it multiple times, once per `case`.
  scrutinee_id = ConvertToValueOrRefExpr(context, scrutinee_id);

  // Two scrutinee shapes are supported so far.
  //
  // Integer scrutinees: `Core.IntLiteral`, a builtin integer type, or a class
  // type directly adapting a builtin integer type, as `Int(N)` and `UInt(N)`
  // do. Other class types whose object representation is an integer type,
  // such as `Core.Char` or user-defined adapter classes, are excluded: they
  // have their own operator semantics.
  //
  // Choice scrutinees with an integer discriminant: dispatch compares the
  // alternative's index against the `.discriminant` field. The temporary
  // cleanup handling below stays trivially correct for both shapes as a type
  // property, not a syntactic one: integer values have no `destroy`
  // functions, and an in-slice choice's payloads are restricted to trivially
  // copyable and destructible types when the choice's representation is
  // completed (see handle_choice.cpp), so its destruction is a no-op.
  auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();
  bool is_int_scrutinee = false;
  if (context.types().TryGetIntTypeInfo(scrutinee_type_id)) {
    auto unqualified_type_id =
        context.types().GetUnqualifiedType(scrutinee_type_id);
    if (context.types().Is<SemIR::ClassType>(unqualified_type_id)) {
      is_int_scrutinee =
          context.types()
              .TryGetAsIfValid<SemIR::IntType>(
                  context.types().GetAdaptedType(unqualified_type_id))
              .has_value();
    } else {
      is_int_scrutinee = true;
    }
  }
  if (!is_int_scrutinee &&
      !GetChoiceDiscriminantType(context, scrutinee_type_id)) {
    return context.TODO(node_id, "match on unsupported scrutinee type");
  }

  // Destroy any temporaries created in the scrutinee expression.
  AddAndDiscardTemporaryCleanups(context);

  context.node_stack().Push(node_id, scrutinee_id);
  return true;
}

auto HandleParseNode(Context& /*context*/, Parse::MatchIntroducerId /*node_id*/)
    -> bool {
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchStatementStartId node_id)
    -> bool {
  // Keep the scrutinee value on the node stack for the case arms to find.
  auto scrutinee_id =
      context.node_stack().Pop<Parse::NodeKind::MatchCondition>();
  context.node_stack().Push(node_id, scrutinee_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchCaseIntroducerId node_id)
    -> bool {
  // Only single-node-rooted, guard-free `case` patterns are supported so far:
  // a single integer literal for an integer scrutinee, or a single
  // leading-dot designator (`.Name`, per decision-log W5 SF-4: leading-dot
  // only) for a choice scrutinee. The parse tree is stored in postorder and
  // the introducer is a leaf node, so the pattern's first node is at the next
  // node index; the bracketing `MatchCase` node must immediately follow the
  // pattern. Diagnosing here, before the pattern's nodes are traversed, keeps
  // unsupported pattern nodes from reaching their handlers outside of a
  // pattern-matching context.
  auto pattern_kind =
      context.parse_tree().node_kind(Parse::NodeId(node_id.index + 1));
  auto after_pattern_kind =
      context.parse_tree().node_kind(Parse::NodeId(node_id.index + 2));
  if (GetChoiceDiscriminantType(
          context, context.insts().Get(PeekScrutinee(context)).type_id())) {
    // A designator pattern is [name, DesignatorExpr], then `MatchCase`.
    if (pattern_kind == Parse::NodeKind::IdentifierNameNotBeforeSignature &&
        after_pattern_kind == Parse::NodeKind::DesignatorExpr) {
      auto third_kind =
          context.parse_tree().node_kind(Parse::NodeId(node_id.index + 3));
      if (third_kind == Parse::NodeKind::MatchCase) {
        context.node_stack().Push(node_id);
        return true;
      }
      if (third_kind == Parse::NodeKind::MatchCaseGuardIntroducer) {
        return context.TODO(node_id,
                            "match `case` pattern other than an integer "
                            "literal, or a case guard");
      }
      // A designator-rooted pattern with more nodes, such as `.Ok(...)`,
      // is an attempt to destructure the alternative's payload (slice 2).
      return context.TODO(node_id,
                          "match case pattern destructuring a choice payload");
    }
    if (pattern_kind == Parse::NodeKind::IdentifierNameExpr) {
      // For example `case IntResult.Err`: only the leading-dot spelling is
      // in-slice (SF-4); the qualified form is a recorded work item.
      return context.TODO(node_id,
                          "qualified alternative pattern in match case");
    }
    return context.TODO(
        node_id,
        "match `case` pattern other than an integer literal, or a case guard");
  }
  if (pattern_kind != Parse::NodeKind::IntLiteral ||
      after_pattern_kind != Parse::NodeKind::MatchCase) {
    return context.TODO(
        node_id,
        "match `case` pattern other than an integer literal, or a case guard");
  }
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context,
                     Parse::MatchCaseGuardIntroducerId node_id) -> bool {
  return context.TODO(node_id, "HandleMatchCaseGuardIntroducer");
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardStartId node_id)
    -> bool {
  return context.TODO(node_id, "HandleMatchCaseGuardStart");
}

auto HandleParseNode(Context& context, Parse::MatchCaseGuardId node_id)
    -> bool {
  return context.TODO(node_id, "HandleMatchCaseGuard");
}

auto HandleParseNode(Context& context, Parse::MatchCaseId node_id) -> bool {
  auto pattern_id = context.node_stack().PopExpr();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchCaseIntroducer>();
  auto scrutinee_id = PeekScrutinee(context);
  auto scrutinee_type_id = context.insts().Get(scrutinee_id).type_id();

  // Build the arm's condition — docs/design/pattern_matching.md mandates the
  // operand order for expression patterns: "The scrutinee is compared with
  // the expression using the `==` operator: _expression_ `==` _scrutinee_" —
  // the same way as the infix `==` operator: the `EqWith` interface takes a
  // single argument that is the type of the RHS operand.
  SemIR::InstId cond_value_id = SemIR::InstId::None;
  if (auto disc_type_id =
          GetChoiceDiscriminantType(context, scrutinee_type_id)) {
    // A choice scrutinee: `MatchCaseIntroducer` admitted a single leading-dot
    // designator, resolved against the scrutinee's choice scope (see
    // `DesignatorExpr` handling in handle_name.cpp).
    auto pattern_type_id = context.insts().Get(pattern_id).type_id();
    if (pattern_type_id == SemIR::ErrorInst::TypeId) {
      // The designator failed to resolve; a diagnostic was already produced.
      cond_value_id = SemIR::ErrorInst::InstId;
    } else if (context.types().Is<SemIR::FunctionType>(pattern_type_id)) {
      // The designator names a payload alternative's constructor function;
      // destructuring its payload is slice 2.
      return context.TODO(node_id,
                          "match case pattern destructuring a choice payload");
    } else {
      // The designator names a payload-free alternative constant of the
      // scrutinee's choice type. Its constant is a struct value whose leading
      // element is the alternative's discriminant; compare it against the
      // scrutinee's discriminant field.
      CARBON_CHECK(context.types().GetUnqualifiedType(pattern_type_id) ==
                       context.types().GetUnqualifiedType(scrutinee_type_id),
                   "Alternative constant type differs from scrutinee type");
      auto const_id = context.constant_values().Get(pattern_id);
      CARBON_CHECK(const_id.is_constant(),
                   "Alternative constant is not constant");
      auto struct_value = context.insts().GetAs<SemIR::StructValue>(
          context.constant_values().GetInstId(const_id));
      auto elements = context.inst_blocks().Get(struct_value.elements_id);
      CARBON_CHECK(!elements.empty(), "Choice constant has no discriminant");
      auto index_value_id = elements[0];

      auto disc_access_id =
          AddInst<SemIR::ClassElementAccess>(context, node_id,
                                             {.type_id = *disc_type_id,
                                              .base_id = scrutinee_id,
                                              .index = SemIR::ElementIndex(0)});
      SemIR::InstId args[] = {context.types().GetTypeInstId(*disc_type_id)};
      auto eq_id =
          BuildBinaryOperator(context, node_id,
                              {.interface_name = CoreIdentifier::EqWith,
                               .interface_args_ref = args,
                               .op_name = CoreIdentifier::Equal},
                              index_value_id, disc_access_id);
      cond_value_id = ConvertToBoolValue(context, node_id, eq_id);
    }
  } else {
    // An integer scrutinee with an integer-literal pattern.
    SemIR::InstId args[] = {context.types().GetTypeInstId(scrutinee_type_id)};
    auto eq_id = BuildBinaryOperator(context, node_id,
                                     {.interface_name = CoreIdentifier::EqWith,
                                      .interface_args_ref = args,
                                      .op_name = CoreIdentifier::Equal},
                                     pattern_id, scrutinee_id);
    cond_value_id = ConvertToBoolValue(context, node_id, eq_id);
  }

  // Create the arm's body block and the block for the next test (or the
  // `default` body), and branch to the right one.
  auto then_block_id =
      AddDominatedBlockAndBranchIf(context, node_id, cond_value_id);
  auto else_block_id = AddDominatedBlockAndBranch(context, node_id);

  // Start emitting the arm's body block.
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(then_block_id);
  context.region_stack().AddToRegion(then_block_id, node_id);

  context.node_stack().Push(node_id, else_block_id);
  return true;
}

auto HandleParseNode(Context& /*context*/,
                     Parse::MatchDefaultIntroducerId /*node_id*/) -> bool {
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchDefaultId node_id) -> bool {
  // The current block is the last case arm's else block, or the enclosing
  // block if there are no case arms; either way it is where the `default`
  // arm's body should be emitted, so there is nothing to do other than note
  // the presence of the `default` arm for `MatchStatement`. Parse guarantees
  // the `default` arm is last.
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchHandlerStartId node_id)
    -> bool {
  context.node_stack().Push(node_id);
  context.scope_stack().PushForSameRegion(ScopeStack::CleanupScopeKind::Owned);
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchHandlerId node_id) -> bool {
  AddAndDiscardScopeCleanups(context);
  context.scope_stack().Pop(/*check_unused=*/true);
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::MatchHandlerStart>();

  if (context.node_stack().PeekIs(Parse::NodeKind::MatchDefault)) {
    // This is the `default` arm's body: leave its block on the instruction
    // block stack for `MatchStatement` to converge, and leave the
    // `MatchDefault` entry on the node stack.
    return true;
  }

  // This is a case arm's body: leave its finished block on the instruction
  // block stack for `MatchStatement` to converge, and start emitting the else
  // block, which holds the next arm's test or the `default` body.
  auto else_block_id = context.node_stack().Pop<Parse::NodeKind::MatchCase>();
  context.inst_block_stack().Push(else_block_id);
  context.region_stack().AddToRegion(else_block_id, node_id);

  // Keep the scrutinee exposed for the next case arm.
  context.node_stack().Push(node_id, PeekScrutinee(context));
  return true;
}

auto HandleParseNode(Context& context, Parse::MatchStatementId node_id)
    -> bool {
  bool has_default =
      context.node_stack()
          .PopAndDiscardSoloNodeIdIf<Parse::NodeKind::MatchDefault>();
  int num_case_arms = 0;
  while (context.node_stack().PeekIs(Parse::NodeKind::MatchHandler)) {
    context.node_stack().Pop<Parse::NodeKind::MatchHandler>();
    ++num_case_arms;
  }
  context.node_stack().Pop<Parse::NodeKind::MatchStatementStart>();

  if (!has_default) {
    // A `match` whose patterns are not exhaustive and that has no `default`
    // is an error per docs/design/pattern_matching.md, and integer-literal
    // patterns are never exhaustive. Exhaustiveness checking for other
    // pattern kinds is future work.
    return context.TODO(node_id, "match statement without `default` arm");
  }

  // The instruction block stack holds one body block per case arm, plus the
  // `default` arm's body block on top; branch from all of them to a new
  // resumption block. With no case arms, the `default` body was emitted
  // directly into the enclosing block, and there is nothing to converge.
  int num_blocks = num_case_arms + 1;
  if (num_blocks >= 2) {
    AddConvergenceBlockAndPush(context, node_id, num_blocks);
  }
  return true;
}

}  // namespace Carbon::Check
