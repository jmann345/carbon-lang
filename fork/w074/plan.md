<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-074 plan: `export x;` of a runtime `let` — the sanctioned import_ref.cpp amendment

Status: PLAN. Drafted 2026-08-18. Size S — one slice (W74a).
Baseline: trunk 577fdc3 (post-PR #29; conformance **96 PASS / 0 FAIL /
28 SKIP over 124**). Authoritative record: fork/inventory/work-items.json
W-074. This is the import_ref.cpp amendment round that fork/w069/plan.md
§5 step 3(ii) fenced and its Amendment 1 adjudication deferred ("pinning
the ExportDecl arm rides a future import_ref amendment round with its own
review") — that round is this plan. NO implementation in this document.
All verification rides self-hosted runner CI (autoupdate to fixpoint per
R26; conformance per R9).

## 0. The defect, precisely

`export x;` in library B, where `x` is an imported file-scope RUNTIME
`let` from library A, crashes the CHECKER of any file importing B:

-   check/eval_inst.cpp:363-368: `EvalConstantInst(..., SemIR::ExportDecl)`
    forwards the exported value's constant — NotConstant for a runtime
    `let` (the W-069 design keeps runtime bindings NotConstant at check;
    lowering promotes the storage).
-   check/import_ref.cpp `TryResolveInstCanonical` (fn at 4435): the
    non-constant branch (4480) then asserts
    `CARBON_CHECK(resolver.import_insts().Is<SemIR::AnyBinding>(inst_id))`
    (4483-4484) — an `ExportDecl` is not an `AnyBinding`. CHECK-crash.
-   The CHECK is upstream-era; W5-S3b added only the AnyBinding resolution
    logic beneath it (4485-4505) and never taught the branch about
    `ExportDecl`, because no upstream shape could put a NotConstant
    `ExportDecl` there: upstream's only value-level export golden,
    check/testdata/var/export_name.carbon, exports a `var`, and its
    `ExportDecl` is CONSTANT (`export v, ... [concrete = imports.%v.var]`
    — a ref binding to concrete `VarStorage`). Only the fork-minted
    runtime-`let` shape reaches the branch through an `ExportDecl`.

Chain anatomy (fixes the mechanism choice): handle_export.cpp:75-92
requires the exported name to be an `ImportRefLoaded` and mints
`ExportDecl{.value_id = <B's ImportRefLoaded>}`. Main's import of `x`
through B lands `GetInstForLoad` (5035+) on B's `ExportDecl` (it chases
only `ImportRefUnloaded`), so `Resolve` runs on the `ExportDecl` itself.
Contrast the WORKING `export import library` chain (check golden
let/global_runtime.carbon, reexport subfile): there B's scope holds an
`ImportRefUnloaded`, `GetInstForLoad` chases through to A's binding, and
the W5-S3b AnyBinding branch answers.

## 1. V-3a: is exporting a `let` binding design-sanctioned? YES

-   docs/design/code_and_name_organization/README.md ("Exporting imported
    names"): "`export` can be used either as a modifier to the `import`
    keyword to export the entire imported library, **or in an
    `export <name>` declaration to export a specific entity**" and
    "Exports just the \"Bar\" entity, which must come from an import."
    The ONLY stated exclusions: "Namespaces cannot be exported using a
    `export <name>` declaration" and "Names in other packages also cannot
    be exported." No entity-kind restriction — nothing scopes
    `export <name>` to types/functions.
-   proposals/p003938-exporting-imported-names.md (Proposal): "support
    the `export` keyword on **individual, file-scoped or
    namespace-scoped entities** (excluding entities in other packages,
    and namespaces themselves)." A file-scope `let` binding is a named
    file-scoped entity; it qualifies. Background posture, same doc:
    "Names declared in a Carbon file are currently exported by default."
-   Upstream implementation intent agrees: handle_export.cpp enforces
    exactly the proposal's restrictions (`ExportNotImportedEntity`,
    `ExportRedundant`; namespace/member/params rejections in the
    packages/fail_export_name_* goldens) — no value-vs-type filter. And
    var/export_name.carbon PROVES value-level runtime entities are in
    scope: `export v;` of a `var` works today (constant path).

