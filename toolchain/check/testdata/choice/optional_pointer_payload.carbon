// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/optional_pointer_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/optional_pointer_payload.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md D-SV-8): the SF-6 payload
// predicate admits the pointer-niche `Core.Optional(T*)` -- an adapter of
// `MaybeUnformed(T*)` -- by name, as a pointer payload; `Core.Optional(T)` for
// a non-pointer `T`, and the other qualified adapters (`Cpp.nullptr_t`,
// `Core.MaybeUnformed(T)`), are still not payloads.

// --- pointer.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Slot {
  Held(p: Core.Optional(i32*)),
  Empty
}

fn Read(s: Slot) -> bool {
  match (s) {
    case .Held(p: Core.Optional(i32*)) => {
      return p.HasValue();
    }
    case .Empty => {
      return false;
    }
  }
  return false;
}
//@dump-sem-ir-end

// --- fail_todo_non_pointer_optional.carbon

library "[[@TEST_NAME]]";

choice Boxed {
  Held(o: Core.Optional(i32)),
  Empty
}

// --- fail_todo_nullptr_payload.carbon

library "[[@TEST_NAME]]";

choice NullBox {
  Held(p: Core.CppCompat.NullptrT),
  Empty
}

// --- fail_todo_maybe_unformed_payload.carbon

library "[[@TEST_NAME]]";

choice Unformed {
  Held(x: Core.MaybeUnformed(i32*)),
  Empty
}

