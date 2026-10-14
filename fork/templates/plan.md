# Integrated templates plan: crashes, dependent forms, splice lowering (TP-1)

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

**Status:** rev 1, 2026-10-14 -- the planner's draft, not yet reviewed. Two
plan reviews are owed under R29(c) (review A: architecture and design fidelity;
review B: concreteness, process and cross-workstream), then a separate fixer
(R11). Branch `claude/carbon-fork-0-1-tp`, worktree `/home/user/carbon-tp`, cut
from trunk b2576f6c3, whose `toolchain/` and `core/` trees equal the upstream
cut as built into the fork toolchain 0bdce60a5 (upstream base c1e83b0b7; trunk
differs from 0bdce60a5 by fork records only). Every line number below is
against b2576f6c3 unless a branch or commit is named. Nothing below is
implemented on this branch at rev 1; the prototype that §2 quotes exists only
as a patch in the planner's scratch directory (`$P` below), measured by
relinking the trunk build's objects with the patched translation units.

**Scratch and measurement environment.** `$P` is
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/tp1/planner`.
The baseline of every measurement is the trunk toolchain
`/home/user/carbon-build/carbon-trunk/install/bin/carbon` (`carbon version`
`0.0.0-0.dev+0bdce60a5`) and its `file_test` with the trunk runfiles; the
differential oracle is the upstream nightly
`/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon`
(`0.0.0-0.nightly.2026.10.12+62f1cc6`). Prototypes were compiled with the trunk
build's own compile line (the `cxx`/`cflags` of
`/home/user/carbon-build/carbon-trunk/build.ninja`) for the patched translation
units only, linked into `carbon-busybox` and `file_test` under
`/dev/shm/tp1-planner/<variant>/` (script `$P/bin/relink.sh`), and deleted when
no longer needed. Where a prototype changed a header, every translation unit
that uses the changed declaration was recompiled with the patched header first
on the include path (variants v2 and later: `sem_ir/expr_info.h`; v3 and v10:
`sem_ir/typed_insts.h`, an approximation that §0.8 discloses); a change to an
X-macro list (`sem_ir/inst_kind.def`, `diagnostics/kind.def`) was not relinked
and is hand-predicted in §2 with the code path quoted. No full toolchain was
built, nothing under `/home/user/carbon-build` was written, no other worktree
was touched (read-only `git show` and `git diff` only), and the owner's runner
was not used (R28). Probe sources are under `$P/probes`, `$P/runs`, `$P/sweep`,
`$P/iso`, `$P/forms`, `$P/xlib` and `$P/progs`; their compiler logs are under
`$P/out/<toolchain>/`.

**Items.** W-014, "W7: integrated templates -- template lowering (SpliceInst)
plus dependent-form conversions, operators, and pattern splices"
(fork/inventory/work-items.json; kind todo-stub, size L), with the three
DD-1 residues filed under the same gap row on PR 58 (W-183 constraint lookup,
W-192 struct copy and array index, W-193 deduction through a class's
arguments) and UA-2's W-127 (an uninitialized `var y: T;`, filed on PR 51),
which the measured defect list of DD-1 cites as X20 and X23. **Milestone row:**
"Generics: Integrated templates" (fork/gap-analysis.md:54 on trunk, :59 or :60
on the held branches; records name it by its bullet text, R7), PARTIAL.
**Arbiter of record** (W-014's notes): every `fail_todo` split under
toolchain/check/testdata/generic/template/ flips, the lowering fatal is gone,
and a template function executes in the run harness.

**Outcome this plan commits to.** (a) Every compiler crash and the miscompile
on template-dependent forms that DD-1 pinned (X28 to X33, probe PR-AK), and
the ones this plan's sweep found (§0.6), become correct implementations,
each with its root cause fixed where it arises (§0.3, §1.2), except two
forms that are outside templates proper and become precise `semantics TODO`
diagnostics with goldens and W-ids (cross-library templates, template form
parameters; §1.8). (b) The dependent forms of proposal 2200's "Use of
dependent value is dependent" that trunk rejects where the function is defined
-- `*`, `->`, `&`, tuple element access, calls of a value whose type is a
template parameter, struct copies and array indexing -- are deferred to
instantiation through the existing action machinery (§1.3). (c) SpliceInst
lowering, which upstream PR 7727 landed before the cut, is completed for
the cases it mishandles (a splice of an in-place initializer, categories and
constants read in the generic instead of the specific; §1.4). (d) Proposal
2200's name lookup into a constrained template parameter (W-183, with the
different-entities error) and deduction through a class's arguments (W-193)
are implemented, each with its root cause found and its cost measured on a
relinked prototype (§1.5, §1.6), and W-127's deferred impl lookup with them
(§1.7). (e) Three of the four `fail_todo` splits under generic/template/ flip;
the fourth (`member_out_of_line.carbon` `fail_todo_basic`) is a different
defect, measured and filed (W-254, §1.13), so W-014's arbiter is not met in
full and the row stays PARTIAL (D-TP-18). (f) Eight conformance programs, one
with a C++ differential oracle, join the bullet. (g) The land-time
integration with PR 58 amends templates.md's limits list with dated notes,
flips DD-1's fixtures, and amends W-183, W-192 and W-193 with texts this plan
specifies (§2.9). (h) The work lands as five implementation commits, each
with its fill commit, a programs commit, a row commit, a discharge commit and
the land-time integration commit, with a fix-commit budget and a shrink line
(§3).

**Id allocation (recorded so no workstream collides).** Re-scanned for this
plan on 2026-10-14 over the 79 refs `refs/heads/claude/carbon-fork-0-1-*`,
`refs/remotes/origin/claude/carbon-fork-0-1-*`, `refs/heads/trunk` and
`refs/remotes/origin/trunk` of /home/user/carbon-lang with

<!-- google-doc-style-ignore -->

```sh
cd /home/user/carbon-lang
refs=$(git for-each-ref --format='%(refname)' \
  'refs/heads/claude/carbon-fork-0-1-*' \
  'refs/remotes/origin/claude/carbon-fork-0-1-*' \
  refs/heads/trunk refs/remotes/origin/trunk)