Verdict: `export x;` of a runtime `let` is licensed; the crash is an
implementation gap, not a design fence. Lane (b) "diagnose: cannot export
a runtime binding" would CONTRADICT the design (V-3 veto criterion) —
rejected. Lane (c) (change `ExportDecl`'s eval to mint some constant)
would alter constant semantics that upstream goldens pin (`export v`'s
`[concrete = ...]` forwarding) — V-3a risk, rejected.

## 2. Mechanism: lane (a) — peek through `ExportDecl` in the non-constant branch

ADOPTED (veto-able): the check-side mirror of
`SemIR::GetCanonicalFileAndInstId`'s export arm (sem_ir/import_ir.cpp:
47-50), inserted immediately before the CHECK at import_ref.cpp:4483.
~10 lines, nothing else in the file:

```cpp
  auto inst_constant_id = resolver.import_constant_values().Get(inst_id);
  if (!inst_constant_id.is_constant()) {
    // `export x;` of a runtime binding mints an `ExportDecl` whose
    // constant forwards the exported value's NotConstant (eval_inst.cpp).
    // Peek through to the exported value -- the check-side mirror of
    // `GetCanonicalFileAndInstId`'s export arm -- so the reference
    // resolves exactly like a direct import of the binding: no importable
    // constant; lowering's canonical chase supplies the one symbol.
    if (auto export_decl =
            resolver.import_insts().TryGetAs<SemIR::ExportDecl>(inst_id)) {
      CARBON_CHECK(!resolver.import_constant_values()
                        .Get(export_decl->value_id)
                        .is_constant());
      return ResolveResult::Done(SemIR::ConstantId::NotConstant);
    }
    CARBON_CHECK(resolver.import_insts().Is<SemIR::AnyBinding>(inst_id), ...
```

