<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# FO-1 plan: the follow-ons that gate the held PRs, then their landings

**Status:** rev 1, 2026-11-02 -- the planner's draft, for the two plan reviews
of R29(c). Records only: this plan changes no toolchain, prelude, golden,
program or workflow file. It plans fork/ORCHESTRATION.md's Next actions items
10, 13, 15, 16 and 17 (trunk 03b40f7c5 :2427-2476, :2482-2491 and the lead
above item 1, :2273-2283) and the two drifts W-139 (PR 60) and W-352 (PR 56),
then the five landings of LAND-1's procedure (fork/land/land1-plan.md rev 8,
D-LAND-5, D-LAND-6, D-LAND-9 to D-LAND-12, D-LAND-20 and the landing-time
rulings (1) to (22)) as stages 13 to 17. PR 53 (SAFE-1) is out of scope: it
waits for the orchestrator's re-ruling of the C++ boundary question (W-148,
W-365, W-366), a separate workstream.

**Summary.** Every number below is container-local, EXPECTED, not of record
(R9), measured on detached worktrees under /dev/shm against trunk 03b40f7c5,
whose toolchain is c6c9d5fe3's (the install 0.0.0-0.dev+c6c9d5fe3), and read
against upstream's tip 68569d234 (fetched 2026-11-02 17:01 UTC, unchanged
since 14:01). Four findings decide the plan.

