<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Operator export plan: Carbon operator impls as C++ operator overloads (OX-1, W-054)

**Status:** rev 1, 2026-10-14 -- the planner's draft, for the two plan reviews
of R29(c). Nothing below is implemented. Branch `claude/carbon-fork-0-1-ox`,
cut from trunk f67ab650d, whose toolchain and core sources equal the upstream
cut 0bdce60a5 (`git diff --stat 0bdce60a5 f67ab650d -- toolchain core` prints
nothing); trunk has since moved to 44761146d, a fork/ORCHESTRATION.md-only
stamp that records this workstream and its id reservation, and is not merged
into the branch. Every line number below is against f67ab650d unless a branch
is named. Every measured outcome in §0.2 was taken in this container with the
trunk build (`/home/user/carbon-build/carbon-trunk`, `carbon version` reporting
`0.0.0-0.dev+0bdce60a5`) and its file_test, the upstream nightly 2026.10.12 (an
oracle for the failure only, never for an EXPECT; R16(d), R30), and prototype
toolchains relinked from the trunk build's objects with this plan's §2.1 to
§2.4 compiled in (§0.2, setup); no toolchain was built, nothing under
/home/user/carbon-build was modified, no worktree other than this one was
touched (others were read with `git show`), and the owner's runner was not used
(R28). The spec of §2.1 to §2.4 is the prototype `v4`, byte for byte: its diff
(sha256 68762c67…a3fa37 over the four files) compiled with the trunk build's
flags, clang-format 21.1.8 clean, and was measured end to end.

**Item:** W-054, "Export Carbon operator impls as C++ operator overloads" (kind
missing-feature, size L, subsystem toolchain/check/cpp, blocked_by W-007).
**Milestone row:** fork/gap-analysis.md:48, "Type system: C++ interop —
exporting Carbon operator overloads into C++", MISSING, evidence "No evidence
anywhere of exporting Carbon operator impls for use from C++ (audit: 'operator
interop is one-directional')"; records refer to the row by its bullet text (R7),
because held PRs move its line. **Bullet text** (docs/project/milestones.md:129
to :132): "Operator overloading", "C++ interop:", "Exporting Carbon overloads
into C++". **Arbiter:**
fork/conformance/programs/interop/cpp_operator_export.carbon, SKIP,
EXPECT-STDOUT `42`. **Criterion:** the bullet, read under F-017 (D-OX-1,
D-OX-14): every concrete operator impl of the checking file whose interface has
a C++ overloaded-operator counterpart ([over.oper]) is usable from C++ with that
operator, and every case left out is filed with its reason.

**Outcome this plan commits to:** the arbiter un-SKIPs to PASS with its EXPECT
`42` re-derived from the program text (30 plus 12; §1.8), its body
byte-identical to the commented sketch (M-15, R6, R27); the impls of 31 `Core`
interface members across seven families (arithmetic, negation, bitwise and
shift, compound assignment, increment and decrement, comparison, indexing)
export as C++ operators — member operators when the impl's `Self` is the
exported class, non-member operators found by argument-dependent lookup when it
is not (D-OX-2, D-OX-3) — with `!=` available for an impl that keeps `EqWith`'s
default `NotEqual` (D-OX-5) and Carbon's own operator expressions unchanged
(D-OX-11, M-9, M-10); six new conformance programs, one per family plus the
non-member form, PASS with hand-derived EXPECTs (§1.8); three new goldens (two
check, one lower; 24 splits) fill by autoupdate with no existing golden changing
(M-8); F-017 is minted with a new design page,
docs/design/interoperability/operators.md, and a dated amendment to
docs/design/interoperability/README.md (D-OX-13); the row moves MISSING → DONE,
**expected, not of record** (D-OX-14), with W-202 and W-204 to W-209 filed under
it and W-203, a pre-existing defect the audit found, filed under the type-export
row; the header moves +1 DONE, −1 MISSING. Conformance: PASS +7, SKIP −1,
programs +6, bullets +1 PASS (from the floor of record 128 / 0 / 22 over 150,
48/56, to 135 / 0 / 21 over 156, 49/56, measured in the container, M-13).

**Id allocation (recorded so no workstream collides):** re-scanned for this plan
over the 76 refs `trunk`, `origin/trunk` and every local and `origin`
`claude/carbon-fork-0-1-*` branch with the command below (M-18): the ledger
maximum is W-232 (SC-1 round 9, claude/carbon-fork-0-1-sc), and no text on any
ref names W-202..W-211 or F-017 except trunk 44761146d's fork/ORCHESTRATION.md,
which records the reservation. OP-2 holds W-196..W-201 and F-016; W-190 is
unused forever; W-169 is SC-1's reserve; W-170..W-179 and W-195 are OP-1's;
W-180..W-194 DD-1's; W-212..W-231 VA-1's (F-018 if VA-1 mints one); SC-1's later
rounds take W-232 and up. **OX-1 reserves W-202..W-211** and uses W-202..W-209
(§1.10); W-210 and W-211 are spares for residues the implementation reviews
find, and an unused reserved id stays unused, never reused. **OX-1 mints fork
design id F-017** (D-OX-13). Immediately before the discharge commit writes the
ledger, the command is re-run; if any of W-202..W-211 or F-017 is taken by
then, the residues re-allocate from the maximum plus one, skipping every
reserved block (and the design id from the next free F-id), and the landed notes
say so.

```bash
cd /home/user/carbon-ox
refs=$(git for-each-ref --format='%(refname:short)' \
  refs/heads/claude/carbon-fork-0-1-* refs/remotes/origin/claude/carbon-fork-0-1-* \
  refs/heads/trunk refs/remotes/origin/trunk)
for r in $refs; do
  git show "$r":fork/inventory/work-items.json 2>/dev/null \
    | grep -oE '"id": "W-[0-9]+"' | grep -oE '[0-9]+'
done | sort -n | tail -1
for r in $refs; do git grep -l -E 'W-20[2-9]|W-21[01]|F-017' "$r" -- fork docs; done | sort -u
```

**Design authority** (each cited where used):

-   docs/design/README.md:3657-3693, "Operator overloading" under C++
    interoperability, provisional ("no design for this has been through the
    proposal process yet", :3659-3660): "Carbon types implementing an operator
    overload using an interface should get the corresponding operator overload
    in C++. So implementing `ModWith(U)` in Carbon for a type effectively
    implements `operator%` in C++ for that type" (:3666-3668); "However, there
    may be edge cases around implicit conversions or overload selection that
    don't map completely into Carbon" (:3672-3673); "they are matched according
    to which operation has the most similar semantics rather than using the
    same symbols. For example, the `^x` operation and `BitComplement` interface
    in Carbon corresponds to the `~x` operation and `operator~` function in C++"
    (:3676-3679).
-   docs/design/interoperability/README.md:350, "## TODO: The operator
    interoperability model", an empty section: the accepted design does not
    decide the export mapping, hence F-017. :212-238, "Overload resolution",
    the OV-3 amendment (F-009): an exported overload set "appears to C++ as an
    ordinary C++ overload set", resolved "under C++'s rules", "a documented
    divergence"; D-OX-15 follows it.
-   docs/design/expressions/README.md:326-358, the operator table (which
    operators exist and which are statements); arithmetic.md:214-292,
    bitwise.md:192-271, comparison_operators.md:248-271 (`EqWith`, its default
    `NotEqual` "`return not (self==u);`" at :260, "The expression `x!=y` calls
    `x.(EqWith(U).NotEqual)(y)`" at :271) and :345-380 (`OrderedWith` with
    `Compare`, which the prelude does not declare), indexing.md:46-97 (`IndexWith.At`
    and the `ref` forms), pointer_operators.md:21-36 (dereference is not an
    interface).
-   core/prelude/operators/arithmetic.carbon:24-91, bitwise.carbon:22-79,
    comparison.carbon:11-34 (`default fn NotEqual`, :14-16; "TODO: fn Compare",
    :24), index.carbon:7-10 (`At` only), deref.carbon:8-10 (`CppUnsafeDeref`,
    for imported C++ types).
-   proposals/p001178-rework-operator-interfaces.md:84-88: "The intent to
    provide a low-level interface for individual operators is directly motivated
    by the desire to provide strong interoperability with operators defined in
    C++"; p000702-comparison-operators.md:339-340: "Overriding `!=` separately
    from `==` is expected to be used to support floating-point NaN comparisons
    and for C++ interoperability";
    p001191-bitwise-and-shift-operators.md:140-143: "permitting separate
    overloading of each of the bitwise operators with custom return types. This
    should allow smooth interoperability with C++ overloaded operators".
-   docs/project/milestones.md:169, "Interfaces powering language syntax
    (operators, conversions, etc.)": the milestone names operators and
    conversions apart (D-OX-18).
-   fork/decision-log.md, "OV-3: overload-set export, documented divergence"
    (:3517 on), F-009's sub-fork F-009i (an unmappable member is omitted after
    its TODO; D-OX-9 departs from it with the reason M-9 measures), and
    rulebook R30.
-   fork/inventory/work-items.json, W-007 (the contention-file discipline:
    additive edits, sequencing), W-118 (two set members with one C++
    signature), W-109 (write-through indexing), W-045 (import-direction
    rewrites).

V-3: no accepted proposal or leads' direction is contradicted. The direction of
the export is the design overview's (:3666-3668, provisional); its form —
member or non-member, the default `!=`, the void compound assignments, the
by-value `operator[]`, the omission of unmappable impls and of conversions —
fills a silence of the accepted design (the README section is empty) and is
minted as fork design F-017 for after-the-fact veto (R29(a)). The two
divergences it documents (C++ conversions on operands, base-class member
lookup) are the overview's own caveat (:3672-3673) and follow OV-3's precedent.

## §0 Audit: what exists, what was measured, what is stale

### §0.1 Sub-feature table (verified in-tree at f67ab650d)

| # | Element | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Exported Carbon class | LANDED, lazy | toolchain/check/cpp/export.cpp:61-98 `ExportClassToCppInDeclContext` creates the `CXXRecordDecl` in the parent's mapped context and sets external lexical and visible storage (:93-95); `ExportClassToCpp` :277-311; the definition is produced by `CarbonExternalASTSource::CompleteType` (generate_ast.cpp:443-588: `final`, base, `ExportAllFieldsToCpp`, the destructor unless trivially copyable, virtual functions); every other member is produced on demand by name. |
| 2 | The name-lookup hook | LANDED; operator names unanswered | generate_ast.cpp:330-441 `FindExternalVisibleDeclsByName`: the switch on the name kind (:364-387) answers `Identifier` and `CXXConstructorName` and returns `false` for every other kind (`default:`, :385-386), operator names among them; a found Carbon entity maps through `MapInstIdToClangDeclOrType` (:202-293). |
| 3 | Function and method export | LANDED | export.cpp `FunctionInfo` :646-753 (`self_param` :682-686; `GetCppName` an identifier or a constructor name, :723-730); `BuildFunctionInfo` :774-825 exports the callee's parent scope first (:780-784), and an impl's scope is neither a namespace nor a class, so it reaches the TODO `non-class non-namespace name scope` (:157); `BuildCppToCarbonThunkDecl` :1096-1191 takes the C++ name as a parameter (:1098), creates a `CXXMethodDecl` in a record (:1148-1151) and a `FunctionDecl` elsewhere (:1167-1170), `inline`, always-inline and internal-linkage (:1185-1188); its type from `BuildCppToCarbonThunkFunctionType` :1028-1093 (`const` for `self`, `&` for `ref self`, :1080-1089); `BuildCppToCarbonThunkBody` :1209-1325 (`*this` as the first argument, :1246-1250; `return_storage` and an NRVO return, :1219-1243 and :1300-1320); `BuildCarbonToCarbonThunk` :1332-1399 generates `<name>__carbon_thunk` in the callee's parent scope (:1337-1342, :1371) and defines it with `BuildThunkDefinitionForExport` (check/thunk.cpp:385-440); `GetOrExportFunctionToCpp` :1606-1644 registers the export in `clang_decls` (:1632-1642). |
| 4 | Overload-set export (OV-3) | LANDED | generate_ast.cpp:256-289, the `OverloadSetValue` arm: each member through `GetOrExportFunctionToCpp`, delivered as one list; export.cpp:1378-1389, the `overload_index` hunk. |
| 5 | Thunk bodies | LANDED | C++ side: export.cpp:1209-1325. Carbon side: check/thunk.cpp:385-440 (`BuildThunkCall` :309-326, `PerformThunkCall` :270-302, which forms `self.(callee)` for a `self` parameter, :292-296). toolchain/check/cpp/thunk.cpp (`BuildCalleeCallExpr` :725, `BuildReturnValueStore` :810, `BuildThunkBody` :916, `BuildCatchingThunkBody` :958) is the import direction, Carbon calling C++ (§0.3 item 3). |
| 6 | Type mapping | LANDED | type_mapping.cpp:504 `MapToCppType`; :196-372 `TryMapClassType` (recognized types; otherwise `ExportClassToCpp`, :366); returns a null type, without a diagnostic, for an unmappable type (a tuple, for one). |
| 7 | Impl storage | LANDED; no index by `Self` | sem_ir/impl.h:18-104 (`self_id`, `interface`, `scope_id`, `witness_id`, `defined`); `ImplStore`'s lookup map is keyed by `(self constant, SpecificInterface)` (:249), so "every impl whose `Self` is `C`" needs a walk of `context.impls()`, as `CollectCandidateImplsForQuery` walks it (check/impl_lookup.cpp:699-726). An impl's functions are entries of its own name scope; a default member is not (M-3). |
| 8 | The import direction (the inverse table) | LANDED | check/cpp/operators.cpp:36-209 `GetClangOperatorKind` maps `Core` interface and member names to `OverloadedOperatorKind`; `FindClangOperator` :864-953 runs Clang's operator overload resolution and rejects a rewritten candidate as a TODO (:891-898). |
| 9 | Carbon's impl lookup asks C++ | LANDED | check/impl_lookup.cpp:1327-1339: for a concrete query with a C++ type among the operands, `LookupCppImpl` (cpp/impl_lookup.cpp:638-724) builds a witness from a C++ operator and it replaces any Carbon impl found; for the operator interfaces it calls `LookupCppOperator` (operators.cpp:741-862), which runs Clang's lookup on the operand types, the exported Carbon class among them (M-9, M-10). |
| 10 | `Core` operator interfaces | LANDED (prelude) | core/prelude/operators/arithmetic.carbon:24-91, bitwise.carbon:22-79, comparison.carbon:11-34 (`default fn NotEqual`; no `Compare`), index.carbon:7-10 (`At` only); no dereference interface for Carbon types (deref.carbon:8-10 is `CppUnsafeDeref`). |
| 11 | `inline Cpp` | LANDED | generate_ast.cpp:59-86 and :616-700 (the code is parsed into the file's Clang AST against the exported declarations, in place); the default language mode is C++17 (M-6). |
| 12 | Arbiter | SKIP | fork/conformance/programs/interop/cpp_operator_export.carbon, EXPECT `42`, `return 1;` guard, the body commented out. |
| 13 | Docs | SILENT | docs/design/interoperability/README.md:350, an empty "TODO" section; docs/design/README.md:3657-3693, provisional. DD-1 (claude/carbon-fork-0-1-dd) fills the README section and says the export is not implemented (§6.2). |

### §0.2 Measurements

Setup, under the planner's scratch directory (`$X` below is
`/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad/ox1`):
`$X/bin/relink.py` (the ST-1 and OP-2 relink recipe, generalized) compiles each
patched source with the `cxx`, `cflags` and per-object `extra` flags of
`/home/user/carbon-build/carbon-trunk/build.ninja`, the include root switched to
this worktree (whose headers equal the build's) and an overlay directory first
for a patched header, into `$X/tc/<variant>/obj/`, and relinks `bin/file_test`
and `bin/carbon-busybox` from the trunk build's objects with the patched objects
substituted, writing only under `$X/tc/<variant>/`. Each `install-<variant>` is
a `cp -a` of the trunk install with its busybox replaced. `bin/run.sh` compiles
one program with `--output-last-input-only` (R2), links and runs it;
`bin/mrun.sh` does the same for several units, each compiled last in turn as the
conformance runner does; `bin/ft.sh` runs a file_test in test mode over the full
manifest from this worktree with the trunk runfiles; `bin/fill.sh` previews a
new golden by substituting it for an existing manifest entry in a scratch mirror
(`interop/cpp/class/export/static.carbon` holds check `operator.carbon`,
`layout.carbon` holds `operator_ast.carbon`, lower `mangle.carbon` holds lower
`operator.carbon`), then runs two autoupdate passes and a test-mode pass.
Variants: `v1` (member operators only), `v2` (plus the default `!=` and the
Carbon-side guard), `v3` (plus non-member operators), `v4` (plus the silent
omission of unmappable impls: the spec, §2.1 to §2.4), and the mutants of M-14.
`XDG_CACHE_HOME` was a directory under `$X` for every `carbon` run.

**M-1. The arbiter's body fails on trunk and on the nightly, for one reason.**
The SKIP body, uncommented (`$X/probes/p1/op_export.carbon`), compiled with the
trunk install and with the nightly 2026.10.12
(`0.0.0-0.nightly.2026.10.12+62f1cc6`): both exit 1 with the single diagnostic

```text
op_export.carbon:20:13: error: invalid operands to binary expression ('Carbon::Meters' and 'Carbon::Meters')
   20 |   return (a + b).value;
      |           ~ ^ ~
```

What the `inline Cpp` block sees, from `carbon compile` with `--phase=check` and
`--dump-cpp-ast` on the same program with `a+b` replaced by `a.value+b.value`
(trunk): `namespace Carbon` holds `class Meters definition` with
`<undeserialized declarations>`, `DefinitionData ... aggregate standard_layout
trivially_copyable pod trivial`, a `FinalAttr`, `FieldDecl ... value 'int'
mutable`, `CXXMethodDecl ... Make 'Carbon::Meters (int)' static inline
internal-linkage` whose body calls `Make__carbon_thunk 'void (const int &, const
Carbon::Meters &)'` and returns `return_storage` by NRVO, and the implicit
trivial destructor. There is no operator declaration of any kind, and the impl's
`Op` has no C++ view: it is not a member of the class's scope, and operator
names are never answered (§0.1 rows 2 and 3). The record is complete and its
members appear on demand, so a C++ operator lookup into it is a lookup Carbon
can answer.

**M-2. Every path an exported Carbon class reaches today, and where an
operator would enter.** Read end to end (§0.1 rows 1 to 6): a class becomes a
record on first use by name or by type mapping; its fields are exported as a
group at completion or layout; a method, class function, constructor-named
function, overload set, variable or nested type is exported when Clang asks the
class or namespace for that identifier; a virtual function is declared at
completion. Not exported: anything without an identifier name (operators,
conversions), a generic member function (TODO, export.cpp:1596-1598), a
specific of a generic class's members (TODO :68-71 and the generic-class
destructor gap, generate_ast.cpp:506-518), and impls, whose functions live in
impl scopes that `ExportNameScopeToCpp` cannot map (:151-159). The C++
declaration of an exported function is built by `BuildCppToCarbonThunkDecl`
under any `DeclarationName` it is given, and its body by
`BuildCppToCarbonThunk`; both are static functions of export.cpp that take a
`FunctionInfo`, so an impl's `Op` can be exported under `operator+` by new code
that builds the `FunctionInfo` itself, without `BuildFunctionInfo`'s scope
export (M-4).

**M-3. Where an operator impl lives in SemIR.** `carbon compile` with
`--phase=check` and `--dump-sem-ir` of a class `Money` with one `i32` field and
`impl Money as Core.EqWith(Money)` declaring only `Equal`
(`$X/probes/eq/eq.sem`): the impl block holds
`%Money.as.EqWith.impl.Equal.decl`, the witness table is `impl_witness_table
(%Money.as.EqWith.impl.Equal.decl, constants.%EqWith.WithSelf.NotEqual.3da)` —
the default `NotEqual` is the interface's own function with the impl's specific,
not a function of the impl — and the impl scope's members are `.Money =
<poisoned>` and `.Equal = ...`. So a lookup of `NotEqual` in the impl scope
finds nothing, and a lookup of a name the impl's checking poisoned finds an
entry that is not `is_found()`: `v1`, which called `target_inst_id()` on such an
entry, failed `CHECK failure at toolchain/sem_ir/name_scope.h:83: is_found()` on
`a!=b` (the fix is `GetImplMemberFunctionId`'s `is_found()` test, §2.1). The
`Core` interfaces are recognized by name: `CoreIdentifier` names every operator
interface and member (check/core_identifier.def:19-97), while
`SemIR::CoreInterface` (sem_ir/core_interface_kind.def) lacks the bitwise
interfaces, `BitComplement` and `IndexWith`, so `interface.core_interface`
cannot classify them; an interface is a `Core` one when
`IsCorePackage(interface.parent_scope_id)` holds, as `GetCoreInterface` tests
(check/custom_witness.cpp:1440-1449).

**M-4. How Clang asks for an operator, and the form that answers it.** `v1`
(member operators only) failed M-3's CHECK inside the hook, and its stack is the
lookup path: `ExportOperatorsToCpp` ←
`CarbonExternalASTSource::FindExternalVisibleDeclsByName` ←
`DeclContext::lookupImpl` ← `LookupDirect` ← `Sema::LookupQualifiedName` ←
`Sema::AddMemberOperatorCandidates` ← `Sema::LookupOverloadedBinOp` ←
`Sema::CreateOverloadedBinOp`, the record being the left operand's class. With
`v3`, the same hook also receives `namespace Carbon` with the operator name from
argument-dependent lookup on an exported operand (M-7's `3*m`). Clang caches
each answer per context and name: `DeclContext::lookupImpl` returns a stored
entry without asking again once it holds no external declarations
(clang/lib/AST/DeclBase.cpp:1951-1954 in /home/user/llvm-src), so each class and
namespace is asked once per operator name. The declarations that answer are a
`CXXMethodDecl` named `DeclarationNames.getCXXOperatorName(kind)` in the record
(the member form) and a `FunctionDecl` of that name in the namespace (the
non-member form); `v1` exported the arbiter's `operator+` as `CXXMethodDecl ...
used operator+ 'Carbon::Meters (Carbon::Meters) const' inline internal-linkage`
whose body calls `Op__carbon_thunk 'void (const Carbon::Meters &, const
Carbon::Meters &, const Carbon::Meters &)'`, and the program printed `42`
(`$X/probes/p1/v1`). The generated Carbon thunk lowers as
`_COp__carbon_thunk.Meters.Main:AddWith.b69bc498d15e4c3c.Core`, mangled by the
impl's `Self` and the interface's specific (sem_ir/mangler.cpp:92-158), so two
impls of one interface never share a thunk symbol.

