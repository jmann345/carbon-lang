<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Slices plan: `Core.Slice(T)` + heap allocation (SL-1, W-055) and `std::span` mapping (SL-2, W-056)

**Status:** DRAFT rev 1, 2026-09-28, awaiting the two adversarial plan
reviews (R29(c)); folds will be marked "(amended <date>, review fold:
...)" in place and listed in the fold record before Sign-off. Branch
`claude/carbon-fork-0-1-slices` off trunk 8e32108f8 (post-PR #43: UN-1
landed; the weekly cut holds a sixth week). **Base at rebase:**
fork/conformance/out/scoreboard.json on this trunk reads
`totals.PASS = 114`, `totals.SKIP = 25`, every fail class 0, so
`totals.PASS + totals.SKIP = 139` programs (generated
2026-09-27T12:30:10Z on the hosted-verification toolchain); the
gap-analysis header (fork/gap-analysis.md:18-20) agrees: 114 PASS / 0
FAIL / 25 SKIP over 139, 45/56 bullets, 27 DONE / 21 PARTIAL / 7 MISSING
/ 1 DESIGN-ONLY. OV-1 (+2 PASS / −1 SKIP / +1 total) and UN-2 (+2 PASS /
+2 total) land before this workstream, so the expected absolute base
when SL-1 rebases is **118 PASS / 0 FAIL / 24 SKIP over 142**; every count
below is stated as a DELTA and the absolutes are recomputed from the
scoreboard file at rebase time (R9 — the last two records were off by
one from mental arithmetic). All toolchain, core, docs and fork line
numbers are against 8e32108f8 and were re-verified for this plan; stale
ledger citations are corrected in §0.2. The container cannot build the
toolchain (clang 18 < 19), so every golden and diagnostic outcome is
pre-registered for the hosted autoupdate to confirm or refute (R28(b)).