Item 10 is OP-2's, not SC-1's. A class `S` with `fn Next(self) ->
Core.Optional(Self);` in its own definition, with no template constraint at
all, is rejected with ``unable to monomorphize specific `<none>` `` on PR 57's
install and on the land simulation, and checks on trunk's, PR 56's, PR 60's
and the nightly's (section 0.2). The root: OP-2's `let Type: Destroy;` in the
private `OptionalStorage` (upstream's tip has `let Type: type;`) makes forming
`Core.Optional(S)` look up `DefaultOptionalStorage(S)`'s `Destroy`, and the
custom `Destroy` witness completes the class before it honors the class's own
`Destroy` impl, which monomorphizes `MaybeUnformed(S)` while `S` is incomplete.
A seven-line change to toolchain/check/custom_witness.cpp, made on PR 57's
branch, fixes it at that root (measured: the split passes, nothing else
changes; D-FO1-1).

W-139 is realigned the way upstream spells the mechanism: a call that passes
a checked-symbolic argument to a function whose `template` binding has
structural requirements is deferred to each specific, wrapped as CT-1's
`DeferCppCallOnSymbolicArgs` already wraps a symbolic C++ template argument in
a `TemplateInst` (upstream check/call.cpp:387-395 at 68569d234). Measured: a
checked generic calling a template-constrained function compiles and prints
7; an unsatisfying argument is reported as ``unable to monomorphize specific
`Caller(D)` `` with SC-1's notes (D-FO1-2). The commit needs CT-1's code, so it
follows the land-time merge of trunk into PR 60's branch, not precedes it.

W-352's in-place route keeps D-OP-4's signatures and F-015's API: two private
interfaces over the storage type, a fallback for every storage and a more
specialized impl for `DefaultOptionalStorage(T)` that compares the
`MaybeUnformed(T)` fields as `T` values. Measured with a counting probe: 14
`Copy` and 14 `Destroy` calls over nine comparisons become 0 and 0, in
concrete and in checked-generic code, on PR 56's, PR 57's and the land
simulation's toolchains, and OP-1's generic program still prints its
EXPECT. W-352's break condition is tested and does not fire (D-FO1-4).

Item 13 and note 7 are PR 59's: `choice C { A(... each x: i32) }` and a pack of
a padded element (`{.a: i32, .b: bool}` or `Core.Optional(i32)`) abort on PR 59
and on the PR 59 simulation, and the two fixes (W-367, a TODO in
handle_pack_expansion.cpp's `Pattern` case; W-368, the array-stride layout of
a pack in lower/type.cpp) are measured: the TODO is reported at 1:14, the
three padded-pack probes print 2, 7 and 7 as PR 66 does, and the gate stays
2004 of 2004 (D-FO1-5, D-FO1-6).

The landings (section 2.5 to 2.9) then follow LAND-1's procedure, each
follow-on first merging trunk into its own branch (D-LAND-12), so each trunk
landing is a merge with no refill. Expected container values: trunk's 1986 of
1986 and 193/0/15 over 208 (49 of 56 bullets) become 2003, 2006, 2011, 2029
and 2047 files gated, and 196/0/14 over 210, 201/0/17 over 218, 208/0/14
over 222, 218/0/13 over 231 and 228/0/13 over 241, with 50, 50, 50, 51 and 51
bullets (section 5).

## Contents

-   Section 0: audit (versions and states, the reproductions, the land
    simulations, collisions, programs, upstream's register, ids, disk)
-   Section 1: decisions D-FO1-1 to D-FO1-14
-   Section 2: spec, slice by slice and landing by landing
-   Section 3: the commits in order
-   Section 4: testdata matrix
-   Section 5: conformance deltas
-   Section 6: churn and collisions
-   Section 7: risks and rejected alternatives
-   Section 8: verification and what is not run
-   Hand-off notes
-   Appendix A: golden sources
-   Appendix B: conformance programs
-   Appendix C: the docs amendments
-   Appendix D: the records texts
-   Appendix E: the landings' fields (LAND-1 Appendix C rows)

Conventions. `trunk` is origin/trunk 03b40f7c5. `$P` is the planner's scratch
directory
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/fo1/planner,
`$CB` the arbiter's
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild,
`$T` trunk's install /home/user/carbon-build/carbon-trunk/install/bin/carbon,
`$N` the nightly
/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon.
The simulations are scratch commits on no branch, made in a detached worktree
/dev/shm/fo1-planner/wt2 and built one at a time in /dev/shm/fo1-planner/wt with
CB_BUILD_ROOT=/dev/shm/fo1-planner/builds (deleted with this plan's commit):
`sim60` d1d6d7031 (PR 60's head merged into trunk), `sim56` 7d06ec256 (PR 56's),
`sim57` 479ccea1e (PR 57's over sim56), `sim57x60` 47bf3cf0b (PR 60's over
sim57), `sim60x56` 81513bce3 and `sim60x57` d417713b5 (PR 56's then PR 57's over
sim60, the order items 15 and 16 land), `sim59` 11b45d0a8 (PR 59's head merged
into trunk), `sim66` 0ed25ea10 (PR 66's over sim59) and `sim59f` 8847649d8
(sim59 with W-367's and W-368's prototypes). Records conflicts in the
simulations took trunk's side, as VA-2's `mall` did (fork/variadics/va2-plan.md
section 8.7), and the README table was regenerated; code conflicts took the rule
each row of section 0.3 names. The placeholders of the records texts are
LAND-1's (its conventions table), and this plan adds `<sha-...>` for the slice
commits, each measured by `git rev-parse --short=9 HEAD` after the commit, and
`<rev>` for this plan's revision at sign-off. File:line cites name the sha they
were read at.

## §0 Audit

### §0.1 Versions and states

Measured 2026-11-02 17:01 UTC after `git fetch origin` and `git fetch upstream
trunk`; `git ls-remote origin` gives every held head as the task's list, and
upstream's trunk is 68569d234 ("Improve lexer and parser diagnostic locations
(#7990)", 2026-11-01).

| What | Value | Evidence |
| --- | --- | --- |
| trunk | 03b40f7c5, toolchain and testdata equal to c6c9d5fe3's | `git diff --name-only c6c9d5fe3 origin/trunk -- toolchain core` lists 0 files |
| trunk's install | 0.0.0-0.dev+c6c9d5fe3 | `$T version` |
| PR 60 (SC-1) | cc4daba00 on origin; the worktree /home/user/carbon-sc is at 40a76ab81, behind | `git ls-remote`; `git -C /home/user/carbon-sc rev-parse HEAD` |
| PR 56 (OP-1) | 9f12209d8; /home/user/carbon-op at 894139b34, behind | as above |
| PR 57 (OP-2) | e23113ba2; /home/user/carbon-op2 at a080c7886, behind | as above |
| PR 59 (VA-1) | b0822a744; /home/user/carbon-va at b0822a744 | as above |
| PR 66 (VA-2) | 43c8ab476; /home/user/carbon-va2 at 43c8ab476 | as above |
| PR 53 (SAFE-1) | 2407efa74 (out of scope) | as above |
| PR 60's install | 0.0.0-0.dev+866468cba, an ancestor of cc4daba00 with the same toolchain and core (one testdata file differs) | `git diff --name-only 866468cba cc4daba00 -- toolchain core ':!*/testdata/*'` lists 0 |
| PR 56's install | +5d9edb3e0, same toolchain and core as 9f12209d8 (3 testdata files differ) | as above |
| PR 57's install | +9f9ccd768, same toolchain and core as e23113ba2 | as above |
| PR 59's install | +88b1b5bd2, same toolchain and core as b0822a744 | as above |
| PR 66's install | +1517517eb, same toolchain and core as 43c8ab476 | as above |
| the nightly | 0.0.0-0.nightly.2026.10.12+62f1cc6, an oracle only (R30) | `$N version` |

The held installs predate LAND-1 (their merge bases with trunk are 8068151ed
for PR 60, 162c7e839 for PR 56, f67ab650d for PR 57 and 3eb7f36f0 for PR 59
and PR 66), so they measure each PR's own code, and the simulations measure the
code each landing will produce.

### §0.2 The reproductions

Probe files are in `$P/probes`, `$P/i10`, `$P/w139`, `$P/w352` and `$P/w368`;
each line is the first diagnostic or the program's output.

**Item 10.** The SC-1 split fails on `sim57x60` (with TP-1's S, section 0.3)
exactly as item 10 says (`$P/sim57x60/gate.log:1649-1700`): the split
`self_facet_in_signature_required` in
check/testdata/named_constraint/template_constraint.carbon reports
``unable to monomorphize specific `<none>` `` at `fn Next(self) ->
Core.Optional(Self);` (its :75:20) with the notes
`` `Core.MaybeUnformed(T as Core.Destroy)` evaluates to incomplete type
`Core.MaybeUnformed(S as Core.Destroy)` `` (optional.carbon:141, `var value:
MaybeUnformed(T);`), the same through maybe_unformed.carbon:14, and "class is
incomplete within its definition" at `class S`; the `fail_todo_` split of the
same file gains the same error at its :86:20. It does not fail on `sim60`
(trunk with PR 60 and S, no OP-2). The probe i10a.carbon, a class `S` with
`Core.Copy` and `Core.Destroy` impls and `fn Next(self) ->
Core.Optional(Self);`, no template constraint:

| Toolchain | i10a (method in the class) | i10b (the same signature outside the class) |
| --- | --- | --- |
| trunk (`$T`) | checks | checks |
| PR 56's install | checks | checks |
| PR 57's install | ``unable to monomorphize specific `<none>` `` | checks |
| PR 60's install | checks | checks |
| the nightly | checks | checks |
| `sim57x60` with S | ``unable to monomorphize specific `<none>` `` | checks |
| `sim57x60` with S and D-FO1-1's fix | checks, compiles, links and returns 0 | checks |

The `<none>` is the stringified impl specific (`StringifySpecific` pushes an
impl's entity name, which has none; toolchain/sem_ir/stringify.cpp:1436-1440),
the blanket `impl forall [T: Copy & Destroy] T as OptionalStorage where .Type =
DefaultOptionalStorage(T)` resolved for `S`. With a custom core whose
`OptionalStorage` says `let Type: type;` (upstream's spelling at the tip,
core/prelude/types/optional.carbon:17 at 68569d234) i10a checks on the same
toolchain (`$P/i10/e1.txt`), and with OP-2's explicit `impl forall [T: Copy &
Destroy] DefaultOptionalStorage(T) as Destroy` removed it still fails
(`$P/i10/e2.txt`); `let Type: type;` is not the fix, because a checked generic
that creates a `Core.Optional(T)` is then rejected again (``cannot access member
of interface `Core.Destroy` in type `Core.Optional(T as
Core.OptionalStorage)` `` on the custom core, on trunk and on PR 56's install,
`$P/i10/gen_*.txt`), which OP-2's W-170 exists to allow. The lookup that
completes the class is toolchain/check/custom_witness.cpp's `CanDestroyType`,
whose `TryToCompleteType` (:376-379 on `sim57x60`, :375-377 at e23113ba2) runs
before `CanDestroyClass` consults `HasClassKeyedImpl` (SL-1's R-12, :282-286).

**W-139.** The probes p1 (a checked `Caller[U: type](x: U)` calling `CallGet`,
whose `template T: HasGet` is a template constraint, with `C.Get` returning 7),
p2 (callers with a `D` lacking `Get` and an `E` whose `Get` returns `bool`), p3
(the definitions only) and n1 (the same call with a nominal interface):

| Toolchain | p1 | p2 | p3 | n1 |
| --- | --- | --- | --- | --- |
| trunk, the nightly | "unrecognized declaration introducer" (no `template constraint`) | the same | the same | checks |
| PR 60's install | ``cannot convert type `U` into type implementing `HasGet` `` at the definition (D-SC-6) | the same | the same | checks |
| `sim57x60` with W-139 | compiles, links, prints 7 | ``unable to monomorphize specific `Caller(D)` `` with "type `D` has no member named `Get` required by template constraint `HasGet`", and the same for `Caller(E)` with "member `Get` of type `E` does not match the signature required by template constraint `HasGet`" | checks | checks |

So passing a symbolic constant to a template parameter already works for a
nominal constraint, on the fork and in upstream's nightly; only SC-1's
structural check rejects it at the definition.

**W-352.** The probe count.carbon (`$P/w352`) holds `Counted`, whose `Copy` and
`Destroy` count into two variables, compares two non-empty Optionals and an
empty one nine times (`==`, `!=`, `<`, `<=`, `>`, `>=`, empty `==`, empty `<`,
self `==`) and prints the nine results and the two counts; gcount.carbon does
the six through checked generics `[T: Core.Eq & Core.Copy & Core.Destroy]` and
`[T: Core.Ordered & ...]`:

| Toolchain | count.carbon | gcount.carbon | OP-1's optional_compare_generic.carbon |
| --- | --- | --- | --- |
| trunk, the nightly | ``cannot access member of interface `Core.EqWith(...)` `` (no comparisons) | not run | not run |
| PR 56's install | `0 1 1 1 0 0 0 1 1 14 14` | not run | not run |
| PR 57's install | `0 1 1 1 0 0 0 1 1 14 14` | not run | not run |
| PR 56's, PR 57's and `sim57x60`'s toolchains with D-FO1-4's prelude (`--custom-core`) | `0 1 1 1 0 0 0 1 1 0 0` | `0 1 1 1 0 0 0 0` | `2 1 1 0 1 0`, its EXPECT |

**Item 13 (W-367).** h01.carbon is `choice C { A(... each x: i32) }` with an
empty `Run`:

| Toolchain | h01 |
| --- | --- |
| trunk | "expected identifier or `Self` after `.`" at 1:15 (trunk's lexer has no `...`), rc 1 |
| the nightly | "expected pattern" at 1:14, rc 1 |
| PR 59's install | rc 134, "CHECK failure at .../toolchain/lower/file_context.h:187: type_id.is_concrete(): Lowering symbolic type ... {kind: StructType ...}" |
| PR 66's install | the same CHECK, rc 134 |
| `sim59` with W-367 | ``semantics TODO: `pack expansion pattern in a choice alternative's parameter list` `` at 1:14, rc 1 |

**Note 7 (defect A, W-368).** VA-2's probes e09 (a pack of
`Core.Optional(i32)`), e11 (a pack of `{.a: i32, .b: bool}` constants) and e13
(the same built at run time), copied from
scratchpad/va2-impl/amend11/probes/c3:

| Toolchain | e09 | e11 | e13 |
| --- | --- | --- | --- |
| trunk | "expected identifier or `Self` after `.`" | the same | the same |
| the nightly | "expected pattern" | the same | the same |
| PR 59's install | rc 134, CHECK failure at lower/type.cpp:936 (the layout check) | the same | the same |
| `sim59` | the same, at lower/type.cpp:936 | the same | the same |
| PR 66's install | prints 2 | prints 7 | prints 7 |
| `sim59` with W-368 | prints 2 | prints 7 | prints 7 |

The expected values are each program's own arithmetic: e09 counts the two
`Some` of three, and e11 and e13 sum 1, 2 and 4.

### §0.3 The land simulations

`git merge-tree --write-tree --name-only` of each head against trunk, run in the
detached worktree (the conflicted files; records files are
fork/ORCHESTRATION.md, fork/decision-log.md, fork/gap-analysis.md,
fork/inventory/work-items.json and fork/conformance/README.md):

| Merge | Conflicted files outside the records files | Regions | Rule |
| --- | --- | --- | --- |
| PR 60 into trunk | docs/design/templates.md; toolchain/check/convert.cpp; toolchain/check/member_access.cpp; toolchain/check/merge.cpp | 1; 2; 1; 1 | templates.md: SC-1's paragraph in place of upstream's "However, if there are still use cases" paragraph, then DD-1's section "Templates in the 0.1 toolchain" (DD-1's state L, fork/designdocs/plan.md:4229-4231); convert.cpp: in `PerformAction(ConvertAction)` and `(ConvertToCategoryAction)` SC-1's check first, then A2's comment and `PendingBlock` (TP-1's M rule, fork/templates/plan.md:1395); member_access.cpp: `pointer_dereference.h` beside `structural_conformance.h`, alphabetical (TP-1's item 7); merge.cpp: `CheckRedeclExplicitParamsAfterSelfMatch` takes OV-4's `llvm::ArrayRef(...).drop_front()` operands with SC-1's two arguments (fork/overload/ov4-plan.md:1907, :2300) |
| PR 60 into trunk, not conflicted | merge.cpp's `CheckOverloadMemberParamsMatch` auto-merges without SC-1's two arguments at its two calls, which do not compile otherwise | 0 | OV-4's M: `/*new_specific_id=*/SemIR::SpecificId::None, /*found_error=*/nullptr` added to both calls (ov4-plan.md:1755-1756, :1795-1797) |
| PR 56 into trunk | docs/design/control_flow/loops.md; docs/design/error_handling.md | 1; 1 | loops.md by DR-1's M-a rule and C.7 (fork/direction/plan.md section 1.16); error_handling.md both amendments in date order, OP-1's (2026-10-13) then DR-1a's (2026-10-21) (fork/direction/plan.md:708) |
| PR 57 over `sim56` | lower/testdata/array/iterate.carbon; lower/testdata/for/break_continue.carbon; lower/testdata/for/for.carbon | 3; 3; 3, each CHECK lines only | GOLD-1, then DR-1a's m57 refills by autoupdate (fork/direction/plan.md:1566-1574) |
| PR 60 over `sim57` | the same four as PR 60 into trunk | the same | the same rules; merge.cpp's result is byte-identical to `sim60`'s |
| PR 56 then PR 57 over `sim60` | as PR 56 and PR 57 above | the same | the same; `sim60x57`'s toolchain, core and docs trees equal `sim57x60`'s (`git diff --stat` empty) |
| PR 59 into trunk | toolchain/check/handle_function.cpp | 1 | OV-4's rule: VA-1's pack gate (`PackExpansionPattern` TODO, `break`) before OV-4's default look-through (`DefaultValuePattern` to `binding_pattern_id`) (ov4-plan.md section 6.2, M's message) |
| PR 66 over `sim59` | toolchain/check/convert.cpp; toolchain/check/eval.cpp | 1; 1 | VA-2's recorded resolutions (its rule 1 and rule 2, va2-plan.md section 6.2; the `mall` scratch 3d99f544e): convert.cpp keeps TP-1's `SpliceInst` block, closed, then VA-2's pack segment; eval.cpp keeps both members, trunk's `diagnosed_non_constant_ids_` first |
| PR 66 over `sim59f` | toolchain/check/convert.cpp; eval.cpp; toolchain/lower/type.cpp | 1; 1; 1 | as above, and lower/type.cpp takes VA-2's side: its D-VA2-7 hunk is the same array-stride layout over C1's `element_id` and adds the heterogeneous pack's struct; W-367's hunk in handle_pack_expansion.cpp merges with VA-2's rewritten `Pattern` case without a conflict (it lands after VA-2's "pattern other than a parameter list or let" TODO) |

Built and gated (`$CB/build.sh`, `install.sh`, `gate.sh`, `conformance.sh`;
logs in `$P/<sim>/`):

| Tree | Build | Gate | Conformance | Failures and their class |
| --- | --- | --- | --- | --- |
| `sim60` (no composition) | 324 steps, 7 m 18 s | 1993 passed, 10 failed of 2003 | 193 PASS, 2 COMPILE-FAIL, 14 SKIP of 209; 49 bullets | eight template-constraint goldens fail on ``member name `X` names different entities in type `C` and in its constraint `HasWrap` `` (TP-1's C5 over SC-1, a plan-named failure: TP-1's S restores them, fork/templates/plan.md:5224-5235), and the two programs generics/structural_conformance.carbon and interop/cpp_structural_conformance.carbon for the same reason; fail_template_constraint_requirement_call.carbon and lower/template/template_constraint.carbon are refills |
| `sim60` with S (TP-1's S re-derived, section 2.5) | incremental | 2001 passed, 2 failed of 2003 | 195 PASS, 0 FAIL, 14 SKIP of 209; 50 bullets | the two refills: a note gains its location (`fail_requirement_through_template_instantiation.carbon:24:49` and four more) and lower IR names change (`@tuple.6f2.4af`); CHECK lines only |
| `sim57x60` with S | incremental | 2001 passed, 10 failed of 2011 | not run | item 10 (a defect, section 0.2) and nine refills: SV-1's choice/optional_pointer_payload, interop/cpp/stdlib/optional and variant; PR 60's two above; DR-1a's m57 three; TP-1's lower/template/for_range (CT-1's PR 57 composition, "its red set empty but TP-1's for_range refill") |
| `sim57x60` with S and D-FO1-1 | incremental | 2002 passed, 9 failed of 2011 | 206 PASS, 0 FAIL, 14 SKIP of 220; 50 bullets | the nine refills only; no `fail_`-prefix problem |
| `sim57x60` with S, D-FO1-1 and D-FO1-4's prelude | install only | 1995 passed, 16 failed of 2011 | not run | the nine and seven W-352 refills: check optional/compare.carbon (164 lines) and optional/fail_compare.carbon (one note's prelude line, optional.carbon:215 to :280), lower optional/compare.carbon, optional/destroy.carbon, primitives/optional.carbon, for/bindings.carbon and interop/cpp/pointer.carbon; CHECK lines only (`$P/w352/gate_w352.log`) |
| `sim57x60` with S, D-FO1-1 and W-139 | incremental | 2001 passed, 10 failed of 2011 | not run | the nine refills and fail_template_constraint_checked_binding.carbon, whose splits `fail_symbolic_arg` and `fail_require_in_interface_symbolic` now succeed (a `fail_`-prefix problem that W-139's renames resolve, section 2.2) |
| `sim59` | 324 steps, 6 m 37 s | 2004 passed, 0 failed of 2004 | 202 PASS, 0 FAIL, 14 SKIP of 216; 50 bullets | none |
| `sim59` with W-367 and W-368 | incremental | 2004 passed, 0 failed of 2004 | not re-run | none |

No CHECK failure or stack dump in any gate. TP-1's mutant M18 reverts S, so
`sim60` without S is M18's run: it turns the eight template-constraint goldens
and the two programs red, as TP-1's record predicts ("scv13: nine of SC-1's
goldens", fork/templates/plan.md:4648-4651), the ninth there being the refill
that TP-1's later rounds made a refill.

### §0.4 Collisions with trunk's landed code

| File | Landed code there (PR) | Slice | Collision |
| --- | --- | --- | --- |
| toolchain/check/call.cpp | CT-1's `IsCheckedSymbolicCppArg` and `DeferCppCallOnSymbolicArgs` (PR 64, :939-1003 on `sim57x60`); OV-4's resolution (PR 68); DR-1's return storage (PR 63, PR 65) | B (W-139) | W-139 extends `DeferCppCallOnSymbolicArgs`'s condition and adds a helper above its comment; it does not exist on PR 60's branch before M (`grep -c DeferCppCallOnSymbolicArgs` gives 0 at cc4daba00), which is why W-139 follows M (D-FO1-2). DR-1's test on the added lines: no `TemporaryStorage`, no `return_arg_id`, no `ConvertCallArgs` (0 of each, `$P/w139/W139v2.patch`), and 0 in SC-1's and VA-1's own call.cpp and convert.cpp lines |
| toolchain/check/convert.cpp | TP-1's A2 `PendingBlock`, `SpliceInst`, `AddConvertActionIfDependent` (PR 61); CT-1 (PR 64) | B, and PR 60's merge | the merge's two regions (section 0.3); W-139 does not touch convert.cpp (its first prototype there, a `ConvertAction` on a `TemplateInst`-wrapped self, failed deduction with "inconsistent deductions for value of generic parameter `T`", `$P/w139/p1.txt`, and was dropped) |
| toolchain/check/member_access.cpp | TP-1's C5 `LookupMemberInTemplateConstraint` (PR 61) | PR 60's merge | S (section 2.5) |
| toolchain/check/merge.cpp | OV-4's `GetOverloadMemberParamPatterns`, `CheckOverloadMemberParamsMatch` (PR 68) | PR 60's merge | section 0.3 |
| toolchain/check/handle_pack_expansion.cpp | none on trunk (PR 59's file) | D (W-367) | VA-2's C1 rewrites the `Pattern` case; W-367 merges into it without a conflict (section 0.3) |
| toolchain/lower/type.cpp | none in `BuildTypeForInst(PackType)` (PR 59's function) | D (W-368) | VA-2's D-VA2-7 hunk at PR 66's merge, one region, VA-2's side |
| toolchain/check/custom_witness.cpp | SL-1's `HasClassKeyedImpl` (trunk before LAND-1), OP-2's adapter arms (PR 57) | A (item 10) | none textual; the fix applies at e23113ba2 (`git apply --check`) and on `sim57x60` |
| core/prelude/types/optional.carbon | none on trunk since the cut but upstream's | C (W-352) | the block rewrite applies at 9f12209d8 and at e23113ba2 (measured equal to the installed cores' rewrite) |
| docs/design/templates.md | DD-1's and TP-1's section (PR 58, PR 61) | PR 60's merge | section 0.3 |
| docs/design/generics/template_constraints.md | none on trunk (PR 60's page) | B | none |

### §0.5 Conformance programs touched and new

The new programs, each with hand-derived EXPECT lines (R16 (d)), are in Appendix
B: generics/structural_conformance_checked_caller.carbon (W-139, EXPECT 7:
`Caller(c)` calls `CallGet(c)`, which returns `c.Get()`, 7 by `C`'s field),
stdlib/optional_compare_in_place.carbon (W-352, EXPECT the nine comparison
results from F-015's rules, docs/design/optional.md "Comparison", then 0 and 0
from comparison_operators.md's "should have no observable side-effects" as W-352
realizes it) and generics/variadics_padded_element.carbon (W-368, EXPECT 7
twice, 1 + 2 + 4 from constants and from run-time values). Touched: OP-1's
stdlib/optional_compare_payload.carbon, whose header comment says each
comparison reads a copy; its EXPECT does not change (the live count is 2 before
and after either way), and its comment is rewritten (Appendix B.4). Item 10 and
W-367 add goldens only.

### §0.6 Upstream's direction, R32 (a) and (c)

Read at 68569d234; the cut is c1e83b0b7 (`git merge-base origin/trunk
68569d234`), 150 upstream commits since.

Quoted at the tip (R32 (a)):

-   docs/design/generics/overview.md:375-379: "Likewise, it's allowed to pass a
    symbolic or template constant value to a checked or runtime parameter. _We
    have decided to support passing a symbolic constant to a template
    parameter, see [leads issue #2153: Checked generics calling
    templates](https://github.com/carbon-language/carbon-lang/issues/2153),
    but incorporating it into the design is future work._"
-   docs/design/generics/appendix-witness.md:151-156: "Carbon's planned
    approach to support calling a templated function from a checked-generic
    function, decided in
    [issue #2153](https://github.com/carbon-language/carbon-lang/issues/2153),
    relies on monomorphization. Trying to rely on witness tables would result in
    different semantics for calling the same function with the same types,
    depending on which witness tables were available at the callsite."
-   toolchain/check/call.cpp:386-395: "// Wrap symbolic template args in a
    `TemplateInst` so that all symbolic // arguments are treated as
    templates." over `SemIR::TemplateInst{.type_id = arg.type_id(), .inst_id =
    arg_id}`, then `AddDependentActionSplice(context, loc_id,
    SemIR::CallAction{...})`.
-   docs/design/expressions/comparison_operators.md:315-316 ("Additionally,
    these operations should have no observable side-effects.", `EqWith`) and
    :433-434 ("the members of an `OrderedWith` implementation should have no
    observable side-effects.").
-   core/prelude/types/optional.carbon:15-25: `private interface
    OptionalStorage { let Type: type; ... fn Get(value: Type) -> Self; ... }`,
    no comparison impls, `fn Get(self) -> T { return T.Get(self as T.Type); }`
    (:39-41).
-   docs/design/variadics.md:60-63 ("In a tuple literal pattern (such as a
    function parameter list), `...` iteratively matches the elements of the
    scrutinee tuple.") and :206-208 ("A pack expansion pattern "`...`
    _subpattern_" appears as part of a tuple pattern (or an implicit parameter
    list)"); no text on a choice alternative's parameter list (`git grep -n -i
    'choice\|alternative'` over variadics.md finds only the "Alternatives
    considered" heading, :36 and :975, and over proposals/p002240.md none).
-   The tip's parser: a choice alternative's parameter list is
    `StateKind::PatternListAsExplicit`
    (toolchain/parse/handle_choice.cpp:86-88), and `...` is a statement prefix
    only (handle_statement.cpp:54-58, `PackExpansionStart`), so `...` in a
    pattern list reports `ExpectedPattern` "expected pattern"
    (handle_expr.cpp:270); the nightly prints it at 1:14 for h01.

Upstream commits since the cut touching each slice's files (R32 (c), by sha
and subject; `git log c1e83b0b7..68569d234 -- <files>`):

| Slice | Files | Commits | Change to a stated mechanism or prelude signature |
| --- | --- | --- | --- |
| A, C | core/prelude/types/optional.carbon, comparison.carbon, destroy.carbon, check/custom_witness.cpp, comparison_operators.md | 05a7ecbd3 "Move `SubobjectDestroy` and `SelfDestruct` out of interface `Destroy` (#7942)"; 51e2c76a8 "Add a HasError helper to SpecificStore (#7970)"; f396762e2 "Fix destroying function-local `var`s of choice types (#7941)"; 6c1d2a86e "Fix crashes on impl lookup for bound method types (#7940)"; 947c1eb52 "Add a `Core.Array` class type, and make `array` refer to it. (#7892)" | 05a7ecbd3 changes `Destroy`'s signature (OP-2's `(self.value unsafe as T).(Destroy.SelfDestruct)()` is W-354's, UA-3's); optional.carbon is untouched (RG-1's H6.4 check holds) |
| B | generics/*.md, templates.md, check/call.cpp, deduce.cpp, convert.cpp, member_access.cpp, merge.cpp | 503f09037, db87a84b6, 0d3b606a5, 3af25cc1b, 7beb29f8b, 2c9739799, bf5d2a2ac, 62f1cc6a3, 230227264, 059ee7b9e, 4a8993af2, 947c1eb52, 5fed32a9a | none on issue 2153: overview.md and appendix-witness.md were last touched by 7134e23f2 (2026-09-29), an ancestor of the cut; db87a84b6 ("Improve tests and clarify design for observe equivalence chains (#7987)") clarifies `observe`, not template calls |
| D | variadics.md, p002240.md, check/handle_pack_expansion.cpp, lower/type.cpp, handle_choice.cpp (check and parse) | 68569d234; a045da8e6 "Document the discrepancy between checking and execution for variadics (#7963)"; 62f1cc6a3; 9fd28f730; 2ec4bab59 "Lex and parse support for `...` statements and `expand`. (#7832)" | a045da8e6 documents checking versus execution, not parameter lists; 2ec4bab59 parses `...` as a statement only |

Register entries DR-0 keeps that the slices discharge or touch (RG-1's
vocabulary, fork/register/rg1-plan.md):

-   W-139 is the DRIFT entry of RG-1's SC-1 block (rg1-plan.md section 2.H3
    and W-139's notes): discharged by Slice B for the call path, the generic
    class's `require` path narrowed to W-373 as NONE (D-FO1-3).
-   H5.4 (rg1-plan.md:951), OP-1's comparisons' `T.Copy` and `T.Destroy` per
    value, DRIFT with W-352: becomes ALIGNED by Slice C, its break condition
    "upstream's Optional gains comparisons or a matchable form (W-320)".
-   H6.4 (:961, optional.carbon lines that replace upstream's, NONE, W-355):
    stays NONE; Slice C adds lines after :205 and Slice A none to
    optional.carbon, so the H6.4 grep check is unchanged.
-   VA-1's block (H8): a NONE entry is added for W-367's refusal, "upstream
    silent on a pack expansion pattern in a choice alternative's parameter list;
    the tip's parser rejects it", its break condition "variadics.md or a
    proposal speaks to choice alternatives, or the tip's parser accepts the
    form", watched by W-355; W-368 adds none (a layout fix to upstream's array
    rule).

No new drift is found: Slice A's fix is fork code (SL-1's shortcut moved ahead
of upstream's completion in a fork-modified function), Slice B's spelling is
upstream's own, Slice C's private interfaces are prelude-private machinery and
Slice D refuses what upstream's parser refuses.

### §0.7 The id re-scan

`git fetch origin`, then over the 171 refs of
`git for-each-ref refs/remotes/origin refs/heads` and the 25 worktrees of
`git worktree list`, grep of each fork/inventory/work-items.json for
`"id": "W-3(6[7-9]|7[0-9])"`: only W-372 is filed (trunk's lineage and the two
scratch worktrees of this plan). W-367 to W-371 appear in plan texts only
(reservations: W-367 and W-368 to this work by D-LAND-13, W-369 and W-370
LAND-1's residue ids, unused by every landing (LAND-1's D-LAND-22 kept W-369
unused; no landing filed W-370), W-371 the next id of PR 53's realignment).
W-373 and W-374 appear on no ref in any file under fork/. So: W-367 (item 13)
and W-368 (defect A) are filed by Slice D; W-369 and W-370 stay reserved to
these landings' residues (D-FO1-12); W-373 is the next free id for anything else
and is taken by D-FO1-3; W-374 follows.

### §0.8 Disk

`df -h /home/user`: 1.9 G free of 252 G; /dev/shm 16 G. One build at a time
under /dev/shm/fo1-planner/builds (about 3 GB with its install), deleted with
this plan's commit; nothing was copied to /home/user.

## §1 Decisions

**D-FO1-1, item 10's root and carrier.** The defect is OP-2's (PR 57), not
SC-1's: SC-1's split only contains a class with a method returning
`Core.Optional(Self)`, and the probe without any template constraint fails on
PR 57's install alone (section 0.2). Root (R17): OP-2's `let Type: Destroy;`
makes the blanket `OptionalStorage` impl's specific for a class `C` look up
`DefaultOptionalStorage(C)`'s `Destroy` when `Core.Optional(C)` is formed, and
`CanDestroyType` completes a class before `CanDestroyClass` honors the class's
own `Destroy` impl (SL-1's R-12), so it monomorphizes
`DefaultOptionalStorage(C)`, whose `MaybeUnformed(C)` field needs `C` complete,
inside `C`'s own definition. The answer for a class with its own `Destroy`
impl never depended on completeness (the custom witness declines it either
way and impl lookup selects the declared impl), so the fix is to decline it
before completing: commit A1 on PR 57's branch (section 2.1), with the split
`incomplete_self_signature` in check/testdata/optional/destroy.carbon (OP-2's
golden) and its fill F-A1. Not upstream's `let Type: type;` (it removes the
checked-generic destruction OP-2 is for, measured), and not SC-1's split
reworded (it hides an IN form: a method returning `Core.Optional(Self)` is
ordinary code). The fix is under OP-2's review rule (D-FO1-9) and lands with
PR 57; at PR 60's landing, before PR 57's, the split passes (measured on
`sim60`), so no SC-1 commit is owed. _Break condition:_ A1's gate on PR 57's
branch, or on the land tree, changes a golden other than its own split's file,
or i10a still fails; then the root is re-measured and this decision is
re-planned before A1 is committed.

**D-FO1-2, W-139's mechanism, its order and its texts.** Upstream decided that
a symbolic constant may be passed to a template parameter and that the call
relies on monomorphization (overview.md:375-379, appendix-witness.md:151-156),
and its toolchain spells the deferral of a symbolic template argument as a
`TemplateInst` wrapper and a `CallAction` performed in each specific
(check/call.cpp:386-395). The fork already has that spelling for a C++ callee:
CT-1's `DeferCppCallOnSymbolicArgs` (PR 64). W-139 extends it, by condition, to
a Carbon callee with a `template` binding whose facet type has structural
requirements (`FacetTypeHasStructuralRequirements`), so the call is performed
once per specific of the checked caller, where SC-1's check runs on a concrete
self and reports a failure as ``unable to monomorphize specific `Caller(D)` ``
with SC-1's notes. No second spelling: one deferral path, upstream's
instruction. D-SC-6's definition-time rejection stays for the other entry
points a checked-symbolic self reaches (a conversion outside a call, and the
`require` of an impl in a generic class, D-FO1-3). The commit B1 needs CT-1's
function, which PR 60's branch lacks until trunk is merged into it, so on PR
60's branch the order is M (the land-time merge), S, B1, F-B1, D-B (docs and
records), not B1 first as item 15 orders it; R32 (e) holds either way (a new
commit on the PR's branch before it lands). The docs:
docs/design/generics/template_constraints.md's paragraph at :456-468 is
rewritten and a dated note follows RG-1's (Appendix C.1), and D-SC-6's
superseded text in fork/structural/plan.md gains a dated amendment. _Break
condition:_ B1's gate shows a change to a golden outside
named_constraint/ and lower/template/template_constraint.carbon, or a review
shows a call the deferral misses whose argument is checked-symbolic and whose
callee has such a binding (then the condition is widened, not guarded), or
upstream's tip changes call.cpp:386-395's spelling (then B1 follows it).

**D-FO1-3, W-139's shrink line: the generic class's `require`.** W-139's notes
also name an impl inside a generic class whose interface `require`s a template
constraint, whose self (`Box(T)`) is checked-symbolic at the class end. That is
not a template parameter receiving a symbolic constant, so issue 2153 does not
decide it, and deferring a `require` check per specific needs a hook at impl
specific resolution that B1 does not touch. It is filed as W-373 (NONE, watched
by W-355, Appendix D.3), and W-139 is discharged. _Break condition:_ upstream
states how a checked-symbolic self satisfies a requirement that needs a concrete
type, or lands interface/require.carbon's `fail_todo_implicit_self_impls`
(the D-SC-6 break condition); W-373 is then scheduled as a drift.

**D-FO1-4, W-352's in-place route.** Two private interfaces over the storage
type, `OptionalStorageEq(T)` and `OptionalStorageOrdered(T)`, each with a
blanket impl for `T.(OptionalStorage.Type)` that compares the values `T.Get`
returns and a more specialized impl for `DefaultOptionalStorage(T)` that
compares `(a.value unsafe as T)` with `(b.value unsafe as T)`, as RG-1's probe
did (rg1-plan.md section 4.8); the comparison impls' bodies call them. The impl
headers, the six function signatures and F-015's API table rows
(docs/design/optional.md:98-99) are unchanged; in a checked generic, the call
dispatches through the symbolic witness and is specialized at monomorphization
to the in-place impl (measured: gcount prints 0 copies and 0 destroys). Only
the pointer niche reaches the blanket impl, and only once `T*` is `Eq` (W-174),
where its `Get` is a primitive copy with no observable effect. Two routes were
measured and rejected: the bound `where .Type impls OptionalStorageEq`, which
keeps concrete code in place but rejects OP-1's generic program (its four
comparisons, "cannot access member of interface `Core.EqWith(...)`"), and a
`template` impl, which hits W-250's TODO across the library boundary. One
commit C1 on PR 56's branch with its fill F-C1, the program and the docs, then
PR 56's branch merged into PR 57's (C-M57) with its refill. W-352's break
condition (the route cannot keep D-OP-4's signatures or F-015's API) is tested
and does not fire. _Break condition:_ a review shows the blanket impl over an
associated type is an upstream impl rule's violation (an orphan or overlap rule
upstream states at its tip), or C1's gate changes a golden other than OP-1's,
OP-2's and SV-1's optional goldens; then W-352 gains `blocked_by` W-320 as its
own break condition says, and PR 56 and PR 57 wait.

**D-FO1-5, W-367: the refusal at the root.** In handle_pack_expansion.cpp's
`Pattern` case, a pack expansion pattern whose list is a choice alternative's
(the innermost scope is the choice's `ClassDecl` with no name scope,
`ScopeStack::PushForChoiceAlternative`) is refused with the TODO ``pack
expansion pattern in a choice alternative's parameter list``, with a `TODO:`
comment, pinned by the split `fail_todo_choice_alternative` in
check/testdata/variadics/fail_todo_slice.carbon (commit D1, fill F-D1), and
W-367 is filed in PR 59's branch's ledger by the records commit D-R beside it
(D-LAND-13). Not a parse-time guard (VA-1's parser accepts the form as
upstream's lexer and parser would once they parse pattern `...`; the check is
where VA-1 admits it), and not a lowering guard (that would hide the IN form).
Upstream is silent in its design and rejects the form at parse at its tip
(section 0.6), so the fork rule is the TODO, registered under W-355 as NONE.
_Break condition:_ upstream's design or proposal p002240 speaks to choice
alternatives, or a VA-2 change reaches a choice alternative's parameters (VA-2's
hand-off note 9).

**D-FO1-6, note 7's ruling: defect A is PR 59's and W-368 is a fix.** PR 59
aborts at its lower/type.cpp layout check (:936) on VA-1's own forms, a pack of
an element whose LLVM type is smaller than its Carbon array stride, as
section 0.2 measures. Under D-LAND-2 (an abort whose root lies in the PR's own
scope) and R33 (c), PR 59 takes the array-stride layout as commit D2 (VA-2's
D-VA2-7 hunk, rewritten for PR 59's `element_type_inst_id`, section 2.4) with
the lower split `padded_element` and the program of Appendix B.3, and W-368 is
filed beside it by D-R. PR 66's merge then takes VA-2's side of lower/type.cpp
(section 0.3). _Break condition:_ D2's gate on PR 59's branch changes a golden
other than lower/testdata/variadics/pack_expansion.carbon, or VA-2's land-time M
finds its D-VA2-7 hunk no longer covers PR 59's one-type pack.

**D-FO1-7, the landing order and the retargets.** Stages 13 to 17 continue
LAND-1's numbering: PR 60 (item 15), PR 56 then PR 57 (item 16), PR 59 then PR
66 (item 17). PR 57's base is retargeted from claude/carbon-fork-0-1-op to trunk
by the orchestrator after PR 56's phase 2 and confirmed with `pull_request_read`
before stage 15, and PR 66's from claude/carbon-fork-0-1-va after PR 59's phase
2 before stage 17 (D-LAND-11's precedent for PR 64 and PR 65). PR 53 is not
touched. FO-1 changes neither EH-C's (W-346) position on trunk's base after the
held PRs nor UA-3's after it. _Break condition:_ a slice that cannot be
completed (its break condition fires); the PRs after it in the same item wait
(PR 57 waits on PR 56, PR 66 on PR 59), the other items proceed, and the
orchestrator rules.

**D-FO1-8, branch-side land merges.** Each follow-on first merges trunk into its
own branch (a merge commit, never a rebase) with the land-time steps that change
code, pages or goldens, fills and gates them, reviews them under the PR's rule
and pushes them (D-LAND-12), so the trunk landing is D-LAND-6's procedure over
a head that already contains trunk: its merge is a fast-forward-equivalent tree
(`git merge --no-ff` still makes the merge commit), expected `<g0>` equal to
`<gn>` with no refill, and its records commit carries the records texts of
Appendix D and E. _Break condition:_ trunk moves between a branch's land merge
and its trunk landing (another landing, a weekly check's records); the branch
merges trunk again (a second land merge) before the trunk landing, and only a
conflict no rule of section 2 decides stops it.

**D-FO1-9, the review rules.** Each PR's own rule, quoted: SC-1, "the ONE
implementation review runs after the hosted verification of SC-1c is green
(R29(c))" (fork/structural/plan.md:2056-2057 at cc4daba00), never green while
Actions is disabled, so two, as its fill rounds ran; OP-1, "After commit 4, stop
for the implementation review of R29(c)", folded as two
(fork/optional/plan.md:3199 and :3296 at 9f12209d8); OP-2, "ONE review once
hosted verification is green; until then two, the OP-1 precedent"
(fork/optional2/plan.md:2964-2965 at e23113ba2); VA-1, "D, discharge, after two
implementation reviews: R29(c) drops to one only once hosted verification is
green, and GitHub Actions is disabled on the fork ... so it never is"
(fork/variadics/plan.md:6945-6948 at b0822a744); VA-2's land-time M, S-CT, F-M,
L-F and L are reviewed by its section 3 item 15's rule
(fork/variadics/va2-plan.md at 43c8ab476). So Slices A to D each take two fresh
implementation reviews and a separate fixer (R11), and each trunk landing takes
D-LAND-10's one fresh reviewer, two where the PR's plan asks a document review
of a land-time page edit (PR 60's template_constraints.md and templates.md, PR
56's optional.md: two, R29(c)'s document review). _Break condition:_ hosted
verification returns green before a slice's review; then the PR's own rule gives
one.

**D-FO1-10, the fix budgets and shrink lines.** Slice A: one code commit and its
fill; at most two fix commits after its reviews; no shrink (the defect blocks
PR 57). Slice B: one code commit, its fill, the docs and records; at most three
fix commits; the shrink line is D-FO1-3's (already taken for the `require`
path); a further shrink is not allowed (the call path is the drift). Slice C:
one commit, its fill and the program; at most two fix commits; past them,
W-352's break condition (D-FO1-4). Slice D: two code commits (W-367, W-368),
their fills, the program and the records; at most two fix commits each; no
shrink (both are aborts). _Break condition:_ a budget exhausted; the slice
stops, its PR waits and the orchestrator rules.

**D-FO1-11, what stops.** A landing or a slice stops (D-LAND-10) on: a moved
head; a conflict or region section 0.3 and section 2 do not name with a rule;
a gate failure that is not a refill section 2 names or a `fail_`-prefix
problem a named rename resolves; a refill that changes a non-CHECK line or a
golden no merged PR or slice explains (D-LAND-8); D-LAND-18's conformance stop
rule against section 5's rows; a mutant of D-LAND-20 that does not reproduce
its record; a review BLOCKER or MAJOR; a records text this plan does not give
(D-LAND-9); a break condition of D-FO1-1 to D-FO1-10. Every stop returns the
difference to the orchestrator, who rules under R29. _Break condition:_ none.

**D-FO1-12, ids.** W-367 (item 13) and W-368 (defect A), D-LAND-13's
reservations, are filed on PR 59's branch by D-R and reach trunk with PR 59;
W-373 (D-FO1-3) is filed on PR 60's branch by B-R; W-369 and W-370 stay
reserved for a residue a FO-1 landing finds, filed in trunk's ledger by that
landing's records commit, otherwise unused; anything else takes W-374 onward
after a re-scan. _Break condition:_ any of these filed elsewhere first; then
the next free id after a re-scan, recorded in the commit.

**D-FO1-13, the register entries.** FO-1's records commits write: W-139's
discharge note and W-373's NONE entry (B-R), H5.4's verdict ALIGNED with W-352's
discharge note (C-R), and the NONE entry for W-367's refusal (L59), each in
RG-1's vocabulary with its break condition and W-355 as its item, and each
re-checked by the weekly upstream check's quote and grep scripts; the rows of
fork/register/rg1-plan.md's tables and rg1-checks.tsv gain them in those
commits, on each branch after its land merge brings the register files
(Appendix D.6). _Break condition:_ the weekly check
classifies one of them otherwise; its records rule.

**D-FO1-14, the conformance and gate expectations.** The landings' expected
values are section 5's, computed from the simulations' measured counts plus
the FO-1 programs and splits, and D-LAND-18's stop rule applies to them as
LAND-1's section 4 rows. _Break condition:_ as D-LAND-18.

## §2 Spec

Every commit below: `--author='jmann345 <jerrymannstan@gmail.com>'`,
`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com`, a new
commit (never an amend, rebase or force-push), explicit paths only (R20), a
prek fixpoint on its files first (`SKIP=fix-cc-deps,check-build-graph,
check-bazel-mod-deps,forbid-llvm-googletest uvx prek run --files <paths>`,
XDG_CACHE_HOME under the actor's scratch), R31's counts of every markdown file
it edits before the edit, after it and after prek in its message, and the
message ending after a blank line with the session's two trailers. Each build
is `$CB/build.sh` and `$CB/install.sh` on the branch's worktree with
CB_BUILD_ROOT under /dev/shm (one build per role, deleted after), each gate
`$CB/gate.sh`, each fill `$CB/autoupdate.sh` on exactly the files the gate
names, to its fixpoint (R16, R26), and each conformance run `$CB/conformance.sh`
with XDG_CACHE_HOME under the actor's scratch. The held worktrees under
/home/user are behind their pushed heads (section 0.1): each slice works in a
fresh worktree of the pushed head, never in another role's.

### §2.1 Slice A: item 10 on PR 57 (OP-2)

Branch claude/carbon-fork-0-1-op2 at e23113ba2 (PR 57). Commit A1, "OP-2 fix:
a class with its own Destroy impl is not completed by the Destroy witness
(item 10)", changes toolchain/check/custom_witness.cpp and
toolchain/check/testdata/optional/destroy.carbon (the source of the new split,
Appendix A.1, with no CHECK line). The code, measured on `sim57x60` and applying
to e23113ba2 (`git apply --check`; `$P/i10/F1.patch`):

<!-- google-doc-style-ignore -->

```diff
@@ static auto CanDestroyType(Context& context, SemIR::LocId loc_id,
     return DestroyFormat::NoDestroy;
   }

+  // Fork (OP-2, item 10): a class that declares its own `Destroy` impl is
+  // destroyed by that impl, never by the synthesized witness (`CanDestroyClass`,
+  // SL-1's R-12), so whether its type is complete does not decide the answer.
+  // It is not completed here: `OptionalStorage.Type` is `Destroy`, so forming
+  // `Core.Optional(C)` looks up `DefaultOptionalStorage(C)`'s `Destroy` where
+  // `C` may still be incomplete, as in a method of `C` returning
+  // `Core.Optional(Self)`.
+  if (auto class_type = inst.TryAs<SemIR::ClassType>();
+      class_type && HasClassKeyedImpl(context, *class_type,
+                                      SemIR::CoreInterface::Destroy,
+                                      /*outside_core_only=*/false)) {
+    return DestroyFormat::NoDestroy;
+  }
+
   // Incomplete types can not be destroyed.
   auto type_id = context.types().GetTypeIdForTypeInstId(inst_id);
   if (!TryToCompleteType(context, type_id, loc_id)) {
```

<!-- google-doc-style-resume -->

`HasClassKeyedImpl` is declared above `CanDestroyType` (:225 at e23113ba2).
The `partial` query keeps the synthesized witness: its instruction is a
`PartialType`, not a `ClassType`, so it is not declined here, as
`CanDestroyClass`'s own shortcut excepts it. Commit F-A1, "OP-2 fix fill:
autoupdate item 10's split on the container arbiter", runs autoupdate on
check/testdata/optional/destroy.carbon; the predicted CHECK-relevant lines are
none: the split checks with no diagnostic and has no dump range, so the fill
adds nothing for it (if autoupdate adds a line, it is reviewed as a prediction
miss before the commit). The gate after F-A1 on PR 57's branch: every golden
passes; predicted unchanged elsewhere (measured on `sim57x60`: the fix changed
no file but the one SC-1 split's). Records commit A-R on the same branch: the
fold record in fork/optional2/plan.md (Appendix D.1) and the decision-log
paragraph of Appendix D.2, item 10's evidence, no ledger id (item 10 is a
defect of OP-2's own scope, fixed before it lands; D-LAND-2's class).

### §2.2 Slice B: W-139 on PR 60 (SC-1)

Branch claude/carbon-fork-0-1-sc at cc4daba00 (PR 60), after the land-time
merge M60 of section 2.5 (D-FO1-2's order). Commit B1, "SC-1 fix: a checked
generic's call of a template-constrained function is checked per specific
(W-139; leads issue 2153)", changes toolchain/check/call.cpp and the test
sources of Appendix A.2. The code, measured on `sim57x60` with S (the prototype
put the helper between `DeferCppCallOnSymbolicArgs`'s comment and its
definition; B1 puts it above the comment, which gains the sentence shown):

<!-- google-doc-style-ignore -->

```diff
@@ static auto IsCheckedSymbolicCppArg(Context& context, SemIR::InstId arg_id)
+// Fork (SC-1, W-139): returns whether `callee_id` is a function with a
+// `template` binding constrained by a `template constraint`, whose structural
+// requirements can be checked only for a concrete argument.
+static auto CalleeHasStructuralTemplateBinding(Context& context,
+                                               SemIR::InstId callee_id)
+    -> bool {
+  auto callee = GetCallee(context.sem_ir(), callee_id);
+  auto* callee_fn = std::get_if<SemIR::CalleeFunction>(&callee);
+  if (!callee_fn) {
+    return false;
+  }
+  const auto& function = context.functions().Get(callee_fn->function_id);
+  if (!function.generic_id.has_value()) {
+    return false;
+  }
+  for (auto binding_id : context.inst_blocks().Get(
+           context.generics().Get(function.generic_id).bindings_id)) {
+    auto binding = context.insts().TryGetAs<SemIR::SymbolicBinding>(binding_id);
+    if (binding &&
+        context.entity_names().Get(binding->entity_name_id).is_template &&
+        FacetTypeHasStructuralRequirements(context, binding->type_id)
+            .has_value()) {
+      return true;
+    }
+  }
+  return false;
+}
+
 // A call to an imported C++ function whose argument is a value of a symbolic
 // type that is not template-dependent, such as a checked generic's `x: T`, or
 // is such a type, as the `T` of `Cpp.Twice(T, x)`, cannot be resolved by Clang
 // until the type is known. As for a C++ template name applied to a symbolic
 // argument (`PerformCallToNonFunction`), the call is deferred as a `CallAction`
 // that each specific performs once its arguments' types are concrete
 // (`ActionIsPerformable`); a type argument is wrapped in a `TemplateInst`, as
-// there. Returns `None` if the call is not such a call.
+// there. Fork (SC-1, W-139): so is a call that passes such an argument to a
+// function with a `template` binding constrained by a `template constraint`:
+// a symbolic constant passed to a template parameter relies on
+// monomorphization (leads issue 2153; generics/overview.md and
+// generics/appendix-witness.md). Returns `None` if the call is not such a call.
 static auto DeferCppCallOnSymbolicArgs(Context& context, SemIR::LocId loc_id,
                                        SemIR::InstId callee_id,
                                        llvm::ArrayRef<SemIR::InstId> arg_ids,
                                        bool is_desugared) -> SemIR::InstId {
   if (llvm::none_of(arg_ids,
                     [&](SemIR::InstId arg_id) {
                       return IsCheckedSymbolicCppArg(context, arg_id);
                     }) ||
-      !std::holds_alternative<SemIR::CalleeCppOverloadSet>(
-          GetCallee(context.sem_ir(), callee_id))) {
+      (!std::holds_alternative<SemIR::CalleeCppOverloadSet>(
+           GetCallee(context.sem_ir(), callee_id)) &&
+       !CalleeHasStructuralTemplateBinding(context, callee_id))) {
     return SemIR::InstId::None;
   }
```

<!-- google-doc-style-resume -->

call.cpp gains `#include "toolchain/check/structural_conformance.h"` in the
alphabetical place (it is already included on `sim57x60`, from SC-1's
call.cpp hunk; B1 adds it only if M's tree lacks it). D-SC-6's branch in
structural_conformance.cpp (:568-580 at cc4daba00) keeps its code; its comment
gains, after "a checked-symbolic self never satisfies a structural
requirement.", the sentence "A call that passes one to a `template` binding is
deferred to each specific before it reaches here (call.cpp,
`DeferCppCallOnSymbolicArgs`, W-139)." No other toolchain file changes.

Test sources (Appendix A.2): in
check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon
the splits `fail_symbolic_arg` and `fail_require_in_interface_symbolic` are
renamed `symbolic_arg` and `require_in_interface_symbolic`, their comments
rewritten, and two splits are added, `fail_symbolic_arg_unsatisfied` and
`fail_symbolic_arg_mismatch`; lower/testdata/template/template_constraint.carbon
gains the split `checked_caller`. Commit F-B1, "SC-1 fix fill: autoupdate
W-139's splits on the container arbiter", fills those two files. Predicted
CHECK-relevant lines (measured on the prototype's p2, `$P/w139/p2v2.txt`):
`fail_symbolic_arg_unsatisfied` gets, at the call `Caller(d)`, ``error: unable
to monomorphize specific `Caller(D)` [ResolvingSpecificHere]``, at `CallGet(x)`
in `Caller` ``note: cannot convert type `D` into type implementing `HasGet` ``,
then ``note: type `D` has no member named `Get` required by template
constraint `HasGet` ``, ``note: requirement declared here`` at the requirement
`fn`, and ``note: while deducing parameters of generic declared here`` at
`CallGet`; `fail_symbolic_arg_mismatch` gets the same error for `Caller(E)`
with ``note: member `Get` of type `E` does not match the signature required by
template constraint `HasGet` `` at `E.Get`; the renamed splits have no
diagnostic; `checked_caller`'s IR has a `Caller` specific for `C` calling a
`CallGet` specific for `C` (no call to a symbolic function remains). The gate
after F-B1 on the branch: every golden passes (measured on the land tree:
fail_template_constraint_checked_binding.carbon's two `fail_`-prefix problems
are the only failures B1 adds, which the renames resolve).

The program generics/structural_conformance_checked_caller.carbon (Appendix
B.1) is in B1. Commit D-B, the docs, rewrites template_constraints.md's
paragraph and adds a dated note after RG-1's (Appendix C.1), and amends D-SC-6
in fork/structural/plan.md (Appendix C.2). Commit B-R, the records (Appendix
D.3): W-139's discharge note, W-373 filed, the clause of the gap row
"Generics: Template-style structural conformance to nominal constraints", SC-1's
decision-log paragraph, the register rows (Appendix D.6).

### §2.3 Slice C: W-352 on PR 56 (OP-1), merged into PR 57

Branch claude/carbon-fork-0-1-op at 9f12209d8 (PR 56). Commit C1, "OP-1 fix:
Core.Optional compares its payloads in place (W-352)", changes
core/prelude/types/optional.carbon, the comment of
fork/conformance/programs/stdlib/optional_compare_payload.carbon (Appendix
B.4), the new program stdlib/optional_compare_in_place.carbon (Appendix B.2)
and the README table (`runner.py --update-readme-table`). The prelude text,
measured on PR 56's, PR 57's and `sim57x60`'s toolchains with `--custom-core`
(`$P/w352/w352_block.carbon`, applied by `$P/w352/w352.py` from
`final impl forall [T: Destroy & OptionalStorage & Eq]` through the end of the
`OrderedWith` impl), replaces OP-1's two impls; OP-1's comment above them
(:206-214 at 9f12209d8, "Each function tests `HasValue()` before it calls
`Get()` ... `Get()` returns a copy, destroyed by the end of the call, so
`Destroy` is in the bound") becomes the text of the first comment block below,
whose first sentence keeps OP-1's semantics paragraph verbatim up to "never
read.":

<!-- google-doc-style-ignore -->

```carbon
// Fork (OP-1, F-015, docs/design/optional.md): comparison when `T` compares,
// with the semantics of C++ `std::optional`'s relational operators and Rust's
// `Option`. Two empty values are equal; an empty and a non-empty value are
// not; two non-empty values compare as their values do under `T`'s own
// operator; and an empty value orders before every non-empty one. Each
// function tests `HasValue()` before it reads a value, so the storage of an
// empty operand is never read.
//
// Fork (OP-1, W-352): the payloads are compared in place, with no `Copy` or
// `Destroy` of `T` per operand, as comparison_operators.md asks of `EqWith`
// and `OrderedWith` ("should have no observable side-effects"). Each storage
// compares through these private interfaces: the default storage reads its
// `MaybeUnformed(T)` field as a `T` value; any other storage, which in 0.1 is
// only the pointer niche, whose `T*` is neither `Eq` nor `Ordered` (W-174),
// compares the values `T.Get` returns, a primitive copy for a pointer.
private interface OptionalStorageEq(T: Destroy & OptionalStorage & Eq) {
  fn PayloadEqual(a: Self, b: Self) -> bool;
  fn PayloadNotEqual(a: Self, b: Self) -> bool;
}

impl forall [T: Destroy & OptionalStorage & Eq]
    T.(OptionalStorage.Type) as OptionalStorageEq(T) {
  fn PayloadEqual(a: Self, b: Self) -> bool { return T.Get(a) == T.Get(b); }
  fn PayloadNotEqual(a: Self, b: Self) -> bool {
    return T.Get(a) != T.Get(b);
  }
}

impl forall [T: Copy & Destroy & Eq]
    DefaultOptionalStorage(T) as OptionalStorageEq(T) {
  fn PayloadEqual(a: Self, b: Self) -> bool {
    return (a.value unsafe as T) == (b.value unsafe as T);
  }
  fn PayloadNotEqual(a: Self, b: Self) -> bool {
    return (a.value unsafe as T) != (b.value unsafe as T);
  }
}

private interface OptionalStorageOrdered(T: Destroy & OptionalStorage & Ordered) {
  fn PayloadLess(a: Self, b: Self) -> bool;
  fn PayloadLessOrEquivalent(a: Self, b: Self) -> bool;
  fn PayloadGreater(a: Self, b: Self) -> bool;
  fn PayloadGreaterOrEquivalent(a: Self, b: Self) -> bool;
}

impl forall [T: Destroy & OptionalStorage & Ordered]
    T.(OptionalStorage.Type) as OptionalStorageOrdered(T) {
  fn PayloadLess(a: Self, b: Self) -> bool { return T.Get(a) < T.Get(b); }
  fn PayloadLessOrEquivalent(a: Self, b: Self) -> bool {
    return T.Get(a) <= T.Get(b);
  }
  fn PayloadGreater(a: Self, b: Self) -> bool { return T.Get(a) > T.Get(b); }
  fn PayloadGreaterOrEquivalent(a: Self, b: Self) -> bool {
    return T.Get(a) >= T.Get(b);
  }
}

impl forall [T: Copy & Destroy & Ordered]
    DefaultOptionalStorage(T) as OptionalStorageOrdered(T) {
  fn PayloadLess(a: Self, b: Self) -> bool {
    return (a.value unsafe as T) < (b.value unsafe as T);
  }
  fn PayloadLessOrEquivalent(a: Self, b: Self) -> bool {
    return (a.value unsafe as T) <= (b.value unsafe as T);
  }
  fn PayloadGreater(a: Self, b: Self) -> bool {
    return (a.value unsafe as T) > (b.value unsafe as T);
  }
  fn PayloadGreaterOrEquivalent(a: Self, b: Self) -> bool {
    return (a.value unsafe as T) >= (b.value unsafe as T);
  }
}

final impl forall [T: Destroy & OptionalStorage & Eq]
    Optional(T) as EqWith(Optional(T)) {
  fn Equal(self, other: Optional(T)) -> bool {
    if (self.HasValue() != other.HasValue()) {
      return false;
    }
    if (not self.HasValue()) {
      return true;
    }
    return T.Type.(OptionalStorageEq(T).PayloadEqual)(self as T.Type,
                                                      other as T.Type);
  }
  fn NotEqual(self, other: Optional(T)) -> bool {
    if (self.HasValue() != other.HasValue()) {
      return true;
    }
    if (not self.HasValue()) {
      return false;
    }
    return T.Type.(OptionalStorageEq(T).PayloadNotEqual)(self as T.Type,
                                                         other as T.Type);
  }
}
```

<!-- google-doc-style-resume -->

The `OrderedWith` impl's four functions keep OP-1's tests and order and return
`T.Type.(OptionalStorageOrdered(T).PayloadLess)(self as T.Type, other as
T.Type)` and the like (`$P/w352/w352_block.carbon`, verbatim). The `Destroy` in
the impls' bounds stays: it is part of the frozen header
(docs/design/optional.md:98-99), and the fallback impl's `T.Get` copies need it.
The line `private interface OptionalStorageOrdered(T: Destroy & OptionalStorage
& Ordered) {` is 81 columns; the commit wraps it after `&` (prek's formatter
does not touch `.carbon`, and `carbon format` is not run). Commit F-C1, "OP-1
fix fill: autoupdate W-352's goldens on the container arbiter", fills what the
gate names on PR 56's branch; predicted there:
check/testdata/optional/compare.carbon (the SemIR of the comparison impls) and
check/testdata/optional/fail_compare.carbon (one note's prelude line, :215 to
the line of the `final impl ... EqWith` after C1),
lower/testdata/optional/compare.carbon and
lower/testdata/primitives/optional.carbon (the lowered impls and the prelude's
IR names), plus any golden that prints a line of optional.carbon after :205;
measured on the land tree: those and lower optional/destroy.carbon,
for/bindings.carbon and interop/cpp/pointer.carbon, CHECK lines only. A golden
outside OP-1's, OP-2's, SV-1's and those three lower files stops C1 (D-FO1-4's
break condition).

Then on PR 57's branch (claude/carbon-fork-0-1-op2): C-M57, "OP-2: merge OP-1's
W-352 fix (R32 (e))", merges PR 56's head at F-C1 into PR 57's branch after A1,
F-A1 and A-R; its conflicts are expected in fork/ records only (OP-2's own
optional.carbon edits are after :275 and at :15, :18, :40-48, which C1 does not
touch: measured, C1's block rewrite applies to e23113ba2's file as to
9f12209d8's). F-C-M57 refills what PR 57's gate then names (predicted: OP-2's
goldens that print optional.carbon lines and the comparison impls, among the
seven of the land tree's W-352 set). Commit C-R, W-352's discharge note, H5.4's
verdict, the decision-log paragraph and optional.md's amendment (Appendix C.3,
D.4), is made on PR 56's branch after its land merge M56 (section 2.6), because
W-352 and the register files exist only on trunk (RG-1's PR 67): `git show
9f12209d8:fork/inventory/work-items.json` has no W-352. It reaches PR 57 with
trunk at M57.

### §2.4 Slice D: item 13 (W-367) and note 7 (W-368) on PR 59 (VA-1)

Branch claude/carbon-fork-0-1-va at b0822a744 (PR 59). Commit D1, "VA-1 fix: a
pack expansion pattern in a choice alternative's parameter list is a TODO
(W-367)", changes toolchain/check/handle_pack_expansion.cpp and adds the split
of Appendix A.3 to check/testdata/variadics/fail_todo_slice.carbon, after
`fail_todo_interface_function`. The code, measured on `sim59` and applying to
b0822a744:

<!-- google-doc-style-ignore -->

```diff
@@ auto HandleParseNode(Context& context, Parse::PackExpansionStartId node_id)
                             "pack expansion pattern outside an explicit "
                             "parameter list");
       }
+      // Fork (VA-1, W-367): a choice alternative's parameter list is an
+      // explicit parameter list too, checked in the alternative's own scope
+      // (`ScopeStack::PushForChoiceAlternative`, the choice's `ClassDecl` with
+      // no name scope), but an alternative's parameters are its payload's
+      // fields, which a pack cannot be yet.
+      // TODO: Support a pack expansion pattern in a choice alternative's
+      // parameter list, or diagnose it as the design decides.
+      if (auto scope_inst_id = context.scope_stack().PeekInstId();
+          scope_inst_id.has_value() &&
+          context.insts().Is<SemIR::ClassDecl>(scope_inst_id) &&
+          !context.scope_stack().PeekNameScopeId().has_value()) {
+        return context.TODO(node_id,
+                            "pack expansion pattern in a choice "
+                            "alternative's parameter list");
+      }
       // Fork (VA-1, D-VA-5): an interface's function is matched by the
       // functions of its impls, and the thunk that adapts one to the other
       // does not clone a pack expansion pattern yet.
```

<!-- google-doc-style-resume -->

A class's own function is checked with the class's name scope on the scope stack
(`PushForEntity`, a name scope), and a function's parameters in the scope
`DeclNameStack::PushScopeAndStartName` pushes (no instruction), so only the
alternative scope matches; a second alternative's list is entered by
`HandleParseNode(ChoiceAlternativeListCommaId)` with the same scope kind
(handle_choice.cpp:924-933 on `sim59`). Commit F-D1 fills
fail_todo_slice.carbon. Predicted CHECK lines (measured,
`$P/probes/h01_w367.txt`): ``// CHECK:STDERR:
fail_todo_choice_alternative.carbon:[[@LINE+4]]:14: error: semantics TODO: `pack
expansion pattern in a choice alternative's parameter list` [SemanticsTodo]``,
the source line, the caret line `^~~` under `...`, and the empty
`// CHECK:STDERR:` line, as the file's other TODO splits read.

Commit D2, "VA-1 fix: a pack is laid out at its element's array stride
(W-368)", changes toolchain/lower/type.cpp, adds the split of Appendix A.4 to
lower/testdata/variadics/pack_expansion.carbon and the program of Appendix B.3.
The code, measured on `sim59` and applying to b0822a744:

<!-- google-doc-style-ignore -->

```diff
@@ static auto BuildTypeForInst(FileContext& context, SemIR::PackType inst)
     -> LoweredTypes {
   auto arity = context.sem_ir().GetZExtIntValue(inst.arity_id);
   CARBON_CHECK(arity, "Lowering pack type of unknown arity");
-  return {llvm::ArrayType::get(
-              context.GetType(context.sem_ir().types().GetTypeIdForTypeInstId(
-                  inst.element_type_inst_id)),
-              *arity),
-          nullptr};
+  // Fork (VA-1, W-368): a pack is laid out as an array of its element type,
+  // each element at the array stride of that type, as `BuildTypeForInst` for
+  // an `ArrayType` lays out its elements and `ObjectLayout::ForArray` computes
+  // the pack's size (check/type_completion.cpp).
+  auto elem_type_id = context.sem_ir().types().GetTypeIdForTypeInstId(
+      inst.element_type_inst_id);
+  auto stride = context.sem_ir()
+                    .types()
+                    .GetCompleteTypeInfo(elem_type_id)
+                    .object_layout.ArrayStride();
+  auto* elem_type = context.GetType(elem_type_id);
+  auto elem_size = SemIR::ObjectSize::Bytes(
+      context.llvm_module().getDataLayout().getTypeAllocSize(elem_type));
+  if (elem_size != stride) {
+    CARBON_CHECK(elem_size < stride, "Pack element type too large");
+    elem_type =
+        BuildTailPaddedType(elem_type, stride.bytes() - elem_size.bytes());
+  }
+  return {llvm::ArrayType::get(elem_type, *arity), nullptr};
 }
```

<!-- google-doc-style-resume -->

It is VA-2's D-VA2-7 hunk (scratchpad/va2-impl/amend11/c3b/c3b.patch,
fork/variadics/va2-plan.md section 2.8) for PR 59's `element_type_inst_id`,
which upstream's own `BuildTypeForInst(ArrayType)` also reads
(lower/type.cpp:627-648 on `sim59`). Commit F-D2 fills pack_expansion.carbon.
Predicted CHECK-relevant lines: the split `padded_element` lowers `SumA`'s pack
as an array of three elements of the padded type `BuildTailPaddedType` builds
for `{.a: i32, .b: bool}` (a packed LLVM struct of 5 bytes at its 8-byte array
stride, as VA-2's defect A record reads, va2-plan.md:2128-2139 at 43c8ab476),
each `each x.a` is a `getelementptr` into that array, and `Call` passes the
three elements `Make` returns; the lowering does not stop. The exact IR is the
fill's, reviewed as a diff (R16). The gate after F-D2: every golden passes
(measured on `sim59` with D1 and D2 before their splits: 2004 of 2004). Commit
D-R, the records: W-367 and W-368 filed in PR 59's branch's ledger (Appendix
D.5), VA-1's decision-log paragraph and fold record; the NONE register entry
waits for M59 (section 2.8). VA-2's hand-off notes 7 and 9 are discharged by
D-R's texts (their break condition "PR 59 landing on trunk before the fix" no
longer reachable).

### §2.5 Landing G-60: PR 60 (stage 13)

Item 15's steps, in the order they run (D-FO1-2, D-FO1-8). The actor is SC-1's
follow-on implementer, in a fresh worktree of claude/carbon-fork-0-1-sc at
cc4daba00 under /dev/shm, its build under /dev/shm; each commit below is gated
before it is made.

1.  `git fetch origin`; `git ls-remote origin` shows cc4daba00 for PR 60 and
    trunk at 03b40f7c5 or later. If trunk moved,
    `git merge-tree --write-tree --name-only` of trunk and cc4daba00 is re-run
    and compared with the row of section 0.3; a file or region not there with
    no rule here stops (D-FO1-11).
2.  **M60**, "SC-1: merge trunk at `<trunk>` (LAND-1 stage 13, D-LAND-12)":
    `git merge --no-ff --no-commit origin/trunk` on PR 60's branch, never a
    rebase. convert.cpp's two regions: SC-1's
    `CheckConversionIsNotOfStructuralRequirement` call first, then A2's comment
    and `PendingBlock`, in `PerformAction(ConvertAction)` and
    `PerformAction(ConvertToCategoryAction)` (TP-1's M rule,
    fork/templates/plan.md section 3 item 7). member_access.cpp's include
    region: `pointer_dereference.h` beside `structural_conformance.h`,
    alphabetical. merge.cpp's region: `CheckRedeclExplicitParamsAfterSelfMatch`
    takes OV-4's `llvm::ArrayRef(...).drop_front()` operands with SC-1's two
    arguments, and `CheckOverloadMemberParamsMatch`'s two calls, which
    auto-merge, gain `/*new_specific_id=*/SemIR::SpecificId::None,
    /*found_error=*/nullptr` (OV-4's M, ov4-plan.md section 3). templates.md's
    region: SC-1's paragraph in place of upstream's "However, if there are still
    use cases" paragraph, then DD-1's section "Templates in the 0.1 toolchain".
    The records files by D-LAND-5's OR, DL, GA and LG rules (trunk's blocks
    first, SC-1's appended), fork/conformance/README.md's table regenerated
    (`runner.py --update-readme-table`). `git diff --name-only --diff-filter=U`
    empty; prek on the resolved files; `git add` by name. M60's own build is
    expected to compile (the simulation's did) and its gate to be red on the
    eight template-constraint goldens and the two programs that S restores
    (section 0.3, TP-1's M18 record).
3.  **S**, "TP-1 (7): over SC-1, a template constraint's requirement defers to
    the type in constraint lookup": member_access.cpp only, the hunk of
    `$P/sim60/S.patch` (after the `ErrorInst` check in
    `LookupMemberInTemplateConstraint`, the comment of TP-1's section 2.5
    verbatim, then a return of `SemIR::InstId::None` when
    `GetStructuralRequirementOfType` of the found member's type has a value). It
    is TP-1's S re-derived: TP-1's text calls
    `GetStructuralRequirementRef(context, member_id)`, which SC-1's head no
    longer declares (fork/templates/plan.md:4637 against cc4daba00
    toolchain/check/structural_conformance.h:105,
    `GetStructuralRequirementOfType` over a type); the commit message says so.
    Gate after S, measured on `sim60`: 2001 of 2003, the two refills of step 5.
4.  **M18**, TP-1's mutant, run once after S on S's build (relink only): revert
    member_access.cpp's S hunk, rebuild, gate; expected red on the eight
    template-constraint goldens and the two programs (measured as `sim60`
    without S, section 0.3); then S restored and rebuilt. The result goes in
    the Landed text as "M18 killed" with the counts (D-LAND-20's rule).
5.  **F-M60**, "SC-1: autoupdate the goldens the land merge changes (stage 13)":
    `$CB/autoupdate.sh` on check
    named_constraint/fail_template_constraint_requirement_call.carbon and
    lower/template/template_constraint.carbon, the two the gate names (measured:
    a note gains its location, IR names change; CHECK lines only).
6.  The checks of item 15 that are not commits, each recorded in B-R's text:
    DR-1's test on SC-1's added call.cpp and convert.cpp lines (`git diff
    <trunk>...HEAD -- toolchain/check/call.cpp toolchain/check/convert.cpp`
    piped to `grep -c` of `TemporaryStorage`, `return_arg_id` and
    `ConvertCallArgs` on `+` lines: measured 0, 0 and 0, also with B1's lines);
    CT-1's PR 60 composition re-measured on the merged build with the probes
    t08, t09, t13 and t14 (CT-1's `$X/rr1p`, their CT-1 outputs 47, 48 and
    the incomplete-class diagnostic for `C(i32)` twice) and tc5 and tc6
    (expected 8 and 7), under CT-1's break condition (fork/cpp-templates/plan.md
    section 0.9: tc5 or tc6 behaving otherwise, or an SC-1 golden other than
    F-M60's two changing, stops); not measured by this plan (section 8).
7.  **B1**, **F-B1**, the program, **D-B** and **B-R** of section 2.2, in that
    order, each gated; then the two implementation reviews of D-FO1-9 on
    M60..B-R (one of them also the document review of D-B and of DD-1's
    state-L text, step 8), the fixer, and `git push origin
    claude/carbon-fork-0-1-sc` (a fast-forward).
8.  **L60**, DD-1's state L for SC-1, a land-time page commit on PR 60's branch
    after D-B, "SC-1: DD-1's state L (stage 13)": fork/designdocs/plan.md
    section 2.13's SC-1 texts: interoperability/README.md's C++ templates
    section gains "; the design of both directions is in" and the link
    `[Template
    constraints](../generics/template_constraints.md#mapping-to-and-from-c20-concepts)`;
    templates.md's state-L status sentences, the `Circle` paragraph's last
    sentence and the `template constraint` limit; quote fixture X12 deleted from
    fork/designdocs/samples/ and from the checker's table (section 2.4 there);
    both checker modes 0 errors (`python3 -I fork/designdocs/check_samples.py`,
    and with `--toolchain` on the branch's install). The texts are DD-1's
    verbatim, re-read against M60's tree; a text the merged page no longer fits
    stops (D-LAND-14's break condition).
9.  The trunk landing, D-LAND-6's twelve steps for PR 60 at its pushed head:
    the merge is clean (the head contains trunk), expected `<g0>` = `<gn>` =
    2003 of 2003, conformance 196/0/14 over 210, 50 of 56 bullets; no refill
    commit; the records commit "Land PR 60: records" with Appendix A.3 to A.10's
    texts and Appendix E's fields; one fresh reviewer, two for the page edits
    (D-FO1-9).

The commit order on the branch is therefore M60, S, F-M60, B1, F-B1, D-B, L60,
B-R. B1's prototype was measured on `sim57x60` (which holds PR 57), not on M60's
tree; the expectation on M60's tree is the same two `fail_`-prefix problems and
fills (section 4), and a difference is a stop of D-FO1-2's break condition.

### §2.6 Landing G-56: PR 56 (stage 14)

Item 16's PR 56 steps, after stage 13's phase 2 and after C1 and F-C1 on PR
56's branch (section 2.3) under OP-1's two reviews. Actor: OP-1's follow-on
implementer, a fresh worktree of claude/carbon-fork-0-1-op at its pushed head.

1.  Heads confirmed as in section 2.5 step 1 (PR 56 at F-C1's sha).
2.  **M56**, "OP-1: merge trunk at `<trunk>` (LAND-1 stage 14, D-LAND-12)":
    docs/design/control_flow/loops.md by DR-1's M-a rule and C.7
    (fork/direction/plan.md section 1.16); docs/design/error_handling.md with
    both amendments in date order, OP-1's (2026-10-13) then DR-1a's
    (2026-10-21) (fork/direction/plan.md section 0.8, :708); the records files
    by D-LAND-5; the README table regenerated.
3.  **F-M56**: autoupdate on what M56's gate names. Predicted: none, or SV-1's
    choice/optional_pointer_payload.carbon, interop/cpp/stdlib/optional.carbon
    and variant.carbon (CHECK lines of the prelude's Optional), which the land
    tree `sim57x60` names with PR 57 in it; `sim60x56` was not built
    (section 8), so the set is the gate's, and each file must be explained by
    OP-1's prelude or W-352's (D-LAND-8).
4.  **C-R** of section 2.3, now that W-352 and RG-1's register files are on
    the branch.
5.  **L56**, the land-time records and page commit on PR 56's branch, "OP-1:
    land-time texts (stage 14)": row 78's DR-0 sentence kept beside PR 56's text
    as DR-1's C.3 rewrites it (fork/direction/plan.md section 1.16; PR 57 later
    adds its DONE text); W-323's discharge note, DR-1's C.2 text with PR 56's
    commit 894139b34; DD-1's state L for PR 56 (interoperability/README.md's
    pointer section, "`Core.Optional(T*)` in Carbon" gaining the link
    `([Optional](../optional.md), fork decision F-015)`, DD-1 section 2.13),
    both checker modes 0 errors.
6.  Two implementation reviews (OP-1's rule, D-FO1-9) of C1 to L56 (C1 and
    F-C1 reviewed with C-M57 in view); fixer; push.
7.  The trunk landing (D-LAND-6) at the pushed head: expected 2006 of 2006,
    201/0/17 over 218, 50 bullets, no refill; records commit with Appendix E's
    fields. RG-1's OP-1 note is not owed (D-LAND-15 names OP-2's and VA-1's
    only).

### §2.7 Landing G-57: PR 57 (stage 15)

After stage 14's phase 2, the orchestrator retargets PR 57 from
claude/carbon-fork-0-1-op to trunk (D-FO1-7) and the actor confirms the base
with `pull_request_read`. PR 57's branch then holds A1, F-A1, A-R (section 2.1)
and C-M57, F-C-M57 (section 2.3), under OP-2's two reviews.

1.  Heads confirmed; base `trunk`.
2.  **M57**, "OP-2: merge trunk at `<trunk>` (LAND-1 stage 15, D-LAND-12)":
    trunk now holds PR 60 and PR 56, and PR 57's branch holds PR 56's head, so
    the conflicts are PR 57's over `sim56` (section 0.3): lower/testdata
    array/iterate.carbon, for/break_continue.carbon and for/for.carbon, CHECK
    lines only, each taken from trunk's side by GOLD-1 and refilled in step 3;
    the records files by D-LAND-5. Measured: `sim60x57`'s toolchain, core and
    docs trees equal `sim57x60`'s, so the order of stages 13 to 15 changes no
    code.
3.  **F-M57**: autoupdate on what M57's gate names. Predicted (measured on
    `sim57x60` with S and A1, nine refills there): DR-1a's m57 three (lower
    array/iterate, for/break_continue, for/for;
    fork/direction/plan.md:1566-1574), TP-1's lower/template/for_range.carbon
    (CT-1's PR 57 composition, its red set otherwise empty,
    fork/cpp-templates/plan.md section 0.9: a golden other than for_range.carbon
    red, or a for_range.carbon diff different from its mirror's, stops), SV-1's
    three unless F-M56 refilled them, and PR 60's two only if OP-2's prelude
    moves their lines again; plus the W-352 goldens of OP-2's that F-C-M57 did
    not settle. Each named in the message with the PR whose change it combines
    (D-LAND-8).
4.  The conditional refill of SV-1's fail_todo_core_optional.carbon: only if
    M57's gate names it (fork/sumtype-interop/plan.md section 3 item 8);
    otherwise not touched.
5.  The nested-pointer leg of
    fork/conformance/programs/interop/cpp_sum_type_roundtrip_diff.carbon with
    its oracle, SV-1's text (section 1.7 there), expected `-10 -20 81 -1 -2 81`,
    a land-time program commit "OP-2: SV-1's nested pointer leg (stage 15)" if
    the program on M57's tree lacks it; the oracle is the nightly (R30), never a
    held install.
6.  **L57**, "OP-2: land-time texts (stage 15)": OP-2's fold of W-197 into
    W-126 (W-197's title gains "(FOLDED into W-126)", W-126 gains W-197's OP-2
    note and the Optional row, row 43 and optional.md name W-126 again,
    fork/optional2/plan.md's ORCHESTRATION item); SV-1's Doc-M (optional.md and
    the F-015 paragraph, fork/sumtype-interop/plan.md Appendix C.3 and C.8),
    its texts re-derived under SV-1's section 1.14 document review because they
    describe the view W-322 retired; C.5's W-177 evidence with its note
    withdrawn; C.8's F-015 references; the W-177 cite in
    match_core_optional_diff.carbon's header; F-M's PR 57 part; RG-1's OP-2
    note (rg1-plan.md:2553-2560 by D-LAND-15's rule, "2026-10-27" read
    "2026-10-28").
7.  Two implementation reviews (OP-2's rule) of M57 to L57, one of them the
    document review of Doc-M (R29(c)); fixer; push.
8.  The trunk landing at the pushed head: expected 2011 of 2011, 208/0/14
    over 222, 50 bullets, no refill; Appendix E's fields.

### §2.8 Landing G-59: PR 59 (stage 16)

Item 17's PR 59 steps, owned by VA-1's workstream, after D1, F-D1, D2, F-D2
and D-R (section 2.4) under VA-1's two reviews and VA-2's item 2 preconditions
(fork/variadics/va2-plan.md at 43c8ab476, its Next actions item). Independent
of stages 13 to 15 in code (no conflict between PR 59 and PR 60, 56 or 57 in
section 0.3's merge-trees), it runs after them in LAND-1's numbering; if
stage 13 to 15 stop, stage 16 may run first by the orchestrator's ruling
(D-FO1-7).

1.  Heads confirmed.
2.  **M59**, "VA-1: merge trunk at `<trunk>` (LAND-1 stage 16, D-LAND-12)":
    toolchain/check/handle_function.cpp by OV-4's rule (VA-1's pack gate,
    the `PackExpansionPattern` TODO and its `break`, before OV-4's default
    look-through from `DefaultValuePattern` to its `binding_pattern_id`;
    ov4-plan.md section 6.2); the records files by D-LAND-5.
3.  **M-VA**, SV-1's land-time hunk (fork/sumtype-interop/plan.md section 3
    item 8, `$W/land/m-va-pack-element.diff`) with its mutants M19 and M21
    run after it (their records in SV-1's section 8); **S-VA**, CT-1's land-time
    code commit (fork/cpp-templates/plan.md section 3 item 13, D-CT-3's refusal
    of a pack expansion argument) with Appendix C.11's split and its mutant
    M18 (CT-1's, which reverts S-VA); TP-1's VA-1 compositions: none
    (measured by TP-1, fork/templates/plan.md section 3 item 8).
4.  **F-M59**: autoupdate on what the gate after S-VA names. Measured on `sim59`
    (trunk 03b40f7c5, without M-VA and S-VA): 2004 of 2004, nothing to fill;
    M-VA and S-VA add their own splits, filled here; a golden of stages 13 to
    15 that VA-1's toolchain changes is predicted none (VA-1 touches no
    Optional or template-constraint lowering) and, if named, must be explained
    (D-LAND-8).
5.  DR-1's test on VA-1's added call.cpp and convert.cpp lines (measured 0,
    0, 0 at b0822a744).
6.  **L59**, "VA-1: land-time texts (stage 16)": W-284 with its `blocked_by`
    W-219 and its clauses in row 68, the decision-log entry's D-SV-4 and
    id-list clauses, W-011's notes and the SV-1 Branches row
    (fork/sumtype-interop/plan.md Appendix C.6 to C.9); RG-1's VA-1 note
    (rg1-plan.md:2573-2583 by D-LAND-15's rule) and, as the last of the five
    notes once PR 57's has landed, W-343's discharge (RG-1's text, :500-504);
    the NONE register entry for W-367's refusal (Appendix D.6), which D-R
    cannot write because RG-1's register files reach PR 59's branch only at
    M59.
7.  Two implementation reviews (VA-1's rule) of M59 to L59; fixer; push.
8.  The trunk landing at the pushed head: expected 2029 of 2029, 218/0/13 over
    231, 51 bullets, no refill.

### §2.9 Landing G-66: PR 66 (stage 17)

After stage 16's phase 2 the orchestrator retargets PR 66 from
claude/carbon-fork-0-1-va to trunk. VA-2's own land-time commits
(fork/variadics/va2-plan.md section 3 item 15), verbatim in their messages
there:

1.  **M**, the merge of trunk into PR 66's branch by VA-2's section 6.2 rules:
    toolchain/check/convert.cpp keeps TP-1's `SpliceInst` block, closed, then
    VA-2's pack segment (rule 1); toolchain/check/eval.cpp keeps both members,
    trunk's `diagnosed_non_constant_ids_` first (rule 2); handle_function.cpp
    as M59 resolved it (VA-2 rewrites the pack gate's neighbour, OV-4's rule
    again); toolchain/lower/type.cpp, which conflicts once D2 is on trunk,
    takes VA-2's side (its D-VA2-7 hunk is D2's layout over C1's `element_id`
    plus the heterogeneous pack's struct; measured over `sim59f`, one region);
    handle_pack_expansion.cpp auto-merges W-367's hunk into VA-2's rewritten
    `Pattern` case (measured), and the merged case is read to confirm the
    choice-alternative test still precedes the parameter-list test.
2.  **S-CT**, VA-2's land-time test commit of D-VA2-14 (the new split file
    `fail_todo_cpp_call_on_hetero_element`, VA-2 section A.11), no code.
3.  **F-M**, the fill M and S-CT need; **L-F**, the README table and program
    headers regenerated; **L**, VA-2's records commit re-quoting the run on the
    merge.
4.  Two reviews by VA-2's rule (its section 3 item 15); push.
5.  The trunk landing: expected 2047 of 2047, 228/0/13 over 241, 51 bullets.

W-367's split `fail_todo_choice_alternative` and W-368's `padded_element` and
program stay on PR 66's merged tree, and VA-2's hand-off notes 7 and 9 are
already discharged by D-R; VA-2's L names them as such.

## §3 The commits in order

Slices A, C and D run on three branches and may run at the same time (one
build per role under /dev/shm); Slice B runs after M60 on PR 60's branch. The
landings run in stage order. Each message below is the title; the body names
the decision, the measured gate and prek's result, and for a markdown file
R31's counts; the trailers follow a blank line (section 2's preamble).

| # | Branch (PR) | Commit | Title | Files | Gate after (expected) |
| --- | --- | --- | --- | --- | --- |
| 1 | op2 (57) | A1 | OP-2 fix: a class with its own Destroy impl is not completed by the Destroy witness (item 10) | check/custom_witness.cpp; check/testdata/optional/destroy.carbon | autoupdate would change destroy.carbon only if the split prints (predicted not); every other golden passes |
| 2 | op2 (57) | F-A1 | OP-2 fix fill: autoupdate item 10's split on the container arbiter | destroy.carbon, if autoupdate changes it | all pass |
| 3 | op2 (57) | A-R | OP-2: item 10 recorded (D-FO1-1) | fork/optional2/plan.md; fork/decision-log.md | unchanged |
| 4 | op (56) | C1 | OP-1 fix: Core.Optional compares its payloads in place (W-352) | core/prelude/types/optional.carbon; two programs; fork/conformance/README.md | the W-352 goldens of OP-1 and SV-1 named in section 2.3 |
| 5 | op (56) | F-C1 | OP-1 fix fill: autoupdate W-352's goldens on the container arbiter | the files the gate names | all pass |
| 6 | op2 (57) | C-M57 | OP-2: merge OP-1's W-352 fix (R32 (e)) | merge; records conflicts by D-LAND-5's rules | OP-2's goldens that print the comparison impls |
| 7 | op2 (57) | F-C-M57 | OP-2: autoupdate the goldens OP-1's W-352 fix changes | the files the gate names | all pass |
| 8 | va (59) | D1 | VA-1 fix: a pack expansion pattern in a choice alternative's parameter list is a TODO (W-367) | check/handle_pack_expansion.cpp; check/testdata/variadics/fail_todo_slice.carbon | autoupdate would change fail_todo_slice.carbon |
| 9 | va (59) | F-D1 | VA-1 fix fill: autoupdate W-367's split on the container arbiter | fail_todo_slice.carbon | all pass |
| 10 | va (59) | D2 | VA-1 fix: a pack is laid out at its element's array stride (W-368) | lower/type.cpp; lower/testdata/variadics/pack_expansion.carbon; one program; README table | autoupdate would change pack_expansion.carbon |
| 11 | va (59) | F-D2 | VA-1 fix fill: autoupdate W-368's split on the container arbiter | pack_expansion.carbon | all pass |
| 12 | va (59) | D-R | VA-1: W-367 and W-368 filed and fixed (D-FO1-5, D-FO1-6) | fork/inventory/work-items.json; fork/variadics/plan.md; fork/decision-log.md | unchanged |
| 13 | sc (60) | M60 | SC-1: merge trunk at `<trunk>` (LAND-1 stage 13, D-LAND-12) | merge | the eight goldens and two programs S restores, and F-M60's two |
| 14 | sc (60) | S | TP-1 (7): over SC-1, a template constraint's requirement defers to the type in constraint lookup | check/member_access.cpp | F-M60's two |
| 15 | sc (60) | F-M60 | SC-1: autoupdate the goldens the land merge changes (stage 13) | two goldens | 2003 of 2003 |
| 16 | sc (60) | B1 | SC-1 fix: a checked generic's call of a template-constrained function is checked per specific (W-139; leads issue 2153) | check/call.cpp; check/structural_conformance.cpp (comment); two test files; one program; README table | autoupdate would change the two test files |
| 17 | sc (60) | F-B1 | SC-1 fix fill: autoupdate W-139's splits on the container arbiter | two test files | 2003 of 2003 |
| 18 | sc (60) | D-B | SC-1: template_constraints.md states upstream's decision on issue 2153 (W-139) | docs/design/generics/template_constraints.md; fork/structural/plan.md | unchanged |
| 19 | sc (60) | L60 | SC-1: DD-1's state L (stage 13) | docs/design/templates.md; docs/design/interoperability/README.md; fork/designdocs/samples/ (X12); fork/designdocs/check_samples.py | unchanged; both checker modes 0 errors |
| 20 | sc (60) | B-R | SC-1: W-139 discharged, W-373 filed (D-FO1-2, D-FO1-3) | fork/inventory/work-items.json; fork/decision-log.md; fork/gap-analysis.md; fork/register files | unchanged |
| 21 | trunk | merge, records | Land PR 60: SC-1, template-style structural conformance (F-010); Land PR 60: records | LAND-1's Appendix A.1; A.3 to A.10 with Appendix E's fields | 2003 of 2003 |
| 22 | op (56) | M56, F-M56, C-R, L56 | OP-1: merge trunk at `<trunk>` (LAND-1 stage 14, D-LAND-12); OP-1: autoupdate the goldens the land merge changes (stage 14); OP-1: W-352 discharged (D-FO1-4), its files docs/design/optional.md, fork/optional/plan.md, fork/decision-log.md, fork/inventory/work-items.json, fork/register/rg1-plan.md and fork/register/rg1-checks.tsv; OP-1: land-time texts (stage 14) | section 2.6 | 2006 of 2006 |
| 23 | trunk | merge, records | Land PR 56: OP-1, Core.Optional comparison and the fork design F-015; Land PR 56: records | as row 21 | 2006 of 2006 |
| 24 | op2 (57) | M57, F-M57, the conditional refill, the nested-pointer leg, L57 | OP-2: merge trunk at `<trunk>` (LAND-1 stage 15, D-LAND-12); OP-2: autoupdate the goldens the land merge changes (stage 15); OP-2: SV-1's nested pointer leg (stage 15); OP-2: land-time texts (stage 15) | section 2.7 | 2011 of 2011 |
| 25 | trunk | merge, records | Land PR 57: OP-2, Core.Optional owns its value, the MaybeUnformed unsafe-as fix, checked Get; Land PR 57: records | as row 21 | 2011 of 2011 |
| 26 | va (59) | M59, M-VA, S-VA, F-M59, L59 | VA-1: merge trunk at `<trunk>` (LAND-1 stage 16, D-LAND-12); SV-1's M-VA and CT-1's S-VA messages from their plans; VA-1: autoupdate the goldens the land merge changes (stage 16); VA-1: land-time texts (stage 16) | section 2.8 | 2029 of 2029 |
| 27 | trunk | merge, records | Land PR 59: VA-1, definition-checked variadics, slice 1; Land PR 59: records | as row 21 | 2029 of 2029 |
| 28 | va2 (66) | M, S-CT, F-M, L-F, L | VA-2's messages, its section 3 item 15 | section 2.9 | 2047 of 2047 |
| 29 | trunk | merge, records | Land PR 66: VA-2, definition-checked variadics, slice 2; Land PR 66: records | as row 21 | 2047 of 2047 |

The trunk landings' titles are each PR's Appendix E title. A records file a
slice commit edits is edited again by its PR's land merge only by D-LAND-5's
rules; no slice writes ORCHESTRATION.md (the orchestrator's stamp does,
D-LAND-16).

## §4 Testdata matrix

Predicted from the simulations and the prototypes; R16: no CHECK line is
written by hand, and each fill is autoupdate's, reviewed as a diff.

| File | Commit | Change | Fill | Evidence |
| --- | --- | --- | --- | --- |
| check/testdata/optional/destroy.carbon | A1 | split `incomplete_self_signature` (Appendix A.1), no CHECK line | F-A1: predicted none (no diagnostic, no dump range) | i10a checks with the fix, section 0.2 |
| check/testdata/named_constraint/template_constraint.carbon (`self_facet_in_signature_required` and its `fail_todo_` twin) | none | none | none | fails at PR 57's landing without A1, passes with it (`sim57x60`) |
| check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon | B1 | `fail_symbolic_arg` and `fail_require_in_interface_symbolic` renamed without `fail_`, comments rewritten; `fail_symbolic_arg_unsatisfied` and `fail_symbolic_arg_mismatch` added (Appendix A.2) | F-B1: the renamed splits lose their STDERR lines; the two new ones gain section 2.2's | `$P/w139/gate.log`, `$P/w139/p2v2.txt` |
| lower/testdata/template/template_constraint.carbon | B1 | split `checked_caller` (Appendix A.2) | F-B1: its LLVM IR | p1 prints 7 |
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon; lower/testdata/template/template_constraint.carbon | M60 | none | F-M60: a note's location; IR names | `$P/sim60/gateS.log` |
| check/testdata/optional/compare.carbon; check/testdata/optional/fail_compare.carbon; lower/testdata/optional/compare.carbon; lower/testdata/optional/destroy.carbon; lower/testdata/primitives/optional.carbon; lower/testdata/for/bindings.carbon; lower/testdata/interop/cpp/pointer.carbon | C1 | none | F-C1 (OP-1's files on PR 56) and F-C-M57 (the rest on PR 57); CHECK lines only | `$P/w352/gate_w352.log` |
| check/testdata/variadics/fail_todo_slice.carbon | D1 | split `fail_todo_choice_alternative` (Appendix A.3) | F-D1: section 2.4's four lines | h01 with W-367 |
| lower/testdata/variadics/pack_expansion.carbon | D2 | split `padded_element` (Appendix A.4) | F-D2: its LLVM IR | e13 prints 7 with W-368 |
| SV-1's choice/optional_pointer_payload.carbon, interop/cpp/stdlib/optional.carbon, variant.carbon | M56 or M57 | none | F-M56 or F-M57 | `$P/sim57x60/gate.log` |
| lower/testdata/array/iterate.carbon, for/break_continue.carbon, for/for.carbon | M57 | conflicted, trunk's side (GOLD-1) | F-M57 (DR-1a's m57) | section 0.3 |
| lower/testdata/template/for_range.carbon | M57 | none | F-M57 (CT-1's PR 57 composition) | `$P/sim57x60/gate.log` |
| SV-1's fail_todo_core_optional.carbon | M57 | none | only if M57's gate names it | SV-1 section 3 item 8 |
| M-VA's and S-VA's splits; VA-2's S-CT file | M-VA, S-VA, S-CT | their plans' sources | F-M59, F-M | their plans |

Files gated: trunk 1986; after stage 13, 2003 (PR 60's 17 new files); 14, 2006
(PR 56's 3); 15, 2011 (PR 57's 5); 16, 2029 (PR 59's 18); 17, 2047 (PR 66's 17
and S-CT's one). No slice adds a test file.

## §5 Conformance deltas

The rows D-LAND-18 (d) and (e) compare against, container-measured on the
simulations (section 0.3) plus this plan's three programs, each predicted to
PASS by its EXPECT lines (Appendix B). Trunk at 03b40f7c5: 193 PASS, 0 FAIL,
15 SKIP over 208 programs, 49 of 56 bullets (LAND-1's last landing, PR 68).

| Stage | PR | Programs added (from the PR) | Programs added (FO-1) | SKIP change | Expected after | Bullets | Measured basis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 13 | 60 | interop/cpp_structural_conformance.carbon (and generics/structural_conformance.carbon changed, SKIP on trunk, now run) | generics/structural_conformance_checked_caller.carbon | minus 1 | 196/0/14 over 210 (PASS +3) | 50 | `sim60` with S: 195/0/14 over 209, 50 bullets |
| 14 | 56 | seven stdlib/optional_* programs (OP-1) | stdlib/optional_compare_in_place.carbon | plus 3 (OP-1's SKIPs for ops PR 57 provides) | 201/0/17 over 218 (PASS +5) | 50 | static count of `sim56` (215 programs, 18 SKIP over trunk's 208 and 15); not run |
| 15 | 57 | four stdlib/optional_* programs (OP-2) | none | minus 3 | 208/0/14 over 222 (PASS +7) | 50 | `sim57x60` with S and A1: 206/0/14 over 220, 50 bullets, before B.1 and B.2 |
| 16 | 59 | eight generics/variadics_* programs (VA-1) | generics/variadics_padded_element.carbon | minus 1 | 218/0/13 over 231 (PASS +10) | 51 | `sim59`: 202/0/14 over 216, 50 bullets over trunk's 49, so plus 1 |
| 17 | 66 | ten programs (VA-2) | none | 0 | 228/0/13 over 241 (PASS +10) | 51 | static count of `sim66` (226 programs, 14 SKIP); not run |

Each landing's (e) expected delta is the PASS change in the row. Where the row's
basis is a static count, D-LAND-18 (d) still applies; a difference is
explained by name in the landing's records or stops it. OP-1's
stdlib/optional_compare_payload.carbon keeps its EXPECT through stage 14 and
after (its count is 2 with or without W-352: it counts the live payloads, not
copies; Appendix B.4).

## §6 Churn and collisions

| Slice | Files and lines (prototype) | Held or planned work that touches the same lines | Rule |
| --- | --- | --- | --- |
| A | custom_witness.cpp +14 in `CanDestroyType` | UA-3 (upstream's 05a7ecbd3 moves `SubobjectDestroy` and `SelfDestruct` out of `Destroy`, a prelude and custom-witness change UA-3 takes); SL-1's `CanDestroyClass` shortcut stays | UA-3 merges A1's hunk as fork code beside upstream's; A1's comment names item 10 so the merge keeps it |
| B | call.cpp +36 (helper and condition), structural_conformance.cpp comment +2, template_constraints.md one paragraph and one note | CT-1's `DeferCppCallOnSymbolicArgs` (trunk); UA-3's call.cpp merge; W-372 none | B1 changes CT-1's condition, so CT-1's goldens are in B1's gate: measured unchanged on the land tree |
| C | optional.carbon -40/+90 in OP-1's block after :205 | OP-2's lines (:15, :18, :40-48, after :275) on PR 57; DR-1's W-320 (stopped); RG-1's H6.4 grep check | C-M57 merges cleanly (measured apply); H6.4's check reads lines C does not change |
| D | handle_pack_expansion.cpp +15 in the `Pattern` case; lower/type.cpp +17 in `BuildTypeForInst(PackType)` | VA-2's C1 (`Pattern` case rewritten) and D-VA2-7 (the same function) on PR 66 | section 2.9: W-367 auto-merges, lower/type.cpp takes VA-2's side |
| landings | the records files | EH-C (W-346) and UA-3, which wait on trunk after the held PRs; SAFE-2/SAFE-3's PR 53 | no FO-1 commit touches PR 53's branch; EH-C and UA-3 merge trunk after stage 17 |

No slice changes a file of PR 53, of fork/tools/, of .github/ or of the
rulebook. The program count change of each stage is fork/conformance/README.md's
table, regenerated by the runner, never hand-edited.

## §7 Risks and rejected alternatives

**Rejected: fixing item 10 on trunk.** Trunk does not fail (section 0.2: i10a
checks on trunk's install and on `sim60`); the defect needs OP-2's `let Type:
Destroy`, which only PR 57 brings. A trunk commit would be a fix with no
failing input on its own tree, its split passing before and after, so its
golden would not pin it, and it would land OP-2's precondition before OP-2.
_Falsifier:_ an input that fails on trunk's install with the same note chain;
none was found (i10b and the eight template-constraint splits check).

**Rejected: landing PR 60 before W-139.** RG-1 classified W-139 as a drift
(DRIFT, rg1-plan.md section 2.H3), and R32 (e) puts the realignment on the PR's
branch before it lands; item 15 names "W-139's fix commit ... on PR 60's
branch" as its gate. Landing first would put upstream's decided direction's
opposite on trunk and the page text calling issue 2153 open.
_Falsifier:_ upstream reopens issue 2153 or removes the overview.md sentence;
the weekly check would see it (W-355).

**Rejected: a parse guard for W-367.** VA-1 cherry-picked upstream's lexer and
parser for `...` (its plan's section 2); upstream's tip parses `...` as a
statement prefix only, so a pattern-position parse rule is VA-1's own, and a
parse-time refusal there would reject the form before the check that knows
it is a choice alternative. The checker sees the scope; the TODO there is
the root, as D-VA-5's interface TODO is. _Falsifier:_ the TODO fires on a
form that is not a choice alternative (the gate and VA-1's own splits pass
unchanged, measured).

**Rejected: deferring W-352 behind W-320.** W-320 (`Core.Optional` matchable
by `Match`) stopped at DR-1's section 0.8 counterexample, and W-352's break
condition makes W-320 a dependency only if the in-place route cannot keep the
signatures and API; it can (D-FO1-4). Waiting would hold PR 56 and PR 57 on a
stopped item. _Falsifier:_ D-FO1-4's break condition.

**Rejected: `let Type: type;` in `OptionalStorage`** (upstream's spelling).
It fixes i10a and breaks OP-2's checked-generic destruction (W-170), measured
(section 0.2); it would be a direction change for PR 57 that its own register
entry does not ask for.

**Rejected: W-352 by a `where .Type impls OptionalStorageEq` bound or a
`template` impl.** Measured (D-FO1-4): the bound rejects OP-1's generic
program; the template impl hits W-250's TODO.

**Rejected: W-139 at the conversion** (`convert.cpp`, a `ConvertAction` on a
`TemplateInst`-wrapped self). Measured: deduction reports "inconsistent
deductions for value of generic parameter `T`" (section 0.4); the call is
upstream's unit of deferral, not the conversion.

**Risk: B1's condition is too narrow or too wide.** Too narrow: a callee
reached through an overload set or an impl member with a `template` binding.
`GetCallee` returns `CalleeFunction` for each candidate after resolution; an
overload set's candidates are resolved before this check (OV-4's call.cpp
order), measured with p1 only. The review is asked to construct the overload
and member forms (D-FO1-2's break condition widens, not guards). Too wide: a
callee whose `template` binding has a structural requirement but whose
argument is not checked-symbolic is not deferred (the `none_of` test runs
first).

**Risk: A1 hides a missing `Destroy`.** A class with its own `Destroy` impl
never used the synthesized witness (`CanDestroyClass` declines it after
completion too), so the answer is the same; an incomplete class without such
an impl still reaches `TryToCompleteType` and is diagnosed as before.

**Risk: the static counts of stages 14 and 17.** `sim56` and `sim66` were not
built (disk: one build at a time, section 0.8); their rows in section 5 are
static. D-LAND-18 stops on a difference, so a wrong count costs a stop, not a
wrong record.

**Risk: trunk moves between a branch merge and its landing** (another
landing, a weekly check). D-FO1-8's break condition: the branch merges trunk
again.

## §8 Verification and what is not run

Run for this plan (container-local, EXPECTED, not of record, R9):

1.  Four builds under /dev/shm/fo1-planner/builds, one at a time: `sim60`
    (and S, W-139 and A1 relinks), `sim57x60` (and S, A1, W-139, W-352 by
    custom core), `sim59` (and W-367, W-368); each with `$CB/install.sh`,
    `$CB/gate.sh` and, where section 0.3 says, `$CB/conformance.sh`.
2.  Probes on trunk's, the five held installs', the nightly's and the
    simulations' toolchains (section 0.2), outputs in `$P`.
3.  `git merge-tree --write-tree --name-only` for each landing (section 0.3),
    and `git apply --check` of each prototype on its PR's pushed head.
4.  The id re-scan (section 0.7) and upstream's register reads at 68569d234
    (section 0.6).
5.  DR-1's test on the prototypes' added lines (section 0.4).

The slices' and landings' implementers run, at each commit: the build, the
gate, autoupdate to its fixpoint on exactly the files the gate names, the
gate again, conformance where a program, the prelude or the toolchain changes,
`runner.py --self-test`, DD-1's two checker modes from L60 on and EV-1's
checker, prek to a fixpoint with R31's counts, `json.load` of the ledger, the
model-identifier grep of the diff, the mutants (M18 at stage 13; M19, M21 and
CT-1's M18 at stage 16), and the register scripts at the landing day's tip
(D-LAND-19) where a records text names the tip.

Not run by this plan, and why:

1.  `sim56`, `sim60x56`, `sim57` and `sim66` builds: disk (one build per role,
    about 3 GB each); their counts in section 5 are static, from the trees.
2.  CT-1's PR 60 composition probes (t08, t09, t13, t14, tc5, tc6) and its
    PR 57 composition's for_range diff against a mirror: CT-1's `$X` probe
    tree was not re-materialized; item 15's step runs them (step 6 of
    section 2.5).
3.  SV-1's M-VA with M19 and M21, CT-1's S-VA with M18, VA-2's M, S-CT and F-M
    on the merged trees: their plans' land-time steps, measured by those plans
    on the held state, re-measured at stages 16 and 17.
4.  The slice commits on the PRs' own branches: prototypes were measured on
    the simulations and checked to apply (A1 on e23113ba2, C1 on 9f12209d8 and
    e23113ba2, D1 and D2 on b0822a744); B1 needs M60's tree.
5.  The register scripts (`check_quotes.sh`, `check_greps.sh`) and DD-1's and
    EV-1's checkers on the land trees: records-time checks, run by each
    landing.
6.  Hosted CI and any Bazel build: Actions is disabled and Bazel is not
    installed (R28); the container arbiter is the record (R33 (b)).
7.  A nightly newer than 2026.10.12: not fetched; the oracle is the installed
    one (R30).
8.  `sim59`'s conformance overlapped the W-367 rebuild's install (202/0/14 over
    216 recorded from that run); the trunk landing re-runs it.

## Hand-off notes

1.  Work in fresh worktrees of the pushed heads under /dev/shm; the held
    worktrees under /home/user are read-only and behind (section 0.1).
2.  The prototypes are in `$P` (`i10/F1.patch`, `sim60/S.patch`,
    `w139/W139v2.patch`, `w352/w352_block.carbon` with `w352.py`,
    `w367/W367.patch`, `w368/W368.patch`); apply each with `git apply` and
    re-read it against section 2, which governs where they differ (B1's helper
    placement and comment).
3.  B1 after M60, S and F-M60, never before (D-FO1-2).
4.  A fill that writes a line outside CHECK lines, or a golden section 4 does
    not name, stops the commit (D-LAND-8).
5.  The `fail_`-prefix problems at B1 are expected and resolved by B1's own
    renames in the same commit; the gate after B1 must show none.
6.  Each records text is Appendix D's or E's, verbatim but for placeholders;
    a text not given is a stop (D-LAND-9).
7.  Dates are the UTC commit date (`date -u +%F`).
8.  No model identifier in any repository file; the trailers carry the
    session's attribution.
9.  Retargets of PR 57 and PR 66 are the orchestrator's; confirm the base with
    `pull_request_read` before the stage.
10. If trunk moved, re-run section 0.3's merge-tree for the branch and
    compare; a new conflict with a rule here is recorded as "not in the dry
    run".

## Appendix A: golden sources

Each source is the split's text without CHECK lines; autoupdate writes those
(R16). The splits go after the split named, in the file named.

### A.1 check/testdata/optional/destroy.carbon: `incomplete_self_signature` (A1)

After the split `generic.carbon`.

<!-- google-doc-style-ignore -->

```carbon
// --- incomplete_self_signature.carbon
library "[[@TEST_NAME]]";

// Item 10 (FO-1, D-FO1-1): a class with its own `Copy` and `Destroy` impls
// names `Core.Optional(Self)` in a method's signature inside its definition.
// Forming `Core.Optional(S)` looks up `DefaultOptionalStorage(S)`'s `Destroy`
// while `S` is incomplete; the class's own `Destroy` impl answers that lookup
// without completing `S`.
class S {
  impl as Core.Copy {
    fn Op(unused self) -> Self { return {}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
  fn Next(self) -> Core.Optional(Self);
}
```

<!-- google-doc-style-resume -->

### A.2 W-139's splits (B1)

In
check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon:
the file comment's "a checked-generic self never satisfies one (D-SC-6, the
conservative answer to leads issue 2153)." becomes "a checked-generic argument
passed to such a binding is checked in each specific of its caller (W-139, as
upstream decided leads issue 2153); elsewhere a checked-generic self never
satisfies one (D-SC-6)."; the split `fail_symbolic_arg.carbon` becomes
`symbolic_arg.carbon` with the comment below added after its `library` line and
its code unchanged; the split `fail_require_in_interface_symbolic.carbon`
becomes `require_in_interface_symbolic.carbon` with its comment replaced by the
one below and its code unchanged; and two splits follow `symbolic_arg`.

<!-- google-doc-style-ignore -->

```carbon
// --- symbolic_arg.carbon
library "[[@TEST_NAME]]";

// W-139 (leads issue 2153): a checked-generic argument passed to a `template`
// binding constrained by a template constraint is checked in each specific of
// `Caller`, so the definition checks.

// --- fail_symbolic_arg_unsatisfied.carbon
library "[[@TEST_NAME]]";

// W-139: the call is checked in `Caller(D)`, where `D` has no member `Get`.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  return CallGet(x);
}

class D {
  var v: i32;
}

fn Use(d: D) -> i32 { return Caller(d); }

// --- fail_symbolic_arg_mismatch.carbon
library "[[@TEST_NAME]]";

// W-139: the call is checked in `Caller(E)`, where `E.Get` returns `bool`.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  return CallGet(x);
}

class E {
  var v: i32;
  fn Get(self) -> bool { return true; }
}

fn Use(e: E) -> i32 { return Caller(e); }

// --- require_in_interface_symbolic.carbon
library "[[@TEST_NAME]]";

// W-139: `G`'s `T: I` is checked-symbolic, and the call that passes `x` to a
// `template` binding is checked in each specific of `G`, so the definition
// checks; a structural requirement is still not forwarded through an
// interface's `require` to a checked binding's own member lookup (D-SC-6;
// mirrors upstream's interface/require.carbon `fail_todo_implicit_self_impls`).
```

<!-- google-doc-style-resume -->

In lower/testdata/template/template_constraint.carbon, after its last split:

<!-- google-doc-style-ignore -->

```carbon
// --- checked_caller.carbon
library "[[@TEST_NAME]]";

// W-139: `Caller(C)` calls `CallGet(C)`; both are lowered per specific.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 { return CallGet(x); }

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Run() -> i32 {
  let c: C = {.v = 7};
  return Caller(c);
}
```

<!-- google-doc-style-resume -->

### A.3 variadics/fail_todo_slice.carbon: `fail_todo_choice_alternative` (D1)

After the split `fail_todo_interface_function.carbon`.

<!-- google-doc-style-ignore -->

```carbon
// --- fail_todo_choice_alternative.carbon
library "[[@TEST_NAME]]";

// W-367: a pack expansion pattern in a choice alternative's parameter list.
choice C { A(... each x: i32) }
```

<!-- google-doc-style-resume -->

### A.4 lower/testdata/variadics/pack_expansion.carbon: `padded_element` (D2)

After the split `forward_converted_field.carbon`, before `lib.carbon`.

<!-- google-doc-style-ignore -->

```carbon
// --- padded_element.carbon
library "[[@TEST_NAME]]";

// W-368: a pack of an element whose LLVM type, a packed struct of 5 bytes, is
// smaller than its array stride, 8 bytes, is laid out at the stride.
fn Add(a: i32, b: i32) -> i32 = "int.sadd";

fn Make(a: i32) -> {.a: i32, .b: bool} { return {.a = a, .b = true}; }

fn SumA(... each x: {.a: i32, .b: bool}) -> i32 {
  var total: i32 = 0;
  ... total = Add(total, each x.a);
  return total;
}

fn Call() -> i32 {
  return SumA(Make(1), Make(2), Make(4));
}
```

<!-- google-doc-style-resume -->

## Appendix B: conformance programs

Each EXPECT line is derived by hand from the program's text and the design
it cites (R16 (d)); the prototype outputs agree (section 0.2). The license
header of every program is the repository's three lines.

### B.1 generics/structural_conformance_checked_caller.carbon (B1)

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Template-style structural conformance to nominal constraints
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// A checked generic calls a template-constrained function (leads issue 2153:
// "We have decided to support passing a symbolic constant to a template
// parameter", docs/design/generics/overview.md). The call is checked in each
// specific of `Caller`, where `U` is `C`, whose own `Get` satisfies `HasGet`
// structurally (fork decision F-010). Expected: `Caller(c)` returns
// `CallGet(c)`, which returns `c.Get()`, `c.v`, 7.

import Core library "io";

template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 { return CallGet(x); }

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Run() -> i32 {
  let c: C = {.v = 7};
  Core.Print(Caller(c));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B.2 stdlib/optional_compare_in_place.carbon (C1)

The program is `$P/w352/count.carbon` under this header:

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   0
//   1
//   1
//   1
//   0
//   0
//   0
//   1
//   1
//   0
//   0
//
// Comparing `Core.Optional(T)` values compares the held values in place: no
// `Copy` and no `Destroy` of `T` per operand (W-352), as
// docs/design/expressions/comparison_operators.md asks of `EqWith` and
// `OrderedWith` ("should have no observable side-effects"). `Counted` counts
// its copies and destructions. Expected, from F-015's rules
// (docs/design/optional.md, "Comparison"): with `a` holding 1, `b` holding 2
// and `n` empty, `a == b` 0, `a != b` 1, `a < b` 1, `a <= b` 1, `a > b` 0,
// `a >= b` 0, `n == a` 0 (empty and non-empty are not equal), `n < a` 1 (an
// empty value orders first) and `a == a` 1; then the copies and destructions
// the nine comparisons made, 0 and 0.
```

<!-- google-doc-style-resume -->

followed by count.carbon's text from `import Core library "io";` to its end,
verbatim.

### B.3 generics/variadics_padded_element.carbon (D2)

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   7
//
// A pack of a struct whose layout has tail padding (W-368): each element is
// read at its array stride. Expected: `F` sums the `.a` fields, 1 + 2 + 4 = 7,
// for constants and for values built at run time.

import Core library "io";

fn F(... each x: {.a: i32, .b: bool}) -> i32 {
  var n: i32 = 0;
  ... n = n + each x.a;
  return n;
}

fn Make(a: i32) -> {.a: i32, .b: bool} { return {.a = a, .b = true}; }

fn Run() -> i32 {
  Core.Print(F({.a = 1, .b = true}, {.a = 2, .b = false},
               {.a = 4, .b = true}));
  Core.Print(F(Make(1), Make(2), Make(4)));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B.4 stdlib/optional_compare_payload.carbon: the comment (C1)

Its lines 19 and 20 at 9f12209d8 ("held value through `Get()`, which returns
a copy, and each copy is destroyed" and "by the end of the comparison.
`Tracked` counts its live copies through a") become the two lines below; no
other line changes, so OP-2's hunk at its lines 27 to 29 merges at C-M57
without a conflict. The EXPECT lines stay: the counts are of live values, 2
before and after either way.

<!-- google-doc-style-ignore -->

```carbon
// held value in place, with no copy (W-352), as comparison_operators.md asks
// of `EqWith` and `OrderedWith`. `Tracked` counts its live copies through a
```

<!-- google-doc-style-resume -->

## Appendix C: the docs amendments

### C.1 docs/design/generics/template_constraints.md (D-B)

The paragraph that begins "Using a template constraint on a checked-generic
binding is an error in 0.1" (:456-468 at cc4daba00) becomes:

<!-- google-doc-style-ignore -->

```markdown
Using a template constraint on a checked-generic binding is an error in 0.1
(landed: `TemplateConstraintOnNonTemplateBinding` at the binding, SC-1
D-SC-8). Passing a checked-generic argument to a template-constrained binding
is supported, as upstream decided in
[leads issue 2153](https://github.com/carbon-language/carbon-lang/issues/2153):
"We have decided to support passing a symbolic constant to a template
parameter" ([overview](overview.md)), and such a call "relies on
monomorphization" ([witness appendix](appendix-witness.md)). The toolchain
checks the call in each specific of the checked caller, where the argument's
type is concrete, as it does for a C++ template given a symbolic argument; an
argument type that does not conform is diagnosed when that specific is formed,
with the requirement it misses. Elsewhere a checked-generic self still never
satisfies a structural requirement (`StructuralRequirementNeedsConcreteType`,
D-SC-6): a conversion outside a call, and the `require` of an impl in a generic
class (fork work item W-373). Member lookup through a checked binding never
finds structural members
([#2200](/proposals/p002200-template-generics.md#template-constraints)), which
is why a template constraint constrains only a `template` binding.
```

<!-- google-doc-style-resume -->

After RG-1's note (2026-10-28), which stays, this note follows:

<!-- google-doc-style-ignore -->

```markdown
> **SC-1 note (<date>).** W-139 realigned: the definition-time rejection the
> note above describes is replaced by the check in each specific that the
> paragraph above it states, upstream's mechanism (upstream's
> toolchain/check/call.cpp wraps a symbolic template argument in a
> `TemplateInst` and performs the call in each specific). The `require` of an
> impl in a generic class keeps D-SC-6's rejection; leads issue 2153 does not
> decide it (W-373).
```

<!-- google-doc-style-resume -->

### C.2 fork/structural/plan.md: D-SC-6's amendment (D-B)

Appended as the last paragraph of the D-SC-6 bullet (:388 at cc4daba00), at
the bullet's indentation:

<!-- google-doc-style-ignore -->

```markdown
(Amended <date>, FO-1, W-139: a checked-symbolic self that a call passes to a
`template` binding is no longer rejected at the caller's definition; the call
is deferred to each specific (call.cpp, `DeferCppCallOnSymbolicArgs`,
fork/followon/fo1-plan.md D-FO1-2), where the self is concrete, as upstream
decided leads issue 2153. The rejection stays for a conversion outside a call
and for an impl's `require` in a generic class, W-373.)
```

<!-- google-doc-style-resume -->

### C.3 docs/design/optional.md (C-R)

In "Comparison", the paragraph that begins "In 0.1 a comparison of two
non-empty values reads each through `Get()`" (:322-328 at 9f12209d8) and the
first sentence of the next become:

<!-- google-doc-style-ignore -->

```markdown
A comparison of two non-empty values compares the held values in place, with
no `Copy` and no `Destroy` of `T` per operand, as the comparison operators
design asks: `EqWith`'s operations and the members of an `OrderedWith`
implementation "should have no observable side-effects" (fork work item W-352,
realigned <date>).

Each comparison tests `HasValue()` on its operands before it reads a held
value, so the storage of an empty operand is never read.
```

<!-- google-doc-style-resume -->

The next paragraph's "Neither operand is moved, changed or destroyed." stays.
The API table rows (:95-96) do not change.

## Appendix D: the records texts

Placeholders as the conventions say; each text goes where its heading says.

### D.1 fork/optional2/plan.md: the item 10 fold record (A-R)

A new section at the end of the file, after "Landed notes (OP-2, 2026-10-14)":

<!-- google-doc-style-ignore -->

```markdown
## Item 10 fold record (FO-1, <date>)

ORCHESTRATION's Next actions item 10 (an SC-1 split failing with ``unable to
monomorphize specific `<none>` `` on the land tree) is OP-2's defect: a class
with its own `Destroy` impl that names `Core.Optional(Self)` in a method's
signature inside its definition was rejected on PR 57's toolchain only. Root:
`OptionalStorage`'s `let Type: Destroy;` makes forming `Core.Optional(C)` look
up `DefaultOptionalStorage(C)`'s `Destroy`, and `CanDestroyType` completed the
class before `CanDestroyClass` honored its own `Destroy` impl. Fixed by
<sha-A1> (custom_witness.cpp declines such a class before completing it) with
the split `incomplete_self_signature` in check/testdata/optional/destroy.carbon
and its fill <sha-F-A1>; gate <g> of <g> on the branch; reviewed by two
implementation reviews (fork/followon/fo1-plan.md D-FO1-1, D-FO1-9).
```

<!-- google-doc-style-resume -->

### D.2 fork/decision-log.md: OP-2's entry (A-R)

The last paragraph of `### OP-2 / F-016: Core.Optional ownership, adapter
destruction, the MaybeUnformed representation fix, checked Get (2026-10-14)`:

<!-- google-doc-style-ignore -->

```markdown
_Item 10 (<date>, FO-1):_ a class whose own `Destroy` impl answers the
`Destroy` query is no longer completed by the custom witness, so a method of
`C` returning `Core.Optional(Self)` checks (<sha-A1>, fork/followon/fo1-plan.md
D-FO1-1); `let Type: Destroy` stays, since upstream's `let Type: type` removes
W-170's checked-generic destruction (measured).
```

<!-- google-doc-style-resume -->

### D.3 W-139 and W-373 (B-R)

W-139 in fork/inventory/work-items.json: `kind` becomes `implemented`; the
title gains, after "SC-1 residue", " (DISCHARGED at SC-1's W-139 fix, <date>)";
`evidence` gains first "Landed at SC-1 (<sha-B1>): toolchain/check/call.cpp
`CalleeHasStructuralTemplateBinding` and `DeferCppCallOnSymbolicArgs`'s
condition (a call passing a checked-symbolic argument to a `template` binding
with structural requirements is a `CallAction` performed in each specific);
the splits `symbolic_arg`, `fail_symbolic_arg_unsatisfied`,
`fail_symbolic_arg_mismatch` and `require_in_interface_symbolic`, and
lower/testdata/template/template_constraint.carbon's `checked_caller`
(<sha-F-B1>)"; `notes` gains "Discharged <date> (FO-1, D-FO1-2): upstream's
spelling (check/call.cpp:386-395 at <tip>), docs rewritten (<sha-D-B>); the
generic class's `require` path is W-373.".

W-373, appended after the last item:

<!-- google-doc-style-ignore -->

```json
{
  "id": "W-373",
  "kind": "missing-feature",
  "title": "SC-1 residue (D-SC-6; FO-1 D-FO1-3): an impl in a generic class whose interface `require`s a template constraint is checked at the class end with its checked-symbolic self (`Box(T)`), so the structural requirement is rejected there; not a template parameter receiving a symbolic constant, so leads issue 2153 does not decide it",
  "subsystem": "toolchain/check (impl.cpp, structural_conformance.cpp)",
  "size": "M",
  "bullet": "Generics: Template-style structural conformance to nominal constraints",
  "evidence": [
    "toolchain/check/impl.cpp `CheckDeferredRequireDeclsAtClassEnd` (the class-end check of an impl's `require`)",
    "toolchain/check/testdata/named_constraint/template_constraint_require.carbon `fail_todo_require_in_interface_in_generic_class_impl`",
    "fork/followon/fo1-plan.md D-FO1-3"
  ],
  "blocked_by": [],
  "notes": "Register: NONE (RG-1 vocabulary), watched by W-355. Break condition: upstream states how a checked-symbolic self satisfies a requirement that needs a concrete type, or lands interface/require.carbon's `fail_todo_implicit_self_impls`; this item is then scheduled as a drift."
}
```

<!-- google-doc-style-resume -->

The `evidence` cites are re-pinned by B-R to M60's tree, with line numbers.
The gap row "Generics: Template-style structural conformance to nominal
constraints" gains, before its closing `|`, " W-139 discharged <date> (FO-1:
checked generics call template-constrained functions per specific); W-373
filed." SC-1's decision-log entry `### SC-1: template structural conformance
(F-010) (2026-10-12)` gains as its last paragraph:

<!-- google-doc-style-ignore -->

```markdown
_W-139 (<date>, FO-1):_ a checked generic's call of a template-constrained
function is checked in each specific (<sha-B1>), as upstream decided leads
issue 2153 and spells it (check/call.cpp's `TemplateInst` deferral); D-SC-6
stays for a conversion outside a call and for the generic class's `require`
(W-373). Land merge <sha-M60> with TP-1's S re-derived (<sha-S>; M18 killed);
fork/followon/fo1-plan.md D-FO1-2, D-FO1-3.
```

<!-- google-doc-style-resume -->

### D.4 W-352 and H5.4 (C-R)

W-352 in fork/inventory/work-items.json: `kind` becomes `implemented`; the title
gains, after "OP-1", " (DISCHARGED at OP-1's W-352 fix, <date>)"; `evidence`
gains first "Landed at OP-1 (<sha-C1>): core/prelude/types/optional.carbon's
private `OptionalStorageEq(T)` and `OptionalStorageOrdered(T)`, the default
storage's impls comparing the `MaybeUnformed(T)` fields as `T` in place;
fork/conformance/programs/stdlib/optional_compare_in_place.carbon prints 0
copies and 0 destructions over nine comparisons"; `notes` gains "Discharged
<date> (FO-1, D-FO1-4): signatures and F-015's API unchanged; the break
condition (blocked_by W-320) did not fire.". OP-1's decision-log entry `### OP-1
/ F-015: Core.Optional comparison and design (2026-10-13)` gains as its last
paragraph:

<!-- google-doc-style-ignore -->

```markdown
_W-352 (<date>, FO-1):_ the comparisons compare the held values in place
through two private interfaces over the storage type, with no `Copy` or
`Destroy` per operand (<sha-C1>), as comparison_operators.md asks; D-OP-4's
signatures and F-015's API rows are unchanged (fork/followon/fo1-plan.md
D-FO1-4).
```

<!-- google-doc-style-resume -->

fork/optional/plan.md gains at its end, after "Landed notes (OP-1,
2026-10-13)", a paragraph: "W-352 realigned (<date>, FO-1): <sha-C1> and
<sha-F-C1>; D-OP-4's 'Get() returns a copy, destroyed by the end of the call'
holds for `Get()` and no longer for the comparisons (fork/followon/fo1-plan.md
section 2.3)."

### D.5 W-367 and W-368 (D-R)

Appended to PR 59's branch's fork/inventory/work-items.json:

<!-- google-doc-style-ignore -->

```json
{
  "id": "W-367",
  "kind": "missing-feature",
  "title": "VA-1 residue (FO-1 D-FO1-5; LAND-1 item 13): a pack expansion pattern in a choice alternative's parameter list (`choice C { A(... each x: i32) }`) is a semantics TODO; it aborted in lowering before the TODO",
  "subsystem": "toolchain/check (handle_pack_expansion.cpp)",
  "size": "M",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "toolchain/check/handle_pack_expansion.cpp the `Pattern` case's choice-alternative TODO (<sha-D1>)",
    "toolchain/check/testdata/variadics/fail_todo_slice.carbon `fail_todo_choice_alternative` (<sha-F-D1>)"
  ],
  "blocked_by": [],
  "notes": "Upstream is silent on a choice alternative's parameter list in docs/design/variadics.md and p002240, and its parser rejects `...` there (`ExpectedPattern`); register NONE, watched by W-355. Break condition: the design speaks to choice alternatives, or VA-2 reaches an alternative's parameters (VA-2's hand-off note 9)."
}
```

```json
{
  "id": "W-368",
  "kind": "implemented",
  "title": "VA-1 (DISCHARGED at VA-1's W-368 fix, <date>; LAND-1 note 7, defect A): a pack of an element whose LLVM type is smaller than its array stride aborted at lower/type.cpp's layout check; a pack is now laid out at its element's array stride",
  "subsystem": "toolchain/lower (type.cpp)",
  "size": "S",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "Landed at VA-1 (<sha-D2>): toolchain/lower/type.cpp `BuildTypeForInst(PackType)` (`BuildTailPaddedType` to the stride)",
    "toolchain/lower/testdata/variadics/pack_expansion.carbon `padded_element` (<sha-F-D2>); fork/conformance/programs/generics/variadics_padded_element.carbon"
  ],
  "blocked_by": [],
  "notes": "VA-2's D-VA2-7 layout for PR 59's one-type pack (fork/followon/fo1-plan.md D-FO1-6); PR 66's merge takes VA-2's side of the function."
}
```

<!-- google-doc-style-resume -->

VA-1's decision-log entry `### VA-1: definition-checked variadics, slice 1
(2026-10-14)` gains as its last paragraph:

<!-- google-doc-style-ignore -->

```markdown
_W-367 and W-368 (<date>, FO-1):_ a pack expansion pattern in a choice
alternative's parameter list is a semantics TODO (<sha-D1>, W-367), and a pack
is laid out at its element's array stride (<sha-D2>, W-368), so neither form
aborts (fork/followon/fo1-plan.md D-FO1-5, D-FO1-6).
```

<!-- google-doc-style-resume -->

fork/variadics/plan.md gains at its end, after "Landed notes (VA-1,
2026-10-14)", a section `## FO-1 fold record (<date>)` with the same two
sentences and the gate after F-D2.

### D.6 The register entries (B-R, C-R, L59)

In fork/register/rg1-plan.md: H9.5's verdict cell becomes "ALIGNED (W-139
discharged <date>, FO-1: the call is checked per specific, upstream's
`TemplateInst` deferral)" and its item cell "W-139 (discharged)" (B-R); H5.4's
verdict cell becomes "ALIGNED (W-352 discharged <date>, FO-1: in place, no
`Copy` or `Destroy` per operand)" (C-R); and two rows are added, H9.7 after
H9.6 (B-R) and H8.9 after H8.8 (L59):

<!-- google-doc-style-ignore -->

```markdown
| H9.7 | an impl's `require` of a template constraint in a generic class is checked at the class end with a checked-symbolic self (D-SC-6, W-373) | silent at the tip | NONE | upstream states how a checked-symbolic self satisfies a requirement that needs a concrete type | W-355; W-373 |
| H8.9 | a pack expansion pattern in a choice alternative's parameter list is a semantics TODO (W-367) | silent at the tip, check H8.9: `git grep -c -i -E 'choice\|alternative'` over docs/design/variadics.md = 2 (the "Alternatives considered" heading and its contents link) | NONE | the design speaks to choice alternatives | W-355; W-367 |
```

<!-- google-doc-style-resume -->

In fork/register/rg1-checks.tsv, after H8.7's row, the tab-separated row
`H8.9`, `G`, `-i -E`, `choice|alternative`, `docs/design/variadics.md`, `2`
(measured 2 at 68569d234). The count in rg1-plan.md's header ("89 checks")
gains one.

## Appendix E: the landings' fields (LAND-1 Appendix C rows)

The fields of LAND-1's Appendix A for stages 13 to 17, `<moved>` "none"
where empty; titles are the PRs' GitHub titles shortened as LAND-1's C.1 does
(measured with `gh api` on each pull request of jmann345/carbon-lang).

| PR | Suffix | Spec | Workstream | Title | Summary | Moved | Next |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 60 | sc | FO-1 2.5 | SC-1 | SC-1, template-style structural conformance (F-010) | F-010: `template constraint` requirements satisfied by a type's own members, with W-139 realigned (checked generics call template-constrained functions per specific) and TP-1's S; W-139 discharged, W-373 filed | none | PR 56 (OP-1) |
| 56 | op | FO-1 2.6 | OP-1 | OP-1, Core.Optional comparison and the fork design F-015 | F-015: `Core.Optional` comparison, in place (W-352 discharged), with DD-1's state L for PR 56 | none | PR 57 (OP-2), after the orchestrator retargets it to trunk |
| 57 | op2 | FO-1 2.7 | OP-2 | OP-2, Core.Optional owns its value, the MaybeUnformed unsafe-as fix, checked Get | F-016: ownership, adapter destruction, the MaybeUnformed fix and checked Get, with item 10 fixed; W-170, W-171, W-173 discharged; Optional row DONE | none | PR 59 (VA-1) |
| 59 | va | FO-1 2.8 | VA-1 | VA-1, definition-checked variadics, slice 1 | W-013 slice 1 with W-367's TODO and W-368's layout, M-VA and S-VA; row 53 PARTIAL; W-343 discharged | none | PR 66 (VA-2), after the orchestrator retargets it to trunk |
| 66 | va2 | FO-1 2.9 | VA-2 | VA-2, definition-checked variadics, slice 2 | W-212, W-213 and W-225: generic and heterogeneous packs, tuple pack segments, variadic impls | none | the orchestrator's stamp after the follow-ons |

The targets of A.5 and A.6:

| PR | Plan file and anchor (A.5) | Decision-log entry (A.6) |
| --- | --- | --- |
| 60 | fork/structural/plan.md, the end of the file, under a new heading `### Landed notes (SC-1, LAND-1)` after "Landed notes (SC-1 fill rounds, 2026-10-13)" | `### SC-1: template structural conformance (F-010) (2026-10-12)`, after D.3's paragraph |
| 56 | fork/optional/plan.md, the end of the file, after D.4's paragraph | `### OP-1 / F-015: Core.Optional comparison and design (2026-10-13)`, after D.4's paragraph |
| 57 | fork/optional2/plan.md, the end of the file, after D.1's section | `### OP-2 / F-016: Core.Optional ownership, adapter destruction, the MaybeUnformed representation fix, checked Get (2026-10-14)`, after D.2's paragraph |
| 59 | fork/variadics/plan.md, the end of the file, after D.5's section | `### VA-1: definition-checked variadics, slice 1 (2026-10-14)`, after D.5's paragraph |
| 66 | fork/variadics/va2-plan.md, the end of "Landed notes (VA-2, 2026-10-27)", before `## Appendix A. Conformance programs, golden sources and records` | `### VA-2: definition-checked variadics, slice 2 (2026-10-27)` |

Each landing's records commit also writes LAND-1's A.3 Branches row, A.4's
dated paragraph and header, A.8's gap header sentence, A.9's Scoreboard
paragraph and A.10's mark on the gap rows its PR's records labelled "not of
record", and marks its Next actions item (15, 16 or 17) done with the
landing's merge sha; item 10's and item 13's marks go with stages 15 and 16.
The anchors were read at the heads of section 0.1 and are re-checked unique on
each landing's records tree (D-LAND-9).
