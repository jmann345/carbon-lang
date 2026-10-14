<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Optional plan: ownership, the `MaybeUnformed` representation fix, a checked `Get()` (OP-2)

**Status:** rev 1, 2026-10-14 -- the planner's draft, not yet reviewed (R29(c):
two plan reviews follow). Nothing below is implemented. Branch
`claude/carbon-fork-0-1-op2`, cut from the OP-1 branch head 379f20f67 (PR 56,
held open), whose toolchain and core sources equal those of OP-1's build
5d9edb3e0 (`git diff --name-only 5d9edb3e0 379f20f67 -- toolchain core` names
only OP-1's three testdata files). OP-2 is a STACKED workstream: it lands after
PR 56 and closes the three items that keep the gap row "Stdlib: Optional"
PARTIAL under OP-1's D-OP-13 (fork/optional/plan.md). Every line number below
is against 379f20f67 unless a branch is named. Every measured outcome in §0.2
was taken in this container with OP-1's carbonbuild toolchain
(`/home/user/carbon-build/carbon-op`, `carbon version` 0.0.0-0.dev+5d9edb3e0),
the trunk toolchain (`/home/user/carbon-build/carbon-trunk`, 0bdce60a5) or the
upstream nightly 2026.10.12, always on COPIES of the install trees and on
binaries relinked from copies of the build's objects (§0.2, setup); no
toolchain was built, nothing under /home/user/carbon-build was modified, no
worktree other than this one was touched, and the owner's runner was not used
(R28).

**Items:** W-170 (a `Core.Optional` never destroys the value it holds;
row-bounding), W-171 (the default storage mis-lowers `MaybeUnformed(T) unsafe
as T` when `T`'s value representation differs; row-bounding) and W-173 (`Get()`
on an empty value is unchecked; the TY4 gate of D-OP-13). **Milestone row:**
fork/gap-analysis.md:80 on this branch, "Stdlib: Optional", PARTIAL; records
refer to it by its bullet text (R7). **Criterion:** OP-1's D-OP-13 break
condition, verbatim: "`optional_destroys_value`, `optional_bool` and
`optional_nested_pointer` [...] all un-SKIP to PASS in a conformance run of
record (W-170 and W-171 landed), and F-013's TY4 is not falsified by `Get()` on
an empty `Optional(T*)` (W-173 lands a checked `Get`, or TY4 is amended to name
that obligation); only then does the row move to DONE, with the remaining
residues as filed limits, in the commit that un-SKIPs the arbiters and quotes
that run, never by a records-only commit (R9)".

**Outcome this plan commits to:** the three arbiters un-SKIP to PASS with their
EXPECT values unchanged and re-derived from F-015 (R16(d)); two toolchain
defects are fixed at their root, both upstream defects too (upstream trunk head
d4f1ec203 carries the same code, M-3, M-5): (1) lowering converts a value
between `MaybeUnformed(T)`'s and `T`'s value representations, which can differ
per specific since upstream PR 6334, and convert.cpp's CHECK tests the operand
its comment names (W-171, D-OP2-1, D-OP2-2); (2) an adapter is destroyed as its
adapted type, where the toolchain treated every adapter as trivially
destructible (W-170, D-OP2-3); the prelude's default storage then declares the
`Destroy` that destroys its value when it holds one, while `Core.Optional` and
the pointer niche declare none, so `Core.Optional(T*)` stays trivially
destructible and a union may still hold one (D-OP2-4); `Get()` on an empty value
fails-stop, so TY4 holds as written (W-173, D-OP2-7). No existing line of
core/prelude/types/optional.carbon moves (D-OP2-8). Three new conformance
programs (one with a C++17 `std::optional` oracle) and five new goldens are
added; 28 existing goldens are refilled by autoupdate. The row moves PARTIAL →
DONE, **expected, not of record** (Actions is disabled), with two new limits
filed (W-196, W-197), neither an operation of `Core.Optional` that fails
through its documented API (D-OP2-12).

**Id allocation (recorded so no workstream collides):** re-scanned for this plan
over trunk (f67ab650d), origin/trunk and every local and `origin`
`claude/carbon-fork-0-1-*` ref: the ledger maximum is W-195 (OP-1, on the op and
op2 branches); sc W-168, st W-167, ev W-155, safe W-150, cmake W-133, ua2
W-127, trunk W-125. W-169 is SC-1's reserve; W-170..W-179 and W-195 are OP-1's;
W-180..W-194 are DD-1's reservation (claude/carbon-fork-0-1-dd,
fork/designdocs/plan.md, which gives W-192..W-194 as spares and says "No fork
design id is minted: F-016 stays" unallocated); W-190 is unused forever. No
text on any ref names W-196 or above, or F-016, except DD-1's sentence that it
does not mint F-016. **OP-2 reserves W-196..W-199**: W-196 and W-197 are the two
residues of §1.7, and W-198 and W-199 are spares for residues a review finds; an
unused reserved id stays unused and is never reused. OP-2 implements F-015 and
**mints no fork design id** (D-OP2-11). Immediately before the discharge commit
writes the ledger, the maximum is re-scanned; if any of W-196..W-199 is taken
by then, the residues re-allocate from the maximum plus one, skipping every
reserved block, and the landed notes say so.

**Design authority** (each cited where used):

-   docs/design/optional.md (F-015, OP-1): "An `Optional(T)` owns the value it
    holds: `Some(v)` stores a copy of `v`, copying an `Optional(T)` copies its
    value, and destroying a non-empty `Optional(T)` destroys its value"
    (:358-360), "The fix must keep `Core.Optional(T*)` trivially destructible,
    because a union may have a `Core.Optional(T*)` field" (:363-364), and the
    0.1 limits W-170, W-171 and W-173 with their close conditions (:466-482).
-   docs/design/classes.md: "Adapters" (:1776-1813): an adapter adds no fields
    ("not fields, base classes, or virtual functions", :1791-1796) and "The
    adapted type is compatible with the original type" (:1797-1799);
    "Destructors" (:1992-2003): a type is `TrivialDestructor` only if "the class
    declaration does not define a destructor or the class defines the destructor
    with an empty body `{ }`" and all its data members are.
-   proposals/p001154-destructors.md:211-227: the considered, not adopted,
    alternative "Allow direct implementation of `TrivialDestructor`", whose
    `Optional` sketch destroys its value only when it holds one (`destructor
    [me: Self] { if (me.holds_value) value.Destroy(); }`) and opts into
    `TrivialDestructor` when its argument does.
-   docs/design/unions.md:216-245 ("Field rules in 0.1"): a type is trivially
    destructible "if it carries no destruction obligation: no destructor
    anywhere in the type or its subobjects"; the 0.1 note admits
    `Core.Optional(T*)` fields (:233-238).
-   proposals/p006357-c-interop-mapping-pointer-types.md:247-249:
    `Core.Optional(T*)` has "the same ABI as a C++ pointer, including that the
    "none" state is represented with a C++ null pointer representation".
-   fork/decision-log.md, "SL-1: Core.Slice, Core.Buf, heap allocation,
    fail-stop": D-SL-4, "a bounds violation fails-stop — one stderr line naming
    the operation, then `abort()`, SIGABRT — unconditionally"; and, on the safe
    branch (PR 53), D-SAFE-14 (fail-stop everywhere, no build flag disables a
    check; break condition "a per-site `unsafe fn` accessor, never a flag", per
    W-146's notes) and TY4 (docs/design/safety/type_safety.md:179-195 there):
    "the only way to reach the pointee of an `Optional(T*)` is through `Get`
    after `HasValue`, a `match`, or the `?` form of the error handling design",
    and "that marker is the only place a null can be dereferenced".
-   Upstream PR 6334 ("Use the value representation of `T` as that of
    `MaybeUnformed(T)` where possible", 8f19f7a7c, 2025-11-07), which made
    `MaybeUnformed(T)`'s value representation depend on `T` and introduced the
    convert.cpp block that W-171 hits (M-3).

V-3: no accepted proposal or leads' direction is contradicted. Both toolchain
fixes repair upstream code that upstream's own head still carries (M-3, M-5);
neither changes a rule any design page states. The adapter destruction rule
follows from classes.md's adapter rules (an adapter's object is an object of the
adapted type and declares no fields of its own); it is recorded as an
auto-adopted decision (D-OP2-3), not a new fork design. The one consequence that
departs from C++, `Core.Optional(i32)` not being trivially destructible where
C++'s `std::optional<int>` is, is what classes.md's adopted `TrivialDestructor`
rule says (p001154's conditional alternative was not adopted), and is filed as
W-196 rather than claimed as design.

## §0 Audit: what exists, what was measured, what is stale

### §0.1 Sub-feature table (verified in-tree at 379f20f67)

| # | Element | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Default storage | LANDED, leaks | core/prelude/types/optional.carbon:140-143 `private class DefaultOptionalStorage(T: Copy & Destroy) { var value: MaybeUnformed(T); var has_value: bool; }`; its `OptionalStorage` impl :148-179; `Get` :169-171 is `return value.value unsafe as T;` and `Copy` :172-178 reads `(value.value unsafe as T).(Some)()`. No `Destroy` impl in the file. |
| 2 | Pointer niche | LANDED | `final impl forall [T: type] T* as OptionalStorage where .Type = MaybeUnformed(T*)` :188-204; `Get` :200-202 `return value unsafe as T*;`. `Core.Optional(T*)` adapts `MaybeUnformed(T*)`, not the default storage. |
| 3 | `Optional(T)` | LANDED | `class Optional(T: OptionalStorage)` :30-46, `adapt T.Type;` :45; `Get(self) -> T` :40-42 returns `T.Get(self as T.Type)` with no test. |
| 4 | `OptionalStorage` | LANDED, private | :17-26; `let Type: type;` :18, so generic code cannot prove `T.Type` destructible. |
| 5 | `MaybeUnformed(T)` | LANDED | core/prelude/types/maybe_unformed.carbon:13-15 `class MaybeUnformed(T: Destroy) { adapt MakeMaybeUnformed(T); }`; the builtin type's destruction is a no-op by design ("TODO: implement destruction for `Core.MaybeUnformed(T)`", toolchain/check/custom_witness.cpp:1056-1060). |
| 6 | `MaybeUnformed(T)`'s value representation | LANDED, per `T` | toolchain/check/type_completion.cpp:809-832: the same as `T`'s when that copies every byte of the object, otherwise a pointer, and always a pointer for `bool` (:822-826, "TODO: Should ValueRepr::IsCopyOfObjectRepr return false for `bool`?"); an adapter's representation is its adapted type's (:768-776). So `MaybeUnformed(bool)` is a pointer and `bool` a copy; `MaybeUnformed(Core.Optional(U*))` is a pointer and `Core.Optional(U*)` a copy (`U*`). |
| 7 | Removing `MaybeUnformed` from a value | LANDED, defective | toolchain/check/convert.cpp:1687-1704: when the value and target kinds differ, `CARBON_CHECK(unformed_value_rep.kind == SemIR::ValueRepr::Pointer)` (:1698), where `value_rep` is computed for the operand `MaybeUnformed(T)` (:1693-1694) and `unformed_value_rep` for the target `T` (:1695-1696), then `value_as_ref`, `as_compatible`, `acquire_value`. |
| 8 | `as_compatible` lowering | LANDED, a no-op | toolchain/lower/handle.cpp:98-101 `context.SetLocal(inst_id, context.GetValue(inst.source_id));` whatever the two types' value representations; sem_ir/typed_insts.h:195-203 "Perform a no-op conversion to a compatible type". `value_as_ref` lowering CHECKs a pointer representation (lower/handle_expr_category.cpp:75-83); `acquire_value` loads for a copy representation (:28-45). |
| 9 | Destroy of a class | LANDED | `CanDestroyClass` (custom_witness.cpp:234-335) yields to a class-keyed declared `Destroy` (:269-272, SL-1), otherwise checks the adapted type or object representation has a witness and returns `Trivial` when the class has no struct fields (:323-326); `Class::GetStructTypeFields` returns no fields for an adapter (sem_ir/class.cpp:55-63, "Return an empty array since adapters can't declare fields"), so every adapter is `Trivial`, and `MakeSubobjectDestroyOpBody`'s class arm (:1018-1041) walks only struct fields. |
| 10 | Union field rule | LANDED | class.cpp:637 `!IsTriviallyDestructible(...) \|\| HasNonTrivialUserCopyImpl(...)` → `UnionFieldNotTriviallyCopyable` (:639); `IsTriviallyDestructible` (custom_witness.cpp:839-962) rejects a class with any class-keyed user `Destroy` impl (`HasUserDestroyImpl`, :554-665) and walks into an adapter's adapted type (:886-893). |
| 11 | `Get()` on an empty value | UNCHECKED | :40-42; M-10. The fail-stop builtin exists: `"fail_stop"`, `auto(CoreStringType)->NoReturn` (sem_ir/builtin_function_kind.cpp:841-844), lowered as `write(2, ...)` then `abort()` (lower/handle_call.cpp:682-716), used by core/prelude/types/slice.carbon:20 and :39-44 (D-SL-4). |
| 12 | Arbiters | 3 SKIP | fork/conformance/programs/stdlib/optional_destroys_value.carbon (EXPECT 2 0 1 0 3 0), optional_bool.carbon (1 1 0 1 0 1 0), optional_nested_pointer.carbon (1 0 0 1 1), each "Un-SKIP when W-17x lands; the body then needs no change." |
| 13 | Docs | LANDED (OP-1) | docs/design/optional.md: the ownership rule and its W-170 limit (:356-392), W-171's sentences (:295-299), the generic-local limit (:284-290), the 0.1 limits (:462-522). |

### §0.2 Measurements

Setup, all under the planner's scratch directory (`$S` below is
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/op2`):
`install-copy` is a `cp -a` of OP-1's install tree; each prototype is a further
copy whose `lib/carbon/core/prelude/types/optional.carbon` and, for a toolchain
prototype, `lib/carbon/carbon-busybox` are replaced; `bin/mkrunfiles.sh` builds
a runfiles tree whose `carbon/toolchain/install/*` entries point at that copy
(file_test finds the install root through `RUNFILES_DIR`); `bin/run.sh` compiles
one program with `--output-last-input-only` (R2), links and runs it. A toolchain
prototype is built by `bin/relink.py` (the ST-1 relink recipe of
`$S/../st1-fixer/fix/relink.py`, generalized): it compiles each patched source
with the `cxx`, `cflags` and per-object `extra` flags of
`/home/user/carbon-build/carbon-op/build.ninja` (include root switched to this
worktree, whose headers equal the build's), into `$S/tc/<variant>/obj/`, and
relinks `bin/file_test` and `bin/carbon-busybox` from that build's objects with
the patched objects substituted, writing only to `$S/tc/<variant>/bin/`. The
variants used below: **a** = §2.2's lower/handle.cpp and convert.cpp; **d** =
**a** plus §2.2's custom_witness.cpp (the whole §2.2 patch); **c** = an earlier
**d** that tested `IsTriviallyDestructible` directly, with no error-type guard,
and called the adapted type's `SelfDestruct` unconditionally. Prelude
prototypes: **op1** (the file at 379f20f67), **p1** (op1 plus §2.1's storage
`Destroy` impl only), **p2** (OP-1's M-6 prototype re-applied to op1: `let Type:
Destroy;` and `Destroy` impls on both the default storage and `Optional(T)`),
**p2b** (p2 without the storage impl), **p3** (p1 plus `let Type: Destroy;`),
**chk** (op1 plus §2.1's checked `Get` only), **t2** (§2.1 without its two
appended comment blocks) and **t3** (§2.1 byte for byte, 301 lines; §2.1's patch
applies to this worktree with `git apply --check`). Each install copy used a
fresh `XDG_CACHE_HOME` (the runtimes cache is keyed by the install digest, which
a copy leaves unchanged). file_test ran in test mode over the whole manifest
from this worktree (`$S/bin/ft.sh`, read-only), 1945 tests. The EXPECT values of
§1.5 and §2.4 were derived from F-015 before any program ran (R16(d)); every
other number below is a measurement.

```
S=/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/op2
python3 $S/bin/relink.py $S/tc/d \
  obj/toolchain/lower/handle.cpp.o=$S/src/a/handle.cpp \
  obj/toolchain/check/convert.cpp.o=$S/src/a/convert.cpp \
  obj/toolchain/check/custom_witness.cpp.o=$S/src/d/custom_witness.cpp
cp -a $S/install-copy $S/install-d-t3
cp $S/tc/d/bin/carbon-busybox $S/install-d-t3/lib/carbon/carbon-busybox
cp $S/proto/optional.t3.carbon $S/install-d-t3/lib/carbon/core/prelude/types/optional.carbon
$S/bin/mkrunfiles.sh $S/install-d-t3 $S/runfiles-d-t3
$S/bin/ft.sh $S/runfiles-d-t3 $S/tc/d/bin/file_test $S/ft-d-t3.log
$S/bin/run.sh $S/install-d-t3 $S/cache-d-t3 <program.carbon>
cd /home/user/carbon-op2 && XDG_CACHE_HOME=$S/cache-d-t3 python3 fork/conformance/runner.py \
  --toolchain $S/install-d-t3/lib/carbon/carbon-busybox --programs <dir> --out <out>
```

-   **M-1 (the three arbiters, reproduced).** On the OP-1 copy:
    optional_destroys_value exits 0 printing `2 1 1 0 3 2` (EXPECT `2 0 1 0 3
    0`); optional_bool aborts compile, exit 134, at "Lowering function
    Copy(bool as Core.Copy & Core.Destroy)" (optional.carbon:172) with "CHECK
    failure at /home/user/carbon-op/toolchain/lower/handle_call.cpp:984:
    args_ok: Argument mismatch: call ptr
    @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.8ae0339be4ca7eba"(ptr
    %return, ptr %value1)"; optional_nested_pointer exits 0 printing `1 1 1 0
    0` (EXPECT `1 0 0 1 1`). Each equals the SKIP line OP-1 wrote. On the
    trunk install the runner reports OUTPUT-MISMATCH, COMPILE-FAIL (the check
    error on `==`, which trunk lacks) and COMPILE-FAIL.
-   **M-2 (W-171 outside Optional, three toolchains).** Four check-or-compile
    probes in `$S/probes/w171`, each run on the trunk install, the OP-1 copy
    and the upstream nightly 2026.10.12: `fn F(m: Core.MaybeUnformed(bool)) ->
    bool { return m unsafe as bool; }` aborts check on all three, "CHECK failure
    at .../toolchain/check/convert.cpp:1698: unformed_value_rep.kind ==
    SemIR::ValueRepr::Pointer" (the nightly at its :1562); the `i32` twin
    compiles on all three; `fn G[T: Core.Copy & Core.Destroy](m:
    Core.MaybeUnformed(T)) -> T { return m unsafe as T; }` called with a
    `Core.MaybeUnformed(bool)` checks clean and aborts lowering on all three,
    "Function return type does not match operand type of return inst!" with
    "CHECK failure at .../toolchain/lower/lower.cpp:48:
    !llvm::verifyModule(...)"; and `m unsafe as Core.Optional(i32*)` for `m:
    Core.MaybeUnformed(Core.Optional(i32*))` compiles everywhere. Run, that
    last conversion is silently wrong outside any generic: mu_opt_run.carbon
    stores `Some(&n)` with `n = 7` into the `MaybeUnformed`, converts it back
    and prints `*o.Get()`: `-366584636` on the OP-1 copy, where 7 is right;
    through `G`, mu_gen_run.carbon prints `-1783208916 5` (the `i32`
    specific is right). So the defect has three escapes, not one (§1.1).
-   **M-3 (upstream has not fixed it).** `git ls-remote` of
    https://github.com/carbon-language/carbon-lang refs/heads/trunk is
    d4f1ec203, "Introduce a CheckedSaveAndRestore like llvm::SaveAndRestore",
    2026-10-13 22:47 UTC (a `--depth=1 --filter=blob:none` fetch into a scratch
    bare repository for the date). Its toolchain/check/convert.cpp:1556-1567
    is this branch's :1690-1701 byte for byte (the CHECK at its :1562, the line
    the nightly names); its toolchain/lower/handle.cpp:75-78 lowers
    `AsCompatible` as a no-op; its type_completion.cpp MaybeUnformed
    representation equals this branch's. The code arrived with upstream PR
    6334 (8f19f7a7c, 2025-11-07): before it, `MaybeUnformed(T)` always had a
    pointer representation and the conversion always emitted `value_as_ref`
    then `acquire_value` (`git show 8f19f7a7c -- toolchain/check/convert.cpp`,
    the removed lines), which was correct in generics too; PR 6334 made the
    representation depend on `T` and the round trip conditional, and named the
    two variables the other way round from what they hold.
-   **M-4 (the W-171 fix, prototype a).** With variant **a** (§2.2's
    handle.cpp and convert.cpp hunks only, OP-1's prelude): optional_bool
    prints `1 1 0 1 0 1 0`, optional_nested_pointer `1 0 0 1 1`, mu_opt_run
    `7`, mu_gen_run `7 5`, and both aborting probes of M-2 compile; file_test
    `[==========] 1945 tests from 1 test suite ran.` and `[  PASSED  ] 1945
    tests.`: the fix moves no golden. Variant **b** (the same lowering change,
    with convert.cpp's whole check-side round trip, :1687-1704's `if`, deleted
    instead of corrected) also passes 1945 of 1945: no golden exercises the
    concrete round trip (§7 A-2).
-   **M-5 (W-170's root cause: the adapter, not only the storage).** With
    prelude **p1** (a `Destroy` impl on `DefaultOptionalStorage(T)` only) on the
    OP-1 toolchain, optional_destroys_value still prints `2 1 1 0 3 2`:
    `Core.Optional(T)` is an adapter of its storage, and the toolchain destroys
    an adapter as `Trivial` without touching the adapted object (§0.1 row 9).
    The same holds for any adapter: adapter_destroy.carbon (`class AdaptP {
    adapt P; }` over a `P` whose `Destroy` prints `200 + v`, locals `p = {.v =
    1}` and `a = MakeP(2) as AdaptP`, then `Core.Print(0)`) prints `0 201` on
    the OP-1 copy, where `0 202 201` is right, and `0` on the upstream nightly
    (which does not select a class's own declared `Destroy` at all; the fork
    does since SL-1, D-SL-16). Upstream trunk d4f1ec203's custom_witness.cpp
    has the same `GetStructTypeFields(...).empty()` test (:276-279) and its
    sem_ir/class.cpp the same empty array for adapters (:58-62). p1 changes 7
    goldens (check: interop/cpp/range_for, slice/basic; lower: array/iterate,
    for/bindings, for/break_continue, for/for, primitives/optional), all
    SemIR or IR only: the storage's synthesized field walk is replaced by the
    declared impl.
-   **M-6 (OP-1's M-6 re-measured; which impl breaks unions, and why).**
    Prelude **p2** (OP-1's prototype: `let Type: Destroy;` and `Destroy` impls
    on both `DefaultOptionalStorage(T)` and `Optional(T)`) on the OP-1
    toolchain fixes the program (`2 0 1 0 3 0`) and fails 28 of 1945 goldens:
    OP-1's 26 plus its own two compare goldens, which did not exist when M-6
    was first measured; both union/basic goldens gain "union field `o` has type
    `Core.Optional(i32* as Core.OptionalStorage)`, which is not trivially
    copyable and destructible [UnionFieldNotTriviallyCopyable]". Prelude
    **p2b** (the impl on `Optional(T)` alone) does not fix the program (`2 1 1
    0 3 2`: the storage it delegates to has no destroy of its own) and still
    breaks unions (29 goldens). p1 (the storage impl alone) breaks no union:
    `Core.Optional(i32*)` uses the pointer-niche storage (`final impl forall
    [T: type] T* as OptionalStorage`, :188-204), never the default one. So the
    union regression comes from the impl keyed on `Optional` itself:
    `HasUserDestroyImpl` (custom_witness.cpp:554-665) treats a class-keyed impl
    as covering every specific of the class, `Optional(i32*)` included,
    regardless of the impl's constraints.
-   **M-7 (the adopted destroy, prototype d with t3).** With variant **d**
    and prelude **t3**: optional_destroys_value prints `2 0 1 0 3 0`,
    optional_bool `1 1 0 1 0 1 0`, optional_nested_pointer `1 0 0 1 1`;
    adapter_destroy `0 202 201`. A union probe accepts `union U1 { var p:
    Core.Optional(i32*); var q: Core.Optional(C*); var n: i32; }` and rejects
    `union U2 { var o: Core.Optional(i32); var n: i32; }` with
    `UnionFieldNotTriviallyCopyable` at 8:7, which the OP-1 copy accepts
    (D-OP2-6). Blast radius, file_test over the whole manifest: the toolchain
    alone (variant **d**, prelude op1) fails 1 golden,
    check/testdata/interop/cpp/range_for.carbon (its `Optional` of a C++
    iterator value now calls the storage's synthesized destroy); prelude **t2**
    alone on the OP-1 toolchain fails 28; together (**d** + **t3**) fail the
    same 28, the list of §6.1, with no new diagnostic in any diff (`grep` of the
    log for added `error:` or `warning:` lines is empty). Variant **c**
    additionally failed check/testdata/function/generic/resolve_used.carbon,
    whose adapter `Core.Int(0)` has an error-typed adapted type and gained a
    body `as_compatible` of `<error>`; **d**'s guard
    (`adapted_type_id != SemIR::ErrorInst::TypeId`) removes it, as measured.
-   **M-8 (`let Type: Destroy;` is what lets generic code destroy an
    Optional).** gentemp.carbon (`fn Hold[T: Core.Copy & Core.Destroy](a: T) ->
    bool` with `let o: Core.Optional(T) = Core.Optional(T).Some(a);` and a
    temporary `Core.Optional(T).Some(a).HasValue()`, called with a counting
    `Tracked` whose count starts at 1) fails on the OP-1 copy and on **d** +
    **p1** with "cannot access member of interface `Core.Destroy` in type
    `Core.Optional(T as Core.OptionalStorage)` that does not implement that
    interface" (12:29 and 13:10), and with **d** + **p3** compiles and prints
    `1` (both copies destroyed; the same with **d** + **t3**). The bound's cost:
    **d** + **t3** without it (`t2nt`) fails 15 goldens, with it 28; the 13
    extra are SemIR-only (`import_ref`s typed `%Destroy.type` instead of `type`,
    the storage witness tables).
-   **M-9 (ownership on every path, prototype d + t3; the same with t2).**
    assign.carbon, four helpers each with its own counter, each printing the
    count inside and the caller after: `4 1 3 0 2 0 1 0`. Reading: `o = p` with
    both non-empty holds four objects and leaves one after the scope (the
    overwritten value, ST-1's W-160: assignment does not destroy it; no double
    destroy, the count never goes below the leak); an Optional of an Optional
    built from a temporary holds three and none after; a class field holding an
    Optional two, then none; a checked generic's local Optional is gone when the
    generic returns (1, then 0). nesttrace.carbon (OP-1's R1-2 trace, `o1 == o2`
    on two `Core.Optional(Core.Optional(P))`, `Copy` printing `100 + v`,
    `Destroy` `200 + v`): the output is `101 101 102 102 -1 101 102 101 102 202
    201 202 201 0 -2 202 202 201 201 202 201`, where the OP-1 copy prints `...
    101 102 101 102 202 201 0 -2 202 201`: the comparison now balances (four
    copies, four destroys), and at the end all six `P` objects are destroyed. A
    class that declares its own `Destroy` does not destroy its fields
    (declared_fields.carbon: `class Outer { var p: P; impl as Core.Destroy {...}
    }` prints its `Op`'s `100` and never `201`), on the OP-1 copy and with OP-2
    alike; a class without one does (`Plain { var p: P; }` prints `202`). Filed
    as W-197 (§1.7).
-   **M-10 (W-173: today, the fail-stop, and its cost).** empty_i32.carbon
    (`Core.Print(Core.Optional(i32).None()...Get())` through a `let`) prints
    `-1456905704`, exit 0, on the OP-1 copy (`-1665659480` on trunk);
    empty_ptr.carbon (`*o.Get()` on an empty `Core.Optional(i32*)`) exits 200
    on both (undefined behavior: the dereference of the null pointer; OP-1's
    M-9 saw SIGSEGV, 139, from the same source). With **d** + **t3** (and
    **t2**) both print
    `carbon: Core.Optional.Get on an empty value; terminating` on stderr and
    abort, exit 134 from the shell; some_ok.carbon (both payloads non-empty)
    prints `7 5`. Cost, `fn Sum(n: i32) -> i32` summing a `for (i: i32 in
    Core.Range(n))` loop, `carbon compile --optimize=speed --dump-llvm-ir`,
    instructions in `_CSum.Main`: OP-1 36 (3 blocks); **chk** (the check only)
    36, and no `@abort` or `@write` call is left in the module, because the
    loop's own `HasValue()` test makes the check's branch dead; **d** + **p3**
    (the destroy only) 44 (6 blocks); **d** + **t2** 44. The check costs
    nothing in that loop; the `+8` instructions are the destroy's
    `has_value` store, load and branch for the `Core.Optional(i32)` that
    `Next` returns, W-196's cost. The check alone (**chk** on the OP-1
    toolchain) fails 15 goldens, all among the 28 (§6.1).
-   **M-11 (refill of the 28, to a fixpoint).** A scratch mirror
    (`$S/mirror-fill3`: toolchain/testing/testdata and the 28 goldens at their
    paths) autoupdated by variant **d**'s file_test with **t3**: the first pass
    fills, the second and third change nothing (`diff -r` of the trees after
    passes 2 and 3 is empty, and after passes 1 and 2 too), and test mode then
    passes 28 of 28. Against this worktree the refill is `+4184 -6785` lines
    over the 28 files (`git diff --no-index --numstat`, per file in §6.1); the
    same totals were measured with **t2**.
-   **M-12 (the five new goldens).** §2.3's sources, autoupdated by the same
    file_test with **t3** in a second mirror at substitute manifest paths
    (check/testdata/class/adapter/adapt.carbon,
    check/testdata/as/maybe_unformed.carbon,
    check/testdata/optional/fail_compare.carbon,
    lower/testdata/builtins/maybe_unformed.carbon,
    lower/testdata/optional/compare.carbon): each converges by its second run,
    and test mode then passes 5 of 5; sizes: check class/adapter/destroy 320
    lines (259 CHECK), check as/maybe_unformed_value_repr 458 (412), check
    optional/destroy 622 (543), lower builtins/maybe_unformed_value_repr 352
    (299), lower optional/destroy 530 (482). The first drafts drew an
    `UnusedBinding` warning (`fn Op(ref self) {}`) and a `CopyOfUncopyableType`
    error (`(1 as i32) as AdaptI32` copies a value of an adapter without
    `Copy`); §2.3's texts are the corrected ones. §4 quotes the key lines.
-   **M-13 (conformance).** The whole suite on **d** + **t2** with this
    branch's programs unchanged: `PASS 132`, `SKIP 25`, every other status 0,
    over 157, bullets 48 PASS / 8 SKIP, program by program the scoreboard OP-1's
    discharge quotes. With §2.4's programs in a scratch copy of programs/
    (`$S/conf/programs-final`): `PASS 138`, `SKIP 22`, every other status 0,
    over 160, bullets 48 PASS / 0 FAIL / 8 SKIP (scoreboard generated
    2026-10-14T01:20:33Z), and against the first run exactly six status
    differences, all Optional: optional_destroys_value, optional_bool and
    optional_nested_pointer SKIP → PASS, optional_destroy_diff,
    optional_get_empty_fail_stop and optional_pointer_get_empty_fail_stop new
    PASS (the C++17 oracle's stdout equals the Carbon binary's). On **d** +
    **t3** (two comment blocks after :275 beyond t2), the 14 programs whose
    path contains `optional` (`--filter optional`; the Optional bullet's 13 and
    error_handling/optional_try): 13 PASS and optional_pointer_compare SKIP
    (scoreboard generated 2026-10-14T01:41:19Z). In a scratch tree
    (runner.py, README.md, gap-analysis.md and that programs/ copy),
    `runner.py --update-readme-table` writes 160 rows, the seven of §2.4 new or
    changed,
    and `--self-test` prints `self-test: 160 programs parsed, 56 bullets in
    table, OK`.
-   **M-14 (non-vacuity and mutants).** On the OP-1 copy the six programs are
    OUTPUT-MISMATCH (optional_destroys_value, optional_nested_pointer),
    COMPILE-FAIL (optional_bool: the abort, exit -6 from the runner;
    optional_destroy_diff: the generic local of M-8) and RUN-FAIL
    (optional_get_empty_fail_stop: exit 0; optional_pointer_get_empty_fail_stop:
    exit 217); on trunk the same except optional_bool and
    optional_nested_pointer are COMPILE-FAIL (no `==`). Without its checked
    generic helper, optional_destroy_diff prints `2 1 3 2 1 1 1 3 2` on the
    OP-1 copy and `2 0 3 0 1 0 1 3 0` with **d** + **t2**: every
    after-the-scope count differs. Three prelude mutants of the storage
    `Destroy` (each in its own install copy with variant **d**): m1, no
    `has_value` test (destroys the unformed value of an empty Optional):
    optional_destroys_value RUN-FAIL, exit -11, while optional_destroy_diff
    PASSes (it destroys no empty Optional); m2, an empty `Op`: both programs
    OUTPUT-MISMATCH; m4, the value destroyed twice: both OUTPUT-MISMATCH. The
    toolchain halves have their own falsifiers: without §2.2's
    custom_witness.cpp hunks the storage impl does nothing (M-5), and without
    its handle.cpp hunk optional_bool aborts (M-1, M-2).
-   **M-15 (composition with ST-1, PR 55).** ST-1's build directory
    (`/home/user/carbon-build/carbon-st`, 0.0.0-0.dev+84ff63560, whose toolchain
    sources differ from this branch's only in check/cpp/export.cpp) relinked by
    the same recipe with §2.2's three sources (`$S/tc/st-d`), a copy of its
    install carrying **t3** (ST-1's string.carbon with this optional.carbon),
    and file_test over a `git archive` of claude/carbon-fork-0-1-st at
    21307851a: `[==========] 1950 tests from 1 test suite ran.` and `[  PASSED
    ] 1924 tests.`; the 26 that fail are §6.1's 28 minus OP-1's two compare
    goldens, which that branch does not have. So the new
    `import library "prelude/types/string"` (§2.1) compiles against ST-1's
    string.carbon, ST-1's own `private fn FailStop` does not clash with this
    one (each is private to its library, as slice.carbon's already is beside
    it), and ST-1 adds no golden to the refill.
-   **M-16 (composition with SC-1, textual only).** §2.2's patch applies with
    `git apply --check` to the three files as they are on
    claude/carbon-fork-0-1-sc at 857d5b048 (SC-1's fill round 6), with an
    offset of 14 lines in convert.cpp (whose CHECK is at :1712 there) and of 2
    in custom_witness.cpp (whose only SC-1 change adds
    `StructuralRequirementType` to `IsBuiltinWithTrivialDestruction`,
    :199-200); SC-1 does not change lower/handle.cpp. SC-1's build was not used
    (§0.2, not measured).

Not measured, and why: an OP-2 toolchain built from this worktree by
carbonbuild (the planner builds nothing; the relinked variant **d** compiles
exactly §2.2's three sources with the build's flags and links them with the
build's other objects, so it is that toolchain up to the version stamp, and §8
builds it); SC-1's toolchain composed with §2.2 (SC-1's build directory is its
own and was rebuilt during this planning, stamped a9c887101.dirty at 00:52 UTC
while its head moved to 857d5b048; §8.8 re-runs everything on the merge
commit); the whole suite on **d** + **t3** (a run on a fresh cache was stopped
for time after 34 programs; M-13 ran the whole suite on **t2** and the Optional
programs on **t3**); Bazel-only tests, clangd-tidy, macOS, Windows and an
opt-mode toolchain (§8); LLVM-side assertions (the CMake LLVM is a Release
build without them, carbonbuild README).

### §0.3 Ledger, row and brief claims found stale (each corrected where §2 says)

1.  W-171's notes say "SC-1 moves the CHECK to convert.cpp:1712"; at SC-1's
    head 857d5b048 it is still :1712, and the variables it misnames are at
    :1707-1710 there (M-16). The discharge re-reads both at the merge of trunk.
2.  W-170's notes and OP-1's D-OP-12 say a declared `Destroy` "makes every
    Optional, the pointer niche included, user-destructible"; that is true of
    an impl keyed on `Optional`, not of one on the default storage, which never
    reaches `Optional(T*)` (M-6). The brief's question ("because the impl is on
    the storage interface or on Optional itself?") is answered: on `Optional`
    itself.
3.  The brief and W-170 put the fix in the prelude ("subsystem core/prelude (+
    the union field rule)"); the measured root cause is also in the toolchain
    (custom_witness.cpp: adapters are never destroyed, M-5). W-170's subsystem
    is corrected at discharge to "core/prelude + toolchain/check
    (custom_witness.cpp)".
4.  W-171's title says the default storage "silently return[s] the storage
    address for `Core.Optional(U*)`"; the defect is not the storage's: any
    `as_compatible` of a value whose two types' representations differ is
    wrong, concretely after adapter stripping (M-2's mu_opt_run) and in every
    generic (M-2's `G`). The discharge note says so.
5.  W-108's headline ("a `Core.Buf` (or any class with a declared `Destroy`
    impl) held in a field is not destroyed") is stale for a class without its
    own `Destroy`: `Plain { var p: P; }` destroys `p` (M-9). What remains is a
    class WITH its own `Destroy`, whose fields are not destroyed (M-9's
    `Outer`), filed as W-197; W-108 gets an OP-2 note, not a status change (it
    is SL-1's item).
6.  docs/design/optional.md:388-392 and ORCHESTRATION.md's Next actions item 6
    (the TY4 amendment OP-1 owes SAFE-1) describe `Get()` as unchecked; both
    are rewritten by §2.5 and §2.6.
7.  optional_compare_payload.carbon:26-29 says the held values "are never
    destroyed in 0.1"; refreshed (§2.4), its EXPECT unchanged.

### §0.4 Decisions this plan auto-adopts (R29(a): the design recommendation under V-2/V-3, veto-able after the fact)

Each decision cites what it follows or the silence it fills and carries a
one-sentence break condition. The decision-log entry "OP-2" is written at
discharge (§2.6) with these decisions by number; it implements F-015 and mints
no fork design id.

-   **D-OP2-1: W-171 is fixed where it is caused, in lowering: an
    `as_compatible` of a value converts between its operand's and its result's
    value representations.** A pointer representation to a copy one loads the
    object as the result type (`LoadObject`); a copy to a pointer stores the
    value into a new `alloca` of the result type and yields its address
    (`CreateAlloca`, `StoreObject`); equal kinds stay a no-op. The invariant,
    in one sentence: compatible types share an object representation but not
    necessarily a value representation (type_completion.cpp:809-832), and in a
    generic only the specific being lowered knows which (R17). It is the root
    cause because all three escapes of M-2 (the concrete CHECK, the generic,
    the adapter-stripped explicit `unsafe as`) end in the same no-op
    (handle.cpp:98-101) applied to two different representations, and only
    lowering sees the specific; the check side cannot, since both
    representations are `Dependent` there. `GetValueRepr` already adds the
    kinds to the specific's fingerprint (lower/function_context.cpp:450-457),
    so specifics that differ only in representation are never coalesced
    (M-12: `Unwrap` lowers to three distinct specifics for `bool`, `i32` and
    `Core.Optional(i32*)`). Break condition: upstream fixes the defect another
    way (for example a dedicated SemIR conversion); the next upstream advance
    takes upstream's fix and drops this hunk if upstream's makes the three
    probes of M-2 and the two W-171 arbiters pass.
-   **D-OP2-2: convert.cpp's check-side round trip stays, with its CHECK testing
    the operand.** The two `ValueRepr::ForType` calls swap their type
    arguments (two lines), so `unformed_value_rep` is the `MaybeUnformed(T)`
    operand's, as the comment above them says ("`MaybeUnformed(T)` might have a
    pointer value representation when `T` does not"), and the unchanged
    `CARBON_CHECK(unformed_value_rep.kind == SemIR::ValueRepr::Pointer)` then
    states a true invariant: the two kinds differ only when the operand's is a
    pointer (type_completion.cpp:816-827 can only turn `T`'s representation into
    a pointer). The concrete `MaybeUnformed(bool) unsafe as bool` then emits
    `value_as_ref`, `as_compatible` on a reference and `acquire_value` (§4),
    which lowering's new conversion never sees (it acts on values only).
    Deleting the round trip instead (variant **b**, M-4) changes the same zero
    goldens, but deletes upstream code; the two-line correction is the
    smaller divergence (V-3). Break condition: upstream rewrites or deletes the
    block; this hunk follows it.
-   **D-OP2-3: an adapter is destroyed as its adapted type.** In
    custom_witness.cpp, `CanDestroyClass` returns `NonTrivial` for an adapter
    whose adapted type has destruction work and `Trivial` otherwise, and
    `MakeSubobjectDestroyOpBody`'s class arm, for such an adapter, converts
    `self` to the adapted type (`as_compatible` on the reference) and calls its
    `SelfDestruct`; "destruction work" is the existing union and export
    predicate, `!IsTriviallyDestructible(adapted)`, guarded against an
    error-typed adapted type (M-7's variant **c**). One sentence (R17): an
    adapter declares no fields and its object is an object of the adapted type
    (classes.md:1789-1799), so its destruction is that type's. It is the root
    cause of W-170 because the storage's own `Destroy` is unreachable without
    it (M-5); it is also a general defect (M-5's adapter_destroy), fixed for
    every adapter, upstream's included (M-5). `IsTriviallyDestructible`
    already walks an adapter into its adapted type (:886-893), so the union and
    C++ export predicates already agreed with this rule; only the destroy
    synthesis disagreed. Break condition: an accepted upstream design or
    upstream change specifies adapter destruction otherwise; this hunk follows
    it, and the Optional storage's destroy moves to wherever that design puts
    it.
-   **D-OP2-4: the default storage declares the destroy; `Optional` and the
    pointer niche do not.** `impl forall [T: Copy & Destroy]
    DefaultOptionalStorage(T) as Destroy` whose `Op` destroys
    `self.value unsafe as T` when `self.has_value` is true: p001154's sketch
    (`if (me.holds_value) value.Destroy();`), on the storage rather than on
    `Optional`, because an impl keyed on `Optional` reaches `Optional(T*)` and
    breaks union fields (M-6), while one keyed on `DefaultOptionalStorage`
    cannot reach the niche, which adapts `MaybeUnformed(T*)` (M-7: unions of
    `Core.Optional(i32*)` and `Core.Optional(C*)` still compile). The fields
    themselves need nothing more: `MaybeUnformed(T)` never destroys (§0.1 row
    5) and `bool` is trivial, and a class's declared `Destroy` does not destroy
    its fields anyway (W-197), so nothing is destroyed twice. Copy semantics
    are unchanged: `Optional(T) as Copy` (:50-54) still copies the value once
    through the storage's `Copy`, and the copy and the original each destroy
    their own (M-9). Break condition: a union or C++ interop regression appears
    in the gate or the conformance suite (none measured, M-7, M-13), or W-196's
    conditional triviality lands; the impl then moves or gains that condition.
-   **D-OP2-5: `OptionalStorage.Type` is `Destroy` (`let Type: Destroy;` in
    place of `let Type: type;`).** Without it a checked generic cannot destroy
    an `Optional(T)` it creates (M-8), which is W-170's own measured
    consequence (its notes, and optional.md:284-290); with it the storage type
    is known destroyable under the generic's bound, and both storage impls
    satisfy it (`DefaultOptionalStorage(T)` by D-OP2-4, `MaybeUnformed(T*)`
    trivially). It costs 13 SemIR-only refills (M-8). Break condition: the
    storage leaves the public API (W-176) or upstream's `Optional` design
    changes the storage interface; the bound moves with it.
-   **D-OP2-6: `Core.Optional(T)` for a non-pointer `T` is not trivially
    destructible, even when `T` is.** Its storage defines a destructor with a
    non-empty body, which classes.md:1992-2003 makes not `TrivialDestructor`;
    the conditional triviality of C++'s `std::optional` ([optional.dtor]: "If
    `is_trivially_destructible_v<T>` is true, then this destructor is
    trivial") is p001154's considered, not adopted, alternative. Measured
    consequences (M-7, M-10): a union field of type `Core.Optional(i32)`, which
    OP-1 admitted only because nothing was destroyed, is now
    `UnionFieldNotTriviallyCopyable` (unions.md admits `Core.Optional(T*)`
    fields and names no other Optional); a `for` loop over `Core.Range` costs
    eight more optimized instructions per iteration; a Carbon class with a
    `Core.Optional(i32)` field exports to C++ with a destructor rather than as
    trivially copyable (cpp/export.cpp:1743-1762 shares the predicate). Filed
    as W-196 (§1.7), not row-bounding: no operation of `Core.Optional` fails.
    Break condition: an accepted design adopts conditional `TrivialDestructor`
    (or an equivalent), or a program needs an `Optional` of a non-pointer in a
    union; W-196 then lands that rule.
-   **D-OP2-7: W-173 is a fail-stop in `Get()`, not a TY4 amendment.** `Get()`
    on an empty value writes `carbon: Core.Optional.Get on an empty value;
    terminating` to stderr and aborts, through the `"fail_stop"` builtin, as a
    `Core.Slice` bounds violation does (D-SL-4), so `Get()` never reads unformed
    storage and never returns the niche's null pointer, and TY4 holds as
    written ("the only way to reach the pointee of an `Optional(T*)` is through
    `Get` after `HasValue`"; a `Get` without `HasValue` now stops before any
    pointer exists). It is the close condition F-015 already wrote for W-173
    (optional.md:481-482) and SAFE-1's D-SAFE-14 (fail-stop, never a flag).
    Cost, measured: nothing in the optimized `for` loop, whose `HasValue()`
    test makes the check dead (M-10); a test and a branch in each unoptimized
    `Get` specific; 15 goldens on its own, all within the 28 (M-10). TY4's
    amendment path is the rejected alternative (§7 A-7): it would weaken a
    safety rule to describe a defect. Break condition: a measured program or
    benchmark where the check is not folded and costs more than the strategy's
    budget; then a per-site unchecked accessor with an `unsafe` marker is
    added beside `Get()` (D-SAFE-14's form), and `Get()` stays checked.
-   **D-OP2-8: no existing line of optional.carbon moves (D-OP-8 carried).**
    Three blank or replaced lines change in place: :15 (blank) becomes `import
    library "prelude/types/string";` (the `str` that `"fail_stop"` takes is
    `Core.String`, M-10's first probe without it failed "name `Core.String`
    implicitly referenced here, but not found"), :18 `let Type: type;` becomes
    `let Type: Destroy;` (D-OP2-5), and :40-42 become `fn Get(self) -> T;` and a
    two-line comment, the definition moving to the end of the file, out of
    line, after the `FailStop` declaration it calls (Carbon requires
    declaration before use, and :15 holds the import); everything else is
    appended after :275. Measured: the patch applies with `git apply --check`,
    and the 28 refills are the ones the changes cause, not line moves (§6.1).
    Why it matters beyond goldens: SAFE-1's pages (PR 53) cite optional.carbon
    by line (type_safety.md:184 `:186-203`; initialization_safety.md:154-155,
    :388, :396 `:194`, `:201`; temporal_safety.md:916 `:34-42`;
    mutation_safety.md:90 `:30-46`), and every one still points at what it
    names. Break condition: upstream edits optional.carbon above :275; both
    sides are kept at the merge and M-11 is re-run.
-   **D-OP2-9: conformance.** The three arbiters un-SKIP with their EXPECT
    unchanged, re-derived from F-015 in §1.5 (R16(d)), their SKIP line deleted
    and their closing sentence refreshed, bodies unchanged; three programs are
    added: optional_destroy_diff with a C++17 `std::optional` oracle (the two
    sides agree by design, F-015 "as C++ `std::optional` [...] do[es]", so a
    differential oracle is legitimate and R30's bidirectional rule does not
    apply), optional_get_empty_fail_stop and
    optional_pointer_get_empty_fail_stop (`EXPECT-EXIT: -6`, the
    slices_bounds_fail_stop precedent); optional_compare_payload's header is
    refreshed. Break condition: a program stops passing on a toolchain that
    contains OP-2; its EXPECT is re-derived from the design, never from the run
    (R16(d)), and the cause fixed or filed before the program changes.
-   **D-OP2-10: goldens: five new CHECK-free sources, 28 refills, no hand
    edits.** check/testdata/class/adapter/destroy.carbon,
    check/testdata/as/maybe_unformed_value_repr.carbon,
    check/testdata/optional/destroy.carbon (with one `fail_` split pinning
    D-OP2-6), lower/testdata/builtins/maybe_unformed_value_repr.carbon and
    lower/testdata/optional/destroy.carbon; the 28 existing goldens of §6.1 are
    refilled by autoupdate (R15, R16(a)). Break condition: the fill changes a
    golden outside §6.1 or reproduces none of a §4 key line; stop and explain
    it in a plan revision before the fill commit.
-   **D-OP2-11: docs: F-015's page is updated in place with a dated status
    line, classes.md gets a dated amendment; no new fork design id.**
    docs/design/optional.md is the fork's own page: its status line names
    OP-2 and its date, the paragraphs about W-170, W-171 and W-173 are
    replaced by the landed rules, and its 0.1 limits lose three items and gain
    W-196 and W-197 (§2.5). classes.md, upstream's page, gets a dated
    blockquote after its adapter rules (amendments, never rewrites). The
    adapter rule implements classes.md and the ownership rule implements
    F-015; neither is a new design decision, so F-016 is not minted (DD-1 does
    not mint it either). Break condition: a reviewer shows that D-OP2-3 or
    D-OP2-6 decides something no design page implies; it is then minted as
    F-016 in the discharge, after a re-scan for F-016.
-   **D-OP2-12: the row moves PARTIAL → DONE (expected, not of record).**
    D-OP-13's break condition is met: the three arbiters PASS (M-13) and TY4
    holds for `Get()` (D-OP2-7). No operation of `Core.Optional` fails through
    its documented API (D-ST-16's test, as D-OP-13 applied it): the remaining
    limits are 0.1 limits filed under their own bullets or beyond the bullet's
    text, as for rows 77 and 82 (W-172, W-174..W-179, W-195, W-196, W-197; §1.7
    lists each and why it does not bound the row). Per D-OP-13, the row moves in
    the commit that un-SKIPs the arbiters (commit 4), quoting the container run,
    stated as expected and not of record; the other records wait for the
    discharge (commit 5). Break condition: a review finds an operation of
    `Core.Optional` that fails through its documented API; the row stays
    PARTIAL, bounded by it, and commit 4 is corrected by a new commit.
-   **D-OP2-13: merge position, stacked after PR 56.** OP-2's branch carries
    PR 56's commits, so it merges after PR 56 (OP-1), last in the queue trunk
    records (fork/ORCHESTRATION.md: PR 53, PR 51, PR 52, SC-1, PR 54, PR 55,
    then OP-1); its PR, when the orchestrator opens one, targets
    claude/carbon-fork-0-1-op while PR 56 is open and trunk once it has merged.
    Break condition: PR 56 is withdrawn or reworked so that OP-1's prelude
    lines move; OP-2 re-runs M-11 on the new base before its commit 2.
-   **D-OP2-14: SAFE-1 reconciliation.** TY4 stands unamended. The TY4
    amendment OP-1 owes SAFE-1 (fork/ORCHESTRATION.md Next actions item 6, "In
    0.1, `Get()` on an empty `Core.Optional(T*)` is unchecked [...] TY4 does not
    yet hold on that path") is replaced, in OP-2's discharge, by the dated note
    of §2.6, which says TY4 holds on that path since OP-2; if OP-1 has already
    made its amendment when OP-2 lands, OP-2 adds the note after it rather than
    editing it. Break condition: PR 53 changes TY4's text before OP-2 lands; the
    note is re-written against the landed text.

## §1 Design

### §1.1 W-171: the value representation of `MaybeUnformed(T)` (D-OP2-1, D-OP2-2)

Since upstream PR 6334, `MaybeUnformed(T)` takes `T`'s value representation when
that representation copies every byte of the object, and a pointer otherwise
(always for `bool`, whose `i1` value drops seven bits of its byte; and for a
class adapter such as `Core.Optional(U*)`, whose copy representation `U*` is not
its object representation). Removing `MaybeUnformed` from a value therefore
sometimes needs a load. The checker emits one only on one path, and wrongly
guarded:

| Conversion | Before OP-2 | With OP-2 |
| --- | --- | --- |
| concrete `MaybeUnformed(bool) unsafe as bool` | CHECK abort, convert.cpp:1698 (the CHECK tests the target) | `value_as_ref`, `as_compatible` on the reference, `acquire_value` (D-OP2-2) |
| generic `MaybeUnformed(T) unsafe as T`, specific `bool` | `as_compatible` lowered as a no-op: `ret ptr` from an `i1` function, verifier abort | `as_compatible` loads (D-OP2-1) |
| generic, specific `Core.Optional(U*)`; and concrete `MaybeUnformed(Core.Optional(U*)) unsafe as Core.Optional(U*)` | no-op: the field's address used as the pointer, silently | loads the pointer |
| any of these where both representations agree (`i32`, a class) | no-op | no-op (unchanged; M-4: no golden moves) |
| `o unsafe as MaybeUnformed(Core.Optional(U*))`, the other direction | no-op (two such no-ops cancel) | stores to a temporary and uses its address |

The default storage reads its value with exactly the generic form
(optional.carbon:170, :174), which is why `Core.Optional(bool)` crashed and
`Core.Optional(Core.Optional(U*))` read garbage; neither needs a prelude change
once lowering is right (M-4).

### §1.2 W-170: ownership (D-OP2-3..D-OP2-6)

Destroying a `Core.Optional(T)` now destroys the value it holds, if any:

-   `Core.Optional(T)` adapts `T.(OptionalStorage.Type)`, and an adapter is
    destroyed as its adapted type (D-OP2-3).
-   For the default storage, `DefaultOptionalStorage(T)`'s declared `Destroy`
    destroys `value` when `has_value` is true (D-OP2-4).
-   For a pointer `T*`, the storage is `MaybeUnformed(T*)`, which has no
    destruction work, so `Core.Optional(T*)` is trivially destructible: no
    destroy is emitted, its C++ ABI is unchanged (p006357:247-249), and a union
    may hold one (unions.md:233-238; M-7).
-   Generic code may create, hold and destroy a `Core.Optional(T)` under the
    bound `T: Core.Copy & Core.Destroy`, because `OptionalStorage.Type` is
    `Destroy` (D-OP2-5, M-8).
-   Copying is unchanged: a copy holds its own copy of the value, and each is
    destroyed once (M-9).
-   Not changed, and filed elsewhere: assignment does not destroy the
    overwritten value (ST-1's W-160; M-9 shows a leak, never a double destroy);
    a class that declares its own `Destroy` does not destroy its fields, an
    Optional field included (W-197, M-9); `Core.Optional(T)` for a non-pointer
    `T` is not trivially destructible (W-196, D-OP2-6).

### §1.3 W-173: `Get()` fails-stop (D-OP2-7)

`Get()` requires `HasValue()`; on an empty value it writes one line to stderr,
`carbon: Core.Optional.Get on an empty value; terminating`, and calls `abort()`
(SIGABRT; the runner reports -6). The message follows D-SL-4's form ("carbon:
Core.Slice index out of bounds; terminating"). `HasValue()`, `?` (the `Try`
impl), `for` (which tests `HasValue()` before `Get()`) and the comparisons
(which test `HasValue()` on both operands, D-OP-4) never reach the fail-stop.
For `Core.Optional(T*)` this is TY4's rule made true: a `T*` obtained from an
Optional is never null. The C++ side is unchanged: a nullable C++ `T*` still
imports as `Core.Optional(T*)` with the null as its empty value.

### §1.4 C++ interop (boundary)

Unchanged by OP-2: the nullable-pointer mapping in both directions (the niche
has no destructor, so `Core.Optional(T*)` stays a C++ pointer, M-7); a
`std::optional<T>` mapping is W-011's (the bullet "Control flow: matching —
sum-type consumption incl. std::variant/std::optional interop") and out of
scope. An `Optional` of an imported C++ class now runs that class's C++
destructor when it holds a value (the storage's `Op` calls the class's
`Destroy`, which for a C++ class is its destructor, cpp/impl_lookup.cpp
`BuildDestroyWitness`); check/testdata/interop/cpp/range_for.carbon's refill is
that call (M-7).

### §1.5 EXPECT re-derivation (R16(d): from F-015's rules, never from a run)

-   optional_destroys_value (`2 0 1 0 3 0`): `Tracked` counts live objects
    (`Make` and `Copy` add one, `Destroy` removes one). `HoldOne`: `t` (1) and
    the copy `Some(t)` stores (F-015: "`Some(v)` stores a copy of `v`") = 2;
    after `HoldOne` returns, `o` is destroyed, destroying its value, and `t`
    is destroyed = 0. `HoldNone`: `t` only (an empty Optional holds nothing)
    = 1; then 0. `HoldCopy`: `t`, `o`'s value and `p`'s ("copying an
    `Optional(T)` copies its value") = 3; then 0. The file's EXPECT.
-   optional_bool (`1 1 0 1 0 1 0`): `Some(true)` holds a value (1) that reads
    back as `true` (1); `Some(false)` reads back as `false` (0); a copy of
    `Some(true)` reads back as `true` (1); `None()` holds none (0); two
    non-empty Optionals compare as their values (D-OP-1): `true == true` (1),
    `true == false` (0). The file's EXPECT.
-   optional_nested_pointer (`1 0 0 1 1`): `Some(None)` holds a value (1) whose
    own value is empty (0), as does its copy (0); `*Some(Some(&n)).Get().Get()`
    is `n`, 7 (1); `a == b` compares the two inner `Core.Optional(C*)` values
    by `C*`'s user `==`, which compares `v`, 4 and 4 (1). The file's EXPECT.
-   The three new programs derive theirs in their headers (§2.4), and
    optional_destroy_diff's oracle is C++17's `std::optional`, whose ownership
    rule F-015 adopts.

### §1.6 What OP-2 changes in the documented API

Nothing is added to or removed from `Core.Optional`'s public declarations:
`Get()` keeps its signature (its body moves out of line), and the storage
`Destroy` impl and `let Type: Destroy` are private to the prelude. What changes
is behavior the design already states (ownership, F-015) or that F-015 filed as
a limit with a close condition (W-171, W-173).

### §1.7 What OP-2 does not do (residue titles; ids reserved at the head, filed at §2.6)

-   W-196 (Stdlib: Optional; not row-bounding): `Core.Optional(T)` for a
    non-pointer `T` is not trivially destructible, even when `T` is (D-OP2-6):
    a `Core.Optional(i32)` union field is rejected
    (`UnionFieldNotTriviallyCopyable`, M-7), destroying one tests `has_value`
    (eight optimized instructions per iteration of a `for` over `Core.Range`,
    M-10), and a Carbon class with such a field exports to C++ with a
    destructor. C++'s `std::optional<T>` is trivially destructible exactly when
    `T` is ([optional.dtor]); p001154:211-227's conditional `TrivialDestructor`
    is the considered alternative, and classes.md:1992-2003 the adopted rule
    that excludes it. Not row-bounding: every operation of `Core.Optional` works
    through its documented API, and no design statement admits a
    `Core.Optional(i32)` union field. Break condition: an accepted design
    adopts conditional `TrivialDestructor`, and `Core.Optional(i32)` is then
    trivially destructible and a union field again.
-   W-197 (Type system: User-defined types (classes); found while measuring): a
    class that declares its own `Destroy` does not destroy its fields after its
    `Op` runs (M-9's `Outer`): the declared impl's `SubobjectDestroy` is the
    interface's final function, whose body the toolchain ignores
    (core/prelude/destroy.carbon:18-24), where classes.md's destructors destroy
    the members after the destructor body. A `Core.Optional` held in such a
    class leaks its value; `Core.Buf` held in one leaks its block. Distinct from
    SL-1's W-108, whose headline case (a class WITHOUT its own `Destroy`) is
    measured fixed (§0.3 item 5). Not row-bounding: a class's defect, not an
    operation of `Core.Optional`. Break condition: a class with a declared
    `Destroy` destroys its fields after its `Op`, and `Outer` prints `100 201`.
-   Not filed again: assignment does not destroy the overwritten value (ST-1's
    W-160, M-9); the `std::optional` mapping (W-011); no unchecked `Get()`
    opt-out (D-SAFE-14 adds one only on a measured need, D-OP2-7's break
    condition).

OP-1's other residues are unchanged and none bounds the row (D-OP-13): W-172
(literal arguments abort check), W-174 (pointer `==`, under "Stdlib: pointer
types"), W-175 (explicit `as` between Optionals), W-176 (the payload must be
`Copy & Destroy` or a pointer), W-177 (matchability, under the matching
bullet), W-178 (`like`), W-179 (subsumed non-final impls), W-195 (a
compile-time-only `==` in a generic).

## §2 Implementation spec, file by file

### §2.1 core/prelude/types/optional.carbon (275 → 301 lines; no existing line moves)

The whole change as a patch with one line of context, which `git apply` takes
exactly as extracted from this file (measured on this worktree, §0.2): :15
(blank), :18 and :40-42 are replaced in place and :276-301 are appended
(D-OP2-8). This is prototype **t3**, the text every measurement of §0.2 that
names t3 ran on. Blank context lines appear without their leading space,
because prek strips trailing whitespace from this file; `git apply` takes them
as they are (measured: both blocks of §2.1 and §2.2, extracted from this file,
apply to a `git archive` of 379f20f67 and produce byte for byte the files
§0.2 measured).

```diff
--- a/core/prelude/types/optional.carbon
+++ b/core/prelude/types/optional.carbon
@@ -14,6 +14,6 @@ import library "prelude/operators/comparison";
 import library "prelude/types/maybe_unformed";
-
+import library "prelude/types/string";
 // TODO: Decide how to expose this in the public API.
 private interface OptionalStorage {
-  let Type: type;
+  let Type: Destroy;
   fn None() -> Type;
@@ -39,5 +39,5 @@ class Optional(T: OptionalStorage) {
   }
-  fn Get(self) -> T {
-    return T.Get(self as T.Type);
-  }
+  fn Get(self) -> T;
+  // Defined at the end of this file, where an empty value fails-stop
+  // (fork, OP-2, W-173).

@@ -275 +275,27 @@ final impl forall [T: Destroy & OptionalStorage & Ordered]
 }
+
+// Fork (OP-2, F-015, docs/design/optional.md): an Optional owns the value it
+// holds. The default storage destroys its value when it holds one, and the
+// `Optional` adapter is destroyed as its storage. The pointer niche's
+// `MaybeUnformed(T*)` declares no `Destroy`, so `Optional(T*)` stays trivially
+// destructible and a union may hold one. `OptionalStorage.Type` is `Destroy`
+// so that a checked generic can destroy an `Optional(T)` it creates.
+impl forall [T: Copy & Destroy] DefaultOptionalStorage(T) as Destroy {
+  fn Op(ref self) {
+    if (self.has_value) {
+      (self.value unsafe as T).(Destroy.SelfDestruct)();
+    }
+  }
+}
+
+private fn FailStop(message: str) = "fail_stop";
+
+// `Get()` requires `HasValue()`. On an empty value it fails-stop, as a
+// `Core.Slice` bounds violation does, so it never reads unformed storage and
+// never returns the null pointer of the niche (fork, OP-2, W-173).
+fn Optional(T: OptionalStorage).Get(self) -> T {
+  if (not self.HasValue()) {
+    FailStop("carbon: Core.Optional.Get on an empty value; terminating\n");
+  }
+  return T.Get(self as T.Type);
+}
```

Reading notes for the reviewer. The storage `Destroy` is a non-final impl with
`Destroy`'s one required member, `Op` (core/prelude/destroy.carbon:16); the
interface's final `SelfDestruct` then runs `Op` and the ignored
`SubobjectDestroy` (:19-29), so the value is destroyed once, by `Op`.
`self.value unsafe as T` on `ref self` is a reference conversion, which needs
neither D-OP2-1 nor D-OP2-2 (§4's lower key line passes the field's address).
The out-of-line `Get` is a definition of the in-class declaration at :40
(Carbon's redeclaration rules; M-12's goldens show one `Get` per specific); it
calls `HasValue()`, not the storage's `Has`, so it tests exactly what the public
API tests. `FailStop` is private to this library, as slice.carbon's is to that
one; both coexist with ST-1's own in string.carbon (M-15).

### §2.2 Toolchain (three files, one hunk set; every hunk clang-format 21.1.8 clean)

The diff, `git apply --check` clean on this worktree and, with the offsets M-16
lists, on SC-1's head:

```diff
--- a/toolchain/check/convert.cpp
+++ b/toolchain/check/convert.cpp
@@ -1690,9 +1690,9 @@ static auto PerformBuiltinConversion(Context& context, SemIR::LocId loc_id,
         if ((removed_quals & SemIR::TypeQualifiers::MaybeUnformed) !=
                 SemIR::TypeQualifiers::None &&
             category == SemIR::ExprCategory::Value) {
-          auto value_rep =
-              SemIR::ValueRepr::ForType(context.sem_ir(), value_type_id);
           auto unformed_value_rep =
+              SemIR::ValueRepr::ForType(context.sem_ir(), value_type_id);
+          auto value_rep =
               SemIR::ValueRepr::ForType(context.sem_ir(), target.type_id);
           if (value_rep.kind != unformed_value_rep.kind) {
             CARBON_CHECK(unformed_value_rep.kind == SemIR::ValueRepr::Pointer);
--- a/toolchain/check/custom_witness.cpp
+++ b/toolchain/check/custom_witness.cpp
@@ -226,6 +226,16 @@ static auto HasClassKeyedImpl(Context& context, SemIR::ClassType class_type,
                               SemIR::CoreInterface core_interface,
                               bool outside_core_only) -> bool;

+// Returns whether destroying an adapter whose adapted type is
+// `adapted_type_id` does any work. An adapter declares no fields: its object
+// is an object of the adapted type (docs/design/classes.md, "Adapters"), so it
+// is destroyed as that type is, and trivially exactly when that type is.
+static auto AdapterHasDestroyWork(Context& context,
+                                  SemIR::TypeId adapted_type_id) -> bool {
+  return adapted_type_id != SemIR::ErrorInst::TypeId &&
+         !IsTriviallyDestructible(context, adapted_type_id);
+}
+
 // Returns true if `class_type` should impl `Destroy`. `query_is_symbolic` is
 // whether the QUERY constant is symbolic — the same
 // `query_self_const_id.is_symbolic()` fact `LookupDestroyWitness` branches on
@@ -320,6 +330,12 @@ static auto CanDestroyClass(Context& context, SemIR::LocId loc_id,
     return DestroyFormat::NoDestroy;
   }

+  if (class_info.adapt_id.has_value()) {
+    return AdapterHasDestroyWork(context, object_repr_id)
+               ? DestroyFormat::NonTrivial
+               : DestroyFormat::Trivial;
+  }
+
   if (class_info.GetStructTypeFields(context.sem_ir(), class_type.specific_id)
           .empty()) {
     return DestroyFormat::Trivial;
@@ -1026,6 +1042,19 @@ static auto MakeSubobjectDestroyOpBody(Context& context, SemIR::LocId loc_id,
           // destroy synthesis (D-UA-15 residue).
           return;
         }
+        if (auto adapted_type_id = class_info.GetAdaptedType(
+                context.sem_ir(), class_type.specific_id);
+            adapted_type_id.has_value()) {
+          // An adapter is destroyed as its adapted type.
+          if (AdapterHasDestroyWork(context, adapted_type_id)) {
+            auto adapted_id = AddInst<SemIR::AsCompatible>(
+                context, loc_id,
+                {.type_id = adapted_type_id,
+                 .source_id = callee_self_param_id});
+            DiscardExpr(context, BuildSelfDestructCall(context, adapted_id));
+          }
+          return;
+        }
         auto access_context =
             llvm::SaveAndRestore(context.access_context(),
                                  SemIR::NameScopeId::AllowHighestAccessLevel);
--- a/toolchain/lower/handle.cpp
+++ b/toolchain/lower/handle.cpp
@@ -97,7 +97,29 @@ auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,

 auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                 SemIR::AsCompatible inst) -> void {
-  context.SetLocal(inst_id, context.GetValue(inst.source_id));
+  auto* value = context.GetValue(inst.source_id);
+  // Compatible types share an object representation, but a value of one can
+  // still have a different value representation from a value of the other:
+  // `MaybeUnformed(T)` uses a pointer where `T` may use a copy
+  // (check/type_completion.cpp). In a generic, which applies is known only per
+  // specific, so a value is converted here.
+  if (SemIR::GetExprCategory(context.sem_ir(), inst_id) ==
+      SemIR::ExprCategory::Value) {
+    auto source_type = context.GetTypeIdOfInst(inst.source_id);
+    auto target_type = context.GetTypeIdOfInst(inst_id);
+    auto source_kind = context.GetValueRepr(source_type).repr.kind;
+    auto target_kind = context.GetValueRepr(target_type).repr.kind;
+    if (source_kind == SemIR::ValueRepr::Pointer &&
+        target_kind == SemIR::ValueRepr::Copy) {
+      value = context.LoadObject(target_type, value);
+    } else if (source_kind == SemIR::ValueRepr::Copy &&
+               target_kind == SemIR::ValueRepr::Pointer) {
+      auto* storage = context.CreateAlloca(target_type);
+      context.StoreObject(source_type, value, storage);
+      value = storage;
+    }
+  }
+  context.SetLocal(inst_id, value);
 }

 auto HandleInst(FunctionContext& context, SemIR::InstId /*inst_id*/,
```

The invariants, one sentence each (R17):

-   lower/handle.cpp, `AsCompatible`: a value of one type is reinterpreted as a
    value of a compatible type, so its representation must become the result
    type's, which only the specific being lowered knows (D-OP2-1).
-   check/convert.cpp: `unformed_value_rep` is the `MaybeUnformed(T)` operand's
    representation, the only one of the two that can be a pointer when they
    differ (D-OP2-2).
-   check/custom_witness.cpp: an adapter's object is its adapted type's object,
    so it has destruction work exactly when that type does, and that work is the
    adapted type's `SelfDestruct` (D-OP2-3).

What each hunk does not do. The lowering hunk acts on value expressions only
(`GetExprCategory(inst_id) == Value`); a reference `as_compatible` (D-OP2-2's
round trip, the storage's `self.value unsafe as T` on `ref self`, the adapter
destroy's `self` conversion) is unchanged. It handles the two kinds that
`MaybeUnformed` can produce from each other (copy and pointer); `None` and
`Custom` cannot differ between compatible types (type_completion.cpp:816-827
maps `Custom` to a pointer and leaves `None` as `None`). The custom_witness.cpp
hunks do not change a class that declares its own `Destroy` (that class never
reaches the adapter test, :269-272), a choice (returned before it, :1018-1025)
or a non-adapter class; `IsTriviallyDestructible` and the union and export
predicates are unchanged.

### §2.3 Goldens (sources only: `// AUTOUPDATE`, no CHECK lines; R15, R16(a))

Five new files, verbatim. Their headers follow the full-prelude goldens of
OP-1 (check/testdata/optional/compare.carbon); the two lower goldens pass
`--target=x86_64-linux-gnu` as lower/testdata/primitives/optional.carbon does.

**toolchain/check/testdata/class/adapter/destroy.carbon**

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/class/adapter/destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/class/adapter/destroy.carbon

// Fork (OP-2, fork/optional2/plan.md §4): an adapter declares no fields, and
// its object is an object of the adapted type (docs/design/classes.md,
// "Adapters"), so destroying an adapter destroys it as the adapted type: the
// adapter's `SubobjectDestroy` calls the adapted type's `SelfDestruct` when
// that type has destruction work, and is the no-op builtin when it has none.

// --- destructible.carbon

library "[[@TEST_NAME]]";

class P {
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

class AdaptP {
  adapt P;
}

class AdaptAdaptP {
  adapt AdaptP;
}

fn MakeP() -> P;

//@dump-sem-ir-begin
fn F() {
  var unused a: AdaptP = MakeP() as AdaptP;
  var unused b: AdaptAdaptP = MakeP() as AdaptAdaptP;
}
//@dump-sem-ir-end

// --- trivial.carbon

library "[[@TEST_NAME]]";

class AdaptI32 {
  adapt i32;
}

fn MakeAdaptI32() -> AdaptI32;

//@dump-sem-ir-begin
fn G() {
  var unused c: AdaptI32 = MakeAdaptI32();
}
//@dump-sem-ir-end
```

**toolchain/check/testdata/as/maybe_unformed_value_repr.carbon**

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/as/maybe_unformed_value_repr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/as/maybe_unformed_value_repr.carbon

// Fork (OP-2, fork/optional2/plan.md §4, W-171): removing `MaybeUnformed` from
// a value whose value representation differs from the result's goes through a
// reference (`value_as_ref`, then `acquire_value`); `MaybeUnformed(bool)` is
// passed by pointer and `bool` by copy. Where the two representations agree,
// or are unknown until a specific is lowered, the conversion is an
// `as_compatible` alone, and lowering converts the representation per specific
// (lower/testdata/builtins/maybe_unformed_value_repr.carbon).

// --- bool.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn FromBool(m: Core.MaybeUnformed(bool)) -> bool { return m unsafe as bool; }
//@dump-sem-ir-end

// --- i32.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn FromI32(m: Core.MaybeUnformed(i32)) -> i32 { return m unsafe as i32; }
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn Unwrap[T: Core.Copy & Core.Destroy](m: Core.MaybeUnformed(T)) -> T {
  return m unsafe as T;
}
//@dump-sem-ir-end
```

**toolchain/check/testdata/optional/destroy.carbon**

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/optional/destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/optional/destroy.carbon

// Fork (OP-2, fork/optional2/plan.md §4, W-170): a `Core.Optional(T)` owns the
// value it holds (fork design F-015). The default storage declares a `Destroy`
// that destroys the value when there is one, and the `Optional` adapter is
// destroyed as its storage; the pointer niche declares none, so
// `Core.Optional(T*)` stays trivially destructible and a union may hold one.

// --- concrete.carbon

library "[[@TEST_NAME]]";

class Tracked {
  impl as Core.Copy {
    fn Op(unused self) -> Self { return {}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

//@dump-sem-ir-begin
fn Hold(t: Tracked) {
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
}
//@dump-sem-ir-end

// --- pointer.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn HoldPointer(p: i32*) {
  var unused o: Core.Optional(i32*) = Core.Optional(i32*).Some(p);
}
//@dump-sem-ir-end

// --- generic.carbon

library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn HoldGeneric[T: Core.Copy & Core.Destroy](a: T) -> bool {
  let o: Core.Optional(T) = Core.Optional(T).Some(a);
  return o.HasValue();
}
//@dump-sem-ir-end

// --- union_pointer_field.carbon

library "[[@TEST_NAME]]";

union U {
  var o: Core.Optional(i32*);
  var n: i32;
}

// --- fail_union_value_field.carbon

library "[[@TEST_NAME]]";

// `Core.Optional(i32)`'s storage defines a destructor with a non-empty body, so
// under docs/design/classes.md's `TrivialDestructor` rule it is not trivially
// destructible, and it is not a union field type (docs/design/unions.md).
union V {
  var o: Core.Optional(i32);
  var n: i32;
}
```

**toolchain/lower/testdata/builtins/maybe_unformed_value_repr.carbon**

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/maybe_unformed_value_repr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/maybe_unformed_value_repr.carbon

// Fork (OP-2, fork/optional2/plan.md §4, W-171): converting a value between
// `MaybeUnformed(T)` and `T`, whose value representations can differ, loads
// the value when the operand is passed by pointer and the result by copy, and
// stores it to a temporary in the other direction, concretely and in each
// specific of a generic.

// --- concrete.carbon

library "[[@TEST_NAME]]";

fn FromBool(m: Core.MaybeUnformed(bool)) -> bool { return m unsafe as bool; }

fn FromOptionalPointer(m: Core.MaybeUnformed(Core.Optional(i32*)))
    -> Core.Optional(i32*) {
  return m unsafe as Core.Optional(i32*);
}

fn RoundTrip(o: Core.Optional(i32*)) -> Core.Optional(i32*) {
  let m: Core.MaybeUnformed(Core.Optional(i32*)) =
      o unsafe as Core.MaybeUnformed(Core.Optional(i32*));
  return m unsafe as Core.Optional(i32*);
}

// --- generic.carbon

library "[[@TEST_NAME]]";

fn Unwrap[T: Core.Copy & Core.Destroy](m: Core.MaybeUnformed(T)) -> T {
  return m unsafe as T;
}

fn CallBool(m: Core.MaybeUnformed(bool)) -> bool { return Unwrap(m); }

fn CallI32(m: Core.MaybeUnformed(i32)) -> i32 { return Unwrap(m); }

fn CallOptionalPointer(m: Core.MaybeUnformed(Core.Optional(i32*)))
    -> Core.Optional(i32*) {
  return Unwrap(m);
}
```

**toolchain/lower/testdata/optional/destroy.carbon**

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
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/optional/destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/optional/destroy.carbon

// Fork (OP-2, fork/optional2/plan.md §4): destroying a `Core.Optional(T)`
// destroys its value only when it holds one (W-170), `Core.Optional(T*)` has
// no destruction work, `Get()` fails-stop on an empty value (W-173), and
// `Core.Optional(bool)`'s `Get()` loads the `bool` from its storage (W-171).

// --- destroy.carbon

library "[[@TEST_NAME]]";

class Tracked {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn Hold(t: Tracked) {
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
}

fn HoldPointer(p: i32*) {
  var unused o: Core.Optional(i32*) = Core.Optional(i32*).Some(p);
}

// --- get.carbon

library "[[@TEST_NAME]]";

fn GetI32(o: Core.Optional(i32)) -> i32 { return o.Get(); }

fn GetBool(o: Core.Optional(bool)) -> bool { return o.Get(); }
```

The 28 existing goldens of §6.1 are not edited: commit 3's autoupdate rewrites
their CHECK lines (D-OP2-10).

### §2.4 Conformance programs (bullet "Stdlib: Optional", R7)

**Un-SKIPped, EXPECT and body unchanged (D-OP2-9).** In each of the three
arbiters the `// SKIP:` line (:6) is deleted and the header's closing sentence,
"Un-SKIP when W-17x lands; the body then needs no change.", is replaced; nothing
else changes. The new last lines of each header comment, verbatim:

```carbon
// optional_destroys_value.carbon (was :25-26 after the SKIP line's deletion):
// not carry into the next. W-170 landed at OP-2 (fork/optional2/plan.md),
// and the body is unchanged.

// optional_bool.carbon (was :21-22):
// (0); `Some(true) == Some(true)` (1); `Some(true) == Some(false)` (0). W-171
// landed at OP-2 (fork/optional2/plan.md), and the body is unchanged.

// optional_nested_pointer.carbon (was :22, now two lines):
// the objects (1). W-171 landed at OP-2 (fork/optional2/plan.md), and the
// body is unchanged.
```

(The first comment line of each group names the file and is not part of it.)
`$S/newprogs/unskip.py` makes exactly these edits and asserts each old text
occurs once (measured; the results are the files M-13 ran).

**Refreshed header, EXPECT unchanged.** optional_compare_payload.carbon:26-29,
"The held values themselves are never destroyed in 0.1 (W-170, arbitrated by
optional_destroys_value.carbon), which no line here observes: every count is
printed before `Run` returns.", becomes:

```carbon
// copy above died with its statement, so the count is 2 again. The held
// values are destroyed with their Optionals (W-170, landed at OP-2,
// arbitrated by optional_destroys_value.carbon), after the last count is
// printed, so no line here observes it.
```

**New programs, verbatim** (each EXPECT derived in its header before any run,
R16(d); M-13 measured them PASS, M-14 not vacuous):

**fork/conformance/programs/stdlib/optional_destroy_diff.carbon**

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   2
//   0
//   3
//   0
//   1
//   0
//   1
//   0
//   1
//   3
//   0
//
// The ownership rule of fork design F-015 (docs/design/optional.md) on the
// paths that optional_destroys_value.carbon does not take, with a C++17
// `std::optional` oracle (optional_destroy_diff.diff.cpp): an Optional owns the
// value it holds, as `std::optional` does, so live-object counts agree at every
// point printed. `Tracked` counts its live objects through a pointer: `Make`
// and `Copy` add one, `Destroy` removes one, and two of them are equal when
// their `id`s are. Each helper prints the count while its locals are alive, and
// the caller prints it again after the helper returns. Counts are printed only
// where no `Get()` copy or initializer temporary is alive, because those live
// longer in Carbon than in C++. Expected, from F-015's rules (`Some(v)` stores
// one copy of `v`, copying an Optional copies its value, destroying a non-empty
// Optional destroys its value): an Optional in a class field is destroyed with
// the object (2, then 0); an Optional of an Optional built from a named inner
// value holds a copy of that value's copy (3, then 0); a checked generic's
// local `Core.Optional(T)` is destroyed when the generic returns (1, then 0);
// an Optional returned by value keeps the one copy `Some` made (1, then 0); and
// `a == b` on two non-empty values compares equal (1) and leaves only the three
// objects it had (3, then 0).

import Core library "io";

class Tracked {
  var id: i32;
  var live: i32*;
  impl as Core.Copy {
    fn Op(self) -> Self {
      ++*self.live;
      return {.id = self.id, .live = self.live};
    }
  }
  impl as Core.Destroy {
    fn Op(ref self) {
      --*self.live;
    }
  }
}

impl Tracked as Core.EqWith(Tracked) {
  fn Equal(self, other: Tracked) -> bool { return self.id == other.id; }
  fn NotEqual(self, other: Tracked) -> bool { return self.id != other.id; }
}

fn Make(live: i32*) -> Tracked {
  ++*live;
  return {.id = 1, .live = live};
}

fn B(b: bool) -> i32 { return if b then 1 else 0; }

class Box {
  var o: Core.Optional(Tracked);
}

fn HoldField(live: i32*) {
  var t: Tracked = Make(live);
  var unused b: Box = {.o = Core.Optional(Tracked).Some(t)};
  Core.Print(*live);
}

fn HoldNested(live: i32*) {
  var t: Tracked = Make(live);
  var inner: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  var unused outer: Core.Optional(Core.Optional(Tracked)) =
      Core.Optional(Core.Optional(Tracked)).Some(inner);
  Core.Print(*live);
}

fn HoldGeneric[T: Core.Copy & Core.Destroy](a: T) {
  var unused o: Core.Optional(T) = Core.Optional(T).Some(a);
}

fn CallGeneric(live: i32*) {
  var t: Tracked = Make(live);
  HoldGeneric(t);
  Core.Print(*live);
}

fn MakeSome(live: i32*) -> Core.Optional(Tracked) {
  var t: Tracked = Make(live);
  return Core.Optional(Tracked).Some(t);
}

fn HoldReturned(live: i32*) {
  var unused o: Core.Optional(Tracked) = MakeSome(live);
  Core.Print(*live);
}

fn HoldCompared(live: i32*) {
  var t: Tracked = Make(live);
  var a: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  var b: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
  Core.Print(B(a == b));
  Core.Print(*live);
}

fn Run() -> i32 {
  var in_field: i32 = 0;
  HoldField(&in_field);
  Core.Print(in_field);
  var in_nested: i32 = 0;
  HoldNested(&in_nested);
  Core.Print(in_nested);
  var in_generic: i32 = 0;
  CallGeneric(&in_generic);
  Core.Print(in_generic);
  var in_returned: i32 = 0;
  HoldReturned(&in_returned);
  Core.Print(in_returned);
  var in_compared: i32 = 0;
  HoldCompared(&in_compared);
  Core.Print(in_compared);
  return 0;
}
```

**fork/conformance/programs/stdlib/optional_destroy_diff.diff.cpp**

```cpp
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// C++17 oracle for optional_destroy_diff.carbon: the same live-object counts
// over std::optional<Tracked>, printed as printf("%d\n", x). `Tracked` has a
// user-declared copy constructor, so it has no move constructor and every
// copy or move of it is counted the same way as the Carbon `Copy`.

#include <cstdio>
#include <optional>

struct Tracked {
  explicit Tracked(int* l) : id(1), live(l) { ++*live; }
  Tracked(const Tracked& other) : id(other.id), live(other.live) { ++*live; }
  auto operator=(const Tracked&) -> Tracked& = delete;
  ~Tracked() { --*live; }
  int id;
  int* live;
};

static auto operator==(const Tracked& a, const Tracked& b) -> bool {
  return a.id == b.id;
}

static auto B(bool b) -> int { return b ? 1 : 0; }

struct Box {
  std::optional<Tracked> o;
};

static auto HoldField(int* live) -> void {
  Tracked t(live);
  Box b{std::optional<Tracked>(t)};
  std::printf("%d\n", *live);
}

static auto HoldNested(int* live) -> void {
  Tracked t(live);
  std::optional<Tracked> inner(t);
  std::optional<std::optional<Tracked>> outer(inner);
  std::printf("%d\n", *live);
}

template <typename T>
static auto HoldGeneric(const T& a) -> void {
  std::optional<T> o(a);
}

static auto CallGeneric(int* live) -> void {
  Tracked t(live);
  HoldGeneric(t);
  std::printf("%d\n", *live);
}

static auto MakeSome(int* live) -> std::optional<Tracked> {
  Tracked t(live);
  return std::optional<Tracked>(t);
}

static auto HoldReturned(int* live) -> void {
  std::optional<Tracked> o = MakeSome(live);
  std::printf("%d\n", *live);
}

static auto HoldCompared(int* live) -> void {
  Tracked t(live);
  std::optional<Tracked> a(t);
  std::optional<Tracked> b(t);
  std::printf("%d\n", B(a == b));
  std::printf("%d\n", *live);
}

auto main() -> int {
  int field = 0;
  HoldField(&field);
  std::printf("%d\n", field);
  int nested = 0;
  HoldNested(&nested);
  std::printf("%d\n", nested);
  int generic = 0;
  CallGeneric(&generic);
  std::printf("%d\n", generic);
  int returned = 0;
  HoldReturned(&returned);
  std::printf("%d\n", returned);
  int compared = 0;
  HoldCompared(&compared);
  std::printf("%d\n", compared);
  return 0;
}
```

**fork/conformance/programs/stdlib/optional_get_empty_fail_stop.carbon**

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: -6
//
// `Get()` on an empty `Core.Optional(T)` fails-stop (fork design F-015,
// docs/design/optional.md, the W-173 rule): one line on stderr
// (`carbon: Core.Optional.Get on an empty value; terminating`), then
// `abort()`, as a `Core.Slice` bounds violation does
// (stdlib/slices_bounds_fail_stop.carbon, D-SL-4). SIGABRT is 6 on Linux and
// macOS, and the runner reports death by signal N as -N, so -6 is the whole
// observable. Deliberately no `EXPECT-STDOUT`: `abort()` does not flush
// stdio. The `Core.Print(v)` after the read makes a run that survives the
// empty `Get()` fail loudly (exit 0 != -6 -> RUN-FAIL).
//
// Hand-derived expectation (R16(d)): `Pick(-1)` returns `None()` because
// `-1 > 0` is false, so `o.HasValue()` is false and `o.Get()` takes the
// fail-stop branch before any output.

import Core library "io";

fn Pick(x: i32) -> Core.Optional(i32) {
  if (x > 0) {
    return Core.Optional(i32).Some(x);
  }
  return Core.Optional(i32).None();
}

fn Run() -> i32 {
  let o: Core.Optional(i32) = Pick(-1);
  let v: i32 = o.Get();
  Core.Print(v);
  return 0;
}
```

**fork/conformance/programs/stdlib/optional_pointer_get_empty_fail_stop.carbon**

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Stdlib: Optional
// EXPECT-EXIT: -6
//
// `Get()` on an empty `Core.Optional(T*)`, the null-niche Optional that a
// nullable C++ pointer imports as, fails-stop instead of returning the null
// pointer (fork design F-015, docs/design/optional.md, the W-173 rule), so a
// `T*` obtained from an Optional is never null and dereferencing it needs no
// null check: the rule F-013's TY4 ("null is never a hole") states. One line
// on stderr, then `abort()`; -6 is SIGABRT as the runner reports it (the
// stdlib/slices_bounds_fail_stop.carbon precedent). No `EXPECT-STDOUT`:
// `abort()` does not flush stdio, and the `Core.Print` after the read makes a
// run that survives fail loudly (exit 0 != -6 -> RUN-FAIL).
//
// Hand-derived expectation (R16(d)): `Pick(-1)` returns `None()`, the null
// pointer, because `-1 > 0` is false, so `o.Get()` takes the fail-stop branch
// before the dereference and before any output.

import Core library "io";

fn Pick(x: i32, p: i32*) -> Core.Optional(i32*) {
  if (x > 0) {
    return Core.Optional(i32*).Some(p);
  }
  return Core.Optional(i32*).None();
}

fn Run() -> i32 {
  var n: i32 = 7;
  let o: Core.Optional(i32*) = Pick(-1, &n);
  let p: i32* = o.Get();
  Core.Print(*p);
  return 0;
}
```

The program table in fork/conformance/README.md is regenerated by
`runner.py --update-readme-table` (160 rows; the seven rows that change are
the three arbiters' SKIP → run and the three new programs, `differential` for
optional_destroy_diff, M-13).

### §2.5 Docs (D-OP2-11)

**docs/design/optional.md**, eighteen exact replacements of whole paragraphs,
table rows, code lines and list items. The script below is the spec: each
pair's old text must occur exactly once, and the new texts are verbatim. Run on
a copy (`python3 optional_md_edits.py docs/design/optional.md <out> <date>`,
`<date>` the date commit 4 is made, `YYYY-MM-DD`), it was measured: 18 applied,
582 → 591 lines, R31 counts unchanged (11 H2, 3 H3, 55 list items), no new
line over 80 columns outside tables and links, and no W-170, W-171 or W-173
left on the page. What the eighteen do, in order:

1.  The status line (:9-12) names OP-2's landing and what it changed.
2.  The `Get` row (:90): "requires `HasValue()`, and fails-stop on an empty
    value".
3.  "Not provided" (:98-103) loses the checked `Get()` (W-173) and the
    destruction of the held value (W-170).
4.  The storage block's `let Type: type;` (:142) becomes `let Type: Destroy;`.
5.  The storage block gains `impl forall [T: Copy & Destroy]
    DefaultOptionalStorage(T) as Destroy;` after the default storage's impl.
6.  The generic-local limit (:284-290) becomes the statement that a checked
    generic may compare an Optional it creates.
7.  The `bool` and nested-pointer sentences (:296-302) say both payloads work.
8.  Ownership's first paragraph (:358-363) states the rule as implemented,
    with `Core.Optional(T*)` trivially destructible.
9.  Ownership's second paragraph (:364-379) becomes two: how the rule is
    implemented (the storage's `Destroy`, the adapter rule, the niche), and
    the `TrivialDestructor` consequence (W-196) with p001154's alternative.
10. The comparisons paragraph (:381-386) loses the nested-leak sentence.
11. The `Get()` paragraph (:388-392) states the fail-stop and TY4.
12. The assignment paragraph (:398-400) gains the W-197 sentence.
13. The 0.1 limits lose W-170 and W-171 (:466-476).
14. The 0.1 limits lose W-173 (:481-482).
15. W-196 and W-197 are added before W-195's item (:505).
16. The alternative "Destroying the held value with a declared `Destroy` now"
    (:542-544) becomes two: a `Destroy` on `Optional(T)` itself, and amending
    TY4 instead of checking `Get()`.
17. The alternative "A checked `Get()` or a pointer `==`" (:554-555) keeps only
    the pointer `==`.
18. The fork reference (:581-582) adds this plan.

```python
# Applies fork/optional2/plan.md §2.5's edits to a copy of docs/design/optional.md.
# Usage: python3 optional_md_edits.py <in> <out> <date>
import sys
src, out, date = sys.argv[1], sys.argv[2], sys.argv[3]
s = open(src).read()
E = []
E.append(("""**Status:** Fork design (F-015, 2026-10-13): `Core.Optional` as implemented in
the fork's prelude, core/prelude/types/optional.carbon; toolchain status: OP-1
landed 2026-10-13. Upstream has no approved design for `Core.Optional` (proposal
p006357, future work).
""", f"""**Status:** Fork design (F-015, 2026-10-13): `Core.Optional` as implemented in
the fork's prelude, core/prelude/types/optional.carbon; toolchain status: OP-1
landed 2026-10-13, and OP-2 landed {date}: an Optional destroys the value it
holds, `Get()` fails-stop on an empty value, and `Core.Optional(bool)` and
nested pointer-niche Optionals read correctly. Upstream has no approved design
for `Core.Optional` (proposal p006357, future work).
"""))
E.append(("""| `fn Get(self) -> T` | a copy of the held value; requires `HasValue()`, unchecked in 0.1 (W-173) |
""", """| `fn Get(self) -> T` | a copy of the held value; requires `HasValue()`, and fails-stop on an empty value |
"""))
E.append(("""`Core.Eq`, which is every built-in pointer (W-174); a checked `Get()` (W-173);
destruction of the held value (W-170).
""", """`Core.Eq`, which is every built-in pointer (W-174).
"""))
E.append(("""private interface OptionalStorage {
  let Type: type;
""", """private interface OptionalStorage {
  let Type: Destroy;
"""))
E.append(("""impl forall [T: Copy & Destroy] T as OptionalStorage
    where .Type = DefaultOptionalStorage(T);
""", """impl forall [T: Copy & Destroy] T as OptionalStorage
    where .Type = DefaultOptionalStorage(T);

impl forall [T: Copy & Destroy] DefaultOptionalStorage(T) as Destroy;
"""))
E.append(("""In 0.1 a checked generic can compare only `Core.Optional(T)` values that it
receives: a local or temporary `Core.Optional(T)` in its body, such as
`Core.Optional(T).Some(a) == b` or a `let` of that type, is rejected with
"cannot access member of interface `Core.Destroy` in type
`Core.Optional(T as Core.OptionalStorage)`", because `Core.Optional` declares
no `Destroy` impl (W-170).
""", """A checked generic may also compare a `Core.Optional(T)` that it creates, such
as `Core.Optional(T).Some(a) == b` or a `let` of that type: every storage type
is `Core.Destroy`, so the generic can destroy the Optional it made.
"""))
E.append(("""`Core.Optional(bool)` is `Core.Eq`, but in 0.1 comparing two of them, like
reading or copying one, crashes the compiler (W-171). The same defect makes
reading, copying and comparing a `Core.Optional(Core.Optional(U*))` return wrong
values with no diagnostic (W-171). For a payload that exists only at compile
time, such as `Core.IntLiteral`, comparing two `Core.Optional(T)` values passes
check and then crashes the compiler in lowering, as a checked generic's `==` on
`Core.IntLiteral` does without Optional (W-195).
""", """`Core.Optional(bool)` and `Core.Optional(Core.Optional(U*))` compare, and are
read and copied, like any other payload. For a payload that exists only at
compile time, such as `Core.IntLiteral`, comparing two `Core.Optional(T)` values
passes check and then crashes the compiler in lowering, as a checked generic's
`==` on `Core.IntLiteral` does without Optional (W-195).
"""))
E.append(("""copying an `Optional(T)` copies its value, and destroying a non-empty
`Optional(T)` destroys its value. In 0.1 the last rule is not implemented: a
held value is never destroyed (W-170), so a `T` whose `Destroy` frees or counts
leaks one destruction per held value. The fix must keep `Core.Optional(T*)`
trivially destructible, because a union may have a `Core.Optional(T*)` field.
""", """copying an `Optional(T)` copies its value, and destroying a non-empty
`Optional(T)` destroys its value, once. `Core.Optional(T*)` has nothing to
destroy and is trivially destructible, so a union may have a
`Core.Optional(T*)` field.
"""))
E.append(("""considered alternative). The 0.1 storage holds the value in a
`MaybeUnformed(T)`, which runs no destructor, and no `Destroy` impl for
`Core.Optional` exists. Declaring one is not enough: under
[Destructors](classes.md#destructors), a class that defines a destructor with
a non-empty body is not `TrivialDestructor`, so a declared `Destroy` on
`Optional(T)` would make the pointer niche nontrivial and reject the
`Core.Optional(T*)` union fields that
[Unions](unions.md#trivially-destructible-and-trivially-copyable-types) admits.
Proposal p001154's way out, a conditional `TrivialDestructor` impl for
`Optional(U)`, was considered there and not adopted. The program
fork/conformance/programs/stdlib/optional_destroys_value.carbon states the rule
and is skipped until W-170 lands.
""", """considered alternative). The default storage holds the value in a
`MaybeUnformed(T)`, which runs no destructor of its own, and declares the
`Destroy` that destroys the value when it holds one. `Core.Optional(T)` adapts
its storage, and an adapter is destroyed as its adapted type
([Adapters](classes.md#adapters)), so destroying the Optional runs that
`Destroy`. The pointer niche's storage, a `MaybeUnformed(T*)`, declares none,
so `Core.Optional(T*)` stays trivially destructible and keeps the union fields
that [Unions](unions.md#trivially-destructible-and-trivially-copyable-types)
admits; a `Destroy` declared on `Optional(T)` itself would have reached the
pointer niche too.

Under [Destructors](classes.md#destructors), a class that defines a destructor
with a non-empty body is not `TrivialDestructor`, so `Core.Optional(T)` for a
non-pointer `T` is not trivially destructible even when `T` is: a
`Core.Optional(i32)` is not a union field type, and destroying one tests
whether it holds a value (W-196). Proposal p001154's way to make it
conditional, a `TrivialDestructor` impl for `Optional(U)` when `U` has one, was
considered there and not adopted. The programs
fork/conformance/programs/stdlib/optional_destroys_value.carbon and
optional_destroy_diff.carbon, the second with a C++ `std::optional` oracle,
state the rule.
"""))
E.append(("""with an empty operand runs neither ([Comparison](#comparison)). Until W-170
lands, a comparison of two non-empty `Core.Optional(Core.Optional(T))` values
also leaks one copy of each `T` that the inner values hold: each outer `Get()`
copy is a `Core.Optional(T)`, and destroying it does not destroy its value.
""", """with an empty operand runs neither ([Comparison](#comparison)).
"""))
E.append(("""`Get()` requires `HasValue()`. In 0.1 the requirement is not checked (W-173): on
an empty value `Get()` returns the unformed storage, and for `Core.Optional(T*)`
it returns a null pointer, whose dereference needs no `unsafe`. That contradicts
the safety design's TY4 ("null is never a hole", F-013) until W-173 lands a
checked `Get()` or TY4 is amended.
""", """`Get()` requires `HasValue()`. On an empty value it fails-stop: it writes
`carbon: Core.Optional.Get on an empty value; terminating` to standard error and
aborts, as a `Core.Slice` bounds violation does. So `Get()` never returns the
unformed storage, and for `Core.Optional(T*)` never returns a null pointer,
which is the safety design's TY4 ("null is never a hole", F-013).
"""))
E.append(("""workstream (W-160: assignment does not destroy the overwritten value).
""", """workstream (W-160: assignment does not destroy the overwritten value). A class
that declares its own `Destroy` does not yet destroy its fields after that
`Destroy` runs, so an Optional field of such a class keeps its value (W-197); a
class without one destroys its fields, an Optional field included.
"""))
E.append(("""-   **W-170: an Optional never destroys the value it holds.** See
    [Ownership and lifetime](#ownership-and-lifetime). Closes when a `Destroy`
    for `Core.Optional` lands that keeps `Core.Optional(T*)` trivially
    destructible, and optional_destroys_value.carbon passes.
-   **W-171: the default storage misreads a payload whose value representation
    differs from that of its `MaybeUnformed` field.** For
    `Core.Optional(bool)`, `Get()`, a copy and `==` crash the compiler; for
    `Core.Optional(Core.Optional(U*))` they return wrong values with no
    diagnostic. Closes when both lower correctly, and optional_bool.carbon and
    optional_nested_pointer.carbon pass.
""", ""))
E.append(("""-   **W-173: `Get()` on an empty Optional is unchecked.** Closes when `Get()`
    on an empty value is a fail-stop.
""", ""))
E.append(("""-   **W-195: a checked generic's `==` on a compile-time-only type aborts
""", """-   **W-196: `Core.Optional(T)` for a non-pointer `T` is not trivially
    destructible.** See [Ownership and lifetime](#ownership-and-lifetime): a
    `Core.Optional(i32)` is not a union field type, and destroying one tests
    whether it holds a value, where C++'s `std::optional<int>` is trivially
    destructible. Closes when a conditional `TrivialDestructor` rule is
    designed and adopted.
-   **W-197: a class that declares its own `Destroy` does not destroy its
    fields.** An Optional field of such a class keeps its value. Filed under
    classes. Closes when the fields are destroyed after the class's `Destroy`.
-   **W-195: a checked generic's `==` on a compile-time-only type aborts
"""))
E.append(("""-   **Destroying the held value with a declared `Destroy` now.** It makes every
    Optional nontrivially destructible, the pointer niche included, so a
    `Core.Optional(T*)` union field stops compiling (W-170).
""", """-   **A `Destroy` declared on `Optional(T)` itself.** It makes every Optional
    nontrivially destructible, the pointer niche included, so a
    `Core.Optional(T*)` union field stops compiling; the default storage's
    `Destroy`, reached because an adapter is destroyed as its adapted type, does
    not reach the niche.
-   **Amending TY4 to name `Get()`'s precondition instead of checking it.**
    That would describe a hole rather than close it; the check costs nothing in
    a `for` loop, whose own `HasValue()` test makes it dead after optimization.
"""))
E.append(("""-   **A checked `Get()` or a pointer `==` in this design's first step.** Each is
    its own design (W-173, W-174), and neither is needed for comparison.
""", """-   **A pointer `==` in this design.** It is its own design (W-174), and is not
    needed for comparison.
"""))
E.append(("""-   Fork: [fork/optional/plan.md](/fork/optional/plan.md) (decisions
    D-OP-1..15), [fork/decision-log.md](/fork/decision-log.md) (F-015)
""", """-   Fork: [fork/optional/plan.md](/fork/optional/plan.md) (decisions
    D-OP-1..15), [fork/optional2/plan.md](/fork/optional2/plan.md) (decisions
    D-OP2-1..14), [fork/decision-log.md](/fork/decision-log.md) (F-015)
"""))
for old, new in E:
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
open(out, "w").write(s)
print(len(E), "edits applied")
```

**docs/design/classes.md**, a dated blockquote after the adapter rules (after
:1802, before "Inside an adapter, the `Self` type matches the adapter."):

```markdown
> **Fork amendment (<date>, OP-2).** An adapter declares no fields, so its
> object is an object of the adapted type, and destroying an adapter destroys
> that object as the adapted type's destructor does; an adapter is trivially
> destructible exactly when its adapted type is. The fork's 0.1 toolchain
> implements this (fork/optional2/plan.md, D-OP2-3); before it, an adapter's
> object was never destroyed.
```

No other page changes: loops.md, error_handling.md and README.md's OP-1
amendments name no item OP-2 closes (`grep` for W-170, W-171 and W-173 under
docs/ finds only optional.md). SAFE-1's pages are PR 53's (D-OP2-14, §2.6).

### §2.6 Records (commit 4 moves the row; commit 5 writes the rest, after §8)

-   **fork/gap-analysis.md, row "Stdlib: Optional"** (:80 here; found by its
    bullet text at the merge), in commit 4 (D-OP2-12, D-OP-13): status DONE,
    evidence cell: "OP-1 and OP-2 landed (W-058 DISCHARGED 2026-10-13; W-170,
    W-171 and W-173 DISCHARGED `<date>`; fork/optional/plan.md,
    fork/optional2/plan.md; decision-log "OP-1 / F-015: Core.Optional
    comparison and design" and "OP-2: Core.Optional ownership, the
    MaybeUnformed representation fix, checked Get"): `Core.Optional(T)` has a
    decided fork design, docs/design/optional.md (F-015: the class kept per
    D-EH-1, its storage with the C++-pointer null niche,
    `None`/`Some`/`HasValue`/`Get`, the conversions, `Copy` and `Try`); it
    compares when `T` does, with `std::optional`'s rules (the `final` `EqWith`
    and `OrderedWith` impls of core/prelude/types/optional.carbon); it owns its
    value: destroying a non-empty Optional destroys the value once, while
    `Core.Optional(T*)` stays trivially destructible (the default storage
    declares the `Destroy`, and an adapter is now destroyed as its adapted
    type, toolchain/check/custom_witness.cpp); `Get()` on an empty value
    fails-stop, so F-013's TY4 holds for `Get()`; and `Core.Optional(bool)` and
    `Core.Optional(Core.Optional(U*))` read, copy and compare correctly
    (lowering converts a value between `MaybeUnformed(T)`'s and `T`'s
    representations, toolchain/lower/handle.cpp). DONE with filed 0.1 limits,
    none an operation of `Core.Optional` failing through its documented API
    (D-OP-13, D-OP2-12): `Optional(T*)` compares only when `T*` is `Core.Eq`
    (W-174); no explicit `as` between Optionals (W-175); `T` must be
    `Core.Copy & Core.Destroy` or a pointer (W-176); not matchable (W-177); no
    `like` (W-178); a float or character literal passed to `Some` aborts check
    (W-172); a subsumed specialization is diagnosed only where it is used
    (W-179); `==` on `Core.Optional(Core.IntLiteral)` aborts lowering (W-195);
    `Core.Optional(T)` for a non-pointer `T` is not trivially destructible
    (W-196); a class with its own `Destroy` does not destroy an Optional field
    (W-197). Conformance: 12 of 13 programs PASS (stdlib/optional_basic,
    optional_pointer_niche, optional_missing_ops, optional_compare_diff,
    optional_compare_generic, optional_compare_payload,
    optional_destroys_value, optional_bool and optional_nested_pointer SKIP ->
    PASS, optional_destroy_diff with a C++17 std::optional oracle,
    optional_get_empty_fail_stop,
    optional_pointer_get_empty_fail_stop) and optional_pointer_compare (W-174)
    is a SKIP that does not bound the row — EXPECTED, not of record: container
    run `<date>` on the carbonbuild toolchain of `<commit 2 sha>` (scoreboard
    generated `<timestamp>`), 138/0/22 over 160; floor of record 128/0/22 over
    150, run 37402970811; the hosted run R9 requires is pending with no
    dispatch date (Actions disabled)." The header's counts move from 30 DONE /
    21 PARTIAL to 31 DONE / 20 PARTIAL (4 MISSING / 1 DESIGN-ONLY unchanged,
    over 56), and its scoreboard sentence is re-written from §8.4's run. §W9's
    sentence "the Optional's destruction of its value (W-170) and the default
    storage's defect for `Core.Optional(bool)` and nested pointer-niche
    Optionals (W-171) remain" becomes "OP-2 closed the Optional half
    (destruction, W-170; the `MaybeUnformed` representation defect, W-171; the
    checked `Get()`, W-173; `<date>`)".
-   **fork/inventory/work-items.json** (commit 5): W-170, W-171 and W-173 get
    titles "OP-2 (DISCHARGED `<date>`): ..." and notes recording the landing
    commits, the measured evidence (M-5..M-8, M-2..M-4, M-10) and the
    corrections of §0.3 items 1-4; W-170's subsystem becomes "core/prelude +
    toolchain/check (custom_witness.cpp)" and W-171's "toolchain/lower
    (handle.cpp) + toolchain/check (convert.cpp)". Two new items after the
    then-last one: **W-196** (kind `missing-feature`, size M, subsystem
    "core/prelude + docs/design", bullet "Stdlib: Optional", title "OP-2
    residue: `Core.Optional(T)` for a non-pointer `T` is not trivially
    destructible, even when `T` is", evidence M-7's union probe, M-10's loop
    measurement, check/testdata/optional/destroy.carbon's
    `fail_union_value_field` split, classes.md:1992-2003, p001154:211-227,
    notes as §1.7, break condition as §1.7) and **W-197** (kind
    `toolchain-defect`, size S, subsystem "toolchain/check
    (custom_witness.cpp) + core/prelude/destroy.carbon", bullet "Type system:
    User-defined types (classes)", title "OP-2 residue: a class that declares
    its own `Destroy` does not destroy its fields after its `Op`", evidence
    M-9's `Outer` and `Plain`, destroy.carbon:18-24, notes as §1.7). W-108
    gets an "OP-2 note" with §0.3 item 5's measurement and no status change.
-   **fork/decision-log.md** (commit 5): an entry "OP-2: Core.Optional
    ownership, the MaybeUnformed representation fix, checked Get (`<date>`)"
    above the then-newest landed entry, recording D-OP2-1..14 by number, the
    row's move to DONE, the commits, the M-numbers it rests on, V-3 (this plan's
    head)
    and that F-015 is implemented and no F-id minted.
-   **fork/ORCHESTRATION.md** (commit 5): the stamp paragraph; a Branches row
    for `claude/carbon-fork-0-1-op2`; the Scoreboard line (138/0/22 over 160,
    expected); Next actions: OP-2 after PR 56 in the merge order, and item 6's
    TY4 amendment replaced (D-OP2-14) by: "**Fork amendment (`<date>`, OP-2,
    F-015).** `Get()` on an empty `Core.Optional(T*)` fails-stop
    (fork/optional2/plan.md D-OP2-7), so the pointer it returns is never null
    and TY4 holds on that path; a `match` over a `Core.Optional`, which TY4
    also names, waits on W-177." (the mutation_safety.md amendment of item 6 is
    unchanged).
-   **fork/optional/plan.md** is not edited (OP-1's record); this plan gets its
    landed notes in commit 5.

## §3 Commit structure (one PR, "OP-2: Core.Optional owns its value, the MaybeUnformed unsafe-as fix, checked Get", R29(b))

1.  **Plan.** This commit, "OP-2 plan (rev 1): Core.Optional owns its value,
    the MaybeUnformed unsafe-as fix, checked Get"; later revisions fold the two
    plan reviews of R29(c), each amended sentence marked "(amended `<date>`,
    review fold: <finding>)", each revision a new commit.
2.  **Toolchain, prelude and CHECK-free goldens, in ONE commit.** §2.2's
    three files, §2.1's prelude and §2.3's five sources. Either half alone
    breaks file_test (measured, as ST-1's M-10 did): the toolchain alone fails
    1 golden (range_for, M-7) and the prelude alone 28 (M-7), and the prelude
    alone is also wrong (its storage `Destroy` is unreachable without the
    adapter hunks, M-5, and `Core.Optional(bool)` still aborts without the
    lowering hunk, M-1), so neither is a coherent commit. Expected gate on this
    commit: red on exactly §6.1's 28 goldens and the five empty new ones,
    nothing else, no crash.
3.  **Fill.** Only the output of `autoupdate.sh` run to its fixpoint (R26):
    the 28 refills and the five new goldens, converging as M-11 and M-12 did; a
    second run that changes more than `.loc` numbers is a stop. Message
    "Autoupdate testdata goldens on the container arbiter" (the OP-1, ST-1 and
    UA-2 precedent).
4.  **Conformance, docs and the row.** §2.4's program changes and the
    regenerated README table, §2.5's docs, and §2.6's gap row, header and §W9
    sentence, quoting §8.4's run (D-OP2-12, D-OP-13: the row moves in the commit
    that un-SKIPs the arbiters).
5.  **Discharge.** §2.6's other records, written after the implementation
    review, the merge of trunk and §8.8's re-verification of the merge commit,
    so every count is quoted from a run on the tree that lands (R9).

**Between commits 4 and 5**, in this order: the implementation review of R29(c)
(ONE review once hosted verification is green; until then two, the OP-1
precedent), its fold by a separate fixer (R11) in new commits ("OP-2 fixes: fold
the implementation review"), any refill being its own "Autoupdate testdata
goldens on the container arbiter" commit; then the merge of trunk (a merge
commit, never a rebase), taken when OP-2 is next in D-OP2-13's queue, that is,
after PR 56 has merged; then §8.8 on the merge commit; then commit 5. Before
each of commits 2, 4 and 5 and each fix commit, `uvx prek run --files <that
commit's files>` runs to a fixpoint (a run that changes nothing), with R31's
heading and list-item counts recorded before and after for every `.md` in the
commit; before hand-over, `uvx prek run --all-files` runs to a fixpoint too
(R25). Every commit uses explicit paths (R20), the author `jmann345
<jerrymannstan@gmail.com>`, the committer `Claude <noreply@anthropic.com>` and
the session's attribution trailers. A problem found after a commit exists is
fixed by a new commit, never by amending one (AGENTS.md).

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

"Measured" means the line was produced by variant **d**'s file_test with
**t3**, in M-12's mirror from §2.3's sources, or in M-11's mirror for the
refills; at the real paths only the TIP lines, `ModuleID`, `source_filename`,
`DIFile` names and split-file names differ.

| Golden | Split or function | Key lines | Basis |
| --- | --- | --- | --- |
| check/testdata/class/adapter/destroy.carbon | `destructible.carbon` | `fn @Destroy.WithSelf.SubobjectDestroy.loc23_3.1(%self.param: ref %AdaptP)` with `%.loc23_3.1: ref %P = as_compatible %self.param` and a bound `SelfDestruct` over `facet_value constants.%P, (constants.%Destroy.impl_witness)` (P's declared impl); `@...SubobjectDestroy.loc23_3.2(%self.param: ref %AdaptAdaptP)` with `ref %AdaptP = as_compatible %self.param` and a `SelfDestruct` call; 320 lines, 259 CHECK | measured |
| same | `trivial.carbon` | `fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.2(%self.param: ref %AdaptI32) = "no_op";` | measured |
| check/testdata/as/maybe_unformed_value_repr.carbon | `bool.carbon` | `%.loc5_68.1: ref %MaybeUnformed.5b2 = value_as_ref %m.ref`, `%.loc5_68.2: ref bool = as_compatible %.loc5_68.1`, `%.loc5_68.3: bool = acquire_value %.loc5_68.2` (D-OP2-2; this compile aborted at convert.cpp:1698 before OP-2) | measured |
| same | `i32.carbon` | `%.loc5_65.1: %i32 = as_compatible %m.ref` and no `value_as_ref` | measured |
| same | `generic.carbon` | `%.loc6_19.1: @Unwrap.%T.as_type.loc5_63.1 (%T.as_type.5d6) = as_compatible %m.ref` and no `value_as_ref` (the specific decides, D-OP2-1); 458 lines, 412 CHECK | measured |
| check/testdata/optional/destroy.carbon | `concrete.carbon` | `fn @Destroy.WithSelf.SubobjectDestroy.loc15(%self.param: ref %Optional.82b)` with `%.loc15_3.1: ref %DefaultOptionalStorage.44d = as_compatible %self.param` and a `SelfDestruct` call | measured |
| same | `pointer.carbon` | `fn @Destroy.WithSelf.SubobjectDestroy.loc6(%self.param: ref %Optional.5b3) = "no_op";` | measured |
| same | `generic.carbon`, `union_pointer_field.carbon` | no diagnostic | measured |
| same | `fail_union_value_field.carbon` | `` error: union field `o` has type `Core.Optional(i32 as Core.OptionalStorage)`, which is not trivially copyable and destructible [UnionFieldNotTriviallyCopyable] `` at column 7 of `var o` (D-OP2-6); 622 lines, 543 CHECK | measured |
| lower/testdata/builtins/maybe_unformed_value_repr.carbon | `concrete.carbon` | `define i1 @_CFromBool.Main(ptr %m)` with `load i8, ptr %m, align 1`; `define ptr @_CFromOptionalPointer.Main(ptr %m)` with `load ptr, ptr %m, align 8`; `@_CRoundTrip.Main(ptr %o)` with `alloca ptr`, `store ptr %o`, then `load ptr` from it | measured |
| same | `generic.carbon` | three specifics of `Unwrap`: `define linkonce_odr i1 @_CUnwrap.Main.<hash>(ptr %m)` with `load i8, ptr %m`; `define linkonce_odr i32 @_CUnwrap.Main.<hash>(i32 %m)` with `ret i32 %m`; `define linkonce_odr ptr @_CUnwrap.Main.<hash>(ptr %m)` with `load ptr, ptr %m` (not coalesced); 352 lines, 299 CHECK | measured |
| lower/testdata/optional/destroy.carbon | `destroy.carbon` | `@_CHold.Main` calls a `SelfDestruct` on `%o.var` whose `SubobjectDestroy` calls the storage's `SelfDestruct`, which calls `@"_COp.DefaultOptionalStorage.<hash>.Core:Destroy.Core.<hash>"`: `%has_value = getelementptr inbounds nuw <{ { i32 }, i1 }>, ptr %self, i32 0, i32 1`, `load i8`, `trunc i8 ... to i1`, `br i1`, and on the true edge a `SelfDestruct` of `%value` that calls `@"_COp.Tracked.Main:Destroy.Core"`; `@_CHoldPointer.Main`'s `SelfDestruct` is the no-op one | measured |
| same | `get.carbon` | `define linkonce_odr i32 @_CGet.Optional.Core.<hash>(ptr %self)` with `%fail_stop.load = load { ptr, i64 }, ptr @const.anon`, `call i64 @write(i32 2, ...)`, `call void @abort()`; the `bool` storage `Get` (`define linkonce_odr i1 @"_CGet.<hash>:OptionalStorage.Core.<hash>"(ptr %value)`) with `load i8` and `trunc i8 ... to i1` (W-171); 530 lines, 482 CHECK | measured |
| the 28 of §6.1 | -- | each changes only by: generated destroy functions for `DefaultOptionalStorage` replaced by its declared impl; `Optional` adapters' `SubobjectDestroy` gaining the storage call when the payload has destruction work; `import_ref`s of `OptionalStorage.Type` typed `%Destroy.type`; `Get` specifics gaining the fail-stop branch; debug-info lines of the appended functions | measured (M-11) |

Falsifiers: any crash; a golden outside §6.1 and §2.3 in the fill's diff; a
`fail_` split that compiles or a non-`fail_` split with a diagnostic; any key
line above that the fill does not reproduce; a lowered `Get` with no
`HasValue` test before the storage read; a `Core.Optional(T*)` specific with a
non-no-op `SubobjectDestroy`.

## §5 Conformance: three SKIP → PASS, three new; delta PASS +6, SKIP -3, programs +3

From PR 56's head (OP-1 discharged: 132 PASS / 0 FAIL / 25 SKIP over 157,
48/56, its container run; re-measured on **d** + **t2** with unchanged programs
as the same, M-13) the expected result is **138 PASS / 0 FAIL / 22 SKIP over
160, bullets 48/56** (measured, M-13): optional_destroys_value, optional_bool
and optional_nested_pointer SKIP → PASS, optional_destroy_diff,
optional_get_empty_fail_stop and optional_pointer_get_empty_fail_stop new PASS.
The Optional bullet's rollup was PASS and stays PASS, now over 13 programs (12
PASS, optional_pointer_compare SKIP), so the bullet count does not move. From
the floor of record (fork/conformance/out/scoreboard.json, run 37402970811: 128
/ 0 / 22 over 150, 48/56) OP-1 and OP-2 together are PASS +10 and programs +10,
SKIP unchanged. Other PRs land first (PR 53, PR 51, PR 52, SC-1, PR 54, PR 55,
PR 56); §8.8 re-measures on the merge commit and the records quote that run,
never a sum by hand. All totals are expected, not of record (Actions is
disabled), and the row's evidence says so in those words.

## §6 Churn and collision analysis

### §6.1 Golden churn (measured, M-7, M-11)

The 28 refilled goldens, `+4184 -6785` lines in all (the
`git diff --no-index --numstat` of each refill against this worktree):

| Golden (under toolchain/) | Added | Removed |
| --- | --- | --- |
| check/testdata/interop/cpp/class/export/union.carbon | +13 | -85 |
| check/testdata/interop/cpp/class/import/field.carbon | +8 | -4 |
| check/testdata/interop/cpp/function/import/decayed_param.carbon | +13 | -85 |
| check/testdata/interop/cpp/function/import/pointer.carbon | +90 | -592 |
| check/testdata/interop/cpp/function/import/void_pointer.carbon | +39 | -255 |
| check/testdata/interop/cpp/macros/macros.carbon | +12 | -84 |
| check/testdata/interop/cpp/range_for.carbon | +583 | -1983 |
| check/testdata/interop/cpp/stdlib/initializer_list.carbon | +40 | -40 |
| check/testdata/interop/cpp/stdlib/vector_view.carbon | +23 | -93 |
| check/testdata/interop/cpp/stdlib/vector_view_span.carbon | +152 | -356 |
| check/testdata/operators/question_optional.carbon | +112 | -106 |
| check/testdata/optional/compare.carbon | +44 | -35 |
| check/testdata/slice/basic.carbon | +49 | -224 |
| check/testdata/union/basic.carbon | +36 | -108 |
| lower/testdata/array/iterate.carbon | +237 | -240 |
| lower/testdata/builtins/cpp.carbon | +103 | -83 |
| lower/testdata/for/bindings.carbon | +161 | -164 |
| lower/testdata/for/break_continue.carbon | +252 | -254 |
| lower/testdata/for/for.carbon | +254 | -256 |
| lower/testdata/interop/cpp/class/export/union.carbon | +55 | -51 |
| lower/testdata/interop/cpp/nullptr.carbon | +47 | -44 |
| lower/testdata/interop/cpp/pointer.carbon | +317 | -291 |
| lower/testdata/interop/cpp/std_initializer_list_pointer_pointer.carbon | +180 | -140 |
| lower/testdata/interop/cpp/std_initializer_list_pointer_size.carbon | +181 | -141 |
| lower/testdata/interop/cpp/void.carbon | +298 | -235 |
| lower/testdata/optional/compare.carbon | +300 | -271 |
| lower/testdata/primitives/optional.carbon | +559 | -539 |
| lower/testdata/union/basic.carbon | +26 | -26 |

Of these, 15 change with the checked `Get` alone, every golden that lowers or
imports a `Get` specific (check: interop/cpp/class/import/field,
interop/cpp/range_for, interop/cpp/stdlib/vector_view, vector_view_span,
slice/basic; lower: array/iterate, for/bindings, for/break_continue, for/for,
interop/cpp/class/export/union, interop/cpp/nullptr, interop/cpp/pointer,
interop/cpp/void, optional/compare, primitives/optional; M-10); the storage
destroy without `let Type: Destroy` changes none outside those 15 (M-8's
**t2nt** fails exactly them); the bound's SemIR (`import_ref`s typed
`%Destroy.type`) adds the other 13; the W-171 fix alone changes none (M-4). Plus
the five new goldens (2282 lines, 1995 CHECK; M-12). No min_prelude file
changes: min_prelude's own `Optional` (parts/optional.carbon) is a separate
class, and no min_prelude golden loads core/prelude.

### §6.2 Collisions (verified by `git diff --stat` against each branch's merge base at the heads named)

| Branch / PR | Shared paths | Analysis |
| --- | --- | --- |
| PR 56 (OP-1, `claude/carbon-fork-0-1-op` at 379f20f67) | everything OP-1 touched | OP-2 stacks on it (D-OP2-13). A fold commit on PR 56 after this plan that moves optional.carbon's lines, the three arbiters or optional.md's paragraphs re-anchors §2.1 and §2.5 (D-OP2-8's break condition); OP-2 merges PR 56's head with a merge commit. |
| PR 55 (ST-1, `claude/carbon-fork-0-1-st` at 21307851a) | core/prelude/types/string.carbon (imported by §2.1, not edited); records | Measured composition (M-15): no import cycle, no `FailStop` clash, the same refills. ST-1's W-160 (assignment) interacts with ownership: a leak, never a double destroy (M-9). |
| SC-1 (`claude/carbon-fork-0-1-sc` at 857d5b048) | toolchain/check/convert.cpp, toolchain/check/custom_witness.cpp; records | §2.2 applies with offsets +14 and +2 (M-16); the CHECK is at :1712 there. Semantic composition not measured (§0.2). SC-1's own goldens that lower an Optional `Get` or destroy an Optional would join the refill at the merge; §8.8's refill covers them. |
| PR 53 (SAFE-1, `claude/carbon-fork-0-1-safe` at adaae4e35) | none (docs/design/safety/ is PR 53's) | Its line citations of optional.carbon stay valid (D-OP2-8). TY4 stands unamended; OP-1's pending TY4 amendment is replaced (D-OP2-14). D-SAFE-14 is D-OP2-7's policy. |
| DD-1 (`claude/carbon-fork-0-1-dd` at 4287fe0c0) | none: it edits docs/design/README.md, pattern_matching.md and others, not optional.md or classes.md; it adds project/design_docs_cpp_pointers.carbon, which tests `HasValue()` before every `Get()` | Ids: W-180..W-194 are DD-1's; F-016 stays unminted by both. |
| PR 54 (EV-1), UA-2, CMake | none outside the shared records | -- |
| Upstream (trunk head d4f1ec203) | convert.cpp, custom_witness.cpp, lower/handle.cpp, optional.carbon | Each hunk repairs code upstream still carries (M-3, M-5), so an upstream advance conflicts only if upstream fixes the same lines; D-OP2-1's and D-OP2-3's break conditions say what then happens. |

Shared records (gap-analysis.md, work-items.json, decision-log.md,
ORCHESTRATION.md, conformance/README.md): commit 4 touches the gap row and the
README table, commit 5 the rest; each is re-anchored by its bullet text, item
id or heading at the merge of trunk (the OP-1 same-anchor rules).

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1: the lowering conversion changes a program that relied on the
    no-op.** Falsifier: a golden or program outside §6.1 changes on the
    toolchain alone. Measured: none (M-4: 0 of 1945 with variant **a**; M-7: 1,
    range_for, with variant **d**, from the adapter hunks). A pre-existing
    value `as_compatible` between differing representations was either a
    verifier abort or a silent misread (M-2), so no correct program depended on
    it.
-   **R-2: adapter destruction changes destruction for other adapters.**
    Falsifier: a golden or program whose adapter of a type with destruction
    work changes behavior unexpectedly. Measured: only range_for (an Optional of
    a C++ iterator value) among the goldens, and no conformance status change
    beyond the six Optional programs (M-13). An adapter of a C++ class now runs
    its C++ destructor; an adapter of `MaybeUnformed(T)` calls the builtin's
    empty destroy (no work, as before).
-   **R-3: a union field of `Core.Optional(T)` for a non-pointer `T` stops
    compiling.** Falsifier: a golden or program with such a field. Measured:
    none (no `UnionFieldNotTriviallyCopyable` in the 28 diffs, M-7; conformance
    unchanged, M-13). Accepted and filed (D-OP2-6, W-196).
-   **R-4: SC-1's toolchain composes differently.** Not measured (§0.2);
    falsifier: §8.8's gate or conformance on the merge commit.
-   **R-5: performance.** The destroy costs eight optimized instructions per
    `for` iteration over `Core.Range` (M-10), the checked `Get` none there; an
    unoptimized `Get` gains a test and a branch. Falsifier: a benchmark beyond
    the safety strategy's budget (D-OP2-7's and W-196's break conditions).
-   **R-6: double destruction.** Falsifier: a count below zero or a crash in
    any destroy-counting program. Measured: none (M-9: assignment, nesting,
    fields, generics, comparisons; M-14's m4 mutant shows the programs would
    catch it).
-   **R-7: the row is claimed DONE on a container run.** It is stated as
    expected and not of record (D-OP2-12), as OP-1's and ST-1's rows were.

### §7.2 Rejected alternatives

-   **A-1: a prelude-only workaround for W-171.** For example a storage `Get`
    that reads through a pointer instead of `value.value unsafe as T`.
    Rejected with evidence: the defect is the language's, not the storage's;
    M-2's probes outside Optional (`G` over `Core.MaybeUnformed(bool)` aborts,
    mu_opt_run misreads a concrete conversion) stay broken under any prelude
    change, and the storage form is the one SAFE-1's pages cite as the read
    projection (initialization_safety.md:388 on the safe branch). Falsifiable:
    a prelude change that makes M-2's two probes and the two W-171 arbiters
    pass would refute this.
-   **A-2: delete convert.cpp's check-side round trip and rely on lowering
    alone.** Measured equal (variant **b**, 0 goldens, M-4); rejected because
    it deletes upstream code where a two-line correction keeps it (D-OP2-2).
-   **A-3: always emit `value_as_ref` and `acquire_value` in generics, and make
    `value_as_ref` lowering spill a copy representation.** Hand-predicted,
    not measured: every generic `MaybeUnformed(T) unsafe as T` gains SemIR, and
    every lowered `Optional(i32)` storage `Get` and `Copy` an `alloca`, a store
    and a load; it fixes the generic escape and not the concrete
    adapter-stripped one (M-2's mu_opt_run, where `MaybeUnformed` is on both
    foundations).
-   **A-4: a `Destroy` impl on `Optional(T)` (OP-1's M-6).** Measured: fixes
    the program, breaks `Core.Optional(T*)` union fields (M-6).
-   **A-5: a conditional `TrivialDestructor`.** p001154's considered
    alternative, not adopted; the toolchain has no `TrivialDestructor`. Filed as
    W-196's break condition instead.
-   **A-6: a destroy member in the private `OptionalStorage` called from an
    impl on `Optional(T)`.** It still needs an impl keyed on `Optional`, which
    `HasUserDestroyImpl` treats as covering `Optional(T*)` (M-6).
-   **A-7: amend TY4 instead of checking `Get()`.** It would name a hole rather
    than close it, contradicting D-SAFE-14 ("fail-stop everywhere"); the check
    is free where it matters most (M-10).
-   **A-8: the checked `Get` written in the class body.** It moves every line
    after :42 (seven at least, with the `FailStop` declaration and the import
    needing lines above :30), which moves SAFE-1's citations of :186-203,
    :194 and :201 and OP-1's debug-info lines (D-OP2-8).
-   **A-9: an unchecked `UnsafeGet()` now.** No measured need (M-10); D-SAFE-14
    adds one only on such a need.
-   **A-10: keep the row PARTIAL.** No remaining limit is an operation of
    `Core.Optional` failing through its documented API (D-OP2-12).

## §8 Verification and discharge

1.  **Build** this worktree with carbonbuild, never Bazel:
    `carbonbuild/build.sh /home/user/carbon-op2` and
    `carbonbuild/install.sh /home/user/carbon-op2` (into
    `/home/user/carbon-build/carbon-op2`, a new build directory; never into
    another workstream's), after commit 2, with `CB_STAMP=1` so `carbon
    version` names commit 2's sha (OP-1's two-build deviation is avoided by
    building from a clean tree).
2.  **Autoupdate to a fixpoint** (R26): `carbonbuild/autoupdate.sh
    /home/user/carbon-op2`, then again; the second run changes nothing (M-11:
    the refills converge on the first run, M-12: the new goldens by the second).
    Commit 3 is the result.
3.  **Gate**: `carbonbuild/gate.sh /home/user/carbon-op2` passes PR 56's count
    plus the five new goldens: 1945 + 5 = 1950 passed, 0 failed.
4.  **Conformance**: `carbonbuild/conformance.sh /home/user/carbon-op2 <out>`
    reports 138 / 0 / 22 over 160, 48/56, with exactly the six status
    differences of §5 against PR 56's scoreboard; `runner.py --self-test`
    prints `self-test: 160 programs parsed, 56 bullets in table, OK`.
5.  **Mutants** (each in its own install copy, the result recorded in the
    landed notes): m1, m2 and m4 of M-14 against optional_destroys_value and
    optional_destroy_diff (m1: RUN-FAIL -11; m2 and m4: OUTPUT-MISMATCH in
    both); the toolchain without §2.2's custom_witness.cpp hunks
    (optional_destroys_value OUTPUT-MISMATCH, M-5); without its handle.cpp hunk
    (optional_bool COMPILE-FAIL, M-1); `Get` without the check
    (optional_get_empty_fail_stop and optional_pointer_get_empty_fail_stop
    RUN-FAIL, M-14).
6.  **prek** to a fixpoint per commit and `--all-files` before hand-over, with
    R31's counts (§3); clang-format 21.1.8 on §2.2's files (R18; measured
    clean) and on the oracle.
7.  **Not run, said so in the PR body and the landed notes:** Bazel and its
    unit, lit and fuzz tests; clangd-tidy; macOS, Windows and an opt-mode
    toolchain; LLVM-side assertions (the CMake LLVM is a Release build); the
    hosted conformance run (Actions disabled).
8.  **The merge of trunk** (after PR 56 merges): rebuild, refill (any golden
    change in a new "Autoupdate testdata goldens on the container arbiter"
    commit), gate (the merged base's count plus five), conformance, mutants;
    the records quote that run (R9).

## Hand-off notes for the implementer

-   Apply §2.1 and §2.2 with `git apply` from this file's fenced blocks; do not
    retype them. The prelude block is prototype t3 byte for byte.
-   Build once from a clean tree after commit 2 (§8.1); the autoupdate of a
    stale build reproduces nothing.
-   The five new goldens' first fill may need a second run for `.loc`
    renumbering (M-12); a structural change on the second run is a stop (R26).
-   Run the six Optional programs and the mutants on the built toolchain before
    commit 4; the EXPECT values are §1.5's and the headers', never the run's
    (R16(d)).
-   Commit 4 moves the gap row; if the implementation review finds an
    operation of `Core.Optional` failing through its API, the row goes back to
    PARTIAL in a fix commit (D-OP2-12's break condition).
-   Re-scan the ledger before commit 5 and re-read convert.cpp's CHECK line and
    SC-1's offsets at the merge of trunk (§0.3 item 1).
-   Both toolchain fixes are upstream defects (M-3, M-5): the landed notes list
    them for an upstream report, with M-2's probes as reproducers.
