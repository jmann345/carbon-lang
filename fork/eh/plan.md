<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# EH plan: the error-handling remainder (Result, `?` closure, C++ exception interop)

**Status:** PLAN — awaiting two adversarial plan reviews (rulebook R29(c)).
Branch `claude/carbon-fork-0-1-eh` off trunk 5551790 (pre-PR #39: W-077's
struct-pattern PR is in its single implementation review; conformance in
this tree is **101 PASS / 0 FAIL / 28 SKIP over 129** per
fork/conformance/out/scoreboard.json totals — every floor below is stated
relative to that, and W-077's merge adds exactly one PASS program to both
sides of every equation). All line numbers are against trunk 5551790.

**Items:** W-017 (EH-B1 prelude `Core.Result`), W-018 (EH-B2 `?` +
`Core.Try`), W-019 (EH-B3 catching thunks + `Carbon::expected`), the SF-1
follow-up carried on W-016, and the two OPEN sub-forks the remainder hangs
on (SF-9, W-070). **Design authority, not reopened:** fork/decision-log.md
F-006 (:491-523) with sub-decisions F-006a..l, the B0 SF-1..5 trades
(:51-59), the design text docs/design/error_handling.md (the ratified
normative doc; the option paper fork/design-sprint/error-handling.md is its
research record).

