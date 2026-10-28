# Template constraints

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
    -   [Structural, not nominal](#structural-not-nominal)
-   [Declaring a template constraint](#declaring-a-template-constraint)
    -   [The three `require` forms](#the-three-require-forms)
    -   [Member requirements](#member-requirements)
    -   [Validity blocks](#validity-blocks)
    -   [Boolean predicate requirements](#boolean-predicate-requirements)
    -   [Composing with named-constraint requirements](#composing-with-named-constraint-requirements)
-   [Using template constraints](#using-template-constraints)
    -   [Template bindings only](#template-bindings-only)
    -   [Anonymous predicates on bindings](#anonymous-predicates-on-bindings)
    -   [Name lookup](#name-lookup)
-   [Satisfaction](#satisfaction)
    -   [When satisfaction is checked](#when-satisfaction-is-checked)
    -   [Definition-time checking](#definition-time-checking)
    -   [Probe-mode evaluation](#probe-mode-evaluation)
    -   [Completeness and caching](#completeness-and-caching)
    -   [Structural witnesses](#structural-witnesses)
    -   [Diagnostics: no SFINAE](#diagnostics-no-sfinae)
-   [Constrained candidates and overload resolution](#constrained-candidates-and-overload-resolution)
-   [Mapping to and from C++20 concepts](#mapping-to-and-from-c20-concepts)
    -   [Import: C++ concepts as Carbon predicates](#import-c-concepts-as-carbon-predicates)
    -   [Export: Carbon constraints as C++ concepts](#export-carbon-constraints-as-c-concepts)
-   [Relationship to checked generics](#relationship-to-checked-generics)
    -   [Interfaces stay nominal](#interfaces-stay-nominal)
    -   [The migration ladder](#the-migration-ladder)
-   [Dependencies on unimplemented features](#dependencies-on-unimplemented-features)
-   [Alternatives considered](#alternatives-considered)
-   [Open sub-forks](#open-sub-forks)
-   [References](#references)

<!-- tocstop -->

## Overview

> **Fork amendment 2026-10-12 (F-010 / SC-1, fork/structural/plan.md):**
> member requirements are implemented — `template constraint` parses as a
> declaration modifier, method and associated-function requirements are
> declared in the constraint body and checked structurally at the
> facet-conversion chokepoint (`toolchain/check/structural_conformance.cpp`),
> with C++ classes satisfying them through their imported methods. Validity
> blocks, boolean predicates and `where require` are SC-B2 (W-028); the
> two-way C++20 concept mapping is SC-B3 (W-029). Four member forms are
> deferred past SC-1 and marked below: field requirements, associated-constant
> requirements, parameterized requirements and default definitions. Sections
> describing unimplemented parts keep their normative text; each
> SC-1-amended passage is marked in place.

A _template constraint_ is a named constraint that a type satisfies
_structurally_ — by having the right members, by supporting the right
expressions, and by making declared compile-time predicates true — rather than
by an explicit `impl` declaration. Template constraints are the mechanism behind
the 0.1 milestone requirement
([milestones](/docs/project/milestones.md#language-features)):

> Including template-style structural conformance to nominal constraints, both
> modeling the members (like interfaces) and arbitrary predicates (like C++20
> expression validity predicates)

The `template constraint` declaration itself was accepted in proposal
[#818](https://github.com/carbon-language/carbon-lang/pull/818) and given worked
semantics in proposal
[#2200](/proposals/p002200-template-generics.md#template-constraints); this
document completes it with the two extensions called for by proposal 2200's
[expanded template constraints](/proposals/p002200-template-generics.md#expanded-template-constraints)
future work — [validity blocks](#validity-blocks) and
[boolean predicate requirements](#boolean-predicate-requirements) — plus the
[satisfaction semantics](#satisfaction) that make constraints checkable and the
[two-way mapping to C++20 concepts](#mapping-to-and-from-c20-concepts).
Proposal 2200's other future-work direction,
[predicates on non-type parameter values](/proposals/p002200-template-generics.md#predicates-constraints-on-values),
is _not_ completed here and stays out of 0.1 scope; see
[Boolean predicate requirements](#boolean-predicate-requirements).

<!-- Links to /fork/decision-log.md carry no `#f-009-...`/`#f-010-...`
fragment: those headings contain an em dash, which the check-links hook
percent-encodes in a link but keeps raw in the heading's anchor, so no
spelling of the fragment validates (the functions_overloading.md convention).
-->

This design was fixed by fork decision [F-010](/fork/decision-log.md) and
depends on several unimplemented toolchain features; see
[Dependencies on unimplemented features](#dependencies-on-unimplemented-features).
Sub-decisions within this design that have more than one defensible answer are
not decided here: each is marked **OPEN (sub-fork)** in place and collected in
[Open sub-forks](#open-sub-forks) for user decision, per the fork's
[human-in-the-loop rule](/fork/process.md#human-in-the-loop-rule).

### Structural, not nominal

Carbon deliberately has two kinds of constraint entities
([terminology](terminology.md#structural-interfaces)):

-   [Interfaces](details.md#interfaces) are _nominal_: a type satisfies an
    interface only if an `impl` says so. This carries semantic meaning beyond
    structure and is the foundation of checked generics.
-   Template constraints are _structural_: a type satisfies one by its shape and
    properties alone, with no declaration anywhere tying the type to the
    constraint. They are "structural conformance to nominal constraints" in the
    milestone's sense — the _constraint_ is a nominal (named) entity; the
    _conformance_ to it is structural.

Template constraints exist for template code: migrated C++ templates constrain
their parameters by usage, not by implemented interfaces, and C++20 concepts and
`requires`-expressions must have an idiomatic Carbon spelling in both
[directions of interop](#mapping-to-and-from-c20-concepts). Checked generics
continue to use interfaces and (non-template) named constraints; template
constraints never blur that line — see
[Interfaces stay nominal](#interfaces-stay-nominal).

## Declaring a template constraint

A template constraint declaration is a
[named constraint](details.md#named-constraints) declaration with the `template`
keyword before `constraint`:

```carbon
template constraint Summable {
  // (1) Member requirements: modeling the members, like interfaces.
  fn Sum(self, other: Self) -> Self;
  var count: i32;

  // (2) A validity block: expression validity, like a C++20
  // requires-expression with parameters.
  require (x: Self, y: Self) {
    x + y;
    x.Print();
    let _: i64 = x.Size();
  }

  // (3) Boolean predicate requirements: nested requirements, like C++20
  // `requires`-clauses on compile-time boolean expressions.
  require Core.SizeOf(Self) <= 16;

  // Existing named-constraint requirement forms still compose.
  require impls Core.Destroy;
}
```

Like other named constraints, a template constraint may be forward-declared, may
be parameterized, may contain `alias` declarations, and follows the
[declaration and completeness rules](details.md#forward-declarations-and-cyclic-references)
for named constraints. A forward declaration and definition (or two
declarations) of one constraint must agree on `template`
(`NamedConstraintRedeclTemplateMismatch`; SC-1, D-SC-16; after the diagnostic
the constraint is treated as a template constraint). Member requirements may
only be declared inside a `template constraint`, never in a plain `constraint`
or in an `interface`'s
`require` clauses:
[#2200](/proposals/p002200-template-generics.md#template-constraints) admits
"function and field declarations" in a template constraint body, and
[details.md's named-constraint design](details.md#named-constraints) enumerates
the member kinds — methods, associated constants, and associated functions.

### The three `require` forms

All three new requirement forms reuse the existing `require` introducer that
named constraints already use for `require impls`:

-   `require (` _params_ `) {` _statements_ `}` — a
    [validity block](#validity-blocks).
-   `require` _expression_ `;` — a
    [boolean predicate requirement](#boolean-predicate-requirements).
-   `require impls ...`, `require ... impls ...` — the
    [existing named-constraint forms](details.md#named-constraints), unchanged.

Member requirements use no introducer at all; they are written as ordinary
declarations, mirroring how an `interface` body declares its members.

Parsing among these forms is deterministic with one exception. A
`require ... impls ...` requirement is distinguished from a predicate
requirement by the `impls` keyword following the expression. The prefix
`require (`, however, is ambiguous between a validity block and a predicate
whose expression begins with a parenthesized subexpression — for example,
`require (Core.SizeOf(Self)) <= 16;` — and the disambiguation rule has more
than one defensible spelling:

> **OPEN (sub-fork) F-010k — disambiguating `require (`.** Disambiguate by
> lookahead: after the lexer-matched closing `)`, a `{` token means a validity
> block, anything else a predicate expression (recommended: the lexer's
> pre-matched grouping tokens make this lookahead cheap and deterministic), or
> forbid predicate expressions that start with `(`, forcing such predicates to
> be rewritten without leading parentheses.

> **OPEN (sub-fork) F-010a — requirement introducer spelling.** Reuse `require`
> for the validity-block and predicate forms as shown (recommended: one
> introducer for all requirements, mirroring `require impls` and adding no
> keyword), or introduce a dedicated `requires`-style keyword closer to C++
> spelling.

### Member requirements

A member requirement is a declaration in the constraint body that the concrete
type must match. A concrete type `C` satisfies a member requirement if and only
if member lookup for the declared name _in `C` itself_ finds a declaration
matching the requirement after substituting `C` for `Self` — matching signature
for functions, matching type for fields and associated constants.

Two rules from
[#2200](/proposals/p002200-template-generics.md#template-constraints) are
load-bearing and normative:

-   **Members must be found by member lookup in the type.** A declaration
    provided only by an out-of-line (`extend`-less, external) `impl` does _not_
    satisfy a member requirement. An `alias` declared in the type's own scope
    does, when it names a member of the type:

    ```carbon
    interface A { fn F(self); }

    template constraint HasF {
      fn F(self);
    }

    class C {}
    impl C as A { fn F(self) {} }
    // ❌ `C` does not satisfy `HasF`: member lookup in `C` does not find `F`.

    class D {
      impl as A { fn F(self) {} }
      alias F = A.F;
    }
    // ✅ `D` satisfies `HasF`: member lookup in `D` finds `F`.
    ```

    As landed (SC-1, D-SC-5(c), clarified 2026-10-13): a requirement `fn` is a
    declaration of its constraint, not a member of any type, so an alias of the
    requirement itself, `alias F = HasF.F` in a class, finds no member and does
    not satisfy `HasF` (the note `StructuralMemberIsRequirement` says so); nor
    does a facet type used as the self, whose lookup finds only its own
    requirements. For the same reason a requirement implements no interface
    member: `impl C as A { alias F = HasF.F; }` is rejected with
    `ImplFunctionWithNonFunction`, as an alias of another interface's member is,
    while for a class that declares its own matching `F`, `alias F = (C as
    HasF).F` names that member and is accepted.

-   **Member requirements do not affect name lookup.** They guarantee a name
    will be found in the type; they do not change what it resolves to. See
    [Name lookup](#name-lookup).

Function requirements match modulo `Self` substitution: the requirement
`fn Sum(self, other: Self) -> Self` in `Summable` is satisfied by
`class Meters { fn Sum(self, other: Meters) -> Meters; }`. The matching criteria
are those of
[syntactic redeclaration matching](/proposals/p003763-matching-redeclarations.md)
applied between the substituted requirement and the found declaration, so the
same notion of "same signature" governs redeclarations, impl checking, and
structural matching. As landed (SC-1, D-SC-5(d) as amended 2026-10-14, fill
round 12), structural matching uses the comparison the toolchain applies to an
impl member and its interface member, in which a `self` parameter is compared as
a parameter of the self type, and adds one check: a requirement with `self`
needs a member with `self`. It so departs from redeclaration matching, which
would reject a method for `fn Get(x: Self)`, and from impl checking, which
accepts a member without `self` for `fn Get(self)`. Like both, it does not
compare the form of the return: a member `fn Get(self) -> i32` satisfies `fn
Get(self) -> ref i32`, as an impl member satisfies such an interface member and
a definition redeclares such a declaration (D-SC-5(d) as amended 2026-10-14,
fill round 14). As landed (SC-1, D-SC-5): the found member must resolve to
exactly one function (an `overload fn` set, a field, a class or a namespace
does not satisfy; a C++ overload set does only when it holds exactly one
candidate), it must be accessible from the use site (a `private` member
satisfies only from inside its own class), and the signature comparison is the
toolchain's redeclaration matcher with parameter names ignored and both sides
read in their own specifics (a member of a generic class specific such as
`Box(i32).Get` is compared after substitution). The `self` form is part of the
signature: `fn Get(self)` does not match `fn Get(ref self)`. A requirement with
`self` needs a member with `self`: a member function whose first parameter has
the self type does not satisfy `fn Get(self)`, since it cannot be called as
`x.Get()`; a requirement without `self`, `fn Get(x: Self)`, is satisfied by a
method, whose `self` takes the first parameter's place when `T.Get(x)` calls it
(D-SC-5(d) as amended 2026-10-14, fill round 12). A default
definition (a requirement with a body) is a semantics TODO in SC-1 ("function
definition in `template constraint`"); a `fn` in a plain, non-`template`
`constraint` is an error. A requirement with a tuple pattern parameter,
directly, under `var` or under a default value, is a semantics TODO too ("tuple
pattern parameter in `template constraint`") and is not collected, since the
toolchain's signature comparison has no case for a tuple pattern (W-234). Since
fill round 15, so is one with an expression pattern parameter, directly, under
`var` or under a default value ("expression pattern parameter in `template
constraint`"): an expression pattern in a parameter list is a semantics TODO of
its own, and the comparison has no case for two of them (W-238).

> **F-010l — parameterized member requirements: DEFERRED (SC-1, D-SC-2, as
> recommended).** Whether a requirement declaration may itself be a `template`
> or otherwise parameterized function, matching correspondingly parameterized
> members, is not settled by any accepted proposal: neither proposal 818 nor
> [#2200](/proposals/p002200-template-generics.md#template-constraints)
> mentions them, C++20 `requires`-expressions cannot render them (so the
> [export mapping](#export-carbon-constraints-as-c-concepts) has no row for
> them and their interaction with the F-010i opaque hook is unaddressed), and
> matching parameterized declarations has real implementation cost. SC-1
> diagnoses a requirement `fn` with compile-time bindings of its own as a
> semantics TODO ("parameterized requirement in `template constraint`") and
> does not collect it as a requirement; filed as a ledger residue (W-136).

Field requirements (`var count: i32;` above) are satisfied by a field of exactly
the declared name and type. They exist because migrated C++ code constrains on
data members and C++ `requires`-expressions can test them; interfaces have no
counterpart
([field requirements are interface future work](details.md#field-requirements)).

> **F-010b — field requirements in 0.1: DEFERRED past SC-1 (D-SC-2), AGAINST
> this page's recorded recommendation.** The recommendation was to keep `var`
> field requirements from the first stage
> ([#2200's design includes them](/proposals/p002200-template-generics.md#template-constraints)
> — "function and field declarations" — migrated C++ uses them, and the cost is
> small); SC-1 restricts constraint bodies to function requirements and
> diagnoses a `var` member as a semantics TODO ("field requirement in
> `template constraint`"), because a field match needs its own type-equality
> path (`FieldDecl`, not the function matcher), nothing in the conformance
> arbiter needs it, and SC-B2's validity blocks are the natural second
> consumer. Veto-able after the fact; filed as a ledger residue (W-134).
> Associated-
> constant requirements (`let X: type;`) are deferred the same way, which
> NARROWS [details.md's enumeration](details.md#named-constraints) ("method,
> associated constant, and associated function requirements") on an
> implementation-cost ground: the interface form routes through the
> associated-constant introducer in interface context only, so a constraint
> body has no parse for it today. Also veto-able; also filed (W-135).

### Validity blocks

A validity block is the Carbon spelling of a C++20 `requires`-expression with a
parameter list: it introduces hypothetical values and requires a sequence of
statements to be valid for the concrete type.

```carbon
template constraint Buffer {
  require (b: Self, n: i64) {
    // Simple requirements: the expression must type-check.
    b.Data();
    b[n];

    // Compound requirement with a result-type constraint: the expression
    // must type-check and its result must implicitly convert to `i64`.
    let _: i64 = b.Size();

    // Type requirement: the designated member must be a type.
    let _: type = Self.ElementType;
  }
}
```

Semantics:

-   The parameter list declares names usable inside the block, each denoting a
    value of its declared type (which may involve `Self`). Parameters are
    hypothetical: no values are ever created, and nothing in the block is ever
    executed or lowered.
-   The requirement is satisfied for a concrete type `C` if and only if every
    statement in the block would type-check with `C` substituted for `Self`,
    under [probe-mode evaluation](#probe-mode-evaluation).
-   A `let` with a declared type is the compound-requirement form: it
    additionally requires the initializer's type to implicitly convert to the
    declared type. `let _: type = ...;` is the type-requirement form. This gives
    all four C++20 requirement shapes a spelling: simple requirements
    (expression statements), type requirements, compound requirements with
    return-type constraints, and — by way of
    [predicate requirements](#boolean-predicate-requirements) — nested
    requirements.

> **OPEN (sub-fork) F-010c — statement forms permitted in a validity block.**
> Permit exactly expression statements and `let` declarations (recommended: the
> minimal set that covers all four C++20 requirement shapes and keeps the
> [export mapping](#export-carbon-constraints-as-c-concepts) total), or permit
> the full statement grammar (`var`, `if`, loops, ...) inside validity blocks.

### Boolean predicate requirements

A predicate requirement is `require` followed by a compile-time boolean
expression:

```carbon
template constraint SmallRegular {
  require Core.SizeOf(Self) <= 16;
  require Cpp.MyConcept(Self);
}
```

The requirement is satisfied for a concrete type `C` if and only if the
expression, with `C` substituted for `Self`, constant-evaluates to `true` under
[probe-mode evaluation](#probe-mode-evaluation). The expression may use any
compile-time-evaluable Carbon expression, including calls to compile-time
functions and
[imported C++20 concepts](#import-c-concepts-as-carbon-predicates). This is the
C++20 nested requirement (`requires sizeof(T) > 4;`) and `requires`-clause
conjunct, generalized to arbitrary Carbon compile-time evaluation.

(`Core.SizeOf` here stands for the prelude's compile-time size query; its final
prelude spelling belongs to the prelude design, not to this document.)

Predicates over non-type template parameter _values_ (for example, an array
bound that must be nonnegative) are **out of 0.1 scope and remain future work**,
as [details.md](details.md#value-constraints-for-template-parameters) records:
this document defines `require` requirements only inside `template constraint`
bodies and in [`where require` clauses](#anonymous-predicates-on-bindings) on
facet types, and specifies no attachment position for value predicates. Upstream
tracks that direction as
[#2200's predicates future work](/proposals/p002200-template-generics.md#predicates-constraints-on-values)
and
[leads issue 2153](https://github.com/carbon-language/carbon-lang/issues/2153).

> **OPEN (sub-fork) F-010d — predicate expression type.** Require the predicate
> expression to be exactly of type `bool` with no implicit conversion
> (recommended: matches C++20 atomic-constraint rules, keeping the
> [export mapping](#export-carbon-constraints-as-c-concepts) exact and avoiding
> surprise conversions in satisfaction logic), or accept any expression
> implicitly convertible to `bool` as in `if` conditions.

### Composing with named-constraint requirements

The existing named-constraint requirement forms compose freely inside a template
constraint: `require impls I` requires a nominal implementation of `I`,
`require X impls Y` constrains related types, and
[`where` clauses](details.md#where-constraints) apply as in any named
constraint. A template constraint may also require another template constraint
with `require impls`, meaning the other constraint's requirements are included.
The [self-reference](details.md#named-constraints) and
partially-identified-`Self` rules of named constraints apply unchanged.

Combining a template constraint with other facet types using
[`&`](details.md#combining-interfaces-by-anding-facet-types) is permitted and
yields a facet type that is usable
[only on template bindings](#template-bindings-only), since one of its operands
is.

## Using template constraints

### Template bindings only

A template constraint may be used wherever a facet type may be used — as the
type of a binding, as an operand of `&`, as a namespace for
[qualified member names](#name-lookup) — but a binding whose facet type involves
a template constraint must be a `template` binding:

```carbon
// ✅ Template binding constrained by a template constraint.
fn Accumulate[template T: Summable](s: Slice(T)) -> T;

// ❌ Error: checked binding may not use a template constraint.
fn Bad[T: Summable](s: Slice(T)) -> T;
```

Using a template constraint on a checked-generic binding is an error in 0.1
(landed: `TemplateConstraintOnNonTemplateBinding` at the binding, SC-1
D-SC-8; a checked-generic argument passed to a template-constrained binding is
likewise rejected at the checked function's definition with the note
`StructuralRequirementNeedsConcreteType`, D-SC-6). This resolves upstream's
open question
([leads issue 2153](https://github.com/carbon-language/carbon-lang/issues/2153))
conservatively, in the direction
[#2200](/proposals/p002200-template-generics.md#template-constraints) already
commits to: even if checked bindings later admit template constraints, member
lookup through a checked binding will never find structural members, so nothing
is lost in 0.1 by rejecting the combination outright, and permitting it later is
purely additive.

> **RG-1 note (2026-10-28).** Upstream records leads issue 2153 as decided, not
> open: "We have decided to support passing a symbolic constant to a template
> parameter" (upstream docs/design/generics/overview.md:375-379), an approach
> that "relies on monomorphization" (appendix-witness.md:151-154). The
> definition-time rejection described above is therefore a drift under the
> fork's rulebook R32 (d), W-139, which SC-1 realigns on this branch before it
> lands; this paragraph is rewritten with it.

One further use of plain named constraints does not carry over cleanly: a type
may [`impl` a plain named constraint](details.md#named-constraints), but an
impl's members cannot satisfy a template constraint's member requirements, since
[member lookup in the type itself must find them](#member-requirements) —
[#2200](/proposals/p002200-template-generics.md#template-constraints) points to
an adapter, not an impl, for supplying missing members.

> **F-010m — `impl ... as` a template constraint: RESOLVED as an error (SC-1,
> D-SC-8, as recommended).** `impl ... as SomeTemplateConstraint` is rejected
> (`ImplOfNotOneInterface`, pinned by a check golden): structural conformance
> is never declared, and member requirements are unsatisfiable from an impl
> body, so allowing the declaration only for its nominal residue would invite
> confusion. The rejected alternative was to define it as implementing exactly
> the constraint's nominal `require impls` requirements. An `impl ... as I &
> SomeTemplateConstraint` is accepted without a structural check of the impl's
> self in SC-1 (filed as a residue, W-142).

### Anonymous predicates on bindings

A one-off requirement on a single binding should not force declaring a named
constraint. A `where` clause on a binding's facet type may carry a `require`
requirement directly:

```carbon
// Anonymous predicate requirement.
fn Pad[template T: type where require Core.SizeOf(.Self) < 8](x: T) -> i64;

// Anonymous validity requirement.
fn Sort[template T: type where require (a: .Self, b: .Self) { a < b; }]
    (s: Slice(T));
```

The `where require ...` clause attaches the requirement to the facet type
exactly as if it were declared in a template constraint body: `.Self` in the
clause names the constrained type exactly as `Self` does in a constraint body,
the standard correspondence that `.Self` outside a constraint is the same as
`Self` inside it
([#818](/proposals/p000818-constraints-for-generics-generics-details-3.md#inline-constraints-instead-of-self)).
Like every constraint in a `where` clause, a `require` clause must use a
designator such as `.Self` — not the binding's own name, which is not an
earlier name at that point — per the
[designator rule](details.md#constraints-must-use-a-designator) of
[#2376](/proposals/p002376-constraints-must-use-self.md). The
resulting facet type is template-only as [above](#template-bindings-only).

> **OPEN (sub-fork) F-010e — anonymous `where require` on bindings.** Bless the
> `where require ...` binding form (recommended: C++20 allows `requires`-clauses
> and ad-hoc `requires requires` directly on templates, and migration should not
> force naming every one-off constraint), or require every structural/predicate
> requirement to live in a named `template constraint`.

### Name lookup

Name lookup into a constrained template binding follows the constrained-template
rule of
[leads issue 949](https://github.com/carbon-language/carbon-lang/issues/949)
and [#2200](/proposals/p002200-template-generics.md#name-lookup): names are
looked up both in the constraint and in the concrete type, and it is an error if
they resolve to different entities that cannot be merged. Member requirements
guarantee that a name _will_ be found in the concrete type; they do not redirect
lookup. Qualified access through the constraint — `x.(Summable.Sum)(y)` —
resolves to the concrete type's own member: the base type is converted to the
constraint's facet type (the satisfaction check) and the requirement's name is
then looked up in the base type, the semantics
[proposal 2200](/proposals/p002200-template-generics.md#template-constraints)
states ("`C.F` and `HasF.F` refer to the same function"); see
[Structural witnesses](#structural-witnesses). As landed, an associated-function
requirement is not yet redirected through a facet that is symbolic because the
constraint's arguments name a checked generic's parameter (`C.(Has(T).N)()`) or
because the constraint is declared in another constraint's or an interface's
body (`C.(Outer.Inner.N)()`): the compound access is a TODO (W-232), and `(C as
Has(T)).N` keeps the requirement; a method requirement reached through a value,
`c.(Has(T).Get)()`, is redirected (fill round 8). A requirement is never itself
the callee: `HasCount.Count()` names it with no type to satisfy it and is
rejected with `StructuralRequirementUsed`, as is a call through a runtime facet
value or through a self whose lookup finds only the requirement (D-SC-4, as
landed at the 2026-10-13 fill rounds). Named with no such type, as
`HasCount.Count`, the requirement has a type of its own that does not depend on
the constraint's `Self`, as an interface's `I.F` names an associated entity of a
concrete type (D-SC-20, as amended at fill round 5). That type can be named with
`typeof` and used as a type, but it has no values: passing `HasCount.Count` to a
function, putting it in a tuple or struct, naming it as a statement, binding a
value parameter of its `typeof`, or doing any of these in a template
instantiated with a facet type, is the same error, as is a bound method of a
requirement found through a checked generic binding. An object of that type,
such as a class field, exists without being a value: it is destroyed with its
enclosing object, and binding it to a `ref` parameter, calling a `ref self`
method on it, or reaching it through a pointer reads no value and is accepted,
while reading it as a value is the same error, and so is reading a value of a
tuple, struct or array that holds it, or of the type under `const`. A class
value with such a field is accepted, but a field accessed through a class value
is read as a value, so a field that is or holds the type is reached through a
reference to the object, in a `ref self` method rather than a value one. A `var`
parameter of the type can be declared, and each call, which initializes it from
a value, is the same error. A value typed by a generic parameter that is bound
to that type is an empty value and is accepted; in a template it is accepted
only where its conversion records no action, such as a `let` of the parameter's
type, while a call argument or a `var` initializer of it is refused when the
template is instantiated (D-SC-20, as amended at fill rounds 6 and 7). Named
through a type that satisfies it, as `C.(HasCount.Count)`, it is that type's own
function and is a value like any other (D-SC-20, as amended at fill round 4).

## Satisfaction

### When satisfaction is checked

Satisfaction is checked wherever a concrete type is converted to a facet type
that includes template-constraint requirements — the same conversion point at
which nominal facet-type conversion performs implementation lookup. In
particular:

-   At a call to a constrained template function with concrete arguments: after
    deduction, each deduced or explicit argument is converted to its binding's
    facet type; unsatisfied requirements reject the call.
-   At instantiation of a constrained parameterized type with concrete
    arguments.
-   When the argument is itself template-dependent (a constrained template used
    inside another template), the satisfaction check is deferred to the
    enclosing template's instantiation, exactly as other template-dependent
    checking defers.

Consistent with the
[information accumulation principle](/proposals/p000875-principle-information-accumulation.md),
a satisfaction check uses only information available at the point where it runs;
satisfaction never requires whole-program knowledge.

As landed (SC-1, D-SC-3): the check runs inside the toolchain's impl-witness
lookup (`LookupImplWitness`, reached from the facet-conversion chokepoint in
`toolchain/check/convert.cpp`) and nowhere else, so every entry point that
converts a concrete type to a facet type — a call after deduction, a class
parameter, a `require impls` clause checked for a concrete implementer —
observes the same answer. A template-dependent argument reaches the chokepoint
by replay of the enclosing call or conversion action at instantiation, with a
concrete type, so no new deferral mechanism exists. One eager entry point does
see a template-phase `Self`: the `require` check of a template blanket impl (`impl
forall [template T: type] T as I {}` for an `I` that requires a template
constraint) is deferred — structurally satisfied for now, with every use of a
structural member inside the impl checked at monomorphization, and the bare
`require` clause not re-run per specific in SC-1 (D-SC-19; filed as a residue).
One entry point waits instead: a `require` naming a template constraint whose
self is a class still being defined — typically `impl as I` inside the class,
for an `I` that requires a template constraint — has its structural part checked
when that class's definition ends (or that union's, a union being a class),
since a class is incomplete within its definition
([F-010h](#completeness-and-caching)), while the interfaces the same `require`
names are checked at the impl, as for any nominal `require` (D-SC-8(iii),
amended 2026-10-13). An impl inside a generic class has the checked-symbolic
self `Box(T)` and is rejected at the class end (D-SC-6; W-139).

### Definition-time checking

Every requirement in a template constraint is type-checked once, at the
constraint's definition, with `Self` as a symbolic type — exactly as a template
function body is checked at its definition. Errors found at this point (an
unknown name that does not involve `Self`, an ill-formed expression that no
substitution could repair) are hard errors of the constraint definition itself,
not deferred to satisfaction checks. Definition-time checking produces, for each
requirement, the residue of checks that depend on the concrete type; those are
what [probe-mode evaluation](#probe-mode-evaluation) replays.

As landed (SC-1, D-SC-10 as amended at fill rounds 7 and 8): `Self` in a
template constraint is a checked-phase binding, as in a `constraint`, so a
requirement's signature is checked at the definition as an interface member's
is. Two kinds of signature that this section makes valid are therefore
rejected (W-169). A member access into `Self`, of a requirement or of an alias
(`fn M(p: typeof(Self.N)*)`, `-> Self.A`), is rejected as `Self.N` is in an
interface being defined. A use of `Self` that must satisfy a facet type the
constraint does not itself require (`Box(Self)` for `class Box(T: J)`,
`Self.(J.Elem)`, `Core.Slice(Self)`, `Core.Optional(Self)`) is rejected as not
satisfying it. A third kind, a requirement named unqualified in another's
signature (`fn M(p: typeof(N)*)`), has never been satisfiable, with either
phase of `Self`: it is accepted, but it names the requirement's own function for
the satisfying type, which no member's type is, so no type satisfies the
constraint (W-169). Requiring the facet type that
`Self` must satisfy lets the signature name it: `require impls J` for
`Box(Self)` and `Self.(J.Elem)`, and `require impls Core.Copy & Core.Destroy`
for `Core.Slice(Self)` and `Core.Optional(Self)` (`Core.Optional` through its
blanket `OptionalStorage` impl). Requiring a template constraint does not, since
a checked-symbolic self never satisfies one (D-SC-6), and a member access into
`Self` has no such workaround. A member is compared with a requirement rejected
this way, or with any requirement when its own declaration has an error, by one
rule: it satisfies the requirement exactly when the signature comparison holds.
When it does not, nothing more is reported if the comparison would hold with
each erroneous type and each erroneous default value of either declaration
counted as equal to the type or default value in its place in the other: a type
with an error anywhere in it is the error, and so is a default value of a
parameter whose type is the error. A parameter declared with a form that has an
error (`y:? form(ref Undefined)`) is the error itself and counts as equal to the
parameter in its place, binding form included. A `self` declared with a form
that has an error declares no `self`, and the check that a requirement with
`self` has a member with `self` runs first, so a member with one is reported as
a member without `self`, and a requirement with one is a requirement without
`self` whose first parameter is that erroneous `self`, the error itself, which
counts as equal to the parameter in its place, a method's `self` included, so a
member without that leading parameter has one parameter fewer and is reported
(stated 2026-10-14, fill rounds 15 and 16). Everything else is compared as
without the error, including the binding form (`var`, `ref`) of any other
parameter with an error and whether a default value or a return type is there; a
member that differs so is reported as without the error. A member that matches
only through an error gets no diagnostic of its own, the error having been
reported, and the type's other requirements, constraints and interfaces are
still checked and reported. Such a silent failure is still a failure for a
direct use, an overload probe and a blanket impl (W-233) (D-SC-9 as amended
2026-10-14, fill rounds 9 to 14). A `require` whose facet type takes `Self` as
an argument (`require Self impls Conv(Self)`, `require impls Has(Self)`), which
a template-phase `Self` rejected, is accepted. Deferring the checks that involve
`Self`, as this section describes, needs a template-phase `Self`, which SC-B2
takes up with validity blocks (W-028).

### Probe-mode evaluation

Satisfaction of validity blocks and predicate requirements is defined by
_probe-mode evaluation_:

> To check a requirement for a concrete type `C`, the implementation replays the
> requirement's deferred checks with `C` substituted for `Self`, with
> diagnostics _captured_ instead of emitted. If every check succeeds (and, for a
> predicate, the expression evaluates to `true`), the requirement is satisfied.
> If any check fails, the requirement is unsatisfied, and the captured
> diagnostic is retained as the _reason_ for use in
> [diagnostics](#diagnostics-no-sfinae). A probe performs compile-time
> evaluation only — including the constant evaluation its predicate expression
> requires — but never executes runtime code, never lowers or emits object
> code, and never commits semantic effects to the program.

Probe-mode evaluation is a compile-time query, not an error-recovery mechanism:
outside a satisfaction check, the same failures remain ordinary hard errors.
This is the disciplined replacement for SFINAE — validity is tested only where a
declared requirement asks for it, and everywhere else errors stay errors.

Two boundary rules govern what a probe may absorb:

-   **Probe depth.** A probe captures failures in the requirement's own checks —
    the type-checking of the requirement's statements and the evaluation of its
    predicate expression. If performing those checks requires instantiating some
    other template or evaluating some other entity's body, and _that_ fails, the
    failure is not part of the requirement's immediate context.

    > **OPEN (sub-fork) F-010f — probe capture depth.** Treat failures outside
    > the requirement's immediate context (inside instantiations or compile-time
    > function bodies the probe triggers) as hard errors that escape the probe
    > (recommended: this is C++'s proven immediate-context rule; absorbing deep
    > failures turns genuine bugs into silent "unsatisfied" answers and is
    > costly to implement transactionally), or have the probe absorb all
    > failures so that satisfaction checks can never surface an error.

-   **Probe observability.** A probe has no _semantic_ effects: it does not
    change the meaning of any program construct. Compilation _caches_ that the
    probe warms or populates (instantiation caches, imported-declaration caches,
    name-poisoning records) may retain state.

    > **OPEN (sub-fork) F-010g — probe side-effect contract.** Specify
    > "implementation-defined caching effects, no semantic effects"
    > (recommended: C++ accepts the same wart in instantiation and satisfaction
    > caching, and full isolation would require transactional rollback of the
    > checking state), or demand fully isolated probes with no observable trace
    > of any kind.

### Completeness and caching

> **F-010h — satisfaction and type completeness: RESOLVED as "require
> completeness" (SC-1, D-SC-5(a), as recommended).** The concrete type must be
> complete at a satisfaction check; an incomplete type is diagnosed as a hard
> error at a diagnosing conversion (the incomplete-type error with the context
> note `StructuralRequirementIncompleteType`) and is silently unsatisfied in a
> non-diagnosing probe. Rationale: satisfaction of a structural constraint by
> an incomplete type is unstable — members appear as the definition is seen —
> and C++'s incomplete-type concept behavior is a known trap; stricter is
> simpler and can be revisited on evaluator feedback. The rejected alternative
> was to mirror C++ and check against whatever is visible, with the answer
> frozen at first use.

Satisfaction results are not cached in SC-1 (D-SC-7): the check is linear in
the constraint's requirement count and runs once per conversion site, and the
impl-lookup cache (keyed by self and interface) does not apply to it. Every use
site still observes the same answer, coherent by construction under F-010h's
resolution, since the answer is computed only from a complete type. A cache
keyed by identified facet type and self is the recorded fallback if a measured
compile-time regression appears.

### Structural witnesses

There is no structural witness table (SC-1, D-SC-4; this section replaces the
design record's "impl-witness-shaped table"). Satisfaction of member
requirements is a boolean check at the conversion; the facet value a satisfied
conversion produces carries only the interface witnesses its facet type lists —
an empty witness list for a pure template constraint, the shape a conversion to
an empty plain `constraint` already has — so lowering is untouched. The
"structural witness" of a type is the type's own member set:

-   Qualified access `x.(Summable.Sum)(y)` converts the base type to the
    constraint's facet type (the check) and then performs member lookup of the
    requirement's name in the base type, binding the type's own member — the
    semantics
    [proposal 2200](/proposals/p002200-template-generics.md#template-constraints)
    states by name ("`C.F` and `HasF.F` refer to the same function"). For an
    associated-function requirement, one with no `self`, the base itself is
    converted, as for an interface's non-instance member: `C.(HasMake.Make)()`
    and a template's `T.(HasMake.Make)()` call the type's own `Make` (D-SC-4,
    as landed at the 2026-10-13 fill rounds).
-   The [migration ladder](#the-migration-ladder) step from a template
    constraint to a blanket interface `impl` needs no table either: inside
    `impl forall [template T: TheConstraint] T as TheInterface`, each forwarded
    member is a template-dependent member access replayed with the concrete
    type at instantiation.

A table keyed on the constraint is the recorded extension point if a consumer
appears — SC-B3's concept export, or a blanket impl wanting `T.(HasF.F)` as a
constant — and would hang off the identified facet type, not the witness list.
No witness has runtime existence in 0.1; template instantiation resolves every
access statically, in keeping with templates having no dynamic dispatch.

### Diagnostics: no SFINAE

An unsatisfied constraint at a use site is a hard, precisely-located error —
never a silent removal of meaning. Per the
[generics goals](goals.md#better-compiler-experience) and
[#2200's no-SFINAE rationale](/proposals/p002200-template-generics.md#sfinae),
the diagnostic names the constraint, the first unsatisfied requirement in
declaration order, and the captured reason for its failure — for a validity
block, the failing statement's captured diagnostic; for a predicate, its value
or evaluation failure; for a member requirement, the missing or mismatched
member. Carbon has no SFINAE: substitution failure outside a declared
requirement's probe is an error, and constraints filter
[overload candidates](#constrained-candidates-and-overload-resolution) _before_
instantiation rather than discarding failed instantiations after. As landed
(SC-1, D-SC-9), the error is the existing conversion failure ("cannot convert
type `C` into type implementing `HasGet`") with notes for the first unsatisfied
requirement in declaration order: `StructuralMemberMissing`,
`StructuralMemberMismatch` (at the found member),
`StructuralMemberInaccessible` or `StructuralMemberIsRequirement` (lookup found
the requirement itself), each followed by `StructuralRequirementHere` at the
requirement; for a checked-generic self the single note
`StructuralRequirementNeedsConcreteType` is attached instead. A call whose
callee is a requirement, or any other use of a requirement as a value, is the
error `StructuralRequirementUsed` ("can only be used through a type that
satisfies it"; [Name lookup](#name-lookup)).

## Constrained candidates and overload resolution

Function overloading in Carbon is fixed by fork decision
[F-009](/fork/decision-log.md):
marked `overload fn` sets, closed per library, resolved by declaration-order
first-match. This design adopts that rule for constrained candidates, verbatim:

-   During overload resolution, a candidate whose template-constraint or
    predicate requirements are unsatisfied for the call's arguments is
    _skipped_, exactly as a candidate whose parameter types do not match is
    skipped. Checking a candidate's constraints is a
    [probe](#probe-mode-evaluation); its failure diagnostics are captured as
    per-candidate notes for the no-viable-candidate error.
-   The first candidate in declaration order whose signature matches _and_ whose
    constraints are satisfied wins. Candidates after the first match are never
    examined.
-   **There is no subsumption.** Carbon does not partially order candidates by
    constraint specificity as C++20 does; more-constrained does not mean
    preferred. Ordering among constrained overloads is expressed by declaration
    order alone — the same explicit-ordering choice Carbon already made for
    `match_first` impl blocks. Migrated C++ overload sets that rely on
    subsumption partial ordering must be reordered most-specific-first; this is
    a documented, conformance-tested divergence from C++ resolution, of the same
    kind F-009 documents for conversion ranking.

If a call site has exactly one candidate (no overloading), an unsatisfied
constraint is simply the hard error described [above](#diagnostics-no-sfinae).
These rules are operative: F-009's `overload fn` sets landed (OV-1 to OV-3),
and a `[template T: HasGet]` member of a set is probed without diagnostics, so
an unsatisfied structural requirement skips the member silently (SC-1,
D-SC-12; pinned by a check golden and by the conformance program
fork/conformance/programs/generics/structural_conformance.carbon's two-member
`Pick` set).

## Mapping to and from C++20 concepts

The 0.1 milestone requires "mapping C++20 concepts into named predicates, and
named predicates into C++20 concepts"
([milestones](/docs/project/milestones.md#language-features)). Template
constraints are Carbon's named predicates; the mapping is specified here and
delivered with the interop workstream (see
[Dependencies](#dependencies-on-unimplemented-features)).

### Import: C++ concepts as Carbon predicates

An imported C++20 concept is usable from Carbon as a compile-time boolean
predicate: `Cpp.MyConcept(T)` evaluates concept satisfaction through the
embedded Clang and yields a Carbon `bool`. This composes directly with this
design's [predicate requirements](#boolean-predicate-requirements):

| C++20 construct                             | Carbon                                                                                                                                                         |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MyConcept<ConcreteType>`                   | `Cpp.MyConcept(ConcreteType)` — evaluates to `bool`                                                                                                            |
| Concept constraining a template             | `fn F[template T: type where require Cpp.MyConcept(.Self)](...)` or `require Cpp.MyConcept(Self);` in a template constraint; dependent uses defer to instantiation |
| `requires`-expression inside a C++ header   | Evaluated by Clang as part of the concept it appears in; not re-modeled in Carbon                                                                              |
| `std::enable_if`, `void_t`, detection idiom | Migrate to a `template constraint`; Carbon has no SFINAE ([#2200](/proposals/p002200-template-generics.md#sfinae))                                             |

Two limitations are inherent to the import direction and stated plainly:

-   Clang can only check satisfaction for types it can represent. Evaluating an
    imported concept on a _Carbon_ class type requires the type to first be
    exported into the shared Clang AST — the same machinery gap as instantiating
    C++ templates on Carbon types, and part of the same interop workstream.
-   An imported concept is a predicate, not a template constraint: it brings no
    member requirements (see [Structural witnesses](#structural-witnesses)).
    Code that wants member modeling writes a template constraint whose
    requirements include the concept.

### Export: Carbon constraints as C++ concepts

An exported template constraint appears to C++ as a genuine C++20 concept —
interop synthesizes a `ConceptDecl` in the shared Clang AST, not textual headers
— with each requirement rendered in its C++ shape:

| Carbon construct                                                                              | Exported C++20 form                                                                                                                            |
| --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Member function requirement `fn Sum(self, other: Self) -> Self;`                              | Compound requirement: `requires(T x, T o) { { x.Sum(o) } -> std::same_as<T>; }`                                                                |
| Field requirement `var count: i32;`                                                           | Compound requirement on the member: `{ x.count } -> std::same_as<std::int32_t&>;`                                                              |
| Validity block `require (x: Self) { ... }`                                                    | The corresponding `requires`-expression, statement by statement; a `let _: R = e;` line renders as `{ e } -> std::convertible_to<R'>;`         |
| Predicate requirement `require <expr>;` whose operations all have C++ renderings              | Nested requirement with the rendered expression                                                                                                |
| Predicate requirement with Carbon-only semantics (compile-time Carbon calls, `impls` queries) | Nested requirement on an opaque satisfaction hook that calls back into the Carbon compiler's checking of the original constraint               |
| `interface I` (nominal)                                                                       | A concept over the nominal query only — satisfied exactly when a visible `impl` exists — deliberately _not_ a structural `requires`-expression |

The last row preserves the
[nominal/structural boundary](#interfaces-stay-nominal) across the language
boundary: a C++ user of an exported interface-concept sees nominal semantics,
and a C++ user of an exported template constraint sees structural ones, matching
what Carbon code sees.

> **OPEN (sub-fork) F-010i — export fidelity bar.** Accept the opaque
> satisfaction hook for requirements with no C++ rendering, exporting readable
> `requires`-expressions only where shapes map (recommended: satisfaction
> results are always exact; only C++-side readability degrades, and the
> alternative makes every Carbon compile-time feature a blocker for concept
> export), or require every exported requirement to render as a transparent C++
> `requires`-expression and reject the export otherwise.

## Relationship to checked generics

### Interfaces stay nominal

Nothing in this design lets a type satisfy an _interface_ structurally.
Interface satisfaction remains nominal for template bindings exactly as for
checked bindings: `fn F[template T: Sortable](...)` requires a visible `impl` of
`Sortable`, with the template phase changing when the check happens, never what
satisfies it. The rejected alternative — implicit structural satisfaction of
interfaces for template bindings — is recorded in
[Alternatives considered](#alternatives-considered). This rule is load-bearing
for [concept export](#export-carbon-constraints-as-c-concepts): an interface
exports as a nominal-query concept precisely because structure never satisfies
it.

> **OPEN (sub-fork) F-010j — permanence of the nominal-interface rule.** Record
> "interfaces are never structurally satisfied, in any phase" as a permanent
> language rule (recommended: it matches upstream's terminology commitments and
> the export semantics above depend on it), or scope the rule to 0.1 and leave
> structural interface satisfaction open as possible future template sugar.

### The migration ladder

Template constraints are the first rung of the
[template-to-checked-generic upgrade path](goals.md#upgrade-path-from-templates)
([#2200's worked migration sequence](/proposals/p002200-template-generics.md#transition-from-c-templates-to-carbon-checked-generics)),
and this design keeps each rung mechanical:

1.  **Unconstrained template → template constraint.** Capture the template's
    actual usage of its parameter as member requirements and validity blocks.
    Calls that compiled before still compile; calls that never could now fail at
    the call site with a named requirement.
2.  **Template constraint → interface + blanket impl.** Declare an interface
    with the constraint's member requirements and provide
    `impl forall [template T: TheConstraint] T as TheInterface` forwarding each
    member as a template-dependent member access resolved at instantiation
    (see [Structural witnesses](#structural-witnesses)).
    Types that satisfied the constraint now nominally implement the interface
    with unchanged behavior.
3.  **Template binding → checked binding.** With callers migrated to types
    implementing the interface, the binding drops `template`.

Each step either preserves meaning or fails to compile, per the
[generics goals](goals.md#upgrade-path-from-templates); no step silently changes
behavior.

## Dependencies on unimplemented features

Stated plainly, per fork process. The semantics above are normative for when
these land:

-   **`template constraint` is parsed and member requirements are checked
    (SC-1, 2026-10-12).** `template` is a declaration modifier accepted only on
    `constraint` (`toolchain/parse/node_kind.def`,
    `toolchain/check/handle_named_constraint.cpp`); requirement `fn`s are
    collected on the named constraint and checked at the facet-conversion
    chokepoint by `toolchain/check/structural_conformance.cpp`. Plain
    `constraint` declarations with `require impls` are unchanged.
-   **Template-phase checking is partly complete.** Upstream's action-based
    template phase (calls, conversions and member accesses parked as actions
    and replayed at instantiation) and same-file template lowering through
    `SpliceInst` landed before SC-1, so a constrained template function
    executes; the remaining lowering gap is cross-file template lowering
    (`toolchain/lower/handle.cpp`), and operators and conversions on
    template-dependent values are tracked by the templates workstream (W7, per
    [fork/gap-analysis.md](/fork/gap-analysis.md)).
-   **A template-phase `Self` is SC-B2's prerequisite (W-028).** SC-1 checks a
    template constraint's body with a checked-phase `Self` (D-SC-10 as amended
    at fill round 7), so the deferral of the checks that involve `Self`
    ([Definition-time checking](#definition-time-checking)) is not
    implemented; the requirement signatures it would admit are filed as W-169.
-   **Probe-mode evaluation is a new subsystem.** Checking today emits
    diagnostics eagerly; the capture-instead-of-emit replay that probes require
    generalizes an existing non-diagnosing lookup pattern but does not exist
    yet. It is the irreducible implementation cost of validity predicates,
    shared by every design alternative that supports them.
-   **Function overloading (F-009) is implemented** (OV-1 to OV-3). The
    [constrained-candidate rules](#constrained-candidates-and-overload-resolution)
    bind its resolution loop; a template-constrained member is probed without
    diagnostics.
-   **Concept mapping needs the templates and interop workstreams (W7/W8).**
    Concept _import_ on concrete types works in the toolchain today. Deferred
    evaluation for dependent arguments of imported concepts lands with the
    template-completion workstream (W7), per the option paper's staging
    ([fork/design-sprint/structural-conformance.md](/fork/design-sprint/structural-conformance.md));
    `ConceptDecl` export synthesis, the opaque satisfaction hook, and evaluating
    imported concepts on Carbon types (which requires exporting Carbon types
    into the shared Clang AST) are interop-frontier (W8) deliverables per
    [fork/gap-analysis.md](/fork/gap-analysis.md).
-   **Value predicates are out of scope.** Predicates on non-type template
    parameter values are future work, not part of this design; see
    [Boolean predicate requirements](#boolean-predicate-requirements) and
    [#2200's future work](/proposals/p002200-template-generics.md#predicates-constraints-on-values).
    This is a documented scope exclusion, not an accidental gap.
-   **Variadics interaction is out of scope.** Requirements inside variadic
    templates ([variadics](../variadics.md)) interact with pack checking;
    specifying that interaction waits for the variadics implementation
    workstream (W6) and is a documented gap, not an accidental one.

## Alternatives considered

Two alternatives were researched in the option paper
([fork/design-sprint/structural-conformance.md](/fork/design-sprint/structural-conformance.md))
and rejected in fork decision
[F-010](/fork/decision-log.md):

-   **Implicit structural satisfaction of interfaces for template bindings**
    (Go-style, limited to the template phase): rejected because upstream's
    design keeps interfaces nominal on purpose, the migration ladder exists
    _because_ implicit satisfaction was not chosen, and one interface would need
    two contradictory C++ export semantics.
-   **Boolean compile-time predicates only** (D-style, no named structural
    constraints): rejected because it leaves the accepted `template constraint`
    design unimplemented, under-delivers the milestone's "modeling the members"
    half, and degrades concept export to opaque callbacks in all cases. Its one
    distinctive surface — predicates attached directly to bindings — is absorbed
    into this design as [`where require`](#anonymous-predicates-on-bindings)
    (pending sub-fork F-010e).

That decision is final; this document specifies the chosen design rather than
relitigating it.

## Open sub-forks

Per the fork's [sub-fork rule](/fork/process.md#human-in-the-loop-rule), the
following points have more than one defensible answer and are **not decided by
this document**; each is marked OPEN at its point of definition above and awaits
a user decision. Recommendations repeat the inline markers. SC-1 (2026-10-12)
resolved or deferred F-010b, F-010h, F-010l and F-010m as marked; F-010a, c,
d, e, f, g, i, j and k stay OPEN for SC-B2 and SC-B3.

-   **F-010a — requirement introducer spelling.** Reuse `require` for validity
    blocks and predicates vs a dedicated `requires`-style keyword.
    _Recommendation: reuse `require`._
-   **F-010b — field requirements in 0.1.** Keep `var` field requirements in the
    first stage vs defer fields. _Recommendation: keep them, per
    [#2200's "function and field declarations"](/proposals/p002200-template-generics.md#template-constraints)._
    **DEFERRED past SC-1 against the recommendation (D-SC-2; veto-able; ledger
    residue).**
-   **F-010c — validity-block statement forms.** Expression statements and `let`
    only vs the full statement grammar. _Recommendation: expression statements
    and `let` only._
-   **F-010d — predicate expression type.** Exactly `bool` vs implicitly
    convertible to `bool`. _Recommendation: exactly `bool`._
-   **F-010e — anonymous `where require` on bindings.** Bless the binding-level
    form vs require named constraints for every requirement. _Recommendation:
    bless `where require`._
-   **F-010f — probe capture depth.** Immediate-context capture with deep
    failures escaping as hard errors vs absorbing all failures. _Recommendation:
    immediate-context capture, per the C++ precedent._
-   **F-010g — probe side-effect contract.** "Implementation-defined caching
    effects, no semantic effects" vs fully isolated probes. _Recommendation:
    accept caching effects._
-   **F-010h — satisfaction and type completeness.** Require a complete concrete
    type at satisfaction checks vs C++-style check-against-what's-visible.
    _Recommendation: require completeness._ **RESOLVED as recommended (SC-1,
    D-SC-5(a)).**
-   **F-010i — export fidelity bar.** Allow the opaque satisfaction hook for
    non-renderable requirements vs transparent-or-rejected export.
    _Recommendation: allow the opaque hook._
-   **F-010j — permanence of the nominal-interface rule.** Permanent "interfaces
    are never structurally satisfied" vs 0.1-scoped restriction.
    _Recommendation: record it as permanent._
-   **F-010k — disambiguating `require (`.** Lookahead past the matched `)` for
    `{` vs forbidding predicate expressions that start with `(`.
    _Recommendation: lookahead._
-   **F-010l — parameterized member requirements.** Allow `template` or
    parameterized requirement declarations in 0.1 vs defer them.
    _Recommendation: defer past 0.1._ **DEFERRED as recommended (SC-1, D-SC-2;
    ledger residue W-136).**
-   **F-010m — `impl ... as` a template constraint.** Error vs the
    plain-named-constraint meaning (nominal requirements only).
    _Recommendation: error._ **RESOLVED as recommended (SC-1, D-SC-8).**

## References

-   Proposal
    [#818: Constraints for generics (generics details 3)](https://github.com/carbon-language/carbon-lang/pull/818)
    — introduced `template constraint`
-   Proposal [#2200: Template generics](/proposals/p002200-template-generics.md)
    — template-constraint semantics, no-SFINAE rationale, and the
    expanded-constraints/predicates future work this document completes
-   Proposal
    [#875: Principle: information accumulation](/proposals/p000875-principle-information-accumulation.md)
-   Proposal
    [#2138: Checked and template generic terminology](/proposals/p002138-checked-and-template-generic-terminology.md)
-   Proposal
    [#3763: Matching redeclarations](/proposals/p003763-matching-redeclarations.md)
    — the signature-matching criteria member requirements reuse
-   Question-for-leads issues
    [#949: Constrained template name lookup](https://github.com/carbon-language/carbon-lang/issues/949)
    and
    [#2153: Checked generics calling templates](https://github.com/carbon-language/carbon-lang/issues/2153)
-   [Generics: goals](goals.md),
    [terminology](terminology.md#structural-interfaces), and
    [details: named constraints](details.md#named-constraints)
-   [Templates](../templates.md)
-   Fork decisions
    [F-010](/fork/decision-log.md)
    and
    [F-009](/fork/decision-log.md),
    and the option paper
    [fork/design-sprint/structural-conformance.md](/fork/design-sprint/structural-conformance.md);
    the SC-1 implementation plan
    [fork/structural/plan.md](/fork/structural/plan.md)