**M-5. How values cross.** As for an exported method (export.cpp:1006-1024,
:1209-1325): a value parameter of class type is a by-value C++ parameter
(`operator+(Carbon::Money) const`; a trivially copyable class is passed in a
register, `i32 %.coerce`, lower fill M-12), passed to the Carbon thunk by
`const&`; the result is constructed in the C++ operator's `return_storage` by
the Carbon thunk through a reference parameter and returned by NRVO; a `bool`
result is loaded (LValueToRValue, :1310-1315). A class with a user `Destroy`
(`$X/probes/edge/e9_nontrivial.carbon`: `a+b` on two `Tracked`, then the
destroy count) prints `42 4` with the operator and `42 4` with the equivalent
exported method `a.Plus(b)` on trunk (`e9b_method.carbon`): the operator
inherits the method's value passing exactly, including the by-value
parameter's copy and its destruction.

**M-6. The `inline Cpp` dialect, and what it does to `!=`.** An `inline Cpp`
function returning `__cplusplus` prints `201703` on trunk
(`$X/probes/std/std.carbon`): C++17, which never rewrites `a!=b` as `!(a==b)`.
`v1`, exporting only declared members, rejected `(a!=b)` for an impl without
`NotEqual` with `invalid operands to binary expression ('Carbon::Money' and
'Carbon::Money')` (`$X/probes/fam/fam.compile.log`). With `v2` onwards the
default `operator!=` is declared, and `e7_cxx20.carbon` (only `impl Money as
EqWith(i32)`) rejects `5==m` with `invalid operands to binary expression ('int'
and 'Carbon::Money')` under the default dialect and under
`--clang-arg=-std=c++20` alike, while `m==5` compiles: with `operator!=`
declared beside `operator==`, C++20's reversed `==` candidate is not formed.

**M-7. The prototype across every family (`v4`).** `$X/probes/fam/fam.carbon`
(member operators: `Money` with `AddWith(Money)`, `SubWith(Money)`,
`MulWith(i32)`, `DivWith(i32)`, `ModWith(i32)`, `Negate`, five compound
assignments, `Inc`, `Dec`, `EqWith` with the default `NotEqual`, `OrderedWith`;
`Bits` (a `u8`) with the bitwise, complement, shift and bitwise compound impls;
`Tri` with `IndexWith(i32)`; `Unknowable` with a declared `NotEqual`) prints
`9500450,21002331,-42,2,101110,10,8140843,300115,789,0`, each value hand-derived
in the probe's comments (950 and 450; 2100, 233 and 1; -42; the compound chain
ending at 2; the comparison digits 1 0 1 1 1 0 and 1 0; 8, 14, 6 and 243;
30, 1 and 15; 7 8 9; 0 0 for an unknown value). `$X/probes/nm/nm.carbon`
(non-member operators: `impl i32 as MulWith(Money)` with a `+ 1` marker, `i32
as EqWith(Money)` with the default `NotEqual`, `i32 as OrderedWith(Money)`,
`i32 as SubAssignWith(Money)`, `Cpp.Foo as AddWith(Money)`) prints `30 31
111110 42 42 33`, the `31` showing that `3*m` reached the `i32` impl and not
`m*3`'s. Both print the same under `--clang-arg=-std=c++20`. The AST dump
of `fam.carbon` (`v2`) lists 33 operator declarations of the shapes §1.1
tabulates, among them `operator+= 'void (Carbon::Money) &'`, `operator++
'void () &'`, `operator~ 'Carbon::Bits () const'`, `operator[] 'int (int)
const'`; `nm.carbon`'s lists `FunctionDecl ... operator* 'Carbon::Money (int,
Carbon::Money)'` and `operator-= 'void (int &, Carbon::Money)'` in `namespace
Carbon` (`v3`; `v4`'s `fam.carbon` dump lists the same 33). Probes of single
features (`$X/probes/edge/`): a class in a Carbon namespace with an `extend
impl` in its body (`e5_namespace`) prints `42` through
`Carbon::Units::Money`; a derived class whose base has the impl (`e11_base`)
prints `42` (C++ member lookup reaches the base; §1.7).

**M-8. Golden blast radius: none.** file_test in test mode over the whole
manifest (1942 files) from this worktree: trunk 1942 passed; `v1`, `v3`,
`v3`-final and `v4`, 1942 passed each (`$X/ft-*.log`, `.failed` lists empty).
No existing golden applies a C++ operator to an exported Carbon class, and none
evaluates a Carbon operator whose operands mix a C++ type with a Carbon class
that has an operator impl (the only paths §2 reaches), so no existing golden
gains or loses a line; §4 lists no refills.

**M-9. A Carbon-only regression the first cut had, and the fix.** Carbon's impl
lookup asks C++ whenever an operand is a C++ type (§0.1 row 9), and Clang's
operator lookup then asks the exported Carbon class (M-4). With `v3`, which
exported an unmappable impl after its per-function TODO (the OV-3 policy),
`$X/probes/side/side2.carbon` — `impl Money as Core.AddWith(Cpp.Foo) where
.Result = (i32, i32)` and the Carbon-only function `CarbonSide`, which returns
`(m+f).0` — fails with `side2.carbon:7:3: error: semantics TODO: 'failed to map
Carbon return type to C++ type'`; trunk accepts it. `v4` omits an impl whose
signature does not map before building anything (`IsOperatorSignatureMappable`,
§2.1) and accepts it; the split `carbon_side_unmappable` pins it (M-12).

