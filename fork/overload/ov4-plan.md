<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# OV-4 plan: `overload fn` members with default parameter values (W-341)

**Status:** rev 1, 2026-10-28, the planner's draft, for the two plan reviews
that R29 (c) keeps. Branch `claude/carbon-fork-0-1-ov4` in
/home/user/carbon-ov4, cut from trunk 66bd2ba90 (pushed, no commits of its own
before this plan). One PR, base trunk, merging last, after PR 66 (fork
ORCHESTRATION Next actions item 6: "after VA-2 lands and before UA-3"). The
work item is W-341 and only W-341 (size M), the overload workstream's
default-value slice; OV-4 mints no F id (R32 makes upstream's design the
spelling, so F-009j is rewritten, not re-minted) and reserves W-360 to W-364
for its residues. Every measurement below is container-local, EXPECTED, not of
record (R9).

W-341 as filed names two changes, the arity range and the probe over the
supplied arguments. The audit finds that neither is reached first: on trunk a
member with a defaulted parameter is refused at its declaration by D-OV-6 gate
(iii), "`overload fn` with a non-value explicit parameter" (§0.3, every probe
on five toolchains), because the gate does not look through the
`DefaultValuePattern` that wraps the parameter. Lifting the gate exposes two
more defects that the filed mechanism does not mention: member identity
(D-OV-3) treats a default value as a different parameter, so a declaration that
differs from a member only in its default silently becomes a second,
unreachable member, and a declaration whose default is not trailing, which the
plain call path already crashes on (trunk and the nightly, §0.3 p21), would
start crashing through a set. The plan fixes all five at their roots in four
files (§2), with no second resolution path and no new diagnostic, measured on a
prototype build: 1946 of 1946 goldens (trunk's 1942 unchanged plus the four new
files), 130/0/22 over 152 programs (trunk's 128/0/22 over 150 plus the two
new programs), five mutants each caught (§0.5).

## Sections

-   §0 Audit: baseline, upstream at the tip, measurements, the resolution path,
    the prototype and mutants, collisions, programs, register, ids.
-   §1 Design: decisions D-OV4-1 to D-OV4-16, each with its break condition
    (D-OV4-17, the commit sequence, is in §3).
-   §2 Spec, file by file, with the reviewed diffs.
-   §3 Commits, the fix budget, the shrink line and the land-time commits.
-   §4 Testdata matrix.
-   §5 Conformance delta.
-   §6 Churn and collisions with the held PRs.
-   §7 Risks and rejected alternatives.
-   §8 Verification.
-   Hand-off notes, then Appendices A to D (golden sources, programs, docs
    amendments and records texts, verbatim).

## §0 Audit

### §0.1 Baseline and environment

The task's check holds: `git diff --stat 0bdce60a5 66bd2ba90 -- toolchain core`
prints nothing, so trunk's toolchain, prelude and testdata equal 0bdce60a5's and
the install /home/user/carbon-build/carbon-trunk/install/bin/carbon
(`0.0.0-0.dev+0bdce60a5`) is the baseline for every probe. The planner's own
build of this worktree (`CB_BUILD_ROOT=/dev/shm/ov4-planner/builds`, build.sh
and install.sh, 7.5 minutes on 4 cores, `0.0.0-0.dev+66bd2ba90`) re-measured the
baseline before any change: gate 1942 passed, 0 failed (24 s); conformance PASS
128, COMPILE-FAIL 0, LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH
0, SKIP 22 of 150, bullets 48 PASS, 0 FAIL, 8 SKIP, 0 NOT-WRITTEN of 56 (60.2
s). The bullet "Functions: function overloading (Carbon-native)" is PASS with 7
programs. Other toolchains read: PR 59's install (`+88b1b5bd2`), PR 66's
(`+1517517eb`), PR 61's (`+eafca5cb9`), PR 64's (`+224ee2f8f`) and the nightly
`0.0.0-0.nightly.2026.10.12+62f1cc6` (an oracle only, R30). Probes, logs and the
saved prototype are under
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ov4/planner
(`$Q` below): `$Q/probes`, `$Q/out-<toolchain>.txt`, `$Q/saved`,
`$Q/proto-toolchain.diff`.

### §0.2 Upstream at the tip, and every commit since the cut (R32 (a), (c))

`git -C /home/user/carbon-lang fetch -q upstream trunk` leaves upstream/trunk at
**e6fddcf97** (2026-10-27 22:16 UTC, "Add all stores in File to
CollectMemUsage", upstream PR 8050), the tip named for 2026-10-28 00:54 UTC, 133
commits past the cut c1e83b0b7. Every quote below is read there by sha.

_The design text._ Upstream's design pages and proposals at e6fddcf97 do not
describe parameter default values:

-   docs/design/functions.md: `git grep -c -i -E 'default (value|argument)'`
    over functions.md and pattern_matching.md is 0. Its declaration forms
    (:54-57) are "`fn` _name_ [_implicit-parameters_] [_tuple-pattern_] ..."
    with no default; its "Positional parameters" (:242-247) are the `$0`
    parameters of a body without a parameter list, a different feature.
-   docs/design/classes.md:2186-2191, "Optional named parameters", under Future
    work: "Structs are being considered as a possible mechanism for
    implementing optional named parameters. We have three main candidate
    approaches: allowing struct types to have field defaults, having dedicated
    support for destructuring struct values in pattern contexts, or having a
    dedicated optional named parameter syntax." An open question about
    _named_ optional parameters.
-   proposals/: no accepted proposal names positional default values; the
    nearest text is p006254:147-148, about C++ callees: "**Default
    Arguments:** The Carbon call omits arguments that have default values in
    C++. The thunk provides the default values."
-   docs/design/pattern_matching.md:696-697: "We do not yet have an approved
    design for overloaded functions, but it is anticipated that declaration
    order will be used in that case too." Upstream has no overload sets, so
    the interaction of defaults with overload resolution has no upstream text.

_The mechanism, in upstream's toolchain at e6fddcf97 (R32 reads toolchain text
that names a mechanism)._

-   toolchain/check/call.cpp:46-52, `ResolveCalleeInCall`'s comment: "It also
    verifies that the number of arguments is within the range [callee_arity -
    arity_lower_bound_margin, callee_arity]. This allows arity matching when
    the callee has default arguments for some subpatterns." and :241, the plain
    call passing `function.default_value_arity` as that margin.
-   toolchain/check/function.cpp:676-687, `CheckDefaults` (moved there from
    handle_function.cpp by 1b0a5709e): "ensure that if a subpattern provides a
    default value, all subsequent patterns at that level of nesting must
    provide a default value as well. Returns the number of default values
    provided at the top level" and "TODO: per
    https://github.com/carbon-language/carbon-lang/issues/7529, this should
    also consider automatically supplied defaults for fully-specified tuple
    subpatterns".
-   toolchain/check/pattern_match.cpp:950, in the caller's `DefaultValuePattern`
    pre-work: "If there's no scrutinee supplied, supply the default value
    instead.", reached by `CallerPatternMatch`'s `zip_longest` (:1250-1254).
-   toolchain/check/handle_pattern_list.cpp:177 and :185: "default values are
    only supported in parameter lists" and "default value is not a constant".
-   toolchain/check/deduce.cpp:640 (503f09037): "If we are short on arguments,
    check if we can append default values for deduction."; pattern.cpp:363
    `ExtractParameterDefault`.
-   toolchain/check/cpp/export.cpp:964 `BuildDefaultValueExpr` (9799a2326,
    8fdc8ebc3), used at :1223 and :1422 (c7de72757).
-   toolchain/sem_ir/entity_with_params_base.h:136-139: "A count of the
    top-level explicit parameters that have default values provided. This is
    useful for quickly bounds-checking caller argument arity."
