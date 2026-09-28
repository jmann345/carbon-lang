# Function overloading

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Declaring an overload set](#declaring-an-overload-set)
    -   [The `overload` modifier](#the-overload-modifier)
    -   [The `overload` keyword](#the-overload-keyword)
    -   [Closed, same-library sets](#closed-same-library-sets)
    -   [Declaration order is API](#declaration-order-is-api)
    -   [Which functions may be overloaded](#which-functions-may-be-overloaded)
    -   [0.1 limits](#01-limits)
-   [Redeclaration rules](#redeclaration-rules)
    -   [New member versus redeclaration](#new-member-versus-redeclaration)
    -   [Preserved diagnostics](#preserved-diagnostics)
-   [Overload resolution](#overload-resolution)
    -   [First match in declaration order](#first-match-in-declaration-order)
    -   [The candidate match test](#the-candidate-match-test)
    -   [No ranking, no subsumption](#no-ranking-no-subsumption)
    -   [No overloading on return type](#no-overloading-on-return-type)
    -   [Diagnostics](#diagnostics)
    -   [Naming an overload set](#naming-an-overload-set)
-   [Interaction with checked generics](#interaction-with-checked-generics)
    -   [Calls from checked-generic bodies](#calls-from-checked-generic-bodies)
    -   [Generic and constrained members](#generic-and-constrained-members)
    -   [Calls from template code](#calls-from-template-code)
-   [C++ interoperability](#c-interoperability)
    -   [Importing C++ overload sets](#importing-c-overload-sets)
    -   [Exporting Carbon overload sets to C++](#exporting-carbon-overload-sets-to-c)
    -   [Documented divergence: two resolution rules](#documented-divergence-two-resolution-rules)
    -   [Linkage and mangling](#linkage-and-mangling)
-   [Future work](#future-work)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [Sub-forks](#sub-forks)
-   [References](#references)

<!-- tocstop -->

## Overview

> **Fork amendment 2026-09-27 (F-009; ported from the stranded design-docs
> branch 481e08c24 by workstream OV-1, fork/overload/plan.md D-OV-8; status
> updated 2026-09-28 by OV-2).** Toolchain status: same-file `overload fn`
> sets landed at OV-1 (W-024); set import across api/impl and libraries
> (with the closed-set rule, `OverloadSetFrozen`), generic members by
> non-diagnosing deduction, overloaded methods of generic classes, `extern`
> members and the api-member missing-definition check landed at OV-2 (W-025);
> export to C++ lands at OV-3 (W-026). Every sub-fork this page left OPEN is
> CLOSED in place below by the OV decision that resolves it, and the
> [0.1 limits](#01-limits) paragraph lists every gate the landed toolchain
> enforces as a semantics TODO.

_Function overloading_ lets several function definitions share one name, with
the callee chosen by the arguments at each call site. Carbon's overloading is
deliberately narrower than C++'s, in three ways that were each fixed by fork
decision
[F-009](/fork/decision-log.md):

<!-- Links to /fork/decision-log.md carry no `#f-009-...`/`#f-010-...`
fragment: those headings contain an em dash, which the check-links hook
percent-encodes in a link but keeps raw in the heading's anchor, so no
spelling of the fragment validates. -->

-   **Overloading is marked.** Every declaration of every member of an overload
    set carries the `overload` declaration modifier. A name is either a single
    function or an overload set, and any one declaration tells you which.
-   **Overload sets are closed.** All members of a set are declared together in
    the same library, per the accepted principle that
    [interfaces are Carbon's only open extension mechanism](/docs/project/principles/static_open_extension.md)
    ([proposal #998](https://github.com/carbon-language/carbon-lang/pull/998)).
    There is no argument-dependent lookup and no way to add a member to a set
    from outside its library.
-   **Resolution is first-match in declaration order.** Candidates are tried in
    the order they were declared, and the first one that matches is called.
    There is no best-match ranking, no ambiguity metric, and no subsumption
    ordering — the anticipated rule of the
    [pattern matching design](pattern_matching.md#refutability-overlap-usefulness-and-exhaustiveness)
    and of
    [proposal #2875](/proposals/p002875-functions-function-types-and-function-calls.md),
    made normative.

```carbon
package Geometry;

overload fn Dist(a: i64, b: i64) -> i64 { return Abs(a - b); }
overload fn Dist(a: f64, b: f64) -> f64 { return FAbs(a - b); }
overload fn Dist[T: type](a: Vec2(T), b: Vec2(T)) -> T { return Norm(a - b); }

fn Use() {
  Dist(3, 5);        // Calls member 1.
  Dist(1.5, 0.25);   // Member 1 does not match; calls member 2.
  Dist(v1, v2);      // Members 1 and 2 do not match; calls member 3
                     // by deducing `T`.
  var n: i32 = 4;
  Dist(n, n);        // Calls member 1: `i32` implicitly converts to `i64`,
                     // so the first member matches. Member 2 is never tried.
}
```

Overloading serves migration and interop: overloaded C++ APIs need a direct
Carbon spelling, and Carbon APIs must be callable from C++ as ordinary overload
sets. For _open_ extension — attaching operations to types you don't own — the
answer is [interfaces](generics/overview.md#interfaces), not overloading; for
dispatch on argument _values_ rather than types, the answer is
[pattern matching](pattern_matching.md), and value-pattern overload members are
[future work](#future-work).

Overload resolution is fully compile-time. It adds no runtime cost: once a
member is selected, the call compiles exactly as a call to a non-overloaded
function with that member's signature.

## Declaring an overload set

### The `overload` modifier

`overload` is a declaration modifier keyword, valid only on function
declarations:

> [ _access-modifier_ ] [ `overload` ] [ _other-function-modifiers_ ] `fn`
> _name_ ...

It follows any access-control modifier — the one ordering rule the existing
design fixes is that the
[access modifier comes first](classes.md#access-control) — so `private
overload fn F(...)` is well-formed and `overload private fn F(...)` is
diagnosed like any other misordered modifier.

**CLOSED (fork amendment 2026-09-27) by D-OV-1, moot:** `overload` sits in
the `Decl` modifier slot, after any access modifier, `extern` and `extend`,
and is mutually exclusive with the other `Decl`-group modifiers (`virtual`,
`abstract`, `override`, `impl`, `default`, `final`, `export`, `returned`) in
0.1, so no relative order among them arises. `private overload fn F(...)` is
well-formed and `overload private fn F(...)` is diagnosed
(`ModifierMustAppearBefore`), as for every misordered modifier.

Two or more function declarations form an overload set when they:

-   have the same name in the same scope,
-   each carry the `overload` modifier, and
-   have type-distinct parameter lists (see
    [New member versus redeclaration](#new-member-versus-redeclaration)).

Every declaration of every member — forward declarations and definitions alike
— carries the modifier. A declaration that omits `overload` for a name that is
an overload set is diagnosed at that declaration, with a note pointing at the
set; it never silently joins the set. Conversely, `overload` on a name that is
already declared as a non-overloaded function is diagnosed at the `overload`
declaration, with a note pointing at the original declaration. This "any
single declaration reveals the set exists" property is the point of the
marker; see [decision D1](#decisions-within-this-design).

> **Landed behavior (fork amendment 2026-09-27, D-OV-3).** Both mismatches
> are one diagnostic, `OverloadMarkerMismatch` ("`overload` must appear on
> every declaration of `F` or on none") with the `OverloadMarkerPrevious`
> note. An unmarked later declaration against a set is diagnosed and then
> recovers _as if marked_, so a definition still merges into its member and
> calls still resolve (no cascade). A marked later declaration against a
> plain function is diagnosed and not merged: it gets its own function, is
> not added to name lookup, and no redeclaration diagnostic is emitted on
> top.

**CLOSED (fork amendment 2026-09-27) by D-OV-3:** a set with exactly one
member is legal — `overload fn F(...)` with no sibling declaration is valid
and behaves exactly like a non-overloaded function at call sites, so that
members can be added later (or in a later version of the library) without
touching the first declaration. Pinned by the `single_member` golden.

### The `overload` keyword

`overload` becomes a keyword. In the toolchain, it is one
`CARBON_KEYWORD_TOKEN` entry in `toolchain/lex/token_kind.def` (alphabetically
between `Or` and `Override`), a `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER` entry
in `toolchain/parse/node_kind.def`, and a member of the existing **`Decl`
modifier group** in the `KeywordModifierSet` machinery
(`toolchain/check/keyword_modifier_set.h`), with the `fn` introducer's
allowed-modifier set admitting it and every other declaration kind rejecting
it (`ModifierNotAllowedOnDeclaration`). Because the modifier checker permits
at most one modifier per order slot (`toolchain/check/handle_modifier.cpp`),
this placement makes `overload` exclusive with `virtual`, `abstract`,
`override`, `impl`, `default`, `final`, `export` and `returned` in 0.1 — the
[declined F-009d](#which-functions-may-be-overloaded) recommendation
(fork amendment 2026-09-27, D-OV-1). A seventh order group can be added when
virtual members of sets are designed. This otherwise mirrors how `virtual`
and `extern` are implemented today.

Consequences of `overload` becoming a keyword:

-   `overload` is no longer a valid plain identifier anywhere. Existing code
    using it as an identifier must spell it as the
    [raw identifier](lexical_conventions/words.md#raw-identifiers)
    `r#overload`. No identifier named `overload` exists in `core/`,
    `examples/`, or the test suites, so no migration is needed in this
    repository, and `overload` is not a C++ keyword, so imported C++ entities
    named `overload` (rare but legal) are reachable as `Cpp.r#overload`.
-   The editor and highlighter grammars under `utils/` each need a one-word
    manual update, as for any new keyword.

### Closed, same-library sets

All members of an overload set must be declared in the same library, and the
set is complete at the end of that library: no other library — and no C++
header — can add a member. This is the direct application of
[proposal #998](https://github.com/carbon-language/carbon-lang/pull/998):
"function overloading is limited in Carbon to only signatures defined together
in the same library". Consequences:

-   Importers of the library see the whole set (subject to access control:
    `private` members are not visible outside the library, and a call from
    another file resolves against the visible members only). _Fork amendment
    2026-09-27:_ in 0.1 every member of a set has the same access as the
    set's first member (D-OV-6 gate (vi), a semantics TODO otherwise), so
    visibility is all-or-nothing; per-member access is filed as a residue
    item.
-   A Carbon `overload fn` declaration can never extend an imported C++
    overload set: the C++ header is a different library, and Carbon source
    cannot declare into the `Cpp` package. Imported C++ sets are specified in
    [C++ interoperability](#c-interoperability).
-   Open extension points remain the job of
    [interfaces](generics/goals.md#checked-generics-instead-of-open-overloading-and-adl).
    A design that needs callers to add cases for their own types should define
    an interface, not an overload set.

**CLOSED (fork amendment 2026-09-27) by D-OV-7:** yes — every member of a
set is declared in one file (the API file, for a set visible outside the
library; sets declared wholly inside one implementation file are also fine),
and implementation files may _define_ members forward-declared in the API
file but not add members (diagnosed as `OverloadSetFrozen`, landed at OV-2,
with a note at the set's first member; the same diagnostic covers a member
declared in an importing library). This keeps a set's declaration order
readable in one place and avoids order questions between files; relaxing it
later is purely additive. Since OV-2, a set reached through any import —
including the API file seen from its implementation file — is imported whole,
with its member list in declaration order.

### Declaration order is API

The textual order of the member declarations is the resolution order, so the
order is part of the set's API:

-   Appending a member at the end of a set never changes the meaning of an
    existing call: calls that previously resolved still select the same
    earlier member, and only calls that previously failed to resolve can start
    matching the new member.
-   Inserting or reordering members earlier in the set can change which member
    existing calls select, exactly as reordering `match` cases can. Style
    guidance: declare more specific members before more general ones, and
    treat member order with the same care as parameter order.

Within a file, a call site resolves against the members declared _above_ it,
per the
[information accumulation principle](/docs/project/principles/information_accumulation.md)
([proposal #875](https://github.com/carbon-language/carbon-lang/pull/875)) —
the same top-down rule that governs all name lookup — with that principle's
own class-body exception: member function bodies are
[processed in a deferred manner](classes.md#deferred-member-function-definitions),
as if they appeared after the enclosing class, so a call from a sibling
member function body resolves against the _complete_ class-scope set,
including members declared later in the class body. Code that imports the
library sees the complete set.

### Which functions may be overloaded

In 0.1, `overload` is permitted on:

-   Namespace-scope and file-scope function declarations, including
    [generic functions](generics/overview.md#generic-functions) with deduced
    and compile-time parameters.
-   [Member functions of classes](classes.md#member-functions), including
    methods, which declare `self` (or, for mutation, `ref self`) as the first
    parameter in the explicit parameter list per
    [methods](classes.md#methods). All members of such a set are declared in
    the same class body:

    ```carbon
    class List {
      overload fn Append(ref self, x: i64);
      overload fn Append(ref self, s: str);
    }
    ```

    A same-name member function in a base class is _not_ a member of a
    derived class's set — membership requires the same class body. What a
    derived class's `overload` declaration means for lookup of the base
    class's same-name members (hiding, merging, or an error) is explicitly
    deferred to the open cross-boundary rules recorded in
    [classes: overloaded member functions](classes.md#overloaded-member-functions);
    this design does not decide it.
-   Member functions of [unions](unions.md#union-members), under the same
    rules as classes (pinned by the `union_scope_set` golden; fork amendment
    2026-09-27).

`overload` is not permitted on lambdas (they have no name to overload) or on
destructors. _Fork amendment 2026-09-27:_ Carbon destructors are
`impl as Core.Destroy` bodies, and a marked declaration directly inside any
`impl` body is D-OV-6 gate (xiii) ("`overload fn` in an `impl` body"), which
subsumes the destructor rule.

**CLOSED (fork amendment 2026-09-27) by D-OV-6 gate (x):** no in 0.1 —
every member of a set either declares `self` or does not, so that whether the
receiver of `x.F(...)` participates in the match test never varies by
candidate; a member that disagrees with the set on `self` is a semantics TODO
("`overload fn` members that disagree on `self`"). C++ freely overloads
static and non-static member functions, and Carbon already permits calling a
non-method member function through an instance
([classes: non-methods](classes.md#non-methods)); mixed sets are a filed
residue item.

**CLOSED (fork amendment 2026-09-27) by D-OV-3:** no in 0.1 — members of
one set must be distinguishable by their parameters after `self`; two method
members that differ only in `self` shape (`self` versus `ref self`) are a
semantics TODO ("`overload fn` members distinguished only by `self`").
Overloading on expression category parallels upstream's open issue
[#3154](https://github.com/carbon-language/carbon-lang/issues/3154) and is
deferred with it.

**CLOSED (fork amendment 2026-09-27) by D-OV-1, this page's recommendation
DECLINED for 0.1:** `overload` does not compose with `virtual`, `abstract`,
`override` or `impl` (`ModifierNotAllowedWith`). This page recommended yes —
overload resolution selects a member statically first, and virtual dispatch
then applies to the selected member, the "overload resolution should happen
before virtual dispatch" ordering recorded in
[classes: overloaded member functions](classes.md#overloaded-member-functions)
— but the toolchain keys a virtual function's vtable slot by NAME within its
class, so two virtual members of one name need signature-keyed vtable slots
and override matching by signature, a vtable-layout change no 0.1 program
needs. Filed as the residue item "virtual members of overload sets"; the
break condition is a design ruling that `virtual overload fn` is required.

**CLOSED (fork amendment 2026-09-27) by D-OV-6 gate (ix):** no in 0.1 — a
marked declaration directly inside an `interface` body is a semantics TODO
("`overload fn` in an interface"), since overloaded associated functions
interact with witness tables and impl checking in ways nothing in the 0.1
milestone requires.

### 0.1 limits

_Fork amendment 2026-09-27 (fork/overload/plan.md D-OV-6)._ The landed
toolchain enforces each of the following as a semantics TODO diagnosed at the
declaration (or, for the two call-site gates, at the call), so that overload
resolution only ever sees supported members; each lifting slice deletes its
gate and the gate's golden in the same commit:

-   (i) a generic member (`overload fn F[T: type](x: T)`) — LIFTED at OV-2
    (non-diagnosing deduction inside the candidate probe);
-   (ii) a set declared inside a generic scope (a generic class, interface
    or impl) — LIFTED at OV-2 (the set's type records the enclosing self
    specific; interfaces and impls remain gates (ix) and (xiii));
-   (iii) an explicit parameter after `self` that is not a single by-value
    binding (`ref` or `var` parameters, and destructuring tuple or struct
    parameter patterns);
-   (iv) `extern overload fn` — LIFTED at OV-2 (an `extern overload fn`
    must name an existing member of the imported set, and the per-member
    `extern` ownership rules then apply);
-   (v) `overload` on the entry point `Main.Run`;
-   (vi) members whose access modifier differs from the set's;
-   (vii) a set reached through any import, including the API file seen from
    its implementation file — LIFTED at OV-2 (the set is imported whole);
-   (viii) C++ lookup of a Carbon set (export) — until OV-3;
-   (ix) a marked declaration directly in an `interface` body;
-   (x) members that disagree on whether they declare `self`;
-   (xi) a call with a template-dependent argument;
-   (xii) an explicit receiver (`C.M(c, ...)`) for a `ref self` or
    `addr self` member;
-   (xiii) a marked declaration directly in an `impl` body (which covers
    destructors, `impl as Core.Destroy`).

Also excluded in 0.1, as hard errors rather than TODOs: `overload` with
`virtual`, `abstract`, `override`, `impl`, `default`, `final`, `export` or
`returned` (D-OV-1, `ModifierNotAllowedWith`). And one limit that is not a
diagnostic until OV-2: an API-declared member without a definition (the
marked-signature typo above) was accepted and failed at link time; since
OV-2, checking a library's implementation file diagnoses every API-declared
member that neither file defines (`MissingDefinitionInImpl` at the member's
API declaration).

## Redeclaration rules

Carbon's
[syntactic redeclaration matching](functions.md#redeclaration-matching)
([proposal #3763](/proposals/p003763-matching-redeclarations.md)) makes "two
declarations of `F` differ" a hard error today, which is precisely what makes
accidental signature drift loud. The `overload` marker is designed so that
this diagnostic contract survives overloading; that is the primary reason
overloading is marked (see
[Alternatives considered](#alternatives-considered)).

### New member versus redeclaration

For a declaration `D` of name `F` in a scope where `F` is already declared:

-   `D` carries `overload`, and its signature is token-identical (under the
    matching rules of
    [proposal #3763](/proposals/p003763-matching-redeclarations.md)) to an
    existing member: `D` is a _redeclaration of that member_ — typically its
    definition. The usual redeclaration rules apply per member: each member
    may be forward-declared at most once per file, the declaration must
    precede the definition, and the token sequences must match exactly.
-   `D` carries `overload`, and its parameter list is _type-distinct_ from
    every existing member — its sequence of parameter types, after resolving
    type expressions, differs from each member's: `D` declares a _new
    member_, appended to the set in declaration order. Member distinctness is
    a property of parameter _types_, not tokens: no two members of a set may
    have type-identical parameter lists. This is what makes
    [no overloading on return type](#no-overloading-on-return-type)
    enforceable and guarantees each member a distinct
    [mangled name](#linkage-and-mangling).
-   `D` carries `overload`, its parameter list is type-identical to an
    existing member's, and its signature is not token-identical to that
    member's — it differs in a binding name, in the spelling of a type
    expression, or in the return clause: `D` never declares a new member.
    Its precise diagnosis is sub-fork F-009k below.
-   `D` does not carry `overload`: the marker mismatch is diagnosed as
    described [above](#the-overload-modifier). Without the marker, nothing
    about today's behavior changes: two unmarked `fn F` declarations with
    differing signatures remain the same
    "redeclaration differs" / "duplicate name" errors they are today.

**CLOSED (fork amendment 2026-09-27) by D-OV-3:** a marked declaration
whose parameter list is type-identical to an existing member's without the
signatures being token-identical — for example, a binding-name-only
difference: `overload fn G(x: i64);` then `overload fn G(y: i64) { ... }` —
is an invalid redeclaration of that member, diagnosed at `D` with the
diagnostics of proposal #3763 (`RedeclParamDiffers`,
`RedeclParamSyntaxDiffers`, `FunctionRedeclReturnTypeDiffers`, `RedeclRedef`,
`RedeclRedundant`;
[functions: redeclaration matching](functions.md#redeclaration-matching)),
never a silently unreachable member. Member identity is parameter-type
equality: the first type-equal member is the one being redeclared.

### Preserved diagnostics

The failure modes that
[proposal #3763](/proposals/p003763-matching-redeclarations.md) exists to
catch remain caught:

-   **Unmarked signature typo** — a forward declaration and definition that
    disagree:

    ```carbon
    fn F(x: i64) -> i64;
    fn F(x: u64) -> i64 { ... }  // ❌ Error today, error under this design:
                                 // redeclaration differs at parameter 1.
    ```

    Unchanged: without `overload`, differing signatures never form a set.

-   **Marked signature typo** — the same typo inside a marked set:

    ```carbon
    overload fn G(x: i64) -> i64;
    overload fn G(x: u64) -> i64 { ... }  // Declares a second member.
    // ❌ Error at end of file/library: member `G(x: i64)` declared but
    // never defined.
    ```

    Here the typo legally declares a two-member set whose first member has no
    definition. For declarations in an implementation file, the existing
    missing-definition diagnostic (`MissingDefinitionInImpl`,
    `toolchain/check/check_unit.cpp`) fires at the end of the file. For
    declarations in an API file, no such check exists today: the toolchain
    accepts a never-defined non-`extern` API declaration
    (`toolchain/check/testdata/function/declaration/no_definition_in_impl_file.carbon`),
    so the error would surface only at link time. This design therefore
    **depends on adding a library-boundary missing-definition check for
    overload-set members**: every member of a set must be defined by the end
    of the set's library, diagnosed at compile time. With that check, the
    error moves from the second declaration to the library boundary but
    never reaches link time and never silently changes call resolution — the
    trade C++'s unmarked overloading loses on both counts. _Fork amendment
    2026-09-27:_ OV-1 pins today's behavior (an api-declared member without
    a definition is accepted and fails at link; golden
    `marked_typo_undefined_member`); OV-2 landed the missing-definition check
    for api-declared set members in the implementation file
    (fork/overload/plan.md §1.B.7; golden `import.carbon`,
    `fail_undefined.impl.carbon`).

-   **Marked parameter-name typo** — a marked pair differing only in a
    binding name never declares a new member, because members must have
    type-distinct parameter lists; whether it is diagnosed as an invalid
    redeclaration is
    [sub-fork F-009k](#new-member-versus-redeclaration).

## Overload resolution

### First match in declaration order

A direct call whose callee names an overload set is resolved as follows:

1.  The _candidate list_ is the members of the set visible at the call site,
    in declaration order.
2.  Each candidate is tested in turn with the
    [match test](#the-candidate-match-test) below.
3.  The first candidate that passes is selected; later candidates are not
    examined at all. The call then compiles exactly as a direct call to the
    selected member, per [function calls](functions.md#direct-calls).
4.  If no candidate passes, the call is a compile error.

This is the rule
[proposal #2875](/proposals/p002875-functions-function-types-and-function-calls.md)
records as Carbon's intent ("check each candidate in turn until one matches"),
and it is the function-call analog of top-down `match` semantics: an overload
set behaves like an ordered list of patterns, matched first-to-last. It is
also the same ordered-candidates model the toolchain already implements for
`match_first` impl blocks
([generics: prioritization rule](generics/details.md#prioritization-rule)).

### The candidate match test

A candidate _matches_ a call when all of the following succeed, tried in
order and without emitting diagnostics — a failure at any step means "try the
next candidate", not "error". (_Fork amendment 2026-09-27, D-OV-4:_ the
landed probe converts each argument to the parameter type as a value inside a
discarded instruction block, with an integer-literal range pre-test so that an
out-of-range literal rejects an integer member silently. Two conversions still
emit through constant evaluation even when the candidate is rejected — an
integer or float literal converted to a `Float` type that cannot represent
it, a struct or tuple literal initializing an abstract class, and an
out-of-range literal _element_ of a struct or tuple literal converted to a
narrow integer field of an aggregate parameter (the literal pre-test covers
only a top-level integer literal) — recorded as the residue item
"unconditional constant-evaluation diagnostics inside overload probes:
literal→float, abstract-init and aggregate-literal element conversions".)

1.  **Arity.** The number of arguments is within the candidate's accepted
    range; for method calls, the receiver binds to `self` and the
    parenthesized arguments are counted against the parameters after `self`.
    (The range is a single number today; it is specified as a range so that
    [variadic](variadics.md) members can join sets later without changing
    this algorithm. In the toolchain: `GetExplicitArityRange`.)
2.  **Deduction.** Values for the candidate's deduced and compile-time
    parameters are deduced from the argument types, per
    [generic call rules](functions.md#direct-calls). Deduction failure means
    the candidate does not match.
3.  **Constraints.** The deduced values satisfy the candidate's declared
    constraints — interface constraints on compile-time bindings, and, when
    the
    [template constraint](/fork/decision-log.md)
    work lands, `require` validity blocks and boolean predicates. An
    unsatisfied constraint means the candidate does not match; it is not an
    error.
4.  **Conversions.** Each argument
    [implicitly converts](expressions/implicit_conversions.md) to the
    corresponding parameter type, and `ref` prefixes match as required by
    [direct call checking](functions.md#direct-calls). Any failure means the
    candidate does not match.

The selected member is then called with exactly the conversions the match test
found. Argument expressions are evaluated once, before resolution, in the
usual left-to-right order; the match test examines their types and
compile-time values but does not re-evaluate them per candidate.

**CLOSED (fork amendment 2026-09-27) by D-OV-4 step 2(b):** no
Carbon-native default arguments in 0.1, so the arity step above stays exact
and no interaction rule is needed. Carbon has no default-argument design;
overloading substitutes for the common cases, and default arguments on
_imported_ C++ functions keep working (they participate in Clang-side
resolution; see [Importing C++ overload sets](#importing-c-overload-sets)).
Revisit as its own design fork if a need appears.

### No ranking, no subsumption

There is deliberately no notion of a _better_ match:

-   If two candidates would both match, the earlier one wins, always — even
    when the later one is exact and the earlier one requires conversions, and
    even when the later one is non-generic and the earlier one generic. In the
    [overview example](#overview), `Dist(n, n)` with `n: i32` selects the
    `i64` member because it is declared first and `i32` converts to `i64`;
    that the `f64` member exists is irrelevant.
-   Differently-constrained generic members are not partially ordered by their
    constraints: there is no C++20-style subsumption. Declaration order is the
    only priority. (Fork decision
    [F-010](/fork/decision-log.md)
    adopts this same rule for constrained candidates, so the two designs
    cannot disagree.)
-   A member that can never be selected — because an earlier member matches
    everything it matches — is _not_ diagnosed in 0.1. A usefulness
    diagnostic paralleling
    [pattern usefulness checking](pattern_matching.md#refutability-overlap-usefulness-and-exhaustiveness)
    is [future work](#future-work); detecting dead members in general is
    exactly the subsumption analysis this design declines to require.

The cost of this rule is that authors must order members deliberately. The
benefits are that resolution is explainable in one sentence, compile cost is
linear in the number of members (Swift's ranking-based resolution is a known
source of exponential type-checker blowups), and the semantics forward-map
onto pattern matching: declaration-order first-match _is_ match-case order,
which keeps [value-pattern members](#future-work) a compatible extension.

### No overloading on return type

Members of a set may not differ only in return type, and the return type
plays no part in the match test: no type information propagates from the
call's context inward, per
[proposal #2875](/proposals/p002875-functions-function-types-and-function-calls.md).
The enforcement follows from member distinctness: a declaration whose
parameter list is type-identical to an existing member's never declares a new
member, whatever its return clause (see
[New member versus redeclaration](#new-member-versus-redeclaration)).

### Diagnostics

When no candidate matches, the call is diagnosed at the call site. The
diagnostic names the overload set and its declaration location.

**CLOSED (fork amendment 2026-09-27) by D-OV-4 step 4:** the error
`OverloadNoMatch` ("no member of overload set `F` accepts this call") at the
call, plus one `OverloadCandidateRejected` note per member at its declaration
giving the first step of the [match test](#the-candidate-match-test) that
failed for it — a different number of arguments, a parameter its argument
cannot implicitly convert to, generic parameters that could not be deduced,
or a receiver provided to a non-method — the granularity the resolution loop
knows for free. Clang-granularity notes are a filed residue item.

### Naming an overload set

In 0.1, an overload set may be named only as the callee of a
[direct call](functions.md#direct-calls) (including method calls, where the
bound-method machinery applies to the selected member).

**CLOSED (fork amendment 2026-09-27) by D-OV-4 step 6:** any use that
converts the set value — using it as an initializer (`let f: auto = Dist;`),
passing it as an argument, discarding it as a statement — is the hard error
`OverloadSetNotCallee` ("overload set `Dist` can only be used as the callee
of a call"); there are no arguments to resolve against. Other non-call uses
reach the landed diagnostic that precedes any conversion (`&Dist` is
`AddrOfNonRef`; `Dist.x` is the member-access family). The
forward-compatible path is
[proposal #2875](/proposals/p002875-functions-function-types-and-function-calls.md)'s
model of an overload set as a single function type with one
[`Call` impl](functions.md#indirect-calls-and-the-call-interface) per member
in a `match_first` block, which would make sets first-class later without
changing any call-site semantics.

**CLOSED (fork amendment 2026-09-27) by D-OV-10:** yes — an `alias` for
the set's name aliases the whole set as a unit (never an individual member;
golden `alias_of_set`), and re-export through
[`export import`](code_and_name_organization/README.md) carries the whole
set (golden `export_import.carbon`, OV-2); the set stays closed, since an
alias adds no members.

## Interaction with checked generics

The governing constraint, from the
[generics goals](generics/goals.md#checked-generics-instead-of-open-overloading-and-adl):
a checked-generic function is type-checked once, from its definition alone.
Overloading must never break that, so overload resolution is never deferred
to instantiation for checked generics.

### Calls from checked-generic bodies

A call to an overload set inside a checked-generic body is resolved during
the single type-checking of that body, against the symbolic types of the
arguments. For each candidate in declaration order:

-   If the candidate definitely does not match — the match test fails for
    every possible value of the generic bindings in scope — it is skipped.
-   If the candidate definitely matches — the match test succeeds using only
    what the bindings' constraints guarantee — it is selected, once, for all
    instantiations. Every specific of the enclosing function calls this same
    member.
-   If the candidate's match status _depends on the specific_ — it would
    match for some values of a binding `T` and not others — the call is a
    compile error at the definition, diagnosed with the offending candidate
    and binding. The fix is to constrain `T` so the status is determined, to
    reorder or adjust the set, or to make the enclosing parameter a
    `template` binding. _Fork amendment 2026-09-27 (D-OV-4 step 7):_ this
    case cannot arise from the landed probe — a conversion of a symbolic
    argument either resolves through a constraint of `T` or fails, so a
    candidate is definitely matched or definitely rejected, and the golden
    `call_from_generic_body` pins the once-at-the-definition selection.

This makes the rule anticipated in
[generics terminology](generics/terminology.md#ad-hoc-polymorphism) — "a
compile error if overloading of some name prevents a checked-generic function
from being typechecked from its definition alone" — the normative behavior,
and it guarantees monomorphization-independence: which member a call invokes
never varies between specifics of the same checked-generic function.

### Generic and constrained members

Generic members participate in sets through step 2 and step 3 of the
[match test](#the-candidate-match-test): a generic candidate matches when
deduction succeeds and its constraints are satisfiable at the call site. A
call site with concrete argument types resolves fully; the selected generic
member then gets a specific exactly as a call to a non-overloaded generic
function would. Mixed sets — non-generic and generic members, or members with
different constraints — follow declaration order like any other set, with
[no specificity preference](#no-ranking-no-subsumption).

An overload set is not an entity that can implement an interface or appear as
a witness; only its individual members are functions. Interface-driven
dispatch (including operator overloading by way of the `Core` operator interfaces)
is a separate mechanism and is unchanged by this design.

### Calls from template code

Inside a function with [`template` parameters](templates.md), a call whose
arguments involve template-dependent types is resolved after substitution,
when the actual types are known — the C++-like late binding that templates
exist to provide (see
[generics terminology](generics/terminology.md#ad-hoc-polymorphism)). The
resolution rule applied at that point is still Carbon's first-match rule for
Carbon sets (and C++'s rule for
[imported C++ sets](#importing-c-overload-sets)); only the _time_ of
resolution differs, never the algorithm. _Fork amendment 2026-09-27:_ in 0.1
such a call is D-OV-6 gate (xi), a semantics TODO ("overload resolution with
template-dependent arguments"); the mechanism is filed as a residue item.

## C++ interoperability

Both directions are required by the
[0.1 milestone](/docs/project/milestones.md#functions-statements-expressions-etc).
They are asymmetric
by design: each language's call sites use that language's own resolution
rules.

### Importing C++ overload sets

Importing C++ overload sets into Carbon **already works** and is unchanged by
this design; this section documents the mapping.

-   All same-name function declarations visible through imported C++ headers
    form one imported overload set, named through the `Cpp` package
    (`Cpp.frexp`, `Cpp.std.sqrt`, ...). No `overload` marker exists or is
    needed on the C++ side; the marker is a Carbon-authoring construct.
-   A Carbon call to an imported set is resolved by **C++'s rules, exactly**:
    the toolchain hands the candidate set to Clang Sema and performs genuine
    C++ overload resolution — implicit conversion sequence ranking, best
    viable function, ambiguity diagnostics, default arguments, and the
    [literal conversion rules](interoperability/literals.md) for Carbon
    literal arguments. In the toolchain, the set is a `SemIR::CppOverloadSet`
    holding a Clang `UnresolvedSet` of candidates, and calls dispatch through
    `PerformCppOverloadResolution`
    (`toolchain/check/cpp/overload_resolution.cpp`). This satisfies the
    interop requirement of
    [respecting C++'s semantics](interoperability/README.md#overview),
    "including its complex overload resolution rules": an imported call means
    in Carbon what it would mean in C++.
-   Imported sets are closed from Carbon's side: `overload fn` cannot add
    members to a `Cpp` name (see
    [Closed, same-library sets](#closed-same-library-sets)). C++
    open-overloading extension points (`swap`-style customization found by
    ADL) are a separate milestone bullet answered by interfaces, not by this
    design.

The two resolution rules never mix: a callee is either a Carbon set (Carbon
first-match) or an imported C++ set (Clang best-match). No call resolves
against a merged candidate list.

### Exporting Carbon overload sets to C++

An exported Carbon overload set is visible to C++ as an ordinary C++ overload
set. Each exported member is exported through the existing per-function
export machinery (`toolchain/check/cpp/export.cpp`): a `clang::FunctionDecl`
— or `clang::FunctionTemplateDecl`, for generic members, within the same
limits that govern exporting non-overloaded generic functions — created in
the mapped `DeclContext`. Multiple same-name declarations in one context
_are_ a C++ overload set, so C++ callers get ordinary C++ call syntax with no
wrappers:

```carbon
// Carbon
package Geometry;
overload fn Dist(a: i64, b: i64) -> i64;
overload fn Dist(a: f64, b: f64) -> f64;
```

```cpp
// Seen from C++
namespace Geometry {
int64_t Dist(int64_t a, int64_t b);
double Dist(double a, double b);
}
```

C++ call sites to these declarations resolve under **C++'s rules** — the
divergence this creates is specified in the
[next section](#documented-divergence-two-resolution-rules).

**CLOSED (fork amendment 2026-09-27) by fork/overload/plan.md §1.C.1
(OV-3):** when some members of an exported set have signatures that cannot be
mapped to C++ (a parameter type with no C++ mapping), the exportable members
are exported and the rest omitted — matching how per-function export already
behaves — so C++ sees a subset of the set; the existing per-function
semantics TODO on each omitted member is its note. The alternative, refusing
to export the whole set unless every member maps, would make one exotic
member remove an entire API from C++. Until OV-3, C++ lookup of any Carbon
set is D-OV-6 gate (viii), a semantics TODO ("overload set export").

### Documented divergence: two resolution rules

The same argument list can resolve differently on the two sides of the
boundary, because Carbon call sites use first-match and C++ call sites use
best-viable-match. This divergence is **accepted and documented** rather than
restricted, per decision
[F-009](/fork/decision-log.md);
see [decision D5](#decisions-within-this-design). The two shapes it takes,
using the `Dist` set above (members declared `i64` first, `f64` second):

-   **Carbon resolves; C++ rejects.** With a 32-bit integer argument, Carbon
    selects the first member (`i32` converts to `i64`). A C++ call
    `Dist(int{4}, int{4})` is an **ambiguity error**: `int → int64_t` and
    `int → double` are equal-rank standard conversions under C++'s rules.
-   **The two sides pick different members.** For a set declared `i64`
    first, `i32` second — `overload fn Pick(x: i64) -> i32; overload fn
    Pick(x: i32) -> i32;` — a Carbon call with an `i32` argument selects the
    _first_ member (`i32 → i64` is an
    [implicit conversion](expressions/implicit_conversions.md): the integer
    widens), while the C++ call `Pick(int{4})` selects the _`i32`_ member:
    on supported targets `int` is `int32_t`, an exact match, which outranks
    the `int → long` conversion under C++'s rules. (_Fork amendment
    2026-09-27:_ this page's original example used `i32 → f64`, which is not
    an implicit conversion in the prelude — the integer-to-float `ImplicitAs`
    impls are not enabled — so the shape is restated with the `Pick` set that
    OV-3's conformance program asserts in both directions.)

The divergence is bounded: it affects only _which member is selected, or
whether the call compiles_. It can never produce a wrong-ABI call — each
exported member is its own C++ declaration with its own symbol and (where
needed) its own thunk, so whichever member C++ resolution picks is the member
that runs, with the correct signature. There is no scenario in which a call
crosses the boundary and executes a member other than the one the caller's
own language rules selected.

Per the decision, every exported-overload conformance program asserts _both_
directions' resolution: the Carbon-side selection by first-match and the
C++-side selection (or rejection) under C++ rules, so the divergence is
pinned by tests rather than lore.

### Linkage and mangling

Two members of a Carbon set are distinct functions and need distinct linkage
names. The toolchain's mangler derives names from the qualified name plus a
generic-specific fingerprint — plus, for library-private names only, a
fingerprint of the first declaration (`toolchain/sem_ir/mangler.cpp`) — so
two _public_ non-generic members of one set would collide. _Fork amendment
2026-09-27 (D-OV-5):_ the mangled name of an overload-set member carries the
member's **set-relative index** immediately after its name — `overload fn
Pick(x: i64)` at file scope in package `Main` mangles to
`_CPick:overload0.Main` and its sibling to `_CPick:overload1.Main`. The index
is the member's position in declaration order, which is api order and the
same in every file that sees the set, so no fingerprint of any instruction
is involved; a signature fingerprint (this page's original mechanism) was
rejected because instruction fingerprints are not stable across files — an
imported declaration is fingerprinted with an empty declaration block, which
is why the library-private fingerprint already fails to separate two
libraries' functions of one name
(`toolchain/lower/testdata/function/generic/cross_library_name_collision_private.carbon`).
Exported members are **not** unaffected by Carbon-internal mangling: every
exported member's C++ declaration carries its Carbon mangled name as an asm
label (`toolchain/check/cpp/export.cpp`), so the C++ symbol of a member _is_
its `:overload<N>` name and C++ sees N distinct symbols behind N same-named
declarations.

## Future work

-   **Value-pattern members.** The
    [pattern matching design](pattern_matching.md#pattern-matching-as-function-overload-resolution)
    aspires to overload sets whose member signatures contain refutable
    patterns (`overload fn Fib(0) -> i64 { return 0; }`), compiled as a
    dispatcher over the argument tuple. This design is its compile-time
    subset by construction: declaration-order first-match is match-case
    order, so value-pattern members can be added later without changing the
    meaning of any existing set. Per decision F-009, signatures of overload
    members in 0.1 use ordinary irrefutable parameter patterns only; this
    extension is additionally blocked on `match` semantics landing (fork
    workstream W4).
-   **Variadic members.** The [variadics design](variadics.md) is accepted
    but unimplemented; the match test's arity step is specified as a range so
    variadic members can join sets without reworking resolution.
-   **Usefulness diagnostics.** Diagnosing members that can never be
    selected, paralleling pattern usefulness checking; requires the overlap
    analysis 0.1 deliberately omits.
-   **First-class overload sets.** The
    [#2875 model](/proposals/p002875-functions-function-types-and-function-calls.md)
    — one function type, one `Call` impl per member under `match_first` —
    would make naming a set outside a call meaningful.
-   **`self`-shape overloading**, tracking upstream issue
    [#3154](https://github.com/carbon-language/carbon-lang/issues/3154).
-   **Upstream convergence.** Upstream's placeholder syntax is
    `overloaded fn`; if upstream lands its own overloading proposal, renaming
    the keyword or adjusting the marker is a mechanical migration, and every
    semantic rule here matches upstream's recorded intent.

## Decisions within this design

The core of this design was fixed by fork decision
[F-009](/fork/decision-log.md),
ratified by the user:

-   **D1 — Overloading is marked: the `overload` modifier appears on every
    member declaration.** The marker preserves
    [proposal #3763](/proposals/p003763-matching-redeclarations.md)'s
    typo-catching redeclaration diagnostics (an unmarked signature mismatch
    stays a hard error), makes sets grep-able and intent-explicit consistent
    with the explicitness rationale of the
    [static open extension principle](/docs/project/principles/static_open_extension.md),
    and means any single declaration reveals that a set exists.
-   **D2 — Sets are closed and same-library**, per proposal #998. Interfaces
    remain the only open extension mechanism; there is no ADL.
-   **D3 — Resolution is first-match in declaration order, with no ranking
    lattice and no subsumption.** This keeps resolution linear and
    explainable, matches upstream's recorded intent (#2875,
    pattern_matching.md), and is the compile-time subset of the aspirational
    pattern-dispatch model.
-   **D4 — No value patterns in overload signatures in 0.1.** Members use
    ordinary irrefutable parameter patterns; value-pattern dispatch is future
    work layered on `match` semantics.
-   **D5 — Exported sets resolve under C++ rules; the resulting divergence is
    documented and conformance-tested bidirectionally,** rather than
    restricted by an export-coherence check (undecidable in general) or an
    export opt-out. Divergence is bounded to member selection and
    call-validity; ABI correctness is structural.

Points this document leaves genuinely open are collected under
[Sub-forks](#sub-forks) and decided by the user, never silently by
this document.

## Alternatives considered

The alternatives for this area were researched in the option paper
([fork/design-sprint/function-overloading.md](/fork/design-sprint/function-overloading.md))
and rejected in fork decision
[F-009](/fork/decision-log.md):

-   **Unmarked closed overloading** (C++/Swift surface): same semantics, but
    any two same-name declarations silently form a set, so a signature typo
    in a forward-declaration/definition pair becomes a legal two-member set
    and the p003763 diagnostics regress to link-time or call-site confusion.
-   **Pattern-dispatch overloading now** (value patterns as overloads):
    blocked on unimplemented `match` semantics, and an XL implementation;
    adopted instead as the [future](#future-work) this design grows into.
-   **No Carbon-native overloading** (Rust/Zig discipline): fails the
    explicit 0.1 milestone bullet and leaves mechanical migration of
    overloaded C++ APIs with no target.

That decision is final; this document specifies the chosen design rather than
relitigating it.

## Sub-forks

Per the fork's process rule that every sub-decision with more than one
defensible answer goes to the user
([fork/process.md](/fork/process.md#human-in-the-loop-rule)), the following
points were marked OPEN when this page was drafted. **Every one is CLOSED
(fork amendment 2026-09-27)** by the OV decisions of fork/overload/plan.md
under the auto-adoption rule (each is veto-able after the fact); the closing
decision follows each entry, and the closed paragraphs in the sections above
carry the detail.

-   **F-009a — Single-member sets** (see
    [The `overload` modifier](#the-overload-modifier)): legal. CLOSED by
    D-OV-3 (golden `single_member`).
-   **F-009b — Same-file rule** (see
    [Closed, same-library sets](#closed-same-library-sets)): yes in 0.1;
    implementation files only define (`OverloadSetFrozen`, landed at OV-2).
    CLOSED by D-OV-7.
-   **F-009c — `self`-shape overloading** (see
    [Which functions may be overloaded](#which-functions-may-be-overloaded)):
    no in 0.1, a semantics TODO. CLOSED by D-OV-3.
-   **F-009d — `overload` with `virtual`** (see
    [Which functions may be overloaded](#which-functions-may-be-overloaded)):
    NO in 0.1 — this page's YES declined for the vtable reason; residue
    "virtual members of overload sets". CLOSED by D-OV-1.
-   **F-009e — Interface associated functions** (see
    [Which functions may be overloaded](#which-functions-may-be-overloaded)):
    no in 0.1, a semantics TODO. CLOSED by D-OV-6 gate (ix).
-   **F-009f — Diagnostic depth** (see [Diagnostics](#diagnostics)):
    per-candidate first-failure notes with a four-way reason. CLOSED by
    D-OV-4 step 4.
-   **F-009g — Naming a set outside a call** (see
    [Naming an overload set](#naming-an-overload-set)): hard error
    `OverloadSetNotCallee`. CLOSED by D-OV-4 step 6.
-   **F-009h — `alias` and re-export** (see
    [Naming an overload set](#naming-an-overload-set)): yes, whole-set and
    transitive through `export import`. CLOSED by D-OV-10.
-   **F-009i — Partially exportable sets** (see
    [Exporting Carbon overload sets to C++](#exporting-carbon-overload-sets-to-c)):
    export the exportable subset; the per-member semantics TODO is the note.
    CLOSED by fork/overload/plan.md §1.C.1 (OV-3).
-   **F-009j — Default arguments**: none in 0.1; the arity step is exact.
    CLOSED by D-OV-4 step 2(b).
-   **F-009k — Type-identical, token-different declarations** (see
    [New member versus redeclaration](#new-member-versus-redeclaration)):
    an invalid redeclaration of the type-identical member. CLOSED by D-OV-3.
-   **F-009l — Mixing methods and non-methods in one set** (see
    [Which functions may be overloaded](#which-functions-may-be-overloaded)):
    no in 0.1, a semantics TODO. CLOSED by D-OV-6 gate (x).
-   **F-009m — Position of `overload` among declaration modifiers** (see
    [The `overload` modifier](#the-overload-modifier)): moot — `overload`
    sits in the `Decl` slot and is exclusive with the other `Decl` modifiers.
    CLOSED by D-OV-1.

## References

-   [Milestones: functions](/docs/project/milestones.md#functions-statements-expressions-etc)
    — the 0.1 bullets this design closes, including the "closed overloading"
    characterization
-   [Principle: static open extension](/docs/project/principles/static_open_extension.md)
    / Proposal
    [#998: One static open extension mechanism](https://github.com/carbon-language/carbon-lang/pull/998)
-   Proposal
    [#2875: Functions, function types, and function calls](https://github.com/carbon-language/carbon-lang/pull/2875)
    — Future work: Overloading (first-match intent, `match_first` model)
-   [Pattern matching](pattern_matching.md) / Proposal
    [#2188: Pattern matching syntax and semantics](https://github.com/carbon-language/carbon-lang/pull/2188)
    — declaration-order anticipation; overloads as a future refutable-pattern
    context
-   Proposal
    [#3763: Matching redeclarations](https://github.com/carbon-language/carbon-lang/pull/3763)
-   [Principle: information accumulation](/docs/project/principles/information_accumulation.md)
    / Proposal
    [#875](https://github.com/carbon-language/carbon-lang/pull/875)
-   [Generics goals: checked generics instead of open overloading and ADL](generics/goals.md#checked-generics-instead-of-open-overloading-and-adl)
-   [Interoperability: overload resolution](interoperability/README.md#todo-overload-resolution)
-   Fork decision
    [F-009: Function overloading — marked `overload fn`](/fork/decision-log.md)
    and the
    [design-sprint option paper](/fork/design-sprint/function-overloading.md)
-   Fork decision
    [F-010: template constraints](/fork/decision-log.md)
    (adopts this design's declaration-order/no-subsumption rule)
