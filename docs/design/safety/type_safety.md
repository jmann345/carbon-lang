# Type safety

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Rules](#rules)
    -   [TY1: declared-type access and the unsafe operations](#ty1-declared-type-access-and-the-unsafe-operations)
    -   [TY2: `unsafe fn` and the call spelling](#ty2-unsafe-fn-and-the-call-spelling)
    -   [TY3: template parameters never weaken TY1](#ty3-template-parameters-never-weaken-ty1)
    -   [TY4: null is never a hole](#ty4-null-is-never-a-hole)
-   [Diagnostics](#diagnostics)
-   [Worked examples](#worked-examples)
-   [C++ interop consequence](#c-interop-consequence)
-   [Implementation staging](#implementation-staging)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [External facts](#external-facts)
-   [References](#references)

<!-- tocstop -->

## Overview

[Type safety] is the property that memory is accessed and interpreted according
to its intended type. In Carbon it is a static property of the type system:
every value is accessed only at its declared type, every conversion goes through
one of the three conversion interfaces, and the operations that can break the
property are enumerated and each is an `unsafe` operation in Strict Carbon.
This page owns that enumeration, the `unsafe fn` callee contract and its call
spelling, the rule that `template` parameters never weaken the property, and
the rule that a pointer is never null. The [safety strategy](README.md) states
the [soundness model](README.md#soundness-model) these rules are checked under
and the [safety modes](README.md#safety-modes) that decide where the `unsafe`
keyword is required; the [temporal safety](temporal_safety.md) page defines the
pointer kinds, loans and the _unverified_ loan set ⊥ that this page uses.

[type safety]: /docs/design/safety/terminology.md#type-safety

This page was fixed by fork decision [F-013](/fork/decision-log.md),
sub-decisions D-SAFE-4, D-SAFE-5 and D-SAFE-20, synthesized in
[fork/safe/plan.md](/fork/safe/plan.md). No part of this page is implemented in
the toolchain (fork workstream SAFE-1, stage 0); see
[Implementation staging](#implementation-staging). The one type-unsafe
operation the toolchain spells today is `unsafe as`: it is checked as
`ExplicitUnsafeAs` (toolchain/check/convert.h), diagnosed in
toolchain/check/testdata/as/unsafe_as.carbon and lowered in
toolchain/lower/testdata/pointer/convert.carbon, and the fork's
fork/conformance/programs/project/safety_strategy_doc.carbon runs it. Every
other spelling on this page is NEW syntax, marked as such. File and line
citations are against trunk 0bdce60a5 unless a citation says otherwise.

## Rules

### TY1: declared-type access and the unsafe operations

Values are accessed only at their declared type. Conversions go through
`Core.ImplicitAs`, `Core.As` and `Core.UnsafeAs`
(core/prelude/operators/as.carbon:12-34), in that order of strength: an implicit
conversion is also an explicit one, and an explicit one is also an unsafe one.
The rule is unchanged from the
[as expressions](../expressions/as_expressions.md) and
[implicit conversions](../expressions/implicit_conversions.md) designs; what
this page adds is the closed list of operations that can break it. Each is an
`unsafe` operation in Strict Carbon (D-SAFE-5), spelled with the uniform
`unsafe` expression prefix the strategy page defines under
[Operation-tied `unsafe`](README.md#operation-tied-unsafe):

| Operation | Today | Strict spelling | Mechanism |
| --- | --- | --- | --- |
| Pointer reinterpretation, `T*` to `U*` | `p unsafe as U*` exists: `impl forall [T: type, U: type] T* as UnsafeAs(U*)` over the `pointer.unsafe_convert` builtin (as.carbon:61-65) | `p unsafe as U*`, required in both modes | `Core.UnsafeAs`; the obligation is that a valid, complete object of `U` lives at the address for the loan's lifetime, extent included, and the result keeps the operand's loan set |
| `const` removal, `const T*` to `T*` | `unsafe as` is the only cast that discards `const` (toolchain/check/convert.cpp:1843-1846), which answers the TODO at as.carbon:62 | `p unsafe as T*`, required in both modes | `Core.UnsafeAs`; `const` keeps its API-subsetting meaning from [`const`-qualified types](../values.md#const-qualified-types), so the obligation is only that the object is not one whose storage may not be written |
| Integer-to-pointer conversion | No prelude impl provides it (as.carbon has no `UnsafeAs(T*)` impl on an integer type) | `n unsafe as T*` (NEW impl), the result unverified (⊥) | `Core.UnsafeAs`; the result's loan set is ⊥, so using it is the unverified-dereference operation below |
| Union field read | `u.f` with no marker: the Permissive behavior unions.md ships in 0.1 ([Strict Carbon and future safety hooks](../unions.md#strict-carbon-and-future-safety-hooks)) | `unsafe u.f` (NEW spelling); writes need no marker | Defined byte reinterpretation, never undefined behavior ([Reads](../unions.md#reads)); the marker discharges the punning obligation only, and a pointer-carrying value read this way is ⊥ |
| Address of a union field | `&u.f` with no marker | `unsafe &u.f` (NEW spelling) | A deferred read: the pointer is ⊥ on formation for every field type, because a pointer into a union aliases every field of it (unions.md:440-441), so `*s` of such a pointer needs `unsafe *s` |
| Deletion through a non-`Deletable` base | `Allocator.UnsafeDelete` and the `UnsafeAllowDelete` adapter ([classes](../classes.md#destructors), the `Allocator` sketch) | `unsafe alloc.UnsafeDelete(p)`: `UnsafeDelete` becomes an `unsafe fn` (D-SAFE-20) | TY2; the obligation is the one the classes design states, that `p` does not point at a value of a derived type |
| Downcast, `Base*` to `Derived*` | `p unsafe as Derived*`, a pointer reinterpretation | `p unsafe as Derived*` stays the unchecked form; `Core.DynCast(Derived*)(p) -> Core.Optional(Derived*)` is the checked form (D-SAFE-20, NEW, stage 6) | `Core.DynCast` consults the vtable of a `Deletable` class and returns `.None` on a mismatch, so it needs no marker |
| Dereference of an unverified pointer | `*p` and `p->m` with no marker | `unsafe *p` and `unsafe p->m` (NEW spelling) | T6 of the temporal page: the obligation is that the storage outlives every use derived from the dereference |

The set of unsafe operations is identical in both modes. Permissive differs
only in not requiring the keyword at three of them, the union field read, the
unverified dereference and the `unsafe fn` call, which are the "assumed fact"
rows of [What each mode diagnoses](README.md#what-each-mode-diagnoses); `unsafe
as` keeps its keyword in both modes because the toolchain enforces it today in
unmarked files and Permissive's omissions are limited to C++-interop and
migration patterns. Consequently an audit is a search for the keyword: in
Strict files it finds every type-unsafe operation outside the prelude, whose
synthesized C++ witnesses are trusted prelude code (D-SAFE-18), and `unsafe
permissive` finds the units where the search is not exhaustive.

The `unsafe as` obligation between pointer types includes _extent_: a valid,
complete object of the destination type lives at the address for the loan's
lifetime. `(&x) unsafe as i64*` for an `x: i32` is therefore the caster's bug
and not a checker hole. What `unsafe as` never does is extend a lifetime: it
preserves the loan set of its operand, so a converted pointer is exactly as
verified as the pointer it was converted from, and the strategy's narrowness
principle that an unsafe type conversion does not also allow out-of-lifetime
access ([Safe and unsafe code](README.md#safe-and-unsafe-code)) holds by
construction. The dereference of a pointer whose loan set is ⊥ is a separate
operation with a separate marker, which is what EX-TY-3 shows.

### TY2: `unsafe fn` and the call spelling

`unsafe fn F(...)` declares that _calling_ `F` carries an obligation the
checker cannot discharge (D-SAFE-4). In Strict every call of it is spelled
`unsafe F(args)` or `unsafe x.M(args)`; a subscript whose `[]` resolves to an
`unsafe fn` is spelled `unsafe s[i]`, and an infix or assignment operator that
resolves to one is spelled with the parenthesized form, `unsafe (a + b)` or
`unsafe (c = 42)`. The prefix applies to the innermost call, dereference,
subscript or field read that follows the keyword, and `unsafe (` widens it to
the parenthesized expression's outermost operator application; the strategy
page states the parse rule once under
[Operation-tied `unsafe`](README.md#operation-tied-unsafe). An unmarked call is
`StrictUnsafeCallUnmarked`.

The callee contract and the body mode are different things. The body of an
`unsafe fn` is checked in its file's mode, so marking a callee never un-checks
its body; `unsafe permissive fn` is the body-mode marker, a Permissive body that
is safe to call and never colors its callers. The two compose as `unsafe fn` on
the declaration plus `unsafe permissive` on the definition. An `unsafe fn`
states its obligation in its doc comment, and that sentence is the contract a
caller discharges by writing `unsafe`: for `Core.Slice(T).Make` it is the
sentence core/prelude/types/slice.carbon:29-30 already carries for
`UnsafeMake`, "the caller guarantees that `p` names at least `size` valid
elements that outlive the view". The result of an `unsafe fn` call is an
unverified value when it is a pointer or carries one (T6), so a wrapper that
returns such a result to Strict code must either be `unsafe fn` itself or
carry a `bound` parameter that gives the result a loan set
([temporal safety](temporal_safety.md)).

The prelude's `Unsafe`-prefixed functions are the first `unsafe fn`s:
`Core.Slice(T).UnsafeMake` becomes `unsafe fn Make(p: T*, size: i64) -> Self`,
`Core.Slice(T).GetUnchecked` and `Core.Buf(T).GetUnchecked` are declared
`unsafe fn` from the start ([spatial safety](spatial_safety.md)), and
`Allocator.UnsafeDelete` and the `UnsafeAllowDelete` adapter's constructor
become `unsafe fn` (D-SAFE-20). That prelude churn is the residue item W-128,
gated on stage 1, and no example on this page assumes it has landed.

### TY3: template parameters never weaken TY1

A `template` parameter ([templates](../templates.md);
[checked versus template parameters](../generics/terminology.md#checked-versus-template-parameters))
defers type checking of the operations that use it to instantiation; it never
removes that checking. Every operation in an instantiated body is type-checked
against the instantiating type exactly as it would be in a non-generic
function, so a template body contains a type-unsafe operation only where it
spells one, and the spelling is the same `unsafe` form the operation needs
outside a template. In particular, a template instantiated with a pointer type
cannot reinterpret through it without `unsafe as`, and a template whose body
calls an `unsafe fn` carries the `unsafe` at the call in the template's own
text, not at each instantiation. Checked generics are stronger still: their
bodies are type-checked once against the constraint, before any instantiation.
Neither kind of parameter is an escape from TY1, which is why type safety is
"the same as other statically typed languages with generic type systems"
([Memory safety model](README.md#memory-safety-model)).

### TY4: null is never a hole

There are no null pointers in Carbon
([pointer types](../README.md#pointer-types)): `T*` always refers to an object,
and a pointer that may not refer to one is `Core.Optional(T*)`, whose `.None`
state uses the null representation (core/prelude/types/optional.carbon:186-203,
the `OptionalStorage` impl for `T*`). A dereference of a `T*` is therefore never
a null dereference, and the only way to reach the pointee of an `Optional(T*)`
is through `Get` after `HasValue`, a `match`, or the `?` form of the error
handling design. The C++ importer honors `_Nonnull`: a C++ pointer declared
`_Nonnull` imports as `T*` and every other C++ object pointer imports as
`Core.Optional(T*)` (toolchain/check/cpp/import.cpp:1462-1509,
`IsClangTypeNonNull` and `MapObjectPointerType`), so the rule holds across the
boundary without a marker. A null value smuggled through `unsafe as` from an
integer, or read from a union field, is an unverified pointer by TY1, and its
dereference needs `unsafe *p` in Strict; that marker is the only place a null
can be dereferenced, and the obligation it states is violated.

## Diagnostics

The rows below are copied from the one matrix on the strategy page,
[What each mode diagnoses](README.md#what-each-mode-diagnoses); each is a
stage-3 diagnostic under `--strict-checks=warn` and an error from stage 4.

| Diagnostic | Strict | Permissive | Debug runtime |
| --- | --- | --- | --- |
| `StrictUnsafeCallUnmarked` | error | none — assumed fact | — |
| `StrictUnionReadUnmarked` | error | none — assumed fact | — |
| `StrictUnverifiedDeref` (shared with [temporal safety](temporal_safety.md)) | error | none — assumed fact | ASan-class detection ([Build modes](README.md#build-modes)) |
| missing `unsafe` before `as` (existing `ConversionFailure`-class error) | error | error | — |

Message texts:

-   `StrictUnsafeCallUnmarked`: "call to `unsafe fn` {0} requires `unsafe` in
    Strict Carbon", with a note at the callee's declaration quoting its stated
    obligation.
-   `StrictUnionReadUnmarked`: "read of union field `{0}` requires `unsafe` in
    Strict Carbon", on the field read or the `&u.f` that defers it; the note
    says that writes need no marker.
-   `StrictUnverifiedDeref`: "dereference of unverified pointer `{0}` requires
    `unsafe` in Strict Carbon", with a note at the operation that made the
    pointer unverified: the `unsafe as`, the `unsafe fn` or C++ call, the union
    read, or the `unsafe class` field.
-   The missing `unsafe` before `as` is today's error: "cannot convert
    expression of type `const X*` to `X*` with `as`" with the note that the
    type does not implement `Core.As(X*)`, from
    toolchain/check/testdata/as/const.carbon's `fail_cannot_remove_const`
    case (`ptr as X*` for a `const X*`); it is unchanged by this design and
    is emitted in both modes.

The three `Strict` diagnostics have no Permissive twin, warning or otherwise:
in a Permissive unit the three operations are assumed facts, not downgraded
ones, which is what lets a migrated file compile before a single marker is
written. A Permissive file's Strict-readiness for this category is measured by
compiling it with the mode flipped, which is the file rung of the migration
ladder on the strategy page.

## Worked examples

Each rule carries the example the design-conformance checklist
(fork/safe/plan.md §4.1) assigns to it, with the outcome the checklist states
against the 0.1 toolchain. EX-TY-1 is today's syntax and was compiled on the
nightly 2026.10.12 toolchain with exit status 0 for this page, with no
`package` line and with `import Core library "io";` prepended for
`Core.Print`; the rest are NEW syntax that no toolchain parses, each with the
stage that will.

```carbon
// EX-TY-1 (today's syntax; runs today — the body of safety_strategy_doc.carbon:19-28)
fn Run() -> i32 {
  var x: i32 = 42;
  let p: i32* = &x;
  let q: i32* = p unsafe as i32*;
  Core.Print(*q);
  if (*q != 42) { return 1; }
  return 0;
}
// EX-TY-2 (NEW): union read is the unsafe operation; writes are safe
union U { var i: i32; var f: f32; }
fn ReadU() -> i32 {
  var u: U = {.i = 1};
  let a: i32 = unsafe u.i;      // Strict: marker required; Permissive: `u.i`
  let s: i32* = unsafe &u.i;    // address of a union field: a deferred read, and s is a ⊥ pointer (T6, RR-1) — `*s` needs `unsafe *s`
  return a;
}
// EX-TY-3 (NEW): a converted pointer is unverified; its dereference is the audit point
fn Deref(p: i32*) -> i32 {
  let q: i32* = p unsafe as i32*;   // type obligation, extent included (A-14); never a lifetime (README.md:83-87)
  return unsafe *q;                  // temporal obligation, spelled separately (p is a P2 parameter: ⊥ only if its source was)
}
// EX-TY-4 (NEW): unsafe fn and its call; checked downcast
unsafe fn Make(p: T*, size: i64) -> Self;        // on Core.Slice(T), residue W-128
let v: Core.Slice(i32) = unsafe Core.Slice(i32).Make(raw, n);
let d: Optional(Derived*) = Core.DynCast(Derived*)(b);   // safe; `b unsafe as Derived*` is unchecked
```

What each example shows:

-   **EX-TY-1 (TY1, `unsafe as`).** The conversion carries its keyword at the
    operation, which is narrowness principle 3 of the strategy live in the
    toolchain. `q` has the same loan set as `p`, a P1 loan on the local `x`,
    so `*q` needs no marker in either mode: the type obligation was the only
    one taken on. Outcome: ACCEPTS, with output `42`.
-   **EX-TY-2 (TY1, union read).** The write `{.i = 1}` and any later `u.f =
    ...` need no marker. The read `unsafe u.i` discharges the punning
    obligation and nothing else; the read rule is the same defined byte
    reinterpretation in both modes, only the spelling differs. `unsafe &u.i`
    produces a pointer that is ⊥ on formation, so the deferred read `*s` is
    the unverified-dereference operation and is spelled `unsafe *s`. Outcome:
    NEW-SYNTAX, stages 1 and 3; the Permissive read `u.i` ACCEPTS today, the
    fork's `union` being proven by
    fork/conformance/programs/types/union_basic.carbon.
-   **EX-TY-3 (TY1, unverified dereference).** Two obligations, two markers.
    `p unsafe as i32*` takes on the type obligation, extent included, and
    never a lifetime: `q` inherits `p`'s loan set. `p` is a P2 parameter
    whose loan set is ⊥ only when its source was, so in the body as written
    `unsafe *q` states the temporal obligation that the storage outlives the
    use; a caller that passed a verified pointer took on nothing new. Outcome:
    NEW-SYNTAX, stages 1 and 3; today the parser accepts `unsafe` only before
    `as` and rejects every other operator with `ModifierNotAllowedOnOperator`
    (toolchain/parse/handle_expr.cpp:391-399).
-   **EX-TY-4 (TY2 and D-SAFE-20).** `Make` is unsafe to call and its body is
    checked in the prelude file's mode; the call is spelled with the prefix,
    and `v` is an unverified view until the obligation in `Make`'s doc comment
    is the caller's. `Core.DynCast(Derived*)(b)` is the checked downcast and
    needs no marker; `b unsafe as Derived*` remains the unchecked one.
    Outcome: NEW-SYNTAX, stages 1 and 3 for `unsafe fn` and its call (no
    `unsafe fn` modifier exists: toolchain/lex/token_kind.def has `unsafe` as
    a keyword only for the `as` modifier), stage 6 for `Core.DynCast`, and
    W-128 for the prelude rename.
-   **TY4 (`Optional(T*)`).** The checklist's example is the prelude type
    itself. The shape below is today's syntax, taken from
    fork/conformance/programs/stdlib/optional_pointer_niche.carbon and
    compiled on the nightly 2026.10.12 toolchain for this page with exit
    status 0: the `.None` state is reached only through `HasValue`, the
    pointee only through `Get`, and no `unsafe` appears. Outcome: ACCEPTS;
    the importer side is import.cpp:1491-1509.

```carbon
// TY4 (today's syntax): the only way to reach a maybe-absent pointee is through Optional
fn DerefOr(o: Core.Optional(i32*), fallback: i32) -> i32 {
  if (o.HasValue()) {
    return *o.Get();
  }
  return fallback;
}
```

The checklist rows this page owns, in the checklist's own vocabulary:

| Rule | Example | Today | Evidence | Stage |
| --- | --- | --- | --- | --- |
| TY1 `unsafe as` | EX-TY-1 | ACCEPTS | safety_strategy_doc.carbon body; check/testdata/as/unsafe_as.carbon; lower/testdata/pointer/convert.carbon | — |
| TY1 union read | EX-TY-2 | NEW-SYNTAX (Permissive read ACCEPTS today: types/union_basic.carbon) | unions.md, [Strict Carbon and future safety hooks](../unions.md#strict-carbon-and-future-safety-hooks) | 1, 3 |
| TY1 unverified deref | EX-TY-3 | NEW-SYNTAX | handle_expr.cpp:391-399 | 1, 3 |
| TY2 `unsafe fn` | EX-TY-4 | NEW-SYNTAX | token_kind.def (no modifier) | 1, 3 |
| TY4 null | `Optional(T*)` | ACCEPTS | stdlib/optional_pointer_niche.carbon; import.cpp:1491-1509 | — |

The temporal page's regression program `Wild` (EX-TM-8) is the type-safety
case the strategy's narrowness principle names: a pointer read from a union
field after a write through another field is ⊥, and only `unsafe *q` can use
it, so the union read never launders a loan.

## C++ interop consequence

C++ is Permissive Carbon (D-SAFE-18): C++ code is trusted to meet its declared
contracts, and no C++ construct is re-checked. For type safety that has these
consequences:

-   **Casts stay on the C++ side.** A `reinterpret_cast`, a `static_cast` down
    a hierarchy or a C-style cast inside a C++ function is that function's
    business; its result reaches Carbon as a value of the declared return
    type. A pointer returned by C++ is unverified (T6), so a Strict body that
    dereferences it writes `unsafe *p`, and that marker is the audit point
    for the C++ cast as much as for the lifetime.
-   **Null is handled at the import.** A `_Nonnull` C++ pointer imports as `T*`;
    every other C++ object pointer imports as `Core.Optional(T*)`
    (import.cpp:1462-1509). TY4 therefore holds for imported signatures with no
    marker and no wrapper: a Strict caller of an unannotated C++ function
    returning `Widget*` receives an `Optional(Cpp.Widget*)` and tests it before
    use. C++ `T&` imports as `T*`
    ([bidirectional interoperability](../README.md#bidirectional-interoperability-with-c-and-c)),
    which is non-null by construction.
-   **The C++ allowlist needs no type-safety marker.** A call whose signature
    has one of the four shapes of the strategy's
    [C++ call allowlist](README.md#c-call-allowlist) carries no pointer the
    callee could reinterpret or save, so it needs no `unsafe` on this page's
    account either; everything else is `StrictCppCallUnannotated`, a temporal
    diagnostic, and its marked form `unsafe Cpp.F(...)` is the same prefix
    this page uses for an `unsafe fn` call.
-   **Imported operators are `unsafe fn` calls when their signatures are.** A
    C++ member `operator=`, `operator+` or `operator+=` whose signature
    involves a pointer, reference or `this` imports as an `unsafe fn`, and a
    Strict use of it is spelled with the parenthesized form: the `c = 42` of
    fork/conformance/programs/interop/cpp_operator_import_assignment.carbon:26
    is `unsafe (c = 42)`, the one marked site of fourteen the strategy page
    measures on the fork's interop corpus.
-   **C++ unions follow the union rule.** A C++ `union` imports with the
    semantics of [unions](../unions.md): writes unmarked, reads `unsafe u.f`
    in Strict and unmarked in Permissive, a pointer-typed field read ⊥. A
    migrated C++ union that puns a pointer against an integer and uses zero as
    a sentinel declares the field `Core.Optional(T*)`, as the unions page
    already directs, so TY4 holds for it too.
-   **`import Cpp` needs no marker.** The `Cpp.` prefix on every C++ name is
    the audit marker an `unsafe import` would duplicate; this is the named
    asymmetry the strategy page records under
    [Safety modes](README.md#safety-modes).
-   **C++ templates are TY3's case across the boundary.** A C++ template
    instantiated with a Carbon type is type-checked by Clang at instantiation;
    a type-unsafe operation inside it is C++ code and is trusted like any
    other C++ body.

The migration ladder for a C++ API that returns or takes pointers is the one on
the strategy page, [C++ migration example](README.md#c-migration-example):
a Permissive glue file, then a Strict caller of the glue behind `unsafe
import`, then a direct Strict call once the header carries annotations.

## Implementation staging

The design lands in the stages fixed by D-SAFE-21 and listed on the strategy
page under [Implementation staging](README.md#implementation-staging). 0.1
claims no executable behavior from this page: `unsafe as` behaves today exactly
as it did before, and no Strict program is accepted or rejected by the 0.1
toolchain. The rows this page owns:

| Stage | Contents | Owned here |
| --- | --- | --- |
| 0 (this PR) | This page; no toolchain change | All of this page |
| 1 | Lex and parse `unsafe fn`, the `unsafe` prefix forms (`unsafe F(args)`, `unsafe x.M(args)`, `unsafe *p`, `unsafe p->m`, `unsafe u.f`, `unsafe &u.f`, `unsafe s[i]`, `unsafe (...)`), recorded in SemIR and unenforced; `unsafe` before `as` keeps its one-token lookahead | EX-TY-2, EX-TY-3 and EX-TY-4 parse; safety_strategy_doc.carbon un-SKIPs with no body change; the prelude rename of `UnsafeMake` to `unsafe fn Make` and of `UnsafeDelete` (W-128) |
| 3 | Strict static checks without loan sets, `--strict-checks=warn` default | `StrictUnsafeCallUnmarked`, `StrictUnionReadUnmarked`, `StrictUnverifiedDeref` as warnings; the audit property that a Strict file's unmarked type-unsafe operations are exactly the diagnosed ones |
| 4 | The loan checker; `error` default | The same three as errors; `StrictUnverifiedDeref` gains the loan-set reasons the temporal page states (T6) |
| 6 | `bound(a)`, `Core.Lifetime`, `Core.DynCast`, the Rust binding generator | `Core.DynCast(Derived*)(p) -> Core.Optional(Derived*)` as the checked downcast; EX-TY-4's third line |

Stage 2 and stage 5 own nothing on this page.

## Decisions within this design

Each decision below is a sub-decision of fork decision F-013, recorded with
its break condition in [fork/decision-log.md](/fork/decision-log.md); the
strategy page carries D-SAFE-1 to D-SAFE-6, D-SAFE-18 and D-SAFE-21, and the
other category pages carry the rest.

-   **D-SAFE-4 — Callee contract and body mode are different things.** `unsafe
    fn F(...)` declares that calling `F` carries an obligation the checker
    cannot discharge, and in Strict every call is spelled with the prefix; the
    body of an `unsafe fn` is checked in its file's mode. `unsafe permissive
    fn` is the body-mode marker and never colors callers, which keeps the
    strategy's rule that safe and unsafe code are freely mixed (proposal
    p005914). Attempt C's conflation, an `unsafe fn` body being Permissive,
    is rejected. Break condition: a prelude function that needs both — the
    two modifiers compose as `unsafe fn` on the declaration plus `unsafe
    permissive` on the definition; if the parser cannot carry both, the body
    marker moves to a post-signature position without changing semantics.
-   **D-SAFE-5 — Operation-tied `unsafe` is a uniform expression prefix.** The
    forms are `p unsafe as T` (exists today), `unsafe F(args)` and `unsafe
    x.M(args)`, `unsafe *p` and `unsafe p->m`, `unsafe u.f` and `unsafe
    &u.f`, `unsafe s[i]`, and the parenthesized `unsafe (...)` for an operator
    that resolves to an `unsafe fn`; the prefix applies to the innermost
    operation that follows it. The strawman `s_value.unsafe
    RefMemberFunction()` in [values](../values.md) is superseded and carries a
    dated amendment saying so. Break condition: stage 1 finds the prefix
    ambiguous against `unsafe as` — it is not, since `unsafe` followed by `as`
    remains the infix modifier by the existing one-token lookahead
    (handle_expr.cpp:391-394) — then the spelling moves and the set of marked
    operations does not.
-   **D-SAFE-20 — Library surface, all residue, none in 0.1.** On this page:
    `Core.DynCast(Derived*)(p: Base*) -> Core.Optional(Derived*)`, the checked
    downcast through the vtable for `Deletable` classes, with `p unsafe as
    Derived*` as the unchecked one, which closes the strategy's inheritance
    divergence inside type safety; `UnsafeDelete` and `UnsafeAllowDelete`
    become `unsafe fn`. Break condition: none; each is a filed item with its
    own gate.

## Alternatives considered

The design was chosen by a panel of three attempts and two judges, recorded in
[fork/safe/plan.md](/fork/safe/plan.md); the strategy page states the
synthesis. Two alternatives bear on this page:

-   **Attempt A's member-position `.unsafe` form.** The [values](../values.md)
    design's strawman spells an unsafe member call as `s_value.unsafe
    RefMemberFunction()`, and attempt A kept that spelling. Judge 1 found
    (attempt A's R9) that the member-access path has no modifier hook: the
    parser's one generalization point is the trailing-operator path
    (handle_expr.cpp:335-340), so a member-position modifier would be a second
    mechanism for one keyword, and it gives no spelling at all to a
    dereference, a union read, a subscript or an operator. The uniform prefix
    covers every form with one parse rule and one audit pattern, and the
    values page carries a dated amendment pointing here.
-   **Attempt C's Permissive-body `unsafe fn`.** Attempt C made the body of an
    `unsafe fn` Permissive, so that one keyword both warned callers and
    un-checked the callee. Judge 1 found that fatal (item C): it conflates the
    callee contract with the body mode, so every prelude accessor that is
    unsafe to call would lose its own checking, and a Permissive body that is
    perfectly safe to call would have to be declared unsafe to call. D-SAFE-4
    keeps the two orthogonal.
-   **An `unsafe` region or block.** Rejected by the strategy's three narrowness
    principles ([Safe and unsafe code](README.md#safe-and-unsafe-code)): a
    region marks more than the minimal operation and is not separable from the
    safe code around it. `unsafe permissive fn` is the one body-granular marker,
    and it is a mode, not a region of trusted operations.

That decision is final; this page specifies the chosen design rather than
relitigating it.

## External facts

Claims about tools outside this repository appear on the safety pages only in
an "External facts" section with a status column (D-SAFE-22). This page makes
none: every
citation above is to a file in this repository, and the one importer fact it
relies on, that Clang's `_Nonnull` is honored by the importer, is in-repository
code (import.cpp:1462-1509) and is recorded as VERIFIED on the strategy page's
[External facts](README.md#external-facts) table. No normative rule on this
page depends on an UNVERIFIED item.

## References

-   [Safety strategy](README.md): [Soundness model](README.md#soundness-model),
    [Safety modes](README.md#safety-modes) and
    [What each mode diagnoses](README.md#what-each-mode-diagnoses)
-   [Safety terminology: type safety](terminology.md#type-safety)
-   [Temporal safety](temporal_safety.md) (pointer kinds, loans, T6) and
    [Spatial safety](spatial_safety.md) (`unsafe fn GetUnchecked`)
-   [`as` expressions](../expressions/as_expressions.md) and
    [implicit conversions](../expressions/implicit_conversions.md)
-   [Values: `const`-qualified types](../values.md#const-qualified-types) and
    the superseded escape-hatch strawman in
    [values](../values.md)
-   [Unions: reads](../unions.md#reads) and
    [Strict Carbon and future safety hooks](../unions.md#strict-carbon-and-future-safety-hooks)
-   [Classes: destructors and the `Allocator` interface](../classes.md#destructors)
-   [Templates](../templates.md) and
    [generics terminology: checked versus template parameters](../generics/terminology.md#checked-versus-template-parameters)
-   Proposal
    [p000196: Language-level safety strategy](/proposals/p000196-language-level-safety-strategy.md)
-   Proposal
    [p000845: `as` expressions](/proposals/p000845-as-expressions.md)
-   Proposal
    [p002006: Values, variables, pointers, and references](/proposals/p002006-values-variables-pointers-and-references.md)
-   Proposal
    [p005434: `ref` parameters, arguments, returns and `val` returns](/proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md)
-   Proposal
    [p005914: Updating Carbon's safety strategy](/proposals/p005914-updating-carbon-s-safety-strategy.md)
-   Fork decision [F-013](/fork/decision-log.md) and the synthesized plan
    [fork/safe/plan.md](/fork/safe/plan.md), whose design-panel record is the
    option paper for this area
-   The conformance program
    fork/conformance/programs/project/safety_strategy_doc.carbon and the
    toolchain tests toolchain/check/testdata/as/unsafe_as.carbon and
    toolchain/lower/testdata/pointer/convert.carbon
