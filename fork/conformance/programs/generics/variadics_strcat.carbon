// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   3
//   41107
//   0
//   0
//
// The design's StrCat (docs/design/variadics.md, "Additional examples"), its
// body as the design spells it. Core has no `ConvertibleToString` and its
// `String` has no `Reserve` or `Append`, so this program declares the
// interface and a class `Str` with those two methods for `String`; and
// `ToString` returns a one-character code as an `i64`, because a class or
// struct result is a temporary that each iteration would have to destroy,
// which statement expansions do not do yet. StrCat(4 as i32, true, 7 as i32)
// reserves the sum of the lengths, 1 + 2 + 1 = 4, and appends three codes in
// order, 4, 11 and 7, each shifting the code two digits: 41107. StrCat() of
// no arguments reserves 0 and appends nothing.

import Core library "io";

class Str {
  var reserved: i64;
  var appended: i64;
  var code: i64;
  fn Reserve(ref self, n: i64) { self.reserved = n; }
  fn Append(ref self, c: i64) {
    self.code = self.code * 100 + c;
    self.appended = self.appended + 1;
  }
}

impl Str as Core.Copy {
  fn Op(self) -> Self {
    return {.reserved = self.reserved, .appended = self.appended,
            .code = self.code};
  }
}

interface ConvertibleToString {
  fn Length(self) -> i64;
  fn ToString(self) -> i64;
}

impl i32 as ConvertibleToString {
  fn Length(unused self) -> i64 { return 1; }
  fn ToString(self) -> i64 { return self as i64; }
}

impl bool as ConvertibleToString {
  fn Length(unused self) -> i64 { return 2; }
  fn ToString(self) -> i64 {
    if (self) {
      return 11;
    }
    return 10;
  }
}

fn StrCat[... each T: ConvertibleToString](... each param: each T) -> Str {
  var len: i64 = 0;
  ... len += each param.Length();
  var result: Str = {.reserved = 0, .appended = 0, .code = 0};
  result.Reserve(len);
  ... result.Append(each param.ToString());
  return result;
}

fn Run() -> i32 {
  let s: Str = StrCat(4 as i32, true, 7 as i32);
  Core.Print(s.reserved as i32);
  Core.Print(s.appended as i32);
  Core.Print(s.code as i32);
  let e: Str = StrCat();
  Core.Print(e.reserved as i32);
  Core.Print(e.appended as i32);
  return 0;
}
