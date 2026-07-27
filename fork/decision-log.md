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
-   **Guarded designator patterns** (`case .Err if (...)`) keep W4's generic
    pattern/guard TODO string, not the payload-destructuring string.
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
