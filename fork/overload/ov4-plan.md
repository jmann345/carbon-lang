<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# OV-4 plan: `overload fn` members with default parameter values (W-341)

**Status:** rev 3, 2026-10-28 -- SIGNED OFF FOR IMPLEMENTATION. Rev 3 folds
the focused re-review RR1 of rev 2 (7fda41b11; APPROVE-WITH-AMENDMENTS: no
BLOCKER, no MAJOR, four MINORs, all four folded, none rejected; see "Review
fold record (rev 3, 2026-10-28)" at the end of §8), and the "Sign-off" section
after §8 tables every review of this plan. Rev 2, 2026-10-28, folded plan
reviews A and B (fifteen findings: fourteen folded, one folded in part with its
proposed fix rejected on upstream evidence; see "Review fold record (rev 2,
2026-10-28)"). Rev 1 was the planner's draft, fdaed06ae.
Branch `claude/carbon-fork-0-1-ov4` in /home/user/carbon-ov4, cut from trunk
66bd2ba90 (pushed, no commits of its own before this plan). One PR, base
trunk, merging after PR 66 and before EH-C (fork ORCHESTRATION Next actions
item 6: "after VA-2 lands and before UA-3"; amended 2026-10-28, review fold:
B-m2). The work item is W-341 and only W-341 (size M), the overload
workstream's default-value slice; OV-4 mints no F id (R32 makes upstream's
design the spelling, so F-009j is rewritten, not re-minted) and reserves W-360
to W-364 for its residues. Every measurement below is container-local,
EXPECTED, not of record (R9).

W-341 as filed names two changes, the arity range and the probe over the
supplied arguments. The audit finds that neither is reached first: on trunk a
member with a defaulted parameter is refused at its declaration by D-OV-6 gate
(iii), "`overload fn` with a non-value explicit parameter" (§0.3, every probe
on five toolchains), because the gate does not look through the
`DefaultValuePattern` that wraps the parameter. Lifting the gate exposes two
more defects that the filed mechanism does not mention: member identity
(D-OV-3) treats a default value as a different parameter, so a declaration that
differs from a member only in its default silently becomes a second member of
the same parameter types, and a declaration whose default is not trailing,
which the plain call path already crashes on (trunk and the nightly, §0.3
p21), would start crashing through a set. The plan fixes all five at their
roots in four files (§2), with no second resolution path and no new
diagnostic, measured on a prototype build. Rev 2's prototype (the scratch
commit 3ff06902f, §0.5) counts only the trailing defaults of a level with a
diagnosed missing default, so a call that compiled before the fix still
compiles (amended 2026-10-28, review fold: A-m3), and pins the per-specific
conversion of a template-dependent default, which upstream's "Substitution
failure is an error" makes a diagnosed member, never a skipped one (amended
2026-10-28, review fold: A-M1): 1946 of 1946 goldens (trunk's 1942 unchanged
plus the four new files), 130/0/22 over 152 programs (trunk's 128/0/22 over
150 plus the two new programs), mutants M1 to M5 and M5b each caught on the
toolchain and M6 on the programs (§0.5, §8.5; amended 2026-10-28, review fold:
A-m4). Rev 3 changes no toolchain line: it adds one split and one call to
Appendix A.1's golden source, filled and measured on the same prototype
toolchain (1946 of 1946, 130/0/22 over 152; amended 2026-10-28, review fold:
RR1-m1 / RR1-m2).

## Sections

-   §0 Audit: baseline, upstream at the tip, measurements, the resolution path,
    the prototype and mutants, collisions, programs, register, ids.
-   §1 Design: decisions D-OV4-1 to D-OV4-16, each with its break condition
    (D-OV4-17, the commit sequence, is in §3).
-   §2 Spec, file by file, with the reviewed diffs.
-   §3 Commits, the fix budget, the re-review of the fix commits and D, and the
    land-time commits with their messages and texts.
-   §4 Testdata matrix.
-   §5 Conformance delta.
-   §6 Churn and collisions with the held PRs, region by region.
-   §7 Risks and rejected alternatives.
-   §8 Verification, ending with the review fold records of rev 2 and rev 3.
-   Sign-off: every review of this plan, its verdict and its counts.
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

The fixer's rev-2 measurements (amended 2026-10-28, review fold: A-M1, A-m3,
B-M3, B-m5) re-ran the same check first (`git diff --stat 0bdce60a5 66bd2ba90 --
toolchain core` is empty) and built the rev-1 prototype from
`$Q/proto-toolchain.diff` and `$Q/saved` in a detached worktree
(`CB_BUILD_ROOT=/dev/shm/ov4-fixer/builds`, 7.0 minutes): its 38 probes print
the planner's lines exactly. The rev-2 prototype is that build with §2's rev-2
hunks and Appendix A's rev-2 sources, the scratch commits 88899f052 and
3ff06902f on no branch (`0.0.0-0.dev+fdaed06ae.dirty`); its records twin is
59b65eb9c, which adds Appendix C's and D's texts as P and D (§0.6). The fixer's
probes, logs and saved files are under
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ov4/fixer
(`$X` below): `$X/probes` (the planner's 38, reviewer A's 17 and the fixer's f01
to f07), `$X/n-<toolchain>.txt`, `$X/r2/proto-toolchain.diff`, `$X/r2/saved`,
`$X/appx` and `$X/mt-regions2.txt`.

The fixer's rev-3 measurements (amended 2026-10-28, review fold: RR1-m1 / RR1-m2
/ RR1-m3 / RR1-m4) re-ran the check (`git diff --stat 0bdce60a5 66bd2ba90 --
toolchain core` is empty) and rebuilt the rev-2 prototype, the scratch commit
3ff06902f, in a detached worktree (`CB_BUILD_ROOT=/dev/shm/ov4-fixer1/builds`,
9.8 minutes beside probe runs, `0.0.0-0.dev+3ff06902f`), with Appendix A's rev-3
sources written in place of its goldens; rev 3 changes no toolchain line. The
focused re-review's probes r01, r02, r02b and r04 and the fixer's r04s ran on
trunk, PR 59, PR 66, PR 61, PR 64, the nightly and the prototype (§0.3), and
mutant M5 was rebuilt on rev 3 (§0.5). Probes, logs and the rev-3 fill are under
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ov4/fixer1
(`$F` below): `$F/probes`, `$F/n-<toolchain>.txt`, `$F/r3/saved` (the four
filled goldens, each path's `/` written `_`), `$F/r3/golden-rev3.diff` (the
check golden against 3ff06902f's) and `$F/reg` (the register rows and both
scripts' runs).

### §0.2 Upstream at the tip, and every commit since the cut (R32 (a), (c))

`git -C /home/user/carbon-lang fetch -q upstream trunk` left upstream/trunk at
**e6fddcf97** (2026-10-27 22:16 UTC, "Add all stores in File to
CollectMemUsage", upstream PR 8050) for the planner, the tip named for
2026-10-28 00:54 UTC, 133 commits past the cut c1e83b0b7. The fixer's
re-fetch (2026-10-28 06:58 UTC) leaves it at **0421bf3b4** (2026-10-28 05:36
UTC, "Optimize token kinds and whitespace flags", upstream PR 8044), one commit
later, which changes only toolchain/lex and toolchain/base/value_store.h; every
quote below reads identically at both shas, and the fifteen register quotes of
rev 2's Appendix D.6 pass at both (amended 2026-10-28, review fold: A-m1 /
B-m5). The rev-3 fixer's re-fetches (2026-10-28, before 08:05 UTC and again
at 08:31 UTC) leave the tip at 0421bf3b4, and the sixteen quotes of rev 3's
Appendix D.6 pass at both shas (amended 2026-10-28, review fold: RR1-m3).

_The design text_ (amended 2026-10-28, review fold: A-m1 / B-M1; rev 1 said
that no design page or accepted proposal describes parameter default values,
which is false). Upstream's accepted design spells positional default values in
two places, an example in an accepted proposal and a sketch under an open
question, and defines nothing else about them:

-   proposals/p002200-template-generics.md:471-476 at 0421bf3b4, in the
    template-dependent member lookup example: "class C4 { fn M[me: Self](p:
    i32 = 4); }", then "Calls `F` with `T` equal to `C4`, which succeeds,
    using the default value of `4` for `p` when calling `C4.M`." A trailing
    positional default, the argument omitted, the default supplied: the
    toolchain's mechanism. The call is from a template, so it bears on
    D-OV4-11.
-   docs/design/classes.md:2186-2191, "Optional named parameters", under
    Future work: "Structs are being considered as a possible mechanism for
    implementing optional named parameters. We have three main candidate
    approaches: allowing struct types to have field defaults, having dedicated
    support for destructuring struct values in pattern contexts, or having a
    dedicated optional named parameter syntax." Its first candidate,
    :2193-2216 "Field defaults for struct types", declares `fn
    SortIntVector(v: Vector(i32)*, options: {.stable: bool = false,
    .descending: bool = false} = {})` (:2199-2202) and calls
    `SortIntVector(&v);` (:2207) and `SortIntVector(&v, {});` (:2208): the
    parameter `options` has the positional default `{}`, omitted at the first
    call. The open question is the _named_ mechanism (field defaults,
    destructuring or a dedicated syntax); the positional default it is built on
    is spelled as the toolchain spells it.
-   docs/design/functions.md: `git grep -c -i -E 'default (value|argument)'`
    over functions.md and pattern_matching.md is 0. Its declaration forms
    (:54-57) are "`fn` _name_ [_implicit-parameters_] [_tuple-pattern_] ..."
    with no default; its "Positional parameters" (:242-247) are the `$0`
    parameters of a body without a parameter list, a different feature.
-   proposals/p006254:147-148, about C++ callees: "**Default Arguments:** The
    Carbon call omits arguments that have default values in C++. The thunk
    provides the default values."
-   docs/design/pattern_matching.md:696-697: "We do not yet have an approved
    design for overloaded functions, but it is anticipated that declaration
    order will be used in that case too." Upstream has no overload sets, so
    the interaction of defaults with overload resolution has no upstream text.
-   Templates and overload resolution (amended 2026-10-28, review fold: A-M1):
    p002200:214-217, "Substitution failure is an error. In C++, the SFINAE
    rule will skip functions in overload resolution that fail to instantiate.
    Instead, Carbon template parameters use constraints to control when the
    function is available." (the proposal links "the SFINAE rule" to its own
    Terminology section, :176-182); docs/design/README.md:2828-2832,
    "One difference from C++ templates, Carbon template instantiation is not
    controlled by the SFINAE rule of C++ ... but by explicit constraints
    declared in the function signature and evaluated at compile-time."

_The mechanism, in upstream's toolchain at e6fddcf97 and 0421bf3b4 alike (R32
reads toolchain text that names a mechanism)._

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
-   toolchain/check/function.cpp:29-46, `FindSelfPattern`, through
    sem_ir/pattern.cpp:51-55 `IsSelfPattern` and its `GetUnwrapped` (:15-38),
    which looks through `var` patterns, `SpecificConstant` and loaded import
    refs and not through a `DefaultValuePattern`: a parameter named `self`
    that has a default is not the function's `self`, and the function is not
    a method (D-OV4-8; amended 2026-10-28, review fold: RR1-m1).
-   Goldens: function/call/default_values.carbon (its
    `fail_caller_too_few_arguments` split: "0 arguments passed to function
    expecting 2 arguments"), function/declaration, function/definition and
    function/generic default_values.carbon, interop/cpp/function/export and
    lower default_values.carbon, parse/function/default_values.carbon.

The direction is therefore upstream's positional default values, spelled in an
accepted proposal's example and a design page's sketch and implemented by its
toolchain: trailing positional defaults whose values are constants, filled by
the plain call (amended 2026-10-28, review fold: A-m1 / B-M1; rev 1 called it
"upstream's toolchain mechanism with no design page"). F-009j's "no
Carbon-native default arguments in 0.1" denies a mechanism upstream designs and
implements, the R32 (d) drift W-341 files; OV-4's rule follows it and stops,
for named optional parameters, at classes.md's open question (R32 (d); §1
D-OV4-15). Upstream's template design makes a substitution failure an error,
never a reason to skip a candidate, which D-OV4-11 applies to a member whose
template-dependent default fails in a specific.

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

Rows the reviews and the fixer added (amended 2026-10-28, review fold: A-M1 /
A-m3; probes `$X/probes/a09*.carbon`, `a10*`, `f0*`; "rev 1" is the planner's
prototype, "rev 2" the fixer's; trunk, PR 59, PR 66, PR 61 and PR 64 agree on
every row, and PR 64 is measured again on m64 with OV-4, §8.7):

| probe | trunk = PR 59 = PR 66 = PR 61 = PR 64 | rev 1 | rev 2 | nightly |
| --- | --- | --- | --- | --- |
| a09c `class Box(template T: type)` with `Get(y: T = 0)` then `Get()`, `Put(y: T)` then `Put(y: i32)`: `Box(i32).Get()`, `Box(bool).Put(0)`, `Box(bool).Get()` | TODO(iii) | "unable to monomorphize specific `Get(bool)`" at `Box(bool).Get()`, notes "cannot implicitly convert expression of type `Core.IntLiteral` to `bool`" at the default | same | n/a |
| a09b and f02, the plain `fn Get(y: T = 0)` in that class, `Box(bool).Get()` | the same monomorphization error | same | same | same |
| f01, the plain `Get`, `Box(bool).Get(true)`, the argument supplied | the same monomorphization error | same | same | same |
| f04, the set `Get(y: T = 0)` and `Get(b: bool, c: bool)`, `Box(bool).Get(true)` | TODO(iii) and the same monomorphization error | the monomorphization error | same | n/a |
| f05, the set `Get()` then `Get(y: T = 0)`: `Box(i32).Get()`, `Box(i32).Get(5)`, `Box(bool).Get()` | TODO(iii) | prints 2, 1, 2 | same | n/a |
| f06, the set `Get(y: T = 7) -> T` and `Get(b: bool, c: bool) -> T`: `Box(i32).Get()`, `.Get(3)`, `Box(i64).Get()` | TODO(iii); NoMatch | prints 7, 3, 7 | same | n/a |
| f03, a set in a template class whose member 0 is `Get(y: T.Elem)`, no default: `Box(NoElem).Get(true)` | "unable to monomorphize specific `Get(NoElem)`", note "member name `Elem` not found in `NoElem`" | same | same | n/a |
| f03b, that member as a plain function | the same monomorphization error | same | same | same |
| a10 plain `fn P(x: i32 = 1, y: i32, z: i32 = 3)`, `P(5, 6)` | the missing-default error only; the call compiles | the missing-default error, then "2 arguments passed to function expecting 3 arguments" | the missing-default error only | the missing-default error only |
| f07, that declaration as a set member beside `P(b: bool)`, `P(5, 6)` | the missing-default error, TODO(iii), NoMatch | the missing-default error, NoMatch with two arity notes | the missing-default error only (the call resolves) | n/a |

Two more readings. The default of a template class's member is converted in
each specific of the member's declaration, and the conversion fails for the
specific whether the call omits or supplies the argument (f01, f04): a
template-dependent default is part of the declaration, as a template-dependent
parameter type is (f03, a trunk program with no default at all). Resolution
forms the specific of each member it reaches, in declaration order, inside
deduction's `MakeSpecific`, so the failure is diagnosed at the first member
that reaches it and a member after the selected one is never substituted (f05).
Upstream's template design makes that failure an error (§0.2, p002200:214-217),
so the measured behavior is the designed one (D-OV4-11). And the rev-1 count of
0 for a level with a diagnosed missing default rejected `P(5, 6)`, which
trunk's plain path accepts (a10): rev 2 counts the level's trailing defaults
(D-OV4-5).

Rows the focused re-review and the rev-3 fixer added (amended 2026-10-28,
review fold: RR1-m1 / RR1-m2; probes `$F/probes/r0*.carbon`: r01, r02, r02b
and r04 the re-review's, r04s the fixer's; "proto" is rev 2's toolchain, which
rev 3 does not change; PR 61 and PR 64 print trunk's lines exactly, PR 59 and
PR 66 too but for r04's line number):

| probe | trunk = PR 59 = PR 66 = PR 61 = PR 64 | proto | nightly |
| --- | --- | --- | --- |
| r01 plain `class C { fn M(self: i32 = 1) -> i32 }`, `C.M()`, `c.M()` | prints 1, 1 | same | same |
| r02 the set `M(self: i32 = 1)` and `M(unused b: bool)` in `C`: `C.M()`, `C.M(4)`, `c.M()`, `C.M(true)` | TODO(iii) at `self: i32 = 1`; NoMatch at `C.M()` and `c.M()`, arity notes | prints 1, 4, 1, -1 | n/a |
| r02b `M(self, y: i32 = 1)` then `M(self: i32 = 1)`, `c.M()` | TODO(iii) twice, gate (x)'s "`overload fn` members that disagree on `self`", NoMatch | gate (x)'s TODO only | n/a |
| r04 plain `fn P(x: i32 = 1, (a: i32, b: i32), z: i32 = 3)`, `P(5, (1, 2))`, `P((1, 2))` | the missing-default error; at `P((1, 2))` "cannot implicitly convert expression of type `(Core.IntLiteral, Core.IntLiteral)` to `i32`", then a CRASH, `CHECK failure at toolchain/check/pattern_match.cpp:1805`, the `std::holds_alternative<CalleeState*>(state)` check of the tuple pattern's `DoPreWork` (PR 59 and PR 66 at :1807) | the missing-default error, then "1 argument passed to function expecting 3 arguments" at `P((1, 2))` | CRASH at pattern_match.cpp:750, the same check (p21's at :489) |
| r04s that declaration as a set member beside `P(unused b: bool)`, `P((1, 2))` | the missing-default error, TODO(iii) at `x: i32 = 1`, NoMatch | the missing-default error, TODO(iii) at the tuple pattern, NoMatch with an arity note (member 0) and a conversion note (member 1) | n/a |

Two readings (amended 2026-10-28, review fold: RR1-m1 / RR1-m2). A `self`
that has a default is not a receiver, on trunk and upstream alike (§0.2,
`FindSelfPattern`): its plain call binds no receiver and fills `self` (r01),
and the set, reading the same `self_param_id`, treats the member as one
without `self` and prints the plain path's lines (r02), so D-OV4-8 needs no
rule for it. And the count's admitting a call that leaves a parameter without
a default unmatched has a second crash site: when that parameter is a tuple
pattern, the caller's pre-work stops at the tuple pattern's check
(pattern_match.cpp:1805) instead of the parameter pattern's (:1275). The
trailing count closes both: the plain call gets `CallArgCountMismatch` (r04)
and the set the arity note (r04s, behind gate (iii)'s TODO at the tuple
pattern, as p12b is).

### §0.4 Where a defaulted member enters each step of resolution

The path is OV-1's `PerformCallToOverloadSet` (trunk call.cpp:601-712), its
steps as D-OV-4 numbers them (fork/overload/plan.md:348-520):

