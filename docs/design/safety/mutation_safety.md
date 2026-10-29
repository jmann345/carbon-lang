# Mutation safety

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Definition](#definition)
-   [Rules](#rules)
    -   [M1: The pointer lattice from the pointer's side](#m1-the-pointer-lattice-from-the-pointers-side)
    -   [M2: Exclusive-XOR-shared per place](#m2-exclusive-xor-shared-per-place)
    -   [M3: The no-invalidation rule](#m3-the-no-invalidation-rule)
    -   [M4: Method classification by receiver](#m4-method-classification-by-receiver)
    -   [M5: Payload bindings through `match`](#m5-payload-bindings-through-match)
    -   [M6: `Core.Guarded(T)` for observer idioms](#m6-coreguardedt-for-observer-idioms)
    -   [M7: Data races](#m7-data-races)
    -   [M8: Value bindings](#m8-value-bindings)
-   [`Core.Plain`](#coreplain)
-   [`Core.Guarded(T)`](#coreguardedt)
-   [Data races and the facets](#data-races-and-the-facets)
-   [Value bindings](#value-bindings)
-   [Diagnostics](#diagnostics)
-   [Worked examples](#worked-examples)
    -   [EX-M-1: Aliased non-invalidating mutation](#ex-m-1-aliased-non-invalidating-mutation)
    -   [EX-M-2: The opt-in dynamic cell](#ex-m-2-the-opt-in-dynamic-cell)
    -   [EX-M-3: Facets at the thread boundary](#ex-m-3-facets-at-the-thread-boundary)
    -   [EX-M-4a: A value binding that copies](#ex-m-4a-a-value-binding-that-copies)
    -   [EX-M-4b: A value binding that borrows](#ex-m-4b-a-value-binding-that-borrows)
    -   [EX-M-4c: A `Plain` write to a borrowed object](#ex-m-4c-a-plain-write-to-a-borrowed-object)
    -   [EX-M-4d: A borrowed object through a shared pointer](#ex-m-4d-a-borrowed-object-through-a-shared-pointer)
    -   [EX-M-5: Payload bindings through a shared path](#ex-m-5-payload-bindings-through-a-shared-path)
    -   [EX-M-6: The alternative cannot change through another alias](#ex-m-6-the-alternative-cannot-change-through-another-alias)
-   [C++ interop consequence](#c-interop-consequence)
-   [Implementation staging](#implementation-staging)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [External facts](#external-facts)
-   [References](#references)

<!-- tocstop -->

## Overview

[Mutation safety] is the property that a mutation of an object never invalidates
a live access path to that object or its sub-objects. In Carbon it is a static
property, enforced through the pointer kinds and the binding conventions: the
[memory safety model](README.md#memory-safety-model) assigns it to compile-time
enforcement, and this page states the discipline. A place is under either one
exclusive access path or any number of shared ones; through a shared path only
operations that cannot invalidate are permitted, and which operations those are
is decided by one facet, `Core.Plain`; the methods of a class are classified by
their receiver into the ones that may invalidate and the ones that may not; a
`match` on a sum pins the alternative while a payload binding lives; every `ref`
binding is exclusive access, or a frozen read for a `const` type; and a value
binding of a type whose value representation is not a copy binds a borrowed
object that no path mutates while it lives (realigned 2026-10-28, SAFE-2: W-347,
W-348; the superseded 2026-10-12 text read: "a `match` on a sum through a shared
path pins the alternative while a payload reference lives; and a value binding
of a non-`Plain` type is itself a shared access path"). The one run-time
mechanism is opt-in and local, `Core.Guarded(T)`. [Data-race safety] is mutation
safety's cross-thread companion, enforced by the same facets, not a sub-case of
it, and its rules are on this page too. The [safety strategy](README.md) states
the [soundness model](README.md#soundness-model) these rules are checked under
and the [safety modes](README.md#safety-modes) that decide where the `unsafe`
keyword is required; the [temporal safety](temporal_safety.md) page defines the
three pointer kinds, loans, the loan rules T1 to T8 and the _unverified_ loan
set ⊥ that this page uses, and the rule T4 there and the rule M2 here are one
rule seen from two sides.

[mutation safety]: /docs/design/safety/terminology.md#mutation-safety
[data-race safety]: /docs/design/safety/terminology.md#data-race-safety

This page was fixed by fork decision [F-013](/fork/decision-log.md),
sub-decisions D-SAFE-9, D-SAFE-16, D-SAFE-17 and D-SAFE-20, synthesized in
[fork/safe/plan.md](/fork/safe/plan.md); the taxonomy entry is D-SAFE-1 on the
strategy page and the pointer kinds are D-SAFE-7 and D-SAFE-8 on the temporal
page. No part of this page is implemented in the toolchain (fork workstream
SAFE-1, stage 0); see [Implementation staging](#implementation-staging). What
the toolchain does today is this. `T*` is the one pointer kind and nothing is
checked through it; the tokens `exclusive` and `addr` do not exist (`addr self`
appears in one historic source line of an unbuilt example,
third_party/examples/re2/re2.carbon :769, and in comments); `Core.Plain`,
`Core.Guarded`, `Core.Send`, `Core.Sync` and `Core.Freeze` do not exist, nor do
`Core.Atomic`, `Core.Box` and `Core.Thread` — `Core.Atomic(T)` is the stage-5
Carbon signature over `Cpp.std.atomic(T)` filed under W-149, since fork decision
F-008 rejected a native atomic for 0.1, and the other two are D-SAFE-20 library
residue; and `Core.Optional` is a class with an `adapt` rather than a choice
type, so no `match` on it parses (core/prelude/types/optional.carbon:30-46,
:64-68). The examples on this page in today's syntax, EX-M-4a, EX-M-4c and the
functions `Peek`, `Peek2` and `Peek4` of EX-M-4d, were compiled and run on the
2026.10.12 nightly toolchain and their outcomes are stated with them (EX-M-4c
and EX-M-4d added 2026-10-28, SAFE-2: W-348). File and line citations are
against trunk 0bdce60a5 unless a citation says otherwise. Rules M1, M2, M3, M4,
M5 and M8, and the sections they cite, were realigned 2026-10-28 by fork
workstream SAFE-2 to proposal p005434's rules for `ref` bindings and borrowed
objects (W-347, W-348, W-349; fork/safe/safe2-plan.md); each realigned passage
quotes the text it supersedes.

## Definition

A mutation of an object never invalidates a live access path to that object or
its sub-objects. Iterator and reference invalidation, and a change of a sum
type's alternative under a payload reference, are the mutation safety bugs.
This is an access property in the terminology page's sense, on the same footing
as temporal and spatial safety, and it is enforced by an aliasing discipline:
exclusive-XOR-shared access per place (M2) plus the no-invalidation rule (M3).
It is not a mechanism, and it is not "no shared mutation": shared mutation of
`Plain` state through any number of aliases is exactly what the discipline
permits, which is the shared-mutability direction the
[safety strategy](README.md) committed to (proposal p005914) made checkable.
The one exception is upstream's: an object in an active value binding whose
value representation is not a copy is a borrowed object, which no path mutates
while the binding lives (M8; realigned 2026-10-28, SAFE-2: W-348).

Data-race safety, that memory writes are synchronized with reads or writes on
other threads, is the cross-thread companion of this property, enforced by the
same facets (M7), and not a sub-case of it: two threads writing one `Plain`
`i32` race without invalidating anything. The strategy's
[data races versus unsynchronized temporal safety](README.md#data-races-versus-unsynchronized-temporal-safety)
section permits a design that prevents no races that are not also temporal
bugs; this design prevents all races between Carbon-spawned threads, which
that section also permits.

## Rules

### M1: The pointer lattice from the pointer's side

There are three pointer kinds, defined on the temporal page and summarized in
the strategy's [pointer kinds at a glance](README.md#pointer-kinds-at-a-glance)
(D-SAFE-7). Stated from the pointer's side, as what each kind lets its holder
do to the pointee:

| Kind | Spelling | May do through it | May not do through it |
| --- | --- | --- | --- |
| exclusive-mutable | `exclusive T*` (NEW) | everything: read, write any field, call any method, invalidate (M3's operations) | hold it while any other access path to the place is live (M2) |
| shared-mutable | `T*` | read; write `Plain` fields; call `addr` and `const` methods; form further shared loans | any invalidating operation (M3): `StrictInvalidatingThroughShared` |
| shared-const | `const T*` | read; call `const` methods | write anything; the `const` is API subsetting ([`const`-qualified types](../values.md#const-qualified-types)), nothing more |

Through `T*` and `const T*`, the rows' `const` method calls and reads meet M8
when they bind a borrowed object, a by-value `self`, a `ref self: const Self`
or a value binding of a type whose value representation is not a copy: on a
closed place, or on an open one for a `Core.SharedImmutable` type, and with
`unsafe` otherwise (`StrictBorrowFromShared`, or `StrictRefFromShared` for
`ref self: const Self`; M4); and the `T*` row's `Plain` writes exclude every
assignment whose type holds a `Core.SharedImmutable` sub-object, which only an
exclusive path makes (M3) (amended 2026-10-28, document-review fold: R1-M3).

`&x` on a place under exclusive access, an owner, a `ref` binding or `*p` for
`p: exclusive T*`, yields `exclusive T*`; it converts implicitly to `T*`, a
downgrade under which the loan becomes shared and the exclusive carrier is
suspended until every derived loan is dead (the temporal page's reborrow clause
of T2), and to `const T*`; `T*` converts implicitly to `const T*`; and nothing
converts upward except `unsafe as` ([type safety](type_safety.md)). `T*` is the
shared-mutable kind, not the exclusive one, because the C++ `T&` to `T*` mapping
and the prelude's own `ptr: T*` fields of `Core.Slice` and `Core.Buf`
(core/prelude/types/slice.carbon:58, buf.carbon:62) are shared views of one
block; the explicit `exclusive` kind is what the strategy's "exclusive mutable
pointers" (proposal p005914) names. Every `ref` binding is exclusive access to
its referent, or a frozen read for a `const` type, whatever its source
(D-SAFE-8): formed from a place, or through a pointer to a closed place, it is a
checked reborrow, and formed through a shared pointer to an open place it is the
`unsafe` formation of the temporal page's
[`ref` bindings](temporal_safety.md#ref-bindings), so no shared-kind `ref`
exists (realigned 2026-10-28, SAFE-2: W-347; the superseded 2026-10-12 text
read: "A `ref` binding inherits the kind of its source (D-SAFE-8): a `ref`
formed from a place is exclusive access, a `ref` formed from `*p` has `p`'s
kind, and so the rules of this page apply to a shared-kind `ref` exactly as to a
`T*`."). A built-in operator's `ref` operand, an assignment's among them, lives
for the one operation and is established on any place, M3 deciding what the
operation may do (amended 2026-10-29, re-review round 2: RR1-M1).

### M2: Exclusive-XOR-shared per place

At every program point a place is under at most one exclusive loan or under any
number of shared and frozen loans, never both. This is the temporal page's
conflict rule T4 read as a mutation rule: a live exclusive loan excludes every
other access to overlapping places, except through the suspended carrier at the
kind the reborrow clause allows; a live shared loan excludes exclusive loans and
the invalidating operations of M3, and an invalidating operation on a place
kills every interior loan on it; and a live frozen loan, the loan of a borrowed
object (M8) or of a `const` `ref`, excludes besides every other write to the
place's storage, `Plain` writes and `addr` calls included. Liveness is
non-lexical (T3): a loan is live from its creation to the last use of any
carrier, so a shared pointer that is never used again does not block an
invalidating operation on the next line, which is what makes EX-M-1 read as it
does. For a call result or reference expression whose loan set mixes kinds,
the weakest kind governs every place in the set (D-SAFE-8; realigned 2026-10-28,
SAFE-2: W-347, W-348; the superseded 2026-10-12 text read: "At every program
point a place is under at most one exclusive loan or under any number of shared
loans, never both." and "For a carrier whose loan set mixes kinds, the weakest
kind governs every place in the set (D-SAFE-8).").

### M3: The no-invalidation rule

An operation on a place `P` is _invalidating_ if it can end the lifetime of
any object reachable from `P` or change which sub-objects exist at an address
(D-SAFE-9). The invalidating operations are exactly:

-   (a) destruction of `P` or of a sub-object of `P`;
-   (b) `~P`, the move out of `P`
    ([initialization safety](initialization_safety.md), I4);
-   (c) assignment to `P` or to a sub-object of `P`, unless the assigned type
    is `Core.Plain`;
-   (d) a call whose receiver is exclusive, `ref self: Self`;
-   (e) forming an exclusive loan on `P`.

Invalidating operations require exclusive access: they are forbidden through
`T*` and `const T*` (`StrictInvalidatingThroughShared`) and forbidden on the
owner while any shared loan on the place is live
(`StrictSharedBorrowInvalidated`, the temporal page's diagnostic, because the
conflict is a loan conflict). Everything else, reads, overwriting `Plain`
fields, `addr` and `const` methods, is permitted through any number of aliases
at once, but for the assignments of a type that holds a `Core.SharedImmutable`
sub-object, which the next paragraph names (realigned 2026-10-28, SAFE-2: W-348;
this sentence ended "is permitted through any number of aliases at once."). A
`const` method call through `T*` or `const T*` whose `self` binds a borrowed
object or is a `ref self: const Self`, and a read of the pointee into a value
binding of a borrowed object, need besides a closed place, a
`Core.SharedImmutable` type, or `unsafe`, M8 governing the borrowed object and
the temporal page's [`ref` bindings](temporal_safety.md#ref-bindings) the
`const` `ref` (amended 2026-10-28, document-review fold: R1-M3; amended
2026-10-29, re-review round 2: RR1-M2, where this read "and a read of the
pointee into a value binding, meet M8 besides when they bind a borrowed
object: a closed place, a `Core.SharedImmutable` type, or `unsafe`"). The
rule is the strategy's fourth mutation commitment made checkable: iterators hold
`T*`, `Push` is `ref self`, and the C++ notion of "iterator invalidation" is
captured by the methods that require exclusive access, which preclude any
outstanding shared mutable pointers (proposal p005914). Which assignments are
invalidating is decided by one facet, [`Core.Plain`](#coreplain), defined
structurally below so that (c) says exactly what (a) and the sub-object clause
require. An operator that passes its operand to a `ref` parameter, an
assignment among them (the [assignment](../assignment.md#syntax) design's "a
`(ref self: Self)` parameter"), is not a call in (d)'s sense when its
implementation is built in, as the temporal page's
[`ref` bindings](temporal_safety.md#ref-bindings) define it, the language's own,
`&`, member access naming a field, indexing of an array or the toolchain's
interim `=` on a type with no `AssignWith` impl, or an impl of an operator
interface written in core/prelude whose body, while its `ref` operand is bound,
calls no impl written outside core/prelude, whichever type it is for, the
`CppCompat` integers' as much as `Int`'s, a user's type that fills their `U`
being converted to `Self` before the `ref` is bound; the interim `=`
(toolchain/check/handle_operator.cpp:99-123), where the assignment design
rewrites `x = y;` to `x.(AssignWith(U).Op)(y);` (assignment.md:184), counts as
the language's own on an array or a class that is not a data class by this
design's classification and not by the assignment design's "Tuples, structs,
choice types, and data classes" (assignment.md:159), and any user-written `Copy`
or `ImplicitAs` it runs is checked under this rule on every path it takes; and
this rule counts every assignment operator, compound assignment included, and
`++` and `--` as an assignment to the first operand, in (c) and in the next
paragraph: that section establishes its operand for the one operation, the
operand's `ref` forms no loan of its own, neither (d)'s call nor (e)'s exclusive
loan, and (a) to (c) and the next paragraph decide what it may do through a
shared path, while the call of a user-written impl's `ref self`, an impl written
outside core/prelude or a prelude impl that calls one while its `ref` operand is
bound, assignment.md:302-316's default `*self = *self $ other;` for a user's
class among them, is (d)'s (amended 2026-10-28, document-review fold: R1-M1;
amended 2026-10-29, re-review round 2: RR1-m1, where this read "the language's
own or a prelude impl whose body is a builtin: the temporal page's [`ref`
bindings](temporal_safety.md#ref-bindings) establish its operand for the one
operation, and (a) to (c)"; amended 2026-10-29, re-review round 3: RR2-M1,
RR2-m1, where this read "the semantics the assignment design gives a built-in
type with the prelude's impls of them whatever their body, an assignment of a
tuple, struct, array, choice type or class with no user-written `AssignWith`
impl, `&`, member access naming a field or indexing of an array" and "while the
call of a user-written impl's `ref self` is (d)'s").

One more class of write needs exclusive access although it invalidates
nothing: a write of storage that holds a `Core.SharedImmutable` object
([Value bindings](#value-bindings)). A type _holds a `Core.SharedImmutable`
sub-object_ when it is `Core.SharedImmutable`, or is an array, tuple, struct or
class with an element, a field or a base that holds one, or an adapter of a
type that holds one, a closure like `Core.Plain`'s below: `Core.String`,
`Core.Slice(T)` for a `Core.Freeze` `T`, `{.s: str, .n: i32}` and a class with
a `str` field all hold one. An assignment whose assigned type holds one, a
whole-object or a field
assignment and a `Plain` one included, through `T*`, through `addr self`, or to
an open place such as a global
([temporal safety: vocabulary](temporal_safety.md#vocabulary)), is
`StrictSharedImmutableWrite`, a non-`Plain` one staying
`StrictInvalidatingThroughShared`; through an exclusive path, the owner of a
closed place, a `ref` or an `exclusive T*`, it is permitted while no frozen
loan on an overlapping place is live and is `StrictBorrowedObjectMutated`
while one is. A union is outside the closure: reading its field is `unsafe` in
Strict ([unions](../unions.md#strict-carbon-and-future-safety-hooks)), so a
binding of a union's field is formed under that marker, whose obligation then
includes that no path writes the union while the binding's loan is live, a
`bound` parameter's as long as the call's result that keeps it (the temporal
page's T5(d); amended 2026-10-29, re-review round 2: RR1-B1, where this read
"while the binding lives"). This is the
language half of the facet's promise that no path but an exclusive one writes
the type's storage, which a frozen loan on an open place relies on, and an
assignment of an enclosing object writes that storage too. `Core.String`, and
`Core.Slice(T)` for a `Core.Freeze` `T`, are `Plain` and opt in, so
`*q = "longer"` through a `str*` and `*q = {.s = "longer", .n = 1}` through a
`{.s: str, .n: i32}*` are rejected in Strict (EX-M-4d's `Peek2` and `Peek4`),
and `s = "def"` through the owner under a live `const Core.String*` stays
accepted (the temporal page's EX-TM-3). A trusted body keeps this rule too,
writing such an object only through an exclusive path or through storage
owned by an object it holds exclusively, which is why `Core.Buf(T).Set` takes
`ref self` ([Value bindings](#value-bindings); EX-M-4d's `Peek8`). The
`unsafe` prefix on the write, `unsafe (*q = "longer")`, takes on the
obligation that no binding of the object is live (added 2026-10-28, SAFE-2:
W-348).

The escape is the uniform `unsafe` prefix of the strategy's
[operation-tied `unsafe`](README.md#operation-tied-unsafe) on the invalidating
operation itself: `unsafe p->Push(3)` for an exclusive method reached through
a shared pointer, `unsafe (*p = Core.Buf(i32).Make(2, 0))` for a non-`Plain`
assignment through one. Its stated obligation is that no live access path
reaches the storage the operation invalidates. The form is listed on the
strategy page under
[operation-tied `unsafe`](README.md#operation-tied-unsafe) beside the
`unsafe fn` call it resembles (amended 2026-10-12, document-review fold: D-9).
The alternative to the obligation is `Core.Guarded(T)` (M6), which checks it
at run time.

### M4: Method classification by receiver

A method's receiver form states which side of M3 its body is on, and the body
is checked against that statement:

-   `ref self: Self` is exclusive access. The body may do anything to `self`,
    including the invalidating operations, and a call of the method is itself
    invalidating (M3(d)): it needs an exclusive path to the object, an owner,
    a `ref`, or an `exclusive T*`, and no live shared loan on it.
-   `addr self: Self*` is shared-mutable access, the receiver form restored
    for exactly the purpose proposal p005434 reserved `addr` for, "one of the
    pointer semantics" of the memory safety design. The body is checked under
    M3: it may assign `Plain` fields (`i32`, the pointer kinds), but a field
    whose type holds a `Core.SharedImmutable` sub-object, a `Core.Slice(T)` for
    a `Core.Freeze` `T`, the prelude's non-owning `Core.String` or a struct
    holding one, and `*self` when `Self` holds one, only as M3 allows such a
    write, so a setter of a `Core.String` field takes `ref self` (realigned
    2026-10-28, SAFE-2: W-348; this clause read "it may assign `Plain` fields
    (`i32`, the pointer kinds, `Core.Slice`, the prelude's non-owning
    `Core.String`),"), call `addr` and `const` methods
    on `self` and read anything, a `const` call whose `self` binds a borrowed
    object or is a `ref self: const Self`, or a read into a value binding of a
    borrowed object, meeting M8 or the temporal page's `ref` bindings as the
    next bullet says, `*self` being an open place (amended 2026-10-28,
    document-review fold: R1-M3; amended 2026-10-29, re-review round 2:
    RR1-M2, where this read "a `const` call or a read into a value binding
    that binds a borrowed object meeting M8 as the next bullet says"); it
    may not assign a `Core.Buf`, `Core.Box`,
    `Core.Optional` or payload-`choice` field, call an exclusive method on
    `self`, move out of `self` or destroy it. A call of an `addr` method is
    not invalidating and is permitted through `T*`.
-   `ref self: const Self` and by-value `self` are const access: the body
    mutates nothing in `self`. A call binds `self`, a frozen `ref` or a value
    binding that borrows the object when its value representation is not a
    copy, so through an owner, a `ref` or an `exclusive T*` it is permitted,
    and through `T*` or `const T*` it needs a closed place or a
    `Core.SharedImmutable` type, else `StrictBorrowFromShared`, or
    `StrictRefFromShared` for `ref self: const Self` (M8; realigned 2026-10-28,
    SAFE-2: W-347, W-348; the superseded 2026-10-12 text read: "the body
    mutates nothing in `self`, and a call is permitted through every kind.").

Interior mutability, a type that mutates through a const or shared path, is that
type's private Permissive business: `Core.Atomic(T)` over `Cpp.std.atomic(T)` is
the model — a stage-5 Carbon signature over the imported C++ type (W-149), not
a native atomic, which fork decision F-008 rejected for 0.1; 0.1 obtains
atomicity exclusively by way of imported C++ types
([fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md))
—
its body is trusted under the soundness model (S0), and such a type is not
`Core.Freeze`, which is what keeps M7's facet rules sound over it.

### M5: Payload bindings through `match`

A `match` binds a payload by `ref` or by value, under the rules of `ref`
bindings and value bindings. Through a path to a closed place, an owner, a
`ref` or an `exclusive T*`, a `ref` payload is an exclusive sub-loan on the
scrutinee and a value payload that borrows is a frozen one; through a shared
path to an open place a `ref` payload is `StrictRefFromShared` unless it is
marked `unsafe`, and a value payload that borrows is formed only when the
payload's type is `Core.SharedImmutable` (M8). Under any of these sub-loans the
alternative of the sum cannot change while the payload binding lives, and this
is a consequence of M3(c) rather than a separate rule: a payload `choice`, and
`Core.Optional(T)` for every `T`, is non-`Plain`, so assigning a new
alternative to the scrutinee through any shared alias is
`StrictInvalidatingThroughShared`, and assigning it through the owner while the
sub-loan is live is `StrictSharedBorrowInvalidated` (T4). The change of a sum
type's alternative under a payload binding is the second mutation safety bug of
the [definition](#definition); EX-M-5 and EX-M-6 are its two shapes (realigned
2026-10-28, SAFE-2: W-347; the heading read "M5: Payload references through
`match`", and the superseded 2026-10-12 text read: "A `match` through an
exclusive path binds `ref` payloads as exclusive sub-loans on the scrutinee; a
`match` through a shared path binds them as shared sub-loans. Under a shared
sub-loan the alternative of the sum cannot change while the payload reference
lives, and this is a consequence of M3(c) rather than a separate rule: a
payload `choice`, and `Core.Optional(T)` for every `T`, is non-`Plain`, so
assigning a new alternative to the scrutinee through any shared alias is
`StrictInvalidatingThroughShared`, and assigning it through the owner while the
sub-loan is live is `StrictSharedBorrowInvalidated` (T4). The change of a sum
type's alternative under a payload reference is the second mutation safety bug
of the [definition](#definition); EX-M-5 and EX-M-6 are its two shapes."; the
quote amended 2026-10-28, document-review fold: R2-m2, where it stopped at
"while the payload reference lives").

### M6: `Core.Guarded(T)` for observer idioms

The one opt-in run-time exclusivity check is `Core.Guarded(T)` (D-SAFE-20):
a cell holding a `T` and a busy flag, whose `Modify[addr self: Self*](f)`
gives `f` a `ref` to the value for the duration of the call and fails-stop on
re-entry. It is the sanctioned spelling for the observer and back-pointer
idioms that M3 rejects through `T*`: a shared pointer to a `Guarded(Buf(T))`
may call `Modify` and push, where a shared pointer to a `Buf(T)` may not push.
It is a library type with no builtin, is neither `Send` nor `Sync` nor
`Freeze`, and its sketch is under [`Core.Guarded(T)`](#coreguardedt).

### M7: Data races

Strict Carbon has no data races between Carbon-spawned threads (D-SAFE-16).
Three compiler-determined facets, `Core.Send`, `Core.Sync` and `Core.Freeze`,
each defined structurally under
[Data races and the facets](#data-races-and-the-facets), are enforced as generic
constraints at the thread-crossing APIs, and every such API either accepts only
a free loan set or joins inside the borrow, the _thread-boundary lifetime rule_.
The guarantee is stated on this page as a consequence of the pointer kinds plus
that rule once the thread API's lifetime contract is fixed at stage 5; before
stage 5 the 0.1 Permissive contract, that a race is undefined behavior as in
C++, is untouched
([fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md)),
and it continues to describe Permissive code and C++ threads afterwards.

### M8: Value bindings

A value binding of a type whose value representation is a copy holds no loan,
so mutation of the source afterwards is accepted in every mode. A value binding
of any other type binds a borrowed object (proposal p005434) and holds a frozen
loan on it for the binding's non-lexical lifetime, under which every write to
the object's storage through any path is rejected in Strict: an invalidating one
with `StrictSharedBorrowInvalidated`, any other with
`StrictBorrowedObjectMutated`. The loan is formed on a closed place, or on an
open place when the type is `Core.SharedImmutable`, and the binding is
`StrictBorrowFromShared` otherwise. A value binding from a materialized
temporary owns that storage and holds no loan on it. The rule is D-SAFE-17,
stated in full with its memory-safety argument under
[Value bindings](#value-bindings) (realigned 2026-10-28, SAFE-2: W-348; the
superseded 2026-10-12 text read: "A value binding of a `Plain` type copies
eagerly and holds no loan, so mutation of the source afterwards is accepted in
every mode. A value binding of a non-`Plain` type, from `*p` or from an owner,
is a shared loan on the bound object for the binding's non-lexical lifetime,
under which an invalidating operation on the bound object is
`StrictSharedBorrowInvalidated` and a `Plain`-field write through another alias
is erroneous and Debug-reported as `MutationDuringValueBinding`.").

## `Core.Plain`

`Core.Plain` is a compiler-determined facet in the pattern of `Concrete` and
`TrivialDestructor` ([classes: destructors](../classes.md#destructors);
[generics: destructor constraints](../generics/details.md#destructor-constraints)):
it cannot be implemented by hand, and the compiler decides it from the type's
definition. It is defined structurally so that M3(c), "assignment is
invalidating unless the assigned type is `Plain`", matches the definition of
invalidation exactly. A type is `Plain` when:

-   (i) it is `Copy` with trivial destruction: no user destructor in either
    spelling, the `fn destroy(self)` and `fn destroy(ref self)` forms of the
    classes design or the prelude's `impl as Destroy { fn Op(ref self) }`
    form (core/prelude/types/buf.carbon:58-60). The fork's prelude uses the
    interface form, which the classes design does not name; this sentence,
    dated 2026-10-12, is the disclosure (F-013 D-SAFE-9).
-   (ii) every sub-object exists and is formed at a fixed offset regardless of
    the value.

The facet is closed under arrays, tuples, structs and classes whose every field
is `Plain`. Membership of the types this design names:

| Type | `Plain` | Why |
| --- | --- | --- |
| Integers, floats, `bool`, `char` | yes | scalars: (i) and (ii) trivially |
| `T*`, `exclusive T*`, `const T*` | yes | one word; a pointer is a value, and what it points to is the loan rules' business, not this facet's |
| `Core.Slice(T)` | yes | a non-owning `{T*, i64}` view (slice.carbon:24-77); its loan is carried, not owned |
| `Core.String` | yes | the prelude's `str`: a non-owning `{Char*, i64}` with `impl as Copy`, no `Destroy`, and `impl String as UnformedInit` (core/prelude/types/string.carbon:16-28); the design overview's `Core.Str` is the same type under the interop design's name |
| `array(T, N)`, tuples, structs, classes of `Plain` fields | yes | closure |
| `Core.Buf(T)` | no | owns a heap block, `impl as Destroy` frees it (buf.carbon:58-60) |
| `Core.Box(T)` | no | owns its pointee (D-SAFE-20) |
| A `choice` with a payload | no | which payload sub-object exists depends on the value |
| `Core.Optional(T)`, for every `T` | no | a class over `MaybeUnformed` or null-niche storage whose payload sub-object exists only for `Some` (optional.carbon:13-60, :186-203); `DefaultOptionalStorage(T)` is `{MaybeUnformed(T), bool}` (:140-143) and the pointer storage is one `MaybeUnformed(T*)` word (:188-189), so the offsets are fixed and what varies is formedness, which (ii) names |
| `MaybeUnformed(T)` | no | formedness varies by the value, (ii) |
| A union with a pointer-carrying field | no | [unions: field rules](../unions.md#field-rules-in-01) admit `T*` fields, and a pointer read from a union is unverified ([temporal safety](temporal_safety.md), T6) |

Two consequences the table fixes. `Optional(T*)` is not `Plain`, so `*d =
Core.Optional(i32*).None()` through a shared `Optional(i32*)*` is
`StrictInvalidatingThroughShared` (EX-M-6), and a linked structure whose head is
an `Optional(Node*)` field is written only through exclusive access; the break
condition of D-SAFE-9 counts that cost. `Core.String` is `Plain`, so `s = "def"`
under a live `const Core.String*` is accepted in every mode (the temporal page's
EX-TM-3), and an owning string, once the prelude has one, will not be. Through a
`T*` the same assignment is `StrictSharedImmutableWrite` in Strict,
`Core.String` being `Core.SharedImmutable`, and so is a `Plain` assignment
through a `T*` of an array, tuple, struct or class that holds a `Core.String` or
a `Core.Slice(T)` for a `Core.Freeze` `T`, which holds a `Core.SharedImmutable`
sub-object as M3 defines it by the same closure as this facet's (M3; added
2026-10-28, SAFE-2: W-348).

## `Core.Guarded(T)`

The sketch below is in NEW syntax: `addr self` does not parse today, nor does
a `ref` parameter of a function value. It is a sketch, not compile-verified,
and it is Permissive-implemented prelude code behind a Strict signature like
the rest of the prelude (S0): the body writes through `addr self` what a Strict
body could not, and that is the one place where the busy flag's invariant is
trusted rather than checked.

```carbon
// Core.Guarded(T) — sketch, not compile-verified (NEW: `addr self`, `ref` parameter)
class Guarded(T: type) {
  fn Make(value: T) -> Self;
  // Gives `f` exclusive access to the value for the call; re-entry fails-stop.
  fn Modify[addr self: Self*](f: fn (ref v: T)) {
    if (self->busy) { FailStop("carbon: Core.Guarded re-entered; terminating\n"); }
    self->busy = true;        // Plain field: a shared write
    f(self->value);           // trusted: the flag proves no other `ref` is live
    self->busy = false;
  }
  private var busy: bool;
  private var value: T;
}
```

`Modify` is an `addr` method, so it is callable through any number of `T*`
aliases (M4), and the flag is what makes that sound: the second `Modify` on
the same cell while one is active, the re-entrant observer, fails-stop with
"carbon: Core.Guarded re-entered; terminating" rather than handing out a
second `ref`. The cell is not `Send`, not `Sync` and not `Freeze`
(D-SAFE-16): the flag is not atomic and the design does not pretend it is.
It is a library item under residue W-144, filed at discharge, with no builtin
behind it.

## Data races and the facets

`Core.Send`, `Core.Sync` and `Core.Freeze` are compiler-determined facets,
each defined structurally (D-SAFE-16). These are the fork's definitions; the
soundness argument behind the pattern is Rust's auto-trait argument, an
[external fact](#external-facts). A type is `Send` when all its fields are,
`Sync` when all its fields are, and `Freeze` when it has no interior
mutability, that is, when no field is `Core.Atomic(T)`, `Core.Guarded(T)` or
another type whose body mutates through a const or shared path; the
exceptions and the base cases are:

| Type or field | `Send` | `Sync` | Note |
| --- | --- | --- | --- |
| Integers, floats, `bool`, `char` | yes | yes | `Freeze` |
| A `T*` field | the type is **not** `Send` | the type is **not** `Sync` | a shared-mutable reference is thread-local, the rule the strategy adopted from Ante ([external fact](#external-facts)) |
| A `Core.Slice(T)` field | the type is **not** `Send` | the type is **not** `Sync` | `Data(self) -> T*` (slice.carbon:37) reaches a `T*` even from `const Slice*`, because `const` is API subsetting only (as.carbon:41-43) |
| `exclusive T*` | iff `T: Send` | iff `T: Sync` | the exclusive kind carries the pointee's facets, as `&mut T` does |
| `const T*` | iff `T: Sync` | iff `T: Sync` | read-only sharing |
| `Core.Atomic(T)` | yes | yes | not `Freeze` |
| `Core.Guarded(T)` | no | no | not `Freeze`; a single-thread cell |
| An imported C++ type | no, unless annotated | no, unless annotated | a class every one of whose data members is `guarded_by` a `capability` member of Clang's Thread Safety Analysis family imports as `Sync` (D-SAFE-18); nothing else does |
| `unsafe impl T as Core.Send {}`, `as Core.Sync {}` | opt in | opt in | the author's obligation, audited by the `unsafe` |

That `T` is `Sync` exactly when `const T*` is `Send` is then a consequence of
the rows, not the rule. `Freeze` is what makes the strategy's
[C++ call allowlist](README.md#c-call-allowlist) shape 2, a `const T&`
parameter of a `Freeze` type, need no marker: no write is possible through it
during the call.

Enforcement is at the thread-crossing APIs, as generic constraints, in the
staged order the strategy names for data-race safety (proposal p005914):
facets first, then `--strict-concurrency=warn`, then `error`. The
thread-boundary lifetime rule completes it: a thread-crossing API accepts only
a free loan set, the empty set that globals and allocator-owned storage have,
or it is a scoped API whose join lies inside the borrow. Concretely,
`Core.Thread.Spawn[T: Core.Send](f: fn (var t: T), t: T)`, the shape EX-M-3
declares, requires `t`'s loan set to be free, else `StrictBorrowOutlivesPlace`
at the spawn, and
`Core.Thread.Scope(fn (ref s: Scope) { s.Spawn(...); })` holds the scope's
loans live until the closing join, so a loan on a local may cross into a
scoped thread and never into a detached one (EX-M-3). With that rule fixed at
stage 5, the two halves of the strategy's data-race section follow: Strict
Carbon has no data races between Carbon-spawned threads, stronger than the
section requires, and the unsynchronized temporal bugs it says Carbon _must_
prevent, a use after free through a thread, cannot occur because the freeing
thread cannot outlive the loan. The break condition is that facet synthesis
cannot see through an imported C++ layout, which the C++ row's default already
covers.

## Value bindings

A value binding (`let x: T = e;`, a by-value parameter, a by-value `self`) is
the binding the [values](../values.md) design describes as acquiring the value
of a referenced object, with the read possibly deferred, and under which "any
mutation to the object or its storage ends the lifetime of the value binding,
and makes any use of the value expression an error". Proposal p005434 names
the object such a binding reads when its value representation is not a copy:
"Mutation of objects with a non-copy-value representation in an active value
binding ("borrowed objects") is erroneous behavior", and "Our plan is to
prevent mutation of borrowed objects in Carbon's strict safe dialect"
(p005434:660-664). D-SAFE-17 is that plan, in four parts:

-   **A copy-represented type holds no loan.** A type's value representation is
    its `value_rep` when it declares one and otherwise the implementation's
    choice
    ([values: value representation and customization](../values.md#value-representation-and-customization)).
    Today's toolchain (upstream toolchain/check/type_completion.cpp at
    0421bf3b4) gives a copy to `bool`, the integer, floating-point and pointer
    types (:697-751) and to a struct or tuple of one element, whose value is a
    one-element aggregate of its element's value representation (:572-578);
    an adapter, `const T` and `MaybeUnformed(T)` of a copy-represented `T`
    other than `bool` take the representation of the type they wrap (:762-770,
    :783-789, :803-826), so `Core.Optional(T*)`, an adapter of
    `MaybeUnformed(T*)`, is copy-represented. It gives a pointer to every
    other class and to every array (:674-695, :771-781), and to every struct or
    tuple of more than one element, a pointer to the object when every
    element's value representation is a copy of its object representation and
    otherwise a pointer to a separate aggregate of the element values
    (:580-582, :597-609). A binding of a copy-represented type read the value
    when it was bound, so there is no borrowed object and mutation of the
    source afterwards is accepted in every mode: `let b: i32 = a; a = 2;
    return b;` is accepted in Strict and returns 1 (EX-M-4a), and the values
    design carries a dated note saying so. When the copy is a one-element
    aggregate, its element's own representation decides: an element whose
    value representation is not a copy is a borrowed object of the binding.
-   **Any other type binds a borrowed object, under a frozen loan.** The
    binding holds a _frozen_ loan on the bound object for its non-lexical
    lifetime (T2): no path writes the object's storage while it lives. A
    `Plain`-field assignment or an `addr` call on the object through any
    alias, the owner included, and passing a writable carrier of it, a
    non-`const` pointer or a value that carries one, to a call, are
    `StrictBorrowedObjectMutated` (EX-M-4c); an invalidating operation, an
    assignment of a non-`Plain` value, a `ref self` call, a move or a destroy,
    is `StrictSharedBorrowInvalidated` as before (T4; EX-M-4b). The object's
    storage is the object and its sub-objects; storage reached through a
    pointer it holds, the elements of a `Core.Buf` among them, is another
    object's, which is why an `i32` element of a borrowed `Buf` may still be
    written through the `T*` that a view's `Data()` returns, element `i`
    through the one-element view `AsSlice().Subslice(i, i + 1)`, and through
    `b[i] = v` once the indexing interface `IndirectIndexWith` lands;
    `Core.Buf(T).Set` itself takes `ref self`, below.
-   **The frozen loan needs a place the checker can see.** On a closed place
    ([temporal safety: vocabulary](temporal_safety.md#vocabulary)), an owner, a
    `ref`, the pointee of an `exclusive T*` or a place every carrier of whose
    loans the body sees, T4 enforces it against every carrier. On an open
    place, `*p` for a `T*` or `const T*` parameter, a pointer loaded from
    memory, a free or ⊥ pointer, an alias the body cannot see could write the
    object, so the loan is formed only when the bound type is
    `Core.SharedImmutable`, below; any other such binding is
    `StrictBorrowFromShared` (EX-M-4d), and its spellings
    `let v: T = unsafe *p;` and `unsafe p->M()` take on the obligation that no
    path mutates the object while the binding's loan is live, which for a
    `bound self` lasts as long as the call's result that keeps it (the temporal
    page's T5(d); amended 2026-10-29, re-review round 2: RR1-B1, where this
    read "while the binding lives"). The other fixes are an
    owner or an `exclusive T*`, `Core.Guarded(T)`, the type's own
    `value_rep = const Self` when it is small and copyable, and a `var` copy of
    a struct or tuple, `var v: T = *p;`, whose `Plain` elements are read and
    whose class elements bind under this same rule.
-   **A materialized temporary owns its storage.** An initializing expression
    is the third source of a value binding, neither `*p` nor an owner; the
    binding takes ownership of the materialized storage, the values design's
    rule for a `var` pattern applied to `let`, and carries no loan on it, so
    `let o: Core.Optional(i32) = Core.Optional(i32).Some(1);` followed by
    `o.HasValue()` on the next line is accepted. The loans carried _by_ the
    value are unaffected, which is why a view of a temporary `Buf` stays
    `StrictBorrowOfTemporary` on the temporal page (EX-TM-7b).

**`Core.SharedImmutable`** is the facet that says no path but an exclusive one
writes a type's storage. The promise has two halves. The language keeps the
first: every assignment through a shared path whose assigned type holds a
`Core.SharedImmutable` sub-object, the type itself or an array, tuple, struct
or class that holds it, a `Plain` one included, is rejected in Strict by M3
(`StrictSharedImmutableWrite`; EX-M-4d's `Peek2` and `Peek4`), and a union's
field binds only under the `unsafe` its read needs. The author keeps the
second, what no check of the language sees: every field is private, no `addr`
method writes `self`, no function writes the type's storage through a shared
path or returns a
non-`const` pointer or `ref` into it, and no pointer into its own storage is
stored in it. It is opt-in only, `unsafe impl T as Core.SharedImmutable {}`, the
author's audited obligation in the pattern of `unsafe impl T as Core.Send {}`,
and it implies `Core.Freeze`, so a generic type opts in only for a `Freeze`
argument. The prelude opts in for `Core.String`, and for `Core.Slice(T)`,
`Core.Buf(T)` and `Core.Optional(T)` under `forall [T: Core.Freeze]`, and for
`Core.Box(T)` the same way once residue item W-144, which holds the opt-ins,
adds `Box`, their bodies
trusted under the [soundness model](README.md#soundness-model), so a by-value
call such as `p->Size()` through a `Core.Buf(i32)*` or a `const Core.String*`
parameter binds a borrowed object the checker can rely on (EX-M-4d; the temporal
page's EX-TM-1). A struct or tuple type has public elements and never opts in.
The trusted bodies keep the language half too: a trusted body writes an object
whose type holds a `Core.SharedImmutable` sub-object only through an exclusive
path, an owner, a `ref` or an `exclusive T*`, or through a pointer into
storage owned by an object it holds exclusively, every other path to that
storage the type hands out being `bound` to that object; so `Core.Buf(T).Set`,
which writes an element of the block, takes `ref self` under W-144, and
EX-M-4d's `Peek8`, which binds an element frozen through a shared
`Core.Buf(str)*` and then calls `Set`, is `StrictInvalidatingThroughShared` at
the call. The `Ref` method of the indexing interface `IndirectIndexWith`, once
the prelude has it, hands out a `ref` into the storage a `Core.Slice` views or
a `Core.Buf` owns, so it takes `bound self` under W-144, at the interface,
since an impl may not add `bound` beyond it
([temporal safety](temporal_safety.md), T5(e)), and in the `Core.Slice` and
`Core.Buf` impls: a binding formed through `b[i]`, such as
`let s: str = b[0];`, then keeps the loan on `b` that `Set`'s `ref self`
conflicts with, and `b.Set(0, "longer")` while `s` lives is
`StrictSharedBorrowInvalidated` (T4), where an unbound `Ref` would leave `s`
frozen on an element reached through a free result and the call accepted.

The memory-safety argument, and what the rule costs. A frozen loan on a closed
place is sound because every carrier of the place is in the body's view and a
carrier of a local cannot escape it (the Store rule and T5(b)); on an open place
of a `Core.SharedImmutable` type, because M3 rejects every Strict assignment
through a shared path that writes the object's storage, whether its type is the
object's or holds it, every trusted body keeps the same rule, the live shared
path excludes the exclusive ones (M2), its carrier holding a loan the writer's
checker sees or, when it is the free result of a marked `unsafe fn` call or a
carrier derived from it, the marker's obligation that, while a frozen loan
formed through the result, or through a carrier derived from it, is live,
whatever carries the loan, a value binding of a borrowed object, a `const`
`ref` or the result of a call that keeps it, no path other than the result and
its copies writes the storage that loan covers (the temporal page's T6;
amended 2026-10-28, document-review fold: R1-M2; amended 2026-10-29, re-review
round 2: RR1-B1, where this read "when it is the free result of a marked
`unsafe fn` call, the marker's obligation that no other path writes the
storage while the binding lives"), and the opt-in's obligation covers what the
checker cannot see. A write by
unchecked code, a Permissive body, C++ or an alias an `unsafe` binding promised
away, is the erroneous behavior proposal p005434 keeps for it (p005434:670-672),
never undefined behavior, because the safe-code optimizer assumes nothing about
it (the temporal page's T8 emits no `noalias` on an open place), and the Debug
build detects it: Debug keeps, in shadow memory keyed by address and never in
the object's layout, a count of live frozen loans for each byte of a borrowed
object's storage, incremented when the binding is formed and decremented at its
last use as the stage-4 checker computes it, and every store that writes a byte
whose count is non-zero, of any type and by any path, through `T*`, through a
`ref`, through the owner, to a global by name or in an `addr self` body, reports
`MutationDuringValueBinding`. The rule rejects in Strict what the rule of
2026-10-12 accepted: a `Plain`-field write during a binding even where it frees
nothing (EX-M-4c), the aliased write of EX-M-1 while a `bound` result lives (the
temporal page's T5(d)), a by-value call or a `let` of a type that does not opt
in, through a shared pointer whose aliases the body cannot see (EX-M-4d's
`Peek`), a `Plain` assignment through a shared pointer, or to a global, of a
`Core.String`, a `Core.Slice(T)` for a `Core.Freeze` `T` or an array, tuple,
struct or class that holds one (EX-M-4d's `Peek2` and `Peek4`), and a
`Core.Buf(T).Set` call through a shared pointer, on a `Buf` bound by value, or
while a view of the block lives (EX-M-4d's `Peek8`; the temporal page's
EX-TM-3). That is the cost proposal p005434 anticipated when it said to "revisit
the underlying idea of mutation being erroneous if enforcing it in the strict
mode proves fundamentally untenable due to ergonomic costs" (p005434:667-669),
and revisiting it is upstream's call. For Rust, a parameter bound this way is
frozen for the call, which is what `&T` promises, and it exports as `&T` when
its type is `Core.Freeze`
([safe-Rust interop](rust_interop.md)).

(Realigned 2026-10-28, SAFE-2: W-348, W-349. The superseded 2026-10-12 section
body read, in full, its list items separated by " / ": "A value binding (`let x:
T = e;`, a by-value parameter, a by-value `self`) is the binding the
[values](../values.md) design describes as acquiring the value of a referenced
object, with the read possibly deferred, and under which any mutation of the
object ends the binding's lifetime and makes a later use erroneous. D-SAFE-17
ratifies that rule into Strict Carbon in three parts, by the type of the
binding:" / "**A `Plain` type acquires eagerly and holds no loan.** The binding
is a copy, which is what the design overview says a parameter binding does when
copying is legal and cheaper ([functions](../README.md#parameters)); there is no
deferred read, so there is no object whose mutation could end the binding. `let
b: i32 = a; a = 2; return b;` is accepted in Strict and returns 1 (EX-M-4a); the
erroneous reading of the values design does not arise, and that design carries a
dated note saying so." / "**A non-`Plain` type, from `*p` or from an owner, is a
shared loan** on the bound object for the binding's non-lexical lifetime (T2).
Under it an invalidating operation on the bound object, an assignment of a non-`Plain`
value, a `ref self` call, a move or a destroy, is
`StrictSharedBorrowInvalidated` (T4; EX-M-4b): the value design's "mutation ends
the lifetime of the value binding" becomes a static rejection for exactly the
mutations that could invalidate. A `Plain`-field write through _another_ shared
alias during the binding is not rejected: it stays erroneous, as the values
design says, and is Debug-detected by a value-binding shadow flag. Debug keeps,
in shadow memory keyed by object address and never in the object's layout, a
per-object count of live non-`Plain` value bindings, incremented when the
binding is formed and decremented at its last use as the stage-4 checker
computes it; a `Plain`-field write through `T*` or `addr self` whose target's
count is non-zero reports `MutationDuringValueBinding`." / "**A non-`Plain` type
from a materialized temporary owns the storage.** An initializing expression is
the third source of a value binding, neither `*p` nor an owner; the binding
takes ownership of the materialized storage, the values design's rule for a
`var` pattern applied to `let`, and carries no loan on it, so `let o:
Core.Optional(i32) = Core.Optional(i32).Some(1);` followed by `o.HasValue()` on
the next line is accepted. The loans carried _by_ the value are unaffected,
which is why a view of a temporary `Buf` stays `StrictBorrowOfTemporary` on the
temporal page (EX-TM-7b)." / "The memory-safety argument for the second part,
which is the part the fork ratified rather than inherited: `Plain` fields carry
no ownership, so a write to one through another alias changes a value the
binding may read stale but frees nothing the binding may read freed; owning
fields cannot be written through `T*` at all (M3); and exclusive writes are
statically dead for the binding's lifetime (M2). What a stale read costs is
correctness, and that is what the Debug report is for. What is narrowed is the
plan of proposal p005434 to prevent _all_ mutation of borrowed objects in the
strict dialect; this page narrows it, dated 2026-10-12, to "no invalidating
mutation", and the same narrowing is applied at the temporal page's
D-SAFE-11(d), where a `bound` argument stays writable in its `Plain` fields for
the duration of a returned loan. The alternative recorded in D-SAFE-17 is eager
acquisition for every type: always copy, the simplest rule, costly for large
owning types, and the rule the break condition adopts if a memory-safety
consequence, as opposed to a correctness one, is ever demonstrated. For Rust, a
parameter bound this way exports as `&SharedView<T>`, not `&T`
([safe-Rust interop](rust_interop.md)).")

## Diagnostics

The rows below are copied from the one matrix on the strategy page,
[What each mode diagnoses](README.md#what-each-mode-diagnoses). The rows other
than `StrictNotSend` and `StrictNotSync` are stage-4 diagnostics, landing with
the loan checker and the `error` default; those two are stage 5 (three rows
added 2026-10-28, SAFE-2: W-348, W-349).

| Diagnostic | Strict | Permissive | Debug runtime |
| --- | --- | --- | --- |
| `StrictInvalidatingThroughShared` | error | warning `PermissiveAliasedExclusive`; none for a C++ non-`const` method through `T*` — assumed fact | — |
| `StrictBorrowFromShared` (realigned 2026-10-28, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictBorrowedObjectMutated` (realigned 2026-10-28, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` |
| `StrictSharedImmutableWrite` (realigned 2026-10-28, SAFE-2: W-348) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` when a binding of the object is live |
| `StrictNotSend`, `StrictNotSync` (stage 5) | error | warning (`--strict-concurrency=warn`) | — |

Two diagnostics the examples on this page produce belong to the temporal page
and are copied there: `StrictSharedBorrowInvalidated`, an invalidating operation
on the owner while a shared loan is live, whose Debug column is ASan-class
detection when the invalidation frees what a loan reads, the value-binding
report being `StrictBorrowedObjectMutated`'s (realigned 2026-10-28, SAFE-2:
W-348; this read "whose Debug column is `MutationDuringValueBinding` for the
value-binding case,"), and `StrictBorrowOutlivesPlace`, which the
thread-boundary lifetime rule raises at a spawn. A fourth,
`StrictRefFromShared`, a `ref` binding through a shared path to an open place,
is the temporal page's too, and a `ref` payload binding through a shared pointer
raises it (M5; realigned 2026-10-28, SAFE-2: W-347).

Message texts:

-   `StrictInvalidatingThroughShared`: "assignment to `{0}` of non-`Plain`
    type `{1}` requires exclusive access; use an `exclusive` pointer,
    `Core.Guarded`, or `unsafe`", which for the `Buf` assignment through a
    shared `p` that M3's escape shows reads "assignment to `*p` of non-`Plain`
    type `Buf(i32)` requires exclusive access; use an `exclusive` pointer,
    `Core.Guarded`, or `unsafe`", and for EX-M-6 names `*d` and
    `Core.Optional(i32*)`; for a call the first
    placeholder is the call and the text reads "call of `ref self` method
    `{0}` through shared pointer `{1}` requires exclusive access", with the
    same suggestion. A note points at the receiver's declaration.
-   `StrictNotSend`: "`{0}` is not `Core.Send`: field `{1}` of type `{2}` is
    not", at the thread-crossing call, with a note at the API's constraint;
    `StrictNotSync` reads the same with `Core.Sync`. The texts are fixed at
    stage 5 (W-149) with the thread API.
-   `StrictBorrowFromShared`: "`{0}` borrows `{1}` through a shared path;
    `{2}` is not `Core.SharedImmutable`; copy it with `var`, use an
    `exclusive` pointer, or `unsafe`", where `{0}` names the value binding or
    the `bound` pointer argument of a call (the temporal page's T5(d)), at the
    binding or the argument, with a note at the shared path's origin
    (realigned 2026-10-28, SAFE-2: W-348, W-349).
-   `StrictBorrowedObjectMutated`: "write to `{0}` while it is borrowed by the
    value binding `{1}`", at the write or at the call that receives a writable
    carrier of the object, with a note at the binding; for the frozen loan of
    a `const` `ref` or of a `bound` argument the text names that binding or
    that result (realigned 2026-10-28, SAFE-2: W-348, W-349).
-   `StrictSharedImmutableWrite`: "write to `{0}` through a shared path
    overwrites `{1}` of `Core.SharedImmutable` type `{2}`; use an `exclusive`
    pointer or `unsafe`", where `{1}` is `{0}` itself or the sub-object of it
    that holds the type, at the write, with a note at the type's opt-in (M3;
    realigned 2026-10-28, SAFE-2: W-348).
-   `PermissiveAliasedExclusive`: the warning twin, same text, same site,
    under `--strict-checks=warn` or in a Permissive file, and the twin of
    `StrictRefFromShared`, `StrictBorrowFromShared`,
    `StrictBorrowedObjectMutated` and `StrictSharedImmutableWrite` (realigned
    2026-10-28, SAFE-2: W-347, W-348); its one Permissive
    exception is the assumed fact of the matrix, that a C++ non-`const`
    method may be called through a shared pointer, which emits nothing.
-   `MutationDuringValueBinding`: the Debug report, one line in the fail-stop
    convention of the [spatial safety](spatial_safety.md) page, "carbon:
    mutation of a borrowed object; terminating", then `abort()`; Release does
    nothing, the write being erroneous and defined. Debug tests every store that
    writes a byte of a borrowed object under a live frozen loan, of any type and
    by any path, `T*`, a `ref`, the owner, a global by name or an `addr self`
    body. It reports what unchecked code can still do, a Permissive body, C++ or
    an alias an `unsafe` binding promised away, and a Strict body's write only
    when a Permissive caller made it aliasing, as `F(ref x, &x)` does for a
    Strict `fn F(ref r: str, p: const str*)` that binds `*p` and then assigns
    `r`, which that call's `PermissiveAliasedExclusive` flags; any other Strict
    body's write is rejected first (realigned 2026-10-28, SAFE-2: W-348; the
    superseded 2026-10-12 message read "carbon: mutation of an object during a
    live value binding; terminating").

## Worked examples

Each rule carries the example the design-conformance checklist
(fork/safe/plan.md §4.1) assigns to it, with the outcome the checklist states
against the 0.1 toolchain: ACCEPTS, REJECTS, ACCEPTS-UNCHECKED (compiles today
but Strict must reject, with the stage that will) or NEW-SYNTAX (no toolchain
parses it, with the stage that will). EX-M-4a, EX-M-4c and the functions `Peek`,
`Peek2` and `Peek4` of EX-M-4d use only the upstream prelude and were compiled
on the 2026.10.12 nightly toolchain with `carbon compile
--output-last-input-only` and no `package` line, then linked and run (EX-M-4c
and EX-M-4d added 2026-10-28, SAFE-2: W-348); EX-M-4b and EX-M-4d's `BufSize`
and `Peek8` use the fork prelude's `Core.Buf`, which that toolchain lacks; every
other example is NEW syntax. Prelude names are `Core.`-qualified throughout.
Tags of the form A-n, B-n and RR-n in example comments index the review-fold
record of [fork/safe/plan.md](/fork/safe/plan.md).

### EX-M-1: Aliased non-invalidating mutation

```carbon
// EX-M-1 (NEW: `addr`, `exclusive`)
class IntVec {
  fn Push[ref self: Self](v: i32);                 // exclusive: may reallocate
  fn Set[addr self: Self*](i: i64, v: i32);        // non-invalidating: i32 is Plain
  fn Get[bound self: Self](i: i64) -> const i32*;  // result: shared loan on self
  fn Len(self) -> i64;
  private var buf: Core.Buf(i32);  private var len: i64;
}
fn Fill(vec: exclusive IntVec*) {
  let a: IntVec* = vec;           // downgrade: shared loan on *vec
  let b: IntVec* = vec;           // many shared pointers: fine
  a->Set(0, 1);  b->Set(1, 2);    // aliased mutation: fine
  // vec->Push(3);                // StrictSharedBorrowInvalidated while a or b is live
  let first: const i32* = vec->Get(0);   // the bound self of Get freezes *vec while first lives (T5(d))
  // a->Set(0, 5);                // StrictBorrowedObjectMutated: an addr call on the frozen *vec while first lives (realigned 2026-10-28, SAFE-2: W-349; this line read "a->Set(0, 5);  // fine: *first now reads 5 — observable, not dangling")
  Core.Print(*first);
  a->Set(0, 5);                   // fine: first is dead (NLL), and its frozen loan with it
  vec->Push(3);                   // fine: a, b, first are dead (NLL)
}
```

Rules M1, M3 and M4, and the reborrow clause of T2. `IntVec` is the migrated
container shape of the [C++ interop consequence](#c-interop-consequence): `Push`
is `ref self` because it may reallocate `buf`, which would end the lifetime of
every element and so is invalidating (M3(a)); `Set` is `addr self` because
writing an `i32` element is a `Plain` write (M3(c) does not fire) and its body
is checked to do nothing else; `Get` is `bound self` so its result keeps `*vec`
borrowed. `Set`'s body writes the element through the private `buf` with no
exclusive access to it, which a `Plain` `i32` element, another object's storage,
does not need ([Value bindings](#value-bindings)): as
`*self->buf.AsSlice().Subslice(i, i + 1).Data() = v;` until the indexing
interface `IndirectIndexWith` lands, and as `self->buf[i] = v` after it, its
`Ref` taking `bound self` under residue item W-144; `self->buf.Set(i, v)` would
be `StrictInvalidatingThroughShared` (M3(d)), `Core.Buf(T).Set` taking `ref
self` (realigned 2026-10-28, SAFE-2: W-349, W-348; the superseded 2026-10-12
text read: "`Get` is `bound self` so its result is a shared loan on `*vec`.").
The two downgrades `a` and `b` suspend `vec`'s exclusivity, and while either is
live `vec` may be used only at shared kind: `a->Set` and `b->Set` through two
aliases at once are fine, the commented `vec->Push(3)` would be
`StrictSharedBorrowInvalidated`. `first` is the result of `Get`'s `bound self`,
a value binding of `*vec` whose value representation is a pointer, so for
`first`'s lifetime `*vec` is a borrowed object under a frozen loan (the temporal
page's T5(d): each `bound` argument is immutable for the duration of the
returned result), and `a->Set(0, 5)` under it is `StrictBorrowedObjectMutated`:
an `addr` call through an alias writes the frozen object. After
`Core.Print(*first)` `first` is dead, so the same `a->Set(0, 5)` is accepted
there, and once no carrier of any loan is used again `vec->Push(3)` is accepted
(realigned 2026-10-28, SAFE-2: W-349; the superseded 2026-10-12 text read: "`first`
is a shared loan too, and `a->Set(0, 5)` under it is fine: `*first` observes the
new value, which is not a mutation safety bug, because nothing was invalidated.
After `Core.Print(*first)` no carrier of any shared loan is used again, so by
non-lexical liveness the loans are dead and `vec->Push(3)` is accepted.").
Outcome: NEW-SYNTAX; `addr self` and `exclusive` do not parse, and the
toolchain's one `addr self` path is a gated TODO for an explicit receiver
(toolchain/check/call.cpp:528-540). Stage 1 parses the spellings; stage 4 checks
them.

### EX-M-2: The opt-in dynamic cell

```carbon
// EX-M-2 (NEW): the opt-in dynamic cell for observer idioms
fn Observe(counter: Core.Guarded(Core.Buf(i32))*, p: Core.Buf(i32)*) {
  counter->Modify(fn (ref b: Core.Buf(i32)) { b.Push(1); });   // dynamic exclusivity
  // p->Push(1);                  // StrictInvalidatingThroughShared
}
```

Rule M6. `p` is a shared pointer to a `Buf`, and `Push` is an exclusive
method, so the commented line is `StrictInvalidatingThroughShared` by M3(d):
the observer idiom, many holders of a pointer each of which wants to push,
cannot be written through `T*`. `counter` is a shared pointer to a
`Guarded(Buf)`, and `Modify` is an `addr` method, so the call is permitted
through `T*` (M4); inside, `b` is the exclusive `ref` the cell hands out for
the call, and `b.Push(1)` is checked under exclusive access. If an observer
re-enters `Modify` on the same cell from inside `f`, the busy flag fails-stop.
Outcome: NEW-SYNTAX (library); `Core.Guarded` does not exist and the sketch
above does not parse. Stage 4 with W-144 adds the type.

### EX-M-3: Facets at the thread boundary

```carbon
// EX-M-3 (NEW, stage 5): facets at the thread boundary, and the thread-boundary lifetime rule (A-6)
fn Spawn[T: Core.Send](f: fn (var t: T), t: T);          // Core.Thread.Spawn's shape: `t`'s loan set must be free
fn BadSpawn(p: i32*) { Spawn(fn (var q: i32*) { *q = 1; }, p); }   // StrictNotSend: `i32*` is not Send
fn Race() { var x: i32 = 0; Spawn(fn (var q: exclusive i32*) { *q = 1; }, &x); }   // StrictBorrowOutlivesPlace at the spawn: &x is a loan on a local, not free
fn Scoped() { var x: i32 = 0; Core.Thread.Scope(fn (ref s: Core.Thread.Scope) { s.Spawn(fn (var q: exclusive i32*) { *q = 1; }, &x); }); }   // fine: joined inside the borrow
```

Rule M7, both halves. `BadSpawn` passes a `T*` across the thread boundary;
`i32*` is not `Send` by the facet table, so the generic constraint on `Spawn`
fails: `StrictNotSend`. `Race` passes an `exclusive i32*`, which is `Send`
because `i32` is, so the facets accept it, and the thread-boundary lifetime
rule rejects it: `&x` is a loan on a local, not a free loan set, and a detached
thread may outlive `x`, so `StrictBorrowOutlivesPlace` at the spawn. `Scoped`
is the same loan handed to a scoped thread: the scope's join lies inside the
borrow, `x` outlives every thread that borrowed it, and the program is
accepted. The commented tag names the review finding that added the rule.
Outcome: NEW-SYNTAX; no facet, no `Core.Thread` and no `exclusive` exist.
Stage 5 (W-149).

### EX-M-4a: A value binding that copies

```carbon
// EX-M-4a (today's syntax; accepted today and in Strict — realigned 2026-10-28, SAFE-2: W-348: i32's value representation is a copy,
// so the binding holds no loan; b is 1; this comment read "amended 2026-10-12, review fold: A-8, B3: i32 is Plain, the binding copies eagerly (D-SAFE-17), there is no loan to invalidate; b is 1")
fn ValueBinding() -> i32 {
  var a: i32 = 1;
  let b: i32 = a;                 // eager copy
  a = 2;                          // accepted in every mode
  return b;                       // 1
}
```

Rule M8, the copy case. `i32`'s value representation is a copy, so `b` read the
value when it was bound and holds no loan (the heading read "A `Plain` value
binding" and this sentence "Rule M8, the `Plain` case. `i32` is `Plain`, so `b`
acquires eagerly and holds no loan;" before 2026-10-28, SAFE-2: W-348); `a = 2`
is a `Plain` assignment on an owner under no loan, accepted in every mode; `b`
is 1. Outcome: ACCEPTS, today and in Strict. The nightly compiles it with exit
status 0 and no diagnostic, and with a `Run` that prints `ValueBinding()` the
linked program prints `1`; the erroneous-reading rule of the values design does
not arise for an eager copy, and that design's dated note says so.

### EX-M-4b: A value binding that borrows

```carbon
// EX-M-4b (fork-prelude syntax; accepted today — M8: a Core.Buf binding borrows its object under a frozen loan; realigned 2026-10-28, SAFE-2: W-348, was "a non-Plain value binding is a shared loan")
fn ValueBinding2() -> i64 {
  var a: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  let b: Core.Buf(i32) = a;       // frozen loan on a for b's lifetime (T2)
  a = Core.Buf(i32).Make(2, 0);   // Strict: StrictSharedBorrowInvalidated (assignment of a non-Plain type is invalidating, 9(c); b is live below)
  return b.Size();
}
```

Rule M8, the borrowing case. `Core.Buf(i32)` is a class, whose value
representation is a pointer, so `b` binds `a` as a borrowed object under a
frozen loan for its lifetime, which extends to `b.Size()` on the last line
(realigned 2026-10-28, SAFE-2: W-348; the heading read "A non-`Plain` value
binding", and the superseded 2026-10-12 text read "Rule M8, the non-`Plain`
case. `Core.Buf(i32)` is not `Plain`, so `b` is a shared loan on `a` for its
lifetime"). The assignment `a = Core.Buf(i32).Make(2, 0)` is invalidating by
M3(c), and in the fork prelude's `Buf` it is concretely so: the old block is
freed by `Destroy` (buf.carbon:58-60) while `b`'s deferred read could still
reach it. Strict rejects it with `StrictSharedBorrowInvalidated`; Permissive
warns `PermissiveAliasedExclusive`; Debug reports `MutationDuringValueBinding`
at the write in a Permissive body (realigned 2026-10-28, SAFE-2: W-348; the
superseded 2026-10-12 sentence read "Debug reports the stale read if it
happens."; the mark amended 2026-10-28, document-review fold: R2-m2). The fix
is to end `b`'s use before the
assignment or to copy eagerly with a `var`. Outcome: ACCEPTS-UNCHECKED (fork
prelude, not compile-verified in this PR): the fork toolchain compiles it, the
value binding being today's `i32`-independent rule with no loan behind it, and
nothing rejects the assignment. Stage 4.

### EX-M-4c: A `Plain` write to a borrowed object

```carbon
// EX-M-4c (today's syntax; accepted today — added 2026-10-28, SAFE-2: W-348): the Plain write left erroneous before is rejected
fn ValueBinding3() -> i32 {
  var a: {.n: i32, .o: Core.Optional(i32)} = {.n = 1, .o = Core.Optional(i32).None()};
  let b: {.n: i32, .o: Core.Optional(i32)} = a;   // two elements: a pointer representation, so b borrows a under a frozen loan
  a.n = 2;                                        // Strict: StrictBorrowedObjectMutated (b is live below)
  return b.n;
}
```

Rule M8, the frozen loan on a closed place. The struct has two elements and
its `Core.Optional(i32)` element's value representation is a pointer, so
today's toolchain represents the struct's values by a pointer to a separate
aggregate of the element values (upstream
toolchain/check/type_completion.cpp:580-582 and :597-609 at 0421bf3b4), not a
copy, and `b` binds `a` as a borrowed object; `a` is an owner, a closed place,
and the `Plain` assignment
`a.n = 2` writes the borrowed object's storage while `b` lives, which Strict
rejects with `StrictBorrowedObjectMutated` and Permissive warns
`PermissiveAliasedExclusive`. Nothing is invalidated: the program is
memory-safe either way, and the rejection is proposal p005434's prevention of
an erroneous mutation, not a memory-safety repair. Outcome: ACCEPTS-UNCHECKED —
the nightly compiles it with exit status 0 and no diagnostic, and with a `Run`
that prints `ValueBinding3()` the linked program prints `1`: the toolchain
copied the `i32` element into the aggregate it built at the binding, one of the
outcomes the erroneous behavior allows. The fix is a copy,
`var b: {.n: i32, .o: Core.Optional(i32)} = a;`. Stage 4.

### EX-M-4d: A borrowed object through a shared pointer

```carbon
// EX-M-4d (Peek, Peek2, Peek4: today's syntax, accepted today; BufSize, Peek8: fork prelude — added 2026-10-28, SAFE-2: W-348)
fn Peek(p: {.n: i32, .o: Core.Optional(i32)}*, q: {.n: i32, .o: Core.Optional(i32)}*) -> i32 {
  let v: {.n: i32, .o: Core.Optional(i32)} = *p;  // Strict: StrictBorrowFromShared — *p is an open place, and a struct is never Core.SharedImmutable
  q->n = 2;                                       // the write the rule exists for: q may be p
  return v.n;
}
fn BufSize(p: Core.Buf(i32)*) -> i64 { return p->Size(); }   // accepted: Core.Buf(i32) is Core.SharedImmutable (W-144), so self binds frozen on the open *p
fn Peek2(p: const str*, q: str*) -> i64 {
  let s: str = *p;                                // accepted: str, the prelude's Core.String, is Core.SharedImmutable, so s binds frozen on the open *p
  *q = "longer";                                  // Strict: StrictSharedImmutableWrite (M3) — q may be p
  return s.Size();
}
fn Peek4(p: {.s: str, .n: i32}*, q: {.s: str, .n: i32}*) -> i64 {
  let s: str = p->s;                              // accepted: s binds frozen on the open p->s, str being Core.SharedImmutable
  *q = {.s = "longer", .n = 1};                   // Strict: StrictSharedImmutableWrite (M3) — the struct holds a str, and q may be p
  return s.Size();
}
fn Peek8(b: Core.Buf(str)*) -> i64 {
  let s: str = *b->AsSlice().Data();              // accepted: s binds frozen on the open element, str being Core.SharedImmutable
  b->Set(0, "longer");                            // Strict: StrictInvalidatingThroughShared — Set takes ref self (W-144), so no trusted body writes the element s borrows
  return s.Size();
}
```

Rule M8, the open place. In `Peek`, `p` and `q` are shared pointers that may
alias, and nothing the body can see says whether they do, so the frozen loan
`v` needs cannot be established on `*p`: the binding is
`StrictBorrowFromShared`, and the fixes are `var v: ... = *p;`, an `exclusive`
parameter, or `unsafe *p` with its obligation. In `BufSize`, the by-value
`Size` binds `*p` the same way, and `Core.Buf(i32)`'s opt-in to
`Core.SharedImmutable` makes it sound: no path but an exclusive one writes a
`Buf`'s storage, and the live shared path `p` excludes those. `Peek2` is the
other half of that promise: `str` opts in too, so `s` binds frozen on the open
`*p`, and the write the opt-in would otherwise let through, a `Plain`
assignment of the whole `str` through the shared `q`, is rejected by M3 with
`StrictSharedImmutableWrite`. `Peek4` is the same write one level up: the
struct `{.s: str, .n: i32}` is `Plain` and is not `Core.SharedImmutable`, but
it holds a `str`, so the whole-struct assignment through `q` writes the
storage `s` borrows and M3 rejects it with `StrictSharedImmutableWrite`; a
class with a `str` field is rejected the same way. `Peek8` is the same write
made by a trusted body: `s` binds an element of the block frozen, and the
by-value `Set` of the 0.1 prelude would write that element through the block's
pointer, so the prelude keeps M3's rule too ([Value bindings](#value-bindings))
and `Set` takes `ref self`, an exclusive receiver, which the shared `b` cannot
provide (M3(d)); with `b: exclusive Core.Buf(str)*` the call is
`StrictSharedBorrowInvalidated` while `s`, which carries the view's loan on
`*b`, lives, and is accepted after `s`'s last use. Outcome: `Peek`, `Peek2`
and `Peek4` ACCEPTS-UNCHECKED — the nightly compiles all three with exit
status 0; `Peek(&a, &a)` for `a.n == 1` prints `1`, `Peek2(&x, &x)` for
`x == "ab"` prints `6`, and `Peek4(&y, &y)` for `y == {.s = "ab", .n = 0}`
prints `6`, `s` reading the string `q` wrote, the erroneous behavior Strict
now prevents; `BufSize` and `Peek8` are fork prelude, not compile-verified in
this PR, and a class of `Peek8`'s shape, a `str*` field with a by-value `Set`
writing through it, prints `6` on the same nightly. Stage 4, with W-144 for
the opt-ins and `Set`'s receiver.

### EX-M-5: Payload bindings through a shared path

```carbon
// EX-M-5 (NEW-SYNTAX: payload `match` on Core.Optional, which is not a choice today, optional.carbon:64-68 — RR-4; Core.Buf per B2;
// realigned 2026-10-28, SAFE-2: W-347 — a value payload through a shared path, where `case .Some(ref s)` is StrictRefFromShared): payload bindings through a shared path
fn Alt(c: Core.Optional(Core.Buf(i32))*) {
  match (*c) { case .Some(s: Core.Buf(i32)) => { Core.Print(s.Size()); } default => {} }   // frozen sub-loan on the payload (Core.Buf is Core.SharedImmutable, W-144); *c cannot change alternative while s lives (M3(c): Optional is non-Plain)
}
```

Rule M5. `c` is a shared pointer to an open place, so a `ref` payload binding
through `*c` would be `StrictRefFromShared`, and the program binds the payload
by value: `s` binds a `Core.Buf(i32)`, whose value representation is a pointer,
so it is a borrowed object, and the frozen sub-loan stands on the open place
because `Core.Buf` is `Core.SharedImmutable` (realigned 2026-10-28, SAFE-2:
W-347; the superseded 2026-10-12 text read "Rule M5. `c` is a shared pointer, so
the `match` through `*c` binds `s` as a shared sub-loan on `*c`'s payload;").
While `s` lives no alias may assign `*c` a new alternative, because
`Core.Optional(Core.Buf(i32))` is non-`Plain` and such an assignment is M3(c)'s
invalidating operation, rejected through a shared path with
`StrictInvalidatingThroughShared` and through the owner with
`StrictSharedBorrowInvalidated`. Nothing in `Alt` tries, so `Alt` is accepted.
Outcome: NEW-SYNTAX. `Core.Optional` is a class with an `adapt`
(optional.carbon:30-46) and the prelude's own comment (:64-68) says it "is not a
choice" and that the `match` form "applies once an approved `Optional` design
makes it one", so the `case .Some(...)` pattern does not parse against the fork
prelude (realigned 2026-10-28, SAFE-2: W-347; this read "so `case .Some(ref s)`
does not parse against the fork prelude"; the mark amended 2026-10-28,
document-review fold: R2-m2); `ref` payload bindings exist today only for user
`choice` types (toolchain/check/handle_binding_pattern.cpp:518-528). Stage 4
plus the choice-based `Optional` redesign the prelude comment names.

### EX-M-6: The alternative cannot change through another alias

```carbon
// EX-M-6 (regression, review A-3; NEW-SYNTAX for the same reason as EX-M-5, RR-4; realigned 2026-10-28, SAFE-2: W-347 —
// the payload binds by value, a copied i32*, where it was `case .Some(ref p)`): the alternative cannot change through another shared alias either
fn Alt2(c: Core.Optional(i32*)*, d: Core.Optional(i32*)*) {   // two shared T* to one object: allowed
  match (*c) {
    case .Some(p: i32*) => {
      *d = Core.Optional(i32*).None();   // StrictInvalidatingThroughShared: Optional(i32*) is not Plain (D-SAFE-9, A-3)
      Core.Print(*p);
    }
    default => {}
  }
}
```

Rule M3(c) applied to a sum, the regression program behind the structural
definition of `Core.Plain`. Two shared pointers to one `Optional(i32*)` are
allowed (M2). The `match` through `*c` binds `p` by value: a pointer is
copy-represented, so `p` is a copy and holds no loan on the payload, where a
`ref p` would be `StrictRefFromShared` through the shared `c` (M5), and the
2026-10-12 program's `Core.Print(**p)` through the `ref` becomes
`Core.Print(*p)`. `*d = Core.Optional(i32*).None()` would change the alternative
of the object `c` and `d` share, which under a live payload binding is the
second mutation safety bug of the [definition](#definition), and the rule that
catches it is not a special rule about sums: `Optional(i32*)` is non-`Plain`, so
the assignment through the shared `d` is `StrictInvalidatingThroughShared`
regardless of whether any `match` is active (realigned 2026-10-28, SAFE-2:
W-347; the superseded 2026-10-12 text read: "The `match` through `*c` binds `p`
as a shared sub-loan on the payload. `*d = Core.Optional(i32*).None()` would
change the alternative under `p`, the second mutation safety bug of the
[definition](#definition), and the rule that catches it is not a special rule
about sums"). A representational definition of `Plain` ("`Copy` with trivial
destruction") would have admitted `Optional(i32*)`, whose storage is one
null-niche word with a `primitive_copy` and no `Destroy`
(optional.carbon:186-203), and accepted this program; criterion (ii) excludes
it. Outcome: NEW-SYNTAX, the same `match`-on-`Optional` form as EX-M-5. Stage 4
plus the `Optional` redesign.

The checklist rows this page owns, in the checklist's own vocabulary:

| Rule | Example | Today | Stage |
| --- | --- | --- | --- |
| M3/M4 `addr`, reborrow | EX-M-1 | NEW-SYNTAX | 1, 4 |
| M6 `Guarded` | EX-M-2 | NEW-SYNTAX (library) | 4 (W-144) |
| M7 facets, thread-boundary lifetime | EX-M-3 (`BadSpawn`, `Race`, `Scoped`) | NEW-SYNTAX | 5 (W-149) |
| M8 value binding, copy representation (realigned 2026-10-28, SAFE-2: W-348) | EX-M-4a | ACCEPTS (today and in Strict; `b` is 1) | — |
| M8 value binding, borrowed object (realigned 2026-10-28, SAFE-2: W-348) | EX-M-4b | ACCEPTS-UNCHECKED (fork prelude) | 4 |
| M8 `Plain` write to a borrowed object (added 2026-10-28, SAFE-2: W-348) | EX-M-4c | ACCEPTS-UNCHECKED (nightly exit 0, prints 1) | 4 |
| M8 borrowed object through a shared pointer, `Core.SharedImmutable` (added 2026-10-28, SAFE-2: W-348) | EX-M-4d | ACCEPTS-UNCHECKED for `Peek`, `Peek2` and `Peek4` (nightly exit 0, print 1, 6 and 6); `BufSize` and `Peek8` fork prelude | 4 (W-144) |
| M5 payload bindings (realigned 2026-10-28, SAFE-2: W-347) | EX-M-5 | NEW-SYNTAX | 4 plus the `Optional` redesign |
| M3(c) sums non-`Plain` | EX-M-6 `Alt2` | NEW-SYNTAX | 4 plus the `Optional` redesign |

## C++ interop consequence

C++ is Permissive Carbon (D-SAFE-18): C++ code is trusted to meet its declared
contracts, and the importer maps what a C++ declaration says into the receiver
forms and facets of this page. For mutation safety that has these
consequences:

-   **A migrated class partitions its mutating methods by receiver.** A C++
    class whose non-`const` methods are rewritten in Carbon splits them into
    `addr self` methods, the element writes and other non-invalidating
    mutations, and `ref self` methods, `push_back`, `clear`, assignment and
    everything else that can reallocate, destroy or change which sub-objects
    exist. The partition _is_ the invalidation surface the C++ standard
    documents per container: the methods the standard lists as invalidating
    iterators and references are the `ref self` ones, and the ones it guarantees
    do not are the `addr self` ones. EX-M-1's `IntVec` is the shape for
    `std::vector<int>`: `Set` is `operator[]` as a write, `Push` is `push_back`.
    A migrated class therefore gains a checked statement of what C++ left to
    documentation, and a Strict caller holding a `T*` to it can call exactly the
    methods that cannot invalidate its other pointers. An element write takes
    `addr self` only when the element type holds no `Core.SharedImmutable`
    sub-object (M3): a setter of a `str` element, like a setter of a `str` field
    (M4), takes `ref self` although it invalidates nothing, as `Core.Buf(T).Set`
    does for every element type ([Value bindings](#value-bindings); added
    2026-10-28, SAFE-2: W-348).
-   **Imported C++ methods are conservatively exclusive.** A non-`const` C++
    method imports as `ref self`, exclusive and invalidating, because the
    importer cannot see whether its body invalidates; it is callable through
    `exclusive T*`, and through a shared `T*` only as `unsafe p->M(...)` or
    by way of `Core.Guarded`. A `const` method imports as const access. A
    future non-invalidation annotation on a C++ method maps to `addr self`;
    until it exists, the per-site `unsafe` is the audit line of a shared call
    into C++. In Permissive the shared call needs no marker, the third
    assumed fact of the strategy's matrix.
-   **C++ `T&` is shared `T*`.** A C++ reference parameter or member imports
    as the shared-mutable kind
    ([bidirectional interoperability](../README.md#bidirectional-interoperability-with-c-and-c)),
    so C++ code reachable through it can do to the object whatever C++ can,
    and that is the C++ side's business under S0; what the mapping buys is
    that Carbon never hands C++ an `exclusive T*` it did not spell, and T8
    withholds `noalias` at every such boundary. A `_Nonnull` or
    `[[clang::lifetimebound]]` annotation changes the temporal reading of the
    parameter ([temporal safety](temporal_safety.md)), not its kind.
-   **Facets for C++ types come from annotations.** An imported C++ type is
    neither `Send` nor `Sync` unless annotated; a class every one of whose
    data members is `guarded_by` a `capability` member imports as `Sync`,
    and nothing else does. Whether a C++ type is `Freeze` follows the
    structural rule over the layout the importer sees. The members of
    `std::atomic<T>` and `std::thread` that the 0.1 threading decision models
    are allowlist shape 3 on the strategy page and need no marker; the
    function value crossing into `std::thread` is the export case under
    which no `noalias` is emitted.
-   **Interior mutability is C++'s to provide.** `Core.Atomic(T)` is
    `Cpp.std.atomic(T)` behind a Carbon signature; a Carbon type that wants
    to mutate through a shared path in Strict does so by holding one, and is
    then not `Freeze`.

The migration ladder for a C++ API that takes pointers is the one on the
strategy page, [C++ migration example](README.md#c-migration-example); for a
container it is the partition above, applied method by method as each body is
rewritten in Carbon and its receiver chosen.

## Implementation staging

The rows this page owns in the staging of D-SAFE-21; the
[safety README](README.md#implementation-staging) carries the full table. 0.1
claims no executable behavior from this page: no mutation through a shared
pointer is diagnosed, no facet exists, and no value binding holds a loan in
the 0.1 toolchain.

| Stage | Contents | Owned here |
| --- | --- | --- |
| 0 (this PR) | This page; no toolchain change | All of this page |
| 1 | Lex and parse `exclusive`, `addr`, `unsafe impl` and the `unsafe` prefix forms; recorded in SemIR, unenforced (W-145) | The `addr self: Self*` receiver and `exclusive T*` in EX-M-1 parse; `unsafe impl T as Core.Send {}` parses |
| 4 | The loan checker (W-148) | M1 to M5: `Core.Plain` synthesis, `StrictInvalidatingThroughShared` with its twin `PermissiveAliasedExclusive`, M3's `StrictSharedImmutableWrite`, the `addr` body check of M4, payload sub-loans of M5; M8: the frozen loan of a borrowed object, `StrictBorrowedObjectMutated` and `StrictBorrowFromShared`, `Core.SharedImmutable` with the prelude's opt-ins (W-144), and the Debug shadow count behind `MutationDuringValueBinding` (realigned 2026-10-28, SAFE-2: W-348); M6: `Core.Guarded(T)` under W-144 |
| 5 | Facets, `Core.Thread`, `--strict-concurrency` (W-149) | M7: `Core.Send`, `Core.Sync`, `Core.Freeze`, `StrictNotSend`, `StrictNotSync`, the thread-boundary lifetime rule, `unsafe impl` opt-in |

Stages 2, 3 and 6 own nothing on this page. The `match` forms of EX-M-5 and
EX-M-6 additionally wait on the choice-based `Core.Optional` redesign the
prelude's own comment names, which is not a stage of this design.

## Decisions within this design

Each decision below is a sub-decision of fork decision F-013, recorded with
its break condition in [fork/decision-log.md](/fork/decision-log.md); the
[safety README](README.md#decisions-within-this-design) and the other category
pages carry the rest of D-SAFE-1 to D-SAFE-23.

-   **D-SAFE-9 — The no-invalidation rule and `Core.Plain`.** An operation is
    invalidating when it can end the lifetime of an object reachable from the
    place or change which sub-objects exist at an address: destruction, `~P`,
    non-`Plain` assignment, an exclusive-receiver call, forming an exclusive
    loan. Invalidating operations require exclusive access, and so does every
    assignment whose type holds a `Core.SharedImmutable` sub-object (M3,
    D-SAFE-17; added 2026-10-28, SAFE-2: W-348); everything else is permitted
    through any number of aliases, a `const` call whose `self` binds a
    borrowed object or is a `ref self: const Self`, and a read into a value
    binding of a borrowed object, through `T*` or `const T*` needing besides a
    closed place, a `Core.SharedImmutable` type, or `unsafe`, under D-SAFE-17
    and, for the `const` `ref`, D-SAFE-8 (amended 2026-10-28, document-review
    fold: R1-M3; amended 2026-10-29, re-review round 2: RR1-M2, where this read
    "a `const` call or a read into a value binding of a borrowed object
    through `T*` or `const T*` meeting D-SAFE-17's rule besides"). A built-in
    operator's `ref` operand, built in meaning that its implementation is the
    language's own or an impl of an operator interface written in core/prelude
    that calls no impl written outside core/prelude while its `ref` operand is
    bound, M3 counting every assignment operator, compound assignment included,
    and `++` and `--` as an assignment to that operand (added 2026-10-29,
    re-review round 3: RR2-M1), an assignment's among them, is neither an
    exclusive-receiver call nor an exclusive loan: the operation is classified
    by what it does (D-SAFE-8; amended 2026-10-28, document-review fold: R1-M1;
    amended 2026-10-29, re-review round 2: RR1-m1, where this read "is not an
    exclusive-receiver call"). `Core.Plain` is structural: `Copy` with trivial
    destruction, every sub-object existing and formed at a fixed offset;
    `Optional(T)`, `MaybeUnformed(T)`, payload choices, `Buf`, `Box` and
    pointer-carrying unions are not `Plain`, the scalars, the three pointer
    kinds, `Slice` and `String` are. Break condition: a migration corpus in
    which more than 30 percent of C++ non-`const` methods end up exclusive —
    then a finer rule (assignment through `T*` when no sub-loan into the old
    value can exist, needing per-field loan tracking) or an
    `unsafe impl T as Core.Plain` opt-in.
-   **D-SAFE-16 — Data races: inferred facets, staged, all races prevented
    among Carbon threads.** `Send`, `Sync` and `Freeze` are structural facets
    with the base cases of the table above; enforcement is at thread-crossing
    APIs as generic constraints, staged facets, then `warn`, then `error`,
    with the thread-boundary lifetime rule (a free loan set or a scoped join).
    Break condition: facet synthesis cannot see through imported C++ layouts —
    the C++ default, neither unless annotated, already covers it.
-   **D-SAFE-17 — Value bindings through shared pointers.** A value binding of
    a type whose value representation is a copy holds no loan; any other binds
    a borrowed object (proposal p005434) under a frozen loan for its lifetime,
    so Strict prevents every mutation of the object through any path,
    `StrictBorrowedObjectMutated` or, for an invalidating one,
    `StrictSharedBorrowInvalidated`; the loan is formed on a closed place, or
    on an open place for a `Core.SharedImmutable` type (an `unsafe impl` opt-in
    whose storage M3 lets no shared-path assignment write, of the type or of
    one that holds it, which the prelude takes for `String`
    and, for a `Freeze` argument, `Slice`, `Buf` and `Optional`, and for `Box`
    when W-144 adds it, its trusted bodies keeping the same write rule, so
    that `Buf`'s `Set` takes `ref self`), and the binding is
    `StrictBorrowFromShared` otherwise; a binding from a
    materialized temporary owns the storage. This is proposal p005434's plan to
    prevent mutation of borrowed objects in the strict dialect, kept. Break
    condition: upstream relaxes p005434:663 under its :665-669 conditions, or a
    prelude function is shown to write such storage through a shared path, an
    element of a block it owns included, which is answered by fixing that
    function (realigned 2026-10-28, SAFE-2: W-348; the
    superseded 2026-10-12 text read: "A `Plain` value binding copies eagerly
    and holds no loan; a non-`Plain` one from `*p` or an owner is a shared loan
    under which invalidating operations are rejected and `Plain`-field writes
    through other aliases stay erroneous and Debug-detected; one from a
    materialized temporary owns the storage. This narrows proposal p005434's
    plan to prevent all mutation of borrowed objects in the strict dialect.
    Break condition: a demonstrated memory-safety (not correctness) consequence
    — then the eager-copy alternative is adopted for every type.").
-   **D-SAFE-20 — Library surface, all residue, none in 0.1.** `Core.Plain`,
    `Core.Send`, `Core.Sync`, `Core.Freeze` (compiler-determined, `unsafe
    impl` opt-in where opt-in exists), `Core.Guarded(T)` (a busy flag plus
    `fail_stop`, `Modify[addr self: Self*](f)`, no builtin) and
    `Core.Box(T)` and `Core.SharedImmutable` (opt-in only, implying
    `Core.Freeze`; added 2026-10-28, SAFE-2: W-348) are this page's items;
    `Core.Relocatable`, `Core.Move`,
    `Core.Lifetime`, `Core.DynCast` and `Core.Utf8` are the other pages'.
    Break condition: none; each is a filed item with its own gate.

Three rules on this page rest on decisions other pages own: the pointer kinds
and the `ref` rule of M1 are D-SAFE-7 and D-SAFE-8 (the latter realigned
2026-10-28, SAFE-2: W-347, where this text read "the `ref`-kind inheritance of
M1"), and the conflict rule behind M2, with the reborrow clause EX-M-1 relies
on, is T4 of D-SAFE-10 ([temporal safety](temporal_safety.md)); the taxonomy
sentence of the [definition](#definition) is D-SAFE-1
([safety README](README.md)).

## Alternatives considered

The design was chosen by a panel of three attempts and two judges, recorded in
[fork/safe/plan.md](/fork/safe/plan.md); the judges scored the attempts as
wholes, and the [safety README](README.md#alternatives-considered) carries
their verdicts. The alternatives specific to this page:

-   **Attempt A's `shared T*` qualifier with an exclusive `T*`.** Attempt A,
    "Strict Carbon by default: owners, loans, and operation-tied `unsafe`",
    made `T*` the exclusive-mutable kind, re-meant `const T*` as
    shared-immutable, and added a NEW `shared T*` as the Ante-style
    shared-mutable kind with a `SharedAssignable` facet in the role
    `Core.Plain` has here. Judge 1 found the first two fatal: the C++ `T&` to
    `T*` mapping and the prelude's own `ptr: T*` fields of `Slice` and `Buf`
    are shared views of one block, so an exclusive `T*` turns every one into
    an unverified `noalias` claim, and `const` acquiring "shared" reads a
    meaning into `const` that the values design reserves against. The
    synthesis keeps `T*` shared, spells the exclusive kind `exclusive T*`
    (attempt A's explicit kind as a third kind, which both judges asked for),
    and takes attempt B's structural `Plain` over `SharedAssignable` (judge
    2's graft), because a facet the compiler decides from the type's layout
    is what M3(c) needs and an opt-in facet is what the break condition of
    D-SAFE-9 holds in reserve.
-   **Attempt B's single pointer kind.** Attempt B, "Places, projections and
    shared cells", the base of the synthesis, had no exclusive pointer _type_ by
    design and would have had `ref` be the only exclusive access. Judge 2 found
    that fatal because it contradicts proposal p005434's `ref` through `*p`
    examples and makes `ref self` unreachable through a pointer in Strict, so a
    `Push` could be called on an owner but never on a pointee; repairing it
    means adding the exclusive kind, which the synthesis did. Judge 1 also
    required B's MS-5, the value-binding rule, to be ratified rather than
    inherited, which D-SAFE-17 does under [Value bindings](#value-bindings).
    D-SAFE-17 was realigned 2026-10-28 by SAFE-2 (W-348) to proposal p005434's
    rule for borrowed objects.
-   **Swift-style dynamic exclusivity on every access.** Enforcing
    exclusive-XOR-shared at run time for every class property and escaping
    access, the shape Swift's law of exclusivity takes where it cannot be
    proved statically ([external fact](#external-facts)), was rejected on
    budget: the strategy's temporal overhead ceiling is under 1 percent in
    aggregate (proposal p005914), a per-access check is paid on the hot path
    of every program, and the strategy's [constraints](README.md#constraints)
    say why a language-level mechanism with that overhead is not the
    baseline. The design keeps the dynamic check as the opt-in, local
    `Core.Guarded(T)`, paid only by the idiom that needs it.
-   **Narrowing the prevention to invalidating mutation.** The rule of
    2026-10-12 rejected only the invalidating mutations of a non-`Plain` value
    binding's object and left `Plain`-field writes through other aliases
    erroneous and Debug-detected, on the argument that such a write frees
    nothing a binding may read. Withdrawn 2026-10-28 by SAFE-2 (W-348) under
    rulebook R32: proposal p005434 plans to prevent mutation of borrowed
    objects in the strict dialect and keeps relaxing that plan to itself
    (p005434:663-669), so a memory-safety argument is a cost to record, not a
    license; the realigned rule is [Value bindings](#value-bindings). Two
    further alternatives stay rejected: eager acquisition for every type,
    because a non-`Copy` type such as `Core.Buf` cannot be copied and an
    implicit deep copy is the cost the values design says values exist to
    avoid, where a type that wants copies says so with `value_rep = const Self`;
    and a structural, compiler-derived `Core.SharedImmutable`, because its
    soundness rests on declaration conditions and a body rule whose corners an
    opt-in states as the author's obligation. (The superseded 2026-10-12 bullet
    read: "**Preventing all mutation of borrowed objects.** Proposal p005434's
    plan for the strict dialect, taken literally, would reject a `Plain`-field
    write through any alias during a non-`Plain` value binding and would make a
    value binding of `i32` a loan. The first is rejected because it prevents
    nothing a memory-safety argument needs and would reject the aliased `Set`
    of EX-M-1 whenever a value binding of the container is live; the second
    contradicts the eager copy the toolchain performs today (EX-M-4a). The
    eager-copy-for-every-type rule is the recorded alternative of D-SAFE-17 and
    its break condition.")

That decision is final; this page specifies the chosen design rather than
relitigating it.

## External facts

Claims about tools outside this repository appear only here, with a status
(D-SAFE-22). No normative rule on this page depends on an UNVERIFIED item; the
facet definitions are the fork's own, and the rows below are what they were
modeled on.

| Fact | Used by | Status |
| --- | --- | --- |
| Ante's shared-mutable references (spelled `ref` and `mut`, with `imm` and `uniq` the single-owner kinds) forbid operations that could invalidate: returning an element reference of a shape-unstable container, taking a reference to a tagged union's field, and reaching past a pointer boundary each require a single-owner reference; shared references do not implement `Send` | M3's model (the strategy's "safe, shared mutability in the Ante Language"), the `T*` row of the facet table | VERIFIED 2026-10-12 against antelang.org/blog/safe_shared_mutability, the page proposal p005914 links; the fork's rule is M3 with `Core.Plain`, which is broader than Ante's three cases |
| Rust's `Send` and `Sync` are auto traits implemented structurally when every field implements them; raw pointers are neither; `T: Sync` iff `&T: Send` | The soundness argument behind D-SAFE-16's structural facets; the `exclusive T*` and `const T*` rows | VERIFIED 2026-10-12 against the Rustonomicon, "Send and Sync" |
| Rust's `Cell` and `RefCell` provide interior mutability in single-threaded code and are not `Sync`; `RefCell` tracks borrows at run time and panics on a violation | `Core.Guarded(T)` as the fail-stop analogue of `RefCell`; the `Guarded` row of the facet table | VERIFIED 2026-10-12 against the Rust standard library documentation for `std::cell` |
| Swift's law of exclusivity, "two accesses to the same variable are not allowed to overlap unless both accesses are reads", is enforced statically for locals, `inout` parameters and struct properties and dynamically for class properties, globals and escaping variables | The rejected alternative "dynamic exclusivity on every access" | VERIFIED 2026-10-12 against Swift evolution proposal SE-0176; whether dynamic enforcement is on in release builds is not stated there and the fork does not depend on it |
| Clang's Thread Safety Analysis attributes are `capability`, `guarded_by`, `pt_guarded_by`, `requires_capability`, `acquire_capability`, `release_capability` and their shared and try variants; `guarded_by` "declares that the data member is protected by the given capability" | The imported-C++-type row of the facet table (D-SAFE-18's `Sync` import rule) | VERIFIED 2026-10-12 against clang.llvm.org/docs/ThreadSafetyAnalysis.html; the importer's mapping is a stage-5 item |

## References

-   Proposal
    [p005914: Updating Carbon's safety strategy](/proposals/p005914-updating-carbon-s-safety-strategy.md),
    whose shared-and-exclusive mutable pointers, Swift-staged data-race
    safety and iterator-invalidation-by-exclusive-methods commitments this
    page makes checkable.
-   Proposal
    [p005434: `ref` parameters, arguments, returns and `val` returns](/proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md),
    for `ref`, `addr` and the mutation restriction on borrowed objects that
    D-SAFE-17 keeps as its rule (realigned 2026-10-28, SAFE-2: W-348; this text
    read "that D-SAFE-17 narrows").
-   Proposal
    [p004880: Safety milestones and a 2025 roadmap](/proposals/p004880-safety-milestones-and-a-2025-roadmap.md),
    whose "compile-time and type-system based temporal and mutation safety"
    is the commitment the milestone bullet discharges.
-   [values.md](/docs/design/values.md) on value bindings, acquisition and the
    erroneous reading, with its dated note;
    [classes.md](/docs/design/classes.md) on destructors and the
    compiler-determined facets; [unions.md](/docs/design/unions.md) on field
    rules and reads;
    [fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md)
    for the 0.1 memory model and `Cpp.std.atomic(T)`.
-   [Safety](README.md): the soundness model, the safety modes, the diagnostic
    matrix, the pointer-kinds table, the C++ call allowlist and the data-race
    section; the [terminology](terminology.md) page's mutation safety and
    data-race safety entries.
-   The sibling category pages: [Temporal safety](temporal_safety.md) for the
    pointer kinds, loans and T1 to T8, [Type safety](type_safety.md) for
    `unsafe as` and the unsafe operations,
    [Initialization safety](initialization_safety.md) for `~x` and
    `Core.Relocatable`, [Spatial safety](spatial_safety.md) for the fail-stop
    convention, and [Safe-Rust interop](rust_interop.md) for `&Shared<T>` and
    `&SharedView<T>`.
-   Fork decision [F-013](/fork/decision-log.md) and the synthesized plan
    [fork/safe/plan.md](/fork/safe/plan.md), whose design-panel record is the
    option paper for this area.
