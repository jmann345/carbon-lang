<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# TP-2 plan: `IsCallPerformable` follows upstream's deferral of every template-dependent call argument (W-374)

**Status:** rev 3, 2026-11-16 -- SIGNED OFF FOR IMPLEMENTATION. Rev 3 folds
the focused re-review RR1 of rev 2 (b87751859; APPROVE-WITH-AMENDMENTS: no
BLOCKER, no MAJOR, three MINORs, all three folded, none rejected; see "Review
fold record (rev 3, 2026-11-16)" and the "Sign-off" section, both before
Appendix A). Rev 2 (2026-11-16, b87751859) folded reviews A and B under the
orchestrator's rulings of 2026-11-16 (R29), 15 findings (the section "Review
fold record (rev 2, 2026-11-16)" after the hand-off notes; the rulings are
recorded where they apply). Rev 1 (9f09c347b) was for two adversarial plan
reviews. Branch
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

TP-2 landed on trunk (LAND-1, 2026-11-16): merged as PR 71 by a976a9e2b (head
d175fcb5ac793a30add2a810e3effd0fa67a51cc, trunk before 99f4df970; GitHub
merged_at 2026-11-16T21:16:43Z) under R33, fork/templates/tp2-plan.md §3 and
Appendix F; land-time commits none; container-measured (R33 (b)): gate 2047 of
2047, conformance 226 PASS, 0 FAIL, 15 SKIP over 241, 51 of 56 bullets; id
re-scans: W-396 to W-400 ledger items only on the PR's line,
claude/carbon-fork-0-1-tp2 (local and origin, at d175fcb5a), its worktree and
this landing's worktree, over 971 refs, 747 distinct heads and 10 worktrees
after a fetch; W-381 to W-385 unused; W-386 to W-393 reserved only by SAFE-3's
text on the local claude/carbon-fork-0-1-safe and origin's
claude/carbon-fork-0-1-safe-wip (elsewhere range bounds in prose), no ledger
use; no W-4xx but W-400 anywhere, W-400 only on the PR's line; moved to
follow-ons: W-399 and W-400 to TP-1's follow-on (Next actions item 6), W-396 to
W-398 to the weekly check's re-reads (W-355).

**What the measurements settle (§0.3 to §0.6), in four lines.** (1) The removal
is exactly the item's: the function becomes upstream's text at 7a3608bab but for
the `OperandDependence(context, ...)` signature the fork still has (D-TP2-1); on
the prototype m17n_d is rejected as on the nightly, ``unable to monomorphize
specific `Wrap(D)` `` with the nightly's two notes (W-374 discharged by
measurement). (2) Its cost is large and is recorded, not licensed away (R32):
deduction of a template parameter through a class type formed from it
(`Holder(T)`, `Holder(T)*`, `Vec(N)`, W-193's forms, which D-TP-11 made work;
`Core.Int(N)` too, A-m1) is lost, as it is absent on the nightly; refutable
patterns on a template-dependent choice value (TP-1 round 10's X-1 family) and
`index_class_with_index_with` return to upstream's `semantics TODO`; two
definition-time diagnostics move to instantiation; an `impl forall` with a
template binding whose self or interface is formed from it is rejected as on the
nightly (W-400, review A's A-M1, pinned by a `fail_todo_` split); two
conformance programs no longer compile. Upstream's deduce.cpp has no mechanism
for a template-dependent splice ("TODO: Handle more cases.", :443 at 7a3608bab)
and the nightly rejects the same programs, so the plan files residues W-396 to
W-400 with probes and break conditions and adds no fork mechanism (R32 (d);
D-TP2-2). (3) W-139's convert.cpp hunk is NOT removed: measured, its removal
re-opens the structural check of a conversion outside a call (e1 and e2 run, and
the SC-1 split `fail_dependent_conversion_unsatisfied` succeeds), while the
deferral alone already keeps it out of every call's path, so the hunk stays,
narrowed by the deferral and re-described (D-TP2-3; the item's "withdrawn" and
H9.8's break condition were premised on the call case). (4) Eleven goldens
refill CHECK-only; one of them, check/testdata/class/destroy_calls.carbon, lies
outside TP-1's and SC-1's template golden directories, so W-374's break
condition FIRED by its letter; §0.3's table is the report, and the orchestrator
ruled on 2026-11-16 (R29) that the removal PROCEEDS, the changed split
`generic_use_inside_template` being a template split that D-TP-11 itself
refilled when TP-1 landed (TP-1 §1.6), the condition's letter amended to read a
template golden by its changed split's use of a template parameter (D-TP2-4:
ruled, not judged by this plan). Twenty-six splits are renamed (`fail_todo_` or
`todo_fail_`) with the residues named in their comments and one added
`fail_todo_` split pins W-400's form; after the renames, the pin and the fill
the gate is **2047 passed, 0 failed** and conformance **PASS 226 / FAIL 0 / SKIP
15 over 241, 51 of 56 bullets** (two programs SKIP under R10 with the residue
ids; the bar for the landing, D-TP2-5's ruling). (amended 2026-11-16, review
fold: A-M1 / A-m3 / B3 / B4)

**Item:** W-374 (R32 (b), (d); weekly upstream checks 2026-11-09 and 2026-11-16;
FO-1 D-FO1-2 (4)). **Reserved ids:** W-396 to W-400 (§0.9, re-scanned at the
fold), all five filed by D. **No F id.**

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
the prototype, its fill and the renames; 0.4 the probes on the three toolchains;
0.5 the mutants; 0.6 conformance; 0.7 collisions and what UA-3 inherits; 0.8
upstream's direction register (R32 (a), (c)); 0.9 the id re-scan; 0.10 the tree
checker and what is not run. §1 Design (D-TP2-1 to D-TP2-10). §2 Spec, file by
file. §3 Commits, the PR and the landing. §4 Testdata matrix. §5 Conformance
delta. §6 Churn and collisions. §7 Risks and rejected alternatives. §8
Verification. Hand-off notes. Review fold records (rev 2, rev 3) and the
Sign-off. Appendix A the
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

**`IsCallPerformable` on trunk 701863aa5** (toolchain/check/call.cpp:1023-1052;
the comment at :1023-1024, the signature at :1025, D-TP-11's comment and
`forms_type` at :1031-1047, `return true;` at :1051 and the closing brace at
:1052; amended 2026-11-16, review fold: RR1-m3, rev 2 said :1023-1049):

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
| check/testdata/class/destroy_calls.carbon | outside TP-1's and SC-1's template golden directories by path: W-374's break condition FIRED by its letter on this file (ruled 2026-11-16, the orchestrator, R29: the removal proceeds, the changed split being D-TP-11's own refill, plan §1.6: "generic/template/convert.carbon and class/destroy_calls.carbon refill"; D-TP2-4; superseding rev 1's cell "TP-1's by substance (D-TP-11's refill, plan §1.6), outside generic/template/ by path") | only the split `generic_use_inside_template` (`class C(template T: type) {}`, `fn F(template T: type)` at :89-100) changes: `%C.1d0: type = class_type @C, @C(%T) [template]` and the instructions over it become `call_action`/`splice_inst` forms; no STDERR; the other five splits are untouched (every hunk of the fill lies after :1017, where that split's STDOUT begins; re-measured at the fold) |
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

prints nothing (0 lines), where the `// ---` lines it excludes are the
renames below (36 on the planner's tree; 53 at the fold, the re-measurement
below).

**Gate after the fill** (gate-tp2-planner-20261116T161156Z.log): not 2047;
file_test's `fail_`-prefix rule (testing/file_test/file_test_base.cpp:274,
`fail_prefix_problems`) reports nineteen prefix problems in six files (amended
2026-11-16, review fold: B5; rev 1 said "eighteen splits in five files"): the
eighteen this plan renames, in five files, sixteen that "failed; if failure is
expected, add the `fail_` prefix" and two that "succeeded; if success is
expected, remove the `fail_` prefix", and a nineteenth in a sixth file,
template_constraint_dependent.carbon's `fail_dependent_conversion_unsatisfied`
"succeeded", because that gate ran on the hunk-removed build: it is the
measurement that decides D-TP2-3, and M2 restores it (§0.5):

| Golden | Splits that now fail (renamed `fail_todo_`) | Splits that now succeed (renamed `todo_fail_`) |
| --- | --- | --- |
| check generic/template/deduce_class_args.carbon | holder, holder_copy_constraint, holder_pointer, vec_value_param, template_class_type | fail_class_template_literal_with_dependent_array_bound_unknown_field |
| check generic/template/index.carbon | index_class_with_index_with | |
| check generic/template/match_choice.carbon | designator_arm, designator_arm_exhaustive, value_param, nested_match, guard, pattern_forms, int_scrutinee | |
| check generic/template/pointer.carbon | | fail_deref_class_type_param |
| lower template/match_choice.carbon | designator_arm, let_else_payload, int_scrutinee | |

The names follow the tree's convention (2418 `fail_` splits and 45 `todo_`
splits over check/testdata and lower/testdata at 701863aa5, counted by
`grep -rh '^// --- fail_'` and `grep -rh '^// --- todo_'`; amended 2026-11-16,
review fold: RR1-m2, rev 2 said 418 and 42; among them
`todo_fail_private_on_redecl` and `todo_fail_alias_two_file`: a split that
should fail and does not is `todo_fail_`; one that should pass and fails is
`fail_todo_`). With the eighteen renames applied as source edits and the hunk
restored (§0.5, M2) the fill converged again in one pass
(autoupdate-tp2-planner-20261116T162905Z.log: 4 files; ...162917Z.log: 0) and
the gate is **`GATE tp2-planner: 2047 passed, 0 failed`**
(gate-tp2-planner-20261116T162929Z.log). The eleven goldens' numstat on the
planner's tree (renames only, no TODO line): destroy_calls 88/59, convert
94/70, deduce_class_args 87/108, default_init 52/29, index 53/70, match_choice
82/405, pointer 1/5, template_constraint_dependent 16/17, lower class 2/2,
lower initialize 929/1061, lower match_choice 15/530 (insertions/deletions,
3739 CHECK lines in all).

**The eight more renames and the pin (amended 2026-11-16, review fold: A-M1 /
B3).** Eight more match_choice.carbon splits keep failing after the refill but
with the scrutinee TODO in place of the diagnostic each name promised
(`fail_nonexhaustive` pinned `MatchNonexhaustive`; `fail_never_matches`,
`fail_int_never_matches`, `fail_unknown_alternative`,
`fail_guard_on_instantiation`, `fail_int_literal_out_of_range_on_instantiation`,
`fail_payload_literal_on_instantiation` and
`fail_payload_not_trivial_on_instantiation` likewise;
`fail_todo_qualified_alternative` was already so named): they are renamed
`fail_todo_` with a W-397 TODO line each, as the tree's convention for a split
that pins a TODO and R16's weakened-assertion check require (ruled 2026-11-16,
the orchestrator, R29, ruling 4, superseding rev 1's "The nine `fail_` splits
of match_choice.carbon whose diagnostic changes keep their names (they still
fail)"). Twenty-six renames in all (52 `// ---` lines). One split is added,
`fail_todo_impl_forall_formed_self` in deduce_class_args.carbon, pinning
W-400's form (A-M1; adopted by ruling 7). **Re-measured at the fold on the
label tp2-fixer** (the worktree /home/user/carbon-tp2-fixer at 701863aa5 with
§2.1's diff, the twenty-six renames and their TODO lines, A.3's line, the pin
split and the hunk kept, C1's exact shape; build-tp2-fixer.log "done status=0
2026-11-16T17:19:30Z", no warning): the gate before the fill `GATE tp2-fixer:
2036 passed, 11 failed` (gate-tp2-fixer-20261116T171946Z.log), the eleven
files above, each "Autoupdate would make changes", 0 prefix problems, no crash
(B6: the TODO lines and the pin are measured, not inferred); autoupdate 11
files then 0 (one pass); the gate after the fill `GATE tp2-fixer: 2047 passed,
0 failed` (gate-tp2-fixer-20261116T172132Z.log). The TODO lines shift the
splits' source lines, so the dumped SemIR's `loc<line>_<col>` names move with
them and the numstat is larger than the planner's: destroy_calls 88/59,
convert 94/70, deduce_class_args 165/143, default_init 52/29, index 80/95,
match_choice 113/415, pointer 4/5, template_constraint_dependent 18/18, lower
class 2/2, lower initialize 929/1061, lower match_choice 22/530 (1567
insertions, 2427 deletions; 3875 CHECK lines; the 119 non-CHECK changed lines
are exactly the 53 `// ---` lines, the 27 TODO comments over 45 lines, the
pin's 18 source lines and A.3's three). The pin split's filled diagnostics:
`` `impl` with unused generic binding [ImplUnusedBinding] `` at the `impl
forall`, ``warning: binding `self` unused [UnusedBinding]`` in `Val`, and
``cannot access member of interface `I` in type `Box(i32)` that does not
implement that interface [MissingImplInMemberAccess]`` at `h.(I.Val)()`; on
tp2-base the same source runs (the probe a2_impl_self prints 11).

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
| ded_checked_twin (`[T: type]`, `-> i32`; amended 2026-11-16, review fold: RR1-m1, the paragraph after this table) | prints 42 | prints 42 | prints 42 |
| e1n (`let unused y: HasGet = T;` in a template body, interface, called with a `D`) | runs, rc 1 | runs, rc 1 | ``cannot convert type `T` into type implementing `HasGet` `` at the definition |
| e2n (`G(T as HasGet)`) | runs, rc 3 | runs, rc 3 | the same, at the definition |
| e3n (`let y: HasGet = T; return x.(HasGet.Get)();`) | ``unable to monomorphize specific `F(D)` `` | the same | at the definition, then the member note |

e1n and e2n are outside W-374 (a conversion outside a call): on the fork
D-TP-12 keeps the impl lookup deferred and nothing forces the unused facet
value's witness in `F(D)`; filed as W-399 (D-TP2-8).