1.  Erroneous arguments and gate (xi) (:605-626): unchanged; the arguments are
    the call's, and an omitted argument is no argument.
2.  (a) Receiver alignment (:646-652): unchanged. A `self` with a default is
    not a receiver (amended 2026-10-28, review fold: RR1-m1; rev 2 said
    "`self` never has a default in any probe"): `FindSelfPattern`
    (function.cpp:27-44) finds `self` through `IsSelfPattern`
    (sem_ir/pattern.cpp:51-55), whose `GetUnwrapped` (:15-38) does not look
    through a `DefaultValuePattern`, so `fn M(self: i32 = 1)` declares no
    `self_param_id` and is not a method, upstream's toolchain alike (§0.2).
    Its plain call `c.M()` binds no receiver and fills `self` with the default
    (r01). The set reads the same `self_param_id`, so such a member is a
    member without `self` for gate (x) and for this step, and the set prints
    the plain path's lines (r02); beside a member with `self` it is gate (x)'s
    TODO (r02b). A defaulted `self: Self` fails earlier, at the default's
    conversion to the incomplete class (a07, a07b).
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
    `CARBON_CHECK(scrutinee_id.has_value())` in the parameter pattern's
    `DoPreWork` (p21, plain, trunk and nightly), or, when the parameter left
    with no argument is a tuple pattern, :1805's `CARBON_CHECK(
    std::holds_alternative<CalleeState*>(state) || ...)` in the tuple
    pattern's `DoPreWork` (:1772-1805; r04, plain: trunk, PR 59 and PR 66 at
    :1807, the nightly at :750; amended 2026-10-28, review fold: RR1-m2).
    Upstream's tip has the same `CheckDefaults` (only its diagnostic rendering
    differs) and the same `ResolveCalleeInCall`; the crash at the tip is
    inferred, not measured (no tip build).
    A call that omits only the level's trailing defaulted arguments matches on
    trunk and does not crash (a10's `P(5, 6)` for `P(x: i32 = 1, y: i32, z:
    i32 = 3)`), so the root is the count's admitting more than the trailing
    run (amended 2026-10-28, review fold: A-m3).
-   A default whose type is template-dependent (amended 2026-10-28, review
    fold: A-M1): handle_pattern_list.cpp:357-367 converts the default with
    `ConvertToValueOfType`, which for a template-dependent target adds a
    `ConvertToValueAction` splice (convert.cpp:2392-2418) to the declaration's
    eval block. `MakeSpecific` (generic.cpp:700-706) resolves the declaration
    of every specific it forms (`ResolveSpecificDecl`, :689-698, through
    `TryEvalBlockForSpecific`, eval.cpp:3550-3591, under the "unable to
    monomorphize specific" context), and the probe's
    `DeduceGenericCallArguments` forms the member's specific before it
    converts any argument (call.cpp:502-516). The default's conversion
    therefore runs, and diagnoses, when resolution reaches the member, whether
    or not the call omits the argument; the plain call does the same (f01).
-   Import: import_ref.cpp:2806 copies `default_value_arity`, and :2459-2467
    imports a `DefaultValuePattern` as a deduplicated constant; the set's probe
    reads the imported member's pattern types through
    `GetScrutineeTypeInSpecific` and its commit fills `constants.%int_2` (the
    imported default; §4).
-   Export (OV-3): trunk predates 9799a2326, so an exported member's C++
    declaration has no default argument (p18c for a plain function; p18b for a
    set member, where C++ then selects another member).

### §0.5 The prototype and its mutants

The prototype is §2's diff (amended 2026-10-28, review fold: A-m3 / B-m5). Rev
1's (`$Q/proto-toolchain.diff`, 243 lines over call.cpp, handle_function.cpp,
merge.cpp and merge.h) was measured by the planner and committed only as the
scratch commit `4d5eff6de`, whose hunks differ in formatting from rev 1's §2
(B-m5). Rev 2's is the fixer's: rev 1's diff applied with `git apply`, the
`CheckDefaults` hunk changed to the trailing count with its `Fork (OV-4,
W-362)` marker (§2.2), and Appendix A's rev-2 sources and Appendix B's three
program files, committed as the scratch commits 88899f052 and 3ff06902f on no
branch. `git diff fdaed06ae 3ff06902f -- toolchain/check` is
`$X/r2/proto-toolchain.diff` (265 lines) and §2's blocks are copied from it,
so the merge-trees and mirrors of §0.6 and §8.7 ran on the formatted diff that
§2 shows. Measured on rev 2: clang-format 21.1.8 (`--assume-filename`) leaves
the four files unchanged; both clang-tidy passes (`$X/bin/tidy.sh`, the
planner's script pointed at the fixer's build) print nothing on the three .cpp
files; autoupdate reaches its fixpoint on the four goldens after two writing
passes and a third that changes nothing (`!!!!`, `..!.`, `....`, R26); the
gate passes 1946 of 1946; conformance PASS 130, SKIP 22, nothing else, of 152,
bullets 48 PASS, 0 FAIL, 8 SKIP, 0 NOT-WRITTEN of 56, the overloading bullet
PASS with 9 programs (66.1 s); `runner.py --self-test` "152 programs parsed,
56 bullets in table, OK"; the 62 probes of `$X/probe_list.txt` print rev 1's
lines but for a10 and f07 (§0.3).

Mutants, one per decision, each an edit of the rev-2 prototype rebuilt
incrementally and run on the four goldens (`gate.sh --file_tests=...`) and the
probes p02, p04, p13, p21, a10, a09c and f04 (`$X/mutants.py`,
`$X/run_mutants.sh`; the tree was restored and `git diff` compared equal to
rev 2's after the run):

| mutant | edit | measured |
| --- | --- | --- |
| M1 (D-OV4-1 without D-OV4-2) | the range widened, the probe's `CARBON_CHECK(param_pattern_ids.size() == arg_ids.size())` restored without `take_front` | p02, p04 and a09c abort: "CHECK failure at toolchain/check/call.cpp:508: param_pattern_ids.size() == arg_ids.size()"; the gate aborts (exit 134) |
| M2 (D-OV4-2 without D-OV4-1) | the probe's prefix kept, the range exact | all four goldens FAILED; p02 NoMatch; p04 prints 2, 1 (the exact member wins) |
| M3 (D-OV4-3 reverted) | gate (iii) not looking through the default | all four goldens FAILED; p02 and p04 print TODO(iii) |
| M4 (D-OV4-4 reverted) | identity through `CheckRedeclParamsMatch` again | the check golden default_values.carbon FAILED; p13 compiles, its second member of the same parameter types never selected |
| M5 (D-OV4-5 reverted to upstream's count) | `CheckDefaults` returns the level's count | the gate aborts (exit 134) and p21 aborts: "CHECK failure at toolchain/check/pattern_match.cpp:1275: scrutinee_id.has_value()" |
| M5b (D-OV4-5 as rev 1 had it) | a level with a diagnosed missing default counts 0 | the check golden FAILED (`fail_default_not_trailing`'s `Q(5, 6)` diagnosed); a10 gains "2 arguments passed to function expecting 3 arguments" |
| M6 (the programs, §8.5) | `Pick`'s and `Order`'s members swapped in B.1 | measured by the planner on rev 1's prototype, B.1 unchanged since: OUTPUT-MISMATCH, lines 3 and 5 printing 2 and 1 |

Review A's proposed probe check (A-M1's fix), measured as an alternative, not a
mutant: after deduction, reject a member whose specific `HasError()` with
reason 1. The four goldens pass unchanged and a09c still fails with the same
"unable to monomorphize specific `Get(bool)`" error, because
`ResolveSpecificDecl` has already emitted it inside deduction's `MakeSpecific`;
f04 gains a NoMatch error after it. The check would make the set skip a member
whose substitution failed, the SFINAE rule upstream rejects (§7.2).

A scratch measurement for D-OV4-7, the planner's on rev 1, not repeated (rev 2
does not touch deduction): 503f09037's pattern.cpp and pattern.h hunks applied
with `git apply` and its deduce.cpp hunk applied by hand around the fork's
`diagnose` parameter, on top of the prototype: p06 prints 5, 2; p07 (the
generic member in a set) prints 5, 2; p20 prints 9, 2. With no OV-4 code for
generic members, the set takes upstream's deduction once it arrives, which is
UA-3's (reverted; not part of any commit).

Rev 3's measurement (amended 2026-10-28, review fold: RR1-m1 / RR1-m2): the
rev-2 prototype rebuilt from 3ff06902f, its four goldens written from Appendix
A's rev-3 sources without CHECK lines and filled by autoupdate (`!!!!`,
`.!..`, `....`, R26, as on rev 2). The A.2 to A.4 fills are byte-identical to
3ff06902f's, and the check file's differs only in the new split and in
`fail_default_not_trailing` (`$F/r3/golden-rev3.diff`). The gate passes 1946
of 1946 (25 s); conformance PASS 130, SKIP 22, nothing else, of 152, bullets
48 PASS, 0 FAIL, 8 SKIP, 0 NOT-WRITTEN of 56 (67.4 s), as on rev 2. M5 rebuilt
on rev 3: the gate aborts on the check golden at pattern_match.cpp:1275
(`fail_default_not_trailing`'s `F(5)` is its first call), p21 aborts there,
and r04, whose `P` is the split's `R`, aborts at :1805, so the split pins the
second site once the first is fixed apart from it. The tree was restored,
rebuilt and re-gated (1946 of 1946), and the five r probes print §0.3's lines
again.

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
| 67 RG-1 | 56e2e5bbd | none in code; its records collide in five regions (below; amended 2026-10-28, review fold: B-M3) |

`git merge-tree --write-tree --name-only` of the prototype tree against each
head, less that head's own conflicts with trunk 66bd2ba90 (computed the same
way; `$X/mt.sh`), on rev 2's code-only tree 3ff06902f, the formatted diff of §2
(amended 2026-10-28, review fold: B-m5; rev 1 ran on 4d5eff6de): new conflicts
only on PR 59 and PR 66 (toolchain/check/handle_function.cpp, gate (iii)'s
loop, where VA-1 inserts its pack gate at the line OV-4 inserts the
look-through; the `CheckDefaults` hunk merges cleanly beside VA-1's
`PackExpansionPattern` case) and on PR 60 (toolchain/check/merge.cpp,
`CheckRedeclExplicitParamsAfterSelfMatch`'s return, where SC-1 adds the
`new_specific_id` and `found_error` arguments). Every other head, call.cpp of
PR 59, PR 61, PR 64, PR 65 and PR 66 included, merges cleanly. Two semantic
collisions merge cleanly and are caught only by building: SC-1 adds two
parameters with no defaults to `CheckRedeclParams` and `CheckRedeclParamLists`
(PR 60 merge.cpp:562-567 and :585-590), so OV-4's new
`CheckOverloadMemberParamsMatch` must pass `SemIR::SpecificId::None` and
`nullptr` after M (§6.2); and VA-1's pack gate must run before OV-4's
look-through.

The records collisions (amended 2026-10-28, review fold: B-M3; rev 1 listed PR
67 as "none" because its prototype tree held no records): the same merge-tree
on 59b65eb9c, which is 3ff06902f plus P (Appendix C applied) and D (Appendix
D.1 to D.5 applied, with `<date>` filled), comparing each conflict hunk with
the hunks the head already has against trunk (`$X/mt-regions2.py`,
`$X/mt-regions2.txt`). OV-4's records add conflict hunks in exactly two files
and five regions, and in no other file: fork/decision-log.md (the entry above
OV-3's heading and the weekly note), fork/gap-analysis.md, the overloading
design page and fork/overload/plan.md merge cleanly against every head.

| region | heads whose merge gains a hunk there |
| --- | --- |
| ORCHESTRATION's "Last updated:" header | PR 67, 53, 52, 60, 54, 55, 58, 62 |
| ORCHESTRATION's dated paragraphs (OV-4's after the 2026-10-28 04:47 UTC one) | PR 67, 60, 54, 56, 57, 58, 59, 61, 62, 64, 66 |
| ORCHESTRATION's Branches table (OV-4's row after RG-1's) | PR 67, 52, 60, 54, 55, 56, 57, 58, 62, 63, 65 |
| ORCHESTRATION's Next actions item 6 (its first sentence) | PR 67, 53, 52, 54, 55, 56, 57, 58, 59, 61, 62, 64, 66 |
| fork/inventory/work-items.json's tail (W-360 to W-362 appended after W-344) | all seventeen heads, PR 67 first (its W-346 to W-356) |

No hunk is unresolvable: each region's rule is in §6.2, and the land-time M
applies them to the landed trunk, where each region has one landed version
instead of seventeen.

The mirror m66 (§8.7) applies the code rules to PR 66 merged with the
prototype: `$Q/m66-*.log` (rev 1) and the fixer's `$X/m66-*.log` (rev 2).

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
and fork/register/rg1-plan.md §2.T2) classifies F-009's marker NONE (D-RG-6,
T2.7) and its closed sets and declaration-order first match ALIGNED (T2.5,
T2.6, the latter on pattern_matching.md:696-697), each watched by W-355, and
does not classify F-009j, which W-341 had filed as a drift the day before. In
RG-1's vocabulary (D-RG-1 to D-RG-6): an entry is a DRIFT when upstream has
designed its mechanism and the fork spells it otherwise, ALIGNED when the
fork's spelling or rule is upstream's, NONE when upstream is silent; toolchain
text that shows a mechanism with its spelling counts as upstream's (R32's
reading list), and toolchain-internal surfaces are NONE with their merge rules
as break conditions (D-RG-3).

OV-4 adds two entries at land time after PR 67, as rows T2.8 and T2.9 of RG-1's
§2.T2 table, continuing F-009's T2.5 to T2.7 (amended 2026-10-28, review fold:
A-m2 / B-m1; rev 1 numbered them (vi) and (vii), continuing DR-0's DRIFT list,
and classified first match NONE where T2.6 has it ALIGNED):

-   T2.8, F-009j, default arguments in overload sets: **ALIGNED**. The fork's
    rule is the mechanism p002200:471-476 and classes.md:2198-2207 spell and
    upstream's toolchain implements (§0.2). Its silence check is a presence
    watch, `default_value_arity` in toolchain/check (3 lines at 0421bf3b4), and
    its quotes are the toolchain's, the proposal's and classes.md's lines of
    Appendix D.6.
-   T2.9, the plain-call rule for a member with defaults (a member accepts a
    call at k explicit arguments exactly when its ordinary call does, and its
    probe converts the k supplied arguments): **NONE**. Upstream has no overload
    sets and no text on defaults with overloading. Its silence check counts the
    lines of docs/design and proposals that name overloaded functions, function
    overloading or overload sets (40 at 0421bf3b4), which a new upstream
    overloading proposal or page moves.
-   The tie-break between two members that both accept a call stays T2.6's
    ALIGNED first match, unchanged: D-OV4-6 applies T2.6, it adds no entry.

Commit L-R writes both rows into fork/register/rg1-plan.md's §2.T2 table,
directly after T2.7's, with the texts of Appendix D.6, so that the register's
table holds them where W-355's owner re-reads every entry's break condition
(D-RG-17). It appends their checks and quotes to PR 67's
fork/register/rg1-checks.tsv and rg1-quotes.tsv after a `#` comment line
naming fork/overload/ov4-plan.md and the two rows, as RG-1's own later rows
are introduced (rg1-quotes.tsv:270-271). Each TSV row then names a section 2
entry, as the TSVs' header says ("the row names a section 2 entry"), and
section 2 stays the source the two tables are rebuilt from (rg1-plan.md §4.2)
(amended 2026-10-28, review fold: RR1-m4; rev 2 named the rows, but no commit
wrote them). Measured with PR 67's check_greps.sh and check_quotes.sh at both
tips: "checked 2 silence checks, 0 failed" and "checked 16 quotes, 0 failed"
(`$F/reg`; rev 2's fifteen and function.cpp:677, the trailing-default rule
that C.1 quotes; amended 2026-10-28, review fold: RR1-m3); a dry run of the
two rows' insertion into PR 67's rg1-plan.md at 56e2e5bbd changes its R31
counts by two table rows and nothing else. Rev 1's three checks
become these two: its OV4.3 (`default_value_arity`) is T2.8's; its OV4.1
(lines naming both overloading and a default value, 0) is subsumed by T2.9's,
which any such line also moves; its OV4.2 (`default (value|argument)` in
functions.md and pattern_matching.md, 0) is dropped, because a design page that
starts describing default values is a design-page change every weekly check
lists under R32 (c), and T2.8's quotes of classes.md and p002200 fail
check_quotes.sh if those lines move.

### §0.9 Id re-scan

After `git fetch origin`, `git grep -h -o -E '\bW-3[6-9][0-9]\b'` over every
ref in `refs/remotes/origin` and `refs/heads` (164 refs) finds only W-398 and
W-399, each in the range text "W-330 to W-399" of DR-1's, RG-1's and VA-2's
plans; the same grep over the fork/, docs/ and toolchain/ trees of all 22
worktrees finds W-360 once, in this worktree's untracked prototype golden (the
`TODO(UA-3, W-360)` of Appendix A.1), and W-398 and W-399 as above. W-360 to
W-364 are free. RG-1's W-346 to W-356 are on PR 67's branch, W-357 and W-359
appear only as its "unused reserve" text, and W-358 nowhere. The fixer's
re-scan of `\bW-36[0-4]\b` (2026-10-28, after a fetch; amended 2026-10-28,
review fold: B-m5) over the same 164 refs and 22 worktrees, its own scratch
worktrees aside, finds only this branch's fork/overload/ov4-plan.md.

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
-   Rev 1's own false or stale statements, corrected in rev 2 (amended
    2026-10-28, review fold): "Upstream's design pages and proposals at
    e6fddcf97 do not describe parameter default values" (§0.2, C.1, D.2; A-m1,
    B-M1: p002200:471-476 and classes.md:2193-2216 spell them); "a default
    value is a constant ... already converted at the declaration ... nothing in
    it to probe" (D-OV4-2; A-M1: a template-dependent default is converted in
    each specific); "never an unreachable member" (D-OV4-4; B-m5: overlap
    through defaults makes one, as overlap through conversions does); R-3's
    "Such a call either supplied every argument (still passes) or omitted one
    and crashed" (A-m3: rev 1's count of 0 rejected `P(5, 6)`); "five mutants"
    in the introduction (A-m4: M1 to M5 and M6); "OV-4, D-OV4-8" in two golden
    headers (A-m4, B-m4: export is D-OV4-10); and §0.6's "67 RG-1 ... none"
    (B-M3: its records collide in five regions).
