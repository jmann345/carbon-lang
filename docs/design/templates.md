# Templates

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Status](#status)
-   [Overview](#overview)
    -   [Types with template parameters](#types-with-template-parameters)
    -   [Functions with template parameters](#functions-with-template-parameters)
    -   [Overloading](#overloading)
    -   [Constraining templates with interfaces](#constraining-templates-with-interfaces)
-   [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain)

<!-- tocstop -->

## Status

> **Fork status (2026-10-14).** Template generics are accepted: proposal 2200
> makes them part of Carbon, with the terminology of proposal 2138 and the
> name-lookup rules of question-for-leads issue 949 and proposal 989, and the
> [language overview](README.md#checked-and-template-parameters) summarizes the
> accepted design. The [overview](#overview) below is an older sketch, kept
> unchanged. The fork notes in it mark the three places where it and the 0.1
> toolchain differ (the illustrative `buf(T)`, the `Convert(i, f32)` example,
> and specialization), and the open question of its last section is answered
> by F-010, below; no other difference from proposal 2200 is known. Template
> constraints are fixed by fork decision F-010 (`template constraint`
> declarations, `require` validity blocks, and boolean predicates); the SC-1
> workstream implements its member requirements, `require` blocks and
> predicates are fork work item W-028, and none of them is in the toolchain
> this page describes. What the 0.1 toolchain implements is documented, with
> examples that compile, in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain).

## Overview

Carbon templates follow the same fundamental paradigm as C++ templates: they are
instantiated, resulting in late type checking, duck typing, and lazy binding.
They both enable interoperability between Carbon and C++ and address some
(hopefully limited) use cases where the type checking rigor imposed by generics
isn't helpful.

### Types with template parameters

When parameterizing a user-defined type, the parameters can be marked as
template parameters. The resulting type-function will instantiate the
parameterized definition with the provided arguments to produce a complete type
when used. Note that only the parameters marked as having this template behavior
are subject to full instantiation -- other parameters will be type checked and
bound early to the extent possible. For example:

```
class Stack(template T: type) {
  var storage: buf(T);

  fn Push(ref self, value: T);
  fn Pop(ref self) -> T;
}
```

This both defines a parameterized type (`Stack`) and uses one (`buf`). Within
the definition of the type, the template type parameter `T` can be used in all
of the places a normal type would be used, and it will only by type checked on
instantiation.

> **Fork note (2026-10-14).** `buf(T)` is illustrative; Carbon has no `buf`
> type, and the fork's heap buffer is `Core.Buf(T)` ([Slices](slices.md)). A
> class with a `template` parameter compiles and runs in the 0.1 toolchain, as
> `Holder` does in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain).

### Functions with template parameters

Both deduced and explicit function parameters in Carbon can be marked as
template parameters. When called, the arguments to these parameters trigger
instantiation of the function definition, fully type checking and resolving that
definition after substituting in the provided (or computed if deduced)
arguments. The runtime call then passes the remaining arguments to the resulting
complete definition.

```
fn Convert[template T: type](source: T, template U: type) -> U {
  var converted: U = source;
  return converted;
}

fn Foo(i: i32) -> f32 {
  // Instantiates with the `T` deduced argument set to `i32` and the `U`
  // explicit argument set to `f32`, then calls with the runtime value `i`.
  return Convert(i, f32);
}
```

Here we deduce one type parameter and explicitly pass another. It is not
possible to explicitly pass a deduced type parameter, instead the call site
should cast or convert the argument to control the deduction. The explicit type
is passed after a runtime parameter. While this makes that type unavailable to
the declaration of _that_ runtime parameter, it still is a template parameter
and available to use as a type even within the remaining parts of the function
declaration.

> **Fork note (2026-10-14).** Under the accepted
> [implicit conversion rules](expressions/implicit_conversions.md), `i32` does
> not implicitly convert to `f32`, so the toolchain rejects this instantiation
> with ``unable to monomorphize specific `Convert(i32, f32)` ``. The same
> function with an `i64` target compiles and runs, as in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain).

### Overloading

An important feature of templates in C++ is the ability to customize how they
end up specialized for specific types. Because template parameters (whether as
type parameters or function parameters) are pattern matched, we expect to
leverage pattern matching techniques to provide "better match" definitions that
are selected analogously to specializations in C++ templates. When expressed
through pattern matching, this may enable things beyond just template parameter
specialization, but that is an area that we want to explore cautiously.

> **Fork note (2026-10-14).** The 0.1 toolchain does not specialize templates
> by pattern matching. An [overload set](functions_overloading.md) can combine
> members for specific types with a member that has a template parameter; the
> set is resolved in declaration order (fork decision F-009).

### Constraining templates with interfaces

Because we consider only specific _parameters_ to be templated and they could be
individually migrated to a constrained interface using the
[checked-generics system](README.md#generics), constraining templates themselves
may be less critical. Instead, we expect parameterized types and functions may
use a mixture of checked and template generic parameters based on where they are
constrained.

However, if there are still use cases, we would like to explore applying the
interface constraints of the checked-generics system directly to template
parameters rather than create a new constraint system.

## Templates in the 0.1 toolchain

The toolchain implements template parameters: a binding marked `template` in a
deduced parameter list (`[template T: type]`), in an explicit parameter list
(`template N: i32`), or in a class's parameter list
(`class Holder(template T: type)`). A function with a template parameter is
type-checked when it is called, once for each distinct template argument: member
access, conversions, and operators whose meaning depends on a template
parameter are resolved for the argument that the call supplies.

```carbon
import Core library "io";

class Point {
  var x: i32;
  var y: i32;
}

class Size {
  var x: i32;
  var y: i32;
  var depth: i32;
}

class Meters {
  var n: i32;
  impl as Core.ImplicitAs(i32) {
    fn Convert(self) -> i32 { return self.n; }
  }
}

// `p.x` and `p.y` are looked up in the type `T` that each call supplies,
// when the call is instantiated, not when `Sum` is defined.
fn Sum[template T: type](p: T) -> i32 {
  return p.x + p.y;
}

// The conversion and the operator are resolved per instantiation.
fn ToInt[template T: type](x: T) -> i32 {
  let n: i32 = x;
  return n + n;
}

// A deduced template parameter and an explicit one, as in the overview.
fn Convert[template T: type](source: T, template U: type) -> U {
  var converted: U = source;
  return converted;
}

// A template parameter of non-type type.
fn Scale(template N: i32, x: i32) -> i32 {
  return N * x;
}

// A class with a template parameter; its members are checked for each
// argument.
class Holder(template T: type) {
  var item: T;
  fn Get(self) -> T { return self.item; }
}

fn Run() -> i32 {
  let a: Point = {.x = 1, .y = 2};
  let b: Size = {.x = 30, .y = 40, .depth = 0};
  Core.Print(Sum(a));
  Core.Print(Sum(b));
  let m: Meters = {.n = 6};
  Core.Print(ToInt(m));
  let wide: i64 = Convert(7 as i32, i64);
  Core.Print(wide as i32);
  Core.Print(Scale(3, 14));
  let h: Holder(i32) = {.item = 8};
  Core.Print(h.Get());
  return 0;
}
```

This prints `3`, `70`, `12`, `7`, `42`, and `8`.

An instantiation that does not type-check is reported at the call, with the
reason as a note:

```carbon
class Empty {}

fn GetX[template T: type](p: T) -> i32 {
  return p.x;
}

fn Use(e: Empty) -> i32 {
  return GetX(e);
}
```

The toolchain reports ``unable to monomorphize specific `GetX(Empty)` ``, with
the note ``member name `x` not found in `Empty` ``. A checked parameter, without
`template`, is rejected at the function's definition instead, because a checked
generic's members come only from its constraint:

```carbon
fn GetX[T: type](p: T) -> i32 {
  return p.x;
}
```

This reports ``type `T` does not support qualified expressions``.

Limits of the 0.1 toolchain, each a filed fork work item:

-   Member lookup into a template parameter does not consult the parameter's
    constraint. Proposal 2200 looks a name up both in the argument type and in
    the interface constraint; the toolchain looks only in the argument type, so
    a member that the type provides only through an `impl` without `extend` is
    not found (W-183). Declaring it with `extend impl as HasArea` makes the
    call below compile.
-   A template function defined in one library and called from another stops
    the compiler during checking, as it does in the upstream nightly (W-014).
-   An interface constraint is satisfied only by types that implement the
    interface; a type with matching members but no `impl` is rejected with
    ``cannot convert type `Circle` into type implementing `HasArea` ``.
    Structural constraints are F-010's template constraints (see Status).
-   A `match` on a template-dependent value is not supported, so the
    [`match`-based rules](pattern_matching.md#templates) of pattern matching do
    not apply yet.

```carbon
interface HasArea {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  impl as HasArea {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Use(q: Square) -> i32 {
  return Report(q);
}
```

This reports ``unable to monomorphize specific `Report(Square as HasArea)` ``
with the note ``member name `Area` not found in `Square` ``.
