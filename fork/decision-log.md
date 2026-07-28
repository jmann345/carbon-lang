# Decision log

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

Every design fork — a point where the user chose among researched options —
is recorded here. Format: context, options considered, decision, date,
consequences. Undecided forks are listed as OPEN at the top.

## OPEN forks

(none — F-001..F-011 all decided)

## Decided

### V-1..3: viability-review decisions (user by way of AskUserQuestion, 2026-07-20)

**V-1: fork-0.1 targets Linux/macOS** — F-001 amended; Windows recorded
as post-0.1 (XL item stays visible in the gap analysis and inventory).
**V-2: veto-digest model replaces always-ask** — synchronous
AskUserQuestion rounds only for genuine forks (design divergence, scope
trades, north-star tension); mundane sub-decisions auto-adopt the
recommendation and appear in a per-merge veto digest the user can
overturn (overturned items get reworked before the next merge).
**V-3 (as amended by V-3a, 2026-07-20): upstream alignment as veto
criterion, not permission gate** — decisions that CONTRADICT upstream's
accepted proposals or recorded leads' direction are vetoed; where
upstream is ambiguous or silent, creative fork design is permitted and
progress must not slow to await upstream signals; upstream intent is the
default preference, overridable with stated good reason. Ratified designs
F-006..F-011 stand (audit: each was already the lowest-divergence option;
none contradicts an accepted proposal), but genuinely fork-local
spellings (for example F-006a Ok/Err vs the README's illustrative
Success/Failure) enter a divergence-risk register reviewed at each
upstream merge.

### B0 SF-1..5: exception-boundary implementation sub-forks (user by way of AskUserQuestion, 2026-07-20)

Fence = noexcept exception-spec on the thunk type; boundary-identifying
diagnostic recorded as a B3 follow-up (1); explicit mode wins over user
clang args, appended last, justified as a boundary contract not a tuning
default (2); flag on `carbon compile` only for B0 (3); auto resolves from
Clang's final LangOpts, not arg-string scanning (4); the exception-interop
bullet flips PASS on B0's boundary-contract slice with this recorded
scope trade — catching-into-Result stays a visible SKIP until B3 (5).

### W5-S1: scope trades in choice-payload slice 1 (2026-07-19)

Process/scope decisions made by Claude during S1 implementation under
standing rule 6 (language semantics follow docs/design/sum_types.md and the
ratified SF-1..8 outcomes unchanged); recorded per process step 4 so the user
can overrule. Also records, per plan §0.3, that the `Match`
interface/Continuation mechanism of sum_types.md:124-246 (user-defined sum
types) is OUT of the whole W5 workstream — S1 match consumption is direct
discriminant dispatch only.

-   **Scalar-only payload gate.** SF-6's "trivially copyable + trivially
    destructible" restriction is implemented as an over-restrictive structural
    allowlist: integer/float/bool/pointer types and adapters over them
    (`IsInSlicePayloadType`, handle_choice.cpp). Trivially-copyable aggregates
    (struct/tuple payload params) are also rejected, with the same SF-6
    contract diagnostic. Rationale: the allowlist is a type property that fails
    safe (match-gate soundness, plan risk R-4) and avoids relying on
    aggregate-copy machinery S1 does not exercise. Relaxation rides SF-6's
    recorded post-0.1 work item. **Admitted exception**: the gate does not
    query Destroy/Copy witnesses, so a user adapter over a scalar carrying its
    own `Core.Destroy` impl passes it despite not being trivially destructible.
    Harmless today only because destroy-op synthesis is a placeholder no-op
    (custom_witness.cpp `MakeDestroyOpBody`); when destroy synthesis lands, the
    gate must become a destroy-witness triviality check. Recorded here, not
    silently accepted, so the user can overrule.
-   **Alternatives with parameter lists in generic choices** (including
    zero-payload `Alt()`) are gated to the generic/Self-dependent TODO string —
    SF-3's function-like `Alt()` lands for non-generic choices only; generic
    synthesis is S3's re-plan.
-   **Choices with fewer than two alternatives are not matchable in S1**: their
    discriminant is the empty tuple, so they stay behind the widened scrutinee
    TODO (`match on unsupported scrutinee type`). There is nothing to dispatch
    on; S2's exhaustiveness work is the natural place to admit them.
