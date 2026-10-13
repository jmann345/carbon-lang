<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# String plan: byte-wise comparison, the owning `Core.StringBuf` and concatenation (ST-1, W-057)

**Status:** rev 1, the planner's draft (2026-10-13), for the two plan reviews of
R29(c) (rev A: design fidelity; rev B: toolchain reality). Nothing below is
implemented. Branch `claude/carbon-fork-0-1-st`, cut from trunk 80a11e7f0, whose
toolchain, core and docs sources are identical to 0bdce60a5 (the only later
trunk commits are fork/ORCHESTRATION.md stamps). Every line number below is
against 80a11e7f0 and was re-read for this plan. Every measured outcome in §0.2
was taken in this container with the trunk build
(`/home/user/carbon-build/carbon-trunk`, `carbon version` 0.0.0-0.dev+0bdce60a5)
and its file_test, with the prelude of §2.1 applied to a COPY of the install
tree in the planner's scratch directory: nothing was built, nothing was
installed, no worktree was modified, and the owner's runner was not used (R28).

**Item:** W-057 ("W9c: string equality, concatenation, and owning variant", size
M, subsystem core/prelude, bullet "Stdlib: String and string-literal types").
**Milestone row:** fork/gap-analysis.md:77, PARTIAL. The row moves to :78, :80
and :81 on the CM-1, SAFE-1 and SC-1 branches, so records refer to it by its
bullet text (R7) and re-read its line at rebase. **Criterion:** the bullet text,
docs/project/milestones.md:202 "String and related types used with string
literals" (under "Types with important language support", :201). **Outcome this
plan commits to:** row 77 PARTIAL → DONE, expected and not of record until a
conformance run of record, with the 0.1 limits filed as W-160..W-164 under the
precedent of row 82 (DONE with filed limits W-119/W-120). The bullet's PASS
rollup does not move (it already rolls up PASS with one SKIP), so the bullet
count stays 48/56.

**Id allocation (recorded so no workstream collides):** the ledger maximum
across trunk and every live branch is W-150 (SAFE-1, PR 53); W-151 is reserved
for SC-1's W-144 renumber; W-152..W-159 are reserved for the concurrent EV-1
workstream (fork/evaluator/plan.md on claude/carbon-fork-0-1-ev); ST-1's
residues start at W-160 and this plan uses W-160..W-164. Fork design ids run
F-006..F-013 (F-012 is SL-1/SL-2, F-013 is SAFE-1, held in PR 53); ST-1 mints
**F-014** (D-ST-1). No id is ever reused: if trunk's maximum has passed W-159 by
discharge, the residues are re-allocated from the then-maximum and the plan's
landed notes say so.

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
-   docs/design/expressions/arithmetic.md:184-187: "**TODO:** Decide whether
    strings are built-in types, and whether they support `+` for concatenation"
    (issue 457). Undecided upstream.
