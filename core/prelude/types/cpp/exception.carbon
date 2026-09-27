// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/cpp/exception";

import library "prelude/copy";
import library "prelude/default";
import library "prelude/types/cpp/void";

namespace CppCompat;

// A caught C++ exception as a Carbon type (docs/design/error_handling.md,
// "`Cpp.Exception`"; decision F-006g).
//
// This class is surfaced in the `Cpp` package as `Cpp.Exception` by the same
// file-less builtin path as `Cpp.nullptr` (toolchain/check/cpp/import.cpp,
// `LookupBuiltinName`), and `Exception` is a reserved name at the top of that
// package: a header's own global `Exception` is not reachable under it.
//
// Storage (fork/eh/plan.md D-EH-3): the Itanium primary exception object
// pointer returned by `__cxa_current_primary_exception()` inside a catching
// thunk, which on libc++abi is exactly what `std::exception_ptr` holds. The
// capture increments the exception object's refcount once; the C++ support
// header `<carbon/expected.h>` reconstitutes a real `std::exception_ptr` from
// it losslessly (`Carbon::Exception::ptr()`), or rethrows it. A foreign
// (non-C++-runtime) exception yields a null pointer here, which the header
// treats as "no exception object".
//
// 0.1 bounds (both forced by the scalar choice-payload rule, SF-6): the type
// is trivially copyable and trivially destructible, so the refcount taken at
// capture is released only at process exit; and the lazy `TypeName()` /
// `Message()` accessors of the design are deferred (residue item
// "`Cpp.Exception` accessors and release-on-destroy").
class CppCompat.Exception {
  adapt VoidBase*;
}

impl CppCompat.Exception as Copy {
  fn Op(self) -> Self = "primitive_copy";
}

impl CppCompat.Exception as UnformedInit {}
