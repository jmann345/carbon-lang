# Variadics plan: definition-checked variadics, slice 1 (VA-1)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 3, 2026-10-14 -- SIGNED OFF FOR IMPLEMENTATION. Rev 3 folds the
focused re-review of rev 2 (be623188d; APPROVE-WITH-AMENDMENTS: review A's two
BLOCKERs verified RESOLVED, no new BLOCKER, one new MAJOR and three new MINOR
findings, which the re-review numbered VA1-RR-M1 and VA1-RR-m1 to VA1-RR-m3 and
this plan cites as RR-M1 and RR-m1 to RR-m3), each amended sentence or row
marked "(amended 2026-10-14, review fold: RR-n)" and tabled in the "Review fold
record (rev 3, 2026-10-14)" at the end; none is rejected, and the three reviews
are listed in the "Sign-off" after it. Rev 2 (be623188d) folded both plan
reviews of R29(c), every finding of both, by a separate fixer (R11): review A
(architecture; REJECT: two BLOCKERs, one MAJOR, four MINORs) and review B
(concreteness, process and cross-workstream; APPROVE-WITH-AMENDMENTS: four
MAJORs, nine MINORs). The "Review fold record (rev 2, 2026-10-14)" at the end
gives each finding its disposition and the places it landed; review A's ids are
written A-B1, A-B2, A-M1 and A-m1 to A-m4 (its `VA1-A-` prefix dropped), review
B's B-M1 to B-M4 and B-m1 to B-m9, and neither is §7.2's A-n, nor is the
re-review's RR-n. Rev 1 (aced921975) was the planner's draft. Nothing below was
implemented on this branch at rev 3; the implementation followed §3, a separate
fixer folded its two implementation reviews (APPROVE-WITH-FIXES each) in new
commits, and the "Implementation review fold record (2026-10-14)" at the end
tables every finding (amended 2026-10-14, implementation-review fold:
VA1-IR2-m1). Branch `claude/carbon-fork-0-1-va`, cut from trunk f67ab650d, whose
toolchain and core trees equal upstream cut 0bdce60a5. Every line number below
is against f67ab650d unless a commit or branch is named. Every measured outcome
in §0.2 was taken in this container with the trunk toolchain
(`/home/user/carbon-build/carbon-trunk`, `carbon version`
`0.0.0-0.dev+0bdce60a5`), the upstream nightly 2026.10.12 (which carries
2ec4bab59), the trunk build's own compiler flags, the CI-pinned clang-format
(21.1.8) or LLVM's clang-tidy (21.1.8), either in the planner's scratch
directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va1`
(`$V` below), for rev 2, in the fixer's
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va1-fixer`
(`$F` below), or, for rev 3, in the second fixer's `$V/rr3` (`$R` below; amended
2026-10-14, review fold: RR-M1, RR-m2). No toolchain was built, nothing under
/home/user/carbon-build was modified, no worktree other than this one was
touched (the scratch clones `$V/cp` and `$F/cp` are `git clone --shared` copies,
read-only for the repositories they were cloned from), and the owner's runner
was not used (R28). The prototype that §2 quotes exists only in the fixer's
scratch clone `$F/cp`, on the branches `fx-c3` (6d15888c1), `rr-c4` (ee713955b)
and `rr-c5` (5969337e8): `fx-c3` is rev 1's `va1-c3f` plus one commit; rev 2's
`fx-c4` (0cb0f3ec0) replays `va1-c4f`'s commit onto it and adds one, and rev 2's
`fx-c5` (1c61cab6f) replays `va1-c5f`'s commit with the fold's lowering in the
same commit; rev 3's `rr-c4` is `fx-c4` plus one commit, and `rr-c5` replays
`fx-c5`'s commit onto `rr-c4` and adds one, both written with git's plumbing and
no checkout, because the container's disk had about 10 MB free (§2.0; amended
2026-10-14, review fold: RR-M1, RR-m2). It is the source of every code block in
§2, not a substitute for them.

**Item:** W-013, "W6: implement definition-checked variadics"
(fork/inventory/work-items.json; size XL; kind missing-feature). VA-1 is its
FIRST SLICE; W-013 stays open (D-VA-14). **Milestone row:**
fork/gap-analysis.md:53, "Generics: Definition-checked variadics", DESIGN-ONLY;
records refer to it by its bullet text (R7). **Bullet text**
(docs/project/milestones.md:136-139): "Generics", "Checked generics",
"Definition-checked variadics". **Arbiter of record:**
fork/conformance/programs/generics/variadics_each.carbon, SKIP, EXPECT-STDOUT 6
then 0.

**Outcome this plan commits to.** The pack machinery of docs/design/variadics.md
is implemented end to end (lex, parse, check, lower, run) for one principled
subset: a function's explicit parameter list (outside an interface) may contain
one pack expansion pattern `... each x: T` whose operand is a single each-name
value binding of a type `T` that names no pack (a concrete type or an earlier
deduced parameter); the pack binds its arguments' values as any value
parameter binds its argument, so no element is copied and no element type
needs `Core.Copy` (amended 2026-10-14, review fold: A-B2 / B-M1); the body may
contain pack expansion statements whose body is an expression statement, and
calls may pass pack expansion arguments `... expression`, each evaluated where
it is written, before the arguments that follow it (amended 2026-10-14, review
fold: A-B1 / B-M2); the arity is a deduced parameter of the callee (the
design's explicit deduced arity), deduced at each call from the run of
arguments the pattern matches; the body is checked once, against the pack's
element type, which is the design's iterative typechecking for a pack of one
segment; and each specific is lowered by running the expansion body once per
element, which is the design's execution at monomorphization. Upstream's own
start on variadics, 2ec4bab59 and a045da8e6, is cherry-picked as commits 1 and
2 with upstream authorship, so the fork's node kinds, token kinds and check
entry points are upstream's (D-VA-1). Every other form the design gives is
diagnosed as a `semantics TODO` with a golden, rejected with the design's own
rule, or, for `...and` and `...or`, rejected by the parser with a parse golden
(amended 2026-10-14, review fold: B-m3), and filed from W-212 (§1.11). The SKIP
program un-SKIPs to PASS with its EXPECT values 6 and 0 unchanged and
re-derived by hand (§1.6, R16(d)), eight new programs (one with a C++17
differential oracle) join it, fourteen new goldens and one refill are added
(amended 2026-10-14, review fold: A-B1, A-B2, A-M1, B-M1, B-M2, B-m3), and the
row moves DESIGN-ONLY to PARTIAL, expected, not of record, with the header
delta PARTIAL plus one and DESIGN-ONLY minus one (§2.8). The implementation
lands in five implementation commits, each of which compiles at the syntax
level today (M-11) and is planned to build and pass the gate together with its
fill commit (§3).

**Id allocation (recorded so no workstream collides).** Re-scanned for this plan
over the 76 refs `refs/heads/claude/carbon-fork-0-1-*`,
`refs/remotes/origin/claude/carbon-fork-0-1-*`, `refs/heads/trunk` and
`refs/remotes/origin/trunk` of /home/user/carbon-lang (local trunk is now
44761146d, one records-only commit past this branch's base) with

```sh
cd /home/user/carbon-lang
refs=$(git for-each-ref --format='%(refname)' \
  'refs/heads/claude/carbon-fork-0-1-*' \
  'refs/remotes/origin/claude/carbon-fork-0-1-*' \
  refs/heads/trunk refs/remotes/origin/trunk)
for r in $refs; do git grep -hoE 'W-[0-9]{3}' $r -- fork; done | sort -u | tail -3
for r in $refs; do git grep -lE 'W-(21[2-9]|22[0-9]|23[01])\b' $r -- fork; done
for r in $refs; do git grep -hE 'F-01[78]' $r -- fork docs; done | sort -u
```

At rev 1 the ledger maximum on any ref was W-232 (filed by SC-1 round 9 on the
sc branch, named on the op2 branch). For rev 2 the fixer re-ran the three
commands on 2026-10-14 over the same 76 refs (local trunk now 3eb7f36f0, which
records DD-1 as PR 58): the maximum named on any ref is W-244, the end of
DD-1's reserved and unused block W-240..W-244 (fork/designdocs/plan.md:119-123
on the dd branch); SC-1 holds W-232..W-239; W-202..W-211 are OX-1's
reservation; W-212..W-231 and F-018 are named on trunk, the dd branch and the
ox branch only as VA-1's reservation ("reserves W-212 to W-231 and F-018 if
minted", fork/ORCHESTRATION.md on trunk), and F-017 only as OX-1's, which its
rev-2 plan mints. For rev 3 the second fixer re-ran them on 2026-10-14 over the
same 76 refs (local trunk still 3eb7f36f0): the maximum is still W-244, and
W-212..W-231 and F-018 are named only as VA-1's reservation, on trunk, the
integration branch `claude/carbon-fork-0-1-7mwfb7`, the dd branch, the ox
branch (whose OX-1 plan is now at rev 2) and in this plan.
**VA-1 reserves W-212..W-231** (twenty ids): W-212..W-228
are the residues of §1.11's first seventeen items, W-229 and W-230 are the two
residues the review fold adds (§1.11 items 18 and 19; amended 2026-10-14,
review fold: A-m2, A-m3), W-231 stays a spare, and an unused reserved id stays
unused and is never reused.
**No fork design id is minted** (D-VA-14): F-018 stays unallocated unless a
review shows that the slice decides a rule the design leaves open, in which case
F-018 is minted with a dated amendment to docs/design/variadics.md. The ids
appear only in records written by the discharge commit D (§3) and in this
plan; no source file, golden or program header names one, so a
re-allocation touches records only. Immediately before the discharge commit
writes the ledger, the three commands above are re-run; if any of W-212..W-231
or F-018 is taken by then, the residues re-allocate from the maximum plus one,
skipping every reserved block, and the landed notes say so. The discharge
records the reservation's outcome in fork/ORCHESTRATION.md.

**Design authority** (each cited where used):

-   docs/design/variadics.md (accepted p002240; 964 lines at f67ab650d, 1000
    after commit 2, which adds a table-of-contents line after :25 and
    a045da8e6's "Type versus execution semantics" after :493, so that after
    commit 2 a citation of :26 to :493 moves by one line and a citation past
    :493 by 36; amended 2026-10-14, implementation-review fold: VA1-IR2-m4):
    "Packs and each-names" (:83-101), "Pack expansions" (:103-157), "Pack
    expansion expressions and statements" (:159-202), "Pack expansion patterns"
    (:204-236), "Execution Semantics" (:294-344), "Iterative typechecking of
    pack expansions" (:450-492), "Typechecking patterns" (:494-587),
    "Typechecking pattern matches" (:589-641), "Explicit deduced arities"
    (:652-668), "Typing and shaping rules" (:670-714).
-   proposals/p002240-variadics.md: "Generalize `expand`" (the source of
    a045da8e6), "Omit each-names" (:555-657) and "Disallow pack-type bindings"
    (:659), cited for D-VA-11.
-   proposals/p002875-functions-function-types-and-function-calls.md:227 and
    :531 ("`Call` should be variadic", "Once Carbon supports variadics, the
    overloaded call mechanism should be revised"), filed as W-226.
-   The later proposals that mention variadics, found with `grep -lE variadic
    proposals/*.md` (amended 2026-10-14, review fold: B-m6): p002274 :250-257
    (the indexing interfaces should become variadic "once we have a design for
    variadics"; noted in W-212), p002687 :186-193 and :210-215 (impl-selection
    termination keeps keys for variadic argument counts; cited by W-222 and
    W-225), p003848 :372-383 (lambda positional parameters are "variadic by
    design"; not a pack, outside the slice), p002188 :765-772 (struct pattern
    syntax avoids `, ...` because variadics claim `...`), and passing mentions
    in p000157, p000540, p001327, p002360, p003720 and p006254 (the last about C
    varargs). None changes a rule the slice implements.
-   docs/design/values.md "Binding patterns and local variables with `let` and
    `var`" (:170-188: "Value bindings require the matched expression to be a
    value expression, converting it into one as necessary") and
    docs/design/pattern_matching.md "Evaluation order" (:935-1047), cited by
    D-VA-3 and D-VA-4 (amended 2026-10-14, review fold: A-B1, A-B2, B-M1,
    B-M2).
-   Upstream 2ec4bab59 ("Lex and parse support for `...` statements and
    `expand`.", Richard Smith, 2026-10-05) and a045da8e6 ("Document the
    discrepancy between checking and execution for variadics", Geoff Romer,
    2026-10-13), both on upstream/trunk 66a250ad9.
-   fork/inventory/work-items.json W-013's notes, including OV-1's: the
    overload loop's arity check is a range (`GetExplicitArityRange`,
    toolchain/check/call.cpp:424 at f67ab650d, :338 when OV-1 wrote it) "so
    variadic members slot in without reshaping the loop" (W-223).

V-3: no accepted proposal or leads' direction is contradicted. Every rule the
slice implements is the design's, specialized to packs of one segment; every
rule it does not implement is diagnosed, never given a different meaning (§1.2).
The two places where the fork reads upstream's state of the art rather than the
design are recorded as decisions: `each` is a keyword (D-VA-10; the design says
so at :45-47 and :91, upstream's editor grammars already list it, M-10, but
upstream's lexer does not yet, M-3), and the fork extends upstream's parse
shapes rather than waiting for upstream's (D-VA-1, §7 A-3). Where the design
leaves a rule open, the slice diagnoses a `semantics TODO` instead of deciding
it: a pack's name without `each` (D-VA-11), default values beside a pack, and a
pack in an interface function (D-VA-5; amended 2026-10-14, review fold: A-m1,
A-m2, A-m3).

## §0 Audit: what exists, what was measured, what is stale

### §0.1 Sub-feature table (verified in-tree at f67ab650d)

| # | Element | Status at f67ab650d | Evidence |
| --- | --- | --- | --- |
| 1 | `...` token | ABSENT | toolchain/lex/token_kind.def has no `PeriodPeriodPeriod`; the trunk lexer splits `...` into three `Period` tokens (M-3). Upstream 2ec4bab59 adds `CARBON_TOKEN_WITH_VIRTUAL_NODE(CARBON_SYMBOL_TOKEN(PeriodPeriodPeriod, "..."))` and `CARBON_KEYWORD_TOKEN(Expand, "expand")`. |
| 2 | `each` keyword | ABSENT in the lexer; PRESENT in the editor grammars | token_kind.def has no `Each`; the nightly lexes `each` as an `Identifier` (M-3); utils/textmate/Samples/keywords.carbon:39, utils/tree_sitter/queries/highlights.scm:122 and utils/vscode/carbon.tmLanguage.json already list `each` and `expand` as keywords (M-10). |
| 3 | Pack expansion statement | ABSENT; upstream parses it | 2ec4bab59's toolchain/parse/handle_statement.cpp case `PeriodPeriodPeriod` adds `PackExpansionStart`, parses one `Statement`, then `StatementPackExpansionFinish` adds `PackExpansionStatement`; check is `context.TODO(node_id, "HandlePackExpansionStart")` (2ec4bab59's toolchain/check/handle_pack_expansion.cpp:10-13). |
| 4 | Binding patterns | LANDED, no `each` | toolchain/parse/handle_binding_pattern.cpp:71-160: the phase keywords `template`, `generic` and `runtime` (:89-91), then `ref` (:92), then a misordered `unused` (:104-114), then the name (:116-120, :148, :153); a binding name's node is the binding pattern's first child (typed_nodes.h `LetBindingPattern`, `VarBindingPattern`, `CompileTimeBindingPattern`). |
| 5 | Pattern lists | LANDED | toolchain/parse/handle_pattern_list.cpp:11-35 `HandlePatternListElement` pushes the element's finish state then `Pattern`; the variants are Tuple (:37), Struct (:42), Explicit (:67) and Implicit (:72). |
| 6 | Tuple literals and call arguments | LANDED | toolchain/parse/handle_paren_expr.cpp: `HandleParenExpr` (:46), `HandleExprAfterOpenParenFinish` (:63), `HandleTupleLiteralElementFinish` (:86) and `HandleCallExpr` (:116) each push `Expr` for the next element. |
| 7 | Deduction | LANDED, no packs | toolchain/check/deduce.cpp:291 `DeductionContext::Deduce`: a symbolic binding deduces from a constant (:363-400 and :402-433); a kind with `deduce_through` matches operand by operand (:444-454). |
| 8 | Calls | LANDED, fixed arity | toolchain/check/call.cpp:67 `ResolveCalleeInCall` checks `arg_ids.size()` against `param_patterns.size()` less the bound `self` (:79-86); `GetExplicitArityRange` (:424-433) returns `{n, n}`; `PerformCallToFunction` (:298); `PerformCallHelper` (:837); `PerformCall` (:871) defers template-dependent calls. |
| 9 | Pattern matching | LANDED | toolchain/check/pattern_match.cpp:2304 `MatchContext::Dispatch`, `CARBON_FATAL("Inst kind not handled: {0}", ...)` at :2374 and :2414 for an unknown pattern kind. |
| 10 | Tuple to array | LANDED | toolchain/check/convert.cpp:411 `ConvertTupleToArray`, dispatched at :1782; it uses a tuple literal's elements directly and otherwise indexes a materialized tuple. Each element is copy-initialized, which is why rev 2 does not store packs this way (M-22; amended 2026-10-14, review fold: A-B2 / B-M1). |
| 11 | Specifics in lowering | LANDED | toolchain/lower/file_context.cpp:531 `BuildFunctionDefinition` and :548 `BuildFunctionBody` lower one body per specific; toolchain/lower/function_context.cpp:68 `LowerBlockContents`; `SetLocal` (function_context.h:140) refuses a duplicate local. |
| 12 | Prelude tuple Copy | LANDED, hand-written | core/prelude/copy.carbon:49-71: "TODO: Implement tuple copy as a variadic generic impl." then impls for `()`, `(T,)`, `(T, U)` and `(T, U, V)`. There is no core/prelude/types/tuple.carbon (the brief's path does not exist; `ls core/prelude/types` lists none). |
| 13 | Arbiter | SKIP | fork/conformance/programs/generics/variadics_each.carbon: body commented out, `Run` returns 1, SKIP reason "no `...`/`each` tokens exist in toolchain/lex/token_kind.def". |
| 14 | Design | COMPLETE | docs/design/variadics.md, 964 lines; upstream a045da8e6 adds 36 (M-5). |
| 15 | Value aggregates | LANDED | toolchain/check/type_completion.cpp:570-589 `BuildStructOrTupleValueRepr` and :638-678: a tuple or struct value is the address of its elements' value representations (`ValueAggregate`, toolchain/sem_ir/type_info.h:46-48); convert.cpp:594-596 forms a `TupleValue` from the elements' values without copy-initializing them, so a tuple of a class without `Core.Copy` binds as a value (M-21). Rev 2's pack type uses a like representation, always passed by address (D-VA-3; amended 2026-10-14, review fold: A-B2 / B-M1; amended 2026-10-14, review fold: RR-m3). |

### §0.2 Measurements

Setup: `XDG_CACHE_HOME` is `$V/xdg-trunk` for the trunk toolchain
(`/home/user/carbon-build/carbon-trunk/install/bin/carbon`, `$T` below) and
`$V/xdg-nightly` for the nightly
(`/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon`,
`$N` below). Probe sources live in `$V/probes`; rev 2's live in `$F/probes`,
run with `XDG_CACHE_HOME=$F/xdg`. C++ prototypes were not
relinked: the relink recipe of the ST-1 fixer compiles patched sources against a
build's headers and relinks that build's objects, and every implementation
commit here edits an X-macro header that most objects include (M-19), so no
relinked binary would be the toolchain the commit describes. They were instead
compiled with `-fsyntax-only` (M-11), which runs the full C++ front end,
templates and `consteval` tables included, with the trunk build's flags.

**M-1. The SKIP body on trunk.** `$V/probes/sum.carbon` is the program's
commented body uncommented, with the `Core.Print` calls as written:

```carbon
import Core library "io";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total += each n;
  return total;
}

fn Run() -> i32 {
  Core.Print(Sum(1, 2, 3));
  Core.Print(Sum());
  return 0;
}
```

`XDG_CACHE_HOME=$V/xdg-trunk $T compile --output=sum.o --output-last-input-only
sum.carbon` fails in the parser, verbatim (carets omitted):

```text
sum.carbon:3:9: error: expected identifier or `Self` after `.`
sum.carbon:3:9: error: semantics TODO: `handle invalid parse trees in `check``
sum.carbon:3:10: error: expected identifier after `.`
sum.carbon:5:4: error: expected identifier or `Self` after `.`
sum.carbon:5:5: error: expected identifier after `.`
sum.carbon:5:21: error: expected `;` after expression statement
```

**M-2. The same body on the nightly.** The nightly carries 2ec4bab59 and fails
in the parser too, verbatim (carets omitted):

```text
sum.carbon:3:8: error: expected pattern
sum.carbon:3:8: error: semantics TODO: `handle invalid parse trees in `check``
sum.carbon:5:21: error: expected `;` after expression statement
```

`...` is now one token, a parameter list cannot start with it, and in the body
`...` starts a statement whose expression `total += each` ends before the second
identifier `n`, because `each` is an identifier there.

**M-3. What 2ec4bab59 lexes and parses.** `$V/probes/lex.carbon` holds
`... each n ...expand ...and ...or . .. ....`; the flags `--phase=lex`,
`--dump-tokens` and `--omit-file-boundary-tokens` give, on the nightly,
`PeriodPeriodPeriod`,
`Identifier` (`each`), `Identifier` (`n`), `PeriodPeriodPeriod`, `Expand`,
`PeriodPeriodPeriod`, `And`, `PeriodPeriodPeriod`, `Or`, `Period`, `Period`,
`Period`, `PeriodPeriodPeriod`, `Period` (14 tokens), and on trunk 24 tokens
in which every `...` is three `Period` tokens and `expand` is an `Identifier`.
`--phase=parse --dump-parse-tree` of `fn F(x: (i32, i32)) { ... G(expand x); }`
on the nightly gives the subtree `PackExpansionStart '...'`, `CallExprStart`,
`PrefixOperatorExpand 'expand'`, `CallExpr`, `ExprStatement ';'`,
`PackExpansionStatement '...'`. The nightly rejects, each with its first error:
`G(... expand x)` and `G(...expand x)` ("expected expression", at the `...`),
`let y: auto = (... x)` ("expected expression"), `fn F(... x: i32) {}` and
`fn F[... T: type]() {}` ("expected pattern"), `...and true;` ("expected
expression"); only the statement form parses. Upstream's own goldens agree:
2ec4bab59's toolchain/parse/testdata/variadics/pack_expansion_statement.carbon
covers `... G(expand x);`, `... var y: auto = expand x;`, `... if`, `... while`,
`... return;` and `... ... G(expand x);`, and expand.carbon covers `expand` as a
prefix operator with the precedence of prefix `*`.

**M-4. The cherry-pick.** In `$V/cp` at f67ab650d,
`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com git
cherry-pick -x 2ec4bab59` auto-merges 10 of its 12 files and conflicts in two:
toolchain/check/node_stack.h (one hunk: upstream's `case
Parse::NodeKind::PackExpansionStart:` lands between the fork's
`NamedConstraintIntroducer` and `PatternConditionInitializer` case labels; the
resolution keeps all three, in alphabetical order) and toolchain/parse/state.def
(seven hunks at :433, :616, :1639, :1652, :1666, :2024 and :2099, every line of
them a `//` comment). Upstream's state.def diff is 872 changed lines (441 added,
430 removed), of which exactly one is not a comment,
`CARBON_PARSE_STATE(StatementPackExpansionFinish)`, and about ten are the new
state's comment block; the other 860 are a mechanical renotation that rewrites
each placeholder `...` in a comment to `<...>` and each `???` to `<???>`, so
that `...` can mean the token, and re-aligns the caret line under it. Each
conflict is that renotation meeting a comment the fork added (union, `expr ?`,
match and let-else states). The resolution applies the same renotation to the
fork's side of each hunk with the carets moved by the inserted characters
(`$V/bin/renote.py`, which shifts a caret line only for insertions strictly
before the caret and keeps its length); the resolved diff against f67ab650d is
880 changed lines, still exactly one of them not a comment. Result: 3b4a431f0
(author Richard Smith, committer Claude, message upstream's plus "(cherry picked
from commit 2ec4bab59...)"). `git cherry-pick -x a045da8e6` then applies cleanly
(2f0d4c4c4), after `git fetch /home/user/carbon-lang
refs/remotes/upstream/trunk:refs/remotes/up/trunk` into the scratch clone (the
shared clone did not carry the upstream remote's objects). Nothing in either
commit is generated: state.def is an X-macro list included by the parser's
translation units, so "regenerating parse tables" is a recompile of the 42
objects that include it (M-19), which the relink recipe cannot stand in for.

**M-5. Upstream's shapes and direction.** 2ec4bab59 adds 958 lines and removes
430 in 12 files: the two tokens above; node kinds
`CARBON_PARSE_NODE_KIND_STATEMENT(PackExpansionStart)`,
`CARBON_PARSE_NODE_KIND_STATEMENT(PackExpansionStatement)` and
`CARBON_PARSE_NODE_KIND_PREFIX_OPERATOR(Expand)`; typed nodes
`PackExpansionStart` (a leaf on `...`) and `PackExpansionStatement` (bracketed
by it, with a virtual `...` token); `Expand` precedence equal to prefix `*`
(precedence.cpp); check handlers that are TODOs
(`HandlePackExpansionStart`, `HandlePackExpansionStatement`,
`HandlePrefixOperatorExpand`); goldens toolchain/lex/testdata/periods.carbon,
toolchain/parse/testdata/variadics/expand.carbon and
pack_expansion_statement.carbon, and toolchain/check/testdata/variadics/
pack_expansion.carbon (two `fail_todo_` splits). Its message: "No support for
`each` yet, but this should be enough that we can try out an implementation
approach supporting expanding a statement across elements of a tuple without
building "real" variadics." `expand` there is a prefix operator usable anywhere,
which is p002240's "Generalize `expand`" alternative, not the adopted
`...expand` element; a045da8e6 documents the checking/execution discrepancy that
alternative's discussion raised. Between 2ec4bab59 and 66a250ad9 upstream
changed toolchain/check/handle_pack_expansion.cpp not at all;
toolchain/parse/node_kind.def and typed_nodes.h changed only for fn
expressions (1b0a5709e, f83518bfd), away from the lines VA-1 adds (M-16).

**M-6. Upstream's pace.** `git rev-list --count 0bdce60a5..upstream/trunk` is
50 commits, dated 2026-10-05 to 2026-10-14; two of them touch variadics
(2ec4bab59, lex and parse with check TODOs; a045da8e6, docs), and no upstream
commit checks or lowers a pack expansion, an each-name or a pack expansion
pattern. The design is p002240 (pull request 2240; upstream is now past pull
request 7963); the fork's history of upstream is shallow (81 commits from
2026-09-29), so the date of the proposal's acceptance is not measurable here.

**M-7. Arrays with a deduced bound, on trunk.** `$V/probes/arith.carbon`
declares `fn Len[N: Core.IntLiteral](unused a: array(i64, N)) -> i32 { return N;
}`, `Fwd` (forwards its array to `Len`) and `Idx` (returns `a[0]`), and prints
`Fwd` of a three-element array, `Idx` of it, and `Len` of an empty `array(i64,
0)`: output `3`, `1`, `0`, exit 0. `$V/probes/arr.carbon` deduces `N` from
`array(i64, 3)` initialized from a tuple literal: output `0`, `1`. A variant
declaring `var b: array(i64, N + 1);` fails: "array bound is not a constant". So
a deduced `Core.IntLiteral` bound deduces, forwards, indexes and may be zero,
and has no arithmetic in a type, which is why merging segments (arity `N + k`)
is a TODO (D-VA-4, W-215). Rev 1 stored packs in such arrays; rev 2 keeps the
deduced `Core.IntLiteral` arity and stores the elements as values (D-VA-3),
because array storage copy-initializes every element (M-22; amended 2026-10-14,
review fold: A-B2 / B-M1).

**M-8. `Core.Print` takes an `i32`.** core/io.carbon:12 is `fn Print(x: i32) =
"print.int";`. `$V/probes/noas.carbon` (`Core.Print(F())` with `fn F() -> i64`)
fails on trunk: "cannot implicitly convert expression of type `i64` to `i32`",
note "type `i64` does not implement interface `Core.ImplicitAs(i32)`".
`$V/probes/asprobe.carbon` (a non-variadic `Sum3(a, b, c: i64)` with the body's
`total += a;` statements, printed with `as i32`, and a zero printed with `as
i32`) prints `6`, `0`, exit 0. So the arbiter's body, as written, would fail to
compile even with variadics; the un-SKIP adds `as i32` to each print and changes
nothing else (§1.6).

**M-9. Generic element types.** `$V/probes/gasg.carbon` (`fn Last[T:
Core.Copy](a: T, b: T) -> T { var r: T = a; r = b; return r; }`) fails on trunk:
"cannot access member of interface `Core.Destroy` in type `T` that does not
implement that interface"; with `T: Core.Copy & Core.Destroy` it prints `2`,
`7`. The slice's generic-element tests therefore pass the element by value
(`fn Consume[T: type](unused x: T) {}`), which needs neither.

**M-10. Who uses `...` or `each` today.** `grep -rnE '\.\.\.' --include=*.carbon
toolchain/*/testdata core | grep -vE '^\S+:[0-9]+:\s*//'` finds only lines of
C++ split files (`// --- *.h` and `inline Cpp` text) in
toolchain/check/testdata/interop; `grep -rnwE 'each' --include=*.carbon
toolchain core examples fork/conformance | grep -vE '^\S+:[0-9]+:\s*//'` finds
nothing. On upstream/trunk, `git grep -nwE each upstream/trunk -- '*.carbon'`
outside comments finds only utils/textmate/Samples/keywords.carbon:38, a list of
keywords. So making `each` a keyword and `...` a token changes the meaning of no
existing Carbon source in the fork (§6.1).

**M-11. Every implementation state compiles at the syntax level.**
`$V/bin/synchk.py` runs `clang++ <trunk cflags> <per-object extra flags>` with
`-fsyntax-only` (the `cxx`, `cflags` and `extra` of
/home/user/carbon-build/carbon-trunk/build.ninja, include root switched to the
tree under test) over the 315 Carbon translation units of that build
(`$V/all_tus.txt`). Results: the prototype's final state, `315 files, 0 failed`;
every file edited after that sweep started, re-run alone with the same flags
(check/handle_pack_expansion.cpp, handle_name.cpp, type.cpp, call.cpp,
check_unit.cpp, diagnostics/kind.cpp, lower/handle.cpp,
lower/function_context.cpp): 0 failed; the new
toolchain/lower/handle_pack_expansion.cpp, which the trunk build does not list,
with the `extra` flags of lower/handle.cpp: rc 0. The commit-3 and commit-4
states (`va1-c3`, `va1-c4`) are swept the same way in §8.0; the result is
recorded there. `-fsyntax-only` with `-Werror -Wall -Wextra` covers every
template instantiation and `consteval` table (the node-stack id-kind table, the
per-kind lowering and stringify dispatch) but not code generation or linking.
Rev 2 (amended 2026-10-14, review fold: A-B1, A-B2, A-M1, A-m1, A-m3, B-M1,
B-M2, B-M3): the same script over the same 315 units plus
check/handle_pack_expansion.cpp, on scratch worktrees of `fx-c4` and `fx-c5`:
316 units, 0 failed, at each (`$F/synchk_c4_all.out` and
`$F/synchk_c5_all.out`); lower/handle_pack_expansion.cpp with lower/handle.cpp's
flags (`$F/bin/synchk_as.py`): rc 0 at both; check/handle_pack_expansion.cpp,
one of the 316, has the default flags, which are also check/handle_name.cpp's.
C3's code is rev 1's (`fx-c3` adds one parse golden split), so rev 1's C3 sweep
stands (§8.0). The files the seven mutants of §8.5 change, each at its mutant
(`$F/bin/mutsweep.sh`): eight checks, rc 0 at each (function_context.cpp at
MU-1, MU-2 and MU-3, lower/handle_pack_expansion.cpp at MU-4 with
lower/handle.cpp's flags, call.cpp at MU-5 and MU-7, deduce.cpp at MU-6,
check/handle_pack_expansion.cpp at MU-7; `$F/mutsweep.out`), so every mutant is
C++ that compiles and only a run catches it.

**M-12. Formatting.** After one `clang-format -i` (21.1.8, the
.pre-commit-config.yaml pin) of the 42 changed C++ and `.def` files,
`clang-format --dry-run -Werror` passes on all of them; the reformat re-wrapped
14 files (53 lines added, 59 removed) and reordered no `#include`. The base
files were clean before the edits. Rev 2: after one `clang-format -i` of the
C++ and `.def` files the fold changed, `--dry-run -Werror` passes on every
changed C++ and `.def` file of `fx-c4` and `fx-c5` (amended 2026-10-14, review
fold: the fold's own code).

**M-13. Diagnostics registry.** `uv run --python 3.12 --no-project python
toolchain/diagnostics/check_diagnostics.py` (the host Python 3.11 lacks
`typing.override`) passes on the prototype; renaming one new kind in kind.def
makes it print "Unused diagnostic: PreviousPackExpansionPatternX" (negative
control). Rev 2, on `fx-c5`, where `PackNameWithoutEach` is removed (D-VA-11):
passes; renaming `EachNameNotPack` in kind.def prints "Unused diagnostic:
EachNameNotPackX" (negative control; amended 2026-10-14, review fold: A-m2).

**M-14. Conformance headers.** With §2.7's six programs copied into the scratch
clone and `runner.py --update-readme-table` run ("updated program table in
README.md (155 programs)"), `runner.py --self-test` prints "self-test: 155
programs parsed, 56 bullets in table, OK"; before the table update it reports
the README table stale, as it must. Rev 2, with §2.7's nine programs in
`$F/cp`: "updated program table in README.md (158 programs)", then
"self-test: 158 programs parsed, 56 bullets in table, OK" (amended 2026-10-14,
review fold: A-B1, A-B2, B-M1, B-M2).

**M-15. Collisions.** In `$V/cp`, with every `claude/carbon-fork-0-1-*` branch
of /home/user/carbon-lang fetched as `lc/claude/*`, the command
`git merge-tree --write-tree --name-only <branch> <prototype>` against the
prototype (7328f804d,
whose toolchain files equal the final ones but for formatting and three later
hunks) is compared with the same command against f67ab650d, so that conflicts
the branch already has with trunk are not counted: §6.2's table. No branch
gains a conflict. Rev 2 re-measured the same way in `$F/cp` against `fx-c5` and
every branch's head at the time of the fold (§6.2 gives each head): no branch
gains a conflict (amended 2026-10-14, review fold: B-M1, the fold's new
files).

**M-16. The next upstream advance.** `git merge-tree --write-tree --name-only
up/trunk <tree>` (up/trunk is 66a250ad9): 71 conflicted files for f67ab650d, 71
for f67ab650d plus the two cherry-picks (they neither add nor remove one), 74
for the prototype. The three added are toolchain/check/handle_pack_expansion.cpp
(both sides add the file; the fork's version contains upstream's three handlers,
one of them unchanged and two replaced), toolchain/parse/node_kind.def and
toolchain/parse/typed_nodes.h (both sides insert after the same
`PackExpansionStatement` lines, upstream nothing and the fork its new kinds).
Each resolves by taking the fork's side, which contains upstream's lines
verbatim. Rev 2 (amended 2026-10-14, review fold: B-m4): rev 1's 74 left out
the fill. F4 refills upstream's check golden
toolchain/check/testdata/variadics/pack_expansion.carbon, which upstream has
not changed since 2ec4bab59 (`git diff 2ec4bab59 upstream/trunk --
toolchain/check/testdata/variadics/` is empty), so the advance sees an add/add
conflict there too. Measured in `$F/cp`: rev 1's prototype with that file
edited as a refill would edit it, 75; `fx-c5` (whose C4 renames the file's
first split, D-VA-12), 75; `fx-c5` with a simulated refill, 75. The four added
files are handle_pack_expansion.cpp, node_kind.def, typed_nodes.h and that
golden; the golden resolves by taking upstream's file and refilling it.

**M-17. The C++ oracle.** `/home/user/llvm/bin/clang++ -std=c++17 -pthread`
of §2.7's variadics_sum_diff.diff.cpp, run: `123`, `11`, `0`, `30`, `0`, exit
0, which are the values §1.6 derives by hand.

**M-18. Ids.** The re-scan in the head: at rev 1, maximum W-232; at rev 2,
maximum W-244 (DD-1's unused W-240..W-244); both times W-212..W-231 and F-018
named only as VA-1's reservation and F-017 only as OX-1's.

**M-19. Why a full build is needed.** From `ninja -t deps` of the trunk build
(319 objects): token_kind.def is a dependency of 254 objects, node_kind.def of
244, state.def of 42, typed_nodes.h of 186, inst_kind.def of 177, typed_insts.h
of 176, check/node_stack.h of 106, and diagnostics/kind.def of 268 (amended
2026-10-14, review fold: B-m9's check, a line no longer starts with a number and
a period).

**M-20. Lowering conventions the slice relies on.** The `ArrayIndex` lowering
(toolchain/lower/handle.cpp:46-74) reads an `IntLiteral` index from its constant
value and any other index with `GetValue`, and adds the index to the specific's
fingerprint (`AddIntToCurrentFingerprint`, function_context.cpp:590); the
specific coalescer merges two specifics whose fingerprints match
(specific_coalescer.h: "Two function definitions, from the same generic, with
different specific_ids are considered equivalent if, at the LLVM level, one can
be replaced with the other"). So a loop count that depends on the specific must
be fingerprinted (D-VA-9). Rev 2 no longer lowers `each x` through
`ArrayIndex`; the fingerprint rule is what still applies (amended 2026-10-14,
review fold: A-B2 / B-M1).

**M-21. A tuple value binds its elements without copying them, on trunk**
(amended 2026-10-14, review fold: A-B2 / B-M1). `$F/probes/tuplevalue.carbon`
declares a class `C` whose `Core.Copy` impl prints 100 plus its field, a class
`D` with no `Copy` impl, `fn TakeTup(t: (C, C))` and `fn TakeTupD(t: (D, D,
D))`, each printing fields of its elements, and calls `TakeTup((c, d))` and
`TakeTupD((e, f, f))` with `let`-bound values: output `1`, `2`, `3`, `4`, exit
0, so no `Copy.Op` ran and a class without `Copy` was accepted. Its LLVM IR
(`--phase=lower --dump-llvm-ir`) shows the representation: `main` allocates
`{ ptr, ptr }`, stores the two values' addresses into it and passes its
address; `TakeTup` loads each element's address back. A value of a tuple type
holds its elements' value representations; D-VA-3 gives packs the same
representation.

**M-22. An array element initialized from a value is copied, on trunk**
(amended 2026-10-14, review fold: A-B2 / B-M1; review A's probes, re-run in
`$F/probes`). `copy.carbon` passes `(c, c)` to `fn TakeArr(unused a: array(C,
2))` for a class `C` without `Copy` and fails, verbatim: "error: cannot copy
value of type `C`", note "type `C` does not implement interface `Core.Copy`",
note "initializing function parameter". `copyfx.carbon` gives `C` a `Copy` impl
that prints 100 plus its field and calls `TakeOne(c)` (a plain value
parameter), then `TakeArr((c, d))`: output `1`, `0`, `101`, `102`, `1`, `2`,
exit 0, so the array parameter ran `Copy.Op` once per element and the value
parameter did not. Rev 1's pack storage took exactly this path, from a pack
literal (its `ConvertTupleToArray` read the literal's elements) and from a
forwarded expansion (its `PackExpansionInit` initialized each element in place).

**M-23. clang-tidy's `misc-no-recursion`** (amended 2026-10-14, review fold:
B-M3). `$F/bin/tidy.py` runs `/home/user/llvm/bin/clang-tidy` (21.1.8) with
`--checks='-*,misc-no-recursion' --warnings-as-errors='*'`, no line filter, with
the trunk build's flags. On rev 1's C5 toolchain/check/pattern_match.cpp:
"pattern_match.cpp:2325:20: error: function 'Dispatch' is within a recursive
call chain [misc-no-recursion,-warnings-as-errors]", because rev 1 put the new
`DoPreWork` between the `NOLINTNEXTLINE(misc-no-recursion)` comment and
`Dispatch`. On `fx-c5`, with `DoPreWork` above the comment pair: rc 0 and no
diagnostic (`$F/tidy_fx_c5_pm.log`). With the repository's .clang-tidy minus
`modernize-*` (whose checks crash the bundled front end, review B's
measurement), line-filtered to the lines `fx-c5` changes against C2 (review B's
`tidyall.py`, `$F/bin/tidyall.py`): 29 `.cpp` files, rc 0 and no diagnostic in
each (`$F/tidyall_fx_c5.log`). Review B's run on rev 1's C5 had 28 files, all
clean; rev 2 adds cpp/export.cpp, handle_function.cpp and
handle_pattern_list.cpp and no longer changes lower/handle.cpp or
sem_ir/expr_info.cpp.

**M-24. Default values and pattern walkers** (amended 2026-10-14, review fold:
A-m1, A-m3). Default parameter values are upstream's: call.cpp:306-310 counts
`default_value_arity`, and handle_pattern_list.cpp:331-372 wraps the element
pattern, a pack expansion pattern included, in a `DefaultValuePattern`; rev 1's
`GroupPackArguments` ignored both. This grep over toolchain/check and
toolchain/sem_ir finds the walkers over parameter patterns that §2.4 audits:

<!-- google-doc-style-ignore -->

```sh
grep -n 'DefaultValuePattern\|TuplePattern\|AnyVarPattern' \
  toolchain/check/*.cpp toolchain/check/cpp/*.cpp toolchain/sem_ir/*.cpp
```

<!-- google-doc-style-resume -->

**M-25. Rev 3's re-measurements** (amended 2026-10-14, review fold: RR-M1,
RR-m2). Rev 3 changes four files of the prototype, each of which rev 2 already
changes: toolchain/check/handle_pack_expansion.cpp (RR-M1's one hunk), the check
golden fail_pack_expansion.carbon (one split), the lower golden (one split) and
variadics_forward.carbon (two functions and one print). In `$R`, with the trunk
build's flags and `$F/cp`'s checkout of `fx-c5` as the include root (every
header that file includes is the same at `fx-c5`, `rr-c4` and `rr-c5`),
check/handle_pack_expansion.cpp at `rr-c4` gives `-fsyntax-only` rc 0
(`$R/synchk.py`), and rc 1 with "no matching function for call to
'RequireCompleteType'" when the call's location argument is deleted (negative
control); the same file at `rr-mu-7` gives rc 0. A `clang-format -i` (21.1.8) of
a copy changes nothing. clang-tidy with the repository's .clang-tidy minus
`modernize-*`, line-filtered to the changed hunk, gives rc 0 and no diagnostic
(`$R/tidy_hpe.log`). `runner.py --self-test` on an extract of `rr-c5`'s
fork/conformance, gap-analysis.md and milestones.md prints "self-test: 158
programs parsed, 56 bullets in table, OK" and variadics_forward "[stdout: 5
lines; exit: 0]", and `--update-readme-table` leaves the README unchanged
(`$R/selftest.log`). No diagnostic kind is added, so M-13 stands. None of the
four files exists on any of the head's 76 refs, and no upstream commit after
2ec4bab59 touches handle_pack_expansion.cpp or the variadics testdata (`git log
2ec4bab59..upstream/trunk` on those paths prints nothing), so M-15's and M-16's
counts stand.

### §0.3 Ledger, row and brief claims found stale (each corrected where §2 says)

1.  Row 53 and the arbiter's SKIP reason say "no `...`/`each` tokens exist in
    token_kind.def"; after commit 1 `...` exists (from upstream), and after
    commit 3 `each` does. Both texts are replaced by commits C5 and R (§2.7,
    §2.8).
2.  The brief names core/prelude/types/tuple.carbon for the tuple Copy impls;
    they are in core/prelude/copy.carbon:49-71 (§0.1 row 12).
3.  W-013's notes cite `GetExplicitArityRange` at toolchain/check/call.cpp:338;
    it is at :424 at f67ab650d, and VA-1's own changes to call.cpp move it (:558
    at 9a0888ef0, :578 at 0ee9f2d1b), so the discharge corrects the citation to
    the line it measures at the merge commit (§2.8; amended 2026-10-14,
    implementation-review fold: VA1-IR2-m5).
4.  The arbiter's commented body would not compile even with variadics, because
    it prints an `i64` with `Core.Print` (M-8). The un-SKIP repairs it with `as
    i32` and says so in the header (R10, R16(d)).
5.  gap-analysis.md's W6 arbiter ("the worked examples in
    docs/design/variadics.md compile and execute; core/prelude tuple Copy/Eq
    rewritten as a single variadic impl") is the whole item's, not this
    slice's; the discharge keeps it and adds the slice's sentence (§2.8).
6.  Rev 1's W-228 assumed that exporting a variadic function to C++ is
    diagnosed. toolchain/check/cpp/export.cpp:339-354 instead reaches
    `CARBON_CHECK(param_ident, "non-identifier param name {0}")` at :349 for
    the arity binding, whose special name has no C++ identifier
    (toolchain/check/cpp/import.cpp:2904-2910 returns null for one), so the
    compiler aborts before the TODO at :352-353 (hand-predicted from that code
    path; amended 2026-10-14, review fold: A-M1). C4 adds the TODO `exporting a
    variadic function to C++` ahead of the generic export (§2.4).

## §1 Design

Every decision below auto-adopts the design's recommendation under V-2 and V-3
(R29(a)) and is recorded for after-the-fact veto in the decision-log entry
"VA-1" (§2.8). Each carries a one-sentence break condition: the observation
that would make the decision wrong.

### §1.1 Upstream's commits come first, unmodified in substance (D-VA-1)

**D-VA-1.** Commits 1 and 2 are `git cherry-pick -x 2ec4bab59` and `git
cherry-pick -x a045da8e6`, made on this branch exactly as M-4 made them in
scratch: upstream's author and message are kept, the committer is
`Claude <noreply@anthropic.com>`, `-x` appends "(cherry picked from commit
...)", and **the fork's trailers (the author override, Co-Authored-By and
Claude-Session lines) are not added to either commit**, because the commits are
upstream's work and the next upstream advance should see them as the same
change. The only edits are the conflict resolutions of M-4: the node_stack.h
case label kept in order, and the seven state.def comment hunks renoted the way
upstream renoted its own lines. VA-1 then extends upstream's shapes rather than
inventing parallel ones: `PackExpansionStart` starts every pack expansion
(statement, expression element and pattern element), the new node kinds sit
beside upstream's in node_kind.def and typed_nodes.h, and upstream's TODO
handlers in toolchain/check/handle_pack_expansion.cpp are replaced in place, not
renamed, with `HandlePrefixOperatorExpand` left as upstream's TODO (W-217).
Re-deriving the lexer and parser instead would put a second, different
`PeriodPeriodPeriod` and state set into the fork that the next advance must
reconcile hunk by hunk against upstream's 872-line state.def change (M-4);
cherry-picking adds no conflict to that advance (71 before and after, M-16).
Upstream's two messages are kept byte for byte, and so carry two things the
fork's own text never writes: each subject line's upstream pull-request
suffix (upstream pull requests 7832 and 7963, in upstream's own notation) and,
in 2ec4bab59, an `Assisted-by:` trailer naming the assistant upstream used.
Both are an explicit, recorded exception to R31(a)'s rule on such references
and to the fork's rule against naming models in fork-authored text, which
govern what the fork writes; rewriting either would make C1 and C2 different
changes from upstream's (amended 2026-10-14, review fold: B-m9).
_Break condition:_ the next upstream advance shows a conflict in a file the
cherry-picks touched that taking the fork's side does not resolve, or upstream
reverts or reshapes 2ec4bab59's node kinds before VA-1 merges.

### §1.2 The design's rules, each IN or OUT of this slice

Numbered DR-n (DR-1 to DR-42) so that §1.11 and the reviews can cite them; line
numbers are docs/design/variadics.md at f67ab650d. IN means implemented and
covered by a golden or program in §4 and §5; OUT means diagnosed (by the
design's own rule where it gives one, otherwise by a `semantics TODO` with a
golden) and filed.

1.  DR-1. `...` is one token that begins a pack expansion (:44-47,
    :103-118). **IN** (commit 1, upstream's token).
2.  DR-2. `each` is a keyword; an each-name is `each` and a name (:46-47,
    :91-92). **IN** (commit 3; D-VA-10).
3.  DR-3. `each` is part of the name syntax and binds more tightly than any
    expression syntax, so `each x.f()` is `(each x).f()` (:97-101). **IN**
    (commit 3: `EachNameExpr` is a primary expression, parse golden
    `each.carbon` split `expr`).
4.  DR-4. A pack is a fixed number of values, possibly of different types, and
    no run-time expression evaluates to a pack (:85-90). **IN** for packs whose
    elements have one type; packs of different types **OUT** (W-212). A
    pack's name without `each` is a `semantics TODO` (D-VA-11, W-230): the
    design leaves the bare name open (amended 2026-10-14, review fold: A-m2).
5.  DR-5. A pack's arity is a compile-time value (:89-90). **IN**: a deduced
    symbolic binding of type `Core.IntLiteral` (D-VA-3).
6.  DR-6. An each-name can only occur inside a pack expansion (:91-92).
    **IN** (`EachNameOutsidePackExpansion`, `EachBindingOutsidePackExpansion`).
7.  DR-7. A binding pattern with an each-name declares the pack's elements and
    so the pack (:93-96). **IN**.
8.  DR-8. A statement pack expansion `... statement` (:107). **IN** when the
    statement is an expression statement; any other statement **OUT** (W-218),
    diagnosed `semantics TODO: pack expansion of a statement other than an
    expression statement`.
9.  DR-9. A tuple expression element `... expression`, with the precedence of
    `,` (:108-109). **IN** in a call's argument list; in any other tuple
    literal **OUT** (W-213).
10. DR-10. A tuple pattern element `... pattern`, with the precedence of `,`
    (:110-111). **IN** in a function's explicit parameter list; in any other
    tuple pattern **OUT** (W-214).
11. DR-11. An implicit parameter list element `... pattern` (:112-113).
    **OUT** (W-212); it parses (commit 3) and checks to a TODO.
12. DR-12. `...and` and `...or` (:114-115, :307-314). **OUT** (W-216); they
    lex as `...` and a keyword and fail to parse ("expected expression").
13. DR-13. The element `...expand expression`, which is not a pack expansion
    and requires a tuple operand (:120-130). **OUT** (W-217); upstream's
    prefix-operator parse is cherry-picked and its check stays upstream's TODO.
14. DR-14. Parentheses whose nearest content is `...` form a tuple, even
    without a comma (:134-140). **IN** in the parser; checking such a tuple
    literal is **OUT** with DR-9 (W-213).
15. DR-15. `...` is followed by whitespace except before `and`, `or` and
    `expand` (:141-144). **N/A**: a convention; nothing to implement (amended
    2026-10-14, review fold: B-m3).
16. DR-16. All each-names in one expansion name packs of the same arity
    (:146-147). **IN**: an expansion takes the arity of its first each-name,
    and a different arity is a TODO that the slice cannot reach, because a
    function has at most one pack (W-222).
17. DR-17. An expansion without each-names must be a pattern, or an
    expression in the type position of a binding pattern (:147-149). The
    error is **IN** for statement and expression expansions
    (`PackExpansionWithoutEachName`). A pattern expansion without an each-name
    is **OUT** (W-221): its binding without `each` is DR-23's error and any
    other operand is a `semantics TODO`. The type-position form is **OUT**
    (W-212) (amended 2026-10-14, review fold: B-m3).
18. DR-18. A pack expansion cannot contain another pack expansion or
    `...expand` (:151-152). **IN** (`NestedPackExpansion` with the note
    `EnclosingPackExpansion`); the `...expand` half is **OUT** with W-217.
19. DR-19. An each-name cannot be used in the expansion that declares it
    (:154-157). **IN**, vacuously: the slice's only declaring expansion is a
    parameter whose name is not in scope in its own type.
20. DR-20. An expansion is a loop run at monomorphization over the pack index
    0 to N - 1 (:161-167, :298-302). **IN** (D-VA-9).
21. DR-21. `...` in a tuple literal behaves like N comma-separated elements
    (:199-202, :316-318; amended 2026-10-14, review fold: RR-m1). **IN** for
    call arguments: an expansion argument is
    evaluated where it is written, before the arguments after it, as
    pattern_matching.md :1045-1047 requires ("the overall evaluation order is
    always consistent [...] with the written order of the scrutinee
    expressions"); variadics_arg_order and §8.5's MU-7 pin it. Rev 1 ran the
    expansion's body during the call's conversion, after every later
    argument (amended 2026-10-14, review fold: A-B1 / B-M2).
22. DR-22. A pack expansion pattern matches a sequence of elements if each
    matches its subpattern (:206-213). **IN**.
23. DR-23. A binding inside a pack expansion pattern must declare an
    each-name (:214-218). **IN** (`PackExpansionBindingWithoutEach`).
24. DR-24. That binding's type may contain an each-name only if it is a
    deduced parameter of the enclosing pattern (:218-220). **OUT** (W-212).
25. DR-25. The order is `...` phase modifier `each` name (:222-234). **IN**
    in the parser for every phase and modifier; in check **IN** for a value
    binding only, `ref`, `var` and phase-keyword each-bindings **OUT** (W-221).
26. DR-26. A statement expansion executes its statement N times (:304-305).
    **IN**.
27. DR-27. An each-name evaluates to the `$I`th value of its pack (:320-321).
    **IN**.
28. DR-28. Pattern matching is the inverse of evaluation and happens at
    monomorphization (:325-330). **IN**.
29. DR-29. A tuple pattern has at most one `...` subpattern; the N elements
    before it and M after it match the scrutinee's first N and last M, and a
    scrutinee of fewer than N + M elements does not match (:332-337). **IN**
    for parameter lists (`MultiplePackExpansionPatterns`,
    `CallArgCountTooFewForPack`).
30. DR-30. The remaining elements match the operand in order, `$I` counting
    from 0 (:339-344). **IN**: the Nth element is bound to the Nth scrutinee
    as a value binding binds its scrutinee, with no copy initialization
    (docs/design/values.md :186-187; amended 2026-10-14, review fold: RR-m1);
    rev 1 copy-initialized each element into
    an array (amended 2026-10-14, review fold: A-B2 / B-M1).
31. DR-31. Segments, pack literals `⟬⟭`, arity coercions `«E; N»`, shapes and
    scalar components (:348-448). **IN** for one segment only: `«E; N»` is the
    new `PackType`, and the run of arguments a pattern matches is a
    `PackLiteral` of one-element segments; multi-segment shapes **OUT** (W-212,
    W-215).
32. DR-32. Iterative typechecking: every each-name in an expansion has the same
    shape, the expansion is checked segment by segment, and within a segment an
    each-name has the scalar component of its type (:452-481). **IN** for one
    segment: the body is checked once, `each x` having the element type
    (D-VA-8).
33. DR-33. A statement expansion needs no further typechecking; `...and` and
    `...or` are `bool`; a tuple element expansion's segments become the
    enclosing tuple's (:483-490). **IN** for statements and call arguments;
    `...and`/`...or` **OUT** (W-216); tuple types with pack segments **OUT**
    (W-213).
34. DR-34. Type versus execution semantics (a045da8e6, :494-527 after commit
    2). **IN** as documentation (commit 2); its example needs an `if`
    expression in an expansion body and a tuple-pattern operand, **OUT**
    (W-219, W-221).
35. DR-35. Fixed and deduced arity; at most one deduced-arity segment per tuple
    pattern (:494-510). **IN**: the slice's pattern expansions all have
    deduced arity, at most one per parameter list; fixed-arity expansions
    **OUT** (W-222).
36. DR-36. Merging a full pattern's segments into canonical form, which
    rewrites `Min[T](first: T, ... each next: T)` to one pack parameter
    (:512-587, :807-937). **OUT** (W-215); the slice matches the fixed
    parameters around the pack position by position and needs no merge.
37. DR-37. Typechecking a match by splitting and merging scrutinee segments,
    deducing the arity (:589-641). **IN** for a scrutinee that is k
    one-element segments (a pack literal, arity k) or exactly one expansion
    segment (forwarding, arity equal to the argument's); merging an expansion
    with other segments **OUT** (W-215).
38. DR-38. Explicit deduced arities: each pack expansion pattern introduces a
    deduced `__N: Arity`, and `each X: T` becomes `each X: «T; __N»`
    (:654-662). **IN** (D-VA-3): the arity binding is named `<pack arity>`
    (`arity` in SemIR) and has type `Core.IntLiteral`, and `each n: E` is
    declared with the type `«E; N»` itself (amended 2026-10-14, review fold:
    A-B2 / B-M1).
39. DR-39. `Arity` supports only `+` (:664-668). **OUT** (W-215); the slice's
    arity has no `+` (M-7).
40. DR-40. The type of an each-name expression is its binding's type
    expression; the type of a pack expansion is `...B`; `each x: auto` invents
    `each __X` (:694-714). **IN** for the first two (an expansion's type is the
    `PackType` of its body's type); `auto` **OUT** (W-212).
41. DR-41. Reduction and equivalence rules (:716-805). **IN** only "Expansion
    convertibility" (:794-796) for one segment, `...T` converting to `...U` of
    equal arity when `T` converts to `U` (at the call, by a second expansion
    whose body converts each element of the first; amended 2026-10-14, review
    fold: A-B1); the rest **OUT** (W-212, W-215). variadics_forward's
    `Narrowed` and the lower split `forward_converted_field` run it (amended
    2026-10-14, review fold: RR-M1).
42. DR-42. Packs cannot be indexed in Carbon code; `[:N:]` is notation only
    (:176-177). **IN**, vacuously: there is no pack-indexing syntax, and
    indexing a pack's bare name stops at D-VA-11's TODO (amended 2026-10-14,
    review fold: review B's summary, which found the rule missing from this
    list).

### §1.3 The slice and its syntax (D-VA-2, D-VA-10)

**D-VA-2 (the slice).** A function may have, in its explicit parameter list,
one pack expansion pattern whose operand is one each-name value binding of a
type that names no pack: `... each n: i64`, or `... each next: T` with `T` an
earlier deduced parameter, before, between or after ordinary parameters, and
outside an interface (W-229). The pack binds its arguments' values, of any
element type, a class without `Core.Copy` included (D-VA-3). Its body may
contain pack expansion statements over that pack whose body is an expression
statement without control flow or cleanups, and its calls (and calls
elsewhere) may pass pack expansion arguments `... e` where `e` uses each-names
of the enclosing function's pack, each evaluated where it is written (D-VA-4).
That is the design's machinery (DR-1..DR-10, DR-16..DR-33, DR-37, DR-38,
DR-40, DR-41) restricted to packs of one segment, which is everything the
arbiter and the design's SumInts and MiddleVariadic examples (:241-246,
:281-283) need, and it is a real definition check: the generic body is checked
once against the pack type, never per call. The design's StrCat, Zip, Min,
Apply and TupleConcat examples need W-212, W-213, W-215 or W-218 and are the
next slices' arbiters (§1.11). Rev 1 fired this decision's break condition
twice: an expansion argument ran after the arguments written after it (A-B1 /
B-M2), and each element was copied (A-B2 / B-M1); rev 2's D-VA-3 and D-VA-4
remove both causes and add the programs that see them, variadics_arg_order,
variadics_no_copy and variadics_generic_element (amended 2026-10-14, review
fold: A-B1, A-B2, B-M1, B-M2). _Break condition:_ a reviewer shows a form
inside this boundary that the prototype mis-checks or that lowers to the wrong
number or order of evaluations.

**Syntax accepted** (all from §2's parser changes, commit 3):

-   `each` before a binding name, after the phase keyword, `ref` and a
    misordered `unused`: `... template each T: type`, `... ref each x: i32`
    (parse golden `each.carbon`); the binding name must be an identifier
    (`ExpectedIdentifierAfterEachInBinding`).
-   `each name` as a primary expression, postfix operators applying to it
    (`ExpectedIdentifierAfterEach` when no identifier follows).
-   `...` at the start of an element of a tuple pattern, an explicit parameter
    list or an implicit parameter list (not a struct pattern), producing
    `PackExpansionStart`, the operand pattern and `PackExpansionPattern`.
-   `...` at the start of an element of a tuple literal or call argument list,
    producing `PackExpansionStart`, the operand expression and
    `PackExpansionExpr`; `( ... x )` is a tuple literal (DR-14).
-   `...` before a statement (upstream's, commit 1).

**Syntax diagnosed** (each with its golden in §4): every check-time TODO of
D-VA-4, D-VA-5, D-VA-6 and D-VA-11, each a `semantics TODO: <label>` from
`context.TODO`, which ends checking of the file as every TODO does; `...and`
and `...or`, which fail to parse (parse golden split `fail_todo_and_or`;
amended 2026-10-14, review fold: B-m3); and the design's own errors, which
recover where the parse allows and otherwise end checking (a nested
expansion, a second pattern expansion and a pattern binding without `each`
return `false` after their diagnostic, because the enclosing pattern or
expansion has no meaning to recover to).

**D-VA-10 (`each` is a keyword).** `CARBON_KEYWORD_TOKEN(Each, "each")` joins
token_kind.def, as the design says (:46-47, :91) and as the fork's and
upstream's editor grammars already list it (M-10); no existing Carbon source in
the fork uses `each` as a name (M-10), and a program that needs one can write
`r#each` (lex golden `each.carbon`). Upstream's lexer does not have it yet
(M-3). _Break condition:_ upstream lands variadics with `each` as a contextual
identifier rather than a keyword, in which case the fork follows upstream at
the advance and the lex golden is refilled.

### §1.4 SemIR and checking (D-VA-3..D-VA-8, D-VA-11)

**D-VA-3 (the arity and the pack's representation).** Following "Explicit
deduced arities" (DR-38), checking the `...` of a pattern expansion adds a
deduced symbolic binding pattern to the enclosing full pattern, before the
operand: its name is the new special name `NameId::PackArity` (spelled `arity`
in SemIR and `<pack arity>` in diagnostics, toolchain/sem_ir/name.cpp), its
type is `Core.IntLiteral`, which plays the design's `Arity` without its `+`
(DR-39), and it is never added to name lookup, so no source can name it and no
unused-binding warning can fire on it (AddBindingPattern adds no lookup entry,
toolchain/check/pattern.cpp:165-215). The each-name binding `each n: E` inside
the expansion is then declared with the type `«E; N»`, the new `PackType`, `N`
being that arity binding: the design's rewrite of `each X: T` to
`each X: «T; __N»`, taken literally. A pack is a sequence of values, so a value
of a pack type holds its elements' values: its value representation is always
a pointer to `N` element value representations, `ValueAndObjectAggregate` when
`E`'s value representation is its object representation and `ValueAggregate`
otherwise, the kind of representation a tuple value has (§0.1 row 15, M-21),
though a tuple of one element is passed by copy and a pack never is (amended
2026-10-14, review fold: RR-m3); and binding the pack binds each element as a
value parameter binds its argument, with no copy initialization and no
`Core.Copy` ("Value bindings require the matched expression to be a value
expression", docs/design/values.md :186-187; amended 2026-10-14, review fold:
RR-m1). A call forms the pack's value
from its arguments' values (`PackValue`) or from an expansion argument's
iterations (`PackExpansionExpr`), and an each-name use `each n` reads the
element at the pack index (`PackElement`, DR-27), a value of type `E`. The
expansion pattern itself is a `PackExpansionPattern` whose scrutinee type is
the same `PackType`. So a specific of the function knows `N`, and `n` is one
pack value per call. Rev 1 stored the pack as `array(E, N)`; initializing an
array element from a value copy-initializes it, which runs `Core.Copy.Op` once
per element and rejects a class without `Copy` (M-22), so rev 1 fired this
decision's own break condition (amended 2026-10-14, review fold: A-B2 /
B-M1). _Break condition:_ a pack whose elements need a representation an
elementwise value representation cannot give (different element types, W-212,
or reference elements, W-221) enters the slice, or the toolchain's aggregate
value representation changes so that a value aggregate copy-initializes its
elements.

**D-VA-4 (the call groups the pack's arguments).** Before deduction,
`PerformCallToFunction` groups the arguments of a callee with a pack expansion
pattern (`GroupPackArguments`, call.cpp): the arguments before and after the
pattern's position match the parameters before and after it one to one (DR-29,
with the bound `self` first, as `GetExplicitArityRange` counts it), and the run
between them becomes the pattern's single scrutinee. A run of ordinary
arguments becomes a new `PackLiteral` whose type is the tuple of their types
(the design's pack literal of one-element segments, DR-31); a run that is
exactly one pack expansion argument is passed as that argument's pack value
(forwarding, DR-37). An expansion argument is evaluated where it is written:
its handler emits the `PackExpansionExpr`, whose body runs once per element,
at the argument's own position, so the arguments after it are evaluated after
its elements, as the design's "series of comma-separated tuple elements"
(DR-21) and written-order evaluation require. Rev 1 left only a marker at the
argument and spliced the body into the call's conversion, after every later
argument: review A's `Digits(P(1), ... P(each x), P(9))` printed 1 9 2 3, not 1
2 3 9 (amended 2026-10-14, review fold: A-B1 / B-M2). Deduction (deduce.cpp, a
new `PackType` case) deduces `N` as the literal's element count, or as the
forwarded expansion's arity, and the element type against each element type
(so `[T: type](first: T, ... each next: T)` deduces `T` from every element).
Conversion to the parameter's `«E; N»` then forms a `PackValue` from a
`PackLiteral`, each element converted to a value of `E`
(`ConvertPackLiteralToPack`, convert.cpp), and leaves a forwarded pack value
of type `«E; N»` as it is or, for `«U; N»`, converts it by a second
`PackExpansionExpr` whose body converts each element of it
(`ConvertPackToPack`; DR-41's expansion convertibility). Three forms are TODOs,
each with a golden: an expansion argument merged with other arguments for one
pack (its arity is `N + k`, which needs DR-39's `+`, W-215); a pack expansion
in a tuple literal that is not a call's argument list (its type is a tuple
with a pack segment, W-213); and an expansion argument, or a variadic member,
in a call to an overload set (the probe of each member would group per
member, W-223). The slice's diagnostics at a call are
`CallArgCountTooFewForPack` (with the note `InCallToVariadicFunction` on the
callee), `PackExpansionArgForSingularParam`, the slice's diagnostic for a
match that the design's segment merging cannot typecheck (the design fails
such a call because it cannot deduce, for example, ‖next‖ + 1 == ‖n‖; DR-36,
DR-39), and `PackExpansionArgWithoutPackParam` (the callee has no pack
expansion parameter to take the segment; amended 2026-10-14, review fold:
A-m2). _Break condition:_ a call inside the slice whose grouped scrutinee
deduces a different arity, or converts its elements in a different order, from
the design's left-to-right iterative match (DR-30).

**D-VA-5 (what check refuses in the slice).** Each of these is a `semantics
TODO` with a fail_todo golden (§4): a pack expansion pattern outside a
function's explicit parameter list (implicit lists, tuple patterns; W-212,
W-214); an operand that is not exactly one each-name binding (W-221); an
each-name binding that is `ref`, `var` or carries a phase keyword (W-221); two
each-names in one operand (W-221); an expansion over packs of different arities
(defensive and unreachable, because a function has one pack; W-222); a pack
expansion argument in a template-dependent call (W-224); a default value
before, after or on a pack, whose binding the design does not give (W-215;
amended 2026-10-14, review fold: A-m1); a pack expansion pattern in an
interface function, whose impls' thunks would clone a pattern kind thunk.cpp
does not clone (W-229; amended 2026-10-14, review fold: A-m3's walker audit);
exporting a variadic function to C++ (W-228; amended 2026-10-14, review fold:
A-M1); and a pack's name without `each` (D-VA-11, W-230). _Break condition:_
any of these forms turns out to be needed by a program the gap row's bullet
requires for PARTIAL, which would make the slice too small to move the row.

**D-VA-6 (the body of an expansion is straight-line).** A statement or
expression expansion is checked into its own instruction block, which lowering
runs once per element. That block must stay one block and own no cleanup: the
body's statement must be an expression statement (a declaration would introduce
a name, and so storage, per element; W-218), it must not branch (`and`, `or`,
`if` expressions add blocks; W-219), and it must not create a temporary that
needs destroying (W-220). Each is checked when the expansion ends and is a TODO
with a golden; the cleanup TODO's goldens are toolchain/check/testdata/
variadics/fail_todo_cleanup.carbon, whose class has a `Core.Destroy` impl
(amended 2026-10-14, review fold: B-m3). A call's element conversion of a
forwarded pack (D-VA-4) is such a body too, and a conversion that would need a
cleanup is the TODO `pack element conversion that needs a cleanup` (split
`fail_todo_conversion_cleanup`; amended 2026-10-14, review fold: A-B1).
_Break condition:_ a lowering of a straight-line body that
depends on a value computed in an earlier iteration through anything other than
memory (a stale SSA value), which would show up as a wrong program result in
§5's mutants.

**D-VA-7 (eight new instructions).** All in typed_insts.h, listed in
inst_kind.def alphabetically, each with a formatter, namer and (for the type)
stringify case where one is needed (§2.4). Rev 1 had seven: its
`PackExpansionInit` (the deferred array initializer) is gone, and
`PackElement` and `PackValue` are new (amended 2026-10-14, review fold: A-B1,
A-B2, B-M1, B-M2):

| Inst (ir_name) | Fields | Constant kind | Category | Lowered as |
| --- | --- | --- | --- | --- |
| `PackType` (`pack_type`) | `type_id` (always `type`), `element_type_inst_id`, `arity_id` | `WheneverPossible`, `is_type` always, `deduce_through` | type | `[N x E]`; a value of it is always a pointer to `N` element value representations of `E`, `ValueAndObjectAggregate` when `E`'s value representation is its object representation, otherwise `ValueAggregate` (type_completion.cpp; amended 2026-10-14, review fold: RR-m3) |
| `PackElement` (`pack_element`) | `type_id` (the element type), `pack_id`, `index_id` | `Never` | value | a load of the element's value representation at the index from the pack's storage |
| `PackExpansionPattern` (`pack_expansion_pattern`) | `type_id` (pattern type of a `PackType`), `subpattern_id`, `arity_pattern_id` | `Always` | pattern | not lowered (`is_lowered = false`) |
| `PackExpansionStatement` (`pack_expansion_statement`) | `arity_id`, `body_block_id` | `Never` | not an expression | the body, `arity` times |
| `PackExpansionExpr` (`pack_expansion_expr`) | `type_id` (a `PackType`), `body_block_id`, `result_id` | `Never` | value | storage for the elements' values, then the body `arity` times where the instruction is, each iteration's `result_id` stored at the iteration's index; the value is the storage's address |
| `PackIndex` (`pack_index`) | `type_id` (`Core.IntLiteral`) | `Never` | value | the current iteration's index as an `i64` constant |
| `PackLiteral` (`pack_literal`) | `type_id` (a tuple type), `elements_id` | `Never` | mixed | nothing; it is always converted to a `PackValue` |
| `PackValue` (`pack_value`) | `type_id` (a `PackType`), `elements_id` | `Never` | value | storage for the elements' values, each stored; the value is the storage's address |

`PackType` prints as `«E; N»` (toolchain/sem_ir/stringify.cpp), the design's
arity coercion (DR-31), and imports (import_ref.cpp), as does
`PackExpansionPattern`, so an imported variadic function can be called
(golden `import.carbon`); a redeclaration compares the two patterns' operands
and arity patterns (merge.cpp, golden split `redecl.carbon`). The SemIR
verifier (dominance.cpp) treats an expansion's body as evaluated in place and
forgets what it defined when the expansion ends, since the body runs once per
element and nothing in it dominates the code after it. The design's
type/execution discrepancy (DR-34) does not arise in the slice: it needs an
expansion whose iterations have different types (an `if` expression inside an
expansion, W-219, over a pack of several types, W-212), and every pack value
of the slice has one element type (amended 2026-10-14, review fold: A-B2,
which made packs values). The handler of a pack expansion expression requires
its type `«R; N»` complete with `RequireCompleteType`, which for the symbolic
type of a variadic caller adds a `RequireCompleteType` instruction to the
generic, so that each specific's `«R; k»` is complete when lowering reads its
value representation, also when nothing else requires that type: in a forward
whose elements the call converts, such as `Sum(... ToI32(each x))` into a pack
of `i64`, only the converted `«i64; k»` is a parameter's or a conversion's
type. Rev 2 completed it with `CompleteTypeOrCheckFail`, which records nothing
for a symbolic type, so that forward was accepted and then crashed in lowering
(amended 2026-10-14, review fold: RR-M1; the lower split
`forward_converted_field`, variadics_forward's `Narrowed` and the mutant MU-8
see it). When `R` is incomplete, which forming a value of a facet type does not
diagnose, the requirement diagnoses `IncompleteTypeInPackExpansion` and the
expansion becomes an error (amended 2026-10-14, implementation-review fold:
MAJOR-1). _Break condition:_ the formatted SemIR of a golden shows an expansion
body evaluated outside its expansion, the verifier rejects a body the slice
accepts, or lowering meets a specific's pack type that is not complete.

**D-VA-8 (definition checking).** The body of a variadic function is checked
once, when it is defined, as any generic body is: `each n` is a `PackElement` of
the pack at a `PackIndex`, a value of the element type `E` (amended 2026-10-14,
review fold: A-B2 / B-M1) (a concrete type, or the symbolic `T` of `[T:
type](... each next: T)`); every operation on it is checked against `E` with the
ordinary rules, and an error is diagnosed at the definition whatever the calls.
This is the design's iterative typechecking (DR-32: "within a given iteration,
typechecking follows the usual rules of non-variadic typechecking, except that
when we need the type of an each-name, we use the scalar component of the
current segment of its type") for the one case the slice admits, a pack type of
one segment `«E; N»`, whose only scalar component is `E`: one segment, one
iteration of the typechecking loop. The body is never re-checked per call or per
specific; a specific only substitutes `N` and `T`. Rev 1's array storage met
"the reverse": a generic caller that passes a `T` to a pack, or forwards a pack
of `T`, was rejected at its definition for want of `T: Core.Copy` (review B's
probe `ByArray[T: type]`); rev 2 accepts both (check golden splits
`generic_caller` and `forward_generic`; amended 2026-10-14, review fold: B-M1).
_Break condition:_ a body the design's typechecking would reject is accepted for
a one-segment pack, or the reverse.

**D-VA-11 (a pack's name without `each`).** Naming a pack without `each` is a
`semantics TODO`, `use of a pack's name without `each``, not an error
(amended 2026-10-14, review fold: A-m2). The design gives such a use no
meaning yet ("no run-time expression evaluates to a pack", :87-88), and
p002240's "Omit each-names" (:637-645) keeps the bare name open on purpose,
for later operations on the whole sequence, so an error would decide a rule
the design leaves open, which D-VA-14 does not do without F-018. Rev 1 made it
the error `PackNameWithoutEach`; that diagnostic kind is removed. Name lookup
of an identifier expression checks the found binding against the file's packs
(`Context::pack_binding_arities`), at the cost of one hash lookup per
identifier expression; otherwise it builds the same name reference as before
(handle_name.cpp's `HandleNameAsExpr` inlined, M-11). Filed as W-230.
_Break condition:_ upstream gives a pack's bare name a meaning, or makes it an
error, in which case the TODO becomes that.

### §1.5 Lowering (D-VA-9)

**D-VA-9.** A variadic function always has its arity binding, so it is always
generic, and lowering already lowers one body per specific (§0.1 row 11): a call
`Sum(1, 2, 3)` makes the specific `N = 3`, `Sum()` the specific `N = 0`. Within
a specific, `PackExpansionStatement` reads its `arity_id` in the specific
(`GetConstantValueInSpecific`, which must be concrete there) and
`PackExpansionExpr` reads its pack type's arity; both call
`FunctionContext::LowerPackExpansionBody(arity, block, finish_iteration)`,
which lowers the body's instructions `arity` times in order, the pack index
taking each value from 0 to `arity` minus 1, calls `finish_iteration` after
each iteration (a `PackExpansionExpr` stores the iteration's result into the
pack's storage there), and then erases from `locals_` every value the
iteration set, so that the next iteration lowers the same instructions afresh
(`SetLocal` refuses duplicates). A `PackExpansionExpr` is lowered where it
stands in its block, which is the argument's position (D-VA-4), and its pack
type is complete in every specific (D-VA-7; amended 2026-10-14, review fold:
RR-M1). `PackValue`
stores its elements' values into new storage, `PackElement` loads one element
at the pack index, and `PackIndex` lowers to `ConstantInt(i64, index)` (amended
2026-10-14, review fold: A-B1, A-B2, B-M1, B-M2; rev 1 indexed an array and
needed an `ArrayIndex` change in lower/handle.cpp, which rev 2 does not touch).
The arity is added to the specific's fingerprint, so the coalescer never merges
two specifics that run a different number of iterations (M-20). The empty pack
runs no iteration, and its storage is `[0 x E]`. This is the design's execution
model exactly ("These semantics are implemented at monomorphization time, so the
value of N is a known integer constant", :300-301), and no run-time loop is
emitted. Nested expansions cannot reach lowering (check rejects them, DR-18),
and lowering CHECKs that. _Break condition:_ a specific's lowered body evaluates
an expansion body a number of times other than its arity, or in another order,
which §8's mutants are built to detect.

### §1.6 EXPECT re-derivation (R16(d): from the program text and the design, never from a run)

**variadics_each** (EXPECT 6, then 0; unchanged). `Sum(1, 2, 3)`: the run of
arguments `1, 2, 3` is the pack `n` of arity 3 (DR-29, DR-30); `total` starts
at 0; the statement `... total += each n;` executes its statement 3 times with
`$I` = 0, 1, 2 (DR-26), `each n` being the `$I`th element (DR-27), so `total`
becomes 1, then 3, then 6; `Sum` returns 6, and `Core.Print(6 as i32)` prints
`6`. `Sum()`: the pack has arity 0, the statement executes 0 times, `total`
stays 0, and the program prints `0`. `Run` returns 0 (EXPECT-EXIT 0).

**variadics_fixed_params** (12, 123, 4321). `Digits(first, ... each mid,
last)` starts `total` at `first`, appends each element of `mid` as a decimal
digit (`total = total * 10 + each mid`) and returns `total * 10 + last`. With
DR-29, the first argument is `first`, the last is `last`, the rest is `mid`:
`Digits(1, 2)` has `mid` empty, `total` = 1, result 1 * 10 + 2 = 12;
`Digits(1, 2, 3)` has `mid` = (2), `total` = 1 then 12, result 123;
`Digits(4, 3, 2, 1)` has `mid` = (3, 2), `total` = 4, 43, 432, result 4321.

**variadics_forward** (123, 246, 0, 8, 456; amended 2026-10-14, review fold:
RR-M1). `Digits(... each d)` with `total`
from 0 gives the decimal number whose digits are the arguments in order.
`Forward(1, 2, 3)` calls `Digits(... each d)`, which "behaves like a series of
comma-separated tuple elements" (DR-21): `Digits(1, 2, 3)` = 123. `Doubled(1,
2, 3)` calls `Digits(... each d + each d)` = `Digits(2, 4, 6)` = 246.
`Forward()` calls `Digits()` = 0. `Doubled(4)` = `Digits(8)` = 8.
`Narrowed(4, 5, 6)` calls `Digits(... ToI32(each d))`: the expansion evaluates
`ToI32(4)`, `ToI32(5)` and `ToI32(6)`, the `i32` values 4, 5 and 6, and the
call converts each to `i64` by DR-41's expansion convertibility (an `i32`
implicitly converts to an `i64`), so it is `Digits(4, 5, 6)` = 456.

**variadics_empty_pack** (7, 1, 2, 9). `PrintAll(... each n: i32)` prints
each element in order. `PrintAll()` prints nothing; `Core.Print(7)` prints 7;
`PrintAll(1, 2)` prints 1 then 2; `PrintAll()` nothing; `Forward()` forwards
an empty pack to `PrintAll`, nothing; `Core.Print(9)` prints 9.

**variadics_expansion_args** (19, 1239, 15559). `Digits(first, ... each mid,
last)` as in variadics_fixed_params. `Scaled(1)` has `x` empty and calls
`Digits(1, 9)` = 19. `Plain(1, 2, 3)` has `x` = (2, 3) and calls
`Digits(1, ... each x, 9)` = `Digits(1, 2, 3, 9)` = 1239. `Scaled(1, 1, 1, 1)`
has `x` = (1, 1, 1) and calls `Digits(1, ... each x * 5, 9)` = `Digits(1, 5, 5,
5, 9)` = 15559.

**variadics_sum_diff** (no EXPECT-STDOUT; the C++ oracle decides, and these
are the values it must print). `Horner(x, ... each c)` evaluates the
polynomial with coefficients `c` at `x`, highest first: `Horner(10, 1, 2, 3)` =
((0 _10 + 1)_ 10 + 2) * 10 + 3 = 123; `Horner(2, 1, 0, 1, 1)` = 1, 2, 5, 11,
so 11; `Horner(7)` = 0. `SumOfSquares(1, 2, 3, 4)` = `Sum(1, 4, 9, 16)` = 30;
`SumOfSquares()` = 0. M-17 ran the oracle and it printed exactly these.

**variadics_arg_order** (1, 2, 3, 9, 1239, 1, 9, 19; amended 2026-10-14, review
fold: A-B1 / B-M2). `Echo` prints its argument and returns it. `Plain(2, 3)`
calls `Digits(Echo(1), ... Echo(each x), Echo(9))`, which by DR-21 behaves like
`Digits(Echo(1), Echo(2), Echo(3), Echo(9))`, whose arguments are evaluated in
written order (pattern_matching.md :1045-1047): it prints 1, 2, 3 and 9, then
`Digits(1, 2, 3, 9)` is 1, 12, 123, then 1239, which `Run` prints. `Plain()`
has an empty pack: `Echo(1)` and `Echo(9)` print 1 and 9, and `Digits(1, 9)`
is 19.

**variadics_no_copy** (1, 2, 3, 4, 3, 4; amended 2026-10-14, review fold: A-B2
/ B-M1). `PrintPlain(p, q)` binds the pack to the values of `p` and `q` (DR-30)
and `... Core.Print(each p.a)` prints their fields, 1 and 2; `Plain` has no
`Copy` impl, so a copy could not even compile. `PrintLoud(l, m)` prints 3 and
4; a copy would run `Loud`'s `Copy.Op` first, printing 103 or 104.
`ForwardLoud(l, m)` passes its pack on with `... each l`, which binds the same
values again: 3 and 4.

**variadics_generic_element** (3, 2, 2; amended 2026-10-14, review fold: B-M1).
`One` returns 1 for any value, so `Count`, whose statement `... n += One(each
x)` runs once per element, returns the arity: `Count(true, false, true)`
deduces `T = bool`, `N = 3`, and prints 3; `Forward(7 as i64, 8 as i64)`
deduces `T = i64`, `N = 2` and forwards its pack with `... each x` to `Count`,
2; `Count(l, m)` deduces `T = Loud`, `N = 2`, and prints 2 and nothing else,
because binding the pack runs no `Copy.Op`.

### §1.7 Goldens (D-VA-12)

**D-VA-12.** Fourteen new golden files, each a source with `// AUTOUPDATE` and
no CHECK line (R15, R16(a)), with a `fail_` split for every new diagnostic and
every new reachable TODO (§4): toolchain/lex/testdata/each.carbon;
toolchain/parse/testdata/variadics/each.carbon, pack_expansion_expr.carbon and
pack_expansion_pattern.carbon; toolchain/check/testdata/variadics/
each_param.carbon, forward.carbon, import.carbon, fail_call.carbon,
fail_each_name.carbon, fail_pack_expansion.carbon, fail_todo_slice.carbon,
fail_todo_cleanup.carbon and fail_todo_export.carbon;
toolchain/lower/testdata/variadics/pack_expansion.carbon. The one unreachable
TODO, `pack expansion over packs of different arities` (a function has one
pack), has no split (W-222). Upstream's four goldens arrive with commit 1
carrying upstream's CHECK lines. One of them,
toolchain/check/testdata/variadics/pack_expansion.carbon, changes output in
commit 4: its split `fail_todo_pack_expansion_statement.carbon` (`... F();` in
`fn F()`) stops being the TODO `HandlePackExpansionStart` and becomes the
design's error `PackExpansionWithoutEachName`. C4 renames that split to
`fail_pack_expansion_without_each_name.carbon` and F4 refills the file by
autoupdate. Rev 1 kept the name, to spare the next advance a conflict, but F4's
refill already makes the file an add/add conflict there (M-16: 75 conflicts, not
74), so the rename costs nothing more; and file_test only strips `todo_` and
enforces only `fail_` (testing/file_test/test_file.cpp:383-386,
file_test_base.cpp:134-146), so rev 1's break condition could never fire
(amended 2026-10-14, review fold: B-m4, B-m3). _Break condition:_ the next
advance's conflict in that file does not resolve by taking upstream's file and
refilling it.

### §1.8 Conformance programs (D-VA-13)

**D-VA-13.** The arbiter un-SKIPs and eight programs join it, all under the
bullet "Generics: Definition-checked variadics", each 10 to 60 lines, each
arbitrating one concept, each EXPECT derived in §1.6; the last three are
rev 2's, each the program that would have caught one of rev 1's defects
(amended 2026-10-14, review fold: A-B1, A-B2, B-M1, B-M2), and rev 3 adds to
variadics_forward the line that catches rev 2's (amended 2026-10-14, review
fold: RR-M1):

| Program | Concept | EXPECT |
| --- | --- | --- |
| generics/variadics_each.carbon (un-SKIP) | statement expansion over a parameter pack, arity 3 and 0 | 6, 0 |
| generics/variadics_fixed_params.carbon (new) | a pack between fixed parameters (DR-29), iteration order | 12, 123, 4321 |
| generics/variadics_forward.carbon (new) | forwarding `... each d`, an expression expansion argument and one whose elements the call converts, to another variadic function (amended 2026-10-14, review fold: RR-M1) | 123, 246, 0, 8, 456 |
| generics/variadics_empty_pack.carbon (new) | a side-effecting statement expansion runs once per element and never for an empty pack, directly and forwarded | 7, 1, 2, 9 |
| generics/variadics_expansion_args.carbon (new) | an expansion argument between fixed arguments (the call's argument list as a tuple literal of segments) | 19, 1239, 15559 |
| generics/variadics_sum_diff.carbon + .diff.cpp (new) | Horner and a forwarded expression expansion against C++17 variadic templates and comma folds | oracle: 123, 11, 0, 30, 0 |
| generics/variadics_arg_order.carbon (new) | an expansion argument is evaluated where it is written, between side-effecting arguments (DR-21) | 1, 2, 3, 9, 1239, 1, 9, 19 |
| generics/variadics_no_copy.carbon (new) | a pack binds values: a class without `Copy`, and one whose `Copy` prints, directly and forwarded (DR-30) | 1, 2, 3, 4, 3, 4 |
| generics/variadics_generic_element.carbon (new) | a deduced element type `T`, generic forwarding, and a class element through `T` without a copy (DR-32) | 3, 2, 2 |

The harness has no compile-failure EXPECT (fork/conformance/README.md:90-98
lists the directives, and :208-212 makes COMPILE-FAIL a failing status), so
every diagnostic is arbitrated by a `fail_` golden instead. The differential
pair is the agreeing direction only:
Carbon's statement expansion and C++'s comma fold both evaluate left to right,
there is no documented divergence, and so R30's both-sides rule does not apply.
variadics_arg_order has no C++ oracle on purpose: C++ leaves the order of a
call's argument evaluation unspecified, so it cannot pin Carbon's.
No program needs the heterogeneous or multi-pack forms (OUT, W-212, W-222).
_Break condition:_ a program passes against a toolchain whose expansion count
or order is wrong (§8.5's mutants), which would make it vacuous.

### §1.9 Docs and records (D-VA-14)

**D-VA-14.** No design doc changes beyond commit 2's upstream text: every rule
the slice implements is the design's, every rule it omits is a filed limit of
the implementation or a `semantics TODO`, not a language rule, and the fork
mints no design decision (F-018 unallocated). The review fold turned rev 1's
one fork-chosen error, `PackNameWithoutEach`, into a TODO for that reason
(D-VA-11; amended 2026-10-14, review fold: A-m2). A "0.1 limits" section in
docs/design/variadics.md was considered and rejected, because the limits are
temporary implementation gaps tracked in the ledger, and an edit to that file
is a conflict at the next advance in a file upstream is actively changing
(a045da8e6). The design overview's "_Planned_ variadics [...] **Note:**
Provisional." (docs/design/README.md:3323 on trunk 3eb7f36f0, :3357 on the dd
branch) and "**TODO: Variadics are still provisional.**" (:3442 on trunk, :3476
on the dd branch) are upstream's statements about the design's status, which
DD-1 (PR 58) keeps as provisional notes in place, by its own convention; slice
1 implements part of the accepted design without changing it, so both stay
true and no dated fork status note is due: the implementation's status lives in
the gap row and W-013 (amended 2026-10-14, review fold: B-m6). Records, written
by commits R and D (§3, §2.8): row 53 moves DESIGN-ONLY to PARTIAL, expected,
not of record, with a new evidence text; the header's counts move PARTIAL +1
and DESIGN-ONLY -1 from whatever they read at the merge commit; gap-analysis.md
§W6 gains the slice's sentence; W-013 stays open, its notes record the slice and
name the next slice (W-212, then W-213 and W-218); W-212..W-230 are filed
(§1.11); fork/decision-log.md gains the entry "VA-1" (D-VA-1..D-VA-16),
immediately above the newest landed workstream entry at the merge commit
(amended 2026-10-14, review fold: B-M4); fork/ORCHESTRATION.md and
fork/conformance/README.md are updated. _Break condition:_ a review shows the
slice deciding a rule the design leaves open (which mints F-018 with a dated
amendment to variadics.md), or DD-1's landed convention requires a dated note
for an implemented provisional feature.

### §1.10 Merge position (D-VA-15)

**D-VA-15.** VA-1 is cut from trunk (f67ab650d), not stacked, and merges after
DD-1 and OX-1, in the order fork/ORCHESTRATION.md on trunk 3eb7f36f0 records
(amended 2026-10-14, review fold: B-M4's records check; rev 1 quoted trunk
44761146d): "PR 53, PR 51, PR 52, SC-1, PR 54, PR 55, PR 56, PR 57, then PR 58
through its state L integration commit; OX-1 and VA-1 after PR 58" (DD-1 is PR
58); its row there says "merges after OX-1 or DD-1, whichever is later". Before
the discharge it merges trunk with a merge commit, never a rebase (AGENTS.md),
and re-verifies on the merge commit (§8.8). _Break condition:_ a branch ahead of
VA-1 in that order gains a conflict with it that §6.2's re-measurement at merge
time shows cannot be resolved by the rules there.

### §1.11 Residues filed (W-212..W-230; W-231 spare)

Each is filed by commit D with bullet "Generics: Definition-checked variadics"
unless another is named, the design text it implements, its blocking evidence
(the TODO label or diagnostic and its golden split), and `blocked_by` either
the residue it needs first or nothing, with "follows VA-1 slice 1" in its notes:
W-013 itself stays open until its residues land, so a residue blocked by it
would be circular (amended 2026-10-14, review fold: B-m5).

1.  W-212: generic and heterogeneous packs. Pack expansion patterns in implicit
    parameter lists (`[... each T: type]`), binding types that use an each-name
    (`... each x: each T`), `each x: auto` (an invented `each __X`), and the
    multi-segment shapes, pack literals and segment-by-segment typechecking
    they need (DR-4, DR-11, DR-17, DR-24, DR-31, DR-32, DR-40), and with them
    the indexing interfaces made variadic, which p002274 :250-257 defers until
    variadics are designed. Evidence: `fail_todo_generic_pack`. The design's
    StrCat (:251-259) is its arbiter (amended 2026-10-14, review fold: B-m4,
    whose rename now happens in C4; B-m6).
2.  W-213: tuples with pack segments. `(... each x)` outside a call's argument
    list, tuple types `(... each T)`, tuple-typed parameters (DR-9, DR-14,
    DR-33). Evidence: `fail_todo_tuple_literal`. Arbiters: Zip's return
    (:70-82), Apply (:274-278), TupleConcat (:288-292).
3.  W-214: pack expansion patterns in tuple patterns that are not a function's
    explicit parameter list: `let`, `var`, `match` and nested tuple patterns
    (DR-10). Evidence: `fail_todo_tuple_pattern`.
4.  W-215: segment merging and splitting. An expansion argument merged with
    other arguments for one pack (arity `N + k`), the `Arity` type's `+`, the
    canonical form of full patterns, and default values before, after or on a
    pack (DR-36, DR-37, DR-39, DR-41). Evidence: `fail_todo_merged_segments`,
    `fail_todo_default_after_pack`, `fail_todo_default_before_pack`,
    `fail_todo_default_on_pack` (the TODO `default value in a parameter list
    with a pack expansion pattern`); M-7 (amended 2026-10-14, review fold:
    A-m1).
5.  W-216: `...and` and `...or` (DR-12, DR-33). Evidence: they fail to parse,
    parse golden toolchain/parse/testdata/variadics/pack_expansion_expr.carbon
    split `fail_todo_and_or` (amended 2026-10-14, review fold: B-m3).
6.  W-217: `...expand` (DR-13, DR-18): check and lowering of upstream's
    `expand` prefix operator or of the design's `...expand` element, whichever
    upstream settles (the design's own TODO, "Discuss typechecking
    `...expand`", :492). Evidence: upstream's `fail_todo_expand` split,
    `HandlePrefixOperatorExpand`.
7.  W-218: statement expansions of declarations and compound statements:
    `... var each iter: auto = ...;`, `... if`, `... while`, `... return`,
    blocks (DR-8). Evidence: `fail_todo_statement_kind`. Arbiters: Zip
    (:70-82), Min (:263-270).
8.  W-219: control flow inside an expansion body: `and`, `or`, `if`
    expressions, and the "Type versus execution semantics" example (DR-34).
    Evidence: `fail_todo_control_flow`.
9.  W-220: per-element cleanups: an expansion body, or a call's element
    conversion of a forwarded pack, that creates a temporary needing
    destruction (D-VA-6). Evidence: the TODO labels "pack expansion element
    that needs a cleanup" (handle_pack_expansion.cpp,
    `FinishPackExpansionBody`; golden fail_todo_cleanup.carbon, splits
    `fail_todo_cleanup_statement` and `fail_todo_cleanup_argument`) and "pack
    element conversion that needs a cleanup" (convert.cpp,
    `ConvertPackToPack`; split `fail_todo_conversion_cleanup`) (amended
    2026-10-14, review fold: B-m3, A-B1).
10. W-221: each-name bindings that are `ref`, `var`, `template` or `generic`,
    and expansion operands that are not one each-name binding, such as
    `... (each c: bool, each x: i32)` (DR-25, DR-34). Evidence:
    `fail_todo_ref_pack`, `fail_todo_two_each_names`,
    `fail_todo_tuple_operand`.
11. W-222: more than one pack: fixed-arity expansions (`class C(... each T:
    type)`), packs in two parameter lists of one function, and the same-arity
    rule across packs (DR-16, DR-35), and the termination rule's keys for
    variadic argument counts (p002687 :186-193, :210-215). Evidence: the TODO
    label "pack expansion over packs of different arities" (amended
    2026-10-14, review fold: B-m6).
12. W-223: variadic members of `overload fn` sets and pack expansion arguments
    to them; OV-1's range-valued `GetExplicitArityRange` (call.cpp:424) is the
    hook. Bullet "Functions: function overloading (Carbon-native)". Evidence:
    `fail_todo_overload_member`, `fail_todo_overload_pack_arg`.
13. W-224: pack expansion arguments in template-dependent calls, and packs in
    templates. Evidence: `fail_todo_template_dependent_call`.
14. W-225: variadic impls: the prelude's tuple `Copy` as one
    `impl forall [... each T: Copy] (... each T) as Copy` replacing
    core/prelude/copy.carbon:49-71, and tuple `Eq` and `Ordered`, whose impl
    selection terminates by p002687's variadic count keys (:210-215). Bullet
    "Stdlib: tuple/array library parts"; blocked by W-212 and W-213 (amended
    2026-10-14, review fold: B-m6).
15. W-226: a variadic `Core.Call` (p002875:227, :531), so that callable types
    take a parameter list rather than a tuple. Blocked by W-212.
16. W-227: C++ interop, importing: calling C++ variadic function templates and
    instantiating C++ class templates with parameter packs on Carbon packs.
    Bullet "Generics: C++ interop — importing C++ templates, instantiating on
    Carbon types".
17. W-228: C++ interop, exporting: a variadic Carbon function exported to C++
    as a function template over a parameter pack. Bullet "Generics: C++
    interop — exporting Carbon templates/checked generics as C++ templates".
    Evidence: the TODO label "exporting a variadic function to C++"
    (toolchain/check/cpp/export.cpp, `ExportFunctionToCpp`; golden
    fail_todo_export.carbon, split `fail_todo_export_variadic`); without it
    the arity binding reaches export.cpp:349's `CARBON_CHECK` (§0.3 item 6;
    amended 2026-10-14, review fold: A-M1).
18. W-229: variadic interface functions: a pack expansion pattern in an
    interface function, the impls that implement it, and the thunks between
    them, which today's thunk.cpp `ClonePattern` (:137-182) cannot build
    because it CHECK-fails on a pattern kind it does not know (:166-170).
    Evidence: the TODO label "pack expansion pattern in an interface
    function", split `fail_todo_interface_function` (amended 2026-10-14,
    review fold: A-m3, found by the walker audit of §2.4).
19. W-230 (design-needed): a pack's name without `each`. The design gives it
    no meaning, and p002240 "Omit each-names" (:637-645) keeps it open for
    operations on the whole sequence; when the design or upstream decides,
    the TODO becomes that rule. Evidence: the TODO label "use of a pack's name
    without `each`", split `fail_todo_pack_name_without_each` (amended
    2026-10-14, review fold: A-m2).

### §1.12 Decision index

| Decision | Summary | Break condition (one sentence) |
| --- | --- | --- |
| D-VA-1 | cherry-pick 2ec4bab59 and a045da8e6 as commits 1 and 2, upstream authorship, no fork trailers, comment-only resolutions | the next advance conflicts in a cherry-picked file in a way taking the fork's side does not resolve, or upstream reshapes 2ec4bab59's nodes first |
| D-VA-2 | the slice: one homogeneous value pack per function (not in an interface), bound without copying, expression-statement and call-argument expansions evaluated where written, arity deduced, body checked once, lowered per specific | a form inside the boundary is mis-checked or lowered to the wrong count or order |
| D-VA-3 | arity = deduced `Core.IntLiteral` binding `<pack arity>`; each-binding of type `«E; N»`, whose value holds the elements' values (no copy); rev 1's `array(E, N)` storage dropped | a pack needs a representation an elementwise value representation cannot give, or value aggregates start copying their elements |
| D-VA-4 | calls group the pack's arguments into a `PackLiteral` or one forwarded pack value; an expansion argument is evaluated where it is written; merging, tuple-literal expansions and overload sets are TODOs | a grouped scrutinee deduces a different arity or converts in a different order than DR-30 |
| D-VA-5 | check's slice TODOs (implicit lists, tuple patterns, non-binding operands, `ref`/`var`/phase each-bindings, different arities, template-dependent calls, defaults beside a pack, interface functions, C++ export, a bare pack name) | a refused form is needed for the row to be PARTIAL |
| D-VA-6 | expansion bodies are straight-line expression statements without cleanups | a straight-line body's lowering reuses a stale per-iteration value |
| D-VA-7 | eight new instructions with the fields, constant kinds and lowering of §1.4's table; an expansion's pack type required complete per specific (amended 2026-10-14, review fold: RR-M1) | a golden shows an expansion body evaluated outside its expansion, the verifier rejects an accepted body, or lowering meets an incomplete pack type |
| D-VA-8 | definition checking = the body checked once against the element type, the one-segment case of DR-32 | a body is accepted that the design's typechecking rejects for a one-segment pack, or the reverse |
| D-VA-9 | lowering unrolls the body per specific where the expansion stands, erases per-iteration locals, fingerprints the arity | a specific evaluates a body other than arity times or out of order |
| D-VA-10 | `each` is a keyword | upstream makes `each` contextual |
| D-VA-11 | a pack's bare name is a `semantics TODO` (W-230), not an error | upstream gives the bare name a meaning or makes it an error |
| D-VA-12 | fourteen new goldens; upstream's check golden refilled and its first split renamed | the advance's conflict in that golden does not resolve by taking upstream's file and refilling |
| D-VA-13 | un-SKIP plus eight programs, one differential, three that see rev 1's defects | a program passes against a mutant with the wrong count or order |
| D-VA-14 | no design-doc edit, no F-018; row PARTIAL expected; W-013 open; W-212..W-230 filed | the slice is shown to decide a rule the design leaves open, or DD-1's convention requires a dated note |
| D-VA-15 | cut from trunk, merges after DD-1 and OX-1, merge commit, re-verify | a branch ahead gains an unresolvable conflict with VA-1 |
| D-VA-16 | five implementation commits, each with its own fill, then row and discharge (§3); three or four fix commits budgeted; a named shrink line | an implementation commit cannot compile without a later one's files |

## §2 Spec, file by file

### §2.0 Conventions

Every code block below was generated from the fixer's scratch clone `$F/cp` by
`$F/bin/gen_blocks.py` (`git diff -U3` between the per-commit branches, or `git
show` of a whole file), never retyped: C1 is 3b4a431f0, C2 is 2f0d4c4c4, and C3,
C4 and C5 are the branches `fx-c3` (6d15888c1), `rr-c4` (ee713955b) and `rr-c5`
(5969337e8); §8.5's mutants are the branches `rr-mu-1` to `rr-mu-8`, each one
commit on `rr-c5`, the first seven being rev 2's `mu-1` to `mu-7` (on `fx-c5`)
replayed (amended 2026-10-14, review fold: RR-M1, RR-m2). Rev 1's blocks came
from `$V/cp`'s `va1-c3f`, `va1-c4f` and `va1-c5f` by `$V/bin/gen_s2.py`; the
blocks of files the fold left alone regenerate byte for byte (fourteen compared,
with the trailing whitespace the hook strips ignored), and every other block
below is rev 2's (amended 2026-10-14, review fold: all code findings). Rev 3's
blocks come from `$R/bin/gen_blocks_rr.py`, the same script pointed at the `rr-`
branches: of its 80 blocks, 74 equal rev 2's byte for byte, and the other six
are the four files rev 3 changes, MU-7 (whose line numbers move) and MU-8 (new)
(amended 2026-10-14, review fold: RR-M1, RR-m2). Each diff is against the
previous commit's state, so applying §2.3, §2.4 and §2.5 in order to C2
reproduces C5. A diff's blank context lines have lost their leading space to the
trailing-whitespace hook; `git apply` reads a line with nothing on it as a blank
context line, so the diffs still apply. The blocks sit between
`google-doc-style-ignore` and `google-doc-style-resume` comment lines because
the doc-style hook rewrites words inside code (R31(d)), and two context lines
quote code that uses one of them. Every C++ file is clang-format 21.1.8 clean
(M-12). The comments the fork adds carry "Fork (VA-1, D-VA-n)" where a decision
of this plan shapes the code and cite the design's section by name; none names a
W-id (the head's id rule).

### §2.1 Commit C1: cherry-pick of 2ec4bab59

`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com git
cherry-pick -x 2ec4bab59`, which auto-merges ten files and stops on two (M-4).
The resolution:

**toolchain/check/node_stack.h**: keep both sides' case labels, alphabetical,
so that the block reads (3b4a431f0, :488-491):

<!-- google-doc-style-ignore -->

```cpp
      case Parse::NodeKind::NamedConstraintIntroducer:
      case Parse::NodeKind::PackExpansionStart:
      case Parse::NodeKind::PatternConditionInitializer:
      case Parse::NodeKind::PatternConditionIntroducer:
```

<!-- google-doc-style-resume -->

**toolchain/parse/state.def**: in each of the seven hunks, take the fork's
side and apply upstream's renotation to it: a placeholder `...` in a comment
becomes `<...>` and `???` becomes `<???>`, except where the text already reads
`<...>`; a caret line under the comment keeps its length and moves right by the
characters inserted before its first caret (`$V/bin/renote.py` does exactly
this; the hand-written `var <...>      (variant is Regular)` line keeps
upstream's spacing). The seven resolved hunks, as they read in 3b4a431f0:

<!-- google-doc-style-ignore -->

```cpp
// Hunk 1, resolved at state.def:433-439 of 3b4a431f0:
// union <...>
// ^~~~~
//   1. TypeAfterIntroducerAsUnion
//
// var <...>      (variant is Regular)
// ^~~
//   1. VarAsRegular

// Hunk 2, resolved at state.def:612-618 of 3b4a431f0:
// expr ? <...>
//     ^
//   1. ExprInPostfixLoop
//
//  <...>
// ^
//   (state done)

// Hunk 3, resolved at state.def:1631-1632 of 3b4a431f0:
// class/impl/interface/constraint/union <...> { <...> }
//                                                     ^

// Hunk 4, resolved at state.def:1639-1640 of 3b4a431f0:
// class/interface/constraint/union <...>
//                                 ^

// Hunk 5, resolved at state.def:1648-1656 of 3b4a431f0:
// class/impl/interface/constraint/union name ( <...> ) {
//                                                      ^
//   1. DeclScopeLoopAs(Class|Regular|Union)
//   2. DeclDefinitionFinishAs(Class|Impl|Interface|NamedConstraint|Union)
//
// class/impl/interface/constraint/union name ( <...> ) ;
//                                                      ^
// class/impl/interface/constraint/union name ( <...> ) <???>
//                                                      ^

// Hunk 6, resolved at state.def:1994-1996 of 3b4a431f0:
// match (<...>) { case <...>}
//                 ^~~~
//   1. Pattern (or MatchCaseAlternativePattern for a leading-dot pattern)

// Hunk 7, resolved at state.def:2063-2071 of 3b4a431f0:
// match (<...>) { default if (<...>) => {<...>} }
//                 ^~~~~~~~~~~
//   1. Expr
//   2. MatchCaseGuardFinish
//   3. MatchGuardedDefaultStart
//
// match (<...>) { default <???> }
//                         ^
//   (state done)
```

<!-- google-doc-style-resume -->

Then `git add toolchain/check/node_stack.h toolchain/parse/state.def` and
`git -c core.editor=true cherry-pick --continue` with the same committer
variables (amended 2026-10-14, review fold: B-m9, a line no longer starts with
a dash).
The fork's other `...` comments (match, let-else and pattern-condition states
that did not conflict) keep the old notation in C1 and are renoted by C3, so
C1 differs from upstream's commit only where git required a resolution.

### §2.2 Commit C2: cherry-pick of a045da8e6

`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com git
cherry-pick -x a045da8e6`: applies cleanly (36 lines added to
docs/design/variadics.md: a table-of-contents entry and the section "Type
versus execution semantics" after :492).

### §2.3 Commit C3: lex and parse (`fx-c3`)

The lexer gains the `each` keyword; the parser gains the each-name in binding
patterns and expressions and the `...` element of pattern lists, tuple literals
and call argument lists, beside upstream's statement form. The checker gets one
TODO handler per new parse node kind, because check dispatches on every node
kind and would not link without them; C4 replaces them. Invariant: no existing
token sequence parses differently, since `each` and `...` occur in no existing
Carbon source (M-10), and a list element that does not start with `...` takes
exactly the states it took before (`TupleLiteralElement` and
`HandlePatternListElement` push `Expr` or `Pattern` as before). C3's code is
rev 1's; rev 2 adds one parse golden split, `fail_todo_and_or` (§2.6; amended
2026-10-14, review fold: B-m3).

**toolchain/lex/token_kind.def.** The keyword, alphabetical among the keywords
(D-VA-10).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lex/token_kind.def
+++ b/toolchain/lex/token_kind.def
@@ -194,6 +194,7 @@ CARBON_KEYWORD_TOKEN(Continue,            "continue")
 CARBON_KEYWORD_TOKEN(Core,                "Core")
 CARBON_KEYWORD_TOKEN(Cpp,                 "Cpp")
 CARBON_KEYWORD_TOKEN(Default,             "default")
+CARBON_KEYWORD_TOKEN(Each,                "each")
 // The `else` of a `let`-`else` declaration carries a virtual parse node:
 // the `LetElseDecl` close node rides the introducer token, whose budget
 // the (re-kinded) `LetElseIntroducer` leaf already spends.
```

<!-- google-doc-style-resume -->

**toolchain/parse/node_kind.def.** Two element kinds beside upstream's
`PackExpansionStart` and `PackExpansionStatement`, and the two each-name kinds.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/parse/node_kind.def
+++ b/toolchain/parse/node_kind.def
@@ -295,6 +295,11 @@ CARBON_PARSE_NODE_KIND_STATEMENT(WhileStatement)

 CARBON_PARSE_NODE_KIND_STATEMENT(PackExpansionStart)
 CARBON_PARSE_NODE_KIND_STATEMENT(PackExpansionStatement)
+CARBON_PARSE_NODE_KIND_EXPRESSION(PackExpansionExpr)
+CARBON_PARSE_NODE_KIND_PATTERN(PackExpansionPattern)
+
+CARBON_PARSE_NODE_KIND_EXPRESSION(EachNameExpr)
+CARBON_PARSE_NODE_KIND_PATTERN(EachBindingName)

 CARBON_PARSE_NODE_KIND_EXPRESSION(IndexExprStart)
 CARBON_PARSE_NODE_KIND_EXPRESSION(IndexExpr)
```

<!-- google-doc-style-resume -->

**toolchain/parse/typed_nodes.h.** `EachBindingName` is the name child of a
binding pattern (one child, the identifier), so it joins the three binding
patterns' name alternatives; `PackExpansionExpr` and `PackExpansionPattern` are
bracketed by upstream's `PackExpansionStart` with a virtual `...` token, as
upstream's `PackExpansionStatement` is; `EachNameExpr` is an expression with one
child.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/parse/typed_nodes.h
+++ b/toolchain/parse/typed_nodes.h
@@ -419,6 +419,15 @@ struct RuntimeBindingName {
   AnyRuntimeBindingPatternName name;
 };

+// An each-name declared by a binding pattern: `each name`.
+struct EachBindingName {
+  static constexpr auto Kind =
+      NodeKind::EachBindingName.Define({.child_count = 1});
+
+  Lex::EachTokenIndex token;
+  IdentifierNameNotBeforeSignatureId name;
+};
+
 struct BindingPatternTypeStart {
   static constexpr auto Kind =
       NodeKind::BindingPatternTypeStart.Define({.child_count = 0});
@@ -434,7 +443,7 @@ struct LetBindingPattern {

   // TODO: is there some way to reuse AnyRuntimeBindingPatternName here?
   NodeIdOneOf<IdentifierNameNotBeforeSignature, SelfValueName, UnderscoreName,
-              RefBindingName, RuntimeBindingName>
+              EachBindingName, RefBindingName, RuntimeBindingName>
       name;
   BindingPatternTypeStartId introducer;
   Lex::ColonTokenIndex token;
@@ -460,7 +469,7 @@ struct VarBindingPattern {

   // TODO: is there some way to reuse AnyRuntimeBindingPatternName here?
   NodeIdOneOf<IdentifierNameNotBeforeSignature, SelfValueName, UnderscoreName,
-              RuntimeBindingName>
+              EachBindingName, RuntimeBindingName>
       name;
   BindingPatternTypeStartId introducer;
   Lex::ColonTokenIndex token;
@@ -504,7 +513,7 @@ struct CompileTimeBindingPattern {

   // TODO: is there some way to reuse AnyRuntimeBindingPatternName here?
   NodeIdOneOf<IdentifierNameNotBeforeSignature, SelfValueName, UnderscoreName,
-              TemplateBindingName>
+              EachBindingName, TemplateBindingName>
       name;
   CompileTimeBindingPatternTypeStartId introducer;
   Lex::ColonTokenIndex token;
@@ -1034,6 +1043,45 @@ struct PackExpansionStatement {
   Lex::PeriodPeriodPeriodTokenIndex token;
 };

+// A pack expansion element of a tuple literal or call argument list:
+// `... expression`.
+struct PackExpansionExpr {
+  static constexpr auto Kind = NodeKind::PackExpansionExpr.Define(
+      {.category = NodeCategory::Expr,
+       .bracketed_by = PackExpansionStart::Kind,
+       .child_count = 2});
+
+  PackExpansionStartId start;
+  AnyExprId body;
+  // This is a virtual token. The `...` token is owned by the
+  // PackExpansionStart node.
+  Lex::PeriodPeriodPeriodTokenIndex token;
+};
+
+// A pack expansion element of a tuple pattern or parameter list:
+// `... pattern`.
+struct PackExpansionPattern {
+  static constexpr auto Kind = NodeKind::PackExpansionPattern.Define(
+      {.category = NodeCategory::Pattern,
+       .bracketed_by = PackExpansionStart::Kind,
+       .child_count = 2});
+
+  PackExpansionStartId start;
+  AnyPatternId body;
+  // This is a virtual token. The `...` token is owned by the
+  // PackExpansionStart node.
+  Lex::PeriodPeriodPeriodTokenIndex token;
+};
+
+// An each-name used in an expression: `each name`.
+struct EachNameExpr {
+  static constexpr auto Kind = NodeKind::EachNameExpr.Define(
+      {.category = NodeCategory::Expr, .child_count = 1});
+
+  Lex::EachTokenIndex token;
+  IdentifierNameNotBeforeSignatureId name;
+};
+
 using MatchConditionStart =
     LeafNode<NodeKind::MatchConditionStart, Lex::OpenParenTokenIndex>;

```

<!-- google-doc-style-resume -->

**toolchain/parse/node_ids.h.** A runtime binding's name may be an each-name.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/parse/node_ids.h
+++ b/toolchain/parse/node_ids.h
@@ -197,7 +197,7 @@ using AnyPointerDeferenceExprId =
     NodeIdOneOf<PrefixOperatorStarId, PointerMemberAccessExprId>;
 using AnyRuntimeBindingPatternName =
     NodeIdOneOf<IdentifierNameNotBeforeSignatureId, SelfValueNameId,
-                UnderscoreNameId>;
+                UnderscoreNameId, EachBindingNameId>;
 using AnyPrimitiveFormIdId =
     NodeIdOneOf<RefPrimitiveFormId, VarPrimitiveFormId, ValPrimitiveFormId>;

```

<!-- google-doc-style-resume -->

**toolchain/parse/state.def.** Three states (`TupleLiteralElement`,
`PackExpansionExprFinish`, `PackExpansionPatternFinish`), the call and tuple
states' first step renamed from `Expr` to `TupleLiteralElement`, the
pattern-list comment's `...` variant, and the renotation of the fork's remaining
`...` comments in upstream's notation (§2.1).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/parse/state.def
+++ b/toolchain/parse/state.def
@@ -238,7 +238,7 @@ CARBON_PARSE_STATE_VARIANTS3(BraceExprFinish, Type, Value, Unknown)
 //
 // F( <...>
 //  ^
-//   1. Expr
+//   1. TupleLiteralElement
 //   2. TupleLiteralElementFinish
 //   3. CallExprFinish
 CARBON_PARSE_STATE(CallExpr)
@@ -769,7 +769,7 @@ CARBON_PARSE_STATE(ExprStatementFinish)
 //
 // friend <identifier> ;
 //        ^~~~~~~~~~~~~~
-// friend ??? ;
+// friend <???> ;
 //        ^~~~~
 //   (state done)
 CARBON_PARSE_STATE(FriendDecl)
@@ -1042,6 +1042,13 @@ CARBON_PARSE_STATE(AliasFinish)
 //   2. PatternListElementCheckForDefaultValue
 //   2. PatternListElementFinishAs(Tuple|Struct|Explicit|Implicit)
 //
+//  ... <...> (variant is Tuple, Explicit or Implicit)
+// ^~~
+//   1. Pattern
+//   2. PackExpansionPatternFinish
+//   3. PatternListElementCheckForDefaultValue
+//   4. PatternListElementFinishAs(Tuple|Explicit|Implicit)
+//
 //  .foo = <...> (variant is Struct)
 // ^
 //   1. PeriodAsStruct
@@ -1056,6 +1063,13 @@ CARBON_PARSE_STATE(AliasFinish)
 CARBON_PARSE_STATE_VARIANTS4(PatternListElement, Tuple, Struct, Explicit,
                              Implicit)

+// Handles a pack expansion pattern list element after its body.
+//
+// ... <...>
+//          ^
+//   (state done)
+CARBON_PARSE_STATE(PackExpansionPatternFinish)
+
 // Some pattern list elements support optional default value expressions,
 // this state checks for the `=` and if present parses it before moving on
 // to finish the list element.
@@ -1219,13 +1233,13 @@ CARBON_PARSE_STATE_VARIANTS3(ParenConditionFinish, If, While, Match)
 // Handles a pattern condition after its pattern: adds the VariablePattern
 // wrapper for the `var` spelling, then the `=` and the initializer.
 //
-// if/while ( let ... = ...
-//                   ^
+// if/while ( let <...> = <...>
+//                    ^
 //   1. Expr
 //   2. ParenConditionFinishAs(If|While)
 //
-// if/while ( let ... ???
-//                   ^
+// if/while ( let <...> <???>
+//                    ^
 //   2. ParenConditionFinishAs(If|While)   (state done, error)
 CARBON_PARSE_STATE(PatternConditionAfterPattern)

@@ -1255,6 +1269,12 @@ CARBON_PARSE_STATE(OnlyParenExprFinish)
 //   1. Expr
 //   2. ExprAfterOpenParenFinish
 //   3. ParenExprFinish             (SPECIAL: may be replaced)
+//
+// ( ... <...> )
+// ^
+//   1. TupleLiteralElement
+//   2. TupleLiteralElementFinish
+//   3. TupleLiteralFinish
 CARBON_PARSE_STATE(ParenExpr)

 // Handles the `)` of a tuple literal.
@@ -1273,7 +1293,7 @@ CARBON_PARSE_STATE(TupleLiteralFinish)
 //
 // ( <...> , <...> )
 //         ^
-//   1. Expr
+//   1. TupleLiteralElement
 //   2. TupleLiteralElementFinish
 //   SPECIAL: parent becomes TupleLiteralFinish
 //
@@ -1291,7 +1311,7 @@ CARBON_PARSE_STATE(ExprAfterOpenParenFinish)
 //
 // ( <...> , <...> )
 //         ^
-//   1. Expr
+//   1. TupleLiteralElement
 //   2. TupleLiteralElementFinish
 //
 // ( <...> )
@@ -1299,6 +1319,26 @@ CARBON_PARSE_STATE(ExprAfterOpenParenFinish)
 //   (state done)
 CARBON_PARSE_STATE(TupleLiteralElementFinish)

+// Handles an element of a tuple literal or call argument list, which may be
+// a pack expansion.
+//
+// ... <...>
+// ^~~
+//   1. Expr
+//   2. PackExpansionExprFinish
+//
+// <...>
+// ^
+//   1. Expr
+CARBON_PARSE_STATE(TupleLiteralElement)
+
+// Handles a pack expansion tuple literal element after its body.
+//
+// ... <...>
+//          ^
+//   (state done)
+CARBON_PARSE_STATE(PackExpansionExprFinish)
+
 // Handles the `)` of a parenthesized single expression.
 //
 // ( <...> )
@@ -1877,8 +1917,8 @@ CARBON_PARSE_STATE_VARIANTS2(LetFinish, Regular, AssociatedConstant)

 // Handles the end of a `let`-`else` declaration after its else block.
 //
-// let ... = ... else { ... }
-//                           ^
+// let <...> = <...> else { <...> }
+//                                 ^
 //   (state done)
 CARBON_PARSE_STATE(LetElseFinish)

@@ -1983,8 +2023,8 @@ CARBON_PARSE_STATE(MatchConditionFinish)
 //                ^
 //   1. MatchDefaultIntroducer
 //   2. MatchCaseLoopAfterDefault
-// match (...) { default if ...}
-//              ^
+// match (<...>) { default if <...>}
+//                ^
 //   1. MatchDefaultIntroducer
 //   2. MatchCaseLoop
 CARBON_PARSE_STATE(MatchCaseLoop)
@@ -2000,20 +2040,20 @@ CARBON_PARSE_STATE(MatchCaseIntroducer)
 // Handles a choice alternative pattern in a `match` `case`: the designator
 // name, then an optional parenthesized payload pattern list.
 //
-// match (...) { case .Name(...) ... }
-//                    ^~~~~
+// match (<...>) { case .Name(<...>) <...> }
+//                      ^~~~~
 //   1. PatternListAsTuple
 //   2. MatchCaseAlternativePatternFinish
 //
-// match (...) { case .Name ... }
-//                    ^~~~~
+// match (<...>) { case .Name <...> }
+//                      ^~~~~
 //   (state done)
 CARBON_PARSE_STATE(MatchCaseAlternativePattern)

 // Finishes a choice alternative pattern after its payload pattern list.
 //
-// match (...) { case .Name(...) ... }
-//                             ^
+// match (<...>) { case .Name(<...>) <...> }
+//                                ^
 //   (state done)
 CARBON_PARSE_STATE(MatchCaseAlternativePatternFinish)

@@ -2078,17 +2118,17 @@ CARBON_PARSE_STATE(MatchDefaultIntroducer)
 // Handles a guarded `match` default's `=>` and `{` opening statements block,
 // after the guard's closing `)`.
 //
-// match (...) { default if (...) => {...} }
-//                                ^~~~
+// match (<...>) { default if (<...>) => {<...>} }
+//                                    ^~~~
 //   1. StatementScopeLoop
 //   2. MatchHandlerFinish
 //
-// match (...) { default if (...) ??? }
-//                                ^
+// match (<...>) { default if (<...>) <???> }
+//                                    ^
 //   (state done)
 //
-// match (...) { default if (...) => ??? }
-//                                   ^
+// match (<...>) { default if (<...>) => <???> }
+//                                       ^
 //   (state done)
 CARBON_PARSE_STATE(MatchGuardedDefaultStart)

```

<!-- google-doc-style-resume -->

**toolchain/parse/handle_binding_pattern.cpp.** `each` is consumed last before
the name (DR-25) and, after the name, wraps it in `EachBindingName`; only an
identifier can follow (`ExpectedIdentifierAfterEachInBinding`).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/parse/handle_binding_pattern.cpp
+++ b/toolchain/parse/handle_binding_pattern.cpp
@@ -113,11 +113,18 @@ auto HandleBindingPattern(Context& context) -> void {
     misordered_unused_token = context.ConsumeChecked(Lex::TokenKind::Unused);
   }

+  // `each` declares the elements of a pack. It is written last, directly
+  // before the name: the order is `...` phase modifier `each` name
+  // (docs/design/variadics.md, "Pack expansion patterns").
+  auto each_token = context.ConsumeIf(Lex::TokenKind::Each);
+
   // The first item should be an identifier, the placeholder `_`, or `self`.
   std::optional<Lex::TokenIndex> self_token;
+  bool has_identifier_name = false;
   if (auto identifier = context.ConsumeIf(Lex::TokenKind::Identifier)) {
     context.AddLeafNode(NodeKind::IdentifierNameNotBeforeSignature,
                         *identifier);
+    has_identifier_name = true;
   } else if (auto self =
                  context.ConsumeIf(Lex::TokenKind::SelfValueIdentifier)) {
     // Checking will validate where `self` may be declared. Its type may be
@@ -155,6 +162,18 @@ auto HandleBindingPattern(Context& context) -> void {
     on_error(/*expected_name=*/true);
   }

+  // An each-name wraps the name it declares; only an identifier can name a
+  // pack.
+  if (each_token) {
+    if (!has_identifier_name && !state.has_error) {
+      CARBON_DIAGNOSTIC(ExpectedIdentifierAfterEachInBinding, Error,
+                        "expected identifier after `each`");
+      context.emitter().Emit(*each_token, ExpectedIdentifierAfterEachInBinding);
+      state.has_error = true;
+    }
+    context.AddNode(NodeKind::EachBindingName, *each_token, state.has_error);
+  }
+
   auto token_kind = context.PositionKind();
   if (!token_kind.is_binding_pattern_operator()) {
     if (self_token && !template_token && !generic_token && !runtime_token) {
```

<!-- google-doc-style-resume -->

**toolchain/parse/handle_pattern.cpp.** A pattern that starts with `each` is a
binding.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/parse/handle_pattern.cpp
+++ b/toolchain/parse/handle_pattern.cpp
@@ -38,6 +38,7 @@ auto HandlePattern(Context& context) -> void {
     case Lex::TokenKind::Generic:
     case Lex::TokenKind::Runtime:
     case Lex::TokenKind::Ref:
+    case Lex::TokenKind::Each:
     // `self` is always a binding, even when its type is omitted (and so is not
     // followed by a `:`).
     case Lex::TokenKind::SelfValueIdentifier:
```

<!-- google-doc-style-resume -->

**toolchain/parse/handle_expr.cpp.** `each` and an identifier form a primary
expression, so every postfix and binary operator applies to the each-name as a
whole (DR-3).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/parse/handle_expr.cpp
+++ b/toolchain/parse/handle_expr.cpp
@@ -79,6 +79,25 @@ auto HandleExprInPostfix(Context& context) -> void {
       context.PushState(state);
       break;
     }
+    case Lex::TokenKind::Each: {
+      // `each` is part of the name syntax, so it binds more tightly than any
+      // expression syntax (docs/design/variadics.md, "Packs and each-names").
+      auto each_token = context.Consume();
+      if (!context.ConsumeAndAddLeafNodeIf(
+              Lex::TokenKind::Identifier,
+              NodeKind::IdentifierNameNotBeforeSignature)) {
+        CARBON_DIAGNOSTIC(ExpectedIdentifierAfterEach, Error,
+                          "expected identifier after `each`");
+        context.emitter().Emit(*context.position(),
+                               ExpectedIdentifierAfterEach);
+        context.AddInvalidParse(*context.position());
+        context.ReturnErrorOnState();
+        state.has_error = true;
+      }
+      context.AddNode(NodeKind::EachNameExpr, each_token, state.has_error);
+      context.PushState(state);
+      break;
+    }
     case Lex::TokenKind::Fn: {
       context.PushState(state);
       context.PushState(StateKind::LambdaIntroducer);
```

<!-- google-doc-style-resume -->

**toolchain/parse/handle_paren_expr.cpp.** Every element of a tuple literal or
call argument list goes through `TupleLiteralElement`, which starts a
`PackExpansionExpr` when the element begins with `...`; a parenthesized `...`
element makes a tuple literal without a comma (DR-14).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/parse/handle_paren_expr.cpp
+++ b/toolchain/parse/handle_paren_expr.cpp
@@ -53,6 +53,14 @@ auto HandleParenExpr(Context& context) -> void {

   if (context.PositionIs(Lex::TokenKind::CloseParen)) {
     context.PushState(state, StateKind::TupleLiteralFinish);
+  } else if (context.PositionIs(Lex::TokenKind::PeriodPeriodPeriod)) {
+    // A `...` element makes the parentheses a tuple literal even without a
+    // comma: "if the nearest enclosing delimiters around a `...` are
+    // parentheses, they will be interpreted as forming a tuple rather than as
+    // grouping" (docs/design/variadics.md, "Pack expansions").
+    context.PushState(state, StateKind::TupleLiteralFinish);
+    context.PushState(StateKind::TupleLiteralElementFinish);
+    context.PushState(StateKind::TupleLiteralElement);
   } else {
     context.PushState(state, StateKind::ParenExprFinish);
     context.PushState(StateKind::ExprAfterOpenParenFinish);
@@ -79,7 +87,7 @@ auto HandleExprAfterOpenParenFinish(Context& context) -> void {
   // for the next tuple element.
   if (list_token_kind != Context::ListTokenKind::CommaClose) {
     context.PushState(StateKind::TupleLiteralElementFinish);
-    context.PushState(StateKind::Expr);
+    context.PushState(StateKind::TupleLiteralElement);
   }
 }

@@ -94,7 +102,29 @@ auto HandleTupleLiteralElementFinish(Context& context) -> void {
                                Lex::TokenKind::CloseParen, state.has_error) ==
       Context::ListTokenKind::Comma) {
     context.PushState(StateKind::TupleLiteralElementFinish);
-    context.PushState(StateKind::Expr);
+    context.PushState(StateKind::TupleLiteralElement);
+  }
+}
+
+auto HandleTupleLiteralElement(Context& context) -> void {
+  context.PopState();
+
+  // A tuple literal or call argument list element may be a pack expansion,
+  // `... expression`, with the same precedence as `,`
+  // (docs/design/variadics.md, "Pack expansions").
+  if (context.PositionIs(Lex::TokenKind::PeriodPeriodPeriod)) {
+    context.PushState(StateKind::PackExpansionExprFinish);
+    context.AddLeafNode(NodeKind::PackExpansionStart, context.Consume());
+  }
+  context.PushState(StateKind::Expr);
+}
+
+auto HandlePackExpansionExprFinish(Context& context) -> void {
+  auto state = context.PopState();
+
+  context.AddNode(NodeKind::PackExpansionExpr, state.token, state.has_error);
+  if (state.has_error) {
+    context.ReturnErrorOnState();
   }
 }

@@ -120,7 +150,7 @@ auto HandleCallExpr(Context& context) -> void {
   context.AddNode(NodeKind::CallExprStart, context.Consume(), state.has_error);
   if (!context.PositionIs(Lex::TokenKind::CloseParen)) {
     context.PushState(StateKind::TupleLiteralElementFinish);
-    context.PushState(StateKind::Expr);
+    context.PushState(StateKind::TupleLiteralElement);
   }
 }

```

<!-- google-doc-style-resume -->

**toolchain/parse/handle_pattern_list.cpp.** Tuple, explicit and implicit
pattern-list elements, not struct ones, may start with `...` (DR-10, DR-11).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/parse/handle_pattern_list.cpp
+++ b/toolchain/parse/handle_pattern_list.cpp
@@ -7,9 +7,14 @@

 namespace Carbon::Parse {

-// Handles PatternListElementAs(Tuple|Explicit|Implicit).
+// Handles PatternListElementAs(Tuple|Explicit|Implicit). A tuple pattern or
+// parameter list element may be a pack expansion, `... pattern`
+// (docs/design/variadics.md, "Pack expansions"); a struct pattern element may
+// not, so only those variants pass `allow_pack_expansion`.
 static auto HandlePatternListElement(Context& context, StateKind pattern_state,
-                                     StateKind finish_state_kind) -> void {
+                                     StateKind finish_state_kind,
+                                     bool allow_pack_expansion = false)
+    -> void {
   auto state = context.PopState();

   context.PushStateForPattern(finish_state_kind, state.in_var_pattern,
@@ -28,6 +33,12 @@ static auto HandlePatternListElement(Context& context, StateKind pattern_state,
         state.binding_context, state.ambient_precedence);
   }

+  if (allow_pack_expansion &&
+      context.PositionIs(Lex::TokenKind::PeriodPeriodPeriod)) {
+    context.PushState(StateKind::PackExpansionPatternFinish);
+    context.AddLeafNode(NodeKind::PackExpansionStart, context.Consume());
+  }
+
   context.PushStateForPattern(pattern_state, state.in_var_pattern,
                               state.in_unused_pattern,
                               state.in_field_shorthand_pattern,
@@ -36,7 +47,8 @@ static auto HandlePatternListElement(Context& context, StateKind pattern_state,

 auto HandlePatternListElementAsTuple(Context& context) -> void {
   HandlePatternListElement(context, StateKind::Pattern,
-                           StateKind::PatternListElementFinishAsTuple);
+                           StateKind::PatternListElementFinishAsTuple,
+                           /*allow_pack_expansion=*/true);
 }

 auto HandlePatternListElementAsStruct(Context& context) -> void {
@@ -66,12 +78,23 @@ auto HandlePatternListElementAsStruct(Context& context) -> void {

 auto HandlePatternListElementAsExplicit(Context& context) -> void {
   HandlePatternListElement(context, StateKind::Pattern,
-                           StateKind::PatternListElementFinishAsExplicit);
+                           StateKind::PatternListElementFinishAsExplicit,
+                           /*allow_pack_expansion=*/true);
 }

 auto HandlePatternListElementAsImplicit(Context& context) -> void {
   HandlePatternListElement(context, StateKind::Pattern,
-                           StateKind::PatternListElementFinishAsImplicit);
+                           StateKind::PatternListElementFinishAsImplicit,
+                           /*allow_pack_expansion=*/true);
+}
+
+auto HandlePackExpansionPatternFinish(Context& context) -> void {
+  auto state = context.PopState();
+
+  context.AddNode(NodeKind::PackExpansionPattern, state.token, state.has_error);
+  if (state.has_error) {
+    context.ReturnErrorOnState();
+  }
 }

 auto HandleStructPatternDesignatedFieldFinish(Context& context) -> void {
```

<!-- google-doc-style-resume -->

**toolchain/diagnostics/kind.def.** The two parse diagnostics.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/diagnostics/kind.def
+++ b/toolchain/diagnostics/kind.def
@@ -117,6 +117,8 @@ CARBON_DIAGNOSTIC_KIND(ExpectedExpr)
 CARBON_DIAGNOSTIC_KIND(ExpectedPattern)
 CARBON_DIAGNOSTIC_KIND(ExpectedIdentifierAfterPeriodOrArrow)
 CARBON_DIAGNOSTIC_KIND(ExpectedIdentifierOrSelfAfterPeriod)
+CARBON_DIAGNOSTIC_KIND(ExpectedIdentifierAfterEach)
+CARBON_DIAGNOSTIC_KIND(ExpectedIdentifierAfterEachInBinding)
 CARBON_DIAGNOSTIC_KIND(ExpectedBindingName)
 CARBON_DIAGNOSTIC_KIND(ExpectedBindingPattern)
 CARBON_DIAGNOSTIC_KIND(ExpectedCurlyBraceAfter)
```

<!-- google-doc-style-resume -->

**toolchain/check/node_stack.h.** `EachBindingName` is a solo node with no id,
popped by the binding pattern that owns it. It belongs to C3, not C4: the node
stack's compile-time table must classify every parse node kind, and the C3 sweep
failed on toolchain/check/node_stack.cpp without it (§8.0).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/node_stack.h
+++ b/toolchain/check/node_stack.h
@@ -467,6 +467,7 @@ class NodeStack {
       case Parse::NodeKind::ClassIntroducer:
       case Parse::NodeKind::UnionIntroducer:
       case Parse::NodeKind::CodeBlockStart:
+      case Parse::NodeKind::EachBindingName:
       case Parse::NodeKind::ExplicitParamListStart:
       case Parse::NodeKind::ForHeaderStart:
       case Parse::NodeKind::FunctionIntroducer:
```

<!-- google-doc-style-resume -->

**toolchain/check/handle_pack_expansion.cpp.** TODO stubs for the four new parse
node kinds, replaced in C4.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_pack_expansion.cpp
+++ b/toolchain/check/handle_pack_expansion.cpp
@@ -17,6 +17,25 @@ auto HandleParseNode(Context& context, Parse::PackExpansionStatementId node_id)
   return context.TODO(node_id, "HandlePackExpansionStatement");
 }

+auto HandleParseNode(Context& context, Parse::PackExpansionExprId node_id)
+    -> bool {
+  return context.TODO(node_id, "HandlePackExpansionExpr");
+}
+
+auto HandleParseNode(Context& context, Parse::PackExpansionPatternId node_id)
+    -> bool {
+  return context.TODO(node_id, "HandlePackExpansionPattern");
+}
+
+auto HandleParseNode(Context& context, Parse::EachBindingNameId node_id)
+    -> bool {
+  return context.TODO(node_id, "HandleEachBindingName");
+}
+
+auto HandleParseNode(Context& context, Parse::EachNameExprId node_id) -> bool {
+  return context.TODO(node_id, "HandleEachNameExpr");
+}
+
 auto HandleParseNode(Context& context, Parse::PrefixOperatorExpandId node_id)
     -> bool {
   return context.TODO(node_id, "HandlePrefixOperatorExpand");
```

<!-- google-doc-style-resume -->

### §2.4 Commit C4: check and SemIR (`rr-c4`)

The SemIR instructions of D-VA-7, the checking of D-VA-3 to D-VA-8 and D-VA-11,
the diagnostics, import and redeclaration support, the TODOs of D-VA-5, and
the lowering stubs that the per-kind lowering dispatch requires. Invariant:
code without packs takes exactly the paths it took before: `GroupPackArguments`
returns the arguments unchanged for a callee without a pack expansion pattern
after one scan for an expansion argument, the identifier lookup builds the same
reference as `HandleNameAsExpr`, the default-value and export TODOs fire only
beside a `PackExpansionPattern`, and every other change is a new `case` or a
new function. Rev 1's change to toolchain/sem_ir/expr_info.cpp is gone with
`PackExpansionInit` (amended 2026-10-14, review fold: A-B1, A-B2, A-M1, A-m1,
A-m3, B-M1, B-M2).

The code blocks below are C4's; where later commits change the same code, the
tree is the record (amended 2026-10-14, implementation-review fold: MAJOR-1,
MAJOR-2, MINOR-1, MINOR-2, MINOR-3, VA1-IR2-m1). Fix 1 (32ce7d58b) adds the
statement form of D-VA-6's cleanup TODO to `HandleParseNode(ExprStatementId)` in
toolchain/check/handle_expr_statement.cpp. Fix 3 (0ee9f2d1b) makes the
completeness requirement of `HandleParseNode(PackExpansionExprId)`
(handle_pack_expansion.cpp) diagnose instead of check; makes
`FindPackExpansionParam` (call.cpp) find a local pack pattern whose operand was
diagnosed, and `GroupPackArguments` leave a call to it, or a call whose bound
`self` is not the first explicit parameter, to the declaration's diagnostic;
gives a binding named `_` or `self` in a pack expansion pattern
`PackExpansionBindingNotIdentifier` without a suggestion
(handle_binding_pattern.cpp); and raises the slice's TODO for a variadic
`overload fn` member in gate (iii) of `DiagnoseOverloadGates`
(handle_function.cpp). The implementation review fold record at the end gives
the reasons.

**Pattern walkers audited** (amended 2026-10-14, review fold: A-m3). Every
switch or `TryAs` chain over parameter patterns that M-24's grep finds, with
its line at f67ab650d and what C4 does for a `PackExpansionPattern` there:

-   `MatchContext::Dispatch` (pattern_match.cpp:2304), `CheckRedeclParam`
    (merge.cpp:210) and the import resolver (import_ref.cpp): a case each, as
    in rev 1.
-   `CheckDefaults` (handle_function.cpp:913) and
    `CheckUnusedBindingsInPattern` (:1240): a case each, which recurses into
    the operand (new).
-   `PushCallArgs` (sem_ir/stringify.cpp:413): a case, the pack's one argument
    (new).
-   `GetLeafParamPattern` (call.cpp:438): none; it returns `None` for a pack
    expansion pattern, and only the overload probe calls it, after the TODO
    for a variadic member.
-   `MarkPatternUnused` (handle_binding_pattern.cpp:749): none; `unused`
    cannot wrap a pack expansion pattern, because `...` starts its list
    element, and `... unused each n` marks the binding itself.
-   `ClonePattern` (thunk.cpp:137): none; it CHECK-fails on a pattern kind it
    does not know (:166-170) and runs for two kinds of thunk. One is between an
    interface function and its impl, and C4 refuses a pack expansion pattern in
    an interface function with a TODO (W-229). The other is every virtual
    override: class.cpp:385-387 calls `BuildThunk` with the class's
    `self_type_id`, so thunk.cpp:462-467's no-thunk shortcut never applies and
    the base function's parameter patterns are cloned. A variadic virtual
    function cannot reach it, because its arity binding makes it generic, and
    handle_function.cpp:798-802 diagnoses `GenericVirtual` and drops its
    `virtual`; the split `fail_variadic_virtual` pins that guard, so that a
    relaxed generic-virtual rule shows up as a changed golden, not a crash
    (amended 2026-10-14, review fold: RR-m2).
-   `GetFirstBindingNameFromPatternId` (sem_ir/pattern.cpp:57) and its callers
    (handle_pattern_list.cpp's struct shorthand, eval_inst.cpp and mangler.cpp
    for variables, export.cpp for globals): none; they take `var` and struct
    patterns, which cannot hold a pack expansion pattern in the slice.
-   `IsSelfPattern` and `GetPrettyNameFromPatternId` (sem_ir/pattern.cpp:51,
    :91): none; their default answers, `false` and no name, are right for a
    pack.
-   `FunctionInfo` (cpp/export.cpp:664): none; it walks call parameters, which
    are leaf patterns, and the export TODO comes first.
-   handle_match.cpp, refutable_binding.cpp and pattern_match.cpp's match-case
    walkers: none; they take `match`, `let` and `var` tuple patterns, where a
    pack expansion pattern is a TODO (W-214).

**toolchain/sem_ir/inst_kind.def.** The eight kinds, alphabetical (amended
2026-10-14, review fold: A-B1, A-B2, B-M1, B-M2).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/inst_kind.def
+++ b/toolchain/sem_ir/inst_kind.def
@@ -128,6 +128,14 @@ CARBON_SEM_IR_INST_KIND(OutParam)
 CARBON_SEM_IR_INST_KIND(OutParamPattern)
 CARBON_SEM_IR_INST_KIND(OverloadSetType)
 CARBON_SEM_IR_INST_KIND(OverloadSetValue)
+CARBON_SEM_IR_INST_KIND(PackElement)
+CARBON_SEM_IR_INST_KIND(PackExpansionExpr)
+CARBON_SEM_IR_INST_KIND(PackExpansionPattern)
+CARBON_SEM_IR_INST_KIND(PackExpansionStatement)
+CARBON_SEM_IR_INST_KIND(PackIndex)
+CARBON_SEM_IR_INST_KIND(PackLiteral)
+CARBON_SEM_IR_INST_KIND(PackType)
+CARBON_SEM_IR_INST_KIND(PackValue)
 CARBON_SEM_IR_INST_KIND(PartialType)
 CARBON_SEM_IR_INST_KIND(PatternType)
 CARBON_SEM_IR_INST_KIND(PointerType)
```

<!-- google-doc-style-resume -->

**toolchain/sem_ir/typed_insts.h.** The eight instructions of §1.4's table, each
documented with the design section it implements (amended 2026-10-14, review
fold: A-B1, A-B2, B-M1, B-M2).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/typed_insts.h
+++ b/toolchain/sem_ir/typed_insts.h
@@ -1633,6 +1633,131 @@ struct OverloadSetValue {
   OverloadSetId overload_set_id;
 };

+// The element of a pack that an each-name refers to on the current iteration
+// of the enclosing pack expansion: `each x` is the element of the pack `x` at
+// the pack index `index_id` (docs/design/variadics.md, "Execution Semantics":
+// "An each-name evaluates to the `$I`th value of the pack it refers to").
+// `pack_id` is a value of a `PackType`, which holds its elements' values, so
+// the element is read without copying it.
+struct PackElement {
+  static constexpr auto Kind = InstKind::PackElement.Define<Parse::NodeId>(
+      {.ir_name = "pack_element", .constant_kind = InstConstantKind::Never});
+
+  TypeId type_id;
+  InstId pack_id;
+  InstId index_id;
+};
+
+// A pack expansion element of a call argument list, `... body`
+// (docs/design/variadics.md, "Pack expansion expressions and statements"),
+// evaluated where it is written: `body_block_id` runs once per element of the
+// packs its each-names name, and the value of `result_id` on each iteration
+// becomes the next element of the resulting pack value. The same instruction
+// converts a pack value element by element ("Expansion convertibility"), with
+// a body that reads each element of the source pack.
+struct PackExpansionExpr {
+  static constexpr auto Kind =
+      InstKind::PackExpansionExpr.Define<Parse::NodeId>(
+          {.ir_name = "pack_expansion_expr",
+           .constant_kind = InstConstantKind::Never});
+
+  // Always a `PackType`: the type of `result_id`, repeated by the arity of the
+  // expansion.
+  TypeId type_id;
+  AbsoluteInstBlockId body_block_id;
+  InstId result_id;
+};
+
+// A pack expansion pattern, `... subpattern`, in a parameter list
+// (docs/design/variadics.md, "Pack expansion patterns"). `arity_pattern_id` is
+// the binding pattern of the pack's arity, a deduced parameter of the
+// enclosing full pattern ("Explicit deduced arities"): the callee binds it like
+// an implicit parameter, and a call supplies it by deduction.
+struct PackExpansionPattern {
+  static constexpr auto Kind =
+      InstKind::PackExpansionPattern.Define<Parse::PackExpansionPatternId>(
+          {.ir_name = "pack_expansion_pattern",
+           .expr_category = ExprCategory::Pattern,
+           .constant_kind = InstConstantKind::Always,
+           .is_lowered = false});
+
+  // Always a `PatternType` whose scrutinee type is a `PackType`.
+  TypeId type_id;
+  InstId subpattern_id;
+  InstId arity_pattern_id;
+};
+
+// A pack expansion statement, `... body` (docs/design/variadics.md,
+// "Execution Semantics"): `body_block_id` is executed once for each element of
+// the packs its each-names name, `arity_id` times.
+struct PackExpansionStatement {
+  static constexpr auto Kind =
+      InstKind::PackExpansionStatement.Define<Parse::PackExpansionStatementId>(
+          {.ir_name = "pack_expansion_statement",
+           .constant_kind = InstConstantKind::Never});
+
+  InstId arity_id;
+  AbsoluteInstBlockId body_block_id;
+};
+
+// The pack index `$I` of the innermost enclosing pack expansion: the index of
+// the element that an each-name refers to on the current iteration
+// (docs/design/variadics.md, "Execution Semantics": "Although the value of
+// `$I` can vary during execution, it is nevertheless treated as a
+// constant"). Its type is `Core.IntLiteral`; lowering supplies its value as a
+// constant on each iteration.
+struct PackIndex {
+  static constexpr auto Kind = InstKind::PackIndex.Define<Parse::NodeId>(
+      {.ir_name = "pack_index", .constant_kind = InstConstantKind::Never});
+
+  TypeId type_id;
+};
+
+// The run of arguments that a call matches against a pack expansion pattern,
+// merged into one segment: a pack literal (docs/design/variadics.md,
+// "Tuples, packs, segments, and shapes"). Its type is the tuple of its
+// elements' types; it is only ever converted to a `PackValue`, element by
+// element, and has no value of its own.
+struct PackLiteral {
+  static constexpr auto Kind = InstKind::PackLiteral.Define<Parse::NodeId>(
+      {.ir_name = "pack_literal",
+       .expr_category = ExprCategory::Mixed,
+       .constant_kind = InstConstantKind::Never});
+
+  TypeId type_id;
+  InstBlockId elements_id;
+};
+
+// The type `«E; N»` of a pack expansion segment: `arity_id` repetitions of
+// `element_type_inst_id` (docs/design/variadics.md, "Tuples, packs, segments,
+// and shapes"). A pack is a sequence of values, so a value of a pack type
+// holds the value representations of its elements, as a tuple value does,
+// and binding a pack never copies an element.
+struct PackType {
+  static constexpr auto Kind = InstKind::PackType.Define<Parse::NodeId>(
+      {.ir_name = "pack_type",
+       .is_type = InstIsType::Always,
+       .constant_kind = InstConstantKind::WheneverPossible,
+       .deduce_through = true});
+
+  TypeId type_id;
+  TypeInstId element_type_inst_id;
+  InstId arity_id;
+};
+
+// A value of a `PackType` formed from the values `elements_id`, one per
+// element: a call's pack literal converted to the type of the pack that it
+// initializes (docs/design/variadics.md, "Pattern matching": "the Nth
+// iteration of the pack expansion will initialize the Nth element of the
+// named pack from the Nth scrutinee").
+struct PackValue {
+  static constexpr auto Kind = InstKind::PackValue.Define<Parse::NodeId>(
+      {.ir_name = "pack_value", .constant_kind = InstConstantKind::Never});
+
+  TypeId type_id;
+  InstBlockId elements_id;
+};
+
 // Indicates `partial` on a type, such as `partial MyClass`.
 struct PartialType {
   static constexpr auto Kind =
```

<!-- google-doc-style-resume -->

**toolchain/sem_ir/ids.h.** The special name of the deduced arity (D-VA-3),
alphabetical.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/ids.h
+++ b/toolchain/sem_ir/ids.h
@@ -653,6 +653,8 @@ inline constexpr FloatKind FloatKind::PPCFloat128 = FloatKind(6);
   X(CppOperator)                                                 \
   /* The name of the default package `Main`. */                  \
   X(MainPackage)                                                 \
+  /* The name of the deduced arity of a pack. */                 \
+  X(PackArity)                                                   \
   /* The name of `package`. */                                   \
   X(PackageKeyword)                                              \
   /* The name of `.Self`. */                                     \
```

<!-- google-doc-style-resume -->

**toolchain/sem_ir/name.cpp.** Its spellings: `arity` in SemIR, `<pack arity>`
in diagnostics.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/name.cpp
+++ b/toolchain/sem_ir/name.cpp
@@ -33,6 +33,8 @@ static auto GetSpecialName(NameId name_id, bool for_ir) -> llvm::StringRef {
       return for_ir ? "cpp_operator" : "<C++ operator>";
     case NameId::SpecialNameId::MainPackage:
       return "Main";
+    case NameId::SpecialNameId::PackArity:
+      return for_ir ? "arity" : "<pack arity>";
     case NameId::SpecialNameId::PackageKeyword:
       return "package";
     case NameId::SpecialNameId::PeriodSelf:
```

<!-- google-doc-style-resume -->

**toolchain/sem_ir/stringify.cpp.** A pack type prints as the design's arity
coercion, `«E; N»`; the stringifier requires a case for every type
instruction. A call's printed argument list walks through a pack expansion
pattern to the pack's one argument (amended 2026-10-14, review fold: A-m3's
walker audit).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/stringify.cpp
+++ b/toolchain/sem_ir/stringify.cpp
@@ -457,6 +457,12 @@ class Stringifier {
           worklist.push_back(default_value.subpattern_id);
           break;
         }
+        case CARBON_KIND(PackExpansionPattern pack_expansion): {
+          // A pack's argument is the one pack value that the call passes for
+          // its run of arguments.
+          worklist.push_back(pack_expansion.subpattern_id);
+          break;
+        }
         case CARBON_KIND_ANY(AnyBindingPattern, binding): {
           if (binding.subpattern_id.has_value()) {
             worklist.push_back(binding.subpattern_id);
@@ -869,6 +875,11 @@ class Stringifier {
                                    name_scope.name_id());
   }

+  auto StringifyInst(InstId /*inst_id*/, PackType inst) -> void {
+    *out_ << "«";
+    step_stack_->Push(inst.element_type_inst_id, "; ", inst.arity_id, "»");
+  }
+
   auto StringifyInst(InstId /*inst_id*/, PartialType inst) -> void {
     *out_ << "partial ";

```

<!-- google-doc-style-resume -->

**toolchain/sem_ir/formatter.cpp.** The two instructions with bodies print
their operands and then the body as a trailing block, as `splice_block` does
(amended 2026-10-14, review fold: A-B1, which removed `PackExpansionInit`).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/formatter.cpp
+++ b/toolchain/sem_ir/formatter.cpp
@@ -1295,6 +1295,18 @@ auto Formatter::FormatInstRhs(Inst inst) -> void {
       return;
     }

+    case CARBON_KIND(PackExpansionExpr expansion): {
+      FormatArgs(expansion.result_id);
+      FormatTrailingBlock(expansion.body_block_id);
+      return;
+    }
+
+    case CARBON_KIND(PackExpansionStatement statement): {
+      FormatArgs(statement.arity_id);
+      FormatTrailingBlock(statement.body_block_id);
+      return;
+    }
+
     case CARBON_KIND(SpliceBlock splice): {
       FormatArgs(splice.result_id);
       FormatTrailingBlock(splice.block_id);
```

<!-- google-doc-style-resume -->

**toolchain/sem_ir/inst_namer.cpp.** Bodies are named in their enclosing scope;
the pack type is named `pack_type`.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/inst_namer.cpp
+++ b/toolchain/sem_ir/inst_namer.cpp
@@ -1456,6 +1456,19 @@ auto InstNamer::NamingContext::NameInst() -> void {
       AddInstNameId(NameId::ReturnSlot);
       return;
     }
+    case CARBON_KIND(PackExpansionExpr inst): {
+      PushBlockId(scope_id_, inst.body_block_id);
+      AddInstName("");
+      return;
+    }
+    case CARBON_KIND(PackExpansionStatement inst): {
+      PushBlockId(scope_id_, inst.body_block_id);
+      return;
+    }
+    case PackType::Kind: {
+      AddInstName("pack_type");
+      return;
+    }
     case CARBON_KIND(SpliceBlock inst): {
       PushBlockId(scope_id_, inst.block_id);
       AddInstName("");
```

<!-- google-doc-style-resume -->

**toolchain/sem_ir/dominance.cpp.** The verifier evaluates an expansion's body,
a statement's or an expression's, in place and, when the expansion ends,
forgets what the body defined, because the body runs once per element
(amended 2026-10-14, review fold: A-B1 / B-M2; rev 1's `PackExpansionExpr`
evaluated nothing and left its body to its consumer).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/dominance.cpp
+++ b/toolchain/sem_ir/dominance.cpp
@@ -501,11 +501,38 @@ auto DominanceVerifier::VerifyAndRecordInst(InstId root_inst_id,
     InstId inst_id;
     // Whether to finish a `SpliceBlock` after its block has been evaluated.
     bool finish_splice_block = false;
+    // For a pack expansion whose body has been evaluated, the size of
+    // `evaluated_order_` before its body; otherwise -1. The body runs once per
+    // element, so nothing it evaluates dominates the code after the expansion.
+    int finish_pack_expansion_scope = -1;
+  };
+
+  // Schedules the body of a pack expansion to be evaluated in place, followed
+  // by the step that ends its scope and records the expansion itself.
+  auto push_pack_expansion_body = [&](llvm::SmallVector<Step>& worklist,
+                                      InstId inst_id, InstBlockId body_id) {
+    worklist.push_back({.inst_id = inst_id,
+                        .finish_pack_expansion_scope =
+                            static_cast<int>(evaluated_order_.size())});
+    for (InstId body_inst_id :
+         llvm::reverse(file_.inst_blocks().Get(body_id))) {
+      worklist.push_back({.inst_id = body_inst_id});
+    }
   };

   llvm::SmallVector<Step> worklist = {{.inst_id = root_inst_id}};
   while (!worklist.empty()) {
-    auto [inst_id, finish_splice_block] = worklist.pop_back_val();
+    auto [inst_id, finish_splice_block, finish_pack_expansion_scope] =
+        worklist.pop_back_val();
+    if (finish_pack_expansion_scope >= 0) {
+      for (InstId body_inst_id :
+           llvm::drop_begin(evaluated_order_, finish_pack_expansion_scope)) {
+        evaluated_.Erase(body_inst_id);
+      }
+      evaluated_order_.truncate(finish_pack_expansion_scope);
+      RecordEvaluated(inst_id);
+      continue;
+    }
     if (finish_splice_block) {
       auto splice_block = file_.insts().GetAs<SpliceBlock>(inst_id);
       CARBON_RETURN_IF_ERROR(
@@ -529,6 +556,19 @@ auto DominanceVerifier::VerifyAndRecordInst(InstId root_inst_id,
       continue;
     }

+    // A `PackExpansionStatement` or `PackExpansionExpr` evaluates its body in
+    // place, once per element.
+    if (auto statement = inst.TryAs<PackExpansionStatement>()) {
+      CARBON_RETURN_IF_ERROR(
+          VerifyOperand(inst_id, statement->arity_id, block_index));
+      push_pack_expansion_body(worklist, inst_id, statement->body_block_id);
+      continue;
+    }
+    if (auto expansion = inst.TryAs<PackExpansionExpr>()) {
+      push_pack_expansion_body(worklist, inst_id, expansion->body_block_id);
+      continue;
+    }
+
     // A `SpliceInst` evaluates the instruction that its operand names.
     if (auto splice = inst.TryAs<SpliceInst>()) {
       CARBON_RETURN_IF_ERROR(
```

<!-- google-doc-style-resume -->

**toolchain/diagnostics/kind.def.** The checker's thirteen new kinds, in two
blocks: the variadics block after `SemanticsTodo` and the call block's four
(amended 2026-10-14, review fold: A-m2: `PackNameWithoutEach` is gone).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/diagnostics/kind.def
+++ b/toolchain/diagnostics/kind.def
@@ -239,6 +239,17 @@ CARBON_DIAGNOSTIC_KIND(NestedWhereInsideWhereOuterNote)

 CARBON_DIAGNOSTIC_KIND(SemanticsTodo)

+// Variadics checking (fork VA-1).
+CARBON_DIAGNOSTIC_KIND(EachBindingOutsidePackExpansion)
+CARBON_DIAGNOSTIC_KIND(EachNameNotPack)
+CARBON_DIAGNOSTIC_KIND(EachNameOutsidePackExpansion)
+CARBON_DIAGNOSTIC_KIND(EnclosingPackExpansion)
+CARBON_DIAGNOSTIC_KIND(MultiplePackExpansionPatterns)
+CARBON_DIAGNOSTIC_KIND(NestedPackExpansion)
+CARBON_DIAGNOSTIC_KIND(PackExpansionBindingWithoutEach)
+CARBON_DIAGNOSTIC_KIND(PackExpansionWithoutEachName)
+CARBON_DIAGNOSTIC_KIND(PreviousPackExpansionPattern)
+
 // Location context.
 CARBON_DIAGNOSTIC_KIND(InImport)
 CARBON_DIAGNOSTIC_KIND(InCppInclude)
@@ -313,6 +324,10 @@ CARBON_DIAGNOSTIC_KIND(NamespaceDeclNotAtTopLevel)

 // Function call checking.
 CARBON_DIAGNOSTIC_KIND(CallArgCountMismatch)
+CARBON_DIAGNOSTIC_KIND(CallArgCountTooFewForPack)
+CARBON_DIAGNOSTIC_KIND(InCallToVariadicFunction)
+CARBON_DIAGNOSTIC_KIND(PackExpansionArgForSingularParam)
+CARBON_DIAGNOSTIC_KIND(PackExpansionArgWithoutPackParam)
 CARBON_DIAGNOSTIC_KIND(CallToNonCallable)
 CARBON_DIAGNOSTIC_KIND(OverloadCandidateRejected)
 CARBON_DIAGNOSTIC_KIND(OverloadNoMatch)
```

<!-- google-doc-style-resume -->

**toolchain/check/context.h.** The stack of open expansions (for nesting,
each-name arity and pattern state) and the map from each pack's binding to its
arity binding (for each-name and bare-name lookup).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/context.h
+++ b/toolchain/check/context.h
@@ -519,6 +519,41 @@ class Context {
     return match_statement_stack_;
   }

+  // A pack expansion whose `...` has been checked but whose end has not
+  // (docs/design/variadics.md, "Pack expansions"). Pack expansions do not nest
+  // ("A pack expansion [...] cannot contain another pack expansion"), but the
+  // stack lets a nested `...` be diagnosed and recovered from.
+  struct PackExpansionScope {
+    enum class Kind : uint8_t { Statement, Expr, Pattern };
+
+    Kind kind;
+    // The `...` that starts the expansion.
+    Parse::PackExpansionStartId start_node_id;
+    // For a statement or expression: the block that holds the body, the
+    // cleanup depth on entry, and the arity of the packs that the body's
+    // each-names refer to, which is `None` until the first each-name.
+    SemIR::InstBlockId body_block_id = SemIR::InstBlockId::None;
+    ScopeStack::CleanupScopeDepth cleanup_depth =
+        ScopeStack::CleanupScopeDepth::None;
+    SemIR::InstId arity_id = SemIR::InstId::None;
+    // For a pattern: the binding pattern and binding of the pack's deduced
+    // arity, and the each-name binding pattern that the body declares with its
+    // element type, once checked.
+    SemIR::InstId arity_pattern_id = SemIR::InstId::None;
+    SemIR::InstId arity_binding_id = SemIR::InstId::None;
+    SemIR::InstId each_binding_pattern_id = SemIR::InstId::None;
+    SemIR::TypeInstId element_type_inst_id = SemIR::TypeInstId::None;
+  };
+  auto pack_expansion_stack() -> llvm::SmallVector<PackExpansionScope>& {
+    return pack_expansion_stack_;
+  }
+
+  // The arity binding of each pack declared by an each-name binding in this
+  // file, keyed by the pack's binding, which name lookup finds.
+  auto pack_binding_arities() -> Map<SemIR::InstId, SemIR::InstId>& {
+    return pack_binding_arities_;
+  }
+
   // An ongoing impl lookup, used to ensure termination.
   struct ImplLookupStackEntry {
     SemIR::ConstantId query_self_const_id;
@@ -897,6 +932,12 @@ class Context {
   // their arms cover for exhaustiveness.
   llvm::SmallVector<MatchStatementContext> match_statement_stack_;

+  // The stack of pack expansions currently being checked.
+  llvm::SmallVector<PackExpansionScope> pack_expansion_stack_;
+
+  // See `pack_binding_arities()`.
+  Map<SemIR::InstId, SemIR::InstId> pack_binding_arities_;
+
   // Tracks all ongoing impl lookups in order to ensure that lookup terminates
   // via the acyclic rule and the termination rule.
   llvm::SmallVector<ImplLookupStackEntry> impl_lookup_stack_;
```

<!-- google-doc-style-resume -->

**toolchain/check/context.cpp.** The expansion stack is empty when a file is
done.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/context.cpp
+++ b/toolchain/check/context.cpp
@@ -76,6 +76,7 @@ auto Context::VerifyOnFinish() const -> void {
   region_stack_.VerifyOnFinish();
   CARBON_CHECK(match_case_stack_.empty());
   CARBON_CHECK(match_statement_stack_.empty());
+  CARBON_CHECK(pack_expansion_stack_.empty());
   CARBON_CHECK(impl_lookup_stack_.empty());
   CARBON_CHECK(declaring_impl_decls_.empty());
   CARBON_CHECK(return_form_expr_ == std::nullopt);
```

<!-- google-doc-style-resume -->

**toolchain/check/type.h.** `GetPackType`.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/type.h
+++ b/toolchain/check/type.h
@@ -128,6 +128,11 @@ auto GetPointerType(Context& context, SemIR::TypeInstId pointee_type_id)
 auto GetArrayType(Context& context, SemIR::InstId bound_id,
                   SemIR::TypeInstId element_type_inst_id) -> SemIR::TypeId;

+// Gets the pack type `«element_type; arity»`: the type of a pack expansion
+// segment of `arity` elements of type `element_type`.
+auto GetPackType(Context& context, SemIR::TypeInstId element_type_id,
+                 SemIR::InstId arity_id) -> SemIR::TypeId;
+
 // Returns a struct type with the given fields.
 auto GetStructType(Context& context, SemIR::StructTypeFieldsId fields_id)
     -> SemIR::TypeId;
```

<!-- google-doc-style-resume -->

**toolchain/check/type.cpp.** `GetPackType`, through the canonical type
constructor.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/type.cpp
+++ b/toolchain/check/type.cpp
@@ -116,6 +116,11 @@ static auto GetCompleteTypeImpl(Context& context, EachArgT... each_arg)
   return type_id;
 }

+auto GetPackType(Context& context, SemIR::TypeInstId element_type_id,
+                 SemIR::InstId arity_id) -> SemIR::TypeId {
+  return GetTypeImpl<SemIR::PackType>(context, element_type_id, arity_id);
+}
+
 auto GetStructType(Context& context, SemIR::StructTypeFieldsId fields_id)
     -> SemIR::TypeId {
   return GetTypeImpl<SemIR::StructType>(context, fields_id);
```

<!-- google-doc-style-resume -->

**toolchain/check/type_completion.cpp.** A pack type's value representation is
always a pointer to `N` element value representations,
`ValueAndObjectAggregate` when the element's value representation is its
object representation and `ValueAggregate` otherwise (a tuple of one element,
by contrast, is passed by copy), and completing it completes its element type
first (amended 2026-10-14, review fold: A-B2 / B-M1; amended 2026-10-14,
review fold: RR-m3).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/type_completion.cpp
+++ b/toolchain/check/type_completion.cpp
@@ -295,6 +295,9 @@ class TypeCompleter {
   auto BuildInfoForInst(SemIR::TypeId type_id, SemIR::ArrayType /*inst*/) const
       -> SemIR::CompleteTypeInfo;

+  auto BuildInfoForInst(SemIR::TypeId type_id, SemIR::PackType pack_type) const
+      -> SemIR::CompleteTypeInfo;
+
   auto BuildInfoForInst(SemIR::TypeId /*type_id*/, SemIR::ClassType inst) const
       -> SemIR::CompleteTypeInfo;

@@ -450,6 +453,10 @@ auto TypeCompleter::AddNestedIncompleteTypes(SemIR::Inst type_inst) -> bool {
       Push(context_->types().GetTypeIdForTypeInstId(inst.element_type_inst_id));
       break;
     }
+    case CARBON_KIND(SemIR::PackType inst): {
+      Push(context_->types().GetTypeIdForTypeInstId(inst.element_type_inst_id));
+      break;
+    }
     case CARBON_KIND(SemIR::StructType inst): {
       for (auto field : context_->struct_type_fields().Get(inst.fields_id)) {
         Push(context_->types().GetTypeIdForTypeInstId(field.type_inst_id));
@@ -700,6 +707,40 @@ auto TypeCompleter::BuildInfoForInst(SemIR::TypeId type_id,
           .object_layout = layout};
 }

+// Fork (VA-1, D-VA-3): a pack is a sequence of values, so a value of a pack
+// type holds the value representations of its elements, as a tuple value does
+// (`BuildStructOrTupleValueRepr`): binding an element never copies it. It is
+// always passed by address, like an array, so that it can be indexed by the
+// pack index.
+auto TypeCompleter::BuildInfoForInst(SemIR::TypeId type_id,
+                                     SemIR::PackType pack_type) const
+    -> SemIR::CompleteTypeInfo {
+  auto element_type_id =
+      context_->types().GetTypeIdForTypeInstId(pack_type.element_type_inst_id);
+  auto element_info = GetNestedInfo(element_type_id);
+  bool same_as_object_rep = element_info.value_repr.IsCopyOfObjectRepr(
+      context_->sem_ir(), element_type_id);
+  auto value_rep_id = same_as_object_rep
+                          ? type_id
+                          : GetPackType(*context_,
+                                        context_->types().GetTypeInstId(
+                                            element_info.value_repr.type_id),
+                                        pack_type.arity_id);
+
+  SemIR::ObjectLayout layout;
+  if (element_info.object_layout.has_value()) {
+    if (auto arity = context_->sem_ir().GetZExtIntValue(pack_type.arity_id)) {
+      layout =
+          SemIR::ObjectLayout::ForArray(element_info.object_layout, *arity);
+    }
+  }
+  return {.value_repr = MakePointerValueRepr(
+              value_rep_id, same_as_object_rep
+                                ? SemIR::ValueRepr::ValueAndObjectAggregate
+                                : SemIR::ValueRepr::ValueAggregate),
+          .object_layout = layout};
+}
+
 auto TypeCompleter::BuildInfoForInst(SemIR::TypeId type_id,
                                      SemIR::BoolType /*inst*/) const
     -> SemIR::CompleteTypeInfo {
```

<!-- google-doc-style-resume -->

**toolchain/check/handle_binding_pattern.cpp.** An each-name binding must be
inside a pattern expansion and a binding inside a pattern expansion must be an
each-name (DR-6, DR-23); its declared type `E` becomes `«E; N»` (D-VA-3;
amended 2026-10-14, review fold: A-B2 / B-M1); the pack is recorded for its
expansion and for lookup.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_binding_pattern.cpp
+++ b/toolchain/check/handle_binding_pattern.cpp
@@ -326,8 +326,65 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
       context.node_stack()
           .PopAndDiscardSoloNodeIdIf<Parse::NodeKind::RefBindingName>();

+  // The name may be an each-name, which declares a pack
+  // (docs/design/variadics.md, "Packs and each-names").
+  bool is_each =
+      context.node_stack()
+          .PopAndDiscardSoloNodeIdIf<Parse::NodeKind::EachBindingName>();
+
   auto [name_node, name_id] = context.node_stack().PopNameWithNodeId();

+  // The pack expansion pattern whose operand this binding is, if any.
+  Context::PackExpansionScope* pack_scope = nullptr;
+  if (!context.pack_expansion_stack().empty() &&
+      context.pack_expansion_stack().back().kind ==
+          Context::PackExpansionScope::Kind::Pattern) {
+    pack_scope = &context.pack_expansion_stack().back();
+  }
+  if (is_each && !pack_scope) {
+    CARBON_DIAGNOSTIC(EachBindingOutsidePackExpansion, Error,
+                      "each-name binding `each {0}` is not inside a pack "
+                      "expansion pattern",
+                      SemIR::NameId);
+    context.emitter().Emit(name_node, EachBindingOutsidePackExpansion, name_id);
+    is_each = false;
+  } else if (!is_each && pack_scope) {
+    // "a binding pattern within a pack expansion pattern must declare an
+    // each-name" (docs/design/variadics.md, "Pack expansion patterns").
+    CARBON_DIAGNOSTIC(PackExpansionBindingWithoutEach, Error,
+                      "binding pattern in a pack expansion must declare an "
+                      "each-name, such as `each {0}`",
+                      SemIR::NameId);
+    context.emitter().Emit(name_node, PackExpansionBindingWithoutEach, name_id);
+    return false;
+  } else if (is_each) {
+    // Fork (VA-1, D-VA-5): a pack's elements are values of a type that does
+    // not depend on the pack, and the operand declares one each-name.
+    if (node_kind != Parse::NodeKind::LetBindingPattern || is_ref) {
+      return context.TODO(name_node,
+                          "each-name binding that is not a value binding");
+    }
+    if (pack_scope->each_binding_pattern_id.has_value()) {
+      return context.TODO(name_node,
+                          "pack expansion pattern declaring more than one "
+                          "each-name");
+    }
+  }
+  // The type of an each-name binding's pack is `«E; N»` for the declared
+  // element type `E` and the pack's deduced arity `N`: "each X: T" becomes
+  // "each X: «T; __N»" (docs/design/variadics.md, "Explicit deduced
+  // arities"). A value of that type holds the elements' values (fork VA-1,
+  // D-VA-3).
+  auto element_type_inst_id = SemIR::TypeInstId::None;
+  if (is_each && type_expr.type_component_id != SemIR::ErrorInst::TypeId) {
+    element_type_inst_id = type_expr.type_component_inst_id;
+    auto pack_type_id = GetPackType(context, element_type_inst_id,
+                                    pack_scope->arity_binding_id);
+    type_expr.type_component_id = pack_type_id;
+    type_expr.type_component_inst_id =
+        context.types().GetTypeInstId(pack_type_id);
+  }
+
   const DeclIntroducerState& introducer =
       context.decl_introducer_state_stack().innermost();

@@ -499,6 +556,17 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
           }
           result_inst_id = make_binding_pattern(
               SemIR::WrapperBindingPattern::Kind, param_pattern_id);
+          if (is_each) {
+            // Record the pack for its pack expansion pattern, and for name
+            // lookup of its each-name.
+            pack_scope->each_binding_pattern_id = result_inst_id;
+            pack_scope->element_type_inst_id = element_type_inst_id;
+            context.pack_binding_arities().Insert(context.bind_name_map()
+                                                      .Lookup(result_inst_id)
+                                                      .value()
+                                                      .bind_name_id,
+                                                  pack_scope->arity_binding_id);
+          }
           break;
         }
         case Parse::NodeKind::VarBindingPattern:
```

<!-- google-doc-style-resume -->

**toolchain/check/handle_name.cpp.** A bare pack name is a `semantics TODO`
(D-VA-11; amended 2026-10-14, review fold: A-m2); otherwise the same reference
as before.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_name.cpp
+++ b/toolchain/check/handle_name.cpp
@@ -136,8 +136,17 @@ auto HandleParseNode(Context& context,
 auto HandleParseNode(Context& context, Parse::IdentifierNameExprId node_id)
     -> bool {
   auto name_id = GetIdentifierAsNameId(context, node_id);
-  context.node_stack().Push(node_id,
-                            HandleNameAsExpr(context, node_id, name_id));
+  auto result = LookupUnqualifiedName(context, node_id, name_id);
+  auto target_id = result.scope_result.target_inst_id();
+  // Fork (VA-1, D-VA-11): the design gives a pack's name without `each` no
+  // meaning yet, and leaves it open for operations on the whole sequence
+  // (proposals/p002240-variadics.md, "Omit each-names").
+  if (context.pack_binding_arities().Contains(target_id)) {
+    return context.TODO(node_id, "use of a pack's name without `each`");
+  }
+  context.node_stack().Push(
+      node_id,
+      BuildNameRef(context, node_id, name_id, target_id, result.specific_id));
   return true;
 }

```

<!-- google-doc-style-resume -->

**toolchain/check/handle_tuple_literal.cpp.** A tuple literal that holds an
expansion and is not a call's argument list is a TODO (D-VA-4, W-213).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_tuple_literal.cpp
+++ b/toolchain/check/handle_tuple_literal.cpp
@@ -29,6 +29,16 @@ auto HandleParseNode(Context& context, Parse::TupleLiteralId node_id) -> bool {
   context.node_stack()
       .PopAndDiscardSoloNodeId<Parse::NodeKind::TupleLiteralStart>();
   const auto& inst_block = context.inst_blocks().Get(refs_id);
+  // Fork (VA-1, D-VA-4): a tuple literal with a pack expansion element has a
+  // type with a pack segment, `(... «E; N»)`, which this slice does not
+  // represent; only a call's argument list can hold a pack expansion yet.
+  for (auto inst : inst_block) {
+    if (context.insts().Is<SemIR::PackExpansionExpr>(inst)) {
+      return context.TODO(inst,
+                          "pack expansion in a tuple literal outside a call's "
+                          "argument list");
+    }
+  }
   llvm::SmallVector<SemIR::InstId> type_inst_ids;
   type_inst_ids.reserve(inst_block.size());
   for (auto inst : inst_block) {
```

<!-- google-doc-style-resume -->

**toolchain/check/call.cpp.** `GroupPackArguments` (D-VA-4) and its diagnostics,
and the TODOs for overload sets and template-dependent calls; a non-Carbon
callee rejects an expansion argument.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/call.cpp
+++ b/toolchain/check/call.cpp
@@ -295,6 +295,131 @@ static auto RequireBuiltinCallPointeeComplete(
   });
 }

+// Returns whether `arg_id` is a pack expansion argument, `... expression`.
+static auto IsPackExpansionArg(Context& context, SemIR::InstId arg_id) -> bool {
+  return context.insts().Is<SemIR::PackExpansionExpr>(arg_id);
+}
+
+// Diagnoses a pack expansion argument for a callee without a pack expansion
+// parameter to match it.
+static auto DiagnosePackExpansionArgWithoutPackParam(Context& context,
+                                                     SemIR::InstId arg_id)
+    -> void {
+  CARBON_DIAGNOSTIC(PackExpansionArgWithoutPackParam, Error,
+                    "pack expansion argument is not matched by a pack "
+                    "expansion parameter");
+  context.emitter().Emit(arg_id, PackExpansionArgWithoutPackParam);
+}
+
+// Returns the index of the pack expansion pattern in `function`'s parameter
+// patterns, or `nullopt` if it has none.
+static auto FindPackExpansionParam(Context& context,
+                                   const SemIR::Function& function)
+    -> std::optional<size_t> {
+  for (auto [index, pattern_id] : llvm::enumerate(
+           context.inst_blocks().GetOrEmpty(function.param_patterns_id))) {
+    auto const_inst_id =
+        context.constant_values().GetConstantInstId(pattern_id);
+    if (const_inst_id.has_value() &&
+        context.insts().Is<SemIR::PackExpansionPattern>(const_inst_id)) {
+      return index;
+    }
+  }
+  return std::nullopt;
+}
+
+// Fork (VA-1): matches a call's arguments against a variadic callee's
+// parameters (docs/design/variadics.md, "Pattern matching"). The arguments
+// before and after the pack expansion pattern match the parameters before and
+// after it one to one, and the run of arguments between them becomes the
+// pattern's single scrutinee: a `PackLiteral` of those arguments, or a
+// forwarded pack expansion argument on its own (D-VA-4). Returns `false` after
+// diagnosing.
+static auto GroupPackArguments(
+    Context& context, SemIR::LocId loc_id, const SemIR::Function& function,
+    SemIR::InstId self_id, llvm::ArrayRef<SemIR::InstId> arg_ids,
+    llvm::SmallVectorImpl<SemIR::InstId>& grouped_arg_ids) -> bool {
+  auto is_expansion = [&](SemIR::InstId arg_id) {
+    return IsPackExpansionArg(context, arg_id);
+  };
+  auto pack_index = FindPackExpansionParam(context, function);
+  if (!pack_index) {
+    if (const auto* it = llvm::find_if(arg_ids, is_expansion);
+        it != arg_ids.end()) {
+      DiagnosePackExpansionArgWithoutPackParam(context, *it);
+      return false;
+    }
+    grouped_arg_ids.assign(arg_ids.begin(), arg_ids.end());
+    return true;
+  }
+
+  size_t self_size = self_id.has_value() ? 1 : 0;
+  size_t num_params =
+      context.inst_blocks().GetOrEmpty(function.param_patterns_id).size() -
+      self_size;
+  size_t num_before = *pack_index - self_size;
+  size_t num_after = num_params - num_before - 1;
+  if (arg_ids.size() < num_before + num_after) {
+    CARBON_DIAGNOSTIC(CallArgCountTooFewForPack, Error,
+                      "{0} argument{0:s} passed to function expecting at "
+                      "least {1} argument{1:s}",
+                      Diagnostics::IntAsSelect, Diagnostics::IntAsSelect);
+    CARBON_DIAGNOSTIC(InCallToVariadicFunction, Note,
+                      "calling function declared here");
+    context.emitter()
+        .Build(loc_id, CallArgCountTooFewForPack, arg_ids.size(),
+               num_before + num_after)
+        .Note(function.latest_decl_id(), InCallToVariadicFunction)
+        .Emit();
+    return false;
+  }
+
+  // A pack expansion argument's arity is not known until monomorphization, so
+  // it cannot be split to match a parameter that is not a pack expansion
+  // (docs/design/variadics.md, "Typechecking pattern matches").
+  for (auto arg_id : llvm::concat<const SemIR::InstId>(
+           arg_ids.take_front(num_before), arg_ids.take_back(num_after))) {
+    if (is_expansion(arg_id)) {
+      CARBON_DIAGNOSTIC(PackExpansionArgForSingularParam, Error,
+                        "pack expansion argument cannot match a parameter "
+                        "that is not a pack expansion");
+      context.emitter().Emit(arg_id, PackExpansionArgForSingularParam);
+      return false;
+    }
+  }
+
+  auto pack_arg_ids = arg_ids.drop_front(num_before).drop_back(num_after);
+  auto pack_arg_id = SemIR::InstId::None;
+  if (llvm::any_of(pack_arg_ids, is_expansion)) {
+    // Fork (VA-1, D-VA-4): merging a pack expansion argument with other
+    // arguments would deduce an arity `N + k`, and the arity has no `+` yet.
+    if (pack_arg_ids.size() != 1) {
+      context.TODO(loc_id,
+                   "pack expansion argument merged with other arguments for "
+                   "the same pack");
+      return false;
+    }
+    pack_arg_id = pack_arg_ids.front();
+  } else {
+    llvm::SmallVector<SemIR::InstId> type_inst_ids;
+    type_inst_ids.reserve(pack_arg_ids.size());
+    for (auto arg_id : pack_arg_ids) {
+      type_inst_ids.push_back(
+          context.types().GetTypeInstId(context.insts().Get(arg_id).type_id()));
+    }
+    pack_arg_id = AddInst<SemIR::PackLiteral>(
+        context,
+        pack_arg_ids.empty() ? loc_id : SemIR::LocId(pack_arg_ids.front()),
+        {.type_id = GetTupleType(context, type_inst_ids),
+         .elements_id = context.inst_blocks().Add(pack_arg_ids)});
+  }
+
+  grouped_arg_ids.assign(arg_ids.begin(), arg_ids.begin() + num_before);
+  grouped_arg_ids.push_back(pack_arg_id);
+  grouped_arg_ids.append(arg_ids.end() - num_after, arg_ids.end());
+  return true;
+}
+
 auto PerformCallToFunction(Context& context, SemIR::LocId loc_id,
                            SemIR::InstId callee_id,
                            const SemIR::CalleeFunction& callee_function,
@@ -304,6 +429,15 @@ auto PerformCallToFunction(Context& context, SemIR::LocId loc_id,
   // for the call. Also check the arity of the function against the arguments,
   // with allowance for default argument values.
   const auto& function = context.functions().Get(callee_function.function_id);
+
+  // A variadic callee matches a run of the arguments with its pack expansion
+  // pattern; group that run into the pattern's single scrutinee.
+  llvm::SmallVector<SemIR::InstId> grouped_arg_ids;
+  if (!GroupPackArguments(context, loc_id, function, callee_function.self_id,
+                          arg_ids, grouped_arg_ids)) {
+    return SemIR::ErrorInst::InstId;
+  }
+  arg_ids = grouped_arg_ids;
   auto callee_specific_id = ResolveCalleeInCall(
       context, loc_id, function, EntityKind::Function,
       callee_function.enclosing_specific_id, callee_function.self_id, arg_ids,
@@ -608,6 +742,16 @@ static auto PerformCallToOverloadSet(Context& context, SemIR::LocId loc_id,
     return SemIR::ErrorInst::InstId;
   }

+  // Fork (VA-1, D-VA-4): a variadic member or a pack expansion argument would
+  // need the probe to group the arguments for each member.
+  if (llvm::any_of(arg_ids, [&](SemIR::InstId arg_id) {
+        return IsPackExpansionArg(context, arg_id);
+      })) {
+    context.TODO(loc_id,
+                 "pack expansion argument in a call to an overload set");
+    return SemIR::ErrorInst::InstId;
+  }
+
   // D-OV-6 gate (xi): resolution over template-dependent arguments happens
   // after substitution, which is not supported yet.
   for (auto arg_id : arg_ids) {
@@ -651,6 +795,12 @@ static auto PerformCallToOverloadSet(Context& context, SemIR::LocId loc_id,
       continue;
     }

+    // Fork (VA-1, D-VA-4): see above.
+    if (FindPackExpansionParam(context, function)) {
+      context.TODO(loc_id, "variadic member of an overload set");
+      return SemIR::ErrorInst::InstId;
+    }
+
     // (b) Arity, keyed on the call's receiver as the ordinary call path is.
     auto [min_args, max_args] =
         GetExplicitArityRange(context, function, self_id);
@@ -840,6 +990,20 @@ static auto PerformCallHelper(Context& context, SemIR::LocId loc_id,
                               bool is_desugared) {
   // Try treating the callee as a function first.
   auto callee = GetCallee(context.sem_ir(), callee_id);
+
+  // Fork (VA-1): only a Carbon function, or a member of an overload set, can
+  // have a pack expansion parameter to match a pack expansion argument.
+  if (!std::holds_alternative<SemIR::CalleeFunction>(callee) &&
+      !std::holds_alternative<SemIR::CalleeOverloadSet>(callee) &&
+      !std::holds_alternative<SemIR::CalleeError>(callee)) {
+    for (auto arg_id : arg_ids) {
+      if (IsPackExpansionArg(context, arg_id)) {
+        DiagnosePackExpansionArgWithoutPackParam(context, arg_id);
+        return SemIR::ErrorInst::InstId;
+      }
+    }
+  }
+
   CARBON_KIND_SWITCH(callee) {
     case CARBON_KIND(SemIR::CalleeError _): {
       return SemIR::ErrorInst::InstId;
@@ -875,6 +1039,16 @@ auto PerformCall(Context& context, SemIR::LocId loc_id, SemIR::InstId callee_id,
     return PerformCallHelper(context, loc_id, callee_id, arg_ids, is_desugared);
   }

+  // Fork (VA-1, D-VA-5): packs are not template-dependent in this slice.
+  for (auto arg_id : arg_ids) {
+    if (IsPackExpansionArg(context, arg_id)) {
+      context.TODO(arg_id,
+                   "pack expansion argument in a template-dependent "
+                   "call");
+      return SemIR::ErrorInst::InstId;
+    }
+  }
+
   // Pack the callee and args into an inst block. This is an optimization to
   // avoid needing a Bundle in the `CallAction`.
   llvm::SmallVector<SemIR::InstId> inst_ids;
```

<!-- google-doc-style-resume -->

**toolchain/check/deduce.cpp.** A `PackType` parameter deduces its arity and
element type from a pack literal's tuple type or a forwarded expansion's pack
type (DR-37).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/deduce.cpp
+++ b/toolchain/check/deduce.cpp
@@ -9,6 +9,7 @@
 #include "toolchain/check/context.h"
 #include "toolchain/check/convert.h"
 #include "toolchain/check/generic.h"
+#include "toolchain/check/inst.h"
 #include "toolchain/check/subst.h"
 #include "toolchain/check/type.h"
 #include "toolchain/diagnostics/diagnostic.h"
@@ -434,6 +435,40 @@ auto DeductionContext::Deduce() -> bool {
         continue;
       }

+      // Deducing a pack type `«E; N»` against the tuple type `(A1, ..., Ak)`
+      // of a pack literal deduces the arity `N` as `k`, and `E` against each
+      // `Ai` (docs/design/variadics.md, "Typechecking pattern matches").
+      // Against another pack type, as when a call forwards a pack expansion,
+      // it deduces the element type and the arity from the other's.
+      case CARBON_KIND(SemIR::PackType pack_type): {
+        if (auto arg_pack_type =
+                context().insts().TryGetAs<SemIR::PackType>(arg_id)) {
+          Add(pack_type.arity_id, arg_pack_type->arity_id,
+              /*want_value=*/true);
+          Add(pack_type.element_type_inst_id,
+              arg_pack_type->element_type_inst_id, /*want_value=*/true);
+          continue;
+        }
+        auto arg_tuple_type =
+            context().insts().TryGetAs<SemIR::TupleType>(arg_id);
+        if (!arg_tuple_type) {
+          break;
+        }
+        auto element_ids =
+            context().inst_blocks().Get(arg_tuple_type->type_elements_id);
+        auto arity_id = GetOrAddInst<SemIR::IntValue>(
+            context(), loc_id_,
+            {.type_id =
+                 GetSingletonType(context(), SemIR::IntLiteralType::TypeInstId),
+             .int_id = context().ints().Add(
+                 static_cast<int64_t>(element_ids.size()))});
+        Add(pack_type.arity_id, arity_id, /*want_value=*/true);
+        for (auto element_id : llvm::reverse(element_ids)) {
+          Add(pack_type.element_type_inst_id, element_id, /*want_value=*/true);
+        }
+        continue;
+      }
+
       case SemIR::StructValue::Kind:
         // TODO: Match field name order between param and arg.
         break;
```

<!-- google-doc-style-resume -->

**toolchain/check/pattern_match.cpp.** A `PackExpansionPattern` matches its
operand against the grouped scrutinee; in the callee it also binds the arity
like an implicit parameter, before the pack. The new `DoPreWork` is defined
above the `// TODO: There is a cycle ...` and
`// NOLINTNEXTLINE(misc-no-recursion)` pair, so that the pair stays directly
above `Dispatch` (M-23; amended 2026-10-14, review fold: B-M3).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/pattern_match.cpp
+++ b/toolchain/check/pattern_match.cpp
@@ -255,6 +255,8 @@ class MatchContext {
                  SemIR::InstId scrutinee_id, WorkItem entry) -> void;
   auto DoPreWork(State state, SemIR::DefaultValuePattern default_value_pattern,
                  SemIR::InstId scrutinee_id, WorkItem entry) -> void;
+  auto DoPreWork(State state, SemIR::PackExpansionPattern pack_pattern,
+                 SemIR::InstId scrutinee_id, WorkItem entry) -> void;

   // Do the post-work for `entry`. `entry.work` must be a `PostWork`, and
   // the pattern argument must be the value of `entry.pattern_id` in `context_`.
@@ -2299,6 +2301,25 @@ auto MatchContext::DoPreWork(State state,
            .allow_unmarked_ref = entry.allow_unmarked_ref});
 }

+// Fork (VA-1): a pack expansion pattern matches the run of arguments that the
+// call grouped into its scrutinee by matching its operand, the each-name
+// binding, against it (docs/design/variadics.md, "Pattern matching"); the
+// operand's parameter converts the run to the value of the pack. The pack's
+// arity is a deduced parameter ("Explicit deduced arities"), so the callee
+// binds it like an implicit parameter, before the pack itself.
+auto MatchContext::DoPreWork(State state,
+                             SemIR::PackExpansionPattern pack_pattern,
+                             SemIR::InstId scrutinee_id, WorkItem entry)
+    -> void {
+  AddWork({.pattern_id = pack_pattern.subpattern_id,
+           .work = PreWork{.scrutinee_id = scrutinee_id},
+           .allow_unmarked_ref = entry.allow_unmarked_ref});
+  if (std::holds_alternative<CalleeState*>(state)) {
+    AddWork({.pattern_id = pack_pattern.arity_pattern_id,
+             .work = PreWork{.scrutinee_id = SemIR::InstId::None}});
+  }
+}
+
 // TODO: There is a cycle through pattern matching with an action.
 // NOLINTNEXTLINE(misc-no-recursion)
 auto MatchContext::Dispatch(State state, WorkItem entry) -> void {
@@ -2370,6 +2391,10 @@ auto MatchContext::Dispatch(State state, WorkItem entry) -> void {
           DoPreWork(state, default_value_pattern, work.scrutinee_id, entry);
           break;
         }
+        case CARBON_KIND(SemIR::PackExpansionPattern pack_pattern): {
+          DoPreWork(state, pack_pattern, work.scrutinee_id, entry);
+          break;
+        }
         default: {
           CARBON_FATAL("Inst kind not handled: {0}", pattern.kind());
         }
```

<!-- google-doc-style-resume -->

**toolchain/check/convert.cpp.** A `PackLiteral` converts to a `PackValue` of
its elements, each converted to a value of the element type; a pack value
converts to a pack of another element type by a `PackExpansionExpr` whose body
converts the element at the pack index (DR-41), with D-VA-6's cleanup TODO;
`TryToCompleteClassType` looks inside pack types as type completion does. Rev
1's array conversions are gone (amended 2026-10-14, review fold: A-B1, A-B2,
B-M1, B-M2).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/convert.cpp
+++ b/toolchain/check/convert.cpp
@@ -503,6 +503,104 @@ static auto ConvertTupleToArray(Context& context, SemIR::TupleType tuple_type,
                                     .dest_id = return_slot_arg_id});
 }

+// Fork (VA-1, D-VA-3): converts the pack literal of a call's run of arguments
+// to the value of the pack that it initializes. Each argument is converted to
+// a value of the element type, and a pack value holds its elements' values as
+// they are, so no element is copied: "the Nth iteration of the pack expansion
+// will initialize the Nth element of the named pack from the Nth scrutinee"
+// (docs/design/variadics.md, "Pack expansion patterns"). This only converts
+// the type, and produces a value.
+static auto ConvertPackLiteralToPack(Context& context,
+                                     SemIR::PackLiteral literal,
+                                     SemIR::PackType pack_type,
+                                     SemIR::InstId value_id,
+                                     ConversionTarget target) -> SemIR::InstId {
+  auto elements = context.inst_blocks().Get(literal.elements_id);
+  // Deduction made the pack's arity the literal's element count.
+  CARBON_CHECK(
+      context.sem_ir().GetZExtIntValue(pack_type.arity_id) == elements.size(),
+      "Pack literal of {0} elements converted to {1}", elements.size(),
+      target.type_id);
+  auto element_type_id =
+      context.types().GetTypeIdForTypeInstId(pack_type.element_type_inst_id);
+  llvm::SmallVector<SemIR::InstId> value_ids;
+  value_ids.reserve(elements.size());
+  for (auto element_id : elements) {
+    auto converted_id = Convert(context, SemIR::LocId(element_id), element_id,
+                                {.kind = ConversionTarget::Value,
+                                 .type_id = element_type_id,
+                                 .diagnose = target.diagnose});
+    if (converted_id == SemIR::ErrorInst::InstId) {
+      return SemIR::ErrorInst::InstId;
+    }
+    value_ids.push_back(converted_id);
+  }
+  return AddInst<SemIR::PackValue>(
+      context, SemIR::LocId(value_id),
+      {.type_id = target.type_id,
+       .elements_id = context.inst_blocks().Add(value_ids)});
+}
+
+// Fork (VA-1, D-VA-3): converts a pack value of type `«U; N»`, such as the
+// value of a pack expansion argument, to `«T; N»` when `U` converts to `T`
+// (docs/design/variadics.md, "Expansion convertibility"). The result is a pack
+// expansion whose body converts the source's element at the pack index; like
+// the argument's own expansion, it runs once per element. This only converts
+// the type, and produces a value.
+static auto ConvertPackToPack(Context& context, SemIR::PackType src_type,
+                              SemIR::PackType target_type,
+                              SemIR::InstId value_id, ConversionTarget target)
+    -> SemIR::InstId {
+  SemIR::LocId value_loc_id(value_id);
+
+  // Deduction made the target's arity the source's.
+  CARBON_CHECK(context.constant_values().Get(src_type.arity_id) ==
+                   context.constant_values().Get(target_type.arity_id),
+               "Pack of arity {0} converted to {1}", src_type.arity_id,
+               target.type_id);
+
+  auto cleanup_depth = context.scope_stack().cleanup_scope_depth();
+  context.inst_block_stack().Push();
+  auto body_block_id = context.inst_block_stack().PeekOrAdd();
+  auto index_id = AddInst<SemIR::PackIndex>(
+      context, value_loc_id,
+      {.type_id =
+           GetSingletonType(context, SemIR::IntLiteralType::TypeInstId)});
+  auto element_id = AddInst<SemIR::PackElement>(
+      context, value_loc_id,
+      {.type_id = context.types().GetTypeIdForTypeInstId(
+           src_type.element_type_inst_id),
+       .pack_id = value_id,
+       .index_id = index_id});
+  auto result_id = Convert(context, value_loc_id, element_id,
+                           {.kind = ConversionTarget::Value,
+                            .type_id = context.types().GetTypeIdForTypeInstId(
+                                target_type.element_type_inst_id),
+                            .diagnose = target.diagnose});
+  CARBON_CHECK(context.inst_block_stack().is_current_block_reachable() &&
+                   context.inst_block_stack().PeekOrAdd() == body_block_id,
+               "Control flow in a pack element conversion");
+  bool needs_cleanup =
+      context.scope_stack().cleanup_scope_depth() != cleanup_depth;
+  context.inst_block_stack().Pop();
+  if (result_id == SemIR::ErrorInst::InstId) {
+    return SemIR::ErrorInst::InstId;
+  }
+  // Fork (VA-1, D-VA-6): a temporary in an element conversion would need to be
+  // destroyed once per element.
+  if (needs_cleanup) {
+    if (target.diagnose) {
+      context.TODO(value_loc_id,
+                   "pack element conversion that needs a cleanup");
+    }
+    return SemIR::ErrorInst::InstId;
+  }
+  return AddInst<SemIR::PackExpansionExpr>(context, value_loc_id,
+                                           {.type_id = target.type_id,
+                                            .body_block_id = body_block_id,
+                                            .result_id = result_id});
+}
+
 // Performs a conversion from a function to a C++ function pointer type.
 static auto ConvertFunctionToCppPointer(
     Context& context, SemIR::LocId loc_id, SemIR::FunctionType src_type,
@@ -1287,6 +1385,7 @@ static auto TryToCompleteClassType(Context& context, SemIR::TypeId type_id,
         context.types().Is<SemIR::ConstType>(type_id) ||
         context.types().Is<SemIR::CustomLayoutType>(type_id) ||
         context.types().Is<SemIR::MaybeUnformedType>(type_id) ||
+        context.types().Is<SemIR::PackType>(type_id) ||
         context.types().Is<SemIR::PartialType>(type_id))) {
     return true;
   }
@@ -1784,6 +1883,21 @@ static auto PerformBuiltinConversion(Context& context, SemIR::LocId loc_id,
     }
   }

+  // Fork (VA-1, D-VA-3): a call's pack literal of types (T1, T2, ..., Tn)
+  // converts to the pack «T; n» if each Ti converts to T, and a pack «U; N»
+  // converts to «T; N» if U converts to T.
+  if (auto target_pack_type = target_type_inst.TryAs<SemIR::PackType>()) {
+    if (auto literal = value.TryAs<SemIR::PackLiteral>()) {
+      return ConvertPackLiteralToPack(context, *literal, *target_pack_type,
+                                      value_id, target);
+    }
+    if (auto src_pack_type =
+            sem_ir.types().TryGetAs<SemIR::PackType>(value_type_id)) {
+      return ConvertPackToPack(context, *src_pack_type, *target_pack_type,
+                               value_id, target);
+    }
+  }
+
   // Function types can convert to C++ function pointer types.
   if (auto fn_ptr_type =
           context.types().TryGetAs<SemIR::CppFunctionPointerType>(
```

<!-- google-doc-style-resume -->

**toolchain/check/import_ref.cpp.** Import of `PackExpansionPattern` and
`PackType`.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/import_ref.cpp
+++ b/toolchain/check/import_ref.cpp
@@ -2474,6 +2474,40 @@ static auto TryResolveTypedInst(ImportRefResolver& resolver,
       });
 }

+static auto TryResolveTypedInst(ImportRefResolver& resolver,
+                                SemIR::PackExpansionPattern inst)
+    -> ResolveResult {
+  auto type_const_id = GetLocalConstantId(resolver, inst.type_id);
+  auto subpattern = GetLocalImportRefInfo(resolver, inst.subpattern_id);
+  auto arity_pattern = GetLocalImportRefInfo(resolver, inst.arity_pattern_id);
+  if (resolver.HasNewWork()) {
+    return ResolveResult::Retry();
+  }
+
+  return ResolveResult::Deduplicated<SemIR::PackExpansionPattern>(
+      resolver,
+      {.type_id =
+           resolver.local_types().GetTypeIdForTypeConstantId(type_const_id),
+       .subpattern_id = AddLoadedImportRef(resolver, subpattern),
+       .arity_pattern_id = AddLoadedImportRef(resolver, arity_pattern)});
+}
+
+static auto TryResolveTypedInst(ImportRefResolver& resolver,
+                                SemIR::PackType inst) -> ResolveResult {
+  CARBON_CHECK(inst.type_id == SemIR::TypeType::TypeId);
+  auto element_type_inst_id =
+      GetLocalTypeInstId(resolver, inst.element_type_inst_id);
+  auto arity_id = GetLocalConstantInstId(resolver, inst.arity_id);
+  if (resolver.HasNewWork()) {
+    return ResolveResult::Retry();
+  }
+
+  return ResolveResult::Deduplicated<SemIR::PackType>(
+      resolver, {.type_id = SemIR::TypeType::TypeId,
+                 .element_type_inst_id = element_type_inst_id,
+                 .arity_id = arity_id});
+}
+
 static auto TryResolveTypedInst(ImportRefResolver& resolver,
                                 SemIR::ExportDecl inst) -> ResolveResult {
   auto value_id = GetLocalConstantId(resolver, inst.value_id);
@@ -4981,6 +5015,12 @@ static auto TryResolveInstCanonical(ImportRefResolver& resolver,
     case CARBON_KIND(SemIR::OverloadSetValue inst): {
       return TryResolveTypedInst(resolver, inst);
     }
+    case CARBON_KIND(SemIR::PackExpansionPattern inst): {
+      return TryResolveTypedInst(resolver, inst);
+    }
+    case CARBON_KIND(SemIR::PackType inst): {
+      return TryResolveTypedInst(resolver, inst);
+    }
     case CARBON_KIND(SemIR::PartialType inst): {
       return TryResolveTypedInst(resolver, inst);
     }
```

<!-- google-doc-style-resume -->

**toolchain/check/merge.cpp.** A redeclaration's pack expansion pattern is
compared operand by operand and arity by arity.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/merge.cpp
+++ b/toolchain/check/merge.cpp
@@ -335,6 +335,15 @@ static auto CheckRedeclParam(Context& context, bool is_implicit_param,
         }
         break;
       }
+      case CARBON_KIND(SemIR::PackExpansionPattern new_pack_pattern): {
+        auto prev_pack_pattern =
+            prev_param_pattern.As<SemIR::PackExpansionPattern>();
+        pattern_stack.push_back({.prev_id = prev_pack_pattern.subpattern_id,
+                                 .new_id = new_pack_pattern.subpattern_id});
+        pattern_stack.push_back({.prev_id = prev_pack_pattern.arity_pattern_id,
+                                 .new_id = new_pack_pattern.arity_pattern_id});
+        break;
+      }
       case CARBON_KIND(SemIR::DefaultValuePattern new_default_value_pattern): {
         auto prev_default_value_pattern =
             prev_param_pattern.As<SemIR::DefaultValuePattern>();
```

<!-- google-doc-style-resume -->

**toolchain/check/handle_pattern_list.cpp.** A default value after a pack
expansion pattern, or on one, is a `semantics TODO` (D-VA-5, W-215; amended
2026-10-14, review fold: A-m1); the pack expansion pattern's handler
diagnoses a default before it.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_pattern_list.cpp
+++ b/toolchain/check/handle_pattern_list.cpp
@@ -355,6 +355,21 @@ auto HandleParseNode(Context& context, Parse::DefaultValuePatternId node_id)
   // specified. We pop that so we can issue the DefaultValuePattern in its
   // place.
   auto pattern_inst_id = context.node_stack().PopPattern();
+
+  // Fork (VA-1, D-VA-5): the variadics design does not say how default values
+  // beside a pack bind, or what a default for a pack would be. A default
+  // before the pack is diagnosed by the pack expansion pattern.
+  auto is_pack_expansion = [&](SemIR::InstId inst_id) {
+    return context.insts().Is<SemIR::PackExpansionPattern>(inst_id);
+  };
+  if (is_pack_expansion(pattern_inst_id) ||
+      llvm::any_of(
+          context.param_and_arg_refs_stack().PeekCurrentBlockContents(),
+          is_pack_expansion)) {
+    return context.TODO(node_id,
+                        "default value in a parameter list with a pack "
+                        "expansion pattern");
+  }
   auto pattern_type_id = context.insts().Get(pattern_inst_id).type_id();
   auto scrutinee_type_id =
       SemIR::ExtractScrutineeType(context.sem_ir(), pattern_type_id);
```

<!-- google-doc-style-resume -->

**toolchain/check/handle_function.cpp.** The default-value walker and the
`unused` walker recurse into a pack expansion pattern's operand, so `...
unused each n: i64` on a declaration gets `UnusedModifierWithoutDefinition`
like any parameter (split `fail_unused_without_definition`; amended
2026-10-14, review fold: A-m3).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_function.cpp
+++ b/toolchain/check/handle_function.cpp
@@ -985,6 +985,13 @@ static auto CheckDefaults(Context& context, SemIR::Function& function)
                 wrapper_binding_pattern.subpattern_id);
             break;
           }
+          // Fork (VA-1): a pack expansion pattern's operand is its element.
+          case CARBON_KIND(
+              SemIR::PackExpansionPattern pack_expansion_pattern): {
+            state->pattern_work_list.push_back(
+                pack_expansion_pattern.subpattern_id);
+            break;
+          }
           case CARBON_KIND(SemIR::TuplePattern tuple_pattern): {
             auto elements =
                 context.inst_blocks().Get(tuple_pattern.elements_id);
@@ -1279,6 +1286,12 @@ static auto CheckUnusedBindingsInPattern(Context& context,
         work_list.push_back(default_value_pattern.subpattern_id);
         break;
       }
+      // Fork (VA-1): the each-name binding of a pack is checked like any
+      // other binding.
+      case CARBON_KIND(SemIR::PackExpansionPattern pack_expansion_pattern): {
+        work_list.push_back(pack_expansion_pattern.subpattern_id);
+        break;
+      }
       default:
         break;
     }
```

<!-- google-doc-style-resume -->

**toolchain/check/cpp/export.cpp.** Exporting a variadic function to C++ is a
`semantics TODO`, ahead of `ExportGenericBindings`, whose `CARBON_CHECK` would
abort on the arity binding's special name (§0.3 item 6, W-228; amended
2026-10-14, review fold: A-M1).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/cpp/export.cpp
+++ b/toolchain/check/cpp/export.cpp
@@ -1597,6 +1597,18 @@ static auto ExportFunctionToCpp(Context& context, SemIR::LocId loc_id,
       context.TODO(loc_id, "support exporting generic member functions");
       return nullptr;
     }
+    // Fork (VA-1, D-VA-5): a variadic function would be a function template
+    // over a parameter pack; its deduced arity has no name to export.
+    if (llvm::any_of(
+            context.inst_blocks().GetOrEmpty(
+                target->function.param_patterns_id),
+            [&](SemIR::InstId pattern_id) {
+              return context.insts().Is<SemIR::PackExpansionPattern>(
+                  context.constant_values().GetConstantInstId(pattern_id));
+            })) {
+      context.TODO(loc_id, "exporting a variadic function to C++");
+      return nullptr;
+    }
     return ExportGenericFunctionToCpp(context, loc_id, *target);
   }

```

<!-- google-doc-style-resume -->

**toolchain/lower/type.cpp.** In C4 a pack type is never lowered as a run-time
type, because nothing in C4 lowers; C5 replaces the stub.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/type.cpp
+++ b/toolchain/lower/type.cpp
@@ -732,6 +732,11 @@ static auto BuildTypeForInst(FileContext& context, SemIR::PointerType /*inst*/)
           nullptr};
 }

+static auto BuildTypeForInst(FileContext& /*context*/, SemIR::PackType /*inst*/)
+    -> LoweredTypes {
+  CARBON_FATAL("Unexpected pack type in lowering");
+}
+
 static auto BuildTypeForInst(FileContext& /*context*/,
                              SemIR::PatternType /*inst*/) -> LoweredTypes {
   CARBON_FATAL("Unexpected pattern type in lowering");
```

<!-- google-doc-style-resume -->

**toolchain/check/handle_pack_expansion.cpp** (whole file at rr-c4). The whole
file replaces C3's (upstream's three handlers, two of them replaced in place and
`HandlePrefixOperatorExpand` kept as upstream's TODO, and C3's four stubs). A
`...` decides its kind from the node it follows (a list start for an element,
anything else for a statement); a pattern `...` adds the deduced arity binding,
after the TODOs for an interface function and for a default value before it;
a statement or expression `...` opens a block for its body. An each-name is the
pack's element at the pack index (`PackElement`). The end of an expansion
checks D-VA-6's restrictions and DR-17 and builds the instruction; an
expression expansion converts its result to a value inside its body and is
added where the argument is written (amended 2026-10-14, review fold: A-B1,
A-B2, A-m1, B-M1, B-M2, and A-m3's walker audit). Its pack type is required
complete with `RequireCompleteType`, so that every specific's is complete for
lowering (D-VA-7; amended 2026-10-14, review fold: RR-M1).

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/context.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/pattern.h"
#include "toolchain/check/type.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

using PackExpansionScope = Context::PackExpansionScope;

// Returns the kind of pack expansion that a `...` starts. Each pattern-list
// and expression-list comma moves the preceding element off the node stack
// (`ParamAndArgRefsStack::ApplyComma`), so a `...` that begins a list element
// directly follows the list's start node; any other `...` begins a statement.
static auto GetPackExpansionKind(Context& context) -> PackExpansionScope::Kind {
  switch (context.node_stack().PeekNodeKind()) {
    case Parse::NodeKind::ExplicitParamListStart:
    case Parse::NodeKind::ImplicitParamListStart:
    case Parse::NodeKind::TuplePatternStart:
      return PackExpansionScope::Kind::Pattern;
    case Parse::NodeKind::CallExprStart:
    case Parse::NodeKind::TupleLiteralStart:
      return PackExpansionScope::Kind::Expr;
    default:
      return PackExpansionScope::Kind::Statement;
  }
}

auto HandleParseNode(Context& context, Parse::PackExpansionStartId node_id)
    -> bool {
  // "A pack expansion or `...expand` expression cannot contain another pack
  // expansion" (docs/design/variadics.md, "Pack expansions").
  if (!context.pack_expansion_stack().empty()) {
    CARBON_DIAGNOSTIC(NestedPackExpansion, Error,
                      "pack expansion cannot contain another pack expansion");
    CARBON_DIAGNOSTIC(EnclosingPackExpansion, Note,
                      "enclosing pack expansion is here");
    context.emitter()
        .Build(node_id, NestedPackExpansion)
        .Note(context.pack_expansion_stack().back().start_node_id,
              EnclosingPackExpansion)
        .Emit();
    return false;
  }

  PackExpansionScope scope = {.kind = GetPackExpansionKind(context),
                              .start_node_id = node_id};
  switch (scope.kind) {
    case PackExpansionScope::Kind::Pattern: {
      // Fork (VA-1, D-VA-5): a pack expansion pattern is supported directly
      // in a function's explicit parameter list.
      if (!context.node_stack().PeekIs(
              Parse::NodeKind::ExplicitParamListStart) ||
          context.full_pattern_stack().CurrentKind() !=
              FullPatternStack::Kind::ExplicitParamList) {
        return context.TODO(node_id,
                            "pack expansion pattern outside an explicit "
                            "parameter list");
      }
      // Fork (VA-1, D-VA-5): an interface's function is matched by the
      // functions of its impls, and the thunk that adapts one to the other
      // does not clone a pack expansion pattern yet.
      if (context.name_scopes().InstIs<SemIR::InterfaceWithSelfDecl>(
              context.decl_name_stack().PeekParentScopeId())) {
        return context.TODO(node_id,
                            "pack expansion pattern in an interface function");
      }
      // "A tuple pattern can contain no more than one subpattern of the form
      // `...` operand" (docs/design/variadics.md, "Pattern matching"). Each
      // comma has moved the list's earlier elements to the refs stack.
      for (auto param_id :
           context.param_and_arg_refs_stack().PeekCurrentBlockContents()) {
        // Fork (VA-1, D-VA-5): the design does not say how default values
        // beside a pack bind; handle_pattern_list.cpp diagnoses a default
        // after the pack, or on it.
        if (context.insts().Is<SemIR::DefaultValuePattern>(param_id)) {
          return context.TODO(node_id,
                              "default value in a parameter list with a pack "
                              "expansion pattern");
        }
        if (context.insts().Is<SemIR::PackExpansionPattern>(param_id)) {
          CARBON_DIAGNOSTIC(MultiplePackExpansionPatterns, Error,
                            "parameter list can contain at most one pack "
                            "expansion pattern");
          CARBON_DIAGNOSTIC(PreviousPackExpansionPattern, Note,
                            "previous pack expansion pattern is here");
          context.emitter()
              .Build(node_id, MultiplePackExpansionPatterns)
              .Note(param_id, PreviousPackExpansionPattern)
              .Emit();
          return false;
        }
      }
      // The arity of the pack is a deduced parameter of the enclosing full
      // pattern (docs/design/variadics.md, "Explicit deduced arities").
      auto arity_type_id =
          GetSingletonType(context, SemIR::IntLiteralType::TypeInstId);
      auto entity_name_id = AddBindingEntityName(
          context, SemIR::NameId::PackArity, SemIR::TypeInstId::None,
          SemIR::InstId::None, /*is_unused=*/false, BindingPhase::Symbolic);
      auto arity = AddBindingPattern(
          context, node_id, SemIR::ExprRegionId::None, arity_type_id,
          {.kind = SemIR::SymbolicBindingPattern::Kind,
           .type_id = GetPatternType(context, arity_type_id),
           .entity_name_id = entity_name_id,
           .subpattern_id = SemIR::InstId::None});
      scope.arity_pattern_id = arity.pattern_id;
      scope.arity_binding_id = arity.bind_id;
      break;
    }
    case PackExpansionScope::Kind::Statement:
    case PackExpansionScope::Kind::Expr: {
      // The body is checked once, into its own block, which lowering runs
      // once per element (docs/design/variadics.md, "Iterative typechecking
      // of pack expansions" and "Execution Semantics").
      context.inst_block_stack().Push();
      scope.body_block_id = context.inst_block_stack().PeekOrAdd();
      scope.cleanup_depth = context.scope_stack().cleanup_scope_depth();
      break;
    }
  }
  context.pack_expansion_stack().push_back(scope);
  context.node_stack().Push(node_id);
  return true;
}

// Marks the innermost statement or expression pack expansion as invalid after
// one of its each-names is diagnosed, so that its end is not diagnosed again.
static auto InvalidateInnermostPackExpansion(Context& context) -> void {
  auto& stack = context.pack_expansion_stack();
  if (!stack.empty() &&
      stack.back().kind != PackExpansionScope::Kind::Pattern) {
    stack.back().arity_id = SemIR::ErrorInst::InstId;
  }
}

// Finishes the body of a statement or expression pack expansion, popping its
// block. Returns `nullopt` after diagnosing a body that this slice does not
// support, which ends checking, or `InstBlockId::None` after diagnosing an
// invalid body, which the caller recovers from.
static auto FinishPackExpansionBody(Context& context, Parse::NodeId node_id,
                                    const PackExpansionScope& scope)
    -> std::optional<SemIR::InstBlockId> {
  // Fork (VA-1, D-VA-6): the body runs as one straight-line block per element,
  // so control flow inside it, which would add blocks to the function, is not
  // supported yet.
  if (!context.inst_block_stack().is_current_block_reachable() ||
      context.inst_block_stack().PeekOrAdd() != scope.body_block_id) {
    context.TODO(node_id, "control flow in a pack expansion");
    return std::nullopt;
  }
  // Fork (VA-1, D-VA-6): a temporary in an expansion element would need to be
  // destroyed once per element.
  if (context.scope_stack().cleanup_scope_depth() != scope.cleanup_depth) {
    context.TODO(node_id, "pack expansion element that needs a cleanup");
    return std::nullopt;
  }
  auto body_block_id = context.inst_block_stack().Pop();
  if (scope.arity_id == SemIR::ErrorInst::InstId) {
    // An each-name in the body was diagnosed.
    return SemIR::InstBlockId::None;
  }

  // "If an expansion contains no each-names, it must be a pattern, or an
  // expression in the type position of a binding pattern"
  // (docs/design/variadics.md, "Pack expansions").
  if (!scope.arity_id.has_value()) {
    CARBON_DIAGNOSTIC(PackExpansionWithoutEachName, Error,
                      "pack expansion does not use any each-name");
    context.emitter().Emit(scope.start_node_id, PackExpansionWithoutEachName);
    return SemIR::InstBlockId::None;
  }
  return body_block_id;
}

auto HandleParseNode(Context& context, Parse::PackExpansionStatementId node_id)
    -> bool {
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::PackExpansionStart>();
  auto scope = context.pack_expansion_stack().pop_back_val();
  CARBON_CHECK(scope.kind == PackExpansionScope::Kind::Statement);

  // Fork (VA-1, D-VA-6): only an expression statement can be expanded yet. A
  // declaration in the body would introduce a name, and so storage, per
  // element, and the other statements are control flow.
  auto statement = context.parse_tree_and_subtrees()
                       .ExtractAs<Parse::PackExpansionStatement>(node_id);
  if (!statement || context.parse_tree().node_kind(statement->body) !=
                        Parse::NodeKind::ExprStatement) {
    return context.TODO(node_id,
                        "pack expansion of a statement other than an "
                        "expression statement");
  }

  auto body_block_id = FinishPackExpansionBody(context, node_id, scope);
  if (!body_block_id) {
    return false;
  }
  if (!body_block_id->has_value()) {
    return true;
  }
  AddInst<SemIR::PackExpansionStatement>(
      context, node_id,
      {.arity_id = scope.arity_id, .body_block_id = *body_block_id});
  return true;
}

auto HandleParseNode(Context& context, Parse::PackExpansionExprId node_id)
    -> bool {
  auto result_id = context.node_stack().PopExpr();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::PackExpansionStart>();
  auto& stack = context.pack_expansion_stack();
  CARBON_CHECK(stack.back().kind == PackExpansionScope::Kind::Expr);

  // Each iteration's element is a value: a pack holds its elements' values
  // (fork VA-1, D-VA-3). The conversion is part of the body, so that an
  // element whose value needs a temporary gets one per iteration.
  if (context.insts().Get(result_id).type_id() != SemIR::ErrorInst::TypeId) {
    result_id = ConvertToValueExpr(context, result_id);
  }
  auto scope = stack.pop_back_val();

  auto body_block_id = FinishPackExpansionBody(context, node_id, scope);
  if (!body_block_id) {
    return false;
  }
  auto result_type_id = context.insts().Get(result_id).type_id();
  if (!body_block_id->has_value() ||
      result_type_id == SemIR::ErrorInst::TypeId) {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // "The type of a pack expansion expression or pattern is `...B`, where `B`
  // is the type of its body" (docs/design/variadics.md, "Typing and shaping
  // rules"): a pack of the body's type, with the arity of its each-names.
  auto pack_type_id = GetPackType(
      context, context.types().GetTypeInstId(result_type_id), scope.arity_id);
  // Lowering reads the pack type's value representation in every specific, so
  // each specific's pack type must be complete, even when nothing else requires
  // it, as when the call converts the elements to another type. For a symbolic
  // type, `RequireCompleteType` records that requirement in the generic (fork
  // VA-1, D-VA-7). The element type is complete, so the pack type is too, and
  // no diagnostic context is needed here.
  bool complete = RequireCompleteType(context, pack_type_id, node_id,
                                      [](auto& /*builder*/) {});
  CARBON_CHECK(complete, "Expected {0} to be a complete type",
               context.types().GetAsInst(pack_type_id));

  // "`...` in a tuple literal behaves like a series of comma-separated tuple
  // elements" (docs/design/variadics.md, "Pack expansion expressions and
  // statements"), so the expansion is evaluated here, where it is written,
  // before the arguments that follow it (fork VA-1, D-VA-4).
  context.node_stack().Push(node_id, AddInst<SemIR::PackExpansionExpr>(
                                         context, node_id,
                                         {.type_id = pack_type_id,
                                          .body_block_id = *body_block_id,
                                          .result_id = result_id}));
  return true;
}

auto HandleParseNode(Context& context, Parse::PackExpansionPatternId node_id)
    -> bool {
  auto subpattern_id = context.node_stack().PopPattern();
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::PackExpansionStart>();
  auto scope = context.pack_expansion_stack().pop_back_val();
  CARBON_CHECK(scope.kind == PackExpansionScope::Kind::Pattern);

  if (subpattern_id == SemIR::ErrorInst::InstId) {
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }
  // Fork (VA-1, D-VA-5): the operand of a pack expansion pattern is a single
  // each-name binding, such as `... each x: i64`.
  if (scope.each_binding_pattern_id != subpattern_id) {
    return context.TODO(node_id,
                        "pack expansion pattern whose operand is not an "
                        "each-name binding");
  }

  // The scrutinee of the pattern is the run of arguments that it matches, of
  // type `«E; N»` for the element type `E` and the deduced arity `N`
  // (docs/design/variadics.md, "Explicit deduced arities").
  auto pack_type_id =
      GetPackType(context, scope.element_type_inst_id, scope.arity_binding_id);
  context.node_stack().Push(
      node_id, AddInst<SemIR::PackExpansionPattern>(
                   context, node_id,
                   {.type_id = GetPatternType(context, pack_type_id),
                    .subpattern_id = subpattern_id,
                    .arity_pattern_id = scope.arity_pattern_id}));
  return true;
}

auto HandleParseNode(Context& context, Parse::EachBindingNameId node_id)
    -> bool {
  // The enclosing binding pattern handles the each-name.
  context.node_stack().Push(node_id);
  return true;
}

auto HandleParseNode(Context& context, Parse::EachNameExprId node_id) -> bool {
  auto [name_node_id, name_id] = context.node_stack().PopNameWithNodeId();
  auto lookup = LookupUnqualifiedName(context, name_node_id, name_id);
  auto pack_id = lookup.scope_result.target_inst_id();
  if (pack_id == SemIR::ErrorInst::InstId) {
    InvalidateInnermostPackExpansion(context);
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // "An each-name consists of the keyword `each` followed by the name of a
  // pack, and can only occur inside a pack expansion" (docs/design/
  // variadics.md, "Packs and each-names").
  auto arity = context.pack_binding_arities().Lookup(pack_id);
  if (!arity) {
    CARBON_DIAGNOSTIC(EachNameNotPack, Error, "`each {0}` does not name a pack",
                      SemIR::NameId);
    context.emitter().Emit(node_id, EachNameNotPack, name_id);
    InvalidateInnermostPackExpansion(context);
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }
  auto& stack = context.pack_expansion_stack();
  if (stack.empty() || stack.back().kind == PackExpansionScope::Kind::Pattern) {
    CARBON_DIAGNOSTIC(EachNameOutsidePackExpansion, Error,
                      "each-name `each {0}` is not inside a pack expansion",
                      SemIR::NameId);
    context.emitter().Emit(node_id, EachNameOutsidePackExpansion, name_id);
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }

  // "All each-names in a given expansion must refer to packs with the same
  // arity" (docs/design/variadics.md, "Pack expansions"). Fork (VA-1,
  // D-VA-5): a function has at most one pack, so this only fails for an
  // each-name of an enclosing function's pack.
  auto& scope = stack.back();
  if (!scope.arity_id.has_value()) {
    scope.arity_id = arity.value();
  } else if (scope.arity_id != arity.value() &&
             scope.arity_id != SemIR::ErrorInst::InstId) {
    return context.TODO(node_id,
                        "pack expansion over packs of different arities");
  }

  // On each iteration, `each x` is the element of the pack `x` at the pack
  // index (docs/design/variadics.md, "Execution Semantics": "An each-name
  // evaluates to the `$I`th value of the pack it refers to"), a value of the
  // pack's element type.
  auto pack_ref_id =
      BuildNameRef(context, node_id, name_id, pack_id, lookup.specific_id);
  auto pack_type = context.types().TryGetAs<SemIR::PackType>(
      context.insts().Get(pack_ref_id).type_id());
  if (!pack_type) {
    // The pack's element type was invalid, which was diagnosed.
    InvalidateInnermostPackExpansion(context);
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }
  auto index_id = AddInst<SemIR::PackIndex>(
      context, node_id,
      {.type_id =
           GetSingletonType(context, SemIR::IntLiteralType::TypeInstId)});
  context.node_stack().Push(
      node_id, AddInst<SemIR::PackElement>(
                   context, node_id,
                   {.type_id = context.types().GetTypeIdForTypeInstId(
                        pack_type->element_type_inst_id),
                    .pack_id = pack_ref_id,
                    .index_id = index_id}));
  return true;
}

auto HandleParseNode(Context& context, Parse::PrefixOperatorExpandId node_id)
    -> bool {
  return context.TODO(node_id, "HandlePrefixOperatorExpand");
}

}  // namespace Carbon::Check
```

<!-- google-doc-style-resume -->

**toolchain/lower/handle_pack_expansion.cpp** (whole file at rr-c4). C4's
lowering stubs, one per lowered kind of D-VA-7: the dispatch needs a handler
per lowered kind, and nothing in C4 reaches them (C4 has no lower golden and no
program).

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/lower/function_context.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Lower {

// TODO: Lower pack expansions (fork VA-1).

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackElement /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackElement");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackExpansionExpr /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackExpansionExpr");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackExpansionStatement /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackExpansionStatement");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackIndex /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackIndex");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackLiteral /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackLiteral");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackValue /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackValue");
}

}  // namespace Carbon::Lower
```

<!-- google-doc-style-resume -->

### §2.5 Commit C5: lowering (`rr-c5`)

Lowering per D-VA-9. Invariant: outside an expansion body, `pack_index_` is
empty and `SetLocal` records nothing extra; no existing handler changes. Rev 1's
`ArrayIndex` change in toolchain/lower/handle.cpp is gone, because `each x` is a
`PackElement` (amended 2026-10-14, review fold: A-B2 / B-M1); the pack type's
LLVM type replaces C4's fatal stub in toolchain/lower/type.cpp.

**toolchain/lower/function_context.h.** The loop entry point with its
`finish_iteration` callback, the current pack index, and the locals an
iteration set (amended 2026-10-14, review fold: A-B1 / B-M2).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/function_context.h
+++ b/toolchain/lower/function_context.h
@@ -9,6 +9,7 @@

 #include "common/map.h"
 #include "common/raw_string_ostream.h"
+#include "llvm/ADT/STLFunctionalExtras.h"
 #include "llvm/ADT/StringRef.h"
 #include "llvm/IR/IRBuilder.h"
 #include "llvm/IR/LLVMContext.h"
@@ -105,6 +106,25 @@ class FunctionContext {
   // Builds LLVM IR for the specified instruction.
   auto LowerInst(SemIR::InstId inst_id) -> void;

+  // Builds LLVM IR for the body of a pack expansion of `arity` elements, once
+  // per element, with the iteration's `PackIndex` lowered to the element's
+  // index (docs/design/variadics.md, "Execution Semantics": the body is
+  // executed N times, with `$I` ranging from 0 to N - 1). `finish_iteration`,
+  // if given, is called with the index after each iteration's body, while the
+  // values that the iteration computed are still available; they are
+  // discarded before the next iteration.
+  auto LowerPackExpansionBody(
+      uint64_t arity, SemIR::InstBlockId body_block_id,
+      llvm::function_ref<auto(uint64_t index)->void> finish_iteration = {})
+      -> void;
+
+  // Returns the pack index of the current iteration of the pack expansion
+  // being lowered.
+  auto pack_index() const -> uint64_t {
+    CARBON_CHECK(pack_index_, "Pack index used outside a pack expansion");
+    return *pack_index_;
+  }
+
   // Returns a phi node corresponding to the block argument of the given basic
   // block.
   auto GetBlockArg(SemIR::InstBlockId block_id, TypeInFile type)
@@ -141,6 +161,9 @@ class FunctionContext {
     bool added = locals_.Insert(inst_id, value).is_inserted();
     CARBON_CHECK(added, "Duplicate local insert: {0} {1}", inst_id,
                  sem_ir().insts().Get(inst_id));
+    if (pack_index_) {
+      pack_iteration_locals_.push_back(inst_id);
+    }
   }

   // Returns whether a lowered value has been set for the given instruction.
@@ -429,6 +452,12 @@ class FunctionContext {

   // Maps a function's SemIR::File instructions to lowered values.
   Map<SemIR::InstId, llvm::Value*> locals_;
+
+  // While lowering the body of a pack expansion, the index of the current
+  // element, and the instructions given a value in `locals_` during the
+  // current iteration.
+  std::optional<uint64_t> pack_index_;
+  llvm::SmallVector<SemIR::InstId> pack_iteration_locals_;
 };

 namespace Internal {
```

<!-- google-doc-style-resume -->

**toolchain/lower/function_context.cpp.** The loop: fingerprint the arity, then
for each index lower the body, call `finish_iteration`, and erase the
iteration's locals.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/function_context.cpp
+++ b/toolchain/lower/function_context.cpp
@@ -89,6 +89,29 @@ auto FunctionContext::LowerBlockContents(SemIR::InstBlockId block_id) -> void {
   }
 }

+auto FunctionContext::LowerPackExpansionBody(
+    uint64_t arity, SemIR::InstBlockId body_block_id,
+    llvm::function_ref<auto(uint64_t index)->void> finish_iteration) -> void {
+  // "A pack expansion [...] cannot contain another pack expansion"
+  // (docs/design/variadics.md, "Pack expansions"); check diagnoses one.
+  CARBON_CHECK(!pack_index_, "Nested pack expansion in lowering");
+  // The arity is specific-dependent: two specifics whose bodies run a different
+  // number of iterations must not be coalesced.
+  AddIntToCurrentFingerprint(arity);
+  for (auto index : llvm::seq(arity)) {
+    pack_index_ = index;
+    LowerBlockContents(body_block_id);
+    if (finish_iteration) {
+      finish_iteration(index);
+    }
+    for (auto inst_id : pack_iteration_locals_) {
+      locals_.Erase(inst_id);
+    }
+    pack_iteration_locals_.clear();
+  }
+  pack_index_ = std::nullopt;
+}
+
 // Handles typed instructions for LowerInst. Many instructions lower using
 // HandleInst, but others are unsupported or have trivial lowering.
 //
```

<!-- google-doc-style-resume -->

**toolchain/lower/type.cpp** (in C5). A pack type `«E; N»` is `[N x E]`; the
storage of a pack value has the pack type of its elements' value
representations, lowered the same way (amended 2026-10-14, review fold: A-B2
/ B-M1).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/type.cpp
+++ b/toolchain/lower/type.cpp
@@ -732,9 +732,18 @@ static auto BuildTypeForInst(FileContext& context, SemIR::PointerType /*inst*/)
           nullptr};
 }

-static auto BuildTypeForInst(FileContext& /*context*/, SemIR::PackType /*inst*/)
+// Fork (VA-1, D-VA-3): a pack type `«E; N»` is laid out as `N` objects of type
+// `E`. A value of a pack type is the address of a pack of its elements' value
+// representations, whose type is lowered the same way.
+static auto BuildTypeForInst(FileContext& context, SemIR::PackType inst)
     -> LoweredTypes {
-  CARBON_FATAL("Unexpected pack type in lowering");
+  auto arity = context.sem_ir().GetZExtIntValue(inst.arity_id);
+  CARBON_CHECK(arity, "Lowering pack type of unknown arity");
+  return {llvm::ArrayType::get(
+              context.GetType(context.sem_ir().types().GetTypeIdForTypeInstId(
+                  inst.element_type_inst_id)),
+              *arity),
+          nullptr};
 }

 static auto BuildTypeForInst(FileContext& /*context*/,
```

<!-- google-doc-style-resume -->

**toolchain/lower/handle_pack_expansion.cpp** (whole file at rr-c5). Replaces
C4's stubs: a statement reads its arity in the specific and runs its body that
many times; an expansion expression allocates its pack's storage, runs its
body that many times where it stands and stores each iteration's result; a
`PackValue` stores its elements; a `PackElement` loads one; a `PackIndex` is
the iteration's constant (amended 2026-10-14, review fold: A-B1, A-B2, B-M1,
B-M2).

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Type.h"
#include "toolchain/lower/function_context.h"
#include "toolchain/sem_ir/generic.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Lower {

// Fork (VA-1): a pack expansion's body is lowered once per element, the
// compile-time loop of docs/design/variadics.md, "Execution Semantics", run at
// monomorphization: each specific of a variadic function knows its arity. A
// value of a pack type is the address of its elements' value representations
// (D-VA-3), which `PackValue` and `PackExpansionExpr` write where they are
// evaluated and `PackElement` reads.

// Returns the address of the element at `index` of the pack value `storage`,
// of type `pack_type`.
static auto GetPackElementAddr(FunctionContext& context,
                               FunctionContext::TypeInFile pack_type,
                               llvm::Value* storage, llvm::Value* index)
    -> llvm::Value* {
  auto value_repr = context.GetValueRepr(pack_type);
  CARBON_CHECK(value_repr.repr.kind == SemIR::ValueRepr::Pointer,
               "Pack value not passed by address");
  auto* zero = llvm::ConstantInt::get(index->getType(), 0);
  return context.builder().CreateInBoundsGEP(
      context.GetType(value_repr.type().GetPointeeType()), storage,
      {zero, index}, "pack.elem");
}

// Allocates the storage of a value of the pack type `pack_type`.
static auto CreatePackStorage(FunctionContext& context,
                              FunctionContext::TypeInFile pack_type)
    -> llvm::Value* {
  return context.CreateAlloca(
      context.GetValueRepr(pack_type).type().GetPointeeType(), "pack");
}

// Stores the value of `value_id` as the element at `index` of the pack value
// `storage`, of type `pack_type`.
static auto StorePackElement(FunctionContext& context,
                             FunctionContext::TypeInFile pack_type,
                             llvm::Value* storage, uint64_t index,
                             SemIR::InstId value_id) -> void {
  context.StoreObject(
      context.GetValueRepr(context.GetTypeIdOfInst(value_id)).type(),
      context.GetValue(value_id),
      GetPackElementAddr(context, pack_type, storage,
                         context.builder().getInt64(index)));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackElement inst) -> void {
  auto* addr = GetPackElementAddr(
      context, context.GetTypeIdOfInst(inst.pack_id),
      context.GetValue(inst.pack_id), context.GetValue(inst.index_id));
  context.SetLocal(
      inst_id,
      context.LoadObject(
          context.GetValueRepr(context.GetTypeIdOfInst(inst_id)).type(), addr,
          "pack.elem.load"));
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackExpansionExpr inst) -> void {
  // The pack has one element per iteration, each the iteration's result.
  auto pack_type = context.GetTypeIdOfInst(inst_id);
  auto arity = pack_type.file->GetZExtIntValue(
      pack_type.file->types()
          .GetAs<SemIR::PackType>(pack_type.type_id)
          .arity_id);
  CARBON_CHECK(arity, "Pack of unknown arity");
  auto* storage = CreatePackStorage(context, pack_type);
  context.LowerPackExpansionBody(
      *arity, inst.body_block_id, [&](uint64_t index) {
        StorePackElement(context, pack_type, storage, index, inst.result_id);
      });
  context.SetLocal(inst_id, storage);
}

auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
                SemIR::PackExpansionStatement inst) -> void {
  auto [arity_ir, arity_const_id] = GetConstantValueInSpecific(
      context.specific_sem_ir(), context.specific_id(), context.sem_ir(),
      inst.arity_id);
  CARBON_CHECK(arity_const_id.is_concrete(), "Pack arity {0} in {1}",
               inst.arity_id, context.specific_id());
  auto arity = arity_ir->GetZExtIntValue(
      arity_ir->constant_values().GetInstId(arity_const_id));
  CARBON_CHECK(arity, "Pack arity {0} is not an integer", inst.arity_id);
  context.LowerPackExpansionBody(*arity, inst.body_block_id);
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackIndex /*inst*/) -> void {
  context.SetLocal(inst_id, llvm::ConstantInt::get(
                                llvm::Type::getInt64Ty(context.llvm_context()),
                                context.pack_index()));
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackLiteral /*inst*/) -> void {
  // A PackLiteral is always converted to a PackValue, element by element.
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackValue inst) -> void {
  auto pack_type = context.GetTypeIdOfInst(inst_id);
  auto* storage = CreatePackStorage(context, pack_type);
  for (auto [index, element_id] :
       llvm::enumerate(context.sem_ir().inst_blocks().Get(inst.elements_id))) {
    StorePackElement(context, pack_type, storage, index, element_id);
  }
  context.SetLocal(inst_id, storage);
}

}  // namespace Carbon::Lower
```

<!-- google-doc-style-resume -->

### §2.6 Golden sources (AUTOUPDATE, no CHECK lines; R15, R16(a))

Fourteen new files, every one with `// AUTOUPDATE` and its TIP lines and no
CHECK line; the check and lower files include the primitives prelude, as
upstream's variadics golden does, except two: fail_todo_cleanup.carbon
includes the destroy prelude, whose `Core.Destroy` makes a class temporary
need a cleanup, as toolchain/lower/testdata/var/param.carbon uses it, and
fail_todo_export.carbon includes the int prelude and imports `Cpp`, as
toolchain/check/testdata/interop/cpp/function/export/generic.carbon does
(amended 2026-10-14, review fold: A-M1, B-m3). One upstream golden's source
changes too (its first split's name, D-VA-12). A split's name starts with
`fail_` exactly when it is expected to produce an error, and with
`fail_todo_` when that error is a `semantics TODO` (§4 predicts each).

**Sources of record** (amended 2026-10-14, implementation-review fold:
VA1-IR2-m1). Where the tree and this section differ, the tree's golden sources
are the record, and each difference is a fix commit's (§3, "As implemented").
Fix 1 (32ce7d58b) gives the seven callees that the splits
`deduced_element_type`, `generic_caller`, `forward_fixed`, `forward_generic`,
`forward_converted`, `fail_element_conversion` and
`fail_todo_conversion_cleanup` only declared an empty body with `unused`
bindings, because a variadic function is generic through its arity and check
requires a definition of each specific a file uses
(MissingGenericFunctionDefinition, toolchain/check/check_unit.cpp); it moves
`self` out of the implicit parameter lists of `method` and
`fail_variadic_virtual` (SelfInImplicitParamList,
toolchain/check/handle_binding_pattern.cpp); and it makes
`fail_todo_tuple_literal` declare `(i64, i64)` instead of `auto` and
`fail_todo_tuple_operand` write `(each a: i64,)`, a tuple pattern rather than a
parenthesized binding. Fix 2 (0a6367a39) renames the lower golden's five
package-scope `Run` functions that return a value or take parameters to `Call`,
because such a `Run` in the `Main` package is the entry point
(toolchain/sem_ir/entry_point.cpp), and gives `arg_order`'s `Digits` a body
returning `first`. Fix 3 (0ee9f2d1b) adds the seven splits of the implementation
review fold record to fail_call.carbon, fail_each_name.carbon and
fail_pack_expansion.carbon, and marks the packs of `fail_todo_overload_member`
and `fail_without_each_name` `unused`. No change weakens a split: each still
reaches the line §4 gives it.

**toolchain/lex/testdata/each.carbon** (commit C3).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lex/testdata/each.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lex/testdata/each.carbon

each eachx r#each ...each
```

<!-- google-doc-style-resume -->

**toolchain/parse/testdata/variadics/each.carbon** (commit C3).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/variadics/each.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/variadics/each.carbon

// --- binding.carbon

fn F(... each x: i32);

// --- binding_modifiers.carbon

fn F[... template each T: type](... ref each x: i32, ... var each y: i32);

// --- expr.carbon

fn F() {
  ... G(each x, each x.y, each x.f(), -each x);
}

// --- fail_each_without_name.carbon

fn F() {
  G(each);
}

// --- fail_each_binding_without_name.carbon

fn F(... each _: i32);
```

<!-- google-doc-style-resume -->

**toolchain/parse/testdata/variadics/pack_expansion_expr.carbon** (commit C3).
Rev 2 adds the split `fail_todo_and_or` (amended 2026-10-14, review fold:
B-m3).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/variadics/pack_expansion_expr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/variadics/pack_expansion_expr.carbon

// --- call_args.carbon

fn F() {
  G(... each x);
  G(1, ... each x, 2);
}

// --- tuple_literal.carbon

fn F() {
  let t: auto = (... each x);
  let u: auto = (1, ... each x);
  let v: auto = (... each x, ... each y,);
}

// --- expand.carbon

fn F() {
  G(...expand t);
}

// --- fail_missing_operand.carbon

fn F() {
  G(...);
}

// --- fail_todo_and_or.carbon

fn F() {
  let b: bool = ...and G(each x);
  let c: bool = ...or G(each x);
}
```

<!-- google-doc-style-resume -->

**toolchain/parse/testdata/variadics/pack_expansion_pattern.carbon** (commit
C3).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/parse/testdata/variadics/pack_expansion_pattern.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/parse/testdata/variadics/pack_expansion_pattern.carbon

// --- param.carbon

fn F(... each x: i32);
fn G(a: i32, ... each b: i32, c: i32);

// --- implicit.carbon

fn F[... each T: type](... each x: each T);

// --- tuple_pattern.carbon

fn F() {
  let (a: i32, ... each b: i32) = (1, 2);
}
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/pack_expansion.carbon** (commit C4;
upstream's golden). Its first split is renamed (D-VA-12); F4 refills its
CHECK lines, which name the split (amended 2026-10-14, review fold: B-m4).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/testdata/variadics/pack_expansion.carbon
+++ b/toolchain/check/testdata/variadics/pack_expansion.carbon
@@ -10,7 +10,7 @@
 // TIP: To dump output, run:
 // TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/pack_expansion.carbon

-// --- fail_todo_pack_expansion_statement.carbon
+// --- fail_pack_expansion_without_each_name.carbon
 library "[[@TEST_NAME]]";

 fn F() {
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/each_param.carbon** (commit C4). Rev 2
adds the splits `class_element` (a class without `Copy`) and
`generic_caller` (a generic caller passing a `U` twice) (amended 2026-10-14,
review fold: A-B2 / B-M1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/each_param.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/each_param.carbon

// --- statement.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

//@dump-sem-ir-begin
fn ForEach(... each n: i64) {
  ... Consume(each n);
}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  ForEach(1, 2, 3);
  ForEach();
  //@dump-sem-ir-end
}

// --- fixed_params.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn Middle(first: i64, ... each mid: i64, last: i64) {
  Consume(first);
  ... Consume(each mid);
  Consume(last);
}

fn Call() {
  //@dump-sem-ir-begin
  Middle(1, 2);
  Middle(1, 2, 3, 4);
  //@dump-sem-ir-end
}

// --- deduced_element_type.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](x: T);

//@dump-sem-ir-begin
fn ForEach[T: type](first: T, ... each next: T) {
  Consume(first);
  ... Consume(each next);
}
//@dump-sem-ir-end

fn Call() {
  //@dump-sem-ir-begin
  ForEach(1 as i64, 2 as i64, 3 as i64);
  ForEach(true);
  //@dump-sem-ir-end
}

// --- redecl.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach(... each n: i64);

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

// --- method.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

class C {
  fn ForEach[self: Self](... each n: i64) {
    ... Consume(each n);
  }
}

fn Call(c: C) {
  //@dump-sem-ir-begin
  c.ForEach(1, 2);
  //@dump-sem-ir-end
}

// --- class_element.carbon
library "[[@TEST_NAME]]";

class C {
  var a: i64;
}

fn Consume(c: C);

//@dump-sem-ir-begin
fn ForEach(... each c: C) {
  ... Consume(each c);
}
//@dump-sem-ir-end

fn Call(c: C, d: C) {
  //@dump-sem-ir-begin
  ForEach(c, d);
  //@dump-sem-ir-end
}

// --- generic_caller.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](x: T);

fn ForEach[T: type](... each x: T) {
  ... Consume(each x);
}

//@dump-sem-ir-begin
fn Twice[U: type](a: U) {
  ForEach(a, a);
}
//@dump-sem-ir-end
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/forward.carbon** (commit C4). Rev 2 adds
the splits `forward_generic` (forwarding a pack of `T`) and
`forward_converted` (an element conversion at the call) (amended 2026-10-14,
review fold: A-B1, B-M1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/forward.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/forward.carbon

// --- forward.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

//@dump-sem-ir-begin
fn Forward(... each m: i64) {
  ForEach(... each m);
}
//@dump-sem-ir-end

fn Call() {
  Forward(1, 2);
}

// --- forward_expression.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);
fn Double(x: i64) -> i64;

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

//@dump-sem-ir-begin
fn ForwardDoubled(... each m: i64) {
  ForEach(... Double(each m));
}
//@dump-sem-ir-end

// --- forward_fixed.carbon
library "[[@TEST_NAME]]";

fn Middle(first: i64, ... each mid: i64, last: i64);

//@dump-sem-ir-begin
fn Outer(... each x: i64) {
  Middle(0, ... each x, 9);
}
//@dump-sem-ir-end

// --- forward_generic.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](x: T);

fn ForEach[T: type](... each x: T) {
  ... Consume(each x);
}

//@dump-sem-ir-begin
fn Forward[T: type](... each x: T) {
  ForEach(... each x);
}
//@dump-sem-ir-end

// --- forward_converted.carbon
library "[[@TEST_NAME]]";

class Wrap {
  var n: i64;
}

impl Wrap as Core.ImplicitAs(i64) {
  fn Convert(self) -> i64 { return self.n; }
}

fn ForEach(... each n: i64);

//@dump-sem-ir-begin
fn Unwrap(... each w: Wrap) {
  ForEach(... each w);
}
//@dump-sem-ir-end
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/import.carbon** (commit C4).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/import.carbon

// --- lib.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn ForEach(... each n: i64) {
  ... Consume(each n);
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Call() {
  //@dump-sem-ir-begin
  ForEach(1, 2);
  //@dump-sem-ir-end
}
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/fail_call.carbon** (commit C4).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_call.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_call.carbon

// --- fail_too_few_args.carbon
library "[[@TEST_NAME]]";

fn Middle(first: i64, ... each mid: i64, last: i64);

fn F() {
  Middle(1);
}

// --- fail_expansion_for_singular_param.carbon
library "[[@TEST_NAME]]";

fn Head(first: i64, ... each rest: i64);

fn F(... each n: i64) {
  Head(... each n);
}

// --- fail_expansion_without_pack_param.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  Consume(... each n);
}

// --- fail_element_conversion.carbon
library "[[@TEST_NAME]]";

class C {}

fn ForEach(... each n: i64);

fn F() {
  ForEach(1, {} as C);
}
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/fail_each_name.carbon** (commit C4). Rev
2 moves `fail_pack_name_without_each` to fail_todo_slice.carbon (A-m2) and adds
`fail_unused_without_definition` (A-m3) (amended 2026-10-14, review fold:
A-m2, A-m3).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_each_name.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_each_name.carbon

// --- fail_each_name_not_pack.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(x: i64) {
  ... Consume(each x);
}

// --- fail_each_name_outside_expansion.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  Consume(each n);
}

// --- fail_each_binding_outside_expansion.carbon
library "[[@TEST_NAME]]";

fn F(each n: i64) {}

// --- fail_binding_without_each.carbon
library "[[@TEST_NAME]]";

fn F(... n: i64) {}

// --- fail_unused_without_definition.carbon
library "[[@TEST_NAME]]";

fn F(... unused each n: i64);
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/fail_pack_expansion.carbon** (commit C4).
Rev 3 adds the split `fail_variadic_virtual`, which pins the `GenericVirtual`
guard that keeps a variadic virtual function away from `ClonePattern` (§2.4's
walker audit; amended 2026-10-14, review fold: RR-m2).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_pack_expansion.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_pack_expansion.carbon

// --- fail_nested.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  ... ... Consume(each n);
}

// --- fail_without_each_name.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  ... Consume(1);
}

// --- fail_two_pack_patterns.carbon
library "[[@TEST_NAME]]";

fn F(... each a: i64, ... each b: i64);

// --- fail_variadic_virtual.carbon
library "[[@TEST_NAME]]";

base class B {
  virtual fn F[self: Self](... each n: i64);
}
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/fail_todo_slice.carbon** (commit C4). Rev
2 adds `fail_todo_pack_name_without_each`, the three default-value splits,
`fail_todo_interface_function` and `fail_todo_conversion_cleanup` (amended
2026-10-14, review fold: A-m1, A-m2, A-m3, A-B1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_slice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_slice.carbon

// --- fail_todo_generic_pack.carbon
library "[[@TEST_NAME]]";

fn F[... each T: type](... each x: each T);

// --- fail_todo_tuple_pattern.carbon
library "[[@TEST_NAME]]";

fn F() {
  let (... each x: i64) = ();
}

// --- fail_todo_statement_kind.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64) {
  ... var x: i64 = each n;
}

// --- fail_todo_control_flow.carbon
library "[[@TEST_NAME]]";

fn Consume(x: bool);

fn F(... each b: bool) {
  ... Consume(each b and true);
}

// --- fail_todo_tuple_literal.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64) {
  let unused t: auto = (... each n);
}

// --- fail_todo_merged_segments.carbon
library "[[@TEST_NAME]]";

fn ForEach(... each n: i64);

fn F(... each n: i64) {
  ForEach(0, ... each n);
}

// --- fail_todo_ref_pack.carbon
library "[[@TEST_NAME]]";

fn F(... ref each n: i64);

// --- fail_todo_two_each_names.carbon
library "[[@TEST_NAME]]";

fn F(... (each a: i64, each b: i64));

// --- fail_todo_tuple_operand.carbon
library "[[@TEST_NAME]]";

fn F(... (each a: i64));

// --- fail_todo_overload_member.carbon
library "[[@TEST_NAME]]";

overload fn G(unused b: bool) {}
overload fn G(... each n: i64) {}

fn F() {
  G(1, 2);
}

// --- fail_todo_overload_pack_arg.carbon
library "[[@TEST_NAME]]";

overload fn G(unused x: i64) {}
overload fn G(unused b: bool) {}

fn F(... each n: i64) {
  G(... each n);
}

// --- fail_todo_template_dependent_call.carbon
library "[[@TEST_NAME]]";

fn F[template T: type](t: T, ... each n: i64) {
  t.G(... each n);
}

// --- fail_todo_pack_name_without_each.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  Consume(n);
}

// --- fail_todo_default_after_pack.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64, last: i64 = 7);

// --- fail_todo_default_before_pack.carbon
library "[[@TEST_NAME]]";

fn F(first: i64 = 7, ... each n: i64);

// --- fail_todo_default_on_pack.carbon
library "[[@TEST_NAME]]";

fn F(... each n: i64 = 1);

// --- fail_todo_interface_function.carbon
library "[[@TEST_NAME]]";

interface I {
  fn F(... each n: i64);
}

// --- fail_todo_conversion_cleanup.carbon
library "[[@TEST_NAME]]";

class C {
  impl as Core.Destroy {
    fn Op(ref self);
  }
}

class D {}

impl D as Core.ImplicitAs(C) {
  fn Convert(self) -> C;
}

fn ForEach(... each c: C);

fn F(... each d: D) {
  ForEach(... each d);
}
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/fail_todo_cleanup.carbon** (commit C4;
new in rev 2: amended 2026-10-14, review fold: B-m3).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/destroy.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_cleanup.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_cleanup.carbon

// --- fail_todo_cleanup_statement.carbon
library "[[@TEST_NAME]]";

class C {
  impl as Core.Destroy {
    fn Op(ref self);
  }

  fn Make(c: Self) -> Self;
}

fn Consume(c: C);

fn F(... each c: C) {
  ... Consume(C.Make(each c));
}

// --- fail_todo_cleanup_argument.carbon
library "[[@TEST_NAME]]";

class C {
  impl as Core.Destroy {
    fn Op(ref self);
  }

  fn Make(c: Self) -> Self;
}

fn ForEach(... each c: C);

fn F(... each c: C) {
  ForEach(... C.Make(each c));
}
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/fail_todo_export.carbon** (commit C4; new
in rev 2: amended 2026-10-14, review fold: A-M1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/variadics/fail_todo_export.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/variadics/fail_todo_export.carbon

// --- fail_todo_export_variadic.carbon
library "[[@TEST_NAME]]";
import Cpp;

fn Consume(unused x: i32) {}

fn Sum(... each n: i32) {
  ... Consume(each n);
}

inline Cpp '''
void CallSum() {
  Carbon::Sum(1, 2);
}
''';
```

<!-- google-doc-style-resume -->

**toolchain/lower/testdata/variadics/pack_expansion.carbon** (commit C5). Rev 2
adds the splits `class_element` (a pack of class values, stored as addresses),
`arg_order` (an expansion argument between two calls) and `lib` and `use` (an
imported variadic function lowered at two arities) (amended 2026-10-14,
review fold: A-B1, A-B2, A-m4). Rev 3 adds `forward_converted_field`: the
argument's pack type, `«Wrap; N»` of a field of each element, is required
complete by nothing but the expansion, and the call converts it to `Sum`'s
`«i64; N»`. The re-review's `ToI32` form needs an `i32` to `i64` conversion,
which the min prelude does not have, so it is in variadics_forward instead
(amended 2026-10-14, review fold: RR-M1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/primitives.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/variadics/pack_expansion.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/variadics/pack_expansion.carbon

// --- sum.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, each n);
  return total;
}

fn SumOfDoubles(... each m: i64) -> i64 {
  return Sum(... Add(each m, each m));
}

fn Run() -> i64 {
  return Add(Add(Sum(1, 2, 3), Sum()), SumOfDoubles(4, 5));
}

// --- generic_element.carbon
library "[[@TEST_NAME]]";

fn Consume[T: type](unused x: T) {}

fn ForEach[T: type](... each x: T) {
  ... Consume(each x);
}

fn Run() {
  ForEach(true, false);
  ForEach(1 as i32);
}

// --- class_element.carbon
library "[[@TEST_NAME]]";

class C {
  var a: i64;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Get(c: C) -> i64 {
  return c.a;
}

fn SumFields(... each c: C) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, Get(each c));
  return total;
}

fn Run(c: C, d: C) -> i64 {
  return SumFields(c, d);
}

// --- arg_order.carbon
library "[[@TEST_NAME]]";

fn P(x: i64) -> i64;

fn Digits(first: i64, ... each mid: i64, last: i64) -> i64;

fn Plain(... each x: i64) -> i64 {
  return Digits(P(1), ... P(each x), P(9));
}

fn Run() -> i64 {
  return Plain(2, 3);
}

// --- forward_converted_field.carbon
library "[[@TEST_NAME]]";

class Wrap {
  var n: i64;
}

impl Wrap as Core.ImplicitAs(i64) {
  fn Convert(self) -> i64 { return self.n; }
}

class Holder {
  var w: Wrap;
}

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, each n);
  return total;
}

fn SumHeld(... each h: Holder) -> i64 {
  return Sum(... each h.w);
}

fn Run(h: Holder, k: Holder) -> i64 {
  return SumHeld(h, k);
}

// --- lib.carbon
library "[[@TEST_NAME]]";

fn Add(a: i64, b: i64) -> i64 = "int.sadd";

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total = Add(total, each n);
  return total;
}

// --- use.carbon
library "[[@TEST_NAME]]";

import library "lib";

fn Run() -> i64 {
  return Add(Sum(1, 2), Sum(3, 4, 5));
}
```

<!-- google-doc-style-resume -->

### §2.7 Conformance programs (bullet "Generics: Definition-checked variadics", R7)

The arbiter's body is uncommented with `as i32` added to its two prints (M-8),
its SKIP line removed and its header rewritten; eight programs are new, the
last three of them rev 2's (amended 2026-10-14, review fold: A-B1, A-B2, B-M1,
B-M2); the README's program table is regenerated by
`runner.py --update-readme-table` (M-14), never edited by hand.

**fork/conformance/programs/generics/variadics_each.carbon.** The un-SKIP.

<!-- google-doc-style-ignore -->

```diff
--- a/fork/conformance/programs/generics/variadics_each.carbon
+++ b/fork/conformance/programs/generics/variadics_each.carbon
@@ -7,31 +7,27 @@
 // EXPECT-STDOUT:
 //   6
 //   0
-// SKIP: DESIGN-ONLY — a complete 964-line accepted design exists (docs/design/variadics.md, proposal p002240) but there is zero implementation: no `...`/`each` tokens exist in toolchain/lex/token_kind.def (verified by grep), so any pack expansion fails at the lexer. Un-SKIP (and uncomment the body) when W6 (definition-checked variadics implementation) lands.
 //
-// Write-tests-first stub. Intended future test: a definition-checked
-// variadic Sum whose parameter list binds a pack (`... each n: i64`) and
-// whose body statement-expands it (`... total += each n;`) — syntax taken
-// directly from the accepted design's pack-expansion forms
-// (docs/design/variadics.md "Basics": `...` in a tuple-literal pattern
-// iteratively matches, `...` in statement context iteratively executes).
-// Called with three arguments and with zero arguments to prove both the
-// n-ary and empty expansions execute.
+// A definition-checked variadic Sum whose parameter list binds a pack
+// (`... each n: i64`) and whose body statement-expands it
+// (`... total += each n;`): the design's own SumInts example
+// (docs/design/variadics.md, "Additional examples"), renamed. Called with
+// three arguments and with zero, so both the n-ary and the empty expansion
+// execute: 1 + 2 + 3 = 6, and the empty sum is the initial 0. The body is
+// the write-tests-first stub's, uncommented; the only change is `as i32` on
+// each printed sum, because Core.Print takes an i32 (core/io.carbon:12) and
+// i64 does not implicitly convert to i32.

 import Core library "io";

-// fn Sum(... each n: i64) -> i64 {
-//   var total: i64 = 0;
-//   ... total += each n;
-//   return total;
-// }
+fn Sum(... each n: i64) -> i64 {
+  var total: i64 = 0;
+  ... total += each n;
+  return total;
+}

 fn Run() -> i32 {
-  // Intended body once the feature lands:
-  //   Core.Print(Sum(1, 2, 3));
-  //   Core.Print(Sum());
-  //   return 0;
-  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
-  // variadics are implemented.
-  return 1;
+  Core.Print(Sum(1, 2, 3) as i32);
+  Core.Print(Sum() as i32);
+  return 0;
 }
```

<!-- google-doc-style-resume -->

**fork/conformance/programs/generics/variadics_fixed_params.carbon** (new).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   12
//   123
//   4321
//
// A pack between two fixed parameters, the shape of the design's
// MiddleVariadic (docs/design/variadics.md, "Additional examples"): the
// first argument matches `first`, the last matches `last`, and the run
// between them is the pack (docs/design/variadics.md, "Pattern matching").
// The body appends one decimal digit per element in order, so the output
// pins the split and the iteration order: Digits(1, 2) has an empty pack,
// 1 then 12; Digits(1, 2, 3) has the pack (2), 1, 12, then 123;
// Digits(4, 3, 2, 1) has the pack (3, 2), 4, 43, 432, then 4321.

import Core library "io";

fn Digits(first: i64, ... each mid: i64, last: i64) -> i64 {
  var total: i64 = first;
  ... total = total * 10 + each mid;
  return total * 10 + last;
}

fn Run() -> i32 {
  Core.Print(Digits(1, 2) as i32);
  Core.Print(Digits(1, 2, 3) as i32);
  Core.Print(Digits(4, 3, 2, 1) as i32);
  return 0;
}
```

<!-- google-doc-style-resume -->

**fork/conformance/programs/generics/variadics_forward.carbon** (new). Rev 3
adds `ToI32`, `Narrowed` and the fifth print, 456: a forward whose elements the
call converts from `i32` to `i64`, so that nothing but the expansion requires
its pack type complete (amended 2026-10-14, review fold: RR-M1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   123
//   246
//   0
//   8
//   456
//
// A variadic function forwards its pack to another with a pack expansion
// argument, `... each d` or `... each d + each d`: "`...` in a tuple
// literal behaves like a series of comma-separated tuple elements"
// (docs/design/variadics.md, "Pack expansion expressions and statements"),
// so Forward(1, 2, 3) calls Digits(1, 2, 3) and Doubled(1, 2, 3) calls
// Digits(2, 4, 6). Digits appends one decimal digit per element in order:
// 123, then 246; Forward() forwards an empty pack, 0; Doubled(4) is
// Digits(8), 8. The callee's arity is deduced from the expansion's at each
// caller specific. Narrowed(4, 5, 6) passes `... ToI32(each d)`, a pack of
// i32 values 4, 5 and 6, which the call converts element by element to
// Digits' i64 ("`...T` is convertible to `...U` if [...] the scalar
// components of `T` are each convertible to all scalar components of `U`",
// docs/design/variadics.md, "Equivalence, equality, and convertibility"):
// Digits(4, 5, 6), 456. No other parameter or argument has the type of
// that pack of i32, so only the expansion requires it to be complete.

import Core library "io";

fn Digits(... each d: i64) -> i64 {
  var total: i64 = 0;
  ... total = total * 10 + each d;
  return total;
}

fn Forward(... each d: i64) -> i64 {
  return Digits(... each d);
}

fn Doubled(... each d: i64) -> i64 {
  return Digits(... each d + each d);
}

fn ToI32(x: i64) -> i32 {
  return x as i32;
}

fn Narrowed(... each d: i64) -> i64 {
  return Digits(... ToI32(each d));
}

fn Run() -> i32 {
  Core.Print(Forward(1, 2, 3) as i32);
  Core.Print(Doubled(1, 2, 3) as i32);
  Core.Print(Forward() as i32);
  Core.Print(Doubled(4) as i32);
  Core.Print(Narrowed(4, 5, 6) as i32);
  return 0;
}
```

<!-- google-doc-style-resume -->

**fork/conformance/programs/generics/variadics_empty_pack.carbon** (new).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   7
//   1
//   2
//   9
//
// A statement expansion with a side effect runs once per element and never
// for an empty pack: "A statement of the form `...` statement is evaluated
// by executing statement N times" (docs/design/variadics.md, "Expressions
// and statements"). PrintAll() prints nothing, so the first line is the 7
// printed between the calls; PrintAll(1, 2) prints 1 then 2 in order; the
// second empty call prints nothing again; Forward() forwards an empty pack
// to PrintAll, which prints nothing, before the closing 9.

import Core library "io";

fn PrintAll(... each n: i32) {
  ... Core.Print(each n);
}

fn Forward(... each n: i32) {
  PrintAll(... each n);
}

fn Run() -> i32 {
  PrintAll();
  Core.Print(7);
  PrintAll(1, 2);
  PrintAll();
  Forward();
  Core.Print(9);
  return 0;
}
```

<!-- google-doc-style-resume -->

**fork/conformance/programs/generics/variadics_expansion_args.carbon** (new).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   19
//   1239
//   15559
//
// A pack expansion argument between two fixed arguments: the call's
// argument list is a tuple literal of three segments, `first`,
// `... each x * 5` and `9`, and the callee's pattern `(first: i64,
// ... each mid: i64, last: i64)` matches the outer segments to the fixed
// parameters and the expansion to the pack (docs/design/variadics.md,
// "Typechecking pattern matches"). Digits appends one decimal digit per
// argument in order.
// Scaled(1) calls Digits(1, 9) for an empty pack: 19. Plain(1, 2, 3) calls
// Digits(1, 2, 3, 9): 1239. Scaled(1, 1, 1, 1) calls Digits(1, 5, 5, 5,
// 9): the leading 1 is `first`, each of the three remaining elements
// becomes 5: 15559.

import Core library "io";

fn Digits(first: i64, ... each mid: i64, last: i64) -> i64 {
  var total: i64 = first;
  ... total = total * 10 + each mid;
  return total * 10 + last;
}

fn Plain(first: i64, ... each x: i64) -> i64 {
  return Digits(first, ... each x, 9);
}

fn Scaled(first: i64, ... each x: i64) -> i64 {
  return Digits(first, ... each x * 5, 9);
}

fn Run() -> i32 {
  Core.Print(Scaled(1) as i32);
  Core.Print(Plain(1, 2, 3) as i32);
  Core.Print(Scaled(1, 1, 1, 1) as i32);
  return 0;
}
```

<!-- google-doc-style-resume -->

**fork/conformance/programs/generics/variadics_sum_diff.carbon** (new).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
//
// Differential pair: variadics_sum_diff.diff.cpp computes the same values
// with C++17 variadic templates and comma folds, which evaluate their
// operands left to right as Carbon's statement expansion executes its body
// once per element in order (docs/design/variadics.md, "Expressions and
// statements"), so C++ is the oracle for every printed line (no
// EXPECT-STDOUT). Horner evaluates a polynomial whose coefficients are the
// pack, which is order-sensitive; SumOfSquares forwards an expansion whose
// body is an expression of the element, `... each n * each n`, to Sum; the
// empty pack runs no iteration on either side.

import Core library "io";

fn Horner(x: i64, ... each c: i64) -> i64 {
  var total: i64 = 0;
  ... total = total * x + each c;
  return total;
}

fn Sum(... each n: i64) -> i64 {
  var total: i64 = 0;
  ... total += each n;
  return total;
}

fn SumOfSquares(... each n: i64) -> i64 {
  return Sum(... each n * each n);
}

fn Run() -> i32 {
  Core.Print(Horner(10, 1, 2, 3) as i32);
  Core.Print(Horner(2, 1, 0, 1, 1) as i32);
  Core.Print(Horner(7) as i32);
  Core.Print(SumOfSquares(1, 2, 3, 4) as i32);
  Core.Print(SumOfSquares() as i32);
  return 0;
}
```

<!-- google-doc-style-resume -->

**fork/conformance/programs/generics/variadics_sum_diff.diff.cpp** (new; R24
excludes it from clangd-tidy).

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of variadics_sum_diff.carbon: each Carbon
// variadic function is a function template over a parameter pack, and each
// statement expansion `... body;` is a comma fold `((body), ...)`, whose
// operands are evaluated left to right. printf("%d\n", ...) mirrors
// Core.Print's lowering exactly (toolchain/lower/handle_call.cpp).

#include <cstdint>
#include <cstdio>

template <typename... C>
static auto Horner(int64_t x, C... c) -> int64_t {
  int64_t total = 0;
  ((total = total * x + static_cast<int64_t>(c)), ...);
  return total;
}

template <typename... N>
static auto Sum(N... n) -> int64_t {
  int64_t total = 0;
  ((total += static_cast<int64_t>(n)), ...);
  return total;
}

template <typename... N>
static auto SumOfSquares(N... n) -> int64_t {
  return Sum(static_cast<int64_t>(n) * static_cast<int64_t>(n)...);
}

auto main() -> int {
  std::printf("%d\n", static_cast<int>(Horner(10, 1, 2, 3)));
  std::printf("%d\n", static_cast<int>(Horner(2, 1, 0, 1, 1)));
  std::printf("%d\n", static_cast<int>(Horner(7)));
  std::printf("%d\n", static_cast<int>(SumOfSquares(1, 2, 3, 4)));
  std::printf("%d\n", static_cast<int>(SumOfSquares()));
  return 0;
}
```

<!-- google-doc-style-resume -->

**fork/conformance/programs/generics/variadics_arg_order.carbon** (new in rev
2: amended 2026-10-14, review fold: A-B1 / B-M2).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//   3
//   9
//   1239
//   1
//   9
//   19
//
// A pack expansion argument is evaluated where it is written: "`...` in a
// tuple literal behaves like a series of comma-separated tuple elements"
// (docs/design/variadics.md, "Pack expansion expressions and statements"),
// and a call's arguments are evaluated in written order
// (docs/design/pattern_matching.md, "Evaluation order"). Echo prints its
// argument and returns it, so Plain(2, 3), which calls
// Digits(Echo(1), ... Echo(each x), Echo(9)), behaves like
// Digits(Echo(1), Echo(2), Echo(3), Echo(9)): it prints 1, 2, 3 and 9 in that
// order, then Digits appends one decimal digit per argument, 1239. Plain()
// has an empty pack: it prints 1 and 9, then 19.

import Core library "io";

fn Echo(x: i64) -> i64 {
  Core.Print(x as i32);
  return x;
}

fn Digits(first: i64, ... each mid: i64, last: i64) -> i64 {
  var total: i64 = first;
  ... total = total * 10 + each mid;
  return total * 10 + last;
}

fn Plain(... each x: i64) -> i64 {
  return Digits(Echo(1), ... Echo(each x), Echo(9));
}

fn Run() -> i32 {
  Core.Print(Plain(2, 3) as i32);
  Core.Print(Plain() as i32);
  return 0;
}
```

<!-- google-doc-style-resume -->

**fork/conformance/programs/generics/variadics_no_copy.carbon** (new in rev
2: amended 2026-10-14, review fold: A-B2 / B-M1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   2
//   3
//   4
//   3
//   4
//
// A pack binds its arguments' values: "the Nth iteration of the pack
// expansion will initialize the Nth element of the named pack from the Nth
// scrutinee" (docs/design/variadics.md, "Pack expansion patterns"), and
// `each p: Plain` is a value binding, which only requires "the matched
// expression to be a value expression" (docs/design/values.md, "Binding
// patterns and local variables with `let` and `var`"), so it performs no
// copy initialization. Plain implements no Core.Copy, so binding it must not
// need one; Loud's Copy prints 100 plus its field, so a copy would print 103
// or 104. PrintPlain(p, q) prints 1 and 2; PrintLoud(l, m) prints 3 and 4 and
// nothing else; ForwardLoud(l, m) passes its pack on with `... each l`, which
// binds the same values again: 3 and 4.

import Core library "io";

class Plain {
  var a: i32;
}

class Loud {
  var a: i32;
}

impl Loud as Core.Copy {
  fn Op(self) -> Self {
    Core.Print(100 + self.a);
    return {.a = self.a};
  }
}

fn PrintPlain(... each p: Plain) {
  ... Core.Print(each p.a);
}

fn PrintLoud(... each l: Loud) {
  ... Core.Print(each l.a);
}

fn ForwardLoud(... each l: Loud) {
  PrintLoud(... each l);
}

fn Run() -> i32 {
  let p: Plain = {.a = 1};
  let q: Plain = {.a = 2};
  PrintPlain(p, q);
  let l: Loud = {.a = 3};
  let m: Loud = {.a = 4};
  PrintLoud(l, m);
  ForwardLoud(l, m);
  return 0;
}
```

<!-- google-doc-style-resume -->

**fork/conformance/programs/generics/variadics_generic_element.carbon** (new
in rev 2: amended 2026-10-14, review fold: B-M1).

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Generics: Definition-checked variadics
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   3
//   2
//   2
//
// A pack whose element type is a deduced parameter: in
// `Count[T: type](... each x: T)` the body is checked once, with `each x` of
// type `T` (docs/design/variadics.md, "Iterative typechecking of pack
// expansions"), and each call deduces `T` and the arity. One returns 1 for
// any value, so Count returns the pack's arity: Count(true, false, true) is
// 3; Forward(7 as i64, 8 as i64) passes its pack on with `... each x`, 2; and
// Count(l, m) deduces `T` as Loud, whose Copy prints 100 plus its field, and
// prints only 2, because binding a pack copies nothing.

import Core library "io";

class Loud {
  var a: i32;
}

impl Loud as Core.Copy {
  fn Op(self) -> Self {
    Core.Print(100 + self.a);
    return {.a = self.a};
  }
}

fn One[T: type](unused x: T) -> i32 {
  return 1;
}

fn Count[T: type](... each x: T) -> i32 {
  var n: i32 = 0;
  ... n += One(each x);
  return n;
}

fn Forward[T: type](... each x: T) -> i32 {
  return Count(... each x);
}

fn Run() -> i32 {
  Core.Print(Count(true, false, true));
  Core.Print(Forward(7 as i64, 8 as i64));
  let l: Loud = {.a = 3};
  let m: Loud = {.a = 4};
  Core.Print(Count(l, m));
  return 0;
}
```

<!-- google-doc-style-resume -->

**fork/conformance/README.md.** The regenerated rows.

<!-- google-doc-style-ignore -->

```diff
--- a/fork/conformance/README.md
+++ b/fork/conformance/README.md
@@ -291,7 +291,15 @@ fails if this table is stale):
 | `generics/templates_dependent_member.carbon` | Generics: Integrated templates | SKIP |
 | `generics/templates_type_param.carbon` | Generics: Integrated templates | run |
 | `generics/templates_value_param.carbon` | Generics: Integrated templates | run |
-| `generics/variadics_each.carbon` | Generics: Definition-checked variadics | SKIP |
+| `generics/variadics_arg_order.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_each.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_empty_pack.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_expansion_args.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_fixed_params.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_forward.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_generic_element.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_no_copy.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_sum_diff.carbon` | Generics: Definition-checked variadics | differential |
 | `interop/cpp_adl_swap_extension_point.carbon` | Functions: C++ interop — open overload sets as extension points (swap etc.) | SKIP |
 | `interop/cpp_atomic_carbon_class_diff.carbon` | C++ interop: threading, atomics, memory model, synchronization | differential |
 | `interop/cpp_atomic_global_counter_diff.carbon` | C++ interop: threading, atomics, memory model, synchronization | differential |
```

<!-- google-doc-style-resume -->

### §2.8 Records (row in commit R; everything else in commit D)

**fork/gap-analysis.md, row 53 (commit R).** Replace the row with:

<!-- google-doc-style-ignore -->

```markdown
| Generics: Definition-checked variadics | PARTIAL | Slice 1 landed by VA-1 (fork/variadics/plan.md; W-013 stays open), EXPECTED, not of record: `...` (upstream's 2ec4bab59, cherry-picked) and `each` lex and parse; a function may take one pack `... each x: T` of one element type in its explicit parameter list, binding its arguments' values without copying them, expand it in expression statements and pass it on as call arguments (`... e`, evaluated where written); the arity is deduced at each call, the body is checked once against the element type, and each arity is lowered as its own specific. generics/variadics_each.carbon and eight more programs PASS in the container run <run>. Not yet (filed at the discharge): packs of several or deduced types (`[... each T: type]`), expansions in tuple literals and tuple patterns outside calls and parameter lists, `...and`/`...or`/`...expand`, declarations and control flow inside expansions, default values beside a pack, variadic interface functions, variadic impls (the tuple `Copy` rewrite), C++ variadic templates. |
```

<!-- google-doc-style-resume -->

`<run>` is §8.4's run (its log path and counts). Commit D replaces it with
§8.8's and replaces "(filed at the discharge)" with "(W-212..W-230)", so that
no id appears in a record before the re-scan of the head (amended 2026-10-14,
review fold: A-B1, A-B2, A-m1, A-m2, A-m3, B-M1, B-M2).

**fork/gap-analysis.md, header (commit R).** In the bold counts at :18,
PARTIAL +1 and DESIGN-ONLY -1 against whatever the header reads on this branch
at commit R (at f67ab650d: `**30 DONE / 21 PARTIAL / 4 MISSING / 1
DESIGN-ONLY**` becomes `**30 DONE / 22 PARTIAL / 4 MISSING / 0
DESIGN-ONLY**`); the parenthetical scoreboard counts are re-quoted from §8.4's
run; and the clause "leaving variadics and the build-system/documentation rows
as the open back half" becomes "leaving variadics beyond its first slice and
the build-system/documentation rows as the open back half". At the merge of
trunk the header is recounted, never merged (the OP-2 rule), and commit D
re-quotes §8.8's counts.

**fork/gap-analysis.md, §W6 (commit D).** After the **Arbiter:** paragraph:

<!-- google-doc-style-ignore -->

```markdown
**Slice 1 (VA-1, fork/variadics/plan.md):** homogeneous value packs in explicit
parameter lists, expression-statement and call-argument expansions, a deduced
arity, the body checked once and lowered per arity; upstream's 2ec4bab59 and
a045da8e6 cherry-picked. Next: W-212 (generic and heterogeneous packs), then
W-213 and W-218 (tuples with pack segments, statement expansions of
declarations), which the design's Zip needs.
```

<!-- google-doc-style-resume -->

**fork/inventory/work-items.json (commit D).** W-013: `evidence` gains
"fork/variadics/plan.md (VA-1, slice 1)" and
"fork/conformance/programs/generics/variadics_each.carbon (PASS, expected)",
and its `fork/conformance/programs/generics/variadics_each.carbon:6` pin
becomes the file without a line; `notes` gains: "VA-1 slice 1 (<date>,
fork/variadics/plan.md): upstream's lex and parse of `...` cherry-picked
(2ec4bab59, a045da8e6); `each` keyword; one pack `... each x: T` of one element
type per function in its explicit parameter list, expression-statement and
call-argument expansions, a deduced `Core.IntLiteral` arity (the design's
explicit deduced arity), definition checking against the element type (the
one-segment case of iterative typechecking), pack values bound without copies,
expansion arguments evaluated where written, lowering per specific. Residues
W-212..W-230. Next slice: W-212, then W-213 and W-218. OV-1's citation above is
now toolchain/check/call.cpp:<n> (:424 at f67ab650d).", where `<n>` is the line
of `GetExplicitArityRange` at the merge commit (amended 2026-10-14,
implementation-review fold: VA1-IR2-m5). The `source` string gains
"Updated <date> by the VA-1 discharge: W-013 notes record slice 1; W-212..W-230
added (the §1.11 residues of fork/variadics/plan.md); W-231 reserved, unused;
ids re-scanned before this commit (<result>)." The nineteen new items, appended
after the
highest existing item (amended 2026-10-14, review fold: B-m5 for every
`blocked_by`, and the findings named in §1.11). Their docs/design/variadics.md
line numbers are the branch's after C2, which the merge commit keeps unless the
merge changes that file, when D re-derives them (amended 2026-10-14,
implementation-review fold: VA1-IR2-m4):

<!-- google-doc-style-ignore -->

```json
[
  {
    "id": "W-212",
    "kind": "missing-feature",
    "title": "VA-1 residue: generic and heterogeneous packs (`[... each T: type]`, `... each x: each T`, `each x: auto`) and multi-segment pack typechecking",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "XL",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md \"Pack expansion patterns\" (:215-221) and \"Iterative typechecking of pack expansions\" (:451-493); DR-4, DR-11, DR-17, DR-24, DR-31, DR-32, DR-40",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_generic_pack` (`semantics TODO: pack expansion pattern outside an explicit parameter list`)"
    ],
    "blocked_by": [],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). The next slice of W-013. Packs whose elements have different types, or a type that is itself a pack, need pack types of several segments, shapes, and segment-by-segment checking; slice 1's pack type has one element type (D-VA-3), which this item generalizes. The indexing interfaces become variadic with it (proposals/p002274-subscript-syntax-and-semantics.md:250-257). Arbiter: the design's StrCat (:252-260). Break condition: StrCat compiles and runs. Follows VA-1 slice 1."
  },
  {
    "id": "W-213",
    "kind": "missing-feature",
    "title": "VA-1 residue: tuples with pack segments (`(... each x)` outside a call's argument list, tuple types `(... each T)`)",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "L",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :109-110, :135-141, :484-491; DR-9, DR-14, DR-33",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_tuple_literal`"
    ],
    "blocked_by": [
      "W-212"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). A tuple literal with an expansion element has a tuple type with a pack segment, which slice 1 does not represent; call argument lists are handled by grouping (D-VA-4). Arbiters: Zip's return type, Apply, TupleConcat. Break condition: `(... each x)` is a value of a tuple type in a variadic function."
  },
  {
    "id": "W-214",
    "kind": "missing-feature",
    "title": "VA-1 residue: pack expansion patterns in tuple patterns outside a function's explicit parameter list",
    "subsystem": "toolchain/check",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :111-112, :207-214; DR-10",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_tuple_pattern`"
    ],
    "blocked_by": [
      "W-213"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). `let (... each x: i64) = t;`, `var` and `match` tuple patterns, and tuple patterns nested inside a parameter list. Break condition: the split's `let` binds a pack."
  },
  {
    "id": "W-215",
    "kind": "missing-feature",
    "title": "VA-1 residue: merging and splitting segments (an expansion argument merged with other arguments, the `Arity` type's `+`, canonical full patterns, default values beside or on a pack)",
    "subsystem": "toolchain/check",
    "size": "L",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :548-677, :700-704, :830-832, :843-973; DR-36, DR-37, DR-39, DR-41",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon splits `fail_todo_merged_segments` (`ForEach(0, ... each n)`), `fail_todo_default_after_pack`, `fail_todo_default_before_pack` and `fail_todo_default_on_pack` (`semantics TODO: default value in a parameter list with a pack expansion pattern`)",
      "fork/variadics/plan.md M-7: a deduced `Core.IntLiteral` array bound has no arithmetic (`array bound is not a constant` for `N + 1`)"
    ],
    "blocked_by": [],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Slice 1 matches the parameters around a pack position by position and accepts as a pack's scrutinee either ordinary arguments or exactly one expansion argument. Break condition: `ForEach(0, ... each n)` deduces arity `N + 1`. Follows VA-1 slice 1."
  },
  {
    "id": "W-216",
    "kind": "missing-feature",
    "title": "VA-1 residue: `...and` and `...or`",
    "subsystem": "toolchain/parse + toolchain/check + toolchain/lower",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :115-116, :308-315, :488-489; DR-12, DR-33",
      "toolchain/parse/testdata/variadics/pack_expansion_expr.carbon split `fail_todo_and_or`: `...and` and `...or` fail to parse (\"expected expression\")"
    ],
    "blocked_by": [],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Short-circuiting folds over a pack; they also need control flow in expansion bodies (W-219). Break condition: Zip's loop condition `...and each iter != each vector.End()` checks. Follows VA-1 slice 1."
  },
  {
    "id": "W-217",
    "kind": "missing-feature",
    "title": "VA-1 residue: `...expand` (check and lowering of upstream's `expand` operator or the design's `...expand` element)",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :121-131, :152-153, :493 (\"TODO: Discuss typechecking `...expand`\"); DR-13, DR-18",
      "upstream's toolchain/check/testdata/variadics/pack_expansion.carbon split `fail_todo_expand` (`HandlePrefixOperatorExpand`), cherry-picked by VA-1 commit C1"
    ],
    "blocked_by": [
      "W-213"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Upstream parses `expand` as a prefix operator anywhere (p002240's \"Generalize expand\" alternative, upstream 2ec4bab59); the design adopts the element form. Follow upstream's choice at the advance. Break condition: `F(...expand MakeArgs())` calls `F` with the tuple's elements."
  },
  {
    "id": "W-218",
    "kind": "missing-feature",
    "title": "VA-1 residue: statement expansions of declarations and compound statements (`... var each iter: auto = ...;`, `... if`, `... while`, `... return`)",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "L",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :108, :305-306; DR-8",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_statement_kind`"
    ],
    "blocked_by": [
      "W-212"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). A declaration in an expansion declares a pack (one name per element); compound statements need blocks inside the per-element body. Arbiters: Zip (:71-83), Min (:264-271). Break condition: Min runs."
  },
  {
    "id": "W-219",
    "kind": "missing-feature",
    "title": "VA-1 residue: control flow inside an expansion body (`and`, `or`, `if` expressions; the type-versus-execution example)",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md \"Type versus execution semantics\" (a045da8e6, :495-528); DR-34",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_control_flow`"
    ],
    "blocked_by": [],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Slice 1 lowers an expansion body as one straight-line block per element (D-VA-6). Break condition: `... Consume(each b and true)` runs with short-circuiting per element. Follows VA-1 slice 1."
  },
  {
    "id": "W-220",
    "kind": "missing-feature",
    "title": "VA-1 residue: per-element cleanups (a temporary needing destruction inside an expansion body)",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "toolchain/check/handle_expr_statement.cpp `HandleParseNode(ExprStatementId)` for a statement expansion's body (split `fail_todo_cleanup_statement`) and toolchain/check/handle_pack_expansion.cpp `FinishPackExpansionBody` for an expression expansion's (split `fail_todo_cleanup_argument`): `semantics TODO: pack expansion element that needs a cleanup`; toolchain/check/testdata/variadics/fail_todo_cleanup.carbon",
      "toolchain/check/convert.cpp `ConvertPackToPack`: `semantics TODO: pack element conversion that needs a cleanup`; fail_todo_slice.carbon split `fail_todo_conversion_cleanup`",
      "fork/variadics/plan.md D-VA-6"
    ],
    "blocked_by": [],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Break condition: an expansion over a call returning a class with a destructor destroys each temporary once. Follows VA-1 slice 1."
  },
  {
    "id": "W-221",
    "kind": "missing-feature",
    "title": "VA-1 residue: each-name bindings that are `ref`, `var` or phase-qualified, and expansion operands that are not one each-name binding",
    "subsystem": "toolchain/check",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :223-235; a045da8e6's `fn G(... (each c: bool, each x: i32))`; DR-25, DR-34",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon splits `fail_todo_ref_pack`, `fail_todo_two_each_names`, `fail_todo_tuple_operand`"
    ],
    "blocked_by": [
      "W-212"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Break condition: the three splits check."
  },
  {
    "id": "W-222",
    "kind": "missing-feature",
    "title": "VA-1 residue: more than one pack (fixed-arity expansions, packs in two parameter lists of one function, the same-arity rule across packs)",
    "subsystem": "toolchain/check",
    "size": "L",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :147-148, :530-546; DR-16, DR-35",
      "toolchain/check/handle_pack_expansion.cpp: `semantics TODO: pack expansion over packs of different arities` (unreachable in slice 1)",
      "proposals/p002687-termination-algorithm-for-impl-selection.md:186-193, :210-215 (keys for variadic argument counts)"
    ],
    "blocked_by": [
      "W-212"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Arbiter: the design's `class C(... each T: type) { fn F[... each U: type](... each t: each T, ... each u: each U); }`. Break condition: it checks."
  },
  {
    "id": "W-223",
    "kind": "missing-feature",
    "title": "VA-1 residue: variadic members of `overload fn` sets and pack expansion arguments to them",
    "subsystem": "toolchain/check",
    "size": "M",
    "bullet": "Functions: function overloading (Carbon-native)",
    "evidence": [
      "toolchain/check/handle_function.cpp `DiagnoseOverloadGates` (gate (iii), at the member's declaration) and toolchain/check/call.cpp `PerformCallToOverloadSet` (at the call): `semantics TODO: variadic member of an overload set`; `GetExplicitArityRange` (:424 at f67ab650d) returns a range for this purpose (OV-1, fork/overload/plan.md §8.5)",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon splits `fail_todo_overload_member`, `fail_todo_overload_pack_arg`"
    ],
    "blocked_by": [],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). The overload probe would group arguments per member (D-VA-4). Break condition: both splits check and select a member. Follows VA-1 slice 1."
  },
  {
    "id": "W-224",
    "kind": "missing-feature",
    "title": "VA-1 residue: pack expansion arguments in template-dependent calls, and packs in templates",
    "subsystem": "toolchain/check",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "toolchain/check/call.cpp `PerformCall`",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_template_dependent_call`"
    ],
    "blocked_by": [],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Break condition: the split's `t.G(... each n)` instantiates. Follows VA-1 slice 1."
  },
  {
    "id": "W-225",
    "kind": "missing-feature",
    "title": "VA-1 residue: variadic impls; the prelude tuple `Copy` as one variadic impl, and tuple `Eq`/`Ordered`",
    "subsystem": "core/prelude + toolchain/check",
    "size": "L",
    "bullet": "Stdlib: tuple/array library parts",
    "evidence": [
      "core/prelude/copy.carbon:49-71 (\"TODO: Implement tuple copy as a variadic generic impl.\", impls for arities 0 to 3)",
      "proposals/p002687-termination-algorithm-for-impl-selection.md:210-215 (termination with variadic types)"
    ],
    "blocked_by": [
      "W-212",
      "W-213"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). `impl forall [... each T: Copy] (... each T) as Copy` needs generic packs and tuple types with pack segments. Break condition: the four hand-written impls are replaced and a 4-tuple copies."
  },
  {
    "id": "W-226",
    "kind": "missing-feature",
    "title": "VA-1 residue: a variadic `Core.Call`",
    "subsystem": "core/prelude + toolchain/check",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "proposals/p002875-functions-function-types-and-function-calls.md:227 (\"`Call` should be variadic\") and :531"
    ],
    "blocked_by": [
      "W-212"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Break condition: `Call` takes a parameter list rather than a tuple."
  },
  {
    "id": "W-227",
    "kind": "missing-feature",
    "title": "VA-1 residue: importing C++ variadic templates (function templates and class templates with parameter packs) and instantiating them on Carbon packs",
    "subsystem": "toolchain/check/cpp",
    "size": "L",
    "bullet": "Generics: C++ interop — importing C++ templates, instantiating on Carbon types",
    "evidence": [
      "toolchain/check/testdata/interop/cpp/function/import/variadic.carbon (a C++ `template<typename ...T>` function today)"
    ],
    "blocked_by": [
      "W-212"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Break condition: a Carbon pack expansion argument calls a C++ variadic function template."
  },
  {
    "id": "W-228",
    "kind": "missing-feature",
    "title": "VA-1 residue: exporting a variadic Carbon function to C++ as a function template over a parameter pack",
    "subsystem": "toolchain/check/cpp",
    "size": "L",
    "bullet": "Generics: C++ interop — exporting Carbon templates/checked generics as C++ templates",
    "evidence": [
      "toolchain/check/cpp/export.cpp `ExportFunctionToCpp`: `semantics TODO: exporting a variadic function to C++`; toolchain/check/testdata/variadics/fail_todo_export.carbon split `fail_todo_export_variadic`",
      "fork/variadics/plan.md §0.3 item 6: without the TODO, the arity binding reaches `CARBON_CHECK(param_ident, ...)` in `ExportGenericBindings` (export.cpp:349 at f67ab650d)"
    ],
    "blocked_by": [
      "W-212"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Break condition: C++ calls an exported Carbon `Sum(... each n: i64)` with any number of arguments."
  },
  {
    "id": "W-229",
    "kind": "missing-feature",
    "title": "VA-1 residue: variadic interface functions (a pack expansion pattern in an interface function, its impls, and the thunks between them)",
    "subsystem": "toolchain/check",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "toolchain/check/handle_pack_expansion.cpp: `semantics TODO: pack expansion pattern in an interface function`; toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_interface_function`",
      "toolchain/check/thunk.cpp `ClonePattern` (:137-182 at f67ab650d) CHECK-fails on a pattern kind it does not clone (:166-170)"
    ],
    "blocked_by": [],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11), from the review fold's audit of pattern walkers. An impl's function adapts to its interface's through a thunk whose parameter patterns are cloned. Follows VA-1 slice 1. Break condition: the split's interface function and an impl of it are called through the interface with three arguments."
  },
  {
    "id": "W-230",
    "kind": "design-needed",
    "title": "VA-1 residue: a pack's name without `each` (operations on the whole sequence)",
    "subsystem": "docs/design + toolchain/check",
    "size": "S",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "proposals/p002240-variadics.md \"Omit each-names\" (:637-645): the bare name stays open for operations on the whole sequence",
      "toolchain/check/handle_name.cpp: `semantics TODO: use of a pack's name without `each``; toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_pack_name_without_each`"
    ],
    "blocked_by": [],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). The design gives a pack's bare name no meaning yet; slice 1 does not decide one (D-VA-11). Follows VA-1 slice 1. Break condition: the design or upstream gives the bare name a meaning or makes it an error, and the TODO becomes that rule."
  }
]
```

<!-- google-doc-style-resume -->

**fork/decision-log.md (commit D).** A new entry immediately above the newest
landed workstream entry at the merge commit, never first under "## Decided"
above "V-1..3" (amended 2026-10-14, review fold: B-M4; ST-1's review fixed the
same placement as its B5). On trunk 3eb7f36f0 the newest landed workstream
entry is "SL-2" (fork/decision-log.md:2863, the first entry after "Full
autonomy and the throughput protocol"); each held PR that lands before VA-1
puts its own entry above that, and VA-1's goes above the newest of them. The
entry, in the log's format (context, options considered, decision, date,
consequences), with its V-3a divergence-risk register:

<!-- google-doc-style-ignore -->

```markdown
### VA-1: definition-checked variadics, slice 1 (<date>)

Context: W-013 (gap row "Generics: Definition-checked variadics", DESIGN-ONLY);
fork/variadics/plan.md, rev 3 after two plan reviews and a focused re-review,
all folded. Every decision auto-adopted under V-2/V-3 (R29(a)) and open to veto.
Options considered (plan §7.2): desugaring the arbiter to a tuple loop (A-1)
and lexing and parsing only (A-2), both rejected as Goodhart; waiting for
upstream (A-3); storing a pack as a tuple (A-4), as rev 1's `array(E, N)`,
which copies every element (A-10), or as one parameter per element (A-13);
checking per specific (A-5); a run-time loop (A-6); re-deriving upstream's
lexer and parser (A-7); a "0.1 limits" design section (A-8); keeping
upstream's split name (A-9); allowing only copyable element types (A-11); a
TODO for an expansion argument followed by another argument (A-12); and a fork
rule (F-018) for a pack's bare name (A-14). Decisions: D-VA-1, upstream's
2ec4bab59 and a045da8e6 cherry-picked as the first two commits with upstream
authorship and messages and no fork trailers. D-VA-2, the slice: one pack of
one element type per function, in its explicit parameter list and not in an
interface, with expression-statement and call-argument expansions. D-VA-3, the
arity is a deduced `Core.IntLiteral` binding and the pack's type `«E; N»`,
whose value holds the elements' values, so binding a pack copies nothing.
D-VA-4, a call groups a pack's arguments into one scrutinee, and an expansion
argument is evaluated where it is written. D-VA-5 and D-VA-6, the slice's
TODOs and straight-line bodies. D-VA-7, eight new SemIR instructions. D-VA-8,
definition checking is the one-segment case of the design's iterative
typechecking. D-VA-9, lowering unrolls each body per specific. D-VA-10, `each`
is a keyword. D-VA-11, a pack's bare name is a semantics TODO. D-VA-12 and
D-VA-13, goldens and programs. D-VA-14, no design-doc edit, no F-018. D-VA-15,
merge position. D-VA-16, commit structure. Consequences: row PARTIAL
(expected, not of record); W-212..W-230 filed, W-231 unused. R6 repair: the
un-SKIP of generics/variadics_each.carbon changed its commented body in one
mechanical way, `as i32` on its two prints, because Core.Print takes an i32
(core/io.carbon:12) and the body printed an i64 (plan M-8); the C5 commit
message discloses the same repair. Implementation (plan §3, "As implemented"):
fix 1 (32ce7d58b) and fix 2 (0a6367a39) came before the implementation reviews
and repaired golden sources that did not check on this tree (plan §2.6, "Sources
of record"), and fix 1 raised D-VA-6's statement cleanup TODO in
toolchain/check/handle_expr_statement.cpp; C4 and fix 1 share one fill and C5
and fix 2 another, against D-VA-16's one fill per commit. Two implementation
reviews, APPROVE-WITH-FIXES each, were folded by fix 3 (0ee9f2d1b, filled by
88b1b5bd2): two crashes (an expansion argument of an incomplete facet type, on
valid code, and a misplaced `self` beside a pack, after its error) and three
diagnostics (the `each _` and `each self` suggestions, the overload gate's TODO
for a variadic member, and a cascade after an invalid element type). Verified on
the merge commit: <§8.8's run>.

_V-3a divergence-risk register entries (reviewed at each upstream merge):_
(i) `each` is a keyword (D-VA-10), which upstream's lexer does not have yet;
if upstream makes it contextual, follow upstream and refill the lex golden.
(ii) The parse node kinds `PackExpansionExpr`, `PackExpansionPattern`,
`EachNameExpr` and `EachBindingName`, three parse states, and `(... x)` as a
tuple sit beside upstream's `PackExpansionStart` and `PackExpansionStatement`;
if upstream adds its own, take upstream's and move VA-1's check handlers onto
them. (iii) A pack's bare name is a semantics TODO (D-VA-11); if upstream gives
it a meaning or makes it an error, follow upstream. (iv) Eight SemIR
instructions (`PackElement`, `PackExpansionExpr`, `PackExpansionPattern`,
`PackExpansionStatement`, `PackIndex`, `PackLiteral`, `PackType`, `PackValue`)
and the special name `<pack arity>`; if upstream models packs differently,
upstream's replace them at the advance and VA-1's goldens are refilled. (v)
Upstream's check golden toolchain/check/testdata/variadics/pack_expansion.carbon
carries VA-1's output and a renamed first split; the advance resolves its
add/add conflict by taking upstream's file and refilling it. (vi) The two
cherry-picks are upstream's commits with upstream's authorship and messages
(an upstream pull-request suffix and an `Assisted-by:` trailer included); if
upstream reverts or reshapes 2ec4bab59 first, revert C1 and re-derive. (vii)
The next advance's four added conflicts (plan M-16) resolve by taking the
fork's side, which holds upstream's lines, except the golden of (v).
Veto-able.
```

<!-- google-doc-style-resume -->

**fork/ORCHESTRATION.md (commit D).** The VA row of the branch table becomes
the first block below, and a dated paragraph, the second block, follows the
newest dated paragraph at the time; `<...>` fields are filled from §8.8's run
and the merge commit (amended 2026-10-14, review fold: B-M4).

<!-- google-doc-style-ignore -->

```markdown
| `claude/carbon-fork-0-1-va` | HELD OPEN as PR <n> — VA-1 definition-checked variadics slice 1 at <head> (W-013 open; W-212..W-230 filed, W-231 unused; F-018 not minted; expected <counts> over <programs>; row 53 PARTIAL expected); merges after OX-1 or DD-1, whichever is later. |
```

```markdown
<date> (<time> UTC): PR <n> (VA-1, claude/carbon-fork-0-1-va, head <head>:
definition-checked variadics, slice 1; upstream's 2ec4bab59 and a045da8e6
cherry-picked as its first two commits with upstream authorship; W-013 stays
open; W-212 to W-230 filed, W-231 of VA-1's reservation unused; F-018 not
minted; expected <counts> over <programs>; row 53 PARTIAL expected) is OPEN
and HELD. Not run: <the not-run list of fork/variadics/plan.md §8.9, as it
stands at the discharge>. Merge order: <the order at the time>.
```

<!-- google-doc-style-resume -->

**fork/conformance/README.md (commit C5).** Only the regenerated program table
(§2.7); no prose changes.

## §3 Commits (one PR, "VA-1: definition-checked variadics, slice 1", R29(b))

**D-VA-16.** Five implementation commits, C1 to C5, each followed, when it
changes or adds goldens, by its own fill commit, then the row commit R and,
after the implementation reviews, the discharge D. Each implementation commit
compiles on its own (M-11 measures C3 and C4 as separate trees, §8.0), and its
gate is judged on the commit plus its fill, the fork's practice since ST-1 (an
implementation commit's new goldens are empty until autoupdate fills them, so
the commit alone is red exactly on those files and its listed refills, and on
nothing else). _Break condition:_ a commit cannot compile without a later
commit's files, which would merge the two. (The prototype's first split failed
exactly this test, in node_stack.h, and was corrected by moving one case label
from C4 to C3; §8.0.)

**Fix commits and the shrink line** (amended 2026-10-14, review fold: B-m8).
VA-1 is about 1.5 times UN-1 or OV-1 in non-test toolchain code (`rr-c5`
against C2: 42 files, 1628 insertions and 41 deletions, rev 2's `fx-c5` 1620;
amended 2026-10-14, review fold: RR-M1; against UN-1's 29
files, +1104/-258, and OV-1's 42 files, +1026/-35) with four times OV-1's two
new instruction kinds, and it has never been built; UN-1 needed two code-fix
commits after its reviews and OV-1 four. The plan therefore budgets three or
four fix commits after the first build and the implementation reviews, each
its own commit with its own fill (never an amend), and names a shrink line for
a build that cannot be made to work in that budget: forwarding and expansion
arguments (`PackExpansionExpr` as a call argument, `ConvertPackToPack`, the
programs variadics_forward, variadics_expansion_args, variadics_arg_order and
variadics_sum_diff, and the generic forward of variadics_generic_element) move
to a residue from the spare W-231 behind a `semantics TODO: pack expansion
argument`, while statement expansions, pack literals at calls, value packs
and the definition check stay. Row 53 still moves to PARTIAL on what remains
(variadics_each, variadics_fixed_params, variadics_empty_pack, variadics_no_copy
and the rest of variadics_generic_element), and the shrink is a plan revision
the reviews see before it lands.

**As implemented** (amended 2026-10-14, implementation-review fold: VA1-IR2-m1).
The branch holds C1 44a5ce6e3 and C2 663a29df6 (F1 was not needed: the four
upstream goldens passed as cherry-picked), C3 e90b4197e, F3 39df20a36, C4
275967b1d, fix 1 32ce7d58b, F4 4888b50c1, C5 57d263799, fix 2 0a6367a39, F5
31d4183cd and R 9a0888ef0, then the implementation-review fold's fix 3
0ee9f2d1b, its fill F6 88b1b5bd2 and the plan commit that records the fold. Fix
1 and fix 2 came after the first builds and before the implementation reviews,
which departs from the letter of the paragraph above: each repairs golden
sources that did not check on this tree (§2.6, "Sources of record"); fix 1 also
raises D-VA-6's statement cleanup TODO in
toolchain/check/handle_expr_statement.cpp, because an expression statement
discards its temporaries' cleanups before its expansion ends, so
`FinishPackExpansionBody` never saw them; and neither has a fill of its own, F4
filling C4 and fix 1 together and F5 filling C5 and fix 2. Fix 3 folds the two
implementation reviews and F6 fills it. Three of the three or four budgeted fix
commits are used, and the shrink line was not needed. The gate measured 1946
after C1 and C2, 1950 after F3, 1959 after F4, 1960 after F5 and 1960 after F6,
and each implementation or fix commit alone was red on exactly the goldens it
adds or changes and nothing else, with no crash: C3 on 4, C4 and fix 1 on 10, C5
on 1 and fix 3 on 4.

0.  **Plan.** Rev 1, "VA-1 plan (rev 1): definition-checked variadics,
    slice 1", rev 2, "VA-1 plan (rev 2): reviews A and B folded, 20
    findings", and this revision, "VA-1 plan (rev 3): focused re-review
    folded, sign-off" (amended 2026-10-14, review fold: RR-M1); each later
    revision is a new commit, each amended sentence
    marked "(amended <date>, review fold: <finding>)".
1.  **C1, cherry-pick 2ec4bab59** (`git cherry-pick -x 2ec4bab59`, resolutions
    §2.1). Author Richard Smith, upstream's message plus `-x`'s line, committer
    `Claude <noreply@anthropic.com>` (`GIT_COMMITTER_NAME=Claude
    GIT_COMMITTER_EMAIL=noreply@anthropic.com`), **no** fork author override
    and **no** fork trailers (D-VA-1). Adds upstream's four goldens with
    upstream's CHECK lines. Expected gate: trunk's 1942 files plus those four,
    all green, if the fork's file_test reproduces upstream's output for them;
    if it does not, the difference is the fork's own behavior and F1 refills
    the files by autoupdate (§7 R-1).
2.  **C2, cherry-pick a045da8e6** (`git cherry-pick -x a045da8e6`, clean).
    Author Geoff Romer, same committer rule, no fork trailers.
3.  **F1, only if C1's gate is red on upstream's goldens.** The output of
    `autoupdate.sh` on the four files, "Autoupdate testdata goldens on the
    container arbiter".
4.  **C3, lex and parse** (§2.3; 17 files, 355 insertions and 36 deletions at
    `fx-c3`). The `Each` keyword, the four new parse node kinds and three new
    states, the binding, expression and list changes, the two parse diagnostics,
    check TODO stubs for the four new nodes and the node stack's classification
    of `EachBindingName` (check needs a handler and an id kind per node kind;
    §8.0 measured the second), the renotation of the fork's remaining `...`
    comments in state.def, and the four new lex and parse goldens. Expected
    gate: red on exactly the four new goldens.
5.  **F3.** Autoupdate of C3's four goldens, to its fixpoint (R26).
6.  **C4, check and SemIR** (§2.4; 39 files, 1855 insertions and 10 deletions at
    `rr-c4`; amended 2026-10-14, review fold: RR-M1, RR-m2). Everything of §1.4
    and the nine check goldens; the lowering of the new instructions is a fatal
    TODO stub in toolchain/lower/handle_pack_expansion.cpp (lowering needs a
    handler per instruction kind), which no golden or program of C4 reaches.
    Expected gate: red on exactly the nine new goldens and the one refill of
    D-VA-12 (amended 2026-10-14, review fold: A-M1, B-m3, B-m4).
7.  **F4.** Autoupdate of those ten files.
8.  **C5, lowering and programs** (§2.5, §2.7; 16 files, 749 insertions and 40
    deletions at `rr-c5`; amended 2026-10-14, review fold: RR-M1). The lowering
    of D-VA-9, the lower golden, the un-SKIP, the eight programs and the
    regenerated README table. Expected gate: red on exactly the lower golden;
    conformance as §5 (amended 2026-10-14, review fold: A-B1, A-B2, A-m4, B-M1,
    B-M2).
9.  **F5.** Autoupdate of the lower golden.
10. **R, the row.** §2.8's row 53 and header change, quoting §8.4's container
    run, stated EXPECTED, not of record; nothing else.
11. **D, discharge**, after two implementation reviews: R29(c) drops to one only
    once hosted verification is green, and GitHub Actions is disabled on the
    fork (decision log, "Weekly upstream merge 2026-10-12"), so it never is
    (amended 2026-10-14, review fold: B-m7). Their folds come in new commits by
    a separate fixer, then the merge of trunk (a merge commit) when VA-1 is next
    in D-VA-15's order, and §8.8's re-verification on the merge commit: the
    records of §2.8 other than the row (ledger, decision log, ORCHESTRATION, W6
    sentence), the id re-scan of the head, and re-quoted counts.

Every commit uses explicit paths (R20, never `git add -A`), runs `SKIP=
fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest uvx
prek run --files <its files>` to a fixpoint first, with R31's heading and
list-item counts before and after for each `.md`, and, except C1 and C2, uses
the author `jmann345 <jerrymannstan@gmail.com>`, the committer `Claude
<noreply@anthropic.com>` and the session's attribution trailers. A problem found
after a commit exists is fixed by a new commit, never by amending (AGENTS.md).
The upstream goldens of C1 are never edited by hand (R16(a)); if the gate needs
them changed, F1 does it by autoupdate. Before the hand-over to the
implementation reviews, and before any push to the PR branch, prek runs over
every file with `--all-files` (`uvx prek run` with the same `SKIP=`) to a
fixpoint, with R31's counts for every `.md` it changes (R25; amended 2026-10-14,
review fold: B-m7).

The messages of the fork's commits, verbatim but for `<...>` fields
(amended 2026-10-14, review fold: B-M4). Each ends, after a blank line, with
the session's attribution trailers, which this plan does not spell out
because a repository file names no model. Fill commits are "Autoupdate
testdata goldens on the container arbiter" with the same ending.

<!-- google-doc-style-ignore -->

```text
VA-1 C3: lex and parse `each`, pack expansion elements and patterns

`each` becomes a keyword (docs/design/variadics.md, "Packs and
each-names"). The parser accepts an each-name in binding patterns and in
expressions, and a `...` element in tuple patterns, parameter lists, tuple
literals and call argument lists, beside upstream's statement form
(cherry-picked in C1). Check gets TODO stubs for the new parse nodes, which
C4 replaces. New goldens: lex each, parse each, pack_expansion_expr and
pack_expansion_pattern, filled by the next commit.

fork/variadics/plan.md §2.3, D-VA-1, D-VA-10.
```

```text
VA-1 C4: check and SemIR for one pack of values per function

A function's explicit parameter list may hold one pack expansion pattern
`... each x: T`. Its arity is a deduced `Core.IntLiteral` and its type the
new pack type `«T; N»`, whose value holds the elements' values, so binding a
pack copies nothing. A call groups the pack's arguments into a pack literal
or one forwarded expansion argument, which is evaluated where it is written.
Bodies are checked once against the element type. Forms outside the slice
are semantics TODOs with goldens; upstream's check golden is refilled by the
next commit and its first split renamed. Lowering is a stub until C5.

fork/variadics/plan.md §2.4, D-VA-2 to D-VA-8, D-VA-11, D-VA-12.
```

```text
VA-1 C5: lower pack expansions per specific; un-SKIP variadics_each

Each specific of a variadic function knows its arity: an expansion's body
is lowered once per element where the expansion stands, and a pack value is
the address of its elements' value representations. The arbiter
fork/conformance/programs/generics/variadics_each.carbon is un-SKIPped with
one mechanical repair to its commented body: its two prints gain `as i32`,
because Core.Print takes an i32 (core/io.carbon:12) and the body printed an
i64, which would not compile with variadics either (fork/variadics/plan.md
M-8; rulebook R6). Eight new programs, the lower golden and the regenerated
README table.

fork/variadics/plan.md §2.5, §2.7, D-VA-9, D-VA-13.
```

```text
VA-1 R: gap row 53 PARTIAL, expected, not of record

Generics: Definition-checked variadics moves DESIGN-ONLY to PARTIAL on the
container run <run> (fork/variadics/plan.md §8.4), expected, not of record;
the header's counts move PARTIAL +1 and DESIGN-ONLY -1.
```

```text
VA-1 discharge: W-013 slice 1 recorded, residues W-212 to W-230 filed

W-013 stays open with slice 1 in its notes; W-212 to W-230 are filed from
fork/variadics/plan.md §1.11 and W-231 stays unused; F-018 is not minted.
The decision-log entry "VA-1" records D-VA-1 to D-VA-16, the options, the
V-3a register and the R6 repair of variadics_each; ORCHESTRATION records the
PR; row 53 and the header are re-quoted from the merge commit's run <run>.
```

<!-- google-doc-style-resume -->

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

Every line below is a prediction from the code of §2 and the diagnostic strings
in it, not a run; columns and SemIR names are the fill's to decide, and a fill
that contradicts a prediction is a finding for the implementation review, never
a reason to edit a golden (R16(a)). Diagnostic texts are the `CARBON_DIAGNOSTIC`
format strings of §2 with their arguments substituted. Rev 3's
`RequireCompleteType` adds a `require_complete_type` of each expansion
argument's pack type to its caller's generic, so the dumps of forward.carbon's
splits show one beside the parameter's; whether the two share an instruction
when the types are equal is the fill's to show (amended 2026-10-14, review
fold: RR-M1).

| File (commit) | Split | Predicted key output |
| --- | --- | --- |
| lex/testdata/periods.carbon (C1, upstream) | (one file) | upstream's CHECK lines, unchanged (§7 R-1) |
| parse/testdata/variadics/expand.carbon (C1, upstream) | 4 splits | upstream's CHECK lines, unchanged; C3 does not alter them, since none of their call arguments starts with `...` and no name is `each` (M-10) |
| parse/testdata/variadics/pack_expansion_statement.carbon (C1, upstream) | 6 splits | as for expand.carbon |
| check/testdata/variadics/pack_expansion.carbon (C1, upstream; split renamed C4, refilled F4) | `fail_pack_expansion_without_each_name` (upstream's `fail_todo_pack_expansion_statement`, renamed; amended 2026-10-14, review fold: B-m4) | C1: `semantics TODO: `HandlePackExpansionStart` [SemanticsTodo]` (upstream's); after C4: `error: pack expansion does not use any each-name [PackExpansionWithoutEachName]` at the `...` |
| (same) | `fail_todo_expand` | unchanged: `semantics TODO: `HandlePrefixOperatorExpand`` |
| lex/testdata/each.carbon (C3) | (one file) | tokens `Each` (`each`), `Identifier` (`eachx`), `Identifier` (`r#each`), `PeriodPeriodPeriod`, `Each` |
| parse/testdata/variadics/each.carbon (C3) | `binding` | `PackExpansionStart '...'`, `EachBindingName 'each'` over `IdentifierNameNotBeforeSignature 'x'`, `LetBindingPattern ':'`, `PackExpansionPattern '...'` |
| (same) | `binding_modifiers` | the `template`, `ref` and `var` wrappers each enclose an `EachBindingName` |
| (same) | `expr` | `EachNameExpr 'each'` as the first operand of `MemberAccessExpr`, of `CallExprStart`'s callee and of `PrefixOperatorMinus` |
| (same) | `fail_each_without_name` | `error: expected identifier after `each` [ExpectedIdentifierAfterEach]` |
| (same) | `fail_each_binding_without_name` | `error: expected identifier after `each` [ExpectedIdentifierAfterEachInBinding]` |
| parse/testdata/variadics/pack_expansion_expr.carbon (C3) | `call_args` | `PackExpansionStart`, `EachNameExpr`, `PackExpansionExpr '...'` between `CallExprStart` and `CallExpr`, with `TupleLiteralComma` around the middle one (call arguments share the tuple literal states) |
| (same) | `tuple_literal` | `TupleLiteralStart`, `PackExpansionStart`, `EachNameExpr`, `PackExpansionExpr`, `TupleLiteral` for `(... each x)`, without a comma |
| (same) | `expand` | `PackExpansionStart`, `PrefixOperatorExpand 'expand'`, `PackExpansionExpr` |
| (same) | `fail_missing_operand` | `error: expected expression [ExpectedExpr]` at `)` |
| (same) | `fail_todo_and_or` (amended 2026-10-14, review fold: B-m3) | `error: expected expression [ExpectedExpr]` at each `...` (`...and` and `...or` are a `...` followed by a keyword; nothing parses them) |
| parse/testdata/variadics/pack_expansion_pattern.carbon (C3) | `param`, `implicit`, `tuple_pattern` | `PackExpansionStart` after `ExplicitParamListStart`, `ImplicitParamListStart` or `TuplePatternStart`, then the binding, then `PackExpansionPattern '...'` |
| check/testdata/variadics/each_param.carbon (C4) | `statement` | `ForEach`'s `fn_decl` with `symbolic_binding_pattern arity`, a `value_binding_pattern n` of pattern type `«i64; %arity»` and a `pack_expansion_pattern`; its body `pack_expansion_statement %arity` whose block holds `pack_index`, `pack_element` and the call; in `Call`, two calls whose argument is a `pack_literal` of 3 and of 0 elements converted to a `pack_value`, and two specifics of `ForEach` (amended 2026-10-14, review fold: A-B2 / B-M1) |
| (same) | `fixed_params` | `Middle(1, 2)`: `pack_literal` of 0 elements; `Middle(1, 2, 3, 4)`: of 2 |
| (same) | `deduced_element_type` | specifics with `T` = `i64`, arity 2, and `T` = `bool`, arity 0 |
| (same) | `redecl` | no diagnostic |
| (same) | `method` | `c.ForEach(1, 2)` with the bound `self` first and a 2-element `pack_literal` |
| (same) | `class_element` (amended 2026-10-14, review fold: A-B2 / B-M1) | no diagnostic: `ForEach(c, d)` passes a `pack_value (%c.ref, %d.ref)` of type `«%C; 2»`, with no `Copy` lookup, although `C` has no `Copy` impl |
| (same) | `generic_caller` (amended 2026-10-14, review fold: B-M1) | no diagnostic: `Twice`'s `ForEach(a, a)` deduces `T` as `%U` and the arity as 2 and passes a `pack_value` of two `%a.ref`, with no `Copy` requirement on `U` |
| check/testdata/variadics/forward.carbon (C4) | `forward` | `ForEach(... each m)`: in `Forward`'s body, a `pack_expansion_expr` of type `«i64; %arity»` before the call, whose block holds `pack_index` and `pack_element`; the call passes it unchanged, the types being equal (amended 2026-10-14, review fold: A-B1 / B-M2) |
| (same) | `forward_expression` | as `forward`, the block calling `Double` |
| (same) | `forward_fixed` | `Middle(0, ... each x, 9)`: the `pack_expansion_expr` between the `0` and the `9` in the block, so evaluated between them; `0` and `9` to the fixed parameters, the expansion to the pack (amended 2026-10-14, review fold: A-B1 / B-M2) |
| (same) | `forward_generic` (amended 2026-10-14, review fold: B-M1) | no diagnostic: `Forward[T: type]`'s `ForEach(... each x)` passes a `pack_expansion_expr` of type `«%T; %arity»` |
| (same) | `forward_converted` (amended 2026-10-14, review fold: A-B1) | `Unwrap`'s `ForEach(... each w)`: the argument's `pack_expansion_expr` of type `«%Wrap; %arity»`, then, at the call, a second `pack_expansion_expr` of type `«%i64; %arity»` whose block holds `pack_index`, `pack_element` and `Wrap`'s `Convert`; `Unwrap`'s generic requires the argument's `«%Wrap; %arity»` complete (`require_complete_type`; amended 2026-10-14, review fold: RR-M1) |
| check/testdata/variadics/import.carbon (C4) | `lib`, `use` | `use.carbon` imports `ForEach` (`pack_expansion_pattern` and `pack_type` through import refs) and calls it with a 2-element `pack_literal` |
| check/testdata/variadics/fail_call.carbon (C4) | `fail_too_few_args` | `error: 1 argument passed to function expecting at least 2 arguments [CallArgCountTooFewForPack]`, note `calling function declared here [InCallToVariadicFunction]` |
| (same) | `fail_expansion_for_singular_param` | `error: pack expansion argument cannot match a parameter that is not a pack expansion [PackExpansionArgForSingularParam]` |
| (same) | `fail_expansion_without_pack_param` | `error: pack expansion argument is not matched by a pack expansion parameter [PackExpansionArgWithoutPackParam]` |
| (same) | `fail_element_conversion` | `error: cannot implicitly convert expression of type `C` to `i64` [ConversionFailure]` at `{} as C` |
| (same) | `fail_self_after_pack` (amended 2026-10-14, implementation-review fold: MAJOR-2, VA1-IR2-M1) | `error: `self` must be the first explicit parameter [SelfNotFirstParam]` at the declaration, and nothing at `c.F(1, 2)`; no crash |
| (same) | `fail_self_in_implicit_list_with_pack` (amended 2026-10-14, implementation-review fold: MAJOR-2, VA1-IR2-M1) | `error: `self` must be declared in the explicit parameter list [SelfInImplicitParamList]` at each declaration, and nothing at either call: no crash and no count of -1 |
| check/testdata/variadics/fail_each_name.carbon (C4) | `fail_each_name_not_pack` | `error: `each x` does not name a pack [EachNameNotPack]`, and nothing for the expansion |
| (same) | `fail_each_name_outside_expansion` | `error: each-name `each n` is not inside a pack expansion [EachNameOutsidePackExpansion]` |
| (same) | `fail_unused_without_definition` (amended 2026-10-14, review fold: A-m3) | `error: `unused` modifier without a definition [UnusedModifierWithoutDefinition]` |
| (same) | `fail_each_binding_outside_expansion` | `error: each-name binding `each n` is not inside a pack expansion pattern [EachBindingOutsidePackExpansion]`, then `warning: binding `n` unused [UnusedBinding]` (the binding stays an ordinary `n`) |
| (same) | `fail_binding_without_each` | `error: binding pattern in a pack expansion must declare an each-name, such as `each n` [PackExpansionBindingWithoutEach]` |
| (same) | `fail_underscore_without_each`, `fail_self_without_each` (amended 2026-10-14, implementation-review fold: MINOR-1) | `error: binding pattern in a pack expansion must declare an each-name, `each` followed by an identifier [PackExpansionBindingNotIdentifier]` at the `_` and at the `self`, which `each` cannot precede |
| (same) | `fail_invalid_element_type` (amended 2026-10-14, implementation-review fold: MINOR-3) | `error: name `Undeclared` not found [NameNotFound]`, and nothing at the calls `F()`, `F(1)` and `F(1, 2)` |
| check/testdata/variadics/fail_pack_expansion.carbon (C4) | `fail_nested` | `error: pack expansion cannot contain another pack expansion [NestedPackExpansion]`, note `enclosing pack expansion is here [EnclosingPackExpansion]` |
| (same) | `fail_without_each_name` | `error: pack expansion does not use any each-name [PackExpansionWithoutEachName]`, and no UnusedBinding warning, its pack being `unused` (amended 2026-10-14, implementation-review fold: MINOR-2, VA1-IR2-m2) |
| (same) | `fail_two_pack_patterns` | `error: parameter list can contain at most one pack expansion pattern [MultiplePackExpansionPatterns]`, note `previous pack expansion pattern is here [PreviousPackExpansionPattern]` |
| (same) | `fail_variadic_virtual` (amended 2026-10-14, review fold: RR-m2) | `error: generic virtual function [GenericVirtual]` at `F`'s declaration (handle_function.cpp:798-802), and nothing else: no thunk is built and nothing crashes |
| (same) | `fail_incomplete_element` (amended 2026-10-14, implementation-review fold: MAJOR-1) | `error: forming a pack of incomplete type `I` [IncompleteTypeInPackExpansion]` at the `...` of `G(... *each p)`, note `interface was forward declared here`, and nothing at the call; no crash |
| (same) | `fail_incomplete_element_after_error` (amended 2026-10-14, implementation-review fold: MAJOR-1) | `error: parameter has incomplete type ... in function definition [IncompleteTypeInFunctionParam]` at `G`'s and at `F`'s pack, then `IncompleteTypeInPackExpansion` at the `...` of `G(... each p)`, each with the forward declaration's note, and nothing at the call; no crash |
| check/testdata/variadics/fail_todo_slice.carbon (C4) | `fail_todo_generic_pack`, `fail_todo_tuple_pattern` | `semantics TODO: `pack expansion pattern outside an explicit parameter list`` |
| (same) | `fail_todo_statement_kind` | `semantics TODO: `pack expansion of a statement other than an expression statement`` |
| (same) | `fail_todo_control_flow` | `semantics TODO: `control flow in a pack expansion`` |
| (same) | `fail_todo_tuple_literal` | `semantics TODO: `pack expansion in a tuple literal outside a call's argument list`` |
| (same) | `fail_todo_merged_segments` | `semantics TODO: `pack expansion argument merged with other arguments for the same pack`` |
| (same) | `fail_todo_ref_pack` | `semantics TODO: `each-name binding that is not a value binding`` |
| (same) | `fail_todo_two_each_names` | `semantics TODO: `pack expansion pattern declaring more than one each-name`` |
| (same) | `fail_todo_tuple_operand` | `semantics TODO: `pack expansion pattern whose operand is not an each-name binding`` |
| (same) | `fail_todo_overload_member` | `semantics TODO: `variadic member of an overload set`` at the declaration's pack pattern (toolchain/check/handle_function.cpp `DiagnoseOverloadGates`, gate (iii)) and again at the call (toolchain/check/call.cpp `PerformCallToOverloadSet`), and no UnusedBinding warning, its pack being `unused` (amended 2026-10-14, implementation-review fold: MINOR-2, VA1-IR2-m2) |
| (same) | `fail_todo_overload_pack_arg` | `semantics TODO: `pack expansion argument in a call to an overload set`` |
| (same) | `fail_todo_template_dependent_call` | `semantics TODO: `pack expansion argument in a template-dependent call`` |
| (same) | `fail_todo_pack_name_without_each` (amended 2026-10-14, review fold: A-m2) | `semantics TODO: `use of a pack's name without `each``` |
| (same) | `fail_todo_default_after_pack`, `fail_todo_default_before_pack`, `fail_todo_default_on_pack` (amended 2026-10-14, review fold: A-m1) | `semantics TODO: `default value in a parameter list with a pack expansion pattern`` |
| (same) | `fail_todo_interface_function` (amended 2026-10-14, review fold: A-m3) | `semantics TODO: `pack expansion pattern in an interface function`` |
| (same) | `fail_todo_conversion_cleanup` (amended 2026-10-14, review fold: A-B1) | `semantics TODO: `pack element conversion that needs a cleanup`` at the expansion argument |
| check/testdata/variadics/fail_todo_cleanup.carbon (C4; amended 2026-10-14, review fold: B-m3) | `fail_todo_cleanup_statement`, `fail_todo_cleanup_argument` | `semantics TODO: `pack expansion element that needs a cleanup`` |
| check/testdata/variadics/fail_todo_export.carbon (C4; amended 2026-10-14, review fold: A-M1) | `fail_todo_export_variadic` | `semantics TODO: `exporting a variadic function to C++``, then the C++ error `no member named 'Sum' in namespace 'Carbon' [CppInteropParseError]`, as for interop/cpp/function/export/generic.carbon's TODO split; no crash |
| lower/testdata/variadics/pack_expansion.carbon (C5) | `sum` | `Sum` lowered three times: the arity-3 specific with three `add` sequences over loads from `getelementptr [3 x i64]` at 0, 1, 2; the arity-0 specific with none; `SumOfDoubles` (arity 2) storing two doubled elements into a `[2 x i64]` alloca and passing its address to the arity-2 `Sum` (amended 2026-10-14, review fold: A-B2 / B-M1) |
| (same) | `generic_element` | `ForEach` lowered for (`bool`, arity 2) and (`i32`, arity 1), each calling its `Consume` specific once per element |
| (same) | `class_element` (amended 2026-10-14, review fold: A-B2 / B-M1) | `Run` (`Call` after fix 2, 0a6367a39; amended 2026-10-14, implementation-review fold: VA1-IR2-m1) stores the addresses of `c` and `d` into a `[2 x ptr]` alloca and passes it; `SumFields` loads each element's address and calls `Get`; no copy |
| (same) | `arg_order` (amended 2026-10-14, review fold: A-B1 / B-M2) | `Plain`'s arity-2 specific calls `P(1)`, then `P` twice, storing each result into a `[2 x i64]` alloca, then `P(9)`, then `Digits` |
| (same) | `forward_converted_field` (amended 2026-10-14, review fold: RR-M1) | `SumHeld`'s arity-2 specific stores the address of each element's `w` field into a `[2 x ptr]` alloca (the argument's `«Wrap; 2»`), then calls `Wrap`'s `Convert` once per element, storing each `i64` into a `[2 x i64]` alloca whose address it passes to `Sum`'s arity-2 specific; the compiler does not crash |
| (same) | `lib`, `use` (amended 2026-10-14, review fold: A-m4) | `use.carbon` lowers `Sum`'s arity-2 and arity-3 specifics from `lib.carbon`'s definition, with two and three `add` sequences |

Totals: 14 new files with 76 splits (the lex file counted as one; 69 before the
implementation-review fold's seven, amended 2026-10-14, implementation-review
fold: MAJOR-1, MAJOR-2, MINOR-1, MINOR-3; rev 2: 67; rev 1: 12 with 49; amended
2026-10-14, review fold: RR-M1, RR-m2), 1 refill (D-VA-12) and 4 upstream files
carried; no other golden changes (§6.1).

The fills' output beyond the rows above, none of it contradicting a row (amended
2026-10-14, implementation-review fold: VA1-IR2-m1, VA1-IR2-m2):
`fail_todo_and_or` also gets `` `let` declarations must end with a `;`
[ExpectedDeclSemi]`` at each `...`, as
toolchain/parse/testdata/var/fail_runtime.carbon shows for an initializer that
cannot start an expression; `fail_element_conversion` adds the notes
MissingImplInMemberAccessInContext and InCallToFunctionParam, and
`fail_todo_conversion_cleanup` adds InCallToFunctionParam; the arity binding
prints as `symbolic_binding_pattern <pack arity>` and a value pack as a
`value_param_pattern` under a `wrapper_binding_pattern`; the lower golden's
`generic_element` lowers its `Run` as `@main`; and, until fix 3,
`fail_todo_overload_member` and `fail_without_each_name` carried an
UnusedBinding warning and the first also the overload gate's TODO for an
`overload fn` with a non-value explicit parameter, which fix 3 replaced with the
slice's own.

## §5 Conformance delta (from the floor of record, 128 PASS / 0 FAIL / 22 SKIP over 150)

| Program | Before | After | Commit |
| --- | --- | --- | --- |
| generics/variadics_each.carbon | SKIP | PASS (6, 0) | C5 |
| generics/variadics_fixed_params.carbon | absent | PASS (12, 123, 4321) | C5 |
| generics/variadics_forward.carbon | absent | PASS (123, 246, 0, 8, 456; amended 2026-10-14, review fold: RR-M1) | C5 |
| generics/variadics_empty_pack.carbon | absent | PASS (7, 1, 2, 9) | C5 |
| generics/variadics_expansion_args.carbon | absent | PASS (19, 1239, 15559) | C5 |
| generics/variadics_sum_diff.carbon | absent | PASS, C++ oracle agrees (123, 11, 0, 30, 0) | C5 |
| generics/variadics_arg_order.carbon | absent | PASS (1, 2, 3, 9, 1239, 1, 9, 19) | C5 |
| generics/variadics_no_copy.carbon | absent | PASS (1, 2, 3, 4, 3, 4) | C5 |
| generics/variadics_generic_element.carbon | absent | PASS (3, 2, 2) | C5 |

VA-1's own delta: PASS +9, SKIP -1, programs +8, so 137 / 0 / 21 over 158
against the floor of record (amended 2026-10-14, review fold: A-B1, A-B2, B-M1,
B-M2; rev 1: +6, -1, +5, 134 / 0 / 21 over 155), and the bullet "Generics:
Definition-checked variadics", SKIP-only today, becomes PASS (48/56 bullets PASS
becomes 49/56). No other program moves: VA-1 changes no prelude file and no
other program, and the lexer and parser changes alter the meaning of no other
existing Carbon source (M-10). The held PRs ahead of VA-1 move the totals before
it lands (PR 54 to 57 each state an expected count of their own), so commit R
and the discharge quote §8.8's run on the merge commit, not this table's
arithmetic.

## §6 Churn and collisions

### §6.1 Golden churn

Existing goldens that change: one, upstream's
toolchain/check/testdata/variadics/pack_expansion.carbon, in C4 (D-VA-12: its
first split renamed and its output refilled; amended 2026-10-14, review fold:
B-m4). Everything else is predicted unchanged, for four measured reasons: no
existing Carbon source uses `...` or `each` (M-10); parse dumps print node kinds
by name, so new kinds renumber nothing visible; SemIR dumps print instruction
kinds by `ir_name` and special names by spelling (raw dumps print
`name(PeriodSelf)`, not an index; toolchain/check/testdata/basics/raw_sem_ir),
so the new `PackArity` special name, inserted alphabetically before
`PackageKeyword`, renumbers nothing visible; and the new diagnostics fire only
on the new syntax. Rev 2's other changes to shared code fire only beside a pack
too: the default-value TODO and the export TODO test for a
`PackExpansionPattern`, the walker cases and the `TryToCompleteClassType` case
match only pack kinds, and stringify's new case prints only a call to a variadic
function (amended 2026-10-14, review fold: A-M1, A-m1, A-m3). Rev 3's
`RequireCompleteType` runs only in the handler of a pack expansion expression,
so it changes no existing golden either (amended 2026-10-14, review fold:
RR-M1). A golden that changes anyway is refilled by the fill commit of the
commit that changed it and listed in the implementation review, with its cause
(§7 R-4).

### §6.2 Collisions (M-15: `git merge-tree` against each branch, conflicts the branch already has with trunk subtracted)

| Branch (head at rev 2's re-measurement, amended 2026-10-14, review fold: B-M1, B-M2 and the fold's new files) | Files shared with VA-1 | New conflicts |
| --- | --- | --- |
| PR 51, claude/carbon-fork-0-1-ua2 (f96fe8a7a) | fork/conformance/README.md | 0 |
| PR 52, claude/carbon-fork-0-1-cmake (ea573f672) | fork/conformance/README.md | 0 |
| PR 53, claude/carbon-fork-0-1-safe (adaae4e35) | none | 0 |
| PR 54, claude/carbon-fork-0-1-ev (cb3ef2e74) | fork/conformance/README.md | 0 |
| PR 55, claude/carbon-fork-0-1-st (21307851a) | fork/conformance/README.md, check/cpp/export.cpp (rev 2's TODO, in `ExportFunctionToCpp`; PR 55's hunks are elsewhere in the file) | 0 |
| PR 56, claude/carbon-fork-0-1-op (379f20f67) | fork/conformance/README.md | 0 |
| SC-1, claude/carbon-fork-0-1-sc (444ccbafe; rev 1 measured 6231d5b42) | README.md and 18 toolchain files: check/call.cpp, context.cpp, context.h, convert.cpp, handle_binding_pattern.cpp, handle_function.cpp, import_ref.cpp, merge.cpp, type.cpp, type.h, type_completion.cpp; diagnostics/kind.def; lower/type.cpp; parse/node_kind.def; sem_ir/inst_kind.def, inst_namer.cpp, stringify.cpp, typed_insts.h | 0 (every hunk auto-merges) |
| PR 57, claude/carbon-fork-0-1-op2 (628273444) | README.md, check/convert.cpp (rev 1 also shared lower/handle.cpp, which rev 2 does not touch) | 0 |
| PR 58, DD-1, claude/carbon-fork-0-1-dd (fcee90d9b; rev 1 measured 6b692aa14) | fork/conformance/README.md | 0 |
| OX-1, claude/carbon-fork-0-1-ox (7d71f02b3, its rev-2 plan only) | none yet; its plan's export.cpp hunks (includes, :1244, an append at the end) are away from VA-1's hunk in `ExportFunctionToCpp` (inserted after :1599), a semantic touch point only: an exported operator impl is never variadic in the slice, because a pack in an interface function is a TODO | 0; re-measured at merge |

The pre-existing conflicts subtracted are fork/ORCHESTRATION.md on cmake, ev,
st, op, sc and dd, which VA-1's implementation does not touch (the same at rev
2's re-measurement, `$F/mt_base_*.txt`). Two collisions were removed while
prototyping, both by the shape of the code rather than by coordination: the
lowering handlers live in a new file, toolchain/lower/handle_pack_expansion.cpp,
because placing them in lower/handle.cpp conflicted with PR 57's hunk there
(measured, `$V/mt_op2.txt`), and kind.def's new kinds sit in their own block.
Rev 2 removes the last shared lowering hunk: lower/handle.cpp is untouched. The
README table conflicts textually whenever two branches add rows and is
regenerated by `runner.py --update-readme-table` at every merge. The risk with
SC-1 is semantic, not textual: SC-1 rewrites parts of call.cpp, convert.cpp and
handle_binding_pattern.cpp that VA-1 calls into, so §8.8 re-runs the whole gate
and conformance on the merge commit, and a VA-1 golden whose SemIR changes there
is refilled, never merged by hand.

**The next upstream advance** (M-16): VA-1 adds four conflicted files to the 71
the advance already has (rev 1 said three; amended 2026-10-14, review fold:
B-m4): handle_pack_expansion.cpp, node_kind.def and typed_nodes.h resolve by
taking the fork's side, which holds upstream's lines, and upstream's check
golden pack_expansion.carbon by taking upstream's file and refilling it; the
cherry-picks themselves add none. Upstream's later
variadics work will collide with VA-1 in handle_pack_expansion.cpp,
typed_nodes.h and the check of call arguments, and that advance takes upstream's
shapes where they differ from VA-1's (the fork's are additions beside
upstream's, not rewrites of them, D-VA-1). Rev 3 changes only files that rev 2
already changes and that exist on no other ref, so the table and these counts
stand (M-25; amended 2026-10-14, review fold: RR-M1, RR-m2).

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1. Upstream's goldens do not match the fork's file_test.** C1 carries
    four goldens whose CHECK lines upstream's toolchain wrote; the fork's
    parser and diagnostics differ from upstream's in places (union, match,
    let-else). Predicted to match, because none of their inputs uses a fork
    construct. Detected by C1's gate; handled by F1 (autoupdate, never a hand
    edit); falsified if F1 is needed, which is then recorded in the landed
    notes.
-   **R-2. Per-iteration lowering leaks state.** `LowerPackExpansionBody`
    erases from `locals_` exactly what an iteration set; a lowering helper that
    caches a value elsewhere (a per-block cache, a constant cache keyed by
    instruction) would hand iteration 2 iteration 1's value. Mitigated by
    D-VA-6 (no new blocks inside a body) and by the programs' order-sensitive
    outputs (12 vs 21, 123 vs 321, 1239 vs 1329): a stale value prints a wrong
    digit. Falsified by any §5 program's output.
-   **R-3. The SemIR verifier and the formatter.** The verifier's new
    expansion scopes and the namer's block scopes are compiled (M-11) but not
    run. Detected by C4's goldens on a build with CARBON_CHECK enabled (the
    carbonbuild fastbuild-like flags, -Og with checks); a verifier rejection is
    a crash in file_test, never a golden diff.
-   **R-4. Unexpected golden churn.** A golden outside §6.1's one refill
    changes (for example through the special-name renumbering or a hash-order
    dependency). Detected by each fill's diff; any such file is listed with its
    cause in the implementation review before it is accepted.
-   **R-5. Name lookup cost.** Every identifier expression now does one
    `Map::Contains` on `pack_binding_arities_`, which is empty in non-variadic
    code. Falsified if the gate's wall time on the toolchain testdata rises by
    more than its run-to-run noise (it was 31415 ms for trunk's 1942 files,
    carbonbuild README).
-   **R-6. Imported variadic functions in another library's specifics.** Only
    the declaration-level instructions (`PackExpansionPattern`, `PackType`)
    are imported; a specific of an imported generic is lowered from the
    defining file's body, as for every generic (toolchain/lower/testdata/
    function/generic/import.carbon). The check golden `import.carbon` covers the
    call, and the lower golden's `lib` and `use` splits lower an imported
    variadic function at two arities, as that precedent does for a generic
    (amended 2026-10-14, review fold: A-m4); programs are single files, so no
    program links two libraries.
-   **R-7. `each` as a keyword diverges from the nightly.** Upstream's lexer
    does not have it (M-3), so a Carbon file valid upstream that names something
    `each` is invalid in the fork until upstream adds the keyword; M-10 finds no
    such file upstream except the keyword list itself. D-VA-10's break
    condition handles upstream choosing otherwise.
-   **R-8. Code size.** A call with k arguments instantiates a specific whose
    expansion bodies are unrolled k times, the design's monomorphization. No
    bound is imposed; a program with thousands of arguments would compile
    slowly. Not row-bounding.
-   **R-9. A pack value reaches a path that wants an object** (amended
    2026-10-14, review fold: A-B2 / B-M1). A value of `«E; N»` is the address
    of `N` value representations, as a tuple value is, and no `Core.Copy`
    exists for a pack type, so any path that copy-initializes from a pack value
    fails to check ("cannot copy value of type `«E; N»`") rather than
    miscompiling. Only a `var` each-binding (a TODO, W-221) or a pack in a
    tuple (a TODO, W-213) could ask for one in the slice. Detected by a golden's
    check error; falsified by any such error in a §4 split that the slice
    accepts.
-   **R-10. Order and copies regress unseen** (amended 2026-10-14, review fold:
    A-B1, A-B2, B-M1, B-M2). Rev 1's two defects passed every rev-1 program,
    because their operands were pure and their element types primitive.
    variadics_arg_order, variadics_no_copy and variadics_generic_element, and
    §8.5's MU-7, now pin both; a change that reintroduces either fails one of
    them.

### §7.2 Rejected alternatives

-   **A-1. Desugar the one program to a tuple loop** (rejected, Goodhart).
    Rewrite `fn Sum(... each n: i64)` into `fn Sum(n: (i64, ...))` taking a
    tuple and the statement into a loop, enough to print 6 and 0. It would
    implement no rule of the design that the arbiter is meant to arbitrate:
    no each-name, no pack type, no deduced arity, no definition check of the
    body against a pack; `fixed_params`, `forward` and `expansion_args` would
    need three more special cases; and R16(c) prohibits special-casing a
    recognizable test input. The row would read PARTIAL with nothing of the
    design behind it.
-   **A-2. Implement only the lexer and parser** (rejected, Goodhart). Lex and
    parse every form of §1.2 and stop. The row's evidence would change from
    "not even lexable" to "parsed, never checked", and no program could PASS,
    so the bullet would stay SKIP and the row could not honestly move (R9: a
    bullet is done only when the scoreboard says PASS; a PARTIAL row needs a
    working subset, gap-analysis.md:12-14). The lexer and parser are commits 1
    to 3 of this plan; they are a means, not the slice.
-   **A-3. Wait for upstream** (rejected). Upstream's pace (M-6): 50 commits in
    the nine days to 66a250ad9, two of them on variadics, neither checking or
    lowering anything; its first commit says it is trying "an approach
    supporting expanding a statement across elements of a tuple without
    building "real" variadics", which is p002240's "Generalize `expand`"
    alternative, not the adopted design (M-5). The fork's cut is also held (the
    tree-wide rename conflicts with the six held PRs), so even an upstream
    implementation could not arrive before an advance that is not scheduled.
    V-3 permits progress where upstream is silent; D-VA-1 keeps the fork on
    upstream's shapes so that its later work merges.
-   **A-4. Pack storage as a tuple type** (rejected). A pack of one element
    type could be a tuple `(E, E, ...)` of arity N; but a tuple type of
    symbolic arity does not exist (it is W-213's segment type). Rev 2's
    `PackType` borrows the tuple's value representation instead (D-VA-3)
    (amended 2026-10-14, review fold: A-B2 / B-M1).
-   **A-5. Check the body once per specific** (rejected). Checking each
    specific's body would be template instantiation, not a definition check: an
    error would appear only at a call, which the bullet's "definition-checked"
    excludes, and the design's iterative typechecking checks segments, not
    elements (DR-32).
-   **A-6. A run-time loop in lowering** (rejected). Lower the body once inside
    an LLVM loop over the pack's storage (amended 2026-10-14, review fold:
    RR-m3). It would work for this slice's one-type packs,
    but the design specifies execution at monomorphization with `$I` "treated as
    a constant" (:300-302), which heterogeneous packs require (each iteration
    may have a different type), so a loop would be replaced, not extended, by
    W-212.
-   **A-7. Re-derive upstream's lexer and parser in the fork** (rejected,
    D-VA-1): a second state set to reconcile at the advance, against a measured
    one-line real change in upstream's state.def (M-4).
-   **A-8. A "0.1 limits" section in variadics.md** (rejected, D-VA-14).
-   **A-9. Keep upstream's `fail_todo_pack_expansion_statement` name**
    (rejected in rev 2, D-VA-12): rev 1 kept it to spare the advance a
    conflict that the refill causes anyway (M-16) (amended 2026-10-14, review
    fold: B-m4).
-   **A-10. Store a pack as `array(E, N)`** (rev 1's D-VA-3; rejected in rev 2,
    review fold A-B2 / B-M1). It deduces, forwards, indexes and is empty-safe
    on trunk (M-7), but initializing an array element from a value
    copy-initializes it (M-22), which runs `Core.Copy.Op` per element and
    rejects any class without `Copy`, where the design's value binding needs
    neither.
-   **A-11. Allow only copyable element types** (reviews' option (b);
    rejected). A `semantics TODO` for element types not known to be `Core.Copy`
    would keep the array and make the copy unobservable only for types whose
    `Copy` is trivial; a class with a side-effecting `Copy` would still run it,
    which the design does not do, so the restriction would be a 0.1 rule the
    design does not have (an F-018), and it would drop generic callers.
-   **A-12. A TODO for an expansion argument followed by another argument**
    (review A's narrower fallback; rejected). It avoids the reordering by
    refusing it, and would turn variadics_expansion_args into a TODO; emitting
    the expansion where it is written fixes the order with less code than the
    deferred splice had.
-   **A-13. One parameter per element in each specific** (review A's example of
    value storage; rejected). The design's monomorphization allows it, but it
    reshapes call lowering, function types and C++ thunks per specific; the
    pack's value representation needs no new calling convention.
-   **A-14. Make the bare pack name an error as a fork rule (F-018)** (review
    A's other option for A-m2; rejected). It would decide what p002240 leaves
    open on purpose; a TODO keeps the opening and needs no design decision.

## §8 Verification and discharge

Scripts are the carbonbuild set
(`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild`,
`$CB` below); its README describes each. Every run's command, exit status and
log path go into the implementation review's evidence and the landed notes.

### §8.0 Syntax sweeps of the commit states (planner, done)

`$V/bin/synchk.py` (M-11) over the 315 translation units, on scratch worktrees
of `va1-c3` and `va1-c4` (the C3 and C4 states before clang-format; the
formatted `va1-c3f` and `va1-c4f` differ from them only by re-wrapped lines, in
C3 by the node_stack.h case label below, and in C4 by five test splits, `git
diff va1-c3 va1-c3f` and `git diff va1-c4 va1-c4f`): C3 (`va1-c3`) gave `315
files, 1 failed`: toolchain/check/node_stack.cpp,
"static assertion failed due to requirement 'from_category || from_kind':
Id::Kind not specified for EachBindingName; add to
NodeStack::NodeKindToIdKindSpecialCases or specify a node category in
typed_nodes.h". The node stack's classification of `EachBindingName` (one case
label in toolchain/check/node_stack.h) was therefore moved from C4 to C3, where
`va1-c3f` carries it, and the failing file and five other includers of
node_stack.h (check/check_unit.cpp, node_id_traversal.cpp,
handle_binding_pattern.cpp and handle_pack_expansion.cpp, and
parse/handle_binding_pattern.cpp) re-checked on `va1-c3f`: `6 files, 0 failed`.
C4 (`va1-c4`) gave `315 files, 0 failed`, and its lowering stub, which the trunk
build does not list, passes with lower/handle.cpp's flags (rc 0). The C5 state
is the prototype's final state, swept as M-11. So each implementation commit's
C++ is well formed with the trunk build's warnings as errors on its own, which
is what "each commit builds" can be measured to before a build; §8.1 measures
the rest.

Rev 2 (fixer, done; amended 2026-10-14, review fold: every code finding): the
same script, on scratch worktrees `$F/wt-c4` and `$F/wt-c5` of `fx-c4` and
`fx-c5`, over the 315 units plus check/handle_pack_expansion.cpp (a file the
trunk build does not list, swept with the default flags): 316 units, 0 failed,
at each state. lower/handle_pack_expansion.cpp with lower/handle.cpp's flags
(`$F/bin/synchk_as.py`): rc 0 at both states. `fx-c3` changes no code of
`va1-c3f` (one parse golden split), so rev 1's C3 result stands. The files the
seven mutants of §8.5 change, each at its mutant: eight checks, rc 0 at each
(M-11).

Rev 3 (second fixer, done; amended 2026-10-14, review fold: RR-M1): the one C++
file it changes, check/handle_pack_expansion.cpp, at `rr-c4` (the same at
`rr-c5`) and at `rr-mu-7`: rc 0 at each, with a negative control (M-25). Every
other C++ and `.def` file of `rr-c4` and `rr-c5` is byte-identical to
`fx-c4`'s and `fx-c5`'s, so rev 2's sweep stands for them, and MU-8's file is
`fx-c5`'s, which rev 2 swept.

### §8.1 Build (implementer)

After C1, C3, C4 and C5: `$CB/build.sh /home/user/carbon-va` then
`$CB/install.sh /home/user/carbon-va` (the build lands in
/home/user/carbon-build/carbon-va/). A full build is required at each of these
commits, because each edits an X-macro header most objects include (M-19);
the relink recipe is usable only for §8.5's mutants, which edit `.cpp` files
alone. C2 changes docs only and needs no build.

Measured (amended 2026-10-14, implementation-review fold: VA1-IR2-m1): full
builds at C2 (whose toolchain is C1's), C3, C4 and fix 3 (which edits
toolchain/diagnostics/kind.def), incremental ones at fix 1 and C5 (C5 edits no
X-macro header), and version-stamp relinks for the fills, each with 0 warnings
and followed by `install.sh`.

### §8.2 Autoupdate to its fixpoint (implementer)

After each build that has new or changed goldens: `$CB/autoupdate.sh
/home/user/carbon-va <the commit's goldens>`, the goldens given as positional
paths (the script's usage is `autoupdate.sh <worktree> [--threads N]
[files...]`; rev 1's `--file_tests=` form makes it exit 2, review B's
measurement; amended 2026-10-14, review fold: B-m1), then the same command
again, which must change nothing (R26: a second run that changes more than
`.loc` numbers is a stop, not a loop). The fill's diff is reviewed against §4
before the fill commit; a golden whose fill contradicts §4 is a finding, never
an edit.

Measured (amended 2026-10-14, implementation-review fold: VA1-IR2-m1): F3 and F4
reached their fixpoint at the third pass, and neither second pass was
nondeterminism, so each was diagnosed before the third ran. F3's second pass
changed only the lex golden's column padding: `TokenizedBuffer::Print`
(toolchain/lex/tokenized_buffer.cpp) sizes the column field over every token,
including the file-end token after the CHECK lines the first pass adds. F4's
changed only one clang source-line number in `fail_todo_export`'s C++ snippet,
which the CHECK lines inserted above it shift. F5's second pass changed nothing,
and F6's changed nothing either.

### §8.3 Gate (implementer)

`$CB/gate.sh /home/user/carbon-va`, file_test over every testdata file (trunk:
1942 files, `[  PASSED  ] 1942 tests.`, carbonbuild README). Expected, all
passing: 1946 after C1 (and F1 if needed) and after C2; 1950 after F3; 1959
after F4; 1960 after F5 (rev 1: 1957 and 1958; rev 2 adds two check goldens;
amended 2026-10-14, review fold: A-M1, B-m3). Each implementation commit alone
is expected red on exactly its new goldens and its refill, nothing else and no
crash (§3).

Measured (amended 2026-10-14, implementation-review fold: VA1-IR2-m1): every
expected count, and the fold's fix 3 alone red on exactly the 4 goldens whose
sources it changes; after F6, `file_test test mode on /home/user/carbon-va: 1960
passed, 0 failed (exit 0, 98s)` (the fold adds splits, not files).

### §8.4 Conformance (implementer)

`XDG_CACHE_HOME=<a private directory> $CB/conformance.sh /home/user/carbon-va
<a private output directory>` after F5 (the script requires the output
directory, and R5 requires it private; amended 2026-10-14, review fold:
B-m1): expected 137 PASS / 0 FAIL / 21 SKIP over 158 on this branch
(f67ab650d's 128 / 0 / 22 over 150 plus §5's delta), the nine variadics
programs PASS with §1.6's output, and the C++ side of
variadics_sum_diff compiles with the toolchain's own clang++ and agrees. The
row commit R quotes this run, EXPECTED, not of record.

Measured (amended 2026-10-14, implementation-review fold: VA1-IR2-m1): after F5,
137 PASS / 0 FAIL / 21 SKIP over 158 with §1.6's outputs (R's run); after F6,
PASS 137, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0,
DIFF-MISMATCH 0, SKIP 21 (of 158), bullets 49 PASS, 0 FAIL, 7 SKIP of 56, and
the nine variadics programs PASS.

### §8.5 Mutants that prove the programs are not vacuous (implementer)

Each mutant below is an exact diff against `rr-c5`, the branch `rr-mu-n` of
`$F/cp` (rev 3; rev 2's were the branches `mu-n` on `fx-c5`, whose diffs differ
only in MU-7's line numbers; amended 2026-10-14, review fold: RR-M1) (amended
2026-10-14, review fold: B-m2, which asked for exact diffs and found rev 1's
MU-1 prediction for variadics_fixed_params wrong: skipping the only iteration of
`Digits(1, 2, 3)` gives 13, not 12). Each changes `.cpp` files only, so it is
compiled and relinked into a scratch copy of the C5 build with the relink recipe
(`$V/../st1-fixer/fix/relink.py`, generalized as OP-2's `bin/relink.py`), and
the nine programs are run against it. MU-7 is rev 2's: it restores rev 1's order
defect (A-B1 / B-M2). MU-8 is rev 3's: it restores rev 2's
`CompleteTypeOrCheckFail` (RR-M1), and only variadics_forward's `Narrowed` sees
it: lowering `Narrowed`'s arity-3 specific meets the incomplete `«i32; 3»` and
the compiler aborts (a `CARBON_CHECK` in `GetPackElementAddr`, or
`CreatePackStorage`'s use of a missing value representation type), so the
program does not compile. MU-1 leaves the last slot of a forwarded pack
unwritten, but the callee's loop under the same mutant never reads it, so the
predictions below hold. MU-6 makes the compiler abort in
`ConvertPackLiteralToPack`'s `CARBON_CHECK` (a pack literal of k elements
converted to a pack of arity k - 1). Predicted results, each derived from the
program text under the mutant:

| Mutant | each | fixed_params | forward | empty_pack | expansion_args | sum_diff | arg_order | no_copy | generic_element |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MU-1: skip the last iteration (function_context.cpp) | FAIL (3, 0) | FAIL (12, 13, 431) | FAIL (12, 24, 0, 0, 45) | FAIL (7, 1, 9) | FAIL (19, 129, 1559) | FAIL (12, 5, 0, 14, 0) | FAIL (1, 2, 9, 129, 1, 9, 19) | FAIL (1, 3, 3) | FAIL (2, 1, 1) |
| MU-2: run each iteration twice (function_context.cpp) | FAIL (12, 0) | FAIL (12, 1223, 433221) | FAIL (112233, 224466, 0, 88, 445566) | FAIL (7, 1, 1, 2, 2, 9) | FAIL (19, 122339, 15555559) | FAIL | FAIL (1, 2, 2, 3, 3, 9, 122339, 1, 9, 19) | FAIL (each line twice) | FAIL (6, 4, 4) |
| MU-3: iterate the indexes in reverse (function_context.cpp) | PASS (6, 0) | FAIL (12, 123, 4231) | FAIL (321, 642, 0, 8, 654) | FAIL (7, 2, 1, 9) | FAIL (19, 1329, 15559) | FAIL (321, ...) | FAIL (1, 3, 2, 9, 1329, 1, 9, 19) | FAIL (2, 1, 4, 3, 4, 3) | PASS (3, 2, 2) |
| MU-4: `PackIndex` always 0 (lower handle_pack_expansion.cpp) | FAIL (3, 0) | FAIL (12, 123, 4331) | FAIL (111, 222, 0, 8, 444) | FAIL (7, 1, 1, 9) | FAIL (19, 1229, 15559) | FAIL | FAIL (1, 2, 2, 9, 1229, 1, 9, 19) | FAIL (1, 1, 3, 3, 3, 3) | PASS (3, 2, 2) |
| MU-5: the `PackLiteral`'s elements reversed (call.cpp) | PASS (6, 0) | FAIL (12, 123, 4231) | FAIL (321, 642, 0, 8, 654) | FAIL (7, 2, 1, 9) | FAIL (19, 1329, 15559) | FAIL (321, ...) | FAIL (1, 3, 2, 9, 1329, 1, 9, 19) | FAIL (2, 1, 4, 3, 4, 3) | PASS (3, 2, 2) |
| MU-6: arity deduced as the element count minus one (deduce.cpp) | FAIL (compile) | FAIL (compile) | FAIL (compile) | FAIL (compile) | FAIL (compile) | FAIL (compile) | FAIL (compile) | FAIL (compile) | FAIL (compile) |
| MU-7: an expansion argument evaluated at the call, after the later arguments (handle_pack_expansion.cpp and call.cpp) | PASS | PASS | PASS | PASS | PASS | PASS | FAIL (1, 9, 2, 3, 1239, 1, 9, 19) | PASS | PASS |
| MU-8: an expansion argument's pack type completed with `CompleteTypeOrCheckFail` (handle_pack_expansion.cpp; amended 2026-10-14, review fold: RR-M1) | PASS | PASS | FAIL (compile: lowering aborts on `Narrowed`) | PASS | PASS | PASS | PASS | PASS | PASS |

MU-3, MU-4 and MU-5 show why the arbiter alone is not enough (a sum sees
neither order nor which element is read), MU-7 why variadics_arg_order exists
(every other program's operands are pure), MU-8 why variadics_forward has
`Narrowed` (every other expansion's body has its caller's element type;
amended 2026-10-14, review fold: RR-M1), and variadics_generic_element's
PASS under MU-3, MU-4 and MU-5 is expected, because it counts elements. The
rev-1 representation is the natural mutant for variadics_no_copy and
variadics_generic_element: on trunk the same array path rejects `Plain` and
prints 103 and 104 for `Loud` (M-22). A mutant that leaves every program PASS
is a finding against §1.8's set. The diffs:

MU-1:

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/function_context.cpp
+++ b/toolchain/lower/function_context.cpp
@@ -98,7 +98,7 @@ auto FunctionContext::LowerPackExpansionBody(
   // The arity is specific-dependent: two specifics whose bodies run a different
   // number of iterations must not be coalesced.
   AddIntToCurrentFingerprint(arity);
-  for (auto index : llvm::seq(arity)) {
+  for (auto index : llvm::seq(arity == 0 ? arity : arity - 1)) {
     pack_index_ = index;
     LowerBlockContents(body_block_id);
     if (finish_iteration) {
```

<!-- google-doc-style-resume -->

MU-2:

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/function_context.cpp
+++ b/toolchain/lower/function_context.cpp
@@ -99,15 +99,17 @@ auto FunctionContext::LowerPackExpansionBody(
   // number of iterations must not be coalesced.
   AddIntToCurrentFingerprint(arity);
   for (auto index : llvm::seq(arity)) {
-    pack_index_ = index;
-    LowerBlockContents(body_block_id);
-    if (finish_iteration) {
-      finish_iteration(index);
-    }
-    for (auto inst_id : pack_iteration_locals_) {
-      locals_.Erase(inst_id);
+    for (int repeat = 0; repeat < 2; ++repeat) {
+      pack_index_ = index;
+      LowerBlockContents(body_block_id);
+      if (finish_iteration) {
+        finish_iteration(index);
+      }
+      for (auto inst_id : pack_iteration_locals_) {
+        locals_.Erase(inst_id);
+      }
+      pack_iteration_locals_.clear();
     }
-    pack_iteration_locals_.clear();
   }
   pack_index_ = std::nullopt;
 }
```

<!-- google-doc-style-resume -->

MU-3:

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/function_context.cpp
+++ b/toolchain/lower/function_context.cpp
@@ -98,7 +98,7 @@ auto FunctionContext::LowerPackExpansionBody(
   // The arity is specific-dependent: two specifics whose bodies run a different
   // number of iterations must not be coalesced.
   AddIntToCurrentFingerprint(arity);
-  for (auto index : llvm::seq(arity)) {
+  for (auto index : llvm::reverse(llvm::seq(arity))) {
     pack_index_ = index;
     LowerBlockContents(body_block_id);
     if (finish_iteration) {
```

<!-- google-doc-style-resume -->

MU-4:

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/handle_pack_expansion.cpp
+++ b/toolchain/lower/handle_pack_expansion.cpp
@@ -100,7 +100,7 @@ auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                 SemIR::PackIndex /*inst*/) -> void {
   context.SetLocal(inst_id, llvm::ConstantInt::get(
                                 llvm::Type::getInt64Ty(context.llvm_context()),
-                                context.pack_index()));
+                                /*V=*/0));
 }

 auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
```

<!-- google-doc-style-resume -->

MU-5:

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/call.cpp
+++ b/toolchain/check/call.cpp
@@ -411,7 +411,8 @@ static auto GroupPackArguments(
         context,
         pack_arg_ids.empty() ? loc_id : SemIR::LocId(pack_arg_ids.front()),
         {.type_id = GetTupleType(context, type_inst_ids),
-         .elements_id = context.inst_blocks().Add(pack_arg_ids)});
+         .elements_id = context.inst_blocks().Add(
+             llvm::SmallVector<SemIR::InstId>(llvm::reverse(pack_arg_ids)))});
   }

   grouped_arg_ids.assign(arg_ids.begin(), arg_ids.begin() + num_before);
```

<!-- google-doc-style-resume -->

MU-6:

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/deduce.cpp
+++ b/toolchain/check/deduce.cpp
@@ -461,7 +461,7 @@ auto DeductionContext::Deduce() -> bool {
             {.type_id =
                  GetSingletonType(context(), SemIR::IntLiteralType::TypeInstId),
              .int_id = context().ints().Add(
-                 static_cast<int64_t>(element_ids.size()))});
+                 static_cast<int64_t>(element_ids.size()) - 1)});
         Add(pack_type.arity_id, arity_id, /*want_value=*/true);
         for (auto element_id : llvm::reverse(element_ids)) {
           Add(pack_type.element_type_inst_id, element_id, /*want_value=*/true);
```

<!-- google-doc-style-resume -->

MU-7:

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/call.cpp
+++ b/toolchain/check/call.cpp
@@ -400,6 +400,7 @@ static auto GroupPackArguments(
       return false;
     }
     pack_arg_id = pack_arg_ids.front();
+    context.inst_block_stack().AddInstId(pack_arg_id);
   } else {
     llvm::SmallVector<SemIR::InstId> type_inst_ids;
     type_inst_ids.reserve(pack_arg_ids.size());
--- a/toolchain/check/handle_pack_expansion.cpp
+++ b/toolchain/check/handle_pack_expansion.cpp
@@ -260,7 +260,7 @@ auto HandleParseNode(Context& context, Parse::PackExpansionExprId node_id)
   // elements" (docs/design/variadics.md, "Pack expansion expressions and
   // statements"), so the expansion is evaluated here, where it is written,
   // before the arguments that follow it (fork VA-1, D-VA-4).
-  context.node_stack().Push(node_id, AddInst<SemIR::PackExpansionExpr>(
+  context.node_stack().Push(node_id, AddInstInNoBlock<SemIR::PackExpansionExpr>(
                                          context, node_id,
                                          {.type_id = pack_type_id,
                                           .body_block_id = *body_block_id,
```

<!-- google-doc-style-resume -->

MU-8 (amended 2026-10-14, review fold: RR-M1):

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_pack_expansion.cpp
+++ b/toolchain/check/handle_pack_expansion.cpp
@@ -242,19 +242,11 @@ auto HandleParseNode(Context& context, Parse::PackExpansionExprId node_id)

   // "The type of a pack expansion expression or pattern is `...B`, where `B`
   // is the type of its body" (docs/design/variadics.md, "Typing and shaping
-  // rules"): a pack of the body's type, with the arity of its each-names.
+  // rules"): a pack of the body's type, with the arity of its each-names. Its
+  // element type is complete, so it is too.
   auto pack_type_id = GetPackType(
       context, context.types().GetTypeInstId(result_type_id), scope.arity_id);
-  // Lowering reads the pack type's value representation in every specific, so
-  // each specific's pack type must be complete, even when nothing else requires
-  // it, as when the call converts the elements to another type. For a symbolic
-  // type, `RequireCompleteType` records that requirement in the generic (fork
-  // VA-1, D-VA-7). The element type is complete, so the pack type is too, and
-  // no diagnostic context is needed here.
-  bool complete = RequireCompleteType(context, pack_type_id, node_id,
-                                      [](auto& /*builder*/) {});
-  CARBON_CHECK(complete, "Expected {0} to be a complete type",
-               context.types().GetAsInst(pack_type_id));
+  CompleteTypeOrCheckFail(context, pack_type_id);

   // "`...` in a tuple literal behaves like a series of comma-separated tuple
   // elements" (docs/design/variadics.md, "Pack expansion expressions and
```

<!-- google-doc-style-resume -->

Re-run after fix 3 (amended 2026-10-14, implementation-review fold: MAJOR-1,
MAJOR-2, MINOR-3). Fix 3 changes `GroupPackArguments` (call.cpp), which MU-5 and
MU-7 edit, and `HandleParseNode(PackExpansionExprId)` in
handle_pack_expansion.cpp, whose completeness check MU-8 edits and whose
instruction MU-7 edits. MU-1 to MU-7 apply to fix 3's tree as written, at
shifted lines. MU-8 restores `CompleteTypeOrCheckFail` in place of the check fix
3 rewrote, so its diff against fix 3's tree is the one below. Every mutant was
rebuilt with the relink recipe on fix 3's tree and the nine programs run against
it, with a control relink of the unmodified source passing all nine: each of the
eight gives the same status and output, program by program, as the implementer's
run on F5, so each matches the table above.

MU-8 against fix 3's tree:

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_pack_expansion.cpp
+++ b/toolchain/check/handle_pack_expansion.cpp
@@ -242,25 +242,11 @@

   // "The type of a pack expansion expression or pattern is `...B`, where `B`
   // is the type of its body" (docs/design/variadics.md, "Typing and shaping
-  // rules"): a pack of the body's type, with the arity of its each-names.
+  // rules"): a pack of the body's type, with the arity of its each-names. Its
+  // element type is complete, so it is too.
   auto pack_type_id = GetPackType(
       context, context.types().GetTypeInstId(result_type_id), scope.arity_id);
-  // Lowering reads the pack type's value representation in every specific, so
-  // each specific's pack type must be complete, even when nothing else requires
-  // it, as when the call converts the elements to another type. For a symbolic
-  // type, `RequireCompleteType` records that requirement in the generic (fork
-  // VA-1, D-VA-7). Forming a value does not require every type complete (an
-  // incomplete facet type, such as a forward-declared interface's, is not
-  // diagnosed), so the element type can be incomplete here.
-  if (!RequireCompleteType(context, pack_type_id, node_id, [&](auto& builder) {
-        CARBON_DIAGNOSTIC(IncompleteTypeInPackExpansion, Context,
-                          "forming a pack of incomplete type {0}",
-                          SemIR::TypeId);
-        builder.Context(node_id, IncompleteTypeInPackExpansion, result_type_id);
-      })) {
-    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
-    return true;
-  }
+  CompleteTypeOrCheckFail(context, pack_type_id);

   // "`...` in a tuple literal behaves like a series of comma-separated tuple
   // elements" (docs/design/variadics.md, "Pack expansion expressions and
```

<!-- google-doc-style-resume -->

### §8.6 prek, clang-tidy and R31 (every agent, every commit)

`SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
uvx prek run --files <the commit's files>` to a fixpoint; for each `.md`,
heading counts per level and list-item counts (including indented items)
before and after (R31(b)), and the diff grepped for manufactured headings
(R31(c)). C1 and C2 are upstream's text and are not reformatted; if prek wants
to change them, that is recorded and not applied (they are byte-identical to
upstream but for the conflict resolution). Review B ran prek on C1 and C2's
thirteen files at 2f0d4c4c4 and every hook passed, so the contingency is not
expected to arise.

clang-tidy, for every implementation commit and every fix commit (amended
2026-10-14, review fold: B-M3; R21 and R22): `/home/user/llvm/bin/clang-tidy`
(LLVM 21.1.8) over every `.cpp` the commit changes, with the build's own flags,
twice: once with `--checks='-*,misc-no-recursion'` and
`--warnings-as-errors='*'` and no line filter, because a recursion diagnostic
lands on an unchanged function (M-23), and once with the repository's
.clang-tidy minus `modernize-*` (whose checks crash the bundled front end),
line-filtered to the commit's changed lines, as review B's `tidyall.py` does.
`$F/bin/tidy.py` and `$F/bin/tidyall.py` run both with the trunk build's flags;
for VA-1's own build their `B` is /home/user/carbon-build/carbon-va. Every
diagnostic is fixed in the commit's next fix commit; none is suppressed with a
new `NOLINT`.

### §8.7 Harness self-test

`python3 fork/conformance/runner.py --self-test` before every commit that
touches programs (R7): expected "158 programs parsed, 56 bullets in table, OK"
on this branch (M-14; amended 2026-10-14, review fold: A-B1, A-B2, B-M1,
B-M2); rev 3 re-ran it with its changed program (M-25; amended 2026-10-14,
review fold: RR-M1).

### §8.8 Re-verification on the merge commit (implementer, before D)

After the merge of trunk (D-VA-15): §8.1 to §8.4 again on the merge commit,
with the refills the merged branches cause committed as their own fill
commits; the totals of §8.3 and §8.4 then become whatever trunk's floor plus
§5's delta is, and commit D quotes that run. Then the id re-scan of the head.

### §8.9 Not run, and why

-   No build, file_test fill, gate or conformance run was made by the planner
    or the fixer: neither builds a toolchain, and the relink recipe cannot stand
    in for commits that edit X-macro headers (M-19). Every golden line and
    every program output in this plan is a prediction (§4) or a hand
    derivation (§1.6), not a measurement of VA-1's code.
-   The runtime behavior of the lowering (R-2), and of rev 2's pack values
    (the stores and loads of element value representations, R-9), is
    unmeasured until §8.4; the eight mutants of §8.5 were syntax-checked, not
    run (amended 2026-10-14, review fold: RR-M1). RR-M1's crash and its fix
    are hand-predicted from the cited code, as the re-review's analysis was.
-   Bazel-only tests are not part of the container gate (carbonbuild README,
    "Bazel-only tests"): the gtest unit tests (among them
    toolchain/lex/tokenized_buffer_test.cpp, whose keyword table the `Each`
    keyword extends through the X-macro, and the parser's typed-node tests),
    toolchain/diagnostics' coverage test (every diagnostic kind tested; §4
    gives each new kind a `fail_` split), lit tests and fuzzers. They run only
    on hosted CI, which is disabled.
-   Lowering an imported variadic function's specific (R-6) is covered by the
    lower golden's `lib` and `use` splits, unmeasured until §8.2's fill
    (amended 2026-10-14, review fold: A-m4).
-   prek over the cherry-picked commits' files was run by review B, not by the
    planner: every hook passed (§8.6).
-   Hosted CI's clangd-tidy step, part of upstream's gate (R21), cannot run,
    because GitHub Actions is disabled on the fork. §8.6's local clang-tidy
    runs replace it, with two known gaps: `modernize-*` is excluded because
    its checks crash the bundled front end, and clangd's own handling of
    headers is not reproduced. M-23 is the fold's run (amended 2026-10-14,
    review fold: B-M3).

## Hand-off notes for the implementer

1.  **Recreate C1 and C2 exactly.** On `claude/carbon-fork-0-1-va`:
    `GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com git
    cherry-pick -x 2ec4bab59`; resolve per §2.1; then compare with the scratch
    result before `git cherry-pick --continue`: after `git fetch $F/cp
    fx-c5`, `git diff 3b4a431f0 -- toolchain/parse/state.def
    toolchain/check/node_stack.h` must print nothing. Do not pass `--author`, do
    not add trailers (D-VA-1). Then `git cherry-pick -x a045da8e6`, which needs
    the upstream objects (`git fetch /home/user/carbon-lang
    refs/remotes/upstream/trunk` first if the worktree lacks them).
2.  **C3, C4 and C5 are §2.3, §2.4 and §2.5 plus §2.6 and §2.7.** The scratch
    branches `fx-c3`, `rr-c4` and `rr-c5` in `$F/cp` hold exactly those trees
    (rev 2's `fx-c4` and `fx-c5`, and rev 1's `va1-c3f`, `va1-c4f` and
    `va1-c5f` in `$V/cp`, are superseded; amended 2026-10-14, review fold:
    RR-M1, RR-m2);
    after writing each commit from the plan, `git diff <your commit> <scratch
    branch> -- toolchain fork/conformance` must be empty. If the plan and the
    scratch branch ever disagree, the plan is the authority and the disagreement
    is reported.
3.  **Fills are separate commits** ("Autoupdate testdata goldens on the
    container arbiter"), to their fixpoint (R26), reviewed against §4.
4.  **What to run first after C5's build:** M-1's `sum.carbon` with `as i32`
    added to its prints (it is the arbiter's body); then variadics_arg_order
    and variadics_no_copy, which check rev 2's two repairs, and
    variadics_forward, whose `Narrowed` checks rev 3's; then the other
    programs; then §8.5's MU-7 and MU-3, the mutants that only the
    order-sensitive programs catch, and MU-8 (amended 2026-10-14, review fold:
    RR-M1).
5.  **Watch-outs.** The `PackArity` special name is alphabetical in ids.h and
    has a spelling in name.cpp; the new kind.def kinds sit in their own blocks;
    upstream's `fail_todo_pack_expansion_statement` is renamed
    `fail_pack_expansion_without_each_name` and refilled; the programs print
    with `as i32`; every TODO in §2.4 has its golden split except "pack
    expansion over packs of different arities" (W-222; §1.11), which no slice
    program can reach; a pack value is the address of its elements' value
    representations, so a lowering path that treats it as an object is a
    finding (R-9) (amended 2026-10-14, review fold: A-B2, B-m3, B-m4); and a
    pack type that check builds is required complete with
    `RequireCompleteType`, never completed with `CompleteTypeOrCheckFail`,
    because lowering reads it in every specific (amended 2026-10-14, review
    fold: RR-M1).
6.  **Records only in R and D.** No W-id or F-id appears in source, goldens or
    program headers (head, id allocation); the re-scan runs before D.
7.  **R31.** This plan's §2 code blocks sit between `<!--
    google-doc-style-ignore -->` and `<!-- google-doc-style-resume -->`
    lines, because the doc-style hook rewrites words inside code blocks; any
    record text that quotes code does the same.

## Review fold record (rev 2, 2026-10-14)

Two plan reviews of rev 1 (aced921975): review A (architecture; REJECT) and
review B (concreteness, process, Goodhart, scope honesty and cross-workstream;
APPROVE-WITH-AMENDMENTS). A separate fixer (R11) folded all 20 findings and
rejected none; every measurement it re-ran was re-run in `$F`, and every
finding about code was folded into the code of `fx-c3`, `fx-c4` and `fx-c5`
and regenerated into §2, never patched into the plan's text by hand. Review
B's summary also found the design's rule that packs cannot be indexed missing
from §1.2; it is DR-42. Each amended sentence above is marked "(amended
2026-10-14, review fold: <finding>)".

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| A-B1: an expansion argument runs after the arguments written after it | BLOCKER | By the cited code of rev 1 (its `PackExpansionExpr` handler kept only a marker, and `ConvertPackExpansionToArray` spliced the body in at the call's conversion), hand-derived as the review was; no build exists | Folded: the expansion is emitted where it is written and lowered there; element conversion at the call is a second `PackExpansionExpr` (`ConvertPackToPack`) with its cleanup TODO; program variadics_arg_order, mutant MU-7, lower split `arg_order`, check split `forward_converted`; A-12 recorded as rejected | §1.2 DR-21, DR-41; §1.3 D-VA-2; §1.4 D-VA-4, D-VA-6, D-VA-7; §1.5; §1.6; §1.8; §2.4; §2.5; §2.6; §2.7; §4; §5; §7.2; §8.5 |
| A-B2: array storage copies every element | BLOCKER | Yes, on trunk (M-22): `TakeArr((c, c))` fails "cannot copy value of type `C`"; with a printing `Copy`, the output gains 101 and 102 | Folded with the reviews' option (a): the pack type `«E; N»` holds its elements' value representations, as a tuple value does (M-21); `PackValue` and `PackElement` replace the array and `PackExpansionInit`; programs variadics_no_copy and variadics_generic_element; check splits `class_element` and `generic_caller`; lower split `class_element`; A-10, A-11 and A-13 recorded | §0.1 rows 10 and 15; §0.2 M-7, M-21, M-22; §1.2 DR-30, DR-38; §1.4 D-VA-3, D-VA-7, D-VA-8; §1.5; §2.4 to §2.7; §4; §5; §7 |
| A-M1: exporting a variadic function to C++ crashes | MAJOR | Hand-predicted from export.cpp:339-354 and import.cpp:2904-2910, as the review was | Folded: the TODO `exporting a variadic function to C++` ahead of the generic export; golden fail_todo_export.carbon; W-228's evidence; §6.2 lists export.cpp as a touch point with OX-1 and PR 55 | §0.3 item 6; §1.4 D-VA-5; §1.11 W-228; §2.4; §2.6; §4; §6.2 |
| A-m1: defaults beside or on a pack are unfenced | MINOR | By the code: call.cpp:306-310, handle_pattern_list.cpp:331-372, rev 1's `GroupPackArguments` | Folded: the TODO `default value in a parameter list with a pack expansion pattern`, raised by the pattern for a default before it and by the default for one after it or on it; three splits; W-215 | §1.4 D-VA-5; §1.11 W-215; §2.4; §2.6; §4 |
| A-m2: `PackNameWithoutEach` decides an open rule | MINOR | By p002240:637-645 | Folded: a `semantics TODO`, not an error, so no F-018; W-230; `PackExpansionArgForSingularParam` reworded as the slice's diagnostic for a match the design's merging cannot typecheck; A-14 recorded | §1.2 DR-4; §1.4 D-VA-4, D-VA-11; §1.9 D-VA-14; §1.11 W-230; §2.4; §4 |
| A-m3: pattern walkers skip `PackExpansionPattern` | MINOR | By handle_function.cpp:1240-1285 | Folded: cases in `CheckDefaults` and `CheckUnusedBindingsInPattern`; split `fail_unused_without_definition`; the audit of every walker, which also added stringify's `PushCallArgs` case and found thunk.cpp's `ClonePattern`, fenced by the TODO for a pack in an interface function (W-229) | §0.2 M-24; §1.4 D-VA-5; §1.11 W-229; §2.4 (the audit); §2.6; §4 |
| A-m4: imported variadic lowering is unexercised | MINOR | By the precedent lower golden function/generic/import.carbon | Folded: `lib` and `use` splits in the lower golden | §2.6; §4; §7.1 R-6; §8.9 |
| B-M1: array storage requires `Core.Copy`, also of generic callers and forwarders | MAJOR | Yes (M-22, the trunk analog of the review's probes) | Folded with A-B2, with option (a), so no row narrowing is needed; check splits `generic_caller` and `forward_generic`; program variadics_generic_element | as A-B2; §1.4 D-VA-8 |
| B-M2: expansion arguments are reordered, unseen | MAJOR | As A-B1 | Folded with A-B1; variadics_arg_order has no C++ oracle, because C++ leaves the order unspecified | as A-B1; §1.8 |
| B-M3: no clang-tidy in §8; `NOLINTNEXTLINE` detached from `Dispatch` | MAJOR | Yes (M-23): rev 1's pattern_match.cpp:2325 fails `misc-no-recursion` | Folded: `DoPreWork` moved above the comment pair; `fx-c5` measured; the clang-tidy step in §8.6; hosted clangd-tidy in §8.9 | §0.2 M-23; §2.4; §8.6; §8.9 |
| B-M4: the decision-log entry is misplaced and thin | MAJOR | By fork/decision-log.md:9-11 and :2843-2863 | Folded: placement above the newest landed workstream entry; options considered; the V-3a register; the R6 sentence; verbatim commit messages for C3, C4, C5, R and D; the ORCHESTRATION row and paragraph | §1.9 D-VA-14; §2.8; §3 |
| B-m1: §8 commands do not run as written | MINOR | By the carbonbuild README's usage lines | Folded | §8.2; §8.4 |
| B-m2: MU-1 mispredicted; mutants were prose | MINOR | Yes: `Digits(1, 2, 3)` gives 13 | Folded: corrected, and every mutant an exact diff | §8.5 |
| B-m3: IN/OUT and coverage claims contradict the code | MINOR | Yes | Folded: DR-17 split, DR-15 N/A, the cleanup golden with the destroy prelude, the `...and` parse split, D-VA-12 and the outcome reworded | §1.2; §1.4 D-VA-6; §1.7; §2.6; §4 |
| B-m4: M-16 undercounts; the no-rename rationale is void | MINOR | Yes: 75 conflicts with a simulated refill (`$F/mt_sim.txt`); test_file.cpp:383-386 | Folded: the split renamed; M-16 and §6.2 count four added conflicts | §0.2 M-16; §1.7 D-VA-12; §2.6; §6.2; §7.2 A-9 |
| B-m5: residues blocked by an item that stays open | MINOR | Yes | Folded: `blocked_by` empty or the prerequisite residue, notes "Follows VA-1 slice 1" | §1.11; §2.8 |
| B-m6: later proposals unrecorded; DD-1's "Planned" line | MINOR | Yes: the grep's hits | Folded: the grep and its hits; p002274 in W-212, p002687 in W-222 and W-225; D-VA-14 on the design overview's lines | Head; §1.9; §1.11; §2.8 |
| B-m7: review count ambiguous; no `--all-files` prek | MINOR | Yes | Folded: two implementation reviews; R25's run before hand-over | §3 |
| B-m8: no fix-commit budget or shrink line | MINOR | Yes: UN-1 and OV-1's merges | Folded: three or four fix commits budgeted, and a named shrink line | §3 |
| B-m9: lines starting with a dash; upstream messages | MINOR | Yes: four lines | Folded: re-wrapped; D-VA-1 records the upstream messages as an exception | §0.2; §1.1; §2.1 |

## Review fold record (rev 3, 2026-10-14)

The focused re-review of rev 2 (be623188d) returned APPROVE-WITH-AMENDMENTS.
It verified both of review A's BLOCKERs RESOLVED: A-B1 by tracing review A's
`Digits(P(1), ... P(each x), P(9))` through the plan's code, which prints 1, 2,
3 and 9, with MU-7's prediction confirmed; A-B2 by `ConvertPackLiteralToPack`'s
value conversions and `BuildInfoForInst(PackType)`'s pointer representation,
with M-21 and M-22 reproduced on trunk. It also found §2.4's and §2.5's code
byte-identical to `fx-c4` and `fx-c5`, re-derived the EXPECT lines of
variadics_arg_order, variadics_no_copy and variadics_generic_element,
re-counted R31 (H1 1, H2 11, H3 38, 52 dash and 86 numbered items), ran
`runner.py --self-test` and `-fsyntax-only` on five files, and re-scanned the
ids (maximum W-244). It found no new BLOCKER, one MAJOR and three MINORs,
which it numbered VA1-RR-M1 and VA1-RR-m1 to VA1-RR-m3; this plan cites them
as RR-M1 and RR-m1 to RR-m3. A second fixer (R11) folded all four and rejected
none. The code finding was folded into the code of the new scratch branches
`rr-c4` and `rr-c5`, and §2's blocks were regenerated from them (§2.0, M-25),
never patched by hand. The container's disk had about 10 MB free, so the
branches were written with git's plumbing, no build or checkout was possible,
and RR-M1 stays hand-predicted, as the re-review's analysis was. Each amended
sentence is marked "(amended 2026-10-14, review fold: RR-n)". R31, outside
fenced code, rev 2 then rev 3: H1 1 and 1, H2 11 and 13 (this section and the
Sign-off), H3 38 and 38, dash items 52 and 52, numbered items 86 and 86; prek
ran to its fixpoint.

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| RR-M1: an expansion argument's pack type is never required complete per specific, so a converted forward crashes in lowering | MAJOR | By the cited code, hand-derived as the re-review was: type_completion.cpp:882-887 (`CompleteTypeOrCheckFail` records nothing for a symbolic type) against :889-912 (`RequireCompleteType` adds a `RequireCompleteType` instruction for one), eval_inst.cpp:795-818, convert.cpp:2536-2560 and function.cpp:426-440; no build exists | Folded with the re-review's fix: `RequireCompleteType` with a diagnostic context that adds nothing and a `CARBON_CHECK` on its result, since the element type is complete; lower split `forward_converted_field` (`Sum(... each h.w)`, a `«Wrap; N»` that nothing else requires; the lower golden's min prelude has no `i32` to `i64` conversion, so the re-review's `ToI32` form went to the program); variadics_forward's `Narrowed(4, 5, 6)`, EXPECT 456; mutant MU-8 (rev 2's call), which only that program catches | Head; §0.2 M-25; §1.2 DR-41; §1.4 D-VA-7; §1.5; §1.6; §1.8; §1.12; §2.0; §2.4; §2.6; §2.7; §3; §4; §5; §6; §8.0; §8.5; §8.7; §8.9; hand-off |
| RR-m1: the fold's design citations drift from the cited lines | MINOR | Yes: variadics.md:199-202 holds DR-21's sentence and :190-196 the `...and` loop; values.md:186-187 holds the value-binding rule and :184-185 the end of a code block | Folded: DR-21 cites `:199-202, :316-318`; DR-30 and D-VA-3 cite values.md `:186-187` | §1.2 DR-21, DR-30; §1.4 D-VA-3 |
| RR-m2: the walker audit understates where `ClonePattern` runs | MINOR | Yes: class.cpp:385-387 calls `BuildThunk` with `class_info.self_type_id`; thunk.cpp:462-467 skips the no-thunk shortcut whenever `override_self_type_id` has a value; handle_function.cpp:798-802 diagnoses `GenericVirtual` | Folded: the audit bullet names both kinds of thunk and the `GenericVirtual` guard; check split `fail_variadic_virtual` in fail_pack_expansion.carbon, predicted `error: generic virtual function [GenericVirtual]` | §2.4 (the audit); §2.6; §4 |
| RR-m3: descriptive text about the pack representation is inaccurate or stale | MINOR | Yes, by §2.4's `BuildInfoForInst(PackType)` hunk: always `MakePointerValueRepr`, tagged `ValueAndObjectAggregate` or `ValueAggregate` | Folded: the re-review's wording in D-VA-3, the D-VA-7 table, §0.1 row 15 and §2.4's type_completion.cpp note; A-6 says "the pack's storage" | §0.1; §1.4 D-VA-3, D-VA-7; §2.4; §7.2 A-6 |

## Sign-off

Three reviews, every finding folded or verified, none rejected:

| Review | Of | Verdict | Findings |
| --- | --- | --- | --- |
| Review A: architecture | rev 1 (aced921975) | REJECT | 7: 2 BLOCKER, 1 MAJOR, 4 MINOR; all folded in rev 2 (be623188d) |
| Review B: concreteness, process, Goodhart, scope honesty and cross-workstream | rev 1 (aced921975) | APPROVE-WITH-AMENDMENTS | 13: 4 MAJOR, 9 MINOR; all folded in rev 2 (be623188d) |
| Focused re-review | rev 2 (be623188d) | APPROVE-WITH-AMENDMENTS | 4 new: 1 MAJOR, 3 MINOR (RR-M1, RR-m1 to RR-m3), with review A's two BLOCKERs verified RESOLVED; the four folded in rev 3 (this revision) |

The re-review's verdict is not REJECT, and rev 3 folds all of its findings, so
the plan is signed off for implementation at rev 3: R29(c)'s two plan reviews
and the focused re-review that review A's REJECT required are complete. The
implementation follows §3: the cherry-picks C1 and C2, then C3, C4 and C5 from
§2.3 to §2.7 (the scratch branches `fx-c3`, `rr-c4` and `rr-c5`), each with its
fill, against §4's matrix and §5's delta, with §8's verification, the mutants
of §8.5 including MU-8, and two implementation reviews before the discharge.
Residues take ids from the W-212..W-231 reservation by the head's rule, after
its re-scan, and F-018 stays unminted. The row moves only as §2.8 says,
expected and not of record. Merge position: D-VA-15.

## Implementation review fold record (2026-10-14)

Two implementation reviews of ec0b1a7b0..9a0888ef0 (§3 item 11): review 1
(correctness and soundness; APPROVE-WITH-FIXES: two MAJOR and three MINOR
findings, numbered MAJOR-1, MAJOR-2 and MINOR-1 to MINOR-3) and review 2
(strictness, Goodhart and records readiness; APPROVE-WITH-FIXES: one MAJOR and
six MINOR findings, numbered VA1-IR2-M1 and VA1-IR2-m1 to VA1-IR2-m6). Review
1's MAJOR-2 and review 2's VA1-IR2-M1 are one defect, and so are review 1's
MINOR-2 and review 2's VA1-IR2-m2. A separate fixer (R11) reproduced every
finding on the reviewed toolchain (31d4183cd) with the reviews' probes, kept in
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va1-impl/fix/probes`,
folded all eleven and rejected none. The code findings are fix 3 (0ee9f2d1b,
"VA-1 fix: implementation review crashes and diagnostics") with its fill F6
(88b1b5bd2); the records findings are this plan's texts, the §2.8 ones being
what the discharge D copies. No W-id or F-id was minted. Each amended sentence
is marked "(amended 2026-10-14, implementation-review fold: <finding>)". R31,
outside fenced code, before then after this fold: H1 1 and 1, H2 13 and 14 (this
section), H3 38 and 38, dash items 52 and 52, numbered items 86 and 86; prek ran
to its fixpoint.

| Finding | Severity | Reproduced | Disposition | Where |
| --- | --- | --- | --- | --- |
| MAJOR-1: an expansion argument whose element type is an incomplete facet type aborts at a `CARBON_CHECK` (valid code), and the check's comment claims the element type is complete | MAJOR | Yes: `interface I; fn G(... unused each x: type) {} fn F(... each p: I*) { G(... *each p); }` aborts at handle_pack_expansion.cpp:257 (exit 134), as does the after-error form `fn F(... each p: I) { G(... each p); }` | Folded as the review proposed: `RequireCompleteType` diagnoses with the new context `IncompleteTypeInPackExpansion` ("forming a pack of incomplete type {0}", the element type), the expansion becomes an error, and the `CARBON_CHECK` and the false sentence are gone; splits `fail_incomplete_element` and `fail_incomplete_element_after_error`; MU-8's diff re-derived and re-run | §4; §8.5; toolchain/check/handle_pack_expansion.cpp, toolchain/diagnostics/kind.def |
| MAJOR-2 / VA1-IR2-M1: `GroupPackArguments` underflows `num_before` when a bound `self` is not the first explicit parameter, and aborts in `drop_front` (invalid code) | MAJOR | Yes: `class C { fn F(... each n: i64, self: Self); }` and `fn F[self: Self](... each n: i64, last: i64)` abort at the `ArrayRef::drop_front` assertion after their declaration errors, and `fn F[self: Self](... each n: i64)` counts "at least -1 arguments" | Folded with the review's better form: a bound `self` must match the first explicit parameter pattern, checked by name with `SemIR::IsSelfPattern` (which sees through import refs), and otherwise the call is not grouped, the declaration having been diagnosed (`SelfNotFirstParam`, `SelfInImplicitParamList`); splits `fail_self_after_pack` and `fail_self_in_implicit_list_with_pack` (both declarations of the implicit case, so the -1 count is pinned too) | §4; toolchain/check/call.cpp |
| MINOR-1: `PackExpansionBindingWithoutEach` suggests `each _` and `each self`, which do not parse | MINOR | Yes: `fn F(... _: i64) {}` and `class C { fn F(... self) {} }` | Folded: a name that is not an identifier gets the new `PackExpansionBindingNotIdentifier` ("... must declare an each-name, `each` followed by an identifier"), without a suggestion; splits `fail_underscore_without_each` and `fail_self_without_each` | §4; toolchain/check/handle_binding_pattern.cpp, toolchain/diagnostics/kind.def |
| MINOR-2 / VA1-IR2-m2: `fail_todo_overload_member` first hits the overload gate's misleading TODO, and it and `fail_without_each_name` carry unused-binding warnings | MINOR | Yes: the F4 fill shows both, and the probe `overload fn G(... unused each n: i64) {}` still gets the gate's TODO for `overload fn` with a non-value explicit parameter | Folded with the code option: gate (iii) of `DiagnoseOverloadGates` raises the slice's TODO "variadic member of an overload set" at the member's pack pattern, and call.cpp's guard stays for members declared elsewhere; both packs are `unused`; W-223's evidence names both sites | §2.8 W-223; §4; toolchain/check/handle_function.cpp |
| MINOR-3: an invalid pack element type leaves an error-valued pack pattern, so calls get a spurious arity or deduction error | MINOR | Yes, with a correction: the pattern is a `pack_expansion_pattern` whose constant value is an error (its binding has an error type), not `ErrorInst`; `F(1, 2)` gets "2 arguments passed to function expecting 1 argument" and `F(1)` "cannot deduce value for generic parameter `<pack arity>`" | Folded with the review's first option, narrowed: `FindPackExpansionParam` also finds a local pack pattern by its kind, and `GroupPackArguments` does not group a call to a pack whose constant value is an error, so the declaration's error is the only one; trunk's arity error for an ordinary error-typed parameter is unchanged; split `fail_invalid_element_type` with calls of 0, 1 and 2 arguments | §4; toolchain/check/call.cpp |
| VA1-IR2-m1: fix 1 and fix 2 came before the implementation reviews without their own fills, and edited golden sources §2.6 and §4 still describe | MINOR | Yes: the history and §3's D-VA-16 paragraph | Folded without rewriting history (AGENTS.md): §3 "As implemented" lists every commit and the shared fills; §2.6 "Sources of record" names each source change; §4 marks the renamed caller and the fills' extra output; §8.1 to §8.4 record the measurements; the decision-log text of §2.8 records the deviation for D | Head; §2.6; §2.8; §3; §4; §8.1 to §8.4 |
| VA1-IR2-m3: W-220's evidence names only `FinishPackExpansionBody`, which no longer raises the statement split's TODO | MINOR | Yes: since fix 1, `fail_todo_cleanup_statement`'s TODO comes from handle_expr_statement.cpp | Folded: W-220's first evidence string names `HandleParseNode(ExprStatementId)` for the statement split and `FinishPackExpansionBody` for the argument split | §2.8 W-220 |
| VA1-IR2-m4: ten ledger items cite docs/design/variadics.md lines valid only before C2, and the head's shift rule misses C2's table-of-contents line | MINOR | Yes: `git diff -U0 f67ab650d HEAD -- docs/design/variadics.md` inserts one line after :25 and 35 after :493; each re-derived range was checked line for line against f67ab650d's text | Folded: every variadics.md range in §2.8's JSON is the branch's after C2 (W-219 is :495-528), with a sentence saying so, and the head's rule is corrected | Head; §2.8 |
| VA1-IR2-m5: W-013's note would record call.cpp:424 for `GetExplicitArityRange`, which C4 moved | MINOR | Yes: :558 at 9a0888ef0, :578 at fix 3 | Folded: the note's line is a field D fills from the merge commit, beside ":424 at f67ab650d"; §0.3 item 3 says so | §0.3; §2.8 |
| VA1-IR2-m6: the decision-log text says rev 2 and omits the focused re-review and the implementation's deviations | MINOR | Yes | Folded: "rev 3 after two plan reviews and a focused re-review, all folded", a sentence on the three fix commits and the shared fills, and "Verified on the merge commit: <§8.8's run>" | §2.8 |

Verification of fix 3 and F6 (§8): `build.sh` and `install.sh` at fix 3 (273 of
273 ninja steps, because kind.def is an X-macro header; 0 warnings) and a
version-stamp relink at F6 (`0.0.0-0.dev+88b1b5bd2`). clang-tidy on fix 3's four
`.cpp` files: 0 diagnostics with `misc-no-recursion` and 0 with the
line-filtered `.clang-tidy` minus `modernize-*`. The gate at fix 3 alone: `1956
passed, 4 failed`, the four being fail_call.carbon, fail_each_name.carbon,
fail_pack_expansion.carbon and fail_todo_slice.carbon, with no crash. F6's
autoupdate: the second pass changed nothing, and every filled line is the one
§4's new and amended rows predict, the predictions having been written before
the fill. The gate after F6: `file_test test mode on /home/user/carbon-va: 1960
passed, 0 failed` (`Ran 1960 tests`, 0 `!` and 0 `?` marks). Conformance after
F6, with a private cache and output directory: PASS 137, COMPILE-FAIL 0,
LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 21 of 158;
bullets 49 PASS, 0 FAIL, 7 SKIP of 56. Every review probe re-run on F6's
toolchain: no crash, and each gives only its declaration's diagnostic or the new
one. An imported variadic method, called with a bound `self`, without one and
with an empty pack, compiles, links and prints 25, as derived by hand from 6, 9,
0 and 10. The mutants as §8.5's re-run says. prek on each commit's files,
nothing modified.

Not run, as §8.9 says: the Bazel-only tests (among them the diagnostics coverage
test, which the two new diagnostic kinds' splits serve), hosted CI, LLVM-side
assertions and the opt-mode conformance toolchain; §8.8 stays the discharge's.
One observation outside the findings, not changed: a pack whose element type is
invalid still gets a `pack_type` whose element operand is `invalid` in its
declaration's SemIR (no golden dumps one); fix 3 keeps every call away from it.
