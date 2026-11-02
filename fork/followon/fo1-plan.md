<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# FO-1 plan: the follow-ons that gate the held PRs, then their landings

**Status:** rev 2, 2026-11-02 -- reviews A and B of rev 1 folded (the review
fold record at the end of the plan); not signed off: the re-review decides.
Records only: this plan changes no toolchain, prelude, golden,
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

W-139 is realigned on upstream's Carbon path (rewritten 2026-11-02, review
fold: A-B-1 / A-B-2 / A-B-3 / B-B-1 / B-M-1). A call that passes a
checked-symbolic argument to a `template` binding stays an ordinary call with
its declared, substituted return type, as upstream's toolchain makes it when
the binding's constraint is an interface; only the structural check of that
argument is deferred, to each specific of the caller, where the argument is
concrete: the deduced value is the argument's conversion performed per
specific (a `ConvertToValueAction` in the caller's eval block, deduce.cpp).
Measured on M60's tree (`sim60` with S): a checked generic calling a
template-constrained function prints 7; an unsatisfying argument is reported
as ``unable to monomorphize specific `Caller(D)` `` with SC-1's notes; a misuse
of the call's result is diagnosed at the checked generic's definition, as for
an interface; and the same deduction covers a generic class's and a generic
interface's `template` parameter, `Holder(U)` and `J(U)` (D-FO1-2). The commit
touches only SC-1's own files, so it goes on PR 60's branch before the land
merge, in item 15's order. Rev 1's mechanism, CT-1's C++ call deferral widened
to Carbon callees, made the call's result template-dependent inside a checked
generic and was upstream's spelling for C++ template names only; it is
withdrawn (section 7).

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
bullets (section 5); stage 13's row is measured on M60's tree with S, rev 2's
B1 and its fills (196/0/14 over 210, 50 bullets, gate 2003 of 2003).

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
-   Appendix E: the landings' fields (LAND-1 Appendix C rows) and each
    landing's records values
-   Appendix F: the orchestrator's stamps
-   Review fold record (rev 2)

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
were read at. `$Q` is the fixer's scratch directory
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/fo1/fixer,
whose land tree for rev 2 was a detached worktree /dev/shm/fo1-fixer/wt at
`sim60` with S (02fc31f10), then rev 2's B1 (bd47fd623), built with
CB_BUILD_ROOT=/dev/shm/fo1-fixer/builds and deleted with rev 2's commit (added
2026-11-02, review fold: A-B-1 / B-B-1).

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

Probe files are in `$P/probes`, `$P/i10`, `$P/w139`, `$P/w352`, `$P/w368` and,
for rev 2's W-139 table, `$Q/p`; each line is the first diagnostic or the
program's output.

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

