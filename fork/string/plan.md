<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# String plan: byte-wise comparison, the owning `Core.StringBuf` and concatenation (ST-1, W-057)

**Status:** rev 3, 2026-10-13 -- SIGNED OFF FOR IMPLEMENTATION. Rev 3 folds
the focused re-review of rev 2 (APPROVE-WITH-AMENDMENTS: both of rev A's
BLOCKERs verified RESOLVED, one new MAJOR and three new MINOR findings), each
amended sentence or row marked "(amended 2026-10-13, review fold: RR-N-1)"
through "RR-N-4" and tabled in the
[Review fold record (rev 3)](#review-fold-record-rev-3-2026-10-13); none is
rejected, and the three reviews are listed in the [Sign-off](#sign-off). Rev 3
changes no measured text: §2.1 to §2.4 are byte-identical to rev 2's, so every
measurement below stands, and it adds one measurement, M-25. Rev 2 (381f79b92)
folded the two plan reviews of R29(c) (rev A: design soundness and toolchain
correctness, REJECT with 2 BLOCKER, 2 MAJOR and 7 MINOR findings; rev B:
APPROVE-WITH-AMENDMENTS with 5 MAJOR and 7 MINOR), each amended sentence or row
marked "(amended 2026-10-13, review fold: A-n)" or "(... review fold: Bn)" and
tabled in the [Review fold record](#review-fold-record-rev-2-2026-10-13); none
was rejected. Because rev A REJECTed, rev 2 went to that focused re-review (the
fork/w012/plan.md and fork/upstream/plan.md precedent). Rev 1 was the
planner's draft (bff5ba4e8). Nothing below is implemented. Branch
`claude/carbon-fork-0-1-st`, cut from trunk 80a11e7f0, whose toolchain, core and
docs sources are identical to 0bdce60a5 (the only later trunk commits are
fork/ORCHESTRATION.md stamps). Every line number below is against 80a11e7f0 and
was re-read for this plan. Every measured outcome in §0.2 was taken in this
container with the trunk build (`/home/user/carbon-build/carbon-trunk`, `carbon
version` 0.0.0-0.dev+0bdce60a5) and its file_test, with the prelude of §2.1
applied to a COPY of the install tree in a scratch directory; since rev 2 also
with a file_test and a `carbon-busybox` RELINKED from the trunk build's objects
and one recompiled object, export.cpp with §2.2 applied (M-19), so the two
goldens rev 1 could only predict are measured (amended 2026-10-13, review fold:
A-1). Nothing was built with Bazel, nothing was installed, no worktree was
modified, and the owner's runner was not used (R28).

**Since rev 3 (2026-10-13):** implemented by 84ff63560 (§3 commit 2),
16a87052f (commit 3) and d8d10bf70 (commit 4). The two implementation reviews
(both APPROVE-WITH-FIXES, 15 MINOR findings in all) are folded by a fix commit
that changes no code, golden or program and records each finding in the
[Implementation review fold
record](#implementation-review-fold-record-2026-10-13); its in-place
amendments to this plan are marked "(amended 2026-10-13, implementation review
fold: RV1-n)" or "(... ST1-IR2-n)", and the two §4 key lines it corrects
"(amended at landing ...)". The discharge, §3 commit 5, is next.

**Item:** W-057 ("W9c: string equality, concatenation, and owning variant", size
M, subsystem core/prelude, bullet "Stdlib: String and string-literal types").
**Milestone row:** fork/gap-analysis.md:77, PARTIAL. The row moves to :78, :80
and :81 on the CM-1, SAFE-1 and SC-1 branches, so records refer to it by its
bullet text (R7) and re-read its line at rebase. **Criterion:** the bullet text,
docs/project/milestones.md:202 "String and related types used with string
literals" (under "Types with important language support", :201). **Outcome this
plan commits to:** row 77 PARTIAL → DONE, expected and not of record until a
conformance run of record, with the 0.1 limits filed as W-160..W-167 (W-160 and
W-167 under "Type system: User-defined types (classes)", whose row stays DONE
with its access-control phrase amended for W-167 (§2.6; amended 2026-10-13,
review fold: RR-N-3), and W-166 under SAFE-1's loan checker W-148) and UA-2's
W-126 named, under the precedent of row 82 (DONE with filed limits W-119/W-120)
and distinguished from row 79's PARTIAL by D-ST-16 (amended 2026-10-13, review
fold: A-4 / B3). The bullet's PASS rollup does not move (it already rolls up
PASS with one SKIP), so the bullet count stays 48/56.

**Id allocation (recorded so no workstream collides):** the ledger maximum
across trunk and every live branch was W-150 (SAFE-1, PR 53) when rev 1 was
written; W-151 is reserved for SC-1's W-144 renumber, and is on the SC-1
branch's ledger since 2f4ebbf6e (re-read for rev 2: trunk W-125, safe W-150, sc
W-151, cmake W-133, ua2 W-127, ev W-125; re-read for rev 3, unchanged, with
no id at or above W-152 on any branch, and the reservation is trunk
9d3ca60a3's fork/ORCHESTRATION.md:69-75); W-152..W-159 are reserved for the
concurrent EV-1 workstream
(fork/evaluator/plan.md on claude/carbon-fork-0-1-ev); ST-1's residues start at
W-160 and this plan uses W-160..W-167 (amended 2026-10-13, review fold: A-1,
A-2, A-3). Fork design ids run F-006..F-013 (F-012 is SL-1/SL-2, F-013 is
SAFE-1, held in PR 53); ST-1 mints **F-014** (D-ST-1). No id is ever reused: at
discharge the residues are allocated from max(trunk, every live
`claude/carbon-fork-0-1-*` branch) + 1, skipping W-151 and W-152..W-159; if any
of W-160..W-167 is taken by then, they are re-allocated and the plan's landed
notes say so (amended 2026-10-13, review fold: B8).

**Design authority** (each cited where used):

-   docs/design/README.md:622-634 "String types": "**Note:** This is
    provisional, no design for string types has been through the proposal
    process yet." Two types, `String` ("a byte sequence treated as containing
    UTF-8 encoded text") and `StringView` ("a read-only reference to a byte
    sequence"), with "an implicit conversion from `String` to `StringView`"
    (:633-634). String literals, :645-678, are unchanged by this plan.
-   proposals/p006177-c-interop-mapping-std-string-view-to-core-str.md
    (accepted): "Carbon's `Core.Str` is, per [leads issue 5969], the language's
    fundamental non-owning view of a sequence of bytes" (:59-61); "both
    `Core.Str` and `std::string_view` are fundamentally views over bytes, not
    Unicode characters" (:125-126); "The choice of `Str` over `String` for the
    non-owning view type is intentional. It avoids confusion with owning types
    like C++'s `std::string`" (:147-154). The prelude class that `str` names is
    still called `String` (string.carbon:16), as upstream's nightly 2026.10.12
    and upstream-trunk 62f1cc6a3 also have it.
-   docs/design/expressions/arithmetic.md:184-188 ("### Strings" at :184, the
    TODO paragraph at :186-188): "**TODO:** Decide whether strings are built-in
    types, and whether they support `+` for concatenation" (issue 457).
    Undecided upstream (amended 2026-10-13, review fold: A-7).
-   docs/design/expressions/comparison_operators.md:251-271 (`EqWith`, `x == y`
    calls `x.(EqWith(U).Equal)(y)`), :288-290 ("The `EqWith` overload is
    selected without considering possible implicit conversions"), :347-390
    (`OrderedWith`), :436-472 (transitivity, reversal consistency, `EqWith`
    refining `OrderedWith`).
-   docs/design/values.md:168 (:176 once SAFE-1's eight-line insertion at :137
    lands): "**Open question:** The lifetimes of temporaries is not yet
    specified." The fork decides it in F-013 D-SAFE-12 (held in PR 53, which
    merges first, fork/ORCHESTRATION.md:66-67; on its branch
    docs/design/safety/temporal_safety.md:1116-1120): "A loan on a temporary
    lives until the end of the full-expression; a later use is
    `StrictBorrowOfTemporary`; `var` is the fix". ST-1 adopts that rule for
    `str` views (D-ST-6) and treats today's longer toolchain lifetime (M-7) as
    behavior, not design (amended 2026-10-13, review fold: A-11 / B1).
-   fork/gap-analysis.md:241-244, the W9 **Arbiter**: "an approved-design
    Optional and String with comparison/ownership story" (D-ST-16; amended
    2026-10-13, review fold: B3).
-   docs/design/assignment.md:176-184: `x = y;` is rewritten to
    `x.(AssignWith(U).Op)(y);` (the toolchain does not do this, §0.1 row 9).
-   docs/design/classes.md:2156-2159 "Access control for construction": "A
    function may construct a class, by casting a struct value to the class type,
    if it has access to (write) all of its fields."
-   docs/project/milestones.md:202 (the bullet) and :207-208 (C++ interop is
    required for NON-owning string types only).

V-3: no accepted proposal or leads' direction is contradicted. Comparison
semantics follow p006177's "views over bytes" (:125-126); the owning type's
existence follows README.md:627-634; its name and `+` concatenation are fork
fills where upstream is provisional or silent, recorded as F-014 for
after-the-fact veto (R29(a)).

## §0 Audit: what exists, what was measured, what is stale

### §0.1 Sub-feature table (verified in-tree at 80a11e7f0)

| # | Element | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `str` and `Core.String` | LANDED, view only | The `str` keyword resolves through `LookupNameInCore(context, loc_id, CoreIdentifier::String)` (check/literal.cpp:229-233; check/core_identifier.def:86). core/prelude/types/string.carbon is 32 lines (`wc -l`; the brief and gap row 77 say 33): `class String` :16-26 with `Size(self) -> i64` :17, an in-class bitwise `impl as Copy` :19-21, `private var ptr: Char*` :23 and `private var size: i64` :25; `impl String as UnformedInit {}` :28; `impl forall [T: ImplicitAs(i64)] String as IndexWith(T) where .ElementType = Char { fn At(self, subscript: T) -> Char = "string.at"; }` :30-32. No `EqWith`, `OrderedWith`, `AddWith`, no owning type. |
| 2 | `"string.at"` | LANDED, unchecked | kind.def:36 `StringAt`; signature `(CoreStringType, AnyType) -> CoreCharType` (sem_ir/builtin_function_kind.cpp:422-425); `CoreStringType` accepts any class NAMED `String` (:199-212). Compile-time evaluation with `StringAtIndexNegative`/`StringAtIndexOutOfBounds` (check/eval.cpp:2517-2570). Lowering loads `{ptr, size}`, emits `getelementptr inbounds i8` with the RAW subscript operand, loads and zero-extends (lower/handle_call.cpp:422-448): no run-time bounds check, and the operand is whatever `T` the blanket impl received (M-6). |
| 3 | The view class's name is load-bearing | LANDED | Three toolchain sites key on the class name `String`: literal.cpp:232 (the `str` keyword), builtin_function_kind.cpp:209 (`"string.at"`'s matcher), sem_ir/type_info.cpp:193 (`.Case("String", Str)`, which drives the `std::string_view` export mapping, check/cpp/type_mapping.cpp:360-362). Import: check/cpp/custom_type_mapping.cpp:96, :127. |
| 4 | `Char` | LANDED | `class Char { adapt u8; }` (core/prelude/types/char.carbon:16-18); `impl Char as EqWith(Char)` with `"int.eq"`/`"int.neq"` (:49-52) and `OrderedWith(Char)` with `"int.less"` and friends (:54-59), so `Char` orders as its unsigned `u8` representation; blanket `impl forall [T: ImplicitAs(Char)] Char as EqWith(T)` whose impl function takes `other: Char`, not `T` (:61-64), and the reversed blankets (:73-83). That parameter spelling is the precedent of D-ST-9. |
| 5 | Operator interfaces | LANDED | core/prelude/operators/comparison.carbon:12-17 `interface EqWith(Other: type) { fn Equal(self, other: Other) -> bool; default fn NotEqual(...) }`, `constraint Eq` :19-21, `interface OrderedWith(Other: type)` with four required functions and no `Compare` (:24-32, TODO :25), `constraint Ordered` :34-36; operators/arithmetic.carbon:24-27 `interface AddWith(Other: type) { let Result: type; fn Op(self, other: Other) -> Result; }` (no default `Result`, unlike the design's arithmetic.md:229-232) and :30-32 `interface AddAssignWith(Other: type) { fn Op(ref self, other: Other); }`. The impl spelling every prelude file uses defines `NotEqual` explicitly (int.carbon:93-96, char.carbon:49-52, cpp/int.carbon:341-345) and writes `where .Result = X` on `AddWith` (int.carbon:141, char.carbon:92-93). |
| 6 | Heap storage (SL-1) | LANDED | core/prelude/types/buf.carbon:17-23: private wrappers `PointerOffset` (`"pointer.offset"`), `FailStop` (`"fail_stop"`), `HeapAllocate(generic T: type, count: i64) -> MaybeUnformed(T*)` (`"heap.allocate"`), `HeapFree` (`"heap.free"`), `PointerIsNull` (`"pointer.is_null"`); `class Buf(T: Copy & Destroy)` :26-64 with `Make` :28-43 (negative-size and null-block fail-stops), `Size`, `Get`, `Set`, `AsSlice` and the in-class `impl as Destroy { fn Op(ref self) { HeapFree(self.ptr); } }` :58-60; no `Copy`, no `UnformedInit` (:66-67); `final impl ... Buf(T) as IndexWith(i64)` :72-75. Builtins: kind.def:154-161, kind.cpp:836-856, runtime-only (eval.cpp:2597-2600). `"heap.allocate"` turns a zero-byte request into a one-byte block (lower/handle_call.cpp:769-775) and an overflowing count into null (:759-786). A declared `Destroy` impl is selected over the synthesized witness (D-SL-16). |
| 7 | A prelude class owning a heap pointer with a declared `Destroy` | LANDED, one instance | `Core.Buf` is the only one (`grep -rn 'impl as Destroy' core/` hits buf.carbon:58 alone). Field destruction on this trunk: a `Buf` field of a class WITHOUT a declared `Destroy` is freed by the enclosing type's synthesized `SubobjectDestroy` (upstream's, since the UA-1 advance; UA-2 discharges W-108 on its fill), and a class that DECLARES `Destroy` does not destroy its fields (W-126, filed on the UA-2 branch, not yet on trunk) (M-8). |
| 8 | Owning-to-view and C++ | PARTIAL | `str` maps to and from `std::string_view` (row 81, DONE). No owning string anywhere, so no `std::string` mapping. A non-generic `Core` class reaching a C++ call argument crashes the compiler: `ExportClassToCpp` passes the null scope from `ExportNameScopeToCpp` (which has just diagnosed "interop with non-identifier package name", check/cpp/export.cpp:139-142) into `ExportClassToCppInDeclContext` (:294-297), the one caller of `ExportNameScopeToCpp` without a null check (the others: :429-432, :781-784, :1864-1867). Upstream-trunk 62f1cc6a3 has the same unchecked call. No prelude class has reached it before (M-9). |
| 9 | Assignment | LANDED, no destroy | check/handle_operator.cpp:96-130: `=` does not use `AssignWith` (TODO :98-103) and "TODO: Destroy the old value before reinitializing" (:119-120): `InitializeExisting` over the old object. For an owning type the overwritten block leaks (M-5). |
| 10 | Orphan rule | LANDED | check/impl_validation.cpp:153-240 `DiagnoseOrphanImpl`: an impl must be in a library that owns the interface or a class in the self type or the interface's ARGUMENTS; a rewrite `.Result = X` does not count (measured, M-18). |
| 11 | min_prelude | LANDED, separate | toolchain/testing/testdata/min_prelude/parts/string.carbon: `class String { private var ptr: u8*; private var size: u64; }`, no impls, exported by primitives.carbon:24. Goldens that include min_prelude/full.carbon (`--expect-full-prelude`; 315 files, `grep -rl 'INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon' toolchain \| wc -l`; amended 2026-10-13, review fold: A-10) load the INSTALL tree's core/ instead; min_prelude goldens never see core/prelude (M-10). |
| 12 | Conformance | 1 PASS, 1 SKIP | fork/conformance/programs/stdlib/string_basic.carbon PASS (its header :14-15 still says `{Char*, u64}` and "`.Size()` returns u64"; its "Caution" :21-26 documents the literal-subscript crash). stdlib/string_missing_ops.carbon: SKIP :6, `EXPECT-EXIT: 0` :7, `EXPECT-STDOUT` 1 and 4 (:8-10), body :20-29. |
| 13 | Upstream | NONE | The nightly 2026.10.12 string.carbon is byte-identical to trunk's (`diff` empty); upstream-trunk 62f1cc6a3 touches string.carbon only in 7134e23f2 (docs). Upstream has no string comparison, concatenation or owning string. |

### §0.2 Measurements