for r in $refs; do git grep -hoE 'W-[0-9]{3}' $r -- fork; done | sort -u | tail -3
for r in $refs; do git grep -lE 'W-(25[0-9]|26[0-9])\b' $r -- fork; done
for r in $refs; do git grep -hE 'F-019' $r -- fork docs; done | sort -u
```

<!-- google-doc-style-resume -->

The maximum named on any ref is W-249 (OX-1's parked block W-245..W-249);
no ref names any of W-250..W-269 or F-019. **TP-1 reserves W-250..W-269**
(twenty ids); §1.13 files W-250 to W-258, the rest stay spare, and an unused
reserved id stays unused and is never reused. **No fork design id is minted**
(D-TP-17): F-019 stays unallocated unless a review shows that the slice
decides a rule proposal 2200 leaves open, in which case F-019 is minted with
a dated amendment to docs/design/templates.md. F-017 and F-018 stay with OX-1
and VA-1. The ids appear only in records written by the discharge commit D
and in this plan; no source file, golden or program header names one.
Immediately before D writes the ledger, the three commands are re-run; if
any of W-250..W-269 or F-019 is taken by then, the residues re-allocate from
the maximum plus one, skipping every reserved block, and the landed notes
say so. D records the reservation's outcome in fork/ORCHESTRATION.md.

**Design authority** (each cited where used):

-   proposals/p002200-template-generics.md (accepted): "Proposal" :184-229
    (the three differences from checked generics: lookup in the type and the
    constraints, validity by value, impl lookup delayed), "Name lookup"
    :433-505, "Template dependent" :712-738, "Simple member access" :739-768,
    "Compound member access" :769-831, "Impl lookup" :832-863, "Use of
    dependent value is dependent" :864-902.
-   proposals/p002138-checked-and-template-generic-terminology.md
    (terminology), question-for-leads issue 949 and proposal 989 (name
    lookup, cited by p002200:433-441).
-   proposals/p002875-functions-function-types-and-function-calls.md (each
    function has its own type; cited by D-TP-10).
-   proposals/p003763-matching-redeclarations.md :48-215 (token-by-token
    matching of redeclarations; cited by W-254).
-   toolchain/check/type_completion.h:30-45 ("the code that creates an inst
    is responsible for enforcing any type completeness requirements"; cited
    by D-TP-8).
-   docs/design/templates.md as PR 58 rewrote it (head fcee90d9b on
    `claude/carbon-fork-0-1-dd`): "Templates in the 0.1 toolchain" and its
    five groups of limits, with fixtures X13..X33 and R08/R09 under
    fork/designdocs/samples/ and the checker fork/designdocs/check_samples.py.

V-3: no accepted proposal or leads' direction is contradicted. Every rule the
slice implements is proposal 2200's (or p2875's for D-TP-10); where the
toolchain cannot yet do what the design says (templates across libraries,
template form parameters, out-of-line redeclarations with dependent types,
`partial T*`, `match` on a dependent value, arrays with a dependent bound),
the slice diagnoses or leaves the existing diagnostic and files the gap; it
never gives a form a different meaning.

## §0 Audit: measurements with file:line evidence

### §0.1 W-014, the row and the bullet's programs today

W-014's evidence list on trunk is stale. It cites
`lower/handle.cpp:359-364` ("Template lowering not implemented yet"); that
fatal is gone since upstream PR 7727 (in the cut): `HandleInst(SpliceInst)` at
lower/handle.cpp:494-515 lowers a same-file splice by lowering the
instruction the splice resolves to in the specific, and the only template
fatal left in lowering is "Cross-file template lowering not implemented yet"
(:513). UA-2 (PR 51) already re-cited W-014 accordingly on its branch and
un-SKIPped generics/templates_dependent_member.carbon; this plan takes PR 51's
text as the base (TP-1 lands after PR 51, §1.12). Measured here: the
dependent-member program with its `SKIP:` line removed runs on trunk and
prints `42` (`$P/out/misc/tdm.*`), so the trunk program's SKIP reason
(`FATAL failure at toolchain/lower/handle.cpp:363`) is stale on trunk and is
PR 51's to retire.

The row's trunk text ("operators/conversions on dependent values are
fail_todo, lowering hits CARBON_FATAL ... (lower/handle.cpp:363), and
templates.md is a self-described skeletal placeholder") is stale in two of its
three clauses; PR 51 and PR 58 each rewrite it on their branches (§0.9).

The bullet's programs on trunk (fork/conformance/README.md:291-293):
templates_type_param (run, PASS), templates_value_param (run, PASS),
templates_dependent_member (SKIP, stale). Both PASS programs call template
functions and print from them, so the arbiter's third clause ("a template
function executes in the run harness") is already met on trunk; the second
("the lower fatal is gone") is met for same-file templates since PR 7727 and
by this plan's D-TP-14 for the cross-file case (the import is diagnosed before
lowering can reach :513). The first clause ("all generic/template fail_todo
tests flip") is the one that measures this slice: §0.2 lists the four splits.

### §0.2 The defect list, measured

Every DD-1 fixture was compiled (and linked and run when it defines `Run`)
with the trunk toolchain and the nightly by `$P/bin/probe.sh`, from
`/home/user/carbon-dd/fork/designdocs/samples/`; the last column is the
relinked prototype v8 (§0.8), the state this plan specifies. Outcomes:
ERROR is the first error line, CRASH the crash report's first line, RUN the
printed values.

| Fixture | Form | Trunk | Nightly 2026.10.12 | Prototype v8 |
| --- | --- | --- | --- | --- |
| X13 | `*p`, `p: T` | ERROR ``cannot dereference operand of non-pointer type `T` `` | same | same (C3 is not relinkable; predicted to compile, §2.3) |
| X14 | `x.p->n` | ERROR ``cannot apply `->` operator to non-pointer type `<dependent type>` `` | same | same (predicted to compile) |
| X15 | `&x.n`, `ref x: T` | ERROR `cannot take the address of non-reference expression` | same | same (predicted to compile) |
| X16 | `p.1`, `p: T` | ERROR ``type `T` does not support tuple indexing; only tuples can be indexed that way`` | same | same (predicted to compile) |
| X17 | `h(x)`, `h: G` | ERROR ``unable to monomorphize specific `Apply(<type of Twice>)` `` | same | COMPILES; as a program RUN `8` |
| X18 | `return p;` on a struct | ERROR ``unable to monomorphize specific `Id({.x: i32, .y: i32})` `` | same | COMPILES; RUN `5` |
| X19 | `a[1]` on an array | ERROR ``unable to monomorphize specific `Second(array(i32, 3))` `` | same | same (predicted to compile) |
| X20 | `var y: T;` | ERROR ``cannot convert type `T` into type implementing `Core.DefaultOrUnformed` `` | same | COMPILES; RUN `5` |
| X21 | `x.F()` in type and constraint | RUN `21` | RUN `21` | ERROR ``unable to monomorphize specific `G(C as A)` `` (proposal 2200's error) |
| X22 | the operators that resolve per instantiation | RUN `-4 17 14 1 3` | same | same |
| X23 | `var y: T;` in a class method | ERROR (as X20) | same | COMPILES; RUN `6` |
| X24 | `self.item[0]` in a class | ERROR ``unable to monomorphize specific `First(array(i32, 2))` `` | same | same (predicted to compile) |
| X25 | `[template T](h: Holder(T))` | ERROR ``cannot deduce value for generic parameter `T` `` | same | COMPILES; RUN `42` |
| X26 | `partial T*` | ERROR `` `partial` applied to final type `T` `` | same | same (OUT, W-251) |
| X28 | `for (x: i32 in a)`, `a: T` | CRASH `CHECK failure at toolchain/sem_ir/inst.h:249` (Checking ForHeader) | CRASH (same check) | COMPILES; RUN `6` |
| X29 | `-> (T, T)` | CRASH segfault in `PendingBlock::InsertHere` | same | COMPILES; RUN `8` |
| X30 | `-> {.a: T, .b: T}` | CRASH (as X29) | same | COMPILES; RUN `10` |
| X31 | `-> array(T, 2)` | CRASH (as X29) | COMPILES (RUN `8`) | COMPILES; RUN `8` |
| X32 | `H(template T).Both() -> (T, T)` | CRASH `CHECK failure at toolchain/lower/function_context.cpp:223` | CRASH (:201) | COMPILES; RUN `6` |
| X33 | `let (a, b) = p`, `p: T` | CRASH `FATAL failure at toolchain/lower/aggregate.cpp:67` | same | COMPILES; RUN `9` |
| PR-AK | `Id[template T](p: T) -> T` on `(4, 5)` | RUN, prints values that change per run (`90355496 0`, then `-1932202456 3`) | same kind | RUN `4 5` |
| R08 | missing member | ERROR (as the page says) | same | same |
| R09 | constraint-only member | ERROR ``unable to monomorphize specific `Report(Square as HasArea)` `` | same | COMPILES; RUN `25` |
| X05 | structural `Circle` | ERROR ``cannot convert type `Circle` into type implementing `HasArea` `` | same | same (the design's rule) |
| X10 | `match` on a dependent value | ERROR `semantics TODO: match on unsupported scrutinee type` | other TODO | same (OUT, W-252) |
| X11 | `array(i32, N)` from a list | ERROR | COMPILES | same (OUT, W-253) |

PR-AK was reconstructed from fork/designdocs/plan.md on the dd branch,
§4.3 "PR-AK" (`g01_tuple_template_let.carbon`, copied to
`$P/probes/prak_g01.carbon`); X28 to X33, X17, X18, X20, X23, X25 and R09
as programs are `$P/runs/r28_for.carbon`, `r29_dup`, `r30_mk`, `r31_two`,
`r32_both`, `r33_destr`, `r17_apply`, `r18_structcopy`, `r20_uninit`,
`r23_class_uninit`, `r25_deduce` and `r09_constraint`, each the fixture's body
with a `Run` that prints the value the fixture's header derives.

### §0.3 Crash and miscompile root causes

Each stack below is from the trunk toolchain's crash report
(`$P/out/trunk/<fixture>.compile.log`); each root cause was confirmed by the
prototype that removes it (§0.8).

**RC-1 (X29, X30, X31, and the sweep's s22 and s30): a template-dependent
initializer loses its storage.** Stack: `PendingBlock::InsertHere` <-
`CategoryConverter::DoStep` <- `CategoryConverter::Convert` <-
`PerformAction(ConvertToCategoryAction)` <- `TryEvalTypedInst` <-
`TryEvalBlockForSpecific` <- `ResolveSpecificDefinition` <-
`CheckUnit::CheckRequiredDefinitions`. In `return (x, x);` with `x: T`, the
tuple literal is converted element by element (`ConvertTupleToTuple`,
convert.cpp:524-597) into `tuple_access %return, elementN` storage. Each
element `x` has the target's type `T`, so `AddConvertActionIfDependent`
returns at its same-type early exit (convert.cpp:2317-2320) and the category
conversion runs: `x` is a value, the target an in-place initializer, so
`PerformCopy` (:1992-2002) builds `Core.Copy` dispatch on the template type --
a dependent splice -- and `DoStep`'s `Dependent` case (:2174-2181) wraps it in
`ConvertToCategoryAction{conversion_kind = InPlaceInitializing}`. That action
records only the kind. On instantiation `PerformAction(ConvertToCategoryAction)`
(:2453-2460) rebuilds a `ConversionTarget` with neither `storage_id` nor
`storage_access_block`, the copy for `i32` is a by-copy initializer that is
not in place, and :2198 calls `target_.storage_access_block->InsertHere()` on
the null pointer. X31's array form takes the same path through
`ConvertTupleToArray` (:440-503). The nightly runs X31 because upstream
947c1eb52 made `array` the class `Core.Array` (§0.7): its dump shows a single
`initialize_action %.loc16_15, %.loc15_45.5, %return.param` for the whole
conversion, which carries the storage, instead of per-element copies.

**RC-2 (PR-AK, and the sweep's s11 and s15): the same lost storage, silent.**
For `return p;` with `p: T` and `T = (i32, i32)`, the definition holds
`convert_to_category_action %.loc2_45.4, element10` (kind `Initializing`) over
the dependent `Copy` call. On instantiation the copy call initializes its own
temporary, and with no target storage `OverwriteTemporaryStorageArg` has
nothing to redirect it to, while `return` lowers the result as an in-place
initializer of `%return`. The lowered function (trunk,
`--dump-llvm-ir`) shows it:

<!-- google-doc-style-ignore -->

```llvm
define linkonce_odr void @_CId.Main.00f31208999b670d(ptr sret({ i32, i32 }) %return, ptr %p) {
entry:
  %.0d2.temp = alloca { i32, i32 }, align 4
  call void @"_COp.4e4edddc7580c79b:Copy.Core.8608f3c6f62d80cb"(ptr %.0d2.temp, ptr %p)
  ret void
}
```

<!-- google-doc-style-resume -->

`%return` is never written, so the caller reads uninitialized stack: the
values that change from run to run.

**RC-3 (X28, at the definition): a splice is read as if instantiated.** Stack:
`ConstantValueStore::GetInstAs<InstValue>` <- `FindStorageArgForInitializer`
<- `Check::Initialize` <- `HandleParseNode(ForHeader)`. The `for` header
creates the cursor variable and calls `Initialize` (handle_loop_statement.cpp:
228-240) with the cursor from the dependent `Iterate.NewCursor` call; the
conversion is a `ConvertToCategoryAction` splice (RC-1's path), and
`Initialize` (convert.cpp:2738-2766) then asks `FindStorageArgForInitializer`
for its storage argument. Its `SpliceInst` arm (sem_ir/expr_info.cpp:307-317)
calls `GetInstAs<InstValue>` on the splice's constant, which in the
definition is the unevaluated action, not an `InstValue`:
`CHECK failure at toolchain/sem_ir/inst.h:249: Is<TypedInst>(): Casting inst
{kind: ConvertToCategoryAction, ...} to wrong kind InstValue`. Every
template `for` loop over a dependent range hits this where the function is
defined, called or not (X28 has no call).

**RC-4 (X28 with a call over an array, found by the prototype): a pointer type
formed for a dependent type is never completed.** With RC-1 and RC-3 fixed,
`Sum(a)` on an `array(i32, 3)` and the same loop over a member array crash in
lowering: a segfault in `llvm::Argument::addAttr` <-
`FileContext::GetOrCreateLLVMFunction` <- `HandleInst(Call)`. Instrumenting
the prototype (variant `dbg`, `TP1DBG` lines) showed the lowered callee is
the array impl's `Next` with `params=0 sret=1`, because
`FunctionTypeInfoBuilder::TryHandleParameter` (lower/type.cpp:434-520) found
the parameter `cursor: i32*` with an `Unknown` value representation (:493)
and built an inexact function type; `GetOrCreateLLVMFunction`
(lower/file_context.cpp:438-441) then adds the return-slot attribute to the
first argument of a function that has none. The cursor's address is formed at
handle_loop_statement.cpp:254-259 as `AddrOf` of type
`GetPointerType(<dependent cursor type>)`; for a symbolic pointee nothing
requires the pointer type complete, so the specific's `i32*` never gets
complete-type information. The same call written out in a template
(`a.(Core.Iterate.Next)(&c)` with `var c: i32`, `$P/iso/i7_next_op.carbon`)
lowers with three parameters, because `&c` forms `i32*` concretely.
type_completion.h:41-42 puts the obligation on the code that forms the
instruction. Upstream bf91a8b4d (canonical self in `ImplSelfWitness`) was
measured not to change this (variant v3).

**RC-5 (X32): a deferred initialization refers to storage that was never
emitted, then a splice demands a value from an in-place initializer.** The
class method's `return (self.a, self.a);` converts each element through the
`InitializeAction` path of `AddConvertActionIfDependent` (:2335-2391), whose
`storage_id` is the element's `tuple_access %return` -- an instruction still
in the pending storage access block, never inserted (the dump prints it as
`<unexpected>.inst5900007A`). Lowering reaches it through a `SpecificInst`
and fails `CHECK failure at toolchain/lower/function_context.cpp:223:
const_id.is_concrete()`. Upstream 4a8993af2 fixes this first defect by moving
the block into the action; the nightly then fails the second:
`HandleInst(SpliceInst)` (lower/handle.cpp:494-506) calls
`GetValue(inst_value.inst_id)` with a value required, and the spliced
instruction is an `InPlaceInit`, which lowers its initialization and has no
value (nightly: `CHECK failure at toolchain/lower/function_context.cpp:201 ...
{kind: InPlaceInit, ...}`). `HandleInst(SpecificInst)` (:470-485) already
uses `require_value=false` for exactly this reason; the splice handlers do
not.

**RC-6 (X33, and the sweep's s34): lowering asks the generic for a category,
and a value binding of a dependent value is dependent.** First,
`GetAggregateElement` (lower/aggregate.cpp:51-67) computes the aggregate's
category with `SemIR::GetExprCategory(context.sem_ir(), aggr_inst_id)`, without
the specific, so the `splice_inst` of the `convert_action` that destructures
`p` has category `Dependent` and :65-67 is fatal: `Unexpected expression
category for aggregate access into {kind: SpliceInst, ...}`. `ReturnExpr`
(lower/handle.cpp:378-381) already passes the specific; `Assign` (:103-110),
`Temporary`, `ValueAsRef` and `ValueOfInitializer`
(lower/handle_expr_category.cpp:61, :77, :87) do not. Second, with that fixed
(variant v1), `a + b` crashes with `GetValue` of a `SpliceInst` whose value in
the specific is symbolic: the binding `a` is bound to a
`convert_to_category_action(..., Value)` splice, the action kind's category is
`Dependent` (sem_ir/typed_insts.h:612-625), so `a.ref` is `Dependent` too, and
on instantiation `PerformAction` on the operand `a.ref` (not wrapped in a
`SpecificInst`, because its type is concrete and its value is runtime) sees
`Dependent` again and creates a new template action that nothing evaluates
(the v1 dump shows `splice_inst <unexpected>.inst59000673` as the value of
`%.loc4_10.2` in the specific).

**RC-7 (X29 to X32 in lowering, after RC-1): `EmitAggregateInitializer`
decides constness in the generic.** With RC-1 fixed (v1), the tuple's
`tuple_init` crashes at `ValueStore::Get(inst<none>)` <-
`GetTypeOfInstInSpecific` <- `EmitAggregateInitializer`: its in-place loop
(lower/aggregate.cpp:227-235) treats an element whose generic constant is
symbolic (`is_constant()` is true for a template splice) as a constant field
and asks `FindStorageArgForInitializer` for its storage, which (with RC-3's
fix) is `None`. `LowerInst` skips constants with `FunctionContext::IsConstant`
(function_context.cpp:184-188), which reads the specific;
lower/handle.cpp:86-92 (`ArrayInit`, a fork addition from SL-2) has the same
generic read.

**RC-8 (a template used from another library; DD-1's probe PR-A).**
`$P/xlib/lib.carbon` defines `GetN[template T: type]`; `main.carbon` imports
it and calls it. Trunk: `FATAL failure at toolchain/check/import_ref.cpp:5087:
Missing case in TryResolveInstCanonical for instruction kind SpliceInst` while
checking the name `GetN` (nightly: the same at :4875). `TryFinishGeneric`
(import_ref.cpp:1162-1193) imports the generic's definition eval block, which
for a template holds actions and splices, and `TryResolveInstCanonical`
(:4833-5088) has no case for them. Importing them would need a representation
of an imported template's instantiation, which neither check nor lowering has
(lower/handle.cpp:507-513 says so for lowering).

**RC-9 (a template form parameter, found by the sweep).**
`fn F(template Fm: Core.Form, unused x:? Fm) {}` with
`import Core library "prelude/types/form";` (`$P/forms/f3_template_form.carbon`)
compiles on trunk and crashes lowering `F`'s specific: `FATAL failure at
toolchain/lower/type.cpp:514: Unexpected inst kind: {kind: SpliceInst, ...}`,
because `TryHandleParameter` (:434-446) reads the parameter pattern's generic
constant, the splice of a `FormParamPatternAction` (created at
handle_binding_pattern.cpp:470-490). Resolving it in the specific (measured,
variant v9, not kept) yields a `VarPattern` the parameter switch does not
expect either. `Core.Form` is not exported by the prelude (core/prelude does
not import `prelude/types/form`); W-014's "pattern splices" (the
`CARBON_FATAL`s of pattern_match.cpp:2174-2180 for thunk, local and match-case
matching) belong to the same form-parameter feature: local and match-case form
bindings are diagnosed before reaching them (`$P/forms/f1_match.carbon`,
`f4_local.carbon`: `semantics TODO: form binding in match case pattern`,
`semantics TODO: support local form bindings`).

**RC-10 (not a template defect, found by the sweep).**
`fn F(x: (i32, i32)) -> {.a: (i32, i32)} { return {.a = x}; }` crashes the
trunk and the nightly while checking the `return` (`CHECK failure at
toolchain/check/convert.cpp:2199: new_storage_id.has_value()`;
`$P/probes/s32n.carbon`): the struct's initializing representation is by
copy, its single field's is in place, and the field is converted with an
in-place target that has no storage. The template form s32 reaches it on
instantiation. It is outside this slice (W-256).

### §0.4 Rejected dependent forms: which check resolves too early

| Form | Where it is resolved | Why too early | Action kind today |
| --- | --- | --- | --- |
| `*e` (X13) | `PerformPointerDereference`, check/pointer_dereference.cpp:16-37, from handle_operator.cpp:378-400 | it reads `e`'s type at the definition; a template parameter `T` is not a `PointerType`, so `DerefOfNonPointer` | none |
| `e->m` (X14) | the same function from handle_name.cpp:47-90 | the same, with `ArrowOperatorOfNonPointer` | none |
| `&e` (X15) | handle_operator.cpp:270-294 | it requires a durable reference; a member of a dependent operand is a splice whose category is `Dependent` | none |
| `e.N` (X16) | `PerformTupleAccess`, member_access.cpp:892-905, from handle_name.cpp:30-36 | it requires a `TupleType` at the definition | none |
| `h(x)`, `h: G` (X17) | the call is deferred correctly (`CallAction`, call.cpp:871-891) | on instantiation `GetCallee` (sem_ir/function.cpp:73-76) identifies a function only from the callee's constant value, and a parameter has none; a function's type alone names the function (p2875) | `CallAction` (exists) |
| struct copy (X18, W-192) | `CategoryConverter::DoStep` `Value` case, convert.cpp:2266-2275, calls `PerformCopy` (:1992-2002) | it commits to `Core.Copy` for the dependent type at the definition; a concrete struct (and tuple) is copied by the builtin aggregate conversion (`ConvertStructToStruct`, measured in `$P/probes/structcopy.carbon`: `struct_access` and `in_place_init` per field), and struct types implement no `Core.Copy` | `ConvertToCategoryAction` (wrong storage, RC-1) |
| `a[i]` (X19, X24, W-192) | `HandleParseNode(IndexExpr)`, handle_index.cpp:157-215 | it switches on the operand's type at the definition; `T` takes the `IndexWith` branch, and arrays are indexed by the builtin `ArrayIndex` with no `IndexWith` impl | `CompoundMemberAccessAction` + `CallAction` (wrong branch) |
| `var y: T;` (X20, X23, W-127) | `MakeDefaultInit`, handle_let_and_var.cpp:278-305, converts `T` to `Core.DefaultOrUnformed`; `LookupImplWitness`, impl_lookup.cpp:1080-1087 | a symbolic query keeps its deferred witness only if `FindNonFinalWitness` finds an impl that may apply; the prelude's `impl forall [T: UnformedInit]` and `final impl forall [T: Default]` cannot be shown to apply to an unconstrained template `T`, while p002200:198-199 delays impl lookup for templates | none needed (the witness is already deferrable) |
| `x.F()` with `T:! I` (X21, R09, W-183) | `PerformMemberAccess`, member_access.cpp:503-523, defers the whole access; `PerformAction(AccessMemberAction)`, :700-704 | on instantiation the name is looked up in the argument's type only (its own TODO at :506-509 says so) | `AccessMemberAction` (exists) |
| `Holder(T)` (X25, W-193) | `IsCallPerformable`, call.cpp:820-833 | any argument with a template-dependent value defers the call, so the parameter type is `splice(convert_to_value_action(splice(call_action(Holder, T))))` instead of `class_type @Holder, @Holder(%T)`, and deduction (deduce.cpp:399-465) cannot see through a splice | `CallAction` (too eager to defer) |
| `partial T*` (X26) | handle_operator.cpp:342-361 | the eager `PartialOnFinal` check | none (OUT, W-251) |
| `match (x)` (X10) | handle_match.cpp | unsupported scrutinee type | none (OUT, W-252) |

### §0.5 The deferred-action machinery, read

The machinery is in check/action.{h,cpp} and check/eval.cpp; there is no
design document for it (docs/design/generics/ describes the language, not
SemIR). A template-dependent operation is represented in the definition by an
action instruction (`constant_kind` `InstAction` or `MultiInstAction`,
sem_ir/typed_insts.h) placed in the generic's eval block by
`AddDependentActionInst` (action.cpp:315-319), and by a `SpliceInst` in the
function body that stands for the action's result (`AddSpliceInst`,
action.cpp:236-246; `AddDependentActionSplice`, :321-329). `HandleAction`
(action.h) performs the action at once when `ActionIsPerformable`
(action.cpp:202-234: no operand is template-dependent) and otherwise defers
it. On instantiation `TryEvalBlockForSpecific` evaluates the eval block;
`TryEvalTypedInst` (eval.cpp:3150-3186) calls `PerformDelayedAction`, which
refines the operands into the specific (`RefineOperandsInSpecific`,
action.cpp:461-470: an operand with a symbolic type or value becomes a
`SpecificInst`), performs the action in a fresh instruction block and wraps a
multi-instruction result in a `SpliceBlock` (:478-512); the action's constant
becomes an `InstValue` of the result. Lowering a specific lowers a
`SpliceInst` by lowering that result (lower/handle.cpp:494-506).

Action kinds at b2576f6c3 (sem_ir/inst_kind.def): `AccessMemberAction`,
`AccessOptionalMemberAction`, `CallAction`, `CalleePatternMatchAction`,
`CallerPatternMatchAction`, `CompoundMemberAccessAction`, `ConvertAction`,
`ConvertToCategoryAction`, `ConvertToValueAction`, `FormParamPatternAction`,
`InitializeAction` (the only `MultiInstAction`) and
`OutFormParamPatternAction`. Upstream (66a250ad9) has the same twelve.

Per dependent form: member access, compound member access, calls,
conversions and the operators that dispatch through an interface (X22) have
actions and work; copies and initializations have actions that lose their
storage (RC-1, RC-2); dereference, address-of, tuple element access and
indexing have none (§0.4).

### §0.6 Systematic sweep

Thirty-five one-concept programs (`$P/sweep/s01..s35`), five isolation
programs (`$P/iso/i1..i9`), four form programs (`$P/forms/f1..f4`) and the
cross-library pair (`$P/xlib`) were run on trunk and the nightly. Beyond
DD-1's list they found: two more miscompiles of RC-2's kind (s11, a template
calling a template on a tuple; s15, `*p` for `p: T*` with a tuple `T`), three
more crashes of RC-1's kind (s22 `fn F(template N: i32) -> (i32, i32)`, s30
`returned var r: (T, T)`, s32), one of RC-6's (s34, destructuring a member
tuple), RC-4 (a `for` loop over a dependent array, reachable only once RC-3 is
fixed), RC-9 (template form parameters) and RC-10 (non-template). Every other
probe runs with the hand-derived value on trunk, the nightly and v8: dependent
`if` and `while` conditions, struct literals, `as`, assignment, discarded
expressions, method calls returning tuples, generic classes of `T`, calls of
templates from templates on scalars, and the value parameters of templates.
The nightly differs from trunk on two probes only, s29 (`array(T, 2)`
deduction fails on the nightly) and s31 (`var a: array(i32, N);`), both the
`Core.Array` change.

### §0.7 Upstream since the cut

Fifty upstream commits lie between the cut and upstream/trunk 66a250ad9
(`git -C /home/user/carbon-lang log 0bdce60a5..upstream/trunk`), thirty-seven
of them under toolchain/check, toolchain/lower or toolchain/sem_ir; the
nightly is 62f1cc6a3, thirty-six commits past c1e83b0b7. The ones that touch
the template machinery or the forms above, with `git merge-tree` against
b2576f6c3:

| Commit | Subject | Relevance | Merge onto trunk |
| --- | --- | --- | --- |
| 947c1eb52 | Add a `Core.Array` class type, and make `array` refer to it | the reason X31 runs on the nightly: the tuple-to-array conversion becomes one `InitializeAction` with storage (nightly dump of X31, §0.3 RC-1); X29 and X30 still crash on the nightly, so it is not a template fix | not attempted: 131 files, +8912/-8143, a language-level change with a prelude rewrite |
| 4a8993af2 | Fix "<unexpected>" inst when creating an InitializeAction | fixes RC-5's first half by moving the storage access block into the action (`InitializeAction::Target` gains `storage_access_block_id`, sem_ir/typed_insts.h) | one conflict, in a golden (array/init_dependent_bound.carbon); measured as variant v10 (§0.8): with this slice's RC-1 fix it CHECK-fails every template `for` loop at `pending_block.h:89: cleanups_.empty()` (the cursor's `VarStorage` carries a cleanup) |
| bf91a8b4d | Canonicalize the self in ImplSelfWitness | measured as variant v3: no effect on RC-4 | clean |
| 71af20740 | Disable global state that modifies eval while resolving a specific | `declaring_impl_decls` during `TryEvalBlockForSpecific`; no template form here depends on it | clean |
| 230227264, e588469fd, 9fd28f730, 559602b9e | return storage and `return expr;` for value forms; an `EmitAggregateInitializer` crash | non-template return-form work; 559602b9e is unrelated to RC-7 (it fixes value-form returns) | 230227264 and 9fd28f730 conflict in lower files |

Verdict (D-TP-16): no cherry-pick. VA-1 cherry-picked upstream's own start of
its feature; here no upstream commit implements any form of this slice, the
commit that makes X31 run on the nightly is a language-level side effect, and
4a8993af2 is measured to conflict with the storage-carrying fix the slice
needs (it would move the cursor's `VarStorage`, with its cleanup, into the
action). The slice keeps RC-5's fix in this fork's form (D-TP-3) and records
the reconciliation for the next upstream advance (W-258).

### §0.8 Prototypes and golden blast radius

Each variant was relinked from the trunk objects plus the patched translation
units, then run on the probes, the full file_test gate in test mode from this
worktree (1942 files; trunk passes 1942) and the conformance runner (trunk:
128 PASS / 0 FAIL / 22 SKIP over 150, 48 of 56 bullets):

| Variant | Adds | Probes | Gate | Conformance |
| --- | --- | --- | --- | --- |
| v1 | RC-1, RC-2, RC-3 check fixes (A1 to A4) and RC-5, RC-6 lowering fixes (B1, B2) | PR-AK `4 5`, X18 `5`, X28 without a call compiles; X29 to X33 move to lowering crashes | not run | not run |
| v2 | RC-7 (B3, B4) and RC-6's second half (A5) | X29 `8`, X30 `10`, X31 `8`, X32 `6`, X33 `9`, s11 `11`, s15 `2`, s22 `6`, s30 `4`, s34 `5` | 1940 of 1942: generic/template/convert.carbon and unimplemented.carbon change only `convert_to_category_action %x, element1` to `convert_to_value_action %x, <type>` (autoupdate in a scratch mirror: 6 and 12 changed CHECK lines) | 128/0/22 |
| v3 | v2 plus upstream bf91a8b4d (`sem_ir/typed_insts.h` and the six translation units that read `ImplSelfWitness`'s constant kind recompiled) | RC-4 unchanged | not run | not run |
| v4 | X17 and W-193 (call.cpp), RC-8 (import_ref.cpp) | X17 `8`; `Holder(T)` `42`, `Holder(T)*` `5`, `Vec(N)` `3`, a template class argument `9`; the cross-library pair reports `semantics TODO: Unsupported: using a template from another library` and `use of undefined generic function`, no crash | 1937 of 1942: also class/destroy_calls.carbon, generic/template/call.carbon (its `fail_todo` split now succeeds; the other split now fails for the right reason) and lower/testdata/template/class.carbon (one SSA name) | 128/0/22 |
| v5 | W-183 (member_access.cpp) | R09 `25`; with `extend impl` `25`; a type-only member beside a constraint member `72`; a field `9`; X21 rejected with the prototype's note | 1937 (no new change) | 128/0/22 |
| v6 | W-127, first form: accept the deferred witness for a template query | X20 `5`, X23 `6`; but the dump of interop/cpp/template/generic_call.carbon shows the `final impl forall [T: Default]` selected in the definition with a deferred `Default` witness -- an impl chosen before the argument is known | 1935 | not run |
| v7 | W-127 as specified: no impl is selected for a template query in the definition | X20 `5`, X23 `6`; tuple `var y: T;` rejected on instantiation exactly as `var y: (i32, i32);` is without a template | 1935: also facet/period_self.carbon (its `fail_todo` split's first error changes) and interop/cpp/template/generic_call.carbon | 128/0/22 |
| v8 | RC-4 (A6) | every `for` form runs: X28's array `6`, `Core.Range(c.n)` `6`, a member array `12`, `array(i32, N)` `6` | 1934: also interop/cpp/range_for.carbon (34 added CHECK lines: the cursor pointer's `require_complete_type` in checked-generic loops) | 128/0/22 |
| v10 | v8 with upstream 4a8993af2 in place of A4 | every template `for` loop: `CHECK failure at toolchain/check/pending_block.h:89: cleanups_.empty()` | not run | not run |

At v8, 52 of the 59 runnable probes run with their hand-derived values; the
other seven are correct rejections (X21; the tuple `var y: T;`), the two
tuple-index probes that need C3's actions (s03, s05), two probes with errors
of their own (s16, s35) and RC-10's s32. The v8 patch (`$P/tp1-proto-v8.diff`,
13 files, 550 lines with context) is the source of every `.cpp` block in §2.
C3's four action kinds were not relinkable (`sem_ir/inst_kind.def` is an
X-macro list included by most translation units) and are hand-predicted.

### §0.9 Collisions

Merge order of record (fork/ORCHESTRATION.md, 2026-10-14 14:00): PR 53, PR 51,
PR 52, SC-1, PR 54, PR 55, PR 56, PR 57, PR 58 through its state-L
integration commit, then PR 59. TP-1 lands after all of them (D-TP-19). The
v8 patch was dry-run (`patch --dry-run`) onto each branch's copy of the
thirteen files:

| Branch | Shared files with the patch | Dry run | Composition rule at TP-1's merge of trunk |
| --- | --- | --- | --- |
| SC-1 (`claude/carbon-fork-0-1-sc`, 395096d51; fill round 13 or later) | check/convert.cpp (+101 on SC-1), call.cpp (+14), member_access.cpp (+342), import_ref.cpp (+87), impl_lookup.cpp (+57); also typed_insts.h (+18), inst_kind.def (+1) and diagnostics/kind.def (+13), which C3 and C5 extend | one hunk fails: convert.cpp `PerformAction(ConvertAction)`, where SC-1 inserts `CheckConversionIsNotOfStructuralRequirement` before the target is built; every other hunk applies with offsets (member_access.cpp by 148 lines) | keep SC-1's structural check first in each `PerformAction` (ConvertAction, ConvertToCategoryAction, ConvertToValueAction and InitializeAction all carry it on SC-1), then A2's pending block; C5's constraint lookup (W-183) calls SC-1's `LookupMemberNameInTypeScopes` instead of trunk's `LookupMemberNameInScope`, so SC-1's structural-requirement mapping applies to the constraint result too; C3 and C5 append their `inst_kind.def` and `kind.def` lines after SC-1's |
| PR 51 (UA-2, f96fe8a7a) | no toolchain source; adds interop/cpp/template/dependent_var_full_prelude.carbon | applies | C4's W-127 fix makes its split `fail_todo_unformed_dependent_var` succeed: the land-time refill renames it (drops `fail_todo_`) and refills it (§4) |
| PR 58 (DD-1, fcee90d9b) | docs/design/templates.md, fork/designdocs/samples/X13..X33, check_samples.py, the ledger | n/a | the land-time integration commit L (§2.9) |
| PR 59 (VA-1, b0822a744) | check/convert.cpp (+114), call.cpp (+194), import_ref.cpp (+40), deduce.cpp (+35), pattern_match.cpp (+25), handle_binding_pattern.cpp (+76), type_completion.cpp (+41), lower/function_context.{h,cpp}, lower/type.cpp, sem_ir/typed_insts.h (+125), inst_kind.def (+8), kind.def (+19) | all hunks apply with offsets | textual only; C3's new kinds go after VA-1's in `inst_kind.def`; VA-1's pack actions are not template actions and are untouched |
| PR 57 (OP-2, 628273444) | check/convert.cpp (+7), lower/handle.cpp (+52) | applies | textual only |
| PR 52, 53, 54, 55, 56 | none in check or lower (PR 55 touches check/cpp/export.cpp only) | n/a | none |
| OX-1 (parked) | none merged | n/a | none |

### §0.10 What the arbiter's third clause means

"A template function executes in the run harness" means a conformance program
under the bullet that calls a function with a `template` parameter, compiles,
links, runs and prints its EXPECT. Trunk meets it with templates_type_param
and templates_value_param, and PR 51 adds templates_dependent_member. The
slice's programs (§1.10) extend it to every form it implements.

## §1 Design

### §1.1 Proposal 2200's rules, each IN or OUT of this slice

Numbered TR-n so the reviews and §1.13 can cite them. IN means implemented and
covered by a golden or a program in §4 and §5; OUT means left diagnosed (by
the existing diagnostic or a new `semantics TODO` with a golden) and filed.

1.  TR-1. A `template` binding in a deduced, explicit or class parameter
    list; each instantiation is checked and lowered (p002200:232-270).
    **IN** (exists; kept working: X22 and the three trunk programs).
2.  TR-2. Expressions that are not template dependent are checked at the
    definition (:735-737). **IN** (exists; every eager path below is
    unchanged for non-dependent operands, measured by the gate).
3.  TR-3. Template-dependent expressions are type checked when the template
    is instantiated, with monomorphization errors (:720-725). **IN** for the
    forms of TR-4 to TR-12.
4.  TR-4. Use of a dependent value is dependent: `F(expr)`, `expr + 1`,
    `a as expr` (:864-881). **IN**: initialization and copy of a dependent
    value (RC-1, RC-2, X18), returning dependent aggregates (X29 to X32),
    destructuring (X33), `for` over a dependent range (X28).
5.  TR-5. The pointer operators on a dependent operand: `*`, `->`, `&`
    (:864-881 by the same rule). **IN** (C3).
6.  TR-6. Tuple element access and indexing on a dependent operand. **IN**
    (C3).
7.  TR-7. Calling a value whose type is template dependent (:735-737's "a
    function may have a value that is function dependent, but calling that
    function only needs the type of the function"). **IN** (C3, D-TP-10).
8.  TR-8. Simple member access looks in the argument's type and in the
    constraint; if both find the name, they must find the same entity
    (:200-202, :433-441, :476-503, :739-768). **IN** (C5, W-183).
9.  TR-9. Compound member access `x.(I.F)` is checked at the definition when
    the constraint implies it (:769-831). **IN** (exists; X21's `x.(A.F)()`
    part).
10. TR-10. Impl lookup is delayed until all template arguments are known
    (:198-199, :832-863). **IN** for the facet conversions that need it (C4,
    W-127); TR-10's finer rule that an impl lookup whose validity alone is
    dependent is "template validity dependent" is not distinguished from
    "dependent" in the 0.1 toolchain (no observable difference in a
    program; D-TP-12).
11. TR-11. A template parameter is deduced as a checked one is, including
    through a class's arguments (:186-191, "In many ways, template generic
    parameters work like checked generic parameters"). **IN** (C4, W-193).
12. TR-12. Validity can depend on value (:702-710): array types with a
    template-dependent bound compare on instantiation. **IN** where it
    already works (s29, s31 run on trunk); initializing an array with a
    template-dependent bound from a list is **OUT** (X11, W-253).
13. TR-13. `match` over a dependent value, each case body dependent
    (:883-902). **OUT** (X10, W-252; the `match` machinery's own scrutinee
    support is the blocker).
14. TR-14. `auto` and template `let` bindings (:327-347, :232-270). **OUT**
    (W-039, W-031; unchanged).
15. TR-15. Template constraints (:348-432). **OUT** of this slice (SC-1,
    W-027).
16. TR-16. Branching on type identity and specialization (:271-277,
    :935-1001). **OUT** (unchanged; no residue is new).
17. TR-17. A template used from another library (implied by TR-1; the
    toolchain's own TODO at lower/handle.cpp:507-513). **OUT**, diagnosed
    (W-250, D-TP-14).
18. TR-18. A template form parameter (`template Fm: Core.Form`; the forms
    feature, not proposal 2200). **OUT**, diagnosed (W-255, D-TP-15).
19. TR-19. `partial T*` for a template `T` (the class/partial test's own
    TODO). **OUT** (X26, W-251).
20. TR-20. An out-of-line redeclaration of a template class's member whose
    signature names a template-dependent type matches a token-identical
    declaration (p3763). **OUT** (`member_out_of_line.carbon`
    `fail_todo_basic`, W-254).

### §1.2 Crash and miscompile fixes (C1, C2)

**D-TP-2 (A1): a template-dependent operand initialized into storage of the
same type is deferred as a storage-carrying `InitializeAction`.** In
`AddConvertActionIfDependent` (convert.cpp:2312), the same-type early exit is
narrowed: when the target is an initializer with storage and the operand is
not already an initializer, the function continues to its dependence test and
its existing `InitializeAction` branch (:2335-2391), which records the
storage and, on instantiation, runs builtin, user-defined and category
conversion with that storage (`PerformAction(InitializeAction)`, :2474-2520).
How a value of type `T` is copied (element by element for a struct, tuple or
array; through `Core.Copy` otherwise) is decided on instantiation, which is
TR-4. This removes RC-1 and RC-2 and makes X18's struct copy work. _Break
condition:_ a non-template initialization changes (measured: the only goldens
v2 changes are the two dependent value conversions of D-TP-6).

**D-TP-3 (A4): before an `InitializeAction` is created, its storage access
block is inserted at the current position.** The action refers to
`target.storage_id`, so the instructions it depends on (a `tuple_access` of
the return slot, a `VarStorage`) must be emitted before the splice; this is
the fork's form of upstream 4a8993af2's fix, chosen because that commit moves
the block into the action and CHECK-fails on a block with cleanups, which
every template `for` loop has once D-TP-2 applies (measured, v10). _Break
condition:_ upstream changes `PendingBlock::TakeAsInstBlock` to carry
cleanups, in which case the next upstream advance adopts upstream's form and
drops this one (W-258).

**D-TP-4 (A2): an action that replays an initializing conversion supplies its
own storage access block.** `PerformAction(ConvertAction)` and
`PerformAction(ConvertToCategoryAction)` construct their `ConversionTarget`
with a local `PendingBlock` and insert it after the conversion, as
`Initialize` does (convert.cpp:2738-2751). `ConversionTarget`'s contract
(convert.h:61-74) and :588, :781, :879, :918, :1023, :1036, :1144 and :2198
dereference `storage_access_block` for every initializer. _Break condition:_
none; this restores an invariant.

**D-TP-5 (A3, B4): `FindStorageArgForInitializer` takes the specific it is
evaluated in, and an unresolved splice has no storage argument.** The
function gains `SpecificId specific_id = SpecificId::None` (it already tracks
a specific internally from `SpecificInst`); its `SpliceInst` arm returns
`InstId::None` when the splice's constant in that specific is not concrete
(the definition), mirroring `GetExprCategory`'s `SpliceInst` arm
(expr_info.cpp:127-152). Lowering callers pass `context.specific_id()`. This
removes RC-3. _Break condition:_ a caller in check needs the storage of an
unresolved splice (none: `Initialize` falls back to its own `storage_id`).

**D-TP-6 (A5): a dependent value conversion is a `ConvertToValueAction`.** In
`DoStep`'s `Dependent` case, a target of kind `Value` creates
`ConvertToValueAction` (which already exists, with
`ActionExprCategory(Value)`, typed_insts.h:629-641) instead of
`ConvertToCategoryAction`, so a binding of the result has the value category
in the definition and on instantiation alike. This removes RC-6's second
half. _Break condition:_ a dependent value conversion whose result is not a
value on instantiation (impossible: the target kind is `Value`).

**D-TP-7 (B1 to B3): lowering reads categories, constants and storage in the
specific, and a spliced in-place initializer has no value.** B1 passes
`&context.specific_sem_ir(), context.specific_id()` to every
`GetExprCategory` call on an instruction of the function being lowered
(aggregate.cpp:56, handle.cpp:105, handle_expr_category.cpp:61, :77, :87;
`ReturnExpr` already does). B2 makes `HandleInst(SpliceBlock)` and
`HandleInst(SpliceInst)` call `GetValue(..., /*require_value=*/false)` and
set a local only when there is a value, as `HandleInst(SpecificInst)` does.
B3 makes `EmitAggregateInitializer` (aggregate.cpp:227-235) and the fork's
`ArrayInit` arm (handle.cpp:86-92) decide constness with
`FunctionContext::IsConstant`, as `LowerInst` does, and find the storage in
the specific. These remove RC-5's second half, RC-6's first half and RC-7.
_Break condition:_ a lowered non-template function changes (measured: no
lower golden changes except one SSA name in template/class.carbon).

**D-TP-8 (A6): the `for` header requires its cursor pointer type complete.**
handle_loop_statement.cpp:254-259 calls `RequireCompleteType` on the
pointer type before forming `&cursor`; for a symbolic pointee this records a
`require_complete_type` in the eval block, so each specific completes the
pointer type its `Next` call passes. This removes RC-4. B5 adds a
`CARBON_CHECK` to `GetOrCreateLLVMFunction` that an inexact function type has
no return slot, so the next missing completeness requirement anywhere fails
with a message instead of a segfault. _Break condition:_ a checked-generic
loop changes behavior (measured: interop/cpp/range_for.carbon gains only the
`require_complete_type` lines).

**D-TP-14 (C2): a template used from another library is diagnosed when it is
imported.** `TryFinishGeneric` (import_ref.cpp:1162-1193) does not import a
definition eval block that contains an action or a splice, and reports
`semantics TODO: Unsupported: using a template from another library`; the
local generic then has no definition, and the call reports `use of undefined
generic function` (measured, v4). `TryResolveInstCanonical`'s fatal is then
unreachable for template instructions, and lowering's cross-file fatal
(handle.cpp:513) is unreachable because checking reports errors first. OUT,
W-250. _Break condition:_ a template is imported without being named (it is
not: `TryFinishGeneric` runs only for a used generic, measured by the gate,
where no golden imports a template).

**D-TP-15 (C2): a template form parameter is diagnosed.** In
handle_binding_pattern.cpp:470-490, a `FormBindingPattern` whose form is
template dependent reports `semantics TODO: template form parameter` at the
binding, before `FormParamPatternAction` is formed, so RC-9's lowering fatal
and the pattern-splice fatals of pattern_match.cpp:2174-2180 are not reached
through a template form. OUT, W-255. _Break condition:_ `Core.Form` is
exported by the prelude and a design for template forms is accepted.

### §1.3 Dependent-form deferrals (C3)

**D-TP-9: four new action kinds, each performing the existing eager code on
instantiation.** Following `AccessMemberAction` and `CallAction`, each form
gets an action whose `PerformAction` is the code that runs today for a
non-dependent operand; the definition creates the action only when that code
cannot decide yet, so every non-template SemIR is unchanged:

| Action | Fields | Created when | `PerformAction` | Category |
| --- | --- | --- | --- | --- |
| `PointerDereferenceAction` | `MetaInstId pointer_id`, `BoolValue is_arrow` | the operand's unqualified type is template dependent and not a `PointerType` | `PerformPointerDereference` with the `*` or `->` diagnostic | `Dependent` |
| `AddrOfAction` | `MetaInstId lvalue_id`, `AbsoluteInstId` none (one operand) | the operand's category is `Dependent` | the body of `HandleParseNode(PrefixOperatorAmp)` (handle_operator.cpp:270-294), extracted as `PerformAddrOf` | `Value` |
| `TupleIndexAction` | `MetaInstId tuple_id`, `MetaInstId index_id` | the tuple operand's type is template dependent and not a `TupleType` | `PerformTupleAccess` (member_access.cpp:892) | `Dependent` |
| `IndexAction` | `MetaInstId operand_id`, `MetaInstId index_id` | the operand's type is template dependent and not an `ArrayType` | the body of `HandleParseNode(IndexExpr)` (handle_index.cpp:157-215), extracted as `PerformIndex` | `Dependent` |

The narrow creation conditions are the design: a dereference of `p: T*`
(s14) and an index into `array(T, 3)` stay eager, as today. On
instantiation a failure is a monomorphization error whose note is the eager
diagnostic, as for member access (R08). _Break condition:_ an existing
golden other than unimplemented.carbon changes (predicted: none; the creation
conditions are exactly the cases trunk rejects).

**D-TP-10: a callee of function type with no constant value calls the
function its type names.** In `PerformCallHelper` (call.cpp:836), a callee
whose type is a `FunctionType` and whose constant value is not a constant is
replaced, for resolution, by the function type's value (`StructValue` with no
elements, the constant every `fn` declaration evaluates to,
eval_inst.cpp `EvalConstantInst(FunctionDecl)`); the callee expression has
already been evaluated in order, so no side effect is lost. p2875 gives each
function its own type; p002200:735-737 makes such a call "only need the type
of the function". _Break condition:_ a function type with more than one
value (none exists in the toolchain).

### §1.4 SpliceInst lowering

Upstream PR 7727's design is kept: a splice in a specific lowers to the
instruction its action produced there, lowered in place, and its value is
that instruction's value. TP-1 completes it where the measured defects are:
the spliced instruction may be an in-place initializer with no value (B2),
the function's other instructions must read categories and constants of the
splice in the specific (B1, B3), and storage arguments are found in the
specific (D-TP-5). The cross-file case stays a fatal that checking now makes
unreachable (D-TP-14); a later item (W-250) implements it.

### §1.5 Name lookup into a constrained template parameter (W-183, C5)

Root cause: §0.4. Cost, measured on v5: 93 changed lines in
member_access.cpp, no golden change, conformance unchanged, and five probes
(R09 `25`, `extend impl` `25`, type-only member `72`, field `9`, X21
rejected).

**D-TP-13.** On instantiation, `PerformAction(AccessMemberAction)` looks the
name up twice: in the argument's type, as today, and in the constraint of the
template parameter whose type the operand had in the definition (the refined
operand is a `SpecificInst` of the definition's operand; its type there is
`FacetAccessType(T)`; the binding's value in the specific is the argument's
facet value, whose facet type is the constraint). The constraint lookup uses
`LookupMemberNameInScope` with `lookup_in_type_of_base`, so an associated
entity found in the constraint is accessed through the argument's impl, as
`x.(I.F)` is, then instance-bound. If only one lookup finds the name, its
result is used; if both find it, the results must name the same entity (the
same function and enclosing specific for a function, the same constant
otherwise), else the access is an error. The new diagnostic, under
diagnostics/kind.def:

<!-- google-doc-style-ignore -->

```cpp
CARBON_DIAGNOSTIC(TemplateMemberLookupAmbiguous, Error,
                  "member name `{0}` names different entities in type {1} and "
                  "in its constraint {2}",
                  SemIR::NameId, SemIR::TypeId, SemIR::TypeId);
