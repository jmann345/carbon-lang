// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/string";

import library "prelude/copy";
import library "prelude/default";
import library "prelude/destroy";
import library "prelude/types/char";
import library "prelude/types/uint";
import library "prelude/operators";
import library "prelude/types/int";
import library "prelude/types/maybe_unformed";

class String {
  fn Size(self) -> i64 { return self.size; }

  impl as Copy {
    fn Op(self) -> Self { return {.ptr = self.ptr, .size = self.size}; }
  }
  // TODO: This should be an array iterator.
  private var ptr: Char*;
  // TODO: This should be a word-sized integer.
  private var size: i64;

  // A view of the `size` bytes starting at `p`. The caller guarantees that
  // they stay valid and unchanged for as long as the view is used.
  fn UnsafeMake(p: Char*, size: i64) -> Self {
    return {.ptr = p, .size = size};
  }
}

impl String as UnformedInit {}

impl forall [T: ImplicitAs(i64)] String as IndexWith(T) where .ElementType = Char {
  fn At(self, subscript: i64) -> Char = "string.at";
}

// Fork (ST-1, fork/string/plan.md): byte-wise equality and ordering, the
// owning `StringBuf`, and concatenation with `+` and `+=`.

private fn PointerOffset[T: type](p: T*, n: i64) -> T* = "pointer.offset";
private fn FailStop(message: str) = "fail_stop";
private fn HeapAllocate(generic T: type, count: i64) -> MaybeUnformed(T*)
    = "heap.allocate";
private fn HeapFree[T: type](p: T*) = "heap.free";
private fn PointerIsNull[T: type](value: MaybeUnformed(T*)) -> bool
    = "pointer.is_null";

// Whether `a` and `b` hold the same bytes.
private fn BytesEqual(a: str, b: str) -> bool {
  let size: i64 = a.Size();
  if (size != b.Size()) {
    return false;
  }
  var i: i64 = 0;
  while (i < size) {
    if (a[i] != b[i]) {
      return false;
    }
    ++i;
  }
  return true;
}

// Lexicographic order on bytes compared as unsigned values, a proper prefix
// first: -1, 0 or 1 as `a` orders before, the same as, or after `b`.
private fn BytesCompare(a: str, b: str) -> i32 {
  let a_size: i64 = a.Size();
  let b_size: i64 = b.Size();
  var i: i64 = 0;
  while (i < a_size and i < b_size) {
    let a_byte: Char = a[i];
    let b_byte: Char = b[i];
    if (a_byte < b_byte) {
      return -1;
    }
    if (a_byte > b_byte) {
      return 1;
    }
    ++i;
  }
  if (a_size < b_size) {
    return -1;
  }
  if (a_size > b_size) {
    return 1;
  }
  return 0;
}

// A new heap block holding the bytes of `a` followed by those of `b`. A
// zero-byte request still yields a block (the "heap.allocate" lowering).
private fn JoinBytes(a: str, b: str) -> Char* {
  let a_size: i64 = a.Size();
  let b_size: i64 = b.Size();
  var storage: MaybeUnformed(Char*) = HeapAllocate(Char, a_size + b_size);
  if (PointerIsNull(storage)) {
    FailStop("carbon: heap allocation failed; terminating\n");
  }
  let block: Char* = storage unsafe as Char*;
  var i: i64 = 0;
  while (i < a_size) {
    *PointerOffset(block, i) = a[i];
    ++i;
  }
  var j: i64 = 0;
  while (j < b_size) {
    *PointerOffset(block, a_size + j) = b[j];
    ++j;
  }
  return block;
}

impl String as EqWith(String) {
  fn Equal(self, other: String) -> bool { return BytesEqual(self, other); }
  fn NotEqual(self, other: String) -> bool {
    return not BytesEqual(self, other);
  }
}

impl String as OrderedWith(String) {
  fn Less(self, other: String) -> bool {
    return BytesCompare(self, other) < 0;
  }
  fn LessOrEquivalent(self, other: String) -> bool {
    return BytesCompare(self, other) <= 0;
  }
  fn Greater(self, other: String) -> bool {
    return BytesCompare(self, other) > 0;
  }
  fn GreaterOrEquivalent(self, other: String) -> bool {
    return BytesCompare(self, other) >= 0;
  }
}