**M-10. Carbon operator expressions keep calling the impl.** With `v1`,
`$X/probes/mixed/mixed.carbon`'s Carbon function `m+f` (`impl Money as
AddWith(Cpp.Foo)`) lowered to `call void
@_ZNK6Carbon5MoneyplE3Foo.carbon_thunk.__`: Carbon's lookup found the exported
`Money::operator+(Foo)` as the best C++ candidate and called the impl through
the C++ operator and two thunks (§0.1 row 9 replaces the Carbon witness with a
C++ one). With `v2` onwards, the guard in `FindClangOperator`
(`IsExportedCarbonOperator`, §2.4) makes it call
`_COp.Money.Main:AddWith.1ea11ae296c4d4df.Core` directly, as on trunk; the
non-member case (`Cpp.Foo as AddWith(Money)`, `nm.carbon`'s `CarbonSide`) calls
`_COp.Foo.Cpp:AddWith.7b773fb4f7cbc162.Core` directly. One side effect remains
and is accepted (§7.1 R-5): the Carbon-only `$X/probes/side/side.carbon` now
also defines the unused
`_COp__carbon_thunk.Money.Main:AddWith.1ea11ae296c4d4df.Core`, because Clang's
candidate search exported the operator before the guard discarded it.

**M-11. The edges, each measured on `v4` unless named.** (a) A generic impl,
`impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T)` (`e1_generic`):
C++ `m*3` fails `invalid operands to binary expression ('Carbon::Money' and
'int')`; Carbon's `m*3` compiles. (b) An impl declared after the `inline Cpp`
block that uses it (`e3_after`): `invalid operands`, as C++ itself would reject
a use before the declaration. (c) A second impl of an operator declared after
C++ looked that operator up (`e4_cache`): the second block's `m+40` fails with
`invalid operands ... ('Carbon::Money' and 'int')` and a note naming only the
first impl's candidate (M-4's caching). (d) A class imported from another
library (`e6`, two units through `bin/mrun.sh`): C++ `m+m` fails `invalid
operands`, because only `context.impls()` is walked and the library's impls are
not imported (W-204); and the class itself is exported wrongly on trunk and on
the nightly — `e6b` (`.cents` of an imported class) fails `no member named
'cents' in 'Carbon::Money'`, and `e6c` (an exported method `Plus` returning the
imported class by value, then `Get()`) links, runs and prints `-1265344497` on
trunk and `-1536643875` on the nightly where 42 is right: the AST dump shows
`class Money definition ... empty aggregate`, no `FieldDecl`, so a 4-byte Carbon
result is written into a 1-byte C++ object (W-203, filed under the type-export
row; an upstream defect). (e) Two impls whose operands map to one C++ type
(`e12_samesig`, `AddWith(i64)` and `AddWith(Cpp.long)`): Carbon itself rejects
the pair (`found non-final impl with the same type structure as another
non-final impl`), and C++ reports `use of overloaded operator '+' is ambiguous`,
the W-118 shape (W-207). (f) C++'s operand conversions (`e13_conv`): C++ `m*k`
with `long k = 3` calls the `MulWith(i32)` impl and prints `42`, while Carbon's
`m*k` with `k: i64` fails `cannot access member of interface 'Core.MulWith(i64)'
in type 'Money' that does not implement that interface` (`e13b`) — the
documented divergence (§1.7).

**M-12. The new goldens fill, and fail without the feature.** `bin/fill.sh`
with `v4`'s file_test on the three new sources (§2.5): two autoupdate passes,
then test mode, 3 passed; one pass is not a fixpoint, because the AST golden's
`<line:N:...>` positions shift when the CHECK lines are inserted above them
(R26; pass 2 changes only those positions). CHECK lines written: 38 (check
`operator.carbon`, all `CHECK:STDERR` of the eight `fail_` splits), 147
(`operator_ast.carbon`), 690 (lower `operator.carbon`, with
`--clang-arg=-fno-exceptions`). The same sources under trunk's file_test: the
13 splits that must compile fail (`split ... failed; if failure is expected,
add the fail_ prefix`): arithmetic, compound_assignment, comparison, bitwise,
index, non_member, namespace, base_class, unmappable_impl, operator (the AST
golden), member, default_not_equal, carbon_side_cpp_operand;
`carbon_side_unmappable` passes on trunk, as a regression guard must, and fails
under `v3` (M-9), as does `unmappable_impl`. Every `fail_` split fails for its
intended reason (§4).

**M-13. Conformance.** Trunk, the 150 programs of record: 128 PASS / 0 FAIL /
22 SKIP, 48/56 bullets (`$X/conf-trunk`; the floor of record). `v4`, the same
programs: 128 / 0 / 22, 48/56 (`$X/conf-v4-current`). `v4`, the program tree
with §2.6 applied (`$X/progs-full`: the arbiter un-SKIPped and six new
programs): 135 PASS / 0 FAIL / 21 SKIP over 156, 49/56 bullets, the row's bullet
PASS with 7 programs (`$X/conf-full-v4`). Trunk on that tree: 128 PASS / 7
COMPILE-FAIL / 21 SKIP. `runner.py --self-test --programs $X/progs-full`: 156
programs parsed, 56 bullets, one error, the stale README program table that
commit 5 regenerates (§3).

**M-14. The programs are not vacuous.** Two mutants of `v4`'s export.cpp, each
relinked and run over the seven programs: M1 swaps the `AddWith` and `SubWith`
rows (`+` calls `SubWith`): cpp_operator_export COMPILE-FAIL,
cpp_operator_export_arithmetic OUTPUT-MISMATCH (prints
`450,950,2100,233,1,-700`), cpp_operator_export_nonmember COMPILE-FAIL. M2 drops
the `!` from the default `!=` (`!=` returns `==`): cpp_operator_export_compare
OUTPUT-MISMATCH (its second line `1` for `10`), cpp_operator_export_nonmember
OUTPUT-MISMATCH (`10` for `11`). The other programs pass under each mutant
because they do not use the mutated rows.

**M-15. The un-SKIP is the sketch.** The arbiter's commented body, uncommented,
diffed against §2.6's program from `import Core` to `fn Run`: identical, the C++
comment line included; `Run`'s body is the sketch's "Intended body" verbatim
(two lines). No mechanical repair is needed (R6), and the spelling is the
sketch's (R27).

**M-16. Collisions, by `git apply --check` of the §2.1 to §2.4 diff.** On the
four files at claude/carbon-fork-0-1-st (21307851a, PR 55): applies, two hunks
at offset 5 (its 5-line null check at export.cpp:293-300). At
claude/carbon-fork-0-1-sc (ee1f905b0), claude/carbon-fork-0-1-op2 and
claude/carbon-fork-0-1-dd: applies with no offset. At upstream/trunk 66a250ad9:
export.cpp, export.h and generate_ast.cpp apply at offsets; operators.cpp's
include hunk does not (the fork's include block differs there), a one-line
context fix at the next advance. The other files each branch touches are in
§6.2.

**M-17. Upstream has not started operator export.** In /home/user/carbon-lang,
`git merge-base 0bdce60a5 upstream/trunk` is c1e83b0b7, the true upstream cut;
`git log c1e83b0b7..upstream/trunk` lists 50 commits, four under
toolchain/check/cpp: e476a2bd3 (exporting names after a lookup failure: it
restructures `FindExternalVisibleDeclsByName` and stops caching negative
lookups), 62f1cc6a3 (`GenericClassType` renamed `ParameterizedClassType`),
947c1eb52 (`Core.Array`), ae5d1efd1 (`CalleeFunctionInfo` renamed); and
4ab46d448 renames entities for `-share-cpp-ast`. `git grep CXXOperatorName
upstream/trunk -- toolchain/check/cpp` finds only the import direction
(import.cpp:1880, thunk.cpp:400, impl_lookup.cpp:188). OX-1 uses none of the
renamed entities; its names (`ExportOperatorsToCpp`,
`ExportNonMemberOperatorsToCpp`, `IsExportedCarbonOperator`) have no upstream
counterpart to align with; e476a2bd3's change is the one to re-integrate at the
next advance (§6.3).

**M-18. Ids.** The id-allocation command above, over 76 refs: ledger maximum
W-232 (claude/carbon-fork-0-1-sc); `W-20[2-9]`, `W-21[01]` and `F-017` appear
only in trunk's and origin/trunk's fork/ORCHESTRATION.md (the reservation, and
the stale 7mwfb7 copies of the same text); F-016 is OP-2's.

**M-19. Cost, per family (`v4`, export.cpp line spans).** Shared by every
family: the table's type and header (17 lines), `IsOperatorSignatureMappable`
(23), `GetImplMemberFunctionId` (25), `ExportImplFunctionAsCppOperator` (47),
`ExportOperatorsToCpp` (66), the generate_ast.cpp arm (25) and the guard
(`IsExportedCarbonOperator` 27, operators.cpp 6): 236 lines. Per family, rows
of the table: arithmetic 5, negation 1, bitwise and shift 6, compound assignment
10, increment and decrement 2, comparison 6 plus `BuildDefaultNotEqualOperator`
(89), and one row for
indexing. The non-member form: `GetCarbonClassType` (16),
`BuildCppToCarbonNonMemberOperatorDecl` (47),
`ExportImplFunctionAsCppNonMemberOperator` (39),
`ExportNonMemberOperatorsToCpp` (82) and the 3-line condition in
`BuildCppToCarbonThunkBody`: 187 lines. Test cost: §4 (splits) and §5
(programs). Compile cost: one walk of `context.impls()` per class (or namespace)
and operator name, the first time C++ looks that name up there (M-4), and none
for a class whose operators C++ never uses.

### §0.3 Ledger and brief claims found stale (each corrected where §2 says)

1.  W-054's evidence cites `fork/gap-analysis.md:30`; the row is line 48
    (corrected at discharge, §2.8).
2.  The brief places a 5-line null check in toolchain/check/cpp/export.cpp on
    SC-1's branch; it is ST-1's (PR 55, claude/carbon-fork-0-1-st,
    ExportClassToCpp :293-300); `git diff --stat f67ab650d
    claude/carbon-fork-0-1-sc -- toolchain/check/cpp` prints nothing (§6.2).
3.  The brief describes toolchain/check/cpp/thunk.cpp's `BuildThunkBody`,
    `BuildCalleeCallExpr`, `BuildReturnValueStore` and the catching variants as
    the bodies that call Carbon functions from C++; they are the import
    direction's (Carbon calling C++). The export bodies are export.cpp's
    `BuildCppToCarbonThunkBody` and check/thunk.cpp's
    `BuildThunkDefinitionForExport` (§0.1 row 5). OX-1 edits neither thunk.cpp.
4.  Row 47's evidence and the brief credit the import direction with
    "spaceship rewrites"; a rewritten candidate is a semantics TODO
    (operators.cpp:891-898; the `fail_todo_spaceship_rewrites` and
    `fail_todo_comparison_rewrites` splits of
    toolchain/check/testdata/interop/cpp/operators/), W-045's scope.
5.  The brief lists `Deref` among the families; Carbon has no dereference
    interface for its own types (§0.1 row 10), so there is nothing to export.
6.  The brief allows `<=>` "if the imported-direction rewrite logic suggests a
    symmetric mapping"; the prelude's `OrderedWith` has no `Compare` to export
    (comparison.carbon:24), so `<=>` is W-206.
7.  W-007's notes end "Remaining contender: SC-B3 (W-029)"; OX-1 is a contender
    in export.cpp, landed by the same sequencing (§2.8 appends the record).
8.  DD-1's interoperability README (held, not on trunk) says "The other
    direction is not implemented: a Carbon type's operator interface
    implementations are not exported as C++ operators (fork work item W-054)"
    and, in "Using Carbon from C++", "Carbon operator implementations are not
    exported as C++ operators"; both sentences are replaced at OX-1's merge
    (§6.2).
9.  The commit shape the brief suggests ("toolchain and goldens in one commit if
    either alone breaks file_test") is measured, not assumed: the toolchain
    alone leaves file_test green (M-8), so they are separate commits (§3).

### §0.4 Decisions this plan auto-adopts (R29(a): the design recommendation under V-2/V-3, veto-able after the fact)

Each decision carries the one sentence that would break it.

-   **D-OX-1 (the operator set).** Exported: the members of the `Core`
    interfaces whose Carbon operator has a C++ overloadable counterpart —
    `AddWith`, `SubWith`, `MulWith`, `DivWith`, `ModWith`, `Negate`,
    `BitAndWith`, `BitOrWith`, `BitXorWith`, `BitComplement`, `LeftShiftWith`,
    `RightShiftWith`, the ten `*AssignWith` interfaces, `Inc`, `Dec`, `EqWith`
    (`Equal`, `NotEqual`), `OrderedWith` (`Less`, `LessOrEquivalent`,
    `Greater`, `GreaterOrEquivalent`) and `IndexWith.At`: 31 members, the
    inverse of the import table (operators.cpp:36-209) less what Carbon does not
    route through an interface (`AssignWith`, unused for `=`, :123-128). Not
    exported, each for a stated reason: dereference and address-of (no
    interface), `<=>` (no `Compare` in the prelude, W-206), `As` and
    `ImplicitAs` (conversions, W-208). **Breaks if** a `Core` interface of the
    prelude whose Carbon operator C++ can overload is missing from the table
    without a filed reason.
-   **D-OX-2 (member operators).** A complete, non-generic impl whose `Self` is
    exactly the exported class is a member operator of that class's record:
    `const` for a `self` member, `&`-qualified for `ref self`, by-value
    parameters, the result by value — the exported-method mapping unchanged
    (export.cpp:1028-1093). C++ then finds it by member lookup on the left
    operand only, as Carbon finds an impl by lookup on `Self` only. **Breaks
    if** C++ finds a member operator for an impl whose `Self` is not the class,
    or misses one whose `Self` is (M-7 and the `arithmetic`..`index` splits).
-   **D-OX-3 (non-member operators).** A complete, non-generic binary impl
    whose `Self` C++ does not see as an exported Carbon class (a Carbon
    primitive such as `i32`, or an imported C++ type) and whose interface
    argument is a non-generic Carbon class exported into a namespace `N` is a
    non-member operator `R operator@(S, C)` declared in `N`, so C++ finds it by
    argument-dependent lookup on the `C` operand; `operator[]` is excluded
    because C++ requires it to be a member. **Breaks if** `int-Carbon::Money`
    (or `Foo+Carbon::Money` for an imported `Foo`) does not reach the `i32`
    (or `Cpp.Foo`) impl in C++ (M-7 `nm.carbon`, the `non_member` split, the
    nonmember program).
-   **D-OX-4 (which impls).** Only impls of the checking file's
    `context.impls()`: concrete (no `generic_id`), complete at the time C++
    looks the operator up, of an interface in package `Core`. A generic impl,
    an impl on a specific of a generic class (W-202) and an impl of an imported
    library (W-204, blocked by W-203) are filed. **Breaks if** a concrete,
    complete impl of the file on an exported class is not exported.
-   **D-OX-5 (the default `!=`).** An `EqWith` impl that does not declare
    `NotEqual` gets `operator!=` built in C++ as `!(a==b)` over the exported
    `operator==`, of the same form (member or non-member); a declared
    `NotEqual` is exported as itself. That is the interface's default body,
    `not self.Equal(other)` (comparison.carbon:14-16,
    comparison_operators.md:260), and C++17, the `inline Cpp` default, has no
    rewrite to supply it (M-6). **Breaks if** C++ `a!=b` and Carbon `a!=b`
    disagree for any impl (the compare program's `Unknown` line and M-14's M2).
-   **D-OX-6 (no synthesized candidates).** Because `operator!=` always
    accompanies `operator==` (D-OX-5) and no `<=>` is exported, C++20 forms no
    reversed or rewritten candidate, so in every dialect C++ accepts exactly
    the operand orders Carbon has impls for. **Breaks if** C++ accepts `5==m`
    for a class that has only `Money as EqWith(i32)` (the
    `fail_reversed_equality` split, M-6).
-   **D-OX-7 (statements stay statements).** The compound assignments and
    `Inc`/`Dec` take `ref self`, so they export `&`-qualified and `void`, as
    Carbon's statements produce no value; only prefix `++`/`--` exist, as
    Carbon has no postfix form; `=` is not an interface operator and stays C++'s
    copy assignment. **Breaks if** C++ `a+=b` on an lvalue does not modify
    `a` (the compound program), or a temporary or `a++` is accepted (the two
    `fail_` splits).
-   **D-OX-8 (indexing by value).** `IndexWith(I).At` takes `self` and returns
    a value, so `operator[]` is a `const` member returning the element by
    value; several `IndexWith` impls form one C++ overload set. **Breaks if**
    C++ `t[i]` differs from Carbon `t[i]` for the same impl (the index program).
-   **D-OX-9 (diagnostic policy).** An impl whose signature has a type with no
    C++ mapping (or an array, which C++ cannot pass or return by value) is
    omitted without a diagnostic. This departs from OV-3's F-009i (an
    unmappable set member is omitted after its semantics TODO) for the reason
    M-9 measures: Carbon's own operator expressions with a C++ operand make
    Clang look the operator up in the exported class, so a TODO there rejects
    Carbon-only code; and C++ code cannot form an operand of an unmappable
    type, so the omission cannot change which impl a C++ expression selects,
    the hazard F-009i guards. **Breaks if** a Carbon-only expression is
    rejected because an operator impl has no C++ form (the
    `carbon_side_unmappable` split), or a C++ expression selects a different
    impl than it would with the omitted one present.
-   **D-OX-10 (thunks and symbols).** No new thunk kind: the C++ operator is
    built by `BuildCppToCarbonThunkDecl` under the operator's name, or by its
    non-member twin, and calls the generated Carbon thunk
    `<member>__carbon_thunk` in the impl's scope, which mangles by the impl's
    `Self` and interface specific
    (`_COp__carbon_thunk.Money.Main:AddWith.<specific>.Core`, M-4), so two impls
    never share a symbol; the C++ operators are inline, always-inline and
    internal to the translation unit, as exported methods are. Two impls whose
    operand types map to one C++ type are two same-signature declarations,
    ambiguous at every C++ use (W-207, the W-118 shape). **Breaks if** two
    impls' thunks mangle equal (lowering would reuse one, the OV-3 R-10
    failure).
-   **D-OX-11 (Carbon is unchanged).** An exported Carbon operator is never a
    C++ candidate for Carbon's own impl lookup: `FindClangOperator` returns
    `None` when the best viable function is one (`IsExportedCarbonOperator`),
    so the Carbon impl Carbon already found stands. **Breaks if** a Carbon
    operator expression lowers to a call through an exported C++ operator (the
    lower `carbon_side_cpp_operand` split, M-10).
-   **D-OX-12 (laziness and caching).** Operators are exported when Clang
    looks their name up in the class or namespace, and Clang keeps the answer
    (M-4), as for every exported name; an impl declared later is not seen by
    later C++ code (W-205). **Breaks if** an operator C++ looks up after its
    impl is complete is not found (the `fail_impl_after_use` and
    `fail_todo_impl_after_lookup` splits pin the two orders).
-   **D-OX-13 (F-017 and its docs).** The accepted design leaves the operator
    model empty (README :350) and the overview is provisional, so the mapping
    is fork design F-017, documented on a new page,
    docs/design/interoperability/operators.md, with a dated amendment under the
    README's operator section (§2.7); the page, not the README, carries the
    text, because DD-1 rewrites the README (+847 lines, §6.2). **Breaks if** an
    accepted upstream proposal or the leads decide the export differently
    (V-3), or upstream starts operator export (M-17's check, repeated at each
    advance).
-   **D-OX-14 (the row).** Row "Type system: C++ interop — exporting Carbon
    operator overloads into C++" moves MISSING → DONE, expected and not of
    record (R9: the run of record needs Actions), with W-202 and W-204..W-209
    filed under it as limits, under the precedents of row 82 (DONE with filed
    W-119/W-120) and of OV-3's overloading row (DONE with W-117: a set in a
    generic class exports nothing), because every concrete operator overload of
    the file is usable from C++ in both operand positions (M-7, M-13) and each
    limit is a generic, cross-library, ordering or not-yet-designed case.
    **Breaks if** a review finds a concrete same-file impl of D-OX-1's set that
    does not export, or judges W-202 or W-204 row-bounding; then the row stays
    PARTIAL with the same residues and §2.8's text changes only its status word
    and that sentence.
-   **D-OX-15 (divergences, documented).** C++ resolves an exported operator
    under C++'s rules: it converts operands (`m*3L` calls `MulWith(i32)`,
    M-11(f)) and searches base classes (`d+d` calls the base's impl, M-7), where
    Carbon's impl lookup does neither — the overview's "edge cases around
    implicit conversions or overload selection" (:3672-3673) and OV-3's
    precedent. Pinned by goldens (`arithmetic`'s `3L` assertion, `base_class`
    and `fail_base_class_carbon_side`), not by a conformance program, so R30's
    two-sided program obligation does not arise. **Breaks if** C++ selects an
    impl that no C++ overload resolution over the exported declarations would
    select (that would be a toolchain defect, not a divergence).
-   **D-OX-16 (W-007 discipline).** New functions, one new switch arm
    (generate_ast.cpp, not a contention file), one guard (operators.cpp, not a
    contention file), and one in-function hunk in a contention file: the
    condition `target.self_param && isa<clang::CXXMethodDecl>(function_decl)` in
    `BuildCppToCarbonThunkBody` (export.cpp:1247). It is behaviour-preserving,
    because the unchanged line below it casts `function_decl` to `CXXMethodDecl`
    unconditionally whenever `target.self_param` is set, so every existing
    caller already passes a method there; the non-member form is the only caller
    that does not. Nothing is moved or renamed; thunk.cpp (both) and
    type_mapping.cpp are untouched. **Breaks if** any existing golden changes
    (M-8: none).
-   **D-OX-17 (programs).** Seven programs for the bullet: the un-SKIPped
    arbiter and one per family (arithmetic with negation, compound assignment
    with increment, comparison, bitwise and shift, indexing, the non-member
    form), each EXPECT hand-derived (§1.8), none with a `.diff.cpp` oracle: the
    agreeing direction needs none (R30(b)), and the divergences live in
    goldens (D-OX-15). **Breaks if** a program passes with its family's
    operator mis-mapped (M-14 is the check).
-   **D-OX-18 (conversions are not operators here).** `As(T)` and
    `ImplicitAs(T)` are not exported in 0.1 (W-208): the milestone lists
    "operators, conversions" separately (milestones.md:169), C++ spells a
    conversion as a conversion function or constructor rather than an
    overloaded operator, and Clang collects a class's conversion functions from
    its definition, not by name lookup, so they need an eager export at
    completion that no other export does. **Breaks if** the bullet is read to
    include conversions; then W-208 bounds the row and D-OX-14's alternative
    applies.
-   **D-OX-19 (merge position).** OX-1 is cut from trunk, not stacked, and
    merges after DD-1 and PR 57, in the order fork/ORCHESTRATION.md records at
    44761146d; its trunk-sync merge applies §6.2's two-sentence replacement in
    DD-1's README text. **Breaks if** DD-1 merges after OX-1; then DD-1's next
    fold applies the same replacement and the ORCHESTRATION stamp says so.
-   **D-OX-20 (no new SemIR, no new diagnostics).** The feature adds no
    instruction kind, no `CARBON_DIAGNOSTIC`, and no SemIR formatting; its
    observable outputs are C++ declarations (the AST golden), generated thunks
    (the lower golden) and Clang's own diagnostics. **Breaks if** an
    implementation review finds a case that needs a Carbon diagnostic to be
    usable (it would be added with its own golden split and recorded here).

## §1 Design

### §1.1 The export mapping (F-017; D-OX-1)

| `Core` member | C++ | Form when `Self` is the class | Form otherwise (D-OX-3) |
| --- | --- | --- | --- |
| `AddWith(U).Op` | `a + b` | `R operator+(U) const` | `R operator+(S, C)` |
| `SubWith(U).Op` | `a - b` | `R operator-(U) const` | `R operator-(S, C)` |
| `MulWith(U).Op` | `a * b` | `R operator*(U) const` | `R operator*(S, C)` |
| `DivWith(U).Op` | `a / b` | `R operator/(U) const` | `R operator/(S, C)` |
| `ModWith(U).Op` | `a % b` | `R operator%(U) const` | `R operator%(S, C)` |
| `Negate.Op` | `-a` | `R operator-() const` | (unary: none) |
| `BitAndWith(U).Op` | `a & b` | `R operator&(U) const` | `R operator&(S, C)` |
| `BitOrWith(U).Op` | <code>a \| b</code> | <code>R operator\|(U) const</code> | <code>R operator\|(S, C)</code> |
| `BitXorWith(U).Op` | `a ^ b` | `R operator^(U) const` | `R operator^(S, C)` |
| `BitComplement.Op` | `~a` | `R operator~() const` | (unary: none) |
| `LeftShiftWith(U).Op` | `a << b` | `R operator<<(U) const` | `R operator<<(S, C)` |
| `RightShiftWith(U).Op` | `a >> b` | `R operator>>(U) const` | `R operator>>(S, C)` |
| `AddAssignWith(U).Op` .. `ModAssignWith(U).Op` | `+=` `-=` `*=` `/=` `%=` | `void operator+=(U) &` .. | `void operator+=(S&, C)` .. |
| `BitAndAssignWith(U).Op` .. `RightShiftAssignWith(U).Op` | `&=` <code>\|=</code> `^=` `<<=` `>>=` | `void operator&=(U) &` .. | `void operator&=(S&, C)` .. |
| `Inc.Op`, `Dec.Op` | `++a`, `--a` | `void operator++() &` | (unary: none) |
| `EqWith(U).Equal` | `a == b` | `bool operator==(U) const` | `bool operator==(S, C)` |
| `EqWith(U).NotEqual` | `a != b` | `bool operator!=(U) const`, or `!(*this == b)` (D-OX-5) | `bool operator!=(S, C)`, or `!(a == b)` |
| `OrderedWith(U).Less` .. `GreaterOrEquivalent` | `<` `<=` `>` `>=` | `bool operator<(U) const` .. | `bool operator<(S, C)` .. |
| `IndexWith(I).At` | `a[i]` | `E operator[](I) const` | (C++: members only) |

`R` is the impl's declared return type (the interface's `Result` or
`ElementType`), `U` the interface argument, `S` the impl's `Self`, `C` the
exported Carbon class the interface argument names; each maps by
`MapToCppType` (§0.1 row 6). The table is
`OperatorExportTable` (§2.1), one row per interface member with its explicit
parameter count (0 unary, 1 binary) and `OverloadedOperatorKind`; one operator
name can come from two interfaces (`-` from `SubWith` and `Negate`), which
Clang tells apart by parameter count.

### §1.2 How C++ finds it (D-OX-2, D-OX-3, D-OX-12)

Clang asks the external source for an operator name in two contexts (M-4): the
left operand's class, for member candidates, and each associated namespace, for
argument-dependent lookup. A new arm of `FindExternalVisibleDeclsByName`'s
name-kind switch answers both: `ExportOperatorsToCpp` for a Carbon-owned record,
`ExportNonMemberOperatorsToCpp` for a Carbon-owned namespace. Each walks
`context.impls()` in order and keeps the impls D-OX-4 admits whose interface is
the operator's (by `Core` package and name, M-3). The member walk keeps the
impls whose `Self` constant is the record's class type. The non-member walk
keeps the impls with one interface argument that is a non-generic Carbon class
already exported into this namespace, and whose `Self` does not map to a
Carbon-owned record (so `i32` and `Cpp.Foo` qualify, and a Carbon class `Self`
stays a member). For each kept impl and each table row of the operator, the
function the impl declares under the row's member name
(`GetImplMemberFunctionId`: a found entry of the impl's scope, M-3) is exported
once and remembered in `clang_decls`, keyed by the function's first declaration,
exactly as `GetOrExportFunctionToCpp` records an exported function (:1632-1642).
Clang caches the list per context and name; an empty answer is cached as "none"
(`SetNoExternalVisibleDeclsForName`, as the identifier path's null case does at
generate_ast.cpp:410).

### §1.3 Equality, inequality and ordering (D-OX-5, D-OX-6)

`Equal` exports as `operator==`. `NotEqual` exports as itself when the impl
declares it; otherwise `BuildDefaultNotEqualOperator` declares `operator!=`
beside the exported `operator==`, with its type and parameters, and builds the
body `return !(*this==other);` (a `CXXMemberCallExpr` of `operator==` under
`UO_LNot`, M-12's AST golden) or, for the non-member form, `return !(a==b);`
(a call of the non-member `operator==`). Because both are always declared
together and no `<=>` exists, Clang under `-std=c++20` adds no reversed or
rewritten candidate (M-6). The four `OrderedWith` members export one to one;
there is no `Compare` to export (W-206).

### §1.4 Statements and indexing (D-OX-7, D-OX-8)

`*AssignWith`, `Inc` and `Dec` members take `ref self`: the member form is
`&`-qualified (`BuildCppToCarbonThunkFunctionType`'s existing `RQ_LValue`,
export.cpp:1081-1082) and returns `void`; the non-member form takes `S&`
first (`MapToCppParamType` maps a `ref` parameter to an lvalue reference,
:1013-1014), as `int k; k-=m` needs. `IndexWith.At` takes `self`: a `const`
member returning the element by value.

### §1.5 What is not exported, and why (D-OX-1, D-OX-4, D-OX-18)

| Case | Measured | Reason | Filed |
| --- | --- | --- | --- |
| Generic impl; impl on a specific of a generic class | M-11(a) | the export walk takes concrete impls; a generic `Op` needs a C++ template, the generics-export machinery's frontier | W-202 |
| Impls of an imported library | M-11(d) | only `context.impls()` is walked; and an imported class exports as an empty record | W-204 (blocked by W-203) |
| An imported Carbon class at all | M-11(d) | pre-existing: fields are not exported, by-value results corrupt memory | W-203 (type-export row) |
| An impl declared after C++ looked its operator up | M-11(c) | Clang's cached answer (M-4) | W-205 |
| `<=>` | §0.3 item 6 | no `OrderedWith.Compare` in the prelude | W-206 |
| Two impls mapping to one C++ signature | M-11(e) | non-injective type mapping; C++ ambiguity | W-207 |
| `As`, `ImplicitAs` | — | conversions, not operators (D-OX-18) | W-208 |
| `a[i] = v` | — | the prelude's `IndexWith` has only `At` (W-109) | W-209 |
| Postfix `++`/`--`, unary `+`, `!`, `&&`, <code>\|\|</code>, `,`, `->`, unary `*` and `&`, `()`, `=` | the `fail_postfix_increment` split | Carbon has no interface for them | (by design, §2.7) |
| An impl with an unmappable signature | M-9 | omitted silently (D-OX-9) | (by design) |

### §1.6 The diagnostic policy (D-OX-9)

Before anything is built, `IsOperatorSignatureMappable` maps every type of the
impl member's signature (`self`, each explicit parameter, the return type) with
`MapToCppType` and rejects a null result or an array, which C++ cannot pass or
return by value; such an impl is skipped without a diagnostic, and the
non-member builder then asserts what the check established
(`CARBON_CHECK`). Every other failure is Clang's own diagnostic at the C++ use
(`invalid operands to binary expression`, `no viable overloaded '+='`, `cannot
increment value of type`), with Clang's notes listing the exported candidates
(M-11(c)).

### §1.7 Carbon's own expressions, and the divergences (D-OX-11, D-OX-15)

Carbon's impl lookup still finds the Carbon impl first; when an operand is a
C++ type it then asks Clang (§0.1 row 9), Clang's lookup reaches the exported
class, and the new guard in `FindClangOperator` declines a best viable function
that is an exported Carbon operator — a member of a Carbon-owned record, or a
non-member registered in `clang_decls` as a Carbon export, not imported
(`IsExportedCarbonOperator`) — so the Carbon impl stands (M-10). In C++, the
exported declarations take part in ordinary C++ overload resolution: operand
conversions and base-class member lookup apply (M-11(f), M-7), the two
documented divergences of D-OX-15, both where C++ accepts what Carbon does not;
in the other direction, C++ rejects nothing Carbon accepts for a concrete
same-file impl (D-OX-6, M-12).

### §1.8 EXPECT re-derivation (R16(d): from the program text, never from a run)

Each value below follows from the program's Carbon impl bodies and C++ calls
alone; the runs of M-13 agree, and M-14's mutants disagree.

-   cpp_operator_export: `Make(30)+Make(12)` adds the `value` fields:
    `30+12=42`.
-   cpp_operator_export_arithmetic, from 700 and 250 cents: `700+250=950`;
    `700-250=450`; `700*3=2100`; `700/3=233` (`i32` division truncates toward
    zero, arithmetic.md "Integer types"); `700%3=1`; negation gives `-700`.
-   cpp_operator_export_compound, each from 10: `10+5=15`; `10-3=7`;
    `10*4=40`; `10/4=2`; `10%6=4`; two increments and a decrement give `11`.
-   cpp_operator_export_compare, with a = 1 and b = 2, each line ten times a
    true case plus a false case: `==` from `a==a` and `a==b` gives `10`; `!=`
    from `a!=b` and `a!=a`, `10`; `<` from `a<b` and `a<a`, `10`; `<=` from
    `a<=a` and `b<=a`, `10`; `>` from `b>a` and `a>a`, `10`; `>=` from `a>=a`
    and `a>=b`, `10`; for `Unknowable`, value 0 against 1, `Equal` and the
    declared `NotEqual` are both false, so the line is `0` (the default
    `NotEqual` would make it 1).
-   cpp_operator_export_bitwise, with x = 12 (`0b1100`) and y = 10 (`0b1010`)
    as `u8`: AND gives `8`, OR `14`, XOR `6`, the complement `255-12=243`, the
    left shift by two `48`, `128>>3=16`; z starts at 3 and becomes 12, 13, 12,
    9 and finally `4` under `<<=2`, `|=1`, `&=14`, `^=5` and `>>=1`.
-   cpp_operator_export_index, fields 7, 8 and 9: `7*100+8*10+9=789`;
    `t[true]` is the `bool` impl (an exact match beats the `bool`-to-`int`
    promotion), the last field, and `t[false]` the first: `9*10+7=97`.
-   cpp_operator_export_nonmember: `50-8=42` (the `i32` impl, `Self` on the
    left; the other order would give `-42`); `(5==5)*10+(4!=5)=11` (the default
    `!=`); `(4<5)*10+(6<=5)=10`; `10-3=7` written back to the C++ `int`;
    `30+3=33`.

### §1.9 Docs and records (D-OX-13, D-OX-14)

The design text is §2.7: a new page and a dated amendment. The records (§2.8)
are written by commit 5 (the row) and commit 6 (everything else): W-054
discharged and its evidence corrected; W-202..W-209 filed; W-007's notes
extended; the row's status and evidence; the header delta; the decision-log
entry "OX-1 / F-017"; fork/ORCHESTRATION.md's stamp and Branches row; the
conformance README's generated table.

### §1.10 Residues (ids reserved at the head; full ledger entries in §2.8)

| Id | Title | Bullet | blocked_by |
| --- | --- | --- | --- |
| W-202 | OX-1 residue: generic operator impls, and the operator impls of a generic class's specifics, are not exported to C++ | the row | — |
| W-203 | Exporting a Carbon class imported from another library yields an empty C++ record: no fields, and a by-value result corrupts memory (upstream defect) | Type system: C++ interop — importing C++ types / exporting Carbon types | — |
| W-204 | OX-1 residue: operator impls declared in an imported library are not exported to C++ | the row | W-203 |
| W-205 | OX-1 residue: an operator impl declared after C++ looked that operator up on the class or namespace is not seen by later C++ code | the row | — |
| W-206 | OX-1 residue: `<=>` is not exported; the prelude's `OrderedWith` has no `Compare` | the row | — |
| W-207 | OX-1 residue: two operator impls whose operand types map to one C++ type are ambiguous at every C++ use (the W-118 shape) | the row | — |
| W-208 | OX-1 residue: `As` and `ImplicitAs` impls are not exported as C++ conversions | the row | — |
| W-209 | OX-1 residue: `operator[]` returns by value; the `ref` forms of indexing are not exported | the row | W-109 |

## §2 Implementation spec, file by file

### §2.1 to §2.4 Toolchain (four files, one diff; clang-format 21.1.8 clean; compiled and measured as `v4`)

The diff below is `v4` (`$X/ox1-v4.diff`, sha256
68762c67ce337938956adf5bf60a4f63bb184d8f675881b684d4b42b90a3fa37): 602 lines
added and 1 removed over export.cpp (+547, −1), export.h (+24),
generate_ast.cpp (+25) and operators.cpp (+6). It applies to f67ab650d with no
offset and to ST-1's head with offset 5 (M-16); every file passes
`clang-format --style=file` from the CI pin (R18). Invariants, by hunk:

-   **export.cpp, the include and the table (new).** `OperatorExportTable` is
    §1.1; `num_explicit_params` separates `-a` from `a-b`. Nothing reads the
    table but the two walks.
-   **export.cpp, `BuildCppToCarbonThunkBody` (the one in-function hunk,
    D-OX-16).** The `this` argument is passed only for a method; the
    non-member form's first parameter is `self` and is passed by the loop that
    follows like every other parameter, matching the generated Carbon thunk's
    parameter order (`self`, the explicit parameters, the result). For every
    existing caller the new conjunct is true: the body already does
    `cast<clang::CXXMethodDecl>(function_decl)` under `target.self_param`.
-   **export.cpp, the member walk.** `IsOperatorSignatureMappable` runs before
    any declaration exists (D-OX-9); `GetImplMemberFunctionId` returns `None`
    for a member the impl leaves to its default and for a name the impl's
    checking poisoned (M-3), and rejects a function with an enclosing
    specific; `ExportImplFunctionAsCppOperator` reuses an earlier export
    through `clang_decls`, builds the `FunctionInfo` itself (the impl scope
    cannot be exported, M-2), calls the existing `BuildCppToCarbonThunkDecl`
    with the operator's `DeclarationName` and the existing
    `BuildCppToCarbonThunk`, and registers the result as
    `GetOrExportFunctionToCpp` registers an exported function;
    `ExportOperatorsToCpp` returns nothing for a specific of a generic class
    (W-202) and keeps the impls of §1.2.
-   **export.cpp, the default `!=`.** `BuildDefaultNotEqualOperator` gives the
    new declaration `operator==`'s type, parameters, inline, always-inline and
    internal-linkage attributes, and the body `!(this->operator==(p))` or
    `!operator==(p0, p1)`, then hands it to the AST consumer as
    `BuildCppToCarbonThunk` does (export.cpp:1463-1464), so CodeGen emits it on
    use.
-   **export.cpp, the non-member walk.** `GetCarbonClassType` admits a class
    defined in Carbon; the operand's exported declaration must sit in this
    namespace (`getRedeclContext` on both sides); `Self` goes to the member walk
    when it maps to a Carbon-owned record.
    `BuildCppToCarbonNonMemberOperatorDecl` maps `self` and the operand with
    `MapToCppParamType` (a `ref self` becomes `S&`), declares an inline,
    always-inline, internal-linkage `FunctionDecl` in the namespace, and leaves
    the body to `BuildCppToCarbonThunk`.
-   **export.cpp, `IsExportedCarbonOperator`.** True for an overloaded operator
    that is a member of a Carbon-owned record (every member of one comes from
    Carbon, the default `!=` included) or a non-member registered in
    `clang_decls` under the exported-function signature shape and not imported.
    The signature is looked up, never added (`CanonicalValueStore::Lookup`).
-   **export.h.** Three declarations, with comments naming F-017 and the page.
-   **generate_ast.cpp, the `CXXOperatorName` arm.** Placed first in the
    switch, before `Identifier`; record → member walk, namespace → non-member
    walk; an empty answer is cached as none; the arm returns before the
    identifier-based lookup below it, which never sees an operator name.
-   **operators.cpp, the guard.** In `FindClangOperator`'s success case, after
    the builtin and rewrite checks and before `MarkFunctionReferenced`, so
    Clang never marks the exported operator as used by Carbon.

```diff
--- a/toolchain/check/cpp/export.cpp
+++ b/toolchain/check/cpp/export.cpp
@@ -12,6 +12,7 @@
 #include "clang/Sema/EnterExpressionEvaluationContext.h"
 #include "clang/Sema/Sema.h"
 #include "llvm/Support/Casting.h"
