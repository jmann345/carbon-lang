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
> unchanged. Dated fork notes in it mark where it and the 0.1 toolchain differ:
> the illustrative `buf(T)`, two uses of a template type parameter in a class,
> the `Convert(i, f32)` example, deduction through a class's arguments, and
> specialization. The sketch also differs from proposal 2200 itself:
> proposal 2200 lets a specialization change only an implementation and
> rejects ad hoc API specialization (its "Alternatives considered"), which the
> sketch's Overloading section anticipates, and its template constraints,
> below, answer the open question of the sketch's last section. "Limits of the
> 0.1 toolchain", in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain), lists
> differences between the 0.1 toolchain and proposal 2200, each with the
> program or toolchain test that shows it; neither that list nor the fork notes
> is a complete comparison. Template constraints are accepted:
> proposal 818 introduced `template constraint` declarations, whose member
> requirements proposal 2200 specifies, and fork decision F-010 adds `require`
> validity blocks and boolean predicates. Member requirements are implemented
> on the fork's held template-constraint branch (SC-1), and `require` blocks
> and predicates are fork work item W-028; none of them is in the toolchain
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

> **Fork note (2026-10-14).** In the 0.1 toolchain, not every use of `T` in the
> definition waits for instantiation. A method of `Stack` that declares `var y:
> T;` without an initializer is rejected where the class is defined, with
> ``cannot convert type `T` into type implementing `Core.DefaultOrUnformed` ``
> (fork work item W-127, held PR 51). In a class `Holder(template T: type)`
> whose method `First` returns `self.item[0]`, a call of `First` on a
> `Holder(array(i32, 2))` is rejected with ``unable to monomorphize specific
> `First(array(i32, 2))` `` and the note ``cannot access member of interface
> `Core.IndexWith(Core.IntLiteral)` in type `array(i32, 2)` that does not
> implement that interface`` (W-192), although an `array(i32, 2)` member can be
> indexed in a class without a template parameter. The limits in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain) include both.

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

> **Fork note (2026-10-14).** In the 0.1 toolchain, a deduced template
> parameter is not computed from a class's arguments. With
> `class Holder(T: type)`, a call of
> `fn GetTemplate[template T: type](h: Holder(T)) -> T` on a `Holder(i32)` is
> rejected with ``cannot deduce value for generic parameter `T` ``, while the
> same declaration with a checked parameter, `[T: Core.Copy]`, deduces `T` as
> `i32`; a parameter of type `Holder(T)*`, or `Vec(N)` for
> `class Vec(template N: i32)`, behaves the same (fork work item W-193).

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
(`class Holder(template T: type)`). In a function with a template parameter,
the expressions whose meaning depends on the parameter are type-checked when the
function is called, once for each distinct template argument: member access,
method calls, conversions, and the arithmetic, bitwise, comparison, and logical
operators, including compound assignment, `++`, and `--`, are resolved for the
argument that the call supplies. Some other uses of a template-dependent value
are rejected where the function is defined, or fail when it is called for an
argument that would make them valid; the limits below include the pointer
operators `*`, `->`, and `&`, tuple element access, indexing an array, copying
a struct, and calls.

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

Limits of the 0.1 toolchain, each shown by the program or toolchain test cited
(the list is not complete):

-   Member lookup into a template parameter does not consult the parameter's
    constraint. Proposal 2200 looks a name up both in the argument type and in
    the interface constraint; the toolchain looks only in the argument type, so
    a member that the type provides only through an `impl` without `extend` is
    not found (fork work item W-183). The example after this list shows it;
    declaring the member with `extend impl as HasArea` makes it compile. Where
    the type and the constraint give a name different meanings, the toolchain
    does not report it either: for a class with its own method `F` and an
    `impl as A` without `extend` whose `F` differs, and `x.F()` in
    `fn G[template T: A](x: T)`, proposal 2200 rejects the call when `G` is
    instantiated, but the toolchain calls the type's member.
-   A template function defined in one library and called from another stops
    the compiler during checking, as it does in the upstream nightly (W-014).