-   **Specifics of generic choices are not matchable in S1** (`choice P(T:
    type) { A, B }` matched as a `P(i32)` value): they also stay behind
    `match on unsupported scrutinee type`. Plan §2.2c scopes alternative
    name→index metadata to concrete choices, and admitting the
    specific-resolved constant path untested would trade a diagnostic for a
    potential compiler crash; S3's generic re-plan owns it.
-   **Matching a zero-payload function-like alternative (`case .On` for
    `On()`) is gated by the `match case pattern destructuring a choice
    payload` TODO string**, although there is no payload to destructure: the
    designator resolves to the alternative's constructor function, and S1
    keeps every function-typed alternative pattern behind S2's
    destructuring work. SF-3's ratification text covers construction only;
    the string choice is recorded here so R10 SKIP quoting stays consistent.
    In S1 such alternatives are observable through `default`-arm inversion.
    _S2c landing note (2026-07-28):_ superseded — `.On()` now matches per
    SF-3; bare `.On` diagnoses MissingParens (see the S2c note).
-   **Guarded designator patterns** (`case .Err if (...)`) keep W4's generic
    pattern/guard TODO string, not the payload-destructuring string.
    _S2a landing note (2026-07-28):_ the match re-platform's RF-3 co-change
    (fork/match-replatform/plan.md §6) supersedes this: guard nodes are now
    reached by checking, and every guard — on any pattern — is diagnosed at
    the guard's `if` token with the single string
    `` `match case guard` ``. Patterns whose own gate fires first (for
    example a binding in `case a: i32 if (...)`) still emit their pattern
    TODO at the `case` token before the guard nodes are reached. A further
    recorded deviation class from the same landing: pattern-expression
    diagnostics now surface before or instead of the slice-gate TODOs for
    non-golden-pinned inputs (inherent to plan §2.1's re-route of pattern
    nodes through their ordinary handlers) — for example `case undeclared` adds a
    real name-not-found before the TODO; `case .Err == .Stop` and the like
    produce expression errors instead of the payload TODO; `case (.Err)`
    loses the TODO entirely (the tuple wrapper masks the introducer peek;
    the error-typed pattern continues with real `.Self`-scope errors).
    Disposition: recorded as more-honest diagnostics rather than gated —
    adding lookahead to preserve blanket TODOs on unpinned inputs would
    reintroduce the sniffing this slice removes (R17). No golden or SKIP
    evidence pins any affected input (verified by reviewer #1). Veto-able.
    Relatedly, the binding-root gate lives in the binding handlers rather
    than in `MatchCase` classification as the plan sketched, because
    binding nodes check before `MatchCase` — same string and location,
    forced by traversal order.
-   **The `default` arm stays required** for choice matches in S1 (SF-7's
    exhaustiveness lands in S2), so every S1 conformance/testdata match carries
    `default`.
-   **Reconstruction-landing addendum (2026-07-27):** the first full CI run
    of S1 exposed and fixed six defects across five fix rounds:
    generated-constructor FunctionDecl loc; match discriminant lookup (plan
    §2.2c's "constant imports with the binding" premise was wrong, see the
    amendment there); TypeIterator missing CustomLayoutType;
    alternative-param names leaking into the choice scope
    (NameDeclDuplicate across alternatives); constructor ClassInit elements
    built with InitializeExisting against its documented contract (by-copy
    discriminant crashed lowering AND the Small payload store was silently
    dropped — now InPlaceInitializing per upstream's aggregate discipline);
    and review-found F1, a zero-param `Alt()` in a payload-carrying choice
    producing a 1-element ClassInit against a 2-field repr (now filled with
    an uninit payload element mirroring convert.cpp's ChoicePayload case,
    covered by the new mixed_payload_alternatives testdata). Adversarial review passed both semantic fixes with no
    landing blockers and these recorded follow-ups: (1) DONE
    (claude/carbon-fork-0-1-followups): the defense-in-depth fallback at the
    choice-case pattern now emits `match case pattern on unsupported choice
    alternative shape` instead of the scrutinee string, which stays on the
    scrutinee gate only; (2) when §2.2c name-to-index metadata lands for S2
    exhaustiveness, replace `GetAlternativeDiscriminant`'s constant
    excavation with it; (3) optional comment that CustomLayoutType's
    type-structure fingerprint conflates with a same-shaped StructType
    (filter/ordering-only today); (4) DONE (claude/carbon-fork-0-1-followups):
    match/choice_scrutinee_reexported.carbon pins the
    GetCanonicalFileAndInstId multi-hop path through an `export import`
    relay library; (5) DONE (claude/carbon-fork-0-1-followups): duplicate
    alternative NAMES (`choice C { A, A }`, distinct from the fixed param
    collision) no longer CHECK-crash in NameScope::AddRequired —
    handle_choice.cpp diagnoses NameDeclDuplicate/NameDeclPrevious before
    registration and drops the duplicate (references resolve to the first
    alternative), with choice/fail_duplicate_alternative.carbon covering
    constant/constant, constant/function, and function/constant orders. Also
    landed on that branch: the review F-A1 OneShot single-payload-alternative
    testdata (check+lower) pinning the zero-bit-()-discriminant +
    payload-region constructor shape.

### W5 SF-1..8: choice-payload plan sub-forks (user by way of AskUserQuestion, 2026-07-20)

Hybrid struct representation — discriminant + CustomLayoutType payload
region; payload-free choices untouched (SF-1); bit-minimal discriminant
kept, export may revisit behind a repr version (SF-2); zero-payload
`Alt()` function-like alternatives in slice 1 (SF-3); leading-dot
patterns only, qualified form a recorded work item (SF-4); bare
`name: type` bindings per the design doc (SF-5); trivially-copyable +
trivially-destructible payloads only in 0.1, clean diagnostic, deviation
from the unions.md contract text recorded as post-0.1 work (SF-6);
exhaustive choice matches need no `default` — the closed-set case lands
in slice 2, W4's rule stays for integer matches (SF-7); std::variant
mapping DEFERRED to S4 planning WITH the user's steer: tagged unions are
the first-class construct (`choice`), any Core.Variant prelude name would
be sugar over a generic choice at most, and the default lean is the
anonymous/synthesized-choice mapping — introducing a Variant vocabulary
type requires affirmative justification at the S4 fork (SF-8).

### DIFF-1..4: differential-harness sub-decisions (user by way of AskUserQuestion, 2026-07-19)

Differential programs use the C++ oracle only, no EXPECT-STDOUT (1);
C++-side failures report as DIFF-MISMATCH with detail, no separate status
(2); commit 837bb60's conflation fixed by an empty record commit, no
history rewrite (3); the conformance README program table is
auto-generated by `runner.py --update-readme-table` with a `--self-test`
staleness gate (4).

### F-006: Error handling — **Result + postfix `?` by way of Core.Try** (2026-07-19)

**Sub-decision F-006a (user, 2026-07-19): variant naming is `Ok`/`Err`**,
overriding the design README's older Success/Failure spelling; docs and
prelude code use `Core.Result(T, E)` with alternatives `Ok(T)` / `Err(E)`.

**Sub-decisions F-006b..l (user by way of AskUserQuestion, 2026-07-19), all per
doc recommendation:** `?` in the suffix-operator precedence group,
repeatable (b); ImplicitAs-only error conversion, no dedicated trait (c);
`?` requires a declared Core.Try-implementing return type — no
auto-return, file scope, or global initializers (d); `--cpp-exceptions`
defaults to `auto` (e); fenced std::terminate at unfenced boundaries (f);
Cpp.Exception stores exception_ptr only with lazy str accessors and
lossless rethrow (g); export ships the Carbon::expected<T,E> header only,
no generated throwing wrappers (h); Optional implements Try but no
implicit Optional/Result bridge (i); entry points: (), i32,
Result((),E), Result(i32,E) with Err → stderr + exit 1 (j); try-blocks
and catch-expressions deferred past 0.1 (k); Carbon aborts terminate
without unwinding C++ frames (l).

Staged B0-B3 per fork/design-sprint/error-handling.md: B0 `--cpp-exceptions`
flag + fenced terminate-at-boundary thunks (zero deps, replaces today's UB);
B1 Core.Result + match (after W4/W5); B2 postfix `?` through an open
Core.Try interface with ImplicitAs error conversion; B3 catching thunks
importing throwing C++ as Result(T, Cpp.Exception) + Carbon::expected
export. Rejected: library-only (fails the milestone bullet), declared
fallibility (2-3x cost, collides with if-let), native exceptions
(contradicts p000301, XL lowering).

### F-007: Unions - **Native `union` declaration** (2026-07-19)

Rust-shaped safety surface (writes safe, reads defined byte-reinterpretation,
trivially-copyable fields in 0.1), C++-compatible layout on the existing
CustomLayoutType machinery, both interop directions. Settles the
overlapping-storage primitive choice payloads (W5) lower onto. Rejected:
Core.Storage primitive only, import-only. Per fork/design-sprint/unions.md.

**Sub-decisions F-007a..k (user by way of AskUserQuestion, 2026-07-19):**
standalone `union` introducer keyword (a); Rust safety model — writes
safe, reads Strict-unsafe, Permissive behavior in 0.1 (b) — WITH the
user's standing guidance that `choice` is Carbon's safe tagged union
(Rust-enum model) and the docs must steer users to `choice` unless C++
union interop is needed; read semantics are defined byte reinterpretation,
never UB — chosen by the user's lowest-friction rule since the existing
imported-union lowering already behaves this way mechanically (c);
designated single-field or unformed-then-assign init only (d);
trivially-copyable + trivially-destructible fields in 0.1 (e);
anonymous unions import-only in 0.1 (f); debug-build discriminator
tracking committed as named future work (g); `union` reserved keyword
with r#union migration (h); at least one field required (i); fully
guaranteed layout — offset 0, max size/align (j); choice-payload storage
contract stated normatively as the W5 implementation contract (k).

### F-008: Threading/atomics interop — **Fix the three defects** (2026-07-19)

Memory-model design doc + conformance programs + upstreamable fixes for:
std::thread(carbon_fn) check failure, template-specialization-typed global
link failure, std::atomic<CarbonClass> triviality assert (the last doubles
as the first Carbon-type-into-Clang slice F-010/W8 need). Rejected:
doc-only, Core.Sync veneer, native atomics. Per
fork/design-sprint/threading-atomics.md.

### F-009: Function overloading — **Marked `overload fn`** (2026-07-19)

Closed same-library sets (p000998), declaration-order first-match
(p002875), explicit marker on every member (preserves p003763 typo
diagnostics), no value patterns in 0.1. Exported sets resolve under C++
rules: documented divergence with bidirectional conformance tests.
Rejected: unmarked sets, pattern-dispatch, no-overloading. Per
fork/design-sprint/function-overloading.md.

### F-010: Template structural conformance — **`template constraint` + `require`** (2026-07-19)

Implement accepted p000818/p002200 plus require validity blocks and
boolean predicates by way of probe-mode evaluation; two-way C++20 concept
mapping; adopts F-009's declaration-order/no-subsumption rule for
constrained candidates. Rejected: Go-style implicit satisfaction,
predicates-only. Per fork/design-sprint/structural-conformance.md.

### F-011: Combined match control flow — **`if (let ...)` + `let ... else`** (2026-07-19)

Positive form `if (let P = e)` (and while-let), negative form
`let P = e else { diverge }` filling p002188's reserved slot; enclosing-
scope bindings; syntactic divergence list in 0.1 (return/break/continue),
type-based noreturn rule deferred to safe-Carbon work. A future `?`
desugars onto this core per F-006. Rejected: is-expression flow scoping,
guard-let, match-only. Per fork/design-sprint/if-let.md.

### W4-S1: conformance scope trades for match slice 1 (2026-07-19)

Process/scope decision made by Claude during the trial run under standing
rule 6 (not a language-design divergence — the language semantics follow
`docs/design/pattern_matching.md` unchanged); recorded per process step 4
so the user can overrule. Slice 1 implements the `match` _statement_ with
an integer scrutinee, integer-literal `case` patterns, and a `default`
arm; everything else keeps a clean `semantics TODO` diagnostic. Trades:

-   **`control_flow/match_switch.carbon` narrowed to slice-1 arms** (literal
    cases + `default`, the honest C `switch` equivalent) and un-SKIPped so the
    bullet is scoreboard-arbitrated. The guarded-binding arm it previously
    carried moved to the new SKIP program
    `control_flow/match_guard_binding.carbon`, whose SKIP cites the exact
    `MatchCaseIntroducer` gate diagnostic (R10). Alternative rejected:
    keeping the guard arm would have left the bullet permanently SKIP during
    slice 1 with no executable arbiter for the switch-equivalent subset.
-   **`project/most_features_missing_match.carbon` kept SKIP** as the
    guarded-binding representative of that PARTIAL bullet, with its SKIP
    evidence refreshed to the post-slice-1 gate diagnostic, instead of the
    plan §7 alternative (rewrite to slice-1 arms + un-SKIP). Rationale:
    un-SKIPping it on slice-1 arms would double-count coverage
    match_switch.carbon already provides and overstate "most 0.1 features".
-   **Usefulness/redundancy diagnostics deferred**: duplicate or
    never-matching `case` literals (for example two `case 5` arms) are accepted in
    slice 1; runtime first-match-wins SemIR is design-correct, but
    `pattern_matching.md` ("We will diagnose... A pattern is not useful in
    the context of prior patterns") requires a diagnostic. Recorded as
    work item W-066, blocked on W-008 landing.
-   **Scrutinee gate**: only `Core.IntLiteral`, builtin integer types, and
    the `Int(N)`/`UInt(N)` adapters are in-slice. Other class types whose
    object representation is an integer (`Core.Char`, user adapter classes)
    are explicitly gated out to the scrutinee TODO — they have their own
    operator semantics and would break the slice's cleanup-soundness
    argument (adversarial finding F2).

_RF-4 landing note (2026-07-28):_ the match re-platform's RF-4 slice
(fork/match-replatform/plan.md) widens this section's "integer-literal
`case` patterns" to constant integer expression patterns. At the
integer-scrutinee expression-pattern gate in
toolchain/check/pattern_match.cpp ONLY, the TODO string
`` `match `case` pattern other than an integer literal, or a case guard` ``
becomes `` `match case expression pattern that is not a constant integer` ``;
the old string survives verbatim at its other six sites
(handle_match.cpp, handle_binding_pattern.cpp twice,
handle_let_and_var.cpp, pattern_match.cpp's choice-pattern fallback, and
handle_name.cpp's leading-dot designator gate — the last was missed in
this note's original count because the string literal is split across
two source lines there; corrected at S2b).
_RF-4 addendum (2026-07-28):_ the RF-4 autoupdate run exposed a
formatter CHECK-crash on initializing-category case expressions
(`case 2 + 3` — the prelude operator call returns through a return
slot, and a spliced region result must never be initializing-category).
Fixed in commit d9be8f4 by converting such expressions to values inside
the pattern's expression region before it closes, the same invariant
type expressions uphold by way of `ExprAsType`. This invariant is
load-bearing for all later slices. Veto-able.
Testdata: fail_todo_non_int_literal_case.carbon flips to the now-passing
negative_literal_case.carbon, and two files land alongside it —
constant_expr_case.carbon (admitted constant arithmetic) and
fail_todo_non_constant_case.carbon (runtime `var` reads and plain `let`
bindings stay behind the TODO). Recorded admission-semantics caveat from
review: admission is by constant representation (a concrete SemIR
`IntValue`), so a constant of an int-adapter class type is admitted and
produces a real missing-impl `==` operator error downstream rather than
the TODO — reviewed, no crash, deemed acceptable for RF-4 scope.
Implication for W-066 (usefulness diagnostics): constant-expression
admission creates invisible overlaps (`case 5` vs `case 2 + 3` on the
same scrutinee), so duplicate/overlap detection must compare evaluated
constant values, not source forms — noted on the work item. Veto-able.

_S2b landing note (2026-07-28):_ the match re-platform's S2b slice
(fork/match-replatform/plan.md §3.2) discharges this section's binding
gate for bare `name: type` case bindings: they check to a
`ValueBindingPattern` under `Kind::MatchCaseArm` and bind the scrutinee's
value in the arm's scope. The test pass contributes no condition
(bindings are irrefutable), so the arm's condition is a constant `true`
emitted by handle_match.cpp — keeping the first-match-wins CFG uniform —
and the bind pass runs `LocalPatternMatch` in the arm's body block, so
the binding is initialized only where the arm has matched. The TODO
string `` `match `case` pattern other than an integer literal, or a case
guard` `` is therefore no longer emitted at the plain-binding case gate
in toolchain/check/handle_binding_pattern.cpp, but survives byte-identical
at its remaining sites (handle_match.cpp's non-binding-root fallback, the
compile-time-binding and form-binding case gates in
handle_binding_pattern.cpp, handle_let_and_var.cpp's binding-free `var`
case pattern, pattern_match.cpp's choice-pattern fallback, and
handle_name.cpp's leading-dot designator gate — six in all; the
tuple-case and compile-time-binding sites are golden-pinned by
fail_todo_tuple_pattern.carbon). Per
§3.2(c), `var`-mode and `ref` case bindings stay gated behind a NEW
precise TODO string `` `var` or `ref` binding in match `case` pattern ``,
pinned to the binding itself (fail_todo_var_binding.carbon,
fail_todo_ref_binding.carbon). Other testdata: the now-compiling
fail_todo_binding_pattern.carbon flips to binding_pattern.carbon (multiple
arms, mixed literal+binding arms, `unused` modifier);
binding_choice_scrutinee.carbon binds a choice-typed scrutinee and
rematches it in a nested match (risks R-2/R-8);
fail_binding_scope.carbon pins sibling-arm and post-match leakage as
`NameNotFound` (§3.2(b)); fail_unused_case_binding.carbon pins
`UnusedButUsed` under the arm's implicit `let` introducer (§3.2(a));
fail_arm_conversion.carbon gains a bind-pass conversion-failure pin
(R-1); and the fail_todo_match subfile of
toolchain/check/testdata/patterns/unused.carbon — whose first case is a
`var`-mode binding — moves from the combined string at its `case` token
to the new `var`/`ref` string at the binding, the same §3.2(c) sanction. `default` stays required — an irrefutable binding arm does not yet
discharge exhaustiveness (S2e). SKIP evidence refreshed for
control_flow/match_guard_binding.carbon and
project/most_features_missing_match.carbon: their guarded-binding arms
are now rejected at the guard's `if` token ("match case guard") instead
of the `case` token, and both un-SKIP only at S2d. Veto-able.

_S2b R-7 re-derivation (2026-07-28, post-review):_ the bind pass's
no-cleanups argument does not close from the scrutinee gate alone. The
gate guarantees the _scrutinee's_ type is trivially destructible (integer
types; an in-slice choice's payloads are restricted to trivially copyable
and destructible types when its representation completes), but the bind
pass's `Convert` targets the _binding's declared type_, which is not
gated: `case n: i64` on an `i32` scrutinee runs `Core.ImplicitAs` and
materializes a `Temporary` (convert.cpp `FinalizeTemporary` →
`AddInstWithCleanup`), registering a cleanup in the arm's Owned scope —
and destroy synthesis is live on this branch (`Destroy.Op` calls are
emitted at discharge; see toolchain/check/testdata/let/lifetime.carbon),
so discharge placement is real output. Fix applied per the `let`/`for`
precedent (handle_let_and_var.cpp, handle_loop_statement.cpp): the bind
pass now calls `scope_stack().DeferCleanups()` (handle_match.cpp), so
such a temporary is discharged by `MatchHandler`'s end-of-scope cleanups
at arm exit, not by the first arm-body statement's temporary-cleanup
discharge while the binding is live. Output-neutral for in-slice
testdata: `DeferCleanups` only raises the scope's ambient cleanup-depth
marker (scope_stack.h) and emits no insts, and a same-type bind
conversion registers no cleanup (value→value is a no-op; ref→value binds
a value without a `Temporary`), so no existing golden changes. Bounded
today by DeferCleanups plus the scrutinee gate — the binding-type hole
now yields correctly-placed end-of-arm destroys, not unsound ones. Must
be re-derived at S2c (payload destructuring adds non-integer
subscrutinees and per-element conversions). Two further recorded
nuances: the bind pass re-reads the scrutinee at _arm entry_ in the
arm's body block, not at match entry, so a reference-category scrutinee
is observed after earlier arms' tests ran — benign while tests are
effect-free, re-derive at S2d when guards can run arbitrary code between
tests; and fork/conformance/out/scoreboard.json is not hand-edited here —
its regeneration rides the landing autoupdate/merge gate (R9). Also
landed post-review:
toolchain/check/testdata/match/fail_todo_tuple_pattern.carbon re-pins
the surviving combined W4 TODO
string (a tuple-pattern root at handle_match.cpp's non-binding-root
fallback, and `case template n: i32` at handle_binding_pattern.cpp's
compile-time case gate), which had zero testdata pins after S2b's flips.
Veto-able.

_S2c landing note (2026-07-28):_ the match re-platform's S2c slice
(fork/match-replatform/plan.md §3.3) discharges W5-S2's payload
destructuring: `case .Ok(value: i32)` tests the scrutinee's discriminant
and, in the bind pass, extracts the alternative's payload tuple from the
payload region (`ClassElementAccess` field 1, then the alternative's tuple
field — the F-007k offset-0 overlap) and initializes each payload binding
through `LocalPatternMatch` on a `TuplePattern` root, in the arm's scope.
Parse gains the RF-5 dedicated form: `AlternativePatternStart` +
`AlternativePattern` node kinds, entered from `MatchCaseIntroducer` only
when the case pattern starts with `.` followed by an identifier
(leading-dot-only per SF-4); the `Period` token gains a virtual-node
allowance because the wrapper node shares the period with its bracketing
start node. **Name-to-index metadata (the W5-S1 review follow-up (2), now
DONE):** a `SemIR::ChoiceAlternative` side table
(`{name_id, index, payload_field_index, has_parameters}`) on
`SemIR::Class`, populated in declaration order when the choice definition
completes and imported with the class definition (names translated by
`GetLocalNameId`). It replaces `GetAlternativeDiscriminant`'s constant
excavation, which is DELETED from pattern_match.cpp together with its
cross-file `GetCanonicalFileAndInstId` walk — imported and reexported
choices resolve through the ordinary class import
(choice_scrutinee_imported/choice_scrutinee_reexported still pin those
paths, plus the new choice_payload_imported.carbon for payload metadata).
Sanctioned diagnostic changes, verbatim: the TODO string
`` `match case pattern destructuring a choice payload` `` is DISCHARGED —
both emission sites (bare `.Ok` and wrapped-designator, pattern_match.cpp)
are deleted. In its place: in-slice payload patterns compile; the
parens-iff-parameter-list rule (p2188:453-456) is enforced by two new
diagnostics, `` alternative `{0}` is declared with a parameter list, so its
pattern requires parentheses `` (MatchAlternativeMissingParens, bare `.Ok`
— this also supersedes the W5-S1 recorded gate that kept `case .On` for a
zero-payload `On()` behind the payload TODO: `.On()` now matches per SF-3
and bare `.On` gets this error) and `` alternative `{0}` is declared
without a parameter list, so its pattern cannot have parentheses ``
(MatchAlternativeUnexpectedParens, `case .Err()`); wrong arity gets
`` alternative pattern has {0} subpattern{0:s}, but alternative `{1}` is
declared with {2} parameter{2:s} `` (MatchAlternativeArgCountMismatch); a
non-binding payload subpattern (`case .Ok(42)`) gets a NEW precise TODO
`` `non-binding subpattern in match `case` alternative pattern` ``, pinned
to the subpattern. Span choice: all three new match-alternative
diagnostics anchor on the whole alternative pattern node — uniformity
over sharpness — with sharper sub-spans deferred to W-066's
diagnostics-quality work. The combined W4 string survives byte-identical at six
sites, but one site MOVES: handle_name.cpp's leading-dot designator gate
(the split-literal site) is deleted with the whole S2c-scheduled
DesignatorExpr node-stack hack (plan §1.2 F-Q1 residue), and the same
string with the same introducer-node pin is re-emitted from the
`AlternativePattern` check handler in handle_match.cpp (non-choice
scrutinee gate). `qualified alternative pattern in match case` and
`match case pattern on unsupported choice alternative shape` survive
verbatim (the latter now keyed on missing metadata rather than failed
excavation). _R-7 re-derivation for S2c:_ payload extraction itself
registers no cleanups — the `ClassElementAccess` chain is reference
projection into the scrutinee, and in-slice payload element types are
trivially copyable and destructible by the choice-completion gate — but
the bind pass's per-element `Convert` to each binding's DECLARED type is
ungated (the same S2b hole: `case .Set(n: i64)` on an `i32` payload runs
`Core.ImplicitAs` and can materialize a `Temporary` with a registered
cleanup, and destroy synthesis is live), so alternative-payload arms get
the identical `DeferCleanups` treatment as S2b binding arms: such
temporaries discharge at arm exit by `MatchHandler`'s scope cleanups, not
at the next statement while the binding is live. Re-derive at S2d, where
guards run arbitrary code between test and bind. Recorded deviations
(veto-able): (1) the alternative-pattern parse form is gated to the match
case ROOT position only, not all pattern positions as W5 plan §3.2.1
sketched — leading-dot in any other pattern position (function params,
`let`, nested in payload lists, `case (.Err)`) parses exactly as before;
alternative patterns are meaningless without a scrutinee-typed scope, and
F-011's if-let can widen the gate later. (2) Consequently unpinned inputs
of the S2a "more-honest diagnostics" class shift again: `case .Err ==
.Stop` now parses `.Err` as an alternative pattern and the trailing
operator is a parse error (expected `=>`), and `case .Self` takes the
ordinary expression route (`.Self` not in scope) since the lookahead gate
requires an identifier after the period; no golden or SKIP evidence pins
either. (3) A single parenthesized subpattern (`ParenPattern`) is wrapped
in a synthesized `TuplePattern` so payloads uniformly destructure through
upstream's tuple machinery. (4) Unknown alternative names get the standard
member-access diagnostic in both forms (`PerformMemberAccess` against the
choice scope; in the paren form its name-ref lands in a consumed,
unreferenced expr region). (5) `default` stays required — payload arms do
not discharge exhaustiveness (S2e). (6) The paren-form discriminant test
is emitted by a free function (`MatchCaseAlternativePatternMatch`)
sharing `EmitChoiceDiscriminantTest` rather than entering the
`MatchContext` engine worklist as plan §2.1/RF-1 sketched — functionally
equivalent, same file (pattern_match.cpp); fold into the engine at S2d
when guards force it. Testdata:
fail_todo_choice_payload_pattern.carbon is renamed (git mv) to
fail_choice_alternative_pattern.carbon, its `.Ok(42)`/`.Ok` subfiles
re-pinned to the new TODO/diagnostics, qualified subfile unchanged, plus
new arity/parens/unknown-name/nested-designator fail subfiles; new
positive goldens choice_payload_pattern.carbon,
choice_payload_multi.carbon (multi-element, `.On()`, converting binding),
choice_payload_imported.carbon, lower/testdata/match/choice_payload.carbon
(the R-9 payload-GEP pin), and parse alternative_pattern goldens — all new
CHECK content rides the runner autoupdate (R15/R19). Conformance:
choice_payload_roundtrip_diff.carbon un-SKIPs (with a recorded
never-taken `default` arm until S2e); match_sum_type_payload.carbon keeps
only its interop half per the W5 plan §3.3 split, SKIP evidence refreshed
to the S4 blocker. Veto-able.

### F-005: Own-toolchain build environment — **Self-hosted runner** (2026-07-19)

The user registered a self-hosted GitHub Actions runner ("jeromehome",
self-hosted/Linux/X64) on the fork. `.github/workflows/fork_build_toolchain.yaml`
builds `//toolchain/install:carbon_toolchain_tar_gz` from the pushed
branch, runs `bazel test //toolchain/...` as the F-002 merge gate, and
publishes the tarball as a fork release (by way of a hosted publish job). The
sandbox then downloads that release the same way it downloads the mirrored
nightly. First cold build compiles LLVM (hours); the runner's bazel disk
cache makes subsequent fork builds incremental. Security note: on a public
repository, keep the default "require approval for outside collaborators'
workflow runs" protection enabled so third-party PRs can't run code on the
runner host.

### F-001: What "0.1" means for this fork — **Staged official 0.1** (2026-07-19)

Chase the full official checklist from `docs/project/milestones.md`, in
dependency order, tagging intermediate fork milestones (`fork-0.1-alpha`,
`fork-0.1-beta`, …) as scoreboard tiers go green. Design authorship for
the undesigned bullets is in scope. Alternatives rejected: pragmatic
subset-0.1 (diverges from the official definition), upstream-lockstep
(too slow, not autonomous).

### F-002: Upstream relationship — **Bun-style merge gating** (2026-07-19)

User's words: "Follow the same approach used by the Bun zig->rust rewrite
for merging into my fork branch." Interpretation (recorded for review):
in the Bun rewrite, work happened in isolated worktrees/branches and
merged only after **100% of the pre-existing test suite passed in CI**.
Applied here:

-   Feature work happens in child branches/worktrees, never directly on
    `claude/carbon-fork-0-1-7mwfb7`.
-   A merge into the fork branch requires the full pre-existing toolchain
    test suite plus the conformance scoreboard to be green (no skipped or
    deleted tests to force a pass).
-   Upstream trunk merges are treated the same way: merge upstream into a
    staging branch, re-run the suite, land only when green.

### F-003: First scaled track — **Design sprint + match chain in parallel** (2026-07-19)

After the conformance-harness trial (W1): agent fleets draft the missing
designs (error handling, unions, if-let/let-else, function overloading,
threading/atomics interop; then safe Carbon) with the user reviewing at
each design fork, while the implementation loop grinds
match semantics → choice payloads → std::variant/optional interop against
the harness.

### F-004: Arbiter toolchain source — **Upstream nightly prebuilt** (2026-07-19)

User approved adding `carbon-language/carbon-lang` to the session to
download the nightly prebuilt toolchain tarball (Linux x86_64). This
arbitrates _language behavior_ while our fork's tree equals upstream
trunk; it cannot execute fork-local compiler changes — see OPEN F-005.
