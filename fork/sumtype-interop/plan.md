<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Sum-type interop plan: `std::optional` and `std::variant` (SV-1)

**Status:** rev 5, 2026-10-20 -- SIGNED OFF FOR IMPLEMENTATION. The focused
re-review of rev 4 (66deca5ce) returned APPROVE-WITH-AMENDMENTS: every earlier
BLOCKER resolved, no new BLOCKER, one MAJOR (RR4-M1: a Carbon sum value passed
to a C++ `T&&` parameter reaches the TODO that rev 4 said no program reaches)
and three MINORs (RR4-m1 to RR4-m3). Rev 5 folds all four with no toolchain
change, each measured on the prototype v6 and its compositions (§0.6) and
listed in the [re-review of
rev 4](#re-review-of-rev-4-folded-in-rev-5-2026-10-20) of the focused re-review
fold record, and the [sign-off](#sign-off) lists every review of this plan
(amended 2026-10-20, review fold: all RR4 findings). Rev 4
(66deca5ce) folded the focused re-review of rev 3 (4eef66632), which returned
REJECT on RR3-B1, with one MAJOR and four MINORs: the land-time hunk M-VA
recognized only a bare VA-1 pack element, so a pack whose element is a tuple,
struct, array or class holding a sum type still stopped PR 59's composition at
VA-1's CHECK, and rev 3's probe rule made the member an `overload fn` call
selects depend on where the call is. Rev 4 folded all six findings (RR3-B1,
RR3-M1, RR3-m1 to RR3-m4), each measured on v6 and its compositions and listed
in the [re-review of rev 3](#re-review-of-rev-3-folded-in-rev-4-2026-10-20) of
the focused re-review fold record (amended 2026-10-20, review fold: all RR3
findings). Rev 3 (4eef66632) folded the focused re-review of
rev 2 (REJECT on B1 and B-1, six findings: RR-B1, RR-B-1, RR-M1, RR-m1, RR-m2,
RR-m3), measured on the prototype v5 (§0.6), and the re-review of rev 3 found
RR-B1, RR-B-1, RR-m2 and RR-m3 resolved, RR-M1 not resolved and RR-m1 resolved
as stated (amended 2026-10-20, review fold: all RR3 findings). Rev 2 (4d85d14fe)
folded the two adversarial plan reviews of R29(c), A and B, both REJECT, 30
findings (the [review fold record](#review-fold-record-rev-2-2026-10-20)); rev 1
(2026-10-20) is commit 3287b1072. Workstream SV-1 is W5 slice 4 of
fork/w5-choice/plan.md (§4 "S4"): the transparent `std::optional` /
`std::variant` interop mapping, the OPEN half of ledger item W-011, under gap
row 68 ("Control flow: matching — sum-type consumption incl.
std::variant/std::optional interop", PARTIAL). Branch
`claude/carbon-fork-0-1-sv`, cut from trunk 5674fe88b, whose toolchain and core
trees are identical to the fork's trunk toolchain state 0bdce60a5 (the UA-1
advance over the upstream cut c1e83b0b7). Trunk has since gained two
records-only commits, f3156a375 (the weekly upstream check of 2026-10-19:
upstream 3056e7e31 is 85 commits past the cut, 96 conflicting files, the cut
holds) and 254b935b2 (TP-1 is PR 61, held open); neither touches `toolchain/` or
`core/`. Merge position: after PR 61 (TP-1), last of the held queue (§1.15).
Ids: fork design decision **F-020** is minted here (the mapping targets, §1.1);
SV-1 reserves **W-275 to W-294** for its residues (§1.16).

**Summary.** A C++ `std::optional<T>` or `std::variant<T0, ..., Tn>`
specialization stays the C++ class the import makes of it today, so its member
functions keep working, and gains a Carbon sum type: a specific of one of nine
generic `choice` types the prelude declares in `Core.CppCompat`,
`StdOptional(T)` (the docs/design/sum_types.md `Optional(T)` declaration) or
`StdVariant1` to `StdVariant8`, whose alternatives are named by C++ index
(`.Alt0`, `.Alt1`, ...). The two convert into each other by value at the
boundary, through the C++ class's own accessors (`has_value()` and `value()`;
`index()` and `std::get<I>()`) in one direction and its default constructor
and `emplace` in the other, never by reinterpreting bytes: libc++'s layouts are
not the choice layout (§0.5). A `match`, `if`-`let`, `while`-`let` or
`let`-`else` whose scrutinee is such a C++ value converts it, so the fork's
alternative patterns consume it, with exhaustiveness. A C++ `std::optional<T>`
also converts in one implicit step to and from `Core.Optional(T)` for a
non-pointer payload, and a `Core.Optional(T)` with a concrete scalar or pointer
payload is matched as its `StdOptional(T)` view; the class `Core.Optional` is
not redesigned (PR 56 and PR 57 own it) (amended 2026-10-20, review fold:
B-M-5 / A-M4). Every conversion a caller only tests, such as an `overload fn`
candidate probe, builds no control flow and diagnoses nothing, the element
conversions of a tuple, struct or array argument included (SV-1 passes
`diagnose` through trunk's aggregate element conversion, which dropped it), and
is decided from the types alone: where the committed conversion cannot be built
(at file scope, at a template's instantiation, for a VA-1 pack element), the
probe still accepts the member and the committed call reports that limit with
a TODO, so the member a call selects never depends on where the call is; a
Carbon sum value converts only to the C++ class whose sum type it is (amended
2026-10-20, review fold: A-B1 / B-B-1 / A-B2; RR-B1 / RR-B-1; RR3-M1). Every
shape outside the mapping is diagnosed (§1.11), a Carbon sum value passed to a
C++ `T&&` parameter included (amended 2026-10-20, review fold: RR4-M1), and the
residues are filed (§1.16). On every probe of this plan and of its five
reviews, and on the compositions with the held PRs, no valid program stops the
compiler but through W-263, trunk's lowering failure for constant nested
aggregates, which a constant tuple or struct holding a sum-type constant
reaches as trunk's own nested constants do (§1.11; amended 2026-10-20, review
fold: RR4-m1), and no call silently selects another member or computes another
value; rev 3 made the
same claim, and the re-review of rev 3 falsified it twice (a pack element
reached through a tuple, struct, array or class conversion crashed PR 59's
composition, and file scope or a template's instantiation silently changed the
member an `overload fn` call selected), which rev 4 fixes and pins (amended
2026-10-20, review fold: RR3-B1 / RR3-M1). All of it is prototyped: the rev-4
prototype v6 (§0.6) emits the final diagnostics, runs every IN shape of this
plan against C++ oracles, runs the five reviews' probes, and passes the trunk
gate apart from four mechanical refills; composed with the held PRs that touch
its toolchain or prelude files, PR 57 (stacked on PR 56), PR 59, PR 60 and
PR 61, each PR's gate fails only the predicted refills, PR 59's with the
land-time rule of §3 item 8 (amended 2026-10-20, review fold: RR-M1; RR3-B1).

## §0 Audit: measurements with file:line evidence

### §0.0 Conventions

Every measurement in this plan is container-local and "expected, not of record"
(R9): no hosted run, no runner (R28), no Bazel. `$P` is the planner's scratch
directory,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1/planner3`;
its `probes/` hold every probe program named below, `runs/` every log, and
`bin/` the scripts (`probe.sh` compiles, links and runs one program and prints
one line; `diffrun.sh` runs a conformance program and its `.diff.cpp` oracle the
way fork/conformance/runner.py does; `gate.sh` runs file_test over the worktree;
`ptime.py` times the check phase). `$X` is the rev-2 fixer's scratch directory,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer`,
with the same layout: `probes/rA/` and `probes/rB/` are copies of the two plan
reviews' probes, `probes/x/` the fixer's own, `runs/` every rev-2 log, `bin/`
its scripts (`build.sh`, `ft.sh`, `mutant.sh`, `probe.sh`, `diffrun.sh`,
`r31.py`), and `final/` the rev-2 sources: `final/final.diff` (the complete
diff, kind.def, BUILD and the fail_catching.carbon split included), `final/src/`
(the changed files), `final/goldens-src/` (the golden sources without CHECK
lines), `final/goldens-filled/` (their v4 fills) and `final/progs/` (the
programs and oracles) (amended 2026-10-20, review fold: A-M1 / B-M-4). The
fixer's probes `x01` to `x20` are `$X/probes/x/`; rev 1's `$P/probes/x01` to
`x03`, other programs, appear only in §0.2's table. `$Z` is the rev-3 fixer's
scratch directory,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1/fixer3`
(amended 2026-10-20, review fold: all RR findings), with the same layout:
`probes/rr/` the focused re-review's probes (its `v0*` pack probes moved to
`probes/va/`, with `v06` and `v07` added), `probes/rA/`, `rB/` and `x/` copies
of rev 2's, `probes/y/` the rev-3 fixer's own (`y01` to `y03`), `runs/` every
rev-3 log, `bin/` its scripts (`build.sh`, `comp.sh`, `mkft.sh`, `ft.sh`,
`mutant.sh`, `probe.sh`, `runall.sh`, `diffrun.sh`, `mkfinal.sh`), `final/` the
rev-3 sources in rev 2's layout (`final/final.diff`, `final/src/`,
`final/goldens-src/`, `final/goldens-filled/`, and `final/goldens-filled-M/` for
the split appended at M-VA), and `land/` the land-time hunk of §3 item 8
(`land/m-va-pack-element.diff`). `$W` is the rev-4 fixer's scratch directory,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer4`
(amended 2026-10-20, review fold: all RR3 findings), with the same layout:
`probes/` holds copies of the focused re-review of rev 3's probes (`f/`, `h/`,
`lib/`, `rA/`, `rB/`, `rr/`, `tp/`, `va/`, `vn/`, `vn2/`, `x/`, `y/`) and the
rev-4 fixer's own (`vn4/`, n13 to n22, and `z/`, z01), `runs/` every rev-4 log,
`bin/` its scripts (`build.sh`, `comp.sh`, `mkft.sh`, `ft.sh`, `probe.sh`,
`runall.sh`, `mkfinal.sh`, `conf.sh`), `final/` the rev-4 sources in rev 3's
layout, and `land/` the land-time hunk of §3 item 8, its split, the
CHECK-stripped source of the M-VA golden and mutant M21's hunk. `$Y` is the
rev-5 fixer's scratch directory,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer5`
(amended 2026-10-20, review fold: all RR4 findings), with the same layout:
`probes/` holds copies of the focused re-review of rev 4's `cr/`, `cz/` and `w/`
probes and the rev-5 fixer's own (`rx/`, x01 to x20, and `rt/`, t1 and t2),
`runs/` every rev-5 log, `bin/` the focused re-review of rev 4's scripts pointed
at `$Y` (`build.sh`, `comp.sh`, `gate.sh`, `mirror.sh`, `probe.sh`, `relink.sh`,
`runall.sh`) and `r31.py`, `final/` `$W/final/` with fail_sum_types.carbon's
source and fills extended by the two splits of RR4-M1 (every other file is
`$W`'s), `land/` `$W/land/` with the M-VA version of that golden rebuilt over
the new fill, and `exp/` the probe-only experiment of mutant M22
(`exp/srcnode.diff`). Toolchains:

-   **trunk**: `/home/user/carbon-build/carbon-trunk/install/bin/carbon`,
    version `0.0.0-0.dev+0bdce60a5`, the baseline of every comparison; its
    file_test passes 1942 of 1942 and its conformance run is 128 PASS / 0 FAIL
    / 22 SKIP over 150, identical to the scoreboard of record
    (carbonbuild README, "Validation record").
-   **nightly**: the upstream nightly 2026.10.12, a differential oracle only
    (R30).
-   **v1**, **v2** and **v3**: the rev-1 prototypes of §0.6, the trunk build's
    objects relinked with the patched translation units of §2 (the relink
    recipe of TP-1, `$P/bin/relink.sh`) into `/dev/shm/sv1-planner3/v1`,
    `.../v2` and `.../v3`,
    with an install tree whose `core/` carries the new prelude file. A
    relinked prototype cannot change an X-macro list (`diagnostics/kind.def`)
    in place, so the rev-1 prototypes emitted each new diagnostic as
    `context.TODO` with the same facts. The relinked binaries' `carbon link`
    compiles the prelude's
    runtime objects from the trunk build's compiled-in prelude list
    (`runtimes_build_info.h`, generated from `//core:prelude_files`,
    core/BUILD:11 `glob(["prelude/**/*.carbon"])`), which lacks the new file,
    so prototype objects are linked with trunk's `carbon link`; the real build
    globs the new file in, and the prelude file declares only generics, whose
    specifics are emitted into the user's object (§0.6).
-   **v4**: the rev-2 prototype (amended 2026-10-20, review fold: all
    findings), `$X/bin/build.sh v4`, the same relink over the trunk build into
    `/dev/shm/sv1-fixer/v4`, from the sources of `$X/final/src/`. It does emit
    the final diagnostics: the eight new kinds are APPENDED to the end of
    kind.def (after `TestDiagnosticSoftContext2`), so every existing kind keeps
    its enumerator value and only the translation units that use a new kind,
    sum_type.cpp, and the one that names every kind, diagnostics/kind.cpp,
    are recompiled; no other table is indexed by the kind (measured: `grep -rn
    'diagnostics/kind.def'` finds kind.h, kind.cpp and coverage_test.cpp
    only). The final diff places the kinds after
    `CppExportResultNeedsExpectedHeader` (§2.10), which changes no text. Its
    file_test is relinked with a manifest that adds the eight new goldens
    (`/dev/shm/sv1-fixer/man/manifest.cpp`). Programs and the conformance run
    link with trunk's busybox, for the reason above, through a wrapper
    `/dev/shm/sv1-fixer/wrapinst/lib/carbon/carbon-busybox` that runs v4 for
    every subcommand but `link`, in a tree of links to trunk's install (so
    the runner finds `llvm/bin/clang++` and `carbon_install.txt` beside it).
-   **tpv4** and **op2v4**: v4 composed with PR 61 (TP-1, e408ad4d6) and with
    PR 57 (OP-2, 628273444): a `git archive` of the branch head with v4's diff
    applied, relinked over the branch's own build
    (`/home/user/carbon-build/carbon-tp`, `.../carbon-op2`) with
    `$X/bin/relink_tp.sh` and `relink_op2.sh` (§0.7, §8.6).
-   **v5**: the rev-3 prototype (amended 2026-10-20, review fold: all RR
    findings), `$Z/bin/build.sh v5 $Z/src5`, the same relink over the trunk
    build into `/dev/shm/sv1-fixer3/v5`, from the sources of `$Z/final/src/`,
    with the kinds appended as in v4 and its file_test relinked with the same
    eight goldens (`/dev/shm/sv1-fixer3/man/manifest.cpp`); programs and the
    conformance run link through the same wrapper,
    `/dev/shm/sv1-fixer3/wrapinst/lib/carbon/carbon-busybox`. **v4** is
    rebuilt beside it from `$X/final/src/` for the comparisons of §0.6.
-   **tpv5**, **op2v5**, **scv5**, **vav5g** and **vav5n**: v5 composed with
    PR 61, PR 57, PR 60 (SC-1, 40a76ab81) and PR 59 (VA-1, b0822a744), with
    and without the land-time hunk of §3 item 8 (`$Z/bin/comp.sh`): a `git
    archive` of the head in `/dev/shm/sv1-fixer3/mirror-<name>` with
    `$Z/final/final.diff` applied and kind.def kept at the relink-only
    appended position, relinked over that head's build
    (`/home/user/carbon-build/carbon-tp`, `-op2`, `-sc`, `-va`; the SC-1 build
    is toolchain-identical to 40a76ab81, which differs from its stamp
    866468cba in one golden), and gated with the eight goldens added; **vav4**
    and **vav5** are the probe builds of the PR 59 composition (the focused
    re-review's `srcva`, and v5 with the hunk).
-   **v6**: the rev-4 prototype (amended 2026-10-20, review fold: all RR3
    findings), `$W/bin/build.sh v6 $W/src6`, the same relink over the trunk
    build into `/dev/shm/sv1-fixer4/v6`, from the sources of `$W/final/src/`,
    with the kinds appended as in v5 and its file_test relinked with the eight
    goldens (`/dev/shm/sv1-fixer4/man/manifest.cpp`); programs and the
    conformance run link through `/dev/shm/sv1-fixer4/wrapinst/`. **m17** and
    **m20** are v6 with mutants M17 and M20 (§8 item 5).
-   **tpv6**, **op2v6**, **scv6**, **vav6g**, **vav6r** and **vav6n**: v6
    composed by `$W/bin/comp.sh` with PR 61 (TP-1's round-10 head eafca5cb9, as
    74e16c4de, which adds only that commit's two golden fills, relinked over a
    snapshot of `/home/user/carbon-build/carbon-tp` taken at eafca5cb9 into
    `/dev/shm/sv1-fixer4/build-tp`, since a TP-1 fix round rebuilds that tree),
    PR 57, PR 60 and PR 59 (with the rev-4 land-time hunk, with mutant M21's
    hunk, rev 3's bare `PackElement` test, and with no hunk, mutant M19).
-   **Rev 5** (amended 2026-10-20, review fold: all RR4 findings): no
    toolchain change, so v6, scv6, op2v6, tpv6 and vav6 (vav6g's sources:
    PR 59 with the rev-4 land-time hunk) are rebuilt by `$Y/bin/mirror.sh`,
    `build.sh` and `comp.sh` from `$W/final/final.diff` into
    `/dev/shm/sv1-fixer5/`, and deleted after use; tpv6 takes PR 61's pushed
    head 281292d8f (records only past 74e16c4de) and relinks directly over
    `/home/user/carbon-build/carbon-tp`, whose objects stayed at eafca5cb9
    throughout (its busybox's timestamp read before and after). **v6s** is v6
    with W-285's removal tried (`$Y/exp/srcnode.diff`: the conversion's
    blocks attributed to the converted value's parse node when its location
    is not one), mutant M22 of §8 item 5.

### §0.1 The row, the ledger item and the arbiter today

-   **Row 68** (fork/gap-analysis.md:68), PARTIAL: "Carbon-side sum-type
    consumption landed [...] — 5 conformance programs PASS [...]. Missing
    interop half: no transparent std::variant/std::optional mapping — `match`
    on an imported std::optional hits 'match on unsupported scrutinee type'
    (match_sum_type_payload SKIP; W-011 open half / W5 slice 4, SF-8 steer:
    synthesized-choice mapping)." The header (fork/gap-analysis.md:18) reads
    30 DONE / 21 PARTIAL / 4 MISSING / 1 DESIGN-ONLY.
-   **W-011** (fork/inventory/work-items.json:200): "W5b: match destructuring
    of choice payloads (landed at re-platform S2c) + transparent
    std::variant/std::optional interop (open)"; evidence
    `fork/conformance/programs/control_flow/match_sum_type_payload.carbon:6`
    and `toolchain/check/cpp/custom_type_mapping.cpp:92-104`; its arbiter, in
    its notes: "a Carbon match over an imported std::optional/std::variant
    works (open)"; coherence risk 9: "Optional's redesign (W-058) folds into
    these deliverables".
-   **The arbiter program**,
    fork/conformance/programs/control_flow/match_sum_type_payload.carbon, is
    SKIPped with the R10 reason that the scrutinee gate rejects
    `match (Cpp.MaybeSeven())`. Its intended body (lines 25-31 of the comment)
    is `case .Some(n: i32)`, `case .None => { return 1; }` and
    `default => { return 1; }`, EXPECT-STDOUT `7`.
-   **The plan text this slice implements**, fork/w5-choice/plan.md:500-516
    (S4): `std::optional<T>` maps to `Core.Optional(T)`, `std::variant<Ts...>`
    to "a choice-shaped mapping (exact target is sub-fork SF-8)"; "the mapping
    is by-value conversion at the boundary, not a reinterpret; the
    differential arbiter (C++ oracle per DIFF-1) is what keeps this honest";
    files: custom_type_mapping.cpp "+ import glue", conformance interop
    programs "both directions where exportable".
-   **The steer**, fork/decision-log.md:469 (the W5 SF-1..8 entry, user by way
    of AskUserQuestion, recorded 2026-07-20): "tagged unions are the
    first-class construct (`choice`), any Core.Variant prelude name would be
    sugar over a generic choice at most, and the default lean is the
    anonymous/synthesized-choice mapping — introducing a Variant vocabulary
    type requires affirmative justification at the S4 fork (SF-8)".
    SF-6 (same entry): "trivially-copyable + trivially-destructible payloads
    only in 0.1, clean diagnostic". SF-7: exhaustive choice matches need no
    `default` (discharged at the match re-platform's S2e).
-   **What became of `Optional`**: SF-9 was resolved at EH-A as D-EH-1
    (fork/decision-log.md:5665): "`Core.Optional` KEEPS its placeholder class
    identity — it is NOT re-platformed onto `choice`", with the break condition
    "if W-058's approved design makes `Optional` a choice". PR 56 (OP-1, F-015)
    and the stacked PR 57 (OP-2, F-016) redesign its API and keep it a class
    (§0.7).

### §0.2 What trunk and the nightly do today

Probe header: `$P/probes/m01_has_value.carbon` lines 1-18 (an inline C++
block declaring `MaybeSeven()` returning `std::optional<int>` 7, `Nothing()`,
`MaybeS()` returning `std::optional<S>` for a two-`int` struct, `MaybePtr()`
returning `std::optional<int*>`, `VarI()`/`VarD()` returning
`std::variant<int, double>`, `VarMono()` returning
`std::variant<std::monostate, int>`, `VarII()` returning
`std::variant<int, int>` at index 1, and three C++ consumers). Logs:
`$P/runs/audit-trunk.txt`, `$P/runs/audit-nightly.txt`.

| Probe | Body | trunk | nightly |
| --- | --- | --- | --- |
| m01 | `o.has_value()` on `Cpp.std.optional(i32)` | runs, 1 | runs, 1 |
| m02 | `o.value()` | runs, 7 | runs, 7 |
| m03 | `*o` | ``cannot dereference operand of non-pointer type `Cpp.std._C.optional` `` | same |
| m04 | `if (o)` | ``cannot implicitly convert expression of type `Cpp.std._C.optional` to `bool` `` | same |
| m05 | `o.operator_bool()` | ``member name `operator_bool` not found`` | same |
| m06 | `o.value_or(3)` on empty | runs, 3 | runs, 3 |
| n24 | `o.emplace(4)` then `o.value()` | runs, 4 | runs, 4 |
| m09, n25 | `v.index()` on `variant<int, double>` and `<monostate, int>` | runs, 0 and 1 (`index()` imports as `u64`) | same |
| m10, m11, m12 | `Cpp.std.get(i32)(v)`, `get_if`, `holds_alternative` (type spelled as a call) | `no matching function for call to 'get'` (and `get_if`, `holds_alternative`) | same |
| n10, n13 | `Cpp.std.get(i32, v)` on a `var` | ``argument to `ref` parameter not marked with `ref` `` | same |
| n11b, n12 | `Cpp.std.get_if(i32, &v)`, `holds_alternative(i32, v)` | runs, 42 and 1 (`get_if` returns `Core.Optional(i32*)`) | same |
| m25 | `Cpp.std.get(0)(v)` (index form) | `no matching function for call to 'get'` | same |
| a10 | `Cpp.std.visit(Cpp.Idx(), Cpp.VarD())` | ``value of type `type` is not callable`` | same |
| m13, m14, m15 | C++ `optional`/`variant` passed to C++ by value and by `const&` | runs, 7, 7, 1 | same |
| m19, n18, n19 | `Cpp.TakeOpt(7)`, `Cpp.TakeVar(2.5 as f64)`, `Cpp.TakeVar(42)` | runs, 7, 1, 0 (C++ converting constructors) | same |
| n17 | `Cpp.TakeOpt(Cpp.std.nullopt)` | ``semantics TODO: `unsupported conversion to constant from APValue {}` `` | same |
| x01, x03 | a Carbon function returning / taking `Cpp.std.optional(i32)`, called from C++ | runs, 3 and 4 | runs, 3 and 4 |
| a01, a02, m18 | `match (Cpp.MaybeSeven())` with and without `default`; `match (Cpp.MaybeS())` | ``semantics TODO: `match on unsupported scrutinee type` `` | ``semantics TODO: `HandleMatchIntroducer` `` (upstream has no `match`) |
| a03, m17 | `match (Cpp.VarI())` with `.Alt0(...)`; with `.0(n: i32)` | the same TODO; `.0` is also a parse error, ``expected identifier or `Self` after `.` `` | `HandleMatchIntroducer` |
| a07, w10 | `if (let .Some(n: i32) = Cpp.MaybeSeven())`, `while (let ...)` | ``semantics TODO: `refutable pattern binding on unsupported scrutinee type` `` | parse error |
| m20 | `let c: Core.Optional(i32) = Cpp.MaybeSeven();` | ``semantics TODO: `interop with non-identifier package name` `` at optional.carbon:30, then ``cannot implicitly convert expression of type `Cpp.std._C.optional` to `Core.Optional(i32 as Core.OptionalStorage)` `` | the same two errors (the TODO at optional.carbon:29) |
| t04 | `Cpp.TakeOpt(Core.Optional(i32).Some(3))` | the same export TODO, then ``call argument of type `Core.Optional(i32 as Core.OptionalStorage)` is not supported`` | not run |
| a08 | `let c: Core.Result(i32, i32) = Cpp.VarI();` | ``cannot implicitly convert expression of type `Cpp.std._C.variant` to `Core.Result(i32, i32)` `` | ``member name `Result` not found in `Core` `` |
| c01 | `choice` payloads `Core.Optional(i32*)`, `i32*`, `Cpp.S`, a C++ enum, `f64`/`bool`, `Cpp.int` | the first and third rejected, ``semantics TODO: `choice alternative payload that is not trivially copyable and destructible` ``; the rest admitted | ``choice alternatives with parameters are not yet supported`` |
| r03 | `match (Opt(i32).None)` on a Carbon generic choice with a payload arm | **crash**: `Load operand must be a pointer`, `CHECK failure at toolchain/lower/lower.cpp:48: !llvm::verifyModule` | `choice alternatives with parameters are not yet supported` |
| r04 | the same scrutinee bound by `let` first | runs, -1 | as r03 |
| t01 | `let g: i32 = if Cpp.MaybeSeven().has_value() then 1 else 2;` at file scope | ``semantics TODO: `Control flow expressions are currently only supported inside functions.` `` | not run |
| t02 | `match` on a `template` parameter whose argument is a Carbon choice | ``semantics TODO: `match on unsupported scrutinee type` `` | not run |

So, on trunk: the class imports (`Cpp.std._C.optional`, `_C` being libc++'s
inline namespace `__1`), its plain member functions work, operators that would
need a Carbon spelling (`*`, `bool`) do not, the index form of `std::get` cannot
be spelled (toolchain/check/cpp/call.cpp:25-30: "TODO: We should also have a way
to specify that an argument is a non-type template argument"), passing and
returning the C++ class works in both directions, and no Carbon sum type
exists to match. r03 is a pre-existing lowering crash on a Carbon-only shape
that this slice's conversions reach (§0.4, D-SV-9). The nightly agrees on every
interop row and has no `match` at all.

**On v4** (added 2026-10-20, review fold: B-M-5 / A-B2;
`$X/runs/audit-v4-m.txt`, `$X/runs/x-v4.txt`). m20 and t04 compile and run
(t04 prints 3), and their printing variants `$X/probes/x/x01` (a
`Core.Optional(i32)` initialized from `Cpp.MaybeSeven()` and from an empty
optional) and `x03` (a `Core.Optional(i32)` passed to C++ by value, by
`const&` and as `.None()`) print 7 -1 and 3 103 -1, where trunk still gives
the table's errors (`$X/runs/x-trunk.txt`). m19, n18 and n19, a Carbon scalar
passed to a C++ converting constructor, are unchanged (7, 1, 0): the hook owns
only sum-typed values. A Carbon sum value passed to a C++ class other than its
own, which a converting constructor of that class would accept, is the reverse
mismatch error instead of a crash (§1.5).

### §0.3 The import path, and where each mapping step hooks in

Read for this section: toolchain/check/cpp/import.cpp, type_mapping.cpp,
custom_type_mapping.cpp, impl_lookup.cpp, thunk.cpp, overload_resolution.cpp,
call.cpp, toolchain/check/convert.cpp, refutable_binding.cpp, handle_match.cpp,
handle_choice.cpp, pattern_match.cpp, type.cpp; and, for rev 2 (amended
2026-10-20, review fold: A-B1 / B-B-1 / A-M3), convert.h's `ConversionTarget`,
call.cpp's `overload fn` probe, deduce.cpp and every caller of
`IsInSliceChoicePayloadType`.

| Step | Where today | What a mapping needs there |
| --- | --- | --- |
| Recognize the C++ specialization | custom_type_mapping.cpp:20-123, the matcher library (`StdClassTemplate`, `TemplateArgumentsAre`); `GetCustomCppTypeMapping` at :125-141 returns `Str` for `std::string_view` (:89-102; the ledger's evidence cites :92-104) and `Span` for a dynamic-extent `std::span` (:106-122, SL-2's D-SL-8) | two matchers, `StdOptional` (one type argument) and `StdVariant` (one pack of types), and a classifier returning the alternatives in C++ order |
| Replace the imported type | import.cpp:1333-1360 `LookupCustomRecordType`: `Str` imports as `Core.String`, `Span` as `Core.Slice(T')`; the replacement is sound only because the layouts are identical (`{ptr, size}`, D-SL-8's layout premise) | **nothing**: the layouts differ (§0.5), so the class must stay the imported type (§1.1, F-020) |
| Convert a value | convert.cpp `PerformBuiltinConversion` (:1529-1800); a C++ class source with a Carbon class target otherwise falls through to impl lookup and the C++-conversion path, which tries to export the target (the m20 TODO) | a hook before ":1798 Split the qualifiers off the target type": C++ class value to its sum type, and back |
| Test a conversion without performing it (rev 2; amended 2026-10-20, review fold: A-B1 / B-B-1) | `TryConvertToValueOfType`, which sets `ConversionTarget::diagnose` false (convert.h:79-83: "If `diagnose` is false, an `ErrorInst` may be returned, but it must be discarded"); its callers are the `overload fn` probe (call.cpp:549 inside `ProbeOverloadCandidate`, :566-596, which converts in a scratch block, pops it with `PopAndDiscard`, discards the cleanups and CHECKs that nothing leaked), deduction (deduce.cpp:345, :570) and the slice-element test (cpp/import.cpp:1316); trunk's `ConvertAggregateElement` (convert.cpp:361-406) builds each element's `ConversionTarget` without the aggregate's `diagnose` (:393), so a tuple, struct or array argument's elements are converted diagnosing inside the probe (amended 2026-10-20, review fold: RR-B1 / RR-B-1) | the hook decides from the types, and from whether the committed conversion could be built there, emits nothing and builds no block when `diagnose` is false (§1.4); `ConvertAggregateElement` passes `diagnose` to its elements (§2.5); rev 1 built its branch blocks there, rev 2 still did through an aggregate |
| Synthesize a witness from C++ accessors | impl_lookup.cpp:600-656 `BuildCppContiguousRangeWitness` (SL-2's `Core.CppContiguousRange`, core/prelude/types/cpp/slice.carbon:32-37): each witness entry is an imported C++ member function, `data()` and `size()`, found by `LookupCppMemberWithResultType` (:574-598) | not used (§7.2 R-B): `std::get<I>` and the index-tagged construction are not single member functions |
| Call a C++ function with an integer template argument | call.cpp:42-64 splits a Carbon call's arguments into template and function arguments only for types and templates (`IsTemplateArg`, :30-36); overload_resolution.cpp:266 `PerformCppOverloadResolution` takes `template_arg_ids` | the conversion calls `std::get<I>(v)` and `v.emplace<I>(x)` through `PerformCppOverloadResolution` directly with an integer literal `I`, which no Carbon spelling can do today |
| Generate C++ thunks | thunk.cpp:399 `IsCppThunkRequired`, :1037 `BuildCppThunk`, :1549 `PerformCppThunkCall`; :370-398 decides the exception fence | nothing new: every accessor call goes through the existing call path, which builds `<callee>__carbon_thunk` where it already would (§0.5) |
| Offer a Carbon argument to C++ overload resolution | type_mapping.cpp:695 `InventClangArg`, which maps the argument's type with `MapToCppType` (:504) | the sum type of an argument maps to its C++ class before `MapToCppType`, which would otherwise try to export the `Core` choice (the m20 TODO) |
| Gate a `match` scrutinee | handle_match.cpp:190-206 calls `CheckRefutableScrutinee` (refutable_binding.cpp:137-207), shared with `if`-`let`, `while`-`let` and `let`-`else`; its shape gate `IsSupportedScrutineeType` (:83-129) admits integers, `bool`, matchable choices (`IsMatchableChoiceType`, pattern_match.cpp:499), tuples and structs of them; :199-202 emits the TODO | convert an admitted C++ sum value to its sum type after `RequireCompleteType` (:186-197) and before the shape gate |
| Admit a payload | type.cpp:337-354 `IsInSliceChoicePayloadType`: the unqualified, transitively adapted type is an integer, float, `bool` or pointer type, or `()` (D-EH-2); consulted by handle_choice.cpp:760, the per-specific hook eval_inst.cpp:310, :342, and cpp/thunk.cpp:1275 for a catching import's success type (four sites; amended 2026-10-20, review fold: A-M3) | the alternatives' Carbon types must pass it; nullable C++ pointers need D-SV-8, which admits `Core.Optional(T*)` by name and nothing else |

SL-2's precedent, read in full: the `std::span` matcher (D-SL-8) replaces the
imported type because the layouts agree; the `Core.CppContiguousRange`
witness (D-SL-9) is a conversion synthesized at the boundary from a C++
class's accessors, with the blanket `ImplicitAs(Slice(C.Element))` impl in the
prelude (core/prelude/types/slice.carbon:100-106) anchored on `Slice` by the
orphan rule (core/prelude/types/cpp/slice.carbon:21-28). SV-1 follows the
second precedent's shape, a by-value conversion from the class's accessors,
but synthesizes the conversion's SemIR in the toolchain rather than through a
synthesized witness; §7.2 R-B measures the witness form and gives the reasons.

**How the fork's choices are represented and matched.** handle_choice.cpp
builds a choice from its declaration: the class with `is_choice` set
(handle_choice.cpp:84, the only place it is set; import_ref.cpp:2031 copies it
on import), the alternatives side table `SemIR::ChoiceAlternative`
(name, index, `has_parameters`, payload field index), the representation of
F-007k (docs/design/unions.md, "Relationship to choice types": a discriminant
plus union storage for the payloads, `UInt(ceil(log2(n)))` per SF-2, the
payload region a `CustomLayoutType`), per-specific layout for generic payloads
(W5-S3b), synthesized `Copy` and `Destroy` witnesses (W-075, custom_witness.cpp
:279 primitive copy for in-slice payloads), and SF-6's per-specific payload
check (eval_inst.cpp:310-345, `ChoicePayloadNotTrivialInSpecific`). A match
tests the discriminant (`EmitChoiceDiscriminantTest`, pattern_match.cpp:573)
and binds payload elements (`EmitChoicePayloadFieldAccess`, :1048), with
SF-7 exhaustiveness and the dead-`default` error (`MatchDefaultNeverMatches`,
handle_match.cpp:1082-1133, W-078a).

### §0.4 The choice machinery's limits for a mapped choice

1.  **No choice exists without a source declaration.** `Class::is_choice` is
    set in one place, handle_choice.cpp:84, while checking a parsed `choice`
    declaration; import_ref.cpp:2031 copies the flag from an imported class
    that a source file declared. The alternatives table, the F-007k
    representation, the alternative constants and factory functions and the
    synthesized `Copy`/`Destroy` witnesses all hang off that declaration path.
    A compiler-synthesized choice per C++ specialization would have to
    reproduce all of it without a parse tree, plus an identity rule across
    files (§7.2 R-C). A specific of a generic choice declared in the prelude
    reuses every piece as is: measured on the prototype, the specific
    `StdOptional(i32)` mangles as any generic class does
    (`_CSome.StdOptional.CppCompat.Core.84588f41d61dafba`, `$P/runs/arb.ll`),
    its payload-free alternative is the constant `StdOptional.val` and its
    payload alternative the specific function `StdOptional.Some`
    (`$P/runs/arb.semir`), and a library that returns it hands it to a
    consumer that matches it (`$P/probes/v1/xlib`, prints 7).
2.  **Generic payloads** work since W5-S3b: the layout is recomputed per
    specific, and SF-6's per-specific hook (eval_inst.cpp:310-345) rejects a
    specific whose payload is not admitted with
    `ChoicePayloadNotTrivialInSpecific`. The mapping checks admission itself
    before it forms the specific (§1.3), so a C++ type outside the mapping is
    diagnosed for what it is, not as a choice-specific error.
3.  **Payload admission (SF-6)** is narrower than "trivially copyable":
    type.cpp:337-354 admits integers, floats, `bool`, pointers and `()` after
    adapters, and rejects aggregates. Measured (`c01`): `Cpp.S`, a
    trivially copyable two-`int` struct, is rejected; a C++ enum and
    `Cpp.int` are admitted; and `Core.Optional(i32*)`, the type a nullable C++
    `int*` imports as, is rejected, because its adapter chain reaches the
    pointer through a `MaybeUnformed` qualifier that the unqualify-then-adapt
    walk does not strip. D-SV-8 admits `Core.Optional(T*)` by name and no
    other type (§1.8; amended 2026-10-20, review fold: A-M3: rev 1's widened
    walk also admitted `Cpp.nullptr_t` and `MaybeUnformed` types).
4.  **Exhaustiveness (SF-7)** applies to a choice scrutinee whatever produced
    it, and a `default` after full coverage is an error
    (`MatchDefaultNeverMatches`, handle_match.cpp:1082, with the
    `MatchDefaultNeverMatchesFullCoverage` note at :1126). Measured on the
    prototype (`a01`, `s01`): the arbiter's sketched body, which ends with
    `default => { return 1; }`, is rejected with "`default` arm never
    matches; every value of the scrutinee is matched by prior arms"; without
    the `default` it runs and prints 7 (`a02`).
5.  **`Core.Result` and `Core.Optional`.** D-EH-1 keeps them independent: no
    implicit bridge between them; each implements `Try`. This slice adds no
    bridge to `Result` either: a variant's alternatives are positional, so
    `std::variant<int, int>` has no `Ok`/`Err` reading, and `a08` (a
    `std::variant<int, double>` initializing a `Core.Result(i32, i32)`) stays
    the conversion error it is today. A C++ `Carbon::expected<T, E>` import
    is W-085's.
6.  **A constant choice scrutinee crashes lowering today.** `r03`, a `match`
    directly on `Opt(i32).None` of a Carbon generic choice with a payload arm,
    fails LLVM verification (`Load operand must be a pointer`,
    lower/lower.cpp:48). Root cause, toolchain/lower/constant.cpp:243-263
    (`EmitAsConstant(AnyAggregateAccess)`): it builds a constant GEP whose base
    is `GetConstant(inst.aggregate_id)`, assuming an address; when the access is
    folded out of a constant class VALUE (the payload field of a constant
    `choice` value), the base is the value itself, an LLVM constant of aggregate
    type, and the GEP and the later load are ill-formed. The mapping reaches
    this whenever a constant alternative of a payload-carrying `StdOptional`/`StdVariant<N>`
    is read (the reverse conversion of a `.None` constant, `s18`), so this slice
    fixes it at the root (§1.9, D-SV-9). No ledger item records it (`grep -n
    'Load operand' fork/inventory/work-items.json` finds nothing).
7.  **Template-dependent scrutinees** are rejected for every choice, mapped or
    not (`t02`: the scrutinee gate sees the template parameter's symbolic
    type); generic (checked) functions over a choice specific work (`t03`).
    With PR 61 (TP-1), which lands first, a conversion whose type is
    template-dependent is deferred and performed at instantiation, outside any
    function body (§1.10, W-279), and a `match` on a template-dependent choice
    value stops at TP-1's pattern_match.cpp:1409 with no C++ involved (X-1 of
    the fold record) (amended 2026-10-20, review fold: A-M1).

### §0.5 Layouts, and why the conversion goes through the accessors

libc++ 21.1.8 (`/home/user/llvm/include/c++/v1`, the host library the task
names) and the toolchain's own runtime headers (libc++ 24.0,
`install/lib/carbon/runtimes/libcxx/include`, `_LIBCPP_VERSION 240000`, what an
`import Cpp` actually compiles against) agree on the shapes:

-   `std::optional<T>` stores the value first and the engaged flag after it:
    `remove_cv_t<value_type> __val_;` then `bool __engaged_;` (21.1.8
    optional:295-297; 24.0 `__optional/optional.h:84-86`). Measured with the
    host compiler (`$P/probes/layout.cpp`): `optional<int>` is 8 bytes, flag
    at byte 4; `optional<long>`, `<double>`, `<int*>` 16 bytes; all trivially
    copyable and destructible.
-   `std::variant<Ts...>` stores the union of the alternatives first and then
    `__index_t __index;`, an `unsigned char` below 255 alternatives, whose
    "valueless" value is the all-ones `__variant_npos` (21.1.8 variant:349-361,
    :745; 24.0 variant:364, :762). Measured: `variant<int, double>` is 16 bytes
    with the index in byte 8 (1 for the `double` alternative);
    `variant<monostate, int>` and `variant<int, int>` 8 bytes.
-   The fork's choices put the discriminant first: measured in the prototype's
    lower golden, `StdOptional(i32)` is `<{ <{ i1, [3 x i8] }>, [4 x i8] }>`
    and `StdVariant2(i32, f64)` is `<{ <{ i1, [7 x i8] }>, [8 x i8] }>`; the
    discriminant is `UInt(ceil(log2(n)))` (SF-2), `Some` is 0 and `None` 1 in
    declaration order, and no choice value is "valueless".

So the bytes disagree on field order (payload-first against
discriminant-first), on the tag's width and encoding (`bool` engaged = 1
against `Some` = 0; an `unsigned char` index with a valueless sentinel against
an `i1`), and on the valueless state, which a choice cannot represent.
Reinterpreting one as the other is wrong for every specialization; and the
layout is the library's private business (libc++ and libstdc++ differ, and
`_LIBCPP_ABI_*` macros change it), while the accessors are the standard
interface. The conversion therefore calls the accessors, which are ABI-stable
by construction: `has_value()`, `value()`, the default constructor and
`emplace(x)` for `std::optional`; `index()`, `std::get<I>(v)`, the default
constructor and `v.emplace<I>(x)` for `std::variant`.

**Thunks.** Every accessor is called through the existing Carbon-to-C++ call
path, which builds a `__carbon_thunk` wherever its existing rules already do
(thunk.cpp:399 `IsCppThunkRequired`; the exception fence of :370-398). With
libc++ 24.0, measured in `$P/runs/arb.ll` and `$P/runs/s02.ll`: one internal
thunk each for `has_value()`, `value()`, `index()` and each `std::get<I>`
used, per specialization and translation unit, beside the C++ function's own
thunk; `value()` and `std::get<I>` are fenced (they can throw
`bad_optional_access` / `bad_variant_access`), which costs a landing pad that
the guarded call never takes. No new thunk kind is generated: the cost is the
existing per-callee thunk, an `internal` function the optimizer can inline,
and the conversion's branches. `--cpp-exceptions=none` compiles and runs the
same programs (`w13`: 7 and 2).

**Valueless variants** (rewritten 2026-10-20, review fold: A-m2). A
`std::variant` becomes valueless when an alternative's construction throws
during assignment or `emplace`, and that is reachable for admitted
alternatives: `v.emplace<1>(Thrower{})` on a `std::variant<int, double>`,
where `Thrower` has a throwing `operator double()`, leaves `v` valueless
(review A's probe a9_valueless, `$X/probes/rA/a9_valueless.carbon`). Rev 1's
premise that no admitted construction can throw was wrong: the conversion that
throws runs before `emplace` stores anything, on a C++ type that is not an
alternative. The conversion still never reads a wrong value: it tests
`index()` against 0 to n-2 and calls `std::get<n-1>` in the last arm, which on
a valueless variant throws `bad_variant_access` into the B0 fence, which
terminates with its one-line message. Measured on v3 and v4: a9 exits 134 with
``carbon: C++ exception escaped into Carbon through `std::get`; terminating``
and libc++'s ``std::get: variant is valueless``. The fail-stop is the
behavior; no golden pins it (a lower golden cannot run, and a program that
exits 134 is not a conformance PASS), and R-7 records it.

### §0.6 Prototypes and measurements

**Rev 5 (v6, no toolchain change), amended 2026-10-20, review fold: all RR4
findings.** v6 and its compositions are rebuilt from `$W/final/final.diff`
(§0.0); rev 5's only source change is the two new splits of
fail_sum_types.carbon (§1.12). Measured (`$Y/runs/`):

-   **The re-review of rev 4's findings, reproduced** (`repro-rr4.txt`; its
    probes copied to `$Y/probes/cr/`, `cz/` and `w/`): r2, r3, r4, r5 and y02
    give ``semantics TODO: `conversion of a C++ `std::optional` or
    `std::variant` with no source expression` `` at the C++ parameter, with the
    note ``initializing function parameter``; r1 prints 7 and w14 6 8 -1; z1, z7
    and y11 stop at lower.cpp:48
    (``Global variable initializer type does not match global variable type``),
    while z2 prints 3 and y12, y13 and y14 run (7; 10; 4 7); on trunk z5, z8 and
    z9 stop there too and z3, z4 and z6 print 1; w03 and w35, a parameter's
    default value, give the outside-a-function-body TODO.
-   **The `T&&` shape, scoped** (`$Y/probes/rx/` and `rt/`, `rx2.txt`): an
    initializing expression of a sum type or `Core.Optional` reaches the TODO
    through a lone `T&&` (r2 to r5, x20), the `T&&` member of a `const T&`/`T&&`
    pair of free or member functions (x07, x09, x19) and
    `std::vector::push_back` (x13, the TODO located in libc++'s vector header);
    a `const std::optional<int>&&` parameter converts (x01 prints 5); a value (a
    `let` or parameter binding, `.None`, or `as` the C++ class) selects the
    pair's `const&` member (x14 105, x16 105, x18 -100, x10 105) and is refused
    by a lone `T&&` with C++'s ``no matching function for call to 'RR'`` (x02 to
    x06, x11, x12), as a `let` of the C++ class or of any C++ struct is on trunk
    (t1, t2); a C++ call's result binds the `T&&` (r1 7, x08 207, x17 1), and so
    does a C++ function that returns the class (x15 5).
-   **The new split** (`autoupdate-rr-*.log`): `fail_todo_rvalue_ref_param`,
    with its `sink.h`, fills from the CHECK-stripped source to a fixpoint in two
    passes (the second renumbers one line of `fail_todo_export_sum_type`'s
    diagnostic back to rev 4's fill; a third writes nothing), and the file's
    other splits are byte-identical to `$W`'s fill. The M-VA version
    (`$Y/land/`), refilled on vav6 from that fill, converges in one pass, and
    its `fail_todo_pack_element` fill is byte-identical to
    `$W/final/goldens-filled-M/`'s.
-   **Gates** (`gate-<name>.log`): v6 1946 of 1950, scv6 1963 of 1967, tpv6
    (over 281292d8f's tree) 1961 of 1965 and vav6 1964 of 1968, the four
    function-pointer refills only; op2v6 1951 of 1958, op2v5's seven failures;
    the M-VA version passes on vav6 (`gate-vav6-M.log`). On every composition
    the 44 programs of `cr/`, `cz/`, `rx/`, `rt/` and `w/` print what they print
    on v6 (`probes-<name>.txt`, equal once the CHECK messages' source paths are
    normalized); the only stops are the W-263 shapes.
-   **Mutant M22** (`mut-m22.log`, on v6s): the split turns red, `R` compiling
    with no diagnostic; r2 prints 5, r4 4, r5 5, y02 5, x07 205, x09 205, x13 1
    and x20 1, while r3 and x19, the `Core.Optional` forms, keep the TODO (the
    bridged value's location is the parameter's too).
-   **Conformance** is not re-run: the toolchain and the programs are rev 4's,
    whose run the focused re-review of rev 4 repeated (134 / 0 / 21 over 155,
    every status as on v6).
-   **Id re-scan** (§8 item 7; `ids-refs.txt`, `ids-worktrees.txt`): 83 refs and
    15 worktree ledgers, no id of SV-1's block anywhere; TP-1's W-295 to W-297
    on its pushed branch 281292d8f, its local branch and the carbon-tp worktree;
    F-020 in no decision log.

**Rev 4 (v6), amended 2026-10-20, review fold: all RR3 findings.** v6
(`$W/final/final.diff`; built by `$W/bin/build.sh v6 $W/src6`) is v5 with the
fold of RR3-M1: the non-diagnosing path decides from the types alone and no
longer calls `CanBuildBranches`, which loses its `diagnose` parameter (§1.4);
convert.cpp and every file but sum_type.{h,cpp} are v5's. The land-time hunk
M-VA (RR3-B1) is `$W/land/m-va-pack-element.diff`, measured on the PR 59
composition only, since it names a VA-1 instruction kind. Measured on v6
(`$W/runs/`):

-   **The re-review of rev 3's probes** (`$W/probes/`, copies of its `$Z`-style
    sets; `probes-v6.txt` against its v5 results): the 120 programs of rA, rB,
    x, rr and y print what they printed on v5, except p05, the `overload fn`
    call at file scope, which gives the file-scope TODO again, as on v4, by the
    RR3-M1 rule; f01 gives the file-scope TODO at its `let` (v5, and mutant M20:
    `1 2`); the 48 programs of h (the re-review of rev 3's hunt: parameter
    shapes, C++ default arguments and template deduction, 18 unusual alternative
    types, user `ImplicitAs` and `As` impls) print what they printed on v5, h40
    3 4 included; the imported overload set of lib prints 10 9 100; no probe
    crashes.
-   **Templates on trunk's build**: t4 and t7 give ``unable to monomorphize
    specific `F(Cpp.std._C.optional)` `` with W-279's TODO as its note at
    `P(x)`; on M20 t7 prints `1 2` and t4 gets ``no member of overload set
    `P` accepts this call``, which reproduces RR3-M1 without TP-1.
-   **The sum-free element probe** (z01, `$W/probes/z/`): t01's members with
    a `bool` second return print 2 on v6; trunk and M17 give ``cannot
    implicitly convert expression of type `bool` to `i32` `` (RR3-m4).
-   **Gate** (`$W/runs/gate-v6.log`): 1946 of 1950, the four function-pointer
    goldens (34 differing lines, all `clang_function_pointer_type<N>`);
    refilled by autoupdate, 1950 of 1950 (`gate-v6-2.log`).
-   **Goldens** (`$W/runs/autoupdate-v6-final-*.log`): the CHECK-stripped
    sources of Appendix B refill to a fixpoint in two passes (a third writes
    nothing); eight are byte-identical to v5's fills, and
    sum_type_overload.carbon has its sixteen splits, the two `fail_todo_`
    ones with the TODOs of §4.
-   **Conformance** (`$W/runs/conf-v6.log`, scoreboard
    `conf-v6-scoreboard.json`): the full suite with the six programs over
    `/dev/shm/sv1-fixer4/conf-tree` behind the link wrapper: 134 PASS / 0
    FAIL / 21 SKIP over 155, bullets 48 PASS, 0 FAIL, 8 SKIP of 56, runner
    exit 0; every one of the 155 programs has its v5 status;
    `--update-readme-table` then `--self-test` pass (`conf-selftest.log`).
-   **Mutants** (§8 item 5): M17 stops file_test on sum_type_overload.carbon
    with ``Built invalid semantics IR: No terminator in block``
    (`mut-m17.log`); M20 turns `fail_todo_file_scope` and
    `fail_todo_template_overload` red, both compiling with no diagnostic
    (`mut-m20.log`).
-   **The PR 59 composition with the rev-4 M-VA** (vav6g; `probes-vav6g.txt`,
    `gate-vav6g.log`, `gate-vav6g-M.log`): v02, v03 and v04, n01 to n08, n13,
    n14 and n16 to n21 give ``semantics TODO: `conversion of a C++
    `std::optional` or `std::variant` for a pack element` ``; n15 (an
    adapter's `as` in an expansion body) and n22 (a `var` pack) get VA-1's
    own TODOs; v05 VA-1's ``control flow in a pack expansion``; v00 prints
    1 2, v01 7 -1, v06 7 -1, v07 4 -1, n09 7 1 -1 2 and n10 8 1; no probe
    crashes. The gate passes 1964 of 1968, the four refills, before and
    after the extended `fail_todo_pack_element` split is filled (two passes
    to a fixpoint, the file's other splits byte-identical). With rev 3's
    bare test (vav6r, mutant M21), n01 to n05 stop at VA-1's CHECK
    (convert.cpp:587), as the re-review measured on vav5g, and the split
    stops there at `ForwardTuple`; with no hunk (vav6n, M19) it stops at
    `Forward`.
-   **The other compositions** (`$W/runs/comp-*.txt`, `gate-<name>.log`):
    tpv6 (TP-1's round-10 head) passes 1961 of 1965 and scv6 1963 of 1967,
    the four refills only; op2v6 1951 of 1958, op2v5's seven failures. On
    tpv6 (`probes-tpv6.txt`): h1, h2, h3, t2, t4, t5, t6, t7 and x20 give
    W-279's TODO under ``unable to monomorphize specific``, q05 prints 5,
    t3 3 4 and x19 0 (X-1 fixed); sum_type_overload.carbon passes unchanged
    on tpv6 and vav6g.

**Rev 3 (v5), amended 2026-10-20, review fold: all RR findings.** v5
(`$Z/final/final.diff`; built by `$Z/bin/build.sh v5 $Z/src5`) is v4 with the
folds of the focused re-review: convert.cpp's `ConvertAggregateElement` passes
the aggregate conversion's `diagnose` to each element (§1.4, §2.5; RR-B1 /
RR-B-1); a non-diagnosing conversion is accepted only where the committed one
can be built (`CanBuildBranches`, §1.4; RR-m1); and a `Core.Optional` target
whose payload is not matchable is left to `Core.Optional`'s own conversions
(§1.4; RR-m3). The probes, the first gate, the fills and the mutants ran on
v5 builds whose sources differ from `$Z/final/src/` in comments only; the
final gate (`gate-v5-3.log`), the compositions and the conformance run used
the final sources. Measured on v5 (`$Z/runs/`):

-   **The focused re-review's probes** (`$Z/probes/rr/`, its 31 probes on the
    trunk build; `probes-v5.txt` against a v4 rebuilt from `$X/final/src/`,
    `probes-v4.txt`): the seven that stopped v4 with ``Built invalid semantics
    IR: No terminator in block`` (p06, p15, q04, q05, q06, q07, q09) print 8,
    8, 8, 8, 5, 8 and 7, as on the reviewer's v4fx; p05 (an `overload fn`
    call at file scope) calls the member that takes the C++ class and prints
    2, where v4 gave the file-scope TODO; k01 to k03 give trunk's own error
    again (``semantics TODO: `interop with non-identifier package name` `` at
    optional.carbon:30), where v4 gave a misleading `CppSumTypeMismatch`; t01,
    trunk's own `overload fn` probe on a tuple of scalars, calls the second
    member (2) where trunk and v4 give ``cannot implicitly convert expression
    of type `bool` to `i32` ``; the other 19 print what they printed on v4
    (q01 8, q02 8, q03 -3, q08 5, p01 7 -1, ...).
-   **The fixer's probes** (`$Z/probes/y/`): y01, a member whose tuple
    parameter holds a mismatching sum type declared first, prints 8 (v4:
    `CppSumTypeMismatch`, the hard error of RR-B-1); y02, a struct argument in
    the reverse direction, prints 6 (v4: the crash); y03, deduction with a
    tuple parameter holding a sum type, prints 9 -1 on both.
-   **Every earlier probe** (`$Z/probes/rA/`, `rB/` and `x/`: reviews A's and
    B's and the rev-2 fixer's, 86 programs): identical output on v4 and v5, so
    the original counterexamples stay fixed (a1 7, a1b 3, a1c 7, a2 2, r01 to
    r06 2 7 7 1 4 7, a7, a10, a11, x04 and x05 the reverse mismatch).
-   **Programs** (`$Z/runs/progs-v5.txt`): the arbiter prints 7, exit 0; the
    five differential programs are DIFF-PASS at 11, 14, 7, 16 and 4 lines, as
    on v4.
-   **Gate** (`$Z/runs/gate-v5.log`): file_test over trunk's 1942 files and the
    eight new goldens: 1946 of 1950; the four failures are the function-pointer
    goldens, 34 differing lines, all `clang_function_pointer_type<N>`;
    refilled by autoupdate, 1950 of 1950 (`gate-v5-3.log`, on the final
    sources).
-   **Goldens** (`$Z/runs/autoupdate-v5-*.log`): the CHECK-stripped sources of
    Appendix B refill to a fixpoint in two passes (a third writes nothing);
    eight are byte-identical to their v4 fills, and sum_type_overload.carbon
    gains its eight new splits with no diagnostic. That golden dumps no SemIR,
    so it pins that every split compiles without a diagnostic or a crash, and
    the probes above pin which member each call selects.
-   **Conformance** (`$Z/runs/conf-v5.log`, scoreboard
    `conf-v5-scoreboard.json`): the full suite with the six programs, over
    `/dev/shm/sv1-fixer3/confwt` behind the link wrapper of §0.0: 134 PASS / 0
    FAIL / 21 SKIP over 155, bullets 48 PASS, 0 FAIL, 8 SKIP of 56, runner
    exit 0; every program's status is v4's (§5's prediction holds).
-   **Mutants** (`$Z/bin/mutant.sh`): M17, the propagation reverted, stops
    file_test on sum_type_overload.carbon with ``FATAL failure at
    toolchain/check/context.cpp:86: Built invalid semantics IR: No terminator
    in block``; M18, the `CanBuildBranches` test of the non-diagnosing path
    removed, turns its `file_scope` split red with the file-scope TODO
    (`$Z/runs/mut-m17.log`, `mut-m18.log`).
-   **Compositions** (§0.7, §8.6; `$Z/runs/comps.txt`, `gate-<name>.log`):
    tpv5 passes 1959 of 1963 and scv5 1963 of 1967, failing the four
    function-pointer refills only; op2v5 1951 of 1958, the same seven failures
    as op2v4 (§0.7); PR 59 with the land-time hunk (vav5g) 1964 of 1968, the
    four refills only, so VA-1's own goldens are unchanged by the hunk. The
    PR 59 probes (`$Z/probes/va/`): on vav4 (the reviewer's composition) v02
    and v04 stop at VA-1's CHECK ``Control flow in a pack element
    conversion`` (convert.cpp:583); on vav5 v02, v03 and v04 give ``semantics
    TODO: `conversion of a C++ `std::optional` or `std::variant` for a pack
    element` `` (v03, a C++ pack element converted in an expansion body, gave
    VA-1's per-element cleanup TODO on vav4); v00 prints 1 2, v01 7 -1, v05
    gives VA-1's ``control flow in a pack expansion`` TODO on both, and v06
    and v07 (a pack of C++ optionals, and one of `StdOptional(i32)`, forwarded
    without a conversion) print 7 -1 and 4 -1 on both. The split
    `fail_todo_pack_element` (Appendix B) fills on vav5g with the TODO twice,
    and stops vav5n (the composition without the hunk) at that CHECK
    (`$Z/runs/mut-m19-va.log`; mutant M19).

**Rev 2 (v4), amended 2026-10-20, review fold: all findings.** v4
(`$X/final/final.diff`; built by `$X/bin/build.sh v4`) is v3 with the folds of
§1: the hook takes `ConversionTarget::diagnose` and, when it is false, decides
from the types alone, emits nothing and builds no block (§1.4); a Carbon sum
value converts only to the C++ class whose sum type it is (§1.5); a
template-dependent side is left to the deferred conversion (§1.10); the
one-step conversion between a C++ `std::optional<T>` and `Core.Optional(T')`
in both directions (§1.7); the `Core.Optional` view admitted for concrete
choice-payload types only, with a diagnostic for the rest (§1.7);
`std::optional<std::monostate>` (§1.2); the `NoReason` diagnostic (§1.11);
D-SV-8 narrowed to `Core.Optional(T*)` by name (§1.8); D-SV-9 routed through
`FileContext::GetConstant`'s cached global (§1.9); C++ types printed without
their tag keyword; and the eight diagnostic kinds emitted for real (§0.0).
Measured on v4:

-   **Both reviews' probes** (`$X/runs/repro-v3.txt` on a v3 rebuilt from
    `$P/proto/v3.diff`, `$X/runs/repro-v4.txt` on v4): every finding of review A
    and review B reproduces on the v3 rebuild, and on v4: the seven `overload
    fn` probes that crashed with ``Built invalid semantics IR: No terminator in
    block`` (A: a1, a1b, a1c; B: r02, r03, r05, r06) print 7, 3, 7, 7, 7, 4 and
    7, and the three that failed with a spurious error (A: a2; B: r01, r04)
    select the member that accepts the argument (2, 2, 1); the three
    converting-constructor probes that stopped at `control_flow.cpp:61` (a7,
    a10, a11) give the reverse mismatch error; the `Core.Optional` view probes
    (a3, a4, a5) give `CoreOptionalNotMatchable`; review A's f1, f1b and f2 and
    its e6 and f3 give trunk's diagnostics again (D-SV-8); e4
    (`std::optional<std::monostate>`) prints 1 1; every probe that ran on v3
    runs on v4 with the same output.
-   **The fixer's probes** (`$X/probes/x/`, `$X/runs/x-v4.txt`): x01, `let a:
    Core.Optional(i32) = Cpp.MaybeSeven();` and its empty twin, prints 7 -1
    (trunk: m20's two errors); x03, a `Core.Optional(i32)` passed to C++ by
    value and by `const&` and `.None()`, prints 3 103 -1 (trunk: t04's
    errors); x02 and x04 give the forward and reverse mismatch errors; x05 the
    reverse mismatch for a class with a converting constructor; x06, the
    nullable `Core.Optional(i32*)` passed to a C++ `int*`, prints 5 -1 on
    trunk and v4; x07 gives trunk's error on both; x08, `if (let .Some(p:
    i32*) = Cpp.Find(1))` on a nullable C++ pointer, prints 5 -1; x09
    (`std::optional<std::monostate>` both ways) prints 1 0 1 0; x10, a tuple
    scrutinee holding a C++ optional, gives the existing scrutinee TODO; x11,
    an impl whose function returns the C++ class where the interface returns
    the sum type, prints 7; x12 and x13 give `CoreOptionalNotMatchable`; x14
    the existing `ref` binding error; x16 the conditional-operand TODO of
    W-122; x17 is the w12 cascade of §1.10; x18 the file-scope TODO.
-   **Programs** (`$X/runs/progs-v4b.txt`): the arbiter prints 7, exit 0; the
    five differential programs are DIFF-PASS at 11, 14, 7, 16 and 4 lines
    (match_core_optional_diff with `Core.Optional(i64)` in place of rev 1's
    generic `CountSome[T]`, cpp_sum_type_roundtrip_diff with two
    `Core.Optional` argument lines and a computed `half`, Appendix A).
-   **Gate** (`$X/runs/gate-v4-final.log`): file_test over trunk's 1942 files
    and the eight new goldens of §1.12, with fail_catching.carbon's new split:
    1946 of 1950 pass; the four failures are the function-pointer goldens of
    rev 1, whose 34 differing lines are all `clang_function_pointer_type<N>`;
    refilled by autoupdate, 1950 of 1950 pass (`gate-v4-final2.log`).
-   **Goldens**: the eight new goldens and the new fail_catching.carbon split
    autoupdate to a fixpoint in three passes (`$X/runs/autoupdate-v4-*.log`:
    the first writes eight files, the second renumbers fail_sum_types.carbon's
    `[[@LINE+N]]` offsets, the third writes nothing); the CHECK-stripped
    sources of Appendix B refill to byte-identical goldens.
-   **Conformance** (`$X/runs/conf-v4.log`): the full suite with the
    programs of §1.13 (`/dev/shm/sv1-fixer/confwt`): 134 PASS / 0 FAIL / 21
    SKIP over 155, bullets 48 of 56 PASS, as predicted (§5).
-   **Mutants** (`$X/bin/mutant.sh`): M12, the `diagnose` test removed, stops
    file_test at ``FATAL failure at toolchain/check/context.cpp:86: Built
    invalid semantics IR: No terminator in block`` on sum_type_overload.carbon;
    M13, the reverse rule removed, turns fail_sum_types.carbon red (its two
    `fail_reverse_` splits compile, the conversion reaching C++'s converting
    constructor) (`$X/runs/mut-m12.log`, `mut-m13.log`).
-   **Compositions** (§0.7, §8.6): tpv4 passes 1959 of 1963 (the four
    function-pointer refills only), op2v4 1951 of 1958 (those four and three
    of SV-1's goldens, §0.7).

**Rev 1 (v1 to v3).** v1 (first drafted 2026-10-15 at
`sv1/planner/proto/diff/v1.diff`, rebuilt
and re-measured for rev 1), **v2** (v1 plus §1.11's diagnostic
reasons, the W-036 text and the mismatch check; `$P/proto/v2.diff`) and **v3**
(v2 plus the `Core.Optional` match view of §1.7; `$P/proto/v3.diff` against
5674fe88b, its filled goldens `$P/proto/goldens-v3/`) implement rev 1's §2
except the X-macro diagnostics. Each was relinked over the trunk build and
measured:

-   **Probes**, `$P/runs/audit-v3.txt` (v1, v2: `audit-v1.txt`,
    `audit-v2.txt`, identical statuses on the probes they share): every IN
    shape compiles and runs with the C++-derived output:
    the arbiter body without `default` (7); `.None`-first and `.Some`-first
    matches; `let`, `var`, `if`-`let`, `while`-`let` and `let`-`else`
    scrutinees (`d01`, `d02`, `a07`, `w10`: 7, 7, 7, then 3 2 1 0);
    `std::variant<int, double>` (12, -50), `<monostate, int>` with
    `.Alt0(_: ())` (6, 0), `<int, int>` (205, 107), one alternative (8), eight
    alternatives (8), `<bool, long, double, int*>` (1 40 2 -3), a C++ enum,
    `bool`, `char`, `unsigned short` and `float` payloads (2 1 65535);
    `std::optional<int*>` with an engaged null pointer distinct from `None`
    (42 0 -1); a `const std::optional<int>&` return (9); a pointer to a C++
    optional dereferenced as a scrutinee (11, then -1 after `p->reset()`); a
    generic Carbon function over `StdOptional(T)` (7 -5); `as` in both
    directions and through `Core.Optional(i32)` (7 7 7); the reverse
    direction into C++ by value, by `const&`, from constants and from
    `StdVariant2((), i32)` (41 42 -1; 25 9 107; -1 6); a Carbon function with a
    C++ `std::optional` return or parameter called from C++ (41 -1; 41); a
    library returning `StdOptional(i32)` matched in its importer (7).
-   **OUT shapes**: each produced one error and no crash on the probes rev 1
    ran; the two reviews found the crashes rev 1's probes missed (`overload
    fn` sets; C++ converting constructors), which v4 fixes (amended
    2026-10-20, review fold: A-B1 / B-B-1 / A-B2).
-   **Conformance programs**: rev 1's six programs agreed byte for byte with
    their C++ oracles on v3 (`$P/runs/progs-v3.txt`: DIFF-PASS 11, 14, 14 and
    4 lines; the arbiter prints 7, exit 0). The log has no line for
    match_core_optional_diff; review A reproduced it (DIFF-PASS, 7 lines),
    and v4 runs it (amended 2026-10-20, review fold: A-m7).
-   **Gate**: file_test over the worktree, `$P/runs/gate-v3.txt` (and v1,
    v2): 1938 of 1942 pass. The four failures are
    interop/cpp/function/import/{carbon_fn_as_callable, decayed_param,
    function_ptr, method_ptr}.carbon, and all 34 differing lines are the
    printed id of one `cpp_fn_ptr_type` (`clang_function_pointer_type<N>`).
    Attribution, measured: trunk's own file_test with v1's prelude fails the
    same four, and v1's file_test with trunk's prelude passes them, so the
    cause is the new prelude file, not the C++ change (the store's id tag is
    derived from the file's check-IR index, which counts the prelude's
    libraries). They are refilled by autoupdate in the commit that adds the
    file (§3), never by hand.
-   **Prelude cost**: check phase of a trivial file, 60 alternating runs each
    (`$P/bin/ptime.py`): trunk min 213 ms / p10 223 ms; with this plan's
    prelude file (nine choices, two bridge impls) 221 / 235 ms (+5% at p10);
    with the access-interface alternative of §7.2 R-B at four arities 224 /
    246 ms, at eight 252 / 270 ms (+21%). The full gate's wall time is
    unchanged (31.47 s against trunk's 31.42 s), because file_test mostly uses
    the min prelude, so the gate cannot see the prelude's cost; R-2's
    falsifier is therefore the trivial-file check time of the full prelude
    (amended 2026-10-20, review fold: A-m7). The rev-2 prelude file is rev 1's
    (`core/prelude/types/cpp/sum.carbon` is byte-identical to rev 1's), so the
    measurement stands.
-   **The access-witness alternative** (§7.2 R-B), measured in user code on
    trunk with no toolchain change (`$P/../planner/proto/u01_user_conv.carbon`,
    a user `choice` plus an interface implemented for `Cpp.std.optional(i32)`
    through `has_value()`/`value()` and a blanket `ImplicitAs`): the C++ to
    Carbon direction runs (7 -1 8); the reverse (`u02`) cannot pass the
    choice to a C++ parameter (`no matching function for call to 'TakeOpt'`),
    because C++ overload resolution never sees Carbon `ImplicitAs` impls.

### §0.7 Collisions with the held PRs

Regenerated 2026-10-20 (review fold: A-m1 / B-M-4) from `git diff --numstat
$(git merge-base 5674fe88b <branch>) <branch>` over every file SV-1 changes,
kind.def, check/BUILD, the four function-pointer goldens, fail_catching.carbon,
optional.carbon and the three docs pages SV-1 edits (`$X/runs/` has the
commands' output). Held PRs, none merged, merge order of record
(fork/ORCHESTRATION.md on trunk 254b935b2): PR 53, PR 51, PR 52, PR 60 (SC-1),
PR 54, PR 55, PR 56 (OP-1), PR 57 (OP-2), PR 58 (DD-1) through its state L
integration commit, PR 59 (VA-1), PR 61 (TP-1) through its land-time commits,
then SV-1. "Owner at M" is who resolves a textual conflict at SV-1's merge of
trunk: SV-1 always, since every PR lands first, by the rule in the last column.

| PR, branch head | Files shared with SV-1 (numstat) | Nature | Rule at M (owner: SV-1) |
| --- | --- | --- | --- |
| PR 56, OP-1, 379f20f67 | core/prelude/types/optional.carbon (+73/-2); docs/design/optional.md (+582, new) | SV-1 does not edit optional.carbon; sum.carbon imports it and calls `Optional(T).Some`, `.None()`, `HasValue()`, `Get()` only. optional.md is new on PR 56, and SV-1 amends it after M (Doc-M, §3) | none textual; optional.md takes PR 57's text, and Doc-M edits it by Appendix C's anchored edits |
| PR 57, OP-2, 628273444 (build `/home/user/carbon-build/carbon-op2`, toolchain-identical to the head) | optional.carbon (+111/-8); docs/design/optional.md (+614); convert.cpp (+5/-2, the `MaybeUnformed` value-representation check at :1690-1700); function/import/decayed_param.carbon (+13/-85), pointer.carbon and void_pointer.carbon (not SV-1's) | the bridge calls `Get()` only after `HasValue()`; D-SV-8's name test and walk reach `T*` through OP-2's `MaybeUnformed(T*)` (op2v4, as v4: `$P/probes/v1/s05_ptr` prints 42 0 -1, `d04_carbon_optptr` 3, and `$P/probes/o/o04_bridge_stdoptional` 5 6 -1 9); OP-2's convert.cpp hunk is 100 lines above SV-1's hook (the dry run applies it at offset 3) | measured on op2v4 (§0.6): 1951 of 1958 pass; the seven failures are the four function-pointer refills and three of SV-1's goldens, stdlib/optional.carbon, choice/optional_pointer_payload.carbon and match/core_optional_view.carbon, whose SemIR gains OP-2's `%Destroy.lookup_impl_witness` / `%Destroy.facet` entries and reorders imports (12, 387 and 18 changed lines, no diagnostic line changed); F-M refills the seven (§3) |
| PR 60, SC-1, 40a76ab81 | convert.cpp (+94/-7); type.cpp (+8, a new function); toolchain/diagnostics/kind.def (+13); toolchain/check/BUILD (+2) | SV-1's convert.cpp hunk applies at offset 14, its type.cpp hunks at offset 8; kind.def: SC-1's 13 kinds are a separate hunk from SV-1's 8 after `CppExportResultNeedsExpectedHeader`; BUILD: SV-1's two lines apply at offset 1 beside SC-1's `structural_conformance.{cpp,h}` | dry run applies (`$X/runs/dry-sc.log`); the mirror of §8.6 |
| PR 59, VA-1, b0822a744 (build `/home/user/carbon-build/carbon-va`, toolchain-identical to the head) | convert.cpp (+114, a pack-conversion block 11 lines above SV-1's hook); type.cpp (+5); kind.def (+19, its hunk about 15 lines above SV-1's) | textually separate hunks; semantic as well (amended 2026-10-20, review fold: RR-M1): VA-1 converts a pack element in one straight-line block run once per element, an expansion body or `ConvertPackToPack`, and CHECKs that the element conversion made no control flow (convert.cpp:581-583 on the head, ``Control flow in a pack element conversion``), so a sum-type conversion of a pack element stops the compiler (the focused re-review's v02 and v04 on vav4) | dry run applies (convert.cpp at offsets 98 and 114, type.cpp at 5, kind.def at 15; `$Z/runs/dry-va.log`); at M, the land-time hunk M-VA of §3 item 8: the hook refuses a `SemIR::PackElement` value, or what a tuple, struct, array, class or adapter conversion projects from one, with a TODO (W-284), measured on vav6g (§0.6; rev 3's hunk refused only a bare `PackElement`, and a pack of tuples, structs, arrays or classes holding a sum type still stopped at the CHECK, n01 to n05; amended 2026-10-20, review fold: RR3-B1) |
| PR 61, TP-1, e408ad4d6 (build `/home/user/carbon-build/carbon-tp`, stamp 813804758); round-10 head eafca5cb9, pushed with its fill 74e16c4de and records 3d88e6a60 before rev 4's commit, which said not yet pushed; pushed head at rev 5 281292d8f, records only past 74e16c4de, so its toolchain/ and core/ are eafca5cb9's (amended 2026-10-20, review fold: RR3-m3; RR4-m3) | convert.cpp (+560/-29); kind.def (+1); on eafca5cb9 also refutable_binding.cpp (+18/-5) and refutable_binding.h (+17, not SV-1's) and handle_match.cpp (+2/-5, not SV-1's) | semantic as well as textual (amended 2026-10-20, review fold: A-M1): TP-1 defers a conversion whose type is template-dependent and performs it at instantiation (`PerformAction`), outside any function body, so SV-1's hook leaves a template-dependent side to TP-1 and the instantiation-time conversion is W-279's TODO (§1.10); measured on tpv4: 1959 of 1963 pass (the four function-pointer refills only); h2 and h3 give W-279's TODO at instantiation; h1, a `match` on `StdOptional(T)` for a template `T`, stops at TP-1's own pattern_match.cpp:1409 CHECK, which TP-1's head reaches with no C++ at all (x19, a pure-Carbon generic choice: TP-1's toolchain stops, trunk gives W-252's TODO), finding X-1 of the fold record, routed to TP-1; on the round-10 head X-1 is fixed (x19 compiles and prints 0, and h1 gets W-279's TODO at instantiation for its `let`'s conversion; measured on tpv6, which passes 1961 of 1965, the four function-pointer refills only, at rev 5 over 281292d8f's tree as well) | dry run applies, the include hunk with fuzz 1 and the hook at offset 378 (`$X/runs/dry-tp.log`); on 74e16c4de (eafca5cb9's fill) convert.cpp's include hunk and refutable_binding.cpp's first hunk need fuzz 1, and convert.cpp's other hunks apply at offsets 2 to 378 (`$W/runs/dry-summary.txt`), and the same on 281292d8f (`$Y/runs/patch-tpv6.log`); at M, the row is re-measured against PR 61's head of that day (§8 item 6) |
| OX-1, parked (no PR) | none: SV-1 does not touch cpp/export.cpp or cpp/thunk.cpp | SV-1 exports nothing: the conversion calls existing C++ functions through the existing call path, and the reverse mapping of §1.5 names a specialization of an existing C++ class template as the invented argument type of one overload resolution, declaring no name in any C++ scope; a `Core.CppCompat` choice in an exported signature stays the existing export TODO (`s16`, W-049) | none |
| PR 58, DD-1, fcee90d9b | none of SV-1's files; adds fork/designdocs/check_samples.py, whose W2 rule covers docs/design/ | SV-1's sum_types.md, unions.md and optional.md edits are subject to it after M | §8 item 11 runs it after M and after Doc-M (amended 2026-10-20, review fold: B-M-4) |
| PR 51, 52, 53, 54, 55 | none in check, lower, core, kind.def or BUILD (PR 55 touches cpp/export.cpp, which SV-1 does not) | none | none |

**Measured now (2026-10-20, amended 2026-10-20, review fold: A-m1 / B-M-4).**
Rev 1's dry run used the prototype's diff, which had neither the kind.def nor
the BUILD hunks. Rev 2 dry-runs the complete final diff, `$X/final/final.diff`
(toolchain, core, kind.def at its final position, BUILD, and the
fail_catching.carbon split), with `patch -p1 --dry-run` onto a fresh `git
archive` of each head: it applies to PR 56, PR 57, PR 60, PR 59 and PR 61 with
no rejected hunk (`$X/runs/dry-summary.txt` and `dry-<b>.log`). The
compositions with the two PRs that change behavior SV-1 depends on, PR 57 and
PR 61, were built and gated (op2v4, tpv4, §0.6); the composition mirrors of the
other heads are the implementer's (§8.6).

**Measured at rev 3 (2026-10-20, amended 2026-10-20, review fold: RR-B1 /
RR-M1).** Rev 2 dry-ran the diff only; the focused re-review relinked PR 59
with it and found the semantic collision above. Rev 3 re-dry-runs
`$Z/final/final.diff` on trunk 5674fe88b and the five heads: it applies with
no rejected hunk, the new `ConvertAggregateElement` hunks at offset 1 on PR 60,
98 on PR 59 and 2 to 230 on PR 61 (`$Z/runs/dry-summary.txt`), and every
head's convert.cpp has the same four callers of `ConvertAggregateElement`
(none added), so the signature change compiles on each. Every head that a
relink can reach was then composed and gated (§0.6, tpv5, op2v5, scv5,
vav5g), so the semantic collisions are measured, not predicted; the full-build
mirrors of §8.6 repeat them on the full build.

**Measured at rev 4 (2026-10-20, amended 2026-10-20, review fold: RR3-B1 /
RR3-M1 / RR3-m3).** `$W/final/final.diff` differs from rev 3's in sum_type.h and
sum_type.cpp only (convert.cpp is rev 3's), so its dry runs are rev 3's; it
applies to trunk 5674fe88b and to PR 59's head with no rejected hunk, and to
TP-1's round-10 fill 74e16c4de with refutable_binding.cpp's first hunk at fuzz 1
(`$W/runs/dry-summary.txt`). The relinked compositions tpv6, op2v6, scv6 and
vav6g are gated in §0.6.

**Measured at rev 5 (2026-10-20, amended 2026-10-20, review fold: RR4-M1 /
RR4-m3).** The toolchain diff is rev 4's; the compositions are rebuilt and gated
with the extended fail_sum_types.carbon (§0.6), PR 61's at its pushed head
281292d8f, whose toolchain/ and core/ equal 74e16c4de's (3d88e6a60 and 281292d8f
add records only), with every hunk applying as on 74e16c4de.

Records shared with every held PR: fork/gap-analysis.md,
fork/inventory/work-items.json, fork/decision-log.md, fork/ORCHESTRATION.md and
fork/conformance/README.md (its generated program table). SV-1 edits them only
in its records commits R and D (§3), after the merge of trunk M, so they take
the merged trunk's text and SV-1 appends its blocks after the PRs' blocks; the
README table is regenerated by `runner.py --update-readme-table`.

### §0.8 Conformance today under row 68, and the differential harness

The bullet "Control flow: matching — sum-type consumption incl.
std::variant/std::optional interop" has six programs: five PASS
(control_flow/choice_payload_roundtrip_diff, choice_generic_roundtrip_diff,
match_payload_literal, match_single_alternative, match_global_runtime_let)
and one SKIP (control_flow/match_sum_type_payload, §0.1). The runner rolls a
bullet up as PASS when every non-SKIP program passes, so the bullet already
reads PASS (48/56 bullets of record); the SKIP is the missing interop half.
Two of the PASS programs are differential (`<name>.diff.cpp` beside
`<name>.carbon`): the C++ side builds with the toolchain's own
`clang++ -std=c++17 -pthread` (fork/conformance/runner.py:43-52, :431-445) and
must
print the same stdout with the same exit code (DIFF-1: C++ oracle only, no
EXPECT-STDOUT; a C++-side failure reports as DIFF-MISMATCH). A multi-unit
program is a directory with `main.carbon`, its library units and an optional
`main.diff.cpp` (runner.py:293-372). Totals of record: 128 PASS / 0 FAIL /
22 SKIP over 150 (trunk scoreboard, the gap-analysis header).

### §0.9 Upstream direction (V-3a)

-   **Toolchain.** `git log 0bdce60a5..upstream/trunk -- toolchain/check/cpp`:
    13 of upstream's 85 commits since the cut touch it (`-> auto` returns,
    `IndirectIndexWith.Ref`, export namespace and name-leak fixes, a
    `ParameterizedClassType` rename, `Core.Array`); none mentions optional or
    variant, and `git grep -n 'optional\|variant'` of upstream's
    custom_type_mapping.cpp finds nothing. Upstream has no `match` at all
    (the nightly's `HandleMatchIntroducer` TODO, §0.2).
-   **Design.** Upstream's docs/design/sum_types.md has no interop section; its
    "User-defined sum types" section (fork copy :91-246) specifies the `Match`
    interface through which a class becomes matchable: the long-term route
    for a class such as `Core.Optional` or a C++ class to be matched
    directly. Nothing implements it in the fork or upstream.
-   **Proposals.** p0157 (design direction for sum types), "Indexing by type":
    "we don't yet have enough of a design for variadics to give an example of
    a Carbon counterpart for `std::variant<Ts...>`, but a variant with exactly
    three alternative types could be written like so: `choice Variant(T1, T2,
    T3) { Value(T1: value), ... }`": upstream's own sketch of the counterpart
    is a per-arity generic choice. Its overloaded alternative name `Value`
    cannot be used: the fork rejects duplicate alternative names
    (check/testdata/choice/fail_duplicate_alternative.carbon), and
    `std::variant<int, int>` defeats any naming by type. p0157 also weighs
    "pattern matching proxies" (a type converts to a `choice` for matching)
    against continuation-passing for user-defined sum types, and picks the
    latter for that purpose; SV-1 does not define a user-defined sum-type
    mechanism, it maps foreign C++ types at the boundary, where the layout
    forces a copy anyway (§0.5). p2188 (pattern matching syntax and
    semantics) uses `std::variant` only in C++ comparison examples.
-   **Verdict.** No accepted upstream direction contradicts the mapping; the
    two points of contact are recorded as F-020's break conditions (§1.1).

## §1 Design

Every decision below is auto-adopted under R29(a) and V-2/V-3, recorded in
the decision log at discharge for after-the-fact veto, and carries a
one-sentence break condition (D-SV-10 and D-SV-14 gained theirs at rev 2,
amended 2026-10-20, review fold: B-m-6). F-020 is the one fork design decision;
the D-SV decisions implement it.

### §1.1 F-020 (D-SV-1): the mapping targets

**Decision.** A C++ `std::optional<T>` or `std::variant<T0, ..., Tn-1>`
specialization stays imported as the C++ class it is today. When it is
admitted (§1.3), it has a **Carbon sum type**, a specific of a generic
`choice` declared in the prelude (core/prelude/types/cpp/sum.carbon,
namespace `Core.CppCompat`):

<!-- google-doc-style-ignore -->

```carbon
choice CppCompat.StdOptional(T: type) {
  Some(value: T),
  None
}

choice CppCompat.StdVariant2(T0: type, T1: type) {
  Alt0(value: T0),
  Alt1(value: T1)
}
// ... StdVariant1 to StdVariant8, alternatives Alt0 to Alt<n-1>.
```

<!-- google-doc-style-resume -->

`std::optional<T>` has the sum type `StdOptional(T')` and
`std::variant<T0, ..., Tn-1>`, for 1 <= n <= 8, has `StdVariant<n>(T0', ...,
Tn-1')`, where `A'` is the Carbon type the existing C++ import gives `A`,
except that `std::monostate` maps to `()`. The C++ class and its sum type
convert into each other implicitly and by value at the boundary (§1.4, §1.5),
and a refutable-pattern scrutinee of the C++ class converts to its sum type
(§1.6). `StdOptional(T)` is the docs/design/sum_types.md `Optional(T)`
declaration (sum_types.md:63-66; unions.md:617-620), names and order
unchanged. For `std::optional<T>` with a non-pointer payload, the C++ class
also converts in one implicit step to and from `Core.Optional(T')`, through
the sum type and the prelude's `ImplicitAs` bridge; and a `Core.Optional(T)`
scrutinee whose payload is a concrete choice payload type is matched as its
`StdOptional(T)` view (§1.7) (amended 2026-10-20, review fold: B-M-5 / A-M4 /
A-M2 / B-M-1).

**What a user sees** (added 2026-10-20, review fold: B-M-2 / A-M4 / B-m-10).
"Transparent", W-011's word, holds for consumption and for the boundary, not
for every use:

-   matching a C++ `std::optional` or `std::variant` value spells only the
    alternatives (`.Some(n: i32)`, `.None`, `.Alt0(x: f64)`), never a type;
-   a C++ `std::optional<T>` value initializes, returns to or is passed as a
    `Core.Optional(T')`, and a `Core.Optional(T')` is passed where C++ takes
    `std::optional<T>`, with no spelling (x01, x03), but for a C++ `T&&`
    parameter, which takes a fresh value only through a `const T&` overload, by
    passing a value (W-285, §1.5; amended 2026-10-20, review fold: RR4-M1);
-   a Carbon value that becomes a C++ `std::variant`, and a Carbon library API
    that traffics in a variant without naming the C++ class, spell
    `Core.CppCompat.StdVariant<n>(...)`; `StdOptional(T)` is spelled only where
    a user wants the choice itself rather than `Core.Optional(T)`;
-   diagnostics name the sum type: exhaustiveness (`` `match` on choice
    `Core.CppCompat.StdVariant2(i32, ())` ... does not cover alternative
    `.Alt1` ``) and unknown alternatives, also on a `Core.Optional` scrutinee,
    whose view is `Core.CppCompat.StdOptional(T)`;
-   the scrutinee is a converted copy, so a `ref` payload binding is rejected
    (W-280, §1.6), and a C++ sum class nested in a tuple or struct scrutinee is
    not converted (W-281);
-   deduction does not see through the conversion (§1.10).

**Why this is a fork design decision (F), not a consequence of recorded
ones.** fork/w5-choice/plan.md:500-503 said `std::optional<T>` maps to
`Core.Optional(T)`. Since then D-EH-1 kept `Core.Optional` a class, PR 56 and
PR 57 redesign it as a class, and a class cannot be matched (§0.4), so that
target cannot satisfy W-011's arbiter. F-020 changes the target to a choice and
relates it to `Core.Optional` by conversion; and it answers SF-8, which the
user deferred to this slice with a steer.

**The steer, item by item** (fork/decision-log.md:465-469; rewritten
2026-10-20, review fold: A-M4 / B-m-10). F-020 **departs from SF-8's default
lean**, and says so for the owner's veto:

-   "tagged unions are the first-class construct (`choice`)": both targets
    are `choice` types; nothing new is introduced beside `choice`.
-   "any Core.Variant prelude name would be sugar over a generic choice at
    most": `StdVariant1` to `StdVariant8` are generic choices themselves, not
    sugar, with no members, no impls of their own and no API, in `CppCompat`
    (beside `Long32`, `ULong64` and `Exception`), named for the C++ type they
    mirror.
-   "the default lean is the anonymous/synthesized-choice mapping": F-020 is
    NOT that lean. The toolchain synthesizes the specific, so no user declares
    anything to match a C++ value, but the generic choices are prelude names a
    user can spell, and a variant built in Carbon or passed through a Carbon
    library API must spell one: in substance this is SF-8's option (b), a
    prelude vocabulary type, with option (a)'s "the toolchain picks the type"
    for matching. For `std::optional` the departure is smaller, since the
    one-step conversions of §1.7 let user code use `Core.Optional(T)` and never
    spell `StdOptional(T)`.
-   "introducing a Variant vocabulary type requires affirmative
    justification": the justification, measured: (1) no choice can exist
    without a source declaration (handle_choice.cpp:84 is the only place
    `is_choice` is set), so an anonymous synthesized choice would duplicate
    handle_choice.cpp's alternatives table, F-007k layout, alternative
    constants and factories, and `Copy`/`Destroy` witnesses outside the parse
    tree; (2) a specific is one canonical type in every file and library, so a
    value returned by one library is matched in another (`xlib`, §0.4 item 1,
    and the multi-unit program of §1.13), where per-file synthesized entities
    would need a cross-file identity rule, and an anonymous type could not
    appear in a Carbon library's signature at all; (3) upstream's own sketch
    of the Carbon counterpart of `std::variant` is a per-arity generic choice
    (p0157, §0.9); (4) the names are the interop namespace's, not a Carbon
    variant type: a Carbon program with no C++ has no reason to declare a
    `StdVariant2`, and none of them is the design's answer to "a Carbon
    variant type".
-   **SF-9's cost.** `StdOptional(T)` is a second Optional beside the class
    `Core.Optional(T)`: SF-9's option (b), "Coexist -- costs two Optionals",
    whose cost F-020 adopts. It is bounded by the one-step conversions and the
    view of §1.7, so a user who has a `Core.Optional` never needs the second.
-   **Cost to programs without C++** (added 2026-10-20, review fold: A-M4):
    every full-prelude compile checks sum.carbon, +5% check time at p10 on a
    trivial file (§0.6). Loading it only for a file that imports `Cpp` was
    considered and rejected (§7.2 R-L).

**Alternatives considered** (§7.2 has the evidence for each):

-   (a) A synthesized choice per specialization that is the imported type
    (the C++ class replaced, as `std::span` is replaced by `Core.Slice`):
    rejected, because the layouts differ (§0.5), so the replacement would need
    a conversion thunk at every C++ signature that mentions the type and
    could not represent `std::optional<int>*` or `const std::optional<int>&`
    at all (a pointer to a C++ object is not a pointer to a choice);
    measured, keeping the class keeps `s20` (a `const&` return), `w09` (a
    pointer to a C++ optional, `p->reset()`) and every member call of §0.2
    working.
-   (a') An anonymous synthesized choice entity per specialization, the
    steer's default lean (SF-8 (a)): rejected for reasons (1) and (2) above
    (§7.2 R-C).
-   (b) `Core.Optional(T)` itself as the target, with a consumption path for
    a non-choice: the design's path for matching a class is the `Match`
    interface (sum_types.md:91-246), which neither the fork nor upstream
    implements; rejected for 0.1. F-020 gets part of the effect with the
    one-step conversions and the view of §1.7, without the `Match` machinery.
-   (c) `std::variant` deferred (SF-8 option (c)): rejected, the milestone
    bullet names both types and the prototype maps both.
-   (d) Make `Core.Optional` a choice: rejected; it contradicts D-EH-1 and
    the held PR 56 and PR 57, loses the pointer niche that
    `Core.Optional(T*)`'s C++ mapping and the entry point's
    `argv: Core.Optional(char*)*` rely on, and is W-058's to decide (§7.2 R-E).
-   (e) An access interface whose witness the toolchain synthesizes, with
    the conversions as blanket prelude impls (the `CppContiguousRange`
    shape): rejected, measured in §0.6 and §7.2 R-B.

**F-015 amendment** (added 2026-10-20, review fold: A-M4 / B-M-3). F-015 (OP-1,
on PR 56) is the `Core.Optional` design; its page, docs/design/optional.md on
PR 57, says "If that mapping targets `Core.Optional(T)`, this design is amended
first" (:475-478 at 628273444). F-020's one-step conversions and view do relate
the mapping to `Core.Optional(T)`, so SV-1 amends F-015 in the same PR: a dated
amendment in the decision log and anchored edits of optional.md, both written
out in Appendix C and committed at Doc-M (§3), after M brings the page in and
before R and D.

**Break condition.** If the owner vetoes nameable `CppCompat` sum types (the
steer's default lean), the nine choices move to a namespace user code cannot
name, the conversions and matching keep working, and Carbon-side construction
of a variant and Carbon library APIs in variants take the C++ class; if Carbon
gains variadic `choice` declarations, the nine generics collapse into
`StdOptional` and one variadic `StdVariant(... each T)` keeping the `Alt<i>`
names; if the `Match` interface is implemented, the C++ classes and
`Core.Optional` implement it and the scrutinee conversion and the view are
retired; if W-058's approved design makes `Core.Optional` a choice,
`StdOptional` becomes an alias of it and the bridge of §1.7 is deleted; if
upstream lands its own `std::optional`/`std::variant` mapping, F-020 is
re-decided against it.

### §1.2 D-SV-2: alternative names, `std::monostate`, duplicates, arity, nesting

-   **Names by index.** Alternative `i` of a `std::variant` is `.Alt<i>`,
    whose one payload binding is named `value` in the declaration (any name
    in a pattern). Rejected: `.0(x)` (SF-8 option (a)'s spelling) does not
    parse (`m17`: ``expected identifier or `Self` after `.` ``); names derived
    from the alternative's type are not identifiers for most types and
    collide for `std::variant<int, int>`; p0157's overloaded `Value` is a
    duplicate alternative name, which the fork rejects.
-   **`std::monostate`** maps to the payload `()` (D-EH-2 admits it), so the
    pattern is `.Alt0(_: ())` and the value is `StdVariant2((), i32).Alt0(())`
    (measured `w01`: 6, 0; the reverse in the roundtrip program). Rejected: a
    payload-free alternative for it, because one generic declaration cannot
    give an alternative a parameter list in some specifics and not others.
-   **`std::optional<std::monostate>`** (added 2026-10-20, review fold: A-m3)
    maps to `StdOptional(())`, and its `Some` carries `()` in both directions:
    the pattern is `.Some(_: ())` and the value
    `StdOptional(()).Some(())`. Rev 1 treated `std::monostate` as `()` only
    for a variant alternative, so this optional failed with two errors (review
    A's e4 on v3: ``cannot implicitly convert expression of type `const
    Cpp.std._C.monostate` to `()` `` and ``no matching function for call to
    'emplace'``); v4 prints 1 1 for e4 and 1 0 1 0 for `$X/probes/x/x09`, and
    the `monostate_payload` split of stdlib/optional.carbon pins it.
-   **Duplicate alternative types** are told apart by index (measured `s04`,
    `std::variant<int, int>` at index 1 and 0: 205, 107; the reverse in the
    roundtrip program: 107, 3).
-   **Arity** 1 to 8. A `std::variant` with more than eight alternatives is
    diagnosed (§1.11) and filed (W-276). The bound is the prelude's cost: nine
    generic choices cost 5% of a trivial file's check time (§0.6), and the
    cost grows with each declaration.
-   **Nesting.** A nested sum type by value, `std::variant<std::optional<int>,
    int>` or `std::optional<std::variant<int, double>>`, has a class-typed
    alternative, which the payload rule does not admit (§1.3; measured
    `w06`, `w07`); it is diagnosed and filed (W-275). By pointer it works:
    `std::variant<std::optional<int>*, int>` maps the first alternative to the
    nullable pointer `Core.Optional(Cpp.std.optional(i32)*)` and the inner
    optional is matched again through the pointer (measured `s13`: 5, -4).

_Break condition:_ a variadic `choice` lifts the arity bound (with F-020's);
admitting aggregate payloads (W-010's SF-6 residue) admits nesting by value,
with the inner sum type mapped recursively.

### §1.3 D-SV-3: the admitted payload rule

A specialization is **admitted**, and has a sum type, exactly when:

1.  its C++ class is complete, trivially copyable and trivially destructible
    (clang's `isTriviallyCopyable()` and `hasTrivialDestructor()`). Reason
    (rewritten 2026-10-20, review fold: A-m7 / B-m-2): the reverse conversion
    builds a C++ object in Carbon storage that no destructor call ends, and the
    scrutinee gate does destroy the C++ temporary it converted
    (`AddAndDiscardTemporaryCleanups`, control_flow.h:95-97, emits the destroys
    before the arms run), a destroy that must do nothing. For libc++'s own
    classes the rule is implied by rule 4 (an admitted payload is trivially
    copyable and destructible, and libc++ propagates both); it fires for other
    implementations of the classes, such as the goldens' mock;
2.  a `std::variant` has 1 to 8 alternatives;
3.  no alternative type is cv-qualified or a reference type. Reason (rewritten
    2026-10-20, review fold: A-m4 / B-m-3): the sum type of a class must map
    back to that one class, which the reverse conversion and the invented C++
    argument of §1.5 need; `std::variant<const int, double>` and
    `std::variant<int, double>` would share `StdVariant2(i32, f64)`, and a
    value of it offered to C++ as `std::variant<int, double>` does not convert
    to the other. The rule fires on real libc++ variants: libc++'s
    `std::variant<const int, double>` IS trivially copyable (review A's and
    review B's `tc.cpp`), and review A's g1 on it gives `CppSumTypeNotMapped`
    with the `CppSumTypeQualifiedAlternative` note on v4; libc++'s
    `std::optional<const int>` is not trivially copyable, so rule 1 rejects it
    first. References are ill-formed alternatives of both standard templates
    in C++17, so that half of the rule fires only for a non-standard class;
    and
4.  every alternative type is `std::monostate`, or imports as a Carbon type
    that SF-6's payload predicate admits: an integer, floating-point, `bool`
    or pointer type after adapters, which takes in C++ enums, `char` (as
    `Core.Char`), the `CppCompat` integer adapters, non-null pointers, and,
    with D-SV-8, the nullable `Core.Optional(T*)` a plain C++ `T*` imports
    as.

Otherwise the specialization stays a C++ class with no sum type: its members
still work, and every use that needs the sum type is diagnosed with
`CppSumTypeNotMapped` and the note for the first rule it breaks (§1.11):
a `std::string` or other non-trivial payload breaks rule 1
(`s19`), so does `std::optional<const int>` (libc++ deletes its copy
assignment, `w03`); `std::variant<const int, double>` breaks rule 3 (g1); a
trivially copyable struct or a nested `std::optional`
or `std::variant` breaks rule 4 (`s06`, `a11`, `w06`, `w07`). Never a crash and
never a silent wrong value: the rule is checked before the specific is formed,
so SF-6's per-specific check (eval_inst.cpp:310-345) is never the one that
fires for a C++ class. (The `Core.Optional` view of §1.7 checks the same
predicate before it forms its specific, amended 2026-10-20, review fold: A-M2 /
B-M-1.)

SF-6 (decision log, W5 SF-1..8) allows "trivially-copyable +
trivially-destructible payloads" in 0.1, and the implementation's predicate is
narrower (no aggregates); rule 4 follows the implementation, and the gap
between the two, trivially copyable structs, is W-010's residue, recorded for
this mapping as W-275.

_Break condition:_ when SF-6's predicate admits aggregates, rule 4 admits
them with no change here; when non-trivial payloads get discriminant-
dispatched copy and destroy (SF-6's post-0.1 item), rule 1 is lifted for the
classes whose alternatives qualify, with the C++ temporary destroyed by its
real destructor; when the reverse conversion remembers the exact source class
(so two classes may share a sum type), rule 3 admits `const` alternatives as
their unqualified types (W-277).

### §1.4 D-SV-4: the conversion from C++ to Carbon

**Where.** `TryConvertCppSumType` (new, toolchain/check/cpp/sum_type.cpp) is
called from convert.cpp's `PerformBuiltinConversion` just before "Split the
qualifiers off the target type" (convert.cpp:1798), with the conversion's
target type and its `diagnose` flag (amended 2026-10-20, review fold: A-B1 /
B-B-1), so every implicit and explicit conversion, initialization, argument
and return reaches it, and from the scrutinee gate (§1.6). It owns exactly
these pairs (amended 2026-10-20, review fold: A-B2 / B-M-5): a C++
`std::optional`/`std::variant` value to a `Core.CppCompat` sum type or, for
`std::optional<T>`, to a `Core.Optional(T')` whose payload is matchable
(§1.7); and a `Core.CppCompat` sum value, or a `Core.Optional(T')` whose
payload is matchable and not a pointer, to a C++ class (§1.5). It returns
`None` for every other pair, and for a pair with a template-dependent side
(§1.10), so every other conversion is untouched. In particular a C++ sum
value converted to a `Core.Optional` whose payload is not matchable, such as
`Core.Optional(Cpp.std.optional(i32))` whose payload is the value's own class,
is left to `Core.Optional`'s own conversion from its payload (amended
2026-10-20, review fold: RR-m3; rev 2 claimed the pair and reported it as a
`CppSumTypeMismatch`, k01 to k03).

**Conversions a caller only tests** (added 2026-10-20, review fold: A-B1 /
B-B-1; rewritten 2026-10-20, review fold: RR-B1 / RR-B-1 / RR-m1 / RR-m2;
amended 2026-10-20, review fold: RR3-M1).
`ConversionTarget::diagnose` is false for a conversion whose caller tests
convertibility (convert.h:79-83: "an ErrorInst may be returned, but it must
be discarded"). The callers are the `overload fn` candidate probe
(call.cpp:549, `ProbeOverloadCandidate` :560-600, which pops its scratch block
with `PopAndDiscard` and promises to leave "no instruction, cleanup, or
generic-region state behind"), deduction's two speculative conversions and
the slice-element bound test (cpp/import.cpp:1316, types only). Deduction
keeps what it converts: deduce.cpp:345 assigns the converted argument back and
matches it against the parameter pattern, and :570 keeps it as the deduced
argument when it is a constant and fails deduction otherwise.

The rule SV-1 needs is the converse of rev 2's statement that `diagnose` is
false only for a conversion whose caller tests convertibility: every conversion
a caller only tests has `diagnose` false, the element conversions of an
aggregate included. Trunk breaks it in one place: `ConvertAggregateElement`
(convert.cpp:361-406) builds each element's `ConversionTarget` without the
aggregate conversion's flag (:393), so the elements of a tuple, struct or array
argument are converted diagnosing inside the probe. SV-1 passes the flag
through: `ConvertAggregateElement` takes `bool diagnose`, sets it at :393, and
its four callers (:486, :577, :971 and :1135) pass `target.diagnose` (§2.5). For
a non-diagnosing conversion the hook then decides from the types alone: a
mismatch or a class with no sum type returns `ErrorInst` and emits nothing, so
an `overload fn` probe skips a member whose parameter the argument does not
convert to; a convertible pair returns a stand-in of the target type built from
no C++ call and no block (`MakeTestedConversion`: a `temporary_storage` read as
a value), which the probe's scratch block discards. The stand-in is never a
constant, and neither is the branched conversion it stands for, so deduction,
which keeps a constant result and rejects any other, treats both alike; the
slice-element test reads types only, and the probe discards its block. The
committed call converts again with `diagnose` true and builds the real
conversion.

A point where the committed conversion cannot be built (below: outside a
function body, with no source expression, and from M-VA for a VA-1 pack element)
is a limit of the toolchain, not of the types, so the non-diagnosing path does
not test it (amended 2026-10-20, review fold: RR3-M1): the probe accepts the
member, and the committed call emits the limit's TODO. Rev 3 tested it in the
probe too (`CanBuildBranches` with `diagnose` false), which skipped such a
member, so the same call selected different members in different places with no
diagnostic: `P(Cpp.MaybeSeven())` called the `StdOptional(i32)` member inside a
function and the `Cpp.std.optional(i32)` member at file scope (f01: `1 2` on v5
and on mutant M20), and inside a template's instantiation the probe skipped that
member and called a generic one (t7: `1 2` on the PR 61 composition; mutant M20
on trunk's build does the same), so lifting W-036 or W-279 would have silently
changed which member those programs call. F-009's declaration-order first match
calls the first member that accepts the arguments; the argument converts to that
member's parameter, so it is the member, and the program gets the TODO (f01 on
v6: the file-scope TODO; t4 and t7 on tpv6: W-279's TODO under ``unable to
monomorphize specific``; pinned by sum_type_overload.carbon's
`fail_todo_file_scope` and `fail_todo_template_overload`). Rev 3's other aim
stays: a genuine type mismatch is skipped, never a hard error (y01,
`tuple_mismatch_first`).

Rev 1 built the branched conversion in the probe: its blocks were added to the
function's region and survived the probe's `PopAndDiscard`, which crashed seven
measured `overload fn` calls (``Built invalid semantics IR: No terminator in
block``) and made a mismatching or unmapped member a hard error instead of a
skipped candidate (§0.6; mutant M12 restores the crash). Rev 2 tested the flag,
but the flag never reached an aggregate's elements, so the same crash and the
same hard error survived for a member whose parameter is a tuple, struct or
array holding a sum type, in both directions and through deduction (the focused
re-review's p06, p15, q04 to q07 and q09; mutant M17 restores it). Rev 2 also
accepted, at file scope, a member whose conversion the committed call then
refused with the file-scope TODO (p05); rev 3 skipped that member instead
(mutant M18), and rev 4 accepts it again, by the rule above (amended 2026-10-20,
review fold: RR3-M1). Passing the flag through also changes trunk, for the
better: a scalar element mismatch inside an `overload fn` probe no longer emits
a spurious error and skips the member (t01: `P((true, false))` against `(i32,
i32)` and then `(bool, bool)` gives trunk's ``cannot implicitly convert
expression of type `bool` to `i32` `` on trunk and v4, and calls the second
member on v5 and v6); sum_type_overload.carbon's `scalar_tuple_mismatch_first`
pins it with no sum type in the path (amended 2026-10-20, review fold: RR3-m4),
and the gate shows no other golden changes (§0.6).

**What SemIR a converted value is.** The C++ value is first made a value
expression (`ConvertToValueExpr`), so the accessors run on a `const` object
and their `const&` overloads are selected; nothing is moved from. Then one
`temporary_storage` of the sum type is initialized in one of several blocks,
the shape of the catching thunk's result (thunk.cpp
`PerformCppCatchingThunkCall`):

-   `std::optional<T>`: `has_value()` is called once; if true, the block
    calls `value()` (or, for `std::optional<std::monostate>`, makes `()`) and
    initializes the storage with `StdOptional(T').Some` of it; otherwise it
    copy-initializes it from the constant `StdOptional(T').None`; both branch
    to a convergence block, where the storage is read as a value.
-   `std::variant<T0, ..., Tn-1>`: `index()` is called once; arms 0 to n-2
    test `index() == i` (through `Core.EqWith` on `index()`'s own type, `u64`
    on Linux), and the last arm is the fall-through; arm `i` calls
    `std::get<i>(v)` (or makes `()` for `std::monostate`) and initializes the
    storage with `StdVariant<n>(...).Alt<i>` of it.
-   To `Core.Optional(T')` (added 2026-10-20, review fold: B-M-5): the value
    converts to `StdOptional(T')` as above, then through the prelude's
    `StdOptional(T) as ImplicitAs(Optional(T))` impl, in one implicit step.

Each arm owns the cleanups registered while it is built, as an `if`
expression's operands do (control_flow.cpp:175-215,
`BeginConditionalExprOperand`), so a C++ temporary made in one arm (the
`Core.Optional(T*)` that `value()` returns for a pointer payload) is destroyed
in that arm. The explicit integer template argument of `std::get<i>` and
`emplace<i>` is supplied by calling `PerformCppOverloadResolution` with an
integer literal as its `template_arg_ids` (overload_resolution.cpp:266), the
entry point that a Carbon call reaches for type template arguments; no Carbon
spelling is added. The calls themselves go through the existing call path and
its thunks (§0.5); the SemIR of the arbiter body is in §1.6.

**Where it cannot branch** (rewritten 2026-10-20, review fold: A-M1 / A-B2;
amended 2026-10-20, review fold: RR-m1 / RR-M1; RR3-M1 / RR3-B1; RR4-M1). The
conversion branches, so it needs a function body and a parse node for its
blocks; `CanBuildBranches` tests both and emits the TODO, and only the committed
(diagnosing) conversion calls it. Outside a function body it emits ``semantics
TODO: `conversion of a C++ `std::optional` or `std::variant` outside a function
body (at file scope, or deferred to a template's instantiation)` `` and returns
an error: at file scope (a `let` initializer; measured `x18`, the rev-1
`t01`/`s15` shape, and an `overload fn` call there, f01), the same limit as
every branching expression there (W-036), and during template instantiation,
where TP-1 performs a deferred conversion outside any function body (h2, h3 on
tpv4; t4, t7 on tpv6; W-279). A distinguishing test between the two was tried
and rejected: the conversion's location is an instruction in both. A conversion
inside a function whose location reaches no parse node emits ``conversion of a
C++ `std::optional` or `std::variant` with no source expression`` (W-285). A
program reaches it by passing a Carbon sum value or `Core.Optional(T')`, as an
initializing expression such as `.Some(5)`, to a C++ parameter of non-`const`
rvalue reference type `T&&`, alone or as the member that C++ prefers to a
`const T&` sibling (`std::vector::push_back`): the parameter's initialization is
located at its C++ declaration, which is no parse node of the file (r2 to r5,
x07, x09, x13 and x19 on v6; §1.5). Rev 4 said no measured program reaches it
(amended 2026-10-20, review fold: RR4-M1). Rev 1's crash there
(`control_flow.cpp:61`, review A's a7, a10, a11) came through C++'s converting
constructors, which the reverse rule of §1.5 now refuses first, and an impl's
signature-adapting thunk (x11) reaches its node. From M on, a third place cannot
hold branches: a VA-1 pack element, converted in one straight-line block per
element (an expansion body, or `ConvertPackToPack`). The value the hook sees
there is the `SemIR::PackElement` itself, or, when the element's type is a
tuple, struct, array or class holding a sum type, what the aggregate conversion
projects from it (`TupleAccess`, `StructAccess`, `ArrayIndex`,
`ClassElementAccess`, through `AsCompatible`, `AcquireValue` and `ValueAsRef`);
the land-time hunk M-VA (§3 item 8) walks those projections back to a
`PackElement` in `CanBuildBranches`, which then emits ``semantics TODO:
`conversion of a C++ `std::optional` or `std::variant` for a pack element` ``
(W-284) before any block is built, instead of reaching VA-1's CHECK (n01 to n08,
n13, n14 and n16 to n21 on vav6g; n15 and n22 get VA-1's own TODOs first).
Rev 3's hunk tested for a bare `PackElement` only, and a pack of tuples,
structs, arrays or classes holding a sum type still stopped PR 59's composition
at the CHECK (the re-review of rev 3's n01 to n05; mutant M21).

**Valueless.** A valueless `std::variant` is reachable through a throwing
conversion inside `emplace` (§0.5, rewritten 2026-10-20, review fold: A-m2);
its conversion fail-stops in the last arm's `std::get`, through the B0 fence.

_Break condition:_ if a caller that sets `diagnose` false keeps a successful
non-constant result (convert.h's contract forbids it, and deduction keeps only
constants), a new path builds an element's `ConversionTarget` without the
aggregate's `diagnose` (mutant M17's shape), a conversion step projects a pack
element through an instruction the walk of M-VA does not follow (then the
straight-line region is marked by VA-1's code instead, §7.1 R-10), or W-036,
W-279 or W-284 must be lifted, the arms are rebuilt as a call to a synthesized
Carbon function per specialization (one body, no caller-side blocks, §7.2 R-K),
which makes every conversion a single call. W-285 lifts without them, by
attributing the blocks to the argument's own parse node where the parameter's
location is not one (mutant M22, §8 item 5; amended 2026-10-20, review fold:
RR4-M1).

### §1.5 D-SV-5: the conversion from Carbon to C++, and what is exportable

**Converting a sum value to the C++ class.** `TryConvertCppSumType` with a
`StdOptional`/`StdVariant<n>` source and its own C++ class as the target
default-constructs the C++ object (an empty `std::optional`; a `std::variant`
holding a value-initialized first alternative, which every admitted
alternative type has), then dispatches on the choice's discriminant
(`EmitChoiceDiscriminantTest`, pattern_match.cpp:573) and, in the active
alternative's block, reads the payload (`EmitChoicePayloadFieldAccess`, :1048)
and calls `emplace(x)` or `emplace<i>(x)`; a payload-free `None` emplaces
nothing, and a `()` payload calls `emplace()` or `emplace<i>()` with no
argument (`std::optional<std::monostate>` included, amended 2026-10-20, review
fold: A-m3). The result is the C++ temporary, read as a value.

**The reverse rule** (added 2026-10-20, review fold: A-B2). A Carbon sum value
converts to a C++ class target only when that class is the one whose Carbon
sum type it is (`GetCppSumType(target).carbon_type_id` equals the value's
type). Any other C++ class target -- another specialization
(`std::optional<long>` for a `StdOptional(i32)`), a class with a converting
constructor from the right specialization, `std::optional<int*>` for a
`StdOptional(i32*)` (whose own class's sum type is
`StdOptional(Core.Optional(i32*))`) -- is diagnosed in the hook, before
`PerformUserDefinedConversion` would hand the value to C++'s converting
constructors:

> ``error: `Core.CppCompat.StdOptional(i32)` converts to C++ only as the
> `std::optional` or `std::variant` whose Carbon sum type it is, not to
> `std::optional<long>` [CppSumTypeReverseMismatch]``

Measured on v4: review A's a10, a11 and a7 and the fixer's x04 and x05 give it;
rev 1 instead stopped at `control_flow.cpp:61` there, and would otherwise have
narrowed a `StdOptional(i64)` payload into `std::optional<int>` through C++'s
converting constructor where trunk rejects the scalar `Cpp.TakeInt(i64)` (A-B2;
mutant M13 makes the conversion succeed through that constructor). A non-C++
target is not the hook's: a `StdOptional(T)` to `Core.Optional(T)` goes through
the prelude bridge, and to a user's Carbon class through the user's
`ImplicitAs` impl.

**`Core.Optional(T)` to C++** (added 2026-10-20, review fold: B-M-5). A
`Core.Optional(T')` whose payload is a concrete choice payload type and NOT a
pointer converts the same way, through its view: the bridge to
`StdOptional(T')`, then the reverse conversion, to the class whose sum type
that view is, by the same rule. A `Core.Optional(T*)` keeps its existing
mapping to the nullable C++ `T*` (type_mapping.cpp:267-285), unchanged (x06
prints 5 -1 on trunk and v4).

**Passing to C++.** `InventClangArg` (type_mapping.cpp:695) offers an argument
of a sum type to C++ overload resolution as its C++ class
(`MapCarbonSumTypeToCpp`, new: `std::optional`/`std::variant` named through
`LookupCppClassTemplate` and specialized with the mapped argument types), and
a `Core.Optional(T')` with a matchable non-pointer payload as
`std::optional<T>`, so `Cpp.Take(StdOptional(i32).Some(5))` and
`Cpp.Take(Core.Optional(i32).Some(5))` select `Take(std::optional<int>)` or
`Take(const std::optional<int>&)`, and the argument conversion then runs the
reverse conversion (measured `s08`, `s09`, `s18`: 41 42 -1; 25 9 107; -1 6;
x03: 3 103 -1). This happens before `MapToCppType`, which would otherwise try
to export the `Core` type and hit the export TODO. A non-`const` lvalue
reference parameter rejects the temporary, by C++'s own rule (`w08`: `no
matching function for call to 'Reset'`).

A non-`const` rvalue reference parameter `T&&` (added 2026-10-20, review fold:
RR4-M1) takes such an argument when it is an initializing expression
(`.Some(5)`), which C++ sees as an rvalue of the class and prefers to a
`const T&` sibling (`std::vector::push_back`, a setter pair), but the conversion
then gives W-285's TODO, because the parameter's initialization is located at
its C++ declaration (§1.4, §1.11; r2 to r5, x07, x09, x13, x19). A `const T&&`
parameter converts (x01). A value, such as a `let` or parameter binding, `.None`
or `as` the C++ class, is offered to C++ as an lvalue: it selects the `const T&`
sibling (x10, x14, x16, x18), and a lone `T&&` refuses it by C++'s rule, as it
refuses a value of the C++ class itself on trunk (x02 to x06, x11, x12; t1, t2).
A C++ call's result binds the `T&&` (r1, x08).

**Returning to C++.** A Carbon function that C++ calls declares the C++ class
in its signature, `fn Make(n: i32) -> Cpp.std.optional(i32)`, and returns a
sum value, which the return converts (measured `s10`: C++ reads 41 and -1;
`d07`, `d08`, `d09`); a C++ caller passing a `std::optional` to a Carbon
function that takes `Cpp.std.optional(i32)` and matches it works too (`s21`:
41).

**Exportability.**

| Shape | Status |
| --- | --- |
| C++ to Carbon: returns, arguments, `let`/`var` initializers, `as`, scrutinees | IN |
| C++ `std::optional<T>` to `Core.Optional(T')`, non-pointer payload, implicitly | IN (rev 2; x01) |
| Carbon to C++: a sum value, or a `Core.Optional(T')` with a matchable non-pointer payload, passed by value, `const&` or `const&&`; assigned or returned where the C++ class is expected | IN (rev 2 for `Core.Optional`; x03; `const&&` measured at rev 5, x01) |
| A C++ caller of a Carbon function whose signature names the C++ class | IN (existing export) |
| A sum value to any other C++ class (another specialization, a converting constructor) | OUT, `CppSumTypeReverseMismatch` (rev 2) |
| A Carbon function whose signature names a `Core.CppCompat` sum type, called from C++ | OUT: the existing export TODO for `Core` package entities, "interop with non-identifier package name" (export.cpp:139-141; `s16`), W-049's |
| A sum value passed to a non-`const` lvalue reference parameter | OUT by C++'s rules |
| A sum value or `Core.Optional(T')` passed as an initializing expression to a non-`const` `T&&` parameter, alone or the `T&&` member of a `const T&`/`T&&` pair (rev 5; amended 2026-10-20, review fold: RR4-M1) | OUT: ``semantics TODO: `conversion of a C++ `std::optional` or `std::variant` with no source expression` `` at the C++ parameter (W-285); a value argument selects the `const T&` member, and a lone `T&&` refuses a value by C++'s rules |

Rev 1's last row, `Core.Optional(T)` passed directly where C++ takes
`std::optional<T>` (W-278), is IN at rev 2, and W-278 is withdrawn unfiled
(§1.16).

_Break condition:_ if an exported signature must name a sum type, the
export path maps it to the C++ class with a conversion thunk (W-049's
territory), and the table moves the row to IN; if C++'s converting
constructors between specializations must be honored, the reverse rule
converts through the source class first and then lets C++ convert, with a
narrowing check; if a C++ `T&&` parameter must take a fresh sum value, the
conversion's blocks are attributed to the argument's own parse node (W-285's
removal, mutant M22; amended 2026-10-20, review fold: RR4-M1).

### §1.6 D-SV-6: match consumption at the scrutinee gate

`CheckRefutableScrutinee` (refutable_binding.cpp:137-207), shared by `match`,
`if`-`let`, `while`-`let` and `let`-`else`, converts the scrutinee after
`RequireCompleteType` and before the shape gate `IsSupportedScrutineeType`:

-   an admitted C++ sum class converts to its sum type (§1.4); a non-admitted
    one is diagnosed with `CppSumTypeNotMapped` instead of the generic
    "match on unsupported scrutinee type" TODO, and checking of the form stops
    as the TODO did;
-   a `Core.Optional(T)` whose payload type is concrete and passes the
    choice-payload predicate converts to its view `StdOptional(T)` (§1.7); a
    `Core.Optional(T)` whose payload is symbolic or not a choice payload type
    is diagnosed with `CoreOptionalNotMatchable` and checking of the form
    stops, as for an unmapped C++ class (amended 2026-10-20, review fold:
    A-M2 / B-M-1);
-   every other type is untouched, so the five existing scrutinee shapes keep
    their byte-identical paths (the gate's own comment, :176-184).

The scrutinee is then a value of a `choice` specific, and everything after it
is the existing choice machinery: `.Some(n: i32)`, `.None`, `.Alt<i>(...)`
resolve in the specific's scope (`ResolvePendingAlternative`), an unknown
alternative is the existing `MemberNameNotFoundInSpecificScope`, the arms test
the discriminant, payload bindings read the payload tuple, SF-7 coverage
applies, and a `default` after full coverage is `MatchDefaultNeverMatches`.

**What the gate does not consume** (added 2026-10-20, review fold: B-M-2 /
A-m5). The scrutinee is a converted copy, so:

-   a `ref` payload binding, `case .Some(ref n: i32) => { n = 5; }` on a `var`
    C++ optional or `Core.Optional`, is rejected with the existing ``cannot
    bind durable reference to non-reference value of type `i32`
    [ConversionFailureNonRefToRef]`` (review A's b1 and b2, review B's p04 and
    p05, the fixer's x14), where a native `choice` `var` scrutinee binds into
    the object; a `var` binding copies, as for any choice (b3 prints 9 7).
    Pinned by `fail_todo_ref_binding` in stdlib/optional.carbon and
    match/core_optional_view.carbon; filed as W-280 (break condition: the
    `Match` interface, or a by-reference view);
-   a C++ sum class nested in a tuple or struct scrutinee, `match (t)` with
    `t: (Cpp.std.optional(i32), i32)`, is not converted: the gate converts a
    whole scrutinee only, so the existing ``semantics TODO: `match on
    unsupported scrutinee type` `` stays (x10; pinned by
    `fail_todo_tuple_scrutinee` in stdlib/fail_sum_types.carbon; W-281),
    while `(StdOptional(i32), i32)` is supported.

The SemIR of the arbiter's intended body without its `default` (rev 1's
prototype v3, `$P/runs/arb.semir`, `fn @Run`, abbreviated; v4 builds the same
blocks for a conversion that diagnoses, §4's `match` row; `%optional` is the
C++ class `std::optional<int>`, `%StdOptional.4c3` its sum type):

<!-- google-doc-style-ignore -->

```
%MaybeSeven__carbon_thunk.call: init %empty_tuple.type = call imports.%MaybeSeven__carbon_thunk.decl(%addr.loc7_25)
%.loc7_25.3: ref %optional = temporary %.loc7_25.1, %.loc7_25.2
%.loc7_25.4: %optional = acquire_value %.loc7_25.3
%.loc7_26.1: ref %StdOptional.4c3 = temporary_storage
%has_value__carbon_thunk.call: init %empty_tuple.type = call imports.%has_value__carbon_thunk.decl(%.loc7_25.11, %addr.loc7_26)
%.loc7_26.5: bool = acquire_value %.loc7_26.4
if %.loc7_26.5 br !.loc7_26.1 else br !.loc7_26.2
!.loc7_26.1:
  %value__carbon_thunk.call: ref %const.6a8 = call imports.%value__carbon_thunk.decl(%.loc7_25.18)
  %StdOptional.Some.call: init %StdOptional.4c3 to %.loc7_26.7 = call %StdOptional.Some.specific_fn(%.loc7_26.10)
  assign %.loc7_26.1, %StdOptional.Some.call
  br !.loc7_26.3
!.loc7_26.2:
  %None.ref.loc7: %StdOptional.4c3 = name_ref None, %.loc7_26.11 [concrete = constants.%StdOptional.val.f8e]
  %Copy.WithSelf.Op.call: init %StdOptional.4c3 to %.loc7_26.12 = call %bound_method.loc7_26.3(%None.ref.loc7)
  assign %.loc7_26.1, %Copy.WithSelf.Op.call
  br !.loc7_26.3
!.loc7_26.3:
  %.loc7_26.13: %StdOptional.4c3 = acquire_value %.loc7_26.1
  // the C++ temporary and the `bool` temporary are destroyed here
  %.loc8_24.3: ref %u1 = class_element_access %.loc7_26.13, element0
  %UInt.as.EqWith.impl.Equal.call.loc8: init bool = call %bound_method.loc8_24.4(%.loc8_24.2, %.loc8_24.4)
  if %.loc8_24.6 br !match.case.then.loc8 else br !match.case.else.loc8
!match.case.then.loc8:
  %.loc8_24.7: ref %.e8e = class_element_access %.loc7_26.13, element1
  %tuple.elem0: ref %i32 = tuple_access %.loc8_24.8, element0
  %n: %i32 = wrapper_binding n, %.loc8_24.9
  %Print.call: init %empty_tuple.type = call %Print.ref(%n.ref)
```

<!-- google-doc-style-resume -->

_Break condition:_ if the `Match` interface is implemented, the gate calls it
instead of converting (F-020's break condition).

### §1.7 D-SV-7: `Core.Optional`: the bridge, the one-step conversions, the view

**The bridge.** sum.carbon declares, after the choices:

<!-- google-doc-style-ignore -->

```carbon
impl forall [T: Copy & Destroy]
    CppCompat.StdOptional(T) as ImplicitAs(Optional(T)) {
  fn Convert(self) -> Optional(T) {
    match (self) {
      case .Some(value: T) => { return Optional(T).Some(value); }
      case .None => { return Optional(T).None(); }
    }
    // Unreachable: reachability does not consult `match` exhaustiveness.
    return Optional(T).None();
  }
}

impl forall [T: Copy & Destroy]
    Optional(T) as ImplicitAs(CppCompat.StdOptional(T)) {
  fn Convert(self) -> CppCompat.StdOptional(T) {
    if (self.HasValue()) {
      return CppCompat.StdOptional(T).Some(self.Get());
    }
    return CppCompat.StdOptional(T).None;
  }
}
```

<!-- google-doc-style-resume -->

Both go through `Optional`'s public API (`Some`, `None`, `HasValue`, `Get`),
so they assume nothing about its storage, its pointer niche or PR 57's
`MaybeUnformed` representation; `Get()` is called only after `HasValue()`, so
PR 57's fail-stop on an empty `Get()` is never reached. The orphan rule
(impl_validation.cpp `DiagnoseOrphanImpl`) is met: both impls name
`StdOptional`, which sum.carbon declares. No impl overlaps: optional.carbon's
blanket `U as ImplicitAs(Optional(T))` (:128-133) needs `U: OptionalAs(T)`,
which `StdOptional(T)` does not implement. Measured: `s11` (7 8), `w11` (7 7
7), and on the OP-2 composition `o04` (5 6 -1 9, as on v4).

**One step, both ways** (rewritten 2026-10-20, review fold: B-M-5 / A-M4).
Rev 1 left `let c: Core.Optional(i32) = Cpp.MaybeSeven();` an error (m20: the
prelude export TODO, then "cannot implicitly convert") and deferred the
one-step form as W-278 with a reason, "overload resolution would then need a C++
type for `Core.Optional(T)`", that applies only to the Carbon-to-C++ argument
direction; both reviews noted the forward direction had no stated reason.
Rev 2 implements both:

-   C++ to `Core.Optional`: a C++ `std::optional<T>` converts to
    `Core.Optional(T')` when `T'` is its sum type's payload: the hook converts
    to `StdOptional(T')` and then through the bridge (§1.4). x01 prints 7 -1;
    a mismatching payload (`Core.Optional(i64)` from `std::optional<int>`) is
    `CppSumTypeMismatch`, whose text names the one-step target ("converts only
    to its own Carbon sum type `Core.CppCompat.StdOptional(i32)` or to the
    `Core.Optional` of its payload, not to ..."), x02.
-   `Core.Optional` to C++: a `Core.Optional(T')` whose payload is a concrete
    choice payload type and not a pointer is offered to C++ overload
    resolution as `std::optional<T>` and converted through the bridge and the
    reverse conversion (§1.5); x03 prints 3 103 -1. `Core.Optional(T*)` keeps
    the nullable-pointer mapping to `T*` it has today.

The reason rev 1 gave is answered by the split itself: the C++ type of
`Core.Optional(T*)` stays `T*` (p006357's pointer ABI, one of W-177's
constraints), and only the payloads that pointer mapping does not cover are
offered as `std::optional<T>`, in overload resolution only; no exported
signature maps `Core.Optional(T)` (an exported signature that names it stays the
existing export TODO of W-049, as one that names a `Core.CppCompat` sum type
does, `fail_todo_export_sum_type`). This relates the `std::optional` mapping to
`Core.Optional(T)`, so F-015 is amended first (§1.1, Appendix C). W-278 is
withdrawn unfiled; its id stays unused (§1.16).

**The match view (W-177), narrowed** (rewritten 2026-10-20, review fold: A-M2
/ B-M-1). OP-1 filed W-177 on row 68's bullet ("`Core.Optional` is not
matchable (no `.Some`/`.None` patterns, `match` or `if let`)", on PR 56's
branch), with constraints on any fix: keep the `Try` signature, the pointer
ABI, the `HasValue`/`Get` names that `for` calls, and the C++ mapping's name
case; its notes say SAFE-1's EX-M-5 and EX-M-6 wait on it and that it "closes
the V-3a divergence that comparisons copy the held values (D-OP-4)"; and its
break condition is "`.Some` and `.None` patterns over `Core.Optional` are
implemented, by `Match` for classes or by a `choice` that keeps those
constraints". The scrutinee gate converts a `Core.Optional(T)` scrutinee to
`StdOptional(T)` through the bridge (`GetCoreOptionalView`, §2.4), under one
admission rule checked before the view's specific is formed:

-   `T` concrete and a 0.1 choice payload type (SF-6's predicate, with D-SV-8:
    scalars, pointers, `()`, `Core.Optional(U*)`): matched. Measured on v4:
    `Core.Optional(i32)` in both states, `Core.Optional(i32*)` (whose `.Some`
    binds the non-null `i32*`, and whose `None` is the null pointer, so `if
    (let .Some(p: i32*) = Cpp.Find(1))` works on a nullable C++ pointer: x08
    prints 5 -1), `if`-`let`, `Core.Optional(i64)`; match_core_optional_diff
    (7 lines, DIFF-PASS).
-   `T` symbolic: diagnosed, ``cannot match `Core.Optional(T as
    Core.OptionalStorage)` in 0.1: its payload type is symbolic
    [CoreOptionalNotMatchable]``. Rev 1 formed the view for a symbolic `T`,
    so a checked generic that type-checked under `T: Copy & Destroy` failed
    at monomorphization for an aggregate `T`, with errors inside the prelude
    (review A's a4, review B's p03). A native generic choice does not have
    that problem, because its caller forms the choice specific; the view's
    specific is formed only inside the generic, so no constraint on `T` can
    guarantee it.
-   `T` concrete but not a choice payload type (`Core.String`, a tuple, a
    struct, `Core.Optional(i32)`): diagnosed, ``... its payload type is not a
    choice payload type`` (a3, a5, p02, x13), where rev 1 printed "forming
    value of incomplete type `Core.CppCompat.StdOptional(...)`" and the old
    TODO.

The class, its API and its storage are untouched, so W-177's constraints are
kept. The view copies the payload (`Get()` returns a copy), so a `ref` binding
is rejected (§1.6, W-280) and the comparison-copy divergence D-OP-4 is not
closed. **W-177 is therefore NOT discharged** (rev 1 discharged it): SV-1
appends a dated narrowing note (Appendix C) recording what is matchable since
SV-1 and what remains -- symbolic payloads, payloads outside SF-6, `ref`
payload bindings and copy-free matching, so EX-M-5 and EX-M-6 (a
`Core.Optional(Core.Buf(i32))` matched with `case .Some(ref s)`) still wait on
it -- with its break condition unchanged.

_Break condition:_ if W-058's design or the owner wants `Core.Optional`
matched without a copy, by reference or generically, the `Match` interface or
a choice-based `Optional` replaces the view (F-020's break conditions), and
W-177 closes then; if the name `Core.CppCompat.StdOptional` reads wrong in a
pure-Carbon diagnostic (an unknown alternative on a `Core.Optional`
scrutinee names it, `core_optional_view.carbon` `fail_unknown_alternative`),
the view is renamed, a one-identifier change; if PR 56 or PR 57 changes
`Optional`'s pointer mapping, the non-pointer test of the one-step conversion
follows it.

### §1.8 D-SV-8: nullable pointer payloads

A plain C++ `T*` imports as `Core.Optional(T*)` (the nullable pointer), so
`std::optional<int*>`'s payload and a `std::variant<..., int*>` alternative
are `Core.Optional(i32*)`. `Core.Optional(T*)` adapts `MaybeUnformed(T*)`
(optional.carbon:188-190), which adapts `MakeMaybeUnformed(T*)`
(maybe_unformed.carbon), a `T*` carrying the `MaybeUnformed` type qualifier.
`IsInSliceChoicePayloadType` unqualifies first and then walks adapters
(`GetTransitiveAdaptedType(GetUnqualifiedType(t))`, type.cpp:339-340), so the
qualifier found inside the adapter chain stops the walk at a non-pointer and
the payload is rejected (`c01`).

**The fix, narrowed** (rewritten 2026-10-20, review fold: A-M3). Rev 1
replaced the walk with `GetTransitiveUnqualifiedAdaptedType(t).first`, which
admits every type whose qualifier-and-adapter chain reaches a scalar: review A
measured that it also admitted `Cpp.nullptr_t` (it adapts
`MaybeUnformed(VoidBase*)`, core/prelude/types/cpp/nullptr.carbon:31), in a
choice payload, in `std::optional<std::nullptr_t>` and as a catching import's
success type (f1b ran and printed 1 -9), and `Core.MaybeUnformed(i32)` and
`MaybeUnformed(i32*)`, which are not `Copy`, so a choice of them failed with
"cannot copy value" instead of SF-6's TODO (e6, f3). Rev 2 keeps trunk's walk
unchanged and adds one admitted type by name: a `Core.Optional` specific whose
qualifier-and-adapter walk reaches a pointer type (`IsCoreOptionalOfPointer`,
§2.8), exactly the nullable-pointer mapping. `Core.Optional(T*)` is `Copy &
Destroy` (it implements both for every `T*`) and trivially copyable.

**Sites** (amended 2026-10-20, review fold: A-M3). The predicate has four
callers, not three: handle_choice.cpp:760 (a `choice` declaration's payload),
eval_inst.cpp:310 and :342 (the per-specific pre-filter and post-completion
checks), and cpp/thunk.cpp:1275 (`IsCatchingSuccessTypeAdmitted`, a catching
import's success type, whose admitted types thunk.cpp:1337-1365 CHECKs to
complete `Core.Result`). The narrowed rule changes only the first three, for
`Core.Optional(T*)`: a C++ function returning `T*` has the success type
`Core.Optional(T*)`, which implements `Core.Try`, so thunk.cpp:1283-1296 routes
`Cpp.f()?` to the ordinary `Try` operand path before the predicate is asked
(review A's a6, a6b, a6c give the same error on trunk, v3 and v4: "cannot
implicitly convert expression of type `()` to `Cpp.Exception`", `Optional`'s
own break type).

Measured on v4: `d04` (a Carbon choice with a `Core.Optional(i32*)` payload, 3)
and `s05` (42 0 -1: engaged non-null, engaged null, empty all distinct), as on
v3; review A's f1, f1b, f2, e6 and f3 give trunk's diagnostics again (a catching
import of a `std::nullptr_t` function: ``requires a scalar success type in 0.1;
`Cpp.nullptr_t` is not one``; a choice payload of `Core.CppCompat.NullptrT`,
`Core.MaybeUnformed(i32)` or `Core.MaybeUnformed(i32*)`: SF-6's TODO;
`std::optional<std::nullptr_t>`: `CppSumTypeNotMapped`). Pinned:
choice/optional_pointer_payload.carbon `pointer`,
`fail_todo_non_pointer_optional`, `fail_todo_nullptr_payload` and
`fail_todo_maybe_unformed_payload`, and
interop/cpp/exceptions/fail_catching.carbon `fail_nullptr_return` (new split).

_Break condition:_ if PR 57's representation makes the walk reach something
other than the pointer for `Core.Optional(T*)` (measured on op2v4: it reaches
the pointer, s05 prints 42 0 -1), the name test admits `Core.Optional(T*)` by
its argument instead; if SF-6 admits non-`Copy` or aggregate payloads, the name
test is subsumed and deleted.

### §1.9 D-SV-9: constant aggregates in lowering

`EmitAsConstant(AnyAggregateAccess)` (lower/constant.cpp:243-263) builds a
constant GEP whose base is the aggregate's lowered constant. When the access is
folded out of a constant class VALUE (the payload tuple of a constant `choice`
alternative), that constant is the value itself, an LLVM aggregate, and the GEP
and the later load are ill-formed: the root cause of r03 (§0.4 item 6).

**The fix, routed** (rewritten 2026-10-20, review fold: A-m6). Rev 1 wrapped
such a value in a new, uncached `private unnamed_addr` global (`@const.aggr`) at
each access: a parallel mechanism. Function lowering already addresses a value
constant whose value representation is a pointer, in `FileContext::GetConstant`
(file_context.cpp:226-296): an internal constant global, cached in
`global_variables_` and named `@<constant>.<use>`. Rev 2 routes the access
through it: when the base is not a pointer,
`ConstantContext::GetValueConstantAddress` (new, two lines) asks
`FileContext::GetConstant` for the address; `LowerConstants` fills the same
constant store that `FileContext::GetConstant` reads (file_context.cpp:110), and
the aggregate is lowered before the access that uses it. A value whose
representation is not a pointer has no addressable element, and the access is
then left unlowered as a constant (null), as for an unlowered aggregate. This is
the representation rule itself, not a workaround at the mapping: it fixes the
crash for every constant choice scrutinee, mapped or not. It does not reach a
constant tuple or struct whose element is a choice constant, such as
`(Core.CppCompat.StdOptional(i32).None, 0)` in a `var` or `let` initializer:
lowering stops at lower.cpp:48 when the module is verified
(``Global variable initializer type does not match global variable type``), as
trunk's own `((1, 2), 3)` and a user generic choice's `(G(i32).A, 0)` do without
SV-1: the failure is W-263's, TP-1's residue on PR 61 (z1, z7 and y11 on v6; z5,
z8 and z9 on trunk; amended 2026-10-20, review fold: RR4-m1; §1.11). Measured on
v4: `r03` runs (-1), review A's `r05` (two constants in one function) prints -1
-2 5, the reverse conversion of a constant runs (`s18`, and the roundtrip
program), and lower/match/constant_choice_scrutinee.carbon pins
`@uninit.060.anon = internal constant [4 x i8] zeroinitializer` and
`load i32, ptr @uninit.060.anon`.

_Break condition:_ if constant folding stops producing value-category
aggregate accesses (upstream), the routing is dead and is removed with its
golden's refill.

### §1.10 D-SV-10: generics, deduction, templates, libraries, constants, file scope

-   **Generic Carbon code over the mapped type** works as for any choice
    specific: the generic `Unwrap[T: Copy & Destroy]` over `StdOptional(T)`
    matches `o` symbolically and is called with a converted value (`s07`
    prints 7 and then minus 5). A generic over `Core.Optional(T)` does not
    match `o` (rev 2: `CoreOptionalNotMatchable`, §1.7; amended 2026-10-20,
    review fold: A-M2 / B-M-1).
-   **Deduction does not see conversions**, so `Unwrap(Cpp.MaybeSeven(), 0)`
    deduces `T` from the literal alone, as `Core.IntLiteral`. Rev 1 said the
    call gets the single mismatch error; it gets four (rewritten 2026-10-20,
    review fold: A-m7), measured on v4 (x17, rev 1's w12): ``forming value of
    incomplete type `Core.CppCompat.StdOptional(Core.IntLiteral)` `` with
    SF-6's per-specific note at sum.carbon:30 (the parameter type itself, as
    for any generic choice whose argument is not a payload type); the
    `CppSumTypeMismatch` error; ``non-constant call to compile-time-only
    function`` from printing an `IntLiteral` result; and ``unable to
    monomorphize specific `Unwrap(Core.IntLiteral ...)` ``. Only the second is
    SV-1's, and every one is a consequence of the deduced `IntLiteral`;
    suppressing the cascade would be a change to deduction's error recovery,
    not to this mapping. The caller converts first (`let` or `as`). This is
    Carbon's deduction rule, not a residue.
-   **Templates** (rewritten 2026-10-20, review fold: A-M1). The hook returns
    `None` when either type is template-dependent, so it never diagnoses a
    conversion whose types are not known (rev 1 diagnosed h1's symbolic target
    at definition). On trunk such a conversion then takes trunk's existing
    template path. With PR 61 (TP-1), which lands first, the conversion is
    deferred and performed at instantiation in `PerformAction`
    (convert.cpp:2945-2989 on TP-1's head), outside any function body, where the
    conversion cannot branch: it emits the TODO of §1.4 under ``unable to
    monomorphize specific`` (measured on tpv4: h2 and h3; on trunk the same;
    pinned by `fail_todo_template_conversion` in stdlib/fail_sum_types.carbon,
    unchanged on tpv4); filed as W-279. A `match` on a template-dependent value
    is W-252's (TP-1's), for every choice: on TP-1's head a `match` on a
    template-dependent generic choice stops at pattern_match.cpp:1409 with no
    C++ involved (x19 on TP-1's own toolchain; trunk gives W-252's TODO), so h1
    stops there on tpv4; this is finding X-1 of the fold record, routed to TP-1,
    and §1.16 files it only if it is still on the merged trunk at D. TP-1's
    round-10 head fixes X-1 (amended 2026-10-20, review fold: RR3-m3): on tpv6,
    x19 compiles and prints 0, and h1 gets W-279's TODO at instantiation for its
    `let`'s conversion, before its `match`. An `overload fn` call inside a
    template whose member takes the sum type is the same TODO at instantiation,
    not a call of a later member (amended 2026-10-20, review fold: RR3-M1): the
    probe accepts the member, whose committed conversion is the deferred one
    (t4, and t7 with a generic second member, on tpv6 and on trunk's build;
    `fail_todo_template_overload` in stdlib/sum_type_overload.carbon, which
    passes unchanged on tpv6).
-   **Through a Carbon library.** A library may traffic in the sum types
    (`Fetch(n: i32) -> Core.CppCompat.StdOptional(i32)`), and an importer that
    imports no C++ matches them (`xlib`, and the multi-unit program of
    §1.13). A library that exposes the C++ class itself reaches importers
    without a C++ import of the header through W-047's indirect-import TODO
    (measured `lib1/main2`, `main3`, `main7` on trunk and v1: ``semantics
    TODO: `indirect import of C++ declaration with no direct Cpp import` ``),
    and works when the importer imports the header (`main5`, `main6`).
-   **Constants.** A sum type's constants are ordinary choice constants
    (`StdOptional(i32).None`, `StdVariant2(i32, f64).Alt1(2.5)`), usable as
    scrutinees (D-SV-9) and converted to C++ at run time (`s18`). A C++
    `std::optional` value is never a Carbon constant: C++ calls are not
    evaluated at compile time, and `Cpp.std.nullopt` as an argument is the
    existing ``unsupported conversion to constant from APValue {}`` TODO
    (`n17`, unchanged). A constant tuple or struct holding a sum-type
    constant stops lowering as W-263's nested constants do (§1.9, §1.11;
    amended 2026-10-20, review fold: RR4-m1).
-   **File scope, and a parameter's default value.** §1.4: the TODO, riding
    W-036; a default value is checked in the declaration's signature, outside
    any function body (w03, w35; amended 2026-10-20, review fold: RR4-m2).
-   **`overload fn` sets** (added 2026-10-20, review fold: A-B1 / B-B-1; amended
    2026-10-20, review fold: RR-B1 / RR-B-1; RR3-M1): a member whose parameter
    is a sum type, the C++ class, or a tuple, struct or array holding one is a
    candidate like any other: the probe converts without building anything, an
    aggregate's elements included (§1.4), so the first member that accepts the
    argument is called, generic members included. Where the committed conversion
    cannot be built, at file scope or at a template's instantiation, that member
    is still the one the argument converts to, so it is selected and the call
    reports the limit's TODO; rev 3 skipped it there and silently called a later
    member (f01, t7), so the member a call selected depended on where the call
    was (stdlib/sum_type_overload.carbon's sixteen splits:
    `fail_todo_file_scope` and `fail_todo_template_overload` pin the TODO,
    `scalar_tuple_mismatch_first` the sum-free element probe).

_Break condition_ (added 2026-10-20, review fold: B-m-6): if deduction learns
to see through implicit conversions, or TP-1 can splice control flow into an
instantiation, the second and third items are re-decided (W-279 lifts with the
latter).

### §1.11 D-SV-11: diagnostics for every OUT shape

New diagnostic kinds in toolchain/diagnostics/kind.def, after
`CppExportResultNeedsExpectedHeader` (:259), eight at rev 2 (amended
2026-10-20, review fold: A-B2 / A-M2 / B-M-1). The texts below are MEASURED
on v4, which emits the real kinds (§0.0), and pinned by the `fail_` splits of
§1.12; rev 1's were hand-predicted from a prototype that emitted
`context.TODO`. Every OUT shape a user can write, with what the user gets
(rewritten 2026-10-20, review fold: B-M-5 / B-M-2 / A-m5 / A-M1):

| Shape | Diagnostic (v4) | Residue |
| --- | --- | --- |
| an alternative that imports as a class or other non-payload type (`std::optional<S>`, a nested `std::optional`/`std::variant` by value) | ``error: C++ type `std::optional<Point>` has no Carbon sum type [CppSumTypeNotMapped]`` with ``note: alternative 0 has type `Point`, which is not a choice payload type in 0.1 [CppSumTypeAlternativeNotAdmitted]`` | W-275 |
| a class that is not trivially copyable and destructible (`std::optional<std::string>`, libc++'s `std::optional<const int>`) | the same error with ``note: `std::optional<NonTrivial>` is not trivially copyable and trivially destructible [CppSumTypeNotTriviallyCopyable]`` | W-275 (SF-6's post-0.1 item) |
| a `std::variant` of more than eight alternatives | the same error with ``note: `std::variant` with 9 alternatives; at most 8 have a Carbon sum type [CppSumTypeTooManyAlternatives]`` | W-276 |
| a cv-qualified or reference alternative (libc++'s `std::variant<const int, double>`) | the same error with ``note: alternative 0 has qualified or reference type `const int` [CppSumTypeQualifiedAlternative]`` | W-277 |
| a sum type that cannot be completed (not reached by an admitted class; B-m-9) | the same error with no note | none |
| a C++ sum value converted to another sum type or `Core.Optional` (`StdOptional(i64)`, `Core.Optional(i64)` from `std::optional<int>`) | ``error: C++ type `std::optional<int>` converts only to its own Carbon sum type `Core.CppCompat.StdOptional(i32)` or to the `Core.Optional` of its payload, not to `Core.CppCompat.StdOptional(i64)` [CppSumTypeMismatch]`` (a `std::variant` omits the `Core.Optional` clause) | none: a type error |
| a C++ sum value converted to a `Core.Optional` whose payload is not matchable (`Core.Optional(Cpp.std.optional(i32))`, whose payload is the value's own class; amended 2026-10-20, review fold: RR-m3) | not the mapping's: `Core.Optional`'s own conversion from its payload, which on trunk gives ``semantics TODO: `interop with non-identifier package name` `` at optional.carbon:30 (k01 to k03 on trunk and v5); `Core.Optional(...).Some(Cpp.V())` works (k04) | none: trunk's own path, pinned by the probes only (a golden split would pin trunk's TODO at a prelude line PR 57 changes, and autoupdate files a diagnostic located in the prelude under the preceding split) |
| a Carbon sum value or `Core.Optional(T')` converted to any C++ class but its own (another specialization, a converting constructor) | ``error: `Core.CppCompat.StdOptional(i32)` converts to C++ only as the `std::optional` or `std::variant` whose Carbon sum type it is, not to `std::optional<long>` [CppSumTypeReverseMismatch]`` | none: a type error |
| a `Core.Optional(T)` scrutinee with a symbolic payload | ``error: cannot match `Core.Optional(T as Core.OptionalStorage)` in 0.1: its payload type is symbolic [CoreOptionalNotMatchable]`` | W-177 (narrowed, open) |
| a `Core.Optional(T)` scrutinee whose payload is not a choice payload type (`Core.String`, `(i32, i32)`, `Core.Optional(i32)`) | ``error: cannot match `Core.Optional((i32, i32) as Core.OptionalStorage)` in 0.1: its payload type is not a choice payload type [CoreOptionalNotMatchable]`` | W-177 (narrowed, open) |
| a `ref` payload binding on a mapped or view scrutinee | the existing ``error: cannot bind durable reference to non-reference value of type `i32` [ConversionFailureNonRefToRef]`` | W-280 |
| a C++ sum class inside a tuple or struct scrutinee | the existing ``semantics TODO: `match on unsupported scrutinee type` `` | W-281 |
| the conversion inside an `if`-expression arm (`if c then Cpp.MaybeSeven() else Cpp.Nothing()` to a sum type) | the existing ``semantics TODO: `destroying temporaries of a conditionally evaluated operand whose value is not passed by copy` `` | W-122 (a note) |
| the conversion outside a function body: at file scope, in a parameter's default value (a declaration's signature: `fn F(o: Cpp.std.optional(i32) = Core.CppCompat.StdOptional(i32).None)`; w03, w35; amended 2026-10-20, review fold: RR4-m2), or deferred to a template's instantiation, an `overload fn` call there whose member takes the sum type included (amended 2026-10-20, review fold: RR3-M1: the member is selected and the call gets the TODO, never a later member; f01, t4, t7) | ``semantics TODO: `conversion of a C++ `std::optional` or `std::variant` outside a function body (at file scope, or deferred to a template's instantiation)` `` (under ``unable to monomorphize specific`` for a template) | W-036 (file scope and default values, a note); W-279 (instantiation) |
| the conversion of a VA-1 pack element, in an expansion body or a pack converted to a pack of another element type, whose element is the C++ class, the sum type or a `Core.Optional`, or a tuple, struct, array or class holding one, in either direction (from M-VA, §3 item 8; amended 2026-10-20, review fold: RR-M1; RR3-B1: rev 3 covered the bare element only, and the aggregate forms stopped the compiler, n01 to n05) | ``semantics TODO: `conversion of a C++ `std::optional` or `std::variant` for a pack element` `` | W-284 |
| a Carbon sum value or `Core.Optional(T')` passed as an initializing expression (`.Some(5)`) to a C++ non-`const` `T&&` parameter, alone or the `T&&` member C++ prefers to a `const T&` sibling (`std::vector::push_back`), or any other conversion whose location reaches no parse node (amended 2026-10-20, review fold: RR4-M1: rev 4's row said no measured program reaches it; r2 to r5, x07, x09, x13, x19) | ``semantics TODO: `conversion of a C++ `std::optional` or `std::variant` with no source expression` `` at the C++ parameter, with the note ``initializing function parameter`` (`fail_todo_rvalue_ref_param`); a value argument selects the `const T&` member and converts | W-285 |
| a constant tuple or struct holding a sum-type constant, such as `(Core.CppCompat.StdOptional(i32).None, 0)` in a `var` or `let` initializer (amended 2026-10-20, review fold: RR4-m1) | not the mapping's: lowering stops at lower.cpp:48 (`!llvm::verifyModule`: ``Global variable initializer type does not match global variable type``), as trunk does for `((1, 2), 3)`, a class in a constant tuple and a user generic choice's `(G(i32).A, 0)` (z1, z7, y11 on v6; z5, z8, z9 on trunk); `.Some(n)` and run-time elements lower (z2, y12 to y14); no golden or program uses the shape | W-263 (TP-1's, on PR 61; a note) |
| a `Core.CppCompat` sum type in a signature C++ calls | the existing export TODOs (`s16`; `fail_todo_export_sum_type`) | W-049 (a note) |
| a `match` on a template-dependent value | W-252's TODO on trunk; TP-1's pattern_match.cpp:1409 CHECK on PR 61's pushed head (X-1); on TP-1's round-10 head eafca5cb9 the `match` itself works (x19, a pure-Carbon generic choice, prints 0 on tpv6), and h1, whose `let` converts a C++ optional to `StdOptional(T)` before its `match`, gets W-279's TODO for that conversion at instantiation (amended 2026-10-20, review fold: RR3-m3) | W-252; X-1 routed to TP-1, fixed on its round-10 head |

Rev 1's two rows for the one-step `Core.Optional` conversion (m20, t04) are IN
at rev 2 (§1.7). The first four rows share one error and differ in the note,
so a user sees which rule failed and for which alternative. The C++ spelling
(`std::optional<Point>`) is printed with clang's type printer without the tag
keyword (rev 1's prototype printed `class std::optional<int>`), because the
Carbon name of the imported class, `Cpp.std._C.optional`, carries no template
arguments.

`CppSumType::NoReason` (amended 2026-10-20, review fold: B-m-9): rev 1 emitted
nothing for it, which could have left an error inst with no diagnostic. Rev 2
splits it: `AlreadyDiagnosed` when `LookupNameInCore` or forming the specific
returned `ErrorInst` (each diagnoses its own failure, so nothing more is
emitted), and `NoReason` when the formed specific cannot be completed, which
emits `CppSumTypeNotMapped` with no note.

_Break condition:_ if `check_diagnostics.py` (the prek hook
`check-toolchain-diagnostics`) or a reviewer wants one error kind per rule,
the notes become errors; the goldens refill.

### §1.12 D-SV-12: goldens

All new goldens are AUTOUPDATE sources with no CHECK lines; their comments cite
this plan's sections and no W-id (W-ids live in the records only). The interop
goldens mock `std::optional` and `std::variant` in a `sum.h` split, as
stdlib/span.carbon and string_view.carbon mock theirs, so they are hermetic,
small, and pin the members the conversions call; `--target=x86_64-linux-gnu`
pins `size_t`. Sources: Appendix B and `$Y/final/goldens-src/`; fills:
`$Y/final/goldens-filled/` (v6, a fixpoint, §0.6; rev 4's `$W/final/` held the
same but for fail_sum_types.carbon's two rev-5 splits, amended 2026-10-20,
review fold: RR4-M1; rev 3's `$Z/final/` held v5's, identical but for
sum_type_overload.carbon, and rev 2's `$X/final/` v4's, identical but for that
file's eight rev-3 splits; amended 2026-10-20, review fold: RR-B1; RR3-M1 /
RR3-m4). Rev-2 changes are marked (amended 2026-10-20, review fold: A-B1 / B-B-1
/ A-B2 / A-M2 / B-M-1 / A-M3 / B-M-2 / B-M-5 / A-m3 / A-m5 / B-m-1).

| Golden (new unless stated) | Splits |
| --- | --- |
| check/testdata/interop/cpp/stdlib/optional.carbon | `match`, `if_let`, `convert` (both directions, by value and `const&`), `pointer_payload`, `bridge`, `one_step_core_optional` (rev 2), `monostate_payload` (rev 2), `fail_todo_struct_payload`, `fail_dead_default`, `fail_unknown_alternative`, `fail_todo_outside_function`, `fail_todo_ref_binding` (rev 2) |
| check/testdata/interop/cpp/stdlib/variant.carbon | `match`, `monostate`, `duplicate`, `fail_todo_too_many_alternatives`, `fail_todo_nested_by_value`, `fail_index_out_of_range` |
| check/testdata/interop/cpp/stdlib/fail_sum_types.carbon | `fail_todo_qualified_alternative`, `fail_todo_non_trivial` (listed at rev 2; it was in rev 1's source, B-m-1), `fail_conversion_mismatch`, `fail_core_optional_mismatch` (rev 2, replaces rev 1's `fail_todo_core_optional_argument`, now IN), `core_optional_argument_as`, `fail_todo_export_sum_type`, `fail_reverse_other_specialization` (rev 2), `fail_reverse_converting_class` (rev 2), `fail_todo_tuple_scrutinee` (rev 2), `fail_todo_if_arm` (rev 2), `fail_todo_template_conversion` (rev 2), `fail_todo_rvalue_ref_param` (rev 5, after a `sink.h` header split that includes `sum.h`; amended 2026-10-20, review fold: RR4-M1: a sum value to a lone C++ `T&&`, a `Core.Optional` to the `T&&` member of a `const T&`/`T&&` pair, and a value that selects the `const T&` member); the mock's `optional` gains a converting constructor from `optional<U>` (libc++'s shape) so the reverse splits reach it |
| check/testdata/interop/cpp/stdlib/sum_type_overload.carbon (rev 2; eight splits added at rev 3, amended 2026-10-20, review fold: RR-B1 / RR-B-1 / RR-m1; three at rev 4, amended 2026-10-20, review fold: RR3-M1 / RR3-m4) | `convert_first`, `convert_second`, `mismatch_first`, `not_mapped_first`, `reverse`, `generic_member`; rev 3: `tuple_member`, `tuple_mismatch_first`, `struct_member`, `array_member`, `tuple_reverse`, `tuple_core_optional`, `generic_tuple_member`; rev 4: `scalar_tuple_mismatch_first` (no sum type: the element probe of trunk's `ConvertAggregateElement`, whose second member returns `bool` so the call's type pins the member), `fail_todo_file_scope` (rev 3's `file_scope`, renamed: the first member is selected and the call gets the file-scope TODO), `fail_todo_template_overload` (the same at a template's instantiation, under ``unable to monomorphize specific``): the fourteen non-`fail_` splits compile with no diagnostic |
| check/testdata/interop/cpp/stdlib/fail_sum_types.carbon, at M-VA (rev 3; amended 2026-10-20, review fold: RR-M1; RR3-B1) | `fail_todo_pack_element` appended (VA-1's syntax exists only after M): the pack-element TODO, forward and reverse, for a pack of the C++ class or the sum type and, from rev 4, of a tuple, struct, array or class holding one (ten calls) |
| check/testdata/choice/optional_pointer_payload.carbon | `pointer`, `fail_todo_non_pointer_optional`, `fail_todo_nullptr_payload` (rev 2), `fail_todo_maybe_unformed_payload` (rev 2) |
| check/testdata/match/core_optional_view.carbon | `concrete`, `pointer`, `fail_todo_generic` (rev 2: rev 1's passing `generic`), `fail_todo_aggregate` (rev 2), `fail_todo_ref_binding` (rev 2), `fail_unknown_alternative` |
| check/testdata/interop/cpp/exceptions/fail_catching.carbon (existing; one split appended at rev 2) | `fail_nullptr_return`: `Cpp.nullptr_t` is not a catching success type (D-SV-8's narrowing) |
| lower/testdata/interop/cpp/std_sum_types.carbon | `optional` (match and the reverse conversion), `variant` (match and the reverse) |
| lower/testdata/match/constant_choice_scrutinee.carbon | one file (D-SV-9; rev 2's routed global) |
| interop/cpp/function/import/{carbon_fn_as_callable, decayed_param, function_ptr, method_ptr}.carbon (refills) | only `cpp_fn_ptr_type clang_function_pointer_type<N>` ids change (§0.6) |

`fail_todo_` marks a residue that a later slice lifts (W-275, W-276, W-277,
W-279, W-280, W-281, W-284, W-285, W-122, W-036, W-049, and W-177's narrowed
scope, named in the records only); `fail_` marks a permanent error. The
diagnostics coverage test (diagnostics/coverage_test.cpp, Bazel-only) is met by
construction: each of the eight new kinds appears in a `fail_` split
(CppSumTypeNotMapped and its four notes in fail_sum_types.carbon,
optional.carbon and variant.carbon, CppSumTypeMismatch and
CppSumTypeReverseMismatch in fail_sum_types.carbon, CoreOptionalNotMatchable in
core_optional_view.carbon).

_Break condition:_ if a mock diverges from libc++ in a way a program shows,
the mock follows libc++ and its goldens refill.

### §1.13 D-SV-13: conformance programs

All under the bullet "Control flow: matching — sum-type consumption incl.
std::variant/std::optional interop", EXPECT-EXIT 0. Differential programs
have no EXPECT-STDOUT (DIFF-1); every payload is computed at run time from a
seed the C++ side cannot fold away (R16(d)), and the oracle is a plain C++17
program that computes the same values with `std::optional` / `std::variant`
and prints them with `printf("%d\n", ...)`, as `Core.Print` lowers. Bodies:
Appendix A, copies of `$X/final/progs/`, each run on v4 against its oracle
(`$X/runs/progs-v4b.txt`; amended 2026-10-20, review fold: A-M2 / B-M-1 /
B-M-5 / A-m7: three programs changed, items 2, 4 and 5).

1.  **control_flow/match_sum_type_payload.carbon** (SKIP to PASS, the
    arbiter): the intended body, with the sketch's `default` arm removed and
    the removal stated in the header as design-directed, not a weakening
    (R16(b)): after the two alternative arms the `default` is the
    `MatchDefaultNeverMatches` error (§0.4 item 4), and without it the match is
    exhaustive (SF-7). EXPECT-STDOUT `7` stays (a non-differential program;
    the value is C++'s literal 7).
2.  **control_flow/match_std_optional_diff.carbon** + `.diff.cpp` (new, 11
    lines): `std::optional<int>` in both states on call results, `if`-`let`,
    `std::optional<int*>` engaged non-null, engaged null and empty (the
    payload `Core.Optional(i32*)`), `std::optional<std::int64_t>`, a generic
    `Unwrap[T]` over `StdOptional(T)`, and the one-step conversion of a C++
    `std::optional<int>` call result to `Core.Optional(i32)` (rev 1 converted
    a `StdOptional(i32)` value through the bridge; B-M-5).
3.  **control_flow/match_std_variant_diff.carbon** + `.diff.cpp` (new, 14
    lines): `std::variant<int, double>`, `<std::monostate, int>`,
    `<int, int>` by index, `<bool, long, double, int*>` across all four
    alternatives, and the nested shape `std::variant<std::optional<int>*, int>`
    matched again through the pointer; every match exhaustive, no `default`.
4.  **control_flow/match_core_optional_diff.carbon** + `.diff.cpp` (new, 7
    lines): `Core.Optional(i32)` both states, `Core.Optional(i32*)` both
    states, `if`-`let`, and a second concrete payload type through
    `CountSome(o: Core.Optional(i64))` (D-SV-7). Rev 1's `CountSome[T]` matched
    a symbolic payload, which the view does not admit in 0.1 (§1.7, W-177
    narrowed; A-M2 / B-M-1).
5.  **interop/cpp_sum_type_roundtrip_diff.carbon** + `.diff.cpp` (new, 16
    lines): the reverse direction: `StdOptional(i32)` computed and `.None`,
    passed by value and by `const&`; a `Core.Optional(i32)` passed to the same
    two parameters in one step (B-M-5); `StdVariant2(i32, f64)` with a payload
    computed from a seed (rev 1's `half` was the literal 2.5, A-m7),
    `(i32, i32)` by index and `((), i32)` passed to C++; a Carbon function
    with a `std::optional<int>` return called from C++ on both paths; a Carbon
    function taking a `std::variant<int, double>` from C++ and matching it.
6.  **control_flow/cpp_sum_type_library/** (new multi-unit: `source.carbon`,
    `main.carbon`, `main.diff.cpp`; 4 lines): the library converts at its API,
    the importer imports no C++ and matches.

_Break condition:_ a program that cannot be made to agree with its oracle
without changing the design is a finding against F-020, never a test edit.

### §1.14 D-SV-14: docs and records

Every text is written out in Appendix C (rewritten 2026-10-20, review fold:
B-M-3), so the plan reviews see it; D and Doc may only substitute the measured
values of the merged tree into the `<...>` placeholders Appendix C marks. Any
other change to an Appendix C text goes through a document review (both
reviewers of R29(c)) before the PR lands.

-   **docs/design/sum_types.md** gains a dated section "C++ `std::optional`
    and `std::variant` (fork, SV-1, YYYY-MM-DD)" after "User-defined sum
    types" (:91) and before "Alternatives considered" (:248), and one bullet
    in "Alternatives considered" for the rejected identity mapping
    (Appendix C.1). This is the page the fork's `choice` design lives on, as
    SL-2's span mapping was recorded beside `Slice`.
-   **docs/design/unions.md**: the sentence ending "the `std::variant` interop
    mapping built on choice." (:626-627) gains a link to that section
    (Appendix C.2).
-   **docs/design/optional.md** exists only on PR 56's and PR 57's branches;
    after M it is amended (dated, Appendix C.3) wherever it says
    `Core.Optional` is not matchable or that the `std::optional` mapping is
    undesigned: :102, :205, :329, the "Pattern matching" section (:442-458),
    :475-478 and the W-177 limit (:501-504), anchored on PR 57's text at
    628273444 (amended 2026-10-20, review fold: B-M-1 / B-M-3).
-   **Records** (commit R for the row, D for the rest; Appendix C.4 to C.9):
    W-011 DISCHARGED (both halves); W-177 stays OPEN with a dated narrowing
    note; W-275, W-276, W-277, W-279, W-280, W-281 and W-285 filed (§1.16; W-285
    added 2026-10-20, review fold: RR4-M1), W-284 filed at D once M-VA has
    landed (otherwise held until it lands; amended 2026-10-20, review fold:
    RR3-m1), and W-282 only if X-1 is on the merged trunk; notes appended to
    W-036, W-047, W-049, W-122 and W-252, and to W-263 if it is on the merged
    trunk and open (amended 2026-10-20, review fold: RR4-m1), naming the SV-1
    shapes that ride them; row 68 per §1.17; the decision-log entry "SV-1 /
    F-020: `std::optional` and `std::variant` interop mapping" with F-020, the
    F-015 amendment and D-SV-2 to D-SV-16 and its veto digest;
    fork/ORCHESTRATION.md's SV-1 row and Next actions item; the conformance
    README table regenerated with `runner.py --update-readme-table`.

_Break condition_ (added 2026-10-20, review fold: B-m-6): if sum_types.md is
re-platformed or DD-1's state L maps its sections differently, the section
moves to docs/design/interoperability/README.md with a link left behind.

### §1.15 D-SV-15: merge position

SV-1 is cut from trunk 5674fe88b and lands after PR 61 (TP-1), last of the
queue of §0.7. The merge commit M brings in the merged trunk (never a rebase),
resolving conflicts only; the composition rules of §0.7 apply; and the
records commits come after M, so they extend the merged trunk's record files.
_Break condition:_ if the merge order changes, the dry runs of §8.6 are
repeated against whatever has landed, and only the textual rules change.

### §1.16 Residues filed (W-275 to W-281, W-284, W-285; W-278 withdrawn; W-282, W-283 conditional; W-286 to W-294 held)

SV-1 reserves W-275 to W-294 (fork/ORCHESTRATION.md on trunk 254b935b2). The
re-scan of 2026-10-20 at rev 2 (command in §8.7, which now scans local branches
and every worktree's ledger as well; amended 2026-10-20, review fold: B-m-7)
covered 82 refs (`refs/remotes/origin/` and `refs/heads/`) and the ledgers of
the 15 worktrees `git worktree list` names (carbon-tp, -sc, -va, -op, -op2 and
the rest): no id in W-275 to W-294 anywhere; the highest filed id is W-274
(TP-1's); F-020 appears in no decision log (`$X/runs/ids-refs.txt`,
`ids-worktrees.txt`). TP-1's block W-250..W-274 is exhausted, so a further
residue of TP-1's running re-review takes the next free id, possibly W-275 on an
unpushed commit: the re-scan before D therefore includes the worktrees, and an
id taken by then moves SV-1's filing to the next free id in its block. The full
JSON of each item is Appendix C.4 (amended 2026-10-20, review fold: B-M-3).
Re-run at rev 3 (2026-10-20, the same command over 82 refs and 15 worktree
ledgers, `$Z/runs/ids-refs.txt`, `ids-worktrees.txt`): no id of the block
anywhere, the highest filed id still W-274, F-020 in no decision log. The
focused re-review asked for its pack residue as W-283; W-283 is already the
shrink line's conditional id (§3 item 7, Appendix C.4), so the residue takes the
next free id of the block, W-284 (amended 2026-10-20, review fold: RR-M1).
Re-run at rev 4 (2026-10-20, the same command over 83 refs and 15 worktree
ledgers, `$W/runs/ids-refs.txt`, `ids-worktrees.txt`, the grep widened to W-299;
amended 2026-10-20, review fold: all RR3 findings): no id of SV-1's block
anywhere; the highest filed id is now W-295, TP-1's (its block is W-295 to
W-299), on TP-1's pushed branch at 3d88e6a60, its local branch and the carbon-tp
worktree's ledger (rev 4 named the last two only; amended 2026-10-20, review
fold: RR4-m3); F-020 in no decision log. W-284 is filed at D once M-VA has
landed, and held until then (§3 items 8 and 10; amended 2026-10-20, review fold:
RR3-m1). Re-run at rev 5 (2026-10-20, the same command over 83 refs and 15
worktree ledgers, `$Y/runs/ids-refs.txt`, `ids-worktrees.txt`; amended
2026-10-20, review fold: all RR4 findings): no id of SV-1's block anywhere;
TP-1's W-295 to W-297 on its pushed branch at 281292d8f, its local branch and
the carbon-tp worktree; F-020 in no decision log. W-285, the `T&&` parameter
shape that rev 4 filed under W-279 as "no source expression", takes the next
free id of the block, and W-279 keeps the template form (amended 2026-10-20,
review fold: RR4-M1). Planned filings:

| Id | Title | Bullet | Bounds row 68? |
| --- | --- | --- | --- |
| W-275 | a `std::optional`/`std::variant` whose class is not trivially copyable and destructible, or with an alternative that imports as a class (a trivially copyable struct, a nested `std::optional`/`std::variant` by value), has no Carbon sum type | Type system: Sum types (W-010's SF-6 residue: the payload predicate admits no aggregates; non-trivial payloads are SF-6's post-0.1 item) | no: SF-6(a), the user's 0.1 decision, bounds every choice; the error-handling row's precedent attributes the same bound to W-010 |
| W-276 | a `std::variant` of more than eight alternatives has no Carbon sum type | this bullet | no: a declared design bound with a diagnostic; break condition: variadic `choice` |
| W-277 | a cv-qualified or reference alternative has no Carbon sum type; this fires on real libc++ classes, `std::variant<const int, double>` being trivially copyable (rationale corrected 2026-10-20, review fold: A-m4 / B-m-3) | this bullet | no: such a class still imports and its members work, the rule keeps the sum-type-to-class mapping one-to-one (§1.3), and the shape is diagnosed |
| W-278 | WITHDRAWN at rev 2, never filed: rev 1's "one-step `Core.Optional` conversion" is implemented (§1.7); the id stays unused | none | none |
| W-279 | a conversion to or from a C++ sum type that a template defers to its instantiation (TP-1's `PerformAction`), where no control flow can be built (amended 2026-10-20, review fold: RR4-M1: rev 4's row also held the conversion with no source expression, now W-285, and said every non-template form converts) | Generics: Integrated templates | no: the shape is a template's, the same conversion outside a template converts, and it is diagnosed at instantiation |
| W-280 | a `ref` payload binding on a mapped C++ or `Core.Optional` scrutinee is rejected, because the scrutinee is a by-value conversion | this bullet | no for the C++ classes: the payload is a scalar or pointer copy, `var` bindings work, and mutating the C++ object goes through its own API; for `Core.Optional` it is part of W-177's remaining scope (below) |
| W-281 | a C++ sum class nested in a tuple or struct scrutinee is not converted (`match on unsupported scrutinee type`) | this bullet | no: the whole-value scrutinee and every nesting through a Carbon sum type work, and the shape is the existing TODO |
| W-284 | (from M-VA, filed at D once M-VA has landed) a conversion to or from a C++ `std::optional`/`std::variant` for a VA-1 pack element (in an expansion body, or a pack converted to a pack of another element type), whose element is the C++ class, the sum type, a `Core.Optional`, or a tuple, struct, array or class holding one, is a semantics TODO; blocked by VA-1's W-219 (control flow inside an expansion body) (amended 2026-10-20, review fold: RR3-B1 / RR3-m1) | Generics: Definition-checked variadics | no: every non-pack form converts, a pack of the C++ class, of the sum type or of an aggregate holding either is forwarded unchanged (v06, v07, n10) and a pack literal converts element by element (v01, n09), and the shape is diagnosed |
| W-285 | (rev 5) a Carbon sum value or `Core.Optional(T')` passed as an initializing expression to a C++ non-`const` rvalue reference parameter `T&&`, alone or the member C++ prefers to a `const T&` sibling (`std::vector::push_back`), is a semantics TODO (``... with no source expression``): the parameter's initialization is located at its C++ declaration, which gives the conversion's branches no parse node (amended 2026-10-20, review fold: RR4-M1) | this bullet | no: the row's arbiter is the consumption of C++ values by `match`, which the shape does not touch, and Carbon to C++ converts by value, `const&` and `const&&` (w14, x01), a value argument reaches the `const T&` member of a pair (x14, x16), a C++ call's result binds the `T&&` (r1, x08), and the shape is diagnosed |
| W-282 | (conditional) TP-1-origin: a `match` on a template-dependent `choice` value stops the compiler at pattern_match.cpp:1409, where trunk gives W-252's TODO (X-1; x19) | Generics: Integrated templates | filed by SV-1 at D only if TP-1 has not filed it and x19 still stops the merged trunk; otherwise unused. Predicted unused: TP-1's round-10 head eafca5cb9 fixes X-1 (x19 compiles and prints 0 on tpv6; amended 2026-10-20, review fold: RR3-m3) |

**W-177 (OP-1's, on row 68's bullet) stays OPEN** with a dated narrowing note
(Appendix C.5; amended 2026-10-20, review fold: A-M2 / B-M-1): since SV-1,
`.Some`/`.None` patterns work on a `Core.Optional(T)` whose `T` is a concrete
choice payload type; open are symbolic payloads, payloads outside SF-6, `ref`
payload bindings (W-280's `Core.Optional` half) and copy-free matching, so
EX-M-5, EX-M-6 and the D-OP-4 divergence still wait on it. **It bounds row 68**
(one sentence, R17): OP-1's own row text names `Core.Optional`'s matchability
as part of the row's missing half, and generic and by-reference matching of
`Core.Optional` is still missing, so DONE would claim more than SV-1 delivers.

Riding existing items (a note each, no new id; Appendix C.6): W-036 (the
conversion at file scope, or in a parameter's default value; amended 2026-10-20,
review fold: RR4-m2), W-047 (an importer without the header's C++ import), W-049
(a `Core.CppCompat` sum type in an exported signature), W-122 (the conversion
inside an `if`-expression arm), W-252 (TP-1's: a template-dependent scrutinee),
W-263 (TP-1's, filed on PR 61: a constant tuple or struct holding a sum-type
constant stops lowering as W-263's nested constants do; its note is appended
only if W-263 is on the merged trunk and open; amended 2026-10-20, review fold:
RR4-m1). Discharged: W-011 (both halves).

### §1.17 D-SV-16: the row-68 disposition rule

Rewritten 2026-10-20 (review fold: A-M2 / B-M-1 / B-M-3). Row 68 moves PARTIAL
to DONE exactly when, at the records commit R: (1) the arbiter un-SKIPs and
passes; (2) the five new programs pass against their oracles; (3) W-011's
arbiter ("a Carbon match over an imported std::optional/std::variant works, in
executed tests") is met by (1) and (2); (4) every open item on the row's
bullet is non-bounding by §1.16's column, W-177 included if PR 56 has filed it
on the merged trunk; and (5) every SV-1 residue is non-bounding. Otherwise the
row stays PARTIAL with each failing condition named. Rev 1 wrote condition 4
as "W-177 is discharged by match_core_optional_diff", which the view cannot
meet (§1.7).

**Predicted: PARTIAL** (rev 1 predicted DONE), on condition 4 alone: W-177
stays open and bounds the row (§1.16). The header does not move (30 DONE / 21
PARTIAL tree-relative; absolute counts are re-quoted from the merged trunk's
header at R, never derived, R9). If W-177 is not on the merged trunk (PR 56 not
merged), conditions 1 to 5 hold and the row moves to DONE, +1 DONE / -1
PARTIAL. The row's new third column, composed over PR 56's row
(fork/gap-analysis.md:70 on 379f20f67, the same text at :75 on PR 57's head
628273444), with the fallback rule if the merged row differs, is Appendix C.7.

### §1.18 Decision index

Amended 2026-10-20 (review fold: all findings; B-m-6 for the two break
conditions rev 1 lacked).

| Id | Decision | Break condition (one sentence) |
| --- | --- | --- |
| F-020 (D-SV-1) | C++ class kept; sum type = specific of a prelude generic choice in `Core.CppCompat` (`StdOptional`, `StdVariant1..8`), nameable (a departure from SF-8's default lean, recorded for veto; SF-9(b)'s two-Optional cost adopted); by-value conversion both ways; `Core.Optional` bridged in one step for non-pointer payloads; F-015 amended | the owner vetoes nameable sum types, variadic choices, the `Match` interface, a choice-based `Core.Optional`, or an upstream mapping |
| D-SV-2 | `.Alt<i>` by index; `std::monostate` is `()`, in a variant or an optional; duplicates by index; 1 to 8 alternatives; nesting by pointer only | variadic choices or aggregate payloads |
| D-SV-3 | admitted = trivially copyable class, at most 8, unqualified alternatives that pass SF-6's predicate; else `CppSumTypeNotMapped` | SF-6 admits aggregates or non-trivial payloads, or the reverse conversion can remember its source class |
| D-SV-4 | C++ to Carbon in convert.cpp's builtin conversion and the scrutinee gate; every conversion a probe performs, an aggregate's element conversions included, has `diagnose` false (SV-1 passes it through `ConvertAggregateElement`) and builds nothing; a non-diagnosing conversion decides from the types alone, and where the committed one cannot be built the call gets the TODO, never a later member; a `Core.Optional` target with an unmatchable payload is not the hook's; a template-dependent side is deferred; accessors through existing thunks; branches per arm; function scope only, and from M no pack element or projection of one (amended 2026-10-20, review fold: RR-B1 / RR-B-1 / RR-m3 / RR-M1; RR3-M1 / RR3-B1) | a non-diagnosing caller keeps a non-constant result, a new path drops an element's `diagnose`, a pack element reaches the hook through a step the walk does not follow, or W-036, W-279 or W-284 must be lifted (then a synthesized function per specialization); W-285 lifts by the argument's own parse node (mutant M22; amended 2026-10-20, review fold: RR4-M1) |
| D-SV-5 | Carbon to C++ by default construction and `emplace`, only to the class whose sum type the value is; `InventClangArg` maps the sum type, and a `Core.Optional(T)` with a matchable non-pointer payload, to the class; a fresh value passed to a C++ `T&&` parameter is W-285's TODO (amended 2026-10-20, review fold: RR4-M1) | an export path for sum types, C++'s converting constructors must be honored, or a C++ `T&&` parameter must take a fresh value (W-285) |
| D-SV-6 | the shared scrutinee gate converts before the shape gate; `ref` bindings and nested C++ classes are not consumed (W-280, W-281) | the `Match` interface |
| D-SV-7 | the bridge; the one-step conversions both ways for non-pointer payloads; a `Core.Optional(T)` scrutinee is matched as the view for a concrete choice payload `T` only; W-177 narrowed, not discharged | W-058 or the owner wants matching without a copy, by reference or generically; a rename; a change to the pointer mapping |
| D-SV-8 | the SF-6 predicate also admits `Core.Optional(T*)`, by name; nothing else changes, at any of its four sites | PR 57 changes what the walk reaches, or SF-6 admits non-`Copy` payloads |
| D-SV-9 | a value constant indexed by a constant GEP is addressed through `FileContext::GetConstant`'s cached global | upstream stops folding such accesses |
| D-SV-10 | generics, libraries, constants, overload sets work; deduction by its rule; template conversions deferred and then W-279's TODO, an `overload fn` call's included (amended 2026-10-20, review fold: RR3-M1) | deduction sees through conversions, or TP-1 can splice control flow into an instantiation |
| D-SV-11 | one error kind plus four notes, two mismatch errors and `CoreOptionalNotMatchable`; the C++ spelling without tag keyword; `NoReason` emits | the diagnostics hook or a reviewer wants separate kinds |
| D-SV-12 | eight new goldens with a mocked `sum.h`, one appended split, four refills | a mock diverges from libc++ in a way a program shows |
| D-SV-13 | one un-SKIP, five new programs, all differential but the arbiter | an oracle disagreement is a design finding |
| D-SV-14 | sum_types.md dated section, unions.md link, optional.md amendments, records; every text in Appendix C, frozen by the plan reviews | sum_types.md is re-platformed or DD-1 maps its sections differently |
| D-SV-15 | lands after PR 61 through M, then M-VA (the pack-element rule of §3 item 8, covering an element and its projections; amended 2026-10-20, review fold: RR-M1; RR3-B1) | the merge order changes, or PR 59 no longer lands first (M-VA then waits for it) |
| D-SV-16 | the row moves to DONE under §1.17's five conditions; predicted PARTIAL on W-177 | any condition fails, or W-177 closes |

## §2 Spec, file by file

### §2.0 Conventions

Rewritten 2026-10-20 (review fold: all findings). The code below is the
prototype v4 (`$X/final/final.diff`, the files in `$X/final/src/`), relinked
and measured as §0.6 records, formatted with the CI-pinned clang-format 21.1.8
(R18), with one difference from the relinked build: kind.def. v4 appends the
eight new kinds at the end of kind.def so that a relink keeps every existing
kind's value; the diff below inserts them after
`CppExportResultNeedsExpectedHeader`, which changes no diagnostic text and only
renumbers kinds in a full build. Every diagnostic text in this plan is
therefore measured, not hand-predicted (rev 1's §2.10 heading said
"hand-predicted"). BUILD is not read by the relink; its two lines are as in
rev 1. One line of custom_type_mapping.cpp was re-wrapped by clang-format after
v4 was built (whitespace only), which makes its hunks rev 1's again. Paths are
relative to the worktree.

Rev 3 (amended 2026-10-20, review fold: all RR findings): sum_type.h,
sum_type.cpp and convert.cpp below are the prototype v5's
(`$Z/final/final.diff`, the files in `$Z/final/src/`, formatted with the same
clang-format; v5 appends the kinds as v4 did); every other file of §2 is rev
2's, unchanged. The land-time hunk M-VA (§3 item 8) is not part of this diff:
it names `SemIR::PackElement`, which exists only once PR 59 has landed, and is
`$Z/land/m-va-pack-element.diff`, shown in §3 item 8.

Rev 4 (amended 2026-10-20, review fold: all RR3 findings): sum_type.h and
sum_type.cpp below are the prototype v6's (`$W/final/final.diff`, the files in
`$W/final/src/`, formatted as before); convert.cpp and every other file of §2
are rev 3's, unchanged. The non-diagnosing path no longer calls
`CanBuildBranches`, which loses its `diagnose` parameter and always emits
(RR3-M1); the land-time hunk M-VA is `$W/land/m-va-pack-element.diff` (RR3-B1).

### §2.1 core/prelude/types/cpp/sum.carbon (new) and core/prelude/types.carbon

**Invariant:** the nine choices declare nothing but alternatives, so every
specific's layout, constants, `Copy` and `Destroy` come from the existing
`choice` machinery; the two impls use only `Optional`'s public API. The file
imports `prelude/types/optional` (for the bridge) and `prelude/operators`
(the `match` in the first impl tests the discriminant through `Core.EqWith`,
which inside package `Core` must be imported explicitly, as result.carbon
does).

The file is rev 1's, unchanged at rev 2 (its comments say what the toolchain
does with it; `$X/final/src/core/prelude/types/cpp/sum.carbon` is byte-equal to
the block below).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/cpp/sum";

import library "prelude/copy";
import library "prelude/destroy";
import library "prelude/operators";
import library "prelude/types/optional";
import library "prelude/types/uint";

// The Carbon sum types of C++ `std::optional<T>` and `std::variant<Ts...>`
// (fork decision F-020; docs/design/sum_types.md, "C++ `std::optional` and
// `std::variant`"). The C++ class stays imported as a class; where a `choice`
// is expected -- a `match`, `if`-`let`, `while`-`let` or `let`-`else`
// scrutinee, or a conversion to one of these types -- the toolchain converts
// it through its C++ accessors (check/cpp/sum_type.cpp), and a value of one of
// these types converts back to the C++ class through its default constructor
// and `emplace`. Neither direction reads or writes the other side's bytes:
// libc++'s layouts are not the `choice` layout.
//
// `StdOptional(T)` is the docs/design/sum_types.md `Optional(T)` declaration.
// A `std::variant` alternative has no name in C++, so `StdVariant<N>` names
// its alternatives by C++ index: `.Alt0` is `index() == 0`. A
// `std::monostate` alternative has the payload `()`.

namespace CppCompat;

choice CppCompat.StdOptional(T: type) {
  Some(value: T),
  None
}

choice CppCompat.StdVariant1(T0: type) {
  Alt0(value: T0)
}

choice CppCompat.StdVariant2(T0: type, T1: type) {
  Alt0(value: T0),
  Alt1(value: T1)
}

choice CppCompat.StdVariant3(T0: type, T1: type, T2: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2)
}

choice CppCompat.StdVariant4(T0: type, T1: type, T2: type, T3: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3)
}

choice CppCompat.StdVariant5(T0: type, T1: type, T2: type, T3: type, T4: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3),
  Alt4(value: T4)
}

choice CppCompat.StdVariant6(
    T0: type, T1: type, T2: type, T3: type, T4: type, T5: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3),
  Alt4(value: T4),
  Alt5(value: T5)
}

choice CppCompat.StdVariant7(
    T0: type, T1: type, T2: type, T3: type, T4: type, T5: type, T6: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3),
  Alt4(value: T4),
  Alt5(value: T5),
  Alt6(value: T6)
}

choice CppCompat.StdVariant8(
    T0: type, T1: type, T2: type, T3: type, T4: type, T5: type, T6: type,
    T7: type) {
  Alt0(value: T0),
  Alt1(value: T1),
  Alt2(value: T2),
  Alt3(value: T3),
  Alt4(value: T4),
  Alt5(value: T5),
  Alt6(value: T6),
  Alt7(value: T7)
}

// `StdOptional(T)` and `Core.Optional(T)` convert to each other by value,
// through `Optional`'s public API (`Some`, `None`, `HasValue`, `Get`); neither
// representation is assumed (the pointer niche and the storage are
// prelude/types/optional.carbon's). The toolchain also matches a
// `Core.Optional(T)` scrutinee as its `StdOptional(T)` view, through the
// second impl (fork/sumtype-interop/plan.md §1.7).
impl forall [T: Copy & Destroy]
    CppCompat.StdOptional(T) as ImplicitAs(Optional(T)) {
  fn Convert(self) -> Optional(T) {
    match (self) {
      case .Some(value: T) => {
        return Optional(T).Some(value);
      }
      case .None => {
        return Optional(T).None();
      }
    }
    // Unreachable: reachability does not consult `match` exhaustiveness.
    return Optional(T).None();
  }
}

impl forall [T: Copy & Destroy]
    Optional(T) as ImplicitAs(CppCompat.StdOptional(T)) {
  fn Convert(self) -> CppCompat.StdOptional(T) {
    if (self.HasValue()) {
      return CppCompat.StdOptional(T).Some(self.Get());
    }
    return CppCompat.StdOptional(T).None;
  }
}
```

<!-- google-doc-style-resume -->

core/prelude/types.carbon exports it beside the other `cpp/` files:

<!-- google-doc-style-ignore -->

```diff
--- a/core/prelude/types.carbon
+++ b/core/prelude/types.carbon
@@ -12,6 +12,7 @@
 export import library "prelude/types/cpp/int";
 export import library "prelude/types/cpp/nullptr";
 export import library "prelude/types/cpp/slice";
+export import library "prelude/types/cpp/sum";
 export import library "prelude/types/cpp/void";
 export import library "prelude/types/float";
 export import library "prelude/types/float_literal";
```

<!-- google-doc-style-resume -->

### §2.2 toolchain/check/cpp/custom_type_mapping.{h,cpp}

**Invariant:** the matchers recognize the specialization only (`std`
namespace, the template's name, the argument shapes); they decide nothing
about admission, which needs the Carbon import and lives in sum_type.cpp.
`IsStdMonostate` matches the unqualified, non-template `std::monostate`.

Unchanged at rev 2 (`$X/final/final.diff` carries these hunks as rev 1 did).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/cpp/custom_type_mapping.h
+++ b/toolchain/check/cpp/custom_type_mapping.h
@@ -7,6 +7,7 @@

 #include "clang/AST/DeclCXX.h"
 #include "clang/AST/Type.h"
+#include "llvm/ADT/SmallVector.h"

 namespace Carbon::Check {

@@ -38,6 +39,33 @@
 auto GetCustomCppTypeMapping(const clang::CXXRecordDecl* record_decl)
     -> CustomCppTypeMapping;

+// A C++ sum type that maps by value to a Carbon `choice`
+// (docs/design/sum_types.md, "C++ `std::optional` and `std::variant`"): the
+// C++ class stays imported as a class, and its alternatives are listed here in
+// C++ order -- `std::optional<T>` has the single `T` (its `Some` alternative;
+// `None` carries nothing), `std::variant<Ts...>` has `Ts...`.
+struct CppSumTypeMapping {
+  enum Kind : uint8_t {
+    None,
+    // A `std::optional<T>` specialization.
+    Optional,
+    // A `std::variant<Ts...>` specialization.
+    Variant,
+  };
+
+  Kind kind = None;
+  // The C++ alternative types, in C++ order.
+  llvm::SmallVector<clang::QualType, 4> alternative_types;
+};
+
+// Determines whether `record_decl` is a `std::optional` or `std::variant`
+// specialization, and if so returns its alternatives.
+auto GetCppSumTypeMapping(const clang::CXXRecordDecl* record_decl)
+    -> CppSumTypeMapping;
+
+// Returns whether `type` is the unqualified `std::monostate`.
+auto IsStdMonostate(clang::QualType type) -> bool;
+
 }  // namespace Carbon::Check

 #endif  // CARBON_TOOLCHAIN_CHECK_CPP_CUSTOM_TYPE_MAPPING_H_
```

<!-- google-doc-style-resume -->

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/cpp/custom_type_mapping.cpp
+++ b/toolchain/check/cpp/custom_type_mapping.cpp
@@ -120,6 +120,28 @@
       "span", TemplateArgumentsAre(
                   {TypeTemplateArgument(AnyType), DynamicExtent}))(record_decl);
 }
+// A matcher for a `std::optional<T>` specialization: one type argument.
+static auto StdOptional(const clang::CXXRecordDecl* record_decl) -> bool {
+  return StdClassTemplate(
+      "optional",
+      TemplateArgumentsAre({TypeTemplateArgument(AnyType)}))(record_decl);
+}
+
+// A matcher for a `std::variant<Ts...>` specialization: its single template
+// argument is the pack of alternative types, each a type.
+static auto StdVariant(const clang::CXXRecordDecl* record_decl) -> bool {
+  return StdClassTemplate(
+      "variant", [](const clang::TemplateArgumentList& args) -> bool {
+        if (args.size() != 1 ||
+            args[0].getKind() != clang::TemplateArgument::Pack) {
+          return false;
+        }
+        return llvm::all_of(
+            args[0].pack_elements(), [](const clang::TemplateArgument& arg) {
+              return arg.getKind() == clang::TemplateArgument::Type;
+            });
+      })(record_decl);
+}
 }  // end namespace Matchers

 auto GetCustomCppTypeMapping(const clang::CXXRecordDecl* record_decl)
@@ -140,4 +162,35 @@
   return {.kind = CustomCppTypeMapping::None};
 }

+auto GetCppSumTypeMapping(const clang::CXXRecordDecl* record_decl)
+    -> CppSumTypeMapping {
+  if (Matchers::StdOptional(record_decl)) {
+    const auto& args = cast<clang::ClassTemplateSpecializationDecl>(record_decl)
+                           ->getTemplateArgs();
+    return {.kind = CppSumTypeMapping::Optional,
+            .alternative_types = {args[0].getAsType()}};
+  }
+  if (Matchers::StdVariant(record_decl)) {
+    const auto& args = cast<clang::ClassTemplateSpecializationDecl>(record_decl)
+                           ->getTemplateArgs();
+    CppSumTypeMapping mapping = {.kind = CppSumTypeMapping::Variant};
+    for (const auto& arg : args[0].pack_elements()) {
+      mapping.alternative_types.push_back(arg.getAsType());
+    }
+    return mapping;
+  }
+  return {.kind = CppSumTypeMapping::None};
+}
+
+auto IsStdMonostate(clang::QualType type) -> bool {
+  const auto* record_decl = type->getAsCXXRecordDecl();
+  if (type.hasQualifiers() || !record_decl ||
+      isa<clang::ClassTemplateSpecializationDecl>(record_decl)) {
+    return false;
+  }
+  const auto* identifier = record_decl->getIdentifier();
+  return identifier && identifier->isStr("monostate") &&
+         record_decl->isInStdNamespace();
+}
+
 }  // namespace Carbon::Check
```

<!-- google-doc-style-resume -->

### §2.3 toolchain/check/cpp/sum_type.h (new)

**Invariant** (rewritten 2026-10-20, review fold: A-B1 / B-B-1 / B-m-9):
`GetCppSumType` and `GetCoreOptionalView` emit no diagnostic (except where the
prelude itself is broken: `CppSumType::AlreadyDiagnosed`) and are safe to call
on any type, so the hooks can consult them on every conversion and every
scrutinee; `TryConvertCppSumType` takes the conversion's `diagnose` flag and,
when it is false, emits nothing, builds no block, and decides from the types
alone, so a point where the committed conversion cannot be built is that
conversion's TODO, not a rejection (amended 2026-10-20, review fold: RR-m2: its
stand-in is never a constant; RR3-M1: rev 3 also rejected where
`CanBuildBranches` fails).

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_CHECK_CPP_SUM_TYPE_H_
#define CARBON_TOOLCHAIN_CHECK_CPP_SUM_TYPE_H_

#include "clang/AST/Type.h"
#include "toolchain/check/context.h"
#include "toolchain/sem_ir/ids.h"

namespace Carbon::Check {

// The Carbon sum type that a C++ `std::optional` or `std::variant`
// specialization maps to by value (fork decision F-020): the `Core.CppCompat`
// choice `StdOptional(T')` or `StdVariant<N>(T0', ..., T<N-1>')`.
struct CppSumType {
  enum Status : uint8_t {
    // The type is not a `std::optional` or `std::variant` specialization.
    NotSumType,
    // The type is one, and `carbon_type_id` is its Carbon sum type.
    Mapped,
    // The type is one, but it has no Carbon sum type in 0.1; diagnosed by
    // `DiagnoseCppSumTypeNotMapped`.
    NotMapped,
  };
  Status status = NotSumType;
  // The C++ class type.
  SemIR::TypeId cpp_type_id = SemIR::TypeId::None;
  // For `Mapped`: the Carbon choice type.
  SemIR::TypeId carbon_type_id = SemIR::TypeId::None;
  // True for `std::optional`, false for `std::variant`.
  bool is_optional = false;
  // For `NotMapped`: why, and the index of the first alternative that is not
  // admitted (-1 when the reason is not about one alternative).
  enum Reason : uint8_t {
    // The `Core.CppCompat` choice could not be completed; diagnosed with no
    // note.
    NoReason,
    // Forming the `Core.CppCompat` choice failed, and that failure was
    // diagnosed where it happened; nothing more is emitted.
    AlreadyDiagnosed,
    TooManyAlternatives,
    NotTriviallyCopyable,
    QualifiedAlternative,
    AlternativeNotAdmitted,
  };
  Reason reason = NoReason;
  // For `TooManyAlternatives`: how many.
  int num_alternatives = 0;
  int bad_alternative = -1;
  // For `AlternativeNotAdmitted` and `QualifiedAlternative`: the C++ type of
  // that alternative.
  clang::QualType bad_alternative_type;
};

// Classifies `type_id`. Forms and completes the Carbon sum type when the C++
// type is mapped. Emits no diagnostic, except where the prelude itself is
// broken (no `Core.CppCompat`): see `CppSumType::AlreadyDiagnosed`.
auto GetCppSumType(Context& context, SemIR::LocId loc_id, SemIR::TypeId type_id)
    -> CppSumType;

// Returns the C++ class that `carbon_type_id` maps to when it is offered to
// C++ overload resolution: for a `Core.CppCompat.StdOptional` or
// `StdVariant<N>` specific, the `std::optional` or `std::variant`
// specialization of the mapped argument types; for a `Core.Optional(T)` whose
// payload is matchable (`GetCoreOptionalView`) and not a pointer type,
// `std::optional<T'>`. A null type otherwise, or if the TU has no matching C++
// template.
auto MapCarbonSumTypeToCpp(Context& context, SemIR::LocId loc_id,
                           SemIR::TypeId carbon_type_id) -> clang::QualType;

// Diagnoses a `NotMapped` sum type at `loc_id`.
auto DiagnoseCppSumTypeNotMapped(Context& context, SemIR::LocId loc_id,
                                 const CppSumType& sum_type) -> void;

// Converts `value_id`, of the C++ class type of the `Mapped` `sum_type`, to a
// value of its Carbon sum type, through the C++ accessors. Branches, so it
// needs a function body and a source expression; elsewhere it emits a TODO and
// returns `ErrorInst`.
auto ConvertCppSumToCarbon(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId;

// Converts `value_id`, of the Carbon sum type of the `Mapped` `sum_type`, to a
// value of its C++ class type, through the C++ constructors. Branches, as
// `ConvertCppSumToCarbon` does.
auto ConvertCarbonSumToCpp(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId;

// The conversion hook of `PerformBuiltinConversion`. Converts `value_id` by
// value when it is a C++ `std::optional`/`std::variant` and the target is its
// Carbon sum type or, for `std::optional<T>`, a `Core.Optional(T')` whose
// payload is matchable; or when it is a `Core.CppCompat` sum type or such a
// `Core.Optional(T')` and the target is a C++ class. Returns `None` when
// neither side is involved, or either side is template-dependent (the
// conversion is then deferred to instantiation), and `ErrorInst` for a
// mismatch, which is diagnosed when `diagnose` is true. When `diagnose` is
// false -- a conversion that the caller only tests: an `overload fn` candidate
// probe, the element conversions of an aggregate argument included, or
// deduction -- it decides from the types alone, emits nothing and builds no
// control flow; its result is never a constant. Where the committed conversion
// cannot be built (at file scope, at a template's instantiation), that
// conversion emits the TODO.
auto TryConvertCppSumType(Context& context, SemIR::LocId loc_id,
                          SemIR::InstId value_id, SemIR::TypeId target_type_id,
                          bool diagnose) -> SemIR::InstId;

// The `match` view of a `Core.Optional(T)` scrutinee (SV-1, D-SV-7): the
// docs/design/sum_types.md `Optional(T)` choice
// `Core.CppCompat.StdOptional(T)`, which the prelude's `ImplicitAs` impl
// converts it to by value through `HasValue()` and `Get()`.
struct CoreOptionalView {
  enum Status : uint8_t {
    // The type is not a `Core.Optional` specific.
    NotCoreOptional,
    // `view_type_id` is the view.
    Matchable,
    // Its payload type is symbolic: the view's payload check would happen
    // only at monomorphization, so it is not formed.
    SymbolicPayload,
    // Its payload type is not a 0.1 choice payload type (SF-6).
    PayloadNotAdmitted,
  };
  Status status = NotCoreOptional;
  SemIR::TypeId payload_type_id = SemIR::TypeId::None;
  SemIR::TypeId view_type_id = SemIR::TypeId::None;
};

// Classifies `type_id`; forms the view only when it is `Matchable`. Emits no
// diagnostic.
auto GetCoreOptionalView(Context& context, SemIR::LocId loc_id,
                         SemIR::TypeId type_id) -> CoreOptionalView;

// Diagnoses a `Core.Optional` scrutinee that is not `Matchable`.
auto DiagnoseCoreOptionalNotMatchable(Context& context, SemIR::LocId loc_id,
                                      SemIR::TypeId type_id,
                                      const CoreOptionalView& view) -> void;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_CPP_SUM_TYPE_H_
```

<!-- google-doc-style-resume -->

### §2.4 toolchain/check/cpp/sum_type.cpp (new)

**Invariants** (rewritten 2026-10-20, review fold: A-B1 / B-B-1 / A-B2 / A-M1 /
A-M2 / B-M-1 / B-M-5 / A-m3 / B-m-9): (1) admission is decided before the
specific is formed, in the order of §1.3's rules, and records the first failing
rule for the note; the `Core.Optional` view checks its payload the same way
before forming `StdOptional(T)`; (2) the conversion reads the C++ value only
through `has_value()`/`value()` or `index()`/`std::get<I>()`, on a value
expression, and builds the C++ value only through the default constructor and
`emplace`; (3) every arm of a conversion initializes the one result storage and
owns its own temporaries (`EmitArms`, the `if`-expression operand discipline);
(4) a committed conversion that cannot branch -- outside a function body, or
with no parse node, and from M-VA for a pack element or a projection of one --
emits a TODO and builds no block, so `EmitArms` never sees a `None` node (it
CHECKs); (5) `TryConvertCppSumType` returns `None` for every pair of types it
does not own (a `Core.Optional` target whose payload is not matchable included)
and for a template-dependent side, so no other conversion changes; (6) when
`diagnose` is false it emits nothing and builds no block, returning `ErrorInst`
for a mismatch or `MakeTestedConversion`'s non-constant stand-in for a
convertible pair, and it does not call `CanBuildBranches`, whose limits are the
committed conversion's TODOs (rev 3 called it there; amended 2026-10-20, review
fold: RR3-M1); every conversion a probe performs reaches it with `diagnose`
false, an aggregate's element conversions included (convert.cpp passes the flag
through `ConvertAggregateElement`, §2.5); (7) a Carbon sum value converts only
to the C++ class whose sum type it is (amended 2026-10-20, review fold: RR-B1 /
RR-B-1 / RR-m2 / RR-m3 / RR-M1).

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/cpp/sum_type.h"

#include <iterator>

#include "clang/AST/DeclCXX.h"
#include "clang/AST/DeclTemplate.h"
#include "clang/Sema/Sema.h"
#include "toolchain/check/call.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/core_identifier.h"
#include "toolchain/check/cpp/custom_type_mapping.h"
#include "toolchain/check/cpp/import.h"
#include "toolchain/check/cpp/overload_resolution.h"
#include "toolchain/check/cpp/type_mapping.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/member_access.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/operator.h"
#include "toolchain/check/pattern_match.h"
#include "toolchain/check/type.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/diagnostics/format_providers.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// The largest `std::variant` with a Carbon sum type: `Core.CppCompat` declares
// `StdVariant1` to `StdVariant8` (core/prelude/types/cpp/sum.carbon).
static constexpr int MaxVariantAlternatives = 8;

// Returns the C++ class declaration behind `type_id`, or null.
static auto GetCppClassDecl(Context& context, SemIR::TypeId type_id)
    -> const clang::CXXRecordDecl* {
  auto class_type = context.types().TryGetAs<SemIR::ClassType>(type_id);
  if (!class_type) {
    return nullptr;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (!class_info.scope_id.has_value()) {
    return nullptr;
  }
  auto decl_id =
      context.name_scopes().Get(class_info.scope_id).clang_decl_context_id();
  if (!decl_id.has_value()) {
    return nullptr;
  }
  return dyn_cast<clang::CXXRecordDecl>(
      context.clang_decls().Get(decl_id).decl());
}

// Returns the Carbon payload type of one C++ alternative, or `None` when it is
// not admitted: `std::monostate` is `()`, and any other type must map to a
// type the choice payload rule admits (`IsInSliceChoicePayloadType`, SF-6).
static auto MapAlternative(Context& context, SemIR::LocId loc_id,
                           clang::QualType type) -> SemIR::TypeId {
  if (IsStdMonostate(type)) {
    return GetTupleType(context, {});
  }
  auto type_expr = ImportCppType(context, loc_id, type);
  if (!type_expr.inst_id.has_value() ||
      type_expr.type_id == SemIR::ErrorInst::TypeId) {
    return SemIR::TypeId::None;
  }
  if (!TryToCompleteType(context, type_expr.type_id, loc_id) ||
      !IsInSliceChoicePayloadType(context, type_expr.type_id)) {
    return SemIR::TypeId::None;
  }
  return type_expr.type_id;
}

// The `Core.CppCompat` names, with static storage: the identifier table keeps
// a reference to the spelling it is given.
static auto GetCarbonSumTypeName(bool is_optional, int num_alternatives)
    -> llvm::StringLiteral {
  static constexpr llvm::StringLiteral VariantNames[] = {
      "StdVariant1", "StdVariant2", "StdVariant3", "StdVariant4",
      "StdVariant5", "StdVariant6", "StdVariant7", "StdVariant8"};
  static_assert(std::size(VariantNames) == MaxVariantAlternatives);
  return is_optional ? llvm::StringLiteral("StdOptional")
                     : VariantNames[num_alternatives - 1];
}

// Forms `Core.CppCompat.<name>(args...)`, or returns `ErrorInst::TypeId` after
// the failure was diagnosed where it happened.
static auto FormCarbonSumType(Context& context, SemIR::LocId loc_id,
                              llvm::StringLiteral name,
                              llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> SemIR::TypeId {
  auto cpp_compat_id =
      LookupNameInCore(context, loc_id, CoreIdentifier::CppCompat);
  if (cpp_compat_id == SemIR::ErrorInst::InstId) {
    return SemIR::ErrorInst::TypeId;
  }
  auto generic_id = PerformMemberAccess(context, loc_id, cpp_compat_id,
                                        AddIdentifierName(context, name));
  return ExprAsType(context, loc_id,
                    PerformCall(context, loc_id, generic_id, arg_ids))
      .type_id;
}

auto GetCppSumType(Context& context, SemIR::LocId loc_id, SemIR::TypeId type_id)
    -> CppSumType {
  type_id = context.types().GetUnqualifiedType(type_id);
  const auto* record_decl = GetCppClassDecl(context, type_id);
  if (!record_decl) {
    return {};
  }
  auto mapping = GetCppSumTypeMapping(record_decl);
  if (mapping.kind == CppSumTypeMapping::None) {
    return {};
  }
  CppSumType result = {
      .status = CppSumType::NotMapped,
      .cpp_type_id = type_id,
      .is_optional = mapping.kind == CppSumTypeMapping::Optional};
  int num_alternatives = mapping.alternative_types.size();
  if (num_alternatives < 1 || num_alternatives > MaxVariantAlternatives) {
    result.reason = CppSumType::TooManyAlternatives;
    result.num_alternatives = num_alternatives;
    return result;
  }
  // The C++ class must itself be trivially copyable and destructible: the
  // reverse conversion builds a C++ object that no destructor call ends, and
  // the scrutinee's C++ temporary is destroyed by a call that must do nothing.
  if (!record_decl->isTriviallyCopyable() ||
      !record_decl->hasTrivialDestructor()) {
    result.reason = CppSumType::NotTriviallyCopyable;
    return result;
  }
  llvm::SmallVector<SemIR::InstId> arg_ids;
  for (auto [index, alternative] : llvm::enumerate(mapping.alternative_types)) {
    // A qualified or reference alternative has no by-value payload (SV-1
    // D-SV-3): `std::variant<const int, double>`, `std::variant<int&>`. Two
    // C++ classes would otherwise share one sum type, and the reverse
    // conversion could reach only one of them.
    if (alternative.hasQualifiers() || alternative->isReferenceType()) {
      result.reason = CppSumType::QualifiedAlternative;
      result.bad_alternative = index;
      result.bad_alternative_type = alternative;
      return result;
    }
    auto alternative_type_id = MapAlternative(context, loc_id, alternative);
    if (!alternative_type_id.has_value()) {
      result.reason = CppSumType::AlternativeNotAdmitted;
      result.bad_alternative = index;
      result.bad_alternative_type = alternative;
      return result;
    }
    arg_ids.push_back(context.types().GetTypeInstId(alternative_type_id));
  }
  auto carbon_type_id = FormCarbonSumType(
      context, loc_id,
      GetCarbonSumTypeName(result.is_optional, num_alternatives), arg_ids);
  if (carbon_type_id == SemIR::ErrorInst::TypeId) {
    result.reason = CppSumType::AlreadyDiagnosed;
    return result;
  }
  if (!TryToCompleteType(context, carbon_type_id, loc_id) ||
      (!GetChoiceDiscriminantType(context, carbon_type_id) &&
       num_alternatives > 1)) {
    // Not reached for an admitted specialization; diagnosed with no note
    // (`NoReason`) rather than silently.
    return result;
  }
  result.status = CppSumType::Mapped;
  result.carbon_type_id = carbon_type_id;
  return result;
}

// The C++ spelling of a type in a diagnostic, without the tag keyword
// (`std::optional<int>`, not `class std::optional<int>`).
static auto GetCppTypeSpelling(Context& context, clang::QualType type)
    -> std::string {
  clang::PrintingPolicy policy(context.ast_context().getLangOpts());
  policy.SuppressTagKeyword = true;
  return type.getAsString(policy);
}

// The C++ spelling of the class behind `type_id`, as import.cpp's diagnostics
// print C++ types: the Carbon name of an imported specialization
// (`Cpp.std._C.optional`) carries no template arguments.
static auto GetCppTypeSpelling(Context& context, SemIR::TypeId type_id)
    -> std::string {
  const auto* record_decl = GetCppClassDecl(context, type_id);
  CARBON_CHECK(record_decl, "not a C++ class");
  return GetCppTypeSpelling(
      context,
      clang::QualType(context.ast_context().getCanonicalTagType(record_decl)));
}

auto DiagnoseCppSumTypeNotMapped(Context& context, SemIR::LocId loc_id,
                                 const CppSumType& sum_type) -> void {
  if (sum_type.reason == CppSumType::AlreadyDiagnosed) {
    return;
  }
  CARBON_DIAGNOSTIC(CppSumTypeNotMapped, Error,
                    "C++ type `{0}` has no Carbon sum type", std::string);
  CARBON_DIAGNOSTIC(CppSumTypeTooManyAlternatives, Note,
                    "`std::variant` with {0} alternatives; at most {1} have a "
                    "Carbon sum type",
                    int, int);
  CARBON_DIAGNOSTIC(CppSumTypeNotTriviallyCopyable, Note,
                    "`{0}` is not trivially copyable and trivially "
                    "destructible",
                    std::string);
  CARBON_DIAGNOSTIC(CppSumTypeQualifiedAlternative, Note,
                    "alternative {0} has qualified or reference type `{1}`",
                    int, std::string);
  CARBON_DIAGNOSTIC(CppSumTypeAlternativeNotAdmitted, Note,
                    "alternative {0} has type `{1}`, which is not a choice "
                    "payload type in 0.1",
                    int, std::string);
  auto spelling = GetCppTypeSpelling(context, sum_type.cpp_type_id);
  auto builder = context.emitter().Build(loc_id, CppSumTypeNotMapped, spelling);
  switch (sum_type.reason) {
    case CppSumType::TooManyAlternatives:
      builder.Note(loc_id, CppSumTypeTooManyAlternatives,
                   sum_type.num_alternatives, MaxVariantAlternatives);
      break;
    case CppSumType::NotTriviallyCopyable:
      builder.Note(loc_id, CppSumTypeNotTriviallyCopyable, spelling);
      break;
    case CppSumType::QualifiedAlternative:
      builder.Note(loc_id, CppSumTypeQualifiedAlternative,
                   sum_type.bad_alternative,
                   GetCppTypeSpelling(context, sum_type.bad_alternative_type));
      break;
    case CppSumType::AlternativeNotAdmitted:
      builder.Note(loc_id, CppSumTypeAlternativeNotAdmitted,
                   sum_type.bad_alternative,
                   GetCppTypeSpelling(context, sum_type.bad_alternative_type));
      break;
    case CppSumType::NoReason:
    case CppSumType::AlreadyDiagnosed:
      break;
  }
  builder.Emit();
}

// Returns whether a branching conversion can be built at `loc_id`, and emits a
// TODO when it cannot. It cannot outside a function body -- a file-scope
// initializer (W-036's limit, which every branching expression shares) or a
// conversion that a template defers to its instantiation, which is performed
// outside any function body -- nor where the conversion has no source
// expression to attribute its blocks to. These are limits of the toolchain, not
// of the types, so a non-diagnosing caller does not test them: an `overload fn`
// probe accepts the pair, and the committed call emits the TODO, so which
// member a call selects does not depend on where the call is.
static auto CanBuildBranches(Context& context, SemIR::LocId loc_id) -> bool {
  if (!context.scope_stack().IsInFunctionScope()) {
    context.TODO(loc_id,
                 "conversion of a C++ `std::optional` or `std::variant` "
                 "outside a function body (at file scope, or deferred to a "
                 "template's instantiation)");
    return false;
  }
  if (context.insts().GetCanonicalLocId(loc_id).kind() !=
      SemIR::LocId::Kind::NodeId) {
    context.TODO(loc_id,
                 "conversion of a C++ `std::optional` or `std::variant` "
                 "with no source expression");
    return false;
  }
  return true;
}

// Returns the parse node that the blocks of a branching conversion are
// attributed to, or emits a TODO and returns `None` where a conversion cannot
// branch (`CanBuildBranches`).
static auto GetNodeIdForBranches(Context& context, SemIR::LocId loc_id)
    -> Parse::NodeId {
  if (!CanBuildBranches(context, loc_id)) {
    return Parse::NodeId::None;
  }
  return context.insts().GetCanonicalLocId(loc_id).node_id();
}

// Calls `callee_id`, a C++ overload set, with the explicit integer template
// argument `index` -- `std::get<I>(v)`, `v.emplace<I>(x)` -- which a Carbon
// call cannot spell (cpp/call.cpp `IsTemplateArg`).
static auto CallCppWithIndexTemplateArg(Context& context, SemIR::LocId loc_id,
                                        Parse::NodeId node_id,
                                        SemIR::InstId callee_id, int index,
                                        llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> SemIR::InstId {
  auto callee = SemIR::GetCallee(context.sem_ir(), callee_id);
  const auto* overload = std::get_if<SemIR::CalleeCppOverloadSet>(&callee);
  if (!overload) {
    return SemIR::ErrorInst::InstId;
  }
  SemIR::InstId template_arg_ids[] = {
      MakeIntLiteral(context, node_id, context.ints().Add(index))};
  auto fn_id = PerformCppOverloadResolution(
      context, loc_id,
      context.cpp_overload_sets().Get(overload->cpp_overload_set_id),
      template_arg_ids, overload->self_id, arg_ids);
  auto fn_callee = SemIR::GetCallee(context.sem_ir(), fn_id);
  auto* fn = std::get_if<SemIR::CalleeFunction>(&fn_callee);
  if (!fn) {
    return SemIR::ErrorInst::InstId;
  }
  if (overload->self_id.has_value()) {
    fn->self_id = overload->self_id;
  }
  return PerformCallToFunction(context, loc_id, fn_id, *fn, arg_ids,
                               /*is_desugared=*/true);
}

// Calls the C++ member function `name` of `object_id`.
static auto CallCppMethod(Context& context, SemIR::LocId loc_id,
                          SemIR::InstId object_id, llvm::StringRef name,
                          llvm::ArrayRef<SemIR::InstId> arg_ids = {})
    -> SemIR::InstId {
  auto method_id = PerformMemberAccess(context, loc_id, object_id,
                                       AddIdentifierName(context, name));
  return PerformCall(context, loc_id, method_id, arg_ids,
                     /*is_desugared=*/true);
}

// The value `()`: the payload of a `std::monostate` alternative.
static auto MakeEmptyTupleValue(Context& context, SemIR::LocId loc_id)
    -> SemIR::InstId {
  return GetOrAddInst<SemIR::TupleValue>(
      context, loc_id,
      {.type_id = GetTupleType(context, {}),
       .elements_id = SemIR::InstBlockId::Empty});
}

// One shared storage initialized in one of several blocks: the catching
// thunk's shape (cpp/thunk.cpp `PerformCppCatchingThunkCall`).
class BranchedInit {
 public:
  BranchedInit(Context& context, SemIR::LocId loc_id, SemIR::TypeId type_id)
      : context_(context),
        loc_id_(loc_id),
        storage_id_(AddInst<SemIR::TemporaryStorage>(context, loc_id,
                                                     {.type_id = type_id})) {}

  auto Initialize(SemIR::InstId init_id) -> void {
    if (init_id == SemIR::ErrorInst::InstId) {
      ok_ = false;
      return;
    }
    init_id = InitializeExisting(context_, loc_id_, storage_id_, init_id);
    if (init_id == SemIR::ErrorInst::InstId) {
      ok_ = false;
      return;
    }
    AddInst<SemIR::Assign>(context_, loc_id_,
                           {.lhs_id = storage_id_, .rhs_id = init_id});
  }

  auto storage_id() const -> SemIR::InstId { return storage_id_; }
  auto ok() const -> bool { return ok_; }

 private:
  Context& context_;
  SemIR::LocId loc_id_;
  SemIR::InstId storage_id_;
  bool ok_ = true;
};

// The result of a conversion that a non-diagnosing caller only tests
// (`ConversionTarget::diagnose` is false: the `overload fn` probe, call.cpp
// `ProbeOverloadCandidate`, including the element conversions of an aggregate
// argument; deduction's speculative conversions): a value of the target type
// built from no C++ call and no block, so the probe's scratch block holds all
// of it. It is not a constant, as the conversion it stands for is not, so
// deduction, which keeps a constant result, rejects both alike.
static auto MakeTestedConversion(Context& context, SemIR::LocId loc_id,
                                 SemIR::TypeId type_id) -> SemIR::InstId {
  return ConvertToValueExpr(
      context,
      AddInst<SemIR::TemporaryStorage>(context, loc_id, {.type_id = type_id}));
}

// Emits `n` arms selected by `select(i)` for i < n - 1 (the last arm is the
// fall-through), calling `arm(i)` in each, and converges.
//
// Each arm owns the cleanups registered while it is built, as an `if`
// expression's arms do (`BeginConditionalExprOperand`): a C++ temporary made in
// one arm -- the `Core.Optional(T*)` that `value()` returns for a pointer
// payload -- is destroyed at the end of that arm, where its evaluation
// dominates the destroy. An arm initializes the shared storage and produces no
// value, so no value can refer into those temporaries.
template <typename SelectFn, typename ArmFn>
static auto EmitArms(Context& context, Parse::NodeId node_id, int n,
                     SelectFn select, ArmFn arm) -> void {
  CARBON_CHECK(node_id.has_value(), "branching conversion without a node");
  auto emit_arm = [&](int i) {
    BeginConditionalExprOperand(context);
    arm(i);
    if (context.scope_stack().IsInFunctionScope()) {
      AddAndDiscardTemporaryCleanups(context);
      context.scope_stack().Pop();
    }
  };
  for (int i = 0; i < n; ++i) {
    if (i + 1 < n) {
      auto cond_id = select(i);
      auto then_block_id =
          AddDominatedBlockAndBranchIf(context, node_id, cond_id);
      auto else_block_id = AddDominatedBlockAndBranch(context, node_id);
      context.inst_block_stack().Pop();
      context.inst_block_stack().Push(then_block_id);
      context.region_stack().AddToRegion(then_block_id, node_id);
      emit_arm(i);
      context.inst_block_stack().Push(else_block_id);
      context.region_stack().AddToRegion(else_block_id, node_id);
    } else {
      emit_arm(i);
    }
  }
  if (n > 1) {
    AddConvergenceBlockAndPush(context, node_id, n);
  }
}

// The alternatives of the `choice` `type_id`, in discriminant order.
static auto GetAlternativesInOrder(Context& context, SemIR::TypeId type_id)
    -> llvm::SmallVector<SemIR::ChoiceAlternative> {
  const auto& class_info = context.classes().Get(
      context.types().GetAs<SemIR::ClassType>(type_id).class_id);
  llvm::SmallVector<SemIR::ChoiceAlternative> alternatives(
      class_info.choice_alternatives.begin(),
      class_info.choice_alternatives.end());
  llvm::sort(alternatives,
             [](const auto& a, const auto& b) { return a.index < b.index; });
  return alternatives;
}

auto ConvertCppSumToCarbon(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId {
  CARBON_CHECK(sum_type.status == CppSumType::Mapped);
  auto node_id = GetNodeIdForBranches(context, loc_id);
  if (!node_id.has_value()) {
    return SemIR::ErrorInst::InstId;
  }
  // A value, not a reference: the accessors are then called on a `const`
  // object, so overload resolution picks their `const&` forms and nothing is
  // moved from.
  value_id = ConvertToValueExpr(context, value_id);
  auto carbon_type_inst_id =
      context.types().GetTypeInstId(sum_type.carbon_type_id);
  auto alternatives = GetAlternativesInOrder(context, sum_type.carbon_type_id);
  auto make_alternative = [&](const SemIR::ChoiceAlternative& alternative,
                              SemIR::InstId payload_id) -> SemIR::InstId {
    auto alternative_id = PerformMemberAccess(
        context, loc_id, carbon_type_inst_id, alternative.name_id);
    if (!alternative.has_parameters) {
      return alternative_id;
    }
    return PerformCall(context, loc_id, alternative_id, {payload_id},
                       /*is_desugared=*/true);
  };
  const auto* record_decl = GetCppClassDecl(context, sum_type.cpp_type_id);
  auto mapping = GetCppSumTypeMapping(record_decl);

  BranchedInit result(context, loc_id, sum_type.carbon_type_id);
  if (sum_type.is_optional) {
    // `Some` is alternative 0 and `None` alternative 1: test `has_value()`.
    // A `std::optional<std::monostate>`'s `Some` carries `()`.
    bool is_monostate = IsStdMonostate(mapping.alternative_types[0]);
    auto has_value_id = ConvertToBoolValue(
        context, loc_id, CallCppMethod(context, loc_id, value_id, "has_value"));
    EmitArms(
        context, node_id, 2, [&](int) { return has_value_id; },
        [&](int i) {
          auto payload_id = SemIR::InstId::None;
          if (i == 0) {
            payload_id = is_monostate ? MakeEmptyTupleValue(context, loc_id)
                                      : CallCppMethod(context, loc_id, value_id,
                                                      "value");
          }
          result.Initialize(make_alternative(alternatives[i], payload_id));
        });
  } else {
    int n = alternatives.size();
    auto index_id = n > 1 ? CallCppMethod(context, loc_id, value_id, "index")
                          : SemIR::InstId::None;
    auto std_scope_id =
        context.classes()
            .Get(context.types()
                     .GetAs<SemIR::ClassType>(sum_type.cpp_type_id)
                     .class_id)
            .parent_scope_id;
    auto std_inst_id = context.name_scopes().Get(std_scope_id).inst_id();
    EmitArms(
        context, node_id, n,
        [&](int i) {
          auto index_type_id = context.insts().Get(index_id).type_id();
          auto i_id = ConvertToValueOfType(
              context, loc_id,
              MakeIntLiteral(context, node_id, context.ints().Add(i)),
              index_type_id);
          SemIR::InstId eq_args[] = {
              context.types().GetTypeInstId(index_type_id)};
          auto eq_id =
              BuildBinaryOperator(context, loc_id,
                                  {.interface_name = CoreIdentifier::EqWith,
                                   .interface_args_ref = eq_args,
                                   .op_name = CoreIdentifier::Equal},
                                  index_id, i_id);
          return ConvertToBoolValue(context, loc_id, eq_id);
        },
        [&](int i) {
          auto payload_id = SemIR::InstId::None;
          if (IsStdMonostate(mapping.alternative_types[i])) {
            payload_id = MakeEmptyTupleValue(context, loc_id);
          } else {
            auto get_id =
                PerformMemberAccess(context, loc_id, std_inst_id,
                                    AddIdentifierName(context, "get"));
            payload_id = CallCppWithIndexTemplateArg(context, loc_id, node_id,
                                                     get_id, i, {value_id});
          }
          result.Initialize(make_alternative(alternatives[i], payload_id));
        });
  }
  if (!result.ok()) {
    return SemIR::ErrorInst::InstId;
  }
  return ConvertToValueExpr(context, result.storage_id());
}

auto ConvertCarbonSumToCpp(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId {
  CARBON_CHECK(sum_type.status == CppSumType::Mapped);
  auto node_id = GetNodeIdForBranches(context, loc_id);
  if (!node_id.has_value()) {
    return SemIR::ErrorInst::InstId;
  }
  value_id = ConvertToValueExpr(context, value_id);
  auto cpp_type_inst_id = context.types().GetTypeInstId(sum_type.cpp_type_id);
  const auto& cpp_class = context.classes().Get(
      context.types().GetAs<SemIR::ClassType>(sum_type.cpp_type_id).class_id);
  auto alternatives = GetAlternativesInOrder(context, sum_type.carbon_type_id);
  int n = alternatives.size();

  // Default-construct the C++ object -- an empty `std::optional`, or a
  // `std::variant` holding a value-initialized first alternative -- then
  // `emplace` the active alternative's payload.
  BranchedInit result(context, loc_id, sum_type.cpp_type_id);
  auto ctor_id =
      PerformMemberAccess(context, loc_id, cpp_type_inst_id, cpp_class.name_id);
  result.Initialize(PerformCall(context, loc_id, ctor_id, {}, true));
  auto disc_type_id =
      GetChoiceDiscriminantType(context, sum_type.carbon_type_id);
  // The payload of `alternative`, or `None` for a `()` payload, which
  // `emplace` takes as no argument.
  auto payload_of =
      [&](const SemIR::ChoiceAlternative& alternative) -> SemIR::InstId {
    auto tuple_id = EmitChoicePayloadFieldAccess(
        context, loc_id, value_id, alternative.payload_field_index);
    auto tuple_type_id = context.insts().Get(tuple_id).type_id();
    auto element_type_id = context.types().GetTypeIdForTypeInstId(
        context.inst_blocks().Get(context.types()
                                      .GetAs<SemIR::TupleType>(tuple_type_id)
                                      .type_elements_id)[0]);
    if (element_type_id == GetTupleType(context, {})) {
      return SemIR::InstId::None;
    }
    return ConvertToValueExpr(context, AddInst<SemIR::TupleAccess>(
                                           context, loc_id,
                                           {.type_id = element_type_id,
                                            .tuple_id = tuple_id,
                                            .index = SemIR::ElementIndex(0)}));
  };
  bool ok = result.ok();
  EmitArms(
      context, node_id, n,
      [&](int i) {
        return EmitChoiceDiscriminantTest(context, node_id, value_id,
                                          *disc_type_id, alternatives[i].index);
      },
      [&](int i) {
        const auto& alternative = alternatives[i];
        if (!alternative.has_parameters) {
          // `None`: the default-constructed `std::optional` is empty.
          return;
        }
        llvm::SmallVector<SemIR::InstId, 1> args;
        if (auto payload_id = payload_of(alternative); payload_id.has_value()) {
          args.push_back(payload_id);
        }
        if (sum_type.is_optional) {
          ok &= CallCppMethod(context, loc_id, result.storage_id(), "emplace",
                              args) != SemIR::ErrorInst::InstId;
          return;
        }
        auto emplace_id =
            PerformMemberAccess(context, loc_id, result.storage_id(),
                                AddIdentifierName(context, "emplace"));
        ok &= CallCppWithIndexTemplateArg(context, loc_id, node_id, emplace_id,
                                          i, args) != SemIR::ErrorInst::InstId;
      });
  if (!ok) {
    return SemIR::ErrorInst::InstId;
  }
  return ConvertToValueExpr(context, result.storage_id());
}

// Returns 1 for `Core.CppCompat.StdOptional`, 2 for a `StdVariant<N>`, and 0
// for any other type.
static auto ClassifyCarbonSumType(Context& context, SemIR::TypeId type_id)
    -> int {
  auto class_type = context.types().TryGetAs<SemIR::ClassType>(
      context.types().GetUnqualifiedType(type_id));
  if (!class_type || !class_type->specific_id.has_value()) {
    return 0;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (!class_info.is_choice || !class_info.parent_scope_id.has_value() ||
      !context.name_scopes().IsInCorePackageRoot(class_info.parent_scope_id)) {
    return 0;
  }
  auto parent_name = context.names().GetAsStringIfIdentifier(
      context.name_scopes().Get(class_info.parent_scope_id).name_id());
  auto name = context.names().GetAsStringIfIdentifier(class_info.name_id);
  if (parent_name != "CppCompat" || !name) {
    return 0;
  }
  if (*name == "StdOptional") {
    return 1;
  }
  return name->starts_with("StdVariant") ? 2 : 0;
}

// Returns whether `type_id` is a `Core.Optional(T)` specific, and sets
// `payload_type_id` to `T` (from the argument `T as OptionalStorage`) when the
// argument is concrete. Adds no instruction.
static auto GetCoreOptionalPayload(Context& context, SemIR::TypeId type_id,
                                   SemIR::TypeId& payload_type_id) -> bool {
  payload_type_id = SemIR::TypeId::None;
  auto class_type = context.types().TryGetAs<SemIR::ClassType>(
      context.types().GetUnqualifiedType(type_id));
  if (!class_type || !class_type->specific_id.has_value()) {
    return false;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (class_info.is_choice ||
      !context.name_scopes().IsCorePackage(class_info.parent_scope_id) ||
      context.names().GetAsStringIfIdentifier(class_info.name_id) !=
          "Optional") {
    return false;
  }
  auto args = context.inst_blocks().GetOrEmpty(
      context.specifics().Get(class_type->specific_id).args_id);
  if (args.size() != 1) {
    return false;
  }
  auto arg_const_id = context.constant_values().Get(args[0]);
  if (context.constant_values().GetDependence(arg_const_id) !=
      SemIR::ConstantDependence::None) {
    return true;
  }
  auto arg_inst_id = context.constant_values().GetInstId(arg_const_id);
  if (auto facet = context.insts().TryGetAs<SemIR::FacetValue>(arg_inst_id)) {
    arg_const_id = context.constant_values().Get(facet->type_inst_id);
  }
  payload_type_id = context.types().TryGetTypeIdForTypeConstantId(arg_const_id);
  return true;
}

// Classifies a `Core.Optional` specific without forming its view.
static auto ClassifyCoreOptional(Context& context, SemIR::LocId loc_id,
                                 SemIR::TypeId type_id) -> CoreOptionalView {
  auto payload_type_id = SemIR::TypeId::None;
  if (!GetCoreOptionalPayload(context, type_id, payload_type_id)) {
    return {};
  }
  CoreOptionalView view = {.payload_type_id = payload_type_id};
  if (!payload_type_id.has_value()) {
    view.status = CoreOptionalView::SymbolicPayload;
  } else if (!TryToCompleteType(context, payload_type_id, loc_id) ||
             !IsInSliceChoicePayloadType(context, payload_type_id)) {
    view.status = CoreOptionalView::PayloadNotAdmitted;
  } else {
    view.status = CoreOptionalView::Matchable;
  }
  return view;
}

auto GetCoreOptionalView(Context& context, SemIR::LocId loc_id,
                         SemIR::TypeId type_id) -> CoreOptionalView {
  auto view = ClassifyCoreOptional(context, loc_id, type_id);
  if (view.status != CoreOptionalView::Matchable) {
    return view;
  }
  // The payload is admitted, so forming `StdOptional(T)` cannot fail SF-6's
  // per-specific check.
  view.view_type_id = FormCarbonSumType(
      context, loc_id, GetCarbonSumTypeName(/*is_optional=*/true, 1),
      {context.types().GetTypeInstId(view.payload_type_id)});
  if (view.view_type_id == SemIR::ErrorInst::TypeId) {
    view.status = CoreOptionalView::PayloadNotAdmitted;
  }
  return view;
}

auto DiagnoseCoreOptionalNotMatchable(Context& context, SemIR::LocId loc_id,
                                      SemIR::TypeId type_id,
                                      const CoreOptionalView& view) -> void {
  CARBON_DIAGNOSTIC(CoreOptionalNotMatchable, Error,
                    "cannot match {0} in 0.1: its payload type {1:is "
                    "symbolic|is not a choice payload type}",
                    SemIR::TypeId, Diagnostics::BoolAsSelect);
  context.emitter().Emit(loc_id, CoreOptionalNotMatchable, type_id,
                         view.status == CoreOptionalView::SymbolicPayload);
}

static auto IsTemplateDependent(Context& context, SemIR::TypeId type_id)
    -> bool {
  return context.constant_values().GetDependence(context.types().GetConstantId(
             type_id)) == SemIR::ConstantDependence::Template;
}

// Diagnoses a C++ sum value converted to a type it does not convert to.
static auto DiagnoseCppSumTypeMismatch(Context& context, SemIR::LocId loc_id,
                                       const CppSumType& sum_type,
                                       SemIR::TypeId target_type_id) -> void {
  CARBON_DIAGNOSTIC(CppSumTypeMismatch, Error,
                    "C++ type `{0}` converts only to its own Carbon sum type "
                    "{1}{2: or to the `Core.Optional` of its payload|}, not to "
                    "{3}",
                    std::string, SemIR::TypeId, Diagnostics::BoolAsSelect,
                    SemIR::TypeId);
  context.emitter().Emit(loc_id, CppSumTypeMismatch,
                         GetCppTypeSpelling(context, sum_type.cpp_type_id),
                         sum_type.carbon_type_id, sum_type.is_optional,
                         target_type_id);
}

// Diagnoses a Carbon sum value converted to a C++ class that is not the one
// whose sum type it is: another specialization (`std::optional<long>`), or a
// class with a converting constructor, which C++ would otherwise reach through
// `std::optional`'s own converting constructors.
static auto DiagnoseCppSumTypeReverseMismatch(Context& context,
                                              SemIR::LocId loc_id,
                                              SemIR::TypeId value_type_id,
                                              SemIR::TypeId target_type_id)
    -> void {
  CARBON_DIAGNOSTIC(CppSumTypeReverseMismatch, Error,
                    "{0} converts to C++ only as the `std::optional` or "
                    "`std::variant` whose Carbon sum type it is, not to `{1}`",
                    SemIR::TypeId, std::string);
  context.emitter().Emit(loc_id, CppSumTypeReverseMismatch, value_type_id,
                         GetCppTypeSpelling(context, target_type_id));
}

// Converts a value of a C++ class or Carbon type to the C++ class target
// `target_type_id`, given the Carbon sum type `sum_type_id` the value converts
// to first (itself, or the view of a `Core.Optional`).
static auto ConvertToCppSumClass(Context& context, SemIR::LocId loc_id,
                                 SemIR::InstId value_id,
                                 SemIR::TypeId value_type_id,
                                 SemIR::TypeId sum_type_id,
                                 SemIR::TypeId target_type_id, bool diagnose)
    -> SemIR::InstId {
  auto sum_type = GetCppSumType(context, loc_id, target_type_id);
  if (sum_type.status != CppSumType::Mapped ||
      sum_type.carbon_type_id != sum_type_id) {
    if (diagnose) {
      DiagnoseCppSumTypeReverseMismatch(context, loc_id, value_type_id,
                                        target_type_id);
    }
    return SemIR::ErrorInst::InstId;
  }
  if (!diagnose) {
    return MakeTestedConversion(context, loc_id, target_type_id);
  }
  if (!CanBuildBranches(context, loc_id)) {
    return SemIR::ErrorInst::InstId;
  }
  if (value_type_id != sum_type_id) {
    // A `Core.Optional(T)`: through the prelude's bridge to its view first.
    value_id = ConvertToValueOfType(context, loc_id, value_id, sum_type_id);
    if (value_id == SemIR::ErrorInst::InstId) {
      return value_id;
    }
  }
  return ConvertCarbonSumToCpp(context, loc_id, value_id, sum_type);
}

auto TryConvertCppSumType(Context& context, SemIR::LocId loc_id,
                          SemIR::InstId value_id, SemIR::TypeId target_type_id,
                          bool diagnose) -> SemIR::InstId {
  auto value_type_id = context.types().GetUnqualifiedType(
      context.insts().Get(value_id).type_id());
  target_type_id = context.types().GetUnqualifiedType(target_type_id);
  // A template-dependent side is converted when the template is instantiated
  // (the deferred conversion), with both types known.
  if (IsTemplateDependent(context, value_type_id) ||
      IsTemplateDependent(context, target_type_id)) {
    return SemIR::InstId::None;
  }

  // C++ to Carbon: to the sum type itself, or for `std::optional<T>` to
  // `Core.Optional(T')` through it.
  if (GetCppClassDecl(context, value_type_id)) {
    bool target_is_sum_type =
        ClassifyCarbonSumType(context, target_type_id) != 0;
    auto target_optional =
        target_is_sum_type
            ? CoreOptionalView()
            : ClassifyCoreOptional(context, loc_id, target_type_id);
    // A `Core.Optional` whose payload is not matchable -- in particular one
    // whose payload is the C++ class itself -- is left to `Core.Optional`'s
    // own conversions.
    if (!target_is_sum_type &&
        target_optional.status != CoreOptionalView::Matchable) {
      return SemIR::InstId::None;
    }
    auto sum_type = GetCppSumType(context, loc_id, value_type_id);
    if (sum_type.status == CppSumType::NotSumType) {
      return SemIR::InstId::None;
    }
    if (sum_type.status == CppSumType::NotMapped) {
      if (diagnose) {
        DiagnoseCppSumTypeNotMapped(context, loc_id, sum_type);
      }
      return SemIR::ErrorInst::InstId;
    }
    bool to_core_optional = false;
    if (!target_is_sum_type && sum_type.is_optional) {
      auto view = GetCoreOptionalView(context, loc_id, target_type_id);
      to_core_optional = view.view_type_id == sum_type.carbon_type_id;
    }
    if (sum_type.carbon_type_id != target_type_id && !to_core_optional) {
      if (diagnose) {
        DiagnoseCppSumTypeMismatch(context, loc_id, sum_type, target_type_id);
      }
      return SemIR::ErrorInst::InstId;
    }
    if (!diagnose) {
      return MakeTestedConversion(context, loc_id, target_type_id);
    }
    if (!CanBuildBranches(context, loc_id)) {
      return SemIR::ErrorInst::InstId;
    }
    auto sum_id = ConvertCppSumToCarbon(context, loc_id, value_id, sum_type);
    if (!to_core_optional || sum_id == SemIR::ErrorInst::InstId) {
      return sum_id;
    }
    // Through the prelude's bridge,
    // `StdOptional(T) as ImplicitAs(Optional(T))`.
    return ConvertToValueOfType(context, loc_id, sum_id, target_type_id);
  }

  // Carbon to C++: a sum type, or a `Core.Optional(T')` whose payload is
  // matchable and not a pointer (a `Core.Optional(T*)` keeps the nullable
  // pointer mapping), converts only to the C++ class whose sum type it is.
  if (!GetCppClassDecl(context, target_type_id)) {
    return SemIR::InstId::None;
  }
  if (ClassifyCarbonSumType(context, value_type_id) != 0) {
    return ConvertToCppSumClass(context, loc_id, value_id, value_type_id,
                                value_type_id, target_type_id, diagnose);
  }
  auto value_optional = ClassifyCoreOptional(context, loc_id, value_type_id);
  if (value_optional.status == CoreOptionalView::Matchable &&
      !context.types().Is<SemIR::PointerType>(value_optional.payload_type_id)) {
    auto view = GetCoreOptionalView(context, loc_id, value_type_id);
    return ConvertToCppSumClass(context, loc_id, value_id, value_type_id,
                                view.view_type_id, target_type_id, diagnose);
  }
  return SemIR::InstId::None;
}

auto MapCarbonSumTypeToCpp(Context& context, SemIR::LocId loc_id,
                           SemIR::TypeId carbon_type_id) -> clang::QualType {
  carbon_type_id = context.types().GetUnqualifiedType(carbon_type_id);
  int kind = ClassifyCarbonSumType(context, carbon_type_id);
  llvm::SmallVector<SemIR::TypeId> arg_type_ids;
  if (kind != 0) {
    auto class_type = context.types().GetAs<SemIR::ClassType>(carbon_type_id);
    for (auto arg_id : context.inst_blocks().GetOrEmpty(
             context.specifics().Get(class_type.specific_id).args_id)) {
      if (auto facet = context.insts().TryGetAs<SemIR::FacetValue>(arg_id)) {
        arg_id = facet->type_inst_id;
      }
      arg_type_ids.push_back(context.types().GetTypeIdForTypeConstantId(
          context.constant_values().Get(arg_id)));
    }
  } else {
    // A `Core.Optional(T)` whose payload is matchable and not a pointer is
    // offered as `std::optional<T'>`; a `Core.Optional(T*)` keeps the nullable
    // pointer mapping of `MapToCppType`.
    auto view = ClassifyCoreOptional(context, loc_id, carbon_type_id);
    if (view.status != CoreOptionalView::Matchable ||
        context.types().Is<SemIR::PointerType>(view.payload_type_id)) {
      return clang::QualType();
    }
    kind = 1;
    arg_type_ids.push_back(view.payload_type_id);
  }
  auto* template_decl = LookupCppClassTemplate(
      context, {"std", kind == 1 ? "optional" : "variant"});
  if (!template_decl) {
    return clang::QualType();
  }
  clang::ASTContext& ast_context = context.ast_context();
  clang::TemplateArgumentListInfo arg_list;
  for (auto arg_type_id : arg_type_ids) {
    if (!arg_type_id.has_value() || arg_type_id == SemIR::ErrorInst::TypeId) {
      return clang::QualType();
    }
    // `()` is the payload of a `std::monostate` alternative.
    auto cpp_arg_type = arg_type_id == GetTupleType(context, {})
                            ? LookupCppType(context, {"std", "monostate"})
                            : MapToCppType(context, arg_type_id);
    if (cpp_arg_type.isNull()) {
      return clang::QualType();
    }
    arg_list.addArgument(clang::TemplateArgumentLoc(
        clang::TemplateArgument(cpp_arg_type),
        ast_context.getTrivialTypeSourceInfo(cpp_arg_type)));
  }
  clang::TemplateName template_name(template_decl);
  return context.clang_sema().CheckTemplateIdType(
      clang::ElaboratedTypeKeyword::None, template_name,
      /*TemplateLoc=*/clang::SourceLocation(), arg_list,
      /*Scope=*/nullptr, /*ForNestedNameSpecifier=*/false);
}

}  // namespace Carbon::Check
```

<!-- google-doc-style-resume -->

### §2.5 toolchain/check/convert.cpp

**Invariant:** the hook runs after every conversion that compares the two
types structurally (tuples, structs, arrays, function pointers), and before the
target is unqualified and the class-to-class paths start; it returns `None`
unless one side is a C++ sum class and the other its own sum type or a
`Core.Optional` it relates to (§1.4), and it passes the conversion's `diagnose`
flag (amended 2026-10-20, review fold: A-B1 / B-B-1), so every existing
conversion keeps its path (measured: the gate, §0.6). `ConvertAggregateElement`
gains a `bool diagnose` parameter that its four callers fill from the
aggregate conversion's target, so an element conversion is non-diagnosing
exactly when its aggregate's is (amended 2026-10-20, review fold: RR-B1 /
RR-B-1); on trunk this changes only an `overload fn` probe or a deduction over
an aggregate whose element does not convert, which now fails silently as its
contract says (t01; the gate shows no golden change, §0.6).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/convert.cpp
+++ b/toolchain/check/convert.cpp
@@ -18,6 +18,7 @@
 #include "toolchain/check/core_identifier.h"
 #include "toolchain/check/cpp/export.h"
 #include "toolchain/check/cpp/import.h"
+#include "toolchain/check/cpp/sum_type.h"
 #include "toolchain/check/diagnostic_helpers.h"
 #include "toolchain/check/eval.h"
 #include "toolchain/check/impl_lookup.h"
@@ -364,7 +365,8 @@
     ConversionTarget::Kind kind, SemIR::InstId target_id,
     SemIR::TypeInstId target_elem_type_inst, PendingBlock* target_block,
     llvm::MutableArrayRef<SemIR::InstId> template_storage_args,
-    size_t src_field_index, size_t target_field_index) -> SemIR::InstId {
+    size_t src_field_index, size_t target_field_index, bool diagnose)
+    -> SemIR::InstId {
   auto src_elem_type =
       context.types().GetTypeIdForTypeInstId(src_elem_type_inst);
   auto target_elem_type =
@@ -389,8 +391,11 @@
   }

   // If we're performing a conversion rather than an initialization, we won't
-  // have or need a target.
-  ConversionTarget target = {.kind = kind, .type_id = target_elem_type};
+  // have or need a target. Fork (SV-1): the element conversion inherits the
+  // aggregate conversion's `diagnose`, so that a conversion a caller only tests
+  // (an `overload fn` probe) tests its elements without diagnosing either.
+  ConversionTarget target = {
+      .kind = kind, .type_id = target_elem_type, .diagnose = diagnose};
   if (!target.is_initializer()) {
     return Convert(context, loc_id, src_elem_id, target);
   }
@@ -487,7 +492,7 @@
             context, value_loc_id, value_id, src_type_inst_id, literal,
             ConversionTarget::InPlaceInitializing, return_slot_arg_id,
             array_type.element_type_inst_id, target_block,
-            target.template_storage_args, i, i);
+            target.template_storage_args, i, i, target.diagnose);
     if (init_id == SemIR::ErrorInst::InstId) {
       return SemIR::ErrorInst::InstId;
     }
@@ -577,7 +582,8 @@
         ConvertAggregateElement<SemIR::TupleAccess, SemIR::TupleAccess>(
             context, value_loc_id, value_id, src_type_inst_id, literal,
             inner_kind, target.storage_id, dest_type_inst_id,
-            target.storage_access_block, target.template_storage_args, i, i);
+            target.storage_access_block, target.template_storage_args, i, i,
+            target.diagnose);
     if (init_id == SemIR::ErrorInst::InstId) {
       return SemIR::ErrorInst::InstId;
     }
@@ -972,7 +978,7 @@
           context, value_loc_id, value_id, src_field.type_inst_id, literal,
           inner_kind, target.storage_id, dest_field_type_inst_id,
           target.storage_access_block, target.template_storage_args,
-          src_field_index, dest_field_index);
+          src_field_index, dest_field_index, target.diagnose);
     } else {
       init_id = get_default(dest_field.name_id);
     }
@@ -1136,7 +1142,7 @@
           context, value_loc_id, value_id, src_field.type_inst_id, literal,
           inner_kind, target.storage_id, dest_field.type_inst_id,
           target.storage_access_block, target.template_storage_args,
-          /*src_field_index=*/0, dest_field_index);
+          /*src_field_index=*/0, dest_field_index, target.diagnose);
   if (init_id == SemIR::ErrorInst::InstId) {
     return SemIR::ErrorInst::InstId;
   }
@@ -1795,6 +1801,16 @@
     }
   }

+  // Fork (SV-1, F-020): a C++ `std::optional` or `std::variant` converts by
+  // value to its `Core.CppCompat` sum type (and a `std::optional` to the
+  // `Core.Optional` of its payload), and those back to it. A non-diagnosing
+  // conversion, which the caller only tests, builds no control flow.
+  if (auto sum_id = TryConvertCppSumType(context, loc_id, value_id,
+                                         target.type_id, target.diagnose);
+      sum_id.has_value()) {
+    return sum_id;
+  }
+
   // Split the qualifiers off the target type.
   // TODO: Most conversions should probably be looking at the unqualified target
   // type.
```

<!-- google-doc-style-resume -->

### §2.6 toolchain/check/refutable_binding.cpp

**Invariant:** the conversion happens after `RequireCompleteType` (so the C++
class is complete when its triviality is read) and before the shape gate (so
the gate sees a choice); the five existing scrutinee shapes take neither
branch; a `Core.Optional` scrutinee whose payload is not a concrete choice
payload type is diagnosed here (amended 2026-10-20, review fold: A-M2 /
B-M-1). The include moves to its sorted place (rev 1's hunk was out of
order; clang-format moves it).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/refutable_binding.cpp
+++ b/toolchain/check/refutable_binding.cpp
@@ -10,6 +10,7 @@
 #include "toolchain/check/context.h"
 #include "toolchain/check/control_flow.h"
 #include "toolchain/check/convert.h"
+#include "toolchain/check/cpp/sum_type.h"
 #include "toolchain/check/inst.h"
 #include "toolchain/check/literal.h"
 #include "toolchain/check/member_access.h"
@@ -196,6 +197,43 @@
     return SemIR::InstId::None;
   }

+  // Fork (SV-1, F-020): a C++ `std::optional` or `std::variant` scrutinee is
+  // matched as its `Core.CppCompat` sum type, converted by value through the
+  // C++ accessors; one with no sum type in 0.1 is diagnosed here.
+  if (auto sum_type =
+          GetCppSumType(context, SemIR::LocId(node_id), scrutinee_type_id);
+      sum_type.status != CppSumType::NotSumType) {
+    if (sum_type.status == CppSumType::NotMapped) {
+      DiagnoseCppSumTypeNotMapped(context, SemIR::LocId(node_id), sum_type);
+      return SemIR::InstId::None;
+    }
+    scrutinee_id = ConvertCppSumToCarbon(context, SemIR::LocId(node_id),
+                                         scrutinee_id, sum_type);
+    if (scrutinee_id == SemIR::ErrorInst::InstId) {
+      return SemIR::InstId::None;
+    }
+    scrutinee_type_id = sum_type.carbon_type_id;
+  } else if (auto view = GetCoreOptionalView(context, SemIR::LocId(node_id),
+                                             scrutinee_type_id);
+             view.status != CoreOptionalView::NotCoreOptional) {
+    // Fork (SV-1, D-SV-7): a `Core.Optional(T)` scrutinee whose payload is a
+    // concrete choice payload type is matched as its view
+    // `Core.CppCompat.StdOptional(T)`, converted by value through the
+    // prelude's `ImplicitAs` impl (`HasValue()`, `Get()`); any other payload
+    // is diagnosed here, before a specific could fail at monomorphization.
+    if (view.status != CoreOptionalView::Matchable) {
+      DiagnoseCoreOptionalNotMatchable(context, SemIR::LocId(node_id),
+                                       scrutinee_type_id, view);
+      return SemIR::InstId::None;
+    }
+    scrutinee_id = ConvertToValueOfType(context, SemIR::LocId(node_id),
+                                        scrutinee_id, view.view_type_id);
+    if (scrutinee_id == SemIR::ErrorInst::InstId) {
+      return SemIR::InstId::None;
+    }
+    scrutinee_type_id = view.view_type_id;
+  }
+
   if (!IsSupportedScrutineeType(context, scrutinee_type_id)) {
     context.TODO(node_id, todo_string.str());
     return SemIR::InstId::None;
```

<!-- google-doc-style-resume -->

### §2.7 toolchain/check/cpp/type_mapping.{h,cpp}

**Invariant:** a sum-typed argument is offered to C++ overload resolution as
its C++ class and nothing else, and a `Core.Optional(T)` with a matchable
non-pointer payload as `std::optional<T>` (amended 2026-10-20, review fold:
B-M-5); `LookupCppType` becomes visible for `std::monostate`.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/cpp/type_mapping.h
+++ b/toolchain/check/cpp/type_mapping.h
@@ -31,6 +31,13 @@
     Context& context, std::initializer_list<llvm::StringRef> name_components)
     -> clang::ClassTemplateDecl*;

+// Looks up a C++ type by name, and returns it, or a null type if the lookup
+// finds no type declaration. `name_components` is as for
+// `LookupCppClassTemplate`.
+auto LookupCppType(Context& context,
+                   std::initializer_list<llvm::StringRef> name_components)
+    -> clang::QualType;
+
 // Invents a Clang argument expression to use in overload resolution to
 // represent the given Carbon argument instruction.
 auto InventClangArg(Context& context, SemIR::InstId arg_id) -> clang::Expr*;
```

<!-- google-doc-style-resume -->

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/cpp/type_mapping.cpp
+++ b/toolchain/check/cpp/type_mapping.cpp
@@ -27,6 +27,7 @@
 #include "toolchain/check/cpp/export.h"
 #include "toolchain/check/cpp/import.h"
 #include "toolchain/check/cpp/location.h"
+#include "toolchain/check/cpp/sum_type.h"
 #include "toolchain/check/literal.h"
 #include "toolchain/sem_ir/class.h"
 #include "toolchain/sem_ir/expr_info.h"
@@ -131,8 +132,8 @@
 // or a null type if lookup fails. `name_components` is the full path of the
 // type, including any namespaces or nested types, separated into separate
 // strings.
-static auto LookupCppType(
-    Context& context, std::initializer_list<llvm::StringRef> name_components)
+auto LookupCppType(Context& context,
+                   std::initializer_list<llvm::StringRef> name_components)
     -> clang::QualType {
   auto* type_decl = dyn_cast_or_null<clang::TypeDecl>(
       LookupCppDecl(context, name_components));
@@ -586,6 +587,16 @@
     }
   }

+  // Fork (SV-1, F-020): a `Core.CppCompat` sum type argument, or a
+  // `Core.Optional(T)` with a matchable non-pointer payload, is offered to
+  // overload resolution as the C++ class it converts to; the argument is
+  // converted by value when the call converts it to the parameter's type,
+  // which must be that class. Before `MapToCppType`, which would try, and
+  // diagnose, exporting the prelude type itself.
+  if (arg_cpp_type.isNull()) {
+    arg_cpp_type = MapCarbonSumTypeToCpp(context, form.loc_id, form.type_id);
+  }
+
   if (arg_cpp_type.isNull()) {
     arg_cpp_type = MapToCppType(context, form.type_id);
   }
```

<!-- google-doc-style-resume -->

### §2.8 toolchain/check/type.cpp

**Invariant** (rewritten 2026-10-20, review fold: A-M3): trunk's walk is
unchanged, and exactly one more type is admitted, a `Core.Optional` specific
whose qualifier-and-adapter walk reaches a pointer; every type trunk admits is
still admitted, and `Cpp.nullptr_t` and `Core.MaybeUnformed(T)` stay rejected
at all four call sites (§1.8).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/type.cpp
+++ b/toolchain/check/type.cpp
@@ -334,6 +334,31 @@
   return SemIR::InstId::None;
 }

+// Fork (SV-1, D-SV-8): whether `type_id` is the pointer-niche
+// `Core.Optional(T*)`, the type a nullable C++ `T*` imports as. It adapts
+// `MaybeUnformed(T*)`, whose `MaybeUnformed` type qualifier stops the
+// unqualify-then-adapt walk short of the pointer, so it is admitted by name,
+// with the walk that strips qualifiers and adapters together required to reach
+// a pointer; no other qualified adapter is admitted (`Cpp.nullptr_t` and
+// `Core.MaybeUnformed(T)` are not).
+static auto IsCoreOptionalOfPointer(Context& context, SemIR::TypeId type_id)
+    -> bool {
+  auto class_type = context.types().TryGetAs<SemIR::ClassType>(
+      context.types().GetUnqualifiedType(type_id));
+  if (!class_type || !class_type->specific_id.has_value()) {
+    return false;
+  }
+  const auto& class_info = context.classes().Get(class_type->class_id);
+  if (class_info.is_choice ||
+      !context.name_scopes().IsCorePackage(class_info.parent_scope_id) ||
+      context.names().GetAsStringIfIdentifier(class_info.name_id) !=
+          "Optional") {
+    return false;
+  }
+  return context.types().Is<SemIR::PointerType>(
+      context.types().GetTransitiveUnqualifiedAdaptedType(type_id).first);
+}
+
 auto IsInSliceChoicePayloadType(Context& context, SemIR::TypeId type_id)
     -> bool {
   auto adapted_type_id = context.types().GetTransitiveAdaptedType(
@@ -351,7 +376,8 @@
     return context.inst_blocks().Get(tuple_type->type_elements_id).empty();
   }
   return inst.Is<SemIR::IntType>() || inst.Is<SemIR::FloatType>() ||
-         inst.Is<SemIR::BoolType>() || inst.Is<SemIR::PointerType>();
+         inst.Is<SemIR::BoolType>() || inst.Is<SemIR::PointerType>() ||
+         IsCoreOptionalOfPointer(context, type_id);
 }

 }  // namespace Carbon::Check
```

<!-- google-doc-style-resume -->

### §2.9 toolchain/lower/constant.cpp

**Invariant** (rewritten 2026-10-20, review fold: A-m6): only an access whose
base constant is not already a pointer changes, and its base is addressed by
`FileContext::GetConstant`, function lowering's own cached global for a value
constant whose value representation is a pointer; every access into a
reference-category or addressed aggregate is unchanged.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/constant.cpp
+++ b/toolchain/lower/constant.cpp
@@ -63,6 +63,17 @@
     return file_context_->GetFunction(function_id);
   }

+  // Returns the address of the value constant `const_id`, as function lowering
+  // forms it when the value representation is a pointer (a cached internal
+  // global), or null when the value representation is not a pointer, so no
+  // element of the value has an address.
+  auto GetValueConstantAddress(SemIR::ConstantId const_id) -> llvm::Constant* {
+    auto* address = file_context_->GetConstant(const_id, SemIR::InstId::None);
+    return address->getType()->isPointerTy()
+               ? llvm::cast<llvm::Constant>(address)
+               : nullptr;
+  }
+
   auto GetVtable(SemIR::VtableId vtable_id, SemIR::SpecificId specific_id)
       -> llvm::Constant* {
     return file_context_->GetVtable(vtable_id, specific_id);
@@ -249,6 +260,23 @@
   auto* aggr_type = context.GetType(
       context.sem_ir().insts().Get(inst.aggregate_id).type_id());

+  // Fork (SV-1, D-SV-9): an element access is a reference into its aggregate,
+  // but a `ClassElementAccess` on a constant class VALUE folds to the
+  // element's value constant (eval of a value-category base), and a further
+  // access into that folded constant -- the payload tuple of a constant
+  // `choice` alternative, `match (Opt(i32).None) { case .Some(v: i32) ... }`
+  // -- then finds a value representation where it needs an address. Address
+  // it the way function lowering addresses a value constant whose value
+  // representation is a pointer: the cached internal global of
+  // `FileContext::GetConstant`.
+  if (!aggr_addr->getType()->isPointerTy()) {
+    aggr_addr = context.GetValueConstantAddress(
+        context.sem_ir().constant_values().Get(inst.aggregate_id));
+    if (!aggr_addr) {
+      return nullptr;
+    }
+  }
+
   auto* i32_type = llvm::Type::getInt32Ty(context.llvm_context());
   // For now, we rely on the LLVM type's GEP indexes matching the SemIR
   // aggregate element indexes.
```

<!-- google-doc-style-resume -->

### §2.10 toolchain/diagnostics/kind.def and toolchain/check/BUILD

kind.def, in the C++ interop group after `CppExportResultNeedsExpectedHeader`
(an X-macro list: every translation unit that includes it recompiles in a full
build; v4 appended the same eight kinds at the end instead, §2.0):

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/diagnostics/kind.def
+++ b/toolchain/diagnostics/kind.def
@@ -257,6 +257,14 @@
 CARBON_DIAGNOSTIC_KIND(CppReservedNameShadowed)
 CARBON_DIAGNOSTIC_KIND(CppCatchingImportNonScalarSuccess)
 CARBON_DIAGNOSTIC_KIND(CppExportResultNeedsExpectedHeader)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeNotMapped)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeTooManyAlternatives)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeNotTriviallyCopyable)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeQualifiedAlternative)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeAlternativeNotAdmitted)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeMismatch)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeReverseMismatch)
+CARBON_DIAGNOSTIC_KIND(CoreOptionalNotMatchable)
 CARBON_DIAGNOSTIC_KIND(InlineImportNotCpp)
 CARBON_DIAGNOSTIC_KIND(IncorrectExtension)
 CARBON_DIAGNOSTIC_KIND(IncorrectExtensionImplNote)
```

<!-- google-doc-style-resume -->

BUILD, the new translation unit and header in `//toolchain/check:check`'s
`srcs` and `hdrs`, alphabetical (the `fix-cc-deps` hook is skipped by the
prek invocation; no new dependency is needed, as sum_type.cpp includes only
headers of the same library, diagnostics' format_providers.h, which the library
already depends on, and clang's AST and Sema):

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/BUILD
+++ b/toolchain/check/BUILD
@@ -35,6 +35,7 @@
         "cpp/macros.cpp",
         "cpp/operators.cpp",
         "cpp/overload_resolution.cpp",
+        "cpp/sum_type.cpp",
         "cpp/thunk.cpp",
         "cpp/type_mapping.cpp",
         "custom_witness.cpp",
@@ -102,6 +103,7 @@
         "cpp/macros.h",
         "cpp/operators.h",
         "cpp/overload_resolution.h",
+        "cpp/sum_type.h",
         "cpp/thunk.h",
         "cpp/type_mapping.h",
         "custom_witness.h",
```

<!-- google-doc-style-resume -->

### §2.11 Conformance programs and golden sources

The six programs of §1.13 are reproduced in Appendix A and the golden sources of
§1.12, without CHECK lines, in Appendix B; both are byte copies of the files v4
ran (`$X/final/progs/`, `$X/final/goldens-src/`, whose fills are
`$X/final/goldens-filled/`), and the implementer copies them, never retypes them
(amended 2026-10-20, review fold: all findings). At rev 3 the golden sources and
fills are `$Z/final/goldens-src/` and `$Z/final/goldens-filled/` (v5; the
programs are unchanged and v5 runs them, §0.6), and the M-VA split's fill is
`$Z/final/goldens-filled-M/` (amended 2026-10-20, review fold: RR-B1 / RR-M1).
At rev 4 they are `$W/final/goldens-src/`, `$W/final/goldens-filled/` and
`$W/final/goldens-filled-M/` (v6 and vav6g; amended 2026-10-20, review fold:
RR3-B1 / RR3-M1 / RR3-m4).

## §3 Commits

One PR, "SV-1: `std::optional` and `std::variant` interop mapping" (R29(b)).
Each implementation commit compiles alone and is judged with its fill: alone
it is red exactly on the goldens it adds or refills and on nothing else, with
no crash. Commit messages end with the session trailers; `--author` and the
committer are the workstream's (R20: explicit paths only). Amended 2026-10-20
(review fold: all findings).

0.  **Plan.** Rev 1, "SV-1 plan (rev 1): std::optional and std::variant interop
    mapping" (3287b1072); rev 2 (4d85d14fe) folds the two plan reviews (R29(c));
    rev 3 (4eef66632) folds the focused re-review of rev 2 (REJECT, six
    findings; amended 2026-10-20, review fold: all RR findings); rev 4
    (66deca5ce) folds the focused re-review of rev 3 (REJECT, six findings;
    amended 2026-10-20, review fold: all RR3 findings); rev 5 (this file) folds
    the focused re-review of rev 4 (APPROVE-WITH-AMENDMENTS, four findings) and
    is signed off (amended 2026-10-20, review fold: all RR4 findings).
1.  **C1** "SV-1 (1): Core.CppCompat sum types in the prelude; nullable
    pointer payloads; constant aggregates in lowering": core/prelude/types/cpp
    /sum.carbon, core/prelude/types.carbon, toolchain/check/type.cpp (D-SV-8),
    toolchain/lower/constant.cpp (D-SV-9); new goldens
    choice/optional_pointer_payload.carbon and
    lower/match/constant_choice_scrutinee.carbon, and fail_catching.carbon's
    `fail_nullptr_return` split; the four function-pointer goldens of §0.6 go
    red (their only change, the prelude file's). **F1** fills the three and
    refills the four.
2.  **C2** "SV-1 (2): std::optional and std::variant convert by value to and
    from their Carbon sum types and are matched as them": custom_type_mapping
    .{h,cpp}, cpp/sum_type.{h,cpp} without the `Core.Optional` parts
    (`GetCoreOptionalView`, `DiagnoseCoreOptionalNotMatchable`, the
    `Core.Optional` branches of `TryConvertCppSumType` and
    `MapCarbonSumTypeToCpp`, and the `CoreOptionalNotMatchable` kind),
    convert.cpp, refutable_binding.cpp's C++ branch, cpp/type_mapping.{h,cpp},
    diagnostics/kind.def (seven kinds), check/BUILD; new goldens
    stdlib/optional.carbon without `one_step_core_optional`,
    stdlib/variant.carbon, stdlib/fail_sum_types.carbon without
    `fail_core_optional_mismatch`,
    stdlib/sum_type_overload.carbon, lower/interop/cpp/std_sum_types.carbon.
    **F2**.
3.  **C3** "SV-1 (3): Core.Optional converts to and from std::optional in one
    step, and a Core.Optional scrutinee is matched as its StdOptional view":
    the `Core.Optional` parts of sum_type.{h,cpp} and type_mapping.cpp, the
    `CoreOptionalNotMatchable` kind, refutable_binding.cpp's second branch; new
    golden match/core_optional_view.carbon and the two splits C2 left out.
    **F3**.
4.  **P** "SV-1 (4): conformance programs for the sum-type interop mapping":
    match_sum_type_payload.carbon un-SKIPped with its intended body (the
    `default` removal stated in its header), the five new programs, the
    regenerated README table, `runner.py --self-test`.
5.  **Doc** "SV-1 (5): design: C++ std::optional and std::variant": the dated
    section of docs/design/sum_types.md and the link in unions.md, verbatim from
    Appendix C.1 and C.2 (§1.14), without C.1's `<...>` pack-element line, which
    M-VA writes (item 8; amended 2026-10-20, review fold: RR4-m2).
6.  **Implementation reviews** A and B on the head (not commits).
7.  **Fix commits**, at most three, each with its fill (the budget); the
    **shrink line**, in order: first drop C3 and match_core_optional_diff
    (the one-step conversions and the view; W-177 stays as filed, and
    W-278 is filed after all, Appendix C.4 has its text), then drop the
    reverse direction (the `InventClangArg` mapping and
    `ConvertCarbonSumToCpp`; the roundtrip program and the reverse splits
    leave, and W-283 is filed for "Carbon to C++"). Row 68 stays PARTIAL in
    both cases, as predicted anyway (§1.17). Nothing else is cut: the forward
    conversion, the probe-safe hook and the scrutinee gate are the arbiter.
8.  **Held state (the land-time commits, specified now; amended 2026-10-20,
    review fold: A-m1 / B-M-3 / B-M-4).** While the queue is held, nothing
    merges; the compositions of §8.6 are measured on scratch mirrors at
    implementation time and recorded in D. When PR 61 has landed: **M**, the
    merge of trunk (never a rebase), resolving conflicts only by the rules of
    §0.7 (record files take trunk's text; the README table is regenerated);
    **M-VA** "SV-1: a sum-type conversion of a VA-1 pack element is a TODO"
    (amended 2026-10-20, review fold: RR-M1; RR3-B1), the hunk below
    (`$W/land/m-va-pack-element.diff`: `CanBuildBranches` takes the converted
    value and refuses it when `IsPackElementOrProjection` walks it back, through
    `TupleAccess`, `StructAccess`, `ArrayIndex`, `ClassElementAccess`,
    `AsCompatible`, `AcquireValue` and `ValueAsRef`, to a `SemIR::PackElement`,
    an instruction kind that exists only once PR 59 has landed; rev 3's hunk
    tested a bare `PackElement`, which misses the element of a pack of tuples,
    structs, arrays or classes), the `fail_todo_pack_element` split appended to
    stdlib/fail_sum_types.carbon (Appendix B), filled by autoupdate, and C.1's
    pack-element line inserted into docs/design/sum_types.md's list of 0.1
    limits, with R31's counts (amended 2026-10-20, review fold: RR4-m2);
    measured on the PR 59 composition (vav6g, §0.6), it leaves VA-1's goldens
    unchanged, without it the split stops the compiler at VA-1's CHECK (M19),
    and with rev 3's bare test it stops there too (M21); M-VA files no record
    (W-284 is filed at D, item 10; amended 2026-10-20, review fold: RR3-m1); if
    PR 59 has not landed at M, M-VA waits for it and is the first commit after
    the merge that brings it. The block below differs from the file only in two
    whitespace-only context lines (blank in the block, one space in the file),
    and applies to §2.4's sum_type.cpp as it stands, giving the file's result
    (measured);

    <!-- google-doc-style-ignore -->

    ```diff
    --- a/toolchain/check/cpp/sum_type.cpp
    +++ b/toolchain/check/cpp/sum_type.cpp
    @@ -244,6 +244,36 @@
       builder.Emit();
     }

    +// Returns whether `value_id` is a VA-1 pack element, or is projected from one
    +// by the element, field and category steps of a conversion.
    +static auto IsPackElementOrProjection(Context& context, SemIR::InstId value_id)
    +    -> bool {
    +  while (value_id.has_value()) {
    +    auto inst = context.insts().Get(value_id);
    +    if (inst.Is<SemIR::PackElement>()) {
    +      return true;
    +    }
    +    if (auto access = inst.TryAs<SemIR::TupleAccess>()) {
    +      value_id = access->tuple_id;
    +    } else if (auto access = inst.TryAs<SemIR::StructAccess>()) {
    +      value_id = access->struct_id;
    +    } else if (auto index = inst.TryAs<SemIR::ArrayIndex>()) {
    +      value_id = index->array_id;
    +    } else if (auto access = inst.TryAs<SemIR::ClassElementAccess>()) {
    +      value_id = access->base_id;
    +    } else if (auto compat = inst.TryAs<SemIR::AsCompatible>()) {
    +      value_id = compat->source_id;
    +    } else if (auto acquire = inst.TryAs<SemIR::AcquireValue>()) {
    +      value_id = acquire->value_id;
    +    } else if (auto ref = inst.TryAs<SemIR::ValueAsRef>()) {
    +      value_id = ref->value_id;
    +    } else {
    +      return false;
    +    }
    +  }
    +  return false;
    +}
    +
     // Returns whether a branching conversion can be built at `loc_id`, and emits a
     // TODO when it cannot. It cannot outside a function body -- a file-scope
     // initializer (W-036's limit, which every branching expression shares) or a
    @@ -252,8 +282,10 @@
     // expression to attribute its blocks to. These are limits of the toolchain, not
     // of the types, so a non-diagnosing caller does not test them: an `overload fn`
     // probe accepts the pair, and the committed call emits the TODO, so which
    -// member a call selects does not depend on where the call is.
    -static auto CanBuildBranches(Context& context, SemIR::LocId loc_id) -> bool {
    +// member a call selects does not depend on where the call is. `value_id` is the
    +// value converted, if any.
    +static auto CanBuildBranches(Context& context, SemIR::LocId loc_id,
    +                             SemIR::InstId value_id) -> bool {
       if (!context.scope_stack().IsInFunctionScope()) {
         context.TODO(loc_id,
                      "conversion of a C++ `std::optional` or `std::variant` "
    @@ -268,6 +300,17 @@
                      "with no source expression");
         return false;
       }
    +  // A pack element (VA-1) is converted in a block that runs once per element
    +  // -- an expansion body, or convert.cpp `ConvertPackToPack` -- and is one
    +  // straight-line block, which cannot hold branches. The value is the element,
    +  // or what a tuple, struct, array, class or adapter conversion projects from
    +  // it.
    +  if (IsPackElementOrProjection(context, value_id)) {
    +    context.TODO(loc_id,
    +                 "conversion of a C++ `std::optional` or `std::variant` "
    +                 "for a pack element");
    +    return false;
    +  }
       return true;
     }

    @@ -276,7 +319,7 @@
     // branch (`CanBuildBranches`).
     static auto GetNodeIdForBranches(Context& context, SemIR::LocId loc_id)
         -> Parse::NodeId {
    -  if (!CanBuildBranches(context, loc_id)) {
    +  if (!CanBuildBranches(context, loc_id, SemIR::InstId::None)) {
         return Parse::NodeId::None;
       }
       return context.insts().GetCanonicalLocId(loc_id).node_id();
    @@ -778,7 +821,7 @@
       if (!diagnose) {
         return MakeTestedConversion(context, loc_id, target_type_id);
       }
    -  if (!CanBuildBranches(context, loc_id)) {
    +  if (!CanBuildBranches(context, loc_id, value_id)) {
         return SemIR::ErrorInst::InstId;
       }
       if (value_type_id != sum_type_id) {
    @@ -844,7 +887,7 @@
         if (!diagnose) {
           return MakeTestedConversion(context, loc_id, target_type_id);
         }
    -    if (!CanBuildBranches(context, loc_id)) {
    +    if (!CanBuildBranches(context, loc_id, value_id)) {
           return SemIR::ErrorInst::InstId;
         }
         auto sum_id = ConvertCppSumToCarbon(context, loc_id, value_id, sum_type);
    ```

    <!-- google-doc-style-resume -->

    **F-M**, the refill of what the merge changes: measured
    now on op2v4 and tpv4 (§0.7), decayed_param.carbon and the other three
    function-pointer goldens once, over PR 57's and SV-1's changes together,
    and SV-1's stdlib/optional.carbon, choice/optional_pointer_payload.carbon
    and match/core_optional_view.carbon (OP-2's `Destroy` entries; no
    diagnostic line changes), and any golden of SC-1, VA-1 or TP-1 that the
    merged toolchain changes (predicted none on TP-1's, measured; SC-1's and
    VA-1's at the mirrors); the dry runs of §8.6 repeated against that day's
    heads first; **Doc-M** "SV-1 (6): design: optional.md amended for the
    std::optional mapping": docs/design/optional.md's anchored edits and the
    decision log's F-015 amendment, verbatim from Appendix C.3 and C.8's
    amendment paragraph, with R31's counts and check_samples.py (§8 item 11).
9.  **R** "SV-1 (7): gap row 68": the row and the header, by §1.17 and
    Appendix C.7, after M.
10. **D** "SV-1 (8): discharge": the id re-scan of §8.7 first; W-011 DISCHARGED,
    W-177's narrowing note, W-275, W-276, W-277, W-279, W-280, W-281 and W-285
    filed (W-285 added 2026-10-20, review fold: RR4-M1), W-284 filed once M-VA
    has landed and held until it has (amended 2026-10-20, review fold: RR3-m1),
    W-282 by its condition, W-278 and W-283 by the shrink line's, the notes on
    W-036, W-047, W-049, W-122 and W-252, and on W-263 if it is on the merged
    trunk and open (amended 2026-10-20, review fold: RR4-m1), the decision-log
    entry, fork/ORCHESTRATION.md's row and Next actions item, verbatim from
    Appendix C with only the `<...>` values substituted; after the two
    implementation reviews. The texts are frozen by the plan reviews: a change
    to anything but a placeholder goes to a document review first (§1.14).

## §4 Testdata matrix

Key lines each fill reproduces, measured on v4 (`$X/final/goldens-filled/`;
rewritten 2026-10-20, review fold: all findings), again on v5
(`$Z/final/goldens-filled/`, byte-identical but for sum_type_overload.carbon;
amended 2026-10-20, review fold: all RR findings) and on v6
(`$W/final/goldens-filled/`, byte-identical to v5's but for
sum_type_overload.carbon; amended 2026-10-20, review fold: all RR3 findings),
and at rev 5 on v6 again (`$Y/final/goldens-filled/`, byte-identical to v6's but
for fail_sum_types.carbon's two new splits; amended 2026-10-20, review fold:
RR4-M1): every diagnostic below is the final text, not a prototype TODO. Refills
by name.

| Golden | Key lines the fill must reproduce |
| --- | --- |
| stdlib/optional.carbon `match` | `%has_value__carbon_thunk.call`, `if ... br ... else br`, `%value__carbon_thunk.call`, `%StdOptional.Some.call`, the `%StdOptional.val` constant copied in the other arm, `class_type @StdOptional, @StdOptional(%i32)`; no `default`, no error |
| `if_let` | the same conversion feeding the refutable binding |
| `convert` | `%optional__carbon_thunk.call` (default construction), `%emplace__carbon_thunk.call`, `%Take__carbon_thunk.call` twice and `%TakeRef__carbon_thunk.call` |
| `pointer_payload` | the payload type `Core.Optional(i32*)`; `%value__carbon_thunk.call` |
| `bridge` | the two impls' `Convert` calls, `StdOptional(i32)` to `Core.Optional(i32)` and back |
| `one_step_core_optional` (rev 2) | `%has_value__carbon_thunk`, `%value__carbon_thunk`, then `%StdOptional.as.ImplicitAs.impl.Convert.specific_fn` for the initializer; `%Optional.as.ImplicitAs.impl.Convert` and the reverse conversion's `%emplace__carbon_thunk` before `%Take__carbon_thunk` and `%TakeRef__carbon_thunk`; no error |
| `monostate_payload` (rev 2) | no error (the split dumps no SemIR; x09 runs both directions, 1 0 1 0) |
| `fail_todo_struct_payload` | ``error: C++ type `std::optional<Point>` has no Carbon sum type [CppSumTypeNotMapped]`` and ``note: alternative 0 has type `Point`, which is not a choice payload type in 0.1 [CppSumTypeAlternativeNotAdmitted]`` |
| `fail_dead_default` | ``error: `default` arm never matches; every value of the scrutinee is matched by prior arms [MatchDefaultNeverMatches]`` with the `MatchDefaultNeverMatchesFullCoverage` note naming `Core.CppCompat.StdOptional(i32)` |
| `fail_unknown_alternative` | ``error: member name `Ok` not found in `Core.CppCompat.StdOptional(i32)` [MemberNameNotFoundInSpecificScope]`` |
| `fail_todo_outside_function` | ``error: semantics TODO: `conversion of a C++ `std::optional` or `std::variant` outside a function body (at file scope, or deferred to a template's instantiation)` [SemanticsTodo]`` |
| `fail_todo_ref_binding` (rev 2) | ``error: cannot bind durable reference to non-reference value of type `i32` [ConversionFailureNonRefToRef]`` |
| stdlib/variant.carbon `match` | `%index__carbon_thunk.call` once, `%get__carbon_thunk.call` per arm, `%StdVariant2.Alt0.call` / `%StdVariant2.Alt1.call` |
| `monostate` | the `()` payload `tuple_value ()` in arm 0; `StdVariant2((), i32)` |
| `duplicate` | `class_type @StdVariant2, @StdVariant2(%i32, %i32)` |
| `fail_todo_too_many_alternatives` | ``error: C++ type `std::variant<int, int, int, int, int, int, int, int, int>` has no Carbon sum type`` with ``note: `std::variant` with 9 alternatives; at most 8 have a Carbon sum type [CppSumTypeTooManyAlternatives]`` |
| `fail_todo_nested_by_value` | ``error: C++ type `std::variant<std::optional<int>, int>` has no Carbon sum type`` with ``note: alternative 0 has type `std::optional<int>`, which is not a choice payload type in 0.1`` |
| `fail_index_out_of_range` | ``error: member name `Alt2` not found in `Core.CppCompat.StdVariant2(i32, f64)` [MemberNameNotFoundInSpecificScope]`` |
| stdlib/fail_sum_types.carbon | `fail_todo_qualified_alternative`: ``C++ type `std::optional<const int>` has no Carbon sum type`` with ``alternative 0 has qualified or reference type `const int` [CppSumTypeQualifiedAlternative]``; `fail_todo_non_trivial`: with ``note: `std::optional<NonTrivial>` is not trivially copyable and trivially destructible [CppSumTypeNotTriviallyCopyable]``; `fail_conversion_mismatch` and `fail_core_optional_mismatch`: ``C++ type `std::optional<int>` converts only to its own Carbon sum type `Core.CppCompat.StdOptional(i32)` or to the `Core.Optional` of its payload, not to `Core.CppCompat.StdOptional(i64)` [CppSumTypeMismatch]`` (and `` `Core.Optional(i64 as Core.OptionalStorage)` ``); `core_optional_argument_as`: no error; `fail_todo_export_sum_type`: the three existing export errors (`interop with non-identifier package name` at `{{.*}}/prelude/types/cpp/sum.carbon:30:1`, `failed to map Carbon return type to C++ type`, `no member named 'MakeView' in namespace 'Carbon'`); `fail_reverse_other_specialization` and `fail_reverse_converting_class`: `` `Core.CppCompat.StdOptional(i32)` converts to C++ only as the `std::optional` or `std::variant` whose Carbon sum type it is, not to `std::optional<long>` [CppSumTypeReverseMismatch]`` (and `` `Wrapper` ``), each with the `InCallToFunctionParam` note; `fail_todo_tuple_scrutinee`: ``semantics TODO: `match on unsupported scrutinee type` ``; `fail_todo_if_arm`: ``semantics TODO: `destroying temporaries of a conditionally evaluated operand whose value is not passed by copy` ``; `fail_todo_template_conversion`: ``unable to monomorphize specific `Pass(Cpp.std.__1.optional)` [ResolvingSpecificHere]`` with the outside-a-function-body TODO as its note; `fail_todo_rvalue_ref_param` (rev 5; amended 2026-10-20, review fold: RR4-M1): ``semantics TODO: `conversion of a C++ `std::optional` or `std::variant` with no source expression` [SemanticsTodo]`` twice, at `./sink.h:4:45` and `./sink.h:12:38` (the `T&&` parameters of `TakeRvalue` and of `Put`), each with the `InCallToFunctionParam` note there and ``in file included here [InCppInclude]`` at the split's `import Cpp`; `V`, whose value argument selects `Put`'s `const&` member, has none; mutant M22 removes the first |
| stdlib/sum_type_overload.carbon (rev 2; rev 3: amended 2026-10-20, review fold: RR-B1 / RR-B-1 / RR-m1; rev 4: amended 2026-10-20, review fold: RR3-M1 / RR3-m4) | sixteen splits: the fourteen that are not `fail_` have no diagnostic, `scalar_tuple_mismatch_first` included (trunk gives it ``cannot implicitly convert expression of type `bool` to `i32` ``, z01); `fail_todo_file_scope`: ``error: semantics TODO: `conversion of a C++ `std::optional` or `std::variant` outside a function body (at file scope, or deferred to a template's instantiation)` [SemanticsTodo]`` at `Pick(Cpp.MakeOptional(7))` with the `InCallToFunctionParam` note naming the first member's parameter; `fail_todo_template_overload`: ``error: unable to monomorphize specific `Call(Cpp.std.__1.optional)` [ResolvingSpecificHere]`` with that TODO as its note at `Pick(x)` and the same `InCallToFunctionParam` note (measured on v6, and unchanged on tpv6 and vav6g); the mutants M12 and M17 stop file_test on it with ``Built invalid semantics IR: No terminator in block``, and M20 (rev 3's rule) turns both `fail_todo_` splits red, each compiling with no diagnostic |
| stdlib/fail_sum_types.carbon `fail_todo_pack_element` (at M-VA; rev 3, amended 2026-10-20, review fold: RR-M1; rev 4, amended 2026-10-20, review fold: RR3-B1) | ``error: semantics TODO: `conversion of a C++ `std::optional` or `std::variant` for a pack element` [SemanticsTodo]`` ten times, at the calls of `Forward`, `Back`, `ForwardTuple`, `BackTuple`, `ForwardStruct`, `BackStruct`, `ForwardArray`, `BackArray`, `ForwardClass` and `BackClass`, each with the `InCallToFunctionParam` note (measured on vav6g, `$W/final/goldens-filled-M/`); the file's other splits unchanged; M19 and M21 stop the compiler at VA-1's CHECK on it |
| choice/optional_pointer_payload.carbon | `pointer`: no error, the payload `Core.Optional(i32*)` in the alternative's parameter; `fail_todo_non_pointer_optional`, `fail_todo_nullptr_payload`, `fail_todo_maybe_unformed_payload`: ``error: semantics TODO: `choice alternative payload that is not trivially copyable and destructible` [SemanticsTodo]`` |
| match/core_optional_view.carbon | `concrete`: the bridge's `Convert` call on the scrutinee, then the choice dispatch on `StdOptional(i32)`; `pointer`: no error; `fail_todo_generic`: ``error: cannot match `Core.Optional(T as Core.OptionalStorage)` in 0.1: its payload type is symbolic [CoreOptionalNotMatchable]``; `fail_todo_aggregate`: ``... `Core.Optional((i32, i32) as Core.OptionalStorage)` in 0.1: its payload type is not a choice payload type [CoreOptionalNotMatchable]``; `fail_todo_ref_binding`: the `ConversionFailureNonRefToRef` error; `fail_unknown_alternative`: ``member name `Ok` not found in `Core.CppCompat.StdOptional(i32)` `` |
| exceptions/fail_catching.carbon `fail_nullptr_return` (rev 2) | ``error: catching import of `may_throw_null` requires a scalar success type in 0.1; `Cpp.nullptr_t` is not one [CppCatchingImportNonScalarSuccess]``; the file's other splits unchanged |
| lower/interop/cpp/std_sum_types.carbon | `define internal ... @_ZNKSt3__18optionalIiE9has_valueEv.carbon_thunk._`, `... value ... .carbon_thunk._`, `@_ZNKSt3__17variantIJidEE5indexEv.carbon_thunk._`, two `std::get<I>` thunks, the two `emplace` thunks, `linkonce_odr void @_CSome.StdOptional.CppCompat.Core.<hash>`; the Carbon layouts `<{ <{ i1, [3 x i8] }>, [4 x i8] }>` and `<{ <{ i1, [7 x i8] }>, [8 x i8] }>` beside the mock's `%"class.std::__1::optional" = type <{ i32, i8, [3 x i8] }>` |
| lower/match/constant_choice_scrutinee.carbon | `@uninit.060.anon = internal constant [4 x i8] zeroinitializer` and `load i32, ptr @uninit.060.anon` (rev 2's routed global; rev 1 pinned `@const.aggr`) |
| refills: function/import/{carbon_fn_as_callable, decayed_param, function_ptr, method_ptr}.carbon | only `cpp_fn_ptr_type clang_function_pointer_type<N>` changes, 17 lines in all (34 lines of diff, §0.6) |

## §5 Conformance delta

From the floor of record, 128 PASS / 0 FAIL / 22 SKIP over 150 (trunk
scoreboard; gap-analysis header), tree-relative: **+6 PASS, -1 SKIP, +5
programs**, so 134 / 0 / 21 over 155 on SV-1's own tree; the absolute count at
landing is re-quoted from the merged trunk's scoreboard, never derived (R9),
since every held PR adds programs first (TP-1 alone expects 137/0/22 over
159). Programs that move: control_flow/match_sum_type_payload (SKIP to PASS);
new and PASS: control_flow/match_std_optional_diff,
control_flow/match_std_variant_diff, control_flow/match_core_optional_diff,
interop/cpp_sum_type_roundtrip_diff, control_flow/cpp_sum_type_library. No
other program changes status (the existing programs' toolchain paths are
untouched, §2.5 to §2.9). Bullets: the row-68 bullet already rolls up PASS
(§0.8), so 48/56 stays 48/56.

**Measured on v4** (added 2026-10-20, review fold: all findings): the full
suite, fork/conformance/runner.py over a copy of the worktree with the six
programs of Appendix A (`/dev/shm/sv1-fixer/confwt`), v4 behind the link
wrapper of §0.0 (`$X/runs/conf-v4.log`):
134 PASS / 0 FAIL / 21 SKIP over 155, bullets 48 PASS, 0 FAIL, 8 SKIP
of 56, runner exit 0 (scoreboard copied to `$X/runs/conf-v4-scoreboard.json`).
The six programs PASS, the row-68 bullet rolls up PASS over its 11 programs,
and every other non-SKIP program passes, so no other program changed status
(a SKIP is declared in its program's header, not decided by the toolchain).
The prediction above is met exactly.

## §6 Churn and collisions

Recounted 2026-10-20 from `$X/final/final.diff` (rev 1 said "nine changed" and
listed ten; erratum, review fold: B-m-8), at rev 3 from `$Z/final/final.diff`
(amended 2026-10-20, review fold: all RR findings), and at rev 4 from
`$W/final/final.diff` (amended 2026-10-20, review fold: all RR3 findings).
Toolchain: two new files (cpp/sum_type.h, 143 lines, and cpp/sum_type.cpp, 935
lines, formatted) and ten changed: custom_type_mapping.h +28,
custom_type_mapping.cpp +53, convert.cpp +22/-7 (the hook, and
`ConvertAggregateElement`'s `diagnose` parameter with its four callers),
refutable_binding.cpp +38 (its include moved to sorted order),
cpp/type_mapping.h +7, cpp/type_mapping.cpp +13/-2, type.cpp +27/-1,
lower/constant.cpp +28, diagnostics/kind.def +8, check/BUILD +2. Core: one new
file (sum.carbon, 129 lines) and one line. Testdata: eight new goldens, one
split appended to interop/cpp/exceptions/fail_catching.carbon, four refills (and
seven more at F-M, §3 item 8); at M-VA, sum_type.cpp's land-time hunk (+47/-5;
rev 3's was +18/-5) and one split appended to stdlib/fail_sum_types.carbon.
Conformance: one changed program, five new (one a directory of three files),
four new `.diff.cpp` oracles and one `main.diff.cpp`, the README table. Docs:
sum_types.md, unions.md (one link), optional.md after M. Records at R and D.
Collisions and their rules: §0.7; the land-time order: §3 item 8.

## §7 Risks and rejected alternatives

### §7.1 Risks (each falsifiable)

-   **R-1, the mocks drift from libc++.** The goldens mock `std::optional`
    and `std::variant`; the programs use the toolchain's libc++ 24.0. A
    divergence that matters shows as a program failure against its oracle,
    which is real libc++ on the C++ side too.
-   **R-2, cost.** Prelude: +5% check time at p10 on a trivial file
    (measured, §0.6); every full-prelude compile pays it, programs without C++
    included. Code: one internal thunk per accessor per specialization and
    file (measured). Falsified if the trivial-file check time of the full
    prelude (`$P/bin/ptime.py`, 60 alternating runs) grows by more than 5% at
    p10 against trunk at implementation (rewritten 2026-10-20, review fold:
    A-m7 / B-m-10: rev 1's falsifier was the gate's wall time, which mostly
    runs the min prelude and cannot see the cost); then the arity bound drops
    to 4.
-   **R-3, PR 57's representation.** The bridge uses only `Optional`'s API,
    and D-SV-8's name test reaches the pointer through PR 57's
    `MaybeUnformed(T*)`: measured on op2v4 (o04, s05, d04; §0.7). Falsified by
    a later change to `Optional`'s storage (the mirror of §8.6 at M).
-   **R-4, the internal template-argument path.** `std::get<I>` and
    `emplace<I>` rely on `PerformCppOverloadResolution`'s `template_arg_ids`
    with an integer literal. Falsified if UA-3 (the next upstream advance)
    changes that signature; the adaptation is local to sum_type.cpp.
-   **R-5, copies** (rewritten 2026-10-20, review fold: B-M-2). Matching a C++
    sum value or a `Core.Optional` matches a by-value copy, so it is not
    by-reference matching, and that IS observable: a `ref` payload binding is
    rejected (W-280), where a native `choice` `var` scrutinee binds into the
    object. For admitted alternatives the copy is a scalar or pointer copy,
    so reads agree with by-reference matching; a mutation through the binding
    is the observable difference, and it is diagnosed. Falsified if a program
    whose arms only read shows a different value from its C++ oracle (the
    programs of §1.13 do not).
-   **R-6, other standard libraries.** The matchers key on the template name
    in namespace `std` and the accessors are standard, so libstdc++ would
    work in principle; it is not shipped with the toolchain and not measured.
-   **R-7, valueless variants** (rewritten 2026-10-20, review fold: A-m2) are
    reachable for admitted alternatives through a throwing conversion inside
    `emplace` (a9), and fail-stop through the fence (§0.5). Falsified if a
    valueless variant converts without terminating.
-   **R-8, the probe's stand-in** (added 2026-10-20, review fold: A-B1 /
    B-B-1; rewritten 2026-10-20, review fold: RR-m2 / RR-B1). A
    non-diagnosing conversion returns a `temporary_storage` read as a value,
    never initialized. It is safe because no non-diagnosing caller can
    observe it: call.cpp's probe and import.cpp:1316 discard it, and
    deduction (deduce.cpp:345 and :570) keeps only a constant result and
    rejects any other, while neither the stand-in nor the branched
    conversion it stands for is ever a constant, so deduction treats both
    alike. And it is reached only with `diagnose` false for every
    conversion a probe performs, which needs `ConvertAggregateElement` to
    pass the flag to elements (§2.5). Falsified by a branched conversion
    that yields a constant, by a non-diagnosing caller that keeps a
    non-constant result, or by an element conversion reached with
    `diagnose` true inside a probe (mutant M17's shape); then D-SV-4's
    break condition applies.
-   **R-9, TP-1's template `match`** (added 2026-10-20, review fold: A-M1;
    amended 2026-10-20, review fold: RR3-m3): X-1 (pattern_match.cpp:1409 on
    TP-1's pushed head) is TP-1's, and TP-1's round-10 head eafca5cb9 fixes it
    (x19 compiles and prints 0 on tpv6), so W-282 is predicted unused. Falsified
    if x19 still stops the merged trunk at D (a template `match` on a sum type
    would then stop the compiler without any SV-1 code in the path), and then
    W-282 is filed. The round-10 fix also edits refutable_binding.cpp, beside
    SV-1's scrutinee hook (§0.7); its first hunk applies with fuzz 1, and tpv6
    gates clean.
-   **R-10, compositions with held PRs that convert in single-block regions**
    (added 2026-10-20, review fold: RR-M1; rewritten 2026-10-20, review fold:
    RR3-B1). VA-1 converts pack elements in one straight-line block and CHECKs
    it; M-VA keeps SV-1's conversion out of it by walking the converted value
    back through the projections a conversion takes of an element
    (`TupleAccess`, `StructAccess`, `ArrayIndex`, `ClassElementAccess`,
    `AsCompatible`, `AcquireValue`, `ValueAsRef`) to a `SemIR::PackElement`.
    Rev 3's test recognized only a bare `PackElement`, and the re-review of
    rev 3 measured that its stated detector (v02 to v07) held no aggregate
    element: n01 to n05, a pack of tuples, structs, arrays or classes holding a
    sum type, crashed vav5g. The walk was chosen over marking the region in
    VA-1's code (a flag that `ConvertPackToPack` and the expansion bodies set
    and `CanBuildBranches` reads), which is more general but edits VA-1's
    convert.cpp, handle_pack_expansion.cpp and `Context` at land time; the walk
    is local to SV-1's file and measured. Falsified if a held PR or a later
    slice converts, in such a block, a value that the walk does not reach
    (another single-block region, or a pack element projected through another
    instruction kind): the PR 59 mirror's probes (`$W/probes/va/`, `vn/` and
    `vn4/`: v02 to v07, n01 to n10 and n13 to n22) and the M-VA split's ten
    calls detect it, and mutant M21 shows that the split catches rev 3's
    narrower test; then the region is marked instead (§1.4's break condition).

### §7.2 Rejected alternatives

-   **R-A, reinterpret the libc++ layout.** Rejected on measurement (§0.5):
    payload-first against discriminant-first, an engaged `bool` against
    `Some` = 0, an `unsigned char` index with a valueless sentinel against an
    `i1`; and the layout is private to the library and its ABI macros. The W5
    plan already said "not a reinterpret"; the measurement says why.
-   **R-B, an access interface with a synthesized witness** (SL-2's
    `CppContiguousRange` shape: the prelude declares the choices, an
    interface per arity and blanket `ImplicitAs` impls; impl_lookup.cpp
    synthesizes the witness from C++ members). Measured: it works for the C++
    to Carbon direction of `std::optional` in plain user code on trunk
    (`u01`); but the reverse cannot reach C++ overload resolution through
    `ImplicitAs` (`u02`: `no matching function for call to 'TakeOpt'`), so
    `InventClangArg` needs the same mapping anyway; `std::get<I>` and
    index-tagged construction are not single C++ member functions, so the
    witness needs new generated C++ helpers (a new thunk kind); and the
    prelude grows by an interface and two impls per arity, +21% check time at
    eight arities against this plan's +5% (§0.6).
-   **R-C, a synthesized choice entity per specialization** (SF-8's default
    lean). §1.1's affirmative justification: no source-less choice exists, its
    identity across files and libraries would be new, and an anonymous type
    cannot appear in a Carbon library's signature.
-   **R-D, the identity mapping** (replace the imported class with the
    choice, as `std::span` is replaced by `Core.Slice`). Rejected: the layouts
    differ, and pointers and references to the C++ object (`s20`, `w09`)
    could not be represented.
-   **R-E, make `Core.Optional` a choice.** Examined and rejected: D-EH-1
    keeps the class; PR 56 and PR 57 redesign it as a class (F-015, F-016);
    `Core.Optional(T*)` is ABI-compatible with a C++ nullable pointer through
    its storage (optional.carbon:186-203), which a choice's
    discriminant-first layout is not; the entry point's
    `argv: Core.Optional(char*)*` relies on it; and the identity is W-058's
    decision. What a choice would give for scalar and pointer payloads, the
    view of §1.7 gives without touching the class.
-   **R-F, `.0(x)` alternative names**: a parse error (`m17`).
-   **R-G, alternatives named by type**: undefined for duplicates.
-   **R-H, `std::variant<T, E>` as `Core.Result(T, E)`**: positional
    alternatives carry no `Ok`/`Err` meaning; `a08` stays an error.
-   **R-I, one-step implicit `std::optional<T>` to `Core.Optional(T)`**:
    rejected at rev 1, ADOPTED at rev 2 for non-pointer payloads in both
    directions (§1.7; review fold: B-M-5).
-   **R-J, widening SF-6 to trivially copyable structs here**: it changes every
    choice's payload rule and its `Copy`/`Destroy` witnesses (W-010's
    residue); out of this slice.
-   **R-K, one synthesized Carbon function per specialization** (D-SV-4's break
    condition, offered by both reviews for B1; added 2026-10-20, review fold:
    A-B1 / B-B-1). It would make every conversion one call, which a probe can
    discard and a file-scope initializer and a template instantiation can hold.
    Not adopted now: the fork has no checker-built function with a body of its
    own (thunk.cpp's deferred definitions forward one call to an existing
    callee), so it is a new definition mechanism with its own identity and
    linkage rules across files, while the measured local fix (§1.4: every
    conversion a probe performs, element conversions included, has `diagnose`
    false, and the non-diagnosing path decides from the types alone) removes
    every crash the four reviews before rev 5 found, measured on v6 and, for a
    pack element, on vav6g with M-VA (§0.6), and the focused re-review of rev 4
    found none in SV-1's code; it stays the break condition (amended 2026-10-20,
    review fold: RR-B1 / RR-B-1: rev 2 claimed the same of a fix that left the
    aggregate element conversions diagnosing; RR3-B1 / RR3-M1; RR4-M1: W-285 has
    a cheaper removal, mutant M22).
-   **R-L, loading sum.carbon only for a file that imports `Cpp`** (A-M4's
    suggestion; added 2026-10-20). The prelude is one import:
    core/prelude/types.carbon exports every `types/cpp/` library for every
    file, and `LookupNameInCore` resolves against what the prelude imported;
    a conditional prelude library is a toolchain feature beyond this slice,
    for a 5% trivial-file cost that R-2 bounds.
-   **R-M, admitting `const` alternatives as their unqualified types** (A-m4,
    B-m-3; added 2026-10-20). It would make two C++ classes share one sum
    type, and the value offered to C++ as one of them does not convert to the
    other, so the mapping would be one-directional for those classes (§1.3
    rule 3); it is W-277's break condition instead.

## §8 Verification and discharge

All of it container-local, expected and not of record (R9, R28); the carbonbuild
scripts are
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild/`
(`$CB` below). Amended 2026-10-20 (review fold: all findings).

1.  **Build and install** the worktree itself (a full build, not a relink;
    the X-macro diagnostics need it): `$CB/build.sh /home/user/carbon-sv &&
    $CB/install.sh /home/user/carbon-sv`; `carbon version` prints the head's
    hash. The installed `carbon link` then compiles the new prelude file into
    the runtimes (the relink's limitation of §0.0 disappears).
2.  **Autoupdate to a fixpoint** after each implementation commit:
    `$CB/autoupdate.sh /home/user/carbon-sv <the commit's goldens>` until a
    pass writes nothing; the second pass may only renumber `[[@LINE+N]]`
    offsets of files whose first pass inserted CHECK:STDERR lines (R26;
    measured on v4: fail_sum_types.carbon converged on its second pass, and the
    third wrote nothing).
3.  **Gate**: `$CB/gate.sh /home/user/carbon-sv`: predicted 1950 tests (1942 +
    the eight new goldens), all passing after F1 to F3, 0
    autoupdate-would-change marks (measured on v4, on v5 with
    sum_type_overload.carbon's fourteen splits, and on v6 with its sixteen: 1950
    of 1950 after the four refills; amended 2026-10-20, review fold: RR-B1;
    RR3-M1 / RR3-m4; at rev 5 with fail_sum_types.carbon's new splits, 1946 of
    1950 before the refills, as before: RR4-M1).
4.  **Conformance**: `XDG_CACHE_HOME=... $CB/conformance.sh /home/user/carbon-sv
    <out>`: predicted §5's totals; then `python3 fork/conformance/runner.py
    --update-readme-table` and `--self-test` (R7).
5.  **Mutants**, each relinked over the worktree's build (`$X/bin/mutant.sh`
    shows the recipe) and run against the goldens and the programs; each must
    turn something red, and the record names what:

    | Mutant | Predicted red |
    | --- | --- |
    | M1: `TryConvertCppSumType` returns `None` | every new golden's conversion splits; programs 2 to 6 COMPILE-FAIL |
    | M2: the optional arms swapped (`Some` built when `has_value()` is false) | match_std_optional_diff DIFF-MISMATCH (then a fenced `bad_optional_access`) |
    | M3: `std::get<i + 1>` in arm `i` | match_std_variant_diff DIFF-MISMATCH |
    | M4: the triviality rule dropped | fail_sum_types.carbon `fail_todo_non_trivial` |
    | M5: the qualification rule dropped | `fail_todo_qualified_alternative` |
    | M6: D-SV-8 reverted (measured equivalent: trunk's `c01`) | optional_pointer_payload.carbon `pointer`; match_std_optional_diff's pointer lines |
    | M7: D-SV-9 reverted (measured equivalent: trunk's `r03` crash) | constant_choice_scrutinee.carbon (a crash); the roundtrip program's `.None` constant |
    | M8: the `Core.Optional` view removed | core_optional_view.carbon; match_core_optional_diff COMPILE-FAIL |
    | M9: the `InventClangArg` mapping removed | the roundtrip program COMPILE-FAIL; optional.carbon `convert` and `one_step_core_optional` |
    | M10: `emplace<0>` in every arm of the reverse conversion | the roundtrip program DIFF-MISMATCH |
    | M11: `std::monostate` imported as its class | variant.carbon `monostate` (`CppSumTypeNotMapped`) |
    | M12 (rev 2): the `diagnose` test removed | sum_type_overload.carbon stops file_test, ``Built invalid semantics IR: No terminator in block`` (MEASURED on v4, `$X/runs/mut-m12.log`) |
    | M13 (rev 2): the reverse rule removed | fail_sum_types.carbon: the two `fail_reverse_` splits compile (MEASURED, `$X/runs/mut-m13.log`) |
    | M14 (rev 2): the view admitted for any payload | core_optional_view.carbon `fail_todo_generic` and `fail_todo_aggregate` |
    | M15 (rev 2): D-SV-8's name test widened back to rev 1's walk | optional_pointer_payload.carbon `fail_todo_nullptr_payload` and `fail_todo_maybe_unformed_payload`; fail_catching.carbon `fail_nullptr_return` |
    | M16 (rev 2): the template-dependence test removed | fail_sum_types.carbon `fail_todo_template_conversion` (rev 1's definition-time mismatch, measured by review A on the TP-1 composition) |
    | M17 (rev 3): `ConvertAggregateElement` no longer passes `diagnose` (trunk's line 393 restored) | sum_type_overload.carbon stops file_test, ``Built invalid semantics IR: No terminator in block`` (MEASURED on v5, `$Z/runs/mut-m17.log`, and on v6, `$W/runs/mut-m17.log`); with no sum type in the path, `scalar_tuple_mismatch_first` gets trunk's spurious ``cannot implicitly convert expression of type `bool` to `i32` `` (z01 on m17 and trunk; amended 2026-10-20, review fold: RR3-m4) |
    | M18 (rev 3, retired at rev 4): the non-diagnosing path no longer calls `CanBuildBranches` | rev 3: `file_scope` red with the file-scope TODO (MEASURED, `$Z/runs/mut-m18.log`); rev 4's code is M18, by design (RR3-M1), so M20 replaces it |
    | M19 (rev 3, on the PR 59 mirror after M-VA): the pack-element test removed | fail_sum_types.carbon `fail_todo_pack_element` stops the compiler at VA-1's ``Control flow in a pack element conversion`` CHECK (MEASURED on vav5n, `$Z/runs/mut-m19-va.log`, and with rev 4's split on vav6n, `$W/runs/mut-m19-va.log`) |
    | M20 (rev 4): the non-diagnosing path calls `CanBuildBranches` again (rev 3's rule; built from `$Z/final/src/`'s sum_type.{h,cpp}) | sum_type_overload.carbon `fail_todo_file_scope` and `fail_todo_template_overload` compile with no diagnostic, the second member silently selected (MEASURED on v6's tree, `$W/runs/mut-m20.log`; f01 and t7 print 1 2) |
    | M21 (rev 4, on the PR 59 mirror after M-VA): the walk reduced to rev 3's bare `PackElement` test (`$W/land/mut-m21-bare.diff`) | fail_sum_types.carbon `fail_todo_pack_element` stops the compiler at VA-1's CHECK, at `ForwardTuple` (MEASURED on vav6r, `$W/runs/mut-m21-va.log`) |
    | M22 (rev 5): W-285 lifted by attributing the conversion's blocks to the converted value's parse node where its location is not one (`$Y/exp/srcnode.diff`, v6s) | fail_sum_types.carbon `fail_todo_rvalue_ref_param`: `R` compiles with no diagnostic (MEASURED on v6s, `$Y/runs/mut-m22.log`; r2, r4, r5, y02, x07, x09, x13 and x20 run, and the `Core.Optional` forms r3 and x19 keep the TODO; amended 2026-10-20, review fold: RR4-M1) |

6.  **Composition mirrors** (TP-1's §0.9 shape; rewritten 2026-10-20, review
    fold: B-m-11): with kind.def changed every translation unit recompiles, so
    each mirror is a FULL build, one at a time: for each of PR 57, PR 60, PR 59
    and PR 61, `git archive <head> | tar -x -C /dev/shm/sv1-impl/mirror-<b>` (a
    scratch worktree; `MODULE.bazel` included), `patch -p1 <
    $X/final/final.diff` (§0.7: applies to every head), the golden sources of
    Appendix B added and the manifest regenerated by the build, then
    `CB_BUILD_ROOT=/dev/shm/sv1-impl/build $CB/build.sh
    /dev/shm/sv1-impl/mirror-<b>`, `$CB/install.sh`, `$CB/gate.sh`, the six
    programs, and the deletion of the mirror and its build before the next.
    Budget, from the carbonbuild README's records: about 10 to 17 minutes of
    wall time per build on 4 cores and under 1 GB per mirror with its build in
    `/dev/shm`, so about an hour in all. Predicted, from op2v4 and tpv4 (§0.6):
    PR 57's mirror fails exactly the seven goldens of F-M (§3 item 8); PR 61's
    the four function-pointer goldens; PR 60's and PR 59's the four
    function-pointer goldens and none of their own; on PR 57's mirror `o04`
    prints 5 6 -1 9 and `s05` 42 0 -1; on PR 61's, h2 and h3 give W-279's TODO
    at instantiation and h1 and x19 reach X-1 unless TP-1 has fixed it. Repeated
    at M against that day's heads. Rev 3 (amended 2026-10-20, review fold:
    RR-M1): `$Z/final/final.diff` replaces `$X/final/final.diff`; PR 59's mirror
    also applies the M-VA hunk and appends the `fail_todo_pack_element` split,
    and runs the PR 59 probes (`$Z/probes/va/`: v02, v03 and v04 give the
    pack-element TODO, v00 1 2, v01 7 -1, v05 VA-1's control-flow TODO, v06 7
    -1, v07 4 -1); predicted, from the relinked compositions of §0.6 (tpv5,
    op2v5, scv5, vav5g): the same failures as above, and on PR 59's mirror the
    four function-pointer refills only. Rev 4 (amended 2026-10-20, review fold:
    RR3-B1 / RR3-M1 / RR3-m3): `$W/final/final.diff` replaces
    `$Z/final/final.diff` and `$W/land/` replaces `$Z/land/`; PR 59's mirror
    also runs the aggregate pack probes (`$W/probes/vn/` and `vn4/`: n01 to n08
    and n13, n14, n16 to n21 give the pack-element TODO, n15 and n22 VA-1's own
    TODOs, n09 prints 7 1 -1 2 and n10 8 1); PR 61's mirror, at PR 61's head of
    the day, runs `$W/probes/tp/` (on tpv6: t4 and t7 give W-279's TODO, x19
    prints 0) and re-measures §0.7's PR 61 row, refutable_binding.cpp's hunk and
    X-1; predicted, from tpv6, op2v6, scv6 and vav6g (§0.6): the same failures
    as above. Rev 5 (amended 2026-10-20, review fold: RR4-M1 / RR4-m3): PR 61's
    head of record is 281292d8f (pushed, toolchain-identical to 74e16c4de);
    every mirror also runs `$Y/probes/rx/`, `rt/`, `cr/`, `cz/` and `w/`, which
    print on tpv6, op2v6, scv6 and vav6 what they print on v6 (§0.6), and its
    gate includes fail_sum_types.carbon's `fail_todo_rvalue_ref_param`.
7.  **Id re-scan** (before D; run 2026-10-20 for §1.16; widened 2026-10-20,
    review fold: B-m-7):

    <!-- google-doc-style-ignore -->

    ```bash
    for r in $(git for-each-ref --format='%(refname:short)' \
        refs/remotes/origin/ refs/heads/); do
      git show "$r:fork/inventory/work-items.json" 2>/dev/null \
        | grep -o '"id": *"W-[0-9]*"' | sed "s|^|$r |"
    done | grep -E 'W-(27[5-9]|28[0-9]|29[0-4])"'
    for w in $(git worktree list --porcelain | sed -n 's/^worktree //p'); do
      grep -o '"id": *"W-[0-9]*"' "$w/fork/inventory/work-items.json" \
        2>/dev/null | sed "s|^|$w |"
    done | grep -E 'W-(27[5-9]|28[0-9]|29[0-4])"'
    ```

    <!-- google-doc-style-resume -->

    Expected: no output (no id of the block filed anywhere, on a pushed or a
    local ref or in an unpushed worktree ledger). Run on 2026-10-20 over 82 refs
    and 15 worktree ledgers: no output; the highest filed id is W-274. Re-run at
    rev 3 (2026-10-20, amended 2026-10-20, review fold: RR-M1): the same; W-284
    joins the planned filings (§1.16). Re-run at rev 4 over 83 refs and 15
    worktree ledgers (amended 2026-10-20, review fold: all RR3 findings): no
    output; with the pattern widened to W-299, TP-1's W-295 on TP-1's pushed
    branch at 3d88e6a60, its local branch and the carbon-tp worktree, TP-1's own
    block (§1.16; rev 4 named the last two only, amended 2026-10-20, review
    fold: RR4-m3). Re-run at rev 5 over 83 refs and 15 worktree ledgers: no
    output; widened, TP-1's W-295 to W-297 on its pushed branch at 281292d8f,
    its local branch and the carbon-tp worktree.
8.  **clang-tidy** (rewritten 2026-10-20, review fold: B-m-4): the carbonbuild
    builds write no compile database, so after item 1, `ninja -C
    /home/user/carbon-build/carbon-sv -t compdb >
    /dev/shm/sv1-impl/compile_commands.json`, then LLVM 21.1.8's clang-tidy
    (`/home/user/llvm/bin/clang-tidy -p /dev/shm/sv1-impl
    --checks=-modernize-use-trailing-return-type <file>`, the exclusion TP-1
    needed: with it this container's clang-tidy stops every file at
    ``missing '(' after '__has_feature'``) on sum_type.cpp,
    custom_type_mapping.cpp, convert.cpp, refutable_binding.cpp,
    type_mapping.cpp, type.cpp and lower/constant.cpp; no new finding on a
    changed line. Measured on v4's sources with a database derived from the
    trunk build's (`$X/runs/tidy-compile_commands.json`, the prototype's
    include directory first; logs `$X/runs/tidy-*.log`): no finding in
    sum_type.cpp, custom_type_mapping.cpp, convert.cpp, refutable_binding.cpp,
    type.cpp or lower/constant.cpp, and type_mapping.cpp's four
    `misc-no-recursion` errors are trunk's own (the same four, one line
    earlier, on 0bdce60a5's file). If the database cannot be generated, the
    step moves to item 12's not-run list with that reason.
9.  **prek** on every changed path to a fixpoint:
    `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <paths>`, including check-toolchain-diagnostics (each
    new `CARBON_DIAGNOSTIC` used once, registered in kind.def).
10. **R31 and R27** (added 2026-10-20, review fold: B-m-5): before and after
    every markdown edit (Doc, Doc-M, R, D, and every plan revision), the
    heading counts per level, the bullet and numbered-item counts outside code
    blocks (`$X/bin/r31.py <file>`) and `git diff -U0 <file> | grep -E
    '^\+\s*#{1,6} [0-9]'` (no numbered heading introduced by a reflow), each
    difference accounted for in the commit message; and R27's spelling diff:
    sum.carbon's `StdOptional` declaration against sum_types.md:63-66's
    `Optional(T)` (identical but for the name and `CppCompat.`), and every
    code sample of Appendix C.1 against the toolchain's spelling, compiled.
11. **Design-doc samples** (added 2026-10-20, review fold: B-M-4): after M and
    after Doc-M, `python3 -I fork/designdocs/check_samples.py` and the same
    with `--toolchain /home/user/carbon-build/carbon-sv/install/bin/carbon`
    (PR 58's checker, whose W2 rule covers docs/design/), expecting 0 errors
    with the toolchain.
12. **Not run here, and why**: the hosted gate and conformance (R28: the
    owner's runner is not used; Actions are disabled); Bazel-only tests
    (diagnostics/coverage_test.cpp, which checks that every diagnostic kind
    appears in some golden, is covered by construction, §1.12); clang-tidy if
    item 8's database cannot be generated; LLVM-assertion builds (the
    container's LLVM is Release); macOS and Windows (another libc++ ABI or the
    MSVC STL); libstdc++ (not shipped with the toolchain); opt-mode
    conformance.

## Hand-off notes for the implementer

Rewritten 2026-10-20 (review fold: all findings).

-   Start from `$W/final/final.diff` (the measured rev-4 prototype v6, with
    kind.def at its final position and BUILD) and `$W/final/src/` (the formatted
    files); copy, do not retype (amended 2026-10-20, review fold: all RR3
    findings). Rev 5 changes no toolchain file; its goldens are `$Y/final/`
    (amended 2026-10-20, review fold: RR4-M1). Rev 3's `$Z/final/` is
    superseded: its probe skips an `overload fn` member at file scope and at a
    template's instantiation, silently calling a later one. Rev 2's `$X/final/`
    is superseded: it crashes in an `overload fn` set whose member takes a
    tuple, struct or array holding a sum type. Rev 1's `$P/proto/v3.diff` and
    `$P/final/` are superseded too: they crash in `overload fn` sets and on C++
    converting constructors.
-   The land-time hunk M-VA (`$W/land/m-va-pack-element.diff`) and its split
    (`$W/land/fail_todo_pack_element.split`, filled in
    `$Y/final/goldens-filled-M/` over rev 5's file) go in after M, once PR 59
    has landed, with C.1's pack-element line (amended 2026-10-20, review fold:
    RR4-m2); `$W/bin/comp.sh` and `$Y/bin/` show how they were measured on the
    PR 59 composition. Rev 3's `$Z/land/` hunk is superseded: it misses a pack
    of aggregates (amended 2026-10-20, review fold: RR3-B1).
-   The diagnostics are final: v4, v5 and v6 emitted them with the kinds
    appended to kind.def (§0.0); the full build places them as §2.10 shows. The
    goldens' first fill reproduces `$Y/final/goldens-filled/` exactly.
-   Link prototypes with trunk's `carbon link` (§0.0); the full build of §8.1
    removes the need.
-   The goldens mock `std::optional`/`std::variant` (Appendix B,
    `$Y/final/goldens-src/`); the programs use real libc++ (Appendix A,
    `$X/final/progs/`). Keep both.
-   The arbiter's body loses its `default` arm; its header says why
    (R16(b)), and no other existing program is edited.
-   Records and docs texts are Appendix C, verbatim, after M; only the `<...>`
    placeholders are filled (§1.14). W-177 is narrowed, not discharged.
-   Probe programs that pin every measured number of this plan are in
    `$P/probes/` (rev 1: m*, n*, a*, t*, x*: trunk; v1/, w/, o/: the prototype),
    `$X/probes/` (rev 2: rA/ and rB/, the two reviews' probes; x/, the fixer's),
    `$Z/probes/` (rev 3: rr/ and va/, the focused re-review's; y/, the fixer's),
    `$W/probes/` (rev 4: copies of the focused re-review of rev 3's f/, h/, tp/,
    vn/, vn2/ and the rest; vn4/ and z/, the fixer's) and `$Y/probes/` (rev 5:
    copies of the focused re-review of rev 4's cr/, cz/ and w/; rx/ and rt/, the
    fixer's; amended 2026-10-20, review fold: all RR4 findings);
    `$X/bin/probe.sh <variant> <file>` or `$Y/bin/runall.sh <variant> <dir>`
    re-runs them.
-   X-1 (TP-1's pattern_match.cpp:1409 on a template-dependent choice `match`)
    is TP-1's, fixed on its round-10 head; check x19 on the merged trunk before
    D (§1.16).
-   A limit on where the conversion can be built (file scope, a template's
    instantiation, a pack element) is the committed conversion's TODO, never a
    reason for an `overload fn` probe to skip a member (§1.4, RR3-M1); keep
    `CanBuildBranches` out of the non-diagnosing path.
-   clang-tidy: §8 item 8's database recipe works on the carbonbuild build
    (measured on v4); keep the `modernize-use-trailing-return-type` exclusion.
-   Two shapes stay out of the passing splits and the programs (added
    2026-10-20, review fold: RR4-M1 / RR4-m1): a fresh sum value passed to a C++
    `T&&` parameter, W-285's TODO, pinned by `fail_todo_rvalue_ref_param` only
    (pass a value, which selects a `const T&` overload); and a constant tuple or
    struct holding a sum-type constant, which stops lowering until W-263 is
    fixed (§1.11).

## Appendix A: conformance programs

Byte copies of `$X/final/progs/`, each run on v4 against its oracle (§1.13,
`$X/runs/progs-v4b.txt`); paths relative to fork/conformance/programs/.
Amended 2026-10-20 (review fold: A-M2 / B-M-1 / B-M-5 / A-m7): the listings
of match_std_optional_diff.carbon, match_core_optional_diff.carbon and its
oracle, and cpp_sum_type_roundtrip_diff.carbon and its oracle changed; the
other seven are rev 1's, byte for byte.

### A: control_flow/match_sum_type_payload.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//
// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020) un-SKIPs this
// program with its intended body: `Cpp.MaybeSeven()` returns a C++
// `std::optional<int>`, which `match` consumes as its Carbon sum type
// `Core.CppCompat.StdOptional(i32)` through the `.Some`/`.None` alternative
// patterns of docs/design/sum_types.md, so sum-type consumption spans the
// interop boundary (first-match-wins per docs/design/pattern_matching.md).
// One edit to the sketch, design-directed and not a weakening (R16(b)): the
// sketch's trailing `default` arm is removed, because the two alternative
// arms cover the closed set and a `default` after them is the dead-default
// error of W-078a (`default` arm never matches); the match is exhaustive
// without it (SF-7). The Carbon-choice half of this program's original sketch
// moved to choice_payload_roundtrip_diff.carbon at S2c.

import Core library "io";
import Cpp inline '''c++
#include <optional>
inline std::optional<int> MaybeSeven() { return 7; }
''';

fn Run() -> i32 {
  match (Cpp.MaybeSeven()) {
    case .Some(n: i32) => { Core.Print(n); }
    case .None => { return 1; }
  }
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: control_flow/match_std_optional_diff.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020): a C++
// `std::optional<T>` stays an imported C++ class, and is matched as the
// Carbon sum type it maps to by value, `Core.CppCompat.StdOptional(T)` --
// the docs/design/sum_types.md `Optional(T)` declaration, alternatives
// `.Some(value: T)` and `.None`. The conversion reads the C++ object through
// its accessors (`has_value()`, `value()`); it never reinterprets libc++'s
// bytes. Every payload is computed at run time from a seed the C++ side
// cannot see in advance (R16d). Covered: an exhaustive match without
// `default` on a call result (SF-7); `if (let .Some(...) = ...)`; a pointer
// payload, `std::optional<int*>`, whose engaged null pointer is distinct
// from `None` (the payload is the nullable `Core.Optional(i32*)`, D-SV-8); a
// 64-bit payload; a generic Carbon function over the mapped type; and the
// implicit one-step conversion of a C++ `std::optional<int>` to
// `Core.Optional(i32)`.
// Differential pair: match_std_optional_diff.diff.cpp computes the same
// values with `std::optional` and prints the same lines (DIFF-1).

import Core library "io";
import Cpp inline '''c++
#include <cstdint>
#include <optional>

inline int target = 0;

inline auto MaybeTwice(int n) -> std::optional<int> {
  if (n > 0) {
    return n * 2;
  }
  return std::nullopt;
}

inline auto MaybeAddress(int n) -> std::optional<int*> {
  target = n * 3;
  if (n > 0) {
    return &target;
  }
  if (n == 0) {
    return nullptr;
  }
  return std::nullopt;
}

inline auto MaybeWide(int n) -> std::optional<std::int64_t> {
  if (n > 0) {
    return static_cast<std::int64_t>(n) * 1000000000;
  }
  return std::nullopt;
}
''';

fn Seed(x: i32) -> i32 { return x + 4; }

fn Unwrap[T: Core.Copy & Core.Destroy](o: Core.CppCompat.StdOptional(T),
                                       fallback: T) -> T {
  var result: T = fallback;
  match (o) {
    case .Some(value: T) => {
      result = value;
    }
    case .None => {}
  }
  return result;
}

fn Show(n: i32) {
  match (Cpp.MaybeTwice(n)) {
    case .Some(value: i32) => {
      Core.Print(value);
    }
    case .None => {
      Core.Print(-1);
    }
  }
}

fn ShowPointer(n: i32) {
  match (Cpp.MaybeAddress(n)) {
    case .Some(p: Core.Optional(i32*)) => {
      if (p.HasValue()) {
        Core.Print(*p.Get());
      } else {
        Core.Print(0);
      }
    }
    case .None => {
      Core.Print(-1);
    }
  }
}

fn ShowWide(n: i32) {
  match (Cpp.MaybeWide(n)) {
    case .Some(value: i64) => {
      Core.Print((value / 1000000000) as i32);
    }
    case .None => {
      Core.Print(-1);
    }
  }
}

fn Run() -> i32 {
  Show(Seed(3));
  Show(Seed(-7));
  if (let .Some(value: i32) = Cpp.MaybeTwice(Seed(1))) {
    Core.Print(value);
  }
  ShowPointer(Seed(1));
  ShowPointer(Seed(-4));
  ShowPointer(Seed(-9));
  ShowWide(Seed(5));
  ShowWide(Seed(-5));
  let some: Core.CppCompat.StdOptional(i32) = Cpp.MaybeTwice(Seed(17));
  let none: Core.CppCompat.StdOptional(i32) = Cpp.MaybeTwice(Seed(-17));
  let fallback: i32 = Seed(-11);
  Core.Print(Unwrap(some, fallback));
  Core.Print(Unwrap(none, fallback));
  let carbon_optional: Core.Optional(i32) = Cpp.MaybeTwice(Seed(17));
  if (carbon_optional.HasValue()) {
    Core.Print(carbon_optional.Get());
  }
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: control_flow/match_std_optional_diff.diff.cpp

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of match_std_optional_diff.carbon: the same
// C++ functions, inspected with `has_value()` and `*` where the Carbon side
// matches `.Some` and `.None`, in the same order, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdint>
#include <cstdio>
#include <optional>

static int target = 0;

static auto MaybeTwice(int n) -> std::optional<int> {
  if (n > 0) {
    return n * 2;
  }
  return std::nullopt;
}

static auto MaybeAddress(int n) -> std::optional<int*> {
  target = n * 3;
  if (n > 0) {
    return &target;
  }
  if (n == 0) {
    return nullptr;
  }
  return std::nullopt;
}

static auto MaybeWide(int n) -> std::optional<std::int64_t> {
  if (n > 0) {
    return static_cast<std::int64_t>(n) * 1000000000;
  }
  return std::nullopt;
}

static auto Seed(int x) -> int { return x + 4; }

template <typename T>
static auto Unwrap(std::optional<T> o, T fallback) -> T {
  return o.has_value() ? *o : fallback;
}

static auto Show(int n) -> void {
  auto o = MaybeTwice(n);
  std::printf("%d\n", o.has_value() ? *o : -1);
}

static auto ShowPointer(int n) -> void {
  auto o = MaybeAddress(n);
  if (!o.has_value()) {
    std::printf("%d\n", -1);
  } else if (*o == nullptr) {
    std::printf("%d\n", 0);
  } else {
    std::printf("%d\n", **o);
  }
}

static auto ShowWide(int n) -> void {
  auto o = MaybeWide(n);
  std::printf("%d\n", o.has_value() ? static_cast<int>(*o / 1000000000) : -1);
}

auto main() -> int {
  Show(Seed(3));
  Show(Seed(-7));
  if (auto o = MaybeTwice(Seed(1)); o.has_value()) {
    std::printf("%d\n", *o);
  }
  ShowPointer(Seed(1));
  ShowPointer(Seed(-4));
  ShowPointer(Seed(-9));
  ShowWide(Seed(5));
  ShowWide(Seed(-5));
  auto some = MaybeTwice(Seed(17));
  auto none = MaybeTwice(Seed(-17));
  int fallback = Seed(-11);
  std::printf("%d\n", Unwrap(some, fallback));
  std::printf("%d\n", Unwrap(none, fallback));
  if (some.has_value()) {
    std::printf("%d\n", *some);
  }
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: control_flow/match_std_variant_diff.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020): a C++
// `std::variant<T0, ..., Tn>` stays an imported C++ class, and is matched as
// the Carbon sum type it maps to by value, `Core.CppCompat.StdVariant<N>`,
// whose alternatives are named by C++ index: `.Alt0` holds the value when
// `index() == 0`. The conversion reads `index()` and then `std::get<I>`; it
// never reinterprets libc++'s bytes. Covered, every payload computed at run
// time (R16d): `std::variant<int, double>`; a `std::monostate` alternative,
// whose payload is `()`; duplicate alternative types,
// `std::variant<int, int>`, told apart by index; four alternatives of
// `bool`, `long`, `double` and `int*`; and a nested shape, a variant holding
// a pointer to a `std::optional<int>`, matched again through the pointer.
// Each match is exhaustive and has no `default` (SF-7). Differential pair:
// match_std_variant_diff.diff.cpp (DIFF-1).

import Core library "io";
import Cpp inline '''c++
#include <optional>
#include <variant>

inline auto IntOrHalf(int n) -> std::variant<int, double> {
  if (n > 0) {
    return n * 3;
  }
  return n * 0.5;
}

inline auto Tenths(double d) -> int { return static_cast<int>(d * 10); }

inline auto MaybeEmpty(int n) -> std::variant<std::monostate, int> {
  if (n > 0) {
    return n + 100;
  }
  return std::monostate();
}

inline auto LeftOrRight(int n) -> std::variant<int, int> {
  if (n > 0) {
    return std::variant<int, int>(std::in_place_index<1>, n);
  }
  return std::variant<int, int>(std::in_place_index<0>, -n);
}

inline int cell = 0;

inline auto Mixed(int n) -> std::variant<bool, long, double, int*> {
  switch (n % 4) {
    case 0:
      return n > 4;
    case 1:
      return static_cast<long>(n) * 7;
    case 2:
      return n * 0.25;
    default:
      cell = n;
      return &cell;
  }
}

inline std::optional<int> inner;

inline auto Nested(int n) -> std::variant<std::optional<int>*, int> {
  if (n > 0) {
    inner = n * 11;
    return &inner;
  }
  if (n == 0) {
    inner = std::nullopt;
    return &inner;
  }
  return n;
}
''';

fn Seed(x: i32) -> i32 { return x + 2; }

fn ShowIntOrHalf(n: i32) {
  match (Cpp.IntOrHalf(n)) {
    case .Alt0(i: i32) => {
      Core.Print(i);
    }
    case .Alt1(d: f64) => {
      Core.Print(Cpp.Tenths(d));
    }
  }
}

fn ShowMaybeEmpty(n: i32) {
  match (Cpp.MaybeEmpty(n)) {
    case .Alt0(unused empty: ()) => {
      Core.Print(0);
    }
    case .Alt1(i: i32) => {
      Core.Print(i);
    }
  }
}

fn ShowLeftOrRight(n: i32) {
  match (Cpp.LeftOrRight(n)) {
    case .Alt0(left: i32) => {
      Core.Print(1000 + left);
    }
    case .Alt1(right: i32) => {
      Core.Print(2000 + right);
    }
  }
}

fn ShowMixed(n: i32) {
  match (Cpp.Mixed(n)) {
    case .Alt0(b: bool) => {
      if (b) {
        Core.Print(1);
      } else {
        Core.Print(0);
      }
    }
    case .Alt1(l: i64) => {
      Core.Print(l as i32);
    }
    case .Alt2(d: f64) => {
      Core.Print(Cpp.Tenths(d));
    }
    case .Alt3(p: Core.Optional(i32*)) => {
      Core.Print(*p.Get());
    }
  }
}

fn ShowNested(n: i32) {
  match (Cpp.Nested(n)) {
    case .Alt0(p: Core.Optional(Cpp.std.optional(i32)*)) => {
      match (*p.Get()) {
        case .Some(v: i32) => {
          Core.Print(v);
        }
        case .None => {
          Core.Print(-1);
        }
      }
    }
    case .Alt1(i: i32) => {
      Core.Print(i);
    }
  }
}

fn Run() -> i32 {
  ShowIntOrHalf(Seed(2));
  ShowIntOrHalf(Seed(-5));
  ShowMaybeEmpty(Seed(1));
  ShowMaybeEmpty(Seed(-3));
  ShowLeftOrRight(Seed(5));
  ShowLeftOrRight(Seed(-9));
  ShowMixed(Seed(6));
  ShowMixed(Seed(7));
  ShowMixed(Seed(8));
  ShowMixed(Seed(9));
  ShowMixed(Seed(10));
  ShowNested(Seed(1));
  ShowNested(Seed(-2));
  ShowNested(Seed(-6));
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: control_flow/match_std_variant_diff.diff.cpp

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of match_std_variant_diff.carbon: the same
// C++ functions, inspected by `index()` and `std::get<I>` where the Carbon
// side matches `.Alt<I>`, in the same order, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdio>
#include <optional>
#include <variant>

static auto IntOrHalf(int n) -> std::variant<int, double> {
  if (n > 0) {
    return n * 3;
  }
  return n * 0.5;
}

static auto Tenths(double d) -> int { return static_cast<int>(d * 10); }

static auto MaybeEmpty(int n) -> std::variant<std::monostate, int> {
  if (n > 0) {
    return n + 100;
  }
  return std::monostate();
}

static auto LeftOrRight(int n) -> std::variant<int, int> {
  if (n > 0) {
    return std::variant<int, int>(std::in_place_index<1>, n);
  }
  return std::variant<int, int>(std::in_place_index<0>, -n);
}

static int cell = 0;

static auto Mixed(int n) -> std::variant<bool, long, double, int*> {
  switch (n % 4) {
    case 0:
      return n > 4;
    case 1:
      return static_cast<long>(n) * 7;
    case 2:
      return n * 0.25;
    default:
      cell = n;
      return &cell;
  }
}

static std::optional<int> inner;

static auto Nested(int n) -> std::variant<std::optional<int>*, int> {
  if (n > 0) {
    inner = n * 11;
    return &inner;
  }
  if (n == 0) {
    inner = std::nullopt;
    return &inner;
  }
  return n;
}

static auto Seed(int x) -> int { return x + 2; }

static auto Print(int n) -> void { std::printf("%d\n", n); }

auto main() -> int {
  for (int n : {Seed(2), Seed(-5)}) {
    auto v = IntOrHalf(n);
    Print(v.index() == 0 ? std::get<0>(v) : Tenths(std::get<1>(v)));
  }
  for (int n : {Seed(1), Seed(-3)}) {
    auto v = MaybeEmpty(n);
    Print(v.index() == 0 ? 0 : std::get<1>(v));
  }
  for (int n : {Seed(5), Seed(-9)}) {
    auto v = LeftOrRight(n);
    Print(v.index() == 0 ? 1000 + std::get<0>(v) : 2000 + std::get<1>(v));
  }
  for (int n : {Seed(6), Seed(7), Seed(8), Seed(9), Seed(10)}) {
    auto v = Mixed(n);
    switch (v.index()) {
      case 0:
        Print(std::get<0>(v) ? 1 : 0);
        break;
      case 1:
        Print(static_cast<int>(std::get<1>(v)));
        break;
      case 2:
        Print(Tenths(std::get<2>(v)));
        break;
      default:
        Print(*std::get<3>(v));
        break;
    }
  }
  for (int n : {Seed(1), Seed(-2), Seed(-6)}) {
    auto v = Nested(n);
    if (v.index() == 0) {
      const std::optional<int>& o = *std::get<0>(v);
      Print(o.has_value() ? *o : -1);
    } else {
      Print(std::get<1>(v));
    }
  }
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: control_flow/match_core_optional_diff.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md D-SV-7, W-177): a `Core.Optional(T)`
// scrutinee is matched as its view `Core.CppCompat.StdOptional(T)`, the
// docs/design/sum_types.md `Optional(T)` choice, converted by value through
// `HasValue()` and `Get()`; the class itself is unchanged. Covered, every
// payload computed at run time (R16d): `Core.Optional(i32)` in both states,
// exhaustively and without `default`; `Core.Optional(i32*)`, whose `None` is
// the null pointer, so `.Some` binds a non-null `i32*`; `if`-`let`; and a
// second payload type, `Core.Optional(i64)`. A symbolic payload type is not
// matched in 0.1 (W-177, narrowed). Differential pair:
// match_core_optional_diff.diff.cpp, the same values in `std::optional`
// (DIFF-1).

import Core library "io";

fn Seed(x: i32) -> i32 { return x * 3 - 4; }

fn MaybePositive(n: i32) -> Core.Optional(i32) {
  if (n > 0) {
    return Core.Optional(i32).Some(n);
  }
  return Core.Optional(i32).None();
}

fn Show(o: Core.Optional(i32)) {
  match (o) {
    case .Some(value: i32) => {
      Core.Print(value);
    }
    case .None => {
      Core.Print(-1);
    }
  }
}

fn ShowPointer(p: Core.Optional(i32*)) {
  match (p) {
    case .Some(q: i32*) => {
      Core.Print(*q);
    }
    case .None => {
      Core.Print(0);
    }
  }
}

fn MaybeWide(n: i32) -> Core.Optional(i64) {
  if (n > 0) {
    return Core.Optional(i64).Some(n);
  }
  return Core.Optional(i64).None();
}

fn CountSome(o: Core.Optional(i64)) -> i32 {
  match (o) {
    case .Some(unused value: i64) => {
      return 1;
    }
    case .None => {
      return 0;
    }
  }
  return -1;
}

fn Run() -> i32 {
  Show(MaybePositive(Seed(5)));
  Show(MaybePositive(Seed(1)));
  var cell: i32 = Seed(7);
  ShowPointer(Core.Optional(i32*).Some(&cell));
  ShowPointer(Core.Optional(i32*).None());
  if (let .Some(value: i32) = MaybePositive(Seed(4))) {
    Core.Print(value + 100);
  }
  Core.Print(CountSome(MaybeWide(Seed(2))));
  Core.Print(CountSome(MaybeWide(Seed(-2))));
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: control_flow/match_core_optional_diff.diff.cpp

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of match_core_optional_diff.carbon: the same
// values held in `std::optional<int>` and a nullable `int*`, inspected with
// `has_value()` and `*` (null for the pointer's `None`) where the Carbon side
// matches `.Some` and `.None`, in the same order, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdio>
#include <optional>

static auto Seed(int x) -> int { return x * 3 - 4; }

static auto MaybePositive(int n) -> std::optional<int> {
  if (n > 0) {
    return n;
  }
  return std::nullopt;
}

static auto Show(std::optional<int> o) -> void {
  std::printf("%d\n", o.has_value() ? *o : -1);
}

static auto ShowPointer(int* p) -> void {
  std::printf("%d\n", p != nullptr ? *p : 0);
}

static auto MaybeWide(int n) -> std::optional<long long> {
  if (n > 0) {
    return n;
  }
  return std::nullopt;
}

static auto CountSome(std::optional<long long> o) -> int {
  return o.has_value() ? 1 : 0;
}

auto main() -> int {
  Show(MaybePositive(Seed(5)));
  Show(MaybePositive(Seed(1)));
  int cell = Seed(7);
  ShowPointer(&cell);
  ShowPointer(nullptr);
  if (auto o = MaybePositive(Seed(4)); o.has_value()) {
    std::printf("%d\n", *o + 100);
  }
  std::printf("%d\n", CountSome(MaybeWide(Seed(2))));
  std::printf("%d\n", CountSome(MaybeWide(Seed(-2))));
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: interop/cpp_sum_type_roundtrip_diff.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020), the Carbon-to-C++
// direction: a value of `Core.CppCompat.StdOptional(T)` or `StdVariant<N>`
// passed where C++ takes `std::optional<T>` or `std::variant<Ts...>` -- by
// value or by `const&` -- converts by value, through the C++ class's
// constructor and `emplace`; a constant alternative (`.None`) converts as a
// computed one does. A Carbon function exported to C++ names the C++ class in
// its signature (the Carbon sum types themselves are not exported, W-049
// and the plan's residue list): it returns a `std::optional<int>` built from
// the Carbon sum type on each of two paths, and it takes a `std::variant`
// and matches it. A `Core.Optional(i32)` argument reaches the same
// parameters in one implicit step (D-SV-7). Every payload is computed at run
// time from a seed (R16d).
// Differential pair: cpp_sum_type_roundtrip_diff.diff.cpp (DIFF-1).

import Core library "io";
import Cpp inline '''c++
#include <optional>
#include <variant>

inline auto TakeOptional(std::optional<int> o) -> int {
  return o.has_value() ? *o + 1 : -1;
}

inline auto TakeOptionalRef(const std::optional<int>& o) -> int {
  return o.has_value() ? *o + 2 : -2;
}

inline auto TakeVariant(std::variant<int, double> v) -> int {
  return v.index() == 0 ? std::get<0>(v) : static_cast<int>(std::get<1>(v) * 10);
}

inline auto TakePair(const std::variant<int, int>& v) -> int {
  return static_cast<int>(v.index()) * 100 +
         (v.index() == 0 ? std::get<0>(v) : std::get<1>(v));
}

inline auto TakeEmpty(std::variant<std::monostate, int> v) -> int {
  return v.index() == 0 ? -7 : std::get<1>(v);
}
''';

fn Seed(x: i32) -> i32 { return x + 5; }

fn SeedF(x: f64) -> f64 { return x + x; }

fn MakeOptional(n: i32) -> Cpp.std.optional(i32) {
  if (n > 0) {
    return Core.CppCompat.StdOptional(i32).Some(n * 4);
  }
  return Core.CppCompat.StdOptional(i32).None;
}

fn InspectVariant(v: Cpp.std.variant(i32, f64)) -> i32 {
  match (v) {
    case .Alt0(i: i32) => {
      return i + 1;
    }
    case .Alt1(d: f64) => {
      return Cpp.TakeVariant(Core.CppCompat.StdVariant2(i32, f64).Alt1(d)) + 2;
    }
  }
  return -100;
}

inline Cpp '''
inline auto UseMakeOptional(int n) -> int {
  std::optional<int> o = Carbon::MakeOptional(n);
  return o.has_value() ? *o : -3;
}

inline auto UseInspectVariant(int n) -> int {
  if (n > 0) {
    return Carbon::InspectVariant(std::variant<int, double>(n));
  }
  return Carbon::InspectVariant(std::variant<int, double>(n * 1.5));
}
''';

fn Run() -> i32 {
  let some: Core.CppCompat.StdOptional(i32) =
      Core.CppCompat.StdOptional(i32).Some(Seed(30));
  let none: Core.CppCompat.StdOptional(i32) =
      Core.CppCompat.StdOptional(i32).None;
  Core.Print(Cpp.TakeOptional(some));
  Core.Print(Cpp.TakeOptionalRef(some));
  Core.Print(Cpp.TakeOptional(none));
  Core.Print(Cpp.TakeOptional(Core.CppCompat.StdOptional(i32).None));
  Core.Print(Cpp.TakeOptional(Core.Optional(i32).Some(Seed(40))));
  Core.Print(Cpp.TakeOptionalRef(Core.Optional(i32).None()));
  let half: f64 = SeedF(1.25);
  Core.Print(Cpp.TakeVariant(Core.CppCompat.StdVariant2(i32, f64).Alt1(half)));
  Core.Print(Cpp.TakeVariant(Core.CppCompat.StdVariant2(i32, f64).Alt0(Seed(4))));
  Core.Print(Cpp.TakePair(Core.CppCompat.StdVariant2(i32, i32).Alt1(Seed(2))));
  Core.Print(Cpp.TakePair(Core.CppCompat.StdVariant2(i32, i32).Alt0(Seed(3))));
  Core.Print(Cpp.TakeEmpty(Core.CppCompat.StdVariant2((), i32).Alt0(())));
  Core.Print(Cpp.TakeEmpty(Core.CppCompat.StdVariant2((), i32).Alt1(Seed(6))));
  Core.Print(Cpp.UseMakeOptional(Seed(1)));
  Core.Print(Cpp.UseMakeOptional(Seed(-8)));
  Core.Print(Cpp.UseInspectVariant(Seed(2)));
  Core.Print(Cpp.UseInspectVariant(Seed(-7)));
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: interop/cpp_sum_type_roundtrip_diff.diff.cpp

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_sum_type_roundtrip_diff.carbon: the
// Carbon sum type values are the `std::optional` and `std::variant` values
// they convert to, built with the same runtime seeds, and the two Carbon
// functions the C++ side calls are written here in C++, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdio>
#include <optional>
#include <variant>

static auto TakeOptional(std::optional<int> o) -> int {
  return o.has_value() ? *o + 1 : -1;
}

static auto TakeOptionalRef(const std::optional<int>& o) -> int {
  return o.has_value() ? *o + 2 : -2;
}

static auto TakeVariant(std::variant<int, double> v) -> int {
  return v.index() == 0 ? std::get<0>(v)
                        : static_cast<int>(std::get<1>(v) * 10);
}

static auto TakePair(const std::variant<int, int>& v) -> int {
  return static_cast<int>(v.index()) * 100 +
         (v.index() == 0 ? std::get<0>(v) : std::get<1>(v));
}

static auto TakeEmpty(std::variant<std::monostate, int> v) -> int {
  return v.index() == 0 ? -7 : std::get<1>(v);
}

static auto Seed(int x) -> int { return x + 5; }

static auto SeedF(double x) -> double { return x + x; }

static auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) {
    return n * 4;
  }
  return std::nullopt;
}

static auto InspectVariant(std::variant<int, double> v) -> int {
  if (v.index() == 0) {
    return std::get<0>(v) + 1;
  }
  return TakeVariant(std::variant<int, double>(std::get<1>(v))) + 2;
}

static auto UseMakeOptional(int n) -> int {
  std::optional<int> o = MakeOptional(n);
  return o.has_value() ? *o : -3;
}

static auto UseInspectVariant(int n) -> int {
  if (n > 0) {
    return InspectVariant(std::variant<int, double>(n));
  }
  return InspectVariant(std::variant<int, double>(n * 1.5));
}

static auto Print(int n) -> void { std::printf("%d\n", n); }

auto main() -> int {
  std::optional<int> some = Seed(30);
  std::optional<int> none = std::nullopt;
  Print(TakeOptional(some));
  Print(TakeOptionalRef(some));
  Print(TakeOptional(none));
  Print(TakeOptional(std::nullopt));
  Print(TakeOptional(std::optional<int>(Seed(40))));
  Print(TakeOptionalRef(std::nullopt));
  double half = SeedF(1.25);
  Print(TakeVariant(std::variant<int, double>(std::in_place_index<1>, half)));
  Print(TakeVariant(std::variant<int, double>(std::in_place_index<0>, Seed(4))));
  Print(TakePair(std::variant<int, int>(std::in_place_index<1>, Seed(2))));
  Print(TakePair(std::variant<int, int>(std::in_place_index<0>, Seed(3))));
  Print(TakeEmpty(std::variant<std::monostate, int>(std::monostate())));
  Print(TakeEmpty(std::variant<std::monostate, int>(Seed(6))));
  Print(UseMakeOptional(Seed(1)));
  Print(UseMakeOptional(Seed(-8)));
  Print(UseInspectVariant(Seed(2)));
  Print(UseInspectVariant(Seed(-7)));
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: control_flow/cpp_sum_type_library/source.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// The library unit of cpp_sum_type_library: it imports the C++ and converts
// at its own API, so its importer sees only the Carbon sum type.

library "source";

import Cpp inline '''c++
#include <optional>
#include <variant>

inline auto MaybeSquare(int n) -> std::optional<int> {
  if (n > 0) {
    return n * n;
  }
  return std::nullopt;
}

inline auto CountOrFlag(int n) -> std::variant<int, bool> {
  if (n > 0) {
    return n + 1;
  }
  return n == 0;
}
''';

fn Fetch(n: i32) -> Core.CppCompat.StdOptional(i32) {
  return Cpp.MaybeSquare(n);
}

fn Classify(n: i32) -> Core.CppCompat.StdVariant2(i32, bool) {
  return Cpp.CountOrFlag(n);
}
```

<!-- google-doc-style-resume -->

### A: control_flow/cpp_sum_type_library/main.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Control flow: matching — sum-type consumption incl. std::variant/std::optional interop
// EXPECT-EXIT: 0

// SV-1 (fork/sumtype-interop/plan.md, fork decision F-020), through a Carbon
// library: source.carbon converts the C++ `std::optional<int>` and
// `std::variant<int, bool>` it imports to `Core.CppCompat.StdOptional(i32)`
// and `StdVariant2(i32, bool)` at its API, and this unit, which imports no
// C++ (an imported C++ class does not cross a Carbon library, W-047), matches
// the Carbon sum types, exhaustively and without `default`. Payloads are
// computed at run time (R16d). Differential pair: main.diff.cpp (DIFF-1).

import library "source";
import Core library "io";

fn Seed(x: i32) -> i32 { return x - 3; }

fn Run() -> i32 {
  match (Fetch(Seed(9))) {
    case .Some(value: i32) => {
      Core.Print(value);
    }
    case .None => {
      Core.Print(-1);
    }
  }
  match (Fetch(Seed(1))) {
    case .Some(value: i32) => {
      Core.Print(value);
    }
    case .None => {
      Core.Print(-1);
    }
  }
  match (Classify(Seed(10))) {
    case .Alt0(count: i32) => {
      Core.Print(count);
    }
    case .Alt1(flag: bool) => {
      if (flag) {
        Core.Print(1);
      } else {
        Core.Print(0);
      }
    }
  }
  match (Classify(Seed(3))) {
    case .Alt0(count: i32) => {
      Core.Print(count);
    }
    case .Alt1(flag: bool) => {
      if (flag) {
        Core.Print(-2);
      } else {
        Core.Print(-3);
      }
    }
  }
  return 0;
}
```

<!-- google-doc-style-resume -->

### A: control_flow/cpp_sum_type_library/main.diff.cpp

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of cpp_sum_type_library: the library's C++
// functions, inspected where the Carbon units match, printing with
// `printf("%d\n", ...)` as `Core.Print` lowers.

#include <cstdio>
#include <optional>
#include <variant>

static auto MaybeSquare(int n) -> std::optional<int> {
  if (n > 0) {
    return n * n;
  }
  return std::nullopt;
}

static auto CountOrFlag(int n) -> std::variant<int, bool> {
  if (n > 0) {
    return n + 1;
  }
  return n == 0;
}

static auto Seed(int x) -> int { return x - 3; }

static auto Print(int n) -> void { std::printf("%d\n", n); }

auto main() -> int {
  for (int n : {Seed(9), Seed(1)}) {
    auto o = MaybeSquare(n);
    Print(o.has_value() ? *o : -1);
  }
  auto first = CountOrFlag(Seed(10));
  Print(first.index() == 0 ? std::get<0>(first) : (std::get<1>(first) ? 1 : 0));
  auto second = CountOrFlag(Seed(3));
  Print(second.index() == 0 ? std::get<0>(second)
                            : (std::get<1>(second) ? -2 : -3));
  return 0;
}
```

<!-- google-doc-style-resume -->

## Appendix B: golden sources

The AUTOUPDATE sources of §1.12 without their CHECK lines
(`$X/final/goldens-src/`; `$X/final/goldens-filled/` holds them filled by v4).
Paths relative to toolchain/. Rewritten 2026-10-20 (review fold: all findings):
every listing is v4's; stdlib/sum_type_overload.carbon is new, and
fail_catching.carbon's appended split is listed as its diff hunk. At rev 3
(amended 2026-10-20, review fold: all RR findings) the sources are
`$Z/final/goldens-src/`, filled by v5 in `$Z/final/goldens-filled/`:
sum_type_overload.carbon gains eight splits, and fail_sum_types.carbon gains a
split at M-VA, listed after it. At rev 4 (amended 2026-10-20, review fold:
RR3-B1 / RR3-M1 / RR3-m4) they are `$W/final/goldens-src/`, filled by v6 in
`$W/final/goldens-filled/` (and the M-VA split by vav6g in
`$W/final/goldens-filled-M/`): sum_type_overload.carbon renames one split and
gains two, and the M-VA split gains eight calls.

### B: check/testdata/interop/cpp/stdlib/optional.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/optional.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/optional.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1, F-020): a `std::optional<T>`
// specialization stays an imported C++ class; where a Carbon sum type is
// expected -- a `match`, `if`-`let` or `let`-`else` scrutinee, or a
// conversion to `Core.CppCompat.StdOptional(T)` -- it converts by value
// through `has_value()` and `value()`, and a `StdOptional(T)` converts back
// through the class's default constructor and `emplace`.

// --- sum.h

// Mocks of libc++'s `std::optional` and `std::variant`, as string_view.carbon
// and span.carbon mock theirs, so the goldens are hermetic: the members the
// conversions call (`has_value`, `value`, `emplace`, `index`, `std::get`),
// libc++'s inline namespace, and `size_t` pinned by `--target`.
namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template <typename T>
    class optional {
     public:
      optional() : value_(), engaged_(false) {}
      optional(T value) : value_(value), engaged_(true) {}
      bool has_value() const { return engaged_; }
      const T& value() const { return value_; }
      template <typename... A>
      T& emplace(A... args) {
        value_ = T(args...);
        engaged_ = true;
        return value_;
      }

     private:
      T value_;
      bool engaged_;
    };

    struct monostate {};

    template <typename... Ts>
    class variant {
     public:
      variant() : index_(0) { emplace<0>(); }
      size_t index() const { return index_; }
      template <size_t I, typename... A>
      __type_pack_element<I, Ts...>& emplace(A... args) {
        index_ = I;
        auto* p = reinterpret_cast<__type_pack_element<I, Ts...>*>(storage_);
        *p = __type_pack_element<I, Ts...>(args...);
        return *p;
      }
      alignas(8) unsigned char storage_[8];
      size_t index_;
    };

    template <size_t I, typename... Ts>
    const __type_pack_element<I, Ts...>& get(const variant<Ts...>& v) {
      return *reinterpret_cast<const __type_pack_element<I, Ts...>*>(
          v.storage_);
    }
  }
}

struct Point {
  int x;
  int y;
};

inline auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) return std::optional<int>(n);
  return std::optional<int>();
}

inline int cell = 0;

inline auto MakePointer(int n) -> std::optional<int*> {
  if (n > 0) return std::optional<int*>(&cell);
  return std::optional<int*>();
}

inline auto MakePoint() -> std::optional<Point> {
  return std::optional<Point>(Point{1, 2});
}

inline auto Take(std::optional<int> o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto TakeRef(const std::optional<int>& o) -> int {
  return o.has_value() ? o.value() : -2;
}

inline auto MakeMono(int n) -> std::optional<std::monostate> {
  if (n > 0) return std::optional<std::monostate>(std::monostate());
  return std::optional<std::monostate>();
}

inline auto TakeMono(std::optional<std::monostate> o) -> bool {
  return o.has_value();
}

// --- match.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Predicted: the scrutinee converts once, before the arms: a call of
// `has_value`'s thunk, a branch, `value`'s thunk call and
// `StdOptional(i32).Some` in one block, the `None` constant's copy in the
// other, each assigned to one `temporary_storage` of the sum type; the arms
// then test its `.discriminant` as for any `choice`. Exhaustive without
// `default` (SF-7).
//@dump-sem-ir-begin
fn F(n: i32) -> i32 {
  match (Cpp.MakeOptional(n)) {
    case .Some(v: i32) => {
      return v;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}
//@dump-sem-ir-end

// --- if_let.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// `if`-`let` shares the scrutinee gate (refutable_binding.cpp).
//@dump-sem-ir-begin
fn G(n: i32) -> i32 {
  if (let .Some(v: i32) = Cpp.MakeOptional(n)) {
    return v;
  }
  return 0;
}
//@dump-sem-ir-end

// --- convert.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Both directions as implicit conversions: the C++ class to the sum type, and
// the sum type -- computed or the `None` constant -- to a by-value and a
// `const&` parameter. Overload resolution sees a `StdOptional(i32)` argument
// as the C++ class.
//@dump-sem-ir-begin
fn H(n: i32) -> i32 {
  let s: Core.CppCompat.StdOptional(i32) = Cpp.MakeOptional(n);
  let none: Core.CppCompat.StdOptional(i32) =
      Core.CppCompat.StdOptional(i32).None;
  return Cpp.Take(s) + Cpp.TakeRef(s) + Cpp.Take(none);
}
//@dump-sem-ir-end

// --- pointer_payload.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A nullable C++ `int*` payload is `Core.Optional(i32*)`, which D-SV-8
// admits as a choice payload, so an engaged null pointer is
// `.Some(<None pointer>)`, distinct from `.None`.
//@dump-sem-ir-begin
fn P(n: i32) -> bool {
  match (Cpp.MakePointer(n)) {
    case .Some(p: Core.Optional(i32*)) => {
      return p.HasValue();
    }
    case .None => {
      return false;
    }
  }
  return false;
}
//@dump-sem-ir-end

// --- bridge.carbon

library "[[@TEST_NAME]]";

// `StdOptional(T)` and `Core.Optional(T)` convert to each other implicitly,
// through `Optional`'s public API.
fn B(s: Core.CppCompat.StdOptional(i32)) -> Core.CppCompat.StdOptional(i32) {
  let o: Core.Optional(i32) = s;
  return o;
}

// --- one_step_core_optional.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::optional<T>` converts to `Core.Optional(T')` in one implicit step,
// through its sum type and the bridge; a `Core.Optional(T')` whose payload is
// not a pointer is offered to C++ as `std::optional<T>` and converted back the
// same way (fork/sumtype-interop/plan.md §1.7).
//@dump-sem-ir-begin
fn O(n: i32) -> i32 {
  let o: Core.Optional(i32) = Cpp.MakeOptional(n);
  return Cpp.Take(o) + Cpp.TakeRef(o);
}
//@dump-sem-ir-end

// --- monostate_payload.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// `std::optional<std::monostate>`'s `Some` carries `()`, in both directions.
fn M(n: i32) -> bool {
  match (Cpp.MakeMono(n)) {
    case .Some(_: ()) => {
      return Cpp.TakeMono(Core.CppCompat.StdOptional(()).Some(()));
    }
    case .None => {
      return false;
    }
  }
  return false;
}

// --- fail_todo_struct_payload.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// SF-6: a class payload has no Carbon sum type in 0.1 (plan §1.3); the class
// import is unaffected, only the `match` is diagnosed.
fn S() -> i32 {
  match (Cpp.MakePoint()) {
    case .None => {
      return 0;
    }
    default => {
      return 1;
    }
  }
  return 2;
}

// --- fail_dead_default.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The sum type's closed alternative set makes a trailing `default` dead
// (`MatchDefaultNeverMatches`), as for any `choice`.
fn D(n: i32) -> i32 {
  match (Cpp.MakeOptional(n)) {
    case .Some(v: i32) => {
      return v;
    }
    case .None => {
      return -1;
    }
    default => {
      return -2;
    }
  }
  return -3;
}

// --- fail_unknown_alternative.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The alternatives are the sum type's, `Some` and `None`.
fn U(n: i32) -> i32 {
  match (Cpp.MakeOptional(n)) {
    case .Ok(v: i32) => {
      return v;
    }
    default => {
      return -1;
    }
  }
  return -2;
}

// --- fail_todo_outside_function.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The conversion branches, and control flow outside a function is not
// supported in 0.1 (plan §1.4).
let global: Core.CppCompat.StdOptional(i32) = Cpp.MakeOptional(1);

// --- fail_todo_ref_binding.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The scrutinee is the by-value conversion of the C++ object, not the object,
// so a `ref` payload binding has no durable reference to bind (§1.6).
fn R() {
  var o: Cpp.std.optional(i32) = Cpp.MakeOptional(1);
  match (o) {
    case .Some(ref n: i32) => {
      n = 2;
    }
    case .None => {}
  }
}
```

<!-- google-doc-style-resume -->

### B: check/testdata/interop/cpp/stdlib/variant.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/variant.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/variant.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1, F-020): a
// `std::variant<Ts...>` specialization of one to eight alternatives
// converts by value to `Core.CppCompat.StdVariant<N>(Ts'...)`, whose
// alternative `.Alt<I>` is the C++ alternative `I`: `index()`, then
// `std::get<I>`; back through the default constructor and `emplace<I>`.

// --- sum.h

// Mocks of libc++'s `std::optional` and `std::variant`, as string_view.carbon
// and span.carbon mock theirs, so the goldens are hermetic: the members the
// conversions call (`has_value`, `value`, `emplace`, `index`, `std::get`),
// libc++'s inline namespace, and `size_t` pinned by `--target`.
namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template <typename T>
    class optional {
     public:
      optional() : value_(), engaged_(false) {}
      optional(T value) : value_(value), engaged_(true) {}
      bool has_value() const { return engaged_; }
      const T& value() const { return value_; }
      template <typename... A>
      T& emplace(A... args) {
        value_ = T(args...);
        engaged_ = true;
        return value_;
      }

     private:
      T value_;
      bool engaged_;
    };

    struct monostate {};

    template <typename... Ts>
    class variant {
     public:
      variant() : index_(0) { emplace<0>(); }
      size_t index() const { return index_; }
      template <size_t I, typename... A>
      __type_pack_element<I, Ts...>& emplace(A... args) {
        index_ = I;
        auto* p = reinterpret_cast<__type_pack_element<I, Ts...>*>(storage_);
        *p = __type_pack_element<I, Ts...>(args...);
        return *p;
      }
      alignas(8) unsigned char storage_[8];
      size_t index_;
    };

    template <size_t I, typename... Ts>
    const __type_pack_element<I, Ts...>& get(const variant<Ts...>& v) {
      return *reinterpret_cast<const __type_pack_element<I, Ts...>*>(
          v.storage_);
    }
  }
}

inline auto IntOrHalf(int n) -> std::variant<int, double> {
  std::variant<int, double> v;
  if (n > 0) {
    v.emplace<0>(n);
  } else {
    v.emplace<1>(n * 0.5);
  }
  return v;
}

inline auto MaybeEmpty(int n) -> std::variant<std::monostate, int> {
  std::variant<std::monostate, int> v;
  if (n > 0) v.emplace<1>(n);
  return v;
}

inline auto LeftOrRight(int n) -> std::variant<int, int> {
  std::variant<int, int> v;
  v.emplace<1>(n);
  return v;
}

inline auto TakePair(const std::variant<int, int>& v) -> int {
  return static_cast<int>(v.index());
}

using Nine = std::variant<int, int, int, int, int, int, int, int, int>;
inline auto MakeNine() -> Nine { return Nine(); }

inline auto Nested() -> std::variant<std::optional<int>, int> {
  return std::variant<std::optional<int>, int>();
}

// --- match.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Predicted: one `index` thunk call, one equality test per alternative but
// the last, a `std::get<I>` thunk call per alternative, and
// `StdVariant2(i32, f64).Alt<I>` into one `temporary_storage`.
//@dump-sem-ir-begin
fn F(n: i32) -> i32 {
  match (Cpp.IntOrHalf(n)) {
    case .Alt0(i: i32) => {
      return i;
    }
    case .Alt1(unused d: f64) => {
      return -1;
    }
  }
  return -2;
}
//@dump-sem-ir-end

// --- monostate.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::monostate` alternative has the payload `()`; no `std::get` call.
//@dump-sem-ir-begin
fn M(n: i32) -> i32 {
  match (Cpp.MaybeEmpty(n)) {
    case .Alt0(unused empty: ()) => {
      return 0;
    }
    case .Alt1(i: i32) => {
      return i;
    }
  }
  return -1;
}
//@dump-sem-ir-end

// --- duplicate.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Duplicate alternative types are told apart by index, both ways.
//@dump-sem-ir-begin
fn D(n: i32) -> i32 {
  match (Cpp.LeftOrRight(n)) {
    case .Alt0(unused left: i32) => {
      return 0;
    }
    case .Alt1(right: i32) => {
      return Cpp.TakePair(Core.CppCompat.StdVariant2(i32, i32).Alt1(right));
    }
  }
  return -1;
}
//@dump-sem-ir-end

// --- fail_todo_too_many_alternatives.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// `Core.CppCompat` declares `StdVariant1` to `StdVariant8` (plan §1.2).
fn N() -> i32 {
  match (Cpp.MakeNine()) {
    default => {
      return 0;
    }
  }
  return 1;
}

// --- fail_todo_nested_by_value.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::optional` held by value in a `std::variant` is a class payload
// (SF-6, plan §1.3); held by pointer it is a pointer payload.
fn V() -> i32 {
  match (Cpp.Nested()) {
    default => {
      return 0;
    }
  }
  return 1;
}

// --- fail_index_out_of_range.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn R(n: i32) -> i32 {
  match (Cpp.IntOrHalf(n)) {
    case .Alt2(i: i32) => {
      return i;
    }
    default => {
      return -1;
    }
  }
  return -2;
}
```

<!-- google-doc-style-resume -->

### B: check/testdata/interop/cpp/stdlib/fail_sum_types.carbon

Rev 5 appends the `sink.h` header split and `fail_todo_rvalue_ref_param`
(amended 2026-10-20, review fold: RR4-M1); the file's other splits are rev 4's.

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_sum_types.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/fail_sum_types.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1.11): the shapes outside the
// `std::optional`/`std::variant` mapping, each diagnosed, none a crash.

// --- sum.h

// Mocks of libc++'s `std::optional` and `std::variant`, as string_view.carbon
// and span.carbon mock theirs, so the goldens are hermetic: the members the
// conversions call (`has_value`, `value`, `emplace`, `index`, `std::get`),
// libc++'s inline namespace, and `size_t` pinned by `--target`.
namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template <typename T>
    class optional {
     public:
      optional() : value_(), engaged_(false) {}
      optional(T value) : value_(value), engaged_(true) {}
      template <typename U>
      optional(const optional<U>& other) : value_(), engaged_(false) {
        if (other.has_value()) emplace(other.value());
      }
      bool has_value() const { return engaged_; }
      const T& value() const { return value_; }
      template <typename... A>
      T& emplace(A... args) {
        value_ = T(args...);
        engaged_ = true;
        return value_;
      }

     private:
      T value_;
      bool engaged_;
    };

    struct monostate {};

    template <typename... Ts>
    class variant {
     public:
      variant() : index_(0) { emplace<0>(); }
      size_t index() const { return index_; }
      template <size_t I, typename... A>
      __type_pack_element<I, Ts...>& emplace(A... args) {
        index_ = I;
        auto* p = reinterpret_cast<__type_pack_element<I, Ts...>*>(storage_);
        *p = __type_pack_element<I, Ts...>(args...);
        return *p;
      }
      alignas(8) unsigned char storage_[8];
      size_t index_;
    };

    template <size_t I, typename... Ts>
    const __type_pack_element<I, Ts...>& get(const variant<Ts...>& v) {
      return *reinterpret_cast<const __type_pack_element<I, Ts...>*>(
          v.storage_);
    }
  }
}
inline auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) return std::optional<int>(n);
  return std::optional<int>();
}

inline auto MakeConst() -> std::optional<const int> {
  return std::optional<const int>();
}

struct NonTrivial {
  ~NonTrivial() {}
  int n;
};

inline auto MakeNonTrivial() -> std::optional<NonTrivial> {
  return std::optional<NonTrivial>();
}

inline auto Take(std::optional<int> o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto TakeLong(std::optional<long> o) -> long {
  return o.has_value() ? o.value() : -1;
}

struct Wrapper {
  Wrapper(std::optional<int> o) : n(o.has_value() ? o.value() : -1) {}
  int n;
};

inline auto TakeWrapper(Wrapper w) -> int { return w.n; }

// --- fail_todo_qualified_alternative.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// The mock `optional<const int>` is trivially copyable, so the qualified
// alternative is the rule that fails (§1.3 rule 3).
fn F() {
  match (Cpp.MakeConst()) {
    default => {}
  }
}

// --- fail_todo_non_trivial.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A class with a non-trivial destructor (§1.3 rule 1).
fn N() {
  match (Cpp.MakeNonTrivial()) {
    default => {}
  }
}

// --- fail_conversion_mismatch.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A C++ sum type converts only to its own Carbon sum type.
fn G() {
  let unused s: Core.CppCompat.StdOptional(i64) = Cpp.MakeOptional(1);
}

// --- fail_core_optional_mismatch.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `std::optional<int>` converts in one step to `Core.Optional(i32)` only.
fn H() {
  let unused o: Core.Optional(i64) = Cpp.MakeOptional(1);
}

// --- core_optional_argument_as.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn K() -> i32 {
  return Cpp.Take(Core.Optional(i32).Some(3) as Core.CppCompat.StdOptional(i32));
}

// --- fail_todo_export_sum_type.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A `Core.CppCompat` sum type in a signature that C++ calls is not exported;
// the C++ class is the exportable spelling.
fn MakeView(x: i32) -> Core.CppCompat.StdOptional(i32) {
  return Core.CppCompat.StdOptional(i32).Some(x);
}

inline Cpp '''
inline int Use() { Carbon::MakeView(3); return 1; }
''';

// --- fail_reverse_other_specialization.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A Carbon sum value converts only to the C++ class whose sum type it is, not
// to another specialization through C++'s converting constructor, which would
// narrow or widen the payload silently (§1.5).
fn L() -> i64 {
  return Cpp.TakeLong(Core.CppCompat.StdOptional(i32).Some(3));
}

// --- fail_reverse_converting_class.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// Nor to a class with a converting constructor from that class.
fn W() -> i32 {
  return Cpp.TakeWrapper(Core.CppCompat.StdOptional(i32).Some(3));
}

// --- fail_todo_tuple_scrutinee.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A C++ sum class inside a tuple scrutinee is not converted (§1.11).
fn T() {
  let t: (Cpp.std.optional(i32), i32) = (Cpp.MakeOptional(1), 2);
  match (t) {
    default => {}
  }
}

// --- fail_todo_if_arm.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A conversion inside an `if`-expression arm makes temporaries that the arm
// must destroy before yielding a value whose representation is not a copy: the
// existing conditional-operand cleanup TODO (§1.11).
fn I(c: bool) {
  let unused s: Core.CppCompat.StdOptional(i32) =
      if c then Cpp.MakeOptional(1) else Cpp.MakeOptional(0);
}

// --- fail_todo_template_conversion.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A template defers the conversion of its dependent value to instantiation,
// where no control flow can be built (§1.10).
fn Pass[template T: type](x: T) -> Core.CppCompat.StdOptional(i32) {
  return x;
}

fn U() {
  let unused s: Core.CppCompat.StdOptional(i32) = Pass(Cpp.MakeOptional(1));
}

// --- sink.h

#include "sum.h"

inline auto TakeRvalue(std::optional<int>&& o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto Put(const std::optional<int>& o) -> int {
  return o.has_value() ? 100 + o.value() : -100;
}

inline auto Put(std::optional<int>&& o) -> int {
  return o.has_value() ? 200 + o.value() : -200;
}

// --- fail_todo_rvalue_ref_param.carbon

library "[[@TEST_NAME]]";

import Cpp library "sink.h";

// A sum value or `Core.Optional` passed to a C++ `T&&` parameter, alone or the
// member C++ selects from a `const T&` and `T&&` pair, initializes the
// parameter at its C++ declaration, which gives the conversion no parse node
// for its branches (§1.5, §1.11).
fn R() -> i32 {
  return Cpp.TakeRvalue(Core.CppCompat.StdOptional(i32).Some(5));
}

fn P() -> i32 {
  return Cpp.Put(Core.Optional(i32).Some(6));
}

// A value, such as a parameter, selects the `const&` member, which converts.
fn V(o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return Cpp.Put(o);
}
```

<!-- google-doc-style-resume -->

At M-VA (§3 item 8; added 2026-10-20, review fold: RR-M1), after PR 59 has
landed, this split is appended to the file (VA-1's `...` and `each` syntax
exists only then); its fill on the PR 59 composition is
`$Y/final/goldens-filled-M/` (rev 5: refilled over the extended file, the
split's own fill byte-identical to rev 4's `$W/final/goldens-filled-M/`; amended
2026-10-20, review fold: RR4-M1). Rev 4 adds the tuple, struct, array and class
forms in both directions (amended 2026-10-20, review fold: RR3-B1); rev 3's two
functions are unchanged:

<!-- google-doc-style-ignore -->

```carbon
// --- fail_todo_pack_element.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// A pack element is converted in one straight-line block per element, which
// cannot hold the conversion's branches (§1.11, the land-time rule of §3 item
// 8): forwarding a pack of C++ optionals to a pack of their sum type, and back;
// and the same for a pack whose element is a tuple, struct, array or class
// holding one, whose conversion converts what it projects from the element.
fn Each(... unused each o: Core.CppCompat.StdOptional(i32)) {}

fn Forward(... each c: Cpp.std.optional(i32)) {
  Each(... each c);
}

fn TakeEach(... unused each c: Cpp.std.optional(i32)) {}

fn Back(... each o: Core.CppCompat.StdOptional(i32)) {
  TakeEach(... each o);
}

fn EachTuple(... unused each t: (Core.CppCompat.StdOptional(i32), i32)) {}

fn ForwardTuple(... each t: (Cpp.std.optional(i32), i32)) {
  EachTuple(... each t);
}

fn TakeEachTuple(... unused each t: (Cpp.std.optional(i32), i32)) {}

fn BackTuple(... each t: (Core.CppCompat.StdOptional(i32), i32)) {
  TakeEachTuple(... each t);
}

fn EachStruct(... unused each s: {.o: Core.CppCompat.StdOptional(i32)}) {}

fn ForwardStruct(... each s: {.o: Cpp.std.optional(i32)}) {
  EachStruct(... each s);
}

fn TakeEachStruct(... unused each s: {.o: Cpp.std.optional(i32)}) {}

fn BackStruct(... each s: {.o: Core.CppCompat.StdOptional(i32)}) {
  TakeEachStruct(... each s);
}

fn EachArray(... unused each a: array(Core.CppCompat.StdOptional(i32), 1)) {}

fn ForwardArray(... each t: (Cpp.std.optional(i32),)) {
  EachArray(... each t);
}

fn TakeEachArray(... unused each a: array(Cpp.std.optional(i32), 1)) {}

fn BackArray(... each t: (Core.CppCompat.StdOptional(i32),)) {
  TakeEachArray(... each t);
}

class SumHolder {
  var o: Core.CppCompat.StdOptional(i32);
}

fn EachSumHolder(... unused each h: SumHolder) {}

fn ForwardClass(... each s: {.o: Cpp.std.optional(i32)}) {
  EachSumHolder(... each s);
}

class CppHolder {
  var o: Cpp.std.optional(i32);
}

fn EachCppHolder(... unused each h: CppHolder) {}

fn BackClass(... each s: {.o: Core.CppCompat.StdOptional(i32)}) {
  EachCppHolder(... each s);
}
```

<!-- google-doc-style-resume -->

### B: check/testdata/interop/cpp/stdlib/sum_type_overload.carbon

Rev 3 appends eight splits, from `tuple_member` to `file_scope`, and two
sentences to the header comment (amended 2026-10-20, review fold: RR-B1 / RR-B-1
/ RR-m1). Rev 4 adds `scalar_tuple_mismatch_first` (amended 2026-10-20, review
fold: RR3-m4), renames `file_scope` to `fail_todo_file_scope`, which the call's
TODO now fails, adds `fail_todo_template_overload`, and rewrites the header's
last sentence (amended 2026-10-20, review fold: RR3-M1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/sum_type_overload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/sum_type_overload.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1.4): an `overload fn` set probes
// each member by converting the arguments without diagnosing, then discards
// the probe; a sum-type conversion there builds no control flow and emits
// nothing, so a member that does not accept the argument is skipped and the
// member that does is called, in either direction and for a generic member.
// The element conversions of a tuple, struct or array argument are probed the
// same way, scalar elements included. A member whose parameter the argument
// converts to is accepted even where the call cannot build the conversion (at
// file scope, or at a template's instantiation), and the call reports that
// limit, so the member a call selects does not depend on where the call is.

// --- sum.h

// Mocks of libc++'s `std::optional` and `std::variant`, as string_view.carbon
// and span.carbon mock theirs, so the goldens are hermetic: the members the
// conversions call (`has_value`, `value`, `emplace`, `index`, `std::get`),
// libc++'s inline namespace, and `size_t` pinned by `--target`.
namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template <typename T>
    class optional {
     public:
      optional() : value_(), engaged_(false) {}
      optional(T value) : value_(value), engaged_(true) {}
      bool has_value() const { return engaged_; }
      const T& value() const { return value_; }
      template <typename... A>
      T& emplace(A... args) {
        value_ = T(args...);
        engaged_ = true;
        return value_;
      }

     private:
      T value_;
      bool engaged_;
    };

    struct monostate {};

    template <typename... Ts>
    class variant {
     public:
      variant() : index_(0) { emplace<0>(); }
      size_t index() const { return index_; }
      template <size_t I, typename... A>
      __type_pack_element<I, Ts...>& emplace(A... args) {
        index_ = I;
        auto* p = reinterpret_cast<__type_pack_element<I, Ts...>*>(storage_);
        *p = __type_pack_element<I, Ts...>(args...);
        return *p;
      }
      alignas(8) unsigned char storage_[8];
      size_t index_;
    };

    template <size_t I, typename... Ts>
    const __type_pack_element<I, Ts...>& get(const variant<Ts...>& v) {
      return *reinterpret_cast<const __type_pack_element<I, Ts...>*>(
          v.storage_);
    }
  }
}

struct Point {
  int x;
  int y;
};

inline auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) return std::optional<int>(n);
  return std::optional<int>();
}

inline int cell = 0;

inline auto MakePointer(int n) -> std::optional<int*> {
  if (n > 0) return std::optional<int*>(&cell);
  return std::optional<int*>();
}

inline auto MakePoint() -> std::optional<Point> {
  return std::optional<Point>(Point{1, 2});
}

inline auto Take(std::optional<int> o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto TakeRef(const std::optional<int>& o) -> int {
  return o.has_value() ? o.value() : -2;
}

inline auto MakeMono(int n) -> std::optional<std::monostate> {
  if (n > 0) return std::optional<std::monostate>(std::monostate());
  return std::optional<std::monostate>();
}

inline auto TakeMono(std::optional<std::monostate> o) -> bool {
  return o.has_value();
}

// --- convert_first.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(o: Core.CppCompat.StdOptional(i32)) -> i32 {
  match (o) {
    case .Some(n: i32) => {
      return n;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick(Cpp.MakeOptional(7));
}

// --- convert_second.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused b: bool) -> i32 { return 100; }
overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 1;
}

fn F() -> i32 {
  return Pick(Cpp.MakeOptional(7));
}

// --- mismatch_first.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused o: Core.CppCompat.StdOptional(i64)) -> i32 {
  return 1;
}
overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 2;
}

fn F() -> i32 {
  return Pick(Cpp.MakeOptional(7));
}

// --- not_mapped_first.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 1;
}
overload fn Pick(o: Cpp.std.optional(Cpp.Point)) -> i32 {
  return o.value().x;
}

fn F() -> i32 {
  return Pick(Cpp.MakePoint());
}

// --- reverse.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused b: bool) -> i32 { return 100; }
overload fn Pick(o: Cpp.std.optional(i32)) -> i32 {
  return o.value();
}

fn F() -> i32 {
  return Pick(Core.CppCompat.StdOptional(i32).Some(3));
}

// --- generic_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick[T: Core.Copy & Core.Destroy](unused x: T,
                                              o: Core.CppCompat.StdOptional(i32))
    -> i32 {
  match (o) {
    case .Some(n: i32) => {
      return n;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}
overload fn Pick(unused x: bool, unused y: bool) -> i32 { return 0; }

fn F() -> i32 {
  return Pick(1 as i32, Cpp.MakeOptional(7));
}

// --- tuple_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused t: (Core.CppCompat.StdOptional(i32), i32)) -> i32 {
  return 1;
}
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick((Cpp.MakeOptional(7), 1));
}

// --- tuple_mismatch_first.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused t: (Core.CppCompat.StdOptional(i64), i32)) -> i32 {
  return 1;
}
overload fn Pick(unused t: (Core.CppCompat.StdOptional(i32), i32)) -> i32 {
  return 2;
}

fn F() -> i32 {
  return Pick((Cpp.MakeOptional(7), 1));
}

// --- struct_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused b: bool) -> i32 { return 100; }
overload fn Pick(unused s: {.a: Core.CppCompat.StdOptional(i32), .b: i32})
    -> i32 {
  return 1;
}

fn F() -> i32 {
  return Pick({.a = Cpp.MakeOptional(7), .b = 1});
}

// --- array_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused a: array(Core.CppCompat.StdOptional(i32), 1)) -> i32 {
  return 1;
}
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick((Cpp.MakeOptional(7),));
}

// --- tuple_reverse.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(t: (Cpp.std.optional(i32), i32)) -> i32 {
  return Cpp.Take(t.0) + t.1;
}
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick((Core.CppCompat.StdOptional(i32).Some(4), 1));
}

// --- tuple_core_optional.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused t: (Core.Optional(i32), i32)) -> i32 { return 1; }
overload fn Pick(unused b: bool) -> i32 { return 100; }

fn F() -> i32 {
  return Pick((Cpp.MakeOptional(7), 1));
}

// --- generic_tuple_member.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick[T: Core.Copy & Core.Destroy](
    unused x: T, unused t: (Core.Optional(i32), i32)) -> i32 {
  return 1;
}
overload fn Pick(unused x: bool, unused y: bool) -> i32 { return 0; }

fn F() -> i32 {
  return Pick(1 as i32, (Cpp.MakeOptional(7), 1));
}

// --- scalar_tuple_mismatch_first.carbon

library "[[@TEST_NAME]]";

// No sum type: the first member's tuple elements are probed without
// diagnosing, so it is skipped with no error, and the second is called, as the
// return type shows.
overload fn Pick(unused t: (i32, i32)) -> i32 { return 1; }
overload fn Pick(unused t: (bool, bool)) -> bool { return true; }

fn F() -> bool {
  return Pick((true, false));
}

// --- fail_todo_file_scope.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 1;
}
overload fn Pick(unused o: Cpp.std.optional(i32)) -> i32 { return 2; }

// At file scope the sum-type conversion cannot be built (W-036). The argument
// converts to the first member's parameter, so the probe accepts that member,
// and the call reports the limit rather than calling the second member.
let x: i32 = Pick(Cpp.MakeOptional(7));

// --- fail_todo_template_overload.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

overload fn Pick(unused o: Core.CppCompat.StdOptional(i32)) -> i32 {
  return 1;
}
overload fn Pick[T: Core.Copy & Core.Destroy](unused x: T) -> i32 {
  return 2;
}

// A template performs the call's conversion at its instantiation, where the
// sum-type conversion cannot be built either (§1.10): the probe accepts the
// first member, and the instantiation reports the limit rather than calling
// the generic member.
fn Call[template T: type](x: T) -> i32 {
  return Pick(x);
}

fn F() -> i32 {
  return Call(Cpp.MakeOptional(7));
}
```

<!-- google-doc-style-resume -->

### B: check/testdata/choice/optional_pointer_payload.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/choice/optional_pointer_payload.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/choice/optional_pointer_payload.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md D-SV-8): the SF-6 payload
// predicate admits the pointer-niche `Core.Optional(T*)` -- an adapter of
// `MaybeUnformed(T*)` -- by name, as a pointer payload; `Core.Optional(T)` for
// a non-pointer `T`, and the other qualified adapters (`Cpp.nullptr_t`,
// `Core.MaybeUnformed(T)`), are still not payloads.

// --- pointer.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
choice Slot {
  Held(p: Core.Optional(i32*)),
  Empty
}

fn Read(s: Slot) -> bool {
  match (s) {
    case .Held(p: Core.Optional(i32*)) => {
      return p.HasValue();
    }
    case .Empty => {
      return false;
    }
  }
  return false;
}
//@dump-sem-ir-end

// --- fail_todo_non_pointer_optional.carbon

library "[[@TEST_NAME]]";

choice Boxed {
  Held(o: Core.Optional(i32)),
  Empty
}

// --- fail_todo_nullptr_payload.carbon

library "[[@TEST_NAME]]";

choice NullBox {
  Held(p: Core.CppCompat.NullptrT),
  Empty
}

// --- fail_todo_maybe_unformed_payload.carbon

library "[[@TEST_NAME]]";

choice Unformed {
  Held(x: Core.MaybeUnformed(i32*)),
  Empty
}
```

<!-- google-doc-style-resume -->

### B: check/testdata/match/core_optional_view.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/match/core_optional_view.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/match/core_optional_view.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1.7): a `Core.Optional(T)`
// scrutinee whose payload is a concrete 0.1 choice payload type is matched as
// its view `Core.CppCompat.StdOptional(T)`, converted by value through the
// prelude's `ImplicitAs` impl; the class is unchanged.

// --- concrete.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(o: Core.Optional(i32)) -> i32 {
  match (o) {
    case .Some(value: i32) => {
      return value;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}
//@dump-sem-ir-end

// --- pointer.carbon

library "[[@TEST_NAME]]";

// `Core.Optional(T*)`'s `None` is the null pointer; `.Some` binds the
// non-null `T*`.
fn G(p: Core.Optional(i32*)) -> i32 {
  if (let .Some(q: i32*) = p) {
    return *q;
  }
  return 0;
}

// --- fail_todo_generic.carbon

library "[[@TEST_NAME]]";

// A symbolic payload type is not viewed: whether `StdOptional(T)` is a valid
// choice would be known only at monomorphization (§1.7).
fn H[T: Core.Copy & Core.Destroy](o: Core.Optional(T)) -> bool {
  match (o) {
    case .Some(unused value: T) => {
      return true;
    }
    case .None => {
      return false;
    }
  }
  return false;
}

// --- fail_todo_aggregate.carbon

library "[[@TEST_NAME]]";

// Nor a payload that is not a 0.1 choice payload type (SF-6).
fn A(o: Core.Optional((i32, i32))) -> bool {
  if (let .Some(unused value: (i32, i32)) = o) {
    return true;
  }
  return false;
}

// --- fail_todo_ref_binding.carbon

library "[[@TEST_NAME]]";

// The view is a by-value copy, so a `ref` payload binding is rejected.
fn R() {
  var o: Core.Optional(i32) = Core.Optional(i32).Some(4);
  match (o) {
    case .Some(ref n: i32) => {
      n = 9;
    }
    case .None => {}
  }
}

// --- fail_unknown_alternative.carbon

library "[[@TEST_NAME]]";

fn K(o: Core.Optional(i32)) {
  match (o) {
    case .Ok(unused value: i32) => {}
    default => {}
  }
}
```

<!-- google-doc-style-resume -->

### B: lower/testdata/interop/cpp/std_sum_types.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/std_sum_types.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/std_sum_types.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md §1, F-020): the conversions as
// LLVM IR: the C++ object keeps libc++'s layout in its own alloca and is read
// only through the accessor thunks; the Carbon sum type is a separate alloca
// of the `choice` layout (`<{ <{ i1, [3 x i8] }>, [4 x i8] }>` for
// `StdOptional(i32)`), written by `Some`'s constructor or the `None`
// constant's copy; the reverse builds the C++ object by its default
// constructor and `emplace`.

// --- sum.h

// Mocks of libc++'s `std::optional` and `std::variant`, as string_view.carbon
// and span.carbon mock theirs, so the goldens are hermetic: the members the
// conversions call (`has_value`, `value`, `emplace`, `index`, `std::get`),
// libc++'s inline namespace, and `size_t` pinned by `--target`.
namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template <typename T>
    class optional {
     public:
      optional() : value_(), engaged_(false) {}
      optional(T value) : value_(value), engaged_(true) {}
      bool has_value() const { return engaged_; }
      const T& value() const { return value_; }
      template <typename... A>
      T& emplace(A... args) {
        value_ = T(args...);
        engaged_ = true;
        return value_;
      }

     private:
      T value_;
      bool engaged_;
    };

    struct monostate {};

    template <typename... Ts>
    class variant {
     public:
      variant() : index_(0) { emplace<0>(); }
      size_t index() const { return index_; }
      template <size_t I, typename... A>
      __type_pack_element<I, Ts...>& emplace(A... args) {
        index_ = I;
        auto* p = reinterpret_cast<__type_pack_element<I, Ts...>*>(storage_);
        *p = __type_pack_element<I, Ts...>(args...);
        return *p;
      }
      alignas(8) unsigned char storage_[8];
      size_t index_;
    };

    template <size_t I, typename... Ts>
    const __type_pack_element<I, Ts...>& get(const variant<Ts...>& v) {
      return *reinterpret_cast<const __type_pack_element<I, Ts...>*>(
          v.storage_);
    }
  }
}

inline auto MakeOptional(int n) -> std::optional<int> {
  if (n > 0) return std::optional<int>(n);
  return std::optional<int>();
}

inline auto IntOrHalf(int n) -> std::variant<int, double> {
  std::variant<int, double> v;
  if (n > 0) {
    v.emplace<0>(n);
  } else {
    v.emplace<1>(n * 0.5);
  }
  return v;
}

inline auto Take(std::optional<int> o) -> int {
  return o.has_value() ? o.value() : -1;
}

inline auto TakeVariant(std::variant<int, double> v) -> int {
  return static_cast<int>(v.index());
}

// --- optional.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn F(n: i32) -> i32 {
  match (Cpp.MakeOptional(n)) {
    case .Some(v: i32) => {
      return v;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}

fn G(n: i32) -> i32 {
  return Cpp.Take(Core.CppCompat.StdOptional(i32).Some(n));
}

// --- variant.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

fn H(n: i32) -> i32 {
  match (Cpp.IntOrHalf(n)) {
    case .Alt0(i: i32) => {
      return i;
    }
    case .Alt1(unused d: f64) => {
      return -1;
    }
  }
  return -2;
}

fn K(d: f64) -> i32 {
  return Cpp.TakeVariant(Core.CppCompat.StdVariant2(i32, f64).Alt1(d));
}
```

<!-- google-doc-style-resume -->

### B: lower/testdata/match/constant_choice_scrutinee.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/match/constant_choice_scrutinee.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/match/constant_choice_scrutinee.carbon

// Fork (SV-1, fork/sumtype-interop/plan.md D-SV-9): a `match` directly on a
// constant choice value with a payload arm. The payload access folds to the
// payload region's constant, which lowering now gives an address (a private
// constant global) before indexing into it; trunk built a load from a
// non-pointer constant and failed LLVM verification.

choice Opt(T: type) {
  Some(value: T),
  None
}

fn Sink(unused n: i32) {}

fn F() -> i32 {
  match (Opt(i32).None) {
    case .Some(v: i32) => {
      Sink(v);
      return v;
    }
    case .None => {
      return -1;
    }
  }
  return -2;
}
```

<!-- google-doc-style-resume -->

### B: check/testdata/interop/cpp/exceptions/fail_catching.carbon (split appended)

The existing file gains one split at its end (added 2026-10-20, review
fold: A-M3); the hunk, against trunk, from `$X/final/final.diff`:

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/testdata/interop/cpp/exceptions/fail_catching.carbon
+++ b/toolchain/check/testdata/interop/cpp/exceptions/fail_catching.carbon
@@ -169,3 +169,21 @@
   // CHECK:STDERR:
   return Core.Result(i32, Cpp.Exception).Ok(Cpp.get_fn_ptr()()?);
 }
+
+// --- fail_nullptr_return.carbon
+
+library "[[@TEST_NAME]]";
+
+import Cpp;
+
+inline Cpp '''
+decltype(nullptr) may_throw_null();
+''';
+
+// `Cpp.nullptr_t` adapts `MaybeUnformed(VoidBase*)`, a qualified adapter that
+// the SF-6 predicate does not admit, so it is not a scalar success type
+// (fork/sumtype-interop/plan.md D-SV-8 admits only `Core.Optional(T*)`).
+fn F() -> Core.Result(i32, Cpp.Exception) {
+  Cpp.may_throw_null()?;
+  return Core.Result(i32, Cpp.Exception).Ok(0);
+}
```

<!-- google-doc-style-resume -->

## Appendix C: records and docs texts

Added 2026-10-20 (review fold: B-M-3; A-M4 and B-m-10 for C.8's veto digest).
Doc writes C.1 (but for its `<...>` pack-element line, which M-VA writes;
amended 2026-10-20, review fold: RR4-m2) and C.2; Doc-M writes C.3 and C.8's
F-015 amendment paragraph; R writes C.7; D writes C.4, C.5, C.6, the rest of C.8
and C.9, in that order, after M. `YYYY-MM-DD` is the date of the commit that
writes the text, and `<...>` marks a value D measures on the merged tree;
nothing else in a text changes without a document review (§1.14).

**Held state.** While PR 51 to PR 61 are held, SV-1 writes no records commit
and no Doc-M: its branch carries the plan, C1 to C3, P, Doc and any fix
commits, and every record file stays trunk's. If the orchestrator records
SV-1's state on trunk meanwhile, it uses C.9's row with the held wording given
there.

### C.1 docs/design/sum_types.md: the new section and one alternative

Inserted after the section "User-defined sum types" (it ends before
"## Alternatives considered", :248 on trunk); the table of contents is
regenerated by prek's `markdown-toc`.

<!-- google-doc-style-ignore -->

````markdown
## C++ `std::optional` and `std::variant`

> **Fork addition YYYY-MM-DD (F-020; fork/sumtype-interop/plan.md).** Upstream
> has no mapping of these C++ types; this section records the fork's.

A C++ `std::optional<T>` or `std::variant<T0, ..., Tn>` imported into Carbon
stays a C++ class, and its member functions work as for any imported class.
When its alternatives qualify, it also has a Carbon sum type: a specific of a
`choice` that the prelude declares in `Core.CppCompat`.

```carbon
choice CppCompat.StdOptional(T: type) {
  Some(value: T),
  None
}

choice CppCompat.StdVariant2(T0: type, T1: type) {
  Alt0(value: T0),
  Alt1(value: T1)
}
```

`StdOptional(T)` is the `Optional(T)` declaration of
[`choice` declarations](#choice-declarations). `StdVariant1` to `StdVariant8`
name a variant's alternatives by C++ index, because C++ gives them no names: a
value with `index() == 1` is `.Alt1`. A `std::monostate` alternative has the
payload `()`. Two alternatives of the same type are told apart by index.

A `match`, `if let`, `while let` or `let ... else` scrutinee of the C++ class is
converted to its sum type, so alternative patterns consume it, with the
coverage rules of any `choice`: a `match` that names every alternative needs no
`default`. A C++ `std::optional<T>` also converts in one implicit step to and
from `Core.Optional(T)` when `T` is not a pointer type, and a `Core.Optional(T)`
is matched as `StdOptional(T)` when `T` is a scalar or pointer type:

```carbon
import Core library "io";
import Cpp inline '''c++
#include <optional>
#include <variant>
inline auto MaybeSeven() -> std::optional<int> { return 7; }
inline auto Measure() -> std::variant<int, double> { return 2.5; }
inline auto Take(std::optional<int> o) -> int { return o ? *o : -1; }
''';

fn Run() -> i32 {
  match (Cpp.MaybeSeven()) {
    case .Some(n: i32) => { Core.Print(n); }
    case .None => { return 1; }
  }
  match (Cpp.Measure()) {
    case .Alt0(i: i32) => { Core.Print(i); }
    case .Alt1(_: f64) => { Core.Print(-1); }
  }
  let o: Core.Optional(i32) = Cpp.MaybeSeven();
  Core.Print(Cpp.Take(o));
  return 0;
}
```

The conversions copy by value, through the class's own accessors
(`has_value()` and `value()`, `index()` and `std::get<I>()`) in one direction
and its default constructor and `emplace` in the other. They never
reinterpret the object's bytes: a standard library lays these classes out
differently from the discriminant-first layout of a `choice`
([Relationship to choice types](unions.md#relationship-to-choice-types)). A
Carbon sum value converts to C++ only as the class whose sum type it is, so no
C++ converting constructor can narrow its payload.

In 0.1, each of these is diagnosed and recorded as a fork work item:

-   a class that is not trivially copyable and destructible, or an alternative
    that is a class, such as a struct or a nested `std::optional`, by value
    (W-275);
-   a `std::variant` of more than eight alternatives (W-276);
-   a `const`, `volatile` or reference alternative (W-277);
-   a conversion that a template defers to its instantiation (W-279), or one
    in a file-scope initializer or a parameter's default value (W-036);
-   a Carbon sum value passed to a C++ `T&&` parameter, alone or preferred to
    a `const T&` overload such as `std::vector::push_back` (W-285);
<-   a conversion of a VA-1 pack element, in an expansion body or a pack
    converted to a pack of another element type (W-284);>
-   a `ref` payload binding, since the scrutinee is a copy (W-280);
-   a C++ `std::optional` or `std::variant` nested in a tuple or struct
    scrutinee (W-281);
-   a `Core.Optional(T)` scrutinee whose `T` is generic or not a scalar or
    pointer type (W-177).
````

<!-- google-doc-style-resume -->

The list's `<...>` line (added 2026-10-20, review fold: RR4-m2) is the M-VA
commit's: Doc writes the list without it, and M-VA inserts it, without the angle
brackets, once PR 59 has landed (§3 items 5 and 8); the W-036 and W-285 lines
are Doc's (amended 2026-10-20, review fold: RR4-M1 / RR4-m2).

And one bullet appended to "Alternatives considered":

<!-- google-doc-style-ignore -->

```markdown
-   Replacing an imported `std::optional` or `std::variant` by a Carbon
    `choice`, as `std::span` is replaced by `Core.Slice`: the layouts differ,
    and a pointer or reference to the C++ object could not be represented
    (fork decision F-020).
```

<!-- google-doc-style-resume -->

### C.2 docs/design/unions.md: the link

The sentence at :624-627 of "Relationship to choice types" ends "by
user-defined sum types, and by the `std::variant` interop mapping built on
choice.", its first clause a link to sum_types.md's "User-defined sum types".
Doc replaces the source of its last two lines only:

<!-- google-doc-style-ignore -->

```markdown
[user-defined sum types](sum_types.md#user-defined-sum-types), and by the
[`std::variant` interop mapping](sum_types.md#c-stdoptional-and-stdvariant)
built on choice.
```

<!-- google-doc-style-resume -->

### C.3 docs/design/optional.md: the F-015 amendment (Doc-M)

Anchored on PR 57's text at 628273444 (line numbers there); Doc-M replaces
each OLD text, which must occur exactly once in the merged file, by its NEW
text. If an OLD text is not found verbatim, Doc-M stops and the edit goes to a
document review (§1.14).

1.  :101-102. OLD: ``Not provided, on purpose or as a filed limit: `.Some` and
    `.None` patterns and `match` over an Optional (W-177);`` NEW: ``Not
    provided, on purpose or as a filed limit: `.Some` and `.None` patterns and
    `match` over an Optional whose payload is generic or not a scalar or pointer
    type, and a pattern that binds its payload by reference (W-177; matching for
    scalar and pointer payloads since SV-1, YYYY-MM-DD, see
    [Pattern matching](#pattern-matching));``
2.  :204-205. OLD: ``Comparison does not need a `choice`, so F-015 keeps the
    class and records matchability as a limit (W-177, [Pattern
    matching](#pattern-matching)).`` NEW: the OLD text followed by ``Since
    SV-1 (amended YYYY-MM-DD, F-020), a `Core.Optional(T)` of a scalar or
    pointer `T` is matched through a `choice` view, and the class is
    unchanged.``
3.  :328-329. OLD: ``This is a fork divergence, which a by-reference accessor
    or matchability (W-177) removes.`` NEW: ``This is a fork divergence, which
    a by-reference accessor or matching without a copy (W-177) removes; the
    matching of [Pattern matching](#pattern-matching) copies, so it does not
    (amended YYYY-MM-DD, SV-1).``
4.  :444-458, the two paragraphs of "Pattern matching". NEW:

    <!-- google-doc-style-ignore -->

    ```markdown
    `Core.Optional` is a class, not a `choice`. Since SV-1 (amended
    YYYY-MM-DD, F-020; [Sum types](sum_types.md#c-stdoptional-and-stdvariant)),
    a `Core.Optional(T)` whose `T` is a scalar or pointer type (an integer,
    floating-point or `bool` type, a pointer, `()`, or a `Core.Optional(U*)`)
    is matched as its view, the `choice` `Core.CppCompat.StdOptional(T)` with
    the alternatives `.Some(value: T)` and `.None`: `match`, `if let`,
    `while let` and `let ... else` take it, converted by value through
    `HasValue()` and `Get()`, and the class, its API and its storage are
    unchanged. A `Core.Optional(T*)`'s `.Some` binds the non-null `T*`. The
    pattern matching design's `Optional(T).None`, an expression pattern
    compared using `==`, names a value; in this design `None` is a function,
    `Optional(T).None()`, and the view's `.None` is an alternative pattern.

    A generic `T`, or a `T` that is not a scalar or pointer type, is diagnosed
    (W-177), and a `ref` payload binding is rejected, because the view is a
    copy (W-280); such code tests `HasValue()` and then calls `Get()`, or uses
    `?`. The [Sum types](sum_types.md#user-defined-sum-types) design's `Match`
    interface, through which a class becomes matchable without a copy, is not
    implemented. The safety design's examples EX-M-5 and EX-M-6, which match a
    `Core.Optional(Core.Buf(i32))` by reference, wait on W-177, which may close
    by `Match` for classes or by a `choice` that keeps the constraints of
    [A class, not a choice](#a-class-not-a-choice); no redesign of
    `Core.Optional` as a choice comes from this design.
    ```

    <!-- google-doc-style-resume -->
5.  :475-478. OLD: the paragraph beginning ``A mapping of C++'s
    `std::optional<T>` in either direction is not designed here:``. NEW:
    ``A C++ `std::optional<T>` keeps its C++ class and has a Carbon sum type,
    `Core.CppCompat.StdOptional(T)` ([Sum
    types](sum_types.md#c-stdoptional-and-stdvariant), fork decision F-020).
    For a `T` that is not a pointer type, it converts to and from
    `Core.Optional(T)` in one implicit step, through that sum type and the
    prelude's `ImplicitAs` impls, and a `Core.Optional(T)` argument is offered
    to C++ overload resolution as `std::optional<T>`; `Core.Optional(T*)`
    keeps the nullable-pointer mapping above. No exported signature names
    `Core.Optional(T)` for a non-pointer `T` (W-049) (amended YYYY-MM-DD,
    SV-1).``
6.  :501-504. OLD: the W-177 bullet. NEW: ``-   **W-177: `Core.Optional` is
    matched only for a concrete scalar or pointer payload, by value** (narrowed
    YYYY-MM-DD, SV-1). Closes when `.Some` and `.None` patterns over every
    `Core.Optional(T)`, binding by reference, are implemented, by `Match` for
    classes or by a `choice` that keeps the constraints of [A class, not a
    choice](#a-class-not-a-choice).``
7.  :544-547. OLD: ``It closes when `Core.Optional` becomes matchable (W-177)
    or gains a by-reference accessor.`` NEW: ``It closes when `Core.Optional`
    is matched without a copy (W-177) or gains a by-reference accessor.``

R31 for Doc-M: optional.md's heading counts do not change; its bullet count
does not change (item 6 replaces one bullet by one).

### C.4 fork/inventory/work-items.json: the filed items

Appended to `items` after the merged trunk's last item, in id order, at D (§3
item 10; records go in R and D only). W-282 only under its condition (§1.16);
W-278 and W-283 only if the shrink line of §3 item 7 is taken (texts at the
end); W-284 at D once M-VA (§3 item 8) has landed, and held until it has (added
2026-10-20, review fold: RR-M1; amended 2026-10-20, review fold: RR3-m1: rev 3
said "with M-VA", which read as filing it in the M-VA commit); W-285 at D with
the others (added 2026-10-20, review fold: RR4-M1, which also narrows W-279 to
the template form).

<!-- google-doc-style-ignore -->

```json
{
  "id": "W-275",
  "kind": "missing-feature",
  "title": "SV-1 residue: a C++ `std::optional`/`std::variant` whose class is not trivially copyable and destructible, or with an alternative that imports as a class (a trivially copyable struct, a nested `std::optional`/`std::variant` by value), has no Carbon sum type",
  "subsystem": "toolchain/check/cpp (sum_type.cpp) + toolchain/check (type.cpp)",
  "size": "L",
  "bullet": "Type system: Sum types (discriminated unions)",
  "evidence": [
    "toolchain/check/cpp/sum_type.cpp `GetCppSumType` (rules 1 and 4 of fork/sumtype-interop/plan.md §1.3) and `MapAlternative` (`IsInSliceChoicePayloadType`, toolchain/check/type.cpp)",
    "toolchain/check/testdata/interop/cpp/stdlib/optional.carbon `fail_todo_struct_payload`, stdlib/variant.carbon `fail_todo_nested_by_value`, stdlib/fail_sum_types.carbon `fail_todo_non_trivial` (CppSumTypeNotMapped with CppSumTypeAlternativeNotAdmitted or CppSumTypeNotTriviallyCopyable)",
    "fork/sumtype-interop/plan.md §1.3, §1.16"
  ],
  "blocked_by": ["W-010"],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD, fork/sumtype-interop/plan.md §1.16). SF-6 (decision log, W5 SF-1..8) admits trivially copyable and destructible payloads in 0.1, and its implementation admits scalars, pointers and `()` only; the mapping follows the implementation, so `std::optional<S>` for a trivially copyable struct `S`, a nested sum type by value and a class that is not trivially copyable are diagnosed, and the class still imports with its members. Not bounding row 68: SF-6(a), the user's 0.1 decision, bounds every choice, and the error-handling row's precedent attributes the same bound to W-010. Break condition: SF-6's predicate admits aggregates (the struct and nested cases follow with no change to the mapping), or non-trivial payloads get discriminant-dispatched copy and destroy (the class rule is lifted for classes whose alternatives qualify)."
}
{
  "id": "W-276",
  "kind": "missing-feature",
  "title": "SV-1 residue: a C++ `std::variant` of more than eight alternatives has no Carbon sum type",
  "subsystem": "core/prelude (types/cpp/sum.carbon) + toolchain/check/cpp (sum_type.cpp)",
  "size": "M",
  "bullet": "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop",
  "evidence": [
    "core/prelude/types/cpp/sum.carbon (`StdVariant1` to `StdVariant8`)",
    "toolchain/check/cpp/sum_type.cpp `MaxVariantAlternatives`",
    "toolchain/check/testdata/interop/cpp/stdlib/variant.carbon `fail_todo_too_many_alternatives` (CppSumTypeTooManyAlternatives)",
    "fork/sumtype-interop/plan.md §1.2"
  ],
  "blocked_by": [],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD, fork/sumtype-interop/plan.md §1.16). A declared design bound: the prelude declares one generic choice per arity, and every full-prelude compile checks them (nine choices cost 5% of a trivial file's check time at p10, plan §0.6). Not bounding row 68: diagnosed, and the class still imports with its members. Break condition: variadic `choice` declarations, one `StdVariant(... each T)` keeping the `Alt<i>` names."
}
{
  "id": "W-277",
  "kind": "missing-feature",
  "title": "SV-1 residue: a C++ `std::optional`/`std::variant` with a cv-qualified or reference alternative has no Carbon sum type (libc++'s trivially copyable `std::variant<const int, double>` included)",
  "subsystem": "toolchain/check/cpp (sum_type.cpp)",
  "size": "S",
  "bullet": "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop",
  "evidence": [
    "toolchain/check/cpp/sum_type.cpp `GetCppSumType` (rule 3 of fork/sumtype-interop/plan.md §1.3)",
    "toolchain/check/testdata/interop/cpp/stdlib/fail_sum_types.carbon `fail_todo_qualified_alternative` (CppSumTypeQualifiedAlternative)",
    "fork/sumtype-interop/plan.md review fold record, A-m4 / B-m-3 (libc++'s `std::variant<const int, double>` is trivially copyable; review A's g1)"
  ],
  "blocked_by": [],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD, fork/sumtype-interop/plan.md §1.16). The rule keeps the mapping from C++ class to Carbon sum type one-to-one: `std::variant<const int, double>` and `std::variant<int, double>` would share `StdVariant2(i32, f64)`, and a value offered to C++ as one does not convert to the other. libc++'s `std::optional<const int>` is not trivially copyable and is rejected by the triviality rule first; a reference alternative is ill-formed in standard C++17. Not bounding row 68: the class imports with its members and the shape is diagnosed. Break condition: the reverse conversion remembers its exact source class; `const` alternatives are then admitted as their unqualified types."
}
{
  "id": "W-279",
  "kind": "todo-stub",
  "title": "SV-1 residue: a conversion to or from a C++ `std::optional`/`std::variant` that a template defers to its instantiation is a semantics TODO",
  "subsystem": "toolchain/check/cpp (sum_type.cpp `CanBuildBranches`) + toolchain/check (convert.cpp `PerformAction`)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
    "toolchain/check/cpp/sum_type.cpp `CanBuildBranches` (``conversion of a C++ `std::optional` or `std::variant` outside a function body (at file scope, or deferred to a template's instantiation)``)",
    "toolchain/check/testdata/interop/cpp/stdlib/fail_sum_types.carbon `fail_todo_template_conversion`, stdlib/sum_type_overload.carbon `fail_todo_template_overload`",
    "fork/sumtype-interop/plan.md §1.4, §1.10 (review A's h2 and h3 on the TP-1 composition; t4 and t7, the focused re-review of rev 3's RR3-M1)"
  ],
  "blocked_by": [],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD, fork/sumtype-interop/plan.md §1.16). The conversion branches (one arm per alternative) and needs a function body for its blocks; TP-1 performs a template's deferred conversion at instantiation, outside any function body, so the conversion gives this TODO under `unable to monomorphize specific`. An `overload fn` call there whose member takes the sum type gets the same TODO: the member is the one the argument converts to, so it is selected rather than skipped for a later one, and lifting this item does not change which member a program calls. The same TODO at file scope rides W-036, and the no-source-expression TODO beside it is W-285. Not bounding row 68: the same conversion outside a template converts, and the template form is diagnosed. Break condition: TP-1 can emit control flow into an instantiation, or the conversion becomes one call to a synthesized function per specialization (plan §7.2 R-K), which also lifts the file-scope case."
}
{
  "id": "W-280",
  "kind": "missing-feature",
  "title": "SV-1 residue: a `ref` payload binding is rejected on a `match`, `if let`, `while let` or `let ... else` scrutinee that is a C++ `std::optional`/`std::variant` or a `Core.Optional`, which is matched as a by-value conversion",
  "subsystem": "toolchain/check (refutable_binding.cpp, handle_binding_pattern.cpp)",
  "size": "M",
  "bullet": "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop",
  "evidence": [
    "toolchain/check/refutable_binding.cpp (the scrutinee is converted to its `Core.CppCompat` sum type or view before the shape gate)",
    "toolchain/check/handle_binding_pattern.cpp:518-528 (a `ref` binding needs a durable reference)",
    "toolchain/check/testdata/interop/cpp/stdlib/optional.carbon and match/core_optional_view.carbon `fail_todo_ref_binding` (ConversionFailureNonRefToRef)",
    "fork/sumtype-interop/plan.md §1.6, §7.1 R-5"
  ],
  "blocked_by": [],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD, fork/sumtype-interop/plan.md §1.16). A native `choice` `var` scrutinee binds `case .Some(ref n)` into the object; a mapped scrutinee is a converted copy, so the existing `cannot bind durable reference to non-reference value` error is given, and a `var` binding copies, as for any choice. For `Core.Optional` this is part of W-177's open scope (SAFE-1's EX-M-5 matches `case .Some(ref s)`). Not bounding row 68 for the C++ classes: the payload is a scalar or pointer copy, reads agree with C++, and a mutation goes through the class's own API (`emplace`). Break condition: the `Match` interface, or a by-reference view of the C++ object."
}
{
  "id": "W-281",
  "kind": "todo-stub",
  "title": "SV-1 residue: a C++ `std::optional`/`std::variant` nested in a tuple or struct scrutinee is not converted (`match on unsupported scrutinee type`)",
  "subsystem": "toolchain/check (refutable_binding.cpp)",
  "size": "S",
  "bullet": "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop",
  "evidence": [
    "toolchain/check/refutable_binding.cpp (`IsSupportedScrutineeType`; the conversion applies to a whole scrutinee)",
    "toolchain/check/testdata/interop/cpp/stdlib/fail_sum_types.carbon `fail_todo_tuple_scrutinee`",
    "fork/sumtype-interop/plan.md §1.6 (review A's m5)"
  ],
  "blocked_by": [],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD, fork/sumtype-interop/plan.md §1.16). `match (t)` with `t: (Cpp.std.optional(i32), i32)` gives the existing scrutinee TODO, while `(Core.CppCompat.StdOptional(i32), i32)` is supported. Not bounding row 68: the whole-value scrutinee and every nesting through a Carbon sum type work, and the shape is diagnosed. Break condition: the gate converts the elements of tuple and struct scrutinees, or the `Match` interface."
}
{
  "id": "W-284",
  "kind": "todo-stub",
  "title": "SV-1 residue: a conversion to or from a C++ `std::optional`/`std::variant` for a VA-1 pack element (in an expansion body, or a pack converted to a pack of another element type), the element being the C++ class, the sum type, a `Core.Optional`, or a tuple, struct, array or class holding one, is a semantics TODO",
  "subsystem": "toolchain/check/cpp (sum_type.cpp `CanBuildBranches`) + toolchain/check (convert.cpp `ConvertPackToPack`, handle_pack_expansion.cpp)",
  "size": "M",
  "bullet": "Generics: Definition-checked variadics",
  "evidence": [
    "toolchain/check/cpp/sum_type.cpp `CanBuildBranches` and `IsPackElementOrProjection` (``conversion of a C++ `std::optional` or `std::variant` for a pack element``)",
    "toolchain/check/convert.cpp `ConvertPackToPack` (the CHECK ``Control flow in a pack element conversion``, which the TODO keeps the conversion from reaching)",
    "toolchain/check/testdata/interop/cpp/stdlib/fail_sum_types.carbon `fail_todo_pack_element` (the bare element and the tuple, struct, array and class forms, both directions)",
    "fork/sumtype-interop/plan.md §1.4, §1.11, §3 item 8 (M-VA), focused re-review fold record RR-M1 and RR3-B1"
  ],
  "blocked_by": ["W-219"],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD, fork/sumtype-interop/plan.md §1.16), after M-VA. VA-1 converts a pack element in one straight-line block run once per element, and the sum-type conversion branches (one arm per alternative), so the hook refuses a value that is a `SemIR::PackElement` or that a tuple, struct, array, class or adapter conversion projects from one; without the refusal the conversion stopped the compiler at VA-1's CHECK (the focused re-review's v02 and v04, and, for a pack of aggregates, the re-review of rev 3's n01 to n05). A pack of the C++ class, of the sum type or of an aggregate holding either, forwarded unchanged, works, and so does a pack literal. Not bounding row 68: every non-pack form converts, and the shape is diagnosed. Break condition: W-219 lets an expansion body hold control flow, or the conversion becomes one call to a synthesized function per specialization (plan §7.2 R-K)."
}
{
  "id": "W-285",
  "kind": "todo-stub",
  "title": "SV-1 residue: a Carbon sum value or `Core.Optional` passed as an initializing expression to a C++ non-`const` rvalue reference parameter (`T&&`), alone or the member C++ prefers to a `const T&` overload, is a semantics TODO",
  "subsystem": "toolchain/check/cpp (sum_type.cpp `CanBuildBranches`) + toolchain/check (pattern_match.cpp, the parameter's initialization)",
  "size": "S",
  "bullet": "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop",
  "evidence": [
    "toolchain/check/cpp/sum_type.cpp `CanBuildBranches` (``conversion of a C++ `std::optional` or `std::variant` with no source expression``, at the C++ parameter, with the note `initializing function parameter`)",
    "toolchain/check/testdata/interop/cpp/stdlib/fail_sum_types.carbon `fail_todo_rvalue_ref_param`",
    "fork/sumtype-interop/plan.md §1.4, §1.5, §1.11, focused re-review fold record RR4-M1 (r2 to r5, x07, x09, x13 and x19; mutant M22)"
  ],
  "blocked_by": [],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD, fork/sumtype-interop/plan.md §1.16). C++ overload resolution sees a Carbon sum value or `Core.Optional(T)` given as an initializing expression, such as `.Some(5)`, as an rvalue of its C++ class, so it binds a `T&&` parameter and prefers the `T&&` member of a `const T&`/`T&&` pair such as `std::vector::push_back`; the parameter's initialization is located at its C++ declaration, which gives the conversion's branches no parse node, so the conversion gives this TODO there. By value, `const&` and `const&&` parameters convert; a value (a `let` or parameter binding, a constant such as `.None`, or `as` the C++ class) is offered as an lvalue, selects the `const T&` member of a pair, and is refused by a lone `T&&` by C++'s rule, as a value of the C++ class is on trunk; a C++ call's result binds the `T&&`. Not bounding row 68: the row's arbiter is the consumption of C++ values by `match`, which this shape does not touch, and the other parameter forms convert. Removal: attribute the blocks to the argument's own parse node where the parameter's location is not one (mutant M22 of the plan runs the sum-type forms that way; the `Core.Optional` form needs the node of the value before its bridge). Break condition: that removal lands, or the conversion becomes one call to a synthesized function per specialization (plan §7.2 R-K)."
}
{
  "id": "W-282",
  "kind": "toolchain-defect",
  "title": "TP-1 residue (filed by SV-1): a `match` on a template-dependent `choice` value stops the compiler at pattern_match.cpp:1409 (`Alternative constant type differs from scrutinee type`), where trunk gave W-252's TODO",
  "subsystem": "toolchain/check (pattern_match.cpp)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
    "toolchain/check/pattern_match.cpp:1407-1409 <line on the merged trunk>",
    "fork/sumtype-interop/plan.md review fold record, X-1 (x19: `choice Opt(T: type) { Some(value: T), None }` and `fn Conv[template T: type](unused t: T) -> i32 { let s: Opt(T) = Opt(T).None; match (s) { case .Some(unused n: T) => { return 1; } case .None => { return 0; } } return -1; }` called as `Conv(one)`: TP-1's head e408ad4d6 stops, trunk 0bdce60a5 gives `match on unsupported scrutinee type`)"
  ],
  "blocked_by": [],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD) because x19 still stops the merged trunk at <commit> and TP-1 had not filed it. No C++ is involved; the same CHECK stops `match` on `Core.CppCompat.StdOptional(T)` for a template `T`. Break condition: x19 compiles, or gives W-252's TODO again."
}
```

<!-- google-doc-style-resume -->

Shrink-line texts (§3 item 7), filed only if that line is taken:

<!-- google-doc-style-ignore -->

```json
{
  "id": "W-278",
  "kind": "missing-feature",
  "title": "SV-1 residue: a C++ `std::optional<T>` and `Core.Optional(T)` convert into each other only through `Core.CppCompat.StdOptional(T)` (`as`), not implicitly in one step, and a `Core.Optional(T)` is not offered to C++ as `std::optional<T>`",
  "subsystem": "toolchain/check/cpp (sum_type.cpp, type_mapping.cpp)",
  "size": "M",
  "bullet": "Stdlib: Optional",
  "evidence": ["fork/sumtype-interop/plan.md §1.7, §3 item 7 (the shrink line)"],
  "blocked_by": [],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD) only because the shrink line dropped C3. Break condition: C3 of fork/sumtype-interop/plan.md lands."
}
{
  "id": "W-283",
  "kind": "missing-feature",
  "title": "SV-1 residue: a Carbon sum value does not convert to its C++ `std::optional`/`std::variant` class (Carbon to C++)",
  "subsystem": "toolchain/check/cpp (sum_type.cpp, type_mapping.cpp)",
  "size": "M",
  "bullet": "Control flow: matching — sum-type consumption incl. std::variant/std::optional interop",
  "evidence": ["fork/sumtype-interop/plan.md §1.5, §3 item 7 (the shrink line)"],
  "blocked_by": [],
  "notes": "Filed at the SV-1 discharge (YYYY-MM-DD) only because the shrink line dropped the reverse direction. Bounds row 68: interop in one direction only. Break condition: `ConvertCarbonSumToCpp` and the `InventClangArg` mapping of fork/sumtype-interop/plan.md §1.5 land."
}
```

<!-- google-doc-style-resume -->

### C.5 W-177: the narrowing note (OPEN)

Appended to W-177's `notes`, and its `evidence` gains
`toolchain/check/testdata/match/core_optional_view.carbon` and
`fork/conformance/programs/control_flow/match_core_optional_diff.carbon`:

> Narrowed at SV-1 (YYYY-MM-DD, fork/sumtype-interop/plan.md §1.7, F-020): a
> `Core.Optional(T)` scrutinee whose `T` is a concrete 0.1 choice payload type
> (an integer, floating-point, `bool` or pointer type, `()`, or
> `Core.Optional(U*)`) is matched as its view `Core.CppCompat.StdOptional(T)`
> by `match`, `if let`, `while let` and `let ... else`, converted by value
> through `HasValue()` and `Get()`; the class, its API and this item's
> constraints are unchanged. Still open, and diagnosed: a symbolic `T` and a
> payload outside SF-6 (`CoreOptionalNotMatchable`), a `ref` payload binding
> (W-280's `Core.Optional` half) and matching without a copy; so SAFE-1's
> EX-M-5 and EX-M-6 and the D-OP-4 divergence still wait on this item. It
> bounds row 68. Break condition unchanged.

### C.6 Notes on existing items, and W-011's discharge

-   **W-011**, `kind` `implemented`, title "W5b (DISCHARGED at SV-1,
    YYYY-MM-DD): match destructuring of choice payloads (landed at re-platform
    S2c) + transparent std::variant/std::optional interop (landed at SV-1)";
    `evidence` replaced by: `core/prelude/types/cpp/sum.carbon`,
    `toolchain/check/cpp/sum_type.cpp`, `toolchain/check/refutable_binding.cpp`,
    `toolchain/check/testdata/interop/cpp/stdlib/optional.carbon`,
    `.../stdlib/variant.carbon`, `.../stdlib/fail_sum_types.carbon`,
    `.../stdlib/sum_type_overload.carbon`,
    `fork/conformance/programs/control_flow/match_sum_type_payload.carbon` (SKIP
    to PASS) and the four differential programs and the library program of
    fork/sumtype-interop/plan.md §1.13; `notes` appended: "Interop half LANDED
    at SV-1 (YYYY-MM-DD, fork/sumtype-interop/plan.md, F-020): a C++
    `std::optional<T>`/`std::variant<Ts...>` keeps its C++ class and converts by
    value, through its accessors, to and from `Core.CppCompat.StdOptional(T)` /
    `StdVariant1..8` (alternatives `.Alt<i>` by C++ index), and `match`, `if
    let`, `while let` and `let ... else` consume it with exhaustiveness; a C++
    `std::optional<T>` converts to and from `Core.Optional(T)` in one step for a
    non-pointer `T`. The arbiter is met: match_sum_type_payload un-SKIPped and
    PASS, and match_std_optional_diff, match_std_variant_diff,
    match_core_optional_diff, cpp_sum_type_roundtrip_diff and
    cpp_sum_type_library PASS against C++ oracles (container-built,
    <PASS>/<FAIL>/<SKIP> over <programs>, expected, not of record). Residues
    W-275, W-276, W-277, W-279, W-280, W-281, W-285<, W-284><, W-282><,
    W-278><, W-283>; W-177 narrowed, open." (The placeholders are filled from
    C.4's filing rules; amended 2026-10-20, review fold: RR3-m1 / RR3-m2; W-285
    added 2026-10-20, review fold: RR4-M1.)
-   **W-036**, `notes` appended: "SV-1 (YYYY-MM-DD): a conversion to or from a
    C++ `std::optional`/`std::variant` in a file-scope initializer or in a
    parameter's default value gives the TODO
    `conversion of a C++ std::optional or std::variant outside a function body`,
    an `overload fn` call there whose member takes the sum type included (that
    member is selected, not skipped) (fork/sumtype-interop/plan.md §1.4, §1.10;
    optional.carbon `fail_todo_outside_function`, sum_type_overload.carbon
    `fail_todo_file_scope`); it lifts with this item." (amended 2026-10-20,
    review fold: RR3-M1; RR4-m2)
-   **W-047**, `notes` appended: "SV-1 (YYYY-MM-DD): a Carbon library whose API
    names `Cpp.std.optional(...)` reaches an importer without a direct C++
    import of the header through this TODO; an API in
    `Core.CppCompat.StdOptional(...)` does not (fork/sumtype-interop/plan.md
    §1.10)."
-   **W-049**, `notes` appended: "SV-1 (YYYY-MM-DD): a `Core.CppCompat` sum type
    (and a non-pointer `Core.Optional(T)`) in an exported signature gives the
    existing `interop with non-identifier package name` TODO
    (fail_sum_types.carbon `fail_todo_export_sum_type`); the C++ class is the
    exportable spelling (fork/sumtype-interop/plan.md §1.5)."
-   **W-122**, `notes` appended: "SV-1 (YYYY-MM-DD): a conversion of a C++
    `std::optional`/`std::variant` to its sum type inside an `if`-expression
    arm registers C++ temporaries and yields a value whose representation is
    not a copy, so it gives this TODO (fail_sum_types.carbon
    `fail_todo_if_arm`)."
-   **W-252**, `notes` appended: "SV-1 (YYYY-MM-DD): a `match` on a
    template-dependent C++ sum value or `Core.CppCompat` sum type rides this
    item; on TP-1's head such a `match` on any `choice` stopped at
    pattern_match.cpp:1409 (fork/sumtype-interop/plan.md fold record, X-1;
    <filed as W-282 | fixed by TP-1 at <commit>>)."
-   **W-263** (TP-1's, filed on PR 61; appended only if it is on the merged
    trunk and open; added 2026-10-20, review fold: RR4-m1), `notes` appended:
    "SV-1 (YYYY-MM-DD): a constant tuple or struct holding a `Core.CppCompat`
    sum-type constant, such as `(Core.CppCompat.StdOptional(i32).None, 0)` in a
    `let` or `var` initializer, reaches this failure (lower.cpp:48), as a user
    generic `choice` constant in a tuple does without SV-1; `.Some(n)` and
    run-time elements lower (fork/sumtype-interop/plan.md §1.9, §1.11)."

### C.7 fork/gap-analysis.md: row 68 (commit R)

R composes over PR 56's row (379f20f67, fork/gap-analysis.md:70; the same text
at :75 on PR 57's head 628273444), which the merge order puts on trunk before
SV-1. R deletes nothing: the row's text stays verbatim, because it records what
was true when it was written, and R appends one dated sentence to the third
column. The status stays **PARTIAL** (§1.17). The sentence:

> SV-1 (YYYY-MM-DD, fork/sumtype-interop/plan.md, F-020) lands the interop
> half (W-011 DISCHARGED): a C++ `std::optional<T>` / `std::variant<Ts...>`
> keeps its C++ class and converts by value, through its accessors, to and
> from `Core.CppCompat.StdOptional(T)` / `StdVariant1..8` (alternatives
> `.Alt0`, `.Alt1`, ... by C++ index; `std::monostate` as `()`), and `match`,
> `if`-`let`, `while`-`let` and `let`-`else` consume it with exhaustiveness; a
> C++ `std::optional<T>` converts to and from `Core.Optional(T)` in one step
> for a non-pointer `T`; match_sum_type_payload un-SKIPped, 11 conformance
> programs PASS (the 5 above, match_sum_type_payload, match_std_optional_diff,
> match_std_variant_diff, match_core_optional_diff, cpp_sum_type_roundtrip_diff
> and cpp_sum_type_library, against C++ oracles); 0.1 limits, each diagnosed:
> class-type or non-trivial alternatives (W-275, SF-6), more than 8
> alternatives (W-276), qualified alternatives (W-277), template-deferred
> conversions (W-279), `ref` payload bindings (W-280), sum classes nested in
> tuple scrutinees (W-281), C++ `T&&` parameters (W-285)<, VA-1 pack elements
> (W-284)>, file scope (W-036). Still PARTIAL on W-177,
> narrowed: `Core.Optional(T)` is matched for a concrete scalar or pointer `T`
> only, by value; generic and aggregate payloads, `ref` bindings and copy-free
> matching stay open.

The `<...>` follows C.4's filing rule for W-284: kept, without the brackets,
once M-VA has landed (added 2026-10-20, review fold: RR4-m2, as for C.1; W-285
added 2026-10-20, review fold: RR4-M1).

Fallback: if the merged row's text differs from PR 56's, R keeps the merged
text verbatim and appends the same sentence. If W-177 is not on the merged
trunk (PR 56 not merged), the status becomes **DONE**, the sentence ends after
"file scope (W-036).", and the header moves by +1 DONE / -1 PARTIAL;
otherwise the header does not move. The evidence cell gains "SV-1:
container-built, <PASS>/<FAIL>/<SKIP> over <programs>, expected, not of record
(Actions disabled)".

### C.8 fork/decision-log.md (D; the F-015 paragraph at Doc-M)

Doc-M appends, after the merged trunk's OP-1 / F-015 entry's last paragraph:

> **F-015 amendment (YYYY-MM-DD, SV-1, F-020).** The `std::optional` mapping
> this design deferred to W-011 relates to `Core.Optional(T)`: a C++
> `std::optional<T>` converts to and from `Core.Optional(T)` in one implicit
> step for a non-pointer `T` (through `Core.CppCompat.StdOptional(T)` and two
> prelude `ImplicitAs` impls that use only the public API), a
> `Core.Optional(T)` argument is offered to C++ overload resolution as
> `std::optional<T>`, and a `Core.Optional(T)` scrutinee of a scalar or
> pointer `T` is matched as that choice by value. The class, its API, its
> storage, the `Try` impl and `Core.Optional(T*)`'s pointer mapping are
> unchanged; docs/design/optional.md is amended at the seven places
> fork/sumtype-interop/plan.md Appendix C.3 lists. W-177 stays open, narrowed.
> Veto-able with F-020.

D appends a new entry at the end of the log; its placeholders follow C.4's
filing rules: `<, W-284>` once M-VA has landed, `<, W-282>` under its condition,
`<, W-278>` and `<, W-283>` only if the shrink line's first and second steps are
taken, and `<W-278 withdrawn unfiled; >` and `<W-283 and >` only if they are not
(amended 2026-10-20, review fold: RR3-m1 / RR3-m2: rev 3 froze "W-278 withdrawn
unfiled; W-283 unused" and "W-284" into the text, which the shrink line or a
late M-VA would contradict); `<rev-5 commit>` is the hash of the plan's rev-5
commit (amended 2026-10-20, review fold: all RR4 findings):

> ### SV-1 / F-020: `std::optional` and `std::variant` interop mapping (YYYY-MM-DD)
>
> Gap row 68 ("Control flow: matching — sum-type consumption incl.
> std::variant/std::optional interop") stays PARTIAL on W-177 (narrowed); W-011
> is DISCHARGED: its arbiter, a Carbon match over an imported std::optional or
> std::variant, runs in match_sum_type_payload (un-SKIPped) and in four
> differential programs and a library program against C++ oracles. The
> expected conformance scoreboard is <PASS> / <FAIL> / <SKIP> over <programs>,
> <bullets>/56 bullets, container-built and not of record (Actions disabled,
> R9, R28). Landed on claude/carbon-fork-0-1-sv in the commits
> fork/sumtype-interop/plan.md §3 fixes: <C1> ... <D>, after the plan's
> 3287b1072 (rev 1), 4d85d14fe (rev 2, reviews A and B folded), 4eef66632
> (rev 3, the focused re-review of rev 2 folded), 66deca5ce (rev 4, the
> focused re-review of rev 3 folded) and <rev-5 commit> (rev 5, the focused
> re-review of rev 4 folded, signed off) <and any later revision>.
>
> **Veto digest** (R29(a), for the owner):
>
> -   **F-020** (minted here): a C++ `std::optional`/`std::variant` keeps its
>     class and maps by value to a specific of a prelude generic `choice` in
>     `Core.CppCompat` (`StdOptional(T)`, `StdVariant1..8`, `.Alt<i>` by
>     index). This **departs from SF-8's default lean** (the anonymous,
>     synthesized-choice mapping): the types are nameable, and a variant built
>     in Carbon or carried by a Carbon library API spells one, which is SF-8's
>     option (b) in substance. Justification: no `choice` exists without a
>     source declaration, a specific is one type across files and libraries
>     where an anonymous entity could not appear in a library signature, and
>     upstream's own sketch is a per-arity generic choice (p0157). It adopts
>     SF-9's option (b) cost, a second Optional beside the class, bounded by
>     the one-step conversions and the view. It amends F-015 (above). Break
>     condition: the owner's veto of nameable sum types (they then move to a
>     namespace user code cannot name), variadic choices, the `Match`
>     interface, a choice-based `Core.Optional`, or an upstream mapping.
> -   **D-SV-2**: alternatives named by C++ index; `std::monostate` is `()`;
>     1 to 8 alternatives; nesting by pointer only.
> -   **D-SV-3**: admitted = a trivially copyable and destructible class whose
>     alternatives are unqualified and SF-6 payloads; else
>     `CppSumTypeNotMapped` with a note.
> -   **D-SV-4**: conversion in `PerformBuiltinConversion` and the scrutinee
>     gate; a conversion a caller only tests (an `overload fn` probe, its
>     aggregate element conversions included, which `ConvertAggregateElement`
>     now marks non-diagnosing too) builds nothing and is decided from the
>     types alone, so a point where the conversion cannot be built (file
>     scope, a template's instantiation) is the call's TODO and never selects
>     another member; a template-dependent side is left to instantiation; a
>     pack element, or what a conversion projects from one, is a TODO<
>     (W-284)>.
> -   **D-SV-5**: Carbon to C++ only to the class whose sum type the value is
>     (`CppSumTypeReverseMismatch` otherwise); a fresh value passed to a C++
>     `T&&` parameter is a TODO (W-285).
> -   **D-SV-6**: the shared scrutinee gate converts; `ref` bindings (W-280)
>     and nested C++ classes (W-281) are not consumed.
> -   **D-SV-7**: the `Core.Optional` bridge, the one-step conversions, and
>     the view for concrete scalar and pointer payloads; W-177 narrowed.
> -   **D-SV-8**: `Core.Optional(T*)` admitted as a choice payload by name;
>     nothing else changes at the predicate's four sites.
> -   **D-SV-9**: a constant GEP into a value constant uses
>     `FileContext::GetConstant`'s cached global (fixes a lowering crash on
>     every constant choice scrutinee).
> -   **D-SV-10**: generics, libraries, constants and overload sets work;
>     deduction does not see through the conversion; template conversions are
>     W-279.
> -   **D-SV-11** to **D-SV-16**: eight diagnostic kinds; eight goldens and
>     one split; one un-SKIP and five programs; the sum_types.md section,
>     unions.md link and optional.md amendment; merge after PR 61; the row
>     rule (PARTIAL predicted on W-177).
>
> V-3 holds: no accepted proposal or leads' direction is contradicted
> (upstream has no `match` and no mapping, fork/sumtype-interop/plan.md §0.9).
> Two divergences are disclosed: the sum types are fork prelude names, and the
> view matches `Core.Optional` by copy. Filed: W-275, W-276, W-277, W-279,
> W-280, W-281, W-285<, W-284><, W-282><, W-278><, W-283>; <W-278 withdrawn
> unfiled; ><W-283 and >W-286 to W-294 unused.

### C.9 fork/ORCHESTRATION.md (D)

A Branches row after TP-1's:

> | `claude/carbon-fork-0-1-sv` | IMPLEMENTED, PR <n> — SV-1
> `std::optional`/`std::variant` interop mapping (W-011 discharged; gap row 68
> stays PARTIAL on W-177, narrowed), plan rev <n> signed off, head <head>;
> W-275..W-277, W-279..W-281 and W-285 filed<, W-284><, W-282><, W-278><,
> W-283>; <W-278 withdrawn, ><W-283 and >W-286..W-294 unused; F-020 minted; gate
> <passed>/<total> and conformance <PASS>/<FAIL>/<SKIP> over <programs> on the
> container toolchain. |

The placeholders follow C.8's rule (amended 2026-10-20, review fold: RR3-m1 /
RR3-m2; W-285 added 2026-10-20, review fold: RR4-M1). Held wording (while PR 51
to PR 61 are held): "IMPLEMENTED AND HELD, no PR — SV-1 ... at <head>; lands
after PR 61 by the land-time items in Next actions", and Next actions gains:
"SV-1 at land time (fork/sumtype-interop/plan.md §3 item 8): M over the trunk
that holds PR 51 to PR 61; M-VA (the pack-element rule and its split); F-M
(seven refills, predicted); Doc-M; R; the id re-scan; D with Appendix C's
texts."

## Review fold record (rev 2, 2026-10-20)

Reviews A and B of rev 1 (3287b1072) both returned REJECT: review A with 2
BLOCKERs, 4 MAJORs and 7 MINORs (ids A-B1, A-B2, A-M1 to A-M4, A-m1 to A-m7),
review B with 1 BLOCKER, 5 MAJORs and 11 MINORs (B-B-1, B-M-1 to B-M-5, B-m-1
to B-m-11): 30 findings. Every finding was reproduced in the fixer's scratch
`$X` before it was folded: a v3 rebuilt from `$P/proto/v3.diff` reproduces
every measured finding (`$X/runs/repro-v3.txt`), and v4 (§0.6) is measured on
the same probes (`$X/runs/repro-v4.txt`). All 30 are folded; none is rejected.
The marks "(amended 2026-10-20, review fold: ...)" in the text name them; the
date is the fold's (rev 1 is itself dated 2026-10-20).

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| A-B1, B-B-1: the conversion builds blocks inside the `overload fn` probe and ignores `diagnose` | BLOCKER | yes: a1, a1b, a1c, r02, r03, r05, r06 crash (`No terminator in block`); a2, r01, r04 spurious errors | folded: `diagnose` passed through; a non-diagnosing conversion decides from types, emits nothing, builds no block; overload golden; mutant M12 (measured red) | §1.4, §2.3 to §2.5, §1.12 `sum_type_overload.carbon`, §8 item 5, §7.1 R-8, §7.2 R-K |
| A-B2: a C++ converting constructor reaches the reverse conversion with no node; silent narrowing | BLOCKER | yes: a7, a10, a11 stop at control_flow.cpp:61 | folded: the reverse rule (only to the class whose sum type the value is, `CppSumTypeReverseMismatch`); no block builder ever sees a `None` node (a TODO, and `EmitArms` CHECKs); splits; mutant M13 (measured red) | §1.5, §1.4, §1.11, §2.4, §1.12 `fail_reverse_*`, §8 item 5 |
| A-M1: TP-1 composition is semantic | MAJOR | yes: v3 on tpv4-like build (review A's), and v4 on tpv4 (h1 to h3) | folded: template-dependent side returns `None`; instantiation-time conversion is W-279's TODO; tpv4 gated; h1's stop traced to TP-1 (X-1) | §1.10, §0.7, §1.16, §1.11, §8 item 6, §7.1 R-9 |
| A-M2, B-M-1: W-177 discharge over-claims | MAJOR | yes: a3, a4, a5, b2, p02-like x13, x12 | folded: view admitted for concrete SF-6 payloads only, `CoreOptionalNotMatchable` otherwise; W-177 stays OPEN, narrowed; row 68 predicted PARTIAL; CountSome made concrete | §1.7, §1.16, §1.17, §1.13, Appendix C.5, C.7 |
| A-M3: D-SV-8 widens the predicate, fourth site | MAJOR | yes: f1b runs, f2 runs, e6/f3 copy errors on v3 | folded: `Core.Optional(T*)` admitted by name; four sites listed; NullptrT and MaybeUnformed pinned; catching path shown unchanged (a6b) | §1.8, §2.8, §1.12, §4, mutant M15 |
| A-M4, B-m-10: the steer framing | MAJOR / MINOR | n/a (text) | folded: F-020 restated as a departure from SF-8's default lean, recorded for veto, with a break condition; SF-9(b)'s cost adopted; one-step conversions so `StdOptional` is not needed for optionals; F-015 amended; conditional loading considered (R-L) | §1.1, §1.7, §7.2 R-L, Appendix C.8 |
| A-m1: three of SV-1's goldens change on OP-2 | MINOR | yes: op2v4, 1951 of 1958, same three plus four | folded: F-M lists seven refills; the complete diff dry-run on every head | §0.7, §3 item 8, §8 item 6 |
| A-m2: valueless is reachable | MINOR | yes: a9 terminates through the fence | folded | §0.5, §1.4, §7.1 R-7 |
| A-m3: `std::optional<std::monostate>` | MINOR | yes: e4's two errors on v3 | folded: supported both ways; split | §1.2, §1.5, §2.4, §1.12 `monostate_payload` |
| A-m4, B-m-3: W-277's rationale | MINOR | yes: `tc.cpp`, g1 | folded: rationale corrected; admitting `const` rejected with a reason (R-M) | §1.3, §1.16, §7.2 R-M, Appendix C.4 |
| A-m5: tuple scrutinee with a C++ sum class | MINOR | yes: x10 | folded: OUT, W-281, split | §1.6, §1.11, §1.16 |
| A-m6: D-SV-9 duplicates the value-representation global | MINOR | yes (code read) | folded: routed through `FileContext::GetConstant`; r03, r05 run; golden refilled | §1.9, §2.9, §4 |
| A-m7: accuracy (cleanup, R-2, missing log line, `half`, w12) | MINOR | yes: x17 four errors; log line absent | folded: each text corrected; `half` computed; the cascade documented | §1.3, §7.1 R-2, §0.6, Appendix A, §1.10 |
| B-M-2: `ref` bindings unlisted, R-5 false | MAJOR | yes: b1, b2, x14 | folded: OUT row, W-280, two splits, R-5 rewritten, "what a user sees" | §1.6, §1.11, §1.1, §7.1 R-5 |
| B-M-3: no land-time texts | MAJOR | n/a | folded: Appendix C has every text; D's texts frozen by the plan reviews | Appendix C, §1.14, §3 |
| B-M-4: collisions omit kind.def and BUILD; dry run incomplete | MAJOR | yes: numstat; rev 1's diff lacked the hunks | folded: table regenerated; complete diff dry-run on five heads; check_samples.py after M and Doc-M | §0.7, §8 items 6 and 11 |
| B-M-5: C++ to `Core.Optional` missing, W-278's reason | MAJOR | yes: m20 on v3 | folded: one-step conversions both ways (non-pointer payloads); W-278 withdrawn | §1.7, §1.5, §1.11, §1.12 |
| B-m-1: `fail_todo_non_trivial` missing from §1.12 | MINOR | yes | folded | §1.12 |
| B-m-2: rule 1's rationale | MINOR | yes (control_flow.cpp:163-167) | folded | §1.3 |
| B-m-4: clang-tidy step | MINOR | yes | folded: compdb recipe, measured on v4 (no new finding) | §8 item 8 |
| B-m-5: R31 and R27 | MINOR | n/a | folded: §8 item 10; rev 2's own counts below | §8 item 10, this record |
| B-m-6: missing break conditions | MINOR | yes | folded: D-SV-10, D-SV-14 | §1.10, §1.14, §1.18 |
| B-m-7: re-scan scope | MINOR | yes | folded: refs/heads and worktree ledgers; re-run (82 refs, 15 worktrees) | §8 item 7, §1.16 |
| B-m-8: §6 nine versus ten | MINOR | yes | folded (erratum, rev 2 commit) | §6 |
| B-m-9: `NoReason` emits nothing | MINOR | yes (code read) | folded: `AlreadyDiagnosed` split from `NoReason`, which emits | §1.11, §2.3, §2.4 |
| B-m-11: mirrors are full builds | MINOR | n/a | folded: full builds, budget, cleanup | §8 item 6 |

**X-1, found by the fold** (not a review finding): a `match` on a
template-dependent `choice` value stops TP-1's head (e408ad4d6) at
pattern_match.cpp:1409, ``Alternative constant type differs from scrutinee
type``, with no C++ involved (`$X/probes/x/x19_tp_choice_match.carbon` on
`/home/user/carbon-build/carbon-tp`'s install), where trunk 0bdce60a5 gives
W-252's TODO. It is TP-1's: routed to TP-1's running re-review; SV-1 files it
as W-282 at D only if it is unfiled and still on the merged trunk (§1.16).

**R31 counts** (`$X/bin/r31.py`, outside code blocks): rev 1 had headings
{level 1: 1, level 2: 13, level 3: 61}, 76 bullets and 38 numbered items in
5108 lines; rev 2's counts and their differences are in the rev-2 commit
message. Every new heading is intentional (§0.6's text gains no heading; the
new ones are Appendix C's and this record's).

## Focused re-review fold record (rev 3, 2026-10-20)

The focused re-review of rev 2 (4d85d14fe) returned **REJECT**: two BLOCKERs
that it named B1 and B-1 (review A's A-B1 and review B's B-B-1, NOT RESOLVED),
one MAJOR (RR-M1) and three MINORs (RR-m1, RR-m2, RR-m3), with A-B2 RESOLVED.
This plan names the two BLOCKERs RR-B1 and RR-B-1, so that they cannot be
confused with the rev-2 ids. Every finding was reproduced before it was
folded, on a v4 rebuilt from `$X/final/src/` (`$Z/runs/probes-v4.txt`), on
trunk (`probes-trunk-rr.txt`) and on the reviewer's PR 59 composition rebuilt
from its `srcva` (vav4, `probes-vav4.txt`), and each fold is measured on v5
and its compositions (§0.6). All six are folded; none is rejected. The marks
"(amended 2026-10-20, review fold: RR-...)" name them. The date is the fold's,
as rev 2's marks are: the workflow's template dated the marks 2026-10-15, five
days before rev 2, and recording a later fold under an earlier date than the
revision it amends would misstate the record.

**The re-review, as returned** (its claims, abridged; its probes and logs are
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-rr/`,
`probes/` and `runs/`):

-   **Method.** Every §2 code block extracted, identical to `$X/final/src/`
    but for kind.def's relink-only position; two relinked prototypes, v4rr
    (the plan's code) and v4fx (with its proposed fix), deleted after use.
-   **Original counterexamples pass on v4rr**: a1 7, a1b 3, a1c 7, a2 2, r01
    to r06 2 7 7 1 4 7, c1 7 -1; a7, a10, a11, x04 and x05 give
    `CppSumTypeReverseMismatch`; the rev-2 fixer's x01 to x18 reproduce.
-   **B1 and B-1 stay open.** ``context.cpp:86 Built invalid semantics IR: No
    terminator in block`` fires on an `overload fn` member whose parameter is
    a tuple, struct or array holding a sum type (p06, q04, q05, q06, q07, q09,
    and p15 through deduction); the non-overloaded forms run (q01 8, q02 8,
    q03 -3, q08 5). The root cause is trunk's `ConvertAggregateElement`, which
    drops `diagnose` (convert.cpp:393): inside the probe the element
    conversion reaches the hook with `diagnose` true and builds blocks, and
    trunk shows the same drop without SV-1 (t01's spurious error). Rev 2's
    sentence "diagnose is false only for a conversion whose caller tests
    convertibility" is true, but the plan needs the converse. A measured fix:
    pass `diagnose` through `ConvertAggregateElement` and its four callers
    (v4fx: every aggregate probe runs, the original probes are unchanged, the
    trunk gate is v4rr's). The same parameters make a mismatching member a
    hard error (B-1).
-   **A-B2 is resolved**: the reverse rule acts inside
    `PerformBuiltinConversion` before C++'s converting constructors; no probe
    reached control_flow.cpp:61 and nothing narrowed silently.
-   **RR-M1 (MAJOR).** Composed with PR 59 (vav4), forwarding a pack of C++
    optionals to a pack of sum-type parameters (v02), and the reverse (v04),
    stop at VA-1's CHECK ``Control flow in a pack element conversion``; §0.7
    recorded PR 59 as textual only, checked by a dry run.
-   **RR-m1, RR-m2, RR-m3 (MINOR).** At file scope the probe accepts a member
    that the committed call rejects with a TODO (p05); R-8 and §1.4 said
    deduction discards the non-diagnosing results, which deduce.cpp keeps;
    the hook claimed a C++ sum class converted to the `Core.Optional` of that
    same class and reported a mismatch (k01 to k03).

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| RR-B1 (the re-review's B1): the `overload fn` probe still builds blocks for a tuple, struct or array parameter holding a sum type | BLOCKER | yes: p06, p15, q04 to q07 and q09 crash on v4 (`No terminator in block`), and the fixer's y02 (a struct, reverse direction); t01's spurious error on trunk and v4 | folded: `ConvertAggregateElement` passes `diagnose` to its elements (the reviewer's fix, as on v4fx); the rule is stated as "every conversion a probe performs, element conversions included, has `diagnose` false" in the summary, §1.4, §1.10, §1.18, §2.4, R-8 and R-K; eight splits in sum_type_overload.carbon; mutant M17 (measured red); t01's trunk change recorded | §1.4, §2.5, §2.4, §1.10, §1.12, §1.18, §4, §6, §7.1 R-8, §7.2 R-K, §8 items 3 and 5, Appendix B |
| RR-B-1 (the re-review's B-1): the conversion is still not probe-safe, and a mismatching aggregate member is a hard error | BLOCKER | yes: y01 gives `CppSumTypeMismatch` on v4 | folded with RR-B1 (same root cause and fix); split `tuple_mismatch_first`; y01 prints 8 on v5 | as RR-B1 |
| RR-M1: the PR 59 composition stops at VA-1's CHECK | MAJOR | yes: v02 and v04 on vav4 | folded: PR 59's row in §0.7 is semantic; the land-time hunk M-VA makes `CanBuildBranches` refuse a `SemIR::PackElement` with a TODO, chosen over turning VA-1's CHECK into a TODO because it fires before any block is built, where a TODO after VA-1's `Convert` returns would leave the conversion's blocks in the function; residue W-284 (W-283 is already the shrink line's conditional id); split `fail_todo_pack_element`, filled on vav5g; M19 measured red on vav5n; every relinkable composition gated (tpv5, op2v5, scv5, vav5g); §8.6 runs the PR 59 probes | §0.6, §0.7, §1.4, §1.11, §1.12, §1.16, §1.18, §3 item 8, §4, §6, §7.1 R-10, §8 items 5 to 7, Appendix B, C.4, C.8, C.9 |
| RR-m1: at file scope the probe accepts what the committed call rejects | MINOR | yes: p05 gives the file-scope TODO on v4 | folded: `CanBuildBranches`, called by the non-diagnosing path too (it also covers the no-source-expression case); split `file_scope`; p05 prints 2 on v5; M18 measured red | §1.4, §2.3, §2.4, §1.10, §1.12, §8 item 5 |
| RR-m2: deduction keeps non-diagnosing results | MINOR | yes (deduce.cpp:343-357 and :568-584 read) | folded: the invariant is restated (neither the stand-in nor the branched conversion is ever a constant, so deduction rejects both alike); R-8's falsifier is a branched conversion that yields a constant; "discarded" is kept for call.cpp and import.cpp:1316 only; the comments in sum_type.h and sum_type.cpp say the same | §1.4, §2.3, §2.4, §7.1 R-8 |
| RR-m3: the hook claims a C++ sum class converted to `Core.Optional` of that class | MINOR | yes: k01 to k03 give `CppSumTypeMismatch` on v4 | folded: a `Core.Optional` target whose payload is not matchable returns `None`; k01 to k03 give trunk's own error again on v5; the shape is listed in §1.11; no golden split, because it would pin trunk's TODO at a prelude line that PR 57 changes, and autoupdate files that prelude-located diagnostic under the preceding split (measured, then withdrawn) | §1.4, §1.11, §2.3, §2.4 |

**Verdict handling.** The re-review's verdict is REJECT, with B1 and B-1 open
on rev 2, so the Status line reads "rev 3 -- NOT signed off: B1, B-1" and this
revision has no Sign-off section; a re-review of rev 3 decides whether the
folds resolve them.

**R31 counts** (`$X/bin/r31.py`, outside code blocks): rev 2 had headings
{level 1: 1, level 2: 15, level 3: 72}, 119 bullets and 47 numbered items in
7269 lines; rev 3's counts and their differences are in the rev-3 commit
message. The one new heading is this record's.

### Re-review of rev 3, folded in rev 4 (2026-10-20)

The focused re-review of rev 3 (4eef66632) returned **REJECT**: one BLOCKER,
RR3-B1 (RR-M1 NOT RESOLVED), one MAJOR, RR3-M1, and four MINORs, RR3-m1 to
RR3-m4. It found RR-B1, RR-B-1, RR-m2 and RR-m3 RESOLVED, and RR-m1 RESOLVED
as stated, its fold being the cause of RR3-M1. Every finding about a
measurement was reproduced in the rev-4 fixer's scratch `$W` before it was
folded: rev 3's probe rule as mutant M20 (v6 with `$Z/final/src/`'s
sum_type.{h,cpp}, which is v5's code over the same trunk build), rev 3's
M-VA test as mutant M21 on the PR 59 composition (vav6r), trunk's spurious
error on the sum-free z01, and TP-1's round-10 head as tpv6; each fold is
measured on v6 and its compositions (§0.6). All six are folded; none is
rejected. The marks "(amended 2026-10-20, review fold: RR3-...)" name them.

**The re-review, as returned** (its claims, abridged; its probes and logs are
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-rr3/`,
`probes/` and `runs/`):

-   **Method.** The 14 §2 code blocks extracted and applied to a `git
    archive` of 5674fe88b: byte-identical to `$Z/final/src/` but for
    kind.def's relink-only position; the §3 item 8 block equal to
    `$Z/land/m-va-pack-element.diff` but for one whitespace-only context
    line; Appendix A and B equal to their sources. v5 relinked; the nine
    golden sources refilled to a fixpoint in three passes, byte-identical to
    `$Z/final/goldens-filled/`.
-   **B1 and B-1 RESOLVED** on SV-1's own head: p06 8, q04 8, q05 8, q06 5,
    q07 8, q09 7, p15 8, t01 2, y01 8, y02 6, y03 9 -1; the 120 probes of
    rA, rB, x, rr and y as on the fixer's v5, no crash. RR-m1 resolved as
    stated (p05 prints 2), RR-m2 resolved (deduce.cpp:343-357 and :568-584),
    RR-m3 resolved (k01 to k03 give trunk's own TODO).
-   **RR-M1 NOT RESOLVED (RR3-B1).** On vav5g (PR 59 with the §2 code and
    M-VA), v02 to v04 and n06 to n08 give the pack-element TODO, n09 runs,
    but n01 to n05, a pack whose element is a tuple, struct, array or class
    holding a sum type, stop at VA-1's CHECK (convert.cpp:587): the hook sees
    a `TupleAccess` or `StructAccess` of the `PackElement`. The vav5g gate
    (1964 of 1968) cannot see it, and M-VA lands after the implementation
    reviews.
-   **Probe-safety hunt on v5**: pointer, class-holding-sum, default
    argument and template-deduction members, 18 unusual alternative types,
    an imported overload set, user `ImplicitAs`/`As` impls and a VA-1
    variadic member: no crash, no spurious diagnostic. On TP-1's round-10
    head every template probe gives W-279's TODO, x19 compiles, and the gate
    is 1961 of 1965. The one real problem is MAJOR-1 (RR3-M1): the probe's
    `CanBuildBranches` test made f01 print 1 2 (member 1 inside a function,
    member 2 at file scope) and t7 print 1 2 on the TP-1 composition, and t4
    get ``no member of overload set `P` accepts this call`` instead of
    W-279's TODO.
-   **Gate, conformance, records.** Gate 1946 of 1950 (the four refills);
    conformance 134 / 0 / 21 over 155, every program as on v5; the
    `--self-test` passes once the README table is regenerated; R31 counts as
    the rev-3 commit message says; the id re-scan (83 refs, 15 worktree
    ledgers) finds no W-275 to W-299 and no F-020.
-   **Scope.** Row 68 PARTIAL, W-011 DISCHARGED, W-177 OPEN and narrowed,
    F-020's statement and break condition coherent; false were §1.11's
    pack-element row and W-284's text (aggregate packs), and the summary's
    "never a crash, never a silent wrong value". MINORs: W-284's filing
    commit inconsistent across §1.14, §3 item 10 and C.4 (RR3-m1); C.8 and
    C.9 hard-code W-278 and W-283 (RR3-m2); PR 61's round-10 head touches
    refutable_binding.cpp/.h and fixes X-1 (RR3-m3); the trunk change of
    passing `diagnose` has no sum-free golden (RR3-m4).

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| RR3-B1: RR-M1 not resolved: M-VA misses a pack element reached through an aggregate projection, so the land-time state crashes on valid programs | BLOCKER | yes: n01 to n05 stop at VA-1's CHECK (convert.cpp:587) on vav6r (v6 with rev 3's bare `PackElement` test), and the extended split stops there at `ForwardTuple` (mutant M21) | folded with the reviewer's measured option: `CanBuildBranches` takes the converted value and `IsPackElementOrProjection` walks it back through `TupleAccess`, `StructAccess`, `ArrayIndex`, `ClassElementAccess`, `AsCompatible`, `AcquireValue` and `ValueAsRef` to a `PackElement` (vav6g: n01 to n08, n13, n14, n16 to n21 and v02 to v04 give the TODO, n09, n10, v00, v01, v06 and v07 run, n15 and n22 get VA-1's own TODOs, no crash; gate 1964 of 1968, the four refills, with the extended split filled). The region option (VA-1's code marks the straight-line region) is recorded as the break condition: it is more general but edits VA-1's files and `Context` at land time. `fail_todo_pack_element` gains the tuple, struct, array and class forms in both directions (ten calls); M19 and M21 measured red; §1.4, §1.11, W-284, R-10 and the summary restated | §0.6, §0.7, §1.4, §1.11, §1.12, §1.16, §1.18, §3 item 8, §4, §6, §7.1 R-10, §8 items 5 and 6, Appendix B, C.4, C.8 |
| RR3-M1: the RR-m1 fold makes overload selection depend on where the conversion can be built | MAJOR | yes: f01 and t7 print 1 2 on m20 (rev 3's rule on trunk's build), and t4 gets ``no member of overload set `P` accepts this call`` there | folded with the reviewer's first option: the non-diagnosing path decides from the types alone and no longer calls `CanBuildBranches` (rev 2's behavior for the limits, rev 3's skip kept for genuine mismatches, y01), which loses its `diagnose` parameter; the committed call emits the TODO (f01 on v6: the file-scope TODO; t4 and t7 on v6 and tpv6: W-279's TODO under ``unable to monomorphize specific``); `file_scope` becomes `fail_todo_file_scope`, `fail_todo_template_overload` added (it passes unchanged on tpv6 and vav6g); M18 retired, M20 measured red on both splits | Summary, §1.4, §1.10, §1.11, §1.12, §1.18, §2.3, §2.4, §4, §8 item 5, Appendix B, C.4 (W-279), C.6 (W-036), C.8 |
| RR3-m1: the commit that files W-284 is inconsistent across sections | MINOR | yes (text): §1.14 and §3 item 10 omitted W-284; C.4 said "with M-VA" | folded: W-284 is filed at D once M-VA has landed and held until then, in §1.14, §1.16, §3 items 8 and 10 and C.4's header; C.6, C.8 and C.9 put it behind a placeholder | §1.14, §1.16, §3 items 8 and 10, C.4, C.6, C.8, C.9 |
| RR3-m2: C.8 and C.9 hard-code "W-278 withdrawn unfiled; W-283 unused" | MINOR | yes (text) | folded: W-278, W-283 and W-284 behind placeholders, with C.8's rule for filling them | C.6, C.8, C.9 |
| RR3-m3: PR 61 has moved: TP-1's round-10 fix touches refutable_binding.cpp/.h and fixes X-1 | MINOR | yes: numstat on eafca5cb9 (refutable_binding.cpp +18/-5, refutable_binding.h +17, handle_match.cpp +2/-5); the dry run on 74e16c4de applies refutable_binding.cpp's first hunk with fuzz 1; tpv6 (relinked over a snapshot of the carbon-tp build) passes 1961 of 1965; x19 prints 0, h1 to h3, t2, t4 to t7 and x20 give W-279's TODO | folded: §0.7's PR 61 row, §1.11's last row, R-9 and W-282's condition updated (W-282 predicted unused); at M the row is re-measured against PR 61's head of that day (§8 item 6) | §0.7, §1.10, §1.11, §1.16, §7.1 R-9, §8 item 6 |
| RR3-m4: the trunk behavior change from passing `diagnose` through `ConvertAggregateElement` has no golden | MINOR | yes: z01 (t01's members with a `bool` second return) gives trunk's ``cannot implicitly convert expression of type `bool` to `i32` `` on trunk and on m17, and prints 2 on v6 | folded: split `scalar_tuple_mismatch_first` in sum_type_overload.carbon, no sum type, whose second member returns `bool` so the call's type pins the member; it fails on M17 without the sum-type splits | §1.12, §4, §8 item 5, Appendix B |

**Verdict handling.** The re-review's verdict is REJECT, on RR3-B1, so the
Status line reads "rev 4 -- NOT signed off: RR3-B1" and this revision has no
Sign-off section; a re-review of rev 4 decides whether the folds resolve it.

**R31 counts** (`$X/bin/r31.py`, outside code blocks): rev 3 had headings
{level 1: 1, level 2: 16, level 3: 72}, 139 bullets and 47 numbered items in
7987 lines; rev 4's counts and their differences are in the rev-4 commit
message. The one new heading is this subsection's.

### Re-review of rev 4, folded in rev 5 (2026-10-20)

The focused re-review of rev 4 (66deca5ce) returned **APPROVE-WITH-AMENDMENTS**:
every earlier BLOCKER RESOLVED (RR-B1, RR-B-1, and RR3-B1, which carried RR-M1),
RR3-M1, RR-m1 to RR-m3 and RR3-m1 to RR3-m4 RESOLVED (RR3-m3 with one stale
fact), no new BLOCKER, one MAJOR (RR4-M1) and three MINORs (RR4-m1 to RR4-m3).
Every finding about a measurement was reproduced in the rev-5 fixer's scratch
`$Y` before it was folded, on v6 rebuilt from `$W/final/final.diff` and on trunk
(§0.6), and each fold is measured on v6 and its compositions. All four are
folded; none is rejected. The marks "(amended 2026-10-20, review fold: RR4-...)"
name them.

**The re-review, as returned** (its claims, abridged; its probes and logs are
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-rr4/`,
`probes/` and `runs/`):

-   **Method.** The 14 §2 code blocks applied to a `git archive` of 5674fe88b
    with no fuzz, byte-identical to `$W/final/src/` but for kind.def's
    relink-only position; the §3 item 8 block equal to
    `$W/land/m-va-pack-element.diff` but for two whitespace-only context lines;
    the 12 Appendix A and 9 Appendix B blocks equal to their sources; v6
    relinked over trunk's objects.
-   **Every open item RESOLVED.** p06 8, q04 8, q05 8, q06 5, q07 8, q09 7, p15
    8, t01 2, y01 8, y02 6, y03 9 -1, and the 169 lines of the rA, rB, x, rr, y,
    z, f and h sets as `$W`'s `probes-v6.txt`; on vav6 (PR 59's b0822a744 with
    the §2 code and M-VA) v02 to v04, n01 to n08, n13, n14 and n16 to n21 give
    the pack-element TODO, n15, n22 and v05 VA-1's own TODOs, v00, v01, v06,
    v07, n09 and n10 run, 12 new pack probes do not crash, and mutant M21
    rebuilt turns the split red; f01 and p05 give the file-scope TODO, t4 and t7
    W-279's, and mutant M20 rebuilt prints 1 2; deduce.cpp:343-347 and :568-582
    as RR-m2's fold says; k01 to k05 as RR-m3's; W-284's filing and placeholders
    consistent.
-   **Probe-safety hunt**: about 110 new probes on v6, tpv6 and vav6, with no
    crash or spurious error caused by SV-1; four crashes that trunk shares (a C
    variadic call with extra arguments at overload_resolution.cpp:229, an
    interface method impl with an adapted return type, a `const` C++ class
    parameter, and W-263's constant nested aggregates, the last graded RR4-m1).
-   **Gate, compositions, conformance, consistency.** v6 1946 of 1950, the four
    function-pointer goldens; scv6 1963 of 1967, op2v6 1951 of 1958, tpv6 over
    74e16c4de's tree 1961 of 1965 and vav6 1964 of 1968; conformance 134 / 0 /
    21 over 155, every status as `$W`'s; R31 counts as rev 4's commit message
    says, all 47 code blocks inside markers; the cited lines accurate; no id of
    SV-1's block filed anywhere, W-295 TP-1's, F-020 unused.
-   **Scope.** Row 68 PARTIAL on W-177, W-011 DISCHARGED and W-177 OPEN and
    narrowed: honest. Every OUT shape is diagnosed, but some are not listed:
    rvalue-reference parameters (RR4-M1), and parameter default values and, in
    the user docs, the pack limit (RR4-m2).

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| RR4-M1: a sum value or `Core.Optional` passed to a C++ rvalue-reference parameter hits the no-source-expression TODO, which rev 4 said no program reaches | MAJOR | yes: r2 to r5 and y02 give the TODO at the C++ parameter on v6, with r1 7 and w14 6 8 -1; the fixer's sweep (`$Y/probes/rx/`, `rt/`) adds the `T&&` member C++ prefers to a `const T&` sibling (x07, x09, x19) and `std::vector::push_back` (x13), and shows that `const&&` converts (x01), that a value selects `const&` (x10, x14, x16, x18), and that a lone `T&&` refuses a value as trunk refuses a value of the C++ class (x02 to x06, x11, x12; t1, t2) | folded with the reviewer's second option, recorded as OUT: §1.4's sentence corrected; a §1.5 paragraph and Exportability row, and the IN row widened to `const&&`; §1.11's row rewritten and §1.1's user-facing list amended; the shape filed as W-285 under row 68's bullet, not bounding (the row's arbiter is consumption by `match`, and a value argument reaches a `const T&` member), and W-279 narrowed to the template form, its "every non-template form converts" withdrawn; C.1, C.6, C.7, C.8 and C.9 list W-285; split `fail_todo_rvalue_ref_param` with a `sink.h`, filled by autoupdate on v6 and passing on every composition; the reviewer's first option is mutant M22 and W-285's removal: tried on v6s, it runs the sum-type forms and turns the split red, but it changes the reviewed toolchain after the last review and leaves the `Core.Optional` form, whose bridged value has no node, so it is not adopted now | Summary, §0.6, §1.1, §1.4, §1.5, §1.11, §1.12, §1.14, §1.16, §1.18, §3 item 10, §4, §7.2 R-K, §8 items 5 and 6, Appendix B, C.1, C.4, C.6 to C.9, hand-off notes |
| RR4-m1: a constant tuple holding a sum-type constant stops lowering (W-263's trunk failure) and is not recorded | MINOR | yes: z1, z7 and y11 stop v6 at lower.cpp:48; z5, z8 and z9 stop trunk there; z2 prints 3 and y12 to y14 run; the same on every composition | folded: W-263 rides (§1.16; a C.6 note appended at D only if W-263 is on the merged trunk and open); a trunk-owned row in §1.11; D-SV-9's and the constants bullet's scope stated; the Summary's no-crash claim bounded by it; no golden or program uses the shape (hand-off notes) | Summary, §1.9, §1.10, §1.11, §1.14, §1.16, §3 item 10, C.6, hand-off notes |
| RR4-m2: parameter default values, and in the user docs the pack-element limit, missing from the lists | MINOR | yes: w03 and w35 give the outside-a-function-body TODO on v6; C.1 had no pack line (text) | folded with the reviewer's first option for (a): a parameter's default value named in §1.10, §1.11's row, W-036's note (§1.16, C.6) and C.1's W-036 line, the TODO's text unchanged; for (b), C.1 gains a `<...>` pack-element line that Doc omits and M-VA writes (§3 items 5 and 8, Appendix C's header), and C.7 the same placeholder by C.4's rule | §1.10, §1.11, §1.16, §3 items 5 and 8, C.1, C.6, C.7, hand-off notes |
| RR4-m3: PR 61's facts stale at rev 4's commit | MINOR | yes: 3d88e6a60 (pushed 21:55) contains eafca5cb9 and 74e16c4de, 74e16c4de..3d88e6a60 changes no toolchain/ or core/ file, and its ledger has W-295; since then PR 61 moved to 281292d8f (23:24, records only, W-295 to W-297) | folded: §0.7's PR 61 row at 281292d8f, pushed and toolchain-identical to the measured trees; tpv6 rebuilt over 281292d8f's tree (1961 of 1965, every hunk as on 74e16c4de); §1.16's and §8 item 7's re-scan sentences corrected and re-run (83 refs, 15 worktree ledgers: no id of SV-1's block; W-295 to W-297 on TP-1's pushed branch) | §0.0, §0.6, §0.7, §1.16, §8 items 6 and 7 |

**Verdict handling.** The re-review's verdict is APPROVE-WITH-AMENDMENTS, and
rev 5 folds every amendment it asks for, so the Status line reads "rev 5,
2026-10-20 -- SIGNED OFF FOR IMPLEMENTATION" and the [sign-off](#sign-off)
follows this record. The folds change no toolchain file: the prototype the
reviews measured, `$W/final/final.diff`, is the implementation's start, and the
golden and record texts above are what rev 5 adds.

**R31 counts** (`$Y/bin/r31.py`, outside code blocks): rev 4 had headings
{level 1: 1, level 2: 16, level 3: 73}, 158 bullets, 47 numbered items, 196
table rows and 23 indented table rows in 8479 lines, and 47 code blocks, all
between markers; rev 5's counts and their differences are in the rev-5 commit
message. The new headings are this subsection's and the sign-off's.

## Sign-off

Rev 5 (2026-10-20) is SIGNED OFF FOR IMPLEMENTATION: the focused re-review of
rev 4 returned APPROVE-WITH-AMENDMENTS, and rev 5 folds its four findings with
no change to the measured toolchain (added 2026-10-20, review fold: all RR4
findings). Every review of this plan:

| Review | Of | Verdict | Findings | Folded in |
| --- | --- | --- | --- | --- |
| Plan review A (R29(c)) | rev 1, 3287b1072 | REJECT | 13: 2 BLOCKER, 4 MAJOR, 7 MINOR (A-B1, A-B2, A-M1 to A-M4, A-m1 to A-m7) | rev 2, 4d85d14fe |
| Plan review B (R29(c)) | rev 1, 3287b1072 | REJECT | 17: 1 BLOCKER, 5 MAJOR, 11 MINOR (B-B-1, B-M-1 to B-M-5, B-m-1 to B-m-11) | rev 2, 4d85d14fe |
| Focused re-review of rev 2 | rev 2, 4d85d14fe | REJECT | 6: 2 BLOCKER, 1 MAJOR, 3 MINOR (RR-B1, RR-B-1, RR-M1, RR-m1 to RR-m3) | rev 3, 4eef66632 |
| Focused re-review of rev 3 | rev 3, 4eef66632 | REJECT | 6: 1 BLOCKER, 1 MAJOR, 4 MINOR (RR3-B1, RR3-M1, RR3-m1 to RR3-m4) | rev 4, 66deca5ce |
| Focused re-review of rev 4 | rev 4, 66deca5ce | APPROVE-WITH-AMENDMENTS | 4: 1 MAJOR, 3 MINOR (RR4-M1, RR4-m1 to RR4-m3) | rev 5, this revision |

In all, five reviews and 46 findings (6 BLOCKER, 12 MAJOR, 28 MINOR), every one
checked before it was folded (reproduced where it is about a measurement) and
none rejected; the folds are listed in the
[review fold record](#review-fold-record-rev-2-2026-10-20) and the [focused
re-review fold record](#focused-re-review-fold-record-rev-3-2026-10-20). What
stays open is filed (§1.16) or is a land-time step (§3 item 8); the
implementation reviews of §3 item 6 judge the implementation against this
revision.

## Revision record

-   Rev 1 (2026-10-20): first revision, for the two plan reviews of R29(c).
    The prototype was first drafted on 2026-10-15 and rebuilt, extended (v2,
    v3) and re-measured for this revision; every number above is from
    2026-10-20 unless marked.
-   Rev 2 (2026-10-20): reviews A and B (both REJECT, 30 findings) folded; no
    finding rejected (the
    [review fold record](#review-fold-record-rev-2-2026-10-20)). The
    prototype v4 (§0.6) replaces v3 and emits the final diagnostics; §2 is
    regenerated from it; Appendix C holds every land-time text; F-020 is
    restated as a departure from SF-8's default lean, recorded for veto; the
    row-68 prediction moves from DONE to PARTIAL (W-177 narrowed, not
    discharged); W-278 is withdrawn and W-279 to W-281 join the planned
    filings (W-282 conditional). §6's "nine changed" files are ten
    (erratum). Every number is from 2026-10-20 unless marked.
-   Rev 3 (2026-10-20): the focused re-review of rev 2 (REJECT: B1, B-1,
    RR-M1, RR-m1 to RR-m3) folded, none rejected (the
    [focused re-review fold record](#focused-re-review-fold-record-rev-3-2026-10-20)).
    The prototype v5 (§0.6) replaces v4: `ConvertAggregateElement` passes
    `diagnose` to its elements, the non-diagnosing path accepts only what
    `CanBuildBranches` allows, and a `Core.Optional` target whose payload is
    not matchable is no longer the hook's; §2.3 to §2.5 are regenerated from
    it; the land-time hunk M-VA, its split and W-284 answer the PR 59
    composition; the compositions with PR 57, PR 59, PR 60 and PR 61 are
    relinked and gated. Not signed off: the Status line names the open
    BLOCKERs, pending a re-review of rev 3.
-   Rev 4 (2026-10-20): the focused re-review of rev 3 (REJECT: RR3-B1,
    RR3-M1, RR3-m1 to RR3-m4) folded, none rejected (the
    [re-review of rev 3](#re-review-of-rev-3-folded-in-rev-4-2026-10-20)).
    The prototype v6 (§0.6) replaces v5: the non-diagnosing path decides
    from the types alone, so a toolchain limit is the call's TODO and never
    selects another `overload fn` member; the land-time hunk M-VA walks a
    converted value back through a conversion's projections to a pack
    element; sum_type_overload.carbon gains `scalar_tuple_mismatch_first`
    and `fail_todo_template_overload` and renames `file_scope`, and the
    M-VA split gains the aggregate pack forms; §2.3, §2.4 and §3 item 8 are
    regenerated from it; W-284's filing and the land-time placeholders are
    made consistent; TP-1's round-10 head is measured (tpv6). Not signed
    off: the Status line names RR3-B1, pending a re-review of rev 4.
-   Rev 5 (2026-10-20): the focused re-review of rev 4 (APPROVE-WITH-AMENDMENTS:
    RR4-M1, RR4-m1 to RR4-m3) folded, none rejected (the
    [re-review of rev 4](#re-review-of-rev-4-folded-in-rev-5-2026-10-20)). No
    toolchain change: a sum value passed to a C++ `T&&` parameter is recorded
    as OUT and filed as W-285 (W-279 narrowed to the template form), pinned by
    fail_sum_types.carbon's new `fail_todo_rvalue_ref_param` split and by mutant
    M22; W-263 rides for a constant tuple or struct holding a sum-type constant;
    parameter default values and the user page's pack-element line are listed;
    PR 61's facts are brought to its pushed head 281292d8f and every composition
    is gated again. SIGNED OFF FOR IMPLEMENTATION (the [sign-off](#sign-off)).