-   Rev 2's own false or incomplete statements, corrected in rev 3 (amended
    2026-10-28, review fold: RR1): "`self` never has a default in any probe"
    (§0.4) and "`self` included only when it carries a default, which no
    probe could declare (p13e)" (D-OV4-8, D.2; RR1-m1: `fn M(self: i32 = 1)`
    compiles, and is not a method); W-362's one crash site (RR1-m2: a tuple
    pattern left without an argument stops at pattern_match.cpp:1805); C.1's
    cite of call.cpp for the trailing and constant rules (RR1-m3:
    function.cpp:676-679 and handle_pattern_list.cpp:185 state them); and
    "rows T2.8 and T2.9 of RG-1's §2.T2 table" with no commit writing them
    (RR1-m4: L-R now does).

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
default (§0.4 step 6). A default value is converted to the parameter's type
by the declaration (handle_pattern_list.cpp:357-367): once, when its type is
not template-dependent, and in each specific of the declaration when it is,
through the `ConvertToValueAction` the declaration's eval block replays. The
probe has nothing of its own to check in it either way: the non-dependent
default converted at the declaration, and the dependent one converts, or
fails, when deduction's `MakeSpecific` forms the member's specific, before the
probe converts any supplied argument and whether or not the call omits it
(§0.3 f01, f04; §0.4; amended 2026-10-28, review fold: A-M1, whose finding
showed rev 1's "a constant of the parameter's type already converted at the
declaration" to be false for a template-dependent type). One resolution path
serves members with and without defaults. _Break condition:_ a default whose
value depends on the call (a non-constant default, or a default of a parameter
whose type is deduced from it), which upstream does not allow today
(handle_pattern_list.cpp:185 at 0421bf3b4 "default value is not a constant");
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
plain declarations (p13 against p13b), never a second member of the same
parameter types, which is what D-OV-3's rationale excludes ("would form a
two-member set whose second member is unreachable"). A member that an earlier
member's defaults cover, `Pick(x: i32)` after `Pick(x: i32, y: i32 = 2)`, is a
different case: its parameter types differ, it is a member, and first match
never selects it, as `Pick(i32)` after `Pick(i64)` is never selected for an
`i32` argument today (basic.carbon `first_match_order`); D-OV4-6 keeps such
sets legal (amended 2026-10-28, review fold: B-m5; rev 1 said "never an
unreachable member"). `CheckRedeclParam` itself is not changed, because
thunk.cpp:466-469 also reaches it with `check_syntax` false, through
`CheckFunctionTypeMatches` (function.cpp:358), for upstream's
impl-against-interface comparison, where a default difference must keep its
upstream meaning. _Break condition:_ upstream's redeclaration rules (p003763)
come to allow redeclarations that differ in defaults; identity still ignores
them and the ordinary check follows upstream.

**D-OV4-5 — a diagnosed non-trailing default counts only its trailing
defaults.** `CheckDefaults` diagnoses "this pattern is missing a required
default value." and still returns the level's count, so the plain call of `fn
F(x: i32 = 1, y: i32)` with one argument passes the arity check and aborts at
pattern_match.cpp:1275 (p21: trunk, the nightly; upstream's tip has the same
function and call path, inferred), and the call `R((1, 2))` of
`fn R(x: i32 = 1, (a: i32, b: i32), z: i32 = 3)`, whose omitted parameter is a
tuple pattern, aborts at the tuple pattern's CHECK, pattern_match.cpp:1805
(r04: trunk; the nightly at :750; amended 2026-10-28, review fold: RR1-m2).
Once D-OV4-3 admits such a member, a set reaches the same aborts (mutant M5).
The root of both is the count: a level with a diagnosed missing default counts
only the defaulted patterns after its last pattern without one, the only
parameters a positional call can omit, so the arity check admits exactly the
calls whose omitted arguments all have defaults.
Every call that compiled on trunk still compiles (`P(5, 6)` for `P(x: i32 = 1,
y: i32, z: i32 = 3)`, a10), and every call that crashed, at either site, gets
`CallArgCountMismatch` (plain: p21, r04) or the arity note (set) (amended
2026-10-28, review fold: A-m3 / RR1-m2; rev 1 counted 0, which also rejected
`P(5, 6)`, mutant M5b).
The edit to upstream's `CheckDefaults` carries a `Fork (OV-4, W-362)` marker at
its new field and at its changed return, for UA-3's merge into function.cpp
after 1b0a5709e (amended 2026-10-28, review fold: B-m5). It is the plain path's
fix, made here because OV-4 opens the set path to it; W-362 carries the merge
rule into function.cpp at UA-3 and the upstream report. _Break condition:_
upstream fixes the crash otherwise, and UA-3 takes upstream's fix and drops this
one.

**D-OV4-6 — two members that both accept a call: first match.** With defaults,
`Pick(x: i32, y: i32 = 2)` and `Pick(x: i32)` both accept `Pick(5)`. D-OV-4's
loop takes the first member in declaration order that accepts, so the defaulted
member wins when it is first (p04: 1, 1) and the exact member wins when it is
first (p05: 2, 1). That is D-OV-4 step 5 ("Ranking is deliberately absent")
and upstream's anticipated order, pattern_matching.md:696-697: "it is
anticipated that declaration order will be used in that case too", the quote
RG-1's T2.6 classifies ALIGNED. Using a default is not a worse match and an
exact arity is not a better one: there is no ranking to extend. Such a set is
legal, and no diagnostic warns about the overlap, even where it leaves the
later member unselectable (D-OV4-4; amended 2026-10-28, review fold: B-m5 /
A-m2). _Break condition:_ upstream approves an overloading design that ranks
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
`default_value_arity` counts the explicit parameters with defaults after
`self`. The range for `c.M()` is `[1 - 1, 1]` explicit arguments, and for
`C.M(c)` it is `[2 - 1, 2]` with the receiver probed against `self` as D-OV-4
step 2(e) does; both fill `n` at the commit (p08: 102, 105, 102, 107, the plain
method's output). A parameter named `self` that carries a default is not a
`self` parameter upstream: `FindSelfPattern` (upstream function.cpp:29-46 at
0421bf3b4) does not look through the `DefaultValuePattern`, so the function is
not a method, its plain call `c.M()` binds no receiver and `self` takes its
default (r01: 1, 1 on trunk and the nightly). The set reads the same
`self_param_id`, so it treats such a member as a member without `self`, exactly
as the plain call does: gate (x) groups it with selfless members, and `C.M()`,
`C.M(4)`, `c.M()` and `C.M(true)` print 1, 4, 1, -1 against
`M(self: i32 = 1)` then `M(b: bool)` (r02); beside a member with `self` it is
gate (x)'s "members that disagree on `self`" TODO (r02b). The split
`defaulted_self_is_not_a_receiver` pins the plain and the set calls (amended
2026-10-28, review fold: RR1-m1; rev 2 said "`self` included only when it
carries a default, which no probe could declare (p13e)", which is false: p13e's
`self` is refused for its list, not for its default). _Break condition:_
upstream's `FindSelfPattern` comes to look through a default, so that a
defaulted `self` is a receiver or an error; the receiver's alignment and the
split are then re-read.

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

**D-OV4-11 — template-dependent calls and members of template classes.**
Since UA-1 a call with a template-dependent argument is deferred as a
`CallAction` and resolved for each specific (fail_todo_gates.carbon's
`template_dependent`), where the arguments are concrete and the rule above
applies (p16: member 0, exit 1; the lower split `template_dependent_default`
pins `T(i32)` calling member 0 with the default `2` and `T(bool)` calling
member 1, amended 2026-10-28, review fold: B-m5); gate (xi) stays for a call
that is not deferred. A member of a template class whose default (or
parameter type) is template-dependent is substituted when resolution reaches
it, in declaration order, and a substitution failure is an error, not a
skipped candidate: upstream's p002200:214-217 at 0421bf3b4, "Substitution
failure is an error. In C++, the SFINAE rule will skip functions in overload
resolution that fail to instantiate. Instead, Carbon template parameters use
constraints to control when the function is available.", and README.md
:2828-2832. So `Box(bool).Get()` against `Get(y: T = 0)` then `Get()` is
diagnosed at member 0, exactly as the plain call of member 0 alone (a09b, with
the argument supplied f01), and `Box2(bool).Get()` against `Get()` then `Get(y:
T = 0)` selects member 0 without substituting member 1 (f05); the split
`fail_template_default_specific` pins both (amended 2026-10-28, review fold:
A-M1; §7.2 records the rejected fall-through). The rule predates OV-4: a
member whose template-dependent parameter type fails in the specific is
diagnosed the same way on trunk (f03). PR 61's and PR 64's toolchains print the
same lines for every one of these probes, alone and merged with OV-4 (m61,
m64, §8.7). _Break condition:_ PR 61's or a later change resolves a dependent
call before substitution, which would then reach the arity step with
dependent arguments; or upstream adopts SFINAE for overload resolution, and
the member is then rejected silently.

**D-OV4-12 — what a default may be.** Upstream's toolchain requires a constant
(handle_pattern_list.cpp:185 at e6fddcf97, "default value is not a constant");
`1 + 1` is a constant (p11: 12), a file-scope `let K` and an earlier parameter
`x` are not (p11b, p11c, on every toolchain). Upstream's design text says
nothing about what a default may be (§0.2: its two examples use literals), so
OV-4 stops at the toolchain's rule and adds none. _Break
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

**D-OV4-14 — goldens and programs.** Golden sources: one check file with 18
splits (Appendix A.1, rev 2 adding `fail_template_default_specific` and
respelling `fail_redecl_default_differs` and `fail_default_not_trailing`, rev 3
adding `defaulted_self_is_not_a_receiver` and `fail_default_not_trailing`'s
`R`; amended 2026-10-28, review fold: RR1-m1 / RR1-m2), the
export check file with 3 splits (A.2), a lower file with 3 splits (A.3, rev 2
adding `template_dependent_default`) and the export lower twin (A.4); CHECK
lines by autoupdate only (R16) (amended 2026-10-28, review fold: A-M1, A-m3,
B-m5). Programs: `functions/overloading_default_values.carbon` with a
hand-derived EXPECT (B.1) and the DIFF-1 pair
`functions/overloading_default_values_diff.carbon` and `.diff.cpp` (B.2, B.3),
whose calls are the ones where C++'s best viable match agrees with first match;
the both-accept call is not in the pair, because C++ rejects `Pick(5)` against
`Pick(int, int = 2)` and `Pick(int)` as ambiguous, and B.1 pins Carbon's
selection instead. _Break condition:_ a review finds an EXPECT line not
derivable from §1's rule and the prelude, which is then re-derived, never
re-run.

**D-OV4-15 — docs and records (R32).** docs/design/functions_overloading.md
is rewritten in place where its text is false and amended where it is
incomplete (amended 2026-10-28, review fold: B-M4; rev 1 inserted amendments
beside the false sentences, which W-341's notes, "functions_overloading.md
:570-576 and :1022-1023 are rewritten", do not allow): the match test's CLOSED
paragraph (:570-576), the F-009j item (:1022-1023) and the arity step's
parenthesis (:543-545) are rewritten, each with a dated parenthesis quoting the
2026-09-27 text it supersedes, as the page's OPEN paragraphs became dated
CLOSED ones in place (Appendix C.1 to C.3); the 0.1 limits item (iii) and the
D-OV-3 CLOSED paragraph each gain one dated sentence, which supersedes nothing
(C.4, C.5). C.1 names upstream's positional default values with the design
text and the toolchain text of §0.2 quoted at 0421bf3b4 (amended 2026-10-28,
review fold: A-m1 / B-M1). fork/overload/plan.md is history: :380 and :2173
get dated notes, not rewrites (C.6). Records (Appendix D, all in commit D,
after the reviews and their fixes; amended 2026-10-28, review fold: B-M5):
W-341 DISCHARGED (kind `implemented`, title prefixed "OV-4 (DISCHARGED at
OV-4, <date>)"); W-360, W-361 and W-362 filed; W-363 and W-364 unused; the
decision-log entry "OV-4" with D-OV4-1 to D-OV4-17, the V-3 check by sha and
the register lines, placed with OV-1 to OV-3 (B-m4); the weekly entry's W-341
paragraph a dated "resolved by OV-4" note; the gap row stays DONE with its
evidence refreshed; ORCHESTRATION's header, a dated paragraph, a Branches row
and its Next actions item 6. The register entries in RG-1's vocabulary (§0.8):
T2.8, F-009j, **ALIGNED**; T2.9, the plain-call rule, **NONE**, watched by
W-355; the tie-break stays T2.6's ALIGNED first match (amended 2026-10-28,
review fold: A-m2 / B-m1). Their two table rows, two silence checks and sixteen
quote rows (Appendix D.6) are added to PR 67's fork/register/rg1-plan.md
(§2.T2's table, after T2.7's row), rg1-checks.tsv and rg1-quotes.tsv only at
land time, after PR 67 lands (commit L-R), so that each TSV row names a
section 2 entry, as the TSVs' header says, and W-355's owner re-reads the two
break conditions where every other entry's is (amended 2026-10-28, review
fold: RR1-m4 / RR1-m3; rev 2 named the table rows but no commit wrote them, and
had fifteen quotes, without function.cpp:677's trailing-default rule). Named
optional parameters stay where upstream leaves them, an open question in
classes.md, with no fork spelling. _Break condition:_ RG-1's vocabulary or
table formats change before land time; L-R then follows the landed format.

**D-OV4-16 — merge position and the held state.** One PR, base trunk,
merging after PR 66 (ORCHESTRATION item 6) and before EH-C (W-346, the other
R32 item item 6 schedules "after the held PRs land and before UA-3", "on
trunk's base, beside W-341"), held open like the seventeen before it while
GitHub Actions is disabled (amended 2026-10-28, review fold: B-m2). OV-4 goes
first because its plan exists and EH-C's does not; if EH-C is ready first,
either order is allowed, because the two share no toolchain, prelude, golden or
program file (EH-C renames `Core.Result`'s alternatives in core/prelude and the
goldens and programs that spell them; OV-4's goldens dump only their own
ranges and spell no `Result`), and whichever lands second merges the other's
records by §6.2's region rules, its ledger items in id order (W-360 to W-362
after EH-C's own). No held PR carries the drift, so none is amended (R32 (e)):
a `git grep` of the seventeen held heads for "no default arg", "has no default
arg", "no Carbon-native default" and "default-argument design" finds only
trunk's own three statements (functions_overloading.md, fork/overload/plan.md
and call.cpp's comment), which OV-4 rewrites or notes, and PR 59's call.cpp
keeps the exact range. At land time OV-4's branch merges the trunk that then
holds PR 51 to PR 67 (commit M), resolving handle_function.cpp against PR 59
and PR 66, merge.cpp against PR 60 and the records region by region (§6.2),
refills what the merged branches change (F-M), adds the register rows (L-R) and
re-quotes the gate and conformance (L), each with the message and texts of §3.
_Break condition:_ the land sequence changes order so that OV-4 lands before PR
59, PR 60 or PR 66; the same rules then apply on their side, by their own merge
commits.

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
    pattern_match.cpp:1275, or at :1805 when the omitted parameter is a tuple
    pattern (amended 2026-10-28, review fold: RR1-m2); fixed by D-OV4-5 in
    handle_function.cpp's `CheckDefaults` (the trailing count; amended
    2026-10-28, review fold: A-m3), which upstream moved to function.cpp
    (1b0a5709e). UA-3 carries the fix into function.cpp, or drops it if
    upstream fixed the crash another way, and reports both crash sites
    upstream if the tip still has them. Break condition: D-OV4-5's.
-   W-363 and W-364: reserved, unused unless a review files a residue.

## §2 Spec, file by file

Every C++ hunk below is rev 2's prototype's, built and measured (§0.5),
formatted by clang-format 21.1.8 and clean under both clang-tidy passes;
§2.1 and §2.3 are rev 1's unchanged, §2.2's third hunk is rev 2's. Line numbers
are trunk 66bd2ba90's on the `-` side and the prototype's on the `+` side.
The diffs are reviewed diffs, written by C1 as given; a review that changes
one changes this section by a dated amendment first. The repository's
trailing-whitespace hook strips the leading space of each blank context line
inside these blocks, so they are for reading; `$X/r2/proto-toolchain.diff` is
the same diff in a form `git apply` takes.

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
`param_pattern_id` for the TODO's location (D-OV4-3). (3) `CheckDefaults`
keeps a `trailing_default_count` per level beside upstream's `default_count`,
reset by every pattern without a default, and a level that diagnosed a missing
default returns it in place of `default_count` (D-OV4-5); `state` is that
level (`level_state_stack.back()`), as the diagnostic block above it already
assumes. The new field and the changed return each carry `Fork (OV-4,
W-362)`, the marker UA-3's merge into upstream's function.cpp looks for, and
the three-line update between them names that field (amended
2026-10-28, review fold: A-m3 / B-m5; rev 1 returned 0 for such a level and
carried no marker).

<!-- google-doc-style-ignore -->

```diff
diff --git a/toolchain/check/handle_function.cpp b/toolchain/check/handle_function.cpp
index 91c3fdd4e..11269535b 100644
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
@@ -948,6 +955,10 @@ static auto CheckDefaults(Context& context, SemIR::Function& function)

     // A count of the number of patterns on this level that have defaults.
     int32_t default_count = 0;
+
+    // Fork (OV-4, W-362): a count of the patterns at the end of this level
+    // that have defaults, after its last pattern without one.
+    int32_t trailing_default_count = 0;
   };

   llvm::SmallVector<PatternLevelState> level_state_stack;
@@ -1005,6 +1016,9 @@ static auto CheckDefaults(Context& context, SemIR::Function& function)
       }
       // Finished processing this subpattern, detect a missing default if
       // required.
+      state->trailing_default_count = state->current_pattern_has_default
+                                          ? state->trailing_default_count + 1
+                                          : 0;
       if (state->current_pattern_has_default &&
           !state->first_pattern_with_default.has_value()) {
         state->first_pattern_with_default = state->current_id;
@@ -1036,8 +1050,13 @@ static auto CheckDefaults(Context& context, SemIR::Function& function)
     }

     // Extract the count from the level we just completed, overwriting any
-    // nested level value extracted previously.
-    default_count = level_state_stack.back().default_count;
+    // nested level value extracted previously. Fork (OV-4, W-362): a level
+    // with a diagnosed missing default counts only its trailing defaults, so
+    // that a caller's arity check never admits a call that omits an argument
+    // for a parameter with no default value.
+    default_count = state->patterns_missing_defaults.empty()
+                        ? state->default_count
+                        : state->trailing_default_count;
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
writing passes and a third that changes nothing, R26, measured on rev 1 and rev
2), and nothing else: no existing golden moves (measured, 1942 of 1942 pass on
the prototype before the four files are added). File names and splits
(amended 2026-10-28, review fold: A-M1 / A-m3 / B-m5 / RR1-m1 / RR1-m2):