```

<!-- google-doc-style-resume -->

On instantiation it becomes the note under ``unable to monomorphize specific
`G(C as A)` ``. For X21 the note reads ``member name `F` names different
entities in type `C` and in its constraint `A` `` (hand-predicted from the
format; C5 is not relinkable because of the new diagnostic kind).
_Break condition:_ SC-1's `LookupMemberNameInTypeScopes` maps a structural
requirement found in the constraint to the type's own member, so a template
constraint's requirement and the type's member are the same entity; the
composition (§0.9) must keep that, or the rule is restated in the plan's
next revision.

### §1.6 Deduction through a class's arguments (W-193, C4)

Root cause: §0.4. Cost, measured on v4: 32 changed lines in call.cpp for both
X17 and W-193; generic/template/convert.carbon and class/destroy_calls.carbon
refill (the dependent `C(T)` types become `class_type @C, @C(%T)
[template]` constants instead of `call_action` splices; no diagnostic
changes).

**D-TP-11.** `IsCallPerformable` (call.cpp:820-833) treats a call to a generic
class, interface or named constraint (the callee's type is
`GenericClassType`, `GenericInterfaceType` or `GenericNamedConstraintType`)
as performable when no argument's _type_ is template dependent; the
arguments' _values_ may be template dependent, as symbolic arguments of a
checked generic are. The resulting type is a template-dependent class type,
which deduction (deduce.cpp:399-465) matches through its specific as it does
for a checked parameter. Every other callee keeps today's rule. _Break
condition:_ a generic class whose parameter conversion depends on the
argument's value (none: the arguments are converted to the declared
parameter types, which the call checks with the symbolic values).

### §1.7 Deferred impl lookup (W-127, C4)

Root cause: §0.4. Cost, measured on v7: 26 changed lines in
impl_lookup.cpp; facet/period_self.carbon's `fail_todo` split changes its
first error (from `ConversionFailureFacetToFacet` to
`NestedWhereInsideWhere`, both on `.YF()`, whose `eval fn` result is template
dependent), and interop/cpp/template/generic_call.carbon no longer selects an
impl in the definition.

**D-TP-12.** A template-dependent query self (`ConstantDependence::Template`)
is never resolved in the definition: `EvalLookupSingleFinalWitness`
(impl_lookup.cpp:1182) returns `None` for it, before collecting candidates,
and `LookupImplWitness` (:989) keeps the deferred `LookupImplWitness` as the
witness without asking `FindNonFinalWitness`. Selecting even a `final` impl
early is wrong for a template, because the final impl's own requirement
(`T: Default` for the prelude's `DefaultOrUnformed`) can be decided only on
instantiation (measured as v6's defect). This is proposal 2200's "Impl lookup
is delayed until all templated types, interfaces, and parameters are known"
(:198-199). _Break condition:_ a checked (symbolic, not template) query
changes (impossible by the condition; measured by the gate).

### §1.8 Out-of-slice forms and their diagnostics

| Form | Today | After TP-1 | W-id |
| --- | --- | --- | --- |
| a template used from another library | fatal (RC-8) | `semantics TODO` at the import, golden | W-250 |
| `partial T*` | `PartialOnFinal`, golden `fail_todo_partial_template_dependent` | unchanged | W-251 |
| `match` on a dependent value | `semantics TODO`, fixture X10 | unchanged | W-252 |
| an array with a dependent bound from a list | error, golden `fail_todo_init_template_dependent_bound` | unchanged | W-253 |
| an out-of-line redeclaration naming `T.U` | rejected even when token-identical (measured `$P/probes/mool.carbon`), message prints `<cannot stringify ...>` | unchanged | W-254 |
| a template form parameter | lowering fatal (RC-9) | `semantics TODO` at the binding, golden | W-255 |

### §1.9 Goldens

All new goldens are AUTOUPDATE sources without CHECK lines, filled by the
container arbiter's autoupdate to a fixpoint (R15, R16(a), R19, R26); every
new diagnostic has a `fail_` split. Names and splits are in §2.7; predicted
key lines in §4. Flipped `fail_todo` splits:

1.  generic/template/unimplemented.carbon `fail_todo_unimplemented_operator`
    (`*x.n`, `F` not called): C3 makes the definition valid; renamed
    `deref_dependent_member.carbon`, no STDERR, and a new split
    `fail_deref_dependent_member_non_pointer.carbon` calls `F` on a class
    whose `n` is `i32` to pin the instantiation error (note
    ``cannot dereference operand of non-pointer type `i32` ``).
2.  generic/template/unimplemented.carbon `fail_todo_unimplemented_value`
    (`*c.n` with `template c: C`): renamed `deref_dependent_value.carbon`,
    no STDERR (no instantiation; `C.n` is `i32`, so any call is an error,
    which split 1's failing companion pins for the type form).
3.  generic/template/call.carbon `fail_todo_dependent_call_nonconst_arg`:
    renamed `dependent_call_nonconst_arg.carbon`, no STDERR (measured v4).
    Its sibling `fail_dependent_call_nonconst_arg_wrong_type` keeps its name
    and now fails on the argument conversion (measured: the note becomes
    ``Core.ImplicitAs` implicitly referenced here, but package `Core` not
    found`` under min_prelude/none.carbon, with ``initializing function
    parameter``); its `// TODO: should fail, but not because of
    UseOfNonExprAsValue` comment is removed, because it no longer fails for
    that reason.
