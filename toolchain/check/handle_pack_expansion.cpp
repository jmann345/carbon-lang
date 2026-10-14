// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/context.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/pattern.h"
#include "toolchain/check/type.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

using PackExpansionScope = Context::PackExpansionScope;

// Returns the kind of pack expansion that a `...` starts. Each pattern-list
// and expression-list comma moves the preceding element off the node stack
// (`ParamAndArgRefsStack::ApplyComma`), so a `...` that begins a list element
// directly follows the list's start node; any other `...` begins a statement.
static auto GetPackExpansionKind(Context& context) -> PackExpansionScope::Kind {
  switch (context.node_stack().PeekNodeKind()) {
    case Parse::NodeKind::ExplicitParamListStart:
    case Parse::NodeKind::ImplicitParamListStart:
    case Parse::NodeKind::TuplePatternStart:
      return PackExpansionScope::Kind::Pattern;
    case Parse::NodeKind::CallExprStart:
    case Parse::NodeKind::TupleLiteralStart:
      return PackExpansionScope::Kind::Expr;
    default:
      return PackExpansionScope::Kind::Statement;
  }
}

auto HandleParseNode(Context& context, Parse::PackExpansionStartId node_id)
    -> bool {
  // "A pack expansion or `...expand` expression cannot contain another pack
  // expansion" (docs/design/variadics.md, "Pack expansions").
  if (!context.pack_expansion_stack().empty()) {
    CARBON_DIAGNOSTIC(NestedPackExpansion, Error,
                      "pack expansion cannot contain another pack expansion");
    CARBON_DIAGNOSTIC(EnclosingPackExpansion, Note,
                      "enclosing pack expansion is here");
    context.emitter()
        .Build(node_id, NestedPackExpansion)
        .Note(context.pack_expansion_stack().back().start_node_id,
              EnclosingPackExpansion)
        .Emit();
    return false;
  }

  PackExpansionScope scope = {.kind = GetPackExpansionKind(context),
                              .start_node_id = node_id};
  switch (scope.kind) {
    case PackExpansionScope::Kind::Pattern: {
      // Fork (VA-1, D-VA-5): a pack expansion pattern is supported directly
      // in a function's explicit parameter list.
      if (!context.node_stack().PeekIs(
              Parse::NodeKind::ExplicitParamListStart) ||
          context.full_pattern_stack().CurrentKind() !=
              FullPatternStack::Kind::ExplicitParamList) {
        return context.TODO(node_id,
                            "pack expansion pattern outside an explicit "
                            "parameter list");
      }
      // Fork (VA-1, D-VA-5): an interface's function is matched by the
      // functions of its impls, and the thunk that adapts one to the other
      // does not clone a pack expansion pattern yet.
      if (context.name_scopes().InstIs<SemIR::InterfaceWithSelfDecl>(
              context.decl_name_stack().PeekParentScopeId())) {
        return context.TODO(node_id,
                            "pack expansion pattern in an interface function");
      }
      // "A tuple pattern can contain no more than one subpattern of the form
      // `...` operand" (docs/design/variadics.md, "Pattern matching"). Each
      // comma has moved the list's earlier elements to the refs stack.
      for (auto param_id :
           context.param_and_arg_refs_stack().PeekCurrentBlockContents()) {
        // Fork (VA-1, D-VA-5): the design does not say how default values
        // beside a pack bind; handle_pattern_list.cpp diagnoses a default
        // after the pack, or on it.
        if (context.insts().Is<SemIR::DefaultValuePattern>(param_id)) {
          return context.TODO(node_id,
                              "default value in a parameter list with a pack "
                              "expansion pattern");
        }
        if (context.insts().Is<SemIR::PackExpansionPattern>(param_id)) {
          CARBON_DIAGNOSTIC(MultiplePackExpansionPatterns, Error,
                            "parameter list can contain at most one pack "
                            "expansion pattern");
          CARBON_DIAGNOSTIC(PreviousPackExpansionPattern, Note,
                            "previous pack expansion pattern is here");
          context.emitter()
              .Build(node_id, MultiplePackExpansionPatterns)
              .Note(param_id, PreviousPackExpansionPattern)
              .Emit();
          return false;
        }
      }
      // The arity of the pack is a deduced parameter of the enclosing full
      // pattern (docs/design/variadics.md, "Explicit deduced arities").
      auto arity_type_id =
          GetSingletonType(context, SemIR::IntLiteralType::TypeInstId);
      auto entity_name_id = AddBindingEntityName(
          context, SemIR::NameId::PackArity, SemIR::TypeInstId::None,
          SemIR::InstId::None, /*is_unused=*/false, BindingPhase::Symbolic);
      auto arity = AddBindingPattern(
          context, node_id, SemIR::ExprRegionId::None, arity_type_id,
          {.kind = SemIR::SymbolicBindingPattern::Kind,
           .type_id = GetPatternType(context, arity_type_id),
           .entity_name_id = entity_name_id,
           .subpattern_id = SemIR::InstId::None});
      scope.arity_pattern_id = arity.pattern_id;
      scope.arity_binding_id = arity.bind_id;
      break;
    }
    case PackExpansionScope::Kind::Statement:
    case PackExpansionScope::Kind::Expr: {
      // The body is checked once, into its own block, which lowering runs
      // once per element (docs/design/variadics.md, "Iterative typechecking
      // of pack expansions" and "Execution Semantics").
      context.inst_block_stack().Push();
      scope.body_block_id = context.inst_block_stack().PeekOrAdd();
      scope.cleanup_depth = context.scope_stack().cleanup_scope_depth();
      break;
    }
  }
  context.pack_expansion_stack().push_back(scope);
  context.node_stack().Push(node_id);
  return true;
}