// An owning, heap-allocated byte string; `str` is its view. Not copyable: a
// copy is `StringBuf.Make(s)`. Not `UnformedInit`: `Destroy` runs
// unconditionally on `var` storage, as for `Buf`.
class StringBuf {
  // A new string holding a copy of the bytes of `s`.
  fn Make(s: str) -> Self {
    return {.ptr = JoinBytes(s, ""), .size = s.Size()};
  }
  // A new string holding the bytes of `a` followed by those of `b`.
  fn Concat(a: str, b: str) -> Self {
    return {.ptr = JoinBytes(a, b), .size = a.Size() + b.Size()};
  }
  fn Size(self) -> i64 { return self.size; }
  // A view of the bytes, valid until `self` is destroyed or appended to.
  fn AsStr(self) -> str { return String.UnsafeMake(self.ptr, self.size); }

  impl as Destroy {
    fn Op(ref self) { HeapFree(self.ptr); }
  }

  // Appends in a new block and then frees the old one, so `other` may be a
  // view of `self`.
  impl as AddAssignWith(str) {
    fn Op(ref self, other: str) {
      let block: Char* = JoinBytes(self.AsStr(), other);
      HeapFree(self.ptr);
      self.size = self.size + other.Size();
      self.ptr = block;
    }
  }

  private var ptr: Char*;
  private var size: i64;
}

impl StringBuf as ImplicitAs(str) {
  fn Convert(self) -> str { return self.AsStr(); }
}

impl StringBuf as AddAssignWith(StringBuf) {
  fn Op(ref self, other: StringBuf) { self += other.AsStr(); }
}

impl String as AddWith(String) where .Result = StringBuf {
  fn Op(self, other: String) -> StringBuf {
    return StringBuf.Concat(self, other);
  }
}

impl String as AddWith(StringBuf) where .Result = StringBuf {
  fn Op(self, other: StringBuf) -> StringBuf {
    return StringBuf.Concat(self, other.AsStr());
  }
}

impl StringBuf as AddWith(String) where .Result = StringBuf {
  fn Op(self, other: String) -> StringBuf {
    return StringBuf.Concat(self.AsStr(), other);
  }
}

impl StringBuf as AddWith(StringBuf) where .Result = StringBuf {
  fn Op(self, other: StringBuf) -> StringBuf {
    return StringBuf.Concat(self.AsStr(), other.AsStr());
  }
}

impl String as EqWith(StringBuf) {
  fn Equal(self, other: StringBuf) -> bool {
    return BytesEqual(self, other.AsStr());
  }
  fn NotEqual(self, other: StringBuf) -> bool {
    return not BytesEqual(self, other.AsStr());
  }
}

impl StringBuf as EqWith(String) {
  fn Equal(self, other: String) -> bool {
    return BytesEqual(self.AsStr(), other);
  }
  fn NotEqual(self, other: String) -> bool {
    return not BytesEqual(self.AsStr(), other);
  }
}

impl StringBuf as EqWith(StringBuf) {
  fn Equal(self, other: StringBuf) -> bool {
    return BytesEqual(self.AsStr(), other.AsStr());
  }
  fn NotEqual(self, other: StringBuf) -> bool {
    return not BytesEqual(self.AsStr(), other.AsStr());
  }
}

impl String as OrderedWith(StringBuf) {
  fn Less(self, other: StringBuf) -> bool {
    return BytesCompare(self, other.AsStr()) < 0;
  }
  fn LessOrEquivalent(self, other: StringBuf) -> bool {
    return BytesCompare(self, other.AsStr()) <= 0;
  }
  fn Greater(self, other: StringBuf) -> bool {
    return BytesCompare(self, other.AsStr()) > 0;
  }
  fn GreaterOrEquivalent(self, other: StringBuf) -> bool {
    return BytesCompare(self, other.AsStr()) >= 0;
  }
}

impl StringBuf as OrderedWith(String) {
  fn Less(self, other: String) -> bool {
    return BytesCompare(self.AsStr(), other) < 0;
  }
  fn LessOrEquivalent(self, other: String) -> bool {
    return BytesCompare(self.AsStr(), other) <= 0;
  }
  fn Greater(self, other: String) -> bool {
    return BytesCompare(self.AsStr(), other) > 0;
  }
  fn GreaterOrEquivalent(self, other: String) -> bool {
    return BytesCompare(self.AsStr(), other) >= 0;
  }
}

impl StringBuf as OrderedWith(StringBuf) {
  fn Less(self, other: StringBuf) -> bool {
    return BytesCompare(self.AsStr(), other.AsStr()) < 0;
  }
  fn LessOrEquivalent(self, other: StringBuf) -> bool {
    return BytesCompare(self.AsStr(), other.AsStr()) <= 0;
  }
  fn Greater(self, other: StringBuf) -> bool {
    return BytesCompare(self.AsStr(), other.AsStr()) > 0;
  }
  fn GreaterOrEquivalent(self, other: StringBuf) -> bool {
    return BytesCompare(self.AsStr(), other.AsStr()) >= 0;
  }
}