-   A `match` on a template-dependent value is not supported (it reports
    ``semantics TODO: `match on unsupported scrutinee type` ``), so the
    [`match`-based rules](pattern_matching.md#templates) of pattern matching do
    not apply yet.
-   Template `let` bindings are not supported (W-031). Proposal 2200's
    `let template N:! i64 = 4;` is written `let template N: i64 = 4;` in the
    toolchain's syntax; in a function body it reports the diagnostic shown in
    [Compile-time evaluation in the 0.1 toolchain](metaprogramming.md#compile-time-evaluation-in-the-01-toolchain),
    and at file scope, where proposal 2200's own example declares it with the
    array bound `N`, it reports ``` semantics TODO: ``let` compile time
    binding outside function or interface` ```.
-   `auto`, which proposal 2200 calls a shortcut for an unnamed templated type,
    is not supported as a type: `let x: auto = F();` and `fn F() -> auto`
    report ``semantics TODO: `HandleAutoTypeLiteral` `` (W-039).
-   An array whose bound is a template parameter cannot be initialized from a
    list of values: `var a: array(i32, N) = (1, 2, 3);` in a function with the
    parameter `template N: i32` reports
    `cannot initialize array with dependent bound from a list of initializers`
    (pinned by `fail_todo_init_template_dependent_bound.carbon` in
    `toolchain/check/testdata/array/init_dependent_bound.carbon`). The upstream
    nightly accepts this initialization.
-   `template constraint` declarations are not parsed: the parser reports
    `unrecognized declaration introducer` (pinned by
    `fail_todo_template_constraint.carbon` in
    `toolchain/parse/testdata/generics/named_constraint/`); see
    [Status](#status).
-   Some operators on a template-dependent operand are checked where the
    function is defined and rejected, whatever the argument: for a parameter `p:
    T`, `*p` reports ``cannot dereference operand of non-pointer type `T` `` and
    `p.1` reports ``type `T` does not support tuple indexing; only tuples can be
    indexed that way``; for a member `p` of a template-dependent `x`, `x.p->n`
    reports ``cannot apply `->` operator to non-pointer type `<dependent
    type>` ``; and `&x.n` for a parameter `ref x: T` reports ``cannot take the
    address of non-reference expression`` (fork work item W-014;
    `generic/template/unimplemented.carbon` in the toolchain's check tests pins
    the dereference as `fail_todo`). Each compiles in a function without a
    template parameter.
-   A value whose type is a template parameter cannot be called: for
    `fn Apply[template G: type](h: G, x: i32) -> i32 { return h(x); }`, the call
    `Apply(Twice, 4)` reports
    ``unable to monomorphize specific `Apply(<type of Twice>)` `` with the note
    ``value of type `<type of Twice>` is not callable`` (W-014; pinned as
    `fail_todo` by `generic/template/call.carbon`).
-   Copying a value whose type is a template argument of struct type, and
    indexing one of array type, fail when the call is instantiated: the
    toolchain resolves them through `Core.Copy` and `Core.IndexWith`, which
    those types do not implement, although the same code with the type written
    out runs (fork work item W-192). `fn Id[template T: type](p: T) -> T` with
    the body `return p;`, called on a `{.x: i32, .y: i32}`, reports ``unable to
    monomorphize specific `Id({.x: i32, .y: i32})` `` with the note ``cannot
    access member of interface `Core.Copy` in type `{.x: i32, .y: i32}` that
    does not implement that interface``, and `a[1]` for a parameter `a: T` in a
    function `Second`, called on an `array(i32, 3)`, reports ``unable to
    monomorphize specific `Second(array(i32, 3))` `` with the note ``cannot
    access member of interface `Core.IndexWith(Core.IntLiteral)` in type
    `array(i32, 3)` that does not implement that interface``.
-   A tuple value whose type is a template argument is not compiled correctly:
    on an `(i32, i32)` argument, destructuring a parameter `p: T` with
    `let (a: i32, b: i32) = p;` stops the compiler while it lowers the
    instantiation, and `fn Id[template T: type](p: T) -> T { return p; }`
    returns values other than its argument's, which differ from run to run
    (W-014).
-   A `var` of a template parameter's type without an initializer, `var y: T;`,
    is rejected where the function is defined with ``cannot convert type `T`
    into type implementing `Core.DefaultOrUnformed` ``, where proposal 2200
    delays impl lookup until the template argument is known; `var y: i32;`
    compiles (fork work item W-127, held PR 51).
-   A deduced template parameter is not computed from a class's arguments, as
    the fork note in
    [Functions with template parameters](#functions-with-template-parameters)
    shows (W-193).
-   `partial T*` for a template parameter `T` is rejected with
    `` `partial` applied to final type `T` ``, as for a checked parameter,
    although whether the template argument is final is known only on
    instantiation (pinned as `fail_todo` by `class/partial/qualifier.carbon` in
    the toolchain's check tests).

The first limit, for example:

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

As the accepted design specifies, an interface constraint is satisfied only by
types that implement the interface: for a class `Circle` with an `Area` method
and no `impl`, a call `Report(c)` is rejected with
``cannot convert type `Circle` into type implementing `HasArea` ``. A
constraint on the members a type declares is a `template constraint`
(proposals 818 and 2200; see [Status](#status)).