-   Goldens: function/call/default_values.carbon (its
    `fail_caller_too_few_arguments` split: "0 arguments passed to function
    expecting 2 arguments"), function/declaration, function/definition and
    function/generic default_values.carbon, interop/cpp/function/export and
    lower default_values.carbon, parse/function/default_values.carbon.

The direction is therefore upstream's toolchain mechanism with no design page:
trailing positional defaults whose values are constants, filled by the plain
call. F-009j's "no Carbon-native default arguments in 0.1" denies a mechanism
upstream implements, the R32 (d) drift W-341 files; OV-4's rule follows the
toolchain and stops, for named optional parameters, at classes.md's open
question (R32 (d); §1 D-OV4-15).

_Every upstream commit since the cut that touches default values_ (from `git
log c1e83b0b7..upstream/trunk` over handle_function.cpp, function.cpp,
call.cpp, deduce.cpp, pattern.cpp, pattern_match.cpp, handle_pattern_list.cpp,
merge.cpp, import_ref.cpp, cpp/export.cpp, entity_with_params_base.h and the
four default_values goldens, each diff grepped for `default_value`,
`DefaultValue`, `ExtractParameterDefault`, `CheckDefaults`,
`arity_lower_bound_margin` and `default_values`, plus a grep of subjects for
"default"):

| sha | date | subject (upstream PR) | what it does to default values |
| --- | --- | --- | --- |
| 1b0a5709e | 2026-10-06 | Initial support for fn expressions. (7893) | moves `CheckDefaults` to function.cpp, unchanged (W-362's merge rule) |
| 2c9739799 | 2026-10-15 | Render diagnostics through the terminal library (7683) | `RequiredPatternDefaultValue*` notes become labels; goldens re-rendered |
| d87891f3a | 2026-10-15 | Fix diagnostic style issues (7982) | drops the trailing period of the `RequiredPatternDefaultValue*` texts |
| 9799a2326 | 2026-10-20 | Export function default values to C++ (7988) | exported C++ declarations get default arguments |
| 503f09037 | 2026-10-21 | Add support for default values for non-generic parameters of generic functions. (8011) | deduction appends defaults for omitted arguments |
| 427c448dc | 2026-10-24 | Simplify the generic function default values test. (8027) | golden only |
| 8fdc8ebc3 | 2026-10-25 | Fix use-after-free of var name in BuildDefaultValueExpr (8025) | export fix |
| c7de72757 | 2026-10-26 | Adds support for exporting default values for concrete parameters of generic functions. (8019) | export of generic functions' defaults |

Golden churn only, no mechanism: 24766e213, 62f1cc6a3, 05a7ecbd3 and
b766aa4d1. No commit since the cut changes the arity margin, the caller's fill
or the trailing-default rule, and none adds design text; the arity rule OV-4
copies is the cut's and the tip's alike.

### §0.3 Measurements (probes `$Q/probes/p*.carbon`, every toolchain)

Each probe is compiled with `carbon compile --output-last-input-only`, linked
and run where it compiles (`$Q/bin/probe.sh`). "TODO(iii)" is gate (iii)'s
"semantics TODO: ``overload fn` with a non-value explicit parameter`" at the
defaulted parameter; "NoMatch" is "no member of overload set `F` accepts this
call" with its notes. Trunk, PR 59, PR 66, PR 61 and PR 64 agree on every row,
so one column carries them; "proto" is the prototype of §2; the nightly has no
`overload fn` and runs the plain rows only.

| probe | trunk = PR 59 = PR 66 = PR 61 = PR 64 | proto | nightly |
| --- | --- | --- | --- |
| p01 plain `fn F(x: i32, y: i32 = 2)`, `F(1)`, `F(1, 5)` | prints 12, 15 | 12, 15 | 12, 15 |
| p02 set with that member and `F(b: bool)`, `F(1)` | TODO(iii); NoMatch, notes "candidate takes a different number of arguments" (member 0) and "candidate has a parameter its argument cannot implicitly convert to" (member 1) | 12 | n/a |
| p03 the same set, `F(1, 5)`, `F(true)` | TODO(iii) only (the call resolves) | 15, 1 | n/a |
| p04 `Pick(x, y = 2)` then `Pick(x)`, `Pick(5)`, `Pick(5, 6)` | TODO(iii) | 1, 1 | n/a |
| p05 `Pick(x)` then `Pick(x, y = 2)`, same calls | TODO(iii) | 2, 1 | n/a |
| p06 plain generic `fn G[T: type](x: T, y: i32 = 2)`, `G(true, 5)`, `G(true)` | "cannot deduce value for generic parameter `T`" at `G(true)` | same | same |
| p07 that generic function as a set member | TODO(iii); NoMatch, arity note | NoMatch, "candidate has generic parameters that could not be deduced" | n/a |
| p08 method `M(self, y: i32 = 2)` and `M(self, b: bool)`: `c.M()`, `c.M(5)`, `C.M(c)`, `C.M(c, 7)` | TODO(iii); NoMatch at `c.M()` and `C.M(c)`, arity notes | 102, 105, 102, 107 | n/a |
| p08b the plain method | 102, 105, 102, 107 | same | same |
| p09 a set in `class Box(T: type)`, `Box(bool).Get()`, `.Get(9)` | TODO(iii); NoMatch | 2, 9 | n/a |
| p09b the plain generic-class method | 2, 9 | same | same |
| p10 a defaulted member imported from library "dl", `F(1)`, `F(1, 5)`, and a plain `P(1)` | TODO(iii) in the library; NoMatch in the importer (the imported member's arity note) | 13, 12, 15 | n/a |
| p10n the plain imported function | 13, 15 | same | same |
| p11 default `1 + 1` | TODO(iii); NoMatch | 12 | n/a |
| p11b default naming a file-scope `let K` | "default value is not a constant" | same | same |
| p11c default naming the earlier parameter `x` | "default value is not a constant" | same | same |
| p12 `var x: i32` before a default; p12b a tuple pattern before a default | TODO(iii) at the `var` or tuple parameter; NoMatch for the one-argument call | TODO(iii) at the `var` or tuple parameter only (the calls resolve) | n/a |
| p12c a defaulted tuple pattern; p12d a defaulted `var` parameter | TODO(iii) at the defaulted parameter; NoMatch for the one-argument call | TODO(iii) at the defaulted parameter only | n/a |
| p13 `F(x, y = 2)` then `F(x, y)` (definitions) | TODO(iii) | "redeclaration differs at parameter 2" | n/a |
| p13b the same two plain declarations | "redeclaration differs at parameter 2" | same | same |
| p13c defaults 2 and 3 on type-equal members | TODO(iii) twice; NoMatch | "redeclaration differs at parameter 2" | n/a |
| p13d forward declaration and definition with the same default | TODO(iii) twice; NoMatch | 12 | n/a |
| p13e `M[self: Self](y = 2)` and `M[ref self: Self](y)` | "`self` must be declared in the explicit parameter list" twice, TODO(iii), "members distinguished only by `self`" | the same without TODO(iii) | n/a |
| p14 `F()` below the minimum | TODO(iii); NoMatch, two arity notes | NoMatch, two arity notes | n/a |
| p15 `F(true)` against `F(x, y = 2)` and `F(b, c)` | TODO(iii); NoMatch, two arity notes | NoMatch: conversion note (member 0), arity note (member 1) | n/a |
| p16 a set called from `fn T(template U: type, u: U)`, `T(i32, 1)` | TODO(iii); "unable to monomorphize specific `T(i32)`" with NoMatch | exits 1 (member 0) | n/a |
| p16b the plain function in the template | exits 1 | same | same |
| p17 class-typed default `d: C = {.v = 3}`, initializing argument `F(MakeC())` | TODO(iii); NoMatch | 73, 77 | n/a |
| p18 set exported to C++, C++ `Carbon::F(1, 5)` | TODO(iii) | exits 15 | n/a |
| p18b the same set, C++ `Carbon::F(1)` | TODO(iii) | exits 255: C++ selects `F(bool)`, -1 | n/a |
| p18c a plain defaulted function exported, C++ `Carbon::P(1)` | Clang "too few arguments to function call, expected 2, have 1" | same | same |
| p19 all-defaulted `F(x = 4, y = 2)`: `F()`, `F(7)`, `F(7, 8)`, `F(true)` | TODO(iii); NoMatch at `F()` and `F(7)` | 42, 72, 78, -1 | n/a |
| p20 generic member `Get[U: type](u: U, y = 2)` in a generic class, `Get(1, 9)`, `Get(1)` | TODO(iii); NoMatch | NoMatch at `Get(1)`, deduction note | n/a |
| p21 plain `fn F(x: i32 = 1, y: i32)` called `F(5)` | the error "this pattern is missing a required default value." then a CRASH, `CHECK failure at toolchain/check/pattern_match.cpp:1275: scrutinee_id.has_value()` | the error, then "1 argument passed to function expecting 2 arguments" | CRASH |
| p21b the same declaration as a set member | TODO(iii); NoMatch | the error, then NoMatch with an arity note | n/a |

Three readings matter for the design. First, the filed mechanism is necessary
but not sufficient: gate (iii) refuses every defaulted member before the arity
step, and once the gate looks through the default, the arity step and the probe
are exactly W-341's (mutants M1 and M2 below). Second, the prototype's set
column equals the plain column wherever the plain function exists (p01/p02,
p08/p08b, p09/p09b, p10/p10n, p16/p16b, p13/p13b): the plain path is the oracle
and the set reaches it. Third, generic members (p06, p07, p20) fail in the
plain path on trunk too, by deduction; the set reports that as reason 2, the
same failure.

### §0.4 Where a defaulted member enters each step of resolution

The path is OV-1's `PerformCallToOverloadSet` (trunk call.cpp:601-712), its
steps as D-OV-4 numbers them (fork/overload/plan.md:348-520):

1.  Erroneous arguments and gate (xi) (:605-626): unchanged; the arguments are
    the call's, and an omitted argument is no argument.
2.  (a) Receiver alignment (:646-652): unchanged; `self` never has a default
    in any probe (p13e shows `self` in the implicit list is refused first).
3.  (b) Arity (:654-660): `GetExplicitArityRange` (:420-432) returns `{n, n}`
    with `n` = parameter patterns less one when the call binds a receiver; its
    comment (:420-423) says "Carbon has no default arguments, so the range is
    exact". The plain path checks `[n - default_value_arity, n]` at
    `ResolveCalleeInCall` (:73-82), with `default_value_arity` passed at :310.
    This is the step W-341 names.
4.  (d) Deduction (`ProbeOverloadCandidateInScratchScope`, :502-516): the
    probe passes the supplied explicit arguments to
    `DeduceGenericCallArguments`, as `ResolveCalleeInCall` does at :108-117.
    Trunk's deduce.cpp:72-78 (`AddAll`) treats a parameter list whose length
    differs from the argument list's as non-deduced, so a generic function's
    own bindings stay undeduced when an argument is omitted (p06's
    `DeductionIncomplete`); a member of a generic class has no own bindings to
    deduce and passes (p09b). Upstream's 503f09037 appends the defaults there.
5.  (e) The conversion probe (:518-555): `CARBON_CHECK(param_pattern_ids.size()
    == arg_ids.size())` at :498 and `llvm::enumerate(arg_ids,
    param_pattern_ids)`, which requires equal lengths: widening the range alone
    stops here (mutant M1). A `DefaultValuePattern` carries its subpattern's
    pattern type (typed_insts.h:757-766, handle_pattern_list.cpp:357-367), so
    `GetScrutineeTypeInSpecific` (generic.cpp:924-931) reads the parameter's
    type through it unchanged: a supplied argument for a defaulted parameter is
    probed exactly like any other (p03).
6.  Commit (:675-690): `BuildNameRef` of the member, the `BoundMethod` re-wrap,
    then `PerformCallToFunction` (:298) with the call's `arg_ids`. That is the
    plain path from here: `ResolveCalleeInCall` with `default_value_arity`
    (:307-310), `ConvertCallArgs` (:350, convert.cpp:2825), whose
    `CallerPatternMatch` (pattern_match.cpp:2533-2585) zips
    `concat(self_arg_refs, arg_refs)` against the parameter patterns with
    `zip_longest` (:2552-2569) and passes `None` for each omitted argument;
    `DoPreWork` for a `DefaultValuePattern` (:2273-2297) then supplies the
    default value through `WrapInstForSpecific` (:2278-2285). Nothing on the
    commit path knows it came from a set, so the fill is upstream's, unchanged
    (the golden's `call %Scale.ref(%.loc10_32.2, @Scale.loc5.%.loc5_41.2)` is
    the plain golden's `call %F.ref(%.loc7_6.6, @F.%.loc3_34.6)` shape).

Outside the call path:

-   Gate (iii) (handle_function.cpp:851-882, `DiagnoseOverloadGates`) requires
    each explicit parameter after `self` to be a `WrapperBindingPattern` whose
    subpattern is a `ValueParamPattern`; `y: i32 = 2` is a
    `DefaultValuePattern` whose subpattern is that binding, so the gate fires
    (every TODO(iii) cell above).
-   Member identity (handle_function.cpp:360-370, `TryMergeIntoOverloadSet`)
    calls `CheckRedeclParamsMatch(..., /*diagnose=*/false,
    /*check_syntax=*/false)`, which reaches merge.cpp's `CheckRedeclParam`: a
    kind difference (`DefaultValuePattern` against `WrapperBindingPattern`,
    :262) or a different default constant (:338-355) is a mismatch, so the
    declaration becomes a new member (p13 and p13c with the gate lifted alone:
    both compile, the second member never selected).
-   `CheckDefaults` (handle_function.cpp:913-1045) diagnoses a non-trailing
    default but still returns the level's count (:1040), so
    `default_value_arity` admits a call that omits a parameter with no
    default, and
    `CallerPatternMatch` then reaches pattern_match.cpp:1275's
    `CARBON_CHECK(scrutinee_id.has_value())` (p21, plain, trunk and nightly).
    Upstream's tip has the same `CheckDefaults` (only its diagnostic rendering
    differs) and the same `ResolveCalleeInCall`; the crash at the tip is
    inferred, not measured (no tip build).
-   Import: import_ref.cpp:2806 copies `default_value_arity`, and :2459-2467
    imports a `DefaultValuePattern` as a deduplicated constant; the set's probe
    reads the imported member's pattern types through
    `GetScrutineeTypeInSpecific` and its commit fills `constants.%int_2` (the
    imported default; §4).
-   Export (OV-3): trunk predates 9799a2326, so an exported member's C++
    declaration has no default argument (p18c for a plain function; p18b for a
    set member, where C++ then selects another member).

### §0.5 The prototype and its mutants

The prototype is §2's diff on this worktree (`$Q/proto-toolchain.diff`, 243
lines over call.cpp, handle_function.cpp, merge.cpp and merge.h), with
Appendix A's four golden files and Appendix B's three program files; it was
committed only as the scratch commit `4d5eff6de` (`git commit-tree`, on no
branch) for the merge-tree runs, and the worktree was restored after this plan's
measurements. Measured on it: clang-format 21.1.8 (`--assume-filename`) leaves
the four files unchanged after formatting; clang-tidy 21.1.8 (VA-2's two
passes, `$Q/bin/tidy.sh`, `--checks='-*,misc-no-recursion'
--warnings-as-errors='*'` and the repository's .clang-tidy minus `modernize-*`
line-filtered to the changed lines) prints nothing on the three .cpp files;
autoupdate reaches its fixpoint on the four new goldens after two writing
passes (the first writes all four, the second rewrites one, `..!.`, a line
number shift as R26 describes) and a third that changes nothing (`....`); the
gate passes 1946 of 1946; conformance PASS 130, SKIP
22, nothing else, of 152, bullets 48 PASS of 56, the overloading bullet PASS
with 9 programs (46.3 s).

Mutants, one per decision, each an edit of the prototype rebuilt and run on
the four new goldens (`gate.sh --file_tests=...`) and the probes:

| mutant | edit | measured |
| --- | --- | --- |
| M1 (D-OV4-1 without D-OV4-2) | the range widened, the probe's `CARBON_CHECK(param_pattern_ids.size() == arg_ids.size())` kept | p02 and p04 abort: "CHECK failure at toolchain/check/call.cpp:509: param_pattern_ids.size() == arg_ids.size()"; the gate aborts (exit 134) |
| M2 (D-OV4-2 without D-OV4-1) | the probe's prefix kept, the range exact | all four goldens FAILED; both programs COMPILE-FAIL |
| M3 (D-OV4-3 reverted) | gate (iii) not looking through the default | all four goldens FAILED ("Autoupdate would make changes"); p02 prints TODO(iii) |
| M4 (D-OV4-4 reverted) | identity through `CheckRedeclParamsMatch` again | default_values.carbon FAILED; p13 compiles with exit 0, an unreachable second member |
| M5 (D-OV4-5 reverted) | `CheckDefaults` returns the level's count | the gate aborts (exit 134): "CHECK failure at toolchain/check/pattern_match.cpp:1275: scrutinee_id.has_value()" |

A scratch measurement for D-OV4-7: 503f09037's pattern.cpp and pattern.h hunks
applied with `git apply` and its deduce.cpp hunk applied by hand around the
fork's `diagnose` parameter, on top of the prototype: p06 prints 5, 2; p07
(the generic member in a set) prints 5, 2; p20 prints 9, 2. With no OV-4 code
for generic members, the set takes upstream's deduction once it arrives, which
is UA-3's (reverted; not part of any commit).

### §0.6 Collisions with the held PRs (numstat, then `git merge-tree`)

Numstat of OV-4's files on each held head against its merge base with trunk
(heads re-read at 2026-10-28 after `git fetch origin`):

| PR | head | OV-4's files it touches |
| --- | --- | --- |
| 51 UA-2 | f96fe8a7a | functions_overloading.md +14 -1 (the 0.1 limits item (xi) and the template paragraph), conformance README +3 -3 |
| 52 CM-1 | e6bc32a6d | conformance README +63 -2 |
| 53 SAFE-1 | 2407efa74 | none |
| 54 EV-1 | cb3ef2e74 | conformance README +10 -1 |
| 55 ST-1 | c3cdecc5d | README +5 -1, cpp/export.cpp +5 |
| 56 OP-1 | 9f12209d8 | README +8 -1 |
| 57 OP-2 | e23113ba2 | README +12 -1 |
| 58 DD-1 | fcee90d9b | README +19 |
| 59 VA-1 | b0822a744 | call.cpp +194, handle_function.cpp +19 (gate (iii)'s loop and `CheckDefaults`), merge.cpp +9, deduce.cpp +35, pattern_match.cpp +25, import_ref.cpp +40, export.cpp +12, README +9 -1 |
| 60 SC-1 | cc4daba00 | merge.cpp +238 -29, merge.h +32 -4, handle_function.cpp +51, call.cpp +14, import_ref.cpp +86 -1, README +2 -1 |
| 61 TP-1 | 66aa13132 | call.cpp +30 -2, import_ref.cpp +504 -12, README +10 |
| 62 SV-1 | 0ef8a0334 | README +6 -1 |
| 63 DR-1a | 89aabd125 | none |
| 64 CT-1 | 551a03328 | call.cpp +103 -2, import_ref.cpp +504 -12, README +19 -2 |
| 65 DR-1b | fee0ef31c | call.cpp +4 -1 (return storage), README +2 |
| 66 VA-2 | 43c8ab476 | as PR 59, with deduce.cpp +127, pattern_match.cpp +73, import_ref.cpp +108, merge.cpp +13, and four overload goldens refilled (basic, generic_class_method_set, import, import_class_scope) |
| 67 RG-1 | 56e2e5bbd | none |

`git merge-tree --write-tree --name-only` of the prototype tree against each
head, less that head's own conflicts with trunk 66bd2ba90 (computed the same
way): new conflicts only on PR 59 and PR 66
(toolchain/check/handle_function.cpp, gate (iii)'s loop, where VA-1 inserts its
pack gate at the line OV-4 inserts the look-through) and on PR 60
(toolchain/check/merge.cpp, `CheckRedeclExplicitParamsAfterSelfMatch`'s return,
where SC-1 adds the `new_specific_id` and `found_error` arguments). Every other
head, call.cpp of PR 59, PR 61, PR 64, PR 65 and PR 66 included, merges cleanly.
Two semantic collisions merge cleanly and are caught only by building: SC-1 adds
two parameters with no defaults to `CheckRedeclParams` and
`CheckRedeclParamLists` (PR 60 merge.cpp:562-567 and :585-590), so OV-4's new
`CheckOverloadMemberParamsMatch` must pass `SemIR::SpecificId::None` and
`nullptr` after M (§6.2); and VA-1's pack gate must run before OV-4's
look-through. The mirror m66 (§8.7) applies both rules to PR 66 merged with the
prototype: `$Q/m66-*.log`.

### §0.7 Conformance programs touched and new

OV-1's programs live in fork/conformance/programs/functions/
(`overloading_native`, `overloading_methods`, `overloading_generic`,
`overloading_generic_class`, the multi-unit `overloading_cross_library`) and
OV-3's in interop/ (`cpp_export_overload_set`, its `_divergence` sibling), all
under the bullet "Functions: function overloading (Carbon-native)". None
declares a defaulted member and none changes. New (Appendix B):
`functions/overloading_default_values.carbon` (hand-derived EXPECT, 13 lines)
and the differential pair `functions/overloading_default_values_diff.carbon`
with `overloading_default_values_diff.diff.cpp` (DIFF-1: no EXPECT-STDOUT, the
C++ twin's stdout and exit are the oracle; the set is not exported, so R30's
"no `.diff.cpp` for an exported set" does not apply). Measured: both PASS on
the prototype, both COMPILE-FAIL on trunk; `runner.py --self-test` on the
prototype reports 152 programs, 56 bullets, OK after `--update-readme-table`
adds their two rows.

### §0.8 The V-3a register (DR-0) and RG-1's vocabulary

DR-0's register keeps (i) PR 62's D-SV-7 view, (ii) D-SL-3's read-only slice
and (iii) the pointer cursor (decision-log.md:243-248), all resolved on held
branches; none concerns default values. RG-1 (PR 67, its decision-log V-3 group
and fork/register/rg1-plan.md §2.T2) classifies F-009's marker NONE (D-RG-6)
and its closed sets and first match ALIGNED (T2.5, T2.6), each watched by W-355,
and does not classify F-009j, which W-341 had filed as a drift the day before.
In RG-1's vocabulary (D-RG-1 to D-RG-6): an entry is a DRIFT when upstream has
designed its mechanism and the fork spells it otherwise, ALIGNED when the fork's
spelling or rule is upstream's, NONE when upstream is silent; toolchain text
that shows a mechanism with its spelling counts as upstream's (R32's reading
list), and toolchain-internal surfaces are NONE with their merge rules as break
conditions (D-RG-3). OV-4 adds two lines at land time after PR 67 (§1
D-OV4-15, Appendix D.6): F-009j becomes ALIGNED, quoting the toolchain text of
§0.2; the rule between members that accept a call through defaults is NONE,
with silence checks for W-355's weekly run.

### §0.9 Id re-scan

After `git fetch origin`, `git grep -h -o -E '\bW-3[6-9][0-9]\b'` over every
ref in `refs/remotes/origin` and `refs/heads` (164 refs) finds only W-398 and
W-399, each in the range text "W-330 to W-399" of DR-1's, RG-1's and VA-2's
plans; the same grep over the fork/, docs/ and toolchain/ trees of all 22
worktrees finds W-360 once, in this worktree's untracked prototype golden (the
`TODO(UA-3, W-360)` of Appendix A.1), and W-398 and W-399 as above. W-360 to
W-364 are free. RG-1's W-346 to W-356 are on PR 67's branch, W-357 and W-359
appear only as its "unused reserve" text, and W-358 nowhere.

### §0.10 Stale or contradicted claims found

-   The task's context says PR 59's `GetExplicitArityRange` is "widened for
    packs at :574-587"; PR 59's call.cpp:574-587 keeps the exact range and the
    comment "Carbon has no default arguments" (PR 59 gates variadic members
    instead, its `TODO("variadic member of an overload set")`, D-VA-4, W-223),
    as W-341's own notes say. OV-4's call.cpp merges cleanly with it.
-   W-341's mechanism omits gate (iii), member identity and the non-trailing
    default (§0.3, §0.4): its notes' "The call is diagnosed, not miscompiled
    (read from the code; no build this week)" is right, but the diagnostic is
    gate (iii)'s TODO at the declaration first, then `OverloadNoMatch`.
-   W-341's evidence cites "check/cpp/export.cpp:1209 `BuildDefaultValueExpr`"
    at 21c825a3f; at e6fddcf97 the definition is at :964 and the uses at :1223
    and :1422 (c7de72757 moved it).
-   fork/overload/plan.md:380 and :2173 and docs/design/functions_overloading.md
    :540-545, :570-576 and :1022-1023 are the only sentences of the two files
    that say or assume Carbon has no default arguments (`git grep -n -i -E 'no
    default arg|has no default|no Carbon-native default|default-argument
    design'` over docs/ and fork/); the page's "0.1 limits" item (iii) and its
    "New member versus redeclaration" CLOSED paragraph need a sentence each,
    since D-OV4-3 and D-OV4-4 change what they cover.

## §1 Design

The rule, stated once: **an `overload fn` member with default values behaves,
for the number of arguments it is called with, exactly as the ordinary call of
the same function would if it were the only one; between two members that both
accept a call, the first in declaration order is selected (D-OV-4).** The plain
call path is the oracle. Every decision below is that rule applied to one step,
auto-adopted under R29 (a) and veto-able after the fact; none has a second path
or a new diagnostic.

