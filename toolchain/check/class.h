// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_CLASS_H_
#define CARBON_TOOLCHAIN_CHECK_CLASS_H_

#include <tuple>

#include "toolchain/check/context.h"
#include "toolchain/check/decl_introducer_state.h"
#include "toolchain/check/name_component.h"
#include "toolchain/lex/token_kind.h"
#include "toolchain/parse/node_ids.h"

namespace Carbon::Check {

// Builds the `SemIR::Class` and `ClassDecl` for a `class` or `union`
// declaration or definition, merging with a previous declaration where one
// exists. The caller has already popped the name component, the introducer
// node and the introducer state; `decl_kind` is `Class` or `Union` and selects
// the allowed modifiers, the inheritance kind and `ClassFields::is_union`.
// Returns the class and the `ClassDecl` instruction.
auto BuildClassOrUnionDecl(Context& context, Parse::AnyClassDeclId node_id,
                           bool is_definition, NameComponent name,
                           DeclIntroducerState introducer,
                           Lex::TokenKind decl_kind)
    -> std::tuple<SemIR::ClassId, SemIR::InstId>;

// Sets the `Self` type for the class.
auto SetClassSelfType(Context& context, SemIR::ClassId class_id) -> void;

// Starts the class definition, adding `Self` to name lookup.
auto StartClassDefinition(Context& context, SemIR::Class& class_info,
                          SemIR::InstId definition_id) -> void;

// Computes the object representation for a fully defined class.
auto ComputeClassObjectRepr(Context& context, Parse::ClassDefinitionId node_id,
                            SemIR::ClassId class_id,
                            llvm::ArrayRef<SemIR::InstId> field_decls,
                            llvm::ArrayRef<SemIR::InstId> vtable_contents,
                            llvm::ArrayRef<SemIR::InstId> body) -> void;

// Computes the object representation for a fully defined union: a
// `CustomLayoutType` with every field at offset zero, sized and aligned by the
// max-of-fields rule (docs/design/unions.md, "Layout"), after enforcing the
// at-least-one-field rule and the 0.1 field rules (trivially destructible and
// no `Core.Copy` impl declared outside package `Core`). A generic union
// completes with an error witness behind a `generic union` TODO.
auto ComputeUnionObjectRepr(Context& context, Parse::UnionDefinitionId node_id,
                            SemIR::ClassId class_id,
                            llvm::ArrayRef<SemIR::InstId> field_decls,
                            llvm::ArrayRef<SemIR::InstId> vtable_contents)
    -> void;

// Whether a non-static field decl is currently being checked.
auto InNonStaticFieldDecl(Context& context) -> bool;

// Whether a static class var decl is currently being checked.
auto InStaticClassScopeVar(Context& context) -> bool;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_CLASS_H_