**Milestone bullets this plan flips** (fork/gap-analysis.md:59-60, both
still MISSING in the table even though their conformance rollups are PASS):
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
| 9 | Prelude `Core.Result(T, E)` with `Ok`/`Err` (F-006a) | MISSING | `grep -rn Result core/prelude` hits only arithmetic `.Result` associated constants (int.carbon:141-220, float.carbon:196-216, char.carbon:93-128); no `result.carbon`; conformance programs use a user `MyResult` (control_flow_constructs.carbon:29-32) |
| 10 | `Result`'s `Try` impl | MISSING | no impl exists; sketch at docs/design/error_handling.md:383-396 (`final impl forall [T: type, E: type] Result(T, E) as Try`) |
| 11 | `Optional` implements `Try`, `BreakType = ()` (F-006i/D9) | MISSING, doubly gated | core/prelude/types/optional.carbon:27-45 (placeholder class, `HasValue`/`Get`); no `Try` impl; `ControlFlow(T, ())` rejected per specific — toolchain/check/type.cpp:313-320 `IsInSliceChoicePayloadType` admits only int/float/bool/pointer (through adapters), pinned by fail_question_preflight.carbon:107-126 (`fail_unit_break_type`, W-070) |
| 12 | Entry point `Run() -> Core.Result((), E)` / `Result(i32, E)` (F-006j/D10) | MISSING | toolchain/check/handle_function.cpp:373-393 `IsValidEntryPointReturnType` admits `()`/none/i32 only; :417-420 diagnostic text names two shapes; lower/type.cpp:335-341 + handle.cpp:267-275 special-case only the no-return-type entry point |
| 13 | Catching thunks: `Result(S, Cpp.Exception)` imports (B3) | MISSING | thunk.cpp has one thunk shape per callee (`BuildCppThunk` :749, `PerformCppThunkCall` :791); no exception capture anywhere in toolchain/check/cpp/ (`grep -n current_exception\|exception_ptr\|__cxa_` is empty) |
| 14 | `Cpp.Exception` synthesized into the `Cpp` package (F-006g) | MISSING | import.cpp:2453-2500 `LookupBuiltinName` handles `Cpp.long`-style builtins and `Cpp.nullptr` only; no `Exception` case; nothing under core/prelude/types/cpp/ (int, nullptr, void) |
| 15 | `Carbon::expected<T, E>` export + support header (F-006h/D8) | MISSING | type_mapping.cpp:145-250 `TryMapClassType` maps Char/CppCompat/Optional-pointer/Str only; export.cpp:993-1039 maps the return type through it (`failed to map Carbon return type to C++ type` TODO :1013); no header under toolchain/install/ |
| 16 | Conformance for the two bullets | PARTIAL | bullet 1: 4 PASS programs, all over a USER `MyResult` (control_flow_constructs, question_propagation_diff, question_generic_diff, question_generic_thread_diff); bullet 2: 4 PASS B0 programs + 1 SKIP (cpp_exception_interop.carbon:10 SKIP, body commented :21-40) — no program names `Core.Result`, `Cpp.Exception`, `Carbon::expected`, or a `Result`-returning `Run` |
| 17 | Design docs | DONE (text) | docs/design/error_handling.md (950 lines, normative, staging table :800-812); docs/design/README.md:3885-3918 already replaces the placeholder section; docs/design/expressions/README.md:358, :382-385 carry `?`. The sentence "Carbon does not have language features dedicated to error handling" survives ONLY in fork/gap-analysis.md:59 (quoting a README line that no longer exists) |

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
6.  **fork/gap-analysis.md:59-60** are both still MISSING with 2026-07-19
    evidence text ("No try/throw tokens or parser states", "clang_invocation
    .cpp contains no exception-handling configuration") that is false since
    B0/B1a; the header counts (:15-17, 24/18/13/1) have never been
    recomputed. The scoreboard's `gap_status` column mirrors that table.
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
    plan lands is the sketch's signature verbatim, so nothing user-visible
    changes.
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
    in the TU. Both recorded as new work items (§8.5). Break condition:
    SF-6 widening past scalars (W-010 residue) reopens (i) as a real
    `Destroy` impl calling `__cxa_decrement_exception_refcount`.
-   **D-EH-4 — the catching-import SELECTION surface delivered in 0.1 is
    the `?`-directly-on-the-call form** (error_handling.md:674-678 names
    it as one of the contexts). The other context — a binding or argument
    whose EXPECTED type is `Core.Result(S, Cpp.Exception)` — needs an
    expected-type channel the checker does not have (conversions run after
    the call is emitted; convert.h:14-60 has no "context type" input), so
    it is recorded as a residue item with the one-line workaround
    `fn Wrap() -> Core.Result(S, Cpp.Exception) { return .Ok(Cpp.f(x)?); }`.
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
    try.carbon:9-10 needs for a choice's discriminant) plus `"prelude/try"`
    for the impl. Cycle check: try.carbon's closure is as/uint → copy,
    default, destroy, operators, char_literal, float_literal, int,
    int_literal (verified by the import lines of each); none imports
    types/result or types/optional. Rejected: putting `Result` in
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
    .ElementType = T`). optional.carbon gains `import library
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
    first argument is `()` or `i32`-like (through `IsI32`, :297, which
    already admits adapters), for any `E`; the diagnostic text at :417-419
    grows to name the four D10 shapes (churn: check/testdata/main_run/
    fail_mismatch_return.carbon's one CHECK line, autoupdated). Lowering
    (§2.A.5) keeps the mangled name `main` (mangler.cpp:194-196 unchanged)
    and gives a `Result`-returning `Run` the C ABI `i32 main()` — no sret
    parameter — by allocating the return slot locally and emitting the D10
    epilogue at `ReturnExpr`: disc==0 → return the `Ok` payload (or 0 for
    `()`), disc==1 → `write(2, msg)` naming `E` (`SemIR::StringifyConstantInst`
    on `E`'s type inst, the file_context.cpp:576-577 precedent) and return
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
    parent is the `?` (parse golden operators/question.carbon:73-81). The
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
    `FunctionDecl` with `AsmLabelAttr("__cxa_current_primary_exception")`
    (mangling bypass, the thunk's own asm-label precedent thunk.cpp:555-
    559; `GeneratePlacementNewFunctionDecl` :31-59 is the synthesized-decl
    precedent), cached on `CppContext` beside `placement_new_decl_`
    (cpp/context.h:47-52). The return value ALWAYS goes through the
    out-pointer (uniform shape; the existing `has_simple_return_type`
    split :640-745 is not reused for the catching variant) — for a `void`
    callee `ret` is omitted. The discriminant is `int` (simple ABI). ABI
    reference: libcxxabi/include/cxxabi.h:170-172,
    libcxxabi/src/cxa_exception.cpp:713-729 (returns the thrown object with
    an incremented refcount; NULL for foreign exceptions).
3.  **Carbon side of a catching call (`PerformCppCatchingThunkCall`, new in
    thunk.cpp) builds the `Result` with existing insts only:**
    `TemporaryStorage ret: S` (skipped for `S == ()`), `TemporaryStorage
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
    alongside the built-in file-less entities" (:683-712). Reserved-name
    rule (:701-706): the builtin case runs BEFORE Clang lookup in
    `ImportNameFromCpp`, so a header-declared global `Exception` is
    unreachable as `Cpp.Exception` — exactly the doc's rule; pinned (§4).
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
    namespace is reopened, not clobbered, by the header: `BuildCarbonNamespace`
    (generate_ast.cpp:298-331) reuses an existing `NamespaceDecl` and the
    external source only answers names ordinary lookup does not find.
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
    `Exception::ptr()` = `try { __cxa_rethrow_primary_exception(primary_); }
    catch (...) { return std::current_exception(); }` (cxa_exception.cpp:
    756-770 increments the refcount, so the stored pointer stays valid —
    lossless, D7). Deviation recorded (V-3a register): the doc says
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
    nullptr, false) })})` (Sema.h:11349-11354, :8595). The write call is
    `__carbon_boundary_write(2, "<msg>", len)` — a synthesized C-linkage
    decl with `AsmLabelAttr("write")` (identifier differs from any
    user-visible `write`, so no redeclaration conflict; POSIX on both V-1
    platforms), cached on `CppContext`; `<msg>` is a `clang::StringLiteral`
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
        `return SetEntryPointReturnInt32(func_ctx)` (:142-149); the return
        parameter is then routed through `IgnoreParam` into
        `unused_param_indices_` (:205-208) as it is for by-copy returns,
        so the LLVM function is `i32 main()`.
        `FunctionTypeInfo` (type.h:27-46) gains
        `SemIR::TypeId entry_point_result_type_id = None`.
    -   lower/file_context.cpp:659-666 (`BuildFunctionBody`, after the
        unused-parameter poison loop): if `entry_point_result_type_id`
        has a value, `CreateAlloca(GetType(result type))` in the entry
        block and `SetLocal(return_param_id, alloca)` — overriding the
        poison so `ReturnSlot` (handle.cpp:260-263) and the in-place
        initializer target real storage.
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
    `Core.CppCompat.Exception` type inst.
3.  **thunk.h/.cpp:**
    -   `auto BuildCppCatchingThunk(Context&, const SemIR::Function&
        callee) -> clang::FunctionDecl*` — `CreateThunkFunctionDecl` shape
        with a `is_catching` flag threaded into `GenerateThunkMangledName`
        (suffix `.carbon_thunk_catch`, :76-118) and the parameter list of
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
        top; when it fires, delegate to `PerformCppCatchingThunkCall`
        (§1.B.3) and record the result inst in
        `context.cpp_catching_call_results()` (a `Set<InstId>` on
        `Context`) so §2.B.6 can annotate.
    -   `BuildThunkBody` (:646-747): the fence wrapper (§1.B.8), gated on
        `IsCppThunkFenceRequired(context, callee_info.decl)`; helper
        `GetOrCreateBoundaryWriteDecl(CppContext&, Sema&)` and
        `GetOrCreateCxaCurrentPrimaryExceptionDecl(...)` beside
        `GeneratePlacementNewFunctionDecl` (:31).
4.  **check/cpp/context.h:** two cached `clang::FunctionDecl*` members
    with accessors (the :47-52 pattern).
5.  **type_mapping.cpp:** `LookupCppClassTemplate` (static, beside
    `LookupCppType` :102-131); `case Result:` and `case CppException:` in
    `TryMapClassType` (§1.B.5). **export.cpp:1007-1015:** before the
    generic "failed to map Carbon return type" TODO, if the return type is
    a `Result` specific and `LookupCppClassTemplate` finds nothing, emit
    `CppExportResultNeedsExpectedHeader` (Error) and return nullptr.
    **diagnostics/kind.def:** `CppExportResultNeedsExpectedHeader` (after
    :246's CppInterop block) and `QuestionCppCatchingImportNote` (Context;
    after :580 `QuestionReturnTypeNotTry`).
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
    in `runtimes/libcxxabi/include`, clang_invocation.cpp:174-181).

## §3 Commit structure

**EH-A (PR "EH-A: Core.Result, Optional as Try, Result entry points"),
four commits:**

1.  prelude + `()` admission + `RecognizedTypeInfo::Result` + entry-point
    check widening (compiles standalone; goldens stale).
2.  lowering: entry-point `Result` epilogue.
3.  §4.A goldens (AUTOUPDATE, empty CHECK lines, R15/R19) + the W-070 pin
    move + §5.A conformance programs + gap-analysis row 59 + ledger.
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
    row 60 + ledger + decision-log + docs.

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
    the widened `InvalidMainRunReturnType` text), `fail_non_result_class`.
    **main_run/fail_mismatch_return.carbon:13** CHECK text moves (autoupdate).
-   **lower/testdata/operators/question_result.carbon** (the lower
    question.carbon shape over the prelude type: the Branch call, the
    discriminant `icmp`, the early `ret`), **lower/testdata/choice/
    unit_payload.carbon** (pins the zero-sized store shape and the
    `<{ <{ i1, [3 x i8] }>, [4 x i8] }>` layout for `ControlFlow(i32,
    ())`), **lower/testdata/main_run/return_result.carbon** (`define i32
    @main()`, the alloca'd return slot, the `load i8` discriminant, the
    `write` declaration and both `ret`s).
-   Hand-traced predictions the reviewers check against the autoupdate:
    `main` has no `sret` parameter; the `err` block's `write` callee is
    `declare i64 @write(i32, ptr, i64)`; `unit_payload`'s `Break(())` store
    is a zero-length `store {} ...` or absent (either is accepted; a
    CARBON_FATAL/crash is the R-3 falsifier).

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
    fenced, another `Cpp.f()?` catching — the per-call-site rule :657-661),
    `reserved_name` (inline C++ declares `struct Exception {}`; `Cpp.Exception`
    still names the Carbon class — :701-706).