Setup, all under the planner's scratch directory (`$S` below is
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/st1`):
`install-copy` is `cp -a` of `/home/user/carbon-build/carbon-trunk/install`,
whose `lib/carbon/core/prelude/types/string.carbon` was replaced by successive
prototypes, the last being exactly §2.1 ("v5"); `runfiles-v3` is a runfiles tree
whose `carbon/toolchain/install/*` entries symlink `install-copy/lib/carbon/*`
(file_test resolves the install root through `RUNFILES_DIR`, the carbonbuild
README's runfiles section); `bin/run.sh` compiles with
`--output-last-input-only` (R2), links and runs one program. Each prelude
version got a fresh `XDG_CACHE_HOME`, because the runtimes cache that holds the
compiled prelude object is keyed by `install_digest.txt`
(toolchain/driver/runtimes_cache.cpp:179-185), which the copy leaves unchanged.
The copy is a faithful model of an ST-1 build for everything but export.cpp: the
runtimes prelude list `CarbonCorePreludeSrcs` is compiled into the binary
(toolchain/driver/carbon_runtimes.cpp:64-70), and ST-1 adds no prelude FILE
(D-ST-10), so the trunk binary compiles every file ST-1 changes.

```
T=/home/user/carbon-build/carbon-trunk
cp -a $T/install $S/install-copy
cp $S/proto/string.v5.carbon $S/install-copy/lib/carbon/core/prelude/types/string.carbon
$S/bin/run.sh $S/install-copy $S/cache-v5 <program.carbon>
cd /home/user/carbon-st && RUNFILES_DIR=$S/runfiles-v3 TEST_TMPDIR=$S/ft-tmp \
  $T/bin/file_test --print_slowest_tests=0 < /dev/null
cd /home/user/carbon-st && XDG_CACHE_HOME=$S/cache-v5 python3 fork/conformance/runner.py \
  --toolchain $S/install-copy/lib/carbon/carbon-busybox --programs <dir> --out <out>
```

-   **M-1 (the SKIP program on trunk).** `carbon compile --phase=check
    string_missing_ops.carbon` with the trunk install prints exactly the two
    errors its header quotes: `` 24:17: error: cannot access member of interface
    `Core.EqWith(str)` in type `str` that does not implement that interface ``
    and `` 26:16: error: cannot access member of interface `Core.AddWith(str)`
    in type `str` that does not implement that interface ``, exit 1. The
    upstream nightly prints the same two.
-   **M-2 (the prototype prelude is accepted).** With §2.1 in the copy, every
    prelude file check-compiles (no diagnostic from core/), and
    string_missing_ops.carbon, unmodified, compiles, links and prints `1` and
    `4`, exit 0.
-   **M-3 (operators).** A probe over literals, mixed operands and appends
    printed `1 0 1 1 1 1 0 1 1 0 1 Carbon 6 1 1 1 abcCarbon xyxyxyxyxy 10 20
    Carbon! Carbon 0 1`, each line as hand-predicted before the run: equality of
    two 3-byte strings that differ in their last byte is 0, `"ab" < "abc"` is 1,
    `"abc" < "ab"` is 0, `"\xFF" > "a"` is 1 (bytes compare unsigned), `"Car" +
    "bon"` is `Carbon` with size 6, `"a" + "b" + "c" + s` is `abcCarbon`, five
    `acc += "xy"` give 10 bytes and `acc += acc` gives 20, an explicit copy
    `Core.StringBuf.Make(s)` gains `!` while `s` stays `Carbon`.
-   **M-4 (allocation balance).** An `LD_PRELOAD` shim counting `malloc` and
    non-null `free` (built with `/home/user/llvm/bin/clang -shared`, scratch
    only) on the prototype: a `Core.Print`-only baseline shows 1 `malloc`
    (stdio's buffer) and 0 `free`; the M-3 probe 14 and 13 (13 string blocks,
    all freed); a lifetime probe (`Make`, a `let` view of a `+` temporary, a
    chained `+`, three `+=`, a `returned var` built in a callee and then
    appended to, a `StringBuf` field of a class without a declared `Destroy`) 11
    and 10; 1000 loop iterations of `var t: Core.StringBuf = piece + piece +
    piece;` 2001 and 2000; 20 doublings of two strings plus 10000 one-byte
    appends 10044 and 10043. No leak and no double free in any program that
    avoids `=` (M-5).
-   **M-5 (assignment leaks).** `var s = Make("a"); s = s + "b"; s = Make("q");`
    plus a class with its own `impl as Destroy` holding a `StringBuf` field: 5
    `malloc`, 1 `free`. Both overwritten blocks and the field leak (§0.1 rows 7
    and 9).
-   **M-6 (subscripts on trunk).** `s[0]` on a runtime `str` aborts the compiler
    in lowering, "GEP indexes must be integers / `getelementptr inbounds i8, ptr
    %string.ptr, {} zeroinitializer`", on the trunk install and on the nightly.
    `s[i]` with `i: u8 = 200` on a 201-byte string printed byte 0x01 instead of
    `X`: the 8-bit GEP index is sign-extended, so the read lands 56 bytes before
    the string. With D-ST-9 the same programs print `C` and `X`.
-   **M-7 (temporary lifetimes).** A class `D` whose `Destroy` prints its
    negated id: the temporary of `let v: V = D.Make(10);` (converted by
    `ImplicitAs`) is destroyed at the end of the enclosing block, not at the end
    of the statement; an expression-statement temporary
    (`Core.Print(Use(D.Make(20)))`) is destroyed at the end of its statement;
    temporaries of a `var` initializer in a loop body are destroyed at the end
    of each iteration (`0 -10 1 -11`); `returned var` is destroyed once, by the
    caller; `x = D.Make(31)` never destroys the old value 30. The lower golden
    of §4 shows the same placement for `StringBuf` (`Chain`'s intermediate
    temporary is destroyed just before `s` at the end of the function). This
    is toolchain behavior, not design: F-013 D-SAFE-12 ends a loan on a
    temporary at the full-expression, and SAFE-1's EX-TM-7b outcome text says
    the opposite of this measurement (temporal_safety.md:831-840 on its
    branch: the temporary `Buf` "is destroyed at the end of the
    full-expression, so `v[0]` reads freed memory"); re-measured for rev 2
    with that exact line, `let v: Core.Slice(i32) =
    Core.Buf(i32).Make(4, 7).AsSlice();` followed by `Make(4, 9)`, on the
    trunk install: `v[0]` prints 7, and the tracking shim of §8.8 reports 3
    `malloc` and 2 `free`, both blocks freed at the end of the block. §2.6
    reconciles the two pages (amended 2026-10-13, review fold: A-11 / B1).
-   **M-8 (fields).** In M-4, the `StringBuf` field of a plain class was freed
    with the object; in M-5, the field of a class that declares `Destroy` was
    not.
-   **M-9 (the C++ boundary).** `Cpp.ViewSize(s)` with `s: Core.StringBuf` and
    `ViewSize(std::string_view)` aborts the compiler: after "semantics TODO:
    `interop with non-identifier package name`" at the `class StringBuf` line,
    the assertion "`isa<> used on a null pointer`" fires in
    `ExportClassToCppInDeclContext` called from `ExportClassToCpp`
    (`MapToCppType` → `InventClangArg`). A user class `MyStr` with
    `ImplicitAs(str)` passed the same way gets the ordinary "no matching
    function for call to 'ViewSize'" with "no known conversion from 'const
    Carbon::MyStr' to 'std::string_view'": C++ overload resolution does not see
    Carbon conversions. A generic `Core.Buf(i32)` argument gets the clean "call
    argument of type `Core.Buf(...)` is not supported" (the parameterized path
    already checks for null). `Cpp.ViewSize(s.AsStr())` prints 5, `Cpp.Hello()
    == s` prints 1 and `Cpp.Hello() + "!" == "hello!"` prints 1. The §2.2 fix
    was syntax-checked on a scratch copy of export.cpp: `syn/check_one.sh
    $S/cpp/export.cpp /home/user/carbon-st` → `OK (10.5s)` under the toolchain's
    `-Werror` flag set, and clang-format 21.1.8
    (`/home/user/llvm/bin/clang-format`, the R18 pin) leaves it unchanged.
    Since rev 2 it is also compiled with the trunk build's own flags and
    linked into file_test and `carbon-busybox` (M-19), and the relinked
    file_test turns `Cpp.Consume(b)` with `b: Core.StringBuf` into the
    diagnostics of §1.6 instead of the crash (M-10, M-11; amended 2026-10-13,
    review fold: A-1).
-   **M-10 (golden blast radius).** file_test in test mode over the whole
    manifest, read-only from /home/user/carbon-st, with the prototype prelude:
    the first run ABORTED (exit 134) inside
    check/testdata/interop/cpp/operators/operators.carbon, split
    `fail_todo_import_plus_with_string_view_conversion.carbon`: `s1 + s2` now
    resolves to `String as AddWith(String)`, and converting the `StringBuf`
    result to the C++ class `StringViewConvertibleC` reaches M-9's crash through
    `LookupCppConversion`. One crashing test aborts the whole run. Excluding
    that file
    (`--gtest_filter=-ToolchainFileTest.toolchain/check/testdata/interop/cpp/operators/operators.carbon`):
    `Ran 1941 tests`, 1940 passed, 1 failed,
    toolchain/check/testdata/operators/overloaded/string_indexing.carbon, which
    is D-ST-9's (without D-ST-9 all 1941 pass). Autoupdating that file in a
    scratch mirror adds 79 CHECK lines and removes 33 (the thunk between
    `IndexWith(Core.IntLiteral).At` and the `i64` impl function, and the
    literal's conversion to `i64`); a second autoupdate pass changes nothing.
    Rev 2, with the relinked file_test of M-19 (the §2.2 fix in), over the whole
    manifest and nothing excluded: `Ran 1942 tests`, 1940 passed, 2 failed
    (string_indexing.carbon and operators.carbon), no abort, 26 s wall.
    operators.carbon autoupdated in the mirror converges on its THIRD run (the
    runs are counted up to and including the one that prints only `.`; amended
    2026-10-13, review fold: RR-N-4): run 1 replaces the four
    `MissingImplInMemberAccess` lines of
    `fail_todo_import_plus_with_string_view_conversion` with
    `CppCallArgTypeNotSupported`, `ConversionFailure` and its note, and places
    the prelude-located `SemanticsTodo` (string.carbon:141:1) inside the
    PRECEDING split, `fail_todo_rewrite_equal`, whose `[[@LINE+4]]` becomes
    `[[@LINE+8]]`; run 2 renumbers that split's SemIR (`.loc23` to `.loc27`,
    three lines); run 3 prints `.`. Net +16/−5 lines, two upstream splits
    touched (amended 2026-10-13, review fold: A-5).
-   **M-11 (new goldens).** The §2.3 sources, autoupdated in a scratch mirror at
    substitute manifest paths (the trunk file_test runs only files in its
    compiled manifest). Rev 1: check `string/compare.carbon` 487 lines (439
    CHECK), `string/string_buf.carbon` 912 (863),
    `string/fail_string_buf.carbon` 70 (25); lower `string/compare.carbon` 81
    (62), `string/string_buf.carbon` 136 (109), `string/subscript.carbon` 130
    (110). Rev 2, the eight sources of §2.3 as amended, with the relinked
    file_test of M-19: check `string/compare.carbon` 488 lines (439 CHECK),
    `string/string_buf.carbon` 927 (876), `string/fail_string_buf.carbon` 70
    (25), `interop/cpp/stdlib/string_buf.carbon` 332 (264),
    `interop/cpp/operators/fork_all_operands_conversion.carbon` 43 (4); lower
    `string/compare.carbon` 81 (62), `string/string_buf.carbon` 215 (176),
    `string/subscript.carbon` 130 (110). Every one converges on its second
    autoupdate run (the first fills it, the second prints `.`; amended
    2026-10-13, review fold: RR-N-4) and then passes in test mode. §4 quotes
    their key lines (amended 2026-10-13, review fold: A-1, B2, B4).
-   **M-12 (conformance).** The five §2.4 programs on the prototype: 5 PASS,
    including the DIFF check against the C++17 oracle; on the trunk install all
    five are COMPILE-FAIL (not vacuous). The full existing suite on the
    prototype: `PASS 128 ... SKIP 22` over 150, bullets 48 PASS / 0 FAIL / 8
    SKIP, and zero status differences against
    fork/conformance/out/scoreboard.json. `runner.py --self-test` passes on
    80a11e7f0. Rev 2 re-ran the six String programs as amended in §2.4
    (string_missing_ops with line 26 rewritten, the reworded headers,
    string_basic's new header) on the M-19 install: 6 PASS, the String bullet
    PASS (amended 2026-10-13, review fold: B1, B2).
-   **M-13 (performance).** The M-4 stress program (20 doublings of two 1-byte
    strings to 1 MiB, 100 byte-wise equality tests of the two 1 MiB strings,
    10000 one-byte appends) runs in 0.099 to 0.130 s wall. A byte loop in Carbon
    is not a 0.1 bottleneck.
-   **M-14 (compile time).** `class C(B: bool)`: `C(1 == 1)*` is accepted,
    `C("x" == "x")*` is "argument for generic parameter is not a compile-time
    constant". A file-scope `let same: bool = "a" == "a";` is accepted.
-   **M-15 (generic `if` expressions, unrelated to strings).** `fn Min[T:
    Core.Ordered & Core.Copy](a: T, b: T) -> T { return if a < b then a else b;
    }` aborts lowering ("All operands to PHI node must be the same type as the
    PHI node!", `HandleInst(..., BranchWithArg)`) for `T = str` AND for a user
    class `P` on the unmodified trunk install, and the nightly crashes too (exit
    134). The statement form `if (a < b) { return a; } return b;` works with
    `str` (prints 5 for `Min("pear", "apple")`). Filed as W-164, not fixed here.
-   **M-16 (other branches' goldens).** UA-2's three new goldens (check and
    lower `slice/buf_field.carbon`, check
    `interop/cpp/template/dependent_var_full_prelude.carbon`) pass under the
    prototype prelude; UA-2 changes no toolchain source, so trunk's file_test is
    its toolchain. CM-1 and SAFE-1 add no goldens; none of SC-1's 18 changed
    goldens (16 of them new) mentions `str` or `String` outside CHECK lines
    (`git show` grep). Re-read for rev 2 at SC-1's head 2f4ebbf6e (whose tree
    8e4dd11ce is identical to fbfb99104, the head rev B cited): still 16 new
    and 2 modified goldens, none mentioning `str` or `String` outside CHECK
    lines; but since 42841fa8d SC-1 also changes member_access.cpp,
    name_lookup.cpp, generic.cpp, handle_require.cpp and
    structural_conformance.cpp, and `a == b` resolves through member access
    (`a.(EqWith(U).Equal)(b)`), so a semantic interaction is R-9's to catch,
    not ruled out here (amended 2026-10-13, review fold: B7).
-   **M-17 (an access hole not to rely on).** A file-scope function returning
    `{.ptr = p, .size = n}` as a class with private fields compiles, while
    reading `x.size` from file scope is "cannot access private member".
    classes.md:2156-2159 forbids the former, so the prelude does not use it
    (D-ST-11). User code can use it, and it falsifies `StringBuf`'s ownership
    invariant: `fn Forge(p: char*) -> Core.StringBuf { return {.ptr = p, .size
    = 1}; }` called with `&c` for a local `char` compiles, runs, and the
    tracking shim of §8.8 reports a free of a pointer `malloc` never returned
    (`malloc=1 free=0 bad=1`); `Core.Buf(i32)` forged the same way does the
    same. Filed as W-167 (amended 2026-10-13, review fold: A-3).
-   **M-18 (the orphan rule).** A scratch prelude library `string_orphan` (added
    to the copy's prelude manifest for a check-only run, then removed) declaring
    `impl String as AddWith(String) where .Result = StringBufX` with
    `StringBufX` defined there: "orphan `impl` found; something in the self-type
    or constraint must be defined in the same file". So `String`'s `AddWith`
    impls live in string.carbon, and `StringBuf` must too (D-ST-10).
-   **M-19 (a relinked toolchain with §2.2; rev 2).** The §2.2 patch applied to
    a scratch copy of export.cpp (`git apply --check` of the §2.2 block
    passes), compiled with the trunk build.ninja's own `$cxx $cflags` (12 s),
    and linked into `bin/file_test` and `bin/carbon-busybox` from every other
    object of /home/user/carbon-build/carbon-trunk (under 1 s, the trunk
    link lines with the one object swapped); the busybox replaces the one in
    an install copy that carries §2.1, and a runfiles tree whose
    `carbon/toolchain/install/*` entries point into that copy serves file_test
    through `RUNFILES_DIR`. For every file ST-1 changes this is an ST-1
    toolchain: only export.cpp differs from trunk among C++ sources, and the
    prelude is read from the install tree (§0.2 setup). clang-format 21.1.8
    with the repository's style leaves the patched file unchanged. Rev 1's
    "Not measured" paragraph (the §2.2 runtime behavior and the two goldens it
    changes) is discharged by this: M-10 and M-11 measure both goldens
    (amended 2026-10-13, review fold: A-1).
-   **M-20 (a crash in C++ overload resolution, independent of ST-1).** Rev 1's
    `as_str` split, `Cpp.Consume(b.AsStr());` against the mock
    `basic_string_view` header of §2.3, aborts the M-19 file_test (exit 134,
    Clang's assertion `DD && "queried property of class with no definition"`
    in `CXXRecordDecl::data()`, crash context "Checking CallExpr
    Cpp.Consume(b.AsStr())"), which aborts the whole run. It is a trunk bug:
    with the same mock header, `fn Mk() -> str { return "a"; } fn F() {
    Cpp.Consume(Mk()); }` aborts the UNMODIFIED trunk install's `carbon compile
    --phase=check` the same way, in `IsMoveEquivalentToCopy`
    (check/cpp/overload_resolution.cpp:157-172, reached at :199 for an xvalue
    argument: an initializing `str` passed to a parameter whose
    `basic_string_view<char>` specialization was never instantiated, so
    `hasMoveConstructor()` queries a class with no definition; upstream-trunk
    62f1cc6a3 has the same code at :156-199). The same `F` with `let v: str =
    Mk(); Cpp.Consume(v);` passes, and with the real libc++ `<string_view>`
    `Cpp.ViewSize(Mk())` compiles, links and prints 3. Filed as W-165; the
    split binds the view to a `let` first (§2.3; amended 2026-10-13, review
    fold: A-1).
-   **M-21 (a `str` view can outlive its owner; rev 2).** With §2.1 and the
    §8.8 shim, four natural shapes compile silently and read freed memory:
    `fn Join(a: str, b: str) -> str { return a + b; }` (the `+` result is a
    temporary `StringBuf` viewed through `ImplicitAs(str)` and destroyed when
    `Join` returns; printing `Join("hello, ", "world")`
    after one more 12-byte allocation prints `XXXXXXXXXXXX`); a local `var`
    owner returned as `-> str` (prints the next allocation's `YYYY`, not
    `abc!`); a `str` field initialized from a `+` temporary (prints `QQQ`, not
    `zz?`); and `let v: str = s; s += "!";` leaves `v` reading a later block
    (`ZZZZZZZZ`, not `abcdefgh`). The `let` view of a declaration's temporary
    (string_missing_ops line 26 as test-first written) is the one shape
    today's toolchain keeps alive (M-7). Filed as W-166 (amended 2026-10-13,
    review fold: A-2).
-   **M-22 (more 0.1 limits; rev 2).** `var s: Core.StringBuf = if c then a +
    a else Core.StringBuf.Make("x");` is "semantics TODO: `destroying
    temporaries of a conditionally evaluated operand whose value is not passed
    by copy`" (check/control_flow.cpp:209-212, the UA-1 residue W-122);
    `var s = Make("a"); s = s + "b"; s = Make("q");` with one `Core.Print`
    shows 4 `malloc` (stdio's and three blocks) and 1 `free` (W-160)
    (amended 2026-10-13, review fold: A-4, A-10).
-   **M-23 (allocation balance of the six String programs; rev 2).** Each
    binary of the M-12 rev 2 run under the §8.8 shim: string_basic `malloc=1
    free=0`, string_missing_ops 2 and 1, string_ordering_diff 3 and 2,
    string_buf_lifetime 8 and 7, string_concat_loop 20 and 19,
    string_subscripts 28 and 27, every one `bad=0`. Each count is
    re-derivable by hand from the program text, and matches: stdio's one
    buffer plus one block per `Make`, per `+` result (intermediate ones
    included) and per `+=`, every block freed (amended 2026-10-13, review
    fold: B2).
-   **M-24 (the all-operands-conversion TODO with `bool`; rev 2).** The §2.3
    source fork_all_operands_conversion.carbon (two `bool` operands, a C++
    class constructible from `bool` with a free `operator+`) fills to 43
    lines with `` cannot access member of interface `Core.AddWith(bool)` in
    type `bool` that does not implement that interface
    [MissingImplInMemberAccess] `` at column 40, the diagnostic upstream's
    `str` split pinned before ST-1; the filled file passes unchanged on the
    UNMODIFIED trunk file_test, so it pins only pre-existing behavior (amended
    2026-10-13, review fold: B4).
-   **M-25 (the self-aliasing append and its rewrite; rev 3).** In the rev 3
    fixer's scratch tree
    (`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/st1-fix3`)
    with rev 2's M-19 install copy, whose string.carbon is byte-identical to
    §2.1, and a fresh `XDG_CACHE_HOME`; every line was predicted by hand before
    the run. A probe `var s: Core.StringBuf = Core.StringBuf.Make("abc"); s +=
    Core.StringBuf.Make(s);` then `var t: Core.StringBuf =
    Core.StringBuf.Make("xy"); t += t;` prints `abcabc`, 6, 1 (for `s ==
    "abcabc"`) and `xyxy`, and the §8.8 shim reports `malloc=6 free=5 bad=0`
    (stdio's buffer and five blocks; the copy is freed at the end of its
    statement). The six String programs extracted from §2.4 (string_basic from
    the tree): runner 6/6 PASS, and exactly M-23's shim counts. With
    string_buf_lifetime's `s += s;` and string_concat_loop's `big += big;`
    rewritten to `s += Core.StringBuf.Make(s);` and `big +=
    Core.StringBuf.Make(big);` (D-ST-14's W-148 remedy), EXPECT unchanged: 6/6
    PASS, and the two counts become `malloc=9 free=8` and `malloc=30 free=29`
    (one more block per rewritten append, every block freed, `bad=0`) (amended
    2026-10-13, review fold: RR-N-1).

Not measured, and why: an ST-1 toolchain built from this worktree by
carbonbuild (M-19 is the trunk build with one object swapped, which is
equivalent for the files ST-1 changes, but not the build the gate of §8 runs);
Bazel-only tests, macOS, Windows and an opt-mode toolchain were not available
(§8) (amended 2026-10-13, review fold: A-1).

### §0.3 Ledger and brief claims found stale (each corrected at discharge, §2.6)

1.  W-057's evidence
    `fork/conformance/programs/stdlib/string_missing_ops.carbon:2` is a license
    line; the SKIP line is :6.
2.  W-057's note "a non-owning {Char*, u64}": the prelude's `size` is `i64`
    (string.carbon:25); the `u64` is the min_prelude part's (gap row 77 already
    says so).
3.  Gap row 77 and the brief say string.carbon has 33 lines; it has 32 (`wc
    -l`).
4.  string_basic.carbon:14-15 says `{Char*, u64}` and "`.Size()` returns u64":
    both are `i64` (string.carbon:17, :25). Its "Caution" :21-26 is accurate on
    trunk (M-6) and becomes stale at D-ST-9; the header is refreshed in commit 4
    (§3), the body is not touched.
5.  The brief lists `Core.Buf(T)`'s API as "Make/At/Set/Size/Destroy": `Buf` has
    `Make`, `Size`, `Get`, `Set`, `AsSlice` and the `Destroy` impl; `At` is the
    `IndexWith(i64)` impl's function (buf.carbon:28-75).
6.  The §W9 "Depends on" line (gap-analysis.md:226-230) lists variadics, sum
    types, unions and variant/optional interop as dependencies of "the String
    and Optional halves": none is a dependency of the String half, which this
    plan implements without them; corrected to "the Optional half" at discharge.

### §0.4 Decisions this plan auto-adopts (R29(a): the design recommendation under V-2/V-3, veto-able after the fact)

Each decision cites what it follows or the silence it fills and carries a
one-sentence break condition. The decision-log entry F-014 is written at
discharge (§2.6) with these decisions by number.

-   **D-ST-1: a fork design decision, F-014.** The owning string's existence
    follows README.md:627-634, but its name, its ownership rules and `+` as
    concatenation (arithmetic.md:184-188, issue 457 undecided; amended
    2026-10-13, review fold: A-7) have no proposal
    behind them, so this is a fork-level design decision and not merely an
    implementation of upstream's: F-014 is minted and recorded at discharge, and
    the byte semantics of comparison (p006177:125-126) are recorded under it.
    Break condition: an accepted upstream proposal for string types lands; F-014
    is then re-derived against it at the next upstream advance.
-   **D-ST-2: equality is byte-wise and written in Carbon; no new builtin.**
    `impl String as EqWith(String)` compares sizes, then bytes through `a[i] !=
    b[i]` (the `Char` impls, char.carbon:49-52) in a private `BytesEqual(a: str,
    b: str) -> bool`. A `"string.eq"` builtin lowered to `memcmp` would need
    four toolchain sites (kind.def, kind.cpp validation, an eval arm, a lowering
    arm) for no 0.1 benefit (M-13: 100 comparisons of 1 MiB strings with the
    other work in 0.13 s); the Carbon body keeps every semantic line in source,
    the D-SL-5 reasoning. Its one cost, no compile-time evaluation (M-14), is
    filed as W-163. Break condition: a measured program where string comparison
    dominates, or W-163 is taken up; then the body calls the builtin and the
    impl signature does not change.
-   **D-ST-3: ordering is lexicographic on bytes as unsigned values, a proper
    prefix first.** `impl String as OrderedWith(String)`: the first differing
    byte decides (as `Char`'s `u8` order, char.carbon:54-59), else the shorter
    string orders first. This is exactly C++'s `std::string_view` order
    (`char_traits<char>::compare` compares as `unsigned char`,
    [char.traits.specializations.char]), which makes a C++ differential oracle
    legitimate (§2.4, R30 does not apply: the two sides agree by construction).
    The four functions share a private `BytesCompare(a: str, b: str) -> i32`
    returning -1, 0 or 1; there is no `Compare` because the prelude's
    `OrderedWith` has none (comparison.carbon:24-32). It is transitive,
    consistent under reversal, and `==` refines it
    (comparison_operators.md:436-472). Break condition: upstream specifies a
    different string order (for example code-point or locale order); then
    `BytesCompare` changes and the oracle with it.
-   **D-ST-4: the owning type is a separate class, `Core.StringBuf`; `str` stays
    the view.** Of the three shapes the brief names, (iii) is adopted: `class
    StringBuf { private var ptr: Char*; private var size: i64; }`, the
    `{pointer, size}` layout of `String` and `Buf`, owning a heap block
    allocated by `"heap.allocate"` and freed by an in-class `impl as Destroy {
    fn Op(ref self) { HeapFree(self.ptr); } }` (the buf.carbon:58-60 shape).
    (i), an owning `Core.String` with the view renamed `Core.Str`, matches
    p006177's names but renames an upstream class that three toolchain sites key
    on by name (§0.1 row 3), churns every golden that prints `@String` or
    `%String.val` and union/basic.carbon's source, and preempts upstream's own
    rename; rejected (§7 A-1). (ii), `+` returning a leaking `str`, makes every
    concatenation in a loop leak and contradicts README.md's owning/view split;
    rejected (§7 A-2). The name: `String` is taken by the view class, and
    `StringBuf` says "the heap buffer of a string" in the vocabulary
    README.md:887-889 already uses for `Core.Buf(T)`. `StringBuf` holds a raw
    pointer, not a `Buf(Char)` field, because growing in place needs to replace
    the block, which a field cannot do without move semantics (assignment does
    not destroy, M-5), and because a declared `Destroy` on the owner would leave
    a `Buf` field undestroyed (M-8). Break condition: upstream renames the view
    class to `Str` and names the owning type; `StringBuf` is renamed to that
    name (a mechanical rename, layout unchanged).
-   **D-ST-5: `StringBuf` is not copyable and not `UnformedInit`.** There is no
    `Copy` impl, so a copy is `CopyOfUncopyableType`
    (custom_witness.cpp:1833-1838 synthesizes `Copy` only for choices and
    unions; M-11 pins "cannot copy value of type `StringBuf`"), never a double
    free; the deep copy is explicit, `Core.StringBuf.Make(s)`, the `Core.Buf`
    precedent (D-SL-6). A string built in a function leaves it through `returned
    var` (a `return s;` of a plain `var` is a copy, also pinned). Not
    `UnformedInit`: `Destroy` runs unconditionally on `var` storage (D-SL-6's
    measurement), so `var s: Core.StringBuf;` must stay the
    `ConversionFailureTypeToFacet` error it is (pinned). Break condition: a move
    or relocation operator lands (`~x`, F-013 D-SAFE-13 I4 once implemented);
    `return s;` then moves, and a deep-copy `Copy` impl is reconsidered.
-   **D-ST-6: conversions and view lifetime.** `impl StringBuf as
    ImplicitAs(str)` (README.md:633-634's owning-to-view conversion) and the
    explicit `AsStr()`; there is no implicit `str` to `StringBuf` conversion,
    since README.md specifies only the other direction and an implicit
    allocation would hide cost (pinned as `fail_view_to_owned`). A view is valid
    until its `StringBuf` is destroyed or appended to, and a view of a temporary
    `StringBuf` until the end of the full-expression that creates it: F-013
    D-SAFE-12's rule (values.md:168 leaves the question open upstream). Today's
    toolchain destroys a declaration initializer's temporaries at the end of the
    enclosing block (M-7); that is behavior, not design, and no ST-1 program,
    golden or doc example relies on it (D-ST-14 rewrites string_missing_ops line
    26, and the `LetView` golden binds a `var` owner). The conversion makes
    three natural shapes silent use-after-frees today (M-21): a `-> str`
    function returning a `+` result or a local `StringBuf`, a `str` field
    initialized from a temporary, and a view held across `+=`; nothing diagnoses
    them until SAFE-1's stage 4 loan checker (W-148), so they are filed as
    W-166, `StringBuf.AsStr` and `StringBuf as ImplicitAs(str)`'s `Convert` join
    W-144's list of view producers that need `bound self` (§2.6), together with
    the interface declaration `ImplicitAs(Dest).Convert` that the `Convert` impl
    needs it on (D-ST-11; amended 2026-10-13, review fold: RR-N-2), and the docs
    and hand-off carry the rule "a function returning `str` never returns a `+`
    result or a local `StringBuf`; it returns `Core.StringBuf`" (amended
    2026-10-13, review fold: A-2, A-11 / B1). Break condition: W-148 lands and
    rejects one of ST-1's own programs or goldens beyond the four expected trips
    D-ST-14 names, or the toolchain's temporaries become full-expression-scoped
    and a program's output changes; then a view of a temporary is rewritten to
    bind a `var` owner and a self-aliasing append to append a copy, `s +=
    Core.StringBuf.Make(s);`, each with its EXPECT unchanged (amended
    2026-10-13, review fold: RR-N-1).
-   **D-ST-7: concatenation.** `+` on each of the four operand pairs of `str`
    and `StringBuf` builds a new `StringBuf` (`where .Result = StringBuf`)
    through `StringBuf.Concat(a: str, b: str)`; `+=` with a `str` or `StringBuf`
    right operand appends by allocating the joined block, copying both parts,
    freeing the old block and only then updating `self`, so `s += s` is
    memory-safe today (M-3, M-4, M-25); it is not part of the design, since
    F-013 rejects it once W-148 lands (§1.4), and `s += Core.StringBuf.Make(s);`
    is the spelling that stays valid (amended 2026-10-13, review fold: RR-N-1).
    No `char` or `CharLiteral` operand (`s + 'c'` stays "cannot access member of
    interface `Core.AddWith(Core.CharLiteral)`"). Loops append with `+=`: `s = s +
    t` leaks through M-5's assignment gap, which is W-160. Break condition:
    upstream decides issue 457 against `+` for strings; the four `AddWith` impls
    are deleted and `Concat` and `+=` remain.
-   **D-ST-8: comparisons for all four operand pairs, as explicit impls.**
    `EqWith` and `OrderedWith` are implemented for (`str`, `str`), (`str`,
    `StringBuf`), (`StringBuf`, `str`) and (`StringBuf`, `StringBuf`), because
    the `EqWith` overload is selected without implicit conversions
    (comparison_operators.md:288-290). Not `Char`'s blanket shape (`impl forall
    [T: ImplicitAs(Char)] T as EqWith(Char)`, char.carbon:61-83): with blankets
    every `str == str` would choose among three candidate impls and instantiate
    a generic impl per use, for one convertible type. Break condition: a second
    type converts implicitly to `str`; then the mixed pairs become blankets over
    `T: ImplicitAs(str)`.
-   **D-ST-9: `str` subscripts convert to `i64` before `"string.at"`.** The
    blanket impl's function becomes `fn At(self, subscript: i64) -> Char =
    "string.at";` (string.carbon:31), the parameter spelling of
    char.carbon:61-64. The subscript of any `T: ImplicitAs(i64)` is converted in
    the impl's thunk, so an integer literal reaches the builtin as an `i64`
    constant and a `u8` is zero-extended: both M-6 defects are fixed,
    compile-time `StringAtIndexNegative`/`StringAtIndexOutOfBounds` still fire
    (measured: "index `-1` is negative.", "string index `4` is out of bounds;
    string has length 4."), and the cost is one refilled golden (M-10). Break
    condition: upstream fixes the lowering of `"string.at"` for literal or
    narrow subscripts; the line is reverted to upstream's.
-   **D-ST-10: one file, no new import lines, no moved lines above the class's
    end.** Everything is in core/prelude/types/string.carbon: the orphan rule
    puts every `String` impl there (M-18), and `AddWith(String) where .Result =
    StringBuf` there forces `StringBuf` into the same library, since a separate
    string_buf.carbon importing string.carbon would form a cycle. The two
    imports string.carbon needs are swapped into existing import lines (:12
    `prelude/operators/index` becomes `prelude/operators`, which re-exports
    index, as, arithmetic and comparison; :14 `prelude/operators/as` becomes
    `prelude/types/maybe_unformed`), so lines 1-25 do not move; `UnsafeMake`
    goes after the fields; the rest is appended after :32. No prelude FILE is
    added, which also keeps the runtimes prelude list unchanged (§0.2 setup).
    Break condition: upstream splits string.carbon; the ST-1 section moves with
    the class.
-   **D-ST-11: `String.UnsafeMake(p: Char*, size: i64) -> String` is public.**
    `StringBuf.AsStr` must form a `String` from its block, which
    classes.md:2156-2159 allows only with access to the fields; the toolchain
    does not enforce that rule (M-17) and the plan does not rely on its absence.
    The name is `Slice(T).UnsafeMake`'s (D-SL-11). SAFE-1's W-144 renames every
    `UnsafeMake` to `unsafe fn Make` when stage 1 lands; this one joins that
    list, with `StringBuf.AsStr` and `StringBuf as ImplicitAs(str)`'s `Convert`
    as view producers that need `bound self` (§2.6; amended 2026-10-13, review
    fold: A-2 / B1). Because an impl may drop but not add `bound` (F-013 T5(e),
    temporal_safety.md:507-512 on the safe branch), the `Convert` impl can carry
    `bound self` only if the interface declaration `ImplicitAs(Dest).Convert`
    (core/prelude/operators/as.carbon:23) carries it, as SP3 has `IndexWith.At`
    and `Copy.Op` carry it; so that declaration joins the list, with
    `As(Dest).Convert` (:18) and `UnsafeAs(Dest).Convert` (:13), through which
    the workaround blankets at :27-34 forward `b as str`. Without it the
    converted view reads as free under T5(a), and W-148 would not flag `fn
    Join(a: str, b: str) -> str { return a + b; }`. SAFE-1's SP3 has the same
    gap for `Slice(T) as ImplicitAs(Slice(const T))`'s `Convert`, and T2's
    clause that every `ImplicitAs` impl is not a loan boundary must read an
    owner-to-view `Convert` as a `bound self` producer; both are items of the
    SAFE-1 reconciliation (§2.6) (amended 2026-10-13, review fold: RR-N-2). The
    toolchain's hole lets user code forge a `StringBuf` (M-17), which is filed
    as W-167, not used (amended 2026-10-13, review fold: A-3). Break condition:
    `friend` is implemented (check/handle_class.cpp:364-371 is a TODO today);
    then `UnsafeMake` becomes private to `String` and `StringBuf`.
-   **D-ST-12: C++ interop.** A `StringBuf` reaches a `std::string_view`
    parameter through its view, `Cpp.F(s.AsStr())`, because C++ overload
    resolution does not see Carbon `ImplicitAs` conversions (M-9). Passing it
    directly must be a diagnostic, not the M-9 crash: `ExportClassToCpp` returns
    null when `ExportNameScopeToCpp` did, the check its three sibling callers
    already make (§2.2; a fork-local fix of an upstream latent bug, the UA-1
    precedent). No `std::string` mapping: the milestone requires only non-owning
    string mapping (milestones.md:207-208), and libc++'s `std::string`
    (small-string layout) is not `{pointer, size}`; filed as W-161. Break
    condition: upstream fixes the null check (drop the fork's lines at that
    advance) or designs owning-string interop (W-161 follows it).
-   **D-ST-13: min_prelude does not change.** No min_prelude golden loads
    core/prelude (§0.1 row 11), and M-10 shows the prelude change alters no
    golden other than the two named. The new goldens include
    min_prelude/full.carbon, as SL-1's did. Break condition: a min_prelude
    golden needs string comparison; then parts/string.carbon grows the impl it
    needs, by itself.
-   **D-ST-14: conformance.** string_missing_ops.carbon is un-SKIPped with its
    EXPECT values unchanged: its two assertions are design-derived (`"hi" ==
    "hi"` is true under byte equality; the concatenation of two 2-byte strings
    has 4 bytes). Its body changes in one line, :26, the test-first `let c: str
    = a + b;` becoming `var c: Core.StringBuf = a + b;`: as written, `c` views
    a temporary past its full-expression, which D-ST-6 and F-013 D-SAFE-12
    reject and which passes today only through M-7's undesigned lifetime; it
    was also non-discriminating, since `c.Size()` reads only the view's size
    field. The repair is disclosed in the un-SKIP commit's message and the
    decision-log entry (the R6 template; amended 2026-10-13, review fold: B1).
    Four programs are added (§2.4): the ordering differential pair, the
    ownership and lifetime program, concatenation in loops, and the subscript
    fixes. Names are kept (string_missing_ops stays string_missing_ops: the
    scoreboard identity matters more than the name). Break condition: one of
    the six String programs stops passing on a toolchain that contains ST-1 —
    in particular when W-148's checker lands; the program's EXPECT is then
    re-derived from the design, never from the run (R16(d)), and the cause
    fixed or filed before the program changes (amended 2026-10-13, review
    fold: B9). No ST-1 program binds a view of a temporary past its
    full-expression, but four lines are expected W-148 trips: the
    self-aliasing appends string_buf_lifetime's `s += s;`,
    string_concat_loop's `big += big;` and the check golden append.carbon's
    `b += b;` (`StrictSharedBorrowInvalidated` under F-013 T4 with M8,
    §1.4), and view.carbon's `fn View(b: Core.StringBuf) -> str { return b;
    }`, which is expected to need `bound b` under T5(a) and SP3's audit rule.
    They stay as written in ST-1: unlike line 26, which relied on an
    undesigned lifetime and could not discriminate, a self-append is
    memory-safe under any lifetime rule, it is the suite's only exercise of
    D-ST-7's read-before-free order, and its rejection is not observable
    before W-148. When W-148 lands, the two program lines become `s +=
    Core.StringBuf.Make(s);` and `big += Core.StringBuf.Make(big);`, EXPECT
    unchanged and disclosed in the R6 template (measured now, M-25: both
    still PASS, and §8.8's counts become 9/8 and 30/29); the commit that
    lands W-148, which refills every golden its checker changes, rewrites
    append.carbon's line the same way, moves `b += b;` into a `fail_` split
    that pins the new diagnostic, and adds `bound b` to `View` (amended
    2026-10-13, review fold: RR-N-1).
-   **D-ST-15: docs.** A new normative page docs/design/strings.md, marked as a
    dated fork amendment, plus dated blockquote amendments (never rewrites) at
    README.md "String types", arithmetic.md "Strings" and the interop README's
    `std::string_view` and `str` subsection (§2.5). Break condition: upstream's
    string design lands; strings.md is then reconciled with it.
-   **D-ST-16: row 77 becomes DONE with filed limits; `str` subscripts stay
    unchecked at run time.** The bullet's text is met: the string types used
    with string literals exist as a view and an owning type with comparison,
    concatenation and conversion. The W9 Arbiter's String half, "an
    approved-design ... String with comparison/ownership story"
    (gap-analysis.md:241-244), is met under R29(a): F-014 is a decided fork
    design, recorded for after-the-fact veto as F-012 is for slices, whose
    comparison and ownership story, limits included, is docs/design/strings.md.
    Row 79 stays PARTIAL because a design-specified operation OF ITS OWN TYPE is
    missing (write-through indexing, indexing.md's `IndirectIndexWith`, W-109);
    ST-1 leaves no design-specified string operation missing (README.md:627-634
    specifies the two types and the owning-to-view conversion), and every open
    item is either a language-wide mechanism filed under its own bullet or a
    limit beyond the bullet's text. Named in the row: assignment does not
    destroy the overwritten value (W-160, refiled under "Type system:
    User-defined types (classes)": handle_operator.cpp:119-120, every class with
    a `Destroy`, `Core.Buf` included); a class that declares `Destroy` does not
    destroy a `StringBuf` field (UA-2's W-126); a `str` view can outlive its
    owner (W-166, SAFE-1's loan checker W-148); struct-literal construction
    bypasses private-field access, so a forged `StringBuf` can free a non-heap
    pointer (W-167, classes bullet); an `if` expression with a `StringBuf`
    temporary in an arm is a semantics TODO (UA-1's W-122); owning-string C++
    interop (W-161, which milestones.md:207-208 does not require); no run-time
    bounds check on `str` subscripts (W-162: a checked `At` would have to be a
    Carbon body, which loses the compile-time `StringAt` diagnostics that
    upstream's string_indexing.carbon `fail_` splits pin, so the check belongs
    in the builtin's lowering; it is not part of SAFE-1's W-146, whose title
    covers arrays and division only, and is linked to it as related);
    compile-time string comparison (W-163). W-164 (M-15) and W-165 (M-20) are
    filed under the generics and string-mapping bullets; row 51's and row 81's
    text does not change (amended 2026-10-13, review fold: A-4 / B3, A-10, B12);
    row 41 ("Type system: User-defined types (classes)") stays DONE, its "access
    control fully checked" amended to name W-167 (§2.6; amended 2026-10-13,
    review fold: RR-N-3). Break condition: a program that uses only the
    documented API (no `=` on a `Core.StringBuf`) leaks or double-frees under
    the §8.8 shim check, or a design-specified string operation is shown
    missing; then the row stays PARTIAL with it named (amended 2026-10-13,
    review fold: B3 / B9).

## §1 Design

### §1.1 The two types

`str` is unchanged: the prelude class `Core.String`, a non-owning view of bytes
(`{ptr: Char*, size: i64}`, copyable, `UnformedInit`), the type of every string
literal (README.md:645-678, string_literals.md), mapped to and from
`std::string_view`. It gains the comparison impls (§1.2), the `+` impls (§1.4),
the public `UnsafeMake` (D-ST-11) and the `i64` subscript parameter (§1.5).

`Core.StringBuf` is new: an owning byte string with the same `{pointer, size}`
representation over a block from `"heap.allocate"`, freed by its declared
`Destroy` impl. Its API is deliberately small: `Size()` and the comparisons
(§1.2) are on both types, and subscripts are on the view only (amended
2026-10-13, implementation review fold: ST1-IR2-1).

| Member | Meaning |
| --- | --- |
| `fn Make(s: str) -> Self` | a new string holding a copy of `s`'s bytes; also the explicit deep copy of a `StringBuf` (which converts to `str` at the call) |
| `fn Concat(a: str, b: str) -> Self` | a new string holding `a`'s bytes then `b`'s; what every `+` impl calls |
| `fn Size(self) -> i64` | the number of bytes |
| `fn AsStr(self) -> str` | the view; valid until `self` is destroyed or appended to, and for a temporary `self` until the end of its full-expression; nothing diagnoses a later use today (W-166; amended 2026-10-13, review fold: A-2) |
| `impl as Destroy` | frees the block (`"heap.free"`) |
| `impl as AddAssignWith(str)`, `impl StringBuf as AddAssignWith(StringBuf)` | `s += t`: join into a new block, free the old one, then update `self` |
| `impl StringBuf as ImplicitAs(str)` | the owning-to-view conversion of README.md:633-634 |

Not provided, on purpose: `Copy` (D-ST-5), `UnformedInit` (D-ST-5), an implicit
conversion from `str` (D-ST-6), `IndexWith` and `Iterate` on `StringBuf` (read
through the view: `let v: str = s; v[i]`), UTF-8 validation or character
iteration (p006177:125-129 keeps these types byte views; SAFE-1's `Core.Utf8`,
W-144, is the place for a validated type).

### §1.2 Comparison

`BytesEqual(a, b)`: sizes differ → false; otherwise the first `i` with `a[i] !=
b[i]` → false; else true. `BytesCompare(a, b)`: over `i < min(a.Size(),
b.Size())`, the first unequal pair of bytes decides by `Char`'s unsigned order
(-1 or 1); then the shorter string is first; equal sizes give 0. Every `EqWith`
and `OrderedWith` impl of §2.1 is one line over these two functions, with the
`StringBuf` operands viewed through `AsStr()`. Equality is a refinement of the
order (equal bytes and sizes ⇔ `BytesCompare` is 0), as
comparison_operators.md:468-472 asks. Generic code sees `str` as `Core.Eq` and
`Core.Ordered` (measured: `IsEq[T: Core.Eq]` with `str` prints 1 then 0; `Min[T:
Core.Ordered & Core.Copy]` in statement form prints 5).

### §1.3 Ownership and lifetime

-   A `StringBuf` that the prelude builds (`Make`, `Concat`, every `+`) owns
    exactly one block from `"heap.allocate"`, never null: a zero-byte request
    yields a one-byte block (lower/handle_call.cpp:769-775), and an allocation
    failure is the existing fail-stop "carbon: heap allocation failed;
    terminating" (as buf.carbon:33-35). A value forged from a struct literal
    through the toolchain's access hole (M-17) holds whatever pointer it was
    given and its destruction is undefined (W-167; amended 2026-10-13, review
    fold: A-3).
-   Its declared `Destroy` frees the block when a `var` goes out of scope, when
    a temporary dies (today's toolchain, M-7: a declaration initializer's
    temporaries at the end of the enclosing block, an expression statement's
    at the end of the statement; the design ends a view of a temporary at its
    full-expression, D-ST-6) and when an enclosing object without a declared
    `Destroy` is destroyed (M-8; pinned by the lower golden's `Field`, §4)
    (amended 2026-10-13, review fold: A-11 / B1, B2).
-   It is never copied implicitly (D-ST-5). A function returns a string it
    builds as `-> Core.StringBuf`, either directly (`return a + b;`, an
    initializing expression) or through `returned var` (M-7: destroyed once);
    never as `-> str`, which returns a view of a block freed on return (M-21,
    W-166; amended 2026-10-13, review fold: A-2).
-   Known 0.1 gaps, each filed: `s = t;` does not destroy the old value
    (handle_operator.cpp:119-120), so the old block leaks (W-160); a class that
    declares its own `Destroy` does not destroy a `StringBuf` field (W-126 on
    the UA-2 branch; not re-filed here); a `str` view can outlive its owner
    with no diagnostic (W-166); a forged `StringBuf` (W-167) (amended
    2026-10-13, review fold: A-2, A-3).

### §1.4 Concatenation

`+` on (`str`, `str`), (`str`, `StringBuf`), (`StringBuf`, `str`) and
(`StringBuf`, `StringBuf`) returns a new `StringBuf`; chains associate left to
right, so the expression of the next fence allocates one intermediate block,
destroyed with the enclosing block's temporaries (today's toolchain, M-7), and
one result. `+=` appends in place and is the spelling for loops. An `if`
expression whose arm builds a `StringBuf` temporary (`if c then a + a else
...`) is a semantics TODO today (M-22, UA-1's W-122; assigning in an `if`
statement instead would leak through W-160), so 0.1 code builds the string in
each branch where it is used (amended 2026-10-13, review fold: A-10).

```carbon
var s: Core.StringBuf = piece + piece + piece;  // a temporary, then s
s += "!";  // one new block; the previous one is freed
```

The append reads both parts into the new block (`JoinBytes`) before `HeapFree`
releases the old one, so a right operand that is or views `self` (`s += s`, or
`s += v` where `v` is `s.AsStr()`) is memory-safe and accepted today (M-3,
M-25). It is not part of the design. Under F-013, which ST-1 adopts as governing
(D-ST-6), `s += s` binds the by-value non-`Plain` parameter `other` of
`AddAssignWith(StringBuf).Op` to the owner `s`, a shared loan on `s` for the
call (T2's value-binding clause, mutation_safety.md M8), and the `ref self` call
is an invalidating operation on `s` (M3(d)), so T4 makes it
`StrictSharedBorrowInvalidated` once W-148's loan checker lands, as Rust rejects
`s.push_str(&s)`; `s += v` is rejected the same way once `AsStr` and `Convert`
carry `bound self` (W-144, D-ST-11). The spelling that stays valid appends a
copy, `s += Core.StringBuf.Make(s);` (M-25: the same bytes, one more block), and
D-ST-14 names the three existing self-appends as expected W-148 trips (amended
2026-10-13, review fold: RR-N-1). Sizes add in `i64`; a sum past the address
space reaches `"heap.allocate"` as an impossible count and fails-stop as an
allocation failure.

### §1.5 Subscripts

`s[i]` keeps its design meaning (the `IndexWith` rewrite, indexing.md) and its
compile-time diagnostics; D-ST-9 only moves the conversion of the subscript to
`i64` from nowhere (the builtin received `T` raw) into the impl's thunk. There
is still no run-time bounds check (W-162).

### §1.6 C++ interop

Unchanged: `str` and `std::string_view` map both ways. New and documented: a
`StringBuf` crosses as its view, `Cpp.F(s.AsStr())` (with the real libc++
`<string_view>`; against a mock `basic_string_view` that no code instantiates,
a call result passed straight to the parameter crashes Clang on trunk too, so
the golden binds the view to a `let` first, M-20, W-165; amended 2026-10-13,
review fold: A-1); a `std::string_view`
returned by C++ compares with and concatenates to Carbon strings like any `str`
(measured: `Cpp.Hello() == s` and `Cpp.Hello() + "!" == "hello!"` print 1).
`Cpp.F(s)` with `s: Core.StringBuf` is diagnosed: "call argument of type
`Core.StringBuf` is not supported" together with the existing "semantics TODO:
`interop with non-identifier package name`" at the class (W-049's TODO,
export.cpp:139-142), the shape param_unsupported.carbon already pins for `i512`.
No `std::string` mapping in either direction (W-161).

### §1.7 What ST-1 does not do (residue titles; ids at §2.6)

-   W-160 (classes bullet; amended 2026-10-13, review fold: B3): assignment
    does not destroy the overwritten value, so `s = t;` on a `Core.StringBuf`
    (or a `Core.Buf`, or any class with a `Destroy`) leaks the old block; `=`
    does not use `AssignWith` (handle_operator.cpp:98-103, :119-120;
    assignment.md:176-184).
-   W-161: owning-string C++ interop: no `Core.StringBuf` and `std::string`
    mapping, and C++ overload resolution does not consider a Carbon
    `ImplicitAs(str)` conversion of a `Core.StringBuf` argument (`AsStr()` is
    required).
-   W-162: no run-time bounds check on `str` subscripts (`"string.at"` lowers to
    an unchecked `getelementptr`); `Core.Slice` and `Core.Buf` fail-stop
    (D-SL-4). Independent of SAFE-1's W-146 (arrays and division), related to
    it (amended 2026-10-13, review fold: A-10 / B1).
-   W-163: `str` comparisons are not compile-time constants (`C("x" == "x")` is
    rejected, M-14); needs a `"string.eq"`/`"string.compare"` builtin with an
    eval arm, or compile-time evaluation of function bodies.
-   W-164 (Generics, found while measuring, M-15): an `if` expression whose type
    is a symbolic `T` crashes lowering in a specific where `T` is a class type.
-   W-165 (string mapping, found while measuring, M-20): an initializing `str`
    argument passed to a C++ `basic_string_view<char>` parameter whose
    specialization was never instantiated asserts in Clang
    (`IsMoveEquivalentToCopy`, check/cpp/overload_resolution.cpp:157-172);
    upstream has the same code (amended 2026-10-13, review fold: A-1).
-   W-166 (SAFE-1's loan checker): a `str` view of a `Core.StringBuf` can
    outlive its owner with no diagnostic, for example a `-> str` function
    returning a `+` result or a local owner, a `str` field initialized from a
    temporary, a `+` result assigned to an existing `str` variable, a view
    held across `+=` (M-21; amended 2026-10-13, review fold: A-2; the
    assignment shape amended 2026-10-13, implementation review fold: RV1-2).
-   W-167 (classes bullet): struct-literal construction of a class bypasses
    private-field access control (classes.md:2156-2159), so user code can
    forge a `Core.StringBuf` or `Core.Buf` whose `Destroy` frees a non-heap
    pointer (M-17; amended 2026-10-13, review fold: A-3).
-   Not filed again: an `if` expression with a `StringBuf` temporary in an arm
    is UA-1's W-122 (check/control_flow.cpp:209-212, M-22; amended 2026-10-13,
    review fold: A-10).
-   Not filed (no requirement names them): `StringBuf` indexing and iteration,
    character iteration over `str`, `Core.Utf8` (SAFE-1's W-144), a `c_str()`
    terminator.

## §2 Implementation spec, file by file

### §2.1 core/prelude/types/string.carbon (the whole file after ST-1; 275 lines)

Edits to existing lines, all inside the first 32 lines (the rest is appended):

```diff
 import library "prelude/types/uint";
-import library "prelude/operators/index";
+import library "prelude/operators";
 import library "prelude/types/int";
-import library "prelude/operators/as";
+import library "prelude/types/maybe_unformed";
...
   private var size: i64;
+
+  // A view of the `size` bytes starting at `p`. The caller guarantees that
+  // they stay valid and unchanged for as long as the view is used.
+  fn UnsafeMake(p: Char*, size: i64) -> Self {
+    return {.ptr = p, .size = size};
+  }
 }
...
 impl forall [T: ImplicitAs(i64)] String as IndexWith(T) where .ElementType = Char {
-  fn At(self, subscript: T) -> Char = "string.at";
+  fn At(self, subscript: i64) -> Char = "string.at";
 }
+
+// Fork (ST-1, fork/string/plan.md): ... (lines 40-275 of §2.1, appended)
```

The complete file, byte for byte the prototype of every measurement in §0.2:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

package Core library "prelude/types/string";

import library "prelude/copy";
import library "prelude/default";
import library "prelude/destroy";
import library "prelude/types/char";
import library "prelude/types/uint";
import library "prelude/operators";
import library "prelude/types/int";
import library "prelude/types/maybe_unformed";

class String {
  fn Size(self) -> i64 { return self.size; }

  impl as Copy {
    fn Op(self) -> Self { return {.ptr = self.ptr, .size = self.size}; }
  }
  // TODO: This should be an array iterator.
  private var ptr: Char*;
  // TODO: This should be a word-sized integer.
  private var size: i64;

  // A view of the `size` bytes starting at `p`. The caller guarantees that
  // they stay valid and unchanged for as long as the view is used.
  fn UnsafeMake(p: Char*, size: i64) -> Self {
    return {.ptr = p, .size = size};
  }
}

impl String as UnformedInit {}

impl forall [T: ImplicitAs(i64)] String as IndexWith(T) where .ElementType = Char {
  fn At(self, subscript: i64) -> Char = "string.at";
}

// Fork (ST-1, fork/string/plan.md): byte-wise equality and ordering, the
// owning `StringBuf`, and concatenation with `+` and `+=`.

private fn PointerOffset[T: type](p: T*, n: i64) -> T* = "pointer.offset";
private fn FailStop(message: str) = "fail_stop";
private fn HeapAllocate(generic T: type, count: i64) -> MaybeUnformed(T*)
    = "heap.allocate";
private fn HeapFree[T: type](p: T*) = "heap.free";
private fn PointerIsNull[T: type](value: MaybeUnformed(T*)) -> bool
    = "pointer.is_null";

// Whether `a` and `b` hold the same bytes.
private fn BytesEqual(a: str, b: str) -> bool {
  let size: i64 = a.Size();
  if (size != b.Size()) {
    return false;
  }
  var i: i64 = 0;
  while (i < size) {
    if (a[i] != b[i]) {
      return false;
    }
    ++i;
  }
  return true;
}

// Lexicographic order on bytes compared as unsigned values, a proper prefix
// first: -1, 0 or 1 as `a` orders before, the same as, or after `b`.
private fn BytesCompare(a: str, b: str) -> i32 {
  let a_size: i64 = a.Size();
  let b_size: i64 = b.Size();
  var i: i64 = 0;
  while (i < a_size and i < b_size) {
    let a_byte: Char = a[i];
    let b_byte: Char = b[i];
    if (a_byte < b_byte) {
      return -1;
    }
    if (a_byte > b_byte) {
      return 1;
    }
    ++i;
  }
  if (a_size < b_size) {
    return -1;
  }
  if (a_size > b_size) {
    return 1;
  }
  return 0;
}

// A new heap block holding the bytes of `a` followed by those of `b`. A
// zero-byte request still yields a block (the "heap.allocate" lowering).
private fn JoinBytes(a: str, b: str) -> Char* {
  let a_size: i64 = a.Size();
  let b_size: i64 = b.Size();
  var storage: MaybeUnformed(Char*) = HeapAllocate(Char, a_size + b_size);
  if (PointerIsNull(storage)) {
    FailStop("carbon: heap allocation failed; terminating\n");
  }
  let block: Char* = storage unsafe as Char*;
  var i: i64 = 0;
  while (i < a_size) {
    *PointerOffset(block, i) = a[i];
    ++i;
  }
  var j: i64 = 0;
  while (j < b_size) {
    *PointerOffset(block, a_size + j) = b[j];
    ++j;
  }
  return block;
}

impl String as EqWith(String) {
  fn Equal(self, other: String) -> bool { return BytesEqual(self, other); }
  fn NotEqual(self, other: String) -> bool {
    return not BytesEqual(self, other);
  }
}

impl String as OrderedWith(String) {
  fn Less(self, other: String) -> bool {
    return BytesCompare(self, other) < 0;
  }
  fn LessOrEquivalent(self, other: String) -> bool {
    return BytesCompare(self, other) <= 0;
  }
  fn Greater(self, other: String) -> bool {
    return BytesCompare(self, other) > 0;
  }
  fn GreaterOrEquivalent(self, other: String) -> bool {
    return BytesCompare(self, other) >= 0;
  }
}

// An owning, heap-allocated byte string; `str` is its view. Not copyable: a
// copy is `StringBuf.Make(s)`. Not `UnformedInit`: `Destroy` runs
// unconditionally on `var` storage, as for `Buf`.
class StringBuf {
  // A new string holding a copy of the bytes of `s`.
  fn Make(s: str) -> Self {
    return {.ptr = JoinBytes(s, ""), .size = s.Size()};
  }
  // A new string holding the bytes of `a` followed by those of `b`.
  fn Concat(a: str, b: str) -> Self {
    return {.ptr = JoinBytes(a, b), .size = a.Size() + b.Size()};
  }
  fn Size(self) -> i64 { return self.size; }
  // A view of the bytes, valid until `self` is destroyed or appended to.
  fn AsStr(self) -> str { return String.UnsafeMake(self.ptr, self.size); }

  impl as Destroy {
    fn Op(ref self) { HeapFree(self.ptr); }
  }

  // Appends in a new block and then frees the old one, so `other` may be a
  // view of `self`.
  impl as AddAssignWith(str) {
    fn Op(ref self, other: str) {
      let block: Char* = JoinBytes(self.AsStr(), other);
      HeapFree(self.ptr);
      self.size = self.size + other.Size();
      self.ptr = block;
    }
  }

  private var ptr: Char*;
  private var size: i64;
}

impl StringBuf as ImplicitAs(str) {
  fn Convert(self) -> str { return self.AsStr(); }
}

impl StringBuf as AddAssignWith(StringBuf) {
  fn Op(ref self, other: StringBuf) { self += other.AsStr(); }
}

impl String as AddWith(String) where .Result = StringBuf {
  fn Op(self, other: String) -> StringBuf {
    return StringBuf.Concat(self, other);
  }
}

impl String as AddWith(StringBuf) where .Result = StringBuf {
  fn Op(self, other: StringBuf) -> StringBuf {
    return StringBuf.Concat(self, other.AsStr());
  }
}

impl StringBuf as AddWith(String) where .Result = StringBuf {
  fn Op(self, other: String) -> StringBuf {
    return StringBuf.Concat(self.AsStr(), other);
  }
}

impl StringBuf as AddWith(StringBuf) where .Result = StringBuf {
  fn Op(self, other: StringBuf) -> StringBuf {
    return StringBuf.Concat(self.AsStr(), other.AsStr());
  }
}

impl String as EqWith(StringBuf) {
  fn Equal(self, other: StringBuf) -> bool {
    return BytesEqual(self, other.AsStr());
  }
  fn NotEqual(self, other: StringBuf) -> bool {
    return not BytesEqual(self, other.AsStr());
  }
}

impl StringBuf as EqWith(String) {
  fn Equal(self, other: String) -> bool {
    return BytesEqual(self.AsStr(), other);
  }
  fn NotEqual(self, other: String) -> bool {
    return not BytesEqual(self.AsStr(), other);
  }
}

impl StringBuf as EqWith(StringBuf) {
  fn Equal(self, other: StringBuf) -> bool {
    return BytesEqual(self.AsStr(), other.AsStr());
  }
  fn NotEqual(self, other: StringBuf) -> bool {
    return not BytesEqual(self.AsStr(), other.AsStr());
  }
}

impl String as OrderedWith(StringBuf) {
  fn Less(self, other: StringBuf) -> bool {
    return BytesCompare(self, other.AsStr()) < 0;
  }
  fn LessOrEquivalent(self, other: StringBuf) -> bool {
    return BytesCompare(self, other.AsStr()) <= 0;
  }
  fn Greater(self, other: StringBuf) -> bool {
    return BytesCompare(self, other.AsStr()) > 0;
  }
  fn GreaterOrEquivalent(self, other: StringBuf) -> bool {
    return BytesCompare(self, other.AsStr()) >= 0;
  }
}

impl StringBuf as OrderedWith(String) {
  fn Less(self, other: String) -> bool {
    return BytesCompare(self.AsStr(), other) < 0;
  }
  fn LessOrEquivalent(self, other: String) -> bool {
    return BytesCompare(self.AsStr(), other) <= 0;
  }
  fn Greater(self, other: String) -> bool {
    return BytesCompare(self.AsStr(), other) > 0;
  }
  fn GreaterOrEquivalent(self, other: String) -> bool {
    return BytesCompare(self.AsStr(), other) >= 0;
  }
}

impl StringBuf as OrderedWith(StringBuf) {
  fn Less(self, other: StringBuf) -> bool {
    return BytesCompare(self.AsStr(), other.AsStr()) < 0;
  }
  fn LessOrEquivalent(self, other: StringBuf) -> bool {
    return BytesCompare(self.AsStr(), other.AsStr()) <= 0;
  }
  fn Greater(self, other: StringBuf) -> bool {
    return BytesCompare(self.AsStr(), other.AsStr()) > 0;
  }
  fn GreaterOrEquivalent(self, other: StringBuf) -> bool {
    return BytesCompare(self.AsStr(), other.AsStr()) >= 0;
  }
}
```

Compile verification (§0.2): copied over
`install-copy/lib/carbon/core/prelude/types/string.carbon`, `carbon compile
--phase=check` of any program reports nothing from core/ (M-2); the programs of
§2.4 compile, link and pass (M-12); the full suite holds 128 / 0 / 22 (M-12);
file_test changes exactly the goldens of §4 (M-10). Line facts the goldens
depend on: `class String` stays at :16, `class StringBuf` is at :141 (pinned by
`fail_buf_arg`'s prelude-located TODO, §4), `At` is at :37.

### §2.2 toolchain/check/cpp/export.cpp (+5 lines)

The hunk starts at :294, with no blank context line, so that prek's
trailing-whitespace hook cannot corrupt it; `git apply --check` of this block
passes against 80a11e7f0 (amended 2026-10-13, review fold: A-9 / B12):

```diff
--- a/toolchain/check/cpp/export.cpp
+++ b/toolchain/check/cpp/export.cpp
@@ -294,4 +294,9 @@
   auto* decl_context =
       ExportNameScopeToCpp(context, loc_id, class_info.parent_scope_id);
+  // Fork (ST-1, fork/string/plan.md D-ST-12): the parent scope could not be
+  // exported and that has been diagnosed, as the other callers check.
+  if (!decl_context) {
+    return nullptr;
+  }
   auto* record_decl = ExportClassToCppInDeclContext(
       context, decl_context, class_info, class_type.specific_id);
```

No new diagnostic kind (the TODO and `CppCallArgTypeNotSupported` exist), no
header change, no other caller affected: `MapToCppType` already maps a null
`TagDecl` to a null `QualType` (check/cpp/type_mapping.cpp:365-369), and
`ExportAndCompleteClassToCpp` already tests the pointer (export.cpp:313-321).
The record-insertion code after the call (:299-310) is skipped for the null
case, as in `ExportParameterizedClassToCpp` (:429-432). Syntax-checked and
format-checked (M-9), compiled and linked into a file_test that runs the whole
manifest without aborting (M-19, M-10; amended 2026-10-13, review fold: A-1).
Apply it with `git apply` or by hand.

### §2.3 Goldens (sources only: `// AUTOUPDATE`, no CHECK lines; R15/R16)

Eight new files (rev 2 adds
toolchain/check/testdata/interop/cpp/operators/fork_all_operands_conversion.carbon,
amended 2026-10-13, review fold: B4). Their TIP lines are what autoupdate
writes; the implementer may omit them and let autoupdate add them. The
prelude-dependent ones include min_prelude/full.carbon (D-ST-13); every positive
check split brackets its code with `//@dump-sem-ir-begin`/`end` (the SL-1 rule,
fork/slices/plan.md §4). Identifiers avoid the keyword list (a function named
`Copy` was renamed `Dup` after the measured dump showed `@Copy.loc7`). Each
source below is byte for byte the text the rev 2 fill of M-11 ran.

toolchain/check/testdata/string/compare.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/string/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/string/compare.carbon

// Fork (ST-1, fork/string/plan.md §4): byte-wise `EqWith` and `OrderedWith`
// on `str` and `Core.StringBuf`, all four operand pairs (D-ST-2, D-ST-3,
// D-ST-8).

// --- str_str.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Eq(a: str, b: str) -> bool { return a == b; }
fn Ne(a: str, b: str) -> bool { return a != b; }
fn Lt(a: str, b: str) -> bool { return a < b; }
fn Ge(a: str, b: str) -> bool { return a >= b; }
//@dump-sem-ir-end

// --- mixed.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn EqBufStr(a: Core.StringBuf, b: str) -> bool { return a == b; }
fn LtStrBuf(a: str, b: Core.StringBuf) -> bool { return a < b; }
fn GtBufBuf(a: Core.StringBuf, b: Core.StringBuf) -> bool { return a > b; }
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

fn Min[T: Core.Ordered & Core.Copy](a: T, b: T) -> T {
  return if a < b then a else b;
}

//@dump-sem-ir-begin
fn UseMin() -> str { return Min("pear", "apple"); }
//@dump-sem-ir-end
```

toolchain/check/testdata/string/string_buf.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/string/string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/string/string_buf.carbon

// Fork (ST-1, fork/string/plan.md §4): the owning `Core.StringBuf`
// (D-ST-4..7).

// --- concat.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Concat(a: str, b: str) -> Core.StringBuf { return a + b; }
fn Chain(a: str) -> Core.StringBuf { return a + a + a; }
fn Dup(s: Core.StringBuf) -> Core.StringBuf { return Core.StringBuf.Make(s); }
//@dump-sem-ir-end

// --- append.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Append(s: str) -> i64 {
  var b: Core.StringBuf = Core.StringBuf.Make(s);
  b += "!";
  b += b;
  return b.Size();
}
//@dump-sem-ir-end

// --- view.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn View(b: Core.StringBuf) -> str { return b; }
fn LetView(a: str) -> i64 {
  var c: Core.StringBuf = a + a;
  let v: str = c;
  return v.Size();
}
//@dump-sem-ir-end
```

toolchain/check/testdata/string/fail_string_buf.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/string/fail_string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/string/fail_string_buf.carbon

// Fork (ST-1, fork/string/plan.md §4): the pinned 0.1 limits of
// `Core.StringBuf` (D-ST-5, D-ST-6).

// --- fail_copy.carbon

library "[[@TEST_NAME]]";

fn C(s: Core.StringBuf) {
  var unused t: Core.StringBuf = s;
}

// --- fail_return_var.carbon

library "[[@TEST_NAME]]";

fn R() -> Core.StringBuf {
  var s: Core.StringBuf = Core.StringBuf.Make("x");
  return s;
}

// --- fail_unformed.carbon

library "[[@TEST_NAME]]";

fn U() {
  var unused u: Core.StringBuf;
}

// --- fail_view_to_owned.carbon

library "[[@TEST_NAME]]";

fn V(v: str) -> Core.StringBuf { return v; }
```

toolchain/check/testdata/interop/cpp/stdlib/string_buf.carbon (positive and
`fail_` splits in one CHECK golden, which file_test judges per split; the mock
header is string_view.carbon's; the `as_str` split binds the view to a `let`
before the call, because rev 1's `Cpp.Consume(b.AsStr());` aborts file_test
through the trunk bug of M-20, W-165; amended 2026-10-13, review fold: A-1):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/stdlib/string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/stdlib/string_buf.carbon

// Fork (ST-1, fork/string/plan.md §4): a `Core.StringBuf` reaches a C++
// `std::string_view` parameter through its explicit view `AsStr()` (D-ST-12),
// bound to a `let` first: a call result passed straight to a parameter of this
// mock `basic_string_view` crashes Clang, with or without ST-1 (W-165);
// passed directly, C++ overload resolution cannot see the Carbon
// `ImplicitAs(str)` conversion and the argument's type cannot be exported, so
// the call is diagnosed instead of crashing the compiler (D-ST-12).

// --- string_view.h

namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    template<typename T> struct char_traits {};

    template<typename CharT, typename Traits = char_traits<CharT>>
    class basic_string_view {
     public:
      basic_string_view() = default;
      size_t size() const { return size_; }

     private:
      const CharT* data_;
      size_t size_;
    };

    using string_view = basic_string_view<char>;
  }
}

auto Consume(std::string_view sv) -> void;

// --- as_str.carbon

library "[[@TEST_NAME]]";

import Cpp library "string_view.h";

//@dump-sem-ir-begin
fn F(b: Core.StringBuf) {
  let v: str = b.AsStr();
  Cpp.Consume(v);
}
//@dump-sem-ir-end

// --- fail_buf_arg.carbon

library "[[@TEST_NAME]]";

import Cpp library "string_view.h";

fn G(b: Core.StringBuf) {
  Cpp.Consume(b);
}
```

toolchain/check/testdata/interop/cpp/operators/fork_all_operands_conversion.carbon
(new in rev 2, fork-owned, beside upstream's operators.carbon whose source is
not edited: it keeps the "All operands conversion" TODO pinned with an operand
type that still has no `AddWith`, since ST-1 gives `str` one; amended
2026-10-13, review fold: B4):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu --clang-arg=-std=c++20
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/operators/fork_all_operands_conversion.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/operators/fork_all_operands_conversion.carbon

// Fork (ST-1, fork/string/plan.md §4): operators.carbon's "All operands
// conversion" split pins, with two `str` operands, the TODO that a C++
// `operator+` is not found through conversions of operands that are not C++
// classes. Since ST-1, `str + str` is Carbon concatenation, so that split now
// fails later, on its result; this split keeps the TODO pinned with `bool`,
// which has no `AddWith` impl (core/prelude/types/bool.carbon).

// --- plus_with_bool_conversion.h

class BoolConvertibleC {
 public:
  BoolConvertibleC(bool b);
};
auto operator+(BoolConvertibleC lhs, BoolConvertibleC rhs) -> BoolConvertibleC;

// --- fail_todo_import_plus_with_bool_conversion.carbon

library "[[@TEST_NAME]]";

import Cpp library "plus_with_bool_conversion.h";

fn F() {
  let b1: bool = true;
  let b2: bool = false;
  let unused c: Cpp.BoolConvertibleC = b1 + b2;
}
```

toolchain/lower/testdata/string/compare.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/string/compare.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/string/compare.carbon

// Fork (ST-1, fork/string/plan.md §4): comparisons call the prelude's impl
// functions, whose bodies are in the prelude object.

fn Eq(a: str, b: str) -> bool { return a == b; }
fn Lt(a: str, b: str) -> bool { return a < b; }
fn EqBufStr(a: Core.StringBuf, b: str) -> bool { return a == b; }
```

toolchain/lower/testdata/string/string_buf.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/string/string_buf.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/string/string_buf.carbon

// Fork (ST-1, fork/string/plan.md §4): `+` returns a `Core.StringBuf` whose
// declared `Destroy` impl runs at the end of the scope; the intermediate
// temporary of a chained `+` in a `var` initializer is destroyed at the end of
// the enclosing block, just before `s` (today's toolchain, ST-1 M-7); and a
// `Core.StringBuf` field of a class without a declared `Destroy` is destroyed
// by that class's synthesized destructor.

fn Concat(a: str, b: str) -> i64 {
  var s: Core.StringBuf = a + b;
  s += "!";
  return s.Size();
}

fn Chain(a: str) -> i64 {
  var s: Core.StringBuf = a + a + a;
  return s.Size();
}

class Holder {
  var text: Core.StringBuf;
}

fn Field(a: str) -> i64 {
  var h: Holder = {.text = a + a};
  return h.text.Size();
}
```

(Rev 2: the header comment states M-7's placement, which rev 1's comment
contradicted, and `Holder`/`Field` pin a `StringBuf` field's destruction;
amended 2026-10-13, review fold: A-6 / B6, B2.)

toolchain/lower/testdata/string/subscript.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/string/subscript.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/string/subscript.carbon

// Fork (ST-1, fork/string/plan.md §4): `str` subscripts convert to `i64`
// before "string.at" (D-ST-9): a literal subscript on a runtime `str` is an
// `i64` constant index, and a `u8` subscript is zero-extended.

fn Literal(s: str) -> char { return s[0]; }
fn Unsigned(s: str, i: u8) -> char { return s[i]; }
fn Signed(s: str, i: i64) -> char { return s[i]; }
```

Two existing goldens are REFILLED by autoupdate, sources untouched:
toolchain/check/testdata/operators/overloaded/string_indexing.carbon (D-ST-9,
measured +79/-33 CHECK lines) and
toolchain/check/testdata/interop/cpp/operators/operators.carbon, splits
`fail_todo_import_plus_with_string_view_conversion.carbon` (D-ST-7 plus D-ST-12)
and `fail_todo_rewrite_equal.carbon` (which receives the prelude-located
`SemanticsTodo` and a `.loc` renumbering; measured in M-10, converging on the
third autoupdate run; amended 2026-10-13, review fold: A-5, RR-N-4). The first
split keeps its name: it still fails, and its TODO (C++ operators found through
conversions of Carbon operands) is still open upstream, but this split no longer
exercises it: `s1 + s2` on `str` now has a Carbon meaning, so the conversion of
its result is what fails. The TODO stays pinned by the new fork-owned
fork_all_operands_conversion.carbon with `bool` operands (M-24), and the
divergence register of §2.6 records that the upstream split's subject changed
(amended 2026-10-13, review fold: A-5 / B4).

### §2.4 Conformance programs (bullet "Stdlib: String and string-literal types", R7)

fork/conformance/programs/stdlib/string_missing_ops.carbon, un-SKIPped: line 6
(`// SKIP:`) is deleted, the explanatory paragraph and the two body comments are
refreshed, the EXPECT lines are unchanged, and the body changes in one line,
:26 (`let c: str = a + b;` becomes `var c: Core.StringBuf = a + b;`, D-ST-14;
the un-SKIP commit's message discloses it in the R6 template's words; amended
2026-10-13, review fold: B1):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   1
//   4
//
// Written test-first for the String bullet and un-SKIPped at ST-1
// (fork/string/plan.md; working slice: string_basic.carbon). `a == b` is the
// byte-wise `String as EqWith(String)` impl and `a + b` is `String as
// AddWith(String)`, whose result is the owning `Core.StringBuf`, so `c` is a
// `var` that owns it; both are in core/prelude/types/string.carbon. At the
// un-SKIP the test-first `let c: str = a + b;` became
// `var c: Core.StringBuf = a + b;`, the EXPECT unchanged: a `str` view of that
// temporary would be used after its full-expression, which the fork's design
// rejects (F-013 D-SAFE-12) and which this toolchain allows only because it
// destroys a declaration's temporaries at the end of the block.

import Core library "io";

fn Run() -> i32 {
  let a: str = "hi";
  let b: str = "hi";
  // `String as EqWith(String)`: byte-wise.
  Core.Print(if a == b then 1 else 0);
  // `String as AddWith(String)`: concatenation into a `Core.StringBuf`.
  var c: Core.StringBuf = a + b;
  Core.Print(c.Size() as i32);
  return 0;
}
```

fork/conformance/programs/stdlib/string_ordering_diff.carbon and its oracle
string_ordering_diff.diff.cpp (clang-format 21.1.8 clean, M-9's command):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
//
// Differential pair: string_ordering_diff.diff.cpp is the equivalent C++17
// program over `std::string_view` and `std::string`, whose comparisons are
// `char_traits<char>::compare`, a byte-wise comparison of `unsigned char`
// values and then of lengths; the runner requires byte-identical exit code
// and stdout, so C++ is the oracle for every line (no EXPECT-STDOUT here, the
// arith_widths_diff precedent). Carbon side: `==`/`!=` are `String as
// EqWith(String)` and `<`/`<=`/`>`/`>=` are `String as OrderedWith(String)`,
// lexicographic on bytes compared as unsigned values with a proper prefix
// first; `+` builds a `Core.StringBuf`, which compares with `str` in both
// operand orders (core/prelude/types/string.carbon, fork/string/plan.md).
// Core.Print lowers to printf("%d\n", x), mirrored by the C++ side.

import Core library "io";

fn B(b: bool) -> i32 { return if b then 1 else 0; }

fn Run() -> i32 {
  // Equality: the same bytes, one differing byte, different lengths, empty.
  Core.Print(B("carbon" == "carbon"));
  Core.Print(B("carbon" == "carbOn"));
  Core.Print(B("carbon" != "carbo"));
  Core.Print(B("" == ""));
  // Ordering: the first differing byte decides, else the shorter is first.
  Core.Print(B("apple" < "apricot"));
  Core.Print(B("app" < "apple"));
  Core.Print(B("apple" <= "app"));
  Core.Print(B("Zebra" < "apple"));
  Core.Print(B("b" > "abc"));
  Core.Print(B("abc" >= "abc"));
  // Bytes are unsigned: 0xC3, the first byte of UTF-8 "é", sorts after 'z'.
  Core.Print(B("\xC3\xA9" > "z"));
  // An owning concatenation compares with views in both operand orders.
  var joined: Core.StringBuf = "app" + "le";
  Core.Print(joined.Size() as i32);
  Core.Print(B(joined == "apple"));
  Core.Print(B("apricot" > joined));
  Core.Print(B(joined < Core.StringBuf.Make("apples")));
  return 0;
}
```

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// C++17 oracle for string_ordering_diff.carbon: the same comparisons over
// std::string_view and std::string, printed as printf("%d\n", x).

#include <cstdio>
#include <string>
#include <string_view>

static auto B(bool b) -> int { return b ? 1 : 0; }

auto main() -> int {
  using std::string_view;
  std::printf("%d\n", B(string_view("carbon") == string_view("carbon")));
  std::printf("%d\n", B(string_view("carbon") == string_view("carbOn")));
  std::printf("%d\n", B(string_view("carbon") != string_view("carbo")));
  std::printf("%d\n", B(string_view("") == string_view("")));
  std::printf("%d\n", B(string_view("apple") < string_view("apricot")));
  std::printf("%d\n", B(string_view("app") < string_view("apple")));
  std::printf("%d\n", B(string_view("apple") <= string_view("app")));
  std::printf("%d\n", B(string_view("Zebra") < string_view("apple")));
  std::printf("%d\n", B(string_view("b") > string_view("abc")));
  std::printf("%d\n", B(string_view("abc") >= string_view("abc")));
  std::printf("%d\n", B(string_view("\xC3\xA9") > string_view("z")));
  std::string joined = std::string("app") + "le";
  std::printf("%d\n", static_cast<int>(joined.size()));
  std::printf("%d\n", B(joined == string_view("apple")));
  std::printf("%d\n", B(string_view("apricot") > string_view(joined)));
  std::printf("%d\n", B(joined < std::string("apples")));
  return 0;
}
```

fork/conformance/programs/stdlib/string_buf_lifetime.carbon (rev 2: the header
claims only what the EXPECT lines observe, and names where freeing is pinned;
amended 2026-10-13, review fold: B2):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   Hello, Carbon!
//   14
//   abcabc
//   6
//   field
//   1
//   Hello, Carbon!
//
// The owning string `Core.StringBuf` (core/prelude/types/string.carbon,
// fork/string/plan.md): a heap block freed by its declared `Destroy` impl,
// not copyable (a copy is `Core.StringBuf.Make(s)`), viewed as `str` through
// `ImplicitAs(str)`. What the expected lines observe: a string built in a
// callee leaves it through `returned var` with its bytes intact (a `return`
// of a plain `var` would copy, which `StringBuf` rejects); `s += s` appends
// the string's own bytes; a `StringBuf` held in a field reads back; and an
// explicit copy is independent of its source. That blocks are freed is not
// observable here: the destroy calls are pinned by
// toolchain/lower/testdata/string/string_buf.carbon, and the allocation
// balance is the plan's manual shim check (fork/string/plan.md §8). Expected
// lines: "Hello, " (7 bytes) + "Carbon" (6) + "!" (1) = 14 bytes; "abc" +
// "abc"; the field's bytes; the copy gained a "?" so it differs (1); the
// source is unchanged.

import Core library "io";

class Greeting {
  var text: Core.StringBuf;
}

fn PrintStr(s: str) {
  let n: i64 = s.Size();
  var i: i64 = 0;
  while (i < n) {
    Core.PrintChar(s[i]);
    ++i;
  }
  Core.PrintChar('\n');
}

fn MakeGreeting(who: str) -> Core.StringBuf {
  returned var g: Core.StringBuf = "Hello, " + who;
  g += "!";
  return var;
}

fn Run() -> i32 {
  var g: Core.StringBuf = MakeGreeting("Carbon");
  PrintStr(g);
  Core.Print(g.Size() as i32);

  var s: Core.StringBuf = Core.StringBuf.Make("abc");
  s += s;
  PrintStr(s);
  Core.Print(s.Size() as i32);

  var holder: Greeting = {.text = Core.StringBuf.Make("field")};
  PrintStr(holder.text);

  var copy: Core.StringBuf = Core.StringBuf.Make(g);
  copy += "?";
  Core.Print(if copy != g then 1 else 0);
  PrintStr(g);
  return 0;
}
```

fork/conformance/programs/stdlib/string_concat_loop.carbon (rev 2: the header
no longer claims an unobservable one-block-at-a-time property; amended
2026-10-13, review fold: B2):

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   Carbon 0.1
//   10
//   1024
//   1
//   abcabcabc!
//
// Concatenation in loops (core/prelude/types/string.carbon,
// fork/string/plan.md). `acc += w` appends: each append allocates the joined
// block and frees the previous one (string.carbon's `AddAssignWith(str)`; the
// allocation balance is not observable here and is the plan's manual shim
// check, fork/string/plan.md §8). Expected lines: "Car" + "bon" + " " + "0.1"
// (10 bytes); ten self-appends double one byte to 2^10 = 1024 bytes, every one
// 'z' (1); a chained `+` builds "abc" three times plus "!" left to right.
// Loops append with `+=`, never `acc = acc + w;`: assignment does not yet
// destroy the value it overwrites (check/handle_operator.cpp TODO), so that
// spelling would leak the previous block (fork/string/plan.md residue W-160).

import Core library "io";

fn PrintStr(s: str) {
  let n: i64 = s.Size();
  var i: i64 = 0;
  while (i < n) {
    Core.PrintChar(s[i]);
    ++i;
  }
  Core.PrintChar('\n');
}

fn Run() -> i32 {
  let words: array(str, 4) = ("Car", "bon", " ", "0.1");
  var acc: Core.StringBuf = Core.StringBuf.Make("");
  for (w: str in words) {
    acc += w;
  }
  PrintStr(acc);
  Core.Print(acc.Size() as i32);

  var big: Core.StringBuf = Core.StringBuf.Make("z");
  var k: i32 = 0;
  while (k < 10) {
    big += big;
    ++k;
  }
  Core.Print(big.Size() as i32);
  let view: str = big;
  var all_z: bool = true;
  var i: i64 = 0;
  while (i < view.Size()) {
    if (view[i] != 'z') {
      all_z = false;
    }
    ++i;
  }
  Core.Print(if all_z then 1 else 0);

  let piece: str = "abc";
  var chained: Core.StringBuf = piece + piece + piece + "!";
  PrintStr(chained);
  return 0;
}
```

fork/conformance/programs/stdlib/string_subscripts.carbon:

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: String and string-literal types
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   Cn
//   X
//   h
//
// `str` subscripts after ST-1 (fork/string/plan.md): `String as IndexWith(T)`
// for every `T: ImplicitAs(i64)` now takes its subscript as `i64`, so the
// subscript converts before the "string.at" builtin sees it. Two shapes this
// pins: an integer literal subscript on a runtime `str` (`s[0]`), which used
// to crash lowering ("GEP indexes must be integers"; string_basic.carbon's
// caution), and a `u8` subscript above 127, which used to reach the
// `getelementptr` as an 8-bit index that LLVM sign-extends, so `s[200 as u8]`
// read 56 bytes BEFORE the string. Expected lines: "Carbon"[0] and [5]; byte
// 200 of 25 copies of "abcdefgh" followed by "X" is the "X"; byte 199 is the
// last "h".

import Core library "io";

fn At(s: str, i: u8) -> char { return s[i]; }

fn Run() -> i32 {
  let s: str = "Carbon";
  Core.PrintChar(s[0]);
  Core.PrintChar(s[5]);
  Core.PrintChar('\n');

  var long: Core.StringBuf = Core.StringBuf.Make("");
  var k: i32 = 0;
  while (k < 25) {
    long += "abcdefgh";
    ++k;
  }
  long += "X";
  let i: u8 = 200;
  Core.PrintChar(At(long, i));
  Core.PrintChar('\n');
  let j: u8 = 199;
  Core.PrintChar(At(long, j));
  Core.PrintChar('\n');
  return 0;
}
```

fork/conformance/programs/stdlib/string_basic.carbon: lines 13-26 (the comment
block between the EXPECT block and `import Core library "io";`) are replaced by
the following, the body and EXPECT untouched (§0.3 item 4):

```carbon
// Working slice of the String bullet: string literals have type `str`
// (Core.String, a non-owning {Char*, i64} — core/prelude/types/string.carbon),
// `.Size()` returns i64, `s[i]` returns `char` through the `String as
// IndexWith` impl ("string.at" builtin, toolchain/check/testdata/operators/
// overloaded/string_indexing.carbon), and `str` is Copy. Chars print one at a
// time with Core.PrintChar (inline putchar), the same loop as Core.PrintStr's
// body (core/io.impl.carbon), because PrintStr itself does not link here
// (README).
//
// The indexes below are `i64`-typed, as written before ST-1, when a bare
// literal subscript on a runtime `str` crashed lowering; since ST-1 the
// subscript converts to `i64` first (fork/string/plan.md D-ST-9,
// string_subscripts.carbon). Comparison, concatenation and the owning
// `Core.StringBuf` are exercised by string_missing_ops.carbon and the other
// string_* programs.
```

Then `python3 fork/conformance/runner.py --update-readme-table` (the README
program table gains four rows and string_missing_ops' row turns from SKIP to
run) and `--self-test` (R7).

### §2.5 Docs (D-ST-15; dated amendments, never rewrites)

-   **docs/design/strings.md (new, normative).** Status line "Fork design
    (F-014, <date>): the string types as implemented; toolchain status: ST-1
    landed <date>" (amended 2026-10-13, review fold: B12). Sections: Overview
    (the two types, §1.1's table, the `str` keyword and the `Core.String`/`Core.Str`
    naming note with p006177:147-154); Comparison (§1.2, with the unsigned-byte
    order and its `char_traits<char>` parity); Concatenation (§1.4, with the
    self-aliasing append `s += s` stated as accepted and memory-safe today and
    rejected by F-013's T4 with M8 once W-148 lands, and `s +=
    Core.StringBuf.Make(s);` as the spelling that stays valid; amended
    2026-10-13, review fold: RR-N-1); Ownership and lifetime (§1.3, including
    `returned var`, and the view rule of D-ST-6 stated as the design: a view of
    a temporary is valid until the end of its full-expression, F-013 D-SAFE-12,
    with values.md:168 cited as upstream's open question; the block-scoped
    destruction of M-7 is described as today's toolchain behavior that programs
    must not rely on, and the rule "a function returning `str` never returns a
    `+` result or a local `StringBuf`; it returns `Core.StringBuf`" is stated
    with M-21's `Join` as its example; amended 2026-10-13, review fold: A-2,
    A-11 / B1); Subscripts (§1.5); Interoperability (§1.6); 0.1 limits
    (W-160..W-163 and W-165..W-167 by title, each with its break condition, plus
    UA-2's W-126 and UA-1's W-122 by reference; W-167 is stated as applying to
    `Core.Buf` too; amended 2026-10-13, review fold: A-2, A-3, A-10; W-164 joins
    the list, and Comparison's "generic code sees `str` as `Core.Ordered`" names
    it with the statement-form workaround, because the `if`-expression `Min` of
    compare.carbon's `generic.carbon` split crashes lowering when a reader
    compiles it; amended 2026-10-13, implementation review fold: RV1-3);
    Alternatives considered (§7's A-1..A-8); References (README.md String types,
    string_literals.md, comparison_operators.md, arithmetic.md, p006177,
    milestones.md:202). Every API line in it is copied from §2.1 and diffed
    against the landed prelude (R27); every example in it binds a `var` owner,
    never a `str` view of a temporary (amended 2026-10-13, review fold: A-11),
    and appends a copy of a string to itself, never `s += s` (amended
    2026-10-13, review fold: RR-N-1).
-   **docs/design/README.md**, after :634 ("There is an implicit conversion ...
    from `String` to `StringView`."): a blockquote "**Fork amendment
    (<date>, F-014).** In the fork the view is `str`, the prelude class
    `Core.String` (the interop design's `Core.Str`), and the owning type is
    `Core.StringBuf`; `==`, `!=`, `<`, `<=`, `>` and `>=` compare bytes, `+`
    concatenates into a new `Core.StringBuf` and `+=` appends.", ending in a
    link to strings.md titled "Strings". No heading is added, so the README's
    table of contents does not change.
-   **docs/design/expressions/arithmetic.md**, after :188 (the end of the
    Strings TODO paragraph, :186-188; amended 2026-10-13, review fold: A-7): a
    blockquote "**Fork amendment (<date>, F-014):** strings are library
    types, and `+` concatenates them: on `str` and `Core.StringBuf` operands it
    returns a new `Core.StringBuf`, and `+=` appends.", ending in a link to
    ../strings.md titled "Strings". The TODO line stays, as upstream's.
-   **docs/design/interoperability/README.md**, at the end of the
    `std::string_view` and `str` subsection (before its References, :304):
    "**Fork amendment (<date>, F-014).** The owning `Core.StringBuf` has no
    C++ mapping; it reaches a `std::string_view` parameter through its view,
    `Cpp.F(s.AsStr())`, because C++ overload resolution does not see Carbon
    conversions (W-161).", ending in a link to
    ../strings.md#interoperability titled "Strings", as its two siblings end
    (amended 2026-10-13, implementation review fold: ST1-IR2-7). The three
    amendments carry the landing date, not this plan's (amended 2026-10-13,
    review fold: B12).

### §2.6 Records (commit 5, after verification)

-   **fork/inventory/work-items.json, W-057:** title prefixed "ST-1
    (LANDED <date>): ", kind `implemented`; evidence:
    core/prelude/types/string.carbon (the §2.1 line ranges as landed),
    check/cpp/export.cpp (the null check), the eight new goldens and the
    two refilled ones, the five programs; notes: what landed by D-ST
    number, §0.3 items 1-2 as corrected, "not prelude-only: one toolchain
    null check", and the string_missing_ops line 26 repair (D-ST-14). Where
    it cites the decision-log entry, it quotes the heading text without the
    date, double-quoted as rows 79 and 82 do: "ST-1 / F-014: str comparison,
    Core.StringBuf, concatenation" (amended 2026-10-13, implementation review
    fold: ST1-IR2-3).
-   **New items W-160..W-167**, each `{id, kind, title, subsystem, size, bullet,
    evidence, blocked_by, notes}` with the mechanism and the break condition
    (amended 2026-10-13, review fold: A-1, A-2, A-3, A-10, B3): W-160
    (`todo-stub`, toolchain/check handle_operator.cpp, M, bullet "Type system:
    User-defined types (classes)", because the mechanism leaks for every class
    with a `Destroy`, `Core.Buf` included; evidence handle_operator.cpp:98-103
    and :119-120, assignment.md:176-184, M-5, M-22; mechanism: build the
    destroy of the old value before the right-hand side, or route `=` through
    `AssignWith`); W-161 (`missing-feature`, toolchain/check/cpp, M, bullet
    "Type system: C++ interop — importing C++ types / exporting Carbon types";
    evidence export.cpp:139-142 (W-049's TODO), M-9; mechanism: a `std::string`
    mapping or a thunk-side conversion, and Carbon conversions in
    `InventClangArg`; notes: the TODO of a direct `Core.StringBuf` argument is
    diagnosed once per use, at string.carbon:141, because §2.2's null check
    records no failed export and every use re-runs `ExportNameScopeToCpp`, so
    this item deduplicates the TODO or caches the failure (amended
    2026-10-13, implementation review fold: RV1-6)); W-162
    (`missing-feature`, lower/handle_call.cpp
    `StringAt` arm, S, bullet String; evidence lower/handle_call.cpp:422-448,
    D-SL-4, M-6; mechanism: the `fail_stop` sequence in the lowering arm;
    `blocked_by: []`, notes "related: W-146, the same stage-2 shape for
    arrays; not covered by W-146's title, which names arrays and division
    only"); W-163 (`missing-feature`, sem_ir builtins + eval, S, bullet String;
    evidence M-14); W-164 (`toolchain-defect`, the kind of the W-121
    precedent for a crash, toolchain/lower, M, bullet "Generics: generic
    functions and types"; evidence M-15, the PHI assertion in
    `HandleInst(FunctionContext&, InstId, BranchWithArg)`); W-165
    (`toolchain-defect`, toolchain/check/cpp overload_resolution.cpp, S,
    bullet "Stdlib C++ interop: transparent non-owning string mapping";
    evidence M-20's mock-header reproducer `fn Mk() -> str { return "a"; } fn
    F() { Cpp.Consume(Mk()); }`, Clang's assertion text, overload_resolution.cpp
    :157-172 and :199, upstream-trunk 62f1cc6a3 :156-199; notes: the real
    libc++ `<string_view>` is unaffected; mechanism: require the parameter
    type to be complete, or test `hasDefinition()`, before
    `hasMoveConstructor()`); W-166 (`missing-feature`, title "a `str` view of
    a `Core.StringBuf` can outlive its owner", toolchain/check (the loan
    checker), M, bullet "Project: detailed and concrete design for safe Carbon
    (type/init/spatial/temporal/mutation + safe-Rust-interop analysis)", the
    bullet SAFE-1 files W-148 under; evidence M-21's four shapes (a `-> str`
    function returning a `+` result or a local owner, a `str` field initialized
    from a temporary, a view held across `+=`), D-ST-6, and a fifth shape, a
    `+` result assigned to an existing `str` variable: `var w: str = "";`,
    then `w = "ef" + "gh";` and one more 4-byte `Core.StringBuf.Make`, prints
    `YYYY`, not `efgh` (shim `malloc=5 free=4 bad=0`; amended 2026-10-13,
    implementation review fold: RV1-2); notes: the shapes are examples, not an
    exhaustive list; `blocked_by:
    ["W-148"]` when W-148 is on trunk at discharge, else the dependency in the
    notes); W-167 (`missing-feature`, title "struct-literal construction of a
    class bypasses private-field access control", toolchain/check, S, bullet
    "Type system: User-defined types (classes)"; evidence classes.md:2156-2159,
    M-17's Forge reproducer for `Core.StringBuf` and `Core.Buf(i32)`, the
    shim's `bad=1`).
-   **W-144 (SAFE-1's, if on trunk at discharge):** its evidence gains
    `StringBuf.AsStr`, `StringBuf as ImplicitAs(str)`'s `Convert` (the view
    producers that need `bound self`) and `String.UnsafeMake` (an `UnsafeMake`
    for the `unsafe fn Make` rename), at their landed string.carbon lines; if
    PR 53 has not landed, the same three go into the ORCHESTRATION note of the
    SAFE-1 reconciliation below (amended 2026-10-13, review fold: A-2 / B1).
    It also gains the interface declaration `ImplicitAs(Dest).Convert`
    (core/prelude/operators/as.carbon:23), with `As(Dest).Convert` (:18) and
    `UnsafeAs(Dest).Convert` (:13) for the workaround blankets at :27-34, as
    needing `bound self` beside `IndexWith.At` and `Copy.Op`: by F-013 T5(e)
    an impl may drop but not add `bound`, so without it the `Convert` impl
    cannot keep the loan (D-ST-11; the same fallback applies if PR 53 has not
    landed; amended 2026-10-13, review fold: RR-N-2).
-   **fork/gap-analysis.md:** row 77 (re-read its line) → DONE with the text
    below; the header counts as a DELTA (DONE +1, PARTIAL −1) applied to
    whatever the header reads at rebase, and its scoreboard sentence written
    in CM-1's words: "(reconciled <date> against the expected conformance
    scoreboard — <P> PASS / 0 FAIL / <S> SKIP over <N> programs, <B>/56
    bullets PASS, stated as expected, not of record (Actions disabled) — and
    the fork/inventory/work-items.json ledger; ...)" (amended 2026-10-13,
    review fold: B5); §W9 "Depends on" → "for the Optional half only" (§0.3
    item 6) and its paragraph's "owning/comparable String and a designed
    (non-placeholder) Optional remain" → "comparison, concatenation and the
    owning `Core.StringBuf` landed at ST-1 (W-057 DISCHARGED <date>); a designed
    (non-placeholder) Optional remains".
-   Row 77's new text: "DONE | ST-1 landed (W-057 DISCHARGED <date>,
    fork/string/plan.md, decision-log "ST-1 / F-014: str comparison,
    Core.StringBuf, concatenation"): string literals are `str` (`Core.String`,
    the non-owning `{Char*, i64}` view, core/prelude/types/string.carbon) with
    byte-wise `==`/`!=` and lexicographic unsigned-byte `<`/`<=`/`>`/`>=`; the
    owning `Core.StringBuf` (a heap block freed by its declared `Destroy`; not
    copyable, `Core.StringBuf.Make(s)` copies; not `UnformedInit`) converts
    implicitly to `str`; `+` on `str` and `Core.StringBuf` operands builds a new
    `Core.StringBuf` and `+=` appends; `str` subscripts convert to `i64` before
    `"string.at"` (a literal subscript on a runtime string no longer crashes
    lowering; a `u8` above 127 no longer reads before the string). 0.1 limits,
    each a filed item: language-wide, `s = t` leaks the overwritten block of
    any class with a `Destroy`, a `Core.StringBuf` included (W-160), a class
    that declares its own `Destroy` does not destroy a `Core.StringBuf` field
    (W-126), struct-literal construction bypasses private-field access, so a
    forged `Core.StringBuf` can free a non-heap pointer (W-167), and an `if`
    expression with a `Core.StringBuf` temporary in an arm is a semantics TODO
    (W-122); a `str` view of a `Core.StringBuf` can outlive its owner with no
    diagnostic until SAFE-1's loan checker (W-166, W-148): a function
    returning `str` must not return a `+` result or a local `Core.StringBuf`;
    no `std::string` mapping, a `Core.StringBuf` reaches C++ through `AsStr()`
    (W-161); `str` subscripts are not bounds-checked at run time (W-162);
    string comparisons are not compile-time constants (W-163). Conformance:
    6/6 programs PASS (stdlib/string_basic, string_missing_ops SKIP -> PASS,
    string_ordering_diff with a C++17 oracle, string_buf_lifetime,
    string_concat_loop, string_subscripts) — EXPECTED, not of record:
    container run <date> on the carbonbuild toolchain of <sha> (scoreboard
    generated <timestamp>), <P>/0/<S> over <N>; floor of
    record <the base's scoreboard totals and run, re-read at rebase; today
    128/0/22, run 37402970811>; the hosted run R9 requires is pending with no
    dispatch date (Actions disabled)." (amended 2026-10-13, review fold: A-2,
    A-3, A-4 / B3, A-10, B5). If UA-2 has not landed at ST-1's rebase, W-126
    is named by its title without the id and is not re-filed. The
    decision-log citation is the entry's heading text without the date,
    double-quoted as rows 79 and 82 cite theirs, so a grep finds it (rev 3
    cited a string that matched no heading); the run is cited by toolchain
    sha, the scoreboard's `generated` timestamp and its totals, never by an
    output directory, because the container runs write to session scratch
    directories that do not survive the session (amended 2026-10-13,
    implementation review fold: ST1-IR2-3, RV1-5 / ST1-IR2-4).
-   **Row 41** ("Type system: User-defined types (classes)"; re-read its
    line, :41 here and :42 to :45 on the cmake, safe and sc branches, R7)
    stays DONE, and its text "access control fully checked and lowered"
    becomes "access control checked for member access (struct-literal
    construction is not: W-167, classes.md:2156-2159) and lowered", because
    W-167 falsifies "fully checked". W-160 is listed in the ledger only, as
    W-164 and W-165 are for rows 51 and 81: the row's text makes no claim
    about assignment. No header count changes (amended 2026-10-13, review
    fold: RR-N-3).
-   **fork/decision-log.md:** a new entry immediately above the newest landed
    entry, which follows "### Full autonomy and the throughput protocol
    (2026-09-27)" (:2843-2862): today that is :2863 "### SL-2: std::span ↔
    Core.Slice mapping, owning-container views (2026-10-05)", and after PR 52
    or 53 lands it is whichever of their entries is then first there (both
    insert at :2863); re-read at rebase (the top of "Decided", :20-22, is the
    oldest material, V-1..3). Heading, in the SAFE-1 precedent's shape: "###
    ST-1 / F-014: str comparison, Core.StringBuf, concatenation (<date>)"
    (amended 2026-10-13, review fold: A-8 / B5). SL-1's entry (:3747) is the
    content's shape: the bullet flip, the commits, what landed by mechanism,
    D-ST-1..16 by number with their break conditions, the string_missing_ops
    line 26 repair in the R6 template's words (B1), the not-of-record status
    of the conformance totals, and the "_V-3a divergence-risk register
    entries_" paragraph: the fork-local name
    `Core.StringBuf` (README.md:629's owning `String`, p006177's `Core.Str`
    view: on upstream's rename, `StringBuf` takes the owning type's name); `+`
    on strings decides issue 457 for the fork; string.carbon:12, :14 and :37
    edit upstream lines and :26-31 insert into upstream's class (on an upstream
    edit of those lines, keep both and re-run M-10); export.cpp's null check
    (drop it when upstream adds one); operators.carbon's
    `fail_todo_import_plus_with_string_view_conversion` split now pins a
    different failure than upstream's and no longer exercises its own TODO, and
    its `fail_todo_rewrite_equal` split carries the prelude-located
    `SemanticsTodo` (keep the fork's CHECK lines at the merge, re-run
    autoupdate); the fork-owned fork_all_operands_conversion.carbon pins that
    TODO instead (when upstream implements C++ operator lookup through operand
    conversions, it refills and is renamed or removed with upstream's split)
    (amended 2026-10-13, review fold: A-5 / B4). One sentence of the entry
    says that two of §4's key lines were quoted inexactly by this plan and
    are amended at landing (the generic `Min` call's `to %.loc9_16.1`, and
    the `zext` one call deeper, in `FromUInt`), with no golden change
    (amended 2026-10-13, implementation review fold: RV1-1 / ST1-IR2-9).
-   **fork/ORCHESTRATION.md:** the Branches table row for
    `claude/carbon-fork-0-1-st`, the "Last updated" / "Later on" stamp
    paragraph (PR, verification record, the not-run list) and the Scoreboard
    subsection (amended 2026-10-13, review fold: B5). Before commit 5, trunk
    9d3ca60a3 (fork/ORCHESTRATION.md only: the id reservations at :69-75 and
    the `claude/carbon-fork-0-1-st` Branches row at :413) is merged into the
    branch with a merge commit, never a rebase (AGENTS.md; the EV-1
    precedent dff212ccc), so that commit 5 edits trunk's existing st row in
    place instead of adding a second one, and cites the reservation lines
    from the merged tree. Commit 5's ORCHESTRATION note (the "Next actions"
    for ST-1's merge) also carries: (1) the landing-date stamps to re-stamp
    in a new commit at the merge if the merge date differs from the one
    written, namely strings.md's status line (:29-30), the three Fork
    amendment lines (docs/design/README.md:636,
    docs/design/expressions/arithmetic.md:190,
    docs/design/interoperability/README.md:303), W-057's "LANDED <date>"
    title, row 77's "DISCHARGED <date>", the §W9 paragraph's "DISCHARGED
    <date>" and the decision-log heading's date; (2) that strings.md cites
    W-126 (filed on the UA-2 branch only) and W-148 (on the SAFE-1 branch
    only) on the assumption that PR 51 and PR 53 merge before ST-1, the
    ORCHESTRATION merge order, and that either id is replaced by its item's
    title in a new commit if its PR has not merged by then; (3) the fresh id
    scan below (amended 2026-10-13, implementation review fold: RV1-4 /
    ST1-IR2-2, ST1-IR2-5, ST1-IR2-6).
-   **Id re-scan, immediately before commit 5 writes the ledger:** the
    maximum `W-` id of fork/inventory/work-items.json on trunk and on every
    local and `origin` `claude/carbon-fork-0-1-*` ref, quoted in commit 5's
    message and the landed notes (the fix round's scan, 68 refs: trunk
    W-125, ua2 W-127, cmake W-133, safe W-150, sc W-151, ev W-155; W-160 to
    W-167 unfiled on every ref). If re-allocation triggers, the same commit
    renumbers the residue ids where they are already written:
    docs/design/strings.md (W-160 to W-167), the interoperability README's
    amendment (W-161) and string_concat_loop.carbon's header (W-160)
    (amended 2026-10-13, implementation review fold: ST1-IR2-5).
-   **SAFE-1 reconciliation** (amended 2026-10-13, review fold: B1). If PR 53
    has landed first (the ORCHESTRATION merge order), ST-1 makes these edits at
    its rebase; otherwise they go, verbatim, into ORCHESTRATION's "Next
    actions" for SAFE-1's rebase: (1) under EX-TM-7b's outcome
    (temporal_safety.md:831-840 on the safe branch), a dated ST-1 amendment:
    "Measured (ST-1 M-7, <date>): today's toolchain destroys a declaration
    initializer's temporaries at the end of the enclosing block, so this `v[0]`
    reads the live block (it prints 7 after a second `Make(4, 9)`); the
    design's loan still ends at the full-expression, and the next statement's
    use is `StrictBorrowOfTemporary`"; (2) dated amendments to
    spatial_safety.md SP2's one-gap list (:130-149) and to :433-438: `str`
    subscripts through the `"string.at"` builtin are unchecked (W-162), so a
    read through `Core.String` is not one of SP2's checked shapes; (3)
    initialization_safety.md:103-104's `types/string.carbon :28` becomes `:34`;
    (4) the W-144 evidence item above; (5) strings.md states D-SAFE-12 as the
    view rule (§2.5); (6) dated amendments to spatial_safety.md SP3 (:159-201)
    and to temporal_safety.md T2's "Copies preserve loans" paragraph
    (:264-273): the interface declaration `ImplicitAs(Dest).Convert`
    (core/prelude/operators/as.carbon:23), with `As(Dest).Convert` and
    `UnsafeAs(Dest).Convert` for the workaround blankets at :27-34, carries
    `bound self` per T5(e), beside `IndexWith.At` and `Copy.Op`, because an
    owner-to-view `Convert` (`Slice(T) as ImplicitAs(Slice(const T))`'s at
    slice.carbon:80-84, `StringBuf as ImplicitAs(str)`'s) creates a loan
    rather than preserving one, so T2's "every `ImplicitAs` impl is not a
    loan boundary" reads such a `Convert` as a `bound self` producer (amended
    2026-10-13, review fold: RR-N-2); (7) under T4 (temporal_safety.md:303-317),
    a dated ST-1 example: "`s += s;` on a `Core.StringBuf` is
    `StrictSharedBorrowInvalidated`: the by-value `other` is a shared loan on
    `s` (M8) and the `ref self` call invalidates `s` (M3(d)); it is
    memory-safe in today's toolchain, and the fork's spelling is `s +=
    Core.StringBuf.Make(s);`", and, if W-148 is on trunk at discharge, its
    notes name D-ST-14's four expected trips (amended 2026-10-13, review fold:
    RR-N-1).
-   **Cross-branch re-cites, conditional:** if SAFE-1 (PR 53) has landed first,
    its citations of string.carbon:16-27 and :16-28
    (docs/design/safety/mutation_safety.md:312, rust_interop.md:202,
    temporal_safety.md:736 and :960) become :16-32 and :16-34, and
    mutation_safety.md's `Plain` table gains the row "`Core.StringBuf` | no |
    owns a heap block, `impl as Destroy` frees it (string.carbon:141-171)" with
    a dated ST-1 note; the decision log's historical entries are not edited.

## §3 Commit structure (one PR, "ST-1: str comparison, Core.StringBuf and concatenation", R29(b))

1.  **Plan.** Rev 1 (bff5ba4e8); rev 2 (381f79b92) folding the two plan
    reviews with each amendment marked "(amended 2026-10-13, review fold: A-n)"
    or "(... review fold: Bn)" and the rev 2 Review fold record; rev 3 (this
    commit) folding the focused re-review of rev 2, marked "(... review fold:
    RR-N-n)", with the rev 3 fold record and the Sign-off. Each revision is a
    new commit.
2.  **Prelude and toolchain, CHECK-free.** core/prelude/types/string.carbon
    (§2.1), toolchain/check/cpp/export.cpp (§2.2), the eight golden sources of
    §2.3 with `// AUTOUPDATE` and no CHECK lines. The prelude and the null check
    MUST be in one commit: the prelude alone makes operators.carbon crash, and
    one crashing test aborts the whole file_test run (M-10). Expected gate on
    this commit alone: red on exactly ten goldens (the eight empty ones and the
    two refills), nothing else, and no abort (M-10's rev 2 run; amended
    2026-10-13, review fold: A-1, B4).
3.  **Fill.** Only the output of `autoupdate.sh` run to its fixpoint BEFORE the
    commit is made (R26): the eight new goldens filled and the two refilled. The
    fixpoint is reached when a run of `autoupdate.sh` prints only `.`, and runs
    are counted up to and including that one: operators.carbon converges on its
    third run (M-10: the first refills it, the second renumbers `.loc` lines
    only, the third prints `.`), every other golden on its second (the first
    fills it, the second prints `.`). Any run after the first that changes more
    than `.loc` numbers is a stop (R26) (amended 2026-10-13, review fold:
    RR-N-4). Message "Autoupdate testdata goldens on the container arbiter" (the
    UA-2 precedent, f96fe8a7a) (amended 2026-10-13, review fold: A-5, B10).
4.  **Conformance and docs.** The five programs and the oracle of §2.4
    (string_missing_ops with its line 26 repair, disclosed in this commit's
    message in the R6 template's words), string_basic.carbon's header, the
    regenerated conformance README table, docs/design/strings.md and the three
    amendments of §2.5.
5.  **Discharge.** The records of §2.6, written after §8's runs so every count
    is quoted from a run (R9).

Before each of commits 2, 4 and 5, `uvx prek run --files <that commit's files>`
runs to a fixpoint (a run that changes nothing), with R31's heading and
list-item counts recorded before and after for every `.md` in the commit. A
problem found after a commit exists is fixed by a NEW commit (a fix commit
after commit 2, a new autoupdate commit for a refill), never by amending one:
AGENTS.md requires asking before rewriting history, and R29 forbids asking
(the fork/slices/plan.md fix-round precedent; amended 2026-10-13, review fold:
B10).

## §4 Testdata matrix (R16: autoupdate fills; the predictions are confirmed or refuted by the fill)

"Measured" means the line was produced by the trunk file_test with the §2.1
prelude in the scratch mirror of M-11 (substitute paths change only the TIP
lines, the `ModuleID` and `source_filename` lines and the split-file names),
since rev 2 by M-19's file_test relinked with §2.2, from the §2.3 sources as
amended. No row is "predicted" any more: rev 1's two predicted rows are
measured, and the fill of §8.2 must reproduce every row (amended 2026-10-13,
review fold: A-1 / B4).

| Golden | Split or function | Key lines | Basis |
| --- | --- | --- | --- |
| check/testdata/string/compare.carbon | `str_str.carbon` | `@Eq`: `impl_witness_access constants.%EqWith.impl_witness..., element0 [concrete = constants.%str.as.EqWith.impl.Equal]` and `%str.as.EqWith.impl.Equal.call: init bool = call %bound_method(%a.ref, %b.ref)`; `@Ne` element1 `NotEqual`; `@Lt` `%str.as.OrderedWith.impl.Less.call`; `@Ge` element3 `GreaterOrEquivalent`; the `imports` block gains `import_ref Core//prelude/types/string` entries for the four `OrderedWith` functions | measured |
| same | `mixed.carbon` | `@EqBufStr`: `%StringBuf.as.EqWith.impl.Equal.call`; `@LtStrBuf`: `%str.as.OrderedWith.impl.Less.call` through a second `str` impl (`@str.as.OrderedWith.impl.<hash>`, the (`str`, `StringBuf`) one); `@GtBufBuf`: element2, `%StringBuf.as.OrderedWith.impl.Greater.call` | measured |
| same | `generic.carbon` | `@UseMin`: `%Min.call: init %str... to %.loc9_16.1 = call %Min.specific_fn(%String.val..., %String.val...)`, so `str` satisfies `Core.Ordered & Core.Copy` (a check golden: M-15's crash is in lowering); the fill's line, compare.carbon:485, is `%Min.call: init %str.3d4 to %.loc9_16.1 = call %Min.specific_fn(%String.val.loc9_33, %String.val.loc9_41)`, and rev 3 left out its `to %.loc9_16.1` (amended at landing 2026-10-13, implementation review fold: RV1-1 / ST1-IR2-9) | measured |
| check/testdata/string/string_buf.carbon | `concat.carbon` | `@Concat`: `return %str.as.AddWith.impl.Op.call to %return.param`; `@Chain`: `temporary ..., %str.as.AddWith.impl.Op.call` (`ref %StringBuf`) then `%StringBuf.as.AddWith.impl.Op.call`, with the temporary's `Destroy` facet; `@Dup`: `converted %s.ref, %StringBuf.as.ImplicitAs.impl.Convert.call` feeding `%StringBuf.Make.call` | measured |
| same | `append.carbon` | `@Append`: two `%StringBuf.as.AddAssignWith.impl.Op.call` (the `"!"` literal and `b` itself), `%StringBuf.Size.call`, and `%Destroy.WithSelf.SelfDestruct.call` on `%b.var` before the return | measured |
| same | `view.carbon` | `@View`: `%StringBuf.as.ImplicitAs.impl.Convert.call: init %str` and `converted %b.ref`; `@LetView` (rev 2: a `var` owner, then a view of it): `%str.as.AddWith.impl.Op.call: init %StringBuf to %.loc7_3.1` into `%c.var`, then `%StringBuf.as.ImplicitAs.impl.Convert.call: init %str` on `%c.ref` into a `temporary_storage` for the `str`, and the `SelfDestruct` of `%c.var` before the return (amended 2026-10-13, review fold: A-11 / B1) | measured |
| check/testdata/string/fail_string_buf.carbon | `fail_copy` | `` error: cannot copy value of type `StringBuf` [CopyOfUncopyableType] `` and `` note: type `Core.StringBuf` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext] ``, column 34 | measured |
| same | `fail_return_var` | the same two at `return s;`, column 10 | measured |
| same | `fail_unformed` | `` error: cannot convert type `Core.StringBuf` into type implementing `Core.DefaultOrUnformed` [ConversionFailureTypeToFacet] `` | measured |
| same | `fail_view_to_owned` | `` error: cannot implicitly convert expression of type `str` to `Core.StringBuf` [ConversionFailure] `` and `` note: type `str` does not implement interface `Core.ImplicitAs(Core.StringBuf)` [MissingImplInMemberAccessInContext] `` | measured |
| check/testdata/interop/cpp/stdlib/string_buf.carbon | `as_str.carbon` | `@F`: `%StringBuf.AsStr.call: init %str to %.loc8_24.1`, `%v: %str = wrapper_binding v`, then `%addr: %ptr... = addr_of` the `value_as_ref` of `%v.ref` and `%Consume__carbon_thunk.call ... (%addr)`, as string_view.carbon's `Cpp.Consume("hello")` passes a `str` (rev 2: the `let` form; rev 1's direct call aborted, M-20) | measured (M-11 rev 2; amended 2026-10-13, review fold: A-1) |
| same | `fail_buf_arg.carbon` | `` error: call argument of type `Core.StringBuf` is not supported [CppCallArgTypeNotSupported] `` at column 15, the `b` of `Cpp.Consume(b)`, and `` {{.*}}/prelude/types/string.carbon:141:1: error: semantics TODO: `interop with non-identifier package name` [SemanticsTodo] `` over `class StringBuf {`, which autoupdate places at the top of the file, after the TIP lines; no crash | measured (M-11 rev 2, as rev 1 predicted from type_mapping.cpp:594-598 and export.cpp:139-142; param_unsupported.carbon:77-84 has the same pair for `i512`; amended 2026-10-13, review fold: A-1) |
| check/testdata/interop/cpp/operators/fork_all_operands_conversion.carbon (new in rev 2) | `fail_todo_import_plus_with_bool_conversion.carbon` | `` error: cannot access member of interface `Core.AddWith(bool)` in type `bool` that does not implement that interface [MissingImplInMemberAccess] `` at column 40, `b1 + b2`; 43 lines, 4 CHECK; the same file passes on the unmodified trunk file_test | measured (M-24; amended 2026-10-13, review fold: B4) |
| lower/testdata/string/compare.carbon | `Eq`, `Lt`, `EqBufStr` | `call i1 @"_CEqual.String.Core:EqWith.<hash>.Core"(ptr %a, ptr %b)` with a matching `declare` (the body is in the prelude object); `@"_CLess.String.Core:OrderedWith.<hash>.Core"`; `@"_CEqual.StringBuf.Core:EqWith.<hash>.Core"` | measured |
| lower/testdata/string/string_buf.carbon | `Concat`, `Chain`, `Field` | `call void @"_COp.String.Core:AddWith.<hash>.Core"(ptr %s.var, ptr %a, ptr %b)`; `call void @"_COp.StringBuf.Core:AddAssignWith.<hash>.Core"(ptr %s.var, ptr @String.val...)`; at exit `call void @_CSelfDestruct.Destroy.Core.<hash>(ptr %s.var)`, whose `linkonce_odr` body calls `@"_COp.StringBuf.Core:Destroy.Core"(ptr %self)` then the field walk (`ret void`); in `Chain` the intermediate `%.loc27_29.1.temp` is destroyed at the function's end, just before `%s.var` (M-7; the header comment now says so, A-6 / B6); in `Field` (rev 2) `%h.var` is destroyed by `@"_CSelfDestruct.<hash>:core.Destroy.Core"`, whose `weak_odr` `_CSubobjectDestroy` calls `@_CSelfDestruct.Destroy.Core.<hash>(ptr %...text)`, the `StringBuf` field's declared `Destroy` (amended 2026-10-13, review fold: A-6 / B6, B2) | measured |
| lower/testdata/string/subscript.carbon | `Literal`, `Unsigned`, `Signed` | `Literal`: `getelementptr inbounds i8, ptr ..., i64 0`; `Unsigned`: `call i64 @"_CConvert.UInt.<hash>.Core:ImplicitAs..."(i8 %i)`, whose body calls `@"_CConvert.Int.<hash>.Core:FromUInt..."(i8 %self)`, whose body has the `zext i8 ... to i64`, feeding the `getelementptr`; `Signed`: `getelementptr inbounds i8, ptr ..., i64 %i`. The fill's lines (subscript.carbon:38, :41, :58, :65; their `, !dbg` suffixes omitted): `%UInt.as.ImplicitAs.impl.Convert.call = call i64 @"_CConvert.UInt.9452f4c51951679b.Core:ImplicitAs.f48df0d8add56b17.Core.28ad8c0e3712175a"(i8 %i)`, the `getelementptr inbounds i8, ptr %str.as.IndexWith.impl.At.call.string.ptr, i64 %UInt.as.ImplicitAs.impl.Convert.call`, the `_CConvert.UInt...` body's `%1 = call i64 @"_CConvert.Int.9452f4c51951679b.Core:FromUInt.94db85caea4a44af.Core.60d2bb209e06e693"(i8 %self)`, and that callee's `%2 = zext i8 %1 to i64`; rev 3 placed the `zext` one call too high (amended at landing 2026-10-13, implementation review fold: RV1-1 / ST1-IR2-9) | measured |
| check/testdata/operators/overloaded/string_indexing.carbon (refill) | `test_string_indexing.carbon` | two functions `@str.as.IndexWith.impl.At.1`/`.2` (the `i64` impl function and its thunk), the literal's `%Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64`, the call results still `[concrete = constants.%int_84]` and `%int_116`; +79/−33 CHECK lines; the `fail_` splits' diagnostics unchanged | measured |
| check/testdata/interop/cpp/operators/operators.carbon (refill of two splits) | `fail_todo_import_plus_with_string_view_conversion.carbon` and `fail_todo_rewrite_equal.carbon` | in the first, the four `MissingImplInMemberAccess` lines for `Core.AddWith(str)` are replaced by `` call argument of type `Core.StringBuf` is not supported [CppCallArgTypeNotSupported] `` at column 46 (`[[@LINE+11]]`), then `` cannot implicitly convert expression of type `Core.StringBuf` to `Cpp.StringViewConvertibleC` [ConversionFailure] `` and its `` type `Core.StringBuf` does not implement interface `Core.ImplicitAs(Cpp.StringViewConvertibleC)` `` note; the prelude-located `SemanticsTodo` of the `fail_buf_arg` row lands in the PRECEDING split, `fail_todo_rewrite_equal`, whose `[[@LINE+4]]` becomes `[[@LINE+8]]`, and the second autoupdate run renumbers three of its SemIR lines (`.loc23` to `.loc27`); the third run prints `.`; +16/−5 lines in all; every other split unchanged | measured (M-10 rev 2; amended 2026-10-13, review fold: A-5 / B4, RR-N-4) |

Falsifiers: any crash; any golden outside this table in the fill's diff; a
`fail_` split that compiles; the `StringAt` values other than 84 and 116; any
key line above that the fill does not reproduce (amended 2026-10-13, review
fold: B4).

## §5 Conformance: one SKIP → PASS, four new; delta PASS +5 / SKIP −1 / total +4

On the floor of record (fork/conformance/out/scoreboard.json at 80a11e7f0: 128
PASS / 0 FAIL / 22 SKIP over 150, bullets 48/56) the expected result is **133
PASS / 0 FAIL / 21 SKIP over 154, bullets 48/56**, the String bullet PASS over
six programs. Other PRs land first (UA-2's +3 PASS −3 SKIP, SC-1's two
programs), so the absolute numbers are re-quoted from the run at rebase, never
added by hand (R9); only the delta is this plan's claim.

EXPECT derivations (R16(d): from the design and independent reasoning; each
matched the prototype run only after being written down):

-   **string_missing_ops** (EXPECT unchanged; line 26 binds the owner, D-ST-14):
    `"hi" == "hi"`: equal sizes, equal bytes, so `Equal` is true and the `if`
    yields 1. `a + b`: 2 + 2 bytes, so the owning `c.Size()` is 4. Exit 0
    (amended 2026-10-13, review fold: B1).
-   **string_ordering_diff**: no EXPECT-STDOUT; the C++17 oracle defines the
    bytes (the arith_widths_diff precedent). Predicted for review:
    `carbon`/`carbon` 1; `carbon`/`carbOn` 0 ('o' 0x6F against 'O' 0x4F);
    `carbon` != `carbo` 1 (sizes); empty == empty 1; `apple` < `apricot` 1 ('p'
    0x70 < 'r' 0x72 at index 2); `app` < `apple` 1 (prefix); `apple` <= `app` 0;
    `Zebra` < `apple` 1 (0x5A < 0x61); `b` > `abc` 1 (0x62 > 0x61); `abc` >=
    `abc` 1; "\xC3\xA9" > `z` 1 (0xC3 > 0x7A unsigned); `joined.Size()` 5;
    `joined == "apple"` 1; `"apricot" > joined` 1; `joined < Make("apples")` 1
    (prefix). Fifteen lines, exit 0.
-   **string_buf_lifetime**: "Hello, " (7 bytes) + "Carbon" (6) + "!" (1) prints
    `Hello, Carbon!` and 14; `s += s` on `abc` prints `abcabc` and 6; the field
    prints `field`; the copy gained `?` and the source did not, so `copy != g`
    is 1 and `g` still prints `Hello, Carbon!`. Exit 0.
-   **string_concat_loop**: "Car" + "bon" + " " + "0.1" prints `Carbon 0.1` and
    10; ten self-appends of one byte give 2^10, so 1024; every byte is `z`, so
    1; the chained `+` prints `abcabcabc!`. Exit 0.
-   **string_subscripts**: `"Carbon"[0]` is `C` and `[5]` is `n` (one line
    `Cn`); 25 copies of `abcdefgh` are bytes 0-199, so byte 200 is the appended
    `X` and byte 199 is the last `h`. Exit 0.

Non-vacuity (M-12): all five are COMPILE-FAIL on the trunk install;
string_subscripts additionally discriminates D-ST-9 (without it, `s[0]` crashes
lowering and `At(long, 200 as u8)` printed a byte from before the string). What
the programs do NOT observe is that blocks are freed: their EXPECT lines read
bytes and sizes only. Freeing is pinned by the lower golden's destroy calls
(`Concat`, `Chain`, `Field`, §4) and checked by the manual shim run of §8.8,
whose expected counts (M-23) are re-derivable by hand from the program text
(amended 2026-10-13, review fold: B2).

## §6 Churn inventory (verified by grep at 80a11e7f0)

-   **Files:** core/prelude/types/string.carbon (32 → 275 lines; four existing
    lines changed or followed by insertions, :12, :14, :25-26, :31);
    toolchain/check/cpp/export.cpp (+5); eight new goldens; two refilled
    goldens; five programs and one oracle (one modified, four new),
    string_basic.carbon's header; fork/conformance/README.md (generated table);
    docs/design/strings.md (new), docs/design/README.md,
    docs/design/expressions/arithmetic.md,
    docs/design/interoperability/README.md (one blockquote each);
    fork/string/plan.md, fork/inventory/work-items.json, fork/gap-analysis.md,
    fork/decision-log.md, fork/ORCHESTRATION.md; if PR 53 has landed, SAFE-1's
    docs/design/safety/temporal_safety.md, spatial_safety.md,
    initialization_safety.md, mutation_safety.md and rust_interop.md (§2.6;
    amended 2026-10-13, review fold: B1, B4).
-   **Goldens:** exactly two existing goldens change (M-10; three of
    operators.carbon's lines are a `.loc` renumbering); no min_prelude
    golden can change (D-ST-13); no raw_sem_ir or prelude-dumping golden changes
    (all pass under the prototype). Full-prelude goldens compile a longer
    string.carbon; file_test wall time moved within run-to-run noise (25 s to 49
    s across runs that shared the CPU with other measurement work; the trunk
    record is 31 s).
-   **Line shifts that break citations:** string.carbon :26-32 move to :32-38
    (the class's closing brace, `UnformedInit`, the `IndexWith` impl); lines
    1-25 do not move. Citations of the old numbers: gap row 77 (rewritten by
    §2.6), W-057 (rewritten), fork/unions/plan.md:70 ("string.carbon:28") and
    the decision log's historical entries (history, not edited), and SAFE-1's
    normative pages (re-cited by §2.6 if PR 53 lands first). export.cpp :298
    onward shift by +5; W-049's evidence list cites export.cpp lines that are
    already stale on trunk (:428, :436, :510, ... against the post-advance file)
    and is not this plan's to refresh.
-   **Other branches (none touches core/, min_prelude or export.cpp):** SC-1
    (head 2f4ebbf6e, tree-identical to fbfb99104; amended 2026-10-13, review
    fold: B7) changes check/ sources but none of ST-1's files, including
    member_access.cpp and name_lookup.cpp since 42841fa8d, which R-9 covers;
    none of its 18 changed goldens uses strings (M-16); after either lands, the
    other rebases and refills its own new goldens. UA-2 (PR 51): goldens-only,
    and its three new goldens pass under the ST-1 prelude (M-16); both edit
    fork/gap-analysis.md, fork/inventory/work-items.json and
    fork/decision-log.md, in different rows. CM-1 (PR 52): records only
    overlap. SAFE-1 (PR 53): docs/design/README.md (blockquotes at :2148, :2168
    and :3900, not near :634), docs/design/expressions/arithmetic.md (a
    blockquote at :164, which moves the Strings section from :184-188 to
    :193-197; amended 2026-10-13, review fold: A-7) and docs/design/values.md
    (eight lines at :137, which move :168 to :176; amended 2026-10-13, review
    fold: B12): different hunks, a clean merge, re-read the line at rebase; its
    string.carbon citations are §2.6's conditional re-cite. EV-1 (W-062,
    documentation, plan only today): any tutorial text it writes about strings
    must describe the post-ST-1 API if ST-1 lands first; the orchestrator
    passes it §1.1's table.
-   **Same-anchor files and their resolution** (amended 2026-10-13, review
    fold: B5): every live branch edits these at the same places, so a rebase
    conflict there is expected and resolved by rule, never by merging hunks:
    fork/decision-log.md (CM-1 and SAFE-1 both insert at :2863, SC-1 at its
    :3773; re-anchor ST-1's entry above the then-newest landed entry, §2.6);
    the fork/gap-analysis.md header sentence and counts (re-apply ST-1's
    DELTA, DONE +1 / PARTIAL −1, to whatever the header reads); the
    fork/conformance/README.md program table (regenerate with
    `runner.py --update-readme-table`); fork/ORCHESTRATION.md's Branches table,
    stamp paragraph and Scoreboard subsection (re-stamp); and
    fork/inventory/work-items.json (append after the then-last item, ids per
    the allocation rule).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1: the build's fill differs from M-19's measurement.** Rev 1 could not
    measure operators.carbon or the interop golden; rev 2 measured both with
    the relinked file_test (M-10, M-11), so the residual risk is that the
    carbonbuild toolchain of §8.1 behaves differently from the trunk build
    with one object swapped. Falsifier: the fill shows a crash, or any key line
    of §4's operators.carbon, interop or fork_all_operands_conversion rows
    (`CppCallArgTypeNotSupported`, the prelude-located `SemanticsTodo`,
    `ConversionFailure` and its note, `MissingImplInMemberAccess` for
    `Core.AddWith(bool)`) is missing or different. Contingency: a crash means
    the null check belongs in `ExportNameScopeToCpp`'s other callers too
    (grep `ExportNameScopeToCpp(` at the fill), fixed in a fix commit after
    commit 2; any other difference stops the fill, and the plan is revised to
    explain it before commit 3 (amended 2026-10-13, review fold: A-1 / B4,
    B10).
-   **R-2: a golden outside §4 moves.** M-10 rules it out for the prelude; the
    null check only changes a path that crashed before, and no trunk golden
    crashes (1942/1942). Falsifier: the fill's diff names another file.
    Contingency: stop, diff it, and either explain it in §4 by a rev or revert
    the cause.
-   **R-3: temporary lifetimes change under the string goldens.** If the
    toolchain moves a declaration initializer's temporaries to the end of the
    full-expression (D-SAFE-12's rule made toolchain behavior), only
    lower/testdata/string/string_buf.carbon's `Chain` placement moves (a
    refill); no program, golden or doc example views a temporary past its
    full-expression since rev 2 (D-ST-6, D-ST-14). Falsifier: lower IR
    destroying the temporary before the next statement, or any String program
    changing its output. Contingency: refill `Chain`; for a program, D-ST-14's
    break condition (amended 2026-10-13, review fold: A-11 / B1).
-   **R-4: F-013 forbids `let c: str = a + b;`.** Resolved in rev 2 rather than
    contingent: D-SAFE-12 (held in PR 53, merging first) makes that use of a
    view of a temporary `StrictBorrowOfTemporary`, so line 26 binds
    `var c: Core.StringBuf = a + b;` now, EXPECT unchanged, disclosed in the
    R6 template (D-ST-14), and the `LetView` golden binds a `var` owner.
    Falsifier of the residual: a new ST-1 program or doc example that views a
    temporary past its full-expression. Contingency: rewrite it the same way
    (amended 2026-10-13, review fold: A-11 / B1).
-   **R-5: upstream adds string operations or renames the view class before the
    next advance.** Falsifier: the weekly upstream check sees string.carbon
    change. Contingency: D-ST-4's and D-ST-10's break conditions; the divergence
    register entry of §2.6 tells the merge which side wins.
-   **R-6: a prelude edit by another workstream conflicts in string.carbon.**
    None of the live branches touches core/ (§6). Falsifier: a rebase conflict
    in core/prelude/types/string.carbon. Contingency: keep both sides; re-run
    M-10's full file_test.
-   **R-7: the byte loops are slow somewhere that matters.** M-13 bounds the 0.1
    cost. Falsifier: a conformance or evaluator program timing out in a string
    loop. Contingency: D-ST-2's break condition (a builtin, W-163).
-   **R-8: the build or the fill competes with the concurrent SC-1 agent.** Four
    cores; a build is 10 to 17 minutes. Falsifier: `uptime` load above 4 at
    build start. Contingency: wait; never touch /home/user/carbon-sc or its
    build directory.
-   **R-9: SC-1's member-access and name-lookup changes alter how ST-1's impls
    resolve.** SC-1 (2f4ebbf6e) changes member_access.cpp, name_lookup.cpp,
    generic.cpp, handle_require.cpp and structural_conformance.cpp, and every
    ST-1 operator resolves through member access (`a == b` is
    `a.(EqWith(U).Equal)(b)`, comparison_operators.md:251-271); M-16 rules out
    only textual overlap. Falsifier: after rebasing onto a trunk that contains
    SC-1, the M-2, M-10 and M-12 re-runs on the ST-1 build differ from this
    plan's (a golden outside §4 moves, a §4 key line changes, a program's
    output changes). Contingency: refill, and explain the difference in a plan
    revision before the fill commit (amended 2026-10-13, review fold: B7).
-   **R-10: W-148's loan checker rejects ST-1 lines.** F-013 makes the
    self-aliasing append `StrictSharedBorrowInvalidated` and is expected to
    require `bound b` on view.carbon's `View`; D-ST-14 names the four lines.
    Falsifier: when W-148 lands, it rejects an ST-1 program or golden line
    other than those four, or accepts the three self-appends (then §1.4's
    reading of T4 with M8 is wrong, and strings.md is amended with the
    checker's actual rule). Contingency: D-ST-6's and D-ST-14's break
    conditions; the two program rewrites are measured already (M-25) (amended
    2026-10-13, review fold: RR-N-1).

Rejected alternatives (each with the evidence that rejects it):

-   **A-1: rename the view to `Core.Str` and make `Core.String` the owning
    type.** It matches p006177's names and README.md's owning `String`, but
    renames an upstream class keyed by name at literal.cpp:232,
    builtin_function_kind.cpp:209 and type_info.cpp:193, changes every golden
    that prints `@String`, `%String.val` or `_COp.String` (10 check and lower
    goldens print the class name: `grep -rlE
    'CHECK.*[^a-zA-Z_]String[^a-zA-Z_]' toolchain/check/testdata
    toolchain/lower/testdata | wc -l`; amended 2026-10-13, review fold: A-10)
    and union/basic.carbon:315's source (`var
    text: Core.String;`), and preempts the rename upstream will choose. D-ST-4's
    break condition gets the same result when upstream moves.
-   **A-2: keep `str` the only type; `+` allocates and never frees (or
    fails-stop).** Every concatenation in a loop leaks (M-4's 10000 appends
    would hold 50 MB); contradicts README.md:627-634.
-   **A-3: `"string.eq"`/`"string.compare"` builtins lowered to `memcmp`.** Four
    toolchain sites and a lowering arm for no measured benefit (M-13); kept as
    W-163's mechanism.
-   **A-4: `Char`'s blanket shape for mixed comparisons.** §0.4 D-ST-8.
-   **A-5: `StringBuf` as a wrapper of a `Core.Buf(Char)` field.** `+=` must
    replace the block: assigning a new `Buf` to the field does not destroy the
    old one (M-5) and the new `Buf` temporary would free the block it hands
    over; and a declared `Destroy` on `StringBuf` would leave the field
    undestroyed (M-8).
-   **A-6: a separate core/prelude/types/string_buf.carbon.** The orphan rule
    (M-18) keeps `String`'s `AddWith` impls in string.carbon, and they name
    `StringBuf`, so the two files would import each other; a new file also
    changes the runtimes prelude list compiled into the binary (§0.2 setup).
-   **A-7: a bounds-checked `str` subscript in Carbon.** A Carbon `At` body
    cannot be evaluated at compile time, so `"Test"[4]` would stop being the
    `StringAtIndexOutOfBounds` error that upstream's string_indexing.carbon
    `fail_` splits pin: weakening an existing test (R16(b)). W-162 puts the
    check in the lowering instead.
-   **A-8: fixing the literal subscript in `"string.at"`'s lowering.** It needs
    the subscript's signedness and its constant in `HandleCall`; the prelude's
    parameter type does both through existing conversions, in the spelling
    `Char`'s impls already use (D-ST-9).

## §8 Verification and discharge

The carbonbuild scripts are not in the repository yet: they are the session
scratchpad's
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/carbonbuild/`
(its README.md documents them; the pending carbonbuild/R28 amendment moves them
into the repository, after which that path is used instead). `$CB` below is that
directory (amended 2026-10-13, review fold: B12).

1.  **Build** (no Bazel, ever; the owner declined installing it): `$CB/build.sh
    /home/user/carbon-st` then `$CB/install.sh /home/user/carbon-st` (outputs
    under /home/user/carbon-build/carbon-st/; 10 to 17 minutes on 4 cores;
    `-Werror` clean, export.cpp already compiled with the same flags by M-19).
    `install/bin/carbon version` prints `0.0.0-0.dev+<sha>`.
2.  **Fill to fixpoint** (R26): `$CB/autoupdate.sh /home/user/carbon-st` with
    the ten golden paths of §4, repeated until a run prints only `.`:
    operators.carbon converges on its third run (the first refills it, the
    second renumbers `.loc` lines only, M-10), every other golden on its
    second (the first fills it); a run after the first that changes more
    than `.loc` numbers is a stop. Commit 3 holds exactly the files the fill
    changed (amended 2026-10-13, review fold: A-5, RR-N-4).
3.  **Gate:** `$CB/gate.sh /home/user/carbon-st` → the rebased base's file_test
    count plus 8, 0 failed, no `!` or `?` marks (1950 = 1942 + 8 on
    80a11e7f0; UA-2 adds 3 and SC-1 16 if they land first) (amended
    2026-10-13, review fold: B4, B7). The verdict is read from gate.sh's exit
    status and from the log's `[==========] N tests from ... ran.` and
    `[  PASSED  ] N tests.` lines, never from the failed count of gate.sh's
    summary line: that count is parsed from a `[  FAILED  ] N tests` line
    which file_test's brief output never prints, so a red run reads "0
    failed" (commit 2's run printed `1940 passed, 0 failed (exit 1, 26s)`)
    until the harness fix lands with the carbonbuild scripts (amended
    2026-10-13, implementation review fold: ST1-IR2-8).
4.  **Conformance:** `XDG_CACHE_HOME=/home/user/carbon-build/carbon-st/cache
    $CB/conformance.sh /home/user/carbon-st
    /home/user/carbon-build/carbon-st/conf-out` (the new install digest gives a
    fresh runtimes cache; the first link is slow, R4) → the §5 delta on the
    base of record, the String bullet PASS with six programs, no other status
    change. fork/conformance/out/scoreboard.json is NOT overwritten by a
    container run unless the orchestrator designates container runs as of
    record (the pending carbonbuild/R28 amendment); the totals go into the
    landed notes, the row text's "expected, not of record" sentence (§2.6) and
    the PR body (amended 2026-10-13, review fold: B5, B12). As run, the
    orchestrator directed both container runs into session scratch
    directories instead of conf-out: the implementation run into
    `st1-impl/conf` (whose runtimes-cache location was not recorded) and the
    fix round's into `st1-impl/conf-fix` with the `XDG_CACHE_HOME` above,
    created first: the driver falls back to a temporary cache per invocation
    when that directory is missing
    (toolchain/driver/runtimes_cache.cpp:193-203), so every link then
    rebuilds the runtimes.
    Commit 5 cites a run by toolchain sha, the scoreboard's `generated`
    timestamp and its totals (§2.6), and the shim of step 8 runs on that
    run's `bin/` (amended 2026-10-13, implementation review fold: RV1-5 /
    ST1-IR2-4).
5.  **Runner:** `python3 fork/conformance/runner.py --self-test` clean after
    `--update-readme-table` (R7).
6.  **prek fixpoint** (R22, R25), per commit as §3 says: `uvx prek run --files
    <that commit's files>` until a run changes nothing, before each of commits
    2, 4 and 5; for every `.md` in the commit, heading counts per level and
    list-item counts (R31(b)) recorded before and after, and the diff grepped
    for `^\+\s*#{1,6} [0-9]|^\+#[0-9]` (R31(c)); clang-format 21.1.8 on
    export.cpp and the oracle (R18) (amended 2026-10-13, review fold: B10).
7.  **Reconciliation greps:** `grep -n 'class StringBuf'
    core/prelude/types/string.carbon` → :141; `grep -rln 'StringBuf' core
    toolchain/check toolchain/lower toolchain/sem_ir` → string.carbon, six of
    the eight new goldens (all but lower `string/subscript.carbon` and
    `interop/cpp/operators/fork_all_operands_conversion.carbon`) and the
    refilled operators.carbon, where only its `CHECK:STDERR` lines match; no
    `.cpp` or `.h` file (amended 2026-10-13, review fold: B11); `grep -c 'if
    (!decl_context)' toolchain/check/cpp/export.cpp` → 4; `grep -rn
    'string_missing_ops' fork/conformance/README.md` → a `run` row.
8.  **Allocation check (manual, not a gate; amended 2026-10-13, review fold: B2,
    B3):** the ownership claims no EXPECT line can observe are checked by
    running each String program's binary from step 4's
    `/home/user/carbon-build/carbon-st/conf-out/bin/` under this `LD_PRELOAD`
    shim, built in a scratch directory with `/home/user/llvm/bin/clang -shared
    -fPIC -O1 -o st1_shim.so st1_shim.c -ldl`, as
    `LD_PRELOAD=<scratch>/st1_shim.so <binary> > /dev/null`. Expected, on
    stderr, M-23's counts: string_basic `malloc=1 free=0`, string_missing_ops 2
    and 1, string_ordering_diff 3 and 2, string_buf_lifetime 8 and 7,
    string_concat_loop 20 and 19, string_subscripts 28 and 27, every one
    `bad=0`. After D-ST-14's W-148 rewrite of the two self-appends,
    string_buf_lifetime is 9 and 8 and string_concat_loop 30 and 29 (M-25;
    amended 2026-10-13, review fold: RR-N-1). Any other count is D-ST-16's break
    condition. The shim (scratch only, never committed):

    ```c
    // Counts malloc and free, and counts as "bad" a free of a pointer that
    // malloc did not return (a double free, or a stack or static pointer).
    #define _GNU_SOURCE
    #include <dlfcn.h>
    #include <stdio.h>
    #include <unistd.h>

    enum { kMaxLive = 1 << 16 };
    static void* live[kMaxLive];
    static long n_live, n_malloc, n_free, n_bad;

    void* malloc(size_t size) {
      static void* (*real_malloc)(size_t);
      if (!real_malloc) real_malloc = dlsym(RTLD_NEXT, "malloc");
      void* p = real_malloc(size);
      ++n_malloc;
      if (n_live < kMaxLive) live[n_live++] = p;
      return p;
    }

    void free(void* p) {
      static void (*real_free)(void*);
      if (!real_free) real_free = dlsym(RTLD_NEXT, "free");
      if (!p) return;
      long i = n_live - 1;
      while (i >= 0 && live[i] != p) --i;
      if (i < 0) {
        ++n_bad;
        return;
      }
      live[i] = live[--n_live];
      ++n_free;
      real_free(p);
    }

    __attribute__((destructor)) static void Report(void) {
      char line[96];
      int len = snprintf(line, sizeof line, "shim: malloc=%ld free=%ld bad=%ld\n",
                         n_malloc, n_free, n_bad);
      write(2, line, len);
    }
    ```

9.  **Discharge:** §2.6, then the ORCHESTRATION stamp; the PR body carries the
    verification record and the not-run list.

**Not run, and why (named in the PR body):** Bazel and every Bazel-only test
(gtest unit tests, lit tests, fuzzers, install_test.py; no `_test.cpp` is
touched); clangd-tidy on export.cpp (R21's second hosted step; no hosted runs
exist while GitHub Actions is disabled); any hosted run and the owner's runner
(R28); an opt-mode (`NDEBUG`) toolchain, where M-9's crash would be a null
dereference rather than an assertion; LLVM with assertions (the CMake LLVM is
Release); macOS, Windows, ASan; libstdc++ (the `str` mapping is disabled there
by design).

## Hand-off notes for the implementer

-   Copy §2.1, §2.2, §2.3 and §2.4 verbatim from this file: §2.1 is the text
    every §0.2 measurement ran; §2.2, §2.3 and §2.4 as amended are the texts
    the rev 2 measurements ran (M-19's patch, M-11's and M-24's fills, M-12's
    rev 2 program run). Rev 1's §2.3 was NOT all measured text: its `as_str`
    split had never run, and it aborts file_test (M-20). If anything must
    change, re-run M-2, M-10 and M-12 against your build before committing, and
    record the change in the plan's landed notes (amended 2026-10-13, review
    fold: A-1).
-   Commit 2 is prelude AND export.cpp together (M-10). If file_test aborts with
    "isa<> used on a null pointer", the null check is missing or misplaced; if
    it aborts with "queried property of class with no definition", a `str`
    call result reaches a mock `basic_string_view` parameter (W-165, M-20).
-   Do not write CHECK lines, do not edit a filled golden, and do not touch
    min_prelude (D-ST-13). The fill must change exactly the ten files of §4
    (amended 2026-10-13, review fold: B4).
-   The prelude-located TODO in `fail_buf_arg` and in operators.carbon pins
    string.carbon:141 (`class StringBuf`); an edit above that line moves both,
    and autoupdate follows.
-   In programs and docs, loops append with `+=`; never show `s = s + t` (W-160)
    and never pass a `Core.StringBuf` straight to C++ (use `AsStr()`). New
    code appends a string to itself as `s += Core.StringBuf.Make(s);`, never
    `s += s` (F-013's T4 rejects it once W-148 lands); the three existing
    self-appends and `View` are D-ST-14's expected W-148 trips and are copied
    as written (amended 2026-10-13, review fold: RR-N-1).
-   A function that builds a string returns `Core.StringBuf`, with `returned
    var` or as a direct `return a + b;`; `return s;` of a plain `var` is a copy
    error (pinned). A function returning `str` never returns a `+` result or a
    local `Core.StringBuf` (a silent use-after-free, M-21, W-166), and no
    program, golden or doc example binds a `str` view of a temporary past its
    full-expression; bind a `var` owner (D-ST-6; amended 2026-10-13, review
    fold: A-2, A-11 / B1).
-   docs/design/strings.md's API listing is copied from the landed string.carbon
    and diffed against it before commit 4 (R27).
-   Re-read at rebase (R9): gap row 77's line, the header counts and the
    scoreboard base; the decision-log anchor (§2.6); arithmetic.md's Strings
    section and values.md:168 (both move when SAFE-1 lands, §6); the SAFE-1
    pages of §2.6's reconciliation. Allocate the residues from max(trunk,
    every live `claude/carbon-fork-0-1-*` branch) + 1, skipping W-151 and
    W-152..W-159; if W-160..W-167 are taken, re-allocate and say so in the
    landed notes (amended 2026-10-13, review fold: A-8, B8, B12). Also
    re-read at rebase: every landing-date stamp (strings.md's status line,
    the three Fork amendment lines, and commit 5's W-057 title, row 77, §W9
    paragraph and decision-log heading), re-stamped in a new commit if the
    merge date differs; strings.md's W-126 and W-148, which assume that PR 51
    and PR 53 merge first; and, if re-allocation triggers, the residue ids
    already written in strings.md, the interoperability README's amendment
    and string_concat_loop.carbon's header (§2.6; amended 2026-10-13,
    implementation review fold: RV1-4 / ST1-IR2-2, ST1-IR2-5).
-   Never run `git add -A` (R20); commit with the author and committer
    conventions of the brief, and end each message with exactly the
    attribution trailer lines that the session's harness attribution notice
    specifies, plus the brief's Claude-Session line; this plan does not
    reproduce the trailer text, because the brief forbids model names in
    repository files and the notice, not the brief, decides that line (rev 1's
    commit followed the notice). Do not push or open the PR until the
    orchestrator says so (amended 2026-10-13, review fold: B12).
-   Row 51 ("Generics: generic functions and types", DONE) and row 81 (the
    string-mapping bullet, DONE) are left unchanged: W-164 and W-165 are listed
    in the ledger only (amended 2026-10-13, review fold: B12). Row 41 ("Type
    system: User-defined types (classes)", DONE) stays DONE, with "access
    control fully checked" amended to name W-167 and W-160 in the ledger only
    (§2.6; amended 2026-10-13, review fold: RR-N-3).
-   Fix-ups after a commit exists are new commits, never amends (§3; amended
    2026-10-13, review fold: B10).

## Review fold record (rev 2, 2026-10-13)

Every finding of the two rev 1 reviews, its grade, its disposition and where it
is folded. Rev A (design soundness and toolchain correctness) returned REJECT
with 2 BLOCKER, 2 MAJOR and 7 MINOR findings; rev B returned
APPROVE-WITH-AMENDMENTS with 5 MAJOR and 7 MINOR. All 23 are folded; none is
rejected. Review A's ids A-1..A-11 are review findings; the rejected
alternatives of §7 keep their own A-1..A-8 numbering and are always cited as "§7
A-n". The fixer re-opened every cited location and re-ran every measurement a
finding is about in its own scratch tree
(`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/st1-fixer`:
an install copy with §2.1, a file_test and busybox relinked with §2.2, M-19);
each reproduction is the §0.2 entry named in the table. Because rev A REJECTed,
rev 2 goes to a focused re-review before implementation.

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| A-1: the interop golden's `as_str` split crashes file_test | BLOCKER | Reproduced (M-20: exit 134 on the relinked file_test; the same assertion from `fn Mk() -> str` plus `Cpp.Consume(Mk())` on the unmodified trunk install; the `let` form passes; real libc++ prints 3). Folded as the reviewer proposed: the split binds `let v: str = b.AsStr();` first (filled: 332 lines, fixpoint in one pass); W-165 filed under the string-mapping bullet as `toolchain-defect`; both rev 1 "predicted" goldens measured with a relinked file_test (M-19, M-10, M-11); the hand-off's "measured text" claim corrected | Status; id allocation; §0.2 M-9, M-10, M-11, M-19, M-20, "Not measured"; §1.6; §1.7 W-165; §2.2; §2.3 interop golden; §2.6 W-165; §3 commit 2; §4 header and interop rows; §7 R-1; hand-off |
| A-2: implicit `StringBuf` to `str` conversion permits a silent use-after-free | BLOCKER | Reproduced (M-21: `Join` prints `XXXXXXXXXXXX`, the local owner `YYYY`, the field `QQQ`, the view across `+=` `ZZZZZZZZ`). Folded: W-166 filed (bullet: the SAFE-1 design bullet that holds W-148), named in D-ST-6, §1.1, §1.3, §1.7, strings.md, row 77 and the hand-off; `AsStr` and `Convert` added to W-144's view producers; the "never return a `+` result or a local owner as `str`" rule in docs and hand-off | Id allocation; §0.2 M-21; D-ST-6; D-ST-11; §1.1 table; §1.3; §1.7; §2.5 strings.md; §2.6 W-166, W-144, row 77; hand-off |
| A-3: forged `Core.StringBuf` frees a non-heap pointer | MAJOR | Reproduced (M-17 as amended: `malloc=1 free=0 bad=1`; `Core.Buf(i32)` `bad=1`; no ledger item on trunk, safe, ua2, sc, ev or cmake mentions it). Folded: W-167 (classes bullet); §1.3's invariant qualified to values the prelude builds; strings.md's limits, with `Core.Buf` | Id allocation; §0.2 M-17; D-ST-11; §1.3; §1.7; §2.5; §2.6 W-167, row 77 |
| A-4: DONE cites row 82 and ignores row 79 | MAJOR | Folded with the reviewer's second option: D-ST-16 now distinguishes row 79 in one sentence (row 79 lacks a design-specified operation of its own type, W-109; ST-1 leaves none missing) and lists W-166 and W-167 among the row's limits; together with B3 | Outcome paragraph; §0.2 M-22; D-ST-16; §2.6 row 77 |
| A-5: operators.carbon touches a second split and needs a third pass | MINOR | Reproduced (M-10 rev 2: the `SemanticsTodo` lands in `fail_todo_rewrite_equal`, `[[@LINE+4]]` to `+8`; pass 2 renumbers `.loc23` to `.loc27`; pass 3 prints `.`; +16/−5). Folded: §4 names both splits; §8.2 allows a loc-only extra pass; the divergence register lists both; §2.3 says the upstream TODO is no longer exercised | §0.2 M-10; §2.3 refill paragraph; §2.6 divergence register; §3 commit 3; §4 operators row; §8.2 |
| A-6: the lower golden's comment contradicts its fill | MINOR | Reproduced (filled `Chain`: the `%.loc27_29.1.temp` destroy just before `%s.var` at the end). Folded: the comment rewritten as proposed and the golden re-filled (215 lines) | §2.3 lower string_buf.carbon; §4 lower row |
| A-7: arithmetic.md cited off by one | MINOR | Reproduced (:184 heading, TODO :186-188; :193-197 on the safe branch). Folded as proposed | Design authority; D-ST-1; §2.5 arithmetic.md; §6 SAFE-1 shift |
| A-8: decision-log insertion point is wrong | MINOR | Reproduced (:20-22 is V-1..3; landed entries start at :2863 after :2843-2862; SAFE-1 and CM-1 insert at :2863). Folded: the anchor and the "ST-1 / F-014: ..." heading as proposed | §2.6 decision log; §6 same-anchor list; hand-off |
| A-9: the §2.2 diff cannot be applied with `git apply` | MINOR | Reproduced (`corrupt patch at line 14`; `--recount` applies). Folded: the hunk starts at :294 with header `@@ -294,4 +294,9 @@`; `git apply --check` of the new block passes, after this rev's prek too | §2.2 |
| A-10: unlisted 0.1 limits and record inaccuracies | MINOR | Reproduced each: the `if`-expression TODO (M-22); W-146's title (arrays and division only); W-121's kind `toolchain-defect`; 10 goldens, not 12; 315 files, not 316. Folded: the `if`-expression TODO is cited as UA-1's existing W-122 (the same `EndConditionalExprOperand` TODO, control_flow.cpp:209-212), not re-filed, in §1.4, §1.7, strings.md and row 77; W-162 described as independent of and related to W-146; W-164 filed as `toolchain-defect`; both counts quoted with their commands | §0.1 row 11; §0.2 M-22; D-ST-16; §1.4; §1.7; §2.5; §2.6 W-162, W-164, row 77; §7 A-1 count |
| A-11: new material makes block-scoped temporaries a design guarantee | MINOR | Folded as proposed, together with B1: strings.md states the full-expression rule (D-SAFE-12) as design and M-7 as toolchain behavior; `LetView` binds a `var` owner (re-filled: 927 lines); line 26 rewritten (B1) | Design authority; §0.2 M-7; D-ST-6; §1.3; §2.3 `view.carbon`; §2.5; §4 view row; §7 R-3, R-4; hand-off |
| B1: unreported contradictions with SAFE-1's pages; line 26 rests on a lifetime F-013 forbids | MAJOR | Reproduced (EX-TM-7b's line on trunk: `v[0]` prints 7, 3 `malloc` / 2 `free`; temporal_safety.md:831-840, :1116-1120; spatial_safety.md:130-149, :433-438; initialization_safety.md:103-104 on the safe branch). Folded with the reviewer's preferred option: line 26 becomes `var c: Core.StringBuf = a + b;`, EXPECT unchanged, disclosed in the R6 template; the five-edit SAFE-1 reconciliation in §2.6 (applied at ST-1's rebase if PR 53 has landed, else handed to SAFE-1's rebase through ORCHESTRATION) | Design authority; §0.2 M-7, M-12; D-ST-6; D-ST-11; D-ST-14; §1.3; §1.7 W-162; §2.4 string_missing_ops; §2.5; §2.6 W-144, SAFE-1 reconciliation; §3 commit 4; §5; §6 files; §7 R-3, R-4 |
| B2: lifetime claims no EXPECT can detect; no golden pins field destruction | MAJOR | Folded: (i) `Holder`/`Field` added to the lower golden (filled: `_CSubobjectDestroy` calls the field's `StringBuf` destroy); (ii) both program headers reworded to claim only what EXPECT observes; (iii) the shim's source and command are §8.8, a manual check whose expected counts (M-23) are re-derivable by hand from the program text and match the measured run | §0.2 M-11, M-12, M-23; §1.3; §2.3 lower string_buf.carbon; §2.4 headers; §4 lower row; §5 non-vacuity; §8.8 |
| B3: the DONE flip skips the W9 Arbiter, files W-160 under the flipped bullet, omits W-126 | MAJOR | Reproduced (gap-analysis.md:241-244; row 79's tail; `s = Make(...)` leaks, M-22). Folded: D-ST-16 quotes the Arbiter and states in one sentence how F-014 meets it under R29(a); W-160 refiled under "Type system: User-defined types (classes)" and named in row 77 as language-wide; W-126 named in row 77; D-ST-16's break condition is the reviewer's observable one | Design authority; outcome paragraph; D-ST-16; §1.7 W-160; §2.6 W-160, row 77; §8.8 |
| B4: operators.carbon's upstream split stops testing its TODO; R-1 unfalsifiable | MAJOR | Folded: the fork-owned check/testdata/interop/cpp/operators/fork_all_operands_conversion.carbon pins the TODO with `bool` operands (M-24: filled, 43 lines, passes on the unmodified trunk too); the divergence register records the changed subject; R-1 now requires every §4 key line, and the prediction is measured (A-1) | §0.2 M-11, M-24; §2.3 new golden and refill paragraph; §2.6 divergence register; §3; §4 new row, falsifiers; §6; §7 R-1; §8.2, §8.3, §8.7 |
| B5: discharge records break the newest-entry discipline | MAJOR | Reproduced ((a) CM-1's and SC-1's "expected, not of record" wording; (b) the anchors of A-8; (c) no "scope map" in fork/ORCHESTRATION.md on any branch; (d) the shared anchors). Folded: the row text ends "EXPECTED, not of record" with the floor of record and run 37402970811; the header sentence follows CM-1's words; the A-8 anchor; ORCHESTRATION's real targets; a §6 same-anchor list with resolution rules | §2.6 gap-analysis, row 77, decision log, ORCHESTRATION; §6; §8.4 |
| B6: the lower golden's comment contradicts M-7 | MINOR | Same defect as A-6; folded there | §2.3; §4 |
| B7: the SC-1 analysis is stale; the gate count is absolute | MINOR | Reproduced: SC-1's head is now 2f4ebbf6e, whose tree 8e4dd11ce equals fbfb99104's (SC-1 re-committed its records commit after rev B read it); member_access.cpp, name_lookup.cpp and three more sources changed since 42841fa8d. Folded: SC-1 re-cited, R-9 added, the gate stated as "+8 over the rebased base" | §0.2 M-16; §6; §7 R-9; §8.3 |
| B8: the id rule checks trunk only | MINOR | Folded as proposed (ledger maxima re-read: trunk W-125, safe W-150, sc W-151, cmake W-133, ua2 W-127, ev W-125) | Id allocation; hand-off |
| B9: D-ST-14 has no break condition; D-ST-16's is unobservable | MINOR | Folded, with one departure: because B1's preferred option rewrites line 26 now, B9's suggested D-ST-14 condition ("line 26 is then rewritten") would never fire; D-ST-14's condition is instead "a String program stops passing on a toolchain that contains ST-1, in particular when W-148 lands", which is observable. D-ST-16 takes B3's condition | D-ST-14; D-ST-16 |
| B10: wording implies amending commits; prek timing unspecified | MINOR | Folded as proposed: fix commits, never amends; prek to a fixpoint before commits 2, 4 and 5 with R31 counts | §3; §7 R-1; §8.6; hand-off |
| B11: the §8.7 grep contradicts §4 | MINOR | Reproduced against the rev 2 fills (6 of 8 new goldens and operators.carbon's `CHECK:STDERR` lines name `StringBuf`; export.cpp does not). Folded with the measured list | §8.7 |
| B12: commands not self-contained; dates and cross-branch lines will be wrong | MINOR | Folded: (1) the absolute carbonbuild path and a concrete outdir; (2) the patch fixed (A-9); (3) `<date>` in the three amendments and strings.md; (4) values.md:168 → :176 named, and in the re-read list; (5) the hand-off names where the trailer comes from (the harness attribution notice) without reproducing it, because the brief forbids model names in repository files; row 51 and row 81 stay unchanged | §2.2; §2.5; §6; §8 preamble, §8.4; hand-off |

## Review fold record (rev 3, 2026-10-13)

The focused re-review of rev 2 (381f79b92) returned APPROVE-WITH-AMENDMENTS. It
re-measured both of rev A's BLOCKERs in its own scratch tree
(`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/st1-rr`:
an install copy carrying the §2.1 block extracted from this file, export.cpp
with §2.2 applied by `git apply`, a file_test and busybox relinked from the
trunk objects) and found both RESOLVED: the full manifest ran 1942 tests, 1940
passed, the two expected refills failed and nothing aborted; the eight new
goldens filled at M-11's sizes, byte-identical to rev 2's fills; the six
programs passed and §8.8's shim reproduced M-23's counts. It added one MAJOR and
three MINOR findings. Its ids are cited here with an "RR-" prefix, so that its
A-1 and A-2 are not confused with rev A's. All six are folded or verified; none
is rejected. The fixer re-read every cited SAFE-1 line on
claude/carbon-fork-0-1-safe (adaae4e35) and re-ran the one measurement a finding
rests on (M-25). Rev 3 changes no text of §2.1 to §2.4, so M-10, M-11, M-12,
M-19 to M-21, M-23 and M-24 stand as measured.

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| RR-A-1: the interop golden's `as_str` split; W-165; the two rev 1 predicted goldens | BLOCKER (rev A's A-1) | Verified RESOLVED by the re-review (the rev 1 split still aborts its relinked file_test; the rev 2 source fills to 332 lines, 264 CHECK, and passes; the trunk-only reproducer aborts unmodified trunk; real libc++ is unaffected). No change required | None |
| RR-A-2: the `StringBuf` to `str` use-after-free | BLOCKER (rev A's A-2) | Verified RESOLVED by the re-review (an independent probe reproduces the four shapes on the ST-1 install, and the documented `-> Core.StringBuf` shape is clean, `malloc=13 free=12 bad=0`; W-166 is named everywhere required; no ST-1 program, golden or doc example uses a W-166 shape). No change required for the blocker; its precision gap is RR-N-2 | None |
| RR-N-1: self-aliasing append (`s += s`) is presented as designed, but F-013 rejects it, so D-ST-14's "no ST-1 program should trip W-148" is false | MAJOR | Reproduced: on the safe branch, T2's value-binding clause (temporal_safety.md:249-257) and M8 (mutation_safety.md:272-283) make the by-value `other` a shared loan on `s`, M3(d) (:172) makes the `ref self` call invalidating, and T4 (temporal_safety.md:303-317) makes the pair `StrictSharedBorrowInvalidated`; at runtime `s += Core.StringBuf.Make(s)` and `t += t` are correct and leak-free (M-25: `abcabc`, 6, 1, `xyxy`, `malloc=6 free=5 bad=0`). Folded with the reviewer's second option, keeping the lines: D-ST-7, §1.4 and strings.md state the append as accepted and memory-safe today and rejected once W-148 lands, with `s += Core.StringBuf.Make(s);` as the spelling that stays valid. D-ST-14 names the three self-appends and `View` (expected to need `bound b`) as expected W-148 trips, with the program rewrite measured now (M-25: 6/6 PASS, 9/8 and 30/29) and the golden rewrite assigned to W-148's landing. D-ST-6's break-condition remedy covers them, R-10 makes the trip falsifiable, and the SAFE-1 reconciliation gains the T4 example. The lines stay rather than being rewritten now because, unlike line 26 (B1), a self-append does not rely on an undesigned lifetime, is memory-safe under any lifetime rule, and is the suite's only exercise of D-ST-7's read-before-free order | Status; §0.2 M-25; D-ST-6; D-ST-7; D-ST-14; §1.4; §2.5 strings.md; §2.6 SAFE-1 reconciliation (7); §7 R-10; §8.8; hand-off |
| RR-N-2: the W-144 addition names the impl's `Convert`, but by T5(e) only the interface declaration can carry `bound self` | MINOR | Reproduced: T5(e) (temporal_safety.md:507-512) lets an impl drop but not add `bound`; SP3 (spatial_safety.md:159-201) puts `bound self` on the declarations `IndexWith.At` and `Copy.Op` but not on `ImplicitAs(Dest).Convert` (core/prelude/operators/as.carbon:23), although SP3 lists `Slice(T) as ImplicitAs(Slice(const T))`'s `Convert` as a view producer; T2's "every `ImplicitAs` impl is not a loan boundary" (:264-273) does not cover an owner-to-view conversion. Folded as proposed: D-ST-6, D-ST-11 and §2.6's W-144 item name the interface declaration (with `As(Dest).Convert` and `UnsafeAs(Dest).Convert`, through which the workaround blankets at as.carbon:27-34 forward `b as str`), and the SAFE-1 reconciliation gains item (6) for the gap shared with SP3 and the T2 clause | D-ST-6; D-ST-11; §2.6 W-144, SAFE-1 reconciliation (6) |
| RR-N-3: W-167 and W-160 are filed under row 41, whose DONE text says "access control fully checked" | MINOR | Reproduced (the row's text is identical on trunk and on the cmake, safe, sc, ua2 and ev branches, at :41 to :45). Folded with the reviewer's second option: row 41 stays DONE and its text becomes "access control checked for member access (struct-literal construction is not: W-167, classes.md:2156-2159) and lowered"; W-160 stays ledger-only, because the row makes no claim about assignment; no header count changes | Outcome paragraph; D-ST-16; §2.6 row 41; hand-off |
| RR-N-4: the autoupdate pass counts use two conventions | MINOR | Reproduced (M-11 counted changing passes, §3 and §8.2 counted runs for operators.carbon and changing passes for the rest). Folded as proposed: runs are counted up to and including the one that prints only `.`; operators.carbon converges on its third run, every other golden on its second | §0.2 M-10, M-11; §2.3 refill paragraph; §3 commit 3; §4 operators row; §8.2 |

## Sign-off

Three reviews, every finding folded or verified, none rejected:

| Review | Of | Verdict | Findings |
| --- | --- | --- | --- |
| Rev A: design soundness and toolchain correctness | rev 1 (bff5ba4e8) | REJECT | 11: 2 BLOCKER, 2 MAJOR, 7 MINOR; all folded in rev 2 (381f79b92) |
| Rev B | rev 1 (bff5ba4e8) | APPROVE-WITH-AMENDMENTS | 12: 5 MAJOR, 7 MINOR; all folded in rev 2 (381f79b92) |
| Focused re-review | rev 2 (381f79b92) | APPROVE-WITH-AMENDMENTS | 6: rev A's 2 BLOCKERs verified RESOLVED, 1 MAJOR and 3 MINOR new; the four new ones folded in rev 3 (this revision) |

The re-review's verdict is not REJECT, and rev 3 folds all of its findings, so
the plan is signed off for implementation at rev 3: R29(c)'s two plan reviews
and the focused re-review that rev A's REJECT required are complete. The
implementation follows §3's commits 2 to 5 on `claude/carbon-fork-0-1-st`,
against the measured texts of §2.1 to §2.4 and §4's matrix, with §8's
verification, and residues allocated from W-160 by the rule of the id allocation
paragraph. Merge position for fork/ORCHESTRATION.md's merge order, which defers
ST-1's position to this sign-off: after PR 53, PR 51, PR 52 and SC-1, the order
§5's deltas, §6's rebase notes and §2.6's conditional SAFE-1 reconciliation
assume; ST-1 and EV-1 share only the same-anchor records of §6, so their
relative order is the orchestrator's.

## Implementation review fold record (2026-10-13)

Two implementation reviews of commits 2 to 4 (84ff63560, 16a87052f,
d8d10bf70) returned APPROVE-WITH-FIXES: review 1 (ids RV1-1 to RV1-6) with 6
MINOR findings, review 2 (ids ST1-IR2-1 to ST1-IR2-9) with 9 MINOR. Neither
found a BLOCKER or a MAJOR, and none of their probes broke the prelude. Three
pairs are one finding seen twice (RV1-1 and ST1-IR2-9, RV1-4 and ST1-IR2-2,
RV1-5 and ST1-IR2-4). All 15 are folded and none is rejected; two name an
action that the session's permission policy refused to the fixer, the merge of
ST1-IR2-6 and the harness change of ST1-IR2-8, and those are handed on with
their fold recorded below. The fix commit changes no code, golden or program,
so the build of 84ff63560 and commit 3's fill stand. The fixer reproduced every
finding about behavior in its own scratch tree (session scratch
`st1-impl/fix`: the ST-1 install of 84ff63560, a private copy of review 1's
runtimes cache for that install digest, and the §8.8 shim, byte-identical to
its text above), with each expected line written down before the run.

| Finding | Grade | Disposition | Where folded |
| --- | --- | --- | --- |
| RV1-1 / ST1-IR2-9: two §4 key lines are not reproduced literally | MINOR | Reproduced (check compare.carbon:485 reads `init %str.3d4 to %.loc9_16.1 = call`; in lower subscript.carbon the `_CConvert.UInt...:ImplicitAs` body calls `_CConvert.Int...:FromUInt` at :58, whose body has the `zext` at :65). Folded: both §4 rows amended at landing with the fill's lines; §2.6's decision-log entry gains one sentence; no golden changes | §4 `generic.carbon` and lower subscript rows; §2.6 decision log |
| RV1-2: W-166's shapes leave out a `+` result assigned to an existing `str` | MINOR | Reproduced (`assign.carbon`: `w = "ef" + "gh";` and then one 4-byte `Make` prints `YYYY`; the `var`-owner control prints `efgh`; shim `malloc=5 free=4 bad=0`). Folded: strings.md's W-166 bullet opens "For example" and names the shape; §1.7 and §2.6's W-166 evidence gain it | strings.md 0.1 limits; §1.7 W-166; §2.6 W-166 |
| RV1-3: strings.md says generic code sees `str` as `Core.Ordered` without W-164 | MINOR | Reproduced (`gen_if.carbon`: the `if`-expression `Min("pear", "apple")` aborts `carbon compile`, exit 134, with the PHI assertion; the statement form prints 5). Folded: one sentence at Comparison with the statement form, and W-164 joins strings.md's 0.1 limits; §2.5 records the departure from its list | strings.md Comparison and 0.1 limits; §2.5 |
| RV1-4 / ST1-IR2-2: the "landed 2026-10-13" stamps assume a merge date | MINOR | Verified (none of PRs 51, 52, 53 or SC-1 is merged; trunk is 9d3ca60a3). Folded as both propose: every landing-date stamp is on the hand-off's re-read list and in commit 5's ORCHESTRATION note, to be re-stamped in a new commit at the merge if the date differs; no stamp changes now, because the merge date is not known | §2.6 ORCHESTRATION; hand-off |
| RV1-5 / ST1-IR2-4: the records name a conformance directory the run did not use, and a cache path that did not exist | MINOR | Reproduced (/home/user/carbon-build/carbon-st/cache did not exist before this round, and /root/.cache/carbon_runtimes holds no runtimes for 84ff63560). Cause, read from toolchain/driver/runtimes_cache.cpp:193-203: when `XDG_CACHE_HOME` names a missing directory the driver falls back to a temporary cache per invocation, so every `carbon link` of that run rebuilt the runtimes and nothing persisted (the run took 2917 s; the fix round's first attempt, with the directory still missing, was stopped after 21 programs and restarted once the directory existed). Folded: row 77 cites a run by toolchain sha, `generated` timestamp and totals; §8.4 records the as-run directories and that the cache directory must exist; the fix round re-ran conformance and the §8.8 shim with that `XDG_CACHE_HOME` (results below) | §2.6 row 77; §8.4 |
| RV1-6: each direct C++ use of a `StringBuf` repeats the prelude-located TODO | MINOR | Reproduced (`twice.carbon`, two `Cpp.ViewSize(s)` calls: the `SemanticsTodo` at string.carbon:141:1 twice, each before its `CppCallArgTypeNotSupported`; exit 1, no crash). Folded as directed, with no code change: W-161's notes | §2.6 W-161 |
| ST1-IR2-1: strings.md says `Size()` and comparison need the view, and introduces the accepted forms as the error | MINOR | Verified against string.carbon:150 (`StringBuf.Size`) and :205-275 (the `EqWith` and `OrderedWith` impls with a `StringBuf` operand). Folded: Overview now says `Size()` and the comparisons are on both types and subscripts on `str` only; Ownership and lifetime introduces "the two accepted forms"; §1.1 amended. The optional point stands as written: `IsEq[T: Core.Eq]` with `str` prints 1 then 0 (`gen_stmt.carbon`), so the `Core.Eq` claim is measured, though no golden pins it | strings.md Overview, Ownership and lifetime; §1.1 |
| ST1-IR2-3: row 77's decision-log citation matches no heading | MINOR | Verified (rows 79 and 82 cite "SL-1: ..." and "SL-2: ...", the headings at decision-log.md:3747 and :2863 without their dates). Folded: row 77 and W-057 cite "ST-1 / F-014: str comparison, Core.StringBuf, concatenation" | §2.6 W-057, row 77 |
| ST1-IR2-5: the id re-read is stale for EV, and ids are written into three files | MINOR | Reproduced (68 refs with a ledger: trunk W-125, ua2 W-127, cmake W-133, safe W-150, sc W-151, ev W-155; W-160 to W-167 unfiled on all). Folded: §2.6's id re-scan item with the renumbering file list, the ORCHESTRATION note's W-126 and W-148 condition, and the hand-off | §2.6; hand-off |
| ST1-IR2-6: the branch lacks trunk 9d3ca60a3 | MINOR | Verified (`git diff --stat 80a11e7f0 9d3ca60a3`: fork/ORCHESTRATION.md only, 11 insertions, the reservations at :69-75 and the st row at :413). The fixer's merge was refused by the session's permission policy, so the branch is unchanged. Folded as commit 5's first step: a merge commit, never a rebase (the EV-1 precedent dff212ccc), then the st row edited in place | §2.6 ORCHESTRATION |
| ST1-IR2-7: the interoperability amendment does not link strings.md | MINOR | Folded as recommended: the amendment ends `See [Strings](../strings.md#interoperability).`; §2.5 records the departure from its text | interoperability/README.md:303-306; §2.5 |
| ST1-IR2-8: gate.sh prints "0 failed" on a red run | MINOR | Reproduced (the unmodified script, fed gate_commit2.log, prints `1940 passed, 0 failed (exit 1, ...)` and no failing files). A fix was written and checked in scratch (`st1-impl/fix/gate.sh.new`: failures counted from the unique `[  FAILED  ] ToolchainFileTest` lines and as ran minus passed, a `gate: PASS` or `gate: FAILED` line, the failing files always listed, an aborted run reported with the log tail): fed gate_commit2.log it prints 10 failed, FAILED and the ten files; gate_commit3.log, 1950 passed and PASS; a truncated log with exit 134, FAILED and the tail. It is not installed: the session's permission policy refused replacing the shared harness script, so it goes with the carbonbuild landing (the R28 amendment). §8.3 reads the verdict from the exit status and the log | §8.3 |

Fix-round verification, at the fix commit's tree with the toolchain of
84ff63560 (the commit changes no file the gate or the runner compiles):

-   **Gate:** gate.sh printed `1950 passed, 0 failed (exit 0, 61s)`, and the
    log reads `[==========] 1950 tests from 1 test suite ran.` and
    `[  PASSED  ] 1950 tests.` with no `[  FAILED  ]` line.
-   **Conformance** into `st1-impl/conf-fix`, with
    `XDG_CACHE_HOME=/home/user/carbon-build/carbon-st/cache` created first:
    scoreboard generated 2026-10-13T19:47:00Z, PASS 133, COMPILE-FAIL 0,
    LINK-FAIL 0, RUN-FAIL 0, OUTPUT-MISMATCH 0, DIFF-MISMATCH 0, SKIP 21 of
    154, bullets 48 PASS and 8 SKIP of 56, in 83.4 s. Against
    fork/conformance/out/scoreboard.json (128/0/22 over 150) the only status
    changes are the five String programs of §5, and against the
    implementation run's scoreboard there is none. The String bullet is PASS
    over six programs. This is §5's expected result, not of record.
-   **Allocation check (§8.8)** on that run's six String binaries: 1/0, 2/1,
    3/2, 8/7, 20/19 and 28/27 (malloc/free), every one `bad=0`, M-23
    exactly.
-   **Runner:** `--self-test` prints "154 programs parsed, 56 bullets in
    table, OK".
-   **Docs:** R27 does not apply to the edits (strings.md's API listing is
    unchanged). R31 counts before and after this commit's prek: strings.md
    h1 1, h2 10, h3 2 before and after, dash items 47 before and 48 after
    (the new W-164 limit), numbered items 0; the interoperability README h1
    1, h2 13, h3 16, dash items 37 and numbered items 3, unchanged; this
    plan h1 1, h2 13 before and 14 after (this section), h3 17, dash items
    117 before and 123 after (§2.6's id re-scan item and this list's five),
    numbered items 20. prek reached its fixpoint on the second run; the
    first rewrapped only this commit's own §2.5 lines.
