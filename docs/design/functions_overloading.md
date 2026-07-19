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
-   [Open sub-forks](#open-sub-forks)
-   [References](#references)

<!-- tocstop -->

## Overview

_Function overloading_ lets several function definitions share one name, with
the callee chosen by the arguments at each call site. Carbon's overloading is
deliberately narrower than C++'s, in three ways that were each fixed by fork
decision
[F-009](/fork/decision-log.md#f-009-function-overloading--marked-overload-fn-2026-07-19):

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

**OPEN (sub-fork F-009m):** the position of `overload` relative to the other
declaration modifiers (`virtual`, `abstract`, `impl`) — no existing rule
determines it, and either order is defensible. Recommendation: `overload`
immediately after the access modifier and before the others, as in the
grammar line above, so the set marker is always leftmost after access.

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
declaration, with a note suggesting adding `overload` to the original
declaration. This "any single declaration reveals the set exists" property is
the point of the marker; see
[decision D1](#decisions-within-this-design).

**OPEN (sub-fork F-009a):** whether a set with exactly one member is legal —
that is, whether `overload fn F(...)` with no sibling declarations is valid.
Recommendation: yes; a single-member set is legal and behaves exactly like a
non-overloaded function at call sites, so that members can be added later (or
in a later version of the library) without touching the first declaration.

### The `overload` keyword

`overload` becomes a keyword. In the toolchain, it is one
`CARBON_KEYWORD_TOKEN` entry in `toolchain/lex/token_kind.def` (alphabetically
between `Or` and `Override`), a `CARBON_PARSE_NODE_KIND_TOKEN_MODIFIER` entry
in `toolchain/parse/node_kind.def`, plus a **new standalone modifier group**
with its own order slot in the `KeywordModifierSet` machinery
(`toolchain/check/keyword_modifier_set.h`) and validation in the `fn`
introducer state that rejects it on any other declaration kind. `overload`
cannot join the existing `Decl` group: the modifier checker permits at most
one modifier per order slot (`toolchain/check/handle_modifier.cpp`), and
`virtual`, `abstract`, and `impl` are all `Decl`-group, so a `Decl`-group
`overload` would reject `overload virtual fn` outright and foreclose
[sub-fork F-009d](#which-functions-may-be-overloaded). This otherwise mirrors
how `virtual` and `extern` are implemented today.

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
    another file resolves against the visible members only).
-   A Carbon `overload fn` declaration can never extend an imported C++
    overload set: the C++ header is a different library, and Carbon source
    cannot declare into the `Cpp` package. Imported C++ sets are specified in
    [C++ interoperability](#c-interoperability).
-   Open extension points remain the job of
    [interfaces](generics/goals.md#checked-generics-instead-of-open-overloading-and-adl).
    A design that needs callers to add cases for their own types should define
    an interface, not an overload set.

**OPEN (sub-fork F-009b):** whether all members must additionally be declared
in the same _file_. Recommendation: yes in 0.1 — every member of a set is
declared in one file (the API file, for a set visible outside the library;
sets declared wholly inside one implementation file are also fine), and
implementation files may _define_ members forward-declared in the API file but
not add members. This keeps a set's declaration order readable in one place
and avoids order questions between files; relaxing it later is purely
additive.

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
    rules as classes.

`overload` is not permitted on lambdas (they have no name to overload) or on
destructors.

**OPEN (sub-fork F-009l):** whether methods and non-method member functions
may share one set — C++ freely overloads static and non-static member
functions, and Carbon already permits calling a non-method member function
through an instance ([classes: non-methods](classes.md#non-methods)).
Recommendation: no in 0.1 — every member of a set either declares `self` or
does not — so that whether the receiver of `x.F(...)` participates in the
match test never varies by candidate.

**OPEN (sub-fork F-009c):** whether two method members may differ _only_ in
`self` shape (`self` versus `ref self`). Recommendation: no in 0.1 — members
of one set must be distinguishable by their parameters after `self`;
overloading on expression category parallels upstream's open issue
[#3154](https://github.com/carbon-language/carbon-lang/issues/3154) and is
deferred with it.

**OPEN (sub-fork F-009d):** whether `overload` composes with `virtual` (and
`abstract`/`impl`) on methods. Recommendation: yes; overload resolution
selects a member statically first, and virtual dispatch then applies to the
selected member — the "overload resolution should happen before virtual
dispatch" ordering already recorded in
[classes: overloaded member functions](classes.md#overloaded-member-functions).

**OPEN (sub-fork F-009e):** whether interface associated functions may be
overloaded. Recommendation: no in 0.1 — `overload` is not permitted inside
`interface` bodies, since overloaded associated functions interact with
witness tables and impl checking in ways nothing in the 0.1 milestone
requires.

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

**OPEN (sub-fork F-009k):** the diagnosis of a marked declaration whose
parameter list is type-identical to an existing member's without the
signatures being token-identical — for example, a binding-name-only
difference:
`overload fn G(x: i64);` then `overload fn G(y: i64) { ... }`.
Recommendation: an invalid redeclaration of that member, diagnosed at `D`,
preserving proposal #3763's parameter-name-typo diagnostic
([functions: redeclaration matching](functions.md#redeclaration-matching))
inside marked sets rather than silently creating an unreachable member.

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
    trade C++'s unmarked overloading loses on both counts.

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
next candidate", not "error":

1.  **Arity.** The number of arguments is within the candidate's accepted
    range; for method calls, the receiver binds to `self` and the
    parenthesized arguments are counted against the parameters after `self`.
    (The range is a single number today; it is specified as a range so that
    [variadic](variadics.md) members can join sets later without changing
    this algorithm.)
2.  **Deduction.** Values for the candidate's deduced and compile-time
    parameters are deduced from the argument types, per
    [generic call rules](functions.md#direct-calls). Deduction failure means
    the candidate does not match.
3.  **Constraints.** The deduced values satisfy the candidate's declared
    constraints — interface constraints on compile-time bindings, and, when
    the
    [template constraint](/fork/decision-log.md#f-010-template-structural-conformance--template-constraint--require-2026-07-19)
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

**OPEN (sub-fork F-009j):** Carbon-native default arguments. Carbon has no
default-argument design; overloading substitutes for the common cases, and
default arguments on _imported_ C++ functions keep working (they participate
in Clang-side resolution; see
[Importing C++ overload sets](#importing-c-overload-sets)). Recommendation:
no Carbon-native default arguments in 0.1, so the arity step above stays
exact and no interaction rule is needed; revisit as its own design fork if a
need appears.

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
    [F-010](/fork/decision-log.md#f-010-template-structural-conformance--template-constraint--require-2026-07-19)
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

**OPEN (sub-fork F-009f):** the depth of the no-match diagnostic. The two
defensible levels are a single "no matching member of overload set `F`"
error, or that error plus one note per candidate giving the first step of the
[match test](#the-candidate-match-test) that failed for it (Clang's style,
which Carbon users already see for imported C++ sets). Recommendation:
per-candidate first-failure notes from the start — the resolution loop
computes the failing step anyway, and C++ migrators will expect candidate
notes.

### Naming an overload set

In 0.1, an overload set may be named only as the callee of a
[direct call](functions.md#direct-calls) (including method calls, where the
bound-method machinery applies to the selected member).

**OPEN (sub-fork F-009g):** what any other use of the name is. Using a set as
a value (`var f: auto = Dist;`), asking for its type, or passing it as a
callable does not select a member — there are no arguments to resolve
against. Recommendation: hard compile error in 0.1, diagnosed as "an overload
set cannot be used as a value". The forward-compatible path is
[proposal #2875](/proposals/p002875-functions-function-types-and-function-calls.md)'s
model of an overload set as a single function type with one
[`Call` impl](functions.md#indirect-calls-and-the-call-interface) per member
in a `match_first` block, which would make sets first-class later without
changing any call-site semantics.

**OPEN (sub-fork F-009h):** whether `alias` may name an overload set, and
what it means. Recommendation: yes — an `alias` for the set's name aliases
the whole set as a unit (never an individual member), and re-export through
[`export import`](code_and_name_organization/README.md) carries the whole
set; the set stays closed, since an alias adds no members.

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
    `template` binding.

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
dispatch (including operator overloading via the `Core` operator interfaces)
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
resolution differs, never the algorithm.

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

**OPEN (sub-fork F-009i):** what happens when some members of an exported set
have signatures that cannot be mapped to C++ (a parameter type with no C++
mapping). Recommendation: export the exportable members and omit the rest —
matching how per-function export already behaves — so C++ sees a subset of
the set; a note-level diagnostic on the omitted members is desirable. The
alternative, refusing to export the whole set unless every member maps, would
make one exotic member remove an entire API from C++.

### Documented divergence: two resolution rules

The same argument list can resolve differently on the two sides of the
boundary, because Carbon call sites use first-match and C++ call sites use
best-viable-match. This divergence is **accepted and documented** rather than
restricted, per decision
[F-009](/fork/decision-log.md#f-009-function-overloading--marked-overload-fn-2026-07-19);
see [decision D5](#decisions-within-this-design). The two shapes it takes,
using the `Dist` set above (members declared `i64` first, `f64` second):

-   **Carbon resolves; C++ rejects.** With a 32-bit integer argument, Carbon
    selects the first member (`i32` converts to `i64`). A C++ call
    `Dist(int{4}, int{4})` is an **ambiguity error**: `int → int64_t` and
    `int → double` are equal-rank standard conversions under C++'s rules.
-   **The two sides pick different members.** For a set declared `f64` first,
    `i32` second, a Carbon call with an `i32` argument selects the _first_
    member (`i32 → f64` is a lossless
    [implicit conversion](expressions/implicit_conversions.md)), while the
    C++ call `Dist(int{4}, ...)` selects the _`i32`_ member: on supported
    targets `int` is `int32_t`, an exact match, which outranks the
    `int → double` conversion under C++'s rules.

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
names. The toolchain's mangler today derives names from the qualified name
plus a generic-specific fingerprint — plus, for library-private names only, a
fingerprint of the first declaration (`toolchain/sem_ir/mangler.cpp`) — so
two _public_ non-generic members of one set would collide; implementing this
design adds a signature fingerprint to the mangled name of overloaded
functions. Because members are required to have type-distinct parameter lists
(see [New member versus redeclaration](#new-member-versus-redeclaration)),
the signature fingerprint distinguishes every pair of members.
Exported members are unaffected by Carbon-internal mangling: their C++-side
declarations use the C++ ABI's own (signature-distinguishing) mangling, as
single-function export does today.

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
[F-009](/fork/decision-log.md#f-009-function-overloading--marked-overload-fn-2026-07-19),
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
[Open sub-forks](#open-sub-forks) and decided by the user, never silently by
this document.

## Alternatives considered

The alternatives for this area were researched in the option paper
([fork/design-sprint/function-overloading.md](/fork/design-sprint/function-overloading.md))
and rejected in fork decision
[F-009](/fork/decision-log.md#f-009-function-overloading--marked-overload-fn-2026-07-19):

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

## Open sub-forks

Per the fork's process rule that every sub-decision with more than one
defensible answer goes to the user
([fork/process.md](/fork/process.md#human-in-the-loop-rule)), the following
points are marked OPEN in the sections above and are **not** decided by this
document. Each is listed with this document's recommendation.

-   **F-009a — Single-member sets** (see
    [The `overload` modifier](#the-overload-modifier)): is `overload fn` with
    no sibling declaration legal? Recommendation: yes, to allow sets to grow
    without editing the first declaration.
-   **F-009b — Same-file rule** (see
    [Closed, same-library sets](#closed-same-library-sets)): must all members
    be declared in one file, with implementation files only defining?
    Recommendation: yes in 0.1.
-   **F-009c — `self`-shape overloading** (see
    [Which functions may be overloaded](#which-functions-may-be-overloaded)):
    may method members differ only in `self` shape (`self` versus
    `ref self`)? Recommendation: no in 0.1; the parameters after `self` must
    distinguish members.
-   **F-009d — `overload` with `virtual`** (see
    [Which functions may be overloaded](#which-functions-may-be-overloaded)):
    permitted? Recommendation: yes, with overload resolution before virtual
    dispatch.
-   **F-009e — Interface associated functions** (see
    [Which functions may be overloaded](#which-functions-may-be-overloaded)):
    overloadable? Recommendation: no in 0.1.
-   **F-009f — Diagnostic depth** (see [Diagnostics](#diagnostics)): single
    no-match error, or per-candidate first-failure notes? Recommendation:
    per-candidate notes.
-   **F-009g — Naming a set outside a call** (see
    [Naming an overload set](#naming-an-overload-set)): what does it mean?
    Recommendation: hard error in 0.1; first-class sets are future work.
-   **F-009h — `alias` and re-export** (see
    [Naming an overload set](#naming-an-overload-set)): does an alias name
    the whole set, transitively through `export import`? Recommendation: yes,
    whole-set and transitive.
-   **F-009i — Partially exportable sets** (see
    [Exporting Carbon overload sets to C++](#exporting-carbon-overload-sets-to-c)):
    export the exportable subset, or refuse the whole set? Recommendation:
    export the subset, with a note on omitted members.
-   **F-009j — Default arguments**: Carbon-native default arguments are
    undesigned, and overloading substitutes for the common cases; C++ default
    arguments remain supported on _import_ (they participate in Clang-side
    resolution). Recommendation: no Carbon-native default arguments in 0.1
    and no interaction rule to specify; revisit as its own design fork if a
    need appears.
-   **F-009k — Type-identical, token-different declarations** (see
    [New member versus redeclaration](#new-member-versus-redeclaration)): how
    is a marked declaration diagnosed whose parameter list is type-identical
    to an existing member's without the signatures being token-identical
    (for example, differing only in a binding name)? Recommendation: invalid
    redeclaration of that member, preserving proposal #3763's name-typo
    diagnostic.
-   **F-009l — Mixing methods and non-methods in one set** (see
    [Which functions may be overloaded](#which-functions-may-be-overloaded)):
    may members of one set differ in whether they declare `self`?
    Recommendation: no in 0.1; revisit if C++ static/non-static migration
    demands it.
-   **F-009m — Position of `overload` among declaration modifiers** (see
    [The `overload` modifier](#the-overload-modifier)): does `overload`
    precede or follow `virtual`/`abstract`/`impl`? Recommendation:
    immediately after the access modifier, before the others.

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
-   [Interoperability: overload resolution](interoperability/README.md#overload-resolution)
-   Fork decision
    [F-009: Function overloading — marked `overload fn`](/fork/decision-log.md#f-009-function-overloading--marked-overload-fn-2026-07-19)
    and the
    [design-sprint option paper](/fork/design-sprint/function-overloading.md)
-   Fork decision
    [F-010: template constraints](/fork/decision-log.md#f-010-template-structural-conformance--template-constraint--require-2026-07-19)
    (adopts this design's declaration-order/no-subsumption rule)