**D-OV4-1 — the arity rule.** `GetExplicitArityRange` returns `[n -
default_value_arity, n]`, with `n` the member's parameter patterns less one when
the call binds a receiver, exactly the range `ResolveCalleeInCall` checks for
the plain call (call.cpp:73-82 with the margin passed at :310; upstream
call.cpp:46-52 and :241 at e6fddcf97), and with that function's
`CARBON_CHECK(default_value_arity <= n)`. The range stays keyed on the call's
receiver (D-OV-4 step 2(b)): through `c.M()` the explicit arguments after
`self` count, through `C.M(c)` the receiver is argument 0 (p08). The comment at
call.cpp:420-423 is rewritten (§2.1). _Break condition:_ upstream changes how
the plain call computes its range (for example issue 7529's automatic defaults
for fully-specified tuple subpatterns, function.cpp:682 at e6fddcf97), and the
range follows it, since it reads the same `default_value_arity`; or upstream's
design picks another optional-parameter mechanism (classes.md:2186-2191's
candidates) or removes positional defaults, and W-341's break condition fires.

**D-OV4-2 — the probe converts the supplied arguments; the commit fills the
rest.** `ProbeOverloadCandidateInScratchScope` zips the supplied arguments with
the leading parameter patterns (`take_front(arg_ids.size())`), deducing a
generic member from the supplied explicit arguments as the plain call does
(call.cpp:108-117). Its CHECK at :498 becomes the invariant the arity step now
guarantees: the arguments are a prefix of the parameters, and every omitted
parameter is one of the trailing `default_value_arity` defaulted ones. The
commit is unchanged: `PerformCallToFunction` reaches `CallerPatternMatch`,
whose `zip_longest` and `DefaultValuePattern` pre-work supply each omitted
default (§0.4 step 6). A default value is a constant of the parameter's type
already converted at the declaration (handle_pattern_list.cpp:357-367), so
there is nothing in it to probe. One resolution path serves members with and
without defaults. _Break condition:_ a default whose value depends on the
call (a non-constant default, or a default of a parameter whose type is
deduced from it), which upstream does not allow today
(handle_pattern_list.cpp:185 at e6fddcf97 "default value is not a constant");
the probe would then have to probe the default too.

**D-OV4-3 — gate (iii) looks through a default value.** D-OV-6 gate (iii)
requires each explicit parameter after `self` to be a single by-value binding,
because the probe is a value conversion. A `DefaultValuePattern` adds a default
to the pattern it wraps and changes nothing else, so the gate reads the wrapped
pattern: `y: i32 = 2` is accepted, a defaulted `var` parameter or a defaulted
tuple pattern is still gated (p12c, p12d), and the TODO stays at the parameter
as written. _Break condition:_ gate (iii) is lifted (W-095), and this
look-through goes with it.

**D-OV4-4 — member identity ignores default values (D-OV-3, F-009k).** Member
identity is parameter-type equality; a default value is part of a
declaration's tokens, not of a parameter's type. `TryMergeIntoOverloadSet`
compares with `CheckOverloadMemberParamsMatch`, which is the comparison it made
(`CheckRedeclParamsMatch` with `check_syntax` false) applied to the explicit
parameter patterns with each top-level `DefaultValuePattern` replaced by the
pattern it wraps; `CheckRedeclExplicitParamsAfterSelfMatch`, D-OV-3's
"distinguished only by `self`" test, reads the same stripped list. A
declaration that differs from a member only in a default is then a
redeclaration of that member, and the ordinary redeclaration check (merge.cpp
:338-355, `check_syntax` true) diagnoses `RedeclParamDiffers` exactly as for two
plain declarations (p13 against p13b), never an unreachable second member.
`CheckRedeclParam` itself is not changed, because thunk.cpp:466-469 also
reaches it with `check_syntax` false, through `CheckFunctionTypeMatches`
(function.cpp:358), for upstream's impl-against-interface comparison,
where a default difference must keep its upstream meaning. _Break condition:_
upstream's redeclaration rules (p003763) come to allow redeclarations that
differ in defaults; identity still ignores them and the ordinary check follows
upstream.

**D-OV4-5 — a diagnosed non-trailing default counts no defaults.**
`CheckDefaults` diagnoses "this pattern is missing a required default value."
and still returns the level's count, so the plain call of `fn F(x: i32 = 1, y:
i32)` with one argument passes the arity check and aborts at
pattern_match.cpp:1275 (p21: trunk, the nightly; upstream's tip has the same
function and call path, inferred). Once D-OV4-3 admits such a member, a set
reaches the same abort (mutant M5). The root is the count: a level with a
diagnosed missing default counts no defaults, so every caller supplies every
argument and gets `CallArgCountMismatch` (plain) or the arity note (set). It is
the plain path's fix, made here because OV-4 opens the set path to it; W-362
carries the merge rule into function.cpp at UA-3 and the upstream report. _Break
condition:_ upstream fixes the crash otherwise, and UA-3 takes upstream's fix
and drops this one.

**D-OV4-6 — two members that both accept a call: first match.** With defaults,
`Pick(x: i32, y: i32 = 2)` and `Pick(x: i32)` both accept `Pick(5)`. D-OV-4's
loop takes the first member in declaration order that accepts, so the defaulted
member wins when it is first (p04: 1, 1) and the exact member wins when it is
first (p05: 2, 1). That is D-OV-4 step 5 ("Ranking is deliberately absent")
and upstream's anticipated order, pattern_matching.md:696-697: "it is
anticipated that declaration order will be used in that case too". Using a
default is not a worse match and an exact arity is not a better one: there is
no ranking to extend. Such a set is legal; no diagnostic warns about the
overlap. _Break condition:_ upstream approves an overloading design that ranks
candidates, or one that rejects overlapping members.

**D-OV4-7 — generic members: OUT on trunk, by the shared deduction; IN at UA-3
with no OV-4 code.** A generic member whose defaulted parameter is non-generic
(`G[T: type](x: T, y: i32 = 2)`) called with `y` omitted fails deduction on
trunk exactly as the plain call does (p06's `DeductionIncomplete`), because
trunk's `AddAll` ignores a parameter list longer than its arguments; the set
reports the member with "candidate has generic parameters that could not be
deduced" (p07, p20). Upstream's 503f09037 appends the defaults inside
`DeduceGenericCallArguments`, the function both paths call; applied to the
prototype in a scratch build, it makes p06, p07 and p20 select and print with
no OV-4 change (§0.5). OV-4 does not cherry-pick it: its export.cpp half needs
9799a2326, which trunk lacks, and its deduce.cpp half lands in the function
PR 66 changes by +127 lines. The split `fail_todo_generic_member_default` pins
both the plain and the set behavior with a `TODO(UA-3, W-360)` comment, and
W-360 asks UA-3's audit to take 503f09037 and refill the split. A defaulted
member of a generic class whose own parameters are not generic is IN now (p09:
the enclosing specific supplies the class's bindings). _Break condition:_ UA-3
lands without 503f09037's deduce.cpp hunk, or PR 66's deduction changes the
result for a defaulted generic member; W-360 then re-plans.

**D-OV4-8 — methods and receivers.** No step adds a receiver rule:
`default_value_arity` counts explicit parameters, `self` included only when it
carries a default, which no probe could declare (p13e). The range for `c.M()`
is `[1 - 1, 1]` explicit arguments, and for `C.M(c)` it is `[2 - 1, 2]` with the
receiver probed against `self` as D-OV-4 step 2(e) does; both fill `n` at the
commit (p08: 102, 105, 102, 107, the plain method's output). _Break condition:_
upstream lets `self` take a default, and the receiver's alignment is re-read.

**D-OV4-9 — import.** An imported member carries `default_value_arity`
(import_ref.cpp:2806) and its `DefaultValuePattern` as a deduplicated constant
(:2459-2467), so the arity step, the probe and the commit read it unchanged
(p10: 13, 12, 15; the import splits fill `constants.%int_2`).
`GetOverloadMemberParamPatterns` reads each pattern through its constant, as
`CheckRedeclParam` does, so identity sees through an imported default too.
_Break condition:_ upstream stops importing `default_value_arity` or the
pattern, which would break its own plain imported call
(function/call/default_values.carbon `imported_callee`) first.

**D-OV4-10 — export to C++ (OV-3): what trunk does, pinned on both sides.**
Trunk predates 9799a2326, so each exported member's C++ declaration has no
default argument (p18c for a plain function). A C++ call that supplies every
argument selects the member (p18: 15); a C++ call that omits one is resolved by
C++ among the other members, so `Carbon::F(1)` selects `F(bool)` (p18b: -1)
where Carbon's `F(1)` selects the defaulted member, and with no other viable
member Clang rejects the call ("no matching function for call to 'F'"). The
split interop/cpp/function/export/overload_set_default.carbon and its lower
twin pin both sides (R30); no exported-set program is added, because the C++
side's selection is the pre-9799a2326 export, which UA-3 changes. W-361 carries
it: at UA-3, 9799a2326, 8fdc8ebc3 and c7de72757 give each exported member its
default arguments, the divergence split's C++ side moves to the defaulted
member, and that change is recorded in the decision log before the golden
moves (R30 (c)). _Break condition:_ the per-member export path stops exporting
a defaulted member (it is exported today), or UA-3's export differs from the
plain function's.

**D-OV4-11 — template-dependent calls.** Since UA-1 a call with a
template-dependent argument is deferred as a `CallAction` and resolved for each
specific (fail_todo_gates.carbon's `template_dependent`), where the arguments
are concrete and the rule above applies (p16: member 0, exit 1); gate (xi)
stays for a call that is not deferred. PR 61's gate changes nothing on this
path; the mirror m61 confirms it at implementation time (§8.7). _Break
condition:_ PR 61's or a later change resolves a dependent call before
substitution, which would then reach the arity step with dependent arguments.

**D-OV4-12 — what a default may be.** Upstream's toolchain requires a constant
(handle_pattern_list.cpp:185 at e6fddcf97, "default value is not a constant");
`1 + 1` is a constant (p11: 12), a file-scope `let K` and an earlier parameter
`x` are not (p11b, p11c, on every toolchain). Upstream's design pages say
nothing (§0.2), so OV-4 stops at the toolchain's rule and adds none. _Break
condition:_ upstream allows a default to name an earlier parameter, and
D-OV4-2's break condition fires with it.

**D-OV4-13 — diagnostics.** No new diagnostic kind and no text change.
`OverloadCandidateRejected`'s reason 0, "candidate takes a different number of
arguments", is true of a range (it says "different", not "the wrong number of
N"), and upstream's own `CallArgCountMismatch` for a defaulted function names
only the maximum ("0 arguments passed to function expecting 2 arguments",
function/call/default_values.carbon). A supplied argument that does not convert
is reason 1 (p15). _Break condition:_ a review shows the note misleads for a
real call (for example a call within the range rejected for arity), which
would be a defect in D-OV4-1, not in the text.

**D-OV4-14 — goldens and programs.** Golden sources: one check file with 16
splits (Appendix A.1), the export check file with 3 splits (A.2), a lower file
with 2 splits (A.3) and the export lower twin (A.4); CHECK lines by autoupdate
only (R16). Programs: `functions/overloading_default_values.carbon` with a
hand-derived EXPECT (B.1) and the DIFF-1 pair
`functions/overloading_default_values_diff.carbon` and `.diff.cpp` (B.2, B.3),
whose calls are the ones where C++'s best viable match agrees with first match;
the both-accept call is not in the pair, because C++ rejects `Pick(5)` against
`Pick(int, int = 2)` and `Pick(int)` as ambiguous, and B.1 pins Carbon's
selection instead. _Break condition:_ a review finds an EXPECT line not
derivable from §1's rule and the prelude, which is then re-derived, never
re-run.

**D-OV4-15 — docs and records (R32).** docs/design/functions_overloading.md
gets dated fork amendments that keep the superseded text visible, in the form
DR-1 used on loops.md and optional.md (Appendix C.1 to C.5): the CLOSED
paragraph at :570-576 and F-009j at :1022-1023 stay, each followed by an
amendment naming upstream's positional default values with the toolchain text
of §0.2 quoted at e6fddcf97; the arity step (:540-545), the 0.1 limits item
(iii) and the D-OV-3 CLOSED paragraph each gain one dated sentence.
fork/overload/plan.md is history: :380 and :2173 get dated notes, not rewrites
(C.6). Records (Appendix D): W-341 DISCHARGED (kind `implemented`, title
prefixed "OV-4 (DISCHARGED at OV-4, <date>)"); W-360, W-361 and W-362 filed;
W-363 and W-364 unused; the decision-log entry "OV-4" with D-OV4-1 to
D-OV4-17, the V-3 check by sha and the register lines; the weekly entry's W-341
paragraph a dated "resolved by OV-4" note; the gap row stays DONE with its
evidence refreshed; ORCHESTRATION's header, a dated paragraph, a Branches row
and its Next actions item 6. The register lines in RG-1's vocabulary: F-009j is
**ALIGNED** (the fork's rule is the toolchain's mechanism, quoted); "members
that accept a call through defaults, first match" is **NONE** (upstream has no
overload sets and no text on defaults with overloading), watched by W-355. Its
three silence checks and F-009j's nine quote rows (Appendix D.6) are added to PR
67's fork/register/rg1-checks.tsv and rg1-quotes.tsv only at land time, after PR
67 lands (commit L-R). Named optional parameters stay where upstream leaves
them, an open question in classes.md, with no fork spelling. _Break condition:_
RG-1's vocabulary or table formats change before land time; L-R then follows the
landed format.

**D-OV4-16 — merge position and the held state.** One PR, base trunk,
merging after PR 66 (ORCHESTRATION item 6), held open like the seventeen
before it while GitHub Actions is disabled. No held PR carries the drift, so
none is amended (R32 (e)): a `git grep` of the seventeen held heads for "no
default arg", "has no default arg", "no Carbon-native default" and
"default-argument design" finds only trunk's own three statements
(functions_overloading.md, fork/overload/plan.md and call.cpp's comment), which
OV-4 amends, and PR 59's call.cpp keeps the exact range. At land time OV-4's
branch merges the trunk that then holds PR 51 to PR 67 (commit M), resolving
handle_function.cpp against PR 59 and PR 66 and merge.cpp against PR 60 by
§6.2's rules, refills what the merged branches change (F-M), adds the register
rows (L-R) and re-quotes the gate and conformance (L). _Break condition:_ the
land sequence changes order so that OV-4 lands before PR 59, PR 60 or PR 66; the
same rules then apply on their side, by their own merge commits.

### §1.1 Residues (W-360 to W-364)

-   **W-360** (missing-feature): generic `overload fn` members with default
    values for non-generic parameters; trunk's deduction ignores a short
    argument list, upstream's 503f09037 appends the defaults; owner UA-3, whose
    audit takes 503f09037 and refills `fail_todo_generic_member_default`
    (renaming it to a passing split). Break condition: D-OV4-7's.
-   **W-361** (missing-feature): default values of exported `overload fn`
    members reach C++ with 9799a2326, 8fdc8ebc3 and c7de72757; owner UA-3; the
    export split's `divergence_omitted` and `fail_cpp_omitted` move, recorded
    under R30 (c) before the goldens. Break condition: D-OV4-10's.
-   **W-362** (toolchain-defect, filed already resolved on the fork): the plain
    call of a function with a diagnosed non-trailing default aborted at
    pattern_match.cpp:1275; fixed by D-OV4-5 in handle_function.cpp's
    `CheckDefaults`, which upstream moved to function.cpp (1b0a5709e). UA-3
    carries the fix into function.cpp, or drops it if upstream fixed the crash
    another way, and reports the crash upstream if the tip still has it. Break
    condition: D-OV4-5's.
-   W-363 and W-364: reserved, unused unless a review files a residue.

## §2 Spec, file by file

Every C++ hunk below is the prototype's, built and measured (§0.5), formatted
by clang-format 21.1.8 and clean under both clang-tidy passes. Line numbers
are trunk 66bd2ba90's on the `-` side and the prototype's on the `+` side.
The diffs are reviewed diffs, written by C1 as given; a review that changes
one changes this section by a dated amendment first. The repository's
trailing-whitespace hook strips the leading space of each blank context line
inside these blocks, so they are for reading; `$Q/proto-toolchain.diff` is the
same diff in a form `git apply` takes.

### §2.1 toolchain/check/call.cpp (C1)

`GetExplicitArityRange` returns the plain call's range (D-OV4-1) and its
comment says so; the probe zips the supplied arguments with the leading
parameter patterns, under the invariant the arity step guarantees (D-OV4-2).
The `CARBON_CHECK(default_value_arity <= expected_args_size)` is
`ResolveCalleeInCall`'s own (:81-82), so the set and the plain call abort on
the same impossible input, never on different ones. `take_front` replaces the
whole-list zip because `llvm::enumerate` over two ranges requires equal
lengths. The commit path is untouched: the hunk's last line is the only change
inside `ProbeOverloadCandidateInScratchScope` besides its comment.

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/call.cpp b/toolchain/check/call.cpp
index 8a7571fe8..7a2c4cce4 100644
--- a/toolchain/check/call.cpp
+++ b/toolchain/check/call.cpp
@@ -419,8 +419,11 @@ struct OverloadProbeResult {

 // Returns the range of explicit argument counts a member accepts, keyed on
 // whether the call binds a receiver, exactly as `ResolveCalleeInCall` computes
-// the expected count. Carbon has no default arguments, so the range is exact;
-// it is a range so that variadic members (W-013) can widen it.
+// it for the ordinary call `PerformCallToFunction` makes: from the parameter
+// count less the member's trailing parameters with default values
+// (`default_value_arity`) up to the parameter count. A call that omits
+// defaulted arguments selects the member as it would call the same function
+// alone; the commit's pattern match supplies the omitted values.
 static auto GetExplicitArityRange(Context& context,
                                   const SemIR::Function& function,
                                   SemIR::InstId self_id)
@@ -429,7 +432,9 @@ static auto GetExplicitArityRange(Context& context,
       context.inst_blocks().GetOrEmpty(function.param_patterns_id);
   size_t expected_args_size =
       param_patterns.size() - (self_id.has_value() ? 1 : 0);
-  return {expected_args_size, expected_args_size};
+  auto default_value_arity = static_cast<size_t>(function.default_value_arity);
+  CARBON_CHECK(default_value_arity <= expected_args_size);
+  return {expected_args_size - default_value_arity, expected_args_size};
 }

 // Returns the leaf parameter pattern of a parameter pattern, looking through
@@ -487,15 +492,23 @@ static auto IntLiteralArgFitsParam(Context& context, SemIR::InstId arg_id,
 }

 // The body of `ProbeOverloadCandidate`, run inside its scratch scope: deduces
-// a generic member's arguments (D-OV-4 step 2(d)), then converts each explicit
+// a generic member's arguments (D-OV-4 step 2(d)), then converts each supplied
 // argument to its parameter type in the resulting specific (step 2(e)).
+// Parameters whose arguments the call omits have default values and are not
+// probed: the commit's `CallerPatternMatch` supplies their defaults.
 static auto ProbeOverloadCandidateInScratchScope(
     Context& context, SemIR::LocId loc_id, const SemIR::Function& function,
     SemIR::SpecificId enclosing_specific_id, SemIR::InstId self_id,
     llvm::ArrayRef<SemIR::InstId> arg_ids) -> OverloadProbeResult {
   auto param_pattern_ids =
       context.inst_blocks().GetOrEmpty(function.param_patterns_id);
-  CARBON_CHECK(param_pattern_ids.size() == arg_ids.size());
+  // The arity step admitted the call, so the arguments are a prefix of the
+  // parameters and every omitted parameter is one of the trailing
+  // `default_value_arity` parameters that have default values.
+  CARBON_CHECK(arg_ids.size() <= param_pattern_ids.size() &&
+               param_pattern_ids.size() - arg_ids.size() <=
+                   static_cast<size_t>(function.default_value_arity));
+  param_pattern_ids = param_pattern_ids.take_front(arg_ids.size());

   OverloadProbeResult result;

```

