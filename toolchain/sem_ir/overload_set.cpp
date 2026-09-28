// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/sem_ir/overload_set.h"

#include "llvm/ADT/STLExtras.h"
#include "toolchain/base/value_store_impl.h"
#include "toolchain/sem_ir/file.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::SemIR {

auto GetOverloadMemberIndex(const File& sem_ir, const OverloadSet& overload_set,
                            FunctionId function_id) -> int {
  for (auto [index, member_decl_id] :
       llvm::enumerate(overload_set.member_decl_ids)) {
    if (sem_ir.insts().GetAs<FunctionDecl>(member_decl_id).function_id ==
        function_id) {
      return static_cast<int>(index);
    }
  }
  return -1;
}

}  // namespace Carbon::SemIR

namespace Carbon {
template class ValueStore<SemIR::OverloadSetId, SemIR::OverloadSet,
                          Tag<SemIR::CheckIRId>>;
}  // namespace Carbon
