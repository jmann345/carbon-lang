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
[fork/safe/plan.md](/fork/safe/plan.md). No part of this page is implemented
in the toolchain (fork workstream SAFE-1, stage 0); see
[Implementation staging](#implementation-staging). The toolchain today has no
loan analysis and no borrow diagnostic, and the tokens `bound`, `addr` and
`exclusive` do not exist: toolchain/lex/token_kind.def declares `unsafe` as a
keyword and none of the three. Every pointer in today's toolchain behaves as an
unmarked Permissive pointer, and today's `ref` bindings are checked only by the
rule of proposal p005434 that a `ref` binds a durable reference expression.
File and line citations are against trunk 0bdce60a5 unless a citation says
otherwise; the examples marked "today's syntax" were compiled on the 2026.10.12
nightly toolchain and their outcomes are stated with each example.

## Vocabulary

The rules use seven words, fixed by D-SAFE-10.

-   A _place_ is the storage of a durable reference expression
    ([values: reference expressions](../values.md#reference-expressions)): a
    `var`, a `var` parameter, a field, a materialized temporary, or the storage
    behind a pointer. Places nest: `x.f` and `*p` are places within the places
    `x` and `*p`'s pointee, and `root(P)` names the outermost place that `P`
    lies within, which is the one whose lifetime bounds `P`'s.
-   A _loan_ is a triple of a place, a _kind_ and an _origin_. The kind is
    _exclusive_ or _shared_; the origin is the expression that formed the loan,
    which the diagnostics name.
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
| unverified (any kind) | the same spellings, loan set ⊥ | `unsafe as` from non-pointers, `unsafe fn`/C++ results, union reads and `unsafe &u.f`, `unsafe class` fields | ⊥ | copy, compare, store, pass; `unsafe *p` to use | — | raw pointer |

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
other access to the object is live while the result is used.

The receiver forms follow the kinds. `ref self: Self` is exclusive access, as
proposal p005434 defines it. `addr self: Self*` is the shared-mutable receiver,
restored for exactly the purpose p005434 reserves it under "Restore `addr`":
"to allow the `self` parameter to use one of the pointer semantics we create as
part of the upcoming memory safety design". Its declared type is the pointer
type the body sees, `Self*`, rather than the historic `addr self: Self` that
third_party/examples/re2/re2.carbon:769 still spells in a file no target
builds, because the receiver is the address-taking form and the body uses it
as a shared pointer. `ref self: const Self` and by-value `self` are const
access. The method classification this gives — which methods may invalidate,
which may only write `Plain` fields — is rule M4 of the
[mutation safety](mutation_safety.md) page.

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

A `ref` binding inherits the kind of its source (D-SAFE-8). A `ref` formed from
a place is exclusive access, as p005434 states and this design keeps: "A `ref`
binding may only bind to a durable reference expression or an expression that
can be converted to one. The bound durable reference expression must outlive
the `ref` binding." A `ref` formed from `*p` inherits `p`'s kind: exclusive
from `exclusive T*`, shared-mutable from `T*`, under which the mutation page's
M3 applies to every use of the binding, and const from `const T*`. So the
proposal's `Valid1(bound p: i32*) -> ref i32 { return *p; }` and its
`ValToRef(bound y: C) -> ref D { return *y.ptr; }` stay valid in both modes,
the result being a shared-kind `ref`: a `ref` through which an invalidating
operation is rejected but a `Plain` write is not.

A `ref` or a call result whose loan set mixes kinds has the **weakest** kind:
shared if any loan in the set is shared, const if any is const. The proposal's
`Conditional(b: bool, bound ref r: C, bound p: C*) -> ref C` carries the set
`{(r, exclusive), (*p, shared)}` and so is a shared-kind `ref`, and T4 applies
to every place in the set. The program `Pick`/`UsePick` of EX-TM-8 is this
rule's example: a non-`Plain` assignment through such a `ref` is
`StrictInvalidatingThroughShared` regardless of whether any other view is
live.

> **Narrowing (fork amendment 2026-10-12, F-013 D-SAFE-8).** Proposal p005434
> states (p005434:82) that "the address of a `ref` binding is `nocapture` and
> `noalias`". This design emits `noalias` and `captures(none)` only for
> exclusive-kind refs, and only under the conditions of T8 below; a shared-kind
> `ref` carries neither attribute. The proposal's sentence is kept for the
> exclusive kind and narrowed for the rest, because a shared-kind `ref` is, by
> construction, one alias among many.

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
-   `let ref r = x;` forms an exclusive loan on `x`
    ([`ref` bindings](#ref-bindings)).
-   A value binding of a non-`Plain` type, from `*p` or from an owner, forms a
    shared loan on the bound object for the binding's lifetime (D-SAFE-17, rule
    M8 of the mutation page); a value binding of a `Plain` type copies eagerly
    and holds no loan; and a value binding of a non-`Plain` type from an
    initializing expression — a materialized temporary, the third source
    [values](../values.md#binding-patterns-and-local-variables-with-let-and-var)
    names — takes ownership of the materialized storage, the `var` rule
    applied to `let`, and holds no loan on it. The loans carried _by_ the
    bound value are unaffected in every case.
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
`exclusive T*` to `T*` downgrade, a `bound self` by value, an `addr self` call,
`&*p` at shared kind — _suspends_ the carrier's exclusivity: until every
derived loan is dead the carrier may be used only at shared kind (reads,
`Plain` writes, `addr` and `const` methods, further shared loans), and an
invalidating use of it is `StrictSharedBorrowInvalidated`. This is how the
mutation page's EX-M-1 reads: `vec->Get(0)` while a derived view lives is a
shared use, and `vec->Push(3)` is legal only once every derived view is dead.

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

A live exclusive loan excludes every other access to overlapping places,
except through the suspended carrier at shared kind (the reborrow clause of
T2): a second loan or a direct use while one is live is
`StrictExclusiveBorrowConflict`. A live shared loan excludes exclusive loans
and invalidating operations on overlapping places — destruction, `~`,
assignment of a non-`Plain` value, a `ref self` call, formation of an exclusive
loan, the mutation page's rule M3 — and an invalidating operation on a place
`P` kills every interior loan on `P`: the operation is
`StrictSharedBorrowInvalidated` while such a loan is live. For a carrier whose
loan set mixes kinds, T4 is applied to every place in the set at the weakest
kind ([`ref` bindings](#ref-bindings)). T4 and the mutation page's rule M2 are
one rule seen from two sides: T4 is stated over loans and M2 over the access a
place is under.

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
-   the result of any `unsafe fn` call and of any unannotated C++ call;
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

A ⊥ pointer may be copied, compared, stored and passed. Dereferencing it
(`*p`, `p->m`), binding a `ref` through it, forming a view from it, or passing
it to a `bound` parameter needs `unsafe *p`, the operation-tied spelling of
[type safety](type_safety.md), and the obligation that spelling takes on is
that the storage outlives every use derived from the dereference; an unmarked
use is `StrictUnverifiedDeref`. `unsafe as` between pointer types preserves the
loan set of its operand, so a conversion never extends a lifetime, and its own
obligation is the type-safety one, extent included. The programs `Wild` and
`Wild3` of EX-TM-8 are this rule's regression set: the first is the case the
strategy page's narrowness principle names, an unsafe type conversion that
must not also allow out-of-lifetime access; the second shows why the pointer
itself, not the value loaded through it, must be ⊥ — a Strict callee that
returns the pointee of a `bound` pointer-to-pointer parameter is correct code
that cannot see the union, and its result over such an argument must stay ⊥.

### T7: Temporaries

T7 is D-SAFE-12, stated in [Temporaries](#temporaries).

### T8: Codegen honesty

`noalias` and `captures(none)` are emitted for exclusive loans only where the
checker established them: intra-function, and on `ref` and `exclusive T*`
parameters of functions that are not exported to C++, not address-taken (no
function value crosses to C++ or Permissive code), and whose every Carbon call
site in the package is Strict-checked. That is a whole-package fact, and
otherwise the attributes are never emitted, which is the policy p005434 states
under "How addresses interact with `ref`": "these attributes won't be passed to
LLVM unless their requirements can be established". The fork's own corpus has
both excluded shapes: C++ calls `fn Bump(ref self, n: i32)` from `inline Cpp`
(fork/conformance/programs/interop/cpp_export_method.carbon:31-33), and
`std::thread` takes a Carbon function value
(cpp_thread_carbon_fn_diff.carbon:38-45), and both are callers the
whole-package fact must count. A Permissive or C++ caller that aliases such a
parameter produces erroneous behavior, never undefined behavior, which is the
strategy's rule that "the optimization of safe code will not rely on
properties that are not established locally" (proposal p005914).

## The first enforceable subset

Stage 3 ships a checker with no loan sets, the P1/P2/P3 subset, a strict subset
of T1 to T8 that attempt C contributed and both judges asked for:

-   **P1** — a pointer formed by `&local` or `&param` in the body being
    checked. It may be dereferenced and passed to a non-`bound` parameter; it
    may never escape: not returned, not stored, not passed to a `bound`
    parameter whose result escapes.
-   **P2** — a pointer parameter of the function, or a `ref` binding. It may be
    dereferenced without a marker; it escapes only as T5 allows.
-   **P3** — everything else: a pointer that was returned by a call, loaded
    from memory, converted, or produced by C++. It is ⊥ to the subset, so its
    dereference needs `unsafe *p`.

The subset proves T5(c) for the return of a P1 pointer (EX-TM-2), the Store
rule for a P1 pointer stored anywhere, and T6 for P3; it proves nothing about
views. It is sound only together with the prelude churn of W-128: without
`bound self` on `Core.Buf.AsSlice` and `bound p` on `Core.Slice.FromArray`, a
view of a local escapes as a class value and no P rule fires, which is judge
2's refutation of attempt C's stage-1 claim (`Leak` and `Escape` in EX-TM-4).
With W-128 in place, a view is a P1 carrier when its `bound` argument was P1,
and `Leak` and `Escape` are rejected at stage 3; `Store` needs the Store rule
over a ⊥ destination and is rejected at stage 4.

## `bound`, `bound(a)` and `unsafe class`

This section is D-SAFE-11 and rule T5. `bound` is the one lifetime annotation,
kept from proposal p005434 with its semantics now fixed.

-   **(a) The result's loans.** The loan set of a call's result is the union of
    the loan sets of the arguments passed to `bound` parameters, `self`
    included, with kind equal to the parameter's kind: `ref` and
    `exclusive T*` parameters give exclusive, value, `T*` and `const`
    parameters give shared, and a mixed set takes the weakest kind. A function
    with no `bound` parameters returns a free value, subject to the Store rule;
    this is never read as applying to a copy, a conversion or a `Copy.Op` of
    an existing value (T2). A prelude function whose result can carry a loan
    from a parameter — a view of `self`, a `T` payload returned from `self`, a
    `T` argument stored into the result — without `bound` on that parameter is
    a defect of the W-128 audit under the spatial page's rule SP3, not a loan
    boundary. A ⊥ argument to a `bound` parameter makes the result ⊥, after
    the `unsafe` that T6 demands for the pass.
-   **(b) Escape in the callee.** A non-`bound` pointer or `ref` parameter may
    not escape: not returned, not stored, not passed as a `bound` argument
    whose result escapes; the violation is `StrictEscapeOfUnboundParam`. A
    `bound` parameter may escape only into the return value.
-   **(c) Dangling returns.** Returning a loan on a local, a temporary or a
    `var` parameter is `StrictDanglingReturn`. The cases p005434 calls
    erroneous under "`bound` parameters" (`Invalid1` to `Invalid3`) become hard
    errors in Strict and warnings in Permissive.
-   **(d) The argument stays borrowed.** For the duration of a returned loan
    the bound argument stays borrowed in the caller at the parameter's kind.
    The proposal asks (p005434:826-830) for the bound parameter to be
    "immutable for the duration of the lifetime of the returned result"; this
    design narrows "immutable" to "not invalidated": a shared-kind bound
    argument stays writable in its `Plain` fields through other aliases, the
    same narrowing D-SAFE-17 applies to value bindings. This is a dated
    narrowing, recorded here and in the F-013 entry.
-   **(e) Interfaces.** An impl may drop but not add `bound` relative to its
    interface, as the proposal states. This is why the prelude's interface
    declarations `IndexWith.At` (core/prelude/operators/index.carbon:9) and
    `Copy.Op` carry `bound self` themselves after W-128: a user-written
    `Copy.Op` may then keep its loan without (a) reading its result as free,
    while the prelude's primitive copies stay governed by T2.
-   **(f) Named lifetimes.** `bound(a)`, with `[a: Core.Lifetime]` as a deduced
    parameter, is pinned now and implemented at stage 6. One name is one loan
    set: every argument passed to a `bound(a)` parameter, every `bound(a)`
    field of the receiver and the result join a single set whose kind is the
    weakest among them; a store from a place in set `a` into a place in set `a`
    passes the Store rule; two names are unrelated sets. Bare `bound` is the
    elision form and expresses no relation between names. An outlives relation
    between names (`a: b`) is deferred to the stage-6 plan (W-134). The
    proposal already defers linked structures to "More precise lifetimes";
    EX-TM-6 is the shape that section asks for.
-   **(g) The `unsafe class` interim.** Until stage 6, a Strict class with a
    non-owning pointer field is declared `unsafe class`: its invariant is the
    author's, every construction site in Strict is `unsafe` because
    construction may store non-free loans, its pointer fields are ⊥ (reads
    through them need `unsafe *`), and the Store rule treats them as a ⊥
    destination that accepts only free loans. `Holder` in EX-TM-4 is the
    shape, and its `h->p = &y` is `StrictStoreOutlivesSource` by this rule.

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
| `StrictSharedBorrowInvalidated` | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` for the value-binding case (D-SAFE-17) |
| `StrictBorrowOutlivesPlace`, `StrictBorrowOfTemporary`, `StrictDanglingReturn`, `StrictStoreOutlivesSource`, `StrictEscapeOfUnboundParam` | error | warning `PermissiveDanglingLoan` | ASan-class detection |
| `StrictCppCallUnannotated` | error | warning `PermissiveUnannotatedCppCall` — assumed fact | — |

The diagnostics and what each names:

-   `StrictExclusiveBorrowConflict`: "`{0}` is borrowed exclusively by `{1}`
    here, used again at {2}", placed at the conflicting use, with `{1}` the
    origin of the live exclusive loan (T4).
-   `StrictSharedBorrowInvalidated`: placed at the invalidating operation,
    naming the place and the live shared loan's origin (T4; the reborrow
    clause of T2).
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
design must reject and are kept verbatim from the plan.

### EX-TM-1: A `bound` result borrows both arguments

```carbon
// EX-TM-1 (NEW: `bound` token): result borrows both, shared
fn Longest(bound a: const Core.String*, bound b: const Core.String*) -> const Core.String* {
  if (a->Size() > b->Size()) { return a; } else { return b; }
}
```

Rule T5(a). Outcome today: NEW-SYNTAX — toolchain/lex/token_kind.def has no
`bound` token. Under the design the result's loan set is the union of `a`'s
and `b`'s at shared kind, so in a caller both arguments stay borrowed, not
invalidated, while the result is live; neither may be destroyed or assigned a
non-`Plain` value, and both may still be read. Lands at stage 1 (the token) and
stage 4 (the loan).

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
enforceable subset (residue item W-131).

### EX-TM-3: Liveness and non-invalidating writes

```carbon
// EX-TM-3 (today's syntax for everything but the `bound` on AsSlice, which is W-128; amended
// 2026-10-12, review fold: B2 — the prelude's String is Plain, so the invalidating assignment is a Buf's)
fn Use() {
  var s: Core.String = "abc";
  let p: const Core.String* = &s;   // shared loan on s
  Core.Print(p->Size() as i32);
  s = "def";                        // OK even while p is live: String is Plain (B2), assignment is non-invalidating
  var buf: Core.Buf(i32) = Core.Buf(i32).Make(4, 0);
  let v: Core.Slice(i32) = buf.AsSlice();   // AsSlice is [bound self] after W-128: v holds an interior loan on buf
  buf.Set(1, 7);                    // OK: Set is non-invalidating and i32 is Plain
  Core.Print(v[1]);                 // prints 7; last use of v: loan ends (NLL)
  buf = Core.Buf(i32).Make(1, 0);   // OK after v is dead; before it: StrictSharedBorrowInvalidated (the block v views is freed)
}
```

Rules T3 and T4 with the mutation page's M3. Outcome today: ACCEPTS-UNCHECKED
— the `String` half (the first five statements, with `Core.Print` given the
`as i32` the [slices](../slices.md) design uses for a `Size()` result) compiles
on the nightly with exit status 0, and it is accepted in Strict too: the
prelude's `String` is a non-owning `{Char*, i64}` with `impl as Copy` and no
`Destroy` (core/prelude/types/string.carbon:16-28), so it is `Plain` and the
assignment under the live `const String*` is non-invalidating. The `Buf` half
is fork prelude code (`Make`, `Set`, `AsSlice` at
core/prelude/types/buf.carbon:28-56) and is not compile-verified against the
upstream nightly; the view `v` holds an interior loan on `buf` once `AsSlice`
is `[bound self]` (W-128), `buf.Set(1, 7)` is permitted through it because
`Set` is non-invalidating and `i32` is `Plain`, and the last use of `v` ends
the loan, after which the assignment to `buf` — which frees the block `v`
viewed — is legal. Moved one line earlier, that assignment is
`StrictSharedBorrowInvalidated`. The loan rule lands at stage 4.

### EX-TM-4: The regression set

```carbon
// EX-TM-4 (regression set, judge 2 — all three are accepted by today's toolchain and must be
// rejected by stage 4; the first two also by stage 3 once W-128 lands)
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
with `unsafe class` as the one NEW spelling (a plain `class` until stage 6, as
the comment says). Under the design: `Leak` returns a view whose loan is on the
local `b`, whose `Destroy` frees the block, and the return copy keeps the loan
by T2, so it is `StrictBorrowOutlivesPlace`; `Escape` stores a view of the
inner-scope array `a` into the outer `s` and reads it after `a` ended, which is
`StrictBorrowOutlivesPlace` at the inner scope's exit; `Store` writes a loan on
the local `y` into a ⊥ destination, the pointer field of an `unsafe class`
reached through a free pointer, and is `StrictStoreOutlivesSource`. `Leak` and
`Escape` are rejected at stage 3 once W-128 gives `AsSlice` and `FromArray`
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
free under T5(a) in the full checker but P3 to the subset, which has no loan
sets; the subset therefore demands `unsafe *r`, and the full checker at stage 4
accepts `*r` unmarked because the result is free. The marked form is correct
in both. Lands at stage 1 (the token) and stage 3 (the subset).

### EX-TM-6: Named lifetimes

```carbon
// EX-TM-6 (NEW, stage 6): named lifetimes
fn Push[a: Core.Lifetime](list: bound(a) List*, node: bound(a) Node*) { list->head = .Some(node); }
```

Rule T5(f). Outcome today: NEW-SYNTAX, stage 6 (residue item W-134). Under the
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
// EX-TM-7b (today's syntax except the `bound self` on AsSlice, W-128): a `bound` result on a temporary
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
the view are what the rule checks. Rejected at stage 4 with W-128.

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
  return s.Subslice(0, 2);          // StrictDanglingReturn: Subslice is [bound self] (W-128, A-2) — a sub-loan on a
}
fn Launder2() -> Core.Slice(const i32) {
  var v: Cpp.std.vector(i32) = Cpp.MakeVector();         // the cpp_span_view.carbon:64-65 shape
  let view: Core.Slice(const i32) = v;                   // the container ImplicitAs is [bound self] (W-128, A-2)
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
  var o: Core.Optional(i32*) = Core.Optional(i32*).Some(&x);   // Store rule: x outlives o — accepted; Some's `bound value` (W-128, RR-2) puts x's loan in o
  return o.Get();                   // StrictDanglingReturn: Get is [bound self] after W-128 (RR-2) — rev 2's receiver grep missed a result of type T
}
fn Launder5() -> Core.Optional(i32*) {
  var x: i32 = 1;
  return Core.Optional(i32*).Some(&x);   // StrictDanglingReturn: Some has no receiver; `bound value` (W-128, RR-2) carries the loan on x into the result
}
fn Pick(b: bool, bound ref r: Core.Buf(i32), bound p: Core.Buf(i32)*) -> ref Core.Buf(i32) {
  if (b) { return r; } else { return *p; }               // p005434:772-779's Conditional: result kind is the weakest (shared)
}
fn UsePick() {
  var x: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  var y: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  let q: Core.Buf(i32)* = &y;  let q2: Core.Buf(i32)* = &y;
  let ref z: Core.Buf(i32) = Pick(false, x, q);          // z: shared-kind ref whose loan set covers x and y (A-5)
  let v: Core.Slice(i32) = q2->AsSlice();                // interior loan on y
  z = Core.Buf(i32).Make(5, 0);     // StrictInvalidatingThroughShared (RR-7): a non-Plain assignment through a shared-kind ref, rejected regardless of v; y's live view is the second reason
  Core.Print(v[0]);
}
```

Rules T6, T2, T5(a) and D-SAFE-8; the programs the plan's reviews added, kept
verbatim, each of which must be rejected by stage 4 with the diagnostic named
in its comment. Outcome today: NEW-SYNTAX for `Wild`, `Wild3`, `Pick` and
`UsePick` (`unsafe u.p`, `unsafe &u.p` and `bound` do not parse; the `union`
itself is fork syntax proven by
fork/conformance/programs/types/union_basic.carbon, and the upstream nightly
has no `union`); ACCEPTS-UNCHECKED for `Launder1` to `Launder5`, which are
today's syntax over the fork prelude (`Subslice` at slice.carbon:46-52, the
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
-   **`Load`** (T5(a)). Correct Strict code, accepted: a read through a
    verified `bound` pointer-to-pointer whose result carries `q`'s loans at
    shared kind.
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
    two are rejected at stage 3 with W-128, the third at stage 4.
-   **`Launder4`, `Launder5`** (T5(a) and the W-128 audit). `Optional.Some` has
    no receiver and stores its `T` argument into the result; `Optional.Get`
    returns a `T` payload from `self`. Both carry a loan when `T` is a pointer
    type, so both are `bound` after W-128 — a receiver-only audit would have
    missed them — and the returns are `StrictDanglingReturn`. Rejected at
    stage 3 with W-128.
-   **`Pick`, `UsePick`** (D-SAFE-8). `Pick`'s result carries `{(r, exclusive),
    (*p, shared)}` and is a shared-kind `ref`; the assignment of a new `Buf`
    through `z` is `StrictInvalidatingThroughShared`, the mutation page's
    diagnostic for a non-`Plain` assignment through shared-kind access,
    regardless of the view `v`; the live view of `y` through `q2` is the
    second reason. Rejected at stage 4.

The checklist rows this page owns, in the checklist's own vocabulary:

| Rule | Example | Today | Evidence | Stage |
| --- | --- | --- | --- | --- |
| T5 `bound` | EX-TM-1 | NEW-SYNTAX | token_kind.def (no `bound`) | 1, 4 |
| T5c dangling return | EX-TM-2 | ACCEPTS-UNCHECKED | p005434 `Invalid1` (erroneous); nightly exit 0 | 3 (P-subset) |
| T3/T4 NLL | EX-TM-3 | ACCEPTS-UNCHECKED (Permissive semantics today; the `String` assignment under a live `const String*` compiles on the nightly, exit 0, and is accepted in Strict too) | string.carbon:16-28; buf.carbon:28-56 | 4 |
| Regression set | EX-TM-4 | ACCEPTS-UNCHECKED | judge 2's programs; buf.carbon:54-60; slice.carbon:26-28 | 3 (`Leak`, `Escape` with W-128), 4 (`Store`) |
| P-subset / `exclusive` | EX-TM-5 | NEW-SYNTAX | handle_expr.cpp:391-399 | 1, 3 |
| T5f named | EX-TM-6 | NEW-SYNTAX | — | 6 |
| T7 temporaries, `ref` | EX-TM-7 | REJECTS today ("cannot bind durable reference to non-reference value of type `str`", nightly 2026.10.12; p005434:173-175) | convert.cpp:2216-2219 TODO is the extension point | — |
| T7 temporaries, `bound` result | EX-TM-7b | ACCEPTS-UNCHECKED (fork prelude; `bound self` is W-128) | buf.carbon:54-56 | 4 (W-128) |
| T6 union laundering | EX-TM-8 `Wild`/`Wild3` | NEW-SYNTAX (`unsafe u.p`, `unsafe &u.p`, `bound`; the union is fork syntax, types/union_basic.carbon; the nightly has no `union`) | unions.md [Reads](../unions.md#reads), [Aliasing](../unions.md#aliasing) | 1, 3 |
| T2 copies preserve loans, W-128 signature audit | EX-TM-8 `Launder1` to `Launder5` | ACCEPTS-UNCHECKED (fork prelude) | slice.carbon:46-56, :74-77, :80-84, :100-106; as.carbon:37-39; optional.carbon:34-42, :69-78; buf.carbon:28, :45, :72-75; index.carbon:9; p005434 "`bound` parameters" | 3 with W-128 (`Launder1`, `Launder2`, `Launder4`, `Launder5`), 4 (`Launder3`) |
| D-SAFE-8 mixed-kind result | EX-TM-8 `Pick`/`UsePick` | NEW-SYNTAX (`bound`) | p005434 `Conditional` | 1, 4 |

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
    function returns, and every pointer loaded from a C++ object, has the loan
    set ⊥ (T6): a Strict body that uses its pointee writes `unsafe *p`, and
    that marker is the audit point. This is the strategy's "there won't be an
    assumption that a call to C++ code won't save a copy of pointers to
    passed-in objects" (proposal p005914) turned around: Carbon also assumes
    nothing about what a C++ result points at.
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
-   **Migrated classes with non-owning pointer fields are `unsafe class`.** A
    C++ class holding a raw pointer it does not own migrates to Strict Carbon
    as an `unsafe class` under T5(g) until stage 6's `bound(a)` fields can
    state the lifetime; its pointer fields are ⊥, so every read through them
    in Strict is marked, which is the audit surface of the migrated invariant.
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
| 1 | Lex and parse `exclusive`, `bound`, `addr`, `unsafe class`, `bound(a)` with `[a: Core.Lifetime]`; recorded in SemIR, unenforced | EX-TM-1, EX-TM-5, EX-TM-6 and EX-TM-8 parse (residue item W-129) |
| 3 | Strict static checks without loan sets; `--strict-checks=warn` default | The P1/P2/P3 subset: `StrictDanglingReturn` for a P1 return (EX-TM-2), `StrictBorrowOutlivesPlace` for `Leak` and `Escape` once W-128 lands, `StrictUnverifiedDeref` for P3; `StrictCppCallUnannotated` with the allowlist and the annotation mapping; the warning twins `PermissiveDanglingLoan` and `PermissiveUnannotatedCppCall` (residue item W-131, gated on W-128) |
| 4 | The loan checker | T1 to T8 and the Store rule over loan sets; `bound` per T5(a) to (e); `exclusive`; the reborrow and same-kind-copy clauses; `StrictExclusiveBorrowConflict`, `StrictSharedBorrowInvalidated`, `StrictBorrowOfTemporary`, `StrictStoreOutlivesSource`, `StrictEscapeOfUnboundParam`; `noalias` and `captures(none)` under T8; `error` default (residue item W-132) |
| 5 | Facets, `Core.Thread`, `--strict-concurrency` | `StrictBorrowOutlivesPlace` at a thread-crossing call whose argument's loan set is not free, the thread-boundary lifetime rule of the mutation page (residue item W-133) |
| 6 | `bound(a)` and `Core.Lifetime`, `Core.DynCast`, the Rust binding generator | T5(f): one name, one loan set; `bound(a)` fields replace the `unsafe class` interim for Strict classes with non-owning pointers (EX-TM-6; residue item W-134) |

Stage 2 owns nothing on this page. The prelude churn that stage 3 depends on —
`bound self` on `AsSlice`, `Subslice`, `Get`, `At`, the view conversions,
`Optional.Get` and `Branch`, `bound` on `FromArray`'s pointer, on
`Optional.Some`'s and `Buf.Make`'s value parameters and on the interface
declarations `IndexWith.At` and `Copy.Op`, and `UnsafeMake` becoming
`unsafe fn Make` — is residue item W-128 and is never assumed in an example
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
-   **D-SAFE-8 — `ref` bindings inherit the kind of their source.** A `ref`
    from a place is exclusive; a `ref` from `*p` has `p`'s kind; a mixed loan
    set has the weakest kind and T4 applies to every place in it. `noalias`
    and `captures(none)` are emitted only for exclusive-kind refs under T8,
    which narrows p005434:82 in a dated amendment on this page. Break
    condition: an accepted p005434 example that becomes invalid in Permissive
    mode (none may; the checklist lists them as accepted).
-   **D-SAFE-10 — Loans T1 to T8 plus the Store rule.** As stated under
    [Rules T1 to T8 and the Store rule](#rules-t1-to-t8-and-the-store-rule),
    with the first enforceable subset P1/P2/P3 shipping at stage 3 only
    together with the prelude churn of W-128. Break condition: any
    Strict-accepted counterexample; judge 2's three programs (EX-TM-4) and the
    review set (EX-TM-8) are the standing regression set on this page.
-   **D-SAFE-11 — `bound` semantics fixed; named lifetimes pinned.** As stated
    under
    [`bound`, `bound(a)` and `unsafe class`](#bound-bounda-and-unsafe-class),
    with the narrowing of p005434:826-830 from "immutable" to "not invalidated".
    Break condition: upstream amends p005434's `bound` with different semantics
    — a V-3 review; the fork keeps whichever is lower-divergence and records the
    delta.
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
    D-SAFE-8 are that repair: `exclusive T*` exists, and a `ref` through `*p`
    inherits `p`'s kind so that the proposal's `Valid1` and `ValToRef` stay
    valid.
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
    that is sound only with W-128's `bound` on the view producers, and never
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
    `~x`, [Spatial safety](spatial_safety.md) for views and the W-128
    signature rule, [Mutation safety](mutation_safety.md) for M1 to M8 and the
    facets, and [Safe-Rust interop](rust_interop.md) for the mapping.
-   Fork decision [F-013](/fork/decision-log.md) and the synthesized plan
    [fork/safe/plan.md](/fork/safe/plan.md), whose design-panel record is the
    option paper for this area.
-   The conformance programs fork/conformance/programs/types/union_basic.carbon
    and fork/conformance/programs/interop/cpp_span_view.carbon,
    cpp_export_method.carbon and cpp_thread_carbon_fn_diff.carbon.
