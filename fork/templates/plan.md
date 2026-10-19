# Integrated templates plan: crashes, dependent forms, splice lowering (TP-1)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 3, 2026-10-14 -- SIGNED OFF FOR IMPLEMENTATION

Implemented on the branch and held (§1.12): the implementation commits, the
programs, the records-only merge of trunk and the state-T measurements are
recorded in §3 and §8, and the two implementation reviews are folded by the
fix commits that the
[implementation review fold record](#implementation-review-fold-record-2026-10-14)
tables (amended 2026-10-14, implementation-review fold: IR2-MINOR-10).

The row commit R (35e2240b5) and the discharge commit D follow the fold; the
[landed notes](#landed-notes-tp-1-2026-10-14) record them, the runs measured at
D and every land-time item (amended 2026-10-14, records: R and D).

The focused re-review of the fold (round 1: REJECT and APPROVE-WITH-FIXES from
two reviews of 7c7b1b170..bf8e1b4cc, fourteen findings, RR1-M1 and RR2-M1 one
finding) is folded by the re-review fix commits that the
[focused re-review fold record](#focused-re-review-of-the-fold-2026-10-15)
tables, with four residues filed, W-267 to W-270 (amended 2026-10-15, focused
re-review of the fold: all findings). Neither review of round 1 judged the
branch dry and its fixer changed the toolchain, so round 2 is owed, over the
fixer's commits 632f92117..c874c270f and the records commit that records
round 1; the PR opens and is held after a dry round (amended 2026-10-15,
records: re-review round 1).

Round 2 (two APPROVE-WITH-FIXES reviews of 632f92117..764e55445, seven
findings, three of them MAJOR) is folded by the fix commits
2165322c5..24bf5ea45 and the records commit bdc1f62d7, which the same record
tables, with one residue filed, W-271, a crash that trunk and the nightly
share (amended 2026-10-15, focused re-review of the fold: all round-2
findings). Neither review judged the branch dry, and the round's fixer changed
five toolchain source files, four goldens and one program, so round 3 is owed,
over the round-2 fixer's commits 2165322c5..bdc1f62d7 and the records commit
after them that records round 2's reviews; the PR opens and is held after a
dry round (amended 2026-10-15, records: re-review round 2).

Round 3 (two APPROVE-WITH-FIXES reviews of 2165322c5..aa57bfe1c, four findings,
three distinct: one MAJOR, which both reviews found, and two MINOR, records
only) is folded by the fix commits 68102438e..e7dc20a43 and the records commit
after them, which the same record tables, with no residue filed (amended
2026-10-15, focused re-review of the fold: all round-3 findings). Neither review
judged the branch dry, and the round's fixer changed two toolchain source files
and one golden, so round 4 is owed, over the round-3 fixer's commits
68102438e..e7dc20a43 and the records commit after them; the PR opens and is held
after a dry round.

Rev 1 (6245f8687) was the planner's draft. Reviews A (architecture and design
fidelity) and B (concreteness, process and cross-workstream) of rev 1 were
folded into rev 2 (1b26e8c32) by a separate fixer (R11): 27 findings, none
rejected whole, each changed passage marked "(amended 2026-10-14, review fold:
A-n / B-n)". The focused re-review of rev 2 that R29(c) requires returned
APPROVE-WITH-AMENDMENTS with six findings, two MAJOR and four MINOR, which a
second fixer folded into rev 3, each changed passage marked "(amended
2026-10-14, review fold: RR-n)". The
[review fold record](#review-fold-record-rev-2-2026-10-14) lists every finding
with its disposition and the sections it changed, and
[Sign-off](#sign-off) lists the three reviews. Branch
`claude/carbon-fork-0-1-tp`, worktree
`/home/user/carbon-tp`, cut from trunk b2576f6c3, whose `toolchain/` and
`core/` trees equal the upstream cut as built into the fork toolchain
0bdce60a5 (upstream base c1e83b0b7; trunk differs from 0bdce60a5 by fork
records only; trunk has since moved to 8bfd78ae3, records only). Every line
number below is against b2576f6c3 unless a branch or commit is named. Nothing
below is implemented on this branch at rev 3; the prototypes that §2 quotes
exist only as patches in scratch directories, measured by relinking the trunk
build's objects with the patched translation units.

**Scratch and measurement environment.** `$P` is the planner's scratch,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1/planner`
(rev 1's measurements), and `$X` the fixer's,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1-fixer`
(rev 2's; amended 2026-10-14, review fold: A-B1 / B-m6), and `$Y` the second
fixer's,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1/fixer2`
(rev 3's; amended 2026-10-14, review fold: RR-M1 / RR-M2). The baseline of every
measurement is the trunk toolchain
`/home/user/carbon-build/carbon-trunk/install/bin/carbon` (`carbon version`
`0.0.0-0.dev+0bdce60a5`) and its `file_test` with the trunk runfiles; the
differential oracle is the upstream nightly
`/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon`
(`0.0.0-0.nightly.2026.10.12+62f1cc6`). Prototypes were compiled with the trunk
build's own compile line (the `cxx`/`cflags` of
`/home/user/carbon-build/carbon-trunk/build.ninja`) for the patched translation
units only, linked into `carbon-busybox` and `file_test` under
`/dev/shm/tp1-planner/<variant>/` (rev 1, script `$P/bin/relink.sh`) or
`/dev/shm/tp1-fixer/<variant>/` (rev 2, `$X/bin/relink.sh`; `$X/bin/relinkb.sh`
takes another worktree's build directory, for the compositions of §0.9) or
`/dev/shm/tp1-fixer2/<variant>/` (rev 3, `$Y/bin/relink.sh`, which rebuilt v13
from `$X/v13.diff` and built v14 and the measurement-only variants g and m20),
and deleted when no longer needed. Where a prototype changed a header, every
translation unit that uses the changed declaration was recompiled with the
patched header first on the include path (`sem_ir/expr_info.h`: its callers in
convert.cpp, formatter.cpp and the three lowering files; `check/pending_block.h`
gains two inline members that only convert.cpp calls); a change to an X-macro
list (`sem_ir/inst_kind.def`, `diagnostics/kind.def`) cannot be relinked and is
hand-predicted in §2 and Appendix D with the code path quoted. No full toolchain
was built, nothing under `/home/user/carbon-build` was written, no other
worktree was touched (read-only `git show`, `git diff` and `git archive` only),
and the owner's runner was not used (R28). Probe sources are under `$P/probes`,
`$P/runs`, `$P/sweep`, `$P/iso`, `$P/forms`, `$P/xlib` and `$P/progs` (rev 1),
review A's under
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1-reviewA/p`
(copied to `$X/probes/ra`), and rev 2's own under `$X/probes/new` and
`$X/probes/fixed`; `$X/matrix-table.tsv` holds every probe's outcome on trunk,
the nightly and the rev 2 prototype side by side. The re-review's probes
(`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1-rr/probes/n`)
are copied to `$Y/probes/rr`, rev 3's own are under `$Y/probes/v14` and
`$Y/probes/rc10`, and `$Y/mx/v13/v13.txt` and `$Y/mx/v14/v14.txt` hold every
probe's outcome on v13 and v14 (amended 2026-10-14, review fold: RR-M1 / RR-M2).
`$F` is the focused re-review fixer's scratch,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1-rr/fixer-r1`,
and the two re-reviews' probes are under
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1-rr/rev1-r1/probes`
and `.../tp1-rr/rev2-r1/p` (amended 2026-10-15, focused re-review of the fold:
all findings).

**Items.** W-014, "W7: integrated templates -- template lowering (SpliceInst)
plus dependent-form conversions, operators, and pattern splices"
(fork/inventory/work-items.json; kind todo-stub, size L), with the three
DD-1 residues filed under the same gap row on PR 58 (W-183 constraint lookup,
W-192 struct copy and array index, W-193 deduction through a class's
arguments) and UA-2's W-127 (an uninitialized `var y: T;`, filed on PR 51),
which the measured defect list of DD-1 cites as X20 and X23. **Milestone row:**
"Generics: Integrated templates" (fork/gap-analysis.md:54 on trunk, :59 or :60
on the held branches; records name it by its bullet text, R7), PARTIAL.
**Arbiter of record** (W-014's notes): every `fail_todo` split under
toolchain/check/testdata/generic/template/ flips, the lowering fatal is gone,
and a template function executes in the run harness.

**Outcome this plan commits to** (amended 2026-10-14, review fold: A-B1 / A-M2 /
A-M3 / B-M2 / A-m2 / A-m3). (a) Every compiler crash and the miscompile on
template-dependent forms that DD-1 pinned (X28 to X33, probe PR-AK), the ones
rev 1's sweep found (§0.6), the ones review A found (nested aggregates built
from template calls: b09, b09b, b09e, c1, c3, c4, c5; the struct conversion
e01), and the ones the re-review found (a class value built from a struct
literal that holds a template call: r2, r4, r8, r9; amended 2026-10-14, review
fold: RR-M1), and a constant element beside a template-dependent one, such as
the `1` of `return (x, 1);`, which the first implementation review found
stopping lowering (D-TP-25; (amended 2026-10-14, implementation-review fold:
IR1-B1)), become correct implementations, each with its root cause fixed where
it arises (§0.3, §1.2). Four forms remain, each measured, filed under this
bullet and named in the row residue and on the page (amended 2026-10-14, review
fold: RR-M1 / RR-M2): a struct with one field or a tuple with one element,
initialized by copy, whose element is an aggregate initialized in place, which
stops the compiler (s32, returning `{.a = x}` for `{.a: (i32, i32)}`) or is
compiled wrongly (q07c, returning `{.a = {.b = (x, x)}, .c = x}`, whose values
change from run to run) exactly as the same code without a template parameter
does (W-256, RC-10); a `for` loop over a template-dependent range whose cursor
is initialized in place, a tuple or a class (W-264, the toolchain's own ordering
TODO at handle_loop_statement.cpp:216-218); a constant nested aggregate, which
fails LLVM verification with or without a template and which template copies now
reach (W-263); and lowering a form-parameter pattern splice, `template` or
`generic` (W-255). A class value from a struct literal that leaves a field to
its default initializer also still stops the compiler (W-264's second form), and
so does the same code without a template parameter, for any runtime class value
with a defaulted field (W-265). A template used from another library becomes a
`semantics TODO` at the `import` (W-250), whether the dependent operation is in
its definition or in its declaration (D-TP-14; (amended 2026-10-14,
implementation-review fold: IR1-M2)), a class template's field types and member
function declarations and an interface's or named constraint's declaration
included ((amended 2026-10-15, focused re-review of the fold: RR1-M1 / RR2-M1)),
and so does an entity whose declaration, definition or bindings name such an
entity, such as a nested generic class or a deduced parameter constrained by
such an interface ((amended 2026-10-15, focused re-review of the fold:
RR2r2-M1)). A runtime value used as a type, such as `x.0` for a template's
runtime parameter `x`, is an error at that operand on instantiation (D-TP-26;
(amended 2026-10-15, focused re-review of the fold: RR1-B1)). Five behaviors
that the focused re-review of the fold measured, each the same on trunk, are
filed under this bullet: the temporaries that a template's actions create on
instantiation are never destroyed (W-267); `var e: T.Elem;` is rejected where
the function is defined (W-268); `return {} as T;` for a class without `Copy` is
rejected on instantiation (W-269); and an interface or named constraint whose
later parameter's type depends on a template parameter stops the compiler in its
own library when it is used (W-270); and, measured by its round 2, a generic
class from another library that declares a nested class or interface stops the
compiler where the class is used, with or without a template parameter (W-271;
(amended 2026-10-15, focused re-review of the fold: RR2r2-M1)). (b) The
dependent forms of proposal 2200's "Use of dependent value is dependent" that
trunk rejects where the function is defined -- `*`, `->`, `&`, tuple element
access, calls of a value whose type is a template parameter, struct copies and
array indexing -- are deferred to instantiation through the existing action
machinery (§1.3). (c) SpliceInst lowering, which upstream PR 7727 landed before
the cut, is completed for the cases it mishandles (a splice of an in-place
initializer, categories and constants read in the generic instead of the
specific; §1.4). (d) Proposal 2200's name lookup into a constrained template
parameter is implemented on instantiation (W-183, with the different-entities
error, for an operand whose type in the definition is the parameter; an access
through a field whose declared type is the parameter is W-266, (amended
2026-10-14, implementation-review fold: IR1-M3)), deduction through a class's
arguments (W-193), with a class template's literal whose array field has a
template-dependent bound converted on instantiation, as it was on trunk, where
`C(N)` was a deferred call ((amended 2026-10-15, focused re-review of the fold:
RR2-1-M2)), and W-127's deferred impl lookup (§1.5 to §1.7); the definition-time
half of proposal 2200's simple member access and the type-level `T.F` are not
(TR-8 is PARTIAL, W-260 to W-262). (e) All four `fail_todo` splits under
generic/template/ flip: three by the dependent forms, and
`member_out_of_line.carbon` `fail_todo_basic` because the redeclaration it
rejects does differ (p3763) and only its diagnostic text was wrong, which C2
fixes (D-TP-23); W-014's first arbiter clause is met for the four `fail_todo`
splits present when W-014 was filed, and TP-1's own twenty-eight `fail_todo`
splits pin its residues (fail_todo_import.carbon's twenty-seven, W-250's gap
behind the second clause, and constraint_lookup.carbon's
`fail_todo_field_of_template_class`, W-266; (amended 2026-10-14,
implementation-review fold: IR2-MINOR-6); the focused re-review of the fold
added five of the twenty-seven in round 1, seven in round 2 and eleven in
round 3, (amended 2026-10-15, focused re-review of the fold: RR1-M1 / RR2-M1
/ RR2r2-M1 / RR3-1-M1)); its second is not
(the cross-file lowering fatal stays in the code behind the `semantics TODO`),
and generic/template/operator.carbon's two `todo_fail` pins stay (W-259), so the
row stays PARTIAL and W-014 stays OPEN (D-TP-18). (f) Nine conformance programs,
one with a C++ differential oracle, join the bullet (the ninth,
templates_constant_elements, from the implementation-review fold; (amended
2026-10-14, implementation-review fold: IR1-B1)). (g) The land-time integration
with PR 58 amends templates.md with dated notes, flips DD-1's fixtures and adds
three, with texts this plan gives in full and a measured run of PR 58's checker
(Appendix C). (h) The work lands as five implementation commits with their
fills, a programs commit, the merge of trunk with its fill, the implementation
reviews on the merged head, the fix commits, the land-time integration with its
document review, the row commit and the discharge commit last (§3); the merge
commit resolves conflicts only, and the composition with SC-1 is its own commit
S after it (amended 2026-10-14, review fold: RR-m2). While PR 51 to PR 59 are
held, M merges trunk's records only, and S, F6 and L are measured and stay
land-time commits (§1.12 "Held state"; (amended 2026-10-14,
implementation-review fold: IR2-MINOR-10)).

**Id allocation (recorded so no workstream collides;** amended 2026-10-14,
review fold: B-m1 / A-m8 / RR-m4**).** Re-scanned for rev 2 on 2026-10-14,
and again for rev 3 on 2026-10-14 with the same output, over the 78
refs `refs/heads/claude/carbon-fork-0-1-*`,
`refs/remotes/origin/claude/carbon-fork-0-1-*`, `refs/heads/trunk` and
`refs/remotes/origin/trunk` of /home/user/carbon-lang other than this
workstream's own two refs (80 refs match the patterns; the two excluded are
`refs/heads/claude/carbon-fork-0-1-tp` and its remote-tracking ref, which
carry this plan's own reservation text) with

<!-- google-doc-style-ignore -->

```sh
cd /home/user/carbon-lang
refs=$(git for-each-ref --format='%(refname)' \
  'refs/heads/claude/carbon-fork-0-1-*' \
  'refs/remotes/origin/claude/carbon-fork-0-1-*' \
  refs/heads/trunk refs/remotes/origin/trunk |
  grep -v 'claude/carbon-fork-0-1-tp$')
for r in $refs; do git grep -hoE 'W-[0-9]{3}' $r -- fork; done | sort -u | tail -3
for r in $refs; do git grep -lE 'W-(25[0-9]|26[0-9])\b' $r -- fork; done
for r in $refs; do git grep -hE 'F-019' $r -- fork docs; done | sort -u
```

<!-- google-doc-style-resume -->

The expected output, as measured on 2026-10-14, is `W-244`, `W-245` and `W-249`
from the first command (the maximum named on any other ref is W-249, OX-1's
parked block W-245..W-249) and nothing from the second and third. **TP-1
reserves W-250..W-269** (twenty ids) **and W-270..W-274**, which the focused
re-review of the fold reserved to its own residues (SV-1 holds W-275..W-294, so
no TP-1 id goes beyond W-274; (amended 2026-10-15, focused re-review of the
fold: all findings)); §1.13 files W-250 to W-266 (W-265 added at rev 3; amended
2026-10-14, review fold: RR-M1; W-266 added by the implementation-review fold,
(amended 2026-10-14, implementation-review fold: IR1-M3)) and W-267 to W-271
(filed by the focused re-review of the fold, W-271 by its round 2; (amended
2026-10-15, focused re-review of the fold: RR2r2-M1)), W-272 to W-274 stay
unused, and an unused reserved id stays unused and is never reused. **No fork
design id is minted** (D-TP-17): F-019 stays unallocated unless a review shows
that the slice decides a rule proposal 2200 leaves open, in which case F-019 is
minted with a dated amendment to docs/design/templates.md. F-017 and F-018 stay
with OX-1 and VA-1. The ids appear only in this plan and in three commits: the
page and fixture texts of the land-time integration L (Appendix C), the row of R
(§2.8), and the records of the discharge commit D (amended 2026-10-14, review
fold: RR-m4), and in the records commits after D that record the focused
re-review of the fold (c874c270f, 764e55445, its round 2's bdc1f62d7 and
aa57bfe1c, and its round 3's records commit; (amended 2026-10-15, focused
re-review of the fold: RR2r2-m2; records: re-review round 2; focused re-review
of the fold: all round-3 findings)); no source file, golden or
program header names one. Three pushed commit messages already
name W-250: C2's (637e3efaf, "the latter stays in the code (W-250)"), the second
fix commit's (12bd6d67a, "W-250's `semantics TODO`") and the records commit of
the focused re-review's round 1 (764e55445, "n8 stops it after W-250's TODO";
(amended 2026-10-15, focused re-review of the fold: RR2r2-m2)). The plan's
commits and D name ids in their messages too: rev 1 (6245f8687: W-250 and
W-269), rev 3 (aaf43d5a4: W-256, W-264 and W-265) and D (bf8e1b4cc: W-250,
W-266, W-267 and W-269), as the round-2 fixer's scan of every message since the
cut found; the round-2 fix commits and both records commits of round 2 name
none (amended 2026-10-15, focused re-review of the fold: RR2r2-m2; records:
re-review round 2), and neither do round 3's fix commits and records commit
(amended 2026-10-15, focused re-review of the fold: all round-3 findings).
History is not
rewritten, so if the re-scan before L re-allocates an id, D's landed notes
record the new id against each commit that names it; later commit messages
describe a residue instead of naming its reserved id ((amended 2026-10-14,
implementation-review fold: IR2-MINOR-4)). The three commands are re-run twice:
immediately before L, the first commit that publishes an id outside this plan,
and immediately before D writes the ledger. Any output other than the expected
one above that names W-250..W-274 or F-019 means another workstream took the id
(amended 2026-10-15, focused re-review of the fold: RR2r2-m2). Before L, the
residues re-allocate from the maximum plus one, skipping every reserved block,
and L, R and D are written with the new ids. Before D, the same re-allocation
also rewrites the ids that L's page and fixture texts and R's row already
published, in a commit before D. D records both outcomes in
fork/ORCHESTRATION.md and in the plan's landed notes. From the focused re-review
of the fold on, the second command's pattern is `W-(25[0-9]|26[0-9]|27[0-4])\b`;
its run on 2026-10-15's records (the
[focused re-review fold record](#focused-re-review-of-the-fold-2026-10-15))
finds the ids only in trunk's own reservation sentence (amended 2026-10-15,
focused re-review of the fold: RR2-M2).

**Design authority** (each cited where used):

-   proposals/p002200-template-generics.md (accepted): "Proposal" :184-229
    (the three differences from checked generics: lookup in the type and the
    constraints, validity by value, impl lookup delayed), "Name lookup"
    :433-505, "Template dependent" :712-738, "Simple member access" :739-768,
    "Compound member access" :769-831, "Impl lookup" :832-863, "Use of
    dependent value is dependent" :864-902.
-   proposals/p002138-checked-and-template-generic-terminology.md
    (terminology), question-for-leads issue 949 and proposal 989 (name
    lookup, cited by p002200:433-441).
-   proposals/p002875-functions-function-types-and-function-calls.md (each
    function has its own type; cited by D-TP-10).
-   proposals/p003763-matching-redeclarations.md :182-215 (two declarations
    differ if their token sequences differ; cited by D-TP-23 and W-254).
-   docs/design/expressions/member_access.md "Lookup ambiguity" :542-551 (more
    than one distinct member found makes the program invalid; cited by
    D-TP-13).
-   toolchain/check/type_completion.h:30-45 ("the code that creates an inst
    is responsible for enforcing any type completeness requirements"; cited
    by D-TP-8).
-   docs/design/templates.md as PR 58 rewrote it (head fcee90d9b on
    `claude/carbon-fork-0-1-dd`): "Templates in the 0.1 toolchain" and its
    five groups of limits, with fixtures X13..X33 and R08/R09 under
    fork/designdocs/samples/ and the checker fork/designdocs/check_samples.py.

V-3: no accepted proposal or leads' direction is contradicted. Every rule the
slice implements is proposal 2200's (or p2875's for D-TP-10, p3763's for
D-TP-23); where the toolchain cannot yet do what the design says (templates
across libraries, form parameters, out-of-line redeclarations with dependent
types, `partial T*`, `match` on a dependent value, arrays with a dependent
bound, the definition-time half of member lookup, assignment checks on
instantiation), the slice diagnoses or leaves the existing behavior and files
the gap; it never gives a form a different meaning.

## §0 Audit: measurements with file:line evidence

### §0.1 W-014, the row and the bullet's programs today

W-014's evidence list on trunk is stale. It cites
`lower/handle.cpp:359-364` ("Template lowering not implemented yet"); that
fatal is gone since upstream PR 7727 (in the cut): `HandleInst(SpliceInst)` at
lower/handle.cpp:494-515 lowers a same-file splice by lowering the
instruction the splice resolves to in the specific, and the only template
fatal left in lowering is "Cross-file template lowering not implemented yet"
(:513). UA-2 (PR 51) already re-cited W-014 accordingly on its branch and
un-SKIPped generics/templates_dependent_member.carbon; this plan takes PR 51's
text as the base (TP-1 lands after PR 51, §1.12). Measured here: the
dependent-member program with its `SKIP:` line removed runs on trunk and
prints `42` (`$P/out/misc/tdm.*`), so the trunk program's SKIP reason
(`FATAL failure at toolchain/lower/handle.cpp:363`) is stale on trunk and is
PR 51's to retire.

The row's trunk text ("operators/conversions on dependent values are
fail_todo, lowering hits CARBON_FATAL ... (lower/handle.cpp:363), and
templates.md is a self-described skeletal placeholder") is stale in two of its
three clauses; PR 51 and PR 58 each rewrite it on their branches (§0.9).

The bullet's programs on trunk (fork/conformance/README.md:291-293):
templates_type_param (run, PASS), templates_value_param (run, PASS),
templates_dependent_member (SKIP, stale). Both PASS programs call template
functions and print from them, so the arbiter's third clause ("a template
function executes in the run harness") is already met on trunk. The second
clause ("the lower fatal is gone") is met for same-file templates since
PR 7727, and is **not met** after TP-1 either (amended 2026-10-14, review
fold: B-M2): the cross-file fatal at lower/handle.cpp:513 stays in the code,
and TP-1 only makes it unreachable by reporting a `semantics TODO` for a
template used from another library at its `import` (D-TP-14), which leaves
that ordinary use of templates unsupported (W-250). The first clause ("all
generic/template fail_todo tests flip") is the one this slice meets in full:
§0.11 lists the four splits, and the two `todo_fail` pins that the clause's
wording does not cover but that are TODO pins all the same (W-259; amended
2026-10-14, review fold: B-M3).

### §0.2 The defect list, measured

Every DD-1 fixture was compiled (and linked and run when it defines `Run`)
with the trunk toolchain and the nightly by `$P/bin/probe.sh` (rev 1) and
`$X/bin/probe.sh` (rev 2), from
`/home/user/carbon-dd/fork/designdocs/samples/`; the last column is the rev 2
prototype v13 (§0.8), the state this plan specifies (amended 2026-10-14,
review fold: A-B1). Outcomes: ERROR is the first error line, CRASH the crash
report's first line, RUN the printed values.

| Fixture | Form | Trunk | Nightly 2026.10.12 | Prototype v13 |
| --- | --- | --- | --- | --- |
| X13 | `*p`, `p: T` | ERROR ``cannot dereference operand of non-pointer type `T` `` | same | same (C3 is not relinkable; predicted to run, §2.3) |
| X14 | `x.p->n` | ERROR ``cannot apply `->` operator to non-pointer type `<dependent type>` `` | same | same (predicted to run) |
| X15 | `&x.n`, `ref x: T` | ERROR `cannot take the address of non-reference expression` | same | same (predicted to run) |
| X16 | `p.1`, `p: T` | ERROR ``type `T` does not support tuple indexing; only tuples can be indexed that way`` | same | same (predicted to run) |
| X17 | `h(x)`, `h: G` | ERROR ``unable to monomorphize specific `Apply(<type of Twice>)` `` | same | COMPILES; as a program RUN `8` |
| X18 | `return p;` on a struct | ERROR ``unable to monomorphize specific `Id({.x: i32, .y: i32})` `` | same | COMPILES; RUN `5` |
| X19 | `a[1]` on an array | ERROR ``unable to monomorphize specific `Second(array(i32, 3))` `` | same | same (predicted to run) |
| X20 | `var y: T;` | ERROR ``cannot convert type `T` into type implementing `Core.DefaultOrUnformed` `` | same | COMPILES; RUN `5` |
| X21 | `x.F()` in type and constraint | RUN `21` | RUN `21` | ERROR ``unable to monomorphize specific `G(C as A)` `` (proposal 2200's error) |
| X22 | the operators that resolve per instantiation | RUN `-4 17 14 1 3` | same | same |
| X23 | `var y: T;` in a class method | ERROR (as X20) | same | COMPILES; RUN `6` |
| X24 | `self.item[0]` in a class | ERROR ``unable to monomorphize specific `First(array(i32, 2))` `` | same | same (predicted to run) |
| X25 | `[template T](h: Holder(T))` | ERROR ``cannot deduce value for generic parameter `T` `` | same | COMPILES; RUN `42` |
| X26 | `partial T*` | ERROR `` `partial` applied to final type `T` `` | same | same (OUT, W-251) |
| X28 | `for (x: i32 in a)`, `a: T` | CRASH `CHECK failure at toolchain/sem_ir/inst.h:249` (Checking ForHeader) | CRASH (same check) | COMPILES; RUN `6` |
| X29 | `-> (T, T)` | CRASH segfault in `PendingBlock::InsertHere` | same | COMPILES; RUN `8` |
| X30 | `-> {.a: T, .b: T}` | CRASH (as X29) | same | COMPILES; RUN `10` |
| X31 | `-> array(T, 2)` | CRASH (as X29) | COMPILES (RUN `8`) | COMPILES; RUN `8` |
| X32 | `H(template T).Both() -> (T, T)` | CRASH `CHECK failure at toolchain/lower/function_context.cpp:223` | CRASH (:201) | COMPILES; RUN `6` |
| X33 | `let (a, b) = p`, `p: T` | CRASH `FATAL failure at toolchain/lower/aggregate.cpp:67` | same | COMPILES; RUN `9` |
| PR-AK | `Id[template T](p: T) -> T` on `(4, 5)` | RUN, prints values that change per run (`1267490136 2` in rev 2's run) | same kind | RUN `4 5` |
| R08 | missing member | ERROR (as the page says) | same | same |
| R09 | constraint-only member | ERROR ``unable to monomorphize specific `Report(Square as HasArea)` `` | same | COMPILES; RUN `25` |
| X05 | structural `Circle` | ERROR ``cannot convert type `Circle` into type implementing `HasArea` `` | same | same (the design's rule) |
| X10 | `match` on a dependent value | ERROR `semantics TODO: match on unsupported scrutinee type` | other TODO | same (OUT, W-252) |
| X11 | `array(i32, N)` from a list | ERROR | COMPILES | same (OUT, W-253) |

PR-AK was reconstructed from fork/designdocs/plan.md on the dd branch,
§4.3 "PR-AK" (`g01_tuple_template_let.carbon`, copied to
`$P/probes/prak_g01.carbon`); X28 to X33, X17, X18, X20, X23, X25 and R09
as programs are `$P/runs/r28_for.carbon`, `r29_dup`, `r30_mk`, `r31_two`,
`r32_both`, `r33_destr`, `r17_apply`, `r18_structcopy`, `r20_uninit`,
`r23_class_uninit`, `r25_deduce` and `r09_constraint`, each the fixture's body
with a `Run` that prints the value the fixture's header derives. The flipped
fixture texts of Appendix C were run with PR 58's checker and v13 (§2.9).

### §0.3 Crash and miscompile root causes

Each stack below is from the trunk toolchain's crash report
(`$P/out/trunk/<fixture>.compile.log`); each root cause was confirmed by the
prototype that removes it (§0.8).

**RC-1 (X29, X30, X31, and the sweep's s22 and s30): a template-dependent
initializer loses its storage.** Stack: `PendingBlock::InsertHere` <-
`CategoryConverter::DoStep` <- `CategoryConverter::Convert` <-
`PerformAction(ConvertToCategoryAction)` <- `TryEvalTypedInst` <-
`TryEvalBlockForSpecific` <- `ResolveSpecificDefinition` <-
`CheckUnit::CheckRequiredDefinitions`. In `return (x, x);` with `x: T`, the
tuple literal is converted element by element (`ConvertTupleToTuple`,
convert.cpp:524-597) into `tuple_access %return, elementN` storage. Each
element `x` has the target's type `T`, so `AddConvertActionIfDependent`
returns at its same-type early exit (convert.cpp:2317-2320) and the category
conversion runs: `x` is a value, the target an in-place initializer, so
`PerformCopy` (:1992-2002) builds `Core.Copy` dispatch on the template type --
a dependent splice -- and `DoStep`'s `Dependent` case (:2174-2181) wraps it in
`ConvertToCategoryAction{conversion_kind = InPlaceInitializing}`. That action
records only the kind. On instantiation `PerformAction(ConvertToCategoryAction)`
(:2453-2460) rebuilds a `ConversionTarget` with neither `storage_id` nor
`storage_access_block`, the copy for `i32` is a by-copy initializer that is
not in place, and :2198 calls `target_.storage_access_block->InsertHere()` on
the null pointer. X31's array form takes the same path through
`ConvertTupleToArray` (:440-503). The nightly runs X31 because upstream
947c1eb52 made `array` the class `Core.Array` (§0.7): its dump shows a single
`initialize_action %.loc16_15, %.loc15_45.5, %return.param` for the whole
conversion, which carries the storage, instead of per-element copies.

**RC-2 (PR-AK, the sweep's s11 and s15, and review A's b01b, b02, b03,
b05, b07, b08 and rev 2's s16c and s35b): the same lost storage, silent.**
For `return p;` with `p: T` and `T = (i32, i32)`, the definition holds
`convert_to_category_action %.loc2_45.4, element10` (kind `Initializing`) over
the dependent `Copy` call. On instantiation the copy call initializes its own
temporary, and with no target storage `OverwriteTemporaryStorageArg` has
nothing to redirect it to, while `return` lowers the result as an in-place
initializer of `%return`. The lowered function (trunk,
`--dump-llvm-ir`) shows it:

<!-- google-doc-style-ignore -->

```llvm
define linkonce_odr void @_CId.Main.00f31208999b670d(ptr sret({ i32, i32 }) %return, ptr %p) {
entry:
  %.0d2.temp = alloca { i32, i32 }, align 4
  call void @"_COp.4e4edddc7580c79b:Copy.Core.8608f3c6f62d80cb"(ptr %.0d2.temp, ptr %p)
  ret void
}
```

<!-- google-doc-style-resume -->

`%return` is never written, so the caller reads uninitialized stack: the
values that change from run to run.
The same lost storage gives wrong values, not crashes, in more forms (amended
2026-10-14, review fold: A-B1 / B-M4; `$X/matrix-table.tsv`): review A's b01b
(an initializer with side effects), b03 (a class copy returned), b05, b07 (a
tuple assigned) and b08 (a `returned var` of class type), rev 2's s16c
(`x = y` through a `ref x: T` on a tuple) and the destructor of a
template-dependent `var` (review A's b02, rev 2's s35b and n04: `var y: T =
x;` for a class `D` whose destructor prints `n` destroys uninitialized storage
on trunk, printing values such as `-247441984`). Each prints the right values
on v13, equal to the same code with the types written out (`n04c`).

**RC-3 (X28, at the definition): a splice is read as if instantiated.** Stack:
`ConstantValueStore::GetInstAs<InstValue>` <- `FindStorageArgForInitializer`
<- `Check::Initialize` <- `HandleParseNode(ForHeader)`. The `for` header
creates the cursor variable and calls `Initialize` (handle_loop_statement.cpp:
228-240) with the cursor from the dependent `Iterate.NewCursor` call; the
conversion is a `ConvertToCategoryAction` splice (RC-1's path), and
`Initialize` (convert.cpp:2738-2766) then asks `FindStorageArgForInitializer`
for its storage argument. Its `SpliceInst` arm (sem_ir/expr_info.cpp:307-317)
calls `GetInstAs<InstValue>` on the splice's constant, which in the
definition is the unevaluated action, not an `InstValue`:
`CHECK failure at toolchain/sem_ir/inst.h:249: Is<TypedInst>(): Casting inst
{kind: ConvertToCategoryAction, ...} to wrong kind InstValue`. Every
template `for` loop over a dependent range hits this where the function is
defined, called or not (X28 has no call).

**RC-4 (X28 with a call over an array, found by the prototype): a pointer type
formed for a dependent type is never completed.** With RC-1 and RC-3 fixed,
`Sum(a)` on an `array(i32, 3)` and the same loop over a member array crash in
lowering: a segfault in `llvm::Argument::addAttr` <-
`FileContext::GetOrCreateLLVMFunction` <- `HandleInst(Call)`. Instrumenting
the prototype (variant `dbg`, `TP1DBG` lines) showed the lowered callee is
the array impl's `Next` with `params=0 sret=1`, because
`FunctionTypeInfoBuilder::TryHandleParameter` (lower/type.cpp:434-520) found
the parameter `cursor: i32*` with an `Unknown` value representation (:493)
and built an inexact function type; `GetOrCreateLLVMFunction`
(lower/file_context.cpp:438-441) then adds the return-slot attribute to the
first argument of a function that has none. The cursor's address is formed at
handle_loop_statement.cpp:254-259 as `AddrOf` of type
`GetPointerType(<dependent cursor type>)`; for a symbolic pointee nothing
requires the pointer type complete, so the specific's `i32*` never gets
complete-type information. The same call written out in a template
(`a.(Core.Iterate.Next)(&c)` with `var c: i32`, `$P/iso/i7_next_op.carbon`)
lowers with three parameters, because `&c` forms `i32*` concretely.
type_completion.h:41-42 puts the obligation on the code that forms the
instruction. Upstream bf91a8b4d (canonical self in `ImplSelfWitness`) was
measured not to change this (variant v3).

**RC-5 (X32, and review A's b09, b09b, b09e, c1, c3, c4, c5): the storage of a
deferred initialization is placed in the template's body, where no specific can
use it in the right order** (amended 2026-10-14, review fold: A-B1). The class
method's `return (self.a, self.a);` converts each element through the
`InitializeAction` path of `AddConvertActionIfDependent` (:2335-2391), whose
`storage_id` is the element's `tuple_access %return`. `ConvertAggregateElement`
(convert.cpp:399-405) adds that access to the pending storage access block
inside a `PendingBlock::DiscardUnusedInstsScope`, and nothing inserts or merges
the block before the scope ends, so the instruction is dropped (the dump prints
it as `<unexpected>.inst5900007A`); lowering reaches it through a `SpecificInst`
and fails `CHECK failure at toolchain/lower/function_context.cpp:223:
const_id.is_concrete()`. Two placements were measured and both are wrong:

-   Rev 1's A4 inserts the block where the action is created. That puts the
    storage after the initializer when the initializer is itself an earlier
    in-place initializer, such as a template call returning an aggregate:
    for `fn G[template T: type](x: T) -> ((T, T), i32) { return (Pair(x),
    1); }` the `tuple_access %return.param, element0` comes after the
    `splice_inst` of the call, and on instantiation
    `PerformAction(InitializeAction)` rewrites the call's `TemporaryStorage`
    (`OverwriteTemporaryStorageArg`, convert.cpp:103-150, `MergeReplacing` at
    the storage-argument position) into a `SpecificInst` of that later
    instruction, which lowering reaches first: RC-5's CHECK again (review
    A's b09, b09b, c1, c3, c4; reproduced on v8 and on mutant M2 of v13,
    §8.5).
-   Upstream 4a8993af2 moves the block into the action. That removes the
    instructions from the body, and the body still uses an outer element's
    access for the inner literal's `tuple_init`: for `return ((x, x), x);`
    the outer `tuple_access %return, element0` is taken into the first inner
    element's action, and the verifier reports ``tuple_access used by
    tuple_init ... is not dominated`` (review A's v11, the upstream form plus
    a test that inserts a block with cleanups eagerly, on b09e, c1 and c5).
    Without that test, `PendingBlock::TakeAsInstBlock` CHECK-fails on the
    `for` cursor's `VarStorage`, which carries a cleanup (rev 1's v10).

A non-template initialization puts the storage access instructions where the
initializer needs them: in place of the initializer's temporary
(`MergeReplacing`) or before its own `*_init` (`InsertHere`). In a template,
which of the two applies, and where the initializer's temporary is, are known
only in the specific; so the action must carry its own copy of the access
instructions and let each specific place it, while the body keeps the
originals for its own uses (D-TP-3). Upstream 4a8993af2 fixes the
`<unexpected>` instruction; the nightly then fails the second defect:
`HandleInst(SpliceInst)` (lower/handle.cpp:494-506) calls
`GetValue(inst_value.inst_id)` with a value required, and the spliced
instruction is an `InPlaceInit`, which lowers its initialization and has no
value (nightly: `CHECK failure at toolchain/lower/function_context.cpp:201 ...
{kind: InPlaceInit, ...}`). `HandleInst(SpecificInst)` (:470-485) already
uses `require_value=false` for exactly this reason; the splice handlers do
not.

**RC-6 (X33, and the sweep's s34): lowering asks the generic for a category,
and a value binding of a dependent value is dependent.** First,
`GetAggregateElement` (lower/aggregate.cpp:51-67) computes the aggregate's
category with `SemIR::GetExprCategory(context.sem_ir(), aggr_inst_id)`, without
the specific, so the `splice_inst` of the `convert_action` that destructures
`p` has category `Dependent` and :65-67 is fatal: `Unexpected expression
category for aggregate access into {kind: SpliceInst, ...}`. `ReturnExpr`
(lower/handle.cpp:378-381) already passes the specific; `Assign` (:103-110),
`Temporary`, `ValueAsRef` and `ValueOfInitializer`
(lower/handle_expr_category.cpp:61, :77, :87) do not. Second, with that fixed
(variant v1), `a + b` crashes with `GetValue` of a `SpliceInst` whose value in
the specific is symbolic: the binding `a` is bound to a
`convert_to_category_action(..., Value)` splice, the action kind's category is
`Dependent` (sem_ir/typed_insts.h:612-625), so `a.ref` is `Dependent` too, and
on instantiation `PerformAction` on the operand `a.ref` (not wrapped in a
`SpecificInst`, because its type is concrete and its value is runtime) sees
`Dependent` again and creates a new template action that nothing evaluates
(the v1 dump shows `splice_inst <unexpected>.inst59000673` as the value of
`%.loc4_10.2` in the specific).

**RC-7 (X29 to X32 in lowering, after RC-1): `EmitAggregateInitializer`
decides constness in the generic.** With RC-1 fixed (v1), the tuple's
`tuple_init` crashes at `ValueStore::Get(inst<none>)` <-
`GetTypeOfInstInSpecific` <- `EmitAggregateInitializer`: its in-place loop
(lower/aggregate.cpp:227-235) treats an element whose generic constant is
symbolic (`is_constant()` is true for a template splice) as a constant field
and asks `FindStorageArgForInitializer` for its storage, which (with RC-3's
fix) is `None`. `LowerInst` skips constants with `FunctionContext::IsConstant`
(function_context.cpp:184-188), which reads the specific;
lower/handle.cpp:86-92 (`ArrayInit`, a fork addition from SL-2) has the same
generic read.

**RC-8 (a template used from another library; DD-1's probe PR-A).**
`$P/xlib/lib.carbon` defines `GetN[template T: type]`; `main.carbon` imports
it and calls it. Trunk: `FATAL failure at toolchain/check/import_ref.cpp:5087:
Missing case in TryResolveInstCanonical for instruction kind SpliceInst` while
checking the name `GetN` (nightly: the same at :4875). `TryFinishGeneric`
(import_ref.cpp:1162-1193) imports the generic's definition eval block, which
for a template holds actions and splices, and `TryResolveInstCanonical`
(:4833-5088) has no case for them. Importing them would need a representation
of an imported template's instantiation, which neither check nor lowering has
(lower/handle.cpp:507-513 says so for lowering).

**RC-9 (a form parameter, `template` or `generic`, found by the sweep;
amended 2026-10-14, review fold: A-M3).**
`fn F(template Fm: Core.Form, unused x:? Fm) {}` with
`import Core library "prelude/types/form";` (`$P/forms/f3_template_form.carbon`,
review A's f02) compiles on trunk and crashes lowering `F`'s specific: `FATAL
failure at toolchain/lower/type.cpp:514: Unexpected inst kind: {kind:
SpliceInst, ...}`, because `TryHandleParameter` (:434-446) reads the parameter
pattern's generic constant, the splice of a `FormParamPatternAction` (created
at handle_binding_pattern.cpp:470-490). The defect is not template-specific:
review A's f01 is the existing upstream golden `form_generic_param`
(toolchain/check/testdata/function/call/form.carbon:108-116,
`fn F(generic Fm: Core.Form, unused x:? Fm) {}` called as
`F(form(var i32), x)`), which checks and then hits the same fatal when it is
compiled to an object, on trunk and on v13 (`$X/out/v12/ra/f01_*`), because a
checked form parameter also creates a deferred `FormParamPatternAction`
(action.cpp makes it performable only for a concrete `InitForm`, `RefForm` or
`ValueForm`). Resolving the pattern in the specific (measured, variant v9,
not kept) yields a `VarPattern` the parameter switch does not expect either.
`Core.Form` is not exported by the prelude (core/prelude does not import
`prelude/types/form`); W-014's "pattern splices" (the `CARBON_FATAL`s of
pattern_match.cpp:2174-2180 for thunk, local and match-case matching) belong
to the same form-parameter feature: local and match-case form bindings are
diagnosed before reaching them (`$P/forms/f1_match.carbon`, `f4_local.carbon`:
`semantics TODO: form binding in match case pattern`,
`semantics TODO: support local form bindings`). TP-1 leaves all of it
unchanged and files it (W-255): a guard for the template spelling alone would
turn programs that check today into errors while the same crash stays
reachable through `generic` (R17).

**RC-10 (not a template defect, found by the sweep).**
`fn F(x: (i32, i32)) -> {.a: (i32, i32)} { return {.a = x}; }` crashes the
trunk and the nightly while checking the `return` (`CHECK failure at
toolchain/check/convert.cpp:2199: new_storage_id.has_value()`;
`$P/probes/s32n.carbon`): the struct's initializing representation is by
copy, its single field's is in place, and the field is converted with an
in-place target that has no storage. The template form s32 reaches it on
instantiation. It is outside this slice, but it is reachable from a
template and is filed under this bullet and named in the row residue and on
the page (W-256; amended 2026-10-14, review fold: B-M2).

The defect is wider than that crash, and it also compiles programs wrongly
(amended 2026-10-14, review fold: RR-M2). Measured without any template on
trunk and the nightly (`$Y/probes/rc10`):

-   wrong values that change from run to run: `var s: {.a: (i32, i32)} =
    {.a = x};` for a tuple value `x` (k02), and a struct whose field is a
    struct of one tuple field, returned from a value or a literal or stored
    in a `var` (k04, k05, and the re-review's q07cn,
    `fn G(x: i32) -> {.a: {.b: (i32, i32)}, .c: i32}` returning
    `{.a = {.b = (x, x)}, .c = x}`);
-   the CHECK above: returning `{.a = (x, x)}` (k03), a one-element tuple of a
    tuple (k08), s32n and the re-review's q07en;
-   ``CHECK failure at toolchain/lower/handle_call.cpp:984: args_ok`` when
    `{.a = (3, 4)}` is passed to a parameter of that type (k06);
-   correct values: a literal of constants in a `var` (k01, prints 3) and a
    `var` parameter (k07, prints 7).

The template form q07c (`fn G[template T: type](x: T) ->
{.a: {.b: (T, T)}, .c: T}` returning `{.a = {.b = (x, x)}, .c = x}`)
segfaults on trunk and the nightly, which is RC-1's lost storage, not RC-10.
With RC-1 fixed it prints values that change from run to run on v13 and v14
(1841369832, then 1182435416 in the re-review's runs, 1408068200 in rev 3's),
as q07cn does on trunk. TP-1 therefore turns that template crash into the
miscompile that the same code without a template parameter already has; it
does not create the miscompile, and the neighbouring forms run (q07f, a
two-field inner struct, and q07g, a tuple field, print 9). D-TP-1 accepts
the trade for this form because the fix belongs to RC-10, and a diagnosis
was measured and rejected: variant g (`$Y`, v14 plus a `semantics TODO` in
`ConvertAggregateElement` for an element initialized in place inside an
aggregate initialized by copy) diagnoses q07c, q07cn, k02 to k05, k08 and
s32, but also rejects k01 and k07, which run today, and changes
tuple/class_tuples.carbon `fail_type_assign`'s diagnostic (gate 1934 of
1942). That would turn working programs into errors without fixing the
non-template miscompile (R17, as for D-TP-15; §7.2(11)). W-256 records the
miscompile with and without template parameters, the row residue and the page
name it, and no golden or program uses the form.

**RC-11 (review A's e01, found in review): a replayed conversion has no
storage access block** (amended 2026-10-14, review fold: A-m1).
`fn F[template T: type](x: T) -> {.a: i64} { return x; }` called with a
`{.a: i32}` segfaults on trunk and the nightly while the specific is resolved:
the `ConvertAction` replay (`PerformAction(ConvertAction)`, convert.cpp:2439)
builds a `ConversionTarget` with no `storage_access_block`, and
`ConvertStructToStruct` dereferences it for the converted field's storage
(`ConversionTarget`'s contract, convert.h:61-74, requires the block for every
initializer). A2 (D-TP-4) fixes it: v13 prints 4, and mutant M3 (A2 dropped)
segfaults again (§8.5).

**RC-12 (found in rev 2; restated at rev 3): a template-dependent in-place
initializer whose storage root is allocated after it** (amended 2026-10-14,
review fold: A-B1 / RR-M1). D-TP-3's copy puts the access instructions where
each specific needs them, but not the root they start from. A root that is
already in the body when the initializer is checked (a `var`'s `VarStorage`,
created with the `var` pattern by `GetOrAddVarStorage`,
handle_let_and_var.cpp:147; the return slot) precedes everything; a root that
is still pending when the action is created does not. Check creates four
such roots after the initializers they hold:

-   the temporary of a tuple-to-array value conversion (convert.cpp:471,
    `ConvertTupleToArray`, after the elements are converted);
-   the temporary of a union value (convert.cpp:1084, `ConvertStructToUnion`);
-   the temporary of a class value (convert.cpp:1203, `ConvertStructToClass`);
-   the `for` cursor's `VarStorage` (handle_loop_statement.cpp:229, after the
    `NewCursor` call; the toolchain's own TODO at :216-218 says "We need to
    allocate the `VarStorage` before building the operator").

A `var` parameter's `VarStorage` (pattern_match.cpp:1740) is also pending
when its argument is converted, but measured unaffected: the re-review's q10
prints 9. A pending root is inserted where the action is created, so when its
initializer turns out, in the specific, to be an in-place initializer with its
own temporary, the rewritten temporary names a root that comes later. Measured
on v13 (`$Y/mx/v13/v13.txt`):

-   A class value fails the SemIR verifier during checking: ``FATAL failure at
    toolchain/check/context.cpp:86: Built invalid semantics IR: Operand ...
    (temporary_storage) used by instruction ... (class_element_access) ... is
    not dominated``. The re-review's r4 is
    `let c: C = {.a = Pair(x), .b = 1};` in `fn G[template T: type](x: T)`,
    with `class C { var a: (i32, i32); var b: i32; }` and `Pair` the template
    `return (x, x);`. Its r2 uses the generic class `C(T)`, r8 has
    `.a = MkP(x)` for a template returning a class, and r9 is
    `({.a = Pair(x), .b = 1} as C).Sum()`. Rev 3's t01 (r2 for `i32` and
    `i64`), t03 (a class value inside a tuple value), t04 (two class values in
    an array value) and t11 fail the same way.
-   An array value and a union value fail the same verifier check: rev 2's n02
    (`let a: array((T, T), 2) = (Pair(x), Pair(x));`) and rev 3's t10
    (`let u: U = {.p = Pair(x)};` for `union U { var p: (i32, i32); var w:
    i64; }`).
-   The `for` cursor form n01 (a loop over a class whose cursor is
    `(i32, i32)`) fails `CHECK failure at
    toolchain/lower/function_context.cpp:223` while `Sum(Counter)` is
    lowered.

The same bodies without a template run (r2n 9, r8n 7, t10n 12, n01c 6), because
there `MergeReplacing` moves the root itself into the call's temporary, and the
`var`, argument and return forms of the class value run on v13 (r6 7, r3 7, r1
9). Trunk crashes on every template form above (RC-1, or RC-3 for n01), and so
does the nightly, except on t10, whose `union` declaration the upstream
toolchain does not parse. The three value temporaries are fixed in C1 by
D-TP-24, which leaves a template-dependent value conversion that would allocate
its own temporary to `Convert`, so that it is deferred as one action and each
specific allocates the temporary as a concrete conversion does. Measured on v14
(`$Y/v14.diff`, v13 plus D-TP-24): r2 prints 3, r4 7, r8 7, r9 7, t01 `6 8`, t03
9, t04 9, t11 8, n02 5 and t10 12, the values of the same code without
templates. Two forms remain (W-264):

-   The `for` cursor, which is not a conversion's temporary: the loop header
    creates it, and the fix is to allocate it before `NewCursor` is called,
    the TODO above. A cursor that is an integer (arrays, `Core.Range`) is not
    initialized in place, so every loop of DD-1's list runs.
-   A class value whose struct literal leaves a field to its default
    initializer (t02: `let c: C = {.a = Pair(x)};` with `var b: i32 = 5;` in
    `C`). D-TP-24 defers only a source that names exactly the class's fields,
    so that a missing or unexpected field is still diagnosed where the
    function is defined, and t02 fails the verifier as above. The same code
    without a template stops the compiler too, as does any runtime class
    value or `var` whose field takes its default (t02n, t16n, t17n: ``FATAL
    failure at toolchain/sem_ir/expr_info.cpp:359: Initialization from
    unexpected inst {kind: IntValue ...}`` on trunk; the nightly stops on
    them too). That is a defect of field defaults, not of templates (the
    stack is `EmitAggregateInitializer` while the function is lowered),
    filed as W-265 because the template form reaches it once W-264 is
    fixed.

**RC-13 (review A's h03c and b04d; not a template defect): a constant nested
aggregate fails LLVM verification** (amended 2026-10-14, review fold: A-m3).
`let t: ((i32, i32), i32) = ((1, 2), 3);` and a struct `let` with a tuple
field fail `CHECK failure at toolchain/lower/lower.cpp:48:
!llvm::verifyModule(...)` ("Global variable initializer type does not match
global variable type") on trunk, the nightly and v13. Trunk rejected the
template copies of such values (b04b, b04c, h03) during checking; with D-TP-2
they check and reach the same failure. The same bodies with runtime values
(b04e, h03b) run on v13. Outside this slice (W-263); TP-1's goldens and
programs use runtime values, never constant nested aggregates.

### §0.4 Rejected dependent forms: which check resolves too early

| Form | Where it is resolved | Why too early | Action kind today |
| --- | --- | --- | --- |
| `*e` (X13) | `PerformPointerDereference`, check/pointer_dereference.cpp:16-37, from handle_operator.cpp:378-400 | it reads `e`'s type at the definition; a template parameter `T` is not a `PointerType`, so `DerefOfNonPointer` | none |
| `e->m` (X14) | the same function from handle_name.cpp:47-90 | the same, with `ArrowOperatorOfNonPointer` | none |
| `&e` (X15) | handle_operator.cpp:270-294 | it requires a durable reference; a member of a dependent operand is a splice whose category is `Dependent` | none |
| `e.N` (X16) | `PerformTupleAccess`, member_access.cpp:892-905, from handle_name.cpp:30-36 | it requires a `TupleType` at the definition | none |
| `h(x)`, `h: G` (X17) | the call is deferred correctly (`CallAction`, call.cpp:871-891) | on instantiation `GetCallee` (sem_ir/function.cpp:73-76) identifies a function only from the callee's constant value, and a parameter has none; a function's type alone names the function (p2875) | `CallAction` (exists) |
| struct copy (X18, W-192) | `CategoryConverter::DoStep` `Value` case, convert.cpp:2266-2275, calls `PerformCopy` (:1992-2002) | it commits to `Core.Copy` for the dependent type at the definition; a concrete struct (and tuple) is copied by the builtin aggregate conversion (`ConvertStructToStruct`, measured in `$P/probes/structcopy.carbon`: `struct_access` and `in_place_init` per field), and struct types implement no `Core.Copy` | `ConvertToCategoryAction` (wrong storage, RC-1) |
| `a[i]` (X19, X24, W-192) | `HandleParseNode(IndexExpr)`, handle_index.cpp:157-215 | it switches on the operand's type at the definition; `T` takes the `IndexWith` branch, and arrays are indexed by the builtin `ArrayIndex` with no `IndexWith` impl | `CompoundMemberAccessAction` + `CallAction` (wrong branch) |
| `var y: T;` (X20, X23, W-127) | `MakeDefaultInit`, handle_let_and_var.cpp:278-305, converts `T` to `Core.DefaultOrUnformed`; `LookupImplWitness`, impl_lookup.cpp:1080-1087 | a symbolic query keeps its deferred witness only if `FindNonFinalWitness` finds an impl that may apply; the prelude's `impl forall [T: UnformedInit]` and `final impl forall [T: Default]` cannot be shown to apply to an unconstrained template `T`, while p002200:198-199 delays impl lookup for templates | none needed (the witness is already deferrable) |
| `x.F()` with `T:! I` (X21, R09, W-183) | `PerformMemberAccess`, member_access.cpp:503-523, defers the whole access; `PerformAction(AccessMemberAction)`, :700-704 | on instantiation the name is looked up in the argument's type only (its own TODO at :506-509 says so); in the definition the constraint is not consulted at all, so neither proposal 2200's definition-time meaning nor its ambiguity rule applies (review A's a12, a13), and `T.F` is never compared (a05) | `AccessMemberAction` (exists) |
| `Holder(T)` (X25, W-193) | `IsCallPerformable`, call.cpp:820-833 | any argument with a template-dependent value defers the call, so the parameter type is `splice(convert_to_value_action(splice(call_action(Holder, T))))` instead of `class_type @Holder, @Holder(%T)`, and deduction (deduce.cpp:399-465) cannot see through a splice | `CallAction` (too eager to defer) |
| `partial T*` (X26) | handle_operator.cpp:342-361 | the eager `PartialOnFinal` check | none (OUT, W-251) |
| `match (x)` (X10) | handle_match.cpp | unsupported scrutinee type | none (OUT, W-252) |

### §0.5 The deferred-action machinery, read

The machinery is in check/action.{h,cpp} and check/eval.cpp; there is no
design document for it (docs/design/generics/ describes the language, not
SemIR). A template-dependent operation is represented in the definition by an
action instruction (`constant_kind` `InstAction` or `MultiInstAction`,
sem_ir/typed_insts.h) placed in the generic's eval block by
`AddDependentActionInst` (action.cpp:315-319), and by a `SpliceInst` in the
function body that stands for the action's result (`AddSpliceInst`,
action.cpp:236-246; `AddDependentActionSplice`, :321-329). `HandleAction`
(action.h) performs the action at once when `ActionIsPerformable`
(action.cpp:202-234: no operand is template-dependent) and otherwise defers
it. On instantiation `TryEvalBlockForSpecific` evaluates the eval block;
`TryEvalTypedInst` (eval.cpp:3150-3186) calls `PerformDelayedAction`, which
refines the operands into the specific (`RefineOperandsInSpecific`,
action.cpp:461-470: an operand with a symbolic type or value becomes a
`SpecificInst`), performs the action in a fresh instruction block and wraps a
multi-instruction result in a `SpliceBlock` (:478-512); the action's constant
becomes an `InstValue` of the result. Lowering a specific lowers a
`SpliceInst` by lowering that result (lower/handle.cpp:494-506).

Action kinds at b2576f6c3 (sem_ir/inst_kind.def): `AccessMemberAction`,
`AccessOptionalMemberAction`, `CallAction`, `CalleePatternMatchAction`,
`CallerPatternMatchAction`, `CompoundMemberAccessAction`, `ConvertAction`,
`ConvertToCategoryAction`, `ConvertToValueAction`, `FormParamPatternAction`,
`InitializeAction` (the only `MultiInstAction`) and
`OutFormParamPatternAction`. Upstream (66a250ad9) has the same twelve.

Per dependent form: member access, compound member access, calls,
conversions and the operators that dispatch through an interface (X22) have
actions and work; copies and initializations have actions that lose their
storage (RC-1, RC-2); dereference, address-of, tuple element access and
indexing have none (§0.4).

The deferral is needed only where the eager code cannot decide (amended
2026-10-14, review fold: A-m7): an operand whose type is a template binding
(`T`), its facet access type (`T` for `template T: I`), or the type of a
template-dependent expression (`<dependent type>`, a `TypeOfInst` of a
splice), whose kind -- pointer, tuple, array or class -- is known only on
instantiation. A template-dependent type whose kind is known, such as the
class `C(T)` or `Vec(T)`, keeps today's eager path: `*c` for `c: C(T)` is
rejected where it is written, and `v[i]` for `v: Vec(T)` with an `IndexWith`
impl already defers through `CompoundMemberAccessAction` and `CallAction`.

### §0.6 Systematic sweep

Thirty-five one-concept programs (`$P/sweep/s01..s35`), nine isolation
programs (`$P/iso/i1..i9`), four form programs (`$P/forms/f1..f4`) and the
cross-library pair (`$P/xlib`) were run on trunk and the nightly for rev 1.
Beyond DD-1's list they found: two more miscompiles of RC-2's kind (s11, a
template calling a template on a tuple; s15, `*p` for `p: T*` with a tuple
`T`), two more crashes of RC-1's kind (s22 `fn F(template N: i32) -> (i32,
i32)`, s30 `returned var r: (T, T)`), one of RC-6's (s34, destructuring a
member tuple), RC-4 (a `for` loop over a dependent array, reachable only once
RC-3 is fixed), RC-9 (form parameters) and RC-10, which is not a template
defect and which s32 reaches with a template parameter (rev 1 counted s32 as
RC-1's kind; amended 2026-10-14, review fold: B-m2). Every other
probe runs with the hand-derived value on trunk, the nightly and the
prototype: dependent `if` and `while` conditions, struct literals, `as`,
assignment, discarded expressions, method calls returning tuples, generic
classes of `T`, calls of templates from templates on scalars, and the value
parameters of templates. The nightly differs from trunk on two probes only,
s29 (`array(T, 2)` deduction fails on the nightly) and s31
(`var a: array(i32, N);`), both the `Core.Array` change.

Rev 2 re-ran the whole set, review A's fifty-seven probes and eleven of its
own on trunk, the nightly and v13 (`$X/bin/matrix.sh`, 183 runs per
toolchain, table `$X/matrix-table.tsv`; amended 2026-10-14, review fold:
A-B1 / A-m1 / A-m3 / B-M4). Beyond rev 1's list:

-   Review A's nested aggregates built from template calls (b09, b09a, b09b,
    b09c, b09e, c1, c2, c3, c4, c5, h04) crash trunk and the nightly and
    crashed v8 (RC-5); all run on v13 with the values of the same code
    without templates.
-   Review A's wrong-value forms and rev 2's s16c, s35b and n04 (RC-2) print
    the right values on v13.
-   e01 (RC-11) segfaults trunk and the nightly and runs on v13.
-   n01, n02 (RC-12) crash v13; n01c, the same loop without a template, runs.
    n03 (`var y: U = (Pair(x), x);` with `U` a template parameter) runs, so
    a `var`'s storage, which precedes its initializer, is not affected. n02
    runs on v14 (D-TP-24; amended 2026-10-14, review fold: RR-M1).
-   h03c and b04d (RC-13) fail LLVM verification on all three toolchains;
    b04b, b04c and h03, which trunk rejected while checking, reach the same
    failure on v13; b04e and h03b, with runtime values, run.
-   f01 (review A's form `generic` parameter, RC-9) crashes trunk and v13 as
    the template spelling f02 does.
-   s16 and s35 had errors of their own (an integer literal deduced against an
    `i32`, and a destructor declared with a syntax the toolchain does not
    accept). Their corrections are `$X/probes/fixed/s16b` (prints 8 on both
    toolchains), `s16c` (a tuple through `ref x: T`, prints 3 on trunk and 7
    on v13) and `s35b` (`impl as Core.Destroy`; prints garbage on trunk and
    `17 0 7` on v13).

Rev 3 rebuilt v13 from `$X/v13.diff` (byte-identical sources, 13 translation
units relinked) and built v14, then ran rev 2's probe directories, the
re-review's 35 probes (`$Y/probes/rr`) and rev 3's 24 (`$Y/probes/v14`) on
both (`$Y/bin/matrix.sh`, 235 runs per toolchain, `$Y/mx/`; amended
2026-10-14, review fold: RR-M1 / RR-M2). v14 differs from v13 only on the
RC-12 value forms, which crash v13 and run on v14 with the values of the
same code without templates (r2, r4, r8, r9, n02, t01, t03, t04, t10, t11),
and in the line number of RC-10's CHECK in convert.cpp. Rev 3's diagnostics
probes keep their definition-time errors on v14: an unexpected field (t13), a
missing field (t13b), a union's unknown field (t18) and an array of the wrong
length (t19). q07c and the RC-10 probes of `$Y/probes/rc10` are §0.3's
RC-10.

### §0.7 Upstream since the cut

Fifty upstream commits lie between the cut and upstream/trunk 66a250ad9
(`git -C /home/user/carbon-lang log 0bdce60a5..upstream/trunk`), thirty-six
of them under toolchain/check, toolchain/lower or toolchain/sem_ir (`git log
--oneline 0bdce60a5..upstream/trunk -- toolchain/check toolchain/lower
toolchain/sem_ir | wc -l`; amended 2026-10-14, review fold: A-m8); the
nightly is 62f1cc6a3, thirty-six commits past c1e83b0b7. The ones that touch
the template machinery or the forms above, with `git merge-tree` against
b2576f6c3:

| Commit | Subject | Relevance | Merge onto trunk |
| --- | --- | --- | --- |
| 947c1eb52 | Add a `Core.Array` class type, and make `array` refer to it | the reason X31 runs on the nightly: the tuple-to-array conversion becomes one `InitializeAction` with storage (nightly dump of X31, §0.3 RC-1); X29 and X30 still crash on the nightly, so it is not a template fix | not attempted: 131 files, +8912/-8143, a language-level change with a prelude rewrite |
| 4a8993af2 | Fix "<unexpected>" inst when creating an InitializeAction | addresses RC-5's first defect by moving the storage access block into the action (`InitializeAction::Target` gains `storage_access_block_id`, sem_ir/typed_insts.h) | one conflict, in a golden (array/init_dependent_bound.carbon); measured as rev 1's v10 (CHECK at `pending_block.h:89` on every template `for` loop) and as review A's v11 with a cleanup guard (nested literals fail the verifier, §0.3 RC-5) |
| bf91a8b4d | Canonicalize the self in ImplSelfWitness | measured as variant v3: no effect on RC-4 | clean |
| 71af20740 | Disable global state that modifies eval while resolving a specific | `declaring_impl_decls` during `TryEvalBlockForSpecific`; no template form here depends on it | clean |
| 230227264, e588469fd, 9fd28f730, 559602b9e | return storage and `return expr;` for value forms; an `EmitAggregateInitializer` crash | non-template return-form work; 559602b9e is unrelated to RC-7 (it fixes value-form returns) | 230227264 and 9fd28f730 conflict in lower files |

Verdict (D-TP-16, amended 2026-10-14, review fold: A-B1): no cherry-pick.
VA-1 cherry-picked upstream's own start of its feature; here no upstream
commit implements any form of this slice, the commit that makes X31 run on
the nightly is a language-level side effect, and 4a8993af2's placement is
measured wrong for nested literals (it takes instructions the template body
still uses) as well as for the `for` cursor (it cannot carry a cleanup). Rev 1
rejected it only for the second reason, which a one-line guard removes
(review A's v11); the first is the reason that holds. D-TP-3 uses
4a8993af2's representation of the block -- an `InstValue` of a `SpliceBlock`
that is in no block -- but fills it with a copy of the access instructions
instead of the shared block, and carries it in the existing
`InitializeAction::Target::storage_id`, so `InitializeAction::Target` keeps its
layout. When the next upstream advance brings 4a8993af2's separate
`storage_access_block_id`, the copy moves into that field and the copy rule
stays (W-258).

### §0.8 Prototypes and golden blast radius

Rev 1's variants (the planner's, kept as measured):

Each variant was relinked from the trunk objects plus the patched translation
units, then run on the probes, the full file_test gate in test mode from this
worktree (1942 files; trunk passes 1942) and the conformance runner (trunk:
128 PASS / 0 FAIL / 22 SKIP over 150, 48 of 56 bullets):

| Variant | Adds | Probes | Gate | Conformance |
| --- | --- | --- | --- | --- |
| v1 | RC-1, RC-2, RC-3 check fixes (A1 to A4) and RC-5, RC-6 lowering fixes (B1, B2) | PR-AK `4 5`, X18 `5`, X28 without a call compiles; X29 to X33 move to lowering crashes | not run | not run |
| v2 | RC-7 (B3, B4) and RC-6's second half (A5) | X29 `8`, X30 `10`, X31 `8`, X32 `6`, X33 `9`, s11 `11`, s15 `2`, s22 `6`, s30 `4`, s34 `5` | 1940 of 1942: generic/template/convert.carbon and unimplemented.carbon change only `convert_to_category_action %x, element1` to `convert_to_value_action %x, <type>` (autoupdate in a scratch mirror: 6 and 12 changed CHECK lines) | 128/0/22 |
| v3 | v2 plus upstream bf91a8b4d (`sem_ir/typed_insts.h` and the six translation units that read `ImplSelfWitness`'s constant kind recompiled) | RC-4 unchanged | not run | not run |
| v4 | X17 and W-193 (call.cpp), RC-8 (import_ref.cpp) | X17 `8`; `Holder(T)` `42`, `Holder(T)*` `5`, `Vec(N)` `3`, a template class argument `9`; the cross-library pair reports `semantics TODO: Unsupported: using a template from another library` and `use of undefined generic function`, no crash | 1937 of 1942: also class/destroy_calls.carbon, generic/template/call.carbon (its `fail_todo` split now succeeds; the other split now fails for the right reason) and lower/testdata/template/class.carbon (one SSA name) | 128/0/22 |
| v5 | W-183 (member_access.cpp) | R09 `25`; with `extend impl` `25`; a type-only member beside a constraint member `72`; a field `9`; X21 rejected with the prototype's note | 1937 (no new change) | 128/0/22 |
| v6 | W-127, first form: accept the deferred witness for a template query | X20 `5`, X23 `6`; but the dump of interop/cpp/template/generic_call.carbon shows the `final impl forall [T: Default]` selected in the definition with a deferred `Default` witness -- an impl chosen before the argument is known | 1935 | not run |
| v7 | W-127 as specified: no impl is selected for a template query in the definition | X20 `5`, X23 `6`; tuple `var y: T;` rejected on instantiation exactly as `var y: (i32, i32);` is without a template | 1935: also facet/period_self.carbon (its `fail_todo` split's first error changes) and interop/cpp/template/generic_call.carbon | 128/0/22 |
| v8 | RC-4 (A6) | every `for` form runs: X28's array `6`, `Core.Range(c.n)` `6`, a member array `12`, `array(i32, N)` `6` | 1934: also interop/cpp/range_for.carbon (34 added CHECK lines: the cursor pointer's `require_complete_type` in checked-generic loops) | 128/0/22 |
| v10 | v8 with upstream 4a8993af2 in place of A4 | every template `for` loop: `CHECK failure at toolchain/check/pending_block.h:89: cleanups_.empty()` | not run | not run |

At v8, 52 of the 59 runnable probes ran with their hand-derived values. The
v8 patch (`$P/tp1-proto-v8.diff`) has 12 files, +268/-33 (rev 1 said 13
files; amended 2026-10-14, review fold: B-m2). Review A rebuilt v8
byte-identically and found the RC-5 family it does not fix (§0.3).

Rev 2's variants (the fixer's, `$X`; amended 2026-10-14, review fold: A-B1 /
A-M1 / A-M4 / B-M5 / A-m2 / A-m4 / B-m2). v12 is v8 with D-TP-3 replaced (the
copied storage access chain instead of A4's `InsertHere`), `SameMemberEntity`
rewritten (D-TP-13), D-TP-12 narrowed to queries that name a template binding,
and D-TP-14 moved to the `import` with the cascade suppressed; v13 adds
D-TP-23's stringification. The v13 patch is `$X/v13.diff` (14 files,
+513/-37 with comments; `$X/v12.diff` plus `$X/v13-stringify.diff`).

| Variant | Adds | Probes | Gate (1942 files) | Conformance |
| --- | --- | --- | --- | --- |
| v12 | the rev 2 C1, C2 (import), C3 (callee rule), C4 and C5 prototypes | the whole matrix of §0.6: every DD-1 and review A form runs except RC-10 (s32), RC-12 (n01, n02), RC-13 (b04*, h03, h03c) and RC-9 (f01, f02); X21, a03 (Cowboy), a09 (a field beside a constraint method), a10, a11 rejected on instantiation | 1936: generic/template/convert.carbon, unimplemented.carbon, call.carbon, class/destroy_calls.carbon, interop/cpp/range_for.carbon, lower/testdata/template/class.carbon; facet/period_self.carbon and interop/cpp/template/generic_call.carbon no longer change | not run |
| v13 | v12 plus stringify.cpp (D-TP-23) | as v12; mool's message prints ``type `<pattern for T.U>` ... differs from previous parameter type `<pattern for T.U>` `` | 1935: also generic/template/member_out_of_line.carbon (two STDERR lines, the `<cannot stringify ...>` text becomes `T.U`) | 128/0/22 over 150 |
| vc1 | v13's C1 objects only | | 1939: convert.carbon, unimplemented.carbon, range_for.carbon | |
| vc12 | v13's C1 and C2 objects | | 1938: also member_out_of_line.carbon | |
| vc123 | plus call.cpp with only C3's callee rule | | 1937: also call.carbon | |
| vc1234 | plus v13's call.cpp and impl_lookup.cpp (C4) | | 1935: also class/destroy_calls.carbon and lower/testdata/template/class.carbon (C5 adds none) | |
| scv13, scv13b | v13 over SC-1's sources, relinked over the SC-1 build | R09 25, X21 and a09 rejected, b09b 7, X20 5, X25 42, e01 4, n04 as without templates, r28 6 | §0.9 | |
| vav13 | v13 over VA-1's sources, relinked over the VA-1 build | | §0.9 | |
| M2, M3, M15, M16 | mutants of v13 | §8.5 | | |
| v14 | v13 plus D-TP-24 in convert.cpp (`$Y/v14.diff`, 14 files, +578/-40; amended 2026-10-14, review fold: RR-M1) | the RC-12 value forms run (§0.3); n01 and t02 do not (W-264); no other probe changes (§0.6) | 1935, the same seven files with byte-identical failure output; the new initialize.carbon splits autoupdate with no crash, and every other new golden of Appendix A autoupdates identically to v13 | 128/0/22 over 150 |
| g, m20 | measurement-only variants of v14: g diagnoses RC-10's shape (§0.3, §7.2(11)); m20 drops `HasSameFieldNames` (§8.5) | g: k01 and k07 rejected; m20: t13's error moves to instantiation, t13b compiles | g: 1934 (also tuple/class_tuples.carbon) | |

The attribution rows give each commit's "red exactly on" set of §3 (C1: convert,
unimplemented, range_for; C2: member_out_of_line; C3: call; C4: convert,
destroy_calls and lower/template/class, convert.carbon's `class_type` lines
being C4's; C5: none; (amended 2026-10-14, implementation-review fold:
IR2-MINOR-3)) from linking v13's objects per commit; rev 1 attributed
lower/testdata/template/class.carbon to C1, which the measurement contradicts
(B-m2). New goldens add their own files. C3's four action kinds and C5's
diagnostic kind were not relinkable (`sem_ir/inst_kind.def` and
`diagnostics/kind.def` are X-macro lists included by most translation units) and
are hand-predicted in Appendix D; the six DD-1 forms that need them (X13 to X16,
X19, X24) are the only fixtures that fail with v13 under PR 58's checker (§2.9).

Measured at implementation (amended 2026-10-14, implementation: measured):
each commit is red alone exactly on these sets and its new goldens, except
that two of Appendix A's splits need C4 and are added by C4, not C3
(index.carbon's `index_class_with_index_with` and pointer.carbon's
`fail_deref_class_type_param`), so C4 alone is also red on index.carbon and
pointer.carbon (§8, "Measured at implementation").

At the implementation-review fold (amended 2026-10-14, implementation-review
fold: IR1-B1), the first fix commit (7c7b1b170) refills one more trunk golden,
lower/testdata/template/merging.carbon: a constant splice now lowers the
instructions of its block that are not constant (D-TP-25), so `({} as T).F()`
allocates the `{}` temporaries that the same code without a template allocates
(measured: the non-template `({} as A).F()` lowers to the same `alloca {}` and
lifetime start). TP-1 refills eight trunk goldens in all; the second fix commit
(12bd6d67a) changes none.

New golden sources (Appendix A) were run through v13's `file_test
--autoupdate` by writing each into a path that is in the trunk build's
manifest, in a scratch mirror (`$X/bin/au_carrier.sh`; `file_test` runs only
the files its build listed): every C1, C2, C4 and C5 split checks, fails or
lowers as §4 says, with the prototype's `semantics TODO` note in place of C5's
`TemplateMemberLookupAmbiguous`.

### §0.9 Collisions

Merge order of record (fork/ORCHESTRATION.md, 2026-10-14 14:00): PR 53, PR 51,
PR 52, SC-1, PR 54, PR 55, PR 56, PR 57, PR 58 through its state-L
integration commit, then PR 59. TP-1 lands after all of them (D-TP-19).
Rev 2 re-ran every collision against each branch's head as of 2026-10-14
(amended 2026-10-14, review fold: A-m5 / B-M6): SC-1 is at b3bb7bf31 (round
14's records; its toolchain equals 9197882e5's, which review A cited, and
0d596103e, which review B cited, is the round-14 fill before it), VA-1
(PR 59) at b0822a744, OP-2 (PR 57) at 628273444, UA-2 (PR 51) at f96fe8a7a,
DD-1 (PR 58) at fcee90d9b. The measured v13 patch was dry-run (`patch
--dry-run`) onto each branch's copy of its fourteen files; the hand-predicted
files of C3 and C5 were compared hunk by hunk with each branch's diff from
b2576f6c3; and v13 was composed over SC-1's and VA-1's sources and relinked
over their own builds (`/home/user/carbon-build/carbon-sc`, whose objects are
SC-1's 55d77c5e1, toolchain-identical to b3bb7bf31 except one golden;
`/home/user/carbon-build/carbon-va`, VA-1's head), then gated over each
branch's own testdata (`git archive` into `/dev/shm/tp1-fixer/mirror-sc` and
`mirror-va`). The dry run and the gate are repeated at the merge M against the
heads of that day.

| Branch | Measured v13 files | Hand-predicted files (C3, C5) | Composed and gated | Composition rule at M |
| --- | --- | --- | --- | --- |
| SC-1 (b3bb7bf31) | convert.cpp (SC-1 +101): six of seven hunks apply, `PerformAction(ConvertAction)` fails; call.cpp (+14), impl_lookup.cpp (+57), import_ref.cpp (+87), member_access.cpp (+342, offset 148), stringify.cpp (+20) apply | member_access.cpp `PerformTupleAccess` (SC-1's D-SC-20 error return right after `ConvertToValueOrRefExpr`, :1189-1195); typed_insts.h (+18), inst_kind.def (+1, `StructuralRequirementType`), diagnostics/kind.def (+13): different lines; handle_binding_pattern.cpp is no longer touched (D-TP-15 dropped) | as specified in §2.5, scv13: 1943 of 1959 (16 files: TP-1's 7 and 9 of SC-1's template-constraint goldens, where `x.Get()` on a `template constraint` parameter is rejected as "different entities"); with the rule at the right, scv13b: 1952 of 1959, only TP-1's 7 | SC-1's `CheckConversionIsNotOfStructuralRequirement` call stays the first statement of `PerformAction(ConvertAction)` and `(ConvertToCategoryAction)`, then A2's `PendingBlock` (M's resolution of that textual conflict keeps both sides' statements, SC-1's first, and adds none; measured in scv13); C5's constraint lookup returns `None` when the member it finds is a `template constraint` requirement (SC-1's `GetStructuralRequirementRef`), because the type's own member satisfies the requirement and is the entity, so the type lookup decides (measured in scv13b, §2.5); that rule is new code, so it is commit S right after M, not part of M (amended 2026-10-14, review fold: RR-m2); C3's `TupleIndexAction` test goes before `ConvertToValueOrRefExpr` and SC-1's D-SC-20 return stays after it, and `PerformAction(TupleIndexAction)` calls `PerformTupleAccess`, which runs SC-1's check on the concrete operand; C3's and C5's X-macro lines go in alphabetical order beside SC-1's |
| PR 59, VA-1 (b0822a744) | convert.cpp (+114), call.cpp (+194, one hunk with fuzz 1), import_ref.cpp (+40), lower/function_context.cpp (+23), stringify.cpp (+11): all apply | handle_name.cpp: VA-1 changes `IdentifierNameExpr` (:136-150), C3 the `PointerMemberAccessExpr` handler (:47-90): different functions; typed_insts.h (+125), inst_kind.def (+8 `Pack*` kinds before `PartialType`; C3's `PointerDereferenceAction` goes between `PatternType` and `PointerType`, two unchanged lines away), diagnostics/kind.def (+19): different lines | vav13: 1953 of 1960, only TP-1's 7 | textual only |
| PR 57, OP-2 (628273444) | convert.cpp (+7), lower/handle.cpp (+52): apply | none | not composed (no shared function) | textual only |
| PR 51, UA-2 (f96fe8a7a) | none | none | not composed | C4's W-127 fix makes PR 51's split `fail_todo_unformed_dependent_var` in interop/cpp/template/dependent_var_full_prelude.carbon succeed: F6 renames it `unformed_dependent_var` and refills it (§3) |
| PR 58, DD-1 (fcee90d9b) | none in toolchain | none | n/a | the land-time integration commit L (§2.9, Appendix C) |
| PR 52, 53, 54, 55, 56 | none in check or lower (PR 55 touches check/cpp/export.cpp only) | none | n/a | none |
| OX-1 (parked) | none merged | none | n/a | none |

Which goldens refill at M: none of SC-1's or VA-1's under the composition rules
above (measured); TP-1's seven refills of §4 recur on the merged tree; PR 51's
split renames. DD-1's R09 and X21, as fixtures and as `$P/runs` programs, give
the same result on v13, scv13b and vav13: R09 compiles and prints `25`, and X21
is rejected with ``unable to monomorphize specific `G(C as A)` ``
(`$X/sc-r09-x21.log`). Records at M: TP-1's branch has changed no ledger,
decision-log, gap-analysis or ORCHESTRATION text before M (R and D come after
it, §3), so those files take the merged trunk's text without conflict;
fork/conformance/README.md conflicts only in its generated program table, which
F6 regenerates with `python3 fork/conformance/runner.py --update-readme-table`
and checks with `--self-test`.

**Composition at state T, 2026-10-14, SC-1 head a35535174, VA-1 head b0822a744
(amended 2026-10-14, implementation: held state).** M merged no PR (§1.12), so
the dry run and the compositions that §3 places at M were measured on copies,
with the whole of TP-1 at the branch head 6efc3f257 rather than v13. The full
TP-1 diff (`git diff b2576f6c3..6efc3f257 -- toolchain core`: 45 files, 25
sources, 13 new goldens and the seven refills of §4) was dry-run with `patch`
onto a `git archive` of each branch head and then applied there. Every
translation unit that includes a changed file (by the branch build's `ninja -t
deps`; 270 of 320 translation units on SC-1 and 271 of 321 on VA-1, because
inst_kind.def and diagnostics/kind.def are X-macro lists) was compiled from the
composed sources and relinked over the rest of the branch's own objects into
`/dev/shm`. SC-1's build is `/home/user/carbon-build/carbon-sc`,
0.0.0-0.dev+5d778d044, whose toolchain equals a35535174's (the commits after it
change one golden and records); VA-1's is `/home/user/carbon-build/carbon-va`,
0.0.0-0.dev+88b1b5bd2, whose toolchain equals b0822a744's. Each composition was
gated twice: over the branch's own testdata (a `git archive` mirror, with the
branch build's manifest) and over the composed testdata (the branch's goldens
plus TP-1's 13 new and 7 refilled ones, with a manifest that adds the 13). The
mirrors were deleted after the measurement (`$I/stage4/comp/`, the logs).

| Composition | Dry run of the TP-1 diff | Gate, branch's testdata | Gate, composed testdata | Programs and fixtures |
| --- | --- | --- | --- | --- |
| SC-1 a35535174, without S (the M state; mutant M18) | 45 files: convert.cpp's hunk for `PerformAction(ConvertAction)` and `(ConvertToCategoryAction)` fails, as above, and is resolved by the rule (SC-1's check first, then A2's `PendingBlock`); member_access.cpp's two include hunks fail (SC-1 already includes `<variant>`; `pointer_dereference.h` goes beside SC-1's `structural_conformance.h`); every other hunk applies, with offsets, and member_access.cpp's `PerformTupleAccess` hunk with fuzz 2, before SC-1's D-SC-20 return as the rule requires | 1943 of 1959: TP-1's seven refills and nine SC-1 goldens (interop/cpp/class/import/template_constraint.carbon, seven named_constraint/template_constraint*.carbon, lower/testdata/template/template_constraint.carbon), whose splits now report `TemplateMemberLookupAmbiguous` for a requirement | 1963 of 1972: the same nine | the eight programs print their EXPECT lines; R09 prints `25`; X21 is rejected with the `TemplateMemberLookupAmbiguous` note |
| SC-1 a35535174, with S (§2.5's text) | the same tree, with S in `LookupMemberInTemplateConstraint` | 1952 of 1959: only TP-1's seven refills (scv13b's result) | 1972 of 1972 | as without S |
| VA-1 b0822a744 | 45 files apply, with offsets; two hunks with fuzz 1 (call.cpp's in `PerformCallHelper`, inst_kind.def's `PointerDereferenceAction` line), each at its place | 1953 of 1960: only TP-1's seven refills | 1973 of 1973 | as on SC-1 |

The rules of the table above hold at state T: M composes with SC-1 by the
convert.cpp rule and with VA-1 textually, and S restores SC-1's nine goldens,
so mutant M18 (S reverted) is killed. With TP-1's own fills in the composed
trees, every golden passes on both branches, so at state T F6 has nothing to
refill on SC-1 or VA-1: TP-1's seven refills apply unchanged, and no SC-1 or
VA-1 golden changes. PR 51's split is not on either branch, so its rename is
measured at land time. Each branch's build passes its own mirror (SC-1 1959
of 1959, run after SC-1's round 17 had rebuilt it; VA-1 1960 of 1960).

**Composition at the implementation-review fold, 2026-10-15, SC-1 head
1646988dc, VA-1 head b0822a744 (amended 2026-10-14, implementation-review
fold: IR1-B1 / IR1-M1 / IR1-M2 / IR1-m2 / IR1-m3).** The fold's fix commits
change import_ref.cpp and stringify.cpp, which SC-1 and VA-1 also change,
function_context.cpp, which VA-1 changes, and member_access.cpp (a comment),
which SC-1 changes, so the compositions were measured again by state T's
method with the whole of TP-1 at the fold's head f360b8735 (`git diff
b2576f6c3..f360b8735 -- toolchain core`: 47 files, 26 sources, 13 new goldens
and the eight refills). SC-1's head had moved to 1646988dc (records after
round 17), and its build `/home/user/carbon-build/carbon-sc`,
0.0.0-0.dev+866468cba, has 1646988dc's toolchain (the commits after
866468cba change goldens and records); VA-1's head and build are state T's.
The dry runs reproduce state T's: on SC-1, convert.cpp's hunk for
`PerformAction(ConvertAction)` and `(ConvertToCategoryAction)` fails and is
resolved by the rule, member_access.cpp's two include hunks fail
(`pointer_dereference.h` goes beside `structural_conformance.h`) and its
`PerformTupleAccess` hunk applies with fuzz 2 before SC-1's return, and every
other hunk applies; on VA-1 every hunk applies, two with fuzz 1. The 270 and
271 affected translation units were compiled from the composed sources and
relinked over each branch's objects in `/dev/shm`, deleted after the
measurement (`$I/fixer/comp/`, the logs; `$I/fixer/comp.log`).

| Composition | Gate, branch's testdata | Gate, composed testdata | Programs and fixtures |
| --- | --- | --- | --- |
| SC-1 1646988dc, without S (M18) | 1942 of 1959: TP-1's eight refills and the same nine SC-1 template-constraint goldens as at state T | 1963 of 1972: the same nine | the nine programs print their EXPECT lines |
| SC-1 1646988dc, with S | 1951 of 1959: only TP-1's eight refills (a first run also failed interop/cpp/modules/import.carbon's C++ module split, over a `TEST_TMPDIR` copied from the run without S; the file passes alone, and a re-run of the whole gate over a fresh one gives 1951 of 1959 with only the eight refills red) | 1972 of 1972 | the nine programs print their EXPECT lines; R09 prints `25`; X21 is rejected with the `TemplateMemberLookupAmbiguous` note |
| VA-1 b0822a744 | 1952 of 1960: only TP-1's eight refills | 1973 of 1973 | the nine programs print their EXPECT lines; R09 prints `25`; X21 is rejected with the `TemplateMemberLookupAmbiguous` note |

The rules hold at the fold as at state T: S restores SC-1's nine goldens
(M18 killed), every golden passes on the composed trees, and F6 has nothing
to refill on SC-1 or VA-1 beyond TP-1's own eight refills, the fold's
lower/template/merging.carbon among them.

### §0.10 What the arbiter's third clause means

"A template function executes in the run harness" means a conformance program
under the bullet that calls a function with a `template` parameter, compiles,
links, runs and prints its EXPECT. Trunk meets it with templates_type_param
and templates_value_param, and PR 51 adds templates_dependent_member. The
slice's programs (§1.10) extend it to every form it implements.

### §0.11 TODO pins under generic/template/

Added 2026-10-14 (review fold: B-M3). The directory holds four `fail_todo`
splits and two `todo_fail` splits (`.agents/skills/toolchain_tests/SKILL.md`:99,
"should produce errors but does not"):

| Golden | Split | Pins | After TP-1 (v13) |
| --- | --- | --- | --- |
| unimplemented.carbon | `fail_todo_unimplemented_operator` | `*x.n` rejected in the definition | compiles; renamed `deref_dependent_member` (C3, predicted) |
| unimplemented.carbon | `fail_todo_unimplemented_value` | `*c.n` with `template c: C` rejected | compiles; renamed `deref_dependent_value` (C3, predicted); `*c.n` uses a dependent value, so proposal 2200 checks it on instantiation |
| call.carbon | `fail_todo_dependent_call_nonconst_arg` | `H(x)` with `H: G` not callable | succeeds (measured, vc123); renamed `dependent_call_nonconst_arg` |
| member_out_of_line.carbon | `fail_todo_basic` | an out-of-line redeclaration whose types differ from the declaration (`T` and `T.U`), reported with `<cannot stringify ...>` | still fails, correctly (p3763), with the types printed as `T.U` (D-TP-23, measured); renamed `fail_basic` |
| operator.carbon | `todo_fail_assign_const` | `t.x = 456` through `ref t: T` on a `const C` accepted | unchanged (still accepted, measured by the gate); filed W-259 |
| operator.carbon | `todo_fail_assign_let` | `T.x = 0` on a class `let` accepted | unchanged; filed W-259 |

The two `todo_fail` splits are soundness gaps: an assignment whose left
operand is template-dependent is not checked on instantiation for being an
assignable reference. Checking it needs an assignment action (a fifth action
kind of C3's shape), which is outside this slice; they are filed, named in the
row residue and listed on the page (Appendix C).

## §1 Design

### §1.1 Proposal 2200's rules, each IN or OUT of this slice

Numbered TR-n so the reviews and §1.13 can cite them. IN means implemented and
covered by a golden or a program in §4 and §5; OUT means left diagnosed (by
the existing diagnostic or a new `semantics TODO` with a golden) and filed.

1.  TR-1. A `template` binding in a deduced, explicit or class parameter
    list; each instantiation is checked and lowered (p002200:232-270).
    **IN** (exists; kept working: X22 and the three trunk programs).
2.  TR-2. Expressions that are not template dependent are checked at the
    definition (:735-737). **IN** (exists; every eager path below is
    unchanged for non-dependent operands, measured by the gate).
3.  TR-3. Template-dependent expressions are type checked when the template
    is instantiated, with monomorphization errors (:720-725). **IN** for the
    forms of TR-4 to TR-12.
4.  TR-4. Use of a dependent value is dependent: `F(expr)`, `expr + 1`,
    `a as expr` (:864-881). **IN**: initialization and copy of a dependent
    value (RC-1, RC-2, X18), returning dependent aggregates (X29 to X32),
    destructuring (X33), `for` over a dependent range (X28), nested
    aggregates built from template calls (review A's b09 to c5), and class,
    union and array values built from them (the re-review's r2 to r9,
    D-TP-24); except a template-dependent in-place initializer of a storage
    root that is allocated after it, which leaves the `for` cursor and a
    class value with a defaulted field (amended 2026-10-14, review fold: A-B1
    / RR-M1; RC-12, W-264), and the forms that RC-10 stops on or compiles
    wrongly with or without templates (amended 2026-10-14, review fold:
    RR-M2; W-256). A tuple or struct type whose element is a produced type,
    such as `(T.Elem, i32)`, is IN (amended 2026-10-15, focused re-review of
    the fold: RR1-M2). Also excepted (amended 2026-10-15, focused re-review
    of the fold: RR1-m3 / RR1-m5): destroying the temporaries that an action
    creates on instantiation (a `var` parameter's copy of `x`, a temporary
    class value), which are never destroyed, as on trunk (W-267); and a
    dependent `as` conversion to a class without `Copy` that is returned,
    `return {} as T;`, which forms a value that the return then copies, as on
    trunk (W-269).
5.  TR-5. The pointer operators on a dependent operand: `*`, `->`, `&`
    (:864-881 by the same rule). **IN** (C3).
6.  TR-6. Tuple element access and indexing on a dependent operand. **IN**
    (C3).
7.  TR-7. Calling a value whose type is template dependent (:735-737's "a
    function may have a value that is function dependent, but calling that
    function only needs the type of the function"). **IN** (C3, D-TP-10).
8.  TR-8. Simple member access looks in the argument's type and in the
    constraint; if both find the name, they must find the same entity
    (:200-202, :433-441, :476-503, :739-768). **PARTIAL** (amended
    2026-10-14, review fold: A-M2): IN on instantiation for an access through
    a value whose type in the definition is the parameter (`x.F`, `p->F`),
    with a field, a constant and a function each compared by entity (C5,
    W-183); OUT through a field whose declared type is the parameter (W-266;
    (amended 2026-10-14, implementation-review fold: IR1-M3), written into
    this rule 2026-10-15, focused re-review of the fold: RR2-m5); OUT where
    the constraint gives the access
    its meaning at the definition (:744-752: `let b: bool = x.F();` for an
    `F` returning `i32` is accepted in an uncalled definition, review A's
    a13; W-260), where two interfaces of the constraint declare the name
    (:766-767, a12; W-261), and for the type-level `T.F()`, which calls the
    constraint's `F` without comparing it with the type's own (a05; W-262).
9.  TR-9. Compound member access `x.(I.F)` is checked at the definition when
    the constraint implies it (:769-831). **IN** (exists; X21's `x.(A.F)()`
    part).
10. TR-10. Impl lookup is delayed until all template arguments are known
    (:198-199, :832-863). **IN** for the facet conversions that need it (C4,
    W-127); TR-10's finer rule that an impl lookup whose validity alone is
    dependent is "template validity dependent" is not distinguished from
    "dependent" in the 0.1 toolchain (no observable difference in a
    program; D-TP-12). An impl lookup on a produced type, such as the
    `Core.DefaultOrUnformed` conversion of `var e: T.Elem;`, is still made
    where the function is defined and rejects it, as on trunk (W-268;
    amended 2026-10-15, focused re-review of the fold: RR1-m4).
11. TR-11. A template parameter is deduced as a checked one is, including
    through a class's arguments (:186-191, "In many ways, template generic
    parameters work like checked generic parameters"). **IN** (C4, W-193).
12. TR-12. Validity can depend on value (:702-710): array types with a
    template-dependent bound compare on instantiation. **IN** where it
    already works (s29, s31 run on trunk); initializing an array with a
    template-dependent bound from a list is **OUT** (X11, W-253), except in a
    class template's literal whose class's fields hold such an array, which
    is converted on instantiation, as on trunk, where the class type was a
    deferred call (amended 2026-10-15, focused re-review of the
    fold: RR2-1-M2).
13. TR-13. `match` over a dependent value, each case body dependent
    (:883-902). **OUT** (X10, W-252; the `match` machinery's own scrutinee
    support is the blocker).
14. TR-14. `auto` and template `let` bindings (:327-347, :232-270). **OUT**
    (W-039, W-031; unchanged).
15. TR-15. Template constraints (:348-432). **OUT** of this slice (SC-1,
    W-027).
16. TR-16. Branching on type identity and specialization (:271-277,
    :935-1001). **OUT** (unchanged; no residue is new).
17. TR-17. A template used from another library (implied by TR-1; the
    toolchain's own TODO at lower/handle.cpp:507-513). **OUT**, diagnosed at
    the `import` (W-250, D-TP-14; amended 2026-10-14, review fold: A-m4): a
    function or class template whose declaration, definition, field types or
    member function declarations hold an action, and an interface or named
    constraint whose declaration holds one (amended 2026-10-15, focused
    re-review of the fold: RR1-M1 / RR2-M1). An interface or named constraint
    whose later parameter's type depends on a template parameter stops the
    compiler in its own library when it is used, as on trunk (W-270). An
    entity whose declaration, definition or bindings name such a template,
    interface or constraint is diagnosed the same way: a nested generic class
    with such a field, a function whose declaration or body names such a
    class, and a deduced parameter, a class or impl parameter or an interface
    member's parameter constrained by such an interface (amended 2026-10-15,
    focused re-review of the fold: RR2r2-M1), and an entity that names one
    through a concrete operand, such as a call of a function template, a
    class template as a specific's argument, a tuple or struct element or a
    field type, a constraint's argument or rewrite, or a blanket impl's
    witness (amended 2026-10-15, focused re-review of the fold: RR3-1-M1 /
    RR3r2-M1). A generic class from another
    library that declares a nested class or interface and whose data names no
    action stops the compiler where the class is used, with or without a
    template parameter, as on trunk and the nightly (W-271; (amended
    2026-10-15, focused re-review of the fold: RR2r2-M1)).
18. TR-18. A form parameter, `template Fm: Core.Form` or
    `generic Fm: Core.Form` (the forms feature, not proposal 2200). **OUT**,
    unchanged: lowering a call still stops the compiler for both spellings
    (W-255; amended 2026-10-14, review fold: A-M3).
19. TR-19. `partial T*` for a template `T` (the class/partial test's own
    TODO). **OUT** (X26, W-251).
20. TR-20. An out-of-line redeclaration of a template class's member whose
    signature names a template-dependent type matches a token-identical
    declaration (p3763). **OUT** (`$P/probes/mool.carbon`, W-254; amended
    2026-10-14, review fold: A-m2). A redeclaration that does differ is
    rejected, as p3763 requires, and since D-TP-23 its diagnostic prints the
    dependent types (`member_out_of_line.carbon`, renamed `fail_basic`).
21. TR-21. An assignment's left operand is an assignable reference, checked
    on instantiation when it is template dependent. **OUT** (operator.carbon's
    two `todo_fail` splits, W-259; added 2026-10-14, review fold: B-M3).

### §1.2 Crash and miscompile fixes (C1, C2)

**D-TP-2 (A1): a template-dependent operand initialized into storage of the
same type is deferred as a storage-carrying `InitializeAction`.** In
`AddConvertActionIfDependent` (convert.cpp:2312), the same-type early exit is
narrowed: when the target is an initializer with storage and the operand is
not already an initializer, the function continues to its dependence test and
its existing `InitializeAction` branch (:2335-2391), which records the
storage and, on instantiation, runs builtin, user-defined and category
conversion with that storage (`PerformAction(InitializeAction)`, :2474-2520).
How a value of type `T` is copied (element by element for a struct, tuple or
array; through `Core.Copy` otherwise) is decided on instantiation, which is
TR-4. This removes RC-1 and RC-2 and makes X18's struct copy work. _Break
condition:_ a non-template initialization changes (measured on v13's C1
objects alone, vc1: the only goldens that change are the two dependent value
conversions of D-TP-6 and the cursor completeness of D-TP-8).

**D-TP-3 (A4, rewritten 2026-10-14, review fold: A-B1): an
`InitializeAction` carries a copy of the instructions that compute its
storage, and each specific places the copy where its initialization needs
it.** When `AddConvertActionIfDependent` creates the action, the instructions
of the pending storage access block that `target.storage_id` depends on
(element accesses such as `tuple_access %return.param, element0`, an outer
element's access, an `ArrayIndex` with its `IntValue` index, an
`AsCompatible`) are copied, in block order and with their operands remapped to
the copies, into a `SpliceBlock` that is in no block; the action's storage is
the `InstValue` of that block (4a8993af2's representation, carried in the
existing `InitializeAction::Target::storage_id`). The originals stay pending,
so the template's body uses them as it would without the action: the next
element's conversion or the enclosing `*_init` inserts them, and an element
access that nothing else uses is dropped by `ConvertAggregateElement`'s
`DiscardUnusedInstsScope`. On instantiation `PerformAction(InitializeAction)`
puts the copies into its own storage access block before the `SpecificInst`
of the copied storage, so they land in place of the initializer's temporary
(`MergeReplacing`) or before the specific's `*_init` (`InsertHere`), exactly
where a concrete initialization puts them. A storage root (`VarStorage`,
`TemporaryStorage`) is never copied, because it is one object that the body
also names: a root that precedes the initializer (a `var`'s, the return
slot) is used as it is, and a root that is still pending (the `for` cursor's,
a value conversion's temporary) is inserted with its cleanups where the
action is created, before the action's splice. This removes RC-5's first
defect and review A's RC-5 family (b09 to c5 run on v13; mutant M2, which
restores rev 1's placement, crashes b09b, c1 and c3 again). _Break
condition:_ a template-dependent in-place initializer of a pending root
whose initializer has its own temporary in the specific (RC-12): the
rewritten temporary names a root that comes later. The three value
temporaries are such roots, and D-TP-24 removes them by deferring their
whole conversion; the `for` cursor is the one left, and its fix is to
allocate it before its initializer, not to change this rule (W-264; amended
2026-10-14, review fold: RR-M1).

**D-TP-24 (A7, added 2026-10-14, review fold: RR-M1): a template-dependent
conversion that would allocate its own temporary for an aggregate value is
deferred whole.** `ConvertTupleToArray` (without storage), and
`ConvertStructToUnion` and `ConvertStructToClass` (for a value) return the
source unconverted when the source or the target type is template dependent
(`IsTemplateDependentValueTemporary`, §2.1), so that `Convert`'s
`AddConvertActionIfDependent` defers the whole conversion as one
`ConvertToValueAction` (or a `ConvertAction` for `as`). On instantiation
`PerformAction` repeats the builtin conversion with concrete types, so the
temporary is allocated in the specific, where the elements' initializers
are, and `MergeReplacing` moves it into an element call's temporary exactly
as for the same code without a template. The definition-time checks stay
where they are: the array's bound and element count are checked before the
early return; a union's designated field is checked before it; and a class
value is deferred only when the source names exactly the class's fields
(`HasSameFieldNames`), so a missing or unexpected field is still diagnosed
where the function is defined (t13, t13b, t18, t19 on v14). `get_default`
finds the struct literal through a `SpecificInst`, as
`GetAggregateLiteralElements` does. This removes RC-12 for the three value
temporaries (§0.3: r2, r4, r8, r9, n02, t01, t03, t04, t10, t11 run on v14).
Proposal 2200 checks a use of a dependent value when the template is
instantiated (:864-881), and the source here is such a value; deferring the
conversion that builds the temporary changes no non-dependent check (gate
unchanged). _Break condition:_ a non-template conversion, or a template
conversion that is not template dependent, changes (measured: the v14 gate's
failure output is byte-identical to v13's, and every other new golden
autoupdates identically).

A class initializer whose class's fields hold an array with a
template-dependent bound is deferred whole too (amended 2026-10-15, focused
re-review of the fold: RR2-1-M2). C4 forms `C(N)` in the definition (D-TP-11),
where trunk deferred it as a call, so a literal such as `var c: C(N) = {.a =
(1, 2, 3), .b = N};`, or `return {.a = (4, 5, 6), .b = N};` from `-> C(N)`,
was converted there field by field and reached `ConvertTupleToArray`'s
`ArrayInitDependentBound`; trunk and the nightly compile and run both
(round 2's b04b and b12). `ConvertStructToClass` returns such an initializer
unconverted when its fields are exactly the class's
(`HoldsTemplateDependentArrayBound`, through struct, tuple, array and class
fields), so `Convert` defers it as one `InitializeAction`; a struct, tuple or
array that holds such a class converts it as its element, so it is deferred
the same way. (b678e2985 also deferred such an aggregate whole, because an
element deferred inside an aggregate converted in the definition stopped
lowering at value_store.h's CHECK; that crash is the one `NeedsSpecificInst`
fixes, below, and with that fix the aggregate test changed only value names,
so f44280c1c removes it.) The array's own literal, `var a: array(i32, N) =
(1, 2, 3);`, and a struct or tuple literal that holds one directly stay
W-253, as on trunk. The fixer's probes of the rule found that a deferred
conversion of a runtime literal with a template value element, `let p: P(N) =
{.a = x, .b = N};` for a class template `P` without arrays, already stopped
lowering at 764e55445 (value_store.h's CHECK; trunk at an inst.h cast): the
literal is not symbolic, so the action referred to it without a
`SpecificInst`, and `N`, template dependent in the generic, was converted by a
second action created inside the specific, which lowering cannot resolve.
`NeedsSpecificInst` (action.cpp) now also wraps a struct or tuple literal one
of whose elements needs it, so its elements are the specific's values.
Measured: b04b, b12 and the fixer's f01 to f32, g33 to g39 and h1 to h7 run
with their twins' values, except f04, f05, f17, f18 and f20, a constant
nested aggregate whose non-template twins f21 and f22 fail LLVM verification
on all three toolchains (W-263); a wrong element count is reported on
instantiation and an unknown field where the function is defined.
deduce_class_args.carbon's four new splits, lower initialize.carbon's six and
two lines of templates_deduce_class_args pin it; mutants M36 and M40 (M37 to
M39, which removed the aggregate test from each of its three uses, changed
lower initialize.carbon in value names only).

**D-TP-4 (A2): an action that replays an initializing conversion supplies its
own storage access block.** `PerformAction(ConvertAction)` and
`PerformAction(ConvertToCategoryAction)` construct their `ConversionTarget`
with a local `PendingBlock` and insert it after the conversion, as
`Initialize` does (convert.cpp:2738-2751). `ConversionTarget`'s contract
(convert.h:61-74) and :588, :781, :879, :918, :1023, :1036, :1144 and :2198
dereference `storage_access_block` for every initializer. This removes RC-11
(review A's e01: v13 prints 4; mutant M3, without A2, segfaults; amended
2026-10-14, review fold: A-m1 / B-M4). _Break condition:_ none; this restores
an invariant.

**D-TP-5 (A3, B4): `FindStorageArgForInitializer` takes the specific it is
evaluated in, and an unresolved splice has no storage argument.** The
function gains `SpecificId specific_id = SpecificId::None` (it already tracks
a specific internally from `SpecificInst`); its `SpliceInst` arm returns
`InstId::None` when the splice's constant in that specific is not concrete
(the definition), mirroring `GetExprCategory`'s `SpliceInst` arm
(expr_info.cpp:127-152). Lowering callers pass `context.specific_id()`. This
removes RC-3. _Break condition:_ a caller in check needs the storage of an
unresolved splice (none: `Initialize` falls back to its own `storage_id`).

**D-TP-6 (A5): a dependent value conversion is a `ConvertToValueAction`.** In
`DoStep`'s `Dependent` case, a target of kind `Value` creates
`ConvertToValueAction` (which already exists, with
`ActionExprCategory(Value)`, typed_insts.h:629-641) instead of
`ConvertToCategoryAction`, so a binding of the result has the value category
in the definition and on instantiation alike. This removes RC-6's second
half. _Break condition:_ a dependent value conversion whose result is not a
value on instantiation (impossible: the target kind is `Value`). The
conversion of a tuple to a type converts each element of the tuple's constant
value; an element that splices a template-dependent action's result, such as
`T.Elem` in `(T.Elem, i32)`, is that splice's constant, which is not attached
to the generic, so its conversion stayed template dependent in every specific
and the tuple type reached lowering symbolic (`file_context.h`'s
`type_id.is_concrete()` CHECK; the first re-review's d06, its a and g on trunk
too). `ConvertTupleToType` (convert.cpp) now converts the generic's
instruction for that constant (`GetOrAddInstWithSpecificConstantValue`), so
the conversion is performed in each specific: `(T.Elem, i32)` lowers as
`(i32, i32)` does (lower/template/initialize.carbon
`return_tuple_of_associated_type` and `var_tuple_of_associated_type`, whose
function bodies equal their non-template twins' apart from the mangled names;
mutant M27), and `(x.0, i32)` for a runtime `x` is diagnosed by D-TP-26
((amended 2026-10-15, focused re-review of the fold: RR1-M2)).

**D-TP-7 (B1 to B3): lowering reads categories, constants and storage in the
specific, and a spliced in-place initializer has no value.** B1 passes
`&context.specific_sem_ir(), context.specific_id()` to every
`GetExprCategory` call on an instruction of the function being lowered
(aggregate.cpp:56, handle.cpp:105, handle_expr_category.cpp:61, :77, :87;
`ReturnExpr` already does). B2 makes `HandleInst(SpliceBlock)` and
`HandleInst(SpliceInst)` call `GetValue(..., /*require_value=*/false)` and
set a local only when there is a value, as `HandleInst(SpecificInst)` does.
B3 makes `EmitAggregateInitializer` (aggregate.cpp:227-235) and the fork's
`ArrayInit` arm (handle.cpp:86-92) decide constness with
`FunctionContext::IsConstant`, as `LowerInst` does, and find the storage in
the specific. These remove RC-5's second half, RC-6's first half and RC-7.
_Break condition:_ a lowered non-template function changes (measured: C1
alone, vc1, changes no lower golden; the one SSA name in template/class.carbon
comes from C4, vc1234; amended 2026-10-14, review fold: B-m2).

**D-TP-8 (A6): the `for` header requires its cursor pointer type complete.**
handle_loop_statement.cpp:254-259 calls `RequireCompleteType` on the
pointer type before forming `&cursor`; for a symbolic pointee this records a
`require_complete_type` in the eval block, so each specific completes the
pointer type its `Next` call passes. This removes RC-4. B5 adds a
`CARBON_CHECK` to `GetOrCreateLLVMFunction` that an inexact function type has
no return slot, so the next missing completeness requirement anywhere fails
with a message instead of a segfault. _Break condition:_ a checked-generic
loop changes behavior (measured: interop/cpp/range_for.carbon gains only the
`require_complete_type` lines).

**D-TP-25 (added 2026-10-14, implementation-review fold: IR1-B1): a constant
splice lowers the instructions of its block that are not constant.** In a
template's specific, the element `1` of `return (x, 1);` converts to a constant
`i32` 1, so its splice has a constant value, but the block it splices also holds
the copy of its in-place initializer's storage access chain (D-TP-3),
`tuple_access %return.param, element1`, which is not constant. `LowerInst`
skipped the splice as a constant, so the chain was never lowered, and
`EmitAggregateInitializer`'s constant-element loop (B3), or the `ArrayInit`
handler's, failed `function_context.cpp:223` when it stored the constant into
that storage. `LowerInst` now lowers, for a constant `SpliceInst`, the
instruction it splices in the specific, and, for a constant `SpliceBlock`, the
instructions of its block that are not constant (`LowerStorageInConstantSplice`,
function_context.cpp), where the splice is, as a non-template function lowers
the same instructions in its body; the constant-element loops then find the
storage. Measured: the review's m01 to m29 and r01 to r16 run (m01 prints 101
and r04 prints 6, as trunk does for r04), except r06 and r16, which copy a class
without `Copy` and are rejected as without a template;
lower/template/merging.carbon gains the `alloca {}` of its non-template twin
(§0.8). Pinned by nine check and lower splits of initialize.carbon and the
program templates_constant_elements; mutant M21 (the call removed) aborts both.
_Break condition:_ a golden whose non-template twin does not lower the same
instructions changes.

**D-TP-26 (added 2026-10-14, implementation-review fold: IR1-M1; rewritten
2026-10-15, focused re-review of the fold: RR1-B1 / RR1-m2): in a specific, a
runtime operand where a constant is needed is an error at that operand.** A
template's type expressions can be runtime results of actions on instantiation:
`array(i32, a[0])` indexes a template value parameter's array with `ValueAsRef`
and `ArrayIndex`, `array(i32, Get(a))` calls a runtime function, and `x.0`,
`x[0]`, `*p` or `MakeT(x)` on a template's runtime parameter, written as a type
(`let a: x.0`, `(x.0, i32)`, `{.p: x.0, .q: i32}`, `array(MakeT(x), 1)`, `->
x.0`, `var a: x.0`, `2 as x.0`), are values, not types, in the specific. The
fold diagnosed only the array bound (IR1-M1): every other position reached
eval.cpp's "PatternType should always be constant" FATAL, `(x.0, i32)` passed
checking and stopped lowering, and `2 as x.0` passed checking (the first
re-review's r1 to r8 and c12, and the fixer's probes of its own first fix; trunk
and the nightly reject the tuple-index and dereference forms where the function
is defined, because they defer no action there, and trunk stops at the same
FATAL for the call form, c12). `TryEvalTypedInst`, when an instruction's
evaluation in a specific fails, finds its first operand that is not constant
(`FindNonConstantOperand`, which also reports whether the operand is used as a
type: a `TypeInstId`, in a bundle or in a struct type's fields too). If the
instruction is a type or always constant, or the operand is used as a type, it
reports eval.cpp's own ``expression is runtime; expected constant`` at that
operand, once per operand in the specific, and makes the operand's value in the
specific's value block the error constant (`MakeSpecificValueAnError`), as
`ExprAsType` makes such a type an error outside a template, so that the
specific's other uses of the value see an error; a type or an always-constant
instruction is then the error constant, and any other instruction stays not
constant. `GetExprCategory` and `FindStorageArgForInitializer`
(sem_ir/expr_info.cpp) and `TryGetCalleeAsBoundMethod` (sem_ir/function.cpp)
treat a splice whose value is the error constant as an error. Outside a specific
the bound is checked where it is written (handle_array.cpp's ``array bound is
not a constant``). The array bound's conversion of the runtime `i32` to
`Core.IntLiteral` reports its own ``non-constant call to compile-time-only
function`` first, so that monomorphization error has two notes. Pinned by
index.carbon's `fail_index_in_array_bound_on_instantiation`, by its nine splits
for a runtime type (`fail_tuple_index_as_type`, `fail_index_as_type`,
`fail_tuple_type_element`, `fail_struct_type_field`, `fail_array_element_type`,
`fail_tuple_index_as_type_of_used_binding`,
`fail_tuple_index_as_conversion_target`, `fail_tuple_index_as_return_type` and
`fail_tuple_index_as_var_type`, each `_on_instantiation`) and by
pointer.carbon's `fail_deref_as_type_on_instantiation` and
`fail_pointee_type_on_instantiation`, with index.carbon's
`template_value_as_type` keeping a template value parameter's `t.0`, `(t.1,
i32)` and `s.p` as types; mutants M22 (the diagnosis removed), M26 (the rule
narrowed to array types, as the fold had it), M32 (no error value in the
specific), M33 (no rule for an operand used as a type) and M34 (no error arm in
`GetExprCategory`). _Break condition:_ a valid program's specific reaches the
diagnosis (measured: none of the 213 probes of the two re-reviews and the
fixer). A checked generic's specific reaches it only through an `eval fn` from
another library, which cannot be evaluated there (the first re-review's m5, m12
and m16: trunk stops the compiler on all three, the nightly on m5 and m12);
there the diagnosis is the intended result, and the upstream limit is in W-250's
notes ((amended 2026-10-15, focused re-review of the fold: RR1-B1 / RR1-m2)).

Every such operand is an error, not only the first (amended 2026-10-15,
focused re-review of the fold: RR2-1-M1). For `array(x.0, x.1)` with `x:
(type, i32)`, only the bound, the first operand, was made the error constant,
so the element type `x.0` kept no value in the specific and the conversion of
`a[0]` stopped the compiler at value_store.h's `inst<none>` CHECK, after the
diagnostics (round 2's c10 and c19; trunk and the nightly reject both where
the function is defined). `TryEvalTypedInst` now collects every operand that
is not constant (`FindNonConstantOperands`) and, of those the instruction
needs constant, diagnoses the first once and makes each the error constant in
the specific's value block; `(x.0, x.1)` as a type has one note at its first
element instead of two at the same location. index.carbon's
`fail_array_type_two_runtime_operands_on_instantiation` and
`fail_tuple_type_two_runtime_elements_on_instantiation` pin it; mutant M35,
which makes only the first operand an error, aborts the first. Of the three
sem_ir readers, a program reaches only `GetExprCategory`'s error arm (M34).
`FindStorageArgForInitializer` is called with a specific only from lowering,
which does not run after the diagnosed error that an error value in a
specific implies, and `TryGetCalleeAsBoundMethod` with a specific only
through `GetExprCategory`'s `Call` arm, for a call whose callee is a splice,
which no golden or probe of the two rounds reaches: mutants x1 and x2 of §8,
which remove those two arms, survive the gate. The arms are kept so that an
error value in a specific reads as an action not performed rather than being
cast to an instruction (amended 2026-10-15, focused re-review of the
fold: RR2r2-m1).

**D-TP-14 (C2, rewritten 2026-10-14, review fold: A-m4 / B-m6): a generic from
another library whose definition is resolved per instantiation is diagnosed
once, at the `import`.** `TryFinishGeneric` (import_ref.cpp:1162-1193) does not
import a definition eval block that contains an action or a splice. After its
`HasNewWork()` retry point, so that a retried import reports once, it reports
``semantics TODO: `using a generic from another library whose definition is
resolved for each instantiation, such as a template` `` at the location of the
importing file's `import` declaration (`ImportIR::decl_id`; `LocId::None` only
for an indirect import, which has none), and gives the local generic an empty
definition block, so its uses resolve and the cascaded ``use of undefined
generic function`` is not reported; the file has an error and is not lowered.
The wording covers what the test detects, an eval block that holds an action or
a splice: a template, and a checked generic whose definition holds one, such as
a call of a C++ template. A checked generic that calls an `eval fn` from another
library is not detected, because the call is a template-phase call, not an
action; the imported `eval fn` cannot be evaluated, so the generic's specific
reports D-TP-26's ``expression is runtime; expected constant``, whether or not
the generic itself is imported, where trunk and the nightly stop the compiler
(an upstream limit, in W-250's notes; (amended 2026-10-15, focused re-review of
the fold: RR1-m2)). Measured on v13 (`$X/probes/xlibA`, `$X/probes/xlib`):
`main.carbon:1:1: error: semantics TODO: ...` with the `import` line quoted, for
a function template, a class template (`Box(i32)`) and a method call on it,
nothing else; an import whose templates are unused compiles. A function or class
template whose declaration holds an action, such as `fn Elem[template T:
type](x: T) -> T.Item` or `class Pick(template T: type, U: T.Item)`, reaches
`TryResolveInstCanonical` while its signature is imported, before
`TryFinishGeneric` would test the definition, and stopped the compiler there
(the first implementation review's main_declaction, trunk too; (amended
2026-10-14, implementation-review fold: IR1-M2)). The import of such a function
or class reports the same TODO, once for the entity, when the entity is first
resolved (`IsDeclResolvedPerInstantiation`), and resolves the entity to the
error constant, which the imports of its function type and generic class type
pass on, so its uses report nothing more (fail_todo_import.carbon's two
`_declaration` splits). That test alone left three shapes that stopped the
compiler, as on trunk and the nightly (the focused re-review of the fold): a
class template whose field type holds an action (`var item: T.Item`), whose
complete-type witness reached the fatal before `TryFinishGeneric` tested the
definition; a class template whose method declaration holds one (`fn
Get(self) -> T.Item`), whose method resolved to the error constant inside the
class's definition eval block, where generic.cpp's CHECK rejects it; and an
interface or named constraint whose declaration holds one (`interface
PickI(template T: type, U: T.Item)`), which compiles in its own library and
reached the fatal on import. The import of a class, an interface or a named
constraint now tests, before any of its data is loaded
(`IsTypeResolvedPerInstantiation`), its declaration, its definition, for an
interface or constraint its generic with `Self`, and the declarations of the
functions and classes that its definition names; when any is resolved per
instantiation, it reports the TODO once and resolves to the error constant,
which the generic interface and named-constraint types and an imported facet
type pass on (`HasErrorConstraint`), so no error constant reaches an eval block
(fail_todo_import.carbon's `_class_field_type`, `_class_method_declaration`,
`_interface_declaration`, `_constraint_declaration` and
`_interface_member_declaration` splits; mutants M23, M28 and M29). None of the
54 cross-library probes of the two re-reviews and the fixer reaches
`TryResolveInstCanonical`'s fatal any more, and an impl whose declaration holds
an action is rejected in its own library (``impl as non-facet type``,
measured). An interface or named constraint whose later parameter's type
depends on a template parameter stops the compiler in its own library when it
is used (sem_ir/generic.cpp:84's CHECK, trunk and the nightly too; W-270), so
its uses from another library are not measured past that ((amended 2026-10-15,
focused re-review of the fold: RR1-M1 / RR2-M1)). Lowering's cross-file fatal
(handle.cpp:513) is unreachable because checking reports an error first; it
stays in the code (W-250). _Break condition:_ a template is imported without
being resolved (it is not: the definition and declaration tests run only for an
entity that a use or an `export` resolves; review A's `main_unused` compiles,
and an intermediate library whose `export Id;` re-exports a template reports the
TODO at its own `import`, the first implementation review's libd).

The test walks what the entity's loaded data names (amended 2026-10-15,
focused re-review of the fold: RR2r2-M1). Round 2's second review found that
it stopped at the entities it was given: a class template's nested generic
class with a field or method of type `T.Item` (n01, n02, n03) put the nested
class's error constant in the outer class's definition eval block
(generic.cpp:239's CHECK), and a function whose deduced parameter is
constrained by an interface template whose member returns `T.Item` (n05)
gave a symbolic binding the error type (sem_ir/type.cpp:27's CHECK), each
after the TODO. The fixer's probes found the same for a checked generic whose
declaration or body names such a class (p1, p6, p9), for a class, interface
member, method or impl constrained by such an interface (p5, p3, p8, p4) and
for a class whose field's type is such a class (p7). Trunk stops all of them
at `TryResolveInstCanonical`'s FATAL; the nightly stops n05 and p2 to p9
there, and n01, n02, n03 and p1 at import_ref.cpp:1168's CHECK, which it also
reaches for their checked twin n07 (amended 2026-10-15, focused re-review of
the fold: RR3r2-m1; 94227d82c's message says the nightly stops them at the
FATAL). `PerInstantiationWalk`
(import_ref.cpp) is a worklist over the imported instructions that an
entity's eval blocks and its bindings' types name: an action or a splice ends
it; a function type adds its function's declaration; a class type or a
generic class type adds its class's declaration and definition; a facet type
adds the generic and the generic with `Self` of each interface and named
constraint it names; and each generic is added once, so a class that names
itself, or an interface whose members' `Self` has its facet type, ends.
`IsDeclResolvedPerInstantiation` walks a generic's declaration block and the
types of its bindings, which are loaded with the bindings and are not eval
block entries when they are concrete (`WithMethod(Holder)`);
`IsTypeResolvedPerInstantiation` adds the definition block; an impl whose
generic the walk rejects is diagnosed and not imported, so it is not a
candidate for impl lookup in the file (its split also reports that `K` does
not implement `Marker`); and `TryFinishGeneric` does not import a definition
that names such an entity. Six fail_todo_import.carbon splits pin the shapes,
and a seventh `HasErrorConstraint`, which a parameter whose type is such an
interface's facet type reaches in a function that is not generic (`fn G(x:
WithMethod(Holder))`); mutants M43 to M50 and the redefined M28. Measured
(§8, "Measured at the focused re-review of the fold, round 2"): of the 64
cross-library probes of round 2, 40 report the TODO, once per entity, with no
crash, 16 compile, 5 are rejected in their library with trunk's own
diagnostic, and every one that compiled at 764e55445 still compiles, so no
error constant reaches an eval block or a binding's type in any shape the two
rounds measured. The other three, the second review's y04, y05 and y09, stop
at another FATAL, `GetLocalGenericId`'s (import_ref.cpp:1423; :1287 at
aa57bfe1c), as they do on
trunk and the nightly: a generic class from another library that declares a
nested class or interface, with or without a template parameter, filed as
W-271 (amended 2026-10-15, focused re-review of the fold: RR2r2-M1).

The walk follows each reference that the import loads (amended 2026-10-15,
focused re-review of the fold: RR3-1-M1 / RR3r2-M1). Round 3's two reviews
found that it tested only the kind of each entry it reached and never an
entry's operands, so a template named through a concrete operand of an entry
still reached an eval block as the error constant after the TODO: a checked
generic, a generic class's method or a blanket impl's method whose body
calls a function template whose declaration holds an action, through the
callee and the specific of its `specific_function` (c1 to c4, e1:
`GetLocalGenericId`'s FATAL); and a class template as a specific's
argument, a tuple element or a field beside one of type `T` (a1 to a5, b2,
b3, f3, f3b, g1, g2: generic.cpp:239's or sem_ir/type.cpp:27's CHECK). A
checked generic whose body calls a function template whose definition alone
holds one (d1, d2) stopped at `TryResolveInstCanonical`'s InstValue FATAL
instead: `TryFinishGeneric` did not import the function's definition, but
`TryFinishSpecific` imported the definition values of its specific. The
fixer's probes found the same for an array or struct element, a rewrite
constraint's value, a `where .Self impls` constraint's argument, an
interface member's return type, a struct field of a generic class, a
checked generic that calls one constrained by such an interface, a second
use of a template that the file had already reached, and a witness of a
blanket impl that cannot be imported, as a specific's argument (inst.h's
cast CHECK). Trunk and the nightly stop every one of them at
`TryResolveInstCanonical`'s SpliceInst FATAL, and each compiles in one file
on all three. `PerInstantiationWalk` now follows, for each instruction it
reaches, its type and its operands: the field types of a struct type, the
elements of a block, the generic and the arguments of a specific, each
interface and named constraint of a facet type with its specific and the
types and values its constraints name, and the function (its declaration),
class, interface, named constraint or impl (its declaration and definition)
that an operand names, with a set of the instructions it has reached. A
function's specific adds the function's declaration only, as a function
whose definition alone is resolved for each instantiation is imported
without that definition; `TryFinishSpecific` tests the generic's
definition as `TryFinishGeneric` does and leaves the specific's definition
empty, as the generic's is (68102438e). A specific's values are not walked:
they are its generic's entries evaluated for its arguments, so they name
what those name. A walk that reaches no action records what it reached in
the file's `Context::PerInstantiationWalkCache`, so the imports into a file
walk each instruction and generic about once: the wider walk raised the
gate's time across threads from 102.6 s to 127.2 s, and with the record it
takes 91.8 s (d54c37f91). A walk that reaches one records nothing. Eleven
fail_todo_import.carbon splits pin the shapes (68102438e, ada45a7c6); mutants
M51 to M67 and the redefined M43 and M50. Measured (§8, "Measured at the
focused re-review of the fold, round 3"): of the 110 cross-library probes
of round 3, the 32 that stopped the compiler after the TODO at aa57bfe1c
report it, once per entity, with no crash; every one that compiled there
still compiles; and the six that stop the compiler stop trunk too: W-271's
four, and the round-1 fixer's q1 and q2, a generic class with an empty
nested class, which W-271's notes record.

**D-TP-15 (dropped 2026-10-14, review fold: A-M3).** Rev 1 diagnosed a
template form parameter as a `semantics TODO`. RC-9 is not template-specific
(the upstream golden `form_generic_param` crashes lowering the same way), so
the guard would have turned checking programs into errors while the crash
stayed reachable, and its sketch returned without pushing a pattern onto the
node stack. TP-1 leaves form parameters unchanged and files the crash
(W-255).

**D-TP-23 (C2, added 2026-10-14, review fold: A-m2): a diagnostic prints the
splice of a template-dependent operation as the expression it performs.**
`Stringifier` (sem_ir/stringify.cpp:723-726) prints a `SpliceInst` whose operand
is an action by stringifying the action, and prints an `AccessMemberAction` as
`<base>.<name>` and a `ConvertAction`, `ConvertToCategoryAction` or
`ConvertToValueAction` as its operand, instead of falling back to `<cannot
stringify ...>` (stringify.cpp:353). Measured on v13:
member_out_of_line.carbon's two messages read ``type `<pattern for T.U>` of
parameter 1 in redeclaration differs from previous parameter type `<pattern for
T>` `` and ``function redeclaration differs because return type is `T.U` ``, and
no other golden changes. The split's redeclarations do differ (`T` and `T.U`),
so rejecting them is p3763's rule, and the split flips to `fail_basic`; W-254
keeps only the token-identical case (mool), whose message now shows the defect
plainly (``<pattern for T.U>` ... differs from ... `<pattern for T.U>` ``). The
implementation-review fold adds C3's four kinds, `CallAction` and
`CompoundMemberAccessAction`, which still printed ``<cannot stringify ...>`` (a
redeclaration whose return type is `array(i32, v.0)`, or `C(*p)`): they print as
`*x`, `(*x)` before `->`, `&x`, `x.N`, `x[i]`, `f(args)` and `x.(M)`
(index.carbon's `fail_redecl_differs_in_dependent_operation`; mutant M24;
(amended 2026-10-14, implementation-review fold: IR1-m2)). A prefix `*` or `&`
operand of an index, a tuple index, a member access or a call prints in
parentheses (`C((*p)[0])`, which printed as `C(*p[0])`, the text of the
redeclaration it differs from), an associated entity prints as
`Interface.Member` (`T.(Container.Elem)`, `v.0.(Core.Negate.Op)()`; an imported
interface's member through its import's entity name), and a compound member
access whose member is an associated entity prints from that constant; the
split gains five redeclarations, so `AddrOfAction`,
`CompoundMemberAccessAction` and the `->` form have goldens too (mutants M24,
M30 and M31; (amended 2026-10-15, focused re-review of the fold: RR1-m1 /
RR2-m6)). A member access, or a compound member access, whose base is the
dereference that `->` performs, looking through splices and conversions,
prints as `p->n` or `p->(I.F)`, so `C(*p->q)` and `C(*(*p).q)`, `C((**p).n)`
and `C((*p)->n)`, and `C(p->(J.G)())` and `C((*p).(J.G)())`, which printed
the same, print as they are written (the split's R, S and U, and N as `C(p->n)`
and `C(p->m)`; mutants M41 and M42; (amended 2026-10-15, focused re-review of
the fold: RR2-1-m1)). _Break condition:_ a golden outside generic/template/
changes (measured: none).

### §1.3 Dependent-form deferrals (C3)

**D-TP-9: four new action kinds, each performing the existing eager code on
instantiation.** Following `AccessMemberAction` and `CallAction`, each form
gets an action whose `PerformAction` is the code that runs today for a
non-dependent operand; the definition creates the action only when that code
cannot decide yet, so every non-template SemIR is unchanged:

| Action | Fields | Created when | `PerformAction` | Category |
| --- | --- | --- | --- | --- |
| `PointerDereferenceAction` | `MetaInstId pointer_id`, `BoolValue is_arrow` | the operand's unqualified type is an opaque template-dependent type (below) | `PerformPointerDereference` with the `*` or `->` diagnostic | `Dependent` |
| `AddrOfAction` | `MetaInstId lvalue_id` | the operand's category is `Dependent` and its type is an opaque template-dependent type | the body of `HandleParseNode(PrefixOperatorAmp)` (handle_operator.cpp:270-294), extracted as `PerformAddrOf` | `Value` |
| `TupleIndexAction` | `MetaInstId tuple_id`, `MetaInstId index_id` | the tuple operand's type is an opaque template-dependent type | `PerformTupleAccess` (member_access.cpp:892) | `Dependent` |
| `IndexAction` | `MetaInstId operand_id`, `MetaInstId index_id` | the operand's type is an opaque template-dependent type | the body of `HandleParseNode(IndexExpr)` (handle_index.cpp:157-215), extracted as `PerformIndex` | `Dependent` |

An opaque template-dependent type (amended 2026-10-14, review fold: A-m7) is a
type whose constant is template dependent and whose unqualified instruction is a
`SymbolicBinding` (a template type parameter `T`), a `FacetAccessType` of one (`T`
for `template T: I`), a `TypeOfInst` (`<dependent type>`, the type of a
template-dependent expression's splice), or a `SpliceInst` (a type that a
template-dependent operation produces, such as `T.Elem` for `template T:
Container`, an `AccessMemberAction`'s splice; `const T` is as opaque as `T`;
(amended 2026-10-14, implementation-review fold: IR1-m3)): a type whose kind --
pointer, tuple, array, class -- is known only on instantiation
(`IsOpaqueTemplateDependentType`, Appendix D). Every other type keeps today's
eager path, including a template-dependent class type such as `C(T)` or
`Vec(T)`, whose kind is known: `*c` for `c: C(T)` is rejected where it is
written (TR-2), and `v[i]` for `v: Vec(T)` with an `IndexWith` impl keeps its
`CompoundMemberAccessAction` and `CallAction` (pinned by index.carbon's
`index_class_with_index_with` split, whose SemIR must not change). A dereference
of `p: T*` (s14) and an index into `array(T, 3)` stay eager, as today. On
instantiation a failure is a monomorphization error whose note is the eager
diagnostic, as for member access (R08). _Break condition:_ an existing golden
other than unimplemented.carbon changes (predicted: none; the creation
conditions are a subset of the cases trunk rejects).

**D-TP-10: a callee of function type with no constant value calls the
function its type names.** In `PerformCallHelper` (call.cpp:836), a callee
whose type is a `FunctionType` and whose constant value is not a constant is
replaced, for resolution, by the function type's value (`StructValue` with no
elements, the constant every `fn` declaration evaluates to,
eval_inst.cpp `EvalConstantInst(FunctionDecl)`); the callee expression has
already been evaluated in order, so no side effect is lost. p2875 gives each
function its own type; p002200:735-737 makes such a call "only need the type
of the function". _Break condition:_ a function type with more than one
value (none exists in the toolchain).

### §1.4 SpliceInst lowering

Upstream PR 7727's design is kept: a splice in a specific lowers to the
instruction its action produced there, lowered in place, and its value is
that instruction's value. TP-1 completes it where the measured defects are:
the spliced instruction may be an in-place initializer with no value (B2),
the function's other instructions must read categories and constants of the
splice in the specific (B1, B3), and storage arguments are found in the
specific (D-TP-5). The cross-file case stays a fatal that checking now makes
unreachable (D-TP-14); a later item (W-250) implements it.

### §1.5 Name lookup into a constrained template parameter (W-183, C5)

Root cause: §0.4. Cost, measured on v5 (rev 1) and v12/v13 (rev 2): about 100
changed lines in member_access.cpp, no golden change on trunk, conformance
unchanged. Probes on v13 (amended 2026-10-14, review fold: A-M1): R09 `25`,
`extend impl` `25`, a type-only member `72`, a type field the constraint
lacks `9`, review A's RoundWidget (`alias Draw = Renderable.Draw`) `7`,
SquareWidget (an out-of-line `impl` whose `Draw` aliases the class's) `8 8`,
Pig (constraint only) `3`, an associated constant `5`, two constraints `12`;
rejected on instantiation: X21, Cowboy (a class `Draw` beside a different
`impl` `Draw`), a field `F` beside the constraint's method `F` (a09), and the
same conflict through a pointer (a10) or a call result's `let` (a11).

**D-TP-13 (amended 2026-10-14, review fold: A-M1 / A-M2 / B-M6).** On
instantiation, `PerformAction(AccessMemberAction)` looks the name up twice: in
the argument's type, as today, and in the constraint of the template
parameter whose type the operand had in the definition (the refined operand
is a `SpecificInst` of the definition's operand; its type there is
`FacetAccessType(T)`; the binding's value in the specific is the argument's
facet value, whose facet type is the constraint). The constraint lookup uses
`LookupMemberNameInScope` with `lookup_in_type_of_base`, so an associated
entity found in the constraint is accessed through the argument's impl, as
`x.(I.F)` is, then instance-bound. If only one lookup finds the name, its
result is used; if both find it, the results must name the same entity
(member_access.md "Lookup ambiguity" :542-551), else the access is an error.
`SameMemberEntity` decides it: two functions are the same entity when they
are the same function in the same enclosing specific (`GetCallee`'s
`CalleeFunction`, which sees through a bound method and an alias); a function
and a member that is not a function are distinct; two members that are not
functions are the same entity only when both have the same constant value,
so a field, which has none, is distinct from every other result (rev 1
compared constant values for every non-function pair, and two runtime values
compared equal: a09 printed 9 on v8 and is rejected on v13; mutant M15, which
restores rev 1's comparison, accepts it again). Over SC-1 (§0.9), a member the
constraint lookup finds that is a `template constraint` requirement (SC-1's
`GetStructuralRequirementRef`) returns `None` from the constraint lookup: the
type's own member satisfies the requirement and is the entity, so the type
lookup decides (scv13 without this rule rejects nine of SC-1's
template-constraint goldens; scv13b with it changes none). The new
diagnostic, under diagnostics/kind.def:

<!-- google-doc-style-ignore -->

```cpp
CARBON_DIAGNOSTIC(TemplateMemberLookupAmbiguous, Error,
                  "member name `{0}` names different entities in type {1} and "
                  "in its constraint {2}",
                  SemIR::NameId, SemIR::TypeId, SemIR::TypeId);
```

<!-- google-doc-style-resume -->

On instantiation it becomes the note under ``unable to monomorphize specific
`G(C as A)` ``. For X21 the note reads ``member name `F` names different
entities in type `C` and in its constraint `A` `` (hand-predicted from the
format; C5 is not relinkable because of the new diagnostic kind; v13 emits a
`semantics TODO` in its place).

TR-8's definition-time half is not implemented (amended 2026-10-14, review
fold: A-M2): proposal 2200 gives `x.G()` the constraint's meaning where the
function is defined when the constraint has `G` (:744-752), and makes a name
the constraint declares twice ambiguous there (:766-767), and
member_access.md:436-440 compares a type-level access as well. The toolchain
defers the whole access, so a13 (`let b: bool = x.F();` with `F` returning
`i32`) and a12 (`template T: A & B` with `F` in both) compile when uncalled,
and a05 (`T.F()`, a type's own `F` beside the constraint's) calls the
constraint's `F` without a comparison, because the operand of a type-level
access is a type, not a value of type `FacetAccessType`. Implementing the
definition half means giving such an access the constraint member's type in
the definition (a signature-typed splice), which is a separate design step;
TP-1 files the three (W-260, W-261, W-262), names them on the page and keeps
§7.2(5)'s rejection of a definition-only rule, which would lose the
instantiation comparison. _Break condition:_ SC-1's requirement mapping
changes so that a requirement found in a constraint is no longer the type's
member, or a template constraint's requirement can name a non-function
member; then the composition rule above is restated.

### §1.6 Deduction through a class's arguments (W-193, C4)

Root cause: §0.4. Cost, measured on v4: 32 changed lines in call.cpp for both
X17 and W-193; generic/template/convert.carbon and class/destroy_calls.carbon
refill (the dependent `C(T)` types become `class_type @C, @C(%T)
[template]` constants instead of `call_action` splices; no diagnostic
changes), and lower/testdata/template/class.carbon renames one SSA value
(vc1234, amended 2026-10-14, review fold: B-m2).

**D-TP-11.** `IsCallPerformable` (call.cpp:820-833) treats a call to a generic
class, interface or named constraint (the callee's type is
`GenericClassType`, `GenericInterfaceType` or `GenericNamedConstraintType`)
as performable when no argument's _type_ is template dependent; the
arguments' _values_ may be template dependent, as symbolic arguments of a
checked generic are. The resulting type is a template-dependent class type,
which deduction (deduce.cpp:399-465) matches through its specific as it does
for a checked parameter. Every other callee keeps today's rule. Measured on
v13 for DD-1's PR-AJ forms (amended 2026-10-14, review fold: B-m5): a
template `T` from `Holder(T)` with a checked class parameter (PR-AJ's e04 and
v02: `holder`, 42 with X25's checked twin), with a `Core.Copy` class
parameter (review A's g02: `holder_copy_constraint`, 7), from a template
class's `Holder(T)` (v04, u11: `template_class_type`, 9), from `Holder(T)*`
(w02: `holder_pointer`, 5), and `N` from `Vec(N)` (v09: `vec_value_param`,
3); a value-dependent class argument in a parameter's type (review A's g03,
`Vec(N + 1)` with `N` explicit: `class_argument_expression`, 13) and in a
return type (g01, `Vec(M)`: `class_argument_return_type`, 1). Deducing `N`
from `Vec(N + 1)` is not deduction through a class argument and is rejected
as for a checked parameter (``cannot deduce value for generic parameter
`N` ``). _Break condition:_ a generic class whose parameter conversion
depends on the argument's value (none: the arguments are converted to the
declared parameter types, which the call checks with the symbolic values).
Because the class type is formed in the definition, a literal of a class
whose fields hold an array with a template-dependent bound is converted on
instantiation by D-TP-24's rule, as trunk's deferred call converted it
(amended 2026-10-15, focused re-review of the fold: RR2-1-M2).

### §1.7 Deferred impl lookup (W-127, C4)

Root cause: §0.4. Cost, measured on v12 (amended 2026-10-14, review fold:
A-M4 / B-M5): about 100 changed lines in impl_lookup.cpp, no golden change on
trunk. Rev 1's v7 tested only `ConstantDependence::Template` of the query's
self, which is broader than a template binding: eval.cpp:3075-3090 forces the
results of `TemplateOnly` instructions -- a C++ template instantiated with
symbolic arguments (`TemplateInst`, typed_insts.h:2258-2268) and an `eval fn`
call -- to template dependence inside checked generics. Rev 1's two refills
were both checked generics: interop/cpp/template/generic_call.carbon
(`fn F[T: type](unused x: T)` calling a C++ template; v7 dropped its selected
`DefaultOrUnformed` impl) and facet/period_self.carbon (`impl forall [T:
type] ... where .Y1 = .YF()` with an `eval fn`; its first error changed from
`ConversionFailureFacetToFacet` to a misleading `NestedWhereInsideWhere`).

**D-TP-12 (rewritten 2026-10-14).** Impl lookup for a query that names a
template binding is never resolved in the definition:
`EvalLookupSingleFinalWitness` (impl_lookup.cpp:1182) returns `None` for it,
before collecting candidates, and `LookupImplWitness` (:989) keeps the deferred
`LookupImplWitness` as the witness without asking `FindNonFinalWitness`. A query
names a template binding when its self, or an argument of its interface's
specific, is template dependent and reaches a `SymbolicBinding` whose entity
name `is_template` through its operands (`NamesTemplateBinding`, §2.4:
instruction, type, instruction-block, specific and struct-field operands,
following only symbolic constants). That is proposal 2200's "Impl lookup is
delayed until all templated types, interfaces, and parameters are known"
(:198-199) for the template parameters it is about; a checked generic's C++
template or `eval fn` result is not a templated type or parameter of the
generic, and keeps today's lookup. Selecting even a `final` impl early is wrong
for a template, because the final impl's own requirement (`T: Default` for the
prelude's `DefaultOrUnformed`) can be decided only on instantiation (v6's
defect). Measured on v12: facet/period_self.carbon and generic_call.carbon no
longer change (they are the pins that a checked generic with a C++ template self
or an `eval fn` result keeps its lookup); X20 `5`, X23 `6`, a tuple `var y: T;`
rejected on instantiation as `var y: (i32, i32);` is without a template; a
concrete self with a template-dependent interface defers its lookup: with `impl
i32 as Tag(W)`, `let unused t: Tag(U) = i32;` compiles and `F(W)` checks
(default_init.carbon `template_interface_facet_value`), and beside a `final impl
forall [T: type] i32 as Tag(T)` the definition of `(i32 as Tag(U)).Id()` keeps
`lookup_impl_witness %i32, @Tag, @Tag(%U) [template]`
(`template_interface_final_impl`); these are D-TP-12's interface-side pins and
kill mutant M17. `template_interface_concrete_self` (`fn Widen(template U: type,
x: i32) -> U { return x; }`) only checks that `return x;` is one deferred
`initialize_action`: its definition makes no lookup, which is why M17 survived
it ((amended 2026-10-14, implementation-review fold: IR1-m1 / IR2-MAJOR-1)).
_Break condition:_ a golden of a checked generic changes, or a query that names
no template binding is deferred (falsifiers: facet/period_self.carbon and
interop/cpp/template/generic_call.carbon change, §7.1(2)).

### §1.8 Out-of-slice forms and their diagnostics

Amended 2026-10-14 (review fold: A-M2 / A-M3 / A-m2 / A-m3 / B-M2 / B-M3).

| Form | Today | After TP-1 | W-id |
| --- | --- | --- | --- |
| a template, or a generic resolved per instantiation, used from another library | fatal (RC-8) | `semantics TODO` at the `import`, golden `fail_todo_import.carbon`; a function or class template whose declaration holds an action too, its `_declaration` splits (amended 2026-10-14, implementation-review fold: IR1-M2); a class template whose field type or method declaration holds one, and an interface or named constraint whose declaration holds one, five more splits (amended 2026-10-15, focused re-review of the fold: RR1-M1 / RR2-M1); an entity whose declaration, definition or bindings name one of these, such as a nested generic class with such a field or a deduced parameter constrained by such an interface, six more splits, and a seventh for an imported facet type naming such an interface (amended 2026-10-15, focused re-review of the fold: RR2r2-M1); an entity that names one through a concrete operand of an eval block entry, such as a callee, a specific's argument, a tuple or struct element, a field type, a constraint's argument or rewrite, or a blanket impl's witness, eleven more splits (amended 2026-10-15, focused re-review of the fold: RR3-1-M1 / RR3r2-M1) | W-250 |
| an access through a field whose declared type is a constrained template parameter: `self.c.F()` in `class W(template T: A)`, `h.c.F()` for `h: Holder(T)` | member not found on instantiation | unchanged: the field access is itself deferred, so the operand's type in the definition is not the parameter; pinned by constraint_lookup.carbon `fail_todo_field_of_template_class` (amended 2026-10-14, implementation-review fold: IR1-M3) | W-266 |
| an array bound that a template-dependent operation computes at runtime: `array(i32, a[0])`, `array(i32, Get(a))` | FATAL in eval.cpp (the call form; the index form was an error on trunk) | ``expression is runtime; expected constant`` on instantiation (D-TP-26), index.carbon `fail_index_in_array_bound_on_instantiation` (amended 2026-10-14, implementation-review fold: IR1-M1) | none |
| a runtime value written as a type in a template: `let a: x.0`, `(x.0, i32)`, `{.p: x.0}`, `array(MakeT(x), 1)`, `-> x.0`, `var a: x.0`, `2 as x.0`, `let a: *p` | rejected where the function is defined (the tuple-index and dereference forms), on instantiation (the index form), FATAL in eval.cpp (the call form) | ``expression is runtime; expected constant`` at the operand on instantiation (D-TP-26), eleven `_on_instantiation` splits of index.carbon and pointer.carbon (amended 2026-10-15, focused re-review of the fold: RR1-B1); with two runtime operands, `array(x.0, x.1)` or `(x.0, x.1)`, both are errors and the first is reported, two more splits (amended 2026-10-15, focused re-review of the fold: RR2-1-M1) | none |
| a tuple type whose element is a produced type: `var t: (T.Elem, i32)`, `-> (T.Elem, i32)` | CHECK in lowering (`file_context.h`), or rejected before C5 | lowers as `(i32, i32)` (D-TP-6), lower initialize.carbon's two `_of_associated_type` splits (amended 2026-10-15, focused re-review of the fold: RR1-M2) | none |
| the temporaries that a template's actions create on instantiation: `K(x)` for `fn K(var d: D)`, `Mk(x.n + 100).n`, `G((x, 1))` for `fn G(var p: (D, i32))` | never destroyed | unchanged (amended 2026-10-15, focused re-review of the fold: RR1-m3) | W-267 |
| `var e: T.Elem;` for a template `T: Container` | ``cannot convert type ... into type implementing `Core.DefaultOrUnformed` `` where the function is defined, the type printed `<splice of <cannot stringify ...>>` | unchanged; the type prints `T.Elem` (amended 2026-10-15, focused re-review of the fold: RR1-m4) | W-268 |
| `return {} as T;` for a class `T` without `Copy` | ``unable to monomorphize specific`` with ``cannot copy value of type `A` `` | unchanged (amended 2026-10-15, focused re-review of the fold: RR1-m5) | W-269 |
| an interface or named constraint whose later parameter's type depends on a template parameter, used in its own library: `fn UseI[T: I(Holder, 1)](x: T)` for `interface I(template T: type, U: T.Item)` | CHECK at sem_ir/generic.cpp:84 | unchanged; its import reports W-250's TODO (amended 2026-10-15, focused re-review of the fold: RR1-M1 / RR2-M1) | W-270 |
| a generic class from another library that declares a nested class or interface, used: `fn Use(o: Outer(i32)*)` for `class Outer(T: type) { class Inner { var x: T; } }`, with or without `template` | FATAL at import_ref.cpp:1086 (`GetLocalGenericId`: ``Unexpected inst for generic declaration``) | unchanged (import_ref.cpp:1287); when the nested class's data names an action, W-250's TODO is reported instead (amended 2026-10-15, focused re-review of the fold: RR2r2-M1) | W-271 |
| `partial T*` | `PartialOnFinal`, golden `fail_todo_partial_template_dependent` | unchanged | W-251 |
| `match` on a dependent value | `semantics TODO`, fixture X10 | unchanged | W-252 |
| an array with a dependent bound from a list | error, golden `fail_todo_init_template_dependent_bound` | unchanged directly and in a struct or tuple literal; in a class template's literal, `var c: C(N) = {.a = (1, 2, 3), .b = N}` and the same returned from `-> C(N)`, which C4 made an error where trunk compiles them, converted on instantiation (D-TP-24), deduce_class_args.carbon's and lower initialize.carbon's `_dependent_array_bound` splits (amended 2026-10-15, focused re-review of the fold: RR2-1-M2) | W-253 |
| an out-of-line redeclaration naming `T.U`, token-identical | rejected (`$P/probes/mool.carbon`), message printed `<cannot stringify ...>` | still rejected; the message now prints `T.U` on both sides (D-TP-23) | W-254 |
| a form parameter, `template` or `generic` | lowering fatal (RC-9) | unchanged | W-255 |
| a by-copy struct or one-element tuple holding an in-place aggregate: returning `{.a = x}`, or a nested `{.a = {.b = (x, x)}, .c = x}` | CHECK in `Convert` (RC-10), with or without a template; the nested form is compiled wrongly without a template and segfaults with one (RC-1) | the CHECK unchanged (fixture X34); the nested template form is compiled wrongly, as without a template (RC-10; amended 2026-10-14, review fold: RR-M2) | W-256 |
| assignment through a template-dependent left operand | accepted when not assignable (operator.carbon `todo_fail` splits) | unchanged | W-259 |
| the constraint's meaning and ambiguity at the definition; a type-level `T.F` | not checked; `T.F` calls the constraint's member | unchanged; fixture X36 for `T.F` | W-260, W-261, W-262 |
| a constant nested aggregate | LLVM verification CHECK (RC-13), with or without a template | unchanged; template copies of such values now reach it | W-263 |
| a template-dependent in-place initializer of a storage root allocated after it: the `for` cursor of tuple or class type; a class value whose literal omits a defaulted field | crash (RC-1 or RC-3 on trunk) | crash in lowering (the cursor) or the verifier (the class value) (RC-12); fixture X35; a class, union or array value otherwise runs (D-TP-24; amended 2026-10-14, review fold: RR-M1) | W-264 |
| a runtime class value or `var` whose field takes its default initializer | FATAL at expr_info.cpp:359 while lowering, with or without a template (added 2026-10-14, review fold: RR-M1) | unchanged; the template form stops at RC-12 first, during checking | W-265 |

### §1.9 Goldens

All new goldens are AUTOUPDATE sources without CHECK lines, filled by the
container arbiter's autoupdate to a fixpoint (R15, R16(a), R19, R26); every
new diagnostic has a `fail_` split. Their sources are in Appendix A, verbatim
(amended 2026-10-14, review fold: B-M1); the C1, C2, C4 and C5 sources were
run through v13's autoupdate (§0.8). Flipped `fail_todo` splits (§0.11):

1.  generic/template/unimplemented.carbon `fail_todo_unimplemented_operator`
    (`*x.n`, `F` not called): C3 makes the definition valid; renamed
    `deref_dependent_member.carbon`, no STDERR, and a new split
    `fail_deref_dependent_member_non_pointer.carbon` calls `F` on a class
    whose `n` is `i32` to pin the instantiation error (note
    ``cannot dereference operand of non-pointer type `i32` ``).
2.  generic/template/unimplemented.carbon `fail_todo_unimplemented_value`
    (`*c.n` with `template c: C`): renamed `deref_dependent_value.carbon`,
    no STDERR; `c.n` is a use of a dependent value, so `*c.n` is checked on
    instantiation (p002200:864-881), and a call of `F` with a `C` whose `n` is
    `i32` is the instantiation error that split 1's companion pins for the
    type form.
3.  generic/template/call.carbon `fail_todo_dependent_call_nonconst_arg`:
    renamed `dependent_call_nonconst_arg.carbon`, no STDERR (measured, vc123).
    Its sibling `fail_dependent_call_nonconst_arg_wrong_type` moves, with its
    body unchanged and its TODO comment removed, to a new golden
    generic/template/call_wrong_arg_type.carbon under
    `min_prelude/convert.carbon` (amended 2026-10-14, review fold: A-m8 /
    B-m4): under call.carbon's `min_prelude/none.carbon` it would fail on a
    ``Core.ImplicitAs` implicitly referenced here, but package `Core` not
    found`` artifact; under convert.carbon it fails for the intended reason,
    ``cannot implicitly convert expression of type `X` to `Y` `` with the note
    ``type `X` does not implement interface `Core.ImplicitAs(Y)` `` (measured,
    v13). call.carbon gains the split `dependent_call_two_callees`.
4.  generic/template/member_out_of_line.carbon `fail_todo_basic`: renamed
    `fail_basic.carbon` (D-TP-23, measured on v13; amended 2026-10-14, review
    fold: A-m2).

Refills without a new name (each measured on v13, with the commit that
causes it, §0.8): generic/template/convert.carbon (C1: D-TP-6; C4: D-TP-11),
interop/cpp/range_for.carbon (C1: D-TP-8), class/destroy_calls.carbon (C4:
D-TP-11), lower/testdata/template/class.carbon (C4: one SSA name), and in F6
PR 51's interop/cpp/template/dependent_var_full_prelude.carbon (its
`fail_todo_unformed_dependent_var` split renamed `unformed_dependent_var`,
D-TP-12). Rev 1's facet/period_self.carbon and
interop/cpp/template/generic_call.carbon refills are gone with D-TP-12's
narrowing (amended 2026-10-14, review fold: A-M4 / B-M5).

### §1.10 Conformance programs and their EXPECT derivations (R16(d))

Nine programs under fork/conformance/programs/generics/ (the ninth from the
implementation-review fold; (amended 2026-10-14, implementation-review fold:
IR1-B1)), bullet "Generics: Integrated templates", each derived from the program
text and the design, then cross-checked (never derived) against v13 where it can
run and against the same bodies with the types written out on trunk. Their full
texts, with headers, are in Appendix B (amended 2026-10-14, review fold: B-M1 /
B-M4 / B-m3 / B-m5 / A-m6):

| Program | Forms | EXPECT | Derivation |
| --- | --- | --- | --- |
| templates_dependent_pointer | `*p`, `x.p->n`, `&x.n` and `*q += 1` (X13, X14, X15) | `4`, `7`, `8` | `Deref(&n)` reads `n` = 4; `Next(link)` reads `link.p->n` = `node.n` = 7; `Bump(ref node)` adds 1 to `node.n` through `&node.n` and returns 8. Concrete baseline on trunk prints `4 7 8` ($P/progs/base_pointer.carbon). C3, not run on v13. |
| templates_dependent_index | `p.1` (X16), `a[1]` (X19), `self.item[0]` in a class template (X24) | `5`, `2`, `8` | element 1 of `(4, 5)`; element 1 of `(1, 2, 3)`; element 0 of `(8, 9)`. Concrete baseline prints `5 2 8`. C3, not run on v13. |
| templates_return_aggregates_diff (differential, with `templates_return_aggregates_diff.diff.cpp`) | X29, X30, X31, X32, X33, PR-AK, X18, and a tuple of a template call (review A's b09b) | none (the C++ oracle computes `8 10 8 6 9 4 5 7 7`) | `Dup(4)` sums 4 + 4; `Mk(5)` sums 5 + 5; `Two(4)` sums 4 + 4; `H(i32)` with `a = 3` sums 3 + 3; `Sum((4, 5))` is 9; `Id((4, 5))` prints 4 then 5; `Id({.x = 6, .y = 7}).y` is 7; `G(3)` returns `((3, 3), 1)`, 7. The oracle compiled with the toolchain's clang++ prints the same; v13 prints the same. |
| templates_for_dependent_range | X28 over an array argument, over `Core.Range(c.n)` and over a member array | `6`, `10`, `12` | 1 + 2 + 3; 0 + 1 + 2 + 3 + 4 (`Core.Range(5)` yields 0 to 4, core/prelude/range.carbon); 7 + 2 + 3. Three distinct values, so each loop is told apart (B-m5). v13 prints `6 10 12`. |
| templates_dependent_call | X17 with two callees | `8`, `25` | `Twice(4)`; `Square(5)`. v13 prints `8 25`. |
| templates_constraint_lookup | W-183: a constraint-only member and an `extend impl` member | `25`, `6` | 5 x 5 through `Square`'s `impl as HasArea`; 2 x 3 through `Rect`'s `extend impl`. v13 prints `25 6`. |
| templates_deduce_class_args | W-193: `Holder(T)`, `Holder(T)*`, `Vec(N)`; a class template's literal whose array field has the template bound, in a `var` and returned (amended 2026-10-15, focused re-review of the fold: RR2-1-M2) | `21`, `42`, `3`, `16`, `8` | the item; the item read through the pointer, doubled; the deduced `N`; `SumArr(3, 10)` adds the first and third elements of `(10, 2, 3)` and N, 10 + 3 + 3; `MakeArr(3)`'s second element and N, 5 + 3. v13 prints `21 42 3`; the round-2 head prints all five. |
| templates_dependent_var (rev 1's templates_uninit_var, renamed) | W-127 in a function and a class template method (X20, X23), and `var y: T = x;` for a class with a destructor (B-M4) | `5`, `6`, `11`, `0`, `1` | `Swap(4, 5)` returns its second argument assigned into `y`; `Peek` returns `top` = 6; `Keep(d)` copies `d` with `D`'s `Copy` (n + 10 = 11), and `y`'s destructor prints 11 as `Keep` returns, before `Run` prints `Keep`'s result 0; `d` is destroyed when `Run` returns and prints 1. v13 prints `5 6 11 0 1`; trunk destroys uninitialized storage there (RC-2). |
| templates_constant_elements (added by the implementation-review fold, D-TP-25) | a constant element beside a template-dependent one: `(x, 1)`, `{.a = x, .b = 2}` and `(x, 3)` as an array returned, a `var` of `(x, 1)`, an assignment of `(x, 1)`, `((x, 2), 3)`, a template value `N` beside a runtime value, and a class `P(T)` returned and in a `var` | `41`, `42`, `43`, `41`, `41`, `423`, `34`, `41`, `42` | each line is the first element times 10 plus the second, with x = 4: 4 and 1, 4 and 2, 4 and 3, the `var`'s 4 and 1, the assignment's 4 and 1 over the initial 4 and 9, then 4, 2 and 3 as 400 + 20 + 3, `N` = 3 beside 4, the class's 4 and 1, and the `var`'s 4 and 2. The branch head prints them; trunk stops the compiler (a segfault); the review's twins without a template run on trunk. |

No program pins a nightly difference: R30 governs Carbon-versus-C++
divergence, and no form here diverges from C++; the one differential program
uses the C++ oracle in the agreeing direction (fork/conformance/README.md
"Differential Carbon-vs-C++ programs"), and is named with the `_diff` suffix
that the other 23 differential pairs use. The negative forms (X21's
different entities, a dereference of a non-pointer on instantiation, the
cross-library TODO) are goldens, not programs. Every program avoids constant
nested aggregates (W-263), in-place cursors and defaulted class fields
(W-264, W-265), and RC-10's by-copy aggregates with an in-place element
(W-256), which no program can pin because they print values that change from
run to run (amended 2026-10-14, review fold: RR-M1 / RR-M2).

### §1.11 Docs and records

Amended 2026-10-14 (review fold: B-B2 / B-m2). Docs: TP-1's implementation
commits change no design page. The land-time integration commit L (§2.9,
Appendix C) amends docs/design/templates.md (PR 58's text) with dated notes,
rewrites PR 58's fixtures and adds three, and maps them in
fork/designdocs/check_samples.py. Records, each written in exactly one
commit: the conformance README rows in P (regenerated); the row in R; in D,
last: W-014's notes and evidence, W-127, W-183, W-192 and W-193 discharged
(all four exist on the branch only after M merges PR 51 and PR 58), the
residues W-250 to W-266 filed (amended 2026-10-14, review fold: RR-M1;
W-266 (amended 2026-10-14, implementation-review fold: IR1-M3)), the
decision-log entry "TP-1", and
fork/ORCHESTRATION.md (Appendix E has every text).

### §1.12 Merge position

TP-1 is cut from trunk b2576f6c3 and lands after PR 59 (D-TP-19). Trunk, with
every earlier PR merged, is merged into the branch with a merge commit M,
never a rebase (AGENTS.md "Version control"), **before** the implementation
reviews (amended 2026-10-14, review fold: B-B2): the composition rules of
§0.9 resolve the conflicts, M resolves conflicts only, the commit S after it
adds C5's composition rule with SC-1 (amended 2026-10-14, review fold:
RR-m2), the fill F6 refills what the merge changes, the full build,
autoupdate fixpoint, gate and conformance re-run on the merged head, and the
two implementation reviews then review that head, so C5's composition with
SC-1 and A2's with SC-1's structural checks are reviewed. L, R and D follow
the reviews' fix commits.

**Held state (amended 2026-10-14, implementation: held state).** GitHub Actions
is disabled on the repository, so none of PR 51 to PR 59 is on trunk, and trunk
is 8bfd78ae3, records-only commits over b2576f6c3. M is therefore the merge of
trunk as it is: it brings fork/ORCHESTRATION.md and fork/decision-log.md only,
with no conflict and no toolchain, core or testdata file (6efc3f257), so its
build, gate and conformance are commit P's. The compositions with SC-1 and VA-1
that §3 places in M, S and F6 are measured, not committed: the full TP-1 diff is
composed over each branch's head and relinked over its own build (§0.9,
"Composition at state T"), S's text is measured there, and S, F6 and L stay
land-time commits with the texts of §2.5, §3 and Appendix C. The implementation
reviews review the branch head with trunk's records merged, plus those
measurements. When PR 51 to PR 59 are on trunk, M is repeated as a merge of that
trunk, the composition is measured again on the merged tree, and S, F6 and L
follow it as §3 orders them. D-TP-19's break condition is kept: if the merge
order of record changes, the merge position is decided again. The held-state
commits are M (6efc3f257), the measurement record 4e1f07a91, and the
implementation-review fold's fix commits 7c7b1b170 and 12bd6d67a with their
fills 17501c978 and f360b8735 and its records commit; the compositions were
measured again over the fold's head (§0.9) (amended 2026-10-14,
implementation-review fold: IR2-MINOR-10).

### §1.13 Residues filed (W-250..W-271; W-272..W-274 unused)

Amended 2026-10-14 (review fold: A-M2 / A-M3 / A-m2 / A-m3 / B-M1 / B-M2 /
B-M3 / RR-M1 / RR-M2 / RR-m1) and 2026-10-15 (focused re-review of the fold:
RR1-M1 / RR2-M1 / RR1-m2 / RR1-m3 / RR1-m4 / RR1-m5, items 1 and 18 to 21;
round 2: RR2r2-M1 / RR2-1-M2, items 1, 4 and 22).
Each item's full ledger text, with kind, size, subsystem, evidence and break
condition, is in Appendix E; D files W-250 to W-266, and the focused re-review
of the fold files W-267 to W-270 and, in its round 2, W-271.

1.  W-250 (TR-17). A generic whose definition or declaration is resolved per
    instantiation (an eval block that holds an action or a splice: a
    template, or a checked generic whose definition holds one, such as a call
    of a C++ template), used from another library: `semantics TODO` at the
    `import` (RC-8, D-TP-14), for a function or class template, a class
    template's field types and member function declarations, and an interface
    or named constraint (amended 2026-10-15, focused re-review of the fold:
    RR1-M1 / RR2-M1 / RR1-m2). A checked generic that calls an `eval fn` from
    another library is not detected; its specific reports D-TP-26's
    diagnosis, where trunk stops the compiler (an upstream limit). An entity
    whose declaration, definition or bindings name such a generic, such as a
    nested generic class or a binding constrained by such an interface, is
    diagnosed the same way (amended 2026-10-15, focused re-review of the fold:
    RR2r2-M1), and so is one that names it through a concrete operand, such
    as a callee or a specific's argument (amended 2026-10-15, focused
    re-review of the fold: RR3-1-M1 / RR3r2-M1). Removal: import of action
    and splice instructions and
    cross-file template lowering (lower/handle.cpp:507-513).
2.  W-251 (TR-19). `partial T*` for a template `T` (X26;
    class/partial/qualifier.carbon `fail_todo_partial_template_dependent`):
    needs the `PartialOnFinal` check performed on instantiation.
3.  W-252 (TR-13). `match` on a template-dependent value (X10).
4.  W-253 (TR-12). An array with a template-dependent bound initialized
    from a list (X11; array/init_dependent_bound.carbon
    `fail_todo_init_template_dependent_bound`); the nightly accepts it after
    upstream 947c1eb52. In a class template's literal whose class's fields
    hold such an array, the initializer is converted on instantiation, as on
    trunk (amended 2026-10-15, focused re-review of the fold: RR2-1-M2).
5.  W-254 (TR-20). An out-of-line redeclaration of a template class member
    whose signature names a template-dependent type is rejected even when
    token-identical (`$P/probes/mool.carbon`); its message, after D-TP-23,
    reads ``type `<pattern for T.U>` ... differs from previous parameter type
    `<pattern for T.U>` ``. The stringification half of rev 1's W-254 is fixed
    by D-TP-23.
6.  W-255 (TR-18). Lowering a form-parameter pattern splice crashes for
    `generic` and `template` form parameters (RC-9; f01 is the upstream
    golden `form_generic_param` compiled to an object, f02 the template
    spelling); the pattern-splice fatals of pattern_match.cpp:2174-2180 and
    return.cpp's symbolic-form TODOs (:217, :228) belong to the same feature.
    This is the "pattern splices" of W-014's title, which W-014 keeps open.
7.  W-256. A struct with one field or a tuple with one element, initialized
    by copy, whose element is an aggregate initialized in place (RC-10):
    `Convert` crashes on returning `{.a = x}`, with a template parameter on
    instantiation (s32, fixture X34) and without one where the function is
    defined (s32n), and the program is compiled wrongly, printing values that
    change from run to run, for a nested `{.a = {.b = (x, x)}, .c = x}` with
    a template parameter (q07c, which segfaulted on trunk) and without one
    (q07cn, k02, k04, k05 on trunk). Filed under this bullet because
    templates reach it; no golden or program uses the miscompiling forms
    (amended 2026-10-14, review fold: RR-M2).
8.  W-257. Hardening only: lowering builds an inexact function type when a
    parameter's type is incomplete (lower/type.cpp:493) and continues;
    B5's check makes it fail loudly, but the inexact type should not be
    built at all.
9.  W-258. Upstream-advance reconciliation: 4a8993af2 adds
    `InitializeAction::Target::storage_access_block_id` and fills it with the
    shared storage access block; TP-1 carries a copy of the access chain in
    `storage_id` (D-TP-3). At the next upstream advance, the copy moves into
    upstream's field and the copy rule stays, because upstream's sharing
    takes instructions that the template body still uses, so nested literals
    fail the verifier (amended 2026-10-14, review fold: RR-m1).
10. W-259 (TR-21). An assignment whose left operand is template-dependent is
    not checked on instantiation for being an assignable reference
    (generic/template/operator.carbon `todo_fail_assign_const`,
    `todo_fail_assign_let`).
11. W-260 (TR-8). Proposal 2200 gives a member access the constraint's meaning
    at the definition when the constraint has the name (p002200:744-752); the
    toolchain defers the whole access (review A's a13).
12. W-261 (TR-8). A name that two interfaces of a template parameter's
    constraint declare is not reported as ambiguous at the definition
    (p002200:766-767; review A's a12).
13. W-262 (TR-8). A type-level access `T.F` through a constrained template
    type parameter is not compared with the type's own member
    (member_access.md:436-440; review A's a05, fixture X36).
14. W-263. A constant nested aggregate fails LLVM verification (RC-13; review
    A's h03c and b04d without templates, b04b, b04c and h03 with them).
15. W-264 (TR-4). A template-dependent in-place initializer of a storage root
    allocated after it crashes (RC-12): a `for` loop whose cursor is a tuple
    or a class (`$X/probes/new/n01`, fixture X35; CHECK at
    function_context.cpp:223 while the call is lowered), and a class value
    whose struct literal leaves a field to its default initializer
    (`$Y/probes/v14/t02`, the SemIR verifier during checking). Fix by
    allocating the cursor before its initializer
    (handle_loop_statement.cpp:216-218's own TODO). The value temporaries of
    rev 2's n02 and the re-review's class values are fixed by D-TP-24
    (amended 2026-10-14, review fold: RR-M1).
16. W-265. A runtime class value or `var` whose field takes its default
    initializer stops the compiler while it is lowered (``FATAL failure at
    toolchain/sem_ir/expr_info.cpp:359: Initialization from unexpected inst``,
    from `EmitAggregateInitializer`), with or without a template
    (`$Y/probes/v14/t02n`, `t16n`, `t17n`; trunk and the nightly). Not a
    template defect; filed here because the template form t02 reaches it once
    W-264 is fixed, with the classes row as its candidate owner (added
    2026-10-14, review fold: RR-M1).
17. W-266 (TR-8; added 2026-10-14, implementation-review fold: IR1-M3).
    Member lookup into a constrained template parameter's constraint does not
    apply when the operand's type is the parameter only through a deferred
    member access: a field of a template class (`self.c.F()` in `class
    W(template T: A)`, the first implementation review's f13) or of a class
    whose argument is the parameter (`h.c.F()` for `h: Holder(T)`, f15) is a
    deferred `AccessMemberAction` whose type in the definition is
    `<dependent type>`, so on instantiation `F` is looked up in `C` alone and
    is not found when `C` implements `A` without `extend` (trunk the same).
    Pinned by constraint_lookup.carbon `fail_todo_field_of_template_class`.
    Removal: record the declared type of the field the deferred access
    names, so the constraint of the parameter it is can be consulted.
18. W-267 (TR-4; added 2026-10-15, focused re-review of the fold: RR1-m3).
    The temporaries that a template's actions create on instantiation are
    never destroyed: `MaybeAddCleanupForInst` (check/control_flow.cpp:143-149)
    registers a cleanup only in a cleanup scope, which an action's
    instantiation is not. The first re-review's a06 prints `1000 11 2000 5 5
    3000 1 4000 101 5000 201 6000 1` where its non-template twin prints
    `1000 11 11 2000 5 5 3000 1 4000 101 101 5000 201 201 6000 1` (a `var`
    parameter's copy of `x`, `Mk(x.n + 100)` and `K({.n = x.n + 200})`), and
    a05 prints `100 1 200 12 300 1 400 2 1` against `100 11 1 200 12 11 12 300
    11 1 400 2 1`; trunk the same. A temporary that is not template dependent
    in the same template is destroyed. Removal: register an instantiated
    action's temporaries in the cleanup scope of the statement it is in.
19. W-268 (TR-10; added 2026-10-15, focused re-review of the fold: RR1-m4).
    `var e: T.Elem;` for a template `T: Container` is rejected where the
    function is defined (``cannot convert type `T.Elem` into type implementing
    `Core.DefaultOrUnformed` ``, the first re-review's d03), while `var e: T;`
    works (W-127): `NamesTemplateBinding` (impl_lookup.cpp:578-630) follows
    `InstId`, `TypeInstId`, `InstBlockId` and `SpecificId` operands, not the
    `MetaInstId` operands of a splice's action, so the deferral of D-TP-12
    does not see the template binding; trunk the same, its message printing
    `<splice of <cannot stringify ...>>`. index.carbon's
    `fail_tuple_index_as_var_type_on_instantiation` shows the same
    definition-time lookup for `var a: x.0;`. Removal: follow a splice's
    action's operands in `NamesTemplateBinding`.
20. W-269 (TR-4; added 2026-10-15, focused re-review of the fold: RR1-m5).
    `return {} as T;` for a class `T` without `Copy` is rejected on
    instantiation (``unable to monomorphize specific `R1(A)` `` with ``cannot
    copy value of type `A` ``, the first re-review's e02) where the same code
    without a template parameter compiles and prints 1: the dependent `as`
    forms a value, not an initializer, so the return copies it; trunk and the
    nightly the same. Removal: route a dependent conversion to an
    initializing target through the `InitializeAction` path (D-TP-2).
21. W-270 (TR-17; added 2026-10-15, focused re-review of the fold: RR1-M1 /
    RR2-M1). An interface or named constraint whose later parameter's type
    depends on a template parameter (`interface I(template T: type, U:
    T.Item)`) stops the compiler in its own library when it is used, as in
    `fn UseI[T: I(Holder, 1)](x: T)` (``CHECK failure at
    toolchain/sem_ir/generic.cpp:84: ... Given a specific for the wrong
    generic``; the first re-review's local_i, the fixer's local_i and
    libk2; trunk and the nightly the same). Its import reports W-250's TODO,
    so the imported facet-type and impl paths past it cannot be measured
    until it is fixed. Removal: resolve the later parameter's type in the
    specific of the generic it belongs to.
22. W-271 (TR-17; added 2026-10-15, focused re-review of the fold:
    RR2r2-M1). A generic class from another library that declares a nested
    class or interface stops the compiler where the class is used, as
    `fn Use(unused o: Outer(i32)*) {}` does for
    `class Outer(T: type) { class Inner { var x: T; } }` (``Unexpected inst
    for generic declaration``, a `FacetType`, the FATAL in
    `GetLocalGenericId`, import_ref.cpp:1287 and :1086 on trunk; the fixer's
    t1, v1 with `template T` and s1 with a nested `interface Inner {}`, and
    the second review's y04, y05 and y09; trunk 0bdce60a5 and the nightly the
    same). Not a template defect: the same classes compile in their own
    library, and the import compiles when the class is not used. A generic
    class whose nested class is empty stops at check/generic.cpp:239's CHECK
    on the fork and trunk and compiles on the nightly (q1). When the nested
    class's data names an action, W-250's walk reports the TODO first (y07).
    The mechanism was not investigated; t1 compiling is the break condition.

### §1.14 Decision index (auto-adopted under V-2/V-3; each has a break condition above or here)

-   D-TP-1. The slice is crash and miscompile fixes first (R17), then the
    rejected dependent forms, then W-183, W-193 and W-127, each IN because
    its root cause was found and its cost measured. A template crash whose
    removal exposes a miscompile that the same code without a template
    already has (RC-10's q07c) is accepted only with the miscompile recorded
    (W-256), named in the row and on the page, and kept out of goldens and
    programs, because the only diagnosis measured also rejects working
    programs (§0.3 RC-10, §7.2(11); amended 2026-10-14, review fold: RR-M2).
    _Break:_ a review shows a measured cost understated by more than one fix
    commit.
-   D-TP-2. Same-type template-dependent initialization is a storage-carrying
    `InitializeAction` (§1.2).
-   D-TP-3. The action carries a copy of its storage access chain, and each
    specific places it; the body keeps the originals; pending roots are
    inserted at the action (§1.2; rewritten 2026-10-14, review fold: A-B1).
-   D-TP-4. Replayed initializing conversions get a local storage access block
    (§1.2).
-   D-TP-5. `FindStorageArgForInitializer` is specific-aware; an unresolved
    splice has no storage argument (§1.2).
-   D-TP-6. A dependent value conversion is a `ConvertToValueAction`; a
    tuple-to-type conversion converts the generic's instruction for a spliced
    element's constant (§1.2; (amended 2026-10-15, focused re-review of the
    fold: RR1-M2)).
-   D-TP-7. Lowering reads categories, constants and storage in the
    specific; a spliced in-place initializer has no value (§1.2).
-   D-TP-8. The `for` cursor pointer type is required complete; an inexact
    function type with a return slot is a CHECK (§1.2).
-   D-TP-9. Four action kinds for `*`/`->`, `&`, tuple element access and
    indexing, created only for an opaque template-dependent type, qualified or
    not, a produced type such as `T.Elem` included (§1.3; amended 2026-10-14,
    review fold: A-m7; (amended 2026-10-14, implementation-review fold:
    IR1-m3)).
-   D-TP-10. A function-typed callee with no constant value calls its type's
    function (§1.3).
-   D-TP-11. Generic type constructors with template-dependent argument
    values are formed eagerly (§1.6).
-   D-TP-12. Impl lookup for a query that names a template binding selects
    no impl in the definition (§1.7; rewritten 2026-10-14, review fold: A-M4
    / B-M5).
-   D-TP-13. Member lookup into a constrained template parameter consults the
    type and the constraint on instantiation; different entities, a field
    beside a function included, are an error; over SC-1 a template
    constraint's requirement defers to the type (§1.5; amended 2026-10-14,
    review fold: A-M1 / A-M2 / B-M6).
-   D-TP-14. A generic resolved per instantiation, used from another library, is
    a `semantics TODO` at the `import`, once, with no cascade, a function or
    class template whose declaration holds an action included (§1.2; rewritten
    2026-10-14, review fold: A-m4 / B-m6; (amended 2026-10-14,
    implementation-review fold: IR1-M2)), and a class template's field types
    and member function declarations and an interface's or named constraint's
    declaration too; a checked generic calling an imported `eval fn` is not
    detected ((amended 2026-10-15, focused re-review of the fold: RR1-M1 /
    RR2-M1 / RR1-m2)); an entity whose declaration, definition or bindings
    name such a generic is found by one walk and diagnosed the same way
    ((amended 2026-10-15, focused re-review of the fold: RR2r2-M1)), the
    walk following each reference the import loads, so an entity that names
    one through a concrete operand of an entry, such as a callee or a
    specific's argument, is found too ((amended 2026-10-15, focused
    re-review of the fold: RR3-1-M1 / RR3r2-M1)).
-   D-TP-15. Dropped (A-M3): form parameters are unchanged and filed (W-255).
-   D-TP-16. No upstream cherry-pick; 4a8993af2's representation is used for
    a copy, not the shared block (§0.7; amended 2026-10-14, review fold:
    A-B1). _Break:_ upstream lands a template commit that subsumes one of C1
    to C5 before TP-1's merge, in which case the plan's next revision takes
    it as C0 with upstream authorship.
-   D-TP-17. No fork design id (F-019 unminted): every rule is proposal
    2200's, p2875's or p3763's, and the SC-1 composition rule is SC-1's own
    D-SC-4. _Break:_ a review shows a rule decided here that proposal 2200
    leaves open.
-   D-TP-18. The row stays PARTIAL and W-014 stays OPEN: the first arbiter
    clause is met for the four `fail_todo` splits present when W-014 was filed
    (TP-1's own `fail_todo` splits, twenty-eight since round 3 of the
    focused re-review of the fold, pin W-250 and W-266; (amended 2026-10-14,
    implementation-review fold: IR2-MINOR-6; amended 2026-10-15, focused
    re-review of the fold: RR1-M1 / RR2-M1 / RR2r2-M1 / RR3-1-M1)), the
    second is not
    (handle.cpp:513, :524 at the fold's head, behind W-250), and the residues of
    §1.13 are material gaps (gap-analysis.md:12-13). _Break:_ the row is
    re-graded against gap-analysis.md:12-13 when W-250, W-254, W-255, W-259 and
    W-264 are closed; not moved to DONE on the arbiter alone (amended
    2026-10-14, review fold: B-M2 / A-m2); W-256 and W-265 are not template
    defects and do not hold the row (amended 2026-10-14, review fold: RR-M1 /
    RR-M2).
-   D-TP-19. Merge after PR 59 with a merge of trunk M, before the
    implementation reviews; the PR 58 integration is a separate commit L after
    them (§1.12, §3; amended 2026-10-14, review fold: B-B2). In the held state M
    merges trunk's records only, and the compositions are measured (§1.12 "Held
    state"; (amended 2026-10-14, implementation-review fold: IR2-MINOR-10)).
    _Break:_ the merge order of record changes.
-   D-TP-20. Nine conformance programs, one differential, named `_diff` (§1.10;
    amended 2026-10-14, review fold: A-m6 / B-m3; (amended 2026-10-14,
    implementation-review fold: IR1-B1)). _Break:_ a program's derivation is
    shown wrong; it is re-derived, never re-run to fit.
-   D-TP-21. DD-1's fixtures flip at land time with unique quotes; resolved
    limits get dated notes, never silent deletions; the texts are written in
    full and checked by PR 58's checker before L, and L has a document review
    (§2.9, Appendix C; amended 2026-10-14, review fold: B-B1). _Break:_ PR 58's
    checker, as merged, rejects a fixture kind the texts use.
-   D-TP-22. Commits C1 to C5 with fills, P, M (conflicts only), S (the SC-1
    composition rule) and F6, the implementation reviews, at most three fix
    commits, L with its document review, R, D last; shrink C5 first, then C3's
    `TupleIndexAction` and `IndexAction`; never C1 or C2 (§3; amended
    2026-10-14, review fold: B-B2 / RR-m2). In the held state S, F6 and L are
    land-time commits, and the fold used two of the three fix commits for the
    toolchain and the third for these records (§1.12, §3; (amended 2026-10-14,
    implementation-review fold: IR2-MINOR-10)). The focused re-review of the
    fold adds four toolchain fix commits with their fills, a formatting commit
    and a records commit beyond that budget, for the root-cause reason §3's
    dated note gives; nothing is shrunk ((amended 2026-10-15, focused re-review
    of the fold: RR1-B1 / RR1-M1 / RR1-M2 / RR1-m1 / RR2-m6)); its round 2 adds
    four more with their fills, a commit that makes two of their tests
    iterative for clang-tidy, and a records commit, for the reason the second
    dated note gives ((amended 2026-10-15, focused re-review of the fold:
    RR2-1-M1 / RR2-1-M2 / RR2-1-m1 / RR2r2-M1)); its round 3 adds a fix
    commit with its fill, a commit that records the walk's results for each
    file, a commit of three more splits with its fill, and a records commit,
    for the reason the third dated note gives ((amended 2026-10-15, focused
    re-review of the fold: RR3-1-M1 / RR3r2-M1)). _Break:_ a commit cannot
    compile without a later commit's files.
-   D-TP-23. A diagnostic prints a template-dependent operation's splice as its
    expression, for every action kind a template creates, with a prefix
    operand of a postfix operation in parentheses and an interface member as
    `Interface.Member` (§1.2; added 2026-10-14, review fold: A-m2; (amended
    2026-10-14, implementation-review fold: IR1-m2); (amended 2026-10-15,
    focused re-review of the fold: RR1-m1 / RR2-m6)), and a member access
    through `->` as `p->n` ((amended 2026-10-15, focused re-review of the
    fold: RR2-1-m1)).
-   D-TP-24. A template-dependent conversion that would allocate its own
    temporary for an array, union or class value is deferred whole; a class
    value only when its source names exactly the class's fields (§1.2; added
    2026-10-14, review fold: RR-M1); an initializer of a class whose fields
    hold an array with a template-dependent bound is deferred whole too, an
    aggregate that holds one converting it as its element, and a runtime
    literal with a template-dependent element is referred to in the specific
    ((amended 2026-10-15, focused re-review of the fold: RR2-1-M2)).
    _Break:_ above.
-   D-TP-25. A constant splice lowers the instructions of its block that are
    not constant, where the splice is (§1.2; added 2026-10-14,
    implementation-review fold: IR1-B1). _Break:_ above.
-   D-TP-26. In a specific, an operand that is not constant where a type, an
    always-constant instruction or an operand used as a type needs a constant
    is an error at that operand, and its value in the specific is the error
    constant (§1.2; added 2026-10-14, implementation-review fold: IR1-M1;
    (amended 2026-10-15, focused re-review of the fold: RR1-B1 / RR1-m2)),
    every such operand of the instruction, the first reported ((amended
    2026-10-15, focused re-review of the fold: RR2-1-M1)). _Break:_ above.

## §2 Spec, file by file

### §2.0 Conventions

Code blocks are the v8 prototype's diff where the change was relinked
(marked "measured"), or hand-written against the quoted trunk code where it
was not (marked "hand-predicted"). C++ follows the CI-pinned clang-format
21.1.8 (R18); the implementer runs it. Every comment that cites this fork
says "Fork (TP-1, ...)" only where the code diverges from upstream's
structure; comments state invariants, not history.

### §2.1 Commit C1: initializers keep their storage; splices resolve in the specific

Files: check/convert.cpp, check/pending_block.h,
check/handle_loop_statement.cpp, sem_ir/expr_info.{h,cpp}, lower/aggregate.cpp,
lower/handle.cpp, lower/handle_expr_category.cpp, lower/function_context.cpp,
lower/file_context.cpp.

**A1 and A4, check/convert.cpp `AddConvertActionIfDependent` (measured;
A4 rewritten 2026-10-14, review fold: A-B1).**

<!-- google-doc-style-ignore -->

```diff
   if (context.insts().Get(expr_id).type_id() == target.type_id) {
-    // No conversion required.
-    return SemIR::InstId::None;
+    // No type conversion is required. A template-dependent operand that is not
+    // already an initializer still needs a copy into the target's storage, and
+    // how it is copied (element by element for a struct, tuple or array value,
+    // through `Core.Copy` otherwise) is known only for a concrete type, so
+    // that copy is deferred, with its storage, below.
+    if (!target.is_initializer() || !target.storage_id.has_value() ||
+        SemIR::IsInitializerCategory(
+            SemIR::GetExprCategory(context.sem_ir(), expr_id))) {
+      return SemIR::InstId::None;
+    }
   }
@@
     auto action_type_id = GetTupleType(context, action_type_elements_id);

+    // The action carries its own copy of the instructions that compute
+    // `target.storage_id` from the pending storage access block, so that each
+    // specific can place them where the initialization needs them (in place
+    // of a storage argument of the initializer, as `MergeReplacing` does for a
+    // concrete initialization); the template's own body keeps the originals
+    // for its other uses.
+    auto action_storage_id =
+        CloneStorageAccessChain(context, loc_id, target);
+
     // Create the initialization action.
@@
-                 .storage_id = target.storage_id,
+                 .storage_id = action_storage_id,
```

<!-- google-doc-style-resume -->

The helpers, added before `AddConvertActionIfDependent` (measured):

<!-- google-doc-style-ignore -->

```cpp
// Returns the operand of `arg` if it names an instruction whose value is used.
static auto GetInstOperand(SemIR::IdAndKind arg) -> SemIR::InstId {
  if (auto id = arg.TryAs<SemIR::InstId>()) {
    return *id;
  }
  if (auto id = arg.TryAs<SemIR::DestInstId>()) {
    return *id;
  }
  return SemIR::InstId::None;
}

// Returns whether `inst_id` allocates storage: such an instruction is one
// object, which every use must share, so it is never copied.
static auto IsStorageRoot(Context& context, SemIR::InstId inst_id) -> bool {
  return context.insts().IsOneOf<SemIR::VarStorage, SemIR::TemporaryStorage>(
      inst_id);
}

// Prepares the storage of a template-dependent initialization for an
// `InitializeAction`. The instructions in the pending storage access block
// that `target.storage_id` depends on are copied into a `SpliceBlock` that is
// in no block, whose `InstValue` is returned as the action's storage; the
// action adds the copies to its own storage access block in each specific. A
// pending storage root (the `for` cursor's `VarStorage`, a temporary) is not
// copied: the pending block is inserted here, so that the root precedes the
// action's splice. Returns `target.storage_id` if nothing is pending.
static auto CloneStorageAccessChain(Context& context, SemIR::LocId loc_id,
                                    const ConversionTarget& target)
    -> SemIR::InstId {
  auto pending = target.storage_access_block->insts();
  llvm::SmallVector<SemIR::InstId> worklist = {target.storage_id};
  llvm::SmallVector<SemIR::InstId> chain_ids;
  while (!worklist.empty()) {
    auto inst_id = worklist.pop_back_val();
    if (!llvm::is_contained(pending, inst_id) ||
        llvm::is_contained(chain_ids, inst_id)) {
      continue;
    }
    chain_ids.push_back(inst_id);
    auto inst = context.insts().Get(inst_id);
    for (auto arg : {inst.arg0_and_kind(), inst.arg1_and_kind()}) {
      if (auto operand_id = GetInstOperand(arg); operand_id.has_value()) {
        worklist.push_back(operand_id);
      }
    }
  }
  if (chain_ids.empty()) {
    return target.storage_id;
  }
  // The chain in block order, which is an order in which operands precede
  // their uses.
  llvm::SmallVector<SemIR::InstId> ordered;
  for (auto inst_id : pending) {
    if (llvm::is_contained(chain_ids, inst_id)) {
      ordered.push_back(inst_id);
    }
  }
  if (llvm::any_of(ordered, [&](SemIR::InstId inst_id) {
        return IsStorageRoot(context, inst_id);
      })) {
    target.storage_access_block->InsertHere();
  }
  // Copy the non-root instructions, remapping operands that name an earlier
  // copy.
  Map<SemIR::InstId, SemIR::InstId> copies;
  llvm::SmallVector<SemIR::InstId> copy_ids;
  for (auto inst_id : ordered) {
    if (IsStorageRoot(context, inst_id)) {
      continue;
    }
    auto loc_and_inst = context.insts().GetWithLocId(inst_id);
    auto remap = [&](SemIR::IdAndKind arg) -> int32_t {
      auto operand_id = GetInstOperand(arg);
      if (operand_id.has_value()) {
        if (auto copy = copies.Lookup(operand_id)) {
          return copy.value().index;
        }
      }
      return arg.value();
    };
    loc_and_inst.inst.SetArgs(remap(loc_and_inst.inst.arg0_and_kind()),
                              remap(loc_and_inst.inst.arg1_and_kind()));
    auto copy_id = AddInstInNoBlock(context, loc_and_inst);
    copies.Insert(inst_id, copy_id);
    copy_ids.push_back(copy_id);
  }
  if (copy_ids.empty()) {
    return target.storage_id;
  }
  auto block_id = AddInstInNoBlock<SemIR::SpliceBlock>(
      context, loc_id,
      {.type_id = SemIR::InstType::TypeId,
       .block_id = context.inst_blocks().Add(copy_ids),
       .result_id = copies.Lookup(target.storage_id).value()});
  return context.constant_values().GetInstId(context.constants().GetOrAdd(
      SemIR::InstValue{.type_id = SemIR::InstType::TypeId, .inst_id = block_id},
      SemIR::ConstantDependence::None));
}
```

<!-- google-doc-style-resume -->

`PerformAction(InitializeAction)` (convert.cpp:2474-2530) uses the copy
(measured):

<!-- google-doc-style-ignore -->

```diff
   const auto& target_bundle = context.bundles().Get(action.target_id);
   PendingBlock target_block(&context);
-  auto specific_storage_id = AddSpecificInstToPendingBlock(
-      target_block, target_bundle.storage_id, specific_id);
+  // The storage is either an instruction in the template's body or the
+  // `InstValue` of a copy of the instructions that compute it, which this
+  // specific places where the initialization needs them.
+  auto storage_id = target_bundle.storage_id;
+  if (auto inst_value =
+          context.insts().TryGetAsIfValid<SemIR::InstValue>(storage_id)) {
+    auto splice_block =
+        context.insts().GetAs<SemIR::SpliceBlock>(inst_value->inst_id);
+    for (auto inst_id : context.inst_blocks().Get(splice_block.block_id)) {
+      target_block.AddInstId(inst_id);
+    }
+    storage_id = splice_block.result_id;
+  }
+  auto specific_storage_id =
+      AddSpecificInstToPendingBlock(target_block, storage_id, specific_id);
```

<!-- google-doc-style-resume -->

check/pending_block.h gains two members, beside `AddInst` (measured; the
first is 4a8993af2's):

<!-- google-doc-style-ignore -->

```cpp
  // Appends an existing instruction, which is not in any block, to the pending
  // block.
  auto AddInstId(SemIR::InstId inst_id) -> void { insts_.push_back(inst_id); }

  // The pending instructions, in order.
  auto insts() const -> llvm::ArrayRef<SemIR::InstId> { return insts_; }
```

<!-- google-doc-style-resume -->

Invariant: after the change, a `ConvertToCategoryAction` is created only for
a target without storage or that is not an initializer (the same-type case
with storage now takes the `InitializeAction` branch, which already existed
for the different-type case); an `InitializeAction`'s storage is either an
instruction that is in the body before the action's splice or a copy that the
action places itself; and the body's own storage access instructions are
inserted by whichever conversion would have inserted them without the
action. The dependence test that follows the early exit is unchanged, so a
non-dependent operand still returns `None`. The copy uses the instruction's
generic types, as 4a8993af2's shared block does; the specific's lowering maps
them through its specific. A clang-tidy pass may prefer a `Set` for
`chain_ids`; the chains are a handful of instructions.

**A5, `CategoryConverter::DoStep` `Dependent` case (measured).**

<!-- google-doc-style-ignore -->

```diff
     case SemIR::ExprCategory::Dependent:
+      if (target_.kind == ConversionTarget::Value) {
+        // The result is known to be a value, so record that in the action:
+        // a binding of it, and every use of the binding, then has the value
+        // category in the definition, as it does on instantiation.
+        auto type_inst_id = context_.types().GetTypeInstId(
+            context_.insts().Get(expr_id).type_id());
+        return Done{AddDependentActionSplice<SemIR::ConvertToValueAction>(
+            context_, loc_id_,
+            {.type_id = SemIR::InstType::TypeId,
+             .inst_id = expr_id,
+             .target_type_inst_id = type_inst_id},
+            type_inst_id)};
+      }
       return Done{AddDependentActionSplice<SemIR::ConvertToCategoryAction>(
```

<!-- google-doc-style-resume -->

**A2, the two `PerformAction`s (measured).**

<!-- google-doc-style-ignore -->

```diff
 auto PerformAction(Context& context, SemIR::LocId loc_id,
                    SemIR::ConvertAction action) -> SemIR::InstId {
   const auto& target_bundle = context.bundles().Get(action.target_id);
+  // An initializing target always has a storage access block, which the
+  // aggregate conversions add element storage to. This action carries no
+  // storage, so the block holds only what the conversion itself creates.
+  PendingBlock target_block(&context);
   ConversionTarget target = {
       .kind = ConversionTarget::Kind(target_bundle.conversion_kind.index),
       .type_id = context.types().GetTypeIdForTypeInstId(
-          target_bundle.target_type_inst_id)};
+          target_bundle.target_type_inst_id),
+      .storage_access_block = &target_block};

   auto expr_id =
       PerformBuiltinConversion(context, loc_id, action.inst_id, target);
   expr_id = PerformUserDefinedConversion(context, loc_id, expr_id, target);
-  return PerformCategoryConversion(context, loc_id, expr_id, target);
+  expr_id = PerformCategoryConversion(context, loc_id, expr_id, target);
+  target_block.InsertHere();
+  return expr_id;
 }
```

<!-- google-doc-style-resume -->

`PerformAction(ConvertToCategoryAction)` changes the same way. After SC-1
lands, SC-1's `CheckConversionIsNotOfStructuralRequirement` call stays the
first statement of each (§0.9; composed and measured in scv13). Killer: the
check golden initialize.carbon `return_struct_convert` (review A's e01), which
segfaults without A2 (mutant M3; amended 2026-10-14, review fold: A-m1 /
B-M4).

**A3 and B4, sem_ir/expr_info.{h,cpp} (measured).** The declaration gains a
defaulted fourth parameter and its comment a paragraph:

<!-- google-doc-style-ignore -->

```cpp
// `specific_id` is the specific in which `init_id` is evaluated: in a
// template's specific, a splice in the initializer is resolved to the
// instruction it splices in that specific.
auto FindStorageArgForInitializer(const File& sem_ir, InstId init_id,
                                  bool allow_transitive = true,
                                  SpecificId specific_id = SpecificId::None)
    -> InstId;
```

<!-- google-doc-style-resume -->

The definition drops its local `auto specific_id = SemIR::SpecificId::None;`
and its `SpliceInst` arm returns `InstId::None` when
`GetConstantValueInSpecific(sem_ir, specific_id, inst.inst_id)` is not
concrete, with the comment "The action that produces the spliced instruction
has not been performed: in a template's definition, the initializer and its
storage argument are known only on instantiation." Callers unchanged in check
(convert.cpp:111, :180, :196, :224, :2762; formatter.cpp:1080); lowering
callers pass the specific (B3).

**A6, check/handle_loop_statement.cpp (measured).**

<!-- google-doc-style-ignore -->

```diff
   auto cursor_type_inst_id = context.types().GetTypeInstId(cursor_type_id);
+  auto cursor_ptr_type_id = GetPointerType(context, cursor_type_inst_id);
+  // The code that forms an instruction enforces its type's completeness
+  // (type_completion.h): for a template-dependent cursor type, this records
+  // the requirement, so that each specific completes the pointer type its
+  // `Next` call passes. A pointer type is always complete, so the
+  // diagnostic context adds nothing.
+  RequireCompleteType(context, cursor_ptr_type_id, SemIR::LocId(node_id),
+                      [](auto& /*builder*/) {});
   auto cursor_addr_id = AddInst<SemIR::AddrOf>(
       context, node_id,
-      {.type_id = GetPointerType(context, cursor_type_inst_id),
-       .lvalue_id = cursor_var_id});
+      {.type_id = cursor_ptr_type_id, .lvalue_id = cursor_var_id});
```

<!-- google-doc-style-resume -->

The file includes toolchain/check/type_completion.h.

**A7, check/convert.cpp value temporaries (measured, v14; added 2026-10-14,
review fold: RR-M1).** D-TP-24. The three functions return the source
unconverted when they would allocate a template-dependent value's temporary,
after their definition-time checks; `Convert` then defers the conversion
(`AddConvertActionIfDependent`, the `Value` case's `ConvertToValueAction` or
the `ConvertAction` of an `as`), and `PerformAction` repeats it in the
specific. `OperandDependence` is action.h's, which convert.cpp already
includes.

<!-- google-doc-style-ignore -->

```diff
+// Returns whether a conversion that would allocate its own temporary storage
+// for an aggregate value depends on a template parameter. The temporary is a
+// storage root that the conversion creates after the source's elements, so an
+// element whose in-place initializer is resolved for each instantiation, such
+// as a call of a template that returns an aggregate, would be redirected in the
+// specific to a root that follows it. Such a conversion is instead left to
+// `Convert`, which defers it as one action, so that each specific allocates
+// the temporary as a concrete conversion does.
+static auto IsTemplateDependentValueTemporary(Context& context,
+                                              SemIR::InstId value_id,
+                                              SemIR::TypeId target_type_id)
+    -> bool {
+  return OperandDependence(context, SemIR::MetaInstId(value_id)) ==
+             SemIR::ConstantDependence::Template ||
+         OperandDependence(context, target_type_id) ==
+             SemIR::ConstantDependence::Template;
+}
+
 // Performs a conversion from a tuple to an array type. This function only
@@ ConvertTupleToArray, after the bound and count checks
+  // The bound and the element count are checked above, where the function is
+  // defined; the elements are converted for each instantiation.
+  if (!target.storage_id.has_value() &&
+      IsTemplateDependentValueTemporary(context, value_id, target.type_id)) {
+    return value_id;
+  }
+
   PendingBlock target_block_storage(&context);
@@ ConvertStructToUnion
   PendingBlock target_block(&context);

+  // A template-dependent union value is converted for each instantiation,
+  // after the designated field is checked below.
+  bool defer_value = !target.is_initializer() &&
+                     IsTemplateDependentValueTemporary(context, value_id,
+                                                       target.type_id);
+
   // If we're trying to create a union value, form temporary storage to hold
   // the initializer.
-  if (!target.is_initializer()) {
+  if (!target.is_initializer() && !defer_value) {
@@ ConvertStructToUnion, after the designated field is found
   auto dest_field_index =
       static_cast<size_t>(dest_field_it - dest_elem_fields.begin());
+  if (defer_value) {
+    return value_id;
+  }
@@ before ConvertStructToClass
+// Returns whether the struct type `src_type` names exactly the fields of
+// `dest_type` that a struct can initialize, which excludes a class's vptr and
+// a choice's payload.
+static auto HasSameFieldNames(Context& context, SemIR::StructType src_type,
+                              SemIR::StructType dest_type) -> bool {
+  auto src_fields = context.struct_type_fields().Get(src_type.fields_id);
+  int32_t num_dest_fields = 0;
+  for (auto dest_field :
+       context.struct_type_fields().Get(dest_type.fields_id)) {
+    if (dest_field.name_id == SemIR::NameId::Vptr ||
+        dest_field.name_id == SemIR::NameId::ChoicePayload) {
+      continue;
+    }
+    ++num_dest_fields;
+    if (!llvm::any_of(src_fields, [&](const SemIR::StructTypeField& field) {
+          return field.name_id == dest_field.name_id;
+        })) {
+      return false;
+    }
+  }
+  return static_cast<int32_t>(src_fields.size()) == num_dest_fields;
+}
+
@@ ConvertStructToClass
   // If we're trying to create a class value, form temporary storage to hold the
-  // initializer.
+  // initializer. A template-dependent source whose fields are exactly the
+  // class's is converted for each instantiation instead; any other source is
+  // converted here, so that a missing or unexpected field is diagnosed where
+  // the function is defined.
   if (!target.is_initializer()) {
+    if (IsTemplateDependentValueTemporary(context, value_id, target.type_id) &&
+        HasSameFieldNames(context, src_type, dest_struct_type)) {
+      return value_id;
+    }
     target.kind = ConversionTarget::Initializing;
@@ ConvertStructToClass, get_default
   auto get_default = [&](SemIR::NameId name_id) {
-    if (!context.insts().Is<SemIR::StructLiteral>(value_id)) {
+    // A deferred conversion refers to the literal through a `SpecificInst`.
+    if (!GetAggregateLiteralElements<SemIR::StructLiteral>(context, value_id)
+             .has_value()) {
       return SemIR::InstId::None;
     }
```

<!-- google-doc-style-resume -->

Measured on v14 (§0.3, §0.6, §0.8): the RC-12 value forms run; the gate's
failure output is byte-identical to v13's; conformance 128/0/22; mutants M19
(v13, without A7) and M20 (without `HasSameFieldNames`) are killed by
initialize.carbon's new splits (§8.5). The hunks apply to SC-1's, VA-1's and
OP-2's copies of convert.cpp of 2026-10-14 with offsets only (`patch
--dry-run`, `$Y/dry`).

**B1, lowering categories in the specific (measured).** Each of
lower/aggregate.cpp:56, lower/handle.cpp:105 (`Assign`),
lower/handle_expr_category.cpp:61 (`Temporary`), :77 (`ValueAsRef`) and :87
(`ValueOfInitializer`) becomes

<!-- google-doc-style-ignore -->

```cpp
SemIR::GetExprCategory(context.sem_ir(), <inst>, &context.specific_sem_ir(),
                       context.specific_id())
```

<!-- google-doc-style-resume -->

as `ReturnExpr` (handle.cpp:378-381) already is; aggregate.cpp gains the
comment "The aggregate can be a splice in a template's specific; its category
is that of the spliced instruction."

**B2, lower/handle.cpp splice handlers (measured).**

<!-- google-doc-style-ignore -->

```diff
 auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                 SemIR::SpliceBlock inst) -> void {
   context.LowerBlockContents(inst.block_id);
-  context.SetLocal(inst_id, context.GetValue(inst.result_id));
+  // In a template's specific, the result can be an in-place initializer,
+  // which has no value; see the `SpecificInst` case above.
+  if (auto* value = context.GetValue(inst.result_id, /*require_value=*/false)) {
+    context.SetLocal(inst_id, value);
+  }
 }
@@
     context.LowerInst(inst_value.inst_id);
-    context.SetLocal(inst_id, context.GetValue(inst_value.inst_id));
+    // The spliced instruction can be an in-place initializer, which has no
+    // value; see the `SpecificInst` case above.
+    if (auto* value =
+            context.GetValue(inst_value.inst_id, /*require_value=*/false)) {
+      context.SetLocal(inst_id, value);
+    }
```

<!-- google-doc-style-resume -->

Invariant: a consumer that needs the splice's value still fails loudly in
`GetValue` with `require_value` (the default); only the splice itself no
longer demands one.

**B3, lower/aggregate.cpp `EmitAggregateInitializer`, lower/handle.cpp
`ArrayInit`, lower/function_context.cpp `InitializeStorage` (measured).**

<!-- google-doc-style-ignore -->

```diff
       for (auto [i, ref_id] : llvm::enumerate(refs)) {
-        if (context.sem_ir().constant_values().Get(ref_id).is_constant()) {
-          auto dest_id =
-              SemIR::FindStorageArgForInitializer(context.sem_ir(), ref_id);
+        // Whether the element was skipped as a constant is decided in the
+        // specific, as `LowerInst` decides it.
+        if (context.IsConstant(ref_id)) {
+          auto dest_id = SemIR::FindStorageArgForInitializer(
+              context.sem_ir(), ref_id, /*allow_transitive=*/true,
+              context.specific_id());
```

<!-- google-doc-style-resume -->

handle.cpp:87-89 changes the same way; function_context.cpp:438-442 passes
`specific_id_`.

**B5, lower/file_context.cpp `GetOrCreateLLVMFunction` (hand-predicted).**
Before `return_arg.addAttr` (:438-442):

<!-- google-doc-style-ignore -->

```cpp
CARBON_CHECK(!llvm_function->arg_empty(),
             "Return slot for {0} without parameters: a parameter type was "
             "not complete when the function type was built",
             mangled_name);
```

<!-- google-doc-style-resume -->

### §2.2 Commit C2: cross-library generics are diagnosed; dependent operations print as expressions

Amended 2026-10-14 (review fold: A-M3 / A-m2 / A-m4 / B-m6). Files:
check/import_ref.cpp, sem_ir/stringify.cpp. Rev 1's
check/handle_binding_pattern.cpp change is dropped with D-TP-15.

**check/import_ref.cpp `TryFinishGeneric` (measured).** The block from
`GetLocalSpecificData` to the end of the function becomes:

<!-- google-doc-style-ignore -->

```cpp
  auto specific_data =
      GetLocalSpecificData(resolver, import_generic.self_specific_id);

  // A definition that holds actions or the splices of their results is
  // resolved for each instantiation (a template's, or a checked generic's that
  // calls a C++ template or an `eval fn`). Instantiating it in this file needs
  // a representation of that resolution that does not exist yet (lowering's
  // "Cross-file template lowering" has the same gap), so the definition is
  // not imported and the import is diagnosed once, at the `import`.
  auto definition_block_id = import_generic.definition_block_id;
  bool resolved_per_instantiation =
      definition_block_id.has_value() &&
      llvm::any_of(resolver.import_ir().inst_blocks().Get(definition_block_id),
                   [&](SemIR::InstId inst_id) {
                     auto kind =
                         resolver.import_ir().insts().Get(inst_id).kind();
                     return kind.is_action() ||
                            kind == SemIR::SpliceInst::Kind ||
                            kind == SemIR::SpliceBlock::Kind;
                   });

  llvm::SmallVector<SemIR::InstId> definition_block;
  if (definition_block_id.has_value() && !resolved_per_instantiation) {
    definition_block =
        GetLocalInstBlockContents(resolver, definition_block_id);
  }

  if (resolver.HasNewWork()) {
    return false;
  }

  auto& local_generic = resolver.local_generics().Get(local_generic_id);
  CARBON_CHECK(!local_generic.self_specific_id.has_value(),
               "Currently assuming we can't find a GenericId multiple ways");

  local_generic.self_specific_id =
      GetOrAddLocalSpecific(resolver, import_generic.self_specific_id,
                            specific_data, local_generic_id);

  if (resolved_per_instantiation) {
    auto import_decl_id =
        resolver.local_ir().import_irs().Get(resolver.import_ir_id()).decl_id;
    resolver.local_context().TODO(
        import_decl_id.has_value() ? SemIR::LocId(import_decl_id)
                                   : SemIR::LocId::None,
        "using a generic from another library whose definition is resolved "
        "for each instantiation, such as a template");
    // An empty definition: its uses resolve, so the missing body is not
    // diagnosed a second time, and the file is not lowered.
    local_generic.definition_block_id = SemIR::InstBlockId::Empty;
  } else if (definition_block_id.has_value()) {
    local_generic.definition_block_id = ResolveLocalEvalBlock(
        resolver, definition_block_id, definition_block, local_generic_id,
        SemIR::GenericInstIndex::Region::Definition);
  }
  return true;
}
```

<!-- google-doc-style-resume -->

The diagnostic is emitted after the `HasNewWork()` retry point, so a retried
import reports once; rev 1's sketch emitted it before, at `LocId::None`.
Measured output (`$X/probes/xlibA`): ``main_box.carbon:1:1: error: semantics
TODO: `using a generic from another library whose definition is resolved for
each instantiation, such as a template` `` with the `import` line, and no
``use of undefined generic function``.

**sem_ir/stringify.cpp `Stringifier` (measured, D-TP-23).** The `SpliceInst`
overload becomes the first function below, and the four action overloads are
added after it:

<!-- google-doc-style-ignore -->

```cpp
  auto StringifyInst(InstId /*inst_id*/, SpliceInst inst) -> void {
    // The splice of a template-dependent operation is printed as the
    // expression the operation performs.
    if (sem_ir_->insts().Get(inst.inst_id).kind().is_action()) {
      step_stack_->PushInstId(inst.inst_id);
      return;
    }
    *out_ << "<splice of ";
    step_stack_->Push(inst.inst_id, ">");
  }

  // Template-dependent operations, printed as the expressions they perform.
  auto StringifyInst(InstId /*inst_id*/, AccessMemberAction inst) -> void {
    step_stack_->Push(InstId(inst.base_id), ".", inst.name_id);
  }

  auto StringifyInst(InstId /*inst_id*/, ConvertAction inst) -> void {
    step_stack_->PushInstId(inst.inst_id);
  }

  auto StringifyInst(InstId /*inst_id*/, ConvertToCategoryAction inst)
      -> void {
    step_stack_->PushInstId(inst.inst_id);
  }

  auto StringifyInst(InstId /*inst_id*/, ConvertToValueAction inst) -> void {
    step_stack_->PushInstId(inst.inst_id);
  }
```

<!-- google-doc-style-resume -->

### §2.3 Commit C3: dependent dereference, address-of, tuple element access, indexing and calls

Hand-predicted (the X-macro list is not relinkable), except call.cpp (measured).
The complete code of every file -- the four `inst_kind.def` lines, the four
`typed_insts.h` structs, `IsOpaqueTemplateDependentType`,
`PerformPointerDereference` with its kind enum and its two diagnostics,
`PerformAddrOf`, the `PerformTupleAccess` deferral, `PerformIndex`, the four
`PerformAction` bodies and the three handler rewrites -- is in Appendix D,
marked hand-predicted (amended 2026-10-14, review fold: B-M1 / A-m7). Files:
sem_ir/inst_kind.def, sem_ir/typed_insts.h, check/pointer_dereference.h,
check/pointer_dereference.cpp, check/handle_operator.cpp, check/handle_name.cpp,
check/member_access.cpp (`PerformTupleAccess` and
`PerformAction(TupleIndexAction)`), check/member_access.h,
check/handle_index.cpp, check/call.cpp.

**sem_ir/inst_kind.def**: the list is alphabetical (as SC-1's and VA-1's
additions are; rev 1's §6 said append-only, amended 2026-10-14, review fold:
B-m2), in ASCII order: `AddrOfAction` after `AddrOf` (:25),
`IndexAction` between `InPlaceInit` and `InitForm` (:102-103),
`PointerDereferenceAction` between `PatternType` and `PointerType`
(:132-133), `TupleIndexAction` between `TupleAccess` and `TupleInit`
(:172-173).

**check/call.cpp `PerformCallHelper` (measured).**

<!-- google-doc-style-ignore -->

```diff
                               bool is_desugared) {
+  // A function's type has one value, the function (proposal 2875), so a
+  // callee of function type with no constant value, such as a template's
+  // parameter `h: G` once `G` is `<type of F>`, calls that function. The
+  // callee expression has already been evaluated; only its value is replaced.
+  if (!context.constant_values().Get(callee_id).is_constant()) {
+    auto callee_type_id = context.insts().Get(callee_id).type_id();
+    if (context.types().Is<SemIR::FunctionType>(callee_type_id)) {
+      callee_id = AddInst<SemIR::StructValue>(
+          context, loc_id,
+          {.type_id = callee_type_id,
+           .elements_id = SemIR::InstBlockId::Empty});
+    }
+  }
+
   // Try treating the callee as a function first.
```

<!-- google-doc-style-resume -->

(The prototype also tested `has_value()`; `is_constant()` is false for
`None`, so the single test suffices.)

### §2.4 Commit C4: class-argument deduction and deferred impl lookup

**check/call.cpp `IsCallPerformable` (measured).**

<!-- google-doc-style-ignore -->

```diff
   if (OperandDependence(context, callee_id) ==
       SemIR::ConstantDependence::Template) {
     return false;
   }
+  // A generic class, interface or named constraint applied to arguments forms
+  // a type. Its arguments are compile-time values that can be symbolic, as in
+  // a checked generic, so a template-dependent argument value makes the type
+  // dependent without making the call dependent; only an argument whose type
+  // is template-dependent defers the call. Forming the type now is what lets
+  // `Holder(T)` in a parameter's type deduce `T`.
+  bool forms_type = context.types().IsOneOf<
+      SemIR::GenericClassType, SemIR::GenericInterfaceType,
+      SemIR::GenericNamedConstraintType>(
+      context.insts().Get(callee_id).type_id());
   for (auto arg_id : arg_ids) {
-    if (OperandDependence(context, arg_id) ==
-        SemIR::ConstantDependence::Template) {
+    auto dependence =
+        forms_type
+            ? OperandDependence(context, context.insts().Get(arg_id).type_id())
+            : OperandDependence(context, arg_id);
+    if (dependence == SemIR::ConstantDependence::Template) {
       return false;
     }
   }
```

<!-- google-doc-style-resume -->

After SC-1 lands, its +14 lines in call.cpp are in `PerformCallToFunction`,
not here (dry run applies with an 8-line offset).

**check/impl_lookup.cpp (measured on v12; rewritten 2026-10-14, review fold:
A-M4 / B-M5).** Two helpers before the `ImportImplFilter` class:

<!-- google-doc-style-ignore -->

```cpp
// Returns whether the constant instruction `inst_id` names a template binding,
// directly or through its operands. Template dependence alone does not say so:
// a C++ template instantiated with symbolic arguments and the result of an
// `eval fn` are template dependent in a checked generic, too.
static auto NamesTemplateBinding(Context& context, SemIR::InstId inst_id)
    -> bool {
  llvm::SmallVector<SemIR::InstId> worklist = {inst_id};
  llvm::SmallVector<SemIR::InstId> visited;
  auto push = [&](SemIR::InstId id) {
    if (!id.has_value() || llvm::is_contained(visited, id)) {
      return;
    }
    if (!context.constant_values().Get(id).is_symbolic()) {
      return;
    }
    visited.push_back(id);
    worklist.push_back(id);
  };
  auto push_specific = [&](SemIR::SpecificId specific_id) {
    if (specific_id.has_value()) {
      for (auto arg_id : context.inst_blocks().Get(
               context.specifics().Get(specific_id).args_id)) {
        push(arg_id);
      }
    }
  };
  while (!worklist.empty()) {
    auto inst = context.insts().Get(worklist.pop_back_val());
    if (auto binding = inst.TryAs<SemIR::SymbolicBinding>()) {
      if (context.entity_names().Get(binding->entity_name_id).is_template) {
        return true;
      }
    }
    for (auto arg : {inst.arg0_and_kind(), inst.arg1_and_kind()}) {
      if (auto id = arg.TryAs<SemIR::InstId>()) {
        push(*id);
      } else if (auto id = arg.TryAs<SemIR::TypeInstId>()) {
        push(*id);
      } else if (auto id = arg.TryAs<SemIR::InstBlockId>()) {
        if (id->has_value()) {
          for (auto elem_id : context.inst_blocks().Get(*id)) {
            push(elem_id);
          }
        }
      } else if (auto id = arg.TryAs<SemIR::SpecificId>()) {
        push_specific(*id);
      } else if (auto id = arg.TryAs<SemIR::SpecificInterfaceId>()) {
        push_specific(context.specific_interfaces().Get(*id).specific_id);
      } else if (auto id = arg.TryAs<SemIR::StructTypeFieldsId>()) {
        for (auto field : context.struct_type_fields().Get(*id)) {
          push(field.type_inst_id);
        }
      }
    }
  }
  return false;
}

// Returns whether impl lookup for the query is delayed until the template it
// is in is instantiated (proposal 2200: "until all templated types,
// interfaces, and parameters are known"): its self or its interface names a
// template binding.
static auto QueryNamesTemplateBinding(
    Context& context, SemIR::ConstantId self_const_id,
    const SemIR::SpecificInterface& specific_interface) -> bool {
  if (context.constant_values().GetDependence(self_const_id) ==
          SemIR::ConstantDependence::Template &&
      NamesTemplateBinding(context,
                           context.constant_values().GetInstId(self_const_id))) {
    return true;
  }
  if (!specific_interface.specific_id.has_value()) {
    return false;
  }
  for (auto arg_id : context.inst_blocks().Get(
           context.specifics().Get(specific_interface.specific_id).args_id)) {
    if (context.constant_values().GetDependence(
            context.constant_values().Get(arg_id)) ==
            SemIR::ConstantDependence::Template &&
        NamesTemplateBinding(context, arg_id)) {
      return true;
    }
  }
  return false;
}
```

<!-- google-doc-style-resume -->

In `EvalLookupSingleFinalWitness`, after the
`impl_lookup_no_symbolic_final_lookups` early return (:1250-1254):

<!-- google-doc-style-ignore -->

```cpp
  // Proposal 2200: impl lookup for a template-dependent query is performed
  // when the template is instantiated; no impl is selected in the definition,
  // not even a final one whose requirements could be proven only then.
  if (QueryNamesTemplateBinding(context, query_self_const_id,
                                query_specific_interface)) {
    return SemIR::ConstantId::None;
  }
```

<!-- google-doc-style-resume -->

and in `LookupImplWitness`'s loop, before the `FindNonFinalWitness` test
(:1080-1087):

<!-- google-doc-style-ignore -->

```cpp
    // Proposal 2200 ("Use of dependent value is dependent"): impl lookup for a
    // template-dependent query is performed when the template is
    // instantiated, so the deferred `LookupImplWitness` is the witness even
    // when no candidate impl can be shown to apply in the definition.
    if (QueryNamesTemplateBinding(context, req_impl.self_facet_value,
                                  req_impl.specific_interface)) {
      result_witness_ids.push_back(result_witness_id);
      continue;
    }
```

<!-- google-doc-style-resume -->

### §2.5 Commit C5: member lookup into a constrained template parameter

**check/member_access.cpp (measured on v13, verbatim; the diagnostic emit is
hand-predicted; amended 2026-10-14, review fold: B-M1 / A-M1 / B-M6).** Two
helpers before `PerformAction(AccessMemberAction)`:

<!-- google-doc-style-ignore -->

```cpp
// Looks `name_id` up in the constraint of the template parameter whose type the
// deferred member access's operand had in the template's definition: for
// `x: T` with `template T:! I`, `x.F` also finds `I.F` for the argument's facet
// (proposal 2200, "Name lookup"). Returns `None` if the operand's type was not
// such a parameter or the constraint has no such member.
static auto LookupMemberInTemplateConstraint(Context& context,
                                             SemIR::LocId loc_id,
                                             SemIR::InstId base_id,
                                             SemIR::NameId name_id)
    -> SemIR::InstId {
  auto specific_inst = context.insts().TryGetAs<SemIR::SpecificInst>(base_id);
  if (!specific_inst) {
    return SemIR::InstId::None;
  }
  auto facet_access_type = context.types().TryGetAs<SemIR::FacetAccessType>(
      context.insts().Get(specific_inst->inst_id).type_id());
  if (!facet_access_type) {
    return SemIR::InstId::None;
  }
  auto facet_const_id = SemIR::GetConstantValueInSpecific(
      context.sem_ir(), specific_inst->specific_id,
      facet_access_type->facet_value_inst_id);
  auto facet_id = context.constant_values().GetInstIdIfValid(facet_const_id);
  if (!facet_id.has_value()) {
    return SemIR::InstId::None;
  }
  auto facet_type_id = context.insts().Get(facet_id).type_id();
  if (!context.types().IsConstrainedFacetType(facet_type_id)) {
    return SemIR::InstId::None;
  }
  auto facet_type_const_id = context.types().GetConstantId(facet_type_id);
  llvm::SmallVector<LookupScope> lookup_scopes;
  if (!AppendLookupScopesForConstant(context, loc_id, facet_type_const_id,
                                     facet_const_id, /*extended_scope=*/false,
                                     &lookup_scopes)) {
    return SemIR::InstId::None;
  }
  // Probe first, so that a name the constraint lacks is not diagnosed.
  if (!LookupQualifiedName(context, loc_id, name_id, lookup_scopes,
                           /*required=*/false)
           .scope_result.is_found()) {
    return SemIR::InstId::None;
  }
  // An associated entity found in the constraint is accessed in the
  // argument's type through its impl, as `x.(I.F)` is.
  auto member_id = LookupMemberNameInScope(
      context, loc_id, base_id, name_id, facet_type_const_id, lookup_scopes,
      /*lookup_in_type_of_base=*/true, /*required=*/true);
  if (member_id == SemIR::ErrorInst::InstId) {
    return member_id;
  }
  return PerformInstanceBinding(context, loc_id, base_id, member_id);
}

// Returns whether two member access results name the same entity: the
// function a bound method binds, or the result itself.
static auto SameMemberEntity(Context& context, SemIR::InstId a_id,
                             SemIR::InstId b_id) -> bool {
  auto a = SemIR::GetCallee(context.sem_ir(), a_id);
  auto b = SemIR::GetCallee(context.sem_ir(), b_id);
  auto* a_fn = std::get_if<SemIR::CalleeFunction>(&a);
  auto* b_fn = std::get_if<SemIR::CalleeFunction>(&b);
  if (a_fn && b_fn) {
    return a_fn->function_id == b_fn->function_id &&
           a_fn->enclosing_specific_id == b_fn->enclosing_specific_id;
  }
  if (a_fn || b_fn) {
    // A function and a member that is not a function: a field, or a
    // constant of another kind.
    return false;
  }
  // Two members that are not functions name the same entity only if they
  // have the same constant value; a member without one (a field) is distinct
  // from every other result.
  auto a_const_id = context.constant_values().Get(a_id);
  return a_const_id.is_constant() &&
         a_const_id == context.constant_values().Get(b_id);
}
```

<!-- google-doc-style-resume -->

`PerformAction(AccessMemberAction)` becomes (the prototype emitted a
`context.TODO` where the diagnostic is, because the new kind needs
diagnostics/kind.def):

<!-- google-doc-style-ignore -->

```cpp
auto PerformAction(Context& context, SemIR::LocId loc_id,
                   SemIR::AccessMemberAction action) -> SemIR::InstId {
  // Proposal 2200: a member of a template-dependent operand is looked up in
  // the argument's type and in the template parameter's constraint; if both
  // find it, they must find the same entity.
  auto constraint_member_id = LookupMemberInTemplateConstraint(
      context, loc_id, action.base_id, action.name_id);
  if (!constraint_member_id.has_value()) {
    return PerformActionHelper(context, loc_id, action.base_id, action.name_id,
                               /*required=*/true);
  }
  auto type_member_id = PerformActionHelper(
      context, loc_id, action.base_id, action.name_id, /*required=*/false);
  if (!type_member_id.has_value() ||
      type_member_id == SemIR::ErrorInst::InstId) {
    return constraint_member_id;
  }
  if (constraint_member_id != SemIR::ErrorInst::InstId &&
      !SameMemberEntity(context, type_member_id, constraint_member_id)) {
    CARBON_DIAGNOSTIC(TemplateMemberLookupAmbiguous, Error,
                      "member name `{0}` names different entities in type {1} "
                      "and in its constraint {2}",
                      SemIR::NameId, SemIR::TypeId, SemIR::TypeId);
    // The argument's type, and the constraint's facet type: the type of the
    // facet value that `LookupMemberInTemplateConstraint` found.
    auto base_type_id = context.insts().Get(action.base_id).type_id();
    auto facet_const_id = SemIR::ConstantId::None;
    auto facet_type_id = GetTemplateConstraintFacetType(
        context, action.base_id, &facet_const_id);
    context.emitter().Emit(loc_id, TemplateMemberLookupAmbiguous,
                           action.name_id, base_type_id, facet_type_id);
    return SemIR::ErrorInst::InstId;
  }
  return type_member_id;
}
```

<!-- google-doc-style-resume -->

`GetTemplateConstraintFacetType` (hand-predicted) is the first half of
`LookupMemberInTemplateConstraint` -- from the `SpecificInst` test to
`facet_type_id` -- factored out and returning `facet_type_id` (or
`TypeId::None`), so that both functions share it. The
`TemplateMemberLookupAmbiguous` line goes into diagnostics/kind.def in the
member-access group, in the alphabetical place the file uses there.

Measured at implementation (amended 2026-10-14, implementation-review fold:
IR2-MINOR-2): the tree takes Appendix D's three-argument helper, so
`PerformAction(AccessMemberAction)` passes a local `facet_const_id`, as the
block above now shows, and `LookupMemberInTemplateConstraint` calls the helper
for its first half instead of repeating it. diagnostics/kind.def has no
member-access group: the line is in the "Name lookup" group, which holds
`MemberNameNotFound`, between `NoPeriodSelfForDesignator` and
`UsedBeforeInitialization`. `SameMemberEntity`'s comment says what it returns, a
bool ((amended 2026-10-14, implementation-review fold: IR2-MINOR-9)).

**Over SC-1 (commit S, right after M; measured in scv13b; amended 2026-10-14,
review fold: RR-m2).** SC-1's `LookupMemberNameInScope`
already delegates to its `LookupMemberNameInTypeScopes` with an `AccessInfo`
and `diagnose`; C5 calls it unchanged. After the lookup, before the instance
binding:

<!-- google-doc-style-ignore -->

```cpp
  // Fork (TP-1 over SC-1): a member requirement of a `template constraint` is
  // satisfied by the type's own member of that name (structural conformance),
  // so it names the same entity as the lookup in the type, which decides.
  if (GetStructuralRequirementRef(context, member_id)) {
    return SemIR::InstId::None;
  }
```

<!-- google-doc-style-resume -->

Without it, `x.Get()` on a value of a `template constraint` parameter is
reported as two entities (scv13: nine of SC-1's goldens change, among them
the splits `satisfy`, `const_method_value_self`,
`self_facet_in_signature_required`, `dependent_caller` and `ladder`, which
fail where they succeeded); with it, none changes (scv13b).

### §2.6 Commit P: conformance programs

Amended 2026-10-14 (review fold: B-M1 / A-m6 / B-m3 / B-M4 / B-m5). Eight
programs under fork/conformance/programs/generics/ and one C++ oracle; their
full texts, each beginning with the license comment, `// CONFORMANCE-BULLET:
Generics: Integrated templates`, the EXPECT lines of §1.10 and a comment with
the forms, the derivation and the DD-1 fixtures it supersedes, are in Appendix
B. The differential program is `templates_return_aggregates_diff.carbon` with
`templates_return_aggregates_diff.diff.cpp`, as the 23 existing differential
pairs are named. fork/conformance/README.md's program table is generated: P runs
`python3 fork/conformance/runner.py --update-readme-table`, then `python3
fork/conformance/runner.py --self-test` (R7). Measured in a scratch copy of
fork/ (`$X/confsim`): the regeneration adds exactly the eight rows below, in
sorted position after `generics/structural_conformance.carbon` and around
`generics/templates_dependent_member.carbon`, and the self-test reports
``self-test: 158 programs parsed, 56 bullets in table, OK``.

<!-- google-doc-style-ignore -->

```text
| `generics/templates_constraint_lookup.carbon` | Generics: Integrated templates | run |
| `generics/templates_deduce_class_args.carbon` | Generics: Integrated templates | run |
| `generics/templates_dependent_call.carbon` | Generics: Integrated templates | run |
| `generics/templates_dependent_index.carbon` | Generics: Integrated templates | run |
| `generics/templates_dependent_pointer.carbon` | Generics: Integrated templates | run |
| `generics/templates_dependent_var.carbon` | Generics: Integrated templates | run |
| `generics/templates_for_dependent_range.carbon` | Generics: Integrated templates | run |
| `generics/templates_return_aggregates_diff.carbon` | Generics: Integrated templates | differential |
```

<!-- google-doc-style-resume -->

### §2.7 Golden sources (AUTOUPDATE, no CHECK lines)

Amended 2026-10-14 (review fold: B-M1 / A-B1 / A-M1 / A-m1 / A-m7 / A-m8 /
B-M4 / B-m4). Every source is in Appendix A, verbatim. New check goldens,
each `// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon`
unless noted:

-   check/testdata/generic/template/initialize.carbon (C1): `return_tuple`,
    `return_struct`, `return_array`, `class_method_return_tuple`,
    `return_param_tuple` (PR-AK), `copy_struct` (X18), `returned_var_tuple`
    (s30), `value_param_return_tuple` (s22), `return_tuple_of_call` (b09b),
    `return_two_calls` (b09), `return_nested_literal` (b09e),
    `var_tuple_of_call` (c1), `var_dependent_type_from_literal_of_call` (n03),
    `return_struct_of_call` (c3), `class_method_tuple_of_call` (c4),
    `nontemplate_call_in_template_literal` (c5), `let_class_value_of_call`
    (the re-review's r4, M19's killer), `let_array_value_of_calls` (n02),
    `fail_class_value_unexpected_field` (t13 without a call, M20's killer;
    amended 2026-10-14, review fold: RR-M1), `return_struct_convert`
    (e01, M3's killer), `var_with_destructor` (b02, M16's killer),
    `destructure_param` (X33), `destructure_member` (s34).
-   check/testdata/generic/template/for_range.carbon (C1): `range_param`
    (no call), `range_param_called_array`, `range_member_array`,
    `range_core_range`, `range_dependent_bound` (`array(i32, N)`).
-   check/testdata/generic/template/fail_todo_import.carbon (C2, under
    min_prelude/none.carbon): `lib.carbon` (a function template, a class
    template and a plain function), `fail_todo_import_function.carbon`,
    `fail_todo_import_class.carbon`, `import_unused.carbon` (no error). The fold
    adds to `lib.carbon` a class `Holder`, a function template `Elem` whose
    return type is `T.Item` and a class template `Pick` whose parameter type is
    `T.Item`, and the splits `fail_todo_import_function_declaration` and
    `fail_todo_import_class_declaration` (amended 2026-10-14,
    implementation-review fold: IR1-M2). The focused re-review of the fold adds
    to `lib.carbon` the class templates `FieldBox` (a field of type `T.Item`)
    and `MethodBox` (a method returning `T.Item`), the interface `PickI` and the
    named constraint `PickC` (a parameter of type `T.Item`) and the interface
    `WithMethod` (a member function returning `T.Item`), and the splits
    `fail_todo_import_class_field_type`,
    `fail_todo_import_class_method_declaration`,
    `fail_todo_import_interface_declaration`,
    `fail_todo_import_constraint_declaration` and
    `fail_todo_import_interface_member_declaration` (amended 2026-10-15, focused
    re-review of the fold: RR1-M1 / RR2-M1). Round 2 adds to `lib.carbon` the
    class templates `Outer` and `OuterMethod` (a nested generic class with a
    field or a method of type `T.Item`), the functions `Constrained` (a deduced
    parameter constrained by `WithMethod(Holder)`), `TakesWithMethod` (a
    parameter of that facet type), `NeedsMarker`, `NamesFieldBox` and
    `BodyNamesFieldBox` (`FieldBox(T)` in a declaration and in a body), the
    interface `Marker` with `impl forall [V: WithMethod(Holder)] V as Marker`,
    and the class `K`, and the splits
    `fail_todo_import_nested_class_field_type`,
    `fail_todo_import_nested_class_method_declaration`,
    `fail_todo_import_function_constrained_by_template_interface`,
    `fail_todo_import_function_parameter_of_template_interface_type`,
    `fail_todo_import_impl_constrained_by_template_interface`,
    `fail_todo_import_function_declaration_names_class_template` and
    `fail_todo_import_function_definition_names_class_template` (amended
    2026-10-15, focused re-review of the fold: RR2r2-M1 / RR2r2-m1). Round 3
    adds to `lib.carbon` the interface `HasItem` with `impl Holder as HasItem`,
    the function templates `TakesItem` (a parameter of type `T.Item*`) and
    `NamesItem` (`T.Item;` in its body only), the checked generics
    `CallsTakesItem` and `CallsNamesItem` that call them, the interface
    `ItemDoer` with a blanket impl whose method calls `TakesItem`, the class
    `FieldBoxField` (fields of type `T` and `FieldBox(Holder)*`), the class
    `Pair` and the functions `TakesPair`, `TakesTuple` and `TakesStruct` (`FieldBox(Holder)`
    as a class argument and in a tuple and a struct), the interface `WithArg`
    and the functions `ConstrainedByWithArg` and `ConstrainedByRewrite` (`FieldBox(Holder)`
    as a constraint's argument and as a rewrite's value), and the class
    `MarkerArg` and the function `TakesMarkerArg` (a witness of the blanket impl
    as a class argument), and the splits
    `fail_todo_import_function_definition_calls_function_template`,
    `fail_todo_import_function_definition_calls_function_template_definition`,
    `fail_todo_import_impl_method_calls_function_template`,
    `fail_todo_import_class_field_names_class_template`,
    `fail_todo_import_function_declaration_names_class_template_in_class_argument`,
    `fail_todo_import_function_declaration_names_class_template_in_tuple`,
    `fail_todo_import_function_constrained_by_interface_of_class_template`,
    `fail_todo_import_function_declaration_names_impl_of_template_interface`,
    `fail_todo_import_function_declaration_names_class_template_in_struct`,
    `fail_todo_import_function_constrained_by_rewrite_to_class_template` and
    `fail_todo_import_two_uses_name_class_template` (amended 2026-10-15, focused
    re-review of the fold: RR3-1-M1 / RR3r2-M1).
-   check/testdata/generic/template/member_out_of_line.carbon (C2): the split
    `fail_todo_basic` renamed `fail_basic` (body unchanged).
-   check/testdata/generic/template/pointer.carbon (C3): `deref_param`,
    `arrow_member`, `addr_of_member`, `deref_pointer_param` (s14, eager,
    unchanged shape), `fail_deref_class_type_param` (`*c` for `c: C(T)`,
    rejected where written; added by C4, which forms `C(T)`, not C3),
    `fail_deref_non_pointer_on_instantiation`; the fold adds `deref_const_param`
    (`p: const T`), `fail_arrow_non_pointer_on_instantiation` and
    `fail_addr_of_value_on_instantiation` (the `->` and `&` diagnostics on
    instantiation) (amended 2026-10-14, implementation-review fold: IR2-MINOR-3
    / IR1-m3 / IR2-MINOR-8); the focused re-review of the fold adds
    `fail_deref_as_type_on_instantiation` (`let a: *p` for `p: type*`) and
    `fail_pointee_type_on_instantiation` (`MakeT(x)*`) (amended 2026-10-15,
    focused re-review of the fold: RR1-B1).
-   check/testdata/generic/template/index.carbon (C3): `tuple_index_param`,
    `array_index_param`, `class_member_array_index`,
    `index_class_with_index_with` (a `Vec(T)` with an `IndexWith` impl, whose
    SemIR must stay `compound_member_access_action` and `call_action`; added by
    C4, without which `Get(v, 0)` cannot deduce `T`),
    `fail_tuple_index_non_tuple_on_instantiation`,
    `fail_index_non_indexable_on_instantiation`; the fold adds
    `fail_tuple_index_const_param_on_instantiation` (`p.1` for `p: const T` is
    checked on instantiation, and `const (i32, i32)` is rejected there as it is
    without a template), `tuple_index_associated_type` (`e.0` for `e: T.Elem`),
    `fail_index_in_array_bound_on_instantiation` (D-TP-26) and
    `fail_redecl_differs_in_dependent_operation` (D-TP-23) (amended 2026-10-14,
    implementation-review fold: IR2-MINOR-3 / IR1-m3 / IR1-M1 / IR1-m2); the
    focused re-review of the fold adds D-TP-26's runtime-type splits
    `fail_tuple_index_as_type_on_instantiation`,
    `fail_index_as_type_on_instantiation`,
    `fail_tuple_type_element_on_instantiation`,
    `fail_struct_type_field_on_instantiation`,
    `fail_array_element_type_on_instantiation`,
    `fail_tuple_index_as_type_of_used_binding_on_instantiation`,
    `fail_tuple_index_as_conversion_target_on_instantiation`,
    `fail_tuple_index_as_return_type_on_instantiation` and
    `fail_tuple_index_as_var_type_on_instantiation`, and
    `template_value_as_type` (a template value parameter's `t.0`, `(t.1, i32)`
    and `s.p` as types), and extends
    `fail_redecl_differs_in_dependent_operation` with `class D(Q: i32*)`,
    `interface Container { let Elem: type; let Other: type; }` and the
    redeclarations H (`*p[0]`, `(*p)[0]`), K (`-v.0`, `-v.1`), L
    (`T.(Container.Elem)`, `T.(Container.Other)`), M (`&p.n`, `&p.m`) and N
    (`p->n`, `p->m`) (amended 2026-10-15, focused re-review of the fold: RR1-B1
    / RR1-m1 / RR2-m6). Round 2 adds
    `fail_array_type_two_runtime_operands_on_instantiation` (`var a:
    array(x.0, x.1);` for `x: (type, i32)`) and
    `fail_tuple_type_two_runtime_elements_on_instantiation` (`let p: (x.0,
    x.1)`), and extends the redeclaration split with `interface J` and R
    (`*p->q`, `*(*p).q`), S (`(**p).n`, `(*p)->n`) and U (`p->(J.G)()`,
    `(*p).(J.G)()`) (amended 2026-10-15, focused re-review of the fold:
    RR2-1-M1 / RR2-1-m1).
-   check/testdata/generic/template/unimplemented.carbon (C3): the two
    renamed splits of §1.9 and `fail_deref_dependent_member_non_pointer`.
-   check/testdata/generic/template/call.carbon (C3): the renamed split, the
    new `dependent_call_two_callees`, and the wrong-type split moved out.
-   check/testdata/generic/template/call_wrong_arg_type.carbon (C3, under
    min_prelude/convert.carbon): `fail_dependent_call_nonconst_arg_wrong_type`.
-   check/testdata/generic/template/deduce_class_args.carbon (C4): `holder`,
    `holder_copy_constraint`, `holder_pointer`, `vec_value_param`,
    `template_class_type`, `class_argument_expression`,
    `class_argument_return_type`; round 2 adds
    `class_template_literal_with_dependent_array_bound`,
    `class_template_return_with_dependent_array_bound`,
    `fail_class_template_literal_with_dependent_array_bound_count_on_instantiation`
    and `fail_class_template_literal_with_dependent_array_bound_unknown_field`,
    each over `class Arr(template N: i32)` with a field `array(i32, N)` (amended
    2026-10-15, focused re-review of the fold: RR2-1-M2).
-   check/testdata/generic/template/default_init.carbon (C4): `var_uninit`,
    `class_method_var_uninit`, `fail_var_uninit_tuple_on_instantiation`,
    `template_interface_concrete_self` (`return x;` only), and the fold's
    `template_interface_facet_value` and `template_interface_final_impl`,
    D-TP-12's interface-side pins and M17's killers (amended 2026-10-14,
    implementation-review fold: IR1-m1 / IR2-MAJOR-1).
-   check/testdata/generic/template/constraint_lookup.carbon (C5):
    `constraint_only`, `extend_impl_same_entity`, `type_only_member`,
    `field_not_in_constraint`, `round_widget_alias`, `square_widget_impl_alias`,
    `fail_different_entities` (X21), `fail_cowboy`,
    `fail_field_vs_constraint_method` (a09, M15's killer); the fold adds
    `fail_todo_field_of_template_class`, W-266's pin (amended 2026-10-14,
    implementation-review fold: IR1-M3).

New lower goldens (`toolchain/lower/testdata/template/`):
`initialize.carbon` (C1: `return_param_tuple`, whose IR stores both fields
into `%return` (PR-AK); `return_tuple`; `class_method_return_tuple` (X32);
`return_tuple_of_call` (b09b: `Pair` is called with the return slot's
element, M2's killer); `let_class_value_of_call` (the class temporary is
allocated in the specific and `Pair` initializes its field `a`; added
2026-10-14, review fold: RR-M1); `return_struct_convert` (e01);
`var_with_destructor` (the copy into `%y.var`, then its destruction);
`destructure_param`; and the fold's nine constant-element splits, which the
check golden also gains: `return_tuple_constant_element`,
`return_struct_constant_field`, `return_array_constant_element`,
`var_tuple_constant_element`, `assign_tuple_constant_element`,
`return_nested_constant_element`, `template_value_element`,
`return_class_constant_field` and `var_class_constant_field`, M21's
killers (amended 2026-10-14, implementation-review fold: IR1-B1)); and the
focused re-review's `return_tuple_of_associated_type` and
`var_tuple_of_associated_type`, a `(T.Elem, i32)` returned and in a `var`,
M27's killers (amended 2026-10-15, focused re-review of the fold: RR1-M2));
and round 2's `var_class_with_dependent_array_bound`,
`return_class_with_dependent_array_bound`,
`var_struct_of_class_with_dependent_array_bound`,
`var_tuple_of_class_with_dependent_array_bound`,
`var_array_of_class_with_dependent_array_bound` and
`let_class_value_with_template_value_field`, M36's and M40's killers (amended
2026-10-15, focused re-review of the fold: RR2-1-M2)),
`for_range.carbon` (C1: `range_param_called_array`, M9's killer),
`pointer_index.carbon` (C3) and `dependent_call.carbon` (C3).

### §2.8 Records texts (commit D; row in commit R)

Amended 2026-10-14 (review fold: B-M1 / B-M2 / B-B2 / B-m5 / RR-m3). Every
record text -- W-014's notes, the discharges of W-127, W-183, W-192 and
W-193, the seventeen residue items with kind, size, subsystem, evidence and
break condition, the decision-log entry with its veto digest and the
ORCHESTRATION stamp -- is in Appendix E.

**Row (commit R; rewritten 2026-10-14, review fold: RR-m3; W-183's clause, W-266
and the handle.cpp line (amended 2026-10-14, implementation-review fold: IR1-M3
/ IR2-MINOR-5)).** The "Generics: Integrated templates" row stays PARTIAL. In
the merge order PR 58 lands after PR 51 and its row supersedes PR 51's, so R
composes over PR 58's row (fcee90d9b, fork/gap-analysis.md:60). R deletes
nothing: DD-1's text, including its three dated parentheticals and its two fold
sentences, stays verbatim, because each records what was true when DD-1 wrote
it. R appends one dated TP-1 sentence that names which of DD-1's limits TP-1
resolves, what it adds and the residue. The full row R writes, with `YYYY-MM-DD`
the date of R:

<!-- google-doc-style-ignore -->

```text
| Generics: Integrated templates | PARTIAL | `template T: type` checks and simple dependent member access works by way of deferred actions. Template functions and classes are checked for each instantiation and lowered (toolchain/lower/handle.cpp:494-505 lowers SpliceInst within a file; across files is W-014), and DD-1's P04 runs conversions and operators on template-dependent values; generic/template/unimplemented.carbon still pins dereferencing a template-dependent value as fail_todo (DD-1, 2026-10-14, replacing the clause that dependent operators and conversions were fail_todo and that lowering hit CARBON_FATAL 'Template lowering not implemented yet', which no longer occurs under toolchain/). templates.md no longer self-describes as a placeholder (DD-1, 2026-10-14: a dated status note and the measured section "Templates in the 0.1 toolchain"). DD-1's third document-review fold (2026-10-14) lists more measured limits there, among them the operators `*`, `->` and `&`, tuple element access, calls and template-dependent tuples (W-014), a struct copy and an array index on instantiation (W-192) and deduction through a class's arguments (W-193), which it files under this bullet; status unchanged. DD-1's fourth document-review fold (6433978b5, 2026-10-14) adds a `for` loop whose range depends on a template parameter, which stops the compiler where the function is defined, and returning a value of a tuple, struct or array type built from a template parameter, which stops it when a call is instantiated (during checking) or, for a class template's method, while the call is lowered, all W-014's; status unchanged. (TP-1, YYYY-MM-DD, plan fork/templates/plan.md, keeping DD-1's text above as its record and resolving these of its limits: the fail_todo pin of dereferencing in unimplemented.carbon, which flips with every other generic/template fail_todo split; the operators `*`, `->` and `&`, tuple element access, calls of function-typed values and template-dependent tuples; the struct copy and array index (W-192, discharged); deduction through a class's arguments (W-193, discharged); the `for` loop that stopped the compiler where the function is defined; and the returns of tuples, structs and arrays, in a function and in a class template's method.) Template functions and classes are also checked for each instantiation in their dependent initializations, copies, destructuring and class, union and array values built from template calls, member lookup consults a constrained template parameter's constraint on instantiation for an operand whose type in the definition is the parameter (proposal 2200; W-183, discharged), and `var y: T;` resolves its default on instantiation (W-127, discharged); status unchanged. Residue: templates across libraries (W-250, a `semantics TODO` at the `import`, so lower/handle.cpp:524 stays), constraint lookup through a field whose declared type is the parameter (W-266), out-of-line redeclarations naming `T.U` (W-254), form-parameter pattern splices (W-255), a struct with one field or a tuple with one element holding an aggregate initialized in place, which stops the compiler or is compiled wrongly with or without templates (W-256), assignment checks on instantiation (W-259, generic/template/operator.carbon `todo_fail`), the definition-time half of constraint lookup and type-level `T.F` (W-260 to W-262), constant nested aggregates (W-263), a `for` loop whose cursor is a tuple or a class and a class value whose literal leaves a field to its default (W-264), field defaults in runtime class values with or without templates (W-265), `partial T*` (W-251), `match` on dependent values (W-252) and arrays with a dependent bound from a list (W-253). |
```

<!-- google-doc-style-resume -->

If the merged trunk's row is not PR 58's text above (a later merge edited it), R
keeps the merged text verbatim and appends the same TP-1 sentence and residue. A
limit the merged text no longer names is dropped from the "resolving" list. A
clause that a later workstream added and that TP-1 changes gets its own "(TP-1,
YYYY-MM-DD: ...)" marker after it, never a deletion. R's commit message quotes
the row it started from. The header count is unchanged. R re-cites every
file:line in the text it writes to the tree it is written on, as D does
(lower/handle.cpp:513 at b2576f6c3 is :524 at 4e1f07a91 and at the fold's head;
(amended 2026-10-14, implementation-review fold: IR2-MINOR-5)).

**Held state (amended 2026-10-14, implementation-review fold: IR2-MAJOR-2).**
While PR 51 to PR 59 are held (§1.12), trunk's row is the pre-DD-1 text at
fork/gap-analysis.md:54, and the ledger ends at W-125, so neither PR 58's row
nor W-127, W-183, W-192 and W-193 exist on the branch. R and D are then
written in two parts. Now, R keeps trunk's line-54 text verbatim and appends
one dated TP-1 sentence that presupposes no DD-1 text:

<!-- google-doc-style-ignore -->

```text
| Generics: Integrated templates | PARTIAL | `template T: type` checks and simple dependent member access works by way of deferred actions, but operators/conversions on dependent values are fail_todo, lowering hits CARBON_FATAL 'Template lowering not implemented yet' (lower/handle.cpp:363), and templates.md is a self-described skeletal placeholder. (TP-1, YYYY-MM-DD, plan fork/templates/plan.md, held until PR 51 to PR 59 land: template functions and classes are checked for each instantiation and lowered within a file, so the operators `*`, `->` and `&`, tuple element access, indexing, calls of function-typed values, conversions, copies, destructuring, `for` loops over a dependent range and returns of tuples, structs, arrays and classes built from template parameters compile and run, the generic/template fail_todo splits present when W-014 was filed flip, member lookup consults a constrained template parameter's constraint on instantiation, deduction sees through a class's arguments and `var y: T;` resolves its default on instantiation; status unchanged. Residue: templates across libraries (W-250, a `semantics TODO` at the `import`, so lower/handle.cpp:524 stays), constraint lookup through a field whose declared type is the parameter (W-266), out-of-line redeclarations naming `T.U` (W-254), form-parameter pattern splices (W-255), a struct with one field or a tuple with one element holding an aggregate initialized in place (W-256), assignment checks on instantiation (W-259), the definition-time half of constraint lookup and type-level `T.F` (W-260 to W-262), constant nested aggregates (W-263), in-place `for` cursors and defaulted class fields (W-264, W-265), `partial T*` (W-251), `match` on dependent values (W-252) and arrays with a dependent bound from a list (W-253).) |
```

<!-- google-doc-style-resume -->

At land time, after M is repeated over the trunk that holds the PRs, a
records commit recomposes the row: it starts from the merged trunk's row (PR
58's text, or a later merge's), applies the rule above (the full row of this
section when the merged row is PR 58's text), and replaces the held-state
sentence by the TP-1 sentence of that row, so the row carries one TP-1
sentence. D's held-state contents are Appendix E's "Held state" texts.

The focused re-review of the fold's records commit amends the held-state row
on the branch (amended 2026-10-15, focused re-review of the fold: all
findings): "PR 51 to PR 60" for "PR 51 to PR 59", since PR 60 (SC-1) lands
before TP-1; the container run of its head (1f0bc7be0's toolchain, scoreboard
generated 2026-10-19T15:28:25Z by the container clock, with the same counts);
W-250's residue names class templates' fields and member functions,
interfaces and named constraints; and the residue ends with W-267 to W-270.
The land-time recomposition carries the same residue. Its round 2's records
commit amends the row again (amended 2026-10-15, focused re-review of the
fold: all round-2 findings): the run of 24bf5ea45's toolchain (scoreboard
generated 2026-10-19T18:50:58Z by the container clock, with the same counts);
a class template's literal whose array field has a template-dependent bound
converted on instantiation; W-250's residue naming the entities that name such
a generic; and W-271 at the end of the residue.

### §2.9 Land-time integration with PR 58 (commit L)

Rewritten 2026-10-14 (review fold: B-B1 / B-M2 / B-M3 / A-M2). After M, with PR
58 on the branch, L applies the edits of Appendix C: seventeen anchored edits to
docs/design/templates.md (the Status paragraph, the two sketch notes in "Types
with template parameters", the W-193 note in "Functions with template
parameters", the 0.1 section's introduction, and every resolved or changed
limit, each with a unique, fixture-specific sentence), the R09 block changed to
run (its old result kept in a dated note), new bullets for the limits measured
after TP-1 (W-256, its compile-time crash and its miscompile; W-264 with W-265;
W-263, W-255, W-259, W-260 to W-262; amended 2026-10-14, review fold: RR-M1 /
RR-M2), the full new text of the nineteen rewritten fixtures (X13 to X21, X23 to
X25, X28 to X33, R09) and three new ones (X34 for W-256, X35 for W-264, X36 for
W-262), and their three entries in check_samples.py's `SAMPLES`. Every resolved
limit keeps its text and gains "(Resolved by TP-1, YYYY-MM-DD: ...)", the land
date replacing `YYYY-MM-DD`.

Measured, not predicted (rev 1's hand-off said the checker could not run
before PR 58 merges; a scratch copy of PR 58's tree runs it): the script
`$X/sim/l/apply_l.py` applies Appendix C to a copy of fcee90d9b's
`docs/design`, `fork/designdocs` and `fork/conformance/programs/project`
(`$X/sim/root`), and

<!-- google-doc-style-ignore -->

```sh
python3 -I fork/designdocs/check_samples.py
# check_samples: 19 program blocks, 70 fixtures, 3 W2 hits (2 allowlisted, 1 qualified); 0 errors
python3 -I fork/designdocs/check_samples.py --toolchain /dev/shm/tp1-fixer/v13/install/bin/carbon
# check_samples: 19 program blocks, 70 fixtures (compiled), 3 W2 hits (2 allowlisted, 1 qualified); 6 errors
```

<!-- google-doc-style-resume -->

The six `--toolchain` errors are exactly the fixtures that need C3's
actions (X13, X14, X15, X16, X19, X24: ``compile failed: <the old
error>``), which v13 does not have; every other fixture, including X21's
error line, X34's and X35's crash stages (`ResolveSpecificDefinition`,
`Lowering function Sum(Counter)`), X36's `2` and R09's `25`, passes. The
baseline of the same tree before the edits reports 0 errors (67 fixtures).
Rev 3 re-ran the simulation on its own texts (amended 2026-10-14, review
fold: RR-M1 / RR-M2): Appendix C extracted from the rev 3 plan with the
re-review's extractor, applied with `patch` to a `git archive` of fcee90d9b's
`docs` and `fork` in `$Y/sim/root`, the date set to 2026-10-20. The results
are the same: 67 fixtures and 0 errors before the edits, 70 fixtures and 0
errors after them without a toolchain, and with v14 the same six C3 errors
(`--toolchain /dev/shm/tp1-fixer2/v14/install/bin/carbon`). The miscompile
bullet of W-256 has no fixture, because its values change from run to run,
as PR-AK's did.
On the merged tree, L re-runs both commands with TP-1's toolchain and
records them in D; X21's quoted note is the hand-predicted
`TemplateMemberLookupAmbiguous` wording, and C5's fill decides it.

Not a fixture (partly rejected, with evidence, review fold B-B1 item 5):
the cross-library bullet's new text names the `semantics TODO`, but no
fixture can pin it, because `run_fixture` compiles one file alone
(check_samples.py:1100-1110, `compile ... --output-last-input-only
<fixture>`) and the form needs two libraries; the golden
generic/template/fail_todo_import.carbon pins it, and the page cites the
golden. L is reviewed by a document review (two reviewers, R29(c)) before R
and D, as PR 58's page needed four rounds; a fold of that review is a fix
commit of L and re-runs the checker.

**Measured with TP-1's toolchain (amended 2026-10-14, implementation: held
state).** L stays a land-time commit (§1.12), so its checker run is
simulated on copies, as above, with the install of the branch head
(`/home/user/carbon-build/carbon-tp/install/bin/carbon`, 0.0.0-0.dev+df6487a05,
whose sources equal M's). Each copy is a `git archive` of fcee90d9b's `docs`
and `fork` under `$I/sim-l` (`/home/user/carbon-dd` is not edited). Appendix
C, extracted from this plan, is byte-identical to `$Y/sim/ext4` and was
applied with `patch` (`root-c`); `$X/sim/l/apply_l.py <root> 2026-10-20`
was run on a second copy (`root-a`). The two differ only in page prose
that rev 3 rewrote after `apply_l.py` was written (the 0.1 section's
introduction, one dated note and three limit bullets); the fixtures and the
`SAMPLES` lines are identical, and the checker reports the same on both.

<!-- google-doc-style-ignore -->

```text
root-base (fcee90d9b, before the edits), without and with --toolchain:
check_samples: 19 program blocks, 67 fixtures, 3 W2 hits (2 allowlisted, 1 qualified); 0 errors
check_samples: 19 program blocks, 67 fixtures (compiled), 3 W2 hits (2 allowlisted, 1 qualified); 19 errors
root-c (Appendix C) and root-a (apply_l.py), the same two lines for both:
check_samples: 19 program blocks, 70 fixtures, 3 W2 hits (2 allowlisted, 1 qualified); 0 errors
check_samples: 19 program blocks, 70 fixtures (compiled), 3 W2 hits (2 allowlisted, 1 qualified); 0 errors
```

<!-- google-doc-style-resume -->

With the toolchain, the 19 errors before the edits are exactly the nineteen
fixtures that L rewrites (X13 to X21, X23 to X25, X28 to X33, R09): each now
compiles or runs where it pins an error or a crash. After the edits there is no
error, so the six C3 fixtures (X13, X14, X15, X16, X19, X24) pass, and so do
X21's `TemplateMemberLookupAmbiguous` quote, X34's and X35's crash stages, X36's
`2` and R09's `25`. On the merged tree, at land time, L re-runs both commands,
and D records them. At the implementation-review fold both roots were checked
again with and without the fold's install (0.0.0-0.dev+12bd6d67a, whose
toolchain sources equal f360b8735's): the same two lines for each, 0 errors, so
the fold's toolchain changes move no fixture (amended 2026-10-14,
implementation-review fold: IR1-B1 / IR1-M1 / IR1-M2 / IR1-m3).

## §3 Commits (one PR, "TP-1: integrated templates", R29(b))

**D-TP-22 (rewritten 2026-10-14, review fold: B-B2).** Five implementation
commits, each followed by its fill commit when it changes or adds goldens,
then the programs commit P, the merge of trunk M, which resolves conflicts
only, the SC-1 composition commit S and the fill F6 (amended 2026-10-14,
review fold: RR-m2), the two implementation reviews on the merged head, the
fix commits, the land-time
integration L with its document review, the row commit R, and the discharge
D last. Each implementation commit compiles alone, and its gate is judged on
the commit plus its fill: alone it is red exactly on the goldens it adds or
refills (§4; the refill attribution is measured, §0.8) and on nothing else,
with no crash. _Break condition:_ a commit cannot compile without a later
commit's files, which merges the two.

0.  **Plan.** Rev 1, "TP-1 plan (rev 1): integrated templates: crashes,
    dependent forms, splice lowering"; rev 2 folds the two reviews; rev 3
    folds the focused re-review of rev 2 and is signed off (amended
    2026-10-14, review fold: RR-M1).
1.  **C1** "TP-1 (1): template-dependent initializers keep their storage;
    lowering reads the specific" (A1 to A7, B1 to B5, the storage access
    copy and the value-temporary deferral of D-TP-24; the C1 goldens; red
    alone on convert.carbon, unimplemented.carbon, range_for.carbon and its
    new goldens; amended 2026-10-14, review fold: RR-M1). F1.
2.  **C2** "TP-1 (2): cross-library generics are diagnosed at the import;
    diagnostics print dependent operations" (import_ref.cpp, stringify.cpp;
    fail_todo_import.carbon and the member_out_of_line.carbon rename). F2.
3.  **C3** "TP-1 (3): dependent dereference, address-of, tuple element access,
    indexing and calls are checked on instantiation" (four action kinds,
    pointer_dereference.{h,cpp}, handle_operator.cpp, handle_name.cpp,
    member_access.{h,cpp}, handle_index.cpp, call.cpp's callee rule; goldens,
    the unimplemented.carbon and call.carbon flips, call_wrong_arg_type.carbon;
    index.carbon's `index_class_with_index_with` and pointer.carbon's
    `fail_deref_class_type_param` are C4's, measured; (amended 2026-10-14,
    implementation-review fold: IR2-MINOR-3)). F3.
4.  **C4** "TP-1 (4): class-argument deduction and deferred impl lookup for
    templates" (call.cpp `IsCallPerformable`, impl_lookup.cpp; goldens and the
    convert.carbon, destroy_calls.carbon and lower/template/class.carbon
    refills, and the two splits above, so C4 alone is red on index.carbon and
    pointer.carbon too; (amended 2026-10-14, implementation-review fold:
    IR2-MINOR-3)). F4.
5.  **C5** "TP-1 (5): member lookup into a constrained template parameter
    consults the constraint" (member_access.cpp, diagnostics/kind.def; the
    constraint_lookup golden). F5.
6.  **P** "TP-1 (6): conformance programs for integrated templates" (eight
    programs, one `.diff.cpp`, the regenerated README table, `--self-test`).
7.  **M** the merge of trunk, with PR 51, SC-1, PR 52 to PR 58 and PR 59 on it
    (§1.12), never a rebase. M resolves conflicts only (amended 2026-10-14,
    review fold: RR-m2): SC-1's `PerformAction` hunks keep both sides'
    statements in §0.9's order and add none, the README table is regenerated,
    and every record file is taken from trunk (TP-1 has not edited one yet; in
    the held state, D's records are written before the repeated M, which then
    keeps TP-1's appended blocks after the PRs' blocks in fork/gap-analysis.md,
    fork/inventory/work-items.json, fork/decision-log.md and
    fork/ORCHESTRATION.md, (amended 2026-10-14, implementation-review fold:
    IR2-MAJOR-2)). M adds no logic that neither side has, so `git log -p` of the
    commits around it attributes every rule. The dry run of §0.9 is repeated
    first against the heads of that day, and its result is recorded in D. M
    alone builds; its gate is red on SC-1's nine template-constraint goldens,
    which S restores (measured as scv13), and on what F6 refills.
8.  **S** "TP-1 (7): over SC-1, a template constraint's requirement defers to
    the type in constraint lookup" (member_access.cpp only, §2.5: C5's
    lookup returns `None` for a member that SC-1's
    `GetStructuralRequirementRef` reports, which cannot exist before M).
    With S, SC-1's nine goldens pass again (measured as scv13b); mutant M18
    reverts S. **F6** then refills what the merge changes: TP-1's seven
    refills recomputed on the merged tree, PR 51's
    `fail_todo_unformed_dependent_var` renamed `unformed_dependent_var` and
    refilled, and any SC-1 or VA-1 golden the merged toolchain changes
    (measured: none on either composition). M, S and F6 are judged together,
    as an implementation commit and its fill are.
9.  **Implementation reviews** A and B (R29(c)) on the merged head, not a
    commit; they see C5 over SC-1 and A2 beside SC-1's structural checks.
10. **Fix commits** (at most three, below), each with its fill. At the
    implementation-review fold: 7c7b1b170 (D-TP-25) with its fill 17501c978,
    12bd6d67a (D-TP-26, D-TP-14's declarations, D-TP-23's action kinds, the
    opaque types of §1.3) with its fill f360b8735, and the records commit
    that folds the rest into this plan; the shrink line was not used
    (amended 2026-10-14, implementation-review fold: IR2-MINOR-10). At the
    focused re-review of the fold: 632f92117 (D-TP-26 for every type
    position, D-TP-6's tuple element) with its fill d069d639d, d8f6ab60a
    (D-TP-14's class, interface and constraint tests) with its fill
    22b9074bd, 73b3124dd (D-TP-23's precedence and interface members) with
    its fill 831289fad, 67a9dd91c (clang-format only), ba64734e7 (D-TP-26's
    error value in the specific and its readers) with its fill 1f0bc7be0, and
    the records commit that adds the
    [focused re-review fold record](#focused-re-review-of-the-fold-2026-10-15);
    beyond the budget, by the dated note below (amended 2026-10-15, focused
    re-review of the fold: all findings). At its round 2: 2165322c5 (D-TP-26
    for every runtime operand) with its fill e6a663c22, 123eb40ca (D-TP-23's
    `->`) with its fill 8af8ad78b, b678e2985 (D-TP-24's class initializers and
    `NeedsSpecificInst`) with its fill 7ea3fed97, 94227d82c (D-TP-14's walk)
    with its fill 4fcbf62ef, 282930a73 (the walk and the literal test made
    iterative for clang-tidy, no golden change), f44280c1c (an aggregate
    converts a class template's literal as its element) with its fill
    24bf5ea45, and the records commit that
    records the round, by the second dated note (amended 2026-10-15, focused
    re-review of the fold: all round-2 findings). At its round 3: 68102438e
    (D-TP-14's walk follows each reference the import loads, and
    `TryFinishSpecific` tests the generic's definition) with its fill
    d0fbfd56b, d54c37f91 (the walk's per-file record, no golden change),
    ada45a7c6 (three more splits, no toolchain change) with its fill
    e7dc20a43, and the records commit that records the round, by the third
    dated note (amended 2026-10-15, focused re-review of the fold: all
    round-3 findings).
11. **L** "TP-1: integration with PR 58" (§2.9, Appendix C), then its
    document review and fold commits; `check_samples.py` with and without
    `--toolchain` on every one of them. The id re-scan of the front matter
    runs before L, the first commit that publishes an id (amended
    2026-10-14, review fold: RR-m4).
12. **R** "TP-1: row" (§2.8's full row text, composed over PR 58's row; header
    unchanged; in the held state, §2.8's held-state row over trunk's, recomposed
    at land time, (amended 2026-10-14, implementation-review fold:
    IR2-MAJOR-2)).
13. **D** "TP-1 discharge", last: the ledger (W-014's notes; W-127, W-183,
    W-192 and W-193 discharged; W-250 to W-266 filed), the decision-log
    entry, ORCHESTRATION, the plan's landed notes with the measured gate,
    conformance and checker runs of the merged tree, and the outcomes of both
    id re-scans, the one before L and the one run immediately before D. In
    the held state D writes Appendix E's held-state texts: W-014's notes with
    the state-T measurements, W-250 to W-266 appended after W-125, the
    decision-log entry, a TP-1 Branches row and the Next actions of the land
    time; the discharges of W-127, W-183, W-192 and W-193 move to a land-time
    records commit after the repeated M, when the four items exist
    (amended 2026-10-14, implementation-review fold: IR2-MAJOR-2).

**Held state (amended 2026-10-14, implementation: held state).** While PR 51 to
PR 59 are held (§1.12), items 7, 8 and 11 run in two parts. Now: M is the merge
of trunk 8bfd78ae3 (6efc3f257, "TP-1 (M): merge of trunk 8bfd78ae3 (held state:
records only)"), records only; S, F6 and L are measured on composed copies and
not committed (§0.9 "Composition at state T", §2.9 "Measured with TP-1's
toolchain"); the implementation reviews (item 9) review the branch head and
those measurements, and their fix commits (item 10), R and D follow as above. D
records every land-time item (M with the PRs, S, F6, L with its document review,
and the id re-scan before L) in the plan's landed notes and in ORCHESTRATION's
Next actions. The held-state commits are M (6efc3f257), the measurement record
4e1f07a91, the fold's fix commits 7c7b1b170 and 12bd6d67a with their fills
17501c978 and f360b8735, and its records commit ((amended 2026-10-14,
implementation-review fold: IR2-MINOR-10)). At land time, M is repeated as a
merge of the trunk that holds the PRs, and S, F6 and L are committed with the
texts above, each with the build, gate and checker runs of §8.

**Fix commits and the shrink line.** TP-1 is about VA-1's size in toolchain
code: the measured v14 patch is 14 files and about 620 changed lines with
comments (amended 2026-10-14, review fold: RR-M1); C3 adds four action kinds
(about 250 lines, Appendix D) and C5 a diagnostic kind; VA-1 needed three fix
commits, OV-1 four. Budget: three fix commits after the merged build and the
implementation reviews, each its own commit with its own fill, never an amend.
Shrink line, in order, for a build that cannot be made to work in that budget:
first C5 (W-183) leaves the PR and W-183 stays open with the v13 prototype
recorded in its notes; then C3's `TupleIndexAction` and `IndexAction` (X16, X19,
X24 keep today's errors; W-192 stays open with X18's struct copy recorded as
fixed, and no new id is filed for the same gap; amended 2026-10-14, review fold:
B-m5); C1 and C2 are never shrunk (R17: they remove crashes). Each shrink is a
plan revision the reviews see before it lands, and the row text and Appendix C
lose the clauses it covered.

**Budget note (amended 2026-10-15, focused re-review of the fold: RR1-B1 /
RR1-M1 / RR1-M2 / RR1-m1 / RR2-m6).** The implementation-review fold spent the
three fix commits. The focused re-review of the fold adds four toolchain fix
commits, each with its fill, a formatting commit and a records commit. Root
cause: its findings are four separate defects that the fold's fixes left
reachable, not a wider slice. RR1-B1 and RR1-M2 are D-TP-26's and D-TP-6's
rules, which the fold applied to an array bound only, applied to every type
position (632f92117, completed by ba64734e7 after the fixer's own probes of
632f92117 found that a diagnosed type's other uses, a return type and an `as`
target still read the runtime value as a type); RR1-M1 and RR2-M1 are one
finding, D-TP-14's test applied before a class's, interface's or constraint's
data is loaded (d8f6ab60a); and RR1-m1 with RR2-m6 is D-TP-23's printing
(73b3124dd). Each removes a crash or a wrong diagnostic where it arises (R17);
the formatting commit 67a9dd91c only rewraps d8f6ab60a's lines; nothing is
shrunk.

**Budget note, round 2 (amended 2026-10-15, focused re-review of the fold:
RR2-1-M1 / RR2-1-M2 / RR2-1-m1 / RR2r2-M1).** Round 2 adds four toolchain fix
commits, each with its fill, a commit that rewrites two of their tests as
worklists, a fifth fix commit with its fill that removes a test the four made
redundant, and a records commit. Root cause: four separate defects that round
1's fixes left reachable, not a wider slice. D-TP-26 made only an
instruction's first runtime operand an error, so a second one kept no value
in the specific (2165322c5); D-TP-23 printed `->` as `(*p).` (123eb40ca); C4's
class types formed in the definition left a class template's literal to be
converted there, where trunk deferred it, and the deferral exposed a
pre-existing crash of a deferred runtime literal with a template value
element (b678e2985); and D-TP-14's test stopped at the entity it was given,
not what its loaded data names (94227d82c). Each removes a crash or a wrong
diagnostic, or restores a program trunk compiles, where it arises (R17);
282930a73 changes no behavior: clang-tidy's misc-no-recursion, an error in
this configuration, rejected the recursive forms of two of the new tests; and
f44280c1c changes only value names: it removes b678e2985's aggregate-level
deferral, which the same commit's fix of `NeedsSpecificInst` made redundant;
nothing is shrunk.

**Budget note, round 3 (amended 2026-10-15, focused re-review of the fold:
RR3-1-M1 / RR3r2-M1).** Round 3 adds a toolchain fix commit with its fill, a
commit that records each walk's result for the file, a commit of three more
splits with its fill, and a records commit. Root cause: one defect that round
2's fix left reachable, not a wider slice. D-TP-14's walk tested only the kind
of each entry it reached, not the operands the import loads with it, and
`TryFinishSpecific` imported the definition of a specific whose generic's
definition `TryFinishGeneric` had not imported (68102438e). Each change removes
a crash where it arises (R17); d54c37f91 changes no behavior: the wider walk
raised the gate's time across threads by a quarter, and the record brings it
below round 2's; ada45a7c6 changes no toolchain file: it pins the shapes that
three of the round's mutants change; nothing is shrunk.

## §4 Testdata matrix (autoupdate fills; the fill must reproduce these lines)

Amended 2026-10-14 (review fold: A-B1 / A-M1 / A-M4 / B-M5 / A-m2 / A-m4 /
A-m8 / B-m4 / RR-M1). Key lines by name; numbers are placeholders the fill
writes. "Measured" lines were produced by v13's autoupdate (§0.8), or by
v14's where they say so; v14 reproduces every v13 line.

| Golden | Split | Key line |
| --- | --- | --- |
| generic/template/initialize.carbon | return_tuple | measured: `initialize_action %x.ref..., %T..., constants.%inst.splice_block..., true [template]` for each element, the storage a copied `splice_block %tuple.elem0` in the constants, no `convert_to_category_action` |
| same | return_param_tuple | measured: `initialize_action %p.ref, %T..., %return.param, false [template]` (the return slot is a root in the body, so nothing is copied) |
| same | return_tuple_of_call | measured: no STDERR; the specific's copy of `tuple_access %return.param, element0` is the `Pair` call's storage |
| same | copy_struct, return_struct_convert, var_with_destructor, return_nested_literal, var_tuple_of_call | measured: no STDERR |
| same | destructure_param | measured: `convert_to_value_action` (not `convert_to_category_action ..., element1`) for the bindings |
| same | let_class_value_of_call, let_array_value_of_calls | measured on v14: no STDERR; the whole conversion is one `convert_to_value_action %..., constants.%C [template]` in the definition, and in the specific the `Pair` call's storage is a `splice_block` that holds the class's `temporary_storage` (added 2026-10-14, review fold: RR-M1) |
| same | fail_class_value_unexpected_field | measured on v14: ``error: struct `C` has no field named `c` `` where `G` is defined, with no call of `G` |
| generic/template/for_range.carbon | range_param | measured: no STDERR; `require_complete_type %ptr` in the definition |
| lower/testdata/template/initialize.carbon | return_param_tuple | measured: the `Id((i32, i32))` specific stores both fields into `%return` (no `alloca` that is never read) |
| same | return_tuple_of_call | measured: `call void @_CPair...(ptr %tuple.elem0...tuple.elem, i32 %x)` into the return slot |
| same | var_with_destructor | measured: `%y.var = alloca`, the `Copy` call into `%y.var`, then the destroy call on `%y.var` |
| same | let_class_value_of_call | measured on v14: in `G(i32)`, one `alloca` of the class, the `Pair` call into its field `a`'s `getelementptr`, then the store of 1 into `b` |
| generic/template/fail_todo_import.carbon | fail_todo_import_function, fail_todo_import_class | measured: ``error: semantics TODO: `using a generic from another library whose definition is resolved for each instantiation, such as a template` `` at the `import` line, nothing else; import_unused: no STDERR |
| generic/template/member_out_of_line.carbon | fail_basic (renamed) | measured: ``type `<pattern for T.U>` of parameter 1 in redeclaration differs from previous parameter type `<pattern for T>` `` and ``return type is `T.U` `` |
| generic/template/call_wrong_arg_type.carbon | fail_dependent_call_nonconst_arg_wrong_type | measured: note ``cannot implicitly convert expression of type `X` to `Y` `` |
| generic/template/pointer.carbon | fail_deref_non_pointer_on_instantiation | predicted: ``error: unable to monomorphize specific`` with note ``cannot dereference operand of non-pointer type `i32` `` |
| same | fail_deref_class_type_param | predicted: ``cannot dereference operand of non-pointer type `C(T)` `` where it is written |
| generic/template/index.carbon | fail_tuple_index_non_tuple_on_instantiation | predicted: note ``type `i32` does not support tuple indexing`` |
| same | index_class_with_index_with | predicted: `compound_member_access_action` and `call_action`, as on trunk |
| generic/template/unimplemented.carbon | deref_dependent_member (renamed) | predicted: `pointer_dereference_action ..., false [template]`, no STDERR |
| generic/template/call.carbon | dependent_call_nonconst_arg (renamed) | measured: no STDERR |
| generic/template/deduce_class_args.carbon | holder | measured: no STDERR; `class_type @Holder, @Holder(%T) [template]` in the parameter's type |
| generic/template/constraint_lookup.carbon | fail_different_entities, fail_cowboy, fail_field_vs_constraint_method | ``unable to monomorphize specific `...` `` (measured) with note ``member name `F` names different entities in type `C` and in its constraint `A` `` (predicted wording; v13 emits a `semantics TODO` there) |
| generic/template/default_init.carbon | fail_var_uninit_tuple_on_instantiation | measured: note ``cannot access member of interface `Core.DefaultOrUnformed` in type `(i32, i32)` `` |
| same | template_interface_concrete_self | measured: no STDERR |
| generic/template/convert.carbon | refill | measured: `convert_to_value_action` in place of `convert_to_category_action ..., element1`; `class_type @A, @A(%T) [template]` in place of `call_action (%A.generic, %T)` |
| interop/cpp/range_for.carbon | refill | measured: `require_complete_type %ptr...` lines (34) |

Rows added by the implementation-review fold ((amended 2026-10-14,
implementation-review fold: IR1-B1 / IR1-M1 / IR1-M2 / IR1-M3 / IR1-m1 / IR1-m2
/ IR1-m3 / IR2-MAJOR-1 / IR2-MINOR-8); every line measured by the fold's
autoupdate):

| Golden | Split | Key line |
| --- | --- | --- |
| generic/template/initialize.carbon | return_tuple_constant_element | no STDERR; in `M(i32)` element 1's splice is a `splice_block` with the constant value `int_1` that holds `tuple_access @M.%return.param, element1` |
| same | the other eight constant-element splits | no STDERR |
| lower/testdata/template/initialize.carbon | return_tuple_constant_element | `store i32 %x` into element 0 and `store i32 1` into element 1 of `%return` |
| same | assign_tuple_constant_element | `%t.var` stores `%x` and `%y`, then `%x` and `1` |
| lower/testdata/template/merging.carbon | refill | `alloca {}` and `llvm.lifetime.start` for the `{}` temporaries, as the non-template twin |
| generic/template/default_init.carbon | template_interface_facet_value | no STDERR |
| same | template_interface_final_impl | `lookup_impl_witness %i32, @Tag, @Tag(%U) [template]` in the definition; `impl_witness ..., @i32.as.Tag.impl(bool)` in `Get(bool)` |
| generic/template/pointer.carbon | deref_const_param | no STDERR |
| same | fail_arrow_non_pointer_on_instantiation | ``unable to monomorphize specific `Next(Node)` `` with note ``cannot apply `->` operator to non-pointer type `Node` [ArrowOperatorOfNonPointer]`` |
| same | fail_addr_of_value_on_instantiation | ``unable to monomorphize specific `Read(Counter)` `` with note ``cannot take the address of non-reference expression [AddrOfNonRef]`` |
| generic/template/index.carbon | fail_tuple_index_const_param_on_instantiation | ``unable to monomorphize specific `Second((i32, i32))` `` with note ``type `const (i32, i32)` does not support tuple indexing`` |
| same | tuple_index_associated_type | no STDERR; `e.0` is a `tuple_index_action` |
| same | fail_index_in_array_bound_on_instantiation | ``unable to monomorphize specific `Make(array(i32, 1), (1,))` `` twice, with the notes ``non-constant call to compile-time-only function`` and ``expression is runtime; expected constant [EvalRequiresConstantValue]`` |
| same | fail_redecl_differs_in_dependent_operation | ``return type is `array(i32, v.1)` `` against `` `array(i32, v.0)` ``, and `` `C(p[0])` `` against `` `C(*p)` `` |
| generic/template/fail_todo_import.carbon | fail_todo_import_function_declaration, fail_todo_import_class_declaration | the `semantics TODO` at the `import` line, nothing else |
| generic/template/constraint_lookup.carbon | fail_todo_field_of_template_class | ``unable to monomorphize specific `Go(C as A)` `` with note ``member name `F` not found in `C` `` |

Rows added by the focused re-review of the fold ((amended 2026-10-15, focused
re-review of the fold: RR1-B1 / RR1-M1 / RR1-M2 / RR1-m1 / RR2-M1 / RR2-m6);
every line measured by the re-review fixer's autoupdate):

| Golden | Split | Key line |
| --- | --- | --- |
| generic/template/index.carbon | fail_tuple_index_as_type_on_instantiation, fail_index_as_type_on_instantiation, fail_tuple_type_element_on_instantiation, fail_struct_type_field_on_instantiation, fail_array_element_type_on_instantiation, fail_tuple_index_as_type_of_used_binding_on_instantiation, fail_tuple_index_as_conversion_target_on_instantiation, fail_tuple_index_as_return_type_on_instantiation | ``unable to monomorphize specific `F(...)` `` with one note, ``expression is runtime; expected constant [EvalRequiresConstantValue]``, at the runtime operand (`x.0`, `x[0]` or `MakeT(x)`) |
| same | fail_tuple_index_as_var_type_on_instantiation | the same note on instantiation, and where `F` is defined ``cannot convert type `x.0` into type implementing `Core.DefaultOrUnformed` `` (W-268's lookup) |
| same | template_value_as_type | no STDERR |
| same | fail_redecl_differs_in_dependent_operation (extended) | ``return type is `C((*p)[0])` `` against `` `C(*p[0])` ``, `` `C(v.1.(Core.Negate.Op)())` `` against `` `C(v.0.(Core.Negate.Op)())` ``, `` `T.(Container.Other)` `` against `` `T.(Container.Elem)` ``, `` `D(&p.m)` `` against `` `D(&p.n)` ``, and `` `C((*p).m)` `` against `` `C((*p).n)` `` |
| generic/template/pointer.carbon | fail_deref_as_type_on_instantiation, fail_pointee_type_on_instantiation | ``unable to monomorphize specific`` with the note ``expression is runtime; expected constant`` at `*p` or `MakeT(x)` |
| lower/testdata/template/initialize.carbon | return_tuple_of_associated_type, var_tuple_of_associated_type | the function bodies equal their non-template twins' (`$F/p/twin`) apart from the mangled names |
| generic/template/fail_todo_import.carbon | fail_todo_import_class_field_type, fail_todo_import_class_method_declaration, fail_todo_import_interface_declaration, fail_todo_import_constraint_declaration, fail_todo_import_interface_member_declaration | the `semantics TODO` at the `import` line, nothing else |

Rows added by round 2 of the focused re-review of the fold ((amended
2026-10-15, focused re-review of the fold: RR2-1-M1 / RR2-1-M2 / RR2-1-m1 /
RR2r2-M1 / RR2r2-m1); every line measured by the round's autoupdate):

| Golden | Split | Key line |
| --- | --- | --- |
| generic/template/index.carbon | fail_array_type_two_runtime_operands_on_instantiation | where `F` is defined, ``cannot convert type `array(x.0, x.1)` into type implementing `Core.DefaultOrUnformed` `` (W-268's lookup); on instantiation, ``unable to monomorphize specific `F((type, i32))` `` twice, with the notes ``non-constant call to compile-time-only function`` and ``expression is runtime; expected constant`` at `x.1`; no crash |
| same | fail_tuple_type_two_runtime_elements_on_instantiation | ``unable to monomorphize specific `F((type, type))` `` once, with one note ``expression is runtime; expected constant`` at `(x.0, x.1)` |
| same | fail_redecl_differs_in_dependent_operation (extended) | N: ``return type is `C(p->m)` `` against `` `C(p->n)` ``; R: `` `C(*(*p).q)` `` against `` `C(*p->q)` ``; S: `` `C((*p)->n)` `` against `` `C((**p).n)` ``; U: `` `C((*p).(J.G)())` `` against `` `C(p->(J.G)())` `` |
| generic/template/deduce_class_args.carbon | class_template_literal_with_dependent_array_bound, class_template_return_with_dependent_array_bound | no STDERR |
| same | fail_class_template_literal_with_dependent_array_bound_count_on_instantiation | ``unable to monomorphize specific `Make(3)` `` with the note ``cannot initialize array of 3 elements from tuple with 2 elements`` |
| same | fail_class_template_literal_with_dependent_array_bound_unknown_field | ``struct `Arr(N)` has no field named `m` `` where `Make` is defined |
| lower/testdata/template/initialize.carbon | var_class_with_dependent_array_bound | in `M(3)`, `store i32 %x`, `store i32 2` and `store i32 3` into the array field of `%c.var` and `store i32 3` into its `n` |
| same | return_class_with_dependent_array_bound, var_struct_of_class_with_dependent_array_bound, var_tuple_of_class_with_dependent_array_bound, var_array_of_class_with_dependent_array_bound | each element initialized in place, as the non-template twin's |
| same | let_class_value_with_template_value_field | in `M(3)`, `store i32 %x` into the temporary's `a` and `store i32 3` into its `b` |
| generic/template/fail_todo_import.carbon | the seven round-2 splits | the `semantics TODO` at the `import` line, once; the impl split also ``cannot convert type `K` into type implementing `Marker` `` |
| generic/template/fail_todo_import.carbon | the eleven round-3 splits | the `semantics TODO` at the `import` line, once, and nothing else; `fail_todo_import_two_uses_name_class_template` twice, for `FieldBox` and for `TakesTuple` |

Refills by name: generic/template/convert.carbon, unimplemented.carbon,
call.carbon, member_out_of_line.carbon, class/destroy_calls.carbon,
interop/cpp/range_for.carbon, lower/testdata/template/class.carbon, and the
fold's lower/testdata/template/merging.carbon; in F6
PR 51's dependent_var_full_prelude.carbon. facet/period_self.carbon and
interop/cpp/template/generic_call.carbon must not change (D-TP-12's pins).

## §5 Conformance delta (from the floor of record, 128 PASS / 0 FAIL / 22 SKIP over 150)

Measured on v13: 128/0/22 over 150, 48 of 56 bullets PASS, no program changes
status; v14 measures the same (amended 2026-10-14, review fold: RR-M1). TP-1
adds eight programs, all PASS on TP-1's toolchain (six measured on v13, the two
C3 programs predicted from their concrete baselines): 136/0/22 over 158 on trunk
plus TP-1 alone, the bullet already PASS. Against the merge order, the floor at
TP-1's landing is PR 59's expected state plus every earlier PR (PR 59's own
record: 137/0/21 over 158 against its base), so the expected landing count is
that floor plus eight PASS; D records the measured numbers of the merged tree.
The implementation-review fold adds a ninth program, templates_constant_elements
(D-TP-25): 137/0/22 over 159 at the fold's head, 48 of 56 bullets PASS, and the
landing count is the floor plus nine PASS (amended 2026-10-14,
implementation-review fold: IR1-B1). No program moves from SKIP to PASS because
of TP-1 (PR 51 already un-SKIPs templates_dependent_member).

## §6 Churn and collisions

Golden churn: §4's refills (seven files on trunk) plus the new goldens.
Collisions: §0.9. The one textual conflict with SC-1 (convert.cpp
`PerformAction(ConvertAction)`) composes as stated there, and C5's composition
rule is the commit S right after M (amended 2026-10-14, review fold: RR-m2).
A7's hunks (D-TP-24) apply to SC-1's, VA-1's and OP-2's convert.cpp with offsets
only (amended 2026-10-14, review fold: RR-M1). C3's and C5's X-macro additions
are alphabetical inserts on lines that SC-1's and VA-1's do not touch (amended
2026-10-14, review fold: B-m2). PR 58's integration is confined to commit L.

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

1.  The four actions of C3 were not relinked. _Falsifier:_ C3's build plus F3
    show a golden other than unimplemented.carbon and call.carbon changing
    outside the new files, or a non-template program changing. Mitigation:
    the creation conditions are a subset of the cases trunk rejects (§1.3).
2.  D-TP-12 changes impl selection for queries that name a template binding
    (amended 2026-10-14, review fold: A-M4 / B-M5). _Falsifier:_
    facet/period_self.carbon or interop/cpp/template/generic_call.carbon
    changes (a checked generic's `eval fn` or C++ template result was
    deferred), or a template program changes output. Measured on v12: neither
    golden changes, no program changes.
3.  D-TP-11 forms dependent class types eagerly; a generic class whose
    definition depends on a template argument's value is completed in the
    definition. _Falsifier:_ an instantiation diagnostic moves to the
    definition in a golden (measured: none).
4.  SC-1's member_access.cpp moves again before TP-1 lands. _Falsifier:_ the
    §0.9 dry run, repeated at M, fails more hunks than one, or the scv13b
    composition's gate differs; response: the composition is redone in S
    and F6, and the reviews see it.
5.  A template-dependent `&` of a value now waits for instantiation, where
    its `AddrOfNonRef` becomes a note. This is TR-3's behavior, not a risk to
    correctness.
6.  D-TP-3's copy places the access instructions per specific, but a pending
    root still precedes the initializer only if the initializer has no
    temporary in the specific (added 2026-10-14, review fold: A-B1). D-TP-24
    removes the three value temporaries; the `for` cursor and a class value
    with a defaulted field remain (amended 2026-10-14, review fold: RR-M1).
    _Falsifier:_ a form other than those two crashes with RC-5's CHECK or the
    verifier on TP-1's toolchain; response: the form joins W-264's evidence,
    or the plan's next revision allocates the root earlier.
7.  D-TP-24 defers a template-dependent class, union or array value whole, so
    an error in an element's conversion is reported on instantiation, as for
    any dependent value (added 2026-10-14, review fold: RR-M1). _Falsifier:_
    a definition-time error that does not depend on the template argument
    moves to instantiation in a golden (measured: none; the field names, the
    union's designated field and the array's length are still checked where
    the function is defined, t13, t13b, t18, t19).

### §7.2 Rejected alternatives

1.  **Turn every crash into a `semantics TODO`.** Rejected: a Goodhart
    alternative (R16, R17). It would make the fixtures and the gate green
    while the forms that proposal 2200 makes valid still fail; the root
    causes (§0.3) are a copied storage chain and five category reads, cheaper
    than the guards. Only the cross-library form gets a TODO (D-TP-14), and
    the form-parameter guard is dropped (D-TP-15, A-M3).
2.  **Cherry-pick upstream 947c1eb52 to make X31 run.** Rejected: a 131-file
    language change (array as a class) that leaves X29 and X30 crashing.
3.  **Cherry-pick upstream 4a8993af2 as C0** (amended 2026-10-14, review
    fold: A-B1 / RR-m1). Rejected by measurement: it moves the shared storage
    access block, which the template body still uses, into the action, so
    nested literals fail the verifier (review A's v11, which includes the
    one-line guard that removes the `pending_block.h:89` CHECK rev 1's v10
    hit on the `for` cursor's cleanup; that CHECK is not a reason). Its
    representation is kept for D-TP-3's copy.
4.  **Insert the storage access block where the action is created (rev 1's
    A4).** Rejected by measurement (added 2026-10-14, review fold: A-B1): the
    storage then follows an earlier in-place initializer whose temporary the
    action rewrites (b09, b09b, c1, c3, c4 crash on v8 and on mutant M2).
5.  **Defer every form through `HandleAction` (defer when any operand is
    template dependent).** Rejected: it changes the SemIR of every template
    that dereferences a `T*` or indexes an `array(T, N)` or a `Vec(T)`, which
    work today, and moves definition-time errors to instantiation (TR-2)
    (§1.3).
6.  **W-183 at the definition only (look the name up in the constraint when
    the template is defined, and use it).** Rejected: proposal 2200 looks in
    both and requires agreement (:440-441, :476-503); the constraint-only
    result would silently call `I.F` where the type's own `F` differs. The
    definition half on top of the instantiation comparison is the right
    design and is filed (W-260, W-261).
7.  **W-127 by accepting the deferred witness only (v6).** Rejected by
    measurement: a final impl is selected in the definition with an unproven
    requirement.
8.  **W-127 by deferring every template-dependent query (rev 1's v7).**
    Rejected by measurement (added 2026-10-14, review fold: A-M4 / B-M5):
    `TemplateInst` and `eval fn` results are template dependent in checked
    generics, and two checked-generic goldens changed, one to a misleading
    diagnostic.
9.  **Fix W-254 here by making action constants structurally canonical.**
    Rejected for this slice: redeclaration matching of dependent types
    touches merge.cpp's comparison, which SC-1 rewrites (+137 on SC-1).
10. **Diagnose template form parameters (rev 1's D-TP-15).** Rejected
    (added 2026-10-14, review fold: A-M3): the crash is the same for
    `generic` (§0.3 RC-9).
11. **Diagnose RC-10's shape (a by-copy aggregate with an in-place element)
    instead of compiling q07c wrongly.** Rejected by measurement (added
    2026-10-14, review fold: RR-M2): variant g's `semantics TODO` also
    rejects k01 and k07, which run today, and changes
    tuple/class_tuples.carbon's diagnostic, without fixing the same
    miscompile in code without templates (§0.3 RC-10). The fix belongs to
    RC-10 (W-256).
12. **Defer every template-dependent class value, whatever its field names
    (rev 3's first v14 draft).** Rejected by measurement (added 2026-10-14,
    review fold: RR-M1): an unexpected field (t13) was then reported only on
    instantiation, and not at all in a template that is never called (t13b
    compiles on m20). D-TP-24 defers only a source with exactly the class's
    fields.
13. **Allocate every pending root before its initializer (the TODO of
    handle_loop_statement.cpp:216-218) in this slice.** Not taken (added
    2026-10-14, review fold: RR-M1): for the three value temporaries,
    deferring the conversion is local to convert.cpp and measured; for the
    `for` cursor, it reorders the loop header's checking, which no prototype
    has measured, and it is filed (W-264).

## §8 Verification and discharge

Amended 2026-10-14 (review fold: B-m6 / A-m1 / B-M4 / A-M1). The scripts are the
container arbiter's, in
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild/`
(`CB` below; README.md there).

1.  **Build** (implementer): `$CB/build.sh /home/user/carbon-tp` and
    `$CB/install.sh /home/user/carbon-tp`, after each implementation commit
    and after M; `-Werror` clean.
2.  **Autoupdate to its fixpoint** (R26): `$CB/autoupdate.sh
    /home/user/carbon-tp <files>` on the commit's new and refilled goldens, a
    second pass loc-number-only, then the gate.
3.  **Gate**: `$CB/gate.sh /home/user/carbon-tp`: the commit alone red
    exactly on §4's files for it (§0.8's attribution); with its fill, every
    file passes (trunk 1942 plus the new goldens).
4.  **Conformance**: `$CB/conformance.sh /home/user/carbon-tp <outdir>`:
    128/0/22 plus the new programs at P; `runner.py --self-test` (R7).
5.  **Mutants** (each must turn a named golden or program red, and is reverted;
    M2, M3, M15 and M16 were run on v13 and killed by the named input,
    `$X/mutants.log` and `$X/mutants2.log`, and M19 and M20 at rev 3,
    `$Y/au-v13.log` and `$Y/au-m20.log`): M1 restore A1's early exit
    (initialize.carbon and templates_return_aggregates_diff fail: crash); M2
    replace `CloneStorageAccessChain` by rev 1's `InsertHere` of the whole block
    (lower initialize.carbon `return_tuple_of_call`: RC-5's CHECK; measured on
    b09b, c1, c3); M3 drop A2's block (initialize.carbon
    `return_struct_convert`: segfault; measured on e01); M4 restore
    `FindStorageArgForInitializer`'s unconditional `GetInstAs` (for_range.carbon
    `range_param`: CHECK); M5 revert B1 in aggregate.cpp (destructure_param:
    FATAL); M6 revert B2 (initialize.carbon `class_method_return_tuple` lower
    split: CHECK); M7 revert B3 (return_tuple lower: CHECK); M8 revert A5
    (destructure_param: lowering CHECK on a symbolic splice); M9 drop A6 (lower
    for_range.carbon `range_param_called_array`: segfault, then with B5 the new
    CHECK); M10 make D-TP-10's callee rule apply only when `has_value()` is
    false (templates_dependent_call: `CallToNonCallable`); M11 revert
    `IsCallPerformable` (deduce_class_args: `DeductionIncomplete`); M12 remove
    the template branch of `EvalLookupSingleFinalWitness` (default_init.carbon
    `var_uninit`: the v6 shape, `DefaultOrUnformed` selected in the definition);
    M13 make `SameMemberEntity` always true (constraint_lookup
    `fail_different_entities` succeeds); M14 drop C3's
    `PointerDereferenceAction` creation (pointer.carbon: `DerefOfNonPointer` at
    the definition); M15 restore rev 1's constant comparison for non-function
    results (`fail_field_vs_constraint_method` succeeds; measured: a09 prints `2
    9`); M16 keep A1's early exit when the storage is a `VarStorage`
    (initialize.carbon `var_with_destructor` lower split: the copy goes to a
    temporary and `%y.var` is destroyed uninitialized; templates_dependent_var
    prints a garbage value where it expects 11; measured on n04 and b02); M17
    drop `NamesTemplateBinding`'s interface-argument test (default_init.carbon
    `template_interface_facet_value`, whose conversion of `i32` to a `Tag(U)`
    facet is rejected in the definition, and `template_interface_final_impl`,
    whose definition selects the final impl; (amended 2026-10-14,
    implementation-review fold: IR1-m1 / IR2-MAJOR-1)); M18 revert commit S, the
    SC-1 composition rule (nine SC-1 template-constraint goldens fail, measured
    in scv13; amended 2026-10-14, review fold: RR-m2); M19 remove A7's three
    early returns (initialize.carbon `let_class_value_of_call` and
    `let_array_value_of_calls`: ``Built invalid semantics IR`` during checking;
    measured, v13 is this mutant, by its autoupdate of rev 3's
    initialize.carbon); M20 drop `HasSameFieldNames` from A7's class test
    (initialize.carbon `fail_class_value_unexpected_field` loses its error,
    because `G` is never called, and file_test reports the `fail_` split as
    succeeded; measured on variant m20; M19 and M20 added 2026-10-14, review
    fold: RR-M1); M21 remove D-TP-25's call in `LowerInst` (lower
    initialize.carbon's constant-element splits: function_context.cpp's CHECK;
    templates_constant_elements does not compile); M22 remove D-TP-26's
    diagnosis (index.carbon `fail_index_in_array_bound_on_instantiation`:
    eval.cpp's FATAL); M23 remove the two `IsDeclResolvedPerInstantiation` tests
    (fail_todo_import.carbon's `_declaration` splits:
    `TryResolveInstCanonical`'s FATAL); M24 remove the `TupleIndexAction`
    stringification and rename the `CallAction` one (index.carbon
    `fail_redecl_differs_in_dependent_operation`: ``<cannot stringify ...>``);
    M25 drop the predicate's unqualification and its `SpliceInst`
    (pointer.carbon `deref_const_param` and index.carbon
    `tuple_index_associated_type`: errors where the function is defined); M21 to
    M25 added (amended 2026-10-14, implementation-review fold: IR1-B1 / IR1-M1 /
    IR1-M2 / IR1-m2 / IR1-m3). The focused re-review of the fold redefines M22
    (remove D-TP-26's whole diagnosis in `TryEvalTypedInst`: index.carbon and
    pointer.carbon abort at eval.cpp's FATAL) and M23 (remove the class's
    `IsTypeResolvedPerInstantiation` test and the function's
    `IsDeclResolvedPerInstantiation` test: fail_todo_import.carbon aborts at
    `TryResolveInstCanonical`'s FATAL), keeps M24 over the re-review's
    `PushPostfix` text, and adds M26 (D-TP-26 narrowed back to `ArrayType`, the
    fold's rule: index.carbon and pointer.carbon abort at the FATAL), M27
    (remove `ConvertTupleToType`'s splice resolution: lower initialize.carbon
    aborts at `file_context.h`'s CHECK), M28 (`IsTypeResolvedPerInstantiation`
    tests the declaration only: fail_todo_import.carbon aborts), M29 (no
    interface or named-constraint test: fail_todo_import.carbon aborts), M30 (no
    parentheses around a prefix operand and no `AssociatedEntity` printing:
    index.carbon's redeclaration split prints ``<cannot stringify ...: {kind:
    AssociatedEntity, ...}>``), M31 (no `AddrOfAction` or
    `CompoundMemberAccessAction` printing and no `->` branch: the split prints
    ``<cannot stringify ...>`` for both kinds), M32 (no error value in the
    specific: index.carbon aborts at value_store.h's CHECK), M33 (no rule for an
    operand used as a type:
    `fail_tuple_index_as_conversion_target_on_instantiation` succeeds) and M34
    (no error arm in `GetExprCategory`: index.carbon aborts at inst.h's cast
    CHECK) (amended 2026-10-15, focused re-review of the fold: RR1-B1 / RR1-M1 /
    RR2-M1 / RR1-M2 / RR1-m1 / RR2-m6). Round 2 of the focused re-review
    redefines M22, M26, M28, M31, M32 and M33 to the same intent over the code
    it rewrote (M28: a class type's definition block is not walked; M31 also
    drops the `->` printing that moved to `GetArrowPointer`), and adds
    M35 (only an instruction's first runtime operand is an error: index.carbon
    aborts at value_store.h's CHECK), M36 (`ConvertStructToClass` converts a
    class template's literal where the template is defined: deduce_class_args
    and lower initialize.carbon change), M37, M38 and M39 (b678e2985's test
    that deferred a struct, tuple or array holding such a class whole, removed
    from each: lower initialize.carbon changed in value names only, so
    f44280c1c removed the test, and the three have no code left), M40
    (`NeedsSpecificInst` does not look into a literal's
    elements: lower initialize.carbon aborts at value_store.h's CHECK), M41 and
    M42 (no `->` printing for a member access or a compound member access:
    index.carbon's redeclaration split changes), M43 to M49 (the walk adds a
    named class's declaration only, skips the bindings' types, skips a facet
    type, imports an impl whatever it names, tests a declaration block or a
    definition for actions and splices only, or loses `HasErrorConstraint`:
    fail_todo_import.carbon aborts), M50 (the walk keeps no visited sets:
    fail_todo_import.carbon does not finish) and x1 and x2 (the error arms of
    `TryGetCalleeAsBoundMethod` and `FindStorageArgForInitializer` removed:
    expected to survive, as D-TP-26 records) (amended 2026-10-15, focused
    re-review of the fold: RR2-1-M1 / RR2-1-M2 / RR2-1-m1 /
    RR2r2-M1 / RR2r2-m1). Round 3 redefines M43 (a class that an operand
    names adds its declaration only) and M50 (the walk keeps no set of
    instructions or generics) and adds M51 to M67: the walk follows no
    operand (M51), no instruction's type (M52), no specific operand (M53), no
    struct field type (M54), no block operand (M55), no impl operand (M56),
    no facet type's specifics (M57) or its constraints' types and rewrites
    (M66), no specific's arguments (M59), no absolute instruction (M62),
    function (M63), interface or named constraint (M64) or specific
    interface (M65) operand; `TryFinishSpecific` imports every definition
    (M58); a function's specific adds its definition (M60); a walk that
    reaches an action records what it reached (M61); and M44 with M52
    (M67). M44, M52, M56, M60, M62, M64 and M65 are expected to survive, as
    the round-3 measurements record (amended 2026-10-15, focused re-review
    of the fold: RR3-1-M1 / RR3r2-M1).
6.  **clang-tidy** on every changed `.cpp` with the repository's configuration
    (LLVM 21.1.8's clang-tidy, as VA-1 ran it), except
    `modernize-use-trailing-return-type`: with it, this container's clang-tidy
    stops every file at a location-less ``missing '(' after '__has_feature'``
    (`clang-diagnostic-error`), and it is the only one of the eight
    `modernize-*` checks tried on lower/aggregate.cpp that does so ((amended
    2026-10-14, implementation-review fold: IR2-MINOR-7)); **prek** with
    `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest`
    on the changed paths to a fixpoint, with R31's heading and list counts
    before and after each markdown edit.
7.  **Merge and land-time integration**: after M, the full build,
    autoupdate, gate, conformance and §0.9's dry run on the merged tree; after
    L and each of its document-review folds, `python3
    fork/designdocs/check_samples.py` with and without `--toolchain
    <TP-1 install>/bin/carbon`, expecting 0 errors with the toolchain (the six
    C3 fixtures of §2.9 included).
8.  **Not run, and why**: hosted CI (GitHub Actions disabled on the
    repository); bazel and the bazel-only tests (no bazel in the container;
    gtest unit tests, lit, fuzzers, clangd-tidy's compile_commands); ASan and
    macOS/Windows; LLVM with assertions (the container's LLVM is Release); the
    owner's runner (R28).

**Measured at implementation (amended 2026-10-14, implementation: measured).**
The implementer's scratch is `$I`,
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1-impl`
(`impl/` for C1 to F5, `stage4/` for P, the mutants, M and the compositions,
`sim-l/` for L).

-   Baseline: `$Y/v14.diff` relinked over the trunk objects, 1935 of 1942
    with the seven refills of §0.8, failure output byte-identical to
    `$Y/gate-v14.log`; conformance 128/0/22 over 150.
-   Build (item 1): C1 a full build (322 steps), C3 and C5 X-macro rebuilds
    (181 and 272 steps), C2 and C4 incremental; `-Werror` clean. M changes
    no toolchain, core or testdata file and is not rebuilt: the install of
    record, 0.0.0-0.dev+df6487a05, is built from sources equal to M's.
-   Gate (items 2 and 3), each commit alone, then with its fill, every fill
    at its autoupdate fixpoint (a second pass changed nothing, except F3's,
    which moved location numbers only; its third changed nothing): C1
    (675e0dd94) 1939 of 1946, F1 (283197da2) 1946; C2 (637e3efaf) 1945 of
    1947, F2 (1eff04d24) 1947; C3 (438b3c971) 1945 of 1952, F3 (a8b3c7900)
    1952; C4 (781908afb) 1947 of 1954, F4 (989a6496c) 1954; C5 (df6487a05)
    1954 of 1955, F5 (96fa092b6) 1955; P (32c8ed777) and M (6efc3f257)
    1955 of 1955. No commit crashed. Each red set is §0.8's, except that two
    of Appendix A's splits need C4 and are added by C4, not C3:
    index.carbon's `index_class_with_index_with` (without C4, `Get(v, 0)`
    fails with `DeductionIncomplete`) and pointer.carbon's
    `fail_deref_class_type_param` (without C4, `C(T)` is a `call_action`
    splice and the message prints `<cannot stringify ...>`), so C4 alone is
    red on seven files, index.carbon and pointer.carbon among them.
-   Conformance (item 4): 128/0/22 over 150 at C2, C3 and C5; 136/0/22 over
    158 at P and at M, 48 of 56 bullets PASS; `runner.py --self-test`
    reports "158 programs parsed, 56 bullets in table, OK". The eight
    programs print their EXPECT lines: templates_dependent_pointer `4 7 8`,
    templates_dependent_index `5 2 8`, templates_for_dependent_range
    `6 10 12`, templates_dependent_call `8 25`, templates_constraint_lookup
    `25 6`, templates_deduce_class_args `21 42 3`, templates_dependent_var
    `5 6 11 0 1`, and templates_return_aggregates_diff
    `8 10 8 6 9 4 5 7 7`, as its C++ oracle does.
-   Mutants (item 5): each was relinked over the build of C5 (M18 over the
    SC-1 composition, §0.9) and run on its named goldens alone, the full
    gate (1955 files) and the eight programs (`$I/stage4/mut/`). A golden
    file stops at its first crash, so where the named split is not the
    first to crash, it was also compiled alone. Nineteen are killed; M17
    survives, and is open for the fixer.
-   clang-tidy and prek (item 6): no clang-tidy diagnostic on the changed
    lines of any changed `.cpp` (the repository's configuration without its
    `modernize-*` checks); prek clean on every commit's paths.
-   Merge and land-time integration (item 7): M merged trunk's records only
    (§1.12); the dry run and the compositions are §0.9's "Composition at
    state T", and the checker runs are §2.9's "Measured with TP-1's
    toolchain".

| Mutant | Named killer (§8 item 5) | Measured |
| --- | --- | --- |
| M1 | initialize.carbon, templates_return_aggregates_diff: crash | killed: check and lower initialize.carbon abort in `return_tuple` (`CHECK failure at toolchain/check/convert.cpp:2278: new_storage_id.has_value()`), and so does the program's compile; templates_dependent_var also prints a garbage value for 11 |
| M2 | lower initialize.carbon `return_tuple_of_call`: RC-5's CHECK | killed: lowering `G(i32)` aborts (`function_context.cpp:223: const_id.is_concrete()`, a `SpecificInst` with a non-concrete value); check initialize.carbon changes; the differential program aborts |
| M3 | initialize.carbon `return_struct_convert`: segfault | killed: check and lower initialize.carbon segfault in `return_struct_convert` |
| M4 | for_range.carbon `range_param`: CHECK | killed: checking `range_param`'s `for` header aborts (`inst.h:249`, a `TupleAccess` cast to `InstValue`); templates_for_dependent_range aborts |
| M5 | `destructure_param`: FATAL | killed: lowering `Sum((i32, i32))` in `destructure_param` aborts (`FATAL failure at toolchain/lower/aggregate.cpp:69: Unexpected expression category for aggregate access into ... SpliceInst`); the differential program aborts |
| M6 | lower `class_method_return_tuple`: CHECK | killed: lower initialize.carbon aborts first in `return_tuple` (`Dup(i32)`, `function_context.cpp:223` on an `InPlaceInit`); `class_method_return_tuple` alone aborts the same way in `Both(i32)`; the differential program aborts |
| M7 | lower `return_tuple`: CHECK | killed: lowering `Dup(i32)` in `return_tuple` aborts (`value_store.h:284: id.index >= 0: inst<none>`); the differential program aborts |
| M8 | `destructure_param`: lowering CHECK on a symbolic splice | killed: lowering `Sum((i32, i32))` aborts (`function_context.cpp:223` on a `SpliceInst`); check initialize.carbon changes; the differential program aborts |
| M9 | lower for_range.carbon `range_param_called_array`: B5's CHECK | killed: B5's `CHECK failure at toolchain/lower/file_context.cpp:443` ("Return slot for ... without parameters") lowering `Sum(array(i32, 3))`; check for_range.carbon changes |
| M10 | templates_dependent_call: `CallToNonCallable` | killed: the program does not compile (``value of type `<type of Twice>` is not callable``); call.carbon, call_wrong_arg_type.carbon and lower dependent_call.carbon change |
| M11 | deduce_class_args.carbon: `DeductionIncomplete` | killed: `holder`, `holder_copy_constraint` and `holder_pointer` report `DeductionIncomplete`; convert.carbon, destroy_calls.carbon, index.carbon, pointer.carbon and lower template/class.carbon change; templates_deduce_class_args does not compile |
| M12 | default_init.carbon `var_uninit`: v6's shape | killed: `var_uninit`'s definition selects the prelude's `DefaultOrUnformed` impl (`impl_witness ..., @T.as_type.as.DefaultOrUnformed.impl(%Default.facet) [template]`); only default_init.carbon changes |
| M13 | constraint_lookup `fail_different_entities` succeeds | killed: "split `fail_different_entities.carbon` succeeded" |
| M14 | pointer.carbon: `DerefOfNonPointer` in the definition | killed: `deref_param` and `fail_deref_non_pointer_on_instantiation` report `DerefOfNonPointer`, and `arrow_member` `ArrowOperatorOfNonPointer`, where the function is defined; unimplemented.carbon and lower pointer_index.carbon change; templates_dependent_pointer does not compile |
| M15 | `fail_field_vs_constraint_method` succeeds | killed: "split `fail_field_vs_constraint_method.carbon` succeeded" |
| M16 | lower `var_with_destructor`; templates_dependent_var prints garbage for 11 | killed: `Copy` writes a temporary, not `%y.var`; templates_dependent_var prints `5 6 -2036312640 0 1`; check initialize.carbon and for_range.carbon change |
| M17 | default_init.carbon `template_interface_concrete_self`: an error in the definition | **survives**: gate 1955 of 1955, the eight programs pass. The split's `return x;` is one deferred `initialize_action` into the return slot, so no `i32 as ImplicitAs(U)` lookup is made in the definition (its SemIR has no `lookup_impl_witness`); its SemIR, and that of two probes (a class with `impl as Core.ImplicitAs(i64)` returned as `U`, and `x.(Tag(U).Id)()` with a `final impl forall [T: type] i32 as Tag(T)`), is identical with and without the mutant (`$I/stage4/mutprobe/M17`). Open for the fixer |
| M18 | SC-1's nine template-constraint goldens | killed: over SC-1 a35535174 without S, nine SC-1 template-constraint goldens fail (1943 of 1959 on SC-1's testdata, 1963 of 1972 on the composed testdata), their splits reporting `TemplateMemberLookupAmbiguous`; with S, none (§0.9) |
| M19 | `let_class_value_of_call`, `let_array_value_of_calls`: invalid SemIR during checking | killed: ``Built invalid semantics IR`` (a `temporary_storage` not dominated by its evaluation) checking `let_class_value_of_call`; `let_array_value_of_calls` alone fails the same way |
| M20 | `fail_class_value_unexpected_field` succeeds | killed: "split `fail_class_value_unexpected_field.carbon` succeeded" |

**Measured at the implementation-review fold (amended 2026-10-14,
implementation-review fold: IR1-B1 / IR1-M1 / IR1-M2 / IR1-m1 / IR2-MAJOR-1 /
IR2-MINOR-7).** The fixer's scratch is `$I/fixer` (`probe/` for the
reproductions, `mut/` for the mutants, `comp/` for the compositions).

-   Build (item 1): both fix commits incremental, `-Werror` clean; the install
    of record is 0.0.0-0.dev+12bd6d67a, whose toolchain sources equal the
    fold head's (its fill and records commits change no toolchain file).
-   Gate (items 2 and 3): 7c7b1b170 alone 1952 of 1955 (check and lower
    initialize.carbon, lower/template/merging.carbon), with its fill
    17501c978 1955 of 1955; 12bd6d67a alone 1950 of 1955 (default_init,
    pointer, index, fail_todo_import and constraint_lookup under
    generic/template), with its fill f360b8735 1955 of 1955. No commit
    crashed; each fill's second autoupdate pass changed nothing.
-   Conformance (item 4): 137/0/22 over 159 at both fix commits, 48 of 56
    bullets PASS; `runner.py --self-test` reports "159 programs parsed, 56
    bullets in table, OK"; templates_constant_elements prints
    `41 42 43 41 41 423 34 41 42` (trunk stops the compiler with a
    segfault).
-   Mutants (item 5): every mutant was relinked again over the fold's build
    (`$I/fixer/bin/mutate.py`, which carries M14's text after the fold's
    edit of `PerformPointerDereference`), and run on its named goldens, the
    full gate (1955 files) and the nine programs; M18 runs over the SC-1
    composition (§0.9). All twenty-five are killed; M17 is killed by the
    fold's splits.
-   clang-tidy (item 6): on the changed lines of every `.cpp` TP-1 changes (`git
    diff b2576f6c3..` of the fold's head, 18 files), with every check of the
    repository's configuration but `modernize-use-trailing-return-type`: no
    diagnostic in any of the 18 files, the other `modernize-*` checks included
    (`$I/fixer/tidy-tp1-all.log`). The fold's own code needed three
    `NOLINTNEXTLINE(misc-no-recursion)` lines in function_context.cpp, because
    D-TP-25 lowers from inside `LowerInst` (the recursion is bounded by the
    nesting of splices).
-   prek (item 6): clean on each fix commit's paths; `uvx prek run
    --all-files` to a fixpoint before the push.
-   Land-time integration (item 7): §2.9's checker runs repeat with 0 errors;
    the compositions are §0.9's "Composition at the implementation-review
    fold".

| Mutant | Named killer | Measured at the fold |
| --- | --- | --- |
| M1 | initialize.carbon, templates_return_aggregates_diff | killed: check and lower initialize.carbon abort (`convert.cpp:2278`); templates_return_aggregates_diff and templates_constant_elements do not compile; templates_dependent_var prints garbage for 11 |
| M2 | lower `return_tuple_of_call` | killed: lower initialize.carbon aborts (function_context.cpp's `const_id.is_concrete()` CHECK); check initialize.carbon changes; the differential program aborts |
| M3 | `return_struct_convert` | killed: check and lower initialize.carbon segfault |
| M4 | for_range.carbon `range_param` | killed: check and lower for_range.carbon abort (`inst.h:249`); templates_for_dependent_range aborts |
| M5 | `destructure_param` | killed: lower initialize.carbon aborts (`aggregate.cpp:69`); the differential program aborts |
| M6 | lower `class_method_return_tuple` | killed: lower initialize.carbon aborts; the differential program and templates_constant_elements abort |
| M7 | lower `return_tuple` | killed: lower initialize.carbon aborts (`value_store.h:284`); the differential program and templates_constant_elements abort |
| M8 | `destructure_param` | killed: lower initialize.carbon aborts on a `SpliceInst`; check initialize.carbon changes; the differential program aborts |
| M9 | lower `range_param_called_array` | killed: B5's CHECK (`file_context.cpp:443`); check for_range.carbon changes |
| M10 | templates_dependent_call | killed: the program does not compile; call.carbon, call_wrong_arg_type.carbon and lower dependent_call.carbon change |
| M11 | deduce_class_args.carbon | killed: eight goldens change, among them deduce_class_args.carbon, default_init.carbon (the fold's `Tag(U)`) and lower initialize.carbon (the fold's `P(T)` splits); templates_deduce_class_args does not compile |
| M12 | default_init.carbon `var_uninit` | killed: only default_init.carbon changes |
| M13 | `fail_different_entities` | killed: it and `fail_cowboy` succeed |
| M14 | pointer.carbon | killed: pointer.carbon, unimplemented.carbon, index.carbon (the fold's `C(*p)`) and lower pointer_index.carbon change; templates_dependent_pointer does not compile |
| M15 | `fail_field_vs_constraint_method` | killed: the split succeeds |
| M16 | lower `var_with_destructor`; templates_dependent_var | killed: check and lower initialize.carbon and check for_range.carbon change; templates_dependent_var prints a garbage value for 11 |
| M17 | default_init.carbon `template_interface_facet_value` and `template_interface_final_impl` | killed: `template_interface_facet_value` fails in the definition (``cannot convert type `i32` into type implementing `Tag(U)` ``), and `template_interface_final_impl`'s definition selects `impl_witness @i32.as.Tag.impl(%U)` instead of keeping `lookup_impl_witness`; only default_init.carbon changes |
| M18 | SC-1's nine template-constraint goldens | killed: over SC-1 1646988dc without S, the nine goldens fail (1942 of 1959 on SC-1's testdata with TP-1's eight refills, 1963 of 1972 composed); with S, none (§0.9) |
| M19 | `let_class_value_of_call`, `let_array_value_of_calls` | killed: ``Built invalid semantics IR`` checking initialize.carbon |
| M20 | `fail_class_value_unexpected_field` | killed: the split succeeds |
| M21 | lower initialize.carbon's constant-element splits; templates_constant_elements | killed: lower initialize.carbon aborts (function_context.cpp's CHECK on a `SpecificInst`), merging.carbon changes, and the program does not compile |
| M22 | index.carbon `fail_index_in_array_bound_on_instantiation` | killed: index.carbon aborts (`eval.cpp`: ``PatternType should always be constant``) |
| M23 | fail_todo_import.carbon's `_declaration` splits | killed: fail_todo_import.carbon aborts (``Missing case in TryResolveInstCanonical for instruction kind SpliceInst``) |
| M24 | index.carbon `fail_redecl_differs_in_dependent_operation` | killed: the messages print ``<cannot stringify ...: {kind: TupleIndexAction, ...}>``; only index.carbon changes |
| M25 | pointer.carbon `deref_const_param`, index.carbon `tuple_index_associated_type` | killed: ``cannot dereference operand of non-pointer type`` and ``type `T.Elem` does not support tuple indexing`` where the functions are defined, and `fail_tuple_index_const_param_on_instantiation`'s error moves there too |

**Measured at the focused re-review of the fold (amended 2026-10-15, focused
re-review of the fold: all findings).** In `$F`: `p/` and `work/` for the
reproductions and probes, `sweep/final.tsv` for the sweep, `mutants/` and
`allmut/` for the mutants, `conf/` for conformance. Container-built, EXPECTED,
not of record (Actions disabled).

-   Build (item 1): each fix commit incremental, `-Werror` clean; the install
    of record is 0.0.0-0.dev+1f0bc7be0, whose toolchain sources equal
    ba64734e7's (its fill and the records commit change no toolchain source).
-   Gate (items 2 and 3): 632f92117 alone 1952 of 1955 (index.carbon,
    pointer.carbon, lower initialize.carbon), with its fill d069d639d 1955 of
    1955; d8f6ab60a alone 1954 of 1955 (fail_todo_import.carbon), with its
    fill 22b9074bd 1955 of 1955; 73b3124dd alone 1954 of 1955 (index.carbon),
    with its fill 831289fad 1955 of 1955; 67a9dd91c 1955 of 1955; ba64734e7
    alone 1954 of 1955 (index.carbon), with its fill 1f0bc7be0 "file_test test
    mode on /home/user/carbon-tp: 1955 passed, 0 failed (exit 0, 27s)", its log
    "Ran 1955 tests in 25648 ms wall time, 99037 ms across threads" with 0 `!`
    and 0 `?` marks. No commit crashed; each fill's second autoupdate pass
    changed nothing.
-   Conformance (item 4), into `$F/conf`: "PASS 137, COMPILE-FAIL 0, LINK-FAIL
    0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 (of 159)",
    bullets 48 PASS / 0 FAIL / 8 SKIP / 0 NOT-WRITTEN of 56, scoreboard
    generated 2026-10-19T15:28:25Z (the container clock) in 67.7 s; `runner.py
    --self-test`: "self-test: 159 programs parsed, 56 bullets in table, OK".
-   Mutants (item 5): M22, M23 and M24 (whose code the fix commits change) and
    the new M26 to M34, each built by recompiling its one translation unit into
    `/dev/shm/fixer-r1/<name>` and relinking `file_test` (`$F/bin/mut.sh`), run
    on its named goldens: all killed (`$F/mutants/mutants_final.log`,
    `m22_final.log`). M1 to M17, M19 to M21 and M25 re-run with the fold's
    harness over this build (`$F/allmut`, M4's text updated for ba64734e7's
    edit of its line), each on its named goldens, the full gate and the nine
    programs: all killed. M18 was not re-run: it reverts S, which is a
    land-time commit, and the re-review changes no file S touches.
-   clang-tidy (item 6): 0 diagnostics on the re-review's changed lines of
    convert.cpp, eval.cpp, import_ref.cpp, expr_info.cpp, function.cpp and
    stringify.cpp (`$F/tidy_final.log`), with the same exclusion; after
    67a9dd91c, clang-format (the same LLVM release) changes nothing.
-   Probes: the 213 single-file and cross-library probes of the two re-reviews
    and the fixer, swept on the fork, trunk 0bdce60a5 and the nightly
    (`$F/bin/sweep.py`, `$F/sweep/final.tsv`): on the fork 72 compile, 137 are
    rejected with a diagnostic and 4 stop the compiler, each as on trunk and
    the nightly (e01_twin, which has no template, at a constant tuple holding
    a class value, W-263's class; local_i twice and main_k2, W-270); trunk
    stops on 84 and the nightly on 77. Of the 54 cross-library probes, 39
    report W-250's TODO where trunk stops the compiler on 38.
-   Not re-run (land-time items, §1.12): the compositions with SC-1 and VA-1,
    the L simulation and PR 58's checker. The re-review's convert.cpp hunk is
    in `ConvertTupleToType` and its include, which merge with PR 60 cleanly
    (`git merge-tree`: PR 60 conflicts in the two `PerformAction` hunks only).

| Mutant | Named killer | Measured at the focused re-review of the fold |
| --- | --- | --- |
| M22 (redefined) | index.carbon, pointer.carbon | killed: both abort (``PatternType should always be constant``) |
| M23 (redefined) | fail_todo_import.carbon | killed: it aborts (``Missing case in TryResolveInstCanonical for instruction kind SpliceInst``) |
| M24 | index.carbon `fail_redecl_differs_in_dependent_operation` | killed: ``<cannot stringify ...: {kind: TupleIndexAction, ...}>`` and ``{kind: CallAction, ...}`` |
| M26 | index.carbon, pointer.carbon | killed: both abort (``PatternType should always be constant``) |
| M27 | lower initialize.carbon `return_tuple_of_associated_type`, `var_tuple_of_associated_type` | killed: it aborts (``type_id.is_concrete(): Lowering symbolic type ... TupleType``) |
| M28 | fail_todo_import.carbon `_class_field_type`, `_class_method_declaration` | killed: it aborts (``Missing case in TryResolveInstCanonical``) |
| M29 | fail_todo_import.carbon `_interface_declaration`, `_constraint_declaration` | killed: it aborts (``Missing case in TryResolveInstCanonical``) |
| M30 | index.carbon `fail_redecl_differs_in_dependent_operation` | killed: K and L print ``<cannot stringify ...: {kind: AssociatedEntity, ...}>`` |
| M31 | the same split | killed: ``<cannot stringify ...: {kind: CompoundMemberAccessAction, ...}>`` and ``{kind: AddrOfAction, ...}`` |
| M32 | index.carbon's runtime-type splits | killed: it aborts (``id.index >= 0: inst<none>``) |
| M33 | index.carbon `fail_tuple_index_as_conversion_target_on_instantiation` | killed: the split succeeds |
| M34 | index.carbon's runtime-type splits | killed: it aborts (``Casting inst {kind: ErrorInst, ...} to wrong kind InstValue``) |

**Measured at the focused re-review of the fold, round 2 (amended 2026-10-15,
focused re-review of the fold: all round-2 findings).** In `$F`, which for
this round is `.../tp1-rr/fixer-r2`: `probes/` for the reproductions and the
fixer's probes, `sweep/final2.tsv` for the sweep, `mut/` for the mutants,
`conf/` and `conf2/` for conformance and `logs/` for the builds, autoupdates
and gates.
Container-built, EXPECTED, not of record (Actions disabled).

-   Build (item 1): each fix commit incremental, `-Werror` clean; the install
    of record is 0.0.0-0.dev+24bf5ea45, whose toolchain sources equal
    f44280c1c's (its fill and the two records commits change no toolchain
    source).
-   Gate (items 2 and 3): 2165322c5 alone 1954 of 1955 (index.carbon), with
    its fill e6a663c22 1955 of 1955; 123eb40ca alone 1954 of 1955
    (index.carbon), with its fill 8af8ad78b 1955 of 1955; b678e2985 alone
    1953 of 1955 (deduce_class_args.carbon, lower initialize.carbon), with its
    fill 7ea3fed97 1955 of 1955; 94227d82c alone 1954 of 1955
    (fail_todo_import.carbon), with its fill 4fcbf62ef 1955 of 1955;
    282930a73, which changes no golden, 1955 of 1955; f44280c1c alone 1954 of
    1955 (lower initialize.carbon, in value names only), with its fill
    24bf5ea45 "file_test test mode on /home/user/carbon-tp: 1955 passed, 0
    failed (exit 0, 26s)", its log "Ran 1955 tests in 24766 ms wall time,
    95784 ms across threads" with 0 `!` and 0 `?` marks. No commit crashed;
    each fill's second autoupdate pass changed nothing.
-   Conformance (item 4), into `$F/conf2`: "PASS 137, COMPILE-FAIL 0,
    LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22
    (of 159)", bullets 48 PASS / 0 FAIL / 8 SKIP / 0 NOT-WRITTEN of 56,
    scoreboard generated 2026-10-19T18:50:58Z (the container clock) in 67.5 s,
    the same counts as 282930a73's run in `$F/conf` (generated 18:05:21Z; the
    directories amended 2026-10-15, records: re-review round 2);
    templates_deduce_class_args prints `21 42 3 16 8`; `runner.py
    --self-test`: "self-test: 159 programs parsed, 56 bullets in table, OK".
-   Mutants (item 5): each relinked over 24bf5ea45's build by recompiling its
    translation units into `/dev/shm/fixer-r2-mut` (`$F/mut/bin/runmut2.sh`,
    the texts in `$F/mut/bin/mutate2.py`) and run on its named goldens, the
    full gate and the nine programs. The new M35, M36 and M40 to M49 and the
    redefined M22, M26, M28, M31, M32 and M33 are killed, as the table below
    gives; M1 to M17, M19 to M21, M23 to M25, M27, M29, M30 and M34, re-run,
    are killed by their named goldens, as before. M37 to M39 were run over
    282930a73's build, where they changed lower initialize.carbon's struct,
    tuple and array splits in value names only, which is why f44280c1c
    removes the test they mutate. M50 was run on
    fail_todo_import.carbon alone, which did not finish in 120 s where it
    takes 16 ms (`$F/mut/bin/runmut50.sh`), so its gate was not run. x1 and x2
    survive: the gate passes 1955 of 1955 and the nine programs print their
    EXPECT lines. M18 was not re-run: it reverts S, a land-time commit, and
    round 2 changes no file S touches. No `/dev/shm` copy is left.
-   clang-tidy (item 6): 0 diagnostics on round 2's changed lines of
    action.cpp, convert.cpp, eval.cpp, import_ref.cpp and stringify.cpp
    against 764e55445 at 24bf5ea45 (`$F/logs/tidy3.log`), with the same
    exclusion. Before
    282930a73, `misc-no-recursion`, an error in this configuration, reported
    the recursive forms of the walk and of `NeedsSpecificInst`
    (`$F/logs/tidy.log`). clang-format 21.1.8 changes none of the five files.
-   Probes: the 284 single-file and cross-library probes of the round's two
    reviews and its fixer, swept on the fork, trunk 0bdce60a5 and the nightly
    (`$F/mut/bin/sweep.py`, and `sweep2.py`, which compiles each of the 64
    cross-library probes with the libraries it imports; `$F/sweep/final2.tsv`):
    on the fork 114 compile, 149 are rejected with a diagnostic and 21 stop
    the compiler; trunk stops on 90 and the nightly on 96, and no probe that
    trunk compiles fails on the fork. Of the 21, 18 are W-263's class, a
    constant nested aggregate that fails LLVM verification (lower.cpp:48): 16
    stop trunk and the nightly too, and the first review's b06c and
    b06_type_members are rejected by trunk where the function is defined while
    their twins stop all three. The other 3 are W-271 (y04, y05 and y09), as on
    trunk and the nightly. Of the 64 cross-library probes, 40 report W-250's
    TODO, once per entity (twice for p1 and p6, each of which uses two
    entities), where trunk stops on 43; 16 compile; 5 are rejected in their
    library with trunk's own diagnostic; and every one that compiled at
    764e55445 (the second review's logs) still compiles. The sweep ran on
    282930a73's toolchain; the fork's column, re-run at 24bf5ea45
    (`$F/sweep/fork_24bf5ea45.tsv`), is unchanged.
-   Not re-run (land-time items, §1.12): the compositions with SC-1 and VA-1,
    the L simulation and PR 58's checker. `git merge-tree` of 24bf5ea45 with
    trunk f3156a375 and each held PR gives the PR body's conflict table
    unchanged; with PR 60, convert.cpp conflicts in the two `PerformAction`
    hunks only, so round 2's convert.cpp hunks merge cleanly.

| Mutant | Named killer | Measured at round 2 of the focused re-review of the fold |
| --- | --- | --- |
| M22 (redefined) | index.carbon, pointer.carbon | killed: both abort (``PatternType should always be constant``) |
| M26 (redefined) | index.carbon, pointer.carbon | killed: both abort (``PatternType should always be constant``) |
| M28 (redefined) | fail_todo_import.carbon | killed: it aborts (``Missing case in TryResolveInstCanonical for instruction kind SpliceInst``) |
| M31 (redefined) | index.carbon `fail_redecl_differs_in_dependent_operation` | killed: ``<cannot stringify ...: {kind: CompoundMemberAccessAction, ...}>`` and ``{kind: AddrOfAction, ...}``, and `C(*p.m)` for `C(p->m)` |
| M32 (redefined) | index.carbon's runtime-type splits | killed: it aborts (``id.index >= 0: inst<none>``) |
| M33 (redefined) | index.carbon `fail_tuple_index_as_conversion_target_on_instantiation` | killed: the split succeeds |
| M35 | index.carbon `fail_array_type_two_runtime_operands_on_instantiation` | killed: it aborts (``id.index >= 0: inst<none>``) |
| M36 | deduce_class_args.carbon's and lower initialize.carbon's `_dependent_array_bound` splits | killed: ``cannot initialize array with dependent bound from a list of initializers`` where the functions are defined |
| M37, M38, M39 | lower initialize.carbon's `var_struct_`, `var_tuple_` and `var_array_of_class_with_dependent_array_bound` | at 282930a73, red in value names only, the stores unchanged; f44280c1c removes the test they mutate |
| M40 | lower initialize.carbon `let_class_value_with_template_value_field` | killed: it aborts (``id.index >= 0: inst<none>``) |
| M41 | index.carbon `fail_redecl_differs_in_dependent_operation` | killed: N, R and S print `C((*p).m)`, `C(*(*p).q)` and `C((**p).n)` |
| M42 | the same split | killed: U prints `C((*p).(J.G)())` on both sides |
| M43 | fail_todo_import.carbon `_nested_class_field_type` | killed: it aborts (generic.cpp:239's CHECK, ``Adding generic constant ... with non-symbolic value``) |
| M44 | fail_todo_import.carbon `_function_constrained_by_template_interface` | killed: it aborts (sem_ir/type.cpp:27's CHECK) |
| M45 | the same split | killed: it aborts (sem_ir/type.cpp:27's CHECK) |
| M46 | fail_todo_import.carbon `_impl_constrained_by_template_interface` | killed: it aborts (generic.cpp:239's CHECK) |
| M47 | fail_todo_import.carbon's round-2 splits | killed: it aborts (sem_ir/type.cpp:27's CHECK) |
| M48 | fail_todo_import.carbon `_function_definition_names_class_template` | killed: it aborts (generic.cpp:239's CHECK) |
| M49 | fail_todo_import.carbon `_function_parameter_of_template_interface_type` | killed: it aborts (inst.h's cast CHECK, ``Casting inst {kind: ErrorInst, ...} to wrong kind GenericInterfaceType``) |
| M50 | fail_todo_import.carbon | killed: it does not finish in 120 s |
| x1 | none (`TryGetCalleeAsBoundMethod`'s error arm) | survives, as recorded: gate 1955 of 1955, the nine programs pass |
| x2 | none (`FindStorageArgForInitializer`'s error arm) | survives, as recorded: gate 1955 of 1955, the nine programs pass |

**Measured at the focused re-review of the fold, round 3 (amended 2026-10-15,
focused re-review of the fold: all round-3 findings).** In `$F`, which for
this round is `.../tp1-rr/fixer-r3`: `probes/` for the reproductions and the
fixer's probes, `sweep/` for the sweeps, `mut/` for the mutants, `conf/` for
conformance and `logs/` for the builds, autoupdates and gates.
Container-built, EXPECTED, not of record (Actions disabled).

-   Build (item 1): each fix commit incremental, `-Werror` clean; the install
    of record is 0.0.0-0.dev+d54c37f91, whose toolchain sources equal the
    head's (ada45a7c6, its fill and the records commit change no toolchain
    source).
-   Gate (items 2 and 3): 68102438e alone 1954 of 1955
    (fail_todo_import.carbon), with its fill d0fbfd56b 1955 of 1955, its log
    "Ran 1955 tests in 32862 ms wall time, 127218 ms across threads";
    d54c37f91, which changes no golden, "file_test test mode on
    /home/user/carbon-tp: 1955 passed, 0 failed (exit 0, 25s)", its log "Ran
    1955 tests in 23837 ms wall time, 91808 ms across threads"; ada45a7c6
    alone 1954 of 1955 (fail_todo_import.carbon), with its fill e7dc20a43
    "file_test test mode on /home/user/carbon-tp: 1955 passed, 0 failed (exit
    0, 26s)", its log "Ran 1955 tests in 24427 ms wall time, 94117 ms across
    threads" with 0 `!` and 0 `?` marks. No commit crashed; each fill's
    second autoupdate pass changed nothing. aa57bfe1c's import_ref.cpp,
    relinked over the same build, ran the gate in 102.6 s across threads
    (26.6 s wall); the times are one run each on this container.
-   Conformance (item 4), into `$F/conf`: "PASS 137, COMPILE-FAIL 0,
    LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 (of
    159)", bullets 48 PASS / 0 FAIL / 8 SKIP / 0 NOT-WRITTEN of 56, scoreboard
    generated 2026-10-19T20:56:03Z (the container clock) in 65.2 s on
    d54c37f91's toolchain; `runner.py --self-test`: "self-test: 159 programs
    parsed, 56 bullets in table, OK".
-   Mutants (item 5): each relinked over d54c37f91's build by recompiling
    import_ref.cpp into `/dev/shm/fixer-r3` (`$F/mut/bin/runmut3.sh`, the
    texts in `$F/mut/bin/mutate3.py`) and run on fail_todo_import.carbon, the
    full gate and the nine programs, which print their EXPECT lines under
    every mutant; each that survived the golden was also swept over the 110
    probes below (`$F/mut/bin/survsweep.sh`, `$F/mut/survsweep.log`). The
    mutants of import_ref.cpp's walk that round 2 defined are re-run (M23,
    M28, M29, M44 to M49) or redefined (M43, M50), and seventeen are new
    (M51 to M67). Killed, as the table below gives: M23, M28, M29, M43, M45
    to M51, M53, M55, M57 to M59, M63 and M67, and M54, M61 and M66 once
    ada45a7c6's splits pin the probes that they change. Seven survive the
    golden, the gate, the nine programs and the 110 probes, none of which
    any of them changes: M44 and M52, the binding-type and the
    instruction-type paths, each of which reaches what the other reaches
    (removing both, M67, is killed); M56, an impl operand, because a generic
    impl's witness names the impl's generic through its specific; M60, a
    function's specific adding its definition, which reports the same TODO
    for the caller instead of the callee; and M62, M64 and M65, an absolute
    instruction, an interface or named constraint, and a specific
    interface operand, which no shape measured reaches except through a
    facet type or a specific that the walk also follows. They stay, because
    the import loads what they name. The other mutants of earlier rounds
    mutate files round 3 does not change and are not re-run. No `/dev/shm`
    copy is left.
-   clang-tidy (item 6): 0 diagnostics on the round's changed lines of
    import_ref.cpp and context.h against aa57bfe1c at d54c37f91
    (`$F/logs/tidy.log`), with the same exclusion; clang-format 21.1.8
    changes neither file.
-   Probes: the round's 110 cross-library probes (the first review's 51, the
    second review's 14, round 2's second review's 11, the 17 splits of
    fail_todo_import.carbon at aa57bfe1c run with the full prelude, and the
    fixer's 17), swept on aa57bfe1c's import_ref.cpp relinked over the build,
    on the head, on trunk 0bdce60a5 and on the nightly (`$F/bin/xsweep.py`,
    `$F/sweep/final.tsv` and `surv.tsv`): at aa57bfe1c 38 stop the
    compiler; at the head the 32 of them that stopped after the TODO report
    it, once per entity, with no crash, and the other six stop the compiler
    as they do on trunk, W-271's four and q1 and q2; 47 more report the TODO
    on both, and 25 compile on both, so no probe that compiled at aa57bfe1c
    changes. Trunk and the nightly stop all 32 at `TryResolveInstCanonical`'s
    SpliceInst FATAL, and each compiles in one file on all three. The
    nightly also stops v2_n07, the checked twin of round 2's n01 to n03, at
    import_ref.cpp:1168, and rejects r2m_conv, r2m_plain and r2m_wrap, which
    the fork and trunk compile. The 103 probes swept at 68102438e's
    toolchain give the same result as at d54c37f91's.
-   Not re-run (land-time items, §1.12): the compositions with SC-1 and VA-1,
    the L simulation and PR 58's checker. `git merge-tree` of d54c37f91
    with trunk f3156a375 and each held PR gives the PR body's conflict
    table unchanged: context.h and import_ref.cpp merge cleanly with every
    one.

| Mutant | Named killer | Measured at round 3 of the focused re-review of the fold |
| --- | --- | --- |
| M23 (re-run) | fail_todo_import.carbon `_function_declaration` | killed: it aborts (``Missing case in TryResolveInstCanonical for instruction kind SpliceInst``) |
| M28 (re-run) | fail_todo_import.carbon `_class_field_type` | killed: it aborts (the same FATAL) |
| M29 (re-run) | fail_todo_import.carbon `_interface_declaration` | killed: it aborts (the same FATAL) |
| M43 (redefined: a class that an operand names adds its declaration only) | fail_todo_import.carbon `_nested_class_field_type` | killed: it aborts (generic.cpp:239's CHECK) |
| M44 (re-run) | none alone; M67 | survives: gate 1955 of 1955, the nine programs pass, none of the 110 probes changes |
| M45 (re-run) | fail_todo_import.carbon `_function_constrained_by_template_interface` | killed: it aborts (sem_ir/type.cpp:27's CHECK) |
| M46 (re-run) | fail_todo_import.carbon `_impl_constrained_by_template_interface` | killed: it aborts (generic.cpp:239's CHECK) |
| M47 (re-run) | fail_todo_import.carbon `_function_declaration_names_class_template` | killed: it aborts (sem_ir/type.cpp:27's CHECK) |
| M48 (re-run) | fail_todo_import.carbon `_function_definition_names_class_template` | killed: it aborts (generic.cpp:239's CHECK) |
| M49 (re-run) | fail_todo_import.carbon `_function_parameter_of_template_interface_type` | killed: it aborts (inst.h's cast CHECK) |
| M50 (redefined: no set of instructions or generics) | fail_todo_import.carbon | killed: it does not finish in 120 s |
| M51 (the walk follows no operand) | fail_todo_import.carbon `_class_method_declaration` | killed: it aborts (generic.cpp:239's CHECK) |
| M52 (no instruction's type) | none alone; M67 | survives, as M44 |
| M53 (no specific operand) | fail_todo_import.carbon `_function_declaration_names_class_template_in_class_argument` | killed: it aborts (sem_ir/type.cpp:27's CHECK) |
| M54 (no struct field type) | fail_todo_import.carbon `_function_declaration_names_class_template_in_struct` (ada45a7c6) | killed at ada45a7c6: it aborts (sem_ir/type.cpp:27's CHECK); at d54c37f91 the gate passed and three probes stopped the compiler |
| M55 (no block operand) | fail_todo_import.carbon `_function_declaration_names_class_template_in_tuple` | killed: it aborts (sem_ir/type.cpp:27's CHECK) |
| M56 (no impl operand) | none | survives: gate 1955 of 1955, the nine programs pass, none of the 110 probes changes |
| M57 (no facet type's specifics) | fail_todo_import.carbon `_function_constrained_by_interface_of_class_template` | killed: it aborts (sem_ir/type.cpp:27's CHECK) |
| M58 (`TryFinishSpecific` imports every definition) | fail_todo_import.carbon `_function_definition_calls_function_template_definition` | killed: it aborts (``Missing case in TryResolveInstCanonical for instruction kind InstValue``) |
| M59 (no specific's arguments) | fail_todo_import.carbon `_function_declaration_names_class_template_in_class_argument` | killed: it aborts (sem_ir/type.cpp:27's CHECK) |
| M60 (a function's specific adds its definition) | none | survives: the same TODO, for the caller; none of the 110 probes changes |
| M61 (a walk that reaches an action records what it reached) | fail_todo_import.carbon `_two_uses_name_class_template` (ada45a7c6) | killed at ada45a7c6: it aborts (sem_ir/type.cpp:27's CHECK); at d54c37f91 the gate passed and six probes stopped the compiler |
| M62 (no absolute instruction operand) | none | survives: gate 1955 of 1955, the nine programs pass, none of the 110 probes changes |
| M63 (no function operand) | fail_todo_import.carbon `_class_method_declaration` | killed: it aborts (generic.cpp:239's CHECK) |
| M64 (no interface or named-constraint operand) | none | survives, as M62 |
| M65 (no specific interface operand) | none | survives, as M62 |
| M66 (no facet type's constraint types or rewrites) | fail_todo_import.carbon `_function_constrained_by_rewrite_to_class_template` (ada45a7c6) | killed at ada45a7c6: it aborts (sem_ir/type.cpp:27's CHECK); at d54c37f91 the gate passed and two probes stopped the compiler |
| M67 (M44 and M52) | fail_todo_import.carbon `_function_constrained_by_template_interface` | killed: it aborts (sem_ir/type.cpp:27's CHECK) |

## Hand-off notes for the implementer

Amended 2026-10-14 (review fold: B-m6 / B-B2 / A-B1).

-   Start from `$Y/v14.diff` (`$Y` is
    `/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1/fixer2`;
    amended 2026-10-14, review fold: RR-M1): it applies to trunk b2576f6c3 with
    no offsets and is `$X/v13.diff` (`$X` is
    `/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1-fixer`)
    plus A7 (D-TP-24): C1, C2, C3's call.cpp part, C4 and C5's lookup (with a
    `context.TODO` where the diagnostic belongs). `$P/tp1-proto-v8.diff` is rev
    1's and has the RC-5 defect.
-   Relink-measure C1 first: v14's numbers (gate 1935 of 1942 with seven
    refills, the same as v13's; conformance 128/0/22; `$Y/mx/v14/v14.txt` and
    `$X/matrix-table.tsv`) are the baseline; any difference is a finding.
    The per-commit red sets are §0.8's.
-   Commit identity for every commit: `--author="jmann345
    <jerrymannstan@gmail.com>"` with `GIT_COMMITTER_NAME=Claude
    GIT_COMMITTER_EMAIL=noreply@anthropic.com`, the message ending, after a
    blank line, with the session's attribution trailers. Stage by explicit
    path only, never `git add -A` (R20); never edit goldens by hand or write
    CHECK lines; never touch .github/.
-   M comes before the implementation reviews and resolves conflicts only (§3,
    §0.9); S then adds C5's structural-requirement rule, and F6 renames and
    refills PR 51's split (amended 2026-10-14, review fold: RR-m2). In the held
    state M merges trunk's records only and S, F6 and L are measured, then
    committed at land time (§1.12 "Held state"; (amended 2026-10-14,
    implementation-review fold: IR2-MINOR-10)).
-   Run the id re-scan of the front matter before L and again before D, and
    record both outcomes in D (amended 2026-10-14, review fold: RR-m4).
-   `Core.Range(n)` yields 0 to n-1; X28's fixture has no call, the program
    and the new fixture text add one.
-   PR 58's checker runs on a scratch copy before PR 58 merges
    (`$X/sim/l/apply_l.py <root> <date>`); its fixtures are read from
    `/home/user/carbon-dd` and never edited there.
-   Every new diagnostic needs a `fail_` split (§2.7); the
    `TemplateMemberLookupAmbiguous` text is hand-predicted and its fill is
    the arbiter of its exact rendering, which Appendix C's X21 quote then
    follows.
-   Keep goldens and programs off constant nested aggregates (W-263),
    in-place `for` cursors and class values with a defaulted field (W-264,
    W-265), and RC-10's by-copy aggregates with an in-place element, which
    stop the compiler or print values that change from run to run (W-256;
    amended 2026-10-14, review fold: RR-M1 / RR-M2).

## Review fold record (rev 2, 2026-10-14)

Rev 1 (6245f8687) had two independent reviews under R29(c). Review A covered
root causes and design soundness, and review B covered concreteness, process,
Goodhart, scope honesty and cross-workstream effects. Both returned REJECT,
with 27 findings: A-B1, A-M1 to A-M4, A-m1 to A-m8, B-B1, B-B2, B-M1 to B-M6
and B-m1 to B-m6. A separate fixer (R11) folded them into rev 2. For each
finding the fixer opened the cited location and reproduced the finding on its
own relinked prototypes under `/dev/shm/tp1-fixer` (deleted when done), with
the scripts, logs and sources in `$X`. All 27 are folded and none is rejected
whole. One sub-item is rejected with evidence (R17): B-B1's item 5 asks for a
cross-library fixture, and §2.9 shows that none can exist. Rev 2's prototype
is v13 (`$X/v13.diff`, 14 files, +513/-37). It runs every crash form the
reviews named except the four that are measured and filed (W-255, W-256,
W-263, W-264). Its gate is 1935 of 1942 with the seven refills of §4, and its
conformance is 128/0/22. "Front matter" below means the Status, Outcome and
Id allocation paragraphs.

-   **A-B1** (BLOCKER) Folded. Reproduced: v8 stops the compiler on b09, b09b,
    b09e, c1, c3, c4 and c5 (nested aggregates built from template calls).
    Rev 1's shared storage access block takes instructions that the template
    body still uses. D-TP-3 is rewritten: the action carries a copy of its
    storage access chain (`CloneStorageAccessChain`, §2.1), each specific
    places the copy, the body keeps the originals, and pending roots, such as
    the `for` cursor's `VarStorage`, are inserted at the action. RC-5 is
    restated. D-TP-16 is restated: 4a8993af2's representation is used for the
    copy, and the reason that holds against its shared block is the nested
    literals, not the cleanup, which a one-line guard removes. W-258 is
    restated with it. v13 runs
    b09, b09b, b09e, c1, c3, c4, c5, X28 to X33, PR-AK, s11, s15, s22, s30 and
    s34. They are splits of generic/template/initialize.carbon, with lower
    splits. The forms left are measured and filed: n01 and n02 (W-264), s32
    (W-256) and b04 and h03 (W-263). C1 grows and is never shrunk. Changed:
    front matter, §0.2, §0.3, §0.6, §0.7, §0.8, §1.1, §1.2, §1.14, §2.1, §2.7,
    §4, §7.1, §7.2 and the hand-off notes.
-   **A-M1** (MAJOR) Folded. Reproduced: a09 (a field and a constraint method
    with the same name) prints `2 9` on v8. `SameMemberEntity` now compares
    the two lookup results before instance binding. Function and non-function
    results are distinct, and a non-function result must be the same constant.
    Added `fail_field_vs_constraint_method` and the design page's RoundWidget
    and SquareWidget examples to constraint_lookup.carbon. Mutant M15 (rev 1's
    comparison restored) was run, and a09 is accepted again, which kills it.
    Changed: §0.8, §1.5, §1.14, §2.5, §2.7, §4 and §8.
-   **A-M2** (MAJOR) Folded through the second option. TR-8 is PARTIAL. The
    definition-time half of simple member access is filed as W-260, its
    ambiguity as W-261, and the type-level `T.F` comparison as W-262, all from
    the spares. The Outcome, the row residue and the page's limits name them.
    Changed: front matter, §1.1, §1.5, §1.8, §1.13, §1.14, §2.9 and Appendix
    C.
-   **A-M3** (MAJOR) Folded. Reproduced: f01, the same crash with `generic`
    form parameters. D-TP-15 is dropped and kept as rejected alternative
    §7.2(10). RC-9 and W-255 are restated as "lowering of form-parameter
    pattern splices, `template` or `generic`", with f01 and f02 as evidence.
    The TR-18 "diagnosed" claim and the row text's "diagnosed" are removed.
    Changed: front matter, §0.3, §1.1, §1.2, §1.8, §1.13, §2.2 and §7.2.
-   **A-M4** (MAJOR) Folded. D-TP-12 is rewritten. It now applies to a query
    whose self, or an argument of its interface's specific, names a template
    binding (`NamesTemplateBinding`, §2.4), with proposal 2200 :198-199 as the
    justification. A checked generic's `TemplateInst` or `eval fn` result
    keeps today's lookup. The interface-side pin is
    `template_interface_concrete_self` in default_init.carbon. The checked
    generic with a C++ template self is pinned by the existing
    interop/cpp/template/generic_call.carbon, which no longer changes. Mutant
    M17 drops the interface test. §7.1(2)'s falsifier names both goldens.
    Changed: §0.8, §1.7, §1.9, §1.14, §2.4, §4, §7.1 and §7.2.
-   **A-m1** (MINOR) Folded. Reproduced: M3 cannot be killed by rev 1's named
    test. e01 (a struct conversion) reaches A2 and is in §0.3 as RC-11. It is
    initialize.carbon `return_struct_convert`, with a lower split, and M3's
    killer (measured: segfault). Changed: §0.3, §0.6, §1.2, §2.1, §2.7 and §8.
-   **A-m2** (MINOR) Folded. W-254 is narrowed to token-identical dependent
    redeclarations. Stringifying actions and splices in diagnostics was
    measured as small and is done in C2 (D-TP-23, §2.2). With it,
    member_out_of_line.carbon `fail_todo_basic` becomes `fail_basic`, because
    its two declarations differ (p3763) and only the text was wrong. D-TP-18
    is restated. Changed: front matter, §0.8, §1.1, §1.2, §1.8, §1.9, §1.13,
    §1.14, §2.2 and §4.
-   **A-m3** (MINOR) Folded. Reproduced: a constant nested `let` fails LLVM
    verification, with or without a template. Filed as W-263 (RC-13). TP-1's
    goldens and programs use runtime values for nested aggregates, and §0.6
    says so. Changed: front matter, §0.3, §0.6, §1.8 and §1.13.
-   **A-m4** (MINOR) Folded. D-TP-14 is rewritten. The `semantics TODO` is
    reported once, at the `import`'s location, for any generic whose definition
    is resolved per instantiation, and its cascaded error is suppressed. A
    class-template split, `fail_todo_import_class.carbon`, is added. Changed:
    front matter, §0.8, §1.1, §1.2, §1.14, §2.2 and §4.
-   **A-m5** (MINOR) Folded. §0.9 now covers the hand-predicted C3 and C5
    files against SC-1, VA-1 and PR 57, hunk by hunk. It records every
    branch's head as of 2026-10-14 (SC-1 b3bb7bf31, with the same toolchain as
    9197882e5). Changed: §0.9.
-   **A-m6** (MINOR) Folded. The program is named
    `templates_return_aggregates_diff`. F6 and P regenerate the README table
    with `runner.py --update-readme-table` and check it with `--self-test`
    (measured: eight rows added, self-test OK over 158 programs). Changed:
    §1.10, §1.14, §2.6 and Appendix B.
-   **A-m7** (MINOR) Folded. C3's actions are created only for an opaque
    template-dependent operand type (§1.3 lists the conditions). Added
    index.carbon `index_class_with_index_with`, a `Vec(T)` with an
    `IndexWith` impl whose SemIR must not change. Changed: §0.5, §1.3, §1.14,
    §2.3, §2.7 and Appendix D.
-   **A-m8** (MINOR) Folded. The call.carbon wrong-type split moves to
    call_wrong_arg_type.carbon under min_prelude/convert.carbon, which pins
    the real conversion failure. The two counts are corrected: 36 upstream
    commits under check, lower and sem_ir, and 80 refs matching the id scan's
    patterns (78 after B-m1's exclusion). Changed: front matter, §0.7, §1.9,
    §2.7 and §4.
-   **B-B1** (BLOCKER) Folded, except item 5 in part. The L texts are written
    in full (Appendix C): the page diff, nineteen rewritten fixtures with
    unique QUOTEs, three new fixtures (X34, X35, X36) and the SAMPLES diff.
    The dated notes are on the Status paragraph and both sketch notes. X21's
    error and note are in the W-183 bullet. R09 is decided as a page block
    that runs and expects `25`. The s32 form is listed as a form that still
    stops the compiler. They were simulated with PR 58's checker
    (fcee90d9b): 0 errors without the toolchain, and with v13 the six
    expected C3 errors that commit C3 removes. L has a document review. Item 5
    is partly rejected: the cross-library bullet is rewritten to the
    `semantics TODO`, but no fixture can pin it, because `run_fixture`
    compiles one file alone (check_samples.py:1100-1110). The golden
    fail_todo_import.carbon pins it instead. Changed: §1.14, §2.9 and Appendix
    C.
-   **B-B2** (BLOCKER) Folded. The commits are reordered as: C1 to C5 with
    their fills, P, M with F6, the implementation reviews on the merged head,
    the fix commits, L with its document review, R with the merged row text,
    and D last. D quotes the merged runs, discharges W-127, W-183, W-192 and
    W-193, and re-scans the ids. §0.9 says how each records file merges at M.
    Changed: §1.11, §1.12, §1.14, §2.8, §3, the hand-off notes and Appendix
    E.
-   **B-M1** (MAJOR) Folded. All golden sources are given verbatim (Appendix
    A), and so are the eight programs with their headers (Appendix B). C3's
    code and C5's hand-predicted parts are marked as such (Appendix D), and v8's
    `LookupMemberInTemplateConstraint` is quoted verbatim (§2.5). The fifteen
    ledger items W-250 to W-264 are written in full, with the decision-log
    entry and its veto digest (Appendix E). Changed: §1.9, §1.10, §1.13, §2.3,
    §2.5 to §2.8 and Appendices A, B, D and E.
-   **B-M2** (MAJOR) Folded. §0.1 says the lower-fatal clause is not met.
    Outcome (a) names s32, and W-256 is filed under this bullet as a
    template-reachable crash, named in the row residue and on the page.
    D-TP-18's break condition re-grades the row against
    gap-analysis.md:12-13 when W-250, W-254, W-255, W-259 and W-264 are
    closed, and never on the arbiter alone. W-014 stays open. Changed: front
    matter, §0.1, §0.3, §1.8, §1.13, §1.14, §2.8, §2.9 and Appendices C and E.
-   **B-M3** (MAJOR) Folded. operator.carbon `todo_fail_assign_const` and
    `todo_fail_assign_let` are audited in the new §0.11 and measured on v13
    (still accepted). They are filed as W-259 (an assignment action is
    outside the slice) and named in the row residue and the page's limits.
    Changed: §0.1, §0.11, §1.1, §1.8, §1.13, §2.9 and Appendix C.
-   **B-M4** (MAJOR) Folded. A2's input is e01 (see A-m1), and M3 names it.
    s16 and s35 are fixed and run. The destructor test is
    `var_with_destructor` (b02), a check split and a lower split.
    templates_dependent_var prints from `destroy`. Mutant M16 keeps the early
    exit for a `VarStorage`, and both tests kill it (measured on n04 and b02).
    Changed: §0.3, §0.6, §1.2, §1.10, §2.1, §2.6, §2.7, §8 and Appendix B.
-   **B-M5** (MAJOR) Folded. Root cause of the period_self change: eval.cpp
    :3075-3090 forces `TemplateOnly` results (`TemplateInst`, `eval fn`) to
    template dependence inside checked generics. D-TP-12 is narrowed to
    template bindings (see A-M4). Measured on v12 and v13:
    facet/period_self.carbon and generic_call.carbon no longer change. The
    break condition and §7.1(2) name both as falsifiers. Changed: §0.8, §1.7,
    §1.9, §1.14, §2.4, §4, §7.1 and §7.2.
-   **B-M6** (MAJOR) Folded. The v13 patch was dry-run against SC-1, VA-1, OP-2,
    UA-2 and DD-1 at their 2026-10-14 heads, and the hand-predicted hunks were
    compared. v13 was composed over SC-1 and over VA-1, then relinked and gated.
    scv13 is 1943 of 1959, because nine SC-1 template constraint goldens break.
    With the composition rule (`GetStructuralRequirementRef` defers to the type,
    D-TP-13) scv13b is 1952 of 1959 and vav13 is 1953 of 1960, and the failures
    are TP-1's own seven refills. R09 and X21 give v13's results over both
    compositions (R09 prints `25`, X21 is rejected). The dry run is repeated at
    M. Changed: §0.9, §1.5, §1.14 and §2.5.
-   **B-m1** (MINOR) Folded. The three re-scan commands exclude this
    workstream's own two refs (`grep -v 'claude/carbon-fork-0-1-tp$'`), and
    the expected output is recorded. Re-run on 2026-10-14 over 78 refs: W-244,
    W-245 and W-249, and nothing for W-250 to W-269 or F-019. Changed: front
    matter.
-   **B-m2** (MINOR) Folded. Corrected: the v8 patch has 12 files, not 13;
    s32 is RC-10's kind, not RC-1's; inst_kind.def is alphabetical, in ASCII
    order with the positions given, not append-only; and
    lower/template/class.carbon's refill belongs to C4. The per-commit
    attribution is now measured on the cumulative variants vc1, vc12, vc123
    and vc1234. W-183's discharge keeps the page's limit text with a dated
    note, as §2.9 does. §1.11 and Appendix E say which commit writes each
    record: the discharges are written in D, and the page notes in L.
    Changed: §0.6, §0.8, §1.2, §1.6, §1.11, §2.3, §6 and Appendix E.
-   **B-m3** (MINOR) Folded with A-m6. The names are
    templates_return_aggregates_diff.carbon and
    templates_return_aggregates_diff.diff.cpp, in the mode `differential`.
    Changed: §1.10, §1.14, §2.6 and Appendix B.
-   **B-m4** (MINOR) Folded with A-m8. The split is under
    min_prelude/convert.carbon and pins the real `ImplicitAs` error. Changed:
    §1.9, §2.7 and §4.
-   **B-m5** (MINOR) Folded. The second program line uses `Core.Range(5)` and
    prints `10`. Each PR-AJ form is measured on v13 (§1.6). Under the shrink,
    W-192 stays open with X18 recorded as fixed. W-183's break condition
    follows the dated-note policy. Changed: §1.6, §1.10, §2.6, §2.8, §3 and
    Appendices B and E.
-   **B-m6** (MINOR) Folded. Script paths are absolute, the commit identity
    and the staging rule (explicit paths, R20) are stated, PR 51's split
    rename is assigned to F6, and the import TODO is reported at the
    `import`'s location (A-m4). Changed: front matter, §1.2, §1.14, §2.2, §8
    and the hand-off notes.

### Focused re-review of rev 2, folded into rev 3 (2026-10-14)

The focused re-review of rev 2 (1b26e8c32) under R29(c) returned
APPROVE-WITH-AMENDMENTS. It found the three rev 1 BLOCKERs resolved (A-B1,
B-B1, B-B2) and re-measured each one independently:

-   v13 rebuilt byte-identically, with every listed counterexample and the
    re-review's own stress probes printing the values of the same code
    without templates;
-   the gate 1935 of 1942, and mutant M2 killed;
-   Appendix C simulated with its own extractor: 0 errors without a
    toolchain, and with v13 the six C3 errors only;
-   the id re-scan clean.

It raised six new findings, two MAJOR and four MINOR, none a BLOCKER. A
second fixer (R11) folded all six into rev 3, and none is rejected. Each was
reproduced on a rebuilt v13 under `/dev/shm/tp1-fixer2` (deleted when done),
with the scripts, logs, sources and probes in `$Y`.

-   **RR-M1** (MAJOR) Folded, with the fix the finding proposed.
    Reproduced: on the rebuilt v13, r2, r4, r8 and r9 fail the SemIR
    verifier (`Built invalid semantics IR ... is not dominated`), while r2n
    and r8n run, and trunk and the nightly crash on all four. Rev 3 found
    more of the family: class values in a tuple value, an array value and
    an argument (t01, t03, t04, t11) and a union value (t10). It also listed
    every pending root that check creates (convert.cpp:471, :1084, :1203;
    handle_loop_statement.cpp:229; pattern_match.cpp:1740, measured
    unaffected). RC-12 is restated with them. The measurement the finding
    asked for was made. v14 defers a template-dependent array, union or
    class value conversion whole (D-TP-24, A7, `$Y/v14.diff`), and r2, r4,
    r8, r9, n02, t01, t03, t04, t10 and t11 run with the values of the same
    code without templates. The gate's failure output is byte-identical to
    v13's, conformance is 128/0/22, every other new golden autoupdates
    identically, and no other probe of the 235 changes. A first draft that
    deferred every class value moved an unexpected field's error to
    instantiation (t13) and lost it in an uncalled template, so a class
    value is deferred only when its source names exactly the class's fields
    (§7.2(12), mutant M20). The fix is kept in C1, with three new splits in
    check initialize.carbon, one in lower initialize.carbon and mutant M19.
    W-264 narrows to the `for` cursor (n01, X35) and a class value whose
    literal leaves a field to its default (t02). That form also showed that
    a runtime field default stops the compiler without templates, filed as
    W-265. The page bullet is rewritten with the right stages, lowering for
    the loop and checking for the class value, and its array value clause
    is gone because n02 runs. The class values need no crash fixture,
    because they run; X35 still pins the loop. Changed: front matter, §0.3,
    §0.6, §0.8, §1.1, §1.2, §1.8, §1.10, §1.11, §1.13, §1.14, §2.1, §2.7,
    §2.8, §2.9, §4, §6, §7.1, §7.2, §8, the hand-off notes and Appendices A,
    C and E.
-   **RR-M2** (MAJOR) Folded. Reproduced: q07c prints values that change
    from run to run on v13 and v14, and trunk and the nightly segfault on
    it; q07cn prints such values on trunk and the nightly. The family is
    wider without templates: k02, k04 and k05 are compiled wrongly; k03, k08
    and q07en stop at RC-10's CHECK; k06 stops in lowering; k01 and k07 run.
    RC-10 is restated: TP-1 removes RC-1's crash, and the template then
    behaves as the same code without a template, which RC-10 compiles
    wrongly. D-TP-1 states why the trade is accepted for this form. A
    diagnosis was measured as variant g and rejected, because it also
    rejects k01 and k07, which run, and it changes
    tuple/class_tuples.carbon (§7.2(11)). W-256 records the miscompile with
    and without templates. Outcome (a), the row residue and the page name
    it: a new bullet under "Stopping the compiler, or compiled wrongly",
    and notes in the resolved returning bullet and the intro note. No golden
    or program uses the form, and no fixture can pin it, as with PR-AK.
    Changed: front matter, §0.3, §1.1, §1.8, §1.10, §1.13, §1.14, §2.8,
    §2.9, §7.2, the hand-off notes and Appendices C and E.
-   **RR-m1** (MINOR) Folded. §1.13 item 9 drops the cleanup clause, and
    §7.2(3) gives the nested literals as the reason; the `pending_block.h:89`
    CHECK is named only as one that a guard removes. Changed: §1.13 and
    §7.2.
-   **RR-m2** (MINOR) Folded. M resolves conflicts only: SC-1's
    `PerformAction` hunks keep both sides' statements and add none. C5's
    structural-requirement rule is the separate commit S right after M, F6
    follows S, and M18 reverts S. Changed: front matter, §0.9, §1.12, §1.14,
    §2.5, §3, §6, §7.1, §8 and the hand-off notes.
-   **RR-m3** (MINOR) Folded. §2.8 gives R's full row, composed over PR 58's
    row (fcee90d9b, fork/gap-analysis.md:60), which supersedes PR 51's in the
    merge order. It keeps DD-1's text verbatim, with its three dated
    parentheticals, and appends one dated TP-1 sentence. That sentence
    lists which of DD-1's limits TP-1 resolves, among them the `for` loop
    that stopped the compiler where the function is defined, then what TP-1
    adds and the residue. §2.8 also states the rule for a merged row that
    differs from PR 58's. Changed: §2.8 and §3.
-   **RR-m4** (MINOR) Folded. The id paragraph names L, R and D as the
    commits that publish ids. The three commands run before L and before D,
    and D records both outcomes; a collision found before D also rewrites
    L's and R's texts in a commit before D. The commands were re-run for
    rev 3 with the same output: W-244, W-245 and W-249, and nothing in
    W-250..W-269 or F-019. Changed: front matter, §3, the hand-off notes and
    Appendix E.

## Implementation review fold record (2026-10-14)

Two implementation reviews (R29(c)) reviewed the branch head 4e1f07a91 (trunk
8bfd78ae3's records merged) and the state-T measurements: review 1 (IR1,
adversarial correctness, scratch `$I/rev1`) returned REJECT with seven findings,
one BLOCKER, three MAJOR and three MINOR; review 2 (IR2, strictness and
records, scratch `$I/rev2`) returned APPROVE-WITH-FIXES with thirteen, two
MAJOR and eleven MINOR. A separate fixer (R11) reproduced every finding on the
installed toolchain before changing anything (`$I/fixer/probe`), folded them in
three fix commits within §3's budget, two for the toolchain, each with its
fill, and one for these records, and used no shrink. IR1-m1 and IR2-MAJOR-1 are
one finding (M17's killer). No finding is rejected; one is narrowed and filed
with a pin (IR1-M3), with the reason in its row.

Commits: 7c7b1b170 "TP-1 fix: a constant element of a template-dependent
initializer gets its storage" and its fill 17501c978; 12bd6d67a "TP-1 fix:
dependent array bounds and imported template signatures are diagnosed; const
and produced types are opaque" and its fill f360b8735; and the records commit
that adds this section. Each fix commit was gated alone (red exactly on the
goldens it adds splits to or refills, no crash), then with its fill at the
autoupdate fixpoint (a second pass changed nothing): fix 1 alone 1952 of 1955
(check and lower initialize.carbon, lower/template/merging.carbon), with its
fill 1955 of 1955; fix 2 alone 1950 of 1955 (default_init, pointer, index,
fail_todo_import and constraint_lookup under generic/template), with its fill
1955 of 1955. The fold adds splits, not files, so the file count stays 1955.

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| IR1-B1: a constant element beside a template-dependent one (`return (x, 1);`, `{.a = x, .b = 2}`, `array(T, 2)` from `(x, 3)`, `var`, assignment, nesting, a template value, `P(T)`) stops lowering at function_context.cpp:223; r04 and m26 ran on trunk | BLOCKER | Fixed in 7c7b1b170 (D-TP-25): a constant splice lowers the instructions of its block that are not constant, so the copied storage chain exists when the constant is stored. Reproduced on all ten named probes; every m probe of the review and every r probe but r06 and r16 now runs with its hand value (m01 101, m26 41, r04 6, r12 41); r06 and r16 copy a class without `Copy` and are rejected, as without a template. Nine check and lower splits of initialize.carbon and the program templates_constant_elements; mutant M21 (the call removed) aborts lower initialize.carbon and the program's compile. lower/template/merging.carbon refills to its non-template twin's IR (the `{}` temporaries' `alloca`). | §0.8, §1.2 D-TP-25, §1.10, §2.7, §4, §5, §8, Appendices A and B |
| IR1-M1: an `IndexAction` result as an array bound turns trunk's error into a FATAL (`InitForm`/`PatternType` "should always be constant"); a `CallAction` there was a FATAL on trunk | MAJOR | Fixed in 12bd6d67a (D-TP-26): in a specific, an array type whose bound is not a constant reports ``expression is runtime; expected constant`` at the bound and is an error. j13, j14 and the trunk-only j15 are errors now. index.carbon `fail_index_in_array_bound_on_instantiation`; mutant M22 restores the FATAL. Not total (amended 2026-10-15, focused re-review of the fold: RR1-B1): the same class reached the FATAL for every type position but an array bound, and `(x.0, i32)` passed checking; completed in 632f92117 and ba64734e7, by the record below | §1.2 D-TP-26, §1.8, §2.7, §4, §8 |
| IR1-M2: a cross-library template whose signature holds an action still reaches `TryResolveInstCanonical`'s FATAL, contrary to D-TP-14 | MAJOR | Fixed in 12bd6d67a: a function or class template whose declaration holds an action reports W-250's TODO when it is first resolved and resolves to an error (`IsDeclResolvedPerInstantiation`; the imports of its function type and generic class type pass the error on). main_declaction and a class form report the TODO alone; an imported impl with such a declaration is rejected in its own library, so it cannot reach the import. D-TP-14's "unreachable" claim and its break condition (an `export` resolves the entity, the review's libd) are rewritten. Two `_declaration` splits in fail_todo_import.carbon; mutant M23 restores the FATAL. Not total (amended 2026-10-15, focused re-review of the fold: RR1-M1 / RR2-M1): a class template whose field type or method declaration holds an action, and an interface or named constraint whose declaration holds one, still stopped the compiler, and the "unreachable" claim was false; completed in d8f6ab60a, by the record below | §1.2 D-TP-14, §1.8, §2.7, §4, Appendix E W-250 |
| IR1-M3: W-183 is discharged although constraint lookup does not apply through a field of a template class or of `Holder(T)` | MAJOR | Narrowed and filed: TR-8's IN wording and W-183's discharge now say "an operand whose type in the definition is the parameter", and W-266 (from the spare ids) records the field form, pinned by constraint_lookup.carbon `fail_todo_field_of_template_class` (f13's shape; trunk the same). Implementing it needs the declared type of the field a deferred access names, an extension of C5, which is first on the shrink line, so no fix commit widens it (R17) | Outcome (d), §1.8, §1.13, §2.8, Appendix E |
| IR1-m1 = IR2-MAJOR-1: M17 survives because `template_interface_concrete_self` makes no lookup | MINOR, MAJOR | Fixed in 12bd6d67a: default_init.carbon `template_interface_facet_value` (IR2's p7: no STDERR, an error under M17) and `template_interface_final_impl` (IR1's k13 and IR2's p6: `lookup_impl_witness ... [template]` in the definition); M17 is killed by default_init.carbon | §1.7, §2.7, §4, §8 |
| IR1-m2: diagnostics print `<cannot stringify ...>` for the four C3 action kinds and `CallAction` | MINOR | Fixed in 12bd6d67a: `StringifyInst` for `AddrOfAction`, `CallAction`, `CompoundMemberAccessAction` (found while folding m3: `T.(Container.Elem)` printed the same way), `IndexAction`, `PointerDereferenceAction` and `TupleIndexAction`; j06 and j07 print `array(i32, v.0)` and `C(*p)`. index.carbon `fail_redecl_differs_in_dependent_operation`; mutant M24. Precedence, interface members and goldens for three of the six kinds added in 73b3124dd (amended 2026-10-15, focused re-review of the fold: RR1-m1 / RR2-m6) | §1.2 D-TP-23 |
| IR1-m3: `IsOpaqueTemplateDependentType` misses `const T` and `T.Elem` | MINOR | Fixed in 12bd6d67a: the predicate unqualifies, and includes a `SpliceInst` type, which is what `T.Elem` is for a template `T` (an `AccessMemberAction`'s splice; measured, not an `ImplWitnessAccess`). i16 and i18 compile; on instantiation `p.1` for `p: const (i32, i32)` is rejected as the same code without a template is on trunk (`$I/fixer/p/constnt.carbon`), so the eager paths keep upstream's behavior and are not unqualified (one rule). pointer.carbon `deref_const_param`, index.carbon `fail_tuple_index_const_param_on_instantiation` and `tuple_index_associated_type`; mutant M25 | §1.3, D-TP-9, §2.7, §4 |
| IR2-MAJOR-2: R and D cannot be written as specified in the held state | MAJOR | Fixed in the records: §2.8's held-state row over trunk's line-54 text and its land-time recomposition, §3 items 7, 12 and 13, and Appendix E's held-state texts (W-014's notes with the held measurements, W-250 to W-266 after W-125, the decision log's place, a TP-1 Branches row, the Next actions of the land time, the discharges moved after the repeated M, and the conflict rule that keeps TP-1's appended blocks after the PRs') | §2.8, §3, Appendix E |
| IR2-MINOR-1: Appendix E's decision-log placement | MINOR | Fixed: immediately above OX-1's entry (decision-log.md:2863 at 8bfd78ae3), re-anchored at land time | Appendix E |
| IR2-MINOR-2: four tree departures from the plan's code text | MINOR | Fixed: dated notes adopt the tree's text for `MakeIntType`'s location and `LiteralSubscriptTargetType`, the three-argument helper and the factored lookup (§2.5's block updated), kind.def's "Name lookup" group, and typed_insts.h's alphabetical order | §2.5, Appendix D |
| IR2-MINOR-3: the moved-splits amendment is partial; §0.8's C4 set omits convert.carbon | MINOR | Fixed: §0.8's C4 set is convert, destroy_calls and lower/template/class; §2.7, §3 items 3 and 4, and the Appendix A headings say the two splits are C4's | §0.8, §2.7, §3, Appendix A |
| IR2-MINOR-4: C2's message publishes W-250 before the re-scan | MINOR | Fixed in the records: the id paragraph names 637e3efaf and the fold's own 12bd6d67a, which also names W-250, so a re-allocation is recorded against both in D's landed notes; later messages describe residues | front matter |
| IR2-MINOR-5: no re-cite rule for R | MINOR | Fixed: §2.8 has R re-cite every file:line to its tree; the row cites lower/handle.cpp:524 | §2.8 |
| IR2-MINOR-6: "first arbiter clause met" omits TP-1's own `fail_todo` splits | MINOR | Fixed: Outcome (e), D-TP-18, the row and W-014's notes say the four splits present when W-014 was filed flip, and TP-1's five pin W-250 (four) and W-266 (one) | front matter, §1.14, §2.8, Appendix E |
| IR2-MINOR-7: the clang-tidy run dropped `modernize-*` without a reason | MINOR | Fixed: `modernize-use-trailing-return-type` alone makes clang-tidy 21.1.8 stop every file at a location-less ``missing '(' after '__has_feature'`` (measured: of eight modernize checks tried on aggregate.cpp it is the only one); the fold's runs exclude only that check, and the re-run over all of TP-1's changed lines is in §8 | §8 |
| IR2-MINOR-8: no split for the instantiation-time `->` and `&` errors | MINOR | Fixed in 12bd6d67a: pointer.carbon `fail_arrow_non_pointer_on_instantiation` and `fail_addr_of_value_on_instantiation` | §2.7, §4 |
| IR2-MINOR-9: `SameMemberEntity`'s comment says it returns an entity | MINOR | Fixed in 12bd6d67a and §2.5 | §2.5 |
| IR2-MINOR-10: the held-state amendment does not reach §1.14, the front matter, the hand-off notes or §3's commit list | MINOR | Fixed: pointers in the Status line, Outcome (h), D-TP-19, D-TP-22 and the hand-off notes; §1.12 and §3 name 4e1f07a91 and the fold's commits | front matter, §1.12, §1.14, §3, hand-off notes |
| IR2-MINOR-11: program headers name W-127, W-183 and W-193 | MINOR | Fixed in the records commit: the three headers and Appendix B drop the "fork work item W-nnn" clauses; DD-1's fixture names stay, and D's landed notes record that they resolve when PR 58 lands | Appendix B, Appendix E |

Measured at the fold's head (§8 "Measured at the implementation-review
fold", §0.9 "Composition at the implementation-review fold", §2.9): gate 1955
of 1955 files; conformance 137/0/22 over 159, 48 of 56 bullets PASS; all
twenty-five mutants killed, M18 over SC-1; no clang-tidy diagnostic on TP-1's
changed lines; PR 58's checker reports 0 errors with and without the
toolchain on both simulated roots; and both compositions pass every golden of
their composed trees. Not run, as §8 item 8 says: hosted CI, Bazel and its
tests, ASan, macOS and Windows, LLVM with assertions and the owner's runner;
and the land-time items (M with the PRs, S, F6, L with its document review,
the id re-scans, R and D), which follow this fold.

## Sign-off

Rev 3 is signed off for implementation (2026-10-14). The last review's
verdict is APPROVE-WITH-AMENDMENTS, and every amendment is folded above.

| Review | Of | Verdict | Findings | Folded in |
| --- | --- | --- | --- | --- |
| A (architecture and design fidelity) | rev 1 (6245f8687) | REJECT | 13: A-B1; A-M1 to A-M4; A-m1 to A-m8 | rev 2 (1b26e8c32) |
| B (concreteness, process and cross-workstream) | rev 1 (6245f8687) | REJECT | 14: B-B1, B-B2; B-M1 to B-M6; B-m1 to B-m6 | rev 2 (1b26e8c32) |
| Focused re-review | rev 2 (1b26e8c32) | APPROVE-WITH-AMENDMENTS | 6: RR-M1, RR-M2; RR-m1 to RR-m4 | rev 3 |

In all, 33 findings: 3 BLOCKER, 12 MAJOR and 18 MINOR. All are folded and
none is rejected whole; B-B1's item 5 is rejected in part, with evidence
(§2.9). Implementation starts from `$Y/v14.diff` (hand-off notes), and the
implementation reviews of R29(c) run on the merged head (§3).

## Landed notes (TP-1, 2026-10-14)

Written by the discharge commit D, "TP-1 discharge", after the row commit R
(35e2240b5, "TP-1: row"). Both are dated 2026-10-14, the date of every TP-1
record, and were committed at 2026-10-15 UTC. In the held state (§1.12) there is
no merged tree, so these notes record the branch head's runs, the measurements
on composed copies and every land-time item; the land-time records commit (§3
item 13, "Held state") adds the merged tree's runs here and the outcomes of its
two id re-scans.

-   **What D writes** (Appendix E's held-state texts, §2.8, §3 item 13): W-014's
    notes appended in fork/inventory/work-items.json, with the third arbiter
    clause and the next slice named beside Appendix E's text and its last
    sentence in the held-state form; W-250 to W-266 appended after W-125 in id
    order, W-267 to W-269 unused and never reused; the decision-log entry "TP-1:
    integrated templates (2026-10-14)" immediately above "OX-1 parked: operator
    export to C++ cannot be made invisible to Carbon's own resolution
    (2026-10-14)", with D-TP-1 to D-TP-26 verbatim from §1.14; in
    fork/ORCHESTRATION.md a dated TP-1 paragraph after PR 59's, a Branches row
    after VA-1's, the expected scoreboard after the Scoreboard history, and Next
    actions item 5 with the land-time commits in order; and these notes. R wrote
    §2.8's held-state row over trunk's line 54, with the container run of the
    next item quoted as EXPECTED, not of record.
-   **Id re-scan before D** (the front matter's three commands, run from
    /home/user/carbon-lang on 2026-10-15, about 00:54 UTC, after `git fetch
    origin`; origin/trunk is 8bfd78ae3): 80 refs match the patterns and 78
    remain after TP-1's two are excluded; the first command printed `W-244`,
    `W-245` and `W-249`, and the second and third printed nothing. That is the
    expected output, so no id is re-allocated, W-250 stands in the messages of
    637e3efaf and 12bd6d67a, and F-019 stays unallocated. The re-scan before L
    did not run, because L is a land-time commit; it and the second re-scan are
    land-time items below.
-   **Measured at D, on the branch head 824f29c4e** (the install
    0.0.0-0.dev+12bd6d67a, whose toolchain sources equal the head's; R and D
    change records only). Gate: "file_test test mode on /home/user/carbon-tp:
    1955 passed, 0 failed (exit 0, 31s)", its log "Ran 1955 tests in 29928 ms
    wall time, 116020 ms across threads" with 0 `!` and 0 `?` marks.
    Conformance, with a private `XDG_CACHE_HOME` and output directory under
    `$I/records`: "PASS 137, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0,
    OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22 (of 159)", bullets 48 PASS / 0
    FAIL / 8 SKIP / 0 NOT-WRITTEN of 56, scoreboard generated
    2026-10-15T00:56:22Z in 66.7 s, the nine TP-1 programs PASS; `runner.py
    --self-test`: "self-test: 159 programs parsed, 56 bullets in table, OK".
    Expected, not of record (Actions is disabled).
-   **Measured on copies, in place of the merged tree** (§0.9, §2.9, §8): the
    compositions over SC-1 and VA-1 at state T (SC-1 a35535174, VA-1 b0822a744)
    and again at the fold (SC-1 1646988dc, VA-1 b0822a744), every composed
    golden passing with S (1972 of 1972 on SC-1, 1973 of 1973 on VA-1) and
    mutant M18 killed without it; and PR 58's checker on `git archive` copies of
    fcee90d9b with Appendix C applied, 70 fixtures and 0 errors with and without
    TP-1's toolchain (df6487a05 at state T, 12bd6d67a at the fold). Every
    `/dev/shm` copy was deleted after its measurement.
-   **Discharges at land time** (IR2-MAJOR-2): W-127 is PR 51's item and
    W-183, W-192 and W-193 are PR 58's, so none is in trunk's ledger and D
    cannot mark them. The land-time records commit gives each title
    "(DISCHARGED at TP-1, <date>)" and Appendix E's paragraph, with these
    landing commits: W-127 by C4 781908afb (impl_lookup.cpp
    `QueryNamesTemplateBinding`) with F4 989a6496c, and PR 51's split renamed
    in F6; W-183 by C5 df6487a05 (member_access.cpp
    `LookupMemberInTemplateConstraint`) with F5 96fa092b6, composed with SC-1
    by S, for an operand whose type in the definition is the parameter (the
    field form is W-266); W-192 by C1 675e0dd94 (the struct copy, convert.cpp
    `AddConvertActionIfDependent`) with F1 283197da2 and C3 438b3c971
    (`IndexAction`) with F3 a8b3c7900; W-193 by C4 781908afb (call.cpp
    `IsCallPerformable`) with F4 989a6496c.
-   **Ledger re-cites** (Appendix E: evidence re-cited to the tree D writes on,
    here the branch head, each with its b2576f6c3 line beside it): W-250
    lower/handle.cpp:517-524 (:506-513); W-251 handle_operator.cpp:323-342
    (:342-361); W-253 convert.cpp:448-459 (:430-441); W-256 convert.cpp:2278
    (:2199); W-264 handle_loop_statement.cpp:220-222, the ordering TODO itself
    (:219-221; Appendix E's :216-218 included the two TODO lines above it), and
    :230 (:229), with convert.cpp's value temporaries at :496, :1115 and :1267
    (:471, :1084, :1203); W-265 sem_ir/expr_info.cpp:365 (:359); W-014's notes
    name lower/handle.cpp:524 (:513). Evidence in files TP-1 does not change
    keeps its lines. At land time the records commit re-cites them to the merged
    tree.
-   **Program headers** (IR2-MINOR-11): the nine programs name DD-1's fixtures
    (X13 to X33, R09) and no item id; those fixtures are on PR 58's branch only,
    so the names resolve when PR 58 lands, and L rewrites the fixtures.
-   **Land-time items, in order after PR 59** (fork/ORCHESTRATION.md Next
    actions item 5): (a) M repeated as a merge of the trunk that holds PR 51 to
    PR 59, after §0.9's dry run against the heads of that day, resolving
    conflicts only and keeping TP-1's appended record blocks after the PRs'; (b)
    S (§2.5's text); (c) F6 (TP-1's eight refills recomputed, PR 51's split
    renamed and refilled, and any SC-1 or VA-1 golden the merged toolchain
    changes), M, S and F6 judged together with §8's build, autoupdate, gate,
    conformance and mutants; (d) the id re-scan before L; (e) L with its
    document review and fold commits, `check_samples.py` with and without
    `--toolchain` on each; (f) a records commit that recomposes the row over the
    merged one (§2.8's full row, one TP-1 sentence), discharges W-127, W-183,
    W-192 and W-193, re-anchors the decision-log entry and writes Appendix E's
    ORCHESTRATION stamp, W-014's merged-tree sentence and the merged runs here;
    (g) the second id re-scan, immediately before that commit's ledger edit; (h)
    the hosted runs when Actions returns, which are the record.
-   **Against the brief D was given**: D follows this plan as the
    implementation-review fold left it, so W-266 is filed (W-267 to W-269 are
    the spare ids), the decision-log entry carries D-TP-25 and D-TP-26 beside
    D-TP-1 to D-TP-24, and the four discharges move to land time; the Branches
    row reads "IMPLEMENTED AND HELD, PR TO OPEN AND HOLD", because the PR is
    opened and held by the orchestrator, not by D.
-   **After D** (amended 2026-10-15, focused re-review of the fold: all
    findings): the focused re-review of the fold changed the toolchain and
    filed W-267 to W-270, so W-267 to W-269 are no longer unused, and its
    round 2 filed W-271 (amended 2026-10-15, focused re-review of the fold:
    RR2r2-M1); its record is
    the [next section](#focused-re-review-of-the-fold-2026-10-15). Its round 1
    was not dry, so the Branches row reads "IMPLEMENTED AND HELD, RE-REVIEW
    ROUND 2 OWED" until a dry round (amended 2026-10-15, records: re-review
    round 1). Its round 2 was not dry either, and its fixer changed the
    toolchain, so the row reads "IMPLEMENTED AND HELD, RE-REVIEW ROUND 3 OWED"
    (amended 2026-10-15, focused re-review of the fold: all round-2 findings).
    Its round 3 was not dry either, and its fixer changed the toolchain, so
    the row reads "IMPLEMENTED AND HELD, RE-REVIEW ROUND 4 OWED" (amended
    2026-10-15, focused re-review of the fold: all round-3 findings).

## Focused re-review of the fold (2026-10-15)

R29(c)'s focused re-review of the implementation-review fold runs in rounds:
two fresh reviews of the commits since the last reviewed head, then a separate
fixer (R11) for what they find. The PR opens and is held after a round with no
BLOCKER or MAJOR finding whose fixer changes no toolchain file. Round 1, below,
had one BLOCKER and four MAJOR findings (three distinct), and its fixer changed
six toolchain source files and four goldens, so round 2 is owed, over the
round-1 fixer's commits 632f92117..c874c270f and the records commit that
records round 1 (amended 2026-10-15, records: re-review round 1). Round 2,
after round 1 below, had three MAJOR findings, and its fixer changed five
toolchain source files, four goldens and one program, so round 3 is owed, over
the round-2 fixer's commits 2165322c5..bdc1f62d7 and the records commit after
them that records round 2's reviews (amended 2026-10-15, focused re-review of
the fold: all round-2 findings; records: re-review round 2). Round 3, after
round 2 below, had one MAJOR finding, which both reviews found, and its fixer
changed two toolchain source files and one golden, so round 4 is owed, over
the round-3 fixer's commits 68102438e..e7dc20a43 and the records commit after
them (amended 2026-10-15, focused re-review of the fold: all round-3
findings).

### Round 1: the fold's commits, at bf8e1b4cc

Two reviews (R29(c)) of the fold's commits 7c7b1b170..bf8e1b4cc, at the head
bf8e1b4cc: review 1 (RR1, adversarial correctness, probes in
`.../tp1-rr/rev1-r1`) returned REJECT with eight findings, one BLOCKER, two
MAJOR and five MINOR, four of the MINOR records only; review 2 (RR2, strictness
and records, `.../tp1-rr/rev2-r1`) returned APPROVE-WITH-FIXES with six, two
MAJOR and four MINOR, one MAJOR and three MINOR records only. RR1-M1 and RR2-M1
are one finding, so there are thirteen distinct. (Trunk's 2026-10-19
ORCHESTRATION paragraph numbers the two reviews the other way round; this record
numbers them as the fixer's brief does.) A separate fixer (R11; `$F`) reproduced
every finding on the installed toolchain 0.0.0-0.dev+12bd6d67a, on trunk
0bdce60a5 and on the nightly before changing anything, folded the six toolchain
findings in four fix commits, each with its fill, and a formatting commit, and
folded the records findings in the records commit that adds this section. No
finding is rejected. A finding marked records only changes no toolchain file,
goldens included, so the residues it files (W-267 to W-269) are evidenced by
probes and have no pin split yet. Four residues are filed: W-267 to W-269,
TP-1's spare ids, and W-270, the first of W-270..W-274, which the re-review's
brief reserved to it; W-271 to W-274 stay unused (round 2 files W-271;
amended 2026-10-15, focused re-review of the fold: RR2r2-M1). The fix commits
carry the
container clock's date, 2026-10-19 UTC; this record is dated 2026-10-15, the
re-review's date.

Neither review judged the branch dry. Review 1: an invalid program passes
checking because of TP-1 (r6, `let unused a: (x.0, i32) = (1, 2);`, which trunk
rejects where it is defined) and, with a use (r7), stops lowering at
function_context.cpp's `Missing value` CHECK; four other invalid forms (r1, r2,
r3 and r8) that trunk 0bdce60a5 and the nightly 62f1cc6 diagnose stop the
compiler at eval.cpp's `PatternType should always be constant` FATAL, as they
did at 4e1f07a91; and the cross-library class-member shape (n8) stops it after
W-250's TODO. Review 2: one MAJOR (RR2-M1) and one MINOR (RR2-m6) need
toolchain or golden changes, and two records overclaim, IR1-M2's "Fixed" with
D-TP-14's "unreachable", and the TR-8 narrowing that the fold record named.

The reviews' own runs at bf8e1b4cc, container-built, EXPECTED, not of record,
the worktree untouched and every `/dev/shm` copy deleted. Review 1 used the
install 0.0.0-0.dev+12bd6d67a, whose toolchain sources equal the head's, with a
private cache, build-root view and conformance output directory: the gate, "1955
passed, 0 failed", its progress line 1955 `.` with no `!` or `?`; conformance
"PASS 137, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0,
DIFF-MISMATCH 0, SKIP 22" of 159, bullets 48 PASS / 0 FAIL / 8 SKIP of 56, the
nine TP-1 programs the only movers from
fork/conformance/out/scoreboard.json's 128/0/22 of 150; M21 to M25 relinked
under `/dev/shm/rr1-r1`, each killed by the golden the fold names; and the nine
EXPECT lines of templates_constant_elements re-derived by hand (R16(d)), all
matching. Review 2 read the full diff of 4e1f07a91..bf8e1b4cc (25 files), re-ran
IR1's, IR2's and the fold fixer's probes on the three toolchains, three runs
each, and ran an autoupdate of the fold's eight goldens on a `git archive` copy
of the head, which changed nothing (R26), and the full gate there, 1955 of 1955;
conformance 137/0/22 over 159, 48 of 56 bullets, and `runner.py --self-test`,
"159 programs parsed, 56 bullets in table, OK"; `prek --all-files` on a clone,
every hook passing; clang-format 21.1.8 clean on the fold's seven C++ files and
clang-tidy 0 diagnostics on its changed lines of six `.cpp` files; the id
re-scan of 2026-10-15 over trunk 5674fe88b, the ten held PRs, OX-1 and 65 other
refs, with no collision; and the PR body's size, 26,664 bytes, under the limit.

Commits: 632f92117 "TP-1 re-review fix: a runtime result of a deferred action
used as a type is diagnosed; a template splice in a tuple type resolves in each
specific" (eval.cpp, convert.cpp) and its fill d069d639d; d8f6ab60a "TP-1
re-review fix: imported class templates, interfaces and constraints resolved per
instantiation are diagnosed at the import" (import_ref.cpp) and its fill
22b9074bd; 73b3124dd "TP-1 re-review fix: dependent operations print with their
precedence, and interface members by name" (stringify.cpp) and its fill
831289fad; 67a9dd91c "TP-1 re-review fix: clang-format the imported facet type's
constraint test"; ba64734e7 "TP-1 re-review fix: a diagnosed runtime type is an
error in its specific, and a runtime conversion target is diagnosed" (eval.cpp,
sem_ir/expr_info.cpp, sem_ir/function.cpp) and its fill 1f0bc7be0; and the
records commit. Each fix commit was gated alone, red exactly on the goldens it
adds splits to, with no crash, and then with its fill at the autoupdate
fixpoint (§8 "Measured at the focused re-review of the fold"). The fixer's own
probes of 632f92117 found four more forms of RR1-B1 that it left reachable,
which ba64734e7 completes. §3's budget is exceeded by the dated note there, for
the root-cause reason it gives. Since the cut, TP-1 changes 27 toolchain source
files and adds 13 goldens and refills 8 (`git diff --stat b2576f6c3 1f0bc7be0 --
toolchain core`: 48 files, +9674/-537; the re-review's own `git diff --stat
bf8e1b4cc 1f0bc7be0 -- toolchain core`: 10 files, +1007/-27).

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR1-B1: D-TP-26 fixed only array bounds; a runtime result of a deferred action used as any other type (r1 `let a: x.0`, r2 `x[0]`, r3 `*p`, r8 `{.p: x.0, ...}`) reached eval.cpp's `PatternType` FATAL, r6 `(x.0, i32)` passed checking and r7 stopped lowering, and c12's note blamed the bound | BLOCKER | Fixed in 632f92117 and ba64734e7 (D-TP-26 rewritten): in a specific, an operand that is not constant where a type, an always-constant instruction or an operand used as a type needs one is reported at that operand and is the error constant in the specific. r1, r2, r3, r6, r7, r8 and c12 are errors with one note at the runtime operand (c12's at 3:23, its `MakeT(x)`). The fixer's probes of 632f92117 found four more forms, `let a: x.0 = 1; return a;`, `var a: x.0;`, `-> x.0` and `2 as x.0` (the last passed checking), which ba64734e7 completes; trunk rejects the tuple-index and dereference forms where they are defined and stops at the FATAL for the call form. Eleven `_on_instantiation` splits of index.carbon and pointer.carbon and `template_value_as_type`; mutants M22, M26, M32, M33 and M34. IR1-M1's row in the implementation review fold record and the PR body's "Fixed by: D-TP-26" line are amended. Since round 2, every runtime operand that the instruction needs constant is an error in the specific, not only the first (2165322c5: `array(x.0, x.1)` had stopped the compiler at value_store.h's CHECK; (amended 2026-10-15, focused re-review of the fold: RR2-1-M1)) | Outcome (a), §1.2 D-TP-26, §1.8, §1.14, §2.7, §4, §8, Appendix A |
| RR1-M1 = RR2-M1: an imported class template whose field type (n9, main_f1) or method declaration (n8, n2, n3, main_m1, main_m2) holds an action, and an imported interface or named constraint whose declaration holds one (m3, m4, main_i2, main_c2), still stopped the compiler (generic.cpp:236's CHECK or `TryResolveInstCanonical`'s FATAL); D-TP-14's "unreachable" was false | MAJOR | Fixed in d8f6ab60a (D-TP-14 amended): `IsTypeResolvedPerInstantiation` tests a class's, interface's or constraint's declaration, definition, generic with `Self` and the declarations its definition names before any of its data is loaded; the TODO is reported once and the error passes through the generic interface and constraint types and an imported facet type. Every named probe reports the TODO at the `import` (trunk and the nightly stop at the FATAL); five fail_todo_import.carbon splits; mutants M23, M28 and M29. Using such an interface or constraint in its own library stops the compiler on all three toolchains (sem_ir/generic.cpp:84): filed as W-270. IR1-M2's row, W-250's title, evidence and notes, and the PR body's RC-8 and TR-17 lines are amended. Round 2 found that the test stopped at the entities it was given, so a nested generic class or an interface constraint still stopped the compiler after the TODO; since 94227d82c and 282930a73 it walks what the entity's data names (amended 2026-10-15, focused re-review of the fold: RR2r2-M1) | Outcome (a) and (e), TR-17, §1.2 D-TP-14, §1.8, §1.13, §1.14, §2.7, §4, Appendix E, ledger W-250 and W-270 |
| RR1-M2: a tuple type with a produced-type element, `(T.Elem, i32)`, passed checking and stopped lowering (d06's a, b, d, f and g) | MAJOR | Fixed in 632f92117 (D-TP-6 amended): `ConvertTupleToType` converts the generic's instruction for a spliced element's constant, so the conversion is performed in each specific. d06's a to g compile and print 5 (d06's h, an uninitialized `var` of `(T.Elem*, i32)`, is W-268's lookup); lower initialize.carbon `return_tuple_of_associated_type` and `var_tuple_of_associated_type`, whose function bodies equal their non-template twins'; mutant M27. TR-4's IN wording names the form | TR-4, §1.2 D-TP-6, §1.8, §1.14, §2.7, §4, Appendix A |
| RR1-m1: printing lost precedence (`C(*p[0])` for `C((*p)[0])`, two identical texts) and printed `<cannot stringify ...: {kind: AssociatedEntity, ...}>` for an operator's interface member; `v.(I.F)` dropped the interface | MINOR | Fixed in 73b3124dd (D-TP-23 amended): a prefix operand of a postfix operation prints in parentheses, and an associated entity prints as `Interface.Member`. s02 prints `C(v.(I.F)().(Core.AddWith(Core.IntLiteral).Op)(1))`; the redeclaration split gains H and K; mutant M30. Since round 2, a member access through `->` prints as `p->n` (123eb40ca; (amended 2026-10-15, focused re-review of the fold: RR2-1-m1)) | §1.2 D-TP-23, §1.14, §2.7, §4, §8 |
| RR1-m2 (records only): D-TP-26's break condition is met by an imported `eval fn`, and W-250's title overclaims | MINOR | Folded: D-TP-26's break condition says that a checked generic's specific reaches the diagnosis only through an `eval fn` from another library, where it is the intended result (m5, m12 and m16 report it; trunk stops the compiler on all three); eval.cpp's comment says "In a specific" since 632f92117; W-250's title and D-TP-14's wording sentence name eval blocks that hold an action or a splice, and W-250's notes record the imported `eval fn` as an upstream limit | §1.2 D-TP-14 and D-TP-26, §1.13, ledger W-250 |
| RR1-m3 (records only): the temporaries a template's actions create on instantiation are never destroyed (a06, a05; trunk the same) | MINOR | Filed as W-267; TR-4 excepts it. a06 still prints `1000 11 2000 5 5 3000 1 4000 101 5000 201 6000 1` against its twin's `1000 11 11 2000 5 5 3000 1 4000 101 101 5000 201 201 6000 1` | TR-4, §1.8, §1.13, ledger W-267 |
| RR1-m4 (records only): `var e: T.Elem;` is rejected where it is defined (d03; trunk the same) | MINOR | Filed as W-268; TR-10 names it. index.carbon's `fail_tuple_index_as_var_type_on_instantiation`, added for RR1-B1, shows the same definition-time lookup for `var a: x.0;` | TR-10, §1.8, §1.13, ledger W-268 |
| RR1-m5 (records only): `return {} as T;` for a class without `Copy` cannot copy (e02; trunk and the nightly the same) | MINOR | Filed as W-269; TR-4 excepts it | TR-4, §1.8, §1.13, ledger W-269 |
| RR2-M2 (records only): the PR body has no merge-tree conflicts, its merge order says "4. SC-1", it omits PR 60, its diffstat base is not trunk, and a merge of trunk 5674fe88b silently duplicates TP-1's Branches row | MAJOR | Folded into the PR body: a "Conflicts" subsection under "Held OPEN" gives `git merge-tree --write-tree` of the head against trunk (now f3156a375, records only) and each held PR, with the files and resolutions (record files: the trunk's or the PR's text first, TP-1's blocks after; trunk's stale TP-1 Branches row dropped for the branch's; convert.cpp: SC-1's check first, then A2's `PendingBlock`; member_access.cpp: both includes; README.md regenerated with `runner.py --update-readme-table`); "4. PR 60"; "PR 51 to PR 60"; the diffstat from the merge base; and the id re-scan against trunk f3156a375 | PR body, front matter |
| RR2-m3 (records only): the PR body has no Co-Authored-By statement, and its review record omits this re-review | MINOR | Folded into the PR body: the Attribution paragraph states that each commit carries the Co-Authored-By trailer of the agent that wrote it and that no history was rewritten; the review table gains this re-review's two rows; the bullet that listed a review of 7c7b1b170 and 12bd6d67a as not run is deleted | PR body |
| RR2-m4 (records only): W-014's notes give container counts without "EXPECTED, not of record" | MINOR | Folded: W-014's notes and Appendix E's held-state template say "container-built, EXPECTED, not of record (Actions disabled)", marked amended | ledger W-014, Appendix E |
| RR2-m5 (records only): the fold record says TR-8 was narrowed, but §1.1's TR-8 was unamended | MINOR | Folded: TR-8 says "a value whose type in the definition is the parameter" and "OUT through a field whose declared type is the parameter (W-266)", marked with IR1-M3's amendment and this re-review | §1.1 TR-8 |
| RR2-m6: three of the six new printing overloads had no golden, and M24 covered two | MINOR | Fixed in 73b3124dd: the redeclaration split gains L (`T.(Container.Elem)`, `T.(Container.Other)`), M (`&p.n`, `&p.m`, with `class D(Q: i32*)`) and N (`p->n`, `p->m`); mutant M31 removes the three and is killed | §1.2 D-TP-23, §2.7, §4, §8 |

Measured at the head (§8 "Measured at the focused re-review of the fold"),
container-built, EXPECTED, not of record: gate 1955 of 1955 files;
conformance 137/0/22 over 159, 48 of 56 bullets PASS; every mutant re-run
killed (thirty-three: M1 to M17 and M19 to M34); no clang-tidy diagnostic on
the re-review's changed lines; the 213 probes as §8 gives them. The ledger's
evidence lines in the files the re-review changes are re-cited to 1f0bc7be0:
W-253 convert.cpp:449-460, W-256 convert.cpp:2288, W-264 convert.cpp's :497,
:1125 and :1277, W-265 sem_ir/expr_info.cpp:369 (each with its b2576f6c3 line
beside it, as before). The id re-scan of the front matter, run on 2026-10-19
(15:45 UTC, the container clock) from /home/user/carbon-lang after `git fetch
origin` (origin/trunk is f3156a375), with the second command's pattern
widened to W-270..W-274: 81 refs match the patterns and 79 remain after TP-1's
two are excluded; the first command printed `W-274`, `W-275` and `W-294`, all
from trunk's ORCHESTRATION paragraph that reserves W-267 to W-274 for this
re-review and W-275 to W-294 for SV-1; the second printed that file on
refs/heads/trunk, refs/remotes/origin/trunk and
refs/remotes/origin/claude/carbon-fork-0-1-7mwfb7 (all f3156a375), for the same
sentence; the third printed nothing. No other workstream took an id. Not run,
as §8 item 8 says: hosted CI, Bazel and its tests, ASan, macOS and Windows,
LLVM with assertions and the owner's runner; and the land-time items (M with
the PRs, S, F6, L with its document review, the compositions, PR 58's checker,
the id re-scans before L and D, and the discharges), which wait for PR 51 to
PR 60.

Round 1's status: not dry in either review, and its fixer changed six
toolchain source files (check/convert.cpp, check/eval.cpp,
check/import_ref.cpp, sem_ir/expr_info.cpp, sem_ir/function.cpp and
sem_ir/stringify.cpp) and four goldens (check generic/template's
fail_todo_import.carbon, index.carbon and pointer.carbon, and lower
template/initialize.carbon; `git diff --stat bf8e1b4cc 1f0bc7be0 -- toolchain
core`). Round 2 is owed: two fresh reviews of 632f92117..c874c270f and the
records commit that records round 1, which changes records only.
fork/ORCHESTRATION.md's TP-1 Branches row reads "IMPLEMENTED AND HELD,
RE-REVIEW ROUND 2 OWED" until a round is dry (amended 2026-10-15, records:
re-review round 1).

### Round 2: the round-1 fixer's commits, at 764e55445

Two fresh reviews (R29(c)) of the round-1 fixer's commits 632f92117..c874c270f
and the records commit 764e55445, at the head 764e55445 (amended 2026-10-15,
focused re-review of the fold: all round-2 findings): review 1 (RR2-1,
adversarial correctness, probes in `.../tp1-rr/rev1-r2`) returned
APPROVE-WITH-FIXES with three findings, two MAJOR and one MINOR; review 2
(RR2r2, strictness and records, `.../tp1-rr/rev2-r2`) returned
APPROVE-WITH-FIXES with four, one MAJOR and three MINOR, two of the MINOR
records only. The seven are distinct. A separate fixer (R11; `$F` is
`.../tp1-rr/fixer-r2` in this round) reproduced every finding on the installed
toolchain 0.0.0-0.dev+1f0bc7be0, whose toolchain sources equal the head's, on
trunk 0bdce60a5 and on the nightly before changing anything; folded the five
findings that are not records only (RR2r2-m1 by a split of 94227d82c and a
record) in four fix commits, each with its fill, a commit that rewrites two of
their tests as worklists, and a fifth fix commit with its fill that removes a
test the four made redundant; and folded the two records-only findings in
bdc1f62d7, the records commit that adds this section (amended 2026-10-15,
records: re-review round 2). No finding is rejected. One
residue is filed: W-271, the second id of W-270..W-274, for a crash that the
second review's probes reach on all three toolchains (W-272 to W-274 stay
unused). The fix commits carry the container clock's date, 2026-10-19 UTC;
this record is dated 2026-10-15, the re-review's date.

Neither review judged the branch dry. Review 1: RR2-1-M1 is a toolchain defect
on the surface of the fold's D-TP-26 that round 1 left reachable, and RR2-1-M2
a TP-1 regression outside the fold's surfaces (C4, unchanged since 4e1f07a91);
there is no BLOCKER. Review 2: D-TP-14's "no error constant reaches an eval
block" is false (RR2r2-M1), and three minor records and test gaps remain;
every crash it found also stops trunk and the nightly.

The reviews' own runs at 764e55445, container-built, EXPECTED, not of record,
the worktree untouched and every `/dev/shm` copy deleted. Review 1 used the
install 0.0.0-0.dev+1f0bc7be0, whose toolchain sources equal the head's, with a
private cache and build-root view: the gate, "1955 passed, 0 failed", its
progress line 1955 `.` with no `!` or `?`; conformance "PASS 137, COMPILE-FAIL
0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22" of 159,
bullets 48 PASS / 8 SKIP of 56, the nine TP-1 programs the only movers from
fork/conformance/out/scoreboard.json's 128/0/22 of 150; M21 to M25 rebuilt over
the head and each killed by its named golden or program; the nine EXPECT lines
of templates_constant_elements re-derived by hand (R16(d)), all matching;
position probes, each run three times, and D-TP-26 and printing probes; and the
imports of 4e1f07a91 and bf8e1b4cc relinked over the build for 27 cross-library
probes, whose behavior only moves from the FATAL to the TODO; it also found the
normalized `--dump-llvm-ir` bodies of a01 and templates_constant_elements equal
to their non-template twins', no false positive and no false negative among
its D-TP-26 probes (21 runtime-as-type forms, all rejected), and trunk and the
nightly stopping on every template form of its position probes (amended
2026-10-15, records: re-review round 2). Review 2 read the
full diff of bf8e1b4cc..764e55445 (15 files, +2258/-187); ran an autoupdate of
the fold's and round 1's eight goldens on a `git archive` copy of the head,
which changed nothing (R26), and the full gate there, 1955 of 1955; conformance
137/0/22 over 159, 48 of 56 bullets, and `runner.py --self-test`, "159 programs
parsed, 56 bullets in table, OK"; 40 runtime-as-type probes and the round-1
probes on the three toolchains; its own mutants x5, x6 and x7, killed, and x1,
x2 and x4, which survive (RR2r2-m1); `git merge-tree --write-tree` of the head
against trunk f3156a375 and each held PR, which reproduces the PR body's
conflict table; the id re-scan over 81 other refs, with no collision; `prek
--all-files` on a clone, every hook passing; clang-format 21.1.8 clean on round
1's ten C++ files and clang-tidy 0 diagnostics on its changed lines of six
`.cpp` files; and the PR body's size, 39,560 bytes. It also checked the
records: the implementation review fold record's 20 findings in 19 rows, round
1's 14 findings (13 distinct), the round-1 fixer's sweep (on the fork 72
compile, 137 are rejected and 4 stop the compiler; trunk stops on 84 and the
nightly on 77) and mutant logs, the evidence lines of W-267 to W-270 (R10),
the ledger's 146 items ending at W-270, the decision-log entry's place above
OX-1's, gap row 54 PARTIAL under an unchanged header, and that no CHECK line
was written by hand and no source, golden or program header that TP-1 added
names a W-id (amended 2026-10-15, records: re-review round 2).

Commits: 2165322c5 "TP-1 re-review fix: every runtime operand that a specific
needs constant is an error there" (eval.cpp) and its fill e6a663c22; 123eb40ca
"TP-1 re-review fix: a member access through `->` prints as `p->n`"
(stringify.cpp) and its fill 8af8ad78b; b678e2985 "TP-1 re-review fix: a class
template's literal whose array field has a template-dependent bound is
converted on instantiation" (convert.cpp, action.cpp and the program
templates_deduce_class_args) and its fill 7ea3fed97; 94227d82c "TP-1 re-review
fix: an imported entity that names one that cannot be imported is diagnosed at
the import" (import_ref.cpp) and its fill 4fcbf62ef; 282930a73 "TP-1 re-review
fix: the import test and the literal test walk iteratively" (import_ref.cpp,
action.cpp; no golden change); f44280c1c "TP-1 re-review fix: an aggregate that
holds a class template's literal is converted element by element"
(convert.cpp) and its fill 24bf5ea45; and the records commit. Each fix commit
was gated alone, red exactly on the goldens it adds splits to or refills, with
no crash, and then with its fill at the autoupdate fixpoint (§8 "Measured at
the focused re-review of the fold, round 2"). The round's own mutants M37 to
M39 showed that b678e2985's aggregate-level deferral changed only value names
once `NeedsSpecificInst` was fixed, so f44280c1c removes it. §3's budget is
exceeded by the second dated note there, for the root-cause reason it gives.
Since the cut, TP-1 changes 28 toolchain source files and adds 13 goldens and
refills 8 (`git diff --stat b2576f6c3 24bf5ea45 -- toolchain core`: 49 files,
+11135/-540; the round's own `git diff --stat 764e55445 24bf5ea45 -- toolchain
core`: 9 files, +1610/-152).

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR2-1-M1: D-TP-26 made only an instruction's first runtime operand an error in the specific, so `array(x.0, x.1)` for `x: (type, i32)` stopped the compiler at value_store.h's `inst<none>` CHECK after the diagnostics (c10, c19), and `(x.0, x.1)` as a type had two notes at one location | MAJOR | Fixed in 2165322c5 (D-TP-26 amended): `FindNonConstantOperands` collects every operand that is not constant, and of those the instruction needs constant, the first is diagnosed once and each is the error constant in the specific's value block. c10 and c19 are errors with no crash: on instantiation the specific is reported with the notes ``non-constant call to compile-time-only function`` and ``expression is runtime; expected constant`` at `x.1`; trunk and the nightly reject both where the function is defined. index.carbon's `fail_array_type_two_runtime_operands_on_instantiation` and `fail_tuple_type_two_runtime_elements_on_instantiation`; mutant M35 | §1.2 D-TP-26, §1.8, §1.14, §2.7, §4, §8 |
| RR2-1-M2: a class template's literal whose array field has a template-dependent bound, `var c: C(N) = {.a = (1, 2, 3), .b = N};` and the same returned from `-> C(N)`, was rejected with `ArrayInitDependentBound` where trunk and the nightly compile and run it (b04b, b12), because C4 forms `C(N)` in the definition | MAJOR | Fixed in b678e2985 and f44280c1c (D-TP-24 amended): `ConvertStructToClass` defers such an initializer whole when its fields are exactly the class's (`HoldsTemplateDependentArrayBound`), and an aggregate that holds one converts it as its element. The fixer's probes found that a deferred runtime literal with a template value element, `let p: P(N) = {.a = x, .b = N};`, already stopped lowering at 764e55445 (value_store.h's CHECK; trunk at an inst.h cast): `NeedsSpecificInst` (action.cpp) now wraps a struct or tuple literal whose element needs it. b04b, b12 and the fixer's f, g and h probes run with their twins' values, except f04, f05, f17, f18 and f20, W-263's class, whose twins fail on all three toolchains; deduce_class_args.carbon's four splits, lower initialize.carbon's six and templates_deduce_class_args's `16` and `8`; mutants M36 and M40. W-253's and W-263's notes are amended | §1.2 D-TP-24, §1.6, §1.8, §1.10, §1.13, §2.7, §4, §8, Appendices A and B, ledger W-253 and W-263 |
| RR2-1-m1: a member access through `->` printed as `(*p).n`, so `C(*p->q)` and `C(*(*p).q)`, and two other pairs, printed the same text in a redeclaration diagnostic | MINOR | Fixed in 123eb40ca (D-TP-23 amended): a member access or a compound member access whose base is the dereference that `->` performs, looking through splices and conversions, prints as `p->n` or `p->(I.F)`. The redeclaration split gains R, S and U, and N prints `C(p->n)`; mutants M41 and M42 | §1.2 D-TP-23, §1.14, §2.7, §4, §8 |
| RR2r2-M1: across libraries, a class template's nested generic class with a field or method of type `T.Item` (n01, n02, n03) and a function constrained by a template interface whose member returns `T.Item` (n05) reported W-250's TODO and then stopped the compiler (generic.cpp:239's or sem_ir/type.cpp:27's CHECK); D-TP-14's "no error constant reaches an eval block" was false | MAJOR | Fixed in 94227d82c and 282930a73 (D-TP-14 amended): `PerInstantiationWalk` walks the imported instructions that an entity's eval blocks and its bindings' types name, adding a function's declaration, a class's declaration and definition, and each interface and named constraint of a facet type, each generic once; an impl whose generic the walk rejects is diagnosed and not imported. n01, n02, n03, n05 and the fixer's p1 to p9 report the TODO once per entity with no crash (trunk stops them at `TryResolveInstCanonical`'s FATAL, and the nightly stops n05 and p2 to p9 there and n01, n02, n03 and p1 at import_ref.cpp:1168's CHECK, as it does their checked twin n07; amended 2026-10-15, focused re-review of the fold: RR3r2-m1); seven fail_todo_import.carbon splits; mutants M43 to M50 and the redefined M28. The second review's y04, y05 and y09 stop at another FATAL on all three toolchains, with or without a template: a generic class from another library that declares a nested class or interface, filed as W-271. 282930a73 makes the walk and the literal test worklists, because clang-tidy's misc-no-recursion is an error here. Round 3 found that the walk tested only each entry's kind, not its operands, and 68102438e makes it follow each reference the import loads (amended 2026-10-15, focused re-review of the fold: RR3-1-M1 / RR3r2-M1) | Outcome (a), TR-17, §1.2 D-TP-14, §1.8, §1.13, §1.14, §2.7, §4, §8, Appendix E, ledger W-250 and W-271 |
| RR2r2-m1: three error guards that round 1 added are reached by no golden: mutants that remove the use of `HasErrorConstraint` (x4), `TryGetCalleeAsBoundMethod`'s error arm (function.cpp:31-32, x1) and `FindStorageArgForInitializer`'s (expr_info.cpp, x2) survive the gate and 306 probes | MINOR | Folded: `HasErrorConstraint` is reached by a parameter of such a facet type in a function that is not generic, now pinned by `fail_todo_import_function_parameter_of_template_interface_type` (94227d82c; mutant M49). The other two are kept and recorded, not pinned: `FindStorageArgForInitializer` is called with a specific only from lowering, which does not run after the diagnosed error that an error value in a specific implies, and `TryGetCalleeAsBoundMethod` with a specific only through `GetExprCategory`'s `Call` arm, for a callee that is a splice, which no golden or probe of the two rounds reaches; the arms keep an error value in a specific read as an action not performed rather than cast to an instruction (mutants x1 and x2, which survive) | §1.2 D-TP-26, §2.7, §8, ledger W-250 |
| RR2r2-m2 (records only): the plan's id paragraph omitted 764e55445, whose message names W-250, said the ids appear only in the plan, L, R and D, and kept the failure condition's W-250..W-269 | MINOR | Folded: the paragraph lists 637e3efaf, 12bd6d67a and 764e55445 as the pushed messages that name W-250, says the ids also appear in the records commits after D (c874c270f, 764e55445 and this round's), and widens the failure condition to W-250..W-274 or F-019. The fixer's scan of every message since the cut also found ids in the plan's rev 1 and rev 3 and in D's message, which the paragraph now lists; the round's commit messages name none | Front matter (id allocation) |
| RR2r2-m3 (records only): the PR body's FILL-CAUGHT MISSES stopped at the fold's fills | MINOR | Folded into the PR body: a bullet for round 1's fills d069d639d, 22b9074bd, 831289fad and 1f0bc7be0 (none against §4, whose rows were written from the fixer's own autoupdate; 1f0bc7be0's `var` split also showed a definition-time `DefaultOrUnformed` error, W-268), one for this round's fills (none, for the same reason), and, under the other layers that caught misses, the round-1 fixer's probes of 632f92117, which found four more RR1-B1 forms that ba64734e7 completed | PR body |

Measured at the head (§8 "Measured at the focused re-review of the fold, round
2"), container-built, EXPECTED, not of record: gate 1955 of 1955 files;
conformance 137/0/22 over 159, 48 of 56 bullets PASS; every mutant re-run killed
but x1 and x2, which survive as recorded; no clang-tidy diagnostic on the
round's changed lines; the 284 probes as §8 gives them. The ledger's evidence
lines in the files the round changes are re-cited to the head: W-253
convert.cpp:507-518 and W-256 convert.cpp:2361, and W-264's temporaries :556,
:1184 and :1350 (each with its b2576f6c3 line beside it, as before). The id
re-scan of the front matter, re-run on 2026-10-19 (19:00 UTC, the container
clock) from /home/user/carbon-lang after `git fetch origin` (origin/trunk is
f3156a375): 81 refs match the patterns and 79 remain after TP-1's two are
excluded; the first command printed `W-274`, `W-275` and `W-294`, from trunk's
ORCHESTRATION paragraph that reserves W-267 to W-274 for this re-review and
W-275 to W-294 for SV-1; the second printed that file on refs/heads/trunk,
refs/remotes/origin/trunk and refs/remotes/origin/claude/carbon-fork-0-1-7mwfb7,
for the same sentence; the third printed nothing. No other workstream took an
id, so W-271 is TP-1's. The records commit after bdc1f62d7 re-ran the three
commands on 2026-10-19 (19:32 UTC, after `git fetch origin`; origin/trunk still
f3156a375) with the same three outputs, and `git merge-tree` of bdc1f62d7 with
trunk and each held PR reproduced the PR body's conflict table (amended
2026-10-15, records: re-review round 2). Not run, as §8 item 8 says: hosted CI,
Bazel and its tests, ASan, macOS and Windows, LLVM with assertions and the
owner's runner; and the land-time items, which wait for PR 51 to PR 60.

Round 2's status: not dry in either review, and its fixer changed five
toolchain source files (check/action.cpp, check/convert.cpp, check/eval.cpp,
check/import_ref.cpp and sem_ir/stringify.cpp), four goldens (check
generic/template's deduce_class_args.carbon, fail_todo_import.carbon and
index.carbon, and lower template/initialize.carbon) and the program
templates_deduce_class_args (`git diff --stat 764e55445 24bf5ea45 -- toolchain
core fork/conformance/programs`). Round 3 is owed: two fresh reviews of the
round-2 fixer's commits 2165322c5..bdc1f62d7 and the records commit after them
that records round 2's reviews, which, like bdc1f62d7, changes records only.
The PR opens and is held after a round with no BLOCKER or MAJOR finding whose
fixer changes no toolchain file. fork/ORCHESTRATION.md's TP-1 Branches row
reads "IMPLEMENTED AND HELD, RE-REVIEW ROUND 3 OWED" until a round is dry
(amended 2026-10-15, focused re-review of the fold: all round-2 findings;
records: re-review round 2).

### Round 3: the round-2 fixer's commits, at aa57bfe1c

Two fresh reviews (R29(c)) of the round-2 fixer's commits
2165322c5..bdc1f62d7 and the records commit aa57bfe1c, at the head aa57bfe1c
(amended 2026-10-15, focused re-review of the fold: all round-3 findings):
review 1 (RR3-1, adversarial correctness, probes in `.../tp1-rr/rev1-r3`)
returned APPROVE-WITH-FIXES with one finding, MAJOR; review 2 (RR3r2,
strictness and records, `.../tp1-rr/rev2-r3`) returned APPROVE-WITH-FIXES
with three, one MAJOR and two MINOR, both MINOR records only. RR3-1-M1 and
RR3r2-M1 are one finding, so there are three distinct. A separate fixer
(R11; `$F` is `.../tp1-rr/fixer-r3` in this round) reproduced every finding
on the installed toolchain 0.0.0-0.dev+24bf5ea45, whose toolchain sources
equal the head's, on trunk 0bdce60a5 and on the nightly before changing
anything; folded the MAJOR finding in a fix commit with its fill, a commit
that records each walk's result for the file, and a commit of three more
splits with its fill, which pin the shapes that three of the round's
mutants change; and folded the two records-only findings in the records
commit that adds this section. No finding is rejected, no residue is filed
and W-272 to W-274 stay unused. The fix commits carry the container clock's
date, 2026-10-19 UTC; this record is dated 2026-10-15, the re-review's date.

Neither review judged the branch dry. Review 1: the single-library surfaces
had no defect it could find, but on the W-250 import surface eleven of its
51 cross-library probes reported the TODO and then stopped the compiler, the
class of defect graded MAJOR in rounds 1 and 2; there is no BLOCKER. Review
2: D-TP-14's "no error constant reaches an eval block" was still false
(RR3r2-M1), and two records were inexact (RR3r2-m1, RR3r2-m2); every crash it
found also stops trunk and the nightly.

The reviews' own runs at aa57bfe1c, container-built, EXPECTED, not of
record, the worktree untouched and every `/dev/shm` copy deleted. Review 1
used the install 0.0.0-0.dev+24bf5ea45 with a private cache and build-root
view: the gate, "1955 passed, 0 failed", its progress line 1955 `.` with no
`!` or `?`; conformance "PASS 137, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0,
OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 22" of 159, bullets 48 PASS / 0
FAIL / 8 SKIP of 56, the nine TP-1 programs the only movers from
fork/conformance/out/scoreboard.json's 128/0/22 of 150; M21 to M25 relinked
over the head, each killed by its named golden or program, and round 2's
M35, M36 and M40 and a mutant that removes the impl guard, each killed; the
nine EXPECT lines of templates_constant_elements and round 2's `16` and `8`
re-derived by hand (R16(d)); D-TP-25 position probes, each run three times,
equal to their non-template twins but for W-267's redundant GEPs and no-op
destroys; D-TP-26 and printing probes with no false positive; 305
single-file probes on the head and on a relink of 764e55445's five changed
files, of which none that compiled at 764e55445 fails at the head and the
17 that stop the head are W-263's, whose twins stop too; 51 cross-library
probes on the head, 764e55445, 4e1f07a91's import_ref.cpp relinked and
trunk, of which every one that compiled on 4e1f07a91 still compiles, 20
report the TODO cleanly, 6 stop at W-271's crashes and 11 report the TODO
and then stop the compiler (RR3-1-M1); and clang-tidy, 0 diagnostics on the
five `.cpp` files round 2 changed. Review 2 read the full diff of
764e55445..aa57bfe1c (15 files, +2818/-307); ran an autoupdate of the nine
goldens touched since 4e1f07a91 on a `git archive` copy, which changed
nothing (R26), and the full gate there, 1955 of 1955; conformance 137/0/22
over 159, 48 of 56 bullets, `runner.py --self-test` and a no-op
`--update-readme-table`; M35 rebuilt over the head, killed; the round-2
fixes re-checked on the three toolchains (c10, c19 and c17 errors with no
crash; b04b, b12, k1, k3, l1 and l4 printing their twins' values; s01 and s02
printing as written); W-271's, W-253's, W-256's and W-264's evidence lines,
R10-exact; the round-2 table's seven findings, the implementation-review
fold record unchanged, and every count of the records and the PR body
(49 files, +11135/-540, at 24bf5ea45; 74 findings, 72 distinct; seventeen
`fail_todo` splits); the ledger's 147 items ending at W-271, the
decision-log entry's place above OX-1's, gap row 54 PARTIAL under an
unchanged header and the Branches row; the id re-scan after `git fetch
origin` over 79 other refs, with no collision and every held PR's ledger
outside W-250..W-274; `git merge-tree` of the head against trunk f3156a375
and each held PR, which reproduces the PR body's conflict table; the PR body's
size, 49,972 characters, with no model identifier and no `#NN` reference;
`prek --all-files` on a clone, 28 hooks passing; R31 counts equal at
bdc1f62d7 and aa57bfe1c; and clang-format 21.1.8 clean on round 2's five
`.cpp` files.

Commits: 68102438e "TP-1 re-review fix: the import test follows each reference
that the import loads" (import_ref.cpp and fail_todo_import.carbon's eight new
splits) and its fill d0fbfd56b; d54c37f91 "TP-1 re-review fix: the import test
walks each imported instruction once per file" (context.h and import_ref.cpp; no
golden change); ada45a7c6 "TP-1 re-review fix: pin the struct, rewrite and
repeated-use import shapes" (three more splits; no toolchain change) and its
fill e7dc20a43; and the records commit. 68102438e and ada45a7c6 were each
gated alone, red exactly on fail_todo_import.carbon, with no crash, and then
with their fills at the autoupdate fixpoint; d54c37f91, which changes no
golden, passed 1955 of 1955 (§8 "Measured at the focused re-review of the
fold, round 3"). §3's budget is exceeded by the third dated note there, for
the root-cause reason it gives.
Since the cut, TP-1 changes 29 toolchain source files and adds 13 goldens and
refills 8 (`git diff --stat b2576f6c3 e7dc20a43 -- toolchain core`: 50 files,
+11514/-546; the round's own `git diff --stat aa57bfe1c e7dc20a43 -- toolchain
core`: 3 files, +448/-75).

| Finding | Severity | Disposition | Where |
| --- | --- | --- | --- |
| RR3-1-M1 = RR3r2-M1: `PerInstantiationWalk` tested only the kind of each entry it reached and never an entry's operands, so a template named through a concrete operand of an entry was missed. Across libraries, a checked generic, a generic class's method or a blanket impl's method whose body calls a function template whose declaration holds an action (c1 to c4, e1), and a class template as a specific's argument, a tuple element or a field beside one of type `T` (a1 to a5, b2, b3, f3, f3b, g1, g2), reported W-250's TODO and then stopped the compiler at `GetLocalGenericId`'s FATAL or at generic.cpp:239's or sem_ir/type.cpp:27's CHECK; a checked generic whose body calls a function template whose definition alone holds one (d1, d2) stopped at `TryResolveInstCanonical`'s InstValue FATAL, because `TryFinishSpecific` imported the definition values of a specific whose generic's definition was not imported; the comments at import_ref.cpp:955-957 and :1111-1113, D-TP-14 and the PR body said no error reaches an eval block | MAJOR | Fixed in 68102438e, d54c37f91 and ada45a7c6 (D-TP-14 amended): the walk follows each instruction's type and operands, the generic and arguments of each specific, each interface and named constraint of a facet type with its specific and the types and values its constraints name, and the function (its declaration), class, interface, named constraint or impl (its declaration and definition) that an operand names; `TryFinishSpecific` leaves the definition of a specific whose generic's definition is resolved for each instantiation empty, as `TryFinishGeneric` leaves the generic's; and the file records what each walk that reaches no action reached (`Context::PerInstantiationWalkCache`), because the wider walk raised the gate's time across threads from 102.6 s to 127.2 s, and with the record the gate takes 91.8 s. The 19 probes and the fixer's 13 more (an array, struct or tuple element, a rewrite constraint's value, a `where .Self impls` constraint's argument, an interface member's return type, a blanket impl's witness as a specific's argument, a struct field of a generic class and a checked generic calling one constrained by such an interface) report the TODO with no crash; trunk and the nightly stop all 32 at `TryResolveInstCanonical`'s SpliceInst FATAL, and each compiles in one file on all three. Eleven fail_todo_import.carbon splits; mutants M51 to M67 and the redefined M43 and M50; the comments are rewritten | Outcome (a), TR-17, §1.2 D-TP-14, §1.8, §1.14, §2.7, §3, §4, §8, Appendix A, Appendix E, ledger W-250 and W-271 |
| RR3r2-m1 (records only): the records said the nightly stops n01, n02, n03 and p1 at `TryResolveInstCanonical`'s FATAL | MINOR | Folded, reproduced: the nightly stops n01, n02, n03, p1 and the checked twin n07 at import_ref.cpp:1168's CHECK and n05 and p2 to p9 at the FATAL (:4875), and trunk stops all thirteen at the FATAL (:5087); the golden's `_nested_class_field_type` and `_nested_class_method_declaration` splits stop the nightly at :1168 too, and trunk at the FATAL and at generic.cpp:420's CHECK. D-TP-14, round 2's RR2r2-M1 row and W-250's evidence are amended; 94227d82c's message, which says the nightly stops them at the FATAL, is not rewritten | §1.2 D-TP-14, round 2's table, ledger W-250 |
| RR3r2-m2 (records only): the PR body's round-2 probe summary said that trunk and the nightly reach all 21 of the fork's crashes; trunk and the nightly reject two of the 18 W-263 crashes, b06c and b06_type_members, where the function is defined | MINOR | Folded into the PR body with the review's text, reproduced: the fork stops both at lower.cpp:48's CHECK, and trunk and the nightly reject both with ``does not support tuple indexing`` | PR body |

Measured at the head (§8 "Measured at the focused re-review of the fold,
round 3"), container-built, EXPECTED, not of record: gate 1955 of 1955 files;
conformance 137/0/22 over 159, 48 of 56 bullets PASS; every mutant killed but
the seven recorded as surviving, M44, M52, M56, M60, M62, M64 and M65, whose
paths others cover; no clang-tidy diagnostic on the round's changed lines;
the 110 cross-library probes as §8 gives them. W-271's evidence line is re-cited
to the head, import_ref.cpp:1423 (:1287 at aa57bfe1c). The id re-scan of the
front matter, re-run on 2026-10-19 (21:13 UTC, the container clock) after `git
fetch origin` (origin/trunk is f3156a375): 81 refs match the patterns and 79
remain after TP-1's two are excluded, and the three commands print what
round 2's runs printed: `W-274`, `W-275` and `W-294` from trunk's ORCHESTRATION
paragraph that reserves W-267 to W-274 for this re-review and W-275 to W-294 for
SV-1; that file on refs/heads/trunk, refs/remotes/origin/trunk and
refs/remotes/origin/claude/carbon-fork-0-1-7mwfb7; and nothing. No other
workstream took an id. `git merge-tree` of the head with trunk f3156a375 and
each held PR reproduces the PR body's conflict table: context.h and
import_ref.cpp merge cleanly with every one. Not run, as §8 item 8 says: hosted
CI, Bazel and its tests, ASan, macOS and Windows, LLVM with assertions and the
owner's runner; and the land-time items, which wait for PR 51 to PR 60.

Round 3's status: not dry in either review, and its fixer changed two
toolchain source files (check/context.h and check/import_ref.cpp) and one
golden (check generic/template's fail_todo_import.carbon; `git diff --stat
aa57bfe1c e7dc20a43 -- toolchain core fork/conformance/programs`). Round 4 is
owed: two fresh reviews of the round-3 fixer's commits
68102438e..e7dc20a43 and the records commit after them, which changes records
only. The PR opens and is held after a round with no BLOCKER or MAJOR
finding whose fixer changes no toolchain file. fork/ORCHESTRATION.md's TP-1
Branches row reads "IMPLEMENTED AND HELD, RE-REVIEW ROUND 4 OWED" until a
round is dry (amended 2026-10-15, focused re-review of the fold: all round-3
findings).

## Appendix A: golden sources

Added 2026-10-14 (review fold: B-M1). Each file below is the complete
AUTOUPDATE source, without CHECK lines; the fill writes the CHECK lines.
Sources marked "measured" were autoupdated on v13 (§0.8) and check, fail or
lower as §4 says; "hand-predicted" sources need C3's action kinds.

### A: check/generic/template/initialize.carbon

C1, measured (on v13; the three splits after
`nontemplate_call_in_template_literal` were added at rev 3 and measured on
v14, amended 2026-10-14, review fold: RR-M1). The nine splits from
`return_tuple_constant_element` on are the first fix commit's (7c7b1b170),
measured (amended 2026-10-14, implementation-review fold: IR1-B1).

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/initialize.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/initialize.carbon

// --- return_tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}
//@dump-sem-ir-end

fn Use() -> (i32, i32) {
  return Dup(4 as i32);
}

// --- return_struct.carbon
library "[[@TEST_NAME]]";

fn Mk[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = x};
}

fn Use() -> {.a: i32, .b: i32} {
  return Mk(5 as i32);
}

// --- return_array.carbon
library "[[@TEST_NAME]]";

fn Two[template T: type](x: T) -> array(T, 2) {
  return (x, x);
}

fn Use() -> array(i32, 2) {
  return Two(4 as i32);
}

// --- class_method_return_tuple.carbon
library "[[@TEST_NAME]]";

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Use(h: H(i32)) -> (i32, i32) {
  return h.Both();
}

// --- return_param_tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Id[template T: type](p: T) -> T {
  return p;
}
//@dump-sem-ir-end

fn Use(t: (i32, i32)) -> (i32, i32) {
  return Id(t);
}

// --- copy_struct.carbon
library "[[@TEST_NAME]]";

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Use(s: {.x: i32, .y: i32}) -> i32 {
  return Id(s).y;
}

// --- returned_var_tuple.carbon
library "[[@TEST_NAME]]";

fn Mk[template T: type](x: T) -> (T, T) {
  returned var r: (T, T) = (x, x);
  return var;
}

fn Use() -> (i32, i32) {
  return Mk(2 as i32);
}

// --- value_param_return_tuple.carbon
library "[[@TEST_NAME]]";

fn F(template N: i32) -> (i32, i32) {
  return (N, N);
}

fn Use() -> (i32, i32) {
  return F(3);
}

// --- return_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

//@dump-sem-ir-begin
fn G[template T: type](x: T) -> ((T, T), i32) {
  return (Pair(x), 1);
}
//@dump-sem-ir-end

fn Use() -> ((i32, i32), i32) {
  return G(3 as i32);
}

// --- return_two_calls.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Quad[template T: type](x: T) -> ((T, T), (T, T)) {
  return (Pair(x), Pair(x));
}

fn Use() -> ((i32, i32), (i32, i32)) {
  return Quad(3 as i32);
}

// --- return_nested_literal.carbon
library "[[@TEST_NAME]]";

fn Quad[template T: type](x: T) -> ((T, T), T) {
  return ((x, x), x);
}

fn Use() -> ((i32, i32), i32) {
  return Quad(3 as i32);
}

// --- var_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((T, T), T) {
  var y: ((T, T), T) = (Pair(x), x);
  return y;
}

fn Use() -> ((i32, i32), i32) {
  return G(3 as i32);
}

// --- var_dependent_type_from_literal_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn H(template U: type, template T: type, x: T) -> U {
  var y: U = (Pair(x), x);
  return y;
}

fn Use() -> ((i32, i32), i32) {
  return H(((i32, i32), i32), i32, 4);
}

// --- return_struct_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> {.a: (T, T), .b: T} {
  return {.a = Pair(x), .b = x};
}

fn Use() -> {.a: (i32, i32), .b: i32} {
  return G(3 as i32);
}

// --- class_method_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

class H(template T: type) {
  var a: T;
  fn Both(self) -> ((T, T), T) { return (Pair(self.a), self.a); }
}

fn Use(h: H(i32)) -> ((i32, i32), i32) {
  return h.Both();
}

// --- nontemplate_call_in_template_literal.carbon
library "[[@TEST_NAME]]";

fn PairI(x: i32) -> (i32, i32) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((i32, i32), (T, T)) {
  return (PairI(1), (x, x));
}

fn Use() -> ((i32, i32), (i32, i32)) {
  return G(3 as i32);
}

// --- let_class_value_of_call.carbon
library "[[@TEST_NAME]]";

class C {
  var a: (i32, i32);
  var b: i32;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

//@dump-sem-ir-begin
fn G[template T: type](x: T) -> i32 {
  let c: C = {.a = Pair(x), .b = 1};
  return c.a.0 + c.a.1 + c.b;
}
//@dump-sem-ir-end

fn Use() -> i32 {
  return G(3 as i32);
}

// --- let_array_value_of_calls.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> T {
  let a: array((T, T), 2) = (Pair(x), Pair(x));
  return a[1].0;
}

fn Use() -> i32 {
  return G(5 as i32);
}

// --- fail_class_value_unexpected_field.carbon
library "[[@TEST_NAME]]";

class C {
  var a: (i32, i32);
  var b: i32;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> i32 {
  let c: C = {.a = Pair(x), .c = 1};
  return c.b;
}

// --- return_struct_convert.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> {.a: i64} {
  return x;
}

fn Use(s: {.a: i32}) -> {.a: i64} {
  return F(s);
}

// --- var_with_destructor.carbon
library "[[@TEST_NAME]]";

class D {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n + 10}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

//@dump-sem-ir-begin
fn F[template T: type](x: T) -> i32 {
  var unused y: T = x;
  return 0;
}
//@dump-sem-ir-end

fn Use(d: D) -> i32 {
  return F(d);
}

// --- destructure_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}
//@dump-sem-ir-end

fn Use(t: (i32, i32)) -> i32 {
  return Sum(t);
}

// --- destructure_member.carbon
library "[[@TEST_NAME]]";

class Outer {
  var inner: (i32, i32);
}

fn F[template T: type](x: T) -> i32 {
  let (a: i32, b: i32) = x.inner;
  return a + b;
}

fn Use(o: Outer) -> i32 {
  return F(o);
}

// --- return_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn M[template T: type](x: T) -> (T, T) {
  return (x, 1);
}
//@dump-sem-ir-end

fn Use() -> (i32, i32) {
  return M(4 as i32);
}

// --- return_struct_constant_field.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = 2};
}

fn Use() -> {.a: i32, .b: i32} {
  return M(4 as i32);
}

// --- return_array_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> array(T, 2) {
  return (x, 3);
}

fn Use() -> array(i32, 2) {
  return M(4 as i32);
}

// --- var_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> (T, T) {
  var p: (T, T) = (x, 1);
  return p;
}

fn Use() -> (i32, i32) {
  return M(4 as i32);
}

// --- assign_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T, y: T) -> (T, T) {
  var t: (T, T) = (x, y);
  t = (x, 1);
  return t;
}

fn Use() -> (i32, i32) {
  return M(4 as i32, 9 as i32);
}

// --- return_nested_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> ((T, T), T) {
  return ((x, 2), 3);
}

fn Use() -> ((i32, i32), i32) {
  return M(4 as i32);
}

// --- template_value_element.carbon
library "[[@TEST_NAME]]";

fn M(template N: i32, x: i32) -> (i32, i32) {
  return (N, x);
}

fn Use() -> (i32, i32) {
  return M(3, 4);
}

// --- return_class_constant_field.carbon
library "[[@TEST_NAME]]";

class P(T: type) {
  var a: T;
  var b: T;
}

fn M[template T: type](x: T) -> P(T) {
  return {.a = x, .b = 1};
}

fn Use() -> P(i32) {
  return M(4 as i32);
}

// --- var_class_constant_field.carbon
library "[[@TEST_NAME]]";

class P(T: type) {
  var a: T;
  var b: T;
}

fn M[template T: type](x: T) -> T {
  var p: P(T) = {.a = x, .b = 2};
  return p.b;
}

fn Use() -> i32 {
  return M(4 as i32);
}
```

<!-- google-doc-style-resume -->

### A: check/generic/template/for_range.carbon

C1, measured.

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/for_range.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/for_range.carbon

// --- range_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}
//@dump-sem-ir-end

// --- range_param_called_array.carbon
library "[[@TEST_NAME]]";

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Use(a: array(i32, 3)) -> i32 {
  return Sum(a);
}

// --- range_member_array.carbon
library "[[@TEST_NAME]]";

class W {
  var a: array(i32, 3);
}

fn F[template T: type](w: T) -> i32 {
  var s: i32 = 0;
  for (e: i32 in w.a) {
    s += e;
  }
  return s;
}

fn Use(w: W) -> i32 {
  return F(w);
}

// --- range_core_range.carbon
library "[[@TEST_NAME]]";

class W {
  var n: i32;
}

fn Count[template T: type](w: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in Core.Range(w.n)) {
    s += x;
  }
  return s;
}

fn Use(w: W) -> i32 {
  return Count(w);
}

// --- range_dependent_bound.carbon
library "[[@TEST_NAME]]";

fn Sum(template N: i32, a: array(i32, N)) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Use(a: array(i32, 3)) -> i32 {
  return Sum(3, a);
}
```

<!-- google-doc-style-resume -->

### A: lower/template/initialize.carbon

C1, measured (on v13; `let_class_value_of_call` was added at rev 3 and
measured on v14, amended 2026-10-14, review fold: RR-M1). The nine splits from
`return_tuple_constant_element` on are the first fix commit's (7c7b1b170),
measured (amended 2026-10-14, implementation-review fold: IR1-B1). The last two,
`return_tuple_of_associated_type` and `var_tuple_of_associated_type`, are the
focused re-review's first fix commit's (632f92117), measured (amended
2026-10-15, focused re-review of the fold: RR1-M2). The last six, from
`var_class_with_dependent_array_bound`, are its round 2's (b678e2985),
measured (amended 2026-10-15, focused re-review of the fold: RR2-1-M2).

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/initialize.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/initialize.carbon

// --- return_param_tuple.carbon
library "[[@TEST_NAME]]";

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Use(t: (i32, i32)) -> (i32, i32) {
  return Id(t);
}

// --- return_tuple.carbon
library "[[@TEST_NAME]]";

fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Use() -> (i32, i32) {
  return Dup(4 as i32);
}

// --- class_method_return_tuple.carbon
library "[[@TEST_NAME]]";

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Use(h: H(i32)) -> (i32, i32) {
  return h.Both();
}

// --- return_tuple_of_call.carbon
library "[[@TEST_NAME]]";

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((T, T), i32) {
  return (Pair(x), 1);
}

fn Use() -> ((i32, i32), i32) {
  return G(3 as i32);
}

// --- let_class_value_of_call.carbon
library "[[@TEST_NAME]]";

class C {
  var a: (i32, i32);
  var b: i32;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> i32 {
  let c: C = {.a = Pair(x), .b = 1};
  return c.a.0 + c.a.1 + c.b;
}

fn Use() -> i32 {
  return G(3 as i32);
}

// --- return_struct_convert.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> {.a: i64} {
  return x;
}

fn Use(s: {.a: i32}) -> {.a: i64} {
  return F(s);
}

// --- var_with_destructor.carbon
library "[[@TEST_NAME]]";

class D {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n + 10}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn F[template T: type](x: T) -> i32 {
  var unused y: T = x;
  return 0;
}

fn Use(d: D) -> i32 {
  return F(d);
}

// --- destructure_param.carbon
library "[[@TEST_NAME]]";

fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}

fn Use(t: (i32, i32)) -> i32 {
  return Sum(t);
}

// --- return_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> (T, T) {
  return (x, 1);
}

fn Use() -> (i32, i32) {
  return M(4 as i32);
}

// --- return_struct_constant_field.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = 2};
}

fn Use() -> {.a: i32, .b: i32} {
  return M(4 as i32);
}

// --- return_array_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> array(T, 2) {
  return (x, 3);
}

fn Use() -> array(i32, 2) {
  return M(4 as i32);
}

// --- var_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> (T, T) {
  var p: (T, T) = (x, 1);
  return p;
}

fn Use() -> (i32, i32) {
  return M(4 as i32);
}

// --- assign_tuple_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T, y: T) -> (T, T) {
  var t: (T, T) = (x, y);
  t = (x, 1);
  return t;
}

fn Use() -> (i32, i32) {
  return M(4 as i32, 9 as i32);
}

// --- return_nested_constant_element.carbon
library "[[@TEST_NAME]]";

fn M[template T: type](x: T) -> ((T, T), T) {
  return ((x, 2), 3);
}

fn Use() -> ((i32, i32), i32) {
  return M(4 as i32);
}

// --- template_value_element.carbon
library "[[@TEST_NAME]]";

fn M(template N: i32, x: i32) -> (i32, i32) {
  return (N, x);
}

fn Use() -> (i32, i32) {
  return M(3, 4);
}

// --- return_class_constant_field.carbon
library "[[@TEST_NAME]]";

class P(T: type) {
  var a: T;
  var b: T;
}

fn M[template T: type](x: T) -> P(T) {
  return {.a = x, .b = 1};
}

fn Use() -> P(i32) {
  return M(4 as i32);
}

// --- var_class_constant_field.carbon
library "[[@TEST_NAME]]";

class P(T: type) {
  var a: T;
  var b: T;
}

fn M[template T: type](x: T) -> T {
  var p: P(T) = {.a = x, .b = 2};
  return p.b;
}

fn Use() -> i32 {
  return M(4 as i32);
}

// --- return_tuple_of_associated_type.carbon
library "[[@TEST_NAME]]";

interface Container {
  let Elem: type;
  fn Get(self) -> Elem;
}

class Ints {
  var n: i32;
  impl as Container where .Elem = i32 {
    fn Get(self) -> i32 { return self.n; }
  }
}

fn F[template T: Container](x: T) -> (T.Elem, i32) {
  return (x.Get(), 5);
}

fn Use(n: Ints) -> (i32, i32) {
  return F(n);
}

// --- var_tuple_of_associated_type.carbon
library "[[@TEST_NAME]]";

interface Container {
  let Elem: type;
}

class Ints {
  impl as Container where .Elem = i32 {}
}

fn G[template T: Container](unused x: T) -> i32 {
  var t: (T.Elem, i32) = (4, 5);
  return t.1;
}

fn Use(n: Ints) -> i32 {
  return G(n);
}

// --- var_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  var c: Arr(N) = {.a = (x, 2, 3), .n = N};
  return c.n;
}

fn Use() -> i32 {
  return M(3, 1);
}

// --- return_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> Arr(N) {
  return {.a = (4, x, 6), .n = N};
}

fn Use() -> Arr(3) {
  return M(3, 5);
}

// --- var_struct_of_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  var s: {.c: Arr(N), .d: i32} = {.c = {.a = (x, 2, 3), .n = N}, .d = x};
  return s.d;
}

fn Use() -> i32 {
  return M(3, 1);
}

// --- var_tuple_of_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  var t: (Arr(N), i32) = ({.a = (1, 2, x), .n = N}, x);
  return t.1;
}

fn Use() -> i32 {
  return M(3, 1);
}

// --- var_array_of_class_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  var v: array(Arr(N), 2) = ({.a = (x, 2, 3), .n = N}, {.a = (4, 5, 6), .n = x});
  return v[1].n;
}

fn Use() -> i32 {
  return M(3, 1);
}

// --- let_class_value_with_template_value_field.carbon
library "[[@TEST_NAME]]";

class P(template N: i32) {
  var a: i32;
  var b: i32;
}

fn M(template N: i32, x: i32) -> i32 {
  let p: P(N) = {.a = x, .b = N};
  return p.a;
}

fn Use() -> i32 {
  return M(3, 1);
}
```

<!-- google-doc-style-resume -->

### A: lower/template/for_range.carbon

C1, measured.

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/for_range.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/for_range.carbon

// --- range_param_called_array.carbon
library "[[@TEST_NAME]]";

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Use(a: array(i32, 3)) -> i32 {
  return Sum(a);
}
```

<!-- google-doc-style-resume -->

### A: check/generic/template/fail_todo_import.carbon

C2, measured. `Holder`, `Elem` and `Pick` in `lib.carbon` and the two
`_declaration` splits are the second fix commit's (12bd6d67a), measured (amended
2026-10-14, implementation-review fold: IR1-M2). `FieldBox`, `MethodBox`,
`PickI`, `PickC` and `WithMethod` in `lib.carbon` and the last five splits are
the focused re-review's (d8f6ab60a), measured (amended 2026-10-15, focused
re-review of the fold: RR1-M1 / RR2-M1). `Outer`, `OuterMethod`, `Constrained`,
`TakesWithMethod`, `Marker` and its impl, `NeedsMarker`, `K`, `NamesFieldBox`
and `BodyNamesFieldBox` in `lib.carbon` and the last seven splits are its round
2's (94227d82c), measured (amended 2026-10-15, focused re-review of the fold:
RR2r2-M1 / RR2r2-m1). `HasItem` and its impl, `TakesItem`, `CallsTakesItem`,
`NamesItem`, `CallsNamesItem`, `ItemDoer` and its impl, `FieldBoxField`, `Pair`,
`TakesPair`, `TakesTuple`, `WithArg`, `ConstrainedByWithArg`, `MarkerArg`,
`TakesMarkerArg`, `TakesStruct` and `ConstrainedByRewrite` in `lib.carbon` and
the last eleven splits are its round 3's (68102438e, ada45a7c6), measured
(amended 2026-10-15, focused re-review of the fold: RR3-1-M1 / RR3r2-M1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/fail_todo_import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/fail_todo_import.carbon

// --- lib.carbon
library "[[@TEST_NAME]]";

fn Twice[template T: type](x: T) -> T {
  return x;
}

class Box(template T: type) {
  var v: T;
  fn Get(self) -> T { return self.v; }
}

fn Plain(x: ()) -> () {
  return x;
}

class Holder {
  alias Item = ();
  var item: ();
}

fn Elem[template T: type](x: T) -> T.Item {
  return x.item;
}

class Pick(template T: type, unused U: T.Item) {}

class FieldBox(template T: type) {
  var item: T.Item;
}

class MethodBox(template T: type) {
  var t: T;
  fn Get(self) -> T.Item { return self.t.item; }
}

interface PickI(template T: type, unused U: T.Item) {}

constraint PickC(template T: type, unused U: T.Item) {}

interface WithMethod(template T: type) {
  fn F() -> T.Item;
}

class Outer(template T: type) {
  class Inner(unused U: type) {
    var x: T.Item;
  }
}

class OuterMethod(template T: type) {
  class Inner(unused U: type) {
    fn F() -> T.Item;
  }
}

fn Constrained[V: WithMethod(Holder)](unused v: V) {}

fn TakesWithMethod(unused x: WithMethod(Holder)) {}

interface Marker {}

impl forall [V: WithMethod(Holder)] V as Marker {}

fn NeedsMarker[T: Marker](unused t: T) {}

class K {
  impl as WithMethod(Holder) {
    fn F() -> () { return (); }
  }
}

fn NamesFieldBox[T: type](unused p: FieldBox(T)*) {}

fn BodyNamesFieldBox[T: type](unused t: T) {
  FieldBox(T);
}

interface HasItem {
  let Item: type;
}

impl Holder as HasItem where .Item = () {}

fn TakesItem[template T: HasItem](unused x: T, unused p: T.Item*) {}

fn CallsTakesItem[T: HasItem](t: T, p: T.Item*) {
  TakesItem(t, p);
}

fn NamesItem[template T: HasItem](unused x: T) {
  T.Item;
}

fn CallsNamesItem[T: HasItem](t: T) {
  NamesItem(t);
}

interface ItemDoer(P: type) {
  fn Do(self, p: P);
}

impl forall [T: HasItem] T as ItemDoer(T.Item*) {
  fn Do(self, p: T.Item*) {
    TakesItem(self, p);
  }
}

class FieldBoxField(T: type) {
  var t: T;
  var p: FieldBox(Holder)*;
}

class Pair(unused A: type, unused B: type) {}

fn TakesPair[T: type](unused p: Pair(T, FieldBox(Holder))*) {}

fn TakesTuple[T: type](unused p: (T, FieldBox(Holder)*)*) {}

interface WithArg(unused U: type) {}

fn ConstrainedByWithArg[T: WithArg(FieldBox(Holder))](unused t: T) {}

class MarkerArg(unused A: type, unused B: Marker) {}

fn TakesMarkerArg[T: type](unused p: MarkerArg(T, K)*) {}

fn TakesStruct[T: type](unused p: {.a: T, .b: FieldBox(Holder)*}*) {}

fn ConstrainedByRewrite[T: HasItem where .Item = FieldBox(Holder)*](unused t: T) {}

// --- fail_todo_import_function.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> () {
  return Twice(());
}

// --- fail_todo_import_class.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(b: Box(())) -> () {
  return b.Get();
}

// --- import_unused.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() -> () {
  return Plain(());
}

// --- fail_todo_import_function_declaration.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(h: Holder) -> () {
  return Elem(h);
}

// --- fail_todo_import_class_declaration.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(unused p: Pick(Holder, ())) {}

// --- fail_todo_import_class_field_type.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(unused b: FieldBox(Holder)) {}

// --- fail_todo_import_class_method_declaration.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(b: MethodBox(Holder)) -> () {
  return b.Get();
}

// --- fail_todo_import_interface_declaration.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(unused x: PickI(Holder, ())) {}

// --- fail_todo_import_constraint_declaration.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use[V: PickC(Holder, ())](unused v: V) {}

// --- fail_todo_import_interface_member_declaration.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(unused x: WithMethod(Holder)) {}

// --- fail_todo_import_nested_class_field_type.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(unused o: Outer(Holder)*) {}

// --- fail_todo_import_nested_class_method_declaration.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(unused o: OuterMethod(Holder)*) {}

// --- fail_todo_import_function_constrained_by_template_interface.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(k: K) {
  Constrained(k);
}

// --- fail_todo_import_function_parameter_of_template_interface_type.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  TakesWithMethod;
}

// --- fail_todo_import_impl_constrained_by_template_interface.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(k: K) {
  NeedsMarker(k);
}

// --- fail_todo_import_function_declaration_names_class_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  NamesFieldBox;
}

// --- fail_todo_import_function_definition_names_class_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(h: Holder) {
  BodyNamesFieldBox(h);
}

// --- fail_todo_import_function_definition_calls_function_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(h: Holder, p: ()*) {
  CallsTakesItem(h, p);
}

// --- fail_todo_import_function_definition_calls_function_template_definition.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(h: Holder) {
  CallsNamesItem(h);
}

// --- fail_todo_import_impl_method_calls_function_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(h: Holder, p: ()*) {
  h.(ItemDoer(()*).Do)(p);
}

// --- fail_todo_import_class_field_names_class_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(unused f: FieldBoxField(())*) {}

// --- fail_todo_import_function_declaration_names_class_template_in_class_argument.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  TakesPair;
}

// --- fail_todo_import_function_declaration_names_class_template_in_tuple.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  TakesTuple;
}

// --- fail_todo_import_function_constrained_by_interface_of_class_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  ConstrainedByWithArg;
}

// --- fail_todo_import_function_declaration_names_impl_of_template_interface.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  TakesMarkerArg;
}

// --- fail_todo_import_function_declaration_names_class_template_in_struct.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  TakesStruct;
}

// --- fail_todo_import_function_constrained_by_rewrite_to_class_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use() {
  ConstrainedByRewrite;
}

// --- fail_todo_import_two_uses_name_class_template.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Use(p: ((), FieldBox(Holder)*)*) {
  TakesTuple(p);
}
```

<!-- google-doc-style-resume -->

### A: check/generic/template/pointer.carbon

C3, hand-predicted; `deref_pointer_param` and `fail_deref_class_type_param` take
the eager path and were measured on v13. `fail_deref_class_type_param` is added
by C4, measured at implementation, and the three splits after
`fail_deref_non_pointer_on_instantiation` are the second fix commit's
(12bd6d67a) (amended 2026-10-14, implementation-review fold: IR2-MINOR-3 /
IR1-m3 / IR2-MINOR-8). The last two are the focused re-review's (632f92117),
measured (amended 2026-10-15, focused re-review of the fold: RR1-B1).

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/pointer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/pointer.carbon

// --- deref_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Deref[template T: type](p: T) -> i32 {
  return *p;
}
//@dump-sem-ir-end

fn Use(n: i32*) -> i32 {
  return Deref(n);
}

// --- arrow_member.carbon
library "[[@TEST_NAME]]";

class Node {
  var n: i32;
}

class Link {
  var p: Node*;
}

fn Next[template T: type](x: T) -> i32 {
  return x.p->n;
}

fn Use(link: Link) -> i32 {
  return Next(link);
}

// --- addr_of_member.carbon
library "[[@TEST_NAME]]";

class Counter {
  var n: i32;
}

//@dump-sem-ir-begin
fn Read[template T: type](ref x: T) -> i32 {
  let p: i32* = &x.n;
  return *p;
}
//@dump-sem-ir-end

fn Use(ref c: Counter) -> i32 {
  return Read(ref c);
}

// --- deref_pointer_param.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: T*) -> T {
  return *p;
}

fn Use(n: i32*) -> i32 {
  return Deref(n);
}

// --- fail_deref_class_type_param.carbon
library "[[@TEST_NAME]]";

class C(T: type) {
  var item: T;
}

fn F[template T: type](c: C(T)) -> T {
  return *c;
}

// --- fail_deref_non_pointer_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Use(n: i32) -> i32 {
  return Deref(n);
}

// --- deref_const_param.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: const T) -> i32 {
  return *p;
}

fn Use(n: i32*) -> i32 {
  return Deref(n as const (i32*));
}

// --- fail_arrow_non_pointer_on_instantiation.carbon
library "[[@TEST_NAME]]";

class Node {
  var n: i32;
}

fn Next[template T: type](x: T) -> i32 {
  return x->n;
}

fn Use(node: Node) -> i32 {
  return Next(node);
}

// --- fail_addr_of_value_on_instantiation.carbon
library "[[@TEST_NAME]]";

class Counter {
  var n: i32;
}

fn Read[template T: type](x: T) -> i32 {
  let p: i32* = &x.n;
  return *p;
}

fn Use(c: Counter) -> i32 {
  return Read(c);
}

// --- fail_deref_as_type_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](p: T) -> i32 {
  let unused a: *p = 1;
  return 0;
}

fn Use(p: type*) -> i32 {
  return F(p);
}

// --- fail_pointee_type_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn MakeT(unused n: i32) -> type { return i32; }

fn F[template T: type](x: T, y: i32*) -> i32 {
  let unused a: MakeT(x)* = y;
  return 0;
}

fn Use(n: i32, p: i32*) -> i32 {
  return F(n, p);
}
```

<!-- google-doc-style-resume -->

### A: check/generic/template/index.carbon

C3, hand-predicted; `index_class_with_index_with` takes the eager path and was
measured on v13 (it runs and prints 6 as a program, where trunk cannot deduce
`T`). `index_class_with_index_with` is added by C4, measured at implementation,
and the four splits after `fail_index_non_indexable_on_instantiation` are the
second fix commit's (12bd6d67a) (amended 2026-10-14, implementation-review fold:
IR2-MINOR-3 / IR1-m3 / IR1-M1 / IR1-m2). The focused re-review adds the five
splits from `fail_tuple_index_as_type_on_instantiation` to
`fail_array_element_type_on_instantiation` and `template_value_as_type`
(632f92117), the four from
`fail_tuple_index_as_type_of_used_binding_on_instantiation` to
`fail_tuple_index_as_var_type_on_instantiation` (ba64734e7), and `class D`,
`interface Container` and the redeclarations H to N of
`fail_redecl_differs_in_dependent_operation` (73b3124dd), all measured (amended
2026-10-15, focused re-review of the fold: RR1-B1 / RR1-m1 / RR2-m6). Round 2
adds `interface J` and the redeclarations R, S and U to that split
(123eb40ca) and the two splits after
`fail_tuple_index_as_var_type_on_instantiation` (2165322c5), all measured
(amended 2026-10-15, focused re-review of the fold: RR2-1-M1 / RR2-1-m1).

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/index.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/index.carbon

// --- tuple_index_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Second[template T: type](p: T) -> i32 {
  return p.1;
}
//@dump-sem-ir-end

fn Use(t: (i32, i32)) -> i32 {
  return Second(t);
}

// --- array_index_param.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn At1[template T: type](a: T) -> i32 {
  return a[1];
}
//@dump-sem-ir-end

fn Use(a: array(i32, 3)) -> i32 {
  return At1(a);
}

// --- class_member_array_index.carbon
library "[[@TEST_NAME]]";

class Holder(template T: type) {
  var item: T;
  fn First(self) -> i32 { return self.item[0]; }
}

fn Use(h: Holder(array(i32, 2))) -> i32 {
  return h.First();
}

// --- index_class_with_index_with.carbon
library "[[@TEST_NAME]]";

class Vec(T: type) {
  var tag: i32;
  impl as Core.IndexWith(i32) where .ElementType = i32 {
    fn At(self, unused i: i32) -> i32 { return self.tag; }
  }
}

//@dump-sem-ir-begin
fn Get[template T: type](v: Vec(T), i: i32) -> i32 {
  return v[i];
}
//@dump-sem-ir-end

fn Use(v: Vec(bool)) -> i32 {
  return Get(v, 0);
}

// --- fail_tuple_index_non_tuple_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn Use(n: i32) -> i32 {
  return Second(n);
}

// --- fail_index_non_indexable_on_instantiation.carbon
library "[[@TEST_NAME]]";

class Empty {}

fn At1[template T: type](a: T) -> i32 {
  return a[1];
}

fn Use(e: Empty) -> i32 {
  return At1(e);
}

// --- fail_tuple_index_const_param_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn Second[template T: type](p: const T) -> i32 {
  return p.1;
}

fn Use(t: (i32, i32)) -> i32 {
  return Second(t as const (i32, i32));
}

// --- tuple_index_associated_type.carbon
library "[[@TEST_NAME]]";

interface Container {
  let Elem: type;
  fn Get(self) -> Elem;
}

class Pairs {
  var p: (i32, i32);
  impl as Container where .Elem = (i32, i32) {
    fn Get(self) -> (i32, i32) { return self.p; }
  }
}

//@dump-sem-ir-begin
fn First[template T: Container](x: T) -> i32 {
  let e: T.Elem = x.Get();
  return e.0;
}
//@dump-sem-ir-end

fn Use(c: Pairs) -> i32 {
  return First(c);
}

// --- fail_index_in_array_bound_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn Make(template T: type, template a: T) -> i32 {
  var r: array(i32, a[0]);
  r[0] = 5;
  return r[0];
}

fn Use() -> i32 {
  return Make(array(i32, 1), (1,));
}

// --- fail_redecl_differs_in_dependent_operation.carbon
library "[[@TEST_NAME]]";

class C(N: i32) {}

class D(Q: i32*) {}

interface Container {
  let Elem: type;
  let Other: type;
}

interface J {
  fn G(self) -> i32;
}

fn F(template T: type, template v: T) -> array(i32, v.0);
fn F(template T: type, template v: T) -> array(i32, v.1);

fn G(template P: type, template p: P) -> C(*p);
fn G(template P: type, template p: P) -> C(p[0]);

fn H(template P: type, template p: P) -> C(*p[0]);
fn H(template P: type, template p: P) -> C((*p)[0]);

fn K(template T: type, template v: T) -> C(-v.0);
fn K(template T: type, template v: T) -> C(-v.1);

fn L[template T: Container](x: T) -> T.(Container.Elem);
fn L[template T: Container](x: T) -> T.(Container.Other);

fn M(template P: type, template p: P) -> D(&p.n);
fn M(template P: type, template p: P) -> D(&p.m);

fn N(template P: type, template p: P) -> C(p->n);
fn N(template P: type, template p: P) -> C(p->m);

fn R(template P: type, template p: P) -> C(*p->q);
fn R(template P: type, template p: P) -> C(*(*p).q);

fn S(template P: type, template p: P) -> C((**p).n);
fn S(template P: type, template p: P) -> C((*p)->n);

fn U(template P: type, template p: P) -> C(p->(J.G)());
fn U(template P: type, template p: P) -> C((*p).(J.G)());

// --- fail_tuple_index_as_type_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> i32 {
  let unused a: x.0 = 1;
  return 0;
}

fn Use(t: (type, type)) -> i32 {
  return F(t);
}

// --- fail_index_as_type_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> i32 {
  let unused a: x[0] = 1;
  return 0;
}

fn Use(a: array(type, 1)) -> i32 {
  return F(a);
}

// --- fail_tuple_type_element_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> i32 {
  let unused a: (x.0, i32) = (1, 2);
  return 0;
}

fn Use(t: (type, type)) -> i32 {
  return F(t);
}

// --- fail_struct_type_field_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> i32 {
  let unused a: {.p: x.0, .q: i32} = {.p = 5, .q = 7};
  return 0;
}

fn Use(t: (type, type)) -> i32 {
  return F(t);
}

// --- fail_array_element_type_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn MakeT(unused n: i32) -> type { return i32; }

fn F[template T: type](x: T) -> i32 {
  let unused a: array(MakeT(x), 1) = (1,);
  return 0;
}

fn Use(n: i32) -> i32 {
  return F(n);
}

// --- fail_tuple_index_as_type_of_used_binding_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> i32 {
  let a: x.0 = 1;
  return a;
}

fn Use(t: (type, type)) -> i32 {
  return F(t);
}

// --- fail_tuple_index_as_conversion_target_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> i32 {
  return 2 as x.0;
}

fn Use(t: (type, type)) -> i32 {
  return F(t);
}

// --- fail_tuple_index_as_return_type_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> x.0 {
  return 1;
}

fn Use(t: (type, type)) {
  F(t);
}

// --- fail_tuple_index_as_var_type_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> i32 {
  var a: x.0;
  a = 1;
  return a;
}

fn Use(t: (type, type)) -> i32 {
  return F(t);
}

// --- fail_array_type_two_runtime_operands_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> i32 {
  var a: array(x.0, x.1);
  return a[0];
}

fn Use(t: (type, i32)) -> i32 {
  return F(t);
}

// --- fail_tuple_type_two_runtime_elements_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> i32 {
  let p: (x.0, x.1) = (1, 2);
  return p.1;
}

fn Use(t: (type, type)) -> i32 {
  return F(t);
}

// --- template_value_as_type.carbon
library "[[@TEST_NAME]]";

fn F(template t: (type, type)) -> i32 {
  let a: t.0 = 5;
  let b: (t.1, i32) = (6, 7);
  return a + b.0 + b.1;
}

fn G(template s: {.p: type}) -> i32 {
  let a: s.p = 4;
  return a;
}

fn Use() -> i32 {
  return F((i32, i32)) + G({.p = i32});
}
```

<!-- google-doc-style-resume -->

### A: lower/template/pointer_index.carbon

C3, hand-predicted.

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/pointer_index.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/pointer_index.carbon

// --- deref_param.carbon
library "[[@TEST_NAME]]";

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Use(n: i32*) -> i32 {
  return Deref(n);
}

// --- addr_of_member.carbon
library "[[@TEST_NAME]]";

class Counter {
  var n: i32;
}

fn Bump[template T: type](ref x: T) -> i32 {
  let q: i32* = &x.n;
  *q += 1;
  return x.n;
}

fn Use(ref c: Counter) -> i32 {
  return Bump(ref c);
}

// --- tuple_index_param.carbon
library "[[@TEST_NAME]]";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn Use(t: (i32, i32)) -> i32 {
  return Second(t);
}

// --- array_index_param.carbon
library "[[@TEST_NAME]]";

fn At1[template T: type](a: T) -> i32 {
  return a[1];
}

fn Use(a: array(i32, 3)) -> i32 {
  return At1(a);
}
```

<!-- google-doc-style-resume -->

### A: lower/template/dependent_call.carbon

C3; its body was measured as a program on v13, which prints 8.

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/dependent_call.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/dependent_call.carbon

// --- call_function_typed_value.carbon
library "[[@TEST_NAME]]";

fn Apply[template G: type](h: G, x: i32) -> i32 {
  return h(x);
}

fn Twice(x: i32) -> i32 {
  return 2 * x;
}

fn Use() -> i32 {
  return Apply(Twice, 4);
}
```

<!-- google-doc-style-resume -->

### A: check/generic/template/call_wrong_arg_type.carbon

C3, measured.

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/convert.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/call_wrong_arg_type.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/call_wrong_arg_type.carbon

// --- fail_dependent_call_nonconst_arg_wrong_type.carbon
library "[[@TEST_NAME]]";

class X {}
class Y {}
fn F[template G: type](H: G, x: X) {
  H(x);
}
fn TakeY(unused y: Y) {}

fn BadCall(x: X) { F(TakeY, x); }
```

<!-- google-doc-style-resume -->

### A: check/generic/template/deduce_class_args.carbon

C4, measured. The last four splits are the focused re-review's round 2's
(b678e2985), measured (amended 2026-10-15, focused re-review of the
fold: RR2-1-M2).

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/deduce_class_args.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/deduce_class_args.carbon

// --- holder.carbon
library "[[@TEST_NAME]]";

class Holder(T: type) {
  var item: T;
}

//@dump-sem-ir-begin
fn GetTemplate[template T: type](h: Holder(T)) -> T {
  return h.item;
}
//@dump-sem-ir-end

fn Use(h: Holder(i32)) -> i32 {
  return GetTemplate(h);
}

// --- holder_copy_constraint.carbon
library "[[@TEST_NAME]]";

class Holder(T: Core.Copy) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Use(h: Holder(i32)) -> i32 {
  return Get(h);
}

// --- holder_pointer.carbon
library "[[@TEST_NAME]]";

class Holder(T: type) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)*) -> T {
  return h->item;
}

fn Use(h: Holder(i32)*) -> i32 {
  return Get(h);
}

// --- vec_value_param.carbon
library "[[@TEST_NAME]]";

class Vec(template N: i32) {
  var a: i32;
}

fn Size[template N: i32](unused v: Vec(N)) -> i32 {
  return N;
}

fn Use(v: Vec(3)) -> i32 {
  return Size(v);
}

// --- template_class_type.carbon
library "[[@TEST_NAME]]";

class Holder(template T: type) {
  var item: T;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Use(h: Holder(i32)) -> i32 {
  return Get(h);
}

// --- class_argument_expression.carbon
library "[[@TEST_NAME]]";

class Vec(N: i32) {
  var tag: i32;
}

fn Size(template N: i32, v: Vec(N + 1)) -> i32 {
  return N + v.tag;
}

fn Use(v: Vec(4)) -> i32 {
  return Size(3, v);
}

// --- class_argument_return_type.carbon
library "[[@TEST_NAME]]";

class Vec(N: i32) {
  var tag: i32;
}

fn Make(template M: Core.IntLiteral) -> Vec(M) {
  return {.tag = 1};
}

fn Use() -> Vec(3) {
  return Make(3);
}

// --- class_template_literal_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Make(template N: i32, x: i32) -> i32 {
  var c: Arr(N) = {.a = (x, 2, 3), .n = N};
  return c.n;
}

fn Use() -> i32 {
  return Make(3, 1);
}

// --- class_template_return_with_dependent_array_bound.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Make(template N: i32) -> Arr(N) {
  return {.a = (4, 5, 6), .n = N};
}

fn Use() -> Arr(3) {
  return Make(3);
}

// --- fail_class_template_literal_with_dependent_array_bound_count_on_instantiation.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Make(template N: i32) -> i32 {
  var c: Arr(N) = {.a = (1, 2), .n = N};
  return c.n;
}

fn Use() -> i32 {
  return Make(3);
}

// --- fail_class_template_literal_with_dependent_array_bound_unknown_field.carbon
library "[[@TEST_NAME]]";

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Make(template N: i32) -> i32 {
  var c: Arr(N) = {.a = (1, 2, 3), .m = N};
  return c.n;
}
```

<!-- google-doc-style-resume -->

### A: check/generic/template/default_init.carbon

C4, measured. The last two splits are the second fix commit's (12bd6d67a),
D-TP-12's interface-side pins (amended 2026-10-14, implementation-review fold:
IR1-m1 / IR2-MAJOR-1).

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/default_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/default_init.carbon

// --- var_uninit.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F[template T: type](x: T) -> T {
  var y: T;
  y = x;
  return y;
}
//@dump-sem-ir-end

fn Use() -> i32 {
  return F(5 as i32);
}

// --- class_method_var_uninit.carbon
library "[[@TEST_NAME]]";

class Stack(template T: type) {
  var top: T;
  fn Peek(self) -> T {
    var y: T;
    y = self.top;
    return y;
  }
}

fn Use(s: Stack(i32)) -> i32 {
  return s.Peek();
}

// --- fail_var_uninit_tuple_on_instantiation.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](x: T) -> T {
  var y: T;
  y = x;
  return y;
}

fn Use(t: (i32, i32)) -> (i32, i32) {
  return F(t);
}

// --- template_interface_concrete_self.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Widen(template U: type, x: i32) -> U {
  return x;
}
//@dump-sem-ir-end

fn Use(x: i32) -> i64 {
  return Widen(i64, x);
}

// --- template_interface_facet_value.carbon
library "[[@TEST_NAME]]";

interface Tag(T: type) {}
class W {}
impl i32 as Tag(W) {}

fn F(template U: type) {
  let unused t: Tag(U) = i32;
}

fn Use() {
  F(W);
}

// --- template_interface_final_impl.carbon
library "[[@TEST_NAME]]";

interface Tag(T: type) {
  fn Id() -> i32;
}
final impl forall [T: type] i32 as Tag(T) {
  fn Id() -> i32 { return 3; }
}

//@dump-sem-ir-begin
fn Get[template U: type](unused u: U) -> i32 {
  return (i32 as Tag(U)).Id();
}
//@dump-sem-ir-end

fn Use() -> i32 {
  return Get(true);
}
```

<!-- google-doc-style-resume -->

### A: check/generic/template/constraint_lookup.carbon

C5, measured with the prototype's TODO in place of the diagnostic. The last
split, W-266's pin, is the second fix commit's (12bd6d67a) (amended 2026-10-14,
implementation-review fold: IR1-M3).

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/generic/template/constraint_lookup.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/generic/template/constraint_lookup.carbon

// --- constraint_only.carbon
library "[[@TEST_NAME]]";

interface HasArea {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  impl as HasArea {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Use(q: Square) -> i32 {
  return Report(q);
}

// --- extend_impl_same_entity.carbon
library "[[@TEST_NAME]]";

interface HasArea {
  fn Area(self) -> i32;
}

class Rect {
  var w: i32;
  var h: i32;
  extend impl as HasArea {
    fn Area(self) -> i32 { return self.w * self.h; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Use(r: Rect) -> i32 {
  return Report(r);
}

// --- type_only_member.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var v: i32;
  fn G(unused self) -> i32 { return 7; }
  impl as A {
    fn F(unused self) -> i32 { return 2; }
  }
}

fn H[template T: A](x: T) -> i32 {
  return x.G() * 10 + x.F();
}

fn Use(c: C) -> i32 {
  return H(c);
}

// --- field_not_in_constraint.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var n: i32;
  impl as A {
    fn F(unused self) -> i32 { return 2; }
  }
}

fn H[template T: A](x: T) -> i32 {
  return x.n;
}

fn Use(c: C) -> i32 {
  return H(c);
}

// --- round_widget_alias.carbon
library "[[@TEST_NAME]]";

interface Renderable {
  fn Draw(self) -> i32;
}

class RoundWidget {
  var n: i32;
  impl as Renderable {
    fn Draw(self) -> i32 { return self.n; }
  }
  alias Draw = Renderable.Draw;
}

fn DrawTemplate[template T: Renderable](c: T) -> i32 {
  return c.Draw();
}

fn Use(r: RoundWidget) -> i32 {
  return DrawTemplate(r);
}

// --- square_widget_impl_alias.carbon
library "[[@TEST_NAME]]";

interface Renderable {
  fn Draw(self) -> i32;
}

class SquareWidget {
  var n: i32;
  fn Draw(self) -> i32 { return self.n * 2; }
}

impl SquareWidget as Renderable {
  alias Draw = SquareWidget.Draw;
}

fn DrawTemplate[template T: Renderable](c: T) -> i32 {
  return c.Draw();
}

fn Use(s: SquareWidget) -> i32 {
  return DrawTemplate(s);
}

// --- fail_different_entities.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var v: i32;
  fn F(unused self) -> i32 { return 1; }
  impl as A {
    fn F(unused self) -> i32 { return 2; }
  }
}

fn G[template T: A](x: T) -> i32 {
  return x.(A.F)() * 10 + x.F();
}

fn Use(c: C) -> i32 {
  return G(c);
}

// --- fail_cowboy.carbon
library "[[@TEST_NAME]]";

interface Renderable {
  fn Draw(self) -> i32;
}

class Cowboy {
  var n: i32;
  fn Draw(unused self) -> i32 { return 1; }
}

impl Cowboy as Renderable {
  fn Draw(unused self) -> i32 { return 2; }
}

fn DrawTemplate[template T: Renderable](c: T) -> i32 {
  return c.Draw();
}

fn Use(c: Cowboy) -> i32 {
  return DrawTemplate(c);
}

// --- fail_field_vs_constraint_method.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var F: i32;
  impl as A {
    fn F(unused self) -> i32 { return 2; }
  }
}

fn H[template T: A](x: T) -> i32 {
  return x.F;
}

fn Use(c: C) -> i32 {
  return H(c);
}

// --- fail_todo_field_of_template_class.carbon
library "[[@TEST_NAME]]";

interface A {
  fn F(self) -> i32;
}

class C {
  var n: i32;
  impl as A {
    fn F(self) -> i32 { return self.n; }
  }
}

class W(template T: A) {
  var c: T;
  fn Go(self) -> i32 { return self.c.F(); }
}

fn Use(w: W(C)) -> i32 {
  return w.Go();
}
```

<!-- google-doc-style-resume -->

### A: changes to existing goldens

Each change edits the source lines outside CHECK lines; the fill rewrites the
CHECK lines.

-   check/testdata/generic/template/call.carbon (C3): the first split becomes
    `dependent_call_nonconst_arg.carbon` with the same body and no STDERR;
    the split `fail_dependent_call_nonconst_arg_wrong_type.carbon` moves to
    call_wrong_arg_type.carbon above, without its `// TODO: should fail, but
    not because of UseOfNonExprAsValue` line; and this split is added after
    the first:

<!-- google-doc-style-ignore -->

```carbon
// --- dependent_call_two_callees.carbon
library "[[@TEST_NAME]]";

class X {}
fn F[template G: type](H: G, x: X) {
  H(x);
}
fn TakeX(unused x: X) {}
fn AlsoTakeX(unused x: X) {}

fn GoodCalls(x: X) {
  F(TakeX, x);
  F(AlsoTakeX, x);
}
```

<!-- google-doc-style-resume -->

-   check/testdata/generic/template/unimplemented.carbon (C3): the two splits
    become the first and third below (bodies kept, comments restated), and the
    second is added:

<!-- google-doc-style-ignore -->

```carbon
// --- deref_dependent_member.carbon

library "[[@TEST_NAME]]";

// A dereference of a template-dependent expression is checked when the
// template is instantiated.
fn F[template T: type](x: T) {
  *x.n;
}

// --- fail_deref_dependent_member_non_pointer.carbon

library "[[@TEST_NAME]]";

class C {
  var n: i32;
}

fn F[template T: type](x: T) {
  *x.n;
}

fn G(c: C) {
  F(c);
}

// --- deref_dependent_value.carbon

library "[[@TEST_NAME]]";

class C {
  var n: i32;
}

// `c.n` uses the value of a template parameter, so a dereference of it is
// checked when the template is instantiated (proposal 2200, "Use of dependent
// value is dependent").
fn F(template c: C) {
  *c.n;
}
```

<!-- google-doc-style-resume -->

-   check/testdata/generic/template/member_out_of_line.carbon (C2): the line
    `// --- fail_todo_basic.carbon` becomes `// --- fail_basic.carbon`.
-   F6: PR 51's interop/cpp/template/dependent_var_full_prelude.carbon: the
    line `// --- fail_todo_unformed_dependent_var.carbon` becomes
    `// --- unformed_dependent_var.carbon`.

## Appendix B: conformance programs

Added 2026-10-14 (review fold: B-M1 / B-M4 / B-m3 / B-m5 / A-m6). The eight
programs and the C++ oracle of commit P, complete. Six were run on v13 and
print their EXPECT lines (the differential program prints
`8 10 8 6 9 4 5 7 7`, as its oracle does when compiled with the toolchain's
`clang++ -std=c++17 -pthread`); templates_dependent_pointer and
templates_dependent_index need C3 and were checked against their concrete
baselines, which print `4 7 8` and `5 2 8`.

### B: generics/templates_dependent_pointer.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   7
//   8
//
// Proposal 2200 ("Use of dependent value is dependent"): `*`, `->` and `&`
// on a template-dependent operand are checked when the template is
// instantiated (TP-1, fork/templates/plan.md; DD-1 fixtures X13, X14, X15).
// Deref(&n) reads n = 4; Next(link) reads link.p->n = node.n = 7; Bump(ref
// node) adds 1 to node.n through &node.n and returns 8. The same functions
// with the types written out print the same three lines.

import Core library "io";

class Node {
  var n: i32;
}

class Link {
  var p: Node*;
}

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Next[template T: type](x: T) -> i32 {
  return x.p->n;
}

fn Bump[template T: type](ref x: T) -> i32 {
  let q: i32* = &x.n;
  *q += 1;
  return x.n;
}

fn Run() -> i32 {
  var n: i32 = 4;
  Core.Print(Deref(&n));
  var node: Node = {.n = 7};
  let link: Link = {.p = &node};
  Core.Print(Next(link));
  Core.Print(Bump(ref node));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: generics/templates_dependent_index.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   2
//   8
//
// Proposal 2200 ("Use of dependent value is dependent"): tuple element access
// and indexing on a template-dependent operand are checked when the template
// is instantiated, as a tuple access and an array index (TP-1; DD-1 fixtures
// X16, X19, X24). Element 1 of (4, 5) is 5; element 1 of (1, 2, 3) is 2;
// element 0 of the class member (8, 9) is 8. The same code with the types
// written out prints the same three lines.

import Core library "io";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn At1[template T: type](a: T) -> i32 {
  return a[1];
}

class Holder(template T: type) {
  var item: T;
  fn First(self) -> i32 { return self.item[0]; }
}

fn Run() -> i32 {
  let t: (i32, i32) = (4, 5);
  Core.Print(Second(t));
  let a: array(i32, 3) = (1, 2, 3);
  Core.Print(At1(a));
  let h: Holder(array(i32, 2)) = {.item = (8, 9)};
  Core.Print(h.First());
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: generics/templates_return_aggregates_diff.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
//
// Proposal 2200: returning, copying and destructuring values whose types are
// built from template parameters, checked and lowered for each instantiation
// (TP-1, fork/templates/plan.md; DD-1 fixtures X29 to X33 and probe PR-AK,
// which printed values that changed from run to run). Differential pair:
// templates_return_aggregates_diff.diff.cpp computes the expected lines with
// the same templates in C++17 (no EXPECT-STDOUT). Dup(4) sums 4 + 4 = 8;
// Mk(5) sums 5 + 5 = 10; Two(4) sums 4 + 4 = 8; H(i32).Both with a = 3 sums
// 3 + 3 = 6; Sum((4, 5)) is 9; Id((4, 5)) prints 4 then 5; Id of
// {.x = 6, .y = 7} has .y = 7; G(3) returns ((3, 3), 1), which sums to 7.

import Core library "io";

fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Mk[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = x};
}

fn Two[template T: type](x: T) -> array(T, 2) {
  return (x, x);
}

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Pair[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn G[template T: type](x: T) -> ((T, T), i32) {
  return (Pair(x), 1);
}

fn Run() -> i32 {
  let t: (i32, i32) = Dup(4 as i32);
  Core.Print(t.0 + t.1);
  let s: {.a: i32, .b: i32} = Mk(5 as i32);
  Core.Print(s.a + s.b);
  let a: array(i32, 2) = Two(4 as i32);
  Core.Print(a[0] + a[1]);
  let h: H(i32) = {.a = 3};
  let u: (i32, i32) = h.Both();
  Core.Print(u.0 + u.1);
  let p: (i32, i32) = (4, 5);
  Core.Print(Sum(p));
  let r: (i32, i32) = Id(p);
  Core.Print(r.0);
  Core.Print(r.1);
  let q: {.x: i32, .y: i32} = {.x = 6, .y = 7};
  Core.Print(Id(q).y);
  let n: ((i32, i32), i32) = G(3 as i32);
  Core.Print(n.0.0 + n.0.1 + n.1);
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: generics/templates_return_aggregates_diff.diff.cpp

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential oracle for templates_return_aggregates_diff.carbon: the same
// templates in C++17, printing as Core.Print does (printf "%d\n").

#include <array>
#include <cstdio>
#include <tuple>

struct AB {
  int a;
  int b;
};

struct XY {
  int x;
  int y;
};

template <typename T>
auto Dup(T x) -> std::tuple<T, T> {
  return {x, x};
}

template <typename T>
auto Mk(T x) -> AB {
  return {x, x};
}

template <typename T>
auto Two(T x) -> std::array<T, 2> {
  return {x, x};
}

template <typename T>
struct H {
  T a;
  auto Both() const -> std::tuple<T, T> { return {a, a}; }
};

template <typename T>
auto Sum(T p) -> int {
  auto [a, b] = p;
  return a + b;
}

template <typename T>
auto Id(T p) -> T {
  return p;
}

template <typename T>
auto Pair(T x) -> std::tuple<T, T> {
  return {x, x};
}

template <typename T>
auto G(T x) -> std::tuple<std::tuple<T, T>, int> {
  return {Pair(x), 1};
}

auto main() -> int {
  auto t = Dup(4);
  std::printf("%d\n", std::get<0>(t) + std::get<1>(t));
  AB s = Mk(5);
  std::printf("%d\n", s.a + s.b);
  auto a = Two(4);
  std::printf("%d\n", a[0] + a[1]);
  H<int> h = {3};
  auto u = h.Both();
  std::printf("%d\n", std::get<0>(u) + std::get<1>(u));
  std::tuple<int, int> p = {4, 5};
  std::printf("%d\n", Sum(p));
  auto r = Id(p);
  std::printf("%d\n", std::get<0>(r));
  std::printf("%d\n", std::get<1>(r));
  XY q = {6, 7};
  std::printf("%d\n", Id(q).y);
  auto n = G(3);
  std::printf("%d\n", std::get<0>(std::get<0>(n)) +
                          std::get<1>(std::get<0>(n)) + std::get<1>(n));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: generics/templates_for_dependent_range.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   6
//   10
//   12
//
// Proposal 2200: a `for` loop whose range depends on a template parameter is
// checked when the template is instantiated (TP-1; DD-1 fixture X28, which
// stopped the compiler). Sum over the array (1, 2, 3) is 6; CountUp over
// Core.Range(5), which yields 0 to 4 (core/prelude/range.carbon), is 10;
// SumMember over the member array (7, 2, 3) is 12.

import Core library "io";

class Counter {
  var n: i32;
}

class Wrapper {
  var a: array(i32, 3);
}

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn CountUp[template T: type](c: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in Core.Range(c.n)) {
    s += x;
  }
  return s;
}

fn SumMember[template T: type](w: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in w.a) {
    s += x;
  }
  return s;
}

fn Run() -> i32 {
  let a: array(i32, 3) = (1, 2, 3);
  Core.Print(Sum(a));
  let c: Counter = {.n = 5};
  Core.Print(CountUp(c));
  let w: Wrapper = {.a = (7, 2, 3)};
  Core.Print(SumMember(w));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: generics/templates_dependent_call.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   8
//   25
//
// Proposal 2200 (p002200:735-737: calling a function needs only its type)
// and proposal 2875 (each function has its own type): a value whose type is a
// template parameter is called, with the function its type names (TP-1; DD-1
// fixture X17). Apply(Twice, 4) is 2 x 4 = 8; Apply(Square, 5) is 5 x 5 = 25.

import Core library "io";

fn Apply[template G: type](h: G, x: i32) -> i32 {
  return h(x);
}

fn Twice(x: i32) -> i32 {
  return 2 * x;
}

fn Square(x: i32) -> i32 {
  return x * x;
}

fn Run() -> i32 {
  Core.Print(Apply(Twice, 4));
  Core.Print(Apply(Square, 5));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: generics/templates_constraint_lookup.carbon

The headers of this program, templates_deduce_class_args and
templates_dependent_var no longer name W-183, W-193 and W-127, which are not on
this branch in the held state; they keep DD-1's fixture names, which resolve
when PR 58 lands, as D's landed notes record (amended 2026-10-14,
implementation-review fold: IR2-MINOR-11).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   25
//   6
//
// Proposal 2200 ("Name lookup", p002200:433-441, :476-503): a member of a
// value whose type is a constrained template parameter is looked up in the
// argument type and in the constraint (TP-1; DD-1 fixture R09). Square
// provides Area only through `impl as HasArea`, so the
// constraint finds it: 5 x 5 = 25. Rect's `extend impl` makes the type and
// the constraint find the same function: 2 x 3 = 6.

import Core library "io";

interface HasArea {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  impl as HasArea {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

class Rect {
  var w: i32;
  var h: i32;
  extend impl as HasArea {
    fn Area(self) -> i32 { return self.w * self.h; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Run() -> i32 {
  let q: Square = {.side = 5};
  Core.Print(Report(q));
  let r: Rect = {.w = 2, .h = 3};
  Core.Print(Report(r));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: generics/templates_deduce_class_args.carbon

The class `Arr`, the functions `SumArr` and `MakeArr` and the lines `16` and
`8` are the focused re-review's round 2's (b678e2985), hand-derived (R16(d)) and
measured (amended 2026-10-15, focused re-review of the fold: RR2-1-M2).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   21
//   42
//   3
//   16
//   8
//
// Proposal 2200 (p002200:186-191: template parameters are deduced as checked
// ones are): a deduced template parameter is deduced through a class's
// arguments (TP-1; DD-1 fixture X25). Get(h) is the item, 21; GetThrough(&h)
// reads the item through the pointer, and the program
// doubles it, 42; Size(v) is the deduced N of Vec(3), 3. A class template's
// array field whose bound is the template parameter is initialized from a
// list on instantiation (TP-1): SumArr(3, 10) adds the first and third
// elements of `(10, 2, 3)` and N, 10 + 3 + 3, 16; MakeArr(3) returns such a
// class value, whose second element and N sum to 5 + 3, 8.

import Core library "io";

class Holder(T: type) {
  var item: T;
}

class Vec(template N: i32) {
  var tag: i32;
}

class Arr(template N: i32) {
  var a: array(i32, N);
  var n: i32;
}

fn Get[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn GetThrough[template T: type](h: Holder(T)*) -> T {
  return h->item;
}

fn Size[template N: i32](unused v: Vec(N)) -> i32 {
  return N;
}

fn SumArr(template N: i32, x: i32) -> i32 {
  var c: Arr(N) = {.a = (x, 2, 3), .n = N};
  return c.a[0] + c.a[2] + c.n;
}

fn MakeArr(template N: i32) -> Arr(N) {
  return {.a = (4, 5, 6), .n = N};
}

fn Run() -> i32 {
  var h: Holder(i32) = {.item = 21};
  Core.Print(Get(h));
  Core.Print(GetThrough(&h) * 2);
  let v: Vec(3) = {.tag = 0};
  Core.Print(Size(v));
  Core.Print(SumArr(3, 10));
  let m: Arr(3) = MakeArr(3);
  Core.Print(m.a[1] + m.n);
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: generics/templates_dependent_var.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   6
//   11
//   0
//   1
//
// Proposal 2200 (p002200:198-199: impl lookup waits for the template
// arguments) and "Use of dependent value is dependent": a `var` of a template
// parameter's type, with or without an initializer (TP-1; DD-1 fixtures X20
// and X23). Swap(4, 5) assigns its second argument into
// y and returns 5; Peek returns top = 6. Keep(d) copies d into y with
// D's Copy, which adds 10 (n = 11), and y's destructor prints 11 when Keep
// returns, before Run prints Keep's result 0; d itself is destroyed when Run
// returns and prints 1. The same functions with D written out print the same
// lines.

import Core library "io";

class D {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n + 10}; }
  }
  impl as Core.Destroy {
    fn Op(ref self) { Core.Print(self.n); }
  }
}

fn Swap[template T: type](unused a: T, b: T) -> T {
  var y: T;
  y = b;
  return y;
}

class Stack(template T: type) {
  var top: T;
  fn Peek(self) -> T {
    var y: T;
    y = self.top;
    return y;
  }
}

fn Keep[template T: type](x: T) -> i32 {
  var unused y: T = x;
  return 0;
}

fn Run() -> i32 {
  Core.Print(Swap(4 as i32, 5 as i32));
  let s: Stack(i32) = {.top = 6};
  Core.Print(s.Peek());
  let d: D = {.n = 1};
  Core.Print(Keep(d));
  return 0;
}
```

<!-- google-doc-style-resume -->

### B: generics/templates_constant_elements.carbon

Added by the first fix commit (7c7b1b170) (amended 2026-10-14,
implementation-review fold: IR1-B1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   41
//   42
//   43
//   41
//   41
//   423
//   34
//   41
//   42
//
// Proposal 2200 ("Use of dependent value is dependent"): an initializer whose
// elements mix a template-dependent value with a constant initializes every
// element, as the same initializer does without a template (TP-1, the
// implementation-review fold). Each line prints the first element times 10
// plus the second: `(x, 1)` returned, `{.a = x, .b = 2}` returned and
// `(x, 3)` returned as an array, with x = 4, give 41, 42 and 43; a `var` of
// `(x, 1)` gives 41; a `var` initialized with `(x, 9)` and then assigned
// `(x, 1)` gives 41; `((x, 2), 3)` prints its three elements as 423; a
// template value `N = 3` beside the runtime 4 gives 34; a class `P(T)`
// returned from `{.a = x, .b = 1}` gives 41, and a `var` of `P(T)` from
// `{.a = x, .b = 2}` gives 42.

import Core library "io";

class P(T: type) {
  var a: T;
  var b: T;
}

fn RetTuple[template T: type](x: T) -> (T, T) {
  return (x, 1);
}

fn RetStruct[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = 2};
}

fn RetArray[template T: type](x: T) -> array(T, 2) {
  return (x, 3);
}

fn VarTuple[template T: type](x: T) -> T {
  var p: (T, T) = (x, 1);
  return p.0 * 10 + p.1;
}

fn Assign[template T: type](x: T, y: T) -> (T, T) {
  var t: (T, T) = (x, y);
  t = (x, 1);
  return t;
}

fn Nested[template T: type](x: T) -> ((T, T), T) {
  return ((x, 2), 3);
}

fn Value(template N: i32, x: i32) -> (i32, i32) {
  return (N, x);
}

fn RetClass[template T: type](x: T) -> P(T) {
  return {.a = x, .b = 1};
}

fn VarClass[template T: type](x: T) -> T {
  var p: P(T) = {.a = x, .b = 2};
  return p.a * 10 + p.b;
}

fn Run() -> i32 {
  let t: (i32, i32) = RetTuple(4 as i32);
  Core.Print(t.0 * 10 + t.1);
  let s: {.a: i32, .b: i32} = RetStruct(4 as i32);
  Core.Print(s.a * 10 + s.b);
  let a: array(i32, 2) = RetArray(4 as i32);
  Core.Print(a[0] * 10 + a[1]);
  Core.Print(VarTuple(4 as i32));
  let u: (i32, i32) = Assign(4 as i32, 9 as i32);
  Core.Print(u.0 * 10 + u.1);
  let n: ((i32, i32), i32) = Nested(4 as i32);
  Core.Print(n.0.0 * 100 + n.0.1 * 10 + n.1);
  let v: (i32, i32) = Value(3, 4);
  Core.Print(v.0 * 10 + v.1);
  let c: P(i32) = RetClass(4 as i32);
  Core.Print(c.a * 10 + c.b);
  Core.Print(VarClass(4 as i32));
  return 0;
}
```

<!-- google-doc-style-resume -->

## Appendix C: commit L, the PR 58 integration texts

Added 2026-10-14 (review fold: B-B1 / B-M2 / B-M3 / A-M2). The page edits are
given as the unified diff that `$X/sim/l/apply_l.py` produces on fcee90d9b's
docs/design/templates.md, with the land date `YYYY-MM-DD` set to 2026-10-20
for the run; L uses its own date. The fixtures follow, complete, then the
`SAMPLES` lines. The run of PR 58's checker on the result is §2.9's.

### C: docs/design/templates.md

<!-- google-doc-style-ignore -->

````diff
--- a/docs/design/templates.md
+++ b/docs/design/templates.md
@@ -51,6 +51,13 @@
 > predicates. Member requirements are implemented on the fork's held
 > template-constraint branch (SC-1), and `require` blocks and predicates are
 > fork work item W-028; none of them is in the toolchain this page describes.
+>
+> **Fork note (TP-1, 2026-10-20).** The integrated-templates work (TP-1)
+> resolved many of the limits listed in
+> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain), and of the
+> fork notes in the sketch; each resolved limit and note keeps its text and is
+> marked resolved, with the date, and the limits measured after TP-1 are
+> listed with them.

 ## Overview

@@ -89,6 +96,10 @@
 > [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain) compiles and
 > runs; the next note and the limits listed there show uses of `T` in such a
 > class that are rejected or that stop the compiler.
+> (Amended by TP-1, 2026-10-20: the uses that the next note shows now compile
+> and run; an out-of-line definition of such a class's member whose signature
+> names a member of `T`, such as `T.U`, is still rejected even when it is
+> written exactly as the declaration, fork work item W-254.)

 > **Fork note (2026-10-14).** In the 0.1 toolchain, not every use of `T` in the
 > definition waits for instantiation, and not every use that waits succeeds. A
@@ -102,6 +113,12 @@
 > `Core.IndexWith(Core.IntLiteral)` in type `array(i32, 2)` that does not
 > implement that interface`` (W-192), although an `array(i32, 2)` member can be
 > indexed in a class without a template parameter.
+>
+> **Fork note (TP-1, 2026-10-20).** Both forms in the note above are resolved:
+> `Peek` on a `Stack(i32)` whose `top` is 6 returns 6, with impl lookup for
+> `T` delayed until the method is instantiated, and `First` on a
+> `Holder(array(i32, 2))` holding `(8, 9)` returns 8, indexing the array
+> member as an array.

 ### Functions with template parameters

@@ -148,6 +165,11 @@
 > same declaration with a checked parameter, `[T: Core.Copy]`, deduces `T` as
 > `i32`; a parameter of type `Holder(T)*`, or `Vec(N)` for
 > `class Vec(template N: i32)`, behaves the same (fork work item W-193).
+>
+> **Fork note (TP-1, 2026-10-20).** The deduction is implemented:
+> `GetTemplate(h)` deduces `T` as `i32` from `Holder(T)`, as the checked
+> declaration does, and the `Holder(T)*` and `Vec(N)` forms deduce `T` and
+> `N` the same way.

 ### Overloading

@@ -194,6 +216,19 @@
 tuple element access, indexing an array, copying a struct, calls, `for` loops,
 and returning a tuple.

+> **Fork note (TP-1, 2026-10-20).** Since these limits were measured, the
+> toolchain also resolves for each instantiation the pointer operators `*`,
+> `->`, and `&`, tuple element access, indexing, struct copies, calls of a
+> value whose type is a template parameter, `for` loops over a
+> template-dependent range, returning a tuple, struct, or array built from a
+> template parameter, destructuring a template-dependent tuple, `var y: T;`,
+> member lookup into a constrained template parameter, and deduction through a
+> class's arguments. The limits below that it resolved are marked resolved;
+> the limits measured after TP-1 are added to the groups they belong to,
+> among them `for` loops whose cursor is a tuple or a class, and returning
+> some structs whose field is itself a struct or tuple, which still stop the
+> compiler or are compiled wrongly.
+
 ```carbon
 import Core library "io";

@@ -308,10 +343,28 @@
     without `extend` whose `F` differs, and `x.F()` in
     `fn G[template T: A](x: T)`, proposal 2200 rejects the call when `G` is
     instantiated, but the toolchain calls the type's member.
+    (Resolved by TP-1, 2026-10-20: when `G` is instantiated, the name is
+    looked up in the argument type and in the constraint, and a member that
+    only the constraint provides is found, as the example below shows; where
+    the two give the name different meanings, the call reports
+    ``unable to monomorphize specific `G(C as A)` `` with the note
+    ``member name `F` names different entities in type `C` and in its
+    constraint `A` ``.)
+-   Proposal 2200 also gives a member access the constraint's meaning where
+    the function is defined, when the constraint has the name: the toolchain
+    checks such an access only when the function is called, so
+    `let b: bool = x.F();` for an `F` of the constraint that returns `i32` is
+    accepted in a definition that is never called, and a name that two
+    interfaces of the constraint both declare is not reported as ambiguous
+    there (fork work items W-260 and W-261). `T.F()` for a type parameter calls
+    the constraint's `F` without comparing it with the type's own member of
+    that name (W-262).

 For example:

 ```carbon
+import Core library "io";
+
 interface HasArea {
   fn Area(self) -> i32;
 }
@@ -327,13 +380,18 @@
   return s.Area();
 }

-fn Use(q: Square) -> i32 {
-  return Report(q);
+fn Run() -> i32 {
+  let q: Square = {.side = 5};
+  Core.Print(Report(q));
+  return 0;
 }
 ```

-This reports ``unable to monomorphize specific `Report(Square as HasArea)` ``
-with the note ``member name `Area` not found in `Square` ``.
+This prints `25`: `s.Area()` finds `Area` in the constraint `HasArea`.
+(Amended by TP-1, 2026-10-20: before TP-1, the same declarations with
+`fn Use(q: Square) -> i32 { return Report(q); }` in place of `Run` reported
+``unable to monomorphize specific `Report(Square as HasArea)` `` with the note
+``member name `Area` not found in `Square` ``.)

 As the accepted design specifies, an interface constraint is satisfied only by
 types that implement the interface: for a class `Circle` with an `Area` method
@@ -354,6 +412,10 @@
     expression`` (fork work item W-014; `generic/template/unimplemented.carbon`
     in the toolchain's check tests pins the dereference as `fail_todo`). Each
     compiles in a function without a template parameter.
+    (Resolved by TP-1, 2026-10-20: each is checked when the call is
+    instantiated: `Deref(&n)` returns 4 for `var n: i32 = 4`, `Next(link)`
+    returns 4 for a link to a node whose `n` is 4, `Read(ref c)` returns 4 for
+    a counter whose `n` is 4, and `Second(t)` on `(4, 5)` returns 5.)
 -   A `var` of a template parameter's type without an initializer, `var y: T;`,
     is rejected where the function is defined with ``cannot convert type `T`
     into type implementing `Core.DefaultOrUnformed` ``, where proposal 2200
@@ -361,6 +423,11 @@
     compiles (fork work item W-127, held PR 51). A method of a class with a
     template parameter is rejected the same way, as the fork note in
     [Types with template parameters](#types-with-template-parameters) shows.
+    (Resolved by TP-1, 2026-10-20: `F(5 as i32)` returns 5 for the function
+    whose body is `var y: T; y = x; return y;`; for a tuple argument, the
+    instantiation reports that `(i32, i32)` does not implement
+    `Core.DefaultOrUnformed`, as `var y: (i32, i32);` does without a template
+    parameter.)
 -   `partial T*` for a template parameter `T` is rejected with
     `` `partial` applied to final type `T` ``, as for a checked parameter,
     although whether the template argument is final is known only on
@@ -381,6 +448,8 @@
     ``unable to monomorphize specific `Apply(<type of Twice>)` `` with the note
     ``value of type `<type of Twice>` is not callable`` (W-014; pinned as
     `fail_todo` by `generic/template/call.carbon`).
+    (Resolved by TP-1, 2026-10-20: `Apply(Twice, 4)` calls `Twice` and
+    returns 8, because a function's type names the function, proposal 2875.)
 -   Copying a value whose type is a template argument of struct type, and
     indexing one of array type, fail when the call is instantiated: the
     toolchain resolves them through `Core.Copy` and `Core.IndexWith`, which
@@ -397,11 +466,20 @@
     array member in a method of a class with a template parameter fails the
     same way, as the fork note in
     [Types with template parameters](#types-with-template-parameters) shows.
+    (Resolved by TP-1, 2026-10-20: the copy and the index are chosen when the
+    call is instantiated: `Id(s).y` returns 5 for `{.x = 4, .y = 5}`, and
+    `Second(a)` on `(1, 2, 3)` returns 2.)

 Stopping the compiler, or compiled wrongly:

 -   A template function defined in one library and called from another stops
     the compiler during checking, as it does in the upstream nightly (W-014).
+    (Changed by TP-1, 2026-10-20: the compiler no longer stops; the `import`
+    of the library reports ``semantics TODO: `using a generic from another
+    library whose definition is resolved for each instantiation, such as a
+    template` `` when the importing file uses such a function or class, fork
+    work item W-250, pinned by
+    `generic/template/fail_todo_import.carbon`.)
 -   A `for` loop whose range depends on a template parameter stops the
     compiler where the function is defined, whether or not the function is
     called: for example, `for (x: i32 in a)` for a parameter `a: T`, a range
@@ -410,6 +488,8 @@
     a function without a template parameter, and a loop in a function with a
     template parameter whose range does not depend on the parameter, such as
     `Core.Range(3)`, runs (W-014). The upstream nightly stops the same way.
+    (Resolved by TP-1, 2026-10-20: each such definition compiles, and
+    `Sum(a)` on an `array(i32, 3)` holding `(1, 2, 3)` returns 6.)
 -   Returning a value of some types built from a template parameter stops
     the compiler when a call is instantiated:
     `fn Dup[template T: type](x: T) -> (T, T)` with the body `return (x, x);`,
@@ -419,12 +499,49 @@
     form. In a class `H(template T: type)`, a method
     `fn Both(self) -> (T, T)` that returns `(self.a, self.a)` stops the
     compiler while it lowers a call of the method (W-014).
+    (Resolved by TP-1, 2026-10-20: `Dup(4 as i32)` returns `(4, 4)`,
+    `Mk(5 as i32)` returns `{.a = 5, .b = 5}`, `Two(4 as i32)` returns an
+    array holding 4 and 4, and `h.Both()` returns `(3, 3)` for `h.a` = 3.
+    The struct forms that the limits measured after TP-1 list below are not
+    resolved.)
 -   A tuple value whose type is a template argument is not compiled correctly:
     on an `(i32, i32)` argument, destructuring a parameter `p: T` with
     `let (a: i32, b: i32) = p;` stops the compiler while it lowers the
     instantiation, and `fn Id[template T: type](p: T) -> T { return p; }`
     returns values other than its argument's, which differ from run to run
-    (W-014).
+    (W-014). (Resolved by TP-1, 2026-10-20: `Sum(t)` on `(4, 5)` returns 9,
+    and `Id` returns its argument.)
+-   Measured after TP-1: returning `{.a = x}` from
+    `fn F[template T: type](x: T) -> {.a: (i32, i32)}` with the body
+    `return {.a = x};` stops the compiler when the call is instantiated, as
+    the same function without a template parameter does where it is defined
+    (fork work item W-256).
+-   Measured after TP-1: a struct whose field is a struct with a single tuple
+    field is compiled wrongly. `G(3 as i32)` for
+    `fn G[template T: type](x: T) -> {.a: {.b: (T, T)}, .c: T}` with the body
+    `return {.a = {.b = (x, x)}, .c = x};` returns values that differ from
+    run to run, and so does the same function with `i32` written for `T`
+    (fork work item W-256).
+-   Measured after TP-1: a `for` loop whose range depends on a template
+    parameter stops the compiler while it lowers a call of the function when
+    the range's cursor is initialized in place, as for a range whose cursor
+    is a tuple or a class; a range whose cursor is an integer, such as an
+    array or a `Core.Range`, runs (fork work item W-264).
+-   Measured after TP-1: a class value built in a template from a struct
+    literal that leaves a field to its default initializer, such as
+    `let c: C = {.a = Pair(x)};` where `Pair` is a template that returns
+    `(T, T)` and `C`'s field `b` has the default `5`, stops the compiler
+    during checking, and the same code
+    without a template parameter stops it while it lowers the function (fork
+    work items W-264 and W-265).
+-   Measured after TP-1: a constant nested tuple or struct, such as
+    `let t: ((i32, i32), i32) = ((1, 2), 3);`, stops the compiler while it
+    verifies the generated code, with or without a template parameter, and a
+    template that copies such a value reaches the same failure (fork work item
+    W-263).
+-   Measured after TP-1: a function with a form parameter, such as
+    `fn F(template Fm: Core.Form, unused x:? Fm)` or its `generic` form, stops
+    the compiler while it lowers a call (fork work item W-255).

 Forms of proposal 2200 that are not implemented yet:

@@ -453,4 +570,10 @@
 -   A deduced template parameter is not computed from a class's arguments, as
     the fork note in
     [Functions with template parameters](#functions-with-template-parameters)
-    shows (W-193).
+    shows (W-193). (Resolved by TP-1, 2026-10-20, as the fork note there
+    says.)
+-   An assignment through a template-dependent operand is not checked when
+    the template is instantiated: assigning to a field of a `const` object
+    through a `ref` parameter of template type, or to a class's `let` member,
+    is accepted (fork work item W-259; pinned as `todo_fail` by
+    `generic/template/operator.carbon`).
````

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/R09_template_constraint_lookup.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", block
// EXPECT-STDOUT:
//   25
// QUOTE: This prints `25`: `s.Area()` finds `Area` in the constraint `HasArea`

import Core library "io";

interface HasArea {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  impl as HasArea {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

fn Report[template T: HasArea](s: T) -> i32 {
  return s.Area();
}

fn Run() -> i32 {
  let q: Square = {.side = 5};
  Core.Print(Report(q));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X13_template_deref.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   4
// QUOTE: `Deref(&n)` returns 4
// Pins the resolution, by TP-1 (fork/templates/plan.md), of the page's limit
// on prefix `*` with a template-dependent operand: `*p` is checked when
// `Deref(&n)` is instantiated for an `i32*`, and the program prints 4. Before
// TP-1 the definition was rejected with ``cannot dereference operand of
// non-pointer type `T` `` (fork work item W-014). Proposal 2200's "Use of
// dependent value is dependent" section makes the expression dependent.

import Core library "io";

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Run() -> i32 {
  var n: i32 = 4;
  Core.Print(Deref(&n));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X14_template_arrow.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   4
// QUOTE: `Next(link)` returns 4
// Pins the resolution, by TP-1, of the page's limit on `->` with a
// template-dependent operand: `x.p->n` is checked when `Next(link)` is
// instantiated, and the program prints `node.n`, 4. Before TP-1 the
// definition was rejected with ``cannot apply `->` operator to non-pointer
// type `<dependent type>` `` (fork work item W-014).

import Core library "io";

class Node {
  var n: i32;
}

class Link {
  var p: Node*;
}

fn Next[template T: type](x: T) -> i32 {
  return x.p->n;
}

fn Run() -> i32 {
  var node: Node = {.n = 4};
  let link: Link = {.p = &node};
  Core.Print(Next(link));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X15_template_address.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   4
// QUOTE: `Read(ref c)` returns 4
// Pins the resolution, by TP-1, of the page's limit on `&` with a
// template-dependent operand: `&x.n` on a `ref` parameter of template type is
// checked when `Read(ref c)` is instantiated, where `x.n` is a reference
// expression, and the program prints 4. Before TP-1 the definition was
// rejected with "cannot take the address of non-reference expression" (fork
// work item W-014).

import Core library "io";

class Counter {
  var n: i32;
}

fn Read[template T: type](ref x: T) -> i32 {
  let p: i32* = &x.n;
  return *p;
}

fn Run() -> i32 {
  var c: Counter = {.n = 4};
  Core.Print(Read(ref c));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X16_template_tuple_element.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   5
// QUOTE: `Second(t)` on `(4, 5)` returns 5
// Pins the resolution, by TP-1, of the page's limit on tuple element access
// with a template-dependent operand: `p.1` is checked when `Second(t)` is
// instantiated for `(i32, i32)`, and the program prints 5. Before TP-1 the
// definition was rejected with ``type `T` does not support tuple indexing;
// only tuples can be indexed that way`` (fork work item W-014).

import Core library "io";

fn Second[template T: type](p: T) -> i32 {
  return p.1;
}

fn Run() -> i32 {
  let t: (i32, i32) = (4, 5);
  Core.Print(Second(t));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X17_template_dependent_call.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   8
// QUOTE: `Apply(Twice, 4)` calls `Twice` and returns 8
// Pins the resolution, by TP-1, of the page's limit on calling a value whose
// type is a template parameter: `h(x)` calls the function that `G`, the type
// of `Twice`, names (proposal 2875 gives each function its own type), and the
// program prints 2 x 4. Before TP-1 the call failed when `Apply(Twice, 4)`
// was instantiated, with the note ``value of type `<type of Twice>` is not
// callable`` (fork work item W-014).

import Core library "io";

fn Apply[template G: type](h: G, x: i32) -> i32 {
  return h(x);
}

fn Twice(x: i32) -> i32 {
  return 2 * x;
}

fn Run() -> i32 {
  Core.Print(Apply(Twice, 4));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X18_template_struct_copy.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   5
// QUOTE: `Id(s).y` returns 5
// Pins the resolution, by TP-1, of the page's limit on copying a value whose
// type is a template argument of struct type: `return p;` copies the struct
// field by field when `Id` is instantiated for `{.x: i32, .y: i32}`, and the
// program prints the copy's `.y`, 5. Before TP-1 the instantiation failed
// with the note ``cannot access member of interface `Core.Copy` in type
// `{.x: i32, .y: i32}` that does not implement that interface`` (fork work
// item W-192).

import Core library "io";

fn Id[template T: type](p: T) -> T {
  return p;
}

fn Run() -> i32 {
  let s: {.x: i32, .y: i32} = {.x = 4, .y = 5};
  Core.Print(Id(s).y);
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X19_template_array_index.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   2
// QUOTE: `Second(a)` on `(1, 2, 3)` returns 2
// Pins the resolution, by TP-1, of the page's limit on indexing a value whose
// type is a template argument of array type: `a[1]` is indexed as an array
// when `Second` is instantiated for `array(i32, 3)`, and the program prints 2.
// Before TP-1 the instantiation failed with the note ``cannot access member
// of interface `Core.IndexWith(Core.IntLiteral)` in type `array(i32, 3)` that
// does not implement that interface`` (fork work item W-192).

import Core library "io";

fn Second[template T: type](a: T) -> i32 {
  return a[1];
}

fn Run() -> i32 {
  let a: array(i32, 3) = (1, 2, 3);
  Core.Print(Second(a));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X20_template_uninit_var.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   5
// QUOTE: `F(5 as i32)` returns 5
// Pins the resolution, by TP-1, of the page's limit on a `var` of a template
// parameter's type without an initializer: impl lookup for `T` is delayed
// until `F` is instantiated, as proposal 2200 specifies, and the program
// prints 5. Before TP-1 the definition was rejected with ``cannot convert type
// `T` into type implementing `Core.DefaultOrUnformed` `` (fork work item W-127,
// held PR 51).

import Core library "io";

fn F[template T: type](x: T) -> T {
  var y: T;
  y = x;
  return y;
}

fn Run() -> i32 {
  Core.Print(F(5 as i32));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X21_template_lookup_both.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-ERROR: unable to monomorphize specific `G(C as A)`
// QUOTE: member name `F` names different entities in type `C` and in its constraint `A`
// Pins the resolution, by TP-1, of the page's limit on a name that a template
// parameter's type and its constraint give different meanings: `x.F()` finds
// the class's own `F` in `C` and the `impl`'s `F` in `A`, so `G(c)` is
// rejected when `G` is instantiated, as proposal 2200's "Name lookup" section
// (p002200:476-503) requires; the quote is the note under the error. Before
// TP-1 the program printed 21, calling the type's member (fork work item
// W-183). `x.(A.F)()` alone still calls the `impl`'s `F`.

import Core library "io";

interface A {
  fn F(self) -> i32;
}

class C {
  var v: i32;
  fn F(self) -> i32 { return 1; }
  impl as A {
    fn F(self) -> i32 { return 2; }
  }
}

fn G[template T: A](x: T) -> i32 {
  return x.(A.F)() * 10 + x.F();
}

fn Run() -> i32 {
  let c: C = {.v = 9};
  Core.Print(G(c));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X23_template_class_uninit_var.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Types with template parameters", quote
// EXPECT-STDOUT:
//   6
// QUOTE: `Peek` on a `Stack(i32)` whose `top` is 6 returns 6
// Pins the resolution, by TP-1, of the fork note after the overview's `Stack`
// example: a method of a class with a template parameter that declares
// `var y: T;` without an initializer is checked when `Peek` is instantiated,
// and the program prints `top`, 6. Before TP-1 the class was rejected where it
// is defined (fork work item W-127, held PR 51). X20 pins the same form in a
// function.

import Core library "io";

class Stack(template T: type) {
  var top: T;
  fn Peek(self) -> T {
    var y: T;
    y = self.top;
    return y;
  }
}

fn Run() -> i32 {
  let s: Stack(i32) = {.top = 6};
  Core.Print(s.Peek());
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X24_template_class_index.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Types with template parameters", quote
// EXPECT-STDOUT:
//   8
// QUOTE: `First` on a `Holder(array(i32, 2))` holding `(8, 9)` returns 8
// Pins the resolution, by TP-1, of the fork note after the overview's `Stack`
// example: in a class with a template parameter, `self.item[0]` is indexed as
// an array when `First` is instantiated for `array(i32, 2)`, and the program
// prints 8. Before TP-1 the instantiation failed with the note ``cannot access
// member of interface `Core.IndexWith(Core.IntLiteral)` in type
// `array(i32, 2)` that does not implement that interface`` (fork work item
// W-192). X19 pins the same form in a function.

import Core library "io";

class Holder(template T: type) {
  var item: T;
  fn First(self) -> i32 { return self.item[0]; }
}

fn Run() -> i32 {
  let h: Holder(array(i32, 2)) = {.item = (8, 9)};
  Core.Print(h.First());
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X25_template_deduce_class_arg.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Functions with template parameters", quote
// EXPECT-STDOUT:
//   42
// QUOTE: `GetTemplate(h)` deduces `T` as `i32` from `Holder(T)`
// Pins the resolution, by TP-1, of the fork note after the overview's
// `Convert` example: a deduced template parameter is deduced from a class's
// arguments, so `GetTemplate(h)` and `GetChecked(h)` both deduce `T` as `i32`
// and the program prints 21 + 21. Before TP-1 `GetTemplate(h)` was rejected
// with ``cannot deduce value for generic parameter `T` `` (fork work item
// W-193). The `Holder(T)*` and `Vec(N)` forms are pinned by the toolchain's
// generic/template/deduce_class_args.carbon.

import Core library "io";

class Holder(T: type) {
  var item: T;
}

fn GetChecked[T: Core.Copy](h: Holder(T)) -> T {
  return h.item;
}

fn GetTemplate[template T: type](h: Holder(T)) -> T {
  return h.item;
}

fn Run() -> i32 {
  let h: Holder(i32) = {.item = 21};
  Core.Print(GetChecked(h) + GetTemplate(h));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X28_template_for_dependent_range.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   6
// QUOTE: `Sum(a)` on an `array(i32, 3)` holding `(1, 2, 3)` returns 6
// Pins the resolution, by TP-1, of the page's limit on a `for` loop whose
// range depends on a template parameter: the definition compiles, and the
// call `Sum(a)` iterates the array and prints 1 + 2 + 3. Before TP-1 the
// compiler stopped while it checked the loop's header in the definition, with
// or without a call (fork work item W-014).

import Core library "io";

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Run() -> i32 {
  let a: array(i32, 3) = (1, 2, 3);
  Core.Print(Sum(a));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X29_template_return_tuple.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   8
// QUOTE: `Dup(4 as i32)` returns `(4, 4)`
// Pins the resolution, by TP-1, of the page's limit on returning a value of a
// type built from a template parameter, in its tuple form: the program prints
// 4 + 4. Before TP-1 the compiler stopped while it resolved the definition of
// `Dup(i32)`, on the fork toolchain and the nightly (fork work item W-014).

import Core library "io";

fn Dup[template T: type](x: T) -> (T, T) {
  return (x, x);
}

fn Run() -> i32 {
  let t: (i32, i32) = Dup(4 as i32);
  Core.Print(t.0 + t.1);
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X30_template_return_struct.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   10
// QUOTE: `Mk(5 as i32)` returns `{.a = 5, .b = 5}`
// Pins the resolution, by TP-1, of the struct form of the page's limit on
// returning a value of a type built from a template parameter: the program
// prints 5 + 5. Before TP-1 the compiler stopped, on the fork toolchain and
// the nightly (fork work item W-014).

import Core library "io";

fn Mk[template T: type](x: T) -> {.a: T, .b: T} {
  return {.a = x, .b = x};
}

fn Run() -> i32 {
  let s: {.a: i32, .b: i32} = Mk(5 as i32);
  Core.Print(s.a + s.b);
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X31_template_return_array.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   8
// QUOTE: `Two(4 as i32)` returns an array holding 4 and 4
// Pins the resolution, by TP-1, of the array form of the page's limit on
// returning a value of a type built from a template parameter: the program
// prints 4 + 4, as the upstream nightly already did. Before TP-1 the fork
// toolchain stopped (fork work item W-014).

import Core library "io";

fn Two[template T: type](x: T) -> array(T, 2) {
  return (x, x);
}

fn Run() -> i32 {
  let a: array(i32, 2) = Two(4 as i32);
  Core.Print(a[0] + a[1]);
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X32_template_class_method_tuple.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   6
// QUOTE: `h.Both()` returns `(3, 3)`
// Pins the resolution, by TP-1, of the class form of the page's limit on
// returning a value of a type built from a template parameter: the program
// prints 3 + 3. Before TP-1 the file checked and the compiler stopped while it
// lowered `Both(i32)`, on the fork toolchain and the nightly (fork work item
// W-014).

import Core library "io";

class H(template T: type) {
  var a: T;
  fn Both(self) -> (T, T) { return (self.a, self.a); }
}

fn Run() -> i32 {
  let h: H(i32) = {.a = 3};
  let t: (i32, i32) = h.Both();
  Core.Print(t.0 + t.1);
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X33_template_tuple_destructure.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   9
// QUOTE: `Sum(t)` on `(4, 5)` returns 9
// Pins the resolution, by TP-1, of the destructuring half of the page's limit
// on tuple values whose type is a template argument: the program prints
// 4 + 5. Before TP-1 the compiler stopped while it lowered `Sum((i32, i32))`,
// at toolchain/lower/aggregate.cpp:67 (fork work item W-014). The other half,
// `Id` returning values that differ from run to run, is pinned by the
// toolchain's lower/testdata/template/initialize.carbon and by the conformance
// program templates_return_aggregates_diff.

import Core library "io";

fn Sum[template T: type](p: T) -> i32 {
  let (a: i32, b: i32) = p;
  return a + b;
}

fn Run() -> i32 {
  let t: (i32, i32) = (4, 5);
  Core.Print(Sum(t));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X34_template_return_struct_of_tuple.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: ResolveSpecificDefinition
// QUOTE: `fn F[template T: type](x: T) -> {.a: (i32, i32)}` with the body `return {.a = x};`
// Pins the page's limit, measured after TP-1, on returning a struct whose one
// field is a tuple, initialized from a value: the compiler stops while it
// resolves the definition of `F((i32, i32))`. The same function without a
// template parameter, with `x: (i32, i32)`, stops the compiler too, where it
// is defined (fork work item W-256).

fn F[template T: type](x: T) -> {.a: (i32, i32)} {
  return {.a = x};
}

fn Use() -> i32 {
  let t: (i32, i32) = (1, 2);
  let s: {.a: (i32, i32)} = F(t);
  return s.a.1;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X35_template_for_tuple_cursor.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-CRASH: Lowering function Sum(Counter)
// QUOTE: a range whose cursor is a tuple or a class
// Pins the page's limit, measured after TP-1, on a `for` loop whose range
// depends on a template parameter and whose cursor type is initialized in
// place: the compiler stops while it lowers `Sum(Counter)`. The cursor's
// storage is allocated after the call that initializes it, which the
// toolchain's own TODO in toolchain/check/handle_loop_statement.cpp records;
// a loop over an array or a `Core.Range`, whose cursor is an integer, runs
// (fork work item W-264). The same loop in a function without a template
// parameter runs and prints 6.

class Counter {
  var n: i32;
  impl as Core.Iterate where .CursorType = (i32, i32) and .ElementType = i32 {
    fn NewCursor(self) -> (i32, i32) { return (0, self.n); }
    fn Next(unused self, cursor: (i32, i32)*) -> Core.Optional(i32) {
      if (cursor->0 >= cursor->1) {
        return Core.Optional(i32).None();
      }
      let v: i32 = cursor->0;
      (*cursor).0 = v + 1;
      return Core.Optional(i32).Some(v);
    }
  }
}

fn Sum[template T: type](c: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in c) {
    s += x;
  }
  return s;
}

fn Use() -> i32 {
  let c: Counter = {.n = 4};
  return Sum(c);
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/samples/X36_template_type_member_constraint.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Templates in the 0.1 toolchain", quote
// EXPECT-STDOUT:
//   2
// QUOTE: `T.F()` for a type parameter calls the constraint's `F`
// Pins the page's limit, measured after TP-1, on member lookup through a
// template type parameter rather than a value: `T.F()` calls the `impl`'s
// `F` (2), although `C` has its own `F` (1) and proposal 2200 looks a name up
// in both and requires the same entity (fork work item W-262). `x.F()` on a
// value of type `T` is rejected in the same case (X21).

import Core library "io";

interface A {
  fn F() -> i32;
}

class C {
  fn F() -> i32 { return 1; }
  impl as A {
    fn F() -> i32 { return 2; }
  }
}

fn G[template T: A](unused x: T) -> i32 {
  return T.F();
}

fn Run() -> i32 {
  let c: C = {};
  Core.Print(G(c));
  return 0;
}
```

<!-- google-doc-style-resume -->

### C: fork/designdocs/check_samples.py

<!-- google-doc-style-ignore -->

```diff
--- a/fork/designdocs/check_samples.py
+++ b/fork/designdocs/check_samples.py
@@ -320,6 +320,24 @@
         "templates.md",
         "Templates in the 0.1 toolchain",
         QUOTE,
+        "X34_template_return_struct_of_tuple.carbon",
+    ),
+    (
+        "templates.md",
+        "Templates in the 0.1 toolchain",
+        QUOTE,
+        "X35_template_for_tuple_cursor.carbon",
+    ),
+    (
+        "templates.md",
+        "Templates in the 0.1 toolchain",
+        QUOTE,
+        "X36_template_type_member_constraint.carbon",
+    ),
+    (
+        "templates.md",
+        "Templates in the 0.1 toolchain",
+        QUOTE,
         "X07_template_let_file_scope.carbon",
     ),
     (
```

<!-- google-doc-style-resume -->

## Appendix D: C3's code and C5's hand-predicted parts

Added 2026-10-14 (review fold: B-M1 / A-m7). Hand-predicted against the quoted
trunk code: `sem_ir/inst_kind.def` and `diagnostics/kind.def` are X-macro
lists that every translation unit includes, so none of this was relinked. The
implementer builds it and the fills are the arbiter.

### D: sem_ir/inst_kind.def

Four lines, in the list's ASCII order (§2.3):

<!-- google-doc-style-ignore -->

```cpp
CARBON_SEM_IR_INST_KIND(AddrOfAction)
CARBON_SEM_IR_INST_KIND(IndexAction)
CARBON_SEM_IR_INST_KIND(PointerDereferenceAction)
CARBON_SEM_IR_INST_KIND(TupleIndexAction)
```

<!-- google-doc-style-resume -->

### D: sem_ir/typed_insts.h

Measured at implementation (amended 2026-10-14, implementation-review fold:
IR2-MINOR-2): the tree places the four structs at their alphabetical places in
typed_insts.h, the order of inst_kind.def and of the file, not beside
`AccessMemberAction`.

Beside `AccessMemberAction`, in alphabetical order among the actions.
`BoolValue` is already an action operand (`CallAction`), and
`OperandDependenceInSpecific` handles it (action.cpp:101-108). The
`PerformAction` declarations come from action.h's X-macro (:82-84).

<!-- google-doc-style-ignore -->

```cpp
// An action that takes the address of a template-dependent operand, `&expr`.
struct AddrOfAction {
  static constexpr auto Kind = InstKind::AddrOfAction.Define<Parse::NodeId>(
      {.ir_name = "addr_of_action",
       .expr_category = ActionExprCategory(ExprCategory::Value),
       .constant_kind = InstConstantKind::InstAction,
       .is_lowered = false});

  TypeId type_id;
  MetaInstId lvalue_id;
};

// An action that indexes a template-dependent operand, `expr[index]`.
struct IndexAction {
  static constexpr auto Kind = InstKind::IndexAction.Define<Parse::NodeId>(
      {.ir_name = "index_action",
       .expr_category = ActionExprCategory(ExprCategory::Dependent),
       .constant_kind = InstConstantKind::InstAction,
       .is_lowered = false});

  TypeId type_id;
  MetaInstId operand_id;
  MetaInstId index_id;
};

// An action that dereferences a template-dependent operand, `*expr`, or the
// base of `expr->member` when `is_arrow`.
struct PointerDereferenceAction {
  static constexpr auto Kind =
      InstKind::PointerDereferenceAction.Define<Parse::NodeId>(
          {.ir_name = "pointer_dereference_action",
           .expr_category = ActionExprCategory(ExprCategory::Dependent),
           .constant_kind = InstConstantKind::InstAction,
           .is_lowered = false});

  TypeId type_id;
  MetaInstId pointer_id;
  BoolValue is_arrow;
};

// An action that accesses a tuple element of a template-dependent operand,
// `expr.N`.
struct TupleIndexAction {
  static constexpr auto Kind = InstKind::TupleIndexAction.Define<Parse::NodeId>(
      {.ir_name = "tuple_index_action",
       .expr_category = ActionExprCategory(ExprCategory::Dependent),
       .constant_kind = InstConstantKind::InstAction,
       .is_lowered = false});

  TypeId type_id;
  MetaInstId tuple_id;
  MetaInstId index_id;
};
```

<!-- google-doc-style-resume -->

### D: check/diagnostic_helpers.h

`LocIdForDiagnostics::TokenOnly` takes only a `Parse::NodeId` (:26-28); the
shared functions below take a `SemIR::LocId`, so a second overload is added
beside it. A typed parse node ID converts to `Parse::NodeId` by a standard
conversion, which wins over `SemIR::LocId`'s converting constructor, so no
existing call becomes ambiguous.

<!-- google-doc-style-ignore -->

```cpp
  // Constructs a token-only location for a diagnostic at `loc_id`.
  static auto TokenOnly(SemIR::LocId loc_id) -> LocIdForDiagnostics {
    return LocIdForDiagnostics(loc_id, true);
  }
```

<!-- google-doc-style-resume -->

### D: check/pointer_dereference.h

The declarations replace `PerformPointerDereference`'s callback form:

<!-- google-doc-style-ignore -->

```cpp
// Which operator a pointer dereference is for, which selects its diagnostic.
enum class PointerDereferenceKind : bool { Star, Arrow };

// Returns whether `type_id` is a template-dependent type whose kind is not
// known where the template is defined: a template type parameter, its facet
// access type, or the type of a template-dependent expression. Every other
// type, including a template-dependent class type such as `C(T)`, has a kind
// that the eager code can act on.
auto IsOpaqueTemplateDependentType(Context& context, SemIR::TypeId type_id)
    -> bool;

// Creates SemIR to perform a pointer dereference with base expression
// `base_id`, for `*` or for the base of `->`. A template-dependent operand of
// opaque type is dereferenced when the template is instantiated. Returns the
// result of the access.
auto PerformPointerDereference(Context& context, SemIR::LocId loc_id,
                               SemIR::InstId base_id,
                               PointerDereferenceKind kind) -> SemIR::InstId;

// Creates SemIR to take the address of `operand_id`, `&operand`.
auto PerformAddrOf(Context& context, SemIR::LocId loc_id,
                   SemIR::InstId operand_id) -> SemIR::InstId;
```

<!-- google-doc-style-resume -->

### D: check/pointer_dereference.cpp

The definitions; the two `CARBON_DIAGNOSTIC`s and the `DerefOfType` note move
here from handle_operator.cpp:387-399 and handle_name.cpp:53-60 with their
texts, kinds and token-only locations unchanged, so every existing golden's
STDERR is byte-identical. The file includes check/action.h, check/type.h and
check/diagnostic_helpers.h.

<!-- google-doc-style-ignore -->

```cpp
auto IsOpaqueTemplateDependentType(Context& context, SemIR::TypeId type_id)
    -> bool {
  if (OperandDependence(context, type_id) !=
      SemIR::ConstantDependence::Template) {
    return false;
  }
  return context.types().IsOneOf<SemIR::SymbolicBinding,
                                 SemIR::FacetAccessType, SemIR::TypeOfInst>(
      type_id);
}

// Diagnoses a dereference of a value of a non-pointer type.
static auto DiagnoseNotPointer(Context& context, SemIR::LocId loc_id,
                               PointerDereferenceKind kind,
                               SemIR::TypeId not_pointer_type_id) -> void {
  // TODO: Pass in the expression we're trying to dereference to produce a
  // better diagnostic.
  if (kind == PointerDereferenceKind::Arrow) {
    CARBON_DIAGNOSTIC(ArrowOperatorOfNonPointer, Error,
                      "cannot apply `->` operator to non-pointer type {0}",
                      SemIR::TypeId);
    context.emitter().Emit(LocIdForDiagnostics::TokenOnly(loc_id),
                           ArrowOperatorOfNonPointer, not_pointer_type_id);
    return;
  }
  CARBON_DIAGNOSTIC(DerefOfNonPointer, Error,
                    "cannot dereference operand of non-pointer type {0}",
                    SemIR::TypeId);
  auto builder =
      context.emitter().Build(LocIdForDiagnostics::TokenOnly(loc_id),
                              DerefOfNonPointer, not_pointer_type_id);
  // TODO: Check for any facet here, rather than only a type.
  if (not_pointer_type_id == SemIR::TypeType::TypeId) {
    CARBON_DIAGNOSTIC(
        DerefOfType, Note,
        "to form a pointer type, write the `*` after the pointee type");
    builder.Note(LocIdForDiagnostics::TokenOnly(loc_id), DerefOfType);
  }
  builder.Emit();
}

auto PerformPointerDereference(Context& context, SemIR::LocId loc_id,
                               SemIR::InstId base_id,
                               PointerDereferenceKind kind) -> SemIR::InstId {
  // Proposal 2200: a dereference of a template-dependent operand whose type's
  // kind is not known yet is checked when the template is instantiated.
  if (IsOpaqueTemplateDependentType(
          context, context.types().GetUnqualifiedType(
                       context.insts().Get(base_id).type_id()))) {
    return AddDependentActionSplice<SemIR::PointerDereferenceAction>(
        context, loc_id,
        {.type_id = SemIR::InstType::TypeId,
         .pointer_id = base_id,
         .is_arrow =
             SemIR::BoolValue::From(kind == PointerDereferenceKind::Arrow)},
        SemIR::TypeInstId::None);
  }
  // TODO: Once we have a finalized design for a pointer interface, use
  //
  //   HandleUnaryOperator(context, loc_id, {"Pointer", "Dereference"});
  //
  // to convert to a pointer value.
  base_id = ConvertToValueExpr(context, base_id);
  auto type_id = context.types().GetUnqualifiedType(
      context.insts().Get(base_id).type_id());
  auto result_type_id = SemIR::ErrorInst::TypeId;
  if (auto pointer_type =
          context.types().TryGetAs<SemIR::PointerType>(type_id)) {
    result_type_id =
        context.types().GetTypeIdForTypeInstId(pointer_type->pointee_id);
  } else if (type_id != SemIR::ErrorInst::TypeId) {
    DiagnoseNotPointer(context, loc_id, kind, type_id);
  }
  return AddInst<SemIR::Deref>(
      context, loc_id, {.type_id = result_type_id, .pointer_id = base_id});
}

auto PerformAction(Context& context, SemIR::LocId loc_id,
                   SemIR::PointerDereferenceAction action) -> SemIR::InstId {
  return PerformPointerDereference(context, loc_id, action.pointer_id,
                                   action.is_arrow.ToBool()
                                       ? PointerDereferenceKind::Arrow
                                       : PointerDereferenceKind::Star);
}

auto PerformAddrOf(Context& context, SemIR::LocId loc_id,
                   SemIR::InstId operand_id) -> SemIR::InstId {
  auto category = SemIR::GetExprCategory(context.sem_ir(), operand_id);
  // Proposal 2200: whether a template-dependent operand is a durable
  // reference is known when the template is instantiated.
  if (category == SemIR::ExprCategory::Dependent &&
      IsOpaqueTemplateDependentType(
          context, context.insts().Get(operand_id).type_id())) {
    return AddDependentActionSplice<SemIR::AddrOfAction>(
        context, loc_id,
        {.type_id = SemIR::InstType::TypeId, .lvalue_id = operand_id},
        SemIR::TypeInstId::None);
  }
  auto type_id = context.insts().Get(operand_id).type_id();
  // Only durable reference expressions can have their address taken.
  switch (category) {
    case SemIR::ExprCategory::DurableRef:
    case SemIR::ExprCategory::Error:
      break;
    default:
      CARBON_DIAGNOSTIC(AddrOfNonRef, Error,
                        "cannot take the address of non-reference expression");
      context.emitter().Emit(LocIdForDiagnostics::TokenOnly(loc_id),
                             AddrOfNonRef);
      operand_id = SemIR::ErrorInst::InstId;
      break;
  }
  // TODO: Preserve spelling of type of operand where possible.
  auto type_inst_id = context.types().GetTypeInstId(type_id);
  return AddInst<SemIR::AddrOf>(
      context, loc_id,
      SemIR::AddrOf{.type_id = GetPointerType(context, type_inst_id),
                    .lvalue_id = operand_id});
}

auto PerformAction(Context& context, SemIR::LocId loc_id,
                   SemIR::AddrOfAction action) -> SemIR::InstId {
  return PerformAddrOf(context, loc_id, action.lvalue_id);
}
```

<!-- google-doc-style-resume -->

### D: handlers and the other two actions

handle_operator.cpp, handle_name.cpp, member_access.cpp and handle_index.cpp.
`PerformTupleAccess` keeps its declaration in member_access.h; `PerformIndex`
is file-local to handle_index.cpp, which defines its `PerformAction`.

<!-- google-doc-style-ignore -->

```cpp
// handle_operator.cpp
auto HandleParseNode(Context& context, Parse::PrefixOperatorAmpId node_id)
    -> bool {
  auto value_id = context.node_stack().PopExpr();
  context.node_stack().Push(node_id, PerformAddrOf(context, node_id, value_id));
  return true;
}

auto HandleParseNode(Context& context, Parse::PrefixOperatorStarId node_id)
    -> bool {
  auto base_id = context.node_stack().PopExpr();
  context.node_stack().Push(
      node_id, PerformPointerDereference(context, node_id, base_id,
                                         PointerDereferenceKind::Star));
  return true;
}

// handle_name.cpp, `HandleParseNode(Context&, Parse::PointerMemberAccessExprId)`:
// the `diagnose_not_pointer` lambda is removed, and each of its three
// `PerformPointerDereference(context, node_id, <base>, diagnose_not_pointer)`
// calls becomes
//   PerformPointerDereference(context, node_id, <base>,
//                             PointerDereferenceKind::Arrow)

// member_access.cpp, at the top of `PerformTupleAccess`, before
// `ConvertToValueOrRefExpr` (over SC-1, SC-1's D-SC-20 error return stays
// right after that call):
  // Proposal 2200: tuple element access into a template-dependent operand
  // whose type's kind is not known yet is checked on instantiation.
  if (IsOpaqueTemplateDependentType(
          context, context.insts().Get(tuple_inst_id).type_id())) {
    return AddDependentActionSplice<SemIR::TupleIndexAction>(
        context, loc_id,
        {.type_id = SemIR::InstType::TypeId,
         .tuple_id = tuple_inst_id,
         .index_id = index_inst_id},
        SemIR::TypeInstId::None);
  }

// member_access.cpp, after `PerformTupleAccess`:
auto PerformAction(Context& context, SemIR::LocId loc_id,
                   SemIR::TupleIndexAction action) -> SemIR::InstId {
  return PerformTupleAccess(context, loc_id, action.tuple_id,
                            action.index_id);
}

// handle_index.cpp: the handler's body moves into `PerformIndex`, with
// `node_id` replaced by `loc_id` (and `MakeIntType`'s location argument by
// `loc_id`), and an `IndexAction` for an opaque template-dependent operand.
static auto PerformIndex(Context& context, SemIR::LocId loc_id,
                         SemIR::InstId operand_inst_id,
                         SemIR::InstId index_inst_id) -> SemIR::InstId {
  operand_inst_id = ConvertToValueOrRefExpr(context, operand_inst_id);
  auto operand_inst = context.insts().Get(operand_inst_id);
  auto operand_type_id = operand_inst.type_id();
  // Proposal 2200: whether a template-dependent operand is an array, indexed
  // by `ArrayIndex`, or a type that implements `IndexWith`, is known when the
  // template is instantiated.
  if (IsOpaqueTemplateDependentType(context, operand_type_id)) {
    return AddDependentActionSplice<SemIR::IndexAction>(
        context, loc_id,
        {.type_id = SemIR::InstType::TypeId,
         .operand_id = operand_inst_id,
         .index_id = index_inst_id},
        SemIR::TypeInstId::None);
  }
  CARBON_KIND_SWITCH(context.types().GetAsInst(operand_type_id)) {
    // ... today's `ArrayType` and default cases (handle_index.cpp:162-215),
    // each returning its `elem_id` instead of pushing it.
  }
}

auto PerformAction(Context& context, SemIR::LocId loc_id,
                   SemIR::IndexAction action) -> SemIR::InstId {
  return PerformIndex(context, loc_id, action.operand_id, action.index_id);
}

auto HandleParseNode(Context& context, Parse::IndexExprId node_id) -> bool {
  auto index_inst_id = context.node_stack().PopExpr();
  auto operand_inst_id = context.node_stack().PopExpr();
  context.node_stack().Push(
      node_id, PerformIndex(context, node_id, operand_inst_id, index_inst_id));
  return true;
}
```

<!-- google-doc-style-resume -->

Measured at implementation (amended 2026-10-14, implementation-review fold:
IR2-MINOR-2): `MakeIntType` takes a `Parse::NodeId`, so "`MakeIntType`'s
location argument by `loc_id`" above does not compile. The tree's `PerformIndex`
derives `node_id = context.insts().GetCanonicalLocId(loc_id).node_id()` and
passes it to `MakeIntType` and to the fork's literal-subscript probe
`LiteralSubscriptTargetType`, which the text above does not mention;
`PerformIndexWith` takes a `SemIR::LocId`, and the `ValueAsRef` and `ArrayIndex`
instructions use `loc_id`. On instantiation `loc_id` is the `IndexAction`'s
instruction, whose canonical location is the index expression's node.

### D: check/member_access.cpp, C5's factored helper

`LookupMemberInTemplateConstraint` (§2.5, measured) starts with the facet
lookup below; factoring it out gives the diagnostic its third argument:

<!-- google-doc-style-ignore -->

```cpp
// Returns the facet type that constrains the template parameter whose type the
// deferred member access's operand had in the template's definition, and sets
// `*facet_const_id` to the argument's facet value; or returns `None` if the
// operand's type was not a constrained template parameter.
static auto GetTemplateConstraintFacetType(Context& context,
                                           SemIR::InstId base_id,
                                           SemIR::ConstantId* facet_const_id)
    -> SemIR::TypeId {
  auto specific_inst = context.insts().TryGetAs<SemIR::SpecificInst>(base_id);
  if (!specific_inst) {
    return SemIR::TypeId::None;
  }
  auto facet_access_type = context.types().TryGetAs<SemIR::FacetAccessType>(
      context.insts().Get(specific_inst->inst_id).type_id());
  if (!facet_access_type) {
    return SemIR::TypeId::None;
  }
  *facet_const_id = SemIR::GetConstantValueInSpecific(
      context.sem_ir(), specific_inst->specific_id,
      facet_access_type->facet_value_inst_id);
  auto facet_id = context.constant_values().GetInstIdIfValid(*facet_const_id);
  if (!facet_id.has_value()) {
    return SemIR::TypeId::None;
  }
  auto facet_type_id = context.insts().Get(facet_id).type_id();
  if (!context.types().IsConstrainedFacetType(facet_type_id)) {
    return SemIR::TypeId::None;
  }
  return facet_type_id;
}
```

<!-- google-doc-style-resume -->

`PerformAction(AccessMemberAction)` (§2.5) passes
`GetTemplateConstraintFacetType(context, action.base_id, &facet_const_id)` as
the diagnostic's third argument, and `LookupMemberInTemplateConstraint` calls it
for its first half (measured at implementation, §2.5; (amended 2026-10-14,
implementation-review fold: IR2-MINOR-2)).

### D: diagnostics/kind.def

One line, in the member-access group (measured at implementation: the file has
no such group, and the line is in the "Name lookup" group beside
`MemberNameNotFound`; (amended 2026-10-14, implementation-review fold:
IR2-MINOR-2)):

<!-- google-doc-style-ignore -->

```cpp
CARBON_DIAGNOSTIC_KIND(TemplateMemberLookupAmbiguous)
```

<!-- google-doc-style-resume -->

## Appendix E: records texts (commit D, last)

Added 2026-10-14 (review fold: B-M1 / B-M2 / B-B2 / B-m2 / B-m5). D writes
these after M, L and R, when W-127 (PR 51's) and W-183, W-192 and W-193
(PR 58's) exist on the branch; `YYYY-MM-DD` is the discharge date, and
`<merged ...>` placeholders are the measured values of the merged tree that D
records.

**Held state (amended 2026-10-14, implementation-review fold: IR2-MAJOR-2).**
While PR 51 to PR 59 are held (§1.12), D is written over trunk's records,
which end the ledger at W-125 and have no W-127, W-183, W-192 or W-193, no
TP-1 Branches row and the pre-DD-1 row at gap-analysis.md:54. D then writes:

-   W-014's notes as below, with the last sentence replaced by "Branch head
    <head> (held; PR 51 to PR 59 not on trunk), container-built, EXPECTED, not
    of record (Actions disabled): file_test <passed> of <total>, conformance
    <PASS>/<FAIL>/<SKIP> over <programs>; composed over SC-1 and VA-1 and
    checked with PR 58's checker on copies (plan §0.9, §2.9), 0 errors with
    the toolchain. The discharges of PR 51's W-127 and PR 58's W-183, W-192
    and W-193 follow at land time." (The label amended 2026-10-15, focused
    re-review of the fold: RR2-m4.)
-   W-250 to W-266 appended to work-items.json's `items` after W-125, as
    below; the focused re-review of the fold appends W-267 to W-270 after
    W-266 (amended 2026-10-15, focused re-review of the fold: all findings),
    and its round 2 W-271 after W-270 (amended 2026-10-15, focused re-review
    of the fold: RR2r2-M1).
-   The decision-log entry, at the place given below.
-   A Branches row in fork/ORCHESTRATION.md, after VA-1's, for
    `claude/carbon-fork-0-1-tp`, whose state reads: "IMPLEMENTED AND HELD,
    no PR -- TP-1 integrated templates at <head> (W-014 OPEN; W-250..W-266
    filed, W-267..W-269 unused; gate <passed>/<total> and conformance
    <PASS>/<FAIL>/<SKIP> over <programs> on the container toolchain; row
    "Generics: Integrated templates" stays PARTIAL); lands after PR 59 by
    the land-time items in Next actions." Since the focused re-review of the
    fold, the row says W-250..W-270 filed and W-271..W-274 unused (amended
    2026-10-15, focused re-review of the fold: all findings), and since its
    round 2, W-250..W-271 filed and W-272..W-274 unused (amended 2026-10-15,
    focused re-review of the fold: RR2r2-M1).
-   An item at the end of fork/ORCHESTRATION.md's Next actions: "TP-1 at land
    time (fork/templates/plan.md §3): repeat M over the trunk that holds PR
    51 to PR 59, keeping TP-1's appended record blocks after the PRs'; S;
    F6, with PR 51's split renamed; the id re-scan; L with its document
    review; a records commit that recomposes the row over the merged one
    (§2.8) and discharges W-127, W-183, W-192 and W-193; the id re-scan
    before D's landed notes."

At land time the records commit after the repeated M writes the discharges
below and the stamp, and replaces the held-state sentences by the merged
tree's values.

### E: W-014 notes, appended

> TP-1 (fork/templates/plan.md, YYYY-MM-DD): the template crashes and the
> miscompile DD-1 measured (X28 to X33, PR-AK), rev 1's sweep and review A's
> nested aggregates (plan §0.6) are fixed at their root causes (plan §0.3:
> storage of template-dependent initializers, carried as a copy that each
> specific places; splices read in the specific; the cursor pointer's
> completeness); `*`, `->`, `&`, tuple element access, indexing and calls of
> a function-typed value are deferred to instantiation by four new actions
> and the callee rule of p2875; member lookup consults the constraint on
> instantiation (W-183), deduction sees through class arguments (W-193),
> impl lookup for queries that name a template binding is deferred (W-127),
> a constant element beside a dependent one is stored, a runtime array
> bound in a template is an error instead of a fatal, and a diagnostic
> prints a dependent operation as its expression; since the focused
> re-review of the fold, a runtime value where a specific needs any type or
> constant is an error at that value, and a tuple type with a produced
> element such as `(T.Elem, i32)` lowers; since its round 2, a class
> template's literal whose array field has a template-dependent bound is
> converted on instantiation. The four generic/template
> `fail_todo` splits present when W-014 was filed flip (unimplemented.carbon's
> two, call.carbon's, member_out_of_line.carbon's, whose redeclarations do
> differ under p3763), so the first arbiter clause is met for them; TP-1's
> own twenty-eight `fail_todo` splits pin W-250 (twenty-seven, five of them
> added by the focused re-review of the fold's round 1, seven by its round 2
> and eleven by its round 3) and W-266 (one). The second
> clause is not met: the
> cross-file lowering fatal (lower/handle.cpp:513) stays behind W-250's
> `semantics TODO`. W-014 stays OPEN for W-250, W-255 (the pattern splices of
> the title) and W-264, and the row stays PARTIAL with W-251 to W-270
> (amended 2026-10-14, implementation-review fold: IR2-MINOR-6 / IR1-M3;
> amended 2026-10-15, focused re-review of the fold: RR1-B1 / RR1-M1 / RR2-M1
> / RR1-M2 / RR1-m3 / RR1-m4 / RR1-m5 / RR2-1-M2 / RR2r2-M1 / RR3-1-M1).
> Merged tree: file_test <merged passed> of <merged total>, conformance
> <merged PASS>/<merged FAIL>/<merged SKIP>, check_samples 0 errors with and
> without the toolchain.

Evidence is re-cited to the merged tree's lines in the same commit (D comes
after M, so the lines exist).

### E: discharges

Each item's title gains "(DISCHARGED at TP-1, YYYY-MM-DD)", as OP-2 marked
W-170, and its notes gain the paragraph below.

-   **W-127** (PR 51): "DISCHARGED by TP-1: impl lookup for a query that names
    a template binding selects no impl in the definition and keeps the
    deferred witness (impl_lookup.cpp `QueryNamesTemplateBinding`), so
    `var y: T;` resolves `DefaultOrUnformed` on instantiation (X20 and X23
    run; default_init.carbon); checked generics keep their lookup
    (facet/period_self.carbon and interop/cpp/template/generic_call.carbon
    unchanged); PR 51's split lost its `fail_todo_` prefix in F6."
-   **W-183** (PR 58): "DISCHARGED by TP-1: on instantiation a member of a
    template-dependent operand is looked up in the argument type and in the
    parameter's constraint (member_access.cpp
    `PerformAction(AccessMemberAction)`); R09 runs (25), X21's `x.F()` is
    rejected with `TemplateMemberLookupAmbiguous`, and a field beside a
    constraint method is rejected too (constraint_lookup.carbon); templates.md's
    limit keeps its text with a dated resolution note (Appendix C of the plan).
    This holds for an operand whose type in the definition is the parameter;
    an access through a field whose declared type is the parameter is W-266.
    The definition-time half and type-level `T.F` are W-260 to W-262."
    (Amended 2026-10-14, implementation-review fold: IR1-M3.)
-   **W-192** (PR 58): "DISCHARGED by TP-1: a template-dependent copy is
    deferred with its storage (convert.cpp `AddConvertActionIfDependent`), so
    a struct is copied by the builtin aggregate conversion on instantiation
    (X18 runs); an index into an operand of opaque template-dependent type is
    an `IndexAction`, so an array is indexed by `ArrayIndex` (X19, X24 run)."
    Under §3's shrink of C3's index actions, W-192 is not discharged: its
    notes record X18 as fixed and it stays open.
-   **W-193** (PR 58): "DISCHARGED by TP-1: a generic type constructor
    applied to template-dependent argument values forms its type in the
    definition (call.cpp `IsCallPerformable`), so deduction matches
    `Holder(T)` (PR-AJ's e04 and v02, and review A's g02 with a `Core.Copy`
    class parameter), a template class's `Holder(T)` (v04, u11),
    `Holder(T)*` (w02) and `Vec(N)` (v09): deduce_class_args.carbon and X25
    run."

### E: residues W-250 to W-266

Seventeen new items, appended to fork/inventory/work-items.json's `items` in id
order (W-256 and W-264 restated and W-265 added at rev 3; amended 2026-10-14,
review fold: RR-M1 / RR-M2; W-250 restated and W-266 added by the
implementation-review fold, (amended 2026-10-14, implementation-review fold:
IR1-M2 / IR1-M3)):

<!-- google-doc-style-ignore -->

```json
[
 {
  "id": "W-250",
  "kind": "todo-stub",
  "title": "TP-1 residue: a generic from another library whose definition or declaration is resolved for each instantiation (an eval block that holds an action or a splice: a template, a class template's field types or member function declarations, an interface or named constraint, or a checked generic whose definition holds one, such as a call of a C++ template) is a `semantics TODO` at the `import`",
  "subsystem": "toolchain/check (import_ref.cpp) + toolchain/lower",
  "size": "L",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/check/import_ref.cpp `TryFinishGeneric` (the TODO at the importing file's `import`; the definition is not imported, and the local generic gets an empty definition so the missing body is not reported again)",
   "toolchain/check/import_ref.cpp `IsDeclResolvedPerInstantiation` (a function or class template whose declaration holds an action reports the same TODO when it is first resolved and resolves to an error)",
   "toolchain/check/import_ref.cpp `IsTypeResolvedPerInstantiation` (added by the focused re-review of the fold: a class, interface or named constraint is tested before any of its data is loaded) and `PerInstantiationWalk` (its round 2: the test walks what the entity's eval blocks and bindings' types name, so an entity that names one that cannot be imported, an impl included, is diagnosed too; its round 3: the walk follows each instruction's type and operands, a specific's generic and arguments and a facet type's specifics, so an entity that names one through a callee, a specific's argument, a tuple or struct element, a field type, a constraint's argument or rewrite, or a blanket impl's witness is diagnosed too, and `TryFinishSpecific` does not import the definition of a specific whose generic's definition is not imported)",
   "toolchain/lower/handle.cpp:507-513 (\"Cross-file template lowering not implemented yet\", now unreachable because checking reports the TODO first)",
   "toolchain/check/testdata/generic/template/fail_todo_import.carbon (`fail_todo_import_function`, `fail_todo_import_class`, `fail_todo_import_function_declaration`, `fail_todo_import_class_declaration`, and the focused re-review's five `_class_field_type`, `_class_method_declaration`, `_interface_declaration`, `_constraint_declaration` and `_interface_member_declaration` splits, and its round 2's seven, from `_nested_class_field_type` to `_function_definition_names_class_template`, and its round 3's eleven, from `_function_definition_calls_function_template` to `_two_uses_name_class_template`; `import_unused` compiles)",
   "fork/templates/plan.md §0.3 RC-8 (trunk: FATAL at import_ref.cpp:5087, Missing case in TryResolveInstCanonical for SpliceInst)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Removal needs the import of action and splice instructions and a representation of an imported template's instantiation in check and lowering. Break condition: a use of a template from another library must compile and run (W-014's second arbiter clause)."
 },
 {
  "id": "W-251",
  "kind": "missing-feature",
  "title": "TP-1 residue: `partial T*` for a template parameter `T` is rejected with `PartialOnFinal`, although whether the argument is final is known only on instantiation",
  "subsystem": "toolchain/check (handle_operator.cpp)",
  "size": "S",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/check/handle_operator.cpp:342-361",
   "toolchain/check/testdata/class/partial/qualifier.carbon `fail_todo_partial_template_dependent`",
   "fork/designdocs/samples/X26_template_partial.carbon"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Needs the `PartialOnFinal` check performed on instantiation, an action of C3's shape. Break condition: the split flips."
 },
 {
  "id": "W-252",
  "kind": "missing-feature",
  "title": "TP-1 residue: `match` on a template-dependent value is a `semantics TODO`",
  "subsystem": "toolchain/check (handle_match.cpp)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/check/handle_match.cpp (unsupported scrutinee type)",
   "fork/designdocs/samples/X10_template_match_dependent.carbon",
   "proposals/p002200-template-generics.md:883-902"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). The `match` machinery's scrutinee support is the blocker. Break condition: X10 compiles."
 },
 {
  "id": "W-253",
  "kind": "missing-feature",
  "title": "TP-1 residue: an array whose bound is template-dependent cannot be initialized from a list of values",
  "subsystem": "toolchain/check (convert.cpp `ConvertTupleToArray`)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/check/convert.cpp:430-441 (`ArrayInitDependentBound`)",
   "toolchain/check/testdata/array/init_dependent_bound.carbon `fail_todo_init_template_dependent_bound`",
   "fork/designdocs/samples/X11_template_dependent_bound.carbon (the nightly accepts it after upstream 947c1eb52)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). In a class template's literal whose class's fields hold such an array, the initializer is converted on instantiation, as on trunk (focused re-review of the fold, round 2). Break condition: the split flips, or an upstream advance brings 947c1eb52."
 },
 {
  "id": "W-254",
  "kind": "missing-feature",
  "title": "TP-1 residue: an out-of-line redeclaration of a template class's member whose signature names a template-dependent type, such as `T.U`, is rejected even when token-identical to its declaration",
  "subsystem": "toolchain/check (merge.cpp redeclaration comparison)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "fork/templates/plan.md §1.8 probe `mool.carbon` (``type `<pattern for T.U>` of parameter 1 in redeclaration differs from previous parameter type `<pattern for T.U>` ``)",
   "proposals/p003763-matching-redeclarations.md:182-215 (declarations differ only if their token sequences differ)",
   "toolchain/check/testdata/generic/template/member_out_of_line.carbon `fail_basic` (a redeclaration that does differ, rejected correctly)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). The comparison compares action constants, which are not canonical across declarations. The stringification half of the old defect was fixed by TP-1 (D-TP-23). Break condition: mool compiles; SC-1's merge.cpp rewrite is the place."
 },
 {
  "id": "W-255",
  "kind": "toolchain-defect",
  "title": "TP-1 residue: lowering a call of a function with a form parameter, `template` or `generic`, stops the compiler at the parameter pattern's splice; with the pattern-splice FATALs of thunk, local and match-case matching, the \"pattern splices\" of W-014's title",
  "subsystem": "toolchain/lower (type.cpp) + toolchain/check (pattern_match.cpp, return.cpp)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/lower/type.cpp:434-514 (`TryHandleParameter` reads the generic constant, a `FormParamPatternAction` splice: FATAL Unexpected inst kind SpliceInst)",
   "toolchain/check/testdata/function/call/form.carbon:108-116 `form_generic_param` (compiled to an object, the same FATAL; review A's f01) and fork/templates/plan.md §0.3 RC-9 (f02, the template spelling)",
   "toolchain/check/pattern_match.cpp:2174-2180",
   "toolchain/check/return.cpp:217, :228"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Not template-specific: a guard for the template spelling was rejected (plan D-TP-15, dropped). `Core.Form` is not exported by the prelude. Break condition: form_generic_param compiles to an object."
 },
 {
  "id": "W-256",
  "kind": "toolchain-defect",
  "title": "TP-1 residue: a struct with one field or a tuple with one element, initialized by copy, whose element is an aggregate initialized in place, stops the compiler or is compiled wrongly (values that change from run to run), with or without a template parameter",
  "subsystem": "toolchain/check (convert.cpp) + toolchain/sem_ir (type_info.cpp)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/check/convert.cpp:2199 (trunk) `new_storage_id.has_value()` CHECK (s32 with a template, s32n, k03, k08 and q07en without)",
   "fork/templates/plan.md §0.3 RC-10: wrong values without a template on trunk and the nightly (k02 `var s: {.a: (i32, i32)} = {.a = x};`; k04, k05 and q07cn, a struct field that is a struct of one tuple field), and with one after TP-1 (q07c, which segfaulted on trunk through RC-1)",
   "toolchain/lower/handle_call.cpp:984 `args_ok` CHECK (k06, `{.a = (3, 4)}` passed as an argument)",
   "fork/designdocs/samples/X34_template_return_struct_of_tuple.carbon (after TP-1's integration)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). The aggregate's initializing representation is a copy while its element's is in place, so the element is converted with an in-place target that has no storage, or is initialized in place and then read as a value. A `semantics TODO` for the shape was measured and rejected because it also rejects working forms (plan §7.2(11)). Not a template defect; TP-1 removed the template-only crash that hid the miscompile in q07c. Break condition: X34 compiles and runs, and q07cn and q07c print 9."
 },
 {
  "id": "W-257",
  "kind": "toolchain-defect",
  "title": "TP-1 residue (hardening): lowering builds an inexact function type when a parameter's type is incomplete, and continues",
  "subsystem": "toolchain/lower (type.cpp)",
  "size": "S",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/lower/type.cpp:493",
   "toolchain/lower/file_context.cpp `GetOrCreateLLVMFunction` (TP-1's CHECK that an inexact function type has no return slot)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Break condition: an incomplete parameter type is diagnosed or completed before lowering."
 },
 {
  "id": "W-258",
  "kind": "infra",
  "title": "TP-1 residue: reconcile TP-1's copied storage access chain with upstream 4a8993af2's `InitializeAction::Target::storage_access_block_id` at the next upstream advance",
  "subsystem": "toolchain/check (convert.cpp) + toolchain/sem_ir (typed_insts.h)",
  "size": "S",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/check/convert.cpp `CloneStorageAccessChain` (TP-1, plan D-TP-3)",
   "upstream 4a8993af2 (the shared block moved into the action; fails nested literals, plan §0.3 RC-5)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). At the advance, carry TP-1's copy in upstream's field and keep the copy rule. Break condition: the advance lands."
 },
 {
  "id": "W-259",
  "kind": "missing-feature",
  "title": "TP-1 residue: an assignment whose left operand is template-dependent is not checked on instantiation for being an assignable reference",
  "subsystem": "toolchain/check (handle_operator.cpp, assignment)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/check/testdata/generic/template/operator.carbon:31 `todo_fail_assign_const` (`t.x = 456` through `ref t: T` on a `const C`)",
   "toolchain/check/testdata/generic/template/operator.carbon:62 `todo_fail_assign_let` (`T.x = 0` on a class `let`)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Needs an assignment action of C3's shape. Break condition: both splits flip to `fail_`."
 },
 {
  "id": "W-260",
  "kind": "missing-feature",
  "title": "TP-1 residue: a member access whose name the template parameter's constraint has is not given the constraint's meaning where the function is defined (proposal 2200's simple member access), so an expression that misuses it is accepted in an uncalled definition",
  "subsystem": "toolchain/check (member_access.cpp)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "proposals/p002200-template-generics.md:744-752",
   "fork/templates/plan.md §1.5 (review A's a13: `let b: bool = x.F();` with `A.F -> i32` compiles; the checked a14 is rejected)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Break condition: a13 is rejected where it is defined."
 },
 {
  "id": "W-261",
  "kind": "missing-feature",
  "title": "TP-1 residue: a name that two interfaces of a template parameter's constraint declare is not reported as ambiguous where the function is defined",
  "subsystem": "toolchain/check (member_access.cpp)",
  "size": "S",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "proposals/p002200-template-generics.md:766-767",
   "fork/templates/plan.md §1.5 (review A's a12: `fn G[template T: A & B](x: T) -> i32 { return x.F(); }` compiles uncalled)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Break condition: a12 is rejected."
 },
 {
  "id": "W-262",
  "kind": "missing-feature",
  "title": "TP-1 residue: a type-level member access `T.F` through a constrained template type parameter is not compared with the type's own member, so it calls the constraint's member where the type has a different one",
  "subsystem": "toolchain/check (member_access.cpp)",
  "size": "S",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "docs/design/expressions/member_access.md:436-440",
   "fork/designdocs/samples/X36_template_type_member_constraint.carbon (prints 2: the `impl`'s `F`, beside `C`'s own `F` returning 1)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). TP-1's comparison covers an access through a value of the parameter's type. Break condition: X36 is rejected on instantiation."
 },
 {
  "id": "W-263",
  "kind": "toolchain-defect",
  "title": "TP-1 residue: a constant nested tuple or struct fails LLVM verification while it is lowered, with or without a template parameter, and template copies of such values now reach the same failure",
  "subsystem": "toolchain/lower (constants)",
  "size": "S",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/lower/lower.cpp:48 (`!llvm::verifyModule`: Global variable initializer type does not match global variable type)",
   "fork/templates/plan.md §0.3 RC-13 (review A's h03c and b04d without templates; b04b, b04c and h03, which trunk rejected while checking, with them)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Break condition: `let t: ((i32, i32), i32) = ((1, 2), 3);` compiles."
 },
 {
  "id": "W-264",
  "kind": "toolchain-defect",
  "title": "TP-1 residue: a template-dependent in-place initializer of a storage root that is allocated after it stops the compiler: a `for` loop over a range whose cursor is a tuple or a class, and a class value whose struct literal leaves a field to its default initializer",
  "subsystem": "toolchain/check (handle_loop_statement.cpp, convert.cpp)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/check/handle_loop_statement.cpp:216-218 (the toolchain's own TODO: allocate the cursor's `VarStorage` before building the operator), :229",
   "fork/templates/plan.md §0.3 RC-12 (`$X/probes/new/n01`: CHECK at function_context.cpp:223 lowering `Sum(Counter)`; n01c, the same loop without a template, prints 6; `$Y/probes/v14/t02`: the SemIR verifier during checking)",
   "toolchain/check/convert.cpp `ConvertStructToClass` (D-TP-24 defers a class value only when its source names exactly the class's fields; the array, union and class value temporaries of :471, :1084 and :1203 are otherwise fixed by it)",
   "fork/designdocs/samples/X35_template_for_tuple_cursor.carbon (after TP-1's integration)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Fix by allocating the cursor before its initializer; t02 then reaches W-265. Break condition: X35 compiles and runs."
 },
 {
  "id": "W-265",
  "kind": "toolchain-defect",
  "title": "TP-1 residue (not a template defect): a runtime class value or `var` whose field takes its default initializer stops the compiler while it is lowered, with or without a template parameter",
  "subsystem": "toolchain/lower (aggregate.cpp `EmitAggregateInitializer`) + toolchain/sem_ir (expr_info.cpp)",
  "size": "S",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/sem_ir/expr_info.cpp:359 (trunk: FATAL Initialization from unexpected inst {kind: IntValue ...}, from `FindStorageArgForInitializer` in `EmitAggregateInitializer`)",
   "fork/templates/plan.md §0.3 RC-12 (`$Y/probes/v14/t16n`: `let c: C = {.a = x};` with `var b: i32 = 5;` in `C`; t17n, the `var` form; t02n; trunk and the nightly)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13), because the template form t02 reaches it once W-264 is fixed. Candidate owner: Type system: User-defined types (classes). Break condition: t16n compiles and prints 8."
 },
 {
  "id": "W-266",
  "kind": "missing-feature",
  "title": "TP-1 residue: member lookup into a constrained template parameter's constraint does not apply when the operand's type is the parameter only through a deferred member access, such as a field of a template class (`self.c.F()` in `class W(template T: A)`) or of `Holder(T)`",
  "subsystem": "toolchain/check (member_access.cpp)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
   "toolchain/check/member_access.cpp `GetTemplateConstraintFacetType` (the operand must be a `SpecificInst` whose type in the definition is the parameter's `FacetAccessType`; `self.c` is an `access_member_action` splice of `<dependent type>`)",
   "toolchain/check/testdata/generic/template/constraint_lookup.carbon `fail_todo_field_of_template_class` (``member name `F` not found in `C` `` on instantiation)",
   "fork/templates/plan.md implementation review fold record, IR1-M3 (the review's f13 and f15; trunk the same)"
  ],
  "blocked_by": [],
  "notes": "Filed at the TP-1 discharge (YYYY-MM-DD, fork/templates/plan.md §1.13). Removal: record the declared type of the field a deferred access names, so the constraint of the template parameter it is can be consulted. Break condition: the split flips and prints the impl's value as a program."
 }
]
```

<!-- google-doc-style-resume -->

### E: residues W-267 to W-271 (focused re-review of the fold)

Four new items, appended after W-266 by the focused re-review of the fold's
records commit, as written there (amended 2026-10-15, focused re-review of the
fold: RR1-m3 / RR1-m4 / RR1-m5 / RR1-M1 / RR2-M1), and a fifth, W-271,
appended after W-270 by the records commit of its round 2 (amended 2026-10-15,
focused re-review of the fold: RR2r2-M1); their evidence and notes are the
ledger's, in full.

<!-- google-doc-style-ignore -->

```json
[
 {
  "id": "W-267",
  "kind": "toolchain-defect",
  "title": "TP-1 residue: the temporaries that a template's actions create on instantiation (a `var` parameter's copy of a template-dependent argument, a temporary class value) are never destroyed",
  "subsystem": "toolchain/check (control_flow.cpp, action instantiation)",
  "size": "M",
  "bullet": "Generics: Integrated templates"
 },
 {
  "id": "W-268",
  "kind": "missing-feature",
  "title": "TP-1 residue: `var e: T.Elem;` for a template `T` is rejected where the function is defined, because the deferral of impl lookup does not see a template binding through a splice's action",
  "subsystem": "toolchain/check (impl_lookup.cpp)",
  "size": "S",
  "bullet": "Generics: Integrated templates"
 },
 {
  "id": "W-269",
  "kind": "missing-feature",
  "title": "TP-1 residue: `return {} as T;` for a template `T` that is a class without `Copy` is rejected on instantiation, because the dependent `as` forms a value that the return copies",
  "subsystem": "toolchain/check (convert.cpp, dependent conversions)",
  "size": "M",
  "bullet": "Generics: Integrated templates"
 },
 {
  "id": "W-270",
  "kind": "toolchain-defect",
  "title": "TP-1 residue: an interface or named constraint whose later parameter's type depends on a template parameter (`interface I(template T: type, U: T.Item)`) stops the compiler in its own library when it is used",
  "subsystem": "toolchain/check + toolchain/sem_ir (generic.cpp)",
  "size": "M",
  "bullet": "Generics: Integrated templates"
 },
 {
  "id": "W-271",
  "kind": "toolchain-defect",
  "title": "TP-1 residue: a generic class from another library that declares a nested class or interface stops the compiler where the class is used, with or without a template parameter",
  "subsystem": "toolchain/check (import_ref.cpp)",
  "size": "M",
  "bullet": "Generics: Integrated templates"
 }
]
```

<!-- google-doc-style-resume -->

### E: decision log, entry "TP-1"

Placed immediately above `### OX-1 parked: operator export to C++ cannot be made
invisible to Carbon's own resolution (2026-10-14)` (decision-log.md:2863 at
8bfd78ae3), which is the newest dated entry, directly after "Full autonomy and
the throughput protocol" as VA-1's, DD-1's and OP-2's entries are; at land time
it is re-anchored above whatever entry then follows "Full autonomy" (amended
2026-10-14, implementation-review fold: IR2-MINOR-1):

> ### TP-1: integrated templates (YYYY-MM-DD)
>
> Context: W-014 (gap row "Generics: Integrated templates", PARTIAL), with
> DD-1's residues W-183, W-192 and W-193 and UA-2's W-127;
> fork/templates/plan.md, rev 3 after two plan reviews (27 findings folded)
> and a focused re-review (APPROVE-WITH-AMENDMENTS, six findings folded),
> implemented and then folded with two implementation reviews (REJECT with
> seven findings, APPROVE-WITH-FIXES with thirteen; plan's implementation
> review fold record).
> Every decision auto-adopted under V-2/V-3
> (R29(a)) and open to veto. Options considered (plan §7.2): turning crashes
> into TODOs (rejected as Goodhart), cherry-picking 947c1eb52 or 4a8993af2,
> inserting the storage block at the action (rev 1), deferring every form,
> a definition-only W-183, accepting the deferred witness only, deferring
> every template-dependent query, canonical action constants for W-254, a
> template form-parameter guard, a `semantics TODO` for RC-10's shape, and
> deferring every class value whatever its fields. Decisions: D-TP-1,
> crashes first, with a template crash that exposes the same code's
> non-template miscompile recorded rather than diagnosed; D-TP-2,
> same-type dependent initialization is a storage-carrying
> `InitializeAction`; D-TP-3, the action carries a copy of its storage access
> chain that each specific places; D-TP-4, replayed conversions get a storage
> access block; D-TP-5, storage arguments are found in the specific; D-TP-6,
> dependent value conversions are `ConvertToValueAction`s; D-TP-7, lowering
> reads the specific; D-TP-8, the `for` cursor pointer is completed; D-TP-9,
> four actions for opaque template-dependent operands; D-TP-10, a
> function-typed callee calls its type's function (p2875); D-TP-11, generic
> type constructors with dependent argument values are formed eagerly;
> D-TP-12, impl lookup for queries that name a template binding is deferred;
> D-TP-13, constraint lookup on instantiation, with different entities an
> error and SC-1's requirements deferring to the type; D-TP-14,
> cross-library generics resolved per instantiation are a `semantics TODO` at
> the `import`; D-TP-15, dropped; D-TP-16, no cherry-pick; D-TP-17, no fork
> design id; D-TP-18, row PARTIAL; D-TP-19, merge after PR 59, before the
> implementation reviews; D-TP-20, nine programs; D-TP-21, PR 58's fixtures
> flipped with dated notes; D-TP-22, commit structure, with the merge
> resolving conflicts only; D-TP-23, dependent operations print as
> expressions; D-TP-24, a template-dependent array, union or class value is
> converted whole for each instantiation; D-TP-25, a constant splice lowers
> the storage its block holds; D-TP-26, a runtime array bound in a
> specific is an error. Consequences: row PARTIAL; W-250..W-266 filed,
> W-267..W-269 unused; W-127, W-183 (for an operand whose type is the
> parameter; W-266 for a field), W-192, W-193 discharged.
>
> (The focused re-review of the fold amended the entry in place: D-TP-26 is
> a runtime operand where a specific needs a constant, W-250..W-270 are
> filed and W-271..W-274 unused, and a "FOCUSED RE-REVIEW OF THE FOLD"
> paragraph follows the reviews; amended 2026-10-15, focused re-review of
> the fold: all findings. Its round 2 amended it again: W-250..W-271 are
> filed and W-272..W-274 unused, and the paragraph "FOCUSED RE-REVIEW OF THE
> FOLD, ROUND 2" follows the first; amended 2026-10-15, focused re-review of
> the fold: all round-2 findings.)
> <Implementation, review and merged-tree verification paragraph, as VA-1's
> entry has.>
>
> Veto digest: D-TP-3 (a copy of the storage chain, not upstream's shared
> block), D-TP-12 (deferral limited to template bindings), D-TP-13 (a field
> beside a constraint method is an error; SC-1's requirements defer to the type;
> through a field it is W-266), D-TP-14 (cross-library templates are a TODO, not
> implemented), D-TP-15 (form parameters left alone), D-TP-18 (PARTIAL with
> sixteen residues; twenty since the focused re-review of the fold), D-TP-23
> (the redeclaration split flips by a diagnostic fix), D-TP-24 (a class value is
> deferred only when its fields match, so definition-time field errors stay),
> W-256 (q07c's template crash traded for the miscompile the same code has
> without templates).

### E: fork/ORCHESTRATION.md stamp

> TP-1 (`claude/carbon-fork-0-1-tp`, PR <n>, head <sha>): integrated
> templates, W-014 (OPEN), W-127/W-183/W-192/W-193 discharged, W-250..W-271
> filed (W-272..W-274 unused; amended 2026-10-15, focused re-review of the
> fold, round 2; re-scans before L and before D:
> <outcomes>); merged
> after PR 59 (<merge sha>); file_test <merged passed>/<merged total>,
> conformance <merged counts>, check_samples 0 errors; row "Generics:
> Integrated templates" PARTIAL.
