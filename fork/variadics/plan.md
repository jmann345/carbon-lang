# Variadics plan: definition-checked variadics, slice 1 (VA-1)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 1, 2026-10-14, the planner's draft for the two plan reviews of
R29(c). Nothing below is implemented on this branch. Branch
`claude/carbon-fork-0-1-va`, cut from trunk f67ab650d, whose toolchain and core
trees equal upstream cut 0bdce60a5. Every line number below is against f67ab650d
unless a commit or branch is named. Every measured outcome in §0.2 was taken in
this container with the trunk toolchain (`/home/user/carbon-build/carbon-trunk`,
`carbon version` 0.0.0-0.dev+0bdce60a5), the upstream nightly 2026.10.12 (which
carries 2ec4bab59), the trunk build's own compiler flags, or the CI-pinned
clang-format 21.1.8, always in the planner's scratch directory
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/va1`
(`$V` below). No toolchain was built, nothing under /home/user/carbon-build was
modified, no worktree other than this one was touched (the scratch clone `$V/cp`
is a `git clone --shared` of /home/user/carbon-lang, read-only for that
repository), and the owner's runner was not used (R28). The prototype that §2
quotes exists only in that scratch clone, on branch `va1-impl` at dff8ef0b5,
with the per-commit states `va1-c3f`, `va1-c4f` and `va1-c5f` beside it (§2.0);
it is the source of every code block in §2, not a substitute for them.

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
subset: a function's explicit parameter list may contain one pack expansion
pattern `... each x: T` whose operand is a single each-name value binding of a
type `T` that names no pack (a concrete type or an earlier deduced parameter);
the body may contain pack expansion statements whose body is an expression
statement, and calls may pass pack expansion arguments `... expression`; the
arity is a deduced parameter of the callee (the design's explicit deduced
arity), deduced at each call from the run of arguments the pattern matches; the
body is checked once, against the pack's element type, which is the design's
iterative typechecking for a pack of one segment; and each specific is lowered
by running the expansion body once per element, which is the design's execution
at monomorphization. Upstream's own start on variadics, 2ec4bab59 and a045da8e6,
is cherry-picked as commits 1 and 2 with upstream authorship, so the fork's node
kinds, token kinds and check entry points are upstream's (D-VA-1). Every other
form the design gives is either diagnosed as a `semantics TODO` with a golden or
rejected with the design's own rule, and filed from W-212 (§1.11). The SKIP
program un-SKIPs to PASS with its EXPECT values 6 and 0 unchanged and re-derived
by hand (§1.6, R16(d)), five new programs (one with a C++17 differential oracle)
join it, twelve new goldens and one refill are added, and the row moves
DESIGN-ONLY to PARTIAL, expected, not of record, with the header delta PARTIAL
plus one and DESIGN-ONLY minus one (§2.8). The implementation lands in five
implementation commits, each of which compiles at the syntax level today (M-11)
and is planned to build and pass the gate together with its fill commit (§3).

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

The ledger maximum on any ref is W-232 (filed by SC-1 round 9 on the sc branch,
named on the op2 branch); W-202..W-211 are OX-1's reservation; W-212..W-231 and
F-018 are named on trunk 44761146d and the dd branch only as VA-1's reservation
("reserves W-212 to W-231 and F-018 if minted", fork/ORCHESTRATION.md on
trunk), and F-017 only as OX-1's. **VA-1 reserves W-212..W-231** (twenty ids):
W-212..W-228 are the residues of §1.11, W-229..W-231 are spares for a residue
the reviews find, and an unused reserved id stays unused and is never reused.
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
    after commit 2 adds a045da8e6's "Type versus execution semantics" after
    :492, so every citation past :492 is +36 after commit 2): "Packs and
    each-names" (:83-101), "Pack expansions" (:103-157), "Pack expansion
    expressions and statements" (:159-202), "Pack expansion patterns"
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
shapes rather than waiting for upstream's (D-VA-1, §7 A-3).

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
| 10 | Tuple to array | LANDED | toolchain/check/convert.cpp:411 `ConvertTupleToArray`, dispatched at :1782; it uses a tuple literal's elements directly and otherwise indexes a materialized tuple. |
| 11 | Specifics in lowering | LANDED | toolchain/lower/file_context.cpp:531 `BuildFunctionDefinition` and :548 `BuildFunctionBody` lower one body per specific; toolchain/lower/function_context.cpp:68 `LowerBlockContents`; `SetLocal` (function_context.h:140) refuses a duplicate local. |
| 12 | Prelude tuple Copy | LANDED, hand-written | core/prelude/copy.carbon:49-71: "TODO: Implement tuple copy as a variadic generic impl." then impls for `()`, `(T,)`, `(T, U)` and `(T, U, V)`. There is no core/prelude/types/tuple.carbon (the brief's path does not exist; `ls core/prelude/types` lists none). |
| 13 | Arbiter | SKIP | fork/conformance/programs/generics/variadics_each.carbon: body commented out, `Run` returns 1, SKIP reason "no `...`/`each` tokens exist in toolchain/lex/token_kind.def". |
| 14 | Design | COMPLETE | docs/design/variadics.md, 964 lines; upstream a045da8e6 adds 36 (M-5). |

### §0.2 Measurements

Setup: `XDG_CACHE_HOME` is `$V/xdg-trunk` for the trunk toolchain
(`/home/user/carbon-build/carbon-trunk/install/bin/carbon`, `$T` below) and
`$V/xdg-nightly` for the nightly
(`/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon`,
`$N` below). Probe sources live in `$V/probes`. C++ prototypes were not
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
`... each n ...expand ...and ...or . .. ....`; `--phase=lex --dump-tokens
--omit-file-boundary-tokens` gives, on the nightly, `PeriodPeriodPeriod`,
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

**M-7. Arrays as pack storage, on trunk.** `$V/probes/arith.carbon` declares
`fn Len[N: Core.IntLiteral](unused a: array(i64, N)) -> i32 { return N; }`,
`Fwd` (forwards its array to `Len`) and `Idx` (returns `a[0]`), and prints
`Fwd` of a three-element array, `Idx` of it, and `Len` of an empty
`array(i64, 0)`: output `3`, `1`, `0`, exit 0. `$V/probes/arr.carbon` deduces
`N` from `array(i64, 3)` initialized from a tuple literal: output `0`, `1`. A
variant declaring `var b: array(i64, N + 1);` fails: "array bound is not a
constant". So a deduced `Core.IntLiteral` bound deduces, forwards, indexes and
may be zero, and has no arithmetic in a type, which is why merging segments
(arity `N + k`) is a TODO (D-VA-4, W-215).

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
`$V/bin/synchk.py` runs `clang++ <trunk cflags> <per-object extra flags>
-fsyntax-only` (the `cxx`, `cflags` and `extra` of
/home/user/carbon-build/carbon-trunk/build.ninja, include root switched to the
tree under test) over the 315 Carbon translation units of that build
(`$V/all_tus.txt`). Results: the prototype's final state, `315 files, 0
failed`; every file edited after that sweep started, re-run alone with the same
flags (check/handle_pack_expansion.cpp, handle_name.cpp, type.cpp, call.cpp,
check_unit.cpp, diagnostics/kind.cpp, lower/handle.cpp,
lower/function_context.cpp): 0 failed; the new
toolchain/lower/handle_pack_expansion.cpp, which the trunk build does not list,
with the `extra` flags of lower/handle.cpp: rc 0. The commit-3 and commit-4
states (`va1-c3`, `va1-c4`) are swept the same way in §8.0; the result is
recorded there. `-fsyntax-only` with `-Werror -Wall -Wextra` covers every
template instantiation and `consteval` table (the node-stack id-kind table, the
per-kind lowering and stringify dispatch) but not code generation or linking.

**M-12. Formatting.** After one `clang-format -i` (21.1.8, the
.pre-commit-config.yaml pin) of the 42 changed C++ and `.def` files,
`clang-format --dry-run -Werror` passes on all of them; the reformat re-wrapped
14 files (53 lines added, 59 removed) and reordered no `#include`. The base
files were clean before the edits.

**M-13. Diagnostics registry.** `uv run --python 3.12 --no-project python
toolchain/diagnostics/check_diagnostics.py` (the host Python 3.11 lacks
`typing.override`) passes on the prototype; renaming one new kind in kind.def
makes it print "Unused diagnostic: PreviousPackExpansionPatternX" (negative
control).