+#include "toolchain/check/core_identifier.h"
 #include "toolchain/check/cpp/access.h"
 #include "toolchain/check/cpp/import.h"
 #include "toolchain/check/cpp/location.h"
@@ -1244,7 +1245,9 @@

   llvm::SmallVector<clang::Expr*> call_args;
   // For methods, pass the `this` pointer as the first argument to the callee.
-  if (target.self_param) {
+  // A non-member operator (fork decision F-017) declares `self` as its first
+  // parameter instead, which the loop below passes like the others.
+  if (target.self_param && isa<clang::CXXMethodDecl>(function_decl)) {
     call_args.push_back(
         GetThisArg(sema, clang_loc, cast<clang::CXXMethodDecl>(function_decl)));
   }
@@ -1901,4 +1904,547 @@
   return var_decl;
 }

+namespace {
+// One row of the operator export table (fork decision F-017): the `Core`
+// operator interface and member function that a C++ overloaded operator calls
+// when C++ applies it to an exported Carbon class that implements that
+// interface. The table is the inverse of the import direction's
+// `GetClangOperatorKind` (check/cpp/operators.cpp), restricted to the members
+// that are operators in C++.
+struct OperatorExportEntry {
+  CoreIdentifier interface_name;
+  CoreIdentifier member_name;
+  // The number of explicit parameters after `self`: 0 for a unary operator, 1
+  // for a binary operator.
+  int num_explicit_params;
+  clang::OverloadedOperatorKind op_kind;
+};
+}  // namespace
+
+static constexpr OperatorExportEntry OperatorExportTable[] = {
+    // Arithmetic.
+    {CoreIdentifier::AddWith, CoreIdentifier::Op, 1, clang::OO_Plus},
+    {CoreIdentifier::SubWith, CoreIdentifier::Op, 1, clang::OO_Minus},
+    {CoreIdentifier::MulWith, CoreIdentifier::Op, 1, clang::OO_Star},
+    {CoreIdentifier::DivWith, CoreIdentifier::Op, 1, clang::OO_Slash},
+    {CoreIdentifier::ModWith, CoreIdentifier::Op, 1, clang::OO_Percent},
+    {CoreIdentifier::Negate, CoreIdentifier::Op, 0, clang::OO_Minus},
+    // Bitwise and shift.
+    {CoreIdentifier::BitAndWith, CoreIdentifier::Op, 1, clang::OO_Amp},
+    {CoreIdentifier::BitOrWith, CoreIdentifier::Op, 1, clang::OO_Pipe},
+    {CoreIdentifier::BitXorWith, CoreIdentifier::Op, 1, clang::OO_Caret},
+    {CoreIdentifier::BitComplement, CoreIdentifier::Op, 0, clang::OO_Tilde},
+    {CoreIdentifier::LeftShiftWith, CoreIdentifier::Op, 1, clang::OO_LessLess},
+    {CoreIdentifier::RightShiftWith, CoreIdentifier::Op, 1,
+     clang::OO_GreaterGreater},
+    // Compound assignment.
+    {CoreIdentifier::AddAssignWith, CoreIdentifier::Op, 1, clang::OO_PlusEqual},
+    {CoreIdentifier::SubAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_MinusEqual},
+    {CoreIdentifier::MulAssignWith, CoreIdentifier::Op, 1, clang::OO_StarEqual},
+    {CoreIdentifier::DivAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_SlashEqual},
+    {CoreIdentifier::ModAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_PercentEqual},
+    {CoreIdentifier::BitAndAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_AmpEqual},
+    {CoreIdentifier::BitOrAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_PipeEqual},
+    {CoreIdentifier::BitXorAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_CaretEqual},
+    {CoreIdentifier::LeftShiftAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_LessLessEqual},
+    {CoreIdentifier::RightShiftAssignWith, CoreIdentifier::Op, 1,
+     clang::OO_GreaterGreaterEqual},
+    // Increment and decrement: Carbon's are prefix only.
+    {CoreIdentifier::Inc, CoreIdentifier::Op, 0, clang::OO_PlusPlus},
+    {CoreIdentifier::Dec, CoreIdentifier::Op, 0, clang::OO_MinusMinus},
+    // Comparison. A `NotEqual` the impl does not declare is the interface's
+    // default, `not self.Equal(other)`, and is exported as `!(a == b)`
+    // (`BuildDefaultNotEqualOperator`).
+    {CoreIdentifier::EqWith, CoreIdentifier::Equal, 1, clang::OO_EqualEqual},
+    {CoreIdentifier::EqWith, CoreIdentifier::NotEqual, 1,
+     clang::OO_ExclaimEqual},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::Less, 1, clang::OO_Less},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::LessOrEquivalent, 1,
+     clang::OO_LessEqual},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::Greater, 1,
+     clang::OO_Greater},
+    {CoreIdentifier::OrderedWith, CoreIdentifier::GreaterOrEquivalent, 1,
+     clang::OO_GreaterEqual},
+    // Indexing.
+    {CoreIdentifier::IndexWith, CoreIdentifier::At, 1, clang::OO_Subscript},
+};
+
+// Returns whether every type in `target`'s signature has a C++ mapping that a
+// C++ operator can take or return. Carbon's own operator lookup asks C++ for
+// candidates whenever an operand is a C++ type (cpp/impl_lookup.cpp), which
+// looks up the operator in the exported Carbon class, so an operator impl
+// whose signature does not map is omitted without a diagnostic: C++ cannot
+// form an operand of an unmappable type, and a Carbon operator expression must
+// not be rejected because its impl has no C++ form.
+static auto IsOperatorSignatureMappable(Context& context,
+                                        const FunctionInfo& target) -> bool {
+  auto maps = [&](SemIR::TypeId type_id) {
+    auto cpp_type = MapToCppType(context, type_id);
+    return !cpp_type.isNull() && !cpp_type->isArrayType();
+  };
+  if (target.self_param && !maps(target.self_param->type_id)) {
+    return false;
+  }
+  for (const auto& param : target.explicit_params) {
+    if (!maps(param.type_id)) {
+      return false;
+    }
+  }
+  return !target.return_type_id.has_value() || maps(target.return_type_id);
+}
+
+// Returns the function that `impl` declares as its `member_name`, or `None`
+// when the impl leaves that member to the interface's `default fn`.
+static auto GetImplMemberFunctionId(Context& context, const SemIR::Impl& impl,
+                                    CoreIdentifier member_name)
+    -> SemIR::FunctionId {
+  auto& impl_scope = context.name_scopes().Get(impl.scope_id);
+  auto entry_id =
+      impl_scope.Lookup(context.core_identifiers().AddNameId(member_name));
+  if (!entry_id) {
+    return SemIR::FunctionId::None;
+  }
+  // A name the impl does not declare can still have an entry: checking the
+  // impl poisons the names it looked up in its own scope.
+  const auto& result = impl_scope.GetEntry(*entry_id).result;
+  if (!result.is_found()) {
+    return SemIR::FunctionId::None;
+  }
+  LoadImportRef(context, result.target_inst_id());
+  auto callee = SemIR::GetCallee(context.sem_ir(), result.target_inst_id());
+  auto* callee_function = std::get_if<SemIR::CalleeFunction>(&callee);
+  if (!callee_function || callee_function->enclosing_specific_id.has_value()) {
+    return SemIR::FunctionId::None;
+  }
+  return callee_function->function_id;
+}
+
+// Exports `function_id`, an impl's member, as the C++ member operator
+// `entry.op_kind` of `record_decl`, through the same C++ and Carbon thunks as
+// an exported method. Returns null if the function's shape is not the
+// operator's, or if its signature has no C++ mapping.
+static auto ExportImplFunctionAsCppOperator(Context& context,
+                                            clang::CXXRecordDecl* record_decl,
+                                            SemIR::FunctionId function_id,
+                                            const OperatorExportEntry& entry)
+    -> clang::CXXMethodDecl* {
+  const auto& function = context.functions().Get(function_id);
+  SemIR::LocId loc_id(function.first_decl_id());
+
+  // Reuse an earlier export of this function.
+  if (const auto* clang_decl =
+          context.clang_decls().Lookup(function.first_decl_id())) {
+    return dyn_cast<clang::CXXMethodDecl>(clang_decl->decl());
+  }
+
+  FunctionInfo target(context, function_id, function, record_decl,
+                      /*export_as_constructor=*/false);
+  if (!target.self_param ||
+      static_cast<int>(target.explicit_params.size()) !=
+          entry.num_explicit_params ||
+      !IsOperatorSignatureMappable(context, target)) {
+    return nullptr;
+  }
+  auto* operator_decl = BuildCppToCarbonThunkDecl(
+      context, loc_id, target,
+      context.ast_context().DeclarationNames.getCXXOperatorName(entry.op_kind));
+  if (!operator_decl) {
+    return nullptr;
+  }
+  BuildCppToCarbonThunk(context, loc_id, target, operator_decl,
+                        /*extra_name=*/"");
+
+  SemIR::ClangDeclSignature signature{
+      .kind = SemIR::ClangDeclSignature::Normal,
+      .num_params = static_cast<int32_t>(operator_decl->getNumParams())};
+  signature.passing_modes.assign(
+      signature.num_params, SemIR::ClangDeclSignature::PassingMode::ByValue);
+  context.clang_decls().Add(
+      {.key = SemIR::ClangDeclKey::ForFunctionDecl(
+           operator_decl,
+           context.clang_decl_signatures().Add(std::move(signature))),
+       .inst_id = function.first_decl_id()});
+  return cast<clang::CXXMethodDecl>(operator_decl);
+}
+
+// Builds `operator!=` for an `EqWith` impl that leaves `NotEqual` to its
+// default, `not self.Equal(other)` (docs/design/expressions/
+// comparison_operators.md, "Equality"), as `!(a == b)` over the exported
+// `operator==`, beside it and of the same form, member or non-member: C++17
+// does not rewrite `a != b` itself.
+static auto BuildDefaultNotEqualOperator(Context& context,
+                                         clang::FunctionDecl* equal_decl)
+    -> clang::FunctionDecl* {
+  clang::ASTContext& ast_context = context.ast_context();
+  clang::Sema& sema = context.clang_sema();
+  auto clang_loc = equal_decl->getLocation();
+  auto* decl_context = equal_decl->getDeclContext();
+
+  clang::DeclarationNameInfo name_info(
+      ast_context.DeclarationNames.getCXXOperatorName(clang::OO_ExclaimEqual),
+      clang_loc);
+  auto type = equal_decl->getType();
+  auto* tinfo = ast_context.getTrivialTypeSourceInfo(type, clang_loc);
+  auto* equal_method_decl = dyn_cast<clang::CXXMethodDecl>(equal_decl);
+  clang::FunctionDecl* not_equal_decl = nullptr;
+  if (equal_method_decl) {
+    not_equal_decl = clang::CXXMethodDecl::Create(
+        ast_context, equal_method_decl->getParent(), clang_loc, name_info, type,
+        tinfo, clang::SC_None, /*UsesFPIntrin=*/false,
+        /*isInline=*/true, clang::ConstexprSpecKind::Unspecified, clang_loc,
+        clang::AssociatedConstraint());
+    not_equal_decl->setAccess(clang::AS_public);
+  } else {
+    not_equal_decl = clang::FunctionDecl::Create(
+        ast_context, decl_context, clang_loc, name_info, type, tinfo,
+        clang::SC_None, /*UsesFPIntrin=*/false, /*isInlineSpecified=*/true,
+        /*hasWrittenPrototype=*/true, clang::ConstexprSpecKind::Unspecified,
+        clang::AssociatedConstraint());
+  }
+  llvm::SmallVector<clang::ParmVarDecl*> params;
+  for (const auto* equal_param : equal_decl->parameters()) {
+    params.push_back(clang::ParmVarDecl::Create(
+        ast_context, not_equal_decl, clang_loc, clang_loc, /*Id=*/nullptr,
+        equal_param->getType(), /*TInfo=*/nullptr, clang::SC_None,
+        /*DefArg=*/nullptr));
+  }
+  not_equal_decl->setParams(params);
+  decl_context->addHiddenDecl(not_equal_decl);
+  not_equal_decl->addAttr(clang::AlwaysInlineAttr::CreateImplicit(ast_context));
+  not_equal_decl->addAttr(
+      clang::InternalLinkageAttr::CreateImplicit(ast_context));
+
+  clang::Sema::ContextRAII context_raii(sema, not_equal_decl);
+  clang::EnterExpressionEvaluationContext evaluated(
+      sema, clang::Sema::ExpressionEvaluationContext::PotentiallyEvaluated);
+  sema.ActOnStartOfFunctionDef(nullptr, not_equal_decl);
+  llvm::SmallVector<clang::Expr*> args;
+  for (auto* param : params) {
+    args.push_back(sema.BuildDeclRefExpr(param,
+                                         param->getType().getNonReferenceType(),
+                                         clang::VK_LValue, clang_loc));
+  }
+  clang::ExprResult equal_call;
+  if (equal_method_decl) {
+    auto* member_expr = sema.BuildMemberExpr(
+        GetThisArg(sema, clang_loc, cast<clang::CXXMethodDecl>(not_equal_decl)),
+        /*IsArrow=*/false, clang_loc, clang::NestedNameSpecifierLoc(),
+        clang::SourceLocation(), equal_method_decl,
+        clang::DeclAccessPair::make(equal_method_decl, clang::AS_public),
+        /*HadMultipleCandidates=*/false,
+        clang::DeclarationNameInfo(equal_decl->getDeclName(), clang_loc),
+        ast_context.BoundMemberTy, clang::VK_PRValue, clang::OK_Ordinary);
+    equal_call = sema.BuildCallToMemberFunction(/*S=*/nullptr, member_expr,
+                                                clang_loc, args, clang_loc);
+  } else {
+    clang::ExprResult callee = sema.BuildDeclRefExpr(
+        equal_decl, equal_decl->getType(), clang::VK_LValue, clang_loc);
+    equal_call = sema.BuildCallExpr(/*S=*/nullptr, callee.get(), clang_loc,
+                                    args, clang_loc);
+  }
+  CARBON_CHECK(equal_call.isUsable());
+  auto not_expr =
+      sema.CreateBuiltinUnaryOp(clang_loc, clang::UO_LNot, equal_call.get());
+  CARBON_CHECK(not_expr.isUsable());
+  auto return_stmt = sema.BuildReturnStmt(clang_loc, not_expr.get());
+  CARBON_CHECK(return_stmt.isUsable());
+  clang::Stmt* stmts[] = {return_stmt.get()};
+  sema.ActOnFinishFunctionBody(
+      not_equal_decl, clang::CompoundStmt::Create(ast_context, stmts,
+                                                  clang::FPOptionsOverride(),
+                                                  clang_loc, clang_loc));
+  sema.getASTConsumer().HandleTopLevelDecl(clang::DeclGroupRef(not_equal_decl));
+  return not_equal_decl;
+}
+
+auto ExportOperatorsToCpp(Context& context, clang::CXXRecordDecl* record_decl,
+                          clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*> {
+  llvm::SmallVector<clang::NamedDecl*> operator_decls;
+  auto carbon_class =
+      SemIR::GetAsCarbonOwnedClass(context.sem_ir(), record_decl);
+  if (!carbon_class) {
+    return operator_decls;
+  }
+  auto [class_type_id, class_type] = *carbon_class;
+  // TODO: Export the operator impls of a generic class's specifics.
+  if (class_type.specific_id.has_value()) {
+    return operator_decls;
+  }
+  auto class_const_id = context.types().GetConstantId(class_type_id);
+
+  // Impls are visited in the order they were added to the file, which is
+  // declaration order for the impls this file declares.
+  for (auto [impl_id, impl] : context.impls().enumerate()) {
+    // Only a complete, non-generic impl whose `Self` is exactly this class
+    // exports, and it exports as a member operator, so C++ finds it by member
+    // lookup on the left operand as Carbon finds it by impl lookup on `Self`.
+    if (!impl.is_complete() || impl.generic_id.has_value() ||
+        !impl.interface.interface_id.has_value() ||
+        context.constant_values().Get(impl.self_id) != class_const_id) {
+      continue;
+    }
+    const auto& interface =
+        context.interfaces().Get(impl.interface.interface_id);
+    if (!context.name_scopes().IsCorePackage(interface.parent_scope_id)) {
+      continue;
+    }
+    for (const auto& entry : OperatorExportTable) {
+      if (entry.op_kind != op_kind ||
+          context.core_identifiers().AddNameId(entry.interface_name) !=
+              interface.name_id) {
+        continue;
+      }
+      clang::CXXMethodDecl* operator_decl = nullptr;
+      if (auto function_id =
+              GetImplMemberFunctionId(context, impl, entry.member_name);
+          function_id.has_value()) {
+        operator_decl = ExportImplFunctionAsCppOperator(context, record_decl,
+                                                        function_id, entry);
+      } else if (entry.member_name == CoreIdentifier::NotEqual) {
+        if (auto equal_id =
+                GetImplMemberFunctionId(context, impl, CoreIdentifier::Equal);
+            equal_id.has_value()) {
+          if (auto* equal_decl = ExportImplFunctionAsCppOperator(
+                  context, record_decl, equal_id,
+                  {.interface_name = CoreIdentifier::EqWith,
+                   .member_name = CoreIdentifier::Equal,
+                   .num_explicit_params = 1,
+                   .op_kind = clang::OO_EqualEqual})) {
+            operator_decl = cast<clang::CXXMethodDecl>(
+                BuildDefaultNotEqualOperator(context, equal_decl));
+          }
+        }
+      }
+      if (operator_decl) {
+        operator_decls.push_back(operator_decl);
+      }
+    }
+  }
+  return operator_decls;
+}
+
+// Returns the Carbon class type that `type_inst_id` names, if it is a class
+// defined in Carbon (not one imported from C++).
+static auto GetCarbonClassType(Context& context, SemIR::InstId type_inst_id)
+    -> std::optional<SemIR::ClassType> {
+  auto class_type = context.constant_values().TryGetInstAs<SemIR::ClassType>(
+      context.constant_values().Get(type_inst_id));
+  if (!class_type) {
+    return std::nullopt;
+  }
+  const auto& class_info = context.classes().Get(class_type->class_id);
+  if (!class_info.scope_id.has_value() ||
+      context.name_scopes().Get(class_info.scope_id).is_cpp_scope()) {
+    return std::nullopt;
+  }
+  return class_type;
+}
+
+// Declares the non-member C++ operator `op_kind` in `namespace_decl` for the
+// impl member `target`, whose `self` becomes the first C++ parameter. The
+// signature's types map (`IsOperatorSignatureMappable`).
+static auto BuildCppToCarbonNonMemberOperatorDecl(
+    Context& context, SemIR::LocId loc_id, const FunctionInfo& target,
+    clang::NamespaceDecl* namespace_decl, clang::OverloadedOperatorKind op_kind)
+    -> clang::FunctionDecl* {
+  clang::ASTContext& ast_context = context.ast_context();
+  auto clang_loc = GetCppLocation(context, loc_id);
+
+  llvm::SmallVector<clang::QualType> param_types;
+  for (const auto& param : llvm::concat<const FunctionInfo::Param>(
+           llvm::ArrayRef(*target.self_param), target.explicit_params)) {
+    auto cpp_type = MapToCppParamType(context, loc_id, param);
+    CARBON_CHECK(!cpp_type.isNull(), "checked by IsOperatorSignatureMappable");
+    param_types.push_back(cpp_type);
+  }
+  clang::QualType return_type = ast_context.VoidTy;
+  if (target.return_type_id.has_value()) {
+    return_type = MapToCppType(context, target.return_type_id);
+    CARBON_CHECK(!return_type.isNull(),
+                 "checked by IsOperatorSignatureMappable");
+  }
+  auto function_type = ast_context.getFunctionType(
+      return_type, param_types, clang::FunctionProtoType::ExtProtoInfo());
+  auto* function_decl = clang::FunctionDecl::Create(
+      ast_context, namespace_decl, clang_loc,
+      clang::DeclarationNameInfo(
+          ast_context.DeclarationNames.getCXXOperatorName(op_kind), clang_loc),
+      function_type,
+      ast_context.getTrivialTypeSourceInfo(function_type, clang_loc),
+      clang::SC_None, /*UsesFPIntrin=*/false, /*isInlineSpecified=*/true,
+      /*hasWrittenPrototype=*/true, clang::ConstexprSpecKind::Unspecified,
+      clang::AssociatedConstraint());
+  llvm::SmallVector<clang::ParmVarDecl*> params;
+  for (auto type : param_types) {
+    params.push_back(clang::ParmVarDecl::Create(
+        ast_context, function_decl, clang_loc, clang_loc, /*Id=*/nullptr, type,
+        /*TInfo=*/nullptr, clang::SC_None, /*DefArg=*/nullptr));
+  }
+  function_decl->setParams(params);
+  namespace_decl->addHiddenDecl(function_decl);
+  function_decl->addAttr(clang::AlwaysInlineAttr::CreateImplicit(ast_context));
+  function_decl->addAttr(
+      clang::InternalLinkageAttr::CreateImplicit(ast_context));
+  return function_decl;
+}
+
+// Exports `function_id`, an impl's member, as the non-member C++ operator
+// `entry.op_kind` in `namespace_decl`, through the same C++ and Carbon thunks
+// as an exported method. Returns null as `ExportImplFunctionAsCppOperator`
+// does.
+static auto ExportImplFunctionAsCppNonMemberOperator(
+    Context& context, clang::NamespaceDecl* namespace_decl,
+    SemIR::FunctionId function_id, const OperatorExportEntry& entry)
+    -> clang::FunctionDecl* {
+  const auto& function = context.functions().Get(function_id);
+  if (const auto* clang_decl =
+          context.clang_decls().Lookup(function.first_decl_id())) {
+    return dyn_cast<clang::FunctionDecl>(clang_decl->decl());
+  }
+  SemIR::LocId loc_id(function.first_decl_id());
+  FunctionInfo target(context, function_id, function, namespace_decl,
+                      /*export_as_constructor=*/false);
+  if (!target.self_param || target.explicit_params.size() != 1 ||
+      !IsOperatorSignatureMappable(context, target)) {
+    return nullptr;
+  }
+  auto* operator_decl = BuildCppToCarbonNonMemberOperatorDecl(
+      context, loc_id, target, namespace_decl, entry.op_kind);
+  if (!operator_decl) {
+    return nullptr;
+  }
+  BuildCppToCarbonThunk(context, loc_id, target, operator_decl,
+                        /*extra_name=*/"");
+  SemIR::ClangDeclSignature signature{
+      .kind = SemIR::ClangDeclSignature::Normal,
+      .num_params = static_cast<int32_t>(operator_decl->getNumParams())};
+  signature.passing_modes.assign(
+      signature.num_params, SemIR::ClangDeclSignature::PassingMode::ByValue);
+  context.clang_decls().Add(
+      {.key = SemIR::ClangDeclKey::ForFunctionDecl(
+           operator_decl,
+           context.clang_decl_signatures().Add(std::move(signature))),
+       .inst_id = function.first_decl_id()});
+  return operator_decl;
+}
+
+auto ExportNonMemberOperatorsToCpp(Context& context,
+                                   clang::NamespaceDecl* namespace_decl,
+                                   clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*> {
+  llvm::SmallVector<clang::NamedDecl*> operator_decls;
+  for (auto [impl_id, impl] : context.impls().enumerate()) {
+    // A binary operator impl whose operand type is a Carbon class exported
+    // into this namespace and whose `Self` C++ does not see as an exported
+    // Carbon class: C++ finds it by argument-dependent lookup on the operand.
+    if (!impl.is_complete() || impl.generic_id.has_value() ||
+        !impl.interface.interface_id.has_value() ||
+        !impl.interface.specific_id.has_value()) {
+      continue;
+    }
+    const auto& interface =
+        context.interfaces().Get(impl.interface.interface_id);
+    if (!context.name_scopes().IsCorePackage(interface.parent_scope_id)) {
+      continue;
+    }
+    auto args = context.inst_blocks().Get(
+        context.specifics().Get(impl.interface.specific_id).args_id);
+    if (args.size() != 1) {
+      continue;
+    }
+    auto operand_class = GetCarbonClassType(context, args.front());
+    if (!operand_class || operand_class->specific_id.has_value()) {
+      continue;
+    }
+    const auto* operand_decl = context.clang_decls().Lookup(
+        context.classes().Get(operand_class->class_id).first_decl_id());
+    if (!operand_decl ||
+        operand_decl->decl()->getDeclContext()->getRedeclContext() !=
+            namespace_decl->getRedeclContext()) {
+      continue;
+    }
+    // A `Self` that C++ sees as an exported Carbon class has the impl as a
+    // member operator instead (`ExportOperatorsToCpp`).
+    auto self_cpp_type = MapToCppType(
+        context, context.types().GetTypeIdForTypeInstId(impl.self_id));
+    if (!self_cpp_type.isNull()) {
+      if (const auto* self_record = self_cpp_type->getAsCXXRecordDecl();
+          self_record &&
+          SemIR::GetAsCarbonOwnedClass(context.sem_ir(), self_record)) {
+        continue;
+      }
+    }
+    for (const auto& entry : OperatorExportTable) {
+      // Only binary operators have an operand; C++ requires `operator[]` to
+      // be a member.
+      if (entry.op_kind != op_kind || entry.num_explicit_params != 1 ||
+          entry.op_kind == clang::OO_Subscript ||
+          context.core_identifiers().AddNameId(entry.interface_name) !=
+              interface.name_id) {
+        continue;
+      }
+      clang::FunctionDecl* operator_decl = nullptr;
+      if (auto function_id =
+              GetImplMemberFunctionId(context, impl, entry.member_name);
+          function_id.has_value()) {
+        operator_decl = ExportImplFunctionAsCppNonMemberOperator(
+            context, namespace_decl, function_id, entry);
+      } else if (entry.member_name == CoreIdentifier::NotEqual) {
+        if (auto equal_id =
+                GetImplMemberFunctionId(context, impl, CoreIdentifier::Equal);
+            equal_id.has_value()) {
+          if (auto* equal_decl = ExportImplFunctionAsCppNonMemberOperator(
+                  context, namespace_decl, equal_id,
+                  {.interface_name = CoreIdentifier::EqWith,
+                   .member_name = CoreIdentifier::Equal,
+                   .num_explicit_params = 1,
+                   .op_kind = clang::OO_EqualEqual})) {
+            operator_decl = BuildDefaultNotEqualOperator(context, equal_decl);
+          }
+        }
+      }
+      if (operator_decl) {
+        operator_decls.push_back(operator_decl);
+      }
+    }
+  }
+  return operator_decls;
+}
+
+auto IsExportedCarbonOperator(Context& context,
+                              const clang::FunctionDecl* function_decl)
+    -> bool {
+  if (!function_decl->isOverloadedOperator()) {
+    return false;
+  }
+  // Every member of an exported Carbon class comes from Carbon.
+  if (const auto* method_decl = dyn_cast<clang::CXXMethodDecl>(function_decl)) {
+    return SemIR::GetAsCarbonOwnedClass(context.sem_ir(),
+                                        method_decl->getParent())
+        .has_value();
+  }
+  SemIR::ClangDeclSignature signature{
+      .kind = SemIR::ClangDeclSignature::Normal,
+      .num_params = static_cast<int32_t>(function_decl->getNumParams())};
+  signature.passing_modes.assign(
+      signature.num_params, SemIR::ClangDeclSignature::PassingMode::ByValue);
+  auto signature_id = context.clang_decl_signatures().Lookup(signature);
+  if (!signature_id.has_value()) {
+    return false;
+  }
+  auto clang_decl_id =
+      context.clang_decls().LookupId(SemIR::ClangDeclKey::ForFunctionDecl(
+          const_cast<clang::FunctionDecl*>(function_decl), signature_id));
+  return clang_decl_id.has_value() &&
+         !context.clang_decls().Get(clang_decl_id).is_imported;
+}
+
 }  // namespace Carbon::Check
--- a/toolchain/check/cpp/export.h
+++ b/toolchain/check/cpp/export.h
@@ -141,6 +141,30 @@
 auto ExportVarToCpp(Context& context, SemIR::InstId inst_id,
                     SemIR::VarStorage var_storage) -> clang::VarDecl*;

+// Exports the operator impls of the Carbon class behind `record_decl` that C++
+// spells as `op_kind` as member operators of `record_decl`, and returns them
+// (fork decision F-017; docs/design/interoperability/operators.md). Only a
+// complete, non-generic impl in this file whose `Self` is exactly the class
+// exports; a member whose signature has no C++ mapping is omitted without a
+// diagnostic. Returns an empty list when no impl maps.
+auto ExportOperatorsToCpp(Context& context, clang::CXXRecordDecl* record_decl,
+                          clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*>;
+
+// Exports the binary operator impls whose `Self` is not a Carbon class and
+// whose operand type is a Carbon class exported into `namespace_decl`, as
+// non-member operators of that namespace that C++ finds by argument-dependent
+// lookup on the operand (fork decision F-017). Returns them.
+auto ExportNonMemberOperatorsToCpp(Context& context,
+                                   clang::NamespaceDecl* namespace_decl,
+                                   clang::OverloadedOperatorKind op_kind)
+    -> llvm::SmallVector<clang::NamedDecl*>;
+
+// Returns whether `function_decl` is a Carbon operator impl exported to C++ by
+// `ExportOperatorsToCpp` or `ExportNonMemberOperatorsToCpp`.
+auto IsExportedCarbonOperator(Context& context,
+                              const clang::FunctionDecl* function_decl) -> bool;
+
 }  // namespace Carbon::Check

 #endif  // CARBON_TOOLCHAIN_CHECK_CPP_EXPORT_H_
--- a/toolchain/check/cpp/generate_ast.cpp
+++ b/toolchain/check/cpp/generate_ast.cpp
@@ -363,6 +363,31 @@

   clang::IdentifierInfo* identifier = nullptr;
   switch (decl_name.getNameKind()) {
+    case clang::DeclarationName::CXXOperatorName: {
+      // A C++ overloaded operator applied to an exported Carbon class finds
+      // the class's Carbon operator impls by member lookup (fork decision
+      // F-017), and an impl whose `Self` is not a Carbon class by
+      // argument-dependent lookup in its operand class's namespace. No other
+      // Carbon entity answers an operator name.
+      auto* mutable_decl_context =
+          const_cast<clang::DeclContext*>(decl_context);
+      llvm::SmallVector<clang::NamedDecl*> operator_decls;
+      if (auto* record_decl =
+              dyn_cast<clang::CXXRecordDecl>(mutable_decl_context)) {
+        operator_decls = ExportOperatorsToCpp(
+            *context_, record_decl, decl_name.getCXXOverloadedOperator());
+      } else if (auto* namespace_decl =
+                     dyn_cast<clang::NamespaceDecl>(mutable_decl_context)) {
+        operator_decls = ExportNonMemberOperatorsToCpp(
+            *context_, namespace_decl, decl_name.getCXXOverloadedOperator());
+      }
+      if (operator_decls.empty()) {
+        SetNoExternalVisibleDeclsForName(decl_context, decl_name);
+        return false;
+      }
+      SetExternalVisibleDeclsForName(decl_context, decl_name, operator_decls);
+      return true;
+    }
     case clang::DeclarationName::Identifier: {
       identifier = decl_name.getAsIdentifierInfo();
       break;
--- a/toolchain/check/cpp/operators.cpp
+++ b/toolchain/check/cpp/operators.cpp
@@ -11,6 +11,7 @@
 #include "toolchain/check/convert.h"
 #include "toolchain/check/core_identifier.h"
 #include "toolchain/check/cpp/custom_type_mapping.h"
+#include "toolchain/check/cpp/export.h"
 #include "toolchain/check/cpp/import.h"
 #include "toolchain/check/cpp/location.h"
 #include "toolchain/check/cpp/overload_resolution.h"
@@ -897,6 +898,11 @@
                           best_viable_fn->Function->getNameAsString()));
         return SemIR::ErrorInst::InstId;
       }
