# Optional

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** Fork design (F-015, 2026-10-13): `Core.Optional` as implemented in
the fork's prelude, core/prelude/types/optional.carbon; toolchain status: OP-1
landed 2026-10-13, and OP-2 landed 2026-10-14: an Optional destroys the value it
holds, `Get()` fails-stop on an empty value, `Core.Optional(bool)` and nested
pointer-niche Optionals read correctly, and only `Core.Optional(T*)` may be
declared without an initializer. Upstream has no approved design for
`Core.Optional` (proposal p006357, future work).

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [The type](#the-type)
    -   [The API](#the-api)
    -   [A class, not a choice](#a-class-not-a-choice)
    -   [Storage and the null niche](#storage-and-the-null-niche)
-   [Comparison](#comparison)
-   [Ownership and lifetime](#ownership-and-lifetime)
-   [Propagation and iteration](#propagation-and-iteration)
-   [Pattern matching](#pattern-matching)
-   [C++ interoperability](#c-interoperability)
-   [0.1 limits](#01-limits)
-   [Alternatives considered](#alternatives-considered)
-   [References](#references)

<!-- tocstop -->

## Overview

`Core.Optional(T)` holds either no value or one value of type `T`. Upstream's
design already depends on it in four places, and this page is the fork's design
for those uses:

-   **Nullable pointers.** "There are no null pointers in Carbon. To represent a
    pointer that may not refer to a valid object, use the type `Optional(T*)`."
    ([Pointer types](README.md#pointer-types)); "Optional pointers are expected
    to serve nullable use cases" ([Values](values.md#pointers)).
-   **Iteration.** `Iterate.Next` returns `Optional(ElementType)`, and a `for`
    loop runs until it returns an empty value
    ([Ranged-for for user-defined types](control_flow/loops.md#ranged-for-for-user-defined-types)).
-   **Error propagation.** `Optional(T)` implements `Try`, so `?` propagates
    absence ([Error handling](error_handling.md#optional-and-user-types),
    decision D9).
-   **C++ interoperability.** A nullable C++ `T*` maps to `Core.Optional(T*)`
    (proposal
    [p006357](/proposals/p006357-c-interop-mapping-pointer-types.md)).

Upstream records the gap itself: "While we do not yet have an approved design
for the `Core.Optional` type, it is already in use in the design of `for`
statements" (p006357), and the prelude calls the API a placeholder. This page is
the fork's answer, fork design F-015, recorded in the fork decision log for
after-the-fact veto. It adopts the type as the prelude implements it, adds
comparison, and states the ownership rules. The [0.1 limits](#01-limits)
section lists each filed limit of the 0.1 toolchain against it, and the one
divergence it discloses, with the condition under which each closes.

A typical use tests for a value before reading it:

```carbon
fn ValueOr(o: Core.Optional(i32), fallback: i32) -> i32 {
  if (o.HasValue()) {
    return o.Get();
  }
  return fallback;
}
```

## The type

`Core.Optional(T)` is a class holding either no value ("empty", made by
`None()`) or one value of type `T` (made by `Some(v)`). It adapts the storage
type `T.(OptionalStorage.Type)`: by default a `{MaybeUnformed(T), bool}` pair,
and for a pointer type `T*` a single `MaybeUnformed(T*)` word in which the null
pointer is the empty value, so `Core.Optional(T*)` has a C++ pointer's ABI and
is what a nullable C++ `T*` imports as. `OptionalStorage` is private, so in 0.1
every `T` must be `Core.Copy & Core.Destroy` (the default storage's bound) or a
pointer, and generic code names `Core.Copy & Core.Destroy` for its `T` (W-176).

| Member | Meaning |
| --- | --- |
| `fn None() -> Self` | the empty value |
| `fn Some(value: T) -> Self` | a value holding a copy of `value` (one `Copy`) |
| `fn HasValue(self) -> bool` | whether it holds a value |
| `fn Get(self) -> T` | a copy of the held value; requires `HasValue()`, and fails-stop on an empty value |
| `impl forall [T: OptionalStorage] Optional(T) as Copy` | copies the held value, if any |
| `impl forall [T: type] Optional(T*) as UnformedInit` | a pointer-niche Optional may be declared without an initializer; any other may not (W-200) |
| `ImplicitAs(Optional(T))` from `T`, from any `U: ImplicitAs(T)` and from `Optional(U)` | `Some` of the (converted) value; empty stays empty |
| `final impl forall [T: Destroy & OptionalStorage] Optional(T) as Try where .ContinueType = T and .BreakType = ()` | `o?` continues with the value or propagates absence as `()` (D9) |
| `final impl forall [T: Destroy & OptionalStorage & Eq] Optional(T) as EqWith(Optional(T))` | `==` and `!=` ([Comparison](#comparison)) |
| `final impl forall [T: Destroy & OptionalStorage & Ordered] Optional(T) as OrderedWith(Optional(T))` | `<`, `<=`, `>` and `>=` ([Comparison](#comparison)) |

Not provided, on purpose or as a filed limit: `.Some` and `.None` patterns and
`match` over an Optional (W-177); an explicit `as` between Optionals of
different payloads (W-175); comparison with a bare `T` or with `Cpp.nullptr`
(W-178); comparison of a pointer-niche Optional whose pointer type is not
`Core.Eq`, which is every built-in pointer (W-174); declaring a non-pointer
Optional without an initializer (W-200).

### The API

The public declarations of core/prelude/types/optional.carbon, with function
bodies elided:

```carbon
class Optional(T: OptionalStorage) {
  fn None() -> Self;
  fn Some(value: T) -> Self;
  fn HasValue(self) -> bool;
  fn Get(self) -> T;
  adapt T.Type;
}

impl forall [T: type] Optional(T*) as UnformedInit {}

impl forall [T: OptionalStorage] Optional(T) as Copy;

final impl forall [T: Destroy & OptionalStorage] Optional(T) as Try
    where .ContinueType = T and .BreakType = ();

impl forall [T: OptionalStorage, U: OptionalAs(T)]
    U as ImplicitAs(Optional(T));

final impl forall [T: Destroy & OptionalStorage & Eq]
    Optional(T) as EqWith(Optional(T));

final impl forall [T: Destroy & OptionalStorage & Ordered]
    Optional(T) as OrderedWith(Optional(T));
```

The storage, private to the prelude:

```carbon
private interface OptionalStorage {
  let Type: Destroy;
  fn None() -> Type;
  fn Some(self) -> Type;
  fn Has(value: Type) -> bool;
  fn Get(value: Type) -> Self;
  fn Copy(value: Type) -> Type;
}

private class DefaultOptionalStorage(T: Copy & Destroy) {
  var value: MaybeUnformed(T);
  var has_value: bool;
}

impl forall [T: Copy & Destroy] T as OptionalStorage
    where .Type = DefaultOptionalStorage(T);

impl forall [T: Copy & Destroy] DefaultOptionalStorage(T) as Destroy;

final impl forall [T: type] T* as OptionalStorage
    where .Type = MaybeUnformed(T*);
```

The three conversions behind the public `ImplicitAs` impl go through a private
interface:

```carbon
private interface OptionalAs(T: OptionalStorage) {
  fn Convert(self) -> Optional(T);
}

final impl forall [T: OptionalStorage]
    T as OptionalAs(T);

impl forall [T: Destroy & OptionalStorage, U: ImplicitAs(T)]
    U as OptionalAs(T);

impl forall [T: Destroy & OptionalStorage,
             U: Destroy & OptionalStorage & ImplicitAs(T)]
    Optional(U) as OptionalAs(T);
```

### A class, not a choice

The design's own examples spell `Optional` as a `choice` with alternatives
`.Some` and `.None` ([Sum types](sum_types.md#choice-declarations)), and as a
class that implements `Match`
([User-defined sum types](sum_types.md#user-defined-sum-types)). The fork's
error-handling step kept the prelude's class (fork decision D-EH-1, which
resolved SF-9: "`Core.Optional` KEEPS its placeholder class identity") and left
re-platforming it onto `choice` to the Optional design, W-058, which is this
page. F-015 keeps the class (fork decision D-OP-7), because the names and the
layout it has are already load-bearing:

-   the toolchain's `for` calls `HasValue` and `Get` by name
    (toolchain/check/handle_loop_statement.cpp);
-   the C++ mapping finds the type by its name, `Optional`
    (toolchain/sem_ir/type_info.cpp), and a nullable C++ `T*` must keep a C++
    pointer's ABI;
-   the `Try` impl's signature is fixed by the error-handling design (D9);
-   `Main.Run`'s `argv` parameter is a `Core.Optional(char*)*`.

Comparison does not need a `choice`, so F-015 keeps the class and records
matchability as a limit (W-177, [Pattern matching](#pattern-matching)).

### Storage and the null niche

A `Core.Optional(T)` is the storage type `T.(OptionalStorage.Type)`, adapted.
The default storage is `DefaultOptionalStorage(T)`, a `MaybeUnformed(T)` value
beside a `bool` that says whether it holds one; `Some` copies its argument into
the unformed field, and `Get` reads it back as a `T`. A pointer type `T*` has
its own `final` storage impl, a single `MaybeUnformed(T*)`, in which
`"pointer.make_null"` is the empty value and `HasValue()` is a null test. That
is what proposal p006357 requires: "This places a constraint on the
implementation of `Core.Optional(T*)` that it has the same ABI as a C++ pointer,
including that the "none" state is represented with a C++ null pointer
representation."

`OptionalStorage` is private (its declaration says "TODO: Decide how to expose
this in the public API"), so user code cannot name it. A type outside the
prelude can therefore be the payload of a `Core.Optional` only through one of
the two public storage impls: it is `Core.Copy & Core.Destroy`, or it is a
pointer. Generic code says so in its bounds:
`fn F[T: Core.Eq & Core.Copy & Core.Destroy](a: Core.Optional(T))`. A bound of
`Core.Eq` alone is rejected with "cannot convert type `T` that implements
`Core.Eq` into type implementing `Core.OptionalStorage`". The design's
`class Optional(T: Movable)` keeps the storage bound out of the public API
([Specialization](generics/details.md#specialization)); until the fork does the
same, a non-copyable value cannot be held (W-176).

## Comparison

`Core.Optional(T)` implements `Core.EqWith(Core.Optional(T))` when `T` is
`Core.Eq`, and `Core.OrderedWith(Core.Optional(T))` when `T` is `Core.Ordered`;
neither requires the other. Two empty values are equal. An empty value and a
non-empty value are not equal. Two non-empty values are equal exactly when their
values are equal under `T`'s `==`, and `!=` on them is `T`'s `!=`. An empty
value orders before every non-empty value, two empty values are equivalent, and
two non-empty values order as their values do under `T`'s `<`, `<=`, `>` and
`>=`. Both operands have the type `Core.Optional(T)`: there is no comparison
with a bare `T`, with `Cpp.nullptr`, or with `Core.Optional(U)` for another `U`.

With `a` and `b` of type `Core.Optional(T)`, and `x` and `y` their values when
they hold one:

| Expression | both empty | `a` empty, `b` not | `a` not, `b` empty | both hold values |
| --- | --- | --- | --- | --- |
| `a == b` | true | false | false | `x == y` |
| `a != b` | false | true | true | `x != y` |
| `a < b` | false | true | false | `x < y` |
| `a <= b` | true | true | false | `x <= y` |
| `a > b` | false | false | true | `x > y` |
| `a >= b` | true | false | true | `x >= y` |

This is the table of C++'s `[optional.relops]` for two `std::optional<T>`
operands, where `!=` on two engaged operands is the contained type's `!=`, and
the order Rust derives for `Option<T>`, in which `None` compares less than any
`Some`. Because the two agree, a C++ program over `std::optional<int>` is a
differential oracle for Carbon's `Core.Optional(i32)` comparisons. The relation
is an equivalence when `T`'s `==` is one, the order is transitive and consistent
under reversal when `T`'s is, and equality refines the order when `T`'s equality
refines `T`'s order, as
[Compatibility of equality and ordering](expressions/comparison_operators.md#compatibility-of-equality-and-ordering)
asks. That section also places no requirement that a type with an ordering has
an equality, which is why the two impls are independent: a payload that is only
`Core.Ordered` gives Optionals that order and do not compare equal.

The operands must have the same type because "the `EqWith` overload is selected
without considering possible implicit conversions"
([Equality](expressions/comparison_operators.md#equality)). The remedy that
section names, the
[`like` operator](generics/details.md#like-operator-for-implicit-conversions),
is not implemented (W-178), so `o == 5` and `o == Cpp.nullptr` have no impl,
and an `Optional(i32)` does not compare with an `Optional(i64)`. The
conditional impls are
[conditional conformance](generics/details.md#conditional-conformance), whose
motivating example is the same shape: a container compared with another
container with the same element type when the element type is comparable.

Generic code compares Optionals by naming the payload's constraint:

```carbon
fn Same[T: Core.Eq & Core.Copy & Core.Destroy](a: Core.Optional(T),
                                               b: Core.Optional(T)) -> bool {
  return a == b;
}
```

A checked generic may also compare a `Core.Optional(T)` that it creates, such
as `Core.Optional(T).Some(a) == b` or a `let` of that type: every storage type
is `Core.Destroy`, so the generic can destroy the Optional it made.

A pointer-niche `Core.Optional(T*)` compares exactly when `T*` is `Core.Eq`. The
prelude gives the built-in pointer types no `==` (W-174), so
`Core.Optional(i32*)` does not compare; a library that owns a class `C` may
implement `C* as Core.EqWith(C*)`, and `Core.Optional(C*)` then compares.
`Core.Optional(bool)` and `Core.Optional(Core.Optional(U*))` compare, and are
read and copied, like any other payload. For a payload that exists only at
compile time, such as `Core.IntLiteral`, comparing two `Core.Optional(T)` values
passes check and then crashes the compiler in lowering, as a checked generic's
`==` on `Core.IntLiteral` does without Optional (W-195).

For example, with a library's own pointer equality, which compares the objects
the pointers refer to, `Core.Optional(C*)` values compare through the null
niche:

```carbon
class C {
  var v: i32;
}

impl C* as Core.EqWith(C*) {
  fn Equal(self, other: C*) -> bool { return self->v == other->v; }
  fn NotEqual(self, other: C*) -> bool { return self->v != other->v; }
}

fn SameC(a: Core.Optional(C*), b: Core.Optional(C*)) -> bool {
  return a == b;
}
```

In 0.1 a comparison of two non-empty values reads each through `Get()`, which
runs `T`'s `Copy` once and its `Destroy` once per value. The comparison
operators design says that `EqWith`'s operations and the members of an
`OrderedWith` implementation "should have no observable side-effects"; for a `T`
whose `Copy` or `Destroy` has an observable effect, so does comparing two
`Core.Optional(T)` values. This is a fork divergence, which a by-reference
accessor or matchability (W-177) removes.

Each comparison tests `HasValue()` on its operands before it calls `Get()`, so
the storage of an empty operand is never read, and a comparison with an empty
operand copies nothing. Neither operand is moved, changed or destroyed.

The impls are `final`: when `T` is `Core.Eq`, no other library can change what
`==` means on `Core.Optional(T)`. Proposal p5337 makes a non-final impl that a
`final` impl completely subsumes an error; the 0.1 toolchain reports it only
where the impl would be used, not at its declaration (W-179).

`final` is a choice, not a necessity: `EqWith` and `OrderedWith` have no
associated constants, so generic code type-checks without it. It is chosen
because comparison is part of the type's definition, as for the prelude's
integer comparisons (`Int(N)` with `Int(M)`) and floating-point comparisons,
which are `final` too. A
payload that is not `Core.Eq` is not matched by the final impl, so its library
may still implement `Core.Optional(Q) as Core.EqWith(Core.Optional(Q))` and
define `==` on its Optionals. The prelude may declare these `final` impls
because it declares the root of their `Self` type
([Libraries that can contain a `final` impl](generics/details.md#libraries-that-can-contain-a-final-impl)).

An accepted design already presupposes this equality: in
[Pattern matching](pattern_matching.md#alternative-patterns), "a pattern of the
form `Optional(T).None` is an expression pattern and is compared using `==`"
(proposal p002188).

## Ownership and lifetime

An `Optional(T)` owns the value it holds: `Some(v)` stores a copy of `v`,
copying an `Optional(T)` copies its value, and destroying a non-empty
`Optional(T)` destroys its value, once. `Core.Optional(T*)` has nothing to
destroy and is trivially destructible, so a union may have a
`Core.Optional(T*)` field.

The rule is C++'s for `std::optional` and Rust's for `Option`, and the
destructors proposal's `Optional` sketch destroys its value exactly when it
holds one ("`if (me.holds_value) value.Destroy();`", proposal p001154, a
considered alternative). The default storage holds the value in a
`MaybeUnformed(T)`, which runs no destructor of its own, and declares the
`Destroy` that destroys the value when it holds one. `Core.Optional(T)` adapts
its storage, and an adapter is destroyed as its adapted type, and is trivially
destructible exactly when that type is (fork design F-016,
[Adapters](classes.md#adapters)), so destroying the Optional runs that
`Destroy`. The pointer niche's storage, a `MaybeUnformed(T*)`, declares none,
so `Core.Optional(T*)` stays trivially destructible and keeps the union fields
that [Unions](unions.md#trivially-destructible-and-trivially-copyable-types)
admits; a `Destroy` declared on `Optional(T)` itself would have reached the
pointer niche too.

Under [Destructors](classes.md#destructors), a class that defines a destructor
with a non-empty body is not `TrivialDestructor`, so the default storage is
not, and by F-016 neither is `Core.Optional(T)` for a non-pointer `T`, even
when `T` is trivially destructible: a `Core.Optional(i32)` is not a union field
type, and destroying one tests whether it holds a value and, when it does,
calls the value's destroy, which for `i32` is an out-of-line call that does
nothing (W-196). Proposal p001154's way to make it conditional, a
`TrivialDestructor` impl for `Optional(U)` when `U` has one, was considered
there and not adopted. Because the storage's destroy reads whether it holds a
value, only `Core.Optional(T*)` may be declared without an initializer and left
unformed, as `Core.Buf` may not be (W-200). The programs
fork/conformance/programs/stdlib/optional_destroys_value.carbon,
optional_destroy_diff.carbon, the second with a C++ `std::optional` oracle, and
optional_cpp_class_destroy.carbon state the rule.

Comparisons never move or destroy a held value. A comparison of two non-empty
operands runs `T.Copy` and `T.Destroy` once per value, through `Get()`, and one
with an empty operand runs neither ([Comparison](#comparison)).

`Get()` requires `HasValue()`. On an empty value it fails-stop: it writes
`carbon: Core.Optional.Get on an empty value; terminating` to standard error and
aborts, as a `Core.Slice` bounds violation does. So `Get()` never returns the
unformed storage, and for `Core.Optional(T*)` never returns a null pointer,
which is the safety design's TY4 ("null is never a hole", F-013).

`Core.Optional(T)` is not `Core.Plain` for any `T` (F-013, D-SAFE-9): its value
sub-object exists only when it holds one, so under Strict Carbon assigning an
`Optional` through a shared path is an invalidating operation.

Assignment `o = p;` does not destroy the old value of any class with a
`Destroy`; that is not specific to `Core.Optional`, and is filed by the strings
workstream ("assignment does not destroy the overwritten value"). A class that
declares its own `Destroy` does not yet destroy its fields after that `Destroy`
runs, so an Optional field of such a class keeps its value (W-197); a class
without one destroys its fields, an Optional field included.

## Propagation and iteration

`?` on a `Core.Optional(T)` continues with the held value or propagates absence:
the `Try` impl has `ContinueType = T` and `BreakType = ()`
([Error handling](error_handling.md#optional-and-user-types), decision D9).
There is no implicit bridge to `Core.Result` (D9): inside a function that
returns `Core.Result(T, E)`, `?` on an Optional propagates absence as the `()`
that its `Try` impl breaks with, so it compiles only when `()` converts to `E`.
For `E = ()`, absence propagates as `.Err(())`; for any other `E` it is a
conversion error from `()` to `E`. The landed `Try` body
dispatches through `HasValue()` and `Get()`, the same two-way split as the
design's `match` sketch, because `Core.Optional` is not a choice. `?` builds a
`Core.ControlFlow(T, ())`, which is a `choice`, and in 0.1 a `choice` payload
must be a scalar or a pointer (SF-6), so `o?` on an Optional of a class or a
tuple is rejected, as `?` on a `Core.Result` of one is: the Sum types bullet's
W-010 residue.

A `for` loop over a type that implements `Iterate` calls its `Next`, which
returns `Optional(ElementType)`, and stops at the first empty value; the
toolchain calls `HasValue()` and `Get()` by name, which is why those two names
are part of this design
([Ranged-for for user-defined types](control_flow/loops.md#ranged-for-for-user-defined-types)).
Because `Core.Optional(T)` needs `T: Copy & Destroy` (W-176), so does
`Iterate.ElementType`: a range of non-copyable values cannot be iterated yet
(core/prelude/iterate.carbon, "TODO: Support iterating ranges of non-copyable
values").

## Pattern matching

`Core.Optional` is a class, not a `choice`, and is not matchable in 0.1: there
are no `.Some` and `.None` patterns and no `match` over it (W-177). The pattern
matching design's `Optional(T).None`, an expression pattern compared using `==`,
names a value; in this design `None` is a function, `Optional(T).None()`.

Code tests `HasValue()` and then calls `Get()`, or uses `?`. The
[Sum types](sum_types.md#user-defined-sum-types) design's `Match` interface,
through which a class becomes matchable, is not implemented. The examples in the
design that match on `Optional`, in [Sum types](sum_types.md),
[Pattern matching](pattern_matching.md#alternative-patterns) and the `Try`
sketch of [Error handling](error_handling.md#the-coretry-interface), and the
safety design's examples EX-M-5 and EX-M-6, wait on W-177, which may close by
`Match` for classes or by a `choice` that keeps the constraints of
[A class, not a choice](#a-class-not-a-choice); no redesign of `Core.Optional`
as a choice comes from this design.

> **Fork amendment (2026-10-21, DR-0 D-DR-1, DR-1).** Under fork/rulebook.md
> R32, matchability is not a fork limit chosen here: upstream designs
> `Optional`'s matching as a class implementing `Match`
> (docs/design/sum_types.md), and the fork takes that route, not a `choice`
> (DR-0 rejected the `choice` conversion). Its patterns are `.Some(<pattern>)`
> and, because `None` is a function here, `.None()` (sum_types.md:214-222);
> where this page says "`.Some` and `.None` patterns" it means those. W-177
> closes with W-320, which waits on a conflict in upstream's own pages over how
> `Match` declares `Continuation` (W-324), and the examples that match on
> `Optional` wait with it.

## C++ interoperability

A nullable C++ `T*` imports as `Core.Optional(T*)`, and `Core.Optional(T*)`
exports as `T*`; the null niche makes the two the same bits. `Cpp.nullptr`
converts to `Optional(T*).None()`. Comparing two C++ pointers in Carbon, and
therefore two `Core.Optional(T*)` values for a built-in `T*`, needs W-174.

An imported C++ class can be held, and `Some`, `HasValue()` and `Get()` work;
destroying a non-empty Optional of one runs the class's C++ destructor on the
held copy. If its `operator==` makes it `Core.Eq`, in 0.1 `==` on two
`Core.Optional(T)` values for such a class `T` fails to check with "semantics
TODO: `interop with non-identifier package name`" at the prelude's `Optional`
class: the comparison would need the toolchain to name the `Core` package from
C++, which it does not yet do (toolchain/check/cpp/export.cpp, W-049).

A mapping of C++'s `std::optional<T>` in either direction is not designed here:
it is the open half of the fork's work on sum-type consumption with
`std::variant` and `std::optional` interop (W-011). If that mapping targets
`Core.Optional(T)`, this design is amended first.

## 0.1 limits

Each limit is a filed fork work item, with the condition under which it closes:

-   **W-172: a float or character literal argument for a
    `T: Core.Copy & Core.Destroy` parameter aborts check.**
    `Core.Optional(f64).Some(2.5)` is an example; bind a typed value first
    (`let f: f64 = 2.5;`). Closes when the toolchain handles literal types
    there.
-   **W-174: the built-in pointer types have no `==`.** So `Core.Optional(T*)`
    compares only when a library gives `T*` an equality. Closes when the
    prelude gives `T*` an `EqWith(T*)` impl, whose design must say whether it
    is `final` and what happens to a library's own pointer equality, and
    optional_pointer_compare.carbon passes.
-   **W-175: no explicit `as` between Optionals of different payloads.**
    Closes with the design's own example,
    `impl forall [U: type, T: As(U)] Optional(T) as As(Optional(U))`; the
    implicit direction exists.
-   **W-176: the payload must be `Core.Copy & Core.Destroy`, or a pointer.**
    Closes when the storage bound leaves the public API, as in the design's
    `Optional(T: Movable)`.
-   **W-177: `Core.Optional` is not matchable.** Closes when `.Some` and
    `.None` patterns over it are implemented, by `Match` for classes or by a
    `choice` that keeps the constraints of
    [A class, not a choice](#a-class-not-a-choice).
-   **W-178: the `like` operator is not implemented.** Closes when `like`
    lands; the comparisons then admit implicit operand conversions only if the
    design says so.
-   **W-179: a non-final impl that a `final` impl completely subsumes is
    diagnosed only where it is used.** Closes when its declaration is
    diagnosed, as proposal p5337 specifies.
-   **W-196: `Core.Optional(T)` for a non-pointer `T` is not trivially
    destructible.** See [Ownership and lifetime](#ownership-and-lifetime): a
    `Core.Optional(i32)` is not a union field type, and destroying one tests
    whether it holds a value and calls the value's out-of-line destroy, where
    C++'s `std::optional<int>` is trivially destructible. Closes when a
    conditional `TrivialDestructor` rule is designed and adopted.
-   **W-199: a `const C` object never runs `C`'s declared `Destroy`.** So a
    `Core.Optional(const C)` keeps its held value. Filed under classes. Closes
    when a `const C` is destroyed as a `C` is.
-   **W-200: only `Core.Optional(T*)` may be declared without an
    initializer.** An unformed default storage would leave the flag that says
    whether it holds a value uninitialized for its destroy to read. For the
    same reason, a class with a non-pointer `Core.Optional` field, or an
    adapter of one, must not implement `Core.UnformedInit`, as one with a
    `Core.Buf` field must not: the toolchain accepts the impl, but its unformed
    object's destroy reads that flag. Closes when a variable's destroy runs
    only once it is formed, as for `Core.Buf` (W-115).
-   **W-195: a checked generic's `==` on a compile-time-only type aborts
    lowering.** `Core.Optional(Core.IntLiteral)` values compare through the
    generic impl, which lowers `Core.IntLiteral`'s compile-time-only `==` as a
    run-time call; `Eq2(1, 2)` for `fn Eq2[T: Core.Eq](a: T, b: T)` aborts the
    same way. Closes when such a call is evaluated at compile time or
    diagnosed.
-   **W-049: comparing `Core.Optional(T)` for an imported C++ class `T` fails
    to check.** See [C++ interoperability](#c-interoperability). Filed by the
    C++ export work. Closes when the toolchain can name the `Core` package
    from C++.
-   **Assignment does not destroy the overwritten value** (filed by the strings
    workstream). Closes with assignment that destroys the old value.
-   **A class that declares its own `Destroy` does not destroy its fields**
    (W-197), so an Optional field of such a class keeps its value. Closes when
    such a class's fields are destroyed after its `Destroy` runs.

One divergence is disclosed rather than filed: in 0.1 a comparison of two
non-empty values runs `T`'s `Copy` and `Destroy` once per value
([Comparison](#comparison)). It closes when `Core.Optional` becomes matchable
(W-177) or gains a by-reference accessor.

## Alternatives considered

-   **Comparison between different payload types** (C++'s
    `optional<T> == optional<U>`). The conditional-conformance example compares
    containers with the same element type, Rust's `Option` agrees, and a
    second, overlapping `final` blanket impl would interact with every other
    `EqWith` blanket's specialization rules for no requirement.
-   **Comparison with a bare value or with `Cpp.nullptr`** (C++'s `opt == v`
    and `opt == std::nullopt`). `EqWith` is selected without implicit
    conversions, with `like` as the mechanism; two impls per direction per
    operand type would also make `Optional(Optional(T)) == Optional(T)`
    ambiguous between nesting levels.
-   **A comparison member in `OptionalStorage`, or a builtin.** It avoids the
    copies of `Get()`, but needs pointer equality for the niche (W-174) and
    changes the private interface that every storage implements, for no 0.1
    benefit.
-   **Rebuilding `Optional` as a `choice` now.** The pointer ABI, the `Try`
    signature, the names the `for` desugaring calls and the C++ mapping's name
    all constrain it, and comparison does not need it (W-177).
-   **A `Destroy` declared on `Optional(T)` itself.** It makes every Optional
    nontrivially destructible, the pointer niche included, so a
    `Core.Optional(T*)` union field stops compiling; the default storage's
    `Destroy`, reached because an adapter is destroyed as its adapted type, does
    not reach the niche.
-   **Amending TY4 to name `Get()`'s precondition instead of checking it.**
    That would describe a hole rather than close it; the check costs nothing in
    a `for` loop, whose own `HasValue()` test makes it dead after optimization.
-   **The dated note above the placeholder TODO as a multi-line comment.** Every
    debug-info and diagnostic line number below it moves, which moves goldens
    that never compare an Optional.
-   **Non-`final` comparison impls.** A payload's library could then silently
    redefine `==` on its Optionals even when the payload is `Core.Eq`.
-   **`NotEqual` by the interface default, `not Equal`.** Every prelude
    same-type comparison defines `NotEqual` itself, and C++ uses the contained
    type's `!=`; for a `T` whose `!=` is not the negation of its `==`, the
    default would disagree with that rule.
-   **A pointer `==` in this design.** It is its own design (W-174), and is not
    needed for comparison.

## References

-   Proposal
    [p006357: C++ Interop: Mapping pointer types](/proposals/p006357-c-interop-mapping-pointer-types.md):
    the nullable pointer mapping, the null-pointer ABI constraint, and an
    Optional design as future work
-   Proposal
    [p001885: `for` statement and user types](/proposals/p001885-for-statement-and-user-types.md)
    and [Loops](control_flow/loops.md#ranged-for-for-user-defined-types)
-   [Comparison operators](expressions/comparison_operators.md)
-   [Generics: conditional conformance](generics/details.md#conditional-conformance),
    [`final` impl declarations](generics/details.md#final-impl-declarations) and
    [specialization](generics/details.md#specialization)
-   [Sum types](sum_types.md)
-   [Error handling](error_handling.md), decision D9
-   [Milestones](/docs/project/milestones.md): "Optional", under "Types with
    important language support"
-   Proposal
    [p002188: Pattern matching syntax and semantics](/proposals/p002188-pattern-matching-syntax-and-semantics.md)
-   Proposal [p001154: Destructors](/proposals/p001154-destructors.md) and
    [Classes: destructors](classes.md#destructors)
-   Proposal
    [p005337: Interface extension and `final impl` update](/proposals/p005337-interface-extension-and-final-impl-update.md)
-   [Unions](unions.md#trivially-destructible-and-trivially-copyable-types)
-   Fork: [fork/optional/plan.md](/fork/optional/plan.md) (decisions
    D-OP-1..15), [fork/optional2/plan.md](/fork/optional2/plan.md) (decisions
    D-OP2-1..16), [fork/decision-log.md](/fork/decision-log.md) (F-015, F-016)
