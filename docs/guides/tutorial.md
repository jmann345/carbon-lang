# Tutorial: Carbon from hello world to C++ interop

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

This tutorial is ten complete programs, from hello world to calling C++ from
Carbon and Carbon from C++. Each section is one program: save it under the
name shown, build it with the commands of [Before you start](#before-you-start),
and compare what it prints with the section's expected output. Each section
says which toolchain runs it, names the constructs to notice with links to the
design documents that define them, and links the FAQ entries for the errors it
can produce.

<!-- toc -->

## Table of contents

-   [Before you start](#before-you-start)
-   [Hello, world](#hello-world)
-   [Values, variables and functions](#values-variables-and-functions)
-   [Classes](#classes)
-   [Interfaces and generics](#interfaces-and-generics)
-   [Choice types and match](#choice-types-and-match)
-   [Errors as values](#errors-as-values)
-   [Calling C++ from Carbon](#calling-c-from-carbon)
-   [Linking your own C++ library](#linking-your-own-c-library)
-   [Calling Carbon from C++](#calling-carbon-from-c)
-   [A multi-file package](#a-multi-file-package)
-   [Where next](#where-next)

<!-- tocstop -->

## Before you start

Install a toolchain and put its `bin` directory on your `PATH` as
[Getting started](getting_started.md) describes, and run every command from the
directory that holds the section's files. Each single-file section builds and
runs with the same three commands; for `hello.carbon` they are:

```shell
carbon compile --output=hello.o hello.carbon
carbon link --output=hello hello.o
./hello
```

For another section, replace `hello` with the name of that section's file
without its `.carbon` extension. The sections
[Linking your own C++ library](#linking-your-own-c-library) and
[A multi-file package](#a-multi-file-package) show their own commands; give
each its own directory, since both have a `main.carbon`.

Each section starts with a "Runs on" line. "The upstream nightly (measured
with 0.0.0-0.nightly.2026.10.12) and this fork's toolchain" means that the
program ran unchanged on both; a later nightly was not measured. "This fork's
toolchain only" marks the two sections whose features the nightly rejects; see
[Two toolchains](getting_started.md#two-toolchains).

## Hello, world

Runs on: the upstream nightly (measured with 0.0.0-0.nightly.2026.10.12) and
this fork's toolchain. Save it as `hello.carbon`:

```carbon
import Cpp library "<iostream>";

fn Run() {
  Cpp.std.cout << "Hello, world!\n";
}
```

Output:

```text
Hello, world!
```

What to notice: `Run` is the entry point. `import Cpp library` brings a C++
header in as the package `Cpp`, so `Cpp.std.cout` is C++'s `std::cout`. Text
goes through C++ here because `Core.PrintStr` needs `carbon build`; see the
FAQ. Design:
[the tour of the basics](/docs/design/README.md#tour-of-the-basics) and
[interoperability](/docs/design/interoperability/README.md).

If it fails, see the FAQ:

-   [Compiling a C++ import fails inside libc++](evaluator_faq.md#compiling-a-c-import-fails-inside-libc)
-   [Linking fails with an undefined symbol in Core](evaluator_faq.md#linking-fails-with-an-undefined-symbol-in-core)

## Values, variables and functions

Runs on: the upstream nightly (measured with 0.0.0-0.nightly.2026.10.12) and
this fork's toolchain. Save it as `functions.carbon`:

```carbon
import Core library "io";

fn Square(x: i32) -> i32 {
  return x * x;
}

fn SumOfSquares(n: i32) -> i32 {
  var total: i32 = 0;
  for (i: i32 in Core.InclusiveRange(1, n)) {
    total += Square(i);
  }
  return total;
}

fn Run() -> i32 {
  let limit: i32 = 4;
  Core.Print(SumOfSquares(limit));

  var countdown: i32 = 3;
  while (countdown > 0) {
    Core.Print(countdown);
    --countdown;
  }

  let parity: i32 = if limit % 2 == 0 then 0 else 1;
  Core.Print(parity);
  Core.Print(if (limit + 1) % 2 == 0 then 0 else 1);
  return 0;
}
```

Output:

```text
30
3
2
1
0
1
```

What to notice: `let` binds an immutable value and `var` a mutable variable,
and the type follows the name. `for` loops over a range, and
`Core.InclusiveRange(1, n)` includes both ends. `if ... then ... else` is an
expression, usable as an initializer, a call argument or a `return` operand
(as another operator's operand it needs parentheses), and the last two prints
take its two arms. `Run` may return `i32`, which becomes the exit code. Design:
[name-binding declarations](/docs/design/README.md#name-binding-declarations),
[functions](/docs/design/functions.md),
[control flow](/docs/design/control_flow/README.md) and
[`if` expressions](/docs/design/expressions/if.md).

If it fails, see the FAQ:

-   [How is the exit code set?](evaluator_faq.md#how-is-the-exit-code-set)

## Classes

Runs on: the upstream nightly (measured with 0.0.0-0.nightly.2026.10.12) and
this fork's toolchain. Save it as `classes.carbon`:

```carbon
import Core library "io";

class Point {
  fn Origin() -> Point {
    return {.x = 0, .y = 0};
  }

  fn Translate(ref self, dx: i32, dy: i32) {
    self.x += dx;
    self.y += dy;
  }

  fn Sum(self) -> i32 {
    return self.x + self.y;
  }

  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  var p: Point = Point.Origin();
  p.Translate(3, 4);
  Core.Print(p.x);
  Core.Print(p.Sum());
  p.Translate(-1, 2);
  Core.Print(p.Sum());
  return 0;
}
```

Output:

```text
3
7
8
```

What to notice: a function without `self`, such as `Origin`, is called on the
class. A method declared with `ref self` may modify the object. A struct
literal such as `{.x = 0, .y = 0}` initializes the fields. Design:
[classes](/docs/design/classes.md).

If it fails, see the FAQ:

-   [The compiler rejects a fork feature](evaluator_faq.md#the-compiler-rejects-a-fork-feature)

## Interfaces and generics

Runs on: the upstream nightly (measured with 0.0.0-0.nightly.2026.10.12) and
this fork's toolchain. Save it as `generics.carbon`:

```carbon
import Core library "io";

interface Shape {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  extend impl as Shape {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

class Rectangle {
  var width: i32;
  var height: i32;
  extend impl as Shape {
    fn Area(self) -> i32 { return self.width * self.height; }
  }
}

fn DoubleArea[T: Shape](s: T) -> i32 {
  return 2 * s.Area();
}

class Pair(T: type) {
  var first: T;
  var second: T;
}

fn Run() -> i32 {
  let sq: Square = {.side = 3};
  let rect: Rectangle = {.width = 2, .height = 5};
  Core.Print(DoubleArea(sq));
  Core.Print(DoubleArea(rect));

  let p: Pair(i32) = {.first = sq.Area(), .second = rect.Area()};
  Core.Print(p.first + p.second);
  return 0;
}
```

Output:

```text
18
20
19
```

What to notice: `DoubleArea` is checked once against the `Shape` interface,
not once per type it is called with: it is a checked generic. `extend impl`
makes the interface's methods members of the class. `Pair(T)` is a generic
class. Design: [generics](/docs/design/generics/overview.md).

If it fails, see the FAQ:

-   [The compiler rejects a fork feature](evaluator_faq.md#the-compiler-rejects-a-fork-feature)

## Choice types and match

Runs on:
[this fork's toolchain](getting_started.md#build-this-forks-toolchain-from-source)
only. The upstream nightly reports
``semantics TODO: `choice alternatives with parameters are not yet supported` ``
and ``semantics TODO: `HandleMatchIntroducer` ``. Save the program as
`choice_match.carbon`:

```carbon
import Core library "io";

choice Figure {
  Circle(radius: i32),
  Rectangle(width: i32, height: i32),
  Empty
}

// Approximates pi as 3 to stay in integer arithmetic.
fn Area(f: Figure) -> i32 {
  var area: i32 = 0;
  match (f) {
    case .Circle(r: i32) => { area = 3 * r * r; }
    case .Rectangle(w: i32, h: i32) => { area = w * h; }
    case .Empty => { area = 0; }
  }
  return area;
}

fn Describe(n: i32) -> i32 {
  var code: i32 = 0;
  match (n) {
    case 0 => { code = 100; }
    case x: i32 if (x < 0) => { code = 200; }
    default => { code = 300; }
  }
  return code;
}

fn Run() -> i32 {
  Core.Print(Area(Figure.Circle(2)));
  Core.Print(Area(Figure.Rectangle(3, 5)));
  Core.Print(Area(Figure.Empty));
  Core.Print(Describe(0));
  Core.Print(Describe(-4));
  Core.Print(Describe(9));
  return 0;
}
```

Output:

```text
12
15
0
100
200
300
```

What to notice: a `choice` is a sum type whose alternatives may carry values.
`match` destructures them, needs no `default` when every alternative is
covered, and runs only the first matching case, with no fall-through. A guard
is written `if (...)`: the toolchain requires the parentheses, though the
design's grammar does not. The arms assign and the function returns once
because, unlike the design, the toolchain does not yet treat an exhaustive
`match` as returning on every path: without a `default` arm, a function whose
arms all return still needs a `return` after the `match`; see the FAQ. Design:
[choice types](/docs/design/sum_types.md) and
[pattern matching](/docs/design/pattern_matching.md).

If it fails, see the FAQ:

-   [The compiler rejects a fork feature](evaluator_faq.md#the-compiler-rejects-a-fork-feature)
-   [A function ending in a match needs a return](evaluator_faq.md#a-function-ending-in-a-match-needs-a-return)
-   [Which toolchain do I need?](evaluator_faq.md#which-toolchain-do-i-need)

## Errors as values

Runs on:
[this fork's toolchain](getting_started.md#build-this-forks-toolchain-from-source)
only. The upstream nightly reports
``member name `Result` not found in `Core` ``. Save the program as
`errors.carbon`:

```carbon
import Core library "io";

// Returns the quotient, or the dividend as the error when dividing by zero.
fn Divide(a: i32, b: i32) -> Core.Result(i32, i32) {
  if (b == 0) {
    return Core.Result(i32, i32).Err(a);
  }
  return Core.Result(i32, i32).Ok(a / b);
}

// `?` returns early with the error; otherwise it unwraps the value.
fn Average(total: i32, count: i32) -> Core.Result(i32, i32) {
  let mean: i32 = Divide(total, count)?;
  return Core.Result(i32, i32).Ok(mean);
}

fn Report(r: Core.Result(i32, i32)) {
  match (r) {
    case .Ok(v: i32) => { Core.Print(v); }
    case .Err(e: i32) => { Core.Print(-e); }
  }
}

fn Run() -> i32 {
  Report(Average(12, 4));
  Report(Average(7, 0));
  if (let .Ok(v: i32) = Divide(9, 3)) {
    Core.Print(v);
  }
  if (let .Ok(v: i32) = Divide(1, 0)) {
    Core.Print(v);
  } else {
    Core.Print(0);
  }
  return 0;
}
```

Output:

```text
3
-7
3
0
```

What to notice: `Core.Result(T, E)` is a `choice` in the prelude, with the
alternatives `Ok` and `Err`. The postfix `?` returns the error to the caller,
or unwraps the value. `if (let pattern = value)` runs its block only when the
pattern matches, and its `else` block otherwise. `Run` may itself return
`Core.Result((), E)`; an error then prints a line to stderr and exits with
code 1. Design: [error handling](/docs/design/error_handling.md).

If it fails, see the FAQ:

-   [The compiler rejects a fork feature](evaluator_faq.md#the-compiler-rejects-a-fork-feature)
-   [Which toolchain do I need?](evaluator_faq.md#which-toolchain-do-i-need)
-   [How is the exit code set?](evaluator_faq.md#how-is-the-exit-code-set)

## Calling C++ from Carbon

Runs on: the upstream nightly (measured with 0.0.0-0.nightly.2026.10.12) and
this fork's toolchain. Save it as `interop_use_cpp.carbon`:

```carbon
import Core library "io";
import Cpp library "<cstdlib>";
import Cpp library "<vector>";
import Cpp inline '''c++
class Counter {
 public:
  Counter(int start) : total_(start) {}
  void Add(int n) { total_ += n; }
  int Total() const { return total_; }

 private:
  int total_;
};

inline std::vector<int> FirstPrimes() { return {2, 3, 5, 7}; }
''';

fn Run() -> i32 {
  // A C++ standard library function.
  Core.Print(Cpp.std.abs(-5));

  // A C++ class: constructor, mutating method, const method.
  var c: Cpp.Counter = Cpp.Counter.Counter(10);
  c.Add(5);
  Core.Print(c.Total());

  // A C++ container, iterated with a Carbon `for` loop.
  var primes: Cpp.std.vector(i32) = Cpp.FirstPrimes();
  var sum: i32 = 0;
  for (p: i32 in primes) {
    sum += p;
  }
  Core.Print(sum);
  return 0;
}
```

Output:

```text
5
15
17
```

What to notice: C++ names live under `Cpp`, and C++ `int` is Carbon `i32`. A
constructor is called as `Cpp.Counter.Counter(...)`. A C++ class template is
instantiated with a Carbon type argument, as in `Cpp.std.vector(i32)`.
`import Cpp inline` compiles C++ source written in the Carbon file. Overload
resolution for `std::abs` is C++'s own. The constructor call, C++ method calls
and `import Cpp inline` are toolchain behavior whose design sections are still
placeholders. Design:
[interoperability](/docs/design/interoperability/README.md).

If it fails, see the FAQ:

-   [Compiling a C++ import fails inside libc++](evaluator_faq.md#compiling-a-c-import-fails-inside-libc)
-   [Which C++ standard library does Carbon use?](evaluator_faq.md#which-c-standard-library-does-carbon-use)

## Linking your own C++ library

Runs on: the upstream nightly (measured with 0.0.0-0.nightly.2026.10.12) and
this fork's toolchain. This section has three files. `rectangle.h`:

```cpp
#ifndef RECTANGLE_H_
#define RECTANGLE_H_

// Returns the area of a `width` by `height` rectangle.
auto RectangleArea(int width, int height) -> int;

#endif  // RECTANGLE_H_
```

`rectangle.cpp`:

```cpp
#include "rectangle.h"

auto RectangleArea(int width, int height) -> int { return width * height; }
```

`main.carbon`:

```carbon
import Core library "io";
import Cpp library "rectangle.h";

fn Run() -> i32 {
  Core.Print(Cpp.RectangleArea(6, 7));
  return 0;
}
```

Build and run it from the directory that holds the three files:

```shell
carbon clang -- -c rectangle.cpp -o rectangle.o
carbon compile --output=main.o main.carbon
carbon link --output=main main.o rectangle.o
./main
```

Output:

```text
42
```

What to notice: build the C++ files with `carbon clang` (or with the
toolchain's `lib/carbon/llvm/bin/clang++`), because `carbon link` links libc++:
C++ code that uses the standard library and was compiled by `g++` or a system
`clang++` against libstdc++ does not link, though code like `rectangle.cpp`
that uses none of it does; see the FAQ. A quoted header is found relative to
the directory the compile runs in, so build from the directory that holds the
header, or pass `--clang-arg=-I<dir>`. Design:
[importing and `#include`](/docs/design/README.md#importing-and-include).

This fork keeps these three files, with a license comment added and, in the
header, the guard name the header-guard check requires, in
`fork/evaluator/cpp_library/`, where `build.sh` runs these commands;
`fork/evaluator/check_samples.py` compares them with this page.

If it fails, see the FAQ:

-   [A C++ header is not found](evaluator_faq.md#a-c-header-is-not-found)
-   [C++ objects built with g++ fail to link](evaluator_faq.md#c-objects-built-with-g-fail-to-link)

## Calling Carbon from C++

Runs on: the upstream nightly (measured with 0.0.0-0.nightly.2026.10.12) and
this fork's toolchain. Save it as `interop_call_carbon.carbon`:

```carbon
import Core library "io";
import Cpp;

// Carbon functions that the C++ code below calls.
fn Square(n: i32) -> i32 {
  return n * n;
}

fn Clamp(v: i32, lo: i32, hi: i32) -> i32 {
  if (v < lo) { return lo; }
  if (v > hi) { return hi; }
  return v;
}

// C++ code sees the Carbon functions in the `Carbon` namespace.
inline Cpp '''c++
inline int SumOfSquaresClamped(int n, int lo, int hi) {
  int total = 0;
  for (int i = 1; i <= n; ++i) {
    total += Carbon::Square(i);
  }
  return Carbon::Clamp(total, lo, hi);
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.SumOfSquaresClamped(3, 0, 100));
  Core.Print(Cpp.SumOfSquaresClamped(10, 0, 100));
  Core.Print(Cpp.SumOfSquaresClamped(3, 20, 100));
  return 0;
}
```

Output:

```text
14
100
20
```

What to notice: `import Cpp;` with a later `inline Cpp` block exports the
Carbon functions declared above that block into C++'s `Carbon` namespace; the
`inline Cpp` block and that rule are toolchain behavior no design document
describes yet. The three calls reach the three arms of `Clamp`: in range,
above `hi`, and below `lo`. C++ compiled separately cannot call Carbon yet,
because no header is generated; see the FAQ. Design:
[interoperability](/docs/design/interoperability/README.md).

If it fails, see the FAQ:

-   [Can separately compiled C++ call my Carbon functions?](evaluator_faq.md#can-separately-compiled-c-call-my-carbon-functions)

## A multi-file package

Runs on: the upstream nightly (measured with 0.0.0-0.nightly.2026.10.12) and
this fork's toolchain. This section has three files. `geometry.carbon`:

```carbon
package Geometry;

// The API file: the declarations that importers of `Geometry` can use.

class Rect {
  var width: i32;
  var height: i32;
}

fn Area(r: Rect) -> i32;
fn Perimeter(r: Rect) -> i32;
```

`geometry.impl.carbon`:

```carbon
impl package Geometry;

// The implementation file: it sees the API file's declarations implicitly.

fn Area(r: Rect) -> i32 {
  return r.width * r.height;
}

fn Perimeter(r: Rect) -> i32 {
  return 2 * (r.width + r.height);
}
```

`main.carbon`:

```carbon
import Core library "io";
import Geometry;

fn Run() -> i32 {
  let r: Geometry.Rect = {.width = 3, .height = 4};
  Core.Print(Geometry.Area(r));
  Core.Print(Geometry.Perimeter(r));
  return 0;
}
```

Build and run it from the directory that holds the three files:

```shell
carbon compile --output=geometry.o geometry.carbon
carbon compile --output-last-input-only --output=geometry.impl.o geometry.carbon geometry.impl.carbon
carbon compile --output-last-input-only --output=main.o geometry.carbon main.carbon
carbon link --output=shapes geometry.o geometry.impl.o main.o
./shapes
```

Output:

```text
12
14
```

What to notice: a file that imports or implements a package is compiled
together with that package's API file, and `--output-last-input-only` writes
only the last file's object file, because the toolchain does not yet compile
files separately. `carbon build -o=shapes main.carbon geometry.carbon
geometry.impl.carbon` does the same in one step. Design:
[code and name organization](/docs/design/code_and_name_organization/README.md).

If it fails, see the FAQ:

-   [An imported package API is not found](evaluator_faq.md#an-imported-package-api-is-not-found)
-   [The compiler only outputs one of several files](evaluator_faq.md#the-compiler-only-outputs-one-of-several-files)

## Where next

-   The [language design](/docs/design/README.md), for the rest of the
    language.
-   The [evaluator FAQ](evaluator_faq.md), for the errors you may meet and the
    questions it answers.
-   [fork/gap-analysis.md](/fork/gap-analysis.md) and
    [fork/conformance/README.md](/fork/conformance/README.md), for what this
    fork implements and how it is tested.