+      // A Carbon operator impl exported to C++ (fork decision F-017) is not a
+      // C++ candidate: Carbon's own impl lookup has already found that impl.
+      if (IsExportedCarbonOperator(context, best_viable_fn->Function)) {
+        return SemIR::InstId::None;
+      }
       sema.MarkFunctionReferenced(loc, best_viable_fn->Function);

       // If this is an operator method, the first arg will be used as self.
```

### §2.5 Goldens (sources only: `// AUTOUPDATE`, no CHECK lines; R15, R16(a))

Three new files, filled only by autoupdate (commit 4). Splits whose name begins
`fail_` must fail; the others must compile (M-12 measured both ways on trunk,
`v3` and `v4`). No existing golden changes (M-8).

#### toolchain/check/testdata/interop/cpp/class/export/operator.carbon (19 splits)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/operator.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/operator.carbon

// Carbon operator impls on an exported Carbon class are C++ operators (fork
// decision F-017, docs/design/interoperability/operators.md): an impl whose
// `Self` is the class is a member operator, `const` for a `self` member and
// lvalue-ref-qualified (`&`) for a `ref self` one; an impl whose `Self` C++
// sees as anything else and whose operand is the class is a non-member
// operator in the class's namespace, found by argument-dependent lookup. The
// `static_assert`s pin the C++ result types. The sibling operator_ast.carbon
// pins the declarations Clang is handed; lower/.../operator.carbon the thunks.

// --- arithmetic.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents + other.cents); }
}
impl Money as Core.SubWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents - other.cents); }
}
impl Money as Core.MulWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents * k); }
}
impl Money as Core.DivWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents / k); }
}
impl Money as Core.ModWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents % k; }
}
impl Money as Core.Negate where .Result = Money {
  fn Op(self) -> Money { return Money.Make(-self.cents); }
}

inline Cpp '''
using Carbon::Money;
static_assert(__is_same(decltype(Money::Make(1) + Money::Make(2)), Money));
static_assert(__is_same(decltype(Money::Make(1) - Money::Make(2)), Money));
static_assert(__is_same(decltype(Money::Make(1) * 3), Money));
// C++ converts a `long` operand to the impl's `int`; Carbon would need an
// `impl Money as MulWith(i64)` (a documented divergence).
static_assert(__is_same(decltype(Money::Make(1) * 3L), Money));
static_assert(__is_same(decltype(Money::Make(1) / 3), Money));
static_assert(__is_same(decltype(Money::Make(1) % 3), int));
static_assert(__is_same(decltype(-Money::Make(1)), Money));
inline int Use(const Money& a, const Money& b) {
  return (a + b - b * 2 / 3).cents + a % 7 + (-a).cents;
}
''';

// --- compound_assignment.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents += other.cents; }
}
impl Money as Core.MulAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents *= k; }
}
impl Money as Core.Inc {
  fn Op(ref self) { ++self.cents; }
}
impl Money as Core.Dec {
  fn Op(ref self) { --self.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int Use(Money a, Money b) {
  static_assert(__is_same(decltype(a += b), void));
  static_assert(__is_same(decltype(++a), void));
  a += b;
  a *= 2;
  ++a;
  --a;
  return a.cents;
}
''';

// --- fail_compound_assignment_rvalue.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents += other.cents; }
}

inline Cpp '''
using Carbon::Money;
// A `ref self` operator is `&`-qualified: like a `ref self` method, it is not
// callable on a temporary.
inline void Use(Money b) { Money::Make(1) += b; }
''';

// --- fail_postfix_increment.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.Inc {
  fn Op(ref self) { ++self.cents; }
}

inline Cpp '''
// Carbon's `++` is a prefix statement: only `operator++()` is exported.
inline void Use(Carbon::Money& a) { a++; }
''';

// --- comparison.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}
impl Money as Core.OrderedWith(Money) {
  fn Less(self, other: Money) -> bool { return self.cents < other.cents; }
  fn LessOrEquivalent(self, other: Money) -> bool { return self.cents <= other.cents; }
  fn Greater(self, other: Money) -> bool { return self.cents > other.cents; }
  fn GreaterOrEquivalent(self, other: Money) -> bool { return self.cents >= other.cents; }
}

class Unknowable {
  var v: i32;
}

impl Unknowable as Core.EqWith(Unknowable) {
  fn Equal(self, o: Unknowable) -> bool { return self.v != 0 and o.v != 0 and self.v == o.v; }
  fn NotEqual(self, o: Unknowable) -> bool { return self.v != 0 and o.v != 0 and self.v != o.v; }
}

inline Cpp '''
using Carbon::Money;
static_assert(__is_same(decltype(Money() == Money()), bool));
static_assert(__is_same(decltype(Money() != Money()), bool));
static_assert(__is_same(decltype(Money() < Money()), bool));
inline bool Use(Money a, Money b, Carbon::Unknowable u) {
  return (a == b) && (a != b) && (a < b) && (a <= b) && (a > b) && (a >= b) && (u != u);
}
''';

// --- fail_reversed_equality.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

// Carbon has `m == 5` but not `5 == m`; with `operator!=` exported beside
// `operator==`, C++20 does not synthesize the reversed candidate either.
impl Money as Core.EqWith(i32) {
  fn Equal(self, k: i32) -> bool { return self.cents == k; }
}

inline Cpp '''
inline bool Forward(Carbon::Money m) { return m == 5; }
inline bool Reversed(Carbon::Money m) { return 5 == m; }
''';

// --- bitwise.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Bits {
  var v: u8;
}

impl Bits as Core.BitAndWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return {.v = self.v & o.v}; }
}
impl Bits as Core.BitOrWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return {.v = self.v | o.v}; }
}
impl Bits as Core.BitXorWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return {.v = self.v ^ o.v}; }
}
impl Bits as Core.BitComplement where .Result = Bits {
  fn Op(self) -> Bits { return {.v = ^self.v}; }
}
impl Bits as Core.LeftShiftWith(i32) where .Result = Bits {
  fn Op(self, n: i32) -> Bits { return {.v = self.v << (n as u8)}; }
}
impl Bits as Core.RightShiftAssignWith(i32) {
  fn Op(ref self, n: i32) { self.v >>= (n as u8); }
}

inline Cpp '''
using Carbon::Bits;
static_assert(__is_same(decltype(~Bits()), Bits));
inline int Use(Bits a, Bits b) {
  Bits c = (a & b) | (a ^ b);
  c >>= 1;
  return (~c << 2).v;
}
''';

// --- index.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Pair {
  var first: i32;
  var second: i32;
}

impl Pair as Core.IndexWith(i32) where .ElementType = i32 {
  fn At(self, i: i32) -> i32 { if (i == 0) { return self.first; } return self.second; }
}
impl Pair as Core.IndexWith(bool) where .ElementType = i32 {
  fn At(self, b: bool) -> i32 { if (b) { return self.second; } return self.first; }
}

inline Cpp '''
using Carbon::Pair;
static_assert(__is_same(decltype(Pair()[0]), int));
// Two impls of one interface are one C++ overload set: `true` selects the
// `bool` member by exact match, as Carbon's `p[true]` selects `IndexWith(bool)`.
inline int Use(const Pair& p) { return p[0] + p[true]; }
''';

// --- non_member.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
impl i32 as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self == m.cents; }
}
impl i32 as Core.SubAssignWith(Money) {
  fn Op(ref self, m: Money) { self -= m.cents; }
}
impl Cpp.Foo as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self.n + m.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int Use(Money m, int k, Foo f) {
  k -= m;
  return (50 - m) + (5 == m) + (4 != m) + k + (f + m);
}
''';

// --- namespace.carbon

library "[[@TEST_NAME]]";

import Cpp;

namespace Units;

class Units.Money {
  var cents: i32;
  extend impl as Core.SubWith(Units.Money) where .Result = i32 {
    fn Op(self, o: Units.Money) -> i32 { return self.cents - o.cents; }
  }
}

impl i32 as Core.MulWith(Units.Money) where .Result = i32 {
  fn Op(self, m: Units.Money) -> i32 { return self * m.cents; }
}

inline Cpp '''
inline int Use(Carbon::Units::Money a, Carbon::Units::Money b) {
  return (a - b) + 2 * a;
}
''';

// --- base_class.carbon

library "[[@TEST_NAME]]";

import Cpp;

base class Base {
  var v: i32;
}

class Derived {
  extend base: Base;
}

impl Base as Core.AddWith(Base) where .Result = i32 {
  fn Op(self, o: Base) -> i32 { return self.v + o.v; }
}

inline Cpp '''
// C++ member lookup finds `Base::operator+` from a `Derived` and converts
// both operands to `Base`; Carbon's impl lookup for `Derived` finds no
// `AddWith` impl (fail_base_class_carbon_side), a documented divergence.
inline int Use(const Carbon::Derived& d) { return d + d; }
''';

// --- fail_base_class_carbon_side.carbon

library "[[@TEST_NAME]]";

base class Base {
  var v: i32;
}

class Derived {
  extend base: Base;
}

impl Base as Core.AddWith(Base) where .Result = i32 {
  fn Op(self, o: Base) -> i32 { return self.v + o.v; }
}

fn Use(d: Derived) -> i32 { return d + d; }

// --- fail_todo_generic_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T) where .Result = i32 {
  fn Op(self, k: T) -> i32 { return self.cents * (k as i32); }
}

inline Cpp '''
inline int Use(Carbon::Money m) { return m * 3; }
''';

// --- unmappable_impl.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}
impl Money as Core.AddWith((i32, i32)) where .Result = i32 {
  fn Op(self, p: (i32, i32)) -> i32 { return self.cents + p.0 + p.1; }
}

inline Cpp '''
// The tuple impl has no C++ form and is omitted without a diagnostic; C++
// cannot form a tuple operand, so the omission cannot change which impl a
// C++ `+` selects.
inline int Use(Carbon::Money m) { return m + m; }
''';

// --- carbon_side_unmappable.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

// Carbon's impl lookup for `Money as AddWith(Cpp.Foo)` asks C++ for an
// operator, which looks up `operator+` in the exported `Carbon::Money`: the
// impl's tuple result has no C++ form, so it is omitted silently and this
// Carbon-only expression is not rejected.
impl Money as Core.AddWith(Cpp.Foo) where .Result = (i32, i32) {
  fn Op(self, f: Cpp.Foo) -> (i32, i32) { return (self.cents, f.n); }
}

fn Use(m: Money, f: Cpp.Foo) -> i32 { return (m + f).0; }

// --- fail_impl_after_use.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

inline Cpp '''
inline int Use(Carbon::Money m) { return m + m; }
''';

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// --- fail_todo_impl_after_lookup.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

inline Cpp '''
inline int First(Carbon::Money m) { return m + m; }
''';

impl Money as Core.AddWith(i32) where .Result = i32 {
  fn Op(self, k: i32) -> i32 { return self.cents + k; }
}

inline Cpp '''
inline int Second(Carbon::Money m) { return m + 1; }
''';

// --- money_lib.carbon

library "[[@TEST_NAME]]";

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, o: Money) -> i32 { return self.cents + o.cents; }
}