**Items:** W-055 ("W9a: implement Core slice type and heap allocation",
size L, subsystem core/prelude + check support) and W-056 ("W9b:
transparent std::span / contiguous-container view mapping", size M,
blocked_by W-055). **Design authority:** there is no fork design-sprint
page for slices (`ls fork/design-sprint`: error-handling,
function-overloading, if-let, reading-list, structural-conformance,
threading-atomics, unions) and no decision-log entry mentions slices,
heap allocation or `std::span` (`grep -in 'slice\|heap\|span'
fork/decision-log.md` hits only choice-work "slice" in the PR sense), so
this plan establishes what UPSTREAM's design says (§0.3, D-SL-1..14) and
applies R29(a) where it is silent, never contradicting its direction
(V-3). The upstream sources, each cited where used: docs/design/README.md
:872-916 ("Arrays and buffers": `array(T, N)` = `Core.Array(T, N)`,
`buf(T)` = `Core.Buf(T)` "heap-allocated dynamically sized array";
"Slices": `> **TODO:** Slices`, :912-914); docs/design/expressions/
indexing.md (the `IndexWith`/`IndirectIndexWith` rewrite rules and the
`class Span(T: type) { impl as IndirectIndexWith(like i64) ... }` example,
:61-63, :116-121); docs/design/values.md:1125-1131 (pointers "cannot be
indexed or have pointer arithmetic performed on them ... Slice or view
style types are expected to provide access to indexable regions ... raw
pointer arithmetic ... through specialized constructs"); docs/design/
safety/README.md:218-232 ("bounds checking is enabled in the release
build"; detectable bugs get "[fail-stop] behavior") with terminology.md
:98-102 (fail-stop = "immediately terminating the program"); docs/design/
classes.md:1849-1875 (the `Allocator` interface with `Delete`/
`UnsafeDelete` over `Deletable`/`Destructible` facets, none of which the
toolchain has); docs/project/milestones.md:69 ("heap allocation" as an
example library component), :201-214 (the 0.1 stdlib list: "Slices";
"Transparent mapping between Carbon and C++ _non-owning_ contiguous
container types — Includes starting from an owning container and forming
the non-owning view and then transparently mapping that between
languages"); proposals/p004682:310-332 (the owning-buffer vocabulary
table: `Core.Buf(T)` is the "Indirect, Mutable Size" row; "Carbon does
not have proposed names for heap-allocated storage, so we use some
placeholders"); proposals/p002274:44-51 (a slice "refers to some region
of an array ... such as `std::string_view` or `std::span`") and :258-272
(read-only subscripting is an open problem). The prelude's closest
existing view type is `core/prelude/types/string.carbon:16-25`
(`class String { private var ptr: Char*; private var size: i64; }`) with
its indexing done by the builtin `"string.at"` (:31-33).

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
| 8 | Generic prelude classes over a pointer field, unformed pointers, `unsafe as` | LANDED | optional.carbon:188-203 (`final impl forall [T: type] T* as OptionalStorage where .Type = MaybeUnformed(T*)`, `result unsafe as T* = self;` :194, `return value unsafe as T*;` :201, `PointerIsNull` :181, `MakeUninitializedOptionalPointer(generic T: type) -> MaybeUnformed(T*)` :183-184); `me.value unsafe as T = self;` (:162) is the precedent for assigning through a symbolic-`T` reference; range.carbon:13-33 (`class IntRange(N: IntLiteral)` with an in-class `impl as Iterate`) |
| 9 | `Iterate` over arrays | LANDED | iterate.carbon:20-32 (`impl forall [T: Copy & Destroy, N: IntLiteral] array(T, N) as Iterate where .ElementType = T and .CursorType = i32`); the C++ range path :33-82 |
| 10 | Import mapping of a C++ std type onto a Carbon prelude type | LANDED for `std::string_view` ↔ `str` only | check/cpp/custom_type_mapping.cpp:93-99 (`StdStringView` matcher: `basic_string_view<char, char_traits<char>>` in `std`), :102-109 (`GetCustomCppTypeMapping` → `CustomCppTypeMapping::Str`), header :13-19 (a payload-less enum); consumed by import.cpp:1262-1274 (`LookupCustomRecordType` → `MakeStringType`), registered as the tag's inst by `MapTagType` :1277-1300 so the C++ class is never imported as a class. Golden check/testdata/interop/cpp/stdlib/string_view.carbon (a MOCK `std::basic_string_view` with `const CharT* data_; size_t size_;` — layout identity is the premise) |
| 11 | Export mapping of a Carbon prelude type onto a C++ std type | LANDED for `str`, `Optional(T*)`, `Result(T, E)` | sem_ir/type_info.h:351-388 `RecognizedTypeInfo::Kind` (…, `Optional`, `Result`, `Str`), type_info.cpp:148-151 `ExpectsArgs`, :165-196 (Core-root class recognized BY NAME through a `StringSwitch`); consumed by the EXHAUSTIVE `switch (type_info.kind)` in check/cpp/type_mapping.cpp:196-330 (`Optional` :267-285 unwraps `Optional(T*)` to `T*` through `WrappedType`, `Result` :286-318 instantiates `Carbon::expected` by way of `LookupCppClassTemplate` + `CheckTemplateIdType`, `Str` :319-321 `LookupCppType({"std", "string_view"})`); the other consumers are comparisons, not switches (lower/type.cpp:587, lower/handle.cpp:301, export.cpp:1040, handle_function.cpp:388) |
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
    found in W-009's citation).
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
6.  **gap-analysis row 74 "String is a 33-line non-owning {Char*, u64}"**
    — string.carbon:23-25 declares `size: i64` (the `u64` is the
    min_prelude PART, toolchain/testing/testdata/min_prelude/parts/
    string.carbon:11-13). Corrected in the row text at discharge (the
    `String`/`Slice` layout twin-ship matters for D-SL-8).
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
    `Optional` already impose (iterate.carbon:20, optional.carbon:134);
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
-   **D-SL-4 — a bounds violation is a fail-stop: one line on stderr,
    then `abort()`; unconditional in 0.1 (no build modes).**
    safety/README.md:218-221 ("bounds checking is enabled in the release
    build") and :229-232 (detectable bugs "have [fail-stop] behavior and
    provide detailed diagnostics"), terminology.md:98-102. The toolchain
    has no build-mode notion (README.md:379-385 is design text only), so
    the check is always on. Mechanism: the prelude tests `i < 0 or i >=
    self.size` in Carbon and calls the `fail_stop` builtin (D-SL-5),
    which lowers as `write(2, message.ptr, message.size)` (the exact
    `write` declaration of lower/handle.cpp:349-350, so both sites share
    one module-level declaration) followed by a call to `abort` marked
    `noreturn`. No `unreachable` is emitted after the call: the checker
    still emits the branch to the merge block after the `if` body, and a
    terminator mid-block would be invalid IR — a `noreturn` call followed
    by dead code is valid and the optimizer folds it (R-1 falsifier
    below). The message names the operation, not the index (no integer
    formatting at this level; `printf` from a generic prelude body is not
    available): `carbon: Core.Slice index out of bounds; terminating`,
    `carbon: Core.Slice.Subslice range out of bounds; terminating`,
    `carbon: Core.Buf index out of bounds; terminating`, `carbon: Core.Buf
    size is negative; terminating`, `carbon: heap allocation failed;
    terminating`. Exit is SIGABRT (6). Break condition: build modes land
    (the check becomes mode-gated) or a `CARBON_DIAGNOSTIC`-style runtime
    diagnostics facility exists (message gains the index).
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
-   **D-SL-6 — heap allocation is the owning class `Core.Buf(T: Copy &
    Destroy)` (`{ptr: T*, size: i64}`) over libc `malloc`/`free`:
    `Make(size: i64, fill: T)`, `Size(self)`, `Get(self, i)`, `Set(self,
    i, value)`, `AsSlice(self)`, `impl as Destroy` frees; not `Copy`; no
    `buf(T)` keyword; no `Allocator` interface; element destructors are
    NOT run.** README.md:887-889 names `Core.Buf(T)` (with `buf(T)` as
    the shorthand) as THE heap-allocated dynamically sized array —
    p004682:316-322 calls the name a placeholder, but it is the only
    heap-storage spelling upstream's design text carries, so V-3 says use
    it. The `buf` shorthand would be a lexer/parser change for a
    placeholder name: residue. classes.md:1849-1875's `Allocator` needs
    `Deletable`/`Destructible` facets the toolchain lacks: residue,
    mechanism named. Every element is initialized from `fill` (no
    unformed elements escape: `MaybeUnformed` never leaves `Make`), the
    fill loop assigns through `*PointerOffset(ptr, i) = fill` (the
    optional.carbon:162 assignment shape). `Set(self, ...)` takes `self`
    by value on purpose: the storage is the heap block the pointer names,
    so no `ref self` is needed, and D-SL-3's const hazard does not arise
    (heap memory is writable; `Buf(const T)` is legal but pointless).
    Element destructors: `Buf(T)`'s `Destroy` frees the block without
    running `T`'s destructor per element, mirroring what
    `Optional(T)`/`MaybeUnformed(T)` already do (maybe_unformed.carbon
    :12-16 adapts a builtin that the destroy walk treats as trivial,
    custom_witness.cpp:277-281, :641-645) — there is no precedent for an
    explicit `Destroy.Op` call in Carbon source (`grep -rn 'Destroy.Op)()'
    toolchain/check/testdata core` is empty). Residue with the break
    condition "explicit destroy calls or `TrivialDestructor` facets land
    (generics/details.md:4190-4192)". `Buf` has no `Copy` impl, so
    copying is a compile error, never a double free; it has `UnformedInit`
    so `var b: Core.Buf(i32);` type-checks like `String` (string.carbon
    :28) — an unformed `Buf` is never destroyed with a garbage pointer
    because `Destroy` on unformed variables is not run (the design's
    unformed-state rule; the same holds for every prelude type today).
    Over-aligned `T` (alignment > `max_align_t`) is residue (`malloc`
    only guarantees 16). Break condition: an upstream proposal names the
    heap types — rename; an `Allocator` design lands — `Buf` gains an
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
    and whose `Size` converts through `As(i64)` (`size_t` maps to `u64`
    where `uint64_t` is `unsigned long`, else to `Core.CppCompat.ULong64`;
    both have `As(Int(64))`, uint.carbon:97 and cpp/int.carbon). This is
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
| `HeapAllocate` | `"heap.allocate"` | `auto(AnySizedInt)->MaybeUnformed<PointerTo<AnyType>>` (the `generic T: type` parameter is not a runtime parameter and is not validated — the `MakeUninitializedOptionalPointer(generic T: type) -> MaybeUnformed(T*) = "make_uninitialized"` precedent validates `auto()->AnyType`) | `elem_type` from the RESULT type (`MaybeUnformedType.inner_id` → `PointerType.pointee_id` → `GetType`); `bytes = mul(sext_or_trunc(count, i64), i64 getTypeAllocSize(elem_type))`; `bytes = select(icmp eq bytes 0, i64 1, bytes)` (a zero-length or zero-sized request still yields a unique non-null block — `malloc(0)` may return null); `malloc = getOrInsertFunction("malloc", ptr, i64)`; result `CreateCall(malloc, {bytes})` | runtime-only |
| `HeapFree` | `"heap.free"` | `auto(PointerTo<AnyType>)->NoReturn` | `free = getOrInsertFunction("free", void, ptr)`; `CreateCall(free, {p})` | runtime-only |

`IsCompTimeOnly` (:919-1010) needs no change (default `false`). Every
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

impl forall [T: Copy & Destroy, U: ImplicitAs(i64)]
    Slice(T) as IndexWith(U) where .ElementType = T {
  fn At(self, subscript: U) -> T { return self.Get(subscript.Convert()); }
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
literal for `Core.String` (io.carbon:9 `fn PrintStr(msg: str)`), so the
`FailStop` declaration needs `prelude/types/string` only for the literal
argument's class to be complete. `self.ptr as const T*` is as.carbon
:57-59 (`T* as As(const T*)`); `.size = N` converts the symbolic
`IntLiteral` `N` to `i64` through int.carbon:31-33 inside a generic body
exactly as iterate.carbon:25 compares `*cursor < N`. `subscript.Convert()`
on a `U: ImplicitAs(i64)` value is optional.carbon:79-83's shape.
Returning `*PointerOffset(...)` (a durable reference of symbolic type
`T`) from a `-> T` function copies through `Copy` as optional.carbon
:170-172 (`return value.value unsafe as T;`) does. `i < 0` and `end >
self.size` are `Int(N) as OrderedWith(T: ImplicitAs(Int(N)))`
(int.carbon:113) and the `Int(N) as OrderedWith(Int(M))` (:98) impls.
The private fields are readable only from the class's own methods and
in-class impls (string.carbon:19-25 is the shape), so every
out-of-class impl reaches the data through the public API only:
`IndexWith` through `Get`, `ImplicitAs(Slice(const T))` through
`Data()`/`Size()`/`UnsafeMake` — the optional.carbon:74-76 shape of an
out-of-class impl building the class through its public constructor
(`Optional(T).Some(self)`). The in-class alternative (`impl as
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

impl forall [T: Copy & Destroy] Buf(T) as UnformedInit {}

impl forall [T: Copy & Destroy, U: ImplicitAs(i64)]
    Buf(T) as IndexWith(U) where .ElementType = T {
  fn At(self, subscript: U) -> T { return self.Get(subscript.Convert()); }
}
```

Precedents: `HeapAllocate(T, size)` with an explicit `generic` type
argument is optional.carbon:183-184/:192-193
(`MakeUninitializedOptionalPointer(T)`); `storage unsafe as T*` is :201;
`PointerIsNull` :181/:198; the fill assignment through a symbolic-`T`
reference is :162; the in-class `impl as Destroy { fn Op(ref self) ... }`
is lower/testdata/var/param.carbon:17-21 (a user class); redeclaring a
builtin in a second prelude file is default.carbon:52-54 versus
optional.carbon:137-138 (`"make_uninitialized"` twice). The `Buf` class
has no `Copy` impl, so `var c: Buf(i32) = b;` diagnoses at the copy
(pinned, §4.A `fail_copy`).

#### §1.A.4 `Iterate` for slices (appended to core/prelude/iterate.carbon after :82)

```carbon
impl forall [T: Copy & Destroy]
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
element types; `Buf.Resize`/`Push` (the design's "Mutable Size" is the
STORAGE class, not an API promise, p004682:316); array-value → slice
conversion (D-SL-2); comptime evaluation of slice reads (all four
builtins are runtime-only; a constant `Core.Slice` never forms because
`&a` of a local is not constant).

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
    (export.cpp:894, :950; return :960) — no new diagnostic kind, one
    pinned golden (`fail_no_span_header`). `std::span<const int>` needs
    `const i32` to map: `ConstType` is already an arm of `TryMapType`
    (string_view's `const CharT*` return types round-trip today).
-   The `Kind` switch is the ONLY exhaustive switch over
    `RecognizedTypeInfo::Kind` (§0.1 row 11); every comparison site keeps
    working.

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
      require Self.(SizeType) impls As(i64);
      alias Element = Self.(DataType).(CppDataPointer.Element);
    }

    impl forall [C: CppContiguous where .Element impls Copy & Destroy]
        C as ImplicitAs(Slice(C.Element)) {
      fn Convert(self) -> Slice(C.Element) {
        return Slice(C.Element).UnsafeMake(
            self.Data().(CppDataPointer.Raw)(),
            self.Size().(As(i64).Convert)());
      }
    }
    ```

    Shapes: the constraint with `extend require impls`, `require
    Self.(X) impls Y` and an `alias` projection is iterate.carbon:57-64
    (`CppRange`); the blanket impl with a `where .X impls` bound and a
    projection in the target interface is :66-82 (`T as Iterate where
    .ElementType = T.ValueType`); the explicit `.(Interface.Method)()`
    call is :78 (`cursor->0.(CppUnsafeDeref.Op)()`). slice.carbon then
    also imports `prelude/types/optional` (acyclic: optional.carbon
    :7-14 imports no `types/slice`). For a `std::vector<int>` `v`:
    `Data()` is `data() const` (the const filter, impl_lookup.cpp
    :403-416) → `Optional(const i32*)` → `Element = const i32`;
    `Size()` is `size() const` → `u64` (Linux) or
    `Core.CppCompat.ULong64` (macOS), both `As(i64)`; the result is
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
    `.Case("Slice", Slice)`.
5.  **toolchain/check/cpp/type_mapping.cpp:** the `Slice` arm (§1.B.2).
6.  **toolchain/sem_ir/core_interface_kind.def:** `CppContiguousRange`.
7.  **toolchain/check/cpp/impl_lookup.cpp:** `BuildCppContiguousRange
    Witness` + the `LookupCppImpl` case (§1.B.3).
8.  **toolchain/check/custom_witness.cpp:** :1487-1500 list gains the
    kind (it answers nullopt like `CppRangeForIterate`).
9.  **core/prelude/types/slice.carbon:** the interop section (§1.B.3)
    plus `import library "prelude/types/optional";`.
10. **Goldens:** §4.B. **Conformance:** §5.B. **Docs:** interop README
    paragraph + slices.md status line (§8.6).

## §3 Commit structure

**SL-1 (PR "SL-1: Core.Slice, Core.Buf and the runtime bounds
fail-stop"), four commits:**

1.  sem_ir + eval + lower: the four builtins (§2.A.1-4) + their builtin
    goldens (check/testdata/builtins/{pointer/offset, fail_stop,
    heap/allocate_free}.carbon; lower/testdata/builtins/{pointer_offset,
    fail_stop, heap}.carbon), CHECK-free. Run the hosted `compile` probe
    on this commit alone (R-3 hand-off).
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

Rules baked in from the recent landings: every golden ships with
`// AUTOUPDATE` and EMPTY CHECK lines; positives never share a file with
`fail_` subfiles (one erroring subfile blanks the lower golden of a
split file, and a check dump of a file with errors is a different
artifact); a `fail_` subfile's predicted diagnostic names the KIND and
the message so the fill is a confirm/refute, not a discovery; identifiers
never collide with the words.md:47-104 keyword list (`base`, `default`,
`destroy`, `like`, `runtime`, `then`, `union` are the traps — none is
used below); `//@dump-sem-ir-begin/end` brackets every positive so the
prelude is excluded from the dump.

### §4.A SL-1

-   **check/testdata/builtins/pointer/offset.carbon** (`min_prelude/int
    .carbon`; the pointer/is_null.carbon shape with user-declared
    builtins): `fn Offset[T: type](p: T*, n: i64) -> T* =
    "pointer.offset";` and `fn F(p: i32*) -> i32* { return Offset(p, 1);
    }`. Predicted: a `%Offset.specific_fn` call in `@F` with `%p` and the
    `int_1` constant converted to `i64`; no diagnostics.
    Subfiles `fail_mismatched_pointee` (`fn Bad[T: type, U: type](p: T*,
    n: i64) -> U* = "pointer.offset";`) and `fail_non_pointer` (`fn
    Bad(p: i64, n: i64) -> i64 = "pointer.offset";`): predicted
    `InvalidBuiltinSignature` "invalid signature for builtin function
    \"pointer.offset\"" (handle_function.cpp:862-865) at each `fn`.
-   **check/testdata/builtins/fail_stop.carbon** (`min_prelude/full
    .carbon` — `str` needs `Core.String`): `fn Stop(message: str) =
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
        constant), the `IndexWith` impl witness for
        `Slice(i32) as IndexWith(Core.IntLiteral)` selected for the
        `IntLiteral` subscript, and an `At` call producing a value of
        type `%i32` (not a reference). No diagnostics.
    -   `index_runtime_subscript`: `fn G(s: Core.Slice(i32), i: i32) ->
        i32 { return s[i]; }` — predicted the same impl with `U = i32`
        (the `i32 → i64` widening bound satisfied by int.carbon:62-68).
    -   `subslice_and_size`: `fn H(s: Core.Slice(i32)) -> i64 { return
        s.Subslice(1, 3).Size(); }` — predicted two method calls, no
        diagnostics.
    -   `const_view`: `fn K(s: Core.Slice(i32)) -> Core.Slice(const i32)
        { return s; }` — predicted the in-class `ImplicitAs(Slice(const
        i32))` witness call.
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
    `@Buf.as.Destroy.impl(%i32)` — a `destroy` dump line; `as_slice`
    (`fn S(b: Core.Buf(i32)) -> Core.Slice(i32) { return b.AsSlice(); }`);
    `unformed` (`var b: Core.Buf(i32);`).
    **check/testdata/slice/fail_buf.carbon:** `fail_copy` (`fn C(b:
    Core.Buf(i32)) { var c: Core.Buf(i32) = b; }`) — predicted the
    copy-witness failure the checker emits today for initializing a
    variable from a value of a class with no `Copy` impl (the kind and
    message are the ones `grep -rn 'cannot copy\|CopyValue' toolchain/
    check/convert.cpp` names at implementation time; the pre-registered
    prediction is that an error IS emitted at the `= b` and that no
    `PrimitiveCopy`/memcpy appears — a clean compile is the falsifier).
-   **lower/testdata/builtins/pointer_offset.carbon** (`min_prelude/int
    .carbon`; user-declared builtin as in lower/testdata/builtins/pointer
    .carbon:13-15): `fn F(p: i32*, n: i64) -> i32* { return Offset(p, n);
    }` — predicted IR: `%ptr.offset = getelementptr inbounds i32, ptr %p,
    i64 %n` and `ret ptr %ptr.offset`.
-   **lower/testdata/builtins/fail_stop.carbon** (`full.carbon`): `fn
    F() { Stop("boom\n"); }` — predicted: a private global string
    constant for the literal, a `String` value materialized, `call i64
    @write(i32 2, ptr <ptr>, i64 5)`, `call void @abort()`, then the
    ordinary `ret void` (D-SL-4: no `unreachable`); declarations
    `declare i64 @write(i32, ptr, i64)` and `declare void @abort()` with
    the `noreturn` attribute in an `attributes #N` group. This golden is
    the R-1 falsifier (an IR verifier failure means the block shape is
    wrong).
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
        in-class `ImplicitAs(Slice(const i32))` witness, the call names
        the thunk (`.carbon_thunk._` suffix as string_view.carbon's
        `Consume` golden); `G` returns the `Core.Slice(i32)` specific
        with the out-pointer thunk form. No diagnostics, no imported
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
    (export.cpp:894/:950) at the reference — loud, no new kind.
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
-   **check/testdata/interop/cpp/stdlib/vector_view.carbon** (`full
    .carbon`; mock `class VectorLike { public: const int* data() const;
    int* data(); std::size_t size() const; };` with `using size_t =
    __SIZE_TYPE__` in `std`): `fn View(v: Cpp.VectorLike) ->
    Core.Slice(const i32) { return v; }` — predicted the blanket
    `ImplicitAs` witness over the synthesized `CppContiguousRange`
    witness (a `custom_witness` constant naming `data`/`size` function
    decls) and the `As(i64)` conversion of the `u64` size; no
    diagnostics. **fail_no_size** (own file): `class NoSize { public:
    int* data(); };` → `ConversionFailure` "cannot implicitly convert
    expression of type `Cpp.NoSize` to `Core.Slice(i32)`".
-   **lower/testdata/interop/cpp/span.carbon** (`full.carbon`, the mock
    header): twin of `pass_and_return` — predicted: a thunk definition
    whose mangled name contains `4span` and the all-ones extent
    `18446744073709551615` with the `.carbon_thunk._` suffix, taking `ptr`
    (the `Slice` storage address) and calling the real `Consume` with a
    by-value `span` load; for `Produce`, the out-pointer thunk writing 16
    bytes into the Carbon return slot. No `memcpy` between differently
    sized types (the layout premise's IR-level check).

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
2.  **stdlib/slices_heap_buf.carbon (new, bullet "Stdlib: Slices").**
    Heap storage viewed and mutated through the slice API:

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

    EXPECT-STDOUT: `3` (size), `7` (the fill value), `12` (10 + 2 after
    `Fill` writes 10, 11, 12), `33` (10 + 11 + 12). Four lines. `b` is
    passed by value to `Fill` without a copy (value bindings of a
    non-`Copy` class are references — README.md:1301-1303 — and `Set`
    writes through the shared heap block; the program's third line is
    the proof). `Destroy` frees at `Run`'s exit; a leak is not
    observable, a double free would abort — exit 0 is the check.
    `i as i32` is `Int(64) as As(Int(32))` (int.carbon:70).
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
    `Sum` needs `<span>` in the TU: it is included.

Zero landed programs move (no landed program includes `<span>` or names
`Slice`). Bullet row 79: 2/2 PASS → DONE, or 1/2 with one SKIP → PARTIAL
(D-SL-9 fallback; the fold record states which).

## §6 Churn inventory (verified by grep at 8e32108f8)

### §6.A SL-1

-   **Existing goldens that move: none predicted.** (a) Check dumps
    exclude the prelude (`//@dump-sem-ir` ranges) and SemIR names are
    symbolic, so two NEW prelude files and two `export import` lines
    change no existing check golden — the try.carbon precedent (commit
    6b0b80e, fork/eh/plan.md:1138-1142). (b) The EH-A lesson (:1199-1215):
    a prelude edit that shifts lines ABOVE a method that lowered code
    references moves every lower golden's `DILocation`s for that method.
    SL-1's only edits to EXISTING prelude files are types.carbon (no
    functions) and an APPEND to iterate.carbon after its last line
    (:82), so no existing method moves; `grep -rn 'Iterate.Core\|
    IntRange' toolchain/lower/testdata` lists the goldens that would
    have moved (array/iterate, for/*, interop/cpp/range_for-adjacent) and
    they are predicted byte-identical. (c) The eight raw_sem_ir goldens
    (`grep -rl 'dump-raw-sem-ir\|raw_sem_ir' toolchain/*/testdata`) do
    not import the prelude's `types` library beyond what they use; if
    one prints an `import_ir` index table, adding two prelude libraries
    could renumber it — the fill decides; a moved raw golden is
    reconciled, not a stop (its diff must be index-only).
-   **Builtin tables:** `CARBON_DEFINE_ENUM_CLASS_NAMES` and
    `ForBuiltinName` are generated; no golden prints the enum.
-   **min_prelude parts:** unchanged (no test combines a part with
    `Slice`).
-   **Diagnostics coverage test** (toolchain/diagnostics/coverage_test
    .cpp, `TEST(Coverage, Kind)` :82): SL-1 adds NO diagnostic kind, so
    nothing to cover. **Parse coverage test:** no parse change.
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
-   **min_prelude parts:** none (parts/iterate.carbon does not carry the
    interop section; the vector_view golden uses `full.carbon`).
-   **Interop README:** one dated paragraph; docs prek only.
-   **Diagnostics coverage:** no new kind (D-SL-8's failure path reuses
    `SemanticsTodo`).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — the `fail_stop` lowering produces invalid IR.** The arm
    emits `call @abort()` (noreturn) and NO terminator, relying on the
    checker's own branch/return after the `if` body. Falsifier: the
    hosted `compile` probe or `lower/testdata/builtins/fail_stop.carbon`
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
    `RecognizedTypeInfo::Kind` in type_mapping.cpp's switch (compile
    error). No new `SemIR::Inst` kind, so check/import.cpp
    `GetImportName`, import_ref.cpp's resolver and
    sem_ir/type_iterator.cpp's runtime-fatal `default` are not in play —
    a reviewer who finds an inst kind in the diff has found a plan
    violation. Falsifier: the hosted `compile` probe (commit 1 of each
    PR) red on `-Wswitch`, or a lower golden's fill printing the fatal.
-   **R-4 — the symbolic-`T` prelude bodies fail definition checking.**
    Specific shapes at risk: `*PointerOffset(self.ptr, i) = fill` (a
    store through a symbolic-`T` reference — precedent optional.carbon
    :162), `return *PointerOffset(...)` (copy of a symbolic `T` from a
    reference — precedent :170-172), `.size = N` inside a generic method
    (IntLiteral → i64, precedent iterate.carbon:25), deduction of `[N:
    IntLiteral]` through `array(T, N)*` (pointer-then-array deduction —
    precedents `T* as Copy` and `array(T, N) as Iterate` separately, not
    combined). Falsifier: the prelude's own compile (hosted `compile`
    probe, commit 2) diagnosing inside slice.carbon/buf.carbon.
    Contingency for the deduction: `FromArray` takes `(generic N:
    IntLiteral, p: array(T, N)*)` explicitly (the
    `MakeUninitializedOptionalPointer(T)` explicit-generic shape) and the
    conformance spelling becomes `FromArray(4, &a)` — disclosed in the
    fold, never silent.
-   **R-5 — the `IndexWith(U)` blanket impl over `U: ImplicitAs(i64)`
    is ambiguous or unmatched for `IntLiteral` subscripts.** Precedent:
    string.carbon:31-33 has the identical shape and `msg[i]` /
    `"abc"[0]` work (io.impl.carbon:10). Falsifier: `from_array_index`
    diagnosing "no impl of `Core.IndexWith(Core.IntLiteral)`" or an
    ambiguity. Contingency: a second concrete impl for `IntLiteral`
    (the int.carbon:31/:42 pair pattern).
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
-   **R-8 — the thunk's `.carbon_thunk._` for a `std::span` parameter
    needs the span to be copy-constructible from the pointer-passed
    object.** It is (trivially copyable). Falsifier: Clang diagnostics
    inside the synthesized thunk body in span.carbon's fill.
-   **R-9 — the D-SL-9 owning→view chain (five steps: member lookup
    with the const filter → witness → `CppDataPointer` selection on
    `Optional(const i32*)` → `As(i64)` on `u64`/`ULong64` → blanket
    `ImplicitAs(Slice(C.Element))` with a projection in the interface
    argument).** Precedents per step are cited in §1.B.3; the untested
    composition is the risk. Falsifiers, in order: (i)
    `member_data_size` failing `AssertIsContiguous` (witness not built);
    (ii) `vector_view.carbon` diagnosing "no impl of
    `Core.ImplicitAs(Core.Slice(const i32))`" (the constraint or the
    projection); (iii) `cpp_span_view` COMPILE-FAIL on the real
    `std::vector<int>` (real-header member overload sets: libc++'s
    `data()` has exactly two overloads, `size()` one — but `size()` on
    libc++ is `size() const noexcept`; if `LookupCppMethod` reports
    "overload sets unsupported" the filter did not reduce to one).
    Contingency (loud, D-SL-9): the PR lands without commit 2; the
    program stays SKIP with the refreshed reason; the bullet is PARTIAL;
    residue "owning C++ container to Core.Slice view" carries the
    refuting run id and the last step reached.
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
-   **R-12 — Buf's `Destroy` runs on an unformed `var b: Core.Buf(i32);`
    and frees garbage.** The design's unformed rule: destroy is skipped
    for unformed variables. Falsifier: `check/testdata/slice/buf.carbon`
    `unformed` dump showing a destroy call on `%b.var`, or a crash in a
    conformance program declaring an unformed `Buf` (none does in 0.1 —
    add one only if the dump is clean). Contingency: drop the
    `UnformedInit` impl for `Buf` (then `var b: Buf(i32);` is a
    compile-time `DefaultOrUnformed` failure — loud).
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
    NEW files only (§6) plus, at most, index-only diffs in a raw_sem_ir
    golden (§6.A(c)). Any other pre-existing golden in the diff is a
    stop.
2.  **Gate:** mode `gate` green (prek + `bazel test //toolchain/...`;
    clang-format 21.1.8 per R18; `uvx prek run --files <changed>` locally
    before every push, R25). The diagnostics coverage test and the parse
    coverage test are part of the gate (no new kinds, so no new
    coverage obligations — a reviewer should still diff kind.def).
3.  **Conformance:** mode `conformance`; deltas per §5 (SL-1 +3 PASS /
    −1 SKIP / +2 total; SL-2 +2 / −1 / +1, or +1 / 0 / +1 under the
    D-SL-9 fallback) on whatever base trunk has at rebase time — on the
    expected post-OV-1/post-UN-2 base 118/0/24 over 142 that is 121/0/23
    over 144 after SL-1 and 123/0/22 over 145 after SL-2 (recompute from
    scoreboard.json, never by hand: R9). `runner.py --self-test` and
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
    `grep -rn 'RecognizedTypeInfo::Slice' toolchain` hits type_info.cpp
    and type_mapping.cpp.
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
        "array-value to slice conversion" (D-SL-2, only if upstream
        specifies it — otherwise not filed); "static-extent `std::span`
        mapping" (D-SL-8); "owning C++ container to Core.Slice view" —
        ONLY if the D-SL-9 fallback fires; "ADL `data`/`size` sources
        for `CppContiguousRange`" (§1.B.3).
6.  **Docs (D-SL-13):** at SL-1, new docs/design/slices.md with the
    status paragraph "fork amendment 2026-09-28 (F-012): `Core.Slice(T)`
    and `Core.Buf(T)` as implemented; toolchain status: SL-1 landed
    <date>; interop mapping at SL-2", sections: Overview (view semantics,
    explicit formation from `&a`, D-SL-2), the API (§1.A.2/§1.A.3
    signatures), Bounds behavior (D-SL-4 with the safety citations),
    Heap buffers (D-SL-6 with the p004682 placeholder-name note),
    Iteration, Interop (filled at SL-2: D-SL-8/9/10, the
    `std::span<const int>` ↔ `Core.Slice(const i32)` rule, the
    `-std=c++20` note), "0.1 limits" (every residue title with its break
    condition), Alternatives considered (the §7 rejected list),
    References (README.md arrays section, indexing.md, values.md,
    safety README, p002274, p004682, milestones.md). README.md:912-914
    becomes a three-sentence summary + link, marked "(fork amendment
    2026-09-28, F-012)"; README.md:887-889's `buf(T)` sentence gains a
    parenthetical "(the fork implements `Core.Buf(T)` without the
    shorthand, see Slices)". At SL-2, docs/design/interoperability/
    README.md's container-mapping placeholder (if one exists — `grep -n
    'span\|contiguous' docs/design/interoperability/README.md` at rebase)
    gets the dated paragraph; otherwise the paragraph goes under the
    existing string-view mapping text.
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
-   `heap.allocate`'s element type comes from the RESULT type
    (`MaybeUnformed(T*)`), not from an argument; the count is sign-
    extended to `i64` before the multiply; the zero guard is a `select`.
-   Out-of-class impls (`IndexWith`, `ImplicitAs(Slice(const T))`, the
    §1.B.3 interop impl) touch public API only (`Data`, `Size`, `Get`,
    `UnsafeMake`); `Buf.AsSlice` uses `UnsafeMake`. If you reach for a
    private field from outside its class, stop.
-   slice.carbon must not import `prelude/iterate` (cycle); the `Iterate`
    impl is APPENDED to iterate.carbon — do not insert it mid-file (DI
    churn in eight lower goldens, fork/eh/plan.md:1199-1215).
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
    positives and `fail_` subfiles never share a file; hand-derived
    EXPECT values only (R16(d)).

## Review fold record

Rev 1: none yet. The two adversarial reviews' findings and their folds
will be tabled here before Sign-off, coordinator [R29(a)] rulings
marked.

## Sign-off

Pending the two adversarial plan reviews (R29(c)). On sign-off,
implementation proceeds SL-1 first (§3) on the trunk of that day, SL-2
when SL-1's hosted verification is green and UN-2 has merged (§0.4).
Later amendments are folded in place, each marked "(amended <date>,
review fold: ...)".