Why `Done(NotConstant)` and not a recursive resolve of `value_id`:
`value_id` is B's `ImportRefLoaded` whose constant in B is itself
NotConstant (the W5-S3b runtime-`let` signature) — re-entering `Resolve`
on it would hit this same branch as a non-binding and crash again; and
the correct answer for a runtime binding IS `NotConstant` (identical to
what the AnyBinding branch returns at 4505 for a direct import). The
W5-S3b bound-value-constant sub-case (4500-4504) cannot hide behind an
`ExportDecl`: if the underlying bound value were constant, B's loaded ref
and hence the `ExportDecl`'s forwarded constant would be constant, and
resolution rides the constant path — the existing
`TryResolveTypedInst(..., SemIR::ExportDecl)` arm at 2312 (that is
today's working constant-export route). The inner `CARBON_CHECK` states
exactly this invariant; it firing is the falsifier that the argument is
wrong (then: widen to resolve `value_id`'s bound value, amendment).

Export-of-export needs NO loop: each file's `ExportDecl` wraps that
file's own `ImportRefLoaded` (handle_export.cpp requires it), so every
resolver invocation peeks at most one level; the multi-hop chain is
covered by a probe (§3), not by extra code. Lowering side: ZERO changes —
the W69a chase (lower/function_context.cpp:221-245 →
`GetCanonicalFileAndInstId`) already walks main → B's `ExportDecl` →
B's ref's import source → A's binding; it was implemented at W69a and
left unpinned pending exactly this fix.

Upstream-merge friction: import_ref.cpp is the fork's hottest upstream
surface (w069 §6 R-5). Posture: the diff is ONE contiguous insertion at a
stable anchor (the S3b comment block precedes it); at each weekly merge,
upstream wins the surrounding text and the peek re-applies as a
self-contained hunk. If upstream restructures `TryResolveInstCanonical`'s
non-constant branch (for example resolves its "TODO: Import of non-constant
BindNames"), the peek is re-evaluated against the new shape rather than
force-carried — same yield rule the S3b block already lives under.

## 3. Probes (red-first, honestly stated)

P-0 (boundary pin, lands FIRST, green today): constant-bound `let`
export by way of `export <name>` — A: `let c: i32 = 42;`, B: `export c;`,
main uses `c`. Pins the constant path (`export c, ... [concrete = ...]`;
importer's `[concrete = ...]`) so the fix demonstrably does not touch
it. New subfiles in check/testdata/let/global_runtime.carbon (fork-owned;
avoids churning upstream's packages/export_name.carbon).

P-1 (the crash shape): subfiles in the SAME golden — A `scalar.carbon`
(exists: `let x: i32 = Seed();`), new `export_name.carbon`
(`import library "scalar"; export x;`), new `import_export_name.carbon`
(`fn UseExportName() -> i32 { return x; }`). Expected pins: the export
file's `%x: i32 = export x, imports.%Main.x` with NO `[concrete = ...]`;
the importer's `import_ref ... loaded` with NO `[concrete = ...]` — the
same NotConstant signature as the existing import_scalar subfile.
HONESTY: today this shape CHECK-CRASHES, and crashes are not goldenable —
the probe cannot land red. It lands WITH the fix in the same slice; the
red evidence is the recorded W69a-round crash (decision-log R17
deviation (1)) plus a one-time pre-fix crash reproduction quoted in the
PR description, not a committed red golden.

P-2 (chain depth): a two-hop export-name chain — new subfiles
`export_export_name.carbon` (`import library "export_name"; export x;`)
and its importer (mirrors upstream packages/export_name.carbon's
`export_export` shape). Pins that the one-level peek composes per hop.

P-3 (W69a P-2 unlock, lower side): extend
lower/testdata/let/global_runtime.carbon with the same
export_name/import_export_name subfiles — main imports through B's
`export x;` and reads it. Expected pin: ONE `_Cx.Main` external global
declared/loaded in the importer, same symbol the defining file owns —
the promoted-global chase's ExportDecl arm exercised for the first time
(until now only import-chain hops were pinned by way of the reexport subfile).

Negative pin: every golden not named above is byte-identical in the PR
diff; the import_ref.cpp diff is the §2 insertion only.

## 4. One slice: W74a

1.  Land P-0 (boundary pin) — first commit, green pre-fix.
2.  The §2 insertion in import_ref.cpp (only file with logic changes).
3.  P-1/P-2 check subfiles + P-3 lower subfiles; autoupdate to fixpoint.
4.  Comment-only retexts made true by the fix (no behavior change):
    the two "W-074 crash shape, deliberately not exercised" dodge
    comments in fork/conformance/programs/code_org/
    library_multifile_export/{export.carbon:9-11, main.carbon:29-34}
    become "fixed at W74a; the shape is golden-pinned in
    let/global_runtime.carbon" with a dated marker.
5.  Records: work-items.json W-074 disposition; a dated
    "discharged at W74a" line at fork/w069/plan.md Amendment 1 (and its
    §8 P-2/unpinned-arm mention); decision-log entry; ORCHESTRATION.

Conformance: NO program change (ADOPTED, veto-able). The ledger
acceptance is golden-level; the natural runtime arbitration (an
`export x` unit in code_org/import_runtime_let, or a runtime `let`
export threaded through library_multifile_export) would either bifurcate
a landed arbiter's import route or churn a just-merged program's
EXPECT-STDOUT — recorded as optional follow-up material, not W74a scope.
**Expected floor: unchanged, exactly 96/0/28 over 124** (comment retexts
move no status).

## 5. Discharge criteria (R9-aligned)

-   The crash shape checks CLEAN: P-1 subfiles in the check golden pin
    export + importer with no `[concrete = ...]`; P-2 chain subfiles
    likewise; P-0 boundary pin byte-stable across the fix commits.
-   P-3 lower golden pins one `_Cx.Main` across the export-name route —
    the W69a P-2 ExportDecl-arm "implemented but unpinned" record is
    updated to discharged (w069 plan Amendment 1 + decision-log).
-   Golden autoupdate reaches fixpoint (R26); all untouched goldens
    byte-identical; gate green.
-   Conformance floor exactly 96/0/28 over 124; the two stale dodge
    comments retexted.
-   import_ref.cpp PR diff is the single §2 insertion (audit line).

## 6. Risks

-   **R-1 upstream collision (import_ref.cpp is upstream-hot).**
    Mitigation: minimal single-hunk insertion at the S3b anchor; the
    weekly-merge yield rule (§2) — upstream restructuring triggers
    re-evaluation, never force-carry.
-   **R-2 chain depth.** Export-of-export covered by P-2; the
    no-loop-needed argument (§2) is structural (per-file single wrap).
    Falsifier: P-2 crashing or the inner CHECK firing → amendment, not
    workaround.
-   **R-3 hidden constant sub-case.** If an `ExportDecl` ever reaches the
    branch with a CONSTANT `value_id`, the inner CARBON_CHECK fires
    loudly (by design) instead of silently mis-resolving; §2 names the
    widening that would then be reviewed.
-   **R-4 W-075 interaction: none.** W-075 (choice alternative-constant
    copy on by-value return) is a check-side value-conversion gap in a
    different subsystem; the shapes here never return a choice by value.
    Noted only so the two S-items don't get entangled in one PR.
-   **R-5 tuple/pointer-rep export shapes.** P-1 pins the scalar shape;
    choice-typed/tuple runtime lets exported by name ride the identical
    NotConstant route (the peek never inspects the type). If a reviewer
    wants belt-and-suspenders, a choice-typed export subfile is a cheap
    P-1 extension — offered, not required.

## 7. Open questions for the coordinator

None blocking. Two adopt-unless-vetoed decisions restated: (i) lane (a)
peek + `Done(NotConstant)` per the §1 design evidence; (ii) no
conformance program change (floor stays exactly 96/0/28), with the
runtime-arbitrated export-x unit recorded as optional follow-up material.

## Review-round amendments + sign-off (2026-08-18, coordinator)

One adversarial plan review: **APPROVE** — every load-bearing claim
verified against the tree, including the §2 re-crash claim (attacked
directly: recursion on the wrapped ImportRefLoaded provably re-enters
the 4483 CHECK; no chase redirects `TryResolveInst`; even a hand-rolled
chase would return the same NotConstant). Findings folded:

1.  **SF-1 (misattribution corrected):** the working constant-export
    route does NOT dispatch on the ExportDecl arm at
    import_ref.cpp:2311-2315/4580 — it dispatches on the exported
    value's canonical constant inst (the VarStorage arm for `export v`,
    the route var/export_name.carbon's `[concrete = %v.var]` importer
    pins); the ExportDecl arm is bypassed by the eval forwarding and
    appears statically dead for these shapes. §2's parenthetical is
    superseded by this record.
2.  **N-2:** the insertion's true upstream-side neighbor is upstream's
    OWN TODO at import_ref.cpp:4481-4482 ("Import of non-constant
    BindNames…"); the S3b comment block FOLLOWS the CHECK. The yield
    rule's trigger (upstream implementing that TODO) sits directly at
    the hunk boundary — exactly where the weekly merge will surface it.
3.  **N-3:** pre-fix, the two-hop chain crashes at the MIDDLE
    exporter's own check (its `export x;` name-lookup loads the inner
    ExportDecl), not only at the final importer — P-2's coverage is
    per-hop, discharged file-by-file.
4.  **N-1/N-4:** implementation may reuse `untyped_inst` by way of `TryAs`;
    golden dialect renders `%x: %i32`.
5.  **N-5 ADOPTED:** two probe extensions join W74a's set — **P-4** an
    impl-file consumer (`impl library` reading its api's `export x;` of
    a runtime let — the ApiForImpl route, nowhere pinned for runtime
    lets) and **P-5** an import_both-shaped dual-route merge subfile
    (main imports the defining AND the exporting library — mirrors
    upstream's import_both pin, extending it from classes to runtime
    lets). Same mechanism, cheap, close real coverage holes.

**This plan is APPROVED for implementation** (one slice, W74a). The V-2
digest carries: lane (a) adoption; the no-conformance-change floor
adoption (96/0/28 unchanged); the two probe adoptions; the SF-1
correction. Veto-able.