-   toolchain/check/testdata/function/overload/default_values.carbon:
    `omitted_and_supplied`, `all_defaulted`, `first_member_needs_default`,
    `exact_member_first`, `method_default`, `defaulted_self_is_not_a_receiver`
    (rev 3: the plain and the set call of a defaulted `self`, D-OV4-8),
    `generic_class_member_default`, `template_dependent_default`,
    `redecl_same_default`,
    `fail_redecl_default_differs` (rev 2: the design page's two pairs in its
    own spelling, R27, and the forward-declared `H`),
    `fail_too_few`, `fail_supplied_argument_rejected`,
    `fail_default_not_trailing` (rev 2: `Q(5, 6)` accepted and `Q(5)`
    rejected beside rev 1's `F(5)` and `P(5)`; rev 3: `R((1, 2))` rejected,
    its unmatched parameter a tuple pattern), `fail_todo_non_value_default`,
    `fail_template_default_specific` (rev 2: a template class's member whose
    default fails in `Box(bool)`, and the reversed order that never
    substitutes it), `fail_todo_generic_member_default`, `import_lib` and
    `import_use` (eighteen splits).
-   The export check file
    (toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon):
    `supplied`, `divergence_omitted`, `fail_cpp_omitted`.
-   toolchain/lower/testdata/function/overload/default_values.carbon:
    `omitted_and_supplied`, `class_default`, `template_dependent_default`
    (rev 2: the deferred call in `T(i32)` and `T(bool)`, lowered).
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

docs/design/functions_overloading.md: the three in-place rewrites and two
dated sentences of Appendix C.1 to C.5, and fork/overload/plan.md's two dated
notes, Appendix C.6 (amended 2026-10-28, review fold: B-M4). A rewrite replaces
the false text and quotes it, dated, inside the new paragraph, the way the
page's own OPEN paragraphs became dated CLOSED ones in place and PR 63's
loops.md change replaced its superseded lines; a dated sentence is inserted
where the existing text stays true.

### §2.7 Records (D, L-R, L)

Appendix D, verbatim but for their `<...>` fields: D.1 the ledger (W-341
discharged, W-360 to W-362), D.2 the decision-log entry "OV-4", D.3 the weekly
entry's note, D.4 the gap row's evidence cell and D.5 ORCHESTRATION, all in
commit D after the reviews and their fixes; D.6 the register rows (L-R, land
time); D.7 the land-time texts of M and L (amended 2026-10-28, review fold:
B-M3 / B-M5; rev 1 put the row and ORCHESTRATION in a commit R before the
reviews).

## §3 Commits (one PR, "OV-4: `overload fn` members with default parameter values (W-341)", R29 (b))

**D-OV4-17 — the commit sequence.** Every commit is authored `jmann345
<jerrymannstan@gmail.com>` with `GIT_COMMITTER_NAME=Claude
GIT_COMMITTER_EMAIL=noreply@anthropic.com`, adds explicit paths only (R20),
and ends its message, after a blank line, with the session's attribution
trailers. Nothing is pushed until the implementation workflow says so, and the
PR is opened held, base trunk. Rev 1's commit R is gone: the gap row and
ORCHESTRATION move into D, after the reviews, so no record claims the
discharge before the ledger does (amended 2026-10-28, review fold: B-M5 /
B-m4).

1.  **Plan**: fork/overload/ov4-plan.md, rev 1 (fdaed06ae), rev 2 (7fda41b11)
    and this rev 3, the signed-off one (amended 2026-10-28, review fold: RR1).
    Later plan revisions are commits on the same file, each a fold record.
2.  **C1, the toolchain change with its golden sources**: §2.1 to §2.3 and
    Appendix A's four files without CHECK lines, after re-fetching upstream
    and naming the tip in the message's body (rev 2 read 0421bf3b4; amended
    2026-10-28, review fold: B-m5). Gate on C1 alone: red on exactly those
    four files ("Autoupdate would make changes"), no crash, 1942 of the other
    1942 pass (measured shape: the prototype passes 1942 of 1942 before the
    four files exist). Message: "OV-4 (1/3): overload set members with
    default values: the arity range, the probe over the supplied arguments,
    gate (iii), member identity and the trailing default count".
3.  **F1, its fill**: the autoupdate output of the four files at its fixpoint
    (R26); nothing else may change. Message: "OV-4 (2/3): fill C1's goldens
    (autoupdate)".
4.  **P, the programs and docs**: Appendix B's three files, the README table's
    two rows (§2.5), Appendix C's rewrites and amendments of
    docs/design/functions_overloading.md and the dated notes in
    fork/overload/plan.md. `runner.py --self-test` before the commit: "152
    programs parsed, 56 bullets in table, OK". Message: "OV-4 (3/3):
    programs, the overloading page rewritten for upstream's default values,
    and the OV-1 plan's dated notes".
5.  **Two implementation reviews** (R11: separate agents; R29 (c): two until
    the hosted-equivalent verification is green, then one), against C1 to P,
    with the mall rehearsal of §8.7 measured before they start.
6.  **Fix commits, at most three**, each with its own fill when it changes
    goldens (the fill is not counted). A records-only commit that changes no
    toolchain, golden or program file is not a fix commit.
7.  **D, the records**: the ledger (D.1: W-341 DISCHARGED, W-360 to W-362
    filed), the decision-log entry OV-4 (D.2), the weekly entry's note (D.3),
    the gap row's evidence (D.4) and ORCHESTRATION (D.5), every `<...>` field
    filled from the commits and runs it names, after the reviews and their
    fixes. Message: "OV-4 records: W-341 DISCHARGED; W-360 to W-362 filed;
    decision-log entry OV-4; gap row evidence and ORCHESTRATION".
8.  **The focused re-review** (amended 2026-10-28, review fold: B-m3): one
    fresh agent per round reviews the fix commits and D against the two
    implementation reviews' findings, this plan and the records' cites (every
    `<...>` filled, every sha and figure re-read from its run). A round is dry
    when it finds no BLOCKER and no MAJOR and its MINORs, if any, change no
    toolchain, golden or program file; those MINORs are folded by one records
    commit without a further round. A round that is not dry gets a fixer and
    another round, at most three rounds; a fourth would be a plan revision.
    The PR is opened held after a dry round.

**No shrink line** (amended 2026-10-28, review fold: B-M2; rev 1's two steps,
a semantics TODO for defaulted members of generic classes and the omission of
defaulted members from export, would each have gated an IN form the plain path
supports, which §7.2 itself rejects under R17). When the fix budget is spent
and a review still finds a defect that needs a toolchain, golden or program
change, OV-4 stops at a plan revision (rev 3) that re-plans the defect at its
root, as VA-2's D-VA2-19 break condition did. The core (the arity range, the
probe, gate (iii)'s look-through, identity and the default count) is W-341
itself and has no smaller form; the generic members and the export are already
residues of upstream code that has not arrived (W-360, W-361), not slices to
cut. _Break condition:_ a commit cannot build without a later commit's files,
which merges the two and is recorded in the landed notes; a defect a review
finds in a commit is fixed at its root in a fix commit, never by a guard
(R17).

**The land-time commits**, specified now and made when the land sequence
reaches OV-4, after PR 66 and with PR 67 landed first (amended 2026-10-28,
review fold: B-M3; rev 1 gave no messages or texts):

1.  **M**: `git merge --no-ff` of the trunk that then holds PR 51 to PR 67
    into OV-4's branch, conflicts resolved by §6.2's rules, region by region,
    with SC-1's two arguments added to the two calls in
    `CheckOverloadMemberParamsMatch` (a semantic change the textual merge does
    not show). Never a rebase (AGENTS.md). Message: the block after this
    list, verbatim but for `<...>`.
2.  **F-M**: the refills the merged branches cause in OV-4's four goldens, by
    autoupdate to its fixpoint, and nothing else; the m66, m64 and m61
    mirrors (§8.7, measured: none) and m60 and mall (to be measured) predict
    it. Message: "OV-4 land (F-M): refill OV-4's goldens on the merged branch
    (autoupdate)", its body naming each refilled file. If autoupdate changes
    nothing, there is no F-M commit, and L says so.
3.  **L-R**: the register entries of Appendix D.6: its two table rows
    inserted into fork/register/rg1-plan.md's §2.T2 table directly after
    T2.7's row, and its checks and quotes appended to PR 67's
    fork/register/rg1-checks.tsv and rg1-quotes.tsv, after re-fetching
    upstream and checking them with PR 67's check_greps.sh and
    check_quotes.sh at that tip (each count and quote re-read; a moved count
    is a weekly-check finding, not an edit), with prek and rg1-plan.md's R31
    counts before and after (two table rows more, nothing else; amended
    2026-10-28, review fold: RR1-m4). Message: "OV-4 land (L-R): register rows
    T2.8 and T2.9 in fork/register/rg1-plan.md, rg1-checks.tsv and
    rg1-quotes.tsv", its body: "Checked at upstream <tip>: <n> silence checks
    and <m> quotes, 0 failed (fork/overload/ov4-plan.md Appendix D.6)."
4.  **L**: §8.1 to §8.4 re-run on the branch's head after M, F-M and L-R, the
    gate and conformance figures quoted into the ledger, the decision log and
    ORCHESTRATION by the texts of Appendix D.7, EXPECTED, not of record, as
    every land-time record is while Actions is disabled. Message: "OV-4 land
    (L): the merged branch re-verified; W-341's landing recorded".

M's message, verbatim but for `<...>`:

<!-- google-doc-style-ignore -->

```text
OV-4 land (M): merge trunk <trunk> into claude/carbon-fork-0-1-ov4

Trunk <trunk> holds PR 51 to PR 67. Resolved by fork/overload/ov4-plan.md
section 6.2: toolchain/check/handle_function.cpp keeps VA-1's pack gate
before OV-4's default look-through (PR 59, PR 66);
toolchain/check/merge.cpp takes SC-1's argument list, and OV-4's
CheckOverloadMemberParamsMatch passes SemIR::SpecificId::None and nullptr
for SC-1's two new parameters (PR 60); ORCHESTRATION's header, dated
paragraphs, Branches table and item 6 and the ledger's tail keep both
sides by the section's region rules. No golden is edited by hand; F-M
refills.
```

<!-- google-doc-style-resume -->

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

Each row's prediction is hand-traced from §1 before the build; the measured
column is rev 3's fill (`$F/r3/saved/<path>`, line numbers in the filled file;
amended 2026-10-28, review fold: A-M1 / A-m3 / B-m5, the rows marked "rev 2"
new or changed, and RR1-m1 / RR1-m2, the rows marked "rev 3" new or changed,
every line number of the check file re-read because the new split and `R`
move its diagnostics and dumps; the other three files' fills are rev 2's,
byte for byte). Every row matched; nothing was predicted differently and
corrected.

_toolchain/check/testdata/function/overload/default_values.carbon:_

| split | predicted | measured |
| --- | --- | --- |
| omitted_and_supplied | member 0 takes `Scale(1)` with the default `10` filled from the declaration's converted default; `Scale(2, 3)` both supplied; no diagnostic | :606 `call %Scale.ref.loc10_33(%.loc10_32.2, @Scale.loc5.%.loc5_41.2)`, :625 `(%.loc10_43.2, %.loc10_46.2)`; the declaration's `default_value_pattern %factor.patt, %int_10.6bf` at :453 |
| all_defaulted | `Count()` fills both, `Count(5)` fills `b`, `Count(5, 6)` none, `Count(true)` member 1 | :713 both `@Count.loc4.%...` values, :724 one, :752 none, :765 `call %Count.ref.loc11_71(%true)` |
| first_member_needs_default | `Pick(5)` member 0 with the default; `Pick(5, 6)` member 0 | :858 `(%.loc11_31.2, @Pick.loc7.%.loc7_49.2)`, :877 two supplied |
| exact_member_first | `Pick(5)` member 0 with one argument; `Pick(5, 6)` member 1 | :972 one argument, :991 two |
| method_default | `c.Plus()` and `Counter.Plus(c)` fill `n`; `c.Plus(5)` and `Counter.Plus(c, 7)` supply it; receivers as D-OV-4 binds them | :1088 and :1116 with `@Counter.Plus.loc9.%.loc9_35.2`, :1102 and :1138 supplied |
| defaulted_self_is_not_a_receiver (rev 3) | `c.P()` binds no receiver and passes `P`'s default for `self`; `C.M()` and `c.M()` select member 0 with its default and no receiver; `C.M(4)` member 0 with `4`; `C.M(true)` member 1; no diagnostic | :1233 `call %P.ref(@C.P.%.loc9_20.2)`; :1237 `call %M.ref.loc16_22(@C.M.loc10.%.loc10_29.2)` and :1271 `call %M.ref.loc16_39(@C.M.loc10.%.loc10_29.2)`; :1258 `(%.loc16_30.2)`; :1284 `@C.%C.M.decl.loc11` and :1285 `(%true)`; no STDERR |
| generic_class_member_default | `Box(bool).Get()` fills `y` in the specific; `Get(9)` supplies | :1376 `call %Box.Get.specific_fn.loc13_40(@Box.Get.loc8.%.loc8_28.2)`, :1393 |
| template_dependent_default | both specifics check; no diagnostic (the per-specific selection is pinned by the lower split of the same name) | :1484 and :1489, no STDERR |
| redecl_same_default | one member; `F(1)` fills from the definition's default | :1564 `(%.loc10_28.2, @F.loc7.%.loc7_32.2)` |
| fail_redecl_default_differs (rev 2) | three `RedeclParamDiffers` with `RedeclParamPrevious`, at parameter 2 of the second `F`, `G` and `H`, the `F` and `G` pairs spelled as C.5 spells them | :171/:174, :181/:184, :191/:194 |
| fail_too_few | `OverloadNoMatch`, two arity notes | :209, :212, :215 |
| fail_supplied_argument_rejected | `OverloadNoMatch`; member 0 conversion note, member 1 arity note | :230, :233, :236 |
| fail_default_not_trailing (rev 2, rev 3) | four `RequiredPatternDefaultValueMissing` (`F`, `P`, `Q`, `R`) with their first-default notes; `F(5)` `OverloadNoMatch` with an arity note (member 0) and a conversion note (member 1); `P(5)` "1 argument passed to function expecting 2 arguments"; `Q(5, 6)` accepted; `Q(5)` and `R((1, 2))` "1 argument passed to function expecting 3 arguments"; no crash | :252/:255, :262/:265, :271/:274, :280/:283, :289/:292/:295, :299/:302, :306/:309, :313/:316 (`R((1, 2))` at column 57); nothing at `Q(5, 6)`'s column 40 |
| fail_todo_non_value_default | two gate (iii) TODOs, at `var y: i32 = 2` and at the defaulted tuple pattern | :329, :334 |
| fail_template_default_specific (rev 2) | one "unable to monomorphize specific `Get(bool)`" at `Box(bool).Get()`, with the notes "cannot implicitly convert expression of type `Core.IntLiteral` to `bool`" and the missing `ImplicitAs` impl at the default; nothing for `Box(i32).Get()`, `Box2(bool).Get()` or `Box2(i32).Get(5)` | :363, :366, :369 (no other STDERR) |
| fail_todo_generic_member_default | `G(true, 5)` selects; `G(true)` `OverloadNoMatch` with the deduction note; `P(true)` `DeductionIncomplete` with `DeductionGenericHere` | :389/:392, :396/:399 |
| import_lib, import_use | `F(1)` fills the imported default as the constant `2`; `F(1, 5)` supplies | :1651 `(%.loc9_28.2, constants.%int_2)`, :1670 |

_toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon:_
`supplied` and `divergence_omitted` check with no diagnostic, Carbon's `F(1)`
filling the default (:178, :284); `fail_cpp_omitted` gets Clang's "no matching
function for call to 'F'" with two "candidate function not viable: requires 2
arguments, but 1 was provided" notes (:75, :78, :81).

_toolchain/lower/testdata/function/overload/default_values.carbon:_ `Scale(1)`
lowers to `call i32 @"_CScale:overload0.Main"(i32 1, i32 10)` (:73) beside
`(i32 2, i32 3)` (:74); the class-typed default is passed as the constant
`@C.val.a26.loc7_35.9` (:158) beside two materialized temporaries (:163); rev
2's `template_dependent_default` lowers `T(i32)`'s deferred call to `call i32
@"_CF:overload0.Main"(i32 %u, i32 2)` (:314), the default filled, and
`T(bool)`'s to `call i32 @"_CF:overload1.Main"(i1 %u)` (:321).

_toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon:_
Carbon's `F(1)` is `call i32 @"_CF:overload0.Main"(i32 1, i32 2)` (:83); C++'s
`CallOne` calls `@"_CF__carbon_thunk:overload1.Main"` (:162), the `F(bool)`
member's thunk: the divergence R30 asks to assert.

## §5 Conformance delta (from trunk's 128 PASS / 0 FAIL / 22 SKIP over 150, re-measured)

| | PASS | COMPILE-FAIL | others | SKIP | total | bullets PASS/FAIL/SKIP/NOT-WRITTEN |
| --- | --- | --- | --- | --- | --- | --- |
| trunk 66bd2ba90, re-measured (§0.1) | 128 | 0 | 0 | 22 | 150 | 48/0/8/0 |
| the two new programs on trunk | 0 | 2 | 0 | 0 | 2 | the overloading bullet would FAIL |
| prototype (§0.5; rev 1 and rev 2 alike) | 130 | 0 | 0 | 22 | 152 | 48/0/8/0; the overloading bullet PASS with 9 programs |

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
both are UA-3's refills. Rev 2 adds no existing-golden churn: its new split
and lower split are inside OV-4's own files (amended 2026-10-28, review fold:
A-M1 / B-m5); nor does rev 3, whose split and call are in the same check file
(amended 2026-10-28, review fold: RR1-m1 / RR1-m2).

### §6.2 Collisions with the held PRs and the merge rules

