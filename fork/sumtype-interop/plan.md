<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Sum-type interop plan: `std::optional` and `std::variant` (SV-1)

**Status:** rev 1 (2026-10-20), for the two adversarial plan reviews of R29(c).
Workstream SV-1 is W5 slice 4 of fork/w5-choice/plan.md (§4 "S4"): the
transparent `std::optional` / `std::variant` interop mapping, the OPEN half of
ledger item W-011, under gap row 68 ("Control flow: matching — sum-type
consumption incl. std::variant/std::optional interop", PARTIAL). Branch
`claude/carbon-fork-0-1-sv`, cut from trunk 5674fe88b, whose toolchain and core
trees are identical to the fork's trunk toolchain state 0bdce60a5 (the UA-1
advance over the upstream cut c1e83b0b7). Trunk has since gained two
records-only commits, f3156a375 (the weekly upstream check of 2026-10-19:
upstream 3056e7e31 is 85 commits past the cut, 96 conflicting files, the cut
holds) and 254b935b2 (TP-1 is PR 61, held open); neither touches `toolchain/`
or `core/`. Merge position: after PR 61 (TP-1), last of the held queue (§1.15).
Ids: fork design decision **F-020** is minted here (the mapping targets,
§1.1); SV-1 reserves **W-275 to W-294** for its residues (§1.16).

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
alternative patterns consume it, with exhaustiveness. `StdOptional(T)` and
`Core.Optional(T)` convert into each other through `Optional`'s public API; the
class `Core.Optional` is not redesigned (PR 56 and PR 57 own it). Every shape
outside the mapping is diagnosed (§1.11), never a crash, never a silent wrong
value. All of it is prototyped: the prototype (§0.6) runs every IN shape of
this plan against C++ oracles and passes the trunk gate apart from four
mechanical refills.

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
`ptime.py` times the check phase). Toolchains:

-   **trunk**: `/home/user/carbon-build/carbon-trunk/install/bin/carbon`,
    version `0.0.0-0.dev+0bdce60a5`, the baseline of every comparison; its
    file_test passes 1942 of 1942 and its conformance run is 128 PASS / 0 FAIL
    / 22 SKIP over 150, identical to the scoreboard of record
    (carbonbuild README, "Validation record").
-   **nightly**: the upstream nightly 2026.10.12, a differential oracle only
    (R30).
-   **v1**, **v2** and **v3**: the prototype of §0.6, the trunk build's
    objects relinked with the patched translation units of §2 (the relink
    recipe of TP-1, `$P/bin/relink.sh`) into `/dev/shm/sv1-planner3/v1`,
    `.../v2` and `.../v3`,
    with an install tree whose `core/` carries the new prelude file. A
    relinked prototype cannot change an X-macro list (`diagnostics/kind.def`),
    so the prototype emits each new diagnostic as `context.TODO` with the same
    facts, and the final diagnostics of §1.11 are hand-predicted (said again at
    each one). The relinked binaries' `carbon link` compiles the prelude's
    runtime objects from the trunk build's compiled-in prelude list
    (`runtimes_build_info.h`, generated from `//core:prelude_files`,
    core/BUILD:11 `glob(["prelude/**/*.carbon"])`), which lacks the new file,
    so prototype objects are linked with trunk's `carbon link`; the real build
    globs the new file in, and the prelude file declares only generics, whose
    specifics are emitted into the user's object (§0.6).

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

### §0.3 The import path, and where each mapping step hooks in

Read for this section: toolchain/check/cpp/import.cpp, type_mapping.cpp,
custom_type_mapping.cpp, impl_lookup.cpp, thunk.cpp, overload_resolution.cpp,
call.cpp, toolchain/check/convert.cpp, refutable_binding.cpp, handle_match.cpp,
handle_choice.cpp, pattern_match.cpp, type.cpp.

