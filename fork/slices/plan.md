<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Slices plan: `Core.Slice(T)` + heap allocation (SL-1, W-055) and `std::span` mapping (SL-2, W-056)

**Status:** rev 2 — folded, signed off (2026-09-28); both slices landed
2026-10-05 — SL-1 verified of record (conformance run 37347619141; "Landed notes
(SL-1, 2026-10-05)" at the end of this file) and SL-2 landed pending its hosted
verification of record ("Landed notes (SL-2, 2026-10-05)" after it, with the
placeholders 37373875153 (fill 1d0c65f09) / 37395916761 (on 556a8669d; the first
gate, 37390683098, failed only on the round-5 fill's own `.loc` renumbering
inside vector_view_span.carbon, the two-pass convergence of R26, and convergence
run 37394549957 pushed 556a8669d, 130 `.loc` lines and nothing else) /
37390640614 (on affa54e8a, which the final head differs from only by the
scoreboard commit 2a17f0239 and the CHECK-only convergence commit) the
orchestrator stamps). The two adversarial plan reviews (R29(c); rev A, design
fidelity: 4 MAJOR + 6 MINOR; rev B, toolchain reality: 4 MAJOR + 7 MINOR; both
APPROVE-WITH-AMENDMENTS) are folded in place, each amendment marked "(amended
2026-09-28, review fold: rev A An / rev B Bn)" and tabled in the Review fold
record before Sign-off. Branch `claude/carbon-fork-0-1-slices` off trunk
8e32108f8 (post-PR #43: UN-1 landed; the weekly cut holds a sixth week). **Base
at rebase:** fork/conformance/out/scoreboard.json on this trunk reads
`totals.PASS = 114`, `totals.SKIP = 25`, every fail class 0, so `totals.PASS +
totals.SKIP = 139` programs (generated 2026-09-27T12:30:10Z on the
hosted-verification toolchain); the gap-analysis header
(fork/gap-analysis.md:18-20) agrees: 114 PASS / 0 FAIL / 25 SKIP over 139, 45/56
bullets, 27 DONE / 21 PARTIAL / 7 MISSING / 1 DESIGN-ONLY. OV-1 (+2 PASS / −1
SKIP / +1 total; source: the fork/decision-log.md entry "OV-1: `overload fn`
closed sets, first-match resolution (2026-09-28)" on branch
claude/carbon-fork-0-1-overload — 116 PASS / 0 FAIL / 24 SKIP over 140 on its
own c0c57285f base, run 36451200115) and UN-2 (+2 PASS / +2 total; source: the
fork/decision-log.md entry "UN-2: union C++ interop (2026-09-28)", merged to
trunk 50839d68e — 116 PASS / 0 FAIL / 25 SKIP over 141, run 36447037687) land
before this workstream, so the expected absolute base when SL-1 rebases is **118
PASS / 0 FAIL / 24 SKIP over 142** (the OV-1 entry's own post-merge reading of
scoreboard.json); every count below is stated as a DELTA and the absolutes are
re-quoted from scoreboard.json at rebase time, never derived (R9 — the last two
records were off by one from mental arithmetic) (amended 2026-09-28, review
fold: rev A A8: the deltas had no source in this tree). All toolchain, core,
docs and fork line numbers are against 8e32108f8 and were re-verified for this
plan; stale ledger citations are corrected in §0.2. The container cannot build
the toolchain (clang 18 < 19), so every golden and diagnostic outcome is
pre-registered for the hosted autoupdate to confirm or refute (R28(b)).

**Items:** W-055 ("W9a: implement Core slice type and heap allocation", size L,
subsystem core/prelude + check support) and W-056 ("W9b: transparent std::span /
contiguous-container view mapping", size M, blocked_by W-055). **Design
authority:** there is no fork design-sprint page for slices (`ls
fork/design-sprint`: error-handling, function-overloading, if-let, reading-list,
structural-conformance, threading-atomics, unions) and no decision-log entry
mentions slices, heap allocation or `std::span` (`grep -in 'slice\|heap\|span'
fork/decision-log.md` hits only choice-work "slice" in the PR sense), so this
plan establishes what UPSTREAM's design says (§0.3, D-SL-1..14) and applies
R29(a) where it is silent, never contradicting its direction (V-3). The upstream
sources, each cited where used: docs/design/README.md :872-916 ("Arrays and
buffers": `array(T, N)` = `Core.Array(T, N)`, `buf(T)` = `Core.Buf(T)`
"heap-allocated dynamically sized array"; "Slices": `> **TODO:** Slices`,
:912-914); docs/design/expressions/ indexing.md (the `IndexWith`/`IndirectIndexWith`
rewrite rules and the `class Span(T: type) { impl as IndirectIndexWith(like i64)
... }` example, :61-63, :116-121); docs/design/values.md:1125-1131 (pointers
"cannot be indexed or have pointer arithmetic performed on them ... Slice or
view style types are expected to provide access to indexable regions ... raw
pointer arithmetic ... through specialized constructs");
docs/design/safety/README.md:218-224 (the RELEASE build: "bounds checking is
enabled in the release build", plus an unsafe opt-out "that disables the
run-time enforcement") and :229-232 (the DEBUG build: detectable bugs get
"[fail-stop] behavior and provide detailed diagnostics" — the promise D-SL-4
adopts as the single 0.1 mode; amended 2026-09-28, review fold: rev A A3) with
safety/terminology.md:98-102 (fail-stop = "immediately terminating the
program"); docs/design/ classes.md:1849-1875 (the `Allocator` interface with
`Delete`/ `UnsafeDelete` over `Deletable`/`Destructible` facets, none of which
the toolchain has); docs/project/milestones.md:69 ("heap allocation" as an
example library component), :201-214 (the 0.1 stdlib list: "Slices";
"Transparent mapping between Carbon and C++ _non-owning_ contiguous container
types — Includes starting from an owning container and forming the non-owning
view and then transparently mapping that between languages");
proposals/p004682:310-332 (the owning-buffer vocabulary table: `Core.Buf(T)` is
the "Indirect, Mutable Size" row; "Carbon does not have proposed names for
heap-allocated storage, so we use some placeholders"); proposals/p002274:44-51
(a slice "refers to some region of an array ... such as `std::string_view` or
`std::span`") and :258-272 (read-only subscripting is an open problem). The
prelude's closest existing view type is `core/prelude/types/string.carbon:16-25`
(`class String { private var ptr: Char*; private var size: i64; }`) with its
indexing done by the builtin `"string.at"` (:31-33).

**Milestone bullets this plan flips** (R7: copied character-for-character
into every conformance header): fork/gap-analysis.md:76 "Stdlib: Slices"
— MISSING → PARTIAL at SL-1 (the 0.1 limits of D-SL-3/D-SL-6 are honest
residue, §8.6); fork/gap-analysis.md:79 "Stdlib C++ interop: transparent
non-owning contiguous container mapping (incl. owning->view)" — MISSING
→ DONE at SL-2, or PARTIAL if the D-SL-9 owning→view chain is refuted by
the hosted fill (§5.B, §7 R-9).

## §0 Audit: what already exists, and where the ledger is stale

### §0.1 Sub-feature table (verified in-tree at 8e32108f8)

| # | Element | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A slice type in the prelude | MISSING | `grep -rn Slice core/` is empty (W-055's note holds); the only "Slice" in the toolchain is the choice-work predicate `IsInSliceChoicePayloadType` (check/type.cpp) — a PR-slice name, unrelated |
| 2 | `array(T, N)` | LANDED as a toolchain builtin type, not a prelude class | `SemIR::ArrayType` (check/handle_index.cpp:52-84 indexes it directly with `ArrayIndex`; :56 "TODO: Replace this with impl lookup rather than hardcoding `i32`"); no `class Array` in core/ — README.md:874-876's "defined in the prelude" is aspirational. Runtime array indexing has NO bounds check: only constant indices are checked (eval.cpp:1160 `ArrayIndexOutOfBounds`; check/testdata/index/fail_array_out_of_bound_access.carbon) |
| 3 | Pointer arithmetic / element addressing | ABSENT by design and in the toolchain | values.md:1125-1131; the pointer builtins are exactly three: `pointer.make_null`, `pointer.is_null`, `pointer.unsafe_convert` (sem_ir/builtin_function_kind.def:151-153; .cpp:816-834; lower/handle_call.cpp:635-652). `pointer.unsafe_convert` lowers to the identity (:649-652) — it CAN retype `array(T, N)*` as `T*` (element 0 address) but cannot advance |
| 4 | Runtime element access through a view | LANDED for `str` only, as a whole-operation builtin | `"string.at"` (`StringAt`): validated `(CoreStringType, AnyType) -> CoreCharType` (builtin_function_kind.cpp:423-425, matcher :199-212 matches any class NAMED `String`); lowered as load `{ptr, size}`, `getelementptr inbounds i8`, load, zext (lower/handle_call.cpp:416-441); constant-evaluated with `StringAtIndexNegative`/`StringAtIndexOutOfBounds` diagnostics (eval.cpp:2552-2604) but NO runtime check |
| 5 | Fail-stop / abort primitive | MISSING | `grep -rn 'llvm.trap\|CreateUnreachable\|"abort"' toolchain/lower` is empty. The only libc reach-outs are `putchar`/`printf`/`getchar` (handle_call.cpp:382-411) and the `Core.Result` entry-point epilogue's `write(2, message, len)` (lower/handle.cpp:347-358, D10) — the stderr-message idiom this plan reuses |
| 6 | Heap allocation | MISSING | `grep -rn -i 'malloc\|calloc\|"free"' toolchain/lower toolchain/check core` is empty; `getOrInsertFunction` sites are the four above. `String` never allocates (a literal's storage is a global, lower/constant.cpp:354-360) |
| 7 | `IndexWith` | LANDED, `At` only | core/prelude/operators/index.carbon: `interface IndexWith(SubscriptType: type) { let ElementType: type; fn At(self, subscript: SubscriptType) -> ElementType; }` — no `Ref`, no `IndirectIndexWith` (indexing.md:61-63); `PerformIndexWith` (handle_index.cpp:33-43) looks up `IndexWith(<subscript's own type>)` and calls `At`; :79-80 "TODO: This should be replaced by a choice between using `IndexWith` and `IndirectIndexWith`". User impls: check/testdata/operators/overloaded/index_with_prelude.carbon:16-27 (`impl C as Core.IndexWith(SubscriptType) where .ElementType = ElementType`) |
| 8 | Generic prelude classes over a pointer field, unformed pointers, `unsafe as` | LANDED | optional.carbon:188-203 (`final impl forall [T: type] T* as OptionalStorage where .Type = MaybeUnformed(T*)`, `result unsafe as T* = self;` :194, `return value unsafe as T*;` :201, `PointerIsNull` :181, `MakeUninitializedOptionalPointer(generic T: type) -> MaybeUnformed(T*)` :183-184); `me.value unsafe as T = self;` (:162) and `return value.value unsafe as T;` (:170) are the nearest precedents for a symbolic-`T` store and copy — `unsafe as` ADAPTER casts on a `MaybeUnformed(T)` FIELD, not derefs of a `T*`; no check/lower golden derefs a checked-generic pointee and copies or stores it (pointer/basic.carbon:19 is concrete, generic/template_dependence.carbon:18-20 is `template T`, every `*p = ...` in lower/testdata is concrete) — R-4 names the shape (amended 2026-09-28, review fold: rev A A5); range.carbon:13-33 (`class IntRange(N: IntLiteral)` with an in-class `impl as Iterate`) |
| 9 | `Iterate` over arrays | LANDED | iterate.carbon:20-32 (`impl forall [T: Copy & Destroy, N: IntLiteral] array(T, N) as Iterate where .ElementType = T and .CursorType = i32`); the C++ range path :33-82 |
| 10 | Import mapping of a C++ std type onto a Carbon prelude type | LANDED for `std::string_view` ↔ `str` only | check/cpp/custom_type_mapping.cpp:93-99 (`StdStringView` matcher: `basic_string_view<char, char_traits<char>>` in `std`), :102-109 (`GetCustomCppTypeMapping` → `CustomCppTypeMapping::Str`), header :13-19 (a payload-less enum); consumed by import.cpp:1262-1274 (`LookupCustomRecordType` → `MakeStringType`), registered as the tag's inst by `MapTagType` :1277-1300 so the C++ class is never imported as a class. Golden check/testdata/interop/cpp/stdlib/string_view.carbon (a MOCK `std::basic_string_view` with `const CharT* data_; size_t size_;` — layout identity is the premise) |
| 11 | Export mapping of a Carbon prelude type onto a C++ std type | LANDED for `str`, `Optional(T*)`, `Result(T, E)` | sem_ir/type_info.h:351-388 `RecognizedTypeInfo::Kind` (…, `Optional`, `Result`, `Str`), type_info.cpp:148-151 `ExpectsArgs`, :165-196 (Core-root class recognized BY NAME through a `StringSwitch`); consumed by the EXHAUSTIVE `switch (type_info.kind)` in check/cpp/type_mapping.cpp:196-330 (`Optional` :267-285 unwraps `Optional(T*)` to `T*` through `WrappedType`, `Result` :286-318 instantiates `Carbon::expected` by way of `LookupCppClassTemplate` + `CheckTemplateIdType`, `Str` :319-321 `LookupCppType({"std", "string_view"})`); the SECOND exhaustive switch is `RecognizedTypeInfo::PrintLiteral` (type_info.cpp:238-295: no `default`, `case Optional: case Result: break;` at :285-287), reached from every stringifier/namer site (stringify.cpp:339/:891, inst_namer.cpp:1036/:1518) — that is, from every check golden that names a `Core.Slice(...)` type (amended 2026-09-28, review fold: rev B B4); the remaining consumers are comparisons, not switches (lower/type.cpp:587, lower/handle.cpp:301, export.cpp:1040, handle_function.cpp:388) |
| 12 | By-value passing of a mapped class across the thunk | LANDED | a non-simple-ABI parameter type (any class: thunk.cpp:260-275 `IsSimpleAbiType`) becomes a `_Nonnull` pointer thunk parameter (:509-515, :519-546); the Carbon side passes the object's address and the C++ side reinterprets the storage — `str`→`std::string_view` today, `Core.Slice(T)`→`std::span<T>` tomorrow on the same premise |
| 13 | Carbon array → C++ std type by value | LANDED for `std::initializer_list<T>` | operators.cpp:212-284 synthesizes a per-call builtin `cpp.std.initializer_list.make` (`(AnyArray) -> StdInitializerList`, layout recognized by sem_ir/cpp_initializer_list.cpp:13-49 as `{T*, T*}` or `{T*, size}`); lowered by `StoreArrayAsStdInitializerList` (handle_call.cpp:262-316) — it stores the ARRAY VALUE's pointer (`context.GetValue(array_inst_id)`, :276) as `begin`. This is the "array value aliased into a view" mechanism D-SL-2 deliberately does NOT generalize |
| 14 | Synthesized interface impls for C++ classes (owning→view precedent) | LANDED for `CppRangeForIterate` | impl_lookup.cpp:496-558 (`BuildCppRangeForIterateWitness`: member lookup `LookupCppMethod` :391-436 — when several overloads exist it keeps the `const`-qualified ones :403-416, "overload sets unsupported" TODO :423 — else ADL `LookupCppUnqualified` :438-494; the witness is `BuildCustomWitness(... {begin_result_type, end_result_type, begin_fn, end_fn})` in interface-member order); dispatched from the EXHAUSTIVE `switch (core_interface)` in `LookupCppImpl` :561-651 (:625-627) and listed in custom_witness.cpp:1487-1500; the kind is an x-macro entry (sem_ir/core_interface_kind.def:22) resolved by name (handle_interface.cpp:94-98) with a `CoreIdentifier` (core_identifier.def:37); prelude side iterate.carbon:33-82 (`private interface CppRangeForIterate`, constraints `CppIterator`/`CppSentinelFor`/`CppRange`, the blanket `Iterate` impl with projections `T.ValueType`, `T.Iterator`) |
| 15 | Real `std::vector`/`std::span` in tests | NONE | no check/lower golden and no conformance program includes `<vector>` or `<span>` (`grep -rl 'std::vector\|std::span' toolchain/*/testdata fork/conformance/programs` hits only the SKIP stub); cpp_template_builtins.carbon uses a mock `Cpp.vector(i32)`. The embedded Clang gets `-x c++` and `-stdlib=libc++` (base/clang_invocation.cpp:73-74, :139) and NO `-std=`, so Clang 21's default `gnu++17` applies — `<span>` needs `--clang-arg=-std=c++20` (driver flag `clang-arg`, compile_options.cpp:35; conformance directive `// COMPILE-ARGS:`, runner.py:140, :163-165) |
| 16 | Conformance stubs | SKIP | fork/conformance/programs/stdlib/slices_basic.carbon (bullet :5, EXPECT :6-9, SKIP :10, strawman :22-27 `Core.Slice(i32).Make(&a, 1, 3)`); interop/cpp_span_view.carbon (bullet :5, EXPECT :6-9, SKIP :10, strawman :35-39 `Cpp.SumSpan(a)` on an array VALUE and `v.AsSlice()` on an imported vector — both rewritten, D-SL-2/D-SL-9). The runner checks exit code and stdout only (`rc != prog.expect_exit` :587; `expect_stdout` :161, `None` = unchecked); a signal death reports Python's negative code |
| 17 | Docs | TODO stub | README.md:912-914; indexing.md is normative for the `IndirectIndexWith` future (D-SL-3); README.md:39 TOC entry exists |

### §0.2 Ledger and brief claims found stale (each corrected at §8.5 discharge)

1.  **W-055 evidence `slices_basic.carbon:6` and W-056 evidence
    `cpp_span_view.carbon:6`** point at the `EXPECT-EXIT` line; the SKIP
    lines are :10 in both files (the same off-by-four the unions plan
    found in W-009's citation). W-055's second evidence line
    `fork/gap-analysis.md:61` is stale too: the "Stdlib: Slices" row is
    :76 (:61 is the open-overload-sets row) (amended 2026-09-28, review
    fold: rev A A10).
2.  **W-056 evidence `custom_type_mapping.cpp:92-104`:** the `StdStringView`
    matcher is :93-99 and `GetCustomCppTypeMapping` is :102-109. More
    importantly the note "custom_type_mapping.cpp is the mechanism this
    extends" names only the IMPORT half: the export half is
    `RecognizedTypeInfo` (type_info.cpp:165-196) plus the type_mapping.cpp
    switch (§0.1 row 11), and the owning→view half is the synthesized-impl
    machinery of impl_lookup.cpp (§0.1 row 14). All three are in-plan.
3.  **W-055 subsystem "core/prelude (+ check support as needed)":** the
    work is NOT prelude-only. Pointer advancement, fail-stop and
    malloc/free do not exist as builtins (§0.1 rows 3, 5, 6), so SL-1
    adds four `BuiltinFunctionKind`s with check validation, eval and
    lowering arms (D-SL-5). The ledger note gets that record.
4.  **W-055 note "grep -rn Slice in core/ returns nothing (verified)"**
    still true; **"heap allocation is likewise absent"** true; the
    parenthetical "no separate SKIP program exists for it" is true and
    stays true — §5.A attaches the heap program to the "Stdlib: Slices"
    bullet because its arbiter is a slice over heap storage (no bullet
    row exists for heap allocation and R7 forbids inventing one).
5.  **gap-analysis §W9 "Depends on: Definition-checked variadics
    implementation, Sum types with payloads, native unions, and
    std::variant/optional interop" (:161):** none of the four is a
    dependency of W-055/W-056 (nothing in §1 touches variadics, choice
    payloads, unions or the variant/optional mapping); the line describes
    W9's OTHER halves (String/Optional). Recorded, not edited (the header
    is a W9-level statement).
6.  **gap-analysis row 74 "String is a 33-line non-owning {Char*, u64}"** —
    string.carbon:23-25 declares `size: i64` (the `u64` is the min_prelude PART,
    toolchain/testing/testdata/min_prelude/parts/ string.carbon:14-17; amended
    2026-09-28, review fold: rev A A10). Corrected in the row text at discharge
    (the `String`/`Slice` layout twin-ship matters for D-SL-8).
7.  **cpp_span_view.carbon's strawman `Cpp.SumSpan(a)`** (array value
    passed as a span) contradicts values.md:1125-1131's explicit-view
    philosophy and would alias a value binding that the design allows to
    be a COPY (README.md:1301-1303 "implemented using a pointer, unless it
    is legal to copy and copying is cheaper") — D-SL-2 rejects it; the
    view is formed explicitly from `&a`. **`v.AsSlice()`** on an imported
    `std::vector` cannot exist (Carbon cannot add methods to an imported
    class); D-SL-9 replaces it with the conversion `let view:
    Core.Slice(const i32) = v;`. Both are disclosed in the un-SKIP commit
    per R6's F8d template.
8.  **README.md:874-876 "`array(T, N)` ... shorthand for the library type
    `Core.Array(T, N)`. This type is defined in the prelude."** — false in
    the toolchain (§0.1 row 2). Not this plan's to fix (upstream text);
    D-SL-1 is written against the ACTUAL builtin array type and the
    amendment in §8.6 says so.
9.  **W-056 note "a span matcher plus owning-container->view conversions
    alongside the shipped str<->std::string_view mapping"** — accurate as
    far as it goes; add: the mapping needs an ELEMENT-TYPE payload the
    current payload-less enum cannot carry (header :13-19), and the
    static-extent `std::span<T, N>` must be excluded (D-SL-8).

### §0.3 Decisions this plan auto-adopts (R29(a): design recommendation under V-2/V-3, veto-able after the fact)

Each decision cites the upstream text it follows or the silence it
fills, and carries a break condition. Decision-log entry F-012 is
written at SL-1 discharge (§8.5) with these sub-decisions verbatim.

-   **D-SL-1 — `Core.Slice(T)` is a prelude class `{ptr: T*, size:
    i64}` with `T: Copy & Destroy`, spelled `Core.Slice(T)` in full.**
    Layout-identical to `String` (string.carbon:23-25) and to the
    `{T*, size_t}` object representation of libc++'s and libstdc++'s
    dynamic-extent `std::span` (the premise §0.1 rows 10/12 already rest
    on for `str`). The element constraint is the one `Iterate` and
    `Optional` already impose (iterate.carbon:20, optional.carbon:140 —
    amended 2026-09-28, review fold: rev A A10);
    `const T` satisfies it (copy.carbon:22 `impl forall [T: Copy] const T
    as Copy`; the destroy witness walks through `ConstType`,
    custom_witness.cpp:272-275) so `Slice(const i32)` — the mapping of
    `std::span<const int>` — is well-formed. No keyword shorthand: the
    design's provisional `[T]` "sized pointer" spelling (p004682:324-329)
    is not adopted (unlike `buf`/`array` it never reached README.md).
    V-3: README.md:912-914 is a TODO; values.md:1125-1131 asks for
    exactly a "slice or view style type"; no contradiction. Break
    condition: an accepted upstream proposal names the slice type or its
    literal syntax — rename/alias then, layout unchanged.
-   **D-SL-2 — views are formed from POINTERS to arrays
    (`Core.Slice(T).FromArray(&a)`, `fn FromArray[N: IntLiteral](p:
    array(T, N)*) -> Self`), from `Buf` (`b.AsSlice()`), from a raw
    pointer+size (`UnsafeMake`, D-SL-11) and from other slices
    (`Subslice`); there is NO implicit conversion from an array VALUE.**
    Rationale: a value binding of array type may be implemented by copy
    (README.md:1301-1303), so a view of `self` inside a `Convert(self)`
    could alias a temporary — silent dangling (R15); and `&a` is the
    design's syntactic marker for aliasing (values.md:1121-1125). The
    `std::initializer_list` precedent (§0.1 row 13) aliases an array
    value only for the duration of one C++ call and is not generalized.
    Consequence for interop (§1.B): a Carbon array reaches
    `std::span<const int>` as `Cpp.SumSpan(Core.Slice(i32).FromArray(&a))`,
    not `Cpp.SumSpan(a)`. Break condition: an upstream indexing/slices
    design specifies an array→slice conversion; the pinned golden
    `fail_array_value_no_conversion` (§4.A) is deleted then.
-   **D-SL-3 — indexing is `IndexWith.At` returning the element BY
    VALUE, bounds-checked at runtime; `Slice` is read-only in 0.1.**
    indexing.md:116-121's `Span` implements `IndirectIndexWith` with a
    `Ref` returning `ref T`, but the toolchain has neither
    `IndirectIndexWith` nor `ref` returns (§0.1 row 7; handle_index.cpp
    :79-80 TODO) and the prelude's `IndexWith` has only `At`. So `s[i]`
    is a value expression: reads work for every `T: Copy`, and `s[i] = v`
    diagnoses `AssignmentToNonAssignable` "expression is not assignable"
    (handle_operator.cpp:110-116) — loud, pinned as `fail_write_through`.
    Writes to owned storage go through `Buf.Set` (D-SL-6). No `Set` on
    `Slice`: a `Slice(const T)` over C++ read-only memory would compile
    its store at the symbolic definition (the const check at
    handle_operator.cpp:107-113 sees only the unqualified symbolic `T`)
    and fault at runtime — the one shape R15 forbids. Break condition:
    `IndirectIndexWith`/`ref`-returning methods land in the toolchain;
    `Core.Slice` then switches to indexing.md's `Span` shape and the
    pin is deleted.
-   **D-SL-4 — a bounds violation is a fail-stop: one line on stderr, then
    `abort()`; unconditional in 0.1 (no build modes).** Attribution, stated
    precisely (amended 2026-09-28, review fold: rev A A3):
    safety/README.md:218-221 says of the RELEASE build only that "bounds
    checking is enabled in the release build", and :222-224 that Carbon "will
    provide ways to write unsafe code that disables the run-time enforcement";
    the fail-stop-plus-diagnostics sentence is the DEBUG build's — :229-232
    begins "The debug build will change the actual behavior ... to have
    [fail-stop] behavior and provide detailed diagnostics"
    (safety/terminology.md:98-102 defines fail-stop). The toolchain has no
    build-mode notion (README.md:379-385 is design text only), so 0.1 has ONE
    mode, and this plan adopts the debug-build promise as that mode — an R29(a)
    fill under a missing notion, not behavior the release text mandates; the
    check is always on. The release paragraph's enforcement opt-out is
    upstream-specified residue this plan does not implement (`UnsafeMake`/`Data()`
    form views; they do not provide an unchecked READ), filed by title as
    "unchecked slice access (the release-build enforcement opt-out,
    safety/README.md:222-224)" in §1.A.6/§8.5. Mechanism: the prelude tests `i <
    0 or i >= self.size` in Carbon and calls the `fail_stop` builtin (D-SL-5),
    which lowers as `write(2, message.ptr, message.size)` (the exact `write`
    declaration of lower/handle.cpp:349-350, so both sites share one
    module-level declaration) followed by a call to `abort` marked `noreturn`.
    No `unreachable` is emitted after the call: the checker still emits the
    branch to the merge block after the `if` body, and a terminator mid-block
    would be invalid IR — a `noreturn` call followed by dead code is valid and
    the optimizer folds it (R-1 falsifier below). The message names the
    operation, not the index (no integer formatting at this level; `printf` from
    a generic prelude body is not available): `carbon: Core.Slice index out of
    bounds; terminating`, `carbon: Core.Slice.Subslice range out of bounds;
    terminating`, `carbon: Core.Buf index out of bounds; terminating`, `carbon:
    Core.Buf size is negative; terminating`, `carbon: heap allocation failed;
    terminating`. Exit is SIGABRT (6). Break condition: build modes land (the
    check becomes mode-gated) or a `CARBON_DIAGNOSTIC`-style runtime diagnostics
    facility exists (message gains the index).
-   **D-SL-5 — four new builtins, all runtime-only, declared `private`
    in the prelude: `"pointer.offset"` (`fn PointerOffset[T: type](p: T*,
    n: i64) -> T*`), `"fail_stop"` (`fn FailStop(message: str)`),
    `"heap.allocate"` (`fn HeapAllocate(generic T: type, count: i64) ->
    MaybeUnformed(T*)`), `"heap.free"` (`fn HeapFree[T: type](p: T*)`).**
    values.md:1128-1130: raw pointer arithmetic "through specialized
    constructs" — a private prelude builtin is such a construct; users
    get no `+` on pointers. Exposure is identical to the existing
    `pointer.unsafe_convert`: a builtin body `= "name"` is accepted in any
    file (lower/testdata/builtins/pointer.carbon:13-15 declares
    `pointer.make_null`/`pointer.is_null` outside `Core`), so a user who
    writes `= "pointer.offset"` gets it — no new surface class. Why not
    a whole-operation `"slice.at"` like `"string.at"`: it would push the
    bounds check, the message and a by-value copy of an arbitrary `T`
    into lowering (the `PrimitiveCopy`/`CopyValue` machinery), whereas
    the composable form keeps every semantic line in Carbon source
    (R17). Why `heap.allocate` returns `MaybeUnformed(T*)`: the prelude
    can then test failure with the EXISTING `pointer.is_null` idiom and
    reveal the pointer with `unsafe as T*` exactly as optional.carbon
    :196-202 does. Break condition: upstream adds pointer-offset or
    allocation builtins under other names — rename, one line each.
-   **D-SL-6 — heap allocation is the owning class `Core.Buf(T: Copy & Destroy)`
    (`{ptr: T*, size: i64}`) over libc `malloc`/`free`:
    `Make(size: i64, fill: T)`, `Size(self)`, `Get(self, i)`,
    `Set(self, i, value)`, `AsSlice(self)`, `impl as Destroy` frees; not `Copy`,
    not `UnformedInit`; no `buf(T)` keyword; no `Allocator` interface; element
    destructors are NOT run.** README.md:887-889 names `Core.Buf(T)` (with
    `buf(T)` as the shorthand) as THE heap-allocated dynamically sized array —
    p004682:316-322 calls the name a placeholder, but it is the only
    heap-storage spelling upstream's design text carries, so V-3 says use it.
    The `buf` shorthand would be a lexer/parser change for a placeholder name:
    residue. classes.md:1849-1875's `Allocator` needs `Deletable`/`Destructible`
    facets the toolchain lacks: residue, mechanism named. Every element is
    initialized from `fill` (no unformed elements escape: `MaybeUnformed` never
    leaves `Make`), the fill loop assigns through `*PointerOffset(ptr, i) =
    fill` — an `InitializeExisting` into a `Deref` of symbolic `T`, whose
    nearest precedent is the optional.carbon:162 adapter-cast store; R-4 names
    the shape and its isolating golden lines (amended 2026-09-28, review fold:
    rev A A5). `Set(self, ...)` takes `self` by value on purpose: the storage is
    the heap block the pointer names, so no `ref self` is needed, and D-SL-3's
    const hazard does not arise (heap memory is writable; `Buf(const T)` is
    legal but pointless). Element destructors: `Buf(T)`'s `Destroy` frees the
    block without running `T`'s destructor per element, mirroring what
    `Optional(T)`/`MaybeUnformed(T)` already do (maybe_unformed.carbon :12-16
    adapts a builtin that the destroy walk treats as trivial,
    custom_witness.cpp:277-281, :641-645) — there is no precedent for an
    explicit `Destroy.Op` call in Carbon source (`grep -rn 'Destroy.Op)()'
    toolchain/check/testdata core` is empty). Residue with the break condition
    "explicit destroy calls or `TrivialDestructor` facets land
    (generics/details.md:4190-4192)". `Buf` has no `Copy` impl, so copying is a
    compile error (`CopyOfUncopyableType`, §4.A `fail_copy`), never a double
    free — custom_witness.cpp:1461-1467 synthesizes `Copy` only for choice and
    union self types, so nothing is synthesized for `Buf`. **`Buf` is NOT
    `UnformedInit`** (amended 2026-09-28, review fold: rev B B1 / rev A A9): the
    toolchain runs `Destroy` on every `var` UNCONDITIONALLY —
    pattern_match.cpp:1727 registers the cleanup
    (`AddInstWithCleanup<SemIR::VarStorage>`) BEFORE `Initialize` runs (the
    `GetOrAddVarStorage` path at :1680 likewise); control_flow.h:75-83 →
    `MaybeAddCleanupForInst` (control_flow.cpp:143-148) → scope_stack.h:256-258
    `PushCleanupFor`; control_flow.cpp:151-158 `AddCleanups` builds a `Destroy`
    call for every registered id; there is no unformed-state tracking anywhere
    (`grep
    -n unformed` over pattern_match.cpp, control_flow.cpp and
    handle_let_and_var.cpp is empty; lower/testdata/var/param.carbon:62-66 shows
    the unconditional destroy call on a `var`). The design's "destroy is skipped
    for unformed variables" rule is therefore UNIMPLEMENTED, and an
    `UnformedInit` `Buf` would let `var b: Core.Buf(i32);` compile and then
    `free()` stack garbage at scope exit — nothing in §4/§5 executes that path,
    so it would have shipped green. Instead `var b: Core.Buf(i32);` is a
    compile-time `DefaultOrUnformed` failure, pinned as `fail_unformed` (§4.A),
    and the residue title "`Core.Buf` unformed declarations (needs
    unformed-state-aware destroy)" is filed (§8.5). `Slice` keeps its
    `UnformedInit`: it has no user `Destroy` and its `{T*, i64}` fields are
    trivially destroyed, so an unformed `Slice` is as harmless as an unformed
    `String` (string.carbon:28). Over-aligned `T` (alignment > `max_align_t`) is
    residue (`malloc` only guarantees 16). Break condition: an upstream proposal
    names the heap types — rename; an `Allocator` design lands — `Buf` gains an
    allocator parameter defaulting to the global one.
-   **D-SL-7 — `Core.Slice(T)` implements `Iterate`** (`.CursorType =
    i64`, mirroring iterate.carbon:20-32 for arrays) so `for (x: T in s)`
    works; appended at the END of iterate.carbon so no existing method's
    source line moves (the EH-A churn lesson, fork/eh/plan.md:1199-1215).
    No break condition needed (pure addition).
-   **D-SL-8 — `std::span<T, std::dynamic_extent>` ↔ `Core.Slice(T')` in
    both directions; static-extent spans stay ordinary class imports.**
    milestones.md:209-214. Import: custom_type_mapping.cpp gains a
    `StdSpan` matcher (`span` in `std`, two template arguments: a type,
    and an integral equal to `dynamic_extent`, that is all-ones `size_t`)
    and the mapping result gains an element-type payload; import.cpp's
    `LookupCustomRecordType` builds `Core.Slice(T')` by
    `LookupNameInCore(CoreIdentifier::Slice)` + `PerformCall` (the
    `MakeOptionalType` shape, :1367-1372) over `ImportCppType(element)`.
    Export: `RecognizedTypeInfo::Slice` (a Core-root class named `Slice`
    with one argument) → `std::span<T'>` instantiated by
    `LookupCppClassTemplate({"std", "span"})` + `CheckTemplateIdType` (the
    `Result` arm's shape, type_mapping.cpp:286-318) with `T'` mapped
    recursively through `WrappedType` (the `Optional` arm's shape,
    :267-285). Static extents: excluded because their layout is `{T*}`
    only and `Core.Slice` carries a size. Break condition: the layout
    premise fails on a supported libc++ (R-6 falsifier) — then the
    mapping becomes a thunk-side conversion like `initializer_list`.
-   **D-SL-9 — owning → view is a synthesized `Core.CppContiguousRange`
    (member `data()` + `size()`) plus a prelude blanket `ImplicitAs(Core
    .Slice(C.Element))`, so `let view: Core.Slice(const i32) = v;` and
    `Cpp.SumSpan(v)` both work for a `Cpp.std.vector(i32)`.**
    milestones.md:211-214 ("starting from an owning container and forming
    the non-owning view and then transparently mapping"). The mechanism
    is the `CppRangeForIterate` one (§0.1 row 14), which the fork already
    ships for the iteration bullet: a new `CoreInterface` kind, a witness
    built from `LookupCppMethod` of `data` and `size` (the const-overload
    filter :403-416 selects `data() const`, so a `std::vector<int>` yields
    `const int*` → `Core.Slice(const i32)`, which is exactly what
    `std::span<const int>` parameters need), and a prelude constraint
    `CppContiguous` (the `CppRange` shape, iterate.carbon:57-64) whose
    alias `Element` strips the pointer (through a private helper
    interface with impls for `T*` and `Optional(T*)`, because a C++ `T*`
    return maps to `Optional(T*)` unless `_Nonnull`, import.cpp:1380-1386)
    and whose `Size` converts in TWO steps, `ImplicitAs(u64)` then `As(i64)`
    (amended 2026-09-28, review fold: rev A A2). `size_t` maps to `u64` where
    `uint64_t` is `unsigned long` (Linux) and to `Core.CppCompat.ULong64`
    where it is `unsigned long long` (macOS; type_info.h:363-365). *Amended
    2026-10-05 (SL-2 round 2): the per-target reading above is RIGHT, and the
    round-1 amendment that called it "wrong on both counts" is withdrawn —
    import.cpp `MapBuiltinIntegerType` first asks `GetIntNType(64, unsigned)`
    = the target's `uint64_t` and maps to `u64` on `hasSameType`; x86_64
    Linux has `Int64Type = SignedLong`, so `unsigned long` IS `uint64_t`
    there and imports as `u64`; the `ULong64` arm is reached only on Darwin
    (`Int64Type = SignedLongLong`), and `ULong32` on LLP64 (upstream pins:
    primitive_types/long_and_long_long.{lp64,darwin,llp64}.carbon). The
    second fill's vector_view.carbon shows `custom_witness (%Optional.f0c,
    %u64, ...)` on the hosted runner. `ImplicitAs(u64)` holds on every
    target — `u64` through uint.carbon's `UInt(From) as ImplicitAs(To)` over
    `FromUInt(u64)` (what the fill resolved; as.carbon's `T: Copy` identity
    is the other candidate), `ULong64` through cpp/int.carbon:173, `ULong32`
    through :124, `u32` through uint.carbon — and the two-step spelling is
    justified by Darwin alone. The helper interface is the public
    `CppDataPointer` (round-1 note, §2.B.9).*
    `u64` has
    `As(Int(64))` (uint.carbon:97-99) but `ULong64` does NOT: cpp/int.carbon
    :150-176 gives it only `ImplicitAs(IntLiteral)` (comptime
    `int.convert_checked`), `ImplicitAs(u64)` (:172-174) and the `IntLiteral →
    ULong64` pair, and as.carbon:27 forwards `ImplicitAs(U)` to `As(U)` for
    the SAME `U` only — impl lookup does not chain `ULong64 → u64 → i64`. A
    `require Self.(SizeType) impls As(i64)` constraint would thus be
    unsatisfied on macOS, the owning→view conversion would silently not exist
    there, and hosted verification (`runs-on: ubuntu-22.04`,
    .github/workflows/fork_hosted.yaml:38) could not refute it. The constraint
    is `require Self.(SizeType) impls ImplicitAs(u64)` — satisfied by `u64`
    through as.carbon:37 (the `T: Copy` identity; uint.carbon:26) and by
    `ULong64` through cpp/int.carbon:172-174 — and the body converts
    `self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)()`
    (uint.carbon:97-99 for the second step). Chosen over the alternative of
    appending `impl CppCompat.ULong64 as As(i64) { fn Convert(self) -> i64 =
    "int.convert"; }` to cpp/int.carbon because it edits no existing prelude
    file (zero DI-churn exposure, the EH-A lesson) and adds no prelude impl
    whose only consumer would be this chain; the alternative stays as R-9's
    second contingency if the two-step spelling is refuted. This is
    the plan's longest unverified chain (five mechanism steps) and gets
    its own commit, golden and falsifier (§7 R-9); **fallback, loud:**
    if the hosted fill refutes it, SL-2 lands the D-SL-8 mapping alone,
    the bullet flips to PARTIAL, `cpp_span_view.carbon` stays SKIP with
    the refreshed reason "owning→view: synthesized CppContiguousRange
    chain refuted at <run>, see F-012", and the residue item is filed.
    Rejected alternatives: (a) a thunk-side conversion (the thunk's
    parameter types come from the CALLEE, thunk.cpp:530-543; the Carbon
    side converts arguments to the mapped parameter type, so there is no
    place to hand Sema a `vector` where the thunk expects a `span`); (b)
    calling `std::span`'s constructor from Carbon (the mapped
    specialization's members are never imported, §0.1 row 10); (c) an
    explicit `UnsafeMake(v.data().Get(), v.size() as i64)` in user code
    (not "transparent"; kept only as the documented escape hatch).
    Break condition: upstream ships a contiguous-range interface — the
    synthesized interface is renamed to it.
-   **D-SL-10 — `Slice(T)` implicitly converts to `Slice(const T)`**
    (`impl forall [T: Copy & Destroy] Slice(T) as ImplicitAs(Slice(const
    T))`, the pointer precedent as.carbon:53-55). Needed so a
    `Slice(i32)` from `FromArray(&a)` passes to a `std::span<const int>`
    parameter. No break condition.
-   **D-SL-11 — `Core.Slice(T).UnsafeMake(p: T*, size: i64) -> Self` is
    public.** `Buf.AsSlice` (a different class, no private access) and
    the D-SL-9 prelude impl need it; the `Unsafe` prefix follows
    classes.md:1867 (`UnsafeAllowDelete`), details.md:4186
    (`UnsafeDelete`) and `UnsafeAs`. Break condition: none.
-   **D-SL-12 — the fail-stop conformance program asserts `EXPECT-EXIT:
    -6`.** runner.py:454-463 returns `subprocess.run(...).returncode`
    unmodified and :587 compares it with `expect_exit`; Python documents
    a negative value −N as "terminated by signal N"; SIGABRT is 6 on
    Linux and macOS (the two supported hosts). The program prints nothing
    before the violation (stdout is unchecked: `abort` does not flush
    `stdout` buffers, so a checked stdout would be a false negative under
    pipes). Break condition: the runner grows a `// EXPECT-SIGNAL:`
    directive — switch to it.
-   **D-SL-13 — docs: a new normative page docs/design/slices.md
    (dated 2026-09-28 fork amendment) and a dated replacement of
    README.md:912-914's TODO with a summary plus link; indexing.md is not
    edited** (its `Span` example remains the target shape; slices.md
    records the 0.1 deviation D-SL-3 and its break condition). The
    interop README gains one dated paragraph at SL-2.
-   **D-SL-14 — goldens mock `std::span` (as string_view.carbon mocks
    `basic_string_view`); conformance uses the real `<span>` with
    `// COMPILE-ARGS: --clang-arg=-std=c++20`.** §0.1 row 15. A mock
    keeps the goldens hermetic and pins the exact layout premise
    (`T* data_; size_t size_;` with `dynamic_extent` as the default
    second argument). Break condition: the fork's Clang default moves to
    C++20 — drop the directive.

### §0.4 The split decision: two PR-sized workstreams, sequential

R29(b): one PR per scoreboard flip. The two bullets are distinct rows,
W-056 is `blocked_by` W-055, and their toolchain footprints are disjoint
(SL-1: sem_ir builtins, eval, lower, prelude; SL-2: check/cpp, sem_ir
type_info, prelude interop impls).

-   **SL-1 (W-055, PR "SL-1: Core.Slice, Core.Buf and the runtime
    bounds fail-stop"):** the four builtins (kind.def entries, signature
    validation, eval runtime-only arms, lowering arms) with their
    builtin goldens; `core/prelude/types/slice.carbon` (new),
    `core/prelude/types/buf.carbon` (new), two `export import` lines in
    types.carbon, the `Iterate` impl appended to iterate.carbon; check and
    lower goldens for the prelude types; conformance (`slices_basic`
    SKIP→PASS, `slices_heap_buf` and `slices_bounds_fail_stop` new);
    docs/design/slices.md + README amendment; ledger; gap-analysis row
    76 PARTIAL. Size M+ (four small toolchain arms, ~180 prelude lines).
-   **SL-2 (W-056, PR "SL-2: std::span ↔ Core.Slice mapping and
    owning-container views"):** custom_type_mapping payload + `StdSpan`
    matcher + import arm; `RecognizedTypeInfo::Slice` + export arm; the
    synthesized `CppContiguousRange` (core_interface_kind.def,
    core_identifier.def, impl_lookup.cpp witness, custom_witness.cpp
    list) + the prelude constraint and `ImplicitAs` impl (in
    slice.carbon's interop section — `iterate.carbon` is not touched);
    goldens (check: stdlib/span.carbon, function/export/slice.carbon,
    impls/cpp_contiguous_range.carbon, stdlib/vector_view.carbon; lower:
    interop/cpp/span.carbon); conformance (`cpp_span_view` SKIP→PASS,
    `cpp_span_roundtrip_diff` new with a C++ oracle); interop README
    paragraph; ledger; gap-analysis row 79 DONE (or PARTIAL, D-SL-9
    fallback). Size M. Starts when SL-1's hosted verification is green
    (R29(d): its planner-level spec is complete here).
-   **Contention:** SL-2 touches check/cpp/import.cpp (one switch arm
    inside `LookupCustomRecordType` :1262-1274 and one ~10-line helper
    beside `MakeOptionalType` :1367) and type_mapping.cpp (one arm in
    `TryMapClassType`). UN-2 (in flight, W-015) touches import.cpp's
    class-import region (:592-865) and export.cpp — different hunks;
    OV-3 touches generate_ast.cpp only. SL-2 rebases after UN-2 merges
    (it starts after SL-1 anyway); no W-007 refactor precondition is
    triggered because no two of {UN-2, OV-3, SL-2} edit the same hunk.
-   Rejected: one PR (mixes the C++-side mapping into the landing whose
    scoreboard flip — row 76 — is observable at SL-1 alone, and would
    hold the prelude type hostage to the D-SL-9 chain); three PRs with
    heap allocation separate (no bullet flips for it; its only arbiter
    is a slice over heap storage, so it is the same feature's second
    program, §0.2 item 4).

## §1 Design decisions

### §1.A SL-1 — `Core.Slice(T)`, `Core.Buf(T)`, the builtins

#### §1.A.1 The four builtins (sem_ir/builtin_function_kind.{def,cpp})

Names, validated signatures (matchers from builtin_function_kind.cpp:
`TypeParam` :57-70, `PointerTo` :87-98, `MaybeUnformed` :100-114,
`NoReturn` :116-126 — "the return type is `()`", `AnySizedInt` :160,
`AnyType` :191-196, `CoreStringType` :199-212), lowering and eval:

| Kind (x-macro name) | Name string | `ValidateSignature<...>` | Lowering (lower/handle_call.cpp, new arms before `CppStdInitializerListMake` :654) | eval.cpp |
| --- | --- | --- | --- | --- |
| `PointerOffset` | `"pointer.offset"` | `auto(PointerTo<TypeParam<0, AnyType>>, AnySizedInt)->PointerTo<TypeParam<0, AnyType>>` | `CreateInBoundsGEP(elem_type, p, {sext_or_trunc(n, i64)}, "ptr.offset")` where `elem_type = context.GetType(pointee of the arg's SemIR pointer type)` — the same element type lowering `[N x T]` arrays use | runtime-only (added to the `NotConstant` list :2606-2637) |
| `FailStop` | `"fail_stop"` | `auto(CoreStringType)->NoReturn` | load the `str` value as `StringAt` does (:417-425: `CreateLoad(string_type, arg)`, `extractvalue {0}` ptr, `extractvalue {1}` size, `CreateSExtOrTrunc(size, i64)`); `write = getOrInsertFunction("write", i64, i32, ptr, i64)` (byte-identical to handle.cpp:349-350); `CreateCall(write, {i32 2, ptr, size})`; `abort = getOrInsertFunction("abort", void)`, `cast<Function>(abort.getCallee())->setDoesNotReturn()`; `CreateCall(abort)`; NO terminator (D-SL-4) | runtime-only |
| `HeapAllocate` | `"heap.allocate"` | `auto(AnySizedInt)->MaybeUnformed<PointerTo<AnyType>>` (the `generic T: type` parameter is not a runtime parameter and is not validated — the `MakeUninitializedOptionalPointer(generic T: type) -> MaybeUnformed(T*) = "make_uninitialized"` precedent validates `auto()->AnyType`) | `arg_ids.size() == 1` and `arg_ids[0]` is `count` (the `generic T` is not a call parameter: check/function.cpp:69-72 `take_front(explicit_end)`); `elem_type` from the RESULT type — which in the prelude is the ADAPTER CLASS `Core.MaybeUnformed(T*)` (maybe_unformed.carbon:13-15 `class MaybeUnformed(T: Destroy) { adapt MakeMaybeUnformed(T); }`), so the call's type is a `ClassType` and a bare `TryGetAs<SemIR::MaybeUnformedType>` returns nullopt (signature validation passes only because `CheckType` walks adapters, builtin_function_kind.cpp:268-280; neither existing pointer arm needs the pointee, so there is no precedent to copy) — resolved as `sem_ir.types().GetTransitiveAdaptedType(type_id)` (or `GetObjectRepr`, sem_ir/type.h:207-214) in the type's own file, `CARBON_CHECK` that the unwrapped type is a `MaybeUnformedType` (a miss is a fatal, never a silent null element type), then `GetPointeeType`, then `context.GetType({file, pointee})` (which handles an adapter pointee such as `i32` = `Core.Int(32)`, lower/type.cpp:663) (amended 2026-09-28, review fold: rev B B2); `bytes = mul(sext_or_trunc(count, i64), i64 getTypeAllocSize(elem_type))`; `bytes = select(icmp eq bytes 0, i64 1, bytes)` (a zero-length or zero-sized request still yields a unique non-null block — `malloc(0)` may return null); `malloc = getOrInsertFunction("malloc", ptr, i64)`; result `CreateCall(malloc, {bytes})` | runtime-only |
| `HeapFree` | `"heap.free"` | `auto(PointerTo<AnyType>)->NoReturn` | `free = getOrInsertFunction("free", void, ptr)`; `CreateCall(free, {p})` | runtime-only |

`IsCompTimeOnly` (:919-985; the file has 988 lines, `default: return
false` at :982 — amended 2026-09-28, review fold: rev A A10) needs no
change. Every
switch over `BuiltinFunctionKind` is exhaustive: eval.cpp's
`EvalBuiltinFunctionCall` (the four go into the runtime-only case list
:2606-2637 — a missing case is a compile error, the R-3 class), and
lower/handle_call.cpp's `HandleBuiltinCall` (:318-665, ends in
`CARBON_FATAL("Unsupported builtin call.")` :664 — a missing arm is a
RUNTIME fatal, so each of the four gets an arm AND a lower golden that
executes it, §4.A). `CARBON_DEFINE_ENUM_CLASS_NAMES` (:845) is x-macro
generated. The name table `ForBuiltinName` is generated from the same
`BuiltinInfo` array, so a typo in the string surfaces as
`UnknownBuiltinFunctionName` (handle_function.cpp:835-838) in the
prelude's own compile — the hosted `compile` probe catches it before any
golden (R-3).

#### §1.A.2 `core/prelude/types/slice.carbon` (new; the exact text is §2.A.5)

```carbon
package Core library "prelude/types/slice";

import library "prelude/copy";
import library "prelude/default";
import library "prelude/destroy";
import library "prelude/operators";
import library "prelude/types/bool";
import library "prelude/types/int";
import library "prelude/types/int_literal";
// Used only by the interop section SL-2 appends (§1.B.3); imported at SL-1
// so that SL-2 adds no line above any method (§6.B, DI-line churn).
import library "prelude/types/optional";
import library "prelude/types/string";

private fn PointerOffset[T: type](p: T*, n: i64) -> T* = "pointer.offset";
private fn FailStop(message: str) = "fail_stop";
private fn ArrayData[T: type, N: IntLiteral](p: array(T, N)*) -> T*
    = "pointer.unsafe_convert";

class Slice(T: Copy & Destroy) {
  // A view of the `N` elements of `*p`.
  fn FromArray[N: IntLiteral](p: array(T, N)*) -> Self {
    return {.ptr = ArrayData(p), .size = N};
  }
  // A view of `size` elements starting at `p`. The caller guarantees
  // that `p` names at least `size` valid elements that outlive the view.
  fn UnsafeMake(p: T*, size: i64) -> Self {
    return {.ptr = p, .size = size};
  }
  fn Size(self) -> i64 { return self.size; }
  // The raw pointer to element 0 (the twin of `std::span::data()`); no
  // arithmetic on it is possible from user code.
  fn Data(self) -> T* { return self.ptr; }
  // Bounds-checked read; a violation fails-stop (D-SL-4).
  fn Get(self, i: i64) -> T {
    if (i < 0 or i >= self.size) {
      FailStop("carbon: Core.Slice index out of bounds; terminating\n");
    }
    return *PointerOffset(self.ptr, i);
  }
  // The half-open sub-view `[start, end)`; `0 <= start <= end <= Size()`.
  fn Subslice(self, start: i64, end: i64) -> Self {
    if (start < 0 or end < start or end > self.size) {
      FailStop(
          "carbon: Core.Slice.Subslice range out of bounds; terminating\n");
    }
    return {.ptr = PointerOffset(self.ptr, start), .size = end - start};
  }

  impl as Copy {
    fn Op(self) -> Self { return {.ptr = self.ptr, .size = self.size}; }
  }

  private var ptr: T*;
  private var size: i64;
}

impl forall [T: Copy & Destroy] Slice(T) as UnformedInit {}

// Amended 2026-10-05 (round 3, R-5): `IndexWith(i64)` only — the blanket
// `U: ImplicitAs(i64)` impl of rev 2 cannot lower for `U = IntLiteral`.
// Amended 2026-10-05 (round 4, D-SL-18): `final`, so the `where` rewrite is
// known in a generic body (a symbolic lookup resolves only final impls).
final impl forall [T: Copy & Destroy] Slice(T) as IndexWith(i64)
    where .ElementType = T {
  fn At(self, subscript: i64) -> T { return self.Get(subscript); }
}

// `const` can be added to the element type (D-SL-10).
impl forall [T: Copy & Destroy] Slice(T) as ImplicitAs(Slice(const T)) {
  fn Convert(self) -> Slice(const T) {
    return Slice(const T).UnsafeMake(self.Data() as const T*, self.Size());
  }
}
```

Mechanism notes, each with its in-tree precedent (R3): the import list
is acyclic — `prelude/types/*` files import `prelude/operators` and
sibling types (int.carbon:7-13, char.carbon:7-14) and only
`prelude/iterate`/`prelude/range` import `prelude/types` (iterate.carbon
:7-10), so slice.carbon must NOT import `prelude/iterate` (the `Iterate`
impl lives in iterate.carbon, D-SL-7). `str` inside `Core` is the type
literal for `Core.String` (core/io.carbon:15 `fn PrintStr(msg: str)` —
amended 2026-09-28, review fold: rev A A10), so the
`FailStop` declaration needs `prelude/types/string` only for the literal
argument's class to be complete. `self.ptr as const T*` is as.carbon
:57-59 (`T* as As(const T*)`); `.size = N` converts the symbolic
`IntLiteral` `N` to `i64` through int.carbon:31-33 inside a generic body
exactly as iterate.carbon:25 compares `*cursor < N` — `N` is a GENERIC
parameter, a constant in every specific, so its `int.convert_checked` folds
(the round-3 crash class is a RUNTIME value of type `IntLiteral`; amended
2026-10-05). The rev 2 `subscript.Convert()` on a `U: ImplicitAs(i64)`
parameter (cited to optional.carbon:110-115/:128-133 and to String) was
exactly that class and is gone — R-5's 2026-10-05 amendment.
Returning `*PointerOffset(...)` (a durable reference of symbolic type
`T`) from a `-> T` function copies through `Copy` as optional.carbon
:170-172 (`return value.value unsafe as T;`) does — the nearest
precedent, an adapter cast on a `MaybeUnformed(T)` field rather than a
`Deref` of a `T*`; R-4 names both symbolic-pointer shapes and the
isolating `Load`/`Store` lines in builtins/pointer/offset.carbon that
make a prelude failure attributable (amended 2026-09-28, review fold:
rev A A5). `i < 0` and `end >
self.size` are `Int(N) as OrderedWith(T: ImplicitAs(Int(N)))`
(int.carbon:113) and the `Int(N) as OrderedWith(Int(M))` (:98) impls.
The private fields are readable only from the class's own methods and
in-class impls (string.carbon:19-25 is the shape), so every
out-of-class impl reaches the data through the public API only:
`IndexWith` through `Get`, `ImplicitAs(Slice(const T))` through
`Data()`/`Size()`/`UnsafeMake` — the optional.carbon:103-108 shape of
an out-of-class impl building the class through its public constructor
(`Optional(T).Some(self)`; :74-76 is `Try.Branch` — amended 2026-09-28,
review fold: rev A A10). The in-class alternative (`impl as
ImplicitAs(Slice(const T))` reading `self.ptr`) was rejected because no
golden shows a generic class body naming itself with DIFFERENT arguments
(`grep -rn` over check/testdata/class/generic finds only same-argument
self references), and an unverifiable shape in the prelude is a compile
probe failure with no fallback. `Buf.AsSlice` (a different class) uses
`UnsafeMake` for the same private-access reason; a reviewer should apply
this test to every impl in §1.B.3 (they use `UnsafeMake`, `Size`, `Get`
only). `Data()` is public on purpose: it is `std::span::data()`'s twin,
the D-SL-9 conversion is built on the same member on the C++ side, and
a raw `T*` is not indexable in Carbon (values.md:1125), so it leaks no
arithmetic.

#### §1.A.3 `core/prelude/types/buf.carbon` (new)

```carbon
package Core library "prelude/types/buf";

import library "prelude/copy";
import library "prelude/default";
import library "prelude/destroy";
import library "prelude/operators";
import library "prelude/types/bool";
import library "prelude/types/int";
import library "prelude/types/maybe_unformed";
import library "prelude/types/slice";
import library "prelude/types/string";

private fn PointerOffset[T: type](p: T*, n: i64) -> T* = "pointer.offset";
private fn FailStop(message: str) = "fail_stop";
private fn HeapAllocate(generic T: type, count: i64) -> MaybeUnformed(T*)
    = "heap.allocate";
private fn HeapFree[T: type](p: T*) = "heap.free";
private fn PointerIsNull[T: type](value: MaybeUnformed(T*)) -> bool
    = "pointer.is_null";

// An owning, heap-allocated buffer of `size` values of `T`. Not copyable.
class Buf(T: Copy & Destroy) {
  // Allocates `size` elements, each initialized to a copy of `fill`.
  fn Make(size: i64, fill: T) -> Self {
    if (size < 0) {
      FailStop("carbon: Core.Buf size is negative; terminating\n");
    }
    var storage: MaybeUnformed(T*) = HeapAllocate(T, size);
    if (PointerIsNull(storage)) {
      FailStop("carbon: heap allocation failed; terminating\n");
    }
    let ptr: T* = storage unsafe as T*;
    var i: i64 = 0;
    while (i < size) {
      *PointerOffset(ptr, i) = fill;
      ++i;
    }
    return {.ptr = ptr, .size = size};
  }
  fn Size(self) -> i64 { return self.size; }
  fn Get(self, i: i64) -> T { return self.AsSlice().Get(i); }
  // Bounds-checked write. `self` is by value: the storage is the heap
  // block, not the `Buf` object.
  fn Set(self, i: i64, value: T) {
    if (i < 0 or i >= self.size) {
      FailStop("carbon: Core.Buf index out of bounds; terminating\n");
    }
    *PointerOffset(self.ptr, i) = value;
  }
  fn AsSlice(self) -> Slice(T) {
    return Slice(T).UnsafeMake(self.ptr, self.size);
  }

  impl as Destroy {
    fn Op(ref self) { HeapFree(self.ptr); }
  }

  private var ptr: T*;
  private var size: i64;
}

// No `UnformedInit`: `Destroy` runs unconditionally on `var` storage, so an
// unformed `Buf` would free a garbage pointer (D-SL-6).

// Amended 2026-10-05 (round 3, R-5): `IndexWith(i64)` only, as for `Slice`;
// round 4 (D-SL-18): `final`, as for `Slice`.
final impl forall [T: Copy & Destroy] Buf(T) as IndexWith(i64)
    where .ElementType = T {
  fn At(self, subscript: i64) -> T { return self.Get(subscript); }
}
```

Precedents: `HeapAllocate(T, size)` with an explicit `generic` type argument
is optional.carbon:183-184/:192-193 (`MakeUninitializedOptionalPointer(T)`);
`storage unsafe as T*` is :201; `PointerIsNull` :181/:198; the fill assignment
through a symbolic-`T` referent has :162 as its nearest precedent (an
adapter-cast store, not a `T*` deref — R-4; amended 2026-09-28, review fold:
rev A A5); the in-class `impl as Destroy { fn Op(ref self) ... }` is
lower/testdata/var/param.carbon:17-21 (a user class) — on a CONCRETE class, as
is every in-tree user `Destroy` impl (:36-41;
lower/testdata/operators/question_generic.carbon:114-121 `Tag`), so `Buf(T)`'s
is the first inside a generic class and R-12 carries its falsifier (amended
2026-09-28, review fold: rev A A9); redeclaring a builtin in a second prelude
file is default.carbon:52-54 versus optional.carbon:145-146
(`"make_uninitialized"` twice; amended 2026-09-28, review fold: rev A A10).
The `Buf` class has no `Copy` impl, so `var c: Buf(i32) = b;` diagnoses
`CopyOfUncopyableType` at the copy (pinned, §4.A `fail_copy`).

#### §1.A.4 `Iterate` for slices (appended to core/prelude/iterate.carbon after :82)

```carbon
// Amended 2026-10-05 (round 4, D-SL-18): `final`, as the `IndexWith(i64)`
// impls are, so `for (x: T in s)` in a generic body binds `T`.
final impl forall [T: Copy & Destroy]
    Slice(T) as Iterate
    where .ElementType = T and .CursorType = i64 {
  fn NewCursor(unused self) -> i64 { return 0; }
  fn Next(self, cursor: i64*) -> Optional(T) {
    if (*cursor < self.Size()) {
      ++*cursor;
      return Optional(T).Some(self.Get(*cursor - 1));
    } else {
      return Optional(T).None();
    }
  }
}
```

A line-for-line twin of the array impl (:20-32) with `i64` for the
cursor and `Size()`/`Get()` for the bound and the read. `Buf` gets no
`Iterate` impl: `for (x in b.AsSlice())` is the idiom (one impl, one
golden).

#### §1.A.5 `core/prelude/types.carbon`

Two lines in alphabetical position: `export import library
"prelude/types/buf";` after `bool` (:9) and `export import library
"prelude/types/slice";` after `result` (:20). Nothing else in the file
carries code, so no DI line shifts (the §6 rule).

#### §1.A.6 What SL-1 does NOT do (each a residue title, §8.5)

`buf(T)` keyword shorthand; `IndirectIndexWith`/write-through `s[i] =
v`; `Buf` element destructors; an `Allocator` interface; over-aligned
element types; unchecked slice access (the release-build enforcement
opt-out, safety/README.md:222-224 — D-SL-4; amended 2026-09-28, review
fold: rev A A3); `Core.Buf` unformed declarations (needs
unformed-state-aware destroy — D-SL-6; amended 2026-09-28, review fold:
rev B B1); `Buf.Resize`/`Push` (the design's "Mutable Size" is the
STORAGE class, not an API promise, p004682:316); array-value → slice
conversion (D-SL-2); comptime evaluation of slice reads (all four
builtins are runtime-only; a constant `Core.Slice` never forms because
`&a` of a local is not constant); freeing a `Buf` held in a FIELD of
another type (synthesized aggregate destroy ops are the member-destruction
placeholder — W-108, filed as W-105 at the round-2 fix and renumbered at
discharge; amended 2026-10-05).

### §1.B SL-2 — `std::span` mapping and owning-container views

#### §1.B.1 Import: `std::span<T, dynamic_extent>` → `Core.Slice(T')`

-   **custom_type_mapping.h:** `enum class CustomCppTypeMapping` becomes
    `struct CustomCppTypeMapping { enum Kind : uint8_t { None, Str,
    Span }; Kind kind = Kind::None; // For `Span`: the element type.
    clang::QualType element_type; };` and `GetCustomCppTypeMapping`
    returns it. The two existing consumers (import.cpp:1265-1273's
    switch, and nothing else — `grep -rn CustomCppTypeMapping toolchain`
    hits only the .h/.cpp pair and import.cpp) switch on `.kind`.
-   **custom_type_mapping.cpp:** in `namespace Matchers` add
    `DynamicExtent` (`arg.getKind() == clang::TemplateArgument::Integral
    && arg.getAsIntegral().isAllOnes()` — `std::dynamic_extent` is
    `static_cast<size_t>(-1)` in every implementation) and `StdSpan`
    (`StdClassTemplate("span", TemplateArgumentsAre({TypeTemplateArgument
    (AnyType), DynamicExtent}))` with `AnyType = [](clang::QualType) {
    return true; }`); `GetCustomCppTypeMapping` returns `{.kind = Span,
    .element_type = args[0].getAsType()}` when it matches. `std::span<T,
    3>` fails `DynamicExtent` and is imported as an ordinary class
    (§4.B `static_extent_is_a_class`).
-   **import.cpp:** beside `MakeOptionalType` (:1367-1372) add
    `MakeSliceType(Context&, SemIR::LocId, SemIR::InstId
    element_type_inst_id) -> TypeExpr` (`LookupNameInCore(context, loc_id,
    CoreIdentifier::Slice)` + `PerformCall` + `ExprAsType`); in
    `LookupCustomRecordType` (:1262-1274) the new arm: `case
    CustomCppTypeMapping::Span: { auto element = ImportCppType(context,
    loc_id, mapping.element_type); if (element.inst_id ==
    SemIR::ErrorInst::InstId) return TypeExpr::None; return
    MakeSliceType(context, loc_id, element.inst_id); }` where `loc_id`
    is the `AddImportIRInst(record_decl->getLocation())` the `Str` arm
    already forms. A `const int` element maps to `const i32` through
    `MapQualifiedType` (:1330-1343), so `std::span<const int>` →
    `Core.Slice(const i32)`.
-   **core_identifier.def:** `CARBON_CORE_IDENTIFIER(Slice)` (sorted
    between `Result` :80 and `SubAssignWith`). The x-macro feeds only the
    identifier table; no switch.
-   Thunk: `std::span<...>` is not a simple ABI type (thunk.cpp:260-275),
    so the thunk parameter is `std::span<const int>* _Nonnull` and the
    Carbon call passes the `Slice` object's address — byte-identical
    behavior to the `str` path. Returns (`std::span<int> Produce()`) use
    the out-pointer form (`!has_simple_return_type`, :540-543).

#### §1.B.2 Export: `Core.Slice(T')` → `std::span<T'>`

-   **sem_ir/type_info.h:** `Kind` gains `Slice` ("`Core.Slice(...)`")
    after `Result`; type_info.cpp:148-151 `ExpectsArgs` returns true for
    it; :187-192 `.Case("Slice", Slice)`.
-   **check/cpp/type_mapping.cpp:** the exhaustive switch (:196-330)
    gains `case SemIR::RecognizedTypeInfo::Slice:` — one argument, facet
    unwrapped as the `Optional` arm does (:270-273), then `return
    WrappedType{.inner_type_id = <the argument's type>, .wrap_fn =
    [](Context& context, clang::QualType inner) { auto* tmpl =
    LookupCppClassTemplate(context, {"std", "span"}); if (!tmpl) return
    clang::QualType(); <one TemplateArgumentListInfo with `inner`;
    CheckTemplateIdType as :311-318> }}`. A TU without `std::span`
    declared maps to null and the existing loud paths report it: the
    `context.TODO(loc_id, "failed to map Carbon type to C++")` sites
    (export.cpp:894 and :950, the parameter sites that `Sum`'s
    `Core.Slice(const i32)` parameter reaches; the return-type site :960
    prints a DIFFERENT text, "failed to map Carbon return type to C++",
    and :504/:1747 are the field and remaining sites — amended
    2026-09-28, review fold: rev B B11) — no new diagnostic kind, one
    pinned golden (`fail_no_span_header`). `std::span<const int>` needs
    `const i32` to map: `ConstType` is already an arm of `TryMapType`
    (string_view's `const CharT*` return types round-trip today).
-   **sem_ir/type_info.cpp `RecognizedTypeInfo::PrintLiteral` (:238-295) is a
    SECOND exhaustive switch over `Kind`** — no `default`, `case Optional:
    case Result: break;` at :285-287 — and it gains `case Slice: break;`
    beside them: a slice has no literal spelling (D-SL-1 rejects `[T]`), so
    `Core.Slice(...)` keeps printing through the ordinary class path. It is
    reached from every stringifier/namer site (stringify.cpp:339/:891,
    inst_namer.cpp:1036/:1518), so a missing case is a `-Wswitch` error on
    every check golden that names the type (R-3; the compile probe catches
    it). The type_mapping.cpp switch and `PrintLiteral` are the only two
    exhaustive switches; every comparison site (§0.1 row 11) keeps working
    (amended 2026-09-28, review fold: rev B B4).

#### §1.B.3 Owning → view: synthesized `Core.CppContiguousRange`

-   **sem_ir/core_interface_kind.def:** `CppContiguousRange` (sorted
    after `Copy` :21, before `CppRangeForIterate` :22). **core_identifier
    .def:** `CppContiguousRange` (before `CppRangeForIterate` :37).
    handle_interface.cpp:94-98 resolves the prelude interface's kind by
    name automatically (x-macro `.Case`).
-   **check/cpp/impl_lookup.cpp:** `BuildCppContiguousRangeWitness`
    modeled on :496-542: look up member `data` and member `size` with
    `LookupCppMethod` only (no ADL fallback: `std::data`/`std::size` free
    functions exist but the design's owning containers all have members;
    the `Unqualified` path stays for a residue); read each callee's
    `return_type_inst_id`; `BuildCustomWitness(context, loc_id, self,
    interface, {data_result_type, size_result_type, data_fn, size_fn})`
    — the witness table follows the interface's member order (`let
    DataType; let SizeType; fn Data; fn Size`). `LookupCppImpl`'s
    exhaustive switch (:561-651) gains the case; custom_witness.cpp
    :1487-1500's list gains the kind (both are the R-3 class).
-   **Prelude (slice.carbon, interop section at the end of the file):**

    ```carbon
    private interface CppContiguousRange {
      let DataType: type;
      let SizeType: type;
      // TODO: self must be ref-qualified (as CppRangeForIterate).
      fn Data(self) -> DataType;
      fn Size(self) -> SizeType;
    }

    // The element type behind a C++ `data()` result, which maps to `T*`
    // when `_Nonnull` and to `Optional(T*)` otherwise.
    private interface CppDataPointer {
      let Element: type;
      fn Raw(self) -> Element*;
    }
    impl forall [T: type] T* as CppDataPointer where .Element = T {
      fn Raw(self) -> T* { return self; }
    }
    impl forall [T: type] Optional(T*) as CppDataPointer where .Element = T {
      // `None` (an empty container) yields the null pointer; a zero-size
      // slice never dereferences it.
      fn Raw(self) -> T* { return self.Get(); }
    }

    private constraint CppContiguous {
      extend require impls CppContiguousRange;
      require Self.(DataType) impls CppDataPointer;
      // `ImplicitAs(u64)`, not `As(i64)`: `CppCompat.ULong64` (macOS
      // `size_t`) has no `As(i64)` impl (D-SL-9).
      require Self.(SizeType) impls ImplicitAs(u64);
      alias Element = Self.(DataType).(CppDataPointer.Element);
    }

    impl forall [C: CppContiguous where .Element impls Copy & Destroy]
        C as ImplicitAs(Slice(C.Element)) {
      fn Convert(self) -> Slice(C.Element) {
        return Slice(C.Element).UnsafeMake(
            self.Data().(CppDataPointer.Raw)(),
            self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
      }
    }
    ```

    Shapes: the constraint with `extend require impls`, `require
    Self.(X) impls Y` and an `alias` projection is iterate.carbon:57-64
    (`CppRange`); the blanket impl with a `where .X impls` bound and a
    projection in the target interface is :66-82 (`T as Iterate where
    .ElementType = T.ValueType`); the explicit `.(Interface.Method)()`
    call is :78 (`cursor->0.(CppUnsafeDeref.Op)()`). slice.carbon already
    imports `prelude/types/optional` from SL-1 (§1.A.2; acyclic:
    optional.carbon:7-14 imports no `types/slice`), so SL-2 only APPENDS
    this section — no existing line of slice.carbon moves (amended
    2026-09-28, review fold: rev A A4). For a `std::vector<int>` `v`:
    `Data()` is `data() const` (the const filter, impl_lookup.cpp
    :403-416) → `Optional(const i32*)` → `Element = const i32`;
    `Size()` is `size() const` → `u64` (Linux) or
    `Core.CppCompat.ULong64` (macOS), both `ImplicitAs(u64)`, then `u64
    as As(i64)` (D-SL-9; amended 2026-09-28, review fold: rev A A2); the
    result is
    `ImplicitAs(Slice(const i32))` — the exact parameter type of
    `SumSpan(std::span<const int>)`, and the declared type of `let view:
    Core.Slice(const i32) = v;`.
-   Not synthesized: containers whose `data()`/`size()` come only from a
    base class through ADL, or whose `size()` is not `const` (the filter
    keeps the const overload when several exist and otherwise takes the
    single one).

#### §1.B.4 What SL-2 does NOT do (residue titles)

Static-extent spans; `std::span` → `Core.Slice` for element types that
are themselves mapped classes with non-trivial C++ copy (the `T: Copy`
witness of an imported class is `BuildCopyWitness`, untested here);
`std::string` → `str` (a different bullet); `std::array`/C arrays as
sources of owning→view beyond the member `data()`/`size()` rule
(`std::array` has both, so it works; a raw `int[5]` does not — the
Carbon side uses `FromArray(&Cpp.arr)`); `std::mdspan`.

## §2 Implementation spec

### §2.A SL-1 (file by file)

1.  **toolchain/sem_ir/builtin_function_kind.def:** after
    `PointerUnsafeConvert` (:153) add `PointerOffset`; a new block `//
    Runtime failure.` with `FailStop`; a new block `// Heap allocation.`
    with `HeapAllocate`, `HeapFree` — all before `// Facet type
    combination.` (:155).
2.  **toolchain/sem_ir/builtin_function_kind.cpp:** four `constexpr
    BuiltinInfo` entries next to `PointerUnsafeConvert` (:829-832) with
    the §1.A.1 signatures and a one-line comment each ("`pointer.offset`:
    the address of the element `n` positions after `*p`; the caller
    guarantees the result stays inside one allocation" etc.). No matcher
    changes.
3.  **toolchain/check/eval.cpp:** the four kinds join the runtime-only
    list (:2606-2637) — exhaustive switch.
4.  **toolchain/lower/handle_call.cpp:** four arms per §1.A.1, placed
    after `PointerUnsafeConvert` (:649-652). Helper names: `"ptr.offset"`,
    `"fail_stop.ptr"`/`"fail_stop.size"`, `"heap.bytes"`/`"heap.block"`.
5.  **core/prelude/types/slice.carbon (new):** §1.A.2 verbatim (every
    out-of-class impl uses public API only; the private-access reasoning
    is recorded there).
6.  **core/prelude/types/buf.carbon (new):** §1.A.3.
7.  **core/prelude/types.carbon:** two export lines (§1.A.5).
8.  **core/prelude/iterate.carbon:** §1.A.4 appended after :82.
9.  **Goldens:** §4.A (all AUTOUPDATE with empty CHECK lines, R15/R19).
10. **Conformance:** §5.A.
11. **Docs:** docs/design/slices.md (new, D-SL-13), README.md:912-914,
    README.md:39 (link target unchanged). See §8.6.
12. **Ledger/gap/ORCHESTRATION:** §8.5, §8.7.

### §2.B SL-2 (file by file)

1.  **toolchain/check/cpp/custom_type_mapping.{h,cpp}:** §1.B.1 (struct
    with payload; `DynamicExtent`, `AnyType`, `StdSpan` matchers).
2.  **toolchain/check/cpp/import.cpp:** `MakeSliceType` beside :1367;
    the `Span` arm in `LookupCustomRecordType` :1265-1273; the existing
    `Str` arm switches to `mapping.kind`.
3.  **toolchain/check/core_identifier.def:** `CppContiguousRange`,
    `Slice`.
4.  **toolchain/sem_ir/type_info.{h,cpp}:** `Slice` kind; `ExpectsArgs`;
    `.Case("Slice", Slice)`; `case Slice: break;` in `PrintLiteral`
    beside `Optional`/`Result` (:285-287) — the second exhaustive switch
    (§1.B.2; amended 2026-09-28, review fold: rev B B4).
5.  **toolchain/check/cpp/type_mapping.cpp:** the `Slice` arm (§1.B.2).
6.  **toolchain/sem_ir/core_interface_kind.def:** `CppContiguousRange`.
7.  **toolchain/check/cpp/impl_lookup.cpp:** `BuildCppContiguousRange
    Witness` + the `LookupCppImpl` case (§1.B.3).
8.  **toolchain/check/custom_witness.cpp:** :1487-1500 list gains the
    kind (it answers nullopt like `CppRangeForIterate`).
9.  **core/prelude/types/slice.carbon:** the interop section (§1.B.3),
    APPENDED after the last SL-1 line; the `prelude/types/optional`
    import is already in the SL-1 header (§1.A.2), so no existing line
    moves (amended 2026-09-28, review fold: rev A A4).
    -   **Amended 2026-10-05 (SL-2 round 1, after hosted autoupdate run
        37356848697 moved 306 files; R28(d) review miss, the plan's own
        placement was right).** The implementation put the whole section,
        blanket impl included, in a NEW library
        core/prelude/types/cpp/slice.carbon because `u64` (the rev A A2
        constraint) is not nameable in slice.carbon and the import line
        would move the SL-1 lower goldens' DI lines. That broke the
        prelude for every full-prelude program: `impl forall [C:
        CppContiguous ...] C as ImplicitAs(Slice(C.Element))` is an
        orphan there (impl_validation.cpp `DiagnoseOrphanImpl` walks the
        SELF type and the INTERFACE SPECIFIC for a class of the same
        library — `Slice` is prelude/types/slice's; a facet-type bound on
        the self binding does not count), and even had it type-checked,
        impl lookup imports candidates only from the IRs owning the
        query's self/interface/arguments (impl_lookup.cpp
        `FindAssociatedImportIRs`, `CollectCandidateImplsForQuery`), so
        an impl in cpp/slice would never have been a candidate for
        `Cpp.VectorLike as ImplicitAs(Slice(const i32))`. Two more errors
        rode along: the impl body's `self.Data()`/`self.Size()`
        temporaries need `Destroy`, and `CppContiguousRange` declares bare
        `let DataType: type; let SizeType: type;` (a synthesized witness
        can provide no other associated-constant type:
        custom_witness.cpp `BuildCustomWitness` TODOs on it), so the
        requirement is stated on the constraint, the `CppIterator`
        shape (`require Self.(DataType) impls CppDataPointer & Destroy;
        require Self.(SizeType) impls CppSizeToI64 & Destroy;`). The
        landed layout, zero DI churn (the review's variant): the helpers
        stay in cpp/slice.carbon as PUBLIC Core names (`CppContiguousRange`,
        `CppDataPointer`, `CppContiguous`, the `CppUnsafeDeref` precedent)
        plus a new `interface CppSizeToI64 { fn Op(self) -> i64; }` with
        `impl forall [T: ImplicitAs(u64)] T as CppSizeToI64` (keeps `u64`
        out of slice.carbon); cpp/slice.carbon no longer imports
        prelude/types/slice; slice.carbon's SL-1-reserved
        `prelude/types/optional` import line (unused there) became
        `import library "prelude/types/cpp/slice";` at the same line
        count (`class Slice` stays at :24), and the blanket impl is
        appended to slice.carbon with `self.Size().(CppSizeToI64.Op)()`.
        Import graph acyclic: cpp/slice imports copy, destroy, operators,
        types/int, types/optional, types/uint, none of which reach
        types/slice (only prelude/types, prelude/iterate and types/buf
        do). The §1.B.3 sketch is otherwise the landed text.
10. **Goldens:** §4.B. **Conformance:** §5.B. **Docs:** interop README
    paragraph + slices.md status line (§8.6).

## §3 Commit structure

**SL-1 (PR "SL-1: Core.Slice, Core.Buf and the runtime bounds
fail-stop"), four commits:**

1.  sem_ir + eval + lower: the four builtins (§2.A.1-4) + their builtin goldens
    (check/testdata/builtins/{pointer/offset, failstop,
    heap/allocate_free}.carbon; lower/testdata/builtins/{pointer_offset,
    failstop, heap}.carbon — named after the builtin WITHOUT the `fail_` prefix,
    which file_test reserves for diagnosing files; amended 2026-09-28, review
    fold: rev B B3), CHECK-free. Run the hosted `compile` probe on this commit
    alone (R-3 hand-off).
2.  prelude: slice.carbon, buf.carbon, types.carbon, iterate.carbon
    (§2.A.5-8) + check/lower goldens for the types (§4.A), CHECK-free.
3.  conformance (§5.A: `slices_basic` rewritten, `slices_heap_buf`,
    `slices_bounds_fail_stop`) + gap-analysis row 76 PARTIAL + ledger
    (§8.5).
4.  discharge: decision-log F-012, docs (§8.6), ORCHESTRATION stamp,
    residue items (ids allocated then).

**SL-2 (PR "SL-2: std::span ↔ Core.Slice mapping and owning-container
views"), four commits (after UN-2 merges; rebase first):**

1.  import + export mapping (§2.B.1-5) + goldens stdlib/span.carbon,
    function/export/slice.carbon, lower interop/cpp/span.carbon.
2.  synthesized `CppContiguousRange` + prelude interop section (§2.B.6-9)
    -   goldens impls/cpp_contiguous_range.carbon, stdlib/vector_view
        .carbon. **This commit is the D-SL-9 fallback boundary:** if its fill
        is refuted and the fix is not one round, the PR lands without it
        (§5.B's PARTIAL outcome) and the commit becomes the residue's
        starting patch.
3.  conformance (§5.B) + gap-analysis row 79 + ledger.
4.  discharge: interop README, decision-log note under F-012,
    ORCHESTRATION stamp, residue.

## §4 Testdata matrix (R16: no hand-written goldens; autoupdate fills)

Rules baked in from the recent landings: every golden ships with `// AUTOUPDATE`
and EMPTY CHECK lines; in LOWER goldens, positives never share a file with
`fail_` subfiles (one erroring subfile blanks the lower golden of a split file)
— CHECK goldens MAY mix positive and `fail_` subfiles, since file_test judges
each split on its own `per_file_success` (file_test_base.cpp:238-248;
testing/file_test/README.md:81-83) and upstream check testdata does so
everywhere, which is what §4.A's pointer/offset, failstop and heap/allocate_free
files do (amended 2026-09-28, review fold: rev B B7); no golden FILE or split
carries the `fail_` prefix unless it diagnoses — `CompareFailPrefix`
(file_test_base.cpp:126-135, applied to the main file at :233-256 whenever no
split fails) fails a passing test whose name starts with `fail_` (amended
2026-09-28, review fold: rev B B3); a `fail_` subfile's predicted diagnostic
names the KIND and the message so the fill is a confirm/refute, not a discovery;
identifiers never collide with the words.md:47-104 keyword list (`base`,
`default`, `destroy`, `like`, `runtime`, `then`, `union` are the traps — none is
used below); `//@dump-sem-ir-begin/end` brackets every positive so the prelude
is excluded from the dump.

### §4.A SL-1

-   **check/testdata/builtins/pointer/offset.carbon** (`min_prelude/int
    .carbon`; the pointer/is_null.carbon shape with user-declared builtins): `fn
    Offset[T: type](p: T*, n: i64) -> T* = "pointer.offset";` and `fn F(p: i32*)
    -> i32* { return Offset(p, 1); }`. Predicted: a `%Offset.specific_fn` call
    in `@F` with `%p` and the `int_1` constant converted to `i64`; no
    diagnostics. Two ISOLATING lines for R-4's symbolic-pointer shapes (amended
    2026-09-28, review fold: rev A A5): `fn Load[T: Core.Copy](p: T*) -> T {
    return *p; }` (`ConvertToValueExpr` on a `Deref` of symbolic `T` → `Copy`
    witness) and `fn Store[T: Core.Copy](p: T*, v: T) { *p = v; }` (`InitializeExisting`
    into a `Deref` of symbolic `T`; `Core.Copy` is in min_prelude/int.carbon
    through parts/copy.carbon). Predicted: in `@Load` a `Copy.Op` witness call
    on the dereferenced value, in `@Store` an `assign` through the `deref`; no
    diagnostics. If the prelude compile (commit 2) fails on the same shapes,
    this golden's fill from commit 1 attributes the failure to the shape, not to
    the prelude body. Subfiles `fail_mismatched_pointee` (`fn Bad[T: type, U:
    type](p: T*, n: i64) -> U* = "pointer.offset";`) and `fail_non_pointer` (`fn
    Bad(p: i64, n: i64) -> i64 = "pointer.offset";`): predicted
    `InvalidBuiltinSignature` "invalid signature for builtin function
    \"pointer.offset\"" (handle_function.cpp:862-865) at each `fn`.
-   **check/testdata/builtins/failstop.carbon** (`min_prelude/full
    .carbon` — `str` needs `Core.String`; named after the builtin without
    the `fail_` prefix — as `fail_stop.carbon` it would pass only by the
    accident of its `fail_returns_value` split setting
    `require_overall_failure`, file_test_base.cpp:244-247; amended
    2026-09-28, review fold: rev B B3): `fn Stop(message: str) =
    "fail_stop";` and `fn F() { Stop("x"); }` — predicted a call with a
    `str` literal operand converted through the `String` struct value;
    subfile `fail_returns_value` (`fn Bad(message: str) -> i32 =
    "fail_stop";`): `InvalidBuiltinSignature` "...\"fail_stop\"".
-   **check/testdata/builtins/heap/allocate_free.carbon** (`min_prelude/
    full.carbon` for `Core.MaybeUnformed`): `fn Alloc(generic T: type, n:
    i64) -> Core.MaybeUnformed(T*) = "heap.allocate";`, `fn Free[T:
    type](p: T*) = "heap.free";`, `fn F(n: i64) -> Core.MaybeUnformed(i32*)
    { return Alloc(i32, n); }`, `fn G(p: i32*) { Free(p); }`; subfiles
    `fail_allocate_plain_pointer` (`-> T*`) and `fail_free_returns` (`->
    i32`): `InvalidBuiltinSignature` for `"heap.allocate"` /
    `"heap.free"`.
-   **check/testdata/slice/basic.carbon** (`min_prelude/full.carbon`),
    positives only, one dump range per function:
    -   `from_array_index`: `fn F() -> i32 { var a: array(i32, 4) = (1,
        2, 3, 4); let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
        return s[1]; }`. Predicted: a `FromArray` call whose specific
        carries `N = 4` deduced from `array(i32, 4)*` (a
        `specific_function` line naming `@FromArray` with the `int_4`
        constant), the literal subscript converted to `i64` by the
        literal-subscript rule (handle_index.cpp; amended 2026-10-05,
        round 3) so the `Slice(i32) as IndexWith(i64)` witness is
        selected, and an `At` call producing a value of type `%i32` (not
        a reference). No diagnostics.
    -   `index_runtime_subscript`: `fn G(s: Core.Slice(i32), i: i64) ->
        i32 { return s[i]; }` — predicted a direct `IndexWith(i64)`
        dispatch with no subscript conversion (amended 2026-10-05: rev
        2's `i: i32` / `U = i32` is now the `fail_subscript_i32` pin in
        fail_basic.carbon — `MissingImplInMemberAccess` "cannot access
        member of interface `Core.IndexWith(i32)` in type
        `Core.Slice(i32)` that does not implement that interface").
    -   `subslice_and_size`: `fn H(s: Core.Slice(i32)) -> i64 { return
        s.Subslice(1, 3).Size(); }` — predicted two method calls, no
        diagnostics.
    -   `const_view`: `fn K(s: Core.Slice(i32)) -> Core.Slice(const i32)
        { return s; }` — predicted the OUT-of-class `impl forall [T]
        Slice(T) as ImplicitAs(Slice(const T))` witness
        (`@Slice.as.ImplicitAs.impl`, the placement §1.A.2 chose) call
        (amended 2026-09-28, review fold: rev A A7).
    -   `iterate`: `fn Sum(s: Core.Slice(i32)) -> i32 { var t: i32 = 0;
        for (x: i32 in s) { t += x; } return t; }` — predicted the
        `Iterate` witness `@Slice.as.Iterate.impl(%i32)` with `NewCursor`
        and `Next` calls (the array iterate golden's shape,
        check/testdata/for/*).
    -   `unformed`: `fn U() { var s: Core.Slice(i32); }` — predicted the
        `DefaultOrUnformed` blanket impl over `UnformedInit` (the
        string.carbon:28 shape), no `ConversionFailureTypeToFacet`.
    -   `generic_element`: `fn First[T: Core.Copy & Core.Destroy](s:
        Core.Slice(T)) -> T { return s[0]; }` — predicted a symbolic
        `IndexWith` lookup deferred to the specific; no diagnostics.
-   **check/testdata/slice/fail_basic.carbon** (`full.carbon`):
    -   `fail_write_through`: `fn W(s: Core.Slice(i32)) { s[0] = 5; }`
        — predicted `AssignmentToNonAssignable` "expression is not
        assignable" at `s[0]` (D-SL-3's pin).
    -   `fail_array_value_no_conversion`: `fn V(a: array(i32, 4)) { let
        s: Core.Slice(i32) = a; }` — predicted `ConversionFailure`
        "cannot implicitly convert expression of type `array(i32, 4)` to
        `Core.Slice(i32)`" (diagnostics/kind.def:607; D-SL-2's pin).
    -   `fail_non_copy_element`: `class NoCopy {} fn N(s:
        Core.Slice(NoCopy));` — predicted `ConversionFailureTypeToFacet`
        "cannot convert type `NoCopy` into type implementing `Core.Copy &
        Core.Destroy`" (convert.cpp:1336; the class-parameter bound).
-   **check/testdata/slice/buf.carbon** (`full.carbon`), positives:
    `make_get_set` (`fn F(n: i64) -> i32 { var b: Core.Buf(i32) =
    Core.Buf(i32).Make(n, 7); b.Set(0, 9); return b[0] + b.Get(1); }`
    — predicted `Make`/`Set`/`IndexWith.At`/`Get` calls and, at the end
    of `F`, the `Destroy` witness call on `%b.var` from the user impl
    `@Buf.as.Destroy.impl(%i32)` — a `destroy` dump line, the arbiter of
    the first user `impl as Destroy` inside a GENERIC class in the tree
    (R-12; amended 2026-09-28, review fold: rev A A9); `as_slice`
    (`fn S(b: Core.Buf(i32)) -> Core.Slice(i32) { return b.AsSlice(); }`).
    The `unformed` positive of rev 1 is gone: `Buf` is not `UnformedInit`
    (D-SL-6; amended 2026-09-28, review fold: rev B B1).
    **check/testdata/slice/fail_buf.carbon:** `fail_copy` (`fn C(b:
    Core.Buf(i32)) { var c: Core.Buf(i32) = b; }`) — predicted
    `CopyOfUncopyableType` "cannot copy value of type `Core.Buf(i32)`"
    at the `= b` (convert.cpp:1794-1803 `PerformCopy`, reached from the
    initializer target at :2027-2033; diagnostics/kind.def:512) with the
    `MissingImplInMemberAccessInContext` note "type `Core.Buf(i32)` does
    not implement interface `Core.Copy`" — the exact shape of
    check/testdata/class/adapter/adapt_copy.carbon:27-35 for a class
    with no `Copy` impl; no `PrimitiveCopy`/memcpy appears (amended
    2026-09-28, review fold: rev A A6 / rev B B8 — pre-registered, not
    "named at implementation time"); `fail_unformed` (`fn U() { var b:
    Core.Buf(i32); }`) — predicted `ConversionFailureTypeToFacet`
    "cannot convert type `Core.Buf(i32)` into type implementing
    `Core.DefaultOrUnformed`" at the `var` (the
    check/testdata/choice/fail_generic_payload.carbon:37 shape), the pin
    of D-SL-6's refusal (amended 2026-09-28, review fold: rev B B1).
-   **lower/testdata/builtins/pointer_offset.carbon** (`min_prelude/int
    .carbon`; user-declared builtin as in lower/testdata/builtins/pointer
    .carbon:13-15): `fn F(p: i32*, n: i64) -> i32* { return Offset(p, n);
    }` — predicted IR: `%ptr.offset = getelementptr inbounds i32, ptr %p,
    i64 %n` and `ret ptr %ptr.offset`.
-   **lower/testdata/builtins/failstop.carbon** (`full.carbon`; a
    POSITIVE lower golden, so it cannot carry the `fail_` prefix —
    `CompareFailPrefix` would fail it after a green fill, file_test_base
    .cpp:126-135; amended 2026-09-28, review fold: rev B B3): `fn F() {
    Stop("boom\n"); }` — predicted: the literal lowers as TWO globals,
    `@0 = private unnamed_addr constant [6 x i8] c"boom\0A\00"` and
    `@String.val.String.val = internal constant { ptr, i64 } { ptr @0, i64
    5 }` (lower/testdata/operators/string_indexing.carbon:27-28); in `@F`
    a `load { ptr, i64 }` of that global, two `extractvalue`s
    (`%fail_stop.ptr`, `%fail_stop.size` — SSA operands, not literals:
    lower goldens are unoptimized, string_indexing.carbon:39-40), `call
    i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size)`, `call
    void @abort()`, then the ordinary `ret void` (D-SL-4: no
    `unreachable`); declarations `declare i64 @write(i32, ptr, i64)` and
    `declare void @abort()` with the `noreturn` attribute in an
    `attributes #N` group. The arm may `CreateSExtOrTrunc` the size
    only — no constant folding is chased, so a literal `i64 5` operand in
    the fill is NOT expected and its absence is not an R-1 refutation
    (amended 2026-09-28, review fold: rev B B5). This golden is the R-1
    falsifier (an IR verifier failure means the block shape is wrong).
-   **lower/testdata/builtins/heap.carbon** (`full.carbon`): `fn A(n:
    i64) -> Core.MaybeUnformed(i32*) { return Alloc(i32, n); }` and `fn
    Fr(p: i32*) { Free(p); }` — predicted `%heap.bytes = mul i64 %n, 4`,
    the zero-guard `select`, `call ptr @malloc(i64 ...)`, `call void
    @free(ptr %p)`; `declare ptr @malloc(i64)`, `declare void @free(ptr)`.
-   **lower/testdata/slice/basic.carbon** (`full.carbon`; twin of
    check `from_array_index` + `index_runtime_subscript`): predicted in
    the `Get` specific `@"_CGet.<hash>:Slice.Core"`: `icmp slt i64 %i, 0`,
    `icmp sge i64 %i, %size`, an `or i1`, `br i1`, the `write`+`abort`
    calls in the fail block, and `getelementptr inbounds i32` + `load
    i32` on the success path; in `@F` the `FromArray` specific stores
    `ptr %a.var` and `i64 4` into the slice's `{ptr, i64}` storage. This
    is the D-SL-4 arbiter at the IR level.
-   **lower/testdata/slice/buf.carbon** (twin of check `make_get_set`
    with a runtime `n`): predicted `call ptr @malloc`, `icmp eq ptr ...,
    null` (PointerIsNull), the fill loop (`store i32 %fill`), and a
    `call void @free(ptr %...)` inside the destroy specific called at
    `F`'s exit.

The "subfile blanks the lower golden" rule: none of the lower files has
a `fail_` subfile. The two-pass autoupdate rule (R26): the check
`fail_basic.carbon`/`fail_buf.carbon` fills insert STDERR lines above
dumped code — expect a second pass that only renumbers `loc` markers.

### §4.B SL-2

-   **check/testdata/interop/cpp/stdlib/span.carbon** (`min_prelude/
    full.carbon`; header `span.h` mocks `namespace std { using size_t =
    __SIZE_TYPE__; inline namespace __1 { inline constexpr size_t
    dynamic_extent = static_cast<size_t>(-1); template <typename T,
    size_t Extent = dynamic_extent> class span { public: span() =
    default; size_t size() const { return size_; } private: T* data_;
    size_t size_; }; } }` plus `auto Consume(std::span<const int> s) ->
    void;`, `auto Produce() -> std::span<int>;`, `auto ConsumeStatic(std::
    span<int, 3> s) -> void;`):
    -   `pass_and_return`: `fn F(s: Core.Slice(i32)) { Cpp.Consume(s); }`
        and `fn G() -> Core.Slice(i32) { return Cpp.Produce(); }` —
        predicted: `Cpp.Consume`'s imported parameter type prints as the
        `Core.Slice(const i32)` specific (`%Slice.<n>: type = class_type
        @Slice, @Slice(%const)` shape), the argument converts through the
        OUT-of-class `impl forall [T] Slice(T) as ImplicitAs(Slice(const
        T))` witness (`@Slice.as.ImplicitAs.impl`, §1.A.2; amended
        2026-09-28, review fold: rev A A7), the call names the thunk as
        the check dump spells it — `%Consume__carbon_thunk.type: type =
        fn_type @Consume__carbon_thunk` (string_view.carbon:94-95; the
        `.carbon_thunk._` spelling of rev 1 is the LOWERED name, not the
        SemIR one — amended 2026-09-28, review fold: rev B B6); `G`
        returns the `Core.Slice(i32)` specific with the out-pointer thunk
        form (`Produce__carbon_thunk`, :103-104). No diagnostics, no imported
        `span` CLASS anywhere in the dump.
    -   `static_extent_is_a_class`: `fn H(p: Cpp.std.span(i32, 3)*) {}`
        — predicted an imported CLASS (a `class_type @span` with a
        `complete_type_witness` over the imported `{T*}`-only custom
        layout) and NOT a `Slice` specific anywhere in the dump.
    -   **fail_static_extent_from_slice** (own file
        fail_span.carbon): `Cpp.ConsumeStatic(Core.Slice(i32).UnsafeMake
        (p, 3))` — predicted Clang's forwarded "no matching function for
        call to 'ConsumeStatic'" diagnostics (the candidate note names
        `std::span<int, 3>`), that is static extents are honestly unmapped.
-   **check/testdata/interop/cpp/function/export/slice.carbon** (`full
    .carbon`): `fn Sum(s: Core.Slice(const i32)) -> i32 { ... }` plus
    `inline Cpp '''` with the same mock `std::span` (extended with the
    constructor `span(T* p, size_t n) : data_(p), size_(n) {}`) and
    `int F() { int a[2] = {1, 2}; return Carbon::Sum(std::span<const
    int>(a, 2)); }`. Predicted: no diagnostics; the exported
    declaration's parameter type is `std::span<const int>` (visible in
    the SemIR as the export-side `Cpp` function decl the reverse-interop
    path records). **fail_no_span_header** (own file
    fail_export_slice.carbon): the same Carbon `Sum` referenced from
    inline C++ without any `std::span` declaration — predicted
    `SemanticsTodo` "semantics TODO: `failed to map Carbon type to C++`"
    (export.cpp:894/:950 — the PARAMETER sites; the return-type site :960
    prints "failed to map Carbon return type to C++" and `Sum`'s `i32`
    return never reaches it; amended 2026-09-28, review fold: rev B B11)
    at the reference — loud, no new kind.
-   **check/testdata/interop/cpp/impls/cpp_contiguous_range.carbon**
    (the cpp_range_for_iterate.carbon:16-37 shape): a `package Core
    library "cpp_contiguous_range"` test prelude declaring
    `CppContiguousRange` with the §1.B.3 members, an `IsContiguous`
    predicate interface with the `final impl forall [T:
    CppContiguousRange] T as IsContiguous where .Result = true` / blanket
    `false` pair, and `AssertIsContiguous`/`AssertIsNotContiguous`;
    subfiles: `member_data_size` (`class V { public: const int* data()
    const; int* data(); unsigned long size() const; };` →
    `Core.AssertIsContiguous(Cpp.V)` compiles — the const filter picks
    `data() const`), `missing_size` (`class N { public: int* data(); };`
    → `Core.AssertIsNotContiguous(Cpp.N)` compiles), `non_const_only`
    (`class M { public: int* data(); unsigned long size(); };` →
    `AssertIsContiguous(Cpp.M)` compiles: single non-const overloads are
    taken as-is).
-   **check/testdata/interop/cpp/stdlib/vector_view.carbon** (`full .carbon`;
    mock `class VectorLike { public: const int* data() const; int* data();
    std::size_t size() const; };` with `using size_t = __SIZE_TYPE__` in `std`):
    `fn View(v: Cpp.VectorLike) -> Core.Slice(const i32) { return v; }` —
    predicted the blanket `ImplicitAs` witness over the synthesized
    `CppContiguousRange` witness (a `custom_witness` constant naming `data`/`size`
    function decls) and the two-step `ImplicitAs(u64)` (the as.carbon:37
    identity on `u64`) then `As(i64)` conversion of the size (D-SL-9; amended
    2026-09-28, review fold: rev A A2); no diagnostics. **fail_no_size** (own
    file): `class NoSize { public: int* data(); };` → `ConversionFailure`
    "cannot implicitly convert expression of type `Cpp.NoSize` to
    `Core.Slice(i32)`".
-   **lower/testdata/interop/cpp/span.carbon** (`full.carbon`, the mock header):
    twin of `pass_and_return` — predicted: a thunk definition named
    `@<Itanium-mangled Consume>.carbon_thunk._` — the import-side thunk IS named
    after the callee's mangling plus that suffix
    (lower/testdata/interop/cpp/thunks.carbon:117/:122
    `@_ZN9NeedThunkC1ERKS_.carbon_thunk._`, template.carbon:116
    `@_Z8identityIiET_S0_.carbon_thunk._`), so the name contains `4span` and the
    all-ones extent `18446744073709551615` from the mangled `std::span<const
    int, 18446744073709551615>` parameter (rev B B6's IR-name half declined on
    that evidence: `_CF__carbon_thunk.Main`, array.carbon:59/:90, is the
    EXPORT-direction thunk of a Carbon `F`, not this shape); the thunk takes
    `ptr` (the `Slice` storage address) and calls the real `Consume` with a
    by-value `span` load; for `Produce`, the out-pointer thunk writing 16 bytes
    into the Carbon return slot. No `memcpy` between differently sized types
    (the layout premise's IR-level check).

## §5 Conformance

Every program: `import Core library "io";`, values threaded through a
`RuntimeSeed` so nothing constant-folds (the F8/OV template), EXPECT
values hand-derived here (R16(d)), bullet strings verbatim from
gap-analysis.md:76 and :79 (R7), `runner.py --self-test` before commit.

### §5.A SL-1 — one SKIP→PASS, two new; delta PASS +3 / SKIP −1 / total +2

1.  **stdlib/slices_basic.carbon — body REPLACED (SKIP → PASS).** Header
    keeps `// CONFORMANCE-BULLET: Stdlib: Slices`, `EXPECT-EXIT: 0`; the
    SKIP line and the strawman are deleted; the un-SKIP commit discloses
    (R6/F8d) that the strawman's `Core.Slice(i32).Make(&a, 1, 3)` became
    `FromArray(&a).Subslice(1, 3)` (D-SL-2) and that two lines were added
    to prove aliasing and iteration:

    ```carbon
    import Core library "io";

    fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

    fn Run() -> i32 {
      var a: array(i32, 4) = (1, 2, 3, 4);
      // A view of a[1..3): {2, 3}.
      let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a).Subslice(1, 3);
      Core.Print(s.Size() as i32);
      Core.Print(s[1]);
      // Writes to the array are visible through the view: no copy.
      a[2] = RuntimeSeed(10);
      Core.Print(s[1]);
      var total: i32 = 0;
      for (x: i32 in s) {
        total += x;
      }
      Core.Print(total);
      return 0;
    }
    ```

    EXPECT-STDOUT: `2` (elements 1 and 2 of four), `3` (`s[1]` is
    `a[2]`), `30` (after `a[2] = 30`, read through the view), `32` (2 +
    30). Four lines (the stub's first two are unchanged). `s.Size() as
    i32` is int.carbon:70-77's `Int(From) as As(Int(To))`.
2.  **stdlib/slices_heap_buf.carbon (new, bullet "Stdlib: Slices").** Heap
    storage viewed and mutated through the slice API:

    ```carbon
    import Core library "io";

    fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

    fn Fill(b: Core.Buf(i32), v: i32) {
      var i: i64 = 0;
      while (i < b.Size()) {
        b.Set(i, v + (i as i32));
        ++i;
      }
    }

    fn Run() -> i32 {
      var b: Core.Buf(i32) = Core.Buf(i32).Make(RuntimeSeed(-17) as i64, 7);
      let s: Core.Slice(i32) = b.AsSlice();
      Core.Print(s.Size() as i32);
      Core.Print(s[1]);
      Fill(b, RuntimeSeed(-10));
      Core.Print(s[2]);
      var total: i32 = 0;
      for (x: i32 in s) {
        total += x;
      }
      Core.Print(total);
      return 0;
    }
    ```

    EXPECT-STDOUT: `3` (size), `7` (the fill value), `12` (10 + 2 after `Fill`
    writes 10, 11, 12), `33` (10 + 11 + 12). Four lines. `b` is passed by value
    to `Fill` without a copy (value bindings of a non-`Copy` class are
    references — README.md:1301-1303 — and, at the toolchain level, a by-value
    PARAMETER binding is not an initializer target, so `Convert` takes the
    `Done{expr_id}` path with no `PerformCopy`: convert.cpp:2027-2038 copies
    only for initializer and `CppThunkRef` targets — amended 2026-09-28, review
    fold: rev A A6 / rev B B8; `Set` writes through the shared heap block, and
    the program's third line is the proof). `Destroy` frees at `Run`'s exit; a
    leak is not observable, a double free would abort — exit 0 is the check. `i
    as i32` is `Int(64) as As(Int(32))` (int.carbon:70).
3.  **stdlib/slices_bounds_fail_stop.carbon (new, bullet "Stdlib:
    Slices").** `EXPECT-EXIT: -6` (D-SL-12), no `EXPECT-STDOUT`:

    ```carbon
    import Core library "io";

    fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

    fn Run() -> i32 {
      var a: array(i32, 2) = (1, 2);
      let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
      // Index 2 on a two-element view: fails-stop before any output.
      let bad: i32 = s[RuntimeSeed(-18)];
      Core.Print(bad);
      return 0;
    }
    ```

    Derivation: `RuntimeSeed(-18)` is 2, `s.size` is 2, `2 >= 2` takes
    the fail branch: one stderr line then `abort()` → SIGABRT → the
    runner's `returncode` is −6 → matches. The header's comment cites
    safety/README.md:218-232 as the behavior's authority and
    runner.py:454-463/:587 for the code.

Zero landed programs move: no program uses `Slice`, `Buf`, `FromArray`
or the builtin names as identifiers (`grep -rn 'Slice\|Buf\b'
fork/conformance/programs` hits only the two stubs), and SL-1 changes no
diagnostic a landed program triggers. Bullet "Stdlib: Slices": 3/3 PASS
→ the bullet counts as PASS in `bullets`.

### §5.B SL-2 — one SKIP→PASS, one new differential; delta PASS +2 / SKIP −1 / total +1

1.  **interop/cpp_span_view.carbon — body REPLACED (SKIP → PASS).**
    Header keeps the bullet line verbatim, `EXPECT-EXIT: 0`, EXPECT lines
    `10`, `6` unchanged, adds `// COMPILE-ARGS: --clang-arg=-std=c++20`
    (D-SL-14); the un-SKIP commit discloses the two strawman rewrites of
    §0.2 item 7:

    ```carbon
    import Core library "io";
    import Cpp inline '''c++
    #include <numeric>
    #include <span>
    #include <vector>

    inline int SumSpan(std::span<const int> s) {
      return std::accumulate(s.begin(), s.end(), 0);
    }

    inline std::vector<int> MakeVector() { return {2, 4, 6}; }
    ''';

    fn Run() -> i32 {
      var a: array(i32, 4) = (1, 2, 3, 4);
      // The view is formed explicitly (`&a`) and crosses as std::span.
      Core.Print(Cpp.SumSpan(Core.Slice(i32).FromArray(&a)));
      // Owning -> view: the vector converts to a slice of its elements.
      var v: Cpp.std.vector(i32) = Cpp.MakeVector();
      let view: Core.Slice(const i32) = v;
      Core.Print(view[2]);
      return 0;
    }
    ```

    EXPECT-STDOUT: `10` (1+2+3+4 through `std::accumulate`), `6`
    (`view[2]` of {2, 4, 6}; `const i32` → `i32` for `Core.Print` by
    as.carbon:46-48). `view[2]` is `IndexWith(Core.IntLiteral)` on
    `Slice(const i32)`. If the D-SL-9 chain is refuted, this program
    stays SKIP with the refreshed reason and the delta is +1 PASS / 0
    SKIP / +1 total (PARTIAL outcome).
2.  **interop/cpp_span_roundtrip_diff.carbon (new) + .diff.cpp.**
    `COMPILE-ARGS: --clang-arg=-std=c++20`. Both directions with a C++
    oracle:

    ```carbon
    import Core library "io";
    import Cpp inline '''c++
    #include <span>

    inline std::span<const int> Tail(std::span<const int> s) {
      return s.subspan(1);
    }
    ''';

    // Forward declaration: the `inline Cpp` block below references
    // `Carbon::Sum`, and imports must precede every declaration.
    fn Sum(s: Core.Slice(const i32)) -> i32;

    inline Cpp '''
    inline int CallSum() {
      int arr[3] = {5, 6, 7};
      return Carbon::Sum(std::span<const int>(arr));
    }
    ''';

    fn Sum(s: Core.Slice(const i32)) -> i32 {
      var total: i32 = 0;
      var i: i64 = 0;
      while (i < s.Size()) {
        total += s[i];
        ++i;
      }
      return total;
    }

    fn RuntimeSeed(x: i32) -> i32 { return x + 20; }

    fn Run() -> i32 {
      var a: array(i32, 3) = (RuntimeSeed(-19), 2, 3);
      let t: Core.Slice(const i32) = Cpp.Tail(Core.Slice(i32).FromArray(&a));
      Core.Print(t.Size() as i32);
      Core.Print(t[0]);
      Core.Print(Cpp.CallSum());
      return 0;
    }
    ```

    EXPECT-STDOUT: `2` (tail of three), `2` (`a[1]`), `18` (5+6+7 summed
    by the EXPORTED Carbon `Sum` over a C++-made span). The `.diff.cpp`
    oracle computes the same three values in plain C++17 (`subspan` and
    `std::span` replaced by pointer+size arithmetic — the oracle must
    compile with the runner's `-std=c++17`, runner.py:632) and prints
    them; DIFF-MISMATCH is the falsifier for any value drift. Export of
    `Sum` needs `<span>` in the TU: it is included by the `import Cpp
    inline` block, and the `inline Cpp` block joins the same TU. Shape
    (amended 2026-09-28, review fold: rev A A1): rev 1 referenced
    `Carbon::Sum` from the `import Cpp inline` block that PRECEDES the Carbon
    `fn Sum` — a COMPILE-FAIL on the very run meant to flip row 79, because
    imports must precede declarations (so `Sum` cannot be hoisted above the
    import) and an `import Cpp inline` block sees only already-imported
    packages (check/testdata/interop/cpp/function/export/function.carbon
    :23-31 reaches `Carbon::Other::F1()` only because `Other` is imported
    first). The program now uses the fork's single-file export precedent: a
    forward declaration, then the post-declaration `inline Cpp '''` block
    (fork/conformance/programs/interop/cpp_atomic_global_counter_diff
    .carbon:14-31 `fn Bump();` + `inline Cpp
    '''...Carbon::Bump()...'''`; function.carbon:60-67 `fn F(ref n: i32);` +
    `inline Cpp` is the golden twin), matching the §4.B
    function/export/slice.carbon golden, which already uses `inline Cpp`.

Zero landed programs move (no landed program includes `<span>` or names
`Slice`). Bullet row 79: 2/2 PASS → DONE, or 1/2 with one SKIP → PARTIAL
(D-SL-9 fallback; the fold record states which).

## §6 Churn inventory (verified by grep at 8e32108f8)

### §6.A SL-1

-   **Existing goldens that move: none predicted.** (a) Check dumps exclude the
    prelude (`//@dump-sem-ir` ranges) and SemIR names are symbolic, so two NEW
    prelude files and two `export import` lines change no existing check golden
    — the try.carbon precedent (commit 6b0b80e, fork/eh/plan.md:1138-1142). (b)
    The EH-A lesson (:1199-1215): a prelude edit that shifts lines ABOVE a
    method that lowered code references moves every lower golden's `DILocation`s
    for that method. SL-1's only edits to EXISTING prelude files are
    types.carbon (no functions) and an APPEND to iterate.carbon after its last
    line (:82), so no existing method moves; `grep -rn 'Iterate.Core\| IntRange'
    toolchain/lower/testdata` lists the goldens that would have moved
    (array/iterate, for/*, interop/cpp/range_for-adjacent) and they are
    predicted byte-identical. (c) Raw goldens: ZERO move, decided from the tree,
    not by the fill (amended 2026-09-28, review fold: rev B B10). No raw golden
    includes the full prelude: `grep -n INCLUDE-FILE
    toolchain/check/testdata/basics/raw_sem_ir/*` gives
    `min_prelude/none.carbon` (five files), `form.carbon` (bundle) and
    `convert.carbon` (one_file, whose `import_irs` table at :32-36 lists only
    that minimal prelude's IRs); non_core_interfaces.carbon and
    driver/testdata/stdin.carbon run `--no-prelude-import`. Two new
    `prelude/types/*` libraries cannot appear in any `import_ir` table, so a raw
    diff at fill is a STOP (§8.1), never a reconciliation.
-   **Amended 2026-10-05 (round-2 fix after the implementation review;
    R28(d): a review miss recorded in place) — SIX existing goldens
    move, and this bullet's "none predicted" was wrong.** The review's
    BLOCKER: `Buf(T)`'s `impl as Destroy` was dead code — impl lookup
    consults the custom witness first (impl_lookup.cpp
    `EvalLookupSingleFinalWitness`, "Only consider candidates when a
    custom witness didn't apply") and `CanDestroyClass` never looked for
    a declared impl, so the synthesized `ret void` placeholder won and
    every `Buf` leaked while this plan, the docs and the goldens claimed
    `free`. Decidable from the tree, like rev B B1 (decision-log W-021
    note: "a user `Core.Destroy` impl is inert today"). Fix (a) of the
    review, at the root: `CanDestroyClass` answers `NoDestroy` for a
    class covered by a class-keyed declared `Destroy` impl
    (`HasClassKeyedImpl`, the generalized former
    `HasUserCopyImplOutsideCore`: local store plus every imported IR's
    store, matched read-only by class / canonical defining declaration,
    blanket symbolic-self impls ignored, `partial` selves excepted), so
    `LookupDestroyWitness` returns `nullopt` and lookup selects the
    declared impl. This makes EVERY in-tree user `Destroy` impl real, so
    the goldens that hold one move (cleared to CHECK-free for the fill):
    lower/testdata/var/param.carbon (the destroy of `%c.var` now calls
    `@"_COp.C.Main:Destroy.Core"`; the `weak_odr` placeholder definition
    and its DI entries vanish), lower/testdata/var/destroy_control_flow
    .carbon (every `Destructible` destroy calls the user `fn Op(self)`
    through its thunk; the `_COp.474c…` placeholder vanishes),
    lower/testdata/function/overload/basic.carbon `destroy_arg` (the
    temporary's destroy calls `@"_COp.D.Main:Destroy.Core"`),
    lower/testdata/operators/question_generic.carbon `adapter_payload`
    (`MyResult(Tag, i32)`'s field walk now finds `Tag`'s declared
    witness, so the synthesized `_COp…` definition for `Tag` is no longer
    built or emitted; the `MyResult`/`ControlFlow` placeholder calls on
    the propagation path are unchanged — its comments are rewritten),
    and the check twins check/testdata/var/destroy_control_flow.carbon
    and check/testdata/function/overload/basic.carbon (`destroy_arg`:
    the dumped `Destroy.Op.bound`/`call` reference the user impl's `Op`
    instead of `@Destroy.Op.loc…` with the `"no_op"`/placeholder
    definition). Predicted UNCHANGED although they hold a user impl:
    check/testdata/interop/cpp/class/export/fail_atomic_of_nontrivial
    _carbon_class.carbon and check/testdata/union/fail_nontrivial_field
    .carbon (no dump ranges; diagnostics come from the export/union
    predicates, which keep `HasUserDestroyImpl`), check/testdata/impl/
    lookup/fail_poison_custom_witness.carbon (its impl is a blanket
    `forall [T: type] T as Destroy`, not class-keyed), impl/custom_witness/
    destroy.carbon and impl/lookup/impl_overlap_wrapped_types.carbon (no
    user impl; `as Core.Destroy` appears only in expressions/dumps).
    Prelude-wide: `Buf` is the only prelude class with a declared
    `Destroy` impl (`grep -rn 'as Destroy' core/`), so no other prelude
    type changes behavior. MINOR 2 of the same review (the
    `heap.allocate` byte count wraps) is fixed in the lowering arm with
    `llvm.umul.with.overflow.i64`, the wrap bit selecting a null result
    (the prelude's existing fail-stop path); lower/testdata/builtins/
    heap.carbon and slice/buf.carbon are CHECK-free, so no further golden
    moves.
-   **Amended 2026-10-05 (round 4, after hosted autoupdate run 37335213696 moved
    40 files where 18 were predicted; R28(d): review misses recorded in place) —
    four root causes.** **(a) REGRESSION, every union and C++-export golden (13
    files).** `HasUserDestroyImpl` — the scan behind `IsTriviallyDestructible`,
    which is both the union field rule and the export triviality predicate —
    treated EVERY symbolic impl self as a blanket covering every class. The
    prelude's new in-class `impl as Destroy` of `class Buf(T)` has the symbolic
    self `Buf(T)` and sits in every file's import set, so every class left the
    trivially-destructible set — `i32` included, since it is the class
    `Core.Int(32)`: `UnionFieldNotTriviallyCopyable` on `i32`/`array(i8, 4)`
    fields (check/union/{basic,fail_init,fail_modifiers_and_redecl,
    fail_nontrivial_field,import,layout}; lower/union/{basic,layout} lost whole
    modules), and the exported `A`/`OneArg`/union records grew
    `__destroy_thunk`s (lower interop/cpp/issue7142, function/export/
    constructor, class/export/union; check class/export/union, union_by_value),
    and a 14th file, check/function/overload/basic.carbon (its `union_scope_set`
    split gained the same two field errors; it is cleared for the fill rather
    than restored, since its `destroy_arg` content is the legitimate round-2
    move). The round-2 bullet's "`grep -rn 'as Destroy' core/`, so no other
    prelude type changes behavior" looked at the wrong predicate:
    `CanDestroyClass`'s yield IS class-keyed, but the impl it added was the one
    `HasUserDestroyImpl`'s shortcut matches for every class. Fix at the root
    (custom_witness.cpp `HasUserDestroyImpl`): a class-typed impl self, concrete
    or a symbolic specific, is keyed on its class (local `class_id`; imported
    canonical defining declaration); only a non-class symbolic self (`impl
    forall [T: type] T as Destroy`,
    impl/lookup/fail_poison_custom_witness.carbon) is a blanket. The 13 goldens
    are restored from the pre-SL-1 tree (ee434b2b3~3) and predicted
    byte-identical: `git diff ee434b2b3~3 -- toolchain/check/testdata/union`
    must be empty after the next fill. **(b) UNPREDICTED, disclosed and kept:
    the `Iterate` import footprint.** lower/for/{for,bindings,break_continue}
    and lower/array/ iterate gained an uncalled `declare void
    @"_COp.41b89bfca5f3c7d4:core .Destroy.Core"(ptr)` (iterate.carbon's second
    split: `5f42013854821c52`), and check/interop/cpp/range_for renumbered
    `custom_witness.df9cc1.3` → `.4` and split its `i.patt` constant (`.ea1`).
    This is not a destroy-selection change — no class in those files has a
    declared impl, and `CanDestroyClass`'s yield selects nothing new.
    `ImportImplFilter::IsRelevantImpl` (impl_lookup.cpp) filters imported impls
    by INTERFACE only, so every file that looks `Iterate` up materializes every
    prelude `Iterate` impl; the appended `Slice(T) as Iterate where .CursorType =
    i64` carries the `i64 as Destroy` facet value of its rewrite, whose `Op` is
    iterate.carbon's own synthesized witness — exactly the footprint the array
    impl's `.CursorType = i32` already leaves as the pre-existing uncalled
    `declare @"_COp.6f4dee545ed23f91:core.Destroy.Core"` in the SAME four
    goldens and no others. Unavoidable while the impl lives in iterate.carbon
    (slice.carbon cannot import `prelude/iterate`: cycle, hand-off notes); the
    four lower goldens and range_for are kept as filled. **(c) DEFECT in a
    positive golden.** check/slice/basic.carbon `generic_element` pinned `cannot
    implicitly convert ... Core.Slice(T).(Core.IndexWith(i64).ElementType) to
    T`: a symbolic query resolves only FINAL impls
    (`EvalLookupSingleFinalWitness`), so a non-final impl's `where .ElementType =
    T` rewrite is unknown in a generic body. Root fix: `final impl forall` on
    `Slice(T)`/`Buf(T) as IndexWith(i64)` and on `Slice(T) as Iterate`
    (precedent `final impl forall [T: Destroy & OptionalStorage] Optional(T) as
    Try`, optional.carbon:69). Checked against impl_validation.cpp:
    `FinalImplInvalidFile` holds (slice.carbon/buf.carbon hold the root self
    type, iterate.carbon the interface); no non-final impl's query matches them
    (`ImplFinalOverlapsNonFinal`: `String`'s blanket is keyed on `String`, the
    `CppRange` blanket's self is a facet binding, `array(T, N)` is not a
    `Slice`); `ImportFinalImplsWithImplInFile` enumerates only the INTERFACE's
    own IR, so no golden with a local `IndexWith` impl imports the Slice/Buf
    impls, and every `for` golden already imported the `Iterate` impl at lookup
    (check/for/{basic, pattern} use min_prelude/for, which has no `Slice`). The
    split is re-predicted clean; the four slice goldens move and are cleared for
    the fill — check slice/basic, slice/buf (the imported impl entity prints as
    `final impl @…`), lower slice/basic, slice/buf (DI `line:` shifts from the
    prelude comment lines). **(d) The literal-subscript probe's footprint** —
    see the R-5 amendment (round 4): gated off erroneous operands (two goldens
    restored), the `Core.Int` import_ref residue disclosed (two goldens kept as
    filled).
-   **Builtin tables:** `CARBON_DEFINE_ENUM_CLASS_NAMES` and
    `ForBuiltinName` are generated; no golden prints the enum.
-   **min_prelude parts:** unchanged (no test combines a part with
    `Slice`).
-   **Diagnostics coverage test** (toolchain/diagnostics/coverage_test
    .cpp, `TEST(Coverage, Kind)` :82): SL-1 adds ONE diagnostic kind,
    `IncompleteTypeInBuiltinCall` (c200e6b81, kind.def), covered by the
    `fail_incomplete_pointee` splits of check/testdata/builtins/heap/
    allocate_free.carbon and builtins/pointer/offset.carbon once the fill
    writes their `[IncompleteTypeInBuiltinCall]` CHECK:STDERR lines (the
    pipeline runs autoupdate before the gate). *Amended 2026-10-05
    (round 4, re-review finding 3): this bullet said "NO diagnostic kind"
    after the kind had landed.* **Parse coverage test:** no parse change.
-   **Formatter/`InstNamer`:** no new inst kinds (builtins are `Call`
    insts); no new `SemIR::Inst` → the type_iterator.cpp / import_ref.cpp
    / `GetImportName` switches are untouched (recorded because the recent
    lessons name them; §7 R-3).

### §6.B SL-2

-   **Existing goldens that move: none predicted.** The `Str` mapping's
    behavior is unchanged (the enum→struct edit is mechanical); no
    existing golden names a `std::span` or a Core class named `Slice`
    (`grep -rln 'span\b' toolchain/check/testdata/interop` is empty);
    `RecognizedTypeInfo::ForType` returns `None` for every existing class
    exactly as before (`Slice` is a new `.Case`). The
    `CppContiguousRange` synthesis fires only for a query on that
    interface, which no existing code makes.
-   **DI-line churn in SL-1's lower goldens: none** (amended 2026-09-28, review
    fold: rev A A4). Rev 1 had SL-2 add `import library
    "prelude/types/optional";` to slice.carbon's header, which would have
    shifted every `Slice` method (`Get`, `Subslice`, `FromArray`, ...) down
    one source line and moved the `DILocation` lines of
    lower/testdata/slice/basic.carbon, slice/buf.carbon and any interop lower
    golden calling `Get` — exactly the EH-A miss (fork/eh/plan.md:1199-1215:
    one prelude import line moved eight lower goldens), and a §8.1 stop. The
    import is now in the SL-1 header (§1.A.2), so SL-2 only APPENDS (§2.B.9)
    and those goldens are predicted byte-identical.
-   **min_prelude parts:** none (parts/iterate.carbon does not carry the
    interop section; the vector_view golden uses `full.carbon`).
-   **Amended 2026-10-05 (SL-2 round 1).** The first hosted fill (run
    37356848697) moved 306 files — every full-prelude golden took the
    broken prelude's three errors (§2.B.9 amendment); all are restored
    byte-identical to 12a2143d2 at the fix, the SL-1 lower slice goldens
    included (the zero-churn layout keeps `class Slice` at :24 and every
    method's line). Predicted after the fix: the ten new goldens fill;
    nothing pre-existing moves, with one hedge — appending an `ImplicitAs`
    impl to slice.carbon widens the import footprint of every
    `ImplicitAs` query whose associated IRs include prelude/types/slice
    (`ImportImplFilter` imports by interface only), so
    check/testdata/slice/{basic,fail_basic,buf}.carbon and
    lower/testdata/slice/{basic,buf}.carbon may renumber constants (the
    SL-1 round-4(b) `range_for` class; the new impl matches none of their
    queries, so no witness table or `declare` is added). Any other mover,
    or a content change beyond renumbering, is a §8.1 stop.
-   **Interop README:** one dated paragraph; docs prek only.
-   **Diagnostics coverage:** no new kind (D-SL-8's failure path reuses
    `SemanticsTodo`).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — the `fail_stop` lowering produces invalid IR.** The arm
    emits `call @abort()` (noreturn) and NO terminator, relying on the
    checker's own branch/return after the `if` body. Falsifier: the
    hosted `compile` probe or `lower/testdata/builtins/failstop.carbon`
    failing the IR verifier ("Terminator found in the middle of a basic
    block" or "Basic Block ... does not have terminator"). Contingency:
    emit `unreachable` and start a fresh dead block
    (`BasicBlock::Create` + `SetInsertPoint`) so the checker's trailing
    branch lands in the dead block — the pattern lower already uses for
    `Return` in the middle of blocks; never remove the `noreturn`.
-   **R-2 — `abort()` under the conformance runner does not yield −6.**
    Falsifier: `slices_bounds_fail_stop` RUN-FAIL "exit code X, expected
    -6" with X = 134 (a shell wrapper) or −5/−4 (a trap, not SIGABRT).
    Contingency: the runner invokes the binary directly (no shell,
    runner.py:454-463), so 134 cannot occur; a different signal means
    `abort` was not reached — R-1's contingency.
-   **R-3 — the exhaustive-switch and runtime-fatal class.** New
    `BuiltinFunctionKind`s must appear in eval.cpp's runtime-only list
    (compile error if missed) and lower's `HandleBuiltinCall` (RUNTIME
    fatal `"Unsupported builtin call."` :664 if missed); SL-2's new
    `CoreInterface` must appear in `LookupCppImpl` (:561-651, compile
    error) and custom_witness.cpp:1487-1500 (compile error), and the new
    `RecognizedTypeInfo::Kind` in BOTH exhaustive switches —
    type_mapping.cpp's `TryMapClassType` (:196-330) and type_info.cpp's
    `PrintLiteral` (:238-295) (compile errors; amended 2026-09-28, review
    fold: rev B B4). No new `SemIR::Inst` kind, so check/import.cpp
    `GetImportName`, import_ref.cpp's resolver and
    sem_ir/type_iterator.cpp's runtime-fatal `default` are not in play —
    a reviewer who finds an inst kind in the diff has found a plan
    violation. Falsifier: the hosted `compile` probe (commit 1 of each
    PR) red on `-Wswitch`, or a lower golden's fill printing the fatal.
-   **R-4 — the symbolic-`T` prelude bodies fail definition checking (amended
    2026-09-28, review fold: rev A A5).** The two shapes, named: (a)
    `InitializeExisting` into a `Deref` of symbolic type `T` —
    `*PointerOffset(ptr, i) = fill` and `*PointerOffset(self.ptr, i) = value`
    in buf.carbon; (b) `ConvertToValueExpr` on a `Deref` of symbolic `T` → the
    `Copy` witness — `return *PointerOffset(self.ptr, i)` in `Slice.Get`.
    NOTHING in the tree exercises either on a checked generic: the cited
    optional.carbon:162/:170 precedents are `unsafe as` adapter casts on a
    `MaybeUnformed(T)` FIELD, not derefs of a `T*`; pointer/basic.carbon:19 is
    concrete, generic/template_dependence.carbon:18-20 is `template T`, and
    every `*p = ...` in lower/testdata (primitives/int_types.carbon:28-34,
    bool.carbon:23) is concrete. This is the plan's riskiest SL-1 assumption:
    if it fails, every SL-1 golden, all three conformance programs and the
    row-76 flip stall together. Rev B's reading of the mechanism (recorded):
    `return *PointerOffset(...)` from a `-> T` function goes through
    `ConvertToValueOfType` → `PerformCopy` on the `T: Copy` facet as
    optional.carbon:170 does, and `*p = fill` is an `Assign` whose LHS is a
    `Deref` DurableRef without `const` (handle_operator.cpp:104-116 passes it)
    — the same category as the cited precedents, no new risk found.
    Falsifiers, in order: (1) the isolating `Load`/`Store` lines of
    check/testdata/builtins/pointer/offset.carbon (commit 1, §4.A) diagnosing
    — attributes the failure to the shape in one round instead of an
    undifferentiated prelude compile error; (2) the prelude's own compile
    (hosted `compile` probe, commit 2) diagnosing inside
    slice.carbon/buf.carbon. Contingency: none at the shape level — a
    symbolic-`T` deref the definition checker rejects is a checker defect on
    the path the design requires (values.md:1128-1130: element access through
    specialized constructs), fixed in the same PR if one round, else the
    workstream parks per R28(c) with the isolating golden's diagnostic as the
    residue's evidence, disclosed in the fold. Also settled at planning:
    `.size = N` inside a generic method (IntLiteral → i64, iterate.carbon:25)
    stays as a named shape; deduction of `[N: IntLiteral]` through `array(T,
    N)*` is NOT a risk — deduce.cpp:117-146 (`AddInstArg`) walks `TypeInstId`
    arguments structurally, so `array(T, N)*` is the generic walk, not a
    special case; rev 1's explicit-`N` `FromArray(4, &a)` contingency is
    withdrawn.
-   **R-5 — the `IndexWith(U)` blanket impl over `U: ImplicitAs(i64)`
    is ambiguous or unmatched for `IntLiteral` subscripts.** Precedent:
    string.carbon:31-33 has the identical shape and `msg[i]` /
    `"abc"[0]` work (io.impl.carbon:10). Falsifier: `from_array_index`
    diagnosing "no impl of `Core.IndexWith(Core.IntLiteral)`" or an
    ambiguity. Contingency: a second concrete impl for `IntLiteral`
    (the int.carbon:31/:42 pair pattern). **Amended 2026-10-05 (round
    3; R28(d): a review miss recorded in place) — the precedent was
    misapplied and the risk fired at the hosted fill (run 37329946461:
    `FATAL ... Missing constant value for call to comptime-only
    function` lowering `Slice.At(i32, Core.IntLiteral as ImplicitAs(i64))`).**
    The blanket impl matched; what cannot work is its BODY for `U =
    IntLiteral`: `IntLiteral as ImplicitAs(Int(To)).Convert` is
    `"int.convert_checked"`, compile-time only (eval.cpp
    `IsCompTimeOnly`), and `subscript` is a runtime parameter with no
    constant in that specific. string.carbon:30-31 is NOT a precedent for
    this shape: its `At` IS a builtin (`"string.at"`), lowered at the
    CALL site with the call site's constant argument. Neither
    contingency (a second IntLiteral impl would hit the same body
    problem) applies. Root fix in the toolchain, not a narrowing of the
    API: (1) slice.carbon/buf.carbon declare `IndexWith(i64)` only, `At`
    calling `Get` directly; (2) check/handle_index.cpp applies the
    literal-subscript rule — an `IntLiteral`-typed subscript on an
    operand that implements `IndexWith(i64)` and has no
    `IndexWith(Core.IntLiteral)` impl converts to `i64` before dispatch
    (`ConvertToValueOfType`, the array arm's hardcoded conversion decided
    by a non-diagnosing `LookupImplWitness(..., diagnose=false)` probe
    whose facet type is built from the interface decl and a specific, so
    the probe emits nothing and adds no instructions; `Core.IndexWith`
    is resolved with the new non-diagnosing `TryLookupNameInCore`). The
    refinement "and implements `IndexWith(i64)`" (not in the round-3
    brief) is what keeps every existing `IndexWith` golden byte-identical:
    a literal subscript on a type with neither impl still diagnoses
    `Core.IndexWith(Core.IntLiteral)` (index/fail_invalid_base,
    index/fail_non_tuple_access, operators/overloaded/index_with_prelude
    `fail_invalid_subscript_type`/`fail_index_with_not_implemented`), a
    type with its own `IndexWith(Core.IntLiteral)` impl (String,
    index_with_prelude `overloaded_builtin`) is dispatched as written, and
    the missing/wrong `Core.IndexWith` splits of operators/overloaded/
    index.carbon are not probed (`nullopt`), so they diagnose once as
    before. Consequence: an `i32` subscript on a `Slice`/`Buf` is an
    error (`fail_subscript_i32`); slices_bounds_fail_stop.carbon's
    `s[RuntimeSeed(-18)]` becomes `s[RuntimeSeed(-18) as i64]`; the
    `index_runtime_subscript` positives take `i: i64`. Recorded as a fork
    decision in slices.md ("The API", "0.1 limits"). **Amended 2026-10-05
    (round 4; R28(d)) — "every existing `IndexWith` golden
    byte-identical" was wrong on four files, and hosted autoupdate run
    37335213696 moved them:** index/fail_invalid_base (two `IndexWith`
    constants reordered), index/fail_name_not_found (`.IndexWith =
    <poisoned>`), index/fail_non_tuple_access (`%Core.Int ... import_ref
    ... loaded`, `.Int = %Core.Int`, `%Int.type`/`%Int.generic`),
    operators/overloaded/index_with_prelude (the same `Int` import plus a
    `%complete_type.357` renumbering). Two causes. (1) The probe ran on
    operands the dispatch rejects BEFORE any lookup: `BuildBinaryOperator`
    exits for an `ErrorInst` operand (`N[0]`, `F[1]` —
    `UseOfNonExprAsValue`; `a[0]` with `a` unresolved), so the probe's
    `TryLookupNameInCore(IndexWith)` loaded (the reordering) or poisoned
    (`fail_name_not_found`) the name where the dispatch never did. Fixed:
    no probe for an `ErrorInst` operand; both goldens restored and
    predicted byte-identical. (2) `MakeIntType` → `LookupNameInCore(Int)`
    loads the `Core.Int` import_ref into the file, and the `Int`
    generic's constants with it; a discarded inst block cannot undo
    file-level import state, and `i64` IS `Core.Int(64)` — there is no
    way to name it without that load (re-review finding 1; its option
    (b) is impossible). Disclosed and kept as filled: fail_non_tuple_access
    (`0[1]` is the file's only integer-typed expression) and
    index_with_prelude (`fail_invalid_subscript_type` /
    `fail_index_with_not_implemented`: `C` has no
    `IndexWith(Core.IntLiteral)` impl, so the `i64` leg runs). Semantics
    are unchanged in all four — the dispatch still diagnoses
    `Core.IndexWith(Core.IntLiteral)`. Re-review finding 2 folded:
    `TryLookupNameInCore(Int)` guards `MakeIntType`, so a `Core` with a
    one-parameter `IndexWith` but no `Int` emits no spurious
    `CoreNameNotFound`. Round-3 audit miss: it reasoned per golden about
    the `i64` leg's associated IRs and never asked what a name lookup
    leaves behind.
-   **R-6 — the `{T*, i64}` ↔ `std::span` layout premise.** libc++'s
    dynamic-extent `span` is `_Tp* __data_; size_type __size_;`,
    libstdc++'s is `pointer _M_ptr; __extent_storage<dynamic_extent>
    _M_extent;` (one `size_t`), both 16 bytes with the pointer first —
    the same premise `str`/`string_view` rests on. Falsifier: lower
    interop/cpp/span.carbon showing a `memcpy` of a size other than 16
    or the conformance round trip printing a wrong size. Contingency:
    the layout-recognizer approach of cpp_initializer_list.cpp:13-49
    (PointerInt kind) and a conversion builtin — D-SL-8's break.
-   **R-7 — `LookupCppClassTemplate({"std", "span"})` misses the inline
    namespace `__1`.** It finds `Carbon::expected` today and
    `LookupCppType({"std", "string_view"})` finds an inline-namespaced
    alias (type_mapping.cpp:319-321), so std-namespace lookup sees
    through inline namespaces (Clang's `LookupQualifiedName` does).
    Falsifier: `function/export/slice.carbon` diagnosing the
    "failed to map" TODO with the mock present. Contingency: the mock
    puts `span` directly in `std` for the golden (as string_view.carbon
    does with `__1` — it uses `inline namespace __1` and passes) and the
    real-header case is the conformance program's job.
-   **R-8 — the thunk (`Consume__carbon_thunk` in SemIR,
    `@<mangled Consume>.carbon_thunk._` in IR; amended 2026-09-28, review fold:
    rev B B6) for a `std::span` parameter needs the span to be
    copy-constructible from the pointer-passed object.** It is (trivially
    copyable). Falsifier: Clang diagnostics inside the synthesized thunk body in
    span.carbon's fill.
-   **R-9 — the D-SL-9 owning→view chain (five steps: member lookup with the
    const filter → witness → `CppDataPointer` selection on
    `Optional(const i32*)` → `ImplicitAs(u64)` on `u64`/`ULong64` then `As(i64)`
    on `u64` (D-SL-9; amended 2026-09-28, review fold: rev A A2) → blanket
    `ImplicitAs(Slice(C.Element))` with a projection in the interface
    argument).** Precedents per step are cited in §1.B.3; the untested
    composition is the risk. The last step's mechanism (amended 2026-09-28,
    review fold: rev B B9): `TryGetSpecificWitnessIdForImpl`
    (impl_lookup.cpp:245-290) runs `DeduceImplArguments` (deduce.cpp:649-664),
    which adds Self and the interface specific to the worklist; `Deduce()`
    (:462-480) does not FAIL on a non-binding symbolic param such as `C.Element`
    (it `continue`s), and the match is then verified by
    `GetImplInterfaceInSpecific(...) == query specific` (:278-284) after
    substitution — which requires evaluating `C.Element` (a `CppContiguousRange`
    lookup, then a `CppDataPointer` lookup) inside specific resolution. Viable,
    not proven: no in-tree impl has a projection in its interface-argument list
    (grep over core/ and check/testdata is empty). Falsifiers, in order: (i)
    `member_data_size` failing `AssertIsContiguous` (witness not built); (ii)
    `vector_view.carbon` diagnosing "no impl of
    `Core.ImplicitAs(Core.Slice(const i32))`" (the constraint or the projection)
    — contingency for (ii), one line and no PR-shape change: the
    deducible-parameter spelling `impl forall [E: Copy & Destroy, C:
    CppContiguous where .Element = E] C as ImplicitAs(Slice(E))`, where `E` is
    deduced from `Slice(const i32)` through `ClassType` (`deduce_through`,
    sem_ir/typed_insts.h:502-507) and the rewrite constraint is checked in
    `CheckDeductionIsComplete`; if (ii) names the `Size` step instead, the
    second contingency is the appended `impl CppCompat.ULong64 as As(i64)` of
    D-SL-9's rejected alternative; (iii) `cpp_span_view` COMPILE-FAIL on the
    real `std::vector<int>` (real-header member overload sets: libc++'s `data()`
    has exactly two overloads, `size()` one — but `size()` on libc++ is `size()
    const noexcept`; if `LookupCppMethod` reports "overload sets unsupported"
    the filter did not reduce to one). Contingency (loud, D-SL-9): the PR lands
    without commit 2; the program stays SKIP with the refreshed reason; the
    bullet is PARTIAL; residue "owning C++ container to Core.Slice view" carries
    the refuting run id and the last step reached. **Amended 2026-10-05 (SL-2
    round 1).** The first fill (run 37356848697) diagnosed falsifier (ii)'s text
    for a reason this risk never listed: the impl was an orphan in
    cpp/slice.carbon and unreachable by lookup from there (§2.B.9 amendment,
    R28(d)). The projection step itself stands, and "no in-tree precedent" was
    stale: impl/lookup/access.carbon:26 `impl forall [T: Z where .Z1 impls Y] T
    as X(T.Z1.(Y.Y1))` is the shape (two nested `ImplWitnessAccess` in the
    interface argument, type structure `? as X(?)`, a concrete query resolving
    in that file's `F`), and the post-deduction check
    `GetImplInterfaceInSpecific(...) == query specific` evaluates `C.Element`
    through `EvalLookupSingleFinalWitness`, which consults `LookupCppImpl` for a
    concrete C++ self — the same evaluation that resolves `.ElementType =
    T.ValueType` for `for` over a C++ range (range_for.carbon). The primary
    spelling is kept; the rev B B9 fallback is not applied. **Amended 2026-10-05
    (SL-2 round 2).** Step 4's original per-target reading stands (`size_t` is
    `u64` on LP64 Linux and LLP64 Windows, `ULong64` on Darwin; §1.B step 4).
    Falsifier (i) did NOT fire: impls/cpp_contiguous_range.carbon came back with
    no CHECK lines from both fills, which round 1 read as a crash and attributed
    to `ULong64` reaching `LookupCppMemberWithResultType`'s `CARBON_CHECK` —
    unexplained at the time; root cause, read from the harness: the check
    component runs `--dump-sem-ir-ranges=only` (toolchain/testing/file_test.cpp
    `GetDefaultArgs`), the golden had no `//@dump-sem-ir-begin` range and its
    three splits produced no diagnostic, so stdout and stderr were empty and
    `FileTestAutoupdater` had nothing to write (both runs: "Ran 1898 tests" =
    1896 `.carbon` + 2 driver `.cpp`, no `<test>: <error>` line, a `.` not a `!`
    for it). That is a clean PASS of `AssertIsContiguous(Cpp.V)` and `let _: ...
    .SizeType = u64 = Cpp.V` with `unsigned long size()` — positive evidence for
    `u64`, not against it. The precedent's positive splits are empty the same
    way (its 110 CHECK lines are all in `fail_todo_`/`fail_deleted` splits).
    Round 2 restores `unsigned long` and `.SizeType = u64` and adds dump ranges
    around the three `Test()` bodies so the next fill shows the witness; the
    round-1 code change (`void` → `None`, error → propagated) stays, as a real
    ICE fix for `void data(); void size();`. **Amended 2026-10-05 (SL-2 round
    3).** That fill (run 37367343836) HUNG in the file_test run and was
    cancelled (W-121); round 3 keeps one dump range, on `missing_size` only, and
    the witness evidence stays with vector_view.carbon's `view` split — see the
    hand-off notes.
-   **R-10 — `Cpp.std.vector(i32)` itself does not import** (a real
    libc++ class template with allocator/compressed-pair members).
    Precedents: `std::atomic<int>` and `std::mutex` import and destroy
    (cpp_atomic_*, cpp_thread_mutex_raii PASS). Falsifier: COMPILE-FAIL
    naming a `vector` member type. Contingency: `cpp_span_view` uses a
    `std::array<int, 3>` (also `data()`/`size()`) for the owning half
    and the `vector` case becomes residue — disclosed.
-   **R-11 — `-std=c++20` through `--clang-arg` is rejected or ignored
    by the runner's compile line.** `COMPILE-ARGS` is whitespace-split
    into the `carbon compile` argv (runner.py:207-213, :163-165) and
    `clang-arg` is an appendable driver flag (compile_options.cpp:35-46).
    Falsifier: COMPILE-FAIL "unknown option" or `<span>` "file not
    found"/"requires C++20". Contingency: none needed for goldens (mock
    header, D-SL-14); for conformance, the test-prelude-free
    `cpp_iostream.carbon` precedent proves real libc++ headers resolve.
-   **R-12 — `Buf(T)`'s user `impl as Destroy` inside a GENERIC class has no
    in-tree precedent (amended 2026-09-28, review fold: rev B B1 / rev A
    A9).** DECIDED AT PLANNING, not by the fill: rev 1's version of this risk
    ("`Destroy` runs on an unformed `var b: Core.Buf(i32);` and frees
    garbage") was decidable from the code — destroy on `var` storage is
    unconditional (pattern_match.cpp:1727, control_flow.cpp:151-158; D-SL-6),
    so its falsifier would have fired with certainty and cost a hosted round;
    rev 1's contingency is now the decision (`Buf` is not `UnformedInit`;
    `fail_unformed` pins the refusal). What remains unverified is the user
    `Destroy` impl itself: every in-tree user `Destroy` impl is on a CONCRETE
    class (lower/testdata/var/param.carbon:17-21, :36-41;
    lower/testdata/operators/question_generic.carbon:114-121 `Tag`);
    `Buf(T)`'s is the first inside a generic class. Falsifier: no `destroy`
    line on `%b.var` in `make_get_set`'s check dump, a `Destroy` witness
    failure at the `Buf(i32)` specific, or no `call void @free` inside the
    destroy specific of lower slice/buf.carbon. Contingency: none at the shape
    level that keeps `ptr` private (an out-of-class `impl forall [T] Buf(T) as
    Destroy` cannot read `self.ptr`, R-13) — a witness failure on the specific
    is a checker defect in the design's own destructor spelling (classes.md),
    fixed in the same PR if one round, disclosed in the fold. **Amended
    2026-10-05: the falsifier FIRED at the implementation review, not at
    the fill, and was decidable from the tree** — the user impl inside the
    generic class is well-formed, but no user `Destroy` impl was ever
    SELECTED: the destroy custom witness preempted declared impls
    (impl_lookup.cpp) and `CanDestroyClass` never looked for one. Fixed in
    the same PR (one round) at the root — `CanDestroyClass` yields to a
    class-keyed declared impl (§6.A amendment lists the six goldens that
    move). The arbiters (check slice/buf.carbon `make_get_set`'s
    `@Buf.as.Destroy.impl` call; lower slice/buf.carbon's `call void
    @free` inside the destroy specific) now mean what their comments say.
    New limit disclosed in slices.md: a `Buf` held in a FIELD is not freed
    (aggregate destroy ops are still the member-destruction placeholder).
-   **R-13 — private field access from an out-of-class impl.** Caught
    at planning (§1.A.2's paragraph): every out-of-class impl routes
    through `Data()`/`Size()`/`Get`/`UnsafeMake`. Falsifier: any
    "private member" diagnostic in the prelude compile. Contingency: the
    offending access is replaced by the public accessor — never by
    dropping `private` from the fields.
-   **R-14 — `EXPECT-EXIT: -6` breaks `runner.py --self-test` or the
    README table generator.** `int("-6")` parses; the table marks
    `exit: -6`. Falsifier: `--self-test` failing on the directive.
    Contingency: D-SL-12's break condition (an `EXPECT-SIGNAL`
    directive) — a runner change in the same PR, disclosed.
-   **R-15 — autoupdate needs a second pass.** The `fail_` files insert
    STDERR lines above dumped code and the Clang diagnostics in
    `fail_span.carbon` echo snippet line numbers — expect pass 2 to be
    `loc`-only (R26); structural drift on pass 2 is a stop.
-   **R-16 — a lower golden's PHI carries a by-reference value.** Slice
    `Get`'s `if` merges nothing by value (the fail branch does not
    return); `Subslice` computes `end - start` before the struct init.
    Falsifier: a lowering fatal about block arguments in the slice
    goldens. Contingency: hoist the computation into a `let` before the
    `if`.
-   **Rejected alternatives (recorded):** a whole-op `"slice.at"`
    builtin (D-SL-5); array-value → slice `ImplicitAs` (D-SL-2);
    `llvm.trap` instead of `abort` (SIGILL/SIGTRAP differ by
    architecture; no message); `exit(1)` instead of `abort` (not
    fail-stop: it runs atexit handlers and flushes, terminology.md
    :100-102 "minimizing any further business logic"); `Slice.Set`
    (D-SL-3's const hazard); implementing `Buf` element destruction with
    an explicit `Destroy.Op` loop (no precedent; residue); a `buf(T)`
    keyword (placeholder name, lexer churn); putting the `Iterate` impl
    in slice.carbon (import cycle) or mid-file in iterate.carbon (DI
    churn).

## §8 Verification and discharge

1.  **Regen (per PR):** `Fork: hosted verification` mode `compile` on
    commit 1 (R-3), then `autoupdate` to fixpoint on the full PR
    (R26/R28(d): the gate's file_test pass proves it); expected churn is
    NEW files only (§6; no raw_sem_ir golden can move, §6.A(c)). ANY
    pre-existing golden in the diff is a stop (amended 2026-09-28, review
    fold: rev B B10).
2.  **Gate:** mode `gate` green (prek + `bazel test //toolchain/...`;
    clang-format 21.1.8 per R18; `uvx prek run --files <changed>` locally
    before every push, R25). The diagnostics coverage test and the parse
    coverage test are part of the gate (one new kind,
    `IncompleteTypeInBuiltinCall`, covered by the filled
    `fail_incomplete_pointee` splits — amended 2026-10-05, round 4; a
    reviewer should still diff kind.def).
3.  **Conformance:** mode `conformance`; deltas per §5 (SL-1 +3 PASS /
    −1 SKIP / +2 total; SL-2 +2 / −1 / +1, or +1 / 0 / +1 under the
    D-SL-9 fallback) on whatever base trunk has at rebase time — on the
    expected post-OV-1/post-UN-2 base 118/0/24 over 142 (the OV-1
    decision-log entry's post-merge reading; UN-2 alone is trunk
    50839d68e at 116/0/25 over 141 — header, rev A A8) that is 121/0/23
    over 144 after SL-1 and 123/0/22 over 145 after SL-2 (re-quoted from
    scoreboard.json at rebase, never by hand: R9). `runner.py --self-test` and
    `--update-readme-table` clean. Any other movement is a §5/§6 miss —
    stop and reconcile.
4.  **Reconciliation greps at discharge:** after SL-1, `grep -rn
    '"pointer.offset"\|"fail_stop"\|"heap.allocate"\|"heap.free"'
    toolchain core` hits builtin_function_kind.cpp once each, the prelude
    declarations (slice.carbon, buf.carbon) and the builtin goldens;
    `grep -rn 'Unsupported builtin call' toolchain/lower` still hits
    :664 once; `grep -rn 'Slice' core/prelude` hits slice.carbon,
    buf.carbon, types.carbon, iterate.carbon only. After SL-2, `grep -rn
    'CppContiguousRange' toolchain core` hits core_interface_kind.def,
    core_identifier.def, impl_lookup.cpp (two sites), custom_witness.cpp
    (one), slice.carbon, and the impls golden; `grep -rn
    'CustomCppTypeMapping::Str' toolchain` hits the two switch arms;
    `grep -rn 'RecognizedTypeInfo::Slice' toolchain` hits type_mapping.cpp
    once, and `grep -n 'Slice' toolchain/sem_ir/type_info.cpp` hits three
    lines — `ExpectsArgs`, the `.Case("Slice", Slice)` and the
    `PrintLiteral` `case Slice:` (amended 2026-09-28, review fold: rev B
    B4); `ls toolchain/*/testdata/builtins/ | grep fail_stop` is empty —
    the goldens are `failstop.carbon` (rev B B3).
5.  **Ledger edits (fork/inventory/work-items.json):**
    -   W-055 → kind `implemented`, evidence = builtin_function_kind.def
        lines, slice.carbon, buf.carbon, the §4.A goldens,
        `slices_basic` + `slices_heap_buf` + `slices_bounds_fail_stop`;
        notes record §0.2 items 1, 3, 4 and D-SL-1..7, 10-13 by name, and
        "not prelude-only: four builtins".
    -   W-056 → kind `implemented`, blocked_by cleared, evidence = the
        §4.B goldens and §5.B programs; notes record §0.2 items 2, 7, 9,
        D-SL-8/9/14 and the fallback outcome if it fired.
    -   gap-analysis row 74's `{Char*, u64}` → `{Char*, i64}` (§0.2 item
        6); row 76 PARTIAL (SL-1) with the residue list; row 79 DONE or
        PARTIAL (SL-2); the header counts; the §W9 paragraph gains
        "slices and heap allocation landed (SL-1/SL-2); String and
        Optional remain".
    -   **NEW residue items, referred to BY TITLE; ids allocated at
        discharge** by `grep -oE '"id": ?"W-[0-9]+"'
        fork/inventory/work-items.json | sort -t- -k2 -n | tail -1` on
        trunk at that moment (W-094..W-104 are being taken by OV-1 —
        never assume numbers): "write-through slice indexing
        (`IndirectIndexWith`, `ref` returns)" (D-SL-3; mechanism:
        indexing.md's rewrite rules in handle_index.cpp:79-80 and a `Ref`
        member on `IndexWith`); "`buf(T)` keyword shorthand for
        `Core.Buf(T)`" (D-SL-6); "`Core.Buf` element destructors and an
        `Allocator` parameter" (D-SL-6; mechanism: explicit destroy calls
        or the `TrivialDestructor` facet, details.md:4190-4192);
        "over-aligned `Core.Buf` element types" (`aligned_alloc`);
        "runtime bounds diagnostics with the offending index" (D-SL-4);
        "unchecked slice access (the release-build enforcement opt-out,
        safety/README.md:222-224)" (D-SL-4; amended 2026-09-28, review
        fold: rev A A3); "`Core.Buf` unformed declarations (needs
        unformed-state-aware destroy)" (D-SL-6; amended 2026-09-28,
        review fold: rev B B1);
        "array-value to slice conversion" (D-SL-2, only if upstream
        specifies it — otherwise not filed); "static-extent `std::span`
        mapping" (D-SL-8); "owning C++ container to Core.Slice view" —
        ONLY if the D-SL-9 fallback fires; "ADL `data`/`size` sources
        for `CppContiguousRange`" (§1.B.3).
6.  **Docs (D-SL-13):** at SL-1, new docs/design/slices.md with the status
    paragraph "fork amendment 2026-09-28 (F-012): `Core.Slice(T)` and
    `Core.Buf(T)` as implemented; toolchain status: SL-1 landed <date>; interop
    mapping at SL-2", sections: Overview (view semantics, explicit formation
    from `&a`, D-SL-2), the API (§1.A.2/§1.A.3 signatures), Bounds behavior
    (D-SL-4 with the safety citations, saying that the fail-stop-with-message is
    the DEBUG-build promise adopted as the single 0.1 mode and naming the
    release opt-out residue — amended 2026-09-28, review fold: rev A A3), Heap
    buffers (D-SL-6 with the p004682 placeholder-name note), Iteration, Interop
    (filled at SL-2: D-SL-8/9/10, the `std::span<const int>` ↔ `Core.Slice(const
    i32)` rule, the `-std=c++20` note), "0.1 limits" (every residue title with
    its break condition), Alternatives considered (the §7 rejected list),
    References (README.md arrays section, indexing.md, values.md, safety README,
    p002274, p004682, milestones.md). README.md:912-914 becomes a three-sentence
    summary + link, marked "(fork amendment 2026-09-28, F-012)";
    README.md:887-889's `buf(T)` sentence gains a parenthetical "(the fork
    implements `Core.Buf(T)` without the shorthand, see Slices)". At SL-2,
    docs/design/interoperability/ README.md:251-252's TODO ("C++ view types such
    as `std::span` and other standard library types will have corresponding
    types in Carbon") is REPLACED by the dated paragraph, as a subsection titled
    `std::span` and `Core.Slice` beside the existing `std::string_view` and
    `str` subsection (:254) (amended 2026-09-28, review fold: rev A A10).
7.  **ORCHESTRATION stamp** per landing (status paragraph, the floor,
    the PR count, the R28 dispatch list if goldens are parked); the
    weekly-cut rows are untouched.

## Hand-off notes for the implementer

-   Commit 1 first, hosted `compile` probe second, goldens third. The
    four builtins are three exhaustive switches and one runtime-fatal
    switch (R-3); a missed lower arm is invisible until a golden runs.
-   `fail_stop`'s lowering: load the `str` exactly as `StringAt` does
    (:417-425), declare `write` with the byte-identical signature of
    handle.cpp:349-350, mark `abort` `noreturn`, emit NO terminator
    (R-1). If the verifier complains, R-1's contingency — never drop the
    `noreturn`, never `exit`.
-   `heap.allocate`'s element type comes from the RESULT type, not from
    an argument — and that type is the ADAPTER CLASS
    `Core.MaybeUnformed(T*)`: unwrap it with `GetTransitiveAdaptedType`
    (or `GetObjectRepr`) in the type's file, `CARBON_CHECK` the result is
    a `MaybeUnformedType`, then take the pointee (§1.A.1 row 3; rev B
    B2). `arg_ids.size() == 1`; `arg_ids[0]` is the count, sign-extended
    to `i64` before the multiply; the zero guard is a `select`.
-   Amended 2026-10-05 after the first hosted autoupdate (run
    37324972577): both pointee-sized arms need the pointee COMPLETE in
    the specific's file, and nothing at such a call completed it — a
    pointer type is complete without its pointee, so in heap.carbon's
    `A` and pointer_offset.carbon's `F` the type `i32` (`Core.Int(32)`,
    an adapter class) was never completed; lowering represents an
    incomplete type as the unsized opaque struct
    (`FileContext::GetTypeAndDIType`), which asserted in
    `getTypeAllocSize` ("Cannot get layout of opaque structs",
    heap.carbon) and failed the IR verifier with "GEP into unsized
    type!" (pointer_offset.carbon — the second crash of that run, not
    R-1: the `fail_stop` block shape was not refuted). Fixed at the
    root in the checker, where completeness requirements belong:
    `PerformCallToFunction` requires the pointee complete at every
    `pointer.offset`/`heap.allocate` call
    (`RequireBuiltinCallPointeeComplete`, check/call.cpp; a symbolic
    pointee records a `RequireCompleteType` in the enclosing generic,
    enforced per specific), with the new Context diagnostic
    `IncompleteTypeInBuiltinCall` and `fail_incomplete_pointee` splits
    in both check goldens; both lower arms `CARBON_CHECK` `isSized()`.
    The B2 unwrapping shape stands unchanged.
-   Amended 2026-10-05 after the implementation review (REJECT: one
    BLOCKER, two MINOR): `Buf`'s `impl as Destroy` was never selected —
    the destroy custom witness wins impl lookup unless it declines, and
    `CanDestroyClass` did not decline for a class with a declared impl.
    Root fix in check/custom_witness.cpp: `CanDestroyClass` returns
    `NoDestroy` when `HasClassKeyedImpl(class, Destroy)` holds — the
    class-keyed two-population scan generalized from the union rule's
    `HasUserCopyImplOutsideCore` (NOT `HasUserDestroyImpl`'s symbolic-self
    shortcut, which would let any blanket impl disable the witness for
    every class); `partial` selves keep the synthesized witness (a
    declared impl's self never matches `partial C`). Lookup then selects
    `impl forall [T: Copy & Destroy] Buf(T) as Destroy`; `AddCleanups`
    (control_flow.cpp) builds the `Destroy` unary operator on `%b.var`,
    which binds the impl's `fn Op(ref self)` to the var storage (a user
    `fn Op(self)` is adapted by the impl's signature thunk), and the
    specific `Buf(i32).as.Destroy.impl.Op` lowers `HeapFree` to `call void
    @free`. Six existing goldens move (§6.A amendment). `heap.allocate`
    now multiplies with `llvm.umul.with.overflow.i64` and selects a null
    block on wrap (MINOR 2). The W-055 ledger notes, slices.md and the
    decision-log carry the same record; residue W-108 (W-105 before the
    discharge renumbering) files the
    member-held `Buf` leak (synthesized aggregate destroy ops run no
    member destructors).
-   Amended 2026-10-05 (round 3, after hosted autoupdate run 37329946461
    crashed in lower/testdata/slice/basic.carbon): a RUNTIME value of type
    `Core.IntLiteral` cannot exist in lowered code — every `IntLiteral`
    conversion is a comptime-only builtin — so no prelude generic may take
    a `U: ImplicitAs(i64)` (or any facet `IntLiteral` satisfies) parameter
    and convert it at runtime unless the body is itself a builtin lowered
    at the call site (String's `At`). `Slice`/`Buf` take `IndexWith(i64)`
    only, and the literal-subscript rule in check/handle_index.cpp
    converts a literal to `i64` when the operand implements `IndexWith(i64)`
    but not `IndexWith(Core.IntLiteral)` (R-5 amendment). Re-audit of
    slice.carbon/buf.carbon/iterate.carbon for the same class: `.size = N`
    in `FromArray` is a GENERIC `N` (constant per specific, folds, the
    iterate.carbon:25 precedent); `*cursor - 1`, `i < size`, `0`, `1` are
    literal constants — nothing else is a runtime `IntLiteral`.
-   Amended 2026-10-05 (round 4, after hosted autoupdate run 37335213696
    moved 40 files for 18 predicted; §6.A(a)-(d) and R-5 hold the
    records). Lessons for the next fixer: a `grep 'as Destroy'` over
    core/ is not a prediction — the impl you are ADDING is in the result
    set, and every prelude impl is in every file's import set, so any
    predicate keyed on "some symbolic self exists" (`HasUserDestroyImpl`
    was) is reached by it in every TU; `ImportImplFilter` imports by
    interface only, so appending a prelude `Iterate` impl changes the
    lowered output of every `for` golden over the full prelude (an
    uncalled `declare` of each concrete `Destroy` facet in its rewrites);
    a `where` rewrite is known in a generic body only through a `final
    impl` (the Slice/Buf `IndexWith(i64)` and `Slice` `Iterate` impls are
    `final`); a non-diagnosing probe's name lookups are file-level state
    (`import_ref`s, scope poison) that `inst_block_stack` cannot discard —
    probe only where the dispatch itself looks the name up, and when a
    load is unavoidable, say which goldens show it.
-   Amended 2026-10-05 (SL-2 round 1, after hosted autoupdate run
    37356848697 moved 306 files): the orphan rule is a PLACEMENT rule for
    blanket impls — `impl forall [C: SomeConstraint] C as I(Slice(...))`
    must live in the library of a class in its self type or interface
    arguments (`Slice`'s), never in the library of the constraint; and
    impl lookup only ever imports impls from the libraries of the query's
    own types, so an impl that the orphan rule would reject is also one
    lookup would never find. When a prelude impl needs a name its file
    does not import, put the NAME behind a local interface in the helper
    library (`CppSizeToI64` hides `u64`) rather than moving the impl. A
    synthesized witness supplies associated constants as bare `type`s, so
    `Destroy`/`Copy` on them are stated as `require Self.(X) impls ...` on
    the constraint, not as bounds on the interface's `let`s. `unsigned
    long` imports per target — `u64` on x86_64-linux-gnu (it is `uint64_t`
    there), `Core.CppCompat.ULong64` only on Darwin, `ULong32` on LLP64 —
    so a `--target=x86_64-linux-gnu` primitives-prelude golden may name
    `u64` for it; a result-type `CARBON_CHECK` in a witness builder is an
    ICE for `void` members. Read fill-time "no CHECK lines" with the
    harness in hand before calling it a crash: a check golden with no
    `//@dump-sem-ir-begin` range and no diagnostic is a clean PASS that
    writes nothing (`--dump-sem-ir-ranges=only`), and the log shows a
    crash as `Stack dump:`/`CHECK failure` and an abort before "Ran N
    tests", never as a quiet `.`; give every positive split a dump range
    if its evidence must be visible.
-   Amended 2026-10-05 (SL-2 round 3, after hosted autoupdate run
    37367343836 hung): the round-2 fill that first dumped impls/
    cpp_contiguous_range.carbon's three `Test()` bodies ran 32+ minutes in
    the file_test step (every earlier fill: ~12 min build + ~40 s for all
    1898 tests) with no `Stack dump:` and was cancelled. The formatter and
    inst namer run only when a `//@dump-sem-ir-begin` range exists
    (check.cpp `MaybeDumpFormattedSemIR`), so the dump is what changed; the
    only other deltas since the clean fill — `unsigned int` → `unsigned
    long` (`u64` on this target, which span.carbon and vector_view.carbon
    already dump), `_Nonnull` on fail_vector_view's `data()`, and
    `GetOrEmpty` on `Slice`'s bindings block (a read of a block that is
    never `None`) — cannot loop. The same witness dumps cleanly in
    vector_view.carbon, so the first-dumped shapes are the `let` facet
    value typed `CppContiguousRange where .DataType = … and .SizeType = …`
    over a synthesized witness and the `final impl forall [T:
    CppContiguousRange]` specific whose argument is that facet value. No
    loop was found by reading (the namer's fingerprint worklist,
    sem_ir/inst_fingerprinter.cpp `Run`, is the one unbounded walk on the
    naming path and has no cycle guard — a hypothesis, not a finding), so
    the plan's testdata fallback applies: ONE range, on `missing_size`,
    the split where no witness is built; the positives pass silently as
    before; W-121 holds the residue with the run id. Rule: a dump range on
    a shape no filled golden dumps is itself a fill risk — bisect it one
    range at a time, and a hang in one test blocks the whole 2-thread run.
-   **Amended 2026-10-05 (SL-2 round 4, after hosted conformance run
    37378790657).** The first of-record conformance run (on 76c695db4, the
    trunk merge) FAILED both new programs, and neither failure is in the
    §1.B mapping the reviews traced: both the implementation review and the
    re-review traced the span ABI claim as fine (R28(d)), and it IS fine --
    the thunk takes `std::span<const int>* _Nonnull`, returns through the
    out-pointer, and copies the `{ptr, i64}` register return field-wise
    into the Carbon slot (span.carbon's lowered `Produce` thunk). The
    misses are elsewhere. (a) `cpp_span_view` COMPILE-FAIL: an ICE at
    `let view: Core.Slice(const i32) = v;` (`Casting inst {kind: ClassType
    ...} to wrong kind ClassDecl`, import.cpp `GetFunctionName`). With
    `<span>` in the TU, `MapToCppType(Core.Slice(const i32))` is
    `std::span<const int>`, so the `ImplicitAs` lookup's C++ half
    (operators.cpp `LookupCppConversion`) runs Clang's initialization
    sequence, which selects `span`'s RANGE CONSTRUCTOR for the
    `std::vector<int>` source; importing that constructor casts its
    parent's inst -- the mapped `Core.Slice(const i32)` `ClassType`, not a
    `ClassDecl` -- to `ClassDecl`. No golden reached the path: every
    container mock sits in a header WITHOUT `std::span`, so the C++ map is
    null and the lookup declines before Clang runs. Fix at the root:
    `LookupCppConversion` declines every constructor of a class whose
    `ClangDecl` inst is the mapped Carbon type rather than a `ClassDecl`
    (`std::span<T>` when the importer maps it, `std::string_view`; round 5
    narrowed this from "a class with a custom Carbon mapping", the
    matcher), and
    `BuildUnaryOperator` falls through to the prelude's blanket impl as
    D-SL-9 designs. New golden stdlib/vector_view_span.carbon: the mock
    `span` WITH the range constructor plus a `VecLike<T>` class template
    named through `VecLikeInt` (the specialization shape), splits `view`
    (the `let`) and `argument` (`Cpp.Consume(v)`), AUTOUPDATE-filled.
    (b) `cpp_span_roundtrip_diff` OUTPUT-MISMATCH `2 / -724362768 / 18`:
    `t.Size()` right, `t[0]` garbage. Every link of the span path is
    correct in the lowered IR (the `Slice(T) as ImplicitAs(Slice(const
    T))` body, `Data`/`UnsafeMake`, the thunk parameter and return), and
    the exported `Sum` reads `s[i]` through the identical
    `Slice(const i32).Get` specific correctly -- the garbage is `a[1]`.
    Root cause, upstream and latent: `var a: array(i32, 3) =
    (RuntimeSeed(-19), 2, 3)` is the only mixed constant/runtime
    tuple-to-array initializer in the suite and in every golden, and
    lower/handle.cpp `HandleInst(ArrayInit)` only forwarded the
    destination -- `LowerInst` skips the constant elements'
    `in_place_init`s as constants and the non-constant `array_init` makes
    the `var`'s `Assign` copy nothing, so `a[1]`, `a[2]` were never stored
    and `t[0]` read a stale stack word (`0xD4D22C70`).
    `EmitAggregateInitializer`'s `InPlace` arm already finishes constant
    fields for struct/tuple/class inits; `HandleInst(ArrayInit)` now does
    the same. New lower golden array/mixed_constant_init.carbon pins the
    two constant stores. The program's EXPECT (`2 / 2 / 18`) and its
    `RuntimeSeed` are unchanged. No existing golden moves: an all-constant
    `array_init` is itself a constant and never reaches the handler, and
    the all-runtime shape has no constant element. The failed run's totals
    were 126 PASS / 2 FAIL / 22 SKIP over 150 (bullets 47 / 1 / 8), every
    landed program unmoved; the next of-record run must show 128 PASS /
    0 FAIL / 22 SKIP over 150, 48/56 bullets.
-   **Amended 2026-10-05 (SL-2 round 5, after the round-4 re-review,
    APPROVE-WITH-FIXES: HIGH, MEDIUM, LOW; no hosted run between).** (HIGH)
    vector_view_span.carbon never reached the gate it pins: both splits
    convert a PARAMETER binding `v`, a Carbon value that
    `InventPrimitiveClangArg` invents as a C++ prvalue, and the round-4
    mock's range constructor took `R&`, which cannot bind one -- so
    `InitializationSequence` failed, `LookupCppConversion` declined before
    the step loop, and the fill b89020c8a showed the blanket impl for the
    wrong reason (the golden passes on 76c695db4 unchanged). The mock now
    takes the real header's forwarding reference `R&&`, the file gains
    `var_source` (`var v: Cpp.VecLikeInt = Cpp.MakeVecLike();`, the
    conformance program's lvalue category), and every CHECK line is
    cleared. By reading: on 76c695db4, `view`, `var_source` and `argument`
    now select the range constructor and ICE in `GetFunctionName`'s
    `GetAs<ClassDecl>`; with the gate they fall through to the blanket
    impl. (MEDIUM) The gate keyed on the MATCHER
    (`GetCustomCppTypeMapping(parent).kind != None`), but the importer
    applies the mapping conditionally: `LookupCustomRecordType` imports
    `std::span<T>` as an ordinary class when `T` is unmappable or fails
    `Slice`'s `Copy & Destroy` bound (span.carbon's `NoCopySpan`), and for
    that destination the constructor's parent IS a `ClassDecl` and the
    pre-round-4 import was fine -- the gate turned a working conversion
    into "cannot implicitly convert" for every `std::span<S>` over a C++
    class `S` (imported classes do not impl `Copy`). The gate now keys on
    the importer's decision: when the matcher fires it imports the parent
    type (`MapTagType` registers the `ClangDeclKey` either way) and
    declines iff the registered inst is not a `ClassDecl`
    (`LookupClangDeclInstId`, now declared in import.h); an
    already-diagnosed parent returns the error inst, and unmapped classes
    never enter the branch (no existing golden can move). New split
    `noncopyable_element_class_constructor`: `VecLike<Carbon::NoCopy>` ->
    `Cpp.NoCopySpan`, predicted to import and call the range constructor
    (impls/as.carbon's `Dest2__carbon_thunk` shape), as before round 4.
    (LOW) This amendment's and the decision log's "no Carbon declaration"
    wording narrowed to the registered inst's kind. No conformance program
    moves (both already take the mapped path); the next fill rewrites
    vector_view_span.carbon's four ranges and nothing else.
-   Out-of-class impls (`IndexWith`, `ImplicitAs(Slice(const T))`, the
    §1.B.3 interop impl) touch public API only (`Data`, `Size`, `Get`,
    `UnsafeMake`); `Buf.AsSlice` uses `UnsafeMake`. If you reach for a
    private field from outside its class, stop.
-   slice.carbon must not import `prelude/iterate` (cycle); the `Iterate`
    impl is APPENDED to iterate.carbon — do not insert it mid-file (DI
    churn in eight lower goldens, fork/eh/plan.md:1199-1215). The same
    rule inside slice.carbon: its `prelude/types/optional` import is in
    the SL-1 header on purpose, so SL-2 APPENDS its interop section and
    adds no line above a method (rev A A4).
-   D-SL-9's `Size` conversion is TWO steps — `ImplicitAs(u64)` then
    `As(i64)` — and the constraint is `ImplicitAs(u64)`; never constrain
    on `As(i64)` (`CppCompat.ULong64`, macOS `size_t`, has none; rev A
    A2).
-   `cpp_span_roundtrip_diff`: forward-declare `fn Sum` BEFORE the
    `inline Cpp` block that names `Carbon::Sum`; the `import Cpp inline`
    block holds only `<span>` and `Tail` (rev A A1).
-   Every fail-stop message ends in `\n` and starts with `carbon:`
    (the D10 epilogue's register).
-   Conformance: `RuntimeSeed` everywhere a value could fold; `EXPECT-
    EXIT: -6` for the fail-stop program and NO `EXPECT-STDOUT` there;
    `COMPILE-ARGS: --clang-arg=-std=c++20` on both SL-2 programs;
    `runner.py --self-test` before every conformance commit (R7); `uvx
    prek run --files` before every push (R25).
-   SL-2: the payload-carrying `CustomCppTypeMapping` is a struct; grep
    for the two `Str` uses and switch on `.kind`. The `Slice` export arm
    returns a `WrappedType` whose `wrap_fn` does the template lookup —
    a null from `LookupCppClassTemplate` propagates to the existing TODO
    paths; do not add a diagnostic kind.
-   SL-2 commit 2 is the fallback boundary (D-SL-9): if its fill is
    refuted and one round does not fix it, land without it and file the
    residue with the run id. Never weaken `cpp_span_view`'s EXPECT lines
    to make it pass (R16(b)).
-   Every new AUTOUPDATE golden ships with empty CHECK lines (R15/R19);
    in LOWER goldens positives and `fail_` subfiles never share a file
    (check goldens may mix them); no golden file or split begins with
    `fail_` unless it diagnoses (file_test_base.cpp:126-135;
    testing/file_test/README.md:81-83) — hence `failstop.carbon`, not
    `fail_stop.carbon` (rev B B3/B7); hand-derived EXPECT values only
    (R16(d)).

## Review fold record (rev 2, 2026-09-28)

Every finding of the two rev 1 reviews (rev A: design fidelity; rev B:
toolchain reality; both APPROVE-WITH-AMENDMENTS), where it was folded,
and the one place the fold departs from the reviewer's text (with the
evidence the departure rests on). The fixer re-opened every cited source
location before folding; trunk moved to 50839d68e (UN-2 merged,
116/0/25 over 141) while the reviews ran — line citations stay against
8e32108f8, and SL-1 rebases onto the trunk of its day.

| Finding | Disposition |
| --- | --- |
| rev A A1 (MAJOR): `cpp_span_roundtrip_diff` references `Carbon::Sum` from the `import Cpp inline` block that precedes `fn Sum` — a COMPILE-FAIL | folded at §5.B.2: `<span>` + `Tail` stay in `import Cpp inline`; `fn Sum(...) -> i32;` forward-declared; `CallSum` moved to a post-declaration `inline Cpp '''` block (cpp_atomic_global_counter_diff.carbon:14-31; function.carbon:60-67); hand-off |
| rev A A2 (MAJOR): `CppCompat.ULong64` has no `As(i64)` (cpp/int.carbon:150-176; as.carbon:27 forwards same-`U` only) — the D-SL-9 conversion silently absent on macOS | folded: constraint `ImplicitAs(u64)` + two-step conversion (D-SL-9 with the reason for the choice, §1.B.3 code and prose, §4.B `vector_view`, R-9, hand-off); the `impl ULong64 as As(i64)` alternative kept as R-9's second contingency |
| rev A A3 (MAJOR): D-SL-4 attributes the debug-build sentence (safety/README.md:229-232) to the release build | folded: header, D-SL-4 (the debug-build promise adopted as the single 0.1 mode, break condition unchanged), §1.A.6, §8.5 residue "unchecked slice access (the release-build enforcement opt-out, safety/README.md:222-224)", §8.6 slices.md "Bounds behavior" |
| rev A A4 (MAJOR): SL-2's `prelude/types/optional` import line repeats the EH-A DI-churn miss on SL-1's lower goldens | folded: the import is in SL-1's slice.carbon header (§1.A.2); §1.B.3, §2.B.9 (SL-2 appends only), §6.B new bullet, hand-off |
| rev A A5 (MINOR): R-4's precedents are inexact (optional.carbon:162/:170 are adapter casts, not `T*` derefs); pointer-then-array deduction is not a risk (deduce.cpp:117-146) | folded: §0.1 row 8, D-SL-6, §1.A.2/§1.A.3 notes, R-4 rewritten (both shapes named, falsifier order, rev B's mechanism reading recorded, honest no-shape-level contingency), §4.A pointer/offset.carbon `Load`/`Store` isolating lines; the `FromArray(4, &a)` contingency withdrawn |
| rev A A6 = rev B B8 (MINOR): `fail_copy`'s diagnostic is knowable now; a by-value parameter binding does not copy | folded: §4.A `fail_copy` pre-registers `CopyOfUncopyableType` + the `MissingImplInMemberAccessInContext` note (adapt_copy.carbon:27-35; convert.cpp:1794-1803, :2027-2033); §5.A.2 cites convert.cpp:2027-2038; §1.A.3 |
| rev A A7 (MINOR): two predictions name an in-class witness the design rejects | folded: §4.A `const_view`, §4.B `pass_and_return` → the out-of-class `@Slice.as.ImplicitAs.impl` |
| rev A A8 (MINOR): the 118/0/24-over-142 base rests on deltas with no source in this tree | folded: header and §8.3 cite the two decision-log entries (OV-1: 116/0/24 over 140 on branch claude/carbon-fork-0-1-overload, run 36451200115; UN-2: 116/0/25 over 141 on trunk 50839d68e, run 36447037687) and the OV-1 entry's post-merge reading 118/0/24 over 142; re-quoted from scoreboard.json at rebase |
| rev A A9 (MINOR): no precedent for a user `impl as Destroy` inside a GENERIC class | folded: §1.A.3 notes, §4.A `make_get_set` (the arbiter), R-12 (shape, falsifier, contingency) |
| rev A A10 (MINOR): citation fixes | folded in place: core/io.carbon:15; optional.carbon:110-115/:128-133, :103-108, :140, :145-146; min_prelude/parts/string.carbon:14-17; `IsCompTimeOnly` :919-985 (988-line file, `default` at :982); interop README.md:251-252's TODO replaced at SL-2 (§8.6); §0.2 item 1 records W-055's stale `gap-analysis.md:61` (row is :76) |
| rev B B1 (MAJOR): `Buf` + `UnformedInit` frees an uninitialized pointer; `Destroy` on `var` storage is unconditional (pattern_match.cpp:1727, control_flow.cpp:151-158) | folded: `UnformedInit` dropped from buf.carbon (§1.A.3); D-SL-6 states the toolchain fact with citations and files the residue title; the `unformed` positive → `fail_unformed` in fail_buf.carbon with the pre-registered `ConversionFailureTypeToFacet` (fail_generic_payload.carbon:37 shape); R-12 "decided at planning"; §1.A.6, §8.5 |
| rev B B2 (MAJOR): `heap.allocate`'s result type is the adapter CLASS `Core.MaybeUnformed(T*)` (maybe_unformed.carbon:13-15), so a bare `TryGetAs<MaybeUnformedType>` is nullopt; `arg_ids[0]` is the count | folded: §1.A.1 row 3 (`GetTransitiveAdaptedType`/`GetObjectRepr` in the type's file + `CARBON_CHECK` + `GetPointeeType` + `GetType`), hand-off |
| rev B B3 (MAJOR): a positive lower golden named `fail_stop.carbon` cannot pass `CompareFailPrefix` (file_test_base.cpp:126-135, :233-256) | folded: both goldens renamed `failstop.carbon` (§3, §4.A check + lower, R-1, §8.4); the prefix rule stated in §4 and the hand-off |
| rev B B4 (MAJOR): `RecognizedTypeInfo::PrintLiteral` (type_info.cpp:238-295) is a second exhaustive switch over `Kind` | folded: §0.1 row 11, §1.B.2, §2.B.4 (`case Slice: break;`), R-3, §8.4 grep expectation |
| rev B B5 (MINOR): the `fail_stop` IR prediction carried the message length as a literal | folded: §4.A failstop lower prediction (two globals, `load`, two `extractvalue`s, SSA `write` operands; string_indexing.carbon:27-28, :39-40) |
| rev B B6 (MINOR): the thunk spelling `.carbon_thunk._` "does not exist" | **folded in part, declined in part.** Folded: the CHECK-dump spelling is `Consume__carbon_thunk`/`Produce__carbon_thunk` (string_view.carbon:94-95, :103-104) — §4.B `pass_and_return`, R-8. Declined for the LOWER golden: the import-side thunk's IR name IS `<Itanium-mangled callee>.carbon_thunk._` — lower/testdata/interop/cpp/thunks.carbon:117/:122 `@_ZN9NeedThunkC1ERKS_.carbon_thunk._`, template.carbon:116 `@_Z8identityIiET_S0_.carbon_thunk._` — so it does contain `4span` and the mangled all-ones extent; the reviewer's `_CF__carbon_thunk.Main` (array.carbon:59/:90) is the EXPORT-direction thunk of a Carbon `F`, a different shape. §4.B lower span.carbon keeps rev 1's prediction with that evidence spelled out |
| rev B B7 (MINOR): §4's "positives never share a file with `fail_` subfiles" contradicts §4.A's own check goldens | folded: the rule is scoped to LOWER goldens (file_test_base.cpp:238-248; README.md:81-83); the three check files stay as written; hand-off |
| rev B B8 (MINOR) | see rev A A6 |
| rev B B9 (MINOR): a projection in the interface argument — name the deducible-parameter fallback | folded: R-9 mechanism paragraph (impl_lookup.cpp:245-290, deduce.cpp:462-480/:649-664) + the `[E: Copy & Destroy, C: CppContiguous where .Element = E]` contingency at falsifier (ii) |
| rev B B10 (MINOR): the raw_sem_ir contingency is moot | folded: §6.A(c) "zero raw goldens move" (the INCLUDE-FILE grep; the `--no-prelude-import` files), §8.1 stop tightened |
| rev B B11 (MINOR): export.cpp:960 prints "failed to map Carbon RETURN type to C++" | folded: §1.B.2, §4.B `fail_no_span_header` (parameter sites :894/:950; :504/:1747 named) |
| rev B B12 and rev A "checks that passed" (verified, no finding) | recorded, so the implementer does not re-open them: the builtin matchers and `IsValidBuiltinDeclaration`'s `()` substitution; exactly two switches enumerate `PointerUnsafeConvert`; the `CoreInterface` switches and x-macro `AsCoreIdentifier`; the R-1 block shape (`Branch`/`BranchIf`, `write` declaration); `--clang-arg=-std=c++20` reaching Clang with no `-std=` default; the libstdc++ 13 `span` layout and the `isAllOnes()` test; the import/export sites; the prelude precedents and the acyclic import graph; the §5 EXPECT re-derivations (2/3/30/32, 3/7/12/33, −6, 10/6, 2/2/18); SL-1/SL-2 hunk disjointness; R28/R7/R16 compliance and the unused `F-012` |

## Sign-off

**SIGNED OFF FOR IMPLEMENTATION, 2026-09-28 (rev 2).** Rev 2 folds the
two adversarial plan reviews (R29(c)). Neither review REJECTed, so no
focused re-review is required: the eight MAJORs are one-round folds
that reverse no decision's direction — D-SL-4 gains its correct
attribution and a residue title, D-SL-6 loses `Buf`'s `UnformedInit`,
D-SL-9's constraint is respelled — and every fold is tabled above with
the one partial decline and its evidence. Verification is hosted-only
per R28: the `Fork: hosted verification` workflow's compile, autoupdate,
gate and conformance modes (§8), never the self-hosted runner; goldens
come only from autoupdate (R16/R28(c)), and a workstream whose goldens
stay unfilled parks as an open PR with its dispatch list in
fork/ORCHESTRATION.md. Implementation proceeds SL-1 first (§3) on the
trunk of that day (50839d68e or later; absolutes re-quoted from
scoreboard.json at rebase, R9), SL-2 when SL-1's hosted verification is
green (UN-2 has already merged, §0.4). Later amendments are folded in
place, each marked "(amended <date>, review fold: ...)".

## Landed notes (SL-1, 2026-10-05)

SL-1 landed on claude/carbon-fork-0-1-slices: 2adc95742 (the four builtins
and their goldens), 2633b769e (slice.carbon, buf.carbon, types.carbon, the
`Iterate` impl, the prelude goldens), 55706e3eb (conformance + ledger),
0c88bddf5 (slices.md + the README amendment), then the fix rounds c200e6b81
(round 1), 24ef65c1c (round 2), ee434b2b3 (round 3), 7b69e540b and 713eddc7a
(round 4), with the hosted fills 50cd6c82c and 84315a5d4 between rounds 3
and 4. Ledger, gap-analysis row and decision-log entry ("SL-1: Core.Slice,
Core.Buf, heap allocation, fail-stop (2026-10-05)", the F-012 record with
D-SL-15..20) are the discharge commit. SL-2 is next (§0.4; it inherits the
`optional` import already in slice.carbon's header, the `final` impls, the
literal-subscript rule and W-108). Deltas from this plan, honestly:

-   **§6.A(a) "no existing golden moves" was wrong four times over.**
    Fifteen pre-existing goldens move: six because declared `Destroy`
    impls are now selected (round 2: lower var/param,
    var/destroy_control_flow, function/overload/basic `destroy_arg`,
    operators/question_generic `adapter_payload`; check
    var/destroy_control_flow, function/overload/basic); five for the
    `Iterate` import footprint (round 4(b): lower for/{for, bindings,
    break_continue}, array/iterate — one uncalled `declare` of
    iterate.carbon's synthesized `Destroy.Op` for the `i64 as Destroy`
    facet of the appended impl's rewrite, beside the `i32` twin the array
    impl already left there; check interop/cpp/range_for — two constants
    renumbered); two for the literal-subscript rule's `Core.Int` load
    (round 4(d): index/fail_non_tuple_access,
    operators/overloaded/index_with_prelude); and
    check/function/overload/basic.carbon a second time (its
    `union_scope_set` split took the round-3 regression's pins and is
    cleared, not restored); and a fifteenth the round-4 fixer did not
    predict, caught by the hosted fill a6cae2bab (on 713eddc7a):
    check/for/actual.carbon, 81/81 lines of pure name disambiguation
    (`%N` → `%N.fe9`, `%N.patt` → `%N.patt.aa5`, `%Iterate_where.type` →
    `.131`, `%Iterate.impl_witness` → `.195`, the `Optional.{Some,None}.
    specific_fn`, `IntLiteral...Convert.{bound,specific_fn}` and
    `%bound_method` suffixes, `%Core.import_ref.84b` → `.84ba`; every
    reference renamed; no instruction added or removed). Cause, read from
    the tree: its lib.carbon declares a local `impl as Core.Iterate`, so
    `ImportFinalImplsWithImplInFile` (impl_validation.cpp:473) imports
    every `final impl` of `Iterate` — since D-SL-18, the `Slice(T) as
    Iterate` impl — and that import's closure puts a second, unprinted
    `symbolic_binding N` into lib.carbon's constant namespace (NOT the
    impl's own `forall [T]`; the `N`-named bindings reachable through
    `Slice(T)` are `Slice.FromArray[N: IntLiteral]` and slice.carbon's
    file-scope `ArrayData[T, N]` — its fingerprint differs from the
    `N, 0` printed, so it is not `Int(N)`'s), beside a second `Iterate
    where ...` facet type and witness; the formatter suffixes the local
    ones. trivial.carbon, with no local `Iterate` impl, keeps `%N` bare.
    The 13 union/export goldens the round-3 fill
    broke are restored from ee434b2b3~3 and are byte-identical at HEAD
    (`git diff ee434b2b3~3 HEAD -- toolchain/check/testdata/union
    toolchain/lower/testdata/union` is empty). Lesson, recorded in the
    hand-off notes: a `grep 'as Destroy' core/` is not a prediction when
    the impl being added is in the result set and every prelude impl is in
    every file's import set.
-   **One diagnostic kind, not none.** §6.A's coverage bullet said "no
    diagnostic kind" until the re-review's finding 3;
    `IncompleteTypeInBuiltinCall` (kind.def:533) exists and is covered by
    the `fail_incomplete_pointee` splits of
    check/testdata/builtins/heap/allocate_free.carbon and
    builtins/pointer/offset.carbon, filled at run 37335213696.
-   **`IndexWith(i64)` only (D-SL-17), not rev 2's blanket `IndexWith(U:
    ImplicitAs(i64))`.** R-5's `Core.String` precedent was misapplied: its
    `At` is a call-site-lowered builtin, so a runtime `IntLiteral`
    parameter never exists there; `Slice.At`'s Carbon body would call a
    compile-time-only conversion on a runtime value. The literal-subscript
    rule in check/handle_index.cpp replaces the blanket impl for literals;
    an `i32` subscript is an error (`fail_subscript_i32`, W-116);
    `index_runtime_subscript` takes `i: i64`;
    slices_bounds_fail_stop.carbon reads `s[RuntimeSeed(-18) as i64]`.
-   **`final` on three prelude impls (D-SL-18).** `Slice(T)`/`Buf(T) as
    IndexWith(i64)` and `Slice(T) as Iterate` are `final impl forall`; §1.A
    wrote plain `impl forall`. A symbolic lookup resolves only final impls,
    so without `final` the `where .ElementType = T` rewrite is unknown in a
    generic body and `generic_element` (a positive) filled with a
    `ConversionFailure`. The §1.A.2/§1.A.3/§1.A.4 sketches are amended in
    place.
-   **The pointee-completeness hook (D-SL-15).** Neither §1.A.1 nor the
    hand-off notes anticipated that a pointer type is complete without its
    pointee: `fn A(n: i64) -> Core.MaybeUnformed(i32*) { return Alloc(i32,
    n); }` never completed `i32`, and lowering represented it as the unsized
    opaque struct. `RequireBuiltinCallPointeeComplete` (check/call.cpp)
    runs after `ConvertCallArgs` for every `Builtin` callee; the rev B B2
    unwrapping shape stands.
-   **Declared `Destroy` impls win destroy lookup (D-SL-16) and
    `HasUserDestroyImpl` is class-keyed (D-SL-19).** R-12 said the user
    impl inside a generic class was "the first in the tree" and gave a
    fill-time falsifier; the falsifier would have fired with certainty (no
    user `Destroy` impl was ever SELECTED — decision-log W-021 note), so
    R-12 was a planning miss of the rev B B1 class, caught by the
    implementation review instead. The round-2 fix then exposed the
    symbolic-self shortcut in the export/union predicate (round 4(a)).
-   **`heap.allocate` detects overflow (D-SL-20).** §1.A.1's arm multiplied
    without a check; `llvm.umul.with.overflow.i64`'s wrap bit joins the
    null-block path. lower/testdata/builtins/heap.carbon's comment predicts
    the shape; the IR is the fill's.
-   **Source anchors moved.** The lowering arms are handle_call.cpp:660
    (`PointerOffset`), :682 (`FailStop`), :719 (`HeapAllocate`), :790
    (`HeapFree`) and the runtime-fatal `default` is :812 (the plan's :649
    and :664); the x-macro entries are .def:154, :157, :160-161; eval's
    runtime-only arms are :2648-2651. Twelve toolchain source files, not the
    §2.A four: builtin_function_kind.{def,cpp}, eval.cpp, handle_call.cpp,
    call.cpp, custom_witness.{h,cpp}, handle_index.cpp, impl_lookup.cpp,
    name_lookup.{h,cpp}, kind.def.
-   **Spellings to working syntax (R3).** The §1.A sketches already used
    `[T: type]`; the only spelling deltas are the `final` modifiers above.
    check/slice/basic.carbon's `unformed` split keeps its `UnusedBinding`
    STDERR pin (the implementation review's MINOR 3; confirmed by the
    fill). `failstop.carbon`, not `fail_stop.carbon`, in both suites (rev B
    B3 held).
-   **Residue the slice added (filed at discharge, blocked_by []):** W-108
    the member-held `Buf` (filed as W-105 at the round-2 fix; renumbered
    because trunk's OV-2 discharge took W-105..W-107 — every citation on
    this branch now reads W-108); W-116 integer subscripts other than `i64`
    and literals (D-SL-17). The §8.5 titles are W-109..W-115 (write-through
    indexing, `buf(T)`, element destructors + `Allocator`, over-aligned
    elements, the index in the fail-stop message, unchecked access,
    unformed `Buf`). "array-value to slice conversion" is NOT filed (D-SL-2:
    only if upstream specifies it).
-   **Scoreboard base.** The branch's in-tree
    fork/conformance/out/scoreboard.json is 3c9df53f7 (generated
    2026-09-28T17:19:40Z): `totals.PASS = 118`, `totals.SKIP = 24`, every
    fail class 0, 142 programs listed, 46/56 bullets — the OV-1 entry's
    post-merge reading the header predicted. §5.A's delta (+3 PASS / −1
    SKIP / +2 programs; "Stdlib: Slices" SKIP → PASS) gives the expected
    121 / 0 / 23 over 144, 47/56. Trunk has since taken OV-2 (121 / 0 / 24
    over 145, 46/56), so the of-record numbers on the trunk merge are that
    base plus the same delta.

Reconciliation greps (§8.4), run at 713eddc7a:

-   `grep -rn '"pointer.offset"\|"fail_stop"\|"heap.allocate"\|"heap.free"'
    toolchain core` outside testdata: builtin_function_kind.cpp once each
    (:837, :844, :851, :856); the prelude declarations slice.carbon:19-20
    and buf.carbon:17-21; plus call.cpp:245 and :260 — the
    `RequireBuiltinCallPointeeComplete` names for the diagnostic, not
    anticipated by the grep's expectation and correct. The builtin goldens
    carry the rest.
-   `grep -rn 'Unsupported builtin call' toolchain/lower`: one hit,
    handle_call.cpp:812. As planned.
-   `grep -rln 'Slice' core/prelude`: buf.carbon, slice.carbon,
    iterate.carbon — and types.carbon through its `export import` line
    (`grep -rn` lists it). As planned.
-   `ls toolchain/*/testdata/builtins/ | grep fail_stop`: empty; the goldens
    are `failstop.carbon` in both suites (rev B B3).
-   `git diff ee434b2b3~3 HEAD -- toolchain/check/testdata/union
    toolchain/lower/testdata/union`: empty (round 4(a)'s falsifier).
-   `git diff 0bba39de2..HEAD --stat` over the testdata trees names exactly
    the fifteen pre-existing goldens listed above plus the new SL-1 files
    (fourteen at 713eddc7a; check/for/actual.carbon joined in a6cae2bab);
    no raw_sem_ir golden moved (§6.A(c)).
-   The one kind: kind.def:533, one `CARBON_DIAGNOSTIC` and one emit site
    (call.cpp:276-280), fired by the two `fail_incomplete_pointee` splits.
-   `runner.py --self-test`: "144 programs parsed, 56 bullets in table,
    OK" (the implementation review's run); the README table carries the
    three programs as `run`.
-   Ledger max id on this branch before discharge: W-105 (the round-2
    residue); trunk's max is W-107 (OV-2), so W-105 is renumbered W-108 and
    W-109..W-116 are allocated after it.

Hosted verification of record (R28(b); the container cannot build the
toolchain): first autoupdate run 37324972577 FAILED (the two incomplete-pointee
crashes; fix c200e6b81); second autoupdate run 37329946461 FAILED (the
comptime-only conversion in `Slice.At`; fix ee434b2b3); third autoupdate run
37335213696 success — fill 50cd6c82c (40 files where 18 were predicted) and the
convergence pass 84315a5d4 (`.loc`-only); fourth autoupdate, after 7b69e540b and
713eddc7a, run 37341482411 (and 37345524695 on the trunk merge, which changed
nothing); gate 37347712964 green; conformance 37347619141: 124 PASS / 0 FAIL /
23 SKIP over 147, 47/56 bullets, against the expected 121 / 0 / 23 over 144,
47/56.

## Landed notes (SL-2, 2026-10-05)

SL-2 landed on claude/carbon-fork-0-1-sl2 (off trunk 9e5dd5f75): 65338a7b7 (the
import and export mapping, five goldens), 17d506e2e (the synthesized
`CppContiguousRange`, the prelude interop library, three goldens), 677d0e4b2
(conformance + gap row + ledger), 12a2143d2 (slices.md's Interop section, the
interop README subsection), then the fix rounds fd9cdd5da (round 1) and
58c08be07 (round 2), with the hosted fills 0790c7428 + 2c21f6e24 (the run
37356848697 pair) and 18e2165c1 + 0c9924049 (runs 37362980320 and 37365683022)
between them. Ledger closure, the gap-analysis row and the decision-log entry
("SL-2: std::span ↔ Core.Slice mapping, owning-container views (2026-10-05)",
the second half of the F-012 record, D-SL-21..27) are the discharge commit; the
mid-stream "SL-2 round-1 note" stays in the log beneath it. Deltas from this
plan, honestly:

-   **§2.B.9's placement was right, was deviated from, and was restored at
    round 1.** The implementer put the whole interop section, blanket impl
    included, in a NEW library core/prelude/types/cpp/slice.carbon to keep
    `u64` (the rev A A2 constraint) out of slice.carbon without an import
    line that would move the SL-1 lower goldens' DI lines (§6.B, rev A A4).
    The blanket impl is an orphan there and unreachable by impl lookup
    (§2.B.9 amendment; D-SL-21), and the first hosted fill took every
    full-prelude golden down (306 files). The landed layout is the
    implementation review's zero-churn variant: the helpers stay in
    cpp/slice.carbon as PUBLIC Core names (the §1.B.3 sketch said `private`;
    `CppUnsafeDeref` is the public precedent), a new `interface CppSizeToI64`
    hides `u64` there (D-SL-23), slice.carbon's SL-1-reserved
    `prelude/types/optional` import line — unused there — became `import
    library "prelude/types/cpp/slice";` at the same line count (`class
    Slice` at :24, every method on its line), and the impl is appended beside
    `Slice` (slice.carbon:85-106). The lesson is a RULE now (D-SL-21 and the
    hand-off notes), where §2.B.9 had stated a placement without its reason.
-   **§1.B.3's constraint carries the bounds.** `require Self.(DataType) impls
    CppDataPointer & Destroy; require Self.(SizeType) impls CppSizeToI64 &
    Destroy;` where the sketch had `CppDataPointer` and `ImplicitAs(u64)`
    with no `Destroy`: the `Convert` body's `self.Data()`/`self.Size()`
    results are temporaries, and a synthesized witness supplies
    associated constants as bare `type`s (`BuildCustomWitness` TODOs on any
    other), so the bound cannot sit on the interface's `let`s (D-SL-22). The
    `Convert` body calls `.(CppSizeToI64.Op)()` for the two-step size
    conversion. §1.B.3's per-target reading of the size type (`u64` on Linux,
    `Core.CppCompat.ULong64` on macOS) STANDS: round 1 overwrote it with
    "`ULong64` on every 64-bit target" to explain an unfilled golden, the
    re-review refuted that from the target tables (`X86_64TargetInfo`
    `Int64Type = SignedLong`; long_and_long_long.{lp64,darwin,llp64}.carbon),
    and round 2 restored it everywhere (§1.B, §7 R-9, the hand-off notes).
-   **§1.B.1's `Span` arm gained two hardenings the plan did not have.**
    `SliceElementSatisfiesBound` tests the element against `Slice`'s own `T:
    Copy & Destroy` binding without diagnosing (`TryConvertToValueOfType`,
    bindings read with `GetOrEmpty`) and falls back to the class import —
    the plan's `PerformCall` converted WITH diagnostics, a header-site error
    for `std::span<NonCopyable>` (D-SL-24; `noncopyable_element_is_a_class`);
    an already-diagnosed element error is propagated rather than returned as
    `TypeExpr::None`, which would have imported the specialization as a
    class and diagnosed twice. A deleted C++ copy constructor does NOT fail
    the bound (`BuildCopyWitness` imports the deleted decl), so such a span
    maps to a `Core.Slice` whose element copies fail at the use site —
    disclosed in slices.md, W-056 and import.cpp, not filed.
-   **§1.B.3's witness builder declines `void` members.**
    `LookupCppMemberWithResultType` returns `None` for a `void` `data()`/
    `size()` and propagates an unmappable result type where the
    `CppRangeForIterate` precedent `CARBON_CHECK`s; reached from every
    `ImplicitAs(Slice(...))` conversion of a C++ class, that CHECK was an
    ICE (the implementation review's MAJOR 2; `fail_void_members`).
-   **§4.B spellings to working syntax (R3) and splits the reviews added.**
    `static_extent_is_a_class` names `std::span<int, 3>` through a header
    alias `IntSpan3` (the class/import/template.carbon `using Ai32 = A<int>`
    spelling), not `Cpp.std.span(i32, 3)` — no golden instantiates a C++ class
    template with a non-type argument from Carbon; the impls golden's mock
    `data()` members return `_Nonnull` pointers (the primitives min-prelude
    has no `Optional`), restore `unsigned long size()` with `.SizeType = u64`
    under the `--target=x86_64-linux-gnu` pin, and since round 3 wrap ONE
    `Test()` body — `missing_size`'s — in a `//@dump-sem-ir-begin/end`
    range (round 2 wrapped all three; the fill hung, below);
    span.carbon and fail_span.carbon carry the same `--target` pin (MINOR 6)
    and fail_span's header declares `ConsumeStatic` only (MINOR 5);
    span.carbon gains `noncopyable_element_is_a_class`, fail_vector_view
    .carbon gains `fail_void_members`, vector_view.carbon's splits are `view`
    and `nonnull_data`, and `fail_no_size` fills with `ConversionFailure`
    alone, as MINOR 9 said it would. The lower thunk is exactly the §4.B
    prediction — `@_Z7ConsumeNSt3__14spanIKiLm18446744073709551615EEE
    .carbon_thunk._`, `4span` and the all-ones extent in the mangling, the
    `Slice` storage address in, a by-value `span` load out, no `memcpy`
    between differently sized types. EIGHT golden files, not the "ten" the
    round records counted (`git diff --stat 9e5dd5f75..HEAD` over the two
    testdata trees: check stdlib/{span, fail_span, vector_view,
    fail_vector_view}, function/export/{slice, fail_export_slice},
    impls/cpp_contiguous_range; lower interop/cpp/span).
-   **§5.B.1 prints three values, not two.** `Core.Print(Cpp.SumSpan(v))` → `12`
    joins cpp_span_view (the implementation review's MINOR 7: the vector passed
    DIRECTLY to a `std::span<const int>` parameter is the argument-conversion
    shape, distinct from the `let`), so EXPECT is `10 6 12`; both programs pin
    the R-6 layout premise with `static_assert(sizeof (std::span<const int>) ==
    16)`. The D-SL-9 fallback (`cpp_span_view` SKIP with a refreshed reason, +1
    / 0 / +1, PARTIAL) was NOT taken: the chain resolved at the second fill, and
    37390640614 (on affa54e8a, which the final head differs from only by the
    scoreboard commit 2a17f0239 and the CHECK-only convergence commit)
    arbitrates it at runtime.
-   **§6.B held once the impl was where §2.B.9 put it.** The first fill's 306
    movers were the orphan, not churn; the second fill moved no pre-existing
    golden, and §6.B's round-1 hedge — that check/lower slice goldens might
    renumber constants under the wider `ImplicitAs` import footprint — did
    NOT fire (the impl's type structure `? as ImplicitAs(Slice(?))` is never a
    candidate for their queries). The convergence pass 0c9924049 renumbered
    two Clang-echoed source lines in `CHECK:STDERR` (fail_export_slice,
    fail_span), R26's shape.
-   **The silent golden was a reading error, not a crash.** impls/
    cpp_contiguous_range.carbon came back without CHECK lines from both fills.
    Root cause, read from the harness at round 2: the check component runs
    `--dump-sem-ir-ranges=only` (toolchain/testing/file_test.cpp
    `GetDefaultArgs`), the golden had no dump range and none of its three splits
    produced a diagnostic, so stdout and stderr were empty and the autoupdater
    had nothing to write — a clean PASS and positive evidence for `u64` (both
    runs: "Ran 1898 tests", no `<test>: <error>` line, no `Stack dump:`). The
    precedent cpp_range_for_iterate.carbon's positive splits are empty the same
    way. Round 2 added dump ranges around all three `Test()` bodies so the fill
    would show the witness; that fill (run 37367343836) HUNG in the file_test
    run — 32+ minutes against ~40 s for all 1898 tests the fill before, no
    `Stack dump:` — and was cancelled. Round 3 keeps the range on `missing_size`
    only (no witness is built there) and files W-121; the witness evidence is
    vector_view.carbon's `view` split, which dumps the same `custom_witness`
    cleanly. 37373875153 (fill 1d0c65f09) fills the one range.
-   **§7 outcomes.** R-6 not refuted at the IR level (the 16-byte thunk load;
    the runtime half is 37390640614 (on affa54e8a, which the final head differs
    from only by the scoreboard commit 2a17f0239 and the CHECK-only convergence
    commit)'s). R-7 not refuted: function/export/slice .carbon filled with
    `std::span<const int>` through the mock's inline `__1`. R-8 not refuted: no
    Clang diagnostic inside the synthesized thunk body. R-9: falsifier (ii)
    fired at the first fill for a reason the risk never listed (the orphan), (i)
    did NOT fire (the silent golden was a PASS), the chain resolved at the
    second fill; (iii), R-10 and R-11 have no golden (the real libc++
    `std::vector<int>` and `<span>` under `-std=c++20`) and are arbitrated by
    37390640614 (on affa54e8a, which the final head differs from only by the
    scoreboard commit 2a17f0239 and the CHECK-only convergence commit). Round 4:
    the first of-record conformance run (37378790657) did not refute R-10
    (`Cpp.std.vector(i32)` imported; the ICE was downstream, in the conversion
    lookup) or R-11 (`std::span<const int>` mapped -- the crash's `ClassType`
    IS the mapping), but failed both
    programs on two defects outside §7's list, recorded in the §6.A round-4
    amendment: the conversion lookup importing `span`'s range constructor, and
    the mixed constant/runtime array initializer never storing its constants.
-   **Round 5 (the round-4 re-review, APPROVE-WITH-FIXES; no hosted run
    between).** The round-4 golden pinned nothing: a parameter source is a
    C++ prvalue and the mock's `R&` range constructor could not bind it, so
    the fill b89020c8a showed the blanket impl with the gate never reached
    (its CHECK lines were the pre-gate output). The mock now takes `R&&` as
    the real header does, a `var_source` split carries the conformance
    program's lvalue category, and the gate keys on the importer's
    registered inst (`ClassDecl` or not) instead of the matcher, which had
    declined the constructors of `std::span<T>` specializations that import
    as ordinary classes (`NoCopySpan`); pinned by a
    `noncopyable_element_class_constructor` split (`VecLike<Carbon::NoCopy>`
    -> `Cpp.NoCopySpan`). The hand-off amendment above has the mechanism.
-   **§8.5 residue.** W-119 (static-extent `std::span` mapping) and W-120
    (ADL `data`/`size` sources) filed at the landing, blocked_by [], ids
    after OV-3's W-117/W-118 (confirmed against trunk 923c2f2af at
    discharge). "owning C++ container to Core.Slice view" is NOT filed (the
    D-SL-9 fallback did not fire). The deleted-copy element case is
    disclosed, not filed (`BuildCopyWitness`'s pre-existing policy).
-   **Scoreboard base.** The branch's in-tree fork/conformance/out/scoreboard
    .json is the SL-1 run of record (last written by e76b8052f, generated
    2026-10-05T17:37:12Z): `totals.PASS = 124`, `totals.SKIP = 23`, every fail
    class 0, 147 programs listed, 47/56 bullets. §5.B's delta (+2 PASS / −1 SKIP
    / +1 program; the contiguous-container bullet SKIP → PASS) gives the
    expected 126 / 0 / 22 over 148, 48/56. Trunk has since taken OV-3 (126 / 0 /
    23 over 149, 47/56), so the of-record numbers on the trunk merge are that
    base plus the same delta. Of record: run 37390640614 (on affa54e8a, which
    the final head differs from only by the scoreboard commit 2a17f0239 and the
    CHECK-only convergence commit), 128 PASS / 0 FAIL / 22 SKIP over 150
    programs, 48/56 bullets.

Reconciliation greps (§8.4), run at 58c08be07:

-   `grep -rn 'CppContiguousRange' toolchain core` outside testdata:
    core_interface_kind.def:22, core_identifier.def:37, impl_lookup.cpp:600
    (the builder's comment), :610 (`BuildCppContiguousRangeWitness`), :706-707
    (the `LookupCppImpl` case) — the "two sites" predicted, as two
    definitions — custom_witness.cpp:1546 (one), and TWO prelude files where
    §8.4 said slice.carbon alone: cpp/slice.carbon:17/:32/:73 (the round-1
    split) and slice.carbon:87 (the impl's comment). Three goldens name it
    (impls/cpp_contiguous_range, stdlib/vector_view, stdlib/fail_vector_view)
    where §8.4 said one.
-   `grep -rn 'CustomCppTypeMapping::Str' toolchain`: custom_type_mapping.cpp
    :128 and import.cpp:1322 — the two switch arms. As planned.
-   `grep -rn 'RecognizedTypeInfo::Slice' toolchain`: type_mapping.cpp:319
    once, plus type_info.cpp:151 (`ExpectsArgs`, qualified in its own file;
    counted under the next grep). As planned.
-   `grep -n 'Slice' toolchain/sem_ir/type_info.cpp`: :151, :192, :289 — the
    three lines (rev B B4). As planned.
-   `grep -rln 'Slice' core/prelude`: buf.carbon, cpp/slice.carbon,
    slice.carbon, iterate.carbon — cpp/slice.carbon joins SL-1's three
    through its comments (it names no `Slice` in code: D-SL-21).
-   `git grep -ln 'span\b' 9e5dd5f75 -- toolchain/check/testdata/interop`:
    empty — §6.B's premise that no pre-existing golden named a span held.
-   `git diff --stat 9e5dd5f75..HEAD -- toolchain/check/testdata toolchain/
    lower/testdata`: exactly the eight new files; no pre-existing golden
    moved (§6.B).
-   `ls toolchain/*/testdata/builtins/ | grep fail_stop`: empty (SL-1's rev B
    B3, unchanged).
-   `runner.py --self-test`: "148 programs parsed, 56 bullets in table, OK";
    the README table carries `cpp_span_view` as `run` and
    `cpp_span_roundtrip_diff` as `differential`.
-   Ledger max id on this branch: W-120; trunk's max is W-118 (OV-3's
    discharge), so W-119/W-120 stand and no id is renumbered.

Hosted verification of record (R28(b); the container cannot build the
toolchain): first autoupdate run 37356848697 — fill 0790c7428 (306 files: the
orphaned prelude impl) and its convergence pass 2c21f6e24 (40 files,
`.loc`-only); fix fd9cdd5da. Second autoupdate run 37362980320 — fill 18e2165c1
(the seven output-producing goldens, no pre-existing mover) and convergence run
37365683022, 0c9924049 (two `CHECK:STDERR` line numbers); fix 58c08be07 (records
and dump ranges; one `_Nonnull`, one `GetOrEmpty`). Third autoupdate, after
58c08be07: run 37367343836 HUNG and was cancelled (W-121); the round-3 fill, run
37373875153 (1d0c65f09), filled impls/cpp_contiguous_range.carbon's one range
and renumbered prelude `.loc`s in stdlib/vector_view.carbon (slice.carbon's
round-2 edit moved the blanket impl four lines). The merged head 76c695db4
converged with no changes (run 37376348469) and its gate 37378838866 passed; the
of-record conformance 37378790657 FAILED both new programs (round 4). Round-4
fill: run 37385761799 (b89020c8a); conformance 37387226286 (85f1c03f1) 128 / 0 /
22 over 150. Round-5 fill: run 37389055212 (affa54e8a, vector_view_span.carbon
only, as predicted). Gate 37395916761 (on 556a8669d; the first gate,
37390683098, failed only on the round-5 fill's own `.loc` renumbering inside
vector_view_span.carbon, the two-pass convergence of R26, and convergence run
37394549957 pushed 556a8669d, 130 `.loc` lines and nothing else); conformance
37390640614 (on affa54e8a, which the final head differs from only by the
scoreboard commit 2a17f0239 and the CHECK-only convergence commit): 128 PASS / 0
FAIL / 22 SKIP over 150 programs, 48/56 bullets, against the expected 128 / 0 /
22 over 150, 48/56 on the merged trunk base (126 / 0 / 22 over 148 on this
branch's own base).
