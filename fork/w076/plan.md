<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-076 plan: `bool` match scrutinees

Status: PLAN. Drafted 2026-09-26. Size S — one slice (W76a).
Baseline: trunk a715b66 (post-PR #35, W-066 landed; conformance
**99 PASS / 0 FAIL / 28 SKIP over 127**). Authoritative record:
fork/inventory/work-items.json W-076. NO implementation in this document.
All goldens ride runner-side autoupdate to fixpoint (R15/R19/R26); no
hand-authored CHECK lines (R16a).

Scope sentence: admit plain `bool` at the match scrutinee gate and treat it
as the two-alternative finite domain the design mandates
(docs/design/pattern_matching.md:591 — "`bool` is treated like a choice
type" with alternatives `false` and `true`): `case true`/`case false`
dispatch through the existing expression-pattern `==` lane after a
deliberate widening of the R9 constant-integer admission to bool constants,
`true`/`false` coverage records the way choice alternatives record (S2e
`covered_alternatives`), exhaustiveness extends (both values covered ⇒ no
`default` needed; a missing value is a real nonexhaustive error, not a
TODO), and the W-066 usefulness domain gains bool constant keys FROM THE
START, per the ledger sentence written for exactly this moment (W-066
discharge notes, work-items.json W-066; fork/w066/plan.md §1.7 break
condition "bool scrutinees: a finite two-value root domain").

## §1 Adjudications

Each with citation and break condition. "Bool type" throughout means the
`SemIR::BoolType` singleton (sem_ir/typed_insts.h:307), compared after
`GetUnqualifiedType` (so `const bool` rides along, matching the int gate's
qualifier handling at handle_match.cpp:163-165).

**1.1 Exhaustiveness: both-values-covered needs no `default`; a missing
value is `MatchNonexhaustive`-class, not a TODO.** The design's own worked
example is a bool match: `IsTrue` with `case false` + `case true` and no
`default` is "Considered exhaustive" (pattern_matching.md:610-617), by way
of :591's bool-as-choice rule. So the SF-7 machinery extends: `MatchStatement`'s
no-`default` branch (handle_match.cpp:1322-1341) must route bool to
`DiagnoseNonexhaustiveMatch` instead of the integer TODO at :1329, and the
diagnostic for a one-value match without `default` names the missing value.
`case true` + `default` works today-shaped: `has_default` short-circuits
the whole branch (:1327), no bool-specific code runs. Message form decided
in §2.3. Break: if reviewers find a design passage requiring `default` on
bool matches (none exists — :610-617 is explicit), this collapses to a gate
widening only.

**1.2 Usefulness: bool keys in the W-066 domain from the start, including
the union-coverage analog.** The ledger mandates it (work-items.json W-066:
"its usefulness domain should include bool constant values from the
start"; W-076 notes: same sentence). Duplicate `case true` dies by
single-prior subsumption once bool constants key (§2.4). The union analog —
`case true` + `case false` priors kill a later binding-rooted arm that no
single prior subsumes — is real for bool exactly as W-066's convergent
major found for choice roots (fork/w066/plan.md, review fold), and the
design counts it: usefulness is extensional ("there exists a value...",
pattern_matching.md:577-579, :627), and bool's domain is the pair.
Mechanism decided: **generalize step 3b** (handle_match.cpp:788-830) with a
bool branch — wildcard root + bool scrutinee + `covered_alternatives`
containing both 0 and 1 — rather than a separate pair-check pass, because
step 3b already owns exactly this shape (finite root domain, union of
priors, statement-level note) and a second mechanism would be R17 bait.
Break: if the reuse forces contortions (it should be ~6 lines), fall back
to a self-contained pair check at the same site with the same note.

**1.3 The R9 widening: exactly concrete bool constants added.** The gate at
pattern_match.cpp:1265-1273 (`is_concrete()` + `Is<SemIR::IntValue>`)
widens to admit a concrete constant whose inst is `SemIR::BoolLiteral`
(typed_insts.h:294 — bool constants are `BoolLiteral` insts, per
eval.cpp:415 construction and :2504 constant reads; there is no separate
"BoolValue inst"). Everything else stays gated: non-constant bool
expressions (`case b2` naming a runtime `var` or a `let` binding — not
constants, see `WrapperBinding` note at :1270-1272), symbolic constants in
generics (`is_concrete()` fails), float/choice-constant leaves. The TODO
string becomes honest: `match case expression pattern that is not a
constant integer or `bool`` — updated at the ONE site, re-pinning
match/fail_todo_non_constant_case.carbon (:22/:41) and
operators/fail_question.carbon (:175) by autoupdate (message-text-only
churn, §6). W8c's polish-declined note (work-items.json W-008 R9: "bool
/f64/choice-constant leaves get this same, admittedly loose, wording")
is half-discharged: bool leaves the wording; f64/choice-constant stay,
still honestly covered by "not a constant integer or `bool`". The R9
residue's "must not widen before W-066" fence is lifted: W-066 landed, and
this widening ships WITH its key extension (§1.2), never without. Break: if
any admitted shape reaches the `==` build without a concrete `BoolLiteral`
constant, the widening predicate is wrong — it is a two-clause `Is<>`
check, nothing else.

**1.4 Guards/bindings/`var`/`ref` compose for free.** Verified: the arm
machinery is scrutinee-type-generic. Binding arms short-circuit to a
constant-true condition and bind by way of `LocalPatternMatch`
(handle_match.cpp:725-726, :928-930 — type-agnostic); guards convert to
`bool` in the arm's body block after the bind pass (W8b fix round 3,
work-items.json W-008 history) with no scrutinee-type dependence; `var`
/`ref` roots ride `EmitCaseArmTestAndBind`'s classification, which branches
on pattern kind, not scrutinee type. Nothing to build; §4 carries one
compose golden as evidence. Break: any compose test failing means a hidden
type dependence — stop and file, don't patch inline.

**1.5 Tuple elements of bool: IN scope, automatic.** The tuple walk gates
by pattern KIND and shape, not element type (`DoMatchCaseTuplePreWork`,
pattern_match.cpp — the non-tuple-scrutinee and arity gates; element
subpatterns route to `DoMatchCaseExprPattern` with the element
sub-scrutinee). Once `IsSupportedScrutineeType` admits bool
(worklist-recursive, handle_match.cpp:154-188 — elements are pushed and
re-checked at :180-184) and R9 admits `BoolLiteral` constants, `case
(true, 1)` on `(bool, i32)` works with zero tuple-lane code: the element
comparison is `bool as EqWith(bool)`, and the element keys as `BoolConst`
under the existing `Tuple` key node (§2.4). IN scope, with goldens (§4
P5). Break: if the walk turns out to type-gate elements anywhere, tuple-of
-bool moves out of scope and that gate is named in the discharge notes.

**1.6 Scrutinee gate stays strict to plain `bool`; adapters and
convertibles are OUT.** The gate admits exactly the unqualified
`SemIR::BoolType` singleton. No `ConvertToBoolValue` on the scrutinee:
`MatchCondition` converts to value-or-ref only (handle_match.cpp:202) and
`if`-style bool conversion is a condition-position rule, not a scrutinee
rule — match dispatches on the scrutinee's own type (choice, int) and bool
follows suit. A class adapting `bool` (and any `Cpp` adapter shape) stays
behind the scrutinee TODO, exactly as int adapters beyond `Int(N)`
/`UInt(N)` do today (:206-210, pinned by fail_todo_adapter_scrutinee.carbon
:21). Recorded as residue, not extended scope. Break: a design cite
requiring implicit scrutinee conversion would reopen this; none exists in
pattern_matching.md's match section.

## §2 Mechanism

**2.1 Gate change** (handle_match.cpp:154-188): in
`IsSupportedScrutineeType`'s worklist loop, admit
`context.types().Is<SemIR::BoolType>(context.types().GetUnqualifiedType(
current_type_id))` alongside `is_int_scrutinee ||
IsMatchableChoiceType(...)` at :174. Tuple elements inherit it by way of the
worklist (:180-184). The trivially-destructible cleanup argument at the
gate (:216-225) extends: bool has no destroy function. Comment updates:
"Three scrutinee shapes" → four (:203, file header :49).

**2.2 Comparison lane: the existing expression-pattern `==` lane,
unchanged — adjudicated over a direct branch.** After the R9 widening, a
bool constant case falls into the existing build at
pattern_match.cpp:1294-1300: `BuildBinaryOperator` with
`CoreIdentifier::EqWith`, interface arg = scrutinee type, operand order
_expression_ `==` _scrutinee_ as the design mandates
(pattern_matching.md:87, quoted at :1288-1292). Evidence this works
end-to-end for bool: `impl bool as EqWith(Self)` exists in the production
prelude (core/prelude/operators/comparison.carbon:35, builtins `bool.eq`
/`bool.neq`), `BuiltinFunctionKind::BoolEq` is wired in constant eval
(check/eval.cpp:2507, :2919) and in lowering (lower/handle_call.cpp:28,
:588). Against the direct-branch alternative (condition = scrutinee for
`case true`, negation for `case false`, the way `if` lowers a converted
bool by way of `BranchIf`): it would fork the expr-pattern lane per scrutinee
type against RF-4's uniform constant classification, `case false` needs a
negation inst the case lane doesn't otherwise build, and it buys nothing —
LLVM folds `icmp eq i1 %b, true` to `%b`, so the EqWith lane IS the direct
branch after trivial optimization, while staying on the design's stated
`==` semantics. Zero new comparison or lowering code. Cost: bool match
testdata needs the full prelude (min_prelude/parts/bool.carbon has no
EqWith impl) — 48 of 59 existing match goldens already use
min_prelude/full.carbon; new files follow. A `default`-only bool match
emits no comparison and stays min_prelude-clean.

**2.3 Coverage recording + nonexhaustive message.** Recording (the S2e
block, handle_match.cpp:846-862): add a branch after the alternative case —
unguarded arm, scrutinee unqualified type is bool, root is an
`ExprPattern` whose region-result constant is a concrete
`SemIR::BoolLiteral` → `covered_alternatives.push_back(value.ToBool() ? 1
: 0)` (`BoolValue::False`=0/`True`=1, sem_ir/ids.h:528-529; the constant
is read exactly where the key builder reads it, by way of a small shared helper
`TryGetCaseBoolConstant(context, pattern_id)`). `covered_alternatives`'s
contract ("possibly with duplicates", context.h:377-381) is unchanged;
indices 0/1 cannot collide with choice discriminants because a statement
has one scrutinee type. `has_irrefutable_arm` interplay: untouched —
binding roots keep setting it, and it short-circuits
`DiagnoseNonexhaustiveMatch` (:1248) before any bool logic runs.
Exhaustiveness: `MatchStatement`'s no-`default` branch (:1322-1341)
becomes "choice or bool → `DiagnoseNonexhaustiveMatch`; else (int) → the
existing :1329 TODO". Inside `DiagnoseNonexhaustiveMatch` (:1245), a bool
branch goes BEFORE the `GetAs<SemIR::ClassType>` at :1254-1255 (which
would CHECK-fail on the bool singleton): missing = {`false` if 0 not
covered, `true` if 1 not covered}, in domain order (false, true) mirroring
the alternative-table order; if empty, return. Diagnostic story decided:
bool values are not named alternatives, so `MatchNonexhaustive`'s wording
("on choice {0} ... alternative{1:s} `.Y`", :1292-1295) does not fit; a
NEW parallel diagnostic:

```
CARBON_DIAGNOSTIC(MatchNonexhaustiveBool, Error,
                  "`match` on `bool` has no `default` arm and does not "
                  "cover value{0:s} {1}",
                  Diagnostics::IntAsSelect, std::string);
```

with {1} = `` `false` ``, `` `true` ``, or `` `false`, `true` `` — for example
"`match` on `bool` has no `default` arm and does not cover value `true`".

**2.4 Usefulness keying, incl. the union rule.** Key builder
(`BuildMatchCaseUsefulnessKey`, pattern_match.cpp:693-792): at the
`ExprPattern` leaf (:774-782), when the concrete constant is not an
`IntValue`, try `SemIR::BoolLiteral` → push a NEW node kind
`Kind::BoolConst`, value in the existing `index` field (0/1); else the
nullopt fallback stands. A new kind over mapping to `IntConst` is the
evidence-based choice: `IntConst` is documented and compared as "keyed by
its evaluated constant['s] `IntId`" (context.h:342-347;
handle_match.cpp:603-608) and `BoolLiteral` carries a `BoolValue`, not an
`IntId` — synthesizing an `IntId` for 0/1 would need an ints-store write
the key path otherwise never does and a multi-sentence justification
(R17); the new kind is one enum value, one field reuse, one subsumption
case. `UsefulnessKeySubsumes` (handle_match.cpp:586-631): add `case
Kind::BoolConst:` — equal kind and equal `index`, else not subsumed
(mirrors `IntConst`). Union rule: extend step 3b (:788-830) — the wildcard
-root condition at :790-793 gains "or scrutinee is bool", with `covers_all`
for bool = `covered_alternatives` contains 0 AND 1, and the note REUSES
`MatchCaseNeverMatchesFullCoverage` ("all alternatives of {0} are matched
by prior arms", :814-816) with the bool TypeId — licensed one-sentence by
pattern_matching.md:591: `bool` is treated like a choice type whose
alternatives are `false` and `true`. (Wording flagged as open question
OQ-1.) Guarded-prior exclusion, dead-arm non-recording into `useful_arms`,
and the `default` exemption (W-078) all carry over untouched.

**2.5 R9 widening site + exact predicate** (pattern_match.cpp:1265-1273):

```
auto const_inst_id = context_.constant_values().GetInstId(pattern_const_id);
if (!pattern_const_id.is_concrete() ||
    !(context_.insts().Is<SemIR::IntValue>(const_inst_id) ||
      context_.insts().Is<SemIR::BoolLiteral>(const_inst_id))) {
  context_.TODO(introducer_node_id,
                "match case expression pattern that is not a constant "
                "integer or `bool`");
```

The RF-4 comment block (:1256-1264) extends: like the int-adapter
admission it documents, a TYPE-mismatched bool constant (`case true` on an
`i32` scrutinee, `case 5` on a bool scrutinee) now reaches the `==` build
and produces a real missing-impl operator diagnostic (`bool as
EqWith(i32)` / `IntLiteral as EqWith(bool)` do not exist) instead of the
old TODO — deliberate, pinned in §4 F5, same precedent as RF-4's recorded
behavior. The choice-scrutinee branch (:1176-1246) is untouched: a bool
constant on a choice scrutinee keeps its dedicated W8c TODO. No lowering
changes anywhere (2.2).

## §3 Single slice W76a, commit structure

One PR off trunk a715b66. Commits:

1.  `W76a: admit bool match scrutinees` — all compiler changes (§2.1-§2.5:
    handle_match.cpp, pattern_match.cpp, context.h enum + comments), no
    testdata.
2.  `W76a: testdata + conformance` — new goldens with AUTOUPDATE markers
    and NO CHECK lines (R15), the repurposed pin (§4 F7), the conformance
    program + README row (§5).
3.  Runner-side autoupdate commit(s) to fixpoint (R26 — expect two passes;
    new files add CHECK lines, so pass-2 must be locNN-only).

Then R11 loop: two adversarial implementation reviews → fixer.

## §4 Testdata matrix (toolchain/check/testdata/match/; all AUTOUPDATE

authored CHECK-free per R15/R16; full prelude unless noted)

Positives:

-   **P1** `bool_scrutinee.carbon` — subfiles: (a) `case false` + `case
    true`, no `default` (exhaustive; pattern_matching.md:610-617 shape);
    (b) `case true` + `default`; (c) constant-expr case (`case true` with
    a runtime scrutinee and `case 1 == 1`-style bool constant if the
    expression form checks — else `true` only); (d) `match (true)`
    constant scrutinee (constant-folds by way of eval BoolEq, mirroring
    constant_scrutinee.carbon).
-   **P2** `bool_scrutinee.carbon` subfile (compose): binding arm `case
    b2: bool`, guarded arm `case true if (c) => ...` + `default`
    (guarded arm records nothing; default required and present).
-   **P3** subfile: `case var v: bool` and `ref` binding on a durable bool
    scrutinee (rides W8b machinery; §1.4 evidence).
-   **P4** subfile: `case false` first then `case true` (order
    irrelevance of coverage).
-   **P5** `bool_tuple_scrutinee.carbon` — `(bool, i32)` scrutinee, `case
    (true, 1)`, `case (false, n: i32)`, `default`; and a `(bool, bool)`
    exhaustive-by-default variant (tuple exhaustiveness itself stays
    default-requiring — only the bool ROOT rule extends, tuples still
    require `default`; pinned so the boundary is explicit).

Fails (expected diagnostics named; exact text lands by way of autoupdate):

-   **F1** `fail_bool_nonexhaustive.carbon` — (a) only `case true`, no
    `default` → `MatchNonexhaustiveBool` naming `` `false` ``; (b) only
    `case false` → naming `` `true` ``; (c) only a guarded `case true if
    (c)` → naming `` `false`, `true` `` (guards never cover, :852-853
    rule); (d) guarded `default` only → same (guarded `default` never
    discharges, handle_match.cpp:100-105 comment).
-   **F2** `fail_bool_case_never_matches.carbon` — duplicate `case true`
    → `MatchCaseNeverMatches` + `MatchCaseNeverMatchesPriorArm` note
    (single-prior BoolConst subsumption).
-   **F3** same file, subfile — `case true` + `case false` then `case b2:
    bool` (and a `default`-less variant is F1 territory; this one keeps
    the arms legal) → `MatchCaseNeverMatches` +
    `MatchCaseNeverMatchesFullCoverage` statement-level note (union rule,
    §2.4); also `case true` + `case false` then `case true` → single-prior
    note (first-covering-arm determinism).
-   **F4** `fail_todo_non_constant_bool_case.carbon` — R9-still-gated
    shapes on a bool scrutinee: `case b2` naming a runtime `var` and a
    `let` binding → the UPDATED TODO string (`...not a constant integer
    or `bool``).
-   **F5** `fail_bool_case_type_mismatch.carbon` — `case true` on `i32`
    scrutinee and `case 5` on bool scrutinee → real missing-impl operator
    diagnostics (§2.5; no longer TODOs).
-   **F6** tuple deadness — in P5's file or F2's: `case (true, 1)` then
    `case (true, 1)` → duplicate by way of `Tuple`+`BoolConst` keys.
-   **F7** pin flip: `fail_todo_non_int_scrutinee.carbon`'s bool probe
    compiles clean after W76a, so the file is REPURPOSED, not deleted
    (R16b-honest): the probe body becomes a still-gated non-int scrutinee
    (an empty `class C {}` value), keeping the
    `match on unsupported scrutinee type` string pinned under its
    accurate name alongside fail_todo_adapter_scrutinee.carbon; the bool
    shape moves to P1 as a positive. Ledger R7 pin list updates at
    discharge.

Lowering: **L1** `toolchain/lower/testdata/match/bool_scrutinee.carbon` —
the P1(a) exhaustive shape, showing BoolEq lowering + arm convergence
(one file; the builtin lane is pre-existing, the bool dispatch CFG shape
is new).

## §5 Conformance

The good-switch bullet ("Control flow: matching — good switch
equivalents") already PASSes on 8 programs (fork/conformance/README.md:248
-259); nothing is owed for it in gap-analysis. A bool-match program still
strengthens the bullet at runtime (C/C++ `switch` cannot dispatch on
`bool` cleanly — this is a Carbon-side "good switch" win): add ONE run
program `control_flow/match_bool.carbon` under that bullet — runtime
bool from a function argument, `case true`/`case false` exhaustive match
without `default`, a guarded arm variant, printed outputs with
EXPECT-STDOUT. Floor GAINS: expected **100 PASS / 0 FAIL / 28 SKIP over
128** (99→100; no existing program is touched, so 0 FAIL is the hard
floor).

## §6 Existing-golden impact

Complete expected churn list (anything beyond this at regen is a stop-and
-diagnose signal):

1.  `toolchain/check/testdata/match/fail_todo_non_int_scrutinee.carbon` —
    repurposed (§4 F7); full regen.
2.  `toolchain/check/testdata/match/fail_todo_non_constant_case.carbon` —
    R9 string change, message-text-only (:22, :41).
3.  `toolchain/check/testdata/operators/fail_question.carbon` — same
    string (:175), message-text-only.

Nothing else: no existing golden contains `case true`/`case false` or a
bool scrutinee (grepped testdata; the only bool-scrutinee probe is the F7
pin), the choice/int/tuple lanes are byte-identical for non-bool types
(every change is behind a bool-type or BoolLiteral test), and parse
testdata is untouched (parse already accepts these shapes).

## §7 Risks

-   **R-1 `DiagnoseNonexhaustiveMatch` order**: the bool branch must
    precede the `GetAs<ClassType>` (:1254) or bool crashes there.
    Covered by F1; cheap to verify.
-   **R-2 dead-arm coverage recording** (W-066 discharge note for W-076
    extenders): the recording block runs for diagnosed-dead arms.
    For bool this stays behavior-invisible: a dead `case true` re-pushes
    a value its killer already covers, and a dead wildcard root (union
    -killed) sets `has_irrefutable_arm` only when both values are already
    covered — exhaustiveness is satisfied either way. Argument recorded
    here so reviewers can falsify it.
-   **R-3 min_prelude coupling**: full-prelude testdata is slow (~1s
    /file); accepted, matching the 48 existing match goldens. The
    `default`-only shapes stay on minimal preludes.
-   **R-4 type-mismatch UX** (§2.5): TODO→missing-impl for `case true` on
    `i32` could read as a regression in friendliness. Precedent: RF-4
    recorded exactly this for int-adapter constants. F5 pins it; OQ-3.
-   **R-5 key-kind drift**: a future IntId-backed unification would
    re-touch subsumption; `BoolConst` is additive and confined to two
    switch sites, so the cost is bounded.

## §8 Verification

1.  Local: `uvx prek run` before every push (R21); bazelisk build +
    targeted file_tests for the new/changed goldens.
2.  Runner: autoupdate workflow fills the CHECK-free goldens; fire pass 2
    and confirm locNN-only diff (R26). Regen must touch ONLY §4's new
    files + §6's three — any other churn is a defect signal.
3.  Gate (`Fork: build toolchain`): green.
4.  Conformance: expected **100/0/28 over 128** (§5). 99 remains the
    absolute floor; a FAIL anywhere is a stop.
5.  Discharge: ledger updates — W-008 R7/R9 residue pin lists, W-076
    notes, decision-log entry; follow-ups only if reviews surface them.

## Open questions for reviewers

-   **OQ-1**: reuse `MatchCaseNeverMatchesFullCoverage`'s "all
    alternatives of `bool`" wording (design-licensed by way of :591) or mint a
    bool-specific note ("both values of `bool` are matched by prior
    arms")? Plan says reuse; wording is a one-line swap if reviewers
    prefer.
-   **OQ-2**: `MatchNonexhaustiveBool` message form (§2.3) — acceptable,
    or fold into `MatchNonexhaustive` with generalized wording (would
    churn every choice-nonexhaustive golden; plan says no)?
-   **OQ-3**: is the §2.5 TODO→missing-impl change for cross-type bool
    /int constants acceptable now (plan: yes, RF-4 precedent), or should
    a type pre-check keep a friendlier diagnostic?
-   **OQ-4**: F7's repurposed probe type (empty class) — any preference
    for a different still-gated scrutinee (for example `f64`)?
