# Design option paper: template-style structural conformance to nominal constraints

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

Status: **OPEN design fork** (input to `fork/decision-log.md`). This is the
design half of workstream W7 (integrated templates completion + structural
conformance) per `fork/gap-analysis.md`, and it feeds W8 (C++ interop
frontier: concept export).

<!-- toc -->

## Table of contents

-   [Problem statement](#problem-statement)
    -   [Which 0.1 bullets this closes](#which-01-bullets-this-closes)
    -   [Reading the milestone bullet](#reading-the-milestone-bullet)
-   [Constraints](#constraints)
    -   [Interop requirements from the milestone](#interop-requirements-from-the-milestone)
    -   [Carbon design principles that bind this design](#carbon-design-principles-that-bind-this-design)
    -   [What upstream has already accepted](#what-upstream-has-already-accepted)
    -   [Prior art](#prior-art)
    -   [Implementation realities in this toolchain](#implementation-realities-in-this-toolchain)
-   [Options](#options)
    -   [Option A: implicit structural satisfaction of interfaces for template bindings](#option-a-implicit-structural-satisfaction-of-interfaces-for-template-bindings)
    -   [Option B: `template constraint` + `require` validity blocks (the accepted-design path)](#option-b-template-constraint--require-validity-blocks-the-accepted-design-path)
    -   [Option C: boolean compile-time predicates only](#option-c-boolean-compile-time-predicates-only)
-   [2153 "predicates" direction, but shipping _only_ this leaves the accepted](#2153-predicates-direction-but-shipping-only-this-leaves-the-accepted)
    -   [How C++20 concepts map, in both directions](#how-c20-concepts-map-in-both-directions)
    -   [Recommendation](#recommendation)
    -   [Dependencies on other workstreams](#dependencies-on-other-workstreams)
    -   [Open questions for the user](#open-questions-for-the-user)

<!-- tocstop -->

## Problem statement

The 0.1 milestone requires, under Generics → Integrated templates
(`docs/project/milestones.md:140-143`):

> Including template-style structural conformance to nominal constraints,
> both modeling the members (like interfaces) and arbitrary predicates
> (like C++20 expression validity predicates)

Nothing exists. The audit (`fork/gap-analysis.md`, row 37) found the phrase
"structural conformance" nowhere in the toolchain, and the templates design
doc (`docs/design/templates.md:22-27`) is a self-described "skeletal design
... a placeholder". The closest accepted design material is:

-   `template constraint` declarations — named constraints that contain
    function/field declarations matched _structurally_ against a type —
    accepted in proposal p000818 (Constraints for generics) and re-affirmed
    with worked examples in p002200 (Template generics,
    `proposals/p002200-template-generics.md:348-431`).
-   p002200's **future work** section explicitly names the two gaps this
    paper must close: "Expanded template constraints" (the kinds of
    constraints expressible in C++20 concepts and requires-expressions,
    lines 1038-1049) and "Predicates: constraints on values" (lines
    1051-1057, tracked upstream as leads issue #2153).

In the toolchain, `template constraint` is not even parsed — the parser
emits `UnrecognizedDecl`
(`toolchain/parse/testdata/generics/named_constraint/template_constraint.carbon`)
and the checker has an explicit
`// TODO: Support for "template constraint"` at
`toolchain/check/handle_named_constraint.cpp:118`.

### Which 0.1 bullets this closes

1.  **Primary**: "Integrated templates — Including template-style structural
    conformance to nominal constraints..." (MISSING; gap-analysis row 37).
2.  **Enables the export half of**: "Mapping C++20 concepts into named
    predicates, and named predicates into C++20 concepts"
    (`docs/project/milestones.md:149-150`; PARTIAL, gap-analysis row 40).
    You cannot export "named predicates" until the language has them; this
    paper defines them. The export machinery itself lands in W8.
3.  **Arbiter contribution**: W7's arbiter requires "a structural-conformance
    test (C++20-style validity predicate) checks and runs".

### Reading the milestone bullet

The phrase is ambiguous and the ambiguity matters for the option split:

-   Reading 1 — _conformance to interfaces is structural in template code_:
    a template argument satisfies an interface constraint by having the
    right members, no `impl` needed. (Go-style implicit satisfaction,
    limited to the template phase.)
-   Reading 2 — *nominal (named) constraint entities whose satisfaction is
    structural*: a named thing you conform to implicitly — exactly
    p000818/p002200's `template constraint`, extended with arbitrary
    predicates.

Upstream's own docs support Reading 2: `docs/design/generics/terminology.md`
(408-438) is careful that _interfaces_ stay nominal ("satisfies the
interface [only] if there is some explicit statement saying so") while
_named constraints_ are the structural mechanism; and p002200's C++
migration story routes structural conformance through `template constraint`
plus explicit blanket impls, never through implicit interface satisfaction.
Reading 1 is nevertheless a real design option (Option A below) because
`docs/design/templates.md:100-111` muses about "applying the interface
constraints of the checked-generics system directly to template parameters
rather than create a new constraint system."

## Constraints

### Interop requirements from the milestone

-   C++20 concepts must import as usable constraints, and Carbon named
    predicates must export as C++20 concepts
    (`docs/project/milestones.md:149-150`).
-   The migration goal: 0.1 features "must also be sufficient to translate
    existing C++ code ... into obvious and unsurprising Carbon code"
    (`docs/project/milestones.md:57-61`). Real C++20 code uses
    `requires`-expressions with simple-requirements (`x + y;`),
    type-requirements (`typename T::value_type;`), compound requirements
    with return-type constraints (`{ x.size() } -> std::integral;`), and
    nested requirements (`requires sizeof(T) > 4;`). All four shapes need
    an idiomatic Carbon spelling or a documented rewrite.
-   Pre-C++20 constraint idioms (`std::enable_if`, `void_t`, detection
    idiom) must translate; p002200 already says these become template
    constraints, not SFINAE — Carbon deliberately has **no SFINAE**
    (`proposals/p002200-template-generics.md:213-217, 924-933`).

### Carbon design principles that bind this design

-   **No SFINAE / errors up front** (p002200 rationale;
    `docs/design/generics/goals.md:140-143`): an unsatisfied constraint at
    a use site is a hard, well-located error; constraints select overloads
    _before_ instantiation rather than discarding failed instantiations.
-   **Interfaces are nominal for checked generics**
    (`docs/design/generics/terminology.md:416-424`): implementing an
    interface carries semantic meaning beyond structure. Any structural
    mechanism must not silently erode this for checked generics — p002200
    (405-426) explicitly bans lookup of structural members through checked
    generic bindings even if template constraints become usable there.
-   **Upgrade path from templates to checked generics**
    (`docs/design/generics/goals.md:417-446`, p000024): each migration step
    either preserves meaning or fails to compile. Structural constraints
    are step 1 of that ladder; the design must keep the
    template-constraint → interface → checked-generic ladder intact
    (p002200 lines 506-700 gives the full worked sequence).
-   **Information accumulation** (p000875): satisfaction checking happens
    at instantiation, where all information is available; nothing here may
    require global whole-program analysis.
-   Project goals served: C++ interop/migration and performance
    (`docs/project/goals.md#interoperability-with-and-migration-from-existing-c-code`,
    `#performance-critical-software`).

### What upstream has already accepted

Chain of accepted proposals this design must respect (all in `proposals/`):

-   p000818 — introduces `template constraint` with structural member
    declarations.
-   p000989 — constrained-template name lookup (look in both the concrete
    type and the constraint; ambiguity is an error).
-   p002138 — checked vs template terminology.
-   p002200 — template generics: no SFINAE, no ad-hoc API specialization,
    structural constraints match members found by member lookup in the type
    (an external/out-of-line `impl` does **not** satisfy a structural
    constraint — p002200:355-375).
-   p007254 — phase keywords: bindings are now `template T: type` (no
    `:!`); examples below use current syntax, not p002200's.

### Prior art

-   **C++20 concepts**: named boolean predicates; requires-expressions test
    expression validity; subsumption partial-orders overloads. Maps most
    directly onto Option B/C. Known pain points to avoid: satisfaction
    caching versus type completeness, and subsumption's normalization cost.
-   **Go**: interfaces satisfied implicitly by method set — the purest
    "structural conformance to nominal constraints" (Option A), and a
    warning: accidental conformance is a real defect class, which is why
    Carbon's checked side is nominal.
-   **Rust**: traits strictly nominal, no structural conformance; `where`
    clauses only nominal bounds. Rust's refusal is upstream's model for the
    checked side.
-   **D**: `if (...)` template constraints — arbitrary compile-time boolean
    predicates plus `__traits(compiles, ...)` for validity — the closest
    prior art for Option C. Ergonomic, but predicates-as-code proved hard
    to introspect for diagnostics and tooling.
-   **Zig**: no declared constraints; pure comptime duck typing with
    `@compileError`. This is what Carbon templates are _without_ this
    feature — the milestone bullet exists precisely to be better than this.
-   **Swift**: nominal protocols; retroactive conformance by way of `extension`
    is the analogue of Carbon's blanket-impl migration step, not of
    structural conformance.

### Implementation realities in this toolchain

What exists and is reusable (all paths relative to repository root):

-   **Named constraints just landed in check**: `constraint` declarations
    with `require impls I` / `extend require impls I` bodies check
    end-to-end (`toolchain/check/handle_named_constraint.cpp`,
    `toolchain/sem_ir/named_constraint.h`,
    `toolchain/check/testdata/named_constraint/` — 12 test files).
    `template constraint` is the unparsed/TODO extension point.
-   **FacetTypeInfo is the constraint store**
    (`toolchain/sem_ir/facet_type_info.h`): canonical vectors of interface
    requirements, named-constraint requirements, rewrite constraints, plus
    a `other_requirements` TODO bool. Structural-member requirements and
    predicate requirements become two new requirement kinds here, flowing
    through existing canonicalization/hashing.
-   **The template phase runs on deferred actions**: template-dependent
    operations become action insts (`AccessMemberAction`,
    `RefineTypeAction`, ... in `toolchain/sem_ir/typed_insts.h`) parked in
    a generic's eval block (`toolchain/check/generic.cpp:258`
    `AddTemplateActionToEvalBlock`) and performed at instantiation by way of
    `PerformDelayedAction` (`toolchain/check/action.h:121-131`).
    Constraint-satisfaction checks for dependent arguments become one more
    action kind on this rail.
-   **Facet-value conversion is the enforcement chokepoint**: converting a
    concrete type to a facet type does `LookupImplWitness`
    (`toolchain/check/convert.cpp:1596-1614`). Structural satisfaction
    slots in as a fallback/alternative witness source at exactly this
    point. `LookupImplWitness` already supports `diagnose = false`
    (`toolchain/check/impl_lookup.h:40`) — the speculative-checking pattern
    predicates need already has precedent.
-   **Concept import exists**: `Cpp.SomeConcept(T)` for concrete `T`
    evaluates through Clang `CheckConceptTemplateId` to a Carbon `bool`
    literal (`toolchain/check/cpp/call.cpp:321-332`, test
    `toolchain/check/testdata/interop/cpp/template/concept.carbon`).
-   **Signature matching exists** for redeclarations and impl checking
    (`toolchain/check/function.cpp`, `toolchain/check/merge.cpp`) —
    reusable for "does the type's `fn F` match the constraint's `fn F`
    modulo `Self` substitution".

What is broken or missing that this design sits on top of:

-   Operators/conversions on template-dependent values are `fail_todo`
    (`toolchain/check/testdata/generic/template/unimplemented.carbon` —
    `MissingImplInMemberAccess` fires at definition time instead of
    deferring).
-   Template lowering is a hard fatal:
    `CARBON_FATAL("Template lowering not implemented yet")` at
    `toolchain/lower/handle.cpp:363` (`SpliceInst`). No structural-
    conformance conformance test can _execute_ until W7 fixes this.
-   There is no speculative checking mode: check is a single pass over the
    parse tree; diagnostics are emitted eagerly. Requires-style validity
    predicates need a "probe" mode (details under Option B).
-   Carbon function overloading does not exist (gap-analysis row 42), so
    "constraints select overloads" has nothing to select between yet.

## Options

### Option A: implicit structural satisfaction of interfaces for template bindings

**Design sketch.** No new declarations. When a facet type constrains a
`template` binding, satisfaction at instantiation is: nominal `impl` if one
exists, otherwise structural — every interface member must be found by
member lookup in the concrete type with a matching signature. A
_structural witness_ (an impl-witness-shaped table whose entries point at
the type's own members) is synthesized so `x.(I.F)()` and unqualified
lookup both work.

```carbon
interface Sortable {
  fn Less[self: Self](other: Self) -> bool;
}

// `T` need not declare `impl as Sortable`; having a matching `Less`
// member suffices — but only because `T` is a *template* binding.
fn Sort[template T: Sortable](s: Slice(T));

class Legacy {  // migrated C++, no impl declarations
  fn Less[self: Self](other: Self) -> bool { ... }
}
// OK: structural conformance. `Sort` with a checked `T: Sortable`
// would reject `Legacy`.
```

Arbitrary predicates are **not covered**; Option A must be paired with
Option C's predicate mechanism to close the milestone bullet.

**C++ interop story.** Good for migration: C++ template code ported to
Carbon templates keeps working against interface-shaped constraints without
writing impls. Concept export is awkward: an interface exported as a
concept would have to test structural shape for template uses but nominal
impls for checked uses — two different C++ predicates for one Carbon name.

**Implementation cost: M.** No lexer/parser work. Check-side: structural
witness synthesis in a new `toolchain/check/structural_conformance.cpp`,
fallback hook in `toolchain/check/convert.cpp:1596` and
`toolchain/check/impl_lookup.cpp`, one new deferred-action kind in
`toolchain/sem_ir/typed_insts.h` + `toolchain/check/action.{h,cpp}` +
eval-block plumbing in `toolchain/check/generic.cpp`, signature matching
reused from `toolchain/check/function.cpp`.

**Evolution risk vs upstream: HIGH.** Upstream's terminology doc pointedly
keeps interfaces nominal, and p002200's migration ladder exists _because_
implicit interface satisfaction was not chosen; the "explore" note in
templates.md is about applying interface constraints to template params
(which p002200 already does, nominally), not about waiving impls. Expect
upstream to reject this; a fork that adopts it will diverge on every
constraint-satisfaction test forever, and programs that relied on implicit
satisfaction break if we later re-converge.

### Option B: `template constraint` + `require` validity blocks (the accepted-design path)

**Design sketch.** Implement p000818/p002200's `template constraint` and
extend it — per p002200's own future-work list — with expression-validity
requirements and boolean predicates, reusing the existing `require`
introducer (`toolchain/lex/token_kind.def:169`) for all three requirement
forms:

```carbon
// A named constraint, satisfied structurally: no impl declaration
// anywhere. Usable only on `template` bindings.
template constraint Summable {
  // (1) Member modeling, "like interfaces": matched against the
  // type's own members by member lookup (an out-of-line impl does
  // NOT satisfy this — p002200 rule).
  fn Sum[self: Self](other: Self) -> Self;
  var count: i32;

  // (2) Expression validity, like a C++20 requires-expression with
  // parameters: satisfied iff every statement in the block would
  // type-check with `x`, `y` of the concrete type.
  require (x: Self, y: Self) {
    x + y;
    x.Print();
    // Compound requirement with return-type constraint:
    let _: i64 = x.Size();
  }

  // (3) Boolean predicate on the type value ("nested requirement"):
  // any compile-time `bool` expression, including imported C++20
  // concepts and Carbon compile-time functions.
  require Core.SizeOf(Self) <= 16;
  require Cpp.std.regular(Self);

  // Existing named-constraint forms still compose:
  require Self impls Core.Destroy;
}

// Use: same positions as any facet type, but only on template bindings.
fn Accumulate[template T: Summable](s: Slice(T)) -> T;

// Anonymous one-off predicate on a binding, no named constraint needed:
fn Pad[template T: type where require Core.SizeOf(T) < 8](x: T) -> i64;
```

Semantics:

-   **Satisfaction** is checked when a concrete type converts to the
    constraint's facet type (the `toolchain/check/convert.cpp:1596`
    chokepoint): member requirements use member lookup + signature match
    modulo `Self` substitution; validity blocks are checked in a *probe
    region*; boolean predicates are constant-evaluated and must be `true`.
    Failure is a hard error naming the first unsatisfied requirement
    (concept-style diagnostics, no SFINAE).
-   **Probe region**: the `require (...) { ... }` body is checked once, at
    the constraint's definition, inside the constraint's generic with
    `Self` symbolic-but-template — producing deferred actions exactly as
    template function bodies do today. Satisfaction for a concrete type =
    run those actions by way of `PerformDelayedAction`
    (`toolchain/check/action.h:121`) with diagnostics captured instead of
    emitted (generalizing the existing `diagnose=false` pattern of
    `toolchain/check/impl_lookup.h:40`); any failed action ⇒ unsatisfied.
    This reuses the eval-block machinery rather than inventing re-parsing.
-   **Structural witness**: satisfaction of member requirements produces a
    witness table pointing at the type's members, so
    `x.(Summable.Sum)(y)` works and the p002200 migration ladder
    (structural → blanket impl → interface) is mechanical.
-   **Caching**: satisfaction results are canonicalized per
    (constraint specific, concrete type) alongside
    `IdentifiedFacetTypeStore` (`toolchain/sem_ir/facet_type_info.h:242`).
-   **Checked generics unaffected**: using a `template constraint` on a
    non-`template` binding is an error (p002200's open question resolved
    conservatively; revisit with upstream's #2153).
-   **No subsumption**: overload selection among differently-constrained
    templates (once W2 delivers overloading) uses declaration order /
    `match_first`-style explicit ordering, not C++ subsumption. This is
    the same choice upstream already made for impl specialization.

**C++ interop story.** Best of the three — see the
[dedicated section below](#how-c20-concepts-map-in-both-directions):
requires-expressions and concepts have one-to-one Carbon spellings, so
imported constraints keep their shape and exported constraints are real
concepts.

**Implementation cost: L** (core), staged:

-   B1 — `template constraint` + member requirements [M]: parse states +
    node kinds for the `template` modifier and member decls in constraint
    bodies (`toolchain/parse/state.def`, `typed_nodes.h`), `is_template`
    flag + member storage in `toolchain/sem_ir/named_constraint.h`,
    resolution of `toolchain/check/handle_named_constraint.cpp:118`, two
    new requirement vectors in `toolchain/sem_ir/facet_type_info.h`,
    satisfaction + witness synthesis in a new
    `toolchain/check/structural_conformance.cpp`, hook at
    `toolchain/check/convert.cpp:1596`, one new deferred-action kind for
    dependent arguments.
-   B2 — validity blocks + boolean predicates [L]: `require (...) {...}`
    and `require <expr>;` grammar; probe-region checking (the one genuinely
    new subsystem: diagnostic capture around eval-block replay; audit
    side effects — name poisoning, Clang decl import — for probe safety);
    `where require ...` on bindings.
-   B3 — interop mapping [M in W7, remainder in W8]: deferred
    concept-satisfaction action for dependent args of imported concepts
    (extends `toolchain/check/cpp/call.cpp:321`); export lands with W8.

**Evolution risk vs upstream: LOW.** B1 implements accepted proposals
verbatim; B2 implements what p002200's future-work section says comes
next, and its spelling (`require` reuse) is the only invented surface.
Upstream converging on a different predicate spelling would cost a
mechanical rename, not a semantic migration.

### Option C: boolean compile-time predicates only

**Design sketch.** Skip named structural constraints entirely. Constraints
on template bindings are arbitrary compile-time `bool` expressions attached
with `where`; expression validity is provided by a `require {...}`
_expression_ that evaluates to `bool` instead of erroring (D's
`__traits(compiles)`, `is_detected`):

```carbon
fn Sum[template T: type
       where require { fn (x: T, y: T) { x + y; } }](s: Slice(T)) -> T;

// Named predicates are just compile-time functions:
fn Summable(template T: type) -> bool {
  return (require { fn (x: T, y: T) { x + y; } }) and Core.SizeOf(T) <= 16;
}
fn Accumulate[template T: type where Summable(T)](s: Slice(T)) -> T;
```

**C++ interop story.** Import is trivial (concepts already evaluate to
`bool`; `where Cpp.std.regular(T)` works as soon as dependent evaluation is
deferred). Export is weak: a predicate function's body is opaque — the
exported concept can only be an opaque satisfaction callback, never a
readable requires-expression, and member requirements are not modeled as
declarations at all, so tooling/diagnostics degrade to "predicate was
false".

**Implementation cost: M.** No named-constraint work, no witness
synthesis. Still needs: `where <bool-expr>` as a new
`toolchain/sem_ir/facet_type_info.h` requirement kind, the probe-mode
subsystem for `require {...}` expressions (same cost as B2's — this is the
irreducible core), compile-time evaluation of user predicate functions
(leans on `toolchain/check/eval.cpp`, whose function-call evaluation
coverage is still partial — p002200 lines 1098-1118 lists this as an open
design question upstream too).

**Evolution risk vs upstream: MEDIUM.** Predicates align with upstream's

## 2153 "predicates" direction, but shipping _only_ this leaves the accepted

`template constraint` design unimplemented, and the milestone's "modeling
the members (like interfaces)" half is only weakly satisfied (members are
tested by usage inside validity blocks, not declared). Convergence with
upstream would mean adding Option B later anyway.

### How C++20 concepts map, in both directions

Assuming Option B's surface (mappings degrade as noted under A/C):

**Import (C++ → Carbon)** — extends what exists at
`toolchain/check/cpp/call.cpp:321-332`:

| C++20 construct | Carbon today | Carbon after this design |
| --- | --- | --- |
| `Concept<ConcreteType>` | `Cpp.Concept(T)` → `bool` (works) | unchanged |
| Concept constraining a template param | n/a | `fn F[template T: type where Cpp.Concept(T)]` — dependent uses defer by way of a new `CheckPredicateAction`; when `T` is concrete, evaluate through Clang as today |
| `requires (T x) { x + y; }` (in C++ headers) | inside imported concepts: evaluated by Clang, invisible to Carbon | unchanged (Clang keeps evaluating its own requires-expressions — no re-modeling) |
| `std::enable_if` / detection idiom | n/a | migrate to `template constraint` per p002200; no SFINAE emulation |

Limitation to record: Clang can only check satisfaction for types it can
see. For Carbon class types the toolchain must first export the type into
the shared Clang AST — the same machinery gap as "C++ templates cannot
instantiate on Carbon class types" (gap-analysis row 38); both are W8.

**Export (Carbon → C++)** — new; lands with W8 on top of
`toolchain/check/cpp/export.cpp` / `generate_ast.cpp` (interop is a shared
in-memory Clang AST, not textual headers, so exported decls are synthesized
`ConceptDecl`s):

| Carbon construct | Exported C++20 form |
| --- | --- |
| `template constraint C` member reqs (`fn Sum[self: Self](o: Self) -> Self;`) | requires-expression compound requirements: `requires(T x, T o) { { x.Sum(o) } -> std::same_as<T>; }` |
| `require (x: Self) { ... }` validity block | the corresponding requires-expression, statement by statement (each Carbon expression form has a defined C++ rendering; forms with no C++ rendering fall back to the opaque hook below) |
| `require <bool-expr>;` with Carbon-only semantics (compile-time fn calls, `Self impls I`) | nested requirement on an opaque satisfaction hook: a Carbon-patched Clang builtin (`__carbon_satisfies(C, T)`) that calls back into check — feasible because the toolchain already carries local Clang patches and owns the Sema instance |
| `interface I` (nominal) | concept over the nominal hook only: `template<class T> concept I = __carbon_impls<T, I>;` — deliberately _not_ a structural requires-expression, preserving nominal semantics across the boundary |

### Recommendation

**Option B, staged B1 → B2 → B3, with Option C's `where <bool-expr>`
binding form absorbed into B2.** Do not do Option A.

Rationale:

1.  **It is the only option that closes the whole bullet.** B models
    members as declarations ("like interfaces") _and_ arbitrary predicates
    (validity blocks + bool requires). A needs C bolted on and still
    diverges; C alone under-delivers the member-modeling half that F-001
    (staged _official_ 0.1) obligates this fork to hit.
2.  **Lowest upstream divergence.** B1 is accepted design (p000818,
    p002200); B2 is upstream's own named future work. Standing rule 5
    ("upstream is a moving asset") argues for building the thing upstream
    will merge toward, and this is the single area where upstream has
    already written down its direction in detail.
3.  **It rides the existing machinery.** Satisfaction checking is a
    fallback at the one facet-conversion chokepoint
    (`toolchain/check/convert.cpp:1596`); dependent satisfaction is one
    more deferred-action kind on the eval-block rail
    (`toolchain/check/generic.cpp:258`); probe mode generalizes an
    existing `diagnose=false` idiom. The only new subsystem (diagnostic
    capture around eval-block replay) is needed by _every_ option that
    supports validity predicates — it is the irreducible cost of the
    milestone bullet, so pay it where it buys the most.
4.  **Best interop story in both directions.** Requires-expressions and
    concepts round-trip shape-preserving; interfaces export nominally,
    keeping Carbon's nominal/structural boundary visible to C++ users
    instead of erasing it.
5.  **Migration ladder stays intact.** Structural witness tables make the
    p002200 template-constraint → blanket-impl → interface sequence
    mechanical — that ladder is the milestone's actual purpose (the
    "upgrade path from templates" generics goal).

Sequencing note: B1 is check-phase-complete without touching lowering, so
it can start before W7 fixes the `toolchain/lower/handle.cpp:363` fatal —
but its _arbiter_ (compile-and-run structural-conformance test) blocks on
that fix landing.

### Dependencies on other workstreams

-   **W7 (carrier)**: dependent-operator/conversion deferral
    (`fail_todo` tests in `toolchain/check/testdata/generic/template/`) and
    the `SpliceInst` lowering fatal must be fixed for conformance tests to
    execute. Probe-mode replay _is_ eval-block replay — B2 and W7's
    deferred-action completion should be one engineering track.
-   **W2 — function overloading design**: constraints as overload filters,
    and the no-subsumption/explicit-ordering decision, must be settled
    jointly with the overloading paper. B is usable without overloading
    (single-candidate hard errors), so W2 gates only the overload-selection
    behavior, not the feature.
-   **W8 — C++ interop frontier**: concept export (`ConceptDecl`
    synthesis, `__carbon_satisfies` hook) and Carbon-type export into the
    Clang AST (shared blocker with templates-on-Carbon-types). B3's
    deferred import-side action can land in W7.
-   **W1 — conformance harness**: the arbiter tests for this area are
    compile-and-run programs; write them with B1.
-   **W6 — variadics**: `require` blocks inside variadic templates
    interact with pack checking; explicitly out of scope until W6 lands
    (note in the design doc, not a blocker).

### Open questions for the user

Beyond choosing an option:

1.  **Spelling.** Reuse `require` for all three requirement forms
    (recommended: one introducer, mirrors `require impls`), or introduce a
    dedicated `requires`-like keyword closer to C++? Also: bless
    `where require ...` on bindings, or require naming a constraint?
2.  **Option A as future sugar.** Record a permanent "interfaces are never
    structurally satisfied" rule (matching upstream), or leave the door
    open? Recommended: record the rule; it is load-bearing for concept
    export semantics.
3.  **Field requirements.** Keep `var` field requirements in template
    constraints (p000818 has them; C++ requires-expressions can test
    members, and migrated C++ uses fields), or restrict to functions for
    B1 and defer fields? Cost is small; recommend keeping them.
4.  **Probe-mode observability.** Rule that satisfaction probing must have
    no observable side effects — but name poisoning and Clang decl import
    are caches with observable edges. Accept "implementation-defined
    caching effects, no semantic effects" (C++ has the same wart in
    instantiation caching), or demand full isolation (costlier)?
5.  **Satisfaction timing vs completeness.** Is satisfaction re-checked if
    a type is completed after first check (C++'s incomplete-type concept
    trap)? Recommended: satisfaction requires a complete type, hard error
    otherwise — stricter than C++, simpler, revisit on evaluator feedback.
6.  **No-subsumption confirmation.** Confirm explicit ordering (match_first
    precedent) over C++-style subsumption for constrained-overload
    selection, accepting that C++ code relying on subsumption partial
    ordering needs manual re-ordering on migration.
7.  **Export fidelity bar.** Is the opaque `__carbon_satisfies` hook
    acceptable for Carbon-only predicates in 0.1 (readable
    requires-expressions only where shapes map), or must every exported
    predicate be a transparent concept (significantly more W8 work)?