4.  generic/template/member_out_of_line.carbon `fail_todo_basic`: stays
    (W-254).

Refills without a new name: generic/template/convert.carbon (D-TP-6, D-TP-11),
class/destroy_calls.carbon (D-TP-11), facet/period_self.carbon (D-TP-12),
interop/cpp/template/generic_call.carbon (D-TP-12),
interop/cpp/range_for.carbon (D-TP-8), lower/testdata/template/class.carbon
(D-TP-3, one SSA name), and at land time PR 51's
interop/cpp/template/dependent_var_full_prelude.carbon (its
`fail_todo_unformed_dependent_var` split renamed `unformed_dependent_var`,
D-TP-12).

### §1.10 Conformance programs and their EXPECT derivations (R16(d))

Eight programs under fork/conformance/programs/generics/, bullet "Generics:
Integrated templates", each derived from the program text and the design,
then cross-checked (never derived) against the relinked prototype where it
can run and against the same bodies with the types written out on trunk:

| Program | Forms | EXPECT | Derivation |
| --- | --- | --- | --- |
| templates_dependent_pointer | `*p`, `x.p->n`, `&x.n` and `*q += 1` (X13, X14, X15) | `4`, `7`, `8` | `Deref(&n)` reads `n` = 4; `Next(link)` reads `link.p->n` = `node.n` = 7; `Bump(ref node)` adds 1 to `node.n` through `&node.n` and returns 8. Concrete baseline on trunk prints `4 7 8` ($P/progs/base_pointer.carbon). |
| templates_dependent_index | `p.1` (X16), `a[1]` (X19), `self.item[0]` in a class template (X24) | `5`, `2`, `8` | element 1 of `(4, 5)`; element 1 of `(1, 2, 3)`; element 0 of `(8, 9)`. Concrete baseline prints `5 2 8`. |
| templates_return_aggregates (differential, with `.diff.cpp`) | X29, X30, X31, X32, X33, PR-AK, X18 | none (the C++ oracle computes `8 10 8 6 9 4 5 7`) | `Dup(4)` sums 4 + 4; `Mk(5)` sums 5 + 5; `Two(4)` sums 4 + 4; `H(i32)` with `a = 3` sums 3 + 3; `Sum((4, 5))` is 9; `Id((4, 5))` prints 4 then 5; `Id({.x = 6, .y = 7}).y` is 7. The C++17 oracle compiled with LLVM 21.1.8's clang++ prints the same; v8 prints the same. |
| templates_for_dependent_range | X28 over an array argument and over `Core.Range(c.n)` | `6`, `6` | 1 + 2 + 3; 0 + 1 + 2 + 3 (`Core.Range(4)` yields 0 to 3, core/prelude/range.carbon). v8 prints `6 6`. |
| templates_dependent_call | X17 with two callees | `8`, `25` | `Twice(4)`; `Square(5)`. v8 prints `8 25`. |
| templates_constraint_lookup | W-183: a constraint-only member and an `extend impl` member | `25`, `6` | 5 x 5 through `Square`'s `impl as HasArea`; 2 x 3 through `Rect`'s `extend impl`. v5 and v8 print `25 6`. |
| templates_deduce_class_args | W-193: `Holder(T)`, `Holder(T)*`, `Vec(N)` | `21`, `42`, `3` | the item; the item read through the pointer, doubled; the deduced `N`. v8 prints `21 42 3`. |
| templates_uninit_var | W-127 in a function and a class template method (X20, X23) | `5`, `6` | `Swap(4, 5)` returns its second argument assigned into `y`; `Peek` returns `top` = 6. v8 prints `5 6`. |