// --- fail_todo_imported_class.carbon

library "[[@TEST_NAME]]";

import Cpp;
import library "money_lib";

inline Cpp '''
// An imported class's impls are not enumerated (W-204), and the class itself
// exports as an empty C++ record (W-203).
inline int Use(Carbon::Money m) { return m + m; }
''';
```

#### toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon (1 split, `--dump-cpp-ast`)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-cpp-ast
// SET-CHECK-SUBSET
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/interop/cpp/class/export/operator_ast.carbon

// The C++ AST that exported Carbon operator impls produce (fork decision
// F-017): `CXXMethodDecl`s of the exported class for impls whose `Self` is
// the class — `const` for `self`, `&` for `ref self` — each an inline
// function whose body calls the impl member's own Carbon thunk
// (`Op__carbon_thunk`, `Equal__carbon_thunk`); an `operator!=` beside an
// `operator==` whose impl leaves `NotEqual` to its default, with the body
// `!(*this == other)`; and a `FunctionDecl` in `namespace Carbon` for an impl
// whose `Self` is `i32`. The sibling operator.carbon pins the uses.

// --- operator.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return {.cents = self.cents + other.cents}; }
}
impl Money as Core.AddAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents += k; }
}
impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}
impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}

inline Cpp '''
inline int Use(Carbon::Money a, Carbon::Money b) {
  a += 1;
  return (a + b != b) + (1 - a);
}
''';
```

#### toolchain/lower/testdata/interop/cpp/class/export/operator.carbon (4 splits)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --clang-arg=-fno-exceptions
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/class/export/operator.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/class/export/operator.carbon

// The lowering of exported Carbon operator impls (fork decision F-017): the
// C++ operator inlines into its caller and calls the impl member's Carbon
// thunk, `_COp__carbon_thunk.<class>.<package>:<interface>...`, which calls
// the impl member `_COp.<class>...`; a default `!=` negates the `==` thunk's
// result; and a Carbon operator expression with a C++ operand still calls the
// Carbon impl directly, not its C++ export.

// --- member.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return {.cents = self.cents + other.cents}; }
}
impl Money as Core.AddAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents += k; }
}

inline Cpp '''
inline int AddInCpp(Carbon::Money a, Carbon::Money b) {
  a += 2;
  return (a + b).cents;
}
''';

fn Call(a: Money, b: Money) -> i32 { return Cpp.AddInCpp(a, b); }

// --- default_not_equal.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}

inline Cpp '''
inline bool NotEqualInCpp(Carbon::Money a, Carbon::Money b) { return a != b; }
''';

fn Call(a: Money, b: Money) -> bool { return Cpp.NotEqualInCpp(a, b); }

// --- non_member.carbon

library "[[@TEST_NAME]]";

import Cpp;

class Money {
  var cents: i32;
}

impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}

inline Cpp '''
inline int SubInCpp(Carbon::Money m) { return 50 - m; }
''';

fn Call(m: Money) -> i32 { return Cpp.SubInCpp(m); }

// --- carbon_side_cpp_operand.carbon

library "[[@TEST_NAME]]";

import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
}

impl Money as Core.AddWith(Cpp.Foo) where .Result = i32 {
  fn Op(self, f: Cpp.Foo) -> i32 { return self.cents + f.n; }
}

inline Cpp '''
inline int AddInCpp(Carbon::Money m, Foo f) { return m + f; }
''';

// Carbon's impl lookup for `Money as AddWith(Cpp.Foo)` also asks C++, which
// now finds the exported `Money::operator+(Foo)`; that candidate is Carbon's
// own impl, so the call below still calls `_COp.Money...` directly.
fn CarbonSide(m: Money, f: Cpp.Foo) -> i32 { return m + f; }

fn CppSide(m: Money, f: Cpp.Foo) -> i32 { return Cpp.AddInCpp(m, f); }
```

### §2.6 Conformance programs (bullet "Type system: C++ interop — exporting Carbon operator overloads into C++", R7)

All seven are single-file `run` programs in fork/conformance/programs/interop/.
The arbiter keeps its filename and bullet; its SKIP line, guard and the
"Write-tests-first stub" header go, its body is the sketch (M-15). Each EXPECT
is re-derived in §1.8.

#### interop/cpp_operator_export.carbon (SKIP → PASS)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// A Carbon class's `Core.AddWith` impl is C++'s `operator+` on the exported
// `Carbon::` type (fork decision F-017): an `inline Cpp` block applies `+`
// to two `Carbon::Meters` values, and Carbon reads the sum back through
// `Cpp.`, so the round trip is observable at runtime (mirroring
// interop/cpp_export_function.carbon). Shape verbatim from
// types/operator_overloading.carbon and
// toolchain/check/testdata/operators/overloaded/add.carbon. 30 + 12 = 42: the
// impl adds the two `value` fields, and `.value` reads the result's field.

import Core library "io";
import Cpp;

class Meters {
  var value: i32;
  fn Make(n: i32) -> Meters { return {.value = n}; }
}

impl Meters as Core.AddWith(Meters) where .Result = Meters {
  fn Op(self, other: Meters) -> Meters {
    return Meters.Make(self.value + other.value);
  }
}

inline Cpp '''
inline int AddMetersInCpp() {
  Carbon::Meters a = Carbon::Meters::Make(30);
  Carbon::Meters b = Carbon::Meters::Make(12);
  // The exported Carbon Core.AddWith impl must surface as operator+ here.
  return (a + b).value;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.AddMetersInCpp());
  return 0;
}
```

#### interop/cpp_operator_export_arithmetic.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   950
//   450
//   2100
//   233
//   1
//   -700
//
// The arithmetic family (fork decision F-017): `AddWith`, `SubWith`,
// `MulWith`, `DivWith` and `ModWith` impls whose `Self` is the class are
// C++ member operators `+ - * / %`, and `Negate` is the unary `-`, each a
// `const` member because each `Op` takes `self` by value. Every value is
// computed by C++ from two amounts of 700 and 250 cents: 700 + 250 = 950;
// 700 - 250 = 450; 700 * 3 = 2100; 700 / 3 = 233 (Carbon's `i32` division
// truncates); 700 % 3 = 1; -(700) = -700. `MulWith(i32)` takes C++'s `int`
// operand, the mixed-type case.

import Core library "io";
import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents + other.cents); }
}
impl Money as Core.SubWith(Money) where .Result = Money {
  fn Op(self, other: Money) -> Money { return Money.Make(self.cents - other.cents); }
}
impl Money as Core.MulWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents * k); }
}
impl Money as Core.DivWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents / k); }
}
impl Money as Core.ModWith(i32) where .Result = Money {
  fn Op(self, k: i32) -> Money { return Money.Make(self.cents % k); }
}
impl Money as Core.Negate where .Result = Money {
  fn Op(self) -> Money { return Money.Make(-self.cents); }
}

inline Cpp '''
using Carbon::Money;
inline int Sum() { return (Money::Make(700) + Money::Make(250)).cents; }
inline int Difference() { return (Money::Make(700) - Money::Make(250)).cents; }
inline int Product() { return (Money::Make(700) * 3).cents; }
inline int Quotient() { return (Money::Make(700) / 3).cents; }
inline int Remainder() { return (Money::Make(700) % 3).cents; }
inline int Negated() { return (-Money::Make(700)).cents; }
''';

fn Run() -> i32 {
  Core.Print(Cpp.Sum());
  Core.Print(Cpp.Difference());
  Core.Print(Cpp.Product());
  Core.Print(Cpp.Quotient());
  Core.Print(Cpp.Remainder());
  Core.Print(Cpp.Negated());
  return 0;
}
```

#### interop/cpp_operator_export_compound.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   15
//   7
//   40
//   2
//   4
//   11
//
// The compound-assignment and increment family (fork decision F-017):
// `AddAssignWith` .. `ModAssignWith`, `Inc` and `Dec` impls take `ref self`,
// so each is a C++ member operator qualified `&` that returns `void` (in
// Carbon these are statements, docs/design/expressions/README.md), and writes
// through to the C++ object it is applied to. Each C++ function starts from
// 10 cents: 10 += 5 is 15; 10 -= 3 is 7; 10 *= 4 is 40; 10 /= 4 is 2
// (truncating); 10 %= 6 is 4; ++, ++, -- from 10 is 11 (prefix only: Carbon
// has no postfix form).

import Core library "io";
import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.AddAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents += other.cents; }
}
impl Money as Core.SubAssignWith(Money) {
  fn Op(ref self, other: Money) { self.cents -= other.cents; }
}
impl Money as Core.MulAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents *= k; }
}
impl Money as Core.DivAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents /= k; }
}
impl Money as Core.ModAssignWith(i32) {
  fn Op(ref self, k: i32) { self.cents %= k; }
}
impl Money as Core.Inc {
  fn Op(ref self) { ++self.cents; }
}
impl Money as Core.Dec {
  fn Op(ref self) { --self.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int AddAssign() { Money a = Money::Make(10); a += Money::Make(5); return a.cents; }
inline int SubAssign() { Money a = Money::Make(10); a -= Money::Make(3); return a.cents; }
inline int MulAssign() { Money a = Money::Make(10); a *= 4; return a.cents; }
inline int DivAssign() { Money a = Money::Make(10); a /= 4; return a.cents; }
inline int ModAssign() { Money a = Money::Make(10); a %= 6; return a.cents; }
inline int IncDec() { Money a = Money::Make(10); ++a; ++a; --a; return a.cents; }
''';

fn Run() -> i32 {
  Core.Print(Cpp.AddAssign());
  Core.Print(Cpp.SubAssign());
  Core.Print(Cpp.MulAssign());
  Core.Print(Cpp.DivAssign());
  Core.Print(Cpp.ModAssign());
  Core.Print(Cpp.IncDec());
  return 0;
}
```

#### interop/cpp_operator_export_compare.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   10
//   10
//   10
//   10
//   10
//   10
//   0
//
// The comparison family (fork decision F-017): `EqWith.Equal` is C++'s `==`,
// `OrderedWith`'s four members are `<`, `<=`, `>` and `>=`. Each C++
// function returns 10 * (a case where the operator is true) + (a case where it
// is false), so 10 is the right answer for each of `==`, `!=`, `<`, `<=`,
// `>` and `>=`, in that order, and a swapped or mis-mapped operator prints
// 0, 1 or 11 instead: a = 1 and b = 2, with (a == a, a == b), (a != b,
// a != a), (a < b, a < a), (a <= a, b <= a), (b > a, a > a), (a >= a, a >= b).
// `Money` leaves `NotEqual` to the interface's default, `not self.Equal(o)`
// (docs/design/expressions/comparison_operators.md), exported as `!(a == b)`.
// `Unknowable` defines its own `NotEqual`, under which an unknown value (0)
// is neither equal nor unequal to anything: (z == one) * 10 + (z != one) is 0
// because C++ calls that `NotEqual`; rewriting `!=` as `!(==)` would print 1.

import Core library "io";
import Cpp;

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl Money as Core.EqWith(Money) {
  fn Equal(self, other: Money) -> bool { return self.cents == other.cents; }
}
impl Money as Core.OrderedWith(Money) {
  fn Less(self, other: Money) -> bool { return self.cents < other.cents; }
  fn LessOrEquivalent(self, other: Money) -> bool { return self.cents <= other.cents; }
  fn Greater(self, other: Money) -> bool { return self.cents > other.cents; }
  fn GreaterOrEquivalent(self, other: Money) -> bool { return self.cents >= other.cents; }
}

class Unknowable {
  var v: i32;
  fn Make(v: i32) -> Unknowable { return {.v = v}; }
}

impl Unknowable as Core.EqWith(Unknowable) {
  fn Equal(self, o: Unknowable) -> bool {
    return self.v != 0 and o.v != 0 and self.v == o.v;
  }
  fn NotEqual(self, o: Unknowable) -> bool {
    return self.v != 0 and o.v != 0 and self.v != o.v;
  }
}

inline Cpp '''
using Carbon::Money;
inline Money A() { return Money::Make(1); }
inline Money B() { return Money::Make(2); }
inline int Eq() { return (A() == A()) * 10 + (A() == B()); }
inline int Ne() { return (A() != B()) * 10 + (A() != A()); }
inline int Lt() { return (A() < B()) * 10 + (A() < A()); }
inline int Le() { return (A() <= A()) * 10 + (B() <= A()); }
inline int Gt() { return (B() > A()) * 10 + (A() > A()); }
inline int Ge() { return (A() >= A()) * 10 + (A() >= B()); }
inline int Unknown() {
  Carbon::Unknowable z = Carbon::Unknowable::Make(0);
  Carbon::Unknowable one = Carbon::Unknowable::Make(1);
  return (z == one) * 10 + (z != one);
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.Eq());
  Core.Print(Cpp.Ne());
  Core.Print(Cpp.Lt());
  Core.Print(Cpp.Le());
  Core.Print(Cpp.Gt());
  Core.Print(Cpp.Ge());
  Core.Print(Cpp.Unknown());
  return 0;
}
```

#### interop/cpp_operator_export_bitwise.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   8
//   14
//   6
//   243
//   48
//   16
//   4
//
// The bitwise and shift family (fork decision F-017): `BitAndWith`,
// `BitOrWith`, `BitXorWith`, `LeftShiftWith` and `RightShiftWith` are C++'s
// `& | ^ << >>`; Carbon's unary `^x`, `BitComplement`, is C++'s `~x` (the
// operation with the most similar semantics, docs/design/README.md, "Operator
// overloading" under C++ interop); the compound forms are `&= |= ^= <<= >>=`.
// `Bits` holds a `u8` (C++ `unsigned char`). With x = 12 (0b1100) and
// y = 10 (0b1010): x & y = 8; x | y = 14; x ^ y = 6; ~x = 255 - 12 = 243;
// x << 2 = 48; 128 >> 3 = 16; and z = 3, then z <<= 2 (12), z |= 1 (13),
// z &= 14 (12), z ^= 5 (9), z >>= 1 (4).

import Core library "io";
import Cpp;

class Bits {
  var v: u8;
  fn Make(v: u8) -> Bits { return {.v = v}; }
}

impl Bits as Core.BitAndWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return Bits.Make(self.v & o.v); }
}
impl Bits as Core.BitOrWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return Bits.Make(self.v | o.v); }
}
impl Bits as Core.BitXorWith(Bits) where .Result = Bits {
  fn Op(self, o: Bits) -> Bits { return Bits.Make(self.v ^ o.v); }
}
impl Bits as Core.BitComplement where .Result = Bits {
  fn Op(self) -> Bits { return Bits.Make(^self.v); }
}
impl Bits as Core.LeftShiftWith(i32) where .Result = Bits {
  fn Op(self, n: i32) -> Bits { return Bits.Make(self.v << (n as u8)); }
}
impl Bits as Core.RightShiftWith(i32) where .Result = Bits {
  fn Op(self, n: i32) -> Bits { return Bits.Make(self.v >> (n as u8)); }
}
impl Bits as Core.BitAndAssignWith(Bits) {
  fn Op(ref self, o: Bits) { self.v &= o.v; }
}
impl Bits as Core.BitOrAssignWith(Bits) {
  fn Op(ref self, o: Bits) { self.v |= o.v; }
}
impl Bits as Core.BitXorAssignWith(Bits) {
  fn Op(ref self, o: Bits) { self.v ^= o.v; }
}
impl Bits as Core.LeftShiftAssignWith(i32) {
  fn Op(ref self, n: i32) { self.v <<= (n as u8); }
}
impl Bits as Core.RightShiftAssignWith(i32) {
  fn Op(ref self, n: i32) { self.v >>= (n as u8); }
}

inline Cpp '''
using Carbon::Bits;
inline Bits X() { return Bits::Make(12); }
inline Bits Y() { return Bits::Make(10); }
inline int And() { return (X() & Y()).v; }
inline int Or() { return (X() | Y()).v; }
inline int Xor() { return (X() ^ Y()).v; }
inline int Complement() { return (~X()).v; }
inline int ShiftLeft() { return (X() << 2).v; }
inline int ShiftRight() { return (Bits::Make(128) >> 3).v; }
inline int Compound() {
  Bits z = Bits::Make(3);
  z <<= 2;
  z |= Bits::Make(1);
  z &= Bits::Make(14);
  z ^= Bits::Make(5);
  z >>= 1;
  return z.v;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.And());
  Core.Print(Cpp.Or());
  Core.Print(Cpp.Xor());
  Core.Print(Cpp.Complement());
  Core.Print(Cpp.ShiftLeft());
  Core.Print(Cpp.ShiftRight());
  Core.Print(Cpp.Compound());
  return 0;
}
```

#### interop/cpp_operator_export_index.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   789
//   97
//
// The indexing family (fork decision F-017): `IndexWith(I).At` is C++'s
// `operator[]`, a `const` member returning the element by value (`At` takes
// `self` and returns a value; the `ref` forms are W-109's). Two impls of one
// interface, `IndexWith(i32)` and `IndexWith(bool)`, are one C++ overload
// set: `t[true]` selects the `bool` member by exact match (`bool` to `int`
// would be a promotion), as Carbon's `t[true]` selects `IndexWith(bool)`. With
// fields 7, 8, 9: t[0] * 100 + t[1] * 10 + t[2] = 789; t[true] is the last
// field (9) and t[false] the first (7), so t[true] * 10 + t[false] = 97.

import Core library "io";
import Cpp;

class Triple {
  var a: i32;
  var b: i32;
  var c: i32;
  fn Make(a: i32, b: i32, c: i32) -> Triple { return {.a = a, .b = b, .c = c}; }
}

impl Triple as Core.IndexWith(i32) where .ElementType = i32 {
  fn At(self, i: i32) -> i32 {
    if (i == 0) {
      return self.a;
    }
    if (i == 1) {
      return self.b;
    }
    return self.c;
  }
}
impl Triple as Core.IndexWith(bool) where .ElementType = i32 {
  fn At(self, last: bool) -> i32 {
    if (last) {
      return self.c;
    }
    return self.a;
  }
}

inline Cpp '''
inline int Digits() {
  const Carbon::Triple t = Carbon::Triple::Make(7, 8, 9);
  return t[0] * 100 + t[1] * 10 + t[2];
}
inline int Ends() {
  const Carbon::Triple t = Carbon::Triple::Make(7, 8, 9);
  return t[true] * 10 + t[false];
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.Digits());
  Core.Print(Cpp.Ends());
  return 0;
}
```

