# Safe-Rust interop

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [The bar](#the-bar)
-   [The asymmetry](#the-asymmetry)
-   [Transport](#transport)
-   [Mapping](#mapping)
    -   [By concern](#by-concern)
    -   [By type](#by-type)
-   [The `Shared<T>` and `SharedView<T>` wrappers](#the-sharedt-and-sharedviewt-wrappers)
-   [Exported-signature examples](#exported-signature-examples)
-   [Verdict](#verdict)
-   [Performance parity](#performance-parity)
-   [C++ interop consequence](#c-interop-consequence)
-   [Implementation staging](#implementation-staging)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [External facts](#external-facts)
-   [References](#references)

<!-- tocstop -->

## Overview

This page is the analysis the 0.1 milestone asks for: how the safe-Carbon
design on the [safety strategy](README.md) page and its five category pages
impacts _safe_ Rust interop. It states what a Carbon function exported to Rust
promises, what a Rust function imported into Carbon is taken to promise, which
of those promises safe Rust can rely on without an `unsafe` block, at what
stage of the [implementation staging](README.md#implementation-staging) each
promise becomes checkable, and what gap remains. The vocabulary is the
strategy page's: the three pointer kinds of the
[pointer kinds table](README.md#pointer-kinds-at-a-glance), loans and `bound`
from [temporal safety](temporal_safety.md), the no-invalidation rule,
`Core.Plain` and the `Send`/`Sync`/`Freeze` facets from
[mutation safety](mutation_safety.md), and the `Core.Relocatable` facet from
[initialization safety](initialization_safety.md).

This page was fixed by fork decision [F-013](/fork/decision-log.md),
sub-decisions D-SAFE-19 and D-SAFE-22, synthesized in
[fork/safe/plan.md](/fork/safe/plan.md). No part of this page is implemented
in the toolchain (fork workstream SAFE-1, stage 0); see
[Implementation staging](#implementation-staging). Everything on this page is
_analysis_, not rule: the mapping depends on facts about Rust that live
outside this repository, each of which is listed under
[External facts](#external-facts) with its verification status (D-SAFE-22),
and no normative Carbon rule on any page depends on this one. The Carbon side
of every example is NEW syntax; the Rust side is a generated declaration that
no tool emits today. File and line citations are against trunk 0bdce60a5
unless a citation says otherwise.

## The bar

The safety strategy (proposal p005914) lists seamless _safe_ Rust interop as a
highly desirable goal: being "able to reliably and consistently avoid unsafe
on the boundary with Rust code", and "no worse than the best Rust/C++ interop
which uses extra safety annotations for the C++ API". It asks that, whether or
not the goal is fully met, the design "clearly demonstrate where we end up and
what any remaining gap there is". The strategy page's
[safe library ecosystem](README.md#safe-library-ecosystem) section states why
the goal matters: Carbon's strategy for safe, reusable cross-platform libraries
is to leverage Rust libraries through interop rather than duplicate them. The
[0.1 milestone](/docs/project/milestones.md) asks for "an analysis of how this
impacts _safe_ Rust interop" and excludes an implementation.

The bar this page measures against is therefore twofold. A Carbon API exported
to Rust should be usable from safe Rust, with `unsafe` appearing on the Rust
side only where Carbon itself spelled an obligation; and a Rust API imported
into Carbon should be callable from Strict Carbon with `unsafe` appearing only
where Carbon's loan rules cannot express what the Rust signature promises. The
[Verdict](#verdict) states where the design lands against each half and names
the gap.

## The asymmetry

The two boundaries are not alike, and the difference decides the shape of
everything below.

Toward C++, Carbon _assumes little_. C++ is Permissive Carbon (D-SAFE-18): C++
code is trusted to meet the contracts its declarations state, and nothing
more. Every pointer a C++ function returns is unverified (loan set ⊥, T6 of
the temporal page); an unannotated pointer-carrying C++ call is `unsafe` in
Strict; and the codegen rule T8 withholds `noalias` at every C++ boundary, so a
C++ callee that aliases or saves a pointer produces erroneous behavior, never
undefined behavior. The strategy's rule that "there won't be an assumption
that a call to C++ code won't save a copy of pointers to passed-in objects"
(proposal p005914) is the whole posture: Carbon protects itself from C++ by
assuming nothing, and C++ does not need to be told anything about Carbon.

Toward Rust, Carbon _must promise_. Safe Rust is compiled under its own
aliasing rules: a `&T` points to memory that is not mutated while the
reference is live, except inside an `UnsafeCell`, and a `&mut T` points to
memory that no other pointer reads or writes while it is live; breaking those
rules is undefined behavior on the Rust side whatever the other language does
([External facts](#external-facts), rows 1 and 2). A Carbon signature exported
to Rust as `fn f(p: &mut T)` is therefore a promise that no alias of `*p` is
read or written during the call, and a signature exported as `fn g(p: &T)` is
a promise that `*p` is not written during the call by anyone. Rust will
optimize on those promises. The asymmetry has three consequences:

-   **Only a Strict-checked function can make the promise.** A Strict body is
    checked against the loan rules, so its `exclusive T*` parameter really is
    the one live access path to its referent (T4, M2) and may export as
    `&mut T`. A Permissive body is trusted, not checked, and trust is not a
    basis for a promise to another compiler: the generator exports every
    Permissive function as a Rust `unsafe fn`, and it refuses `&mut` for a
    Permissive signature even when the Carbon parameter is `exclusive`. The
    `unsafe` on the Rust side is the same audit signal `unsafe permissive` is
    on the Carbon side.
-   **The shared-mutable kind cannot be a Rust reference to `T`.** Carbon's
    `T*` admits any number of aliases that write `Plain` fields and call `addr
    self` methods during one another's lifetimes (M3), which is exactly what a
    Rust `&T` forbids and a `&mut T` forbids more strongly. `T*` is exported
    as `&Shared<T>`, a wrapper that opts out of Rust's immutability guarantee
    the only way Rust permits, and the wrapper exposes exactly the surface M3
    allows. The [wrappers](#the-sharedt-and-sharedviewt-wrappers) section is
    the design of that promise.
-   **Even the const kind cannot be `&T` for an exported class.** Carbon
    writes `Plain` fields through `T*` aliases while a `const T*` to the same
    object is live (EX-TM-3 on the temporal page, EX-M-1 on the mutation page),
    and a value binding of a non-`Plain` type is a shared loan under which the
    same writes are permitted (D-SAFE-17). A Rust `&IntVec` reachable from the
    same exported signature set as a `&Shared<IntVec>` would make
    `Shared::set` undefined behavior for the holder of the `&IntVec`. So
    `const T*` exports as `&SharedView<T>`, the read-only `Cell`-shaped view,
    and as `&T` only under the proviso stated in the [type table](#by-type):
    `T: Core.Freeze` and no `T*` to the same object reachable from Rust in the
    exported signature set — in practice never for an exported class.

The direction into Carbon is the easy one for the same reason: a Rust
signature states its promises in its types and lifetimes, and the importer
derives `bound` from them, so a Rust result is never ⊥ when its lifetime is
declared. The one import that must be `unsafe` is the one where a Carbon
callback could break Rust's promise from the inside; the
[Verdict](#verdict), part (2), names it.

## Transport

The transport is analysis, not rule (D-SAFE-19): its three facts about Rust are
[External facts](#external-facts), rows 7 to 9. The expected shape is this.

-   **C-ABI shims, generated per function on both sides.** Carbon already lowers
    through the target's C++ ABI (fork design
    [threading and atomics](/fork/design-sprint/threading-atomics.md), the
    mechanism guarantee that separately compiled units interoperate through the
    C++ ABI and one LLVM lowering); the Rust binding generator of stage 6 emits,
    for each exported Carbon function, a C-ABI thunk on the Carbon side and an
    `extern "C"` declaration plus a safe wrapper on the Rust side, and for each
    imported Rust function the mirror pair. This is the shape of the best
    existing Rust/C++ tooling ([External facts](#external-facts), row 10),
    applied to Carbon's own lowering instead of to C++ headers.
-   **`extern "C"` only, never `"C-unwind"`.** A Rust panic that reaches a
    non-unwinding ABI boundary aborts the process; a foreign unwind that
    enters a Rust frame through a non-unwinding ABI is undefined behavior on
    the Rust side ([External facts](#external-facts), row 7). The shims are
    therefore `extern "C"`, and the design guarantees that nothing unwinds
    into them from the Carbon side: a Carbon fail-stop terminates without
    unwinding ([terminology](terminology.md#fail-stop); the
    [error handling](../error_handling.md#unrecoverable-errors) design fixes
    that a Carbon-initiated abort unwinds no frame of another language), and
    the C++ exceptions Carbon can see are fenced or caught at the C++ boundary
    before any Carbon frame, so none reaches a Rust frame through Carbon.
-   **Panics and fail-stops are process aborts, and Rust `Drop` does not run.**
    A Rust panic reaching Carbon aborts; a Carbon fail-stop under Rust frames is
    a process abort; in both, Rust destructors on the stack do not run — Rust's
    own abort has the same property ([External facts](#external-facts), rows 7
    and 8). This is documented as the boundary contract, not worked around: a
    Rust caller that needs cleanup on a Carbon fail-stop has the same options it
    has for its own `process::abort`, which is to say none, and Carbon offers no
    `"C-unwind"` variant that would change it.

## Mapping

Two tables state the mapping. The first is by concern, the shape the milestone
asks about; the second is by type, the shape a generator implements. The
_Stage_ column is attempt C's: it names the stage after which the Carbon side
provides what the row relies on, so that the row's promise is checkable rather
than trusted. The binding generator itself is stage 6, so no binding exists
before then; a row marked "0.1" is one whose Carbon-side fact holds in the 0.1
toolchain today, and a row marked "after stage 4" is one that is unsound to
emit until the loan checker exists.

### By concern

| Concern | Carbon side (this design) | Rust side | Boundary rule, and what safe Rust can rely on | Stage |
| --- | --- | --- | --- | --- |
| Ownership transfer | A `Core.Relocatable` value crosses by value: a bitwise relocation leaves the source unformed (I4, D-SAFE-13). A non-`Relocatable` value never crosses by value | `repr(C)` struct for a `Relocatable` type, with a generated `Drop` thunk that runs the Carbon destructor; an owning opaque handle otherwise | A value received by Rust is owned by Rust: Carbon holds no loan on it (a moved-from object is unformed, and I2 forbids its use). Safe Rust relies on the value being a complete, formed object of the declared `repr` | after stage 4 (the `Relocatable` facet and the move operator) |
| Aliasing and mutability | Three kinds: `exclusive T*` is the one live access path (T4, M2); `T*` admits aliases that write `Plain` fields and call `addr self` methods (M3); `const T*` reads. Invalidating operations need exclusive access (D-SAFE-9) | `&mut T`; `&Shared<T>`; `&SharedView<T>`, or `&T` under the proviso | A Strict signature's kinds are checked, so a `&mut T` received by Rust is unique for the call and a `&Shared<T>` is never read or written as a `&T`. Safe Rust relies on the usual meaning of `&mut`, and on `Shared<T>` exposing nothing M3 forbids | after stage 4 (the loan checker and `exclusive`) |
| Lifetimes at the boundary | Loans on places; `bound` ties a result or stored value to one parameter's loan set (T5); `bound(a)` names a set (stage 6); a free loan set is one with no place in it | One elided lifetime for `bound`; named lifetimes for `bound(a)`; `'static` for a free loan set | A `bound` result lives exactly as long as Rust's elided lifetime says; Rust's borrow checker then enforces on the Rust side what Carbon's loan checker enforced on the Carbon side. Safe Rust relies on the lifetime in the generated signature | after stage 4 (`bound`); after stage 6 (`bound(a)`) |
| Unwinding and panics | Fail-stop: one stderr line, then `abort()`; no unwinding of any frame | `extern "C"` shims; a panic reaching one aborts; `Drop` does not run on abort | Neither side ever unwinds through the other. Safe Rust relies on no Carbon frame unwinding into it, which `extern "C"` plus the fail-stop rule guarantees | 0.1 (fail-stop is the 0.1 behavior; the shim rule is a generator rule) |
| `Send`, `Sync` versus Carbon threads | Compiler-determined facets (D-SAFE-16): a `T*` or `Slice(T)` field makes a type neither; `exclusive T*` is `Send` iff `T: Send`; `const T*` is `Send` iff `T: Sync`; `unsafe impl` opts in. Thread-crossing APIs accept only free loan sets or join inside the borrow | `unsafe impl Send`/`Sync` emitted exactly when the Carbon facet holds; nothing exported `Send` or `Sync` before stage 5. `Shared<T>` and `SharedView<T>` are never `Sync` | A type Rust sees as `Send` is one Carbon's facet rules say may cross a thread, and Rust's `spawn` requires `'static`, the same free-loan-set rule as Carbon's `Core.Thread.Spawn`. Safe Rust relies on the auto-trait meaning of the emitted impls | after stage 5 (the facets) |
| ABI and representation | C++-ABI lowering; `Core.Optional(T*)` with a null niche (optional.carbon:186-203); `Core.Slice(T)` and `Core.String` as `{pointer, i64}` (slice.carbon, string.carbon:16-27); `choice` with a tag and a payload; interfaces, vtables and inheritance with no stable layout | `repr(C)` structs; `Option<&Shared<T>>` and `Option<&mut T>` by representation (the null-pointer optimization); two-word shims for views; `repr(C)` tagged unions for `choice`; opaque handles for interface- and inheritance-typed values | Nothing crosses by layout except what both sides document as layout: `repr(C)`, the `Option` niche, and views through a shim that re-forms them. Safe Rust relies on `repr(C)` and the `Option` guarantee only | 0.1 for the Carbon-side layout facts; the `choice` and view shims are generator work (stage 6) |

### By type

| Carbon (this design) | Rust | Condition | Stage |
| --- | --- | --- | --- |
| `exclusive T*` | `&mut T` | Strict-checked function only; the generator refuses `&mut` for a Permissive one | after stage 4 |
| `T*` | `&Shared<T>` | Always; `Shared<T>` is the generated `UnsafeCell`-based wrapper of the next section, exposing exactly the non-invalidating surface | after stage 4 |
| `const T*` | `&SharedView<T>` | By default: the read-only `Cell`-shaped view | after stage 4 |
| `const T*` | `&T` | Only when `T: Core.Freeze` and no `T*` to the same object is reachable from Rust in the exported signature set; in practice never for an exported class | after stage 5 (`Freeze`) |
| `Core.Slice(T)` | `&SharedSlice<T>` | Always; a `&[Cell<T>]`-shaped view formed through a two-word shim, never by layout | after stage 4 |
| `Core.Slice(const T)` | `&[T]` | Only for a `Freeze` element type under the same proviso as `&T`: `Buf.Set` during a live view is the temporal page's EX-TM-3, so a slice of a class reachable through `&Shared` cannot be `&[T]` | after stage 5 (`Freeze`) |
| `bound` parameter or result | one elided lifetime `'a` | The loan set is one parameter's | after stage 4 |
| `bound(a)` | named lifetimes | One name, one loan set (T5(f)) | after stage 6 |
| a free loan set | `'static` | A loan set with no place in it: an owner's value, a literal, a global | after stage 4 |
| a `Core.Relocatable` value | `repr(C)` struct by value, with a generated `Drop` thunk | The facet decides by-value crossing (D-SAFE-13) | after stage 4 |
| a non-`Relocatable` value | an owning opaque handle | Pinned types, and types that opt out by `unsafe impl` | after stage 4 |
| `Core.Optional(T*)` | `Option<&Shared<T>>` | By representation: the prelude's null niche is Rust's null-pointer optimization; not `Option<&T>`, for the reason `T*` is not `&T` | after stage 4 |
| `Core.Optional(exclusive T*)` | `Option<&mut T>` | By representation, Strict-checked function only | after stage 4 |
| a `choice` | a `repr(C)` tagged union, through the shim | The tag and payload are re-formed by the shim; no layout promise is made for the Carbon side | after stage 6 (generator) |
| `Core.String` | `&str` | Only with a UTF-8 obligation: a `Core.Utf8`-validated string (residue, D-SAFE-20), because Rust's `str` requires valid UTF-8 and Carbon's does not; `Core.String` is the prelude's `str`, which the design overview's interop section names `Core.Str` — the same type under the interop design's name | after stage 4, gated on `Core.Utf8` |
| `Core.Result(T, E)` | a `repr(C)` tagged union, through the shim, with `Ok`/`Err` as the variants | A `choice` (core/prelude/types/result.carbon:28) | after stage 6 (generator) |
| interface-typed and inheritance-typed values, vtables | opaque both ways | The strategy's interop posture for inheritance (proposal p005914) | — (not mapped) |
| generics | instantiated on the defining side | A generic Carbon function is exported per instantiation the Rust side names, and a generic Rust function is imported per instantiation the Carbon side names | after stage 6 (generator) |
| `Send`/`Sync` facets | `unsafe impl Send`/`Sync` | Emitted exactly when the facet holds; nothing before stage 5 | after stage 5 |

## The `Shared<T>` and `SharedView<T>` wrappers

The following is an analysis sketch in Rust, not generated code: it shows the
shape the stage-6 generator emits for an exported class `T` and the reason it
is sound under Rust's rules. The Rust facts it relies on are
[External facts](#external-facts), rows 1 to 6.

```rust
// Analysis sketch (D-SAFE-19), not generated code. One pair per exported class T.
#[repr(transparent)]
pub struct Shared<T>(core::cell::UnsafeCell<T>);
#[repr(transparent)]
pub struct SharedView<T>(Shared<T>);

impl<T> Shared<T> {
    // One pair per `Plain` field `f: F` of `T`; `F` maps to a `Copy` Rust type.
    pub fn get_f(&self) -> F { unsafe { (*self.0.get()).f } }
    pub fn set_f(&self, v: F) { unsafe { (*self.0.get()).f = v; } }
    // One per `addr self` method `M` of `T`: a shim call over the raw pointer.
    pub fn m(&self, /* mapped parameters */) -> R {
        unsafe { carbon_shim_T_M(self.0.get(), /* mapped arguments */) }
    }
    // Downgrade to the read-only view: the same object, fewer operations.
    pub fn view(&self) -> &SharedView<T> { unsafe { &*(self as *const Self as *const SharedView<T>) } }
}
impl<T> SharedView<T> {
    // One per `Plain` field: a copy out, never a reference in.
    pub fn get_f(&self) -> F { self.0.get_f() }
    // One per `const` method and per `ref self: const Self` method: a shim call.
    pub fn c(&self, /* mapped parameters */) -> R { /* as above, over `*const T` */ }
}
// No `unsafe impl Sync` is ever written for either wrapper: `UnsafeCell<T>` is `!Sync`,
// which is what D-SAFE-16's rule that a `T*` field makes a type neither `Send` nor
// `Sync` says from the Rust side. No method of either wrapper returns `&T` or `&mut T`.
```

Why this is safe Rust to use, in the terms of Rust's own rules:

-   **`UnsafeCell` is the one permitted opt-out.** Rust's immutability
    guarantee for `&T` is disabled only through `UnsafeCell<T>`, and a
    `&UnsafeCell<T>` may point to data that is being mutated. `&Shared<T>`
    therefore makes no promise Carbon's `T*` would break: a Carbon `addr self`
    method writing a `Plain` field through another `T*` alias during the Rust
    call is exactly the interior mutability the cell declares.
-   **No reference to the interior ever exists on the Rust side.** Every
    accessor copies a `Plain` value out or writes one in through the raw
    pointer `get()` returns, and every method goes through the shim with that
    raw pointer. The wrapper never produces a `&T` or a `&mut T`, so Rust's
    aliasing rules for references are never asserted on the object. This is
    `Cell<T>`'s discipline — a `&T` to the inner value can never be obtained,
    and the value is moved in and out — which is why the mapping calls the
    wrapper `Cell`-shaped and why `Cell` semantics are what the
    no-invalidation rule is: M3 permits through `T*` exactly reads, `Plain`
    writes and non-invalidating methods, and `Cell` permits exactly `get`,
    `set` and nothing that hands out a reference.
-   **Nothing invalidating is reachable.** The wrapper exposes no `ref self`
    method, no assignment of a non-`Plain` field, no move and no destroy; those
    need an `exclusive T*` on the Carbon side and a `&mut T` on the Rust side,
    which only a Strict-checked function receives.
-   **The wrapper is never `Sync`.** `UnsafeCell<T>` is `!Sync`, so neither
    wrapper is, and `&Shared<T>` is not `Send` because a `&U` is `Send` only
    when `U: Sync`. A `&Shared<T>` cannot cross a Rust thread, which is the
    Rust-side statement of D-SAFE-16's rule that a shared-mutable pointer is
    thread-local. The generator writes no `unsafe impl` for the wrappers.
-   **The A-9 proviso keeps `&T` honest.** If a `&T` to an object existed
    anywhere in the exported signature set while a `&Shared<T>` to the same
    object could be formed, `set_f` would mutate bytes a live `&T` promises
    are immutable, which is undefined behavior for the holder of the `&T`.
    `&T` is therefore emitted only when `T: Core.Freeze` and no `T*` to the
    same object is reachable from Rust in the exported signature set, and
    `&SharedView<T>` otherwise; the generator checks the whole set, not one
    signature.

`SharedSlice<T>` is the same construction over a view: a `&[Cell<T>]`-shaped
slice whose elements are read and written by copy, formed by a two-word shim
from the Carbon `{pointer, size}` and never by layout, because Rust makes no
guarantee about the layout of a pointer to an unsized type
([External facts](#external-facts), row 11). Rust itself provides the
conversion from a `&mut [T]` to a `&[Cell<T>]` (`Cell::from_mut` and
`Cell::as_slice_of_cells`), which is the precedent for a slice whose elements
are shared-mutable cells being safe Rust.

Break condition (D-SAFE-19): a Rust soundness argument against the wrapper —
an `UnsafeCell` reachable from a `Sync` type, say — makes `T*` fall back to a
raw pointer on the Rust side, which is attempt A's durable gap, and this page
would say so in a dated edit.

## Exported-signature examples

The Carbon side of each line is NEW syntax (`bound`, `exclusive`, `addr`);
the Rust side is the declaration the stage-6 generator emits, given as
analysis. The design-conformance checklist of
[fork/safe/plan.md](/fork/safe/plan.md) carries these as its "Rust rows" row,
with the outcome ANALYSIS (D-SAFE-22): no toolchain parses the Carbon side and
no tool emits the Rust side, and the Stage column says when each becomes
checkable.

```carbon
fn At[bound self: Self](i: i64) -> const i32*;      // → fn at<'a>(&'a SharedView<Self>, i: i64) -> &'a SharedView<i32>   (stage 4; never &'a i32 for an exported class — A-9)
fn Bump(p: exclusive Counter*);                     // → fn bump(p: &mut Counter)                 (stage 4)
fn Observe(p: Node*);                               // → fn observe(p: &Shared<Node>)             (stage 4; safe, Cell-shaped)
fn Longest(bound a: const Core.String*, bound b: const Core.String*) -> const Core.String*;   // → fn longest<'a>(a: &'a SharedView<str>, b: &'a SharedView<str>) -> &'a SharedView<str> (stage 6 for two names; &str needs Core.Utf8 and the Freeze proviso)
```

What each line shows:

-   **`At`: a `bound` result over a const receiver.** The receiver is
    `bound self: Self` on a `const` path, so the result's loan set is the
    receiver's and the generated lifetime `'a` ties the result to the
    receiver. The receiver exports as `&'a SharedView<Self>` and the result as
    `&'a SharedView<i32>`, not `&'a i32`: `i32` is `Freeze`, but the element
    lives inside an exported class that is reachable as `&Shared<Self>` from
    another signature, under which `set` on the element is permitted (EX-M-1
    on the mutation page writes `a->Set(0, 5)` while `first: const i32*` is
    live). A Rust `&'a i32` would promise immutability that Carbon does not
    keep. Stage 4, because `bound` and the loan checker are stage 4.
-   **`Bump`: the exclusive kind is `&mut`.** `exclusive Counter*` is the one
    live access path to its referent, checked by T4 in a Strict body, so Rust's
    `&mut Counter` is the exact analogue and is safe to hand out. Stage 4; and
    only for a Strict-checked `Bump` — a Permissive `Bump` exports as `unsafe
    fn bump(p: *mut Counter)`.
-   **`Observe`: the shared-mutable kind is `&Shared`.** `Node*` admits other
    `Node*` aliases during the call, so the Rust side receives `&Shared<Node>`,
    through which it may read, write `Plain` fields and call `addr self`
    methods, and nothing else. This is the observer and back-pointer idiom of
    the mutation page (M6) seen from Rust: safe, `Cell`-shaped, and never a
    `&Node`. Stage 4.
-   **`Longest`: two `bound` parameters need two names.** With one elided
    lifetime the result could be tied to one parameter only; two parameters
    whose loan sets both flow into the result need the stage-6 `bound(a)` to
    say which, and the generator then emits one named lifetime per name. The
    `const Core.String*` parameters export as `&'a SharedView<str>` rather
    than `&'a str`: `&str` needs the UTF-8 obligation of `Core.Utf8` and the
    `Freeze` proviso. Stage 6.

## Verdict

The four parts of D-SAFE-19, stated against [the bar](#the-bar).

1.  **Safe Rust calling Strict Carbon.** Every Strict-checked Carbon function
    over relocatable values, `exclusive T*`, `T*` as `&Shared<T>`, `const T*`
    as `&SharedView<T>`, with `bound`-expressible lifetimes, `Core.Optional(T*)`
    as `Option<&Shared<T>>`, `Core.Slice` as `&SharedSlice<T>`, `Core.Result`
    and `repr`-declared `choice` types exports as a safe Rust `fn`. A
    Permissive function always exports as a Rust `unsafe fn`, which is an
    audit signal rather than a gap: the `unsafe` on the Rust side marks
    exactly the Carbon code whose contract is trusted rather than checked.
2.  **Strict Carbon calling safe Rust.** A Rust function with
    `repr(C)`-mappable types and elidable lifetimes imports as a safe
    Carbon function with `bound` derived from its signature, so T6 does not
    apply: a Rust result whose lifetime is declared has a known loan set and
    needs no `unsafe *p`. The exception is a Rust function that takes a `&T`
    together with a Carbon callback: the callback can write through a `T*`
    alias of the same object and re-enter, breaking the `&T` promise from
    inside the call, so that import is `unsafe` with the obligation that the
    callback does not reach the object.
3.  **The remaining gap**, as the strategy asks it be stated. `&T` and `&[T]`
    are never produced for exported classes and slices; `&SharedView<T>` and
    `&SharedSlice<T>` stand in for them, which is the D-SAFE-17 value-binding
    case generalized to the boundary. Named lifetimes and outlives bounds wait
    on stage 6. `Send`/`Sync` export waits on stage 5. Interface-typed and
    inheritance-typed APIs are opaque in both directions. A `&T`-plus-callback
    import is `unsafe`. A Rust API with several lifetimes imports
    conservatively, with the weakest kind and the union of the loan sets
    until `bound(a)` can name them. Every item in this list degrades to
    `unsafe` on one side with a stated obligation, never to undefined
    behavior.
4.  **Performance.** No runtime cost beyond the shim call; spatial checks on
    the Carbon side match Rust's index checks, which the strategy budgets at
    1 to 2 percent; temporal safety is compile-time on both sides and adds
    nothing at the boundary. The next section states the parity in detail.

Against the bar: part (1) meets "reliably and consistently avoid unsafe on the
boundary" for Strict Carbon, with `unsafe` appearing on the Rust side exactly
where Carbon spelled `unsafe permissive`; part (2) meets it for the import
direction except the callback case; and part (3) is the demonstration of
"where we end up and what any remaining gap there is". Against "no worse than
the best Rust/C++ interop which uses extra safety annotations for the C++
API", the comparison is in the [C++ interop consequence](#c-interop-consequence)
section: the annotations that tooling relies on for C++ are the ones Carbon's
Strict signatures carry as checked facts.

## Performance parity

The mapping adds no runtime mechanism. Item by item:

-   **The shim.** One C-ABI call per boundary crossing, re-forming views and
    `choice` values on the way; a call that crosses by value or by pointer
    with no view or `choice` is one direct call. Nothing is allocated,
    reference-counted or registered: the strategy rules out reference counting
    and garbage collection by default (proposal p005914), and the temporal
    page's statement that no runtime temporal mechanism exists in Release
    holds at the boundary as everywhere else.
-   **`Shared<T>` accessors.** A `get_f` is a load through a raw pointer and a
    `set_f` a store; both are inlinable on the Rust side. An `addr self` method
    call is the shim call. There is no busy flag, no borrow counter and no
    check: `Core.Guarded(T)` (mutation page, M6) is the one opt-in dynamic
    exclusivity check in the design and it is a Carbon type the Rust side
    reaches like any other, never something the wrapper adds.
-   **Spatial checks.** A `Core.Slice` reached as `&SharedSlice<T>` is indexed
    on the Rust side with Rust's own bounds check and on the Carbon side with
    Carbon's fail-stop check ([spatial safety](spatial_safety.md), SP2); the
    two are the same check at the same cost, the 1 to 2 percent the strategy
    expects to spend on spatial safety. Neither side checks twice: an element
    read on the Rust side goes through the Rust check only.
-   **Temporal safety.** Compile-time on both sides: Carbon's loan checker on
    the Carbon side, Rust's borrow checker on the Rust side, meeting at the
    generated lifetime. No cost at the boundary.
-   **Zero-fill.** A `Relocatable` value crossing by value is a formed object
    (I6: no unformed object is passed or returned), so Release zero-fill (I5)
    is already paid on the Carbon side and nothing is re-initialized at the
    boundary.

The expected cost of safe interop is therefore the cost of the shim, which the
best existing Rust/C++ tooling pays too, and nothing that scales with the
number of objects or accesses.

## C++ interop consequence

C++ is Permissive Carbon (D-SAFE-18), and the asymmetry above is what the
three-language picture turns on: Carbon assumes little of C++, promises much to
Rust, and so a Carbon layer between the two is a checked signature over a
trusted body. The consequences:

-   **A C++ object reaches Rust as `&Shared<T>`.** C++ `T&` imports as shared
    `T*` ([temporal safety](temporal_safety.md), C++ interop consequence), and
    `T*` exports as `&Shared<T>`; C++ `const T&` imports as `const T*` and
    exports as `&SharedView<T>`. Nothing on the C++ side is ever
    `exclusive T*`, so no C++-owned object is ever seen by Rust as `&mut T`
    through a Carbon signature that merely forwards it. This is the correct
    outcome: a C++ object may have any number of C++-side aliases, and
    `Shared<T>` is the only Rust type that promises nothing about them.
-   **Pointers returned by C++ never become Rust references.** A C++ result
    is ⊥ (T6), and a ⊥ pointer has no loan set from which the generator could
    derive a lifetime. A Strict Carbon function that returns a C++ result
    unchanged does not type-check without `unsafe`, and a function that
    returns it through `unsafe as` with a stated extent is a Strict function
    whose contract the Carbon author took on, which exports as a safe `fn`
    with that author's obligation behind it. The audit line is the Carbon
    `unsafe`, in one place.
-   **The migration ladder is also the export ladder.** The strategy page's
    [migration example](README.md#c-migration-example) wraps a C++ API in a
    Permissive glue file (rung 1), calls it from a Strict file behind
    `unsafe import` (rung 2), and calls the annotated header directly (rung
    4). Seen from Rust: the glue function `NormalizeGlue` exports as `unsafe
    fn`, because its body is Permissive; the Strict `Unit` and `UnitChecked`
    export as safe `fn unit(v: &mut Vec3) -> f32`, because their bodies are
    checked and their `exclusive Cpp.Vec3*` parameter is the one live access
    path for the call. A codebase that walks rungs 1 to 4 for C++ therefore
    walks from `unsafe fn` to safe `fn` for Rust with no further work: the
    Strict wrapper is the safe Rust API.
-   **The annotations are the same ones.** The strategy's bar is "no worse
    than the best Rust/C++ interop which uses extra safety annotations for the
    C++ API". The annotations rung 4 relies on — `_Nonnull`, the noescape
    attribute, `[[clang::lifetimebound]]`, the thread-safety family — are the
    annotations such tooling consumes ([External facts](#external-facts), row
    10, UNVERIFIED for the exact set). Carbon's contribution is that, once a
    Strict signature stands over them, the Rust side receives a _checked_
    promise rather than an annotated C++ declaration: the loan checker
    established that `&len` in `UnitChecked` is a P1 loan on a local passed to
    a non-`bound` parameter, and Rust receives `f32` by value with no
    reference to reason about at all.
-   **Views cross three ways at no C++ cost.** `std::span<T>` imports as
    `Core.Slice(T)` and `std::string_view` as `Core.String` by layout
    ([interoperability](../interoperability/README.md#stdspan-and-coreslice)),
    and each exports to Rust through the two-word shim as `&SharedSlice<T>`
    or `&SharedView<str>`; the Carbon-side bounds check is the only check
    added, and `&str` for the string needs the UTF-8 obligation that C++'s
    `std::string_view` does not carry either.
-   **C++ exceptions never reach a Rust frame.** The
    [error handling](../error_handling.md) design fences or catches every C++
    exception at the C++ boundary, and a Carbon fail-stop unwinds no frame,
    so the `extern "C"` shims of the [transport](#transport) meet their
    no-unwind obligation by construction; no `"C-unwind"` is needed for a
    Carbon layer over C++, which the best existing Rust/C++ tooling cannot
    say of a direct binding to a throwing C++ function.
-   **The C++ thread model stays Permissive.** A C++-spawned thread running
    Carbon code is the 0.1 contract of the
    [threading and atomics](/fork/design-sprint/threading-atomics.md) design,
    under which races are the program's business; the `Send`/`Sync` impls the
    generator emits at stage 5 describe Carbon-spawned threads and Carbon
    facets, and an imported C++ type is neither `Send` nor `Sync` unless
    annotated (D-SAFE-16), so it is never exported as either.

## Implementation staging

The rows this page owns in the staging of D-SAFE-21; the
[safety README](README.md#implementation-staging) carries the full table. 0.1
claims no executable behavior from this page: no binding is generated, no
Carbon signature is exported to or imported from Rust by the 0.1 toolchain,
and this page is the analysis the 0.1 milestone asks for, not a
specification of a tool. The mapping's Stage column states when each row's
promise becomes checkable; the generator that emits the bindings is stage 6.

| Stage | Contents | Owned here |
| --- | --- | --- |
| 0 (this PR) | This page; no toolchain change | All of this page |
| 4 | The loan checker: loans, `bound`, no-invalidation, `exclusive`; `Core.Relocatable` and the move operator | The rows marked "after stage 4": `&mut T`, `&Shared<T>`, `&SharedView<T>`, `&SharedSlice<T>`, elided lifetimes, by-value `Relocatable` crossing, `Option<&Shared<T>>` and `Option<&mut T>`; `Core.Utf8` for `&str` (residue, D-SAFE-20) |
| 5 | Facets, `Core.Thread`, `--strict-concurrency` | The `Send`/`Sync` export row: `unsafe impl` emitted exactly when the facet holds, nothing before; the `Freeze` proviso under which `&T` and `&[T]` may be emitted |
| 6 | `bound(a)` and `Core.Lifetime`, `Core.DynCast`, the Rust binding generator | The generator itself: the C-ABI shims on both sides, the `Shared`/`SharedView`/`SharedSlice` wrappers, the `choice` and `Core.Result` tagged-union shims, per-instantiation generics; named lifetimes for `bound(a)` (the `Longest` example) |

Stages 1, 2 and 3 own nothing on this page: the spellings the examples use
parse at stage 1 under the temporal and mutation pages' rows, and no Rust-side
promise is sound to emit before the loan checker exists.

## Decisions within this design

Each decision below is a sub-decision of fork decision F-013, recorded with
its break condition in [fork/decision-log.md](/fork/decision-log.md); the
[safety README](README.md#decisions-within-this-design) and the category pages
carry the rest of D-SAFE-1 to D-SAFE-23.

-   **D-SAFE-19 — Safe-Rust interop mapping and verdict.** The transport is
    analysis, not rule. The mapping is as stated in [Mapping](#mapping):
    `exclusive T*` as `&mut T` for Strict-checked functions only; `T*` as
    `&Shared<T>`, a generated `UnsafeCell`-based wrapper exposing exactly the
    non-invalidating surface, safe Rust because `Cell` semantics are what the
    no-invalidation rule is; `const T*` as `&SharedView<T>` by default and as
    `&T` only under the `Freeze` and no-reachable-`T*` proviso; `Core.Slice(T)`
    as `&SharedSlice<T>`; `bound` as one elided lifetime and `bound(a)` as
    named lifetimes; `Core.Relocatable` values by value; `Core.Optional(T*)`
    as `Option<&Shared<T>>` by representation; `choice` as a `repr(C)`
    tagged union through the shim; `Core.String` as `&str` only with the
    UTF-8 obligation; interfaces and inheritance opaque; generics instantiated
    on the defining side; `Send`/`Sync` emitted as `unsafe impl` exactly when
    the facet holds. The verdict is the four parts of [Verdict](#verdict).
    Break condition: a Rust soundness argument against the `Shared<T>` wrapper
    — then `T*` falls back to a raw pointer on the Rust side, attempt A's
    durable gap, and this page says so in a dated edit.
-   **D-SAFE-22 — External facts are quarantined.** Every claim about Rust on
    this page — the aliasing rules for `&T` and `&mut T`, `UnsafeCell` as the
    one opt-out, `Cell`'s discipline, the auto-trait rules for `Send` and
    `Sync`, the `extern "C"` abort rule and `"C-unwind"`, the `Option` niche,
    `repr(C)`, the `str` invariant, the layout of pointers to unsized
    types, the shape of the best existing Rust/C++ tooling — appears in
    [External facts](#external-facts) with a status, VERIFIED against a
    primary source by the writer or UNVERIFIED and phrased as "we expect".
    The mapping rows depend on them and are therefore analysis, which is what
    the 0.1 milestone asks for. Break condition: the writer verifies an item —
    the tag is removed in a dated edit.

Three facts this page relies on are decided elsewhere: the three pointer kinds
and the loan rules are D-SAFE-7 and D-SAFE-10
([temporal safety](temporal_safety.md)); the no-invalidation rule, `Core.Plain`,
the facets and the value-binding rule are D-SAFE-9, D-SAFE-16 and D-SAFE-17
([mutation safety](mutation_safety.md)); `Core.Relocatable` and the move
operator are D-SAFE-13 ([initialization safety](initialization_safety.md)); the
C++ posture is D-SAFE-18 ([safety README](README.md#c-call-allowlist)).

## Alternatives considered

The design was chosen by a panel of three attempts and two judges, recorded in
[fork/safe/plan.md](/fork/safe/plan.md); the judges scored the attempts as
wholes, and the [safety README](README.md#alternatives-considered) carries
their verdicts. The alternatives specific to this page:

-   **Attempt A's raw-pointer export of `T*` as the durable gap.** Attempt A,
    "Strict Carbon by default: owners, loans, and operation-tied `unsafe`",
    mapped its shared-mutable kind to a raw pointer on the Rust side and
    named it "the one durable gap": every Carbon API taking a shared-mutable
    pointer would be an `unsafe fn` in Rust forever. Judge 1 scored this
    against attempt B's answer, writing that B "wins the tiebreak ... on the
    Rust analysis (a safe `Shared<T>` spelling where A declares a durable
    gap)". The synthesis takes B's wrapper: the gap A declared is a
    `Cell`-shaped type on the Rust side, safe because the no-invalidation rule
    is `Cell` semantics. A's raw pointer survives only as D-SAFE-19's break
    condition, the fallback if a Rust soundness argument against the wrapper
    is found.
-   **Attempt C's cxx-level posture for 0.1.** Attempt C, "Ratchet: hardened
    runtime core now, annotated borrows later", put Rust interop "at the cxx
    level in 0.1": raw pointers and opaque handles across a C ABI, with the
    safe mapping deferred to a later stage it did not design. Judge 1 found C
    "not a candidate base: its 0.1 scope leaves temporal/mutation
    'provisional-with-syntax'", and a Rust mapping over provisional temporal
    rules cannot state what safe Rust may rely on, which is what the milestone
    asks the analysis to state. The synthesis keeps C's per-row Stage column,
    so that what 0.1 can and cannot promise is said per row rather than by
    deferring the whole mapping.
-   **`&T` for `const T*` and `&[T]` for `Core.Slice(const T)` by default.**
    The plan's first revision mapped the const kind and const slices to Rust's
    plain references. The review found this inconsistent with EX-TM-3 and
    EX-M-1 (fold item A-9): Carbon writes `Plain` fields through `T*` aliases
    during a live `const T*`, which a Rust `&T` forbids. The rows were
    rewritten to `&SharedView<T>` and `&SharedSlice<T>` by default with `&T`
    only under the `Freeze` and no-reachable-`T*` proviso, and the verdict's
    part (1) was narrowed with the difference moved to part (3).
-   **A `"C-unwind"` transport.** Rejected: it would let a Rust panic unwind
    Carbon frames, which have no unwinder and whose fail-stop contract is that
    nothing unwinds, and it would require the C++ exceptions Carbon fences to
    be re-raised rather than terminated; the no-unwind rule the error-handling
    design already fixes for C++ is kept for Rust.
-   **Eager-copy value bindings, for a `&T` mapping.** D-SAFE-17's recorded
    alternative, eager acquisition for every type, would make a value binding
    carry no loan and would remove one of the two reasons `const T*` cannot be
    `&T`; it was rejected on the mutation page as costly for large owning
    types, and the other reason — `Plain`-field writes through `T*` aliases —
    would remain, so the mapping would not change.

That decision is final; this page specifies the chosen analysis rather than
relitigating it.

## External facts

Claims about tools outside this repository appear only here, with a status
(D-SAFE-22). Every mapping row on this page depends on at least one of these,
which is why the page is analysis rather than rule; no normative Carbon rule
on any page depends on an UNVERIFIED item. Where a status reads VERIFIED, the
source was read by the writer on 2026-10-12 and the quoted words are the
source's.

| Row | Fact | Used by | Status |
| --- | --- | --- | --- |
| 1 | Rust's `&T` must point to memory that is not mutated while the reference is live, except for data inside an `UnsafeCell`, and `&mut T` must point to memory that is not read or written by any pointer not derived from it and that no other reference points to while it is live; breaking these rules is undefined behavior | [The asymmetry](#the-asymmetry); the `&mut T` and `&T` rows; the A-9 proviso | VERIFIED against the Rust Reference, "Behavior considered undefined" ("`&T` must point to memory that is not mutated while they are live (except for data inside an `UnsafeCell<U>`), and `&mut T` must point to memory that is not read or written by any pointer not derived from the reference and that no other reference points to while they are live (with no exceptions)"; "the bytes pointed to by a shared reference ... are immutable") |
| 2 | `UnsafeCell<T>` is the only permitted way to disable the requirement that a shared reference's referent is not mutated; a `&UnsafeCell<T>` may point to data that is being mutated | The `Shared<T>` wrapper's soundness | VERIFIED against the Rust Reference, "Interior mutability" ("`std::cell::UnsafeCell<T>` type is the only allowed way to disable this requirement"), and the standard library's `UnsafeCell` page ("`UnsafeCell<T>` opts-out of the immutability guarantee for `&T`: a shared reference `&UnsafeCell<T>` may point to data that is being mutated") |
| 3 | `UnsafeCell<T>` and `Cell<T>` are not `Sync`; `Cell<T>` never gives out a `&T` to its inner value, and moves values in and out through `get` (for `Copy` types) and `set` | The wrappers' `Cell` discipline and their never being `Sync`; the `Send`/`Sync` row | VERIFIED against the standard library's `cell` module page ("`Cell<T>`, `RefCell<T>`, and `OnceCell<T>` allow doing this in a single-threaded way—they do not implement `Sync`"; "a `&T` to the inner value can never be obtained, and the value itself cannot be directly obtained without replacing it with something else"), the `UnsafeCell` page (`impl<T> !Sync for UnsafeCell<T>`) and the `Cell` page (`impl<T> !Sync for Cell<T>`; `get` under `where T: Copy`, "Returns a copy of the contained value"; `set`, "Sets the contained value") |
| 4 | `Cell::from_mut` turns a `&mut T` into a `&Cell<T>`, and `Cell::as_slice_of_cells` turns a `&Cell<[T]>` into a `&[Cell<T>]`; `Cell<T>` has the same in-memory representation as `T` | The `SharedSlice<T>` construction as a `&[Cell<T>]`-shaped view | VERIFIED against the standard library's `Cell` page (`pub const fn from_mut(t: &mut T) -> &Cell<T>`; `pub const fn as_slice_of_cells(&self) -> &[Cell<T>]`; "has the same in-memory representation as its inner type `T`"); whether `Cell` is declared `repr(transparent)` was not confirmed and the sketch's use of that attribute on the wrappers is the generator's own choice |
| 5 | `Send` and `Sync` are auto traits implemented structurally: structs, enums, unions and tuples implement one when all their fields do; `&T` is `Send` only when `T` is `Sync`; `*mut T` has a negative `Send` impl; both are declared `unsafe auto trait`, and a type `T` is `Sync` if and only if `&T` is `Send` | The `Send`/`Sync` row; the facet rules of D-SAFE-16, whose soundness argument is this one | VERIFIED against the Rust Reference, "Special types and traits", "Auto traits" ("Structs, enums, unions, and tuples implement the trait if all of their fields do"; "the standard library implements `Send` for all `&T` where `T` is `Sync`"; "`*mut T` has a negative implementation of `Send`"), and the standard library's `Send` and `Sync` pages (`pub unsafe auto trait Send`, `pub unsafe auto trait Sync`; "a type `T` is `Sync` if and only if `&T` is `Send`"; "the `set` method on `Cell<T>` takes `&self` ... thus `Cell` cannot be `Sync`") |
| 6 | Rust's `std::thread::spawn` requires its closure and result to be `Send + 'static`, because the thread may outlive its creator | The "`Send`, `Sync` versus Carbon threads" row: the same shape as the thread-boundary lifetime rule of D-SAFE-16 | VERIFIED against the standard library's `spawn` page (`F: FnOnce() -> T + Send + 'static, T: Send + 'static`; "threads can outlive the lifetime they have been created in"; "the `Send` marker trait expresses that it is safe to be passed from thread to thread") |
| 7 | A Rust panic that reaches a non-unwinding ABI boundary such as `"C"` aborts; a foreign unwind entering a Rust frame through a non-unwinding ABI is undefined behavior; `"C-unwind"` is the ABI that permits unwinding across the boundary; when a panic is turned into an abort at such a boundary, it is unspecified whether destructors up to the boundary run | [Transport](#transport); the "Unwinding and panics" row | VERIFIED against the Rust Reference, "Functions", "Unwinding" (the table: `panic=unwind`, non-unwinding ABI, `panic`-unwind "abort", native unwind "undefined behavior"; "either no destructors (`Drop` calls) will run, or all destructors up until the ABI boundary will run. It is unspecified which") and the Rustonomicon, "FFI and unwinding" ("`panic` will cause the process to safely abort"; "A foreign exception entering Rust will cause undefined behavior") |
| 8 | Rust's process abort runs no destructors on any thread's stack | The "`Drop` does not run" sentence of the transport | VERIFIED against the standard library's `process::abort` page ("no destructors on the current stack or any other thread's stack will be run") |
| 9 | `Option<T>` has the same size, alignment and function-call ABI as `T` for `&U`, `&mut U`, `Box<U>`, `NonNull<U>` and function pointers, with an all-zero representation for `None`: the null-pointer optimization, which is guaranteed | The `Core.Optional(T*)` as `Option<&Shared<T>>` row and the `Option<&mut T>` row | VERIFIED against the standard library's `option` module page, "Representation" ("Rust guarantees to optimize the following types `T` such that `Option<T>` has the same size, alignment, and function call ABI as `T`", the table listing `&U`, `&mut U`, `Box<U>`, `ptr::NonNull<U>` and `fn` pointers, and `repr(transparent)` structs around one of them, with `None` as all-zero bytes) and the Rustonomicon ("unlike other optimizations it is guaranteed to apply to eligible types"); `Option<&Shared<T>>` is in the table because `Shared<T>` is `repr(transparent)` around an `UnsafeCell<T>`, and `UnsafeCell<T>` is itself `repr(transparent)` — the latter is UNVERIFIED on this page and the generator may instead emit the niche through the shim |
| 10 | The best existing Rust/C++ interop tooling generates per-function thunks on both sides and exposes C++ functions to Rust as safe `fn` wrappers over `unsafe` thunk calls, with its trust in the C++ side established by annotation of the C++ API rather than by checking it | [Transport](#transport); the "annotations are the same ones" item of the C++ interop consequence; the strategy's "no worse than the best Rust/C++ interop" bar | UNVERIFIED as to the trust model: we expect it to be annotation-based, and a landing page read on 2026-10-12 shows a generated safe `fn add_two_integers` wrapping `unsafe { ... __rust_thunk ... }` but states no rule for pointer-carrying functions; the thunk shape is VERIFIED from that page, the exact annotation set is not |
| 11 | Rust makes no guarantee about the layout of a pointer to an unsized type beyond its size and alignment being at least a thin pointer's; all such pointers are currently two words, which is explicitly not to be relied on | The `&SharedSlice<T>` row's "never by layout" and the two-word shim | VERIFIED against the Rust Reference, "Type layout" ("Though you should not rely on this, all pointers to DSTs are currently twice the size of the size of `usize` and have the same alignment") |
| 12 | A `repr(C)` struct is laid out field by field with C's padding rules, and a `repr(C)` enum with fields is represented as a `repr(C)` struct of a tag and a `repr(C)` union of the variants' payloads, the C "tagged union"; the default representation guarantees nothing beyond soundness | The "ABI and representation" row; the `choice` and `Core.Result` rows; by-value `Relocatable` crossing | VERIFIED against the Rust Reference, "Type layout" ("The representation of a `repr(C)` enum with fields is a `repr(C)` struct with two fields, also called a 'tagged union' in C"; "There are no other guarantees of data layout made by this representation") |
| 13 | A Rust `&str` is a pointer to bytes and a length, and Rust libraries may assume it is always valid UTF-8; constructing one without the check is `unsafe` | The `Core.String` as `&str` row and its `Core.Utf8` obligation | VERIFIED against the standard library's `str` page ("Rust libraries may assume that string slices are always valid UTF-8"; "A `&str` is made up of two components: a pointer to some bytes, and a length"; `from_utf8_unchecked` is `unsafe` with the safety requirement "The bytes passed in must be valid UTF-8") |
| 14 | Rust's `&mut T` is the unique way to access its referent while live and any number of `&T` may exist, during which direct mutation is prevented except through interior mutability; a borrow's lifetime is computed over the control-flow graph | The analogue column of the strategy page's pointer kinds table; the "Lifetimes at the boundary" row's claim that Rust's borrow checker enforces the generated lifetime | VERIFIED on the [temporal safety](temporal_safety.md#external-facts) page against the Rust Reference and RFC 2094; not re-verified here |

## References

-   Proposal
    [p005914: Updating Carbon's safety strategy](/proposals/p005914-updating-carbon-s-safety-strategy.md),
    for the bar, the interop posture toward unsafe code and the inheritance
    divergence.
-   Proposal
    [p005434: `ref` parameters, arguments, returns and `val` returns](/proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md),
    for `bound`.
-   Proposal
    [p006357: C++ interop: mapping pointer types](/proposals/p006357-c-interop-mapping-pointer-types.md),
    for `Core.Optional(T*)` and its null representation.
-   Proposal
    [p000257: Initialization of memory and variables](/proposals/p000257-initialization-of-memory-and-variables.md),
    for the unformed state a relocated value leaves behind.
-   The [0.1 milestone](/docs/project/milestones.md), whose safe-Carbon bullet
    asks for this analysis.
-   [Safety](README.md): the soundness model, the safety modes, the pointer
    kinds table with its Rust analogue column, the C++ call allowlist, the
    safe library ecosystem section and the migration example; the
    [terminology](terminology.md) page for fail-stop.
-   The sibling category pages: [Type safety](type_safety.md) for `unsafe as`
    and ⊥, [Initialization safety](initialization_safety.md) for
    `Core.Relocatable` and moves, [Spatial safety](spatial_safety.md) for
    views and their checks, [Temporal safety](temporal_safety.md) for the
    kinds, loans, `bound` and T6, and [Mutation safety](mutation_safety.md)
    for the no-invalidation rule, `Core.Plain`, `Core.Guarded`, value
    bindings and the facets.
-   [Error handling: unrecoverable errors](../error_handling.md#unrecoverable-errors),
    for the no-unwind rule at a language boundary.
-   [Interoperability](../interoperability/README.md): `std::span` and
    `Core.Slice`, `std::string_view` and `str`; the design overview's
    [interoperability](../README.md#bidirectional-interoperability-with-c-and-c)
    section for the `Core.Str` name.
-   Fork design
    [threading and atomics](/fork/design-sprint/threading-atomics.md), for
    the C++-ABI lowering the shims build on and the 0.1 thread contract.
-   The prelude's `Core.Optional` (core/prelude/types/optional.carbon),
    `Core.Slice` (slice.carbon), `Core.String` (string.carbon) and
    `Core.Result` (result.carbon).
-   Fork decision [F-013](/fork/decision-log.md) and the synthesized plan
    [fork/safe/plan.md](/fork/safe/plan.md), whose design-panel record is the
    option paper for this area.