| Step | Where today | What a mapping needs there |
| --- | --- | --- |
| Recognize the C++ specialization | custom_type_mapping.cpp:20-123, the matcher library (`StdClassTemplate`, `TemplateArgumentsAre`); `GetCustomCppTypeMapping` at :125-141 returns `Str` for `std::string_view` (:89-102; the ledger's evidence cites :92-104) and `Span` for a dynamic-extent `std::span` (:106-122, SL-2's D-SL-8) | two matchers, `StdOptional` (one type argument) and `StdVariant` (one pack of types), and a classifier returning the alternatives in C++ order |
| Replace the imported type | import.cpp:1333-1360 `LookupCustomRecordType`: `Str` imports as `Core.String`, `Span` as `Core.Slice(T')`; the replacement is sound only because the layouts are identical (`{ptr, size}`, D-SL-8's layout premise) | **nothing**: the layouts differ (§0.5), so the class must stay the imported type (§1.1, F-020) |
| Convert a value | convert.cpp `PerformBuiltinConversion` (:1529-1800); a C++ class source with a Carbon class target otherwise falls through to impl lookup and the C++-conversion path, which tries to export the target (the m20 TODO) | a hook before ":1798 Split the qualifiers off the target type": C++ class value to its sum type, and back |
| Synthesize a witness from C++ accessors | impl_lookup.cpp:600-656 `BuildCppContiguousRangeWitness` (SL-2's `Core.CppContiguousRange`, core/prelude/types/cpp/slice.carbon:32-37): each witness entry is an imported C++ member function, `data()` and `size()`, found by `LookupCppMemberWithResultType` (:574-598) | not used (§7.2 R-B): `std::get<I>` and the index-tagged construction are not single member functions |
| Call a C++ function with an integer template argument | call.cpp:42-64 splits a Carbon call's arguments into template and function arguments only for types and templates (`IsTemplateArg`, :30-36); overload_resolution.cpp:266 `PerformCppOverloadResolution` takes `template_arg_ids` | the conversion calls `std::get<I>(v)` and `v.emplace<I>(x)` through `PerformCppOverloadResolution` directly with an integer literal `I`, which no Carbon spelling can do today |
| Generate C++ thunks | thunk.cpp:399 `IsCppThunkRequired`, :1037 `BuildCppThunk`, :1549 `PerformCppThunkCall`; :370-398 decides the exception fence | nothing new: every accessor call goes through the existing call path, which builds `<callee>__carbon_thunk` where it already would (§0.5) |
| Offer a Carbon argument to C++ overload resolution | type_mapping.cpp:695 `InventClangArg`, which maps the argument's type with `MapToCppType` (:504) | the sum type of an argument maps to its C++ class before `MapToCppType`, which would otherwise try to export the `Core` choice (the m20 TODO) |
| Gate a `match` scrutinee | handle_match.cpp:190-206 calls `CheckRefutableScrutinee` (refutable_binding.cpp:137-207), shared with `if`-`let`, `while`-`let` and `let`-`else`; its shape gate `IsSupportedScrutineeType` (:83-129) admits integers, `bool`, matchable choices (`IsMatchableChoiceType`, pattern_match.cpp:499), tuples and structs of them; :199-202 emits the TODO | convert an admitted C++ sum value to its sum type after `RequireCompleteType` (:186-197) and before the shape gate |
| Admit a payload | type.cpp:337-354 `IsInSliceChoicePayloadType`: the unqualified, transitively adapted type is an integer, float, `bool` or pointer type, or `()` (D-EH-2); consulted by handle_choice.cpp:760 and the per-specific hook eval_inst.cpp:310, :342 | the alternatives' Carbon types must pass it; nullable C++ pointers need D-SV-8 |

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
    walk does not strip (§1.8, D-SV-8).
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

**Valueless variants.** A `std::variant` becomes valueless only when an
alternative's construction throws during assignment or `emplace`. For the
admitted alternatives (§1.3: scalars, pointers, `std::monostate`) no
construction can throw, so an admitted variant is never valueless. Even so the
conversion never reads a wrong value: it tests `index()` against 0 to n-2 and
calls `std::get<n-1>` in the last arm, which on a valueless variant throws
`bad_variant_access` into the B0 fence, which terminates with its one-line
message (`carbon: C++ exception escaped into Carbon through ...;
terminating`).

### §0.6 Prototypes and measurements

**v1** (first drafted 2026-10-15 at `sv1/planner/proto/diff/v1.diff`, rebuilt
and re-measured for this revision), **v2** (v1 plus §1.11's diagnostic
reasons, the W-036 text and the mismatch check; `$P/proto/v2.diff`) and **v3**
(v2 plus the `Core.Optional` match view of §1.7; `$P/proto/v3.diff` against
5674fe88b, its filled goldens `$P/proto/goldens-v3/`) implement §2 except the
X-macro diagnostics. Each was relinked over the trunk build and measured:

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
-   **OUT shapes** each produce one precise error and no crash (§1.11).
-   **Conformance programs**: the six programs of §1.13 agree byte for byte
    with their C++ oracles on v3 (`$P/runs/progs-v3.txt`: DIFF-PASS 11, 14,
    14 and 4 lines, and 7 for match_core_optional_diff; the arbiter prints 7,
    exit 0), and the five that do not need the view do on v1 and v2 too.
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
-   **Goldens**: the seven golden sources of §1.12 autoupdate to a fixpoint
    on v3 (the first pass writes, the second renumbers only
    fail_sum_types.carbon's `[[@LINE+N]]` offsets, the third writes nothing)
    and pass in test mode; the CHECK-stripped sources of Appendix B refill to
    byte-identical goldens. One source fix was found by the run: the
    constant-scrutinee golden needs `min_prelude/full.carbon` for
    `Core.EqWith`.
-   **Prelude cost**: check phase of a trivial file, 60 alternating runs each
    (`$P/bin/ptime.py`): trunk min 213 ms / p10 223 ms; with this plan's
    prelude file (nine choices, two bridge impls) 221 / 235 ms (+5% at p10);
    with the access-interface alternative of §7.2 R-B at four arities 224 /
    246 ms, at eight 252 / 270 ms (+21%). The full gate's wall time is
    unchanged (31.47 s against trunk's 31.42 s): file_test mostly uses the
    min prelude.
-   **The access-witness alternative** (§7.2 R-B), measured in user code on
    trunk with no toolchain change (`$P/../planner/proto/u01_user_conv.carbon`,
    a user `choice` plus an interface implemented for `Cpp.std.optional(i32)`
    through `has_value()`/`value()` and a blanket `ImplicitAs`): the C++ to
    Carbon direction runs (7 -1 8); the reverse (`u02`) cannot pass the
    choice to a C++ parameter (`no matching function for call to 'TakeOpt'`),
    because C++ overload resolution never sees Carbon `ImplicitAs` impls.

### §0.7 Collisions with the held PRs

Held PRs, none merged, merge order of record (fork/ORCHESTRATION.md on trunk
254b935b2): PR 53, PR 51, PR 52, PR 60 (SC-1), PR 54, PR 55, PR 56 (OP-1),
PR 57 (OP-2), PR 58 (DD-1) through its state L integration commit, PR 59
(VA-1), PR 61 (TP-1) through its land-time commits, then SV-1. Each branch's
diff from its merge base with 5674fe88b, against the files SV-1 changes
(`git diff --numstat $(git merge-base 5674fe88b <branch>) <branch>`):

| PR, branch head | Files shared with SV-1 | Nature | Rule at merge time |
| --- | --- | --- | --- |
| PR 56, OP-1, 379f20f67 | core/prelude/types/optional.carbon (+73/-2: the `EqWith`/`OrderedWith` impls appended, `prelude/operators/comparison` imported) | SV-1 does not edit optional.carbon; its new prelude file imports it and calls `Optional(T).Some`, `.None()`, `HasValue()`, `Get()` only | none textual; the bridge of §1.7 re-measured over PR 56 |
| PR 57, OP-2, 628273444 (build `/home/user/carbon-build/carbon-op2`, toolchain-identical to the head, `git diff --stat 9f9ccd768 628273444 -- toolchain core` empty) | optional.carbon (+111/-8; four hunks: imports at :10-21, `let Type: Destroy` at :24-30, `Get` declared and defined at the end with a fail-stop on an empty value at :37-51, comparisons and the `Get` definition appended at :202+); convert.cpp (+5/-2, the `MaybeUnformed` value-representation check at :1690-1700); custom_witness.cpp (+32, an adapter destroyed as its adapted type); the golden decayed_param.carbon (refilled by PR 57 and by SV-1's prelude file, §0.6) | the bridge calls `Get()` only after `HasValue()`, so OP-2's fail-stop is never reached; D-SV-8 walks `Optional(T*)`'s adapter chain, which OP-2 leaves as `MaybeUnformed(T*)` (optional.carbon:188-203, outside its hunks); OP-2's convert.cpp hunk is 100 lines above SV-1's hook | measured now: the bridge's user-level copy (`$P/probes/c01_optional_bridge.carbon`) prints 5 6 9 on the trunk and on the OP-2 build; at implementation, the composition mirror of §8.6; at merge, decayed_param.carbon is refilled once by autoupdate on the merged tree |
| PR 60, SC-1, 40a76ab81 | convert.cpp (+94/-7: `CanRemoveQualifiers` :1502, `DiagnoseConversionFailureToConstraintValue` :1505-1540, one line in `PerformBuiltinConversion` at :1979 of its base, `AddConvertActionIfDependent`, `PerformAction`, `Convert`); type.cpp (+8, a new function); toolchain/check/BUILD (+2, `structural_conformance.{cpp,h}` at :73 and :147 of its base) | SV-1's convert.cpp hunk is one block before "Split the qualifiers off the target type", no SC-1 hunk within 100 lines; SV-1's type.cpp hunk is inside `IsInSliceChoicePayloadType`, SC-1's is a separate function; BUILD: SV-1 adds `cpp/sum_type.{cpp,h}` after `cpp/overload_resolution.*` (:37, :104), alphabetical and away from SC-1's lines; SC-1's own impl_lookup.cpp is toolchain/check/impl_lookup.cpp, which SV-1 does not touch | textual only; `patch --dry-run` of the SV-1 diff onto SC-1's head at implementation (§8.6) |
| PR 59, VA-1, b0822a744 | convert.cpp (+114: `ConvertTupleToArray` :502, `TryToCompleteClassType` :1286, and a pack-conversion block inserted in `PerformBuiltinConversion` just before "Function types can convert to C++ function pointer types", 11 lines above SV-1's hook); type.cpp (+5, a new function); cpp/export.cpp (+12) | SV-1's hook and VA-1's block are separate hunks with disjoint context; SV-1 does not touch export.cpp | textual only; the dry run of §8.6 |
| PR 61, TP-1, e408ad4d6 | convert.cpp (+560/-29; hunks in the aggregate conversions :407-1240, `CategoryConverter` :2176, `PerformCategoryConversion` :2309-2459, `PerformAction` :2441-2489; none in `PerformBuiltinConversion` after :1240) | no shared function | textual only; the dry run of §8.6 |
| OX-1, parked (no PR) | none: SV-1 does not touch cpp/export.cpp or cpp/thunk.cpp | OX-1's root cause (its plan's "Parking record") is an export into the Sema that Carbon's own resolution then consults. SV-1 exports nothing: its conversion calls existing C++ functions through the existing call path, and the reverse mapping of §1.5 only names a specialization of an existing C++ class template (`std::optional<int>`) as the invented argument type of one overload resolution, declaring no name in any C++ scope; a `Core.CppCompat` choice in an exported signature stays the existing export TODO (`s16`, W-049) | none |
| PR 51, 52, 53, 54, 55, 58 | none in check, lower or core (PR 55 touches cpp/export.cpp, which SV-1 does not) | none | none; PR 58's state L commit is records-only for SV-1's files |

**Measured now (2026-10-20).** The prototype's whole diff (`$P/proto/v3.diff`,
toolchain and core) was dry-run with `patch -p1 --dry-run` onto a `git
archive` of each branch head: it applies to PR 56, PR 57, PR 60, PR 59 and
PR 61, with line offsets only (convert.cpp's hook at +3, +14, +114 and +378
lines; one fuzz-1 include hunk on PR 61's convert.cpp; type.cpp at +5 and +8)
and no rejected hunk (`$P/runs/dry-*.log`). The prelude file composes with PR
57's prelude and toolchain: sum.carbon added to the OP-2 build's `core/`
compiles, and `$P/probes/o/o04_bridge_stdoptional.carbon` (both bridge
directions, `.None` through the bridge, `Core.Optional(i32*)` from
`StdOptional(i32*).None`) prints 5 6 -1 9 on the OP-2 build exactly as on v3.
The scratch mirrors that compose the toolchain change with each branch's own
objects and gate its testdata are the implementer's (§8.6).

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
one-sentence break condition. F-020 is the one fork design decision; the
D-SV decisions implement it.

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
unchanged; it and the class `Core.Optional(T)` convert into each other by
value (`ImplicitAs` both ways, through `Optional`'s public API), and a
`Core.Optional(T)` scrutinee is matched as its `StdOptional(T)` view (§1.7).

**Why this is a fork design decision (F), not a consequence of recorded
ones.** fork/w5-choice/plan.md:500-503 said `std::optional<T>` maps to
`Core.Optional(T)`. Since then D-EH-1 kept `Core.Optional` a class, PR 56 and
PR 57 redesign it as a class, and a class cannot be matched (§0.4), so that
target cannot satisfy W-011's arbiter. F-020 changes the target to a choice and
relates it to `Core.Optional` by conversion; and it answers SF-8, which the
user deferred to this slice with a steer.

**The steer, item by item** (fork/decision-log.md:465-469):

-   "tagged unions are the first-class construct (`choice`)": both targets
    are `choice` types; nothing new is introduced beside `choice`.
-   "any Core.Variant prelude name would be sugar over a generic choice at
    most": `StdVariant1` to `StdVariant8` are exactly generic choices, with no
    members, no impls of their own and no API; they live in `CppCompat`, the
    interop namespace that already holds `Long32`, `ULong64` and `Exception`,
    and are named for the C++ type they mirror. They are not a vocabulary type:
    Carbon code that does not touch C++ has no reason to name them, and none of
    them is the design's answer to "a Carbon variant type".
-   "the default lean is the anonymous/synthesized-choice mapping": the user
    never writes the sum type to match a C++ value; the toolchain synthesizes
    the specific from the C++ specialization and the scrutinee converts to it.
    The choice is synthesized as a specific, not as a new entity.
-   "introducing a Variant vocabulary type requires affirmative
    justification": the affirmative justification for declaring the nine
    generics in the prelude rather than synthesizing one choice entity per C++
    specialization is measured: (1) no choice can exist without a source
    declaration (handle_choice.cpp:84 is the only place `is_choice` is set), so
    a per-specialization entity would duplicate handle_choice.cpp's
    alternatives table, F-007k layout, alternative constants and factories,
    and `Copy`/`Destroy` witnesses outside the parse tree; (2) a specific is
    one canonical type in every file and library, so a value returned by one
    library is matched in another (`xlib`, §0.4 item 1), where per-file
    synthesized entities would need a cross-file identity rule; (3)
    upstream's own sketch of the Carbon counterpart of `std::variant` is a
    per-arity generic choice (p0157, §0.9).

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
-   (b) `Core.Optional(T)` itself as the target, with a consumption path for
    a non-choice: the design's path for matching a class is the `Match`
    interface (sum_types.md:91-246), which neither the fork nor upstream
    implements; rejected for 0.1. F-020 gets the same effect for
    `Core.Optional` with the view of §1.7, without the `Match` machinery.
-   (c) `std::variant` deferred (SF-8 option (c)): rejected, the milestone
    bullet names both types and the prototype maps both.
-   (d) Make `Core.Optional` a choice: rejected; it contradicts D-EH-1 and
    the held PR 56 and PR 57, loses the pointer niche that
    `Core.Optional(T*)`'s C++ mapping and the entry point's
    `argv: Core.Optional(char*)*` rely on, and is W-058's to decide (§7.2 R-E).
-   (e) An access interface whose witness the toolchain synthesizes, with
    the conversions as blanket prelude impls (the `CppContiguousRange`
    shape): rejected, measured in §0.6 and §7.2 R-B.

**Break condition.** If Carbon gains variadic `choice` declarations, the nine
generics collapse into `StdOptional` and one variadic `StdVariant(... each
T)` keeping the `Alt<i>` names; if the `Match` interface is implemented, the
C++ classes and `Core.Optional` implement it and the scrutinee conversion is
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
    (clang's `isTriviallyCopyable()` and `hasTrivialDestructor()`), so that
    reading it by value and then dropping the C++ temporary, which the
    scrutinee gate discards without a destructor call (refutable_binding.cpp
    :204-205, "Destroy any temporaries"), is exact, and the C++ object built
    by the reverse conversion needs no destructor;
2.  a `std::variant` has 1 to 8 alternatives;
3.  no alternative type is cv-qualified or a reference type; and
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
assignment, `w03`); a trivially copyable struct or a nested `std::optional`
or `std::variant` breaks rule 4 (`s06`, `a11`, `w06`, `w07`). Never a crash and
never a silent wrong value: the rule is checked before the specific is formed,
so SF-6's per-specific check (eval_inst.cpp:310-345) is never the one that
fires.

SF-6 (decision log, W5 SF-1..8) allows "trivially-copyable +
trivially-destructible payloads" in 0.1, and the implementation's predicate is
narrower (no aggregates); rule 4 follows the implementation, and the gap
between the two, trivially copyable structs, is W-010's residue, recorded for
this mapping as W-275.

_Break condition:_ when SF-6's predicate admits aggregates, rule 4 admits
them with no change here; when non-trivial payloads get discriminant-
dispatched copy and destroy (SF-6's post-0.1 item), rule 1 is lifted for the
classes whose alternatives qualify, with the C++ temporary destroyed instead
of discarded.

### §1.4 D-SV-4: the conversion from C++ to Carbon

**Where.** `TryConvertCppSumType` (new, toolchain/check/cpp/sum_type.cpp) is
called from convert.cpp's `PerformBuiltinConversion` just before "Split the
qualifiers off the target type" (convert.cpp:1798), so every implicit and
explicit conversion, initialization, argument and return reaches it, and from
the scrutinee gate (§1.6). It returns `None` when neither side is a sum type
of the other, so every other conversion is untouched.

**What SemIR a converted value is.** The C++ value is first made a value
expression (`ConvertToValueExpr`), so the accessors run on a `const` object
and their `const&` overloads are selected; nothing is moved from. Then one
`temporary_storage` of the sum type is initialized in one of several blocks,
the shape of the catching thunk's result (thunk.cpp
`PerformCppCatchingThunkCall`):

-   `std::optional<T>`: `has_value()` is called once; if true, the block
    calls `value()` and initializes the storage with `StdOptional(T').Some`
    of it; otherwise it copy-initializes it from the constant
    `StdOptional(T').None`; both branch to a convergence block, where the
    storage is read as a value.
-   `std::variant<T0, ..., Tn-1>`: `index()` is called once; arms 0 to n-2
    test `index() == i` (through `Core.EqWith` on `index()`'s own type, `u64`
    on Linux), and the last arm is the fall-through; arm `i` calls
    `std::get<i>(v)` (or makes `()` for `std::monostate`) and initializes the
    storage with `StdVariant<n>(...).Alt<i>` of it.

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

**Function scope.** The conversion branches, so it needs a function body.
Outside one (a file-scope `let` initializer) it emits the existing
upstream TODO "Control flow expressions are currently only supported inside
functions." with which every other branching expression is rejected there
(handle_if_expr.cpp:75-78, region_stack.h:39-43; measured `t01` on trunk and
`s15` on v2), and returns an error: one root cause, filed as W-036.

**Valueless.** Unreachable for admitted alternatives, and fail-stop by the B0
fence if ever reached (§0.5).

_Break condition:_ if a reviewer or a measured case shows the per-arm cleanup
scopes leak or double-destroy a temporary, the arms are rebuilt as a call to a
synthesized Carbon function per specialization (one body, no caller-side
blocks), which also lifts the function-scope restriction.

### §1.5 D-SV-5: the conversion from Carbon to C++, and what is exportable

**Converting a sum value to the C++ class.** `TryConvertCppSumType` with a
`StdOptional`/`StdVariant<n>` source and its own C++ class as the target
default-constructs the C++ object (an empty `std::optional`; a `std::variant`
holding a value-initialized first alternative, which every admitted
alternative type has), then dispatches on the choice's discriminant
(`EmitChoiceDiscriminantTest`, pattern_match.cpp:573) and, in the active
alternative's block, reads the payload (`EmitChoicePayloadFieldAccess`, :1048)
and calls `emplace(x)` or `emplace<i>(x)`; a payload-free `None` emplaces
nothing, and a `()` payload calls `emplace<i>()`. The result is the C++
temporary, read as a value.

**Passing to C++.** `InventClangArg` (type_mapping.cpp:695) offers an argument
of a sum type to C++ overload resolution as its C++ class
(`MapCarbonSumTypeToCpp`, new: `std::optional`/`std::variant` named through
`LookupCppClassTemplate` and specialized with the mapped argument types), so
`Cpp.Take(StdOptional(i32).Some(5))` selects `Take(std::optional<int>)` or
`Take(const std::optional<int>&)`, and the argument conversion then runs the
reverse conversion (measured `s08`, `s09`, `s18`: 41 42 -1; 25 9 107; -1 6).
This happens before `MapToCppType`, which would otherwise try to export the
`Core` choice and hit the export TODO. A non-`const` lvalue reference
parameter rejects the temporary, by C++'s own rule (`w08`: `no matching
function for call to 'Reset'`).

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
| Carbon to C++: a sum value passed by value or `const&`; assigned or returned where the C++ class is expected | IN |
| A C++ caller of a Carbon function whose signature names the C++ class | IN (existing export) |
| A Carbon function whose signature names a `Core.CppCompat` sum type, called from C++ | OUT: the existing export TODO for `Core` package entities, "interop with non-identifier package name" (export.cpp:139-141; `s16`), W-049's |
| A sum value passed to a non-`const` lvalue reference parameter | OUT by C++'s rules |
| `Core.Optional(T)` passed directly where C++ takes `std::optional<T>` | OUT: spelled `o as Core.CppCompat.StdOptional(T)` (measured `w11`: 7); residue W-278 (§1.7) |

_Break condition:_ if an exported signature must name a sum type, the
export path maps it to the C++ class with a conversion thunk (W-049's
territory), and this table moves the row to IN.

### §1.6 D-SV-6: match consumption at the scrutinee gate

`CheckRefutableScrutinee` (refutable_binding.cpp:137-207), shared by `match`,
`if`-`let`, `while`-`let` and `let`-`else`, converts the scrutinee after
`RequireCompleteType` and before the shape gate `IsSupportedScrutineeType`:

-   an admitted C++ sum class converts to its sum type (§1.4); a non-admitted
    one is diagnosed with `CppSumTypeNotMapped` instead of the generic
    "match on unsupported scrutinee type" TODO, and checking of the form stops
    as the TODO did;
-   a `Core.Optional(T)` converts to its view `StdOptional(T)` (§1.7);
-   every other type is untouched, so the five existing scrutinee shapes keep
    their byte-identical paths (the gate's own comment, :176-184).

The scrutinee is then a value of a `choice` specific, and everything after it
is the existing choice machinery: `.Some(n: i32)`, `.None`, `.Alt<i>(...)`
resolve in the specific's scope (`ResolvePendingAlternative`), an unknown
alternative is the existing `MemberNameNotFoundInSpecificScope`, the arms test
the discriminant, payload bindings read the payload tuple, SF-7 coverage
applies, and a `default` after full coverage is `MatchDefaultNeverMatches`.

The SemIR of the arbiter's intended body without its `default` (the prototype,
`$P/runs/arb.semir`, `fn @Run`, abbreviated; `%optional` is the C++ class
`std::optional<int>`, `%StdOptional.4c3` its sum type):

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

### §1.7 D-SV-7: `Core.Optional`: the bridge, and its match view

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
7), and the bridge's user-level copy on the OP-2 build (`c01_optional_bridge`:
5 6 9, as on trunk).

**One conversion, not two.** A C++ `std::optional<T>` and `Core.Optional(T)`
convert into each other in one spelled step, `x as
Core.CppCompat.StdOptional(T)` (`w11`), not implicitly in one: `let c:
Core.Optional(i32) = Cpp.MaybeSeven();` stays the conversion error of `m20` (a
C++ class has no `ImplicitAs` to a `Core` class, and Carbon composes no implicit
conversions), and a `Core.Optional(T)` argument to a C++ `std::optional<T>`
parameter stays the argument error of `t04`. Both are residue W-278: an implicit
chain through the sum type is easy in `TryConvertCppSumType`, but overload
resolution would then need a C++ type for `Core.Optional(T)`, which today means
`T*` for pointer payloads (the nullable-pointer mapping) and would mean
`std::optional<T>` for others, a split that is `Core.Optional`'s design (W-058,
PR 56) to make.

**The match view (W-177).** OP-1 filed W-177 on row 68's bullet
("`Core.Optional` is not matchable (no `.Some`/`.None` patterns, `match` or
`if let`)", on PR 56's branch), with constraints on any fix: keep the `Try`
signature, the pointer ABI, the `HasValue`/`Get` names that `for` calls, and
the C++ mapping's name case; and the break condition "`.Some` and `.None`
patterns over `Core.Optional` are implemented, by `Match` for classes or by a
`choice` that keeps those constraints". The scrutinee gate converts a
`Core.Optional(T)` scrutinee to `StdOptional(T)` through the bridge
(`GetCoreOptionalMatchView`, §2.4): the class, its API and its storage are
untouched, so every constraint is kept, and `.Some`/`.None` patterns,
`match`, `if`-`let`, `while`-`let` and `let`-`else` work on it. Measured on
v3 (`$P/probes/o/`): `Core.Optional(i32)` in both states (4, -1), a
`Core.Optional(i32*)` whose `.Some` binds the non-null `i32*` (9) and whose
`None` is the null pointer, `if`-`let` (12), a generic `T: Copy & Destroy`
(1 0), `.None` beside `default` (1); and the program
match_core_optional_diff against its C++ oracle (7 lines). The conversion
copies the held value (`Get()` returns a copy), which is how the payload of
any choice is bound; a symbolic `T` that is not `Copy & Destroy` has no bridge
impl and gets the standard conversion error. The view is not a redesign of
`Optional`: no line of optional.carbon changes.

_Break condition:_ if W-058's design or the owner wants `Core.Optional`
matched without a copy, the `Match` interface or a choice-based `Optional`
replaces the view (F-020's break conditions); if the name
`Core.CppCompat.StdOptional` reads wrong in a pure-Carbon diagnostic (an
unknown alternative on a `Core.Optional` scrutinee names it,
`core_optional_view.carbon` `fail_unknown_alternative`), the view is renamed,
a one-identifier change.

### §1.8 D-SV-8: nullable pointer payloads

A plain C++ `T*` imports as `Core.Optional(T*)` (the nullable pointer), so
`std::optional<int*>`'s payload and a `std::variant<..., int*>` alternative
are `Core.Optional(i32*)`. `Core.Optional(T*)` adapts `MaybeUnformed(T*)`
(optional.carbon:188-190), which adapts `MakeMaybeUnformed(T*)`
(maybe_unformed.carbon), a `T*` carrying the `MaybeUnformed` type qualifier.
`IsInSliceChoicePayloadType` unqualifies first and then walks adapters
(`GetTransitiveAdaptedType(GetUnqualifiedType(t))`, type.cpp:339-340), so the
qualifier found inside the adapter chain stops the walk at a non-pointer and
the payload is rejected (`c01`). The fix walks qualifiers and adapters
together, `GetTransitiveUnqualifiedAdaptedType(t).first` (sem_ir/type.h:234),
the existing helper whose purpose is exactly that walk. The predicate is the
one SF-6 predicate of all three sites (D-EH-2's note), so the widening applies
to every choice: a `Core.Optional(T*)` payload is a pointer, trivially
copyable and destructible, which is what SF-6 admits. Measured: `d04` (a
Carbon choice with a `Core.Optional(i32*)` payload, 3) and `s05` (42 0 -1:
engaged non-null, engaged null, empty all distinct). A `Core.Optional(i32)`
payload stays rejected (it adapts a struct), pinned by
choice/optional_pointer_payload.carbon's `fail_todo_non_pointer_optional`.

_Break condition:_ if PR 57's `MaybeUnformed` representation makes the walk
reach something other than the pointer for `Core.Optional(T*)` (measured in
the composition mirror, §8.6), the predicate admits `Core.Optional(T*)` by
name instead.

### §1.9 D-SV-9: constant aggregates in lowering

`EmitAsConstant(AnyAggregateAccess)` (lower/constant.cpp:243-263) gives a
value-category constant aggregate an address before indexing into it: when
`GetConstant(aggregate_id)` is not a pointer and the aggregate's constant is
not reference-category, it is wrapped in a private `unnamed_addr` constant
global (`@const.aggr`), and the GEP indexes that global. This is the root
cause of r03 (§0.4 item 6), not a workaround at the mapping: it fixes the
crash for every constant choice scrutinee, mapped or not. Measured: `r03` runs
(-1) on v1 to v3; the lower golden match/constant_choice_scrutinee.carbon pins
`@const.aggr = private unnamed_addr constant [4 x i8] zeroinitializer` and the
load from it; the reverse conversion of a constant (`s18`: -1 6).

_Break condition:_ if constant folding stops producing value-category
aggregate accesses (upstream), the guard is dead and is removed with its
golden's refill.

### §1.10 D-SV-10: generics, deduction, templates, libraries, constants, file scope

-   **Generic Carbon code over the mapped type** works as for any choice
    specific: the generic `Unwrap[T: Copy & Destroy]` over `StdOptional(T)`
    matches `o` symbolically and is called with a converted value (`s07`
    prints 7 and then minus 5); a generic over `Core.Optional(T)` matches
    through the view (`o02`).
-   **Deduction does not see conversions**, so `Unwrap(Cpp.MaybeSeven(), 0)`
    deduces nothing from the C++ argument; the call is diagnosed by the
    mismatch error of §1.11 (`w12`), and the caller converts first (`let` or
    `as`). This is Carbon's deduction rule, not a residue.
-   **Templates.** A `match` whose scrutinee is a template-dependent value is
    rejected for every choice (`t02`, `s17`); that is TP-1's W-252, not this
    slice's.
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
    (`n17`, unchanged).
-   **File scope.** §1.4: the existing W-036 TODO.

### §1.11 D-SV-11: diagnostics for every OUT shape

New diagnostic kinds in toolchain/diagnostics/kind.def, beside
`ChoicePayloadNotTrivialInSpecific` (:550). kind.def is an X-macro list, which
a relinked prototype cannot change, so the prototype emits `context.TODO` with
the same facts (the second column, measured on v2 and v3) and the final text
(the third column) is hand-predicted from the `CARBON_DIAGNOSTIC` declarations
of §2.4; the `fail_` goldens of §4 are filled by the implementer's
autoupdate, never by hand.

| Shape | Prototype (measured) | Final (hand-predicted) |
| --- | --- | --- |
| an alternative that imports as a class or other non-payload type (`std::optional<S>`, nested `std::optional`/`std::variant` by value) | ``semantics TODO: `C++ type has no Carbon sum type: alternative 0 has type `struct P`, not a 0.1 choice payload type` `` | ``error: C++ type `std::optional<P>` has no Carbon sum type [CppSumTypeNotMapped]`` with ``note: alternative 0 has type `P`, which is not a choice payload type in 0.1 [CppSumTypeAlternativeNotAdmitted]`` |
| a class that is not trivially copyable and destructible (`std::optional<std::string>`, `std::optional<const int>`) | ``... : not trivially copyable and destructible`` | the same error with ``note: `std::optional<std::string>` is not trivially copyable and trivially destructible [CppSumTypeNotTriviallyCopyable]`` |
| a `std::variant` of more than eight alternatives | ``... : more than 8 alternatives`` | the same error with ``note: `std::variant` with 9 alternatives; at most 8 have a Carbon sum type [CppSumTypeTooManyAlternatives]`` |
| a cv-qualified or reference alternative (a trivially copyable class, so rule 1 holds) | ``... : alternative 0 has qualified type `const int` `` | the same error with ``note: alternative 0 has qualified or reference type `const int` [CppSumTypeQualifiedAlternative]`` |
| a C++ sum value converted to another sum type (`StdOptional(i64)` from `std::optional<int>`) | ``semantics TODO: `C++ sum type converts only to its own Carbon sum type` `` | ``error: C++ type `std::optional<int>` converts only to its own Carbon sum type `Core.CppCompat.StdOptional(i32)`, not `Core.CppCompat.StdOptional(i64)` [CppSumTypeMismatch]`` |
| the conversion outside a function | ``semantics TODO: `Control flow expressions are currently only supported inside functions.` `` | unchanged (the existing W-036 TODO) |
| a `Core.CppCompat` sum type in a signature C++ calls | the existing export TODOs (`s16`) | unchanged (W-049) |
| `Core.Optional(T)` straight to a C++ `std::optional<T>` parameter | the existing ``call argument of type `Core.Optional(i32 as Core.OptionalStorage)` is not supported`` with the export TODO | unchanged (W-278) |

The first four share one error and differ in the note, so a user sees which
rule failed and for which alternative. The C++ spelling (`std::optional<P>`)
is printed with clang's type printer, because the Carbon name of the imported
class, `Cpp.std._C.optional`, carries no template arguments.

_Break condition:_ if `check_diagnostics.py` (the prek hook
`check-toolchain-diagnostics`) or a reviewer wants one error kind per rule,
the notes become errors; the goldens refill.

### §1.12 D-SV-12: goldens

All new goldens are AUTOUPDATE sources with no CHECK lines; their comments
cite this plan's sections and no W-id (W-ids live in the records only). The
interop goldens mock `std::optional` and `std::variant` in a `sum.h` split, as
stdlib/span.carbon and string_view.carbon mock theirs, so they are hermetic,
small, and pin the members the conversions call; `--target=x86_64-linux-gnu`
pins `size_t`. Sources and fills: `$P/proto/goldens-v3/` (filled by v3 to a
fixpoint, §0.6).

| Golden (new unless stated) | Splits |
| --- | --- |
| check/testdata/interop/cpp/stdlib/optional.carbon | `match`, `if_let`, `convert` (both directions, by value and `const&`), `pointer_payload`, `bridge`, `fail_todo_struct_payload`, `fail_dead_default`, `fail_unknown_alternative`, `fail_todo_outside_function` |
| check/testdata/interop/cpp/stdlib/variant.carbon | `match`, `monostate`, `duplicate`, `fail_todo_too_many_alternatives`, `fail_todo_nested_by_value`, `fail_index_out_of_range` |
| check/testdata/interop/cpp/stdlib/fail_sum_types.carbon | `fail_todo_qualified_alternative`, `fail_conversion_mismatch`, `fail_todo_core_optional_argument`, `core_optional_argument_as`, `fail_todo_export_sum_type` |
| check/testdata/choice/optional_pointer_payload.carbon | `pointer`, `fail_todo_non_pointer_optional` |
| check/testdata/match/core_optional_view.carbon | `concrete`, `pointer`, `generic`, `fail_unknown_alternative` |
| lower/testdata/interop/cpp/std_sum_types.carbon | `optional` (match and the reverse conversion), `variant` (match and the reverse) |
| lower/testdata/match/constant_choice_scrutinee.carbon | one file (D-SV-9) |
| interop/cpp/function/import/{carbon_fn_as_callable, decayed_param, function_ptr, method_ptr}.carbon (refills) | only `cpp_fn_ptr_type clang_function_pointer_type<N>` ids change (§0.6) |

`fail_todo_` marks a residue that a later slice lifts (W-275, W-276, W-277,
W-036, W-278, W-049, named in the records only); `fail_` marks a permanent
error.

### §1.13 D-SV-13: conformance programs

All under the bullet "Control flow: matching — sum-type consumption incl.
std::variant/std::optional interop", EXPECT-EXIT 0. Differential programs
have no EXPECT-STDOUT (DIFF-1); every payload is computed at run time from a
seed the C++ side cannot fold away (R16(d)), and the oracle is a plain C++17
program that computes the same values with `std::optional` / `std::variant`
and prints them with `printf("%d\n", ...)`, as `Core.Print` lowers. Bodies:
Appendix A, copies of `$P/progs/` (each run on v3 against its oracle,
`$P/runs/progs-v3.txt`).

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
    `Unwrap[T]` over `StdOptional(T)`, and the bridge to `Core.Optional(i32)`.
3.  **control_flow/match_std_variant_diff.carbon** + `.diff.cpp` (new, 14
    lines): `std::variant<int, double>`, `<std::monostate, int>`,
    `<int, int>` by index, `<bool, long, double, int*>` across all four
    alternatives, and the nested shape `std::variant<std::optional<int>*, int>`
    matched again through the pointer; every match exhaustive, no `default`.
4.  **control_flow/match_core_optional_diff.carbon** + `.diff.cpp` (new, 7
    lines): `Core.Optional(i32)` both states, `Core.Optional(i32*)` both
    states, `if`-`let`, a generic `CountSome[T]` (D-SV-7, W-177).
5.  **interop/cpp_sum_type_roundtrip_diff.carbon** + `.diff.cpp` (new, 14
    lines): the reverse direction: `StdOptional(i32)` computed and `.None`,
    passed by value and by `const&`; `StdVariant2(i32, f64)`, `(i32, i32)` by
    index and `((), i32)` passed to C++; a Carbon function with a
    `std::optional<int>` return called from C++ on both paths; a Carbon
    function taking a `std::variant<int, double>` from C++ and matching it.
6.  **control_flow/cpp_sum_type_library/** (new multi-unit: `source.carbon`,
    `main.carbon`, `main.diff.cpp`; 4 lines): the library converts at its API,
    the importer imports no C++ and matches.

_Break condition:_ a program that cannot be made to agree with its oracle
without changing the design is a finding against F-020, never a test edit.

### §1.14 D-SV-14: docs and records

-   **docs/design/sum_types.md** gains a dated section "C++ `std::optional`
    and `std::variant` (fork, SV-1, 2026-10-20)" after "User-defined sum types"
    and before "Alternatives considered": the mapping (F-020), the names,
    the admitted rule, the conversions both ways, the scrutinee rule, the
    `Core.Optional` bridge and view, and the 0.1 limits with their W-ids; and
    one sentence in "Alternatives considered" for the rejected identity
    mapping. This is the page the fork's `choice` design lives on, as SL-2's
    span mapping was recorded beside `Slice`. docs/design/unions.md's
    "the `std::variant` interop mapping built on choice" (:626-627) gains a
    link to it.
-   **docs/design/optional.md** exists only on PR 56's branch; after the merge
    of trunk (M, §3) its "Pattern matching" paragraph that cites W-177 is
    amended (dated) to the view of §1.7.
-   **Records** (commit D, after two implementation reviews): W-011 DISCHARGED
    (both halves); W-177 DISCHARGED (if PR 56 has merged, which the merge
    order guarantees); W-275 to W-278 filed (§1.16); notes appended to W-036,
    W-047, W-049 and W-252 naming the SV-1 shapes that ride them; row 68 per
    §1.17; the decision-log entry "SV-1: `std::optional` and `std::variant`
    interop mapping" with F-020 and D-SV-2 to D-SV-16; fork/ORCHESTRATION.md's
    SV-1 row; the conformance README table regenerated with
    `runner.py --update-readme-table`.

### §1.15 D-SV-15: merge position

SV-1 is cut from trunk 5674fe88b and lands after PR 61 (TP-1), last of the
queue of §0.7. The merge commit M brings in the merged trunk (never a rebase),
resolving conflicts only; the composition rules of §0.7 apply; and the
records commits come after M, so they extend the merged trunk's record files.
_Break condition:_ if the merge order changes, the dry runs of §8.6 are
repeated against whatever has landed, and only the textual rules change.

### §1.16 Residues filed (W-275 to W-278; W-279 to W-294 held)

SV-1 reserves W-275 to W-294 (fork/ORCHESTRATION.md on trunk 254b935b2). The
re-scan of every origin branch's ledger on 2026-10-20 (command in §8.7) found
the highest filed id W-274 (TP-1's, on claude/carbon-fork-0-1-tp) and no id in
the reserved block; it is repeated before the discharge commit, and an id that
is taken by then moves to the next free one in the block. Planned filings:

| Id | Title | Bullet | Bounds row 68? |
| --- | --- | --- | --- |
| W-275 | `std::optional`/`std::variant` with a class-type alternative (a trivially copyable struct, a nested `std::optional`/`std::variant` by value) has no Carbon sum type | Type system: Sum types (W-010's SF-6 residue: the payload predicate admits no aggregates) | no: SF-6(a), the user's 0.1 decision, bounds every choice; the error-handling row's precedent attributes the same bound to W-010 |
| W-276 | a `std::variant` of more than eight alternatives has no Carbon sum type | this bullet | no: a declared design bound with a diagnostic; break condition: variadic `choice` |
| W-277 | a cv-qualified or reference alternative type has no by-value payload | this bullet | no: libc++'s own `std::optional<const T>` is not trivially copyable, so the rule guards only non-libc++ classes (the golden's mock) |
| W-278 | `Core.Optional(T)` and C++ `std::optional<T>` convert only through `Core.CppCompat.StdOptional(T)` (`as`), not implicitly in one step, and not as a C++ argument | Stdlib: Optional | no: the conversion exists, spelled; the one-step form is `Core.Optional`'s C++-mapping decision (§1.7) |

Riding existing items (a note each, no new id): W-036 (conversion at file
scope), W-047 (an importer without the header's C++ import), W-049 (a
`Core.CppCompat` sum type in an exported signature), W-252 (TP-1's: a
template-dependent scrutinee). Discharged: W-011 (both halves), W-177 (§1.7).

### §1.17 D-SV-16: the row-68 disposition rule

Row 68 moves PARTIAL to DONE exactly when, at the records commit R: (1) the
arbiter un-SKIPs and passes; (2) the five new programs pass against their
oracles; (3) W-011's arbiter ("a Carbon match over an imported
std::optional/std::variant works, in executed tests") is met by (1) to (2); (4)
W-177, if PR 56 has filed it on trunk, is discharged by
match_core_optional_diff; and (5) every SV-1 residue is non-bounding by §1.16's
column. Otherwise the row stays PARTIAL with each failing condition named.
Predicted: DONE. Header delta, tree-relative: 30 DONE / 21 PARTIAL becomes 31
DONE / 20 PARTIAL (+1 DONE, -1 PARTIAL); absolute counts are re-quoted from the
merged trunk's header at R, never derived (R9).

New row status and third column (R, after M; the clause about W-177 only if
PR 56's row text is on the merged trunk):

> **DONE.** Carbon-side sum-type consumption [the current clause, unchanged]
> — and the interop half landed at SV-1 (2026-10-20,
> fork/sumtype-interop/plan.md, F-020): a C++ `std::optional<T>` /
> `std::variant<Ts...>` stays its C++ class and converts by value through its
> accessors to `Core.CppCompat.StdOptional(T)` / `StdVariant1..8`
> (alternatives `.Alt0`, `.Alt1`, ... by C++ index; `std::monostate` as `()`),
> both ways, and `match`, `if`-`let`, `while`-`let` and `let`-`else` consume
> it with exhaustiveness; `Core.Optional(T)` is matched through the same view
> (W-177 DISCHARGED). 11 conformance programs PASS (the 5 above,
> match_sum_type_payload un-SKIPped, match_std_optional_diff,
> match_std_variant_diff, match_core_optional_diff, cpp_sum_type_roundtrip_diff
> and cpp_sum_type_library, against C++ oracles). 0.1 limits, each diagnosed:
> class-type alternatives (W-275, SF-6), more than 8 alternatives (W-276),
> qualified alternatives (W-277), the one-step `Core.Optional` conversion
> (W-278); file scope (W-036), templates (W-252).

### §1.18 Decision index

| Id | Decision | Break condition (one sentence) |
| --- | --- | --- |
| F-020 (D-SV-1) | C++ class kept; sum type = specific of a prelude generic choice in `Core.CppCompat` (`StdOptional`, `StdVariant1..8`); by-value conversion both ways; `Core.Optional` bridged | variadic choices, the `Match` interface, a choice-based `Core.Optional`, or an upstream mapping |
| D-SV-2 | `.Alt<i>` by index; `std::monostate` is `()`; duplicates by index; 1 to 8 alternatives; nesting by pointer only | variadic choices or aggregate payloads |
| D-SV-3 | admitted = trivially copyable class, at most 8, unqualified alternatives that pass SF-6's predicate; else `CppSumTypeNotMapped` | SF-6 admits aggregates or non-trivial payloads |
| D-SV-4 | C++ to Carbon in convert.cpp's builtin conversion and the scrutinee gate; accessors through existing thunks; branches per arm; function scope only | a cleanup defect in the arms |
| D-SV-5 | Carbon to C++ by default construction and `emplace`; `InventClangArg` maps the sum type to the class | an export path for sum types |
| D-SV-6 | the shared scrutinee gate converts before the shape gate | the `Match` interface |
| D-SV-7 | `StdOptional(T)` and `Core.Optional(T)` convert both ways through `Optional`'s API; a `Core.Optional` scrutinee is matched as the view (W-177) | W-058 or the owner wants no copy, or a rename |
| D-SV-8 | the SF-6 predicate walks qualifiers with adapters, so `Core.Optional(T*)` is a pointer payload | PR 57 changes what the walk reaches |
| D-SV-9 | a value-category constant aggregate gets a private constant global before a GEP | upstream stops folding such accesses |
| D-SV-10 | generics, libraries, constants work; deduction and templates by their existing rules | none (consequences) |
| D-SV-11 | one error kind plus four notes, and one mismatch error; the C++ spelling in the message | the diagnostics hook or a reviewer wants separate kinds |
| D-SV-12 | seven new goldens with a mocked `sum.h`, four refills | a mock diverges from libc++ in a way a program shows |
| D-SV-13 | one un-SKIP, five new programs, all differential but the arbiter | an oracle disagreement is a design finding |
| D-SV-14 | sum_types.md dated section; records at D | none |
| D-SV-15 | lands after PR 61 through M | the merge order changes |
| D-SV-16 | the row moves to DONE under §1.17's five conditions | any condition fails |

## §2 Spec, file by file

### §2.0 Conventions

The code below is the prototype v3 (`$P/proto/v3.diff`), relinked and measured
as §0.6 records, with two exceptions that are hand-predicted: the six
`CARBON_DIAGNOSTIC` kinds of §2.10, which an X-macro list carries and a relink
cannot add (the prototype emits `context.TODO` with the same facts at the same
sites), and the BUILD entries, which the relink does not read. The final
`sum_type.cpp` with its diagnostics was compiled `-fsyntax-only` with the trunk
build's exact flags (`-Werror` set included) against a copy of kind.def
extended as §2.10 shows (`$P/final/`): it compiles; its behavior is
predicted, and the implementer's autoupdate shows it. Every C++ hunk was
formatted with the CI-pinned clang-format 21.1.8 (R18). Paths are relative to
the worktree.

### §2.1 core/prelude/types/cpp/sum.carbon (new) and core/prelude/types.carbon

**Invariant:** the nine choices declare nothing but alternatives, so every
specific's layout, constants, `Copy` and `Destroy` come from the existing
`choice` machinery; the two impls use only `Optional`'s public API. The file
imports `prelude/types/optional` (for the bridge) and `prelude/operators`
(the `match` in the first impl tests the discriminant through `Core.EqWith`,
which inside package `Core` must be imported explicitly, as result.carbon
does).

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

**Invariant:** `GetCppSumType` emits no diagnostic and is safe to call on any
type (it returns `NotSumType` for everything that is not a `std::optional` or
`std::variant` specialization), so the two hooks can consult it on every
conversion and every scrutinee.

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
    NoReason,
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
// type is mapped. Emits no diagnostic.
auto GetCppSumType(Context& context, SemIR::LocId loc_id, SemIR::TypeId type_id)
    -> CppSumType;

// Returns the C++ class that `carbon_type_id` -- a `Core.CppCompat.StdOptional`
// or `StdVariant<N>` specific -- maps to, for inventing a C++ overload
// resolution argument, or a null type if it is not one or the TU has no
// matching C++ template.
auto MapCarbonSumTypeToCpp(Context& context, SemIR::TypeId carbon_type_id)
    -> clang::QualType;

// Diagnoses a `NotMapped` sum type at `loc_id`.
auto DiagnoseCppSumTypeNotMapped(Context& context, SemIR::LocId loc_id,
                                 const CppSumType& sum_type) -> void;

// Converts `value_id`, of the C++ class type of the `Mapped` `sum_type`, to a
// value of its Carbon sum type, through the C++ accessors.
auto ConvertCppSumToCarbon(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId;

// Converts `value_id`, of the Carbon sum type of the `Mapped` `sum_type`, to a
// value of its C++ class type, through the C++ constructors.
auto ConvertCarbonSumToCpp(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId;

// If `value_id` is a C++ `std::optional`/`std::variant` value and
// `target_type_id` is its Carbon sum type, or the reverse, converts it by
// value and returns the converted value. Otherwise returns `None`.
auto TryConvertCppSumType(Context& context, SemIR::LocId loc_id,
                          SemIR::InstId value_id, SemIR::TypeId target_type_id)
    -> SemIR::InstId;

// If `type_id` is a `Core.Optional(T)` specific, returns its match view
// `Core.CppCompat.StdOptional(T)`, the docs/design/sum_types.md `Optional(T)`
// choice, which the prelude's `ImplicitAs` impls convert it to by value
// through `HasValue()` and `Get()` (SV-1, D-SV-7). Otherwise returns `None`.
auto GetCoreOptionalMatchView(Context& context, SemIR::LocId loc_id,
                              SemIR::TypeId type_id) -> SemIR::TypeId;

}  // namespace Carbon::Check

#endif  // CARBON_TOOLCHAIN_CHECK_CPP_SUM_TYPE_H_
```

<!-- google-doc-style-resume -->

### §2.4 toolchain/check/cpp/sum_type.cpp (new)

**Invariants:** (1) admission is decided before the specific is formed, in the
order of §1.3's rules, and records the first failing rule for the note; (2)
the conversion reads the C++ value only through `has_value()`/`value()` or
`index()`/`std::get<I>()`, on a value expression, and builds the C++ value only
through the default constructor and `emplace`; (3) every arm of a conversion
initializes the one result storage and owns its own temporaries
(`EmitArms`, the `if`-expression operand discipline); (4) a conversion outside
a function emits the existing file-scope TODO and builds no block; (5)
`TryConvertCppSumType` returns `None` for every pair of types it does not own,
so no other conversion changes.

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
#include "llvm/Support/FormatVariadic.h"
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
  // The C++ class must itself be trivially copyable and destructible, so
  // reading it by value and dropping the temporary are exact.
  if (!record_decl->isTriviallyCopyable() ||
      !record_decl->hasTrivialDestructor()) {
    result.reason = CppSumType::NotTriviallyCopyable;
    return result;
  }
  llvm::SmallVector<SemIR::InstId> arg_ids;
  for (auto [index, alternative] : llvm::enumerate(mapping.alternative_types)) {
    // A qualified or reference alternative has no by-value payload (SV-1
    // D-SV-3): `std::optional<const int>`, `std::variant<int&>`.
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
  auto cpp_compat_id =
      LookupNameInCore(context, loc_id, CoreIdentifier::CppCompat);
  if (cpp_compat_id == SemIR::ErrorInst::InstId) {
    return result;
  }
  auto generic_id = PerformMemberAccess(
      context, loc_id, cpp_compat_id,
      AddIdentifierName(
          context, GetCarbonSumTypeName(result.is_optional, num_alternatives)));
  auto carbon_type = ExprAsType(
      context, loc_id, PerformCall(context, loc_id, generic_id, arg_ids));
  if (carbon_type.type_id == SemIR::ErrorInst::TypeId ||
      !TryToCompleteType(context, carbon_type.type_id, loc_id) ||
      (!GetChoiceDiscriminantType(context, carbon_type.type_id) &&
       num_alternatives > 1)) {
    return result;
  }
  result.status = CppSumType::Mapped;
  result.carbon_type_id = carbon_type.type_id;
  return result;
}

// The C++ spelling of the class behind `type_id`, as import.cpp's diagnostics
// print C++ types: the Carbon name of an imported specialization
// (`Cpp.std._C.optional`) carries no template arguments.
static auto GetCppTypeSpelling(Context& context, SemIR::TypeId type_id)
    -> std::string {
  const auto* record_decl = GetCppClassDecl(context, type_id);
  CARBON_CHECK(record_decl, "not a C++ class");
  return clang::QualType(context.ast_context().getCanonicalTagType(record_decl))
      .getAsString();
}

auto DiagnoseCppSumTypeNotMapped(Context& context, SemIR::LocId loc_id,
                                 const CppSumType& sum_type) -> void {
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
                   sum_type.bad_alternative_type.getAsString());
      break;
    case CppSumType::AlternativeNotAdmitted:
      builder.Note(loc_id, CppSumTypeAlternativeNotAdmitted,
                   sum_type.bad_alternative,
                   sum_type.bad_alternative_type.getAsString());
      break;
    case CppSumType::NoReason:
      // A sum type whose `Core.CppCompat` choice could not be formed: the
      // lookup or the call already diagnosed it.
      return;
  }
  builder.Emit();
}

// The parse node that the blocks of a conversion are attributed to: the
// conversion's own node, or none for an import- or inst-located conversion.
static auto GetNodeIdForBlocks(Context& context, SemIR::LocId loc_id)
    -> Parse::NodeId {
  auto canonical_loc_id = context.insts().GetCanonicalLocId(loc_id);
  return canonical_loc_id.kind() == SemIR::LocId::Kind::NodeId
             ? canonical_loc_id.node_id()
             : Parse::NodeId::None;
}

// Calls `callee_id`, a C++ overload set, with the explicit integer template
// argument `index` -- `std::get<I>(v)`, `v.emplace<I>(x)` -- which a Carbon
// call cannot spell (cpp/call.cpp `IsTemplateArg`).
static auto CallCppWithIndexTemplateArg(Context& context, SemIR::LocId loc_id,
                                        SemIR::InstId callee_id, int index,
                                        llvm::ArrayRef<SemIR::InstId> arg_ids)
    -> SemIR::InstId {
  auto callee = SemIR::GetCallee(context.sem_ir(), callee_id);
  const auto* overload = std::get_if<SemIR::CalleeCppOverloadSet>(&callee);
  if (!overload) {
    return SemIR::ErrorInst::InstId;
  }
  SemIR::InstId template_arg_ids[] = {MakeIntLiteral(
      context, GetNodeIdForBlocks(context, loc_id), context.ints().Add(index))};
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

// Calls the C++ member function `name` of `object_id` with no arguments.
static auto CallCppMethod(Context& context, SemIR::LocId loc_id,
                          SemIR::InstId object_id, llvm::StringRef name,
                          llvm::ArrayRef<SemIR::InstId> arg_ids = {})
    -> SemIR::InstId {
  auto method_id = PerformMemberAccess(context, loc_id, object_id,
                                       AddIdentifierName(context, name));
  return PerformCall(context, loc_id, method_id, arg_ids,
                     /*is_desugared=*/true);
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

auto ConvertCppSumToCarbon(Context& context, SemIR::LocId loc_id,
                           SemIR::InstId value_id, const CppSumType& sum_type)
    -> SemIR::InstId {
  CARBON_CHECK(sum_type.status == CppSumType::Mapped);
  if (!context.scope_stack().IsInFunctionScope()) {
    // The conversion branches, as an `if` expression does, so it shares that
    // expression's file-scope limit and its message (handle_if_expr.cpp).
    context.TODO(loc_id,
                 "Control flow expressions are currently only supported "
                 "inside functions.");
    return SemIR::ErrorInst::InstId;
  }
  auto node_id = GetNodeIdForBlocks(context, loc_id);
  // A value, not a reference: the accessors are then called on a `const`
  // object, so overload resolution picks their `const&` forms and nothing is
  // moved from.
  value_id = ConvertToValueExpr(context, value_id);
  auto carbon_type_inst_id =
      context.types().GetTypeInstId(sum_type.carbon_type_id);
  const auto& carbon_class = context.classes().Get(
      context.types()
          .GetAs<SemIR::ClassType>(sum_type.carbon_type_id)
          .class_id);
  // The alternatives in discriminant order.
  llvm::SmallVector<SemIR::ChoiceAlternative> alternatives(
      carbon_class.choice_alternatives.begin(),
      carbon_class.choice_alternatives.end());
  llvm::sort(alternatives,
             [](const auto& a, const auto& b) { return a.index < b.index; });
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

  BranchedInit result(context, loc_id, sum_type.carbon_type_id);
  if (sum_type.is_optional) {
    // `Some` is alternative 0 and `None` alternative 1: test `has_value()`.
    auto has_value_id = ConvertToBoolValue(
        context, loc_id, CallCppMethod(context, loc_id, value_id, "has_value"));
    EmitArms(
        context, node_id, 2, [&](int) { return has_value_id; },
        [&](int i) {
          result.Initialize(make_alternative(
              alternatives[i],
              i == 0 ? CallCppMethod(context, loc_id, value_id, "value")
                     : SemIR::InstId::None));
        });
  } else {
    int n = alternatives.size();
    auto index_id = n > 1 ? CallCppMethod(context, loc_id, value_id, "index")
                          : SemIR::InstId::None;
    const auto* record_decl = GetCppClassDecl(context, sum_type.cpp_type_id);
    auto mapping = GetCppSumTypeMapping(record_decl);
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
            payload_id = GetOrAddInst<SemIR::TupleValue>(
                context, loc_id,
                {.type_id = GetTupleType(context, {}),
                 .elements_id = SemIR::InstBlockId::Empty});
          } else {
            auto get_id =
                PerformMemberAccess(context, loc_id, std_inst_id,
                                    AddIdentifierName(context, "get"));
            payload_id = CallCppWithIndexTemplateArg(context, loc_id, get_id, i,
                                                     {value_id});
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
  if (!context.scope_stack().IsInFunctionScope()) {
    context.TODO(loc_id,
                 "Control flow expressions are currently only supported "
                 "inside functions.");
    return SemIR::ErrorInst::InstId;
  }
  auto node_id = GetNodeIdForBlocks(context, loc_id);
  value_id = ConvertToValueExpr(context, value_id);
  auto cpp_type_inst_id = context.types().GetTypeInstId(sum_type.cpp_type_id);
  const auto& cpp_class = context.classes().Get(
      context.types().GetAs<SemIR::ClassType>(sum_type.cpp_type_id).class_id);
  const auto& carbon_class = context.classes().Get(
      context.types()
          .GetAs<SemIR::ClassType>(sum_type.carbon_type_id)
          .class_id);
  llvm::SmallVector<SemIR::ChoiceAlternative> alternatives(
      carbon_class.choice_alternatives.begin(),
      carbon_class.choice_alternatives.end());
  llvm::sort(alternatives,
             [](const auto& a, const auto& b) { return a.index < b.index; });
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
  auto payload_of =
      [&](const SemIR::ChoiceAlternative& alternative) -> SemIR::InstId {
    auto tuple_id = EmitChoicePayloadFieldAccess(
        context, loc_id, value_id, alternative.payload_field_index);
    auto tuple_type_id = context.insts().Get(tuple_id).type_id();
    auto element_type_inst_id =
        context.inst_blocks().Get(context.types()
                                      .GetAs<SemIR::TupleType>(tuple_type_id)
                                      .type_elements_id)[0];
    return ConvertToValueExpr(
        context, AddInst<SemIR::TupleAccess>(
                     context, loc_id,
                     {.type_id = context.types().GetTypeIdForTypeInstId(
                          element_type_inst_id),
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
        if (sum_type.is_optional) {
          if (alternative.has_parameters) {
            ok &= CallCppMethod(context, loc_id, result.storage_id(), "emplace",
                                {payload_of(alternative)}) !=
                  SemIR::ErrorInst::InstId;
          }
          return;
        }
        auto emplace_id =
            PerformMemberAccess(context, loc_id, result.storage_id(),
                                AddIdentifierName(context, "emplace"));
        llvm::SmallVector<SemIR::InstId, 1> args;
        auto tuple_type_id =
            context.insts()
                .Get(EmitChoicePayloadFieldAccess(
                    context, loc_id, value_id, alternative.payload_field_index))
                .type_id();
        auto element_type_id =
            context.types().GetTypeIdForTypeInstId(context.inst_blocks().Get(
                context.types()
                    .GetAs<SemIR::TupleType>(tuple_type_id)
                    .type_elements_id)[0]);
        if (element_type_id != GetTupleType(context, {})) {
          args.push_back(payload_of(alternative));
        }
        ok &= CallCppWithIndexTemplateArg(context, loc_id, emplace_id, i,
                                          args) != SemIR::ErrorInst::InstId;
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

auto TryConvertCppSumType(Context& context, SemIR::LocId loc_id,
                          SemIR::InstId value_id, SemIR::TypeId target_type_id)
    -> SemIR::InstId {
  auto value_type_id = context.types().GetUnqualifiedType(
      context.insts().Get(value_id).type_id());
  target_type_id = context.types().GetUnqualifiedType(target_type_id);
  if (ClassifyCarbonSumType(context, target_type_id) != 0) {
    auto sum_type = GetCppSumType(context, loc_id, value_type_id);
    if (sum_type.status == CppSumType::NotSumType) {
      return SemIR::InstId::None;
    }
    if (sum_type.status == CppSumType::NotMapped) {
      DiagnoseCppSumTypeNotMapped(context, loc_id, sum_type);
      return SemIR::ErrorInst::InstId;
    }
    if (sum_type.carbon_type_id == target_type_id) {
      return ConvertCppSumToCarbon(context, loc_id, value_id, sum_type);
    }
    // Not to another sum type: falling through to the generic C++-class
    // conversion would try to export the `Core` choice to C++ (export.cpp's
    // non-identifier package TODO) instead of saying what is wrong.
    CARBON_DIAGNOSTIC(CppSumTypeMismatch, Error,
                      "C++ type `{0}` converts only to its own Carbon sum "
                      "type {1}, not {2}",
                      std::string, SemIR::TypeId, SemIR::TypeId);
    context.emitter().Emit(loc_id, CppSumTypeMismatch,
                           GetCppTypeSpelling(context, value_type_id),
                           sum_type.carbon_type_id, target_type_id);
    return SemIR::ErrorInst::InstId;
  }
  if (ClassifyCarbonSumType(context, value_type_id) != 0) {
    auto sum_type = GetCppSumType(context, loc_id, target_type_id);
    if (sum_type.status == CppSumType::Mapped &&
        sum_type.carbon_type_id == value_type_id) {
      return ConvertCarbonSumToCpp(context, loc_id, value_id, sum_type);
    }
  }
  return SemIR::InstId::None;
}

auto MapCarbonSumTypeToCpp(Context& context, SemIR::TypeId carbon_type_id)
    -> clang::QualType {
  int kind = ClassifyCarbonSumType(context, carbon_type_id);
  if (kind == 0) {
    return clang::QualType();
  }
  bool is_optional = kind == 1;
  auto class_type = context.types().GetAs<SemIR::ClassType>(
      context.types().GetUnqualifiedType(carbon_type_id));
  auto args = context.inst_blocks().GetOrEmpty(
      context.specifics().Get(class_type.specific_id).args_id);
  auto* template_decl = LookupCppClassTemplate(
      context, {"std", is_optional ? "optional" : "variant"});
  if (!template_decl) {
    return clang::QualType();
  }
  clang::ASTContext& ast_context = context.ast_context();
  clang::TemplateArgumentListInfo arg_list;
  for (auto arg_id : args) {
    if (auto facet = context.insts().TryGetAs<SemIR::FacetValue>(arg_id)) {
      arg_id = facet->type_inst_id;
    }
    auto arg_type_id = context.types().GetTypeIdForTypeConstantId(
        context.constant_values().Get(arg_id));
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

auto GetCoreOptionalMatchView(Context& context, SemIR::LocId loc_id,
                              SemIR::TypeId type_id) -> SemIR::TypeId {
  auto class_type = context.types().TryGetAs<SemIR::ClassType>(
      context.types().GetUnqualifiedType(type_id));
  if (!class_type || !class_type->specific_id.has_value()) {
    return SemIR::TypeId::None;
  }
  const auto& class_info = context.classes().Get(class_type->class_id);
  if (class_info.is_choice ||
      !context.name_scopes().IsCorePackage(class_info.parent_scope_id) ||
      context.names().GetAsStringIfIdentifier(class_info.name_id) !=
          "Optional") {
    return SemIR::TypeId::None;
  }
  auto args = context.inst_blocks().GetOrEmpty(
      context.specifics().Get(class_type->specific_id).args_id);
  if (args.size() != 1) {
    return SemIR::TypeId::None;
  }
  // The argument is `T as OptionalStorage`; the view's argument is `T`.
  auto payload_type = ExprAsType(context, loc_id, args[0]);
  if (payload_type.type_id == SemIR::ErrorInst::TypeId) {
    return SemIR::TypeId::None;
  }
  auto cpp_compat_id =
      LookupNameInCore(context, loc_id, CoreIdentifier::CppCompat);
  if (cpp_compat_id == SemIR::ErrorInst::InstId) {
    return SemIR::TypeId::None;
  }
  auto generic_id = PerformMemberAccess(
      context, loc_id, cpp_compat_id,
      AddIdentifierName(context, GetCarbonSumTypeName(true, 1)));
  auto view = ExprAsType(
      context, loc_id,
      PerformCall(context, loc_id, generic_id, {payload_type.inst_id}));
  if (view.type_id == SemIR::ErrorInst::TypeId) {
    return SemIR::TypeId::None;
  }
  return view.type_id;
}

}  // namespace Carbon::Check
```

<!-- google-doc-style-resume -->

### §2.5 toolchain/check/convert.cpp

**Invariant:** the hook runs after every conversion that compares the two
types structurally (tuples, structs, arrays, function pointers), and before the
target is unqualified and the class-to-class paths start; it returns `None`
unless one side is a C++ sum class and the other its own sum type, so every
existing conversion keeps its path (measured: the gate, §0.6).

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
@@ -1795,6 +1796,14 @@
     }
   }

+  // Fork (SV-1, F-020): a C++ `std::optional` or `std::variant` converts by
+  // value to its `Core.CppCompat` sum type, and that sum type back to it.
+  if (auto sum_id =
+          TryConvertCppSumType(context, loc_id, value_id, target.type_id);
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
branch.

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
@@ -196,6 +197,36 @@
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
+  } else if (auto view_type_id = GetCoreOptionalMatchView(
+                 context, SemIR::LocId(node_id), scrutinee_type_id);
+             view_type_id.has_value()) {
+    // Fork (SV-1, D-SV-7): a `Core.Optional(T)` scrutinee is matched as its
+    // view `Core.CppCompat.StdOptional(T)`, converted by value through the
+    // prelude's `ImplicitAs` impl (`HasValue()`, `Get()`).
+    scrutinee_id = ConvertToValueOfType(context, SemIR::LocId(node_id),
+                                        scrutinee_id, view_type_id);
+    if (scrutinee_id == SemIR::ErrorInst::InstId) {
+      return SemIR::InstId::None;
+    }
+    scrutinee_type_id = view_type_id;
+  }
+
   if (!IsSupportedScrutineeType(context, scrutinee_type_id)) {
     context.TODO(node_id, todo_string.str());
     return SemIR::InstId::None;
```

<!-- google-doc-style-resume -->

### §2.7 toolchain/check/cpp/type_mapping.{h,cpp}

**Invariant:** a sum-typed argument is offered to C++ overload resolution as
its C++ class and nothing else; `LookupCppType` becomes visible for
`std::monostate`.

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
@@ -586,6 +587,15 @@
     }
   }

+  // Fork (SV-1, F-020): a `Core.CppCompat` sum type argument is offered to
+  // overload resolution as the C++ class it converts to; the argument is
+  // converted by value when the call converts it to the parameter's type.
+  // Before `MapToCppType`, which would try, and diagnose, exporting the
+  // prelude `choice` itself.
+  if (arg_cpp_type.isNull()) {
+    arg_cpp_type = MapCarbonSumTypeToCpp(context, form.type_id);
+  }
+
   if (arg_cpp_type.isNull()) {
     arg_cpp_type = MapToCppType(context, form.type_id);
   }
```

<!-- google-doc-style-resume -->

### §2.8 toolchain/check/type.cpp

**Invariant:** the predicate's answer changes only for a type whose adapter
chain passes through a type qualifier before reaching a scalar; every type it
admitted before it still admits (unqualifying first and then walking adapters
reaches a subset of what walking both together reaches).

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/type.cpp
+++ b/toolchain/check/type.cpp
@@ -336,8 +336,11 @@

 auto IsInSliceChoicePayloadType(Context& context, SemIR::TypeId type_id)
     -> bool {
-  auto adapted_type_id = context.types().GetTransitiveAdaptedType(
-      context.types().GetUnqualifiedType(type_id));
+  // Fork (SV-1, D-SV-8): qualifiers inside an adapter are walked through too,
+  // so the pointer-niche `Core.Optional(T*)` -- an adapter of
+  // `MaybeUnformed(T*)`, a nullable C++ `T*` -- is a pointer payload.
+  auto adapted_type_id =
+      context.types().GetTransitiveUnqualifiedAdaptedType(type_id).first;
   auto inst = context.types().GetAsInst(adapted_type_id);
   if (auto tuple_type = inst.TryAs<SemIR::TupleType>()) {
     // The zero-sized empty tuple `()` is admitted (W-070 option (a),
```

<!-- google-doc-style-resume -->

### §2.9 toolchain/lower/constant.cpp

**Invariant:** only a value-category constant aggregate whose lowered constant
is not already a pointer is given a global; every access into a
reference-category or addressed aggregate is unchanged.

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/lower/constant.cpp
+++ b/toolchain/lower/constant.cpp
@@ -249,6 +249,26 @@
   auto* aggr_type = context.GetType(
       context.sem_ir().insts().Get(inst.aggregate_id).type_id());

+  // Fork (SV-1, D-SV-9): an element access is a reference into its aggregate,
+  // but a `ClassElementAccess` on a constant class VALUE folds to the
+  // element's value constant (eval of a value-category base), and a further
+  // access into that folded constant -- the payload tuple of a constant
+  // `choice` alternative, `match (Opt(i32).None) { case .Some(v: i32) ... }`
+  // -- then finds a value representation where it needs an address, and the
+  // GEP and the later load were built on a non-pointer constant. Give such an
+  // aggregate an address: a private constant global holding its value.
+  auto aggr_const_inst_id =
+      context.sem_ir().constant_values().GetConstantInstId(inst.aggregate_id);
+  if (!SemIR::IsRefCategory(
+          SemIR::GetExprCategory(context.sem_ir(), aggr_const_inst_id)) &&
+      !aggr_addr->getType()->isPointerTy()) {
+    auto* global = new llvm::GlobalVariable(
+        context.llvm_module(), aggr_type, /*isConstant=*/true,
+        llvm::GlobalVariable::PrivateLinkage, aggr_addr, "const.aggr");
+    global->setUnnamedAddr(llvm::GlobalValue::UnnamedAddr::Global);
+    aggr_addr = global;
+  }
+
   auto* i32_type = llvm::Type::getInt32Ty(context.llvm_context());
   // For now, we rely on the LLVM type's GEP indexes matching the SemIR
   // aggregate element indexes.
```

<!-- google-doc-style-resume -->

### §2.10 toolchain/diagnostics/kind.def and toolchain/check/BUILD (hand-predicted)

kind.def, in the C++ interop group after `CppExportResultNeedsExpectedHeader`
(an X-macro list: every translation unit that includes it recompiles; this is
why the prototype could not carry it):

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/diagnostics/kind.def
+++ b/toolchain/diagnostics/kind.def
@@ -257,6 +257,12 @@
 CARBON_DIAGNOSTIC_KIND(CppReservedNameShadowed)
 CARBON_DIAGNOSTIC_KIND(CppCatchingImportNonScalarSuccess)
 CARBON_DIAGNOSTIC_KIND(CppExportResultNeedsExpectedHeader)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeNotMapped)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeTooManyAlternatives)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeNotTriviallyCopyable)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeQualifiedAlternative)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeAlternativeNotAdmitted)
+CARBON_DIAGNOSTIC_KIND(CppSumTypeMismatch)
 CARBON_DIAGNOSTIC_KIND(InlineImportNotCpp)
 CARBON_DIAGNOSTIC_KIND(IncorrectExtension)
 CARBON_DIAGNOSTIC_KIND(IncorrectExtensionImplNote)
```

<!-- google-doc-style-resume -->

BUILD, the new translation unit and header in `//toolchain/check:check`'s
`srcs` and `hdrs`, alphabetical (the `fix-cc-deps` hook is skipped by the
prek invocation; no new dependency is needed, as sum_type.cpp includes only
headers of the same library and clang's AST and Sema, which the library
already depends on):

<!-- google-doc-style-ignore -->

```diff
--- a/toolchain/check/BUILD
+++ b/toolchain/check/BUILD
@@ -35,6 +35,7 @@ cc_library(
         "cpp/macros.cpp",
         "cpp/operators.cpp",
         "cpp/overload_resolution.cpp",
+        "cpp/sum_type.cpp",
         "cpp/thunk.cpp",
         "cpp/type_mapping.cpp",
         "custom_witness.cpp",
@@ -102,6 +103,7 @@ cc_library(
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

The six programs of §1.13 are reproduced in Appendix A and the golden sources
of §1.12, without CHECK lines, in Appendix B; both are byte copies of the
files the prototype ran (`$P/progs/`, `$P/proto/goldens-v3/` with the CHECK
lines stripped), and the implementer copies them, never retypes them.

## §3 Commits

One PR, "SV-1: `std::optional` and `std::variant` interop mapping" (R29(b)).
Each implementation commit compiles alone and is judged with its fill: alone
it is red exactly on the goldens it adds or refills and on nothing else, with
no crash. Commit messages end with the session trailers; `--author` and the
committer are the workstream's (R20: explicit paths only).

0.  **Plan.** Rev 1 (this file), "SV-1 plan (rev 1): std::optional and
    std::variant interop mapping"; rev 2 folds the two plan reviews (R29(c));
    rev 3 folds a focused re-review if a review REJECTs.
1.  **C1** "SV-1 (1): Core.CppCompat sum types in the prelude; nullable
    pointer payloads; constant aggregates in lowering": core/prelude/types/cpp
    /sum.carbon, core/prelude/types.carbon, toolchain/check/type.cpp (D-SV-8),
    toolchain/lower/constant.cpp (D-SV-9); new goldens
    choice/optional_pointer_payload.carbon and
    lower/match/constant_choice_scrutinee.carbon; the four function-pointer
    goldens of §0.6 go red (their only change, the prelude file's). **F1**
    fills the two and refills the four.
2.  **C2** "SV-1 (2): std::optional and std::variant convert by value to and
    from their Carbon sum types and are matched as them": custom_type_mapping
    .{h,cpp}, cpp/sum_type.{h,cpp} without `GetCoreOptionalMatchView`,
    convert.cpp, refutable_binding.cpp's C++ branch, cpp/type_mapping.{h,cpp},
    diagnostics/kind.def, check/BUILD; new goldens stdlib/optional.carbon,
    stdlib/variant.carbon, stdlib/fail_sum_types.carbon,
    lower/interop/cpp/std_sum_types.carbon. **F2**.
3.  **C3** "SV-1 (3): a Core.Optional scrutinee is matched as its
    StdOptional view": `GetCoreOptionalMatchView` and refutable_binding.cpp's
    second branch; new golden match/core_optional_view.carbon. **F3**.
4.  **P** "SV-1 (4): conformance programs for the sum-type interop mapping":
    match_sum_type_payload.carbon un-SKIPped with its intended body (the
    `default` removal stated in its header), the five new programs, the
    regenerated README table, `runner.py --self-test`.
5.  **Doc** "SV-1 (5): design: C++ std::optional and std::variant": the dated
    section of docs/design/sum_types.md and the link in unions.md (§1.14).
6.  **Implementation reviews** A and B on the head (not commits).
7.  **Fix commits**, at most three, each with its fill (the budget); the
    **shrink line**, in order: first drop C3 and match_core_optional_diff
    (W-177 stays open, and row 68 stays PARTIAL on it once PR 56 has filed it;
    §1.17 condition 4), then drop the reverse direction (the `InventClangArg`
    mapping and `ConvertCarbonSumToCpp`; the roundtrip program and the reverse
    splits leave, W-278 widens to "Carbon to C++", and row 68 stays PARTIAL).
    Nothing else is cut: the forward conversion and the scrutinee gate are the
    arbiter.
8.  **Held state (the land-time commits, specified now).** While the queue is
    held, nothing merges; the compositions of §8.6 are measured on scratch
    mirrors at implementation time and recorded in D. When PR 61 has landed:
    **M**, the merge of trunk (never a rebase), resolving conflicts only by the
    rules of §0.7 (record files take trunk's text; the README table is
    regenerated); **F-M**, the refill of what the merge changes (predicted:
    decayed_param.carbon once, over PR 57's and SV-1's changes together; any
    golden of SC-1, VA-1 or TP-1 that the merged toolchain changes, predicted
    none); the dry runs of §8.6 repeated against that day's heads first.
9.  **R** "SV-1 (6): gap row 68": the row and the header, by §1.17, after M.
10. **D** "SV-1 (7): discharge": the id re-scan of §8.7 first; W-011 and W-177
    DISCHARGED, W-275 to W-278 filed, the notes on W-036, W-047, W-049 and
    W-252, the decision-log entry, docs/design/optional.md's dated amendment
    (after M), fork/ORCHESTRATION.md's row; after the two implementation
    reviews.

## §4 Testdata matrix

Predicted key lines of each fill (measured on v3, `$P/proto/goldens-v3/`;
the four new diagnostics' texts are §1.11's hand-predicted finals, which
replace the prototype's TODO texts in the same splits at the same columns).
Refills by name.

| Golden | Key lines the fill must reproduce |
| --- | --- |
| stdlib/optional.carbon `match` | `%has_value__carbon_thunk.call`, `if ... br ... else br`, `%value__carbon_thunk.call`, `%StdOptional.Some.call`, the `%StdOptional.val` constant copied in the other arm, `class_type @StdOptional, @StdOptional(constants.%i32)`; no `default`, no error |
| `if_let` | the same conversion feeding the refutable binding |
| `convert` | `%optional__carbon_thunk.call` (default construction), `%emplace__carbon_thunk.call`, `%Take__carbon_thunk.call` twice and `%TakeRef__carbon_thunk.call` |
| `pointer_payload` | the payload type `Core.Optional(i32*)`; `%value__carbon_thunk.call` |
| `bridge` | the two impls' `Convert` calls, `StdOptional(i32)` to `Core.Optional(i32)` and back |
| `fail_todo_struct_payload` | final: ``error: C++ type `std::optional<Point>` has no Carbon sum type [CppSumTypeNotMapped]`` and ``note: alternative 0 has type `Point`, which is not a choice payload type in 0.1 [CppSumTypeAlternativeNotAdmitted]`` at 9 (prototype: the TODO text at :9) |
| `fail_dead_default` | ``error: `default` arm never matches; every value of the scrutinee is matched by prior arms [MatchDefaultNeverMatches]`` |
| `fail_unknown_alternative` | ``error: member name `Ok` not found in `Core.CppCompat.StdOptional(i32)` [MemberNameNotFoundInSpecificScope]`` |
| `fail_todo_outside_function` | ``error: semantics TODO: `Control flow expressions are currently only supported inside functions.` [SemanticsTodo]`` at 47 |
| stdlib/variant.carbon `match` | `%index__carbon_thunk.call` once, `%get__carbon_thunk.call` per arm, `%StdVariant2.Alt0.call` / `%StdVariant2.Alt1.call` |
| `monostate` | the `()` payload `tuple_value ()` in arm 0; `StdVariant2((), i32)` |
| `duplicate` | `class_type @StdVariant2, @StdVariant2(constants.%i32, constants.%i32)` |
| `fail_todo_too_many_alternatives` | final: the error with ``note: `std::variant` with 9 alternatives; at most 8 have a Carbon sum type [CppSumTypeTooManyAlternatives]`` |
| `fail_todo_nested_by_value` | final: the error with ``note: alternative 0 has type `std::optional<int>`, which is not a choice payload type in 0.1`` (the prototype printed clang's `class std::optional<int>`; the fill shows clang's spelling) |
| `fail_index_out_of_range` | ``error: member name `Alt2` not found in `Core.CppCompat.StdVariant2(i32, f64)` [MemberNameNotFoundInSpecificScope]`` |
| stdlib/fail_sum_types.carbon | `fail_todo_qualified_alternative`: the error with `[CppSumTypeQualifiedAlternative]`, ``alternative 0 has qualified or reference type `const int` ``; `fail_todo_non_trivial`: with `[CppSumTypeNotTriviallyCopyable]`; `fail_conversion_mismatch`: ``error: C++ type `std::optional<int>` converts only to its own Carbon sum type `Core.CppCompat.StdOptional(i32)`, not `Core.CppCompat.StdOptional(i64)` [CppSumTypeMismatch]``; `fail_todo_core_optional_argument`: the existing ``call argument of type `Core.Optional(i32 as Core.OptionalStorage)` is not supported [CppCallArgTypeNotSupported]`` after the export TODO at `{{.*}}/prelude/types/optional.carbon:30:1`; `core_optional_argument_as`: no error; `fail_todo_export_sum_type`: the three existing export errors (`interop with non-identifier package name` at `{{.*}}/prelude/types/cpp/sum.carbon:30:1`, `failed to map Carbon return type to C++ type`, `no member named 'MakeView' in namespace 'Carbon'`) |
| choice/optional_pointer_payload.carbon | `pointer`: no error, the payload `Core.Optional(i32*)` in the alternative's parameter; `fail_todo_non_pointer_optional`: ``error: semantics TODO: `choice alternative payload that is not trivially copyable and destructible` [SemanticsTodo]`` |
| match/core_optional_view.carbon | `concrete`: the bridge's `Convert` call on the scrutinee, then the choice dispatch on `StdOptional(i32)`; `pointer`, `generic` (`@StdOptional(%T.67d)`): no error; `fail_unknown_alternative`: ``member name `Ok` not found in `Core.CppCompat.StdOptional(i32)` `` |
| lower/interop/cpp/std_sum_types.carbon | `define internal ... @_ZNKSt3__18optionalIiE9has_valueEv.carbon_thunk._`, `... value ... .carbon_thunk._`, `@_ZNKSt3__17variantIJidEE5indexEv.carbon_thunk._`, two `std::get<I>` thunks (`@_ZNSt3__13getILm0EJidEE...` and `ILm1E`), the two `emplace` thunks, `linkonce_odr void @_CSome.StdOptional.CppCompat.Core.<hash>`; the Carbon layouts `<{ <{ i1, [3 x i8] }>, [4 x i8] }>` and `<{ <{ i1, [7 x i8] }>, [8 x i8] }>` beside the mock's `%"class.std::__1::optional" = type <{ i32, i8, [3 x i8] }>` |
| lower/match/constant_choice_scrutinee.carbon | `@const.aggr = private unnamed_addr constant [4 x i8] zeroinitializer` and a `load i32, ptr @const.aggr` |
| refills: function/import/{carbon_fn_as_callable, decayed_param, function_ptr, method_ptr}.carbon | only `cpp_fn_ptr_type clang_function_pointer_type<N>` changes, 17 lines in all |

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
other program changes status (the gate's 1938 unchanged goldens and the
existing programs' toolchain paths are untouched, §2.5 to §2.9). Bullets: the
row-68 bullet already rolls up PASS (§0.8), so 48/56 stays 48/56.

## §6 Churn and collisions

Toolchain: two new files (cpp/sum_type.h, 96 lines, and cpp/sum_type.cpp,
697 lines, formatted) and nine changed (custom_type_mapping.h +24,
custom_type_mapping.cpp +50, convert.cpp +8, refutable_binding.cpp +30,
cpp/type_mapping.h +6, cpp/type_mapping.cpp +11/-2, type.cpp +5/-2,
lower/constant.cpp +19, diagnostics/kind.def +6, check/BUILD +2). Core: one new
file (sum.carbon, 129 lines) and one line. Testdata: seven new goldens and
four refills. Conformance: one changed program, five new (one a directory of
three files), four new `.diff.cpp` oracles and one `main.diff.cpp`, the README
table. Docs: sum_types.md, unions.md (one link), optional.md after M. Records
at R and D. Collisions and their rules: §0.7; the land-time order: §3 item 8.

## §7 Risks and rejected alternatives

### §7.1 Risks (each falsifiable)

-   **R-1, the mocks drift from libc++.** The goldens mock `std::optional`
    and `std::variant`; the programs use the toolchain's libc++ 24.0. A
    divergence that matters shows as a program failure against its oracle,
    which is real libc++ on the C++ side too.
-   **R-2, cost.** Prelude: +5% check time on a trivial file (measured). Code:
    one internal thunk per accessor per specialization and file (measured).
    Falsified if the full gate's wall time grows by more than 5% at
    implementation (measured now: 31.47 s against 31.42 s); then the arity
    bound drops to 4.
-   **R-3, PR 57's representation.** The bridge uses only `Optional`'s API
    (measured on the OP-2 build at user level); D-SV-8's walk is predicted
    unchanged (§1.8). Falsified by the composition mirror (§8.6).
-   **R-4, the internal template-argument path.** `std::get<I>` and
    `emplace<I>` rely on `PerformCppOverloadResolution`'s `template_arg_ids`
    with an integer literal. Falsified if UA-3 (the next upstream advance)
    changes that signature; the adaptation is local to sum_type.cpp.
-   **R-5, copies.** Matching a `Core.Optional` or a C++ sum value copies the
    payload; for admitted (trivially copyable) alternatives this is a scalar
    copy, and for `Core.Optional(T)` a `T: Copy` copy. Falsified if a
    program shows an observable difference from by-reference matching (no
    admitted shape can: the scrutinee is a value).
-   **R-6, other standard libraries.** The matchers key on the template name
    in namespace `std` and the accessors are standard, so libstdc++ would
    work in principle; it is not shipped with the toolchain and not measured.
-   **R-7, valueless variants** are unreachable for admitted alternatives and
    fail-stop through the fence otherwise (§0.5).

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
-   **R-C, a synthesized choice entity per specialization.** §1.1's
    affirmative justification: no source-less choice exists, and its identity
    across files and libraries would be new.
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
    decision. What a choice would give, `.Some`/`.None` patterns, the view of
    §1.7 gives without touching the class.
-   **R-F, `.0(x)` alternative names**: a parse error (`m17`).
-   **R-G, alternatives named by type**: undefined for duplicates.
-   **R-H, `std::variant<T, E>` as `Core.Result(T, E)`**: positional
    alternatives carry no `Ok`/`Err` meaning; `a08` stays an error.
-   **R-I, one-step implicit `std::optional<T>` to `Core.Optional(T)`**:
    deferred (W-278, §1.7).
-   **R-J, widening SF-6 to trivially copyable structs here**: it changes every
    choice's payload rule and its `Copy`/`Destroy` witnesses (W-010's
    residue); out of this slice.

## §8 Verification and discharge

All of it container-local, expected and not of record (R9, R28); the carbonbuild
scripts are
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild/`
(`$CB` below).

1.  **Build and install** the worktree itself (a full build, not a relink;
    the X-macro diagnostics need it): `$CB/build.sh /home/user/carbon-sv &&
    $CB/install.sh /home/user/carbon-sv`; `carbon version` prints the head's
    hash. The installed `carbon link` then compiles the new prelude file into
    the runtimes (the relink's limitation of §0.0 disappears).
2.  **Autoupdate to a fixpoint** after each implementation commit:
    `$CB/autoupdate.sh /home/user/carbon-sv <the commit's goldens>` twice; the
    second pass may only renumber `[[@LINE+N]]` offsets of files whose first
    pass inserted CHECK:STDERR lines (R26; measured on v3: fail_sum_types.carbon
    converged on its second pass), and a third pass writes nothing.
3.  **Gate**: `$CB/gate.sh /home/user/carbon-sv`: predicted 1949 tests (1942 +
    the seven new goldens), all passing, 0 autoupdate-would-change marks.
4.  **Conformance**: `XDG_CACHE_HOME=... $CB/conformance.sh /home/user/carbon-sv
    <out>`: predicted 134 PASS / 0 FAIL / 21 SKIP over 155, bullets 48/56; then
    `python3 fork/conformance/runner.py --update-readme-table` and
    `--self-test` (R7).
5.  **Mutants**, each relinked over the worktree's build and run against the
    goldens and the programs; each must turn something red, and the record names
    what:

    | Mutant | Predicted red |
    | --- | --- |
    | M1: `TryConvertCppSumType` returns `None` | every new golden's conversion splits; programs 2 to 6 COMPILE-FAIL |
    | M2: the optional arms swapped (`Some` built when `has_value()` is false) | match_std_optional_diff DIFF-MISMATCH (then a fenced `bad_optional_access`) |
    | M3: `std::get<i + 1>` in arm `i` | match_std_variant_diff DIFF-MISMATCH |
    | M4: the triviality rule dropped | fail_sum_types.carbon `fail_todo_non_trivial` |
    | M5: the qualification rule dropped | `fail_todo_qualified_alternative` |
    | M6: D-SV-8 reverted (measured equivalent: trunk's `c01`) | optional_pointer_payload.carbon; match_std_optional_diff's pointer lines |
    | M7: D-SV-9 reverted (measured equivalent: trunk's `r03` crash) | constant_choice_scrutinee.carbon (a crash); the roundtrip program's `.None` constant |
    | M8: the `Core.Optional` view removed | core_optional_view.carbon; match_core_optional_diff COMPILE-FAIL |
    | M9: the `InventClangArg` mapping removed | the roundtrip program COMPILE-FAIL; optional.carbon `convert` |
    | M10: `emplace<0>` in every arm of the reverse conversion | the roundtrip program DIFF-MISMATCH |
    | M11: `std::monostate` imported as its class | variant.carbon `monostate` (`CppSumTypeNotMapped`) |

6.  **Composition mirrors** (TP-1's §0.9 shape): for each of PR 57, PR 60,
    PR 59 and PR 61, a `git archive` of the branch head into
    `/dev/shm/sv1-impl/mirror-<b>`, SV-1's diff applied (measured to apply,
    §0.7), every translation unit that includes a changed file (by the
    branch build's `ninja -t deps`; all of them for kind.def) compiled from
    the composed sources and relinked over the branch's own build
    (`/home/user/carbon-build/carbon-{op2,sc,va,tp}`), then the gate over the
    mirror's testdata and the six programs. Predicted: each branch's own
    goldens unchanged, plus decayed_param.carbon's refill on the PR 57 mirror;
    on the PR 57 mirror also `o04` (5 6 -1 9) and D-SV-8's pointer payload
    (`s05`: 42 0 -1). Repeated at M against that day's heads.
7.  **Id re-scan** (before D; also run 2026-10-20 for §1.16):

    <!-- google-doc-style-ignore -->

    ```bash
    for r in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin/); do
      git show "$r:fork/inventory/work-items.json" 2>/dev/null \
        | grep -o '"id": *"W-[0-9]*"' | sed "s|^|$r |"
    done | grep -E 'W-(27[5-9]|28[0-9]|29[0-4])"'
    ```

    <!-- google-doc-style-resume -->

    Expected: no output (no id of the block filed anywhere). Run on
    2026-10-20 over 66 origin refs: no output; the highest filed id is W-274
    (origin/claude/carbon-fork-0-1-tp).
8.  **clang-tidy** on the changed translation units with the repository's
    `.clang-tidy` (upstream runs clangd-tidy; R21): `clang-tidy -p
    /home/user/carbon-build/carbon-sv <file>` for sum_type.cpp,
    custom_type_mapping.cpp, convert.cpp, refutable_binding.cpp,
    type_mapping.cpp, type.cpp, lower/constant.cpp; no new finding.
9.  **prek** on every changed path to a fixpoint:
    `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <paths>`, including check-toolchain-diagnostics (each
    new `CARBON_DIAGNOSTIC` used once, registered in kind.def).
10. **Not run here, and why**: the hosted gate and conformance (R28: the
    owner's runner is not used; Actions are disabled); Bazel-only tests
    (diagnostics/coverage_test.cpp, which checks that every diagnostic kind
    appears in some golden, is covered by construction: each new kind has a
    `fail_` split); LLVM-assertion builds (the container's LLVM is Release);
    macOS and Windows (another libc++ ABI or the MSVC STL); libstdc++ (not
    shipped with the toolchain); opt-mode conformance.

## Hand-off notes for the implementer

-   Start from `$P/proto/v3.diff` (the measured prototype) and `$P/final/`
    (the formatted final sum_type.{h,cpp} with the real diagnostics, the
    formatted hunks, kind.def and BUILD); copy, do not retype.
-   The prototype emits `context.TODO` for the new diagnostics; the final code
    in §2.4 replaces them. The `fail_` goldens' first fill will differ from
    the prototype's at exactly those lines.
-   Link prototypes with trunk's `carbon link` (§0.0); the full build of §8.1
    removes the need.
-   The goldens mock `std::optional`/`std::variant` (Appendix B); the
    programs use real libc++ (Appendix A). Keep both.
-   The arbiter's body loses its `default` arm; its header says why
    (R16(b)), and no other program is edited.
-   Records go in R and D after M, never before (§3 item 8); W-177 is
    discharged only if PR 56 has filed it on trunk.
-   Probe programs that pin every measured number of this plan are in
    `$P/probes/` (m*, n*, a*, t*, x*: trunk; v1/, w/, o/: the prototype);
    `$P/bin/probe.sh <carbon> <file>` re-runs any one.

## Appendix A: conformance programs

Byte copies of `$P/progs/`, each run on the prototype against its oracle
(§1.13); paths relative to fork/conformance/programs/.

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
// implicit conversion of the mapped type to `Core.Optional(T)`.
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
  let carbon_optional: Core.Optional(i32) = some;
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
// generic function over `Core.Optional(T)`. Differential pair:
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

fn CountSome[T: Core.Copy & Core.Destroy](o: Core.Optional(T)) -> i32 {
  match (o) {
    case .Some(unused value: T) => {
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
  Core.Print(CountSome(MaybePositive(Seed(2))));
  Core.Print(CountSome(MaybePositive(Seed(-2))));
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

template <typename T>
static auto CountSome(std::optional<T> o) -> int {
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
  std::printf("%d\n", CountSome(MaybePositive(Seed(2))));
  std::printf("%d\n", CountSome(MaybePositive(Seed(-2))));
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
// and matches it. Every payload is computed at run time (R16d).
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
  let half: f64 = 2.5;
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
  double half = 2.5;
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

The AUTOUPDATE sources of §1.12 without their CHECK lines (`$P/proto/goldens-v3/`
holds them filled by v3). Paths relative to toolchain/.

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
// `std::optional`/`std::variant` mapping, one diagnostic each, no crash.

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

// --- fail_todo_core_optional_argument.carbon

library "[[@TEST_NAME]]";

import Cpp library "sum.h";

// `Core.Optional(T)` reaches a C++ `std::optional<T>` parameter through its
// sum type, spelled with `as`; directly, it is the existing argument error.
fn H() -> i32 {
  return Cpp.Take(Core.Optional(i32).Some(3));
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
// predicate walks qualifiers inside adapters, so the pointer-niche
// `Core.Optional(T*)` -- an adapter of `MaybeUnformed(T*)` -- is a pointer
// payload, while `Core.Optional(T)` for a non-pointer `T`, a class with a
// `bool` beside its value, is still not one.

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
// scrutinee is matched as its view `Core.CppCompat.StdOptional(T)`, converted
// by value through the prelude's `ImplicitAs` impl; the class is unchanged.

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

// --- generic.carbon

library "[[@TEST_NAME]]";

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

## Revision record

-   Rev 1 (2026-10-20): first revision, for the two plan reviews of R29(c).
    The prototype was first drafted on 2026-10-15 and rebuilt, extended (v2,
    v3) and re-measured for this revision; every number above is from
    2026-10-20 unless marked.