-   **check/testdata/interop/cpp/exceptions/fail_catching.carbon:**
    `fail_noexcept_callee` (`Cpp.cannot_throw()?` → `QuestionOperandNotTry`),
    `fail_none_mode` (`EXTRA-ARGS: --cpp-exceptions=none`, same diagnostic),
    `fail_break_type_mismatch` (`Cpp.may_throw_int()?` in a `Result(i32,
    i32)` function → `ConversionFailure` + the new context note),
    `fail_not_direct` (`let x: i32 = Cpp.may_throw_int(); ... x?` → the
    plain `QuestionOperandNotTry` — pins D-EH-4's boundary honestly).
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
    EXPECT-STDOUT is exactly `1`, `10`, `0`, `0`. A fourth probe applies `?`
    to `Core.Optional(i32*)` (the pointer niche) and prints the pointee.
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
-   Source files touched: 9 (result.carbon new; types.carbon; optional
    .carbon; check/type.cpp; check/handle_function.cpp; sem_ir/type_info.h;
    sem_ir/type_info.cpp; check/cpp/type_mapping.cpp (one `break`);
    lower/type.{h,cpp}; lower/file_context.cpp; lower/handle.cpp).

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
-   **Catching/export commits: only new goldens** (§4.B) plus the four
    new diagnostic/identifier registrations.
-   Source files touched: 14 (exception.carbon new; types.carbon;
    core_identifier.def; sem_ir/type_info.{h,cpp}; check/cpp/{import,
    thunk,thunk.h,context.h,type_mapping,export}.cpp; check/handle_question
    .cpp; check/context.h (two containers); diagnostics/kind.def;
    base/install_paths.{h,cpp}; base/clang_invocation.cpp; install/BUILD;
    install/include/carbon/expected.h new).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — `Result` recognized by name collides with a user `Core`
    extension.** Only package `Core`'s root can declare `Result`
    (`IsInCorePackageRoot`); user packages cannot. Falsifier: a user file
    `package Core;` is rejected by the toolchain already.
-   **R-2 — prelude `final impl` over `Result` conflicts with user `impl
    MyResult as Try`.** Different `Self` types; impl lookup is per type.
    Falsifier: control_flow_constructs.carbon keeps PASSing unchanged.
-   **R-3 — zero-sized payload lowering.** `Break(())` stores a `((),)`
    tuple into a zero-byte region field. LLVM accepts zero-size aggregates
    and stores; the check-side `TupleInit` of an empty element is the
    `tuple/one_entry` shape. Falsifier: lower/choice/unit_payload.carbon's
    autoupdate crashes or produces a non-zero-size region. Contingency: the
    D-EH-2 break condition (scalar carrier for `Optional`, `Result((), E)`
    unaffected).
-   **R-4 — entry-point epilogue versus the `ReturnSlot` inst.** `ReturnSlot`
    reads the return param's local (handle.cpp:260-263); the plan binds
    that local to an alloca AFTER the poison loop, so ordering is correct
    by construction. Falsifier: `main_run/return_result.carbon` IR shows a
    `poison` operand.
-   **R-5 — `write` on non-POSIX.** V-1 scopes 0.1 to Linux/macOS; W10
    (Windows) already budgets the boundary thunks' MSVC variant
    (error_handling.md:835-837) — add "the entry-point `write(2)` and the
    fence diagnostic" to that item's notes (§8.5).
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
    104; recorded as W-081, §8.5), and C++ cannot return a Carbon choice
    otherwise. The selection is bounded from the other side instead:
    `fail_not_direct` and `same_callee_both_ways` (§4.B) pin exactly when
    the catching thunk is chosen. The pre-check code path stays in place
    so the residue's landing needs no selection change.
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
3.  **Conformance:** mode `conformance`; EH-A **105/0/28 over 133**, EH-B
    **109/0/27 over 136** (both +1/+1 after W-077 merges); `runner.py
    --self-test` and `--update-readme-table` clean. Any other movement is
    a §5/§6 miss — stop and reconcile.
