<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# W-069 plan: cross-file references to file-scope runtime `let` bindings — exported backing storage in lowering

Status: PLAN (process step 6 — awaiting the two adversarial plan reviews and
the coordinator's answers to §8 before any implementation).
Drafted 2026-08-18.
Baseline: branch trunk 2f8876c (post-PR #27, W-068 discharged; conformance
**93 PASS / 0 FAIL / 29 SKIP over 122 programs**,
fork/conformance/out/scoreboard.json generated 2026-08-18T09:53Z).
Ledger authority: fork/inventory/work-items.json W-069 (half (b) —
constant-bound lets — LANDED at W5-S3b by way of import_ref.cpp's
TryResolveInstCanonical non-constant-binding branch; this plan is the residue,
half (a): a `let` bound to a RUNTIME value has no exported backing storage).
Design authority: docs/design/values.md (expression categories, value
bindings, value-representation license), docs/design/pattern_matching.md;
upstream's own TODO breadcrumbs at
toolchain/lower/testdata/var/import.carbon:47 and
toolchain/lower/handle.cpp:220-224. Precedent format: fork/w072/plan.md and
fork/b2/plan.md. NO implementation in this document — planning only. No local
bazel: all verification rides the self-hosted runner CI (golden autoupdate to
fixpoint per R26; conformance per R9). **Where this plan and any summary
(ORCHESTRATION.md stamps, session notes, decision-log shorthand) disagree,
the plan wins**; divergences discovered mid-slice are folded back here as
dated amendments (the b1/w072 house pattern).

---

## 0. V-3a upstream-alignment check (gating, done first)

### 0.1 The question

Is a cross-file reference to a file-scope `let` bound to a runtime value
(i) something upstream has DESIGNED semantics for, (ii) an
acknowledged-but-unimplemented gap, or (iii) contradicted by design (for example a
rule that a `let` binding's runtime backing is intentionally file-local)?

### 0.2 The evidence, quoted

**Upstream acknowledges the gap, in its own testdata and its own lowering
code — twice:**

1.  toolchain/lower/testdata/var/import.carbon:47, inside the
    `import_tuple_pattern` subfile that imports
    `let (x: i32, var y: i32) = (3, 4);`:

    > `// TODO: Also test `x`. Right now, lowering a reference to an
    > imported `let` asserts.`

    The `var` halves of the same declaration (`y`, and `v`/`w`/`z`) are
    tested and pass through exported `VarStorage` globals
    (`@_Cy.Main = external global i32`, import.carbon:158,178). The `let`
    half is skipped with a TODO — the definition of an acknowledged,
    unimplemented case.

2.  toolchain/lower/handle.cpp:220-224, the `NameRef` lowering:

    > `// `GetValue` will fail on package-scope value bindings because they
    > aren't constants, and they aren't global variables, so as a workaround
    > we peek through bindings here to directly access the bound value.`
    > `// TODO: Find a way of dealing with this that still works if the
    > bound value isn't a global variable or constant either.`

    Upstream names the exact missing case this plan covers: a package-scope
    value binding whose bound value is neither a constant nor a global
    variable — that is a runtime `let`. Both breadcrumbs live in
    `toolchain/lower/`: upstream frames this as a LOWERING problem, not a
    check/SemIR redesign.

**The design does NOT contradict exported backing storage — it licenses the
implementation to choose any backing, provided no address is exposed:**

3.  docs/design/values.md:442-444 ("Value expressions"):

    > "A value cannot be mutated, cannot have its address taken, and may
    > not have storage at all or a stable address of storage."

    So a `let` binding carries no addressable-storage guarantee — and
    equally no storage PROHIBITION. Backing storage is an implementation
    detail as long as the language surface never yields its address.

4.  docs/design/values.md:456-460 (value acquisition semantics):

    > "This allows immediately reading from the object's storage into a
    > machine register or a copy if desired, but does not require that."

    and values.md:141-144: acquisition "may do this by eagerly reading that
    value into a machine register, lazily reading that value on-demand into
    a machine register, or in some other way modeling that abstract value."
    A named module-scope global holding the acquired value is squarely "some
    other way of modeling that abstract value."

5.  docs/design/values.md:495-497 (the as-if copy license):

    > "Carbon's values are much closer to a `const &` in C++ with extra
    > restrictions such as allowing copies under 'as-if' and preventing
    > taking the address."

    This licenses relocating/copying the bound value into dedicated exported
    storage: values have no identity, so the copy is unobservable.

6.  **Design silence on linkage.** Neither values.md nor
    docs/design/code_and_name_organization/ says anything about the
    cross-library storage, linkage, or symbol semantics of file-scope
    bindings (`let` or otherwise); there is no variables/linkage design doc,
    and no proposal was found specifying `let` storage semantics across
    libraries. Where upstream is silent, V-3a permits creative fork design
    at full speed.

7.  **The overview-level license and its one caveat** [amended 2026-08-18,
    review round — reviewer #1 SF-4].
    docs/design/README.md:1236-1249 ("Global constants and variables"):

    > "[Constant `let` declarations] may occur at a global scope as well as
    > local and member scopes. However, there are currently no global
    > variables." — with the explicit note that "the semantics of global
    > constant declarations and absence of global variable declarations is
    > currently provisional."

    So global `let` is licensed at the overview level, global VARIABLES are
    absent by current design, and the whole section is marked provisional.
    The "no global variables" half feeds §0.3's honesty boundary below.

### 0.3 The verdict (veto-able)

**Classification: acknowledged upstream gap (case ii) — full speed under
V-3a.** No accepted proposal or design doc is contradicted by giving a
file-scope runtime `let` exported backing storage AT THE LOWERING LEVEL,
because (a) upstream's own TODOs name the missing lowering, and (b) the
design explicitly denies programs any way to observe whether a value binding
has storage (no address-of, no mutation, as-if copies). The one honestly
fork-authored artifact is ABI-shaped, not semantics-shaped: the mechanism
mints an EXPORTED SYMBOL (`_C<name>.<package>[.<fingerprint>]`) for storage
upstream has never named. That is a **divergence-risk register entry**
(reviewed at each weekly upstream merge, reversible — no SemIR or language
surface depends on the symbol's existence), and a **V-2 veto-digest item**,
NOT an SF-grade synchronous ask: there is no design fork here, only an
implementation-strategy choice inside a space the design deliberately leaves
to the implementation. Honest boundary, stated: if a future upstream design
rules that value bindings' backing is file-local (none found today), the
fork mechanism is a lowering-only branch whose removal churns nothing
outside `toolchain/lower/` + the new goldens — see §6 R-5 for why the
chosen lane makes that retreat cheap. A second honesty note [amended
2026-08-18, review round — reviewer #1 SF-4]: docs/design/README.md
(§0.2 item 7) says "there are currently no global variables" (provisional).
The fork's backing storage is var-SHAPED at the LLVM level — a named
mutable global written once by the ctor — so the mechanism must never
surface it as a language-level global variable: no address, no mutation
path, no new declaration syntax, SemIR untouched. The README's
"no global variables" posture is preserved at the language surface while
the lowering privately borrows the `var` symbol machinery; if that ever
stops being true, R17 applies (redesign, not rationalize).

---

## 1. Current state (claims re-derived from the tree at 2f8876c)

-   **What a file-scope `let` produces at check.** `HandleParseNode(...,
    Parse::LetDeclId)` (toolchain/check/handle_let_and_var.cpp:325-363) runs
    `LocalPatternMatch` on a `value_binding_pattern` — NO `VarStorage` is
    created anywhere on the `let` path (contrast VariablePattern's
    `GetOrAddVarStorage`, handle_let_and_var.cpp:116). The initializer is
    checked inside the `__global_init` pseudo-function
    (`StartPatternInitializer` → `context.global_init().Resume()`,
    handle_let_and_var.cpp:184-197; `UseGlobalInit` is true exactly at
    package scope or static class scope, toolchain/check/global_init.cpp:61-64),
    so the binding's bound-value inst LIVES in `__global_init`'s body —
    visible in check/testdata/let/import.carbon's golden:
    `%.loc4_14: ... = converted @__global_init.%.loc4, ...`. For a
    pointer-value-rep type the bound value is (a value acquisition of) a
    materialized temporary; for a scalar it is the raw runtime inst (call
    result etc.).
-   **How references lower, and where they die.** `NameRef` lowering peeks
    through the binding to `bind_name->value_id` (lower/handle.cpp:225-228)
    and calls `FunctionContext::GetValue`
    (lower/function_context.cpp:171-197): `locals_` → the file's
    `global_variables()` → the constant path, which
    `CARBON_CHECK(const_id.is_concrete(), "Missing value: ... has
    non-concrete value {3}")` (function_context.cpp:188-190). A runtime
    bound value is in no map and has constant value `runtime` — the CHECK
    fires. This kills BOTH the cross-file case (the importer's `NameRef`
    points at an `ImportRefLoaded` with `NotConstant`) AND the same-file
    cross-function case (the bound value is a local of `__global_init`, not
    of the referencing function). The gap was never choice-specific.
-   **Why `var` works (the parity target).** `VarStorage` is itself a
    constant instruction whose constant lowers to the named global
    (`EmitAsConstant(..., SemIR::VarStorage)` → `BuildGlobalVariableDecl`,
    lower/constant.cpp:371-379; `BuildNonCppGlobalVariableDecl` mangles by way of
    `Mangler::MangleGlobalVariable`, lower/file_context.cpp:753-795,
    sem_ir/mangler.cpp:299-324 — name + inverse-qualified scope +
    private-to-library fingerprint). The importer reconstitutes the
    `VarStorage` constant (check/testdata/var/global_decl_import.carbon:
    `%Main.x: ref %struct_type.v = import_ref Main//decl, x, loaded
    [concrete = %x.var]`), its `name_ref` is REF-category so check inserts
    value acquisition at each use, and lowering emits
    `@_Cv.Main = external global ...` + loads
    (lower/testdata/var/import.carbon:84-90). Definitions get initializers
    in `LowerGlobalVariables` (file_context.cpp:285-310) and the runtime
    stores run in `_C__global_init` registered by way of `llvm.global_ctors`
    (file_context.cpp:134-178) — **file-scope runtime initialization
    already exists and runs**; §5's init-order contingency starts from
    parity, not from zero.
-   **Half (b), already landed (the residue boundary).**
    import_ref.cpp:4479-4506: a non-constant imported inst must be an
    `AnyBinding`; if the BOUND value's constant is importable the binding
    resolves to it ("a file-scope `let` can bind a constant initializer...
    Resolve the imported reference to the bound value's constant"), else
    `ResolveResult::Done(SemIR::ConstantId::NotConstant)` — and the comment
    closes with the residue this plan owns: "A binding whose bound value is
    non-constant — a runtime `let` — still has no importable value." Pinned
    today by check/testdata/let/import.carbon (`import_ref ... loaded
    [concrete = constants.%empty_tuple]`).
-   **The ledger's displaced acceptance test.**
    check/testdata/match/choice_generic_payload_scrutinee.carbon:50-71,
    `imported_global` subfile: `let g: P(i64) = P(i64).Neither;` sits in
    the IMPORTING file with the comment "The binding is local — a
    cross-file `let` reference has no lowering story (W-069 ...)". The
    W5-S3b landing note records the move; restoring a cross-file
    runtime-bound `let g` is the ledger's acceptance test for the residue.
-   **Crash pinnability.** file_test compiles in-process and `fail_`
    goldens pin DIAGNOSTICS, not aborts (the one lowering fail golden,
    lower/testdata/basics/fail_before_lowering.carbon, exists to show
    "earlier errors prevent lowering, without crashing"). A `CARBON_CHECK`
    abort kills the test binary — **the crash shape is not representable as
    a golden**; §3 designs around that.
-   **Constraint inherited from check:** file-scope initializers cannot
    contain control flow ("Control flow expressions are currently only
    supported inside functions" — ledger item **W-036**,
    fork/inventory/work-items.json [corrected 2026-08-18, review round —
    reviewer #2 S-6: previously miscited as "the W-024-family TODO";
    W-024 is the overload-sets item]). All probes initialize by way of
    plain calls; branching lives inside the called function.
-   **Conformance ground truth.** 93/0/29 over 122; no SKIP cites W-069,
    `let` import, or global-binding evidence (grepped) — floor movement in
    this plan is by ADDITION only. The conformance runner compiles exactly
    ONE file per program (runner.py; the recorded harness limitation in
    code_org/library_multifile_export.carbon's SKIP) — which caps what a
    conformance program can arbitrate at runtime; see §8 OQ-1.

---

## 2. Mechanism candidates

### 2.1 (a1) — VarStorage-parity promotion in LOWERING (defining file) + import routing (RECOMMENDED)

**Defining file** [amended 2026-08-18, review round — reviewer #2 S-1 /
reviewer #1 SF-2/SF-3]. A pre-pass beside `LowerGlobalVariables`' walk of
the file's top inst block finds every package-scope `AnyBinding` that is a
**VALUE binding** whose bound value's constant is `NotConstant`. The
predicate, concretely: bound value's constant `NotConstant` (half (b)'s
complement — the test import_ref.cpp:4500-4501 already uses) AND the
binding inst's expression category is `ExprCategory::Value`
(`SemIR::GetExprCategory`, sem_ir/expr_info.h — the category a binding
derived from a `ValueBindingPattern` forwards). Non-value bindings are
excluded: a `let ref`-shaped (reference-category) binding is NOT promoted —
the P-8 probe pins whichever behavior the tree has today (check-rejected,
or accepted-and-excluded with the (a3) diagnostic) — and `AliasBinding` is
safe by construction: check rejects runtime-valued aliases outright
(`AliasRequiresConstantValue`, check/handle_alias.cpp:80-84, reviewer #1
NIT-3), so no runtime alias reaches lowering. Class-scope `static`
bindings — the other `UseGlobalInit` arm (global_init.cpp:61-64) — stay
OUT of scope: the crash persists there, is not claimed by this plan, and
is recorded honestly (reviewer #2 N-4).

For each selected binding, build a named `llvm::GlobalVariable` of the
binding type's OBJECT representation, zero-initialized, mangled by a new
`Mangler::MangleGlobalLetBinding` that reuses `MangleGlobalVariable`'s
exact shape (`_C` + `MangleNameId` + `MangleInverseQualifiedNameScope` +
the `IsPrivateToLibrary` fingerprint suffix, mangler.cpp:299-324) applied
to the binding's entity name; register it in the `FileContext` promotion
registry keyed by the BOUND-VALUE inst id (the id `NameRef` peek-through
yields). **Emission, stated precisely** [reviewer #1 SF-2]: the BINDING
inst lives in the FILE TOP BLOCK, not in `__global_init`'s body — only its
BOUND-VALUE inst is ctor-body resident (check/testdata/let/import.carbon's
golden shows the file-block `converted` wrapping `@__global_init.%.loc4`).
So the copy hook keys off the bound-value inst id DURING the ctor's
`BuildFunctionBody` (or an end-of-ctor sweep over the promotion registry):
when the ctor has computed the bound value, emit the copy into the global —
`CreateStore` for a by-copy value rep; a memcpy of the object size from
the bound pointer for a pointer value rep (the as-if license, §0.2 item 5;
promote-the-temporary-in-place is the §5 step 4 optimization, not the
baseline). A registry entry whose key the ctor's `FunctionContext` never
visits (for example a file-block `converted` wrapper shape whose operand
never materializes in the ctor body) must be LOUDLY demoted to the (a3)
diagnostic at pre-pass time — never left as a silent zeroinit global.
Name-keyed reuse before every creation, per the F8c discipline already
written into `BuildNonCppGlobalVariableDecl` (file_context.cpp:772-789).

**Value-representation dispatch** [reviewer #1 SF-3], in
`ValueRepr::Kind` terms (sem_ir/type_info.h:21-41) with
`IsCopyOfObjectRepr` (type_info.h:66) as the store/load gate:

-   `Copy` where the value rep IS a copy of the object rep
    (`IsCopyOfObjectRepr` true) → store/load promotion (the scalar arm,
    W69a);
-   `Pointer` → the W69b memcpy arm (object-rep global; the global's
    address serves as the value rep at uses);
-   `None` (for example a runtime empty-tuple-typed let) → NO storage minted;
    references are served as the empty value (probe P-9 pins this);
-   `Copy` that is NOT object-identical, or `Custom` → the (a3)
    diagnostic, not promotion (loud, pinnable, honest).

**Every reference** — same-file cross-function AND cross-file — is served by
one new branch in `GetValue`'s fall-through (function_context.cpp, before
the concreteness CHECK):

-   local hit in the promoted-let map → produce the value representation
    from the global (load for by-copy reps; the global's address for
    pointer reps — mirroring `GetConstant`'s value-rep dispatch,
    file_context.cpp:207-267);
-   miss + the inst is imported → resolve it with
    **`SemIR::GetCanonicalFileAndInstId`** (sem_ir/import_ir.cpp:29-58)
    [amended 2026-08-18, review round — reviewer #1 SF-1], NOT a
    single-hop `GetImportSource`: the helper chases import chains AND
    peeks through `ExportDecl` re-exports, so an A-defines / B-re-exports
    / main-imports-B chain lands on A's DEFINING binding and its IR
    rather than on B's intermediate inst. If the canonical inst is a
    package-scope value-binding `AnyBinding` (the same predicate as the
    defining side) with non-constant bound value → get-or-create the
    EXTERNAL global declaration, mangled by running the Mangler over the
    CANONICAL (defining) IR (same inputs ⇒ same name as the defining
    file's emission), then produce the value rep the same way. The P-2
    golden gains an export-re-export subfile pinning exactly this chain.
    Both branches call `AddGlobalToCurrentFingerprint` (coalescing,
    §6 R-2).

`handle.cpp`'s peek-through workaround stays; its :223 TODO is retexted to
point at the new path (the "bound value isn't a global variable or constant"
case is now handled for package scope).

Trade-offs: **SemIR is untouched** — zero check-golden churn, zero language-
surface change (no address ever becomes expressible; values.md:442 holds by
construction), the diff is confined to `toolchain/lower/` + one additive
mangler entry, and upstream's two TODO breadcrumbs both point at exactly
this layer. Cost: lowering grows a third storage-ish path next to
`VarStorage` and constants; the import branch must reach through
`GetImportSource` into a foreign IR (a mechanism already exercised at
file_context.cpp:484 and by `GetFileContext(const_ir)` in GetValue itself);
and cross-filename agreement rests on the mangler being a pure function of
the source IR (same property `var` already relies on — the importer mangles
the imported pattern too).

### 2.2 (a2) — check-side VarStorage synthesis (upstream-shaped, NOT chosen)

Give file-scope runtime `let`s a `VarStorage`-like inst at check time
(synthesized storage + the binding routed through it), so lowering and
import ride the existing `var` machinery unchanged. This is plausibly what
an upstream check-side fix would look like — but it is rejected here for
three concrete reasons. (i) **Category leak:** the `var` machinery works
because a ref-category `name_ref` makes check insert value acquisition at
every use (§1); a value binding's uses insert nothing. Making the let name
ref-category under the hood would make `&x` and `x = ...` checkable —
contradicting values.md:442 — unless a new binding kind + gates are minted:
a real SemIR design fork, with import/export format implications, taken
fork-locally. (ii) **Blast radius:** every file-scope `let` golden
(upstream's included) churns SemIR shape, and import_ref.cpp — the
single hottest upstream-merge file the fork touches — needs a matching
resolver arm; (a1) needs neither. (iii) **Merge posture:** if upstream later
lands its own check-side design, an (a1) fork is a dead lowering branch to
delete; an (a2) fork is a SemIR schema to migrate. Recorded as the shape to
RE-EVALUATE if upstream moves first (§6 R-5), not as this plan's lane.

### 2.3 (a3) — reject cleanly (honest degrade; the fallback rung, and W69a's belt-and-suspenders)

Turn the CHECK crash into a diagnosed limitation at check time: when a use
site's `NameRef` binds a package-scope binding whose bound value is
non-constant AND the reference cannot be served (imported binding resolved
`NotConstant`; or same-file reference from outside `__global_init`), emit a
proper diagnostic ("cannot reference file-scope `let` bound to a runtime
value here" — or a `SemanticsTodo` while the mechanism is partial). This is
strictly better than today for the shapes it covers (crash → diagnostic,
`fail_` pinnable), but it fills no gap — the ledger item stays open and the
acceptance tests stay unreachable. Used two ways in this plan: as the
CONTINGENCY floor if (a1) is blocked (§5 step 5), and as the guard for any
shape the promotion pre-pass declines (§5 step 4) so the "either promoted or
diagnosed, never a silent crash or dangling alloca" invariant holds.

### 2.4 Lane decision (recorded; veto-able — digest item 1)

| Candidate | Upstream evidence | Disposition |
| --- | --- | --- |
| (a1) lowering-side promotion + import routing | Both upstream TODOs sit in `toolchain/lower/`; the `var` symbol/ctor machinery it mirrors is upstream's own; SemIR untouched keeps values.md:442 true by construction | **ADOPTED** — primary lane |
| (a2) check-side storage synthesis | Closest to a hypothetical upstream check-side fix, but no upstream signal exists; category-leak + import-format + import_ref-churn costs are real today | Rejected; re-evaluate on upstream movement (§6 R-5) |
| (a3) clean rejection | Honest but fills nothing | Fallback rung + partial-shape guard (§2.3, §5) |

---

## 3. Probes (red-first, within what is representable)

The crash is not goldenable (§1), so "red-first" here means: the
CHECK-side goldens for the crashing shapes land FIRST and pin that check
ACCEPTS them today (proving the fix needs no check change and bounding the
byte-equivalence claim), the working neighbors are pinned to make the
residue boundary explicit, and the lower goldens for the crashing shapes
land WITH the mechanism as empty-CHECK autoupdate files (R15/R19) — their
first green regeneration is the mechanism's compile-validation.

| # | Probe | Vehicle | Expected TODAY (pre-mechanism) | Expected AFTER W69a/W69b |
| --- | --- | --- | --- | --- |
| P-1 | same-file scalar runtime let: `fn Seed() -> i32; let x: i32 = Seed();` + `fn Use() -> i32 { return x; }` | NEW check golden check/testdata/let/global_runtime.carbon | checks clean; binding's bound value inside `@__global_init` pinned in SemIR; (lowering would abort — stated in a comment citing function_context.cpp:188-190, NOT exercised) | SemIR byte-identical; NEW lower golden pins `@_Cx.Main = global i32 0`, ctor store, `load` in `Use` |
| P-2 | cross-file scalar runtime let (defining + importing subfiles); PLUS an export-re-export subfile — A defines the runtime let, B re-exports it, main imports B — pinning the §2.1 `GetCanonicalFileAndInstId` chain [amended 2026-08-18, review round, SF-1] | same check golden, split-file | checks clean; importer pins `import_ref ... loaded` with NO `[concrete = ...]` — the NotConstant signature of the residue | SemIR byte-identical; lower golden pins `external global` + load in the importer — ONE symbol name across the whole A/B/main chain |
| P-3 | constant-bound cross-file let (half (b) boundary) | EXISTING check/testdata/let/import.carbon (`[concrete = constants.%empty_tuple]`) + upstream lower/testdata/var/import.carbon | already green — the boundary pin | UNTOUCHED except the P-6 TODO flip below |
| P-4 | the `var` vehicle | EXISTING lower/testdata/var/import.carbon (`@_Cv.Main` external + ctor stores) | green | byte-identical (parity anchor for the mechanism's symbol/ctor shape) |
| P-5 | choice-typed cross-file RUNTIME let: plib gains `fn MakeNeither() -> P(i64) { return P(i64).Neither; }` and `let g: P(i64) = MakeNeither();`; importer matches `g` | check/testdata/match/choice_generic_payload_scrutinee.carbon — the RESTORED `imported_global` subfile (W69b) | checks clean today (the crash was lowering-only); pins the acceptance shape's SemIR | plus NEW lower golden pinning the promoted object-rep global, ctor memcpy, and the importer's discriminant load |
| P-6 | upstream's own TODO: does half (b) already discharge it? Add `fn X() -> i32 { return x; }` to lower/testdata/var/import.carbon's import subfile and delete the :47 TODO | upstream golden, autoupdate-regenerated | PREDICTED green ALREADY: `x` binds tuple element `3`, a constant — S3b's branch imports it and it lowers by way of the constant path (the four-goldens-improved precedent in the S3b landing note). If RED instead: the failure shape is recorded and the TODO stays until W69a's mechanism covers it — either way the probe ends with the TODO honestly resolved | green; TODO gone — the named upstream breadcrumb is discharged |
| P-7 | runtime TUPLE-pattern let: `let (a: i32, b: i32) = MakePair();` cross-file | subfile of the W69a goldens | checks clean | both bindings promoted independently (per-binding globals) |
| P-8 [added 2026-08-18, review round, S-1] | file-scope `let ref` (reference-category binding) — the non-value-binding exclusion pin | NEW check subfile (fail_ or positive per what the tree does) | pins whichever the tree does TODAY: check-rejected, or accepted (the probe is written first and records the answer) | unchanged if check-rejected; if accepted, EXCLUDED from promotion with the (a3) diagnostic — never silently promoted (§2.1 predicate, R-7) |
| P-9 [added 2026-08-18, review round, SF-3] | runtime EMPTY-TUPLE-typed let: `let e: () = MakeEmpty();` referenced cross-function | subfile of the W69a goldens | checks clean | NO storage minted (`ValueRepr::Kind` = `None`); references served as the empty value; lower golden pins the ABSENCE of a `_Ce` global |
| P-10 [added 2026-08-18, review round, S-5] | whole-tuple/struct-TYPED runtime let, consumed cross-file BOTH as `t.0` (element read) AND as whole `t` | subfile of the W69b goldens | checks clean | promoted object-rep global; both consumption shapes pinned in the importer's lower golden |

Negative pins [reworded 2026-08-18, review round — reviewer #2 S-7]: the
byte-equivalence obligation lands on each slice's **PR-diff audit step
over toolchain/**/testdata**, not on the goldens themselves — a golden
cannot assert anything about OTHER files. The audit confirms that every
existing `let` golden (check/testdata/let/*.carbon, lower/testdata/let/*)
is byte-identical in the slice diff — constant-bound lets MUST keep riding
the constant path, not the new globals (falsifier for an over-broad
promotion predicate); P-1/P-2 carry comments NAMING that audit obligation
so the reviewer's checklist reaches it.

---

## 4. Slices

Each slice is one landable PR through the full R11 loop (implementer → 2
adversarial reviewers → fixer), gated on runner golden autoupdate to
fixpoint (R15/R19/R26) + `bazel test //toolchain/...` + upstream-parity gate
(R21) + `uvx prek run` (R25) + conformance non-regression with
`runner.py --self-test` (R7/R9) + scoreboard regeneration at landing.

### W69a — probes + the mechanism for scalar shapes (M)

-   **Toolchain files:** toolchain/lower/function_context.cpp (the
    `GetValue` fall-through branch), toolchain/lower/file_context.{h,cpp}
    (promotion pre-pass, promoted-let registry, ctor-store emission,
    external-decl builder with name-keyed reuse),
    toolchain/sem_ir/mangler.{h,cpp} (`MangleGlobalLetBinding`, additive —
    and [amended 2026-08-18, review round — reviewer #1 NIT-2] its
    fingerprint input is the **BINDING INST itself**: `AnyBinding` has no
    pattern_id, and a mismatched fingerprint input between the defining
    and importing sides is the F8c-shaped silent name split — both sides
    MUST feed the same binding-inst-derived input),
    toolchain/lower/handle.cpp (comment retext only).
-   **Goldens:** NEW check/testdata/let/global_runtime.carbon
    (P-1/P-2/P-7/P-8/P-9 check side, including P-2's export-re-export
    subfile), NEW lower/testdata/let/global_runtime.carbon (same shapes,
    empty-CHECK → autoupdate), the **R-1 falsifier golden** — a defining
    file + TWO importing files + a private-let subfile; any `.N`-suffixed
    symbol in the regenerated golden is the alarm [assigned 2026-08-18,
    review round — reviewer #2 S-4], upstream
    lower/testdata/var/import.carbon P-6 TODO flip (autoupdate-regenerated
    — R16a: goldens change only by way of the runner autoupdate workflow).
-   **Byte-equivalence:** every existing check golden byte-identical (SemIR
    untouched is the lane's core claim — ANY check-golden churn is
    stop-and-explain, **modulo declared churn** [qualified 2026-08-18,
    review round — reviewer #2 S-3]: the P-6 flip in this slice and the
    P-5 restore at W69b, each landed by way of autoupdate per R16a); existing
    lower goldens byte-identical except var/import.carbon (P-6, new
    function + TODO removal, churn declared).
-   **Floor:** unchanged, **93/0/29 over 122** (goldens only — no floor
    movement; the runtime arbiters land at W69b, after W69h gives the
    harness split-file support [renormalized 2026-08-18, review round —
    reviewer #2 B-1, per §8-A OQ-1(a)]).
-   **Discharge criteria (slice):** P-1/P-2/P-7 lower goldens green at
    fixpoint pinning named-global + ctor-store + external-decl + load
    (with P-8's exclusion pin and P-9's no-storage pin green alongside
    [amended 2026-08-18, review round]); P-6 resolved either way with the
    record; byte-equivalence audit clean; CHECK at
    function_context.cpp:188 no longer reachable for package-scope
    runtime-let references (the reviewers' trace obligation).

### W69h — harness: split-file multi-unit conformance programs (S) [added 2026-08-18, review round — reviewer #2 S-2, encoding §8-A OQ-1(a)]

-   **Files touched:** fork/conformance/runner.py + its `--self-test` +
    the README conventions — ONLY. No toolchain files, no program files,
    no SKIP-directive edits. **Scope guard, extended per reviewer #1
    SF-5:** no new scoreboard fail-class keys —
    .github/workflows/fork_conformance.yaml:84-91 hardcodes the
    fail-class key list (COMPILE-FAIL, LINK-FAIL, RUN-FAIL,
    OUTPUT-MISMATCH, DIFF-MISMATCH); a second compilation unit's compile
    failure is expressed as the existing COMPILE-FAIL, never a new key.
-   **Arbiter:** `runner.py --self-test` green AND a full conformance run
    reproducing **93/0/29 over 122 byte-for-byte** — the
    behavior-preservation proof for every existing single-file program.
-   **No-flip proof, explicit:** SKIP is an IN-FILE marker — runner.py
    parses `// SKIP:` per program (runner.py:183-185) and returns SKIP
    before any compile (runner.py:320-321) — so the runner change ALONE
    can flip nothing; a SKIP flips only when its own file's directive is
    edited, which this slice does not do.
-   **Floor:** unchanged, **93/0/29 over 122** (the byte-identical
    scoreboard rerun IS the claim).
-   **Discharge criteria (conditional + re-open clause):** `--self-test`
    green; the byte-identical full-run scoreboard; the split-file program
    convention documented in the README. If the rerun shows ANY movement
    — any count, any per-program status — the slice STOPS un-landed and
    this plan re-opens at W69h with the diff as evidence; W69b does not
    start until W69h lands clean.

### W69b — class/choice shapes + the ledger acceptance (M)

-   **Toolchain files:** the pointer-value-rep arm of the same lowering
    paths (object-rep global + ctor memcpy + address-as-value-rep at uses).
    Expected to be small — the plumbing lands in W69a; this slice makes the
    rep dispatch real and proves it on the motivating types.
-   **Goldens:** check/testdata/match/choice_generic_payload_scrutinee.carbon —
    the `imported_global` subfile RESTORED to a cross-file split per P-5:
    `let g` moves back to plib, bound to the runtime `MakeNeither()` call
    (the W5-S3b re-authoring undone, upgraded to the runtime form that
    arbitrates the residue), PLUS a constant-bound cross-file sibling
    subfile (`let gc: P(i64) = P(i64).Neither;`) kept as the explicit half-
    (b) boundary pin — see §8 OQ-3. NEW lower golden
    lower/testdata/let/import_choice.carbon (or match/-side, reviewer's
    call) pinning the promoted global's object rep, the ctor memcpy, and
    the importing file's external decl + discriminant load; a class-typed
    (non-choice) subfile rides along so the mechanism is pinned independent
    of choice machinery — its importing-file consumption is a **FIELD
    READ** [specified 2026-08-18, review round — reviewer #2 S-5]; the
    P-10 whole-tuple/struct-typed subfile (consumed as `t.0` AND whole
    `t`) rides in the same golden [S-5]; PLUS the **R-2 falsifier
    golden** — two specifics of one generic each reading a DIFFERENT
    imported runtime let; coalesced output is the bug [assigned
    2026-08-18, review round — reviewer #2 S-4].
-   **Conformance** [renormalized 2026-08-18, review round — reviewer #2
    B-1: W69h lands first, so THIS slice carries BOTH programs]:
    1.  the SINGLE-FILE runtime arbiter, under
        `CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop`
        (deepens an existing-PASS bullet; character-exact per R7): a
        file-scope `let` of a generic-choice specific bound to a runtime
        constructor call (payload runtime-computed per R16d), matched
        exhaustively inside `Run` with the payload read back —
        arbitrating promotion + ctor ordering + readback at runtime.
    2.  the SPLIT-FILE cross-file runtime arbiter (defining library +
        importing main, riding W69h's multi-unit support), under
        `CONFORMANCE-BULLET: Code organization: Importing` — the
        cross-file half of the acceptance arbitrated at runtime, per the
        house DIFF-1 standard.

    **Arbitration recipe, committed now** [reviewer #2 N-6]: runtime
    seeds come from `fn RuntimeSeed(x: i32) -> i32 { return x + 20; }`;
    every expected output is derived from seed ARITHMETIC written as a
    literal, independent of the binding chain under test — never
    recomputed by reading the promoted binding twice. Concrete sketch:
    program 1 seeds its choice payload from `RuntimeSeed(1)` (= 21) and
    expects the matched payload readback to print `21`; program 2's
    defining library binds its runtime let from `RuntimeSeed(3)` (= 23)
    and the importing main prints the imported binding, expecting `23`.
    A zeroinit read (ctor never ran / wrong global) prints `0` and fails
    loudly. Ctor-order safety: `llvm.global_ctors` run before `main`, so
    function-body readers are ordering-safe by construction; the
    seed-derived expectations keep the failure mode observable anyway.
-   **Floor:** **95/0/29 over 124** (+2 by addition; no SKIP flips — none
    cites this work; no bullet flips claimed) [renormalized 2026-08-18,
    review round — B-1].
-   **Discharge criteria (slice = the W-069 residue):** the restored
    cross-file runtime `let g` split green in check AND lower goldens;
    BOTH conformance programs PASS on the scoreboard (R9 — the report
    quotes scoreboard.json); ledger W-069 updated to DISCHARGE-STAGED
    with the R9 hedge, flipping to discharged when the landing scoreboard
    regenerates. W-069 discharges AT THIS SLICE — W69c is contingent
    residue only, with no discharge dependency [renormalized 2026-08-18,
    review round — B-1].

### W69c — CONTINGENT (S): generic/specific-typed residue [renormalized 2026-08-18, review round — reviewer #2 B-1]

Minted only if W69b's traces show imported-generic-specific-typed lets
or specific-coalescing interactions the W69b goldens don't already cover
(the S3b `AddCanonical` import lesson says trace before assuming). The
former trigger (ii) — the split-file runtime program — is DELETED: §8-A
adopted OQ-1(a), W69h lands the harness support before W69b, and W69b
carries the cross-file runtime program itself. W69c is therefore
goldens-only: NO floor claim unless a conformance program is added at
that time (in which case the floor movement is declared then, by
addition only). If the trigger does not fire, W69c is not minted and
W-069 discharges at W69b.

---

## 5. Contingency ladder (pre-declared)

1.  **Expected path:** promotion lands; goldens converge at R26 fixpoint;
    proceed.
2.  **Init-order trouble.** Investigated UP FRONT: file-scope runtime
    initializers already exist and run — check builds `__global_init`
    (global_init.cpp:27-59), lowering registers it in `llvm.global_ctors`
    (file_context.cpp:134-178), and lower/testdata/var/import.carbon's
    goldens show the ctor stores. Function-body readers run post-ctors
    (before `main`), so the acceptance shapes are ordering-safe. The REAL
    residual is cross-TU initializer-reads-imported-binding (static-init-
    order-fiasco): unspecified today for `var` (all ctors priority 0), and
    this plan takes exact PARITY — recorded, not fixed; a probe initializer
    never reads another file's runtime binding. If CI nevertheless shows a
    zeroinit read in the W69b program: STOP, diagnose link/ctor order on
    the runner, and adjudicate before inventing priorities — minting ctor
    priorities is fork ABI and needs its own digest entry.
3.  **Import side can't identify the source binding.** The design leans on
    `GetImportSource` returning a live `ImportIRInstId` for the importer's
    inst (inst.h:590-595). If the loc is not preserved for the specific
    inst `NameRef` hands over: (i) first try keying off the importer's
    `ImportRefLoaded` table entry directly; (ii) if identification
    genuinely requires stashing new data in import_ref.cpp, STOP — that
    file is the highest-merge-friction surface (§6 R-5) — and take a plan
    amendment with its own review round; (iii) if (ii) is refused,
    cross-file drops to lane (a3) diagnostics while same-file promotion
    stands, and W-069 is re-noted with the blocker.
4.  **Promotion-shape fragility.** If the pre-pass cannot reliably map a
    binding to its bound-value inst/copy point for some pattern shape
    (deep converted-chains, exotic tuple patterns), those shapes get the
    (a3) diagnostic instead of promotion — the invariant is "promoted OR
    diagnosed, never a silent crash, never an escaping `__global_init`
    alloca" (§6 R-6's falsifier). Promote-the-temporary-in-place (skipping
    the memcpy) is an OPTIMIZATION contingency in the other direction,
    taken only if the copy shape itself misbehaves.
5.  **Lane fundamentally blocked** (a structural reason lowering cannot
    serve these references): fall back to (a3) wholesale — crash becomes
    diagnostic with `fail_` pins, the testdata split stays local with its
    comment updated to cite the diagnostic, W-069 stays OPEN recording the
    blocker and the (a2) re-evaluation trigger, and the W69b conformance
    programs are not written (no floor claim). This outcome is digest-worthy
    (the item's acceptance test is abandoned for 0.1).
6.  **Upstream lands its own fix mid-workstream** [added 2026-08-18,
    review round — reviewer #2 N-5]. If a weekly upstream merge landing
    BETWEEN slices brings an upstream mechanism for imported-`let`
    lowering (the §6 R-5 grep watches the two TODO breadcrumbs for
    exactly this), the workstream STOPS at that merge: reconcile the fork
    mechanism against upstream's and PREFER upstream's (the V-3a default)
    — the SemIR-untouched lane makes the retreat a lowering-branch
    deletion plus golden regeneration — and re-plan any remaining slices
    on top of upstream's mechanism before continuing.

---

## 6. Risk register (falsifiable)

-   **R-1. Mangling collision (the F8c lesson).** Module symbol-table reuse:
    `BuildNonCppGlobalVariableDecl` already carries the fork's name-keyed
    early-return precisely because double-creation silently renames to
    `.N` and splits initializer from uses (file_context.cpp:772-789, the
    `_Ctotal.Main.2` incident). The let path MUST ride the same
    get-before-create discipline on both the defining and importing sides.
    A promoted let can never collide with a same-scope `var` (one name, one
    declaration — check diagnoses redeclaration), and private-to-library
    bindings take the fingerprint suffix exactly as `MangleGlobalVariable`
    does. FALSIFIER: a lower golden with a defining file + two importing
    files, and a private-let subfile — any `.N`-suffixed symbol in the
    regenerated golden is the alarm.
-   **R-2. Coalescing/fingerprint hole.** Specific functions referencing
    promoted-let globals must include them in their fingerprints or
    `CoalesceEquivalentSpecifics` (file_context.cpp:193-197) could merge
    specifics that touch DIFFERENT globals. The new `GetValue` branch calls
    `AddGlobalToCurrentFingerprint` (as the constant path does at :195).
    FALSIFIER: a golden with two specifics of one generic each reading a
    different imported runtime let — coalesced output is the bug.
-   **R-3. Value-semantics honesty.** The mechanism must never make backing
    storage observable: SemIR untouched ⇒ no address-of, no mutation path
    exists (values.md:442 by construction), and the ctor memcpy is licensed
    by the as-if copy rule (values.md:495-497) — the one-sentence R17
    justification. SF-6 keeps the motivating choice payloads trivially
    copyable; for general classes the relocated object is the binding's own
    materialized temporary, which nothing else can alias (values cannot
    have their address taken). If a reviewer exhibits ANY language-level
    observation channel for the copy, R17 applies: redesign (promote-in-
    place) rather than rationalize.
-   **R-4. Init-order / SIOF** — §5 step 2; parity with `var`, recorded.
-   **R-5. Upstream-merge friction (weekly merges).** Exposure ranked:
    import_ref.cpp — HOT upstream, and this lane deliberately changes ZERO
    lines of it (half (b) already sits there; nothing new is added);
    lower/function_context.cpp + file_context.cpp — moderate churn, small
    additive branches, and file_context already carries fork comments (F8c,
    B2 zeros rationale) that merge cleanly; mangler.{h,cpp} — additive
    entry point. The pre-implementation re-check greps upstream for
    movement on the two TODO breadcrumbs (var/import.carbon:47,
    handle.cpp:223) and on `let` lowering generally; if upstream lands its
    own mechanism, the fork branch YIELDS at the next merge (V-3a default
    preference), which the SemIR-untouched property makes a lowering-only
    deletion plus golden regeneration.
-   **R-6. Partial promotion dangles.** A pointer-rep binding whose temp is
    NOT promoted but whose reference escapes `__global_init` would read a
    dead alloca. Today that shape cannot ship silently (the CHECK fires
    first); the mechanism must preserve loud failure for uncovered shapes
    by way of §5 step 4's diagnostic. FALSIFIER: any regenerated lower golden
    showing a non-ctor function deriving a pointer from a `__global_init`
    alloca.
-   **R-7. Over-broad promotion.** The predicate (package-scope VALUE
    binding, bound value NotConstant — §2.1 as amended) must not catch
    constant-bound lets (they keep the constant path — half (b) regression
    otherwise), nor class-scope `static` bindings beyond scope, nor
    NON-VALUE bindings [extended 2026-08-18, review round — reviewer #2
    S-1]: a `let ref`-shaped reference-category binding and any
    `AliasBinding` are excluded by the `ExprCategory::Value` test (aliases
    doubly so — check rejects runtime aliases,
    handle_alias.cpp:80-84). FALSIFIER: the §3 negative pins (existing let
    goldens byte-identical in the PR-diff audit) + the P-8 `let ref` probe
    (a promoted global for a non-value binding in any regenerated golden
    is the alarm).

---

## 7. Arbiters + discharge criteria (R9)

-   **Arbiters, named:** (i) the runner autoupdate fixpoint on the new
    lower goldens (a green regeneration IS the mechanism executing — R15);
    (ii) `bazel test //toolchain/...` + the R21 upstream-parity gate on CI;
    (iii) the conformance scoreboard — every floor claim in this plan
    quotes fork/conformance/out/scoreboard.json after regeneration, never
    an assertion; (iv) the W69b conformance program's runtime payload
    readback (runtime-computed per R16d, so a misrouted/zeroinit global
    changes observable output).
-   **W-069 (residue, half (a)) discharge criteria** [criteria (2) and
    (4) and the floor table renormalized 2026-08-18, review round —
    reviewer #2 S-3 and B-1]: (1) W69a's P-1/P-2/P-7 lower goldens green
    at fixpoint and P-6 resolved with its record; (2) the check-golden
    byte-equivalence audit clean **modulo declared churn (the P-5 restore
    and the P-6 flip), each landed by way of autoupdate per R16a**; (3) **the
    ledger acceptance test**: the restored cross-file runtime-bound
    `let g` split in
    check/testdata/match/choice_generic_payload_scrutinee.carbon
    (`imported_global`) green, with its lower-side pin; (4) BOTH W69b
    conformance programs — the single-file runtime arbiter AND the
    split-file cross-file runtime arbiter — PASS on a regenerated
    scoreboard at **95/0/29 over 124**; (5) decision-log landing note
    recording the §0.3 verdict, the lane choice, the divergence-register
    entry for the exported symbol shape, and the W5-S3b re-authoring
    undone; (6) work-items.json W-069 updated (DISCHARGE-STAGED under the
    R9 hedge until the landing scoreboard, the W-067/W-068 pattern). If
    §5 step 5 fires instead, W-069 stays OPEN and criteria (3)-(4) are
    replaced by the recorded blocker + `fail_` pins.
-   **Floor expectations per slice** [renormalized 2026-08-18, review
    round — B-1]: W69a **93/0/29 over 122** (no floor movement — goldens
    only) → W69h **93/0/29 over 122** (the byte-identical rerun IS the
    proof) → W69b **95/0/29 over 124** (+2 by addition) → W69c
    contingent, NO floor claim (goldens-only unless a program is added
    at that time). FAIL stays 0 throughout; zero SKIP flips claimed
    (§1); no bullet flips claimed — both additions deepen already-PASS
    bullets (sum-type consumption; Code organization: Importing).

---

## 8. Open questions for the coordinator (adjudicate BEFORE implementation)

-   **OQ-1 — cross-file RUNTIME arbitration versus the single-file harness.**
    runner.py compiles one file per program, so the cross-file half of the
    acceptance can be arbitrated at runtime only if the harness grows
    multi-unit (split-file) program support — the same limitation that
    keeps code_org/library_multifile_export.carbon SKIPped. Options:
    (a) extend the runner in a small pre-W69b harness slice (high leverage:
    also unblocks the Libraries SKIP as separate follow-up work; but it is
    a process/resource spend outside W-069's subsystem);
    (b) accept lower-golden arbitration for the cross-file half (external
    symbol + load pinned, exactly how upstream pins `var` imports) with the
    runtime arbiter exercising the same mechanism single-file, and W-069
    discharges at W69b. RECOMMENDATION: (a), as its own reviewed slice —
    but this is a genuine scope/resource fork, so it is asked, not
    auto-adopted.
-   **OQ-2 — same-file scope-in.** The ledger text says "cross-file", but
    the mechanism necessarily also fixes the SAME-file cross-function
    reference (identical CHECK, §1), and the single-file runtime arbiter
    depends on that half. Confirm the scope-in (recommended: yes; declining
    it would leave the conformance program unwritable under OQ-1(b)).
-   **OQ-3 — fidelity of the restored split.** The historical split bound
    `g` to the CONSTANT `P(i64).Neither`; a faithful restoration is half-
    (b) territory and does NOT arbitrate this item. The plan restores the
    split RUNTIME-bound (`MakeNeither()`) and keeps a constant-bound
    sibling as the boundary pin. Confirm this reading of "restoring the
    `let g` split" satisfies the ledger's acceptance sentence.
-   **OQ-4 (digest-grade, listed for visibility, default auto-adopt):**
    (i) the V-3a divergence-register entry for the fork-minted exported
    symbol shape `_C<name>.<package>[.<fp>]` for let-backed storage;
    (ii) touching upstream's lower/testdata/var/import.carbon for the P-6
    TODO flip (sanctioned route: autoupdate-regenerated, R16a); (iii) the
    conformance-bullet attachments named in §4.

## §8-A. Coordinator adjudications (2026-08-18, pre-review)

Adjudicated per the V-2 delegation (all three fall inside fork-internal
tooling scope and honest scope-extension territory — no language-design
fork, so none rises to a blocking user ask; all three ride the eventual
PR digest as veto-able records):

-   **OQ-1 → (a), extend the runner** with split-file multi-unit program
    support as its OWN small reviewed slice (W69h, "harness"), sequenced
    BEFORE W69b so the cross-file half is runtime-arbitrated per the
    house DIFF-1 standard. Grounds: runtime differential arbitration is
    the house bar for discharge-grade evidence (lower-golden pins are
    static); the extension is paid for once and immediately unblocks
    follow-up work on the Libraries SKIP
    (code_org/library_multifile_export.carbon) — high leverage inside
    the conformance mandate the fork charter already delegates
    [tightened 2026-08-18, review round — reviewer #2 N-3: the Libraries
    BULLET is already PASS by way of code_org/library_named_import.carbon;
    what W69h unblocks is only the PROGRAM-level SKIP→PASS flip for
    library_multifile_export.carbon, as separate follow-up — no bullet
    movement is at stake there]. Scope
    guard: W69h touches ONLY fork/conformance/runner.py + its
    --self-test + README conventions (no toolchain files), and W-069's
    discharge does not claim the Libraries bullet — that is separate
    follow-up.
-   **OQ-2 → YES, same-file scope-in confirmed.** The mechanism fixes
    both halves by construction and the single-file runtime arbiter
    depends on it; the ledger's "cross-file" wording is the surfaced
    SYMPTOM, not a scope fence. Recorded as an amended-at-W-069 scope
    note for the ledger (mirror the W-068 amendment-marker discipline).
-   **OQ-3 → CONFIRMED, the plan's reading is right.** The ledger's own
    residue sentence says "restoring a RUNTIME-`let`-based cross-file
    split is the acceptance test for the residue" — the runtime-bound
    restoration (`MakeNeither()`) IS the acceptance shape; the
    constant-bound sibling stays as the half-(b) boundary pin. A
    byte-faithful restoration of the historical constant-bound split
    would arbitrate nothing.
-   **OQ-4 (i)-(iii) → auto-adopted** as listed (digest-grade).

Slice order after adjudication: W69a (mechanism, scalar) → W69h
(harness, split-file programs) → W69b (choice shapes + restored split +
runtime cross-file arbiter) → W69c contingent (generic residue).

## Review-round amendments (2026-08-18)

Both adversarial plan reviews completed 2026-08-18. Reviewer #1
(mechanism): approve with amendments, no blocker. Reviewer #2
(completeness): one blocker + should-fixes + nits. All surviving findings
are folded into the sections above as dated in-place amendments (markers:
"[amended/renormalized/qualified/corrected/added/assigned/specified/
tightened 2026-08-18, review round]"); the §8-A adjudications stand
unchanged. Summary, with credit:

-   **B-1 (reviewer #2, BLOCKER — §4, §7):** the draft's §4/§7 floors
    predated §8-A's OQ-1(a) + W69h sequencing. Renormalized: W69b carries
    BOTH conformance programs (single-file runtime arbiter + split-file
    cross-file runtime arbiter, since W69h lands before it) with floor
    **95/0/29 over 124**; W69c's split-file trigger (ii) and its floor
    row are DELETED (W69c is goldens-only trigger-(i) residue, no floor
    claim unless a program is added then); the §7 floor ladder now reads
    W69a 93/122 → W69h 93/122 (byte-identical rerun) → W69b 95/124 →
    W69c contingent no-claim.
-   **S-1 (reviewer #2) + SF-3/NIT-3 (reviewer #1) — §2.1, §3 P-8,
    §6 R-7:** the promotion predicate is narrowed to VALUE bindings
    (`ExprCategory::Value`, the `ValueBindingPattern`-derived category);
    `let ref` gets probe P-8 pinning the tree's actual behavior;
    `AliasBinding` is safe because check rejects runtime aliases
    (`AliasRequiresConstantValue`, check/handle_alias.cpp:80-84); R-7's
    falsifier extended.
-   **S-2 (reviewer #2) + SF-5 (reviewer #1) — §4:** W69h now has a full
    slice block: runner.py + --self-test + README only; arbiter =
    self-test green AND a byte-for-byte 93/0/29-over-122 rerun; explicit
    no-flip proof (SKIP is an in-file marker, runner.py:183-185,
    320-321); conditional discharge + re-open clause; scope guard
    extended with "no new scoreboard fail-class keys"
    (fork_conformance.yaml:84-91).
-   **S-3 (reviewer #2) — §4 W69a, §7 criterion (2):** byte-equivalence
    is "clean modulo declared churn (the P-5 restore and the P-6 flip),
    each landed by way of autoupdate per R16a".
-   **S-4 (reviewer #2) — §4:** falsifier goldens assigned: R-1's
    (defining file + two importers + private-let subfile) to W69a; R-2's
    (two specifics reading different imported runtime lets) to W69b.
-   **S-5 (reviewer #2) — §3 P-10, §4 W69b:** whole-tuple/struct-typed
    runtime let consumed as `t.0` AND whole `t` cross-file added to the
    W69b probe/golden set; the class-typed subfile's consumption
    specified as a field read.
-   **S-6 (reviewer #2) — §1:** the control-flow-inside-functions
    constraint is ledger item W-036, not "the W-024-family TODO" —
    miscite corrected.
-   **S-7 (reviewer #2) — §3 negative pins:** the byte-equivalence
    obligation lands on the slice PR-diff audit over
    toolchain/**/testdata, not on goldens (which cannot assert about
    other files).
-   **SF-1 (reviewer #1) — §2.1 import branch, §3 P-2:** the import
    branch resolves by way of `SemIR::GetCanonicalFileAndInstId`
    (sem_ir/import_ir.cpp:29-58) — chases import chains AND peeks
    through `ExportDecl` re-exports — not single-hop `GetImportSource`.
    The counter-program, recorded: A defines the runtime let, B
    `export`-re-exports it, main imports B — a single hop lands on B's
    intermediate inst and mangles against the wrong IR, a silent
    external-symbol mismatch. P-2 gains the A/B/main subfile.
-   **SF-2 (reviewer #1) — §2.1 emission:** the binding inst lives in
    the file top block (check/testdata/let/import.carbon), not in
    `__global_init`'s body; the copy hook keys off the BOUND-VALUE inst
    id during the ctor's `BuildFunctionBody` (or an end-of-ctor registry
    sweep); registry entries the ctor never visits are LOUDLY demoted to
    the (a3) diagnostic at pre-pass time — never a silent zeroinit
    global.
-   **SF-3 (reviewer #1) — §2.1, §3 P-9:** the value-rep dispatch is
    stated in `ValueRepr::Kind` terms (sem_ir/type_info.h:21-41) with
    `IsCopyOfObjectRepr` (type_info.h:66): object-identical Copy →
    store/load; Pointer → W69b memcpy; None → no storage, empty value
    (probe P-9); non-identical Copy / Custom → (a3) diagnostic.
-   **SF-4 (reviewer #1) — §0.2 item 7, §0.3:** docs/design/
    README.md:1236-1249 ("Global constants and variables") cited —
    global `let` licensed, "there are currently no global variables"
    (provisional) — and the no-global-variables note folded into §0.3's
    honesty boundary for the var-shaped fork storage.
-   **NIT-2 (reviewer #1) — §4 W69a:** `MangleGlobalLetBinding`'s
    fingerprint input is the BINDING INST itself (`AnyBinding` has no
    pattern_id); mismatched inputs between sides would be an F8c-shaped
    silent name split.
-   **N-3 (reviewer #2) — §8-A:** the Libraries BULLET is already PASS
    (library_named_import); only the program-level SKIP→PASS is at
    stake, as separate follow-up.
-   **N-4 (reviewer #2) — §2.1:** class-scope `static` bindings (the
    other `UseGlobalInit` arm) stay out of scope; the crash persists
    there, not claimed, recorded honestly.
-   **N-5 (reviewer #2) — §5 step 6:** the mid-workstream STOP named:
    an upstream fix landing in a weekly merge between slices → STOP,
    reconcile, prefer upstream's mechanism.
-   **N-6 (reviewer #2) — §4 W69b:** the conformance arbitration recipe
    committed now: `RuntimeSeed(x) = x + 20`; expectations derived from
    seed arithmetic independent of the chain under test; concrete
    seed/expectation sketch stated for both programs.
-   **Ledger (fork/inventory/work-items.json W-069, reviewer #2 nits):**
    evidence cite var/import.carbon:46 corrected to :47; the notes'
    "re-authored to `var g`" sentence corrected to the tree + the
    W5-S3b record (the var re-author was structurally wrong and was
    fixed at ac1afa4 — the binding moved to the importing file as a
    local `let`); both marked "[corrected at the W-069 plan round]".

## Coordinator sign-off (2026-08-18)

The approval gate below is SATISFIED: both adversarial plan reviews ran
(reviewer #1, mechanism — approve with five amendments, no blocker, every
load-bearing citation verified against the tree; reviewer #2,
completeness — one blocker + six amendment-grade findings, the plan's
evidentiary core intact), all findings were folded as dated amendments by
a separate plan-fixer (no finding judged wrong), and §8's open questions
were adjudicated in §8-A before the reviews. **This plan is APPROVED for
implementation** in the amended slice order W69a → W69h → W69b → W69c
(contingent). The §5 ladder's STOP points and the V-2 veto digest list
below govern deviations. Veto-able.

## Approval gate

This plan does not authorize implementation. Per house protocol it goes to
TWO adversarial plan reviewers (reviewer #1 attacks §0's verdict and §2.1's
mechanism against the tree — the GetImportSource reachability for the
importer's NameRef inst, the value-rep dispatch claims, the mangler purity
assumption, with concrete counter-programs; reviewer #2 attacks
completeness — the §3 probe set for missing negatives, §4's byte-
equivalence claims, §7's floor arithmetic, and every file:line citation),
then the fixer folds surviving findings in as dated amendments, and the
coordinator answers §8 before W69a starts.

V-2 veto digest for this plan: (1) the §0.3 classification
(acknowledged-gap, full speed) + the §2.4 lane adoption (a1); (2) the §2.3
dual-use of (a3) as guard + fallback; (3) the §5 ladder as the only
sanctioned deviation paths (step 3(ii)'s import_ref amendment and step 2's
ctor-priority minting both STOP for adjudication); (4) OQ-4's three
digest items; (5) floor movement §7 (addition-only, no flips). Genuine
synchronous asks: §8 OQ-1/OQ-2/OQ-3.