// Marks the innermost statement or expression pack expansion as invalid after
// one of its each-names is diagnosed, so that its end is not diagnosed again.
static auto InvalidateInnermostPackExpansion(Context& context) -> void {
  auto& stack = context.pack_expansion_stack();
  if (!stack.empty() &&
      stack.back().kind != PackExpansionScope::Kind::Pattern) {
    stack.back().arity_id = SemIR::ErrorInst::InstId;
  }
}

// Finishes the body of a statement or expression pack expansion, popping its
// block. Returns `nullopt` after diagnosing a body that this slice does not
// support, which ends checking, or `InstBlockId::None` after diagnosing an
// invalid body, which the caller recovers from.
static auto FinishPackExpansionBody(Context& context, Parse::NodeId node_id,
                                    const PackExpansionScope& scope)
    -> std::optional<SemIR::InstBlockId> {
  // Fork (VA-1, D-VA-6): the body runs as one straight-line block per element,
  // so control flow inside it, which would add blocks to the function, is not
  // supported yet.
  if (!context.inst_block_stack().is_current_block_reachable() ||
      context.inst_block_stack().PeekOrAdd() != scope.body_block_id) {
    context.TODO(node_id, "control flow in a pack expansion");
    return std::nullopt;
  }
  // Fork (VA-1, D-VA-6): a temporary in an expansion element would need to be
  // destroyed once per element.
  if (context.scope_stack().cleanup_scope_depth() != scope.cleanup_depth) {
    context.TODO(node_id, "pack expansion element that needs a cleanup");
    return std::nullopt;
  }
  auto body_block_id = context.inst_block_stack().Pop();
  if (scope.arity_id == SemIR::ErrorInst::InstId) {
    // An each-name in the body was diagnosed.
    return SemIR::InstBlockId::None;
  }

  // "If an expansion contains no each-names, it must be a pattern, or an
  // expression in the type position of a binding pattern"
  // (docs/design/variadics.md, "Pack expansions").
  if (!scope.arity_id.has_value()) {
    CARBON_DIAGNOSTIC(PackExpansionWithoutEachName, Error,
                      "pack expansion does not use any each-name");
    context.emitter().Emit(scope.start_node_id, PackExpansionWithoutEachName);
    return SemIR::InstBlockId::None;
  }
  return body_block_id;
}