No program pins a nightly difference: R30 governs Carbon-versus-C++
divergence, and no form here diverges from C++; the one differential program
uses the C++ oracle in the agreeing direction (fork/conformance/README.md
"Differential Carbon-vs-C++ programs"). The negative forms (X21's
different entities, a dereference of a non-pointer on instantiation, the
cross-library and form TODOs) are goldens, not programs.

### §1.11 Docs and records

Docs: TP-1's own commits change no design page. The land-time integration
commit L (§2.9) amends docs/design/templates.md (PR 58's text) with dated
notes. Records (commit D unless noted): W-014 notes and evidence (§2.9),
W-183, W-192 and W-193 discharged with texts, W-127 discharged (PR 51's
item), residues W-250 to W-258 filed, the decision-log entry "TP-1", the row
(commit R), fork/conformance/README.md rows (commit P), fork/ORCHESTRATION.md
(commit D and L).

### §1.12 Merge position

TP-1 is cut from trunk b2576f6c3 and lands after PR 59 (D-TP-19). Before its
gate is judged for landing, trunk (with every earlier PR merged) is merged
into the branch with a merge commit, never a rebase (AGENTS.md "Version
control"); the composition rules of §0.9 resolve the conflicts, the full
build, autoupdate fixpoint, gate and conformance re-run on the merge, and the
land-time integration commit L follows it.

### §1.13 Residues filed (W-250..W-258; W-259..W-269 spare)

1.  W-250 (TR-17). A template used from another library: `semantics TODO:
    Unsupported: using a template from another library` (RC-8). Removal:
    import of action and splice instructions and cross-file template
    lowering (lower/handle.cpp:507-513).
2.  W-251 (TR-19). `partial T*` for a template `T` (X26;
    class/partial/qualifier.carbon `fail_todo_partial_template_dependent`):
    needs the `PartialOnFinal` check performed on instantiation.
3.  W-252 (TR-13). `match` on a template-dependent value (X10).
4.  W-253 (TR-12). An array with a template-dependent bound initialized
    from a list (X11; array/init_dependent_bound.carbon
    `fail_todo_init_template_dependent_bound`); the nightly accepts it after
    upstream 947c1eb52.
5.  W-254 (TR-20). Out-of-line redeclaration of a template class member
    whose signature names a template-dependent type is rejected even when
    token-identical, and the message prints `<cannot stringify ...>`
    (generic/template/member_out_of_line.carbon `fail_todo_basic`;
    `$P/probes/mool.carbon`).
6.  W-255 (TR-18). Template form parameters: `semantics TODO: template form
    parameter`; the pattern-splice fatals of pattern_match.cpp:2174-2180 and
    return.cpp's symbolic-form TODOs (:217, :228) belong to the same feature.
7.  W-256. Not a template defect: a by-copy struct whose field is an in-place
    aggregate, initialized from a value (RC-10), crashes `Convert` on trunk
    and the nightly.
8.  W-257. Hardening only: lowering builds an inexact function type when a
    parameter's type is incomplete (lower/type.cpp:493) and continues;
    B5's check makes it fail loudly, but the inexact type should not be
    built at all.
9.  W-258. Upstream-advance reconciliation: 4a8993af2's
    `PendingBlock::TakeAsInstBlock` CHECK-fails on a block with cleanups,
    which D-TP-2 produces for the `for` cursor; the next upstream advance
    keeps D-TP-3's form or extends upstream's to carry cleanups.

### §1.14 Decision index (auto-adopted under V-2/V-3; each has a break condition above or here)

-   D-TP-1. The slice is crash and miscompile fixes first (R17), then the
    rejected dependent forms, then W-183, W-193 and W-127, each IN because
    its root cause was found and its cost measured. _Break:_ a review shows
    a measured cost understated by more than one fix commit.
-   D-TP-2. Same-type template-dependent initialization is a storage-carrying
    `InitializeAction` (§1.2).
-   D-TP-3. The storage access block is inserted before the action, not
    moved into it (§1.2).
-   D-TP-4. Replayed initializing conversions get a local storage access block
    (§1.2).
-   D-TP-5. `FindStorageArgForInitializer` is specific-aware; an unresolved
    splice has no storage argument (§1.2).
-   D-TP-6. A dependent value conversion is a `ConvertToValueAction` (§1.2).
-   D-TP-7. Lowering reads categories, constants and storage in the
    specific; a spliced in-place initializer has no value (§1.2).
-   D-TP-8. The `for` cursor pointer type is required complete; an inexact
    function type with a return slot is a CHECK (§1.2).
-   D-TP-9. Four action kinds for `*`/`->`, `&`, tuple element access and
    indexing, created only where the eager code cannot decide (§1.3).
-   D-TP-10. A function-typed callee with no constant value calls its type's
    function (§1.3).
-   D-TP-11. Generic type constructors with template-dependent argument
    values are formed eagerly (§1.6).
-   D-TP-12. Impl lookup for a template-dependent query selects no impl in the
    definition (§1.7).
-   D-TP-13. Member lookup into a constrained template parameter consults the
    type and the constraint; different entities are an error (§1.5).
-   D-TP-14. A template used from another library is a `semantics TODO`
    (§1.2).
-   D-TP-15. A template form parameter is a `semantics TODO` (§1.2).
-   D-TP-16. No upstream cherry-pick (§0.7). _Break:_ upstream lands a
    template commit that subsumes one of C1 to C5 before TP-1's merge, in
    which case the plan's next revision takes it as C0 with upstream
    authorship.
-   D-TP-17. No fork design id (F-019 unminted). _Break:_ a review shows a
    rule decided here that proposal 2200 leaves open.
-   D-TP-18. The row stays PARTIAL: W-014's first arbiter clause is not met
    while `fail_todo_basic` stands (W-254). _Break:_ W-254 lands, then the
    row moves to DONE on the arbiter's measurement.
-   D-TP-19. Merge after PR 59 with a merge of trunk; the PR 58 integration is
    a separate commit L (§1.12, §2.9). _Break:_ the merge order of record
    changes.
-   D-TP-20. Eight conformance programs, one differential (§1.10). _Break:_ a
    program's derivation is shown wrong; it is re-derived, never re-run to
    fit.
-   D-TP-21. DD-1's fixtures flip at land time to the measured behavior with
    new quotes; resolved limits get dated notes, never silent deletions
    (§2.9). _Break:_ PR 58's checker rejects a fixture kind the plan uses.
-   D-TP-22. Five implementation commits with their fills, then P, R, D, M
    and L; three fix commits at most, shrinking C5 first and C1, C2 never
    (§3). _Break:_ a commit cannot compile without a later commit's files.

## §2 Spec, file by file

### §2.0 Conventions

Code blocks are the v8 prototype's diff where the change was relinked
(marked "measured"), or hand-written against the quoted trunk code where it
was not (marked "hand-predicted"). C++ follows the CI-pinned clang-format
21.1.8 (R18); the implementer runs it. Every comment that cites this fork
says "Fork (TP-1, ...)" only where the code diverges from upstream's
structure; comments state invariants, not history.

### §2.1 Commit C1: initializers keep their storage; splices resolve in the specific

Files: check/convert.cpp, check/handle_loop_statement.cpp,
sem_ir/expr_info.{h,cpp}, lower/aggregate.cpp, lower/handle.cpp,
lower/handle_expr_category.cpp, lower/function_context.cpp,
lower/file_context.cpp.

**A1 and A4, check/convert.cpp `AddConvertActionIfDependent` (measured).**

<!-- google-doc-style-ignore -->

```diff
   if (context.insts().Get(expr_id).type_id() == target.type_id) {
-    // No conversion required.
-    return SemIR::InstId::None;
+    // No type conversion is required. A template-dependent operand that is not
+    // already an initializer still needs a copy into the target's storage, and
+    // how it is copied (element by element for a struct, tuple or array value,
+    // through `Core.Copy` otherwise) is known only for a concrete type, so
+    // that copy is deferred, with its storage, below.
+    if (!target.is_initializer() || !target.storage_id.has_value() ||
+        SemIR::IsInitializerCategory(
+            SemIR::GetExprCategory(context.sem_ir(), expr_id))) {
+      return SemIR::InstId::None;
+    }
   }
@@
     auto action_type_id = GetTupleType(context, action_type_elements_id);

+    // The action refers to `target.storage_id`, so the instructions it
+    // depends on are emitted here, before the splice that uses them.
+    target.storage_access_block->InsertHere();
+
     // Create the initialization action.
```

<!-- google-doc-style-resume -->

Invariant: after the change, a `ConvertToCategoryAction` is created only for
a target without storage or that is not an initializer (the same-type case
with storage now takes the `InitializeAction` branch, which already existed
for the different-type case), and every `InitializeAction`'s `storage_id`
dominates its splice. The dependence test that follows the early exit is
unchanged, so a non-dependent operand still returns `None`.

**A5, `CategoryConverter::DoStep` `Dependent` case (measured).**

<!-- google-doc-style-ignore -->

```diff
     case SemIR::ExprCategory::Dependent:
+      if (target_.kind == ConversionTarget::Value) {
+        // The result is known to be a value, so record that in the action:
+        // a binding of it, and every use of the binding, then has the value
+        // category in the definition, as it does on instantiation.
+        auto type_inst_id = context_.types().GetTypeInstId(
+            context_.insts().Get(expr_id).type_id());
+        return Done{AddDependentActionSplice<SemIR::ConvertToValueAction>(
+            context_, loc_id_,
+            {.type_id = SemIR::InstType::TypeId,
+             .inst_id = expr_id,
+             .target_type_inst_id = type_inst_id},
+            type_inst_id)};
+      }
       return Done{AddDependentActionSplice<SemIR::ConvertToCategoryAction>(
```

<!-- google-doc-style-resume -->

**A2, the two `PerformAction`s (measured).**

<!-- google-doc-style-ignore -->

```diff
 auto PerformAction(Context& context, SemIR::LocId loc_id,
                    SemIR::ConvertAction action) -> SemIR::InstId {
   const auto& target_bundle = context.bundles().Get(action.target_id);
+  // An initializing target always has a storage access block, which the
+  // aggregate conversions add element storage to. This action carries no
+  // storage, so the block holds only what the conversion itself creates.
+  PendingBlock target_block(&context);
   ConversionTarget target = {
       .kind = ConversionTarget::Kind(target_bundle.conversion_kind.index),
       .type_id = context.types().GetTypeIdForTypeInstId(
-          target_bundle.target_type_inst_id)};
+          target_bundle.target_type_inst_id),
+      .storage_access_block = &target_block};

   auto expr_id =
       PerformBuiltinConversion(context, loc_id, action.inst_id, target);
   expr_id = PerformUserDefinedConversion(context, loc_id, expr_id, target);
-  return PerformCategoryConversion(context, loc_id, expr_id, target);
+  expr_id = PerformCategoryConversion(context, loc_id, expr_id, target);
+  target_block.InsertHere();
+  return expr_id;
 }
```

<!-- google-doc-style-resume -->

`PerformAction(ConvertToCategoryAction)` changes the same way. After SC-1
lands, SC-1's `CheckConversionIsNotOfStructuralRequirement` call stays the
first statement of each (§0.9).

**A3 and B4, sem_ir/expr_info.{h,cpp} (measured).** The declaration gains a
defaulted fourth parameter and its comment a paragraph:

<!-- google-doc-style-ignore -->

```cpp
// `specific_id` is the specific in which `init_id` is evaluated: in a
// template's specific, a splice in the initializer is resolved to the
// instruction it splices in that specific.
auto FindStorageArgForInitializer(const File& sem_ir, InstId init_id,
                                  bool allow_transitive = true,
                                  SpecificId specific_id = SpecificId::None)
    -> InstId;
```

<!-- google-doc-style-resume -->

The definition drops its local `auto specific_id = SemIR::SpecificId::None;`
and its `SpliceInst` arm returns `InstId::None` when
`GetConstantValueInSpecific(sem_ir, specific_id, inst.inst_id)` is not
concrete, with the comment "The action that produces the spliced instruction
has not been performed: in a template's definition, the initializer and its
storage argument are known only on instantiation." Callers unchanged in check
(convert.cpp:111, :180, :196, :224, :2762; formatter.cpp:1080); lowering
callers pass the specific (B3).

**A6, check/handle_loop_statement.cpp (measured).**

<!-- google-doc-style-ignore -->

```diff
   auto cursor_type_inst_id = context.types().GetTypeInstId(cursor_type_id);
+  auto cursor_ptr_type_id = GetPointerType(context, cursor_type_inst_id);
+  // The code that forms an instruction enforces its type's completeness
+  // (type_completion.h): for a template-dependent cursor type, this records
+  // the requirement, so that each specific completes the pointer type its
+  // `Next` call passes. A pointer type is always complete, so the
+  // diagnostic context adds nothing.
+  RequireCompleteType(context, cursor_ptr_type_id, SemIR::LocId(node_id),
+                      [](auto& /*builder*/) {});
   auto cursor_addr_id = AddInst<SemIR::AddrOf>(
       context, node_id,
-      {.type_id = GetPointerType(context, cursor_type_inst_id),
-       .lvalue_id = cursor_var_id});
+      {.type_id = cursor_ptr_type_id, .lvalue_id = cursor_var_id});
```

<!-- google-doc-style-resume -->

The file includes toolchain/check/type_completion.h.

**B1, lowering categories in the specific (measured).** Each of
lower/aggregate.cpp:56, lower/handle.cpp:105 (`Assign`),
lower/handle_expr_category.cpp:61 (`Temporary`), :77 (`ValueAsRef`) and :87
(`ValueOfInitializer`) becomes

<!-- google-doc-style-ignore -->

```cpp
SemIR::GetExprCategory(context.sem_ir(), <inst>, &context.specific_sem_ir(),
                       context.specific_id())
```

<!-- google-doc-style-resume -->

as `ReturnExpr` (handle.cpp:378-381) already is; aggregate.cpp gains the
comment "The aggregate can be a splice in a template's specific; its category
is that of the spliced instruction."

**B2, lower/handle.cpp splice handlers (measured).**

<!-- google-doc-style-ignore -->

```diff
 auto HandleInst(FunctionContext& context, SemIR::InstId inst_id,
                 SemIR::SpliceBlock inst) -> void {
   context.LowerBlockContents(inst.block_id);
-  context.SetLocal(inst_id, context.GetValue(inst.result_id));
+  // In a template's specific, the result can be an in-place initializer,
+  // which has no value; see the `SpecificInst` case above.
+  if (auto* value = context.GetValue(inst.result_id, /*require_value=*/false)) {
+    context.SetLocal(inst_id, value);
+  }
 }
@@
     context.LowerInst(inst_value.inst_id);
-    context.SetLocal(inst_id, context.GetValue(inst_value.inst_id));
+    // The spliced instruction can be an in-place initializer, which has no
+    // value; see the `SpecificInst` case above.
+    if (auto* value =
+            context.GetValue(inst_value.inst_id, /*require_value=*/false)) {
+      context.SetLocal(inst_id, value);
+    }
```

<!-- google-doc-style-resume -->

Invariant: a consumer that needs the splice's value still fails loudly in
`GetValue` with `require_value` (the default); only the splice itself no
longer demands one.

**B3, lower/aggregate.cpp `EmitAggregateInitializer`, lower/handle.cpp
`ArrayInit`, lower/function_context.cpp `InitializeStorage` (measured).**

<!-- google-doc-style-ignore -->

```diff
       for (auto [i, ref_id] : llvm::enumerate(refs)) {
-        if (context.sem_ir().constant_values().Get(ref_id).is_constant()) {
-          auto dest_id =
-              SemIR::FindStorageArgForInitializer(context.sem_ir(), ref_id);
+        // Whether the element was skipped as a constant is decided in the
+        // specific, as `LowerInst` decides it.
+        if (context.IsConstant(ref_id)) {
+          auto dest_id = SemIR::FindStorageArgForInitializer(
+              context.sem_ir(), ref_id, /*allow_transitive=*/true,
+              context.specific_id());
```

<!-- google-doc-style-resume -->

handle.cpp:87-89 changes the same way; function_context.cpp:438-442 passes
`specific_id_`.

**B5, lower/file_context.cpp `GetOrCreateLLVMFunction` (hand-predicted).**
Before `return_arg.addAttr` (:438-442):

<!-- google-doc-style-ignore -->

```cpp
CARBON_CHECK(!llvm_function->arg_empty(),
             "Return slot for {0} without parameters: a parameter type was "
             "not complete when the function type was built",
             mangled_name);
```

<!-- google-doc-style-resume -->

### §2.2 Commit C2: cross-library templates and template form parameters are diagnosed

**check/import_ref.cpp `TryFinishGeneric` (measured).**

<!-- google-doc-style-ignore -->

```diff
   auto specific_data =
       GetLocalSpecificData(resolver, import_generic.self_specific_id);
+
+  // A template's definition holds instructions that are resolved per
+  // instantiation (actions and the splices of their results). Instantiating an
+  // imported template needs a representation of that instantiation that does
+  // not exist yet (lowering's "Cross-file template lowering" has the same gap),
+  // so the definition is not imported and its use is diagnosed.
+  auto definition_block_id = import_generic.definition_block_id;
+  if (definition_block_id.has_value() &&
+      llvm::any_of(resolver.import_ir().inst_blocks().Get(definition_block_id),
+                   [&](SemIR::InstId inst_id) {
+                     auto kind = resolver.import_ir().insts().Get(inst_id).kind();
+                     return kind.is_action() ||
+                            kind == SemIR::SpliceInst::Kind ||
+                            kind == SemIR::SpliceBlock::Kind;
+                   })) {
+    resolver.local_context().TODO(
+        SemIR::LocId::None,
+        "Unsupported: using a template from another library");
+    definition_block_id = SemIR::InstBlockId::None;
+  }
```

<!-- google-doc-style-resume -->

and the two later uses of `import_generic.definition_block_id` in the function
read `definition_block_id`. Measured output on `$P/xlib`: `main.carbon:
error: semantics TODO: Unsupported: using a template from another library`
then `main.carbon:4:51: error: use of undefined generic function`.

**check/handle_binding_pattern.cpp (hand-predicted).** In the
`FormBindingPattern` branch (:478-490), before `HandleAction<
SemIR::FormParamPatternAction>`:

<!-- google-doc-style-ignore -->

```cpp
if (OperandDependence(context, form_id) ==
    SemIR::ConstantDependence::Template) {
  // Template form parameters are part of the forms feature, not of
  // proposal 2200, and their pattern splices are not lowered.
  return context.TODO(node_id, "template form parameter");
}
```

<!-- google-doc-style-resume -->

(`form_id` is the binding's form, as at :486; the implementer uses the
binding's existing local name.)

### §2.3 Commit C3: dependent dereference, address-of, tuple element access, indexing and calls

Hand-predicted (the X-macro list is not relinkable), except call.cpp
(measured).

**sem_ir/inst_kind.def**, alphabetical with the existing entries:
`AddrOfAction`, `IndexAction`, `PointerDereferenceAction`,
`TupleIndexAction`.

**sem_ir/typed_insts.h**, beside `AccessMemberAction`:

<!-- google-doc-style-ignore -->

```cpp
// An action that takes the address of a template-dependent operand, `&expr`.
struct AddrOfAction {
  static constexpr auto Kind = InstKind::AddrOfAction.Define<Parse::NodeId>(
      {.ir_name = "addr_of_action",
       .expr_category = ActionExprCategory(ExprCategory::Value),
       .constant_kind = InstConstantKind::InstAction,
       .is_lowered = false});

  TypeId type_id;
  MetaInstId lvalue_id;
};

// An action that indexes a template-dependent operand, `expr[index]`.
struct IndexAction {
  static constexpr auto Kind = InstKind::IndexAction.Define<Parse::NodeId>(
      {.ir_name = "index_action",
       .expr_category = ActionExprCategory(ExprCategory::Dependent),
       .constant_kind = InstConstantKind::InstAction,
       .is_lowered = false});

  TypeId type_id;
  MetaInstId operand_id;
  MetaInstId index_id;
};

// An action that dereferences a template-dependent operand, `*expr`, or the
// base of `expr->member` when `is_arrow`.
struct PointerDereferenceAction {
  static constexpr auto Kind =
      InstKind::PointerDereferenceAction.Define<Parse::NodeId>(
          {.ir_name = "pointer_dereference_action",
           .expr_category = ActionExprCategory(ExprCategory::Dependent),
           .constant_kind = InstConstantKind::InstAction,
           .is_lowered = false});

  TypeId type_id;
  MetaInstId pointer_id;
  BoolValue is_arrow;
};

// An action that accesses a tuple element of a template-dependent operand,
// `expr.N`.
struct TupleIndexAction {
  static constexpr auto Kind = InstKind::TupleIndexAction.Define<Parse::NodeId>(
      {.ir_name = "tuple_index_action",
       .expr_category = ActionExprCategory(ExprCategory::Dependent),
       .constant_kind = InstConstantKind::InstAction,
       .is_lowered = false});

  TypeId type_id;
  MetaInstId tuple_id;
  MetaInstId index_id;
};
```

<!-- google-doc-style-resume -->

`BoolValue` is already an operand kind of actions (`CallAction`), and
`OperandDependenceInSpecific` handles it (action.cpp:101-108). The
`PerformAction` declarations come from the X-macro in action.h.

**check/pointer_dereference.{h,cpp}.** `PerformPointerDereference` takes an
enum `PointerDereferenceKind { Star, Arrow }` instead of the diagnostic
callback, and emits `DerefOfNonPointer` (with the `DerefOfType` note for
`type`) or `ArrowOperatorOfNonPointer` itself; the two `CARBON_DIAGNOSTIC`s
move there from handle_operator.cpp:387-399 and handle_name.cpp:53-60
unchanged (texts, kinds and token-only locations), so every existing golden's
STDERR is byte-identical. At its top:

<!-- google-doc-style-ignore -->

```cpp
auto base_type_id = context.types().GetUnqualifiedType(
    context.insts().Get(base_id).type_id());
if (!context.types().Is<SemIR::PointerType>(base_type_id) &&
    OperandDependence(context, base_type_id) ==
        SemIR::ConstantDependence::Template) {
  // Proposal 2200: a dereference of a template-dependent operand is checked
  // when the template is instantiated.
  return AddDependentActionSplice<SemIR::PointerDereferenceAction>(
      context, loc_id,
      {.type_id = SemIR::InstType::TypeId,
       .pointer_id = base_id,
       .is_arrow = SemIR::BoolValue::From(kind == PointerDereferenceKind::Arrow)},
      SemIR::TypeInstId::None);
}
```

<!-- google-doc-style-resume -->

and `PerformAction(Context&, SemIR::LocId, SemIR::PointerDereferenceAction)`
calls `PerformPointerDereference` with the recorded kind. The definition
check runs before `ConvertToValueExpr`, so an action records the unconverted
operand and the conversion happens on instantiation.

**check/handle_operator.cpp `&`.** The handler's body becomes
`PerformAddrOf(context, node_id, value_id)` in a new
check/pointer_dereference.cpp function (beside its sibling), which, when
`GetExprCategory(value_id)` is `Dependent`, returns
`AddDependentActionSplice<SemIR::AddrOfAction>` and otherwise runs today's
code (:274-293) unchanged. `PerformAction(..., AddrOfAction)` calls it.

**check/member_access.cpp `PerformTupleAccess`.** At its top, before
`ConvertToValueOrRefExpr`: if the operand's type is template dependent and
not a `TupleType`, return `AddDependentActionSplice<TupleIndexAction>`;
`PerformAction(..., TupleIndexAction)` calls `PerformTupleAccess`.

**check/handle_index.cpp.** The `IndexExpr` handler's body after popping the
operands becomes `PerformIndex(context, node_id, operand_inst_id,
index_inst_id)`, which first converts the operand with
`ConvertToValueOrRefExpr` (as today) and, if its type is template dependent
and not an `ArrayType`, returns `AddDependentActionSplice<IndexAction>`;
otherwise it runs today's switch (:162-215) unchanged.
`PerformAction(..., IndexAction)` calls `PerformIndex` with the action's
`LocId`; `LiteralSubscriptTargetType` (the fork's slices R-5 probe) then runs
on the concrete type, as for a non-template index.

**check/call.cpp `PerformCallHelper` (measured).**

<!-- google-doc-style-ignore -->

```diff
                               bool is_desugared) {
+  // A function's type has one value, the function (proposal 2875), so a
+  // callee of function type with no constant value, such as a template's
+  // parameter `h: G` once `G` is `<type of F>`, calls that function. The
+  // callee expression has already been evaluated; only its value is replaced.
+  if (!context.constant_values().Get(callee_id).is_constant()) {
+    auto callee_type_id = context.insts().Get(callee_id).type_id();
+    if (context.types().Is<SemIR::FunctionType>(callee_type_id)) {
+      callee_id = AddInst<SemIR::StructValue>(
+          context, loc_id,
+          {.type_id = callee_type_id,
+           .elements_id = SemIR::InstBlockId::Empty});
+    }
+  }
+
   // Try treating the callee as a function first.
```

<!-- google-doc-style-resume -->

(The prototype also tested `has_value()`; `is_constant()` is false for
`None`, so the single test suffices.)

### §2.4 Commit C4: class-argument deduction and deferred impl lookup

**check/call.cpp `IsCallPerformable` (measured).**

<!-- google-doc-style-ignore -->

```diff
   if (OperandDependence(context, callee_id) ==
       SemIR::ConstantDependence::Template) {
     return false;
   }
+  // A generic class, interface or named constraint applied to arguments forms
+  // a type. Its arguments are compile-time values that can be symbolic, as in
+  // a checked generic, so a template-dependent argument value makes the type
+  // dependent without making the call dependent; only an argument whose type
+  // is template-dependent defers the call. Forming the type now is what lets
+  // `Holder(T)` in a parameter's type deduce `T`.
+  bool forms_type = context.types().IsOneOf<
+      SemIR::GenericClassType, SemIR::GenericInterfaceType,
+      SemIR::GenericNamedConstraintType>(
+      context.insts().Get(callee_id).type_id());
   for (auto arg_id : arg_ids) {
-    if (OperandDependence(context, arg_id) ==
-        SemIR::ConstantDependence::Template) {
+    auto dependence =
+        forms_type
+            ? OperandDependence(context, context.insts().Get(arg_id).type_id())
+            : OperandDependence(context, arg_id);
+    if (dependence == SemIR::ConstantDependence::Template) {
       return false;
     }
   }
```

<!-- google-doc-style-resume -->

After SC-1 lands, its +14 lines in call.cpp are in `PerformCallToFunction`,
not here (dry run applies with an 8-line offset).

**check/impl_lookup.cpp (measured).** In `EvalLookupSingleFinalWitness`,
after the `impl_lookup_no_symbolic_final_lookups` early return (:1250-1254):

<!-- google-doc-style-ignore -->

```cpp
  // Proposal 2200: impl lookup for a template-dependent query is performed
  // when the template is instantiated; no impl is selected in the definition,
  // not even a final one whose requirements could be proven only then.
  if (context.constant_values().GetDependence(query_self_const_id) ==
      SemIR::ConstantDependence::Template) {
    return SemIR::ConstantId::None;
  }
```

<!-- google-doc-style-resume -->

and in `LookupImplWitness`'s loop, before the `FindNonFinalWitness` test
(:1080-1087):

<!-- google-doc-style-ignore -->

```cpp
    // Proposal 2200: the deferred `LookupImplWitness` is the witness of a
    // template-dependent query, whether or not a candidate impl can be shown
    // to apply in the definition.
    if (context.constant_values().GetDependence(req_impl.self_facet_value) ==
        SemIR::ConstantDependence::Template) {
      result_witness_ids.push_back(result_witness_id);
      continue;
    }
```

<!-- google-doc-style-resume -->

### §2.5 Commit C5: member lookup into a constrained template parameter

**check/member_access.cpp (measured on trunk; re-expressed over SC-1 at the
merge).** `PerformAction(AccessMemberAction)` becomes:

<!-- google-doc-style-ignore -->

```cpp
auto PerformAction(Context& context, SemIR::LocId loc_id,
                   SemIR::AccessMemberAction action) -> SemIR::InstId {
  // Proposal 2200: a member of a template-dependent operand is looked up in
  // the argument's type and in the template parameter's constraint; if both
  // find it, they must find the same entity.
  auto constraint_member_id = LookupMemberInTemplateConstraint(
      context, loc_id, action.base_id, action.name_id);
  if (!constraint_member_id.has_value()) {
    return PerformActionHelper(context, loc_id, action.base_id, action.name_id,
                               /*required=*/true);
  }
  auto type_member_id = PerformActionHelper(
      context, loc_id, action.base_id, action.name_id, /*required=*/false);
  if (!type_member_id.has_value() ||
      type_member_id == SemIR::ErrorInst::InstId) {
    return constraint_member_id;
  }
  if (constraint_member_id != SemIR::ErrorInst::InstId &&
      !SameMemberEntity(context, type_member_id, constraint_member_id)) {
    CARBON_DIAGNOSTIC(TemplateMemberLookupAmbiguous, Error,
                      "member name `{0}` names different entities in type {1} "
                      "and in its constraint {2}",
                      SemIR::NameId, SemIR::TypeId, SemIR::TypeId);
    context.emitter().Emit(loc_id, TemplateMemberLookupAmbiguous,
                           action.name_id, <the argument type>,
                           <the constraint facet type>);
    return SemIR::ErrorInst::InstId;
  }
  return type_member_id;
}
```

<!-- google-doc-style-resume -->

`LookupMemberInTemplateConstraint` (about 45 lines, measured): if the
refined operand is a `SpecificInst` whose inner instruction's type is a
`FacetAccessType`, take the facet value's constant in the specific; if its
type is a constrained facet type, append the facet type's lookup scopes
(`AppendLookupScopesForConstant` with the facet value as self), probe
`LookupQualifiedName(..., /*required=*/false)`, and if the name is found,
return `PerformInstanceBinding(base, LookupMemberNameInScope(..., facet type
constant, scopes, /*lookup_in_type_of_base=*/true, /*required=*/true))`.
`SameMemberEntity` compares `GetCallee`'s `CalleeFunction` (function and
enclosing specific) when both are functions, else the constant values. The
emit's two type arguments are the operand's type in the specific and the
facet type; the prototype emitted a `context.TODO` instead because the new
diagnostic kind needs diagnostics/kind.def (an X-macro list). Over SC-1, the
calls go to SC-1's `LookupMemberNameInTypeScopes` (with its `diagnose` and
`AccessInfo` arguments), so a template constraint's structural requirement
found in the constraint is mapped to the type's own member before the
comparison.

### §2.6 Commit P: conformance programs

Eight programs, each beginning with the license comment, `//
CONFORMANCE-BULLET: Generics: Integrated templates`, the EXPECT lines of
§1.10 and a comment that states the forms, the derivation and the DD-1 fixture
it supersedes. Bodies are `$P/progs/*.carbon` (parse-checked with the trunk
toolchain, `--phase=parse`, zero errors each); the C++ oracle is
`$P/progs/templates_return_aggregates.diff.cpp` (license header, C++17,
`printf("%d\n", ...)` as fork/conformance/README.md requires). One body is
given in full as the template for the others' shape:

<!-- google-doc-style-ignore -->

```carbon
// CONFORMANCE-BULLET: Generics: Integrated templates
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   4
//   7
//   8
//
// Proposal 2200 ("Use of dependent value is dependent"): `*`, `->` and `&` on
// a template-dependent operand are checked when the template is instantiated
// (DD-1 fixtures X13, X14, X15). Deref(&n) reads n = 4; Next(link) reads
// link.p->n = node.n = 7; Bump(ref node) adds 1 to node.n through &node.n and
// returns 8.

import Core library "io";

class Node {
  var n: i32;
}

class Link {
  var p: Node*;
}

fn Deref[template T: type](p: T) -> i32 {
  return *p;
}

fn Next[template T: type](x: T) -> i32 {
  return x.p->n;
}

fn Bump[template T: type](ref x: T) -> i32 {
  let q: i32* = &x.n;
  *q += 1;
  return x.n;
}

fn Run() -> i32 {
  var n: i32 = 4;
  Core.Print(Deref(&n));
  var node: Node = {.n = 7};
  let link: Link = {.p = &node};
  Core.Print(Next(link));
  Core.Print(Bump(ref node));
  return 0;
}
```

<!-- google-doc-style-resume -->

fork/conformance/README.md gains eight rows after :293 (`run`; the
differential one `run, diff`), and `runner.py --self-test` is run (R7).

### §2.7 Golden sources (AUTOUPDATE, no CHECK lines)

New check goldens, each `// INCLUDE-FILE:
toolchain/testing/testdata/min_prelude/full.carbon` unless noted, splits
named as below:

-   check/testdata/generic/template/initialize.carbon (C1): `return_tuple`,
    `return_struct`, `return_array`, `class_method_return_tuple`,
    `return_param_tuple` (PR-AK), `copy_struct` (X18), `returned_var_tuple`
    (s30), `value_param_return_tuple` (s22), `destructure_param` (X33),
    `destructure_member` (s34).
-   check/testdata/generic/template/for_range.carbon (C1): `range_param`
    (no call), `range_param_called_array`, `range_member_array`,
    `range_core_range`, `range_dependent_bound` (`array(i32, N)`).
-   check/testdata/generic/template/fail_todo_import.carbon (C2, `//
    INCLUDE-FILE: toolchain/testing/testdata/min_prelude/none.carbon`):
    split files `lib.carbon` (`library "[[@TEST_NAME]]"` defining a template)
    and `fail_todo_import_use.carbon` importing and calling it.
-   check/testdata/function/call/fail_todo_template_form.carbon (C2, under
    min_prelude/form.carbon): `template Fm: Core.Form`.
-   check/testdata/generic/template/pointer.carbon (C3): `deref_param`,
    `arrow_member`, `addr_of_member`, `deref_pointer_param` (s14, eager,
    unchanged shape), `fail_deref_non_pointer_on_instantiation`.
-   check/testdata/generic/template/index.carbon (C3): `tuple_index_param`,
    `array_index_param`, `class_member_array_index`,
    `fail_tuple_index_non_tuple_on_instantiation`,
    `fail_index_non_indexable_on_instantiation`.
-   check/testdata/generic/template/call.carbon (C3): the renamed split and
    a new `dependent_call_two_callees`.
-   check/testdata/generic/template/deduce_class_args.carbon (C4):
    `holder`, `holder_pointer`, `template_class_value`, `template_class_type`.
-   check/testdata/generic/template/default_init.carbon (C4): `var_uninit`,
    `class_method_var_uninit`, `fail_var_uninit_tuple_on_instantiation`.
-   check/testdata/generic/template/constraint_lookup.carbon (C5):
    `constraint_only`, `extend_impl_same_entity`, `type_only_member`, `field`,
    `fail_different_entities` (X21).

New lower goldens (`toolchain/lower/testdata/template/`): `initialize.carbon`
(C1: the PR-AK split, whose IR must store into `%return`, plus
`return_tuple`, `class_method_return_tuple` and `destructure_param`),
`for_range.carbon` (C1: `range_param_called_array`), `pointer_index.carbon`
(C3), `dependent_call.carbon` (C3).

### §2.8 Records texts (commit D; row in commit R)

**W-014 notes, appended** (dated): "TP-1 (fork/templates/plan.md): the
template crashes and the miscompile DD-1 measured (X28 to X33, PR-AK) and the
sweep's (plan §0.6) are fixed at their root causes (plan §0.3: storage of
template-dependent initializers, splices read in the specific, the cursor
pointer's completeness); `*`, `->`, `&`, tuple element access, indexing and
calls of a function-typed value are deferred to instantiation by four new
actions and the callee rule of p2875; member lookup consults the constraint
(W-183), deduction sees through class arguments (W-193), and impl lookup for
template-dependent queries is deferred (W-127). Three of the four
generic/template `fail_todo` splits flip (unimplemented.carbon's two,
call.carbon's); member_out_of_line.carbon `fail_todo_basic` stays (W-254), so
the first arbiter clause is not met and W-014 stays OPEN for it. The pattern
splices of the title are the forms feature (W-255); cross-library templates
are W-250." Evidence re-cited to the post-merge lines.

**W-183** (discharged): "DISCHARGED by TP-1: on instantiation a member of a
template-dependent operand is looked up in the argument type and in the
parameter's constraint (member_access.cpp `PerformAction(AccessMemberAction)`);
R09 runs (25) and X21's `x.F()` is rejected with
`TemplateMemberLookupAmbiguous`; templates.md's limit is replaced by a dated
note (plan §2.9)."

**W-192** (discharged): "DISCHARGED by TP-1: a template-dependent copy is
deferred with its storage (convert.cpp `AddConvertActionIfDependent`), so a
struct is copied by the builtin aggregate conversion on instantiation (X18
runs); an index into a template-dependent operand is an `IndexAction`, so an
array is indexed by `ArrayIndex` (X19, X24 run)."

**W-193** (discharged): "DISCHARGED by TP-1: a generic type constructor
applied to template-dependent argument values forms its type in the definition
(call.cpp `IsCallPerformable`), so deduction matches `Holder(T)`,
`Holder(T)*` and `Vec(N)` (X25 and PR-AJ's forms run)."

**W-127** (discharged): "DISCHARGED by TP-1: impl lookup for a
template-dependent query selects no impl in the definition and keeps the
deferred witness (impl_lookup.cpp), so `var y: T;` resolves
`DefaultOrUnformed` on instantiation (X20, X23 run); the pin's split loses its
`fail_todo_` prefix."

Residues W-250 to W-258 are filed with §1.13's texts, each with evidence
file:line and a break condition. **Row (commit R)**: the "Generics: Integrated
templates" row stays PARTIAL; its text becomes "Template functions and
classes are checked and lowered per instantiation, including dependent
initialization, copies, returns of tuples, structs and arrays, destructuring,
`for` loops, `*`, `->`, `&`, tuple element access, indexing, calls of
function-typed values, constraint lookup (proposal 2200) and deduction
through class arguments (TP-1, plan fork/templates/plan.md); residue:
templates across libraries (W-250, diagnosed), out-of-line redeclarations
with dependent types (W-254, generic/template/member_out_of_line.carbon
`fail_todo_basic`), `partial T*` (W-251), `match` on dependent values (W-252),
arrays with a dependent bound from a list (W-253) and template form parameters
(W-255, diagnosed)." The header count is unchanged.

**Decision log, entry "TP-1: integrated templates (2026-10-14 plan)"**, newest
first, with D-TP-1 to D-TP-22 one line each and the veto digest.
**ORCHESTRATION** stamp: TP-1's PR, head, expected conformance and position.

### §2.9 Land-time integration with PR 58 (commit L)

After PR 58 is on trunk and merged into the branch:

1.  docs/design/templates.md "Templates in the 0.1 toolchain": after the
    paragraph that ends "and returning a tuple." a dated note is added:
    "> **Fork note (TP-1, <date>).** Since this list was measured, the
    toolchain also resolves for each instantiation the pointer operators
    `*`, `->` and `&`, tuple element access, indexing, struct copies, calls
    of a value whose type is a template parameter, `for` loops over a
    template-dependent range, returning a tuple, struct or array built from a
    template parameter, destructuring a template-dependent tuple, `var y:
    T;`, member lookup into a constrained template parameter and deduction
    through a class's arguments; the limits below that say otherwise are
    marked resolved." Each such limit bullet keeps its text and gains "
    (Resolved by TP-1, <date>: the form compiles and runs; fixture
    X<nn>.)" -- dated amendments, never deletions -- and the two
    "Stopping the compiler, or compiled wrongly" items gain the same. The
    W-183 bullet gains "(Resolved by TP-1, <date>: the constraint is
    consulted, and a name the type and the constraint give different
    meanings is rejected when `G` is instantiated; fixtures R09 and X21.)"
2.  fork/designdocs/samples/: X13 to X19, X20, X23, X24, X25, X28 to X33
    become `EXPECT-STDOUT` fixtures: `import Core library "io";` is added, `fn
    Use()` becomes `fn Run()` printing the value the fixture's header derives
    (X13 `4`, X14 `4`, X15 `4`, X16 `5`, X17 `8`, X18 `5`, X19 `2`, X20 `5`,
    X23 the `Peek` of a `{.top = 6}` stack `6`, X24 `8` for `(8, 9)`, X25
    `42`, X28 `6` with a call added, X29 `8`, X30 `10`, X31 `8`, X32 `6`, X33
    `9`), and each `QUOTE` becomes "Resolved by TP-1" (present in the page by
    step 1). X21 becomes `EXPECT-ERROR: unable to monomorphize specific
    ``G(C as A)``` with the QUOTE of the W-183 bullet's amendment. R09 is a
    block fixture: its page block stays (the page keeps it as the example of
    the resolved limit) and the fixture becomes `EXPECT-STDOUT` only if PR
    58's checker allows a block fixture to run (`fn Use` has no `Run`);
    otherwise R09's `EXPECT-ERROR` line is replaced by an `EXPECT-STDOUT`
    fixture X34 with a `Run`, and R09 stays a block whose header says it now
    compiles (the implementer reads check_samples.py's `BLOCK` rules at land
    time and picks the variant the checker accepts).
3.  `python3 fork/designdocs/check_samples.py` and `--toolchain
    <TP-1 install>/bin/carbon` both pass; R31 counts recorded before and
    after.
4.  W-183, W-192 and W-193 on the merged ledger receive §2.8's texts (PR 58
    filed them, so they exist only after the merge).

## §3 Commits (one PR, "TP-1: integrated templates", R29(b))

**D-TP-22.** Five implementation commits, each followed by its fill commit
when it changes or adds goldens, then the programs commit P, the row commit R,
the discharge D after the implementation reviews, and the land-time
integration L. Each implementation commit compiles alone, and its gate is
judged on the commit plus its fill: alone it is red exactly on the goldens it
adds or refills (§4) and on nothing else, with no crash. _Break condition:_ a
commit cannot compile without a later commit's files, which merges the two.

0.  **Plan.** Rev 1, "TP-1 plan (rev 1): integrated templates: crashes,
    dependent forms, splice lowering"; revs 2 and 3 fold the two reviews.
1.  **C1** "TP-1 (1): template-dependent initializers keep their storage;
    lowering reads the specific" (A1 to A6, B1 to B5; the C1 goldens). F1.
2.  **C2** "TP-1 (2): cross-library templates and template form parameters
    are diagnosed" (import_ref.cpp, handle_binding_pattern.cpp; two goldens).
    F2.
3.  **C3** "TP-1 (3): dependent dereference, address-of, tuple element
    access, indexing and calls are checked on instantiation" (four action
    kinds, pointer_dereference.{h,cpp}, handle_operator.cpp, handle_name.cpp,
    member_access.cpp, handle_index.cpp, call.cpp's callee rule; goldens and
    the unimplemented.carbon and call.carbon flips). F3.
4.  **C4** "TP-1 (4): class-argument deduction and deferred impl lookup for
    templates" (call.cpp `IsCallPerformable`, impl_lookup.cpp; goldens and
    refills). F4.
