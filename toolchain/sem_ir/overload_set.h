// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_SEM_IR_OVERLOAD_SET_H_
#define CARBON_TOOLCHAIN_SEM_IR_OVERLOAD_SET_H_

#include "common/ostream.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringExtras.h"
#include "toolchain/base/value_store.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::SemIR {

// A closed set of Carbon functions declared with the `overload fn` marker
// under one name in one scope (fork decision F-009, D-OV-2). Name lookup of
// the overloaded name resolves to an `OverloadSetValue` of type
// `OverloadSetType`; calls are resolved by declaration-order first-match over
// `member_decl_ids`.
struct OverloadSet : public Printable<OverloadSet> {
  // The set's name.
  NameId name_id;

  // The parent scope.
  NameScopeId parent_scope_id;

  // The `FunctionDecl` instruction of the first declaration of each member, in
  // declaration order. Append-only: a member's index is its position here and
  // is part of its mangled name (D-OV-5).
  llvm::SmallVector<InstId, 4> member_decl_ids;

  auto Print(llvm::raw_ostream& out) const -> void {
    out << "{name: " << name_id << ", parent_scope: " << parent_scope_id
        << ", members: [";
    llvm::ListSeparator sep;
    for (auto member_decl_id : member_decl_ids) {
      out << sep << member_decl_id;
    }
    out << "]}";
  }
};

using OverloadSetStore = ValueStore<OverloadSetId, OverloadSet, Tag<CheckIRId>>;

class File;

// Returns the position of `function_id` in `overload_set.member_decl_ids`, or
// -1 if the function is not a member of the set.
auto GetOverloadMemberIndex(const File& sem_ir, const OverloadSet& overload_set,
                            FunctionId function_id) -> int;

}  // namespace Carbon::SemIR

namespace Carbon {
extern template class ValueStore<SemIR::OverloadSetId, SemIR::OverloadSet,
                                 Tag<SemIR::CheckIRId>>;
}  // namespace Carbon

#endif  // CARBON_TOOLCHAIN_SEM_IR_OVERLOAD_SET_H_