**W-139** (rewritten 2026-11-02, review fold: A-B-1 / A-B-3 / B-B-1 / B-M-1).
The probes are in `$Q/p` with the runner `$Q/run.sh`: p1 (a checked
`Caller[U: type](x: U)` calling `CallGet`, whose `template T: HasGet` is a
template constraint, with `C.Get` returning 7), p2 (callers with a `D` lacking
`Get` and an `E` whose `Get` returns `bool`), p3 (the definitions only), n1
(the same call with a nominal interface); review A's x1 (`let b: bool =
CallGet(x);` in `Caller`), x10 (a concrete `D` for `T` beside a symbolic `V`),
x14 (`CallGet(x).foo`) and x5 (`Box(U)` for `class Box(template T: HasGet)`);
review B's gc (the same with `Holder`); and the fixer's gcd (`Holder(U)` in
`Make(D)`), iface (`J(U)` for `interface J(template T: HasGet)`), chain (a
checked `Caller2[V: type]` calling `Caller`), dup (`Sum[template T: HasGet](x:
T, y: T)` called with two `U` arguments) and conv (`let T: HasGet = U;`, a
conversion outside a call). Each cell is the first diagnostic or the output:

| Probe | trunk, the nightly | PR 60's install | rev 1's B1 (reviews A and B, on their land trees) | rev 2's B1 (`sim60` with S, bd47fd623) |
| --- | --- | --- | --- | --- |
| p1 | "unrecognized declaration introducer" (no `template constraint`) | ``cannot convert type `U` into type implementing `HasGet` `` at the definition (D-SC-6) | prints 7 | prints 7 |
| p2 | the same | the same | ``unable to monomorphize specific `Caller(D)` `` and `Caller(E)` | ``unable to monomorphize specific `Caller(D)` `` with "type `D` has no member named `Get` required by template constraint `HasGet`", and `Caller(E)` with "member `Get` of type `E` does not match the signature required by template constraint `HasGet`", one error each |
| p3 | the same | the same | checks | checks |
| n1 | checks | checks | checks | checks |
| x1 | the same as p1 | as p1 | checks with no diagnostic (the call's type is template-dependent) | ``cannot implicitly convert expression of type `i32` to `bool` `` at the definition, as n2 (its nominal analog) on trunk |
| x10 | as p1 | ``cannot convert type `D` into type implementing `HasGet` `` at the definition | checks with no diagnostic | the same as PR 60's install, at the definition |
| x14 | as p1 | as p1 | checks with no diagnostic | ``member name `foo` not found in `i32` `` at the definition |
| x5, gc | as p1 | ``cannot convert type `U` into type implementing `HasGet` `` with `StructuralRequirementNeedsConcreteType` | the same as PR 60's install | x5 returns 1, gc returns 3 |
| gcd | as p1 | as x5 | as x5 | ``unable to monomorphize specific `Make(D)` `` with SC-1's notes |
| iface | as p1 | as x5 | as x5 | prints 5 |
| chain, dup | as p1 | as p1 | not run | chain prints 8, dup prints 7 |
| conv | as p1 | ``cannot convert type `U` into type implementing `HasGet` `` with `StructuralRequirementNeedsConcreteType` | the same | the same (D-SC-6 kept outside a call) |

Review A's x11, x12 (a method `w.CallGet(x)`) and x13 (`Id[template T:
HasGet](x: T) -> T` in `Caller[U: Core.Copy]`) return 8, print 7 and check on
rev 2's B1; review B's ct (a C++ template call in a checked generic) is
unchanged (B1 does not touch call.cpp). So passing a symbolic constant to a
template parameter already works for a nominal constraint, on the fork and in
upstream's nightly, with the call an ordinary call; rev 2's B1 makes the
structural case the same call, with SC-1's check moved to each specific.

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
| `sim57x60` with S, D-FO1-1 and rev 1's W-139 (withdrawn, section 7) | incremental | 2001 passed, 10 failed of 2011 | not run | the nine refills and fail_template_constraint_checked_binding.carbon, whose splits `fail_symbolic_arg` and `fail_require_in_interface_symbolic` now succeed |
| `sim60` with S and rev 2's B1, the fixer's land tree (bd47fd623; added 2026-11-02, review fold: A-B-1 / B-B-1) | incremental, 4 steps after the first (deduce.cpp, structural_conformance.cpp and context.h's dependents) | 2000 passed, 3 failed of 2003: fail_template_constraint_checked_binding.carbon (its splits `fail_symbolic_arg` and `fail_require_in_interface_symbolic` succeed, a `fail_`-prefix problem the renames resolve) and F-M60's two refills; nothing else | not run before the fills | B1 changes no other golden |
| the same with Appendix A.2's sources, F-B1's and F-M60's autoupdate and B.1's program | autoupdate only | 2003 passed, 0 failed of 2003 (autoupdate's second pass writes nothing) | 196 PASS, 0 FAIL, 14 SKIP of 210; 50 bullets | none |
| review A's land tree fbd411c6b: `sim57x60` merged with `sim66`, S, A1, rev 1's B1, W-352's block and W-367 (scratchpad/fo1/reviewA; added 2026-11-02, review fold: A-m-5) | full | 2020 passed, 26 failed of 2046 | not run | every failure a CHECK-only refill (VA-2's and PR 57's compositions, the W-352 set, F-M60's two) or rev 1's two `fail_`-prefix splits; no crash; i10a with A1 returns 0 and `self_facet_in_signature_required` passes there; W-367's TODO fires on h01, h07, h08, h10 and h13 |
| M18 on the fixer's land tree: rev 2's B1 with its fills and S's hunk reverted (added 2026-11-02, review fold: B-m-2) | incremental | 1993 passed, 10 failed of 2003: the eight template-constraint goldens, fail_template_constraint_checked_binding.carbon and lower/template/template_constraint.carbon | 193 PASS, 3 COMPILE-FAIL, 14 SKIP of 210; 49 bullets | the three programs that compile a template constraint's member through a `template` binding (generics/structural_conformance.carbon, interop/cpp_structural_conformance.carbon and B.1's) fail on ``member name `Get` names different entities``; M18 killed |
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
| toolchain/check/deduce.cpp, toolchain/check/structural_conformance.cpp, toolchain/check/context.h | none in deduce.cpp and structural_conformance.cpp (identical at cc4daba00 and on `sim60`); trunk's members in context.h (+20 lines, other regions) | B (W-139; rewritten 2026-11-02, review fold: A-B-1 / A-m-2 / B-B-1 / B-M-2) | none: rev 2's B1 applies at cc4daba00 (`git apply --cached --check` on a temporary index, `$Q/w139/B1v5_toolchain.patch`), and the merge of cc4daba00 plus B1 with trunk (scratch faee2a044) conflicts in the four files of section 0.3's PR 60 row only and gives these three files byte-identical to the land tree's; B1 uses upstream's `AddDependentActionInst`, `AddInstInNoBlock`, `TemplateInst`, `SpliceInst` and `ConvertToValueAction`, all at cc4daba00, and no CT-1 code. DR-1's test on its added lines: no `TemporaryStorage`, no `return_arg_id`, no `ConvertCallArgs` (0 of each), and 0 in SC-1's and VA-1's own call.cpp and convert.cpp lines |
| toolchain/check/call.cpp | CT-1's `IsCheckedSymbolicCppArg` and `DeferCppCallOnSymbolicArgs` (PR 64); OV-4's resolution (PR 68); DR-1's return storage (PR 63, PR 65) | none since rev 2 | rev 1's B1 widened `DeferCppCallOnSymbolicArgs`; withdrawn (section 7) |
| toolchain/check/convert.cpp | TP-1's A2 `PendingBlock`, `SpliceInst`, `AddConvertActionIfDependent` (PR 61); CT-1 (PR 64) | PR 60's merge | the merge's two regions (section 0.3); W-139 does not touch convert.cpp (the planner's first prototype there, a `ConvertAction` splice in `PerformBuiltinConversion` for every checked-symbolic conversion to such a facet type, failed deduction with "inconsistent deductions for value of generic parameter `T`", `$P/w139/p1.txt`; rev 2's B1 converts once per binding and argument in a deduction and leaves other conversions to D-SC-6, section 7) |
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
W-367 add goldens only. Stage 15 also adds SV-1's nested-pointer leg to
interop/cpp_sum_type_roundtrip_diff.carbon and its `.diff.cpp` oracle (Appendix
B.5; added 2026-11-02, review fold: B-M-4).

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
-   toolchain/check/call.cpp:386-395, inside `PerformCallToNonFunction`'s
    `case CARBON_KIND(SemIR::CppTemplateNameType template_name):` (:378):
    "// Wrap symbolic template args in a `TemplateInst` so that all symbolic //
    arguments are treated as templates." over `SemIR::TemplateInst{.type_id =
    arg.type_id(), .inst_id = arg_id}`, then `AddDependentActionSplice(context,
    loc_id, SemIR::CallAction{...})`. It is the only `TemplateInst{` under
    toolchain/check at the tip (`git grep -n 'TemplateInst{' 68569d234 --
    toolchain/check`: one line, :394), so the wrapping and the `CallAction` are
    upstream's spelling for a C++ template name given a symbolic argument; for
    a Carbon callee with a `template` binding, upstream's call is an ordinary
    call with a symbolic specific and the callee's declared return type (n1
    checks on trunk and the nightly, and n2 and n1m, its result misused, are
    diagnosed at the definition, section 0.2) (amended 2026-11-02, review fold:
    A-B-2 / B-B-1).
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
    list)"); no text on a choice alternative's parameter list: the count of
    `git grep -c -i -E 'choice|alternative'` is 2 over variadics.md (the
    "Alternatives considered" heading and its contents link, :36 and :975) and
    15 over
    proposals/p002240-variadics.md, each "alternative(s) considered" or "choice"
    in its English sense, none about a choice alternative's parameter list
    (amended 2026-11-02, review fold: A-m-5: rev 1 said p002240 had no hits).
-   The tip's parser: a choice alternative's parameter list is
    `StateKind::PatternListAsExplicit`
    (toolchain/parse/handle_choice.cpp:86-88), and `...` is a statement prefix
    only (handle_statement.cpp:54-58, `PackExpansionStart`), so `...` in a
    pattern list reports `ExpectedPattern` "expected pattern"
    (handle_expr.cpp:270); the nightly prints it at 1:14 for h01, at 1:17 for
    h08 (`choice C { A, B(... each x: i32) }`), at 2:16 for h10 (the choice in
    a class) and at 1:6 for h03 (`fn F(... each x: i32) -> i32`), so upstream's
    parser refuses a pack expansion pattern in every parameter list, not only a
    choice alternative's (amended 2026-11-02, review fold: A-m-5).

Upstream commits since the cut touching each slice's files (R32 (c), by sha
and subject; `git log c1e83b0b7..68569d234 -- <files>`):

| Slice | Files | Commits | Change to a stated mechanism or prelude signature |
| --- | --- | --- | --- |
| A, C | core/prelude/types/optional.carbon, comparison.carbon, destroy.carbon, check/custom_witness.cpp, comparison_operators.md | 05a7ecbd3 "Move `SubobjectDestroy` and `SelfDestruct` out of interface `Destroy` (#7942)"; 51e2c76a8 "Add a HasError helper to SpecificStore (#7970)"; f396762e2 "Fix destroying function-local `var`s of choice types (#7941)"; 6c1d2a86e "Fix crashes on impl lookup for bound method types (#7940)"; 947c1eb52 "Add a `Core.Array` class type, and make `array` refer to it. (#7892)" | 05a7ecbd3 changes `Destroy`'s signature (OP-2's `(self.value unsafe as T).(Destroy.SelfDestruct)()` is W-354's, UA-3's); optional.carbon is untouched (RG-1's H6.4 check holds) |
| B | generics/*.md, templates.md, check/call.cpp, deduce.cpp, convert.cpp, member_access.cpp, merge.cpp | 503f09037, db87a84b6, 0d3b606a5, 3af25cc1b, 7beb29f8b, 2c9739799, bf5d2a2ac, 62f1cc6a3, 230227264, 059ee7b9e, 4a8993af2, 947c1eb52, 5fed32a9a | none on issue 2153: overview.md and appendix-witness.md were last touched by 7134e23f2 (2026-09-29), an ancestor of the cut; db87a84b6 ("Improve tests and clarify design for observe equivalence chains (#7987)") clarifies `observe`, not template calls |
| D | variadics.md, p002240.md, check/handle_pack_expansion.cpp, lower/type.cpp, handle_choice.cpp (check and parse) | 68569d234; a045da8e6 "Document the discrepancy between checking and execution for variadics (#7963)"; 62f1cc6a3; 9fd28f730; 2ec4bab59 "Lex and parse support for `...` statements and `expand`. (#7832)" | a045da8e6 documents checking versus execution, not parameter lists; 2ec4bab59 parses `...` as a statement only |

Register entries DR-0 keeps that the slices discharge or touch (RG-1's
vocabulary, fork/register/rg1-plan.md):

-   W-139 is H9.5, the DRIFT entry of RG-1's SC-1 block (W-139's notes and
    rg1-plan.md's section 2.H3): discharged by Slice B for every `template`
    binding a call deduces (a function's, a generic class's and a generic
    interface's), and H9.5 becomes ALIGNED with its gap named by D-RG-4 ("An
    entry that implements part of an upstream-designed mechanism with
    upstream's spelling, its gap carried by a work item, is ALIGNED with the
    gap named"); the gap, the `require` of an impl in a generic class, is a
    case issue 2153 does not decide, so it is W-373 under its own row H9.7,
    NONE by D-RG-1 with a silence check; and Slice B's per-specific check
    (deduce.cpp's eval-block `ConvertToValueAction` and the deferral counter)
    is toolchain-internal, H9.8, NONE by D-RG-3 with a silence check (D-FO1-3,
    D-FO1-13, Appendix D.6; amended 2026-11-02, review fold: A-B-2 / B-B-1 /
    B-m-7).
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
of upstream's completion in a fork-modified function); Slice B's call is
upstream's Carbon path, an ordinary call with a symbolic specific, and its
per-specific check is internal machinery for a surface upstream lacks
(structural requirements, H9.3), registered NONE (H9.8), not a second spelling
of upstream's C++ `TemplateInst` deferral, which rev 1 claimed it was (amended
2026-11-02, review fold: A-B-2 / B-B-1); Slice C's private interfaces are
prelude-private machinery; and Slice D refuses, with a TODO in VA-1's check, a
form upstream's parser refuses in every parameter list.

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
and is taken by D-FO1-3, reserved by the sign-off stamp (Appendix F.1) so that
a weekly check cannot take it first (amended 2026-11-02, review fold: B-m-4);
W-374 follows.

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

**D-FO1-2, W-139's mechanism, its order and its texts** (rewritten 2026-11-02,
review fold: A-B-1 / A-B-2 / A-B-3 / A-m-2 / B-B-1 / B-M-1 / B-M-2). Upstream
decided that a symbolic constant may be passed to a template parameter and that
the call relies on monomorphization (overview.md:375-379,
appendix-witness.md:151-156). For a Carbon callee its toolchain makes such a
call an ordinary call with a symbolic specific: the callee's declared return
type is substituted, and the rest of the checked generic is checked at its
definition (n1, n2 and n1m, section 0.2); its `TemplateInst` wrapping and
`CallAction` are the C++ template name's (call.cpp:386-395, the only such site,
section 0.6). SC-1 adds what upstream lacks, structural requirements, which only
a concrete self can be checked against (D-SC-6). So B1 keeps upstream's call and
defers only that check. When a call's deduction converts a checked-symbolic
argument for a `template` binding whose facet type has structural requirements,
the conversion runs with those requirements deferred
(`CheckStructuralRequirements` counts them through the context's deferral
counter instead of rejecting the self), the facet type's interfaces are still
checked at the definition, and the deduced value is the conversion performed
again in each specific of the enclosing generic: a `ConvertToValueAction` in the
caller's eval block on the argument wrapped in a `TemplateInst`, so that the
action waits for a concrete argument, spliced as a value of the binding's type.
Where the argument does not conform, the specific reports SC-1's diagnostic and
notes (``unable to monomorphize specific `Caller(D)` ``); in the generic, the
callee's specific is template-dependent, so the template's body is instantiated
only for a concrete argument, the monomorphization appendix-witness.md names;
the same argument for the same binding is converted once per deduction, so a
binding deduced from two parameters is consistent (dup). The deduction is the
one a generic class's and a generic interface's explicit parameters take, so
`Holder(U)` and `J(U)` are covered (gc, gcd, iface). Only a call's deduction
defers (`DeduceGenericCallArguments`); impl deduction, a conversion outside a
call (conv) and the `require` of an impl in a generic class keep D-SC-6's
rejection (D-FO1-3). B1 changes deduce.cpp, structural_conformance.cpp's D-SC-6
branch and context.h, files SC-1's branch holds unchanged by trunk but for
context.h's other regions, and uses no CT-1 code (section 0.4), so it is made on
PR 60's branch before the land merge, in item 15's order (B1, F-B1, D-B, B-R,
then M60) and as D-LAND-12 states it ("G-60 (PR 60) when W-139's fix commit is
on PR 60's branch"); D-LAND-12's break condition does not fire and no amendment
of it or of item 15 is owed (rev 1's order, B1 after M60, is withdrawn with its
mechanism). The docs: template_constraints.md:456-468 is rewritten and a dated
note follows RG-1's (Appendix C.1); D-SC-6 in fork/structural/plan.md gains a
dated amendment (C.2). _Break condition:_ B1's gate on PR 60's branch, or on
M60's tree, changes a golden other than
fail_template_constraint_checked_binding.carbon and
lower/template/template_constraint.carbon (and, on M60's tree, F-M60's two); or
a review shows a call whose checked-symbolic argument for such a binding is
still rejected at the definition, or whose result or concrete argument escapes
the definition's check; then the root is re-measured and B1 re-planned before
its commit; or upstream's tip gives a Carbon callee's template parameter another
mechanism (B1 then follows it).

**D-FO1-3, W-139's shrink line: the generic class's `require`** (amended
2026-11-02, review fold: A-B-3 / B-M-1 / B-m-4 / B-m-7). W-139's notes also name
an impl inside a generic class whose interface `require`s a template
constraint, whose self (`Box(T)`) is checked-symbolic at the class end
(template_constraint_require.carbon's
`fail_todo_require_in_interface_in_generic_class_impl`). No template parameter
receives a symbolic constant there (the self is the impl's, checked by
`CheckDeferredRequireDeclsAtClassEnd`), so issue 2153 does not decide it,
whereas a generic class's own `template` parameter given a checked-symbolic
argument (`Box(U)`), which it does decide, is covered by B1 (D-FO1-2). The
reclassification follows RG-1's rules: D-RG-4 ("An entry that implements part
of an upstream-designed mechanism with upstream's spelling, its gap carried by a
work item, is ALIGNED with the gap named ... It is a DRIFT only when the fork's
rule decides a case the design decides otherwise") makes H9.5 ALIGNED with
W-373 named, and D-RG-1 makes the gap's own row H9.7 NONE ("a fork-local surface
with no upstream counterpart: upstream is silent"), shown by a silence check
with its rg1-checks.tsv row (Appendix D.6). W-373 is reserved by the sign-off
stamp (Appendix F.1) and filed on PR 60's branch by B-R; W-139 is discharged.
_Break condition:_ upstream states how a checked-symbolic self satisfies a
requirement that needs a concrete type, or lands interface/require.carbon's
`fail_todo_implicit_self_impls` (the D-SC-6 break condition and H9.7's check);
D-RG-4's break condition then applies: H9.5 is re-classified DRIFT and W-373
re-titled and scheduled as the drift.

**D-FO1-4, W-352's in-place route.** Two private interfaces over the storage
type, `OptionalStorageEq(T)` and `OptionalStorageOrdered(T)`, each with a
blanket impl for `T.(OptionalStorage.Type)` that compares the values `T.Get`
returns and a more specialized impl for `DefaultOptionalStorage(T)` that
compares `(a.value unsafe as T)` with `(b.value unsafe as T)`, as RG-1's probe
did (rg1-plan.md section 4.8); the comparison impls' bodies call them. The impl
headers, the six function signatures and F-015's API table rows
(docs/design/optional.md:98-99) are unchanged; in a checked generic, the call
dispatches through the symbolic witness and is specialized at monomorphization
to the in-place impl (measured: gcount prints 0 copies and 0 destroys). Only the
pointer niche reaches the fallback impl: a `Core.Optional(C*)` compares through
it when the program makes `C*` comparable, as optional.md (:304-320 at
9f12209d8) and OP-1's optional_nested_pointer.carbon do with `impl C* as
Core.EqWith(C*)`, and its `Get` is a primitive copy of the pointer with no
observable effect (measured by review A: optional_nested_pointer.carbon still
prints `1 0 0 1 1`; amended 2026-11-02, review fold: A-m-3; rev 1 said `T*` was
never `Eq` in 0.1). Two routes were measured and rejected: the bound `where
.Type impls OptionalStorageEq`, which keeps concrete code in place but rejects
OP-1's generic program (its four comparisons, "cannot access member of interface
`Core.EqWith(...)`"), and a `template` impl, which hits W-250's TODO across the
library boundary. One commit C1 on PR 56's branch with its fill F-C1, the
program and the docs, then PR 56's branch merged into PR 57's (C-M57) with its
refill. W-352's break condition (the route cannot keep D-OP-4's signatures or
F-015's API) is tested and does not fire. _Break condition:_ a review shows the
blanket impl over an associated type is an upstream impl rule's violation (an
orphan or overlap rule upstream states at its tip), or C1's gate or C-M57's
changes a golden outside the set section 2.3 and section 4 name (OP-1's, OP-2's
and SV-1's optional goldens, and lower for/bindings.carbon and
interop/cpp/pointer.carbon, which print the prelude's IR names; amended
2026-11-02, review fold: A-m-3 / B-m-1: rev 1's condition left out the two lower
files its own measurement named); then W-352 gains `blocked_by` W-320 as its own
break condition says, and PR 56 and PR 57 wait.

**D-FO1-5, W-367: the refusal at the root.** In handle_pack_expansion.cpp's
`Pattern` case, a pack expansion pattern whose list is a choice alternative's
(the innermost scope is the choice's `ClassDecl` with no name scope,
`ScopeStack::PushForChoiceAlternative`) is refused with the TODO ``pack
expansion pattern in a choice alternative's parameter list``, with a `TODO:`
comment, pinned by the split `fail_todo_choice_alternative` in
check/testdata/variadics/fail_todo_slice.carbon (commit D1, fill F-D1), and
W-367 is filed in PR 59's branch's ledger by the records commit D-R beside it
(D-LAND-13). The test is the scope, which review A measured correct on h01, h07,
h08, h10 and h13 on PR 66's merge (fbd411c6b); the splits
`fail_todo_choice_second_alternative` (h08) and `fail_todo_choice_in_class`
(h10) pin it beside h01's, and VA-1's own splits of a function's and an
interface function's lists pin that the test does not catch them (Appendix A.3;
amended 2026-11-02, review fold: A-m-5). Not a parse-time guard (VA-1's parser
accepts the form as upstream's lexer and parser would once they parse pattern
`...`; the check is where VA-1 admits it), and not a lowering guard (that would
hide the IN form). Upstream is silent in its design, and its parser at the tip
rejects a pack expansion pattern in every parameter list, a function's included
(h03, section 0.6), so this is VA-1's own refusal in the one list its check
admits but cannot lower: the fork rule is the TODO, registered under W-355 as
NONE (amended 2026-11-02, review fold: A-m-5). _Break condition:_ upstream's
design or proposal p002240 speaks to choice alternatives, or a VA-2 change
reaches a choice alternative's parameters (VA-2's hand-off note 9).

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

**D-FO1-9, the review rules** (rewritten 2026-11-02, review fold: B-m-3). Each
PR's own rule, quoted: SC-1, "the ONE implementation review runs after the
hosted verification of SC-1c is green (R29(c))"
(fork/structural/plan.md:2056-2057 at cc4daba00), never green while Actions is
disabled, so two, as its fill rounds ran; OP-1, "After commit 4, stop for the
implementation review of R29(c)", folded as two (fork/optional/plan.md:3199 and
:3296 at 9f12209d8); OP-2, "ONE review once hosted verification is green; until
then two, the OP-1 precedent" (fork/optional2/plan.md:2964-2965 at e23113ba2);
VA-1, "D, discharge, after two implementation reviews: R29(c) drops to one only
once hosted verification is green, and GitHub Actions is disabled on the fork
... so it never is" (fork/variadics/plan.md:6945-6948 at b0822a744); VA-2,
"**Implementation reviews** (two, R29(c))" (its section 3 item 12,
fork/variadics/va2-plan.md:6523 at 43c8ab476), since its item 15, which lists
the land-time commits M, S-CT, F-M, L-F and L, states no count. One rule follows
for every branch commit of this plan: the slices (A1 to A-R, B1 to B-R, C1 to
C-R, D1 to D-R) and the branch land commits (M60 to B-R2, M56 to L56, M57 to
L57, M59 to L59, VA-2's M to L) each take two fresh implementation reviews and a
separate fixer (R11); where those commits edit a design page (D-B, L60, C-R's
optional.md, L56, L57's Doc-M), both implementation reviewers also review the
page as its document review (R29(c)'s two reviewers), so no page waits for the
trunk landing; and each trunk landing, whose head already holds every code and
page commit (D-FO1-8), takes D-LAND-10's one fresh reviewer of the records-only
landing. _Break condition:_ hosted verification returns green before a slice's
review; then the PR's own rule gives one implementation reviewer, and a page
edit keeps its two document reviewers.

**D-FO1-10, the fix budgets and shrink lines.** Slice A: one code commit and its
fill; at most two fix commits after its reviews; no shrink (the defect blocks
PR 57). Slice B: one code commit, its fill, the docs and records; at most three
fix commits; the shrink line is D-FO1-3's (already taken for the `require`
path); a further shrink is not allowed (every `template` binding a call deduces
is the drift, functions, generic classes and generic interfaces alike; amended
2026-11-02, review fold: A-B-3 / B-M-1). Slice C:
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
W-373 (D-FO1-3) is reserved on trunk by the sign-off stamp (Appendix F.1) and
filed on PR 60's branch by B-R (amended 2026-11-02, review fold: B-m-4); W-369
and W-370 stay reserved for a residue a FO-1 landing finds, filed in trunk's
ledger by that landing's records commit, otherwise unused; anything else takes
W-374 onward after a re-scan. _Break condition:_ any of these filed elsewhere
first; then the next free id after a re-scan, recorded in the commit.

**D-FO1-13, the register entries** (amended 2026-11-02, review fold: A-B-2 /
B-B-1 / B-m-7). FO-1's records commits write: W-139's discharge note, W-140's
note and W-373's entry (B-R, on PR 60's branch before M60); H9.5's verdict
ALIGNED with W-373 named (D-RG-4), the rows H9.7 (W-373, NONE, D-RG-1) and H9.8
(B1's per-specific check, NONE, D-RG-3), each NONE row with its silence check
in rg1-checks.tsv (B-R2, after M60 brings the register files); H5.4's verdict
ALIGNED with W-352's discharge note (C-R); and H8.9 for W-367's refusal with its
check row (L59); each in RG-1's vocabulary with its break condition and W-355
as its item, and each re-checked by the weekly upstream check's quote and grep
scripts (Appendix D.6). _Break condition:_ the weekly check classifies one of
them otherwise; its records rule.

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

Rewritten 2026-11-02 (review fold: A-B-1 / A-B-2 / A-B-3 / A-m-1 / A-m-2 /
B-B-1 / B-M-1 / B-M-2 / B-m-6). Branch claude/carbon-fork-0-1-sc at cc4daba00
(PR 60), before the land merge M60 (D-FO1-2: B1 uses SC-1's files only).
Commit B1, "SC-1 fix: a checked generic's checked-symbolic argument for a
template binding is checked per specific (W-139; leads issue 2153)", changes
toolchain/check/deduce.cpp, toolchain/check/structural_conformance.cpp,
toolchain/check/context.h, the test sources of Appendix A.2 and the program of
Appendix B.1. The code, measured on `sim60` with S (scratch bd47fd623, whose
`ConvertBindingArg` comment and two wrapped lines differ from the text below;
B1 is this text, `$Q/w139/B1v5_toolchain.patch` the measured hunk):

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/context.h
+++ b/toolchain/check/context.h
@@ auto deferred_structural_requires()
   auto deferred_structural_requires()
       -> llvm::SmallVector<DeferredStructuralRequire>& {
     return deferred_structural_requires_;
   }
+
+  // Fork (SC-1, W-139): while not null, `CheckStructuralRequirements` defers
+  // the structural requirements of a checked-symbolic self instead of
+  // rejecting them (D-SC-6), counting each deferral here. Set by deduction
+  // while it converts a checked-symbolic argument for a `template` binding,
+  // which it then checks again in each specific (deduce.cpp).
+  auto structural_check_deferrals() -> int*& {
+    return structural_check_deferrals_;
+  }
@@
   // Fork (SC-1): see `deferred_structural_requires()`.
   llvm::SmallVector<DeferredStructuralRequire> deferred_structural_requires_;
+
+  // Fork (SC-1, W-139): see `structural_check_deferrals()`.
+  int* structural_check_deferrals_ = nullptr;
--- a/toolchain/check/structural_conformance.cpp
+++ b/toolchain/check/structural_conformance.cpp
@@ static auto CheckRequirements(Context& context, SemIR::LocId loc_id,
     // D-SC-6: a checked-symbolic self never satisfies a structural
     // requirement. (A checked binding whose own facet type names a template
     // constraint has an error type, D-SC-8(i), so it is not such a self.)
+    // Fork (SC-1, W-139): except when a call passes it to a `template`
+    // binding, which checks it in each specific of the caller instead
+    // (deduce.cpp, `ConvertBindingArg`).
     if (self.is_symbolic()) {
+      if (auto* deferrals = context.structural_check_deferrals()) {
+        ++*deferrals;
+        continue;
+      }
       if (mode.explain) {
--- a/toolchain/check/deduce.cpp
+++ b/toolchain/check/deduce.cpp
@@
 #include "llvm/ADT/SmallBitVector.h"
 #include "toolchain/base/kind_switch.h"
+#include "toolchain/check/action.h"
 #include "toolchain/check/context.h"
 #include "toolchain/check/convert.h"
 #include "toolchain/check/generic.h"
+#include "toolchain/check/inst.h"
+#include "toolchain/check/structural_conformance.h"
 #include "toolchain/check/subst.h"
@@ class DeductionContext {
   auto MakeSpecific() -> SemIR::SpecificId;

+  // Fork (SC-1, W-139): a call's deduction, not an impl's, defers the
+  // structural requirements of a checked-symbolic argument for a `template`
+  // binding to each specific (`ConvertBindingArg`).
+  auto DeferStructuralChecksOfTemplateArgs() -> void {
+    defer_structural_checks_of_template_args_ = true;
+  }
+
  private:
+  auto ConvertBindingArg(SemIR::InstId binding_id, SemIR::InstId arg_id,
+                         SemIR::TypeId type_id) -> SemIR::InstId;
+
   auto NoteInitializingParam(SemIR::InstId param_id, SemIR::LocId loc_id,
@@
   SemIR::GenericId generic_id_;
   bool diagnose_;
+  // Fork (SC-1, W-139): see `DeferStructuralChecksOfTemplateArgs`.
+  bool defer_structural_checks_of_template_args_ = false;
+  // Fork (SC-1, W-139): the conversions `ConvertBindingArg` deferred.
+  struct DeferredConversion {
+    SemIR::InstId binding_id;
+    SemIR::ConstantId arg_const_id;
+    SemIR::InstId converted_id;
+  };
+  llvm::SmallVector<DeferredConversion> deferred_conversions_;
@@ auto DeductionContext::Deduce() -> bool {
       // `want_value` is only set within types and the arguments for symbolic
       // bindings, so this should never perform a runtime conversion.
-      arg_id = diagnose_ ? ConvertToValueOfType(context(), loc_id_, arg_id,
-                                                param_type_id)
-                         : TryConvertToValueOfType(context(), loc_id_, arg_id,
-                                                   param_type_id);
+      arg_id = ConvertBindingArg(param_id, arg_id, param_type_id);
@@ auto DeductionContext::CheckDeductionIsComplete() -> bool {
       auto converted_arg_id =
-          diagnose_ ? ConvertToValueOfType(context(), loc_id_, deduced_arg_id,
-                                           binding_type_id)
-                    : TryConvertToValueOfType(context(), loc_id_,
-                                              deduced_arg_id, binding_type_id);
+          ConvertBindingArg(binding_id, deduced_arg_id, binding_type_id);
@@ auto DeductionContext::CheckDeductionIsComplete() -> bool {
+// Fork (SC-1, W-139): returns whether `binding_id` is a `template` binding or
+// binding pattern.
+static auto IsTemplateBinding(Context& context, SemIR::InstId binding_id)
+    -> bool {
+  auto entity_name_id = SemIR::EntityNameId::None;
+  if (auto binding =
+          context.insts().TryGetAs<SemIR::SymbolicBinding>(binding_id)) {
+    entity_name_id = binding->entity_name_id;
+  } else if (auto pattern =
+                 context.insts().TryGetAs<SemIR::SymbolicBindingPattern>(
+                     binding_id)) {
+    entity_name_id = pattern->entity_name_id;
+  }
+  return entity_name_id.has_value() &&
+         context.entity_names().Get(entity_name_id).is_template;
+}
+
+// Converts `arg_id`, the argument for the binding or binding pattern
+// `binding_id`, to `type_id`.
+//
+// Fork (SC-1, W-139; leads issue 2153): "We have decided to support passing a
+// symbolic constant to a template parameter" (generics/overview.md), and such
+// a call "relies on monomorphization" (generics/appendix-witness.md). The call
+// stays an ordinary call with a symbolic specific, as when the binding's
+// constraint is an interface. A structural requirement can be checked only
+// for a concrete self (D-SC-6), so a checked-symbolic argument for a
+// `template` binding whose facet type has structural requirements is
+// converted with them deferred, its interfaces checked here, and the deduced
+// value is the conversion performed again in each specific of the enclosing
+// generic: a `ConvertToValueAction` in the eval block, on the argument wrapped
+// in a `TemplateInst` so that it waits for a concrete argument, spliced as a
+// value of `type_id`. A failure there is diagnosed when that specific is
+// formed, and the callee's specific, template-dependent until then, is
+// instantiated only for a concrete argument.
+auto DeductionContext::ConvertBindingArg(SemIR::InstId binding_id,
+                                         SemIR::InstId arg_id,
+                                         SemIR::TypeId type_id)
+    -> SemIR::InstId {
+  auto convert = [&] {
+    return diagnose_ ? ConvertToValueOfType(context(), loc_id_, arg_id, type_id)
+                     : TryConvertToValueOfType(context(), loc_id_, arg_id,
+                                               type_id);
+  };
+  auto arg_const_id = context().constant_values().Get(arg_id);
+  if (!defer_structural_checks_of_template_args_ ||
+      !IsTemplateBinding(context(), binding_id) ||
+      !arg_const_id.is_symbolic() ||
+      context().constant_values().GetDependence(arg_const_id) !=
+          SemIR::ConstantDependence::Checked ||
+      !FacetTypeHasStructuralRequirements(context(), type_id).has_value()) {
+    return convert();
+  }
+  int deferrals = 0;
+  auto* outer_deferrals =
+      std::exchange(context().structural_check_deferrals(), &deferrals);
+  auto converted_id = convert();
+  context().structural_check_deferrals() = outer_deferrals;
+  if (deferrals == 0 || !diagnose_ ||
+      converted_id == SemIR::ErrorInst::InstId) {
+    return converted_id;
+  }
+  // The same argument for the same binding is converted once, so that a
+  // binding deduced from two parameters is deduced consistently.
+  for (const auto& deferred : deferred_conversions_) {
+    if (deferred.binding_id == binding_id &&
+        deferred.arg_const_id == arg_const_id) {
+      return deferred.converted_id;
+    }
+  }
+  // Neither instruction is in a block: they are only the deduced value's.
+  auto template_arg_id = AddInstInNoBlock<SemIR::TemplateInst>(
+      context(), loc_id_,
+      {.type_id = context().insts().Get(arg_id).type_id(), .inst_id = arg_id});
+  auto action_id = AddDependentActionInst(
+      context(), loc_id_,
+      SemIR::ConvertToValueAction{
+          .type_id = SemIR::InstType::TypeId,
+          .inst_id = template_arg_id,
+          .target_type_inst_id = context().types().GetTypeInstId(type_id)});
+  auto deferred_id = AddInstInNoBlock<SemIR::SpliceInst>(
+      context(), loc_id_, {.type_id = type_id, .inst_id = action_id});
+  deferred_conversions_.push_back({.binding_id = binding_id,
+                                   .arg_const_id = arg_const_id,
+                                   .converted_id = deferred_id});
+  return deferred_id;
+}
+
@@ auto DeduceGenericCallArguments(
   DeductionContext deduction(&context, loc_id, generic_id,
                              enclosing_specific_id, diagnose);
+  deduction.DeferStructuralChecksOfTemplateArgs();
```

<!-- google-doc-style-resume -->

Why each part. Only a call's deduction defers (`DeduceGenericCallArguments`,
which serves functions, generic classes and generic interfaces alike, as
section 0.2's gc and iface show); `DeduceImplArguments` does not, so impl
selection is unchanged. The non-diagnosing deduction of OV-4's overload probe
(`ProbeOverloadCandidateInScratchScope`) gets the deferred conversion's value
and adds no instruction; the commit's diagnosing deduction makes the splice. The
facet type's interfaces are still looked up at the definition (mixed: a
`template T: HasGet & Core.Copy` given `U: type` is rejected there for
`Core.Copy`, and given `U: Core.Copy` prints 7, `$Q/p/mixed*.carbon`). The
splice, the `TemplateInst` and the action are in no block: the body's call uses
the specific, and on PR 60's branch, before trunk's TP-1 code arrives, nothing
new reaches lowering. D-SC-6's comment gains the sentence the hunk shows; its
rejection stays for every other entry point (conv, impl deduction and the
`require` of D-FO1-3).

