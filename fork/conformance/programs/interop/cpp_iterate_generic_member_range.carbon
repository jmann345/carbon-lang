// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib C++ interop: transparent iteration-abstraction mapping
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   11
//
// Transparent mapping of the C++ iteration abstraction (member `begin()`/
// `end()` returning an iterator with operator*/++/==/!=) onto Carbon's
// iteration abstraction (`Core.Iterate`): a Carbon generic function
// constrained only on `Core.Iterate where .ElementType = i32` — with no
// knowledge of C++ — consumes the C++ range directly. The toolchain
// synthesizes a `CppRangeForIterate` witness for the imported class
// (toolchain/check/cpp/impl_lookup.cpp) and the blanket
// `impl forall [T: CppRange ...] T as Iterate` in core/prelude/iterate.carbon
// maps it into `Core.Iterate`, so deduction and the range-based `for` inside
// the generic just work. Shapes from
// check/testdata/interop/cpp/range_for.carbon (methods_return_same_type:
// `fn TestIterate[R: Core.Iterate where .ElementType = i32](r: R)` called
// with a C++ range), with C++ bodies filled in so the program links and runs.

import Core library "io";
import Cpp inline '''c++
class Fib {
 public:
  struct Iterator {
    const int* p;
    auto operator*() const -> const int& { return *p; }
    auto operator++() -> Iterator& {
      ++p;
      return *this;
    }
    friend auto operator==(Iterator a, Iterator b) -> bool { return a.p == b.p; }
    friend auto operator!=(Iterator a, Iterator b) -> bool { return a.p != b.p; }
  };

  static auto Make() -> Fib { return Fib(); }

  auto begin() const -> Iterator { return Iterator{data}; }
  auto end() const -> Iterator { return Iterator{data + 4}; }

 private:
  int data[4] = {1, 2, 3, 5};
};
''';

// Pure Carbon abstraction: any Core.Iterate range of i32.
fn Sum[R: Core.Iterate where .ElementType = i32](r: R) -> i32 {
  var total: i32 = 0;
  for (i: i32 in r) {
    total += i;
  }
  return total;
}

fn Run() -> i32 {
  var cpp: Cpp.Fib = Cpp.Fib.Make();
  Core.Print(Sum(cpp));
  return 0;
}