-   docs/design/expressions/comparison_operators.md:251-271 (`EqWith`, `x == y`
    calls `x.(EqWith(U).Equal)(y)`), :288-290 ("The `EqWith` overload is
    selected without considering possible implicit conversions"), :347-390
    (`OrderedWith`), :436-472 (transitivity, reversal consistency, `EqWith`
    refining `OrderedWith`).
-   docs/design/values.md:168: "**Open question:** The lifetimes of temporaries
    is not yet specified."
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
| 11 | min_prelude | LANDED, separate | toolchain/testing/testdata/min_prelude/parts/string.carbon: `class String { private var ptr: u8*; private var size: u64; }`, no impls, exported by primitives.carbon:24. Goldens that include min_prelude/full.carbon (`--expect-full-prelude`, 316 files) load the INSTALL tree's core/ instead; min_prelude goldens never see core/prelude (M-10). |
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
    caller; `x = D.Make(31)` never destroys the old value 30. The check golden
    of §4 shows the same placement for `StringBuf` (`Chain`'s intermediate
    temporary is destroyed just before `s` at the end of the function).
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
-   **M-11 (new goldens).** The §2.3 sources, autoupdated in a scratch mirror at
    substitute manifest paths (the trunk file_test runs only files in its
    compiled manifest): check `string/compare.carbon` 487 lines (439 CHECK),
    `string/string_buf.carbon` 912 (863), `string/fail_string_buf.carbon` 70
    (25); lower `string/compare.carbon` 81 (62), `string/string_buf.carbon` 136
    (109), `string/subscript.carbon` 130 (110); a second pass changes nothing
    (the R26 fixpoint in one pass). §4 quotes their key lines.
    `interop/cpp/stdlib/string_buf.carbon` could not be measured: it needs §2.2.
-   **M-12 (conformance).** The five §2.4 programs on the prototype: 5 PASS,
    including the DIFF check against the C++17 oracle; on the trunk install all
    five are COMPILE-FAIL (not vacuous). The full existing suite on the
    prototype: `PASS 128 ... SKIP 22` over 150, bullets 48 PASS / 0 FAIL / 8
    SKIP, and zero status differences against
    fork/conformance/out/scoreboard.json. `runner.py --self-test` passes on
    80a11e7f0.
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
    (`git show` grep).
-   **M-17 (an access hole not to rely on).** A file-scope function returning
    `{.ptr = p, .size = n}` as a class with private fields compiles, while
    reading `x.size` from file scope is "cannot access private member".
    classes.md:2156-2159 forbids the former, so the prelude does not use it
    (D-ST-11).
-   **M-18 (the orphan rule).** A scratch prelude library `string_orphan` (added
    to the copy's prelude manifest for a check-only run, then removed) declaring
    `impl String as AddWith(String) where .Result = StringBufX` with
    `StringBufX` defined there: "orphan `impl` found; something in the self-type
    or constraint must be defined in the same file". So `String`'s `AddWith`
    impls live in string.carbon, and `StringBuf` must too (D-ST-10).

Not measured, and why: the §2.2 fix's runtime behavior and the two goldens it
changes (operators.carbon's split and interop/cpp/stdlib/string_buf.carbon) need
a toolchain built from this worktree, which the planner does not build (the
brief); §4 predicts them by reading the code paths
(check/cpp/type_mapping.cpp:530-598, check/cpp/operators.cpp:360-385, :802-835,
check/operator.cpp:74-88). Bazel-only tests, macOS, Windows and an opt-mode
toolchain were not available (§8).

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
    concatenation (arithmetic.md:184-187, issue 457 undecided) have no proposal
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
    allocation would hide cost (pinned as `fail_view_to_owned`). A view is
    valid until its `StringBuf` is destroyed or appended to. The toolchain
    keeps a `let` or `var` initializer's temporaries alive to the end of the
    enclosing block (M-7), so `let c: str = a + b;`, the SKIP program's line
    26, views a live string for the rest of the block. values.md:168 leaves
    temporary lifetimes open, and F-013's D-SAFE-12 (held in PR 53) would
    diagnose a view of a temporary used past its full-expression once the stage
    4 loan checker exists (W-148); that future rewrite of line 26 to `var c:
    Core.StringBuf = a + b;` is a hand-off note for W-148, not a change now.
    Break condition: temporaries become full-expression-scoped in the
    toolchain; then string_missing_ops.carbon:26 is rewritten in that change,
    with its EXPECT unchanged.
-   **D-ST-7: concatenation.** `+` on each of the four operand pairs of `str`
    and `StringBuf` builds a new `StringBuf` (`where .Result = StringBuf`)
    through `StringBuf.Concat(a: str, b: str)`; `+=` with a `str` or `StringBuf`
    right operand appends by allocating the joined block, copying both parts,
    freeing the old block and only then updating `self`, so `s += s` is sound
    (M-3, M-4). No `char` or `CharLiteral` operand (`s + 'c'` stays "cannot
    access member of interface `Core.AddWith(Core.CharLiteral)`"). Loops append
    with `+=`: `s = s + t` leaks through M-5's assignment gap, which is W-160.
    Break condition: upstream decides issue 457 against `+` for strings; the
    four `AddWith` impls are deleted and `Concat` and `+=` remain.
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
    list. Break condition: `friend` is implemented
    (check/handle_class.cpp:364-371 is a TODO today); then `UnsafeMake` becomes
    private to `String` and `StringBuf`.
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
    body and EXPECT values unchanged: its two assertions are design-derived
    (`"hi" == "hi"` is true under byte equality; the concatenation of two 2-byte
    strings has 4 bytes) and the program is right as written under README.md's
    owning-to-view conversion and the measured lifetime (D-ST-6). Four programs
    are added (§2.4): the ordering differential pair, the ownership and lifetime
    program, concatenation in loops, and the subscript fixes. Names are kept
    (string_missing_ops stays string_missing_ops: the scoreboard identity
    matters more than the name). Break condition: none.
-   **D-ST-15: docs.** A new normative page docs/design/strings.md, marked as a
    dated fork amendment, plus dated blockquote amendments (never rewrites) at
    README.md "String types", arithmetic.md "Strings" and the interop README's
    `std::string_view` and `str` subsection (§2.5). Break condition: upstream's
    string design lands; strings.md is then reconciled with it.
-   **D-ST-16: row 77 becomes DONE with filed limits; `str` subscripts stay
    unchecked at run time.** The bullet's text is met: the string types used
    with string literals exist as a view and an owning type with comparison,
    concatenation and conversion. The 0.1 limits are filed and named in the row:
    assignment leaks (W-160), owning-string C++ interop (W-161), no run-time
    bounds check on `str` subscripts (W-162: a checked `At` would have to be a
    Carbon body, which loses the compile-time `StringAt` diagnostics that
    upstream's string_indexing.carbon `fail_` splits pin, so the check belongs
    in the builtin's lowering, the stage 2 hardening SAFE-1 files as W-146),
    compile-time string comparison (W-163). W-164 (M-15) is filed under the
    generics bullet. Break condition: a reviewer shows a bullet requirement that
    none of the programs exercises; then the row stays PARTIAL with that
    requirement named.

## §1 Design

### §1.1 The two types

`str` is unchanged: the prelude class `Core.String`, a non-owning view of bytes
(`{ptr: Char*, size: i64}`, copyable, `UnformedInit`), the type of every string
literal (README.md:645-678, string_literals.md), mapped to and from
`std::string_view`. It gains the comparison impls (§1.2), the `+` impls (§1.4),
the public `UnsafeMake` (D-ST-11) and the `i64` subscript parameter (§1.5).

`Core.StringBuf` is new: an owning byte string with the same `{pointer, size}`
representation over a block from `"heap.allocate"`, freed by its declared
`Destroy` impl. Its API is deliberately small; the view carries the read API.

| Member | Meaning |
| --- | --- |
| `fn Make(s: str) -> Self` | a new string holding a copy of `s`'s bytes; also the explicit deep copy of a `StringBuf` (which converts to `str` at the call) |
| `fn Concat(a: str, b: str) -> Self` | a new string holding `a`'s bytes then `b`'s; what every `+` impl calls |
| `fn Size(self) -> i64` | the number of bytes |
| `fn AsStr(self) -> str` | the view; valid until `self` is destroyed or appended to |
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

-   A `StringBuf` owns exactly one block from `"heap.allocate"`, never null: a
    zero-byte request yields a one-byte block (lower/handle_call.cpp:769-775),
    and an allocation failure is the existing fail-stop "carbon: heap allocation
    failed; terminating" (as buf.carbon:33-35).
-   Its declared `Destroy` frees the block when a `var` goes out of scope, when
    a temporary dies (M-7: a declaration initializer's temporaries at the end of
    the enclosing block, an expression statement's at the end of the statement)
    and when an enclosing object without a declared `Destroy` is destroyed
    (M-8).
-   It is never copied implicitly (D-ST-5). A function returns a string it
    builds either directly (`return a + b;`, an initializing expression) or
    through `returned var` (M-7: destroyed once).
-   Known 0.1 gaps, each filed: `s = t;` does not destroy the old value
    (handle_operator.cpp:119-120), so the old block leaks (W-160); a class that
    declares its own `Destroy` does not destroy a `StringBuf` field (W-126 on
    the UA-2 branch; not re-filed here).

### §1.4 Concatenation

`+` on (`str`, `str`), (`str`, `StringBuf`), (`StringBuf`, `str`) and
(`StringBuf`, `StringBuf`) returns a new `StringBuf`; chains associate left to
right, so the expression of the next fence allocates one intermediate block,
destroyed with the enclosing block's temporaries, and one result. `+=` appends
in place and is the spelling for loops.

```carbon
var s: Core.StringBuf = piece + piece + piece;  // a temporary, then s
s += "!";  // one new block; the previous one is freed
```

The append is written so that its right operand may view `self` (`s += s`, or `s
+= v` where `v` is `s.AsStr()`): `JoinBytes` reads both parts into the new block
before `HeapFree` releases the old one. Sizes add in `i64`; a sum past the
address space reaches `"heap.allocate"` as an impossible count and fails-stop as
an allocation failure.

### §1.5 Subscripts

`s[i]` keeps its design meaning (the `IndexWith` rewrite, indexing.md) and its
compile-time diagnostics; D-ST-9 only moves the conversion of the subscript to
`i64` from nowhere (the builtin received `T` raw) into the impl's thunk. There
is still no run-time bounds check (W-162).

### §1.6 C++ interop

Unchanged: `str` and `std::string_view` map both ways. New and documented: a
`StringBuf` crosses as its view, `Cpp.F(s.AsStr())`; a `std::string_view`
returned by C++ compares with and concatenates to Carbon strings like any `str`
(measured: `Cpp.Hello() == s` and `Cpp.Hello() + "!" == "hello!"` print 1).
`Cpp.F(s)` with `s: Core.StringBuf` is diagnosed: "call argument of type
`Core.StringBuf` is not supported" together with the existing "semantics TODO:
`interop with non-identifier package name`" at the class (W-049's TODO,
export.cpp:139-142), the shape param_unsupported.carbon already pins for `i512`.
No `std::string` mapping in either direction (W-161).

### §1.7 What ST-1 does not do (residue titles; ids at §2.6)

-   W-160: assignment does not destroy the overwritten value, so `s = t;` on a
    `Core.StringBuf` (or a `Core.Buf`) leaks the old block; `=` does not use
    `AssignWith` (handle_operator.cpp:98-103, :119-120; assignment.md:176-184).
-   W-161: owning-string C++ interop: no `Core.StringBuf` and `std::string`
    mapping, and C++ overload resolution does not consider a Carbon
    `ImplicitAs(str)` conversion of a `Core.StringBuf` argument (`AsStr()` is
    required).
-   W-162: no run-time bounds check on `str` subscripts (`"string.at"` lowers to
    an unchecked `getelementptr`); `Core.Slice` and `Core.Buf` fail-stop
    (D-SL-4).
-   W-163: `str` comparisons are not compile-time constants (`C("x" == "x")` is
    rejected, M-14); needs a `"string.eq"`/`"string.compare"` builtin with an
    eval arm, or compile-time evaluation of function bodies.
-   W-164 (Generics, found while measuring, M-15): an `if` expression whose type
    is a symbolic `T` crashes lowering in a specific where `T` is a class type.
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

```diff
--- a/toolchain/check/cpp/export.cpp
+++ b/toolchain/check/cpp/export.cpp
@@ -293,6 +293,11 @@

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
format-checked (M-9).

### §2.3 Goldens (sources only: `// AUTOUPDATE`, no CHECK lines; R15/R16)

Seven new files. Their TIP lines are what autoupdate writes; the implementer may
omit them and let autoupdate add them. The prelude-dependent ones include
min_prelude/full.carbon (D-ST-13); every positive split brackets its code with
`//@dump-sem-ir-begin`/`end` (the SL-1 rule, fork/slices/plan.md §4).
Identifiers avoid the keyword list (a function named `Copy` was renamed `Dup`
after the measured dump showed `@Copy.loc7`).

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
  let v: str = a + a;
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
header is string_view.carbon's):

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
// `std::string_view` parameter through its explicit view `AsStr()` (D-ST-12);
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
  Cpp.Consume(b.AsStr());
}
//@dump-sem-ir-end

// --- fail_buf_arg.carbon

library "[[@TEST_NAME]]";

import Cpp library "string_view.h";

fn G(b: Core.StringBuf) {
  Cpp.Consume(b);
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
// declared `Destroy` impl runs at the end of the scope, and the temporary of a
// chained `+` is destroyed at the end of its statement.

fn Concat(a: str, b: str) -> i64 {
  var s: Core.StringBuf = a + b;
  s += "!";
  return s.Size();
}

fn Chain(a: str) -> i64 {
  var s: Core.StringBuf = a + a + a;
  return s.Size();
}
```

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
toolchain/check/testdata/interop/cpp/operators/operators.carbon, split
`fail_todo_import_plus_with_string_view_conversion.carbon` (D-ST-7 plus D-ST-12;
predicted in §4). The split keeps its name: it still fails, and its TODO (C++
operators found through conversions of Carbon operands) is still open; what
changes is that `s1 + s2` on `str` now has a Carbon meaning, so the conversion
of its result is what fails.

### §2.4 Conformance programs (bullet "Stdlib: String and string-literal types", R7)

fork/conformance/programs/stdlib/string_missing_ops.carbon, un-SKIPped: line 6
(`// SKIP:`) is deleted, the explanatory paragraph and the two body comments are
refreshed, the body and the EXPECT lines are unchanged:

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
// AddWith(String)`, whose result is the owning `Core.StringBuf`; the `let`
// binding views it through `StringBuf as ImplicitAs(str)`, and the temporary
// lives to the end of the scope. Both are in core/prelude/types/string.carbon.

import Core library "io";

fn Run() -> i32 {
  let a: str = "hi";
  let b: str = "hi";
  // `String as EqWith(String)`: byte-wise.
  Core.Print(if a == b then 1 else 0);
  // `String as AddWith(String)`: concatenation into a `Core.StringBuf`.
  let c: str = a + b;
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

fork/conformance/programs/stdlib/string_buf_lifetime.carbon:

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
// `ImplicitAs(str)`. Pinned here: a string built in a callee leaves it through
// `returned var` (a `return` of a plain `var` would copy, which `StringBuf`
// rejects); `s += s` appends a view of the string to itself, which is sound
// because the new block is filled before the old one is freed; a `StringBuf`
// field is destroyed with its enclosing object; and an explicit copy is
// independent of its source. Expected lines: "Hello, " (7 bytes) + "Carbon"
// (6) + "!" (1) = 14 bytes; "abc" + "abc"; the field's bytes; the copy gained
// a "?" so it differs (1); the source is unchanged.

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

fork/conformance/programs/stdlib/string_concat_loop.carbon:

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
// fork/string/plan.md). `acc += w` appends in place: each append allocates the
// joined block and frees the previous one, so the loop holds one block at a
// time. Expected lines: "Car" + "bon" + " " + "0.1" (10 bytes); ten
// self-appends double one byte to 2^10 = 1024 bytes, every one 'z' (1); a
// chained `+` builds "abc" three times plus "!" left to right, its
// intermediate `Core.StringBuf` temporaries destroyed when the enclosing block
// ends. Loops append with `+=`, never `acc = acc + w;`: assignment does not
// yet destroy the value it overwrites (check/handle_operator.cpp TODO), so
// that spelling would leak the previous block (fork/string/plan.md residue).

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
    (F-014, 2026-10-13): the string types as implemented; toolchain status: ST-1
    landed <date>". Sections: Overview (the two types, §1.1's table, the `str`
    keyword and the `Core.String`/`Core.Str` naming note with p006177:147-154);
    Comparison (§1.2, with the unsigned-byte order and its `char_traits<char>`
    parity); Concatenation (§1.4); Ownership and lifetime (§1.3, including
    `returned var`, the block-scoped temporaries of M-7 and values.md:168's open
    question); Subscripts (§1.5); Interoperability (§1.6); 0.1 limits
    (W-160..W-163 by title, each with its break condition); Alternatives
    considered (§7's A-1..A-8); References (README.md String types,
    string_literals.md, comparison_operators.md, arithmetic.md, p006177,
    milestones.md:202). Every API line in it is copied from §2.1 and diffed
    against the landed prelude (R27).
-   **docs/design/README.md**, after :634 ("There is an implicit conversion ...
    from `String` to `StringView`."): a blockquote "**Fork amendment
    (2026-10-13, F-014).** In the fork the view is `str`, the prelude class
    `Core.String` (the interop design's `Core.Str`), and the owning type is
    `Core.StringBuf`; `==`, `!=`, `<`, `<=`, `>` and `>=` compare bytes, `+`
    concatenates into a new `Core.StringBuf` and `+=` appends.", ending in a
    link to strings.md titled "Strings". No heading is added, so the README's
    table of contents does not change.
-   **docs/design/expressions/arithmetic.md**, after :187 (the Strings TODO): a
    blockquote "**Fork amendment (2026-10-13, F-014):** strings are library
    types, and `+` concatenates them: on `str` and `Core.StringBuf` operands it
    returns a new `Core.StringBuf`, and `+=` appends.", ending in a link to
    ../strings.md titled "Strings". The TODO line stays, as upstream's.
-   **docs/design/interoperability/README.md**, at the end of the
    `std::string_view` and `str` subsection (before its References, :304):
    "**Fork amendment (2026-10-13, F-014).** The owning `Core.StringBuf` has no
    C++ mapping; it reaches a `std::string_view` parameter through its view,
    `Cpp.F(s.AsStr())`, because C++ overload resolution does not see Carbon
    conversions (W-161)."

### §2.6 Records (commit 5, after verification)

-   **fork/inventory/work-items.json, W-057:** title prefixed "ST-1
    (LANDED <date>): ", kind `implemented`; evidence:
    core/prelude/types/string.carbon (the §2.1 line ranges as landed),
    check/cpp/export.cpp (the null check), the seven new goldens and the
    two refilled ones, the five programs; notes: what landed by D-ST
    number, §0.3 items 1-2 as corrected, "not prelude-only: one toolchain
    null check".
-   **New items W-160..W-164**, each `{id, kind, title, subsystem, size, bullet,
    evidence, blocked_by: [], notes}` with the mechanism and the break
    condition: W-160 (`todo-stub`, toolchain/check handle_operator.cpp, M,
    bullet "Stdlib: String and string-literal types"; evidence
    handle_operator.cpp:98-103 and :119-120, assignment.md:176-184, M-5;
    mechanism: build the destroy of the old value before the right-hand side, or
    route `=` through `AssignWith`); W-161 (`missing-feature`,
    toolchain/check/cpp, M, bullet "Type system: C++ interop — importing C++
    types / exporting Carbon types"; evidence export.cpp:139-142 (W-049's TODO),
    M-9; mechanism: a `std::string` mapping or a thunk-side conversion, and
    Carbon conversions in `InventClangArg`); W-162 (`missing-feature`,
    lower/handle_call.cpp `StringAt` arm, S, bullet String; evidence
    lower/handle_call.cpp:422-448, D-SL-4; mechanism: the `fail_stop` sequence
    in the lowering arm, SAFE-1's W-146 stage 2); W-163 (`missing-feature`,
    sem_ir builtins + eval, S, bullet String; evidence M-14); W-164
    (`todo-stub`, toolchain/lower, M, bullet "Generics: generic functions and
    types"; evidence M-15, the PHI assertion in `HandleInst(FunctionContext&,
    InstId, BranchWithArg)`).
-   **fork/gap-analysis.md:** row 77 (re-read its line) → DONE with the text
    below; the header counts as a DELTA (DONE +1, PARTIAL −1) applied to
    whatever the header reads at rebase, and its scoreboard sentence re-quoted
    from the run (R9); §W9 "Depends on" → "for the Optional half only" (§0.3
    item 6) and its paragraph's "owning/comparable String and a designed
    (non-placeholder) Optional remain" → "comparison, concatenation and the
    owning `Core.StringBuf` landed at ST-1 (W-057 DISCHARGED <date>); a designed
    (non-placeholder) Optional remains".
-   Row 77's new text: "DONE | ST-1 landed (W-057 DISCHARGED <date>,
    fork/string/plan.md, decision-log 'ST-1: str comparison, Core.StringBuf,
    concatenation (F-014)'): string literals are `str` (`Core.String`, the
    non-owning `{Char*, i64}` view, core/prelude/types/string.carbon) with
    byte-wise `==`/`!=` and lexicographic unsigned-byte `<`/`<=`/`>`/`>=`; the
    owning `Core.StringBuf` (a heap block freed by its declared `Destroy`; not
    copyable, `Core.StringBuf.Make(s)` copies; not `UnformedInit`) converts
    implicitly to `str`; `+` on `str` and `Core.StringBuf` operands builds a new
    `Core.StringBuf` and `+=` appends; `str` subscripts convert to `i64` before
    `"string.at"` (a literal subscript on a runtime string no longer crashes
    lowering; a `u8` above 127 no longer reads before the string). 0.1 limits,
    each a filed item: `s = t` leaks the overwritten block (W-160); no
    `std::string` mapping, a `Core.StringBuf` reaches C++ through `AsStr()`
    (W-161); `str` subscripts are not bounds-checked at run time (W-162); string
    comparisons are not compile-time constants (W-163). Conformance: 6/6
    programs PASS (stdlib/string_basic, string_missing_ops SKIP -> PASS,
    string_ordering_diff with a C++17 oracle, string_buf_lifetime,
    string_concat_loop, string_subscripts; <run>)."
-   **fork/decision-log.md:** a new entry at the top of "Decided" (the log is
    newest-first; SL-1's entry at :3747 is the shape): "### ST-1: str
    comparison, Core.StringBuf, concatenation (F-014) (<date>)", with the bullet
    flip, the commits, what landed by mechanism, D-ST-1..16 by number with their
    break conditions, the not-of-record status of the conformance totals, and
    the "_V-3a divergence-risk register entries_" paragraph: the fork-local name
    `Core.StringBuf` (README.md:629's owning `String`, p006177's `Core.Str`
    view: on upstream's rename, `StringBuf` takes the owning type's name); `+`
    on strings decides issue 457 for the fork; string.carbon:12, :14 and :37
    edit upstream lines and :26-31 insert into upstream's class (on an upstream
    edit of those lines, keep both and re-run M-10); export.cpp's null check
    (drop it when upstream adds one); operators.carbon's
    `fail_todo_import_plus_with_string_view_conversion` split now pins a
    different failure than upstream's (keep the fork's CHECK lines at the merge,
    re-run autoupdate).
-   **fork/ORCHESTRATION.md:** the status stamp (PR, verification record, the
    not-run list), a row for `claude/carbon-fork-0-1-st`, and the scope map
    (touched paths, §6).
-   **Cross-branch re-cites, conditional:** if SAFE-1 (PR 53) has landed first,
    its citations of string.carbon:16-27 and :16-28
    (docs/design/safety/mutation_safety.md:312, rust_interop.md:202,
    temporal_safety.md:736 and :960) become :16-32 and :16-34, and
    mutation_safety.md's `Plain` table gains the row "`Core.StringBuf` | no |
    owns a heap block, `impl as Destroy` frees it (string.carbon:141-171)" with
    a dated ST-1 note; the decision log's historical entries are not edited.

## §3 Commit structure (one PR, "ST-1: str comparison, Core.StringBuf and concatenation", R29(b))

1.  **Plan.** This file, rev 1 (this commit), then rev 2 folding the two plan
    reviews with each amendment marked "(amended <date>, review fold: rev A An /
    rev B Bn)" and a review fold record before a sign-off section, the SL-1
    shape.
2.  **Prelude and toolchain, CHECK-free.** core/prelude/types/string.carbon
    (§2.1), toolchain/check/cpp/export.cpp (§2.2), the seven golden sources of
    §2.3 with `// AUTOUPDATE` and no CHECK lines. The prelude and the null check
    MUST be in one commit: the prelude alone makes operators.carbon crash, and
    one crashing test aborts the whole file_test run (M-10). Expected gate on
    this commit alone: red on exactly nine goldens (the seven empty ones and the
    two refills), nothing else.
3.  **Fill.** Only the output of `autoupdate.sh` to its fixpoint (R26): the
    seven new goldens filled and the two refilled. Message "Autoupdate testdata
    goldens on the container arbiter" (the UA-2 precedent, f96fe8a7a). If a
    second pass changes anything, it is folded into this commit only when it is
    `.loc` renumbering; anything structural is a stop (R26).
4.  **Conformance and docs.** The five programs and the oracle of §2.4,
    string_basic.carbon's header, the regenerated conformance README table,
    docs/design/strings.md and the three amendments of §2.5.
5.  **Discharge.** The records of §2.6, written after §8's runs so every count
    is quoted from a run (R9).

## §4 Testdata matrix (R16: autoupdate fills; the predictions are confirmed or refuted by the fill)

"Measured" means the line was produced by the trunk file_test with the §2.1
prelude in the scratch mirror of M-11 (substitute paths change only the TIP
lines, the `ModuleID` and `source_filename` lines and the split-file names);
"predicted" means read from the code paths named, unmeasurable without §2.2.

| Golden | Split or function | Key lines | Basis |
| --- | --- | --- | --- |
| check/testdata/string/compare.carbon | `str_str.carbon` | `@Eq`: `impl_witness_access constants.%EqWith.impl_witness..., element0 [concrete = constants.%str.as.EqWith.impl.Equal]` and `%str.as.EqWith.impl.Equal.call: init bool = call %bound_method(%a.ref, %b.ref)`; `@Ne` element1 `NotEqual`; `@Lt` `%str.as.OrderedWith.impl.Less.call`; `@Ge` element3 `GreaterOrEquivalent`; the `imports` block gains `import_ref Core//prelude/types/string` entries for the four `OrderedWith` functions | measured |
| same | `mixed.carbon` | `@EqBufStr`: `%StringBuf.as.EqWith.impl.Equal.call`; `@LtStrBuf`: `%str.as.OrderedWith.impl.Less.call` through a second `str` impl (`@str.as.OrderedWith.impl.<hash>`, the (`str`, `StringBuf`) one); `@GtBufBuf`: element2, `%StringBuf.as.OrderedWith.impl.Greater.call` | measured |
| same | `generic.carbon` | `@UseMin`: `%Min.call: init %str... = call %Min.specific_fn(%String.val..., %String.val...)`, so `str` satisfies `Core.Ordered & Core.Copy` (a check golden: M-15's crash is in lowering) | measured |
| check/testdata/string/string_buf.carbon | `concat.carbon` | `@Concat`: `return %str.as.AddWith.impl.Op.call to %return.param`; `@Chain`: `temporary ..., %str.as.AddWith.impl.Op.call` (`ref %StringBuf`) then `%StringBuf.as.AddWith.impl.Op.call`, with the temporary's `Destroy` facet; `@Dup`: `converted %s.ref, %StringBuf.as.ImplicitAs.impl.Convert.call` feeding `%StringBuf.Make.call` | measured |
| same | `append.carbon` | `@Append`: two `%StringBuf.as.AddAssignWith.impl.Op.call` (the `"!"` literal and `b` itself), `%StringBuf.Size.call`, and `%Destroy.WithSelf.SelfDestruct.call` on `%b.var` before the return | measured |
| same | `view.carbon` | `@View`: `%StringBuf.as.ImplicitAs.impl.Convert.call: init %str` and `converted %b.ref`; `@LetView`: `temporary_storage` for the `StringBuf` and for the `str` | measured |
| check/testdata/string/fail_string_buf.carbon | `fail_copy` | `` error: cannot copy value of type `StringBuf` [CopyOfUncopyableType] `` and `` note: type `Core.StringBuf` does not implement interface `Core.Copy` [MissingImplInMemberAccessInContext] ``, column 34 | measured |
| same | `fail_return_var` | the same two at `return s;`, column 10 | measured |
| same | `fail_unformed` | `` error: cannot convert type `Core.StringBuf` into type implementing `Core.DefaultOrUnformed` [ConversionFailureTypeToFacet] `` | measured |
| same | `fail_view_to_owned` | `` error: cannot implicitly convert expression of type `str` to `Core.StringBuf` [ConversionFailure] `` and `` note: type `str` does not implement interface `Core.ImplicitAs(Core.StringBuf)` [MissingImplInMemberAccessInContext] `` | measured |
| check/testdata/interop/cpp/stdlib/string_buf.carbon | `as_str.carbon` | `@F`: `%StringBuf.AsStr.call` (`init %str`) passed to `Consume`'s thunk, as string_view.carbon's `Cpp.Consume("hello")` passes a `str` | predicted (check/cpp/thunk.cpp:246 `IsSimpleAbiType`: a class argument is passed by address, the shape of string_view.carbon's `Cpp.Consume("hello")`) |
| same | `fail_buf_arg.carbon` | `` error: call argument of type `Core.StringBuf` is not supported [CppCallArgTypeNotSupported] `` at the `b` of `Cpp.Consume(b)`, and `` {{.*}}/prelude/types/string.carbon:141:1: error: semantics TODO: `interop with non-identifier package name` [SemanticsTodo] `` over `class StringBuf {`; no crash | predicted (type_mapping.cpp:594-598; export.cpp:139-142; param_unsupported.carbon:77-84 has the same pair for `i512`) |
| lower/testdata/string/compare.carbon | `Eq`, `Lt`, `EqBufStr` | `call i1 @"_CEqual.String.Core:EqWith.<hash>.Core"(ptr %a, ptr %b)` with a matching `declare` (the body is in the prelude object); `@"_CLess.String.Core:OrderedWith.<hash>.Core"`; `@"_CEqual.StringBuf.Core:EqWith.<hash>.Core"` | measured |
| lower/testdata/string/string_buf.carbon | `Concat`, `Chain` | `call void @"_COp.String.Core:AddWith.<hash>.Core"(ptr %s.var, ptr %a, ptr %b)`; `call void @"_COp.StringBuf.Core:AddAssignWith.<hash>.Core"(ptr %s.var, ptr @String.val...)`; at exit `call void @_CSelfDestruct.Destroy.Core.<hash>(ptr %s.var)`, whose `linkonce_odr` body calls `@"_COp.StringBuf.Core:Destroy.Core"(ptr %self)` then the field walk (`ret void`); in `Chain` the intermediate `%...temp` is destroyed at the function's end, before `%s.var` (M-7) | measured |
| lower/testdata/string/subscript.carbon | `Literal`, `Unsigned`, `Signed` | `Literal`: `getelementptr inbounds i8, ptr ..., i64 0`; `Unsigned`: `call i64 @"_CConvert.UInt.<hash>.Core:ImplicitAs..."(i8 %i)`, whose body ends in `zext i8 ... to i64`, feeding the `getelementptr`; `Signed`: `getelementptr inbounds i8, ptr ..., i64 %i` | measured |
| check/testdata/operators/overloaded/string_indexing.carbon (refill) | `test_string_indexing.carbon` | two functions `@str.as.IndexWith.impl.At.1`/`.2` (the `i64` impl function and its thunk), the literal's `%Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i64`, the call results still `[concrete = constants.%int_84]` and `%int_116`; +79/−33 CHECK lines; the `fail_` splits' diagnostics unchanged | measured |
| check/testdata/interop/cpp/operators/operators.carbon (refill of one split) | `fail_todo_import_plus_with_string_view_conversion.carbon` | the four `MissingImplInMemberAccess` lines for `Core.AddWith(str)` are replaced by: `` call argument of type `Core.StringBuf` is not supported [CppCallArgTypeNotSupported] `` at column 46 (from `LookupCppConversion` → `InventClangArg`), the prelude-located `SemanticsTodo` of the row above, and `` cannot implicitly convert expression of type `Core.StringBuf` to `Cpp.StringViewConvertibleC` [ConversionFailure] `` with its `Core.ImplicitAs(Cpp.StringViewConvertibleC)` note; the order is autoupdate's; every other split unchanged | predicted (check/operator.cpp:74-88, check/cpp/operators.cpp:360-385; `LookupCppConversion` returns `None` on a null argument, so Carbon's own conversion diagnostic follows) |

Falsifiers: any crash; any golden outside this table in the fill's diff; a
`fail_` split that compiles; the `StringAt` values other than 84 and 116.

## §5 Conformance: one SKIP → PASS, four new; delta PASS +5 / SKIP −1 / total +4

On the floor of record (fork/conformance/out/scoreboard.json at 80a11e7f0: 128
PASS / 0 FAIL / 22 SKIP over 150, bullets 48/56) the expected result is **133
PASS / 0 FAIL / 21 SKIP over 154, bullets 48/56**, the String bullet PASS over
six programs. Other PRs land first (UA-2's +3 PASS −3 SKIP, SC-1's two
programs), so the absolute numbers are re-quoted from the run at rebase, never
added by hand (R9); only the delta is this plan's claim.

EXPECT derivations (R16(d): from the design and independent reasoning; each
matched the prototype run only after being written down):

-   **string_missing_ops** (unchanged): `"hi" == "hi"`: equal sizes, equal
    bytes, so `Equal` is true and the `if` yields 1. `a + b`: 2 + 2 bytes, so
    `c.Size()` is 4. Exit 0.
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
lowering and `At(long, 200 as u8)` printed a byte from before the string).

## §6 Churn inventory (verified by grep at 80a11e7f0)

-   **Files:** core/prelude/types/string.carbon (32 → 275 lines; four existing
    lines changed or followed by insertions, :12, :14, :25-26, :31);
    toolchain/check/cpp/export.cpp (+5); seven new goldens; two refilled
    goldens; five programs and one oracle (one modified, four new),
    string_basic.carbon's header; fork/conformance/README.md (generated table);
    docs/design/strings.md (new), docs/design/README.md,
    docs/design/expressions/arithmetic.md,
    docs/design/interoperability/README.md (one blockquote each);
    fork/string/plan.md, fork/inventory/work-items.json, fork/gap-analysis.md,
    fork/decision-log.md, fork/ORCHESTRATION.md.
-   **Goldens:** exactly two existing goldens change (M-10); no min_prelude
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
    (42841fa8d) changes check/ sources but none of ST-1's files, and none of its
    18 changed goldens uses strings (M-16); after either lands, the other
    rebases and refills its own new goldens. UA-2 (PR 51): goldens-only, and its
    three new goldens pass under the ST-1 prelude (M-16); both edit
    fork/gap-analysis.md, fork/inventory/work-items.json and
    fork/decision-log.md, in different rows. CM-1 (PR 52): records only overlap.
    SAFE-1 (PR 53): docs/design/README.md (blockquotes at :2148, :2168 and
    :3900, not near :634) and docs/design/expressions/arithmetic.md (a
    blockquote at :164, which moves the Strings TODO from :184-187 to :193-196):
    different hunks, a clean merge, re-read the line at rebase; its
    string.carbon citations are §2.6's conditional re-cite. EV-1 (W-062,
    documentation, plan only today): any tutorial text it writes about strings
    must describe the post-ST-1 API if ST-1 lands first; the orchestrator passes
    it §1.1's table.

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1: the operators.carbon refill is not what §4 predicts.** It is the one
    golden whose new output was not measured. Falsifier: the fill shows a crash
    (the null check is not on the path) or the old `AddWith(str)` lines (the
    impls did not load). Contingency: a crash means the null check belongs in
    `ExportNameScopeToCpp`'s other callers too (grep `ExportNameScopeToCpp(` at
    the fill), fixed in commit 2; any non-crash diagnostic set is accepted as
    filled.
-   **R-2: a golden outside §4 moves.** M-10 rules it out for the prelude; the
    null check only changes a path that crashed before, and no trunk golden
    crashes (1942/1942). Falsifier: the fill's diff names another file.
    Contingency: stop, diff it, and either explain it in §4 by a rev or revert
    the cause.
-   **R-3: temporary lifetimes change under the string programs.** values.md:168
    leaves them open; if the toolchain moves a declaration initializer's
    temporaries to the end of the full-expression, `let c: str = a + b;` views
    freed memory (string_missing_ops.carbon:26, check `view.carbon`). Falsifier:
    lower IR destroying the temporary before the next statement
    (lower/testdata/string/string_buf.carbon's `Chain` shows today's placement).
    Contingency: D-ST-6's break condition.
-   **R-4: a reviewer reads F-013 as already forbidding `let c: str = a + b;`.**
    It is a stage 4 rule (D-SAFE-12) of a design held in PR 53 with no checker
    (W-148); it would make line 26 an error, not a wrong answer. Falsifier: an
    F-013 text that makes the view of a block-scoped temporary invalid in 0.1.
    Contingency: rewrite line 26 to `var c: Core.StringBuf = a + b;` with EXPECT
    unchanged and say so in the commit (the R6 disclosure template).
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

Rejected alternatives (each with the evidence that rejects it):

-   **A-1: rename the view to `Core.Str` and make `Core.String` the owning
    type.** It matches p006177's names and README.md's owning `String`, but
    renames an upstream class keyed by name at literal.cpp:232,
    builtin_function_kind.cpp:209 and type_info.cpp:193, changes every golden
    that prints `@String`, `%String.val` or `_COp.String` (12 check and lower
    goldens print the class name) and union/basic.carbon:315's source (`var
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

1.  **Build** (no Bazel, ever; the owner declined installing it):
    `carbonbuild/build.sh /home/user/carbon-st` then `carbonbuild/install.sh
    /home/user/carbon-st` (outputs under /home/user/carbon-build/carbon-st/; 10
    to 17 minutes on 4 cores; `-Werror` clean, export.cpp already syntax-checked
    by M-9). `install/bin/carbon version` prints `0.0.0-0.dev+<sha>`.
2.  **Fill to fixpoint** (R26): `carbonbuild/autoupdate.sh /home/user/carbon-st`
    with the nine golden paths of §4, then the same command again; the second
    run must print only `.`. Commit 3 holds exactly the files the fill changed.
3.  **Gate:** `carbonbuild/gate.sh /home/user/carbon-st` → 1949 tests (1942 +
    7), 0 failed, no `!` or `?` marks.
4.  **Conformance:** `XDG_CACHE_HOME=/home/user/carbon-build/carbon-st/cache
    carbonbuild/conformance.sh /home/user/carbon-st <outdir>` (the new install
    digest gives a fresh runtimes cache; the first link is slow, R4) → the §5
    delta on the base of record, the String bullet PASS with six programs, no
    other status change. fork/conformance/out/scoreboard.json is NOT overwritten
    by a container run unless the orchestrator designates container runs as of
    record (the pending carbonbuild/R28 amendment); the totals go into the
    landed notes and the PR body.
5.  **Runner:** `python3 fork/conformance/runner.py --self-test` clean after
    `--update-readme-table` (R7).
6.  **prek fixpoint** (R22, R25): `uvx prek run --files <every changed file>`
    until a run changes nothing; for every changed `.md`, heading counts per
    level and list-item counts (R31(b)) recorded before and after, and the diff
    grepped for `^\+\s*#{1,6} [0-9]|^\+#[0-9]` (R31(c)); clang-format 21.1.8 on
    export.cpp and the oracle (R18).
7.  **Reconciliation greps:** `grep -n 'class StringBuf'
    core/prelude/types/string.carbon` → :141; `grep -rn 'StringBuf' core
    toolchain/check toolchain/lower toolchain/sem_ir` → string.carbon and the
    new goldens only (no C++ source names it); `grep -c 'if (!decl_context)'
    toolchain/check/cpp/export.cpp` → 4; `grep -rn 'string_missing_ops'
    fork/conformance/README.md` → a `run` row.
8.  **Discharge:** §2.6, then the ORCHESTRATION stamp; the PR body carries the
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

-   Copy §2.1, §2.2, §2.3 and §2.4 verbatim from this file: each is the exact
    text the §0.2 measurements ran. If anything must change, re-run M-2, M-10
    and M-12 against your build before committing, and record the change in the
    plan's landed notes.
-   Commit 2 is prelude AND export.cpp together (M-10). If file_test aborts with
    "isa<> used on a null pointer", the null check is missing or misplaced.
-   Do not write CHECK lines, do not edit a filled golden, and do not touch
    min_prelude (D-ST-13). The fill must change exactly the nine files of §4.
-   The prelude-located TODO in `fail_buf_arg` and in operators.carbon pins
    string.carbon:141 (`class StringBuf`); an edit above that line moves both,
    and autoupdate follows.
-   In programs and docs, loops append with `+=`; never show `s = s + t` (W-160)
    and never pass a `Core.StringBuf` straight to C++ (use `AsStr()`).
-   A function that builds a string returns it with `returned var` or as a
    direct `return a + b;`; `return s;` of a plain `var` is a copy error
    (pinned).
-   docs/design/strings.md's API listing is copied from the landed string.carbon
    and diffed against it before commit 4 (R27).
-   Re-read gap row 77's line, the header counts and the scoreboard base at
    rebase (R9); allocate W-160..W-164 only after checking trunk's maximum id
    and the EV-1/SC-1 reservations.
-   Never run `git add -A` (R20); commit with the author, committer and trailer
    conventions of the brief; do not push or open the PR until the orchestrator
    says so.