Test sources (Appendix A.2): in
check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon
the file comment is rewritten; the split `fail_symbolic_arg` becomes
`symbolic_arg`, instantiated as `Caller(C)` (B-m-6); nine splits follow it
(`fail_symbolic_arg_unsatisfied`, `fail_symbolic_arg_mismatch`,
`fail_symbolic_arg_result_misused`, `fail_symbolic_arg_result_member`,
`fail_concrete_arg_beside_symbolic`, `fail_symbolic_conversion`,
`symbolic_class_arg`, `fail_symbolic_class_arg_unsatisfied`,
`symbolic_interface_arg`); and `fail_require_in_interface_symbolic` becomes
`require_in_interface_symbolic`, instantiated as `G(C)` with a `C` that
implements `I`. lower/testdata/template/template_constraint.carbon gains the
split `checked_caller`. Commit F-B1, "SC-1 fix fill: autoupdate W-139's splits
on the container arbiter", fills those two files. The CHECK-relevant lines,
measured by autoupdate on the land tree (`$Q/gate_b1_filled.txt`; autoupdate's
second pass writes nothing): no diagnostic for `symbolic_arg`,
`symbolic_class_arg`, `symbolic_interface_arg` and
`require_in_interface_symbolic`; for `fail_symbolic_arg_unsatisfied`, at
`Caller(d)`, ``error: unable to monomorphize specific `Caller(D)`
[ResolvingSpecificHere]`` and, at `CallGet(x)` in `Caller`, ``note: cannot
convert type `D` into type implementing `HasGet`
[ConversionFailureTypeToFacet]``, ``note: type `D` has no member named `Get`
required by template constraint `HasGet` [StructuralMemberMissing]`` and
``note: requirement declared here [StructuralRequirementHere]``; for
`fail_symbolic_arg_mismatch` the same for `Caller(E)` with ``note: member `Get`
of type `E` does not match the signature required by template constraint
`HasGet` [StructuralMemberMismatch]``; for `fail_symbolic_arg_result_misused`,
at the definition, ``error: cannot implicitly convert expression of type `i32`
to `bool` [ConversionFailure]`` with its `Core.ImplicitAs(bool)` note; for
`fail_symbolic_arg_result_member`, at the definition, ``error: member name `foo`
not found in `i32` [MemberNameNotFoundInSpecificScope]``; for
`fail_concrete_arg_beside_symbolic`, at the definition, ``error: cannot convert
type `D` into type implementing `HasGet` [ConversionFailureTypeToFacet]`` with
the missing-member, requirement and ``while deducing parameters of generic
declared here [DeductionGenericHere]`` notes; for `fail_symbolic_conversion`
``error: cannot convert type `U` into type implementing `HasGet` `` with
`StructuralRequirementNeedsConcreteType`; for
`fail_symbolic_class_arg_unsatisfied` ``error: unable to monomorphize specific
`Make(D)` `` with the three notes at `Holder(U)`. `checked_caller`'s IR has a
`Caller` specific for `C` calling a `CallGet` specific for `C`, which calls
`C.Get`; no symbolic function is lowered. The gate after F-B1 on M60's tree:
2003 of 2003 with F-M60's two fills (measured); on PR 60's branch before M60
the gate is predicted to name only these two files before F-B1 and none after
(a different set stops B1, D-FO1-2's break condition).

The program generics/structural_conformance_checked_caller.carbon (Appendix
B.1) is in B1: PASS on the land tree, conformance 196/0/14 over 210 with 50
bullets (measured). Commit D-B, the docs, rewrites template_constraints.md's
paragraph and adds a dated note after RG-1's (Appendix C.1), and amends D-SC-6
in fork/structural/plan.md (Appendix C.2). Commit B-R, the records on PR 60's
branch (Appendix D.3): W-139's discharge note, W-140's note (its title example
now checks; the residue is member lookup through the checked binding, A-m-1),
W-373 filed, the clause of the gap row "Generics: Template-style structural
conformance to nominal constraints" and SC-1's decision-log paragraph. Commit
B-R2, the register rows (Appendix D.6: H9.5, H9.7, H9.8 and their check rows),
waits for M60, which brings rg1-plan.md and rg1-checks.tsv to the branch
(section 2.5).

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
// only the pointer niche, compares the values `T.Get` returns, a primitive
// copy of the pointer, when the program makes the pointer type comparable.
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

private interface OptionalStorageOrdered(
    T: Destroy & OptionalStorage & Ordered) {
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

final impl forall [T: Destroy & OptionalStorage & Ordered]
    Optional(T) as OrderedWith(Optional(T)) {
  fn Less(self, other: Optional(T)) -> bool {
    if (not other.HasValue()) {
      return false;
    }
    if (not self.HasValue()) {
      return true;
    }
    return T.Type.(OptionalStorageOrdered(T).PayloadLess)(self as T.Type,
                                                          other as T.Type);
  }
  fn LessOrEquivalent(self, other: Optional(T)) -> bool {
    if (not self.HasValue()) {
      return true;
    }
    if (not other.HasValue()) {
      return false;
    }
    return T.Type.(OptionalStorageOrdered(T).PayloadLessOrEquivalent)(
        self as T.Type, other as T.Type);
  }
  fn Greater(self, other: Optional(T)) -> bool {
    if (not self.HasValue()) {
      return false;
    }
    if (not other.HasValue()) {
      return true;
    }
    return T.Type.(OptionalStorageOrdered(T).PayloadGreater)(self as T.Type,
                                                             other as T.Type);
  }
  fn GreaterOrEquivalent(self, other: Optional(T)) -> bool {
    if (not other.HasValue()) {
      return true;
    }
    if (not self.HasValue()) {
      return false;
    }
    return T.Type.(OptionalStorageOrdered(T).PayloadGreaterOrEquivalent)(
        self as T.Type, other as T.Type);
  }
}
```

<!-- google-doc-style-resume -->

The block is `$P/w352/w352_block.carbon` verbatim, the `OrderedWith` impl
included, but for the `OptionalStorageOrdered` interface's first line, which the
measured file keeps on one 81-column line and the block wraps after its `(`, a
whitespace-only change (prek's formatter does not touch `.carbon`, and `carbon
format` is not run) (amended 2026-11-02, review fold: B-M-4: rev 1 left the
`OrderedWith` impl in scratch). The `OrderedWith` impl keeps OP-1's tests and
order. The `Destroy` in the impls' bounds stays: it is part of the frozen header
(docs/design/optional.md:98-99), and the fallback impl's `T.Get` copies need it.
Commit F-C1, "OP-1 fix fill: autoupdate W-352's goldens on the container
arbiter", fills what the gate names on PR 56's branch; predicted there:
check/testdata/optional/compare.carbon (the SemIR of the comparison impls) and
check/testdata/optional/fail_compare.carbon (one note's prelude line, :215 to
the line of the `final impl ... EqWith` after C1),
lower/testdata/optional/compare.carbon and
lower/testdata/primitives/optional.carbon (the lowered impls and the prelude's
IR names), plus any golden that prints a line of optional.carbon after :205;
measured on the land tree: those and lower optional/destroy.carbon,
for/bindings.carbon and interop/cpp/pointer.carbon, CHECK lines only. A golden
outside OP-1's, OP-2's, SV-1's and those three lower files stops C1 (D-FO1-4's
break condition, which names the same set since rev 2).

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
(W-367)", changes toolchain/check/handle_pack_expansion.cpp and adds the three
splits of Appendix A.3 to check/testdata/variadics/fail_todo_slice.carbon, after
`fail_todo_interface_function` (two of them added 2026-11-02, review fold:
A-m-5). The code, measured on `sim59` and applying to
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
`// CHECK:STDERR:` line, as the file's other TODO splits read; the same four
lines for `fail_todo_choice_second_alternative` at its `B(...` list (the
nightly's column for h08 is 1:17) and for `fail_todo_choice_in_class` (h10's
2:16), predicted from review A's run of h08 and h10 with W-367 on PR 66's merge
(fbd411c6b: the TODO fires on both), not filled by this plan.

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

Item 15's steps, in item 15's order (rewritten 2026-11-02, review fold: A-B-1 /
A-m-2 / B-M-2 / B-m-2 / B-m-3: rev 1 put B1 after the land merge, which fired
D-LAND-12's break condition with no ruling; rev 2's B1 needs no trunk code). The
actor is SC-1's follow-on implementer, in a fresh worktree of
claude/carbon-fork-0-1-sc at cc4daba00 under /dev/shm, its build under
/dev/shm; each commit below is gated before it is made.

1.  `git fetch origin`; `git ls-remote origin` shows cc4daba00 for PR 60 and
    trunk at 03b40f7c5 or later. If trunk moved,
    `git merge-tree --write-tree --name-only` of trunk and cc4daba00 is re-run
    and compared with the row of section 0.3; a file or region not there with
    no rule here stops (D-FO1-11).
2.  **B1**, **F-B1**, **D-B** and **B-R** of section 2.2, in that order, on PR
    60's branch at cc4daba00, each gated on the branch's own build: B1's gate
    names fail_template_constraint_checked_binding.carbon and
    lower/template/template_constraint.carbon only, F-B1 fills them, D-B and
    B-R change no golden; then the two implementation reviews of D-FO1-9 on
    B1..B-R, which are also D-B's document review; the fixer; and `git push
    origin claude/carbon-fork-0-1-sc` (a fast-forward). This is the "W-139's
    fix commit is on PR 60's branch under SC-1's reviews" of item 15 and
    D-LAND-12; item 10 is decided (D-FO1-1), so the land merge may follow.
3.  **M60**, "SC-1: merge trunk at `<trunk>` (LAND-1 stage 13, D-LAND-12)": `git
    merge --no-ff --no-commit origin/trunk` on PR 60's branch, never a rebase.
    convert.cpp's two regions: SC-1's
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
    B1's deduce.cpp, structural_conformance.cpp and context.h auto-merge
    (measured: the merge of cc4daba00 plus B1 with trunk, scratch faee2a044,
    gives them byte-identical to the land tree's). The records files by
    D-LAND-5's OR, DL, GA and LG rules (trunk's blocks first, SC-1's appended),
    fork/conformance/README.md's table regenerated by the runner's README
    option. The unmerged list is empty:
    `git diff --name-only --diff-filter=U` prints nothing. Then prek runs on
    the resolved files and `git add` names each. M60's own build is expected
    to compile and its gate to be red on M18's set (section 0.3: the eight
    template-constraint goldens, fail_template_constraint_checked_binding.carbon
    and lower/template/template_constraint.carbon) and on
    fail_template_constraint_requirement_call.carbon, F-M60's refill; S restores
    all but F-M60's.
4.  **S**, "TP-1 (7): over SC-1, a template constraint's requirement defers to
    the type in constraint lookup": member_access.cpp only, this hunk
    (`$P/sim60/S.patch`, inlined; amended 2026-11-02, review fold: B-M-4), after
    the `ErrorInst` check in `LookupMemberInTemplateConstraint`:

    <!-- google-doc-style-ignore -->

    ```diff
    @@ static auto LookupMemberInTemplateConstraint(Context& context,
       if (member_id == SemIR::ErrorInst::InstId) {
         return member_id;
       }
    +  // Fork (TP-1 over SC-1): a member requirement of a `template constraint` is
    +  // satisfied by the type's own member of that name (structural conformance),
    +  // so it names the same entity as the lookup in the type, which decides.
    +  if (GetStructuralRequirementOfType(context,
    +                                     context.insts().Get(member_id).type_id())
    +          .has_value()) {
    +    return SemIR::InstId::None;
    +  }
       return PerformInstanceBinding(context, loc_id, base_id, member_id);
     }
    ```

    <!-- google-doc-style-resume -->

    It is TP-1's S re-derived: TP-1's text calls
    `GetStructuralRequirementRef(context, member_id)`, which SC-1's head no
    longer declares (fork/templates/plan.md:4637 against cc4daba00
    toolchain/check/structural_conformance.h:105,
    `GetStructuralRequirementOfType` over a type); the commit message says so.
5.  **M18**, TP-1's mutant, run once after S on S's build: revert
    member_access.cpp's S hunk, rebuild, gate and conformance
    (`$CB/conformance.sh`, XDG_CACHE_HOME under the actor's scratch; amended
    2026-11-02, review fold: B-m-2: rev 1 ran the gate only, while M18's
    expected red includes programs); expected, measured on the land tree with
    B1 and its fills (section 0.3): 1993 of 2003, the ten files there, and 193
    PASS, 3 COMPILE-FAIL, 14 SKIP over 210, 49 bullets; then S restored and
    rebuilt. The Landed text says "M18 killed" with the counts (D-LAND-20's
    rule).
6.  **F-M60**, "SC-1: autoupdate the goldens the land merge changes (stage 13)":
    `$CB/autoupdate.sh` on what the gate after S names: check
    named_constraint/fail_template_constraint_requirement_call.carbon and
    lower/template/template_constraint.carbon (measured: a note gains its
    location, IR names change; CHECK lines only), and B1's two test files if
    their fills on the branch, made without TP-1's code, differ from the merged
    toolchain's output (predicted CHECK lines only; any other line stops,
    D-LAND-8). Gate after: 2003 of 2003 (measured on the land tree).
7.  The checks of item 15 that are not commits, each recorded in B-R2's text:
    DR-1's test on SC-1's added call.cpp and convert.cpp lines and on B1's
    (`git diff <trunk>...HEAD -- toolchain/check/call.cpp
    toolchain/check/convert.cpp toolchain/check/deduce.cpp` piped to `grep -c`
    of `TemporaryStorage`, `return_arg_id` and `ConvertCallArgs` on `+` lines:
    measured 0, 0 and 0); CT-1's PR 60 composition re-measured on the merged
    build with the probes t08, t09, t13 and t14 (CT-1's `$X/rr1p`, their CT-1
    outputs 47, 48 and the incomplete-class diagnostic for `C(i32)` twice) and
    tc5 and tc6 (expected 8 and 7), under CT-1's break condition
    (fork/cpp-templates/plan.md section 0.9: tc5 or tc6 behaving otherwise, or
    an SC-1 golden other than F-M60's changing, stops); not measured by this
    plan (section 8).
8.  **L60**, DD-1's state L for SC-1, a land-time page commit, "SC-1: DD-1's
    state L (stage 13)": fork/designdocs/plan.md section 2.13's SC-1 texts:
    interoperability/README.md's C++ templates section gains "; the design of
    both directions is in" and the link `[Template
    constraints](../generics/template_constraints.md#mapping-to-and-from-c20-concepts)`;
    templates.md's state-L status sentences, the `Circle` paragraph's last
    sentence and the `template constraint` limit; quote fixture X12 deleted from
    fork/designdocs/samples/ and from the checker's table (section 2.4 there);
    both checker modes 0 errors (`python3 -I fork/designdocs/check_samples.py`,
    and with `--toolchain` on the branch's install). The texts are DD-1's
    verbatim, re-read against M60's tree; a text the merged page no longer fits
    stops (D-LAND-14's break condition).
9.  **B-R2**, "SC-1: W-139's register rows (stage 13)": Appendix D.6's H9.5,
    H9.7 and H9.8 texts and their rg1-checks.tsv rows, rg1-plan.md's check
    count, and step 7's measured values in SC-1's decision-log paragraph, now
    that M60 brought the register files.
10. The two implementation reviews of D-FO1-9 on M60..B-R2, which are also
    L60's document review; the fixer; and the push (a fast-forward).
11. The trunk landing, D-LAND-6's twelve steps for PR 60 at its pushed head:
    the merge is clean (the head contains trunk), expected `<g0>` = `<gn>` =
    2003 of 2003, conformance 196/0/14 over 210, 50 of 56 bullets (measured on
    the land tree); no refill commit; the records commit "Land PR 60: records"
    with Appendix A.3 to A.10's texts, Appendix E's fields and E.2's stage-13
    values; one fresh reviewer (D-FO1-9).

The commit order on the branch is therefore B1, F-B1, D-B, B-R, then M60, S,
F-M60, L60, B-R2. B1's code and fills were measured on M60's tree with S (the
land tree), not on PR 60's own branch; a difference on the branch is a stop of
D-FO1-2's break condition.

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
    F-C1 reviewed with C-M57 in view), which are also the document review of
    C-R's and L56's page edits; fixer; push.
7.  The trunk landing (D-LAND-6) at the pushed head: expected 2006 of 2006,
    201/0/17 over 218, 50 bullets, no refill; records commit with Appendix E's
    fields and E.2's stage-14 values; one fresh reviewer (D-FO1-9). RG-1's OP-1
    note is not owed (D-LAND-15 names OP-2's and VA-1's only).

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
    fork/conformance/programs/interop/cpp_sum_type_roundtrip_diff.carbon and of
    its oracle, the sibling cpp_sum_type_roundtrip_diff.diff.cpp (DIFF-1),
    SV-1's leg (section 1.7 there), hand-derived `-10 -20 81 -1 -2 81`, a
    land-time program commit "OP-2: SV-1's nested pointer leg (stage 15)" with
    Appendix B.5's texts verbatim, if the program on M57's tree lacks it
    (amended 2026-11-02, review fold: B-M-4: rev 1 named the nightly as the
    oracle, which has no `std::optional` mapping; the leg's Carbon and C++ texts
    were in no plan). The runner compiles the `.diff.cpp` with the toolchain's
    clang and compares the outputs; the leg's six lines are the last six of
    both.
6.  **L57**, "OP-2: land-time texts (stage 15)": OP-2's fold of W-197 into
    W-126 (W-197's title gains "(FOLDED into W-126)", W-126 gains W-197's OP-2
    note and the Optional row, row 43 and optional.md name W-126 again,
    fork/optional2/plan.md's ORCHESTRATION item); SV-1's Doc-M as this plan
    re-derives it (Appendix C.4: optional.md's C++ interoperability paragraph,
    sum_types.md's sentence that still says a `Core.Optional(T)` is matched as
    `StdOptional(T)`, and the F-015 paragraph of the decision log; SV-1's
    Appendix C.3 items 1 to 4, 6 and 7 are withdrawn, since they describe the
    view W-322 retired and optional.md at e23113ba2 already states the
    unmatchable class); C.5's W-177 evidence, Appendix C.5's text, its note
    withdrawn; C.8's F-015 references, the paragraph of Appendix C.4; the W-177
    cite in match_core_optional_diff.carbon's header, a check that W-177
    resolves on M57's tree (SV-1 section 1.12), no text; F-M's PR 57 part,
    which is steps 3 to 5 (SV-1's three goldens, the conditional refill and the
    leg); row 78's DR-0 sentence kept beside PR 57's DONE text as DR-1's C.3
    rewrites it (item 16, fork/direction/plan.md section 1.16; Appendix E.3's
    text; amended 2026-11-02, review fold: A-m-4: rev 1 wrote it at L56 only);
    and RG-1's OP-2 note (rg1-plan.md:2553-2560 by D-LAND-15's rule,
    "2026-10-27" read "2026-10-28") (amended 2026-11-02, review fold: B-M-4).
7.  Two implementation reviews (OP-2's rule, D-FO1-9) of M57 to L57, both
    also the document review of Doc-M's pages (R29(c)); fixer; push.
8.  The trunk landing at the pushed head: expected 2011 of 2011, 208/0/14
    over 222, 50 bullets, no refill; Appendix E's fields and E.2's stage-15
    values; one fresh reviewer (D-FO1-9).

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
7.  Two implementation reviews (VA-1's rule, D-FO1-9) of M59 to L59; fixer;
    push.
8.  The trunk landing at the pushed head: expected 2029 of 2029, 218/0/13 over
    231, 51 bullets, no refill; Appendix E's fields and E.2's stage-16 values;
    one fresh reviewer (D-FO1-9).

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
4.  Two implementation reviews by VA-2's rule, its section 3 item 12's "two,
    R29(c)", since item 15 states no count (D-FO1-9; amended 2026-11-02, review
    fold: B-m-3); fixer; push.
5.  The trunk landing: expected 2047 of 2047, 228/0/13 over 241, 51 bullets;
    Appendix E's fields and E.2's stage-17 values; one fresh reviewer.

W-367's split `fail_todo_choice_alternative` and W-368's `padded_element` and
program stay on PR 66's merged tree, and VA-2's hand-off notes 7 and 9 are
already discharged by D-R; VA-2's L names them as such.

## §3 The commits in order

Slices A, B, C and D run on four branches and may run at the same time (one
build per role under /dev/shm); Slice B runs on PR 60's branch before M60
(amended 2026-11-02, review fold: A-m-2 / B-M-2). The
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
| 13 | sc (60) | B1 | SC-1 fix: a checked generic's checked-symbolic argument for a template binding is checked per specific (W-139; leads issue 2153) | check/deduce.cpp; check/structural_conformance.cpp; check/context.h; two test files; one program; README table | autoupdate would change the two test files |
| 14 | sc (60) | F-B1 | SC-1 fix fill: autoupdate W-139's splits on the container arbiter | two test files | all pass (PR 60's branch) |
| 15 | sc (60) | D-B | SC-1: template_constraints.md states upstream's decision on issue 2153 (W-139) | docs/design/generics/template_constraints.md; fork/structural/plan.md | unchanged |
| 16 | sc (60) | B-R | SC-1: W-139 discharged, W-373 filed (D-FO1-2, D-FO1-3) | fork/inventory/work-items.json; fork/decision-log.md; fork/gap-analysis.md | unchanged |
| 17 | sc (60) | M60 | SC-1: merge trunk at `<trunk>` (LAND-1 stage 13, D-LAND-12) | merge | M18's ten and fail_template_constraint_requirement_call.carbon |
| 18 | sc (60) | S | TP-1 (7): over SC-1, a template constraint's requirement defers to the type in constraint lookup | check/member_access.cpp | F-M60's set |
| 19 | sc (60) | F-M60 | SC-1: autoupdate the goldens the land merge changes (stage 13) | the files the gate names | 2003 of 2003 |
| 20 | sc (60) | L60, B-R2 | SC-1: DD-1's state L (stage 13); SC-1: W-139's register rows (stage 13) | docs/design/templates.md; docs/design/interoperability/README.md; fork/designdocs/samples/ (X12); fork/designdocs/check_samples.py; fork/register/rg1-plan.md; fork/register/rg1-checks.tsv; fork/decision-log.md | unchanged; both checker modes 0 errors |
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
rules; no slice writes ORCHESTRATION.md (the orchestrator's stamps do,
D-LAND-16, with Appendix F's texts; amended 2026-11-02, review fold: B-M-2).

## §4 Testdata matrix

Predicted from the simulations and the prototypes; R16: no CHECK line is
written by hand, and each fill is autoupdate's, reviewed as a diff.

| File | Commit | Change | Fill | Evidence |
| --- | --- | --- | --- | --- |
| check/testdata/optional/destroy.carbon | A1 | split `incomplete_self_signature` (Appendix A.1), no CHECK line | F-A1: predicted none (no diagnostic, no dump range) | i10a checks with the fix, section 0.2 |
| check/testdata/named_constraint/template_constraint.carbon (`self_facet_in_signature_required` and its `fail_todo_` twin) | none | none | none | fails at PR 57's landing without A1, passes with it (`sim57x60`) |
| check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon | B1 | `fail_symbolic_arg` and `fail_require_in_interface_symbolic` renamed without `fail_` and instantiated, comments rewritten; nine splits added (Appendix A.2; amended 2026-11-02, review fold: A-B-1 / A-B-3 / B-m-6) | F-B1: the renamed splits lose their STDERR lines; the new ones gain section 2.2's | measured by autoupdate on the land tree, `$Q/gate_b1_filled.txt` |
| lower/testdata/template/template_constraint.carbon | B1 | split `checked_caller` (Appendix A.2) | F-B1: its LLVM IR | measured: `Caller` and `CallGet` specifics for `C` |
| check/testdata/named_constraint/fail_template_constraint_requirement_call.carbon; lower/testdata/template/template_constraint.carbon | M60 | none | F-M60: a note's location; IR names | `$P/sim60/gateS.log` |
| check/testdata/optional/compare.carbon; check/testdata/optional/fail_compare.carbon; lower/testdata/optional/compare.carbon; lower/testdata/optional/destroy.carbon; lower/testdata/primitives/optional.carbon; lower/testdata/for/bindings.carbon; lower/testdata/interop/cpp/pointer.carbon | C1 | none | F-C1 (OP-1's files on PR 56) and F-C-M57 (the rest on PR 57); CHECK lines only | `$P/w352/gate_w352.log` |
| check/testdata/variadics/fail_todo_slice.carbon | D1 | splits `fail_todo_choice_alternative`, `fail_todo_choice_second_alternative` and `fail_todo_choice_in_class` (Appendix A.3) | F-D1: section 2.4's four lines each | h01 with W-367; h08 and h10 by review A |
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
| 13 | 60 | interop/cpp_structural_conformance.carbon (and generics/structural_conformance.carbon changed, SKIP on trunk, now run) | generics/structural_conformance_checked_caller.carbon | minus 1 | 196/0/14 over 210 (PASS +3) | 50 | measured on the land tree (`sim60` with S, rev 2's B1 and the fills): 196/0/14 over 210, 50 bullets (amended 2026-11-02, review fold: B-B-1) |
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
| B | deduce.cpp +109/-8, structural_conformance.cpp +7, context.h +12, template_constraints.md one paragraph and one note (amended 2026-11-02, review fold: A-B-1 / B-B-1) | UA-3's merge of upstream's deduce.cpp: 503f09037 ("Add support for default values for non-generic parameters of generic functions. (#8011)") rewrites `DeduceGenericCallArguments`'s argument list beside B1's one added line there, and 2c9739799 ("Render diagnostics through the terminal library (#7683)") touches the class's diagnostic helpers; neither touches the two conversions B1 routes (`git log c1e83b0b7..68569d234 -- toolchain/check/deduce.cpp`); W-372 none; CT-1's call.cpp untouched | UA-3 merges `ConvertBindingArg` and the deferral line as fork code beside upstream's changes; B1's comments name W-139 so the merge keeps them |
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

**Rejected: rev 1's B1, CT-1's C++ call deferral widened to Carbon callees**
(added 2026-11-02, review fold: A-B-1 / A-B-2 / B-B-1). It sent the whole call
through `DeferCppCallOnSymbolicArgs`'s `CallAction` splice with no result type,
so the call's type was a `TypeOfInst` and the rest of the checked generic went
unchecked at its definition: reviews A and B measured x1, x14 and x10
checking with no diagnostic (an error only at instantiation, and never if the
generic is not instantiated), and review B measured the C++ analog (ct) the
same on trunk; it left a generic class's `template` parameter rejected (x5,
gc); and its `TemplateInst` deferral is upstream's spelling for a C++ template
name only (section 0.6), so using it for a Carbon callee was a second spelling
under R32 (d), which rev 1 recorded as ALIGNED. Rev 2's B1 keeps upstream's
ordinary call and defers only SC-1's own check (D-FO1-2). _Falsifier:_ a review
showing a form where rev 2's call escapes its definition's check (section 7's
next risk).

**Rejected: W-139 at every conversion** (the planner's first prototype in
`convert.cpp`: a `ConvertAction` splice in `PerformBuiltinConversion` for every
checked-symbolic conversion to a facet type with structural requirements).
Measured: deduction reports "inconsistent deductions for value of generic
parameter `T`" (section 0.4). Root cause, as far as rev 2's prototype
separates it: that splice was made at every such conversion, inside deduction
and out, each a new template-dependent constant, so two conversions feeding
one binding gave two values; rev 2 makes the splice only for a call's
deduction, once per binding and argument (`deferred_conversions_`; dup with
two parameters prints 7), and leaves every other conversion to D-SC-6 (conv).

**Risk: B1's reach is too narrow or too wide** (rewritten 2026-11-02, review
fold: A-B-1 / B-B-1). Too narrow: a `template` binding whose argument a call
deduces some other way. Measured on the land tree: functions (p1), methods
(x12), two parameters of one binding (dup), a dependent return type (x13), a
chain of checked generics (chain), generic classes (gc, x5, gcd) and generic
interfaces (iface); an overload set's members go through OV-4's probe and
commit deductions (section 2.2), not measured with a template-constrained
member; the reviews are asked to construct it (D-FO1-2's break condition
widens, never guards). Too wide: a concrete argument for the binding is
checked at the definition (x10), a template-dependent one is D-SC-19's, a
conversion outside a call keeps D-SC-6 (conv), and the call's result is
checked at the definition (x1, x14).

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
6.  Rev 2's fixer (added 2026-11-02, review fold: A-B-1 / B-B-1 / B-m-2): one
    build under /dev/shm/fo1-fixer/builds of `sim60` with S (02fc31f10), then
    rev 2's B1 as three increments (bd47fd623), section 0.2's probes on it and
    on trunk's, PR 60's and the nightly's toolchains, Appendix A.2's sources
    autoupdated to a fixpoint, the gate (2000 of 2003 before the fills, 2003 of
    2003 after) and conformance (196/0/14 over 210), M18 with conformance (1993
    of 2003, 193/3/14 over 210), B1 checked to apply at cc4daba00 and merged
    with trunk (scratch faee2a044), and the upstream greps of section 0.6; the
    build was deleted with rev 2's commit.

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
    e23113ba2, D1 and D2 on b0822a744, B1 on cc4daba00); B1 was built and gated
    on M60's tree only, not on PR 60's own branch before the merge (amended
    2026-11-02, review fold: A-m-2).
5.  The register scripts (`check_quotes.sh`, `check_greps.sh`) and DD-1's and
    EV-1's checkers on the land trees: records-time checks, run by each
    landing.
6.  Hosted CI and any Bazel build: Actions is disabled and Bazel is not
    installed (R28); the container arbiter is the record (R33 (b)).
7.  A nightly newer than 2026.10.12: not fetched; the oracle is the installed
    one (R30).
8.  `sim59`'s conformance overlapped the W-367 rebuild's install (202/0/14 over
    216 recorded from that run); the trunk landing re-runs it.
9.  The two W-367 pins of Appendix A.3 (h08 and h10) were measured by review A
    on PR 66's merge, not filled by this plan; the nested-pointer leg of
    Appendix B.5 needs SV-1 and PR 57 together (its probe printed the expected
    lines on SV-1's PR 57 composition, round 1's w1), not run on a tree of this
    plan (added 2026-11-02, review fold: A-m-5 / B-M-4).

## Hand-off notes

1.  Work in fresh worktrees of the pushed heads under /dev/shm; the held
    worktrees under /home/user are read-only and behind (section 0.1).
2.  The prototypes are in `$P` (`i10/F1.patch`, `sim60/S.patch`,
    `w352/w352_block.carbon` with `w352.py`, `w367/W367.patch`,
    `w368/W368.patch`) and `$Q` (`w139/B1v5_toolchain.patch`, rev 2's B1, and
    `a2/`, Appendix A.2's sources); apply each with `git apply` and re-read it
    against section 2, which governs where they differ (B1's comments and
    wrapping). `$P/w139/W139v2.patch` is rev 1's withdrawn B1.
3.  B1 on PR 60's branch before M60, as item 15 orders it (D-FO1-2; amended
    2026-11-02, review fold: A-m-2 / B-M-2).
4.  A fill that writes a line outside CHECK lines, or a golden section 4 does
    not name, stops the commit (D-LAND-8).
5.  The `fail_`-prefix problems that B1's code alone would cause are resolved
    by B1's own renames in the same commit; the gate after B1 must show none.
6.  Each records text is Appendix C's, D's, E's or F's, verbatim but for
    placeholders; a text not given is a stop (D-LAND-9).
7.  Dates are the UTC commit date (`date -u +%F`).
8.  No model identifier in any repository file; the trailers carry the
    session's attribution.
9.  Retargets of PR 57 and PR 66 are the orchestrator's; confirm the base with
    `pull_request_read` before the stage.
10. If trunk moved, re-run section 0.3's merge-tree for the branch and
    compare; a new conflict with a rule here is recorded as "not in the dry
    run".
11. The orchestrator's stamps are Appendix F's, verbatim; F.1 precedes the
    first slice commit (W-373's reservation), and each Next actions mark is
    written by the stage F names (added 2026-11-02, review fold: B-M-2 /
    B-m-4).

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

Rewritten 2026-11-02 (review fold: A-B-1 / A-B-3 / B-B-1 / B-M-1 / B-m-6); the
sources are `$Q/a2/`, the ones measured on the land tree. In
check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon:
the file comment's "a checked-generic self never satisfies one (D-SC-6, the
conservative answer to leads issue 2153)." becomes "a checked-generic argument
that a call passes to a `template` binding is checked in each specific of its
caller (W-139, as upstream decided leads issue 2153); elsewhere a
checked-generic self never satisfies one (D-SC-6)."; the split
`fail_symbolic_arg.carbon` is replaced by the ten splits of the first block
below, in its place; and the split `fail_require_in_interface_symbolic.carbon`
is replaced by the split of the second block, in its place. The other splits
are unchanged.

<!-- google-doc-style-ignore -->

```carbon
// --- symbolic_arg.carbon
library "[[@TEST_NAME]]";

// W-139 (leads issue 2153): a checked-generic argument passed to a `template`
// binding constrained by a template constraint is checked in each specific of
// `Caller`, here `Caller(C)`, so the definition checks.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  return CallGet(x);
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(c: C) -> i32 { return Caller(c); }

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
  fn Get(unused self) -> bool { return true; }
}

fn Use(e: E) -> i32 { return Caller(e); }

// --- fail_symbolic_arg_result_misused.carbon
library "[[@TEST_NAME]]";

// W-139: the call has `CallGet`'s declared return type, `i32`, in the checked
// generic, so a misuse of the result is diagnosed at `Caller`'s definition,
// as it is when the constraint is an interface.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  let unused b: bool = CallGet(x);
  return 0;
}

// --- fail_symbolic_arg_result_member.carbon
library "[[@TEST_NAME]]";

// W-139: a member access on the call's `i32` result is checked at `Caller`'s
// definition.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn Caller[U: type](x: U) -> i32 {
  return CallGet(x).foo;
}

// --- fail_concrete_arg_beside_symbolic.carbon
library "[[@TEST_NAME]]";

// W-139: only a checked-symbolic argument for the `template` binding is checked
// per specific; the concrete `D` bound to `T` is checked at `H`'s definition.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn G[template T: HasGet, V: type](x: T, unused y: V) -> i32 { return x.Get(); }

class D {
  var v: i32;
}

fn H[U: type](d: D, u: U) -> i32 { return G(d, u); }

// --- fail_symbolic_conversion.carbon
library "[[@TEST_NAME]]";

// D-SC-6 stays outside a call's template binding: a conversion of a
// checked-symbolic type to a template constraint is rejected.
template constraint HasGet {
  fn Get(self) -> i32;
}

fn Caller[U: type](unused x: U) {
  let unused T: HasGet = U;
}

// --- symbolic_class_arg.carbon
library "[[@TEST_NAME]]";

// W-139: a checked-generic argument for a generic class's `template` parameter
// is checked in each specific of `Make`, here `Make(C)`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Make[U: type](unused x: U) -> i32 {
  var h: Holder(U) = {.n = 3};
  return h.n;
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

fn Use(c: C) -> i32 { return Make(c); }

// --- fail_symbolic_class_arg_unsatisfied.carbon
library "[[@TEST_NAME]]";

// W-139: `Holder(U)` is checked in `Make(D)`, where `D` has no member `Get`.
template constraint HasGet {
  fn Get(self) -> i32;
}

class Holder(template T: HasGet) {
  var n: i32;
}

fn Make[U: type](unused x: U) -> i32 {
  var h: Holder(U) = {.n = 3};
  return h.n;
}

class D {
  var v: i32;
}

fn Use(d: D) -> i32 { return Make(d); }

// --- symbolic_interface_arg.carbon
library "[[@TEST_NAME]]";

// W-139: a checked-generic argument for a generic interface's `template`
// parameter, `J(U)`, is checked in each specific of `Use`.
template constraint HasGet {
  fn Get(self) -> i32;
}

interface J(template T: HasGet) {
  fn F() -> i32;
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
}

impl i32 as J(C) {
  fn F() -> i32 { return 5; }
}

fn Use[U: type](unused x: U) -> i32 {
  return i32.(J(U).F)();
}

fn UseC(c: C) -> i32 { return Use(c); }
```

```carbon
// --- require_in_interface_symbolic.carbon
library "[[@TEST_NAME]]";

// W-139: `G`'s `T: I` is checked-symbolic, and the call that passes `x` to a
// `template` binding is checked in each specific of `G`, here `G(C)`, so the
// definition checks. A structural requirement is still not forwarded through
// an interface's `require` to a member lookup in the checked binding itself,
// `x.Get()` in `G` (W-140; mirrors upstream's interface/require.carbon
// `fail_todo_implicit_self_impls`).
template constraint HasGet {
  fn Get(self) -> i32;
}

interface I {
  require impls HasGet;
}

fn CallGet[template T: HasGet](x: T) -> i32 { return x.Get(); }

fn G[T: I](x: T) -> i32 {
  return CallGet(x);
}

class C {
  var v: i32;
  fn Get(self) -> i32 { return self.v; }
  impl as I {}
}

fn Use(c: C) -> i32 { return G(c); }
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

### A.3 variadics/fail_todo_slice.carbon: W-367's three splits (D1)

After the split `fail_todo_interface_function.carbon`.

<!-- google-doc-style-ignore -->

```carbon
// --- fail_todo_choice_alternative.carbon
library "[[@TEST_NAME]]";

// W-367: a pack expansion pattern in a choice alternative's parameter list.
choice C { A(... each x: i32) }

// --- fail_todo_choice_second_alternative.carbon
library "[[@TEST_NAME]]";

// W-367: the second alternative's list is checked in the same alternative
// scope as the first's.
choice C { A, B(... each x: i32) }

// --- fail_todo_choice_in_class.carbon
library "[[@TEST_NAME]]";

// W-367: a choice declared in a class; the alternative's scope, not the
// class's, is the innermost.
class Outer {
  choice C { A(... each x: i32) }
}
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

The program, verbatim: the header below, then `$P/w352/count.carbon`'s text
(amended 2026-11-02, review fold: B-M-4: rev 1 left the body in scratch):

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

import Core library "io";

class Counted {
  var v: i32;
  var copies: i32*;
  var destroys: i32*;
  impl as Core.Copy {
    fn Op(self) -> Self {
      ++*self.copies;
      return {.v = self.v, .copies = self.copies, .destroys = self.destroys};
    }
  }
  impl as Core.Destroy {
    fn Op(ref self) {
      ++*self.destroys;
    }
  }
}

impl Counted as Core.EqWith(Counted) {
  fn Equal(self, other: Counted) -> bool { return self.v == other.v; }
  fn NotEqual(self, other: Counted) -> bool { return self.v != other.v; }
}

impl Counted as Core.OrderedWith(Counted) {
  fn Less(self, other: Counted) -> bool { return self.v < other.v; }
  fn LessOrEquivalent(self, other: Counted) -> bool {
    return self.v <= other.v;
  }
  fn Greater(self, other: Counted) -> bool { return self.v > other.v; }
  fn GreaterOrEquivalent(self, other: Counted) -> bool {
    return self.v >= other.v;
  }
}

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  var copies: i32 = 0;
  var destroys: i32 = 0;
  var t1: Counted = {.v = 1, .copies = &copies, .destroys = &destroys};
  var t2: Counted = {.v = 2, .copies = &copies, .destroys = &destroys};
  var a: Core.Optional(Counted) = Core.Optional(Counted).Some(t1);
  var b: Core.Optional(Counted) = Core.Optional(Counted).Some(t2);
  var n: Core.Optional(Counted) = Core.Optional(Counted).None();
  let c0: i32 = copies;
  let d0: i32 = destroys;
  Core.Print(B(a == b));
  Core.Print(B(a != b));
  Core.Print(B(a < b));
  Core.Print(B(a <= b));
  Core.Print(B(a > b));
  Core.Print(B(a >= b));
  Core.Print(B(n == a));
  Core.Print(B(n < a));
  Core.Print(B(a == a));
  Core.Print(copies - c0);
  Core.Print(destroys - d0);
  return 0;
}
```

<!-- google-doc-style-resume -->

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

### B.5 interop/cpp_sum_type_roundtrip_diff: the nested-pointer leg

Added 2026-11-02 (review fold: B-M-4). SV-1's leg (fork/sumtype-interop/plan.md
section 1.7), written from its round-1 probe w1, which printed these six lines
on SV-1's PR 57 composition. In
fork/conformance/programs/interop/cpp_sum_type_roundtrip_diff.carbon, the
inline C++ block gains, after `TakeIntOrPointer`:

<!-- google-doc-style-ignore -->

```c++
inline int nested_cell = 81;

inline auto MakeNested(int k) -> std::optional<int*> {
  if (k == 0) {
    return std::nullopt;
  }
  if (k == 1) {
    return static_cast<int*>(nullptr);
  }
  return &nested_cell;
}

inline auto TakeNested(std::optional<int*> o) -> int {
  return o.has_value() ? (*o != nullptr ? **o : -2) : -1;
}
```

<!-- google-doc-style-resume -->

the program gains, before `fn Run`:

<!-- google-doc-style-ignore -->

```carbon
fn ShowNested(o: Core.Optional(Core.Optional(i32*))) -> i32 {
  if (not o.HasValue()) {
    return -10;
  }
  let p: Core.Optional(i32*) = o.Get();
  if (not p.HasValue()) {
    return -20;
  }
  return *p.Get();
}
```

<!-- google-doc-style-resume -->

and `Run` gains, before its `return 0;`:

<!-- google-doc-style-ignore -->

```carbon
  // A C++ `std::optional<int*>` converts in one step to
  // `Core.Optional(Core.Optional(i32*))` and back (needs PR 57's
  // `Core.Optional(T)` of an Optional payload): empty, engaged with a null
  // pointer, and engaged with the address of a C++ global holding 81.
  let empty: Core.Optional(Core.Optional(i32*)) = Cpp.MakeNested(Seed(-5));
  let engaged_null: Core.Optional(Core.Optional(i32*)) =
      Cpp.MakeNested(Seed(-4));
  let engaged_cell: Core.Optional(Core.Optional(i32*)) =
      Cpp.MakeNested(Seed(-3));
  Core.Print(ShowNested(empty));
  Core.Print(ShowNested(engaged_null));
  Core.Print(ShowNested(engaged_cell));
  Core.Print(Cpp.TakeNested(empty));
  Core.Print(Cpp.TakeNested(engaged_null));
  Core.Print(Cpp.TakeNested(engaged_cell));
```

<!-- google-doc-style-resume -->

The oracle, cpp_sum_type_roundtrip_diff.diff.cpp, gains after
`TakeIntOrPointer`:

<!-- google-doc-style-ignore -->

```c++
static int nested_cell = 81;

static auto MakeNested(int k) -> std::optional<int*> {
  if (k == 0) {
    return std::nullopt;
  }
  if (k == 1) {
    return static_cast<int*>(nullptr);
  }
  return &nested_cell;
}

static auto TakeNested(std::optional<int*> o) -> int {
  return o.has_value() ? (*o != nullptr ? **o : -2) : -1;
}

// `Core.Optional(Core.Optional(i32*))` is `std::optional<int*>`: the outer
// empty state is `std::nullopt`, the inner one the null pointer.
static auto ShowNested(std::optional<int*> o) -> int {
  if (!o.has_value()) {
    return -10;
  }
  if (*o == nullptr) {
    return -20;
  }
  return **o;
}
```

<!-- google-doc-style-resume -->

and `main` gains, before its `return 0;`:

<!-- google-doc-style-ignore -->

```c++
  std::optional<int*> empty = MakeNested(Seed(-5));
  std::optional<int*> engaged_null = MakeNested(Seed(-4));
  std::optional<int*> engaged_cell = MakeNested(Seed(-3));
  Print(ShowNested(empty));
  Print(ShowNested(engaged_null));
  Print(ShowNested(engaged_cell));
  Print(TakeNested(empty));
  Print(TakeNested(engaged_null));
  Print(TakeNested(engaged_cell));
```

<!-- google-doc-style-resume -->

Hand-derived output of the six lines, from the two functions' text: `Seed(-5)`,
`Seed(-4)` and `Seed(-3)` are 0, 1 and 2, so `MakeNested` returns empty, a null
pointer and `&nested_cell`; `ShowNested` gives -10 (no outer value), -20 (an
outer value whose inner Optional is empty, the null niche) and 81; `TakeNested`
gives -1, -2 and 81. So `-10 -20 81 -1 -2 81`, one per line, item 16's expected
value. The program has no EXPECT-STDOUT lines (DIFF-1 compares it with the
oracle), and its header gains no sentence. A mismatch stops stage 15
(D-FO1-11).

## Appendix C: the docs amendments

### C.1 docs/design/generics/template_constraints.md (D-B)

Rewritten 2026-11-02 (review fold: A-B-2 / A-B-3 / B-B-1 / B-M-1). The
paragraph that begins "Using a template constraint on a checked-generic binding
is an error in 0.1" (:456-468 at cc4daba00) becomes:

<!-- google-doc-style-ignore -->

```markdown
Using a template constraint on a checked-generic binding is an error in 0.1
(landed: `TemplateConstraintOnNonTemplateBinding` at the binding, SC-1
D-SC-8). Passing a checked-generic argument to a template-constrained binding
is supported, as upstream decided in
[leads issue 2153](https://github.com/carbon-language/carbon-lang/issues/2153):
"We have decided to support passing a symbolic constant to a template
parameter" ([overview](overview.md)), and such a call "relies on
monomorphization" ([witness appendix](appendix-witness.md)). The call is an
ordinary call in the checked generic, with the callee's declared return type,
so the rest of the checked generic is checked at its definition as for any
call; only the argument's structural requirements, which need a concrete type,
are checked later, in each specific of the checked generic, where the argument
is concrete, and an argument type that does not conform is diagnosed when that
specific is formed, with the requirement it misses. This holds for a
function's, a generic class's and a generic interface's `template` parameter
alike. Elsewhere a checked-generic self still never satisfies a structural
requirement (`StructuralRequirementNeedsConcreteType`, D-SC-6): in a conversion
outside a call, and in the `require` of an impl in a generic class (fork work
item W-373), where no template parameter receives the symbolic type. Member
lookup through a checked binding never finds structural members
([#2200](/proposals/p002200-template-generics.md#template-constraints)), which
is why a template constraint constrains only a `template` binding.
```

<!-- google-doc-style-resume -->

After RG-1's note (2026-10-28), which stays, this note follows:

<!-- google-doc-style-ignore -->

```markdown
> **SC-1 note (<date>).** W-139 realigned: the definition-time rejection the
> note above describes is replaced by the check in each specific that the
> paragraph above it states. The call itself is upstream's ordinary call with
> a symbolic argument; the deferred structural check is the fork's own
> mechanism for its structural requirements, which upstream does not have.
> The `require` of an impl in a generic class keeps D-SC-6's rejection; leads
> issue 2153 does not decide it (W-373).
```

<!-- google-doc-style-resume -->

### C.2 fork/structural/plan.md: D-SC-6's amendment (D-B)

Appended as the last paragraph of the D-SC-6 bullet (:388 at cc4daba00), at
the bullet's indentation (rewritten 2026-11-02, review fold: A-B-2 / B-B-1):

<!-- google-doc-style-ignore -->

```markdown
(Amended <date>, FO-1, W-139: a checked-symbolic argument that a call passes
to a `template` binding is no longer rejected at the caller's definition. The
call stays an ordinary call; the argument's structural requirements are
checked in each specific of the caller, where it is concrete (deduce.cpp,
`ConvertBindingArg`, fork/followon/fo1-plan.md D-FO1-2), as upstream decided
leads issue 2153. The rejection stays for a conversion outside a call, for
impl deduction and for an impl's `require` in a generic class, W-373.)
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
The API table rows (:95-96) do not change. In "The API", the storage sketch
(:136-154 at 9f12209d8, the block that begins `private interface
OptionalStorage {`) gains, after `final impl forall [T: type] T* as
OptionalStorage where .Type = MaybeUnformed(T*);`, a blank line and these
declarations, with function bodies elided as the sketch's are (added
2026-11-02, review fold: B-m-5):

<!-- google-doc-style-ignore -->

```carbon
private interface OptionalStorageEq(T: Destroy & OptionalStorage & Eq);
private interface OptionalStorageOrdered(
    T: Destroy & OptionalStorage & Ordered);

impl forall [T: Destroy & OptionalStorage & Eq]
    T.(OptionalStorage.Type) as OptionalStorageEq(T);
impl forall [T: Copy & Destroy & Eq]
    DefaultOptionalStorage(T) as OptionalStorageEq(T);
impl forall [T: Destroy & OptionalStorage & Ordered]
    T.(OptionalStorage.Type) as OptionalStorageOrdered(T);
impl forall [T: Copy & Destroy & Ordered]
    DefaultOptionalStorage(T) as OptionalStorageOrdered(T);
```

<!-- google-doc-style-resume -->

R31 for C-R's optional.md edit: headings unchanged, bullets unchanged; the
code block count gains none (the sketch is an existing block).

### C.4 SV-1's Doc-M, re-derived (L57)

Added 2026-11-02 (review fold: B-M-4). SV-1's Appendix C.3 (seven anchored
edits of optional.md) and C.8's F-015 paragraph describe D-SV-7's view, which
DR-1 retired as a second spelling of the `Match` route (W-322, D-DR-15) before
PR 62 landed; optional.md at e23113ba2 already states the unmatchable class
(DR-1's C.7 text, its "Pattern matching" section and its W-177 bullet). So
SV-1's items 1 to 4, 6 and 7 are withdrawn, and Doc-M is these three texts, on
M57's tree (the old texts occur once; a text not found verbatim stops L57, its
edit going to the document review of D-FO1-9):

1.  docs/design/optional.md, "C++ interoperability" (:486-489 at e23113ba2).
    OLD: the paragraph that begins ``A mapping of C++'s `std::optional<T>` in
    either direction is not designed here:``. NEW:

    <!-- google-doc-style-ignore -->

    ```markdown
    A C++ `std::optional<T>` keeps its C++ class and has a Carbon sum type,
    `Core.CppCompat.StdOptional(T)`
    ([Sum types](sum_types.md#c-stdoptional-and-stdvariant), fork decision
    F-020). For a `T` that is a concrete scalar or pointer payload type, it
    converts to and from `Core.Optional(T)` in one implicit step, through that
    sum type and the prelude's `ImplicitAs` impls, and a `Core.Optional(T)`
    argument is offered to C++ overload resolution as `std::optional<T>`;
    `Core.Optional(T*)` keeps the nullable-pointer mapping above. A
    `Core.Optional(T)` is not matched through that sum type: it is not
    matchable in 0.1 ([Pattern matching](#pattern-matching)). No exported
    signature names `Core.Optional(T)` for a non-pointer `T` (W-049) (amended
    <date>, SV-1, re-derived after DR-1's W-322).
    ```

    <!-- google-doc-style-resume -->
2.  docs/design/sum_types.md (:279-281 at trunk 03b40f7c5), SV-1's own landed
    sentence, which still says that "a `Core.Optional(T)` is matched as
    `StdOptional(T)` when `T` is a scalar or pointer type", the view W-322
    retired (found while re-deriving Doc-M; same document review). OLD: ``A C++
    `std::optional<T>` also converts in one implicit step to and from
    `Core.Optional(T)` when `T` is not a pointer type, and a `Core.Optional(T)`
    is matched as `StdOptional(T)` when `T` is a scalar or pointer type:``. NEW:
    ``A C++ `std::optional<T>` also converts in one implicit step to and from
    `Core.Optional(T)` when `T` is not a pointer type; a `Core.Optional(T)` is
    not itself matched through `StdOptional(T)`, since that view was retired as
    a second spelling of the `Match` route (amended <date>):``, rewrapped to 80
    columns.
3.  fork/decision-log.md, appended after the merged trunk's `### OP-1 / F-015:
    Core.Optional comparison and design (2026-10-13)` entry's last paragraph
    (after D.4's and A.6's paragraphs there):

    <!-- google-doc-style-ignore -->

    ```markdown
    > **F-015 amendment (<date>, SV-1, F-020; re-derived by FO-1 after DR-1's
    > W-322).** The `std::optional` mapping this design deferred to W-011
    > relates to `Core.Optional(T)`: a C++ `std::optional<T>` converts to and
    > from `Core.Optional(T)` in one implicit step for a non-pointer `T` that
    > is a concrete scalar or pointer payload type (through
    > `Core.CppCompat.StdOptional(T)` and two prelude `ImplicitAs` impls that
    > use only the public API), and a `Core.Optional(T)` argument is offered to
    > C++ overload resolution as `std::optional<T>`. A `Core.Optional(T)` is
    > not matched through that choice (D-SV-7's view, retired by DR-1,
    > W-322). The class, its API, its storage, the `Try` impl and
    > `Core.Optional(T*)`'s pointer mapping are unchanged;
    > docs/design/optional.md's "C++ interoperability" paragraph says so.
    > W-177 stays open. Veto-able with F-020.
    ```

    <!-- google-doc-style-resume -->

R31 for Doc-M: optional.md's and sum_types.md's heading and bullet counts do
not change; the decision log gains no heading and no bullet.

### C.5 W-177's evidence (L57)

Added 2026-11-02 (review fold: B-M-4). SV-1's C.5 note is withdrawn (its own
DR-1 amendment); W-177's `evidence` in fork/inventory/work-items.json gains,
last, the string:

<!-- google-doc-style-ignore -->

```text
toolchain/check/testdata/match/fail_todo_core_optional.carbon (DR-1 D-DR-15, W-322: a `Core.Optional` scrutinee of `match` and of `if let` gets the scrutinee TODOs until W-320)
```

<!-- google-doc-style-resume -->

and its `notes` keep W-323's correction (fork/direction/plan.md C.7) unchanged.

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

### D.3 W-139, W-140 and W-373 (B-R)

Rewritten 2026-11-02 (review fold: A-B-2 / A-m-1 / B-B-1 / B-m-7). W-139 in
fork/inventory/work-items.json: `kind` becomes `implemented`; the title gains,
after "SC-1 residue", " (DISCHARGED at SC-1's W-139 fix, <date>)"; `evidence`
gains first "Landed at SC-1 (<sha-B1>): toolchain/check/deduce.cpp
`ConvertBindingArg` (a call's checked-symbolic argument for a `template`
binding with structural requirements is converted with them deferred and
again in each specific, an eval-block `ConvertToValueAction`) and
structural_conformance.cpp's D-SC-6 branch (the deferral counter); the splits
`symbolic_arg`, `fail_symbolic_arg_unsatisfied`, `fail_symbolic_arg_mismatch`,
`fail_symbolic_arg_result_misused`, `fail_symbolic_arg_result_member`,
`fail_concrete_arg_beside_symbolic`, `fail_symbolic_conversion`,
`symbolic_class_arg`, `fail_symbolic_class_arg_unsatisfied`,
`symbolic_interface_arg` and `require_in_interface_symbolic`, and
lower/testdata/template/template_constraint.carbon's `checked_caller`
(<sha-F-B1>)"; `notes` gains "Discharged <date> (FO-1, D-FO1-2): the call is
upstream's ordinary call with a symbolic argument (upstream's `TemplateInst`
wrapping at check/call.cpp:386-395 at <tip> is a C++ template name's, not this
path's); only SC-1's structural check is deferred to each specific, for
functions', generic classes' and generic interfaces' `template` parameters;
docs rewritten (<sha-D-B>); the generic class's `require` path is W-373
(D-RG-4: the register entry H9.5 ALIGNED with W-373 named).".

W-140 in fork/inventory/work-items.json: the title's example ("`interface I {
require impls HasGet; } fn G[T: I](x: T) { CallGet(x); }` is rejected") is
replaced by "a checked binding `T: I`, `I` requiring `HasGet`, does not find
`HasGet`'s requirements by member lookup (`x.Get()` in `G[T: I]`)"; `evidence`'s
second string, which cites `fail_require_in_interface_symbolic`, becomes
"toolchain/check/testdata/named_constraint/fail_template_constraint_checked_binding.carbon
`require_in_interface_symbolic` (since W-139's fix the call `CallGet(x)` checks,
per specific)"; and `notes` gains "Narrowed <date> (FO-1, W-139's fix <sha-B1>):
the title's former example, a call that passes the checked binding to a
`template` binding, checks since W-139 (the call is checked per specific); what
stays is member lookup through the checked binding itself, which mirrors
upstream's interface/require.carbon `fail_todo_implicit_self_impls` and is
picked up with it." (A-m-1: rev 1 left W-140 citing a split that now passes.)

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
  "notes": "Reserved by FO-1's sign-off stamp (fork/followon/fo1-plan.md Appendix F.1). Register: NONE (RG-1 vocabulary; D-RG-1, row H9.7 with its silence check), watched by W-355; it is the gap that D-RG-4 names beside H9.5's ALIGNED. Break condition: upstream states how a checked-symbolic self satisfies a requirement that needs a concrete type, or lands interface/require.carbon's `fail_todo_implicit_self_impls` (H9.7's check moves); D-RG-4's break condition then re-classifies H9.5 DRIFT and this item is re-titled and scheduled as the drift."
}
```

<!-- google-doc-style-resume -->

The `evidence` cites are pinned by B-R at PR 60's branch, with line numbers, and
re-pinned by B-R2 to M60's tree if the merge moves them. `<m18>` is section 2.5
step 5's counts, written by B-R2 into this paragraph (B-R writes the paragraph
without the clause from "Land merge", which B-R2 appends). The gap row
"Generics: Template-style structural conformance to nominal constraints" gains,
before its closing `|`, " W-139 discharged <date> (FO-1: checked generics call
template-constrained functions per specific); W-373 filed." SC-1's decision-log
entry `### SC-1: template structural conformance (F-010) (2026-10-12)` gains as
its last paragraph:

<!-- google-doc-style-ignore -->

```markdown
_W-139 (<date>, FO-1):_ a checked generic may pass a checked-symbolic argument
to a `template` binding with structural requirements (<sha-B1>), as upstream
decided leads issue 2153: the call is an ordinary call, checked at the
definition with the callee's declared return type, and only the argument's
structural requirements are checked in each specific, for functions', generic
classes' and generic interfaces' parameters; D-SC-6 stays for a conversion
outside a call, impl deduction and the generic class's `require` (W-373).
Land merge <sha-M60> with TP-1's S re-derived (<sha-S>; M18 killed, <m18>);
DR-1's call.cpp and convert.cpp test 0, 0 and 0;
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

### D.6 The register entries (B-R2, C-R, L59)

Rewritten 2026-11-02 (review fold: A-B-2 / B-B-1 / B-m-7). In
fork/register/rg1-plan.md: H9.5's verdict cell becomes "ALIGNED (W-139
discharged <date>, FO-1, D-RG-4: a checked-symbolic argument for a `template`
binding is passed as upstream's ordinary call, its structural check deferred
to each specific; the gap, W-373, is H9.7)" and its item cell "W-139
(discharged); W-373 (H9.7)" (B-R2); H5.4's verdict cell becomes "ALIGNED (W-352
discharged <date>, FO-1: in place, no `Copy` or `Destroy` per operand)" (C-R);
and three rows are added, H9.7 and H9.8 after H9.6 (B-R2) and H8.9 after H8.8
(L59):

<!-- google-doc-style-ignore -->

```markdown
| H9.7 | an impl's `require` of a template constraint in a generic class is checked at the class end with a checked-symbolic self (D-SC-6, W-373) | silent at the tip, check H9.7: `git grep -c -F 'fail_todo_implicit_self_impls'` over toolchain/check/testdata/interface/require.carbon = 3: upstream's nominal analog, impl lookup for a required interface on a checked self, is a TODO there | NONE (D-RG-1; the gap D-RG-4 names beside H9.5) | upstream states how a checked-symbolic self satisfies a requirement that needs a concrete type, or its TODO lands (the count moves) | W-355; W-373 |
| H9.8 | the per-specific structural check of a call's checked-symbolic argument for a `template` binding: deduce.cpp's `ConvertBindingArg`, an eval-block `ConvertToValueAction` on the argument in a `TemplateInst`, spliced as the deduced value, and the deferral counter in structural_conformance.cpp (W-139's fix) | silent at the tip, check H9.8: `git grep -c -w 'ConvertBindingArg'` over toolchain/check = 0; upstream has no structural requirements (H9.3) | NONE (D-RG-3: internal) | upstream's own representation of structural requirements, or a design for checking them per specific (merge into it) | W-355 |
| H8.9 | a pack expansion pattern in a choice alternative's parameter list is a semantics TODO (W-367) | silent at the tip, check H8.9: `git grep -c -i -E 'choice\|alternative'` over docs/design/variadics.md = 2 (the "Alternatives considered" heading and its contents link) | NONE | the design speaks to choice alternatives | W-355; W-367 |
```

<!-- google-doc-style-resume -->

In fork/register/rg1-checks.tsv, after H9.6's row, the tab-separated rows
`H9.7`, `G`, `-F`, `fail_todo_implicit_self_impls`,
`toolchain/check/testdata/interface/require.carbon`, `3` and `H9.8`, `G`, `-w`,
`ConvertBindingArg`, `toolchain/check`, `0` (B-R2; measured 3 and 0 at
68569d234); after H8.7's row, `H8.9`, `G`, `-i -E`, `choice|alternative`,
`docs/design/variadics.md`, `2` (L59; measured 2 at 68569d234). Each commit runs
`check_greps.sh <repository> <tip> fork/register/rg1-checks.tsv` at the day's
tip and writes its "checked <n> silence checks, 0 failed" line in its message
(91 rows on trunk 03b40f7c5, so 93 after B-R2 and 94 after L59); rg1-plan.md's
dated counts are not edited (amended 2026-11-02, review fold: B-m-7: rev 1 gave
H9.7 no check row).

## Appendix E: the landings' fields (LAND-1 Appendix C rows)

### E.1 The fields and the targets

The fields of LAND-1's Appendix A for stages 13 to 17, `<moved>` "none"
where empty; titles are the PRs' GitHub titles shortened as LAND-1's C.1 does
(measured with `gh api` on each pull request of jmann345/carbon-lang).

| PR | Suffix | Spec | Workstream | Title | Summary | Moved | Next |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 60 | sc | FO-1 2.5 | SC-1 | SC-1, template-style structural conformance (F-010) | F-010: `template constraint` requirements satisfied by a type's own members, with W-139 realigned (a checked generic's checked-symbolic argument for a `template` binding is checked per specific) and TP-1's S; W-139 discharged, W-140 narrowed, W-373 filed | none | PR 56 (OP-1) |
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
paragraph, A.10's marks (E.2's lists) and Appendix F.2's Next actions marks.
The anchors were read at the heads of section 0.1 and are re-checked unique on
each landing's records tree (D-LAND-9).

### E.2 Each landing's records values

Added 2026-11-02 (review fold: B-M-3). Measured from the trees, per stage; a
value that differs at the landing stops it (D-LAND-9, D-LAND-18). The tally is
`<tally>` after the records edits (`gaptally.py`): trunk's 36/16/3/1 moves only
where a landing changes a row's status, measured by comparing each head's
status column with trunk's for the rows the head changed (`git diff` of the
merge base and the head): PR 60 moves "Generics: Template-style structural
conformance to nominal constraints" MISSING to PARTIAL; PR 56 keeps "Stdlib:
Optional" PARTIAL; PR 57 moves it to DONE; PR 59 moves "Generics:
Definition-checked variadics" DESIGN-ONLY to PARTIAL; PR 66 moves none.

| Stage (PR) | `<tally>` | Landed, held | Gap rows taking A.10's row mark (by bullet text) | Ledger items taking the mark (appended to `notes`) | Prose labels taking the mark | Rows for step 9's `rowcheck.py` | `<rescan>` |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 13 (60) | 36/17/2/1 | 13, 5 | "Generics: Template-style structural conformance to nominal constraints" | W-027 (its labels are in its title, `evidence` and `notes`, 36 of them; one mark) | none: PR 60's head adds no Scoreboard paragraph, and its header label (cc4daba00 fork/gap-analysis.md:18-25) is inside the sentence A.8 replaces | the same row (B-R's clause and the mark) | `W-373 at step 9, before the records edit: <the refs that file it>` (FO-1 prescribes it, D-FO1-12) |
| 14 (56) | 36/17/2/1 | 14, 4 | "Stdlib: Optional" | W-058 | the paragraph PR 56's head adds under the Scoreboard heading, "Expected at OP-1, NOT of record: 132 PASS / 25 SKIP / 0 FAIL ...", after its first sentence (rulings (12) and (16)); its Branches-row label goes with A.3's row | "Stdlib: Optional" (L56's row 78 text, E.3, and the mark) | `none` |
| 15 (57) | 37/16/2/1 | 15, 3 | "Stdlib: Optional" | W-170, W-171, W-173 | "Expected at OP-2, NOT of record: 139 PASS / 22 SKIP / 0 FAIL ...", after its first sentence; the header label of e23113ba2 fork/gap-analysis.md:18-25 is inside A.8's sentence | "Stdlib: Optional" (L57's row 78 text, E.3, and the mark) and "Type system: User-defined types (classes)" (OP-2's fold names W-126 there again) | `none` |
| 16 (59) | 37/17/2/0 | 16, 2 | "Generics: Definition-checked variadics" | none | "Expected at VA-1, NOT of record: 137 PASS / 21 SKIP / 0 FAIL ...", after its first sentence; the header label (b0822a744 fork/gap-analysis.md:18-23) is inside A.8's sentence | "Generics: Definition-checked variadics" and "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop" (L59's W-284 clauses, SV-1's C.7) | `W-367 and W-368 at step 9, before the records edit: <the refs that file them>` |
| 17 (66) | 37/17/2/0 | 17, 1 | "Generics: Definition-checked variadics" and "Stdlib: tuple/array library parts" | W-212 and W-225 (labels in `evidence`) | "Expected at VA-2, NOT of record: 147 PASS / 21 SKIP / 0 FAIL ...", after its first sentence | the two rows of the row-mark column (VA-2's L and the marks) | `none` |

The labels were found by `git diff <merge base> <head> -- fork/gap-analysis.md
fork/ORCHESTRATION.md fork/inventory/work-items.json`, searching the added
lines for `not\s+of\s+record` (counts of matching lines, gap and ledger:
cc4daba00 2 and 3, 9f12209d8 1 and 1, e23113ba2 2 and 5, b0822a744 2 and 0,
43c8ab476 3 and 2, against the base of each landing: PR 57's over 9f12209d8,
PR 66's over b0822a744). Step 9's search on the records tree is the check: a
label it finds that this table lacks, or one this table names that the merge
dropped, is recorded by the review against D-LAND-5's rule that kept or
dropped it, and an unexplained one stops the landing (D-LAND-9). W-369 and
W-370 are used by no stage unless a landing finds a residue (D-FO1-12).

### E.3 Row 78's DR-0 sentence (L56 and L57)

Added 2026-11-02 (review fold: A-m-4). Item 16 and DR-1 (fork/direction/plan.md
section 1.16) keep trunk's DR-0 sentence of "Stdlib: Optional" beside the PR's
own text: at L56 the row's text is PR 56's, and at L57 PR 57's DONE text, each
with this sentence, trunk 03b40f7c5 fork/gap-analysis.md:80 verbatim, appended
before the closing `|`:

<!-- google-doc-style-ignore -->

```text
Direction drift (R32, DR-0): the class KEPT by D-EH-1 and D-OP-7 is not matchable, while upstream's loops.md matches it by `case .Some(<pattern>)` and sum_types.md designs a class with `impl as Match`, a design upstream's own README.md and generics/terminology.md cannot currently admit; W-320 waits on W-324, and the pattern for the empty alternative will be `.None()`.
```

<!-- google-doc-style-resume -->

DR-1 does not move the row's status (D-OP-13 as PR 57 amends it decides it).

## Appendix F: the orchestrator's stamps

Added 2026-11-02 (review fold: B-M-2 / B-m-4). The orchestrator's texts
(D-LAND-16), verbatim but for the placeholders. No amendment of D-LAND-12 or of
item 15 is owed: rev 2's B1 is on PR 60's branch before the land merge, in
item 15's order (D-FO1-2).

### F.1 At sign-off, before the first slice commit

The dated paragraph, after the last dated paragraph:

<!-- google-doc-style-ignore -->

```text
<date> (<hh:mm> UTC): FO-1's plan (fork/followon/fo1-plan.md, rev <r>) is
signed off and on trunk. It plans Next actions items 10, 13 and 15 to 17.
Item 10 is decided: OP-2's defect, fixed on PR 57's branch by A1, so no SC-1
commit is owed (D-FO1-1). Note 7 (VA-2's hand-off note 7, defect A) is ruled
under D-LAND-2: PR 59's own abort, fixed on PR 59's branch with W-368 filed
there (D-FO1-6); item 13's fix and W-367 go to the same branch (D-FO1-5).
W-139 is realigned on PR 60's branch before its land merge (D-FO1-2) and
W-352 on PR 56's, merged into PR 57's (D-FO1-4). W-373 is reserved to FO-1
(D-FO1-3); W-369 and W-370 stay reserved to these landings' residues. The
landings follow as stages 13 to 17 (PR 60, PR 56, PR 57, PR 59, PR 66) by
LAND-1's procedure; PR 53 waits for item 14.
```

<!-- google-doc-style-resume -->

Item 10 gains, at its end:

<!-- google-doc-style-ignore -->

```text
 (Decided <date> by FO-1, fork/followon/fo1-plan.md D-FO1-1: OP-2's defect, fixed by A1 on PR 57's branch; no SC-1 commit is owed.)
```

<!-- google-doc-style-resume -->

Item 13 gains, at its end:

<!-- google-doc-style-ignore -->

```text
 (Planned <date> by FO-1, fork/followon/fo1-plan.md D-FO1-5 and D-FO1-6: W-367's TODO and, under note 7's ruling, W-368's layout fix, both on PR 59's branch.)
```

<!-- google-doc-style-resume -->

### F.2 At each landing's records commit

Each mark is appended at the end of its item, the `<merge sha>` the landing's:

<!-- google-doc-style-ignore -->

```text
stage 13, item 15: (DONE <date>: PR 60 landed by merge <merge sha>, FO-1 stage 13.)
stage 14, item 16: (PR 56 landed <date> by merge <merge sha>, FO-1 stage 14; PR 57 follows.)
stage 15, item 16: (DONE <date>: PR 57 landed by merge <merge sha>, FO-1 stage 15.)
stage 15, item 10: (On trunk <date> with PR 57's landing, merge <merge sha>.)
stage 16, item 17: (PR 59 landed <date> by merge <merge sha>, FO-1 stage 16; PR 66 follows.)
stage 16, item 13: (On trunk <date> with PR 59's landing, merge <merge sha>; W-367 and W-368 filed.)
stage 17, item 17: (DONE <date>: PR 66 landed by merge <merge sha>, FO-1 stage 17.)
```

<!-- google-doc-style-resume -->

### F.3 After stage 17

The dated paragraph, after the last dated paragraph:

<!-- google-doc-style-ignore -->

```text
<date> (<hh:mm> UTC): FO-1 stages 13 to 17 are done: 17 PRs landed, 1
held. Trunk <trunk before> holds PR 60, 56, 57, 59 and 66 beside LAND-1's
twelve, verified in the container at each landing (final: gate <g> of <g>,
conformance <p>/<f>/<s> over <n>, <b>/56 bullets; gap tally <tally>); R21's
hosted gate is owed on all seventeen when Actions returns (R33 (b)). Held:
PR 53, landing by Next actions item 14 when its gate holds. Next: EH-C
(W-346) on trunk's base, then UA-3.
```

<!-- google-doc-style-resume -->

The Next actions lead, replaced whole by:

<!-- google-doc-style-ignore -->

```text
LAND-1 and FO-1 landed seventeen held PRs into trunk (LAND-1: PR 67, 51,
52, 54, 55, 58, 61, 62, 64, 63, 65 and 68; FO-1: PR 60, 56, 57, 59 and 66),
each merged when it was correct and verified in the container. PR 53 waits
for the realignment of its branch completed under the orchestrator's
re-ruling of the C++ boundary question (item 14). The items below stand as
the work still owed.
```

<!-- google-doc-style-resume -->

`<trunk before>` and the values are stage 17's, measured as LAND-1's
conventions say.

## Review fold record (rev 2, 2026-11-02)

Reviews A and B of rev 1 (both REJECT) folded by a fixer; every finding was
reproduced and folded, none rejected. Upstream's tip re-fetched, 68569d234
(unchanged). Measurements are the fixer's, container-local, EXPECTED, not of
record (R9), on the land tree of section 0.3 (`sim60` with S and rev 2's B1,
built under /dev/shm/fo1-fixer and deleted with this commit), with logs and
probes in `$Q`.

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| A-B-1, B-B-1: rev 1's B1 made the call template-dependent in a checked generic | BLOCKER | yes, through the reviewers' probes: rev 1's mechanism has no result type; rev 2's B1 on the land tree diagnoses x1, x14 and x10 at the definition | folded: B1 redesigned in deduce.cpp, an ordinary call with only SC-1's check deferred per specific | D-FO1-2, sections 0.2, 0.3, 0.4, 2.2, 2.5, 7, A.2 |
| A-B-2: the `CallAction` deferral is not upstream's spelling for Carbon callees | MAJOR | yes: the tip's only `TemplateInst{` is in the `CppTemplateNameType` case | folded: claims rewritten; the per-specific check registered NONE (H9.8, D-RG-3) | sections 0.6, 7, C.1, C.2, D.3, D.6 |
| A-B-3, B-M-1: a generic class's `template` parameter stays rejected | MAJOR | yes (x5, gc on PR 60's install) | folded: covered by the same deduction; gc, x5, gcd, iface measured; splits added | D-FO1-2, D-FO1-3, A.2, C.1 |
| A-m-1: W-140 left stale | MINOR | yes: `require_in_interface_symbolic` passes | folded: W-140's title, evidence and note | D.3 |
| A-m-2, B-M-2: the G-60 order fired D-LAND-12's break condition | MINOR, MAJOR | yes | folded: B1 needs no trunk code and goes first, in item 15's order; no amendment owed; stamps added | D-FO1-2, sections 2.5, 3, Appendix F |
| A-m-3, B-m-1: false premise on `T*` and a break condition contradicting section 2.3 | MINOR | yes: optional.md and optional_nested_pointer.carbon make `C*` comparable | folded: comment and reasoning corrected, the set aligned | D-FO1-4, section 2.3 |
| A-m-4: row 78's step moved off PR 57 | MINOR | yes | folded: at L57 too, with the text | section 2.7, E.3 |
| A-m-5: W-367's test, the upstream claim, VA-2's simulation | MINOR | yes: p002240 has 15 hits; the nightly rejects h03 at 1:6 | folded: two pin splits, wording corrected, review A's measurement recorded | D-FO1-5, sections 0.3, 0.6, 2.4, A.3 |
| B-M-3: per-landing records texts not concrete | MAJOR | yes: label counts as the review gave | folded: tally, marks, labels, rowcheck rows and re-scan clause per stage | E.2 |
| B-M-4: texts left to re-derivation or in scratch; the leg's oracle wrong | MAJOR | yes: the nightly has no `std::optional` mapping | folded: the leg, Doc-M (re-derived, with sum_types.md's stale sentence found here), C.5, count.carbon, the `OrderedWith` impl and S inlined | sections 2.3, 2.5, 2.7, B.2, B.5, C.4, C.5 |
| B-m-2: M18 ran the gate only | MINOR | yes | folded: conformance in M18, measured 193/3/14 over 210 | sections 0.3, 2.5 |
| B-m-3: review placement and count inconsistent; VA-2's rule not quoted | MINOR | yes | folded: one rule; VA-2's item 12 quoted | D-FO1-9, sections 2.5 to 2.9 |
| B-m-4: W-373 not reserved on trunk | MINOR | yes | folded: reserved by F.1's stamp | D-FO1-12, section 0.7, F.1 |
| B-m-5: optional.md's prelude sketch not updated | MINOR | yes | folded: the sketch gains the two interfaces and four impls | C.3 |
| B-m-6: renamed W-139 splits never instantiate | MINOR | yes | folded: both instantiated (`Caller(C)`, `G(C)`) | A.2 |
| B-m-7: the NONE reclassification uncited; H9.7 without a check row | MINOR | yes | folded: D-RG-4 and D-RG-1 cited; H9.7 and H9.8 check rows | D-FO1-3, D-FO1-13, D.6 |

Rev 2's decision changes: D-FO1-2 (B1's mechanism and order), D-FO1-3 (the
cited rule), D-FO1-4 (premise and condition), D-FO1-5 (pins), D-FO1-9 (one
review rule), D-FO1-12 (W-373 reserved), D-FO1-13 (H9.5, H9.7, H9.8). Not
re-measured by the fixer: Slices A, C and D's prototypes (unchanged but for
C1's comment and the wrapped interface line, whitespace and comment only) and
the stages 14 to 17 simulations (section 8).
