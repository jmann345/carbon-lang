<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# F-008 plan: the three threading/atomics interop defect fixes + conformance (W-021/W-022/W-023 discharge; W-020 programs half)

Status: PLAN (process step 6, scaled loop). Baseline: trunk f7b36d4
(error-handling B1 complete across PRs #15/#16; upstream merged through
e7050af, 2026-08-08, by way of e7ed621; conformance floor 83 PASS / 0 FAIL /
30 SKIP over 113 programs, 42/56 bullets green —
fork/conformance/out/scoreboard.json). Design authority: the F-008 decision
(fork/decision-log.md:637-644 — Option B of
fork/design-sprint/threading-atomics.md: memory-model design doc +
conformance programs + upstreamable fixes for the three verified defects)
and the sprint paper's measured defect matrix
(threading-atomics.md:97-109). Precedent format: fork/b1/plan.md (on
trunk); fork/b2/plan.md, cited in the first draft, is an UNLANDED branch
artifact (it lives on claude/carbon-fork-0-1-b2, not on trunk f7b36d4) and
is cited below only where b1 has no equivalent, always with that caveat.
NO implementation in this document — planning only.

**The design-doc deliverable of F-008 (threads_and_atomics.md, the W-020
doc half) is NOT in this plan's scope**: it rides the design-docs
reconstruction, gated on the user's unanswered veto digest
(fork/ORCHESTRATION.md next-action 1, presented 2026-07-20). This plan
covers the DEFECT FIXES + CONFORMANCE PROGRAMS only, per the tasking that
created it.

## Amendments (2026-08-09, post-review fix round)

Both adversarial plan reviews returned APPROVE-WITH-AMENDMENTS (strictness
review F-1..F-8; correctness review MAJOR-1/2, MINOR-1..4, NOTE-1..4).
Coordinator adjudications A-D applied as written; every amendment below is
integrated into the sections it names (b1 dated-amendment pattern —
"revised after plan review, 2026-08-09" at each touched site).

-   **A — strictness F-1 (MAJOR) vs correctness NOTE-4, adjudicated
    re-sequence.** The finding: F8a's un-SKIP of cpp_threading_atomics
    rewrote the SKIP's own stated un-SKIP condition ("design lands AND
    Cpp.std.thread/Cpp.std.atomic usable") while the design doc is gated
    on the user's unanswered 2026-07-20 veto digest — the flip was
    entangled with a pending user decision. Amendment: the SKIP→PASS flip
    moves OUT of F8a into F8b (the first defect-fix slice), so the harness
    slice flips no bullet and the flip rides real defect work; no
    synchronous user ask. Touched: §0.2(a)/(b), §0.3, §3 F8a/F8b, §6, §7,
    §11 digest item 1.
-   **B — strictness F-3 (MAJOR), applied.** The finding: the three
    defect-fix arbiters must be scoreboard-visible from F8a. Amendment:
    the F8b/F8c/F8d conformance pairs land AT F8A as SKIP-with-R10-
    evidence (each SKIP text quotes the exact measured diagnostic and
    names its fix slice as the un-SKIP condition), so every fix slice is a
    genuine SKIP→PASS flip. Floors recomputed against runner.py's ACTUAL
    rollup code (runner.py:500-528: any failing program → bullet FAIL; ALL
    programs SKIP → bullet SKIP; otherwise → bullet PASS — so ANY passing
    program under the threading bullet would flip it at F8a). Consequence,
    worked out honestly: F8a's two green harness programs attach to the
    already-PASS bullets they also genuinely arbitrate (§2.5) and re-home
    to the threading bullet at F8b together with the flip. Touched: §2.5,
    §3, §6, §7.
-   **C — strictness F-2 = correctness MAJOR-1 (shared MAJOR),
    adjudicated to one story.** The finding: the F8d degrade-path floor
    was told three contradictory ways (§2.4 "pair rewritten to a bridge",
    §2.5 "pair not added", §7 "no SKIP stub"). Amendment: the §2.5-family
    telling is THE story — under degrade the cpp_thread_carbon_fn_diff
    pair is NOT rewritten to a bridge (a bridge-spawn oracle would pass
    with no Carbon-fn-callable support at all: the trivially-satisfiable-
    probe pattern); since (per B) the pair already exists as a SKIP from
    F8a, the degrade landing state is that the pair STAYS SKIP with its
    text updated to record the documented-limitation decision and W-023's
    upstream-watch (p003848 lambdas) as the un-SKIP condition. §2.4, §2.5,
    §3 F8d, §6, §7 now agree; degrade floor recomputed.
-   **D — correctness MAJOR-2, adjudicated.** The finding: D3's H0
    ("fixed upstream") adjudicator cannot be the mock-header lower golden
    — it is dump-only and never links, while the real defect was measured
    with real libc++ `std::atomic`. Amendment: the F8a-landed SKIP pair
    for D3 (real-header `var total: Cpp.std.atomic(i64);`) is the H0
    arbiter, exercised by a one-off runner adjudication run as F8c's FIRST
    step (compile+link the real program on the runner BEFORE choosing a
    fix site); the mock lower golden stays as the H1/H2/H3 MECHANISM
    probe. A pre-declared path covers "H0 confirmed by mock then falsified
    by real header". Touched: §2.1, §2.3, §3 F8c.
