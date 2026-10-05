// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/buf";

import library "prelude/copy";
import library "prelude/default";
import library "prelude/destroy";
import library "prelude/operators";
import library "prelude/types/bool";
import library "prelude/types/int";
import library "prelude/types/maybe_unformed";
import library "prelude/types/slice";
import library "prelude/types/string";

private fn PointerOffset[T: type](p: T*, n: i64) -> T* = "pointer.offset";
private fn FailStop(message: str) = "fail_stop";
private fn HeapAllocate(generic T: type, count: i64) -> MaybeUnformed(T*)
    = "heap.allocate";
private fn HeapFree[T: type](p: T*) = "heap.free";
private fn PointerIsNull[T: type](value: MaybeUnformed(T*)) -> bool
    = "pointer.is_null";

// An owning, heap-allocated buffer of `size` values of `T`. Not copyable.
class Buf(T: Copy & Destroy) {
  // Allocates `size` elements, each initialized to a copy of `fill`.
  fn Make(size: i64, fill: T) -> Self {
    if (size < 0) {
      FailStop("carbon: Core.Buf size is negative; terminating\n");
    }
    var storage: MaybeUnformed(T*) = HeapAllocate(T, size);
    if (PointerIsNull(storage)) {
      FailStop("carbon: heap allocation failed; terminating\n");
    }
    let ptr: T* = storage unsafe as T*;
    var i: i64 = 0;
    while (i < size) {
      *PointerOffset(ptr, i) = fill;
      ++i;
    }
    return {.ptr = ptr, .size = size};
  }
  fn Size(self) -> i64 { return self.size; }
  fn Get(self, i: i64) -> T { return self.AsSlice().Get(i); }
  // Bounds-checked write. `self` is by value: the storage is the heap
  // block, not the `Buf` object.
  fn Set(self, i: i64, value: T) {
    if (i < 0 or i >= self.size) {
      FailStop("carbon: Core.Buf index out of bounds; terminating\n");
    }
    *PointerOffset(self.ptr, i) = value;
  }
  fn AsSlice(self) -> Slice(T) {
    return Slice(T).UnsafeMake(self.ptr, self.size);
  }

  impl as Destroy {
    fn Op(ref self) { HeapFree(self.ptr); }
  }

  private var ptr: T*;
  private var size: i64;
}

// No `UnformedInit`: `Destroy` runs unconditionally on `var` storage, so an
// unformed `Buf` would free a garbage pointer (D-SL-6).

// `i64` subscripts, as for `Slice` (an integer literal converts at the index
// expression, check/handle_index.cpp); `final` for the same reason — `b[i]`
// on a `Buf(T)` in a generic body has type `T`.
final impl forall [T: Copy & Destroy] Buf(T) as IndexWith(i64)
    where .ElementType = T {
  fn At(self, subscript: i64) -> T { return self.Get(subscript); }
}