**M-14. Conformance headers.** With §2.7's six programs copied into the scratch
clone and `runner.py --update-readme-table` run ("updated program table in
README.md (155 programs)"), `runner.py --self-test` prints "self-test: 155
programs parsed, 56 bullets in table, OK"; before the table update it reports
the README table stale, as it must.

**M-15. Collisions.** In `$V/cp`, with every `claude/carbon-fork-0-1-*` branch
of /home/user/carbon-lang fetched as `lc/claude/*`, `git merge-tree
--write-tree --name-only <branch> <prototype>` against the prototype (7328f804d,
whose toolchain files equal the final ones but for formatting and three later
hunks) is compared with the same command against f67ab650d, so that conflicts
the branch already has with trunk are not counted: §6.2's table. No branch
gains a conflict.

**M-16. The next upstream advance.** `git merge-tree --write-tree --name-only
up/trunk <tree>` (up/trunk is 66a250ad9): 71 conflicted files for f67ab650d, 71
for f67ab650d plus the two cherry-picks (they neither add nor remove one), 74
for the prototype. The three added are toolchain/check/handle_pack_expansion.cpp
(both sides add the file; the fork's version contains upstream's three handlers,
one of them unchanged and two replaced), toolchain/parse/node_kind.def and
toolchain/parse/typed_nodes.h (both sides insert after the same
`PackExpansionStatement` lines, upstream nothing and the fork its new kinds).
Each resolves by taking the fork's side, which contains upstream's lines
verbatim.

**M-17. The C++ oracle.** `/home/user/llvm/bin/clang++ -std=c++17 -pthread`
of §2.7's variadics_sum_diff.diff.cpp, run: `123`, `11`, `0`, `30`, `0`, exit
0, which are the values §1.6 derives by hand.

**M-18. Ids.** The re-scan in the head: maximum W-232; W-212..W-231 and F-018
named only as VA-1's reservation; F-017 only as OX-1's.

**M-19. Why a full build is needed.** From `ninja -t deps` of the trunk build
(319 objects): token_kind.def is a dependency of 254 objects, node_kind.def of
244, state.def of 42, typed_nodes.h of 186, inst_kind.def of 177,
typed_insts.h of 176, check/node_stack.h of 106 and diagnostics/kind.def of
268.

**M-20. Lowering conventions the slice relies on.** The `ArrayIndex` lowering
(toolchain/lower/handle.cpp:46-74) reads an `IntLiteral` index from its constant
value and any other index with `GetValue`, and adds the index to the specific's
fingerprint (`AddIntToCurrentFingerprint`, function_context.cpp:590); the
specific coalescer merges two specifics whose fingerprints match
(specific_coalescer.h: "Two function definitions, from the same generic, with
different specific_ids are considered equivalent if, at the LLVM level, one can
be replaced with the other"). So a loop count that depends on the specific must
be fingerprinted (D-VA-9).

### §0.3 Ledger, row and brief claims found stale (each corrected where §2 says)

1.  Row 53 and the arbiter's SKIP reason say "no `...`/`each` tokens exist in
    token_kind.def"; after commit 1 `...` exists (from upstream), and after
    commit 3 `each` does. Both texts are replaced by commits C5 and R (§2.7,
    §2.8).
2.  The brief names core/prelude/types/tuple.carbon for the tuple Copy impls;
    they are in core/prelude/copy.carbon:49-71 (§0.1 row 12).
3.  W-013's notes cite `GetExplicitArityRange` at toolchain/check/call.cpp:338;
    it is at :424 at f67ab650d. The discharge corrects the citation (§2.8).
4.  The arbiter's commented body would not compile even with variadics, because
    it prints an `i64` with `Core.Print` (M-8). The un-SKIP repairs it with `as
    i32` and says so in the header (R10, R16(d)).
5.  gap-analysis.md's W6 arbiter ("the worked examples in
    docs/design/variadics.md compile and execute; core/prelude tuple Copy/Eq
    rewritten as a single variadic impl") is the whole item's, not this
    slice's; the discharge keeps it and adds the slice's sentence (§2.8).

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
_Break condition:_ the next upstream advance shows a conflict in a file the
cherry-picks touched that taking the fork's side does not resolve, or upstream
reverts or reshapes 2ec4bab59's node kinds before VA-1 merges.

### §1.2 The design's rules, each IN or OUT of this slice

Numbered DR-n so that §1.11 and the reviews can cite them; line numbers are
docs/design/variadics.md at f67ab650d. IN means implemented and covered by a
golden or program in §4 and §5; OUT means diagnosed (by the design's own rule
where it gives one, otherwise by a `semantics TODO` with a golden) and filed.

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
    elements have one type; packs of different types **OUT** (W-212). The
    second half is enforced: a pack's name without `each` is an error
    (D-VA-11).
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
    `expand` (:141-144). A convention; nothing to implement.
16. DR-16. All each-names in one expansion name packs of the same arity
    (:146-147). **IN**: an expansion takes the arity of its first each-name,
    and a different arity is a TODO that the slice cannot reach, because a
    function has at most one pack (W-222).
17. DR-17. An expansion without each-names must be a pattern, or an
    expression in the type position of a binding pattern (:147-149). **IN**
    for patterns and for the error (`PackExpansionWithoutEachName`); the
    type-position form **OUT** (W-212).
18. DR-18. A pack expansion cannot contain another pack expansion or
    `...expand` (:151-152). **IN** (`NestedPackExpansion` with the note
    `EnclosingPackExpansion`); the `...expand` half is **OUT** with W-217.
19. DR-19. An each-name cannot be used in the expansion that declares it
    (:154-157). **IN**, vacuously: the slice's only declaring expansion is a
    parameter whose name is not in scope in its own type.
20. DR-20. An expansion is a loop run at monomorphization over the pack index
    0 to N - 1 (:161-167, :298-302). **IN** (D-VA-9).
21. DR-21. `...` in a tuple literal behaves like N comma-separated elements
    (:190-193, :316-318). **IN** for call arguments.
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
    from 0 (:339-344). **IN**.
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
    (`arity` in SemIR) and has type `Core.IntLiteral`.
39. DR-39. `Arity` supports only `+` (:664-668). **OUT** (W-215); the slice's
    arity has no `+` (M-7).
40. DR-40. The type of an each-name expression is its binding's type
    expression; the type of a pack expansion is `...B`; `each x: auto` invents
    `each __X` (:694-714). **IN** for the first two (an expansion's type is the
    `PackType` of its body's type); `auto` **OUT** (W-212).
41. DR-41. Reduction and equivalence rules (:716-805). **IN** only "Expansion
    convertibility" (:794-796) for one segment, `...T` converting to `...U` of
    equal arity when `T` converts to `U` (each element converts as it is
    stored); the rest **OUT** (W-212, W-215).

### §1.3 The slice and its syntax (D-VA-2, D-VA-10)

**D-VA-2 (the slice).** A function may have, in its explicit parameter list,
one pack expansion pattern whose operand is one each-name value binding of a
type that names no pack: `... each n: i64`, or `... each next: T` with `T` an
earlier deduced parameter, before, between or after ordinary parameters. Its
body may contain pack expansion statements over that pack whose body is an
expression statement without control flow or cleanups, and its calls (and
calls elsewhere) may pass pack expansion arguments `... e` where `e` uses
each-names of the enclosing function's pack. That is the design's machinery
(DR-1..DR-10, DR-16..DR-33, DR-37, DR-38, DR-40, DR-41) restricted to packs of
one segment, which is everything the arbiter and the design's SumInts and
MiddleVariadic examples (:241-246, :281-283) need, and it is a real definition
check: the generic body is checked once against the pack type, never per call.
The design's StrCat, Zip, Min, Apply and TupleConcat examples need W-212,
W-213, W-215 or W-218 and are the next slices' arbiters (§1.11). *Break
condition:* a reviewer shows a form inside this boundary that the prototype
mis-checks or that lowers to the wrong number or order of evaluations.

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
D-VA-4, D-VA-5 and D-VA-6, each a `semantics TODO: <label>` from
`context.TODO`, which ends checking of the file as every TODO does; and the
design's own errors, which recover where the parse allows and otherwise end
checking (a nested expansion, a second pattern expansion and a pattern binding
without `each` return `false` after their diagnostic, because the enclosing
pattern or expansion has no meaning to recover to).

**D-VA-10 (`each` is a keyword).** `CARBON_KEYWORD_TOKEN(Each, "each")` joins
token_kind.def, as the design says (:46-47, :91) and as the fork's and
upstream's editor grammars already list it (M-10); no existing Carbon source in
the fork uses `each` as a name (M-10), and a program that needs one can write
`r#each` (lex golden `each.carbon`). Upstream's lexer does not have it yet
(M-3). _Break condition:_ upstream lands variadics with `each` as a contextual
identifier rather than a keyword, in which case the fork follows upstream at
the advance and the lex golden is refilled.

### §1.4 SemIR and checking (D-VA-3..D-VA-8, D-VA-11)

**D-VA-3 (the arity and the pack's storage).** Following "Explicit deduced
arities" (DR-38), checking the `...` of a pattern expansion adds a deduced
symbolic binding pattern to the enclosing full pattern, before the operand: its
name is the new special name `NameId::PackArity` (spelled `arity` in SemIR and
`<pack arity>` in diagnostics, toolchain/sem_ir/name.cpp), its type is
`Core.IntLiteral`, which plays the design's `Arity` without its `+` (DR-39), and
it is never added to name lookup, so no source can name it and no unused-binding
warning can fire on it (AddBindingPattern adds no lookup entry,
toolchain/check/pattern.cpp:165-215). The each-name binding `each n: E` inside
the expansion is then declared with the type `array(E, N)`, `N` being that
arity binding: the design's rewrite of `each X: T` to `each X: «T; __N»`, with
the coercion's run-time storage made an array, the one built-in type whose
bound can be a deduced `Core.IntLiteral` today and which already deduces,
forwards, indexes and is empty-safe (M-7). The expansion pattern itself is a new
`PackExpansionPattern` whose scrutinee type is the new `PackType` `«E; N»` (the
coercion as a type). So `n`'s storage is one array value per call, an each-name
use `each n` is that array indexed by the pack index (DR-27), and a specific of
the function knows `N`. _Break condition:_ a pack whose elements need a
representation an array of `E` cannot give (different element types, W-212, or
reference elements, W-221) enters the slice, or array value representation
stops being a pointer for some `array(E, N)`, which `ValueAsRef` requires.

**D-VA-4 (the call groups the pack's arguments).** Before deduction,
`PerformCallToFunction` groups the arguments of a callee with a pack expansion
pattern (`GroupPackArguments`, call.cpp): the arguments before and after the
pattern's position match the parameters before and after it one to one (DR-29,
with the bound `self` first, as `GetExplicitArityRange` counts it), and the run
between them becomes the pattern's single scrutinee. A run of ordinary arguments
becomes a new `PackLiteral` whose type is the tuple of their types (the design's
pack literal of one-element segments, DR-31); a run that is exactly one pack
expansion argument is passed as that `PackExpansionExpr` (forwarding, DR-37).
Deduction (deduce.cpp, a new `PackType` case) deduces `N` as the literal's
element count, or as the forwarded expansion's arity, and the element type
against each element type (so `[T: type](first: T, ... each next: T)` deduces
`T` from every element). Conversion to the parameter's array type then converts
a `PackLiteral` element by element with the existing tuple-to-array path (`ConvertTupleToArray`
now also reads a `PackLiteral`'s elements directly) and a `PackExpansionExpr` by
a new `PackExpansionInit` that runs the expansion's body once per element into
the array (`ConvertPackExpansionToArray`, convert.cpp; DR-41's expansion
convertibility). Three forms are TODOs, each with a golden: an expansion
argument merged with other arguments for one pack (its arity is `N + k`, which
needs DR-39's `+`, W-215); a pack expansion in a tuple literal that is not a
call's argument list (its type is a tuple with a pack segment, W-213); and an
expansion argument, or a variadic member, in a call to an overload set (the
probe of each member would group per member, W-223). The design's own errors at
a call are `CallArgCountTooFewForPack` (with the note `InCallToVariadicFunction`
on the callee), `PackExpansionArgForSingularParam` (an expansion cannot match a
non-pack parameter, because its arity is unknown until monomorphization) and
`PackExpansionArgWithoutPackParam` (the callee has no pack expansion parameter).
_Break condition:_ a call inside the slice whose grouped scrutinee deduces a
different arity, or converts its elements in a different order, from the
design's left-to-right iterative match (DR-30).

**D-VA-5 (what check refuses in the slice).** Each of these is a `semantics
TODO` with a fail_todo golden (§4): a pack expansion pattern outside a
function's explicit parameter list (implicit lists, tuple patterns; W-212,
W-214); an operand that is not exactly one each-name binding (W-221); an
each-name binding that is `ref`, `var` or carries a phase keyword (W-221); two
each-names in one operand (W-221); an expansion over packs of different arities
(defensive; W-222); a pack expansion argument in a template-dependent call
(W-224). _Break condition:_ any of these forms turns out to be needed by a
program the gap row's bullet requires for PARTIAL, which would make the slice
too small to move the row.

**D-VA-6 (the body of an expansion is straight-line).** A statement or
expression expansion is checked into its own instruction block, which lowering
runs once per element. That block must stay one block and own no cleanup: the
body's statement must be an expression statement (a declaration would introduce
a name, and so storage, per element; W-218), it must not branch (`and`, `or`,
`if` expressions add blocks; W-219), and it must not create a temporary that
needs destroying (W-220). Each is checked when the expansion ends and is a TODO
with a golden. _Break condition:_ a lowering of a straight-line body that
depends on a value computed in an earlier iteration through anything other than
memory (a stale SSA value), which would show up as a wrong program result in
§5's mutants.

**D-VA-7 (seven new instructions).** All in typed_insts.h, listed in
inst_kind.def alphabetically, each with a formatter, namer and (for the type)
stringify case (§2.4):

| Inst (ir_name) | Fields | Constant kind | Category | Lowered as |
| --- | --- | --- | --- | --- |
| `PackType` (`pack_type`) | `type_id` (always `type`), `element_type_inst_id`, `arity_id` | `WheneverPossible`, `is_type` always, `deduce_through` | type | never a run-time type: `BuildTypeForInst` is a fatal error, as for `PatternType` |
| `PackExpansionPattern` (`pack_expansion_pattern`) | `type_id` (pattern type of a `PackType`), `subpattern_id`, `arity_pattern_id` | `Always` | pattern | not lowered (`is_lowered = false`) |
| `PackExpansionStatement` (`pack_expansion_statement`) | `arity_id`, `body_block_id` | `Never` | not an expression | the body, `arity` times |
| `PackExpansionExpr` (`pack_expansion_expr`) | `type_id` (a `PackType`), `body_block_id`, `result_id` | `Never` | value | nothing; the `PackExpansionInit` that consumes it runs the body |
| `PackExpansionInit` (`pack_expansion_init`) | `type_id` (an array type), `body_block_id`, `dest_id` | `Never` | initializing | the body, once per array element, then the destination |
| `PackIndex` (`pack_index`) | `type_id` (`Core.IntLiteral`) | `Never` | value | the current iteration's index as an `i64` constant |
| `PackLiteral` (`pack_literal`) | `type_id` (a tuple type), `elements_id` | `Never` | mixed | nothing; it is always converted element by element |

`PackType` prints as `«E; N»` (toolchain/sem_ir/stringify.cpp), the design's
arity coercion (DR-31), and imports (import_ref.cpp), as does
`PackExpansionPattern`, so an imported variadic function can be called
(golden `import.carbon`); a redeclaration compares the two patterns' operands
and arity patterns (merge.cpp, golden split `redecl.carbon`). The SemIR
verifier (dominance.cpp) treats an expansion's body as evaluated in place and
forgets what it defined when the expansion ends, since the body runs once per
element and nothing in it dominates the code after it. The design's
type/execution discrepancy (DR-34) does not arise: a `PackExpansionExpr` has a
pack type only as the operand of the conversion that consumes it, and no
instruction ever holds a pack value. _Break condition:_ the formatted SemIR of
a golden shows an expansion body evaluated outside its expansion, or the
verifier rejects a body the slice accepts.

**D-VA-8 (definition checking).** The body of a variadic function is checked
once, when it is defined, as any generic body is: `each n` is an
`ArrayIndex` of the pack's array at a `PackIndex`, converted to a value, and so
has the element type `E` (a concrete type, or the symbolic `T` of
`[T: type](... each next: T)`); every operation on it is checked against `E`
with the ordinary rules, and an error is diagnosed at the definition whatever
the calls. This is the design's iterative typechecking (DR-32: "within a given
iteration, typechecking follows the usual rules of non-variadic typechecking,
except that when we need the type of an each-name, we use the scalar component
of the current segment of its type") for the one case the slice admits, a pack
type of one segment `«E; N»`, whose only scalar component is `E`: one segment,
one iteration of the typechecking loop. The body is never re-checked per call
or per specific; a specific only substitutes `N` and `T`. _Break condition:_ a
body the design's typechecking would reject is accepted for a one-segment pack,
or the reverse.

**D-VA-11 (a pack's name without `each`).** Naming a pack without `each` is an
error, `PackNameWithoutEach` ("pack `{0}` can only be referred to as `each {0}`
inside a pack expansion"): the design gives such a use no meaning ("no run-time
expression evaluates to a pack", :87-88), and p002240 considered and did not
adopt the alternative that would give it one ("Omit each-names", :555-657).
Name lookup of an identifier expression checks the found binding against the
file's packs (`Context::pack_binding_arities`), at the cost of one hash lookup
per identifier expression; otherwise it builds the same name reference as
before (handle_name.cpp's `HandleNameAsExpr` inlined, M-11). _Break condition:_
upstream gives a pack's bare name a meaning (an operation on the whole
sequence), in which case the diagnostic becomes that operation.

### §1.5 Lowering (D-VA-9)

**D-VA-9.** A variadic function always has its arity binding, so it is always
generic, and lowering already lowers one body per specific (§0.1 row 11): a call
`Sum(1, 2, 3)` makes the specific `N = 3`, `Sum()` the specific `N = 0`. Within
a specific, `PackExpansionStatement` reads its `arity_id` in the specific
(`GetConstantValueInSpecific`, which must be concrete there) and
`PackExpansionInit` reads its array type's bound; both call
`FunctionContext::LowerPackExpansionBody(arity, block)`, which lowers the body's
instructions `arity` times in order, the pack index taking each value from 0 to
`arity` minus 1, and after each iteration erases from `locals_` every value the
iteration set, so that the next iteration lowers the same instructions afresh (`SetLocal`
refuses duplicates). `PackIndex` lowers to `ConstantInt(i64, index)`, and
`ArrayIndex` takes it through its non-constant path (it excludes `PackIndex`
from the `IntLiteral` constant path, which reads a constant value a `PackIndex`
does not have). The arity is added to the specific's fingerprint, so the
coalescer never merges two specifics that run a different number of iterations
(M-20). The empty pack runs no iteration, and its array is `array(E, 0)` (M-7).
This is the design's execution model exactly ("These semantics are implemented
at monomorphization time, so the value of N is a known integer constant",
:300-301), and no run-time loop is emitted. Nested expansions cannot reach
lowering (check rejects them, DR-18), and lowering CHECKs that. _Break
condition:_ a specific's lowered body evaluates an expansion body a number of
times other than its arity, or in another order, which §8's mutants are built to
detect.

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

**variadics_forward** (123, 246, 0, 8). `Digits(... each d)` with `total`
from 0 gives the decimal number whose digits are the arguments in order.
`Forward(1, 2, 3)` calls `Digits(... each d)`, which "behaves like a series of
comma-separated tuple elements" (DR-21): `Digits(1, 2, 3)` = 123. `Doubled(1,
2, 3)` calls `Digits(... each d + each d)` = `Digits(2, 4, 6)` = 246.
`Forward()` calls `Digits()` = 0. `Doubled(4)` = `Digits(8)` = 8.

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

### §1.7 Goldens (D-VA-12)

**D-VA-12.** Twelve new golden files, each a source with `// AUTOUPDATE` and no
CHECK line (R15, R16(a)), with a `fail_` split for every new diagnostic and
every new TODO (§4): toolchain/lex/testdata/each.carbon;
toolchain/parse/testdata/variadics/each.carbon, pack_expansion_expr.carbon and
pack_expansion_pattern.carbon; toolchain/check/testdata/variadics/
each_param.carbon, forward.carbon, import.carbon, fail_call.carbon,
fail_each_name.carbon, fail_pack_expansion.carbon and fail_todo_slice.carbon;
toolchain/lower/testdata/variadics/pack_expansion.carbon. Upstream's four
goldens arrive with commit 1 carrying upstream's CHECK lines. One of them,
toolchain/check/testdata/variadics/pack_expansion.carbon, changes output in
commit 4: its split `fail_todo_pack_expansion_statement.carbon` (`... F();`
in `fn F()`) stops being the TODO `HandlePackExpansionStart` and becomes the
design's error `PackExpansionWithoutEachName`. It is refilled by autoupdate in
commit F4 and **not renamed**, although its `fail_todo_` prefix becomes
inaccurate, because a rename is a conflict at the next advance in a file
upstream will itself rewrite when it checks expansions (W-212's notes record the
rename for that advance). _Break condition:_ file_test rejects a `fail_todo_`
split whose output has no TODO, which would force the rename now.

### §1.8 Conformance programs (D-VA-13)

**D-VA-13.** The arbiter un-SKIPs and five programs join it, all under the
bullet "Generics: Definition-checked variadics", each 10 to 45 lines, each
arbitrating one concept, each EXPECT derived in §1.6:

| Program | Concept | EXPECT |
| --- | --- | --- |
| generics/variadics_each.carbon (un-SKIP) | statement expansion over a parameter pack, arity 3 and 0 | 6, 0 |
| generics/variadics_fixed_params.carbon (new) | a pack between fixed parameters (DR-29), iteration order | 12, 123, 4321 |
| generics/variadics_forward.carbon (new) | forwarding `... each d` and an expression expansion argument to another variadic function | 123, 246, 0, 8 |
| generics/variadics_empty_pack.carbon (new) | a side-effecting statement expansion runs once per element and never for an empty pack, directly and forwarded | 7, 1, 2, 9 |
| generics/variadics_expansion_args.carbon (new) | an expansion argument between fixed arguments (the call's argument list as a tuple literal of segments) | 19, 1239, 15559 |
| generics/variadics_sum_diff.carbon + .diff.cpp (new) | Horner and a forwarded expression expansion against C++17 variadic templates and comma folds | oracle: 123, 11, 0, 30, 0 |

The harness has no compile-failure EXPECT (fork/conformance/README.md:90-98
lists the directives, and :208-212 makes COMPILE-FAIL a failing status), so
every diagnostic is arbitrated by a `fail_` golden instead. The differential
pair is the agreeing direction only:
Carbon's statement expansion and C++'s comma fold both evaluate left to right,
there is no documented divergence, and so R30's both-sides rule does not apply.
No program needs the heterogeneous or multi-pack forms (OUT, W-212, W-222).
_Break condition:_ a program passes against a toolchain whose expansion count
or order is wrong (§8.5's mutants), which would make it vacuous.

### §1.9 Docs and records (D-VA-14)

**D-VA-14.** No design doc changes beyond commit 2's upstream text: every rule
the slice implements is the design's, every rule it omits is a filed limit of
the implementation, not a language rule, and the fork mints no design decision
(F-018 unallocated). A "0.1 limits" section in docs/design/variadics.md was
considered and rejected, because the limits are temporary implementation gaps
tracked in the ledger, and an edit to that file is a conflict at the next
advance in a file upstream is actively changing (a045da8e6). Records, written
by commits R and D (§3, §2.8): row 53 moves DESIGN-ONLY to PARTIAL, expected,
not of record, with a new evidence text; the header's counts move PARTIAL +1
and DESIGN-ONLY -1 from whatever they read at the merge commit; gap-analysis.md
§W6 gains the slice's sentence; W-013 stays open, its notes record the slice and
name the next slice (W-212, then W-213 and W-218); W-212..W-228 are filed
(§1.11); fork/decision-log.md gains the entry "VA-1" (D-VA-1..D-VA-16, newest
first under Decided); fork/ORCHESTRATION.md and fork/conformance/README.md are
updated. _Break condition:_ a review shows the slice deciding a rule the design
leaves open, which mints F-018 with a dated amendment to variadics.md.

### §1.10 Merge position (D-VA-15)

**D-VA-15.** VA-1 is cut from trunk (f67ab650d), not stacked, and merges after
DD-1 and OX-1, in the order fork/ORCHESTRATION.md on trunk 44761146d records:
"PR 53, PR 51, PR 52, SC-1, PR 54, PR 55, PR 56, PR 57, then DD-1; OX-1 and
VA-1 after DD-1 in the order their PRs open"; its row there says "merges after
OX-1 or DD-1, whichever is later". Before the discharge it merges trunk with a
merge commit, never a rebase (AGENTS.md), and re-verifies on the merge commit
(§8.8). _Break condition:_ a branch ahead of VA-1 in that order gains a
conflict with it that §6.2's re-measurement at merge time shows cannot be
resolved by the rules there.

### §1.11 Residues filed (W-212..W-228; W-229..W-231 spare)

Each is filed by commit D with bullet "Generics: Definition-checked variadics"
unless another is named, the design text it implements, its blocking evidence
(the TODO label or diagnostic and its golden split), and `blocked_by` W-013's
slice 1:

1.  W-212: generic and heterogeneous packs. Pack expansion patterns in implicit
    parameter lists (`[... each T: type]`), binding types that use an each-name
    (`... each x: each T`), `each x: auto` (an invented `each __X`), and the
    multi-segment shapes, pack literals and segment-by-segment typechecking
    they need (DR-4, DR-11, DR-17, DR-24, DR-31, DR-32, DR-40). Evidence:
    `fail_todo_generic_pack`. The design's StrCat (:251-259) is its arbiter.
    Notes: rename upstream's `fail_todo_pack_expansion_statement` split at the
    advance that brings upstream's own check (D-VA-12).
2.  W-213: tuples with pack segments. `(... each x)` outside a call's argument
    list, tuple types `(... each T)`, tuple-typed parameters (DR-9, DR-14,
    DR-33). Evidence: `fail_todo_tuple_literal`. Arbiters: Zip's return
    (:70-82), Apply (:274-278), TupleConcat (:288-292).
3.  W-214: pack expansion patterns in tuple patterns that are not a function's
    explicit parameter list: `let`, `var`, `match` and nested tuple patterns
    (DR-10). Evidence: `fail_todo_tuple_pattern`.
4.  W-215: segment merging and splitting. An expansion argument merged with
    other arguments for one pack (arity `N + k`), the `Arity` type's `+`, the
    canonical form of full patterns, and default arguments next to a pack
    (DR-36, DR-37, DR-39, DR-41). Evidence: `fail_todo_merged_segments`; M-7.
5.  W-216: `...and` and `...or` (DR-12, DR-33). Evidence: they fail to parse.
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
9.  W-220: per-element cleanups: an expansion body that creates a temporary
    needing destruction (D-VA-6). Evidence: the TODO label "pack expansion
    element that needs a cleanup" (handle_pack_expansion.cpp,
    `FinishPackExpansionBody`); no golden yet, because the slice's goldens use
    only types without destructors.
10. W-221: each-name bindings that are `ref`, `var`, `template` or `generic`,
    and expansion operands that are not one each-name binding, such as
    `... (each c: bool, each x: i32)` (DR-25, DR-34). Evidence:
    `fail_todo_ref_pack`, `fail_todo_two_each_names`,
    `fail_todo_tuple_operand`.
11. W-222: more than one pack: fixed-arity expansions (`class C(... each T:
    type)`), packs in two parameter lists of one function, and the same-arity
    rule across packs (DR-16, DR-35). Evidence: the TODO label "pack expansion
    over packs of different arities".
12. W-223: variadic members of `overload fn` sets and pack expansion arguments
    to them; OV-1's range-valued `GetExplicitArityRange` (call.cpp:424) is the
    hook. Bullet "Functions: function overloading (Carbon-native)". Evidence:
    `fail_todo_overload_member`, `fail_todo_overload_pack_arg`.
13. W-224: pack expansion arguments in template-dependent calls, and packs in
    templates. Evidence: `fail_todo_template_dependent_call`.
14. W-225: variadic impls: the prelude's tuple `Copy` as one
    `impl forall [... each T: Copy] (... each T) as Copy` replacing
    core/prelude/copy.carbon:49-71, and tuple `Eq` and `Ordered`. Bullet
    "Stdlib: tuple/array library parts"; blocked by W-212 and W-213.
15. W-226: a variadic `Core.Call` (p002875:227, :531), so that callable types
    take a parameter list rather than a tuple. Blocked by W-212.
16. W-227: C++ interop, importing: calling C++ variadic function templates and
    instantiating C++ class templates with parameter packs on Carbon packs.
    Bullet "Generics: C++ interop — importing C++ templates, instantiating on
    Carbon types".
17. W-228: C++ interop, exporting: a variadic Carbon function exported to C++
    as a function template over a parameter pack. Bullet "Generics: C++
    interop — exporting Carbon templates/checked generics as C++ templates".

### §1.12 Decision index

| Decision | Summary | Break condition (one sentence) |
| --- | --- | --- |
| D-VA-1 | cherry-pick 2ec4bab59 and a045da8e6 as commits 1 and 2, upstream authorship, no fork trailers, comment-only resolutions | the next advance conflicts in a cherry-picked file in a way taking the fork's side does not resolve, or upstream reshapes 2ec4bab59's nodes first |
| D-VA-2 | the slice: one homogeneous value pack per function, expression-statement and call-argument expansions, arity deduced, body checked once, lowered per specific | a form inside the boundary is mis-checked or lowered to the wrong count or order |
| D-VA-3 | arity = deduced `Core.IntLiteral` binding `<pack arity>`; pack storage = `array(E, N)`; pattern scrutinee type `«E; N»` | a pack needs a representation an array of `E` cannot give, or arrays stop having a pointer value representation |
| D-VA-4 | calls group the pack's arguments into a `PackLiteral` or one forwarded `PackExpansionExpr`; merging, tuple-literal expansions and overload sets are TODOs | a grouped scrutinee deduces a different arity or converts in a different order than DR-30 |
| D-VA-5 | check's slice TODOs (implicit lists, tuple patterns, non-binding operands, `ref`/`var`/phase each-bindings, different arities, template-dependent calls) | a refused form is needed for the row to be PARTIAL |
| D-VA-6 | expansion bodies are straight-line expression statements without cleanups | a straight-line body's lowering reuses a stale per-iteration value |
| D-VA-7 | seven new instructions with the fields, constant kinds and lowering of §1.4's table | a golden shows an expansion body evaluated outside its expansion, or the verifier rejects an accepted body |
| D-VA-8 | definition checking = the body checked once against the element type, the one-segment case of DR-32 | a body is accepted that the design's typechecking rejects for a one-segment pack, or the reverse |
| D-VA-9 | lowering unrolls the body per specific, erases per-iteration locals, fingerprints the arity | a specific evaluates a body other than arity times or out of order |
| D-VA-10 | `each` is a keyword | upstream makes `each` contextual |
| D-VA-11 | a pack's bare name is `PackNameWithoutEach` | upstream gives the bare name a meaning |
| D-VA-12 | twelve new goldens; upstream's check golden refilled, not renamed | file_test rejects a `fail_todo_` split without a TODO |
| D-VA-13 | un-SKIP plus five programs, one differential | a program passes against a mutant with the wrong count or order |
| D-VA-14 | no design-doc edit, no F-018; row PARTIAL expected; W-013 open; W-212..W-228 filed | the slice is shown to decide a rule the design leaves open |
| D-VA-15 | cut from trunk, merges after DD-1 and OX-1, merge commit, re-verify | a branch ahead gains an unresolvable conflict with VA-1 |
| D-VA-16 | five implementation commits, each with its own fill, then row and discharge (§3) | an implementation commit cannot compile without a later one's files |

## §2 Spec, file by file

### §2.0 Conventions

Every code block below was generated from the scratch clone `$V/cp` by
`$V/bin/gen_s2.py` (`git diff -U3` between the per-commit branches, or `git
show` of a whole file), never retyped: C1 is 3b4a431f0, C2 is 2f0d4c4c4, and
C3, C4 and C5 are the branches `va1-c3f` (2c0c47be4), `va1-c4f` (974eacf47)
and `va1-c5f` (80cca957d), whose tree equals `va1-impl` (dff8ef0b5). Each diff
is against the previous commit's state, so applying §2.3, §2.4 and §2.5 in
order to C2 reproduces C5. A diff's blank context lines have lost their
leading space to the trailing-whitespace hook; `git apply` reads a line with
nothing on it as a blank context line, so the diffs still apply. The blocks
sit between `google-doc-style-ignore` and `google-doc-style-resume` comment
lines because the doc-style hook rewrites words inside code (R31(d)), and two
context lines quote code that uses one of them. Every C++ file is clang-format
21.1.8 clean (M-12). The comments the fork adds carry "Fork (VA-1, D-VA-n)"
where a decision of this plan shapes the code and cite the design's section by
name; none names a W-id (the head's id rule).

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

Then `git add toolchain/check/node_stack.h toolchain/parse/state.def` and `git
-c core.editor=true cherry-pick --continue` with the same committer variables.
The fork's other `...` comments (match, let-else and pattern-condition states
that did not conflict) keep the old notation in C1 and are renoted by C3, so
C1 differs from upstream's commit only where git required a resolution.

### §2.2 Commit C2: cherry-pick of a045da8e6

`GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com git
cherry-pick -x a045da8e6`: applies cleanly (36 lines added to
docs/design/variadics.md: a table-of-contents entry and the section "Type
versus execution semantics" after :492).

### §2.3 Commit C3: lex and parse (`va1-c3f`)

The lexer gains the `each` keyword; the parser gains the each-name in binding
patterns and expressions and the `...` element of pattern lists, tuple literals
and call argument lists, beside upstream's statement form. The checker gets one
TODO handler per new parse node kind, because check dispatches on every node
kind and would not link without them; C4 replaces them. Invariant: no existing
token sequence parses differently, since `each` and `...` occur in no existing
Carbon source (M-10), and a list element that does not start with `...` takes
exactly the states it took before (`TupleLiteralElement` and
`HandlePatternListElement` push `Expr` or `Pattern` as before).

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

### §2.4 Commit C4: check and SemIR (`va1-c4f`)

The SemIR instructions of D-VA-7, the checking of D-VA-3 to D-VA-8 and D-VA-11,
the diagnostics, import and redeclaration support, and the lowering stubs that
the per-kind lowering dispatch requires. Invariant: code without packs takes
exactly the paths it took before: `GroupPackArguments` returns the arguments
unchanged for a callee without a pack expansion pattern after one scan for an
expansion argument, the identifier lookup builds the same reference as
`HandleNameAsExpr`, and every other change is a new `case` or a new function.

**toolchain/sem_ir/inst_kind.def.** The seven kinds, alphabetical.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/inst_kind.def
+++ b/toolchain/sem_ir/inst_kind.def
@@ -128,6 +128,13 @@ CARBON_SEM_IR_INST_KIND(OutParam)
 CARBON_SEM_IR_INST_KIND(OutParamPattern)
 CARBON_SEM_IR_INST_KIND(OverloadSetType)
 CARBON_SEM_IR_INST_KIND(OverloadSetValue)
+CARBON_SEM_IR_INST_KIND(PackExpansionExpr)
+CARBON_SEM_IR_INST_KIND(PackExpansionInit)
+CARBON_SEM_IR_INST_KIND(PackExpansionPattern)
+CARBON_SEM_IR_INST_KIND(PackExpansionStatement)
+CARBON_SEM_IR_INST_KIND(PackIndex)
+CARBON_SEM_IR_INST_KIND(PackLiteral)
+CARBON_SEM_IR_INST_KIND(PackType)
 CARBON_SEM_IR_INST_KIND(PartialType)
 CARBON_SEM_IR_INST_KIND(PatternType)
 CARBON_SEM_IR_INST_KIND(PointerType)
```

<!-- google-doc-style-resume -->

**toolchain/sem_ir/typed_insts.h.** The seven instructions of §1.4's table, each
documented with the design section it implements.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/typed_insts.h
+++ b/toolchain/sem_ir/typed_insts.h
@@ -1633,6 +1633,116 @@ struct OverloadSetValue {
   OverloadSetId overload_set_id;
 };

+// A pack expansion element of a call argument list, `... body`
+// (docs/design/variadics.md, "Pack expansion expressions and statements"): a
+// segment whose elements are the values of `result_id` on the successive
+// iterations of `body_block_id`. It evaluates nothing itself: the conversion
+// that initializes the callee's pack splices the body into a
+// `PackExpansionInit`, which runs it once per element.
+struct PackExpansionExpr {
+  static constexpr auto Kind =
+      InstKind::PackExpansionExpr.Define<Parse::PackExpansionExprId>(
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
+// Initializes the array that holds a pack from a pack expansion segment. Each
+// iteration of `body_block_id` initializes the element of `dest_id` at the
+// iteration's `PackIndex`; the number of iterations is the bound of
+// `type_id`, an array type (docs/design/variadics.md, "Execution Semantics").
+struct PackExpansionInit {
+  static constexpr auto Kind =
+      InstKind::PackExpansionInit.Define<Parse::NodeId>(
+          {.ir_name = "pack_expansion_init",
+           .expr_category = ExprCategory::ReprInitializing,
+           .constant_kind = InstConstantKind::Never});
+
+  TypeId type_id;
+  AbsoluteInstBlockId body_block_id;
+  DestInstId dest_id;
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
+// elements' types; it is only ever converted to the pack's array, element by
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
+// and shapes"). Pack types are not first-class: no value has one at run time.
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
coercion, `«E; N»`; the stringifier requires a case for every type instruction.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/stringify.cpp
+++ b/toolchain/sem_ir/stringify.cpp
@@ -869,6 +869,11 @@ class Stringifier {
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

**toolchain/sem_ir/formatter.cpp.** The three instructions with bodies print
their operands and then the body as a trailing block, as `splice_block` does.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/formatter.cpp
+++ b/toolchain/sem_ir/formatter.cpp
@@ -1295,6 +1295,24 @@ auto Formatter::FormatInstRhs(Inst inst) -> void {
       return;
     }

+    case CARBON_KIND(PackExpansionExpr expansion): {
+      FormatArgs(expansion.result_id);
+      FormatTrailingBlock(expansion.body_block_id);
+      return;
+    }
+
+    case CARBON_KIND(PackExpansionInit init): {
+      FormatTrailingBlock(init.body_block_id);
+      FormatReturnSlotArg(init.dest_id);
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
@@ -1456,6 +1456,24 @@ auto InstNamer::NamingContext::NameInst() -> void {
       AddInstNameId(NameId::ReturnSlot);
       return;
     }
+    case CARBON_KIND(PackExpansionExpr inst): {
+      PushBlockId(scope_id_, inst.body_block_id);
+      AddInstName("");
+      return;
+    }
+    case CARBON_KIND(PackExpansionInit inst): {
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

**toolchain/sem_ir/expr_info.cpp.** A `PackExpansionInit` initializes its
`dest_id`, as `ArrayInit` does.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/sem_ir/expr_info.cpp
+++ b/toolchain/sem_ir/expr_info.cpp
@@ -289,6 +289,9 @@ auto FindStorageArgForInitializer(const File& sem_ir, InstId init_id,
       case CARBON_KIND(ArrayInit init): {
         return init.dest_id;
       }
+      case CARBON_KIND(PackExpansionInit init): {
+        return init.dest_id;
+      }
       case CARBON_KIND(ClassInit init): {
         return init.dest_id;
       }
```

<!-- google-doc-style-resume -->

**toolchain/sem_ir/dominance.cpp.** The verifier evaluates an expansion's body
in place and, when the expansion ends, forgets what the body defined, because
the body runs once per element; a `PackExpansionExpr` evaluates nothing (its
consumer splices the body).

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
@@ -529,6 +556,26 @@ auto DominanceVerifier::VerifyAndRecordInst(InstId root_inst_id,
       continue;
     }

+    // A `PackExpansionExpr` evaluates nothing: the `PackExpansionInit` that
+    // consumes it splices its body. A `PackExpansionStatement` or
+    // `PackExpansionInit` evaluates its body in place, once per element.
+    if (inst.Is<PackExpansionExpr>()) {
+      RecordEvaluated(inst_id);
+      continue;
+    }
+    if (auto statement = inst.TryAs<PackExpansionStatement>()) {
+      CARBON_RETURN_IF_ERROR(
+          VerifyOperand(inst_id, statement->arity_id, block_index));
+      push_pack_expansion_body(worklist, inst_id, statement->body_block_id);
+      continue;
+    }
+    if (auto init = inst.TryAs<PackExpansionInit>()) {
+      CARBON_RETURN_IF_ERROR(
+          VerifyOperand(inst_id, init->dest_id, block_index));
+      push_pack_expansion_body(worklist, inst_id, init->body_block_id);
+      continue;
+    }
+
     // A `SpliceInst` evaluates the instruction that its operand names.
     if (auto splice = inst.TryAs<SpliceInst>()) {
       CARBON_RETURN_IF_ERROR(
```

<!-- google-doc-style-resume -->

**toolchain/diagnostics/kind.def.** The checker's fourteen new kinds, in two
blocks: the variadics block after `SemanticsTodo` and the call block's four.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/diagnostics/kind.def
+++ b/toolchain/diagnostics/kind.def
@@ -239,6 +239,18 @@ CARBON_DIAGNOSTIC_KIND(NestedWhereInsideWhereOuterNote)

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
+CARBON_DIAGNOSTIC_KIND(PackNameWithoutEach)
+CARBON_DIAGNOSTIC_KIND(PreviousPackExpansionPattern)
+
 // Location context.
 CARBON_DIAGNOSTIC_KIND(InImport)
 CARBON_DIAGNOSTIC_KIND(InCppInclude)
@@ -313,6 +325,10 @@ CARBON_DIAGNOSTIC_KIND(NamespaceDeclNotAtTopLevel)

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

**toolchain/check/type_completion.cpp.** A pack type is complete with no value
representation of its own, like a pattern type.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/type_completion.cpp
+++ b/toolchain/check/type_completion.cpp
@@ -257,9 +257,9 @@ class TypeCompleter {
              SemIR::AutoType, SemIR::BoundMethodType, SemIR::CharLiteralType,
              SemIR::ErrorInst, SemIR::FacetType, SemIR::FloatLiteralType,
              SemIR::FormType, SemIR::IntLiteralType, SemIR::NamespaceType,
-             SemIR::PatternType, SemIR::RequireSpecificDefinitionType,
-             SemIR::SpecificFunctionType, SemIR::VtableType,
-             SemIR::WitnessType>())
+             SemIR::PackType, SemIR::PatternType,
+             SemIR::RequireSpecificDefinitionType, SemIR::SpecificFunctionType,
+             SemIR::VtableType, SemIR::WitnessType>())
   auto BuildInfoForInst(SemIR::TypeId type_id, InstT /*inst*/) const
       -> SemIR::CompleteTypeInfo {
     // These types are empty at runtime but have values to copy at compile time.
```

<!-- google-doc-style-resume -->

**toolchain/check/handle_binding_pattern.cpp.** An each-name binding must be
inside a pattern expansion and a binding inside a pattern expansion must be an
each-name (DR-6, DR-23); its declared type `E` becomes `array(E, N)` (D-VA-3);
the pack is recorded for its expansion and for lookup.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_binding_pattern.cpp
+++ b/toolchain/check/handle_binding_pattern.cpp
@@ -326,8 +326,63 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
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
+  // The type of an each-name binding's pack: the pack's elements are held in
+  // an array of the declared element type, bounded by the pack's deduced
+  // arity (fork VA-1, D-VA-3).
+  auto element_type_inst_id = SemIR::TypeInstId::None;
+  if (is_each && type_expr.type_component_id != SemIR::ErrorInst::TypeId) {
+    element_type_inst_id = type_expr.type_component_inst_id;
+    auto array_type_id = GetArrayType(context, pack_scope->arity_binding_id,
+                                      element_type_inst_id);
+    type_expr.type_component_id = array_type_id;
+    type_expr.type_component_inst_id =
+        context.types().GetTypeInstId(array_type_id);
+  }
+
   const DeclIntroducerState& introducer =
       context.decl_introducer_state_stack().innermost();

@@ -499,6 +554,17 @@ static auto HandleAnyBindingPattern(Context& context, Parse::NodeId node_id,
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

**toolchain/check/handle_name.cpp.** A bare pack name is `PackNameWithoutEach`
(D-VA-11); otherwise the same reference as before.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/handle_name.cpp
+++ b/toolchain/check/handle_name.cpp
@@ -136,8 +136,30 @@ auto HandleParseNode(Context& context,
 auto HandleParseNode(Context& context, Parse::IdentifierNameExprId node_id)
     -> bool {
   auto name_id = GetIdentifierAsNameId(context, node_id);
-  context.node_stack().Push(node_id,
-                            HandleNameAsExpr(context, node_id, name_id));
+  auto result = LookupUnqualifiedName(context, node_id, name_id);
+  auto target_id = result.scope_result.target_inst_id();
+  // The design gives a pack's name without `each` no meaning yet, leaving it
+  // open for operations on the whole sequence (proposals/p002240-variadics.md,
+  // "Omit each-names"), so such a use is diagnosed.
+  if (context.pack_binding_arities().Contains(target_id)) {
+    CARBON_DIAGNOSTIC(PackNameWithoutEach, Error,
+                      "pack `{0}` can only be referred to as `each {0}` "
+                      "inside a pack expansion",
+                      SemIR::NameId);
+    context.emitter().Emit(node_id, PackNameWithoutEach, name_id);
+    // Its enclosing pack expansion, if any, is invalid; don't diagnose it
+    // again for having no each-name.
+    if (auto& stack = context.pack_expansion_stack();
+        !stack.empty() &&
+        stack.back().kind != Context::PackExpansionScope::Kind::Pattern) {
+      stack.back().arity_id = SemIR::ErrorInst::InstId;
+    }
+    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
+    return true;
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
like an implicit parameter, before the pack.

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
@@ -2301,6 +2303,25 @@ auto MatchContext::DoPreWork(State state,

 // TODO: There is a cycle through pattern matching with an action.
 // NOLINTNEXTLINE(misc-no-recursion)
+// Fork (VA-1): a pack expansion pattern matches the run of arguments that the
+// call grouped into its scrutinee by matching its operand, the each-name
+// binding, against it (docs/design/variadics.md, "Pattern matching"); the
+// operand's parameter converts the run to the array that holds the pack. The
+// pack's arity is a deduced parameter ("Explicit deduced arities"), so the
+// callee binds it like an implicit parameter, before the pack itself.
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
 auto MatchContext::Dispatch(State state, WorkItem entry) -> void {
   if (entry.pattern_id == SemIR::ErrorInst::InstId) {
     if (need_subpattern_results()) {
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

**toolchain/check/convert.cpp.** A `PackLiteral` converts to the pack's array as
a tuple literal does; a `PackExpansionExpr` converts by a `PackExpansionInit`
whose body runs the expansion's body and initializes the array element at the
pack index (DR-41).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/convert.cpp
+++ b/toolchain/check/convert.cpp
@@ -417,11 +417,16 @@ static auto ConvertTupleToArray(Context& context, SemIR::TupleType tuple_type,

   SemIR::LocId value_loc_id(value_id);

-  // If we're initializing from a tuple literal, we will use its elements
+  // If we're initializing from a tuple literal, or from the pack literal that
+  // a call matches against a pack expansion pattern, we will use its elements
   // directly. Otherwise, materialize a temporary if needed and index into the
   // result.
   auto literal =
       GetAggregateLiteralElements<SemIR::TupleLiteral>(context, value_id);
+  if (!literal.has_value()) {
+    literal =
+        GetAggregateLiteralElements<SemIR::PackLiteral>(context, value_id);
+  }
   if (!literal.has_value()) {
     value_id = MaterializeIfInitializer(context, value_id);
   }
@@ -503,6 +508,82 @@ static auto ConvertTupleToArray(Context& context, SemIR::TupleType tuple_type,
                                     .dest_id = return_slot_arg_id});
 }

+// Fork (VA-1): converts a pack expansion argument to the array that holds the
+// pack of the parameter that it matches. The expansion's body is spliced into
+// a `PackExpansionInit`, each iteration of which initializes the array element
+// at the pack index from the body's result (docs/design/variadics.md,
+// "Execution Semantics"). This only converts the type, and does not perform a
+// final conversion to the requested expression category.
+static auto ConvertPackExpansionToArray(Context& context,
+                                        SemIR::PackExpansionExpr expansion,
+                                        SemIR::ArrayType array_type,
+                                        SemIR::InstId value_id,
+                                        ConversionTarget target)
+    -> SemIR::InstId {
+  SemIR::LocId value_loc_id(value_id);
+
+  // Deduction made the array's bound the expansion's arity.
+  auto pack_type = context.types().GetAs<SemIR::PackType>(expansion.type_id);
+  CARBON_CHECK(context.constant_values().Get(pack_type.arity_id) ==
+                   context.constant_values().Get(array_type.bound_id),
+               "Pack expansion of arity {0} converted to {1}",
+               pack_type.arity_id, target.type_id);
+
+  PendingBlock target_block_storage(&context);
+  PendingBlock* target_block = target.storage_access_block
+                                   ? target.storage_access_block
+                                   : &target_block_storage;
+
+  // Arrays are always initialized in-place. Allocate a temporary as the
+  // destination for the array initialization if we weren't given one.
+  SemIR::InstId dest_id = target.storage_id;
+  if (!dest_id.has_value()) {
+    dest_id = target_block->AddInst<SemIR::TemporaryStorage>(
+        value_loc_id, {.type_id = target.type_id});
+  }
+
+  // The body of the initialization, run once per element: the expansion's own
+  // body, then the initialization of the element at the pack index from its
+  // result.
+  context.inst_block_stack().Push();
+  auto element_value_id = AddInst<SemIR::SpliceBlock>(
+      context, value_loc_id,
+      {.type_id = context.insts().Get(expansion.result_id).type_id(),
+       .block_id = expansion.body_block_id,
+       .result_id = expansion.result_id});
+  auto index_id = AddInst<SemIR::PackIndex>(
+      context, value_loc_id,
+      {.type_id =
+           GetSingletonType(context, SemIR::IntLiteralType::TypeInstId)});
+  auto element_type_id =
+      context.types().GetTypeIdForTypeInstId(array_type.element_type_inst_id);
+  PendingBlock element_block(&context);
+  ConversionTarget element_target = {
+      .kind = ConversionTarget::InPlaceInitializing,
+      .type_id = element_type_id,
+      .storage_id = element_block.AddInst<SemIR::ArrayIndex>(
+          value_loc_id, {.type_id = element_type_id,
+                         .array_id = dest_id,
+                         .index_id = index_id}),
+      .storage_access_block = &element_block,
+      .diagnose = target.diagnose};
+  auto init_id =
+      Convert(context, value_loc_id, element_value_id, element_target);
+  element_block.InsertHere();
+  auto body_block_id = context.inst_block_stack().Pop();
+  if (init_id == SemIR::ErrorInst::InstId) {
+    return SemIR::ErrorInst::InstId;
+  }
+
+  // Flush the temporary here if we didn't insert it earlier, so we can add a
+  // reference to the return slot.
+  target_block->InsertHere();
+  return AddInst<SemIR::PackExpansionInit>(context, value_loc_id,
+                                           {.type_id = target.type_id,
+                                            .body_block_id = body_block_id,
+                                            .dest_id = dest_id});
+}
+
 // Performs a conversion from a function to a C++ function pointer type.
 static auto ConvertFunctionToCppPointer(
     Context& context, SemIR::LocId loc_id, SemIR::FunctionType src_type,
@@ -1782,6 +1863,12 @@ static auto PerformBuiltinConversion(Context& context, SemIR::LocId loc_id,
       return ConvertTupleToArray(context, *src_tuple_type, *target_array_type,
                                  value_id, target);
     }
+    // A pack expansion `... e` of arity N converts to array(T, N) if each
+    // element converts to T (fork VA-1).
+    if (auto expansion = value.TryAs<SemIR::PackExpansionExpr>()) {
+      return ConvertPackExpansionToArray(context, *expansion,
+                                         *target_array_type, value_id, target);
+    }
   }

   // Function types can convert to C++ function pointer types.
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

**toolchain/lower/type.cpp.** A pack type is never lowered as a run-time type.

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

**toolchain/check/handle_pack_expansion.cpp** (whole file at va1-c4f). The whole
file replaces C3's (upstream's three handlers, two of them replaced in place and
`HandlePrefixOperatorExpand` kept as upstream's TODO, and C3's four stubs). A
`...` decides its kind from the node it follows (a list start for an element,
anything else for a statement); a pattern `...` adds the deduced arity binding;
a statement or expression `...` opens a block for its body. An each-name
resolves to the pack's array indexed by the pack index. The end of an expansion
checks D-VA-6's restrictions and DR-17, and builds the instruction.

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
#include "toolchain/sem_ir/expr_info.h"
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
      // "A tuple pattern can contain no more than one subpattern of the form
      // `...` operand" (docs/design/variadics.md, "Pattern matching"). Each
      // comma has moved the list's earlier elements to the refs stack.
      for (auto param_id :
           context.param_and_arg_refs_stack().PeekCurrentBlockContents()) {
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
  auto scope = context.pack_expansion_stack().pop_back_val();
  CARBON_CHECK(scope.kind == PackExpansionScope::Kind::Expr);

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

  // On each iteration, `each x` is the element of `x`'s array at the pack
  // index (docs/design/variadics.md, "Execution Semantics": "An each-name
  // evaluates to the `$I`th value of the pack it refers to").
  auto pack_ref_id =
      BuildNameRef(context, node_id, name_id, pack_id, lookup.specific_id);
  auto array_type_id = context.insts().Get(pack_ref_id).type_id();
  auto array_type = context.types().TryGetAs<SemIR::ArrayType>(array_type_id);
  if (!array_type) {
    // The pack's element type was invalid, which was diagnosed.
    InvalidateInnermostPackExpansion(context);
    context.node_stack().Push(node_id, SemIR::ErrorInst::InstId);
    return true;
  }
  if (SemIR::GetExprCategory(context.sem_ir(), pack_ref_id) ==
      SemIR::ExprCategory::Value) {
    pack_ref_id = AddInst<SemIR::ValueAsRef>(
        context, node_id, {.type_id = array_type_id, .value_id = pack_ref_id});
  }
  auto index_id = AddInst<SemIR::PackIndex>(
      context, node_id,
      {.type_id =
           GetSingletonType(context, SemIR::IntLiteralType::TypeInstId)});
  auto element_id = AddInst<SemIR::ArrayIndex>(
      context, node_id,
      {.type_id = context.types().GetTypeIdForTypeInstId(
           array_type->element_type_inst_id),
       .array_id = pack_ref_id,
       .index_id = index_id});
  context.node_stack().Push(node_id, ConvertToValueExpr(context, element_id));
  return true;
}

auto HandleParseNode(Context& context, Parse::PrefixOperatorExpandId node_id)
    -> bool {
  return context.TODO(node_id, "HandlePrefixOperatorExpand");
}

}  // namespace Carbon::Check
```

<!-- google-doc-style-resume -->

**toolchain/lower/handle_pack_expansion.cpp** (whole file at va1-c4f). C4's
lowering stubs: the dispatch needs a handler per lowered kind, and nothing in C4
reaches them (C4 has no lower golden and no program).

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
                SemIR::PackExpansionExpr /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackExpansionExpr");
}

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackExpansionInit /*inst*/) -> void {
  CARBON_FATAL("TODO: Lower PackExpansionInit");
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

}  // namespace Carbon::Lower
```

<!-- google-doc-style-resume -->

### §2.5 Commit C5: lowering (`va1-c5f`)

Lowering per D-VA-9. Invariant: outside an expansion body, `pack_index_` is
empty, `SetLocal` records nothing extra, and `ArrayIndex` takes the same path as
before for every index that is not a `PackIndex`.

**toolchain/lower/function_context.h.** The loop entry point, the current pack
index, and the locals an iteration set.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/function_context.h
+++ b/toolchain/lower/function_context.h
@@ -105,6 +105,21 @@ class FunctionContext {
   // Builds LLVM IR for the specified instruction.
   auto LowerInst(SemIR::InstId inst_id) -> void;

+  // Builds LLVM IR for the body of a pack expansion of `arity` elements, once
+  // per element, with the iteration's `PackIndex` lowered to the element's
+  // index (docs/design/variadics.md, "Execution Semantics": the body is
+  // executed N times, with `$I` ranging from 0 to N - 1). The values that an
+  // iteration computes are discarded before the next one.
+  auto LowerPackExpansionBody(uint64_t arity, SemIR::InstBlockId body_block_id)
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
@@ -141,6 +156,9 @@ class FunctionContext {
     bool added = locals_.Insert(inst_id, value).is_inserted();
     CARBON_CHECK(added, "Duplicate local insert: {0} {1}", inst_id,
                  sem_ir().insts().Get(inst_id));
+    if (pack_index_) {
+      pack_iteration_locals_.push_back(inst_id);
+    }
   }

   // Returns whether a lowered value has been set for the given instruction.
@@ -429,6 +447,12 @@ class FunctionContext {

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
for each index lower the body and erase the iteration's locals.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/function_context.cpp
+++ b/toolchain/lower/function_context.cpp
@@ -89,6 +89,26 @@ auto FunctionContext::LowerBlockContents(SemIR::InstBlockId block_id) -> void {
   }
 }

+auto FunctionContext::LowerPackExpansionBody(uint64_t arity,
+                                             SemIR::InstBlockId body_block_id)
+    -> void {
+  // "A pack expansion [...] cannot contain another pack expansion"
+  // (docs/design/variadics.md, "Pack expansions"); check diagnoses one.
+  CARBON_CHECK(!pack_index_, "Nested pack expansion in lowering");
+  // The arity is specific-dependent: two specifics whose bodies run a different
+  // number of iterations must not be coalesced.
+  AddIntToCurrentFingerprint(arity);
+  for (auto index : llvm::seq(arity)) {
+    pack_index_ = index;
+    LowerBlockContents(body_block_id);
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

**toolchain/lower/handle.cpp.** A `PackIndex` index is lowered through
`GetValue`, since it has no constant value.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/handle.cpp
+++ b/toolchain/lower/handle.cpp
@@ -49,12 +49,14 @@ auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
   auto* llvm_type = context.GetTypeOfInst(inst.array_id);

   // The index in an `ArrayIndex` can be of any integer type, including
-  // IntLiteral. If it is an IntLiteral, its value representation is empty, so
-  // create a ConstantInt from its SemIR value directly.
+  // IntLiteral. If it is an IntLiteral constant, its value representation is
+  // empty, so create a ConstantInt from its SemIR value directly. The other
+  // IntLiteral index is a `PackIndex`, which is lowered to a ConstantInt.
   llvm::Value* index;
   auto index_type = context.GetTypeIdOfInst(inst.index_id);
   if (index_type.file->types().GetTypeInstId(index_type.type_id) ==
-      SemIR::IntLiteralType::TypeInstId) {
+          SemIR::IntLiteralType::TypeInstId &&
+      !context.sem_ir().insts().Is<SemIR::PackIndex>(inst.index_id)) {
     auto value = context.sem_ir().insts().GetAs<SemIR::IntValue>(
         context.sem_ir().constant_values().GetConstantInstId(inst.index_id));
     const auto& apint_value = context.sem_ir().ints().Get(value.int_id);
```

<!-- google-doc-style-resume -->

**toolchain/lower/handle_pack_expansion.cpp** (whole file at va1-c5f). Replaces
C4's stubs: a statement reads its arity in the specific, an initializer reads
its array's bound, both run the body that many times; a `PackIndex` is the
iteration's constant.

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "llvm/IR/Constants.h"
#include "llvm/IR/Type.h"
#include "toolchain/lower/function_context.h"
#include "toolchain/sem_ir/generic.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Lower {

// Fork (VA-1): a pack expansion's body is lowered once per element, the
// compile-time loop of docs/design/variadics.md, "Execution Semantics", run at
// monomorphization: each specific of a variadic function knows its arity.

auto HandleInst(FunctionContext& /*context*/, SemIR::InstId /*inst_id*/,
                SemIR::PackExpansionExpr /*inst*/) -> void {
  // The `PackExpansionInit` that a pack expansion argument is converted to
  // lowers its body.
}

auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                SemIR::PackExpansionInit inst) -> void {
  // The pack's array has one element per iteration.
  auto array_type = context.GetTypeIdOfInst(inst_id);
  auto arity = array_type.file->GetZExtIntValue(
      array_type.file->types()
          .GetAs<SemIR::ArrayType>(array_type.type_id)
          .bound_id);
  CARBON_CHECK(arity, "Pack array of unknown bound");
  context.LowerPackExpansionBody(*arity, inst.body_block_id);
  // The result of initialization is the return slot of the initializer.
  context.SetLocal(inst_id, context.GetValue(inst.dest_id));
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
  // A PackLiteral is always converted to the array of a pack, element by
  // element.
}

}  // namespace Carbon::Lower
```

<!-- google-doc-style-resume -->

### §2.6 Golden sources (AUTOUPDATE, no CHECK lines; R15, R16(a))

Twelve files, every one with `// AUTOUPDATE` and its TIP lines and no CHECK
line; the check and lower files include the primitives prelude, as upstream's
variadics golden does. A split's name starts with `fail_` exactly when it is
expected to produce an error, and with `fail_todo_` when that error is a
`semantics TODO` (§4 predicts each).

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

**toolchain/check/testdata/variadics/each_param.carbon** (commit C4).

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
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/forward.carbon** (commit C4).

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

**toolchain/check/testdata/variadics/fail_each_name.carbon** (commit C4).

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

// --- fail_pack_name_without_each.carbon
library "[[@TEST_NAME]]";

fn Consume(x: i64);

fn F(... each n: i64) {
  Consume(n);
}

// --- fail_each_binding_outside_expansion.carbon
library "[[@TEST_NAME]]";

fn F(each n: i64) {}

// --- fail_binding_without_each.carbon
library "[[@TEST_NAME]]";

fn F(... n: i64) {}
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/fail_pack_expansion.carbon** (commit C4).

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
```

<!-- google-doc-style-resume -->

**toolchain/check/testdata/variadics/fail_todo_slice.carbon** (commit C4).

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
```

<!-- google-doc-style-resume -->

**toolchain/lower/testdata/variadics/pack_expansion.carbon** (commit C5).

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
```

<!-- google-doc-style-resume -->

### §2.7 Conformance programs (bullet "Generics: Definition-checked variadics", R7)

The arbiter's body is uncommented with `as i32` added to its two prints (M-8),
its SKIP line removed and its header rewritten; five programs are new; the
README's program table is regenerated by `runner.py --update-readme-table`
(M-14), never edited by hand.

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

**fork/conformance/programs/generics/variadics_forward.carbon** (new).

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
//
// A variadic function forwards its pack to another with a pack expansion
// argument, `... each d` or `... each d + each d`: "`...` in a tuple
// literal behaves like a series of comma-separated tuple elements"
// (docs/design/variadics.md, "Pack expansion expressions and statements"),
// so Forward(1, 2, 3) calls Digits(1, 2, 3) and Doubled(1, 2, 3) calls
// Digits(2, 4, 6). Digits appends one decimal digit per element in order:
// 123, then 246; Forward() forwards an empty pack, 0; Doubled(4) is
// Digits(8), 8. The callee's arity is deduced from the expansion's at each
// caller specific.

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

fn Run() -> i32 {
  Core.Print(Forward(1, 2, 3) as i32);
  Core.Print(Doubled(1, 2, 3) as i32);
  Core.Print(Forward() as i32);
  Core.Print(Doubled(4) as i32);
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

**fork/conformance/README.md.** The regenerated rows.

<!-- google-doc-style-ignore -->

```diff
--- a/fork/conformance/README.md
+++ b/fork/conformance/README.md
@@ -291,7 +291,12 @@ fails if this table is stale):
 | `generics/templates_dependent_member.carbon` | Generics: Integrated templates | SKIP |
 | `generics/templates_type_param.carbon` | Generics: Integrated templates | run |
 | `generics/templates_value_param.carbon` | Generics: Integrated templates | run |
-| `generics/variadics_each.carbon` | Generics: Definition-checked variadics | SKIP |
+| `generics/variadics_each.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_empty_pack.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_expansion_args.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_fixed_params.carbon` | Generics: Definition-checked variadics | run |
+| `generics/variadics_forward.carbon` | Generics: Definition-checked variadics | run |
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
| Generics: Definition-checked variadics | PARTIAL | Slice 1 landed by VA-1 (fork/variadics/plan.md; W-013 stays open), EXPECTED, not of record: `...` (upstream's 2ec4bab59, cherry-picked) and `each` lex and parse; a function may take one pack `... each x: T` of one element type in its explicit parameter list, expand it in expression statements and pass it on as call arguments (`... e`); the arity is deduced at each call, the body is checked once against the element type, and each arity is lowered as its own specific. generics/variadics_each.carbon and five more programs PASS in the container run <run>. Not yet (filed at the discharge): packs of several or deduced types (`[... each T: type]`), expansions in tuple literals and tuple patterns outside calls and parameter lists, `...and`/`...or`/`...expand`, declarations and control flow inside expansions, variadic impls (the tuple `Copy` rewrite), C++ variadic templates. |
```

<!-- google-doc-style-resume -->

`<run>` is §8.4's run (its log path and counts). Commit D replaces it with
§8.8's and replaces "(filed at the discharge)" with "(W-212..W-228)", so that
no id appears in a record before the re-scan of the head.

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
one-segment case of iterative typechecking), lowering per specific. Residues
W-212..W-228. Next slice: W-212, then W-213 and W-218. OV-1's citation above is
now toolchain/check/call.cpp:424." The `source` string gains "Updated <date> by
the VA-1 discharge: W-013 notes record slice 1; W-212..W-228 added (the §1.11
residues of fork/variadics/plan.md); W-229..W-231 reserved, unused; ids
re-scanned before this commit (<result>)." The seventeen new items, appended
after the highest existing item:

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
      "docs/design/variadics.md \"Pack expansion patterns\" (:214-220) and \"Iterative typechecking of pack expansions\" (:450-492); DR-4, DR-11, DR-17, DR-24, DR-31, DR-32, DR-40",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_generic_pack` (`semantics TODO: pack expansion pattern outside an explicit parameter list`)"
    ],
    "blocked_by": [
      "W-013"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). The next slice of W-013. Packs whose elements have different types, or a type that is itself a pack, need pack types of several segments, shapes, and segment-by-segment checking; slice 1 stores a pack as `array(E, N)` (D-VA-3), which this item replaces for such packs. Arbiter: the design's StrCat (:251-259). At the advance that brings upstream's own check of expansions, rename upstream's `fail_todo_pack_expansion_statement` split (D-VA-12). Break condition: StrCat compiles and runs."
  },
  {
    "id": "W-213",
    "kind": "missing-feature",
    "title": "VA-1 residue: tuples with pack segments (`(... each x)` outside a call's argument list, tuple types `(... each T)`)",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "L",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :108-109, :134-140, :483-490; DR-9, DR-14, DR-33",
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
      "docs/design/variadics.md :110-111, :206-213; DR-10",
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
    "title": "VA-1 residue: merging and splitting segments (an expansion argument merged with other arguments, the `Arity` type's `+`, canonical full patterns, defaults beside a pack)",
    "subsystem": "toolchain/check",
    "size": "L",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :512-641, :664-668, :794-796, :807-937; DR-36, DR-37, DR-39, DR-41",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_merged_segments` (`ForEach(0, ... each n)`)",
      "fork/variadics/plan.md M-7: a deduced `Core.IntLiteral` array bound has no arithmetic (`array bound is not a constant` for `N + 1`)"
    ],
    "blocked_by": [
      "W-013"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Slice 1 matches the parameters around a pack position by position and accepts as a pack's scrutinee either ordinary arguments or exactly one expansion argument. Break condition: `ForEach(0, ... each n)` deduces arity `N + 1`."
  },
  {
    "id": "W-216",
    "kind": "missing-feature",
    "title": "VA-1 residue: `...and` and `...or`",
    "subsystem": "toolchain/parse + toolchain/check + toolchain/lower",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :114-115, :307-314, :487-488; DR-12, DR-33",
      "`...and true` fails to parse (\"expected expression\"), fork/variadics/plan.md M-3"
    ],
    "blocked_by": [
      "W-013"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Short-circuiting folds over a pack; they also need control flow in expansion bodies (W-219). Break condition: Zip's loop condition `...and each iter != each vector.End()` checks."
  },
  {
    "id": "W-217",
    "kind": "missing-feature",
    "title": "VA-1 residue: `...expand` (check and lowering of upstream's `expand` operator or the design's `...expand` element)",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :120-130, :151-152, :492 (\"TODO: Discuss typechecking `...expand`\"); DR-13, DR-18",
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
      "docs/design/variadics.md :107, :304-305; DR-8",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_statement_kind`"
    ],
    "blocked_by": [
      "W-212"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). A declaration in an expansion declares a pack (one name per element); compound statements need blocks inside the per-element body. Arbiters: Zip (:70-82), Min (:263-270). Break condition: Min runs."
  },
  {
    "id": "W-219",
    "kind": "missing-feature",
    "title": "VA-1 residue: control flow inside an expansion body (`and`, `or`, `if` expressions; the type-versus-execution example)",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md \"Type versus execution semantics\" (a045da8e6, :494-527 after VA-1 commit C2); DR-34",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon split `fail_todo_control_flow`"
    ],
    "blocked_by": [
      "W-013"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Slice 1 lowers an expansion body as one straight-line block per element (D-VA-6). Break condition: `... Consume(each b and true)` runs with short-circuiting per element."
  },
  {
    "id": "W-220",
    "kind": "missing-feature",
    "title": "VA-1 residue: per-element cleanups (a temporary needing destruction inside an expansion body)",
    "subsystem": "toolchain/check + toolchain/lower",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "toolchain/check/handle_pack_expansion.cpp `FinishPackExpansionBody`: `semantics TODO: pack expansion element that needs a cleanup`",
      "fork/variadics/plan.md D-VA-6"
    ],
    "blocked_by": [
      "W-013"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). No golden yet: slice 1's goldens use types without destructors. Break condition: an expansion over a call returning a class with a destructor destroys each temporary once."
  },
  {
    "id": "W-221",
    "kind": "missing-feature",
    "title": "VA-1 residue: each-name bindings that are `ref`, `var` or phase-qualified, and expansion operands that are not one each-name binding",
    "subsystem": "toolchain/check",
    "size": "M",
    "bullet": "Generics: Definition-checked variadics",
    "evidence": [
      "docs/design/variadics.md :222-234; a045da8e6's `fn G(... (each c: bool, each x: i32))`; DR-25, DR-34",
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
      "docs/design/variadics.md :146-147, :494-510; DR-16, DR-35",
      "toolchain/check/handle_pack_expansion.cpp: `semantics TODO: pack expansion over packs of different arities` (unreachable in slice 1)"
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
      "toolchain/check/call.cpp `PerformCallToOverloadSet`; `GetExplicitArityRange` (:424 at f67ab650d) returns a range for this purpose (OV-1, fork/overload/plan.md §8.5)",
      "toolchain/check/testdata/variadics/fail_todo_slice.carbon splits `fail_todo_overload_member`, `fail_todo_overload_pack_arg`"
    ],
    "blocked_by": [
      "W-013"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). The overload probe would group arguments per member (D-VA-4). Break condition: both splits check and select a member."
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
    "blocked_by": [
      "W-013"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Break condition: the split's `t.G(... each n)` instantiates."
  },
  {
    "id": "W-225",
    "kind": "missing-feature",
    "title": "VA-1 residue: variadic impls; the prelude tuple `Copy` as one variadic impl, and tuple `Eq`/`Ordered`",
    "subsystem": "core/prelude + toolchain/check",
    "size": "L",
    "bullet": "Stdlib: tuple/array library parts",
    "evidence": [
      "core/prelude/copy.carbon:49-71 (\"TODO: Implement tuple copy as a variadic generic impl.\", impls for arities 0 to 3)"
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
      "fork/variadics/plan.md §1.11"
    ],
    "blocked_by": [
      "W-212"
    ],
    "notes": "Filed at the VA-1 discharge (fork/variadics/plan.md §1.11). Break condition: C++ calls an exported Carbon `Sum(... each n: i64)` with any number of arguments."
  }
]
```

<!-- google-doc-style-resume -->

**fork/decision-log.md (commit D).** A new entry first under "## Decided":

<!-- google-doc-style-ignore -->

```markdown
### VA-1: definition-checked variadics, slice 1 (<date>)

Context: W-013 (gap row "Generics: Definition-checked variadics",
DESIGN-ONLY); fork/variadics/plan.md. Every decision auto-adopted under V-2/V-3
(R29(a)) and open to veto. D-VA-1: upstream's 2ec4bab59 and a045da8e6
cherry-picked as the first two commits with upstream authorship and no fork
trailers. D-VA-2: the slice is one pack of one element type per function, in its
explicit parameter list, with expression-statement and call-argument
expansions. D-VA-3: the arity is a deduced `Core.IntLiteral` binding and a pack
is stored as `array(E, N)`. D-VA-4: a call groups a pack's arguments into one
scrutinee. D-VA-5 and D-VA-6: the slice's TODOs and straight-line bodies.
D-VA-7: seven new SemIR instructions. D-VA-8: definition checking is the
one-segment case of the design's iterative typechecking. D-VA-9: lowering
unrolls each body per specific. D-VA-10: `each` is a keyword. D-VA-11: a pack's
bare name is an error. D-VA-12 and D-VA-13: goldens and programs. D-VA-14: no
design-doc edit, no F-018. D-VA-15: merge position. D-VA-16: commit structure.
Consequences: row PARTIAL (expected, not of record); W-212..W-228 filed.
```

<!-- google-doc-style-resume -->

**fork/ORCHESTRATION.md (commit D).** The VA row of the branch table becomes
"HELD OPEN as PR <n> — VA-1 definition-checked variadics slice 1 at <head>
(W-013 open; W-212..W-228 filed, W-229..W-231 unused; expected <counts> over
<programs>; row 53 PARTIAL expected); merges after OX-1 or DD-1, whichever is
later.", and a dated paragraph records the cherry-picks, the reservation's
outcome and the not-run list of §8.9.

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

0.  **Plan.** This revision, "VA-1 plan (rev 1): definition-checked variadics,
    slice 1"; each later revision is a new commit, each amended sentence marked
    "(amended <date>, review fold: <finding>)".
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
4.  **C3, lex and parse** (§2.3; 17 files, 348 insertions and 36 deletions at
    `va1-c3f`). The `Each` keyword, the four new parse node kinds and three new
    states, the binding, expression and list changes, the two parse diagnostics,
    check TODO stubs for the four new nodes and the node stack's classification
    of `EachBindingName` (check needs a handler and an id kind per node kind;
    §8.0 measured the second), the renotation of the fork's remaining `...`
    comments in state.def, and the four new lex and parse goldens. Expected
    gate: red on exactly the four new goldens.
5.  **F3.** Autoupdate of C3's four goldens, to its fixpoint (R26).
6.  **C4, check and SemIR** (§2.4; 34 files, 1524 insertions and 13 deletions
    at `va1-c4f`). Everything of §1.4 and the seven check goldens; the lowering
    of the new instructions is a fatal TODO stub in
    toolchain/lower/handle_pack_expansion.cpp (lowering needs a handler per
    instruction kind), which no golden or program of C4 reaches. Expected gate:
    red on exactly the seven new goldens and the one refill of D-VA-12.
7.  **F4.** Autoupdate of those eight files.
8.  **C5, lowering and programs** (§2.5, §2.7; 13 files, 399 insertions and 36
    deletions at `va1-c5f`). The lowering of D-VA-9, the
    lower golden, the un-SKIP, the five programs and the regenerated README
    table. Expected gate: red on exactly the lower golden; conformance as §5.
9.  **F5.** Autoupdate of the lower golden.
10. **R, the row.** §2.8's row 53 and header change, quoting §8.4's container
    run, stated EXPECTED, not of record; nothing else.
11. **D, discharge**, after the implementation reviews (R29(c): two until the
    hosted verification is green, then one), their folds in new commits by a
    separate fixer, the merge of trunk (a merge commit) when VA-1 is next in
    D-VA-15's order, and §8.8's re-verification on the merge commit: the
    records of §2.8 other than the row (ledger, decision log, ORCHESTRATION,
    W6 sentence), the id re-scan of the head, and re-quoted counts.

Every commit uses explicit paths (R20, never `git add -A`), runs `SKIP=
fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest uvx
prek run --files <its files>` to a fixpoint first, with R31's heading and
list-item counts before and after for each `.md`, and, except C1 and C2, uses
the author `jmann345 <jerrymannstan@gmail.com>`, the committer `Claude
<noreply@anthropic.com>` and the session's attribution trailers. A problem found
after a commit exists is fixed by a new commit, never by amending (AGENTS.md).
The upstream goldens of C1 are never edited by hand (R16(a)); if the gate needs
them changed, F1 does it by autoupdate.

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

Every line below is a prediction from the code of §2 and the diagnostic strings
in it, not a run; columns and SemIR names are the fill's to decide, and a fill
that contradicts a prediction is a finding for the implementation review, never
a reason to edit a golden (R16(a)). Diagnostic texts are the `CARBON_DIAGNOSTIC`
format strings of §2 with their arguments substituted.

| File (commit) | Split | Predicted key output |
| --- | --- | --- |
| lex/testdata/periods.carbon (C1, upstream) | (one file) | upstream's CHECK lines, unchanged (§7 R-1) |
| parse/testdata/variadics/expand.carbon (C1, upstream) | 4 splits | upstream's CHECK lines, unchanged; C3 does not alter them, since none of their call arguments starts with `...` and no name is `each` (M-10) |
| parse/testdata/variadics/pack_expansion_statement.carbon (C1, upstream) | 6 splits | as for expand.carbon |
| check/testdata/variadics/pack_expansion.carbon (C1, upstream; refilled F4) | `fail_todo_pack_expansion_statement` | C1: `semantics TODO: `HandlePackExpansionStart` [SemanticsTodo]` (upstream's); after C4: `error: pack expansion does not use any each-name [PackExpansionWithoutEachName]` at the `...` |
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
| parse/testdata/variadics/pack_expansion_pattern.carbon (C3) | `param`, `implicit`, `tuple_pattern` | `PackExpansionStart` after `ExplicitParamListStart`, `ImplicitParamListStart` or `TuplePatternStart`, then the binding, then `PackExpansionPattern '...'` |
| check/testdata/variadics/each_param.carbon (C4) | `statement` | `ForEach`'s `fn_decl` with `symbolic_binding_pattern arity`, a `value_binding_pattern n` of pattern type `array(i64, %arity)` and a `pack_expansion_pattern`; its body `pack_expansion_statement %arity` whose block holds `value_as_ref`, `pack_index`, `array_index` and the call; in `Call`, two calls whose argument is a `pack_literal` of 3 and of 0 elements converted by `array_init`, and two specifics of `ForEach` |
| (same) | `fixed_params` | `Middle(1, 2)`: `pack_literal` of 0 elements; `Middle(1, 2, 3, 4)`: of 2 |
| (same) | `deduced_element_type` | specifics with `T` = `i64`, arity 2, and `T` = `bool`, arity 0 |
| (same) | `redecl` | no diagnostic |
| (same) | `method` | `c.ForEach(1, 2)` with the bound `self` first and a 2-element `pack_literal` |
| check/testdata/variadics/forward.carbon (C4) | `forward` | `ForEach(... each m)`: a `pack_expansion_expr` of type `«i64; %arity»` consumed by `pack_expansion_init`, whose block splices the expansion body and initializes `array_index %.., %pack_index` |
| (same) | `forward_expression` | as `forward`, the spliced body calling `Double` |
| (same) | `forward_fixed` | `Middle(0, ... each x, 9)`: `0` and `9` to the fixed parameters, the expansion to the pack |
| check/testdata/variadics/import.carbon (C4) | `lib`, `use` | `use.carbon` imports `ForEach` (`pack_expansion_pattern` and `pack_type` through import refs) and calls it with a 2-element `pack_literal` |
| check/testdata/variadics/fail_call.carbon (C4) | `fail_too_few_args` | `error: 1 argument passed to function expecting at least 2 arguments [CallArgCountTooFewForPack]`, note `calling function declared here [InCallToVariadicFunction]` |
| (same) | `fail_expansion_for_singular_param` | `error: pack expansion argument cannot match a parameter that is not a pack expansion [PackExpansionArgForSingularParam]` |
| (same) | `fail_expansion_without_pack_param` | `error: pack expansion argument is not matched by a pack expansion parameter [PackExpansionArgWithoutPackParam]` |
| (same) | `fail_element_conversion` | `error: cannot implicitly convert expression of type `C` to `i64` [ConversionFailure]` at `{} as C` |
| check/testdata/variadics/fail_each_name.carbon (C4) | `fail_each_name_not_pack` | `error: `each x` does not name a pack [EachNameNotPack]`, and nothing for the expansion |
| (same) | `fail_each_name_outside_expansion` | `error: each-name `each n` is not inside a pack expansion [EachNameOutsidePackExpansion]` |
| (same) | `fail_pack_name_without_each` | `error: pack `n` can only be referred to as `each n` inside a pack expansion [PackNameWithoutEach]` |
| (same) | `fail_each_binding_outside_expansion` | `error: each-name binding `each n` is not inside a pack expansion pattern [EachBindingOutsidePackExpansion]`, then `warning: binding `n` unused [UnusedBinding]` (the binding stays an ordinary `n`) |
| (same) | `fail_binding_without_each` | `error: binding pattern in a pack expansion must declare an each-name, such as `each n` [PackExpansionBindingWithoutEach]` |
| check/testdata/variadics/fail_pack_expansion.carbon (C4) | `fail_nested` | `error: pack expansion cannot contain another pack expansion [NestedPackExpansion]`, note `enclosing pack expansion is here [EnclosingPackExpansion]` |
| (same) | `fail_without_each_name` | `error: pack expansion does not use any each-name [PackExpansionWithoutEachName]` |
| (same) | `fail_two_pack_patterns` | `error: parameter list can contain at most one pack expansion pattern [MultiplePackExpansionPatterns]`, note `previous pack expansion pattern is here [PreviousPackExpansionPattern]` |
| check/testdata/variadics/fail_todo_slice.carbon (C4) | `fail_todo_generic_pack`, `fail_todo_tuple_pattern` | `semantics TODO: `pack expansion pattern outside an explicit parameter list`` |
| (same) | `fail_todo_statement_kind` | `semantics TODO: `pack expansion of a statement other than an expression statement`` |
| (same) | `fail_todo_control_flow` | `semantics TODO: `control flow in a pack expansion`` |
| (same) | `fail_todo_tuple_literal` | `semantics TODO: `pack expansion in a tuple literal outside a call's argument list`` |
| (same) | `fail_todo_merged_segments` | `semantics TODO: `pack expansion argument merged with other arguments for the same pack`` |
| (same) | `fail_todo_ref_pack` | `semantics TODO: `each-name binding that is not a value binding`` |
| (same) | `fail_todo_two_each_names` | `semantics TODO: `pack expansion pattern declaring more than one each-name`` |
| (same) | `fail_todo_tuple_operand` | `semantics TODO: `pack expansion pattern whose operand is not an each-name binding`` |
| (same) | `fail_todo_overload_member` | `semantics TODO: `variadic member of an overload set`` |
| (same) | `fail_todo_overload_pack_arg` | `semantics TODO: `pack expansion argument in a call to an overload set`` |
| (same) | `fail_todo_template_dependent_call` | `semantics TODO: `pack expansion argument in a template-dependent call`` |
| lower/testdata/variadics/pack_expansion.carbon (C5) | `sum` | `Sum` lowered three times: the arity-3 specific with three `add` sequences over `getelementptr [3 x i64]` indexes 0, 1, 2; the arity-0 specific with none; `SumOfDoubles` (arity 2) initializing a `[2 x i64]` temporary with two doubled elements and calling the arity-2 `Sum` |
| (same) | `generic_element` | `ForEach` lowered for (`bool`, arity 2) and (`i32`, arity 1), each calling its `Consume` specific once per element |

Totals: 12 new files with 49 splits (the lex file counted as one), 1 refill
(D-VA-12) and 4 upstream files carried; no other golden changes (§6.1).

## §5 Conformance delta (from the floor of record, 128 PASS / 0 FAIL / 22 SKIP over 150)

| Program | Before | After | Commit |
| --- | --- | --- | --- |
| generics/variadics_each.carbon | SKIP | PASS (6, 0) | C5 |
| generics/variadics_fixed_params.carbon | absent | PASS (12, 123, 4321) | C5 |
| generics/variadics_forward.carbon | absent | PASS (123, 246, 0, 8) | C5 |
| generics/variadics_empty_pack.carbon | absent | PASS (7, 1, 2, 9) | C5 |
| generics/variadics_expansion_args.carbon | absent | PASS (19, 1239, 15559) | C5 |
| generics/variadics_sum_diff.carbon | absent | PASS, C++ oracle agrees (123, 11, 0, 30, 0) | C5 |

VA-1's own delta: PASS +6, SKIP -1, programs +5, so 134 / 0 / 21 over 155
against the floor of record, and the bullet "Generics: Definition-checked
variadics", SKIP-only today, becomes PASS (48/56 bullets PASS becomes 49/56).
No other program moves: VA-1 changes no prelude file and no other program,
and the lexer and parser changes alter the meaning of no other existing Carbon
source (M-10). The
held PRs ahead of VA-1 move the totals before it lands (PR 54 to 57 each state
an expected count of their own), so commit R and the discharge quote §8.8's run
on the merge commit, not this table's arithmetic.

## §6 Churn and collisions

### §6.1 Golden churn

Existing goldens that change: one, upstream's
toolchain/check/testdata/variadics/pack_expansion.carbon, in C4 (D-VA-12).
Everything else is predicted unchanged, for four measured reasons: no existing
Carbon source uses `...` or `each` (M-10); parse dumps print node kinds by
name, so new kinds renumber nothing visible; SemIR dumps print instruction
kinds by `ir_name` and special names by spelling (raw dumps print
`name(PeriodSelf)`, not an index; toolchain/check/testdata/basics/raw_sem_ir),
so the new `PackArity` special name, inserted alphabetically before
`PackageKeyword`, renumbers nothing visible; and the new diagnostics fire only
on the new syntax. A golden that changes anyway is refilled by the fill commit
of the commit that changed it and listed in the implementation review, with
its cause (§7 R-4).

### §6.2 Collisions (M-15: `git merge-tree` against each branch, conflicts the branch already has with trunk subtracted)

| Branch (head) | Files shared with VA-1 | New conflicts |
| --- | --- | --- |
| PR 51, claude/carbon-fork-0-1-ua2 (f96fe8a7a) | fork/conformance/README.md | 0 |
| PR 52, claude/carbon-fork-0-1-cmake (ea573f672) | fork/conformance/README.md | 0 |
| PR 53, claude/carbon-fork-0-1-safe (adaae4e35) | none | 0 |
| PR 54, claude/carbon-fork-0-1-ev (cb3ef2e74) | fork/conformance/README.md | 0 |
| PR 55, claude/carbon-fork-0-1-st (21307851a) | fork/conformance/README.md | 0 |
| PR 56, claude/carbon-fork-0-1-op (379f20f67) | fork/conformance/README.md | 0 |
| SC-1, claude/carbon-fork-0-1-sc (6231d5b42) | README.md and 17 toolchain files: check/call.cpp, context.cpp, context.h, convert.cpp, handle_binding_pattern.cpp, import_ref.cpp, merge.cpp, type.cpp, type.h, type_completion.cpp; diagnostics/kind.def; lower/type.cpp; parse/node_kind.def; sem_ir/inst_kind.def, inst_namer.cpp, stringify.cpp, typed_insts.h | 0 (every hunk auto-merges) |
| PR 57, claude/carbon-fork-0-1-op2 (628273444) | README.md, check/convert.cpp, lower/handle.cpp | 0 |
| DD-1, claude/carbon-fork-0-1-dd (6b692aa14) | fork/conformance/README.md | 0 |
| OX-1, claude/carbon-fork-0-1-ox (f67ab650d, no commits yet) | none; OX-1's brief confines it to toolchain/check/cpp, which VA-1 does not touch | 0 by construction; re-measured at merge |

The pre-existing conflicts subtracted are fork/ORCHESTRATION.md on cmake, ev,
st, op, sc and dd, which VA-1's implementation does not touch. Two collisions
were removed while prototyping, both by the shape of the code rather than by
coordination: the lowering handlers live in a new file,
toolchain/lower/handle_pack_expansion.cpp, because placing them in
lower/handle.cpp conflicted with PR 57's hunk there (measured, `$V/mt_op2.txt`),
and kind.def's new kinds sit in their own block. The README table conflicts
textually whenever two branches add rows and is regenerated by
`runner.py --update-readme-table` at every merge. The risk with SC-1 is
semantic, not textual: SC-1 rewrites parts of call.cpp, convert.cpp and
handle_binding_pattern.cpp that VA-1 calls into, so §8.8 re-runs the whole gate
and conformance on the merge commit, and a VA-1 golden whose SemIR changes
there is refilled, never merged by hand.

**The next upstream advance** (M-16): VA-1 adds three conflicted files to the 71
the advance already has, each resolved by taking the fork's side, which holds
upstream's lines; the cherry-picks themselves add none. Upstream's later
variadics work will collide with VA-1 in handle_pack_expansion.cpp,
typed_nodes.h and the check of call arguments, and that advance takes upstream's
shapes where they differ from VA-1's (the fork's are additions beside
upstream's, not rewrites of them, D-VA-1).

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
    call; no program links two libraries (programs are single files), so the
    lowering of an imported variadic specific is unexercised (§8.9).
-   **R-7. `each` as a keyword diverges from the nightly.** Upstream's lexer
    does not have it (M-3), so a Carbon file valid upstream that names something
    `each` is invalid in the fork until upstream adds the keyword; M-10 finds no
    such file upstream except the keyword list itself. D-VA-10's break
    condition handles upstream choosing otherwise.
-   **R-8. Code size.** A call with k arguments instantiates a specific whose
    expansion bodies are unrolled k times, the design's monomorphization. No
    bound is imposed; a program with thousands of arguments would compile
    slowly. Not row-bounding.

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
-   **A-4. Pack storage as a tuple instead of an array.** A pack of one element
    type could be a tuple `(E, E, ...)` of arity N; but a tuple type of
    symbolic arity does not exist (it is W-213's segment type), while
    `array(E, N)` with a deduced `Core.IntLiteral` bound already deduces,
    forwards, indexes and is empty-safe on trunk (M-7). The array is the
    representation of the one-segment case only; W-212 replaces it for
    heterogeneous packs.
-   **A-5. Check the body once per specific** (rejected). Checking each
    specific's body would be template instantiation, not a definition check: an
    error would appear only at a call, which the bullet's "definition-checked"
    excludes, and the design's iterative typechecking checks segments, not
    elements (DR-32).
-   **A-6. A run-time loop in lowering** (rejected). Lower the body once inside
    an LLVM loop over the array. It would work for this slice's one-type packs,
    but the design specifies execution at monomorphization with `$I` "treated as
    a constant" (:300-302), which heterogeneous packs require (each iteration
    may have a different type), so a loop would be replaced, not extended, by
    W-212.
-   **A-7. Re-derive upstream's lexer and parser in the fork** (rejected,
    D-VA-1): a second state set to reconcile at the advance, against a measured
    one-line real change in upstream's state.def (M-4).
-   **A-8. A "0.1 limits" section in variadics.md** (rejected, D-VA-14).
-   **A-9. Rename upstream's `fail_todo_pack_expansion_statement`** (rejected,
    D-VA-12).

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

### §8.1 Build (implementer)

After C1, C3, C4 and C5: `$CB/build.sh /home/user/carbon-va` then
`$CB/install.sh /home/user/carbon-va` (the build lands in
/home/user/carbon-build/carbon-va/). A full build is required at each of these
commits, because each edits an X-macro header most objects include (M-19);
the relink recipe is usable only for §8.5's mutants, which edit `.cpp` files
alone. C2 changes docs only and needs no build.

### §8.2 Autoupdate to its fixpoint (implementer)

After each build that has new or changed goldens: `$CB/autoupdate.sh
/home/user/carbon-va --file_tests=<the commit's goldens>`, then the same command
again, which must change nothing (R26: a second run that changes more than
`.loc` numbers is a stop, not a loop). The fill's diff is reviewed against §4
before the fill commit; a golden whose fill contradicts §4 is a finding, never
an edit.

### §8.3 Gate (implementer)

`$CB/gate.sh /home/user/carbon-va`, file_test over every testdata file (trunk:
1942 files, `[  PASSED  ] 1942 tests.`, carbonbuild README). Expected, all
passing: 1946 after C1 (and F1 if needed) and after C2; 1950 after F3; 1957
after F4; 1958 after F5. Each implementation commit alone is expected red on
exactly its new goldens and its refill, nothing else and no crash (§3).

### §8.4 Conformance (implementer)

`$CB/conformance.sh /home/user/carbon-va` after F5: expected 134 PASS / 0 FAIL
/ 21 SKIP over 155 on this branch (f67ab650d's 128 / 0 / 22 over 150 plus §5's
delta), the six variadics programs PASS with §1.6's output, and the C++ side of
variadics_sum_diff compiles with the toolchain's own clang++ and agrees. The
row commit R quotes this run, EXPECTED, not of record.

### §8.5 Mutants that prove the programs are not vacuous (implementer)

Each mutant is a one-hunk change to one `.cpp` file, compiled and relinked into
a scratch copy of the C5 build with the relink recipe (`$V/../st1-fixer/fix/
relink.py`, generalized as OP-2's `bin/relink.py`; valid here because no header
changes), and the six programs are run against it. Predicted results:

| Mutant (file: change) | each | fixed_params | forward | empty_pack | expansion_args | sum_diff |
| --- | --- | --- | --- | --- | --- | --- |
| MU-1 function_context.cpp: skip the last iteration | FAIL (3, 0) | FAIL (12, 12, 431) | FAIL | FAIL (7, 1, 9) | FAIL | FAIL |
| MU-2 function_context.cpp: run each iteration twice | FAIL (12, 0) | FAIL | FAIL | FAIL (7, 1, 1, 2, 2, 9) | FAIL | FAIL |
| MU-3 function_context.cpp: iterate the indexes in reverse | PASS (6, 0) | FAIL (12, 123, 4231) | FAIL (321, ...) | FAIL (7, 2, 1, 9) | FAIL | FAIL |
| MU-4 handle_pack_expansion.cpp (lower): `PackIndex` always 0 | FAIL (3, 0) | FAIL | FAIL | FAIL (7, 1, 1, 9) | FAIL | FAIL |
| MU-5 call.cpp: build the `PackLiteral` from the arguments reversed | PASS (6, 0) | FAIL (12, 123, 4231) | FAIL | FAIL (7, 2, 1, 9) | FAIL | FAIL |
| MU-6 deduce.cpp: deduce the arity as the element count minus one | FAIL (compile) | FAIL | FAIL | FAIL | FAIL | FAIL |

MU-3 and MU-5 show why the arbiter alone is not enough (a sum does not see
order) and why §1.8's order-sensitive programs exist. A mutant that leaves
every program PASS is a finding against §1.8's set.

### §8.6 prek and R31 (every agent, every commit)

`SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
uvx prek run --files <the commit's files>` to a fixpoint; for each `.md`,
heading counts per level and list-item counts (including indented items)
before and after (R31(b)), and the diff grepped for manufactured headings
(R31(c)). C1 and C2 are upstream's text and are not reformatted; if prek wants
to change them, that is recorded and not applied (they are byte-identical to
upstream but for the conflict resolution).

### §8.7 Harness self-test

`python3 fork/conformance/runner.py --self-test` before every commit that
touches programs (R7): expected "155 programs parsed, 56 bullets in table, OK"
on this branch (M-14).

### §8.8 Re-verification on the merge commit (implementer, before D)

After the merge of trunk (D-VA-15): §8.1 to §8.4 again on the merge commit,
with the refills the merged branches cause committed as their own fill
commits; the totals of §8.3 and §8.4 then become whatever trunk's floor plus
§5's delta is, and commit D quotes that run. Then the id re-scan of the head.

### §8.9 Not run, and why

-   No build, file_test fill, gate or conformance run was made by the planner:
    the planner does not build a toolchain, and the relink recipe cannot stand
    in for commits that edit X-macro headers (M-19). Every golden line and
    every program output in this plan is a prediction (§4) or a hand
    derivation (§1.6), not a measurement of VA-1's code.
-   The runtime behavior of the lowering (R-2) is unmeasured until §8.4.
-   Bazel-only tests are not part of the container gate (carbonbuild README,
    "Bazel-only tests"): the gtest unit tests (among them
    toolchain/lex/tokenized_buffer_test.cpp, whose keyword table the `Each`
    keyword extends through the X-macro, and the parser's typed-node tests),
    toolchain/diagnostics' coverage test (every diagnostic kind tested; §4
    gives each new kind a `fail_` split), lit tests and fuzzers. They run only
    on hosted CI, which is disabled.
-   Lowering an imported variadic function's specific (R-6): no single-file
    program can, and no lower golden imports.
-   prek over the cherry-picked commits' files was not run in scratch; §8.6
    covers it at implementation time.

## Hand-off notes for the implementer

1.  **Recreate C1 and C2 exactly.** On `claude/carbon-fork-0-1-va`:
    `GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com git
    cherry-pick -x 2ec4bab59`; resolve per §2.1; then compare with the scratch
    result before `git cherry-pick --continue`: after `git fetch $V/cp
    va1-impl`, `git diff 3b4a431f0 -- toolchain/parse/state.def
    toolchain/check/node_stack.h` must print nothing. Do not pass `--author`, do
    not add trailers (D-VA-1). Then `git cherry-pick -x a045da8e6`, which needs
    the upstream objects (`git fetch /home/user/carbon-lang
    refs/remotes/upstream/trunk` first if the worktree lacks them).
2.  **C3, C4 and C5 are §2.3, §2.4 and §2.5 plus §2.6 and §2.7.** The scratch
    branches `va1-c3f`, `va1-c4f` and `va1-c5f` in `$V/cp` hold exactly those
    trees; after writing each commit from the plan, `git diff <your commit>
    <scratch branch> -- toolchain fork/conformance` must be empty. If the plan
    and the scratch branch ever disagree, the plan is the authority and the
    disagreement is reported.
3.  **Fills are separate commits** ("Autoupdate testdata goldens on the
    container arbiter"), to their fixpoint (R26), reviewed against §4.
4.  **What to run first after C5's build:** M-1's `sum.carbon` with `as i32`
    added to its prints (it is the arbiter's body); then the six programs; then
    §8.5's MU-3, the mutant the arbiter alone cannot catch.
5.  **Watch-outs.** The `PackArity` special name is alphabetical in ids.h and
    has a spelling in name.cpp; the new kind.def kinds sit in their own blocks;
    upstream's `fail_todo_pack_expansion_statement` is refilled, not renamed;
    the programs print with `as i32`; every TODO in §2.4 has its golden split
    except "pack expansion element that needs a cleanup" and "pack expansion
    over packs of different arities" (W-220, W-222; §1.11).
6.  **Records only in R and D.** No W-id or F-id appears in source, goldens or
    program headers (head, id allocation); the re-scan runs before D.
7.  **R31.** This plan's §2 code blocks sit between `<!--
    google-doc-style-ignore -->` and `<!-- google-doc-style-resume -->`
    lines, because the doc-style hook rewrites words inside code blocks; any
    record text that quotes code does the same.