<!-- google-doc-style-resume -->

### §2.2 toolchain/check/handle_function.cpp (C1)

Three hunks. (1) `TryMergeIntoOverloadSet` (:366) compares with
`CheckOverloadMemberParamsMatch` (D-OV4-4). (2) Gate (iii) reads through a
top-level `DefaultValuePattern` into `binding_pattern_id` and keeps
`param_pattern_id` for the TODO's location (D-OV4-3). (3) `CheckDefaults`'s
count at the level it completes is 0 when that level diagnosed a missing
default (D-OV4-5); `state` is that level (`level_state_stack.back()`), as the
diagnostic block above it already assumes.

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/handle_function.cpp b/toolchain/check/handle_function.cpp
index 91c3fdd4e..250bb3972 100644
--- a/toolchain/check/handle_function.cpp
+++ b/toolchain/check/handle_function.cpp
@@ -363,10 +363,8 @@ static auto TryMergeIntoOverloadSet(
     auto member_function_id =
         context.insts().GetAs<SemIR::FunctionDecl>(member_decl_id).function_id;
     const auto& member_function = context.functions().Get(member_function_id);
-    if (!CheckRedeclParamsMatch(context, new_params,
-                                DeclParams(member_function),
-                                SemIR::SpecificId::None, /*diagnose=*/false,
-                                /*check_syntax=*/false)) {
+    if (!CheckOverloadMemberParamsMatch(context, new_params,
+                                        DeclParams(member_function))) {
       continue;
     }
     // This is a redeclaration of `member_function`. The ordinary path
@@ -858,19 +856,28 @@ static auto DiagnoseOverloadGates(
   // the resolution probe is a value conversion, so `ref` and `var` members
   // would be accepted by the probe and rejected by the commit. This also gates
   // destructuring tuple and struct parameter patterns, whose leaf is not a
-  // single `ValueParamPattern`. The patterns are this declaration's own: a
-  // redeclaration of an imported member merges into a `Function` whose
-  // pattern block holds import refs to the declaring file's patterns, which
-  // say nothing about the parameter kind here.
+  // single `ValueParamPattern`. A default value does not change the kind of
+  // the parameter it wraps: the probe converts only the arguments a call
+  // supplies, and the commit's pattern match fills an omitted one with its
+  // default. The patterns are this declaration's own: a redeclaration of an
+  // imported member merges into a `Function` whose pattern block holds import
+  // refs to the declaring file's patterns, which say nothing about the
+  // parameter kind here.
   for (auto param_pattern_id :
        context.inst_blocks().GetOrEmpty(function_info.param_patterns_id)) {
     if (param_pattern_id == function_info.self_param_id ||
         param_pattern_id == SemIR::ErrorInst::InstId) {
       continue;
     }
+    auto binding_pattern_id = param_pattern_id;
+    if (auto default_value =
+            context.insts().TryGetAs<SemIR::DefaultValuePattern>(
+                param_pattern_id)) {
+      binding_pattern_id = default_value->subpattern_id;
+    }
     bool is_value_param = false;
     if (auto binding = context.insts().TryGetAs<SemIR::WrapperBindingPattern>(
-            param_pattern_id)) {
+            binding_pattern_id)) {
       is_value_param =
           context.insts().Is<SemIR::ValueParamPattern>(binding->subpattern_id);
     }
@@ -1036,8 +1043,12 @@ static auto CheckDefaults(Context& context, SemIR::Function& function)
     }

     // Extract the count from the level we just completed, overwriting any
-    // nested level value extracted previously.
-    default_count = level_state_stack.back().default_count;
+    // nested level value extracted previously. A level with a diagnosed
+    // missing default counts no defaults, so that a caller's arity check
+    // never admits a call that omits an argument for a parameter with no
+    // default value.
+    default_count =
+        state->patterns_missing_defaults.empty() ? state->default_count : 0;
     level_state_stack.pop_back();
   }

```

<!-- google-doc-style-resume -->

### §2.3 toolchain/check/merge.h and merge.cpp (C1)

`CheckOverloadMemberParamsMatch` is declared beside
`CheckRedeclExplicitParamsAfterSelfMatch`, the other D-OV-3 helper, and both
read `GetOverloadMemberParamPatterns`, the explicit patterns with each
top-level default looked through by its constant (the form `CheckRedeclParam`
reads, merge.cpp:255-259), so an imported member's import refs resolve. The
implicit parameters are compared by `CheckRedeclParams` exactly as
`CheckRedeclParamsMatch` compares them (defaults appear only in explicit
lists: handle_pattern_list.cpp:336-342). `CheckRedeclParam` is not changed
(D-OV4-4's reason).

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/merge.h b/toolchain/check/merge.h
index 94761f1d0..12b285436 100644
--- a/toolchain/check/merge.h
+++ b/toolchain/check/merge.h
@@ -118,12 +118,21 @@ auto CheckRedeclParamsMatch(Context& context, const DeclParams& new_entity,
                             SemIR::SpecificId prev_specific_id, bool diagnose,
                             bool check_syntax) -> bool;

+// Returns whether two declarations' parameters match for `overload fn` member
+// identity (D-OV-3): as `CheckRedeclParamsMatch` with `check_syntax` false
+// decides, except that default values on explicit parameters are ignored,
+// since a default value is not part of a parameter's type. Nothing is
+// diagnosed; returns false if either has an erroneous parameter.
+auto CheckOverloadMemberParamsMatch(Context& context,
+                                    const DeclParams& new_entity,
+                                    const DeclParams& prev_entity) -> bool;
+
 // Returns whether the explicit parameters AFTER the leading `self` parameter of
-// two method declarations have matching types (binding names and syntax are
-// ignored, and nothing is diagnosed). Used by `overload fn` member identity to
-// detect members that differ only in their `self` pattern (D-OV-3). Both
-// entities must have a non-empty explicit parameter list; returns false
-// otherwise or if either has an erroneous parameter.
+// two method declarations have matching types (binding names, syntax and
+// default values are ignored, and nothing is diagnosed). Used by `overload fn`
+// member identity to detect members that differ only in their `self` pattern
+// (D-OV-3). Both entities must have a non-empty explicit parameter list;
+// returns false otherwise or if either has an erroneous parameter.
 auto CheckRedeclExplicitParamsAfterSelfMatch(Context& context,
                                              const DeclParams& new_entity,
                                              const DeclParams& prev_entity)
```

<!-- google-doc-style-resume -->

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/merge.cpp b/toolchain/check/merge.cpp
index d7275ea92..ca23915c4 100644
--- a/toolchain/check/merge.cpp
+++ b/toolchain/check/merge.cpp
@@ -573,6 +573,60 @@ static auto CheckRedeclParamSyntax(Context& context,
   return true;
 }

+// Returns the explicit parameter patterns of an `overload fn` member with each
+// top-level default value looked through: `overload fn` member identity is
+// parameter-type equality (D-OV-3), and a default value is not part of a
+// parameter's type. A declaration that differs from a member only in its
+// default values therefore redeclares that member, and the ordinary
+// redeclaration check diagnoses the difference.
+static auto GetOverloadMemberParamPatterns(Context& context,
+                                           SemIR::InstBlockId param_patterns_id)
+    -> llvm::SmallVector<SemIR::InstId> {
+  llvm::SmallVector<SemIR::InstId> pattern_ids;
+  for (auto pattern_id : context.inst_blocks().GetOrEmpty(param_patterns_id)) {
+    auto const_inst_id =
+        context.constant_values().GetConstantInstId(pattern_id);
+    if (auto default_value =
+            context.insts().TryGetAs<SemIR::DefaultValuePattern>(
+                const_inst_id.has_value() ? const_inst_id : pattern_id)) {
+      pattern_id = default_value->subpattern_id;
+    }
+    pattern_ids.push_back(pattern_id);
+  }
+  return pattern_ids;
+}
+
+auto CheckOverloadMemberParamsMatch(Context& context,
+                                    const DeclParams& new_entity,
+                                    const DeclParams& prev_entity) -> bool {
+  if (EntityHasParamError(context, new_entity) ||
+      EntityHasParamError(context, prev_entity)) {
+    return false;
+  }
+  if (!CheckRedeclParams(
+          context, new_entity.loc_id, new_entity.implicit_param_patterns_id,
+          prev_entity.loc_id, prev_entity.implicit_param_patterns_id,
+          /*is_implicit_param=*/true, SemIR::SpecificId::None,
+          /*diagnose=*/false, /*check_syntax=*/false)) {
+    return false;
+  }
+  if (new_entity.param_patterns_id.has_value() !=
+      prev_entity.param_patterns_id.has_value()) {
+    return false;
+  }
+  auto new_param_pattern_ids =
+      GetOverloadMemberParamPatterns(context, new_entity.param_patterns_id);
+  auto prev_param_pattern_ids =
+      GetOverloadMemberParamPatterns(context, prev_entity.param_patterns_id);
+  if (new_param_pattern_ids.size() != prev_param_pattern_ids.size()) {
+    return false;
+  }
+  return CheckRedeclParamLists(
+      context, new_param_pattern_ids, prev_param_pattern_ids,
+      /*is_implicit_param=*/false, SemIR::SpecificId::None,
+      /*diagnose=*/false, /*check_syntax=*/false);
+}
+
 auto CheckRedeclExplicitParamsAfterSelfMatch(Context& context,
                                              const DeclParams& new_entity,
                                              const DeclParams& prev_entity)
@@ -586,18 +640,18 @@ auto CheckRedeclExplicitParamsAfterSelfMatch(Context& context,
     return false;
   }
   auto new_param_pattern_ids =
-      context.inst_blocks().Get(new_entity.param_patterns_id);
+      GetOverloadMemberParamPatterns(context, new_entity.param_patterns_id);
   auto prev_param_pattern_ids =
-      context.inst_blocks().Get(prev_entity.param_patterns_id);
+      GetOverloadMemberParamPatterns(context, prev_entity.param_patterns_id);
   if (new_param_pattern_ids.empty() || prev_param_pattern_ids.empty() ||
       new_param_pattern_ids.size() != prev_param_pattern_ids.size()) {
     return false;
   }
-  return CheckRedeclParamLists(context, new_param_pattern_ids.drop_front(),
-                               prev_param_pattern_ids.drop_front(),
-                               /*is_implicit_param=*/false,
-                               SemIR::SpecificId::None,
-                               /*diagnose=*/false, /*check_syntax=*/false);
+  return CheckRedeclParamLists(
+      context, llvm::ArrayRef(new_param_pattern_ids).drop_front(),
+      llvm::ArrayRef(prev_param_pattern_ids).drop_front(),
+      /*is_implicit_param=*/false, SemIR::SpecificId::None,
+      /*diagnose=*/false, /*check_syntax=*/false);
 }

 auto CheckRedeclParamsMatch(Context& context, const DeclParams& new_entity,
```

<!-- google-doc-style-resume -->

### §2.4 Golden sources (C1) and their fill (F1)

C1 adds the four files of Appendix A with no CHECK lines (each starts from its
`// AUTOUPDATE` header); F1 is the autoupdate output at its fixpoint (two
writing passes and a third that changes nothing, R26, measured), and nothing
else: no existing golden moves (measured,
1942 of 1942 pass on the prototype before the four files are added). File names
and splits:

-   toolchain/check/testdata/function/overload/default_values.carbon:
    `omitted_and_supplied`, `all_defaulted`, `first_member_needs_default`,
    `exact_member_first`, `method_default`, `generic_class_member_default`,
    `template_dependent_default`, `redecl_same_default`,
    `fail_redecl_default_differs`, `fail_too_few`,
    `fail_supplied_argument_rejected`, `fail_default_not_trailing`,
    `fail_todo_non_value_default`, `fail_todo_generic_member_default`,
    `import_lib` and `import_use` (sixteen splits).
-   The export check file
    (toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon):
    `supplied`, `divergence_omitted`, `fail_cpp_omitted`.
-   toolchain/lower/testdata/function/overload/default_values.carbon:
    `omitted_and_supplied`, `class_default`.
-   The export lower twin
    (toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon):
    `divergence_omitted`.

### §2.5 Programs and the README table (P)

Appendix B's three files under fork/conformance/programs/functions/, and the
two rows `runner.py --update-readme-table` adds to fork/conformance/README.md
(measured):

<!-- google-doc-style-ignore -->

```text
| `functions/overloading_default_values.carbon` | Functions: function overloading (Carbon-native) | run |
| `functions/overloading_default_values_diff.carbon` | Functions: function overloading (Carbon-native) | differential |
```

<!-- google-doc-style-resume -->

### §2.6 Docs (P)

docs/design/functions_overloading.md, the five dated amendments of Appendix
C.1 to C.5, and fork/overload/plan.md's two dated notes, Appendix C.6. Each
amendment is inserted, never substituted: the superseded sentences stay, as on
PR 56's loops.md and optional.md and PR 63's loops.md.

### §2.7 Records (R, D, L-R, L)

Appendix D, verbatim but for their `<...>` fields: D.1 the ledger (W-341
discharged, W-360 to W-362), D.2 the decision-log entry "OV-4", D.3 the weekly
entry's note, D.4 the gap row's evidence cell, D.5 ORCHESTRATION, D.6 the
register rows (land time).

## §3 Commits (one PR, "OV-4: `overload fn` members with default parameter values (W-341)", R29 (b))

**D-OV4-17 — the commit sequence.** Every commit is authored `jmann345
<jerrymannstan@gmail.com>` with `GIT_COMMITTER_NAME=Claude
GIT_COMMITTER_EMAIL=noreply@anthropic.com`, adds explicit paths only (R20),
and ends its message, after a blank line, with the session's attribution
trailers. Nothing is pushed until the implementation workflow says so, and the
PR is opened held, base trunk.

1.  **Plan** (this commit): fork/overload/ov4-plan.md, rev 1. Later plan
    revisions are commits on the same file, each a fold record.
2.  **C1, the toolchain change with its golden sources**: §2.1 to §2.3 and
    Appendix A's four files without CHECK lines. Gate on C1 alone: red on
    exactly those four files ("Autoupdate would make changes"), no crash, 1942
    of the other 1942 pass (measured shape: the prototype passes 1942 of 1942
    before the four files exist). Message: "OV-4 (1/4): overload set members
    with default values: the arity range, the probe over the supplied
    arguments, gate (iii), member identity and the default count".
