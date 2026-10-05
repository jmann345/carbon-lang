// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/slice";

import library "prelude/copy";
import library "prelude/default";
import library "prelude/destroy";
import library "prelude/operators";
import library "prelude/types/bool";
import library "prelude/types/int";
import library "prelude/types/int_literal";
// Used only by the interop section SL-2 appends (§1.B.3); imported at SL-1
// so that SL-2 adds no line above any method (§6.B, DI-line churn).
import library "prelude/types/optional";
import library "prelude/types/string";

private fn PointerOffset[T: type](p: T*, n: i64) -> T* = "pointer.offset";
private fn FailStop(message: str) = "fail_stop";
private fn ArrayData[T: type, N: IntLiteral](p: array(T, N)*) -> T*
    = "pointer.unsafe_convert";

class Slice(T: Copy & Destroy) {
  // A view of the `N` elements of `*p`.
  fn FromArray[N: IntLiteral](p: array(T, N)*) -> Self {
    return {.ptr = ArrayData(p), .size = N};
  }
  // A view of `size` elements starting at `p`. The caller guarantees
  // that `p` names at least `size` valid elements that outlive the view.
  fn UnsafeMake(p: T*, size: i64) -> Self {
    return {.ptr = p, .size = size};
  }
  fn Size(self) -> i64 { return self.size; }
  // The raw pointer to element 0 (the twin of `std::span::data()`); no
  // arithmetic on it is possible from user code.
  fn Data(self) -> T* { return self.ptr; }
  // Bounds-checked read; a violation fails-stop (D-SL-4).
  fn Get(self, i: i64) -> T {
    if (i < 0 or i >= self.size) {
      FailStop("carbon: Core.Slice index out of bounds; terminating\n");
    }
    return *PointerOffset(self.ptr, i);
  }
  // The half-open sub-view `[start, end)`; `0 <= start <= end <= Size()`.
  fn Subslice(self, start: i64, end: i64) -> Self {
    if (start < 0 or end < start or end > self.size) {
      FailStop(
          "carbon: Core.Slice.Subslice range out of bounds; terminating\n");
    }
    return {.ptr = PointerOffset(self.ptr, start), .size = end - start};
  }

  impl as Copy {
    fn Op(self) -> Self { return {.ptr = self.ptr, .size = self.size}; }
  }

  private var ptr: T*;
  private var size: i64;
}

impl forall [T: Copy & Destroy] Slice(T) as UnformedInit {}

// Subscripts are `i64`. An integer literal subscript converts to `i64` at the
// index expression (check/handle_index.cpp, the literal-subscript rule), so
// `s[1]` and `s[i]` with `i: i64` both reach this impl. Not a blanket
// `IndexWith(U: ImplicitAs(i64))` impl: for `U = IntLiteral` its `At` would
// call a compile-time-only conversion on a runtime `subscript`, which cannot
// be lowered (`String`'s blanket impl lowers only because its `At` is itself a
// builtin). `final`, so that in a generic body `s[i]` on a `Slice(T)` has type
// `T` — a symbolic query resolves only final impls, and through a non-final
// impl `.ElementType` stays the abstract
// `Slice(T).(IndexWith(i64).ElementType)` (the `Optional(T) as Try` pattern).
final impl forall [T: Copy & Destroy] Slice(T) as IndexWith(i64)
    where .ElementType = T {
  fn At(self, subscript: i64) -> T { return self.Get(subscript); }
}

// `const` can be added to the element type (D-SL-10).
impl forall [T: Copy & Destroy] Slice(T) as ImplicitAs(Slice(const T)) {
  fn Convert(self) -> Slice(const T) {
    return Slice(const T).UnsafeMake(self.Data() as const T*, self.Size());
  }
}