4.  **Reconciliation greps at discharge:** `grep -rn 'fail_unit_break_type'
    toolchain` is empty; `grep -rn 'does not have language features
    dedicated to error handling' docs fork` hits only history in this plan
    and the decision log; the `Unsupported: fenced thunk` string survives
    at import.cpp:2103-2105 and gains a sibling `Unsupported: catching
    thunk` at the new site; `grep -rn '__cxa_' toolchain/check/cpp` hits
    exactly the two synthesized decls.
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
        fence diagnostic (or its R-9 drop record).
    -   W-016 → title retext ("noexcept-spec fenced thunks"), notes gain
        the SF-1 discharge (or drop) line (§0.2 item 4).
    -   W-070 → DISCHARGED at EH-A by option (a); blocked_by cleared
        (§0.2 item 5).
    -   W-007 → notes: "EH-B landed additively (§1.B.9); the refactor-first
        precondition was not met and no refactor was needed; re-evaluate
        when a second contender starts".
    -   W-058 → notes: "`Optional` gained a `Try` impl over the placeholder
        API at EH-A (D-EH-1); the approved-design work must keep the impl
        signature `final impl forall [T: OptionalStorage] Optional(T) as Try
        where .ContinueType = T and .BreakType = ()`".
    -   NEW W-079: `Cpp.Exception` accessors `TypeName()`/`Message()` +
        release-on-destroy (D-EH-3 bounds; mechanism R-8; blocked_by: the
        SF-6/destroy-synthesis residue of W-010 for the release half).
    -   NEW W-080: catching-import selection in binding/argument contexts
        (D-EH-4 residue; workaround recorded; blocked_by: none — needs an
        expected-type channel).
    -   NEW W-081: import direction `Carbon::expected<T,E>` → `Core.Result`
        (error_handling.md:668-673; a custom_type_mapping.cpp matcher, the
        std::string_view precedent; W-011 family).
    -   W-059 (W10 Windows) notes gain the POSIX `write(2)` dependency
        of the entry-point epilogue and the fence diagnostic (R-5).
    -   The file header's "Updated ... by" trail gains one sentence per PR.
