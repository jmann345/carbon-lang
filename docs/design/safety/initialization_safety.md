# Initialization safety

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Rules](#rules)
    -   [I1: Unformed state and its desugaring](#i1-unformed-state-and-its-desugaring)
    -   [I2: Definite formation in Strict](#i2-definite-formation-in-strict)
    -   [I3: Taking the address of unformed storage](#i3-taking-the-address-of-unformed-storage)
    -   [I4: Moves](#i4-moves)
    -   [I5: Zero-fill in Release, poison in Debug](#i5-zero-fill-in-release-poison-in-debug)
    -   [I6: No unformed members, arguments or returns](#i6-no-unformed-members-arguments-or-returns)
-   [Diagnostics](#diagnostics)
-   [Worked examples](#worked-examples)
    -   [EX-I-1: Conditional initialization](#ex-i-1-conditional-initialization)
    -   [EX-I-2: The `Optional` escape](#ex-i-2-the-optional-escape)
    -   [EX-I-3: A type with no unformed state](#ex-i-3-a-type-with-no-unformed-state)
    -   [EX-I-4: A move leaves its source unformed](#ex-i-4-a-move-leaves-its-source-unformed)
    -   [EX-I-5: The out-parameter shape](#ex-i-5-the-out-parameter-shape)
-   [C++ interop consequence](#c-interop-consequence)
-   [Implementation staging](#implementation-staging)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [External facts](#external-facts)
-   [References](#references)

<!-- tocstop -->

## Overview

[Initialization safety] is the property that memory is properly initialized
before being read. Carbon reaches it as a hybrid of compile-time and run-time
enforcement, the one place where its
[memory safety model](README.md#memory-safety-model) deliberately departs from
Rust's: the language keeps the _unformed state_ of proposal p000257 — storage
that exists, may be assigned to or destroyed, and must not otherwise be used —
and adds three things to it. Strict Carbon checks statically that every use of
an object that may be unformed is dominated by its formation; Release builds
zero-fill unformed storage so that a read which escapes the check is erroneous
with a defined value rather than undefined; and moves are defined as leaving
their source unformed, so that the same analysis covers moved-from objects.

[initialization safety]:
    /docs/design/safety/terminology.md#initialization-safety

The page states six rules, I1 to I6, their diagnostics in each
[safety mode](README.md#safety-modes), the worked examples that pin each rule
to the 0.1 toolchain's behavior today, and what the rules mean for C++
interop. The vocabulary is the [safety README](README.md)'s: a _Strict_ body is
checked, a _Permissive_ body is trusted and receives the warning twin of a
Strict error where the [diagnostic matrix](README.md#what-each-mode-diagnoses)
names one, and the _Release_ and _Debug_ [build modes](README.md#build-modes)
change the behavior of a read that is erroneous in both.

This page was fixed by fork decision [F-013](/fork/decision-log.md),
sub-decision D-SAFE-13, synthesized in [fork/safe/plan.md](/fork/safe/plan.md).
No part of this page is implemented in the toolchain (fork workstream SAFE-1,
stage 0); see [Implementation staging](#implementation-staging). The
toolchain today desugars an uninitialized `var` onto `Core.DefaultOrUnformed`
and has no diagnostic for a read of unformed storage. File and line citations
are against trunk 0bdce60a5 unless a citation says otherwise; the examples
marked "today's syntax" were compiled on the 2026.10.12 nightly toolchain and
their outcomes are stated with each example.

## Rules

### I1: Unformed state and its desugaring

The unformed state of the
[design overview](/docs/design/README.md#unformed-state) and proposal p000257
is kept unchanged. An unformed object satisfies three properties: assignment
from a fully formed value is correct using the type's normal assignment;
destruction is correct using the type's normal destructor; and destruction is
optional, so the program behaves the same whether or not the destructor runs.
Any operation on an unformed object other than destruction or assignment from a
formed value is an error. A type opts into having an unformed state by
implementing `Core.UnformedInit`; a type with no unformed state must be
initialized where it is declared.

Today's desugaring is the rule's implementation and is kept. A `var x: T;`
with no initializer is `var x: T = (T as Core.DefaultOrUnformed).Op();`
(toolchain/check/handle_let_and_var.cpp:277-305, `MakeDefaultInit`). The
blanket impls in core/prelude/default.carbon:41-54 select `Default.Op()` for a
`Default` type and the `make_uninitialized` builtin for an `UnformedInit` type,
so a type that is neither cannot be declared without an initializer. The
prelude's `UnformedInit` types are the integers, floats, `bool` and `char`,
every pointer type, arrays of `UnformedInit` elements, `()` and `{}`
(core/prelude/default.carbon:30-36, types/int.carbon:21, types/uint.carbon:22,
types/float.carbon:22, types/char.carbon:20), `Core.MaybeUnformed(T)` for any
`T` (types/maybe_unformed.carbon:17), `Core.Optional(T)` when its storage type
is `UnformedInit` (types/optional.carbon:48), and the fork prelude's non-owning
`Core.Slice(T)` and `Core.String` (types/slice.carbon:62, types/string.carbon
:28). `Core.Buf(T)` is deliberately not
(types/buf.carbon:66-67): its destructor frees a pointer, and under fork
decision D-SL-6 `Destroy` runs unconditionally on `var` storage, so an unformed
`Buf` would free garbage.

Three categories of object can be unformed, and I2 treats them alike: a local
`var` of an `UnformedInit`-only type declared without an initializer, an
object of type `Core.MaybeUnformed(T)` whatever its initializer, and an object
that has been moved from (I4).

### I2: Definite formation in Strict

Strict Carbon runs a flow-sensitive _definite-formation_ analysis over every
object of the three categories above. It is the same dataflow pass as the
[loan checker](temporal_safety.md), run over formation facts instead of loans.
Every read, member access, method call, value binding, `&x`, `ref` binding or
pass-by-value of such an object must be dominated, on every path that reaches
it, by an assignment from a formed value; otherwise the use is
`StrictUseOfUnformed`. Conditional initialization is therefore rejected: a
`var x: i32;` assigned in one arm of an `if` and read after it is an error, and
the analysis does not try to prove the condition. `Core.Optional(T)` is the
sanctioned escape, the design overview's own suggestion for a type that must
exist before it has a value: the dynamic tracking lives in the `Optional`, and
the read is `x.HasValue()` followed by `x.Get()`.

Assignment re-forms. After `x = v;` with `v` formed, `x` is formed on that path
for every subsequent use until it is moved from again. Formation is a property
of the whole object: assigning one field of an unformed struct does not form it
(I6), so the only formation of a class object is assignment or initialization
of the entire object.

In Permissive the analysis runs and emits the warning twin `MaybeUnformedRead`
at each use; the read itself proceeds and yields the unformed representation,
which I5 defines. This is what makes a Permissive file's Strict-readiness
visible before it is flipped.

### I3: Taking the address of unformed storage

`&x` is a use for I2. In Strict it is permitted for a possibly-unformed `x`
only when `x: Core.MaybeUnformed(T)`, the prelude type whose entire purpose is
to be storage that a callee may form (types/maybe_unformed.carbon:13-17);
otherwise `&x` of a possibly-unformed `x` is `StrictAddressOfUnformed`. The
projection out of `MaybeUnformed(T)` is the existing `unsafe as` conversion:
`x unsafe as T` reads the object as a `T`, the form the prelude uses at
types/optional.carbon:201 (`value unsafe as T*`), and `x unsafe as T = v`
assigns through it, the form at types/optional.carbon:194. That `unsafe as` is
an `unsafe` operation in the sense of [type safety](type_safety.md): the
obligation the programmer takes on is that the storage was formed by the time
of the read, and no second spelling exists for it.

In Permissive, `&x` of a possibly-unformed `x` is allowed for any `x`, and the
callee is _assumed_ to form it, which is proposal p000257's own position that
taking the address of an unformed object is fine so long as the restrictions
apply to uses through the pointer (p000257:102-104). A read of storage that
the callee did not form is then erroneous with a defined value under I5. This
is the row of the [diagnostic matrix](README.md#what-each-mode-diagnoses)
whose Permissive cell reads "none": the warning twin `MaybeUnformedRead` fires
on a later read in the same body, never on the `&x`.

### I4: Moves

The design overview's provisional
[move operator](/docs/design/README.md#move) is made concrete. `~x` yields an
initializing expression carrying `x`'s old value and leaves `x` unformed; after
`~x`, I2 forbids every use of `x` until it is reassigned, and assignment
re-forms it. This is proposal p000257's middle ground between Rust, where a
moved-from object is dead, and C++, where it is valid but unspecified: the
object is unformed, which is a state the type already defines.

The default move of a class is a bitwise relocation of the object followed by
marking the source unformed. A type customizes its move by implementing
`Core.Move`, whose signature is `interface Move { fn Op[ref self: Self]() ->
Self; }` and whose contract is "return the old value as an initializing
expression and leave `self` unformed"; the default impl for `Core.Relocatable`
types is the bitwise relocation. For a type with no `UnformedInit` impl the
moved-from mark is what keeps destruction correct: the destructor does not run
on a moved-from object that was not re-formed. The mark is static wherever the
definite-formation pass decides it and a per-object flag where formation at
scope exit is path-dependent, the dynamic tracking proposal p000257 describes
for `Optional` applied to one object.

Only an entire reference expression may be moved from
([values.md](/docs/design/values.md#entire-reference-expressions), "only entire
reference expressions can be destructively moved"); `~*p` and `~x.field` are
`StrictMoveFromNonEntire`, which is a type rule and so an error in both modes,
not a safety relaxation. Moving through a pointer stays the open item values.md
records there.

`Core.Relocatable` is a compiler-determined facet defined structurally: a type
is `Relocatable` when all of its fields are; the three
[pointer kinds](README.md#pointer-kinds-at-a-glance), the integers, the floats,
`bool` and `char` are; an imported C++ type is `Relocatable` exactly when it is
trivially relocatable; and `unsafe impl T as Core.Relocatable {}` opts a pinned
type out or in. "No self-pointers" is not a criterion, because self-reference
is a property of values rather than types: what makes a relocation safe is the
loan rule T4 of [temporal safety](temporal_safety.md), under which a live
shared loan on `x` — a self-loan included — forbids the invalidating `~x`. The
facet also decides which types cross to Rust by value
([Safe-Rust interop](rust_interop.md)).

### I5: Zero-fill in Release, poison in Debug

In every safety mode, the Release build's `make_uninitialized` zero-fills the
whole object, padding included, so that unformed storage holds zeros until it
is assigned. This promotes the design overview's hardened-mode sentence —
"this causes integers to be set to `0` when in unformed state in this mode"
(docs/design/README.md:2148-2149) — to the Release baseline, which proposal
p005914 permits: its memory-safe-language test requires initialization errors
to have no undefined behavior and allows zero-initialization in place of
fail-stop (p005914:87-88). Proposal p000257 already asked that the entire
storage, padding bytes included, be zeroed as hardening initialization
(p000257:355-358); the departure is only that the fork's Release build is the
hardened build for this purpose, recorded as a dated amendment at the
overview's sentence.

The consequence for a read that I2 does not catch — a Permissive body, or
storage reached through a pointer the callee was assumed to form — is that the
read is _erroneous_ and yields a defined value: zeros for storage that was
never assigned, the representation the last assignment or move left otherwise.
Erroneous here has the meaning [values.md](/docs/design/values.md) gives it: a
bug the implementation may detect and report, never unbounded undefined
behavior.

The Debug build poison-fills unformed storage instead and detects reads of it,
the MemorySanitizer-class detection the [build modes](README.md#build-modes)
section promises; a detected read prints one line, "carbon: read of unformed
object; terminating", and fails-stop, the behavior
[terminology](terminology.md#fail-stop) defines.

### I6: No unformed members, arguments or returns

An object is formed or unformed as a whole. Proposal p000257's "no unformed
members" (p000257:630-637) is kept: a class type has no state in which some
fields are formed and others are not, and I2 does not track fields separately.
An `extend base` subobject is an ordinary field for I2, which closes the
question p000257:639-642 left to the inheritance design: forming a derived
object forms its base, and nothing forms a base alone.

An unformed object is never passed by value to a function nor returned from
one (p000257:760-764); under I2 both are uses, so in Strict they are
`StrictUseOfUnformed` and in Permissive `MaybeUnformedRead`. Escaping an
unformed object to another function is done by address, which is I3's rule.

`Core.Optional(T*)` uses `Core.MaybeUnformed(T*)` as its storage with a null
pointer as the "None" representation (types/optional.carbon:186-203). That is
Permissive prelude code behind a safe API: the `unsafe as` projections inside
it are the prelude's obligations, trusted under the
[soundness model](README.md#soundness-model), and a Strict caller sees only
`None`, `Some`, `HasValue` and `Get`.

## Diagnostics

The rows this page owns in the
[diagnostic matrix](README.md#what-each-mode-diagnoses):

| Diagnostic | Strict | Permissive | Debug runtime |
| --- | --- | --- | --- |
| `StrictUseOfUnformed` | error | warning `MaybeUnformedRead`; Release reads zero (I5) | "carbon: read of unformed object; terminating" |
| `StrictAddressOfUnformed` | error | none — I3's Permissive assumption (the callee forms it) | same as above on a later read |
| `StrictMoveFromNonEntire` | error | error (a type rule, [values.md](/docs/design/values.md#entire-reference-expressions), not a safety relaxation) | — |

The diagnostics and what each names:

-   `StrictUseOfUnformed`: "`{0}` may be unformed here; initialize it on every
    path or use `Optional({1})`", where `{0}` is the object and `{1}` its
    type; the diagnostic is placed at the use.
-   `StrictAddressOfUnformed`: placed at the `&x`, naming the object and the
    `MaybeUnformed` type that would make the address legal; its text is fixed
    at stage 3.
-   `StrictMoveFromNonEntire`: placed at the `~` expression, naming the
    non-entire operand; its text is fixed at stage 4.
-   `MaybeUnformedRead`: the Permissive warning twin of `StrictUseOfUnformed`,
    with the same text and the same placeholders.

No diagnostic of this family exists in the toolchain today:
toolchain/diagnostics/kind.def names no diagnostic containing `Unformed`, and
the examples below that read unformed storage compile without comment.

## Worked examples

Each example carries its outcome against the 0.1 toolchain in the vocabulary
of the plan's design-conformance checklist: ACCEPTS, REJECTS,
ACCEPTS-UNCHECKED (compiles today but Strict must reject or the runtime must
check, with the stage that will) or NEW-SYNTAX (no toolchain parses it, with
the stage that will). The examples marked "today's syntax" were compiled on the
2026.10.12 nightly toolchain with `carbon compile --output-last-input-only`
and no `package` line; `Core.Buf` is the fork prelude's and is not in that
toolchain.

### EX-I-1: Conditional initialization

```carbon
// EX-I-1 (today's syntax; accepted today with no diagnostic — Strict rejects)
fn Choose(c: bool) -> i32 {
  var x: i32;              // unformed: i32 is UnformedInit, not Default
  if (c) { x = 1; }
  return x;                // Strict: StrictUseOfUnformed. Permissive, Release: 0.
}
```

Rule I2. Outcome today: ACCEPTS-UNCHECKED — the nightly compiles it with exit
status 0 and no diagnostic, and the toolchain has no `Unformed` diagnostic to
emit. Under the design, Strict rejects the `return x;` with
`StrictUseOfUnformed` because the path on which `c` is false reaches the read
without an assignment; Permissive warns `MaybeUnformedRead` and, in Release,
the read yields 0 by I5; Debug fails-stop with the read-of-unformed message.
The check lands at stage 3 (residue item W-131).

### EX-I-2: The `Optional` escape

```carbon
// EX-I-2 (today's syntax; accepted today)
fn Choose2(c: bool) -> i32 {
  var x: Core.Optional(i32) = Core.Optional(i32).None();
  if (c) { x = Core.Optional(i32).Some(1); }
  if (x.HasValue()) { return x.Get(); }
  return 0;
}
```

Rule I2, the sanctioned escape. Outcome today: ACCEPTS — the nightly compiles
it with exit status 0, and `None`, `Some`, `HasValue` and `Get` are the
placeholder API at types/optional.carbon:31-42. `x` is formed at its
declaration, so I2 has nothing to say on any path; the dynamic tracking is the
`Optional`'s. The example uses the method API rather than a `match`, because
`Core.Optional` is not a choice type today and has no `.None`/`.Some` patterns.
Strict accepts it unchanged at every stage.

### EX-I-3: A type with no unformed state

```carbon
// EX-I-3 (rejected today: `var b: Core.Buf(i32);` has no DefaultOrUnformed impl, W-115)
fn NeedsInit() { var b: Core.Buf(i32); }
```

Rule I1. Outcome today: REJECTS — `Core.Buf(T)` implements neither `Default`
nor `UnformedInit` (types/buf.carbon:66-67), so the desugaring of I1 finds no
`DefaultOrUnformed` impl and the declaration is an error, the limit
fork/gap-analysis.md records as W-115. This is fork prelude behavior and is not
compile-verified against the upstream nightly, which has no `Core.Buf`. The
design keeps the rejection: a type whose destructor cannot be made optional
has no unformed state, and the programmer initializes it or wraps it in
`Core.Optional`.

### EX-I-4: A move leaves its source unformed

```carbon
// EX-I-4 (NEW `~`; Core.Buf is the fork prelude's owning type): moves re-form on assignment
fn Take() {
  var s: Core.Buf(i32) = Core.Buf(i32).Make(1, 0);
  var t: Core.Buf(i32) = ~s;      // s is now unformed (I4); no Destroy runs on it
  s = Core.Buf(i32).Make(2, 0);   // fine: assignment re-forms s; a read before this is StrictUseOfUnformed
}
```

Rule I4 with I2 over the moved-from object. Outcome today: NEW-SYNTAX — the
move operator is provisional in the design overview
(docs/design/README.md:2160-2168) and no toolchain parses `~s` as a move. Under
the design, `~s` relocates the buffer into `t` and marks `s` unformed; a use of
`s` between the two statements is `StrictUseOfUnformed`; the assignment
re-forms `s`; and at scope exit both `s` and `t` are formed and both
destructors run, freeing two distinct blocks. Had the assignment been omitted,
`s` would leave scope unformed and its destructor would not run, which is what
the moved-from mark is for. Lands at stage 4.

### EX-I-5: The out-parameter shape

```carbon
// EX-I-5 (today's syntax for the type) — the out-parameter migration shape
fn Fill(p: Core.MaybeUnformed(i32)*);
fn Out() -> i32 {
  var x: Core.MaybeUnformed(i32);
  Fill(&x);                       // Strict: allowed only because x is MaybeUnformed
  return x unsafe as i32;         // the existing read projection (optional.carbon:200 shape)
}
```

Rule I3. Outcome today: ACCEPTS (the type and the projection exist) — the
nightly compiles it with exit status 0 when `Fill` is given the body
`*p unsafe as i32 = 1;`, `Core.MaybeUnformed` is at
types/maybe_unformed.carbon:13-17, and the `unsafe as` projection is the form
at types/optional.carbon:201. Under the design, `&x` is accepted in Strict
only because `x` is `MaybeUnformed(i32)`; with `var x: i32;` the same line is
`StrictAddressOfUnformed`. The `unsafe as` on the return is where the
obligation "`Fill` formed `x`" is taken on, and it is the only spelling of that
obligation. The Strict rule lands at stage 3.

## C++ interop consequence

C++ has no unformed state, and the design gives it none. An object that C++
constructed is formed from Carbon's point of view, whatever its constructor did:
the formation facts I2 tracks are Carbon's, a `Cpp.` object comes into
existence formed, and whatever a C++ body leaves indeterminate is the C++
body's business, trusted under the soundness model like the rest of C++.

The out-parameter idiom is the migration case. A C++ function that fills
storage through a pointer, `void Fill(int* out)`, is called from Carbon with
Carbon storage. In Strict that storage is `Core.MaybeUnformed(i32)` and the
read after the call is the `unsafe as` projection, exactly EX-I-5 with
`Cpp.Fill` in place of `Fill`; in a Permissive body `var x: i32; Cpp.Fill(&x);`
is accepted as it is, with the callee assumed to form `x` (I3) and a later
`MaybeUnformedRead` warning on the read. I3's requirement is independent of
the call marker: `Cpp.Fill` takes a pointer, so in Strict the call itself is
also `unsafe Cpp.Fill(&x)` until the header carries the annotations the
[C++ call allowlist](README.md#c-call-allowlist) maps, and after that the
`MaybeUnformed` type is still what makes `&x` legal.

Release zero-fill is what C++ sees. A C++ function that reads a Carbon object
through a pointer it saved while the object was unformed, or after the object
was moved from, reads zeros for never-assigned storage and never reads
indeterminate bytes; the read is erroneous on the Carbon side and defined on
both. A migration tool that turns a C++ `T x;` into Carbon therefore writes
`var x: T;` when `T` is `UnformedInit` and must choose an initializer or
`Core.Optional(T)` otherwise, which is the I1 rule applied at migration time
rather than a new one.

## Implementation staging

The rows this page owns in the staging of D-SAFE-21; the
[safety README](README.md#implementation-staging) carries the full table. 0.1
claims no executable behavior from this page: no read of unformed storage is
diagnosed or zero-filled by the 0.1 toolchain.

| Stage | Contents | Owned here |
| --- | --- | --- |
| 0 (this PR) | This page; no toolchain change | All of this page |
| 2 | Runtime hardening regardless of mode | I5: Release `make_uninitialized` zero-fill of the whole object; Debug poison-fill and the read-of-unformed fail-stop |
| 3 | Strict static checks without loan sets; `--strict-checks=warn` default | I2 definite formation over `UnformedInit` locals and `MaybeUnformed(T)`; I3's `StrictAddressOfUnformed`; I6's argument and return uses; the warning twin `MaybeUnformedRead` (residue item W-131) |
| 4 | The loan checker | I4: `~x`, `Core.Move`, `Core.Relocatable`, `StrictMoveFromNonEntire`, and I2 over moved-from objects; the T4 self-loan rule for relocation |

Stages 1, 5 and 6 own nothing on this page; `~` as a move operator is parsed
with the rest of I4 at stage 4.

## Decisions within this design

The decision below is a sub-decision of fork decision F-013, recorded with its
break condition in [fork/decision-log.md](/fork/decision-log.md); the
[safety README](README.md#decisions-within-this-design) and the other category
pages carry the rest of D-SAFE-1 to D-SAFE-23.

-   **D-SAFE-13 — Initialization: definite formation, zero-fill, moves.** I1
    keeps today's desugaring and the unformed contract. I2 Strict runs a
    flow-sensitive definite-formation analysis over every `UnformedInit`-only
    local, every `MaybeUnformed(T)` and every moved-from object; conditional
    initialization is rejected and `Optional(T)` is the escape. I3 `&x` of a
    possibly-unformed `x` is Strict-legal only for `MaybeUnformed(T)`, whose
    projection is the existing `unsafe as`; Permissive assumes the callee
    forms it. I4 `~x` leaves `x` unformed, the default move is bitwise
    relocation plus the unformed mark, `Core.Move` customizes,
    `Core.Relocatable` is structural, and only entire reference expressions
    move. I5 Release zero-fills the whole object in every mode and Debug
    poison-fills and detects. I6 no unformed members, arguments or returns.
    Break condition: a benchmark in the fork showing more than 0.5 percent
    from zero-fill alone — then zero-fill is scoped to escaped-unformed
    objects only, which the same pass knows, and the rule text of I5 is
    amended in a dated edit.

Two rules on this page rest on decisions other pages own. The `unsafe as`
projection out of `MaybeUnformed(T)` is an `unsafe` operation under D-SAFE-5
([type safety](type_safety.md)); the self-loan that makes relocation safe is
the loan rule T4 under D-SAFE-10 ([temporal safety](temporal_safety.md)).

## Alternatives considered

The design was chosen by a panel of three attempts and two judges, recorded in
[fork/safe/plan.md](/fork/safe/plan.md); the judges scored the attempts as
wholes, and the [safety README](README.md#alternatives-considered) carries
their verdicts. All three attempts kept proposal p000257's unformed state and
zero-fill, so the alternatives specific to this page are two pieces the
synthesis did not take, and one the design overview had.

-   **Attempt C's runtime-tracked address escape in Strict.** Attempt C,
    "Ratchet: hardened runtime core now, annotated borrows later", put its 0.1
    weight on the runtime and would have had Strict track at run time the
    formation of an object whose address escapes, rather than restrict the
    escape statically. Judge 1 found that C "is not a candidate base: its 0.1
    scope leaves temporal/mutation 'provisional-with-syntax'", and judge 2
    refuted its stage-1 soundness claim with programs. The synthesis rejects
    this piece on its own terms: run-time formation tracking is the dynamic
    tracking proposal p000257 reserves for `Optional`, and paying it on every
    address-taken local in Strict buys nothing the static I3 rule with
    `MaybeUnformed(T)` does not, because the one idiom that needs it, the
    out-parameter, already has a type for it whose projection exists today.
    Tracking survives only where I4 needs it, for a moved-from object whose
    formation at scope exit is path-dependent.
-   **Attempt A's `Assume()`.** Attempt A, "Strict Carbon by default: owners,
    loans, and operation-tied `unsafe`", offered an explicit `Assume()` by
    which a Strict body asserts that a possibly-unformed object is formed and
    silences the definite-formation check at that point. Neither judge's
    fatal finding on A concerns this item; the synthesis rejects it because
    the obligation it spells already has a spelling: `x unsafe as T` on a
    `MaybeUnformed(T)` is the assertion that the storage was formed (I3,
    EX-I-5), and D-SAFE-5 makes operation-tied `unsafe` the one uniform
    marker. A second word for the same obligation would be a second thing an
    audit must search for, and on an `i32` local it would silence a check
    that `Core.Optional(i32)` answers without any assertion.
-   **Zero-fill in a hardened build only.** The design overview placed
    zero-fill in a hardened build mode and the fork promotes it to the Release
    baseline. Keeping it hardened-only was not taken because the
    memory-safe-language test of proposal p005914 requires initialization
    errors to have no undefined behavior in the default mode, and an
    uninitialized read in Release is exactly such an error; the cost
    question is the break condition of D-SAFE-13, not a reason to leave the
    default mode unsafe.

That decision is final; this page specifies the chosen design rather than
relitigating it.

## External facts

Claims about tools outside this repository appear only here, with a status
(D-SAFE-22). No normative rule on this page depends on an UNVERIFIED item.

| Fact | Used by | Status |
| --- | --- | --- |
| Clang's `-ftrivial-auto-var-init=zero` zero-fills automatic storage in C and C++, and deployments of it report a cost small enough that production builds enable it | The plausibility of I5's 0.5 percent break condition; no rule depends on the figure | UNVERIFIED: we expect the option to exist under that name and the reported cost to be below one percent on typical workloads; the fork's own benchmark is what the break condition reads |

## References

-   Proposal
    [p000257: Initialization of memory and variables](/proposals/p000257-initialization-of-memory-and-variables.md).
-   Proposal
    [p005914: Updating Carbon's safety strategy](/proposals/p005914-updating-carbon-s-safety-strategy.md).
-   Proposal
    [p005434: `ref` parameters, arguments, returns and `val` returns](/proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md).
-   The design overview's
    [unformed state](/docs/design/README.md#unformed-state) and
    [move](/docs/design/README.md#move) sections, and
    [values.md](/docs/design/values.md) on entire reference expressions and
    erroneous behavior.
-   [Safety](README.md): the soundness model, the safety modes, the diagnostic
    matrix and the build modes; the [terminology](terminology.md) page.
-   The sibling category pages: [Type safety](type_safety.md) for `unsafe as`,
    [Temporal safety](temporal_safety.md) for loans and the T4 rule,
    [Mutation safety](mutation_safety.md) for `Core.Plain`, and
    [Safe-Rust interop](rust_interop.md) for by-value crossing under
    `Core.Relocatable`.
-   Fork decision [F-013](/fork/decision-log.md) and the synthesized plan
    [fork/safe/plan.md](/fork/safe/plan.md), whose design-panel record is the
    option paper for this area.
