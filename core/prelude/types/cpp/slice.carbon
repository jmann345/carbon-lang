// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/cpp/slice";

import library "prelude/copy";
import library "prelude/destroy";
import library "prelude/operators";
import library "prelude/types/int";
import library "prelude/types/optional";
import library "prelude/types/uint";

// The helpers behind the owning C++ container -> `Core.Slice` view
// (fork/slices/plan.md §1.B.3, D-SL-9). A C++ class with member functions
// `data()` and `size()` -- an owning contiguous container such as
// `std::vector<T>` or `std::array<T, N>` -- implements `CppContiguousRange`
// through a witness the toolchain synthesizes (check/cpp/impl_lookup.cpp), the
// `CppRangeForIterate` mechanism of prelude/iterate.carbon.
//
// The blanket `ImplicitAs(Slice(C.Element))` impl that uses these helpers
// lives in prelude/types/slice.carbon, beside `Slice`, not here: the orphan
// rule (check/impl_validation.cpp `DiagnoseOrphanImpl`) anchors an impl on a
// class of its self type or of its interface arguments, and impl lookup
// imports candidates only from the libraries that own the query's types
// (check/impl_lookup.cpp `FindAssociatedImportIRs`) -- a facet-type bound on
// the self binding is neither. So this library imports no `Slice` (slice.carbon
// imports it), and `CppSizeToI64` keeps the `u64` of the size conversion out
// of slice.carbon. The names are public Core names, as `CppUnsafeDeref`
// (prelude/operators/deref.carbon) is, because slice.carbon's impl names them.

interface CppContiguousRange {
  let DataType: type;
  let SizeType: type;
  // TODO: self must be ref-qualified (as CppRangeForIterate).
  fn Data(self) -> DataType;
  fn Size(self) -> SizeType;
}

// The element type behind a C++ `data()` result, which maps to `T*` when
// `_Nonnull` and to `Optional(T*)` otherwise.
interface CppDataPointer {
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

// The `i64` size behind a C++ `size()` result. Two steps, `ImplicitAs(u64)`
// then `As(i64)`, never `As(i64)` directly: `CppCompat.ULong64` (`size_t`
// where it is `unsigned long`, that is Linux and macOS) has no `As(i64)` impl
// (D-SL-9). A signed `size()` (`int`, the Qt shape) has no `ImplicitAs(u64)`
// and so no view; the conversion fails gracefully.
interface CppSizeToI64 {
  fn Op(self) -> i64;
}
impl forall [T: ImplicitAs(u64)] T as CppSizeToI64 {
  fn Op(self) -> i64 {
    return self.(ImplicitAs(u64).Convert)().(As(i64).Convert)();
  }
}

constraint CppContiguous {
  extend require impls CppContiguousRange;
  // `Destroy` on both: the `Data()` and `Size()` results are temporaries in
  // the blanket impl's `Convert` body, and a synthesized witness provides the
  // associated types as bare `type`s (custom_witness.cpp `BuildCustomWitness`
  // supports no other associated-constant type), so the destroy requirement
  // is stated here -- the `CppIterator` shape of prelude/iterate.carbon, whose
  // `Inc & Destroy` serves `++cursor->0` the same way.
  require Self.(DataType) impls CppDataPointer & Destroy;
  require Self.(SizeType) impls CppSizeToI64 & Destroy;
  alias Element = Self.(DataType).(CppDataPointer.Element);
}
