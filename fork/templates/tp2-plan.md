<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# TP-2 plan: `IsCallPerformable` follows upstream's deferral of every template-dependent call argument (W-374)

**Status:** rev 1, 2026-11-16 -- FOR TWO ADVERSARIAL PLAN REVIEWS. Branch
`claude/carbon-fork-0-1-tp2` (worktree /home/user/carbon-tp2), cut from trunk
701863aa5 (2026-11-16, "Merge trunk 50357c591 into arb3-fix": PR 70 (EH-C), the
weekly upstream check of 2026-11-16, SAFE-3's second stop stamp and ARB-3's
arbiter fixes are on it; no commits of its own before this plan). This is the
templates workstream's second slice; fork/templates/plan.md (TP-1, rev 3,
landed as PR 61) is its parent, as fork/eh/ehc-plan.md sits beside
fork/eh/plan.md. **The spec is W-374** (fork/inventory/work-items.json): TP-1
follows upstream's deferral of every template-dependent call argument, the
`forms_type` exception of D-TP-11 removed so that `IsCallPerformable` reads as
upstream's, deduce_class_args.carbon and every other affected golden refilled
by autoupdate, W-139's convert.cpp requirement (D-SC-19 part 4) withdrawn, and
register rows H10.8 and H9.8 re-classified; owner TP-1's follow-on, on trunk's
base before UA-3. Size: the ledger's M (kept, D.1). **The baseline** for every
figure below is the container arbiter's label tp2-base
(/home/user/arb/install/tp2-base/bin/carbon, built by the orchestrator from
701863aa5, `carbon version` 0.0.0-0.dev+unknown): **gate 2047 passed, 0
failed** (/home/user/arb/logs/gate-tp2-base-20261116T153418Z.log, the
arbiter's check.cpp source patch reported `landed`) and **conformance PASS 228
/ FAIL 0 / SKIP 13 over 241, 51 of 56 bullets**
(/home/user/arb/logs/conformance-tp2-base.log). The nightly
/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12 is a
differential oracle only (R30); it carries upstream's deferral.

**What the measurements settle (§0.3 to §0.6), in four lines.** (1) The
removal is exactly the item's: the function becomes upstream's text at
7a3608bab but for the `OperandDependence(context, ...)` signature the fork
still has (D-TP2-1); on the prototype m17n_d is rejected as on the nightly,
``unable to monomorphize specific `Wrap(D)` `` with the nightly's two notes
(W-374 discharged by measurement). (2) Its cost is large and is recorded, not
licensed away (R32): deduction of a template parameter through a class type
formed from it (`Holder(T)`, `Holder(T)*`, `Vec(N)`, W-193's forms, which
D-TP-11 made work) is lost, as it is absent on the nightly; refutable patterns
on a template-dependent choice value (TP-1 round 10's X-1 family) and
`index_class_with_index_with` return to upstream's `semantics TODO`; two
definition-time diagnostics move to instantiation; two conformance programs
no longer compile. Upstream's deduce.cpp has no mechanism for a
template-dependent splice ("TODO: Handle more cases.", :443 at 7a3608bab) and
the nightly rejects the same programs, so the plan files residues W-396 to
W-399 with probes and break conditions and adds no fork mechanism (R32 (d);
D-TP2-2). (3) W-139's convert.cpp hunk is NOT removed: measured, its removal
re-opens the structural check of a conversion outside a call (e1 and e2 run,
and the SC-1 split `fail_dependent_conversion_unsatisfied` succeeds), while the
deferral alone already keeps it out of every call's path, so the hunk stays,
narrowed by the deferral and re-described (D-TP2-3; the item's "withdrawn" and
H9.8's break condition were premised on the call case). (4) Eleven goldens
refill CHECK-only; one of them, check/testdata/class/destroy_calls.carbon, is
outside generic/template/ by path but is D-TP-11's own refill (TP-1 §1.6) and
changes only in its template split, so the item's break condition is judged
NOT fired, and that judgment is the first question put to the reviews
(D-TP2-4). Eighteen splits are renamed (`fail_todo_` or `todo_fail_`) with the
residues named in their comments; after the renames and the fill the gate is
**2047 passed, 0 failed** and conformance **PASS 226 / FAIL 0 / SKIP 15 over
241, 51 of 56 bullets** (two programs SKIP under R10 with the residue ids).

**Item:** W-374 (R32 (b), (d); weekly upstream checks 2026-11-09 and
2026-11-16; FO-1 D-FO1-2 (4)). **Reserved ids:** W-396 to W-399 (§0.9), all
four filed by D. **No F id.**

**Design authority:** fork/rulebook.md R16, R17, R29, R30, R31, R32 and R33;
fork/decision-log.md DR-0 (register block (vii)), RG-1 (D-RG-1, D-RG-3, D-RG-4,
D-RG-9), the entries "Weekly upstream check 2026-11-09" and "Weekly upstream
check 2026-11-16" (their H10.8 paragraphs); fork/templates/plan.md D-TP-11 and
D-TP-12 (which stand, amended); fork/structural/plan.md D-SC-6 and D-SC-19;
fork/followon/fo1-plan.md D-FO1-2 (4) and D-FO1-13; fork/land/land1-plan.md
D-LAND-6 and Appendix A.

## Sections

§0 Audit (measurements with evidence): 0.1 the baseline; 0.2 the function on
trunk and upstream, D-TP-11, D-SC-19 part 4 and the two hunks' provenance; 0.3
the prototype, its fill and the renames; 0.4 the probes on the three
toolchains; 0.5 the mutants; 0.6 conformance; 0.7 collisions and what UA-3
inherits; 0.8 upstream's direction register (R32 (a), (c)); 0.9 the id
re-scan; 0.10 the tree checker and what is not run. §1 Design (D-TP2-1 to
D-TP2-10). §2 Spec, file by file. §3 Commits, the PR and the landing. §4
Testdata matrix. §5 Conformance delta. §6 Churn and collisions. §7 Risks and
rejected alternatives. §8 Verification. Hand-off notes. Appendix A the
goldens' source edits and each file's CHECK change; B the programs and their
EXPECTs; C the plan and page amendments verbatim; D the records texts verbatim;
E the PR text; F the land-time texts with `<...>` placeholders.

## §0 Audit: measurements with file:line evidence

### §0.1 The baseline

/home/user/arb/install/tp2-base exists (built 2026-11-16 15:34 UTC from
701863aa5 by the orchestrator, /home/user/arb/logs/build-tp2-base.log, "done
status=0"). Its gate: `[  PASSED  ] 2047 tests.`, GATE 2047 passed, 0 failed
(gate-tp2-base-20261116T153418Z.log; the arbiter's source patch
0001-check-unit-infos-in-place.diff reported `landed`, so the repository's
check.cpp was compiled). Its conformance: `CONFORMANCE tp2-base: PASS 228 /
FAIL 0 / SKIP 13 over 241 programs; bullets 51 PASS, 0 FAIL, 5 SKIP, 0
NOT-WRITTEN` (conformance-tp2-base.log.nohup; scoreboard
/home/user/arb/conformance/tp2-base/scoreboard.json). The other installs under
/home/user/arb/install (6de18c1f7, aee70185c, b87f130b2, cb726a230, ehc-fix,
ehc-impl) are older trees and were not used.

### §0.2 The two hunks: trunk, upstream, the decisions behind them

**`IsCallPerformable` on trunk 701863aa5** (toolchain/check/call.cpp:1023-1049;
the comment at :1023-1024, the signature at :1025, D-TP-11's comment and
`forms_type` at :1031-1047):

<!-- google-doc-style-ignore -->

```cpp
// Determines whether a call can be performed immediately (i.e. whether it is
// non-template-dependent).
static auto IsCallPerformable(Context& context, SemIR::InstId callee_id,
                              llvm::ArrayRef<SemIR::InstId> arg_ids) -> bool {
  if (OperandDependence(context, callee_id) ==
      SemIR::ConstantDependence::Template) {
    return false;
  }
  // A generic class, interface or named constraint applied to arguments forms
  // a type. Its arguments are compile-time values that can be symbolic, as in
  // a checked generic, so a template-dependent argument value makes the type
  // dependent without making the call dependent; only an argument whose type
  // is template-dependent defers the call. Forming the type now is what lets
  // `Holder(T)` in a parameter's type deduce `T`.
  bool forms_type =
      context.types()
          .IsOneOf<SemIR::GenericClassType, SemIR::GenericInterfaceType,
                   SemIR::GenericNamedConstraintType>(
              context.insts().Get(callee_id).type_id());
  for (auto arg_id : arg_ids) {
    auto dependence =
        forms_type
            ? OperandDependence(context, context.insts().Get(arg_id).type_id())
            : OperandDependence(context, arg_id);
    if (dependence == SemIR::ConstantDependence::Template) {
      return false;
    }
  }
  return true;
}
```

<!-- google-doc-style-resume -->

**Upstream's at 7a3608bab** (`git -C /home/user/carbon-lang show
upstream/trunk:toolchain/check/call.cpp`, fetched 2026-11-16 16:02 UTC;
toolchain/check/call.cpp:449-464; the same body since the cut c1e83b0b7:425-438
but for 4286832b4's `context.sem_ir()` at :453 and :458):

<!-- google-doc-style-ignore -->

```cpp
// Determines whether a call can be performed immediately (i.e. whether it is
// non-template-dependent).
static auto IsCallPerformable(Context& context, SemIR::InstId callee_id,
                              llvm::ArrayRef<SemIR::InstId> arg_ids) -> bool {
  if (OperandDependence(context.sem_ir(), callee_id) ==
      SemIR::ConstantDependence::Template) {
    return false;
  }
  for (auto arg_id : arg_ids) {
    if (OperandDependence(context.sem_ir(), arg_id) ==
        SemIR::ConstantDependence::Template) {
      return false;
    }
  }
  return true;
}
```

<!-- google-doc-style-resume -->

The fork's `OperandDependence` is still declared on `Context&`
(toolchain/check/action.h:93-102 at 701863aa5: the `InstId`, `MetaInstId`,
`TypeInstId` and `TypeId` overloads), where upstream's at 7a3608bab takes
`const SemIR::File&` (action.h:93-102 there), so C1 writes upstream's body
with `context` where upstream has `context.sem_ir()`; UA-3 converts it with the
fork's other `Context&` lines (§0.7). TP-1's commit that added the exception:
781908afb, "TP-1 (4): class-argument deduction and deferred impl lookup for
templates" (`git log -S forms_type --all --full-history --oneline --
toolchain/check/call.cpp`: 781908afb and the land refill 4ce74a243).

**D-TP-11** (fork/templates/plan.md:2703-2744, quoted in Appendix C.1 with its
amendment) says the type is formed when no argument's _type_ is template
dependent so that "deduction (deduce.cpp:399-465) matches through its specific
as it does for a checked parameter", and its break condition is "a generic
class whose parameter conversion depends on the argument's value". FO-1's
m17n_d is that case (fo1-plan.md:583, §0.4 below): `class Holder(template T:
HasGet)` with an interface `HasGet` converts `T` to `HasGet` at the
definition, D-TP-12 keeps the lookup deferred, and no specific forces it.

**D-SC-19 part 4, W-139's convert.cpp hunk** (toolchain/check/convert.cpp:
2671-2691 at 701863aa5, inside `PerformBuiltinConversion`'s facet block after
`LookupImplWitness` succeeds; commit 25a3c6947, "SC-1 fix: a checked-symbolic
argument for a template binding, and a template-dependent self, are checked
per specific (W-139; leads issue 2153; D-SC-19)", `git log -S 'W-139; D-SC-19'
-- toolchain/check/convert.cpp`):

<!-- google-doc-style-ignore -->

```cpp
        // Fork (SC-1, W-139; D-SC-19): the structural requirements of a
        // template-dependent self were deferred, so the conversion is
        // performed again, as an action, in each specific of the enclosing
        // generic, where the self is concrete and a failure is diagnosed. A
        // delayed action adds none: its specific's concrete counterparts
        // perform it again (`Context::delayed_action_depth`).
        if (target.diagnose &&
            context.constant_values().GetDependence(
                sem_ir.constant_values().Get(type_inst_id)) ==
                SemIR::ConstantDependence::Template &&
            context.delayed_action_depth() == 0 &&
            !context.generic_region_stack().Empty() &&
            FacetTypeHasStructuralRequirements(context, target.type_id)
                .has_value()) {
          AddDependentActionInst(
              context, loc_id,
              SemIR::ConvertToValueAction{
                  .type_id = SemIR::InstType::TypeId,
                  .inst_id = value_id,
                  .target_type_inst_id =
                      context.types().GetTypeInstId(target.type_id)});
        }
```

<!-- google-doc-style-resume -->

Its text of record is fork/followon/fo1-plan.md:1060-1091 (D-FO1-2 (4)): "a
diagnosing facet conversion whose self is template-dependent and whose facet
type has structural requirements adds a `ConvertToValueAction` on the converted
value to the enclosing generic's eval block, performed in each specific ... It
adds none in a delayed action or outside a generic region", added for m17c,
m17f, m17d, m9td "and a template body converts `T` to a template constraint
outside a call too, which PR 60's own install accepts (e1, e2)". The withdrawal
clause (fo1-plan.md:1150-1155, quoted in C.3) says the hunk is withdrawn when
TP-1 follows upstream's deferral "since the `call_action` replay then checks a
template-dependent self again"; the replay checks a call's argument, and e1 and
e2 are not calls (§0.4, §0.5).

Why a successful facet conversion is never deferred by upstream's own
machinery: `Convert` (convert.cpp:3677-3691) tries `PerformBuiltinConversion`
first ("We do this now rather than before attempting any conversion so that we
can still perform builtin conversions on dependent arguments", :3680-3686) and
calls `AddConvertActionIfDependent` only afterwards, on the result; for a
`FacetValue` whose type is already the target the first test of
`AddConvertActionIfDependent` (:3160-3171, "No type conversion is required")
returns `InstId::None`. D-SC-19 makes the structural half of that conversion
succeed symbolically ("structurally satisfied for now", structural plan
:946-980), so without the hunk nothing checks it again.

### §0.3 The prototype, its fill and the renames

The detached worktree /home/user/carbon-tp2-planner at 701863aa5 (removed at
the end of this plan's writing) received the two edits of §2.1 and, at first,
the hunk's removal; the arbiter built it under the label tp2-planner
(/home/user/arb/logs/build-tp2-planner.log, "done status=0
2026-11-16T16:10:30Z", 428 ninja steps) and installed it.

**Gate before the fill** (gate-tp2-planner-20261116T161040Z.log): `GATE
tp2-planner: 2036 passed, 11 failed`, every failure "Autoupdate would make
changes", no crash. The eleven files, classified for the item's break condition
(TP-1's template goldens, SC-1's, or other):

| Golden | Class | Why it changes (hand-traced, then measured) |
| --- | --- | --- |
| check/testdata/generic/template/convert.carbon | TP-1's (C4 refill, plan §1.6) | `A(T)` in `MakeA`'s return type becomes a `call_action` plus `splice_inst`; a `convert_to_value_action` of the splice appears; no STDERR |
| check/testdata/generic/template/deduce_class_args.carbon | TP-1's (D-TP-11's own file) | the five positive deduction splits gain ``cannot deduce value for generic parameter `T` `` (`N`); `fail_class_template_literal_with_dependent_array_bound_unknown_field` loses ``struct `Arr(N)` has no field named `m` `` |
| check/testdata/generic/template/default_init.carbon | TP-1's | `template_interface_facet_value`'s `Tag(U)` and kin become `call_action` splices; no STDERR |
| check/testdata/generic/template/index.carbon | TP-1's | `index_class_with_index_with` gains ``cannot deduce value for generic parameter `T` `` |
| check/testdata/generic/template/match_choice.carbon | TP-1's (round 10, X-1) | `Opt(T)` and `Shape(T)` are splices, so every `match` on them reports ``semantics TODO: `match on unsupported scrutinee type` `` (``refutable pattern binding on unsupported scrutinee type`` for `let` ... `else` and pattern conditions); the specific diagnostics of `fail_nonexhaustive`, `fail_never_matches`, `fail_int_never_matches`, `fail_unknown_alternative`, `fail_guard_on_instantiation`, `fail_int_literal_out_of_range_on_instantiation`, `fail_payload_literal_on_instantiation`, `fail_payload_not_trivial_on_instantiation` and `fail_todo_qualified_alternative` are replaced by that TODO; `class_template_choice` and `fail_unknown_alternative_class_template` (a choice declared in a class template, `C` not formed by a call) are unchanged |
| check/testdata/generic/template/pointer.carbon | TP-1's | `fail_deref_class_type_param` loses ``cannot dereference operand of non-pointer type `C(T)` `` (the deref of a splice waits for instantiation, which the split never makes) |
| check/testdata/named_constraint/template_constraint_dependent.carbon | SC-1's (W-139's splits) | the three `Wrap(D)` splits keep their error and gain the note ``initializing generic parameter `T` declared here`` at `class Holder(template T: HasGet)`, the nightly's shape; `fail_dependent_interface_arg_unsatisfied` reports `W(D)` once, at `J(T)`, with that note at `interface J(template T: HasGet)`, and no longer a second time at the blanket impl's `J(V)` (the W-376 cascade's m18i half); `fail_dependent_conversion_unsatisfied` keeps its error when the hunk stays (§0.5) |
| check/testdata/class/destroy_calls.carbon | TP-1's by substance (D-TP-11's refill, plan §1.6: "generic/template/convert.carbon and class/destroy_calls.carbon refill"), outside generic/template/ by path | only the split `generic_use_inside_template` (`class C(template T: type) {}`, `fn F(template T: type)` at :89-100) changes: `%C.1d0: type = class_type @C, @C(%T) [template]` and the instructions over it become `call_action`/`splice_inst` forms; no STDERR; the other five splits are untouched |
| lower/testdata/template/class.carbon | TP-1's | two SSA names renumbered (`vc1234`'s neighbour, plan §1.6) |
| lower/testdata/template/initialize.carbon | TP-1's | the class-template literal specifics are emitted in another order and with other `%.loc` names (929 insertions, 1061 deletions, CHECK lines only); no STDERR |
| lower/testdata/template/match_choice.carbon | TP-1's (round 10) | `designator_arm`, `let_else_payload` and `int_scrutinee` report the TODOs above and lower nothing; `class_template_choice` unchanged |

**The fill** (autoupdate-tp2-planner-20261116T161118Z.log and ...161132Z.log):
pass 1 `AUTOUPDATE tp2-planner: 11 file(s) changed by this run`, pass 2 `0
file(s) changed`, a fixpoint in one pass (R26). CHECK lines only: on the final
tree the command

<!-- google-doc-style-ignore -->

```text
git diff -U0 -- toolchain/check/testdata toolchain/lower/testdata \
  | grep '^[-+]' | grep -vE '^[-+]{3} |^[-+]\s*// CHECK|^[-+]// --- '
```

<!-- google-doc-style-resume -->

prints nothing (0 lines), where the 36 `// ---` lines it excludes are the
renames below.

**Gate after the fill** (gate-tp2-planner-20261116T161156Z.log): not 2047;
file_test's `fail_`-prefix rule (testing/file_test/file_test_base.cpp:274,
`fail_prefix_problems`) reports eighteen splits in five files: sixteen that
"failed; if failure is expected, add the `fail_` prefix" and two that
"succeeded; if success is expected, remove the `fail_` prefix":

| Golden | Splits that now fail (renamed `fail_todo_`) | Splits that now succeed (renamed `todo_fail_`) |
| --- | --- | --- |
| check generic/template/deduce_class_args.carbon | holder, holder_copy_constraint, holder_pointer, vec_value_param, template_class_type | fail_class_template_literal_with_dependent_array_bound_unknown_field |
| check generic/template/index.carbon | index_class_with_index_with | |
| check generic/template/match_choice.carbon | designator_arm, designator_arm_exhaustive, value_param, nested_match, guard, pattern_forms, int_scrutinee | |
| check generic/template/pointer.carbon | | fail_deref_class_type_param |
| lower template/match_choice.carbon | designator_arm, let_else_payload, int_scrutinee | |

The names follow the tree's convention (418 `fail_` splits, 42 `todo_`, among
them `todo_fail_private_on_redecl` and `todo_fail_alias_two_file`: a split that
should fail and does not is `todo_fail_`; one that should pass and fails is
`fail_todo_`). With the eighteen renames applied as source edits and the hunk
restored (§0.5, M2) the fill converged again in one pass
(autoupdate-tp2-planner-20261116T162905Z.log: 4 files; ...162917Z.log: 0) and
the gate is **`GATE tp2-planner: 2047 passed, 0 failed`**
(gate-tp2-planner-20261116T162929Z.log). The eleven goldens' numstat on the
final tree: destroy_calls 88/59, convert 94/70, deduce_class_args 87/108,
default_init 52/29, index 53/70, match_choice 82/405, pointer 1/5,
template_constraint_dependent 16/17, lower class 2/2, lower initialize
929/1061, lower match_choice 15/530 (insertions/deletions, 3739 CHECK lines in
all).

### §0.4 The probes on the three toolchains

FO-1's probe sources did not survive the 2026-11-09 container reset
(scratchpad/fo1-impl holds a RESUME_NOTES.txt only), so each probe was
re-created from its description in fo1-plan.md §0.2 (:396-410, :505-520,
:565-600) and from the SC-1 splits that pin it; the sources are the plan
writer's scratch (tp2/planner/probes, deleted with it) and are given in full in
Appendix A.4 so that the implementer re-creates them identically. The runner
compiles with `carbon compile --output-last-input-only`, links and runs
(fork/conformance/runner.py's commands). Structural probes share `template
constraint HasGet { fn Get(self) -> i32; }`, `class C { fn Get(self) -> i32 {
return 5; } }`, `class D {}` and `class Holder(template T: HasGet) { var x:
i32; }`; nominal probes (`n` suffix, and the `_d` names of FO-1) replace the
constraint by `interface HasGet { fn Get(self) -> i32; }` with `impl as HasGet`
in `C`. "the same" means the same first diagnostic, count and notes.

**W-374's family (fo1-plan.md:583-586) and the deduction forms:**

| Probe | baseline tp2-base | prototype (M2, §0.5: call.cpp upstream's, the hunk kept) | the nightly |
| --- | --- | --- | --- |
| m17n_d (`var h: Holder(T)` in `Wrap[template T: type]`, interface `HasGet`, called with a `D`) | runs, rc 5 (W-374) | ``unable to monomorphize specific `Wrap(D)` `` with ``cannot convert type `D` into type implementing `HasGet` `` and ``initializing generic parameter `T` declared here``, one error | the same |
| m17n (with a `C`) | prints 5 | prints 5 | prints 5 |
| m17dn_d (m17n_d through a checked `Caller[U: type]`) | runs, rc 5 | ``unable to monomorphize specific `Wrap(U)` `` with the `U` and `D` conversion notes, two errors | the same |
| m17fn_d (`Holder(T)` as `Wrap`'s return type, `var h: Holder(D) = Wrap(d)`) | one error, the caller's ``cannot convert type `D` into type implementing `HasGet` `` | two errors: the caller's, then ``unable to monomorphize specific `Wrap(D)` `` with the same note | the same two |
| ded_holder (`fn GetTemplate[template T: type](h: Box(T)) -> T`, `class Box(T: type)`, called with a `Box(i32)`) | prints 42 | ``cannot deduce value for generic parameter `T` `` | the same |
| ded_holder_pointer (`h: Box(T)*`) | prints 5 | the same error | the same |
| ded_template_class_type (`class TBox(template T: type)`) | prints 9 | the same error | the same |
| ded_vec_value_param (`fn Size[template N: i32](unused v: Vec(N))`) | prints 3 | ``cannot deduce value for generic parameter `N` `` | the same |
| ded_explicit (`fn GetExplicit(template T: type, h: Box(T))`, called `GetExplicit(i32, h)`) | prints 42 | prints 42 | prints 42 |
| ded_checked_twin (`[T: Core.Copy]`) | prints 42 | prints 42 | prints 42 |
| e1n (`let unused y: HasGet = T;` in a template body, interface, called with a `D`) | runs, rc 1 | runs, rc 1 | ``cannot convert type `T` into type implementing `HasGet` `` at the definition |
| e2n (`G(T as HasGet)`) | runs, rc 3 | runs, rc 3 | the same, at the definition |
| e3n (`let y: HasGet = T; return x.(HasGet.Get)();`) | ``unable to monomorphize specific `F(D)` `` | the same | at the definition, then the member note |

e1n and e2n are outside W-374 (a conversion outside a call): on the fork
D-TP-12 keeps the impl lookup deferred and nothing forces the unused facet
value's witness in `F(D)`; filed as W-399 (D-TP2-8).

**W-139's probes (fo1-plan.md :396-420, :505-520, :565-600) on the three
toolchains** (the nightly has no `template constraint`: "unrecognized
declaration introducer" for every structural probe, as FO-1 recorded):

| Probe | baseline tp2-base | prototype with the hunk removed | prototype M2 (the hunk kept) |
| --- | --- | --- | --- |
| m17c (`var h: Holder(T)`, `D`) | ``unable to monomorphize specific `Wrap(D)` `` with SC-1's three notes | the same plus ``initializing generic parameter `T` declared here`` | the same as with the hunk removed (one error) |
| m17 (with a `C`) | prints 5 | prints 5 | prints 5 |
| m17f (`Holder(T)` returned; `var h: Holder(D) = Wrap(d)`) | two errors: the caller's conversion, then `Wrap(D)` | the same two, the second with the generic-parameter note | the same as with the hunk removed |
| m17d (through a checked `Caller`) | `Wrap(D)` with SC-1's notes | the same plus the note | the same |
| m9t, m9td (m17f through a checked `Caller`, `C` and `D`) | m9t prints 5; m9td `Caller(D)`, two errors | the same | the same |
| e1 (`let unused y: HasGet = T;`, structural, `D`) | ``unable to monomorphize specific `F(D)` `` with SC-1's notes | **runs, rc 1** (the hole re-opened) | ``unable to monomorphize specific `F(D)` `` with SC-1's notes |
| e2 (`G(T as HasGet)`) | `F(D)`, the same notes | **runs, rc 3** | `F(D)`, the same notes |
| e1c (e1 with a `C`) | runs, rc 1 | runs, rc 1 | runs, rc 1 |
| conv (`let unused y: HasGet = U;` in a checked generic) | D-SC-6's rejection with `StructuralRequirementNeedsConcreteType` | the same | the same |
| gc, gcd (`Holder(U)` in `Make[U: type]`, `C` and `D`) | gc returns 3; gcd `Make(D)` with SC-1's notes | the same | the same |
| q11e (`overload fn Pick` pair, `Caller[U: type]` with a `D`) | ``unable to monomorphize specific `Caller(D)` `` with SC-1's notes (W-375) | the same | the same |
| thunk1 (`impl W as I` whose `F[template T: HasGet]` implements `I.F[U: type]`, `C`) | prints 9 | prints 9 | prints 9 |
| thunk1d (`D`) | two errors: the thunk's conversion with `DeductionGenericHere`, then `F(D)` (W-376) | the same | the same |
| t3s, t7s (`Take[U: type](h: Holder(U))`; `Outer` to `Inner`) | 4; 6 | 4; 6 | 4; 6 |

Not re-created: declact and declactd (a declaration-region `call_action`
resolved by `MakeSpecific`, fo1-plan.md:570-574), whose exact text is not
recorded; the W-376 splits `fail_symbolic_arg_impl_thunk_unsatisfied` and
m18i's pin `fail_dependent_interface_arg_unsatisfied` cover their mechanism
and are in the gate.

**The changed goldens' splits, checked with `compile --phase=check` on the
three toolchains** (90 splits of six goldens; the full table is the plan
writer's scratch, its rows with a change summarised here):

| Split | baseline | prototype | the nightly |
| --- | --- | --- | --- |
| deduce_class_args: holder, holder_copy_constraint, holder_pointer, template_class_type, vec_value_param | checks | ``cannot deduce value for generic parameter `T` `` (`N`) | the same |
| deduce_class_args: fail_class_template_literal_with_dependent_array_bound_unknown_field | ``struct `Arr(N)` has no field named `m` `` | checks (no diagnostic) | checks |
| deduce_class_args: the other 19 splits | as filled | unchanged | the nightly crashes or rejects seven of them (rc 134 or 139 on `class_template_field_of_where_alias` and `fail_checked_generic_calls_template_with_class_template_runtime_literal`; `unable to monomorphize` on the field-default splits), TP-1's W-273 and W-274 forms |
| index: index_class_with_index_with | checks | ``cannot deduce value for generic parameter `T` `` | the same |
| index: the other 23 splits | as filled | unchanged | the nightly rejects the tuple-index forms at the definition (``type `T` does not support tuple indexing``), TP-1's C3 forms |
| match_choice (check): designator_arm, designator_arm_exhaustive, value_param, nested_match, guard, int_scrutinee | checks | ``semantics TODO: `match on unsupported scrutinee type` `` | ``semantics TODO: `choice alternatives with parameters are not yet supported` `` or ``semantics TODO: `HandleMatchIntroducer` `` |
| match_choice: pattern_forms, let_else_payload (lower) | checks | ``semantics TODO: `refutable pattern binding on unsupported scrutinee type` `` | the same TODOs as above |
| match_choice: the nine `fail_` splits named in §0.3's table | their specific diagnostics | the scrutinee TODO | the nightly's TODOs |
| match_choice: class_template_choice, fail_unknown_alternative_class_template, the five `fail_todo_scrutinee_*`, `fail_todo_case_template_constant`, `fail_todo_pattern_form_deferred_call` | as filled | unchanged | the nightly's TODOs |
| pointer: fail_deref_class_type_param | ``cannot dereference operand of non-pointer type `C(T)` `` | checks | ``cannot dereference operand of non-pointer type `<splice of ...>` `` (the nightly's `*` on a splice is rejected at the definition; TP-1's C3 defers it, D-TP-7) |
| pointer: the other 11 splits | as filled | unchanged | the nightly rejects `*`, `->` and `&` on `T` at the definition (TP-1's C3) |
| template_constraint_dependent: the six splits | as filled | as §0.3's row | not applicable |

So on every form the removal loses, the fork's new answer is the nightly's
answer or the TP-1 toolchain's own `semantics TODO`; nothing crashes.

### §0.5 The mutants (one per decision)

**M2, the convert.cpp hunk kept (D-TP2-3; the task's "which probe shows the
double check or the lost replay"):** the prototype rebuilt with convert.cpp
restored (`git checkout -- toolchain/check/convert.cpp`, an incremental build.sh
under the same label, build-tp2-planner-m2.nohup, "done status=0
2026-11-16T16:24:57Z"). Measured in §0.4's third table: e1 and e2 are rejected
again in `F(D)` (the lost check restored), and every call-form probe (m17c,
m17f, m17d, m9td, gcd, q11e, thunk1d) gives exactly the answer of the
hunk-removed build, one error each with the same notes, so there is no double
check: a call's argument conversion now happens only inside the replay, where
`delayed_action_depth() > 0` and the hunk adds nothing. The gate on M2 against
the hunk-removed fill (gate-tp2-planner-20261116T162545Z.log) differs in
template_constraint_dependent.carbon alone (its
`fail_dependent_conversion_unsatisfied` split failing again as on trunk), and
the refill (autoupdate-tp2-planner-20261116T162636Z.log, 1 file) brings that
golden to the §0.3 row. M2 is the plan's prototype.

**M1, the exception kept under another name (D-TP2-1; "which register check
would miss it"):** the M2 tree with `forms_type` re-added as `type_former` (the
same `IsOneOf` test and ternary; build-tp2-planner-m1.nohup). Measured:
ded_holder prints 42, ded_vec_value_param 3, m17n_d runs with rc 5 and e1 is
rejected, trunk's answers to the letter. Check H10.8 of rg1-checks.tsv is an L
count of upstream commits to toolchain/check/call.cpp (9 at 7a3608bab) and
check_greps.sh runs every check at upstream's tip, so no register check sees the
fork's function and M1 passes them all. What catches it: the gate
(gate-tp2-planner-20261116T163448Z.log, `--filter generic/template`): six
goldens fail, `fail_todo_holder` and its four siblings "succeeded; if success is
expected, remove the `fail_` prefix", `fail_todo_index_class_with_index_with`
and `fail_todo_designator_arm` likewise,
`todo_fail_class_template_literal_with_dependent_array_bound_unknown_field`
"failed", and the SemIR of convert, default_init and the rest reverting; and the
probe m17n_d, whose rc 5 is W-374's defect. The plan therefore names the gate's
prefix rule over the eighteen renamed splits and m17n_d as D-TP2-1's detectors
(§8.5), and registers H10.8 with an L check as before plus the quote rows of
§0.8.

### §0.6 Conformance

On the hunk-removed prototype before any program edit
(/home/user/arb/conformance/tp2-planner, first run): `CONFORMANCE tp2-planner:
PASS 226 / FAIL 2 / SKIP 13 over 241 programs; bullets 50 PASS, 1 FAIL, 5
SKIP`. The two failures: generics/templates_deduce_class_args.carbon (``cannot
deduce value for generic parameter `T` `` at :62:14 `Core.Print(Get(h));` and
:63:14 `Core.Print(GetThrough(&h) * 2);`, ``... `N` `` at :65:14
`Core.Print(Size(v));`) and generics/templates_match_dependent_choice.carbon
(``semantics TODO: `match on unsupported scrutinee type` `` at :46:9, the
`match (s)` of `Count`). Both are TP-1's programs for the forms D-TP2-2
withdraws; neither depends on the hunk. With the two `// SKIP:` directives of
Appendix B and the README table regenerated (`runner.py
--update-readme-table`, which the self-test requires), the second run on the
final tree: **`CONFORMANCE tp2-planner: PASS 226 / FAIL 0 / SKIP 15 over 241
programs; bullets 51 PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN`** (runner exit 0;
the bullet stays PASS by the runner's rule, runner.py:876-900: every non-SKIP
program of the bullet passes and at least one passes). No other program's
output changed (the scoreboard's other 239 rows equal the baseline's).

### §0.7 Collisions and what UA-3 inherits

`git -C /home/user/carbon-tp2 merge-tree --write-tree 701863aa5 2407efa74` (PR
53's held head) exits 1 with four conflicts, all records: fork/ORCHESTRATION.md,
fork/decision-log.md, fork/gap-analysis.md and fork/inventory/work-items.json;
none in toolchain/, testdata or the programs. The merge-time rule (R32 (e),
the SAFE-3 stop stamp): PR 53's branch takes trunk after UA-3 by a merge commit,
and these four resolve by the ordinary records rule (both sides' paragraphs
kept in date order, the ledger's items in id order); TP-2's records then sit
under PR 53's in each file. No other open branch touches call.cpp
(claude/carbon-fork-0-1-safe-wip equals PR 53's tree in toolchain/).

UA-3 inherits (W-394's weekly note, "eleven fork lines in the removed
`Context&` form (ten more than the cut's five; call.cpp:1045-1046 rewrite the
cut's :432)"): C1 replaces trunk's :1045-1046 pair by the cut's one-line form
`OperandDependence(context, arg_id)`, so the fork lines that differ from the
cut drop from eleven to nine, and the mechanical conversion `context` to
`context.sem_ir()` of 4286832b4 then covers `IsCallPerformable` as a clean
merge of upstream's own hunk (the function's text equals upstream's but for
that argument). Measured counts of `OperandDependence(context,` under
toolchain/check at 701863aa5: 15 (call.cpp 6, convert.cpp 6, handle_index.cpp
2, pointer_dereference.cpp 1); after C1: 14 (call.cpp 5). The weekly's eleven
counts lines absent from the cut, a different measure; both are recorded for
UA-3's audit (D.5).

### §0.8 Upstream's direction register (R32 (a), (c))

Read at upstream/trunk 7a3608bab (fetched 2026-11-16 16:02 UTC; `git -C
/home/user/carbon-lang rev-parse upstream/trunk`). Quoted at the tip:

-   toolchain/check/call.cpp:449-464, `IsCallPerformable`, quoted whole in §0.2:
    its comment says "Determines whether a call can be performed immediately"
    and "non-template-dependent)", and the body returns false when
    `OperandDependence(context.sem_ir(), callee_id)` or, for any `arg_id`,
    `OperandDependence(context.sem_ir(), arg_id)` is
    `SemIR::ConstantDependence::Template`. The deferral rule TP-2 follows.
-   toolchain/check/action.h:93-102: the four `OperandDependence(const
    SemIR::File& sem_ir, ...)` overloads (4286832b4); the fork's `Context&`
    form is UA-3's (§0.7).
-   toolchain/check/deduce.cpp:395-460: the `SymbolicBinding` case (:401-437)
    deduces a binding against a constant argument; `StructValue` is "TODO:
    Match field name order between param and arg."; then "// TODO: Handle
    more cases." (:443) and the `default:` arm, which matches a parameter
    instruction against an argument of the same kind only when
    `param_inst.kind().deduce_through()` (:446-456). No case reads through a
    `SpliceInst` or a `call_action`, and no TODO names a mechanism for one:
    upstream is silent on deduction through a template-dependent splice, and
    the nightly's ``cannot deduce value for generic parameter `T` `` (§0.4) is
    that silence (D-TP2-2).
-   docs/design/README.md:3012-3016 ("Template name lookup"),
    docs/design/generics/terminology.md:260-268 ("Definition checking") and
    :306-310, and docs/design/generics/overview.md:102-107, verbatim (their
    markdown links kept as written):

<!-- google-doc-style-ignore -->

```text
README.md:3012-3016:
Member lookup into a template parameter is done in the actual value provided by
the caller, _in addition_ to any constraints. This means member name lookup and
type checking for anything [dependent](generics/terminology.md#dependent-names)
on the template parameter can't be completed until the template is instantiated
with a specific concrete type. When the constraint is just `type`, this gives

terminology.md:262-268:
even with templates, to check semantics of expressions that are not
[dependent](#dependent-names) on any template parameter in the definition.
Adding constraints to template parameters and/or switching them to be checked
allows the compiler to increase how much of the definition can be checked. Any
remaining checks are delayed until [instantiation](#instantiation), which can
fail.

terminology.md:306-310:
    `template` keyword. Expressions using such a binding are
    [dependent](#dependent-names) and are
    [late type checked](#early-versus-late-type-checking) once an instantiation
    provides the binding's value.

overview.md:102-107:
-   With a template generic, the concrete argument value used by the caller is
    used for name lookup and typechecking. With checked generics, that is all
    done with the declared restrictions expressed as the types of bindings in
    the declaration. Inside the body of a checked generic with a facet
    parameter, the API of the facet is just the names defined by the facet type.
-   _Deduced parameters_ are parameters whose values are determined by the types
    of the explicit arguments. Generic facet parameters are typically deduced.
```

<!-- google-doc-style-resume -->

The design has deduction; upstream's toolchain has none through a dependent
class type, the gap W-396 records. The register's remaining quotes:

-   proposals/p002200-template-generics.md:205-210: "Impl lookup is delayed
    until all templated types, interfaces, and parameters are known. As a
    consequence of these differences, type checking of any expression dependent
    on a templated parameter may not be completed until its value is known."
-   docs/design/generics/details.md:1075-1077 (H9.8's quote, unchanged): "a
    template constraint can depend on them."; appendix-witness.md:151-154
    (H9.8's first quote, unchanged).

Upstream commits since the cut touching the function, deduce.cpp's template
handling or those pages (`git -C /home/user/carbon-lang log
c1e83b0b7..upstream/trunk --oneline -- toolchain/check/call.cpp
toolchain/check/deduce.cpp toolchain/check/action.cpp toolchain/check/action.h
docs/design/generics docs/design/README.md`, twelve): 4286832b4 (Generalize
`OperandDependence` to take a `SemIR::File`, PR 8106: the only one that touches
`IsCallPerformable`, at :453 and :458), be0f11be9 (a generic scope around
`where` expressions), 503f09037 (default values for non-generic parameters of
generic functions), db87a84b6 (observe equivalence chains, design and tests),
0d3b606a5 (calls to generic functions with deduced return types), 3af25cc1b
(`-> ref/var/val auto`), 7beb29f8b (a fallback loc for diagnostics on canonical
insts), 2c9739799 (diagnostics through the terminal library), bf5d2a2ac (`->
auto` deduced return types), 62f1cc6a3 (`GenericClassType` renamed
`ParameterizedClassType`: D-TP-11's `IsOneOf` names the old name, one more
reason the exception cannot survive UA-3 unchanged), 230227264 (return storage
only with a return parameter), 4a8993af2 (the `InitializeAction`
"<unexpected>" fix). None changes which operands or which dependence defer a
call, none adds deduction through a splice, and none changes README.md
:3012-3016 or the generics pages' sentences above.

**The register (DR-0's block, RG-1's rows; D-TP2-6).** H10.8 becomes ALIGNED
with the quote of call.cpp:449-464 and README.md:3012-3016; its silence check
stays the L count over toolchain/check/call.cpp, 9 at 7a3608bab (`git log
--oneline c1e83b0b7..7a3608bab -- toolchain/check/call.cpp | wc -l`, the nine
subjects above less the three that touch other files only), read by W-355 as
the merge-rule signal for the function (a count that moves means
`IsCallPerformable` or its file changed upstream: re-read the quote rows). H9.8
stays ALIGNED: its silence check `git grep -c -w ConvertBindingArg` over
toolchain/check at 7a3608bab is 0 (re-run), its break condition's third clause
fired and is re-read (D-TP2-3). The other H9 and H10 rows' checks, re-run at
7a3608bab with check_greps.sh's method: H9.3 `is_template` in
sem_ir/named_constraint.h 0; H9.4 `CalleeCppOverloadSet` 3; H9.6
`new_specific_id` 0; H9.7 `fail_todo_implicit_self_impls` 3; H10.1 the
`AddrOfAction` regex 5 (FIRED, W-394, UA-3's, unchanged by TP-2); H10.4 L over
lower/handle.cpp 2; the expected counts of rg1-checks.tsv at 701863aa5, so no
other row moves.

### §0.9 The id re-scan

After `git -C /home/user/carbon-tp2 fetch origin` (2026-11-16 16:27 UTC): 968
refs, 744 distinct heads (`git for-each-ref`), 10 worktrees (`git worktree
list`), 93 branch lines. `git grep -ohE 'W-3[7-9][0-9]|W-4[0-9][0-9]'` over
fork/ at every head and `grep -rohE` over every worktree's fork/: W-394 and
W-395 on trunk and its descendants (filed by the weekly check of 2026-11-16);
W-390 and W-393 in 21 refs and W-391 and W-392 in 3 (SAFE-3's rev 13 reserved
text on claude/carbon-fork-0-1-safe, the SAFE mirror and the stop stamp's
sentences, no ledger use); W-381 to W-385 EH-C's unused reservation, in prose
only; W-396 to W-399 in 32 to 36 refs, every one a range bound in the id
re-scan sentences of fork/decision-log.md (:1030, :19820, :20067-20068,
:20285-20286, :21302) and fork/direction/plan.md:1034, never a ledger id; no
W-4xx anywhere. The ledger at 701863aa5 holds 313 items, maximum W-395. **The
next free id is W-396**; this plan reserves W-396 to W-399 and files all four
(D-TP2-8).

### §0.10 The tree checker: what is measured and what is not run

Measured by the container arbiter (R28 and R33 as amended 2026-11-09):
build.sh, install.py, gate.sh (file_test over its whole manifest, 2047 files),
autoupdate.sh to a fixpoint, conformance.sh (runner.py over 241 programs),
`runner.py --self-test`; the probes of §0.4 with the three toolchains' own
`carbon` binaries; `git merge-tree`; the id re-scan; prek on the plan. Not run:
Bazel (none in the container), clang-tidy and clangd-tidy, the hosted gate
(Actions disabled), the owner's machine and runner (R28), `--phase=lower`
dumps of the probes (the gate's lower goldens cover them), and FO-1's declact
pair (§0.4). The C++ change compiles under the arbiter's clang 21 with the
repository's flags (the build log has no warning for call.cpp).

## §1 Design

**D-TP2-1, the deferral rule is upstream's, to the letter.** `IsCallPerformable`
(toolchain/check/call.cpp) returns false when the callee or any argument is
`SemIR::ConstantDependence::Template`, as upstream's at 7a3608bab (call.cpp:
449-464, quoted in §0.2 and §0.8); D-TP-11's `forms_type` test, its ternary
and its six-line comment are removed, and nothing takes their place under
another name (R17; M1 of §0.5 is the mutant that keeps the exception renamed,
caught by the gate's prefix rule on the eighteen renamed splits and by m17n_d).
The function's text is upstream's but for `OperandDependence(context, ...)`,
the signature the fork keeps until UA-3 (§0.7). Register row H10.8 becomes
ALIGNED (D-TP2-6). _Break condition:_ upstream changes which operands or which
dependence defer a call in `IsCallPerformable`, or docs/design/README.md
:3012-3016 or p002200:205-210 change; then the row is re-read by the weekly
check (W-355) and this plan amended. _Falsifier of the choice:_ a probe on the
prototype that trunk rejects and the nightly accepts, or the reverse, outside
the forms D-TP2-2 lists (none found in §0.4).

**D-TP2-2, the cost of realignment is recorded, residues are filed, no fork
mechanism is added.** With the type-forming call deferred, `Holder(T)` in a
parameter's type is a `call_action` splice, and the toolchain, like the
nightly, cannot deduce `T` from a `Holder(i32)` argument (§0.4: the five
deduce_class_args splits, index's `index_class_with_index_with`,
templates_deduce_class_args.carbon). Upstream's deduce.cpp has no case for a
splice and its "TODO: Handle more cases." names no mechanism (§0.8), so under
R32 (d) the plan adds none: the forms are filed as W-396 (deduction through a
class type formed from a template parameter: W-193's forms, re-opened, with
`ded_holder` as the probe; the workaround is an explicit template argument,
`ded_explicit`, which runs on every toolchain) and the splits and the program
are renamed and SKIPped with W-396 in their comments. The same deferral makes a
generic choice applied to a template parameter a splice, so refutable patterns
on it return to the scrutinee TODO that trunk reported before TP-1's round 10
(X-1): W-397 (the match_choice splits and templates_match_dependent_choice;
the nightly reports its own TODOs there). Two definition-time diagnostics now
wait for an instantiation that their splits never make: W-398
(`fail_deref_class_type_param` and
`fail_class_template_literal_with_dependent_array_bound_unknown_field`, renamed
`todo_fail_`; the nightly agrees on the first and the second). The gap row
stays PARTIAL; its evidence cell says what is withdrawn (D.7). TP-1's D-TP-11
is amended, not deleted: its history stands and its ruling is superseded by
this decision (C.1). _Break conditions:_ W-396, upstream's deduce.cpp deduces a
binding through a template-dependent splice or the nightly runs `ded_holder`
(then the fork follows the mechanism and the splits lose `fail_todo_`); W-397,
upstream's `match` accepts a scrutinee whose type is a splice; W-398, upstream
diagnoses either form at the definition. _Falsifier of the cost:_ a form the
plan lists as lost that runs on the prototype (none: §0.4's tables).

**D-TP2-3, W-139's convert.cpp hunk stays; the deferral narrows it.** The
item's removal text and H9.8's break condition withdraw "convert.cpp's hunk
(part 4) ... since the `call_action` replay then checks a template-dependent
self again" (fo1-plan.md:1150-1155). Measured (§0.4, §0.5): the replay checks
every call form (m17c, m17f, m17d, m9td, gcd, q11e, thunk1d, the three
`Wrap(D)` splits, one error each, as upstream's m17n_d), but a conversion
outside a call (e1, e2; the SC-1 split `fail_dependent_conversion_unsatisfied`)
is performed once, at the definition, where D-SC-19 defers the structural check
and `Convert` never defers a succeeded builtin conversion (§0.2), so with the
hunk removed `F(D)` runs with rc 1 and the `fail_` split succeeds. The hunk is
therefore kept unchanged in code; what changes is its reach, which the deferral
narrows by itself: a call's argument conversion now happens only in the replay
(`delayed_action_depth() > 0`), where the hunk adds nothing, so it fires for a
conversion outside a call alone, and the M2 mutant shows no double check. The
convert.cpp comment is not edited (it describes the mechanism, not
`Holder(T)`); D-SC-19's and D-FO1-2 (4)'s texts gain a dated amendment that
re-reads the withdrawal clause (C.2, C.3): the premise holds for a call and not
for a conversion outside one, so the clause is replaced by this decision's.
Register row H9.8 stays ALIGNED with its convert.cpp part re-described as
resting on D-SC-19 alone (D.6). W-139's notes gain the dated note (D.2). R17's
one-sentence justification: a `fail_` split that succeeds when the hunk is
removed. _Break condition:_ a probe shows a template-dependent self's
structural requirements checked twice in one specific (then the hunk's
`delayed_action_depth` test is wrong, not its existence), or upstream's
convert.cpp defers a facet conversion of a template-dependent self (then the
hunk follows that mechanism). _Falsifier:_ e1 rejected on a build without the
hunk.

**D-TP2-4, the goldens and the item's break condition.** The eleven goldens of
§0.3 refill by autoupdate only (R16), CHECK lines only; the eighteen renamed
splits are source edits of C1, each with a `// TODO:` line naming the residue
(Appendix A), in the tree's `fail_todo_`/`todo_fail_` convention; no split is
deleted and no CHECK line is hand-written.
check/testdata/class/destroy_calls.carbon is classified TP-1's: TP-1 §1.6 names
it as D-TP-11's refill, its change is confined to the split
`generic_use_inside_template` and is the exact reversal of that refill (`class_type
@C, @C(%T) [template]` back to `call_action` and `splice_inst`), with no
diagnostic. The item's break condition, "the removal changes a golden outside
TP-1's and SC-1's template goldens", reads by path (generic/template/,
lower/template/, named_constraint/) or by substance (the goldens TP-1's D-TP-11
touched); the plan takes the second reading, because the condition's purpose is
a blast radius beyond the template forms, which a template split's reversal is
not, and judges it NOT fired. This is the first question for the plan reviews;
if a review takes the first reading, the item's instruction is to STOP and
report, and this plan is that report (every golden named and classified in
§0.3). _Break condition:_ a golden outside the eleven changes at the
implementer's fill (then stop: the blast radius is wider than measured); a
review rules the path reading (then the orchestrator decides whether the removal
proceeds, with §0.3's table as the evidence).

**D-TP2-5, the programs.** templates_deduce_class_args.carbon and
templates_match_dependent_choice.carbon gain a `// SKIP:` directive under R10
(the exact diagnostic, line and column, the residue id and the un-SKIP
condition; Appendix B), their EXPECT lines unchanged so that un-SKIP is
mechanical; the README program table is regenerated by `runner.py
--update-readme-table` (two rows `run` to `SKIP`), which the self-test
requires. Rewriting the programs with explicit template arguments is rejected
(§7.2: it would hide the loss the SKIP pins). Expected: PASS 226 / FAIL 0 /
SKIP 15 over 241, 51 of 56 bullets (measured, §0.6). R16 (b)'s presumption is
answered: the reason cites R32's realignment and the residues. _Break
condition:_ the implementer's conformance run differs from 226/0/15 or 51/0/5.

**D-TP2-6, the register and the records.** H10.8: ALIGNED, with the quotes of
§0.8 (call.cpp:449-450, :453 and :458; README.md:3012-3016) added to
rg1-quotes.tsv as five rows, the L check kept at 9 with its comment line
rewritten, and the row's break condition D-TP2-1's; its "upstream defers it
(follow, refill deduce_class_args.carbon)" is done. H9.8: ALIGNED, the
convert.cpp part re-described (D-TP2-3), the check unchanged. DR-0's block
(vii) gains "resolved <date> by TP-2". The decision-log entry "TP-2" (D.3)
carries D-TP2-1 to D-TP2-10 and the V-3 check of each statement at 7a3608bab
with the text quoted. The two weekly entries' W-374 lines gain a dated
"resolved by TP-2" note where they are living records (the H10.8 paragraphs
and the register rows, D.4). The TP-1 entry's register paragraph gains the
same note. The gap row's evidence cell is refreshed (D.7). ORCHESTRATION's
header, a dated paragraph, a Branches row, Next actions item 6's W-374 sentence
and the UA-3 sentence (D.8). _Break condition:_ the weekly check classifies a
row otherwise; its records rule.

**D-TP2-7, the slices and the fix budget.** The plan commit; C1 (call.cpp, the
eighteen renames with their TODO lines, the SC-1 split's stale TODO line, the
two SKIP directives, the README table); F1 (the fill); P (the plan and page
amendments of Appendix C); two implementation reviews; at most two fix commits
with their fills; R; D; the PR; the landing (§3). The shrink line: the renames
and the SKIPs may be re-cut by a fix (a split moved between `fail_todo_` and
`todo_fail_` after the fill), the amendments may follow in a later records
commit, but the call.cpp change never shrinks and the hunk is never removed
"to see". _Break condition:_ a third defect needing a toolchain, golden or
program change stops the PR at rev 2 of this plan.

**D-TP2-8, the residues W-396 to W-399.** W-396 deduction through a class type
formed from a template parameter (probe ded_holder; break condition above).
W-397 refutable patterns on a template-dependent choice value (probe: the
program templates_match_dependent_choice.carbon; the match_choice splits).
W-398 two definition-time diagnostics moved to instantiation (probes: the two
`todo_fail_` splits). W-399 a conversion of a template-dependent self to an
interface outside a call, its facet value unused, is never checked: e1n and e2n
run with rc 1 and 3 on trunk and the prototype where the nightly rejects them
at the definition (``cannot convert type `T` into type implementing `HasGet`
``); D-TP-12 keeps the lookup deferred and nothing forces the witness; owner
TP-1's follow-on, not this plan's (outside W-374: not a call). Each entry has
its evidence, removal and break condition (D.1). _Break condition:_ the id
re-scan at D finds any of the four used elsewhere (then the next free ids are
taken and this plan's texts re-numbered by D).

**D-TP2-9, the PR and the landing.** One PR, base trunk, opened by the
orchestrator after a dry review round and landed by LAND-1's D-LAND-6 under
R33 with one landing reviewer, Appendix F's texts; the land tree is measured
by the arbiter: gate 2047 of 2047, conformance 226/0/15 over 241, 51 of 56
bullets. The expected scoreboard is lower than trunk's by two SKIPs, each
explained by D-TP2-5; R33 (a)'s "not regressing against the PR's expected
scoreboard" is read against this plan's figures. _Break condition:_ the land
tree's figures differ (then the landing stops at D-LAND-6 step 4).

**D-TP2-10, the docs.** docs/design/templates.md gains two dated TP-2 notes
(the TP-1 fork note at :228-240 that lists "deduction through a class's
arguments" among the resolved limits, and the W-193 limit bullet at :578-582
that says "Resolved by TP-1"), stating the withdrawal and W-396 (C.4).
docs/design/generics/template_constraints.md:484-487 ("when a template
converts a type that depends on its own template parameters to a template
constraint, as `Holder(T)` does ... the structural requirements are checked in
each specific of the template") stays true, by the replay for a call and by
the hunk for a conversion outside one, and is not edited; verified, not
changed. The gap row's clause on `match` is withdrawn in the evidence cell.
_Break condition:_ the designdocs checker (`runner.py --self-test`'s W2 rule)
rejects a note (then it is reworded, not dropped).

## §2 Spec, file by file

### §2.1 toolchain/check/call.cpp (C1)

The measured diff (the prototype's; `git diff` of the worktree):

<!-- google-doc-style-ignore -->

```diff
@@ -1028,23 +1028,9 @@ static auto IsCallPerformable(Context& context, SemIR::InstId callee_id,
       SemIR::ConstantDependence::Template) {
     return false;
   }
-  // A generic class, interface or named constraint applied to arguments forms
-  // a type. Its arguments are compile-time values that can be symbolic, as in
-  // a checked generic, so a template-dependent argument value makes the type
-  // dependent without making the call dependent; only an argument whose type
-  // is template-dependent defers the call. Forming the type now is what lets
-  // `Holder(T)` in a parameter's type deduce `T`.
-  bool forms_type =
-      context.types()
-          .IsOneOf<SemIR::GenericClassType, SemIR::GenericInterfaceType,
-                   SemIR::GenericNamedConstraintType>(
-              context.insts().Get(callee_id).type_id());
   for (auto arg_id : arg_ids) {
-    auto dependence =
-        forms_type
-            ? OperandDependence(context, context.insts().Get(arg_id).type_id())
-            : OperandDependence(context, arg_id);
-    if (dependence == SemIR::ConstantDependence::Template) {
+    if (OperandDependence(context, arg_id) ==
+        SemIR::ConstantDependence::Template) {
       return false;
     }
   }
```

<!-- google-doc-style-resume -->

After it the function's 16 lines equal upstream's :449-464 with `context` for
`context.sem_ir()` at the two call sites: the command

<!-- google-doc-style-ignore -->

```text
diff <(git -C /home/user/carbon-lang show upstream/trunk:toolchain/check/call.cpp \
        | sed -n 449,464p) \
     <(sed -n 1023,1038p toolchain/check/call.cpp)
```

<!-- google-doc-style-resume -->

prints the two `sem_ir()` lines and nothing else (§8.7 is this check).
`IsOneOf` has no other use in call.cpp; no include becomes unused
(`SemIR::GenericClassType` is still named by `PerformCallToNonFunction`).

### §2.2 toolchain/check/convert.cpp: no change (D-TP2-3)

The hunk at :2671-2691 stays byte for byte. The plan records the measurement
that decides it (§0.4, §0.5) and amends the texts that described it as
withdrawn (C.2, C.3).

### §2.3 Goldens (C1 the sources, F1 the fill)

Eighteen `// ---` lines are renamed and each renamed split gets one `// TODO:`
comment line after its `library "[[@TEST_NAME]]";` line, naming the residue
(Appendix A.1 to A.3, verbatim). In
check/testdata/named_constraint/template_constraint_dependent.carbon the split
`fail_dependent_interface_arg_unsatisfied`'s comment line "// TODO: with
TP-1's eager `J(T)`, the impl's `J(V)` is reported too (W-376)." is replaced
by "// Since TP-2 (W-374) `J(T)` is a deferred `call_action`, so `W(D)` is
reported once; the thunk half of W-376 stands." (A.3). No other source line
changes; F1 refills the eleven files (CHECK lines only, §8.2's check).

### §2.4 Programs (C1)

Appendix B's two `// SKIP:` blocks, inserted after each program's `//
CONFORMANCE-BULLET:` line; EXPECT lines unchanged; fork/conformance/README.md's
two rows regenerated by `python3 -I -B fork/conformance/runner.py
--update-readme-table` (:361 and :368, `run` to `SKIP`).

### §2.5 Plan and page amendments (P)

Appendix C: C.1 D-TP-11's dated amendment (fork/templates/plan.md, after the
"Round 10" paragraph at :2744, and a line in the decision index at :3455-3458);
C.2 D-SC-19's dated amendment (fork/structural/plan.md, appended to the bullet
at :980, and a sentence after D-SC-6's FO-1 paragraph at :446); C.3 D-FO1-2
(4)'s dated amendment (fork/followon/fo1-plan.md, after :1091) and the
withdrawal clause's re-read (:1150-1155 gain a dated sentence); C.4 the two
templates.md notes. r31.py counts before and after each file.

### §2.6 Records (R and D)

Appendix D, verbatim with placeholders: D.1 the ledger (W-374 DISCHARGED;
W-139, W-193, W-376 notes; W-396 to W-399 filed); D.2 W-139's note; D.3 the
decision-log entry "TP-2"; D.4 the dated notes in the TP-1 entry, DR-0's block
and the two weekly entries; D.5 the UA-3 audit note; D.6 the register files
and rows; D.7 the gap row; D.8 ORCHESTRATION.

## §3 Commits (one PR, "TP-2: `IsCallPerformable` follows upstream's deferral of every template-dependent call argument (W-374)", R29 (b))

Every commit: `--author='jmann345 <jerrymannstan@gmail.com>'`, `git -c
user.name=Claude -c user.email=noreply@anthropic.com commit -F <file>` with the
message written first by the Write tool, explicit paths only (R20), never an
amend, the message ending after a blank line with the session's attribution
trailers; prek (R25, §8.6) to a fixpoint before each; R31's counts in the
message of every commit that edits markdown; never a heredoc in the same
command as a commit. Nothing is pushed and no PR is opened by the implementer;
the orchestrator opens the PR after the reviews are dry (EH-C's item 10 form).
Records that claim the discharge go in the last commit.

1.  **Plan**: fork/templates/tp2-plan.md, rev 1 and its revisions. Messages:
    "TP-2 plan (rev 1): IsCallPerformable follows upstream's deferral (W-374)",
    "TP-2 plan (rev 2): reviews A and B folded, <n> findings", "TP-2 plan (rev
    3): focused re-review folded, sign-off".
2.  **C1, the deferral with every checker-visible line**: §2.1's diff, the
    eighteen renames with their TODO lines and the SC-1 split's comment (A.1 to
    A.3), the two SKIP directives and the README rows (§2.4). Gate on C1 alone:
    `GATE <label>: 2036 passed, 11 failed`, exactly §0.3's eleven files, each
    "Autoupdate would make changes", no prefix problem (the renames are in C1)
    and no crash (measured shape, §0.3); `runner.py --self-test` green with the
    regenerated table. Message: "TP-2 (1/3): IsCallPerformable defers every
    template-dependent call argument, as upstream's (W-374); eighteen template
    splits renamed for the forms the deferral loses (W-396 to W-398); two
    programs SKIP". Its body names upstream's tip at the re-fetch and the
    kept hunk (D-TP2-3).
3.  **F1, the fill**: autoupdate.sh to its fixpoint (one pass, a second that
    changes nothing); only CHECK lines change (§8.2's check empty); the eleven
    files of §0.3 and no other. Gate after: 2047 of 2047. Message: "TP-2 (2/3):
    fill C1's goldens (autoupdate)", its body naming the eleven files.
4.  **P, the amendments**: Appendix C's texts, nothing else (no record that
    claims a discharge). r31.py before and after; the designdocs checker green.
    Message: "TP-2 (3/3): D-TP-11, D-SC-19 and D-FO1-2 (4) amended; templates.md
    dated notes; upstream quoted at <tip>".
5.  **Two implementation reviews** (R11; R29 (c)), against C1 to P, each with
    §8's measurements re-run by the reviewer on its own label.
6.  **Fix commits, at most two**, each with its own fill when it changes a
    golden; a records-only commit is not a fix commit. The shrink line is
    D-TP2-7's. _Break condition:_ a third defect needing a toolchain, golden or
    program change stops the PR at rev 2.
7.  **R, the records that claim no discharge**: D.3 without its D-time
    paragraphs, D.4, D.5, D.6 (checked at the re-fetched tip with
    check_greps.sh and check_quotes.sh), D.7's evidence cell. Message: "TP-2
    records: decision-log entry TP-2, register rows H10.8 ALIGNED and H9.8
    re-read, dated notes".
8.  **D, the discharge**: D.1 (W-374 DISCHARGED; W-396 to W-399 filed; the
    notes), D.2, D.8, and D.3's D-time paragraphs (the §8.7 check on the tree
    at <R>, the id re-scan's `<n>` refs and `<w>` worktrees, the discharge
    line "_Discharged by this commit: W-374 (TP-2)._"); no text R or D names a
    PR number or its own sha; `json.load` of the ledger, `runner.py
    --self-test`, the model-identifier grep of the branch's diff (0), the id
    re-scan (§8.9). Message: "TP-2 discharge: W-374 DISCHARGED; W-396 to W-399
    filed; gap row evidence and ORCHESTRATION".
9.  **The focused re-review**: one fresh agent per round over the fix commits,
    R and D; dry when no BLOCKER, no MAJOR and only records-only MINORs; at
    most three rounds; the dry round's records commit sets D.8's Branches row
    phrase to "IMPLEMENTED AND REVIEWED; RE-REVIEW ROUND <k> DRY (base trunk
    701863aa5)".
10. **The PR's records, the orchestrator's**: as EH-C's item 10, with `<N>`
    existing only after the PR opens.

**The PR** (Appendix E) opens with base trunk after a dry round. **Land-time
steps** (D-LAND-6, one landing reviewer, Appendix F): (M) if trunk moved since
701863aa5, `git merge --no-ff` of trunk into the branch, conflicts resolved by
§6.2's rules; (F-M) the refill on the merged branch if autoupdate changes a
file; (L) the arbiter on the branch's head: build, install, gate 2047 of 2047,
conformance 226/0/15 over 241, prek; the landing reviewer's report; the merge
into trunk by the orchestrator, the two pushes, `merged: true`, then the
records commit with F.3 to F.9 filled.

## §4 Testdata matrix (R16: autoupdate fills; the fill must reproduce these lines)

| Golden | Split | Class | Predicted CHECK-relevant change (hand-traced) | Measured on the prototype |
| --- | --- | --- | --- | --- |
| check generic/template/deduce_class_args.carbon | fail_todo_holder (was holder) | TP-1's | STDERR gains ``cannot deduce value for generic parameter `T` [DeductionIncomplete]`` at `return GetTemplate(h);` with `DeductionGenericHere` at `fn GetTemplate`; the dumped SemIR of `GetTemplate` shows `Holder(T)` as `call_action (%Holder.generic, %T)` plus `splice_inst`, not `class_type @Holder, @Holder(%T) [template]` | as predicted |
| the same | fail_todo_holder_copy_constraint, fail_todo_holder_pointer, fail_todo_vec_value_param, fail_todo_template_class_type | TP-1's | the same error at `Get(h)`, `GetThrough(&h)`, `Size(v)`, `GetT(h)` (`N` for `Size`) | as predicted |
| the same | todo_fail_class_template_literal_with_dependent_array_bound_unknown_field | TP-1's | STDERR empty: the literal's conversion to the splice `Arr(N)` is deferred whole (D-TP-24's rule for a template-dependent target), and `Make` is never instantiated | as predicted |
| the same | the other 19 splits | TP-1's | SemIR only where a class template type is formed in a template body (`Make`'s `Arr(N)`, `D(N)`, `Box(T)`): `call_action`/`splice_inst` forms; STDERR unchanged (the `fail_` splits keep ``unable to monomorphize``) | as predicted |
| check generic/template/index.carbon | fail_todo_index_class_with_index_with | TP-1's | ``cannot deduce value for generic parameter `T` `` at `return Get(v, 0);` | as predicted |
| check generic/template/match_choice.carbon | fail_todo_designator_arm, fail_todo_designator_arm_exhaustive, fail_todo_value_param, fail_todo_nested_match, fail_todo_guard, fail_todo_int_scrutinee | TP-1's (X-1) | ``semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]`` at each `match (`; the SemIR dump of the function stops there | as predicted |
| the same | fail_todo_pattern_forms | TP-1's | ``semantics TODO: `refutable pattern binding on unsupported scrutinee type` `` at the first pattern condition | as predicted |
| the same | fail_nonexhaustive, fail_never_matches, fail_int_never_matches, fail_unknown_alternative, fail_guard_on_instantiation, fail_int_literal_out_of_range_on_instantiation, fail_payload_literal_on_instantiation, fail_payload_not_trivial_on_instantiation, fail_todo_qualified_alternative | TP-1's | each specific diagnostic replaced by the scrutinee TODO (one error) | as predicted |
| the same | class_template_choice, fail_unknown_alternative_class_template, fail_todo_scrutinee_template_type, fail_todo_scrutinee_template_tuple, fail_todo_case_template_constant, fail_todo_scrutinee_deferred_call, fail_todo_scrutinee_dependent_member, fail_todo_pattern_form_deferred_call | TP-1's | unchanged (no call forms their scrutinee's type) | unchanged |
| check generic/template/pointer.carbon | todo_fail_deref_class_type_param | TP-1's | STDERR empty: `*c` on a splice-typed operand is a deferred `PointerDereferenceAction` (D-TP-7) that no instantiation performs | as predicted (4 CHECK lines removed) |
| check generic/template/convert.carbon, default_init.carbon; check class/destroy_calls.carbon (`generic_use_inside_template`); lower template/class.carbon, initialize.carbon | the template splits that form `A(T)`, `Tag(U)`, `C(T)`, `D(N)` and kin | TP-1's | SemIR only: `class_type @X, @X(%T) [template]` constants replaced by `call_action` plus `splice_inst`, `type_of_inst` and, where a value is converted to the type, `convert_to_value_action`; lower's specifics renumbered; no STDERR | as predicted; initialize.carbon's specifics are also emitted in another order (929/1061 lines) |
| check named_constraint/template_constraint_dependent.carbon | fail_dependent_class_arg_unsatisfied, fail_dependent_class_return_unsatisfied, fail_dependent_class_arg_checked_caller | SC-1's | the error kept, the note ``initializing generic parameter `T` declared here [InitializingGenericParam]`` at `class Holder(template T: HasGet)` added (the replay's conversion carries the parameter's location, as the nightly's m17n_d) | as predicted |
| the same | fail_dependent_interface_arg_unsatisfied | SC-1's | one error (`W(D)` at `J(T)`) with the note at `interface J(template T: HasGet)`; the second error at the blanket impl's `J(V)` and its notes gone (10 CHECK lines removed) | as predicted |
| the same | fail_dependent_conversion_unsatisfied, dependent_caller, dependent_class_arg, fail_dependent_caller_unsatisfied | SC-1's | unchanged (the first by D-TP2-3; the others' forms do not change) | unchanged |
| lower template/match_choice.carbon | fail_todo_designator_arm, fail_todo_let_else_payload, fail_todo_int_scrutinee | TP-1's | the TODOs above; no IR | as predicted |

Every other golden of the 2047: unchanged (measured: the fill touched eleven
files and the gate passed 2047 after it).

## §5 Conformance delta (from trunk's 228 PASS / 0 FAIL / 13 SKIP over 241, re-measured)

| Program | Baseline | Prototype before the SKIPs | Final | Why |
| --- | --- | --- | --- | --- |
| generics/templates_deduce_class_args.carbon | PASS (21 42 3 16 8) | COMPILE-FAIL (``cannot deduce value for generic parameter `T` `` at :62:14 and :63:14, `N` at :65:14) | SKIP (W-396) | D-TP2-2; EXPECT kept |
| generics/templates_match_dependent_choice.carbon | PASS (0 1 41 7 5 1 0 1 0 2 1 0) | COMPILE-FAIL (``semantics TODO: `match on unsupported scrutinee type` `` at :46:9) | SKIP (W-397) | D-TP2-2; EXPECT kept |
| the other 239 | as the baseline | unchanged | unchanged | the deferral touches no other program's forms (the templates_dependent_* programs form no class type from a template parameter in a parameter type; templates_constraint_lookup's and structural_conformance's calls replay as before) |

Expected and measured: **PASS 226 / FAIL 0 / SKIP 15 over 241; bullets 51
PASS, 0 FAIL, 5 SKIP**. The bullet "Generics: Integrated templates" stays PASS
(runner.py:876-900). The gap tally stays 37 / 17 / 2 / 0 (the row is PARTIAL
before and after).

## §6 Churn and collisions

### §6.1 Churn

call.cpp: 2 insertions, 16 deletions (the function net minus 14 lines).
Goldens: eleven files, 1419 insertions and 2356 deletions of CHECK lines, plus
36 `// ---` lines (eighteen renames) and nineteen TODO lines. Programs: two
blocks of eleven and ten comment lines. README.md: two rows. Plans and pages:
C.1 to C.4. Records: D.1 to D.8.

### §6.2 Collisions and the merge rules

PR 53 (§0.7): four records files, resolved by the records rule; nothing in
toolchain or testdata. UA-3: `IsCallPerformable` merges as upstream's own
4286832b4 hunk once TP-2 lands (the fork's text equals upstream's but for the
argument), and 62f1cc6a3's rename of `GenericClassType` no longer meets a fork
use in call.cpp's function; the eighteen renamed splits and the two SKIPs are
fork files upstream never had. A later fork change that restores any lost form
takes the residue's break condition as its gate.

## §7 Risks and rejected alternatives (falsifiable)

### §7.1 Risks

1.  The removal's blast radius is wider than the eleven goldens at the
    implementer's fill (a nondeterministic ordering in lower/initialize.carbon
    is the candidate, 929/1061 lines). _Falsifier:_ F1's second pass changes a
    file, or the gate after F1 fails a file outside the eleven. Response: stop
    (D-TP2-4's break condition).
2.  A conformance program other than the two regresses on another machine's
    ordering. _Falsifier:_ a run with a FAIL outside §5's rows. Response: the
    program's form joins the residue it belongs to; the plan's rev 2.
3.  The hunk kept (D-TP2-3) double-checks a form not probed. _Falsifier:_ a
    specific with two `ConvertToValueAction` requirements on one self (a
    `--dump-sem-ir` of the eval block shows two). Response: the
    `delayed_action_depth` test is re-measured; the hunk is not removed.
4.  UA-3's advance brings deduction through a splice or `match` on one (none
    of the twelve window commits does). _Falsifier:_ a window commit touching
    deduce.cpp's `default:` arm or pattern_match.cpp's scrutinee test.
    Response: W-396 or W-397 follows it at UA-3.
5.  The item's break condition read by path stops the item at review
    (D-TP2-4). _Falsifier:_ a review ruling the path reading. Response: the
    orchestrator's decision with §0.3's table; the plan stands as the report.

### §7.2 Rejected alternatives (each with its falsifier)

-   **Keeping the exception under a flag or a narrower test** (a type-forming
    call deferred only when its argument's conversion is to a facet type). A
    special case under another name (R17); M1 shows the gate and m17n_d catch
    the behavior whatever the name. _Falsifier:_ upstream adds such a test to
    `IsCallPerformable` (then it is upstream's, followed).
-   **Deferring the whole item to UA-3.** The repair needs no advance
    (upstream's function is the cut's), the weekly check scheduled it before
    UA-3, and UA-3's `IsCallPerformable` merge is clean only once the fork's
    text is upstream's. _Falsifier:_ UA-3's dry run merges call.cpp clean with
    the exception in place (it cannot: 62f1cc6a3 renames the type the exception
    names).
-   **Removing W-139's hunk "as the item says" and filing e1 as a residue.** A
    `fail_` split would succeed and be renamed to hide a check FO-1 added for
    that very form (R16 (b)); the hunk's reach is already narrowed by the
    deferral. _Falsifier:_ e1 rejected without the hunk (D-TP2-3's falsifier).
-   **A fork-side deduction helper for `Holder(T)`** (matching a `call_action`'s
    callee and arguments against an argument's class specific in deduce.cpp).
    Upstream has not designed the mechanism; adding one is the second spelling
    R32 (d) forbids and the task excludes. _Falsifier:_ upstream's deduce.cpp
    gains the case (W-396's break condition).
-   **Rewriting the two programs with explicit template arguments** to keep
    them PASS. Hides the loss; the SKIP with R10's evidence pins it for the
    un-SKIP. _Falsifier:_ none needed; a design choice recorded.
-   **Deleting the lost splits.** R16 (b); the renames keep them as pins.

## §8 Verification

### §8.0 The planner's measurements (done, §0.3 to §0.6)

Baseline tp2-base: gate 2047/0, conformance 228/0/13, 51/0/5. Prototype
tp2-planner: gate 2036/11 before the fill, 2047/0 after the fill and the
renames; conformance 226/2/13 before the SKIPs, 226/0/15 after; the probe
tables of §0.4; the mutants of §0.5. The label's directories
(/home/user/arb/build/tp2-planner, install/tp2-planner,
conformance/tp2-planner, cache-tp2-planner) and the worktree were removed when
this plan was committed; the logs named above stay under /home/user/arb/logs.

### §8.1 Build (implementer)

`Repository=/home/user/carbon-tp2 SHA=tp2-impl
/home/user/arb/carbonbuild/build.sh` in the background (9 to 12 minutes; check
`pgrep -fa 'ninja
-C|file_test|runner.py'` first and wait for another build), then `python3 -I
/home/user/arb/carbonbuild/install.py` with the same variables. The build log
must show no warning in call.cpp.

### §8.2 Autoupdate to its fixpoint

`Repository=/home/user/carbon-tp2 SHA=tp2-impl
/home/user/arb/carbonbuild/autoupdate.sh --threads 4` twice: pass 1 "11 file(s)
changed", pass 2 "0 file(s) changed". CHECK-only check: `git diff -U0 F1^ F1 --
toolchain | grep '^[-+]' | grep -vE
'^[-+]{3} |^[-+]\s*// CHECK'` empty.

### §8.3 Gate

`gate.sh --threads 4`: on C1 alone `2036 passed, 11 failed`, the eleven
files, no prefix problem; after F1 `[  PASSED  ] 2047 tests.`, `GATE tp2-impl:
2047 passed, 0 failed`. The expected count is 2047 (no golden added or split).

### §8.4 Conformance

`Repository=/home/user/carbon-tp2 SHA=tp2-impl
CACHE_HOME=/home/user/arb/cache-tp2-impl
/home/user/arb/carbonbuild/conformance.sh --background`; wait for
/home/user/arb/conformance/tp2-impl/.done with `until` loops of at most nine
minutes; the CONFORMANCE line of §5. `python3 -I -B fork/conformance/runner.py
--self-test` green (the README table regenerated in C1).

### §8.5 The detectors of D-TP2-1 and D-TP2-3 (the reviewers re-run them)

m17n_d rejected with the nightly's two notes (D-TP2-1); `fail_todo_holder` and
the other seventeen renamed splits keep their prefixes under the gate; e1 and
e2 rejected in `F(D)` (D-TP2-3); M1 and M2 as §0.5 if a fix touches call.cpp or
convert.cpp (the implementer re-runs M2's probes on its own build; a reviewer
builds M1 on its own label).

### §8.6 prek, R27 and R31 (every commit)

`SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
XDG_CACHE_HOME=<scratch>/xdg uvx prek run --files <paths>` to a fixpoint; the
cache directory deleted by its literal path at the end; `python3 -I
<scratch>/sv1-fixer5/bin/r31.py <file>` before and after each markdown edit,
counts in the message. R27: the renamed splits are diffed against this plan's
Appendix A spelling.

### §8.7 The function-equals-upstream check (at C1, at D, at L)

`diff <(git -C /home/user/carbon-lang show
upstream/trunk:toolchain/check/call.cpp | sed -n 449,464p) <(sed -n 1023,1038p
toolchain/check/call.cpp)` prints exactly the two lines that differ in
`context.sem_ir()` and nothing else (line numbers re-derived if trunk's file
moved); `git grep -c -w forms_type -- toolchain` is 0.

### §8.8 The register checkers (at R)

`fork/register/check_greps.sh /home/user/carbon-lang <tip>
fork/register/rg1-checks.tsv` and `check_quotes.sh` with the five new quote
rows: 0 FAIL rows.

### §8.9 The id re-scan (before D)

§0.9's script over every ref and worktree after a fetch; W-396 to W-399 unused
elsewhere; the counts written into D.3.

### §8.10 Not run, and why

§0.10's list.

## Hand-off notes for the implementer

1.  Read W-374 in the ledger, D-TP-11 (fork/templates/plan.md:2703-2744),
    D-SC-19 (fork/structural/plan.md:946-980), D-FO1-2 (4) (fo1-plan.md
    :1060-1091 and :1150-1155) and this plan's §0.2 to §0.5 before C1; the hunk
    in convert.cpp is kept on purpose (D-TP2-3).
2.  C1 is §2.1's diff plus Appendix A's source edits and Appendix B's blocks;
    copy them verbatim (R27), then `runner.py --update-readme-table`.
3.  Build in the background with a 7200000 ms timeout and poll with `until`
    loops; a gate or conformance run may overlap another agent's, a build may
    not.
4.  F1 is autoupdate's output only; if pass 2 changes a file, stop (§7.1 risk
    1).
5.  P copies Appendix C verbatim; run r31.py on each file before and after.
6.  R and D copy Appendix D with the placeholders filled from the commits and
    runs they name; D's own sha is "this commit".
7.  Delete the label's four directories and the XDG cache by their literal
    paths when done; keep tp2-base.
8.  Re-create §0.4's probes from Appendix A.4 and keep their outputs in your
    scratch for the reviewers.

## Appendix A: the goldens' source edits and the probes

### A.1 check/testdata/generic/template/deduce_class_args.carbon

Six `// ---` lines change; each renamed split gets the TODO line shown after
its `library` line. Verbatim:

<!-- google-doc-style-ignore -->

```text
// --- fail_todo_holder.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Holder(T)` is a deferred `call_action`, and a
// template parameter is not deduced through it (fork work item W-396).

// --- fail_todo_holder_copy_constraint.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_holder (W-396).

// --- fail_todo_holder_pointer.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_holder (W-396).

// --- fail_todo_vec_value_param.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_holder, for a value parameter (W-396).

// --- fail_todo_template_class_type.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_holder, for a class template (W-396).

// --- todo_fail_class_template_literal_with_dependent_array_bound_unknown_field.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Arr(N)` is a deferred `call_action`, so the
// literal's unknown field is diagnosed only on instantiation, which this
// split never makes (fork work item W-398).
```

<!-- google-doc-style-resume -->

The splits' Carbon code is unchanged: `holder` is `class Holder(T: type) { var
item: T; }`, `fn GetTemplate[template T: type](h: Holder(T)) -> T { return
h.item; }`, `fn Use(h: Holder(i32)) -> i32 { return GetTemplate(h); }` (the
`//@dump-sem-ir-begin` markers around `GetTemplate`); the unknown-field split
is `class Arr(template N: i32) { var a: array(i32, N); var n: i32; }`, `fn
Make(template N: i32) -> i32 { var c: Arr(N) = {.a = (1, 2, 3), .m = N};
return c.n; }`.

### A.2 index.carbon, match_choice.carbon (check and lower), pointer.carbon

<!-- google-doc-style-ignore -->

```text
// --- fail_todo_index_class_with_index_with.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Vec(T)` is a deferred `call_action`, and `T` is
// not deduced through it (fork work item W-396).
```

```text
// --- fail_todo_designator_arm.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Opt(T)` is a deferred `call_action`, so a
// `match` on it reports the scrutinee TODO, as trunk did before TP-1's round
// 10 (fork work item W-397).

// --- fail_todo_designator_arm_exhaustive.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm (W-397).

// --- fail_todo_value_param.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm (W-397).

// --- fail_todo_nested_match.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm (W-397).

// --- fail_todo_guard.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm (W-397).

// --- fail_todo_pattern_forms.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm, for pattern conditions and
// `let` ... `else` (W-397).

// --- fail_todo_int_scrutinee.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm, for `Core.Int(N)` (W-397).
```

```text
// --- fail_todo_designator_arm.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Opt(T)` is a deferred `call_action`, so a
// `match` on it reports the scrutinee TODO and nothing is lowered (fork work
// item W-397).

// --- fail_todo_let_else_payload.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm (W-397).

// --- fail_todo_int_scrutinee.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_designator_arm (W-397).
```

```text
// --- todo_fail_deref_class_type_param.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `C(T)` is a deferred `call_action`, so `*c` is a
// deferred dereference that only an instantiation diagnoses, and this split
// makes none (fork work item W-398).
```

<!-- google-doc-style-resume -->

The three blocks are, in order, index.carbon, the check match_choice.carbon
(seven splits), the lower match_choice.carbon (three) and pointer.carbon. In
the check and lower match_choice.carbon the `class_template_choice` split keeps
its name. The nine `fail_` splits of match_choice.carbon whose diagnostic
changes keep their names (they still fail); their CHECK lines refill.

### A.3 check/testdata/named_constraint/template_constraint_dependent.carbon

One comment line in `fail_dependent_interface_arg_unsatisfied` (at :6 of the
split):

<!-- google-doc-style-ignore -->

```text
-// TODO: with TP-1's eager `J(T)`, the impl's `J(V)` is reported too (W-376).
+// Since TP-2 (W-374) `J(T)` is a deferred `call_action`, so `W(D)` is
+// reported once; the thunk half of W-376 stands.
```

<!-- google-doc-style-resume -->

### A.4 The probes (re-created; §0.4)

Common prefix of the structural probes (`import Core library "io";` first):

<!-- google-doc-style-ignore -->

```carbon
template constraint HasGet { fn Get(self) -> i32; }
class C { fn Get(self) -> i32 { return 5; } }
class D {}
class Holder(template T: HasGet) { var x: i32; }
```

Nominal probes replace the first two lines by:

```carbon
interface HasGet { fn Get(self) -> i32; }
class C { impl as HasGet { fn Get(self) -> i32 { return 5; } } }
```

The bodies (each a `fn Run() -> i32`; `d` is `var d: D = {};`, `c` is `var c:
C = {};`):

```carbon
// m17c, m17n_d (nominal)
fn Wrap[template T: type](x: T) -> i32 { var h: Holder(T) = {.x = 5}; return h.x; }
fn Run() -> i32 { var d: D = {}; return Wrap(d); }
// m17, m17n: the same with `c` and `Core.Print(Wrap(c)); return 0;`
// m17f, m17fn_d
fn Wrap[template T: type](x: T) -> Holder(T) { return {.x = 5}; }
fn Run() -> i32 { var d: D = {}; var h: Holder(D) = Wrap(d); return h.x; }
// m17d, m17dn_d
fn Wrap[template T: type](x: T) -> i32 { var h: Holder(T) = {.x = 5}; return h.x; }
fn Caller[U: type](x: U) -> i32 { return Wrap(x); }
fn Run() -> i32 { var d: D = {}; return Caller(d); }
// m9td (m9t with `c` and a print)
fn Wrap[template T: type](x: T) -> Holder(T) { return {.x = 5}; }
fn Caller[U: type](x: U) -> i32 { var h: Holder(U) = Wrap(x); return h.x; }
fn Run() -> i32 { var d: D = {}; return Caller(d); }
// e1, e1n (e1c with `c`)
fn F[template T: type](x: T) -> i32 { let unused y: HasGet = T; return 1; }
fn Run() -> i32 { var d: D = {}; return F(d); }
// e2, e2n
fn G(unused y: HasGet) -> i32 { return 3; }
fn F[template T: type](x: T) -> i32 { return G(T as HasGet); }
fn Run() -> i32 { var d: D = {}; return F(d); }
// e3n
fn F[template T: type](x: T) -> i32 { let y: HasGet = T; return x.(HasGet.Get)(); }
fn Run() -> i32 { var d: D = {}; return F(d); }
// conv
fn F[U: type](x: U) -> i32 { let unused y: HasGet = U; return 1; }
fn Run() -> i32 { var c: C = {}; return F(c); }
// q11e
overload fn Pick[template T: HasGet](x: T) -> i32 { return 3; }
overload fn Pick[template T: type](unused x: T) -> i32 { return 7; }
fn Caller[U: type](x: U) -> i32 { return Pick(x); }
fn Run() -> i32 { var c: C = {}; var d: D = {}; Core.Print(Pick(c)); Core.Print(Pick(d)); Core.Print(Caller(d)); return 0; }
// thunk1 (thunk1d with `d`)
interface I { fn F[U: type](x: U) -> i32; }
class W {}
impl W as I { fn F[template T: HasGet](x: T) -> i32 { return x.Get() + 4; } }
fn Run() -> i32 { var c: C = {}; Core.Print(W.(I.F)(c)); return 0; }
// gc (gcd with `d`)
fn Make[U: type](x: U) -> i32 { var h: Holder(U) = {.x = 3}; return h.x; }
fn Run() -> i32 { var c: C = {}; return Make(c); }
// t3s
fn Take[U: type](h: Holder(U)) -> i32 { return h.x + 1; }
fn Run() -> i32 { var h: Holder(C) = {.x = 3}; Core.Print(Take(h)); return 0; }
// t7s
fn Inner[U: type](h: Holder(U)) -> i32 { return h.x + 1; }
fn Outer[U: type](h: Holder(U)) -> i32 { return Inner(h) + 2; }
fn Run() -> i32 { var h: Holder(C) = {.x = 3}; Core.Print(Outer(h)); return 0; }
```

The deduction probes share `class Box(T: type) { var item: T; }`, `class
Vec(template N: i32) { var tag: i32; }` and `class TBox(template T: type) {
var item: T; }`:

```carbon
// ded_holder
fn GetTemplate[template T: type](h: Box(T)) -> T { return h.item; }
fn Run() -> i32 { var h: Box(i32) = {.item = 42}; Core.Print(GetTemplate(h)); return 0; }
// ded_holder_pointer
fn GetThrough[template T: type](h: Box(T)*) -> T { return h->item; }
fn Run() -> i32 { var h: Box(i32) = {.item = 5}; Core.Print(GetThrough(&h)); return 0; }
// ded_vec_value_param
fn Size[template N: i32](unused v: Vec(N)) -> i32 { return N; }
fn Run() -> i32 { var v: Vec(3) = {.tag = 0}; Core.Print(Size(v)); return 0; }
// ded_template_class_type
fn GetT[template T: type](h: TBox(T)) -> T { return h.item; }
fn Run() -> i32 { var h: TBox(i32) = {.item = 9}; Core.Print(GetT(h)); return 0; }
// ded_checked_twin
fn GetChecked[T: Core.Copy](h: Box(T)) -> T { return h.item; }
fn Run() -> i32 { var h: Box(i32) = {.item = 42}; Core.Print(GetChecked(h)); return 0; }
// ded_explicit
fn GetExplicit(template T: type, h: Box(T)) -> T { return h.item; }
fn Run() -> i32 { var h: Box(i32) = {.item = 42}; Core.Print(GetExplicit(i32, h)); return 0; }
```

<!-- google-doc-style-resume -->

## Appendix B: the programs and their EXPECTs

### B.1 generics/templates_deduce_class_args.carbon

Inserted after `// CONFORMANCE-BULLET: Generics: Integrated templates`:

<!-- google-doc-style-ignore -->

```text
// SKIP: deduction through a class's arguments is withdrawn by TP-2 (fork work
// item W-396; fork/templates/tp2-plan.md D-TP2-2): with `IsCallPerformable`
// upstream's, `Holder(T)` in a parameter's type is a deferred `call_action`,
// and this file fails to compile with ``error: cannot deduce value for generic
// parameter `T` `` at `Core.Print(Get(h));` (:62:14) and at
// `Core.Print(GetThrough(&h) * 2);` (:63:14) and ``error: cannot deduce value
// for generic parameter `N` `` at `Core.Print(Size(v));` (:65:14), as on the
// upstream nightly 2026.10.12 (verified on the container arbiter's install of
// TP-2's prototype). Un-SKIP when W-396's break condition fires: upstream's
// deduce.cpp deduces a template parameter through a template-dependent splice,
// or the nightly runs this program.
```

<!-- google-doc-style-resume -->

The line numbers are the file's before the insertion (the diagnostics the
runner logged); the EXPECT lines (21, 42, 3, 16, 8) and the body are unchanged.
EXPECT re-derived (R16 (d)): `Get(h)` returns the item 21; `GetThrough(&h)`
reads 21 through the pointer, doubled 42; `Size(v)` is `Vec(3)`'s `N`, 3;
`SumArr(3, 10)` is 10 + 3 + 3, 16; `MakeArr(3)` returns `{.a = (4, 5, 6), .n =
3}`, whose second element plus `n` is 8. The first three would print only with
W-396 removed; the program is one unit, so it is SKIPped whole.

### B.2 generics/templates_match_dependent_choice.carbon

Inserted the same way:

<!-- google-doc-style-ignore -->

```text
// SKIP: refutable patterns on a template-dependent choice value are withdrawn
// by TP-2 (fork work item W-397; fork/templates/tp2-plan.md D-TP2-2): with
// `IsCallPerformable` upstream's, `Opt(T)` is a deferred `call_action` and the
// scrutinee's type is a splice, so this file fails to compile with ``error:
// semantics TODO: `match on unsupported scrutinee type` `` at `match (s) {`
// in `Count` (:46:9) and in every other `match` here, as trunk did before
// TP-1's round 10 (X-1) and as the upstream nightly 2026.10.12 reports a TODO
// (verified on the container arbiter's install of TP-2's prototype). Un-SKIP
// when W-397's break condition fires: upstream's `match` accepts a scrutinee
// whose type is a template-dependent splice, or the nightly runs this program.
```

<!-- google-doc-style-resume -->

EXPECT (0 1 41 7 5 1 0 1 0 2 1 0) unchanged, re-derived from the program's own
header: `Count` of a `None` 0 and of a `Some` 1; `Unwrap` 41 and the default 7;
`Width` 5, 1, 0; `Box(i32).Fill` 1 and `Box(i64).Fill` 0; `Small` 2, 1, 0.

### B.3 fork/conformance/README.md

Rows :361 and :368 (the two programs' rows): their third column changes from
`run` to `SKIP`, written by `runner.py --update-readme-table`.

## Appendix C: the plan and page amendments, verbatim

### C.1 fork/templates/plan.md: D-TP-11 (after the "Round 10" paragraph, :2744)

<!-- google-doc-style-ignore -->

```markdown
TP-2 (amended <date>, fork/templates/tp2-plan.md D-TP2-1 and D-TP2-2; W-374):
this decision's ruling is SUPERSEDED. `IsCallPerformable` is upstream's again
(toolchain/check/call.cpp:449-464 at 7a3608bab): a call is deferred when the
callee or any argument is template-dependent, with no exception for a generic
class, interface or named constraint, as docs/design/README.md:3012-3016 and
proposal 2200 (:205-210) leave type checking of anything dependent on a
template parameter to instantiation; the text above and its round-10 paragraph
stand as the record of what the exception did and why. What it bought is
withdrawn and filed: deduction of `T` from a `Holder(i32)` argument against a
`Holder(T)` parameter (W-193's forms; deduce_class_args.carbon's five positive
splits renamed `fail_todo_`, index.carbon's `index_class_with_index_with`,
the program templates_deduce_class_args.carbon SKIP) is W-396, upstream's
deduce.cpp having no case for a template-dependent splice and the nightly
rejecting the same programs; refutable patterns on a template-dependent choice
value (round 10's X-1 forms; match_choice.carbon's splits, the program
templates_match_dependent_choice.carbon SKIP) are W-397; the two
definition-time diagnostics of `fail_deref_class_type_param` and
`fail_class_template_literal_with_dependent_array_bound_unknown_field`, now
made on instantiation only, are W-398. The deduce_class_args.carbon forms that
TP-1 measured on v13 (holder 42, holder_copy_constraint 7, template_class_type
9, holder_pointer 5, vec_value_param 3) are then the nightly's ``cannot deduce
value for generic parameter`` on the fork too; `class_argument_expression` and
`class_argument_return_type` (explicit `N`) still run. The break condition
above fired as FO-1's m17n_d (an interface constraint converted at the
definition and never checked again); TP-2's D-TP2-1 carries the new one.
```

<!-- google-doc-style-resume -->

In the decision index (:3455-3458) the D-TP-11 item gains: " SUPERSEDED by
TP-2 (<date>): the call is deferred as upstream's is; W-396 to W-398 carry the
forms (fork/templates/tp2-plan.md D-TP2-1, D-TP2-2)."

### C.2 fork/structural/plan.md: D-SC-19 (appended to the bullet at :980) and D-SC-6's FO-1 paragraph (:446)

<!-- google-doc-style-ignore -->

```markdown
    (Amended <date>, TP-2, W-374, fork/templates/tp2-plan.md D-TP2-3: the
    requirement that FO-1's amendment above adds in convert.cpp for a
    conversion of a template-phase self (D-FO1-2 (4)) is kept, not withdrawn.
    With `IsCallPerformable` upstream's, a generic type such as `Holder(T)` is
    a deferred `call_action` whose replay converts the concrete argument in
    each specific, so for a call the requirement is never made (the conversion
    runs inside the replay, where `Context::delayed_action_depth` is positive);
    for a conversion a template body makes outside a call (`let unused y:
    HasGet = T;`, `G(T as HasGet)`; the split
    `fail_dependent_conversion_unsatisfied`) it is the only check, and a build
    without it runs `F(D)` (TP-2 §0.4). The withdrawal clause of FO-1's B1
    (fork/followon/fo1-plan.md:1150-1155) was premised on the call case and is
    re-read by TP-2.)
```

<!-- google-doc-style-resume -->

D-SC-6's FO-1 paragraph (:446-449, "a conversion of a template-phase self at a
definition, which TP-1 makes for a generic type such as `Holder(T)` and a
template body makes outside a call, adds a requirement ...") gains, after
"W-374.": " (TP-2, <date>: the generic-type half is a deferred call since
TP-2; the requirement stands for a conversion outside a call, D-SC-19's TP-2
amendment.)"

### C.3 fork/followon/fo1-plan.md: D-FO1-2 (4) (after :1091) and the withdrawal clause (:1150-1155)

<!-- google-doc-style-ignore -->

```markdown
(Amended <date>, TP-2, fork/templates/tp2-plan.md D-TP2-3; W-374 discharged.)
TP-2 made `IsCallPerformable` upstream's, so `Holder(T)` is a deferred
`call_action` and the interface half above is closed by the replay (m17n_d is
rejected as on the nightly). The hunk of this part is not withdrawn: it never
fires for a call now (the replay performs the conversion with
`delayed_action_depth` positive), and it is the only check of a conversion
outside a call (e1, e2; `fail_dependent_conversion_unsatisfied`), which TP-2
measured as running with rc 1 and 3 without it. The clause of this decision's
"Order" paragraph that withdraws the hunk when TP-1 follows the deferral is
re-read: the `call_action` replay checks a call's argument again, not a
conversion outside a call; the hunk stays for the latter (TP-2 §0.4, §0.5).
```

<!-- google-doc-style-resume -->

At :1150-1155, after "(amended 2026-11-02, review fold: RR3-1).": " (Re-read
<date> by TP-2, D-TP2-3: the condition fired, the premise holds for a call
only, and the hunk is kept for a conversion outside a call; D-FO1-2 (4)'s
TP-2 amendment.)"

### C.4 docs/design/templates.md: two dated notes

After the TP-1 fork note's paragraph that ends "which still stop the compiler
or are compiled wrongly." (:239), a new blockquote paragraph:

<!-- google-doc-style-ignore -->

```markdown
> **Fork note (TP-2, <date>).** Since TP-2 the toolchain defers a call whose
> callee or any argument depends on a template parameter, as upstream's does,
> including a generic class applied to one, so deduction through a class's
> arguments is withdrawn again (fork work item W-396): `fn
> Get[template T: type](h: Holder(T)) -> T` is rejected at a call with
> ``cannot deduce value for generic parameter `T` ``, as on upstream's
> nightly; passing the argument explicitly, `fn Get(template T: type, h:
> Holder(T))` called as `Get(i32, h)`, runs. A `match` on a value whose type
> is a generic choice applied to a template parameter reports the scrutinee
> TODO below again (W-397).
```

<!-- google-doc-style-resume -->

The W-193 bullet (:578-582) gains, after "(Resolved by TP-1, 2026-11-02, as
the fork note there says.)": " (Withdrawn by TP-2, <date>, W-396: see the TP-2
fork note there.)"

## Appendix D: the records texts, verbatim

### D.1 fork/inventory/work-items.json

W-374: `title` becomes "TP-1 follow-on (DISCHARGED at TP-2, <date>; R32 (b),
(d); weekly upstream check 2026-11-09: register row H10.8 was DRIFT): TP-1
residue (D-TP-11; found by FO-1's W-139 review): ..." (the rest unchanged);
`kind` "implemented"; `evidence` gains "toolchain/check/call.cpp
`IsCallPerformable` at <C1>: upstream's body at 7a3608bab (call.cpp:449-464)
with the fork's `OperandDependence(context, ...)`; the eleven goldens refilled
by <F1>; fork/templates/tp2-plan.md §0.3 to §0.6"; `notes` gain, appended:
"DISCHARGED by TP-2 (<date>; fork/templates/tp2-plan.md D-TP2-1): the
exception removed at <C1>, m17n_d rejected on the branch's install with
``unable to monomorphize specific `Wrap(D)` `` and the nightly's two notes
(TP-2 §0.4), container-measured gate 2047 of 2047 after <F1>, conformance
226/0/15 over 241, 51/56 bullets. W-139's convert.cpp requirement is NOT
withdrawn (D-TP2-3: the replay checks a call's argument; a conversion outside
a call keeps the requirement). The forms the deferral loses are W-396, W-397
and W-398; W-399 is the interface analogue of a conversion outside a call.
Break condition of the discharge: D-TP2-1's."

W-139's `notes` gain: " TP-2 (<date>, fork/templates/tp2-plan.md D-TP2-3;
W-374 discharged): the convert.cpp requirement of D-SC-19 part 4 is kept, its
reach narrowed by upstream's deferral to a conversion outside a call; the
withdrawal that H9.8's break condition foresaw was premised on the call case
(e1 and e2 run without the hunk, TP-2 §0.4)."

W-193's `notes` gain: " Re-opened in substance by TP-2 (<date>): the deferral
of every template-dependent call argument makes `Holder(T)` a splice that
deduction does not read through, as on the nightly; the forms are W-396's
(this item stays DISCHARGED as TP-1's record)."

W-376's `notes` gain: " TP-2 (<date>): the impl half (m18i, `W(D)` reported a
second time at the blanket impl's `J(V)`) no longer reproduces, `J(T)` being a
deferred call whose replay reports `W(D)` once
(`fail_dependent_interface_arg_unsatisfied`'s refill); the thunk half
(thunk1d, `fail_symbolic_arg_impl_thunk_unsatisfied`) stands."

New items, inserted after W-395 in id order (fields as W-374's):

<!-- google-doc-style-ignore -->

```json
{
  "id": "W-396",
  "kind": "missing-feature",
  "title": "TP-2 residue (D-TP2-2; W-193's forms re-opened): a deduced template parameter is not deduced through a class type formed from it (`Holder(T)`, `Holder(T)*`, `Vec(N)`, `TBox(T)` for `class TBox(template T: type)`), because the type-forming call is deferred and deduction has no case for a template-dependent splice",
  "subsystem": "toolchain/check (deduce.cpp, call.cpp `IsCallPerformable`)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
    "toolchain/check/testdata/generic/template/deduce_class_args.carbon: fail_todo_holder, fail_todo_holder_copy_constraint, fail_todo_holder_pointer, fail_todo_vec_value_param, fail_todo_template_class_type (<F1>); index.carbon: fail_todo_index_class_with_index_with",
    "fork/conformance/programs/generics/templates_deduce_class_args.carbon (SKIP at <C1>)",
    "upstream toolchain/check/deduce.cpp:443 at 7a3608bab, `// TODO: Handle more cases.`, and the `default:` arm's `deduce_through()` test (:446-456): no case reads through a `SpliceInst`; the nightly 2026.10.12 reports ``cannot deduce value for generic parameter `T` `` for the probe ded_holder (fork/templates/tp2-plan.md Appendix A.4)",
    "fork/templates/tp2-plan.md §0.4, D-TP2-2"
  ],
  "blocked_by": [],
  "notes": "Filed at TP-2's discharge (<date>), id reserved by its plan (§0.9: the next free id above W-395 across every ref and worktree). Not a TP-2 regression against upstream: the nightly fails the same programs; a TP-1 capability (D-TP-11, W-193's discharge) withdrawn under R32 because upstream's `IsCallPerformable` defers the type-forming call. Workaround: an explicit template argument (`Get(i32, h)`; the probe ded_explicit runs on every toolchain). Removal: upstream's mechanism when it designs one (no fork spelling, R32 (d)). Break condition: upstream's deduce.cpp deduces a binding through a template-dependent splice or `call_action`, or the nightly runs ded_holder (prints 42); then the fork follows it and the six splits lose `fail_todo_`."
},
{
  "id": "W-397",
  "kind": "missing-feature",
  "title": "TP-2 residue (D-TP2-2; TP-1 round 10's X-1 forms re-opened): a `match`, a pattern condition or `let` ... `else` on a value of a generic choice applied to a template parameter (`Opt(T)`, `Shape(T)`) or on `Core.Int(N)` for a template `N` reports ``semantics TODO: `match on unsupported scrutinee type` `` (``refutable pattern binding on unsupported scrutinee type``), because the scrutinee's type is a deferred splice",
  "subsystem": "toolchain/check (refutable_binding.cpp, handle_match.cpp, call.cpp `IsCallPerformable`)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
    "toolchain/check/testdata/generic/template/match_choice.carbon: fail_todo_designator_arm, fail_todo_designator_arm_exhaustive, fail_todo_value_param, fail_todo_nested_match, fail_todo_guard, fail_todo_pattern_forms, fail_todo_int_scrutinee, and the nine `fail_` splits whose specific diagnostics became the TODO (<F1>); toolchain/lower/testdata/template/match_choice.carbon: fail_todo_designator_arm, fail_todo_let_else_payload, fail_todo_int_scrutinee",
    "fork/conformance/programs/generics/templates_match_dependent_choice.carbon (SKIP at <C1>)",
    "the nightly 2026.10.12 reports ``semantics TODO: `choice alternatives with parameters are not yet supported` `` or ``semantics TODO: `HandleMatchIntroducer` `` on the same splits; trunk before TP-1's round 10 reported the scrutinee TODO (fork/templates/plan.md §1.13 item 26)",
    "fork/templates/tp2-plan.md §0.4, D-TP2-2"
  ],
  "blocked_by": [],
  "notes": "Filed at TP-2's discharge (<date>). A choice declared in a class template (`class_template_choice`, `Box(T).State`) is unchanged: its type is not formed by a call. W-252 (a `match` on a value whose type is not known where the template is defined) is the neighbour; this item is the class that TP-1 had made work and TP-2 withdraws. Removal: upstream's mechanism for a `match` on a template-dependent scrutinee (none designed at 7a3608bab; no fork spelling, R32 (d)). Break condition: upstream's `match` accepts a scrutinee whose type is a template-dependent splice (pattern_match.cpp or refutable_binding.cpp gain the case), or the nightly runs templates_match_dependent_choice.carbon; then the fork follows it."
},
{
  "id": "W-398",
  "kind": "todo-stub",
  "title": "TP-2 residue (D-TP2-2): two definition-time diagnostics on a value whose type is a class template applied to a template parameter are made only on instantiation: `*c` for `c: C(T)` (``cannot dereference operand of non-pointer type``) and an unknown field in a literal converted to `Arr(N)` (``struct `Arr(N)` has no field named `m` ``)",
  "subsystem": "toolchain/check (pointer_dereference.cpp, convert.cpp)",
  "size": "S",
  "bullet": "Generics: Integrated templates",
  "evidence": [
    "toolchain/check/testdata/generic/template/pointer.carbon: todo_fail_deref_class_type_param; deduce_class_args.carbon: todo_fail_class_template_literal_with_dependent_array_bound_unknown_field (<F1>)",
    "the nightly 2026.10.12: the deref split is rejected at the definition with ``cannot dereference operand of non-pointer type `<splice of ...>` `` (upstream has no deferred dereference, TP-1's D-TP-7); the literal split checks there too",
    "fork/templates/tp2-plan.md §0.4, D-TP2-2"
  ],
  "blocked_by": [],
  "notes": "Filed at TP-2's discharge (<date>). Both checks ran at the definition only because D-TP-11 formed the class type there; with the call deferred they are an instantiation's, by TP-1's own rules for a template-dependent operand (D-TP-7, D-TP-24). Removal: none owed; a `fail_` twin that instantiates each form keeps the diagnostic in the gate (the index and pointer goldens' `_on_instantiation` splits are that pattern). Break condition: upstream diagnoses either form at the definition for a splice-typed operand; then the fork follows it."
},
{
  "id": "W-399",
  "kind": "todo-stub",
  "title": "TP-1 residue found by TP-2 (D-TP2-8; D-TP-12): a conversion of a template-dependent self to an interface outside a call, whose facet value is unused (`let unused y: HasGet = T;`, `G(T as HasGet)` in `fn F[template T: type]`), is accepted and `F(D)` runs for a `D` that does not implement the interface, where the nightly rejects it at the definition",
  "subsystem": "toolchain/check (impl_lookup.cpp D-TP-12, convert.cpp)",
  "size": "S",
  "bullet": "Generics: Integrated templates",
  "evidence": [
    "the probes e1n and e2n (fork/templates/tp2-plan.md Appendix A.4): rc 1 and rc 3 on trunk 701863aa5's install and on TP-2's prototype; the nightly 2026.10.12: ``cannot convert type `T` into type implementing `HasGet` `` at the definition; e3n (the facet value used) is rejected in `F(D)` on every toolchain",
    "fork/templates/plan.md D-TP-12 (the deferred `LookupImplWitness` kept as the witness) and fork/templates/tp2-plan.md §0.4"
  ],
  "blocked_by": [],
  "notes": "Filed at TP-2's discharge (<date>); outside W-374, which is a call's argument. The deferred witness of D-TP-12 is evaluated only where a use forces it; an unused facet value forces nothing in the specific. The structural analogue is checked by W-139's convert.cpp requirement (D-SC-19 part 4, kept by TP-2's D-TP2-3). Removal: the specific forces the deferred witnesses of its facet values, or the nightly's definition-time rejection is followed (upstream's rule, R32); owner TP-1's follow-on. Break condition: e1n rejected (at the definition or in `F(D)`) on a fork build."
}
```

<!-- google-doc-style-resume -->

### D.2 W-139's dated note

Given in D.1 (the `notes` sentence); its register twin is D.6's H9.8 text.

### D.3 fork/decision-log.md: the entry "TP-2"

Placed directly after the TP-1 entry's last paragraph (before "### DD-1:
design docs without placeholders (2026-10-14)" at :7084), the log grouping
entries by workstream:

<!-- google-doc-style-ignore -->

```markdown
### TP-2: `IsCallPerformable` follows upstream's deferral of every template-dependent call argument (W-374) (<date>)

Context: W-374 (register row H10.8, DRIFT since the weekly upstream check of
2026-11-09, re-read 2026-11-16), fork/templates/tp2-plan.md rev <r> after two
plan reviews and <k> re-review rounds. Line cites are to trunk 701863aa5
unless a sha is named. Branch claude/carbon-fork-0-1-tp2, commits <plan
revisions>, <C1> (C1), <F1> (F1), <P> (P), <fixes> and this one; the discharge
commit appends the last three paragraphs.

_The item and the rule._ Upstream's `IsCallPerformable`
(toolchain/check/call.cpp:449-464 at 7a3608bab, the cut's body at
c1e83b0b7:425-438 but for 4286832b4's `context.sem_ir()`) returns false when
`OperandDependence` of the callee or of any argument is
`SemIR::ConstantDependence::Template`; docs/design/README.md:3012-3016 says
"type checking for anything dependent on the template parameter can't be
completed until the template is instantiated with a specific concrete type";
p002200:208-210 says "type checking of any expression dependent on a templated
parameter may not be completed until its value is known". TP-1's D-TP-11 made
an exception for a generic class, interface or named constraint, forming
`Holder(T)` at the definition; FO-1's m17n_d showed the interface constraint
converted there and never checked again (rc 5 on trunk, rejected by the
nightly). TP-2 removes the exception (D-TP2-1): the function's text is
upstream's but for the `OperandDependence(context, ...)` signature UA-3
converts.

_The decisions (auto-adopted under R29 (a), veto-able)._ D-TP2-1 the deferral
rule is upstream's, to the letter, no special case under another name (R17).
D-TP2-2 the cost is recorded and filed, no fork mechanism: deduction through a
class type formed from a template parameter (W-396), refutable patterns on a
template-dependent choice (W-397), two definition-time diagnostics moved to
instantiation (W-398); upstream's deduce.cpp:443 "TODO: Handle more cases."
names no mechanism and the nightly rejects the same programs. D-TP2-3 W-139's
convert.cpp hunk (D-SC-19 part 4) is kept: measured, its removal lets `let
unused y: HasGet = T;` and `G(T as HasGet)` run for a `D` lacking `Get` (the
SC-1 split `fail_dependent_conversion_unsatisfied` succeeds), while the
deferral alone keeps the hunk out of every call's path (the replay converts
with `delayed_action_depth` positive); the item's "withdrawn" and H9.8's break
condition were premised on the call case. D-TP2-4 eleven goldens refill
CHECK-only; destroy_calls.carbon is D-TP-11's own refill (its template split
only), so the item's break condition is judged not fired. D-TP2-5 two programs
SKIP under R10. D-TP2-6 the records and the register. D-TP2-7 the slices and
the fix budget of two. D-TP2-8 W-396 to W-399 filed. D-TP2-9 the PR and the
landing under R33. D-TP2-10 the docs' dated notes.

_V-3 check at 7a3608bab (R32 (a))._ Each statement against the tip: the
deferral rule, call.cpp:449-464 quoted above; the signature, action.h:93-102
(`const SemIR::File&`); deduction, deduce.cpp:395-460 (the `SymbolicBinding`
case, the `StructValue` TODO, "// TODO: Handle more cases." at :443, the
`deduce_through()` default); the design, README.md:3012-3016,
terminology.md:260-268 and :306-310, overview.md:102-107, p002200:205-210,
all quoted in the plan's §0.8; the twelve upstream commits since the cut that
touch the function, deduce.cpp or those pages, by sha and subject (4286832b4,
be0f11be9, 503f09037, db87a84b6, 0d3b606a5, 3af25cc1b, 7beb29f8b, 2c9739799,
bf5d2a2ac, 62f1cc6a3, 230227264, 4a8993af2), none changing the rule, the
pages or deduction through a splice. Where upstream is silent (deduction
through a splice, `match` on one) the plan files the residue and adds nothing.

_The register (DR-0's block (vii); RG-1's rows H10.8 and H9.8)._ H10.8 ALIGNED
(D-RG-1): the rule is upstream's text; the quote rows added to
rg1-quotes.tsv (call.cpp:449, :450, :453, :458; README.md:3012-3016); check
H10.8 kept as the L count over toolchain/check/call.cpp, 9 at 7a3608bab, read
by W-355 as the merge-rule signal; break condition D-TP2-1's. H9.8 ALIGNED,
its convert.cpp part re-described as D-SC-19's own, no longer resting on
D-TP-11; check `ConvertBindingArg` 0 at 7a3608bab (re-run); break condition's
third clause re-read by D-TP2-3. The other H9 and H10 checks re-run at
7a3608bab give rg1-checks.tsv's expected counts (H10.1 5, FIRED for W-394,
UA-3's). W-355 carries the rows.

_Measured (container, R33 (b); the plan's §0.3 to §0.6)._ Baseline tp2-base:
gate 2047 of 2047, conformance 228/0/13 over 241. The prototype: gate 2036 of
2047 before the fill (eleven files), 2047 of 2047 after the fill and the
eighteen renames; conformance 226/0/15 over 241, 51 of 56 bullets; m17n_d
rejected as on the nightly; the mutants M1 (the exception renamed: the gate's
prefix rule and m17n_d catch it, no register check does) and M2 (the hunk
kept: no double check, e1 and e2 rejected).

_Break conditions._ D-TP2-1's: upstream changes which operands or which
dependence defer a call, or README.md:3012-3016 or p002200:205-210 change.
D-TP2-2's: W-396 to W-398's. D-TP2-3's: a double check in one specific, or
upstream defers a facet conversion of a template-dependent self. D-TP2-4's: a
golden outside the eleven changes at the fill.

_Residues._ W-396, W-397, W-398 (D-TP2-2), W-399 (D-TP2-8; TP-1's follow-on).

_The §8.7 check on the tree at <R>._ `diff` of upstream's :449-464 against the
fork's function prints the two `context.sem_ir()` lines only; `git grep -c -w
forms_type -- toolchain` 0; the model-identifier grep of the branch's diff 0.

_The id re-scan at D._ <n> refs, <h> distinct heads and <w> worktrees after a
fetch: W-396 to W-399 are this branch's ledger ids only; elsewhere range
bounds in prose; no W-4xx.

_Discharged by this commit: W-374 (TP-2)._
```

<!-- google-doc-style-resume -->

### D.4 The dated notes

The TP-1 entry's register paragraph (fork/decision-log.md:6992-7003, the
"Weekly upstream check 2026-11-09" paragraph that ends "Veto-able.") gains:
" Resolved <date> by TP-2 (the entry "TP-2: ..." below): the exception
removed at <C1>, H10.8 ALIGNED; W-139's requirement kept, D-TP2-3."

DR-0's register block (vii) (:258-263) gains, after "(added 2026-11-09, weekly
upstream check)": " (vii) resolved <date> by TP-2, <C1> and its fill <F1>;
H10.8 ALIGNED; W-139's convert.cpp requirement kept (TP-2 D-TP2-3)."

The entry "Weekly upstream check 2026-11-16": its register row for H10.8
(:19698) gains in its last cell " (resolved <date> by TP-2: ALIGNED)"; its
paragraph "_H10.8's re-read_" (:19730-19747) gains a last sentence "Resolved
<date> by TP-2 (fork/templates/tp2-plan.md): the row is ALIGNED and W-374
DISCHARGED." The entry "Weekly upstream check 2026-11-09": its register row
(:19971) gains the same cell note and its paragraph "_H10.8's verdict_"
(:20002-20030) the same sentence.

### D.5 The UA-3 audit note (fork/ORCHESTRATION.md Next actions item 6)

After "call.cpp:1045-1046 rewriting the cut's :432; pointer_dereference.cpp:24
merging clean)," the sentence: "TP-2 (<date>) restored the cut's one-line form
in `IsCallPerformable`, so nine fork lines remain in that form (fourteen
`OperandDependence(context,` call sites in all: call.cpp 5, convert.cpp 6,
handle_index.cpp 2, pointer_dereference.cpp 1), and 62f1cc6a3's rename of
`GenericClassType` meets no fork use in that function."

### D.6 The register files and rows

fork/register/rg1-plan.md row H10.8 (:1017) becomes:

<!-- google-doc-style-ignore -->

```text
| H10.8 | (viii) D-TP-11 forms a generic class type with template-dependent arguments eagerly (SUPERSEDED <date> by TP-2: `IsCallPerformable` defers a call when the callee or any argument is template-dependent, as upstream's does) | check/call.cpp:449-450 "Determines whether a call can be performed immediately" / "non-template-dependent)."; :453 `if (OperandDependence(context.sem_ir(), callee_id) ==` and :458 `if (OperandDependence(context.sem_ir(), arg_id) ==` at 7a3608bab; README.md:3012-3016 "type checking for anything dependent on the template parameter can't be completed until the template is instantiated with a specific concrete type"; check H10.8: `git log --oneline c1e83b0b7..<tip> -- toolchain/check/call.cpp | wc -l` = 9 at 7a3608bab (the merge-rule signal: a moved count means the function or its file changed; re-read the quote rows) | ALIGNED since <date> (TP-2, fork/templates/tp2-plan.md D-TP2-1; D-RG-1: the rule is upstream's text, the fork's function equal to it but for the `Context&` signature UA-3 converts); was NONE (RG-1) then DRIFT (2026-11-09, re-read 2026-11-16) | upstream changes which operands or which dependence defer a call in `IsCallPerformable`, or README.md:3012-3016 or p002200:205-210 change; then the row is re-read | W-355 (W-374 discharged; the lost forms W-396 to W-398) |
```

<!-- google-doc-style-resume -->

Row H9.8 (:1003): in the first cell "and convert.cpp's requirement for a
template-dependent self with structural requirements, which rests on TP-1's
D-TP-11 forming `Holder(T)` at the definition (W-139's fix, D-SC-19 as amended;
the interface half is W-374)" becomes "and convert.cpp's requirement for a
template-dependent self with structural requirements converted outside a call
(W-139's fix, D-SC-19 as amended by TP-2: a call's argument is converted in
the deferred call's replay, where the requirement is not made)"; the last cell
loses "or TP-1 follows upstream's deferral of every template-dependent call
argument (`IsCallPerformable`, H10.8, W-374): withdraw the convert.cpp
requirement" and gains "(the third clause fired <date> and was re-read by
TP-2's D-TP2-3: the requirement is kept for a conversion outside a call)".

fork/register/rg1-checks.tsv: the H10.8 comment line (:97) gains "; resolved
<date> by TP-2: ALIGNED, the count kept as the merge-rule signal" and the row
stays `H10.8    L    -    -    toolchain/check/call.cpp    9`. The H9.8 row and
its comment are unchanged.

fork/register/rg1-quotes.tsv: five rows appended after a comment line
`# TP-2 (<date>): H10.8's quotes at 7a3608bab`:

<!-- google-doc-style-ignore -->

```text
toolchain/check/call.cpp	449	Determines whether a call can be performed immediately
toolchain/check/call.cpp	450	// non-template-dependent).
toolchain/check/call.cpp	453	if (OperandDependence(context.sem_ir(), callee_id) ==
toolchain/check/call.cpp	458	if (OperandDependence(context.sem_ir(), arg_id) ==
docs/design/README.md	3015	on the template parameter can't be completed until the template is instantiated
```

<!-- google-doc-style-resume -->

(the :449 substring stops before the parenthetical, which the Google-doc-style
hook would rewrite). check_quotes.sh at 7a3608bab: 0 FAIL.

### D.7 fork/gap-analysis.md, row "Generics: Integrated templates" (:56)

Status PARTIAL unchanged. In the evidence cell, after "(W-193, discharged);"
insert "(TP-2, <date>: withdrawn again, W-396, the type-forming call being
deferred as upstream's `IsCallPerformable` defers it; an explicit template
argument runs;)" and after "is checked in the definition and runs (round 10 of
the focused re-review of the fold; ...)" insert " (TP-2, <date>: withdrawn,
W-397, the scrutinee's type being a deferred splice; the scrutinee TODO is
reported again;)"; the Residue list gains ", two definition-time diagnostics
made on instantiation only (W-398) and an unused facet value of a
template-dependent self converted to an interface outside a call (W-399)".
Status does not change because the bullet's programs still pass but the two
SKIPped, the row was PARTIAL before TP-1 resolved W-193 and after, and PARTIAL
names the same material gaps (W-250 to W-298) that remain.

### D.8 fork/ORCHESTRATION.md

Header clause: "Last updated: <date> (TP-2 implemented and reviewed on
claude/carbon-fork-0-1-tp2, W-374 discharged at its records commit; <landed>
PRs landed, 1 held; see the Branches row; the earlier <prev> text follows)."
Dated paragraph, after the last dated paragraph: "<date> (<hh:mm> UTC): TP-2
(W-374, fork/templates/tp2-plan.md) is IMPLEMENTED AND REVIEWED on
claude/carbon-fork-0-1-tp2 (commits <plan revisions>, <C1>, <F1>, <P>, <fixes>,
<R> and this one): `IsCallPerformable` is upstream's (7a3608bab call.cpp:
449-464 but for the `Context&` signature); eleven goldens refilled, eighteen
splits renamed, two programs SKIP (W-396, W-397); W-139's convert.cpp
requirement kept (D-TP2-3); W-396 to W-399 filed; register H10.8 ALIGNED;
container-measured (R33 (b)): gate 2047 of 2047, conformance 226/0/15 over
241, 51/56 bullets. Next: the PR with base trunk, LAND-1's landing, then UA-3."
Branches row, after `claude/carbon-fork-0-1-ehc`'s: "| `claude/carbon-fork-0-1-tp2`
| IMPLEMENTED AND REVIEWED (base trunk 701863aa5) — TP-2: `IsCallPerformable`
follows upstream's deferral of every template-dependent call argument (W-374,
R32); W-396 to W-399 filed; container-measured (R33 (b)): gate 2047 of 2047,
conformance 226/0/15 over 241 |". Next actions item 6: the W-374 sentence
("re-classifies TP-1's register row H10.8 DRIFT on W-374 ... W-139's convert.cpp
requirement is withdrawn when it lands.") gains "(TP-2, <date>: done on
claude/carbon-fork-0-1-tp2, W-374 discharged; the requirement is kept,
D-TP2-3; W-396 to W-399.)"; the UA-3 sentence "UA-3 follows W-341 and W-346
(both landed) and proceeds with PR 53 held" becomes "UA-3 follows W-341, W-346
(both landed) and W-374 (TP-2, <state>) and proceeds with PR 53 held". The
Scoreboard section gains "Expected after TP-2's landing: 226 PASS / 15 SKIP /
0 FAIL (241), 51/56 bullets (two programs SKIP under W-396 and W-397)".

## Appendix E: the PR text

<!-- google-doc-style-ignore -->

```text
TP-2: `IsCallPerformable` follows upstream's deferral of every template-dependent call argument (W-374)

Plan: fork/templates/tp2-plan.md (rev <r>, signed off). Base trunk.

What: toolchain/check/call.cpp's `IsCallPerformable` is upstream's again
(7a3608bab call.cpp:449-464, but for the fork's `OperandDependence(context,
...)` signature, UA-3's): a call is deferred when the callee or any argument is
template-dependent; TP-1's D-TP-11 exception for a generic class, interface or
named constraint is removed (R17, R32). W-374's defect, an interface constraint
converted at a template's definition and never checked again (`Wrap(d)` ran
for a `D` not implementing `HasGet`), is closed: the call's replay rejects
`Wrap(D)` as the upstream nightly does.

Cost, recorded and filed (R32; D-TP2-2): deduction of a template parameter
through a class type formed from it (W-193's forms) is lost as it is absent on
the nightly (W-396); refutable patterns on a template-dependent choice value
return to the scrutinee TODO (W-397); two definition-time diagnostics move to
instantiation (W-398). Eighteen splits renamed `fail_todo_`/`todo_fail_`, two
programs SKIP with the residue ids. W-399 (an unused facet value of a
template-dependent self converted outside a call) found and filed for TP-1's
follow-on.

Kept: W-139's convert.cpp requirement (D-SC-19 part 4). Measured, its removal
lets a conversion outside a call run unchecked (the SC-1 split
`fail_dependent_conversion_unsatisfied` succeeds); the deferral alone keeps it
out of every call's path (D-TP2-3).

Goldens: eleven refilled by autoupdate (CHECK lines only): check
generic/template/{convert,deduce_class_args,default_init,index,match_choice,pointer}.carbon,
check class/destroy_calls.carbon (its template split), check
named_constraint/template_constraint_dependent.carbon, lower
template/{class,initialize,match_choice}.carbon.

Container-measured (R33 (b)): gate 2047 of 2047; conformance 226/0/15 over
241, 51/56 bullets (from 228/0/13: the two SKIPs). Records: W-374 DISCHARGED;
register H10.8 ALIGNED, H9.8 re-read; decision-log entry TP-2.

Commits: <plan revisions>, <C1>, <F1>, <P>, <fixes>, <R>, <D>, <records of the
dry round>.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_018tx3BJWJhp2yYjHPRA5fNR
```

<!-- google-doc-style-resume -->

## Appendix F: the land-time texts (LAND-1 Appendix A, with `<...>`)

### F.1 M, the merge of trunk into the branch (only if trunk moved after 701863aa5)

Message: "TP-2 (M): merge trunk <sha> into claude/carbon-fork-0-1-tp2 before
the landing"; conflicts by §6.2's rules; gate and conformance re-measured.

### F.2 F-M, the refill on the merged branch (only if autoupdate changes a file)

As LAND-1 A.2 with "TP-2" for the title.

### F.3 The merge commit's message (A.1)

<!-- google-doc-style-ignore -->

```text
Land PR <N>: TP-2: IsCallPerformable follows upstream's deferral of every template-dependent call argument (W-374)

Merges claude/carbon-fork-0-1-tp2 at <head> (PR <N>, base trunk) into trunk
<trunk before> under R33, as fork/templates/tp2-plan.md §3 and Appendix F
specify.

Conflicts and rules: <conflicts, or "none">.

Container-measured on the merge's tree (R33 (b)): build ok; gate <g0> of
<gn> before any refill (each golden that fails is refilled by this landing's
refill commit, fork/land/land1-plan.md Appendix A.2, which states the gate
after it); conformance <p>/<f>/<s> over <n>, bullets <b> of 56. prek clean on
the resolved files (SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,
forbid-llvm-googletest).

<trailers>
```

<!-- google-doc-style-resume -->

### F.4 The Branches row (A.3; replaces D.8's row)

<!-- google-doc-style-ignore -->

```text
| `claude/carbon-fork-0-1-tp2` | LANDED as PR <N> by merge <merge sha> (<date>, LAND-1, R33; GitHub merged_at <merged_at>, merge_commit_sha <api sha>) — TP-2: `IsCallPerformable` follows upstream's deferral of every template-dependent call argument (W-374, R32); W-374 discharged, W-396 to W-399 filed; land-time commits <land-time shas>; container-measured (R33 (b)): gate <g> of <g>, conformance <p>/<f>/<s> over <n> |
```

<!-- google-doc-style-resume -->

### F.5 The dated paragraph and the header (A.4)

<!-- google-doc-style-ignore -->

```text
<date> (<hh:mm> UTC): PR <N> (TP-2) LANDED on trunk by merge <merge sha>
under R33 (fork/templates/tp2-plan.md §3 and Appendix F), GitHub merged_at
<merged_at>; container-measured (R33 (b)): gate <g> of <g>, conformance
<p>/<f>/<s> over <n>, <b>/56 bullets, gap tally <tally>; id re-scans:
<rescan>; <landed> PRs landed, 1 held. Next: UA-3 (W-394's audit inherits
TP-2's call.cpp as upstream's own 4286832b4 hunk).
```

<!-- google-doc-style-resume -->

Header clause: "Last updated: <date> (PR <N> landed by LAND-1; <landed> PRs
landed, 1 held; see the paragraph dated <date> (<hh:mm> UTC) below; the earlier
<prev> text follows)." Next actions item 6: "W-374 (TP-2) landed on trunk
<date> as PR <N> by merge <merge sha> (LAND-1)."; the UA-3 sentence's
"<state>" becomes "landed".

### F.6 The Landed paragraph in this plan (A.5)

<!-- google-doc-style-ignore -->

```text
TP-2 landed on trunk (LAND-1, <date>): merged as PR <N> by <merge sha> (head
<head>, trunk before <trunk before>; GitHub merged_at <merged_at>) under R33,
fork/templates/tp2-plan.md §3 and Appendix F; land-time commits <land-time
shas>; container-measured (R33 (b)): gate <g> of <g>, conformance <p> PASS,
<f> FAIL, <s> SKIP over <n>, <b> of 56 bullets; id re-scans: <rescan>; moved to
follow-ons: W-399 to TP-1's follow-on (Next actions item 6), W-396 to W-398 to
the weekly check's re-reads (W-355).
```

<!-- google-doc-style-resume -->

It goes after this plan's Status paragraph.

### F.7 The decision-log sentence (A.6)

<!-- google-doc-style-ignore -->

```text
_Landed (<date>, LAND-1, R33):_ merged into trunk as PR <N> by <merge sha>
(GitHub merged_at <merged_at>); container-measured (R33 (b)): gate <g> of <g>,
conformance <p>/<f>/<s> over <n>; id re-scans: <rescan>; moved to follow-ons:
W-399 to TP-1's follow-on; W-396 to W-398 to W-355's re-reads.
```

<!-- google-doc-style-resume -->

The last paragraph of the TP-2 entry (D.3).

### F.8 The PR description's Landed line (A.7) and W-374's discharge evidence

<!-- google-doc-style-ignore -->

```text
**Landed** on trunk <date> by merge <merge sha> (LAND-1, R33; GitHub
merged_at <merged_at>): container-measured gate <g> of <g>, conformance
<p>/<f>/<s> over <n>, <b>/56 bullets; moved to follow-ons: W-399 to TP-1's
follow-on. Record: fork/ORCHESTRATION.md's paragraph dated <date> (<hh:mm>
UTC).
```

<!-- google-doc-style-resume -->

W-374's `notes` gain, appended: " LAND-1 (<date>, PR <N>'s landing): merged
by <merge sha> (GitHub merged_at <merged_at>); container-measured (R33 (b)):
gate <g> of <g>, conformance <p>/<f>/<s> over <n>, <b>/56 bullets; the §8.7
check re-run on the merge's tree gives the answer recorded at <R>: the two
`context.sem_ir()` lines only, `forms_type` 0."

### F.9 The gap header's first sentence (A.8) and ORCHESTRATION's Scoreboard paragraph (A.9)

As LAND-1's templates, with 37 / 17 / 2 / 0 (unchanged) and PR <N>'s figures
(226 PASS / 0 FAIL / 15 SKIP over 241, 51/56); row 56 takes no "not of record"
mark.