#### interop/cpp_operator_export_nonmember.carbon (new)

```carbon
// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//   11
//   10
//   7
//   33
//
// Operator impls whose `Self` is not an exported Carbon class (fork decision
// F-017): `impl i32 as SubWith(Money)` is the non-member C++ operator
// `int operator-(int, Carbon::Money)` in `namespace Carbon`, found by
// argument-dependent lookup on the `Money` operand, and so are `EqWith`,
// `OrderedWith` and `SubAssignWith` from `i32`, and `AddWith(Money)` from
// the C++ type `Foo`. The left operand is `Self`, as in Carbon: 50 - m(8)
// = 42 (the other order would be -42); (5 == m(5)) * 10 + (4 != m(5)) = 11,
// `!=` from `Equal` alone through `NotEqual`'s default; (4 < m(5)) * 10 +
// (6 <= m(5)) = 10; k = 10, k -= m(3) leaves 7 in the C++ `int`; and
// Foo{30} + m(3) = 33.

import Core library "io";
import Cpp;

inline Cpp '''
struct Foo { int n; };
''';

class Money {
  var cents: i32;
  fn Make(c: i32) -> Money { return {.cents = c}; }
}

impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
impl i32 as Core.EqWith(Money) {
  fn Equal(self, m: Money) -> bool { return self == m.cents; }
}
impl i32 as Core.OrderedWith(Money) {
  fn Less(self, m: Money) -> bool { return self < m.cents; }
  fn LessOrEquivalent(self, m: Money) -> bool { return self <= m.cents; }
  fn Greater(self, m: Money) -> bool { return self > m.cents; }
  fn GreaterOrEquivalent(self, m: Money) -> bool { return self >= m.cents; }
}
impl i32 as Core.SubAssignWith(Money) {
  fn Op(ref self, m: Money) { self -= m.cents; }
}
impl Cpp.Foo as Core.AddWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self.n + m.cents; }
}

inline Cpp '''
using Carbon::Money;
inline int Difference() { return 50 - Money::Make(8); }
inline int Equality() { return (5 == Money::Make(5)) * 10 + (4 != Money::Make(5)); }
inline int Ordering() { return (4 < Money::Make(5)) * 10 + (6 <= Money::Make(5)); }
inline int Assign() { int k = 10; k -= Money::Make(3); return k; }
inline int Foreign() { return Foo{30} + Money::Make(3); }
''';

fn Run() -> i32 {
  Core.Print(Cpp.Difference());
  Core.Print(Cpp.Equality());
  Core.Print(Cpp.Ordering());
  Core.Print(Cpp.Assign());
  Core.Print(Cpp.Foreign());
  return 0;
}
```

### §2.7 Docs (D-OX-13; a new page and a dated amendment, never a rewrite)

#### docs/design/interoperability/operators.md (new)

The page's example is the arbiter's program, so it is compile-verified by the
conformance run (R6); its prose claims are each a measurement of §0.2 or a
split of §2.5. prek's `markdown-toc` hook regenerates the table of contents.

````markdown
# Exporting Carbon operators to C++

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

(The page's `toc` markers, which prek's `markdown-toc` hook fills, are
omitted from this copy.)

## Table of contents