auto HandleParseNode(Context& context, Parse::PackExpansionStatementId node_id)
    -> bool {
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::PackExpansionStart>();
  auto scope = context.pack_expansion_stack().pop_back_val();
  CARBON_CHECK(scope.kind == PackExpansionScope::Kind::Statement);

  // Fork (VA-1, D-VA-6): only an expression statement can be expanded yet. A
  // declaration in the body would introduce a name, and so storage, per
  // element, and the other statements are control flow.
  auto statement = context.parse_tree_and_subtrees()
                       .ExtractAs<Parse::PackExpansionStatement>(node_id);
  if (!statement || context.parse_tree().node_kind(statement->body) !=
                        Parse::NodeKind::ExprStatement) {
    return context.TODO(node_id,
                        "pack expansion of a statement other than an "
                        "expression statement");
  }

  auto body_block_id = FinishPackExpansionBody(context, node_id, scope);
  if (!body_block_id) {
    return false;
  }
  if (!body_block_id->has_value()) {
    return true;
  }
  AddInst<SemIR::PackExpansionStatement>(
      context, node_id,
      {.arity_id = scope.arity_id, .body_block_id = *body_block_id});
  return true;
}

auto HandleParseNode(Context& context, Parse::PackExpansionExprId node_id)
    -> bool {
  auto result_id = context.node_stack().PopExpr();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::PackExpansionStart>();
  auto& stack = context.pack_expansion_stack();
  CARBON_CHECK(stack.back().kind == PackExpansionScope::Kind::Expr);

  // Each iteration's element is a value: a pack holds its elements' values
  // (fork VA-1, D-VA-3). The conversion is part of the body, so that an
  // element whose value needs a temporary gets one per iteration.
  if (context.insts().Get(result_id).type_id() != SemIR::ErrorInst::TypeId) {
    result_id = ConvertToValueExpr(context, result_id);
  }
  auto scope = stack.pop_back_val();

  auto body_block_id = FinishPackExpansionBody(context, node_id, scope);
  if (!body_block_id) {
    return false;
  }
  auto result_type_id = context.insts().Get(result_id).type_id();
  if (!body_block_id->has_value() ||
      result_type_id == SemIR::ErrorInst::TypeId) {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // "The type of a pack expansion expression or pattern is `...B`, where `B`
  // is the type of its body" (docs/design/variadics.md, "Typing and shaping
  // rules"): a pack of the body's type, with the arity of its each-names.
  auto pack_type_id = GetPackType(
      context, context.types().GetTypeInstId(result_type_id), scope.arity_id);
  // Lowering reads the pack type's value representation in every specific, so
  // each specific's pack type must be complete, even when nothing else requires
  // it, as when the call converts the elements to another type. For a symbolic
  // type, `RequireCompleteType` records that requirement in the generic (fork
  // VA-1, D-VA-7). Forming a value does not require every type complete (an
  // incomplete facet type, such as a forward-declared interface's, is not
  // diagnosed), so the element type can be incomplete here.
  if (!RequireCompleteType(context, pack_type_id, node_id, [&](auto& builder) {
        CARBON_DIAGNOSTIC(IncompleteTypeInPackExpansion, Context,
                          "forming a pack of incomplete type {0}",
                          SemIR::TypeId);
        builder.Context(node_id, IncompleteTypeInPackExpansion, result_type_id);
      })) {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // "`...` in a tuple literal behaves like a series of comma-separated tuple
  // elements" (docs/design/variadics.md, "Pack expansion expressions and
  // statements"), so the expansion is evaluated here, where it is written,
  // before the arguments that follow it (fork VA-1, D-VA-4).
  context.node_stack().Push(node_id, AddInst<SemIR::PackExpansionExpr>(
                                         context, node_id,
                                         {.type_id = pack_type_id,
                                          .body_block_id = *body_block_id,
                                          .result_id = result_id}));
  return true;
}

auto HandleParseNode(Context& context, Parse::PackExpansionPatternId node_id)
    -> bool {
  auto subpattern_id = context.node_stack().PopPattern();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::PackExpansionStart>();
  auto scope = context.pack_expansion_stack().pop_back_val();
  CARBON_CHECK(scope.kind == PackExpansionScope::Kind::Pattern);

  if (subpattern_id == SemIR::ErrorInst::InstId) {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }
  // Fork (VA-1, D-VA-5): the operand of a pack expansion pattern is a single
  // each-name binding, such as `... each x: i64`.
  if (scope.each_binding_pattern_id != subpattern_id) {
    return context.TODO(node_id,
                        "pack expansion pattern whose operand is not an "
                        "each-name binding");
  }

  // The scrutinee of the pattern is the run of arguments that it matches, of
  // type `«E; N»` for the element type `E` and the deduced arity `N`
  // (docs/design/variadics.md, "Explicit deduced arities").
  auto pack_type_id =
      GetPackType(context, scope.element_type_inst_id, scope.arity_binding_id);
  context.node_stack().Push(
      node_id, AddInst<SemIR::PackExpansionPattern>(
                   context, node_id,
                   {.type_id = GetPatternType(context, pack_type_id),
                    .subpattern_id = subpattern_id,
                    .arity_pattern_id = scope.arity_pattern_id}));
  return true;
}

auto HandleParseNode(Context& context, Parse::EachBindingNameId node_id)
    -> bool {
  // The enclosing binding pattern handles the each-name.
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::EachNameExprId node_id) -> bool {
  auto [name_node_id, name_id] = context.node_stack().PopNameWithNodeId();
  auto lookup = LookupUnqualifiedName(context, name_node_id, name_id);
  auto pack_id = lookup.scope_result.target_inst_id();
  if (pack_id == SemIR::ErrorInst::InstId) {
    InvalidateInnermostPackExpansion(context);
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // "An each-name consists of the keyword `each` followed by the name of a
  // pack, and can only occur inside a pack expansion" (docs/design/
  // variadics.md, "Packs and each-names").
  auto arity = context.pack_binding_arities().Lookup(pack_id);
  if (!arity) {
    CARBON_DIAGNOSTIC(EachNameNotPack, Error, "`each {0}` does not name a pack",
                      SemIR::NameId);
    context.emitter().Emit(node_id, EachNameNotPack, name_id);
    InvalidateInnermostPackExpansion(context);
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }
  auto& stack = context.pack_expansion_stack();
  if (stack.empty() || stack.back().kind == PackExpansionScope::Kind::Pattern) {
    CARBON_DIAGNOSTIC(EachNameOutsidePackExpansion, Error,
                      "each-name `each {0}` is not inside a pack expansion",
                      SemIR::NameId);
    context.emitter().Emit(node_id, EachNameOutsidePackExpansion, name_id);
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // "All each-names in a given expansion must refer to packs with the same
  // arity" (docs/design/variadics.md, "Pack expansions"). Fork (VA-1,
  // D-VA-5): a function has at most one pack, so this only fails for an
  // each-name of an enclosing function's pack.
  auto& scope = stack.back();
  if (!scope.arity_id.has_value()) {
    scope.arity_id = arity.value();
  } else if (scope.arity_id != arity.value() &&
             scope.arity_id != SemIR::ErrorInst::InstId) {
    return context.TODO(node_id,
                        "pack expansion over packs of different arities");
  }

  // On each iteration, `each x` is the element of the pack `x` at the pack
  // index (docs/design/variadics.md, "Execution Semantics": "An each-name
  // evaluates to the `$I`th value of the pack it refers to"), a value of the
  // pack's element type.
  auto pack_ref_id =
      BuildNameRef(context, node_id, name_id, pack_id, lookup.specific_id);
  auto pack_type = context.types().TryGetAs<SemIR::PackType>(
      context.insts().Get(pack_ref_id).type_id());
  if (!pack_type) {
    // The pack's element type was invalid, which was diagnosed.
    InvalidateInnermostPackExpansion(context);
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }
  auto index_id = AddInst<SemIR::PackIndex>(
      context, node_id,
      {.type_id =
           GetSingletonType(context, SemIR::IntLiteralType::TypeInstId)});
  context.node_stack().Push(
      node_id, AddInst<SemIR::PackElement>(
                   context, node_id,
                   {.type_id = context.types().GetTypeIdForTypeInstId(
                        pack_type->element_type_inst_id),
                    .pack_id = pack_ref_id,
                    .index_id = index_id}));
  return true;
}

auto HandleParseNode(Context& context, Parse::PrefixOperatorExpandId node_id)
    -> bool {
  return context.TODO(node_id, "HandlePrefixOperatorExpand");
}

}  // namespace Carbon::Check
