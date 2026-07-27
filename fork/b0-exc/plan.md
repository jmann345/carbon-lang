<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# B0 implementation plan: `--cpp-exceptions` flag + fenced terminate-at-boundary thunks

Status: PLAN (W4-style loop, per fork/trial-w4/plan.md precedent). Author
context: fork/process.md + fork/rulebook.md loaded; design authority
docs/design/error_handling.md ("Interoperating with C++ exceptions" +
"The fenced boundary: terminate semantics" + staging table) under decision
F-006 (FINAL; sub-decisions e/f are this stage's spec: default `auto`,
fenced std::terminate at unfenced boundaries). Work item:
fork/inventory/work-items.json W-016. No local build (container clang 18);
code must compile on first CI attempt — every edit mirrors an in-file
precedent (R3 applied to C++, per the W4 retrospective's compile-first-try
lesson).

## 0. Stage boundary (restated as checkable behavior)

In B0:

1.  `carbon compile --cpp-exceptions={auto,none,catch}` (default `auto`).
    `none` compiles imported C++ with exceptions disabled; `catch` with
    exceptions enabled; `auto` resolves per D5 (design doc: `catch` unless
    the user's `--clang-arg` state disables exceptions).
2.  In (auto-resolved) `catch` mode, every Carbon call to a
    potentially-throwing C++ callee crosses through a generated thunk whose
    escaping exception deterministically terminates (`std::terminate`
    semantics) AT the thunk — replacing today's UB of unwinding into
    Carbon frames. `none` mode and direct (unthunked) `noexcept` calls are
    byte-identical to today; a `noexcept` callee that independently needs an
    ABI thunk gets no new thunk, but that thunk now carries
    `EST_BasicNoexcept` (strictly strengthening — see §4(b)).

NOT in B0 (hard boundary, error_handling.md staging table): `Core.Result`,
`Cpp.Exception`, catching thunks / `Result(T, Cpp.Exception)` imports (B3),
`Carbon::expected` export (B3), `?` (B2), reverse-direction callback
fencing beyond what falls out naturally (see §4 note), MSVC/Windows.

## 1. Verified toolchain facts this plan builds on

-   **Flag surface.** `CompileOptions` struct + `BuildForCompileSubcommand`
    (toolchain/driver/compile_options.h:31-137, .cpp:125-406). `AddOneOfOption`
    with `.Default(true)` precedent: `--phase` (compile_options.cpp:130-150)
    and `--dump-sem-ir-ranges` (.cpp:274-294). `--clang-arg` accumulates into
    `options->clang_args` (.cpp:31-53).
-   **Embedded Clang invocation.** `CompileOptions::BuildClangInvocation`
    (compile_options.cpp:479-500) builds `all_clang_args` = {opt-level flag}
    -   `clang_args`, then calls `Carbon::BuildClangInvocation`
        (toolchain/base/clang_invocation.cpp:53-109), which runs the real Clang
        driver → `clang::CompilerInvocation`. The resulting **LangOpts carry the
        resolved exceptions state** (`CXXExceptions`), including `-fno-exceptions`
        from user `--clang-arg`s and target defaults.
-   **Plumbing already exists.** The `CompilerInvocation` flows driver → check
    intact: compile_driver.cpp:463,630-631 → `Check::CheckParseTrees`
    (check.h:89-94) → `CheckUnit` (check_unit.cpp:66-73) → `ImportCpp`
    (check_unit.cpp:170) → Clang `CompilerInstance`/`Sema`/`ASTContext`. So
    the thunk code can read the resolved mode as
    `context.ast_context().getLangOpts().CXXExceptions` — **no new field
    threads through check** in B0.
-   **Thunk representation (the question this plan had to settle).** Thunk
    bodies are authored as **Clang AST**: `BuildCppThunk`
    (toolchain/check/cpp/thunk.cpp:651-691) creates a `clang::FunctionDecl`
    (`CreateThunkFunctionDecl`, thunk.cpp:437-479), builds the body with
    `clang::Sema` (`BuildThunkBody`, thunk.cpp:548-649), and hands it to the
    ASTConsumer (`HandleTopLevelDecl`, thunk.cpp:688). LLVM IR is produced
    later by Clang's own `CodeGenerator` during lowering
    (lower/file_context.h:169,273-275). **The fence must therefore be
    authored in Clang AST / on the thunk's C++ function type — not in SemIR
    and not in Carbon lowering.**
-   **Thunk gating.** `IsCppThunkRequired` (thunk.cpp:246-295) is consulted
    once per imported function at `ImportFunctionDecl`
    (check/cpp/import.cpp:1970); when true, the thunk is built and calls are
    routed through it by `PerformCppThunkCall` (check/call.cpp:291). Today it
    returns true only for ABI-bridging needs — B0 extends the predicate
    (design doc "B0 cost shape": fencing adds thunks to simple-ABI
    potentially-throwing calls; explicitly "not a free re-labeling").
-   **Exception-spec precedent in the same file.**
    `GeneratePlacementNewFunctionDecl` already writes
    `ext_info.ExceptionSpec.Type = clang::EST_BasicNoexcept;`
    (thunk.cpp:36-37) — the exact API the fence needs.
-   **Testdata knobs.** file_test supports `// EXTRA-ARGS:` on check/lower
    goldens (for example `--clang-arg=-fno-exceptions` in
    lower/testdata/interop/cpp/class/virtual_fn.carbon:6 and 3 siblings;
    `--clang-arg=-std=c++20` in check testdata) — new goldens can pass
    `--cpp-exceptions=...` the same way. `inline Cpp '''...'''` embeds C++
    in a Carbon file (virtual_fn.carbon:18-24).
-   **Conformance runner observation of terminate.** `runner.py` compares
    `subprocess.run(...).returncode` to `EXPECT-EXIT: <int>`
    (runner.py:143-149,249-259,341-359). POSIX `subprocess` reports a
    signal-killed child as a **negative returncode**, so SIGABRT (what
    `std::terminate`→`abort` produces) is `-6` and `// EXPECT-EXIT: -6`
    works with zero runner changes. Stdout is captured through a pipe, so
    buffered stdout is lost on abort (risk 6). The runner has **no per-program
    compile-flag mechanism** (compile_cmd fixed, runner.py:300-307) — §7 adds
    one. Inline-C++ conformance precedent:
    programs/interop/cpp_operator_import_arithmetic.carbon:19-34
    (`import Cpp inline '''c++ ... '''`).

## 2. Driver flag (`toolchain/driver/compile_options.{h,cpp}`)

compile_options.h — add to `CompileOptions` (next to `Phase`):

```cpp
enum class CppExceptions : int8_t {
  Auto,
  None,
  Catch,
};
...
CppExceptions cpp_exceptions = CppExceptions::Auto;
```

compile_options.cpp — in `BuildForCompileSubcommand` (task scope: compile
subcommand; see sub-fork SF-3), mirroring the `--dump-sem-ir-ranges`
AddOneOfOption shape:

```cpp
b.AddOneOfOption(
    {
        .name = "cpp-exceptions",
        .help = R"""(
Selects how imported C++ code is built with respect to exceptions and what
happens when an exception reaches the language boundary.

`none` compiles imported C++ with exceptions disabled. `catch` compiles it
with exceptions enabled; an exception escaping a call from Carbon into C++
deterministically terminates the program at the boundary. `auto` (the
default) resolves to `none` when the Clang arguments disable exceptions,
and to `catch` otherwise.
)""",
    },
    [&](auto& arg_b) {
      arg_b.SetOneOf(
          {
              arg_b.OneOfValue("auto", CppExceptions::Auto).Default(true),
              arg_b.OneOfValue("none", CppExceptions::None),
              arg_b.OneOfValue("catch", CppExceptions::Catch),
          },
          &cpp_exceptions);
    });
```

In `BuildClangInvocation` (compile_options.cpp:479-500), after
`all_clang_args.append(clang_args);`:

```cpp
switch (cpp_exceptions) {
  case CppExceptions::Auto:
    // Resolved by the Clang driver: LangOpts reflect the user's arguments.
    break;
  case CppExceptions::None:
    all_clang_args.append({"-fno-exceptions", "-fno-cxx-exceptions"});
    break;
  case CppExceptions::Catch:
    all_clang_args.append({"-fexceptions", "-fcxx-exceptions"});
    break;
}
```

Appending AFTER user `clang_args` makes the explicit mode win by Clang's
own last-wins rule (sub-fork SF-2; note the deliberate asymmetry with the
opt-level flag, which is _prepended_ at .cpp:483-488 precisely so user args
can override it — an explicit `--cpp-exceptions` is a boundary-semantics
contract, not a tuning default). No other driver change; `build`/`link`
subcommands untouched.

## 3. Auto-resolution rule — implementation

D5's rule ("catch unless user Clang args disable exceptions") is
implemented by **not implementing it in the driver at all**: `auto` appends
nothing, the Clang driver computes `LangOpts.CXXExceptions` from the user's
arguments (and target defaults), and the check-side fence gates on that
single bit. One mechanism, no arg-string scanning, agrees by construction
with "how the C++ code was actually built" (the design's own rationale).
Consequence worth stating: on a target whose Clang default is
exceptions-off, `auto` resolves to `none` with no user args — consistent
with the rationale, slightly broader than D5's letter (sub-fork SF-4).

## 4. The fence (`toolchain/check/cpp/thunk.cpp`)

Two verified-minimal edits.

**(a) Extend `IsCppThunkRequired`** — after the `is_imported` check and
`decl` lookup (thunk.cpp:254-260), before the signature-based cases:

```cpp
// With C++ exceptions enabled, every potentially-throwing callee crosses
// the boundary through a fenced thunk
// (docs/design/error_handling.md#the-fenced-boundary-terminate-semantics).
if (context.ast_context().getLangOpts().CXXExceptions &&
    decl->getType()->castAs<clang::FunctionProtoType>()->canThrow() !=
        clang::CT_Cannot) {
  return true;
}
```

`castAs<clang::FunctionProtoType>()` on the decl type is already used at
thunk.cpp:283-284; `ImportFunctionDecl` guarantees a prototype
(import.cpp:1960-1961). `CT_Dependent` conservatively counts as
can-throw. In `none` mode (or auto→none) `CXXExceptions` is false and the
predicate — and thus all behavior — is byte-identical to today.
Consequences that fall out for free: `noexcept` callees (including
implicitly-noexcept destructors) get no NEW thunk, and direct (unthunked)
`noexcept` calls stay byte-identical to today — though a `noexcept` callee
that independently needs an ABI thunk carries `EST_BasicNoexcept` on that
thunk by way of (b), strictly strengthening; C++
constructors/methods/operators are covered because every imported callee
funnels through this one predicate and `PerformCppThunkCall`
(call.cpp:291); virtual dispatch is preserved because the thunk body calls
through an unqualified `MemberExpr` (thunk.cpp:559-579).

**(b) Fence the thunk type** — in `CreateThunkFunctionDecl`
(thunk.cpp:445), condition mirrors (a)'s gate:

```cpp
auto ext_proto_info = clang::FunctionProtoType::ExtProtoInfo();
if (context.ast_context().getLangOpts().CXXExceptions) {
  // Fence: an exception escaping the wrapped call reaches this noexcept
  // boundary and terminates deterministically at the thunk.
  ext_proto_info.ExceptionSpec.Type = clang::EST_BasicNoexcept;
}
```

This is the **exception-spec fence**: Clang CodeGen emits the call inside
the thunk as `invoke` with a terminate landing pad
(`__clang_call_terminate` → `std::terminate`), that is the C++-standard
semantics of an exception escaping a `noexcept` function — the design doc's
own analogy for the boundary ("the language-boundary analog of an exception
escaping a `noexcept` C++ function"). One line, exact in-file precedent
(thunk.cpp:37). Applying it to _every_ thunk in catch mode (not just
fence-motivated ones) also fences the pre-existing ABI-bridging thunks,
which the invariant requires.

The design doc's illustrative snippet instead shows an explicit
`try { ... } catch (...) { __carbon_boundary_terminate(); }` that "prints a
diagnostic identifying the boundary". The exception-spec fence produces the
runtime's generic verbose-terminate message (libc++abi names the exception
type but not the boundary) — a real, must-be-recorded delta against the
doc's diagnostic sentence. Authoring the try/catch in Sema is feasible
(`ActOnCXXTryBlock` + a synthesized helper decl, placement-new-decl
pattern) but needs a definition strategy for the helper (inline linkonce
definition emitting the message with no declared stdio, or a runtime
library that does not exist yet). **This is sub-fork SF-1 — recommend the
exception-spec fence for B0 with the boundary-identifying diagnostic
recorded as a follow-up work item feeding B3's thunk rework, but the user
decides.** Both variants terminate deterministically at the thunk; only the
message differs.

Reverse direction note: B0's only Carbon-visible entry points from C++ are
exported Carbon functions, which cannot throw; a C++ frame calling back
into Carbon code that calls throwing C++ hits that call's own fence. No
additional reverse machinery is in B0; recorded as a follow-up alongside
B3.

No BUILD changes: thunk.cpp already depends on the Clang AST/Sema targets
it needs; compile_options.cpp gains no includes (enum is self-contained).

## 5. What is deliberately NOT touched

-   `toolchain/check/check.h` / `CheckParseTreesOptions` — no new member
    (LangOpts carries the mode).
-   `toolchain/lower/**` source — the fence rides Clang CodeGen; Carbon
    lowering emits the same plain `SemIR::Call` to the thunk as today.
-   `toolchain/base/clang_invocation.*` — mode flags are appended by the
    caller; the shared builder stays mode-agnostic (the `carbon clang`
    subcommand is a plain Clang and needs no Carbon-specific default).
-   SemIR: no new inst kinds, no formatter/typed_insts changes.

## 6. Testdata plan (all new goldens AUTOUPDATE + empty CHECK lines, R15/R16a)

New, `toolchain/check/testdata/interop/cpp/exceptions/`:

-   `fenced_thunk.carbon` — default args; non-noexcept `inline Cpp` function
    with simple ABI; SemIR shows the thunk decl + thunk call (today: direct
    call).
-   `noexcept_no_fence.carbon` — `noexcept` callee; SemIR shows a direct
    call, no thunk (locks the zero-cost claim).
-   `none_mode.carbon` — `EXTRA-ARGS: --cpp-exceptions=none`; same callee as
    `fenced_thunk.carbon`, direct call (locks none == today).
-   `auto_resolves_none.carbon` — `EXTRA-ARGS: --clang-arg=-fno-exceptions`;
    direct call (locks D5's auto→none arm).
-   `fail_throw_in_none.carbon` — `EXTRA-ARGS: --cpp-exceptions=none` with
    `throw` in the inline C++; Clang's "cannot use 'throw' with exceptions
    disabled" surfaces by way of CppInteropDriverError-style plumbing (locks
    "diagnosed exactly as Clang would").
-   `catch_overrides_clang_arg.carbon` — `EXTRA-ARGS: --cpp-exceptions=catch
    --clang-arg=-fno-exceptions`; thunk present (shape depends on SF-2's
    resolution; drop if SF-2 resolves to diagnose-conflict, replaced by a
    fail_ golden).

New, `toolchain/lower/testdata/interop/cpp/exceptions/fenced_thunk.carbon`
— LLVM IR golden locking the fence at the IR level (`invoke` +
terminate landing pad inside the thunk; the Carbon caller itself contains
no landing pads of its own).

**Existing goldens change — this is the big one.** 128 check testdata
files and 40 lower testdata files import Cpp; under default args
(auto→catch) every non-noexcept imported function now gets a thunk, so the
majority of those goldens' SemIR/IR shifts (thunk decls appear, calls
reroute; 39 check + 27 lower files already mention `carbon_thunk` and will
shift too; the 2 `dump_cpp_ast` goldens gain `noexcept` on thunk types).
Only the 4 lower goldens already passing `--clang-arg=-fno-exceptions`
(class/export/*, copy_vs_move, virtual_fn) are guaranteed untouched — they
are the auto→none sentinels. Per R16(a) NO hand-editing: push with stale
CHECK lines, expect the red first CI, run the runner-side autoupdate
workflow and commit the reconciliation before the merge gate (R15/R19).
This is the largest autoupdate reconciliation the fork has done — the
reviewed autoupdate diff IS the churn audit (reviewers: sample it for
semantic surprises, not formatting).

Driver testdata: none required (`AddOneOfOption` rejects bad values
generically); optional `fail_` golden for an invalid mode value only if
review asks.

## 7. Conformance suite impact (`fork/conformance/`)

Runner extension (harness work, standing rule 6 — Claude decides): add a
`// COMPILE-ARGS: <args>` directive parsed like EXPECT-EXIT
(runner.py:141-159), whitespace-split and appended to `compile_cmd`
(runner.py:301-307), so programs can pin a `--cpp-exceptions` mode.
Documented in the header-comment grammar (runner.py:110-118); `--self-test`
(R7) and the README auto-table (DIFF-4) re-run before commit.

Programs, all under `programs/error_handling/` on the existing bullet
"Error handling: C++ exception interop (-fno-except config, calling
throwing C++, exporting Carbon errors as std::expected/exceptions)"
(exact text per R7); inline-C++ shape cloned from
interop/cpp_operator_import_arithmetic.carbon:

-   `cpp_exceptions_none_mode.carbon` — `COMPILE-ARGS:
    --cpp-exceptions=none`; non-throwing C++ helper (no `throw` anywhere —
    it would be a compile error in this mode); computes and prints a value;
    EXPECT-EXIT 0 + EXPECT-STDOUT. Pins that the -fno-except configuration compiles and runs (throw
    rejection is pinned by fail_throw_in_none.carbon, not here —
    landing-review honesty note).
-   `cpp_exceptions_auto_catch.carbon` — no COMPILE-ARGS (default `auto`);
    helper containing `throw` on an untaken path; EXPECT-EXIT 0 +
    EXPECT-STDOUT. Pins that the default build keeps C++ exceptions enabled (a literal
    `throw` compiles); auto RESOLUTION is pinned by the check goldens, not
    here (landing-review honesty note).
-   `cpp_exceptions_fence_terminate.carbon` — `COMPILE-ARGS:
    --cpp-exceptions=catch`; helper that unconditionally throws; the Carbon
    call site never sees the exception; `EXPECT-EXIT: -6` (SIGABRT by way of
    negative subprocess returncode, §1) and **no EXPECT-STDOUT** (buffered
    stdout is lost on abort — deliberate, see risk 6). This is the
    documented-crash program. Landing-review honesty note: exit -6 does
    not discriminate fence-present from fence-absent (an uncaught
    exception aborts in the phase-1 handler search before unwinding, so
    an unfenced exceptions-on build exits -6 identically); the fence
    itself is pinned by the lower golden fenced_thunk.carbon.
-   `cpp_exception_interop.carbon` (existing SKIP) — stays SKIP (its body is
    B3: catching into values), but its reason currently cites
    "toolchain/base/clang_invocation.cpp contains no exception-handling
    configuration", which B0 falsifies; rewrite per R10 to cite the actual
    B3 blockers (no `Core.Result` in prelude, no catching-thunk path in
    toolchain/check/cpp/thunk.cpp, no `Cpp.Exception` synthesis; staging
    table in docs/design/error_handling.md).

Bullet accounting: with three passing programs plus one SKIP on the same
bullet, the rollup flips the bullet to PASS (runner.py:448-454: all
non-SKIP pass + one ran) even though catching/export (B3) is unbuilt —
same shape as W4-S1's guard-program trade. Sub-fork SF-5: recommend
following the W4-S1 precedent (flip + decision-log scope-trade entry
stating B0-only coverage), but the user may prefer the bullet held back
(for example by keeping all B0 programs on EXPECT-only status under a new bullet
— which would require a gap-analysis table edit, R7). Never decided here.

Existing interop conformance programs (36 in programs/interop/) now run
fenced calls in their default-mode builds — expected exit/stdout are
unchanged (nothing throws), and the scoreboard non-regression gate is the
proof; a regression there is a B0 bug, not a golden to update.

Post-run bookkeeping: regenerate scoreboard with a private `--out` dir
(R5); update fork/inventory/work-items.json W-016 (and the W-019/B3 item's
evidence line that points at the old clang_invocation state); record
sub-fork outcomes in fork/decision-log.md before merge.

## 8. Files touched (complete list)

-   `toolchain/driver/compile_options.h` — `CppExceptions` enum + member.
-   `toolchain/driver/compile_options.cpp` — flag registration + clang-arg
    appending (§2).
-   `toolchain/check/cpp/thunk.cpp` — `IsCppThunkRequired` gate + thunk
    exception spec (§4).
-   `toolchain/check/testdata/interop/cpp/exceptions/*` (new),
    `toolchain/lower/testdata/interop/cpp/exceptions/fenced_thunk.carbon`
    (new) — §6.
-   ~100-170 existing check/lower interop goldens — autoupdate
    reconciliation only, never hand-edited (§6).
-   `fork/conformance/runner.py` — COMPILE-ARGS directive; README table
    regen.
-   `fork/conformance/programs/error_handling/cpp_exceptions_none_mode.carbon`,
    `cpp_exceptions_auto_catch.carbon`,
    `cpp_exceptions_fence_terminate.carbon` (new);
    `cpp_exception_interop.carbon` (SKIP reason update).
-   `fork/inventory/work-items.json`, `fork/decision-log.md`,
    `fork/conformance/out/scoreboard.json` (regenerated).

No changes to: toolchain/check/check.h, toolchain/base/clang_invocation.*,
toolchain/lower source, toolchain/sem_ir, any BUILD file, parse, lex.

Land sequence (no commits from this loop's implementer; the Push-phase
agent commits): implement → hook-clean (R12/R18) → push → expected-red
first CI on stale goldens → fire autoupdate workflow → reconciliation
commit → `bazel test //toolchain/...` + conformance scoreboard gates →
merge.

## 9. Risks

1.  **Golden-churn scale.** The autoupdate reconciliation touches on the
    order of 150 files; a semantic bug hidden in mechanical churn is the
    main review hazard. Mitigation: reviewers audit a random sample of the
    reconciled goldens (thunk decl present iff callee non-noexcept; the 4
    `-fno-exceptions` sentinels byte-identical), and the lower golden pins
    the IR shape independently.
2.  **Clang API drift vs the CI LLVM pin.**
    `FunctionProtoType::canThrow()`/`CT_Cannot` and
    `ExtProtoInfo::ExceptionSpec` are long-stable, but the container cannot
    compile-check (clang 18 here vs CI's pinned LLVM); the invariants
    reviewer must verify both signatures against the pinned LLVM source
    before push (W4's compile-first-try discipline).
3.  **Thunks-for-everything semantic blast radius.** Routing every
    non-noexcept import through a thunk may perturb paths tuned for direct
    calls: address-taken imported functions, template instantiation timing
    (`MarkFunctionReferenced` now runs on the thunk path), operators, and
    virtual-override interop. Reviewer #1's brief: find the input where the
    thunk changes observable behavior (not just SemIR shape).
4.  **Inlining/EH interaction.** Fenced thunks are `AlwaysInline` +
    internal with a landing pad; correctness does not depend on inlining,
    but if Carbon's pass pipeline ever failed to run the always-inliner the
    thunks stay out-of-line (correct, slightly slower) — and LLVM's inliner
    must merge the personality into Carbon-lowered callers (the design doc
    explicitly blesses this). The lower golden and the conformance
    terminate program are the executable checks.
5.  **Link-time symbols.** The fence introduces `__gxx_personality_v0` /
    `__cxa_*` / `__clang_call_terminate` references into interop objects;
    `carbon link` builds runtimes on demand (R4 — generous timeouts) and
    already links libc++/abi for existing interop programs, but the first
    catch-mode conformance run is the real proof.
6.  **Abort loses buffered stdout.** `std::terminate` → `abort` skips
    stdio flush; the terminate program asserts exit code only. Any future
    EXPECT-STDOUT on a terminating program is a landmine — noted for the
    runner docs.
7.  **Terminate observable is platform-shaped.** `-6` assumes POSIX signal
    reporting through Python `subprocess` on the Linux runner; fine for
    this fork's single-runner reality, would need revisiting for other
    hosts.
8.  **Upstream collision** (standing rule 5): upstream lands interop work
    weekly and exceptions configuration is an obvious target; check
    upstream for in-flight `-fno-exceptions`/thunk-fencing PRs before
    implementation starts.
9.  **Diagnostic-fidelity delta vs the design doc** if SF-1 resolves to the
    exception-spec fence: the "diagnostic identifying the boundary"
    sentence is not yet satisfied. Must be recorded as a deviation +
    follow-up work item, not silently (mirrors W4's usefulness-diagnostics
    deferral, W-066).
10. **Bullet over-claim** if SF-5 resolves to flipping the umbrella
    exception-interop bullet on B0-only coverage — mitigated by the
    decision-log entry and the still-SKIP B3 program, but it is exactly
    the "PASS hides narrowed coverage" lens reviewer #2 must apply.

## 10. OPEN sub-forks (recommendations only — user decides, per process.md "Sub-forks are forks")

-   **SF-1 — fence authoring mechanism.** (a) `noexcept` exception-spec on
    the thunk type (one line, in-file precedent, standard C++ terminate
    semantics; generic runtime message) vs (b) explicit Sema-built
    `try`/`catch (...)` calling a synthesized `__carbon_boundary_terminate`
    helper (matches the doc's snippet and boundary-identifying diagnostic;
    requires new decl synthesis + a definition/link strategy). Recommend (a)
    for B0 with the diagnostic as a recorded follow-up.
-   **SF-2 — explicit mode vs contradictory `--clang-arg`s.** (a) Mode flags
    appended after user args, so an explicit `--cpp-exceptions` silently
    wins by Clang last-wins (zero new machinery) vs (b) driver error on the
    contradiction. Recommend (a); `auto` remains the no-opinion spelling.
-   **SF-3 — flag placement.** (a) `compile` subcommand only (task scope;
    `build` inherits the `Auto` default) vs (b) shared options so
    `carbon build` can set it too. Recommend (a) for B0.
-   **SF-4 — auto-resolution source of truth.** (a) Final
    `LangOpts.CXXExceptions` from the real Clang driver (includes target
    defaults; zero bespoke logic) vs (b) literal scan of user `--clang-arg`
    strings per D5's exact wording. Recommend (a).
-   **SF-5 — bullet accounting for B0.** (a) Let the umbrella
    exception-interop bullet flip PASS with a decision-log scope-trade entry
    (W4-S1 precedent) vs (b) hold the bullet back until B3 (requires
    gap-analysis/bullet restructuring under R7). Recommend (a).
