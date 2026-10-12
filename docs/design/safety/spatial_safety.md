# Spatial safety

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Rules](#rules)
    -   [SP1: No pointer arithmetic](#sp1-no-pointer-arithmetic)
    -   [SP2: Every element access is bounds-checked and fails-stop in every build mode](#sp2-every-element-access-is-bounds-checked-and-fails-stop-in-every-build-mode)
    -   [SP3: Views carry their length and a loan](#sp3-views-carry-their-length-and-a-loan)
    -   [SP4: `unsafe fn GetUnchecked` is the only opt-out](#sp4-unsafe-fn-getunchecked-is-the-only-opt-out)
    -   [SP5: Hardening extensions carry no Strict guarantee](#sp5-hardening-extensions-carry-no-strict-guarantee)
-   [Arithmetic](#arithmetic)
-   [Runtime behavior and messages](#runtime-behavior-and-messages)
-   [Worked examples](#worked-examples)
-   [C++ interop consequence](#c-interop-consequence)
-   [Implementation staging](#implementation-staging)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [External facts](#external-facts)
-   [References](#references)

<!-- tocstop -->

## Overview

[Spatial safety] is the property that memory is accessed only within the bounds
of the object it belongs to. In Carbon it is a run-time property: the
[memory safety model](README.md#memory-safety-model) assigns it to run-time
enforcement, and this page states what that enforcement is. There is no pointer
arithmetic, so the only way to reach an element of a contiguous region is
through an indexable type, `array(T, N)`, `Core.Slice(T)` or `Core.Buf(T)`;
every element access through those types is bounds-checked; a violation
[fails-stop][fail-stop] in every build mode and in every
[safety mode](README.md#safety-modes); the only way to read without the check
is an `unsafe fn`, spelled `unsafe` at the call; and a view carries its length
together with a loan on the storage it views, so that a bounds check is never
performed against storage that no longer exists. Integer arithmetic belongs on
this page too, because a wrongly computed index is the one path by which a
checked access could reach the wrong element without the program noticing: the
rule is that arithmetic never produces undefined behavior in Carbon code.

[spatial safety]: /docs/design/safety/terminology.md#spatial-safety
[fail-stop]: /docs/design/safety/terminology.md#fail-stop

The [safety strategy](README.md) states the
[soundness model](README.md#soundness-model) these rules sit under and the
[safety modes](README.md#safety-modes) that decide where the `unsafe` keyword is
required; what distinguishes this category from the others is that the modes
change nothing here. The strategy's diagnostic matrix,
[What each mode diagnoses](README.md#what-each-mode-diagnoses), carries one row
for spatial safety, "bounds and division-by-zero", and the row reads fail-stop
in every column: Permissive removes only the keyword from the one unchecked
accessor, never the check. The [temporal safety](temporal_safety.md) page
defines the loans that SP3 attaches to views, and the [slices](../slices.md)
design is the library this page's rules are enforced by.

This page was fixed by fork decision [F-013](/fork/decision-log.md),
sub-decisions D-SAFE-14 and D-SAFE-15, synthesized in
[fork/safe/plan.md](/fork/safe/plan.md). No part of this page beyond the live
`Core.Slice`/`Core.Buf` check the slices design already specifies is
implemented in the toolchain (fork workstream SAFE-1, stage 0); see
[Implementation staging](#implementation-staging). What the toolchain does
today is this. The bounds check on `Core.Slice(T)` and `Core.Buf(T)` is live
and fails-stop unconditionally, the 0.1 toolchain having a single mode in which
the release baseline's bounds checks cannot be turned off (fork decision
D-SL-4, [Slices: bounds behavior](../slices.md#bounds-behavior)). An
`array(T, N)` subscript with a constant index is rejected at compile time when
it is out of range (`ArrayIndexOutOfBounds`, toolchain/check/eval.cpp:1080-1116)
and an `array(T, N)` subscript with a run-time index is lowered with no check
at all (toolchain/lower/handle.cpp:47-74, an `inbounds` GEP). No unchecked
accessor exists on either view type: `UnsafeMake` and `Data()` form views, they
do not read without a check. Integer division by zero is emitted unguarded
(toolchain/lower/handle_call.cpp:188-192). File and line citations are against
trunk 0bdce60a5 unless a citation says otherwise; the examples marked "today's
syntax" that use only the upstream prelude were compiled on the 2026.10.12
nightly toolchain and their outcomes are stated with each example, and the
examples that use the fork's `Core.Slice` cite the scoreboard program that
proves their outcome.

## Rules

### SP1: No pointer arithmetic

Carbon pointers do not support pointer arithmetic; the only pointer operations
are dereference and address-of
([pointer types](../README.md#pointer-types)). A `T*` therefore names one
object and can reach no other, and an out-of-bounds access cannot be written
with a pointer. The prelude's `pointer.offset` builtin, which the view types
use to reach an element, is bound by a `private fn` of the slice and buffer
libraries (core/prelude/types/slice.carbon:19, buf.carbon:17); the `private`
hides the wrapper, not the builtin, and the toolchain today accepts a binding
of it in any file: toolchain/check/testdata/builtins/pointer/offset.carbon:23
declares `fn Offset[T: type](p: T*, n: i64) -> T* = "pointer.offset";` in a
Main-package library. The rule is therefore stated on the declaration (amended
2026-10-12, document-review fold: MAJOR-1): in Strict Carbon a builtin binding
outside the prelude is declared `unsafe fn`, as in
`unsafe fn Offset[T: type](p: T*, n: i64) -> T* = "pointer.offset";`, else
`StrictBuiltinBindingUnmarked` ([type safety](type_safety.md) owns the
spelling and the Permissive twin `PermissiveBuiltinBinding`); every call of it
is an `unsafe fn` call under the type page's TY2, the obligation being that the
result stays within the object `p` names; and the search for `unsafe` finds
every such binding, which the W-131 marking pass enforces. With that rule the
elements of a contiguous region are reached only through the indexable types
of SP2, and spatial safety reduces to the bounds behavior of three types
rather than to a property of every pointer.

### SP2: Every element access is bounds-checked and fails-stop in every build mode

Every element access through `array(T, N)`, `Core.Slice(T)` and `Core.Buf(T)`
is bounds-checked, and a violation fails-stop: one line on stderr naming the
operation, then `abort()`
([Runtime behavior and messages](#runtime-behavior-and-messages)). The check is
present in the Release build, the Debug build and every specialized build mode
of the [build modes](README.md#build-modes) section, because the release
baseline of hardening the strategy promises is exactly this check, and it is
present in Strict and Permissive alike, because the safety modes govern where
the `unsafe` keyword is written and this access has no keyword. The fork's
decision D-SL-4, that the 0.1 toolchain's one mode fails-stop unconditionally,
is retained as the Release baseline rather than being the Debug promise it was
adopted from.

The check has three shapes today and one gap:

-   A `Core.Slice(T)` read, `s[i]` or `s.Get(i)`, tests `i < 0 or i >= Size()`
    before the `pointer.offset` (slice.carbon:39-44), and `Subslice(start,
    end)` tests `0 <= start <= end <= Size()` (:46-52). The subscript reaches
    `Get` through the `final impl ... as IndexWith(i64)` at :74-77.
-   A `Core.Buf(T)` read goes through `AsSlice` to the same check
    (buf.carbon:45), and a `Buf` write, `Set(i, value)`, tests the same bounds
    before its store (:48-53).
-   An `array(T, N)` subscript with a constant index is checked at compile time
    by constant evaluation: an index past the end is `ArrayIndexOutOfBounds`,
    "array index `{0}` is past the end of type {1}" (eval.cpp:1080-1116), and
    the program is rejected.
-   The gap: an `array(T, N)` subscript with a run-time index is lowered as an
    `inbounds` GEP with no compare (lower/handle.cpp:47-74). This is a stage-2
    lowering residue (W-130): `ArrayIndex` emits the same compare-and-`fail_stop`
    sequence as `Slice.Get`, with the message "carbon: array index out of
    bounds; terminating", and array subscripts go through `IndexWith(i64)`
    instead of the hardcoded `i32` of toolchain/check/handle_index.cpp:165-170,
    which absorbs the `i32`-subscript residue W-116.

The check costs one compare per access and nothing else: no bounds metadata is
added to a pointer, no allocation is instrumented, and the message text is a
constant (`FailStop(message: str) = "fail_stop"`, slice.carbon:20), so no
formatting runtime is linked. That the cost is low is the strategy's own
expectation ([Build modes](README.md#build-modes), its evidence link); the fork
does not depend on a figure for it, and the one it has seen is an
[external fact](#external-facts).

### SP3: Views carry their length and a loan

A view is a non-owning pointer-and-count over storage it does not own
([Slices: forming a view](../slices.md#forming-a-view)): the length is what SP2
checks against, and the storage must outlive the view for the check to mean
anything. In Strict Carbon that obligation is checked: a view carries a loan on
its storage, in the sense of the [temporal safety](temporal_safety.md) page,
and the loan is formed by the function that produced the view. Concretely, on
`Core.Slice(T)` and `Core.Buf(T)`:

-   `FromArray` takes `bound p`, so the view holds a loan on `*p` and a view of
    a local array cannot escape the local's scope.
-   `Data`, `Get`, `AsSlice`, `Subslice`, the `Slice(T) as
    ImplicitAs(Slice(const T))` conversion's `Convert` (slice.carbon:80-84),
    the C++-container `C as ImplicitAs(Slice(C.Element))` conversion's
    `Convert` (:100-106) and every other producer whose result views `self`'s
    storage take `bound self`, so a view derived from a view or from a `Buf`
    holds the loan of what it was derived from, and the `Copy.Op` at :54-56
    preserves the loan under the temporal page's rule that copies preserve
    loans (T2).
-   `UnsafeMake` becomes `unsafe fn Make(p: T*, size: i64) -> Self`, with the
    sentence slice.carbon:29-30 already carries as its stated obligation: the
    caller guarantees that `p` names at least `size` valid elements that
    outlive the view. A Strict call of it is spelled
    `unsafe Core.Slice(T).Make(p, n)`, and because the marker takes on that
    obligation the result carries the loan set the signature gives — free,
    rule T6 of the temporal page — so no later access through the view needs
    a marker (amended 2026-10-12, document-review fold: D-1).

The W-128 audit rule generalizes the list: the prelude churn reviews every
prelude signature as if its body were Strict-checked, the body itself trusted
(D-SAFE-18), and every parameter, receiver, value or pointer, including a type
parameter `T` that may be instantiated to a pointer-carrying type, whose loans
can reach the result or be stored into `self` is marked `bound`, or the function
becomes `unsafe fn`. Because an impl may drop but not add `bound` (proposal
p005434), the interface declarations `IndexWith.At`
(core/prelude/operators/index.carbon:9) and `Copy.Op`
(core/prelude/copy.carbon:10) carry `bound self` so that the `Slice` and `Buf`
impls may keep it. The named hits today, beyond the view producers above, are
`Optional(T).Get` and `Optional(T).Some`, `OptionalStorage.Get`, `Try.Branch`,
`Buf(T).Make`'s `fill: T`, `Buf.Get`, `Buf.At` and `Slice.At`; the temporal page
carries the regression programs (`Launder1` to `Launder5` in EX-TM-8).
`Core.String`, the prelude's non-owning string, is audited the same way. That
churn is a named residue item, W-128, gated on stage 1, and no example on this
page assumes it has landed: 0.1 keeps the unchecked contract the slices design
states, and the [slices](../slices.md) page carries a dated amendment saying so.

### SP4: `unsafe fn GetUnchecked` is the only opt-out

Unchecked access is `unsafe fn GetUnchecked[bound self: Self](i: i64) -> T` on
`Core.Slice(T)` and `Core.Buf(T)`, declared `unsafe fn` from the start and
spelled `unsafe s.GetUnchecked(i)` at every Strict call
([type safety](type_safety.md), TY2). Its stated obligation is that
`0 <= i < Size()`; nothing else about the call changes, and the `bound self`
keeps the result's loan the same as `Get`'s. This is the "ways to write unsafe
code that disables the run-time enforcement" the strategy's
[build modes](README.md#build-modes) section promises, and it is the only such
way: no build flag disables the checks. The strategy's sentence that Carbon
"will provide a way to disable the default hardening in release builds, but not
in a supported way" is withdrawn by the fork, dated, in a blockquote under
that sentence; the per-site `unsafe fn GetUnchecked` keeps proposal p000196's
"manually disabled for performance-critical use cases" at the site, where an
audit finds it with the same search that finds every other `unsafe`, rather
than at the build, where no search in the source finds it.

Permissive removes only the keyword: `s.GetUnchecked(i)` in a Permissive body
is the same unchecked read with no marker (the `StrictUnsafeCallUnmarked` row
of the matrix is "none — assumed fact" in Permissive). It never removes a
check from `s[i]`, `Get`, `Set` or `Subslice`. The accessor does not exist in
the 0.1 prelude, which is why the "Unchecked slice access" entry of
[Slices: 0.1 limits](../slices.md#01-limits) is removed by W-128's accessor,
not by a build mode as that entry anticipated.

### SP5: Hardening extensions carry no Strict guarantee

The specialized Release build modes of the strategy, Control-Flow Integrity and
hardware-assisted address sanitizing among them
([Build modes](README.md#build-modes)), are extensions that some users can
afford, and the strategy's [constraints](README.md#constraints) say why they
are not the baseline. None of them is part of what Strict Carbon guarantees:
the spatial guarantee is SP1 to SP4 and nothing more, so a Strict program is
exactly as spatially safe under the plain Release build as under any extension,
and an extension is a defense for the Permissive, `unsafe` and C++ code the
soundness model trusts rather than checks.

## Arithmetic

Integer arithmetic is on this page because an index is an integer, and a
wrongly computed index is the one path by which a bounds-checked access could
reach the wrong element without the program noticing. The rule (D-SAFE-15,
amending the build-mode behavior of
[Arithmetic: overflow and other error conditions](../expressions/arithmetic.md#overflow-and-other-error-conditions)
and answering its open question) is that arithmetic in Carbon code never
produces undefined behavior:

-   **Release: signed overflow wraps.** The existing lowering, which emits
    `add`, `sub` and `mul` without the `nsw` flag
    (toolchain/lower/handle_call.cpp:165-181, `SignedOverflowIsUB = false`),
    is made normative: the result is the two's complement result. An overflowed
    index is then a logic bug, not a memory bug, because the access it feeds
    is still bounds-checked.
-   **Every mode: division and remainder by zero fail-stop.** Signed or
    unsigned `/` and `%` by zero fails-stop with "carbon: division by zero;
    terminating" before the division instruction. The guard is NEW, emitted
    before the `CreateSDiv`/`CreateSRem` at handle_call.cpp:188-192 and their
    unsigned twins at :210-214, and lands at stage 2 (W-130).
-   **Debug: overflow fails-stop with a diagnostic.** The Debug build turns the
    wrap into a fail-stop at the operation, which is the development-build row
    of the arithmetic design's table made concrete.
-   **Compile time: overflow is rejected**, as it is today.

The arithmetic design's "performance build" row, under which the optimizer may
assume overflow and division by zero do not occur so that "the behavior of the
program is not defined", is withdrawn for Carbon code: proposal p005914 forbids
undefined behavior in safe code, and with bounds checks in place the one
consequence of overflow the row was guarding against, an out-of-range access,
cannot occur. Its open question, whether a hardened build should trap, wrap or
produce zero, is answered: wrap in Release, trap in Debug, never zero. The
arithmetic page carries a dated blockquote with this decision. The break
condition is a real-world benchmark of the class p005914 names where the loss
of `nsw` exceeds 0.5 percent; that is an owner call on a performance-build
opt-in, not a change to the rule.

## Runtime behavior and messages

A violation of SP2 or of the division rule fails-stop: one line on stderr
naming the operation, then `abort()`. The process dies with `SIGABRT`; nothing
is unwound and no further program logic runs
([fail-stop][fail-stop]). The lowering of the `fail_stop` builtin is a
`write(2, message, size)` followed by a call of `abort`, declared `noreturn`
(handle_call.cpp:682-717). The messages are:

```text
carbon: Core.Slice index out of bounds; terminating
carbon: Core.Slice.Subslice range out of bounds; terminating
carbon: Core.Buf index out of bounds; terminating
carbon: Core.Buf size is negative; terminating
carbon: heap allocation failed; terminating
carbon: array index out of bounds; terminating
carbon: division by zero; terminating
```

The first five exist today (slice.carbon:41, :48-49; buf.carbon:30, :34, :50)
and are the ones [Slices: bounds behavior](../slices.md#bounds-behavior) lists;
the last two are stage 2. The message names the operation, not the index: the
text is a constant so that `fail_stop` needs no formatting runtime, and
reporting the offending index and size is the residue item W-113, which
changes the text and nothing else. `abort()` does not flush stdio, so a program
that writes to stdout before the violation may lose that output; the fork's
fail-stop conformance program deliberately checks only the exit status.

The row this page owns in the strategy's matrix,
[What each mode diagnoses](README.md#what-each-mode-diagnoses), copied in the
matrix's vocabulary:

| Diagnostic (owning page) | Strict | Permissive | Debug runtime |
| --- | --- | --- | --- |
| bounds and division-by-zero (this page) | fail-stop | fail-stop (identical) | fail-stop (identical) |

There is no `Strict` diagnostic on this page and no Permissive twin: the one
static diagnostic a spatial rule produces is today's `ArrayIndexOutOfBounds`
for a constant index, emitted in both modes, and the one keyword a spatial rule
requires is the `unsafe` of SP4, whose absence is the type page's
`StrictUnsafeCallUnmarked`.

## Worked examples

Each rule carries the example the design-conformance checklist
(fork/safe/plan.md §4.1) assigns to it, with the outcome the checklist states
against the 0.1 toolchain: ACCEPTS, REJECTS, ACCEPTS-UNCHECKED (compiles today
but the design says the runtime must check, with the stage that will) or
NEW-SYNTAX (no toolchain parses it, with the stage that will). EX-SP-3, EX-SP-4
and EX-SP-6 use only the upstream prelude and were compiled on the 2026.10.12
nightly toolchain with `carbon compile --output-last-input-only` and no
`package` line; EX-SP-1 and EX-SP-2 use the fork prelude's `Core.Slice`, which
that toolchain lacks, and are proven by the scoreboard programs they cite. Tags
of the form A-n, B-n and RR-n in example comments index the review-fold record
of [fork/safe/plan.md](/fork/safe/plan.md).

```carbon
// EX-SP-1 (today's syntax; runs today)
fn Sum(s: Core.Slice(i32)) -> i32 {
  var total: i32 = 0;
  var i: i64 = 0;
  while (i < s.Size()) { total += s[i]; ++i; }   // checked; final impl Slice(T) as IndexWith(i64)
  return total;
}
// EX-SP-2 (today's syntax; runs today — slices_bounds_fail_stop.carbon, EXPECT-EXIT -6)
fn Oob() -> i32 {
  var a: array(i32, 2) = (1, 2);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  Core.Print(s[RuntimeSeed(-18) as i64]);   // index 2: one stderr line, abort()
  return 0;
}
// EX-SP-3 (today's syntax; rejected today: ArrayIndexOutOfBounds, eval.cpp:1080-1116)
fn ConstOob() -> i32 { var a: array(i32, 2) = (1, 2); return a[2]; }
// EX-SP-4 (today's syntax; accepted today and lowered UNCHECKED — stage 2 closes it)
fn RuntimeArr(i: i32) -> i32 { var a: array(i32, 2) = (1, 2); return a[i]; }
// EX-SP-5 (NEW): the only opt-out
fn Hot(s: Core.Slice(i32), i: i64) -> i32 { return unsafe s.GetUnchecked(i); }
// EX-SP-6 (today's syntax; today `x / y` with y == 0 is emitted unguarded — stage 2 makes it fail-stop)
fn Div(x: i32, y: i32) -> i32 { return x / y; }
```

What each example shows:

-   **EX-SP-1 (SP2, the slice check).** Every `s[i]` reaches `Slice.Get`
    through the `final impl ... as IndexWith(i64)` (slice.carbon:74-77) and is
    checked against `s.Size()`; the loop's own test makes every access in
    range, so the program runs to completion in every mode, and the check it
    performs costs one compare per element. The subscript is `i64` because
    only an integer literal converts implicitly (W-116). Outcome: ACCEPTS; the
    read-through-a-view shape is
    fork/conformance/programs/stdlib/slices_basic.carbon and the check it
    passes through is the one EX-SP-2 fails.
-   **EX-SP-2 (SP2, the violation).** `RuntimeSeed(-18)` is 2 at run time, so
    the subscript is index 2 of a two-element view and `Get` takes the fail
    branch before any output: one line, "carbon: Core.Slice index out of
    bounds; terminating", then `abort()`. The `Core.Print` after the read is
    never reached. Outcome: ACCEPTS, and the run fails-stop: the program is
    fork/conformance/programs/stdlib/slices_bounds_fail_stop.carbon with
    `EXPECT-EXIT: -6` (death by `SIGABRT`, which the runner reports as −6),
    and the check is slice.carbon:39-44. Identical in Strict, Permissive,
    Release and Debug.
-   **EX-SP-3 (SP2, a constant array index).** The index is a constant, so
    constant evaluation checks it against the array's bound and rejects the
    program. Outcome: REJECTS; the nightly exits 1 with "error: array index
    `2` is past the end of type `array(i32, 2)`", the `ArrayIndexOutOfBounds`
    of eval.cpp:1080-1116, pinned by
    toolchain/check/testdata/index/fail_array_out_of_bound_access.carbon.
-   **EX-SP-4 (SP2, a run-time array index).** The index is a parameter, so
    constant evaluation has nothing to check, and the lowering emits an
    `inbounds` GEP with no compare (lower/handle.cpp:47-74): `RuntimeArr(2)`
    reads past the array today. Outcome: ACCEPTS-UNCHECKED; the nightly exits
    0 with no diagnostic. Stage 2 (W-130) closes it: `ArrayIndex` emits the
    compare-and-`fail_stop` sequence of `Slice.Get` with the message "carbon:
    array index out of bounds; terminating", and the subscript goes through
    `IndexWith(i64)`, so the `i32` parameter is converted at the subscript
    rather than being the subscript type.
-   **EX-SP-5 (SP4, the opt-out).** `GetUnchecked` is an `unsafe fn`, so the
    call carries the `unsafe` prefix in Strict and the obligation `0 <= i <
    Size()` is `Hot`'s caller's; in Permissive the same call is written
    without the keyword. The view's loan is unchanged by the accessor. Outcome:
    NEW-SYNTAX; no accessor exists in slice.carbon and no `unsafe fn` modifier
    exists in the toolchain. Stage 1 parses the call spelling and W-128 adds
    the accessor.
-   **EX-SP-6 (D-SAFE-15, division by zero).** `Div(1, 0)` reaches an
    unguarded `sdiv` today (handle_call.cpp:188-192). Outcome:
    ACCEPTS-UNCHECKED; the nightly exits 0 with no diagnostic. Stage 2 (W-130)
    emits the guard, after which `Div(1, 0)` fails-stop with "carbon: division
    by zero; terminating" in every mode, and a `Div` of the least `i32` by
    −1, the overflowing division, wraps in Release and fails-stop in Debug.

The checklist rows this page owns, in the checklist's own vocabulary:

| Rule | Example | Today | Evidence | Stage |
| --- | --- | --- | --- | --- |
| SP2 slice check | EX-SP-1, EX-SP-2 | ACCEPTS | stdlib/slices_bounds_fail_stop.carbon EXPECT-EXIT −6; slice.carbon:39-44 | — |
| SP2 constant array | EX-SP-3 | REJECTS | eval.cpp:1080-1116 `ArrayIndexOutOfBounds` | — |
| SP2 runtime array | EX-SP-4 | ACCEPTS-UNCHECKED | lower/handle.cpp:47-74 | 2 (W-130) |
| SP4 unchecked | EX-SP-5 | NEW-SYNTAX | slice.carbon (no accessor) | 1 + W-128 |
| D-SAFE-15 division | EX-SP-6 | ACCEPTS-UNCHECKED | handle_call.cpp:188-192 | 2 (W-130) |

SP1 and SP3 carry no row of their own: SP1 is the pointer design as it stands,
and SP3's examples are the temporal page's `FromArray` and `AsSlice` programs
(EX-TM-3, EX-TM-4 and the `Launder` set of EX-TM-8), whose outcomes are stated
there.

## C++ interop consequence

C++ is Permissive Carbon (D-SAFE-18): C++ code is trusted to meet its declared
contracts, and no C++ access is re-checked. For spatial safety that has these
consequences:

-   **View types gain the Carbon-side check at no C++ cost.** `std::span<T>` and
    `std::string_view` map to `Core.Slice(T)` and `Core.String`
    ([Slices: interop](../slices.md#interop); the design overview's interop
    section names the string type `Core.Str`, the same type under the interop
    design's name, and the safety pages use the prelude's `Core.String`). Every
    read through the Carbon view is checked by SP2, and the C++ side is
    unchanged: the view's layout is the C++ view's, no thunk inserts a check,
    and a C++ caller that reads the same memory through its own `span` does so
    under C++'s rules. A C++ function taking `std::span<T>` or `std::span<const
    T>` is the fourth shape of the strategy's
    [C++ call allowlist](README.md#c-call-allowlist): when the Carbon argument
    is a loan-carrying `Core.Slice` whose extent the Carbon side has
    established, the call needs no marker in Strict, because the callee receives
    exactly that extent. The owning-container conversion, a `std::vector<int>`
    viewed as `Core.Slice(const i32)` through the prelude's synthesized
    `CppContiguousRange` witness (slice.carbon:100-106), is trusted prelude code
    and produces a view that SP2 checks like any other.
-   **A raw pointer-plus-length API is one `unsafe` per site.** A C++ function
    that returns `T*` plus a count, or a `data()` that is not reachable through
    the witness, yields a pointer with no arithmetic on it (SP1); turning it
    into something indexable is `unsafe Core.Slice(T).Make(p, n)`, and that
    line is the single audit line of a migrated buffer API: the obligation it
    takes on is that `p` names at least `n` valid elements that outlive the
    view, the view is free under rule T6 of the temporal page because the
    marker took on that lifetime, every access through the view is checked
    from then on, and the
    search for `unsafe` finds the one place where the length was asserted
    rather than proven. Permissive removes only the keyword from that line,
    never the check that follows it.
-   **C++ arrays and out-parameters.** A C++ `T[4]` maps to `array(T, 4)`
    ([bidirectional interoperability](../README.md#bidirectional-interoperability-with-c-and-c))
    and is subscripted under SP2; a C++ parameter `T* out` with a length
    convention is the raw pointer case above. A Carbon `array(T, N)` passed to
    C++ as a pointer decays on the C++ side, under C++'s rules.
-   **C++'s own accesses are C++'s business.** An out-of-range `operator[]`
    inside a C++ function, a `reinterpret_cast` that widens a view, or pointer
    arithmetic that walks off a buffer is a bug of the C++ code the soundness
    model trusts; Carbon does not re-check it, and the hardened standard
    library modes a C++ toolchain offers are the C++ side's option, not a
    Strict guarantee (SP5). A pointer returned by such code into Carbon is
    unverified (T6), and its dereference is the type page's `unsafe *p`.
-   **Division.** A division inside a C++ function is C++ arithmetic and is
    not guarded; a division in Carbon code is guarded at the Carbon operation
    in every mode, so a migrated expression gains the guard the moment it is
    rewritten in Carbon and not before.

The migration ladder for a C++ API that takes pointers is the one on the
strategy page, [C++ migration example](README.md#c-migration-example); for a
buffer API the glue file's body is where the pointer-plus-length call becomes
one `unsafe Core.Slice(T).Make(p, n)` behind a signature that takes or returns
a `Core.Slice`, after which every Strict caller indexes a checked view.

## Implementation staging

The design lands in the stages fixed by D-SAFE-21 and listed on the strategy
page under [Implementation staging](README.md#implementation-staging). 0.1
claims no executable behavior from this page beyond what the slices design
already claims: the `Core.Slice` and `Core.Buf` checks are live, and nothing
else on this page is. The rows this page owns:

| Stage | Contents | Owned here |
| --- | --- | --- |
| 0 (this PR) | This page; no toolchain change | All of this page; the dated amendments on the [slices](../slices.md) and [arithmetic](../expressions/arithmetic.md) pages |
| 1 | Lex and parse `unsafe fn` and the `unsafe` prefix forms, recorded in SemIR, unenforced | EX-SP-5's call spelling parses; the prelude churn W-128 is gated here: `unsafe fn GetUnchecked[bound self: Self](i: i64) -> T` on `Slice` and `Buf`, `bound p` on `FromArray`, `bound self` on every view producer and on `IndexWith.At` and `Copy.Op`, `UnsafeMake` renamed to `unsafe fn Make` |
| 2 | Runtime hardening regardless of mode: array index fail-stop, division by zero fail-stop, `--build-mode=debug\|release`, Release zero-fill | `ArrayIndex` lowered as compare-and-`fail_stop` with "carbon: array index out of bounds; terminating", array subscripts through `IndexWith(i64)` (absorbing W-116); the division and remainder guard with "carbon: division by zero; terminating"; Debug overflow fail-stop; residue item W-130 |
| 3 | Strict static checks without loan sets; `--strict-checks=warn` default | `StrictBuiltinBindingUnmarked` for a builtin binding outside the prelude (SP1; residue item W-131); an unmarked `GetUnchecked` call is the type page's `StrictUnsafeCallUnmarked` |
| 4 | The loan checker | SP3 enforced: the `bound` loans of the view producers and the ⊥ result of `unsafe fn Make`, under the temporal page's rules |

Stages 5 and 6 own nothing on this page.

## Decisions within this design

Each decision below is a sub-decision of fork decision F-013, recorded with
its break condition in [fork/decision-log.md](/fork/decision-log.md); the
strategy page carries D-SAFE-1 to D-SAFE-6, D-SAFE-18 and D-SAFE-21, and the
other category pages carry the rest.

-   **D-SAFE-14 — Spatial: fail-stop everywhere, `unsafe fn` is the opt-out,
    views carry loans.** SP1 no arithmetic, `pointer.offset` bound by the
    prelude and by an `unsafe fn` anywhere else.
    SP2 every element access through `array(T, N)`, `Core.Slice(T)` and
    `Core.Buf(T)` is bounds-checked and a violation fails-stop in every build
    mode, D-SL-4 retained as the Release baseline; the array gap, constant
    indices rejected at compile time and run-time indices lowered unchecked,
    is a stage-2 lowering residue in which `ArrayIndex` emits the
    compare-and-`fail_stop` sequence of `Slice.Get` and array subscripts go
    through `IndexWith(i64)`. SP3 views carry their length and a loan:
    `FromArray` takes `bound p`, every producer whose result views `self`'s
    storage takes `bound self`, and the W-128 audit rule reviews every prelude
    signature as if its body were Strict-checked, marking `bound` or `unsafe
    fn`, with `bound self` on the interface declarations `IndexWith.At` and
    `Copy.Op` so that impls may keep it; `UnsafeMake` becomes `unsafe fn
    Make(p: T*, size: i64)` with its existing comment as the stated
    obligation; the prelude churn is the named residue item W-128, gated, and
    never assumed in an example. SP4 unchecked access is `unsafe fn
    GetUnchecked[bound self: Self](i: i64) -> T` on `Slice` and `Buf`; no build
    flag disables checks, and the strategy's promise of an unsupported disable
    for benchmarking is withdrawn by the fork, dated. SP5 hardening extensions
    carry no Strict guarantee. The fail-stop message text stays fixed (W-113)
    so that `fail_stop` needs no formatting runtime. Break condition: none for
    the semantics; the unchecked accessor's name is the residue item's.
-   **D-SAFE-15 — Arithmetic.** Release: signed overflow wraps, the existing
    lowering made normative, and signed or unsigned division or remainder by
    zero fails-stop, a NEW guard before the division instruction at stage 2.
    Debug: overflow fails-stop with a diagnostic. Compile-time overflow is
    already rejected. The arithmetic design's "performance build ... not
    defined" row is withdrawn for Carbon code, because proposal p005914
    forbids undefined behavior in safe code and bounds checks make overflow a
    logic bug rather than a memory bug; its open question is answered with
    wrap, not zero. Break condition: a real-world benchmark of the class
    p005914 names where the loss of `nsw` exceeds 0.5 percent, an owner call on
    a performance-build opt-in.

## Alternatives considered

The design was chosen by a panel of three attempts and two judges, recorded in
[fork/safe/plan.md](/fork/safe/plan.md); the strategy page states the
synthesis. Four alternatives bear on this page:

-   **A build flag that disables the checks.** The strategy's
    [build modes](README.md#build-modes) section promised an unsupported way to
    disable the default hardening in release builds for benchmarking, and
    attempt C carried it as an `--unhardened` build flag beside its hardened
    runtime core. The synthesis withdraws it (D-SAFE-14, review fold A-13(c) in
    [fork/safe/plan.md](/fork/safe/plan.md)) for two reasons. A flag moves the
    disable from the site to the build configuration, so no search of the source
    finds where the check was removed, which is the audit property the whole
    design rests on ([Safe and unsafe code](README.md#safe-and-unsafe-code));
    and a flag makes the matrix's fail-stop row depend on how the program was
    built, so a Permissive program's one spatial guarantee would no longer be
    identical in every mode. The per-site `unsafe fn GetUnchecked` keeps
    proposal p000196's disable "for performance-critical use cases" where the
    keyword is, and a benchmark that wants the unchecked build measures the
    program with the accessor at its hot sites, which is also the program that
    would ship.
-   **Mode-gated checks.** The slices design's 0.1 limits anticipated that the
    unchecked read would arrive with build modes, "the check becomes
    mode-gated", and the toolchain's one mode adopted the Debug build's promise
    as a stopgap (D-SL-4). The synthesis keeps the stopgap as the rule: the
    check is the Release baseline the strategy already requires, Debug adds
    nothing to it, and the opt-out is an accessor, so the arrival of build
    modes at stage 2 changes the behavior of overflow and of unformed reads
    but not of a bounds violation.
-   **Attempt C's ratchet.** Attempt C's thesis was a hardened runtime core
    first, fail-stop bounds, zero-fill and division-by-zero fail-stop as the
    0.1 deliverable, with annotated borrows later. Judge 1 found that C "is
    not a candidate base: its 0.1 scope leaves temporal/mutation
    'provisional-with-syntax'", and judge 2 found its stage-1 temporal claim
    unsound against `Core.Slice`, the scope-escaping `FromArray` being one of
    the counterexamples; both grafted its runtime core, which is stage 2 of
    the staging, and its arithmetic answer with W-113's fixed message text,
    which is D-SAFE-15. What this page keeps from C is therefore its runtime
    content and its rollout posture, not its claim that the runtime core alone
    is a safety guarantee: SP3's loans, enforced at stage 4, are what make the
    bounds check a check against live storage.
-   **Zero on overflow.** The arithmetic design's open question offered zero as
    a hardened-build result because it "may defeat some classes of exploit".
    Rejected: with bounds checks in place an overflowed index cannot reach
    memory, so the exploit class the zero was defending against does not
    arise, and zero costs code size and performance on every operation where
    wrap costs nothing, being the hardware result. Debug traps instead, which
    is the diagnostic a programmer wants from an overflow bug.

That decision is final; this page specifies the chosen design rather than
relitigating it.

## External facts

Claims about tools outside this repository appear on the safety pages only in
an "External facts" section with a status column (D-SAFE-22). No normative
rule on this page depends on an UNVERIFIED item: the division guard is
required by proposal p005914's prohibition of undefined behavior in safe code
whatever the LLVM instruction's semantics are, and the cost figure only
motivates a check the strategy already requires.

| Fact | Used by | Status |
| --- | --- | --- |
| LLVM's `sdiv`, `srem`, `udiv` and `urem` instructions have undefined behavior when the divisor is zero, so an unguarded Carbon division is undefined behavior at the LLVM level today | The motivation for the stage-2 division guard; the "emitted unguarded" wording in the [Overview](#overview) | UNVERIFIED: we expect this from the LLVM language reference; the writer has not checked the reference for this page, and the guard is required regardless |
| The run-time cost of bounds checking in a hardened standard library is small enough that production deployments enable it by default, the figure the strategy's evidence link reports | The expectation in SP2 that the check is cheap; no rule depends on the figure | UNVERIFIED: we expect the figure to be below one percent on typical workloads, as the linked account reports; the fork's own measurement is what D-SAFE-15's 0.5 percent break condition reads |
| Death by `SIGABRT` is reported by the conformance runner as exit status −6 | The EXPECT-EXIT of EX-SP-2 | VERIFIED: fork/conformance/runner.py returns the subprocess return code unmodified and Python reports death by signal N as −N; the program's own header states it and the scoreboard passes |

## References

-   [Safety strategy](README.md): [Soundness model](README.md#soundness-model),
    [Safety modes](README.md#safety-modes),
    [What each mode diagnoses](README.md#what-each-mode-diagnoses),
    [Build modes](README.md#build-modes) and the
    [C++ call allowlist](README.md#c-call-allowlist)
-   [Safety terminology: spatial safety](terminology.md#spatial-safety) and
    [fail-stop](terminology.md#fail-stop)
-   [Slices](../slices.md): [forming a view](../slices.md#forming-a-view),
    [bounds behavior](../slices.md#bounds-behavior),
    [interop](../slices.md#interop) and [0.1 limits](../slices.md#01-limits)
-   [Arithmetic: overflow and other error conditions](../expressions/arithmetic.md#overflow-and-other-error-conditions)
    and [Indexing](../expressions/indexing.md)
-   The design overview's [pointer types](../README.md#pointer-types) and
    [bidirectional interoperability](../README.md#bidirectional-interoperability-with-c-and-c)
    sections
-   [Type safety](type_safety.md) (`unsafe fn` and the call spelling) and
    [Temporal safety](temporal_safety.md) (loans, `bound`, T2 and T6, the
    `Launder` regression set)
-   Proposal
    [p000196: Language-level safety strategy](/proposals/p000196-language-level-safety-strategy.md)
-   Proposal
    [p005434: `ref` parameters, arguments, returns and `val` returns](/proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md)
-   Proposal
    [p005914: Updating Carbon's safety strategy](/proposals/p005914-updating-carbon-s-safety-strategy.md)
-   Fork decision [F-013](/fork/decision-log.md) and the synthesized plan
    [fork/safe/plan.md](/fork/safe/plan.md), whose design-panel record is the
    option paper for this area; fork decision D-SL-4 in the same log, and the
    residue items W-113, W-114, W-116, W-128 and W-130 in
    [fork/inventory/work-items.json](/fork/inventory/work-items.json)
-   The conformance programs
    fork/conformance/programs/stdlib/slices_basic.carbon and
    fork/conformance/programs/stdlib/slices_bounds_fail_stop.carbon, the
    prelude files core/prelude/types/slice.carbon and buf.carbon, and the
    toolchain test
    toolchain/check/testdata/index/fail_array_out_of_bound_access.carbon
