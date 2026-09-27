// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <tuple>

#include "toolchain/check/class.h"
#include "toolchain/check/context.h"
#include "toolchain/check/decl_name_stack.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/name_component.h"
#include "toolchain/lex/token_kind.h"
#include "toolchain/parse/node_ids.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Check {

// A `union` is a `SemIR::Class` with `ClassFields::is_union` whose object
// representation is an all-offsets-zero `CustomLayoutType`
// (docs/design/unions.md, "Layout"). Its declaration and definition follow the
// class handlers exactly, with `BuildClassOrUnionDecl` shared and the object
// representation computed by `ComputeUnionObjectRepr`.

auto HandleParseNode(Context& context, Parse::UnionIntroducerId node_id)
    -> bool {
  // This union is potentially generic; a generic union is diagnosed at its
  // definition (`ComputeUnionObjectRepr`).
  StartGenericDecl(context);
  // Create an instruction block to hold the instructions created as part of the
  // union signature, such as generic parameters.
  context.inst_block_stack().Push();
  // Push the bracketing node.
  context.node_stack().Push(node_id);
  // Optional modifiers and the name follow.
  context.decl_introducer_state_stack().Push<Lex::TokenKind::Union>();
  context.decl_name_stack().PushScopeAndStartName();
  return true;
}

// Pops the union name and introducer and builds the union declaration.
static auto BuildUnionDecl(Context& context, Parse::AnyUnionDeclId node_id,
                           bool is_definition)
    -> std::tuple<SemIR::ClassId, SemIR::InstId> {
  auto name = PopNameComponent(context);
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::UnionIntroducer>();
  auto introducer =
      context.decl_introducer_state_stack().Pop<Lex::TokenKind::Union>();
  return BuildClassOrUnionDecl(context, node_id, is_definition, name,
                               introducer, Lex::TokenKind::Union);
}

auto HandleParseNode(Context& context, Parse::UnionDeclId node_id) -> bool {
  BuildUnionDecl(context, node_id, /*is_definition=*/false);
  context.decl_name_stack().PopScope();
  return true;
}

auto HandleParseNode(Context& context, Parse::UnionDefinitionStartId node_id)
    -> bool {
  auto [class_id, class_decl_id] =
      BuildUnionDecl(context, node_id, /*is_definition=*/true);
  auto& class_info = context.classes().Get(class_id);
  StartClassDefinition(context, class_info, class_decl_id);

  // Enter the union scope.
  context.scope_stack().PushForEntity(
      class_decl_id, class_info.scope_id,
      context.generics().GetSelfSpecific(class_info.generic_id));
  StartGenericDefinition(context, class_info.generic_id);

  context.inst_block_stack().Push();
  context.node_stack().Push(node_id, class_id);
  context.field_decls_stack().PushArray();
  // Kept for symmetry with the class path; a union can never request a
  // vtable (`virtual` is forbidden for a final class), and
  // `ComputeUnionObjectRepr` checks the block stays empty.
  context.vtable_stack().Push();

  class_info.body_block_id = context.inst_block_stack().PeekOrAdd();
  return true;
}

auto HandleParseNode(Context& context, Parse::UnionDefinitionId node_id)
    -> bool {
  auto class_id =
      context.node_stack().Pop<Parse::NodeKind::UnionDefinitionStart>();

  // The union type is now fully defined. Compute its object representation.
  ComputeUnionObjectRepr(context, node_id, class_id,
                         context.field_decls_stack().PeekArray(),
                         context.vtable_stack().PeekCurrentBlockContents());

  context.inst_block_stack().Pop();
  context.field_decls_stack().PopArray();
  context.vtable_stack().Pop();

  FinishGenericDefinition(context, context.classes().Get(class_id).generic_id);

  // The decl_name_stack and scopes are popped by `ProcessNodeIds`.
  return true;
}

}  // namespace Carbon::Check
