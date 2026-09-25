// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "common/map.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "toolchain/check/class.h"
#include "toolchain/check/context.h"
#include "toolchain/check/full_pattern_stack.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/pattern.h"
#include "toolchain/check/type.h"
#include "toolchain/diagnostics/emitter.h"
#include "toolchain/sem_ir/pattern.h"
#include "toolchain/sem_ir/struct_type_field.h"

namespace Carbon::Check {

// Handle the start of any kind of pattern list.
static auto HandlePatternListStart(Context& context, Parse::NodeId node_id)
    -> bool {
  context.node_stack().Push(node_id);
  context.param_and_arg_refs_stack().Push();
  BeginExprRegionForPattern(context);
  return true;
}

auto HandleParseNode(Context& context, Parse::ImplicitParamListStartId node_id)
    -> bool {
  context.full_pattern_stack().StartImplicitParamList();
  return HandlePatternListStart(context, node_id);
}

auto HandleParseNode(Context& context, Parse::TuplePatternStartId node_id)
    -> bool {
  // End the pending `ExprRegion`, so that we can start a new one in
  // `HandlePatternListStart`.
  EndEmptyExprRegionForPattern(context);
  return HandlePatternListStart(context, node_id);
}

auto HandleParseNode(Context& context, Parse::StructPatternStartId node_id)
    -> bool {
  // Struct patterns are checked in `match` `case` position only; every other
  // context — `let`, `var`, parameter lists, class fields — keeps the
  // upstream TODO, which aborts checking at this start node, so the real
  // `StructPattern` and `StructPatternDesignatedField` handlers below stay
  // unreachable outside match arms. A struct pattern nested anywhere inside
  // a case pattern sees `MatchCaseArm` (the innermost full-pattern), while a
  // `let`/`var` inside an arm's BODY pushes its own `NameBindingDecl` frame
  // first — the arm's full pattern is popped before the body checks — and
  // stays behind the TODO.
  if (context.full_pattern_stack().empty() ||
      context.full_pattern_stack().CurrentKind() !=
          FullPatternStack::Kind::MatchCaseArm) {
    return context.TODO(node_id, "struct pattern start");
  }
  // Open a designated-name frame for this struct pattern; one frame per open
  // struct pattern, so nesting is free.
  context.struct_pattern_names_stack().PushArray();
  // End the pending `ExprRegion`, so that we can start a new one in
  // `HandlePatternListStart`.
  EndEmptyExprRegionForPattern(context);
  return HandlePatternListStart(context, node_id);
}

auto HandleParseNode(Context& context, Parse::ExplicitParamListStartId node_id)
    -> bool {
  context.full_pattern_stack().StartExplicitParamList();
  return HandlePatternListStart(context, node_id);
}

// Handle the end of any kind of parameter list (tuple patterns have separate
// logic).
static auto HandleParamListEnd(Context& context, Parse::NodeId node_id,
                               Parse::NodeKind start_kind) -> bool {
  if (context.node_stack().PeekIs(start_kind)) {
    // End the pending region started by a trailing comma, or the opening
    // delimiter of an empty list.
    EndEmptyExprRegionForPattern(context);
  } else {
    // End the pending region for the last pattern in the list.
    EndExprRegionForPattern(context, context.node_stack());
  }
  // Note the Start node remains on the stack, where the param list handler can
  // make use of it.
  auto refs_id = context.param_and_arg_refs_stack().EndAndPop(start_kind);
  context.node_stack().Push(node_id, refs_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::ImplicitParamListId node_id)
    -> bool {
  context.full_pattern_stack().EndImplicitParamList();
  return HandleParamListEnd(context, node_id,
                            Parse::NodeKind::ImplicitParamListStart);
}

auto HandleParseNode(Context& context, Parse::ExplicitParamListId node_id)
    -> bool {
  context.full_pattern_stack().EndExplicitParamList();
  return HandleParamListEnd(context, node_id,
                            Parse::NodeKind::ExplicitParamListStart);
}

auto HandleParseNode(Context& context, Parse::ParenPatternId node_id) -> bool {
  EndExprRegionForPattern(context, context.node_stack());
  auto pattern_id = context.node_stack().PopPattern();
  context.param_and_arg_refs_stack().PopAndDiscard();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::TuplePatternStart>();
  context.node_stack().Push(node_id, pattern_id);
  // Start a new pending `ExprRegion`, to maintain the invariant that one is
  // pending at the end of handling for a pattern.
  BeginExprRegionForPattern(context);
  return true;
}

auto HandleParseNode(Context& context, Parse::TuplePatternId node_id) -> bool {
  if (context.node_stack().PeekIs(Parse::NodeKind::TuplePatternStart)) {
    // End the pending region started by a trailing comma, or the opening
    // delimiter of an empty list.
    EndEmptyExprRegionForPattern(context);
  } else {
    // End the pending region for the last pattern in the list.
    EndExprRegionForPattern(context, context.node_stack());
  }
  auto refs_id = context.param_and_arg_refs_stack().EndAndPop(
      Parse::NodeKind::TuplePatternStart);
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::TuplePatternStart>();

  const auto& inst_block = context.inst_blocks().Get(refs_id);
  llvm::SmallVector<SemIR::InstId> type_inst_ids;
  type_inst_ids.reserve(inst_block.size());
  for (auto inst : inst_block) {
    if (InNonStaticFieldDecl(context)) {
      CARBON_DIAGNOSTIC(FieldWithTuplePattern, Error,
                        "found tuple pattern in class `var` decl");
      context.emitter().Emit(LocIdForDiagnostics::TokenOnly(node_id),
                             FieldWithTuplePattern);

      return false;
    }

    auto type_id = ExtractScrutineeType(context.sem_ir(),
                                        context.insts().Get(inst).type_id());
    type_inst_ids.push_back(context.types().GetTypeInstId(type_id));
  }
  auto type_id = GetPatternType(context, GetTupleType(context, type_inst_ids));
  context.node_stack().Push(
      node_id,
      AddInst<SemIR::TuplePattern>(
          context, node_id, {.type_id = type_id, .elements_id = refs_id}));
  // Start a new pending `ExprRegion`, to maintain the invariant that one is
  // pending at the end of handling for a pattern.
  BeginExprRegionForPattern(context);
  return true;
}

auto HandleParseNode(Context& context, Parse::StructPatternId node_id) -> bool {
  // Reachable only inside a `match` `case` arm: every other context aborts
  // at the `StructPatternStart` gate above.
  //
  // Pop the trailing `_` field discard, if any, left on the stack by
  // `UnderscoreName`. Parse enforces only that `_` is LAST; bare `{_}` —
  // which the grammar's `_` production forbids (it requires at least one
  // preceding field, docs/design/pattern_matching.md) — is diagnosed below,
  // once the element count is in hand.
  bool has_trailing_discard = false;
  if (context.node_stack().PeekIs(Parse::NodeKind::UnderscoreName)) {
    has_trailing_discard = true;
    context.node_stack().Pop<Parse::NodeKind::UnderscoreName>();
    // After a comma-preceded `_` the pending region is the empty one the
    // comma opened; for bare `{_}` it is the still-empty one the start
    // opened.
    EndEmptyExprRegionForPattern(context);
  } else if (context.node_stack().PeekIs(Parse::NodeKind::StructPatternStart)) {
    // End the pending region started by a trailing comma, or the opening
    // delimiter of an empty list.
    EndEmptyExprRegionForPattern(context);
  } else {
    // End the pending region for the last pattern in the list.
    EndExprRegionForPattern(context, context.node_stack());
  }
  auto refs_id = context.param_and_arg_refs_stack().EndAndPop(
      Parse::NodeKind::StructPatternStart);
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::StructPatternStart>();

  // Every exit path pops this pattern's designated-name frame, pushes the
  // resulting pattern inst, and starts a new pending `ExprRegion` to
  // maintain the invariant that one is pending at the end of handling for a
  // pattern.
  auto finish = [&](SemIR::InstId pattern_id) {
    context.struct_pattern_names_stack().PopArray();
    context.node_stack().Push(node_id, pattern_id);
    BeginExprRegionForPattern(context);
    return true;
  };

  const auto& inst_block = context.inst_blocks().Get(refs_id);
  if (has_trailing_discard && inst_block.empty()) {
    CARBON_DIAGNOSTIC(StructPatternDiscardWithoutFields, Error,
                      "`_` in a struct pattern requires at least one named "
                      "field before it");
    context.emitter().Emit(node_id, StructPatternDiscardWithoutFields);
    return finish(SemIR::ErrorInst::InstId);
  }

  // Assemble the field names in element order: the recorded designated name
  // for the element's ordinal when present, else the shorthand field name
  // derived from the element's binding — `a: T` means `.a = a: T`
  // (docs/design/pattern_matching.md, "Struct patterns"), and parse
  // guarantees shorthand fields are named bindings
  // (AnonymousBindingInStructPattern). The names ride the pattern's own
  // type: each field pairs its name with its element's scrutinee type, so
  // consumers recover name-to-element alignment from the type alone.
  //
  // No `InNonStaticFieldDecl` check is needed here, unlike the tuple
  // handler: the `StructPatternStart` gate keeps class-field `var` position
  // (`ClassScopeVarDecl`) behind the upstream TODO.
  auto recorded_names = context.struct_pattern_names_stack().PeekArray();
  size_t recorded_index = 0;
  llvm::SmallVector<SemIR::StructTypeField> fields;
  fields.reserve(inst_block.size());
  Map<SemIR::NameId, SemIR::InstId> first_element_with_name;
  for (auto [i, element_id] : llvm::enumerate(inst_block)) {
    if (element_id == SemIR::ErrorInst::InstId) {
      // An errored element (for example a nested struct pattern that was
      // diagnosed above) has no name or type to contribute.
      return finish(SemIR::ErrorInst::InstId);
    }
    SemIR::NameId name_id = SemIR::NameId::None;
    if (recorded_index < recorded_names.size() &&
        recorded_names[recorded_index].ordinal == static_cast<int32_t>(i)) {
      name_id = recorded_names[recorded_index].name_id;
      ++recorded_index;
    } else {
      auto entity_name_id =
          SemIR::GetFirstBindingNameFromPatternId(context.sem_ir(), element_id);
      CARBON_CHECK(entity_name_id.has_value(),
                   "Shorthand struct pattern field without a named binding");
      name_id = context.entity_names().Get(entity_name_id).name_id;
    }
    auto insert_result = first_element_with_name.Insert(name_id, element_id);
    if (!insert_result.is_inserted()) {
      // A duplicate either dead-constrains one scrutinee field twice or
      // double-binds; diagnosed here, where the pattern inst is built, so
      // the check is context-independent (the `StructNameDuplicate` struct
      // literal parity).
      CARBON_DIAGNOSTIC(StructPatternNameDuplicate, Error,
                        "duplicated field name `{0}` in struct pattern",
                        SemIR::NameId);
      CARBON_DIAGNOSTIC(StructPatternNamePrevious, Note,
                        "field with the same name here");
      context.emitter()
          .Build(element_id, StructPatternNameDuplicate, name_id)
          .Note(insert_result.value(), StructPatternNamePrevious)
          .Emit();
      return finish(SemIR::ErrorInst::InstId);
    }
    auto type_id = ExtractScrutineeType(
        context.sem_ir(), context.insts().Get(element_id).type_id());
    fields.push_back({.name_id = name_id,
                      .type_inst_id = context.types().GetTypeInstId(type_id)});
  }

  auto type_id = GetPatternType(
      context, GetStructType(
                   context, context.struct_type_fields().AddCanonical(fields)));
  return finish(AddInst<SemIR::StructPattern>(
      context, node_id,
      {.type_id = type_id,
       .elements_id = refs_id,
       .has_trailing_discard = SemIR::BoolValue::From(has_trailing_discard)}));
}

auto HandleParseNode(Context& context,
                     Parse::StructPatternDesignatedFieldId /*node_id*/)
    -> bool {
  // Reachable only inside a `match` `case` arm (see `StructPatternStart`).
  // The node stack holds the designator's name — left by the shared
  // `StructFieldDesignator` handler — and above it the field's element: its
  // checked subpattern inst, or its still-unwrapped expression (an
  // expression initializer is wrapped into an `ExprPattern` at the comma/end
  // region close; see `EndExprRegionForPattern`). Record the name against
  // the element's ordinal — the number of elements the open frame has
  // already completed — and re-push the element under its ORIGINAL node id,
  // so the shared comma/end machinery sees exactly the stack it would have
  // seen with no designator.
  // `PopPatternWithNodeId` pops any node carrying an `InstId` — a checked
  // subpattern or a still-unwrapped expression alike.
  auto [element_node_id, element_id] =
      context.node_stack().PopPatternWithNodeId();
  auto name_id = context.node_stack().PopName();
  context.struct_pattern_names_stack().AppendToTop(
      {.ordinal = static_cast<int32_t>(context.param_and_arg_refs_stack()
                                           .PeekCurrentBlockContents()
                                           .size()),
       .name_id = name_id});
  context.node_stack().Push(element_node_id, element_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::PatternListCommaId /*node_id*/)
    -> bool {
  EndExprRegionForPattern(context, context.node_stack());
  context.param_and_arg_refs_stack().ApplyComma();
  BeginExprRegionForPattern(context);
  return true;
}

}  // namespace Carbon::Check
