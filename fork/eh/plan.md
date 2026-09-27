<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# EH plan: the error-handling remainder (Result, `?` closure, C++ exception interop)

**Status:** APPROVED FOR IMPLEMENTATION, 2026-09-27 (two adversarial
plan reviews, rev 1 and rev 2, returned APPROVE-WITH-AMENDMENTS; every
amendment is folded below, each marked "(amended 2026-09-27, review fold:
...)" — see Sign-off). Branch `claude/carbon-fork-0-1-eh` off trunk
5551790, merged with trunk f0e1980 on 2026-09-27 (the gap-analysis
reconciliation and R29; pre-PR #39: W-077's struct-pattern PR is in its
single implementation review). Conformance in this tree is **101 PASS / 0
FAIL / 28 SKIP over 129** per fork/conformance/out/scoreboard.json totals —
every floor below is stated relative to that, and W-077's merge adds
exactly one PASS program to both sides of every equation. All toolchain
and core line numbers are against trunk 5551790; fork/gap-analysis.md line
numbers are against f0e1980; clang/libc++abi line numbers are against the
LLVM checkout the toolchain builds from (`external/llvm-raw+`).
**EH-A LANDED 2026-09-27** (a27059915 check+prelude, ea1822f66 lower,
1918b307e testdata+conformance, c127784c4 the runner-exposed `Destroy`
bound); discharge notes below are marked "(landed 2026-09-27, EH-A:
...)" and leave every EH-B item untouched.

**Items:** W-017 (EH-B1 prelude `Core.Result`), W-018 (EH-B2 `?` +
`Core.Try`), W-019 (EH-B3 catching thunks + `Carbon::expected`), the SF-1
follow-up carried on W-016, and the two OPEN sub-forks the remainder hangs
on (SF-9, W-070). **Design authority, not reopened:** fork/decision-log.md
F-006 (:491-523) with sub-decisions F-006a..l, the B0 SF-1..5 trades
(:51-59), the design text docs/design/error_handling.md (the ratified
normative doc; the option paper fork/design-sprint/error-handling.md is its
research record).

**Milestone bullets this plan flips** (fork/gap-analysis.md:66-67 at
f0e1980 — both PARTIAL with accurate evidence text since trunk's 2026-09-27
reconciliation; this plan flips row 66 to DONE and rewrites row 67's
evidence, see §8.6; amended 2026-09-27, review fold: rev 2 F4):
"Error handling: dedicated control flow constructs" and "Error handling:
C++ exception interop (-fno-except config, calling throwing C++, exporting
Carbon errors as std::expected/exceptions)".

## §0 Audit: what already landed (the ledger is stale in seven places)

### §0.1 Sub-feature table (verified in-tree at 5551790)

| # | F-006 sub-feature | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `--cpp-exceptions={auto,none,catch}`, default `auto` (F-006e) | LANDED (B0) | toolchain/driver/compile_options.cpp:154-176 (flag), :531-544 (mode flags appended after user `--clang-arg`s), compile_options.h:49-53, :105 |
| 2 | Fenced terminate at unfenced boundaries (F-006f) | LANDED (B0), diagnostic-less | toolchain/check/cpp/thunk.cpp:287-306 `IsCppThunkFenceRequired`; :323-328 every potentially-throwing callee takes a thunk; :529-533 `EST_BasicNoexcept` fence; import.cpp:2067-2106 fail-closed TODO; lower golden interop/cpp/exceptions/fenced_thunk.carbon:47-56 (`invoke` + `terminate.lpad`) |
| 3 | SF-1 boundary-identifying diagnostic | MISSING | the fence is the exception-spec only (thunk.cpp:529-533); no `try`/`catch`, no message; recorded deferral fork/decision-log.md:53-55, W-016 notes, W-019 notes |
| 4 | Postfix `?` parse: suffix group, repeatable (F-006b) | LANDED (B1a) | lex token_kind.def:108 `Question`; parse node_kind.def:369 `PostfixOperatorQuestion`; parse/handle_expr.cpp:293-302 in the postfix loop; parse golden operators/question.carbon:73-81 (chained `?`) |
| 5 | `Core.Try` + `Core.ControlFlow` carrier | LANDED (B1b) | core/prelude/try.carbon:21-24 (`ControlFlow(C, B)`, Continue=0/Break=1), :37-48 (`Try`); export-imported at core/prelude.carbon:15 |
| 6 | `?` check desugar onto branch/return, ImplicitAs error conversion (F-006c), D4 placement (F-006d) | LANDED (B1b), COMPLETE for any `Try` type | toolchain/check/handle_question.cpp:153-307 pre-flight (seven diagnostics: :159, :185, :197, :224, :242, :295 + context :349), :309-430 desugar (Branch by way of `BuildUnaryOperator` :344, discriminant test :380, `FromBreak` compound access + `PerformCall` argument conversion = the ImplicitAs conversion :406-416, `BuildReturnWithExpr` :418); diagnostics registered toolchain/diagnostics/kind.def:573-581 |
| 7 | `?` on symbolic operands (W-071) | DISCHARGED (B2a) | custom_witness.cpp:151-200 (`CanDestroyClass` choice clause :196); question.carbon `generic` subfile :215-328; fail_question_generic.carbon; lower question_generic*.carbon (5 files) |
| 8 | Generic `?` continue-threading (W-072/W-073) | DISCHARGED | question_final.carbon, question_generic_thread_diff conformance pair; decision-log W72b/W-073 notes |
| 9 | Prelude `Core.Result(T, E)` with `Ok`/`Err` (F-006a) | MISSING | `grep -rln Result core/prelude` hits nine files, all arithmetic `.Result` associated constants or their uses — int.carbon:141-220, float.carbon:196-216, char.carbon:93-128, plus cpp/int.carbon, uint.carbon, iterate.carbon and operators/{arithmetic,bitwise,deref}.carbon — none declares a type named `Result` (amended 2026-09-27, review fold: rev 1 MINOR-6); no `result.carbon`; conformance programs use a user `MyResult` (control_flow_constructs.carbon:29-32) |
| 10 | `Result`'s `Try` impl | MISSING | no impl exists; sketch at docs/design/error_handling.md:383-396 (`final impl forall [T: type, E: type] Result(T, E) as Try`) |
| 11 | `Optional` implements `Try`, `BreakType = ()` (F-006i/D9) | MISSING, doubly gated | core/prelude/types/optional.carbon:27-45 (placeholder class, `HasValue`/`Get`); no `Try` impl; `ControlFlow(T, ())` rejected per specific — toolchain/check/type.cpp:313-320 `IsInSliceChoicePayloadType` admits only int/float/bool/pointer (through adapters), pinned by fail_question_preflight.carbon:107-126 (`fail_unit_break_type`, W-070) |
| 12 | Entry point `Run() -> Core.Result((), E)` / `Result(i32, E)` (F-006j/D10) | MISSING | toolchain/check/handle_function.cpp:373-393 `IsValidEntryPointReturnType` admits `()`/none/i32 only; :417-420 diagnostic text names two shapes; lower/type.cpp:335-341 + handle.cpp:267-275 special-case only the no-return-type entry point |
| 13 | Catching thunks: `Result(S, Cpp.Exception)` imports (B3) | MISSING | thunk.cpp has one thunk shape per callee (`BuildCppThunk` :749, `PerformCppThunkCall` :791); no exception capture anywhere in toolchain/check/cpp/ (`grep -n current_exception\|exception_ptr\|__cxa_` is empty) |
| 14 | `Cpp.Exception` synthesized into the `Cpp` package (F-006g) | MISSING | import.cpp:2453-2500 `LookupBuiltinName` handles `Cpp.long`-style builtins and `Cpp.nullptr` only; no `Exception` case; nothing under core/prelude/types/cpp/ (int, nullptr, void) |
| 15 | `Carbon::expected<T, E>` export + support header (F-006h/D8) | MISSING | type_mapping.cpp:145-250 `TryMapClassType` maps Char/CppCompat/Optional-pointer/Str only; export.cpp:993-1039 maps the return type through it (`failed to map Carbon return type to C++ type` TODO :1013); no header under toolchain/install/ |
| 16 | Conformance for the two bullets | PARTIAL | bullet 1: 4 PASS programs, all over a USER `MyResult` (control_flow_constructs, question_propagation_diff, question_generic_diff, question_generic_thread_diff); bullet 2: 4 PASS B0 programs + 1 SKIP (cpp_exception_interop.carbon:10 SKIP, body commented :21-40) — no program names `Core.Result`, `Cpp.Exception`, `Carbon::expected`, or a `Result`-returning `Run` |
| 17 | Design docs | DONE (text) | docs/design/error_handling.md (950 lines, normative, staging table :800-812); docs/design/README.md:3885-3918 already replaces the placeholder section; docs/design/expressions/README.md:358, :382-385 carry `?`. The sentence "Carbon does not have language features dedicated to error handling" survived only in fork/gap-analysis.md's pre-reconciliation row evidence and left the tree at trunk f0e1980; `grep -rn` over docs/ and fork/ is empty (amended 2026-09-27, review fold: rev 2 F4) |

### §0.2 Ledger claims found stale (each corrected at §8.5 discharge)

1.  **W-017 title/kind ("design-needed", "Core.Result choice in the
    prelude + match-based consumption + conformance programs",
    blocked_by W-008/W-010):** the design is ratified (docs/design/
    error_handling.md:94-124) and both blockers are landed (W-008 W8c
    COMPLETE 2026-09-25; W-010's payload construction/destructuring landed
    S1-S3c). What is actually missing is the prelude file (§0.1 row 9), and
    the real gate was SF-9 (OPEN, decision-log:15-26), which the ledger
    does not record as a blocker at all.