5.  **C5** "TP-1 (5): member lookup into a constrained template parameter
    consults the constraint" (member_access.cpp, diagnostics/kind.def; the
    constraint_lookup golden). F5.
6.  **P** "TP-1 (6): conformance programs for integrated templates" (eight
    programs, one `.diff.cpp`, README rows).
7.  **R** "TP-1: row" (gap-analysis row text; header unchanged).
8.  **D** "TP-1 discharge" (ledger, residues, decision log, ORCHESTRATION,
    the plan's landed notes) after the two implementation reviews and their
    fold.
9.  **M** the merge of trunk (after PR 59), with SC-1 composition per §0.9,
    then a fill F6 if the merge changes goldens.
10. **L** "TP-1: integration with PR 58" (§2.9).

**Fix commits and the shrink line.** TP-1 is about VA-1's size in toolchain
code: the measured v8 patch is 13 files and about 300 changed lines; C3 adds
four action kinds (about 150 lines) and C5 a diagnostic kind; VA-1 needed
three fix commits, OV-1 four. Budget: three fix commits after the first
build and the implementation reviews, each its own commit with its own fill,
never an amend. Shrink line, in order, for a build that cannot be made to work
in that budget: first C5 (W-183) leaves the PR and W-183 stays open with the
v5 prototype recorded in its notes; then C3's `TupleIndexAction` and
`IndexAction` (X16, X19, X24 keep today's errors, filed from the spares); C1
and C2 are never shrunk (R17: they remove crashes). Each shrink is a plan
revision the reviews see before it lands, and the row text loses the clause
it covered.

## §4 Testdata matrix (autoupdate fills; the fill must reproduce these lines)

Predicted key lines (by name; numbers are placeholders the fill writes):

| Golden | Split | Key line |
| --- | --- | --- |
| generic/template/initialize.carbon | return_tuple | `initialize_action %x.ref..., %T..., %tuple.elem0...` in the definition for each element, no `convert_to_category_action` with `element11` |
| same | return_param_tuple | `initialize_action %p.ref, %T, %return.param, false [template]` |
| same | copy_struct | no STDERR; the specific's `initialize_action` resolves to `struct_init` |
| same | destructure_param | `convert_to_value_action` (not `convert_to_category_action ..., element1`) for the bindings |
| generic/template/for_range.carbon | range_param | no STDERR; `require_complete_type %ptr` in the definition |
| lower/testdata/template/initialize.carbon | return_param_tuple | the `Id((i32, i32))` specific stores both fields into `%return` (no `alloca` that is never read) |
| generic/template/fail_todo_import.carbon | fail_todo_import_use | `error: semantics TODO: Unsupported: using a template from another library`, `error: use of undefined generic function` |
| function/call/fail_todo_template_form.carbon | the split | `semantics TODO: template form parameter` |
| generic/template/pointer.carbon | fail_deref_non_pointer_on_instantiation | ``error: unable to monomorphize specific`` with note ``cannot dereference operand of non-pointer type `i32` `` |
| generic/template/index.carbon | fail_tuple_index_non_tuple_on_instantiation | note ``type `i32` does not support tuple indexing`` |
| generic/template/unimplemented.carbon | deref_dependent_member (renamed) | `pointer_dereference_action ..., false [template]`, no STDERR |
| generic/template/call.carbon | dependent_call_nonconst_arg (renamed) | no STDERR |
| generic/template/constraint_lookup.carbon | fail_different_entities | ``unable to monomorphize specific `G(C as A)` `` with note ``member name `F` names different entities in type `C` and in its constraint `A` `` |
| generic/template/default_init.carbon | fail_var_uninit_tuple_on_instantiation | note ``cannot access member of interface `Core.DefaultOrUnformed` in type `(i32, i32)` `` (measured v7 text) |
| generic/template/convert.carbon | refill | `convert_to_value_action` in place of `convert_to_category_action ..., element1`; `class_type @A, @A(%T) [template]` in place of `call_action (%A.generic, %T)` |
| facet/period_self.carbon | fail_todo_period_self_in_generic_argument | first error `NestedWhereInsideWhere` (measured) |
| interop/cpp/range_for.carbon | refill | `require_complete_type %ptr...` lines (34 measured) |

Refills by name: generic/template/convert.carbon, unimplemented.carbon,
call.carbon, class/destroy_calls.carbon, facet/period_self.carbon,
interop/cpp/template/generic_call.carbon, interop/cpp/range_for.carbon,
lower/testdata/template/class.carbon; at land time PR 51's
dependent_var_full_prelude.carbon and any golden SC-1 or VA-1 add under
generic/template/ that the merge touches.

## §5 Conformance delta (from the floor of record, 128 PASS / 0 FAIL / 22 SKIP over 150)

Measured on v8: 128/0/22 over 150, no program changes status (TP-1's
fixes alter no existing program's output). TP-1 adds eight programs, all
PASS: expected 136/0/22 over 158 on trunk plus TP-1 alone, the bullet already
PASS (its programs are not all SKIP). Against the merge order, the floor at
TP-1's landing is PR 59's expected state plus every earlier PR (PR 59's
own record: 137/0/21 over 158 against its base), so the expected landing
count is that floor plus eight PASS; the discharge records the measured
numbers. No program moves from SKIP to PASS because of TP-1 (PR 51 already
un-SKIPs templates_dependent_member).

## §6 Churn and collisions

Golden churn: §4's refills (eight files on trunk) plus the new goldens.
Collisions: §0.9. The one textual conflict predicted with SC-1 (convert.cpp
`PerformAction(ConvertAction)`) composes as stated there. C3's and C5's
X-macro additions are append-only lines beside SC-1's and VA-1's. PR 58's
integration is confined to commit L.

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

1.  The four actions of C3 were not relinked. _Falsifier:_ C3's build plus F3
    show a golden other than unimplemented.carbon changing outside the new
    files, or a non-template program changing. Mitigation: the creation
    conditions are the exact cases trunk rejects (§1.3).
2.  D-TP-12 changes impl selection for template-dependent queries
    everywhere. _Falsifier:_ the gate shows a template golden other than
    v7's two changing, or a template program changing output. Measured: none
    in 1942 goldens and 150 programs.
3.  D-TP-11 forms dependent class types eagerly; a generic class whose
    definition depends on a template argument's value is completed in the
    definition. _Falsifier:_ an instantiation diagnostic moves to the
    definition in a golden (measured: none).
4.  SC-1's member_access.cpp rewrite moves before TP-1 lands. _Falsifier:_
    the §0.9 dry run, repeated at M, fails more hunks than predicted;
    response: C5 is re-expressed over the merged file in a fix commit.
5.  A template-dependent `&` of a value now waits for instantiation, where
    its `AddrOfNonRef` becomes a note. This is TR-3's behavior, not a risk to
    correctness.

### §7.2 Rejected alternatives

1.  **Turn every crash into a `semantics TODO`.** Rejected: a Goodhart
    alternative (R16, R17). It would make the fixtures and the gate green
    while the forms that proposal 2200 makes valid still fail; the root
    causes (§0.3) are four lines of storage bookkeeping and five category
    reads, cheaper than the guards. Only the two forms outside proposal 2200's
    slice get TODOs (D-TP-14, D-TP-15).
2.  **Cherry-pick upstream 947c1eb52 to make X31 run.** Rejected: a 131-file
    language change (array as a class) that leaves X29 and X30 crashing.
3.  **Cherry-pick upstream 4a8993af2 as C0.** Rejected by measurement (v10:
    every template `for` loop CHECK-fails with this slice's fix); D-TP-3.
4.  **Defer every form through `HandleAction` (defer when any operand is
    template dependent).** Rejected: it changes the SemIR of every template
    that dereferences a `T*` or indexes an `array(T, N)`, which work today,
    for no behavior gain (§1.3).
5.  **W-183 at the definition only (look the name up in the constraint when
    the template is defined, and use it).** Rejected: proposal 2200 looks in
    both and requires agreement (:440-441, :476-503); the constraint-only
    result would silently call `I.F` where the type's own `F` differs.
6.  **W-127 by accepting the deferred witness only (v6).** Rejected by
    measurement: a final impl is selected in the definition with an unproven
    requirement.
7.  **Fix W-254 here by making action constants structurally canonical.**
    Rejected for this slice: redeclaration matching of dependent types
    touches merge.cpp's comparison, which SC-1 rewrites (+137 on SC-1).

## §8 Verification and discharge

1.  **Build** (implementer): the container arbiter's
    `carbonbuild/build.sh /home/user/carbon-tp` and `install.sh`, after each
    implementation commit; `-Werror` clean.
2.  **Autoupdate to its fixpoint** (R26): `autoupdate.sh` on the commit's new
    and refilled goldens, a second pass loc-number-only, then the gate.
3.  **Gate**: `gate.sh`: the commit alone red exactly on §4's files for it;
    with its fill, every file passes (trunk 1942 plus the new goldens).
4.  **Conformance**: `conformance.sh`: 128/0/22 plus the new programs at P;
    `runner.py --self-test` (R7).
5.  **Mutants** (each must turn a named golden or program red, and is
    reverted): M1 restore A1's early exit (initialize.carbon and
    templates_return_aggregates fail: crash); M2 drop A4's `InsertHere`
    (X32's split: lowering CHECK); M3 drop A2's block (s32's template split:
    crash); M4 restore `FindStorageArgForInitializer`'s unconditional
    `GetInstAs` (for_range.carbon `range_param`: CHECK); M5 revert B1 in
    aggregate.cpp (destructure_param: FATAL); M6 revert B2 (X32's lower
    split: CHECK); M7 revert B3 (return_tuple lower: CHECK); M8 revert A5
    (destructure_param: lowering CHECK on a symbolic splice); M9 drop A6
    (`range_param_called_array`: segfault, then with B5 the new CHECK); M10
    make D-TP-10's callee rule apply only when `has_value()` is false
    (templates_dependent_call: `CallToNonCallable`); M11 revert
    `IsCallPerformable` (deduce_class_args: `DeductionIncomplete`); M12
    remove the template branch of `EvalLookupSingleFinalWitness`
    (generic_call.carbon refill differs, v6 shape); M13 make
    `SameMemberEntity` always true (constraint_lookup
    `fail_different_entities` succeeds); M14 drop C3's
    `PointerDereferenceAction` creation (pointer.carbon: `DerefOfNonPointer`
    at the definition).
6.  **clang-tidy** on every changed `.cpp` with the repository's configuration
    (LLVM 21.1.8's clang-tidy, as VA-1 ran it); **prek** with
    `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest`
    on the changed paths to a fixpoint, with R31's heading and list counts
    before and after each markdown edit.
7.  **Land-time integration**: after M and L, the full build, autoupdate,
    gate, conformance, and `check_samples.py` with and without
    `--toolchain` on the merged tree.
8.  **Not run, and why**: hosted CI (GitHub Actions disabled on the
    repository); bazel and the bazel-only tests (no bazel in the container;
    gtest unit tests, lit, fuzzers, clangd-tidy's compile_commands); ASan and
    macOS/Windows; LLVM with assertions (the container's LLVM is Release); the
    owner's runner (R28).

## Hand-off notes for the implementer

-   Start from `$P/tp1-proto-v8.diff`: it applies to trunk b2576f6c3 with no
    offsets and is C1, C2's import part, C3's call.cpp part, C4 and C5's
    lookup (with a `context.TODO` where the diagnostic belongs).
-   Relink-measure C1 first: v8's numbers (gate 1934 of 1942 with eight
    refills, conformance 128/0/22, 52 of 59 runnable probes) are the
    baseline; any difference is a finding.
-   `Core.Range(n)` yields 0 to n-1; X28's fixture has no call, the program
    adds one.
-   The DD-1 checker (`check_samples.py`) runs only after PR 58 is merged into
    the branch; until then the fixtures are read from `/home/user/carbon-dd`
    and never edited there.
-   Every new diagnostic needs a `fail_` split (§2.7); the
    `TemplateMemberLookupAmbiguous` text is hand-predicted and its fill is
    the arbiter of its exact rendering.