6.  **Docs:** docs/design/error_handling.md — dated amendments (history
    unrewritten, the fourth-round precedent): the staging table :800-812
    gains a "landed at EH-A/EH-B" column note and the W5-S3p row records
    D-EH-1; :397-416's `Optional` sketch gets the "signature normative,
    body over the placeholder API until W-058" note; :526-529 the
    `Cpp.Exception`-message clause is marked deferred (W-079); :674-678
    the selection rule marks the binding-context arm deferred (W-080);
    :734 the release clause marked deferred (W-079); :765-767 the
    `std::exception_ptr` mapping sentence amended to `Carbon::Exception`
    with `.ptr()`. docs/design/README.md:3885-3918 needs no change (it
    already points at the doc). fork/gap-analysis.md: row 59 → **DONE**
    ("`?` over `Core.Try` with prelude `Core.Result`/`Optional` impls and
    `Result` entry points; the scalar-payload bound is the Sum types
    bullet's SF-6 residue"), row 60 → **PARTIAL** ("B0 boundary contract +
    catching by `?` + `Carbon::expected` export; residue W-079/W-080/
    W-081"), header counts → 25 DONE / 18 PARTIAL / 12 MISSING / 1
    DESIGN-ONLY after EH-A and 25 / 19 / 11 / 1 after EH-B (R7: bullet
    TEXT untouched).
7.  **Decision log:** entries "EH-A: Core.Result, Optional as Try, Result
    entry points (date)" and "EH-B: catching imports, Cpp.Exception,
    Carbon::expected (date)" carrying D-EH-1..6 with break conditions,
    the §0.2 ledger corrections verbatim, the V-3a divergence-register
    additions (`Carbon::Exception` wrapper naming; the `()` payload
    admission; `Core.Result` as an independent choice), and the OPEN-forks
    section's SF-9 entry moved under Decided with a pointer here.

## Hand-off notes for the implementer

-   R27 first: diff result.carbon's impl and optional.carbon's impl
    SIGNATURE against error_handling.md:383-409 before anything else —
    `final` included.
-   The `()` admission is ONE predicate edit; do not add per-site checks.
-   Entry point: the return parameter must land in `unused_param_indices_`
    (poisoned) and then be OVERRIDDEN with the alloca — if you find the
    param in `lowered_param_indices_` instead, the `main` signature is
    wrong (it grew an `sret`).
-   Catching selection lives in `PerformCppThunkCall`, keyed on the
    `CallExpr` node's successor; guard `node.index + 1 < tree.size()`.
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

Pending two adversarial plan reviews (R29(c)). Amendments will be folded
here with "(amended <date>, review fold: ...)" markers, mirroring
fork/w077/plan.md (branch claude/carbon-fork-0-1-w077).