3.  **F1, its fill**: the autoupdate output of the four files at its fixpoint
    (R26); nothing else may change. Message: "OV-4 (2/4): fill C1's goldens
    (autoupdate)".
4.  **P, the programs and docs**: Appendix B's three files, the README table's
    two rows (§2.5), Appendix C's amendments to
    docs/design/functions_overloading.md and the dated notes in
    fork/overload/plan.md. `runner.py --self-test` before the commit: "152
    programs parsed, 56 bullets in table, OK". Message: "OV-4 (3/4): programs,
    the overloading page's amendments for upstream's default values, and the
    OV-1 plan's dated notes".
5.  **R, the row and the orchestration records**: the gap row's evidence cell
    (Appendix D.4), ORCHESTRATION's header, dated paragraph, Branches row and
    item 6 (D.5). Message: "OV-4 (4/4): gap row evidence and ORCHESTRATION".
6.  **Two implementation reviews** (R11: separate agents; R29 (c): two until
    the hosted-equivalent verification is green, then one), against C1 to R.
7.  **Fix commits, at most three**, each with its own fill when it changes
    goldens (the fill is not counted). A records-only commit that changes no
    toolchain, golden or program file is not a fix commit.
8.  **D, the discharge**: the ledger (D.1: W-341 DISCHARGED, W-360 to W-362
    filed), the decision-log entry OV-4 (D.2) and the weekly entry's note
    (D.3), after the reviews and their fixes. Message: "OV-4 discharge: W-341
    DISCHARGED; W-360 to W-362 filed; decision-log entry OV-4".

**The shrink line**, taken in order when the fix budget is spent and a review
still finds a defect that needs a toolchain, golden or program change:

1.  Generic members with defaults are already OUT (D-OV4-7). Step 1 takes the
    next generic form OUT too: a defaulted member of a generic class (the
    `generic_class_member_default` split) becomes a gate, a semantics TODO
    "`overload fn` member with default values in a generic scope" in
    `DiagnoseOverloadGates` keyed on the member's `generic_id` and
    `default_value_arity`, the split renamed `fail_todo_...`, W-360 widened.
2.  The export split: the export check and lower files are dropped from C1 and
    F1, gate (viii)'s per-member export TODO path omits a member whose
    `default_value_arity` is nonzero (as OV-3's partial export omits an
    unmappable member), W-361 widened to cover the omission.
3.  Nothing else shrinks: the arity range, the probe, gate (iii)'s
    look-through, identity and the default count are W-341 itself; a defect
    there stops OV-4 at a plan revision.

_Break condition:_ a commit cannot build without a later commit's files, which
merges the two and is recorded in the landed notes; a defect a review finds in
a commit is fixed at its root in a fix commit, never by a guard (R17).

**The land-time commits**, specified now and made when the land sequence
reaches OV-4, after PR 66 and with PR 67 landed first:

1.  **M**: `git merge --no-ff` of the trunk that then holds PR 51 to PR 67 into
    OV-4's branch, conflicts resolved by §6.2's rules (handle_function.cpp
    against PR 59 and PR 66, merge.cpp against PR 60, the records against
    every PR), with SC-1's two arguments added to the two calls in
    `CheckOverloadMemberParamsMatch` (a semantic change the textual merge
    does not show). Never a rebase (AGENTS.md).
2.  **F-M**: the refills the merged branches cause in OV-4's four goldens, by
    autoupdate to its fixpoint, and nothing else; the m59, m60, m61, m64 and
    m66 mirrors (§8.7) predict it (m66 measured: none).
3.  **L-R**: the register rows of Appendix D.6 appended to PR 67's
    fork/register/rg1-checks.tsv and rg1-quotes.tsv, checked by its
    check_greps.sh and check_quotes.sh at the tip of that day (each count and
    quote re-read; a moved count is a weekly-check finding, not an edit).
4.  **L**: §8.1 to §8.4 re-run on F-M, the gate and conformance figures quoted
    into the ledger, the decision log and ORCHESTRATION (item 6 marked done),
    EXPECTED, not of record, as every land-time record is while Actions is
    disabled.

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

Each row's prediction is hand-traced from §1 before the build; the measured
column is the prototype's fill (`$Q/saved/<path>`, line numbers in the filled
file). Every row matched; nothing was predicted differently and corrected.

_toolchain/check/testdata/function/overload/default_values.carbon:_

| split | predicted | measured |
| --- | --- | --- |
| omitted_and_supplied | member 0 takes `Scale(1)` with the default `10` filled from the declaration's converted default; `Scale(2, 3)` both supplied; no diagnostic | :513 `call %Scale.ref.loc10_33(%.loc10_32.2, @Scale.loc5.%.loc5_41.2)`, :532 `(%.loc10_43.2, %.loc10_46.2)`; the declaration's `default_value_pattern %factor.patt, %int_10.6bf` at :360 |
| all_defaulted | `Count()` fills both, `Count(5)` fills `b`, `Count(5, 6)` none, `Count(true)` member 1 | :620 both `@Count.loc4.%...` values, :631 one, :659 none, :672 `call %Count.ref.loc11_71(%true)` |
| first_member_needs_default | `Pick(5)` member 0 with the default; `Pick(5, 6)` member 0 | :765 `(%.loc11_31.2, @Pick.loc7.%.loc7_49.2)`, :784 two supplied |
| exact_member_first | `Pick(5)` member 0 with one argument; `Pick(5, 6)` member 1 | :879 one argument, :898 two |
| method_default | `c.Plus()` and `Counter.Plus(c)` fill `n`; `c.Plus(5)` and `Counter.Plus(c, 7)` supply it; receivers as D-OV-4 binds them | :995 and :1023 with `@Counter.Plus.loc9.%.loc9_35.2`, :1009 and :1045 supplied |
| generic_class_member_default | `Box(bool).Get()` fills `y` in the specific; `Get(9)` supplies | :1136 `call %Box.Get.specific_fn.loc13_40(@Box.Get.loc8.%.loc8_28.2)`, :1153 |
| template_dependent_default | both specifics check; no diagnostic (the per-specific selection is not in the dumped range) | :1244 and :1249, no STDERR |
| redecl_same_default | one member; `F(1)` fills from the definition's default | :1324 `(%.loc10_28.2, @F.loc7.%.loc7_32.2)` |
| fail_redecl_default_differs | three `RedeclParamDiffers` with `RedeclParamPrevious`, at parameter 2 of the second `F`, `G` and `H` | :149/:152, :159/:162, :169/:172 |
| fail_too_few | `OverloadNoMatch`, two arity notes | :187, :190, :193 |
| fail_supplied_argument_rejected | `OverloadNoMatch`; member 0 conversion note, member 1 arity note | :208, :211, :214 |
| fail_default_not_trailing | two `RequiredPatternDefaultValueMissing` with their first-default notes; `OverloadNoMatch` with an arity note (member 0) and a conversion note (member 1); `CallArgCountMismatch` "1 argument passed to function expecting 2 arguments" with `InCallToEntity`; no crash | :227/:230, :237/:240, :246/:249/:252, :256/:259 |
| fail_todo_non_value_default | two gate (iii) TODOs, at `var y: i32 = 2` and at the defaulted tuple pattern | :272, :277 |
| fail_todo_generic_member_default | `G(true, 5)` selects; `G(true)` `OverloadNoMatch` with the deduction note; `P(true)` `DeductionIncomplete` with `DeductionGenericHere` | :296/:299, :303/:306 |
| import_lib, import_use | `F(1)` fills the imported default as the constant `2`; `F(1, 5)` supplies | :1411 `(%.loc9_28.2, constants.%int_2)`, :1430 |

_toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon:_
`supplied` and `divergence_omitted` check with no diagnostic, Carbon's `F(1)`
filling the default (:178, :284); `fail_cpp_omitted` gets Clang's "no matching
function for call to 'F'" with two "candidate function not viable: requires 2
arguments, but 1 was provided" notes (:75, :78, :81).

_toolchain/lower/testdata/function/overload/default_values.carbon:_ `Scale(1)`
lowers to `call i32 @"_CScale:overload0.Main"(i32 1, i32 10)` (:59) beside
`(i32 2, i32 3)` (:60); the class-typed default is passed as the constant
`@C.val.a26.loc7_35.9` (:144) beside two materialized temporaries (:149).

_toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon:_
Carbon's `F(1)` is `call i32 @"_CF:overload0.Main"(i32 1, i32 2)` (:83); C++'s
`CallOne` calls `@"_CF__carbon_thunk:overload1.Main"` (:162), the `F(bool)`
member's thunk: the divergence R30 asks to assert.

## §5 Conformance delta (from trunk's 128 PASS / 0 FAIL / 22 SKIP over 150, re-measured)

| | PASS | COMPILE-FAIL | others | SKIP | total | bullets PASS/FAIL/SKIP/NOT-WRITTEN |
| --- | --- | --- | --- | --- | --- | --- |
| trunk 66bd2ba90, re-measured (§0.1) | 128 | 0 | 0 | 22 | 150 | 48/0/8/0 |
| the two new programs on trunk | 0 | 2 | 0 | 0 | 2 | the overloading bullet would FAIL |
| prototype (§0.5) | 130 | 0 | 0 | 22 | 152 | 48/0/8/0; the overloading bullet PASS with 9 programs |

Delta: PASS +2, total +2, no status change for any existing program, no bullet
change (the bullet was already PASS). Hand-derived EXPECTs (B.1) and the DIFF-1
oracle (B.3) both match on the prototype.

## §6 Churn and collisions

### §6.1 Golden churn

Four new golden files (A.1 to A.4); no existing golden changes (the prototype
passes trunk's 1942 unchanged, and its mutants show the 1942 do not cover a
defaulted member at all: no existing split declares one, as W-341's evidence
says). F1 is pure addition. At UA-3, d87891f3a's diagnostic style change
re-renders `fail_default_not_trailing`'s two `RequiredPatternDefaultValue*`
messages without their trailing period, and W-360 and W-361 move their splits;
both are UA-3's refills.

### §6.2 Collisions with the held PRs and the merge rules

| PR | collision with OV-4 (§0.6) | merge rule at M |
| --- | --- | --- |
| 51 UA-2 | functions_overloading.md: PR 51 rewrites 0.1 limits item (xi) and adds a paragraph to "Calls from template code"; OV-4 amends item (iii), the arity step and :570-576/:1022 | textual, disjoint hunks; keep both. README rows: regenerate with `--update-readme-table` |
| 59 VA-1, 66 VA-2 | handle_function.cpp, gate (iii)'s loop (textual conflict); `CheckDefaults` (VA-1 adds a `PackExpansionPattern` case; disjoint) | VA-1's pack gate first, on the parameter as declared, then OV-4's look-through (m66's resolution, §8.7); call.cpp and deduce.cpp merge cleanly; a defaulted pack stays gated by VA-1 (W-215, W-223) |
| 60 SC-1 | merge.cpp `CheckRedeclExplicitParamsAfterSelfMatch` (textual); SC-1's two new parameters of `CheckRedeclParams` and `CheckRedeclParamLists` (semantic) | take SC-1's argument list in the conflict and add `/*new_specific_id=*/SemIR::SpecificId::None, /*found_error=*/nullptr` to OV-4's two calls in `CheckOverloadMemberParamsMatch`; OV-4's identity keeps SC-1's errors-match mode off (`found_error` null), as SC-1's own call there does |
| 61 TP-1, 64 CT-1 | call.cpp, clean | none; m61 and m64 confirm the template split and p16 |
| 65 DR-1b | call.cpp return storage, clean | none |
| 52 to 58, 62, 63, 67 | records only (README rows, ORCHESTRATION, decision log, ledger) | records by each PR's land-time rule; README regenerated |

Every held PR's records files (fork/ORCHESTRATION.md, fork/decision-log.md,
fork/inventory/work-items.json, fork/gap-analysis.md, the conformance README)
conflict with OV-4's R and D commits as they do with each other; M resolves
them by keeping both sides' entries in id and date order, as RG-1's and VA-2's
merges did.

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1: the probe accepts and the commit rejects** (D-OV-4's R-1 class).
    Falsifier: a call within a member's range whose supplied arguments convert
    in the probe but whose commit diagnoses. The commit's only extra work for
    a defaulted member is the fill of constants already converted at the
    declaration (D-OV4-2), so no such call exists unless a default's type
    differs per specific; the generic-class split and p09 exercise that case
    and pass.
-   **R-2: identity changes an existing set.** Falsifier: a trunk golden or
    program whose members differed only in a default before OV-4. None can
    exist: every such member was gated by (iii) (measured, no existing
    golden changes).
-   **R-3: the default count change alters a plain call that worked.**
    Falsifier: a declaration with a diagnosed missing default whose call used
    to pass. Such a call either supplied every argument (still passes) or
    omitted one and crashed (now `CallArgCountMismatch`); the declaration is
    an error either way.
-   **R-4: PR 66's deduction changes D-OV4-7.** Falsifier: m66's p07 or p20
    selecting a generic member with a default omitted. Measured on m66
    (§8.7).

### §7.2 Rejected alternatives

-   **A second probe path for defaulted members** (probe the defaults too, or
    a separate loop for short calls). Rejected: the defaults are constants
    converted at the declaration, the commit already fills them, and a second
    path is the divergence D-OV-4's single loop exists to prevent (R17).
    Falsifier: a default whose conversion can fail at a call, which upstream
    does not allow (D-OV4-12).
-   **Ranking by fewest defaults used** (prefer the exact member). Rejected:
    D-OV-4 has no ranking, upstream anticipates declaration order
    (pattern_matching.md:696-697), and a ranking only for defaults would be a
    fork mechanism upstream has not designed (R32 (d)). Falsifier: an
    accepted upstream overloading design with ranking.
-   **Rejecting sets whose members overlap through defaults** (a declaration
    error when one member's range covers another's types). Rejected: overlap
    is already legal without defaults (`Pick(i64)` before `Pick(i32)`,
    basic.carbon `first_match_order`); declaration order is the API
    (functions_overloading.md, "Declaration order is API"). Falsifier: the
    same.
-   **Deferring everything to UA-3.** Rejected: W-341 is a drift scheduled
    before UA-3 (ORCHESTRATION item 6), the non-generic case needs no upstream
    commit (trunk has the mechanism since UA-1), and only the generic and
    export cases wait for upstream code (W-360, W-361). Falsifier: a
    non-generic defaulted member that cannot work on trunk's code.
-   **Cherry-picking 503f09037 now.** Rejected: its export.cpp half needs
    9799a2326; its deduce.cpp half lands in the function PR 66 rewrites
    (+127 lines), a collision UA-3 resolves once with upstream's whole
    series. Falsifier: UA-3 dropped from the schedule.
-   **A TODO gate on defaulted members** (keep them out of sets). Rejected:
    it hides an IN form the plain path already supports (R17), and it is the
    F-009j drift itself.
-   **Changing `CheckRedeclParam` for `check_syntax` false.** Rejected:
    thunk.cpp's impl-against-interface comparison uses the same mode for
    upstream's meaning (D-OV4-4).
-   **Leaving the non-trailing-default crash to upstream.** Rejected: OV-4
    opens the set path to it (mutant M5), and the root is a two-line count
    (R17); W-362 carries it to UA-3.

## §8 Verification and discharge

Every agent works under /dev/shm/ov4-<role>/ (builds, mirrors) and
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ov4/<role>/
(probes, logs, `XDG_CACHE_HOME`), checks `pgrep -fa 'ninja|file_test'` before a
full build, keeps at most one install, and deletes its builds when done. No
Bazel, no Actions, no runner (R28).

### §8.0 The planner's measurements (done)

§0.1's baseline, §0.3's probes on five toolchains and the nightly, §0.5's
prototype, its five mutants and the 503f09037 scratch, §0.6's numstat and
merge-trees, and the mirror m66 below. The planner's build and mirror were
deleted after this plan's commit; the prototype's files are kept at
`$Q/saved` and `$Q/proto-toolchain.diff`.

### §8.1 Build (implementer)

<!-- google-doc-style-ignore -->

```sh
export CB_BUILD_ROOT=/dev/shm/ov4-impl/builds
CB=/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild
$CB/build.sh /home/user/carbon-ov4 && $CB/install.sh /home/user/carbon-ov4
```

<!-- google-doc-style-resume -->

on C1 (expected: 7 to 17 minutes cold, the incremental rebuild of C1's four
files about 20 seconds; no warning under `-Werror`), then on every fix commit.

### §8.2 Autoupdate to its fixpoint

`$CB/autoupdate.sh /home/user/carbon-ov4 <the four files>` until a pass prints
four dots (measured: the third pass, after two writing passes, R26), then `git
diff --stat` shows only the four files. A pass that changes another file is a
finding.

### §8.3 Gate

`$CB/gate.sh /home/user/carbon-ov4`: expected 1946 passed, 0 failed on F1;
1942 passed and exactly the four new files failed on C1 alone.

### §8.4 Conformance

`XDG_CACHE_HOME=<private> $CB/conformance.sh /home/user/carbon-ov4 <out>`:
expected PASS 130, SKIP 22, nothing else, of 152; bullets 48 PASS, 0 FAIL, 8
SKIP, 0 NOT-WRITTEN of 56; `python3 -I fork/conformance/runner.py --self-test`
"152 programs parsed, 56 bullets in table, OK".

### §8.5 Mutants

M1 to M5 of §0.5, each rebuilt incrementally and run on the four goldens and
the probes, each expected to fail as §0.5 measured; plus M6 for the programs:
`Pick`'s and `Order`'s members each swapped in B.1, expected OUTPUT-MISMATCH
with lines 3 and 5 printing 2 and 1 (measured by the planner on the prototype:
`30 12 2 1 1 1 101 105 101 200 12 72 -1`), so B.1 is not vacuous about first
match. The implementer restores the tree after each
and checks `git diff` is C1's.

### §8.6 prek, clang-tidy and R31 (every commit)

`SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
uvx prek run --files <the commit's paths>` to a fixpoint with a private
`XDG_CACHE_HOME` deleted afterwards; for each `.md`, `python3 -I
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer5/bin/r31.py
<file>` before and after, the counts unchanged, and the diff grepped for a new
line matching `^\+\s*#{1,6} [0-9]|^\+#[0-9]`. clang-format 21.1.8 with
`--assume-filename`; clang-tidy 21.1.8 in VA-2's two passes over every changed
`.cpp` (`$Q/bin/tidy.sh <mode> <tree> <base> <file>`, where `<mode>` is `norec`
for the first pass and anything else for the second, the build's flags read from
build.ninja), every diagnostic fixed in the next fix commit, none suppressed.
The planner's run of both passes on the prototype printed nothing.

### §8.7 Composition mirrors (implementer, before the implementation reviews)

Each mirror is `git worktree add --detach /dev/shm/ov4-<role>/mirror-<n>` of
the held head, then `git merge --no-ff --no-commit` of OV-4's head, the
conflicts resolved by §6.2's rules and the records taken from the held head,
then build, install, gate, conformance and the probes of §0.3, then `git
worktree remove` and the build deleted. Expected red set before the mirror's
own fill: none beyond the held head's own; each mirror's probe output equal to
the prototype's on all 38 probes.

-   **m66, PR 66 plus OV-4 (measured by the planner on the prototype):** the
    one textual conflict in handle_function.cpp resolved by §6.2's rule (VA-1's
    pack gate, then the look-through), the three records conflicts taken from
    PR 66, the README regenerated. Build clean (7 minutes); gate 1981 passed, 0
    failed (PR 66's goldens and OV-4's four, none refilled); conformance PASS
    149, SKIP 21, nothing else, of 170, bullets 49 PASS, 0 FAIL, 7 SKIP (PR
    66's install on the same 170 programs: PASS 147, COMPILE-FAIL 2, the two
    new programs, SKIP 21); the 38 probes print exactly the prototype's lines
    (`diff` of the two outputs empty), so PR 66's deduction leaves D-OV4-7's
    OUT unchanged (p07, p20). PR 59 is PR 66's base, so m66 covers it; m59 is
    run only if PR 66 is not landed with PR 59.
