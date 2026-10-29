# Temporal safety

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Vocabulary](#vocabulary)
-   [Pointer kinds and receivers](#pointer-kinds-and-receivers)
-   [`ref` bindings](#ref-bindings)
-   [Rules T1 to T8 and the Store rule](#rules-t1-to-t8-and-the-store-rule)
    -   [T1: Ownership](#t1-ownership)
    -   [T2: Forming loans](#t2-forming-loans)
    -   [T3: Liveness](#t3-liveness)
    -   [T4: Conflicts](#t4-conflicts)
    -   [T5: `bound`](#t5-bound)
    -   [The Store rule](#the-store-rule)
    -   [T6: The unsafe boundary](#t6-the-unsafe-boundary)
    -   [T7: Temporaries](#t7-temporaries)
    -   [T8: Codegen honesty](#t8-codegen-honesty)
-   [The first enforceable subset](#the-first-enforceable-subset)
-   [`bound`, `bound(a)` and `unsafe class`](#bound-bounda-and-unsafe-class)
-   [Temporaries](#temporaries)
-   [Relocation and `~x`](#relocation-and-x)
-   [The unsafe-code contract](#the-unsafe-code-contract)
-   [Diagnostics](#diagnostics)
-   [Worked examples](#worked-examples)
    -   [EX-TM-1: A `bound` result borrows both arguments](#ex-tm-1-a-bound-result-borrows-both-arguments)
    -   [EX-TM-2: A dangling return](#ex-tm-2-a-dangling-return)
    -   [EX-TM-3: Liveness and non-invalidating writes](#ex-tm-3-liveness-and-non-invalidating-writes)
    -   [EX-TM-4: The regression set](#ex-tm-4-the-regression-set)
    -   [EX-TM-5: The exclusive pointer and the first enforceable subset](#ex-tm-5-the-exclusive-pointer-and-the-first-enforceable-subset)
    -   [EX-TM-6: Named lifetimes](#ex-tm-6-named-lifetimes)
    -   [EX-TM-7 and EX-TM-7b: Temporaries](#ex-tm-7-and-ex-tm-7b-temporaries)
    -   [EX-TM-8: The review regression set](#ex-tm-8-the-review-regression-set)
    -   [EX-TM-9: A `ref` binding through a shared pointer](#ex-tm-9-a-ref-binding-through-a-shared-pointer)
-   [C++ interop consequence](#c-interop-consequence)
-   [Implementation staging](#implementation-staging)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [External facts](#external-facts)
-   [References](#references)

<!-- tocstop -->

## Overview

[Temporal safety] is the property that memory accesses occur only within the
valid lifetime of the intended memory object. Carbon reaches it at compile time
through its type system, with no reference counting, garbage collection,
quarantine or pointer tagging at run time: every pointer value, `ref` binding
and pointer-carrying value carries a _loan set_, a record of the storage it may
refer to, and a Strict function body is accepted only when every loan is dead
before the storage it names is. This page defines the three pointer kinds, the
loans and the rules T1 to T8 over them, the `bound` contract on signatures, the
Store rule, the unverified loan set ⊥ that marks the unsafe boundary, and the
first enforceable subset that ships before loan sets exist. The
[mutation safety](mutation_safety.md) page restates the same lattice from the
pointer's side and owns the no-invalidation rule and `Core.Plain`; the
[type safety](type_safety.md) page owns the spelling of the unverified
dereference; the [safety strategy](README.md) states the
[soundness model](README.md#soundness-model) the rules are checked under, the
[safety modes](README.md#safety-modes), and the
[pointer kinds at a glance](README.md#pointer-kinds-at-a-glance) table that is
repeated below.

[temporal safety]: /docs/design/safety/terminology.md#temporal-safety

This page was fixed by fork decision [F-013](/fork/decision-log.md),
sub-decisions D-SAFE-7, D-SAFE-8, D-SAFE-10, D-SAFE-11 and D-SAFE-12, with the
relocation rule of D-SAFE-13, synthesized in
[fork/safe/plan.md](/fork/safe/plan.md). No part of this page is implemented in
the toolchain (fork workstream SAFE-1, stage 0); see
[Implementation staging](#implementation-staging). The toolchain today has no
loan analysis and no borrow diagnostic, and the tokens `bound`, `addr` and
`exclusive` do not exist: toolchain/lex/token_kind.def declares `unsafe` as a
keyword and none of the three. `Core.Box`, `Core.Relocatable` and
`Core.Lifetime`, named below, are D-SAFE-20 library residue and are not in the
0.1 prelude. Every pointer in today's toolchain behaves as an unmarked
Permissive pointer, and today's `ref` bindings are checked only by the rule of
proposal p005434 that a `ref` binds a durable reference expression. File and
line citations are against trunk 0bdce60a5 unless a citation says otherwise; the
examples marked "today's syntax" were compiled on the 2026.10.12 nightly
toolchain and their outcomes are stated with each example. The `ref` bindings
section, T2, T4, T8, T5(a) and (d), and the examples they decide were realigned
2026-10-28 by fork workstream SAFE-2 to proposal p005434's rules: every `ref`
binding is `nocapture` and `noalias`, Strict prevents mutation of borrowed
objects, and each `bound` argument is immutable for the duration of the returned
result (W-347, W-348, W-349; fork/safe/safe2-plan.md); each realigned passage
quotes the text it supersedes.

## Vocabulary

The rules use seven words, fixed by D-SAFE-10, and two more, _closed_ and
_open_, added 2026-10-28 by SAFE-2 (W-347, W-348).

-   A _place_ is the storage of a durable reference expression
    ([values: reference expressions](../values.md#reference-expressions)): a
    `var`, a `var` parameter, a field, a materialized temporary, or the storage
    behind a pointer. Places nest: `x.f` and `*p` are places within the places
    `x` and `*p`'s pointee, and `root(P)` names the outermost place that `P`
    lies within, which is the one whose lifetime bounds `P`'s.
-   A _loan_ is a triple of a place, a _kind_ and an _origin_. The kind is
    _exclusive_, _shared_ or _frozen_. A frozen loan is the loan of a borrowed
    object or of a `const` `ref`, under which no path writes the place's
    storage, or the loan a call's result holds on the pointee of a `bound` `T*`
    or `const T*` argument, under which no path but the result and the carriers
    copied from it writes the pointee, the result's own access being at the kind
    T5(a) gives its parameter (T5(d); added 2026-10-28, SAFE-2: W-348, W-349);
    the origin is the expression that formed the loan, which the diagnostics
    name.
-   A _loan set_ is what every pointer value, `ref` binding, value binding and
    value of a class type transitively containing a pointer carries. Loans are
    a property of values, not of types (p005434, "Part of the expression type
    system, not object types"): `T*` stays the single indirection construct of
    [values](../values.md#pointers), and no loan appears in a type.
-   The loan set ⊥, read _unverified_, means the checker knows nothing about
    the storage the pointer names. A ⊥ pointer may be copied, compared, stored
    and passed, and every use of its pointee is the `unsafe` operation of T6.
-   The empty loan set, read _free_, means the storage outlives every possible
    use: a global, or allocator-owned storage held by Permissive code and
    handed out behind a Strict signature. Free is the opposite of ⊥: a free
    pointer needs no marker anywhere.
-   An _interior loan_ is a loan reached through an owning indirection: a
    `Core.Buf`'s elements are reached through its `ptr` field and a `Core.Box`'s
    pointee through its handle, so a view of either is a loan on the owner,
    and an invalidating operation on the owner kills it.
-   A place is _closed_ in a function body when every carrier of a loan on it
    is in the body's view: the body's own owners, local `var`s, `var`
    parameters and temporaries, and their sub-objects, the referents of its
    `ref` parameters and of `ref self`, the pointees of its `exclusive T*`
    parameters, and every place reached through a carrier whose loan set holds
    only closed places, such as `*p` for a local `let p: T* = &x;`. Every other
    place is _open_: one reached through a `T*` or `const T*` parameter or
    `addr self`, through a pointer loaded from memory or returned by a call
    whose loan set is not closed, through a free loan, a global among them, or
    through ⊥. An
    exclusive or a frozen loan is formed on a closed place, where T4 sees every
    carrier; on an open place it is an `unsafe` operation, except a frozen loan
    on a `Core.SharedImmutable` type, whose shared-path writes the mutation
    page's M3 rejects (M8). A carrier of a
    closed place cannot escape it: the Store rule keeps a loan on a local out
    of every destination it does not outlive, and T5(b) keeps a non-`bound`
    parameter in (added 2026-10-28, SAFE-2: W-347, W-348).

The kinds, the places and the loan sets together give one lattice, which the
mutation page restates as exclusive-XOR-shared access per place. Carbon's
non-null rule is unchanged: there are no null pointers
([pointer types](../README.md#pointer-types)), and a pointer that may be absent
is `Core.Optional(T*)` ([type safety](type_safety.md), TY4).

## Pointer kinds and receivers

There are three pointer kinds (D-SAFE-7). `T*` is the shared-mutable kind: any
number of `T*` may alias one object, and only the non-invalidating operations
of the mutation page's rule M3 are permitted through one. `exclusive T*` is the
NEW exclusive-mutable kind, the explicit pointer kind proposal p005914 names
beside the shared one, through which everything is permitted. `const T*` is the
shared-const kind, and `const` keeps exactly the API-subsetting meaning of
[`const`-qualified types](../values.md#const-qualified-types): nothing new is
read into it, and in particular `const T*` is not an "immutable" or "frozen"
view, because a `Plain` field of the object may be written through another
alias while a `const T*` to it is live.

| Kind | Spelling | Formed by | Loan kind | Through it you may | Receiver form | Rust analogue (D-SAFE-19) |
| --- | --- | --- | --- | --- | --- | --- |
| exclusive-mutable | `exclusive T*` (NEW) | `&x` on an owner, a `ref`, or `*p` for `p: exclusive T*` | exclusive | everything: read, write, invalidate (`ref self` calls, assignment of non-`Plain`, `~`, destroy) | `ref self: Self` | `&mut T` |
| shared-mutable | `T*` | downgrade from `exclusive T*`; `&x` on a place already under shared access; C++ `T&` | shared | read; write `Plain` fields; `addr`/`const` methods; form further shared loans | `addr self: Self*` (restored) | `&Shared<T>` |
| shared-const | `const T*` | conversion from either kind; C++ `const T&` | shared (const) | read; `const` methods | `ref self: const Self`, by-value `self` | `&SharedView<T>` (`&T` only under the D-SAFE-19 proviso) |
| unverified (any kind) | the same spellings, loan set ⊥ | `unsafe as` from non-pointers, C++ results, union reads and `unsafe &u.f`, `unsafe class` fields | ⊥ | copy, compare, store, pass; `unsafe *p` to use | — | raw pointer |

Every `ref` binding is exclusive access to its referent, or a frozen read of it
when its type is `const`, whatever its source, and a value binding of a type
whose value representation is not a copy binds a borrowed object, frozen for
the binding's lifetime. Through `T*` or `const T*` such a binding is formed
only on a closed place or, for a frozen one, a `Core.SharedImmutable` type, and
is an `unsafe` operation otherwise, so the `const T*` row's receivers meet that
rule when they are called through a shared pointer (T2); and the `T*` row's
`Plain` writes exclude every assignment whose type holds a
`Core.SharedImmutable` sub-object, a `Core.String`, a `Core.Slice(T)` for a
`Core.Freeze` `T`, or a struct, tuple, array or class holding one, which only
an exclusive path makes (the mutation page's M3; realigned 2026-10-28, SAFE-2:
W-347, W-348). A built-in operator's `ref` operand, an assignment's among them,
lives for the one operation and is established on any place, M3 deciding what
the operation may do ([`ref` bindings](#ref-bindings); amended 2026-10-29,
re-review round 2: RR1-M1).

`&x` on a place under exclusive access — an owner, a `ref` binding, or `*p` for
`p: exclusive T*` — yields `exclusive T*`. The conversions between kinds form a
lattice in which every arrow is a downgrade and nothing converts upward except
`unsafe as`:

| From | To `exclusive T*` | To `T*` | To `const T*` |
| --- | --- | --- | --- |
| `exclusive T*` | identity | implicit; the loan becomes shared (a reborrow, T2) | implicit; the loan becomes shared |
| `T*` | `unsafe as` only | identity | implicit |
| `const T*` | `unsafe as` only | `unsafe as` only: the one cast that removes `const` (toolchain/check/convert.cpp:1843-1846, which answers the TODO at core/prelude/operators/as.carbon:62) | identity |

An `unsafe as` between pointer kinds is an `unsafe` operation of
[type safety](type_safety.md); it preserves the loan set of its operand, so it
never extends a lifetime, and its obligation when it upgrades a kind is that no
other access to the object is live while the result is used; the type page's
closed list of unsafe operations carries that upgrade as its own row (amended
2026-10-12, document-review fold: D-4).

The receiver forms follow the kinds. `ref self: Self` is exclusive access, as
proposal p005434 defines it. `addr self: Self*` is the shared-mutable receiver,
restored for exactly the purpose p005434 reserves it under "Restore `addr`": "to
allow the `self` parameter to use one of the pointer semantics we create as part
of the upcoming memory safety design". Its declared type is the pointer type the
body sees, `Self*`, rather than the historic `addr self: Self` that
third_party/examples/re2/re2.carbon:769 still spells in a file no target builds,
because the receiver is the address-taking form and the body uses it as a shared
pointer. `ref self: const Self` and by-value `self` are const access, and a call
of either binds `self` under the rules of [`ref` bindings](#ref-bindings) and T2
(realigned 2026-10-28, SAFE-2: W-347, W-348). The method classification this
gives — which methods may invalidate, which may only write `Plain` fields — is
rule M4 of the [mutation safety](mutation_safety.md) page.

`T*` is the shared kind rather than the exclusive one for two reasons that are
facts about the repository. C++ `T&` is translated to `T*`
([bidirectional interoperability](../README.md#bidirectional-interoperability-with-c-and-c)),
and C++ references alias freely. The prelude's own view types hold `T*`: the
`ptr` field of `Core.Slice(T)` (core/prelude/types/slice.carbon:58) and of
`Core.Buf(T)` (core/prelude/types/buf.carbon:62) are shared views of one
block, with `Buf.AsSlice` and `Slice.Subslice` producing more of them. An
exclusive `T*` would turn every one of those into an unverified `noalias`
claim, which is the fatal flaw both judges found in the attempts that chose
otherwise ([Alternatives considered](#alternatives-considered)).

## `ref` bindings

Every `ref` binding is exclusive access to its referent for its lifetime, as
proposal p005434 states: "The address of a `ref` binding is `nocapture` and
`noalias`" (p005434:83), where `noalias` "means like C `restrict`; you can't
observe mutations through aliases; mutation through a restricted pointer is not
observable through another pointer" (p005434:850-852). A `ref` of a `const`
type is the read-only case: its loan is frozen, so no path writes the referent
while it lives and other paths may read it; any other `ref` holds an exclusive
loan, so no other path reads or writes the referent. A `ref` binding not
marked `bound` does not escape, `captures(none)`, and one marked `bound`
escapes only into the result, `captures(ret: address, provenance)`
(p005434:846-848; T5(b)). The binding's source does not change this, and the
proposal's rule that "A `ref` binding may only bind to a durable reference
expression or an expression that can be converted to one. The bound durable
reference expression must outlive the `ref` binding." is kept; the source
decides only whether the checker can establish it. On a closed place
([Vocabulary](#vocabulary)), an owner, the referent of a `ref`, the pointee of
an `exclusive T*`, or `*p` for a local `p` whose loans are closed, the binding
is a checked reborrow: forming it suspends every other carrier of the place
(T2), and T4 rejects any use of them that the binding excludes. A `const` `ref`
on an open place of a `Core.SharedImmutable` type is checked the same way. Any
other `ref` on an open place, `*p` for a `T*` or `const T*` parameter, a
pointer loaded from memory, a global, a free or ⊥ pointer, is an `unsafe`
formation, spelled at the binding as T6 spells a binding through a ⊥ carrier
(`let ref r: T = unsafe *p;`, or `unsafe F(ref *p)` for a `ref` argument),
whose obligation is the one the proposal gives unsafe code, to "adhere to just
the `noalias` restrictions" (p005434:861-862); unmarked, it is
`StrictRefFromShared` in Strict and its twin `PermissiveAliasedExclusive` in
Permissive. EX-TM-9 is the proposal's own example through a shared pointer.

The `ref` operand of a built-in operator is exclusive by construction.
Proposal p005434 passes to a `ref` parameter the first operand of the
assignment operators and of `++` and `--`, the operand of `&`, the object of
member access and the first operand of indexing (p005434:302-318), and the
[assignment](../assignment.md#syntax) design's first operand "is passed to a
`(ref self: Self)` parameter" whatever its form, "A dereference of a pointer"
and "Member access naming a field" among them (assignment.md:76-82). Where the
operator's implementation is built in, that `ref` lives for the one operation
and nothing else is evaluated while it does, so no other path observes the
referent during it, on any place, open ones included: the checker establishes
it with no marker, the `ref` forms no loan of its own, neither the mutation
page's M3(d) exclusive-receiver call nor its M3(e) exclusive loan, the loans of
the operation's result, `&x`'s and a member access's sub-loan, being T2's, and
M3 alone decides what the operation may do through a shared path. An
implementation is built in when it gives a built-in type the semantics the
[assignment](../assignment.md#built-in-types) design states, `=` on integers,
floating-point types, `bool` and pointers, compound assignment on integers and
floating-point types, and `++` and `--` on integers (assignment.md:146-157),
the prelude's impls of those, "provided for built-in types as necessary to give
the semantics described above" (assignment.md:168-170), counting as built in
whatever their body, `Inc`'s `self += AsInt(1);`
(core/prelude/types/int.carbon:395-399, uint.carbon:457-461) as much as
`fn Op(ref self, other: Self) = "int.sadd_assign";` (int.carbon:331); when it
is the assignment of a tuple, struct, array, choice type or class with no
user-written `AssignWith` impl, whose rules assignment.md:159-161 leaves a
TODO; and when it is the language's own `&`, member access naming a field or
indexing of an array (amended 2026-10-29, re-review round 2: RR1-m1, where
this read "Where the operator's implementation is built in, the language's own
or a prelude impl whose body is a builtin, such as `fn Op(ref self, other:
Self) = "int.sadd_assign";` (core/prelude/types/int.carbon:331), that `ref`
lives for the one operation" and "the checker establishes it with no marker,
and the mutation page's M3 alone decides"). So `q->n = 2` for `q: T*` is a
`Plain` write that M3 permits, and `*q = "longer"` for `q: str*` is
`StrictSharedImmutableWrite`. The `ref self` of a user-written impl of an
operator interface is a `ref` binding under this section's rule, and its call
through a shared path is M3(d)'s exclusive-receiver call,
`StrictInvalidatingThroughShared` (amended 2026-10-28, document-review fold:
R1-M1).

A `ref` _return_ is not a binding. The proposal's
`Valid1(bound p: i32*) -> ref i32 { return *p; }` and
`ValToRef(bound y: C) -> ref D { return *y.ptr; }` return a reference
expression to an open place and stay valid in both modes; the call's result
has the kind of its loans, shared for `Valid1`'s `T*` parameter and frozen for
`ValToRef`'s by-value `y` of a borrowed type (T5(a)), a kind that keeps `y`'s
own storage unwritten while the result lives, and the reference is to `*p` or
`*y.ptr`, a place reached through a pointer and outside the argument's
storage, whose uses the mutation page's M3 governs (amended 2026-10-28,
document-review fold: R1-m2). A call of either is checked by T5(d): while the
result lives, the `bound` argument is written by no path but the result, so a
call through a shared pointer to an open place of a type that is not
`Core.SharedImmutable`, `Valid1(p)` for a parameter `p: i32*`, is
`StrictBorrowFromShared` (added 2026-10-28, SAFE-2: W-349). A result whose loan
set mixes kinds has the
**weakest** kind: frozen if any loan in the set is frozen, and otherwise shared
if any is shared, frozen counting below shared (T5(a); amended 2026-10-28,
document-review fold: R1-m2). The proposal's
`Conditional(b: bool, bound ref r: C, bound p: C*) -> ref C` carries the set
`{(r, exclusive), (*p, shared)}`, so its result is a shared-kind reference
expression, and T4 applies to every place in the set. Binding such a result
with `let ref` is a `ref` binding like any other: checked when every place in
the set is closed, `unsafe` otherwise. The program `Pick`/`UsePick` of EX-TM-8
is the closed case: `z` would be an exclusive `ref` on both `x` and `y`, and
`q2`'s shared loan on `y`, live on the next line, excludes forming it, so the
`let ref z` is `StrictSharedBorrowInvalidated` (T4; amended 2026-10-28,
document-review fold: R1-m1, where this read "which conflicts with the live
`q2` (`StrictExclusiveBorrowConflict`)").

> **Realigned (fork amendment 2026-10-28, SAFE-2: W-347, F-013 D-SAFE-8).** This
> section states proposal p005434:83 for every `ref` binding. The superseded
> 2026-10-12 section read, in the sentences that stated the narrowed rule: "A
> `ref` binding inherits the kind of its source (D-SAFE-8). A `ref` formed from
> a place is exclusive access, as p005434 states and this design keeps: "A `ref`
> binding may only bind to a durable reference expression or an expression that
> can be converted to one. The bound durable reference expression must outlive
> the `ref` binding."" / "A `ref` formed from `*p` inherits `p`'s kind:
> exclusive from `exclusive T*`, shared-mutable from `T*`, under which the
> mutation page's M3 applies to every use of the binding, and const from `const
> T*`. So the proposal's `Valid1(bound p: i32*) -> ref i32 { return *p; }` and
> its `ValToRef(bound y: C) -> ref D { return *y.ptr; }` stay valid in both
> modes, the result being a shared-kind `ref`: a `ref` through which an
> invalidating operation is rejected but a `Plain` write is not." / "A `ref` or
> a call result whose loan set mixes kinds has the **weakest** kind: shared if
> any loan in the set is shared, const if any is const." / "The proposal's
> `Conditional(b: bool, bound ref r: C, bound p: C*) -> ref C` carries the set
> `{(r, exclusive), (*p, shared)}` and so is a shared-kind `ref`, and T4 applies
> to every place in the set." / "The program `Pick`/`UsePick` of EX-TM-8 is this
> rule's example: a non-`Plain` assignment through such a `ref` is
> `StrictInvalidatingThroughShared` regardless of whether any other view is
> live." Its blockquote read: "**Narrowing (fork amendment 2026-10-12, F-013
> D-SAFE-8).** Proposal p005434 states (p005434:83) that "the address of a `ref`
> binding is `nocapture` and `noalias`". This design emits `noalias` and
> `captures(none)` only for exclusive-kind refs, and only under the conditions
> of T8 below; a shared-kind `ref` carries neither attribute. The proposal's
> sentence is kept for the exclusive kind and narrowed for the rest, because a
> shared-kind `ref` is, by construction, one alias among many." (The second and
> sixth sentences quoted in full, amended 2026-10-28, document-review fold:
> R2-m2.)

## Rules T1 to T8 and the Store rule

The rules are D-SAFE-10. They are stated for a Strict function body; a
Permissive body runs the same analysis and receives the warning twins of
[Diagnostics](#diagnostics) instead of errors.

### T1: Ownership

Every object has exactly one owner: a `var`, a `var` parameter, a field, a
temporary, or the allocator behind a free pointer. There is no reference
counting and no garbage collection, which proposal p005914 rules out by
default; a pointer never keeps an object alive, and the lifetime of an object
is the lifetime of its owner's place. Destroying the owner is the invalidating
operation that ends every loan on the object, interior loans included.

### T2: Forming loans

A loan is formed by the operations below, with the kind each gives.

-   `&x` on a place under exclusive access forms an exclusive loan on `x`;
    conversion of the result to `T*` or `const T*` downgrades the loan to
    shared.
-   `&x` on a place already under shared access — one with a live shared loan
    on it — forms a shared loan on `x`: the result is `T*` and no exclusive
    loan is formed, so T4's exclusion of exclusive loans does not fire, which
    is how `UsePick` of EX-TM-8 takes `&y` twice while `q` is live (amended
    2026-10-12, document-review fold: D-14).
-   `let ref r = x;` forms an exclusive loan on `x`, and a `ref` of a `const`
    type a frozen one; a `ref` formed from `*p` or from a call's result forms
    the same loan on every place in the source's loan set when each is closed,
    suspending the source carrier as the reborrow clause below does, and is the
    `unsafe` formation of [`ref` bindings](#ref-bindings) otherwise (realigned
    2026-10-28, SAFE-2: W-347; this bullet read "`let ref r = x;` forms an
    exclusive loan on `x`").
-   A value binding of a type whose value representation is not a copy binds a
    borrowed object and forms a frozen loan on it for the binding's lifetime, on
    a closed place, or on an open place when the type is `Core.SharedImmutable`
    (D-SAFE-17, rule M8 of the mutation page); a value binding of a
    copy-represented type holds no loan, the value having been read; and a value
    binding from an initializing expression — a materialized temporary, the
    third source
    [values](../values.md#binding-patterns-and-local-variables-with-let-and-var)
    names — takes ownership of the materialized storage, the `var` rule applied
    to `let`, and holds no loan on it. The loans carried _by_ the bound value
    are unaffected in every case (realigned 2026-10-28, SAFE-2: W-348; the
    superseded 2026-10-12 text read: "A value binding of a non-`Plain` type,
    from `*p` or from an owner, forms a shared loan on the bound object for the
    binding's lifetime (D-SAFE-17, rule M8 of the mutation page); a value
    binding of a `Plain` type copies eagerly and holds no loan; and a value
    binding of a non-`Plain` type from an initializing expression").
-   `p->f`, `(*p).f`, `case .Some(ref v)`, `Core.Slice.Subslice`,
    `Core.Slice.FromArray` and `Core.Buf.AsSlice` form _sub-loans_: loans on a
    place within the place of their operand, at the operand's kind. A loan
    reached through an owning indirection — a `Buf`'s elements, a `Box`'s
    pointee — is an interior loan on the owner.

**Copies preserve loans.** A copy, a relocation, an `ImplicitAs` or `As`
conversion, or a `Copy.Op` of a loan-carrying value carries the same loan set.
The prelude's identity conversion `impl forall [T: Copy] T as ImplicitAs(T)`
(core/prelude/operators/as.carbon:37-39) and every `Copy` and `ImplicitAs` impl
are not loan boundaries, so `let t = s; return t;` of a view is exactly
`return s;`. The rule in T5(a) that a function with no `bound` parameter returns
a free value applies to functions that _produce_ values, never to the identity
conversions a `let`, a `return` or an argument pass goes through. The programs
`Launder1` to `Launder5` of EX-TM-8 are this clause's regression set.

**A copy of an exclusive carrier is never a second live exclusive carrier of
the same loan.** A same-kind copy — `let q: exclusive i32* = p;` for
`p: exclusive i32*` — is a move of the loan: the source is dead until the
copy's last use (T3). An exclusive carrier reached through a shared path — a
`Plain` field of type `exclusive T*` read through a shared pointer — is copied
as a reborrow at shared kind. T8 therefore never sees two live exclusive
carriers of one loan.

**Reborrow.** Forming a shared loan from an exclusive carrier — the
`exclusive T*` to `T*` downgrade, an `addr self` call, `&*p` at shared kind —
_suspends_ the carrier's exclusivity: until every derived loan is dead the
carrier may be used only at shared kind (reads, `Plain` writes, `addr` and
`const` methods, further shared loans), and an invalidating use of it is
`StrictSharedBorrowInvalidated`. This is how the mutation page's EX-M-1 reads:
`vec->Get(0)` while a derived view lives is a use at shared kind, a `const`
call whose by-value `bound self` forms the frozen loan the next sentence names,
and `vec->Push(3)` is legal only once every derived view is dead. A frozen loan
derived from an exclusive carrier, a by-value `bound self` of a borrowed type
or a value binding of `*p`, suspends it further: until the frozen loan is dead
the carrier may only be read, so EX-M-1's `a->Set(0, 5)` while `first` lives
is `StrictBorrowedObjectMutated` (realigned 2026-10-28, SAFE-2: W-348, W-349).
A by-value `bound self` forms no shared loan, T5(a) giving it frozen for a
borrowed type and no loan on the object for a copy-represented one (amended
2026-10-28, document-review fold: R1-m2; the superseded 2026-10-12 text read
"the `exclusive T*` to `T*` downgrade, a `bound self` by value, an `addr self`
call, `&*p` at shared kind" and "`vec->Get(0)` while a derived view lives is a
shared use").

### T3: Liveness

A loan is live from its formation to the last use of any carrier of it, where
a carrier is a pointer value, `ref` binding, value binding or loan-carrying
class value that holds the loan. Liveness is computed over SemIR's block graph
rather than over lexical scopes, which is the non-lexical-lifetimes rule of the
Rust borrow checker ([External facts](#external-facts)): a loan ends at the
last use, not at the closing brace. At scope exit, every loan on the storage of
a `var` being destroyed must be dead, else `StrictBorrowOutlivesPlace`.
EX-TM-3 shows a loan ending at its last use and the invalidating assignment
that is legal after it.

### T4: Conflicts

A live exclusive loan excludes every other access to overlapping places, except
through the suspended carrier at the kind the reborrow clause of T2 allows: a
second loan or a direct use while one is live is
`StrictExclusiveBorrowConflict`. A live shared loan excludes exclusive loans and
invalidating operations on overlapping places — destruction, `~`, assignment of
a non-`Plain` value, a `ref self` call, formation of an exclusive loan, the
mutation page's rule M3 — and an invalidating operation on a place `P` kills
every interior loan on `P`: the operation is `StrictSharedBorrowInvalidated`
while such a loan is live. A live frozen loan excludes everything a shared loan
excludes and every other write to the place's storage through any carrier: a
`Plain` assignment, an `addr` method call, and passing a carrier of a shared or
exclusive loan on an overlapping place, a non-`const` pointer or a value that
carries one, to a call that could write through it; such a write is
`StrictBorrowedObjectMutated`, and the invalidating ones stay
`StrictSharedBorrowInvalidated`. The one carrier a frozen loan does not exclude
is its holder when the holder may write: the result of a call that holds a
`bound` pointer argument's pointee (T5(d)), with the carriers copied from it,
writes the pointee as the result's own kind allows, and only it does. For a call
result or reference expression whose loan set mixes kinds, T4 is applied to
every place in the set at the weakest kind, frozen counting below shared
([`ref` bindings](#ref-bindings)). T4 and the mutation page's rule M2 are one
rule seen from two sides: T4 is stated over loans and M2 over the access a place
is under (realigned 2026-10-28, SAFE-2: W-347, W-348, W-349; the superseded
2026-10-12 text read "except through the suspended carrier at shared kind (the
reborrow clause of T2)" and "For a carrier whose loan set mixes kinds, T4 is
applied to every place in the set at the weakest kind
([`ref` bindings](#ref-bindings)).", and named no frozen loan).

### T5: `bound`

T5 is the `bound` contract of D-SAFE-11, stated in its own section,
[`bound`, `bound(a)` and `unsafe class`](#bound-bounda-and-unsafe-class).

### The Store rule

Storing a loan-carrying value into a place `P` — a field write, a store through
a pointer, a container insert through a `bound`-free API, a write to a global
— requires every loan in the value to outlive `root(P)`: by lexical nesting
for locals, by T5 for parameters. A free or ⊥ destination accepts only free
loans. A store that fails this is `StrictStoreOutlivesSource`. The rule is what
makes `let h: Holder* = GetGlobalHolder(); h->p = &y;` an error: the loan on
the local `y` does not outlive the global the pointer reaches. It is attempt B's
rule, grafted by judge 2 as the repair for the hole in attempt A's return-only
`bound` contract, and the program `Store` of EX-TM-4 is its standing
regression test.

### T6: The unsafe boundary

The following values carry the loan set ⊥:

-   the result of `unsafe as` from a non-pointer;
-   the result of any unannotated C++ call, and every pointer-typed field read
    from an imported C++ type, because the Carbon checker never saw the C++
    store (the second clause amended 2026-10-12, document-review fold: D-7,
    with D-SAFE-18 amended identically);
-   anything read through an unverified pointer;
-   a value of pointer-carrying type read from a union field (`unsafe u.p`),
    and the pointer `unsafe &u.f` itself, ⊥ on formation for every field type:
    the union read discharges only the punning obligation
    ([unions: reads](../unions.md#reads)), a write `u.n = 0x1234` through
    another field is safe and unmarked, so the loans stored in `u` say nothing
    about the bytes read back, and a pointer into a union aliases every field
    of it ([unions: aliasing](../unions.md#aliasing), unions.md:440-441), so
    `unsafe &u.f` is ⊥ regardless of which field it names;
-   every pointer field of an `unsafe class` (T5(g));
-   the result of a `bound` call one of whose `bound` arguments is ⊥.

**A marked `unsafe fn` call is not in that list** (amended 2026-10-12,
document-review fold: D-1; D-SAFE-10 amended identically). The result of a
marked `unsafe fn` call carries the loan set its signature gives under T5(a),
free when the function has no `bound` parameter, because the `unsafe` on the
call takes on the callee's stated obligation, lifetime included where the doc
comment states one: for `unsafe Core.Slice(T).Make(p, n)` the obligation is
that the elements outlive the view, so the view is free and no later `v[i]`
through it needs a marker, which is what makes that call the single audit line
of a migrated buffer API ([spatial safety](spatial_safety.md)). The result of
an unannotated C++ call stays ⊥ because its marker's obligation, that the
callee saves no pointer, says nothing about what the result points at. A free
result hides from the checker which storage it reaches, so the marker also
takes on what a frozen loan formed through it would otherwise need: while a
frozen loan formed through the result, or through a carrier derived from it,
is live (T3), whatever carries the loan, a value binding of a borrowed object,
a `const` `ref` or the result of a call that keeps it (T5(d)), no path other
than the result and its copies writes the storage that loan covers (amended
2026-10-29, re-review round 2: RR1-B1, where this read "while a value binding
of a borrowed object, or a `const` `ref`, formed through the result or a copy
of it lives, no path other than the result and its copies writes the storage
that binding borrows"). Without that obligation,
`var x: str = "ab"; let v: Core.Slice(str) =
unsafe Core.Slice(str).Make(&x, 1); let s: str = *v.Data(); x = "longer";
return s.Size();` would meet `Make`'s stated obligation, the element outliving
the view, and `s` would still read the owner's write, `x` carrying no frozen
loan the checker could see (amended 2026-10-28, document-review fold: R1-M2).
The obligation lasts as long as the loan, not the binding that formed it. For
`unsafe fn Alias(p: Core.Buf(i32)*) -> Core.Buf(i32)*`, whose doc comment says
that the result points at `*p`, which outlives it, the body
`var b: Core.Buf(i32) = Core.Buf(i32).Make(1, 7);
let r: Core.Buf(i32)* = unsafe Alias(&b);
let s: Core.Slice(i32) = r->AsSlice(); b = Core.Buf(i32).Make(1, 0);
return s[0];` binds `*r`, an open place of a `Core.SharedImmutable` type,
frozen for `AsSlice`'s by-value `bound self`, and `s` keeps that loan once the
binding is dead (T5(d)); the owner's assignment sees no loan on `b` and frees
the block `s` views, which breaks the obligation the marker on `Alias` took on
for as long as `s` lives, so the read of freed memory is a bug of that
`unsafe` line, as the [unsafe-code contract](#the-unsafe-code-contract) has
it, and not of the code the checker accepted (amended 2026-10-29, re-review
round 2: RR1-B1).

A ⊥ pointer may be copied, compared, and passed to a non-`bound` parameter, and
every copy of it is ⊥ (T2). Every use of its pointee is an `unsafe` operation
whose obligation is that the storage outlives every use derived from it, and an
unmarked one is `StrictUnverifiedDeref`. A dereference (`*p`, `p->m`) is spelled
`unsafe *p` or `unsafe p->m`, the operation-tied spelling of
[type safety](type_safety.md); a use that is not a dereference — passing the
carrier to a `bound` parameter, binding a `ref` through it, forming a view from
it, subscripting a ⊥ view — is spelled with the same prefix on the innermost
call, binding or subscript that consumes the carrier, `unsafe Load(q)`, `let ref
r = unsafe *q;`, `unsafe v[i]`, the form the strategy page lists under
[operation-tied `unsafe`](README.md#operation-tied-unsafe) (amended 2026-10-12,
document-review fold: D-1). The same spelling marks a `ref` binding, or a value
binding of a borrowed object, formed on an open place
([`ref` bindings](#ref-bindings), T2): its obligation is the binding's,
`noalias` for a `ref`, which for a ⊥ carrier includes this one, one marker for
one binding (added 2026-10-28, SAFE-2: W-347, W-348). Each marker discharges
exactly one obligation: in `Wild3` the `unsafe &u.p` discharges the address-of
obligation of type safety and not the pass, which needs its own marker; written
`unsafe Load(unsafe &u.p)` the call is accepted and its result is ⊥.

**A ⊥ value does not leave a Strict function through its signature** (amended
2026-10-12, document-review fold: D-2; D-SAFE-10 amended identically).
Returning a ⊥ value from a function that is not `unsafe fn` is
`StrictUnverifiedDeref` at the `return`; storing it into a place whose root is
not a local of the body — a parameter's pointee, a global, a field reached
through a free or ⊥ pointer — is `StrictStoreOutlivesSource` under the Store
rule, because ⊥ is not free and no destination outside the body accepts a loan
the checker cannot see; a copy into a local of the body is accepted and is ⊥.
An `unsafe fn` may return ⊥: its doc comment states the obligation, and its
marked call gives the result the signature's loan set, as above. This is what
makes T5(a)'s rule that a function with no `bound` parameter returns a free
value sound: a Strict body cannot have made the value anything else, and an
`unsafe fn` body is trusted to the obligation its comment states.

```carbon
// AP-1 (NEW: `unsafe fn`, `unsafe` prefix; document review 1) — a ⊥ pointer may not leave a safe signature
fn Raw() -> i32* { let n: i64 = 0x1000; return n unsafe as i32*; }           // StrictUnverifiedDeref at the return: the result is ⊥ and Raw is not `unsafe fn`
unsafe fn RawUnsafe() -> i32* { let n: i64 = 0x1000; return n unsafe as i32*; }   // accepted; the doc comment states what the result points at
fn Use() -> i32 { let r: i32* = unsafe RawUnsafe(); return *r; }             // accepted: the marked call takes on that obligation, so r is free (T5(a))
```

Outcome today for AP-1: NEW-SYNTAX (`unsafe fn` and the `unsafe` prefix do not
parse); `Raw` is rejected at stage 3 by the subset's P3 rule and at stage 4 by
this sentence, `Use` is accepted at stage 4.

`unsafe as` between pointer types preserves the loan set of its operand, so a
conversion never extends a lifetime, and its own obligation is the type-safety
one, extent included. The programs `Wild` and `Wild3` of EX-TM-8 are this
rule's regression set: the first is the case the
strategy page's narrowness principle names, an unsafe type conversion that
must not also allow out-of-lifetime access; the second shows why the pointer
itself, not the value loaded through it, must be ⊥ — a Strict callee that
returns the pointee of a `bound` pointer-to-pointer parameter is correct code
that cannot see the union, and its result over such an argument must stay ⊥.

### T7: Temporaries

T7 is D-SAFE-12, stated in [Temporaries](#temporaries).

### T8: Codegen honesty

`noalias` is emitted, with `captures(none)` for a `ref` not marked `bound` and
`captures(ret: address, provenance)` for one marked `bound` (p005434:846-848),
only where the checker established the requirement against every other
access, Permissive and C++ ones included: intra-function, for a `ref` binding
or an `exclusive T*` loan a Strict body forms on a place whose every carrier
is the body's own, an owner of the body or a place reached only through
carriers of such owners' loans; and, for a `ref` binding on the referent of a
`ref` parameter or on the pointee of an `exclusive T*` parameter, and on those
parameters themselves, only in functions that are not exported to C++, not
address-taken (no function value crosses to C++ or Permissive code), and whose
every Carbon call site in the package is Strict-checked. That is a
whole-package fact, and otherwise the attributes are not emitted; nor are they
ever emitted for a `ref` on an open place, the checked `const` `ref` on a
`Core.SharedImmutable` type included, whose frozen loan Strict enforces but
which a Permissive body or C++ may still write as erroneous behavior. That is
the policy p005434 states under "How addresses interact with `ref`": "these
attributes won't be passed to LLVM unless their requirements can be
established". A `ref` binding formed with `unsafe`, and every `ref` in a
Permissive body, keeps the language's `noalias` rule as the unsafe code's
obligation, "Unsafe code will be required to adhere to just the `noalias`
restrictions, but will not be checked" (p005434:861-863), and carries no
attribute. The fork's own corpus has both excluded shapes: C++ calls
`fn Bump(ref self, n: i32)` from `inline Cpp`
(fork/conformance/programs/interop/cpp_export_method.carbon:31-33), and
`std::thread` takes a Carbon function value
(cpp_thread_carbon_fn_diff.carbon:38-45), and both are callers the
whole-package fact must count. A Permissive or C++ caller that aliases such a
parameter produces erroneous behavior, never undefined behavior, which is the
strategy's rule that "the optimization of safe code will not rely on
properties that are not established locally" (proposal p005914; realigned
2026-10-28, SAFE-2: W-347; the superseded 2026-10-12 text began "`noalias` and
`captures(none)` are emitted for exclusive loans only where the checker
established them:").

## The first enforceable subset

Stage 3 ships a checker with no loan sets, the P1/P2/P3 subset, a strict subset
of T1 to T8 that attempt C contributed and both judges asked for:

-   **P1** — a pointer formed by `&local` or `&param` in the body being
    checked. It may be dereferenced and passed to a non-`bound` parameter; it
    may never escape: not returned, not stored into a place whose root is
    declared outside the source's scope — the subset decides this lexically,
    so `Wild`'s `var u: U = {.p = &x};` into a local declared inside `x`'s
    scope is accepted — and not passed to a `bound` parameter whose result
    escapes (amended 2026-10-12, document-review fold: D-5).
-   **P2** — a pointer parameter of the function, or a `ref` binding. It may be
    dereferenced without a marker; it escapes only as T5 allows.
-   **P3** — everything else: a pointer that was returned by a call, loaded
    from memory, converted, or produced by C++. It is ⊥ to the subset, so its
    dereference needs `unsafe *p`.

The subset proves T5(c) for the return of a P1 pointer (EX-TM-2), the Store
rule for a P1 pointer stored outside the source's scope, and T6 for P3; it
proves nothing about
views. It is sound only together with the prelude churn of W-144: without
`bound self` on `Core.Buf.AsSlice` and `bound p` on `Core.Slice.FromArray`, a
view of a local escapes as a class value and no P rule fires, which is judge
2's refutation of attempt C's stage-1 claim (`Leak` and `Escape` in EX-TM-4).
With W-144 in place, a view is a P1 carrier when its `bound` argument was P1,
and `Leak` and `Escape` are rejected at stage 3; `Store` needs the Store rule
over a ⊥ destination and is rejected at stage 4.

## `bound`, `bound(a)` and `unsafe class`

This section is D-SAFE-11 and rule T5. `bound` is the one lifetime annotation,
kept from proposal p005434 with its semantics now fixed.

-   **(a) The result's loans.** The loan set of a call's result is the union of
    the loan sets of the arguments passed to `bound` parameters, `self`
    included, with kind equal to the parameter's kind: a `ref` parameter gives
    exclusive under a `ref` return and frozen under a `val` or by-value return,
    an `exclusive T*` parameter gives exclusive, `T*` and `const T*` parameters
    give shared, and a by-value parameter of a borrowed type, `self` included,
    or a `const` `ref` gives frozen; a mixed set takes the weakest kind, frozen
    counting below shared, so no write reaches a frozen argument through the
    result (realigned 2026-10-28, SAFE-2: W-349; the superseded 2026-10-12
    sentence read "with kind equal to the parameter's kind: `ref` and `exclusive
    T*` parameters give exclusive, value, `T*` and `const` parameters give
    shared, and a mixed set takes the weakest kind."). A function with no
    `bound` parameters returns a free value, subject to the Store rule; this is
    never read as applying to a copy, a conversion or a `Copy.Op` of an existing
    value (T2). A prelude function whose result can carry a loan from a
    parameter — a view of `self`, a `T` payload returned from `self`, a `T`
    argument stored into the result — without `bound` on that parameter is a
    defect of the W-144 audit under the spatial page's rule SP3, not a loan
    boundary. A ⊥ argument to a `bound` parameter makes the result ⊥, after the
    `unsafe` that T6 demands for the pass.
-   **(b) Escape in the callee.** A non-`bound` pointer or `ref` parameter may
    not escape: not returned, not stored, not passed as a `bound` argument
    whose result escapes; the violation is `StrictEscapeOfUnboundParam`. A
    `bound` parameter may escape only into the return value.
-   **(c) Dangling returns.** Returning a loan on a local, a temporary or a
    `var` parameter is `StrictDanglingReturn`. The cases p005434 calls
    erroneous under "`bound` parameters" (`Invalid1` to `Invalid3`) become hard
    errors in Strict and warnings in Permissive.
-   **(d) The argument stays immutable.** For the duration of a returned loan
    each `bound` argument is immutable, as the proposal says full safety needs:
    "For full safety, we need each bound parameter to be immutable for the
    duration of the lifetime of the returned result" (p005434:831-832); no path
    but the result writes it. A by-value `bound` argument of a borrowed type,
    `bound self` included, and a `bound` `const` `ref` keep their frozen loan
    for the result's lifetime, so no path writes their storage while the result
    lives (`StrictBorrowedObjectMutated`, T4; the mutation page's EX-M-1). A
    `bound ref` argument keeps its exclusive loan, which the result carries (`captures(ret:
    address, provenance)`), so no path but the result reaches it, when the
    result is a `ref` return, as the proposal's `ValidRef`, returning `self.m`
    from `bound ref self`, needs (p005434:730-731); under a `val` or by-value
    result, the proposal's `RefToVal` (p005434:825), it keeps a frozen loan, and
    may be read but not written while the result lives. The pointee of a `bound`
    pointer argument, `T*`, `const T*` or `exclusive T*`, the pointer itself
    being a copy, is held by the result under a frozen loan, an exclusive one
    for an `exclusive T*`: while the result lives no carrier but the result and
    the carriers copied from it writes the pointee, and the result's own access
    is at the kind (a) gives the parameter, so it writes the pointee only as
    that kind allows, never through a `const T*`; an `exclusive T*`'s pointee is
    reached by no other path at all. On a closed place T4 enforces this against
    every carrier, so while a view `Core.Slice(T).FromArray(&a)` of a local
    array lives, `a` is written only through the view ([slices](../slices.md),
    the opening example). On an open place it needs the pointee's type to be
    `Core.SharedImmutable`, whose shared-path writes the mutation page's M3
    rejects; otherwise the call is `StrictBorrowFromShared`, or `unsafe` at the
    call (`unsafe Valid1(p)`, the T6 spelling of a call that consumes a carrier
    the checker cannot vouch for) with the obligation that no path but the
    result writes the pointee while the result lives. The proposal's "We will
    reconsider this with the memory safety design" (p005434:834-835) is answered
    by keeping the sentence (realigned 2026-10-28, SAFE-2: W-349; the bullet was
    "(d) The argument stays borrowed.", and its superseded 2026-10-12 text read:
    "For the duration of a returned loan the bound argument stays borrowed in
    the caller at the parameter's kind. The proposal asks (p005434:831-832) for
    the bound parameter to be "immutable for the duration of the lifetime of the
    returned result"; this design narrows "immutable" to "not invalidated": a
    shared-kind bound argument stays writable in its `Plain` fields through
    other aliases, the same narrowing D-SAFE-17 applies to value bindings. This
    is a dated narrowing, recorded here and in the F-013 entry.").
-   **(e) Interfaces.** An impl may drop but not add `bound` relative to its
    interface, as the proposal states. This is why the prelude's interface
    declarations `IndexWith.At` (core/prelude/operators/index.carbon:9) and
    `Copy.Op` carry `bound self` themselves after W-144: a user-written
    `Copy.Op` may then keep its loan without (a) reading its result as free,
    while the prelude's primitive copies stay governed by T2.
-   **(f) Named lifetimes.** `bound(a)`, with `[a: Core.Lifetime]` as a deduced
    parameter, is pinned now and implemented at stage 6. One name is one loan
    set: every argument passed to a `bound(a)` parameter, every `bound(a)`
    field of the receiver and the result join a single set whose kind is the
    weakest among them; a store from a place in set `a` into a place in set `a`
    passes the Store rule; two names are unrelated sets. Bare `bound` is the
    elision form and expresses no relation between names. An outlives relation
    between names (`a: b`) is deferred to the stage-6 plan (W-150). The
    proposal already defers linked structures to "More precise lifetimes";
    EX-TM-6 is the shape that section asks for.
-   **(g) Pointer fields and the `unsafe class` interim** (amended 2026-10-12,
    document-review fold: D-3; D-SAFE-11(g) amended identically). A Strict
    class with a pointer field is legal without `unsafe class`: its values
    carry the union of their fields' loans as one loan set
    ([Vocabulary](#vocabulary)), formed at construction and propagated by
    T5(a) and T2, so a view-shaped class over locals and `bound` results is
    checked exactly like `Core.Slice`, whose `ptr: T*` is such a field.
    `unsafe class` is required only where a loan must be stated _in the type_
    because the value's lifetime is not the loan's — a field written through a
    free or ⊥ pointer, the `Holder` of EX-TM-4 reached through
    `GetGlobalHolder()`, or a heap-stored node of a linked structure — until
    `bound(a)` fields exist at stage 6. For an `unsafe class` the invariant is
    the author's: every construction site in Strict is `unsafe` because
    construction may store non-free loans, its pointer fields are ⊥ (reads
    through them need `unsafe *`), and the Store rule treats them as a ⊥
    destination that accepts only free loans, so `Holder`'s `h->p = &y` is
    `StrictStoreOutlivesSource` by this rule. The program below is review 1's
    AP-2: `View2` and `Make2` are accepted, `Bad2` is rejected.

```carbon
// AP-2 (NEW: `bound`; document review 1) — a plain Strict class with a pointer field
class View2 { var p: i32*; }                              // legal in Strict without `unsafe class`: a View2 value carries p's loan
fn Make2(bound q: i32*) -> View2 { return {.p = q}; }     // accepted: the result's loan set is q's (T5(a))
fn Bad2() -> View2 { var x: i32 = 1; return Make2(&x); }  // StrictDanglingReturn: a loan on the local x leaves the function (T5(c))
```

Outcome today for AP-2: NEW-SYNTAX (`bound` is not a token); `Bad2` is
rejected at stage 3 with W-144's `bound` on view producers for the `Core.Slice`
shape and at stage 4 for a user class, `View2` and `Make2` are accepted at
every stage.

## Temporaries

A `ref` binding or a `bound` result may carry a loan on a temporary only until
the end of the full-expression; a later use is `StrictBorrowOfTemporary`, and
the fix is the one the proposal suggests under "Temporary lifetimes": provide
storage with `var x: ... = ReturnsATemporary();`. The design diagnoses rather
than extends (D-SAFE-12). This makes the divergence the interoperability
philosophy records under
[object lifetimes](../interoperability/philosophy_and_goals.md#object-lifetimes)
— that Carbon's rules for temporaries may turn code that is safe in C++ into
unsafe Carbon — a compile error, never a dangling pointer.

Today's toolchain already rejects `let ref r: Core.String = MakeString();` by
the proposal's rule that a `ref` binds a durable reference expression, with
the diagnostic "cannot bind durable reference to non-reference value of type
`str`" (EX-TM-7; the materialization point is
toolchain/check/convert.cpp:2216-2219, whose TODO to lifetime-extend for a
`DurableRef` target is the extension point this design declines). So
`StrictBorrowOfTemporary` is reachable only through a `bound` result or a
pointer formed from a temporary, which is EX-TM-7b. The builder-chain idiom
that [values](../values.md#reference-expressions) flags as future work stays
unsupported.

## Relocation and `~x`

The move operator `~x` of rule I4 on the
[initialization safety](initialization_safety.md) page relocates `x`'s value
and leaves `x` unformed; what makes the relocation safe on this page is T4. A
live shared loan on `x` — a self-loan included, a pointer stored in `x` that
names a field of `x` — forbids the invalidating `~x`, so a relocation never
breaks a pointer the checker knows about. `Core.Relocatable` is therefore
defined structurally (D-SAFE-13): a type is `Relocatable` when all of its
fields are; the three pointer kinds, the integers, the floats, `bool` and
`char` are; an imported C++ type is `Relocatable` exactly when it is trivially
relocatable; and `unsafe impl T as Core.Relocatable {}` opts a pinned type out
or in. "No self-pointers" is not a criterion, because self-reference is a
property of values, not types, and the loan rule already covers the values
that have it. The same facet decides which types cross to Rust by value
([Safe-Rust interop](rust_interop.md)).

## The unsafe-code contract

A dangling access created by unsafe Carbon or by C++ breaking a contract — a
`bound` argument freed while the result lives, a pointer saved by an
unannotated C++ callee and used later, a ⊥ pointer dereferenced after its
storage ended — is a bug _of the unsafe code_. Carbon never miscompiles it,
because T8 withholds every aliasing attribute at such a boundary; the Debug
build detects it with the ASan-class detection the
[build modes](README.md#build-modes) promise; and the Release build does not
make it defined. No runtime temporal mechanism exists in Release — no
reference counting, no garbage collection, no quarantine, no pointer tagging —
because the strategy's budget for temporal safety is under one percent in
aggregate (proposal p005914) and quarantine-class hardening for dangling unsafe
accesses lies outside it; the strategy's own constraints section explains why
probabilistic techniques would not buy safety either.

This is the design's named narrowing of the strategy's sentence that
violations of restrictions on unsafe code are made erroneous "where the
behavior is well-defined while still considered a diagnosable" bug
(p005914:209-211): for a dangling access the behavior is erroneous and
Debug-diagnosable, but not well-defined in Release. The narrowing was attempt
B's largest divergence from the strategy and is kept and disclosed rather than
hidden behind a hardening mode the budget does not allow.

## Diagnostics

The rows this page owns in the
[diagnostic matrix](README.md#what-each-mode-diagnoses); `StrictUnverifiedDeref`
is shared with [type safety](type_safety.md), which owns its spelling.

| Diagnostic | Strict | Permissive | Debug runtime |
| --- | --- | --- | --- |
| `StrictUnverifiedDeref` (shared with [type safety](type_safety.md)) | error | none — assumed fact | ASan-class detection ([Build modes](README.md#build-modes)) |
| `StrictExclusiveBorrowConflict` | error | warning `PermissiveAliasedExclusive` | — |
| `StrictSharedBorrowInvalidated` | error | warning `PermissiveAliasedExclusive` | ASan-class detection when the invalidation frees what a loan reads; the value-binding report is `StrictBorrowedObjectMutated`'s (realigned 2026-10-28, SAFE-2: W-348; this cell read "`MutationDuringValueBinding` for the value-binding case (D-SAFE-17)") |
| `StrictRefFromShared` (realigned 2026-10-28, SAFE-2: W-347) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictBorrowOutlivesPlace`, `StrictBorrowOfTemporary`, `StrictDanglingReturn`, `StrictStoreOutlivesSource`, `StrictEscapeOfUnboundParam` | error | warning `PermissiveDanglingLoan` | ASan-class detection |
| `StrictCppCallUnannotated` | error | warning `PermissiveUnannotatedCppCall` — assumed fact | — |

The diagnostics and what each names:

-   `StrictExclusiveBorrowConflict`: "`{0}` is borrowed exclusively by `{1}`
    here, used again at {2}", placed at the conflicting use, with `{1}` the
    origin of the live exclusive loan (T4).
-   `StrictSharedBorrowInvalidated`: placed at the invalidating operation,
    naming the place and the live shared loan's origin (T4; the reborrow
    clause of T2).
-   `StrictRefFromShared`: "`ref` binding `{0}` of `{1}` through a shared path;
    use an `exclusive` pointer or `unsafe`", placed at the binding or at the
    call that binds a `ref` parameter, with a note at the shared path's origin
    ([`ref` bindings](#ref-bindings); added 2026-10-28, SAFE-2: W-347). Its
    siblings `StrictBorrowFromShared`, which a `bound` pointer argument on an
    open place also raises (T5(d)), `StrictBorrowedObjectMutated` and
    `StrictSharedImmutableWrite` are the mutation page's (M3, M8).
-   `StrictBorrowOutlivesPlace`: placed at the scope exit or the thread-crossing
    call, naming the `var` being destroyed and the carrier that still holds a
    loan on it (T3).
-   `StrictBorrowOfTemporary`: placed at the first use after the
    full-expression, naming the temporary (T7).
-   `StrictDanglingReturn`: placed at the `return`, naming the local, temporary
    or `var` parameter the result would refer to (T5(c)).
-   `StrictStoreOutlivesSource`: placed at the store, naming the destination
    place's root and the loan that does not outlive it (the Store rule).
-   `StrictEscapeOfUnboundParam`: placed at the escaping use, naming the
    parameter and suggesting `bound` (T5(b)).
-   `StrictCppCallUnannotated`: placed at the call, naming the C++ function and
    the pointer, reference, view or `this` in its signature that carries no
    annotation and matches no shape of the
    [C++ call allowlist](README.md#c-call-allowlist).
-   `PermissiveAliasedExclusive`, `PermissiveDanglingLoan` and
    `PermissiveUnannotatedCppCall`: the Permissive warning twins, with the same
    text and placeholders as the Strict diagnostic each twins.

The message texts other than the first are fixed at stage 3 for the twins and
the C++-call rule and at stage 4 for the loan diagnostics. No diagnostic of
this family exists in the toolchain today: toolchain/diagnostics/kind.def
names no diagnostic containing `Borrow`, `Loan` or `Dangling`, and the examples
below that are today's syntax compile without comment where the outcome says
so.

## Worked examples

Each example carries its outcome against the 0.1 toolchain in the vocabulary
of the plan's design-conformance checklist: ACCEPTS, REJECTS,
ACCEPTS-UNCHECKED (compiles today but Strict must reject or the runtime must
check, with the stage that will) or NEW-SYNTAX (no toolchain parses it, with
the stage that will). The examples marked "today's syntax" were compiled on the
2026.10.12 nightly toolchain with `carbon compile --output-last-input-only`,
no `package` line and `import Core library "io";` prepended where `Core.Print`
is used; `Core.Buf`, `Core.Slice` and `union` are the fork prelude's
and the fork syntax's and are not in that toolchain, so the examples that use
them cite the fork program or prelude line that proves the cell instead. The
two regression sets, EX-TM-4 and EX-TM-8, are the standing counterexamples the
design must reject and are kept verbatim from the plan, but for `UsePick`'s
comments in EX-TM-8, realigned 2026-10-28 by SAFE-2 (W-347) with the superseded
comments kept in them. Tags of the form A-n,
B-n and RR-n in example comments index the review-fold record of
[fork/safe/plan.md](/fork/safe/plan.md).

### EX-TM-1: A `bound` result borrows both arguments

```carbon
// EX-TM-1 (NEW: `bound` token): result borrows both, shared
fn Longest(bound a: const Core.String*, bound b: const Core.String*) -> const Core.String* {
  if (a->Size() > b->Size()) { return a; } else { return b; }
}
```

Rule T5(a). Outcome today: NEW-SYNTAX — toolchain/lex/token_kind.def has no
`bound` token. Under the design the result's loan set is the union of `a`'s and
`b`'s at shared kind, and by T5(d) the result holds both pointees, frozen as
the pointees of `bound` pointer arguments that are not `exclusive T*`, the
`const` only keeping the result's own access to reads (amended 2026-10-28,
document-review fold: R1-m2): in a caller, while the result is live,
neither pointee may be written, destroyed or assigned through any path, and both
may still be read; on a caller's local the check is T4's, and through a caller's
own shared pointers the prelude's opt-in of `Core.String` to
`Core.SharedImmutable` (W-144) lets the loan be formed. `a->Size()` binds `*a`,
an open place, by value, which the same opt-in makes a checked frozen loan (the
mutation page's M8; realigned 2026-10-28, SAFE-2: W-348, W-349; the superseded
2026-10-12 sentence read "Under the design the result's loan set is the union of
`a`'s and `b`'s at shared kind, so in a caller both arguments stay borrowed, not
invalidated, while the result is live; neither may be destroyed or assigned a
non-`Plain` value, and both may still be read."). Lands at stage 1 (the token)
and stage 4 (the loan).

### EX-TM-2: A dangling return

```carbon
// EX-TM-2 (today's syntax; accepted today — p005434:705-709 `Invalid1` calls it invalid (re-pinned, B10); Strict: StrictDanglingReturn)
fn Bad() -> i32* { var x: i32 = 4; return &x; }
```

Rule T5(c). Outcome today: ACCEPTS-UNCHECKED — the nightly compiles it with
exit status 0 and no diagnostic, and it is the proposal's `Invalid1`, which the
proposal classes as erroneous behavior. Under the design `&x` is a P1 loan on
the local `x`, and returning it is `StrictDanglingReturn` in Strict and
`PermissiveDanglingLoan` in Permissive. Rejected at stage 3 by the first
enforceable subset (residue item W-147).

### EX-TM-3: Liveness and non-invalidating writes

```carbon
// EX-TM-3 (today's syntax for everything but the `bound` on AsSlice, which is W-144; amended
// 2026-10-12, review fold: B2 — the prelude's String is Plain, so the invalidating assignment is a Buf's)
fn Use() {
  var s: Core.String = "abc";
  let p: const Core.String* = &s;   // shared loan on s
  Core.Print(p->Size() as i32);
  s = "def";                        // OK even while p is live: String is Plain (B2), assignment is non-invalidating
  var buf: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  buf.Set(1, 7);                    // OK: no loan on buf is live; Set takes ref self after W-144 (realigned 2026-10-28, SAFE-2: W-348; this call followed the next line and read "buf.Set(1, 7);                    // OK: Set is non-invalidating and i32 is Plain")
  let v: Core.Slice(i32) = buf.AsSlice();   // AsSlice is [bound self] after W-144: v holds an interior loan on buf
  // buf.Set(1, 7);                 // here: StrictSharedBorrowInvalidated — Set's ref self is an exclusive use of buf, and v's frozen loan on buf is live (T4)
  Core.Print(v[1]);                 // prints 7; last use of v: loan ends (NLL)
  buf = Core.Buf(i32).Make(1, 0);   // OK after v is dead; before it: StrictSharedBorrowInvalidated (the block v views is freed)
}
```

Rules T3 and T4 with the mutation page's M3. Outcome today: ACCEPTS-UNCHECKED —
the `String` half (the first five statements, with `Core.Print` given the `as
i32` the [slices](../slices.md) design uses for a `Size()` result) compiles on
the nightly with exit status 0, and it is accepted in Strict too: the prelude's
`String` is a non-owning `{Char*, i64}` with `impl as Copy` and no `Destroy`
(core/prelude/types/string.carbon:16-28), so it is `Plain` and the assignment
under the live `const String*` is non-invalidating. The `Buf` half is fork
prelude code (`Make`, `Set`, `AsSlice` at core/prelude/types/buf.carbon:28-56)
and is not compile-verified against the upstream nightly; the view `v` holds an
interior loan on `buf` once `AsSlice` is `[bound self]` (W-144), `buf.Set(1, 7)`
comes before `v` is formed, because `Set` takes `ref self` once W-144 lands, the
exclusive receiver the mutation page's
[Value bindings](mutation_safety.md#value-bindings) requires of a trusted writer
of an element, so that under the live `v` the call is
`StrictSharedBorrowInvalidated` (realigned 2026-10-28, SAFE-2: W-348; the
superseded clause read "`buf.Set(1, 7)` is permitted through it because `Set` is
non-invalidating and `i32` is `Plain`,"), and the last use of `v` ends the loan,
after which the assignment to `buf` — which frees the block `v` viewed — is
legal. Moved one line earlier, that assignment is
`StrictSharedBorrowInvalidated`. The loan rule lands at stage 4.

### EX-TM-4: The regression set

```carbon
// EX-TM-4 (regression set, judge 2 — all three are accepted by today's toolchain and must be
// rejected by stage 4; the first two also by stage 3 once W-144 lands)
fn Leak() -> Core.Slice(i32) {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  return b.AsSlice();               // StrictBorrowOutlivesPlace: b's Destroy frees the block (the return copy keeps the loan, T2/A-2)
}
fn Escape() -> i32 {
  var s: Core.Slice(i32);
  { var a: array(i32, 2) = (1, 2); s = Core.Slice(i32).FromArray(&a); }
  return s[0];                      // StrictBorrowOutlivesPlace (a ended)
}
unsafe class Holder { var p: i32*; }  // D-SAFE-11(g): fields ⊥, a ⊥ store destination (A-15); plain `class` until bound(a) lands at stage 6
fn GetGlobalHolder() -> Holder*;
fn Store() { var y: i32 = 1; let h: Holder* = GetGlobalHolder(); h->p = &y; }  // StrictStoreOutlivesSource: a ⊥ destination accepts only free loans
```

Rules T3, T5(c), the Store rule and T5(g); judge 2's three programs, the ones
that refuted a stage with no loan sets, kept verbatim. Outcome today:
ACCEPTS-UNCHECKED — all three are accepted by today's toolchain for the fork
prelude (`AsSlice` at buf.carbon:54-56, `FromArray` at slice.carbon:26-28),
with `unsafe class` as the one NEW spelling: a plain `class` today, parsed at
stage 1, and the interim the comment names until `bound(a)` fields replace it
at stage 6. Under the design: `Leak` returns a view whose loan is on the
local `b`, whose `Destroy` frees the block, and the return copy keeps the loan
by T2, so it is `StrictBorrowOutlivesPlace`; `Escape` stores a view of the
inner-scope array `a` into the outer `s` and reads it after `a` ended, which is
`StrictBorrowOutlivesPlace` at the inner scope's exit; `Store` writes a loan on
the local `y` into a ⊥ destination, the pointer field of an `unsafe class`
reached through a free pointer, and is `StrictStoreOutlivesSource`. `Leak` and
`Escape` are rejected at stage 3 once W-144 gives `AsSlice` and `FromArray`
their `bound`; `Store` at stage 4.

### EX-TM-5: The exclusive pointer and the first enforceable subset

```carbon
// EX-TM-5 (NEW): exclusive pointer and the P-subset
fn Lookup() -> i32*;
fn Bump(p: exclusive i32*) { *p += 1; }           // P2: deref ok; exclusive loan on *p
fn Run() -> i32 { var x: i32 = 41; Bump(&x); return x; }   // &x yields exclusive i32*
fn Peek() -> i32 { let r: i32* = Lookup(); return unsafe *r; }   // P3: Lookup has no bound
```

D-SAFE-7 and the P1/P2/P3 subset. Outcome today: NEW-SYNTAX — `exclusive` is
not a token and `unsafe` is accepted only before `as`
(toolchain/parse/handle_expr.cpp:391-399). Under the design `&x` on the owner
`x` yields `exclusive i32*`, `Bump`'s parameter is a P2 carrier that may be
dereferenced without a marker and holds an exclusive loan on `*p` for the
call, and `Run` returns 42. `Lookup` has no `bound` parameter, so its result is
free under T5(a) in the full checker — a Strict `Lookup` body cannot return a
⊥ value (T6), and an `unsafe fn Lookup` would need `unsafe` at the call — but
P3 to the subset, which has no loan sets; the subset therefore demands
`unsafe *r`, and the full checker at stage 4 accepts `*r` unmarked because the
result is free (amended 2026-10-12, document-review fold: D-2). The marked
form is correct in both. Lands at stage 1 (the token) and stage 3 (the subset).

### EX-TM-6: Named lifetimes

```carbon
// EX-TM-6 (NEW, stage 6): named lifetimes
fn Push[a: Core.Lifetime](list: bound(a) List*, node: bound(a) Node*) { list->head = .Some(node); }
```

Rule T5(f). Outcome today: NEW-SYNTAX, stage 6 (residue item W-150). Under the
design `list` and `node` join the one loan set `a`, so the store
`list->head = .Some(node)` is a store from a place in `a` into a place in `a`
and passes the Store rule; with bare `bound` on both parameters the two would
be unrelated sets and the store would be `StrictStoreOutlivesSource`, which is
why linked structures wait on stage 6 or use the `unsafe class` interim of
T5(g) until then.

### EX-TM-7 and EX-TM-7b: Temporaries

```carbon
// EX-TM-7 (today's syntax; REJECTED today — "cannot bind durable reference to non-reference value of
// type `str`", nightly 2026.10.12, p005434:173-175's rule; amended 2026-10-12, review fold: B1)
fn MakeString() -> Core.String;
fn Temp() { let ref r: Core.String = MakeString(); Core.Print(r.Size() as i32); }  // rejected today and in both modes; fix: var
// EX-TM-7b (today's syntax except the `bound self` on AsSlice, W-144): a `bound` result on a temporary
fn Temp2() { let v: Core.Slice(i32) = Core.Buf(i32).Make(4, 0).AsSlice(); Core.Print(v[0]); }  // StrictBorrowOfTemporary: v's loan is on the temporary Buf, dead at the `;`
```

Rule T7. Outcome today for EX-TM-7: REJECTS — the nightly rejects the `ref`
binding with "cannot bind durable reference to non-reference value of type
`str`", exit status 1, by the proposal's rule that a `ref` binds only a durable
reference expression; the design keeps that rejection in both modes, and the
fix is `var r: Core.String = MakeString();`. Outcome today for EX-TM-7b:
ACCEPTS-UNCHECKED — the fork prelude's `AsSlice` (buf.carbon:54-56) returns a
class value and nothing today ties it to the temporary `Buf`, which is
destroyed at the end of the full-expression, so `v[0]` reads freed memory;
under the design `v`'s loan is on the temporary and the use on the next
statement is `StrictBorrowOfTemporary`. The value binding `v` itself takes
ownership of nothing here: its initializer is a view, and the loans carried by
the view are what the rule checks. Rejected at stage 4 with W-144.

### EX-TM-8: The review regression set

```carbon
// EX-TM-8 (regression set, review A — amended 2026-10-12, review fold: A-1, A-2, A-5; re-review fold:
// RR-1 Wild3, RR-2 Launder4/Launder5, RR-7 UsePick's diagnostic; each must be rejected by stage 4 with
// the named diagnostic; today's toolchain accepts the fork-syntax parts)
union U { var p: i32*; var n: i64; }                       // union is fork syntax (types/union_basic.carbon)
fn Wild() -> i32 {
  var x: i32 = 1;
  var u: U = {.p = &x};             // Store rule: x outlives root(u) — accepted
  u.n = 0x1234;                     // union write: safe, no marker (F-007b)
  let q: i32* = unsafe u.p;         // union read: the punning obligation only; q is ⊥ (T6, A-1)
  return *q;                        // StrictUnverifiedDeref: needs `unsafe *q` — the README.md:83-87 case
}
fn Load(bound q: i32**) -> i32* { return *q; }   // correct Strict code, accepted: a read through a verified bound
                                                 // pointer; result loan set = q's at shared kind (11(a))
fn Wild3() -> i32 {
  var x: i32 = 1;
  var u: U = {.p = &x};
  u.n = 0x1234;                     // union write: safe
  let q: i32* = Load(unsafe &u.p);  // StrictUnverifiedDeref: `unsafe &u.p` is a ⊥ pointer on formation (T6, RR-1), and
                                    // passing ⊥ to a bound parameter needs the T6 `unsafe`; Load itself cannot see the union
  return *q;                        // with that `unsafe` spelled, q is ⊥ (a bound call over a ⊥ argument, 11(a)) — `unsafe *q` again
}
fn Launder1() -> Core.Slice(i32) {
  var a: array(i32, 2) = (1, 2);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  return s.Subslice(0, 2);          // StrictDanglingReturn: Subslice is [bound self] (W-144, A-2) — a sub-loan on a
}
fn Launder2() -> Core.Slice(const i32) {
  var v: Cpp.std.vector(i32) = Cpp.MakeVector();         // the cpp_span_view.carbon:64-65 shape
  let view: Core.Slice(const i32) = v;                   // the container ImplicitAs is [bound self] (W-144, A-2)
  return view;                      // StrictDanglingReturn: the return copy keeps the loan on v (T2)
}
fn Launder3() -> Core.Slice(i32) {
  var b: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  let s: Core.Slice(i32) = b.AsSlice();
  let t: Core.Slice(i32) = s;       // Copy.Op is not a loan boundary (T2): t carries s's loan
  return t;                         // StrictBorrowOutlivesPlace, as Leak
}
fn Launder4() -> i32* {
  var x: i32 = 1;
  var o: Core.Optional(i32*) = Core.Optional(i32*).Some(&x);   // Store rule: x outlives o — accepted; Some's `bound value` (W-144, RR-2) puts x's loan in o
  return o.Get();                   // StrictDanglingReturn: Get is [bound self] after W-144 (RR-2) — rev 2's receiver grep missed a result of type T
}
fn Launder5() -> Core.Optional(i32*) {
  var x: i32 = 1;
  return Core.Optional(i32*).Some(&x);   // StrictDanglingReturn: Some has no receiver; `bound value` (W-144, RR-2) carries the loan on x into the result
}
fn Pick(b: bool, bound ref r: Core.Buf(i32), bound p: Core.Buf(i32)*) -> ref Core.Buf(i32) {
  if (b) { return r; } else { return *p; }               // p005434:772-779's Conditional: result kind is the weakest (shared)
}
fn UsePick() {
  var x: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  var y: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  let q: Core.Buf(i32)* = &y;  let q2: Core.Buf(i32)* = &y;
  let ref z: Core.Buf(i32) = Pick(false, x, q);          // StrictSharedBorrowInvalidated (T4): q2's shared loan on y, live below, excludes the exclusive loan z forms (amended 2026-10-28, document-review fold: R1-m1); z: an exclusive ref on x and y, both closed places (realigned 2026-10-28, SAFE-2: W-347; was "z: shared-kind ref whose loan set covers x and y (A-5)")
  let v: Core.Slice(i32) = q2->AsSlice();                // the use that keeps q2's shared loan on y live when z is formed (amended 2026-10-28, document-review fold: R1-m1, where this read "StrictExclusiveBorrowConflict: q2 reaches y while z's exclusive loan on y is live"; was "interior loan on y")
  z = Core.Buf(i32).Make(5, 0);     // through the exclusive ref, not itself rejected (was "StrictInvalidatingThroughShared (RR-7): a non-Plain assignment through a shared-kind ref, rejected regardless of v; y's live view is the second reason")
  Core.Print(v[0]);
}
```

Rules T6, T2, T5(a) and D-SAFE-8; the programs the plan's reviews added, kept
verbatim but for `UsePick`'s comments, realigned 2026-10-28 (SAFE-2: W-347),
each of which must be rejected by stage 4 with the diagnostic named in its
comment. Outcome today: NEW-SYNTAX for `Wild`, `Wild3`, `Pick` and `UsePick` (`unsafe
u.p`, `unsafe &u.p` and `bound` do not parse; the `union` itself is fork syntax
proven by fork/conformance/programs/types/union_basic.carbon, and the upstream
nightly has no `union`); ACCEPTS-UNCHECKED for `Launder1` to `Launder5`, which
are today's syntax over the fork prelude (`Subslice` at slice.carbon:46-52, the
`Slice(const T)` conversion at :80-84, the container conversion at :100-106,
`Optional.Some` and `Optional.Get` at optional.carbon:34-42, the identity
conversion at as.carbon:37-39). What each shows:

-   **`Wild`** (T6). The pointer stored in `u.p` has a loan on `x` and the
    store passes the Store rule; the write `u.n = 0x1234` needs no marker; the
    read `unsafe u.p` discharges the punning obligation only, so `q` is ⊥ and
    `return *q` is `StrictUnverifiedDeref`. This is the case the strategy's
    narrowness principle names: the unsafe type conversion must not also allow
    the out-of-lifetime access, and here it does not, because the second
    obligation has its own marker.
-   **`Load`** (T5(a)). Correct Strict code, accepted: a read through a verified
    `bound` pointer-to-pointer whose result carries `q`'s loans at shared kind.
    By T5(d) the result also holds the caller's `*q`, the pointer `q` points to:
    while the result lives no other path writes it, and in `Wild3` the argument
    is ⊥, which needs the T6 `unsafe` before T5(d) applies (added 2026-10-28,
    SAFE-2: W-349).
-   **`Wild3`** (T6, modular). `unsafe &u.p` is ⊥ on formation, so passing it
    to `Load`'s `bound` parameter needs the T6 `unsafe` and the result of the
    call is ⊥ by T5(a); `Load` cannot see the union and does not need to. Had
    only the value loaded through the pointer been ⊥, `Load`'s result over
    `unsafe &u.p` would have carried the non-⊥ set `{(u.p, shared)}`, and the
    union would have laundered a loan through correct code.
-   **`Launder1`, `Launder2`, `Launder3`** (T2, copies preserve loans). A
    `Subslice`, an `ImplicitAs` conversion of a container to a view, and a
    `let t = s` copy each carry the loan of the view they were made from, so
    the returns are `StrictDanglingReturn` and `StrictBorrowOutlivesPlace`
    exactly as `Leak` is; T5(a)'s free result never applies to them. The first
    two are rejected at stage 3 with W-144, the third at stage 4.
-   **`Launder4`, `Launder5`** (T5(a) and the W-144 audit). `Optional.Some` has
    no receiver and stores its `T` argument into the result; `Optional.Get`
    returns a `T` payload from `self`. Both carry a loan when `T` is a pointer
    type, so both are `bound` after W-144 — a receiver-only audit would have
    missed them — and the returns are `StrictDanglingReturn`. Rejected at
    stage 3 with W-144.
-   **`Pick`, `UsePick`** (D-SAFE-8). `Pick` returns a reference expression, not
    a binding, and is accepted; its result carries `{(r, exclusive), (*p,
    shared)}` and has the weakest kind, shared. In `UsePick` both places in that
    set, `x` and `y`, are locals, so `let ref z` forms an exclusive loan on each
    (T2) and suspends `q`, the carrier passed; `q2` is another carrier of `y`,
    whose shared loan is live on the next line, so forming `z`'s exclusive loan
    on `y` is `StrictSharedBorrowInvalidated`, T4's shared-loan clause, at the
    `let ref z` (amended 2026-10-28, document-review fold: R1-m1; this read
    "live on the next line, so `q2->AsSlice()` is
    `StrictExclusiveBorrowConflict`"). Rejected at stage 4 (realigned
    2026-10-28, SAFE-2: W-347; the superseded 2026-10-12 text read: "`Pick`'s
    result carries `{(r, exclusive), (*p, shared)}` and is a shared-kind `ref`;
    the assignment of a new `Buf` through `z` is
    `StrictInvalidatingThroughShared`, the mutation page's diagnostic for a non-`Plain`
    assignment through shared-kind access, regardless of the view `v`; the live
    view of `y` through `q2` is the second reason.").

### EX-TM-9: A `ref` binding through a shared pointer

```carbon
// EX-TM-9 (F: today's syntax, accepted today — p005434:152-162's F without its Assert line; F2, F3: NEW — added 2026-10-28, SAFE-2: W-347)
fn F(ptr: i32*) {
  let ref x: i32 = *ptr;          // Strict: StrictRefFromShared — *ptr is an open place; Permissive: PermissiveAliasedExclusive
  x += 1;
}
fn F2(ptr: exclusive i32*) { let ref x: i32 = *ptr; x += 1; }   // accepted: a checked reborrow of the exclusive pointee
fn F3(ptr: i32*) { let ref x: i32 = unsafe *ptr; x += 1; }      // accepted: the marker takes on the noalias obligation (p005434:861-862)
```

[`ref` bindings](#ref-bindings), the open place. `ptr` is a shared-pointer
parameter, so `*ptr` is an open place: the caller may hold another `i32*` to
the same object, and nothing in `F` can show that none is used while `x`
lives, which is what `noalias` requires. Strict rejects `F` with
`StrictRefFromShared`; Permissive warns and accepts it, so the proposal's
example stays valid where unchecked code is allowed, as D-SAFE-8's break
condition requires. `F2` takes the exclusive kind, under which `x` is a checked
reborrow, and `F3` spells the obligation; the proposal's caller,
`var y: i32 = 2; F(&y);`, is unchanged for all three, `&y` on the owner
yielding `exclusive i32*`. Outcome: `F` ACCEPTS-UNCHECKED — the nightly
compiles it with exit status 0, and with
`fn Run() -> i32 { var y: i32 = 2; F(&y); Core.Print(y); return 0; }` the
linked program prints `3`; the proposal's own line `Assert(&x == ptr);` is left
out because the nightly has no pointer comparison ("cannot access member of
interface `Core.EqWith(i32*)` in type `i32*` that does not implement that
interface"). `F2` and `F3` are NEW-SYNTAX. Stage 4.

The checklist rows this page owns, in the checklist's own vocabulary:

| Rule | Example | Today | Evidence | Stage |
| --- | --- | --- | --- | --- |
| T5 `bound` | EX-TM-1 | NEW-SYNTAX | token_kind.def (no `bound`) | 1, 4 |
| T5c dangling return | EX-TM-2 | ACCEPTS-UNCHECKED | p005434 `Invalid1` (erroneous); nightly exit 0 | 3 (P-subset) |
| T3/T4 NLL | EX-TM-3 | ACCEPTS-UNCHECKED (Permissive semantics today; the `String` assignment under a live `const String*` compiles on the nightly, exit 0, and is accepted in Strict too) | string.carbon:16-28; buf.carbon:28-56 | 4 |
| Regression set | EX-TM-4 | ACCEPTS-UNCHECKED | judge 2's programs; buf.carbon:54-60; slice.carbon:26-28 | 3 (`Leak`, `Escape` with W-144), 4 (`Store`) |
| P-subset / `exclusive` | EX-TM-5 | NEW-SYNTAX | handle_expr.cpp:391-399 | 1, 3 |
| T5f named | EX-TM-6 | NEW-SYNTAX | — | 6 |
| T7 temporaries, `ref` | EX-TM-7 | REJECTS today ("cannot bind durable reference to non-reference value of type `str`", nightly 2026.10.12; p005434:173-175) | convert.cpp:2216-2219 TODO is the extension point | — |
| T7 temporaries, `bound` result | EX-TM-7b | ACCEPTS-UNCHECKED (fork prelude; `bound self` is W-144) | buf.carbon:54-56 | 4 (W-144) |
| T6 union laundering | EX-TM-8 `Wild`/`Wild3` | NEW-SYNTAX (`unsafe u.p`, `unsafe &u.p`, `bound`; the union is fork syntax, types/union_basic.carbon; the nightly has no `union`) | unions.md [Reads](../unions.md#reads), [Aliasing](../unions.md#aliasing) | 1, 3 |
| T2 copies preserve loans, W-144 signature audit | EX-TM-8 `Launder1` to `Launder5` | ACCEPTS-UNCHECKED (fork prelude) | slice.carbon:46-56, :74-77, :80-84, :100-106; as.carbon:37-39; optional.carbon:34-42, :69-78; buf.carbon:28, :45, :72-75; index.carbon:9; p005434 "`bound` parameters" | 3 with W-144 (`Launder1`, `Launder2`, `Launder4`, `Launder5`), 4 (`Launder3`) |
| D-SAFE-8 mixed-kind result, a `ref` binding on closed places (realigned 2026-10-28, SAFE-2: W-347) | EX-TM-8 `Pick`/`UsePick` | NEW-SYNTAX (`bound`) | p005434 `Conditional` | 1, 4 |
| D-SAFE-8 a `ref` through a shared pointer (added 2026-10-28, SAFE-2: W-347) | EX-TM-9 | ACCEPTS-UNCHECKED for `F` (nightly exit 0, prints 3); NEW-SYNTAX for `F2`, `F3` | p005434:152-162 | 1, 4 |

## C++ interop consequence

C++ is Permissive Carbon (D-SAFE-18): C++ code is trusted to meet its declared
contracts, and the loan checker never looks inside it. For temporal safety
that has these consequences:

-   **C++ `T&` is shared `T*`.** A C++ reference parameter imports as the
    shared-mutable kind, a C++ `const T&` as `const T*`, and a C++ object
    reachable through either may have any number of other aliases on the C++
    side. Nothing on the C++ side is ever an `exclusive T*`; an `exclusive T*`
    passed to C++ downgrades to shared at the call (T2), which is what rung 2
    of the strategy page's [migration example](README.md#c-migration-example)
    shows in `Unit`.
-   **Pointers returned by C++ are ⊥.** Every pointer, reference or view a C++
    function returns, and every pointer-typed field read from an imported C++
    type, has the loan set ⊥ (T6; the second clause is D-SAFE-18 amended
    2026-10-12, document-review fold: D-7): a Strict body that uses its pointee
    writes `unsafe *p`, and that marker is the audit point. This is the
    strategy's "there won't be an assumption that a call to C++ code won't save
    a copy of pointers to passed-in objects" (proposal p005914) turned around:
    Carbon also assumes nothing about what a C++ result points at.
-   **An unannotated pointer-carrying call is `unsafe`.** In Strict a C++
    function whose signature involves any pointer, reference, view or `this`
    is unsafe to call — `unsafe Cpp.F(...)`, else `StrictCppCallUnannotated` —
    unless its declaration carries annotations the importer maps or the call
    has one of the four shapes of the
    [C++ call allowlist](README.md#c-call-allowlist). The obligation the
    marker takes on is the one rung 3 of the migration example states: that
    the callee saves none of the pointers. The annotations and their mapping:
    `_Nonnull` gives a non-null `T*` (honored today,
    toolchain/check/cpp/import.cpp:1462-1509); `[[clang::lifetimebound]]` maps
    to `bound`, the equivalence p005434 itself draws under "`bound`
    parameters"; a noescape-style attribute maps to a non-`bound` parameter
    whose argument need not escape; thread-safety annotations map to the
    facets of the mutation page. The attribute names are
    [external facts](#external-facts). Rung 4 of the migration example,
    `UnitChecked`, is the annotated call: `&len` is a P1 loan on a local passed
    to a non-`bound` parameter, which is permitted, and no marker is needed.
-   **Permissive assumes non-escape, for diagnostics only.** In a Permissive
    body the unannotated call is unmarked and warns
    `PermissiveUnannotatedCppCall` from stage 3; the assumption that the C++
    callee saves no pointer is a diagnostic assumption and never a codegen
    one, because T8 withholds `noalias` and `captures(none)` at every such
    boundary. The strategy page names this reading of proposal p005914 as a
    departure.
-   **C++ methods are exclusive unless annotated.** A non-`const` C++ method
    imports as `ref self`, the invalidating receiver, callable through
    `exclusive T*`; through a shared `T*` only as `unsafe`, or by way of
    `Core.Guarded` (mutation page, M6). A `const` method imports as const
    access. A future non-invalidation annotation on a C++ method maps to
    `addr self`.
-   **C++ callers and function values switch off `noalias`.** A Carbon function
    exported to C++, or whose value crosses to C++ — the `std::thread`
    constructor over a Carbon `fn` in cpp_thread_carbon_fn_diff.carbon — is a
    function T8 emits no aliasing attribute for, so a C++ caller that aliases
    its `ref` parameter produces erroneous behavior and never undefined
    behavior.
-   **Migrated classes whose pointer fields outlive the value are
    `unsafe class`.** A C++ class holding a raw pointer it does not own
    migrates to Strict Carbon as a plain `class` when the pointer's loan is
    the value's own — a view over a constructor argument, the `Core.Slice`
    shape — and as an `unsafe class` under T5(g) when its invariant ties the
    pointer to storage the value does not borrow from its constructor — a node
    written through a free pointer, a registry entry — until stage 6's
    `bound(a)` fields can state that lifetime; in the second case its pointer
    fields are ⊥, so every read through them in Strict is marked, which is
    the audit surface of the migrated invariant.
-   **Temporaries diverge, as a compile error.** C++ code that binds a reference
    to a temporary and uses it later migrates to Carbon code that is
    `StrictBorrowOfTemporary` or rejected by today's `ref` rule, never to a
    dangling pointer; the fix is `var`. This is the interoperability
    philosophy's
    [object lifetimes](../interoperability/philosophy_and_goals.md#object-lifetimes)
    divergence made concrete.

The ladder a migrating codebase walks is the strategy page's: a Permissive glue
file behind a Carbon signature (rung 1), a Strict caller of the glue behind
`unsafe import` (rung 2), then a direct Strict call once the header carries
`_Nonnull` and the noescape attribute (rung 4), with the marked direct call
(rung 3) as the audited shortcut when the header cannot be annotated. Measured
on the fork's interop corpus with the allowlist in force, one C++ call site of
fourteen needs a marker, and it is a type-safety one (an imported
`operator=`), not a temporal one.

## Implementation staging

The rows this page owns in the staging of D-SAFE-21; the
[safety README](README.md#implementation-staging) carries the full table. 0.1
claims no executable behavior from this page: no loan is computed, no borrow
is diagnosed, and no Strict program is accepted or rejected by the 0.1
toolchain.

| Stage | Contents | Owned here |
| --- | --- | --- |
| 0 (this PR) | This page; no toolchain change | All of this page |
| 1 | Lex and parse `exclusive`, `bound`, `addr`, `unsafe class`; recorded in SemIR, unenforced | EX-TM-1, EX-TM-5 and EX-TM-8 parse (residue item W-145); `bound(a)` and EX-TM-6 are stage 6's |
| 3 | Strict static checks without loan sets; `--strict-checks=warn` default | The P1/P2/P3 subset: `StrictDanglingReturn` for a P1 return (EX-TM-2), `StrictBorrowOutlivesPlace` for `Leak` and `Escape` once W-144 lands, `StrictUnverifiedDeref` for P3; `StrictCppCallUnannotated` with the allowlist and the annotation mapping; the warning twins `PermissiveDanglingLoan` and `PermissiveUnannotatedCppCall` (residue item W-147, gated on W-144) |
| 4 | The loan checker | T1 to T8 and the Store rule over loan sets; `bound` per T5(a) to (e), with T5(d)'s hold of a `bound` pointer argument's pointee; `exclusive`; the reborrow and same-kind-copy clauses; frozen loans and the closed-place rule; `StrictExclusiveBorrowConflict`, `StrictSharedBorrowInvalidated`, `StrictRefFromShared`, `StrictBorrowOfTemporary`, `StrictStoreOutlivesSource`, `StrictEscapeOfUnboundParam`; `noalias` with `captures(none)` or `captures(ret: address, provenance)` under T8 where established (realigned 2026-10-28, SAFE-2: W-347, W-348, W-349); `error` default (residue item W-148) |
| 5 | Facets, `Core.Thread`, `--strict-concurrency` | `StrictBorrowOutlivesPlace` at a thread-crossing call whose argument's loan set is not free, the thread-boundary lifetime rule of the mutation page (residue item W-149) |
| 6 | `bound(a)` and `Core.Lifetime`, `Core.DynCast`, the Rust binding generator | T5(f): one name, one loan set; `bound(a)` fields replace the `unsafe class` interim for Strict classes with non-owning pointers (EX-TM-6; residue item W-150) |

Stage 2 owns nothing on this page. The prelude churn that stage 3 depends on —
`bound self` on `AsSlice`, `Subslice`, `Get`, `At`, the view conversions,
`Optional.Get` and `Branch`, `bound` on `FromArray`'s pointer, on
`Optional.Some`'s and `Buf.Make`'s value parameters and on the interface
declarations `IndexWith.At` and `Copy.Op`, and `UnsafeMake` becoming
`unsafe fn Make` — is residue item W-144 and is never assumed in an example
except where the example says so.

## Decisions within this design

Each decision below is a sub-decision of fork decision F-013, recorded with
its break condition in [fork/decision-log.md](/fork/decision-log.md); the
[safety README](README.md#decisions-within-this-design) and the other category
pages carry the rest of D-SAFE-1 to D-SAFE-23.

-   **D-SAFE-7 — Three pointer kinds; `T*` is the shared-mutable one.** `T*`
    is the shared-mutable pointer, `exclusive T*` the NEW exclusive-mutable
    kind, `const T*` the shared-const kind with `const` keeping its
    API-subsetting meaning; `&x` on a place under exclusive access yields
    `exclusive T*`, which converts implicitly downward and never upward except
    by `unsafe as`. Receivers: `ref self: Self` exclusive, `addr self: Self*`
    shared-mutable (restored), `ref self: const Self` and by-value `self`
    const. Break condition: a prelude or interop API that needs a fourth kind
    (exclusive-const) — added additively; the `exclusive` spelling is a
    mechanical rename.
-   **D-SAFE-8 — Every `ref` binding is `nocapture` and `noalias`.** Proposal
    p005434:83's rule holds for every `ref` binding, exclusive, or frozen for a
    `const` type: a checked reborrow on a closed place, and on an open place an
    `unsafe` formation (`StrictRefFromShared` unmarked), a `const` `ref` on a
    `Core.SharedImmutable` type excepted; a built-in operator's `ref` operand,
    an assignment's among them, lives for the one operation and is established
    on any place, M3 deciding what the operation may do (amended 2026-10-29,
    re-review round 2: RR1-M1); a `ref` return is not a binding, so
    `Valid1`, `ValToRef` and `Conditional` stay valid, a mixed result set
    taking the weakest kind; T8 emits `noalias` with `captures(none)` or
    `captures(ret: address, provenance)` only where established against every
    writer, on the body's own places and, under the whole-package condition,
    on `ref` and `exclusive T*` parameters' places, never on an open place nor
    for an `unsafe` one. Break condition: an accepted
    p005434 example that becomes invalid in Permissive mode (none may; the
    checklist lists them as accepted), or an accepted upstream memory-safety
    proposal that narrows p005434:83 (realigned 2026-10-28, SAFE-2: W-347; the
    heading read "`ref` bindings inherit the kind of their source." and the
    superseded 2026-10-12 text: "A `ref` from a place is exclusive; a `ref`
    from `*p` has `p`'s kind; a mixed loan set has the weakest kind and T4
    applies to every place in it. `noalias` and `captures(none)` are emitted
    only for exclusive-kind refs under T8, which narrows p005434:83 in a dated
    amendment on this page.").
-   **D-SAFE-10 — Loans T1 to T8 plus the Store rule.** As stated under
    [Rules T1 to T8 and the Store rule](#rules-t1-to-t8-and-the-store-rule),
    with the first enforceable subset P1/P2/P3 shipping at stage 3 only
    together with the prelude churn of W-144. Break condition: any
    Strict-accepted counterexample; judge 2's three programs (EX-TM-4) and the
    review set (EX-TM-8) are the standing regression set on this page.
-   **D-SAFE-11 — `bound` semantics fixed; named lifetimes pinned.** As stated
    under
    [`bound`, `bound(a)` and `unsafe class`](#bound-bounda-and-unsafe-class),
    with p005434:831-832's "immutable for the duration of the lifetime of the
    returned result" kept for each `bound` argument, a pointer argument's
    pointee included (T5(d); realigned 2026-10-28, SAFE-2: W-349, where this
    text read "with the narrowing of p005434:831-832 from "immutable" to "not
    invalidated""). Break condition: upstream amends p005434's `bound` with
    different semantics — a V-3 review; the fork keeps whichever is
    lower-divergence and records the delta.
-   **D-SAFE-12 — Temporaries: diagnose, do not extend.** A loan on a temporary
    lives until the end of the full-expression; a later use is
    `StrictBorrowOfTemporary`; `var` is the fix; the builder-chain idiom stays
    unsupported. Break condition: a migration corpus where builder chains
    dominate — an owner call on extension.

Two rules on this page rest on decisions other pages own. The unverified
dereference spelling of T6 and the `unsafe as` extent obligation are D-SAFE-5
([type safety](type_safety.md)); the relocation facet `Core.Relocatable` and the
move operator are D-SAFE-13 ([initialization safety](initialization_safety.md));
the no-invalidation rule that T4 enforces and the facets that extend
`StrictBorrowOutlivesPlace` to thread-crossing calls are D-SAFE-9, D-SAFE-16 and
D-SAFE-17 ([mutation safety](mutation_safety.md)); the C++ annotation mapping
and the allowlist are D-SAFE-18 ([safety README](README.md)).

## Alternatives considered

The design was chosen by a panel of three attempts and two judges, recorded in
[fork/safe/plan.md](/fork/safe/plan.md); the judges scored the attempts as
wholes, and the [safety README](README.md#alternatives-considered) carries
their verdicts. The alternatives specific to this page:

-   **Attempt A's exclusive-by-default `T*`.** Attempt A, "Strict Carbon by
    default: owners, loans, and operation-tied `unsafe`", made `T*` the
    exclusive pointer, re-meant `const T*` as shared-immutable, and added a
    NEW `shared T*`. Judge 1 found this fatal (item A): the C++ `T&` to `T*`
    mapping and the prelude's own `ptr: T*` fields in `Slice` and `Buf` are
    shared views of one block, so an exclusive `T*` turns every one of them
    into an unverified `noalias` claim, and `const` acquiring "shared" reads
    into `const` a meaning [values](../values.md#const-qualified-types) rules
    out. The synthesis keeps `T*` shared and takes A's explicit exclusive kind
    as a third kind beside it.
-   **Attempt B's single pointer kind.** Attempt B, "Places, projections and
    shared cells", had no exclusive pointer _type_ at all: `ref` was the only
    exclusive access and `T*` the only pointer. Both judges found this fatal
    (item B): judge 2 wrote that "its single-pointer-kind choice contradicts
    p005434:710-713/826 and makes `ref self` ... unreachable through a pointer
    in Strict; repairing that means adding the exclusive pointer kind, which
    turns B into A", and judge 1 asked for the same graft. D-SAFE-7 and
    D-SAFE-8 are that repair: `exclusive T*` exists, `ref self` is
    reachable through it, and the proposal's `Valid1` and `ValToRef` stay valid
    because they return reference expressions, not bindings (realigned
    2026-10-28, SAFE-2: W-347; this text read "and a `ref` through `*p`
    inherits `p`'s kind so that the proposal's `Valid1` and `ValToRef` stay
    valid").
-   **Attempt C's `derived(...)` and `exclusive ref`.** Attempt C, "Ratchet:
    hardened runtime core now, annotated borrows later", annotated returns
    with `derived(...)` naming the parameters a result derives from, and
    spelled exclusive access as `exclusive ref`. Both are rejected because
    they duplicate what proposal p005434 already has: `derived(...)` is
    `bound` under another name (p005434, "`bound` parameters" and "How
    addresses interact with `ref`"), and `exclusive ref` is what `ref` already
    means. The synthesis takes C's P1/P2/P3 subset and its `unsafe class`
    interim and leaves the spellings.
-   **Attempt C's stage with no loan sets as a soundness claim.** Attempt C
    claimed temporal soundness for its stage 1, whose only temporal rule was
    the non-escaping pointer rule. Judge 2 found it fatal with the programs
    `Leak` and `Escape` of EX-TM-4: a view of a local escapes as a class value
    and the P rule never fires. The subset is kept, but as a stage-3 checker
    that is sound only with W-144's `bound` on the view producers, and never
    as the design's guarantee.
-   **Attempt A's return-only `bound` without a store rule.** Judge 2 refuted
    attempt A's T5(a) with the global `Holder` program of EX-TM-4: a loan on a
    local stored through a free pointer escapes with no return involved. The
    Store rule is attempt B's answer and is grafted.
-   **Swift-style dynamic exclusivity on every access.** Rejected on budget:
    the strategy's temporal overhead ceiling is under one percent in aggregate
    (proposal p005914), and the strategy page's constraints rule out the
    probabilistic variants. `Core.Guarded(T)` (mutation page) is the one
    opt-in run-time check, chosen per object.
-   **Quarantine-class hardening for dangling unsafe accesses.** Rejected on
    the same budget; the design states the narrowing instead, under
    [The unsafe-code contract](#the-unsafe-code-contract).

That decision is final; this page specifies the chosen design rather than
relitigating it.

## External facts

Claims about tools outside this repository appear only here, with a status
(D-SAFE-22). No normative rule on this page depends on an UNVERIFIED item: the
rules T1 to T8 are stated in the repository's own vocabulary, and the Rust
analogues in the kinds table are analysis, owned by
[Safe-Rust interop](rust_interop.md).

| Fact | Used by | Status |
| --- | --- | --- |
| Rust's `&mut T` is the unique way to access its referent while it is live, and any number of `&T` may exist to a value, during which direct mutation of the value is prevented except through interior mutability | The Rust analogue column of the kinds table; the analogy between T4 and Rust's borrow rules | VERIFIED against the Rust Reference, "Pointer types" ("A mutable reference (that hasn't been borrowed) is the only way to access the value it points to"; "When a shared reference to a value is created, it prevents direct mutation of the value ... any number of shared references to a value may exist"), read 2026-10-12 |
| Rust's borrow checker computes a reference's lifetime over the control-flow graph, so a borrow ends at the reference's last possible use rather than at the end of its lexical scope, and the core analysis is within one function | T3's liveness rule, which the design adopts under the same name | VERIFIED against RFC 2094 ("non-lexical lifetimes", "lifetimes that are based on the control-flow graph, rather than lexical scopes"; "the lifetime of a reference lasts only for those portions of the function in which the reference may later be used"; "a basic design focused on control-flow within one function"), read 2026-10-12 |
| Polonius is a formulation of Rust's borrow check in terms of origins (the loans a reference may hold) rather than lifetimes as regions, from which this page's "origin" word is taken | The vocabulary section's _origin_; no rule depends on it | UNVERIFIED: we expect the description to be accurate; the project's own page, read 2026-10-12, says only that it "models the borrow check" and does not state the formulation |
| LLVM's `noalias` parameter attribute means that memory accessed through pointers based on the argument is not also accessed, during the function, through pointers not based on it, for locations modified during the function, with undefined behavior otherwise; `captures(none)` means the pointer is not captured | T8's codegen rule and the reason the attributes are withheld at Permissive and C++ boundaries | VERIFIED against the LLVM Language Reference, "Parameter Attributes" ("memory locations accessed by way of pointer values based on the argument or return value are not also accessed, during the execution of the function, by way of pointer values not based on the argument or return value"; "If there are other accesses not based on the argument or return value, the behavior is undefined"; "`captures(none)`: Pointer not captured"), read 2026-10-12 |
| Clang's `[[clang::lifetimebound]]` attribute and a noescape-style parameter attribute exist with the meanings the importer maps to `bound` and non-`bound` | The annotation mapping under [C++ interop consequence](#c-interop-consequence) | UNVERIFIED as external facts on this page; the `lifetimebound` equivalence itself is in-repository (p005434), the `_Nonnull` mapping is VERIFIED on the [safety README](README.md#external-facts), and the attribute names are a stage-3 item |
| Ante's shared-mutable reference is thread-local and its exclusive reference is the only one through which invalidating operations are permitted | The description of `T*` as "the Ante-style shared-mutable pointer" in the plan; no rule on this page depends on it | UNVERIFIED: we expect Ante's documentation to state this; the design's own rule is M3 of the mutation page, stated without reference to Ante |

## References

-   Proposal
    [p005434: `ref` parameters, arguments, returns and `val` returns](/proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md),
    whose `bound`, `ref` and `val` vocabulary this page fixes.
-   Proposal
    [p005914: Updating Carbon's safety strategy](/proposals/p005914-updating-carbon-s-safety-strategy.md).
-   Proposal
    [p000257: Initialization of memory and variables](/proposals/p000257-initialization-of-memory-and-variables.md),
    for the unformed state that relocation leaves behind.
-   Proposal
    [p006357: C++ interop: mapping pointer types](/proposals/p006357-c-interop-mapping-pointer-types.md),
    for `Core.Optional(T*)` and the `_Nonnull` mapping.
-   [Values](../values.md): reference expressions, pointers,
    `const`-qualified types and the value-binding mutation restriction.
-   The design overview's [pointer types](../README.md#pointer-types) and
    [move](../README.md#move) sections.
-   [Unions: reads](../unions.md#reads) and
    [aliasing](../unions.md#aliasing).
-   [Slices](../slices.md) and the prelude's `Core.Slice` and `Core.Buf`
    (core/prelude/types/slice.carbon, buf.carbon).
-   [Interoperability philosophy and goals: object lifetimes](../interoperability/philosophy_and_goals.md#object-lifetimes).
-   [Safety](README.md): the soundness model, the safety modes, the diagnostic
    matrix, the pointer kinds table, the C++ call allowlist and the migration
    example; the [terminology](terminology.md) page.
-   The sibling category pages: [Type safety](type_safety.md) for `unsafe as`
    and `unsafe *p`, [Initialization safety](initialization_safety.md) for
    `~x`, [Spatial safety](spatial_safety.md) for views and the W-144
    signature rule, [Mutation safety](mutation_safety.md) for M1 to M8 and the
    facets, and [Safe-Rust interop](rust_interop.md) for the mapping.
-   Fork decision [F-013](/fork/decision-log.md) and the synthesized plan
    [fork/safe/plan.md](/fork/safe/plan.md), whose design-panel record is the
    option paper for this area.
-   The conformance programs fork/conformance/programs/types/union_basic.carbon
    and fork/conformance/programs/interop/cpp_span_view.carbon,
    cpp_export_method.carbon and cpp_thread_carbon_fn_diff.carbon.