2.  **W-018 ("design-needed", "postfix `?` operator + Core.Try interface +
    ImplicitAs error conversion", blocked_by W-017):** everything in the
    title landed at B1b/B2a (§0.1 rows 4-8) — over user choices. The
    blocked_by edge is inverted: `?` does not wait on `Core.Result`; the
    prelude `Try` IMPLS (rows 10-11) do. W-018's note "Bare Question token
    already lexed and unused (token_kind.def:103)" is also stale — the token
    is at :108 and is consumed by the parser.
3.  **W-019 blocked_by W-007 ("five-way contention refactor plan before
    any two of these start"):** W-007 is unblocked, S-sized, and still
    unwritten; none of the other four contenders (W-015 unions, W-026,
    W-021/W-023 threading — the last two DISCHARGED at F8b/F8d) is in
    flight. The precondition of W-007 ("before any two start concurrently")
    is not met, so it does not gate this PR; §1.B.9 states the additive
    landing shape that makes the refactor unnecessary now.
4.  **W-016 notes ("fenced (try/catch-terminate) thunks")** — the fence is
    the `noexcept` exception spec, not a `try`/`catch` (thunk.cpp:529-533;
    the notes' own DEVIATION line says so two sentences later). The title
    should not say try/catch.
5.  **W-070 blocked_by "SF-9":** the unit-break bound is an SF-6 allowlist
    question (type.cpp:313-320); SF-9 (Optional's identity) does not
    decide it. This plan decides it (§0.3 D-EH-2).
6.  **fork/gap-analysis.md:66-67 — status flip only** (rewritten; amended
    2026-09-27, review fold: rev 2 F4). Trunk's reconciliation at f0e1980
    already corrected both EH rows to PARTIAL with accurate evidence text
    and recomputed the header counts (:17, 26 DONE / 20 PARTIAL / 8 MISSING
    / 2 DESIGN-ONLY). What remains for this plan is the status flip of row
    66 (PARTIAL → DONE at EH-A, counts 27/19/8/2) and the evidence rewrite
    of row 67 (stays PARTIAL at EH-B; §8.6). The scoreboard's `gap_status`
    column mirrors that table.
7.  **decision-log OPEN fork SF-9 (:15-26)** was to "ride the W5-S3p
    AskUserQuestion round" whose ask package (fork/b2/plan.md §3 B2b,
    :397-420: `fork/design-sprint/s3p-ask.md`) was never written — no such
    file exists, `git log --all | grep -i s3p` is empty. Under R29(a) there
    are no more question rounds; §0.3 auto-adopts the recommendation.

### §0.3 Decisions this plan auto-adopts (R29(a): design recommendation under V-2/V-3, veto-able after the fact)

None of these reopens an F-006 sub-decision; each closes an item F-006
left OPEN or a bound the landing notes recorded "for S3p".

-   **D-EH-1 — SF-9 resolved: `Core.Result(T, E)` is minted as an
    INDEPENDENT prelude choice (library "prelude/types/result"), and
    `Core.Optional` KEEPS its placeholder class identity — it is NOT
    re-platformed onto `choice` in this workstream; it gains a `Try` impl
    over its existing `HasValue()`/`Get()` API.** Rationale: the three SF-9
    options were re-platform / adapter / independent class (decision-log
    :15-26). Re-platforming `Optional` is a separate stdlib feature (W-058,
    "Stdlib: Optional" bullet) with an ABI contract to preserve — the
    pointer null-niche that C++ nullable pointers map onto
    (optional.carbon:161-179, type_mapping.cpp:209-228, import.cpp:1367-
    1385) and the entry-point `argv: Core.Optional(char*)*` signature
    (handle_function.cpp:412) — and the design's own `Optional` Try sketch
    (error_handling.md:397-409) is satisfiable without it: `Branch` needs
    only "is there a value / get it". "How `Core.Result` relates" is
    answered as the design already says (D9, :893-897): no implicit
    bridge, two independent `Try` implementers. V-3 check: upstream has no
    `Result`; upstream's `Optional` is the same placeholder we keep — no
    contradiction. Break condition: if W-058's approved `Optional` design
    later makes it a choice, the `Try` impl body is rewritten to the doc's
    `match` sketch (error_handling.md:397-409) — the impl SIGNATURE this
    plan lands is the sketch's signature MODULO the `OptionalStorage`
    bound: the sketch (error_handling.md:397-398) writes `forall [T: type]`,
    but `class Optional(T: OptionalStorage)` (optional.carbon:29) forces
    `forall [T: OptionalStorage]`; the facet-typed-`where`-rewrite form
    has the in-tree precedent check/testdata/facet/
    validate_rewrite_constraints.carbon:288 (`final impl forall [T: I] T as
    J where .Y = C {}`). The bound is recorded as a dated doc amendment
    (§8.6), so nothing user-visible changes (amended 2026-09-27, review
    fold: rev 1 MINOR-1). (landed 2026-09-27, EH-A: the bound is `Destroy
    & OptionalStorage`, not `OptionalStorage` alone — the landed signature
    is `final impl forall [T: Destroy & OptionalStorage] Optional(T) as Try
    where .ContinueType = T and .BreakType = ()`, optional.carbon:69-70,
    commit c127784c4. Runner-exposed (§7 R-12 landed note): inside `forall
    [T: OptionalStorage]` a symbolic `T` carries only its declared
    interfaces, and `Branch` moves a `T` payload into `ControlFlow(T,
    ()).Continue(...)`, which needs `T: Destroy`; the file's own
    `ImplicitAs` impls (optional.carbon:110, :117) use the same bound for
    the same reason. result.carbon's `[T: type, E: type]` impl needs no
    such bound. D-EH-1's recorded signature and W-058's §8.5 note read
    "the sketch's modulo the `Destroy & OptionalStorage` bound".)
-   **D-EH-2 — W-070 resolved by option (a): the zero-sized empty tuple
    `()` is admitted as a choice payload element (`IsInSliceChoicePayloadType`
    gains `|| (tuple type with zero elements)`).** This is the minimal
    widening the B1 landing note offered (decision-log:602-606; fork/b1/
    plan.md:562-580); it keeps D9's ratified text (`BreakType = ()`) and
    D10's `Result((), E)` spelling literally true, it is trivially copyable
    and destructible (so the W-071 structural-trust note at
    custom_witness.cpp:184-195 stays valid — W-070's own notes say "W-070's
    `()` stays fine"), and it changes no layout of any existing choice (a
    `((),)` payload tuple has size 0). The alternative — a scalar break
    carrier for `Optional` — would contradict D9's text. Break condition:
    a lowering defect on zero-sized payload stores (§7 R-3) flips the plan
    to the scalar carrier for `Optional` ONLY, with D9 amended by a dated
    note; `Result((), E)` would then still work because its `()` sits in
    the `Ok` payload of a two-payload region (size taken from `E`).
-   **D-EH-3 — the `Cpp.Exception` 0.1 storage is the Itanium primary
    exception object pointer (`__cxa_current_primary_exception()`), held
    in a prelude class `Core.CppCompat.Exception { adapt VoidBase*; }`
    surfaced in the `Cpp` package as `Cpp.Exception` by the same
    file-less builtin path as `Cpp.nullptr`.** This IS "stores the
    exception_ptr": on libc++abi `std::exception_ptr` is exactly that
    pointer with refcounting (`cxa_exception.cpp:673-729`), and `.ptr()` in
    the support header reconstitutes a real `std::exception_ptr` from it
    losslessly. Two honest 0.1 bounds, both forced by SF-6 (a payload type
    must be a scalar after adapters, type.cpp:313-320): (i) `Cpp.Exception`
    is trivially copyable and trivially destructible, so the exception
    object's refcount is incremented once at capture and released only at
    process exit — D7's "Destroying a `Cpp.Exception` releases the
    exception_ptr" (error_handling.md:734) is DEFERRED to the choice-payload
    destroy-synthesis work (custom_witness.cpp:623-626 `MakeDestroyOpBody`
    is still upstream's placeholder, so no payload of any choice is
    destroyed today); (ii) the lazy accessors `TypeName()`/`Message()`
    (:715-720) are deferred (§7 R-8) — they need a synthesized C++ helper
    that can only be built when `std::exception`/`<typeinfo>` are declared
    in the TU. Both recorded as ONE new residue item, "`Cpp.Exception`
    accessors and release-on-destroy" (provisional id W-080; ids are
    allocated at discharge, §8.5; amended 2026-09-27, review fold: rev 1 +
    rev 2 ID collision). Break condition: SF-6 widening past scalars
    (W-010 residue) reopens (i) as a real `Destroy` impl calling
    `__cxa_decrement_exception_refcount`.
-   **D-EH-4 — the catching-import SELECTION surface delivered in 0.1 is
    the `?`-directly-on-the-call form** (error_handling.md:674-678 names
    it as one of the contexts). The other context — a binding or argument
    whose EXPECTED type is `Core.Result(S, Cpp.Exception)` — needs an
    expected-type channel the checker does not have (conversions run after
    the call is emitted; convert.h:14-60 has no "context type" input), so
    it is recorded as the residue item "catching-import selection in
    binding/argument contexts" (provisional id W-081, §8.5; amended
    2026-09-27, review fold: rev 1 + rev 2 ID collision) with the one-line
    workaround `fn Wrap() -> Core.Result(S, Cpp.Exception) { return
    .Ok(Cpp.f(x)?); }`.
    The `?` form alone satisfies milestone bullet 3's "automatically using
    Carbon's error handling" (no per-call bridge code). Break condition:
    an expected-type mechanism landing (F-011's `let ... else` work may
    add one) lifts the residue.
-   **D-EH-5 — the SF-1 boundary-identifying diagnostic is delivered as a
    `try { <call> } catch (...) { write(2, msg); throw; }` wrapper INSIDE
    the still-`noexcept` fenced thunk**, so the rethrow reaches the
    existing terminate landing pad (B0's contract unchanged; libc++abi's
    verbose terminate additionally names the exception type) and the
    message names the C++ callee. `write(2, ...)` is chosen over `printf`
    because `abort()` drops buffered stdout (cpp_exceptions_fence_terminate
    .carbon:17-18) and over a runtime helper because no linkable Carbon
    runtime object exists (R1). It is the LAST commit of EH-B with a drop
    rule (§3.B, §7 R-9).
-   **D-EH-6 — split: two PRs.** See §0.4.

### §0.4 The split decision: two PR-sized workstreams, sequential

The remainder is genuinely two milestone features with one directed
dependency, so per R29(b) it is two PRs:

-   **EH-A (bullet 1, "dedicated control flow constructs"):** prelude
    `Core.Result` + `Try` impl; `Optional`'s `Try` impl + the `()` payload
    admission; entry-point `Result` signatures (check + lower); goldens;
    four conformance programs; docs/ledger/gap-analysis discharge. Size M.
    Touches core/prelude, check/type.cpp, check/handle_function.cpp,
    sem_ir/type_info, lower/{type,file_context,handle}.cpp — NOT the
    check/cpp/ contention files.
-   **EH-B (bullet 2, "C++ exception interop"):** catching thunks selected
    by `?`; `Cpp.Exception`; `Carbon::expected` export mapping + the
    install-tree header + include path; the SF-1 fence diagnostic; goldens;
    un-SKIP + three conformance programs; discharge. Size L. Touches
    check/cpp/{thunk,import,export,type_mapping,context}, base/
    {clang_invocation,install_paths}, install/BUILD, diagnostics/kind.def.
-   **Dependency:** EH-B mints `Core.Result(S, Cpp.Exception)` values and
    maps `Core.Result` specifics to `Carbon::expected`, so it needs EH-A's
    prelude type and `RecognizedTypeInfo::Result`. EH-B's planner-level
    spec is complete here; its implementer starts after EH-A's hosted
    verification is green (R29(d) pipelining: EH-A's review overlaps EH-B's
    implementation start only once EH-A's autoupdate fixpoint is in).
-   Rejected: one PR (an L+M diff spanning prelude, lower, and the C++
    Sema synthesis is beyond one review's attention; the two bullets flip
    independently and the scoreboard records each); three PRs (splitting
    EH-B's fence diagnostic out would leave the SF-1 deferral open a third
    time — instead it is a droppable last commit).
-   **Recorded fallback, not adopted (amended 2026-09-27, review fold:
    rev 2 F11):** EH-B stays ONE PR per R29(b). Its two halves are
    file-disjoint — the catching half (thunk.{h,cpp}, import.cpp,
    check/context.h, handle_question.cpp, exception.carbon, the
    exceptions/ goldens) and the export half (type_mapping.cpp,
    export.cpp, install/, base/{install_paths,clang_invocation}, the
    export/ goldens) share only core_identifier.def, type_info.{h,cpp},
    types.carbon and kind.def, all additive lines — so they MAY be split
    into two M PRs (catching first, export second, the fence diagnostic
    riding with whichever lands last) if implementation-review attention
    overruns. The split is a fallback the implementer invokes with a
    one-line note in the decision-log entry, not a plan change.

## §1 Design decisions

### §1.A EH-A — `Core.Result`, `Optional as Try`, entry point

1.  **`Core.Result` lives in a new prelude library
    `core/prelude/types/result.carbon` (package `Core library
    "prelude/types/result"`), export-imported from
    core/prelude/types.carbon (new line between :18 `optional` and :19
    `string`, alphabetical).** Declaration verbatim from
    docs/design/error_handling.md:100-105 (`choice Result(T: type, E: type)
    { Ok(value: T), Err(error: E) }` — Ok first fixes discriminants Ok=0,
    Err=1, which §2.A.5's entry-point epilogue and EH-B's header rely on).
    Imports: `"prelude/operators/as"` and `"prelude/types/uint"` (the two
    try.carbon:9-10 needs for a choice's discriminant), `"prelude/try"`
    for the impl, AND `import library "prelude/operators/comparison";`
    (amended 2026-09-27, review fold: rev 1 MAJOR-1): the impl's `Branch`
    body is a `match` on `self`, and `match` on a choice emits the
    discriminant test through `Core.EqWith` (`EmitChoiceDiscriminantTest`,
    pattern_match.cpp:537-559, `BuildBinaryOperator` with
    `CoreIdentifier::EqWith`); inside package `Core` the `Core.<name>`
    lookup is file-scoped (`GetCorePackage`/`LookupNameInCore`,
    name_lookup.cpp:621-684, resolve against the current file's package
    scope), `EqWith` is declared in operators/comparison.carbon:18, and
    uint.carbon imports `prelude/operators` (uint.carbon:10) WITHOUT
    re-exporting it — so without the explicit import the prelude itself
    fails to compile. Cycle check: try.carbon's closure is as/uint → copy,
    default, destroy, operators, char_literal, float_literal, int,
    int_literal (verified by the import lines of each);
    operators/comparison.carbon imports only `prelude/types/bool` (export)
    and `prelude/types/int_literal` (comparison.carbon:7-8), both leaves;
    none imports types/result or types/optional. Rejected: putting `Result` in
    try.carbon (mixes the operator protocol with a vocabulary type; the
    doc places `Result` and `Try` in separate sections) or under
    types/optional.carbon.
2.  **The `Result` `Try` impl is the doc sketch, spelling-diffed (R27):**
    `final impl forall [T: type, E: type] Result(T, E) as Try where
    .ContinueType = T and .BreakType = E` with the match-reconstruct
    `Branch` body and the `return self.(Try.Branch)();` trailing return,
    and `fn FromBreak(b: E) -> Self { return Result(T, E).Err(b); }` —
    error_handling.md:383-396 byte-for-byte modulo the `Try`/`ControlFlow`
    qualification being unnecessary inside package `Core`. Under `final`
    the recursive trailing return type-collapses (question_final.carbon's
    `inbody_recursive_branch` split; W-073 site 8 at runtime), so no
    `Diverge` helper is needed. Bound inherited, not widened: `T`/`E` must
    be SF-6-admissible per specific (int/float/bool/pointer, through
    adapters) — `Result(SomeClass, E)` diagnoses
    `ChoicePayloadNotTrivialInSpecific` at the forcing use exactly as
    `MyResult(SomeClass, E)` does today (eval_inst.cpp:243-250). That bound
    belongs to the "Type system: Sum types" bullet (W-010's SF-6 residue),
    not to this one, and is stated in the gap-analysis evidence text.
3.  **`Optional`'s `Try` impl is the doc sketch's SIGNATURE over the
    placeholder API:** `final impl forall [T: OptionalStorage] Optional(T)
    as Try where .ContinueType = T and .BreakType = ()`, `Branch` =
    `if (self.HasValue()) { return ControlFlow(T, ()).Continue(self.Get()); }
    return ControlFlow(T, ()).Break(());`, `FromBreak(b: ()) -> Self
    { return Optional(T).None(); }`. The facet-typed rewrite `.ContinueType
    = T` with `T: OptionalStorage` has the exact precedent
    core/prelude/iterate.carbon:20-22 (`[T: Copy & Destroy] ... where
    .ElementType = T`) and the checker golden
    facet/validate_rewrite_constraints.carbon:288 (`final impl forall [T:
    I] T as J where .Y = C {}`) for the `final` + facet-bound + rewrite
    combination (amended 2026-09-27, review fold: rev 1 MINOR-1). (landed
    2026-09-27, EH-A: two spelling changes — the bound is `[T: Destroy &
    OptionalStorage]` (D-EH-1 landed note; R-12), and `FromBreak` is
    spelled `fn FromBreak(unused b: ()) -> Self` because an unreferenced
    named binding inside the prelude diagnoses `UnusedBinding`; precedent
    core/prelude/iterate.carbon:23, :74 — review fix (4), MINOR.)
    optional.carbon gains `import library
    "prelude/try";` (no cycle, §1.A.1). The body differs from the sketch's
    `match (self) { case .Some ... }` because the class is not a choice
    (D-EH-1) — recorded as a dated doc amendment at §8.6, the body being
    observationally the same split. `Optional(T)?` instantiations are
    bounded by SF-6 like every choice (`Optional(str)?` rejects the
    `ControlFlow(str, ())` specific) — `Optional(i32)`/`Optional(T*)` are
    the 0.1 surface, pinned both ways (§4).
4.  **The `()` payload admission is one predicate edit** (D-EH-2):
    type.cpp:313-320 adds `|| (inst.Is<SemIR::TupleType>() &&
    context.inst_blocks().Get(inst.As<SemIR::TupleType>().type_elements_id)
    .empty())` after the adapter walk. All three SF-6 sites route through
    it — the definition path handle_choice.cpp:758, the per-specific eval
    hook eval_inst.cpp:290 and :322 (the first loop's "non-class kind"
    branch and the post-completion check) — so no second predicate is
    minted. Layout facts (handle_choice.cpp:671-680, eval_inst.cpp:314-
    320): a `((),)` tuple has size 0 / align 1, so a `Break(())` payload
    contributes nothing to the max-of-fields region; `ControlFlow(i32, ())`
    lays out as `<{ <{ i1, [3 x i8] }>, [4 x i8] }>`. Rejected: a dedicated
    `IsUnitType` special case at each SF-6 site (three edits, drift risk).
5.  **Entry point:** `IsValidEntryPointReturnType` (handle_function.cpp:
    373-393) additionally accepts a `Core.Result(T, E)` specific whose
    first argument is EXACTLY `()` or `i32`, for any `E`. Bound pinned
    (amended 2026-09-27, review fold: rev 1 MINOR-2): `IsI32`
    (handle_function.cpp:297-301) is a `TypeId` equality against
    `MakeIntType(..., Signed, 32)` — it does NOT see through adapters, so
    `Run() -> Core.Result(AdapterOverI32, E)` is rejected with the same
    `InvalidMainRunReturnType`, exactly as `Run() -> AdapterOverI32` is
    rejected today; pinned by the `fail_adapter_success_type` subfile
    (§4.A). Chosen over a `GetTransitiveAdaptedType` walk because widening
    would have to widen the plain `-> i32` shape too, which is a separate
    D10 question, and the doc's D10 text (:526-529) names `i32` literally.
    The diagnostic text at :417-419 grows to name the four D10 shapes
    (churn: check/testdata/main_run/fail_mismatch_return.carbon's one
    CHECK line, autoupdated). Lowering
    (§2.A.5) keeps the mangled name `main` (mangler.cpp:194-196 unchanged)
    and gives a `Result`-returning `Run` the C ABI `i32 main()` — no sret
    parameter — by allocating the return slot locally and emitting the D10
    epilogue at `ReturnExpr`: disc==0 → return the `Ok` payload (or 0 for
    `()`), disc==1 → `write(2, msg)` naming `E` (`SemIR::StringifyConstantInst`
    on `E`'s type inst, the file_context.cpp:555-557 precedent — anchor
    corrected, amended 2026-09-27, review fold: rev 1 MINOR-6) and return
    1.  `Cpp.Exception`'s message is NOT printed in 0.1 (D-EH-3(ii)); the
        doc sentence :526-529 ("and, when `E` is `Cpp.Exception`, its message
        when available") gets a dated deferral note (§8.6). Rejected:
        synthesizing a separate `main` wrapper function calling a renamed `Run`
        (touches the mangler and every `main`-pinning lower golden — 41 files
        define `@main`); a check-side desugar (check cannot express "exit the
        process").
6.  **Recognition of `Core.Result` is by the existing name-in-Core-root
    mechanism:** `RecognizedTypeInfo::Kind` gains `Result` (type_info.h:
    351-388), `ForType`'s `StringSwitch` (type_info.cpp:185-194) gains
    `.Case("Result", Result)`, `ExpectsArgs` (:148-150) becomes `kind ==
    Optional || kind == Result`, `PrintLiteral` (:266-290) gains a silent
    `case Result: break;`, and type_mapping.cpp's `TryMapClassType` switch
    (:145-250) gains `case SemIR::RecognizedTypeInfo::Result: break;` so it
    stays exhaustive (EH-B replaces that `break` with the mapping). No
    `CoreIdentifier` is needed in EH-A. An associated constant named
    `.Result` (int.carbon:141 etc.) lives in an interface scope, never in
    the Core package root, so `IsInCorePackageRoot` (name_scope.h:410-412)
    cannot confuse the two.
7.  **Zero new diagnostics in EH-A.** The entry-point text change reuses
    `InvalidMainRunReturnType`; `?` over `Core.Result` reuses the seven B1b
    diagnostics; SF-6 rejections reuse `ChoicePayloadNotTrivialInSpecific`.

### §1.B EH-B — catching thunks, `Cpp.Exception`, `Carbon::expected`, fence diagnostic

1.  **Selection (D-EH-4) happens inside `PerformCppThunkCall`
    (thunk.cpp:791), keyed on the call's own parse node:** when `loc_id`
    is a node location whose kind is `CallExpr` and the NEXT postorder node
    (`Parse::NodeId(node.index + 1)`, `tree.node_kind`, tree.h:121-124;
    node_ids.h:36) is `PostfixOperatorQuestion`, the callee is
    fence-required (`IsCppThunkFenceRequired`, thunk.cpp:287), and the
    callee's mapped return type `S` does NOT implement `Core.Try`
    (`LookupImplWitness` in a discarded scratch block — the
    handle_question.cpp:260-286 pre-flight idiom), the call is emitted
    through the CATCHING thunk and has type `Core.Result(S, Cpp.Exception)`.
    Postorder makes this exact: `PostfixOperatorQuestion` has one child, so
    the node after a complete `CallExpr` subtree is its parent iff that
    parent is the `?` (parse golden operators/question.carbon:73-81).
    **Parenthesized operands (amended 2026-09-27, review fold: rev 2
    F6):** the adjacency test walks UP through `ParenExpr` nodes
    (node_kind.def:297; a `ParenExpr` also has exactly one expression
    child plus its `ParenExprStart` bracket, so the postorder successor of
    the `CallExpr` is the `ParenExpr`, and its successor is again either
    the `?` or another `ParenExpr`) so that `(Cpp.f())?` and
    `((Cpp.f()))?` select the catching thunk — `?` binds to the value, not
    the spelling. Guards: `loc_id.kind() == LocId::Kind::NodeId` before
    `loc_id.node_id()` (sem_ir/ids.h:1116/:1154 — an import- or
    desugar-located call has no node) and `index + 1 < tree.size()` at
    every step (parse/tree.h:107). Pinned by the `paren_operand` subfile
    (§4.B). **SF-6 bound on the success type (amended 2026-09-27, review
    fold: rev 2 F3):** forming `Core.Result(S, Cpp.Exception)` requires
    `S` to pass `IsInSliceChoicePayloadType` (type.cpp:313-320: int, float,
    bool or pointer after the adapter walk) — a C++ callee returning a
    class, `std::string`/`str`, or a constructor (a class by value) forms a
    specific that diagnoses `ChoicePayloadNotTrivialInSpecific`
    (eval_inst.cpp:243-250, from the :290/:322 sites) with no mention of
    `?` or C++. The selection therefore wraps the specific's formation in
    a `Diagnostics::ContextScope` (deduce.cpp:555 precedent) emitting the
    new `CppCatchingImportPayloadNote` (Context): "catching import of
    `{0}` requires a scalar success type in 0.1; `{1}` is not one" — so
    the user sees the SF-6 error plus the C++ context. `void` callees are
    unaffected (`()` is admitted by EH-A's D-EH-2 clause). The bound is
    the Sum-types bullet's SF-6 residue, stated in gap row 67's evidence
    and W-019's notes (§8.5, §8.6) and recorded as a dated doc amendment
    (§8.6); pinned by `fail_class_return` and `fail_ctor_return` (§4.B). The
    precedence rule's other two bullets need no code: an `S` that
    implements `Try` (a C++ function returning `Carbon::expected`, imported
    as `Core.Result` by way of §1.B.5) is an ordinary `Try` operand; a
    `noexcept` callee or `none` mode never reaches this branch (fence not
    required) and `?` then diagnoses the existing `QuestionOperandNotTry`
    (handle_question.cpp:349) — exactly the doc's "usual compile error for
    a non-`Try` operand" (:572-580, :679-681). Nested calls are safe: an
    argument call's `CallExpr` node is followed by more argument/`CallExpr`
    nodes, never directly by `?`. Rejected: rewriting the already-emitted
    fenced call from `handle_question.cpp` (would need in-place `Call`
    inst replacement plus argument re-plumbing); a `Context` flag set by
    `HandleParseNode(CallExprId)` (handle_call_expr.cpp:21-33) — works but
    leaks across the `PerformCall` recursion for Carbon callees; token
    lookahead (`tokens().GetKind`) — equivalent but couples check to lex.
2.  **The catching thunk is a second C++-side thunk per callee, built
    lazily and cached per file** in a `Context` map
    `cpp_catching_thunk_decls_: Map<SemIR::FunctionId, SemIR::InstId>`
    (no `SemIR::Function` field, no import_ref churn — C++ decls are
    per-file, import.cpp:151-160). Shape (Sema-built, thunk.cpp precedent
    :646-747):

    ```cpp
    // asm("<callee mangled>.carbon_thunk_catch.<modes>"), always_inline,
    // internal, noexcept (the fence stays: a throw escaping `catch(...)`
    // is impossible, but the spec keeps the boundary contract uniform).
    int f__carbon_catching_thunk(Params... p, T* _Nonnull ret,
                                 void** _Nonnull err) noexcept {
      try {
        new (ret) T(f(args...));   // or `f(args...); return 0;` for void
        return 0;
      } catch (...) {
        *err = __cxa_current_primary_exception();  // refcount +1, or null
        return 1;                                  // for a foreign exception
      }
    }
    ```

    `__cxa_current_primary_exception` is declared by a synthesized
    `FunctionDecl` placed INSIDE a synthesized `extern "C"`
    `LinkageSpecDecl` at TU scope with NO asm label (amended 2026-09-27,
    review fold: rev 2 F2): an `AsmLabelAttr("__cxa_current_primary_exception")`
    is emitted literally on every target (Mangle.cpp:266-277 prepends the
    `\01` marker whenever `getUserLabelPrefix()` is non-empty, and the
    label bypasses the prefix), which on Darwin (user label prefix `_`)
    names a symbol `__cxa_current_primary_exception` that libc++abi does
    not define (its symbol is `___cxa_current_primary_exception`). C
    linkage lets the target's mangler add the prefix, and the decl is
    byte-identical to cxxabi.h:170's own declaration, so a TU that also
    includes `<cxxabi.h>` sees a compatible redeclaration.
    `GeneratePlacementNewFunctionDecl` (:31-59) stays the synthesized-decl
    precedent; the decl is cached on `CppContext` beside
    `placement_new_decl_` (cpp/context.h:47-52). **Distinct Clang
    identifier (amended 2026-09-27, review fold: rev 2 F7):** the catching
    thunk's `DeclarationName` is built by `GetDeclNameForThunk`
    (thunk.cpp:482-526) from the callee's name, and that identifier
    becomes the imported SemIR function's name; reusing the fenced thunk's
    identifier would create a C++ overload set of the two thunks and two
    SemIR functions with the same name. `BuildCppCatchingThunk` therefore
    appends `__carbon_catching` to the identifier (a `is_catching`
    argument to `GetDeclNameForThunk`), and the asm label carries the
    `.carbon_thunk_catch` suffix (§2.B.3). Because the FENCED thunk is
    built eagerly at import time (import.cpp:2034-2062, inside
    `ImportFunction`'s caller) and the catching thunk lazily at the first
    `?`-selected call, a golden's `imports` block shows BOTH thunk decls
    for a callee used both ways (`question_select`, §4.B) — this is
    expected, not churn. The return value ALWAYS goes through the
    out-pointer (uniform shape; the existing `has_simple_return_type`
    split :640-745 is not reused for the catching variant) — for a `void`
    callee `ret` is omitted. The discriminant is `int` (simple ABI). ABI
    reference: libcxxabi/include/cxxabi.h:170-172,
    libcxxabi/src/cxa_exception.cpp:713-729 (returns the thrown object with
    an incremented refcount; NULL for foreign exceptions).
3.  **Carbon side of a catching call (`PerformCppCatchingThunkCall`, new in
    thunk.cpp) builds the `Result` with existing insts only:** the `ret`
    slot is the CALLER'S return slot, never a second temporary (amended
    2026-09-27, review fold: rev 2 F8) — `PerformCallToFunction`
    (check/call.cpp:240-259) already creates a `TemporaryStorage` of type
    `S` as `return_arg_id` whenever `InitRepr::ForType(S).MightBeInPlace()`,
    and `PerformCppThunkCall` peels it off the argument list as
    `return_slot_id` (thunk.cpp:825-828); the catching variant uses that
    inst as `ret` (for a by-copy `S` such as `i32` there is no slot, so
    the catching path mints one `TemporaryStorage ret: S` — the only case
    where it allocates — and none for `S == ()`), `TemporaryStorage
    err: Core.CppCompat.VoidBase*`, `AddrOf` both, the thunk `Call`
    (returns i32), `BuildBinaryOperator(EqWith.Equal, disc, IntLiteral 0)`
    → bool (the `EmitChoiceDiscriminantTest` idiom, pattern_match.cpp:543-
    556), `AddDominatedBlockAndBranchIf` (control_flow.h:34) into an
    Ok block / fall-through Err block, each performing `PerformCall` on
    the alternative constructor obtained by `PerformMemberAccess` on the
    `Core.Result(S, Cpp.Exception)` type inst with `NameId` "Ok"/"Err"
    (handle_question.cpp:366-371 shows the by-string `NameId` idiom) and
    `InitializeExisting` (convert.h:116-118) into one shared
    `TemporaryStorage result: Core.Result(S, Cpp.Exception)`, then
    `AddConvergenceBlockAndPush` (control_flow.h:41) with `result` (a
    reference expression) as the call's value. The `Result` specific is
    formed exactly as `MakeOptionalType` forms `Core.Optional(T)`
    (import.cpp:1367-1372: `LookupNameInCore` + `PerformCall` + `ExprAsType`)
    — hence `Result` joins core_identifier.def. The `Err` argument: `err`
    (a `VoidBase*` value) is converted to `Cpp.Exception` with
    `ConvertForExplicitAs(..., /*unsafe=*/false)` (convert.h:203-205) — the
    prelude adapter's `value as Adapter` conversion, the same `as` the
    prelude uses at optional.carbon:31. Rejected: having the C++ thunk
    write the Carbon choice's bytes directly (layout coupling on the C++
    side); a synthesized Carbon-side wrapper function (a second
    `MakeGeneratedFunctionDecl` surface for no reuse).
4.  **`Cpp.Exception` (D-EH-3):** prelude file core/prelude/types/cpp/
    exception.carbon (package `Core library "prelude/types/cpp/exception"`,
    export-imported from types.carbon after `cpp/void`): `class
    CppCompat.Exception { adapt VoidBase*; }` with `impl ... as Copy { fn
    Op(self) -> Self = "primitive_copy"; }` and `impl ... as UnformedInit
    {}` (the cpp/int.carbon:44-70 shape). Surfaced by a new
    `LookupBuiltinName` case (import.cpp:2453-2500): `*name == "Exception"`
    → `MakeCppCompatType(context, loc_id, CoreIdentifier::Exception)`
    (the `MapNullptrType` path, :1221-1223, :1106-1111) — which is what
    the doc means by "synthesizes the type into the `Cpp` package scope
    alongside the built-in file-less entities" (:683-712). **Reserved-name
    rule (:701-706) — mechanism corrected (amended 2026-09-27, review
    fold: rev 2 F1):** `ImportNameFromCpp` runs `LookupMacro` and then
    `ClangLookupName` FIRST (import.cpp:2685-2693) and reaches
    `ImportBuiltinNameIntoScope` → `LookupBuiltinName` (:2588-2593 →
    :2451) only when Clang lookup finds nothing, so a header's `struct
    Exception {}` or `#define Exception ...` would silently win over the
    builtin, violating the doc. The fix is an explicit reserved-name
    pre-check inserted in `ImportNameFromCpp` BEFORE the macro lookup at
    :2685: if `IsTopCppScope(context, scope_id)` (:2443) and the name is
    `Exception`, the builtin is imported unconditionally
    (`ImportBuiltinNameIntoScope`), and — to deliver the doc's "colliding
    entity is not reachable" note — `LookupMacro`/`ClangLookupName` are
    still consulted; if either finds something, the new Warning
    `CppReservedNameShadowed` is emitted at the use ("C++ entity
    `Exception` declared at global scope is not reachable as
    `Cpp.Exception`, which names the Carbon built-in type; name it through
    a C++-side alias in bridge code" — a Warning because Carbon notes
    attach to an error builder and there is no error here; the
    `ExportRedundant`/`RepeatedConst` Warning precedents). The
    `reserved_name` golden (§4.B) pins both the type identity and the
    warning. No other builtin name gets the pre-check: `long`/`nullptr`
    cannot be declared by a header.
    `RecognizedTypeInfo::Kind` gains `CppException` (`CppCompat` +
    "Exception", type_info.cpp:198 switch) printing as `Cpp.Exception`
    in a `cpp_file` (the `CppNullptrT` precedent :264-266).
5.  **Export mapping (F-006h):** `TryMapClassType`'s `case Result:` maps
    `Core.Result(T, E)` to the C++ class template `Carbon::expected<T', E'>`
    found by NAME in the TU — new `LookupCppClassTemplate(context,
    {"Carbon", "expected"})` (LookupCppType's walk, type_mapping.cpp:102-
    131, but returning the `ClassTemplateDecl`) — instantiated with
    `CheckTemplateIdType` (the cpp/call.cpp:353-356 precedent) on the
    recursively mapped `T'`/`E'` (`()` maps to `VoidTy` explicitly; a
    Carbon class `T`/`E` must pass `IsTriviallyCopyableForExport`,
    export.cpp:1583-1602, else null — the doc's :759-770 rule, which SF-6
    already makes vacuous for anything but adapters). If the template is
    not declared, the new diagnostic `CppExportResultNeedsExpectedHeader`
    ("exporting `{0}` to C++ requires `#include <carbon/expected.h>` in the
    C++ code", InstIdAsType) is emitted where export.cpp:1013 would emit
    its generic TODO, and the mapping fails. `case CppException:` maps to
    `Carbon::Exception` (a plain struct, `LookupCppType`). The `Carbon`
    namespace is reopened, not clobbered, by the header — ordering
    corrected (amended 2026-09-27, review fold: rev 2 F10):
    `BuildCarbonNamespace` runs BEFORE `ParseImports`
    (generate_ast.cpp:1064-1067), so the Carbon-owned `NamespaceDecl`
    exists first and the header's `namespace Carbon { ... }` REOPENS it
    (ordinary C++ namespace reopening); the external source
    (generate_ast.cpp:298-331) only answers names ordinary lookup does not
    find, so the header's `expected`/`Exception` are found by
    `LookupCppClassTemplate`/`LookupCppType` as ordinary declarations.
    The layout contract (§1.B.6) is what lets export.cpp's unchanged
    machinery work: `BuildCppToCarbonThunkBody` (:1155-1256) declares
    `return_storage` of the mapped type and passes it by reference to the
    Carbon thunk, whose `ref` return parameter (:1263-1316) writes the
    Carbon `Result` object into it.
6.  **The header `<carbon/expected.h>` mirrors the choice layout, which is
    what makes the mapping a reinterpretation, not a conversion.**
    Carbon's `Result(T, E)` lowers as the packed struct
    `<{ <{ iN, [A-1 x i8] }>, [P x i8] }>` (lower/testdata/choice/
    payload_layout.carbon:66-73: discriminant sub-struct padded to the
    payload alignment `A`, then the max-of-fields region `P`; discriminant
    stored/loaded as `i8`, :73/:109; `UInt(1)` for two alternatives,
    handle_choice.cpp:618-641). For scalar `T`/`E` (all SF-6 admits), `P =
    max(sizeof T, sizeof E)` is a multiple of `A = max(alignof T, alignof
    E)`, so the C++ standard-layout class

    ```cpp
    template <typename T, typename E> class expected {
      unsigned char disc_;            // 0 = Ok, 1 = Err (Carbon's declaration order)
      union { T ok_; E err_; };       // placed at offset A, sized P: identical bytes
      ...
    };
    template <typename E> class expected<void, E> { unsigned char disc_; union { E err_; }; ... };
    struct Exception { void* primary_; std::exception_ptr ptr() const; [[noreturn]] void rethrow() const; };
    ```

    is byte-identical (`static_assert`s in the header pin
    `is_trivially_copyable<T>` and `offsetof(expected, ok_) ==
    alignof(union)`). API per D8 (:774-779): `has_value()`, `operator
    bool`, `value()`, `error()`, `value_or()`, `operator==`, a
    `Carbon::unexpected<E>` constructor for C++-side construction, and
    under `__cplusplus >= 202302L` conversions to/from `std::expected`.
    `Exception::ptr()` = `if (!primary_) return std::exception_ptr();
    try { __cxa_rethrow_primary_exception(primary_); } catch (...) {
    return std::current_exception(); }` (cxa_exception.cpp:756-770
    increments the refcount, so the stored pointer stays valid —
    lossless, D7). **NULL primary (amended 2026-09-27, review fold: rev 2
    F9):** `__cxa_current_primary_exception` returns NULL for a FOREIGN
    exception (one not thrown by the C++ runtime; cxa_exception.cpp:721-722
    "no way to refcount it") and `__cxa_rethrow_primary_exception(NULL)`
    is a no-op (:758 guards on `thrown_object != NULL`) — so the header
    must not rely on the rethrow to leave the function: `ptr()` returns an
    empty `std::exception_ptr` and `rethrow()` calls `std::terminate()`
    when `primary_` is null, both commented as the foreign-exception case
    (`has_value()` on the Carbon side is unaffected: the discriminant is
    `Err` regardless). **Apple link note (amended 2026-09-27, review fold:
    rev 2 F2):** libc++ on Apple platforms does NOT re-export
    `__cxa_rethrow_primary_exception` (libcxxabi/lib/
    symbols-not-reexported.exp:13), so a C++ consumer of
    `<carbon/expected.h>` that calls `ptr()`/`rethrow()` needs `-lc++abi`
    there; recorded in the header comment, §7 R-5 and W-059's notes
    (§8.5). Deviation recorded (V-3a register): the doc says
    `Cpp.Exception` "maps to `std::exception_ptr`" (:765-767) while the
    landed mapping is the layout-identical wrapper `Carbon::Exception`
    whose `.ptr()` is the `std::exception_ptr` — the doc's own usage line
    (:781, `r.error().ptr()`) already assumes the wrapper.
7.  **Install + include path:** the header ships at
    `lib/carbon/include/carbon/expected.h` (a `toolchain_files` target in
    toolchain/install/BUILD next to `:core` :145-148, added to
    `cc_toolchain_all_files` :284-296 and `all_data_files` :371-386, which
    feed `all_digest_files` :399-404 and the tarball); `InstallPaths` gains
    `include_path()` (= `root_ / "include"`, the `core_package` shape,
    install_paths.cpp:176-179); `AppendDefaultClangArgs` adds
    `-isystem <include_path>` beside the runtimes' `-stdlib++-isystem`
    loop (clang_invocation.cpp:174-181). Goldens do NOT depend on the
    install tree: file_test's data are the clang headers only
    (toolchain/testing/BUILD:59-67), so every export golden declares a
    local layout-compatible `namespace Carbon { template <...> struct
    expected {...}; }` skeleton in its inline C++ — the name-based lookup
    of §1.B.5 accepts it. Conformance programs use the real header.
8.  **Fence diagnostic (D-EH-5):** `BuildThunkBody` (thunk.cpp:646-747)
    wraps its statement, when `IsCppThunkFenceRequired` holds, in
    `ActOnCXXTryBlock(loc, CompoundStmt{body}, {ActOnCXXCatchBlock(loc,
    /*ExDecl=*/nullptr, CompoundStmt{ write-call, BuildCXXThrow(loc,
    nullptr, false) })})` (Sema.h:11349-11354, :8595). The `CompoundStmt`
    wrappers are load-bearing (amended 2026-09-27, review fold: rev 2
    F10): `ActOnCXXTryBlock` does `cast<CompoundStmt>(TryBlock)`
    (SemaStmt.cpp:4562; `CXXTryStmt::Create` takes a `CompoundStmt*`,
    StmtCXX.h:89) — a bare `Stmt` asserts; `ActOnCXXCatchBlock`
    (SemaStmt.cpp:4352-4356) stores its handler as a `Stmt*` without a
    cast, but CodeGen's `EmitCXXTryStmt` and the parser's convention treat
    the handler as a compound statement, so both operands are wrapped
    (`CompoundStmt::Create`). The write call is
    `__carbon_boundary_write(2, "<msg>", len)` — a synthesized decl with
    `AsmLabelAttr(getUserLabelPrefix() + "write")` (amended 2026-09-27,
    review fold: rev 2 F2: a bare `AsmLabelAttr("write")` is emitted
    literally on every target, Mangle.cpp:266-277, and Darwin's user label
    prefix `_` means libc's symbol is `_write` — the prefix is taken from
    `ast_context.getTargetInfo().getUserLabelPrefix()`, empty on
    Linux/ELF). The identifier still differs from any user-visible
    `write`, so no redeclaration conflict; POSIX on both V-1 platforms.
    Rejected for this decl: an `extern "C" write` declaration (a header's
    own `unistd.h` `write` with a different `ssize_t` spelling would
    surface a redeclaration diagnostic inside the thunk). Cached on
    `CppContext`; `<msg>` is a `clang::StringLiteral`
    "carbon: C++ exception escaped into Carbon through `<callee qualified
    name>`; terminating\n" (`decl->getQualifiedNameAsString()`). The
    `noexcept` spec stays (:529-533), so the `throw;` lands in the same
    `terminate.lpad` the lower golden pins today. This changes EVERY
    fenced thunk body in `catch` mode — 27 lower goldens (§6.B) — which is
    why it is the last, droppable commit. Rejected: `__builtin_printf`
    (stdout, lost on abort); a Carbon-side `Core.Print` loop (needs
    pointer indexing the prelude lacks, and R1's link bound).
9.  **W-007 five-way contention, landed without a refactor:** every EH-B
    edit to export.cpp/thunk.cpp/type_mapping.cpp is ADDITIVE at a switch
    arm or a new function — `TryMapClassType` gains two `case`s (§1.B.5),
    thunk.cpp gains `BuildCppCatchingThunk`/`PerformCppCatchingThunkCall`
    and one wrapper in `BuildThunkBody`, export.cpp gains one diagnostic
    site — and none moves or renames an existing function. That is the
    "minimal refactor" W-007 asked for: none. The unions/overloading/
    threading contenders remain able to add their own arms; the plan
    records this in W-007's notes (§8.5).

## §2 Implementation spec

### §2.A EH-A

1.  **core/prelude/types/result.carbon (new, ~60 lines):** header
    comment citing error_handling.md#the-coreresult-type and F-006a; the
    choice (§1.A.1); the `final impl` (§1.A.2). **core/prelude/types.carbon:**
    `export import library "prelude/types/result";` after :18.
    **core/prelude/types/optional.carbon:** `import library "prelude/try";`
    after :13, and the `Try` impl (§1.A.3) after the `Copy` impl at :49-53,
    with a comment recording D-EH-1 (body over the placeholder API; the
    doc sketch's `match` form applies once `Optional` is a choice).
2.  **toolchain/check/type.cpp:313-320:** the `()` clause (§1.A.4), with a
    comment naming W-070 option (a) and the three consuming sites.
3.  **toolchain/sem_ir/type_info.{h,cpp}:** `Result` kind + `ForType` case
    -   `ExpectsArgs` + `PrintLiteral` (§1.A.6).
        **toolchain/check/cpp/type_mapping.cpp:145-250:** `case Result: break;`
        (exhaustiveness).
4.  **toolchain/check/handle_function.cpp:373-393, :417-419:** the D10
    widening — unwrap the specific's first argument through `FacetValue`
    (type_mapping.cpp:212-215 idiom: `TryGetAs<SemIR::FacetValue>(arg)` →
    `type_inst_id`), accept `GetTupleType(context, {})` or `IsI32`; the
    message becomes "invalid return type for `Main.Run` function; expected
    `fn (...)`, `fn (...) -> i32`, `fn (...) -> Core.Result((), E)`, or
    `fn (...) -> Core.Result(i32, E)`".
5.  **Lowering (three files):**
    -   lower/type.cpp:350-362 (`TryHandleReturnForm`, `InitForm` case):
        before the `InitRepr` switch, if `SemIR::IsEntryPoint(...)` and
        `RecognizedTypeInfo::ForType(...).kind == Result`, record
        `entry_point_result_type_id_ = return_type_id` on the builder and
        `return SetEntryPointReturnInt32(func_ctx)` (:142-149).
        **Second, EXPLICIT edit (amended 2026-09-27, review fold: rev 1
        MAJOR-2):** `FunctionTypeInfoBuilder::Build()` calls
        `HandleReturnForm()` and THEN `HandleParameter(return_param_index)`
        (type.cpp:291-303), and `TryHandleParameter`'s `OutParamPattern`
        arm (:452-462) lowers an `InitRepr::InPlace` return type — which a
        choice is — as a pointer parameter through `AddLoweredParam`. The
        return-form edit alone therefore still grows `main` an `sret`-style
        pointer. Add, as the first statement of that arm (before the
        `InitRepr` switch): `if (entry_point_result_type_id_.has_value())
        { return IgnoreParam(index); }` — routing the return parameter into
        `unused_param_indices_` (:205-208) exactly as the `ByCopy`/`None`
        cases do, so the LLVM function is `i32 main()` with zero
        parameters. `FunctionTypeInfo` (type.h:27-46) gains `SemIR::TypeId
        entry_point_result_type_id = None`.
    -   lower/file_context.cpp:657-665 (`BuildFunctionBody`, after the
        unused-parameter poison loop; anchor corrected, amended 2026-09-27,
        review fold: rev 1 MINOR-6): if `entry_point_result_type_id`
        has a value, `CreateAlloca(GetType(result type))` in the entry
        block and `SetLocal(return_param_id, alloca)` — overriding the
        poison so `ReturnSlot` (handle.cpp:260-263) and the in-place
        initializer target real storage. (landed 2026-09-27, EH-A: the
        "override the poison" sequence was unimplementable — `SetLocal`
        CHECKs duplicate inserts (function_context.h:127-131), and
        `CreateAlloca` needs an insert block for its `CreateLifetimeStart`.
        Landed sequence, file_context.cpp:660-720: identify the return
        param before the poison loop and SKIP it there; create the decl
        block as the entry block and set the insert point; one
        `CreateAlloca` and one `SetLocal`; then `lower_block(decl_block_id)`
        positions into that same block. Review fix (3), MINOR. Two more
        headers carry the plumbing: lower/context.h (the message-global
        cache `entry_point_result_err_message_`), lower/function_context.h
        (its accessor) and lower/file_context.h
        (`FunctionInfo::entry_point_result_type_id`) — §6.A landed note.)
    -   lower/handle.cpp:307-315 (`ReturnExpr`, `InitRepr::InPlace`): after
        `InitializeStorage(...)`, if the function is the entry point with a
        `Result` return: `disc = load i8 (StructGEP 0,0 of the alloca)`;
        `icmp eq disc, 0`; `br ok, err`; `ok:` for `Ok(i32)` `StructGEP 1`
        → `load i32` (offset 0 of the region; the Ok tuple is `{i32}`,
        payload_layout.carbon:70-72 shape) → `ret i32`, for `Ok(())`
        `ret i32 0`; `err:` `call @write(i32 2, ptr @msg, i64 len)` (declared
        by `getOrInsertFunction`, the `printf` precedent handle_call.cpp:
        393-396; the message string is a private global like
        `printf_int_format_string`, lower/context.h:138-145) then `ret i32
        1`. Message: "carbon: `Main.Run` returned `.Err` of type `<E>`;
        exiting with code 1\n".
6.  **No BUILD changes** (core/prelude files are globbed; toolchain deps
    unchanged).

### §2.B EH-B

1.  **Prelude:** core/prelude/types/cpp/exception.carbon (§1.B.4) +
    types.carbon export line. **core_identifier.def:** `Exception`,
    `Result` (alphabetical). **type_info.{h,cpp}:** `CppException` kind.
2.  **import.cpp:2453-2500 (`LookupBuiltinName`):** the `"Exception"`
    case before the `StringSwitch` falls to `nullptr`; returns the
    `Core.CppCompat.Exception` type inst. **import.cpp:2685
    (`ImportNameFromCpp`, before `LookupMacro`):** the reserved-name
    pre-check of §1.B.4 — `IsTopCppScope` + name `Exception` → import the
    builtin, then consult `LookupMacro`/`ClangLookupName` only to decide
    whether to emit `CppReservedNameShadowed` (amended 2026-09-27, review
    fold: rev 2 F1).
3.  **thunk.h/.cpp:**
    -   `auto BuildCppCatchingThunk(Context&, const SemIR::Function&
        callee) -> clang::FunctionDecl*` — `CreateThunkFunctionDecl` shape
        with a `is_catching` flag threaded into `GenerateThunkMangledName`
        (suffix `.carbon_thunk_catch`, :76-118) AND into
        `GetDeclNameForThunk` (:482, identifier suffix `__carbon_catching`
        — the distinct-identifier requirement of §1.B.2; amended
        2026-09-27, review fold: rev 2 F7) and the parameter list of
        §1.B.2; body built by a new `BuildCatchingThunkBody` (the
        `BuildThunkBody` call construction :646-720 reused for the inner
        call; try/catch as §1.B.8; `*err = __cxa_current_primary_exception()`
        by way of `BuildDeclRefExpr`/`BuildCallExpr`/`BuildBinOp(BO_Assign)`).
    -   `auto GetOrBuildCppCatchingThunkDecl(Context&, SemIR::FunctionId)
        -> SemIR::InstId` — the cache (§1.B.2), importing the Clang thunk
        decl with `ImportFunction` exactly as import.cpp:2043-2062 does for
        the fenced thunk (`thunk_signature` all-`ByValue`), and setting
        `SetCppThunk` on the imported function; on build failure,
        `context.TODO(loc, "Unsupported: catching thunk for
        potentially-throwing C++ function could not be built")` — the
        :2102-2105 fail-closed shape — and the call falls back to the
        FENCED thunk (never an unfenced direct call).
    -   `PerformCppThunkCall` (:791): the §1.B.1 selection guard at the
        top (`LocId::Kind::NodeId` check, `ParenExpr` walk-up, `tree.size()`
        bound); when it fires, delegate to `PerformCppCatchingThunkCall`
        (§1.B.3) — passing the peeled `return_slot_id` (:825-828) as `ret`
        — and record the result inst in
        `context.cpp_catching_call_results()` (a `Set<InstId>` on
        `Context`) so §2.B.6 can annotate. The `Core.Result(S,
        Cpp.Exception)` specific is formed under the
        `CppCatchingImportPayloadNote` `ContextScope` (§1.B.1).
    -   `BuildThunkBody` (:646-747): the fence wrapper (§1.B.8), gated on
        `IsCppThunkFenceRequired(context, callee_info.decl)`; helpers
        `GetOrCreateBoundaryWriteDecl(CppContext&, Sema&)` (asm label
        `getUserLabelPrefix() + "write"`) and
        `GetOrCreateCxaCurrentPrimaryExceptionDecl(...)` (inside a
        synthesized `extern "C"` `LinkageSpecDecl`, no asm label; §1.B.2)
        beside `GeneratePlacementNewFunctionDecl` (:31).
4.  **check/cpp/context.h:** two cached `clang::FunctionDecl*` members
    with accessors (the :47-52 pattern).
5.  **type_mapping.cpp:** `LookupCppClassTemplate` (static, beside
    `LookupCppType` :102-131); `case Result:` and `case CppException:` in
    `TryMapClassType` (§1.B.5). **export.cpp:1007-1015:** before the
    generic "failed to map Carbon return type" TODO, if the return type is
    a `Result` specific and `LookupCppClassTemplate` finds nothing, emit
    `CppExportResultNeedsExpectedHeader` (Error) and return nullptr.
    **diagnostics/kind.def:** `CppExportResultNeedsExpectedHeader` (after
    :246's CppInterop block), `CppReservedNameShadowed` (Warning, same
    block; §1.B.4), `CppCatchingImportPayloadNote` (Context, same block;
    §1.B.1) and `QuestionCppCatchingImportNote` (Context; after :580
    `QuestionReturnTypeNotTry`) — four diagnostics, two of them added by
    the 2026-09-27 fold (rev 2 F1, F3).
6.  **handle_question.cpp:386-419 (break path):** if the operand inst is
    in `cpp_catching_call_results()`, wrap the `PerformCompoundMemberAccess`
    -   `PerformCall` in `Diagnostics::ContextScope` (deduce.cpp:555
        precedent) emitting `QuestionCppCatchingImportNote`: "operand of `?` is
        a call to potentially-throwing C++ function `{0}`; a thrown exception
        propagates as `Cpp.Exception`" — so a return type whose break type
        does not accept `Cpp.Exception` gets the existing `ConversionFailure`
        plus this context line.
7.  **base/install_paths.{h,cpp}:** `include_path()`. **base/
    clang_invocation.cpp:174-181:** `args.push_back(formatv("-isystem{0}",
    install_paths.include_path()))`. **install/BUILD:** `toolchain_files(
    name = "support_hdrs", srcs = ["include/carbon/expected.h"])` (lands
    at `lib/carbon/include/carbon/expected.h`: the rule strips the package
    path, install_filegroups.bzl:66-84) added to `cc_toolchain_all_files`
    and `all_data_files`. **toolchain/install/include/carbon/expected.h
    (new, ~180 lines):** §1.B.6, license header, C++17-only includes
    (`<cstddef>`, `<exception>`, `<type_traits>`, `<utility>`, and
    `<cxxabi.h>` for `__cxxabiv1::__cxa_rethrow_primary_exception`,
    libcxxabi/include/cxxabi.h:170-172 — the toolchain ships that header
    in `runtimes/libcxxabi/include`, clang_invocation.cpp:174-181). The
    header comment records the NULL-primary (foreign exception) contract
    and the Apple `-lc++abi` requirement of §1.B.6 (amended 2026-09-27,
    review fold: rev 2 F2, F9).

## §3 Commit structure

**EH-A (PR "EH-A: Core.Result, Optional as Try, Result entry points"),
four commits:**

1.  prelude + `()` admission + `RecognizedTypeInfo::Result` + entry-point
    check widening (compiles standalone; goldens stale).
2.  lowering: entry-point `Result` epilogue.
3.  §4.A goldens (AUTOUPDATE, empty CHECK lines, R15/R19) + the W-070 pin
    move + §5.A conformance programs + gap-analysis row 66 + ledger.
4.  discharge: decision-log entry, doc amendments (§8.6), README table.

**EH-B (PR "EH-B: catching imports, Cpp.Exception, Carbon::expected"),
five commits:**

1.  `Cpp.Exception` prelude class + builtin-name surfacing + core
    identifiers.
2.  catching thunk + `?` selection + context note.
3.  `Carbon::expected` mapping + header + install/include path + export
    diagnostic.
4.  fence diagnostic (**droppable**: if it fails hosted verification twice
    after one fix round, revert this commit alone, keep the SF-1 item
    open with the failure evidence — §7 R-9).
5.  §4.B goldens + §5.B conformance (un-SKIP + 3 programs) + gap-analysis
    row 67 + ledger + decision-log + docs.

## §4 Testdata matrix (R16: no hand-written goldens; autoupdate fills)

### §4.A EH-A

-   **check/testdata/operators/question_result.carbon** (full prelude,
    `//@dump-sem-ir` on positives; the question.carbon:23-116 subfile
    shapes over `Core.Result` instead of `MyResult`): `propagate`
    (`Open(n)?` in a `Core.Result(i32, i32)` function, statement/argument/
    chain positions), `convert` (`Result(i32, ErrA)?` inside a
    `Result(i32, ErrB)` function with `impl ErrA as Core.ImplicitAs(ErrB)`
    — ErrA/ErrB adapters over i32, the question.carbon:330-395 shape),
    `unit_ok` (`Core.Result((), i32)` — exercises the `()` payload on the
    Ok side), `generic` (`[T: type, E: type](r: Core.Result(T, E))` with
    `let v: T = r?;` — the final-impl collapse at the PRELUDE impl),
    `fail_class_payload` (`Core.Result(SomeClass, i32)` forcing use →
    `ChoicePayloadNotTrivialInSpecific`, the SF-6 bound pinned against the
    prelude type).
-   **check/testdata/operators/question_optional.carbon:** `some_none`
    (`fn F(o: Core.Optional(i32)) -> Core.Optional(i32) { return
    Core.Optional(i32).Some(o? + 1); }`), `pointer_niche`
    (`Core.Optional(i32*)?`), `fail_optional_in_result` (`Optional?` inside
    a `Result` function → `ConversionFailure` on `()` → `E`, D9's "no
    implicit bridge" pin), `fail_result_in_optional` (the converse),
    `fail_class_element` (`Core.Optional(str)?` → the SF-6 diagnostic).
-   **check/testdata/choice/unit_payload.carbon:** `choice U { A(x: ()),
    B(y: i32) }` construction + `match`; `Core.ControlFlow(i32, ())`
    positive (the W-070 flip). **fail_question_preflight.carbon:107-126**
    `fail_unit_break_type` subfile is DELETED (its pin is the design-
    sanctioned flip, R16(b) citation: W-070 option (a), D-EH-2) and its
    comment block replaced by a one-line pointer to the new positive.
-   **check/testdata/main_run/return_result.carbon:** `unit_ok`
    (`fn Run() -> Core.Result((), i32)`), `i32_ok`, `with_question`
    (`?` inside `Run`), `fail_bad_success_type` (`Core.Result(i64, i32)` →
    the widened `InvalidMainRunReturnType` text), `fail_non_result_class`,
    `fail_adapter_success_type` (`Core.Result(AdapterOverI32, i32)` → the
    same diagnostic; pins the `IsI32` `TypeId`-equality bound of §1.A.5;
    amended 2026-09-27, review fold: rev 1 MINOR-2).
    **main_run/fail_mismatch_return.carbon:13** CHECK text moves (autoupdate).
-   **lower/testdata/operators/question_result.carbon** (the lower
    question.carbon shape over the prelude type: the Branch call, the
    discriminant `icmp`, the early `ret`), **lower/testdata/choice/
    unit_payload.carbon** (pins the zero-sized store shape and the
    `<{ <{ i1, [3 x i8] }>, [4 x i8] }>` layout for `ControlFlow(i32,
    ())`), **lower/testdata/main_run/return_result.carbon** (`define i32
    (`define i32
    @main()`, the alloca'd return slot, the `load i8` discriminant, the
    `write` declaration and both `ret`s).
-   Hand-traced predictions the reviewers check against the autoupdate:
    `define i32 @main()` has ZERO parameters (no `sret`, no `ptr` — the
    §2.A.5 `IgnoreParam` edit; amended 2026-09-27, review fold: rev 1
    MAJOR-2); the `err` block's `write` callee is `declare i64 @write(i32,
    ptr, i64)`; `unit_payload`'s `Break(())` payload is the ONE-element
    tuple `((),)`, whose `InitRepr` is by-copy (a `Copy`-repr aggregate, the
    `tuple/one_entry` shape), so lowering emits `insertvalue { {} } poison,
    {} zeroinitializer, 0` (or the constant `{ {} } zeroinitializer`) and
    a `store { {} } ...` into the region field — a legal zero-size store
    LLVM accepts; a CARBON_FATAL/crash is the R-3 falsifier (prediction
    rewritten; amended 2026-09-27, review fold: rev 1 MINOR-6).
    **Amended 2026-09-27 after the falsifier fired (§7 R-3 note):** that
    prediction holds for the GENERIC `Core.ControlFlow(i32, ()).Break(())`
    only (symbolic payload → cover-then-update → runtime `store { {} }`).
    For the non-generic `U.A(())` the constructor folds: expect
    `@U.val = internal constant <{ <{ i1, [3 x i8] }>, [4 x i8] }>
    <{ <{ i1, [3 x i8] }> zeroinitializer, [4 x i8] zeroinitializer }>`
    (or `zeroinitializer` as a whole, since discriminant 0 + zero region
    is all-zero) and `@U.A` is a `llvm.memcpy` of that template into the
    `sret` return slot, 8 bytes — the alternative_copy.carbon `@Flag.val`
    shape; `@U.B` is unchanged runtime construction. The new
    `multi_unit_payload` subfile predicts the same for `V.C((), ())`
    (`{ {}, {} }` in a `[4 x i8]` region; `V`'s discriminant is `i1`,
    two alternatives).

### §4.B EH-B

-   **check/testdata/interop/cpp/exceptions/catching_thunk.carbon**
    (min_prelude/none is NOT enough — `Core.Result` needs the full
    prelude; use `INCLUDE-FILE: min_prelude/full.carbon`): `question_select`
    (`fn F() -> Core.Result(i32, Cpp.Exception) { return .Ok(Cpp.may_throw_int()?); }`
    — SemIR shows the `.carbon_thunk_catch` decl, both temporaries, the
    `EqWith` test, two alternative-constructor calls and the convergence),
    `void_callee` (`Cpp.may_throw()?` in a `Result((), Cpp.Exception)`
    function — no `ret` temporary), `nested_argument` (`Cpp.f(Cpp.g())?` —
    only `f` catching, `g` fenced), `same_callee_both_ways` (one `Cpp.f()`
    fenced, another `Cpp.f()?` catching — the per-call-site rule :657-661;
    the `imports` block shows BOTH thunk decls with distinct identifiers,
    §1.B.2), `paren_operand` (`(Cpp.may_throw_int())?` and
    `((Cpp.may_throw_int()))?` both select the catching thunk — the
    `ParenExpr` walk-up of §1.B.1; amended 2026-09-27, review fold: rev 2
    F6), `reserved_name` (inline C++ declares `struct Exception {}`;
    `Cpp.Exception` still names the Carbon class — :701-706 — and the
    `CppReservedNameShadowed` warning is emitted at the use; amended
    2026-09-27, review fold: rev 2 F1). `question_select`'s `imports`
    block shows both the eagerly built fenced thunk decl and the catching
    thunk decl (§1.B.2; amended 2026-09-27, review fold: rev 2 F7).
-   **check/testdata/interop/cpp/exceptions/fail_catching.carbon:**
    `fail_noexcept_callee` (`Cpp.cannot_throw()?` → `QuestionOperandNotTry`),
    `fail_none_mode` (`EXTRA-ARGS: --cpp-exceptions=none`, same diagnostic),
    `fail_break_type_mismatch` (`Cpp.may_throw_int()?` in a `Result(i32,
    i32)` function → `ConversionFailure` + the new context note),
    `fail_not_direct` (`let x: i32 = Cpp.may_throw_int(); ... x?` → the
    plain `QuestionOperandNotTry` — pins D-EH-4's boundary honestly),
    `fail_class_return` (`Cpp.may_throw_class()?` where the C++ callee
    returns a class by value → `ChoicePayloadNotTrivialInSpecific` plus
    the `CppCatchingImportPayloadNote` context line) and `fail_ctor_return`
    (`Cpp.Widget(1)?` — a constructor call, the class-by-value case in
    its most common spelling → the same pair; both pin the SF-6 bound of
    §1.B.1; amended 2026-09-27, review fold: rev 2 F3).
-   **check/testdata/interop/cpp/function/export/result_expected.carbon:**
    inline C++ declares the local `namespace Carbon { template <typename T,
    typename E> struct expected { unsigned char disc; union { T ok; E err; };
    }; struct Exception { void* p; }; }` skeleton, then `int Use() { return
    Carbon::F(1).has_value...` (the skeleton needs no methods — the golden
    pins the thunk's return type `Carbon::expected<int, int>` in the
    `imports` block and the export mapping, not C++ semantics);
    `fail_no_header` (no skeleton → `CppExportResultNeedsExpectedHeader`);
    `void_success` (`Core.Result((), i32)` → `Carbon::expected<void, int>`);
    `exception_error` (`Core.Result(i32, Cpp.Exception)` →
    `Carbon::expected<int, Carbon::Exception>`).
-   **lower/testdata/interop/cpp/exceptions/catching_thunk.carbon:** IR
    pins: the catching thunk's `landingpad ... catch ptr null`, the call to
    `@__cxa_current_primary_exception`, `ret i32 1`/`ret i32 0`, and the
    Carbon caller's `icmp`/`br` plus the two alternative stores.
    **lower/testdata/interop/cpp/exceptions/fenced_thunk.carbon** (existing)
    gains the `write` call + the message global in `terminate.lpad`'s
    predecessor (the fence-diagnostic commit's canonical pin).
    **lower/testdata/interop/cpp/function/export/result_expected.carbon:**
    the C++ thunk writing through `return_storage` of the skeleton type.
-   `--exclude-dump-file-prefix`/full-prelude cost: the new check goldens
    over `Core.Result` use the full prelude like question.carbon (:5); the
    exceptions goldens that need only `Cpp.Exception`'s pointer adapter
    still need `Core.Result` → full prelude too.

## §5 Conformance

### §5.A EH-A — four new programs, zero SKIP flips; floor **105 PASS / 0 FAIL / 28 SKIP over 133** (tree-relative)

All under bullet "Error handling: dedicated control flow constructs" (R7:
exact string; `runner.py --self-test` before commit). Harness conventions
(fork/w077/plan.md §5 on branch claude/carbon-fork-0-1-w077, merging as PR #39): `RuntimeSeed(x) = x + 20` inputs, EXPECT
values hand-derived (R16(d)), exit-code belt on every dispatch.

1.  **error_handling/result_prelude_diff.carbon + .diff.cpp** — the
    question_propagation_diff shape (3-deep `?` chain, runtime-selected
    failure depth) over `Core.Result(i32, i32)` with one ImplicitAs error
    conversion layer (`ErrA` → `ErrB`, adapters over i32, so the oracle's
    error code is `code + 1000`). C++ oracle: struct-shaped early return.
    Output table (both sides, hand-computed): depth 0 → `0,<2*seed>`;
    depth 1 → `1,1101`; depth 2 → `1,1202`; depth 3 → `1,1303`.
2.  **error_handling/optional_try.carbon** — `fn Half(n: i32) ->
    Core.Optional(i32)` returns `.Some(n / 2)` for even `n` and `.None()`
    for odd; `fn Quarter(n: i32) -> Core.Optional(i32) { let h: i32 =
    Half(n)?; return Half(h); }` (two `?`-reachable absences: the first
    propagated, the second returned). For each seed the program prints
    `HasValue()` as 1/0 and, when present, `Get()`. C++ mental model
    (`std::optional` with explicit early return), hand-derived: seed 40 →
    Some(10) → `1`, `10`; seed 42 → Half = 21 is odd → `Quarter` returns
    None → `0`; seed 41 → `Half(41)` is None → `?` propagates → `0`.
    A fourth probe applies `?` to `Core.Optional(i32*)` (the pointer
    niche): `var cell: i32 = RuntimeSeed(-14);` (= 6), `fn Deref(p:
    Core.Optional(i32*)) -> Core.Optional(i32)` returns `.Some(*(p?))`,
    and the program prints the pointee for `.Some(&cell)` → `6`.
    EXPECT-STDOUT is exactly `1`, `10`, `0`, `0`, `6` — five lines, the
    fourth probe's line included (reconciled; amended 2026-09-27, review
    fold: rev 1 MINOR-5).
3.  **error_handling/run_result_ok.carbon** — `fn Run() -> Core.Result(i32,
    i32)` computes `Core.Print`s then `return .Ok(RuntimeSeed(-17));`
    → EXPECT-EXIT 3, EXPECT-STDOUT the printed lines; also uses `?` on a
    helper inside `Run`.
4.  **error_handling/run_result_err.carbon** — `fn Run() -> Core.Result((),
    i32)` prints `1`, then `Fails(RuntimeSeed(-20))?` propagates `.Err(7)`
    → EXPECT-EXIT 1, EXPECT-STDOUT `1` only (the line after the `?` must
    NOT print — the belt). stderr is not asserted by the runner (it lands
    in logs/); the message is pinned by the lower golden.

`stdlib/optional_missing_ops.carbon` stays SKIP (its blocker is `EqWith`,
W-058; D-EH-1 does not touch it — recorded so no reviewer reads the
Optional `Try` impl as an "approved design").

### §5.B EH-B — one SKIP→PASS, three new; floor **109 PASS / 0 FAIL / 27 SKIP over 136** (tree-relative)

Bullet "Error handling: C++ exception interop (-fno-except config, calling
throwing C++, exporting Carbon errors as std::expected/exceptions)".

1.  **error_handling/cpp_exception_interop.carbon** — un-SKIP. The stub's
    intended body (:31-40) used the ANNOTATED-BINDING context
    (`let r: Core.Result(i32, Cpp.Exception) = Cpp.PositiveOrThrow(-2);`),
    which is D-EH-4's residue. Mechanical repair, disclosed per R6 in the
    commit message and the program header: route through a one-line
    helper `fn Checked(n: i32) -> Core.Result(i32, Cpp.Exception) { return
    .Ok(Cpp.PositiveOrThrow(n)?); }` and `match (Checked(RuntimeSeed(-22)))`.
    EXPECT-STDOUT stays `7`, `-1`; EXPECT-EXIT 0; the `.Ok` arm's `return 1`
    belt stays.
2.  **error_handling/cpp_exception_catch_diff.carbon + .diff.cpp** — the
    throw-path differential B0's value pair deferred (cpp_exceptions_
    fence_value_diff.carbon:36-44): `CheckedScale(v, f)` throws on `f ==
    0`; Carbon calls it through `?` in a `Result(i32, Cpp.Exception)`
    helper and prints `1,<value>` / `0,-1` per runtime-selected factor; the
    C++ oracle wraps the same call in `try { ... } catch (const
    std::invalid_argument&) { ... }` — byte-identical stdout/exit (DIFF-1).
3.  **error_handling/cpp_expected_export.carbon** — Carbon `fn
    Parse(n: i32) -> Core.Result(i32, i32)` (Err(-n) for negative);
    inline C++ `#include <carbon/expected.h>` and `int Consume(int n) {
    auto r = Carbon::Parse(n); return r.has_value() ? r.value() * 2 :
    r.error(); }`; `Run` prints `Cpp.Consume(RuntimeSeed(-15))` (=10) and
    `Cpp.Consume(RuntimeSeed(-23))` (=3, the error). Also a `Core.Result((),
    i32)` export consumed as `Carbon::expected<void, int>`.
4.  **error_handling/cpp_exception_rethrow_export.carbon** — the lossless
    rethrow (D7): Carbon `fn Catching(n: i32) -> Core.Result(i32,
    Cpp.Exception) { return .Ok(Cpp.Throws(n)?); }` exported; C++ `int
    Recover(int n) { auto r = Carbon::Catching(n); if (r) return r.value();
    try { r.error().rethrow(); } catch (const std::runtime_error& e) {
    return e.what()[0]; } return -1; }` → prints the first byte of the
    original message (`'n'` = 110 for "negative"), proving the dynamic type
    and object survived the round trip.

The B0 programs are untouched; cpp_exceptions_fence_terminate.carbon's
header gains one sentence pointing at the boundary diagnostic's lower pin
(comment-only). README table regenerated (`runner.py --update-readme-table`).

## §6 Churn inventory (verified by grep at 5551790)

### §6.A EH-A

-   **Existing goldens that move: exactly two files.**
    check/testdata/main_run/fail_mismatch_return.carbon:13 (diagnostic
    text) and check/testdata/operators/fail_question_preflight.carbon
    (the `fail_unit_break_type` subfile removed, :107-126). Prelude
    additions have precedent for zero collateral churn: commit 6b0b80e
    (try.carbon) touched only its own new goldens and the min_prelude parts
    (`git show --stat 6b0b80e`), because check dumps exclude the prelude
    and SemIR names are symbolic. No lower golden contains a
    `Result`-returning `Run` (`grep -rn 'Run() -> Core.Result' toolchain
    fork` is empty), and the 41 lower goldens defining `@main` keep their
    `i32`/void paths byte-identical (the epilogue is gated on the `Result`
    return).
-   **min_prelude parts:** unchanged. parts/optional.carbon is a curated
    copy (it diverges from core already, see the `diff`), and no test
    combines it with `Try`; parts/try.carbon stays (the pre-flight golden's
    "no Try impl exists" load-bearing premise, toolchain/testing/testdata/
    min_prelude/try.carbon:12-21, is preserved because the impls live in result.carbon
    and optional.carbon, not try.carbon).
-   Source files touched: 12 (count corrected 9 → 12; amended 2026-09-27,
    review fold: rev 1 MINOR-4): (1) core/prelude/types/result.carbon
    (new); (2) core/prelude/types.carbon; (3) core/prelude/types/
    optional.carbon; (4) toolchain/check/type.cpp; (5) toolchain/check/
    handle_function.cpp; (6) toolchain/sem_ir/type_info.h; (7) toolchain/
    sem_ir/type_info.cpp; (8) toolchain/check/cpp/type_mapping.cpp (one
    `break`); (9) toolchain/lower/type.h; (10) toolchain/lower/type.cpp
    (two sites, §2.A.5); (11) toolchain/lower/file_context.cpp; (12)
    toolchain/lower/handle.cpp. (landed 2026-09-27, EH-A: 15 source files
    were touched, not 12 — the twelve above plus (13) toolchain/lower/
    context.h (the `entry_point_result_err_message_` message-global
    cache), (14) toolchain/lower/function_context.h (the accessor threading
    it to `handle.cpp`) and (15) toolchain/lower/file_context.h
    (`FunctionInfo::entry_point_result_type_id`); review fix (2), MINOR.
    The two moved goldens were exactly the two predicted; c127784c4 also
    rewrapped one 82-column comment in fail_question_preflight.carbon,
    review fix (1).)

### §6.B EH-B

-   **Fence-diagnostic commit: 27 lower goldens move** — every file
    containing `__clang_call_terminate` (the fenced-thunk pin):
    interop/cpp/class/import/{alignment,base,constructor,conversion,
    dynamic,method,virtual_base}, enum, exceptions/fenced_thunk, extern_c,
    function/export/{function,generic}, function/import/{function_decl,
    function_in_template,parameters,return}, globals,
    globals_carbon_defined, nullptr, operators, pointer, reference,
    share_ast, std_initializer_list, template, thunks, void. Each gains the
    `write` call, the message global, and the `throw;` resume edge inside
    the thunk; the Carbon caller's IR is unchanged. This is the R-9
    drop-rule's blast radius and the reason the commit is last.
-   **Zero check goldens move:** check dumps show thunk DECLS only
    (interop/cpp/exceptions/fenced_thunk.carbon:37-54), and no existing
    golden applies `?` to a C++ call (`grep -rln 'Cpp\.[A-Za-z_]*(.*)?'
    toolchain/check/testdata` is empty).
-   **Catching/export commits: only new goldens** (§4.B) plus the six
    new registrations: four diagnostics (§2.B.5) and two core identifiers
    (§2.B.1) (count updated; amended 2026-09-27, review fold: rev 2 F1,
    F3).
-   Source files touched: 14 (exception.carbon new; types.carbon;
    core_identifier.def; sem_ir/type_info.{h,cpp}; check/cpp/{import,
    thunk,thunk.h,context.h,type_mapping,export}.cpp; check/handle_question
    .cpp; check/context.h (two containers); diagnostics/kind.def;
    base/install_paths.{h,cpp}; base/clang_invocation.cpp; install/BUILD;
    install/include/carbon/expected.h new).

**Churn addendum (landed 2026-09-27, EH-A, hosted verification):** the
"exactly two existing files" prediction held for CHECK goldens, but eight
LOWER goldens moved as well — array/iterate, for/bindings,
for/break_continue, for/for, primitives/optional, interop/cpp/nullptr,
interop/cpp/pointer, interop/cpp/void — every changed line a
`DILocation`/`DISubprogram` line number (verified: zero non-debug-info
lines changed). Cause: lowered debug info for `Optional`'s methods embeds
their source line numbers, and `core/prelude/types/optional.carbon` gained
one import line plus the `Try` impl above nothing (the methods sit above
the impl, but the `import library "prelude/try";` line shifts them by one).
Lesson for §6 inventories: any prelude edit that shifts lines ABOVE a
method used by lowered code moves the DI line numbers of every lower golden
that inlines or references that method — count those files (grep the
prelude symbol's linkage name in lower goldens) before claiming zero
collateral.

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — `Result` recognized by name collides with a user `Core`
    extension.** Only package `Core`'s root can declare `Result`
    (`IsInCorePackageRoot`); user packages cannot. A user file `package
    Core library "..."` DOES compile (check/testdata/packages/
    core_name_poisoning.carbon:27, missing_prelude.carbon:27/:43), so the
    honest statement is: a user `Core` library declaring a root `Result`
    is the SAME pre-existing exposure `Optional`/`Char`/`String` already
    have through `RecognizedTypeInfo::ForType`'s `StringSwitch`
    (type_info.cpp:185-190) — no new surface. Falsifier: any existing
    packages/ golden moving (reworded; amended 2026-09-27, review fold:
    rev 1 MINOR-3).
-   **R-2 — prelude `final impl` over `Result` conflicts with user `impl
    MyResult as Try`.** Different `Self` types; impl lookup is per type.
    Falsifier: control_flow_constructs.carbon keeps PASSing unchanged.
-   **R-3 — zero-sized payload lowering.** `Break(())` stores a `((),)`
    tuple — a ONE-element tuple whose `InitRepr` is by-copy (`Copy` repr),
    so the payload takes the by-copy regime: lowering builds the value
    with `insertvalue { {} } poison, {} zeroinitializer, 0` and emits a
    `store { {} }` into the zero-byte region field — a legal zero-size
    store LLVM accepts (prediction restated; amended 2026-09-27, review
    fold: rev 1 MINOR-6); the check-side `TupleInit` of an empty element
    is the `tuple/one_entry` shape. Falsifier: lower/choice/
    unit_payload.carbon's autoupdate hits a CARBON_FATAL/crash or produces
    a non-zero-size region. Contingency: the
    D-EH-2 break condition (scalar carrier for `Optional`, `Result((), E)`
    unaffected).
    **2026-09-27 — falsifier FIRED (run 36301651448; `PadToType` CHECK
    in `EmitAggregateConstant<llvm::ConstantStruct>`, reached from
    `LowerConstants()` ← `FileContext::PrepareToLower()`).** Root cause:
    the prediction above covered only the RUNTIME regime. On the
    non-generic `choice U { A(x: ()), B(y: i32) }` the payload tuple
    `((),)` has exactly one value, so inside `@U.A` the parameter's
    conversion (`converted %_.param, tuple_init ()`) is a concrete
    constant and `EvalConstantInst(ClassInit)` (eval_inst.cpp) folds the
    constructor's `class_init` to `%U.val: %U = struct_value (%int_0,
    %tuple)` — a `StructValue` whose payload element carries the payload
    TUPLE type `((),)` (LLVM `{ {} }`) because handle_choice.cpp's
    non-symbolic arm initializes the alternative's tuple FIELD inside the
    `CustomLayoutType` region (a sub-object), not the region field itself
    (check golden unit_payload.carbon:123). `LowerConstants` lowers every
    concrete constant eagerly; `PadToType({ {} } zeroinitializer,
    [4 x i8])` had no arm for a constant that is neither the element type
    nor its tail-padded wrapper → CHECK. Non-zero-sized payloads never
    fold (they depend on the parameter), every pre-existing choice
    constant covers the region with `%uninit` OF the region type (exact
    type match, for example `%Sized.val = struct_value (%int_2, %uninit)`), and
    generic choices (`Core.ControlFlow`, `Core.Result`) take the symbolic
    cover-then-`UpdateInit` path — so the shape is reachable ONLY through
    D-EH-2's `()` admission on a non-generic choice, exactly what the
    falsifier was for. Fix (toolchain/lower/constant.cpp `PadToType`,
    now taking the `DataLayout`): a zero-sized constant placed in a byte
    region `[N x i8]` contributes no bytes → the region's zero filler
    (identical to the `EmitAsConstant(UninitializedValue)` cover and to
    what the runtime zero-size `store` leaves behind); the residual
    `cast<StructType>` became `dyn_cast` folded into the CHECK so any
    OTHER mismatch stays loud instead of tripping LLVM's cast assertion
    first. Zero churn for existing goldens: the new arm runs only when
    `constant->getType() != llvm_type`, which no pre-existing constant
    satisfies. Contingency NOT taken: the fix is 4 lines and general
    (any all-zero-sized payload tuple, `((), ())` included — pinned by the
    new `multi_unit_payload` subfile). Residual (documented, not fixed
    here): the folded `%U.val` is ill-typed at element 1 in SemIR
    (`EvalConstantInst(ClassInit)`'s `ClassValue` TODO); no check-side
    consumer reaches it since calls do not fold, so lowering is the
    single consumer and now handles it.
-   **R-4 — entry-point epilogue versus the `ReturnSlot` inst.** `ReturnSlot`
    reads the return param's local (handle.cpp:260-263); the plan binds
    that local to an alloca AFTER the poison loop, so ordering is correct
    by construction. (landed 2026-09-27, EH-A: the local is bound ONCE,
    not overridden — the poison loop skips the return param and the alloca
    binding follows it, §2.A.5 landed note; ordering is still by
    construction. Falsifier status: pending the re-dispatched refill — the
    first fill, run 36301020281, was polluted by the R-12 event and
    reverted at 92a6191ee.) Falsifier: `main_run/return_result.carbon` IR shows a
    `poison` operand, OR `define i32 @main(` has any parameter at all
    (the `TryHandleParameter` `OutParamPattern` arm lowering the choice
    return as a pointer param — the §2.A.5 second edit; amended
    2026-09-27, review fold: rev 1 MAJOR-2).
-   **R-5 — `write` on non-POSIX, and symbol prefixes on macOS.** V-1
    scopes 0.1 to Linux/macOS; W10 (Windows) already budgets the boundary
    thunks' MSVC variant (error_handling.md:835-837) — add "the entry-point
    `write(2)` and the fence diagnostic" to that item's notes (§8.5).
    macOS (amended 2026-09-27, review fold: rev 2 F2): synthesized asm
    labels are emitted literally (Mangle.cpp:266-277), so the two
    synthesized decls must not hard-code an unprefixed label — §1.B.2
    (`extern "C"` for `__cxa_current_primary_exception`) and §1.B.8
    (`getUserLabelPrefix() + "write"`) handle it; and libc++ on Apple does
    not re-export `__cxa_rethrow_primary_exception`
    (libcxxabi/lib/symbols-not-reexported.exp:13), so C++ consumers of
    `<carbon/expected.h>` link `-lc++abi` there (header comment; W-059
    notes). Falsifier: a Darwin link of cpp_exception_rethrow_export
    failing on an undefined `___cxa_*` symbol — not exercised by the
    Linux hosted gate, so it is recorded as a V-1 macOS follow-up in
    W-059's notes rather than asserted.
-   **R-6 — parse-tree lookahead breaks on error recovery.** A `?` whose
    operand subtree has errors still has the `?` node as parent; if the
    call inst is `ErrorInst` the handler bails before reaching
    `PerformCppThunkCall`. Falsifier: any `fail_` subfile crashing.
-   **R-7 — the `Carbon::expected` layout mirror is wrong for some
    `T`/`E`.** The argument in §1.B.6 covers scalars, which is all SF-6
    admits; the header's `static_assert`s and cpp_expected_export.carbon's
    runtime values are the falsifier (a wrong offset reads garbage, never
    `3`/`10`). If a future SF-6 widening admits non-scalar payloads, the
    header's `static_assert(sizeof(expected) == A + P)` style checks fail
    to compile, loudly.
-   **R-8 — `Cpp.Exception` accessors deferred** (D-EH-3(ii)). The gap-
    analysis row says PARTIAL for this reason; the work item names the
    mechanism (a Sema-built helper `const char* __carbon_exception_what(void*)`
    with `try { __cxa_rethrow_primary_exception } catch (const std::exception& e)
    { return e.what(); } catch (...) { return nullptr; }`, buildable only
    when `std::exception` is declared in the TU).
-   **R-9 — fence-diagnostic commit fails hosted verification** (Sema
    try/catch construction is the least-precedented code in the PR). Drop
    rule: after one fix round, if the gate is still red on that commit,
    revert it alone; W-016's SF-1 follow-up stays open citing the run.
-   **R-10 — `Carbon` namespace external source versus header-declared
    `expected`.** `BuildCarbonNamespace` reuses an existing namespace and
    the external source answers only names the Main package defines
    (generate_ast.cpp:298-331, :1063). Falsifier: fail_no_header's
    counterpart positive golden `result_expected.carbon` failing to find
    the skeleton template.
-   **R-11 — the `?`-lookahead selects catching for a `Try`-implementing
    `S`.** Excluded by the explicit witness pre-check (§1.B.1), but that
    arm cannot be exercised by a golden yet: its only producer is the
    IMPORT direction (`Carbon::expected<T,E>` → `Core.Result(T,E)`, the
    doc's :668-673), which is not in this plan (it needs a
    custom_type_mapping.cpp matcher, the std::string_view precedent :93-
    104; recorded as the residue item "`Carbon::expected` import direction",
    provisional id W-082, §8.5 — id renumbered; amended 2026-09-27, review
    fold: rev 1 + rev 2 ID collision), and C++ cannot return a Carbon
    choice otherwise. The selection is bounded from the other side instead:
    `fail_not_direct` and `same_callee_both_ways` (§4.B) pin exactly when
    the catching thunk is chosen. The pre-check code path stays in place
    so the residue's landing needs no selection change.
-   **R-12 — prelude `match` has no in-prelude precedent (added; amended
    2026-09-27, review fold: rev 1 MAJOR-1).** result.carbon's `Branch` is
    the first `match` statement compiled inside package `Core`
    (`grep -rn 'match (' core/prelude` is empty today); it depends on the
    file-scoped `Core.EqWith` lookup (§1.A.1) and on the choice-pattern
    machinery being usable before the full prelude is loaded. Mitigation:
    the explicit `prelude/operators/comparison` import, and building
    `//core/...` + one full-prelude check golden FIRST in commit 1.
    Falsifier: the first autoupdate run shows anything but new-file churn
    — a prelude compile error moves EVERY full-prelude golden at once (the
    6460af008 failure mode; hand-off note). Contingency: rewrite `Branch`
    over the discriminant with an `if` on the alternative constructor's
    equality (still `EqWith`, no `match`), which keeps the same import.
    (landed 2026-09-27, EH-A: **the falsifier FIRED exactly as written** —
    on optional.carbon, not result.carbon. The first hosted autoupdate (run
    36301020281) moved ~230 goldens: every full-prelude golden gained the
    same two errors, `optional.carbon:71: cannot access member of interface
    Destroy in type T that does not implement that interface
    [MissingImplInMemberAccess]`, and the lower goldens collapsed. Root
    cause: inside `forall [T: OptionalStorage]`, `Branch` moves a `T`
    payload into `ControlFlow(T, ()).Continue(...)`, and a symbolic `T`
    bound by a non-`type` facet carries only its declared constraints, so
    `T: Destroy` was unprovable; result.carbon's `[T: type, E: type]` impl
    — and its `match`, the risk this entry named — compiled fine. Fix,
    c127784c4: `final impl forall [T: Destroy & OptionalStorage] Optional(T)
    as Try` — the file's own `ImplicitAs` impls (optional.carbon:110, :117)
    already use that bound for the same reason. The polluted fill was
    reverted (92a6191ee) and the refill re-dispatched. Recorded in the
    decision-log EH-A entry as a review MISS (R28(d): the single
    implementation review traced the impl and did not catch it) and as the
    lesson: a symbolic binding bound by a non-`type` facet has only its
    declared interfaces; moving a value of that type requires `Destroy` in
    the bound.)
-   **Rejected alternatives (recorded once):** re-platforming `Optional`
    (§0.3 D-EH-1); an `unsafe`/explicit catching spelling (Option A's
    wrapper, rejected by F-006); mapping `Cpp.Exception` to an imported
    C++ struct (fails SF-6, §1.B.4); a synthesized `main` wrapper (§1.A.5);
    `__builtin_printf` for the fence message (§1.B.8); one PR (§0.4).

## §8 Verification and discharge

1.  **Regen (per PR):** `Fork: hosted verification` mode `autoupdate` to
    fixpoint (R26/R28(d): the gate's file_test pass proves the fixpoint);
    expected churn confined to §6 — EH-A: two existing files + new files;
    EH-B commits 1-3 and 5: new files only; commit 4: the 27 listed lower
    goldens.
2.  **Gate:** mode `gate` green (prek + `bazel test //toolchain/...`;
    clang-format 21.1.8 per R18 on the C++ diff; `uvx prek run --files
    <changed>` locally before every push, R25).
3.  **Conformance:** mode `conformance`; EH-A **105/0/28 over 133** (landed 2026-09-27: 106/0/28 over 134 after #39 added one program), EH-B
    **109/0/27 over 136** (both +1/+1 after W-077 merges); `runner.py
    --self-test` and `--update-readme-table` clean. Any other movement is
    a §5/§6 miss — stop and reconcile.
4.  **Reconciliation greps at discharge:** `grep -rn 'fail_unit_break_type'
    toolchain` is empty; `grep -rn 'does not have language features
    dedicated to error handling' docs fork` hits only history in this plan
    and the decision log (the gap-analysis occurrence left the tree at
    f0e1980; amended 2026-09-27, review fold: rev 2 F4); the `Unsupported:
    fenced thunk` string survives at import.cpp:2103-2105 and gains a
    sibling `Unsupported: catching thunk` at the new site; `grep -rn
    '__cxa_' toolchain/check/cpp` hits exactly the one synthesized
    `__cxa_current_primary_exception` decl and its call site (the `write`
    decl carries no `__cxa_` prefix; count corrected).
5.  **Ledger edits (fork/inventory/work-items.json):**
    -   W-017 → kind `implemented`, title "EH-B1 (LANDED at EH-A): prelude
        `Core.Result` + `Try` impl; `Optional as Try`; `Result` entry
        points", evidence = result.carbon, optional.carbon impl lines,
        handle_function.cpp/lower sites, the §4.A goldens, the §5.A
        programs; blocked_by cleared; notes record §0.2 items 1 and 7 and
        D-EH-1/D-EH-2 verbatim.
    -   W-018 → kind `implemented`, blocked_by cleared, notes: "LANDED at
        B1a/B1b/B2a over user choices (PRs #15/#16/#18); the prelude `Try`
        impls landed at EH-A; the token line is :108" (§0.2 item 2).
    -   W-019 → kind `implemented` with PARTIAL residue, blocked_by cleared
        (W-007 precondition unmet, §0.2 item 3), notes: catching by `?`,
        `Cpp.Exception` storage/rethrow, `Carbon::expected` header + mapping,
        fence diagnostic (or its R-9 drop record), and the SF-6 bound on
        catching imports — "`Cpp.f()?` requires `f`'s return type to be
        scalar (int/float/bool/pointer after adapters) or `void` in 0.1;
        class/`std::string`/constructor returns diagnose
        `ChoicePayloadNotTrivialInSpecific` with the
        `CppCatchingImportPayloadNote` context; lifts with SF-6" (amended
        2026-09-27, review fold: rev 2 F3).
    -   W-016 → title retext ("noexcept-spec fenced thunks"), notes gain
        the SF-1 discharge (or drop) line (§0.2 item 4).
    -   W-070 → DISCHARGED at EH-A by option (a); blocked_by cleared
        (§0.2 item 5).
    -   W-007 → notes: "EH-B landed additively (§1.B.9); the refactor-first
        precondition was not met and no refactor was needed; re-evaluate
        when a second contender starts".
    -   W-058 → notes: "`Optional` gained a `Try` impl over the placeholder
        API at EH-A (D-EH-1); the approved-design work must keep the impl
        signature `final impl forall [T: Destroy & OptionalStorage]
        Optional(T) as Try where .ContinueType = T and .BreakType = ()`"
        (landed 2026-09-27, EH-A: bound corrected from `[T:
        OptionalStorage]` — the `Destroy` half was runner-exposed, §7 R-12
        landed note; the ledger note carries the corrected signature).
    -   **Three NEW residue items, referred to BY TITLE throughout this
        plan; the ids below are PROVISIONAL (amended 2026-09-27, review
        fold: rev 1 + rev 2 ID collision).** W-079 is TAKEN by the W-077
        discharge (struct patterns in let/var/param, PR #39, not yet on
        trunk — trunk's max id is W-078). Instruction: at discharge,
        allocate ids by verifying `max id` on trunk at that moment
        (`grep -oE '"id": ?"W-[0-9]+"' fork/inventory/work-items.json |
        sort -t- -k2 -n | tail -1`) and renumber every cross-reference in
        this plan, the gap-analysis residue text and the decision-log
        entry in the same commit; never assume the provisional numbers.
        -   NEW (provisional W-080) "`Cpp.Exception` accessors and
            release-on-destroy": `TypeName()`/`Message()` + release
            (D-EH-3 bounds; mechanism R-8; blocked_by: the
            SF-6/destroy-synthesis residue of W-010 for the release half).
        -   NEW (provisional W-081) "catching-import selection in
            binding/argument contexts" (D-EH-4 residue; workaround
            recorded; blocked_by: none — needs an expected-type channel).
        -   NEW (provisional W-082) "`Carbon::expected` import direction":
            `Carbon::expected<T,E>` → `Core.Result` (error_handling.md:
            668-673; a custom_type_mapping.cpp matcher, the
            std::string_view precedent; W-011 family).
    -   W-059 (W10 Windows) notes gain the POSIX `write(2)` dependency
        of the entry-point epilogue and the fence diagnostic (R-5), and
        the macOS notes: asm labels need `getUserLabelPrefix()`, and
        libc++ on Apple does not re-export `__cxa_rethrow_primary_exception`
        (symbols-not-reexported.exp:13) so `<carbon/expected.h>` consumers
        link `-lc++abi` (amended 2026-09-27, review fold: rev 2 F2).
    -   The file header's "Updated ... by" trail gains one sentence per PR.
6.  **Docs:** docs/design/error_handling.md — dated amendments (history
    unrewritten, the fourth-round precedent): the staging table :800-812
    gains a "landed at EH-A/EH-B" column note and the W5-S3p row records
    D-EH-1; :397-416's `Optional` sketch gets the "signature normative
    MODULO the `T: OptionalStorage` bound the placeholder class forces
    (optional.carbon:29) — the sketch's `[T: type]` becomes `[T:
    OptionalStorage]`; body over the placeholder API until W-058" note
    (amended 2026-09-27, review fold: rev 1 MINOR-1); :526-529 the
    `Cpp.Exception`-message clause is marked deferred (the "`Cpp.Exception`
    accessors and release-on-destroy" item, provisional W-080); :674-678
    the selection rule marks the binding-context arm deferred (the
    "catching-import selection in binding/argument contexts" item,
    provisional W-081) AND gains the dated amendment "in 0.1 a catching
    import requires the C++ return type to map to a scalar (int, float,
    bool, pointer, after adapters) or `void`, because
    `Core.Result(S, Cpp.Exception)` is a choice specific bound by SF-6
    (toolchain/check/type.cpp `IsInSliceChoicePayloadType`); a class or
    `std::string` return is diagnosed at the `?` with a context note.
    Break condition: the SF-6 lift (Sum types bullet, W-010 residue)
    removes this sentence" (amended 2026-09-27, review fold: rev 2 F3);
    :734 the release clause marked deferred (provisional W-080); :765-767
    the `std::exception_ptr` mapping sentence amended to
    `Carbon::Exception` with `.ptr()`. docs/design/README.md:3885-3918
    needs no change (it already points at the doc). **fork/gap-analysis.md
    (targets rebased onto f0e1980; amended 2026-09-27, review fold: rev 2
    F4):** row 66 ("Error handling: dedicated control flow constructs")
    PARTIAL → **DONE** at EH-A with evidence "`?` over `Core.Try` with
    prelude `Core.Result`/`Optional` `Try` impls and `Result` entry
    points (W-017/W-018/W-070 discharged); 8/8 conformance programs PASS;
    the scalar-payload bound is the Sum types bullet's SF-6 residue";
    header counts 26/20/8/2 → **27 DONE / 19 PARTIAL / 8 MISSING / 2
    DESIGN-ONLY**. Row 67 ("Error handling: C++ exception interop ...")
    STAYS **PARTIAL** at EH-B with its evidence rewritten: "B0 boundary
    contract + catching imports selected by `?` as `Core.Result(S,
    Cpp.Exception)` (scalar/`void` `S` only — SF-6) + `Cpp.Exception`
    storage/rethrow + `Carbon::expected` export header and mapping + the
    SF-1 boundary diagnostic (or its drop record); 8/8 conformance
    programs PASS (cpp_exception_interop un-SKIPped). Residue:
    `Cpp.Exception` accessors and release-on-destroy; catching-import
    selection in binding/argument contexts; `Carbon::expected` import
    direction (ids allocated at discharge, §8.5)"; header counts unchanged
    by EH-B (27/19/8/2). Conformance floors are tree-relative (§5: +1/+1
    on both sides once W-077 merges). R7: bullet TEXT untouched.
7.  **Decision log:** entries "EH-A: Core.Result, Optional as Try, Result
    entry points (date)" and "EH-B: catching imports, Cpp.Exception,
    Carbon::expected (date)" carrying D-EH-1..6 with break conditions,
    the §0.2 ledger corrections verbatim, the V-3a divergence-register
    additions (`Carbon::Exception` wrapper naming; the `()` payload
    admission; `Core.Result` as an independent choice), the three residue
    items named BY TITLE with the ids allocated at that discharge (§8.5;
    amended 2026-09-27, review fold: rev 1 + rev 2 ID collision), the
    §0.4 fallback-split record (rev 2 F11), and the OPEN-forks section's
    SF-9 entry moved under Decided with a pointer here.

## Hand-off notes for the implementer

-   R27 first: diff result.carbon's impl and optional.carbon's impl
    SIGNATURE against error_handling.md:383-409 before anything else —
    `final` included.
-   Build `//core/...` and ONE full-prelude check golden before anything
    else in EH-A commit 1: a prelude compile error moves EVERY
    full-prelude golden (the 6460af008 failure mode), so the first
    autoupdate must show new-file churn only; result.carbon needs the
    explicit `prelude/operators/comparison` import for its `match`
    (§1.A.1; amended 2026-09-27, review fold: rev 1 MAJOR-1).
-   The `()` admission is ONE predicate edit; do not add per-site checks.
-   Entry point: TWO lower/type.cpp edits (§2.A.5) — the return-form
    switch AND the `OutParamPattern` arm's `IgnoreParam` — the return
    parameter must land in `unused_param_indices_` (poisoned) and then be
    OVERRIDDEN with the alloca; if you find the param in
    `lowered_param_indices_` instead, or `define i32 @main(` has any
    parameter, the `main` signature is wrong (amended 2026-09-27, review
    fold: rev 1 MAJOR-2).
-   Catching selection lives in `PerformCppThunkCall`, keyed on the
    `CallExpr` node's successor with a `ParenExpr` walk-up; guard
    `loc_id.kind() == LocId::Kind::NodeId` and `index + 1 < tree.size()`
    at every step (§1.B.1). The catching thunk reuses the peeled
    `return_slot_id` as `ret`; give it a distinct Clang identifier
    (`__carbon_catching`); declare `__cxa_current_primary_exception`
    `extern "C"` and prefix the `write` asm label with
    `getUserLabelPrefix()` (amended 2026-09-27, review fold: rev 2 F2,
    F6, F7, F8).
-   The catching thunk's `ret` out-param is unconditional (also for simple
    ABI types) — do not reuse `has_simple_return_type`.
-   Goldens never include `<carbon/expected.h>`; they declare the skeleton
    inline. Conformance programs include the real header.
-   Land the fence-diagnostic commit LAST and alone; its 27-golden churn is
    expected and enumerated (§6.B).
-   Every new AUTOUPDATE golden ships with empty CHECK lines (R15/R19);
    hand-derived EXPECT values only (R16(d)); `runner.py --self-test`
    before every conformance commit (R7).

## Sign-off

Two adversarial plan reviews (rev 1, rev 2) returned
APPROVE-WITH-AMENDMENTS for both EH-A and EH-B; every amendment is folded
above, each marked "(amended 2026-09-27, review fold: ...)", mirroring
fork/w077/plan.md. Every line cited by a review was re-verified in-tree
before folding; three citations were corrected in the fold (noted in
items 7, 9 and 16).

**EH-A folds:**

1.  rev 1 MAJOR-1 — result.carbon imports `prelude/operators/comparison`
    (`match` on a choice routes through `Core.EqWith`, pattern_match.cpp:
    537-559; file-scoped `Core` lookup name_lookup.cpp:621-684; `EqWith`
    at comparison.carbon:18; uint.carbon does not re-export operators);
    §1.A.1 cycle check extended (comparison imports only bool +
    int_literal); §7 R-12 added (no in-prelude `match` precedent;
    falsifier: anything but new-file churn on the first autoupdate);
    hand-off note on the every-golden blast radius (6460af008).
2.  rev 1 MAJOR-2 — §2.A.5 gains the explicit second lower edit:
    `FunctionTypeInfoBuilder::Build()` calls `HandleReturnForm()` then
    `HandleParameter(return_param_index)` (lower/type.cpp:291-303) and
    the `OutParamPattern` `InPlace` arm (:452-462) would lower the choice
    return as a pointer param — `if (entry_point_result_type_id_
    .has_value()) return IgnoreParam(index);` added at the top of that
    arm; R-4's falsifier and the §4.A prediction extended to "`define i32
    @main()` has zero parameters"; hand-off note updated.
3.  rev 1 MINOR-1 — D-EH-1 wording: `Optional`'s `Try` impl signature is
    the doc sketch's MODULO the `OptionalStorage` bound (optional.carbon:
    29 vs error_handling.md:397-398); said in §0.3, §1.A.3 and the §8.6 doc
    amendment; `final` + facet-bound + rewrite precedent facet/
    validate_rewrite_constraints.carbon:288 cited.
4.  rev 1 MINOR-2 — §1.A.5's "`IsI32` already admits adapters" was
    false (handle_function.cpp:297-301 is a `TypeId` equality); the bound
    is stated honestly (`Result(AdapterOverI32, E)` rejected, same as the
    plain `-> AdapterOverI32` today) and pinned by the new
    `fail_adapter_success_type` subfile (§4.A); the
    `GetTransitiveAdaptedType` walk was rejected as a separate D10
    question.
5.  rev 1 MINOR-3 — §7 R-1's falsifier was false (`package Core library
    "..."` compiles: packages/core_name_poisoning.carbon:27,
    missing_prelude.carbon:27/:43); reworded to the pre-existing
    `Optional`/`Char`/`String` exposure (type_info.cpp:185-190), no new
    surface.
6.  rev 1 MINOR-4/5/6 — §6.A source-file count 9 → 12, enumerated;
    §5.A.2's EXPECT-STDOUT reconciled with the pointer-niche probe (five
    lines, `6` from `RuntimeSeed(-14)`); §0.1 row 9 grep list completed
    (nine files); anchors corrected (`StringifyConstantInst` precedent
    file_context.cpp:555-557, poison loop :657-665); R-3 / §4.A prediction
    rewritten — `((),)` is a one-element tuple → Copy repr → by-copy
    regime → `insertvalue { {} } poison ...` + `store { {} }`, legal; the
    CARBON_FATAL falsifier kept.
7.  rev 2 F4 — rebase facts: trunk f0e1980 already reconciled the
    gap-analysis (26/20/8/2; rows 66-67 both PARTIAL with accurate
    text). §0.2 item 6 rewritten to "status flip only"; header
    paragraph, §0.1 row 17, §3, §8.4 and §8.6 retargeted (row 66 PARTIAL
    → DONE at EH-A, 27/19/8/2; row 67 stays PARTIAL at EH-B with
    evidence rewritten; floors tree-relative, +1/+1 once W-077 merges).
    Citation correction: the README sentence no longer survives anywhere
    (the plan had said gap-analysis:59).
8.  rev 1 + rev 2 (ID collision) — W-079 is taken by the W-077 discharge;
    the three residue items are referred to BY TITLE throughout, with
    provisional ids W-080 (`Cpp.Exception` accessors and
    release-on-destroy), W-081 (catching-import selection in
    binding/argument contexts), W-082 (`Carbon::expected` import
    direction); §8.5 carries the allocate-at-discharge instruction (verify
    max id on trunk); cross-references fixed in §0.3 D-EH-3/D-EH-4, §7
    R-11, §8.5, §8.6 (doc amendments and gap-analysis residue text) and
    §8.7.

**EH-B folds:**

9.  rev 2 F1 MAJOR — §1.B.4's reserved-name mechanism was wrong
    (`ImportNameFromCpp` runs `LookupMacro` + `ClangLookupName` first,
    import.cpp:2685-2693, and reaches `LookupBuiltinName` only on a miss,
    :2588-2593 → :2451). An explicit pre-check before :2685
    (`IsTopCppScope` :2443 + name `Exception` → builtin) is specified,
    with the doc's "colliding entity unreachable" note delivered as the
    Warning `CppReservedNameShadowed` when Clang lookup also finds
    something; `reserved_name` golden kept and extended; §2.B.2, §2.B.5,
    §6.B updated. Citation note: the review's :2686-2693 is :2685-2693 in
    the tree (the `if (clang::MacroInfo* macro_info =` line).
10. rev 2 F2 MAJOR — asm labels are not macOS-portable (Mangle.cpp:
    266-277 emits a synthesized label literally; Darwin's user label
    prefix is `_`). Adapted rather than taken verbatim: `__cxa_current_
    primary_exception` is declared inside an `extern "C"`
    `LinkageSpecDecl` with no asm label (identical to cxxabi.h:170);
    `write` KEEPS its distinct `__carbon_boundary_write` identifier with
    the label prefixed by `getUserLabelPrefix()` (the review's second
    option) so a header's own `write` cannot surface a redeclaration
    diagnostic inside a thunk. Apple's non-re-export of
    `__cxa_rethrow_primary_exception` (libcxxabi/lib/
    symbols-not-reexported.exp:13 — path corrected from the review's
    bare filename) recorded in the header comment, §7 R-5 and W-059's
    notes (`-lc++abi`).
11. rev 2 F3 MAJOR — SF-6 bounds catching imports: `Core.Result(S,
    Cpp.Exception)` needs `S` to pass `IsInSliceChoicePayloadType`
    (type.cpp:313-320); class/str/ctor returns get
    `ChoicePayloadNotTrivialInSpecific` (eval_inst.cpp:243-250 from
    :290/:322). Bound stated in §1.B.1, gap row 67's evidence and W-019's
    notes; `fail_class_return` + `fail_ctor_return` added to
    fail_catching.carbon; the specific's formation wrapped in a
    `Diagnostics::ContextScope` emitting `CppCatchingImportPayloadNote`;
    dated doc amendment with the SF-6-lift break condition added to §8.6.
12. rev 2 F6 — adjacency test walks up through `ParenExpr` nodes
    (node_kind.def:297) so `(Cpp.f())?` selects the catching thunk
    (walk-up chosen over pinning `fail_paren`); guards `loc_id.kind() ==
    LocId::Kind::NodeId` (sem_ir/ids.h:1116/:1154) and `index + 1 <
    tree.size()` (parse/tree.h:107); `paren_operand` subfile added.
13. rev 2 F7 — the catching thunk gets a DISTINCT Clang identifier
    (`GetDeclNameForThunk`, thunk.cpp:482-526, becomes the SemIR function
    name; suffix `__carbon_catching`); §1.B.2/§4.B note that the fenced
    thunk is built eagerly at import (import.cpp:2034-2062), so
    `question_select`'s `imports` block shows BOTH decls.
14. rev 2 F8 — §1.B.3 reuses the caller's return slot: `PerformCallTo
    Function` (check/call.cpp:240-259) creates the `TemporaryStorage` when
    `MightBeInPlace` and `PerformCppThunkCall` peels it as
    `return_slot_id` (thunk.cpp:825-828); it is `ret`; a second temporary
    is minted only for by-copy `S` (no slot exists) and never for `()`.
15. rev 2 F9 — the header handles a NULL primary exception
    (`__cxa_current_primary_exception` returns NULL for foreign
    exceptions, cxa_exception.cpp:721-722; `__cxa_rethrow_primary_
    exception(NULL)` is a no-op, :758): `ptr()` → empty `exception_ptr`,
    `rethrow()` → `std::terminate()`, foreign-exception case commented.
    Lines corrected from the review's :722-723/:755-757.
16. rev 2 F10 — §1.B.5's ordering sentence fixed (`BuildCarbonNamespace`
    runs BEFORE `ParseImports`, generate_ast.cpp:1064-1067; the header
    reopens the namespace); §1.B.8 records that the `CompoundStmt`
    wrappers are load-bearing. Citation correction: the hard requirement
    is `ActOnCXXTryBlock`'s `cast<CompoundStmt>(TryBlock)` at
    SemaStmt.cpp:4562 (`CXXTryStmt::Create`, StmtCXX.h:89);
    `ActOnCXXCatchBlock` at :4352-4356 stores its handler as a `Stmt*`
    without a cast, so the catch wrapper is by CodeGen/parser convention
    rather than a Sema assert — both are still wrapped.
17. rev 2 F11 (record only) — EH-B stays ONE PR per R29(b); §0.4 records
    that its catching and export halves are file-disjoint and MAY be
    split into two M PRs as a fallback if implementation-review attention
    overruns.

Status: APPROVED FOR IMPLEMENTATION, 2026-09-27.

## EH-B landed notes (2026-09-27)

EH-A's landed notes are the inline "(landed 2026-09-27, EH-A: ...)" annotations
above; EH-B's are collected here. Branch claude/carbon-fork-0-1-ehb, commits
94b588847, c83d33051, 3eb4ed0e7, afccce55f, 973fd41f1, 90d49c24d, aa04ea7e0
(plus two trunk merges); one PR, the §0.4 fallback split not invoked. Ledger ids
allocated at discharge: the provisional W-080/W-081/W-082 of §0.3, §7 R-11, §8.5
and §8.6 are **W-083** ("`Cpp.Exception` accessors and release-on-destroy"),
**W-084** ("catching-import selection in binding/argument contexts") and
**W-085** ("`Carbon::expected` import direction") — the ledger's max id at
discharge was W-082 (the W-012 discharge took W-080..W-082 after W-077 took
W-079). The provisional numbers in the sections above are left as written; this
note is the mapping.

**Deltas from the spec (each recorded with its reason in the decision-log entry
"EH-B: catching thunks, Cpp.Exception, Carbon::expected export"):** the
`fail_none_mode` arm is its own file,
check/testdata/interop/cpp/exceptions/fail_catching_none_mode.carbon, because
`EXTRA-ARGS` is file-wide (§4.B listed a subfile). §1.B.3's convergence is the
`if`-expression shape — `AddConvergenceBlockWithArgAndPush` with each arm's
`Result` value as the block argument — not `InitializeExisting` into a shared
`TemporaryStorage`. `cpp_catching_call_results` is `Map<InstId, FunctionId>`
(§2.B.3 said a `Set<InstId>`) so the `?` note names the callee.
Reference-returning callees fail closed (thunk.cpp:1148-1153: TODO plus the
fenced fallback). The identifier suffix is `__carbon_catching_thunk`
(thunk.cpp:651), not §1.B.2/§2.B.3's `__carbon_catching`. A fifth diagnostic,
`InCppCatchingThunk` (kind.def:245), exists because `CARBON_DIAGNOSTIC` must be
declared once and `InCppThunk` lives in import.cpp:2048. `RequireCompleteType`
(thunk.cpp:1367) forces the `Result` specific's completion under the
`CppCatchingImportPayloadNote` scope before any CFG is emitted. types.carbon
exports `cpp/exception` alphabetically (types.carbon:10, before `cpp/int`), not
"after `cpp/void`" (§1.B.4). The header adds `has_exception()`, `operator*` and
`ok()` beyond D8's list, and `value()` is non-throwing by precondition. The
catching thunk is imported through the new public `ImportCppThunkFunctionDecl`
(import.h:93; `AddImportIRInst` + the static `ImportFunction`, nothing else) —
the review blocker: §2.B.3's "importing the Clang thunk decl with
`ImportFunction` exactly as import.cpp does for the fenced thunk" was
implemented through `ImportCppFunctionDecl`, whose `IsCppThunkRequired` check on
the thunk itself would have thunked the thunk for a `const C&` implicit object
parameter and tripped `SetCppThunk`'s CHECK; the `member` subfiles pin it.
Hosted-build misses (review misses per R28(d)): the `clang/Basic/TargetInfo.h`
include for `getUserLabelPrefix()` (90d49c24d) and `LookupCppDecl` returning
`clang::QualType()` from a `clang::Decl*` function (aa04ea7e0).

**Stale citations found by the implementer (not corrected in place; recorded
here):** the docs/design/error_handling.md line numbers cited throughout §1.B
and §8.6 (:526-529, :674-678, :683-712, :701-706, :715-720, :734, :765-767,
:774-779, :781) predate EH-A's amendments and are shifted — the landed anchors
are the selection rule at :700-707 with its amendment at :709-720, the release
clause at :778 with the D-EH-3 amendment at :786-801, and the mapping amendment
at :837-845; §1.B.4's "export-imported from types.carbon after `cpp/void`"
(alphabetical in fact); §4.B's `fail_none_mode` subfile (a file); §1.B.3's
shared-storage convergence (the `if`-expression shape); §1.B.2/§2.B.3's
identifier suffix `__carbon_catching` (`__carbon_catching_thunk`); §5.B.2's
print format "`1,<value>` / `0,-1`" (the program prints each value on its own
line with `Core.Print`, and the C++ oracle matches that); §2.B.5's back-quoted
"exporting `{0}`" (the landed text is "exporting {0} to C++ requires ..." —
`InstIdAsType` formats the type with its own back-quotes); and the `.Ok(...)`
shorthand the plan writes in §1.B.3, §4.B and §5.B does not exist in this tree —
constructors are spelled `Core.Result(S, E).Ok(...)` (the doc's own workaround
line still uses the shorthand). Also §0.1 row 2 / §8.4's import.cpp:2103-2105 is
now import.cpp:2114.

**Reconciliation greps run at discharge (§8.4), on 6dda6a89d:**

-   `grep -rn 'fail_unit_break_type' toolchain` → 0 hits.

-   `grep -rln 'does not have language features dedicated to error handling'
    docs fork` → fork/audit/2026-07-19-area-reports.json,
    fork/audit/2026-07-19-synthesis.json, fork/eh/plan.md — history only (the
    audit snapshots and this plan); the decision log no longer carries it.

-   `Unsupported: fenced thunk` → import.cpp:2114 (the surviving site) plus its
    16 golden pins in
    check/testdata/interop/cpp/function/import/{class,struct,union}.carbon and
    exceptions/fail_fence_thunk_unbuildable.carbon; `Unsupported: catching
    thunk` → thunk.cpp:1241 (the new sibling) and the thunk.h:48 comment. Before
    EH-B: 1 and 0 code sites; after: 1 and 1.

-   `grep -rn '__cxa_' toolchain/check/cpp` → thunk.cpp:107 (the one synthesized
    `__cxa_current_primary_exception` identifier; the call site uses the cached
    decl, so there is no second string), plus comments at thunk.cpp:73, :990,
    :997, :1033 and context.h:89. The `write` decl carries no `__cxa_` prefix,
    as §8.4 says.

-   Diagnostic-kind uniqueness: each of `InCppCatchingThunk` (kind.def:245),
    `CppReservedNameShadowed` (:254), `CppCatchingImportPayloadNote` (:255),
    `CppExportResultNeedsExpectedHeader` (:256) and
    `QuestionCppCatchingImportNote` (:601) appears exactly once in kind.def and
    has exactly one `CARBON_DIAGNOSTIC(...)` declaration
    (`CppReservedNameShadowed`'s spans two lines at import.cpp:2721). Five
    registrations, one more than §2.B.5's four (the `InCppCatchingThunk` delta
    above).

-   `git diff origin/trunk...HEAD --diff-filter=M -- toolchain/check/testdata
    toolchain/lower/testdata toolchain/parse/testdata toolchain/lex/testdata
    toolchain/driver/testdata` → EMPTY. The branch modifies no existing golden;
    it adds six CHECK-free ones (check:
    interop/cpp/exceptions/{catching_thunk,fail_catching,fail_catching_none_mode}.carbon,
    interop/cpp/function/export/result_expected.carbon; lower:
    interop/cpp/exceptions/catching_thunk.carbon,
    interop/cpp/function/export/result_expected.carbon). The 27 lower goldens
    the fence diagnostic moves (§6.B) are therefore NOT yet moved in the tree at
    this commit — the hosted autoupdate fills them, and `grep -rl
    __clang_call_terminate toolchain/lower/testdata` on 6dda6a89d lists exactly
    the 27 files §6.B enumerates:
    interop/cpp/class/import/{alignment,base,constructor,conversion,dynamic,method,virtual_base},
    enum, exceptions/fenced_thunk, extern_c, function/export/{function,generic},
    function/import/{function_decl,function_in_template,parameters,return},
    globals, globals_carbon_defined, nullptr, operators, pointer, reference,
    share_ast, std_initializer_list, template, thunks, void. Expected churn per
    §6.B: exactly those 27 plus the six new files; any other file moving in the
    fill is a §6 miss.

-   Conformance (tree-relative, NOT locally executed — hosted-only per R28): the
    un-SKIP is real in the tree (`grep -rl '^// SKIP' fork/conformance/programs`
    drops from 28 files on origin/trunk to 27, none under error_handling/), and
    the three new programs plus the differential's `.diff.cpp` are present.
    Numbers: <!-- VERIFY: numbers --> (§5.B's floor 109/0/27 over 136 was stated
    before W-012 added one program to trunk).

**Ledger (§8.5) as applied:** W-019 → `implemented`, DISCHARGED with the SF-6
bound and residue in its notes, evidence re-pinned to the landed sites,
blocked_by cleared; W-016 retitled "noexcept-spec fenced thunks", DISCHARGED
(SF-1 landed; droppable under R-9), and W-020's stale blocked_by on it cleared;
W-007 notes record the additive landing; W-059 notes gain the fence `write(2)`
and macOS notes; W-083/W-084/W-085 filed. fork/gap-analysis.md's
exception-interop row stays PARTIAL with the evidence rewritten; header counts
untouched. Decision-log entry "EH-B: catching thunks, Cpp.Exception,
Carbon::expected export (2026-09-27)". Contradiction with §8.5 recorded
honestly: it says W-016's title becomes "noexcept-spec fenced thunks" although,
since D-EH-5, the fenced thunk's BODY does contain a `try`/`catch` — the retitle
is still right because the fence (what terminates) is the `noexcept` spec; the
try/catch only adds the message.