-   **m60, PR 60 plus OV-4:** the merge.cpp conflict and the two added
    arguments (§6.2); expected: SC-1's goldens and OV-4's four pass,
    `fail_redecl_default_differs` unchanged (SC-1's errors-match mode stays
    off on OV-4's path).
-   **m61, PR 61 plus OV-4:** clean merge; expected:
    `template_dependent_default` unchanged, p16 exits 1.
-   **m64, PR 64 plus OV-4:** clean merge (PR 64 contains PR 61); expected as
    m61, and the export split unchanged.
-   **mall, the land-sequence tree:** trunk with PR 67 and PR 53 to PR 66
    merged in §6.2's order, then OV-4: the rehearsal of M and F-M, once the
    held PRs' own land rehearsals exist.

### §8.8 Re-verification on the merge commit (land time)

After M: §8.1 to §8.5 on the merge commit; F-M commits the refills; the
totals become the landed trunk's floor plus §5's delta, and L quotes that run,
EXPECTED, not of record.

### §8.9 Not run, and why

-   The hosted gate, autoupdate and conformance: GitHub Actions is disabled and
    the owner's runner is never used (R28); every figure here is
    container-local.
-   Upstream's tip toolchain was not built: that p21's crash exists at
    e6fddcf97 is inferred from its unchanged `CheckDefaults`,
    `ResolveCalleeInCall` and pattern_match.cpp, not measured.
-   Upstream issue 7529 (named by `CheckDefaults`' TODO) could not be read:
    this session's GitHub API access does not cover carbon-language/carbon-lang
    (HTTP 403); the TODO's own text is quoted instead.
-   Bazel-only tests (gtest unit tests, lit, fuzzers): no Bazel here; OV-4
    changes no unit-tested API.
-   The m60, m61, m64 and mall mirrors: specified for the implementer; only
    m66 was built by the planner.
-   macOS, Windows, ASan and opt builds: the container builds Linux fastbuild
    only.

### §8.10 Id re-scan (before commit D)

The command of §0.9, after a fetch: W-360 to W-364 must still be free on every
ref and worktree but for OV-4's own uses; a hit elsewhere renumbers OV-4's
residues upward within W-360 to W-364, or, if those are taken, to the next
free ids after a new re-scan, recorded in D's message.

## Hand-off notes for the implementer

1.  Start from a clean worktree at this plan's commit: the planner restored
    every file it prototyped. `$Q/saved` holds the prototype's files and
    `$Q/proto-toolchain.diff` its toolchain diff, identical to §2's blocks.
2.  C1's goldens go in without CHECK lines; never write a CHECK line by hand
    (R16). Appendix A's sources are complete; F1 is autoupdate's.
3.  Write the probes of §0.3 into your own scratch (`$Q/probes` is the
    planner's; read, do not write there) and keep `$Q/bin/probe.sh`'s shape:
    compile each unit with `--output-last-input-only`, link, run.
4.  B.1's EXPECT lines are derived in its header; re-derive them from §1 and
    the prelude before running anything (R16 (d)). B.2 has no EXPECT-STDOUT
    (DIFF-1).
5.  The docs amendments of Appendix C are inserted, not substituted; the
    superseded sentences stay, and `<date>` is the commit's `date -u +%F`.
6.  At M, SC-1's signature change compiles only with the two added arguments
    (§6.2); a clean textual merge of merge.cpp is not a clean build.
7.  If a review finds a defect in a generic or exported defaulted member,
    take the shrink line in order (§3), never a guard.
8.  W-360 to W-362 are filed at D, not before; their `<sha>` fields are C1's.

## Appendix A. Golden sources (C1; CHECK lines by autoupdate only)

Each file is written exactly as below; autoupdate adds the CHECK lines.

### §A.1 toolchain/check/testdata/function/overload/default_values.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/default_values.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/default_values.carbon

// `overload fn` members with default parameter values (fork/overload/ov4-plan.md
// OV-4, W-341). A member accepts a call that supplies from its parameter count
// less its trailing defaulted parameters up to its parameter count, exactly as
// the ordinary call of the same function does (`default_value_arity`); the
// resolution probe converts only the supplied arguments, and the committed
// ordinary call fills each omitted parameter with its default value. Between
// two members that both accept a call, the first in declaration order is
// selected (D-OV-4): a default is not a ranking criterion.

// --- omitted_and_supplied.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
overload fn Scale(x: i32, factor: i32 = 10) -> i32 { return x * factor; }
overload fn Scale(unused b: bool) -> i32 { return 0; }

// `Scale(1)` omits `factor`: member 0 accepts one or two arguments, and the
// committed call passes the default `10`. `Scale(2, 3)` supplies it.
fn Use() -> i32 { return Scale(1) + Scale(2, 3); }
//@dump-sem-ir-end

// --- all_defaulted.carbon

library "[[@TEST_NAME]]";

overload fn Count(a: i32 = 1, b: i32 = 2) -> i32 { return a + b; }
overload fn Count(unused flag: bool) -> i32 { return 0; }

// Member 0 accepts zero, one or two arguments; `Count(true)` is rejected by
// member 0's conversion probe of its one supplied argument and selects
// member 1.
//@dump-sem-ir-begin
fn Use() -> i32 { return Count() + Count(5) + Count(5, 6) + Count(true); }
//@dump-sem-ir-end

// --- first_member_needs_default.carbon

library "[[@TEST_NAME]]";

// Both members accept `Pick(5)`: member 0 through its default, member 1
// exactly. Declaration order decides (D-OV-4), so member 0 is selected; there
// is no ranking by exactness or by the number of defaults used.
overload fn Pick(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

//@dump-sem-ir-begin
fn Use() -> i32 { return Pick(5) + Pick(5, 6); }
//@dump-sem-ir-end

// --- exact_member_first.carbon

library "[[@TEST_NAME]]";

// The reverse order: member 0 matches `Pick(5)` exactly and is selected;
// member 1 is reached only by the two-argument call.
overload fn Pick(unused x: i32) -> i32 { return 2; }
overload fn Pick(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }

//@dump-sem-ir-begin
fn Use() -> i32 { return Pick(5) + Pick(5, 6); }
//@dump-sem-ir-end

// --- method_default.carbon

library "[[@TEST_NAME]]";

// The arity range is keyed on the call's receiver: through the object the
// explicit arguments after `self` count, and through the class scope the
// receiver is argument 0 (`Counter.Plus(c)`), matched against `self`.
class Counter {
  var start: i32;
  overload fn Plus(self, n: i32 = 1) -> i32 { return self.start + n; }
  overload fn Plus(unused self, unused b: bool) -> i32 { return 0; }
}

//@dump-sem-ir-begin
fn Use(c: Counter) -> i32 {
  return c.Plus() + c.Plus(5) + Counter.Plus(c) + Counter.Plus(c, 7);
}
//@dump-sem-ir-end

// --- generic_class_member_default.carbon

library "[[@TEST_NAME]]";

// A set in a generic class: the members are non-generic within the specific
// (the enclosing specific supplies the class's bindings), so the defaulted
// member is selected and filled as in a non-generic scope.
class Box(T: type) {
  overload fn Get(y: i32 = 2) -> i32 { return y; }
  overload fn Get(unused b: bool) -> i32 { return -1; }
}

//@dump-sem-ir-begin
fn Use() -> i32 { return Box(bool).Get() + Box(bool).Get(9); }
//@dump-sem-ir-end

// --- template_dependent_default.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// The call is deferred at the definition and resolved for each specific; at
// instantiation the arity rule admits the one-argument call for member 0.
fn T(template U: type, u: U) -> i32 { return F(u); }

//@dump-sem-ir-begin
fn Use() -> i32 { return T(i32, 1) + T(bool, true); }
//@dump-sem-ir-end

// --- redecl_same_default.carbon

library "[[@TEST_NAME]]";

// A forward declaration and a definition with the same default are one member.
overload fn F(x: i32, y: i32 = 2) -> i32;
overload fn F(unused b: bool) -> i32 { return -1; }
overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }

//@dump-sem-ir-begin
fn Use() -> i32 { return F(1); }
//@dump-sem-ir-end

// --- fail_redecl_default_differs.carbon

library "[[@TEST_NAME]]";

// Member identity is parameter-type equality (D-OV-3) and a default value is
// not part of a parameter's type: each second declaration redeclares the
// type-equal member, and the ordinary redeclaration check diagnoses the
// differing default, rather than forming a member no call could reach.
overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn F(unused x: i32, unused y: i32) -> i32 { return 2; }

overload fn G(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn G(unused x: i32, unused y: i32 = 3) -> i32 { return 2; }

overload fn H(x: i32, y: i32 = 2) -> i32;
overload fn H(x: i32, y: i32) -> i32 { return x + y; }

// --- fail_too_few.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// Below member 0's minimum of one argument: every member is rejected by the
// arity step.
fn Use() -> i32 { return F(); }

// --- fail_supplied_argument_rejected.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn F(unused b: bool, unused c: bool) -> i32 { return 2; }

// Member 0 admits one argument but its supplied argument does not convert;
// member 1 needs two.
fn Use() -> i32 { return F(true); }

// --- fail_default_not_trailing.carbon

library "[[@TEST_NAME]]";

// A declaration whose default is not trailing is diagnosed and counts no
// defaults, so a call that omits the last argument is an arity mismatch, for
// a set member and for a plain function alike.
overload fn F(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

fn P(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }

fn Use() -> i32 { return F(5) + P(5); }

// --- fail_todo_non_value_default.carbon

library "[[@TEST_NAME]]";

// D-OV-6 gate (iii) looks through a default value to the parameter it wraps:
// a defaulted `var` parameter or a defaulted tuple pattern is still a
// non-value explicit parameter.
overload fn F(unused x: i32, var y: i32 = 2) -> i32 { return y; }
overload fn G(x: i32, (a: i32, b: i32) = (3, 4)) -> i32 { return x + a + b; }

// --- fail_todo_generic_member_default.carbon

library "[[@TEST_NAME]]";

// TODO(UA-3, W-360): a generic member's defaulted non-generic parameter is
// supplied to deduction by upstream 503f09037, which this trunk predates.
// Until then deduction against a short argument list deduces nothing, so the
// set rejects the member with the deduction reason exactly where the plain
// call of the same generic function fails to deduce.
overload fn G[T: type](unused x: T, y: i32 = 2) -> i32 { return y; }

fn P[T: type](unused x: T, y: i32 = 2) -> i32 { return y; }

fn Use() -> i32 { return G(true, 5) + G(true) + P(true); }

// --- import_lib.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

// --- import_use.carbon

library "[[@TEST_NAME]]";

import library "import_lib";

// The imported member carries its `default_value_arity` and its default value
// pattern, so the set accepts the omitted argument through an import.
//@dump-sem-ir-begin
fn Use() -> i32 { return F(1) + F(1, 5); }
//@dump-sem-ir-end
```

<!-- google-doc-style-resume -->

### §A.2 toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon

// An exported `overload fn` set with a defaulted member (fork/overload/ov4-plan.md
// OV-4, D-OV4-8). Each member is its own C++ declaration (OV-3), and this
// trunk exports no default argument for a Carbon default value: upstream
// exports them from 9799a2326 on, which arrives with UA-3. So a C++ caller
// supplies every argument of a defaulted member, and C++ resolves a call that
// omits one among the other members under C++ rules, where Carbon's call with
// the same arguments selects the defaulted member (rulebook R30: both sides
// asserted; the lower twin pins the C++ side's callee).

// --- supplied.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

inline Cpp '''
inline int CallTwo() { return Carbon::F(1, 5); }
''';

//@dump-sem-ir-begin
fn Use() -> i32 { return F(1) + Cpp.CallTwo(); }
//@dump-sem-ir-end

// --- divergence_omitted.carbon

library "[[@TEST_NAME]]";

import Cpp;

// Carbon's `F(1)` selects member 0 and fills `y` with 2. C++'s
// `Carbon::F(1)` sees `F(int, int)` with no default argument, which is not
// viable for one argument, and selects `F(bool)` through the integral to
// boolean conversion.
overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

inline Cpp '''
inline int CallOne() { return Carbon::F(1); }
''';

//@dump-sem-ir-begin
fn Use() -> i32 { return F(1) + Cpp.CallOne(); }
//@dump-sem-ir-end

// --- fail_cpp_omitted.carbon

library "[[@TEST_NAME]]";

import Cpp;

// No other member is viable for one argument in C++, so Clang rejects the
// call that Carbon accepts.
overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool, unused c: bool) -> i32 { return -1; }

fn Use() -> i32 { return F(1); }

inline Cpp '''
inline int CallOne() { return Carbon::F(1); }
''';
```

<!-- google-doc-style-resume -->

### §A.3 toolchain/lower/testdata/function/overload/default_values.carbon

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/function/overload/default_values.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/function/overload/default_values.carbon

// The committed call to a defaulted `overload fn` member passes the default
// value for the omitted argument (fork/overload/ov4-plan.md OV-4): the lowered
// call to member 0 receives the constant `10`, and a class-typed default is
// initialized in the caller as the ordinary call initializes it.

// --- omitted_and_supplied.carbon

library "[[@TEST_NAME]]";

overload fn Scale(x: i32, factor: i32 = 10) -> i32 { return x * factor; }
overload fn Scale(unused b: bool) -> i32 { return 0; }

fn Use() -> i32 { return Scale(1) + Scale(2, 3); }

// --- class_default.carbon

library "[[@TEST_NAME]]";

class C { var v: i32; }
fn MakeC() -> C { return {.v = 7}; }

overload fn F(c: C, d: C = {.v = 3}) -> i32 { return c.v * 10 + d.v; }
overload fn F(unused b: bool) -> i32 { return -1; }

fn Use() -> i32 { return F(MakeC()) + F(MakeC(), MakeC()); }
```

<!-- google-doc-style-resume -->

### §A.4 toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon

// The C++ side of an exported set with a defaulted member
// (fork/overload/ov4-plan.md D-OV4-8): Carbon's `F(1)` calls member 0
// (`_CF:overload<0>.Main`) with the default `2`, and C++'s `Carbon::F(1)`
// calls member 1 through its thunk, because this trunk exports no default
// argument (upstream 9799a2326 arrives with UA-3).

// --- divergence_omitted.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

inline Cpp '''
inline int CallOne() { return Carbon::F(1); }
''';

fn Use() -> i32 { return F(1) + Cpp.CallOne(); }
```

<!-- google-doc-style-resume -->

## Appendix B. Conformance programs and the C++ oracle (P)

### §B.1 fork/conformance/programs/functions/overloading_default_values.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   30
//   12
//   1
//   1
//   2
//   1
//   101
//   105
//   101
//   200
//   12
//   72
//   -1
//
// `overload fn` members with default parameter values (fork/overload/ov4-plan.md
// OV-4, W-341): a member accepts a call that omits trailing defaulted
// arguments exactly as the ordinary call of the same function does, and a call
// two members accept selects the FIRST in declaration order (D-OV-4).
//
// EXPECT values, hand-derived from the first-match rule, upstream's positional
// default values (the omitted argument takes the parameter's default) and the
// prelude's implicit conversions (no `bool` to `i32` conversion); `Seed(x)` is
// `x + 20`:
//   30   `Scale(Seed(-17))`: 3 with `factor` defaulted to 10.
//   12   `Scale(Seed(-17), Seed(-16))`: 3 * 4.
//   1    `Pick(Seed(-15))`: both members accept one argument; member 0 (which
//        needs its default) is first, so a resolver ranking exact matches
//        first would print 2.
//   1    `Pick(Seed(-15), 6)`: only member 0 takes two.
//   2    `Order(Seed(-15))`: the exact member is first in `Order`.
//   1    `Order(Seed(-15), 6)`: only member 1 takes two.
//   101  `c.Plus()`: `start` 100 plus the default 1.
//   105  `c.Plus(5)`.
//   101  `Counter.Plus(c)`: the receiver is argument 0, `n` defaulted.
//   200  `c.Plus(true)`: member 0 rejects `bool`; member 1 doubles `start`.
//   12   `Count()`: both defaults, 1 * 10 + 2.
//   72   `Count(Seed(-13))`: 7 * 10 + 2.
//   -1   `Count(true)`: member 0 rejects `bool`; member 1.

import Core library "io";

overload fn Scale(x: i32, factor: i32 = 10) -> i32 { return x * factor; }
overload fn Scale(unused b: bool) -> i32 { return 0; }

overload fn Pick(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

overload fn Order(unused x: i32) -> i32 { return 2; }
overload fn Order(unused x: i32, unused y: i32 = 2) -> i32 { return 1; }

class Counter {
  var start: i32;
  overload fn Plus(self, n: i32 = 1) -> i32 { return self.start + n; }
  overload fn Plus(self, b: bool) -> i32 {
    if (b) { return self.start * 2; }
    return 0;
  }
}

overload fn Count(a: i32 = 1, b: i32 = 2) -> i32 { return a * 10 + b; }
overload fn Count(unused flag: bool) -> i32 { return -1; }

fn Seed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(Scale(Seed(-17)));
  Core.Print(Scale(Seed(-17), Seed(-16)));
  Core.Print(Pick(Seed(-15)));
  Core.Print(Pick(Seed(-15), 6));
  Core.Print(Order(Seed(-15)));
  Core.Print(Order(Seed(-15), 6));
  let c: Counter = {.start = Seed(80)};
  Core.Print(c.Plus());
  Core.Print(c.Plus(5));
  Core.Print(Counter.Plus(c));
  Core.Print(c.Plus(true));
  Core.Print(Count());
  Core.Print(Count(Seed(-13)));
  Core.Print(Count(true));
  return 0;
}
```

<!-- google-doc-style-resume -->

### §B.2 fork/conformance/programs/functions/overloading_default_values_diff.carbon

<!-- google-doc-style-ignore -->

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Functions: function overloading (Carbon-native)
// EXPECT-EXIT: 0
//
// Differential pair (DIFF-1): overloading_default_values_diff.diff.cpp is the
// equivalent C++17 program with default arguments and overloads; the runner
// requires byte-identical exit code and stdout, so C++ is the oracle for the
// values. The calls are the ones where Carbon's first match
// (fork/overload/ov4-plan.md OV-4, D-OV-4) and C++'s best viable match select
// the same function: the defaulted member is the only viable one for an
// omitted argument, and `bool` arguments have an exact C++ match where Carbon
// has no `bool` to `i32` conversion. A call two members accept is not here:
// C++ rejects it as ambiguous (overloading_default_values.carbon pins
// Carbon's selection). The set is not exported, so rulebook R30 does not
// apply.

import Core library "io";

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(b: bool) -> i32 {
  if (b) { return -1; }
  return -2;
}

class Counter {
  var start: i32;
  overload fn Plus(self, n: i32 = 1) -> i32 { return self.start + n; }
  overload fn Plus(self, b: bool) -> i32 {
    if (b) { return self.start * 2; }
    return 0;
  }
}

fn Seed(x: i32) -> i32 { return x + 20; }

fn Run() -> i32 {
  Core.Print(F(Seed(-19)));
  Core.Print(F(Seed(-19), Seed(-15)));
  Core.Print(F(true));
  Core.Print(F(false));
  let c: Counter = {.start = Seed(80)};
  Core.Print(c.Plus());
  Core.Print(c.Plus(Seed(-13)));
  Core.Print(c.Plus(true));
  return 0;
}
```

<!-- google-doc-style-resume -->

### §B.3 fork/conformance/programs/functions/overloading_default_values_diff.diff.cpp

<!-- google-doc-style-ignore -->

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// Differential C++17 equivalent of overloading_default_values_diff.carbon:
// overloads with a default argument, selected by C++'s best viable match.
// printf("%d\n", ...) mirrors Core.Print's lowering exactly
// (toolchain/lower/handle_call.cpp).

#include <cstdio>

auto F(int x, int y = 2) -> int { return x * 10 + y; }
auto F(bool b) -> int {
  if (b) {
    return -1;
  }
  return -2;
}

struct Counter {
  int start;
  auto Plus(int n = 1) const -> int { return start + n; }
  auto Plus(bool b) const -> int {
    if (b) {
      return start * 2;
    }
    return 0;
  }
};

auto Seed(int x) -> int { return x + 20; }

auto main() -> int {
  std::printf("%d\n", F(Seed(-19)));
  std::printf("%d\n", F(Seed(-19), Seed(-15)));
  std::printf("%d\n", F(true));
  std::printf("%d\n", F(false));
  const Counter c = {Seed(80)};
  std::printf("%d\n", c.Plus());
  std::printf("%d\n", c.Plus(Seed(-13)));
  std::printf("%d\n", c.Plus(true));
  return 0;
}
```

<!-- google-doc-style-resume -->

## Appendix C. Docs amendments, verbatim (P)

`<date>` is P's `date -u +%F`. Each block is inserted at the anchor named, the
anchor's own text unchanged, so the page keeps its history.

### §C.1 docs/design/functions_overloading.md, after the CLOSED paragraph that ends "Revisit as its own design fork if a need appears." (:570-576)

<!-- google-doc-style-ignore -->

```markdown
> **Fork amendment (<date>, OV-4, W-341; supersedes the CLOSED paragraph
> above).** Carbon parameters take positional default values as upstream's
> toolchain implements them: a parameter written `y: i32 = 2` may be omitted at
> a call, every parameter after a defaulted one must also have a default, the
> default must be a constant, and the call supplies the default for each
> omitted argument. Upstream's toolchain/check/call.cpp:46-52 at e6fddcf97
> checks "that the number of arguments is within the range [callee_arity -
> arity_lower_bound_margin, callee_arity]. This allows arity matching when the
> callee has default arguments for some subpatterns." Upstream's design pages
> at that tip do not describe the mechanism, and its only text on optional
> parameters, "Optional named parameters" in [classes](classes.md), is an open
> question about named ones; this page follows the toolchain and adds no
> spelling of its own. A member with default values matches as the ordinary
> call of the same function would: the arity step accepts from the member's
> parameter count less its trailing defaulted parameters up to its parameter
> count, the match test converts only the arguments the call supplies, and the
> selected member's ordinary call supplies the omitted defaults. When defaults
> make two members accept one call, the first in declaration order is
> selected, as for any two members that accept it; using a default is not a
> worse match. Until the fork takes upstream's later commits, a generic member
> called with a defaulted argument omitted fails deduction as the ordinary
> call of a generic function does (503f09037, W-360), and an exported member's
> C++ declaration carries no default argument (9799a2326, W-361).
```

<!-- google-doc-style-resume -->

### §C.2 the same page, the F-009j entry under "Sub-forks" (:1022-1023), appended to the item

<!-- google-doc-style-ignore -->

```markdown
-   **F-009j — Default arguments**: none in 0.1; the arity step is exact.
    CLOSED by D-OV-4 step 2(b). _Superseded (fork amendment <date>, OV-4,
    W-341):_ members take upstream's positional default values; the arity
    step accepts a range, the match test converts the supplied arguments only,
    and first match decides between members that both accept (see the
    amendment under [The candidate match test](#the-candidate-match-test)).
```

<!-- google-doc-style-resume -->

### §C.3 the same page, the arity step's parenthesis (:543-545), appended inside item 1 after "In the toolchain: `GetExplicitArityRange`.)"

<!-- google-doc-style-ignore -->

```markdown
    _Fork amendment <date>, OV-4:_ the range runs from the candidate's
    parameter count less its trailing defaulted parameters to its parameter
    count, the range the ordinary call checks (see the amendment below).
```

<!-- google-doc-style-resume -->

### §C.4 the same page, "0.1 limits" item (iii) (:364-366), appended to the item

<!-- google-doc-style-ignore -->

```markdown
    (amended <date>, OV-4: a default value does not change the parameter it
    wraps, so `y: i32 = 2` is a by-value binding and is accepted; a defaulted
    `var` parameter or tuple pattern is still gated);
```

<!-- google-doc-style-resume -->

The item's own closing `;` moves after the parenthesis: the item reads "...
destructuring tuple or struct parameter patterns) (amended <date>, ...: ...
still gated);".

### §C.5 the same page, the D-OV-3 CLOSED paragraph that ends "the first type-equal member is the one being redeclared." (:438-448), appended to the paragraph

<!-- google-doc-style-ignore -->

```markdown
_Fork amendment <date>, OV-4:_ a default value is part of a declaration's
tokens, not of a parameter's type, so `overload fn F(x: i32, y: i32 = 2)`
followed by `overload fn F(x: i32, y: i32)` or by `overload fn F(x: i32, y:
i32 = 3)` redeclares the first member and is diagnosed `RedeclParamDiffers`,
as two plain declarations are.
```

<!-- google-doc-style-resume -->

### §C.6 fork/overload/plan.md, dated notes (the plan is history)

At :380-382, after "(stranded sub-fork F-009j's recommendation, :450-457,
adopted; amended 2026-09-27, review fold: rev B B2)." and before "Mismatch",
insert, keeping the item's eight-space indentation:

<!-- google-doc-style-ignore -->

```markdown
        [Note <date>, OV-4: superseded by W-341's discharge; upstream's
        positional default values reached trunk with UA-1's merge 14801f14a
        (2026-10-05), and the range is now the plain call's, from the
        parameter count less `default_value_arity` (fork/overload/ov4-plan.md
        D-OV4-1).]
```

<!-- google-doc-style-resume -->

At :2173, after "j: no default arguments, arity exact;" insert "[note <date>:
superseded by OV-4, fork/overload/ov4-plan.md]" on the same line, rewrapped by
hand inside the item so no line starts with a list marker or a digit and a
period.

## Appendix D. Records texts, verbatim (R, D, L-R, L)

`<date>` is the commit's `date -u +%F`; `<C1>`, `<F1>`, `<P>`, `<M>` and
`<F-M>` are those commits' short shas; `<NN>` is OV-4's PR number; figures in
`<...>` are the run each record quotes.

### §D.1 fork/inventory/work-items.json (D)

W-341 changes in place: `kind` becomes `implemented`, `title` and `subsystem`
are replaced, the four "Landed at" items are prepended to `evidence` (the filed
items stay after them), and the discharge sentence is appended to `notes`.

<!-- google-doc-style-ignore -->

```json
{
  "id": "W-341",
  "kind": "implemented",
  "title": "OV-4 (DISCHARGED at OV-4, <date>): an `overload fn` member with upstream's positional default values is called with a defaulted argument omitted -- the overload set's arity step accepts the plain call's range (`default_value_arity`), its probe converts the supplied arguments only and the ordinary call fills the rest, gate (iii) looks through a default value, member identity ignores defaults, and a diagnosed non-trailing default counts none; F-009j rewritten to name upstream's mechanism (R32 (b), (d); weekly upstream check 2026-10-26)",
  "subsystem": "toolchain/check (call.cpp, handle_function.cpp, merge.cpp, merge.h) + docs/design (functions_overloading.md) + tests",
  "evidence_prepended": [
    "Landed at OV-4 (<C1>): toolchain/check/call.cpp:424-438 (`GetExplicitArityRange`: `[n - default_value_arity, n]`, `ResolveCalleeInCall`'s range and CHECK), :499-511 (`ProbeOverloadCandidateInScratchScope`: the supplied arguments against the leading parameter patterns, under `CARBON_CHECK(arg_ids.size() <= param_pattern_ids.size() && param_pattern_ids.size() - arg_ids.size() <= default_value_arity)`)",
    "Landed at OV-4 (<C1>): toolchain/check/handle_function.cpp:366-367 (member identity through `CheckOverloadMemberParamsMatch`), :872-880 (gate (iii) through a `DefaultValuePattern`), :1046-1051 (`CheckDefaults`: a level with a diagnosed missing default counts none); toolchain/check/merge.cpp:576-628 and merge.h:121-129 (`GetOverloadMemberParamPatterns`, `CheckOverloadMemberParamsMatch`)",
    "Landed at OV-4 (<F1>): toolchain/check/testdata/function/overload/default_values.carbon (16 splits), toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon (3), toolchain/lower/testdata/function/overload/default_values.carbon (2), toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon (1)",
    "Landed at OV-4 (<P>): fork/conformance/programs/functions/overloading_default_values.carbon and the DIFF-1 pair overloading_default_values_diff.carbon and .diff.cpp; docs/design/functions_overloading.md's dated amendments (after the CLOSED paragraph at :570-576, F-009j, the arity step, 0.1 limits item (iii), D-OV-3's paragraph); fork/overload/plan.md's dated notes at :380 and :2173; measured <gate> of <gate> goldens and <pass>/0/<skip> over <total> programs, container-local, EXPECTED, not of record"
  ],
  "notes_appended": " Discharged <date> by OV-4 (fork/overload/ov4-plan.md; decision-log entry OV-4): the filed mechanism was necessary but not sufficient, because D-OV-6 gate (iii) refused every defaulted member at its declaration, member identity treated a default as a different parameter (a declaration differing only in a default became an unreachable member), and a diagnosed non-trailing default left the plain path's arity open (a CHECK at pattern_match.cpp:1275, on trunk and the nightly); OV-4 changed those three too, each at its root, with one resolution path and no new diagnostic. Generic members with defaults wait for 503f09037 at UA-3 (W-360), exported members' C++ default arguments for 9799a2326, 8fdc8ebc3 and c7de72757 (W-361); the default count's fix moves into function.cpp at UA-3 (W-362)."
}
```

<!-- google-doc-style-resume -->

New items, appended in id order:

<!-- google-doc-style-ignore -->

```json
[
  {
    "id": "W-360",
    "kind": "missing-feature",
    "title": "OV-4 residue: generic `overload fn` members with default values for non-generic parameters -- a call that omits a defaulted argument fails deduction on trunk (reason 2, 'candidate has generic parameters that could not be deduced'), exactly as the plain call of a generic function does ('cannot deduce value for generic parameter'), until upstream's 503f09037 appends the defaults in `DeduceGenericCallArguments`",
    "subsystem": "toolchain/check (deduce.cpp, pattern.cpp) + tests",
    "size": "S",
    "bullet": "Functions: function overloading (Carbon-native)",
    "evidence": [
      "toolchain/check/deduce.cpp:72-78 (`AddAll`: a parameter list longer than its arguments is treated as non-deduced) and :631-634",
      "toolchain/check/testdata/function/overload/default_values.carbon `fail_todo_generic_member_default` (its `TODO(UA-3, W-360)`; the set's member G and the plain function P)",
      "upstream 503f09037 (PR 8011): check/deduce.cpp:640-653 at e6fddcf97 ('If we are short on arguments, check if we can append default values for deduction.'), check/pattern.cpp:363 `ExtractParameterDefault`; 427c448dc (PR 8027) its golden",
      "fork/overload/ov4-plan.md D-OV4-7 and section 0.5 (503f09037's hunks applied to the prototype in a scratch build: the generic member in a set selects and prints, with no OV-4 code)"
    ],
    "blocked_by": [],
    "notes": "Filed <date> by OV-4. Owner: UA-3, whose audit takes 503f09037 with the advance and refills `fail_todo_generic_member_default` (renamed without `fail_todo_` once it passes). The fork's `diagnose` parameter of `DeduceGenericCallArguments` (OV-2) and PR 66's deduce.cpp changes are the merge's context. Break condition: UA-3 lands without 503f09037's deduce.cpp hunk, or PR 66's deduction changes the result for a defaulted generic member; the item then re-plans."
  },
  {
    "id": "W-361",
    "kind": "missing-feature",
    "title": "OV-4 residue: default values of exported `overload fn` members reach C++ -- trunk predates 9799a2326, so each member's C++ declaration has no default argument and a C++ call that omits one is resolved among the other members (`Carbon::F(1)` selects `F(bool)` where Carbon's `F(1)` selects `F(i32, i32 = 2)`) or rejected",
    "subsystem": "toolchain/check (cpp/export.cpp) + tests",
    "size": "S",
    "bullet": "Functions: function overloading (Carbon-native)",
    "evidence": [
      "toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon (`divergence_omitted`, `fail_cpp_omitted`) and its lower twin (C++'s `CallOne` calls `_CF__carbon_thunk:overload1.Main`)",
      "upstream 9799a2326 (PR 7988), 8fdc8ebc3 (PR 8025) and c7de72757 (PR 8019): check/cpp/export.cpp:964 `BuildDefaultValueExpr`, used at :1223 and :1422 at e6fddcf97",
      "fork/overload/ov4-plan.md D-OV4-10"
    ],
    "blocked_by": [],
    "notes": "Filed <date> by OV-4. Owner: UA-3. When the advance brings the three commits, each exported member's C++ declaration carries its defaults; the export split's C++ side then selects the defaulted member, and that change is recorded in the decision log before the golden moves (rulebook R30 (c)). Break condition: the per-member export path stops exporting a defaulted member, or UA-3's export of a member differs from a plain function's."
  },
  {
    "id": "W-362",
    "kind": "toolchain-defect",
    "title": "OV-4 residue (fixed on the fork, owed upstream): a call that omits an argument of a function whose default is not trailing aborted at pattern_match.cpp:1275 (`CARBON_CHECK(scrutinee_id.has_value())`), because `CheckDefaults` diagnosed the missing default and still returned the level's count; OV-4's `CheckDefaults` counts no defaults for such a level",
    "subsystem": "toolchain/check (handle_function.cpp; upstream's function.cpp)",
    "size": "S",
    "bullet": "Functions: function overloading (Carbon-native)",
    "evidence": [
      "toolchain/check/handle_function.cpp:1046-1051 (the fix, OV-4 <C1>)",
      "toolchain/check/testdata/function/overload/default_values.carbon `fail_default_not_trailing` (the set member and the plain function P)",
      "upstream e6fddcf97 toolchain/check/function.cpp:688 `CheckDefaults` (moved by 1b0a5709e, PR 7893; unchanged but for diagnostic rendering), call.cpp:46-84",
      "fork/overload/ov4-plan.md D-OV4-5 and section 0.3 p21 (the crash on trunk and on the 2026.10.12 nightly)"
    ],
    "blocked_by": [],
    "notes": "Filed <date> by OV-4. Owner: UA-3, which carries the fix into function.cpp's `CheckDefaults` (1b0a5709e moved it), or drops it if upstream has fixed the crash another way, and reports the crash upstream if the tip still has it. Break condition: upstream fixes it; UA-3 then takes upstream's fix."
  }
]
```

<!-- google-doc-style-resume -->

### §D.2 fork/decision-log.md, the entry OV-4 (D), placed after DR-0's entry (and after RG-1's once PR 67 has landed)

<!-- google-doc-style-ignore -->

```markdown
### OV-4: `overload fn` members with default parameter values (W-341) (<date>)

W-341 (filed at the weekly upstream check 2026-10-26) is DISCHARGED on
claude/carbon-fork-0-1-ov4 (fork/overload/ov4-plan.md, commits <C1>, <F1>,
<P>, <R> and this one): an `overload fn` member with upstream's positional
default values is called with a defaulted argument omitted, as the ordinary
call of the same function is. The gap row "Functions: function overloading
(Carbon-native)" stays DONE with its evidence refreshed. Measured
container-local, EXPECTED, not of record: <gate> of <gate> goldens, conformance
<pass>/0/<skip> over <total>, bullets <bullets>.

_The rule._ A member with default values behaves, for the number of arguments
it is called with, exactly as the ordinary call of the same function would;
between two members that both accept a call, the first in declaration order is
selected (D-OV-4). Decisions, auto-adopted under R29 (a), veto-able:

-   **D-OV4-1:** the arity step accepts `[n - default_value_arity, n]`, keyed
    on the call's receiver: `ResolveCalleeInCall`'s range. Break: upstream
    changes that range (issue 7529's tuple defaults) or picks another
    optional-parameter mechanism.
-   **D-OV4-2:** the probe converts the supplied arguments against the
    leading parameter patterns; the commit's `CallerPatternMatch` fills the
    omitted defaults. Break: a default that depends on the call.
-   **D-OV4-3:** gate (iii) looks through a `DefaultValuePattern`; a defaulted
    `var` or tuple parameter stays gated. Break: gate (iii) lifted (W-095).
-   **D-OV4-4:** member identity (D-OV-3, F-009k) ignores default values; a
    declaration differing from a member only in a default is
    `RedeclParamDiffers`. Break: upstream lets redeclarations differ in
    defaults.
-   **D-OV4-5:** a level with a diagnosed missing default counts no defaults
    (the plain call aborted at pattern_match.cpp:1275; W-362). Break: upstream
    fixes it otherwise.
-   **D-OV4-6:** two members that accept one call, one through a default:
    first match, no ranking (pattern_matching.md:696-697 at e6fddcf97). Break:
    an upstream overloading design with ranking.
-   **D-OV4-7:** generic members with a defaulted argument omitted fail
    deduction as the plain call does, until 503f09037 at UA-3 (W-360). Break:
    UA-3 lands without it.
-   **D-OV4-8:** receivers need no new rule (`self` takes no default). Break:
    upstream allows a defaulted `self`.
-   **D-OV4-9:** imported members carry `default_value_arity` and the pattern.
    Break: upstream stops importing them.
-   **D-OV4-10:** exported members have no C++ default argument until
    9799a2326 at UA-3; both sides pinned (R30; W-361). Break: the export path
    changes.
-   **D-OV4-11:** template-dependent calls resolve per specific, under the
    same rule. Break: a dependent call resolved before substitution.
-   **D-OV4-12:** defaults are constants, by upstream's toolchain; nothing
    added. Break: upstream allows an earlier parameter.
-   **D-OV4-13:** no new diagnostic or text. Break: a misleading note in a
    real call.
-   **D-OV4-14 to D-OV4-17:** the goldens and programs, the docs and records,
    the merge position after PR 66 with no held PR amended, and the commit
    sequence (fork/overload/ov4-plan.md sections 1 and 3).

_V-3 check at upstream's tip e6fddcf97 (R32 (a))._ Upstream's design pages and
proposals do not describe parameter default values: `git grep -c -i -E
'default (value|argument)'` over docs/design/functions.md and
pattern_matching.md is 0, and classes.md:2186-2191 lists "optional named
parameters" as future work ("Structs are being considered as a possible
mechanism for implementing optional named parameters."). Upstream's toolchain
implements positional default values: call.cpp:46-52 ("It also verifies that
the number of arguments is within the range [callee_arity -
arity_lower_bound_margin, callee_arity]. This allows arity matching when the
callee has default arguments for some subpatterns.") and :241, function.cpp
:676-688 (`CheckDefaults`, "TODO: per
https://github.com/carbon-language/carbon-lang/issues/7529"),
pattern_match.cpp:950 ("If there's no scrutinee supplied, supply the default
value instead."), handle_pattern_list.cpp:185 ("default value is not a
constant"). F-009j's "no Carbon-native default arguments in 0.1" denied that
mechanism, the drift W-341 filed under R32 (d); its rewrite names it. Upstream
has no overload sets (pattern_matching.md:696-697: "We do not yet have an
approved design for overloaded functions, but it is anticipated that
declaration order will be used in that case too."), so the rule between
members that accept a call through defaults has no upstream text and follows
first match. Upstream commits since the cut that touch default values:
1b0a5709e, 2c9739799, d87891f3a, 9799a2326, 503f09037, 427c448dc, 8fdc8ebc3,
c7de72757 (fork/overload/ov4-plan.md section 0.2); none changes the arity
margin or the fill.

_V-3a register lines (RG-1's vocabulary, D-RG-1 to D-RG-6)._ (vi) F-009j,
Carbon default arguments in overload sets: **ALIGNED**, the fork's rule is the
mechanism of upstream's toolchain, quoted above; watched by W-355; quotes
added to fork/register/rg1-quotes.tsv at land time. (vii) The rule between
`overload fn` members that accept one call through defaults (first match, no
ranking): **NONE**, upstream has no overload sets and no text on defaults with
overloading; watched by W-355 with silence checks OV4.1 to OV4.3 in
fork/register/rg1-checks.tsv at land time. Break conditions: (vi) upstream
designs another optional-parameter mechanism or removes positional defaults
(W-341's); (vii) an accepted upstream overloading design, or upstream text on
defaults with overloading.

_Residues._ W-360 (generic members, 503f09037), W-361 (export, 9799a2326,
8fdc8ebc3, c7de72757) and W-362 (the default count, into function.cpp), all
UA-3's; W-363 and W-364 unused. No held PR is amended (R32 (e)).
```

<!-- google-doc-style-resume -->

### §D.3 fork/decision-log.md, the weekly entry of 2026-10-26 (D)

Inserted as its own paragraph directly after the paragraph that ends "...or
removes positional defaults." in "Weekly upstream check 2026-10-26 (R32
direction register)":

<!-- google-doc-style-ignore -->

```markdown
_Note <date> (OV-4):_ W-341 is resolved by OV-4 and DISCHARGED (see the entry
"OV-4: `overload fn` members with default parameter values (W-341)"): the
arity step, the probe, gate (iii), member identity and the default count follow
upstream's positional default values, and F-009j is rewritten to name them,
quoted at e6fddcf97. Its break condition has not fired: classes.md:2186-2191
still lists named optional parameters as an open question at e6fddcf97, and no
upstream commit since the cut removes positional defaults.
```

<!-- google-doc-style-resume -->

### §D.4 fork/gap-analysis.md, the row "Functions: function overloading (Carbon-native)" (R)

The row stays DONE. Three in-place edits of its evidence cell:

1.  After "the `--dump-cpp-ast` sibling overload_set_ast.carbon)." insert
    " OV-4 landed (W-341 DISCHARGED <date>, fork/overload/ov4-plan.md): members
    take upstream's positional default values (an R32 realignment of F-009j)
    — a member accepts from its parameter count less its trailing defaulted
    parameters up to its parameter count, the probe converts the supplied
    arguments only and the ordinary call fills the rest, first match decides
    between members that both accept, and a declaration that differs from a
    member only in a default is `RedeclParamDiffers` (check and lower goldens
    function/overload/default_values.carbon and
    interop/cpp/function/export/overload_set_default.carbon)."
2.  After "the documented divergence asserted on both sides in one program
    (rulebook R30)" insert "; at OV-4, functions/overloading_default_values
    (hand-derived EXPECT) and the DIFF-1 pair
    functions/overloading_default_values_diff, 9/9 container-measured on <F1>
    (<pass>/0/<skip> over <total>, EXPECTED, not of record)".
3.  Before " — ids provisional against the slices branch." insert "; OV-4's
    W-360 (generic members with defaults, 503f09037), W-361 (defaults of
    exported members, 9799a2326) and W-362 (the default count, into
    function.cpp), all at UA-3".

### §D.5 fork/ORCHESTRATION.md (R, then the trunk stamp)

Header, prepended to "Last updated:" as each workstream does:

<!-- google-doc-style-ignore -->

```markdown
Last updated: <date> (OV-4, `overload fn` members with upstream's default
parameter values (W-341), is implemented on claude/carbon-fork-0-1-ov4 on
trunk's base and <state>; it merges last, after PR 66; see the paragraph dated
<date> below; the earlier 2026-10-28 text follows).
```

<!-- google-doc-style-resume -->

Dated paragraph, after the paragraph dated "2026-10-28 (04:47 UTC)":

<!-- google-doc-style-ignore -->

```markdown
<date> (<time> UTC): OV-4 is IMPLEMENTED on claude/carbon-fork-0-1-ov4
(fork/overload/ov4-plan.md rev <n>; commits <C1>, <F1>, <P>, <R>; base trunk
66bd2ba90) and <state>. An `overload fn` member with upstream's positional
default values is called with a defaulted argument omitted: the arity step
takes the plain call's range, the probe converts the supplied arguments and
the ordinary call fills the rest; gate (iii) looks through a default value,
member identity ignores defaults (a default-only difference is
`RedeclParamDiffers`), and a diagnosed non-trailing default counts none, which
also fixes the plain path's abort at pattern_match.cpp:1275. F-009j is
rewritten to name upstream's mechanism (R32), quoted at e6fddcf97. Measured
container-local: <gate> of <gate> goldens, <pass>/0/<skip> over <total>.
Residues for UA-3: W-360 (503f09037), W-361 (9799a2326, 8fdc8ebc3,
c7de72757), W-362 (function.cpp). No held PR is amended. OV-4 merges after PR
66 through M, F-M, L-R and L (the plan's section 3).
```

<!-- google-doc-style-resume -->

Branches row, after `claude/carbon-fork-0-1-rg1`'s:

<!-- google-doc-style-ignore -->

```markdown
| `claude/carbon-fork-0-1-ov4` | <state, for example HELD OPEN as PR <NN>> (base trunk 66bd2ba90) — OV-4, `overload fn` members with default parameter values (W-341 DISCHARGED; W-360 to W-362 filed for UA-3; W-363 and W-364 unused), at <head>; gap row "Functions: function overloading (Carbon-native)" stays DONE; expected <gate> of <gate> and <pass>/0/<skip> over <total>; merges last, after PR 66, through M, F-M, L-R and L. |
```

<!-- google-doc-style-resume -->

Next actions item 6, its first sentence replaced (the rest of the item
unchanged):

<!-- google-doc-style-ignore -->

```markdown
6.  **R32 work from the 2026-10-26 weekly check and RG-1 (2026-10-28)**: W-341
    (OV-4) is implemented on claude/carbon-fork-0-1-ov4 and <state>, merging
    after PR 66 and before UA-3 through M, F-M, L-R and L
    (fork/overload/ov4-plan.md section 3); its residues W-360, W-361 and W-362
    go to UA-3.
```

<!-- google-doc-style-resume -->

### §D.6 The register rows (L-R, after PR 67 lands)

Appended to fork/register/rg1-checks.tsv (id, kind, flags, pattern, paths,
count at the tip; measured at e6fddcf97 with PR 67's check_greps.sh: "checked
3 silence checks, 0 failed"):

<!-- google-doc-style-ignore -->

```text
OV4.1	G	-i -E	overload.*default (value|argument)|default (value|argument).*overload	docs/design proposals	0
OV4.2	G	-i -E	default (value|argument)	docs/design/functions.md docs/design/pattern_matching.md	0
OV4.3	G	-w	default_value_arity	toolchain/check	3
```

<!-- google-doc-style-resume -->

Appended to fork/register/rg1-quotes.tsv (path, line at the tip, verbatim
substring; measured at e6fddcf97 with PR 67's check_quotes.sh: "checked 9
quotes, 0 failed"):

<!-- google-doc-style-ignore -->

```text
toolchain/check/call.cpp	49	// the range [callee_arity - arity_lower_bound_margin, callee_arity]. This
toolchain/check/call.cpp	50	// allows arity matching when the callee has default arguments for some
toolchain/check/call.cpp	241	function.default_value_arity);
toolchain/check/pattern_match.cpp	950	// If there's no scrutinee supplied, supply the default value instead.
toolchain/check/function.cpp	682	// TODO: per https://github.com/carbon-language/carbon-lang/issues/7529, this
toolchain/check/handle_pattern_list.cpp	185	"default value is not a constant");
docs/design/classes.md	2186	### Optional named parameters
docs/design/classes.md	2188	Structs are being considered as a possible mechanism for implementing optional
docs/design/pattern_matching.md	696	We do not yet have an approved design for overloaded functions, but it
```

<!-- google-doc-style-resume -->

The rows use the TSV's tab separators (shown as tabs above). At L-R both
scripts are re-run at that day's tip over the whole tables; a failed row is a
weekly-check finding filed under W-355, never an edit of the expected count.
