// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/cpp/slice";

import library "prelude/copy";
import library "prelude/destroy";
import library "prelude/operators";
import library "prelude/types/int";
import library "prelude/types/optional";
import library "prelude/types/slice";
import library "prelude/types/uint";

// Owning C++ container -> `Core.Slice` view (fork/slices/plan.md §1.B.3,
// D-SL-9). A C++ class with member functions `data()` and `size()` -- an
// owning contiguous container such as `std::vector<T>` or `std::array<T, N>`
// -- implements `CppContiguousRange` through a witness the toolchain
// synthesizes (check/cpp/impl_lookup.cpp), the `CppRangeForIterate` mechanism
// of prelude/iterate.carbon. The blanket impl below then converts such a
// container implicitly to `Core.Slice(Element)`, where `Element` is the
// pointee of `data()`'s result: when the container has both a `const` and a
// non-`const` `data()`, the synthesized witness selects the `const` one, so a
// `std::vector<int>` views as `Core.Slice(const i32)` -- the type a
// `std::span<const int>` parameter imports as.
//
// This library lives beside the other C++-compat prelude types rather than in
// prelude/types/slice.carbon because the `Size` conversion names `u64`, which
// that file does not import; adding an import line there would move every
// `Slice` method's source line (the DI-line churn rule, plan §6.B).

private interface CppContiguousRange {
  let DataType: type;
  let SizeType: type;
  // TODO: self must be ref-qualified (as CppRangeForIterate).
  fn Data(self) -> DataType;
  fn Size(self) -> SizeType;
}

// The element type behind a C++ `data()` result, which maps to `T*` when
// `_Nonnull` and to `Optional(T*)` otherwise.
private interface CppDataPointer {
  let Element: type;
  fn Raw(self) -> Element*;
}
impl forall [T: type] T* as CppDataPointer where .Element = T {
  fn Raw(self) -> T* { return self; }
}
impl forall [T: type] Optional(T*) as CppDataPointer where .Element = T {
  // `None` (an empty container) yields the null pointer; a zero-size slice
  // never dereferences it.
  fn Raw(self) -> T* { return self.Get(); }
}

private constraint CppContiguous {
  extend require impls CppContiguousRange;
  require Self.(DataType) impls CppDataPointer;
  // `ImplicitAs(u64)`, not `As(i64)`: `CppCompat.ULong64` (macOS `size_t`)
  // has no `As(i64)` impl (D-SL-9).
  require Self.(SizeType) impls ImplicitAs(u64);
  alias Element = Self.(DataType).(CppDataPointer.Element);
}

impl forall [C: CppContiguous where .Element impls Copy & Destroy]
    C as ImplicitAs(Slice(C.Element)) {
  fn Convert(self) -> Slice(C.Element) {
    return Slice(C.Element).UnsafeMake(
        self.Data().(CppDataPointer.Raw)(),
        self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
  }
}