| PR | collision with OV-4 (§0.6) | merge rule at M |
| --- | --- | --- |
| 51 UA-2 | functions_overloading.md: PR 51 rewrites 0.1 limits item (xi) and adds a paragraph to "Calls from template code"; OV-4 rewrites the match test's CLOSED paragraph, the arity step's parenthesis and F-009j, and amends item (iii) and D-OV-3's paragraph (merge-tree with P: clean) | textual, disjoint hunks; keep both. README rows: regenerate with `--update-readme-table` |
| 59 VA-1, 66 VA-2 | handle_function.cpp, gate (iii)'s loop (textual conflict); `CheckDefaults` (VA-1 adds a `PackExpansionPattern` case; disjoint from the trailing count, merges cleanly) | VA-1's pack gate first, on the parameter as declared, then OV-4's look-through (m66's resolution, §8.7); call.cpp and deduce.cpp merge cleanly; a defaulted pack stays gated by VA-1 (W-215, W-223; a12 on m66 prints VA-1's TODO) |
| 60 SC-1 | merge.cpp `CheckRedeclExplicitParamsAfterSelfMatch` (textual); SC-1's two new parameters of `CheckRedeclParams` and `CheckRedeclParamLists` (semantic) | take SC-1's argument list in the conflict and add `/*new_specific_id=*/SemIR::SpecificId::None, /*found_error=*/nullptr` to OV-4's two calls in `CheckOverloadMemberParamsMatch`; OV-4's identity keeps SC-1's errors-match mode off (`found_error` null), as SC-1's own call there does |
| 61 TP-1, 64 CT-1 | call.cpp, clean | none; m61 and m64 measured: no refill, every probe unchanged (§8.7) |
| 65 DR-1b | call.cpp return storage, clean | none |
| 67 RG-1 and every other head | records only: the five regions of §0.6 | the region rules below |

The records rules, one per region of §0.6's table (amended 2026-10-28, review
fold: B-M3; rev 1's "keeping both sides' entries in id and date order" could
not resolve a sentence both sides replace). M merges the landed trunk, so each
region has one landed version, made by the land-sequence commits of PR 51 to
PR 67 (PR 67's first):

1.  ORCHESTRATION's "Last updated:" header: take the landed trunk's header
    whole and put OV-4's sentence (D.5) in front of it, ending "the earlier
    <date> text follows", as every stamp prepends; never merge two headers'
    sentences.
2.  The dated paragraphs: take every landed paragraph unchanged and put
    OV-4's dated paragraph (D.5) after the last of them, so the dated
    paragraphs stay in time order.
3.  The Branches table: take every landed row unchanged (RG-1's then reads
    as landed) and keep OV-4's row (D.5) directly after RG-1's.
4.  Next actions item 6: take the landed item whole, then re-apply OV-4's one
    edit to it: the sentence that schedules W-341 (whatever its landed
    wording) is replaced by D.5's first sentence, and every other sentence is
    the landed item's. If the land sequence has already removed the W-341
    sentence, D.5's sentence is inserted at the item's start.
5.  The ledger's tail: keep both sides' appended items, in id order (PR 67's
    W-346 to W-356, then any later landed ids below W-360, then OV-4's W-360
    to W-362); the JSON stays one array, and prettier's format is re-checked
    by prek.
6.  fork/decision-log.md, fork/gap-analysis.md, the overloading page and
    fork/overload/plan.md (no conflict measured): if a later landed commit
    makes one, keep both; OV-4's entry stays directly above OV-3's heading, its
    weekly note directly after the paragraph that ends "or removes positional
    defaults.", and each gap-row edit at its anchor of D.4.
7.  The register's table and TSVs (fork/register/rg1-plan.md §2.T2,
    rg1-checks.tsv and rg1-quotes.tsv): OV-4's branch does not touch them
    before L-R, which adds its rows after M, so they cannot conflict at M
    (amended 2026-10-28, review fold: RR1-m4).