-   [Overview](#overview)
-   [The mapping](#the-mapping)
-   [Member and non-member operators](#member-and-non-member-operators)
-   [Equality and inequality](#equality-and-inequality)
-   [Assignment, increment, and indexing](#assignment-increment-and-indexing)
-   [Carbon operator expressions are unchanged](#carbon-operator-expressions-are-unchanged)
-   [Divergences](#divergences)
-   [0.1 limits](#01-limits)
-   [Alternatives considered](#alternatives-considered)
-   [References](#references)

## Overview

> **Fork design (F-017, 2026-10-14).** No accepted proposal specifies how Carbon
> operators are used from C++. This page is the fork's design decision F-017
> (fork/decision-log.md, "OX-1"), recorded for after-the-fact veto.

The [design overview](../README.md#operator-overloading-1) says that Carbon types
implementing an operator overload using an interface "should get the
corresponding operator overload in C++", so that "implementing `ModWith(U)` in
Carbon for a type effectively implements `operator%` in C++ for that type", and
that operations are matched "according to which operation has the most similar
semantics rather than using the same symbols". This page decides how.

An `impl` of one of the `Core` operator interfaces below is a C++ operator on
the exported Carbon type. C++ code in an `inline Cpp` block that applies the
operator calls the impl's function, through the same kind of thunk as an
exported method:

```carbon
import Core library "io";
import Cpp;

class Meters {
  var value: i32;
  fn Make(n: i32) -> Meters { return {.value = n}; }
}

impl Meters as Core.AddWith(Meters) where .Result = Meters {
  fn Op(self, other: Meters) -> Meters {
    return Meters.Make(self.value + other.value);
  }
}

inline Cpp '''
inline int AddMetersInCpp() {
  Carbon::Meters a = Carbon::Meters::Make(30);
  Carbon::Meters b = Carbon::Meters::Make(12);
  return (a + b).value;
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.AddMetersInCpp());
  return 0;
}
```

This prints `42`.

## The mapping

| `Core` interface member                     | C++ operator          | Parameters and result             |
| ------------------------------------------- | --------------------- | --------------------------------- |
| `AddWith(U).Op`                             | `a + b`               | `const`; returns `Result`         |
| `SubWith(U).Op`                             | `a - b`               | `const`; returns `Result`         |
| `MulWith(U).Op`                             | `a * b`               | `const`; returns `Result`         |
| `DivWith(U).Op`                             | `a / b`               | `const`; returns `Result`         |
| `ModWith(U).Op`                             | `a % b`               | `const`; returns `Result`         |
| `Negate.Op`                                 | `-a`                  | `const`; returns `Result`         |
| `BitAndWith(U).Op`                          | `a & b`               | `const`; returns `Result`         |
| `BitOrWith(U).Op`                           | <code>a \| b</code>   | `const`; returns `Result`         |
| `BitXorWith(U).Op`                          | `a ^ b`               | `const`; returns `Result`         |
| `BitComplement.Op`                          | `~a`                  | `const`; returns `Result`         |
| `LeftShiftWith(U).Op`                       | `a << b`              | `const`; returns `Result`         |
| `RightShiftWith(U).Op`                      | `a >> b`              | `const`; returns `Result`         |
| `AddAssignWith(U).Op` .. `ModAssignWith(U)` | `+=` `-=` `*=` `/=` `%=` | `&`-qualified; returns `void`  |
| `BitAndAssignWith(U).Op` .. shifts          | `&=` <code>\|=</code> `^=` `<<=` `>>=` | `&`-qualified; returns `void` |
| `Inc.Op`, `Dec.Op`                          | `++a`, `--a`          | `&`-qualified; returns `void`     |
| `EqWith(U).Equal`                           | `a == b`              | `const`; returns `bool`           |
| `EqWith(U).NotEqual`                        | `a != b`              | `const`; returns `bool`           |
| `OrderedWith(U).Less`                       | `a < b`               | `const`; returns `bool`           |
| `OrderedWith(U).LessOrEquivalent`           | `a <= b`              | `const`; returns `bool`           |
| `OrderedWith(U).Greater`                    | `a > b`               | `const`; returns `bool`           |
| `OrderedWith(U).GreaterOrEquivalent`        | `a >= b`              | `const`; returns `bool`           |
| `IndexWith(I).At`                           | `a[i]`                | `const`; returns `ElementType`    |

The table is the inverse of the C++ operator import, which maps the same C++
operators onto the same interfaces. Parameters and results map as for an
exported method: a value parameter is a C++ by-value parameter, `self` makes a
`const` member operator, `ref self` an lvalue-ref-qualified (`&`) one, and the
result is returned by value.

Carbon's prefix `^` is C++'s `~`: they are the operations with the most similar
semantics. Some C++ operators have no Carbon interface to come from, so a Carbon
type never has them: unary `+`, postfix `++` and `--`, `!`, `&&`, `||`, the
comma operator, `->`, unary `*` and `&`, `()`, and `<=>`. Carbon's `as` is a
conversion, which C++ spells as a conversion function or constructor rather
than an overloaded operator; it is not exported in 0.1 (fork work item W-208).

## Member and non-member operators

Carbon finds an operator by looking up the impl for the type of its left
operand, `Self`. When `Self` is the exported Carbon class, the impl is a
member operator of that class, so C++ finds it by member lookup on the left
operand, as Carbon does. When `Self` is any other type — a Carbon primitive such
as `i32`, or an imported C++ type — and the operand is an exported Carbon class,
the impl is a non-member operator declared in the C++ namespace of that class,
which C++ finds by argument-dependent lookup on the operand:

```carbon
impl i32 as Core.SubWith(Money) where .Result = i32 {
  fn Op(self, m: Money) -> i32 { return self - m.cents; }
}
```

is `int Carbon::operator-(int, Carbon::Money)`, and C++'s `50-m` calls it.
C++ requires `operator[]` to be a member, so only an `IndexWith` impl whose
`Self` is the class is exported.

## Equality and inequality

`a==b` calls `EqWith(U).Equal` and `a!=b` calls `EqWith(U).NotEqual`. An impl
that does not define `NotEqual` uses the interface's default,
`not self.Equal(other)` ([comparison operators](../expressions/comparison_operators.md#equality)),
and `operator!=` is then exported as `!(a==b)`, so `!=` is available in every
C++ language mode. Because `operator!=` is always declared beside `operator==`,
C++20 does not synthesize reversed `==` candidates: C++ accepts `5==m` only if
Carbon has an `impl i32 as EqWith(Money)`, as Carbon does. No `<=>` is exported,
so C++ never rewrites the relational operators either.

## Assignment, increment, and indexing

The compound assignment operators and `++`/`--` are statements in Carbon and
take `ref self`, so the exported operators are `&`-qualified, return `void`, and
modify the object C++ applies them to; `a+=b` on a temporary does not compile.
`a = b` is not an operator interface in Carbon and stays C++'s copy assignment.
`IndexWith(I).At` takes `self` and returns a value, so `a[i]` is a `const`
member returning the element by value and cannot be assigned to.

## Carbon operator expressions are unchanged

When an operand of a Carbon operator expression is a C++ type, Carbon also asks
C++ for a matching operator. An exported Carbon operator is never such a
candidate: Carbon has already found the impl it was exported from, so the
expression calls that impl directly. An impl whose signature has no C++ mapping,
such as one returning a tuple, is not exported, and no diagnostic results; C++
code cannot form an operand of a type that has no C++ mapping.

## Divergences

Each side resolves an operator expression under its own rules, as for an
exported [overload set](README.md#overload-resolution):

-   C++ applies its implicit conversions to the operands of an exported
    operator, so `m*3L` calls an `impl Money as MulWith(i32)` by converting the
    `long` to `int`, where Carbon would need an impl for `i64`.
-   C++ member lookup searches base classes, so `d+d` on a class derived
    from a Carbon base class calls the base's `AddWith(Base)` impl after
    converting both operands to the base, where Carbon finds no impl for the
    derived class.

The divergence is bounded to which impl runs, or whether the expression
compiles; every exported operator calls exactly one Carbon impl function.

## 0.1 limits

-   A generic impl, such as
    `impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T)`, and the
    impls of a specific of a generic class are not exported (fork work item
    W-202).
-   Only the impls of the file that contains the `inline Cpp` block are
    exported; the impls of an imported library are not (W-204), and a class
    imported from another library is not yet exported correctly (W-203).
-   An impl declared after C++ code has looked up that operator on the class is
    not seen by later C++ code (W-205).
-   `<=>` is not exported until `OrderedWith` declares its three-way `Compare`
    (W-206).
-   Two impls whose operand types map to one C++ type make every use of that
    operator ambiguous in C++ (W-207).
-   `As` and `ImplicitAs` are not exported as C++ conversions (W-208).
-   `a[i]` returns a value until the reference forms of indexing exist
    (W-209, W-109).

## Alternatives considered

-   Exporting only `operator+`, the arbiter's case: rejected, because the
    bullet is the whole operator mapping, not one operator.
-   Exporting every impl as a non-member operator: rejected, because C++ would
    then convert the left operand implicitly, which Carbon's dispatch on `Self`
    never does.
-   Hidden friend functions for impls whose `Self` is the class: rejected,
    because argument-dependent lookup finds a friend through either operand,
    so C++ would convert the left operand implicitly, as with a non-member
    operator.
-   Leaving `!=` to C++20's rewrite of `==`: rejected, because the default
    language mode of an `inline Cpp` block is C++17, and because the rewrite
    adds reversed `==` candidates that Carbon does not have.
-   Making each exported operator evaluate the Carbon operator expression
    rather than call the impl's function: rejected for 0.1, because only
    concrete impls are exported, for which impl lookup selects exactly that
    impl, so both call the same function, and the expression form needs a new
    kind of thunk.

## References

-   [Bidirectional interoperability with C and C++](README.md)
-   [Design overview: operator overloading in C++ interoperability](../README.md#operator-overloading-1)
-   [Operator expressions](../expressions/README.md#operators)
-   Proposal
    [#702: Comparison operators](/proposals/p000702-comparison-operators.md)
-   Proposal
    [#1178: Rework operator interfaces](/proposals/p001178-rework-operator-interfaces.md)
-   Proposal
    [#1191: Bitwise and shift operators](/proposals/p001191-bitwise-and-shift-operators.md)
````

#### docs/design/interoperability/README.md (amendment)

Inserted after the heading at :350, "## TODO: The operator interoperability
model", which stays as it is (DD-1 replaces the section; §6.2 gives the
merge-time edit):

```markdown
> **Fork amendment (2026-10-14, F-017).** The export direction is specified in
> [Exporting Carbon operators to C++](operators.md): an implementation of a
> `Core` operator interface is a C++ operator on the exported Carbon type — a
> member operator when the implementing type is that class, and otherwise a
> non-member operator in the class's namespace that C++ finds by
> argument-dependent lookup. C++ resolves these operators under its own rules,
> a documented divergence like that of exported overload sets.
```

### §2.8 Records (commit 5 moves the row; commit 6 writes the rest, after §8)

**The row** (commit 5, fork/gap-analysis.md:48 at f67ab650d; re-read its line at
rebase, R7). Status MISSING → DONE (D-OX-14); the evidence cell becomes:

```text
OX-1 landed (W-054 DISCHARGED <date>, fork/opexport/plan.md, fork design F-017, docs/design/interoperability/operators.md): an impl of a `Core` operator interface is a C++ operator on the exported Carbon type — the arithmetic, negation, bitwise and shift, compound-assignment, increment and decrement, comparison and indexing interfaces, 31 members — a member operator (`const` for `self`, `&` for `ref self`) when the impl's `Self` is the class, and otherwise a non-member operator in the class's namespace found by argument-dependent lookup (`int - Carbon::Money` from `impl i32 as SubWith(Money)`, `Foo + Carbon::Money` from an imported C++ `Self`); `!=` is exported for an impl that keeps `EqWith`'s default `NotEqual`, as `!(a == b)`, so C++17 has it and C++20 synthesizes no reversed `==`; Carbon's own operator expressions still call the impl, never its C++ export (cpp/class/export/operator.carbon, operator_ast.carbon, lower cpp/class/export/operator.carbon). 7/7 programs PASS — interop/cpp_operator_export (SKIP -> PASS, EXPECT 42) and cpp_operator_export_{arithmetic,compound,compare,bitwise,index,nonmember} — expected, not of record: container run on the built toolchain, GitHub Actions disabled. C++ resolves the exported operators under C++'s rules (operand conversions, base-class lookup), a documented divergence. Gated residue, each a filed item: generic impls and generic-class specifics (W-202), impls of an imported library (W-204, blocked by W-203), an impl declared after C++ looked its operator up (W-205), `<=>` (W-206), same-signature impls (W-207), `As`/`ImplicitAs` (W-208), `ref` indexing (W-209).
```

**The header** (commit 5): "N DONE / M PARTIAL / K MISSING / L DESIGN-ONLY" as
it stands at the commit becomes N+1 DONE and K−1 MISSING (at f67ab650d: 30 / 21
/ 4 / 1 → 31 / 21 / 3 / 1), and the reconciliation sentence after it names the
expected conformance totals of §5 relative to the trunk floor at the commit,
"expected, not of record". Recompute with `grep -cE '^\| [^|]+ \| DONE \|'
fork/gap-analysis.md` and the same for PARTIAL, MISSING and DESIGN-ONLY, before
and after.

**The ledger** (commit 6, fork/inventory/work-items.json). W-054 becomes:

```json
{
 "id": "W-054",
 "title": "OX-1 (LANDED <date>): Carbon operator impls exported as C++ operator overloads (fork design F-017) — member operators for impls on the exported class, non-member operators found by argument-dependent lookup otherwise, the default `!=`, Carbon operator expressions unchanged",
 "kind": "implemented",
 "subsystem": "toolchain/check/cpp (export, generate_ast, operators) + docs/design/interoperability",
 "size": "L",
 "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++",
 "evidence": [
  "toolchain/check/cpp/export.cpp (`OperatorExportTable`, `IsOperatorSignatureMappable`, `GetImplMemberFunctionId`, `ExportImplFunctionAsCppOperator`, `BuildDefaultNotEqualOperator`, `ExportOperatorsToCpp`, `ExportNonMemberOperatorsToCpp`, `IsExportedCarbonOperator`; the one in-function hunk, `BuildCppToCarbonThunkBody`'s `isa<clang::CXXMethodDecl>` condition)",
  "toolchain/check/cpp/generate_ast.cpp (`FindExternalVisibleDeclsByName`: the `CXXOperatorName` arm)",
  "toolchain/check/cpp/operators.cpp (`FindClangOperator`: an exported Carbon operator is not a C++ candidate)",
  "toolchain/check/testdata/interop/cpp/class/export/operator.carbon (19 splits) and operator_ast.carbon; toolchain/lower/testdata/interop/cpp/class/export/operator.carbon (4 splits); filled at <fill commit>",
  "fork/conformance/programs/interop/cpp_operator_export.carbon (SKIP -> PASS) and cpp_operator_export_{arithmetic,compound,compare,bitwise,index,nonmember}.carbon",
  "docs/design/interoperability/operators.md (F-017); the dated amendment in docs/design/interoperability/README.md; fork/opexport/plan.md; fork/decision-log.md \"OX-1 / F-017\"",
  "fork/gap-analysis.md:48 at f67ab650d (the row; the original evidence's :30 was stale)"
 ],
 "blocked_by": [],
 "notes": "Discharged by OX-1 (fork/opexport/plan.md). W-007's precondition was met by sequencing, as for EH-B, UN-2 and OV-3: no other export.cpp contender was in flight except ST-1's disjoint 5-line hunk (PR 55), and every OX-1 edit is a new function, a new switch arm in generate_ast.cpp, a guard in operators.cpp, or the one behaviour-preserving condition in BuildCppToCarbonThunkBody; thunk.cpp and type_mapping.cpp untouched. Residues W-202, W-204..W-209 under this row; W-203 under the type-export row."
}
```

New items (commit 6; `kind`, `subsystem` and `size` as below, `evidence` as
cited):

```json
[
 {"id": "W-202", "title": "OX-1 residue: generic operator impls, and the operator impls of a generic class's specifics, are not exported to C++", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["toolchain/check/cpp/export.cpp `ExportOperatorsToCpp` and `ExportNonMemberOperatorsToCpp` (skip `impl.generic_id` and a class specific)", "toolchain/check/testdata/interop/cpp/class/export/operator.carbon split fail_todo_generic_impl (`impl forall [T: Core.ImplicitAs(i32)] Money as Core.MulWith(T)`: C++ `m * 3` is `invalid operands`; Carbon's `m * 3` compiles)", "fork/opexport/plan.md M-11(a)"], "blocked_by": [], "notes": "A generic impl's `Op` needs a C++ template (or one declaration per C++ argument type C++ asks about), the machinery of the generics-export row (W-117 is the overload-set analogue). Filed at the OX-1 discharge."},
 {"id": "W-203", "title": "Exporting a Carbon class imported from another library yields an empty C++ record: no fields, and an exported method returning it by value corrupts memory (upstream defect)", "kind": "toolchain-defect", "subsystem": "toolchain/check/cpp (export)", "size": "M", "bullet": "Type system: C++ interop — importing C++ types / exporting Carbon types", "evidence": ["fork/opexport/plan.md M-11(d): `.cents` of an imported class is `no member named 'cents'`; an exported `Plus` returning the imported class then `Get()` prints -1265344497 on trunk 0bdce60a5 and -1536643875 on the nightly 2026.10.12 where 42 is right; the C++ AST shows `class Money definition ... empty aggregate` with no FieldDecl", "toolchain/check/cpp/export.cpp:570-618 `ExportAllFieldsToCpp` (a struct field whose class-scope entry is not found is skipped, :581-583)"], "blocked_by": [], "notes": "Found by the OX-1 audit; pre-existing and upstream. The root cause is not yet confirmed: the hypothesis is that `LookupClassFieldByStructField` does not find an imported class's fields in its scope before their import refs are loaded. Fix belongs to the type-export row, not to OX-1."},
 {"id": "W-204", "title": "OX-1 residue: operator impls declared in an imported library are not exported to C++", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["toolchain/check/cpp/export.cpp `ExportOperatorsToCpp` walks `context.impls()` only (the impl lookup's import of associated libraries' impls, check/impl_lookup.cpp:669-691, has no counterpart)", "operator.carbon splits money_lib + fail_todo_imported_class", "fork/opexport/plan.md M-11(d)"], "blocked_by": ["W-203"], "notes": "Needs the class's defining library's impls imported (filtered to the Core operator interfaces), and W-203's class export fixed first. When it lands, check that two files exporting the same impl's operator do not both define the external `<member>__carbon_thunk` symbol at link time (exported methods share that open question)."},
 {"id": "W-205", "title": "OX-1 residue: an operator impl declared after C++ looked that operator up on the class or namespace is not seen by later C++ code", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (generate_ast)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["operator.carbon split fail_todo_impl_after_lookup (the second block's `m + 1` is `invalid operands`, the note names only the first impl)", "clang/lib/AST/DeclBase.cpp:1951-1954 (a stored answer is returned without asking again)", "upstream e476a2bd3 (re-enables external lookup for identifiers after a failure; not yet on the fork)"], "blocked_by": [], "notes": "A use before the impl (fail_impl_after_use) is C++'s own rule and not this item. The fix re-asks the source when the impl set has grown since the cached answer."},
 {"id": "W-206", "title": "OX-1 residue: `<=>` is not exported; the prelude's `OrderedWith` has no `Compare`", "kind": "missing-feature", "subsystem": "core/prelude + toolchain/check/cpp (export)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["core/prelude/operators/comparison.carbon:24 (`TODO: fn Compare`)", "docs/design/expressions/comparison_operators.md:345-380 (`fn Compare(self, u: U) -> Ordering`)"], "blocked_by": [], "notes": "When `Compare` lands, export it as `operator<=>` returning a C++ ordering type that `Ordering`'s four values map to (`std::partial_ordering`, given `Incomparable`), and revisit D-OX-6: `<=>` lets C++20 rewrite the relational operators."},
 {"id": "W-207", "title": "OX-1 residue: two operator impls whose operand types map to one C++ type are ambiguous at every C++ use (the W-118 shape)", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["fork/opexport/plan.md M-11(e) (`AddWith(i64)` beside `AddWith(Cpp.long)`: Carbon rejects the pair as same-structure non-final impls; C++ reports `use of overloaded operator '+' is ambiguous`)"], "blocked_by": [], "notes": "Reachable only with `final` impls or types such as `Core.CppCompat.Long64` beside `i64` (W-118's notes). Each impl keeps its own thunk symbol, so no call has the wrong ABI."},
 {"id": "W-208", "title": "OX-1 residue: `As` and `ImplicitAs` impls are not exported as C++ conversions", "kind": "missing-feature", "subsystem": "toolchain/check/cpp (export, generate_ast)", "size": "M", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["docs/design/README.md:3679-3681 (`ImplicitAs(U)` corresponds to implicit conversions in C++)", "docs/project/milestones.md:169 (operators and conversions named apart)"], "blocked_by": [], "notes": "Clang collects conversion functions from the class definition, so these need an eager export at `CompleteType`, explicit for `As`, implicit for `ImplicitAs`; and C++ may convert by constructor or by conversion function, a design choice F-017 does not make."},
 {"id": "W-209", "title": "OX-1 residue: `operator[]` returns by value; the `ref` forms of indexing are not exported", "kind": "missing-feature", "subsystem": "core/prelude + toolchain/check/cpp (export)", "size": "S", "bullet": "Type system: C++ interop — exporting Carbon operator overloads into C++", "evidence": ["core/prelude/operators/index.carbon:7-10 (`At` only)", "docs/design/expressions/indexing.md:46-97 (`IndexWith.Ref`, `IndirectIndexWith`)"], "blocked_by": ["W-109"], "notes": "When W-109 adds the `ref` forms, export `Ref` as a non-`const` `operator[]` returning `E&` beside the `const` one."}
]
```

W-007's notes gain (commit 6): "OX-1 (<date>, fork/opexport/plan.md D-OX-16):
landed additively by sequencing — new functions in export.cpp and export.h, a
new `CXXOperatorName` arm in generate_ast.cpp, a guard in operators.cpp, and ONE
in-function hunk in a contention file, `BuildCppToCarbonThunkBody`'s
`target.self_param && isa<clang::CXXMethodDecl>(function_decl)` condition,
behaviour-preserving for every earlier caller; thunk.cpp and type_mapping.cpp
untouched; nothing moved or renamed; ST-1's disjoint export.cpp hunk, in PR 55,
was the only other contender in flight. W-054's blocked_by edge is cleared.
Remaining contender: SC-B3 (W-029)."

**The decision log** (commit 6, fork/decision-log.md, newest first under
"Decided"): an entry headed "### OX-1 / F-017: Carbon operator impls exported as
C++ operator overloads (<date>)" that records, in the ST-1 entry's order: the
bullet and the row's move (MISSING → DONE, expected and not of record, the
header delta, the conformance totals as expected); the context (the empty README
section, the provisional overview, V-3); the landed commits by hash (§3's
commits 2 to 6, the plan's revisions, the review folds); WHAT LANDED by
mechanism (the table, the two walks, the default `!=`, the silent omission, the
guard, the one in-function hunk); D-OX-1..D-OX-20 as a veto digest, one line
each with its break condition; the residues W-202..W-209; DEVIATIONS from this
plan (each with its measurement); and the verification record of §8 (what ran,
what did not). The entry is the decision record F-017.

**fork/ORCHESTRATION.md** (commit 6): a dated stamp paragraph after the latest
one — "OX-1 (claude/carbon-fork-0-1-ox, head <hash>: Carbon operator impls
exported as C++ operator overloads, fork design F-017; W-054 discharged, W-202
to W-209 filed, W-210 and W-211 unused; expected <totals>) is OPEN and HELD,
verified on the container-built toolchain" — and the Branches row
`claude/carbon-fork-0-1-ox` changed from PLANNING to "HELD OPEN as PR <n> —
OX-1 at <hash> (W-054 discharged; W-202..W-209 filed; expected <totals>; row
48 DONE expected); merges after DD-1".

**fork/conformance/README.md** (commit 5): the generated program table, by
`python3 fork/conformance/runner.py --update-readme-table` (the arbiter's row
from SKIP to `run`, six new `run` rows); `--self-test` then passes.

## §3 Commit structure (one PR, "OX-1: Carbon operator impls exported as C++ operator overloads", R29(b))

Every commit `--author="jmann345 <jerrymannstan@gmail.com>"`, committer
`Claude <noreply@anthropic.com>`, the session trailers after a blank line,
explicit paths only (R20).

1.  **This plan** (fork/opexport/plan.md), then its review folds (rev 2, and
    rev 3 if a review REJECTs).
2.  **Toolchain**: toolchain/check/cpp/export.cpp, export.h, generate_ast.cpp,
    operators.cpp, §2.1 to §2.4 verbatim. Alone it keeps file_test green (M-8:
    1942 of 1942 with `v4`), so it is a commit of its own.
3.  **Golden sources**: the three files of §2.5 with `// AUTOUPDATE` and no
    CHECK lines. file_test is red from here until commit 4, as R19 expects for
    unfilled goldens.
4.  **The fill**: "Autoupdate testdata goldens on the container arbiter" —
    `autoupdate.sh` twice (R26; M-12 measured that one pass leaves the AST
    golden's positions stale), then `gate.sh`; only the three new files change.
5.  **Programs, docs and the row**: the seven programs of §2.6, the README
    program table (`--update-readme-table`),
    docs/design/interoperability/operators.md and the README amendment (§2.7),
    and the row and header of §2.8, quoting the container conformance run as
    expected, not of record.
6.  **Discharge**, after the two implementation reviews (R29(c): one once a
    hosted run is green; Actions is disabled, so two) and their fold: the
    ledger (W-054, W-202..W-209, W-007's notes), the decision-log entry, the
    ORCHESTRATION stamp and Branches row, this plan's landed notes; preceded by
    the id re-scan of the head.

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

No existing golden is refilled (M-8). Predicted key lines, each taken from the
`v4` fill in the scratch mirror (M-12) with the split's own filename in place
of the substitute's:

| File / split | Must | Key line(s) |
| --- | --- | --- |
| check operator.carbon: arithmetic, compound_assignment, comparison, bitwise, index, non_member, namespace, base_class, unmappable_impl, carbon_side_unmappable, money_lib | compile | no output (no SemIR ranges; the `static_assert`s hold) |
| fail_compound_assignment_rvalue | fail | `error: no viable overloaded '+=' [CppInteropParseError]`; note `candidate function not viable: expects an lvalue for object argument` |
| fail_postfix_increment | fail | `error: cannot increment value of type 'Carbon::Money' [CppInteropParseError]` |
| fail_reversed_equality | fail | `error: invalid operands to binary expression ('int' and 'Carbon::Money') [CppInteropParseError]` (the `Reversed` line only) |
| fail_base_class_carbon_side | fail | ``error: cannot access member of interface `Core.AddWith(Derived)` in type `Derived` that does not implement that interface [MissingImplInMemberAccess]`` |
| fail_todo_generic_impl | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'int') [CppInteropParseError]` |
| fail_impl_after_use | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'Carbon::Money')` |
| fail_todo_impl_after_lookup | fail | `error: invalid operands ... ('Carbon::Money' and 'int')`; note `candidate function not viable: no known conversion from 'int' to 'Carbon::Money' for 1st argument` |
| fail_todo_imported_class | fail | `error: invalid operands to binary expression ('Carbon::Money' and 'Carbon::Money')` |
| check operator_ast.carbon: operator | compile | `CXXMethodDecl ... used operator+= 'void (int) &' inline internal-linkage`; `CXXMethodDecl ... used operator+ 'Carbon::Money (Carbon::Money) const'` calling `Op__carbon_thunk 'void (const Carbon::Money &, const Carbon::Money &, const Carbon::Money &)'`; `CXXMethodDecl ... used operator!= 'bool (Carbon::Money) const'` whose body is `UnaryOperator ... 'bool' prefix '!'` over `CXXMemberCallExpr` of `.operator==`; `FunctionDecl ... used operator- 'int (int, Carbon::Money)' inline internal-linkage` in `namespace Carbon` (147 CHECK lines) |
| lower operator.carbon: member | compile | `define void @"_COp__carbon_thunk.Money.Main:AddWith.7b773fb4f7cbc162.Core"`; `define internal i32 @_ZNK6Carbon5MoneyplES0_` calling it; `define internal void @_ZNR6Carbon5MoneypLEi` |
| default_not_equal | compile | `define internal noundef zeroext i1 @_ZNK6Carbon5MoneyneES0_` with `%lnot = xor i1 %call, true` over `@_ZNK6Carbon5MoneyeqES0_` |
| non_member | compile | `define internal noundef i32 @_ZN6CarbonmiEiNS_5MoneyE` calling `@"_COp__carbon_thunk.Int.be1e879c1ad406d8.Core:SubWith.7b773fb4f7cbc162.Core"` |
| carbon_side_cpp_operand | compile | `define i32 @_CCarbonSide.Main` whose one call is `call i32 @"_COp.Money.Main:AddWith.1ea11ae296c4d4df.Core"(ptr %m, ptr %f)`; `@_CCppSide.Main` reaches `@_ZNK6Carbon5MoneyplE3Foo` (690 CHECK lines in the file) |

The fingerprints in symbol names are the fill's; a reviewer checks the shapes,
not the hex digits, which depend on the specific's fingerprint and are
reproduced by any fill of the same sources.

## §5 Conformance: one SKIP → PASS, six new; delta PASS +7, SKIP −1, programs +6

From the floor of record 128 / 0 / 22 over 150, 48/56 bullets (trunk;
re-measured in the container, M-13) to 135 / 0 / 21 over 156, 49/56 (M-13,
`v4`). Programs that move: interop/cpp_operator_export (SKIP → PASS). New, PASS:
interop/cpp_operator_export_arithmetic, _compound, _compare, _bitwise, _index,
_nonmember. No other program changes status (128 of 128 PASS stay PASS under
`v4`). The bullet "Type system: C++ interop — exporting Carbon operator
overloads into C++" goes from SKIP to PASS with 7 programs. At OX-1's land
time the totals are this delta applied to the trunk floor then (the held PRs
ahead of it move it), stated as expected.

## §6 Churn and collision analysis

### §6.1 Churn

toolchain: export.cpp +547/−1, export.h +24, generate_ast.cpp +25,
operators.cpp +6. Goldens: three new files (≈506, 52 and 113 source lines;
after the fill ≈544, 199 and 690+ lines); no existing golden changes. Programs:
one modified, six new. Docs: one new page (≈230 lines), one 7-line amendment.
Records: the row and header, the ledger (one item replaced, eight added, one
note extended), the decision log, ORCHESTRATION, the conformance README table.

### §6.2 Collisions (measured against each live branch at the heads named)

| Branch (PR) | Head | Shared paths | Resolution |
| --- | --- | --- | --- |
| ST-1 (PR 55) | 21307851a | export.cpp (+5 at :293-300), interop README (+5 at :300), records | the diff applies at offset 5 (M-16); the README hunks are disjoint |
| SC-1 | ee1f905b0 | records only (no file under toolchain/check/cpp; its toolchain work is in check/, impl_lookup.cpp among it, which OX-1 does not edit) | applies cleanly (M-16) |
| UA-2 (PR 51) | f96fe8a7a | records only | none |
| CM-1 (PR 52), SAFE-1 (PR 53), EV-1 (PR 54) | ea573f672, adaae4e35, cb3ef2e74 | records only | none |
| OP-1 (PR 56), OP-2 (PR 57) | 379f20f67, c396efeae | records only (prelude and other check files) | none |
| DD-1 | e27b917c8 | docs/design/interoperability/README.md (+847: it fills "The operator interoperability model"), docs/design/README.md (a fork note at :3659 linking that section), records | §6.2.1's two replacements at OX-1's trunk-sync merge after DD-1 |
| VA-1 | f67ab650d (planning) | records only, if its plan holds | the id blocks are disjoint |

#### §6.2.1 The merge-time edit of DD-1's text

At OX-1's trunk-sync merge after DD-1: drop OX-1's amendment block (§2.7) and
keep DD-1's section; in it, replace the last sentence

```text
The other direction is not implemented: a Carbon type's operator interface implementations are not exported as C++ operators (fork work item W-054).
```

with

```text
The other direction is specified in [Exporting Carbon operators to C++](operators.md) (fork design F-017): a Carbon type's operator interface implementations are C++ operators.
```

and in "Using Carbon from C++" replace

```text
Carbon operator implementations are not exported as C++ operators ([The operator interoperability model](#the-operator-interoperability-model)),
```

with

```text
Carbon operator implementations are C++ operators ([Exporting Carbon operators to C++](operators.md)),
```

Records: every branch edits fork/ORCHESTRATION.md, decision-log.md,
gap-analysis.md and work-items.json; OX-1's edits are an appended entry, one
row, new items and one note, merged at the trunk sync.

### §6.3 Upstream

Upstream has not started operator export (M-17). At the next advance,
e476a2bd3's restructured `FindExternalVisibleDeclsByName` (a
`GetCarbonOwnedDecl` prologue, no negative caching) takes OX-1's arm as one
more case; its negative-lookup erasure should then apply to an empty operator
answer too, which also closes W-205's first half. operators.cpp's include hunk
needs its context refreshed (M-16).

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

-   **R-1 (Carbon-only code rejected).** A Carbon operator expression with a
    C++ operand makes Clang look into the exported class (M-9). Falsifier: the
    `carbon_side_unmappable` and `carbon_side_cpp_operand` splits; a third shape
    that fails (an exported class whose impl's export path diagnoses) is a
    BLOCKER for D-OX-9.
-   **R-2 (the condition hunk).** D-OX-16's claim that every earlier caller
    passes a method under `self_param`. Falsifier: any existing golden changing
    (M-8 says none), or a `cast` assertion in the gate.
-   **R-3 (C++ ambiguity with user C++ operators).** A file that both
    implements `Money as AddWith(Foo)` in Carbon and declares a C++
    `operator+(const Carbon::Money&, Foo)` now gives C++ two candidates, and
    Carbon's own `m+f` (whose C++ search then finds an ambiguity) reports it.
    Falsifier: a probe of that shape; accepted as a user error, and filed
    against W-207 if found in practice.
-   **R-4 (hook reach).** Unqualified lookups of an operator name inside
    `namespace Carbon` C++ code (the support header) reach the non-member walk;
    it only answers for impls whose operand is a Carbon class of that namespace.
    Falsifier: a support-header use that changes behaviour; none exists in the
    goldens (M-8).
-   **R-5 (dead thunks).** Carbon's C++ candidate search exports the operator,
    and its Carbon thunk is defined, even when only Carbon uses it (M-10).
    Accepted: one external function per such impl; falsifier: a link
    duplicate, which needs two files exporting one impl (W-204's note).
-   **R-6 (fill drift).** The AST golden needs two autoupdate passes (M-12). A
    third pass that changes anything but positions is nondeterminism: stop and
    diagnose (R26).
-   **R-7 (the row's status).** D-OX-14 rests on the precedents; a reviewer may
    judge W-202 or W-204 row-bounding. The fallback is PARTIAL, a one-word and
    one-sentence change in §2.8.

### §7.2 Rejected alternatives

-   **§7 A-1: export only `operator+`, the arbiter's case, to flip the row.**
    Rejected as the Goodhart move R16 forbids in spirit: the arbiter would pass
    while the bullet ("Exporting Carbon overloads into C++") stays mostly
    unmet; M-19 shows the other families cost table rows, not mechanisms.
-   **§7 A-2: every impl as a non-member operator.** Rejected: C++ would then
    convert the left operand implicitly, which Carbon's dispatch on `Self` never
    does (D-OX-2).
-   **§7 A-3: hidden friends.** Rejected for the same reason: argument-dependent
    lookup finds a friend through either operand.
-   **§7 A-4: leave `!=` to C++20's rewrite.** Rejected: the default dialect is
    C++17 (M-6), and the rewrite adds reversed `==` candidates Carbon lacks.
-   **§7 A-5: export the witness table's default `NotEqual` function.**
    Rejected for 0.1: it is the interface's function with the impl's specific
    (M-3), which the export path cannot take (it requires a non-generic
    function, export.cpp:891); the C++ `!(a==b)` is the default's body by the
    design text (comparison_operators.md:260).
-   **§7 A-6: export the Carbon operator expression (a thunk that calls through
    the interface) instead of the impl's function.** Rejected for 0.1: for a
    concrete impl both select the same function, and it needs a new thunk kind
    in check/thunk.cpp, a contention file.
-   **§7 A-7: keep OV-3's TODO for an unmappable impl.** Rejected by M-9.
-   **§7 A-8: suppress export while Carbon's impl lookup runs (a context
    flag).** Rejected: a new piece of `Context` state, while the silent
    omission plus the guard need none.
-   **§7 A-9: export conversions (`As`, `ImplicitAs`) now.** Rejected for 0.1
    (D-OX-18, W-208).
-   **§7 A-10: a differential `.diff.cpp` oracle per program.** Rejected: the
    agreeing direction needs none (R30(b)), and an oracle would hide the
    divergences D-OX-15 documents.
-   **§7 A-11: record the row PARTIAL now.** Kept as D-OX-14's fallback, not
    chosen: the concrete set is complete in both operand positions.

## §8 Verification and discharge

1.  `carbonbuild/build.sh /home/user/carbon-ox` and `install.sh` (a full build
    of this worktree; the planner relinked only, so the first full build is the
    implementer's), `carbon version` stamped with the head.
2.  `autoupdate.sh` over the three new files, twice; the second pass changes
    only `<line:N:...>` positions; `gate.sh`: the trunk count plus three
    (`1942+3=1945` files at f67ab650d), all passing.
3.  `conformance.sh` into a fresh directory: 135 / 0 / 21 over 156, 49/56 on
    this branch alone; `runner.py --self-test` passes after the table refresh.
4.  The mutants of M-14 rebuilt from the implemented export.cpp: each must
    fail the programs M-14 names.
5.  The probes of M-9 and M-10 (`side2.carbon` accepted; `mixed.carbon`'s
    Carbon function calls `_COp.Money...`).
6.  prek to a fixpoint on the changed paths (the command below), with R31's
    heading and list-item counts before and after every markdown edit.

    ```bash
    SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest \
      uvx prek run --files <changed paths>
    ```

7.  The id re-scan of the head before commit 6.

Not run, and why: no hosted gate, autoupdate or conformance (Actions is
disabled, R28); no `bazel test` (no Bazel in the container); no clangd-tidy
(not installed); no run of the programs on macOS; the multi-file thunk-symbol
question (W-204's note) cannot be exercised until W-203 is fixed.

## Hand-off notes for the implementer

-   §2.1 to §2.4 is a measured diff: apply it (`git apply`) rather than
    retyping, and keep it byte-identical unless a review finding changes it.
-   The previews used substituted file names; the real files' `[[@TEST_NAME]]`
    and TIP lines differ, which is why the fill must run on the real paths.
-   The `fam.carbon`, `nm.carbon`, `side*.carbon` and `edge/` probes under
    `$X/probes/` are the quickest regression set for a review finding.
-   Watch R31 in every markdown edit: §1.8 and §2.8 hold arithmetic and code
    spans that a reflow could push to a line start.
-   If DD-1 has merged when OX-1 rebases, apply §6.2's two replacements in
    the trunk-sync merge and drop the amendment block of §2.7.
