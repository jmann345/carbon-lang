# Pattern conditions and `let ... else`

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Grammar](#grammar)
-   [The positive form: `if (let ...)`](#the-positive-form-if-let-)
-   [The loop form: `while (let ...)`](#the-loop-form-while-let-)
-   [The negative form: `let ... else`](#the-negative-form-let--else)
    -   [The divergence requirement in 0.1](#the-divergence-requirement-in-01)
    -   [Initializer restriction](#initializer-restriction)
-   [Semantics: one refutable-match core](#semantics-one-refutable-match-core)
    -   [Desugaring onto `match`](#desugaring-onto-match)
    -   [Binding scope](#binding-scope)
    -   [Failure-path destruction](#failure-path-destruction)
    -   [Evaluation order and conversions](#evaluation-order-and-conversions)
    -   [Irrefutable patterns](#irrefutable-patterns)
-   [Reserved for future extensions](#reserved-for-future-extensions)
-   [Relationship to the `?` operator](#relationship-to-the--operator)
-   [C++ interoperability](#c-interoperability)
-   [Dependencies and implementation staging](#dependencies-and-implementation-staging)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [Open sub-forks](#open-sub-forks)
-   [References](#references)

<!-- tocstop -->

## Overview

Carbon combines refutable [pattern matching](../pattern_matching.md) with
control flow in three statement-level forms:

-   **Positive:** `if (let` _pattern_ `=` _expression_`) { ... }` — match a
    pattern; on success, run the block with the pattern's bindings in scope.
-   **Loop:** `while (let` _pattern_ `=` _expression_`) { ... }` — re-match
    each iteration; run the body with the bindings in scope; exit the loop on
    the first failure.
-   **Negative:** `let` _pattern_ `=` _expression_ `else { ... }` — match a
    pattern; on success, introduce the bindings into the _enclosing_ scope; on
    failure, run the `else` block, which must diverge.

These are the Carbon equivalents of Rust's `if let`, `while let`, and
`let ... else`, spelled with Carbon's existing keywords, parenthesized
conditions, and required braces
([proposal #623](/proposals/p000623-require-braces.md)). They exist because a
full [`match` statement](../pattern_matching.md#pattern-match-control-flow) is
the wrong tool when only one alternative is interesting: a guard clause or a
single-alternative unwrap should not cost an extra nesting level and a
mandatory `default` arm. The dominant consumers are
[choice types](../sum_types.md) — `Optional`-shaped types, `Core.Result` from
[error handling](../error_handling.md), and the choice-shaped views of C++
`std::optional` and `std::variant` — but the forms accept the full pattern
grammar and work on tuples, structs, and expression patterns as well.

All three forms use the one shared pattern grammar of
[proposal #2188](/proposals/p002188-pattern-matching-syntax-and-semantics.md)
unchanged, and all three are specified as thin clients of the same
refutable-match core that executes `match` `case` patterns: they add surface
syntax, not a second pattern-matching semantics. See
[Semantics](#semantics-one-refutable-match-core).

Accepted proposal #2188 reserved exactly this slot: it noted that a refutable
pattern in a `let`/`var` declaration is an error today, and anticipated a
"`var`/`let`-`else`" feature as the second context permitting refutable
matches (the never-merged upstream PR
[#1871](https://github.com/carbon-language/carbon-lang/pull/1871)). This
document fills that slot. The surface and semantics were fixed by fork
decision [F-011](/fork/decision-log.md); points this document leaves genuinely
open are collected under [Open sub-forks](#open-sub-forks) and decided by the
user, never silently by this document.

## Grammar

A _pattern condition_ is a `let` or `var` introducer followed by a full
pattern, `=`, and a scrutinee expression:

> _pattern-condition_ ::= (`let` | `var`) _full-pattern_ `=` _expression_

The three forms extend the existing [conditional](conditionals.md),
[loop](loops.md), and
[`let`/`var` declaration](../pattern_matching.md#pattern-matching-in-local-variables)
grammars. An _else-clause_ below is the existing `else` grammar of
[conditionals](conditionals.md): `else` followed by a block or by another `if`
statement.

> _statement_ ::= `if` `(` _pattern-condition_ `)` _block_ _else-clause_?
>
> _statement_ ::= `while` `(` _pattern-condition_ `)` _block_
>
> _declaration_ ::= (`let` | `var`) _full-pattern_ `=` _expression_ `else`
> _block_

Notes:

-   _full-pattern_ is the pattern grammar of
    [pattern matching](../pattern_matching.md), unchanged. Refutable patterns
    are permitted — that is the point of these forms. Compile-time
    (`generic`/`template`) bindings are not permitted: the match happens at
    runtime. This document establishes that restriction for pattern
    conditions; it parallels the situation in `match` `case` patterns, which
    [proposal #2188](/proposals/p002188-pattern-matching-syntax-and-semantics.md#type-pattern-matching)
    leaves without a syntactic slot for deduced values absent a future
    `forall` syntax.
-   Because `let` and `var` can never begin an expression, a single-token peek
    after `(` distinguishes a pattern condition from an ordinary boolean
    condition, with no lookahead or backtracking — preserving
    [low context sensitivity](/proposals/p000646-low-context-sensitivity-principle.md).
    A bare `if (P = e)` without the introducer is not a pattern condition; it
    is (and remains) an ordinary expression condition.
-   The `var` spellings (`if (var ...)`, `while (var ...)`, `var ... else`)
    apply [`var` pattern](../pattern_matching.md#var) semantics — the bindings
    get mutable storage — and otherwise behave identically to the `let`
    spellings.

    > OPEN (sub-fork): whether the `var` spellings are in 0.1 or deferred.
    > Recommendation: include them — proposal #2188 treats `var` uniformly
    > and the machinery is shared — deferring only if `var`-in-`case` support
    > slips in the implementation.

-   The `let ... else` declaration ends at the `else` block's closing `}`,
    with no trailing `;`.

    > OPEN (sub-fork): terminator for `let ... else` — end at the `}`
    > (statement-like, as `if` does) or require a trailing `;`
    > (declaration-like, as Rust does). Recommendation: no `;`.

-   These forms appear in function bodies only. A `let ... else` at file scope
    has no meaning — its `else` block could not diverge — and pattern
    conditions belong to statements, which exist only in function bodies.

## The positive form: `if (let ...)`

```carbon
choice Optional(T: type) { None, Some(value: T) }

fn UseOpt(opt: Optional(i32)) -> i32 {
  // `n` is in scope only in the then-block.
  if (let .Some(n: i32) = opt) {
    return n * 2;
  } else {
    return 0;
  }
}
```

On success, the then-block executes with the pattern's bindings in its scope.
On failure, control transfers to the `else` arm if present, and otherwise past
the statement. No bindings are visible in the `else` arm or after the
statement.

`else if` composes as it does for ordinary [conditionals](conditionals.md) —
each `else if` may independently carry a boolean condition or a pattern
condition, and each pattern condition's bindings are scoped to its own
then-block:

```carbon
fn Classify(pair: (i32, i32)) {
  if (let (0, n: i32) = pair) {
    Core.Print(n);       // Second element, when the first is 0.
  } else if (let (n: i32, 0) = pair) {
    Core.Print(n);       // First element, when the second is 0.
  } else {
    Core.Print(-1);
  }
}
```

## The loop form: `while (let ...)`

```carbon
fn Sum(var v: Vector) -> f32 {
  var total: f32 = 0.0;
  // Re-matched each iteration; the loop exits on the first failure.
  while (let .Some(x: f32) = v.PopBack()) {
    total += x;
  }
  return total;
}
```

The pattern condition is the loop condition: each iteration evaluates the
scrutinee expression and matches it; on success the body runs with fresh
bindings, and on failure the loop exits. `break` and `continue` behave as in
any [`while` loop](loops.md#while): `break` exits the loop and `continue`
proceeds to the next evaluation of the scrutinee. There is no `else` on a
`while` statement, with or without a pattern condition.

`while (let ...)` is included in 0.1 by fork decision
[F-011](/fork/decision-log.md); it shares all of the machinery of the
positive form and directly serves the milestone's looping-constructs bullet
for pop-and-iterate loops.

## The negative form: `let ... else`

```carbon
fn ParsePort(s: str) -> i32 {
  let .Some(port: i32) = ParseI32(s) else {
    return -1;
  }
  // `port` is an ordinary binding of this scope from here on.
  return port;
}
```

On success, the pattern's bindings are introduced into the **enclosing**
scope, exactly as if declared by an ordinary `let`/`var` declaration at the
same position. On failure, the `else` block executes; it must diverge, so
code after the declaration can rely unconditionally on the bindings.

This is the guard-clause form: it keeps the success path at the top level of
the function instead of nesting it inside an `if`, and applied to
[`Core.Result`](../error_handling.md#consuming-results-with-let--else-and-if-let-)
it is the manual spelling of what the
[`?` operator](#relationship-to-the--operator) automates.

### The divergence requirement in 0.1

The `else` block must not complete normally. In 0.1 this is a **syntactic**
rule: the block must end with one of

-   `return`,
-   `break`, or
-   `continue`,

where `break` and `continue` are valid only if the declaration is inside a
loop, under the ordinary rules for those statements. This list is fixed by
fork decision [F-011](/fork/decision-log.md). A type-based rule — accepting
any expression of a diverging ("noreturn") type, such as a call to an
aborting function — is explicitly **deferred to the safe-Carbon workstream**,
which owns the design of unrecoverable failure
([error handling: unrecoverable errors](../error_handling.md#unrecoverable-errors)).
Until then, `else { Abort(); }` is rejected; write
`else { Abort(); return; }` or restructure. This is a known 0.1 sharp edge,
accepted to avoid designing noreturn types ahead of the safety work.

> OPEN (sub-fork): depth of the syntactic check — flat (the last statement of
> the `else` block itself must be `return`/`break`/`continue`) or recursive
> (every control path through the block must syntactically end in one of
> them, so `else { if (c) { return 1; } else { return 2; } }` is accepted).
> Recommendation: flat in 0.1 — simplest to specify and implement, and any
> rejected block has a trivial rewrite.

### Initializer restriction

Because [`if` expressions](../expressions/if.md) consume `else` greedily,
`let P = if c then a else { ... }` would be ambiguous between an
if-expression whose else-value is a struct literal and a `let ... else`
declaration. The initializer of a `let ... else` declaration therefore must
not be an unparenthesized `if` expression; violations are diagnosed with a
"parenthesize the initializer" fixit. This adapts Rust RFC 3137's identical
restriction to Carbon's one brace-bearing expression form.

> OPEN (sub-fork): resolution of the `else` ambiguity — forbid
> unparenthesized `if` expressions as `let ... else` initializers (diagnose
> with a fixit), or parse greedily in favor of the if-expression and let the
> misparse surface as a downstream error. Recommendation: forbid with a
> fixit.

## Semantics: one refutable-match core

### Desugaring onto `match`

Each form is specified by an expansion onto a one-`case`
[`match` statement](../pattern_matching.md#pattern-match-control-flow). For
any full pattern `P`, expression `e`, and blocks `S1`, `S2`, `D`:

```carbon
// `if (let P = e) { S1 } else { S2 }` behaves as:
match (e) {
  case P => { S1 }
  default => { S2 }
}
```

```carbon
// `while (let P = e) { S }` behaves as:
while (true) {
  match (e) {
    case P => { S }
    default => { break; }
  }
}
```

Note that in the `while` expansion, `break` and `continue` written inside `S`
already bind to the enclosing `while` loop — `match` is not a `break` target —
so the expansion is faithful for them as well.

```carbon
// `let P = e else { D }` behaves as:
match (e) {
  case P => {}
  default => { D }
}
```

— except that the bindings of `P` are introduced into the enclosing scope
rather than the `case` arm. Because `case` bindings are scoped to their arms,
this last expansion is not literally writable as Carbon source; as with the
[`?` desugaring](../error_handling.md#semantics-and-desugaring), the expansion
specifies the observable behavior — evaluation order, conversions, matching
semantics, and control transfer — not a source-to-source rewrite.

Deltas from a literal `match`, common to all three forms:

-   No [guard](../pattern_matching.md#guards) may follow the pattern; guards
    remain `case`-specific syntax. (Reserved — see
    [future extensions](#reserved-for-future-extensions).)
-   The usefulness and exhaustiveness diagnostics of
    [refutability checking](../pattern_matching.md#refutability-overlap-usefulness-and-exhaustiveness)
    do not apply: there is one pattern and an implicit fallback, so the set
    is exhaustive by construction. The
    [irrefutable-pattern warning](#irrefutable-patterns) applies instead.

Specifying the forms as expansions means they introduce **no new semantic
machinery**: the refutable-match core — match a full pattern against a
scrutinee, branch on failure, place bindings in the success block's scope —
is implemented once for `match` and reused, and the forms lower through the
same ordinary branches `if` and `while` use today. This is the implementation
contract fixed by F-011; see
[Dependencies](#dependencies-and-implementation-staging).

### Binding scope

-   `if (let ...)`: bindings are scoped to the then-block only. They are not
    visible in the `else` arm, in subsequent `else if` conditions, or after
    the statement.
-   `while (let ...)`: bindings are scoped to the loop body and are freshly
    bound on each iteration.
-   `let ... else`: bindings are introduced into the enclosing scope, with
    the same scope a plain `let`/`var` declaration at the same position
    would give them. They are not visible inside the `else` block — the
    match failed there, so there are no values to see:

```carbon
let .Some(port: i32) = ParseI32(s) else {
  // ❌ Error: `port` is not in scope in the failure block.
  Core.Print(port);
  return -1;
}
```

In every form, name shadowing and lookup follow the ordinary rules for the
scope the bindings land in; nothing here adds a new scoping mechanism.

### Failure-path destruction

Objects created by [`var` patterns](../pattern_matching.md#var) during a
match that then **fails** are destroyed at the failure point, before the
failure arm (the `else` block, or loop exit) runs. This is the same rule
`match` `case` failure follows, specified by
[proposal #5164](/proposals/p005164-updates-to-pattern-matching-for-objects.md)
and
[pattern matching](../pattern_matching.md#pattern-match-control-flow); these
forms reuse it unchanged.

### Evaluation order and conversions

The scrutinee expression is evaluated once per match attempt (once for `if`
and `let ... else`; once per iteration for `while`), and the match proceeds
with the conversions, materialization, and
[evaluation order](../pattern_matching.md#evaluation-order) of any other
full-pattern match, per proposals #2188 and
[#5545](/proposals/p005545-expression-form-basics.md). Pattern-match
evaluation stops as soon as failure is known, so only a prefix of the
pattern's side effects may occur on the failure path — exactly as in a
`case`.

### Irrefutable patterns

An irrefutable pattern in any of these forms is valid but diagnosed with a
warning: the condition can never fail, so an ordinary `let`/`var` declaration
or a plain loop expresses the code more directly. Keeping the degenerate case
legal (rather than a hard error) keeps generated and macro-style code
working.

> OPEN (sub-fork): severity for an irrefutable pattern in a combined form —
> warning (Rust's `irrefutable_let_patterns`) or hard error (Swift's rule for
> `guard let` of non-optionals). Recommendation: warning.

## Reserved for future extensions

The following are **not in 0.1**:

-   **Chaining**: boolean chaining of pattern conditions,
    `if (let P = e and cond)` (Rust let-chains).
-   **Condition guards**: `if`-guards inside the condition.
-   **Expression forms**: an if-let _expression_, or any value-yielding
    match form.

Condition guards and expression forms occupy syntax that no 0.1 program can
use, so they can be added later without changing the meaning of existing
code. Chaining is different: `and` and `or` are ordinary binary expression
operators, so `if (let P = e and cond)` already parses in 0.1 with
`e and cond` as the initializer expression. Reserving the let-chain reading
therefore requires restricting the top level of a pattern-condition
initializer to exclude `and` and `or` (diagnosed with a "parenthesize the
initializer" fixit — the same move the
[initializer restriction](#initializer-restriction) makes for `if`
expressions, and the analog of Rust RFC 2497's restriction on let-chain
operands). Without that restriction, adding chains later would change the
meaning of legal programs.

> OPEN (sub-fork): ratify this reservation list — that `and`-chaining,
> condition guards, and expression forms stay out of 0.1 (bringing chaining
> in raises the parse cost and requires extending #5545's evaluation-order
> text). Recommendation: all three stay out of 0.1.

> OPEN (sub-fork): whether 0.1 restricts the top level of a
> pattern-condition initializer to exclude `and`/`or` (diagnosed with a
> parenthesize fixit), keeping let-chains addable without reparsing, or
> allows them and accepts that a future chaining extension would change the
> meaning of some legal programs. Recommendation: restrict with a fixit.

## Relationship to the `?` operator

Fork decision [F-006](/fork/decision-log.md) fixed that the postfix
[`?` operator](../error_handling.md#error-propagation-the-postfix--operator)
is specified by a `match` expansion and implemented directly on the same
refutable-match core these forms lower onto: `expr?` is a compiler-internal
one-case refutable match whose failure arm returns from the enclosing
function. F-011 records the corresponding hook from this side: this
document's core is the desugaring target — a future or present `?` adds no
second pattern-matching construct. In source terms, `?` is the automated
special case of the guard idiom that `let ... else` spells manually:

```carbon
// These behave identically (modulo `?`'s error conversion):
let .Ok(f: File) = Open(name) else { return .Err(<converted error>); }
let f: File = Open(name)?;
```

The division of labor is: `?` for propagate-to-caller, `let ... else` for any
other divergence (`break`, `continue`, returning a default), `if (let ...)`
when both outcomes continue in the same function, and full `match` when more
than one alternative is interesting.

## C++ interoperability

These forms are intra-function control flow with no ABI or export surface;
they are invisible to C++ and require no thunks or header support. Their
interop value is consumption-side ergonomics: once the choice-payload and
sum-type interop work lands (see
[Dependencies](#dependencies-and-implementation-staging)), they give the
obvious and unsurprising translations of the dominant C++ idioms:

| C++ idiom                             | Carbon translation                       |
| ------------------------------------- | ---------------------------------------- |
| `if (opt) { use(*opt); }`             | `if (let .Some(x: T) = opt) { Use(x); }` |
| `if (auto* p = std::get_if<T>(&v))`   | `if (let .Alt(x: T) = v) { ... }`        |
| `if (!opt) return;` guard clause      | `let .Some(x: T) = opt else { return; }` |
| `while (auto item = q.Pop()) { ... }` | `while (let .Some(item: T) = q.Pop())`   |

## Dependencies and implementation staging

Stated plainly, per the fork's staging discipline:

-   **Hard dependency — the refutable-match core (workstream W4).** The
    `match` statement skeleton is implemented: slice 1 (fork decision
    [W4-S1](/fork/decision-log.md)) checks and lowers `match` with an
    integer scrutinee, integer-literal `case` patterns, and a `default` arm.
    What this design needs and what remains W4's outstanding deliverable is
    the refutable-match **core** — pattern-to-CFG with a failure edge,
    bindings in `case` patterns placed in dominated blocks, failure-path
    destruction, and guards — today gated behind the check stage's
    semantics-TODO diagnostics
    (`toolchain/check/handle_match.cpp`). This design is specified as a
    client of that core and its implementation lands **after** it, as the
    second refutable context. Until then, this document is design-only, as
    [error handling](../error_handling.md#implementation-staging) already
    records for its F-011-dependent consumption forms.
-   **Soft dependency — choice payloads and sum-type interop (workstream
    W5).** The forms work today-in-principle on tuple, struct, and
    expression patterns without W5, but the motivating examples —
    `.Some(x: T)` over `Optional`, `Core.Result`, and imported
    `std::optional`/`std::variant` — need payload-carrying choice
    alternatives and the W5 interop mapping. `Core.Optional` is additionally
    a placeholder class today, not a choice type; its rebuild is part of the
    same W5 work (see
    [error handling](../error_handling.md#implementation-staging)).
-   **No lexer work and no lowering work.** All tokens (`if`, `while`,
    `let`, `var`, `else`) exist; and because the forms desugar onto the
    refutable-match core, they lower through ordinary branches with no new
    SemIR instruction kinds.

The conformance plan for this area is: a W5-free program (tuple/struct
patterns) so the forms are arbitrated independently of W5, plus the
`Optional`/`variant` programs gated on W5. As of this writing, only the
pre-design SKIP stub
`fork/conformance/programs/control_flow/if_let_let_else.carbon` exists; its
SKIP evidence and strawman syntax predate this design and must be rewritten
to the accepted grammar, and the W5-free program must be added.

## Decisions within this design

The following are fixed by fork decision [F-011](/fork/decision-log.md) and
are not open:

-   **D1 — The surface is `if (let ...)` / `while (let ...)` plus
    `let ... else`** (option A of the
    [option paper](/fork/design-sprint/if-let.md)), using existing keywords,
    parenthesized conditions, and required braces. The alternatives —
    `is`-expressions with flow-sensitive scoping, a `guard` keyword, and
    match-only — were rejected; see
    [Alternatives considered](#alternatives-considered).
-   **D2 — Binding scope**: success-path scope for the positive and loop
    forms; **enclosing scope** for `let ... else`.
-   **D3 — Divergence in 0.1 is the syntactic list
    `return`/`break`/`continue`**; a type-based noreturn rule is deferred to
    the safe-Carbon workstream.
-   **D4 — Both forms are specified as desugarings onto the refutable-match
    core** (a one-case `match` with the failure arm as the else/exit
    target), so `match`, these forms, and `?` share one pattern-matching
    semantics and one implementation.
-   **D5 — The future `?` operator desugars onto this same core**, per fork
    decision F-006; this document is the desugaring target, not a parallel
    mechanism.
-   **D6 — `while (let ...)` is in 0.1**, included in the F-011 decision.

Points with more than one defensible answer are **not** decided here; they
are marked `OPEN (sub-fork)` in the sections above and collected in
[Open sub-forks](#open-sub-forks).

## Alternatives considered

The alternatives for this area were researched in the option paper
([fork/design-sprint/if-let.md](/fork/design-sprint/if-let.md)) and rejected
in fork decision [F-011](/fork/decision-log.md):

-   **`is` pattern-test expressions with flow-sensitive scoping** (C#-shaped,
    option B): one composable construct, but it requires flow-sensitive name
    scoping — a new compiler concept with famously subtle rules under
    negation, `or`, and loops — puts pattern grammar mid-expression against
    the spirit of
    [low context sensitivity](/proposals/p000646-low-context-sensitivity-principle.md),
    and has no upstream artifact pointing toward it.
-   **`guard let ... else`** (Swift-shaped, option C): identical semantics to
    `let ... else` for the cost of a new keyword — one that collides with a
    common identifier in exactly the C++ code Carbon imports
    (`std::lock_guard`), forcing `r#guard` escapes — while proposal #2188's
    own reservation cites the `let ... else` shape.
-   **`match` only** (option D): fails the 0.1 milestone bullet as written —
    it explicitly names both combined forms — and leaves the guard-clause
    idiom a five-line nested rewrite.

That decision is final; this document specifies the chosen design rather than
relitigating it.

Upstream note: upstream issue
[#5101](https://github.com/carbon-language/carbon-lang/issues/5101)
("patterns as control flow conditions") is a live, un-proposed discussion of
this same area. Every candidate surface in it shares this document's
semantics (the #2188 pattern grammar, #5164 failure destruction,
enclosing-scope `let ... else` bindings, diverging `else`); if upstream later
accepts a different spelling, migration is a mechanical re-spell over
identical semantics.

> OPEN (sub-fork): tracking policy if upstream #5101 produces an accepted
> proposal mid-implementation — pause and adopt upstream's spelling, or
> finish this spelling and migrate mechanically afterward. Recommendation:
> finish this spelling and migrate afterward.

## Open sub-forks

Per the fork's process rule that every sub-decision with more than one
defensible answer goes to the user
([fork/process.md](/fork/process.md#human-in-the-loop-rule)), the following
points are marked OPEN in the sections above and are **not** decided by this
document. Each is listed with this document's recommendation.

-   **F-011a — `let ... else` terminator** (see [Grammar](#grammar)): does
    the declaration end at the `else` block's `}`, or require a trailing
    `;` as in Rust? Recommendation: no `;` — statement-like, matching `if`.
-   **F-011b — divergence-check depth** (see
    [The divergence requirement in 0.1](#the-divergence-requirement-in-01)):
    flat last-statement check, or recursive all-paths syntactic check?
    Recommendation: flat in 0.1.
-   **F-011c — initializer ambiguity rule** (see
    [Initializer restriction](#initializer-restriction)): forbid
    unparenthesized `if` expressions as `let ... else` initializers with a
    fixit, or parse greedily in favor of the if-expression? Recommendation:
    forbid with a fixit.
-   **F-011d — `var` spellings in 0.1** (see [Grammar](#grammar)): are
    `if (var ...)`, `while (var ...)`, and `var ... else` in 0.1, or
    deferred? Recommendation: in 0.1; defer only if `var`-in-`case`
    implementation slips.
-   **F-011e — irrefutable-pattern severity** (see
    [Irrefutable patterns](#irrefutable-patterns)): warning or hard error?
    Recommendation: warning.
-   **F-011f — future-extension reservation list** (see
    [Reserved for future extensions](#reserved-for-future-extensions)):
    ratify that `and`-chaining, condition guards, and expression forms stay
    out of 0.1. Recommendation: ratify as listed (whether the chaining slot
    is grammar-reserved is F-011h).
-   **F-011g — upstream #5101 tracking policy** (see
    [Alternatives considered](#alternatives-considered)): pause-and-adopt
    versus finish-and-migrate if upstream accepts a proposal
    mid-implementation. Recommendation: finish this spelling and migrate
    mechanically afterward.
-   **F-011h — top-level `and`/`or` restriction on pattern-condition
    initializers** (see
    [Reserved for future extensions](#reserved-for-future-extensions)):
    restrict the top level of a pattern-condition initializer to exclude
    `and`/`or` (parenthesize-with-fixit), keeping let-chains addable without
    changing the meaning of existing code, or allow them and give up that
    reservation. Recommendation: restrict with a fixit.

## References

-   [Milestones: control flow statements — Matching](/docs/project/milestones.md)
    — the 0.1 bullet this design closes ("Both positive (`if let` in Rust)
    and negative (`let else` in Rust) combined match control flow and
    variable declaration")
-   [Pattern matching](../pattern_matching.md) / Proposal
    [#2188: Pattern matching syntax and semantics](https://github.com/carbon-language/carbon-lang/pull/2188)
    — the shared pattern grammar, refutability, and the reserved
    `let`-`else` context
-   Proposal
    [#5164: Updates to pattern matching for objects](https://github.com/carbon-language/carbon-lang/pull/5164)
    — failure-path destruction
-   Proposal
    [#5545: Expression form basics](https://github.com/carbon-language/carbon-lang/pull/5545)
    — pattern-match evaluation order
-   Proposal
    [#623: Require braces](https://github.com/carbon-language/carbon-lang/pull/623)
    and Proposal
    [#646: Low context sensitivity principle](https://github.com/carbon-language/carbon-lang/pull/646)
    — the surface-style constraints
-   [Conditionals](conditionals.md) and [Loops](loops.md) — the statements
    these forms extend
-   [Error handling](../error_handling.md) — `Core.Result` consumption and
    the `?` operator that shares this design's core (fork decision F-006)
-   Upstream issue
    [#5101: patterns as control flow conditions](https://github.com/carbon-language/carbon-lang/issues/5101)
    and upstream PR
    [#1871: var/let ... else](https://github.com/carbon-language/carbon-lang/pull/1871)
    (never merged; cited by #2188)
-   Fork decision [F-011](/fork/decision-log.md) and option paper
    [fork/design-sprint/if-let.md](/fork/design-sprint/if-let.md)