ded_checked_twin's row (amended 2026-11-16, review fold: RR1-m1): rev 2
wrote the twin as `fn GetChecked[T: Core.Copy](h: Box(T)) -> T { return
h.item; }` and its row as "prints 42" on the three toolchains, but the
planner's scratch probe was the `[T: type]`, `-> T` form, which tp2-base,
the prototype and the nightly all reject, ``cannot copy value of type `T` ``
with the note ``type `T` does not implement interface `Core.Copy` `` (the
planner's probes_base.txt, probes_nightly.txt and probes_planner.txt record
that failure; the re-review's and this fold's runs reproduce it), so the row
was never measured as stated. The twin is now `fn GetChecked[T: type](h:
Box(T)) -> i32 { return 42; }` (A.4), which prints 42 on tp2-base, the
prototype tp2-fixer1 and the nightly (scratchpad/tp2/fixer1/out); the
`[T: Core.Copy]`, `-> T` form as rev 2 wrote it also prints 42 on the three
when it is compiled at the fold (fixer1's ded_checked_twin_copy). Both forms
measure the control D-TP2-2 relies on, that a checked parameter still
deduces through a class specific `Box(T)`; the rejected `-> T` form failed
on its body's copy of `h.item`, not on deduction.

**Review A's forms (amended 2026-11-16, review fold: A-M1 / A-m1 / A-m4),
re-run at the fold on tp2-base, the prototype tp2-fixer and the nightly** (the
sources in A.4; tp2-fixer is M2's shape, call.cpp upstream's and the hunk
kept):

| Probe | baseline tp2-base | prototype tp2-fixer | the nightly |
| --- | --- | --- | --- |
| a2_impl_self (`impl forall [template T: type] Box(T) as I` for `class Box(T: type)` and `interface I { fn Val(self) -> i32; }`; `h.(I.Val)()` on a `Box(i32)`) | prints 11 | `` `impl` with unused generic binding `` at the `impl`, then ``cannot access member of interface `I` in type `Box(i32)` that does not implement that interface`` at the call; two errors | the first error, then a crash (CHECK failure sem_ir/generic.cpp:84, "Given a specific for the wrong generic") |
| a3_impl_iface (`interface J(T: type)`, `impl forall [template T: type] W as J(T)`, `w.(J(i32).Val)()`) | prints 13 | ``impl as non-facet type `J(T)` `` then the member-access error for `J(i32)` in `W`; two errors | ``impl as non-facet type `<splice of ...>` `` (the splice is not stringified) then the same second error |
| a8_require (structural: `interface I { require impls HasGet; fn Val(self) -> i32; }`, `impl forall [template T: type] Holder(T) as I`, a `Holder(C)`) | prints 8 | `` `impl` with unused generic binding `` then ``cannot access member of interface `I` in type `Holder(C as HasGet)` ...``; two errors | not applicable (no `template constraint`) |
| a5_core_int (`fn Bits[template N: Core.IntLiteral](x: Core.Int(N)) -> i32`, called with an `i64`) | prints 1 | ``cannot deduce value for generic parameter `N` `` with `DeductionGenericHere` | the same |
| declact (`fn Wrap(template F: type, template T: F) -> Holder(T)`; `Caller[U: type]` with `var h: Holder(U) = Wrap(type, U);`; a `C`) | prints 6 | prints 6 | not applicable |
| declactd (the same with a `D`) | ``unable to monomorphize specific `Caller(D)` `` with SC-1's three notes twice and `InitializingGenericParam`; two errors | the same errors and notes | not applicable |

So the three `impl forall` forms are lost forms outside D-TP2-2's rev 1 list on
which trunk and the nightly differ: D-TP2-1's falsifier was met, and the cost
is recorded as W-400 and pinned (D-TP2-2, D-TP2-8), not repaired (R32 (d)).
a5_core_int is a W-396 form (`N` through `Core.Int(N)`), which the
int_scrutinee splits hide behind the body's TODO. The declact pair is unchanged
by TP-2: a declaration-region `call_action` resolved by `MakeSpecific` replays
as before.

**W-139's probes (fo1-plan.md :396-420, :505-520, :565-600) on the three
toolchains** (the nightly has no `template constraint`: "unrecognized
declaration introducer" for every structural probe, as FO-1 recorded):

| Probe | baseline tp2-base | prototype with the hunk removed | prototype M2 (the hunk kept) |
| --- | --- | --- | --- |
| m17c (`var h: Holder(T)`, `D`) | ``unable to monomorphize specific `Wrap(D)` `` with SC-1's three notes | the same plus ``initializing generic parameter `T` declared here`` | the same as with the hunk removed (one error) |
| m17 (with a `C`) | prints 5 | prints 5 | prints 5 |
| m17f (`Holder(T)` returned; `var h: Holder(D) = Wrap(d)`) | two errors: the caller's conversion, then `Wrap(D)` | the same two, the second with the generic-parameter note | the same as with the hunk removed |
| m17d (through a checked `Caller`) | `Wrap(D)` with SC-1's notes | the same plus the note | the same |
| m9t, m9td (m17f through a checked `Caller`, `C` and `D`) | m9t prints 5; m9td `Caller(D)`, two errors | the same two, with the generic-parameter note (amended 2026-11-16, review fold: A-m1: rev 3 said "the same"; measured, tp2-base gives the two errors with 6 notes and the implementation's install the same two with 7, the seventh ``initializing generic parameter `T` declared here`` at `class Holder(template T: HasGet)`, as the m17f row records) | the same |
| e1 (`let unused y: HasGet = T;`, structural, `D`) | ``unable to monomorphize specific `F(D)` `` with SC-1's notes | **runs, rc 1** (the hole re-opened) | ``unable to monomorphize specific `F(D)` `` with SC-1's notes |
| e2 (`G(T as HasGet)`) | `F(D)`, the same notes | **runs, rc 3** | `F(D)`, the same notes |
| e1c (e1 with a `C`) | runs, rc 1 | runs, rc 1 | runs, rc 1 |
| conv (`let unused y: HasGet = U;` in a checked generic) | D-SC-6's rejection with `StructuralRequirementNeedsConcreteType` | the same | the same |
| gc, gcd (`Holder(U)` in `Make[U: type]`, `C` and `D`) | gc returns 3; gcd `Make(D)` with SC-1's notes | the same | the same |
| q11e (`overload fn Pick` pair, `Caller[U: type]` with a `D`) | ``unable to monomorphize specific `Caller(D)` `` with SC-1's notes (W-375) | the same | the same |
| thunk1 (`impl W as I` whose `F[template T: HasGet]` implements `I.F[U: type]`, `C`) | prints 9 | prints 9 | prints 9 |
| thunk1d (`D`) | two errors: the thunk's conversion with `DeductionGenericHere`, then `F(D)` (W-376) | the same | the same |
| t3s, t7s (`Take[U: type](h: Holder(U))`; `Outer` to `Inner`) | 4; 6 | 4; 6 | 4; 6 |

The declact pair (a declaration-region `call_action` resolved by
`MakeSpecific`, fo1-plan.md:574-578; amended 2026-11-16, review fold:
RR1-m3, rev 2 said :570-574) was not re-created by rev 1; review A
re-created it from the description and the fold re-ran it (the table above and
A.4): TP-2 changes nothing there (amended 2026-11-16, review fold: A-m4).

**The changed goldens' splits, checked with `compile --phase=check` on the
three toolchains** (93 splits of six goldens at 701863aa5, deduce_class_args
24, index 22, match_choice 24, pointer 11, template_constraint_dependent 8
and lower's match_choice 4; amended 2026-11-16, review fold: RR1-m2, rev 2
said 90; the full table is the plan
writer's scratch, its rows with a change summarised here):

| Split | baseline | prototype | the nightly |
| --- | --- | --- | --- |
| deduce_class_args: holder, holder_copy_constraint, holder_pointer, template_class_type, vec_value_param | checks | ``cannot deduce value for generic parameter `T` `` (`N`) | the same |
| deduce_class_args: fail_class_template_literal_with_dependent_array_bound_unknown_field | ``struct `Arr(N)` has no field named `m` `` | checks (no diagnostic) | checks |
| deduce_class_args: the other 18 splits (of 24 at 701863aa5; amended 2026-11-16, review fold: RR1-m2, rev 2 said 19) | as filled | unchanged | the nightly crashes or rejects seven of them (rc 134 or 139 on `class_template_field_of_where_alias` and `fail_checked_generic_calls_template_with_class_template_runtime_literal`; `unable to monomorphize` on the field-default splits), TP-1's W-273 and W-274 forms |
| index: index_class_with_index_with | checks | ``cannot deduce value for generic parameter `T` `` | the same |
| index: the other 21 splits (of 22; amended 2026-11-16, review fold: RR1-m2, rev 2 said 23) | as filled | unchanged | the nightly rejects the tuple-index forms at the definition (``type `T` does not support tuple indexing``), TP-1's C3 forms |
| match_choice (check): designator_arm, designator_arm_exhaustive, value_param, nested_match, guard, int_scrutinee | checks | ``semantics TODO: `match on unsupported scrutinee type` `` | ``semantics TODO: `choice alternatives with parameters are not yet supported` `` or ``semantics TODO: `HandleMatchIntroducer` `` |
| match_choice: pattern_forms, let_else_payload (lower) | checks | ``semantics TODO: `refutable pattern binding on unsupported scrutinee type` `` | the same TODOs as above |
| match_choice: the nine `fail_` splits named in §0.3's table (eight of them renamed `fail_todo_` at the fold, B3) | their specific diagnostics | the scrutinee TODO | the nightly's TODOs |
| match_choice: class_template_choice, fail_unknown_alternative_class_template, the four `fail_todo_scrutinee_*` (amended 2026-11-16, review fold: RR1-m2, rev 2 said five), `fail_todo_case_template_constant`, `fail_todo_pattern_form_deferred_call` | as filled | unchanged | the nightly's TODOs |
| pointer: fail_deref_class_type_param | ``cannot dereference operand of non-pointer type `C(T)` `` | checks | ``cannot dereference operand of non-pointer type `<splice of ...>` `` (the nightly's `*` on a splice is rejected at the definition; TP-1's C3 defers it, D-TP-7) |
| pointer: the other 10 splits (of 11; amended 2026-11-16, review fold: RR1-m2, rev 2 said 11) | as filled | unchanged | the nightly rejects `*`, `->` and `&` on `T` at the definition (TP-1's C3) |
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
prefix rule over the twenty-six renamed splits, the pin split and m17n_d as
D-TP2-1's detectors
(§8.5), and registers H10.8 with an L check as before plus the quote rows of
§0.8.

### §0.6 Conformance

On the hunk-removed prototype before any program edit
(/home/user/arb/conformance/tp2-planner, first run): `CONFORMANCE tp2-planner:
PASS 226 / FAIL 2 / SKIP 13 over 241 programs; bullets 50 PASS, 1 FAIL, 5 SKIP`.
The two failures: generics/templates_deduce_class_args.carbon (``cannot deduce
value for generic parameter `T` `` at :62:14 `Core.Print(Get(h));` and :63:14
`Core.Print(GetThrough(&h) * 2);`, ``... `N` `` at :65:14
`Core.Print(Size(v));`) and generics/templates_match_dependent_choice.carbon (``semantics
TODO: `match on unsupported scrutinee type` `` at :46:9, the `match (s)` of
`Count`). Both are TP-1's programs for the forms D-TP2-2 withdraws; neither
depends on the hunk. That first run's log was overwritten by the planner's
second run (B9); its surviving evidence is the fold's re-run on tp2-fixer before
the SKIP edit: `CONFORMANCE tp2-fixer: PASS 226 / FAIL 2 / SKIP 13 over 241
programs; bullets 50 PASS, 1 FAIL, 5 SKIP, 0 NOT-WRITTEN (of 56 in the
gap-analysis table) (runner exit 1)`, kept as
/home/user/arb/logs/conformance-tp2-fixer-noskip.txt and
conformance-tp2-fixer-noskip.log (the CONFORMANCE.txt and the log copied before
the SKIP edit, which the implementer repeats, §8.4); the two program logs there
give templates_deduce_class_args.carbon:62:14 and :63:14 (`T`) and :65:14 (`N`)
``cannot deduce value for generic parameter`` and
templates_match_dependent_choice.carbon:46:9 ``semantics TODO: `match on
unsupported scrutinee type` ``. (amended 2026-11-16, review fold: B9) With the
two `// SKIP:` directives of Appendix B and the README table regenerated (`runner.py
--update-readme-table`, which the self-test requires), the second run on the
final tree:
**`CONFORMANCE tp2-planner: PASS 226 / FAIL 0 / SKIP 15 over 241 programs; bullets 51 PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN`**
(runner exit 0; the bullet stays PASS by the runner's rule, runner.py:876-900:
every non-SKIP program of the bullet passes and at least one passes). No other
program's output changed (the scoreboard's other 239 rows equal the baseline's).
Re-run at the fold with Appendix B's one-line directives (B2): `CONFORMANCE
tp2-fixer: PASS 226 / FAIL 0 / SKIP 15 over 241 programs; bullets 51 PASS, 0
FAIL, 5 SKIP, 0 NOT-WRITTEN (of 56 in the gap-analysis table) (runner exit 0)`
(conformance-tp2-fixer.log, 2026-11-16 17:29 UTC); `runner.py --self-test`
prints "self-test: 241 programs parsed, 56 bullets in table, OK" and records
each program's skip_reason as the whole directive line: the marks begin ``SKIP:
deduction through a class's arguments is withdrawn by TP-2 (fork work item
W-396; fork/templates/tp2-plan.md D-TP2-2): with `IsCallPerformable`
upstream's`` and ``SKIP: refutable patterns on a template-dependent choice value
are withdrawn by TP-2 (fork work item W-397; fork/templates/tp2-plan.md
D-TP2-2)``, and each ends "or the nightly runs this program." (Appendix B quotes
them whole); the diagnostics' lines after the insertion of one line at :6 of
each program are :63:14, :64:14 and :66:14, and :47:9, and the directives name
those (rev 1's blocks named the pre-insertion lines and were recorded by
runner.py:263-265 as their first line only). (amended 2026-11-16, review fold:
B2)

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
    :308-311, and docs/design/generics/overview.md:102-108, verbatim (their
    markdown links kept as written):

<!-- google-doc-style-ignore -->

```text
README.md:3012-3016:
Member lookup into a template parameter is done in the actual value provided by
the caller, _in addition_ to any constraints. This means member name lookup and
type checking for anything [dependent](generics/terminology.md#dependent-names)
on the template parameter can't be completed until the template is instantiated
with a specific concrete type. When the constraint is just `type`, this gives

terminology.md:263-268:
even with templates, to check semantics of expressions that are not
[dependent](#dependent-names) on any template parameter in the definition.
Adding constraints to template parameters and/or switching them to be checked
allows the compiler to increase how much of the definition can be checked. Any
remaining checks are delayed until [instantiation](#instantiation), which can
fail.

terminology.md:308-311:
    `template` keyword. Expressions using such a binding are
    [dependent](#dependent-names) and are
    [late type checked](#early-versus-late-type-checking) once an instantiation
    provides the binding's value.

overview.md:102-108:
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
class type, the gap W-396 records. (Line labels re-anchored at the fold,
amended 2026-11-16, review fold: A-m2 / B7: the quoted texts were right; at
7a3608bab the terminology quote starts at :263, the binding-pattern quote runs
:308-311 (B7's ":308-310" stops one line short of ":311 provides the binding's
value."), the overview quote runs :102-108 and the proposal's two sentences
:205-209 (:207 is blank, so the consequence sentence is :208-209; B7's
":207-209" counts the blank line).) The register's remaining quotes:

-   proposals/p002200-template-generics.md:205-209: "Impl lookup is delayed
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
:20285-20286, :21302), fork/direction/plan.md:1034 and, listed at the fold
(amended 2026-11-16, review fold: A-m2), fork/variadics/va2-plan.md,
fork/eh/ehc-plan.md, fork/overload/ov4-plan.md, fork/register/rg1-plan.md,
fork/land/land1-plan.md and fork/inventory/work-items.json:5162 (a notes
field's range bound), never a ledger id; no W-4xx anywhere. The ledger at
701863aa5 holds 313 items, maximum W-395. **The next free id is W-396**; this
plan reserves W-396 to W-400 and files all five (D-TP2-8). Re-scanned at the
fold (2026-11-16 17:17 UTC, after `git fetch origin`, the planner's script):
969 refs, 745 distinct heads, 11 worktrees; W-396 to W-399 now also in this
branch's plan (34 to 38 refs), W-400 nowhere (the regex covers `W-4[0-9][0-9]`),
so **W-400 is the next free id** and is reserved for the `impl forall` family
(A-M1; ruling 7).

### §0.10 The tree checker: what is measured and what is not run

Measured by the container arbiter (R28 and R33 as amended 2026-11-09):
build.sh, install.py, gate.sh (file_test over its whole manifest, 2047 files),
autoupdate.sh to a fixpoint, conformance.sh (runner.py over 241 programs),
`runner.py --self-test`; the probes of §0.4 with the three toolchains' own
`carbon` binaries; `git merge-tree`; the id re-scan; prek on the plan. Not run:
Bazel (none in the container), clang-tidy and clangd-tidy, the hosted gate
(Actions disabled), the owner's machine and runner (R28), `--phase=lower`
dumps of the probes (the gate's lower goldens cover them). The C++ change
compiles under the arbiter's clang 21 with the repository's flags (the build
log has no warning for call.cpp). (Amended 2026-11-16, review fold: A-m4 / B6
/ B9: FO-1's declact pair is now re-created and run (§0.4); rev 1's C1 gate
shape with Appendix A's TODO lines was inferred from the renames-only tree and
is now measured on tp2-fixer with the TODO lines and the pin in place (§0.3);
rev 1's first conformance run (226/2/13) had no surviving log, the planner's
second run having overwritten it, and the fold's re-run is kept under its own
name (§0.6).)

## §1 Design

**D-TP2-1, the deferral rule is upstream's, to the letter.** `IsCallPerformable`
(toolchain/check/call.cpp) returns false when the callee or any argument is
`SemIR::ConstantDependence::Template`, as upstream's at 7a3608bab (call.cpp:
449-464, quoted in §0.2 and §0.8); D-TP-11's `forms_type` test, its ternary
and its six-line comment are removed, and nothing takes their place under
another name (R17; M1 of §0.5 is the mutant that keeps the exception renamed,
caught by the gate's prefix rule on the twenty-six renamed splits and the pin
split, and by m17n_d).
The function's text is upstream's but for `OperandDependence(context, ...)`,
the signature the fork keeps until UA-3 (§0.7). Register row H10.8 becomes
ALIGNED (D-TP2-6). _Break condition:_ upstream changes which operands or which
dependence defer a call in `IsCallPerformable`, or docs/design/README.md
:3012-3016 or p002200:205-209 change; then the row is re-read by the weekly
check (W-355) and this plan amended. _Falsifier of the choice:_ a form on which
trunk and the nightly differ outside the forms D-TP2-2 lists, W-400 included;
such a form is a cost to record under R32, never a repair by a fork helper (R32
(d)). (Amended 2026-11-16, review fold: A-M1: rev 1's falsifier sentence, "a
probe on the prototype that trunk rejects and the nightly accepts, or the
reverse, outside the forms D-TP2-2 lists (none found in §0.4)", was false:
review A's a2_impl_self, a3_impl_iface and a8_require, an `impl forall` with a
template binding whose self or interface is formed from it, run on trunk and
are rejected by the prototype and the nightly (§0.4); the cost is W-400
(D-TP2-2, D-TP2-8), pinned by `fail_todo_impl_forall_formed_self`.)

**D-TP2-2, the cost of realignment is recorded, residues are filed, no fork
mechanism is added.** With the type-forming call deferred, `Holder(T)` in a
parameter's type is a `call_action` splice, and the toolchain, like the
nightly, cannot deduce `T` from a `Holder(i32)` argument (§0.4: the five
deduce_class_args splits, index's `index_class_with_index_with`,
templates_deduce_class_args.carbon). Upstream's deduce.cpp has no case for a
splice and its "TODO: Handle more cases." names no mechanism (§0.8), so under
R32 (d) the plan adds none: the forms are filed as W-396 (deduction through a
class type formed from a template parameter: W-193's forms, re-opened, with
`ded_holder` as the probe, and `Core.Int(N)`, a5_core_int; the workaround is
an explicit template argument,
`ded_explicit`, which runs on every toolchain) and the splits and the program
are renamed and SKIPped with W-396 in their comments. The same deferral makes a
generic choice applied to a template parameter a splice, so refutable patterns
on it return to the scrutinee TODO that trunk reported before TP-1's round 10
(X-1): W-397 (the match_choice splits and templates_match_dependent_choice;
the nightly reports its own TODOs there). Two definition-time diagnostics now
wait for an instantiation that their splits never make: W-398
(`fail_deref_class_type_param` and
`fail_class_template_literal_with_dependent_array_bound_unknown_field`, renamed
`todo_fail_`; the nightly agrees on the first and the second). An `impl forall`
with a template binding whose self (`Box(T)`, `Holder(T)`) or interface
(`J(T)`) is formed from it is rejected, `` `impl` with unused generic binding ``
or ``impl as non-facet type `J(T)` ``, as on the nightly, where trunk accepted
and ran it: W-400 (amended 2026-11-16, review fold: A-M1; the probes
a2_impl_self, a3_impl_iface and a8_require of §0.4; pinned by the split
`fail_todo_impl_forall_formed_self` of deduce_class_args.carbon, adopted in C1
by the orchestrator's ruling 7, R16 preferring a pin to a prose note; no fork
helper, R32 (d)). W-396 also covers `Core.Int(N)` for a template `N` (A-m1,
the probe a5_core_int; the int_scrutinee splits' TODO lines name it). The gap
row stays PARTIAL; its evidence cell names the two SKIPs and the residues
(D.7; ruling 3). TP-1's D-TP-11
is amended, not deleted: its history stands and its ruling is superseded by
this decision (C.1). _Break conditions:_ W-396, upstream's deduce.cpp deduces a
binding through a template-dependent splice or the nightly runs `ded_holder`
(then the fork follows the mechanism and the splits lose `fail_todo_`); W-397,
upstream's `match` accepts a scrutinee whose type is a splice; W-398, upstream
diagnoses either form at the definition; W-400, upstream's impl lookup deduces
a template binding through a splice-typed self or interface, or the nightly
runs a2_impl_self (prints 11). _Falsifier of the cost:_ a form the
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
hunk. (Ruled 2026-11-16, the orchestrator, R29, ruling 6: a finding that this
keeping contradicts W-374's text is answered by the measurement, e1 and e2 run
without the hunk; W-374's note says the hunk is kept and why (D.1) and H9.8's
break condition is re-read accordingly (D.6). Re-measured at the fold on
tp2-fixer: e1 and e2 rejected in `F(D)` with SC-1's three notes, m17n_d as the
nightly's, §0.4.)

**D-TP2-4, the goldens and the item's break condition.** The eleven goldens of
§0.3 refill by autoupdate only (R16), CHECK lines only; the twenty-six renamed
splits and the pin split are source edits of C1, each with a `// TODO:` line
naming the residue (Appendix A), in the tree's `fail_todo_`/`todo_fail_`
convention; no split is deleted and no CHECK line is hand-written. W-374's
break condition, "the removal changes a golden outside TP-1's and SC-1's
template goldens (then STOP and report)", FIRED by its letter:
check/testdata/class/destroy_calls.carbon lies outside TP-1's and SC-1's
template golden directories by any path reading and its CHECK lines change.
The report is §0.3's table: the file; the split `generic_use_inside_template`
(`class C(template T: type) {}` and `fn F(template T: type)` at :89-100); the
change, `class_type @C, @C(%T) [template]` back to `call_action` and
`splice_inst`, every hunk after :1017 where that split's STDOUT begins; no
diagnostic. (Ruled 2026-11-16, the orchestrator, R29, ruling 1: THE REMOVAL
PROCEEDS. The changed split is a template split, its source uses a template
parameter, that D-TP-11 itself refilled when TP-1 landed (TP-1 §1.6,
"generic/template/convert.carbon and class/destroy_calls.carbon refill"), so
it is TP-1's own golden by substance, and the condition's purpose, to catch the
removal changing non-template behaviour, is not met by it. The condition's
letter is amended in W-374's note (D.1) and here: a template golden is a golden
whose changed split uses a template parameter, wherever the file lives; the
condition stays STOP for any changed split that uses no template. This ruling
supersedes rev 1's text, "the plan takes the second reading, because the
condition's purpose is a blast radius beyond the template forms, which a
template split's reversal is not, and judges it NOT fired. This is the first
question for the plan reviews; if a review takes the first reading, the item's
instruction is to STOP and report, and this plan is that report", which review
B's B4 found to be the planner re-reading the spec to avoid a STOP (R17) and
review A's A-m3 ruled sound on the substance; the ruling, not the substance
reading, is the record, and D.1's W-374 note, D.3 and the Status paragraph
carry the same sentence.) _Break condition of the ruling:_ a changed split with
no template parameter, or a changed CHECK line of a non-template split in any
refilled file (then STOP); a golden outside the eleven changes at the
implementer's fill (then STOP: the blast radius is wider than measured).
(amended 2026-11-16, review fold: A-m3 / B4)

**D-TP2-5, the programs.** templates_deduce_class_args.carbon and
templates_match_dependent_choice.carbon gain one `// SKIP:` line under R10 (the
exact diagnostic, the line and column after the insertion, the residue id and
the un-SKIP condition, in the runner's recorded form; Appendix B), their EXPECT
lines unchanged so that un-SKIP is mechanical; the README program table is
regenerated by `runner.py --update-readme-table` (two rows `run` to `SKIP`),
which the self-test requires. Rewriting the programs with explicit template
arguments is rejected (§7.2: it would hide the loss the SKIP pins). Expected:
PASS 226 / FAIL 0 / SKIP 15 over 241, 51 of 56 bullets (measured, §0.6, twice).
R16 (b)'s presumption is answered: the reason cites R32's realignment and the
residues. (Ruled 2026-11-16, the orchestrator, R29, ruling 3: each SKIP is ONE
`// SKIP:` line in the runner's recorded form, the diagnostic text, the
post-insertion file:line, the residue id and the un-SKIP condition, plain
comment lines after it only if more is needed, superseding rev 1's multi-line
blocks, whose continuation lines runner.py:263-265 never records, so the
scoreboard and W-355's readers would have seen a reason without the diagnostic,
the file:line or the id (B2); the two SKIPs under R10 are accepted as the cost
of R32 (d): upstream's deferral is the design, the fork's extra deduction was a
fork mechanism beyond upstream's text, now withdrawn with W-396 filed and owned
by TP-1's follow-on, and the refutable-pattern family is W-397; the bar for
TP-2's landing is 226 PASS / 0 FAIL / 15 SKIP over 241 with 51 of 56 bullets,
stated in §5 and in Appendix F's land-time texts, and the gap row stays PARTIAL
with its evidence cell naming the two SKIPs and the residues.) _Break
condition:_ the implementer's conformance run differs from 226/0/15 or 51/0/5;
of the ruling: upstream lands deduction through a dependent class type
(deduce.cpp's TODO at :443 resolved), and the SKIPs are lifted at the next
advance that brings it.

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
twenty-six renames with their TODO lines, the pin split, the SC-1 split's stale
TODO line, the two SKIP directives, the README table); F1 (the fill); P (the
plan and page amendments of Appendix C); two implementation reviews; at most two
fix commits with their fills; R; D; the PR; the landing (§3). The shrink line:
the renames and the SKIPs may be re-cut by a fix (a split moved between
`fail_todo_` and `todo_fail_` after the fill), the amendments may follow in a
later records commit, but the call.cpp change never shrinks and the hunk is
never removed "to see". _Break condition:_ a third defect needing a toolchain,
golden or program change stops the PR at rev 2 of this plan.

**D-TP2-8, the residues W-396 to W-400.** W-396 deduction through a class type
formed from a template parameter, `Core.Int(N)` included (probes ded_holder and
a5_core_int; break condition above).
W-397 refutable patterns on a template-dependent choice value (probe: the
program templates_match_dependent_choice.carbon; the match_choice splits).
W-398 two definition-time diagnostics moved to instantiation (probes: the two
`todo_fail_` splits). W-399 a conversion of a template-dependent self to an
interface outside a call, its facet value unused, is never checked: e1n and e2n
run with rc 1 and 3 on trunk and the prototype where the nightly rejects them
at the definition (``cannot convert type `T` into type implementing `HasGet`
``); D-TP-12 keeps the lookup deferred and nothing forces the witness; owner
TP-1's follow-on, not this plan's (outside W-374: not a call). W-400 an `impl
forall` with a template binding whose self or interface is formed from it
(`Box(T) as I`, `W as J(T)`, `Holder(T) as I` with a `require`): trunk accepts
and runs them (11, 13, 8), the prototype rejects them, and the nightly rejects
the two nominal ones the same way (a2_impl_self then crashes in
sem_ir/generic.cpp:84; a8_require is structural, outside the nightly's
grammar); not W-398's substance (a capability lost, not a diagnostic moved),
so a residue of its own (ruling 7); pinned by
`fail_todo_impl_forall_formed_self`; owner TP-1's follow-on; no fork helper
(R32 (d)). (amended 2026-11-16, review fold: A-M1 / A-m1) Each entry has its
evidence, removal and break condition (D.1). _Break condition:_ the id re-scan
at D finds any of the five used elsewhere (then the next free ids are taken
and this plan's texts re-numbered by D).

**D-TP2-9, the PR and the landing.** One PR, base trunk, opened by the
orchestrator after a dry review round and landed by LAND-1's D-LAND-6 under R33
with one landing reviewer, Appendix F's texts; the land tree is measured by the
arbiter: gate 2047 of 2047, conformance 226/0/15 over 241, 51 of 56 bullets (the
bar of D-TP2-5's ruling). The expected scoreboard is lower than trunk's by two
SKIPs, each explained by D-TP2-5; R33 (a)'s "not regressing against the PR's
expected scoreboard" is read against this plan's figures. _Break condition:_ the
land tree's figures differ (then the landing stops at D-LAND-6 step 4).

**D-TP2-10, the docs.** docs/design/templates.md gains two dated TP-2 notes
(the TP-1 fork note at :228-240 that lists "deduction through a class's
arguments" among the resolved limits, and the W-193 limit bullet at :578-582
that says "Resolved by TP-1"), stating the withdrawal, W-396, W-397 and W-400
(C.4).
docs/design/generics/template_constraints.md:484-487 ("when a template
converts a type that depends on its own template parameters to a template
constraint, as `Holder(T)` does ... the structural requirements are checked in
each specific of the template") stays true, by the replay for a call and by
the hunk for a conversion outside one, and is not edited; verified, not
changed. The gap row's clause on `match` is withdrawn in the evidence cell.
_Break condition:_ the designdocs checker (`runner.py --self-test`'s W2 rule)
rejects a note (then it is reworded, not dropped).
(Amended 2026-11-16, fix 1: A-M1 / B-M1. The designdocs checker with
`--toolchain`, which §0.10's run left out (the toolchain-free self-test does
not compile the fixtures), was red on C1+F1 and on P with one error and green
on tp2-base: the TP-1 fork note at :169-172, "The deduction is implemented:
`GetTemplate(h)` deduces `T` as `i32` from `Holder(T)`", and its quote fixture
fork/designdocs/samples/X25_template_deduce_class_arg.carbon, whose
EXPECT-STDOUT is 42, claimed the capability the deferral withdraws, and the
W-193 bullet's "see the TP-2 fork note there" named a note that its section
did not have. That blockquote gains a third dated paragraph, the TP-2 note of
C.4's third block, and X25 is re-pinned as an EXPECT-ERROR fixture whose QUOTE
is that paragraph's sentence, its body unchanged; the checker prints 0 errors
on the fix's install. The fix changes no toolchain, golden or program line; it
is the first of §3 item 6's two fix commits. The records name X25 as W-396's
probe beside ded_holder (D.1, D.3).)

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

Twenty-six `// ---` lines are renamed (52 lines) and one split is added
(`fail_todo_impl_forall_formed_self`, A.1; 53 `// ---` lines changed in all);
each renamed or added split gets one `// TODO:` comment after its `library
"[[@TEST_NAME]]";` line, naming the residue (Appendix A.1 to A.3, verbatim; 27
TODO comments over 45 lines). (amended 2026-11-16, review fold: A-M1 / B3) In
check/testdata/named_constraint/template_constraint_dependent.carbon the split
`fail_dependent_interface_arg_unsatisfied`'s comment line "// TODO: with
TP-1's eager `J(T)`, the impl's `J(V)` is reported too (W-376)." is replaced
by "// Since TP-2 (W-374) `J(T)` is a deferred `call_action`, so `W(D)` is
reported once; the thunk half of W-376 stands." (A.3). No other source line
changes; F1 refills the eleven files (CHECK lines only, §8.2's check).

### §2.4 Programs (C1)

Appendix B's two one-line `// SKIP:` directives, each inserted as line 6
after the program's `// CONFORMANCE-BULLET:` line (ruling 3; B2); EXPECT lines
unchanged; fork/conformance/README.md's
two rows regenerated by `python3 -I -B fork/conformance/runner.py
--update-readme-table` (:361 and :368, `run` to `SKIP`).

### §2.5 Plan and page amendments (P)

Appendix C: C.1 D-TP-11's dated amendment (fork/templates/plan.md, after the
"Round 10" paragraph at :2744, and a line in the decision index at :3455-3458);
C.2 D-SC-19's dated amendment (fork/structural/plan.md, appended to the bullet
that ends at :981 (A-m2), and a sentence after D-SC-6's FO-1 paragraph at :446);
C.3 D-FO1-2 (4)'s dated amendment (fork/followon/fo1-plan.md, after :1091) and
the withdrawal clause's re-read (:1150-1155 gain a dated sentence); C.4 the two
templates.md notes. r31.py counts before and after each file.

### §2.6 Records (R and D)

Appendix D, verbatim with placeholders: D.1 the ledger (W-374 DISCHARGED;
W-139, W-193, W-376 notes; W-396 to W-400 filed); D.2 W-139's note; D.3 the
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
    twenty-six renames with their TODO lines, the pin split and the SC-1 split's
    comment (A.1 to A.3), the two SKIP directives and the README rows (§2.4).
    Gate on C1 alone: `GATE <label>: 2036 passed, 11 failed`, exactly §0.3's
    eleven files, each "Autoupdate would make changes", no prefix problem (the
    renames are in C1) and no crash (measured at the fold on tp2-fixer with the
    TODO lines and the pin in place, §0.3); `runner.py --self-test` green with
    the regenerated table. Message: "TP-2 (1/3): IsCallPerformable defers every
    template-dependent call argument, as upstream's (W-374); twenty-six template
    splits renamed and one added for the forms the deferral loses (W-396 to
    W-398, W-400); two programs SKIP". Its body names upstream's tip at the
    re-fetch and the kept hunk (D-TP2-3).
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
    re-read, dated notes". (Amended 2026-11-16, review fold: RR1-m3,
    implementation re-review: this item's "claim no discharge" and the
    preamble's last sentence reserve the discharge to D, yet D.4's notes and
    D.6's H10.8 row, assigned here, say "W-374 DISCHARGED" and "discharged";
    R, 043978962, wrote them as assigned, true at D's tree, the branch head;
    nothing moves between the commits.)
8.  **D, the discharge**: D.1 (W-374 DISCHARGED; W-396 to W-400 filed; the
    notes), D.2, D.8, and D.3's D-time paragraphs (the §8.7 check on the tree
    at <R>, the id re-scan's `<n>` refs and `<w>` worktrees, the discharge
    line "_Discharged by this commit: W-374 (TP-2)._"); no text R or D names a
    PR number or its own sha; `json.load` of the ledger, `runner.py
    --self-test`, the model-identifier grep of the branch's diff (0), the id
    re-scan (§8.9). Message: "TP-2 discharge: W-374 DISCHARGED; W-396 to W-400
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
| the same | fail_todo_impl_forall_formed_self (added at the fold, A-M1) | TP-1's | STDERR: `` `impl` with unused generic binding [ImplUnusedBinding] `` at `impl forall [template T: type] Box(T) as I`, ``warning: binding `self` unused [UnusedBinding]`` in `Val`, and ``cannot access member of interface `I` in type `Box(i32)` that does not implement that interface [MissingImplInMemberAccess]`` at `h.(I.Val)()` (predicted from the probe a2_impl_self, §0.4) | as predicted (measured at the fold on tp2-fixer) |
| the same | the other 18 splits (of 24 at 701863aa5, 25 with the pin; amended 2026-11-16, review fold: RR1-m2, rev 2 said 19) | TP-1's | SemIR only where a class template type is formed in a template body (`Make`'s `Arr(N)`, `D(N)`, `Box(T)`): `call_action`/`splice_inst` forms; STDERR unchanged (the `fail_` splits keep ``unable to monomorphize``) | as predicted |
| check generic/template/index.carbon | fail_todo_index_class_with_index_with | TP-1's | ``cannot deduce value for generic parameter `T` `` at `return Get(v, 0);` | as predicted |
| check generic/template/match_choice.carbon | fail_todo_designator_arm, fail_todo_designator_arm_exhaustive, fail_todo_value_param, fail_todo_nested_match, fail_todo_guard, fail_todo_int_scrutinee | TP-1's (X-1) | ``semantics TODO: `match on unsupported scrutinee type` [SemanticsTodo]`` at each `match (`; the SemIR dump of the function stops there (fail_todo_int_scrutinee's TODO line also names W-396: `N` is not deduced through `Core.Int(N)`, A-m1, which the body's TODO hides) | as predicted |
| the same | fail_todo_pattern_forms | TP-1's | ``semantics TODO: `refutable pattern binding on unsupported scrutinee type` `` at the first pattern condition | as predicted |
| the same | fail_todo_nonexhaustive, fail_todo_never_matches, fail_todo_int_never_matches, fail_todo_unknown_alternative, fail_todo_guard_on_instantiation, fail_todo_int_literal_out_of_range_on_instantiation, fail_todo_payload_literal_on_instantiation, fail_todo_payload_not_trivial_on_instantiation (the eight renamed from `fail_` at the fold, B3) and fail_todo_qualified_alternative | TP-1's | each specific diagnostic replaced by the scrutinee TODO (one error) | as predicted; re-measured at the fold after the renames (one `SemanticsTodo` CHECK line per split) |
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
| generics/templates_deduce_class_args.carbon | PASS (21 42 3 16 8) | COMPILE-FAIL (``cannot deduce value for generic parameter `T` `` at :62:14 and :63:14, `N` at :65:14) | SKIP (W-396; the directive names :63:14, :64:14 and :66:14, the lines after its insertion) | D-TP2-2; EXPECT kept |
| generics/templates_match_dependent_choice.carbon | PASS (0 1 41 7 5 1 0 1 0 2 1 0) | COMPILE-FAIL (``semantics TODO: `match on unsupported scrutinee type` `` at :46:9) | SKIP (W-397; :47:9 after the insertion) | D-TP2-2; EXPECT kept |
| the other 239 | as the baseline | unchanged | unchanged | the deferral touches no other program's forms (the templates_dependent_* programs form no class type from a template parameter in a parameter type; templates_constraint_lookup's and structural_conformance's calls replay as before) |

Expected and measured (twice: the planner's tp2-planner and the fold's
tp2-fixer): **PASS 226 / FAIL 0 / SKIP 15 over 241; bullets 51 PASS, 0 FAIL, 5
SKIP**. This is the bar for TP-2's landing (ruled 2026-11-16, the orchestrator,
R29, ruling 3: the two SKIPs under R10 are accepted as the cost of R32 (d),
upstream's deferral being the design and the fork's extra deduction a fork
mechanism beyond upstream's text, now withdrawn with W-396 filed and owned by
TP-1's follow-on and the refutable-pattern family as W-397; Appendix F's
land-time texts state the same figures; the gap row stays PARTIAL with its
evidence cell naming the two SKIPs and the residues). _Break condition of the
ruling:_ upstream lands deduction through a dependent class type (deduce.cpp's
TODO at :443 resolved): the SKIPs are lifted at the next advance that brings
it. The bullet "Generics: Integrated templates" stays PASS (runner.py:876-900).
The gap tally stays 37 / 17 / 2 / 0 (the row is PARTIAL before and after).

## §6 Churn and collisions

### §6.1 Churn

call.cpp: 2 insertions, 16 deletions (the function net minus 14 lines). Goldens:
eleven files, 1567 insertions and 2427 deletions (3875 CHECK lines, measured at
the fold with the TODO lines in place, which move the `loc` names; the planner's
renames-only tree had 1419 and 2356), 53 `// ---` lines (twenty-six renames and
one added split), 27 TODO comments over 45 lines, the pin's 18 source lines and
A.3's three. Programs: two one-line `// SKIP:` directives. (amended 2026-11-16,
review fold: B3 / B6) README.md: two rows. Plans and pages: C.1 to C.4. Records:
D.1 to D.8. (Amended 2026-11-16, review fold: A-m2 / B-m5: measured at F1
against 701863aa5, 1567 insertions and 2428 deletions, the one deletion over the
fold's 2427 being the trailing empty line that autoupdate leaves at the end of
toolchain/lower/testdata/template/match_choice.carbon and that prek's
end-of-file-fixer removes; F1 alone 1475 and 2401, the 3875 CHECK lines and that
line.)

### §6.2 Collisions and the merge rules

PR 53 (§0.7): four records files, resolved by the records rule; nothing in
toolchain or testdata. UA-3: `IsCallPerformable` merges as upstream's own
4286832b4 hunk once TP-2 lands (the fork's text equals upstream's but for the
argument), and 62f1cc6a3's rename of `GenericClassType` no longer meets a fork
use in call.cpp's function; the twenty-six renamed splits, the pin and the two
SKIPs are fork files upstream never had. A later fork change that restores any
lost form takes the residue's break condition as its gate.

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
5.  The item's break condition fired by its letter on destroy_calls.carbon and
    the orchestrator ruled that the removal proceeds (D-TP2-4; resolved
    2026-11-16). The risk now is the ruling's own break condition: a changed
    split with no template parameter, or a changed CHECK line of a
    non-template split in any refilled file. _Falsifier:_ such a line in F1's
    diff. Response: STOP and report.

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

In the background (9 to 12 minutes; check for another build first and wait for
it), then the install with the same variables. Every arbiter command of this
section sits in a guarded block (amended 2026-11-16, review fold: A-M2 / B1;
ruling 2), so that no prek hook rewrites the arbiter's variable names (ruling 2
names four: paths.sh's repository variable, which the Google-doc-style hook
expands to a long word, the label, the cache home and the conformance output):
rev 1's prose spans had been rewritten by the Google-doc-style hook to a long
word that paths.sh ignores, so a copy of them would have built and refilled
paths.sh's default tree (R20).

<!-- google-doc-style-ignore -->

```text
pgrep -fa 'ninja -C|file_test|runner.py'
REPO=/home/user/carbon-tp2 SHA=tp2-impl /home/user/arb/carbonbuild/build.sh
REPO=/home/user/carbon-tp2 SHA=tp2-impl python3 -I /home/user/arb/carbonbuild/install.py
```

<!-- google-doc-style-resume -->

The build log's first line echoes the variables as paths.sh received them
(`=== build.sh <time>` followed by the repository path and the label): check it
before the wait.
The log must show no warning in call.cpp.

### §8.2 Autoupdate to its fixpoint

Twice: pass 1 "11 file(s) changed", pass 2 "0 file(s) changed"; then the
CHECK-only check, which must print nothing (the second command):

<!-- google-doc-style-ignore -->

```text
REPO=/home/user/carbon-tp2 SHA=tp2-impl /home/user/arb/carbonbuild/autoupdate.sh --threads 4
git diff -U0 F1^ F1 -- toolchain | grep '^[-+]' | grep -vE '^[-+]{3} |^[-+]\s*// CHECK'
```

<!-- google-doc-style-resume -->

(Amended 2026-11-16, review fold: A-m2 / B-m5: at F1, 6adeedc41, the second
command prints one line, `-`, the trailing empty line autoupdate leaves at the
end of toolchain/lower/testdata/template/match_choice.carbon, whose last split
`fail_todo_int_scrutinee` now lowers nothing, and which prek's
end-of-file-fixer, run before each commit as §3 requires, removes; no CHECK
line. A fresh autoupdate of C1's eleven goldens re-adds the line as its only
difference from F1, a second pass changes nothing, and autoupdate on the
committed head is a no-op, so the fixpoint holds either way and the gate passes;
prek wins over the empty line, no golden of the tree's 2021 ending in a blank
line (review B's count).)

### §8.3 Gate

On C1 alone `2036 passed, 11 failed`, the eleven files, no prefix problem
(measured at the fold with the TODO lines and the pin, §0.3); after F1
`[  PASSED  ] 2047 tests.`, `GATE tp2-impl: 2047 passed, 0 failed`. The
expected count is 2047 (no golden file added; the pin is a split of an existing
one).

<!-- google-doc-style-ignore -->

```text
REPO=/home/user/carbon-tp2 SHA=tp2-impl /home/user/arb/carbonbuild/gate.sh --threads 4
```

<!-- google-doc-style-resume -->

### §8.4 Conformance

Twice: once before the SKIP lines go in (conformance reads the install and the
programs, so the call.cpp change alone gives the 226/2/13 line; B9) and once
on the final tree (the 226/0/15 line of §5), the first run's CONFORMANCE.txt
and log copied under their own names before the second (the fold's are
conformance-tp2-fixer-noskip.txt and .log under /home/user/arb/logs); wait for
the marker with `until` loops of at most nine minutes; `runner.py --self-test`
green (the README table regenerated in C1):

<!-- google-doc-style-ignore -->

```text
REPO=/home/user/carbon-tp2 SHA=tp2-impl CACHE_HOME=/home/user/arb/cache-tp2-impl /home/user/arb/carbonbuild/conformance.sh --background
until [ -f /home/user/arb/conformance/tp2-impl/.done ]; do sleep 20; done
cp /home/user/arb/conformance/tp2-impl/CONFORMANCE.txt /home/user/arb/logs/conformance-tp2-impl-noskip.txt
python3 -I -B fork/conformance/runner.py --self-test
```

<!-- google-doc-style-resume -->

### §8.5 The detectors of D-TP2-1 and D-TP2-3 (the reviewers re-run them)

m17n_d rejected with the nightly's two notes (D-TP2-1); `fail_todo_holder`, the
other twenty-five renamed splits and the pin split
`fail_todo_impl_forall_formed_self` keep their prefixes under the gate (on
tp2-base, whose answers M1 reproduces to the letter, the pin's source runs:
a2_impl_self prints 11, so M1 fails the pin's prefix rule too); e1 and e2
rejected in `F(D)` (D-TP2-3); M1 and M2 as §0.5 if a fix touches call.cpp or
convert.cpp (the implementer re-runs M2's probes on its own build; a reviewer
builds M1 on its own label).

### §8.6 prek, R27 and R31 (every commit)

To a fixpoint; the cache directory deleted by its literal path at the end;
r31.py before and after each markdown edit, counts in the message. R27: the
renamed splits are diffed against this plan's Appendix A spelling. After prek,
the plan's commands grep clean of hook rewrites: the third command below
prints 0 (ruling 2; its pattern is bracketed so that the check does not match
itself; 0 at rev 2).

<!-- google-doc-style-ignore -->

```text
SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest XDG_CACHE_HOME=<scratch>/xdg uvx prek run --files <paths>
python3 -I <scratch>/sv1-fixer5/bin/r31.py <file>
grep -c 'Reposit[o]ry=' fork/templates/tp2-plan.md
```

<!-- google-doc-style-resume -->

### §8.7 The function-equals-upstream check (at C1, at D, at L)

`diff <(git -C /home/user/carbon-lang show
upstream/trunk:toolchain/check/call.cpp | sed -n 449,464p) <(sed -n 1023,1038p
toolchain/check/call.cpp)` prints exactly the two lines that differ in
`context.sem_ir()` and nothing else (line numbers re-derived if trunk's file
moved); `git grep -c -w forms_type -- toolchain` prints no match and exits 1
(amended 2026-11-16, review fold: A-m3: rev 3 said "is 0", the substance; no
file matches, so no count line is printed).

### §8.8 The register checkers (at R)

`fork/register/check_greps.sh /home/user/carbon-lang <tip>
fork/register/rg1-checks.tsv` and `check_quotes.sh` with the five new quote
rows: 0 FAIL rows.

### §8.9 The id re-scan (before D)

§0.9's script over every ref and worktree after a fetch; W-396 to W-400 unused
elsewhere; the counts written into D.3.

### §8.10 Not run, and why

§0.10's list.

## Hand-off notes for the implementer

1.  Read W-374 in the ledger, D-TP-11 (fork/templates/plan.md:2703-2744),
    D-SC-19 (fork/structural/plan.md:946-980), D-FO1-2 (4) (fo1-plan.md
    :1060-1091 and :1150-1155) and this plan's §0.2 to §0.5 before C1; the hunk
    in convert.cpp is kept on purpose (D-TP2-3).
2.  C1 is §2.1's diff plus Appendix A's source edits and Appendix B's two
    directives; copy them verbatim (R27), then `runner.py
    --update-readme-table`.
3.  Build in the background with a 7200000 ms timeout and poll with `until`
    loops, with §8.1's command block copied from its guarded text (the variable
    spelled as paths.sh reads it, never the hook's long word: ruling 2, B1); a
    gate or conformance run may overlap another agent's, a build may not (a
    `nice`d LLVM build of ARB-4 excepted; amended 2026-11-16, review fold: B-m6:
    the implementer's and the fixer's task rule names it as one not to wait for,
    and it ran throughout both builds, each 428 steps, status 0, no warning).
4.  F1 is autoupdate's output only; if pass 2 changes a file, stop (§7.1 risk
    1).
5.  P copies Appendix C verbatim; run r31.py on each file before and after.
6.  R and D copy Appendix D with the placeholders filled from the commits and
    runs they name; D's own sha is "this commit".
7.  Delete the label's four directories and the XDG cache by their literal
    paths when done; keep tp2-base.
8.  Re-create §0.4's probes from Appendix A.4 and keep their outputs in your
    scratch for the reviewers (the fold's are under scratchpad/tp2/fixer/out
    and, for the rev 3 twin, scratchpad/tp2/fixer1/out).
9.  Run conformance once before the SKIP lines go in and keep that run's
    CONFORMANCE.txt and log under their own names (§8.4; B9).

## Review fold record (rev 2, 2026-11-16)

Reviews A (APPROVE-WITH-AMENDMENTS: A-M1, A-M2, A-m1 to A-m4) and B (REJECT:
B1 BLOCKER, B2 to B4 MAJOR, B5 to B9 MINOR) on rev 1 (9f09c347b), folded
under the orchestrator's rulings of 2026-11-16 (R29; seven rulings, each
quoted where it applies as "(ruled 2026-11-16, the orchestrator, R29: ...)"
with the superseded text). Every measured finding was reproduced at the fold:
the detached worktree /home/user/carbon-tp2-fixer (701863aa5 plus C1's exact
shape: §2.1's diff, the twenty-six renames and their TODO lines, A.3's line,
the pin split, the hunk kept) built by the arbiter under the label tp2-fixer
(build 17:12 to 17:19 UTC, 428 steps, no warning; gate 2036/11 before the
fill, autoupdate 11 files then 0, gate 2047/0 after; conformance 226/2/13
before the SKIP lines and 226/0/15 with them, both kept under
/home/user/arb/logs; `runner.py --self-test` OK; the probes of A.4 on tp2-base,
tp2-fixer and the nightly, outputs under scratchpad/tp2/fixer/out); the
worktree and the label's four directories were removed when this revision was
committed, tp2-base kept. Nothing is rejected. Where A and B disagree the plan
says which is right: A-m3's substance reading and B4's STOP are both replaced
by ruling 1 (the ruling is the record); B7's labels ":308-310" and ":207-209"
are themselves off by one against the tip's text and the plan records the
measured lines. No finding proposed a fork helper for `Holder(T)`, so ruling
6's rejection clause had nothing to reject; its amendment of W-374's note and
H9.8's re-read are in D-TP2-3, D.1 and D.6.

| Finding | Disposition | Where |
| --- | --- | --- |
| B1 (BLOCKER) and A-M2 (MAJOR): the arbiter commands rewritten by the doc-style hook | FOLDED per ruling 2: every arbiter command of §3, §8 and the hand-off is in a guarded code block; the grep check recorded in §8.6 (its pattern bracketed so that it does not match itself); 0 at rev 2 | §8.1 to §8.4, §8.6, hand-off item 3 |
| B2 (MAJOR): multi-line SKIP blocks recorded as their first line | FOLDED per ruling 3: one `// SKIP:` line each in the runner's recorded form, post-insertion lines :63:14, :64:14, :66:14 and :47:9; the self-test's marks quoted; conformance re-run 226/0/15 | §0.6, D-TP2-5, §2.4, §5, Appendix B |
| B3 (MAJOR): eight `fail_` splits that now pin a TODO | FOLDED per ruling 4: renamed `fail_todo_` with a W-397 TODO line each; measured (gate 2047/0; one `SemanticsTodo` CHECK line per split); every count updated | §0.3, D-TP2-7, §2.3, §4, §6.1, §8.5, A.2, D.1 (W-397) |
| B4 (MAJOR): D-TP2-4 re-read the break condition to avoid a STOP | FOLDED per ruling 1: fired by the letter; §0.3's table the report; the ruling that the removal proceeds; the amended letter; the ruling's break condition; the substance reading dropped as the plan's justification | Status, §0.3's table, D-TP2-4, §7.1 item 5, D.1, D.3, Appendix E |
| B5 (MINOR): nineteen prefix problems in six files | FOLDED: the planner's log re-read at the fold (19 unique problems; the nineteenth the SC-1 split that decides D-TP2-3) | §0.3 |
| B6 (MINOR): Appendix A's TODO lines never built | FOLDED: measured at the fold (27 TODO comments over 45 lines; the C1 gate shape with them 2036/11; the `loc` names move and the numstat grows) | §0.3, §0.10, §6.1 |
| B7 (MINOR) and A-m2 (MINOR): line labels | FOLDED: re-anchored at 7a3608bab (:263-268, :308-311, :102-108, :205-209 and :208-209; :981; :240); the re-scan's file list completed | §0.8, §0.9, §2.5, C.2, C.4, D.3 |
| B8 (MINOR): the TP-1 entry's 2026-11-16 paragraph | FOLDED: the same "Resolved by TP-2" sentence after its "Veto-able." | D.4 |
| B9 (MINOR): the first conformance run's evidence | FOLDED per ruling 5: re-run on tp2-fixer before the SKIP edit (226/2/13, runner exit 1), kept as conformance-tp2-fixer-noskip.txt and .log; the implementer repeats it | §0.6, §0.10, §8.4, hand-off item 9 |
| A-M1 (MAJOR): `impl forall` with a formed self or interface is lost | FOLDED per ruling 7: the cost recorded as W-400 (the re-scan's next free id), the three probes in A.4 and §0.4's table, D-TP2-1's falsifier rewritten, the pin split `fail_todo_impl_forall_formed_self` adopted in C1 and filled at the fold | §0.4, §0.9, D-TP2-1, D-TP2-2, D-TP2-8, §4, A.1, A.4, C.1, C.4, D.1, D.3, D.6, D.7, E, F |
| A-m1 (MINOR): `Core.Int(N)` is a W-396 form | FOLDED: W-396's title and evidence, the int_scrutinee TODO lines (check and lower) and the probe a5_core_int | §0.4, D-TP2-2, D-TP2-8, §4, A.2, A.4, D.1 |
| A-m3 (MINOR): record the substance ruling | ANSWERED by ruling 1: the record is the orchestrator's ruling, not the substance reading; A's measurement (every hunk of the fill after :1017) is kept as evidence | D-TP2-4, §0.3 |
| A-m4 (MINOR): FO-1's declact pair | FOLDED: re-created and run at the fold (declact prints 6; declactd `Caller(D)` with the same notes on tp2-base and tp2-fixer); sources in A.4 | §0.4, §0.10, A.4 |

## Review fold record (rev 3, 2026-11-16)

The focused re-review RR1 of rev 2 (b87751859; APPROVE-WITH-AMENDMENTS: no
BLOCKER, no MAJOR, three MINORs, each a plan-text correction; its own prototype
`tp2-rr1`, a detached worktree at 701863aa5 plus rev 2's prototype diff, whose
119 non-CHECK lines equal Appendix A and B verbatim, reproduced rev 2's figures:
gate 2047 passed, 0 failed, autoupdate 0 changed, §8.7's diff the two `sem_ir()`
lines only, `forms_type` 0, conformance 226/0/15 over 241 with 51 of 56 bullets
and 226/2/13 with the SKIP lines reverted, the 36 probes of A.4 on tp2-base,
tp2-rr1 and the nightly reproducing every §0.4 row but ded_checked_twin's, W-400
free across 969 refs, 745 heads and 11 worktrees, check_quotes 0 failed on D.6's
five rows and check_greps 96/0 at 7a3608bab, merge-tree 4 record conflicts) is
folded above, each amendment marked "(amended 2026-11-16, review fold:
RR1-<id>)". Every measurement a finding rests on was re-measured by this fold
(scratchpad/tp2/fixer1 of this session, not in the repository): the split counts
at 701863aa5 (`grep -c '^// --- '`: deduce_class_args 24, index 22, pointer 11,
match_choice 24, template_constraint_dependent 8 and lower's match_choice 4, 93
in all; the four `fail_todo_scrutinee_*` splits at match_choice.carbon:512,
:531, :561 and :586; `grep -rh '^// --- fail_'` over check/testdata and
lower/testdata 2418 and `'^// --- todo_'` 45, `todo_fail_private_on_redecl` and
`todo_fail_alias_two_file` among them); call.cpp:1023-1052 (the comment at
:1023-1024, `return true;` at :1051, the brace at :1052);
fork/templates/plan.md:3341 (§1.13 item 26 is W-295), :2730-2744 (D-TP-11's
Round 10 paragraph) and :10318 (the round-10 row with ``match on unsupported
scrutinee type`` at the scrutinee for 24); fork/decision-log.md:7005-7021 (:7022
blank) and :20002-20033 (the paragraph ends "(a) and veto-able.");
fo1-plan.md:574-578; and the twin probes on the three toolchains, the prototype
being the detached worktree /home/user/carbon-tp2-fixer1 at 701863aa5 plus rev
2's prototype diff, built by the arbiter under the label tp2-fixer1 (build 18:24
to 18:31 UTC, 428 steps, no warning; gate 2047 passed, 0 failed; autoupdate 0
changed; conformance PASS 226 / FAIL 0 / SKIP 15 over 241 programs, bullets 51
PASS, 0 FAIL, 5 SKIP of 56, runner exit 0, under its own cache): the planner's
`[T: type]`, `-> T` twin rejected ``cannot copy value of type `T` `` on
tp2-base, tp2-fixer1 and the nightly, A.4's new `[T: type]`, `-> i32` twin and
rev 2's `[T: Core.Copy]`, `-> T` text both printing 42 on the three
(scratchpad/tp2/fixer1/out and out_t). The worktree and the label's four
directories were removed when this revision was committed, tp2-base kept.
Nothing is rejected; no finding touches a decision, a code line, a golden, a
program or a page text, so rev 2's prototype figures stand, re-measured by the
re-review's tp2-rr1 and this fold's tp2-fixer1.

| Finding | Disposition | Where |
| --- | --- | --- |
| RR1-m1 (MINOR): §0.4's ded_checked_twin row was never measured as stated (the planner's scratch twin was rejected on all three toolchains) | FOLDED: the row re-measured with the `[T: type]`, `-> i32` twin (prints 42 on tp2-base, tp2-fixer1 and the nightly) and A.4's twin swapped; the planner's rejected `-> T` form and rev 2's `[T: Core.Copy]` text recorded with their measured answers in the paragraph after the table; D-TP2-2's reading unchanged | §0.4 (the row and the paragraph after its table), A.4, hand-off item 8 |
| RR1-m2 (MINOR): seven split counts off against the goldens at 701863aa5 | FOLDED: 18, 21, 10, 93, four, 2418 and 45, each re-counted at the fold and marked with rev 2's figure | §0.3, §0.4 (five places), §4 |
| RR1-m3 (MINOR): five line and item cites slip | FOLDED: call.cpp:1023-1052; W-397's evidence points at D-TP-11's Round 10 paragraph (:2730-2744) and the round-10 row (:10318) instead of §1.13 item 26 (W-295); :7005-7021; :20002-20033; fo1-plan.md:574-578 | §0.2, D.1 (W-397's evidence), D.4, §0.4 |

## Sign-off

Every review of this plan, with its verdict and its counts (added 2026-11-16,
review fold: RR1):

| Review | Read | Verdict | BLOCKER | MAJOR | MINOR | Folded | Rejected | Fold |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| A: toolchain root causes, design soundness and upstream fidelity | rev 1, 9f09c347b | APPROVE-WITH-AMENDMENTS | 0 | 2 | 4 | 6 (A-M2 with B1; A-m3 answered by ruling 1) | none | rev 2, "Review fold record (rev 2, 2026-11-16)" |
| B: concreteness, process, Goodhart, scope honesty and cross-workstream consistency | rev 1, 9f09c347b | REJECT | 1 | 3 | 5 | 9 (B4 per ruling 1, B1 per ruling 2, B2 per ruling 3, B3 per ruling 4, B9 per ruling 5) | none | rev 2, the same |
| RR1: the focused re-review | rev 2, b87751859 | APPROVE-WITH-AMENDMENTS | 0 | 0 | 3 | 3 | none | rev 3, "Review fold record (rev 3, 2026-11-16)" |

Rev 3 is SIGNED OFF FOR IMPLEMENTATION: the last review's verdict is
APPROVE-WITH-AMENDMENTS, not REJECT; every finding of the three reviews is
folded, under the orchestrator's seven rulings of 2026-11-16 (R29) where they
apply, and none rejected; rev 3 changes no decision, code line, golden,
program or page text (its amendments are a probe's form, seven counts and five
cites), so rev 2's container figures stand (gate 2047 passed, 0 failed;
conformance PASS 226 / FAIL 0 / SKIP 15 over 241, 51 of 56 bullets, the
landing bar of D-TP2-5's ruling; re-measured by the re-review's tp2-rr1 and
this fold's tp2-fixer1 prototypes). The implementation starts from this
plan's commit with §3's C1.

## Appendix A: the goldens' source edits and the probes

### A.1 check/testdata/generic/template/deduce_class_args.carbon

Six `// ---` lines change and one split is added (A-M1's pin, placed before the
file's `// CHECK:STDOUT:` trailer, after `class_template_field_of_where_alias`);
each renamed or added split gets the TODO line shown after its `library` line.
Verbatim:

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

// --- fail_todo_impl_forall_formed_self.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `Box(T)` in the impl's self is a deferred
// `call_action`, so the template binding is reported unused and the impl is
// not found for `Box(i32)` (fork work item W-400).

class Box(T: type) {
  var item: T;
}

interface I {
  fn Val(self) -> i32;
}

impl forall [template T: type] Box(T) as I {
  fn Val(self) -> i32 { return 11; }
}

fn Use(h: Box(i32)) -> i32 {
  return h.(I.Val)();
}
```

<!-- google-doc-style-resume -->

The splits' Carbon code is unchanged: `holder` is `class Holder(T: type) { var
item: T; }`, `fn GetTemplate[template T: type](h: Holder(T)) -> T { return
h.item; }`, `fn Use(h: Holder(i32)) -> i32 { return GetTemplate(h); }` (the
`//@dump-sem-ir-begin` markers around `GetTemplate`); the unknown-field split
is `class Arr(template N: i32) { var a: array(i32, N); var n: i32; }`, `fn
Make(template N: i32) -> i32 { var c: Arr(N) = {.a = (1, 2, 3), .m = N};
return c.n; }`. The pin split's source is new, the probe a2_impl_self's form in
the golden's style; its filled CHECK lines are §0.3's (amended 2026-11-16,
review fold: A-M1).

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
// TODO: as fail_todo_designator_arm, for `Core.Int(N)` (W-397); `N` is
// not deduced through `Core.Int(N)` either (W-396), which the body's TODO
// hides.

// --- fail_todo_unknown_alternative.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) the scrutinee TODO replaces the diagnostic this
// split pinned (fork work item W-397).

// --- fail_todo_nonexhaustive.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_unknown_alternative (W-397).

// --- fail_todo_never_matches.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_unknown_alternative (W-397).

// --- fail_todo_int_never_matches.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_unknown_alternative, for `Core.Int(N)` (W-397).

// --- fail_todo_int_literal_out_of_range_on_instantiation.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_unknown_alternative, for `Core.Int(N)` (W-397).

// --- fail_todo_payload_literal_on_instantiation.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_unknown_alternative (W-397).

// --- fail_todo_guard_on_instantiation.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_unknown_alternative (W-397).

// --- fail_todo_payload_not_trivial_on_instantiation.carbon
library "[[@TEST_NAME]]";
// TODO: as fail_todo_unknown_alternative (W-397).
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
// TODO: as fail_todo_designator_arm, for `Core.Int(N)` (W-397); `N` is
// not deduced through `Core.Int(N)` either (W-396), which the body's TODO
// hides.
```

```text
// --- todo_fail_deref_class_type_param.carbon
library "[[@TEST_NAME]]";
// TODO: since TP-2 (W-374) `C(T)` is a deferred `call_action`, so `*c` is a
// deferred dereference that only an instantiation diagnoses, and this split
// makes none (fork work item W-398).
```

<!-- google-doc-style-resume -->

The four blocks are, in order, index.carbon, the check match_choice.carbon
(fifteen splits: the seven that start failing and the eight renamed from
`fail_` to `fail_todo_` because the scrutinee TODO replaced the diagnostic each
name promised, B3, ruling 4; `fail_todo_qualified_alternative` was already so
named), the lower match_choice.carbon (three) and pointer.carbon. In the check
and lower match_choice.carbon the `class_template_choice` split keeps its name.
(Amended 2026-11-16, review fold: A-m1 / B3: rev 1's "The nine `fail_` splits
of match_choice.carbon whose diagnostic changes keep their names (they still
fail)" is superseded; the two int_scrutinee TODO lines name W-396 too.)

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
// ded_checked_twin (amended 2026-11-16, review fold: RR1-m1; was `[T: Core.Copy]`, `-> T`)
fn GetChecked[T: type](h: Box(T)) -> i32 { return 42; }
fn Run() -> i32 { var h: Box(i32) = {.item = 42}; Core.Print(GetChecked(h)); return 0; }
// ded_explicit
fn GetExplicit(template T: type, h: Box(T)) -> T { return h.item; }
fn Run() -> i32 { var h: Box(i32) = {.item = 42}; Core.Print(GetExplicit(i32, h)); return 0; }
```

Review A's probes (A-M1, A-m1, A-m4; §0.4's last table; added at the fold).
a2_impl_self and a3_impl_iface share the deduction probes' `Box`, `Vec` and
`TBox` lines; a8_require and the declact pair share the structural prefix:

```carbon
// a2_impl_self
interface I { fn Val(self) -> i32; }
impl forall [template T: type] Box(T) as I { fn Val(self) -> i32 { return 11; } }
fn Run() -> i32 { var h: Box(i32) = {.item = 1}; Core.Print(h.(I.Val)()); return 0; }
// a3_impl_iface
interface J(T: type) { fn Val(self) -> i32; }
class W {}
impl forall [template T: type] W as J(T) { fn Val(self) -> i32 { return 13; } }
fn Run() -> i32 { var w: W = {}; Core.Print(w.(J(i32).Val)()); return 0; }
// a5_core_int (the `import` line only)
fn Bits[template N: Core.IntLiteral](x: Core.Int(N)) -> i32 { return 1; }
fn Run() -> i32 { var x: i64 = 3; Core.Print(Bits(x)); return 0; }
// a8_require
interface I { require impls HasGet; fn Val(self) -> i32; }
impl forall [template T: type] Holder(T) as I { fn Val(self) -> i32 { return self.x; } }
fn Run() -> i32 { var h: Holder(C) = {.x = 8}; Core.Print(h.(I.Val)()); return 0; }
// declact (declactd with `d` and `return Caller(d);`)
fn Wrap(template F: type, template T: F) -> Holder(T) { return {.x = 6}; }
fn Caller[U: type](x: U) -> i32 { var h: Holder(U) = Wrap(type, U); return h.x; }
fn Run() -> i32 { var c: C = {}; Core.Print(Caller(c)); return 0; }
```

<!-- google-doc-style-resume -->

## Appendix B: the programs and their EXPECTs

### B.1 generics/templates_deduce_class_args.carbon

Inserted after `// CONFORMANCE-BULLET: Generics: Integrated templates`:

<!-- google-doc-style-ignore -->

```text
// SKIP: deduction through a class's arguments is withdrawn by TP-2 (fork work item W-396; fork/templates/tp2-plan.md D-TP2-2): with `IsCallPerformable` upstream's, `Holder(T)` in a parameter's type is a deferred `call_action`, and this file fails to compile with `error: cannot deduce value for generic parameter `T`` at `Core.Print(Get(h));` (:63:14) and at `Core.Print(GetThrough(&h) * 2);` (:64:14) and `error: cannot deduce value for generic parameter `N`` at `Core.Print(Size(v));` (:66:14), as on the upstream nightly 2026.10.12 (verified on the container arbiter's install of TP-2's prototype). Un-SKIP when W-396's break condition fires: upstream's deduce.cpp deduces a template parameter through a template-dependent splice, or the nightly runs this program.
```

<!-- google-doc-style-resume -->

One line, inserted as line 6 (ruling 3; amended 2026-11-16, review fold: B2:
rev 1's eleven-line block was recorded by runner.py:263-265 as its first line
only and named the pre-insertion lines); the line numbers are the file's after
the insertion (:62, :63 and :65 before it, the lines the runner logged); the
EXPECT lines (21, 42, 3, 16, 8) and the body are unchanged. The runner records
the whole line as the skip_reason (`runner.py --self-test`'s marks, §0.6).
EXPECT re-derived (R16 (d)): `Get(h)` returns the item 21; `GetThrough(&h)`
reads 21 through the pointer, doubled 42; `Size(v)` is `Vec(3)`'s `N`, 3;
`SumArr(3, 10)` is 10 + 3 + 3, 16; `MakeArr(3)` returns `{.a = (4, 5, 6), .n =
3}`, whose second element plus `n` is 8. The first three would print only with
W-396 removed; the program is one unit, so it is SKIPped whole.

### B.2 generics/templates_match_dependent_choice.carbon

Inserted the same way:

<!-- google-doc-style-ignore -->

```text
// SKIP: refutable patterns on a template-dependent choice value are withdrawn by TP-2 (fork work item W-397; fork/templates/tp2-plan.md D-TP2-2): with `IsCallPerformable` upstream's, `Opt(T)` is a deferred `call_action` and the scrutinee's type is a splice, so this file fails to compile with `error: semantics TODO: `match on unsupported scrutinee type`` at `match (s) {` in `Count` (:47:9) and at every other `match` here, as trunk did before TP-1's round 10 (X-1) and as the upstream nightly 2026.10.12 reports a TODO (verified on the container arbiter's install of TP-2's prototype). Un-SKIP when W-397's break condition fires: upstream's `match` accepts a scrutinee whose type is a template-dependent splice, or the nightly runs this program.
```

<!-- google-doc-style-resume -->

One line, inserted as line 6 (the `match (s)` of `Count` is :47:9 after it,
:46:9 before; B2). EXPECT (0 1 41 7 5 1 0 1 0 2 1 0) unchanged, re-derived from
the program's own header: `Count` of a `None` 0 and of a `Some` 1; `Unwrap` 41
and the default 7; `Width` 5, 1, 0; `Box(i32).Fill` 1 and `Box(i64).Fill` 0;
`Small` 2, 1, 0.

(Amended 2026-11-16, review fold: B-m4: compiled with the branch's install, the
file reports one error, at the first `match` (:47:9), and stops, so the
directive's "and at every other `match` here" names the forms the deferral
loses, not the measured count; the line is the program's text and stands as
inserted, no program line being spent on a phrase (ruling 3; the fixer's
decision 5), and W-397's ledger entry and the decision-log entry "TP-2" describe
the measured output.)

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
proposal 2200 (:205-209) leave type checking of anything dependent on a
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
made on instantiation only, are W-398; an `impl forall` with a template binding
whose self or interface is formed from it is rejected as on the nightly, W-400
(the split `fail_todo_impl_forall_formed_self`). The deduce_class_args.carbon
forms that
TP-1 measured on v13 (holder 42, holder_copy_constraint 7, template_class_type
9, holder_pointer 5, vec_value_param 3) are then the nightly's ``cannot deduce
value for generic parameter`` on the fork too; `class_argument_expression` and
`class_argument_return_type` (explicit `N`) still run. The break condition
above fired as FO-1's m17n_d (an interface constraint converted at the
definition and never checked again); TP-2's D-TP2-1 carries the new one.
```

<!-- google-doc-style-resume -->

In the decision index (:3455-3458) the D-TP-11 item gains: " SUPERSEDED by
TP-2 (<date>): the call is deferred as upstream's is; W-396 to W-398 and W-400
carry the forms (fork/templates/tp2-plan.md D-TP2-1, D-TP2-2)."

### C.2 fork/structural/plan.md: D-SC-19 (appended to the bullet that ends at :981) and D-SC-6's FO-1 paragraph (:446)

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
or are compiled wrongly." (:240; A-m2), a new blockquote paragraph:

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
> TODO below again (W-397). An `impl forall` with a template binding whose
> self or interface is formed from it (`impl forall [template T: type] Box(T)
> as I`) is rejected, as on the nightly (W-400).
```

<!-- google-doc-style-resume -->

The W-193 bullet (:578-582) gains, after "(Resolved by TP-1, 2026-11-02, as
the fork note there says.)": " (Withdrawn by TP-2, <date>, W-396: see the TP-2
fork note there.)"

The TP-1 fork note's blockquote (:169-172, "**Fork note (TP-1, 2026-11-02).**
The deduction is implemented: ...") gains a third paragraph, so that the W-193
bullet's "see the TP-2 fork note there" names a note its section has (amended
2026-11-16, fix 1: A-M1 / B-M1; D-TP2-10):

<!-- google-doc-style-ignore -->

```markdown
>
> **Fork note (TP-2, 2026-11-16).** The deduction is withdrawn again (fork
> work item W-396): since TP-2 the toolchain defers every call whose callee or
> argument depends on a template parameter, as upstream's does, so
> `GetTemplate(h)` is rejected again with
> ``cannot deduce value for generic parameter `T` ``, as on upstream's nightly,
> while `GetChecked(h)` still deduces `T` as `i32`; the `Holder(T)*` and
> `Vec(N)` forms are withdrawn the same way. See the TP-2 fork note in
> [Templates in the 0.1 toolchain](#templates-in-the-01-toolchain).
```

<!-- google-doc-style-resume -->

The quote fixture of that section,
fork/designdocs/samples/X25_template_deduce_class_arg.carbon (TP-1's pin of
W-193's resolution, EXPECT-STDOUT 42), is re-pinned on the TP-2 behaviour, its
body unchanged (the first error is at `GetTemplate(h)`, :34:30; amended
2026-11-16, review fold: the fixer's erratum, R10: fix 1's message and this
appendix at fix 1 said :33:30, measured on the pre-splice file, the re-written
header being one line longer than the old) and its comment rewritten; the three
directive lines of its header:

<!-- google-doc-style-ignore -->

```text
// DESIGN-DOCS-SAMPLE: docs/design/templates.md, "Functions with template parameters", quote
// EXPECT-ERROR: cannot deduce value for generic parameter `T`
// QUOTE: `GetTemplate(h)` is rejected again with ``cannot deduce value for generic parameter `T` ``
```

<!-- google-doc-style-resume -->

`python3 -I fork/designdocs/check_samples.py --toolchain <install>/bin/carbon`
prints 0 errors on the fix's install, tp2-fix (one error, X25's compile
failure, on C1+F1 and on P; 0 on tp2-base: the finding).

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
226/0/15 over 241, 51/56 bullets. The break condition "the removal changes a
golden outside TP-1's and SC-1's template goldens (then STOP and report)"
FIRED by its letter on toolchain/check/testdata/class/destroy_calls.carbon
(the split `generic_use_inside_template`, D-TP-11's own refill, TP-1 §1.6;
SemIR only, no diagnostic; the report is fork/templates/tp2-plan.md §0.3's
table); the orchestrator ruled on 2026-11-16 (R29; TP-2 D-TP2-4) that the
removal proceeds and amended the letter: a template golden is a golden whose
changed split uses a template parameter, wherever the file lives, and the
condition stays STOP for any changed split that uses no template. W-139's
convert.cpp requirement is NOT withdrawn, contrary to this note's 'Removal'
sentence (D-TP2-3, measured: e1 and e2, a conversion of a template-dependent
self outside a call, run with rc 1 and 3 without the hunk; the replay checks a
call's argument only, with `delayed_action_depth` positive, so the requirement
is kept for a conversion outside a call and H9.8's third clause is re-read,
TP-2 D.6). The forms the deferral loses are W-396, W-397, W-398 and W-400;
W-399 is the interface analogue of a conversion outside a call. Break
condition of the discharge: D-TP2-1's." (The W-374 sentences on the break
condition and the hunk: amended 2026-11-16, review fold: B4, rulings 1 and 6.)

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
  "title": "TP-2 residue (D-TP2-2; W-193's forms re-opened): a deduced template parameter is not deduced through a class type formed from it (`Holder(T)`, `Holder(T)*`, `Vec(N)`, `TBox(T)` for `class TBox(template T: type)`, and `Core.Int(N)` for a template `N`), because the type-forming call is deferred and deduction has no case for a template-dependent splice",
  "subsystem": "toolchain/check (deduce.cpp, call.cpp `IsCallPerformable`)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
    "toolchain/check/testdata/generic/template/deduce_class_args.carbon: fail_todo_holder, fail_todo_holder_copy_constraint, fail_todo_holder_pointer, fail_todo_vec_value_param, fail_todo_template_class_type (<F1>); index.carbon: fail_todo_index_class_with_index_with; match_choice.carbon (check and lower): fail_todo_int_scrutinee, whose body's TODO hides the deduction loss through `Core.Int(N)`",
    "fork/conformance/programs/generics/templates_deduce_class_args.carbon (SKIP at <C1>)",
    "fork/designdocs/samples/X25_template_deduce_class_arg.carbon (TP-1's quote fixture of docs/design/templates.md's TP-1 fork note, re-pinned at TP-2's fix 1 as an EXPECT-ERROR fixture: ``cannot deduce value for generic parameter `T` `` at `GetTemplate(h)`, :34:30, on the branch's install, where `GetChecked(h)` still deduces; it compiles on tp2-base, whose checker then reports the expected error as missing; amended 2026-11-16, review fold: A-M1 / B-M1)",
    "upstream toolchain/check/deduce.cpp:443 at 7a3608bab, `// TODO: Handle more cases.`, and the `default:` arm's `deduce_through()` test (:446-456): no case reads through a `SpliceInst`; the nightly 2026.10.12 reports ``cannot deduce value for generic parameter `T` `` for the probe ded_holder and ``... `N` `` for a5_core_int, `fn Bits[template N: Core.IntLiteral](x: Core.Int(N))` (fork/templates/tp2-plan.md Appendix A.4)",
    "fork/templates/tp2-plan.md §0.4, D-TP2-2"
  ],
  "blocked_by": [],
  "notes": "Filed at TP-2's discharge (<date>), id reserved by its plan (§0.9: the next free id above W-395 across every ref and worktree). Not a TP-2 regression against upstream: the nightly fails the same programs; a TP-1 capability (D-TP-11, W-193's discharge) withdrawn under R32 because upstream's `IsCallPerformable` defers the type-forming call. Workaround: an explicit template argument (`Get(i32, h)`; the probe ded_explicit runs on every toolchain). Probes: ded_holder and the fixture X25 (amended 2026-11-16, review fold: A-M1 / B-M1). Removal: upstream's mechanism when it designs one (no fork spelling, R32 (d)). Break condition: upstream's deduce.cpp deduces a binding through a template-dependent splice or `call_action`, or the nightly runs ded_holder (prints 42); then the fork follows it and the six splits lose `fail_todo_`."
},
{
  "id": "W-397",
  "kind": "missing-feature",
  "title": "TP-2 residue (D-TP2-2; TP-1 round 10's X-1 forms re-opened): a `match`, a pattern condition or `let` ... `else` on a value of a generic choice applied to a template parameter (`Opt(T)`, `Shape(T)`) or on `Core.Int(N)` for a template `N` reports ``semantics TODO: `match on unsupported scrutinee type` `` (``refutable pattern binding on unsupported scrutinee type``), because the scrutinee's type is a deferred splice",
  "subsystem": "toolchain/check (refutable_binding.cpp, handle_match.cpp, call.cpp `IsCallPerformable`)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
    "toolchain/check/testdata/generic/template/match_choice.carbon: fail_todo_designator_arm, fail_todo_designator_arm_exhaustive, fail_todo_value_param, fail_todo_nested_match, fail_todo_guard, fail_todo_pattern_forms, fail_todo_int_scrutinee, and the nine splits whose specific diagnostics became the TODO, eight of them renamed from `fail_` to `fail_todo_` (fail_todo_nonexhaustive, fail_todo_never_matches, fail_todo_int_never_matches, fail_todo_unknown_alternative, fail_todo_guard_on_instantiation, fail_todo_int_literal_out_of_range_on_instantiation, fail_todo_payload_literal_on_instantiation, fail_todo_payload_not_trivial_on_instantiation) beside fail_todo_qualified_alternative (<F1>); toolchain/lower/testdata/template/match_choice.carbon: fail_todo_designator_arm, fail_todo_let_else_payload, fail_todo_int_scrutinee",
    "fork/conformance/programs/generics/templates_match_dependent_choice.carbon (SKIP at <C1>)",
    "the nightly 2026.10.12 reports ``semantics TODO: `choice alternatives with parameters are not yet supported` `` or ``semantics TODO: `HandleMatchIntroducer` `` on the same splits; trunk before TP-1's round 10 reported the scrutinee TODO (fork/templates/plan.md D-TP-11's Round 10 paragraph, :2730-2744, and the round-10 probe table's X-1 row at :10318, ``match on unsupported scrutinee type`` at the scrutinee for 24; amended 2026-11-16, review fold: RR1-m3: rev 2 pointed at §1.13 item 26, which is W-295, a `Core.Int(N)` comparison that stops lowering)",
    "fork/templates/tp2-plan.md §0.4, D-TP2-2"
  ],
  "blocked_by": [],
  "notes": "Filed at TP-2's discharge (<date>). Measured output (amended 2026-11-16, review fold: B-m4): the branch's install reports one error on templates_match_dependent_choice.carbon, at its first `match` (:47:9), and stops; the SKIP line's \"at every other `match` here\" names the forms, not the count. A choice declared in a class template (`class_template_choice`, `Box(T).State`) is unchanged: its type is not formed by a call. W-252 (a `match` on a value whose type is not known where the template is defined) is the neighbour; this item is the class that TP-1 had made work and TP-2 withdraws. Removal: upstream's mechanism for a `match` on a template-dependent scrutinee (none designed at 7a3608bab; no fork spelling, R32 (d)). Break condition: upstream's `match` accepts a scrutinee whose type is a template-dependent splice (pattern_match.cpp or refutable_binding.cpp gain the case), or the nightly runs templates_match_dependent_choice.carbon; then the fork follows it."
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
},
{
  "id": "W-400",
  "kind": "missing-feature",
  "title": "TP-2 residue (D-TP2-2, D-TP2-8; found by plan review A, A-M1): an `impl forall` with a template binding whose self or interface is formed from it (`impl forall [template T: type] Box(T) as I`; `W as J(T)` for `interface J(T: type)`; `Holder(T) as I` for a structural `I { require impls HasGet; }`) is rejected with ``impl` with unused generic binding` or `impl as non-facet type `J(T)``, and the impl is not found for `Box(i32)`, because the self or interface is a deferred splice",
  "subsystem": "toolchain/check (impl.cpp, impl_lookup.cpp, call.cpp `IsCallPerformable`)",
  "size": "M",
  "bullet": "Generics: Integrated templates",
  "evidence": [
    "toolchain/check/testdata/generic/template/deduce_class_args.carbon: fail_todo_impl_forall_formed_self (<F1>): `ImplUnusedBinding` at the impl, `MissingImplInMemberAccess` at `h.(I.Val)()`",
    "the probes a2_impl_self, a3_impl_iface and a8_require (fork/templates/tp2-plan.md Appendix A.4, §0.4): trunk 701863aa5's install prints 11, 13 and 8; TP-2's prototype rejects all three; the nightly 2026.10.12 rejects a2 (then crashes, CHECK failure sem_ir/generic.cpp:84) and a3 (`impl as non-facet type `<splice of ...>``), and has no `template constraint` for a8",
    "fork/templates/tp2-plan.md D-TP2-1 (its rev 1 falsifier, met), D-TP2-2, D-TP2-8"
  ],
  "blocked_by": [],
  "notes": "Filed at TP-2's discharge (<date>), id reserved by its plan's rev 2 re-scan (§0.9: no W-4xx anywhere). Not a TP-2 regression against upstream: the nightly rejects the same forms; a TP-1 capability (D-TP-11's eager type forming) withdrawn under R32 because upstream's `IsCallPerformable` defers the type-forming call. Not W-398's substance (a capability lost, not a diagnostic moved to instantiation), so a residue of its own (the orchestrator's ruling 7, 2026-11-16). Workaround: a checked binding (`impl forall [T: type] Box(T) as I`) where the body needs no template semantics. Removal: upstream's mechanism when it designs one (no fork spelling, R32 (d)); owner TP-1's follow-on. Break condition: upstream's impl lookup deduces a template binding through a splice-typed self or interface, or the nightly runs a2_impl_self (prints 11); then the fork follows it and the split loses `fail_todo_`."
}
```

<!-- google-doc-style-resume -->

(Amended 2026-11-16, review fold: RR1-m4, implementation re-review: the
ledger's top-level "source" string also gained the per-discharge sentence
"TP-2 (2026-11-16) discharged W-374 and filed W-396 to W-400.", the file's
convention for a discharge (EH-C's "discharged W-346 and filed W-380" sits in
the same string), which this appendix did not name; the ledger stays as D
wrote it, `json.load` ok, prettier at a fixpoint.)

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
p002200:208-209 says "type checking of any expression dependent on a templated
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
CHECK-only; W-374's break condition fired by its letter on
destroy_calls.carbon (its template split `generic_use_inside_template`,
D-TP-11's own refill, SemIR only), the plan's §0.3 table is the report, and
the orchestrator ruled on 2026-11-16 (R29) that the removal proceeds, the
condition's letter amended to read a template golden by its changed split's
use of a template parameter (STOP stays for a changed split with no template).
D-TP2-5 two programs SKIP under R10, one `// SKIP:` line each in the runner's
recorded form; the bar 226/0/15 over 241 with 51 of 56 bullets, ruled
2026-11-16 (R29). D-TP2-6 the records and the register. D-TP2-7 the slices and
the fix budget of two. D-TP2-8 W-396 to W-400 filed (W-400, an `impl forall`
with a template binding whose self or interface is formed from it, found by
plan review A). D-TP2-9 the PR and the
landing under R33. D-TP2-10 the docs' dated notes.

_V-3 check at 7a3608bab (R32 (a))._ Each statement against the tip: the
deferral rule, call.cpp:449-464 quoted above; the signature, action.h:93-102
(`const SemIR::File&`); deduction, deduce.cpp:395-460 (the `SymbolicBinding`
case, the `StructValue` TODO, "// TODO: Handle more cases." at :443, the
`deduce_through()` default); the design, README.md:3012-3016,
terminology.md:263-268 and :308-311, overview.md:102-108, p002200:205-209,
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
2047 before the fill (eleven files), 2047 of 2047 after the fill, the
twenty-six renames and the pin split; conformance 226/0/15 over 241, 51 of 56
bullets; m17n_d
rejected as on the nightly; the mutants M1 (the exception renamed: the gate's
prefix rule and m17n_d catch it, no register check does) and M2 (the hunk
kept: no double check, e1 and e2 rejected).

_Break conditions._ D-TP2-1's: upstream changes which operands or which
dependence defer a call, or README.md:3012-3016 or p002200:205-209 change.
D-TP2-2's: W-396 to W-398's. D-TP2-3's: a double check in one specific, or
upstream defers a facet conversion of a template-dependent self. D-TP2-4's: a
changed split with no template parameter, or a golden outside the eleven
changes at the fill. D-TP2-5's ruling: upstream lands deduction through a
dependent class type (deduce.cpp's TODO at :443 resolved), and the SKIPs are
lifted at the next advance that brings it.

_Residues._ W-396, W-397, W-398 (D-TP2-2), W-399 and W-400 (D-TP2-8; TP-1's
follow-on).

_The §8.7 check on the tree at <R>._ `diff` of upstream's :449-464 against the
fork's function prints the two `context.sem_ir()` lines only; `git grep -c -w
forms_type -- toolchain` prints no match (exit 1; amended 2026-11-16, review
fold: A-m3); the model-identifier grep of the branch's diff 0.

_The id re-scan at D._ <n> refs, <h> distinct heads and <w> worktrees after a
fetch: W-396 to W-400 are this branch's ledger ids only; elsewhere range
bounds in prose; no W-4xx.

_Discharged by this commit: W-374 (TP-2)._
```

<!-- google-doc-style-resume -->

(Amended 2026-11-16, review fold: the entry as the records commit writes it
keeps the paragraphs above and adds, in the Context paragraph, the merge M of
Appendix F.1 (brought forward to the records commits: trunk moved after fix 1,
by ARB-4's two records commits, no conflict) and the implementation reviews'
verdicts; in the V-3 paragraph, the tips the implementation met, d10a566ab and
645e784aa, with the plan's 7a3608bab (B-m1); in the register paragraph, the two
checkers' lines at 645e784aa; in the Measured paragraph, the implementation's,
the fix's and the reviews' measured lines, the folded MINORs A-m1, A-m2 / B-m5,
A-m3, A-m4 / B-m3, B-m2, B-m4 and B-m6, X25 as W-396's probe and the two
commit-message errata. The committed entry is the record; the template above
stands as rev 3 wrote it but for the §8.7 wording.)

(Amended 2026-11-16, review fold: RR1-m1 and RR1-m3, implementation
re-review: the template's "no W-4xx" reads "no other W-4xx" in the committed
entry, W-400 being this branch's own ledger id, and its re-scan counts
distinct heads, 748, beside the 971 refs §0.9 counted, both reproduced by the
re-review; the Measured paragraph gains, by the dry round's records commit,
the re-review's measurement of the merged head 88c9eb8cf, the merge M having
been made without F.1's re-measure (F.1's note).)

### D.4 The dated notes

The TP-1 entry's register paragraph (fork/decision-log.md:6992-7003, the
"Weekly upstream check 2026-11-09" paragraph that ends "Veto-able.") gains:
" Resolved <date> by TP-2 (the entry "TP-2: ..." below): the exception
removed at <C1>, H10.8 ALIGNED; W-139's requirement kept, D-TP2-3." The same
sentence is appended to the TP-1 entry's "Weekly upstream check 2026-11-16"
paragraph (:7005-7021, :7022 being blank; the one that ends "call, or
README.md:3012-3016 changes. Veto-able." and says "the DRIFT stands on
W-374"), both paragraphs being living register notes (amended 2026-11-16,
review fold: B8; the range re-anchored 2026-11-16, review fold: RR1-m3, rev 2
said :7005-7022).

DR-0's register block (vii) (:258-263) gains, after "(added 2026-11-09, weekly
upstream check)": " (vii) resolved <date> by TP-2, <C1> and its fill <F1>;
H10.8 ALIGNED; W-139's convert.cpp requirement kept (TP-2 D-TP2-3)."

The entry "Weekly upstream check 2026-11-16": its register row for H10.8
(:19698) gains in its last cell " (resolved <date> by TP-2: ALIGNED)"; its
paragraph "_H10.8's re-read_" (:19730-19747) gains a last sentence "Resolved
<date> by TP-2 (fork/templates/tp2-plan.md): the row is ALIGNED and W-374
DISCHARGED." The entry "Weekly upstream check 2026-11-09": its register row
(:19971) gains the same cell note and its paragraph "_H10.8's verdict_"
(:20002-20033; amended 2026-11-16, review fold: RR1-m3, rev 2 said
:20002-20030) the same sentence.

### D.5 The UA-3 audit note (fork/ORCHESTRATION.md Next actions item 6)

After "call.cpp:1045-1046 rewriting the cut's :432; pointer_dereference.cpp:24
merging clean)," the sentence: "TP-2 (<date>) restored the cut's one-line form
in `IsCallPerformable`, so nine fork lines remain in that form (fourteen
`OperandDependence(context,` call sites in all: call.cpp 5, convert.cpp 6,
handle_index.cpp 2, pointer_dereference.cpp 1), and 62f1cc6a3's rename of
`GenericClassType` meets no fork use in that function."

(Amended 2026-11-16, review fold: RR1-m2, implementation re-review: the
sentence sits inside the audit item's parenthesis, after "merging clean;" and
before its closing "),", not after it: the words verbatim, its final period
replaced by "),", so that the item's list of audit entries reads on;
ORCHESTRATION.md keeps that placement.)

### D.6 The register files and rows

fork/register/rg1-plan.md row H10.8 (:1017) becomes:

<!-- google-doc-style-ignore -->

```text
| H10.8 | (viii) D-TP-11 forms a generic class type with template-dependent arguments eagerly (SUPERSEDED <date> by TP-2: `IsCallPerformable` defers a call when the callee or any argument is template-dependent, as upstream's does) | check/call.cpp:449-450 "Determines whether a call can be performed immediately" / "non-template-dependent)."; :453 `if (OperandDependence(context.sem_ir(), callee_id) ==` and :458 `if (OperandDependence(context.sem_ir(), arg_id) ==` at 7a3608bab; README.md:3012-3016 "type checking for anything dependent on the template parameter can't be completed until the template is instantiated with a specific concrete type"; check H10.8: `git log --oneline c1e83b0b7..<tip> -- toolchain/check/call.cpp | wc -l` = 9 at 7a3608bab (the merge-rule signal: a moved count means the function or its file changed; re-read the quote rows) | ALIGNED since <date> (TP-2, fork/templates/tp2-plan.md D-TP2-1; D-RG-1: the rule is upstream's text, the fork's function equal to it but for the `Context&` signature UA-3 converts); was NONE (RG-1) then DRIFT (2026-11-09, re-read 2026-11-16); the quotes identical at d10a566ab, the tip at the implementation, and at 645e784aa, the tip at the fix and the records (amended 2026-11-16, review fold: B-m1) | upstream changes which operands or which dependence defer a call in `IsCallPerformable`, or README.md:3012-3016 or p002200:205-209 change; then the row is re-read | W-355 (W-374 discharged; the lost forms W-396 to W-398 and W-400) |
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
deferred as upstream's `IsCallPerformable` defers it;
templates_deduce_class_args.carbon SKIP; an explicit template argument runs;)"
and after "is checked in the definition and runs (round 10 of
the focused re-review of the fold; ...)" insert " (TP-2, <date>: withdrawn,
W-397, the scrutinee's type being a deferred splice;
templates_match_dependent_choice.carbon SKIP; the scrutinee TODO is reported
again;)"; the Residue list gains ", two definition-time diagnostics made on
instantiation only (W-398), an `impl forall` with a template binding whose
self or interface is formed from it (W-400) and an unused facet value of a
template-dependent self converted to an interface outside a call (W-399)". The
cell thus names the two SKIPs and the residues, as ruling 3 requires (amended
2026-11-16, review fold: A-M1).
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
<M> (the merge of Appendix F.1, brought forward because trunk moved after
fix 1; amended 2026-11-16, records), <R> and this one): `IsCallPerformable` is
upstream's (7a3608bab call.cpp:
449-464 but for the `Context&` signature); eleven goldens refilled, twenty-six
splits renamed and one added, two programs SKIP (W-396, W-397); W-139's
convert.cpp requirement kept (D-TP2-3); W-396 to W-400 filed; register H10.8
ALIGNED;
container-measured (R33 (b)): gate 2047 of 2047, conformance 226/0/15 over
241, 51/56 bullets. Next: the PR with base trunk, LAND-1's landing, then UA-3."
Branches row, after `claude/carbon-fork-0-1-ehc`'s: "| `claude/carbon-fork-0-1-tp2`
| IMPLEMENTED AND REVIEWED (base trunk 701863aa5) — TP-2: `IsCallPerformable`
follows upstream's deferral of every template-dependent call argument (W-374,
R32); W-396 to W-400 filed; container-measured (R33 (b)): gate 2047 of 2047,
conformance 226/0/15 over 241 |". Next actions item 6: the W-374 sentence
("re-classifies TP-1's register row H10.8 DRIFT on W-374 ... W-139's convert.cpp
requirement is withdrawn when it lands.") gains "(TP-2, <date>: done on
claude/carbon-fork-0-1-tp2, W-374 discharged; the requirement is kept,
D-TP2-3; W-396 to W-400.)"; the UA-3 sentence "UA-3 follows W-341 and W-346
(both landed) and proceeds with PR 53 held" becomes "UA-3 follows W-341, W-346
(both landed) and W-374 (TP-2, <state>) and proceeds with PR 53 held". The
Scoreboard section gains "Expected after TP-2's landing: 226 PASS / 15 SKIP /
0 FAIL (241), 51/56 bullets (two programs SKIP under W-396 and W-397)".

(Amended 2026-11-16, review fold: RR1-m1 and §3 item 9, implementation
re-review round 1 DRY (APPROVE-WITH-AMENDMENTS: no BLOCKER, no MAJOR, four
records-only MINORs): the Branches row's leading phrase becomes "IMPLEMENTED
AND REVIEWED; RE-REVIEW ROUND 1 DRY (base trunk 701863aa5)", the row names the
merge, "trunk 99f4df970 merged at 949a8f574", and marks the measured figures
as re-measured on the merged head by the round; the dated paragraph names the
commits through D, 88c9eb8cf, where it read "this one", and gains one sentence
naming the round, its verdict and D's sha; the header clause is unchanged, it
points at the Branches row.)

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
instantiation (W-398); an `impl forall` with a template binding whose self or
interface is formed from it is rejected as on the nightly (W-400, pinned by a
`fail_todo_` split). Twenty-six splits renamed `fail_todo_`/`todo_fail_`, one
added, two programs SKIP with the residue ids. W-399 (an unused facet value of
a template-dependent self converted outside a call) found and filed for TP-1's
follow-on.

Break condition: W-374's "the removal changes a golden outside TP-1's and
SC-1's template goldens" fired by its letter on check/testdata/class/
destroy_calls.carbon's template split (D-TP-11's own refill, SemIR only); the
orchestrator ruled that the removal proceeds and amended the letter (D-TP2-4).

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
(Amended 2026-11-16, review fold: RR1-m1, implementation re-review: M was
made at 949a8f574 by the records writer, before R, because trunk moved after
fix 1 (ARB-4's two records commits, fork/decision-log.md's tail and
fork/tools/carbonbuild; merge-tree clean), without this re-measure, every
build input being identical; the re-measure is the re-review's, on the merged
head 88c9eb8cf under its label tp2-rr1: `GATE tp2-rr1: 2047 passed, 0
failed`, `AUTOUPDATE tp2-rr1: 0 file(s) changed`, `CONFORMANCE tp2-rr1: PASS
226 / FAIL 0 / SKIP 15 over 241`, bullets 51/0/5. When the merge touches no
build input the re-measure may be the next review's, and L measures the head
in any case.)

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
| `claude/carbon-fork-0-1-tp2` | LANDED as PR <N> by merge <merge sha> (<date>, LAND-1, R33; GitHub merged_at <merged_at>, merge_commit_sha <api sha>) — TP-2: `IsCallPerformable` follows upstream's deferral of every template-dependent call argument (W-374, R32); W-374 discharged, W-396 to W-400 filed; land-time commits <land-time shas>; container-measured (R33 (b)): gate <g> of <g>, conformance <p>/<f>/<s> over <n> |
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
follow-ons: W-399 and W-400 to TP-1's follow-on (Next actions item 6), W-396
to W-398 to the weekly check's re-reads (W-355).
```

<!-- google-doc-style-resume -->

It goes after this plan's Status paragraph.

### F.7 The decision-log sentence (A.6)

<!-- google-doc-style-ignore -->

```text
_Landed (<date>, LAND-1, R33):_ merged into trunk as PR <N> by <merge sha>
(GitHub merged_at <merged_at>); container-measured (R33 (b)): gate <g> of <g>,
conformance <p>/<f>/<s> over <n>; id re-scans: <rescan>; moved to follow-ons:
W-399 and W-400 to TP-1's follow-on; W-396 to W-398 to W-355's re-reads.
```

<!-- google-doc-style-resume -->

The last paragraph of the TP-2 entry (D.3).

### F.8 The PR description's Landed line (A.7) and W-374's discharge evidence

<!-- google-doc-style-ignore -->

```text
**Landed** on trunk <date> by merge <merge sha> (LAND-1, R33; GitHub
merged_at <merged_at>): container-measured gate <g> of <g>, conformance
<p>/<f>/<s> over <n>, <b>/56 bullets; moved to follow-ons: W-399 and W-400 to
TP-1's follow-on. Record: fork/ORCHESTRATION.md's paragraph dated <date> (<hh:mm>
UTC).
```

<!-- google-doc-style-resume -->

W-374's `notes` gain, appended: " LAND-1 (<date>, PR <N>'s landing): merged
by <merge sha> (GitHub merged_at <merged_at>); container-measured (R33 (b)):
gate <g> of <g>, conformance <p>/<f>/<s> over <n>, <b>/56 bullets; the §8.7
check re-run on the merge's tree gives the answer recorded at <R>: the two
`context.sem_ir()` lines only, `forms_type` no match (exit 1; amended
2026-11-16, review fold: A-m3)."

### F.9 The gap header's first sentence (A.8) and ORCHESTRATION's Scoreboard paragraph (A.9)

As LAND-1's templates, with 37 / 17 / 2 / 0 (unchanged) and PR <N>'s figures
(226 PASS / 0 FAIL / 15 SKIP over 241, 51/56): the bar of D-TP2-5's ruling
(ruling 3), a landing that measures otherwise stopping at D-LAND-6 step 4
(D-TP2-9); row 56 takes no "not of record" mark.