-   **1 — strictness F-4 / correctness MINOR-3.** The Carbon-side
    pthread-linkage claim ("carbon link handles pthread, verified by
    execution 2026-07-19") is restated as HYPOTHESIS H-P: the 2026-07-19
    verification predates the runner migration / glibc divergence
    (ORCHESTRATION.md:45-52); F8a's first runner CI run is its test.
    Link/run-fail of the threaded programs is now a named F8a risk with a
    stop-and-diagnose response. Touched: §2.5, §5 (new R-9), §3 F8a.
-   **2 — strictness F-5 / correctness NOTE-2.** fork/b2/plan.md is an
    unlanded branch artifact (claude/carbon-fork-0-1-b2, not trunk
    f7b36d4) — now said explicitly wherever cited; structural precedents
    re-cited to fork/b1/plan.md (on trunk) where an equivalent exists.
    Touched: header, §3 intro, §4, §5.
-   **3 — correctness MINOR-1.** F-008 decision citation corrected from
    fork/decision-log.md:732-739 to :637-644 (both occurrences: header,
    §0.4).
-   **4 — correctness MINOR-2.** D3 novelty claim reworded to "no
    LOWER/link-level testdata covers a specialization-typed Carbon
    file-scope global", citing
    check/testdata/interop/cpp/template/type_param.carbon:27 (valid.carbon
    split) as the existing CHECK-stage precedent that strengthens the
    compiles-but-doesn't-link localization. Touched: §0.1, §1.
-   **5 — correctness MINOR-4.** integration_tests/make_unique_test.carbon
    (class C, single i32 field, no user Destroy) added to F8b's §4
    movement enumeration — its `unique_ptr<C>` destruction changes
    thunk→trivial; the landing note must re-derive its export path; exit
    criterion: that test stays green. Touched: §3 F8b, §4.
-   **6 — correctness NOTE-1.** `PerformCallToCppFunction` is
    check/cpp/call.cpp:54, not :55. Touched: §0.1.
-   **7 — correctness NOTE-3.** The F8a bridge-spawn program is described
    as "the `.join()` determinism variant of matrix row 9" — the measured
    shape used `.detach()`. Re-verified on the tree: row 9 sits at
    threading-atomics.md:90 (the review's :92 cite corrected on re-check).
    Touched: §2.5.
-   **8 — strictness F-8's disclosed weak spot.** R-1 now states that the
    printed `8` cannot distinguish two threads from one; the condvar
    handoff pair is the concurrency arbiter (single-threaded execution
    deadlock-timeouts it). Touched: §5 R-1.

---

## 0. Scope classification

### 0.1 The three defects, classified against the tree at f7b36d4

Sprint-paper numbering (threading-atomics.md:99-103) kept; work-item IDs
from fork/inventory/work-items.json. Every code-path claim below was
re-traced on THIS tree (post-e7050af), not inherited from the paper —
column 4 says which claims are re-verified statically and which still rest
on the 2026-07-19 empirical run against the nightly toolchain.

| # | Defect | Code path (this tree) | Present at f7b36d4? | Tractability | Evidence that would change the estimate |
| --- | --- | --- | --- | --- | --- |
| D1 (W-023) | `Cpp.std.thread.thread(CarbonFn)` check error: `call argument of type {0} is not supported` | Carbon→C++ call: check/cpp/call.cpp:54 `PerformCallToCppFunction` → overload_resolution.cpp:284 `InventClangArgs` → type_mapping.cpp:534 `InventPrimitiveClangArg` → :415 `MapToCppType` → `TryMapType` has NO `SemIR::FunctionType` case, falls to `default:` (type_mapping.cpp:321-323) → null → `CppCallArgTypeNotSupported` (type_mapping.cpp:419-424) | **YES, re-verified statically**: no function-type mapping exists anywhere in check/cpp/type_mapping.cpp; upstream lambda work (p003848) has NOT landed a callable mapping (no matching commits through e7050af) | M (multi-file: type mapping + arg invention + thunk arg passing + exported-symbol guarantee; ABI must be checked, not assumed — W-023 notes) | If Sema rejects a `DeclRefExpr`-to-exported-decl argument shape, or the thunk cannot drop an AST-embedded arg cleanly, M→L and the pre-declared degrade path (§2.4) fires. If upstream lands p003848 lambdas first, re-plan on top (upstream-watch in W-023.blocked_by). |
| D2 (W-021) | `Cpp.std.atomic(CarbonClass)` instantiates but libc++'s `static_assert(is_trivially_copyable<T>)` fires | Carbon-type-into-Clang export: type_mapping.cpp:232 `ExportClassToCpp` (export.cpp:170-205) creates the `CXXRecordDecl`; lazy completion `CarbonExternalASTSource::CompleteType` (check/cpp/generate_ast.cpp:415-539) `startDefinition` :437, fields :471, then **unconditionally adds a destructor with a thunk-calling body** :473 → `ExportDestructorToCpp` (export.cpp:1327-1401, body built :1385-1398); the explicit TODO "Import any special member functions that affect class properties" sits at generate_ast.cpp:475 | **Mechanism still present, re-verified statically**: the destructor is added for every exported class with no triviality predicate; upstream's recent export work (ctor export 3cb143e, pure-virtual 8f22422, `std::make_unique` on a Carbon type 2ac425e + integration_tests/make_unique_test.carbon) exercises NON-trivial usage only — no triviality marking landed | S (single predicate + conditional trivial destructor in export; one file pair + goldens) | If a defaulted-trivial destructor still leaves `is_trivially_copyable` false (that is another special-member bit is non-trivial on external-source records — F8b's probe golden decides), S→M: the fix must also drive implicit copy/move member declaration through Sema. |
| D3 (W-022) | File-scope `var g: Cpp.std.atomic(i32);` compiles but links with `undefined symbol: _Cgcount.Main.1` (plain imported-class globals like `std::mutex` link fine) | Global definition emission: lower/file_context.cpp:285-310 `LowerGlobalVariables` (called from `LowerDefinitions` :114) sets the initializer on the `llvm::GlobalVariable` created by the constant path — lower/constant.cpp:356-364 `EmitAsConstant(VarStorage)` → file_context.cpp:719-740 `BuildGlobalVariableDecl` → :742-765 `BuildNonCppGlobalVariableDecl` (mangled name from sem_ir/mangler.cpp:299-324) | **UNKNOWN on this tree** — the symptom is from the 2026-07-19 empirical run on the nightly toolchain; the lowering path has since churned upstream (dea290d "Only lower files we are going to emit" #7611, 46b5482 clang-module-per-Carbon-file, a1e8437 header-import modules). No commit names this bug; no LOWER/link-level testdata covers a specialization-typed Carbon file-scope global (verified: lower/testdata/interop/cpp/globals.carbon covers only the C++→Carbon direction; check/testdata/interop/cpp/var/export/var.carbon covers only `i32`) — while the CHECK stage already passes the shape: check/testdata/interop/cpp/template/type_param.carbon:27 (valid.carbon split) declares `var x: Cpp.TwoTypes(Cpp.A, Cpp.B);` green, which strengthens the compiles-but-doesn't-link localization (reworded after plan review, 2026-08-09) | S-M, **diagnose-first** (root cause NOT pinned statically; three live hypotheses, §2.3) | Two-part adjudication (revised after plan review, 2026-08-09, adjudication D): H0 = already fixed upstream is settled by F8c's first-step one-off runner run of the real-header D3 pair (compile+link, §2.3) → F8c collapses to regression-test-only; the F8a probe golden (lower dump, never links) distinguishes H1/H2/H3 (§2.3), each naming a different fix site. |

Loud statement per the tasking: **no evidence was found that any of the
three defects has been fixed upstream** — D1 and D2's mechanisms are
re-confirmed in today's code; D3 cannot be confirmed or refuted statically
and is staged diagnose-first rather than promised. Conversely, upstream's
own `integration_tests/make_unique_test.carbon` (2ac425e) proves the
Carbon-type-into-Clang direction is active upstream territory: D2 is
convergent with upstream intent (the generate_ast.cpp:475 TODO is
upstream's own marker), which is exactly the F-008 decision's premise.

### 0.2 In scope

-   **(a) F8a — conformance + red-baseline slice** (revised after plan
    review, 2026-08-09 — adjudications A/B): rewrite the SKIP stub
    interop/cpp_threading_atomics.carbon's BODY into the executable
    program its own header sketches
    (fork/conformance/programs/interop/cpp_threading_atomics.carbon:11-31)
    while KEEPING it SKIP — the SKIP text refreshed to name F8b as its
    un-SKIP condition (§3); add working-surface programs (threaded
    differential pair + mutex/RAII, attached per §2.5's bullet-honesty
    note); land the F8b/F8c/F8d conformance pairs as SKIP-with-R10-
    evidence stubs (each quoting its measured diagnostic, un-SKIP = its
    fix slice); one-line runner change (`-pthread` on the diff-cpp
    compile, §2.5); and the three defect-characterization goldens (fail_
    probes for D1/D2, the D3 lower-dump probe) that give F8b-d their red
    baselines. No bullet flips at F8a.
-   **(b) F8b — the D2 fix** (W-021): triviality predicate + conditional
    trivial destructor export, plus check goldens; un-SKIPs its
    conformance pair AND cpp_threading_atomics (the threading bullet's
    SKIP→PASS flip rides this first fix slice, not the harness slice —
    adjudication A).
-   **(c) F8c — the D3 fix** (W-022): H0 adjudicated first by a one-off
    runner run of the real-header pair (adjudication D, §2.3), then
    root-cause off the combined probe evidence, fix global-definition
    emission for specialization-typed Carbon globals, lower golden flip +
    un-SKIP of its conformance pair.
-   **(d) F8d — the D1 fix** (W-023): concrete non-generic Carbon function
    values usable as C++ callable arguments, un-SKIPping its conformance
    pair — or, under the F-008-sanctioned degrade path if it proves deeper
    than M, the pair STAYS SKIP with updated evidence (§2.4).

### 0.3 The design-doc gate (restated, not re-litigated)

W-020's doc half (docs/design/interoperability/threads_and_atomics.md and
its 7-point contract, threading-atomics.md:184-224) stays gated on the
design-docs veto digest (ORCHESTRATION next-action 1). This plan's
conformance programs arbitrate BEHAVIOR only and cite the F-008 decision,
not the unwritten doc. The cpp_threading_atomics SKIP text names both the
missing doc and unusable `Cpp.std.thread`/`Cpp.std.atomic` as its evidence
(program line 9); §3 F8a refreshes that stale evidence honestly — the
sprint's executed matrix (threading-atomics.md:78-96) shows the interop
surface works — but (revised after plan review, 2026-08-09, adjudication
A) the un-SKIP itself is re-sequenced to F8b: F8a only rewrites the SKIP
text (quoting the current defect evidence per R10, un-SKIP condition =
F8b), so the flip rides real defect work rather than a harness slice
rewriting the SKIP's own "design lands" clause while that clause's doc is
gated on a pending user decision. The "design lands" clause is superseded
by the F-008 decision itself (which sanctions the fixes without the doc);
that supersession is disclosed for veto as §11 digest item 1.

### 0.4 Out of scope (with rationale)

-   **threads_and_atomics.md authoring** — §0.3; gated user deliverable.
-   **`Core.Sync` veneer and Carbon-native atomics** — rejected Options
    C/D of the ratified F-008 decision (decision-log.md:637-644).
-   **Anything SF-9/S3p/B3-gated** (prelude `Core.Result`/`Core.Optional`,
    catching thunks) — sibling error-handling scope, untouched here; F8
    conformance programs avoid throwing paths' RESULTS but rely on B0's
    landed fence semantics (W-016, `--cpp-exceptions=auto` default) for
    definedness, per the sprint's dependency note
    (threading-atomics.md:468-475).
-   **Exporting Carbon GENERIC class specifics to C++** — the
    `interop with specific class` TODO (export.cpp:67, :176) is W8/F-010
    territory; D2's payload classes are non-generic by design.
-   **C++20-only surface** (`jthread`, `atomic::wait/notify`,
    `atomic_ref`) — the runner pins the diff side to `-std=c++17`
    (runner.py:439) and the Carbon side to Clang's default mode; sprint
    open question 1 belongs to the gated doc digest (§7 item v).
-   **W5-S4 std::variant mapping, W-029 concept export, W-043 templates-on-
    Carbon-generics** — named consumers of D2's shared machinery
    (W-021 notes), not scope.

Scope-disjointness (process.md one-branch-one-scope): the in-flight B2a
branch (claude/carbon-fork-0-1-b2) owns check/handle_question.cpp +
check/custom_witness.cpp + operators testdata + error_handling/
conformance. F8 touches check/cpp/**, lower/**, interop testdata, and
interop/ conformance programs — disjoint. Shared files: runner.py (F8a's
one-line change), README program table, work-items.json, scoreboard —
sequenced at landing, not concurrently edited (R20).

---

## 1. Current state (claims re-derived from the tree at f7b36d4)

-   **The interop surface mostly works.** The sprint's executed matrix
    (threading-atomics.md:78-96, nightly 2026.07.19): atomics with
    orders/CAS/operator sugar, all four mutex types, condvars, RAII guards
    across the boundary, C++ inline globals from Carbon, Carbon functions
    on foreign threads (spawned by way of inline-C++ bridges +
    `Carbon::F` reverse interop), `thread_local`. The three defects are
    the only measured failures, and each has a pure-user-code workaround
    (threading-atomics.md:105-109).
-   **D1 path.** Function-typed call arguments have no Clang mapping:
    type_mapping.cpp:256-327 `TryMapType` enumerates Bool/Char/Class/
    Const/FloatLiteral/Pointer/Array/SymbolicBinding/FacetAccessType and
    nothing else; a Carbon function name's `FunctionType` lands in
    `default:` → null → `CppCallArgTypeNotSupported`
    (type_mapping.cpp:419-424). The machinery a fix composes with exists
    today: `ExportFunctionToCpp` / `ExportNonGenericFunctionToCpp`
    (export.cpp:1278, :1105) synthesize callable `Carbon::F` decls
    (measured working, matrix row 9), and check/cpp/constant.cpp:253-272
    already builds `DeclRefExpr` + `CK_FunctionToPointerDecay` shapes for
    constexpr evaluation — precedent for AST-embedded function
    references.
-   **D2 path.** Every exported Carbon class gets, at lazy completion, an
    explicitly-built destructor whose body calls a Carbon destroy thunk
    (generate_ast.cpp:473, export.cpp:1327-1401), regardless of whether
    the Carbon class is trivially destructible; no code marks any special
    member trivial (the generate_ast.cpp:475 TODO). libc++'s
    `atomic<T>` static_assert on `is_trivially_copyable<T>` therefore
    fires for every Carbon class. The one-predicate requirement is
    already inventoried: W-006 coherence risk 7 ("one trivially-copyable
    predicate over Carbon classes defined once — unions/TA-D2/expected
    export").
-   **D3 path.** Definition emission for Carbon file-scope globals:
    `LowerGlobalVariables` (file_context.cpp:285-310) finds `VarStorage`
    insts in the top inst block and adds a null initializer to the
    declaration created by constant lowering. `BuildNonCppGlobalVariableDecl`
    (:742-765) news a `GlobalVariable` per call with NO caching — LLVM
    silently uniquifies name collisions. `MangleGlobalVariable`
    (mangler.cpp:299-324) appends a fingerprint only for
    private-to-library names (:318-322). No lower/link-level testdata
    exercises a specialization-typed Carbon file-scope global; the check
    stage passes the shape today
    (check/testdata/interop/cpp/template/type_param.carbon:27, valid.carbon
    split — the compiles-but-doesn't-link localization, reworded after
    plan review, 2026-08-09).
-   **Conformance harness facts.** Runner invocation and statuses:
    fork/conformance/README.md:49-143. Differential pairs: C++ oracle
    compiled with the toolchain's own clang++ at
    `<root>/lib/carbon/llvm/bin/clang++` (runner.py:89) with EXACTLY
    `-std=c++17 -o <bin> <file>` (runner.py:439) — **no `-pthread`, and
    no per-program flag mechanism for the C++ side** (COMPILE-ARGS feeds
    only `carbon compile`, README:104-109). Programs run with a 30s
    timeout and exact-stdout matching; multithreaded programs must
    join-before-print (threading-atomics.md:180-182). House conventions:
    differential pairs omit EXPECT-STDOUT (DIFF-1, decision-log.md:476-483);
    runtime-computed inputs per R16d with the `RuntimeSeed(x) = x + 20`
    idiom (types/choice_generic_diff.carbon:64); bullet text must match
    the gap-analysis row character-for-character (R7) — the row is
    `C++ interop: threading, atomics, memory model, synchronization`
    (cpp_threading_atomics.carbon:5). Conformance executes on the
    self-hosted runner by way of the `Fork: conformance suite` workflow
    (fork/conformance-request.txt trigger, scoreboard committed back —
    ORCHESTRATION.md:49-53); the dev container never runs bazel or the
    suite (glibc mismatch, same ops note).
-   **Golden-test facts.** check/lower interop goldens use MOCK headers,
    not real libc++ (`// --- string_view.h` with `inline namespace __1`,
    check/testdata/interop/cpp/stdlib/string_view.carbon:13-38) — the
    F8 probe goldens follow that convention (mock `std::atomic` with
    `static_assert(__is_trivially_copyable(T))`, mock thread-like ctor);
    real `<thread>`/`<atomic>` headers are exercised only by the
    conformance programs on the runner. fail_ subfiles carry hand-written
    CHECK:STDERR pins; positive goldens carry no hand-authored CHECK
    content and ride the runner autoupdate (R15/R16a/R19/R26).

---

## 2. Design (mechanism per defect, pre-declared outcomes)

### 2.1 F8a probes (the red baseline, no compiler changes)

-   **D1 probe** — new check golden
    check/testdata/interop/cpp/function/import/fail_todo_carbon_fn_as_callable.carbon
    (convention: param_unsupported.carbon): mock header with
    `struct thread { template <typename F> thread(F f); void join(); };`
    and a plain `void invoke(void (*f)());`; Carbon passes a Carbon `fn`
    to both; pins the current `CppCallArgTypeNotSupported` text for each.
-   **D2 probe** — new check golden
    check/testdata/interop/cpp/class/export/fail_todo_trivially_copyable.carbon:
    mock `template <typename T> struct atomic {
    static_assert(__is_trivially_copyable(T), "..."); T v; };`
    instantiated on an all-scalar-field Carbon class; pins the
    static_assert diagnostic surfacing through `CppInteropParseError`.
    This golden's post-F8b flip is the D2 discharge test.
-   **D3 probe** — new lower golden
    lower/testdata/interop/cpp/globals_carbon_defined.carbon: Carbon
    file-scope `var g: Cpp.Box(i32);` (mock class template) next to
    `var m: Cpp.Plain;` (mock non-template class), functions reading
    both. Role revised after plan review, 2026-08-09 (adjudication D):
    this golden is the H1/H2/H3 MECHANISM probe — its autoupdated IR dump
    shows, in a reviewed diff, whether `g`'s global stays a bare
    declaration or a duplicate-named pair, distinguishing the §2.3 fix
    sites. It is dump-only and never LINKS, so it CANNOT adjudicate H0
    ("fixed upstream"): the real defect was measured with real libc++
    `std::atomic`, and H0 is settled by the one-off runner adjudication
    run of the real-header D3 pair in F8c's first step (§2.3). This is
    still the diagnose-first evidence R15 can produce without local bazel;
    it is just not the link-level arbiter.

### 2.2 F8b — D2 mechanism

One predicate, one conditional. Predicate `IsTriviallyCopyableForExport`
(new, check/cpp/export.cpp, THE single predicate W-006 risk 7 names):
true iff the class is concrete and non-generic, has no base or vtable
(class_info checks), every field's object repr is itself trivially
copyable under the same predicate (scalars/pointers/nested qualifying
classes), and the class has no user `Core.Destroy` impl (the same lookup
the destroy-thunk machinery consults). When true, `CompleteType` skips
`ExportDestructorToCpp` — no destructor decl is added at all, so Clang's
implicit (trivial) special members stand and `is_trivially_copyable`
holds; when false, today's thunk-destructor path is unchanged.
Pre-declared escalation (from §0.1): if the F8b golden shows the
static_assert STILL firing with no destructor added, the record's other
special-member bits are implicated and the slice re-scopes to M with a
written plan amendment — not an improvised Sema poke.

### 2.3 F8c — D3 mechanism (hypothesis-driven; H0 adjudicated by the real-header pair, H1-H3 by F8a's probe — revised after plan review, 2026-08-09, adjudication D)

**H0 adjudication protocol (F8c's first step, before choosing any fix
site):** a one-off runner adjudication run compiles AND LINKS the
F8a-landed real-header D3 pair (cpp_atomic_global_counter_diff, §2.5 —
`var total: Cpp.std.atomic(i64);` against real `<atomic>`) on the runner,
outside the scoreboard (the pair stays SKIP until F8c lands). Link+run
success = H0; the measured `undefined symbol` = defect live, and the mock
probe's dump picks among H1-H3. The mock lower golden alone cannot settle
H0 — it never links (§2.1).

-   **H0 — fixed upstream** (the lowering rework since 2026-07-19):
    the real-header pair links and runs green in the adjudication run.
    F8c becomes: keep the probe golden as a regression pin + un-SKIP the
    conformance pair; W-022 closes as upstream-fixed, said loudly in the
    ledger.
-   **H0-mock-divergence (pre-declared path)**: the MOCK probe's dump
    shows an initializer (looks fixed) while the REAL-header pair still
    fails to link in the adjudication run.
    _AMENDMENT (2026-08-18, F8c round — this path FIRED)_: the
    F8a-landed mock dump showed one healthy defined global with every
    reference bound to it while run 32079343005 link-failed the
    real-header pair — the mock's field-access shape was falsified as a
    faithful model (it never drove the per-use-cluster re-mint the real
    member-call thunks do). Per this path's own protocol the
    mechanism-probe role moved OFF the F8a dump and onto the
    adjudication run's linker attributions (the `.2`/`.3` per-cluster
    rename suffixes), and the mock was repaired with the member-calls
    split landed alongside the fix; the strictness review caught that
    this amendment had not been filed before the fix commit, and it is
    filed now, before the merge, with the fix's arbiters (the R-4 regen
    pin and the pair's link flip) still pending pre-merge. That falsifies the mock as a
    faithful model of the defect (the specialization shape or import path
    differs), NOT the defect as fixed: F8c halts fix-site selection,
    extends diagnosis on the runner evidence (for example a real-header lower
    dump obtained by way of the adjudication run's artifacts), and files
    a written plan amendment before any fix lands — the same
    stop-and-explain discipline as the all-hypotheses-falsified case
    below.
-   **H1 — double-creation/rename**: `BuildNonCppGlobalVariableDecl` runs
    twice for one var (uncached, :742-765) — for example once from constant
    lowering, once from the non-constant branch at :300 — LLVM renames
    the second to `<name>.1`; uses bind one, the initializer lands on the
    other. Fix: cache by pattern_id (mirror the `global_variables_`
    insert at :305) so declaration and definition are one object.
-   **H2 — specialization-typed VarStorage misses the definition walk**:
    the var's constant is non-concrete (specific-typed), so
    `LowerConstants` skips it (constant.cpp:397-406) while uses go
    through a different path; fix sites at the :295 branch.
-   **H3 — mangled-name divergence** between reference and definition
    (fingerprint arm, mangler.cpp:318-322). Fix: single mangling call
    site, shared.

    The `.1` suffix in the measured symbol `_Cgcount.Main.1` is consistent
    with either H1 (LLVM uniquification) or H3 (fingerprint) — the probe's
    IR dump distinguishes them by inspection. F8c's plan-of-record is
    whichever hypothesis the combined evidence (adjudication run for H0,
    probe dump for H1-H3) confirms; confirming NONE of H0-H3 — or the
    H0-mock-divergence path firing — is a stop-and-explain event (plan
    amendment before any fix lands).

### 2.4 F8d — D1 mechanism and its degrade path

In-scope mapping: a call argument whose type is `SemIR::FunctionType` for
a CONCRETE, non-generic, non-member Carbon function maps to the C++
function-pointer type of its exported decl; the invented Clang arg is a
`DeclRefExpr` to the `ExportNonGenericFunctionToCpp` result (with
`CK_FunctionToPointerDecay`, the constant.cpp:253-272 shape), not an
`OpaqueValueExpr` — the value is AST-embedded, so Sema deduces
`std::thread`'s ctor template on `void(*)()` and the thunk drops the arg
from its runtime parameter list (it is a compile-time constant; thunk
param building at check/cpp/thunk.cpp:353-422 gains a skip). The exported
decl must be guaranteed a definition/symbol in the emitted module
(lower's `HandleReferencedCppFunction` path, file_context.cpp:312-327).
Generic, deduced-parameter, and method values stay diagnosed with today's
`CppCallArgTypeNotSupported` — the F8d negative probe pins that.

**Pre-declared degrade path** (sanctioned by the F-008 decision's own
sequencing note, threading-atomics.md:456-460, and W-023 notes; retold as
ONE story after plan review, 2026-08-09 — adjudication C): if
signature-ABI checking or thunk-arg dropping proves deeper than M, F8d
lands as (i) the negative-probe goldens with today's diagnostic, (ii) the
cpp_thread_carbon_fn_diff pair — already in the tree as a SKIP since F8a
(§2.5) — STAYING SKIP, its text updated to record the
documented-limitation decision and W-023's upstream-watch (p003848
lambdas) as the un-SKIP condition, (iii) W-023 re-staged with the
blocking evidence quoted (R10), and the degrade recorded in the decision
log. The pair is explicitly NOT rewritten to an inline-C++ bridge spawn:
a bridge oracle would pass with zero Carbon-fn-callable support — the
trivially-satisfiable-probe pattern — and would gut the pair as D1's
arbiter. That outcome is a recorded deviation, not a silent ride.

### 2.5 Conformance additions and the runner constraint (revised after plan review, 2026-08-09 — adjudications A/B/C, amendments 1/7)

All three defects admit differential pairs whose C++ side actually
spawns threads / uses `std::atomic`. ALL SIX programs below land at F8a;
what changes per fix slice is SKIP state only (adjudication B):

-   **Green at F8a (2 programs):**
    interop/cpp_thread_condvar_diff.carbon/.diff.cpp — bridge-spawned
    worker: the `.join()` determinism variant of matrix row 9 (the
    measured shape used `.detach()`, threading-atomics.md:90),
    release/acquire handoff through `std::atomic<int>`,
    join-before-print; oracle: plain C++ thread doing the same. And
    interop/cpp_thread_mutex_raii.carbon (lock_guard/unique_lock try_lock
    probes, matrix row 8, prints deterministic `1`/`2`).
    **Bullet attachment (rollup honesty):** runner.py:500-528 makes a
    bullet PASS whenever at least one attached program passes and none
    fail — all-SKIP is the ONLY mix that keeps a bullet SKIP. A green
    program under the threading bullet would therefore flip it at F8a,
    which adjudication A forbids. So at F8a these two attach to the
    already-PASS bullets they also genuinely arbitrate at execution
    level: cpp_thread_condvar_diff under `Functions: C++ interop —
    exporting Carbon functions/methods to C++` (its worker IS an exported
    Carbon function run from C++, on a foreign thread) and
    cpp_thread_mutex_raii under `Type system: C++ interop — synthesizing
    Carbon overloads for imported C++ types` (its RAII release IS the
    synthesized Destroy impl doing observable work). Neither bullet's
    status moves (both are PASS today, scoreboard.json). At F8b both
    programs RE-HOME to the threading bullet together with the flip — the
    header edit is disclosed in the F8b landing note.
-   **SKIP at F8a, flipped at F8b:** the rewritten
    cpp_threading_atomics.carbon (two bridge threads fetch_add a shared
    `std::atomic<int>` 4x each, join, print `8` — its own documented
    intended body; body works today per the matrix, held SKIP per
    adjudication A with un-SKIP = F8b). Plus
    interop/cpp_atomic_carbon_class_diff pair — `std::atomic<Vec2>`
    store/exchange/load of an all-scalar Carbon class, values
    runtime-seeded (`RuntimeSeed(x) = x + 20`); oracle: identical C++
    struct; SKIP text quotes the measured libc++
    `static_assert(is_trivially_copyable<T>)` diagnostic, un-SKIP = F8b.
    Real `<atomic>` on the runner arbitrates what the mock-header golden
    only dump-pins.
-   **SKIP at F8a, flipped at F8c:** interop/cpp_atomic_global_counter_diff
    pair — file-scope `var total: Cpp.std.atomic(i64);` bumped from
    bridge-spawned threads, joined, printed; oracle: C++ global
    `std::atomic<int64_t>`; SKIP text quotes the measured
    `undefined symbol: _Cgcount.Main.1` shape, un-SKIP = F8c. Exit-code
    -   stdout equality is the link-level arbiter D3 needs — and this
        pair's one-off adjudication run is F8c's H0 arbiter (§2.3).
-   **SKIP at F8a, flipped at F8d (or stays SKIP under degrade):**
    interop/cpp_thread_carbon_fn_diff pair — direct
    `Cpp.std.thread.thread(Work)` + `.join()`; oracle:
    `std::thread(work)`; SKIP text quotes the measured
    `call argument of type {0} is not supported` diagnostic
    (`CppCallArgTypeNotSupported`), un-SKIP = F8d. Under the degrade path
    the pair stays SKIP with its text updated per §2.4 — never rewritten
    to a bridge.

**Runner constraint (verified)**: the diff-cpp compile line is fixed at
`-std=c++17` with no thread flags (runner.py:439) and COMPILE-ARGS cannot
reach it. F8a therefore adds `-pthread` to that one command line
unconditionally (harmless for non-threaded oracles, required-or-neutral
for threaded ones depending on the runner host's glibc). **Hypothesis H-P
(restated after plan review, 2026-08-09 — no longer asserted as fact):
the Carbon-side `carbon link` path handles pthread linkage.** The
supporting evidence (threading-atomics.md:175-178) is an execution run
from 2026-07-19, which PREDATES the runner migration and the runner
host's glibc divergence (ORCHESTRATION.md:45-52) — it is therefore a
hypothesis about today's runner, not a verified property, and F8a's FIRST
runner CI run is its test. Link-fail or run-fail of the threaded
programs on the runner is a named F8a risk (§5 R-9) whose response is
stop-and-diagnose, not a workaround commit. One line + README note +
`--self-test` unaffected. Auto-adopt sub-decision, digest item 3. All
threaded programs: join-before-print, deterministic totals only (no
scheduling-dependent output), 30s run timeout respected.

---

## 3. Slices

Each slice is one landable PR off trunk through the full R11 loop
(implementer → 2 adversarial reviewers → fixer), gate = runner-side
autoupdate to R26 fixpoint + `Fork: build toolchain` (prek + clangd-tidy +
`bazel test //toolchain/...`, R21) + `Fork: conformance suite`
non-regression + prek locally before every push (R25). No local bazel —
verification rides testdata goldens + conformance CI exactly as
fork/b1/plan.md §3 stages it (the same staging in fork/b2/plan.md §3 is
an unlanded branch artifact — claude/carbon-fork-0-1-b2, not trunk;
re-cited after plan review, 2026-08-09); one red-first-CI reconciliation
commit per slice is expected (R15/R19).

### F8a — conformance floor + red baseline (S; no compiler changes; revised after plan review, 2026-08-09)

Scope: §2.1 probes; ALL SIX §2.5 programs (2 green under their §2.5
bullet attachments; cpp_threading_atomics body rewritten but KEPT SKIP
with refreshed R10 evidence — stale MISSING claim corrected against the
measured matrix, un-SKIP condition rewritten to "F8b lands the first
defect fix"; the 3 defect pairs as SKIP-with-R10-evidence stubs, each
quoting its measured diagnostic verbatim with un-SKIP = its fix slice);
the runner `-pthread` line; README table regenerated (DIFF-4); work-items
W-020 updated (programs half advanced, doc half gated). NO bullet flips —
the threading bullet's programs are all SKIP at this landing (the only
mix runner.py:500-528 rolls up as bullet-SKIP). Exit criteria:

-   The three probe goldens land autoupdated and green, each pinning the
    CURRENT defect behavior (D1/D2 diagnostics verbatim; D3 IR dump
    answering §2.3's H1-H3 mechanism question — H0 stays open for F8c's
    adjudication run, §2.3).
-   cpp_thread_condvar_diff and cpp_thread_mutex_raii PASS on the runner
    — this run is hypothesis H-P's test (§2.5): link/run-fail here is the
    R-9 stop-and-diagnose event, not a status quo to land. Floor
    86 PASS / 0 FAIL / 33 SKIP over 119 (§6); bullets stay 42/56.
-   The four SKIP programs report SKIP with their new evidence texts;
    the threading bullet stays SKIP.
-   `runner.py --self-test` OK; no existing program's status moves.

### F8b — D2: triviality export + the threading-bullet flip (S; discharges W-021; revised after plan review, 2026-08-09)

Scope: §2.2 predicate + conditional destructor skip; flip the D2 probe
golden positive (the discharge test); extend class/export goldens with a
trivial and a non-trivial (user-Destroy) class side by side; un-SKIP the
F8b conformance pair (SKIP→PASS, a genuine flip off F8a's red baseline);
un-SKIP cpp_threading_atomics (adjudication A: the flip rides this first
fix slice — landing note records that the SKIP's "design lands" clause is
superseded by the F-008 decision, §11 item 1); re-home
cpp_thread_condvar_diff and cpp_thread_mutex_raii to the threading bullet
(§2.5, disclosed header edit); ledger updates. Exit criteria:

-   fail_todo_trivially_copyable flips: mock static_assert instantiation
    succeeds on the qualifying class; the NEGATIVE probe (non-trivial
    class into the same template) still diagnoses the static_assert
    cleanly (R-3).
-   Existing export goldens move ONLY by destructor-decl absence on
    qualifying classes (§4 enumeration, incl.
    integration_tests/make_unique_test.carbon — its export path
    re-derived in the landing note, and the test stays green);
    cpp_type_export_carbon_class and the other 5 existing exporting
    conformance programs stay PASS.
-   cpp_atomic_carbon_class_diff PASSes both sides;
    cpp_threading_atomics PASSes printing `8`; the threading bullet
    flips SKIP→PASS (43/56 — its programs are now 4 PASS + 2 SKIP, which
    runner.py rolls up as PASS); floor 88/0/31 over 119.

### F8c — D3: specialization-typed global emission (S-M; discharges or closes W-022; revised after plan review, 2026-08-09)

Scope: FIRST STEP (before choosing any fix site) — the §2.3 H0
adjudication: a one-off runner run compiling AND linking the F8a-landed
real-header pair cpp_atomic_global_counter_diff (adjudication D); then
the fix per whichever §2.3 hypothesis the combined evidence confirmed
(H0: regression pin only; H0-mock-divergence: stop-and-explain amendment,
no fix); probe golden flips to defined-global IR; un-SKIP the F8c
conformance pair (SKIP→PASS off F8a's red baseline); the D3 NEGATIVE
probe — imported C++ globals (`Cpp.inline_global`, globals.carbon) still
emit NO Carbon-side definition (the :299 invariant, R-5). Exit criteria:

-   The H0 adjudication run's verdict is recorded in the landing note
    (link+run result quoted) BEFORE any fix commit.
-   Probe golden shows `g`'s global with initializer, same symbol name at
    definition and use; no duplicate `.1`-suffixed global anywhere in the
    dump.
-   cpp_atomic_global_counter_diff PASSes (the link-level arbiter);
    floor 89/0/30 over 119; bullets stay 43/56.
-   lower/testdata/interop/cpp/globals.carbon byte-identical (imported
    direction untouched).

### F8d — D1: Carbon fn as C++ callable (M; discharges or re-stages W-023)

Scope: §2.4 mapping + thunk/lowering wiring; D1 probe golden flips for the
concrete case; negative probes (generic fn, method) keep today's
diagnostic; un-SKIP of the F8d conformance pair (or, under the §2.4
degrade, its SKIP text updated in place); upstream re-check for p003848
movement immediately before implementation (standing rule 5; a hit
escalates to the orchestrator). Exit criteria:

-   fail_todo_carbon_fn_as_callable's concrete split flips positive
    (thread ctor template AND plain function-pointer param both resolve);
    generic/method splits still diagnose `CppCallArgTypeNotSupported`.
-   cpp_thread_carbon_fn_diff un-SKIPs and PASSes (SKIP→PASS off F8a's
    red baseline): the C++ side's `std::thread` runs the actual Carbon
    function (R-7's cosmetic-fix falsifier).
-   Floor 90/0/29 over 119 — OR the §2.4 degrade lands with floor
    89/0/30 over 119 (the pair STAYS SKIP with its evidence updated per
    §2.4 — documented limitation + p003848 upstream-watch as the un-SKIP
    condition) and W-023 re-staged with R10 evidence. Bullets 43/56
    either way (the threading bullet already PASSes from F8b; a residual
    SKIP under it does not un-flip it, runner.py:500-528).

Recommended order: **F8a → F8b → F8c → F8d**. F8a first: it is pure
harness/testdata, makes all three defect arbiters scoreboard-visible as
red baselines (SKIP-with-evidence), and tests H-P; it flips no bullet
(revised after plan review, 2026-08-09 — the bullet flip rides F8b). F8b
before F8c/F8d: cheapest fix, it carries the threading-bullet flip, and
it is the first slice of the shared
Carbon-type-into-Clang machinery that F-010/W8 consumers (W-029, W-043)
build on — the F-008 decision's stated reason this defect matters beyond
threading. F8c next (independent subsystem, lower/). F8d last: riskiest,
carries the sanctioned degrade path, and has an upstream-watch dependency.
F8b/F8c are mutually independent and may swap if review capacity favors it.

---

## 4. Byte-equivalence expectations

-   **F8a**: zero toolchain diffs; goldens are additions only; every
    existing golden byte-identical.
-   **F8b**: behavior-widening in one direction — classes that previously
    always got a thunk destructor may now export with none. Expected
    movement, enumerated pre-implementation by grep: goldens dumping
    exported-class ASTs (check/testdata/interop/cpp/class/export/*.carbon,
    lower/testdata/interop/cpp/class/export/class.carbon, thunks goldens
    naming destroy thunks), AND — added after plan review, 2026-08-09 —
    integration_tests/make_unique_test.carbon: its `class C` (single
    `i32` field, no user Destroy) qualifies under the §2.2 predicate, so
    `unique_ptr<C>` destruction changes thunk→trivial; the landing note
    must re-derive that test's export path under the new predicate, and
    the exit criterion is that the test stays green. Non-qualifying
    classes (bases, vtables, user Destroy): zero movement. Any golden
    movement outside the enumerated set is stop-and-explain (b1 §4
    discipline; the same rule in b2 §4 is an unlanded branch artifact).
-   **F8c**: fix is confined to lower global emission; expected movement
    is the new probe golden only. Imported-global goldens
    (globals.carbon) byte-identical (R-5).
-   **F8d**: check-side only for existing goldens (no existing golden
    passes a function to C++ — verified by the D1 probe's novelty); new
    thunk shapes appear only in new goldens. No parse, no prelude, no
    driver changes anywhere in F8; `--cpp-exceptions` machinery untouched.

## 5. Falsification probes (R-1..R-9)

| # | Claim at risk | Probe | FALSIFIER (what proves the fix cosmetic/wrong) |
| --- | --- | --- | --- |
| R-1 | F8a's programs arbitrate real cross-thread behavior, not prints | cpp_threading_atomics: the printed `8` is the joined fetch_add total; condvar pair: the handoff value crosses threads | A program that passes with the thread-spawn bridge deleted (single-threaded shortcut) — reviewer #1 must re-derive why the output REQUIRES the second thread; a Goodharted EXPECT (differential pairs deliberately have none, DIFF-1). **Disclosed weak spot (added after plan review, 2026-08-09):** the printed `8` cannot distinguish two threads from one — a single-threaded execution of both loops also totals 8; the condvar handoff pair is the concurrency arbiter, because a single-threaded execution of its wait/notify protocol deadlock-timeouts (the waiter blocks with no second thread to notify) |
| R-2 | D2 fix makes the type genuinely trivially copyable in Clang | F8b probe: mock `static_assert(__is_trivially_copyable(T))` instantiation | The static_assert passing while a destructor decl is still attached (predicate bypass instead of triviality); or the CONFORMANCE pair failing on real libc++ while the mock golden passes (mock divergence — the pair is the arbiter) |
| R-3 | D2 negative: non-trivial classes still rejected cleanly | F8b probe, user-`Core.Destroy` class into the same template | The static_assert NOT firing for the non-trivial class (predicate too wide — memory-unsafe atomic ops on a class needing destruction), or a crash instead of the diagnostic |
| R-4 | D3 fix defines the SAME symbol uses reference | F8c probe golden IR + the global-counter pair executing | Pair links but prints wrong total (defined the wrong object / duplicate global); probe dump showing two globals for one var; symbol name differing between def and use |
| R-5 | D3 fix does not over-emit | Imported-global negative probe (`Cpp.inline_global`) | Any Carbon-side definition emitted for a C++-owned global (ODR violation the :299 comment guards); globals.carbon golden movement |
| R-6 | D1 fix passes the REAL function, not a stub | F8d pair: C++ `std::thread` must execute the Carbon body (observable side effect on an atomic checked after join) | Pair passing with the Carbon function body edited to a different value in a review probe (would prove the oracle isn't running the Carbon code); check golden resolving the ctor while lowering emits no symbol (link would catch — LINK-FAIL is red, not pass) |
| R-7 | D1 negative: unsupported callables still diagnosed | F8d probes: generic fn, method value | Generic-fn argument compiling (deduction on an unexported symbol = miscompile risk), or a crash replacing today's `CppCallArgTypeNotSupported` |
| R-8 | Runner change is neutral for non-threaded pairs | Full-suite run at F8a | Any pre-existing differential program changing status after `-pthread` (floor regression = halt) |
| R-9 | **H-P (named risk, added after plan review, 2026-08-09)**: `carbon link` still handles pthread linkage on TODAY'S runner (§2.5 — the 2026-07-19 execution evidence predates the runner migration / glibc divergence, ORCHESTRATION.md:45-52) | F8a's first runner CI run of cpp_thread_condvar_diff + cpp_thread_mutex_raii | LINK-FAIL or RUN-FAIL of either threaded program on the runner. Response: STOP-AND-DIAGNOSE — no workaround commit, no SKIP-papering; the failure evidence goes to a written plan amendment (possible outcomes: a Carbon-side link-flag fix as a scoped F8a addition, or re-staging) before F8a lands |

Per R16d, every pair's inputs are runtime-seeded; per the broken-oracle
discipline (b2 §5 R-5 — an unlanded branch artifact,
claude/carbon-fork-0-1-b2, cited for lack of a trunk equivalent; b1's §5
risk-register format is the on-trunk precedent), each new pair must fail
against a deliberately-broken oracle once during authoring — an
always-green pair is falsification.

## 6. Conformance floor arithmetic (recomputed after plan review, 2026-08-09 — adjudications A/B/C)

Rollup semantics this ladder is computed against (runner.py:500-528): a
bullet FAILs if any attached program fails; rolls up SKIP only when ALL
its attached programs SKIP; otherwise PASSes. SKIP programs are never
compiled or run (runner.py:320-321).

Stated over the **B2a baseline: 84 PASS / 0 FAIL / 30 SKIP over 114**
(42/56 bullets — B2a's plan target; the measured floor at f7b36d4 is
83/0/30 over 113, so if F8a lands BEFORE B2a every figure below shifts
−1 PASS / −1 total; bullet counts are unaffected either way).

| Slice | Programs added | SKIPs added | SKIP→PASS flips | Floor after | Bullets |
| --- | --- | --- | --- | --- | --- |
| F8a | +5 (2 green: condvar_diff, mutex_raii; 3 SKIP defect pairs) | +3 (D2/D3/D1 pairs; cpp_threading_atomics STAYS SKIP, text refreshed) | 0 | **86 / 0 / 33 over 119** | 42/56 (threading bullet all-SKIP: 4 SKIP programs) |
| F8b | 0 | 0 | 2 (cpp_threading_atomics + cpp_atomic_carbon_class_diff); condvar/mutex_raii re-home to the threading bullet | **88 / 0 / 31 over 119** | **43/56** (threading bullet: 4 PASS + 2 SKIP → PASS) |
| F8c | 0 | 0 | 1 (cpp_atomic_global_counter_diff) | **89 / 0 / 30 over 119** | 43/56 |
| F8d | 0 | 0 | 1 (cpp_thread_carbon_fn_diff) — or 0 under degrade (pair stays SKIP, §2.4) | **90 / 0 / 29 over 119** (degrade: **89 / 0 / 30 over 119**) | 43/56 either way |

Cross-checks: total programs 114+5 = 119 at F8a and constant after; PASS
84+2 = 86 (F8a), +2 = 88 (F8b), +1 = 89 (F8c), +1 = 90 (F8d); SKIP
30+3 = 33 (F8a), −2 = 31 (F8b), −1 = 30 (F8c), −1 = 29 (F8d); PASS+SKIP
= 119 at every row. F8a's two green programs flip no bullet: they attach
to two already-PASS bullets (§2.5), so 42/56 holds until F8b.

Of the baseline 30 SKIPs, exactly one can honestly flip in F8 —
cpp_threading_atomics, at F8b (the other 29 cite unions, overloading,
structural conformance, variadics, S4/SF-9/B3, docs — none cites a
threading defect). The three F8-minted SKIPs each flip only at their
named fix slice. FAIL stays 0 at every landing; scoreboard regeneration
rides `Fork: conformance suite` (R9).

## 7. TODO-string and SKIP-evidence ledger

-   **Net new TODO strings: zero** across F8a-d. D1's blocker is a
    diagnosed error (`CppCallArgTypeNotSupported`), not a `context.TODO`;
    D2's is a surfaced Clang static_assert; D3's is a link failure. No
    existing TODO string is discharged either: `interop with specific
    class` (export.cpp:67/:176) is explicitly NOT this plan's scope
    (§0.4). Amended only under the F8d degrade, which may add ONE precise
    TODO string + work item (a dated deviation here).
-   **SKIP movement** (retold after plan review, 2026-08-09 —
    adjudications A/B/C): at F8a, THREE SKIPs are minted (the D2/D3/D1
    conformance pairs, each an R10 SKIP quoting its measured diagnostic
    with un-SKIP = its named fix slice) and one SKIP text is REFRESHED in
    place (cpp_threading_atomics: stale MISSING claim corrected against
    threading-atomics.md:78-96's measured matrix; un-SKIP condition
    rewritten from "design lands AND surface usable" to "F8b lands the
    first defect fix" — the design-lands clause superseded by the F-008
    decision, disclosed as §11 item 1). Flips: two at F8b
    (cpp_threading_atomics + the D2 pair), one at F8c (D3 pair), one at
    F8d (D1 pair). Under the F8d degrade the D1 pair STAYS SKIP — its
    text updated to record the documented-limitation decision and
    W-023's upstream-watch (p003848 lambdas) as the un-SKIP condition —
    and W-023's re-staged ledger entry carries the full blocking
    evidence.

## 8. Testdata & golden flow

House rules as at B1/B2: new fail_ subfiles ship hand-written
CHECK:STDERR pins; positive goldens carry AUTOUPDATE markers with empty
CHECK content and ride the runner autoupdate workflow to R26 fixpoint —
never hand-authored (R15/R16a/R19); mock headers per the stdlib
testdata convention (§1); clang-format by way of hooks (R12/R18);
`runner.py --self-test` before every conformance-touching commit (R7);
private `--out` dirs (R5); `uvx prek run` locally before every push
(R23/R25); conformance program bodies compile-verified against the fork
toolchain before commit (R6; R1 PrintStr trap — programs print with
`Core.Print`/`Cpp.std.cout`; R2 `--output-last-input-only` is the
runner's own flagging). Differential pairs follow DIFF-1..4; `.diff.cpp`
files stay excluded from clangd-tidy (R24).

## 9. Work-item ledger

| Item | Movement |
| --- | --- |
| W-020 (TA-0 doc + programs) | ADVANCED at F8a: programs half delivered (deterministic multithreaded programs, join-before-print; the flagship program's un-SKIP follows at F8b per adjudication A); doc half stays GATED (ORCHESTRATION next-action 1) — the item is split at landing so the residue is visible. |
| W-021 (TA-D2 triviality) | DISCHARGED at F8b (or escalated S→M with plan amendment per §2.2's pre-declared condition). |
| W-022 (TA-D3 global emission) | DISCHARGED at F8c under H1-H3; CLOSED-as-upstream-fixed under H0 with the regression pin retained — either way said loudly in the decision-log landing note. |
| W-023 (TA-D1 callable mapping) | DISCHARGED at F8d, or RE-STAGED under the degrade path with R10 evidence; upstream p003848 re-check recorded either way. |
| W-006 risk 7 (single trivially-copyable predicate) | PARTIALLY DISCHARGED at F8b: the predicate exists with one owner (export.cpp); unions (F-007) and `Carbon::expected` export (B3) consume it later. |
| New items | Only under pre-declared deviations: F8d degrade (W-023 successor), F8b escalation, or a §2.3 stop (all-hypotheses-falsified or H0-mock-divergence). None minted speculatively. |

## 10. Non-goals (restated as boundaries)

threads_and_atomics.md authoring (gated); Core.Sync / native atomics
(rejected options); SF-9/S3p/B3 anything; C++20-mode surface; generic
class specific export; TSan scoreboard runs (sprint open question 3 —
scheduling-flake risk in CI; deferred to the doc digest); `volatile` /
`_Atomic` (sprint open question 6, doc digest).

## 11. Open questions: forks vs auto-adopt

**Genuine user forks: none.** F-008 is decided; nothing here diverges
from upstream direction (V-3a: all three fixes complete existing upstream
machinery; D2 implements an upstream TODO). Per V-2, the following
auto-adopt and appear in the merge veto digest:

1.  **The cpp_threading_atomics bullet flip is sequenced with the first
    fix (F8b), not the harness slice** (revised after plan review,
    2026-08-09, adjudication A): F8a only refreshes the SKIP's evidence;
    the SKIP text's "design lands" clause is superseded by the F-008
    decision itself (the fixes are sanctioned without the doc), and the
    flip rides real defect work. Disclosed for veto. Standing veto: keep
    it SKIP until the doc ships — costs the bullet flip at F8b.
2.  **D2 predicate shape** (§2.2): no-base/no-vtable/scalar-fields/no-user-
    Destroy, one owner in export.cpp, consumed later by unions/B3 (W-006
    risk 7). Veto-able toward a narrower (fields-only) or Clang-computed
    predicate.
3.  **Runner gains unconditional `-pthread` on the diff-cpp line** (§2.5).
    Veto: a per-program DIFF-CPP-ARGS directive instead (more machinery,
    same effect).
4.  **F8d argument embedding** as AST-level `DeclRefExpr` constants with
    thunk-param dropping (§2.4), generic/method values staying diagnosed.
5.  **C++ language mode**: conformance stays on Clang's default mode
    (Carbon side) and `-std=c++17` (oracle side, the runner's pin);
    the sprint's C++20-pin question rides the gated doc digest.
6.  **Upstreaming**: fork-first, upstream-second for all three patches
    (standing practice; sprint open question 2) — upstream PRs are
    prepared after fork landing, not gating it.

## Approval gate

This plan does not authorize implementation. Per house protocol it went to
TWO adversarial plan reviewers before coordinator sign-off; both returned
APPROVE-WITH-AMENDMENTS on 2026-08-09, and this document carries the full
fix round (see the Amendments log at top). The original briefs, for the
record:
reviewer #1 attacks the defect mechanisms (§0.1/§2: is the D1 trace
complete — is `InventPrimitiveClangArg` really the only failure site; can
a defaulted-destructor-free record still be non-trivially-copyable; do the
D3 hypotheses exhaust the symptom) with concrete counter-programs;
reviewer #2 attacks the classification and arithmetic (§0.4 disjointness
against the live B2a diff, §6 floor arithmetic, §7's zero-TODO claim, the
§3 exit criteria's falsifiability) and spot-checks every file:line
citation against trunk f7b36d4. Coordinator sign-off items = the six
digest entries in §11 plus: (i) the slice order F8a→F8b→F8c→F8d with the
bullet flip at F8b (adjudication A), (ii) the F8d degrade path as the
only sanctioned deviation (one story, adjudication C), (iii) the F8c
diagnose-first staging (no fix promised until the H0 adjudication run —
F8c's first step, adjudication D — and F8a's mechanism probe together
adjudicate H0-H3).
