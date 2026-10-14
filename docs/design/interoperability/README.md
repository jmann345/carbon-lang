# Bidirectional interoperability with C and C++

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Philosophy and goals](#philosophy-and-goals)
-   [Overview](#overview)
-   [C++ interoperability model: introduction and principles](#c-interoperability-model-introduction-and-principles)
    -   [The successor language mandate](#the-successor-language-mandate)
    -   [The C++ interop type](#the-c-interop-type)
-   [Importing C++ APIs into Carbon](#importing-c-apis-into-carbon)
    -   [Importing C++ libraries (header-based)](#importing-c-libraries-header-based)
    -   [Importing C++ code (inline)](#importing-c-code-inline)
    -   [Accessing built-in C++ entities (file-less)](#accessing-built-in-c-entities-file-less)
    -   [The `Cpp` package](#the-cpp-package)
    -   [Importing C++ macros](#importing-c-macros)
-   [Calling C++ code from Carbon](#calling-c-code-from-carbon)
    -   [Function call syntax and semantics](#function-call-syntax-and-semantics)
    -   [Overload resolution](#overload-resolution)
    -   [Constructors](#constructors)
    -   [Struct literals](#struct-literals)
-   [Accessing C++ classes, structs, and members](#accessing-c-classes-structs-and-members)
-   [Accessing global variables](#accessing-global-variables)
-   [Using C++ templates](#using-c-templates)
-   [Using Carbon from C++](#using-carbon-from-c)
-   [Bi-directional type mapping: primitives and core types](#bi-directional-type-mapping-primitives-and-core-types)
    -   [Integers](#integers)
    -   [Literals](#literals)
    -   [Character types](#character-types)
-   [Advanced type mapping: pointers, references, and `const`](#advanced-type-mapping-pointers-references-and-const)
-   [Bi-directional type mapping: standard library types](#bi-directional-type-mapping-standard-library-types)
    -   [`std::string_view` and `str`](#stdstring_view-and-str)
    -   [`std::span` and `Core.Slice`](#stdspan-and-coreslice)
    -   [C++ ranges in `for` loops](#c-ranges-in-for-loops)
-   [Threads, atomics, and the memory model](#threads-atomics-and-the-memory-model)
-   [The operator interoperability model](#the-operator-interoperability-model)
-   [References](#references)

<!-- tocstop -->

## Philosophy and goals

The C++ interoperability layer of Carbon allows a subset of C++ APIs to be
accessed from Carbon code, and similarly a subset of Carbon APIs to be accessed
from C++ code. This requires expressing one language as a subset of the other.
Bridge code may be needed to map some APIs into the relevant subset, but the
constraints on expressivity should be loose enough to keep the amount of such
bridge code sustainable.

The [interoperability philosophy and goals](philosophy_and_goals.md) provide
more detail.

## Overview

Carbon's bidirectional interoperability with C++ is
[a cornerstone of its design](/docs/project/goals.md#interoperability-with-and-migration-from-existing-c-code),
enabling a gradual transition from existing C++ codebases. The goal is not just
a foreign function interface (FFI), but a seamless, high-fidelity integration
that supports advanced C++ features, from templates to class hierarchies.

C++ APIs are imported into Carbon using an `import Cpp` directive, which makes
C++ declarations available within a dedicated `Cpp` package in Carbon. This
prevents name collisions and makes the origin of symbols explicit. Carbon code
can then call C++ functions, instantiate C++ classes, and use C++ types, while
respecting C++'s semantics, including its complex overload resolution rules and
preserving the nominal distinctions between C++ types like `long` and
`long long`, or `T*` and `T&`, which is critical for correct overload resolution
and template instantiation.

Similarly, Carbon APIs can be designed to be callable from C++. The
interoperability layer is designed to be zero-cost, avoiding unnecessary
allocations or copies when calling between the two languages.

## C++ interoperability model: introduction and principles

### The successor language mandate

The design of Carbon's C++ interoperability is governed by its foundational
goal: [to be a successor language](/README.md), not merely a language with a
foreign function interface (FFI). This mandate dictates a design that moves
beyond the C-style FFI adopted by most modern languages and instead provides
seamless, bidirectional interoperability. The objective is to support deep
integration with existing C++ code, encompassing its most complex features, from
inheritance to templates.

This goal has profound implications for the Carbon compiler and language
semantics. It requires that C++ is not treated as a foreign entity. Instead,
Carbon's semantic model must be _co-designed_ to understand, map, and interact
with C++'s semantic constructs—including templates, class hierarchies, and
complex overload resolution—with high fidelity. The interoperability layer must,
therefore, operate at the semantic analysis level, not just at the linking (ABI)
level. This document specifies the design of this semantic contract.

### The C++ interop type

A core mechanism in this design is the C++ interop type. This concept defines
the "trigger" that activates C++-specific semantic rules within the Carbon
compiler. Any operation involving a type that is designated as a C++ interop
type could invoke the specialized interoperability logic, such as C++ overload
resolution or operator overload resolution that involves both Carbon and C++
operator overloads.

A type is considered a C++ interop type if its definition involves an imported
C++ type in any of the following ways:

1.  A C++ imported type (for example, `Cpp.Widget`).
2.  A pointer to a C++ interop type (for example, `Cpp.Widget*`).
3.  A Carbon generic type parameterized with a C++ interop type (for example,
    `MyCarbonVector(Cpp.Widget)`).

More generally, a C++ interop type is any type for which Carbon's
[orphan rule](https://docs.carbon-lang.dev/docs/design/generics/details.html#orphan-rule)
would allow an impl to be provided by a library in `package Cpp`.

This "pervasive" model of C++-awareness is a fundamental design choice. The C++
semantics are not confined to a specific `unsafe` or `extern "C++"` block; they
affect any Carbon type that composes them. For example, when the Carbon compiler
instantiates a _Carbon_ generic type like `MyCarbonVector(Cpp.Widget)`, its type
system must be aware that the `Cpp.Widget` parameter carries C++-specific rules.
This mandates that Carbon's own generic system, struct layout logic, overload
resolution and operator lookup must query the type system for the presence of a
C++ interop type. If present, Carbon must consider C++ rules when operating over
C++ interop types. This design prioritizes the goal of a seamless and intuitive
user experience.

## Importing C++ APIs into Carbon

### Importing C++ libraries (header-based)

The primary mechanism for importing existing, user-defined C++ code is through
header file inclusion. Carbon must be able to parse and analyze C++ header files
to make their declarations available within Carbon.

**Syntax:** The syntax for this operation is `import Cpp library "header_name"`.
This syntax is used for both standard library headers and user-defined headers:

-   **Standard Library:**

    ```carbon
    import Cpp library "<cstdio>";
    ```

    This import makes entities like `putchar` available.

-   **C++ User-Defined Header:**

    ```carbon
    import Cpp library "circle.h";
    ```

    This import makes user-defined declarations and definitions available.

### Importing C++ code (inline)

C++ source can also be written in a Carbon file. `import Cpp inline` followed by
a string literal, usually a block string literal `'''...'''` tagged `c++`,
compiles that source as if it were a header: its declarations join the `Cpp`
package exactly as a header's do, and it may `#include` headers itself. It is an
`import`, so it comes with the other imports, before any other declaration. A
second spelling, the declaration `inline Cpp '''...''';`, may appear among
Carbon declarations, and its C++ code can call the Carbon declarations above it
through the `Carbon` namespace; it requires an `import Cpp` declaration earlier
in the file, such as `import Cpp;` or the `import Cpp inline` above.

```carbon
import Core library "io";

// C++ source in an import: its declarations join the `Cpp` package like a
// header's.
import Cpp inline '''c++
inline int Triple(int x) { return 3 * x; }
''';

fn Twice(n: i32) -> i32 { return n * 2; }

// An `inline Cpp` declaration may follow Carbon declarations, and its C++
// code can call them through the `Carbon` namespace.
inline Cpp '''c++
inline int TwicePlusOne(int n) { return Carbon::Twice(n) + 1; }
''';

fn Run() -> i32 {
  Core.Print(Cpp.Triple(14));
  Core.Print(Cpp.TwicePlusOne(20));
  return 0;
}
```

This prints `42` and `41`. The string literal's escape sequences are Carbon's
and are processed before C++ sees the text, so a C++ `"\n"` is written `"\\n"`,
or the whole block is written as a raw block string literal `#'''...'''#`.
Accepted proposals 6668 and 7697 use `import Cpp inline` in examples, but no
proposal designs the inline forms; the toolchain parses both
(`toolchain/parse/handle_inline_decl.cpp`) and the tests in
`toolchain/check/testdata/interop/cpp/basics/inline/` pin them. Without an
earlier `import Cpp`, the `inline Cpp` declaration is an error:

```carbon
fn Twice(n: i32) -> i32 { return n * 2; }

inline Cpp '''c++
inline int CallTwice(int n) { return Carbon::Twice(n) + 1; }
''';
```

The toolchain reports ``name `Cpp` not found``.

Leads question
[issue 6830](https://github.com/carbon-language/carbon-lang/issues/6830) asked
whether `import Cpp inline` should be a declaration among the others rather than
one of the imports that precede them. On 2026-03-26 it was decided as a
top-level declaration spelled `inline Cpp '''...'''`, the second form above. The
issue was reopened on 2026-03-30 over the trailing semicolon, which the
toolchain requires
(`toolchain/parse/testdata/packages/import/cpp_inline.carbon`); the discussion
since has also weighed a fenced delimiter in place of `'''`, and no further
decision is recorded, so the issue is open.

### Accessing built-in C++ entities (file-less)

Some C++ entities, particularly built-in primitive types, are not defined in any
header file. They are "intrinsic" to the C++ language. These entities are
available in Carbon without an explicit `import` declaration.

### The `Cpp` package

A critical design choice for managing C++ imports is the mandatory use of a
containing package, `Cpp`. All imported C++ named entities (functions, types,
namespaces) are contained in the `Cpp` package.

-   **Functions:** `Cpp.putchar(...)`
-   **Classes/Types:** `Cpp.Circle`, `Cpp.Point`
-   **Constructors:** `Cpp.Circle.Circle()`

The `Cpp.` prefix makes the _origin_ of every symbol explicit and unambiguous.
It ensures that C++ entities cannot collide with Carbon code.

### Importing C++ macros

An object-like C/C++ macro that evaluates to a constant expression is imported
from C++ as a constant in Carbon.

See [Importing C/C++ macros](macros.md) for details.

## Calling C++ code from Carbon

### Function call syntax and semantics

Once imported, C++ functions are invoked using standard Carbon function call
syntax, prefixed with the `Cpp` name. The Carbon compiler is responsible for
mapping the Carbon arguments to the types expected by the C++ function's
signature.

This often requires explicit casting on the Carbon side, using the `as` keyword,
to satisfy the C++ function's parameter types.

**Example:** The following example imports `cstdio` and calls the C function
`putchar`. The Carbon `Core.Char` variable `n` must be cast first to `u8` and
then to `i32` to match the `int` parameter expected by `putchar`.

```carbon
import Cpp library "<cstdio>";

fn Run() {
  let hello: array(Core.Char, 6) = ('H', 'e', 'l', 'l', 'o', '!');
  for (n: Core.Char in hello) {
    // Carbon 'as' casting is used to match the C++ signature
    Cpp.putchar((n as u8) as i32);
  }
}
```

### Overload resolution

A call from Carbon to an imported C++ overload set is resolved under **C++'s
rules, exactly**: the toolchain hands the candidate set to Clang Sema and
performs genuine C++ overload resolution, including implicit conversion
ranking, ambiguity diagnostics, default arguments, and the
[literal conversion rules](literals.md) for Carbon literal arguments. In the
other direction, an exported Carbon
[overload set](../functions_overloading.md) appears to C++ as an ordinary C++
overload set — every member is its own C++ declaration under the shared name,
a function in the mapped namespace or a member function in the mapped class —
which C++ callers also resolve under C++'s rules: a documented divergence from
Carbon's own declaration-order first-match rule. The same argument list can
therefore select a different member on each side of the boundary (a set
declared `i64` first and `i32` second: Carbon's `Pick(n)` for `n: i32` takes
the first member by widening, C++'s `Carbon::Pick(v)` for `int v` takes the
exact match), or be rejected by C++ as ambiguous where Carbon accepts it
(`Carbon::F(7)` against `F(i64)` and `F(bool)`: `int → long` and `int → bool`
are both Conversion rank). The divergence is bounded to _which_ member runs, or
whether the call compiles — each member carries its own symbol, so no call
crosses the boundary with the wrong ABI. Both directions of the mapping, and
the divergence, are specified in
[Function overloading: C++ interoperability](../functions_overloading.md#c-interoperability)
(fork decision [F-009](/fork/decision-log.md); fork amendment 2026-10-05: the
export direction landed with workstream OV-3, conformance-tested in both
directions by `fork/conformance/programs/interop/cpp_export_overload_set.carbon`
and `cpp_export_overload_set_divergence.carbon`).

### Constructors

No accepted proposal covers C++ constructors. In the 0.1 toolchain, a C++
constructor is a member of its class with the class's name, as in C++, and is
called with call syntax: `Cpp.Point.Point(1, 2)`. C++ overload resolution
chooses among the constructors and supplies default arguments
([Overload resolution](#overload-resolution)). A `var` with no initializer runs
the default constructor; initializing from another object of the class runs its
copy constructor; a constructor that is not `explicit` is an implicit
conversion from its parameter type; and the class's destructor runs when a
Carbon object of the class goes out of scope.

```carbon
import Core library "io";

import Cpp inline '''c++
inline int destroyed = 0;

struct Point {
  int x;
  int y;
  Point() : x(0), y(0) {}
  Point(int px, int py = 10) : x(px), y(py) {}
  ~Point() { ++destroyed; }
};

struct Meters {
  int n;
  Meters(int v) : n(v) {}
};

inline int Length(Meters m) { return m.n; }
''';

fn Make() -> i32 {
  // A constructor is called by its C++ name, as a member of its class; C++
  // overload resolution picks the constructor and fills default arguments.
  var a: Cpp.Point = Cpp.Point.Point(1, 2);
  var b: Cpp.Point = Cpp.Point.Point(3);
  // A `var` with no initializer runs the default constructor.
  var c: Cpp.Point;
  // Initializing from another object runs the copy constructor.
  var d: Cpp.Point = a;
  d.x = 100;
  return a.x + a.y + b.y + c.x + d.x;
}

fn Run() -> i32 {
  Core.Print(Make());
  // The four objects were destroyed when `Make` returned.
  Core.Print(Cpp.destroyed);
  // A non-`explicit` converting constructor is an implicit conversion.
  Core.Print(Cpp.Length(5));
  return 0;
}
```

This prints `113`, `4`, and `5`. An `explicit` constructor is not an implicit
conversion:

```carbon
import Cpp inline '''c++
struct Meters {
  int n;
  explicit Meters(int v) : n(v) {}
};
inline int Length(Meters m) { return m.n; }
''';

fn F() -> i32 {
  return Cpp.Length(5);
}
```

C++ overload resolution finds no viable `Length`, and the toolchain reports
`no matching function for call to 'Length'`.

### Struct literals

No accepted proposal covers initializing a C++ class from a Carbon struct
literal. In the 0.1 toolchain, a struct literal initializes two kinds of C++
class: an empty struct literal `{}` initializes an aggregate with no fields,
and a one-field struct literal initializes a C++ union, naming the member to
make active ([Unions](../unions.md), fork decision F-007). A C++ aggregate with
fields is built in C++, by a function or a constructor, and then used field by
field.

```carbon
import Core library "io";

import Cpp inline '''c++
struct Empty {};
struct Pair {
  int first;
  int second;
};
union Number {
  int as_int;
  float as_float;
};
inline Pair MakePair(int a, int b) { return {a, b}; }
''';

fn Run() -> i32 {
  // An empty aggregate initializes from an empty struct literal.
  var unused e: Cpp.Empty = {};
  // A C++ union initializes from a one-field struct literal naming the
  // active member.
  var n: Cpp.Number = {.as_int = 41};
  // A non-empty aggregate is built in C++ and then used field by field.
  var p: Cpp.Pair = Cpp.MakePair(1, 2);
  p.second = n.as_int;
  Core.Print(p.first + p.second);
  return 0;
}
```

This prints `42`; the union initialization needs the fork's toolchain. A
struct literal with fields does not yet initialize a C++ aggregate:

```carbon
import Cpp inline '''c++
struct Pair {
  int first;
  int second;
};
''';

fn F() -> i32 {
  var p: Cpp.Pair = {.first = 1, .second = 2};
  return p.first;
}
```

The toolchain reports ``cannot implicitly convert expression of type `{.first:
Core.IntLiteral, .second: Core.IntLiteral}` to `Cpp.Pair` `` (fork work items
W-048 and W-051).

## Accessing C++ classes, structs, and members

Proposal 6358 nests C++ namespaces in the `Cpp` package, and proposal 6254
specifies calls to member functions, with the object as C++'s `this`, and the
access check on the function that overload resolution selects; proposals 3720
and 7697 make a C++ pointer to member usable once it is bound to an object with
compound member access, `a.(Cpp.p)`; no accepted proposal covers fields, nested
types, or base classes. In the 0.1 toolchain,
C++ classes and structs are Carbon types in the `Cpp` package, nested in `Cpp`
namespaces as in C++ (`Cpp.geo.Rect`). Their members use Carbon member access:
fields and member functions through an object (`r.Area()`, `r.tag`), and static
member functions and nested types through the class
(`Cpp.geo.Rect.Square(3)`, `Cpp.geo.Rect.Corner`). Members of a public base
class are found through a derived object, and a derived object converts to a
reference to its base.

```carbon
import Core library "io";

import Cpp inline '''c++
namespace geo {
class Rect {
 public:
  Rect(int w, int h) : w_(w), h_(h) {}
  static Rect Square(int s) { return Rect(s, s); }
  int Area() const { return w_ * h_; }
  void Scale(int k) { w_ *= k; h_ *= k; }
  struct Corner {
    int x;
    int y;
  };
  int tag = 7;

 private:
  int w_;
  int h_;
};

struct Shape {
  int id = 5;
  int Id() const { return id; }
};
struct Circle : Shape {
  int radius = 1;
};
inline int IdOf(const Shape& s) { return s.id; }
}  // namespace geo
''';

fn Run() -> i32 {
  // Namespaces, classes, and static member functions are members of `Cpp`.
  var r: Cpp.geo.Rect = Cpp.geo.Rect.Square(3);
  // Member functions and public fields use member access.
  Core.Print(r.Area());
  r.Scale(2);
  r.tag = r.Area();
  Core.Print(r.tag);
  // A nested class is a member of its enclosing class.
  var corner: Cpp.geo.Rect.Corner = Cpp.geo.Rect.Corner.Corner();
  corner.x = 4;
  Core.Print(corner.x);
  // Base-class members are found through a derived object, and a derived
  // object converts to a reference to its base.
  let c: Cpp.geo.Circle = Cpp.geo.Circle.Circle();
  Core.Print(c.Id() + c.radius);
  Core.Print(Cpp.geo.IdOf(c));
  return 0;
}
```

This prints `9`, `36`, `4`, `6`, and `5`. C++ access control applies:

```carbon
import Cpp inline '''c++
class Box {
 public:
  Box() : v_(1) {}

 private:
  int v_;
};
''';

fn F() -> i32 {
  var b: Cpp.Box = Cpp.Box.Box();
  return b.v_;
}
```

The toolchain reports ``cannot access private member `v_` of type `Cpp.Box` ``.
A `const` member function can be called on any object, including a value; a
member function that is not `const` needs a reference expression, such as a
`var`:

```carbon
import Cpp inline '''c++
struct Counter {
  int n = 1;
  void Inc() { ++n; }
};
''';

fn F() {
  let c: Cpp.Counter = Cpp.Counter.Counter();
  c.Inc();
}
```

Called on the value `c`, C++ overload resolution finds no viable `Inc`, and the
toolchain reports `no matching function for call to 'Inc'`.

Inheritance works across the boundary in both directions with a single base: a
Carbon class can `extend base` a C++ class, using it as its hierarchy root, and
override its virtual functions, and C++ code can derive a class from an
exported Carbon base class (the fork's conformance programs
`fork/conformance/programs/interop/inherit_carbon_extends_cpp.carbon` and
`fork/conformance/programs/interop/inherit_cpp_extends_carbon.carbon`).
Multiple, virtual, and diamond
inheritance, and exporting an abstract class whose destructor is not virtual,
are fork work item W-046.

A C++ pointer to member cannot be used this way in the 0.1 toolchain (fork work
item W-194). For a pointer `p` to a data member and a pointer `q` to a member
function, bound to `a` as in proposal 7697's example:

```carbon
import Cpp inline '''c++
struct A {
  int m;
  int F() { return 3; }
};
int A::* p = &A::m;
int (A::* q)() = &A::F;
''';

fn G(ref a: Cpp.A) -> i32 {
  return a.(Cpp.p) + a.(Cpp.q)();
}
```

The toolchain reports ``semantics TODO: `Unsupported: var type: int A::*` ``
for `Cpp.p`, and the call through `q` is not supported either.

## Accessing global variables

Proposal 6358 imports every C++ declaration into the `Cpp` package; no
accepted proposal specifies how a C++ variable behaves in Carbon. In the 0.1
toolchain, a C++ variable at namespace scope, such as an `inline` variable or
an `extern` declaration with its definition, is a durable reference expression
in Carbon, named through the `Cpp` package: it can be read, assigned, and
updated in place. A `const` variable can only be read.

```carbon
import Core library "io";

import Cpp inline '''c++
inline int counter = 40;
inline const int kLimit = 100;
extern int total;
int total = 7;
namespace config {
inline int verbosity = 1;
}
''';

fn Run() -> i32 {
  // A C++ variable is a durable reference: it can be read, assigned, and
  // updated in place.
  Cpp.counter += 2;
  Core.Print(Cpp.counter);
  Core.Print(Cpp.kLimit + Cpp.total);
  Cpp.config.verbosity = 3;
  Core.Print(Cpp.config.verbosity);
  return 0;
}
```

This prints `42`, `107`, and `3`. Assigning a `const` variable is an error:

```carbon
import Cpp inline '''c++
inline const int kLimit = 100;
''';

fn F() {
  Cpp.kLimit = 3;
}
```

The toolchain reports `expression is not assignable`. C++ `thread_local`
variables are covered in
[Threads, atomics, and the memory model](threads_and_atomics.md).

## Using C++ templates

No accepted proposal covers C++ templates. In the 0.1 toolchain, a C++
template is used from Carbon as C++ code uses it. A function template is
called like a function, and C++ deduces its template arguments from the Carbon
arguments. A class template is named with its template arguments in
parentheses, `Cpp.Box(i32)` for `Box<int>`, and each argument list names a
distinct type; the standard library's templates work the same way, such as
`Cpp.std.vector(i32)`. A template argument can be a Carbon class type, so a
C++ template can be instantiated on a Carbon type.

```carbon
import Core library "io";

import Cpp inline '''c++
template <typename T>
T Larger(T a, T b) { return a < b ? b : a; }

template <typename T>
struct Box {
  T value;
  T Get() const { return value; }
  static Box Make(T v) { return Box{v}; }
};
''';

class Point {
  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  // C++ deduces a function template's arguments from the Carbon arguments.
  Core.Print(Cpp.Larger(3, 7));
  // A class template takes its template arguments in parentheses, and each
  // argument list names a distinct type.
  let b: Cpp.Box(i32) = Cpp.Box(i32).Make(5);
  Core.Print(b.Get());
  // A C++ template can be instantiated on a Carbon class type.
  let p: Point = {.x = 3, .y = 4};
  let boxed: Cpp.Box(Point) = Cpp.Box(Point).Make(p);
  Core.Print(boxed.Get().y);
  return 0;
}
```

This prints `7`, `5`, and `4`. A checked generic's type parameter can be a C++
template argument: in a function `F[T: Core.Copy](x: T) -> T`, the body
`let b: Cpp.Box(T) = Cpp.Box(T).Make(x); return b.Get();` compiles, and the
template is instantiated for each specific. One limit in 0.1: a `var` of such
a specialization cannot be declared without an initializer, because
`var b: Cpp.Box(T);` reports that the type does not implement
`Core.DefaultOrUnformed` (fork work item W-043, and W-127 on held PR 51). C++20
concepts can be used: a C++20 concept `IsLarge` applied to a C++ type is a
compile-time `bool`, so `Cpp.IsLarge(Cpp.Small)` can be a generic argument
(`toolchain/check/testdata/interop/cpp/template/concept.carbon`); Carbon
constraints are not exported as C++ concepts (W-029). Using Carbon generics
from C++ is described in [Using Carbon from C++](#using-carbon-from-c).

## Using Carbon from C++

No accepted proposal covers using Carbon from C++. In the 0.1 toolchain, C++
code names Carbon declarations through the `Carbon` namespace:
`Carbon::Twice(7)` calls the Carbon function `Twice`, and `Carbon::Counter` is
the Carbon class `Counter`, whose fields, methods, and class functions C++ uses
as its members. A method declared with `ref self` can be called only on a
non-`const` object that is not a temporary, and one declared with `self` on
any object (`toolchain/check/testdata/interop/cpp/class/export/method.carbon`).
C++ code in the same file reaches Carbon this way from an `inline Cpp`
declaration, placed after the Carbon declarations it names as in the sample
below. A checked generic function
whose generic parameters are types is a C++ function template, and C++ deduces
its arguments; an exported [overload set](#overload-resolution) is resolved by
C++'s rules.

```carbon
import Core library "io";
import Cpp;

class Counter {
  var n: i32;
  fn Make(start: i32) -> Counter { return {.n = start}; }
  fn Get(self) -> i32 { return self.n; }
  fn Add(ref self, k: i32) { self.n += k; }
}

fn Twice(n: i32) -> i32 { return n * 2; }

interface Doubler {
  fn Double(self) -> Self;
}

class Meters {
  var n: i32;
  fn Make(v: i32) -> Meters { return {.n = v}; }
  fn Value(self) -> i32 { return self.n; }
  impl as Doubler {
    fn Double(self) -> Self { return {.n = self.n * 2}; }
  }
}

// A checked generic is exported as a C++ function template.
fn DoubleIt[T: Doubler](x: T) -> T { return x.Double(); }

// C++ code names Carbon declarations through the `Carbon` namespace.
inline Cpp '''c++
inline int UseCarbon(int start) {
  Carbon::Counter c = Carbon::Counter::Make(start);
  c.Add(3);
  return Carbon::Twice(c.Get());
}

inline int UseGeneric() {
  return Carbon::DoubleIt(Carbon::Meters::Make(21)).Value();
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.UseCarbon(4));
  Core.Print(Cpp.UseGeneric());
  return 0;
}
```

This prints `14` and `42`. A generic parameter that is not a type is not
exported:

```carbon
import Cpp;

fn Times[N: i32](x: i32) -> i32 { return N * x; }

inline Cpp '''c++
inline int UseTimes() { return Carbon::Times<3>(2); }
''';
```

The toolchain reports
``semantics TODO: `binding maps to a non-type template parameter` `` (fork work
item W-044). A Carbon function with a `template` parameter cannot yet be
called from C++: the call stops the compiler (fork work item W-191). Carbon
operator implementations are not exported as C++ operators
([The operator interoperability model](#the-operator-interoperability-model)),
and inheritance across the boundary is described in
[Accessing C++ classes, structs, and members](#accessing-c-classes-structs-and-members).

## Bi-directional type mapping: primitives and core types

### Integers

Proposal 5448 fixes the mapping, and the toolchain implements it: C++ `intN_t`
and `uintN_t` are Carbon's `iN` and `uN`, and a C++ integer type that is the
same type as one of them on the target is that Carbon type. On 64-bit Linux,
`signed char`, `short`, `int`, and `long` are `i8`, `i16`, `i32`, and `i64`, the
unsigned types are the matching `uN`, and `size_t` is `u64`. `long long` and
`unsigned long long`, the same width as `long` but different C++ types, are the
distinct Carbon types `Cpp.long_long` and `Cpp.unsigned_long_long`, which `as`
converts to and from `i64` and `u64`. Every C++ integer type is also named in
the `Cpp` package, such as `Cpp.int` and `Cpp.long`.

```carbon
import Core library "io";

import Cpp inline '''c++
#include <cstddef>
#include <cstdint>
inline int NextInt(int x) { return x + 1; }
inline long NextLong(long x) { return x + 1; }
inline long long NextLongLong(long long x) { return x + 1; }
inline unsigned NextUnsigned(unsigned x) { return x + 1; }
inline short NextShort(short x) { return x + 1; }
inline std::int64_t NextInt64(std::int64_t x) { return x + 1; }
inline std::size_t NextSize(std::size_t x) { return x + 1; }
inline unsigned char NextByte(unsigned char x) { return x + 1; }
''';

fn Run() -> i32 {
  // `int`, `short`, `unsigned`, and the fixed-width types are Carbon's
  // integer types; on this target `long` is `i64` and `size_t` is `u64`.
  let a: i32 = Cpp.NextInt(1);
  let b: i16 = Cpp.NextShort(2);
  let c: u32 = Cpp.NextUnsigned(3);
  let d: i64 = Cpp.NextLong(4);
  let e: i64 = Cpp.NextInt64(5);
  let f: u64 = Cpp.NextSize(6);
  let g: u8 = Cpp.NextByte(7);
  // `long long` is the distinct type `Cpp.long_long`; `as` converts it.
  let h: i64 = Cpp.NextLongLong(8) as i64;
  Core.Print(a + (b as i32) + (c as i32));
  Core.Print((d + e + h) as i32);
  Core.Print((f as i32) + (g as i32));
  return 0;
}
```

This prints `9`, `20`, and `15`. A `Cpp.long_long` does not implicitly convert
to `i64`:

```carbon
import Cpp inline '''c++
inline long long NextLongLong(long long x) { return x + 1; }
''';

fn F() -> i64 {
  let h: i64 = Cpp.NextLongLong(8);
  return h;
}
```

The toolchain reports ``cannot implicitly convert expression of type
`Cpp.long_long` to `i64` ``.

### Literals

Carbon and C++ support bi-directional mapping for the types of integer and
floating-point literals. Because Carbon literals do not have suffixes, they
typically follow C++ rules for unsuffixed decimal literals, but can also be
explicitly cast. C++ literals map to corresponding Carbon types based on their
suffixes.

For details, see [literals](literals.md).

### Character types

Carbon's `char` type transparently maps to C++'s `char` type. Carbon's `char`
type is always unsigned. When compiling C++ using Carbon's toolchain, C++ `char`
is treated as `unsigned` by default (`-funsigned-char`). When interoperating
with a signed C++ `char` type (`-fno-unsigned-char`), Carbon will maintain
interoperability, though bits will be interpreted differently in each language.

> References:
>
> -   Proposal
>     [#6710: `char` redesign](https://github.com/carbon-language/carbon-lang/pull/6710)

## Advanced type mapping: pointers, references, and `const`

Proposal 6357 maps C++ object pointers, and the toolchain implements its table:
a C++ pointer that may be null, `T*`, is `Core.Optional(T*)` in Carbon, with
null as an empty `Optional`; a pointer annotated `_Nonnull` is a Carbon pointer
`T*`, which is never null; `const T*` is `Core.Optional(const T*)`; and `void*`
is `Core.Optional(Core.CppCompat.VoidBase*)`. No accepted proposal maps C++
references yet: proposal 5434, which introduces Carbon's `ref` parameters,
leaves the modeling of C++ references to a future proposal. The 0.1 toolchain
maps them onto Carbon's parameter forms: a parameter of type `T&` is a `ref`
parameter, whose argument is marked `ref`; a `const T&` parameter takes a
value; a function returning `T&` returns a durable reference expression, which
can be assigned; and a field of reference type is reached through a pointer
(`*s.r`, pinned by
`toolchain/check/testdata/interop/cpp/class/import/field.carbon`). C++
references are therefore not translated to `T*`, as the
[language overview's standard types](../README.md#standard-types) section
once planned. A `const` member function can be called on a value
([Accessing C++ classes, structs, and members](#accessing-c-classes-structs-and-members)).

```carbon
import Core library "io";

import Cpp inline '''c++
inline void Bump(int* _Nonnull p) { *p += 1; }
inline int* Find(bool found, int* p) { return found ? p : nullptr; }
inline void AddTen(int& r) { r += 10; }
inline int Read(const int& r) { return r; }
inline int ReadThrough(const int* _Nonnull p) { return *p; }

struct Holder {
  int v = 3;
  int& Ref() { return v; }
  int Get() const { return v; }
};
''';

fn Run() -> i32 {
  var n: i32 = 1;
  // `int* _Nonnull` is `i32*`.
  Cpp.Bump(&n);
  Core.Print(n);
  // A pointer that may be null is `Core.Optional(i32*)`.
  let found: Core.Optional(i32*) = Cpp.Find(true, &n);
  if (found.HasValue()) {
    Core.Print(*found.Get());
  }
  let missing: Core.Optional(i32*) = Cpp.Find(false, &n);
  if (not missing.HasValue()) {
    Core.Print(0);
  }
  // A non-`const` reference parameter takes a `ref` argument; a `const`
  // reference parameter takes a value.
  Cpp.AddTen(ref n);
  Core.Print(Cpp.Read(n));
  // `const int* _Nonnull` is `const i32*`, and `i32*` converts to it.
  Core.Print(Cpp.ReadThrough(&n));
  // A returned non-`const` reference is a durable reference expression.
  var h: Cpp.Holder = Cpp.Holder.Holder();
  h.Ref() = 8;
  Core.Print(h.Get());
  return 0;
}
```

This prints `2`, `2`, `0`, `12`, `12`, and `8`. A `T&` argument must be marked:

```carbon
import Cpp inline '''c++
inline void AddTen(int& r) { r += 10; }
''';

fn F() -> i32 {
  var n: i32 = 1;
  Cpp.AddTen(n);
  return n;
}
```

The toolchain reports ``argument to `ref` parameter not marked with `ref` ``.

## Bi-directional type mapping: standard library types

C++ view types map to the corresponding Carbon view types where the two share
an object representation: `std::string_view` to `str` and the dynamic-extent
`std::span<T>` to `Core.Slice(T)`. Other standard library types are imported
as ordinary classes (fork amendment 2026-10-05, SL-2; the sentence this
paragraph replaces was a TODO naming `std::span` as future work).

### `std::string_view` and `str`

C++'s `std::string_view` maps directly to Carbon's `str` (which is an alias for
`Core.Str`) when importing C++ headers. The Carbon compiler treats
`std::string_view` as a type alias for `str` at the ABI level, with identical
memory representation.

This direct mapping is initially enabled only on 64-bit targets (since `str` has
a 64-bit size field, whereas C++ `std::string_view` uses `size_t`, which is
32-bit on 32-bit platforms) and where the standard library representation
matches the pointer-first-then-size layout of `str` (such as `libc++` used by
Clang and MSVC STL). For platforms with other layout conventions (like
`libstdc++`'s size-first-then-pointer layout), this mapping is disabled by
default until layout compatibility is established.

> References:
>
> -   Proposal
>     [#6177: C++ Interop: Mapping `std::string_view` to `Core.Str`](https://github.com/carbon-language/carbon-lang/pull/6177)

### `std::span` and `Core.Slice`

> **Fork amendment 2026-10-05 (SL-2, W-056; fork/slices/plan.md §1.B,
> decisions D-SL-8, D-SL-9, D-SL-10, D-SL-14).** As implemented in the fork
> toolchain; see [Slices](../slices.md#interop) for the Carbon-side API.

C++'s dynamic-extent `std::span<T>` (that is, `std::span<T,
std::dynamic_extent>`) maps directly to Carbon's [`Core.Slice(T)`](../slices.md)
in both directions, on the same premise as the `std::string_view` mapping: both
are a pointer to the first element followed by a size, so the Carbon compiler
treats the span specialization as `Core.Slice(T)` at the ABI level and no
conversion runs at the boundary. The element type maps recursively, so
`std::span<const int>` is `Core.Slice(const i32)`, and a Carbon `Core.Slice(T)`
converts implicitly to `Core.Slice(const T)` as a `std::span<T>` converts to
`std::span<const T>`.

-   Importing: a C++ function taking or returning `std::span<T>` takes or
    returns `Core.Slice(T)` in Carbon. A Carbon array reaches such a parameter
    through an explicit view -- `Cpp.SumSpan(Core.Slice(i32).FromArray(&a))` --
    never from the array value itself, because a view of a value could alias a
    copy.
-   Exporting: a Carbon function whose signature names `Core.Slice(T)` is
    exported with `std::span<T>` in that position, provided the C++
    translation unit has declared `std::span` (`#include <span>`); without it
    the export is diagnosed as unmappable.
-   Owning containers: a C++ class with `data()` and `size()` member functions
    -- `std::vector<T>`, `std::array<T, N>`, `std::string` -- converts
    implicitly to `Core.Slice` of its elements (`let view: Core.Slice(const
    i32) = v;` for a `std::vector<int>` `v`, and `v` passes directly to a
    `std::span<const int>` parameter). When the container has both a `const`
    and a non-`const` `data()`, the `const` one is used, so the view's element
    type is `const T`. The conversion is a view: it owns nothing and is valid
    while the container is.

A static-extent `std::span<T, N>` has a different representation (a pointer
only) and is imported as an ordinary class; it is not mapped to `Core.Slice`.
`<span>` requires C++20, so a translation unit using the mapping compiles with
`-std=c++20` or later (the fork's conformance programs pass
`--clang-arg=-std=c++20`). As for `std::string_view`, the mapping assumes a
64-bit target whose standard library lays out the span as pointer then size
(libc++ and libstdc++ both do).

### C++ ranges in `for` loops

Proposal 1885 lets a `for` loop iterate over a value of any type that
implements its `Iterate` interface, and leaves C++ ranges to future work. In
the 0.1 toolchain, a C++ range can be the range of a Carbon `for` loop. For a
C++ class whose `begin` and `end` are found as members or by argument-dependent
lookup and return an iterator of class type, the toolchain implements
`Core.Iterate`, and the loop calls `begin` and `end` and dereferences and
increments the iterator, as a C++ range-based `for` does (the fork's
conformance programs
`fork/conformance/programs/interop/cpp_range_member_begin_end_iterate.carbon`
and `fork/conformance/programs/interop/cpp_range_adl_begin_end_iterate.carbon`).
Standard library containers are ranges this way.

```carbon
import Core library "io";

import Cpp inline '''c++
#include <vector>

inline std::vector<int> MakeVector() { return {2, 4, 6}; }
''';

fn Run() -> i32 {
  // A C++ range is a Carbon `for` range: the loop calls its `begin` and
  // `end`, and dereferences and increments the iterator.
  var v: Cpp.std.vector(i32) = Cpp.MakeVector();
  var sum: i32 = 0;
  for (n: i32 in v) {
    sum += n;
  }
  Core.Print(sum);
  v.push_back(8);
  var count: i32 = 0;
  for (unused n: i32 in v) {
    ++count;
  }
  Core.Print(count);
  return 0;
}
```

This prints `12` and `4`. A class whose `begin` and `end` return raw pointers
is not yet a range:

```carbon
import Core library "io";

import Cpp inline '''c++
struct Digits {
  int values[3] = {1, 2, 3};
  int* begin() { return values; }
  int* end() { return values + 3; }
};
''';

fn Run() -> i32 {
  var d: Cpp.Digits = Cpp.Digits.Digits();
  var product: i32 = 1;
  for (n: i32 in d) {
    product *= n;
  }
  Core.Print(product);
  return 0;
}
```

The toolchain reports ``cannot access member of interface `Core.Iterate` in type
`Cpp.Digits` that does not implement that interface`` (fork work item W-053).

## Threads, atomics, and the memory model

Carbon 0.1 uses C++'s threads, atomics, and synchronization, through interop,
under the C++ memory model: a Carbon function runs on a `std::thread`, a Carbon
variable can have a `std::atomic` type, and C++ locks order Carbon accesses as
they order C++ ones. The contract is specified in
[Threads, atomics, and the memory model](threads_and_atomics.md) (fork decision
F-008).

## The operator interoperability model

Carbon defines operators by implementing interfaces, and C++ defines them as
functions. The [language overview](../README.md#operator-overloading-1)
describes a mapping in both directions: a C++ operator overload makes the type
usable with the corresponding Carbon operator, and a Carbon interface
implementation makes the C++ operator available. The 0.1 toolchain implements
the first direction: a Carbon operator expression with a C++ operand looks up
the C++ operator functions, members and non-members, and resolves among them
with C++ overload resolution (proposal 6254, "Operator calls"). Imported this
way are the binary arithmetic, bitwise, shift, and relational operators, `==`
and `!=`, compound assignment, indexing, unary `-`, prefix `++` and `--`, and
`^x` for C++'s `operator~` (pinned by
`toolchain/check/testdata/interop/cpp/operators/`).

```carbon
import Core library "io";

import Cpp inline '''c++
struct Money {
  int cents;
  static Money Make(int c) { return Money{c}; }
  Money operator-() const { return Money{-cents}; }
  friend Money operator+(Money a, Money b) { return Money{a.cents + b.cents}; }
  friend Money& operator+=(Money& a, Money b) {
    a.cents += b.cents;
    return a;
  }
  friend bool operator==(Money a, Money b) { return a.cents == b.cents; }
  friend bool operator<(Money a, Money b) { return a.cents < b.cents; }
};
''';

fn Run() -> i32 {
  var a: Cpp.Money = Cpp.Money.Make(30);
  let b: Cpp.Money = Cpp.Money.Make(12);
  // Carbon operator syntax calls the C++ operators that C++ overload
  // resolution selects.
  var c: Cpp.Money = a + b;
  Core.Print(c.cents);
  c += a;
  Core.Print((-c).cents);
  if (a == Cpp.Money.Make(30) and b < a) {
    Core.Print(1);
  }
  return 0;
}
```

This prints `42`, `-72`, and `1`. Not imported in 0.1 (fork work item W-045):
`operator=`, C++20's rewritten comparisons (`!=` from `==`, ordering from
`<=>`), operators whose result is not `bool` where Carbon needs a `bool`, and a
set of several `operator*` overloads. Some C++ operators have no Carbon
operator to map to, by design: unary `+`, postfix `++` and `--`, `!`, `&&`,
`||`, and the comma operator, since Carbon's logical operators are `not`,
`and`, and `or` on `bool`; the
[language overview](../README.md#operator-overloading-1) keeps operators like
these C++-only. Because `operator=` is not imported, assigning an `int` to a
C++ class through its `operator=(int)` fails:

```carbon
import Cpp inline '''c++
struct Cell {
  int value;
  static Cell Make(int n) { return Cell{n}; }
  Cell& operator=(int n) {
    value = n;
    return *this;
  }
};
''';

fn F() -> i32 {
  var c: Cpp.Cell = Cpp.Cell.Make(1);
  c = 42;
  return c.value;
}
```

The toolchain reports ``cannot implicitly convert expression of type
`Core.IntLiteral` to `Cpp.Cell` ``. The other direction is not implemented: a
Carbon type's operator interface implementations are not exported as C++
operators (fork work item W-054).

## References

-   Proposal
    [#6358: C++ Interop: API importing and semantics](https://github.com/carbon-language/carbon-lang/pull/6358)
