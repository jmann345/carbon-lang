# Safety

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Safe and unsafe code](#safe-and-unsafe-code)
-   [Soundness model](#soundness-model)
-   [Safety modes](#safety-modes)
    -   [Operation-tied `unsafe`](#operation-tied-unsafe)
    -   [What each mode diagnoses](#what-each-mode-diagnoses)
-   [Memory safety model](#memory-safety-model)
    -   [Safe Carbon design](#safe-carbon-design)
    -   [Pointer kinds at a glance](#pointer-kinds-at-a-glance)
    -   [C++ call allowlist](#c-call-allowlist)
    -   [Data races versus unsynchronized temporal safety](#data-races-versus-unsynchronized-temporal-safety)
-   [Safe library ecosystem](#safe-library-ecosystem)
-   [Build modes](#build-modes)
-   [Constraints](#constraints)
    -   [Probabilistic techniques likely cannot stop attacks](#probabilistic-techniques-likely-cannot-stop-attacks)
-   [C++ migration example](#c-migration-example)
-   [Implementation staging](#implementation-staging)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [External facts](#external-facts)
-   [References](#references)

<!-- tocstop -->

## Overview

One of Carbon's core goals is [practical safety]. This is referring to _[code
safety]_ as opposed to the larger space of [systems safety]. The largest aspect
of code safety at the language level is [memory safety], but this also applies
to other aspects of code safety such as avoiding undefined behavior in other
forms.

[practical safety]:
    /docs/project/goals.md#practical-safety-and-testing-mechanisms
[code safety]:
    /docs/design/safety/terminology.md#code-software-or-program-safety
[systems safety]: /docs/design/safety/terminology.md#safety
[memory safety]: /docs/design/safety/terminology.md#memory-safety

However, Carbon also has a goal of fine grained, smooth interop-with and
migration-from existing C++ code, and C++ is a fundamentally unsafe language. It
has pervasive sources of undefined behavior and minimal memory safety
guarantees. Our safety strategy has to address how C++ code fits into it, and
provide an incremental path from where the code is at today towards increasing
levels of safety.

Ultimately, Carbon will both provide a [memory-safe language], _and_ provide a
language that is a target for mechanical migration from C++ and optimizes even
further for interop with unsafe C++ with minimal friction.

[memory-safe language]: /docs/design/safety/terminology.md#memory-safe-language

## Safe and unsafe code

Carbon will have both _safe_ and _unsafe_ code. Safe code provides limits on the
potential behavior of the program even in the face of bugs in order to prevent
[safety bugs] from becoming [vulnerabilities]. Unsafe code is any code or
operation which lacks limits or guarantees on behavior, and as a consequence may
have undefined behavior or be a safety bug.

[safety bugs]: /docs/design/safety/terminology.md#safety-bugs
[vulnerabilities]:
    /docs/design/safety/terminology.md#vulnerability-or-security-vulnerability

All things being equal, safe code constructs are preferable to unsafe
constructs, but many unsafe constructs are necessary. Where unsafe constructs
are needed, Carbon follows three principles to incorporate them into the
language:

-   The unsafe capabilities provided should be semantically narrow: only the
    minimal unsafe operation to achieve the desired result.
-   The unsafe code should be syntactically narrow and separable from
    surrounding safe code.
-   There should be a reasonable way of including the keyword `unsafe` in
    whatever syntax is used so that this keyword can be used as a common
    annotation in audits and review.

The result is that we don't model large regions or sections of Carbon code as
"unsafe" or have a parallel "unsafe" variant language. We instead focus on the
narrow and specific unsafe operations and constructs.

Note that when we're talking about the narrow semantics of an unsafe capability,
these are the semantics of the specific unsafe operation. For example, an unsafe
type conversion shouldn't also allow unsafe out-of-lifetime access. This is
separate from the _soundness_ implications of an unsafe operation, which may not
be as easily narrowed.

> **Resolved (fork amendment 2026-10-12, F-013 D-SAFE-2).** The soundness model
> is stated below, in [Soundness model](#soundness-model). The original block
> read:
>
> > **Future work**: More fully expand on the soundness principles and model
> > for safe Carbon code. This is an interesting and important area of the
> > design that isn't currently fleshed out in detail.

## Soundness model

This section and the six category pages it indexes were fixed by fork decision
[F-013](/fork/decision-log.md), with sub-decisions D-SAFE-1 to D-SAFE-23
synthesized in [fork/safe/plan.md](/fork/safe/plan.md). No part of the design
is implemented in the toolchain (fork workstream SAFE-1, stage 0); see
[Implementation staging](#implementation-staging). File and line citations on
the safety pages are against trunk 0bdce60a5 unless a citation says otherwise.

**S0.** Signatures are the contract; Strict bodies are checked; Permissive
bodies, `unsafe fn` bodies and C++ are trusted; every obligation the checker
cannot discharge is spelled `unsafe` at the operation. Stated as a guarantee: a
Strict function body cannot cause a [safety bug][safety bugs] provided (a)
every callee meets its declared signature contract — its loans and `bound`
parameters, its `unsafe fn` marking, and the `Send`/`Sync` facets of its types
— and (b) every `unsafe`-marked operation's stated obligation holds at that
operation. Strict bodies are checked against their callees' signatures;
Permissive bodies, `unsafe fn` bodies and C++ are trusted to meet their own
signatures, and review is where (a) is established for them. Every point where
the programmer takes on an obligation the checker cannot discharge is spelled
`unsafe` at the operation, which makes the three principles of
[Safe and unsafe code](#safe-and-unsafe-code) precise: the operation is the
semantic unit, the keyword is the syntactic unit, and the audit is a search for
the keyword.

The prelude is the first client of this model. `Core.Slice`, `Core.Buf` and
`Core.Optional` are Permissive-implemented behind Strict-checkable signatures
(core/prelude/types/slice.carbon:24-77, buf.carbon:26-64,
optional.carbon:186-203): their bodies are trusted, their signatures are what a
Strict caller is checked against, and the audit of those signatures under the
loan rules is the first residue item of the design (W-144; see
[Temporal safety](temporal_safety.md)). A trusted body keeps the write rule of
the mutation page's M3: it writes an object whose type holds a
`Core.SharedImmutable` sub-object only through an exclusive path, an owner, a
`ref` or an `exclusive T*`, or through a pointer into storage owned by an object
it holds exclusively, every other path to that storage the type hands out being
`bound` to that object; so `Core.Buf(T).Set`, which writes an element of the
block, takes `ref self` under W-144, and the `Ref` method of the indexing
interface `IndirectIndexWith`, once the prelude has it, which hands out a `ref`
into the storage a `Core.Slice` views or a `Core.Buf` owns, takes `bound self`
under W-144, at the interface and in both impls, so that a binding formed
through `b[i]` keeps the loan on `b` that `Set`'s `ref self` conflicts with
([Mutation safety](mutation_safety.md), Value bindings; added 2026-10-28,
SAFE-2: W-348).

The design uses six names for memory safety, five categories and one
companion: [type safety], [initialization safety], [spatial safety],
[temporal safety] and [mutation safety], with [data-race safety] as mutation
safety's cross-thread companion, enforced by the same facets but not a sub-case
of it — two threads writing one `Plain` `i32` race without invalidating
anything. Under this model Strict Carbon satisfies the
[memory-safe language] test of the terminology page as written: the default
mode guarantees spatial, temporal, type and initialization safety; the unsafe
subset is delineated by `unsafe` at every operation; and temporal safety holds
across threads once the thread API's lifetime contract is fixed at stage 5
(D-SAFE-16): every thread-crossing API then accepts only loans that outlive
the thread or joins inside the borrow (see
[Mutation safety](mutation_safety.md); amended 2026-10-12, document-review
fold: D-8).

The guarantee is stated for the supported build modes, Release and Debug and
their extensions. The unsupported benchmarking build of
[Build modes](#build-modes) removes the run-time enforcement the guarantee
relies on, the bounds check, the division guard, the overflow wrap and the
hardening initialization of unformed storage, and nothing on the safety pages
holds in it (realigned 2026-10-28, SAFE-2: W-350, W-351).

## Safety modes

The _safety mode_ of Carbon governs the extent to which unsafe code must include
the local `unsafe` keyword in its syntax to delineate it from safe code.

_Strict Carbon_ is the mode in which all unsafe code is marked with the `unsafe`
keyword. This mode is designed to satisfy the requirements of a [memory
safe language].

_Permissive Carbon_ is a mode optimized for interop with C++ and automated
migration from C++. In this mode, some unsafe code does not require an `unsafe`
keyword: specific aspects of C++ interop or pervasive patterns that occur when
migrating from C++. However, not _all_ unsafe code will omit the keyword, the
permissive mode is designed to be minimal in the unsafe code allowed.

Modes can be configured on an individual file as part of the package
declaration, or an a function body as part of the function definition. More
options such as regions of declarations or regions of statements can be explored
in the future based on demand in practice when working with mixed-strictness
code. More fine grained than statements is not expected given that the same core
expressivity is available at that finer granularity through explicitly marking
`unsafe` operations.

> **Resolved (fork amendment 2026-10-12, F-013 D-SAFE-3/D-SAFE-4).** The
> syntax is fixed below. The original block read:
>
> > **Future work**: Define the exact syntax for package declaration and
> > function definition control of strictness. The syntax for enabling the
> > permissive mode must include the `unsafe` keyword as it is standing in
> > place of more granular use of the `unsafe` keywords and needs to still be
> > discovered when auditing for safety.

Strict is the language default and needs no word. A file is Permissive when
its package declaration carries `unsafe permissive`, which extends the
[`package` directive grammar](/docs/design/code_and_name_organization/README.md#package-directives):

```regex
(unsafe permissive)? (impl)? package IDENTIFIER (library STRING)?;
(unsafe permissive)? (impl)? library STRING;
```

A function body is Permissive when its definition carries `unsafe permissive
fn`. `permissive` is a contextual keyword valid only after `unsafe`, so the
requirement above that the permissive spelling include the `unsafe` keyword
holds, and a search for `unsafe` finds every Permissive unit.

The callee contract and the body mode are different things (D-SAFE-4). `unsafe
fn F(...)` declares that _calling_ `F` carries an obligation the checker cannot
discharge; in Strict every call of it is spelled `unsafe F(args)` or `unsafe
x.M(args)`. The body of an `unsafe fn` is still checked in its file's mode:
marking a callee never un-checks its body. `unsafe permissive fn` is the
body-mode marker: a Permissive body that is safe to call, which never colors
its callers. The two compose as `unsafe fn` on the declaration plus `unsafe
permissive` on the definition. The mode spellings and the operation forms
together (NEW syntax is marked; the `unsafe as` line exists today):

```carbon
package Geometry library "Shapes";                 // Strict (default)
unsafe permissive package Audio library "Glue";    // Permissive file (NEW)
unsafe permissive fn Glue(p: Cpp.Widget*) { ... }  // Permissive body, safe to call (NEW)
unsafe fn Make(p: T*, size: i64) -> Self;          // unsafe to call; body in file mode (NEW)
unsafe import Audio library "Glue";                // Strict file importing a Permissive API (NEW)
let q: i32* = p unsafe as i32*;                    // exists today
let v: T = unsafe s.GetUnchecked(i);               // call of an unsafe fn (NEW)
let r: i32 = unsafe *q;                            // unverified dereference (NEW)
let a: i32 = unsafe u.i;                           // union field read (NEW spelling)
```

> **Resolved (fork amendment 2026-10-12, F-013 D-SAFE-6).** Permissive imports
> are marked as stated below. The original block read:
>
> > **Future work**: Define how to mark `import`s of permissive libraries in
> > various contexts, balancing ergonomic burden against the potential for
> > surprising amounts of unsafety in dependencies.

A Strict file that imports a library whose API file is Permissive writes
`unsafe import P library "L";`, a declaration-level `unsafe` modifier, so the
import is the audit line for the dependency. Importing a Strict library needs
no marker. `import Cpp ...` needs no marker either, and that is a named
asymmetry against the one-rule ask of the original block: a by-value C++
function is called unmarked while a by-value function of a Permissive Carbon
library needs `unsafe import`, because the `Cpp.` prefix on every C++ name is
itself the audit marker an `unsafe import` would duplicate, and the
[C++ call allowlist](#c-call-allowlist) marks every pointer-carrying C++ call
at the operation instead. A driver flag alone was rejected as weaker than a
source marker an audit can search for.

**Rollout.** The language rule is Strict by default; the implementation rule is
staged. The 0.1 toolchain has no modes, so every file today behaves as an
unmarked Permissive file. Stage 3 ships the Strict checks under
`--strict-checks=warn` as the default, so a file's Strict-readiness is visible
as warnings before anything is rejected, and stage 4 flips the default to
`error`. The warning twins in
[What each mode diagnoses](#what-each-mode-diagnoses) are what the `warn`
setting emits; a Permissive file keeps them after the flip.

### Operation-tied `unsafe`

`unsafe` is a uniform expression prefix (D-SAFE-5). Its forms are:

-   `p unsafe as T` — pointer reinterpretation, `const` removal and
    integer-to-pointer conversion; the one form that exists today
    (core/prelude/operators/as.carbon:61-65). It is required in both modes.
-   `unsafe F(args)` and `unsafe x.M(args)` — a call of an `unsafe fn`.
-   `unsafe *p` and `unsafe p->m` — a dereference of an unverified pointer, one
    whose loan set the checker does not know (see
    [Temporal safety](temporal_safety.md)).
-   `unsafe u.f` — a union field read; writes need no marker. `unsafe &u.f` is
    the address of a union field, a deferred read whose result is an
    unverified pointer.
-   `unsafe s[i]` — a subscript whose `[]` resolves to an `unsafe fn`.
-   `unsafe (c = 42)`, `unsafe (a + b)`, `unsafe (a += b)` — an infix or
    assignment operator that resolves to an `unsafe fn`, such as an imported
    C++ member `operator=`.
-   `unsafe F(args)`, `unsafe x.M(args)` and `unsafe s[i]` on a call, method
    or subscript that does not resolve to an `unsafe fn` but consumes an
    unverified carrier — a ⊥ pointer passed to a `bound` parameter, a ⊥ view
    subscripted — where the obligation is the one rule T6 of
    [Temporal safety](temporal_safety.md) states, that the storage outlives
    every use derived from the result (amended 2026-10-12, document-review
    fold: D-1).
-   `unsafe p->Push(3)` and `unsafe (*p = v)` — an invalidating operation of
    rule M3 of [Mutation safety](mutation_safety.md) performed through a
    shared path, whose obligation is that no live access path reaches the
    storage the operation invalidates (amended 2026-10-12, document-review
    fold: D-9).
-   `let ref r: T = unsafe *p;`, `unsafe F(ref *p)`, `let v: T = unsafe *p;`,
    `unsafe p->M(args)` and `unsafe F(p)` — a `ref` binding, a value binding
    of a borrowed object, or a call whose `bound` pointer argument reaches an
    open place, formed where the checker cannot see every other carrier
    ([Temporal safety](temporal_safety.md), `ref` bindings, T2 and T5(d);
    [Mutation safety](mutation_safety.md), M8). For a `ref` the obligation is
    the one proposal p005434 gives unsafe code, to "adhere to just the
    `noalias` restrictions": no other path accesses the referent, or writes it
    for a `const` `ref`, while the binding lives; for a value binding, no path
    mutates the borrowed object while the binding lives; for a `bound` pointer
    argument, no path but the result writes the pointee while the result lives
    (realigned 2026-10-28, SAFE-2: W-347, W-348, W-349).
-   `unsafe fn F(...) = "name"` — a builtin binding declared outside the
    prelude, a declaration-level form like `unsafe import`: the declaration
    asserts the builtin's contract and every call of it is an `unsafe fn`
    call; an unmarked binding is `StrictBuiltinBindingUnmarked` (amended
    2026-10-12, document-review fold: MAJOR-1; rule SP1 of
    [Spatial safety](spatial_safety.md)).

The prefix applies to the innermost call, dereference, subscript or field read
that follows the keyword: in `unsafe x.M(args).N()` it marks `x.M(args)` only,
and `unsafe (x.M(args).N())` widens it by parenthesizing. `unsafe (` begins a
prefix expression whose operand is the parenthesized expression's outermost
operator application, which is what gives the operator forms their spelling.
`unsafe` followed by `as` remains the infix modifier by the existing one-token
lookahead. This uniform prefix supersedes the member-position strawman
`s_value.unsafe RefMemberFunction()` in [values](/docs/design/values.md),
which carries a dated amendment saying so. The set of unsafe operations is the
same in both modes; what Permissive changes is only which of them need the
keyword, as the next table states.

### What each mode diagnoses

This table is the one place that says, per diagnostic, what each mode does.
The category pages copy their rows from it. Permissive is Strict with three
facts _assumed_ rather than proved — that unannotated C++ pointer parameters
do not escape, that C++ non-`const` methods may be called through shared
pointers, and that union reads, `unsafe fn` calls and `unsafe *` need no
marker, the rows marked "assumed fact" — plus the downgrades to a warning
twin; the fail-stop rows are identical in every mode.

| Diagnostic (owning page) | Strict | Permissive | Debug runtime |
| --- | --- | --- | --- |
| `StrictUnsafeCallUnmarked` ([type safety](type_safety.md)) | error | none — assumed fact | — |
| `StrictUnionReadUnmarked` ([type safety](type_safety.md)) | error | none — assumed fact | — |
| `StrictBuiltinBindingUnmarked` ([type safety](type_safety.md); rule SP1 of [spatial safety](spatial_safety.md)) | error | warning `PermissiveBuiltinBinding` | — |
| `StrictUnverifiedDeref` ([type safety](type_safety.md), [temporal safety](temporal_safety.md)) | error | none — assumed fact | ASan-class detection ([Build modes](#build-modes)) |
| missing `unsafe` before `as` (existing `ConversionFailure`-class error) | error | error | — |
| `StrictUseOfUnformed` ([initialization safety](initialization_safety.md)) | error | warning `MaybeUnformedRead`; Release reads zero (I5) | "carbon: read of unformed object; terminating" |
| `StrictAddressOfUnformed` ([initialization safety](initialization_safety.md)) | error | none — I3's Permissive assumption (the callee forms it) | same as above on a later read |
| `StrictMoveFromNonEntire` ([initialization safety](initialization_safety.md)) | error | error (a type rule, [values.md:117-118](/docs/design/values.md), not a safety relaxation) | — |
| `StrictExclusiveBorrowConflict` ([temporal safety](temporal_safety.md)) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictSharedBorrowInvalidated` ([temporal safety](temporal_safety.md)) | error | warning `PermissiveAliasedExclusive` | ASan-class detection when the invalidation frees what a loan reads; the value-binding report is `StrictBorrowedObjectMutated`'s (realigned 2026-10-28, SAFE-2: W-348; this cell read "`MutationDuringValueBinding` for the value-binding case (D-SAFE-17)") |
| `StrictRefFromShared` ([temporal safety](temporal_safety.md); realigned 2026-10-28, SAFE-2: W-347) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictBorrowFromShared` ([mutation safety](mutation_safety.md); realigned 2026-10-28, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | — |
| `StrictBorrowedObjectMutated` ([mutation safety](mutation_safety.md); realigned 2026-10-28, SAFE-2: W-348, W-349) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` |
| `StrictSharedImmutableWrite` ([mutation safety](mutation_safety.md); realigned 2026-10-28, SAFE-2: W-348) | error | warning `PermissiveAliasedExclusive` | `MutationDuringValueBinding` when a binding of the object is live |
| `StrictBorrowOutlivesPlace`, `StrictBorrowOfTemporary`, `StrictDanglingReturn`, `StrictStoreOutlivesSource`, `StrictEscapeOfUnboundParam` ([temporal safety](temporal_safety.md)) | error | warning `PermissiveDanglingLoan` | ASan-class detection |
| `StrictCppCallUnannotated` ([temporal safety](temporal_safety.md)) | error | warning `PermissiveUnannotatedCppCall` — assumed fact | — |
| `StrictInvalidatingThroughShared` ([mutation safety](mutation_safety.md)) | error | warning `PermissiveAliasedExclusive`; none for a C++ non-`const` method through `T*` — assumed fact | — |
| `StrictNotSend`, `StrictNotSync` ([mutation safety](mutation_safety.md), stage 5) | error | warning (`--strict-concurrency=warn`) | — |
| bounds and division-by-zero ([spatial safety](spatial_safety.md)) | fail-stop | fail-stop (identical) | fail-stop (identical) |

The first assumed fact is the Permissive reading of the strategy's
no-assumptions rule for C++ (proposal p005914), named as a departure: that
unannotated C++ pointer parameters do not escape is a diagnostic assumption
only, never a codegen one, because the loan checker withholds `noalias` and
`captures(none)` at every such boundary ([Temporal safety](temporal_safety.md),
T8). `unsafe as` keeps its keyword in both modes because it is enforced today
in unmarked files and Permissive's omissions are limited to C++-interop and
migration patterns.

## Memory safety model

Carbon will use a hybrid of different techniques to achieve memory safety in its
safe code, largely broken down by the categories of memory safety:

-   [Type safety]: compile-time enforcement, the same as other statically typed
    languages with generic type systems.
-   [Initialization safety]: hybrid of run-time and compile-time enforcement.
-   [Spatial safety]: run-time enforcement.
-   [Temporal safety]: compile-time enforcement through its type system.
-   [Mutation safety]: compile-time enforcement through pointer kinds and
    binding conventions; data-race safety is its cross-thread companion,
    enforced by the same facets.
-   [Data-race safety]: compile-time enforcement through its type system.

[type safety]: /docs/design/safety/terminology.md#type-safety
[initialization safety]:
    /docs/design/safety/terminology.md#initialization-safety
[spatial safety]: /docs/design/safety/terminology.md#spatial-safety
[temporal safety]: /docs/design/safety/terminology.md#temporal-safety
[mutation safety]: /docs/design/safety/terminology.md#mutation-safety
[data-race safety]: /docs/design/safety/terminology.md#data-race-safety

**At this high level, this means Carbon's memory safety model will largely match
Rust's.** The only minor deviation at this level from Rust is the use of
run-time enforcement for initialization, where Carbon will more heavily leverage
run-time techniques such as automatic initialization and dynamic "optional"
semantics to improve the ergonomics in Carbon.

However, Carbon and Rust will have substantial differences in the _details_ of
how they approach both temporal and data-race safety.

### Safe Carbon design

The concrete design is on six pages, each owning its rules, diagnostics,
worked examples, C++ interop consequence and staging rows:

-   [Type safety](type_safety.md): values are accessed only at their declared
    type, every type-unsafe operation is an `unsafe` operation in Strict, and
    `unsafe fn` is the callee contract.
-   [Initialization safety](initialization_safety.md): definite formation
    checked in Strict over unformed storage, zero-fill in Release, and moves
    that leave their source unformed.
-   [Spatial safety](spatial_safety.md): every element access is bounds-checked
    and fails-stop in every supported build mode, `unsafe fn GetUnchecked` is
    the supported opt-out beside the unsupported benchmarking build, and views
    carry their length and a loan (realigned 2026-10-28, SAFE-2: W-351; the
    superseded 2026-10-12 text read "fails-stop in every build mode,
    `unsafe fn GetUnchecked` is the only opt-out").
-   [Temporal safety](temporal_safety.md): three pointer kinds, loans on
    places, `bound` on signatures, the Store rule, and the first enforceable
    subset that ships before loan sets.
-   [Mutation safety](mutation_safety.md): exclusive-XOR-shared access per
    place, the no-invalidation rule with `Core.Plain`, value bindings, and
    data-race safety through the `Send`/`Sync`/`Freeze` facets.
-   [Safe-Rust interop](rust_interop.md): the mapping from this design to safe
    Rust, by stage, and the four-part verdict on what safe Rust can rely on.

### Pointer kinds at a glance

The kinds are defined on the [temporal safety](temporal_safety.md) page and
used by every other page.

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
rule when they are called through a shared pointer
([Temporal safety](temporal_safety.md), T2); and the `T*` row's `Plain` writes
exclude every assignment whose type holds a `Core.SharedImmutable` sub-object,
a `Core.String`, a `Core.Slice(T)` for a `Core.Freeze` `T`, or a struct,
tuple, array or class holding one, which only an exclusive path makes
([Mutation safety](mutation_safety.md), M3; realigned 2026-10-28, SAFE-2: W-347,
W-348).

### C++ call allowlist

C++ is Permissive Carbon: C++ code is trusted to meet its declared contracts
(S0). In Strict, a C++ function whose signature involves any pointer,
reference, view or `this` is unsafe to call — `unsafe Cpp.F(...)`, else
`StrictCppCallUnannotated` — unless its declaration carries annotations the
importer maps (`_Nonnull`, `[[clang::lifetimebound]]` as `bound`, a
noescape-style attribute as non-`bound`, thread-safety annotations as facets;
see [Temporal safety](temporal_safety.md) and
[Mutation safety](mutation_safety.md)), or unless the call has one of the four
signature shapes below, which the importer trusts without annotation. The
allowlist is a trusted assumption of the design (D-SAFE-18): it grows only by a
dated edit of this table that names a new shape, never by dropping the rule.

| Shape | Why it needs no marker | Corpus program that exercises it |
| --- | --- | --- |
| 1. By-value parameters and by-value returns | No pointer, reference, view or `this` crosses the call, so nothing can be saved or aliased by the callee | fork/conformance/programs/interop/cpp_export_method.carbon:59-61 (`Cpp.StaticThroughCpp()`, `Cpp.DriveCounterInCpp()`, both returning `int` by value) |
| 2. `const T&` parameters of `Freeze` types, from stage 5 (at stage 3, before `Freeze` exists, the shape keeps the marker; amended 2026-10-12, document-review fold: MINOR-9) | The callee gets read-only access to an object with no interior mutability, so no write is possible through it during the call; that the reference is not saved is the trusted assumption | None directly today: the `begin(const Halves& r)` in cpp_iterate_generic_adl_range.carbon:42-43 is reached only through the prelude's trusted range witnesses |
| 3. The members of `std::atomic<T>` and `std::thread` that fork decision F-008 models: `fetch_add`, `load`, `store`, the constructor taking a Carbon function value, `join` | Their contract is fixed by the 0.1 threading decision ([fork/design-sprint/threading-atomics.md](/fork/design-sprint/threading-atomics.md)); the function value crossing is the export case under which the loan checker emits no `noalias` | cpp_thread_carbon_fn_diff.carbon:38-52 (`Cpp.hits.fetch_add(...)`, `Cpp.std.thread.thread(Work)`, `Cpp.hits.load()`) |
| 4. `std::span<T>` and `std::span<const T>` parameters when the Carbon argument is a loan-carrying `Core.Slice` whose extent the Carbon side proves | The view's bounds are established by Carbon before the call and the callee receives exactly that extent | cpp_span_view.carbon:62-69 (`Cpp.SumSpan(Core.Slice(i32).FromArray(&a))` and the `std::vector` argument) |

Everything else keeps `StrictCppCallUnannotated` in Strict and its warning twin
`PermissiveUnannotatedCppCall` in Permissive. Pointers returned by C++, and
pointer-typed fields read from an imported C++ type, are unverified (the second
clause amended 2026-10-12, document-review fold: D-7). Non-`const` C++ methods
import as `ref self` (exclusive, callable through `exclusive T*`; through a
shared `T*` only as `unsafe` or by way of `Core.Guarded`), `const` methods as
const access; a future non-invalidation annotation on a C++ method maps to `addr
self`. The prelude's synthesized range witnesses (`CppRangeForIterate`,
`CppContiguousRange`) are trusted prelude code, Permissive-implemented behind a
Strict signature like the rest of the prelude. Measured on the fork's interop
corpus with this allowlist in force, one C++ call site of fourteen across six
programs needs a marker — the `c = 42` of
cpp_operator_import_assignment.carbon:33, spelled `unsafe (c = 42)`, a site that
does not compile today because the program is SKIP until the assignment-operator
import lands (its line 6); the document reviews of the design re-measure this
row.

### Data races versus unsynchronized temporal safety

Carbon has the option of distinguishing between two similar but importantly
different classes of bugs: data races and unsynchronized temporal safety
violations. Specifically, there is no evidence from security teams that there is
any significant volume of vulnerabilities that involve a data race bug but don't
also involve a temporal memory safety violation. For example, despite both Go
and non-strict-concurrency Swift only providing temporal safety, the rate of
memory safety vulnerabilities in software written in both matches the expected
low rate for memory-safe languages. As a consequence, Carbon has some
flexibility while still being a [memory-safe language] according to our
definition:

-   Carbon might choose to _not_ prevent data race bugs that are not
    _themselves_ also temporal safety bugs, even though the data race may lead
    to corruption and cause the program to later violate various other forms of
    memory safety. So far, evidence has not shown this to be as significant and
    prevalent source of _vulnerabilities_ as other forms of memory safety bugs.
-   However, Carbon _must_ detect and prevent cases where a lack of
    synchronization directly allows temporal safety bugs, such as use after
    free.

Despite having this flexibility, preventing data race bugs remains _highly
valuable_ for correctness, debugging, and achieving [fearless concurrency]. If
Carbon can, it should work to prevent data races as well.

[fearless concurrency]: https://doc.rust-lang.org/book/ch16-00-concurrency.html

The fork design (2026-10-12, F-013) prevents all data races between
Carbon-spawned threads (D-SAFE-16), which this section permits; see
[Mutation safety](mutation_safety.md).

## Safe library ecosystem

Carbon will need access to memory-safe library ecosystems, both for
general-purpose, multi-platform functionality and for platform-specific
functionality. Currently, the industry is currently investing a massive amount
of effort to build out a sufficient ecosystem of general, multi-platform
software using Rust, and it is critical that Carbon does not impede, slow down,
or require duplicating that ecosystem. Similarly, if any other cross-platform
library ecosystems emerge in any viable memory-safe languages given our
performance constraints, we should work to reuse them and avoid duplication.

**Carbon's strategy for safe and generally reusable cross-platform libraries is
to leverage Rust libraries through interop.** This is a major motivating reason
for seamless and safe Rust interop. The Carbon project will work to avoid
creating duplication between the growing Rust library ecosystem and any future
Carbon library ecosystem. Carbon's ecosystem will be focused instead on
libraries and functionality that would either be missing or only available in
C++.

Platform-specific functionality is typically developed in that platform's native
language, whether that is Swift for Apple platforms or Kotlin for Android.
Again, the goal of Carbon should be to avoid duplicating functionality, and
instead to prioritize high quality interop with the existing platform libraries
in the relevant languages on those platforms.

## Build modes

Where Carbon's safety mode governs the language rules applied to unsafe code,
Carbon's build modes will change the _behavior_ of unsafe code.

There are two primary build modes:

-   **Release**: the primary build mode for programs in production, focuses on
    giving the best possible performance with a practical baseline of safety.
-   **Debug**: the primary build mode during development, focuses on
    high-quality developer experience.

The release build will include a baseline of hardening necessary to uphold the
run-time enforcement components of our
[memory safety model](#memory-safety-model) above. This means, for example, that
bounds checking is enabled in the release build. There is [evidence] that the
cost of these hardening steps is low. Following the specific guidance of our top
priority for [performance control], Carbon will provide ways to write unsafe
code that disables the run-time enforcement, enabling the control of any
overhead incurred.

> **Fork note (2026-10-12, F-013).** The 0.1 toolchain has a single mode in
> which the release baseline's bounds checks are unconditional (fork decision
> D-SL-4); see [Spatial safety](spatial_safety.md).

[evidence]: https://chandlerc.blog/posts/2024/11/story-time-bounds-checking/
[performance control]: /docs/project/goals.md#performance-critical-software

The debug build will change the actual behavior of both safe and unsafe code
with detectable bugs or detectable undefined or erroneous behavior to have
[fail-stop] behavior and provide detailed diagnostics to enable better
debugging. This mode will at least provide similar bug [detection] capabilities
to [AddressSanitizer] and [MemorySanitizer].

[fail-stop]: /docs/design/safety/terminology.md#fail-stop
[detection]: /docs/design/safety/terminology.md#detecting
[AddressSanitizer]: https://clang.llvm.org/docs/AddressSanitizer.html
[MemorySanitizer]: https://clang.llvm.org/docs/MemorySanitizer.html

Carbon will also have additional build modes to provide specific, narrow
capabilities that cannot be reasonably combined into either of the above build
modes. Each of these is expected to be an extension of either the debug or
release build for that specific purpose. For example:

-   Debug + [ThreadSanitizer]: detection of [data-races][data-race safety].
-   Release + specialized [hardening]: some users can afford significant
    run-time overhead in order to use additional hardening. Carbon will have
    several specialized build modes in this space. Hardening techniques in this
    space include [Control-Flow Integrity (CFI)][cfi] and hardware-accelerated
    address sanitizing ([HWASAN]).

[ThreadSanitizer]: https://clang.llvm.org/docs/ThreadSanitizer.html
[hardening]: /docs/design/safety/terminology.md#hardening
[cfi]: https://clang.llvm.org/docs/ControlFlowIntegrity.html
[hwasan]:
    https://clang.llvm.org/docs/HardwareAssistedAddressSanitizerDesign.html

Carbon will provide a way to disable the default hardening in release builds,
but not in a supported way. Its use is expected to be strictly for benchmarking
purposes.

> **Kept (fork note 2026-10-28, SAFE-2: W-351, replacing the withdrawal of
> 2026-10-12, F-013 D-SAFE-14).** The fork provides the way the paragraph
> above promises: the _benchmarking build_, the Release build with its default
> hardening disabled,
> that is with no bounds check, no division-by-zero guard, no overflow wrap,
> which leaves the arithmetic design's performance-build row in force, and no
> hardening initialization of unformed storage. It is not a supported build
> mode: no guarantee of the safety pages holds in it, no program is shipped
> from it, and its spelling is fixed with the build modes at stage 2 (residue
> item W-146). The per-site `unsafe fn GetUnchecked` on `Core.Slice` and
> `Core.Buf` is the supported opt-out ([Spatial safety](spatial_safety.md),
> SP4). (The superseded 2026-10-12 note read: "The fork provides no build flag
> that disables the default hardening, for benchmarking or otherwise. The
> per-site `unsafe fn GetUnchecked` on `Core.Slice` and `Core.Buf` is the only
> disable, which keeps the strategy's "manually disabled for
> performance-critical use cases" (proposal p000196) at the site rather than
> the build; see [Spatial safety](spatial_safety.md). The paragraph above is
> kept as history.")

## Constraints

### Probabilistic techniques likely cannot stop attacks

It's expected that non-cryptographic probabilistic techniques that can be
applied at the language level are attackable through a variety of techniques:

-   The attacker might be able to attack repeatedly until it gets through.
-   The attacker may be able to determine when the attack would be detected and
    only run the attack when it would not be.
-   The attacker might be able control the test condition to make detection much
    less likely or avoid detection completely. For example, if detection is
    based on the last 4 bits of a memory address, an attacker may be able to
    generate memory allocations, viewing the address and only attacking when
    there's a collision.

Hardware vulnerabilities may make these attacks easier than they might otherwise
appear. Future hardware vulnerabilities are difficult to predict. In general, we
do not expect non-cryptographic probabilistic techniques to be an effective
approach to achieving safety.

While _cryptographic_ probabilistic techniques can, and typically do, work
carefully to not be subject to these weaknesses, they face a very different
challenge. The overhead of a cryptographically secure hash is generally
prohibitive for use in language level constructs. Further, some of the defenses
against hardware vulnerabilities and improvements further exacerbate these
overheads. However, when these can be applied usefully such as with [PKeys],
they are robust.

[PKeys]: https://docs.kernel.org/core-api/protection-keys.html

## C++ migration example

A C++ API migrates to Strict Carbon by a ladder of four rungs. All four rungs
are NEW syntax (D-SAFE-3, 5, 6 and 18); the C++ header is today's C++. The
`_Nonnull` qualifier is honored by the importer today
(toolchain/check/cpp/import.cpp:1462-1509); the name of the noescape attribute
is an [external fact](#external-facts).

```cpp
// normalize.h — the C++ API being migrated (EX-MIG-0)
struct Vec3 { float x, y, z; };
// Scales `*v` to unit length in place; stores the old length in `*len`.
void Normalize(Vec3* v, float* len);
// The annotated twin a later rung switches to: neither pointer escapes.
void NormalizeChecked(Vec3* _Nonnull v, float* _Nonnull len);  // plus the noescape attribute (D-SAFE-22) on both
```

```carbon
// EX-MIG-1 (rung 1): a Permissive glue file wraps the unannotated call behind a Carbon signature.
unsafe permissive package Geometry library "Glue";
import Cpp library "normalize.h";
fn NormalizeGlue(v: Cpp.Vec3*) -> f32 {
  var len: f32 = 0.0;
  Cpp.Normalize(v, &len);      // Permissive: no marker; stage 3 warns PermissiveUnannotatedCppCall (§1.1 matrix)
  return len;
}

// EX-MIG-2 (rung 2): a Strict file calls the glue; the import is the audit line.
package Geometry library "Shapes";
unsafe import Geometry library "Glue";        // D-SAFE-6: the API file is Permissive
fn Unit(v: exclusive Cpp.Vec3*) -> f32 {
  return NormalizeGlue(v);                    // accepted: a Carbon signature; `v` downgrades to shared `T*` (T2)
}

// EX-MIG-3 (rung 3): the same Strict file calls C++ directly, before annotation.
fn UnitDirect(v: exclusive Cpp.Vec3*) -> f32 {
  var len: f32 = 0.0;
  Cpp.Normalize(v, &len);                     // StrictCppCallUnannotated: pointer parameters, no annotation
  unsafe Cpp.Normalize(v, &len);              // accepted: the obligation (neither pointer is saved) is the caller's
  return len;
}

// EX-MIG-4 (rung 4): after the header gains annotations, the call is safe with no marker.
fn UnitChecked(v: exclusive Cpp.Vec3*) -> f32 {
  var len: f32 = 0.0;
  Cpp.NormalizeChecked(v, &len);              // accepted: `_Nonnull` + noescape import as non-`bound` parameters (D-SAFE-18);
  return len;                                 //   `&len` is a P1 loan on a local passed to a non-`bound` parameter — fine
}
```

Expected diagnostics per rung: rung 1 none in 0.1,
`PermissiveUnannotatedCppCall` (warning) from stage 3; rung 2 none (an
`unsafe import` is a marker, not a diagnostic); rung 3
`StrictCppCallUnannotated` on the unmarked line from stage 3, none on the
marked line; rung 4 none. The ladder a migrating codebase walks is 1 → 2 → 4,
with 3 as the audited shortcut when the header cannot be annotated. At the file
level the same ladder reads: file → `unsafe permissive package`; function →
delete its `unsafe permissive` after fixing its warnings; file → delete the
package modifier. The "§1.1 matrix" the rung-1 comment names is
[What each mode diagnoses](#what-each-mode-diagnoses).

## Implementation staging

The design lands in six stages after this one, fixed by D-SAFE-21. Stage 0 is
the pages; 0.1 claims no executable behavior from them: no Strict program is
accepted or rejected by the 0.1 toolchain. The rows this page owns are the mode
spellings, the diagnostic matrix's `warn` and `error` defaults, the C++ call
allowlist and the migration ladder; each category page carries its own rows.

| Stage | Contents | Owned here |
| --- | --- | --- |
| 0 (this PR) | This page and the six category pages; no toolchain change | All of this page |
| 1 | Lex and parse `exclusive`, `permissive` (contextual), `bound`, `addr`, the mode spellings, `unsafe fn`, `unsafe impl`, `unsafe class`, `unsafe import`, the `unsafe` prefix forms — recorded in SemIR, unenforced | The mode example; rungs 1 to 4 parse |
| 2 | Runtime hardening regardless of mode: array index fail-stop, division by zero fail-stop, `--build-mode=debug\|release`, Release zero-fill; the unsupported benchmarking build that disables them (realigned 2026-10-28, SAFE-2: W-350, W-351) | — |
| 3 | Strict static checks without loan sets: unsafe-operation marking, definite formation, the C++-call rule with the allowlist, the first enforceable temporal subset, the warning twins; `--strict-checks=warn` default | The matrix's warning column; rung 1's warning, rung 3's error |
| 4 | The loan checker: loans, `bound`, no-invalidation, `exclusive`; frozen loans, the closed-place rule, the `bound` pointer argument's pointee and `Core.SharedImmutable` (realigned 2026-10-28, SAFE-2: W-347, W-348, W-349); `error` default; `noalias` under T8 | The matrix's error column |
| 5 | Facets, `Core.Thread`, `--strict-concurrency` | The `StrictNotSend`/`StrictNotSync` row |
| 6 | `bound(a)` and `Core.Lifetime`, `Core.DynCast`, the Rust binding generator | — |

## Decisions within this design

Each decision below is a sub-decision of fork decision F-013, recorded with
its break condition in [fork/decision-log.md](/fork/decision-log.md); the
category pages carry the rest of D-SAFE-1 to D-SAFE-23, except D-SAFE-23
itself, the review and merge gate for the PR that lands these pages, which is
a process decision recorded only in the log.

-   **D-SAFE-1 — Taxonomy.** Mutation safety is an access property: a mutation
    of an object never invalidates a live access path to that object or its
    sub-objects. Data-race safety is its cross-thread companion, enforced by
    the same facets, not a sub-case. Break condition: upstream adds a
    conflicting definition of "mutation safety" to the terminology page — the
    fork entry is renamed, the rules are not reopened.
-   **D-SAFE-2 — Soundness model S0.** As stated in
    [Soundness model](#soundness-model). Break condition: a program that Strict
    accepts with no `unsafe` spelled and that exhibits a safety bug — a model
    bug; the page is amended and the counterexample joins the regression set.
-   **D-SAFE-3 — Strict is the language default; Permissive is spelled with
    `unsafe`.** Break condition: owner veto of Strict-by-default, or a stage-1
    parse ambiguity between `unsafe permissive` and the `unsafe` expression
    prefix (none exists on paper: the prefix form never precedes
    `permissive`, `package`, `impl`, `library` or `fn`).
-   **D-SAFE-4 — Callee contract and body mode are different things.** Break
    condition: a parser that cannot carry `unsafe fn` on the declaration
    together with `unsafe permissive` on the definition — the body marker
    moves to a post-signature position without changing semantics.
-   **D-SAFE-5 — Operation-tied `unsafe` is a uniform expression prefix.**
    Break condition: stage 1 finds the prefix ambiguous against `unsafe as` —
    the spelling moves, the set of marked operations does not.
-   **D-SAFE-6 — Permissive imports are marked.** Break condition: a migration
    corpus where the marker is on more than half of all imports of a Strict
    file — the marker becomes per-package and a driver flag is added for
    discoverability.
-   **D-SAFE-18 — C++ is Permissive Carbon, with the allowlist.** Break
    condition: the planned C++-migration examples still show the
    unannotated-call rule on more than half of call sites in Strict with the
    allowlist in force — the allowlist grows by named shapes, each a dated
    edit of the table above, never by dropping the rule.
-   **D-SAFE-21 — Staging and what 0.1 claims.** As stated in
    [Implementation staging](#implementation-staging). Break condition: the
    owner reads the milestone row as design-only — a one-cell edit of the gap
    analysis, no page changes.

## Alternatives considered

The design was chosen by a panel of three attempts and two judges, recorded in
[fork/safe/plan.md](/fork/safe/plan.md). Attempt A, "Strict Carbon by default:
owners, loans, and operation-tied `unsafe`", made `T*` the exclusive pointer
and re-meant `const T*` as shared-immutable; judge 1 found both fatal because
the C++ `T&` to `T*` mapping and the prelude's own `ptr: T*` fields are shared
views of one block, so an exclusive `T*` turns every one into an unverified
`noalias` claim. Attempt B, "Places, projections and shared cells", kept `T*`
shared-mutable with invalidation defined structurally but had no exclusive
pointer type; judge 2 found that fatal because it makes `ref self` unreachable
through a pointer in Strict, and repairing it means adding the exclusive kind.
Attempt C, "Ratchet: hardened runtime core now, annotated borrows later", made
Permissive the 0.1 default with `package Main strict;`, gave `unsafe fn`
bodies Permissive semantics, and claimed temporal soundness for a stage with
no loan sets; both judges found the soundness claim refuted by programs that
return a view of a local. The synthesis is B as the base with A's explicit
exclusive kind, loan vocabulary and warning twins, and C's `unsafe import`,
first enforceable subset and rollout posture; the mode spelling rejects C's
`strict` word because Strict needs no word, and rejects a driver flag alone as
weaker than a source marker. That decision is final; this page and the six
category pages specify the chosen design rather than relitigating it.

## External facts

Claims about tools outside this repository appear only here, with a status
(D-SAFE-22). No normative rule on this page depends on an UNVERIFIED item.

| Fact | Used by | Status |
| --- | --- | --- |
| Clang's `_Nonnull` type qualifier is honored by the importer, which maps a `_Nonnull` pointer to Carbon's non-null `T*` | The migration example, rung 4 | VERIFIED: toolchain/check/cpp/import.cpp:1462-1509 (`IsClangTypeNonNull`), trunk 0bdce60a5 |
| Clang has a noescape-style parameter attribute whose presence lets the importer treat a pointer parameter as non-`bound` | The migration example, rung 4; the allowlist's annotation mapping | UNVERIFIED: we expect the attribute to be Clang's `noescape`; its exact name and the importer's mapping are a stage-3 item |
| Clang's `[[clang::lifetimebound]]` attribute marks a parameter whose referent the result may refer to, which the importer maps to `bound` | The allowlist's annotation mapping | UNVERIFIED as an external fact; the equivalence itself is in-repository (proposal p005434) |

## References

-   Proposal
    [#196: Language-level safety strategy](https://github.com/carbon-language/carbon-lang/pull/196).
-   Proposal
    [#5914: Updating Carbon's safety strategy](https://github.com/carbon-language/carbon-lang/pull/5914).
-   Proposal
    [p000257: Initialization of memory and variables](/proposals/p000257-initialization-of-memory-and-variables.md).
-   Proposal
    [p004880: Safety milestones and a 2025 roadmap](/proposals/p004880-safety-milestones-and-a-2025-roadmap.md).
-   Proposal
    [p005434: `ref` parameters, arguments, returns and `val` returns](/proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md).
-   Fork decision [F-013](/fork/decision-log.md) and the synthesized plan
    [fork/safe/plan.md](/fork/safe/plan.md), whose design-panel record is the
    option paper for this area.
-   The category pages: [Type safety](type_safety.md),
    [Initialization safety](initialization_safety.md),
    [Spatial safety](spatial_safety.md), [Temporal safety](temporal_safety.md),
    [Mutation safety](mutation_safety.md) and
    [Safe-Rust interop](rust_interop.md); and the
    [terminology](terminology.md) page.