8.  EH-C (W-346): whichever of OV-4 and EH-C lands second applies rules 1 to
    6 to the other's records in the same way (D-OV4-16).

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1: the probe accepts and the commit rejects** (D-OV-4's R-1 class).
    Falsifier: a call within a member's range whose supplied arguments convert
    in the probe but whose commit diagnoses something the probe did not. The
    commit's only extra work for a defaulted member is the fill, and the fill
    reads a default the declaration converted: once for a non-dependent type,
    and, for a template-dependent type, in the member's specific, which
    deduction's `MakeSpecific` forms inside the probe before any argument is
    converted (amended 2026-10-28, review fold: A-M1; rev 1 said "no such call
    exists unless a default's type differs per specific" and called p09 that
    case). So a default that fails in a specific is diagnosed by the probe's
    own deduction, as the plain call's is, and the commit adds nothing: a09c,
    f01 and f04 print one diagnostic each, the plain call's (§0.3). What that
    leaves is a member that resolution diagnoses rather than skips, which is
    upstream's rule (D-OV4-11), not a probe/commit divergence; the
    generic-class split and p09 pass for a default that converts.
-   **R-2: identity changes an existing set.** Falsifier: a trunk golden or
    program whose members differed only in a default before OV-4. None can
    exist: every such member was gated by (iii) (measured, no existing
    golden changes).
-   **R-3: the default count change alters a plain call that worked.**
    Falsifier: a declaration with a diagnosed missing default whose call used
    to pass and now fails. The trailing count admits exactly the calls whose
    omitted arguments all have defaults, which are the calls that passed on
    trunk without crashing (a10's `P(5, 6)` passes on trunk and on rev 2, and
    `fail_default_not_trailing`'s `Q(5, 6)` pins it); a call that crashed
    now gets `CallArgCountMismatch` or the arity note. The declaration is an
    error either way (amended 2026-10-28, review fold: A-m3; rev 1's count of
    0 falsified this risk, mutant M5b).
-   **R-4: PR 66's deduction changes D-OV4-7.** Falsifier: m66's p07 or p20
    selecting a generic member with a default omitted. Measured on m66 twice
    (the planner's on rev 1, the fixer's on rev 2, §8.7): unchanged.
-   **R-5: the land-time records merge loses a sentence** (amended
    2026-10-28, review fold: B-M3). Falsifier: after M, a landed
    ORCHESTRATION paragraph, Branches row or item 6 sentence, or a ledger item,
    missing or duplicated. §6.2's region rules take each landed region whole
    and re-apply OV-4's edit to it; L's re-read of the four ORCHESTRATION
    regions and `python3 -I` JSON validation of the ledger check it.

### §7.2 Rejected alternatives

-   **A second probe path for defaulted members** (probe the defaults too, or
    a separate loop for short calls). Rejected: a default converts when the
    declaration, or the member's specific, is formed, before the probe converts
    anything (D-OV4-2); the commit already fills it; and a second path is the
    divergence D-OV-4's single loop exists to prevent (R17). Falsifier: a
    default whose conversion can fail at a call after its specific is formed,
    which upstream does not allow (D-OV4-12).
-   **Skipping a member whose specific fails to substitute** (review A's
    A-M1 fix: reject a member when its default's value is an error in the
    probe's specific; amended 2026-10-28, review fold: A-M1). Rejected on
    upstream's design and on measurement. Design: it is the SFINAE rule
    upstream rejects, p002200:214-217 "Substitution failure is an error. In
    C++, the SFINAE rule will skip functions in overload resolution that fail
    to instantiate. Instead, Carbon template parameters use constraints to
    control when the function is available." and README.md:2828-2832, so it
    would be a fork mechanism against an accepted design (R32 (d)), and it
    would treat a template-dependent default unlike a template-dependent
    parameter type, which trunk already diagnoses the same way (f03).
    Measurement: the check, built (§0.5), leaves a09c's diagnostic in place,
    because `ResolveSpecificDecl` emits it inside deduction's `MakeSpecific`
    before any member-level check runs; making it silent would need the
    suppressed-emitter probe of W-028 and W-104, a subsystem outside W-341.
    Its shrink-line variant (a semantics TODO for a member whose default is
    template-dependent) is rejected with the TODO gate below: f06 shows such
    members work in every specific where the default converts. Falsifier:
    upstream adopts SFINAE for overload resolution.
-   **Counting no defaults for a level with a diagnosed missing default**
    (rev 1's D-OV4-5). Rejected: it also rejects calls that omit only
    trailing defaulted arguments, which trunk accepts (a10, review A's
    A-m3). Falsifier: none; the trailing count is the exact bound.
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
-   **A TODO gate on defaulted members** (keep them, or some of them, out of
    sets, as rev 1's shrink line would have for generic classes and export).
    Rejected: it hides an IN form the plain path already supports (R17), and
    it is the F-009j drift itself (amended 2026-10-28, review fold: B-M2).
-   **Changing `CheckRedeclParam` for `check_syntax` false.** Rejected:
    thunk.cpp's impl-against-interface comparison uses the same mode for
    upstream's meaning (D-OV4-4).
-   **Leaving the non-trailing-default crash to upstream.** Rejected: OV-4
    opens the set path to it (mutant M5), and the root is the count (R17);
    W-362 carries it to UA-3.
-   **Inserting the docs amendments beside the false sentences** (rev 1).
    Rejected: W-341's notes require the two ranges rewritten, and a page that
    states a fact and its opposite in adjacent paragraphs misleads its reader;
    the rewrite quotes the superseded text, dated, so the history stays
    visible (amended 2026-10-28, review fold: B-M4).

## §8 Verification and discharge

Every agent works under /dev/shm/ov4-<role>/ (builds, mirrors) and
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ov4/<role>/
(probes, logs, `XDG_CACHE_HOME`), checks `pgrep -fa 'ninja|file_test'` before a
full build, keeps at most one install, and deletes its builds when done. No
Bazel, no Actions, no runner (R28).

### §8.0 The planner's and the fixer's measurements (done)

The planner's: §0.1's baseline, §0.3's probes on five toolchains and the
nightly, rev 1's prototype and its mutants M1 to M5 and M6 and the 503f09037
scratch, §0.6's numstat and merge-trees, and the mirror m66 on rev 1. The
fixer's (amended 2026-10-28, review fold): rev 1's prototype rebuilt and its 38
probes re-run (equal), the 25 added probes on the same five toolchains and the
nightly, rev 2's prototype with its gate, conformance, clang-format, both
clang-tidy passes, the mutants M1 to M5, M5b and A-M1's alternative, the
merge-trees of the code-only tree and of the records tree against all
seventeen heads, the register rows at both tips, the id re-scan, and the
mirrors m66, m64 and m61 on rev 2. Every build, mirror and the prototype's
worktree under /dev/shm/ov4-fixer were deleted after this plan's commit; the
prototype's files are kept at `$X/r2/saved` and `$X/r2/proto-toolchain.diff`,
and its trees as the scratch commits 3ff06902f (code) and 59b65eb9c (records).
The rev-3 fixer's (amended 2026-10-28, review fold: RR1): the rev-2 prototype
rebuilt with rev 3's Appendix A sources, its fill, gate and conformance,
mutant M5, the five r probes on six toolchains and the prototype, and the
register rows at both tips (§0.1, §0.3, §0.5, §0.8); the build and the
worktree under /dev/shm/ov4-fixer1 were deleted before this plan's commit, no
install is kept, and the rev-3 fill is kept at `$F/r3/saved`.

### §8.1 Build (implementer)

<!-- google-doc-style-ignore -->

```sh
export CB_BUILD_ROOT=/dev/shm/ov4-impl/builds
CB=/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild
$CB/build.sh /home/user/carbon-ov4 && $CB/install.sh /home/user/carbon-ov4
```

<!-- google-doc-style-resume -->

on C1 (expected: 7 to 17 minutes cold, measured 7.0 by the fixer, the
incremental rebuild of one changed file about 10 seconds; no warning under
`-Werror`), then on every fix commit.

### §8.2 Autoupdate to its fixpoint

`$CB/autoupdate.sh /home/user/carbon-ov4 <the four files>` until a pass prints
four dots (measured on rev 2 and rev 3: the third pass, after two writing
passes, R26), then `git diff --stat` shows only the four files. A pass that
changes another file is a finding.

### §8.3 Gate

`$CB/gate.sh /home/user/carbon-ov4`: expected 1946 passed, 0 failed on F1;
1942 passed and exactly the four new files failed on C1 alone.

### §8.4 Conformance

`XDG_CACHE_HOME=<private> $CB/conformance.sh /home/user/carbon-ov4 <out>`:
expected PASS 130, SKIP 22, nothing else, of 152; bullets 48 PASS, 0 FAIL, 8
SKIP, 0 NOT-WRITTEN of 56; `python3 -I fork/conformance/runner.py --self-test`
"152 programs parsed, 56 bullets in table, OK".

### §8.5 Mutants

M1 to M5 and M5b of §0.5, each rebuilt incrementally and run on the four
goldens and the probes, each expected to fail as §0.5 measured on rev 2; plus
M6 for the programs: `Pick`'s and `Order`'s members each swapped in B.1,
expected OUTPUT-MISMATCH with lines 3 and 5 printing 2 and 1 (measured by the
planner on the prototype: `30 12 2 1 1 1 101 105 101 200 12 72 -1`), so B.1 is
not vacuous about first match. Seven mutants in all, six of the toolchain and
one of the programs (amended 2026-10-28, review fold: A-m4 / A-m3). The
implementer restores the tree after each and checks `git diff` is C1's.

### §8.6 prek, clang-tidy, R27 and R31 (every commit)

`SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
uvx prek run --files <the commit's paths>` to a fixpoint with a private
`XDG_CACHE_HOME` deleted afterwards; for each `.md`, `python3 -I
/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/sv1-fixer5/bin/r31.py
<file>` before and after, the counts unchanged, and the diff grepped for a new
line matching `^\+\s*#{1,6} [0-9]|^\+#[0-9]`. clang-format 21.1.8 with
`--assume-filename`; clang-tidy 21.1.8 in VA-2's two passes over every changed
`.cpp` (`$X/bin/tidy.sh <mode> <tree> <base> <file>`, where `<mode>` is `norec`
for the first pass and anything else for the second, the build's flags read from
build.ninja), every diagnostic fixed in the next fix commit, none suppressed.
The planner's and the fixer's runs of both passes printed nothing. R27 (amended
2026-10-28, review fold: B-m5): before P, each code span of Appendix C.5 that
spells a declaration is found verbatim in the golden (`grep -F -e 'overload fn
F(x: i32, y: i32 = 2);' -e 'overload fn F(x: i32, y: i32);' -e 'overload fn G(x:
i32, y: i32 = 2);' -e 'overload fn G(x: i32, y: i32 = 3);'` over
toolchain/check/testdata/function/overload/default_values.carbon: four lines at
C1, eight after F1, whose STDERR lines echo them; measured on rev 2), and C.1's
two `Pick` spans are found in the same golden's `first_member_needs_default`
split and in B.1.

### §8.7 Composition mirrors (before the implementation reviews)

Each mirror is `git worktree add --detach /dev/shm/ov4-<role>/src/<name>` of
the held head, then `git merge --no-ff --no-commit` of OV-4's head, the
conflicts resolved by §6.2's rules and the records taken from the held head,
the README regenerated, then build, install, gate, conformance and the probes,
then `git worktree remove` and the build deleted. Expected red set before the
mirror's own fill: none beyond the held head's own; each mirror's probe output
equal to the prototype's.

Measured by the fixer on rev 2 (amended 2026-10-28, review fold: A-M1 / B-m5;
the planner's m66 ran on rev 1): m66 merged the code tree 88899f052 with rev
2's renamed golden copied in, m64 and m61 merged 3ff06902f; "alone" is the held
PR's own install on the same program set.

| mirror | conflicts | gate | conformance with OV-4 | the held PR alone | probes (62) |
| --- | --- | --- | --- | --- | --- |
| m66, PR 66 (43c8ab476) plus OV-4 | handle_function.cpp (VA-1's pack gate, then the look-through), three records files taken from PR 66 | 1981 passed, 0 failed, none refilled | PASS 149, SKIP 21 of 170; bullets 49, 0, 7, 0 | PASS 147, COMPILE-FAIL 2 (OV-4's two programs), SKIP 21 | the prototype's but for a12 (default beside a pack), where PR 66's lexer reads `...` and VA-1's "variadic member of an overload set" TODO fires, as §6.2's rule intends |
| m64, PR 64 (551a03328, which contains PR 61) plus OV-4 | ORCHESTRATION and the ledger, taken from PR 64 | 1963 passed, 0 failed, none refilled | PASS 149, SKIP 20 of 169; bullets 48, 0, 8, 0 | PASS 147, COMPILE-FAIL 2, SKIP 20 | all equal, a09c, f01 to f07 and the template split's p16 included |
| m61, PR 61 (66aa13132) plus OV-4 | the same two records files, taken from PR 61 | 1961 passed, 0 failed, none refilled | PASS 140, SKIP 22 of 162; bullets 48, 0, 8, 0 | PASS 138, COMPILE-FAIL 2, SKIP 22 | all equal |

So TP-1's and CT-1's deferred conversion leaves the template-dependent
default's behavior where trunk's plain path puts it (the A-M1 class, §0.3),
and PR 66's deduction leaves D-OV4-7's OUT unchanged (p07, p20). PR 59 is PR
66's base, so m66 covers it; m59 is run only if PR 66 is not landed with PR 59.

Still to run, by the implementer:

-   **m60, PR 60 plus OV-4:** the merge.cpp conflict and the two added
    arguments (§6.2); expected: SC-1's goldens and OV-4's four pass,
    `fail_redecl_default_differs` unchanged (SC-1's errors-match mode stays
    off on OV-4's path).
-   **mall, the land rehearsal, before the implementation reviews** (amended
    2026-10-28, review fold: B-M3; rev 1 deferred it "once the held PRs' own
    land rehearsals exist"): trunk with PR 67 and PR 53 to PR 66 merged in the
    land order, each conflict resolved by that PR's own land rules, the way
    VA-2's D-VA2-18 rehearsal did
    (/home/user/carbon-va2/fork/variadics/va2-plan.md §8.7 `mall`), then OV-4's
    head merged as M would merge it, with §6.2's region rules, then built,
    gated, filled (as F-M) and run through conformance. Predicted red set before
    F-M: exactly the held sequence's own, measured on the same tree without
    OV-4's merge (VA-2's mall measured 17 held land-time refills and, after its
    F-M, three held-side failures, CT-1's and DR-1b's land-time renames and
    SC-1's `self_facet_in_signature_required`), and none of OV-4's four goldens
    or two programs (m66, m64 and m61 refill nothing, and m60's prediction is
    the same). Predicted counts: the held sequence's tree plus OV-4's four
    goldens and two programs, both programs PASS. A red OV-4 file, or a records
    region §6.2's rules cannot resolve, stops the implementation reviews until
    the plan says why.

### §8.8 Re-verification on the merge commit (land time)

After M: §8.1 to §8.5 on the merge commit; F-M commits the refills; the
totals become the landed trunk's floor plus §5's delta, and L quotes that run,
EXPECTED, not of record.

### §8.9 Not run, and why

-   The hosted gate, autoupdate and conformance: GitHub Actions is disabled and
    the owner's runner is never used (R28); every figure here is
    container-local.
-   Upstream's tip toolchain was not built: that p21's crash exists at
    0421bf3b4 is inferred from its unchanged `CheckDefaults`,
    `ResolveCalleeInCall` and pattern_match.cpp, not measured.
-   Upstream issue 7529 (named by `CheckDefaults`' TODO) could not be read:
    this session's GitHub API access does not cover carbon-language/carbon-lang
    (HTTP 403); the TODO's own text is quoted instead.
-   Bazel-only tests (gtest unit tests, lit, fuzzers): no Bazel here; OV-4
    changes no unit-tested API.
-   The m60 and mall mirrors: specified for the implementer, mall before the
    implementation reviews (§8.7); m66, m64 and m61 were measured on rev 2.
-   M6 was not re-run on rev 2: B.1 is unchanged and the toolchain change
    since rev 1 is the default count, which no program exercises.
-   macOS, Windows, ASan and opt builds: the container builds Linux fastbuild
    only.
-   For rev 3 (amended 2026-10-28, review fold: RR1): the 62 probes of
    `$X/probe_list.txt`, the mutants but M5, clang-format, clang-tidy and the
    mirrors m66, m64 and m61, because rev 3 changes no toolchain line and the
    rebuilt prototype is rev 2's toolchain. The five r probes print on PR 59,
    PR 66, PR 61 and PR 64 alone what trunk prints (PR 59's and PR 66's r04
    abort at :1807, their line for :1805), and the implementer's mall and F-M
    run the new split on the merged branches.

### §8.10 Id re-scan (before commit D)

The command of §0.9, after a fetch: W-360 to W-364 must still be free on every
ref and worktree but for OV-4's own uses; a hit elsewhere renumbers OV-4's
residues upward within W-360 to W-364, or, if those are taken, to the next
free ids after a new re-scan, recorded in D's message. A renumbering of W-360
also edits the `TODO(UA-3, W-360)` comment of
`fail_todo_generic_member_default` in C1's golden source, by a fix commit with
its fill (the comment is source text, so autoupdate keeps it), and the
evidence lines of D.1 that cite it (amended 2026-10-28, review fold: B-m5).

### §8.11 Review fold record (rev 2, 2026-10-28)

Plan reviews A (root causes, soundness, upstream fidelity) and B (records,
process, R31 and R32) of rev 1 (fdaed06ae), both APPROVE-WITH-AMENDMENTS, no
BLOCKER: fifteen findings, every one reproduced in the fixer's scratch
(`$X`) before it was folded, the prototype re-measured wherever a finding
changed it. Fourteen are folded as filed. One, A-M1, is folded in part: its
measurement, its premise (D-OV4-2's sentence was false), its golden split, its
R-1 and §7.2 corrections and its m61 and m64 mirrors are folded; its proposed
fix, a probe that skips a member whose default fails in the specific, is
rejected with evidence, because upstream's accepted design makes substitution
failure an error (p002200:214-217, README.md:2828-2832, R32) and the built
check leaves the diagnostic in place (R17). No finding needed W-363 or W-364.

| finding | severity | disposition | where |
| --- | --- | --- | --- |
| A-M1 template-dependent default: probe accepts, commit fails | MAJOR | folded in part, fix rejected: a09c reproduced on rev 1 and rev 2; f01 and f04 show the default fails in the specific with the argument supplied too, the plain call alike (trunk, nightly); f03 shows the class on trunk with no default; f05 shows a member resolution never reaches is never substituted; the proposed `HasError()` check, built, leaves a09c's error and adds a NoMatch to f04; skipping is SFINAE, which p002200:214-217 rejects | §0.2, §0.3, §0.4, §0.5, D-OV4-2, D-OV4-11, §7.1 R-1, §7.2, A.1 `fail_template_default_specific`, A.3 `template_dependent_default`, §8.7 m61 and m64 |
| A-m1 classes.md's future-work example spells a positional default | MINOR | folded: classes.md:2193-2216 quoted by sha, C.1 reworded, D.2 and D.6 rows added, tip 0421bf3b4 named | §0.2, C.1, D.2, D.6 |
| A-m2 register line (vii) NONE against T2.6's ALIGNED | MINOR | folded: T2.9 is the plain-call rule, NONE; the tie-break stays T2.6's ALIGNED; T2.8's checks are T2.8's | §0.8, D-OV4-6, D-OV4-15, D.2, D.6 |
| A-m3 the count of 0 rejects `P(5, 6)`; R-3 falsified | MINOR | folded: the trailing count, measured (a10 and f07 as trunk; M5b catches rev 1's rule); `Q(5, 6)` and `Q(5)` in `fail_default_not_trailing`; W-362 retitled | §0.3, §0.4, §0.5, D-OV4-5, §2.2, §7.1 R-3, §7.2, A.1, D.1 |
| A-m4 stale ids and mutant count | MINOR | folded: A.2 and A.4 headers cite D-OV4-10; the introduction and §8.5 count M1 to M5, M5b and M6 | header, §8.5, A.2, A.4 |
| B-M1 the V-3 check misses p002200 and classes.md's sketch | MAJOR | folded: p002200:471-476 and classes.md:2193-2216 quoted by sha, the two false sentences corrected, quote rows added and checked at both tips (15 of 15) | §0.2, §0.10, C.1, D.2, D.6 |
| B-M2 the shrink line adds guards R17 rejects | MAJOR | folded: no shrink line; a defect past the budget stops at a plan revision; the core has no smaller form; hand-off note 7 rewritten | §3, §7.2, hand-off note 7 |
| B-M3 land-time commits not concrete; records collisions unmeasured | MAJOR | folded: verbatim messages for M, F-M, L-R and L and D.7's texts; mall required before the implementation reviews with its predicted red set; merge-tree of a tree with P and D against all seventeen heads, PR 67 first, and a rule per region | §0.6, §3, §6.2, §7.1 R-5, §8.7, D.7 |
| B-M4 docs amended beside false text where W-341 requires a rewrite | MAJOR | folded: the CLOSED paragraph, F-009j and the arity parenthesis rewritten in place, each quoting its superseded text, dated; D.1 and D.2 say so | D-OV4-15, §2.6, §7.2, C.1 to C.3, D.1 |
| B-M5 the gap row claims the discharge before D; wrong commit cited | MAJOR | folded: commit R removed; the row and ORCHESTRATION are written in D, after the reviews; the programs cite `<P>` | §2.7, §3, D.4 |
| B-m1 register rows depart from RG-1's format | MINOR | folded: rows T2.8 and T2.9 after a `#` comment; OV4.3 is T2.8's check; T2.9's check trips on a new overloading proposal; OV4.1 subsumed, OV4.2 dropped with its reason | §0.8, D.6 |
| B-m2 ordering against EH-C (W-346) | MINOR | folded: OV-4 before EH-C, either order allowed, records by §6.2 | header, D-OV4-16, §6.2 rule 8 |
| B-m3 no review of the fix commits or D | MINOR | folded: a focused re-review with a dry rule and a cap of three rounds | §3 item 8 |
| B-m4 text errors in golden headers and records; placement | MINOR | folded: D-OV4-10 in A.2 and A.4; no `<R>` (R is gone) and D lists the fix commits; the entry sits with OV-1 to OV-3, newest first | A.2, A.4, D.2, D.5 |
| B-m5 provenance and coverage gaps | MINOR | folded: merge-trees and m66 re-run on 3ff06902f, whose diff is §2's; `Fork (OV-4, W-362)` markers; the lower split dumps `T(i32)` and `T(bool)`; the covered-member case recorded against D-OV-3; an R27 diff step; §8.10 covers the golden's TODO; 0421bf3b4 named and the re-fetch at C1 and L-R | §0.2, §0.5, §0.6, §0.9, D-OV4-4, D-OV4-5, §2.2, §3, §8.6, §8.10, A.3, C.1, C.5 |

Disk: the fixer's prototype build and the m66, m64 and m61 mirrors were built
under /dev/shm/ov4-fixer and deleted with their worktrees; no install is kept.

### §8.12 Review fold record (rev 3, 2026-10-28)

The focused re-review RR1 of rev 2 (7fda41b11), APPROVE-WITH-AMENDMENTS: no
BLOCKER, no MAJOR, four MINORs. It re-checked the base (`git diff --stat
0bdce60a5 66bd2ba90 -- toolchain core` is empty) and the tip (0421bf3b4),
rebuilt the rev-2 prototype 3ff06902f under /dev/shm/ov4-rr1 and measured it:
the gate passes 1946 of 1946; §2's diff blocks are byte-identical to the
prototype's diff; A.1 and B.1 are the prototype's files and B.1 prints its
EXPECT lines; the fifteen D.6 quotes pass at 0421bf3b4 and the two counts are
3 and 40; W-360 to W-364 are free on every ref; and a merge-tree of the records
twin 59b65eb9c against the seventeen heads adds conflicts only in ORCHESTRATION
and the ledger, beside the code conflicts §0.6 names. It found every rev-2
MAJOR resolved (A-M1's fix rejected on upstream evidence, measured: f01, f02,
f04, f05, f06 and a09c as §0.3 says, p002200:214-217 and README.md:2828-2832 as
quoted; B-M1 to B-M5), every MINOR fold in place (A-m3: a10 and f07 as trunk,
p21 an arity error where trunk crashes) and no fold breaking another section.
Every finding was reproduced in the fixer's scratch (`$F`) before it was
folded; none is rejected, and none needs W-363 or W-364.

| finding | severity | disposition | where |
| --- | --- | --- | --- |
| RR1-m1 D-OV4-8 says `self` takes no default, but a defaulted `self` is declarable | MINOR | folded: reproduced (r01 prints 1, 1 on trunk, the four held installs and the nightly; r02 prints 1, 4, 1, -1 on the prototype; r02b is gate (x)'s TODO); the reason restated from upstream's `FindSelfPattern`, which does not look through a default, so the function is not a method and the set treats the member as one without `self`, as the plain call does; the split `defaulted_self_is_not_a_receiver` added, filled and gated | §0.2, §0.3, §0.4 step 2, §0.10, D-OV4-8, D-OV4-14, §2.4, §4, A.1, D.1, D.2 |
| RR1-m2 W-362 and its split miss the tuple-pattern crash site | MINOR | folded: reproduced (r04 aborts at pattern_match.cpp:1805 on trunk, PR 61 and PR 64, at :1807 on PR 59 and PR 66 and at :750 on the nightly; the prototype reports "1 argument passed to function expecting 3 arguments"; r04s is the set form behind gate (iii)); `R((1, 2))` added to `fail_default_not_trailing`; M5 rebuilt on rev 3 aborts r04 at :1805; both sites cited in D-OV4-5, W-362 and its upstream report | §0.3, §0.4, §0.5, §0.10, D-OV4-5, D-OV4-14, §1.1, §2.4, §4, A.1, D.1, D.2, D.5 |
| RR1-m3 C.1 cites call.cpp's arity range for the trailing and constant rules | MINOR | folded: reproduced (call.cpp:46-52 at 0421bf3b4 speaks of the arity range only); C.1 cites function.cpp:676-679 for the trailing rule and handle_pattern_list.cpp:185 for the constant rule and keeps the call.cpp quote for the range; function.cpp:677 added to D.6's quotes (16 of 16 pass at both tips) and the trailing rule quoted in D.2's V-3 check | §0.2, §0.8, D-OV4-15, C.1, D.2, D.6 |
| RR1-m4 rows T2.8 and T2.9 said to join rg1-plan.md's table, written by no commit | MINOR | folded by the review's first fix: L-R also inserts the two rows, verbatim in D.6, into fork/register/rg1-plan.md §2.T2 after T2.7's row, so each TSV row names a section 2 entry, as the TSVs' header says and rg1-plan.md §4.2's rebuild from section 2 assumes; the TSVs' comment lines name the rows; the other fix (the entries only in the decision log) would leave W-355's owner no section 2 entry to re-read | §0.8, D-OV4-15, §3 L-R, §6.2 rule 7, D.2, D.6, hand-off note 10 |

Disk: the rev-3 prototype's build and worktree under /dev/shm/ov4-fixer1 were
deleted before this plan's commit; no install is kept.

## Sign-off

Every review of this plan, with its verdict and its counts (amended
2026-10-28, review fold: RR1):

| review | read | verdict | BLOCKER | MAJOR | MINOR | folded | rejected | fold |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A: root causes, soundness, upstream fidelity | rev 1, fdaed06ae | APPROVE-WITH-AMENDMENTS | 0 | 1 | 4 | 5 (A-M1 in part) | A-M1's proposed fix, on upstream evidence (§7.2) | rev 2, §8.11 |
| B: records, process, R31 and R32 | rev 1, fdaed06ae | APPROVE-WITH-AMENDMENTS | 0 | 5 | 5 | 10 | none | rev 2, §8.11 |
| RR1: the focused re-review | rev 2, 7fda41b11 | APPROVE-WITH-AMENDMENTS | 0 | 0 | 4 | 4 | none | rev 3, §8.12 |

Rev 3 is SIGNED OFF FOR IMPLEMENTATION: the last review's verdict is
APPROVE-WITH-AMENDMENTS, not REJECT; every finding of the three reviews is
folded, A-M1 in part with its proposed fix rejected on the evidence of §7.2;
and rev 3's one change outside the records texts, Appendix A.1's new split and
`R`, was filled on the rev-2 toolchain, gated (1946 of 1946) and run through
conformance (130/0/22 over 152), with no earlier outcome changed (§0.5). The
implementation starts from this plan's commit with §3's C1.

## Hand-off notes for the implementer

1.  Start from a clean worktree at this plan's commit: the planner and the
    fixers restored or deleted every tree they prototyped in. `$X/r2/saved`
    holds rev 2's prototype files and `$X/r2/proto-toolchain.diff` its
    toolchain diff, identical to §2's blocks; the scratch commit 3ff06902f
    holds the same tree (amended 2026-10-28, review fold: B-m5). Rev 3
    changes only Appendix A.1's source: its fill is in `$F/r3/saved` and its
    difference from 3ff06902f's golden is `$F/r3/golden-rev3.diff` (amended
    2026-10-28, review fold: RR1-m1 / RR1-m2).
2.  C1's goldens go in without CHECK lines; never write a CHECK line by hand
    (R16). Appendix A's sources are complete; F1 is autoupdate's.
3.  Write the probes of §0.3 into your own scratch (`$Q/probes`, `$X/probes`
    and `$F/probes` are the planner's and the fixers'; read, do not write
    there) and keep `$Q/bin/probe.sh`'s shape: compile each unit with
    `--output-last-input-only`, link, run.
4.  B.1's EXPECT lines are derived in its header; re-derive them from §1 and
    the prelude before running anything (R16 (d)). B.2 has no EXPECT-STDOUT
    (DIFF-1).
5.  Appendix C's C.1 to C.3 replace the text they name, each quoting the
    superseded text inside the new paragraph; C.4 to C.6 are inserted, the
    existing text unchanged; `<date>` is the commit's `date -u +%F` (amended
    2026-10-28, review fold: B-M4).
6.  At M, SC-1's signature change compiles only with the two added arguments
    (§6.2); a clean textual merge of merge.cpp is not a clean build.
7.  There is no shrink line: a defect a review finds is fixed at its root in a
    fix commit, and one the fix budget cannot hold stops OV-4 at a plan
    revision, never at a guard (amended 2026-10-28, review fold: B-M2).
8.  W-360 to W-362 are filed at D, not before; their `<sha>` fields are C1's.
9.  Run mall before the implementation reviews (§8.7), and the R27 step of
    §8.6 before P (amended 2026-10-28, review fold: B-M3 / B-m5).
10. At L-R, D.6's two table rows go into fork/register/rg1-plan.md §2.T2 as
    well as its rows into the two TSVs; run prek and the R31 counts on
    rg1-plan.md (amended 2026-10-28, review fold: RR1-m4).

## Appendix A. Golden sources (C1; CHECK lines by autoupdate only)

Each file is written exactly as below; autoupdate adds the CHECK lines. Rev 2
changes A.1 (three splits), the headers of A.2 and A.4 (D-OV4-10) and A.3 (one
split) (amended 2026-10-28, review fold: A-M1 / A-m3 / A-m4 / B-m4 / B-m5).

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

// --- defaulted_self_is_not_a_receiver.carbon

library "[[@TEST_NAME]]";

// A parameter named `self` that has a default value does not make a method:
// the function has no `self` parameter, so `c.P()` binds no receiver and fills
// `self` from its default. A set treats such a member as one without `self`,
// exactly as the ordinary call does (D-OV4-8), beside the selfless `M(b)`.
class C {
  fn P(self: i32 = 1) -> i32 { return self; }
  overload fn M(self: i32 = 1) -> i32 { return self; }
  overload fn M(unused b: bool) -> i32 { return -1; }
}

//@dump-sem-ir-begin
fn Use(c: C) -> i32 {
  return c.P() + C.M() + C.M(4) + c.M() + C.M(true);
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
// differing default, rather than forming a member no call could reach. The
// `F` and `G` pairs are the design page's example, spelled as it spells them
// (rulebook R27).
overload fn F(x: i32, y: i32 = 2);
overload fn F(x: i32, y: i32);

overload fn G(x: i32, y: i32 = 2);
overload fn G(x: i32, y: i32 = 3);

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

// A declaration whose default is not trailing is diagnosed and counts only
// the defaults after its last parameter that has none: a call that omits an
// argument for a parameter with no default is an arity mismatch, for a set
// member and for a plain function alike, and a call that omits only trailing
// defaulted arguments is still accepted (`Q(5, 6)`). The parameter without a
// default may be a tuple pattern: `R((1, 2))` is a mismatch too.
overload fn F(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

fn P(unused x: i32 = 1, unused y: i32) -> i32 { return 1; }

fn Q(x: i32 = 1, y: i32, z: i32 = 3) -> i32 { return x + y + z; }

fn R(x: i32 = 1, (a: i32, b: i32), z: i32 = 3) -> i32 { return x + a + b + z; }

fn Use() -> i32 { return F(5) + P(5) + Q(5, 6) + Q(5) + R((1, 2)); }

// --- fail_todo_non_value_default.carbon

library "[[@TEST_NAME]]";

// D-OV-6 gate (iii) looks through a default value to the parameter it wraps:
// a defaulted `var` parameter or a defaulted tuple pattern is still a
// non-value explicit parameter.
overload fn F(unused x: i32, var y: i32 = 2) -> i32 { return y; }
overload fn G(x: i32, (a: i32, b: i32) = (3, 4)) -> i32 { return x + a + b; }

// --- fail_template_default_specific.carbon

library "[[@TEST_NAME]]";

// A default value whose type is template-dependent is converted in each
// specific of the member's declaration, as it is for the ordinary call of the
// same function, whose `Box(bool)` declaration fails to monomorphize even when
// the call supplies `y`. Substitution failure is an error (proposal p2200, no
// SFINAE): resolution forms the specific of each member it reaches, in
// declaration order, so `Box(bool).Get()` is diagnosed at member 0 and does
// not fall through to member 1. A member that resolution never reaches is
// never substituted: `Box2(bool).Get()` selects its member 0 first.
class Box(template T: type) {
  overload fn Get(unused y: T = 0) -> i32 { return 1; }
  overload fn Get() -> i32 { return 2; }
}

class Box2(template T: type) {
  overload fn Get() -> i32 { return 2; }
  overload fn Get(unused y: T = 0) -> i32 { return 1; }
}

fn Use() -> i32 {
  return Box(i32).Get() + Box(bool).Get() + Box2(bool).Get() + Box2(i32).Get(5);
}

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
// OV-4, D-OV4-10). Each member is its own C++ declaration (OV-3), and this
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
// initialized in the caller as the ordinary call initializes it. In a
// template's specific, the deferred call is resolved and filled the same way.

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

// --- template_dependent_default.carbon

library "[[@TEST_NAME]]";

overload fn F(x: i32, y: i32 = 2) -> i32 { return x * 10 + y; }
overload fn F(unused b: bool) -> i32 { return -1; }

// Each specific of `T` resolves its deferred call: `T(i32)` calls member 0
// with the default `2` filled, and `T(bool)` calls member 1.
fn T(template U: type, u: U) -> i32 { return F(u); }

fn Use() -> i32 { return T(i32, 1) + T(bool, true); }
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
// (fork/overload/ov4-plan.md D-OV4-10): Carbon's `F(1)` calls member 0
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

`<date>` is P's `date -u +%F`. C.1 to C.3 replace the text they name, in place,
each quoting the superseded 2026-09-27 text inside the new paragraph; C.4 to
C.6 are inserted at the anchor named, the anchor's own text unchanged
(amended 2026-10-28, review fold: B-M4; rev 1 inserted all six beside their
anchors). Each C.1 to C.5 text was applied to the scratch tree 59b65eb9c and
measured there (§0.6).

### §C.1 docs/design/functions_overloading.md, the match test's CLOSED paragraph (:570-576), replaced

The seven lines from "**CLOSED (fork amendment 2026-09-27) by D-OV-4 step
2(b):** no" through "Revisit as its own design fork if a need appears." are
replaced by (amended 2026-10-28, review fold: A-m1 / B-M1 / B-M4 / B-m5 /
RR1-m3; rev 2 cited call.cpp's arity range for the trailing and constant
rules):

<!-- google-doc-style-ignore -->

```markdown
**CLOSED (fork amendment 2026-09-27; rewritten <date> by OV-4, W-341) by D-OV-4
step 2(b) and OV-4's D-OV4-1:** Carbon parameters take positional default
values, as upstream's design spells them and its toolchain implements them: a
parameter written `p: i32 = 4` may be omitted at a call, and the call uses the
default value for it. Proposal
[p2200](/proposals/p002200-template-generics.md) declares
`class C4 { fn M[me: Self](p: i32 = 4); }` and calls `C4.M` "using the default
value of `4` for `p`", and the future-work sketch "Field defaults for struct
types" under "Optional named parameters" in [classes](classes.md) declares
`options: {.stable: bool = false, .descending: bool = false} = {}` and calls
`SortIntVector(&v);`. Every parameter after a defaulted one must also have a
default (upstream's toolchain at 0421bf3b4, check/function.cpp:676-679: "if a
subpattern provides a default value, all subsequent patterns at that level of
nesting must provide a default value as well"), a default must be a constant
(check/handle_pattern_list.cpp:185: "default value is not a constant"), and a
call supplies from the parameter count less the defaults up to the parameter
count (check/call.cpp:46-52: "the number of arguments is within the range
[callee_arity - arity_lower_bound_margin, callee_arity]"). Named optional
parameters stay the open question that classes.md records; this page adds no
spelling for them. A member with default values matches as the ordinary call of
the same function would: the arity step accepts from the member's parameter
count less its trailing defaulted parameters up to its parameter count, the
match test converts only the arguments the call supplies, and the selected
member's ordinary call supplies the omitted defaults. When defaults make two
members accept one call, the first in declaration order is selected, as for any
two members that accept it; using a default is not a worse match, so a member
that an earlier member's defaults cover, such as
`overload fn Pick(unused x: i32) -> i32` declared after
`overload fn Pick(unused x: i32, unused y: i32 = 2) -> i32`, is never
selected, as a member that an earlier member's conversions cover is not. Until
the fork takes upstream's later
commits, a generic member called with a defaulted argument omitted fails
deduction as the ordinary call of a generic function does (upstream 503f09037,
W-360), and an exported member's C++ declaration carries no default argument
(upstream 9799a2326, W-361). (The superseded text of 2026-09-27 read: "no
Carbon-native default arguments in 0.1, so the arity step above stays exact and
no interaction rule is needed. Carbon has no default-argument design;
overloading substitutes for the common cases, and default arguments on
_imported_ C++ functions keep working (they participate in Clang-side
resolution; see Importing C++ overload sets). Revisit as its own design fork if
a need appears.")
```

<!-- google-doc-style-resume -->

### §C.2 the same page, the F-009j item under "Sub-forks" (:1022-1023), replaced

The item's two lines are replaced by (amended 2026-10-28, review fold: B-M4):

<!-- google-doc-style-ignore -->

```markdown
-   **F-009j — Default arguments**: members take upstream's positional default
    values; the arity step accepts a range, the match test converts the
    supplied arguments only, and first match decides between members that both
    accept (see the CLOSED paragraph that ends
    [The candidate match test](#the-candidate-match-test)). CLOSED by D-OV-4
    step 2(b); rewritten <date> by OV-4 (W-341), whose superseded 2026-09-27
    text read "none in 0.1; the arity step is exact."
```

<!-- google-doc-style-resume -->

### §C.3 the same page, the arity step's parenthesis (:543-545), replaced

The parenthesis from "(The range is a single number today;" through "In the
toolchain: `GetExplicitArityRange`.)" inside item 1 is replaced by (amended
2026-10-28, review fold: B-M4):

<!-- google-doc-style-ignore -->

```markdown
    (The range runs from the candidate's parameter count less its trailing
    parameters with default values up to its parameter count, the range the
    ordinary call checks; it is a range so that [variadic](variadics.md)
    members can join sets later without changing this algorithm. In the
    toolchain: `GetExplicitArityRange`. Rewritten <date> by OV-4, W-341; the
    2026-09-27 text read "The range is a single number today".)
```

<!-- google-doc-style-resume -->

### §C.4 the same page, "0.1 limits" item (iii) (:364-366), its last line replaced

The item's last line, "    parameter patterns);", becomes the three lines
below, so the item's closing `;` moves after the parenthesis:

<!-- google-doc-style-ignore -->

```markdown
    parameter patterns) (amended <date>, OV-4: a default value does not change
    the parameter it wraps, so `y: i32 = 2` is a by-value binding and is
    accepted; a defaulted `var` parameter or tuple pattern is still gated);
```

<!-- google-doc-style-resume -->

### §C.5 the same page, the D-OV-3 CLOSED paragraph that ends "the first type-equal member is the one being redeclared." (:438-448), a sentence after it

Inserted on the line after the paragraph, as its last sentence; its code spans
are the C1 golden's declarations verbatim (R27, §8.6; amended 2026-10-28,
review fold: B-m5):

<!-- google-doc-style-ignore -->

```markdown
_Fork amendment <date>, OV-4:_ a default value is part of a declaration's
tokens, not of a parameter's type, so `overload fn F(x: i32, y: i32 = 2);`
followed by `overload fn F(x: i32, y: i32);`, or
`overload fn G(x: i32, y: i32 = 2);` followed by
`overload fn G(x: i32, y: i32 = 3);`, redeclares the first member and is
diagnosed `RedeclParamDiffers`, as two plain declarations are.
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

## Appendix D. Records texts, verbatim (D, L-R, L)

`<date>` is the commit's `date -u +%F`; `<C1>`, `<F1>`, `<P>`, `<M>` and
`<F-M>` are those commits' short shas, `<fix commits>` the fix commits' short
shas in order (or "no fix commit"); `<NN>` is OV-4's PR number; figures in
`<...>` are the run each record quotes. D.1 to D.5 are commit D's, made after
the reviews and their fixes (amended 2026-10-28, review fold: B-M5 / B-m4; rev
1 put D.4 and D.5 in a commit R before the reviews). Each D.1 to D.5 text was
applied, `<date>` filled, to the scratch tree 59b65eb9c and merged against all
seventeen heads (§0.6).

### §D.1 fork/inventory/work-items.json (D)

W-341 changes in place: `kind` becomes `implemented`, `title` and `subsystem`
are replaced, the four "Landed at" items are prepended to `evidence` (the filed
items stay after them), and the discharge sentence is appended to `notes`
(amended 2026-10-28, review fold: A-M1 / A-m3 / B-M4: the line ranges are rev
2's, the default count is the trailing one, and the docs are "rewritten in
place", which is what P does; RR1-m1 / RR1-m2: eighteen splits, and W-362's
two crash sites).

<!-- google-doc-style-ignore -->

```json
{
  "id": "W-341",
  "kind": "implemented",
  "title": "OV-4 (DISCHARGED at OV-4, <date>): an `overload fn` member with upstream's positional default values is called with a defaulted argument omitted -- the overload set's arity step accepts the plain call's range (`default_value_arity`), its probe converts the supplied arguments only and the ordinary call fills the rest, gate (iii) looks through a default value, member identity ignores defaults, and a diagnosed non-trailing default counts only its trailing defaults; F-009j and the match test's CLOSED paragraph rewritten in place to name upstream's mechanism (R32 (b), (d); weekly upstream check 2026-10-26)",
  "subsystem": "toolchain/check (call.cpp, handle_function.cpp, merge.cpp, merge.h) + docs/design (functions_overloading.md) + tests",
  "evidence_prepended": [
    "Landed at OV-4 (<C1>): toolchain/check/call.cpp:422-438 (`GetExplicitArityRange`: `[n - default_value_arity, n]`, `ResolveCalleeInCall`'s range and CHECK), :495-511 (`ProbeOverloadCandidateInScratchScope`: the supplied arguments against the leading parameter patterns, under `CARBON_CHECK(arg_ids.size() <= param_pattern_ids.size() && param_pattern_ids.size() - arg_ids.size() <= default_value_arity)`)",
    "Landed at OV-4 (<C1>): toolchain/check/handle_function.cpp:366-367 (member identity through `CheckOverloadMemberParamsMatch`), :859-880 (gate (iii) through a `DefaultValuePattern`), :958-961, :1019-1021 and :1053-1059 (`CheckDefaults`, marked `Fork (OV-4, W-362)`: a level with a diagnosed missing default counts only its trailing defaults); toolchain/check/merge.cpp:576-629 and :643-654, merge.h:121-135 (`GetOverloadMemberParamPatterns`, `CheckOverloadMemberParamsMatch`)",
    "Landed at OV-4 (<F1>): toolchain/check/testdata/function/overload/default_values.carbon (18 splits), toolchain/check/testdata/interop/cpp/function/export/overload_set_default.carbon (3), toolchain/lower/testdata/function/overload/default_values.carbon (3), toolchain/lower/testdata/interop/cpp/function/export/overload_set_default.carbon (1)",
    "Landed at OV-4 (<P>): fork/conformance/programs/functions/overloading_default_values.carbon and the DIFF-1 pair overloading_default_values_diff.carbon and .diff.cpp; docs/design/functions_overloading.md rewritten in place at the match test's CLOSED paragraph (:570-576 at 66bd2ba90), the F-009j item (:1022-1023) and the arity step's parenthesis (:543-545), each quoting its superseded 2026-09-27 text, and amended at 0.1 limits item (iii) and D-OV-3's paragraph; fork/overload/plan.md's dated notes at :380 and :2173; measured <gate> of <gate> goldens and <pass>/0/<skip> over <total> programs, container-local, EXPECTED, not of record"
  ],
  "notes_appended": " Discharged <date> by OV-4 (fork/overload/ov4-plan.md; decision-log entry OV-4): the filed mechanism was necessary but not sufficient, because D-OV-6 gate (iii) refused every defaulted member at its declaration, member identity treated a default as a different parameter (a declaration differing only in a default became a second member of the same parameter types), and a diagnosed non-trailing default left the plain path's arity open (the CHECKs at pattern_match.cpp:1275 and, when the unmatched parameter is a tuple pattern, :1805, on trunk and the nightly); OV-4 changed those three too, each at its root, with one resolution path and no new diagnostic. The filed notes' \"functions_overloading.md:570-576 and :1022-1023 are rewritten\" is done in place, each rewrite quoting the text it supersedes. Generic members with defaults wait for 503f09037 at UA-3 (W-360), exported members' C++ default arguments for 9799a2326, 8fdc8ebc3 and c7de72757 (W-361); the default count's fix moves into function.cpp at UA-3 (W-362)."
}
```

<!-- google-doc-style-resume -->

New items, appended in id order after the last item (W-344 on trunk; after
PR 67's W-356 once it has landed, §6.2 rule 5):

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
        "upstream 503f09037 (PR 8011): check/deduce.cpp:640-653 at 0421bf3b4 ('If we are short on arguments, check if we can append default values for deduction.'), check/pattern.cpp:363 `ExtractParameterDefault`; 427c448dc (PR 8027) its golden",
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
        "upstream 9799a2326 (PR 7988), 8fdc8ebc3 (PR 8025) and c7de72757 (PR 8019): check/cpp/export.cpp:964 `BuildDefaultValueExpr`, used at :1223 and :1422 at 0421bf3b4",
        "fork/overload/ov4-plan.md D-OV4-10"
      ],
      "blocked_by": [],
      "notes": "Filed <date> by OV-4. Owner: UA-3. When the advance brings the three commits, each exported member's C++ declaration carries its defaults; the export split's C++ side then selects the defaulted member, and that change is recorded in the decision log before the golden moves (rulebook R30 (c)). Break condition: the per-member export path stops exporting a defaulted member, or UA-3's export of a member differs from a plain function's."
    },
    {
      "id": "W-362",
      "kind": "toolchain-defect",
      "title": "OV-4 residue (fixed on the fork, owed upstream): a call that omits an argument of a function whose default is not trailing aborted at pattern_match.cpp:1275 (`CARBON_CHECK(scrutinee_id.has_value())`), or at :1805 (the tuple pattern's caller-side check) when the omitted parameter is a tuple pattern, because `CheckDefaults` diagnosed the missing default and still returned the level's count; OV-4's `CheckDefaults` counts only the trailing defaults of such a level, so a call that omits only trailing defaulted arguments still compiles",
      "subsystem": "toolchain/check (handle_function.cpp; upstream's function.cpp)",
      "size": "S",
      "bullet": "Functions: function overloading (Carbon-native)",
      "evidence": [
        "toolchain/check/handle_function.cpp:958-961, :1019-1021 and :1053-1059 (the fix, marked `Fork (OV-4, W-362)`, OV-4 <C1>)",
        "toolchain/check/testdata/function/overload/default_values.carbon `fail_default_not_trailing` (the set member F, the plain functions P, Q and R; `Q(5, 6)` compiles, `Q(5)` and `R((1, 2))` are count mismatches)",
        "upstream 0421bf3b4 toolchain/check/function.cpp:688 `CheckDefaults` (moved by 1b0a5709e, PR 7893; unchanged but for diagnostic rendering), call.cpp:46-84",
        "fork/overload/ov4-plan.md D-OV4-5 and section 0.3 p21, r04 and a10 (the crashes on trunk, at :1275 and :1805, and on the 2026.10.12 nightly, at :489 and :750)"
      ],
      "blocked_by": [],
      "notes": "Filed <date> by OV-4. Owner: UA-3, which carries the fix into function.cpp's `CheckDefaults` (1b0a5709e moved it), or drops it if upstream has fixed the crash another way, and reports both crash sites upstream if the tip still has them. Break condition: upstream fixes it; UA-3 then takes upstream's fix."
    }
]
```

<!-- google-doc-style-resume -->

### §D.2 fork/decision-log.md, the entry OV-4 (D), placed directly above "### OV-3: overload-set export, documented divergence (2026-10-05)"

The log groups a workstream's entries newest first (OV-3 at :3805 above OV-2
at :4434 and OV-1 at :4728), so OV-4's entry opens the group; DR-0 and RG-1 sit
under V-1 to V-3 because they amend V-3 (amended 2026-10-28, review fold:
B-m4; rev 1 placed it after DR-0 and RG-1 with no reason).

<!-- google-doc-style-ignore -->

```markdown
### OV-4: `overload fn` members with default parameter values (W-341) (<date>)

W-341 (filed at the weekly upstream check 2026-10-26) is DISCHARGED on
claude/carbon-fork-0-1-ov4 (fork/overload/ov4-plan.md rev <n>, commits <C1>,
<F1>, <P>, <fix commits> and this one): an `overload fn` member with upstream's
positional default values is called with a defaulted argument omitted, as the
ordinary call of the same function is. The gap row "Functions: function
overloading (Carbon-native)" stays DONE with its evidence refreshed. Measured
container-local, EXPECTED, not of record: <gate> of <gate> goldens, conformance
<pass>/0/<skip> over <total>, bullets <bullets>. The entry sits with OV-1 to
OV-3, newest first, as the log groups a workstream's entries.

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
    omitted defaults. A default is converted at the declaration, or, when its
    type is template-dependent, in each specific of the declaration, which
    resolution forms before the probe converts anything (D-OV4-11). Break: a
    default that depends on the call.
-   **D-OV4-3:** gate (iii) looks through a `DefaultValuePattern`; a defaulted
    `var` or tuple parameter stays gated. Break: gate (iii) lifted (W-095).
-   **D-OV4-4:** member identity (D-OV-3, F-009k) ignores default values; a
    declaration differing from a member only in a default is
    `RedeclParamDiffers`. Break: upstream lets redeclarations differ in
    defaults.
-   **D-OV4-5:** a level with a diagnosed missing default counts only its
    trailing defaults (the plain call aborted at pattern_match.cpp:1275, or
    at :1805 when the unmatched parameter is a tuple pattern; W-362). Break:
    upstream fixes it otherwise.
-   **D-OV4-6:** two members that accept one call, one through a default:
    first match, no ranking (pattern_matching.md:696-697). Break: an upstream
    overloading design with ranking.
-   **D-OV4-7:** generic members with a defaulted argument omitted fail
    deduction as the plain call does, until 503f09037 at UA-3 (W-360). Break:
    UA-3 lands without it.
-   **D-OV4-8:** receivers need no new rule: a `self` with a default is not a
    receiver upstream (`FindSelfPattern` does not look through the default),
    so the set treats that member as one without `self`, as the plain call
    does. Break: upstream makes a defaulted `self` a receiver or an error.
-   **D-OV4-9:** imported members carry `default_value_arity` and the pattern.
    Break: upstream stops importing them.
-   **D-OV4-10:** exported members have no C++ default argument until
    9799a2326 at UA-3; both sides pinned (R30; W-361). Break: the export path
    changes.
-   **D-OV4-11:** template-dependent calls resolve per specific under the
    same rule; a member whose specific fails to substitute is an error, not a
    skipped candidate (p002200:214-217, no SFINAE). Break: upstream adopts
    SFINAE for overload sets.
-   **D-OV4-12:** defaults are constants, by upstream's toolchain; nothing
    added. Break: upstream allows an earlier parameter.
-   **D-OV4-13:** no new diagnostic or text. Break: a misleading note in a
    real call.
-   **D-OV4-14 to D-OV4-17:** the goldens and programs, the docs and records,
    the merge position after PR 66 (and before EH-C) with no held PR amended,
    and the commit sequence (fork/overload/ov4-plan.md sections 1 and 3).

_V-3 check at upstream's tip 0421bf3b4 (R32 (a); e6fddcf97 reads the same)._
Upstream's accepted design spells positional default values in two places
and implements them in its toolchain. Proposal p002200:471-476: "class C4 {
fn M[me: Self](p: i32 = 4); }" and "Calls `F` with `T` equal to `C4`, which
succeeds, using the default value of `4` for `p` when calling `C4.M`."
classes.md:2193-2207, "Field defaults for struct types" under the open question
"Optional named parameters" (:2186-2191: "Structs are being considered as a
possible mechanism for implementing optional named parameters."), declares
`options: {.stable: bool = false, .descending: bool = false} = {}` and calls
`SortIntVector(&v);` with the argument omitted. The toolchain: call.cpp:46-52
("It also verifies that the number of arguments is within the range
[callee_arity - arity_lower_bound_margin, callee_arity]. This allows arity
matching when the callee has default arguments for some subpatterns.") and
:241, function.cpp:676-688 (`CheckDefaults`: "if a subpattern provides a
default value, all subsequent patterns at that level of nesting must provide a
default value as well", and "TODO: per
https://github.com/carbon-language/carbon-lang/issues/7529"),
pattern_match.cpp:950 ("If there's no scrutinee supplied, supply the default
value instead."), handle_pattern_list.cpp:185 ("default value is not a
constant"). `git grep -c -i -E 'default (value|argument)'` over functions.md
and pattern_matching.md is 0. F-009j's "no Carbon-native default arguments in
0.1" denied that mechanism, the drift W-341 filed under R32 (d); its rewrite
names it. Upstream has no overload sets (pattern_matching.md:696-697: "We do
not yet have an approved design for overloaded functions, but it is
anticipated that declaration order will be used in that case too."), and its
template design rejects SFINAE (p002200:214-217: "Substitution failure is an
error. In C++, the SFINAE rule will skip functions in overload resolution that
fail to instantiate. Instead, Carbon template parameters use constraints to
control when the function is available."; README.md:2828-2832). Upstream
commits since the cut that touch default values: 1b0a5709e, 2c9739799,
d87891f3a, 9799a2326, 503f09037, 427c448dc, 8fdc8ebc3, c7de72757
(fork/overload/ov4-plan.md section 0.2); none changes the arity margin or the
fill.

_V-3a register lines (RG-1's vocabulary, D-RG-1 to D-RG-6; rows T2.8 and T2.9
of fork/register/rg1-plan.md section 2.T2's table, which the land-time commit
L-R writes with their checks and quotes)._ T2.8,
F-009j, Carbon default arguments in overload sets: **ALIGNED**, the fork's rule
is the mechanism p002200:471-476 and classes.md:2198-2207 spell and upstream's
toolchain implements; quotes in fork/register/rg1-quotes.tsv, check T2.8
(`default_value_arity` in toolchain/check, 3 at the tip) in rg1-checks.tsv;
watched by W-355. T2.9, the plain-call rule for a member with defaults (a
member accepts at k arguments exactly when its ordinary call does, and its
probe converts the k supplied arguments): **NONE**, upstream has no overload
sets and no text on defaults with overloading; check T2.9 (40 lines on
overloaded functions, function overloading and overload sets in docs/design
and proposals at the tip, which a new overloading proposal moves); watched by
W-355. The tie-break between two members that accept one call stays T2.6's
ALIGNED first match, unchanged. Break conditions: T2.8, upstream designs
another optional-parameter mechanism or removes positional defaults (W-341's);
T2.9, an accepted upstream overloading design, or upstream text on defaults
with overloading.

_Residues._ W-360 (generic members, 503f09037), W-361 (export, 9799a2326,
8fdc8ebc3, c7de72757) and W-362 (the default count, into function.cpp), all
UA-3's; W-363 and W-364 unused. No held PR is amended (R32 (e)).
```

<!-- google-doc-style-resume -->

### §D.3 fork/decision-log.md, the weekly entry of 2026-10-26 (D)

Inserted as its own paragraph directly after the paragraph that ends "...or
removes positional defaults." in "Weekly upstream check 2026-10-26 (R32
direction register)" (trunk :6906):

<!-- google-doc-style-ignore -->

```markdown
_Note <date> (OV-4):_ W-341 is resolved by OV-4 and DISCHARGED (see the entry
"OV-4: `overload fn` members with default parameter values (W-341)"): the
arity step, the probe, gate (iii), member identity and the default count follow
upstream's positional default values, and F-009j and the CLOSED paragraph of
functions_overloading.md's match test are rewritten to name them, quoted at
upstream 0421bf3b4 (proposal p002200:471-476, classes.md:2193-2216 and the
toolchain). Its break condition has not fired: classes.md:2186-2191 still
lists named optional parameters as an open question, and no upstream commit
since the cut removes positional defaults.
```

<!-- google-doc-style-resume -->

### §D.4 fork/gap-analysis.md, the row "Functions: function overloading (Carbon-native)" (D)

The row stays DONE. Three in-place edits of its evidence cell (line 60), in
commit D, so the row records the discharge only with the ledger (amended
2026-10-28, review fold: B-M5):

1.  After "the `--dump-cpp-ast` sibling overload_set_ast.carbon)." insert the
    first text below (it begins with a space).
2.  After "the documented divergence asserted on both sides in one program
    (rulebook R30)" insert the second, which cites `<P>`, the commit that
    holds the programs (rev 1 cited `<F1>`).
3.  Before " — ids provisional against the slices branch." insert the third.

<!-- google-doc-style-ignore -->

```text
 OV-4 landed (W-341 DISCHARGED <date>, fork/overload/ov4-plan.md): members take upstream's positional default values (an R32 realignment of F-009j) — a member accepts from its parameter count less its trailing defaulted parameters up to its parameter count, the probe converts the supplied arguments only and the ordinary call fills the rest, first match decides between members that both accept, a declaration that differs from a member only in a default is `RedeclParamDiffers`, and a diagnosed non-trailing default counts only its trailing defaults (check and lower goldens function/overload/default_values.carbon and interop/cpp/function/export/overload_set_default.carbon).
; at OV-4, functions/overloading_default_values (hand-derived EXPECT) and the DIFF-1 pair functions/overloading_default_values_diff, 9/9 container-measured on <P> (<pass>/0/<skip> over <total>, EXPECTED, not of record)
; OV-4's W-360 (generic members with defaults, 503f09037), W-361 (defaults of exported members, 9799a2326) and W-362 (the default count, into function.cpp), all at UA-3
```

<!-- google-doc-style-resume -->

### §D.5 fork/ORCHESTRATION.md (D)

Header, prepended to "Last updated:" as each workstream does:

<!-- google-doc-style-ignore -->

```markdown
Last updated: <date> (OV-4, `overload fn` members with upstream's default
parameter values (W-341), is implemented and reviewed on
claude/carbon-fork-0-1-ov4 on trunk's base; it merges after PR 66 and before
EH-C; see the paragraph dated <date> below; the earlier 2026-10-28 text
follows).
```

<!-- google-doc-style-resume -->

Dated paragraph, after the paragraph dated "2026-10-28 (04:47 UTC)"; it names
every OV-4 commit before D and D itself as "this records commit", never a sha
it cannot know (amended 2026-10-28, review fold: B-m4):

<!-- google-doc-style-ignore -->

```markdown
<date> (<time> UTC): OV-4 is IMPLEMENTED AND REVIEWED on
claude/carbon-fork-0-1-ov4 (fork/overload/ov4-plan.md rev <n>; commits <C1>,
<F1>, <P>, <fix commits> and this records commit; base trunk 66bd2ba90). An
`overload fn` member with upstream's positional default values is called with
a defaulted argument omitted: the arity step takes the plain call's range, the
probe converts the supplied arguments and the ordinary call fills the rest;
gate (iii) looks through a default value, member identity ignores defaults (a
default-only difference is `RedeclParamDiffers`), and a diagnosed non-trailing
default counts only its trailing defaults, which also fixes the plain path's
aborts at pattern_match.cpp:1275 and :1805. F-009j and the match test's CLOSED
paragraph are rewritten to name upstream's mechanism (R32), quoted at 0421bf3b4.
Measured container-local: <gate> of <gate> goldens, <pass>/0/<skip> over
<total>. Residues for UA-3: W-360 (503f09037), W-361 (9799a2326, 8fdc8ebc3,
c7de72757), W-362 (function.cpp). No held PR is amended. OV-4 merges after PR
66 and before EH-C (W-346) through M, F-M, L-R and L (the plan's section 3).
```

<!-- google-doc-style-resume -->

Branches row, after `claude/carbon-fork-0-1-rg1`'s:

<!-- google-doc-style-ignore -->

```markdown
| `claude/carbon-fork-0-1-ov4` | IMPLEMENTED AND REVIEWED (base trunk 66bd2ba90) — OV-4, `overload fn` members with default parameter values (W-341 DISCHARGED; W-360 to W-362 filed for UA-3; W-363 and W-364 unused), at <head>; gap row "Functions: function overloading (Carbon-native)" stays DONE; expected <gate> of <gate> and <pass>/0/<skip> over <total>; merges after PR 66 and before EH-C, through M, F-M, L-R and L. |
```

<!-- google-doc-style-resume -->

Next actions item 6: its first sentence, from "**R32 work" through "on trunk's
base." (trunk :1086-1090), is replaced by the text below, and the item's
second sentence ("RG-1 (W-342 discharged; ...") follows on the same line,
the rest of the item unchanged and rewrapped by hand within the item:

<!-- google-doc-style-ignore -->

```markdown
6.  **R32 work from the 2026-10-26 weekly check and RG-1 (2026-10-28)**: W-341
    (OV-4) is implemented and reviewed on claude/carbon-fork-0-1-ov4, merging
    after PR 66 and before EH-C and UA-3 through M, F-M, L-R and L
    (fork/overload/ov4-plan.md section 3); its residues W-360, W-361 and W-362
    go to UA-3.
```

<!-- google-doc-style-resume -->

### §D.6 The register rows (L-R, after PR 67 lands)

Inserted into fork/register/rg1-plan.md's §2.T2 table, directly after T2.7's
row, verbatim but for `<date>` (L-R's `date -u +%F`) and `<tip>` (the upstream
sha L-R checks at); in a cell `\|` is the pattern's `|`, as that plan's §2 says
(amended 2026-10-28, review fold: RR1-m4; rev 2 gave no table rows):

<!-- google-doc-style-ignore -->

```markdown
| T2.8 | F-009j: upstream's positional default values on `overload fn` members (docs/design/functions_overloading.md's match-test CLOSED paragraph and F-009j item as OV-4 rewrote them; call.cpp `GetExplicitArityRange` and its probe; fork/overload/ov4-plan.md D-OV4-1 to D-OV4-5; added <date> by OV-4's L-R) | at 0421bf3b4, re-read at <tip>: p002200:471 `class C4 { fn M[me: Self](p: i32 = 4); }` and :474 "using the default value of `4` for `p` when"; classes.md:2186 "### Optional named parameters", :2188 "Structs are being considered as a possible mechanism for implementing optional", :2202 `.descending: bool = false} = {}) {` and :2207 `SortIntVector(&v);`; upstream check/call.cpp:49-50 "the range [callee_arity - arity_lower_bound_margin, callee_arity]. This allows arity matching when the callee has default arguments for some" and :241 `function.default_value_arity);`; function.cpp:677 "patterns, ensure that if a subpattern provides a default value, all" and :682 "TODO: per https://github.com/carbon-language/carbon-lang/issues/7529, this"; pattern_match.cpp:950 "If there's no scrutinee supplied, supply the default value instead."; handle_pattern_list.cpp:185 "default value is not a constant"; check T2.8: `git grep -c -w 'default_value_arity'` over toolchain/check = 3 | ALIGNED (fork/overload/ov4-plan.md §0.8) | upstream designs another optional-parameter mechanism or removes positional defaults (W-341's) | W-355; W-341 DISCHARGED at OV-4 |
| T2.9 | F-009j: the plain-call rule for an `overload fn` member with default values: a member accepts a call at k explicit arguments exactly when its ordinary call does, its probe converts the k supplied arguments, and the selected member's ordinary call fills the rest; the tie-break between two members that both accept stays T2.6's (fork/overload/ov4-plan.md D-OV4-1, D-OV4-2 and D-OV4-11; added <date> by OV-4's L-R) | silent at 0421bf3b4, re-read at <tip>, check T2.9: `git grep -c -i -E 'overload(ed\|ing)? (fn\|function\|set)s?\|function overloading'` over docs/design, proposals = 40: no upstream text on default values with overloading; the nearest passage, T2.6's pattern_matching.md:696 "We do not yet have an approved design for overloaded functions, but it"; for a member whose template-dependent default fails in a specific, p002200:214 `-   Substitution failure is an error. In C++, [the SFINAE rule](#terminology)` and README.md:2828 "One difference from C++ templates, Carbon template instantiation is not" | NONE (fork/overload/ov4-plan.md §0.8) | an accepted upstream overloading design, or upstream text on default values with overloading | W-355 |
```

<!-- google-doc-style-resume -->

Appended to fork/register/rg1-checks.tsv (id, kind, flags, pattern, paths,
count at the tip), after a `#` comment line naming this plan and the two rows
(amended 2026-10-28, review fold: A-m2 / B-m1 / RR1-m4; measured at e6fddcf97
and 0421bf3b4 with PR 67's check_greps.sh: "checked 2 silence checks, 0
failed"):

<!-- google-doc-style-ignore -->

```text
# OV-4 (fork/overload/ov4-plan.md section 0.8 and D-OV4-15; added at land time by commit L-R): rows T2.8 (F-009j's default values) and T2.9 (the plain-call rule for a member with defaults) of fork/register/rg1-plan.md section 2.T2.
T2.8	G	-w	default_value_arity	toolchain/check	3
T2.9	G	-i -E	overload(ed|ing)? (fn|function|set)s?|function overloading	docs/design proposals	40
```

<!-- google-doc-style-resume -->

Appended to fork/register/rg1-quotes.tsv (path, line at the tip, verbatim
substring), after the same kind of comment line (amended 2026-10-28, review
fold: A-m1 / B-M1 / RR1-m3 / RR1-m4: rev 3 adds function.cpp:677, the
trailing-default rule C.1 quotes; measured at e6fddcf97 and 0421bf3b4 with
PR 67's check_quotes.sh: "checked 16 quotes, 0 failed"):

<!-- google-doc-style-ignore -->

```text
# OV-4 (fork/overload/ov4-plan.md section 0.8 and D-OV4-15; added at land time by commit L-R): the quotes of rows T2.8 and T2.9 of fork/register/rg1-plan.md section 2.T2.
toolchain/check/call.cpp	49	// the range [callee_arity - arity_lower_bound_margin, callee_arity]. This
toolchain/check/call.cpp	50	// allows arity matching when the callee has default arguments for some
toolchain/check/call.cpp	241	function.default_value_arity);
toolchain/check/pattern_match.cpp	950	// If there's no scrutinee supplied, supply the default value instead.
toolchain/check/function.cpp	677	// patterns, ensure that if a subpattern provides a default value, all
toolchain/check/function.cpp	682	// TODO: per https://github.com/carbon-language/carbon-lang/issues/7529, this
toolchain/check/handle_pattern_list.cpp	185	"default value is not a constant");
proposals/p002200-template-generics.md	471	class C4 { fn M[me: Self](p: i32 = 4); }
proposals/p002200-template-generics.md	474	// using the default value of `4` for `p` when
proposals/p002200-template-generics.md	214	-   Substitution failure is an error. In C++, [the SFINAE rule](#terminology)
docs/design/README.md	2828	One difference from C++ templates, Carbon template instantiation is not
docs/design/classes.md	2186	### Optional named parameters
docs/design/classes.md	2188	Structs are being considered as a possible mechanism for implementing optional
docs/design/classes.md	2202	              .descending: bool = false} = {}) {
docs/design/classes.md	2207	SortIntVector(&v);
docs/design/pattern_matching.md	696	We do not yet have an approved design for overloaded functions, but it
```

<!-- google-doc-style-resume -->

The rows use the TSV's tab separators (shown as tabs above). At L-R both
scripts are re-run at that day's tip over the whole tables; a failed row is a
weekly-check finding filed under W-355, never an edit of the expected count.

### §D.7 The land-time records (L)

Written by L after M, F-M and L-R, on the merged branch (amended 2026-10-28,
review fold: B-M3; rev 1 named them without texts). The ledger: appended to
W-341's `notes`:

<!-- google-doc-style-ignore -->

```text
 Landed <date>: M <M> merged trunk <trunk> (PR 51 to PR 67); F-M <F-M or none>; L-R <L-R> (register rows T2.8 and T2.9); <gate> of <gate> goldens and <pass>/0/<skip> over <total> programs on <L's parent>, container-local, EXPECTED, not of record.
```

<!-- google-doc-style-resume -->

The decision log: appended to the entry OV-4 as its last paragraph:

<!-- google-doc-style-ignore -->

```markdown
_Landed <date> (OV-4, land-time commits)._ M <M> merged trunk <trunk>, which
holds PR 51 to PR 67, into claude/carbon-fork-0-1-ov4 by
fork/overload/ov4-plan.md section 6.2's rules; F-M <F-M, or "none: autoupdate
changed nothing">; L-R <L-R> added the register rows T2.8 and T2.9, checked at
upstream <tip> (<n> silence checks and <m> quotes, 0 failed). Measured on <L's
parent>, container-local, EXPECTED, not of record: <gate> of <gate> goldens,
conformance <pass>/0/<skip> over <total>, bullets <bullets>.
```

<!-- google-doc-style-resume -->

ORCHESTRATION: the header prepended as D.5's was, the dated paragraph after
the last landed paragraph, OV-4's Branches row's state replaced by "MERGED WITH
THE LANDED TRUNK at <head>", and item 6's OV-4 sentence replaced by the third
text below:

<!-- google-doc-style-ignore -->

```markdown
Last updated: <date> (OV-4, `overload fn` members with upstream's default
parameter values (W-341), is merged with the landed trunk and re-verified;
see the paragraph dated <date> below; the earlier <date of the previous
header> text follows).
```

<!-- google-doc-style-resume -->

<!-- google-doc-style-ignore -->

```markdown
<date> (<time> UTC): OV-4's branch is merged with trunk <trunk> (PR 51 to PR
67 landed) and re-verified: M <M>, F-M <F-M or none>, L-R <L-R>, L (this
commit); <gate> of <gate> goldens and <pass>/0/<skip> over <total>,
container-local, EXPECTED, not of record. It merges after PR 66 and before EH-C
(W-346); W-360, W-361 and W-362 go to UA-3.
```

<!-- google-doc-style-resume -->

<!-- google-doc-style-ignore -->

```markdown
W-341 (OV-4) is merged with the landed trunk and re-verified on
claude/carbon-fork-0-1-ov4 (fork/overload/ov4-plan.md section 3), merging
before EH-C and UA-3; its residues W-360, W-361 and W-362 go to UA-3.
```

<!-- google-doc-style-resume -->
