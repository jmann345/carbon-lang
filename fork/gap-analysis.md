# Gap analysis: this fork vs the official 0.1 milestone

Produced 2026-07-19 by a 12-agent audit of trunk @ `99cda60` against
`docs/project/milestones.md#milestone-01`. Statuses: **DONE** (implemented
with real test coverage), **PARTIAL** (works with material gaps),
**MISSING** (absent), **DESIGN-ONLY** (designed, zero implementation).

## Scoreboard

**24 DONE / 18 PARTIAL / 13 MISSING / 1 DESIGN-ONLY** across 56 milestone
bullets. The front half of the compiler is essentially done; the back half
of the checklist is barely started.

## Per-bullet status

| 0.1 milestone bullet | Status | Evidence |
| --- | --- | --- |
| Code organization: Packages | DONE | Full package model checked with ~29 golden tests in toolchain/check/testdata/packages/ incl. restricted names and cross-package import. |
| Code organization: Libraries | DONE | Named libraries, api/impl pairing, export names/export import all checked and tested (check/testdata/packages/). |
| Code organization: Implementation files | DONE | api vs impl file semantics tested in check/testdata/packages/ (pairing, implicit imports). |
| Code organization: Importing | DONE | Lazy cross-IR import machinery (check/import_ref.cpp, 5013 lines), import cycles diagnosed, `import Cpp` and inline imports work; tested across suites. |
| Code organization: Namespaces | DONE | 23 golden tests in check/testdata/namespace/ covering nesting, aliasing, shadowing, cross-import merging, conflict/poisoning diagnostics. |
| Type system: User-defined types (classes) | DONE | Classes with fields, methods, adapt, abstract/base/final, access control fully checked and lowered (check/testdata/class/, lower/testdata/class/). |
| Type system: C++ interop — importing C++ types / exporting Carbon types | PARTIAL | Classes/enums/unions/templates import and Carbon classes export (125 check + 38 lower interop tests), but C++ templates cannot instantiate on Carbon class types and several export cases are fail_todo. |
| Type system: Single inheritance | DONE | base class/extend base, derived-to-base conversion, shadowing — ~19 golden tests in check/testdata/class/inheritance/. |
| Type system: Virtual dispatch | DONE | Vtables with override checking and thunks (check/class.cpp:142-370), verified to LLVM IR with llvm.load.relative.i32 in lower/testdata/class/virtual.carbon. |
| Type system: C++ interop — bi-directional inheritance, hierarchy roots, abstract/final/virtual mapping | PARTIAL | Carbon extends C++ bases and overrides C++ virtuals (with adaptation thunks); C++ derives from exported Carbon classes; but multiple/virtual/diamond inheritance and abstract-with-nonvirtual-dtor export are fail_todo. |
| Type system: Operator overloading | DONE | All operators route through Core interfaces (check/operator.h + core/prelude/operators), ~25 per-operator golden tests in check/testdata/operators/overloaded/. |
| Type system: C++ interop — synthesizing Carbon overloads for imported C++ types | PARTIAL | Broad C++ operator import mapped onto Carbon interfaces incl. spaceship rewrites, plus synthesized Copy/Destroy/As/Eq/Ordered/Iterate impls; assignment-operator import and some rewrites still fail_todo. |
| Type system: C++ interop — exporting Carbon operator overloads into C++ | MISSING | No evidence anywhere of exporting Carbon operator impls for use from C++ (audit: 'operator interop is one-directional'). |
| Type system: Sum types (discriminated unions) | PARTIAL | Parameterless `choice` works end-to-end (enum substitute), but payload alternatives emit context.TODO('choice alternatives with parameters are not yet supported') in handle_choice.cpp:159 and match cannot consume them. |
| Type system: Unions (un-discriminated) + C++ union mapping | MISSING | No `union` token in token_kind.def (verified by grep), no parse/check/design doc; C++ unions import only as opaque interop types. |
| Generics: generic functions and types | DONE | Generic classes/functions/methods with Generic/Specific definition-checked model (sem_ir/generic.h) and monomorphizing lowering (lower/testdata/function/generic/, 28 tests). |
| Generics: Checked generics | DONE | Interfaces, impls (forall/blanket/final), witness tables, associated constants, where-rewrites, named constraints, deduction, specialization + match_first — ~227 golden tests; residual gaps (== constraints, observe semantics, interface defaults) are edges. |
| Generics: Definition-checked variadics | DESIGN-ONLY | Complete 964-line design (docs/design/variadics.md, accepted p002240) but zero implementation — no `...`/`each` tokens exist in token_kind.def (verified). |
| Generics: Integrated templates | PARTIAL | `template T: type` checks and simple dependent member access works via deferred actions, but operators/conversions on dependent values are fail_todo, lowering hits CARBON_FATAL 'Template lowering not implemented yet' (lower/handle.cpp:363), and templates.md is a self-described skeletal placeholder. |
| Generics: Template-style structural conformance to nominal constraints | MISSING | 'structural conformance' appears nowhere in the toolchain and the templates design doc doesn't concretely design it — neither design nor implementation exists. |
| Generics: C++ interop — importing C++ templates, instantiating on Carbon types | PARTIAL | Class/function/alias/variable templates import and instantiate on C++ types and Carbon builtins, but Carbon class types as template args error 'unsupported type used as template argument' (interop/cpp/template/generic_call.carbon). |
| Generics: C++ interop — exporting Carbon templates/checked generics as C++ templates | PARTIAL | check/cpp/export.cpp creates clang FunctionTemplateDecls for type-parameter checked generics; non-type and enclosing-scope generics fail_todo; no Carbon-template export. |
| Generics: C++ interop — C++20 concepts <-> named predicates mapping | PARTIAL | Concepts import as compile-time predicates (interop/cpp/template/concept.carbon passes); the export direction (Carbon predicates as C++20 concepts) has no trace. |
| Functions: separate declaration and definition | DONE | Parsed and checked with redeclaration matching; tested in parse/testdata/function/ and check suites. |
| Functions: function overloading (Carbon-native) | MISSING | pattern_matching.md:696: 'We do not yet have an approved design for overloaded functions' — no design, no implementation of Carbon-side overloading. |
| Functions: C++ interop — importing/calling C++ functions and methods | DONE | Free functions, methods, ctors, extern C imported with auto-generated ABI thunks, verified through LLVM IR goldens (lower/testdata/interop/cpp/). |
| Functions: C++ interop — exporting Carbon functions/methods to C++ | DONE | Reverse interop lets inline C++ call Carbon functions/methods/statics with thunk machinery (check/cpp/export.cpp, 1202 lines; weak_odr thunks landed July 2026). |
| Functions: C++ interop — importing C++ overload sets | DONE | Real Clang Sema overload resolution incl. default arguments and literal-driven resolution (check/cpp/ overload tests). |
| Functions: C++ interop — open overload sets as extension points (swap etc.) | PARTIAL | Only iteration is synthesized into an interface (ADL begin/end -> Core.Iterate); no general swap-style heuristic import, several ADL cases fail_todo. |
| Control flow: conditions | DONE | if/else and if-expressions checked and lowered with golden tests (lower/testdata/). |
| Control flow: loops incl. range-based and C/C++ loop equivalents | DONE | while, for-in over arrays, ranges (Core.Range in prelude) and C++ ranges via Iterate; break/continue; lowered and exercised by ~40 building advent2024 programs. |
| Control flow: matching — good switch equivalents | PARTIAL | match fully parses (14 parse tests) but all 15 check handlers in check/handle_match.cpp are context.TODO stubs (verified: 14 TODO occurrences) — no semantics, no lowering. |
| Control flow: matching — sum-type consumption incl. std::variant/std::optional interop | MISSING | No match semantics, no choice payloads, no std::variant mapping; Optional is a placeholder without pattern integration. |
| Control flow: matching — if-let / let-else combined match+declaration | MISSING | Absent at every layer (no tokens, parse states, or check support) and absent from docs/design/pattern_matching.md — not even designed. |
| C++ interop: threading, atomics, memory model, synchronization | MISSING | No dedicated support, tests, or design doc anywhere in toolchain/ or docs/design/. |
| Error handling: dedicated control flow constructs | MISSING | No try/throw tokens or parser states; docs/design/README.md:3831: 'Carbon does not have language features dedicated to error handling' — undesigned and unimplemented. |
| Error handling: C++ exception interop (-fno-except config, calling throwing C++, exporting Carbon errors as std::expected/exceptions) | MISSING | clang_invocation.cpp contains no exception-handling configuration; no mapping design exists; philosophy doc disclaims seamless exception interop. |
| Stdlib: fundamental types (bool, iN, fN) | DONE | bool, Int(N)/UInt(N) with full checked arithmetic/comparison/conversion impls, Char; Float(N) somewhat narrower (core/prelude/types/). |
| Stdlib: tuple/array library parts | PARTIAL | array Iterate impl works; tuple Copy hand-written only for arities 0-3 with 'TODO: Implement tuple copy as a variadic generic impl'; no tuple Eq/Ordered — blocked on variadics. |
| Stdlib: pointer types | DONE | Pointer Copy/UnformedInit/const conversions, UnsafeAs casts, Optional(T*) null-niche for C++ ABI (core/prelude/). |
| Stdlib: interfaces powering language syntax (operators, conversions) | DONE | AddWith/EqWith/OrderedWith/IndexWith/ImplicitAs/As/UnsafeAs/Copy/Iterate etc. all present and powering syntax, though several shapes are workarounds pending interface extension. |
| Stdlib: String and string-literal types | PARTIAL | String is a 33-line non-owning {Char*, u64} with Size/Copy/indexing only — no equality, concatenation, or owning variant (core/prelude/types/string.carbon). |
| Stdlib: Optional | PARTIAL | Working Some/None/HasValue/Get with pointer niche, but the file states 'We don't have an approved design... The API here is a placeholder' (optional.carbon:27-28). |
| Stdlib: Slices | MISSING | grep for Slice in core/ returns nothing; no slice type anywhere; heap allocation likewise absent. |
| Stdlib C++ interop: transparent fundamental-type mapping | DONE | bool/char/iN/uN/fN map plus CppCompat.Long32/ULongLong64 adapters (core/prelude/types/cpp/, check/cpp/type_mapping.cpp). |
| Stdlib C++ interop: transparent non-owning string mapping | DONE | str <-> std::string_view bidirectional transparent mapping implemented and tested (check/cpp/custom_type_mapping.cpp, proposal p006177). |
| Stdlib C++ interop: transparent non-owning contiguous container mapping (incl. owning->view) | MISSING | No Carbon slice type and no std::span/vector view mapping — only ordinary API import of containers works. |
| Stdlib C++ interop: transparent iteration-abstraction mapping | DONE | Carbon range-for over C++ ranges via synthesized Core.Iterate (member and ADL begin/end), tested in check+lower (cpp_range_for_iterate.carbon). |
| Project: toolchain drop-in usage as Clang C++ toolchain with common Make/CMake build systems | PARTIAL | clang/clang++/clang-cl/lld busybox symlinks with on-demand runtimes are implemented and integration-tested, but nothing exercises or documents them under CMake or Make. |
| Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation | PARTIAL | Compile->link->run works on Linux/macOS for classes/generics/interop, but match, variadics, templates lowering, error handling, and unions are absent — gaps that do undermine evaluation of those features. |
| Project: installs on Windows, macOS, and Linux and builds working programs | PARTIAL | Linux x86-64/arm64 and macOS arm64 in CI (only Linux x86-64 released); Windows explicitly unsupported — clang_runtimes.cpp returns 'TODO: Windows runtimes are untested and not yet supported', LLD wired for ELF/MachO only, no Windows CI. |
| Project: CMake build-system integration plus Make documentation | MISSING | No CMake support, example, or docs anywhere (only a libc++ header-expansion .bzl mentions cmake); Bazel is the only integrated build system. |
| Project: detailed safety strategy | DONE | docs/design/safety/README.md rewritten via accepted p005914 (Strict/Permissive modes, per-category enforcement model, build modes, Rust-ecosystem reuse); residual future-work on soundness model/mode syntax and a stale conflicting principles doc. |
| Project: detailed and concrete design for safe Carbon (type/init/spatial/temporal/mutation + safe-Rust-interop analysis) | MISSING | Temporal/mutation safety exists only as an explicitly 'directional... provisional' section of p005914; no dedicated design docs or follow-up proposals, no Rust-interop analysis, README 'Lifetime and move semantics' is a bare TODO. |
| Project: basic evaluator documentation (getting started to FAQs) | PARTIAL | README nightly-tarball getting-started (Ubuntu-only) and a comprehensive project FAQ exist, but docs/guides contains only a glossary — no language tutorial or evaluation walkthrough. |
| Goal: design docs documented, cohesive, understandable without placeholders | PARTIAL | Generics/variadics/pattern-matching/classes designs are mature, but templates/metaprogramming/match-control-flow are self-described skeletal placeholders and the interop README has ~10 empty TODO sections. |

## Workstreams to close the gap (dependency-ordered)

Sizes: S < M < L < XL. "Arbiter" = the objective test that decides the
workstream is done.

### W1. Execution/conformance test harness [M]

**Depends on:** none

Today only one test executes a compiled Carbon binary; all 1,625 golden tests pin compiler dumps, not behavior. Build the compile-and-run harness first — it is the objective arbiter every other workstream's 'done' claim needs, and it has no dependencies. Include a `carbon run` subcommand or build+exec mode.

**Arbiter:** A bazel test target that compiles, links, AND executes a directory of .carbon programs asserting stdout/exit code (e.g. FileTestBase subclass invoking `carbon build` then ExecuteAndWait, or a generalized install_test.py); advent2024 programs run under it in CI.

### W2. Design authorship: error handling, unions, if-let/let-else, function overloading, threading/atomics interop [XL]

**Depends on:** none

Five 0.1-required features have no accepted design at all — error handling (README explicitly says none exists), un-discriminated unions, if-let/let-else, Carbon function overloading, and C++ threading/atomics interop. Nothing downstream can be implemented until these proposals land; this is the single largest schedule risk because it is bottlenecked on design bandwidth, not engineering.

**Arbiter:** Accepted proposals merged for each topic; docs/design/ sections exist with no 'TODO:'/'placeholder' markers for error handling, unions, combined match-declare, overloading, and threading interop (grep-verifiable against the 0.1 'without placeholders' bar).

### W3. Concrete safe-Carbon design (temporal/mutation safety + safe-Rust-interop analysis) [XL]

**Depends on:** none

The 0.1 checklist requires a detailed, concrete design (not implementation) for safe Carbon. Only a directional sketch exists (Ante-style shared mutability, Swift-style adoption). Pure design work, parallelizable with everything else, but it is the stated reason 0.1 slipped to end-2026.

**Arbiter:** Dedicated accepted proposals replacing p005914's 'provisional' section: concrete pointer/borrow type-system rules, safety-mode syntax, soundness model, worked C++-migration examples, and a written safe-Rust-interop analysis — reviewed against the milestone's five safety categories. No implementation required.

### W4. Pattern matching semantics (match check + lowering, expression/refutable patterns) [L]

**Depends on:** Execution/conformance test harness

match is fully parsed and designed but 100% stubbed in check. Implement match statement checking (cases, guards, default, exhaustiveness), expression patterns, refutable-pattern rejection, and lowering (decision-tree or chain). This unblocks sum types, Optional/variant interop, and the if-let family.

**Arbiter:** All 15 context.TODO stubs in check/handle_match.cpp replaced; parse/testdata/match cases flow through check and lower to golden IR; execution tests demonstrate C/C++ switch-equivalent programs producing correct output incl. guards and default.

### W5. Sum types with payloads, native unions, and std::variant/optional interop [L]

**Depends on:** Pattern matching semantics (match check + lowering, expression/refutable patterns), Design authorship: error handling, unions, if-let/let-else, function overloading, threading/atomics interop

Implement payload-carrying choice alternatives (handle_choice.cpp TODO; storage design in sum_types.md admits the low-level primitive 'hasn't been designed yet'), destructuring through match, the new union feature per its landed design, and the variant/optional interop mapping the milestone names explicitly.

**Arbiter:** Choice alternatives with parameters construct AND destructure via match in executed tests; a `union` declaration round-trips with C++ unions in interop tests; a Carbon match over an imported std::optional/std::variant works.

### W6. Definition-checked variadics implementation [XL]

**Depends on:** none

The design (964 lines, accepted p002240 with formal typechecking appendix) is complete but implementation is at 0% — not even lexable. Requires lexer tokens, parse states, pack typechecking machinery in check, and pack lowering. Independent of match; can start immediately. Explicit 0.1 bullet.

**Arbiter:** `...`/`each` tokens, parse nodes, and check/lower support such that the worked examples in docs/design/variadics.md compile and execute; core/prelude tuple Copy/Eq rewritten as a single variadic impl replacing the arity-3 hand-rolls.

### W7. Integrated templates completion + structural conformance [L]

**Depends on:** Design authorship: error handling, unions, if-let/let-else, function overloading, threading/atomics interop

Template bindings and simple dependent member access exist, but dependent operators/conversions are fail_todo and template lowering is a hard fatal. Structural conformance to nominal constraints needs a real design first (templates.md is a placeholder). Also unlocks C++ templates instantiated on Carbon types.

**Arbiter:** generic/template/unimplemented.carbon fail_todo tests flip to passing (operators, conversions, assoc-const access on dependent values); the CARBON_FATAL at lower/handle.cpp:363 is gone and a template function executes in the run harness; a structural-conformance test (C++20-style validity predicate) checks and runs.

### W8. C++ interop frontier: templates-on-Carbon-types, operator/concept export, exception + threading interop [XL]

**Depends on:** Integrated templates completion + structural conformance, Design authorship: error handling, unions, if-let/let-else, function overloading, threading/atomics interop, Sum types with payloads, native unions, and std::variant/optional interop

Interop machinery is strong (thunks, overload sets, inheritance) but the 0.1 bullets still open are: C++ templates on Carbon class types, exporting operators and concepts, the entire exception-interop story (blocked on error-handling design), threading/atomics, and closing the interop design README's ~10 placeholder sections.

**Arbiter:** Instantiating an imported C++ class template on a Carbon class type works in executed tests; Carbon operators and named predicates usable from C++; a Carbon program calls a throwing C++ function under both -fexceptions and -fno-except configs with defined behavior; a benchmark with interop in the critical path runs — matching the milestone's 'build and run tests of most C++ interoperability' goal.

### W9. Standard library buildout: slices, heap allocation, String, Optional, span mapping [L]

**Depends on:** Definition-checked variadics implementation, Sum types with payloads, native unions, and std::variant/optional interop

Close the 'types with important language support' half of the stdlib checklist: slices (missing entirely), heap allocation (missing), owning/comparable String, a designed (non-placeholder) Optional, and the non-owning contiguous-container interop mapping. Several APIs are currently workarounds pending variadics and interface extension.

**Arbiter:** A core/ test suite (compiled AND executed via the run harness) covering: a slice type with runtime bounds behavior, heap allocation, an approved-design Optional and String with comparison/ownership story, and transparent std::span/owning-container->view mapping round-tripping with C++.

### W10. Windows support end-to-end [XL]

**Depends on:** Execution/conformance test harness

The 0.1 milestone requires install + working programs on Windows; today clang_runtimes.cpp hard-errors on Windows, LLD has no COFF driver wired, there is no Windows CI, and releases are Linux-x86-64-only. Independent of language features; large due to runtimes, linking (link.exe/lld-link), path/ABI work, and CI infrastructure.

**Arbiter:** A Windows runner in CI that installs the toolchain, builds runtimes (or uses prebuilt), compiles/links/executes a Carbon+C++-interop program, and a released carbon_toolchain artifact for Windows alongside macOS and Linux (incl. arm64) with OS/CPU in package names.

### W11. CMake/Make integration and evaluator documentation [M]

**Depends on:** Execution/conformance test harness

The milestone explicitly requires CMake integration plus Make documentation; neither has been started (Bazel-only today, though `carbon config --json` provides groundwork). Evaluator docs are thin (glossary only in docs/guides). Mostly product/docs work, parallelizable late.

**Arbiter:** A CI-tested example CMake project that builds a mixed Carbon/C++ program using the installed toolchain (drop-in Clang mode), written Make-integration docs, and a docs/guides getting-started tutorial an evaluator can follow from install to running a program with interop.

### W12. Unicode source support in the lexer [S]

**Depends on:** none

Explicit TODOs at lex.cpp:301/471/1454 make non-ASCII source a lex error despite a finished design. Small, self-contained, no dependencies — good early win for the 'translate existing C++ code' goal (identifiers in real codebases).

**Arbiter:** Lexer accepts UAX#31/NFC identifiers and Unicode whitespace per docs/design/lexical_conventions/words.md, with golden lex tests for non-ASCII identifiers replacing today's hard errors.

## Overall assessment

This fork (a fresh clone of upstream trunk, July 2026) is roughly at a strong mid-stage toward 0.1: the front half of the compiler is essentially done and the back half of the checklist is barely started. Lexing/parsing cover nearly the whole declared syntax with CI-enforced coverage; checked generics, classes with virtual dispatch, operator overloading, the package/import model, and the C++ interop machinery (embedded Clang, bidirectional thunks, overload sets, inheritance, template import) are implemented with deep golden-test suites and real programs compile to working Linux/macOS binaries. The gaps cluster in three tiers. Tier 1 — undesigned 0.1 requirements: error handling + C++ exception interop, un-discriminated unions, if-let/let-else, function overloading, threading/atomics interop, and the concrete safe-Carbon design; these are bottlenecked on proposal authorship, not code, and are the dominant schedule risk (the project's own roadmap calls end-2026 the earliest plausible 0.1). Tier 2 — designed but unimplemented or stubbed: definition-checked variadics (0% implemented), match semantics (all check handlers are TODO stubs), choice payloads, and template lowering (hard CARBON_FATAL). Tier 3 — product gaps: Windows support (explicitly unsupported), CMake/Make integration (not started), multi-platform releases, evaluator docs, and — critically for judging everything else — the absence of any execution-level conformance testing (exactly one test runs a compiled Carbon binary). Recommended sequencing: stand up the run-and-verify harness immediately as the arbiter, launch the design-authorship and safe-Carbon workstreams in parallel (longest pole), then implement match -> sum types/unions -> stdlib, with variadics, templates/interop frontier, Windows, and CMake proceeding as parallel tracks. Realistically this is 2+ years of work at current velocity for a small team, dominated by design and by the interop/Windows XL items.

## Area summaries

One-paragraph maturity assessment per audited area (full evidence lives in
the audit transcripts; spot-check claims against the cited paths before
relying on them for implementation work).

### Lexing and parsing (toolchain/lex/, toolchain/parse/)

Lexing and parsing are the most mature layers of the toolchain and are close to done for the 0.1 syntax surface, at least for ASCII source. The lexer implements the full documented lexical design (symbols, keywords, raw identifiers, numeric/string/char literals including multiline and raw strings, comment rules, bracket matching with recovery) and is backed by substantial unit tests, golden file tests, fuzzers, and benchmarks. The recursive state-machine parser (164 states, ~300 node kinds) parses essentially every declared language construct: packages/imports/libraries/namespaces, functions (separate decl/definition, terse `=>` bodies, builtin bodies, `->` and `->?` returns), lambdas, classes with base/adapt, interfaces, named constraints, impl (incl. forall, final, match_first), require/observe, choice types, match with guards, all statements, the full operator set with whitespace-sensitive precedence, where-expressions, and compile-time/template/form binding patterns. A CI coverage test enforces that every parse node kind appears in golden testdata, so "implemented but untested" is nearly an empty category here. The real gaps versus design and the 0.1 milestone are: Unicode identifier/whitespace lexing (explicitly TODO, non-ASCII is an error), variadics (`...`/`each` — designed in docs but no tokens exist), the `like` generic-constraint sugar (keyword lexed, never parsed), and any syntax for unions, dedicated error handling, or `if let`/`let else`-style combined match — those are absent at the token/state level entirely.

### Semantic checking core (toolchain/check/ and toolchain/sem_ir/)

The check/sem_ir layer is mature for classes, operator overloading, namespaces, and the package/library/import model: these are implemented end-to-end with large golden-file test suites (965 .carbon files under toolchain/check/testdata) and, for virtual dispatch, verified LLVM lowering (relative vtables, thunks, load.relative dispatch). Sum types exist only as parameterless enum-like `choice` declarations; payload-carrying alternatives emit an explicit "not yet supported" TODO diagnostic. Pattern matching is the largest gap relative to the 0.1 milestone: the `match` statement is fully parsed but every check handler is a `context.TODO` stub, expression patterns are unimplemented, and there is no if-let/let-else equivalent at any layer. Undiscriminated unions and dedicated error-handling constructs are absent entirely — not lexed, not designed (docs/design/README.md states Carbon has no dedicated error-handling features yet). TODO density is significant (488 TODO comments in check/, 173 in sem_ir/, 88 test files exercising the SemanticsTodo diagnostic), but the TODOs cluster in known frontier areas (match, choice payloads, C++ interop edges) rather than in the core class/generic/import machinery.

### Generics system (checked generics, template generics, specialization) vs Carbon 0.1 milestone

Checked generics are the most mature part of the toolchain: interfaces, impls (inline/extend/out-of-line/forall/blanket), witness tables, associated constants and functions, parameterized interfaces, where-clause rewrite and impls constraints, named constraints, deduction, and impl specialization (type-structure prioritization, final impls, and the newly landed match_first blocks) are all implemented with dense file-test coverage (~227 .carbon check tests across impl/interface/facet/where_expr/named_constraint/match_first/deduce/generic dirs) plus monomorphizing lowering tests. Within checked generics the notable gaps are same-type (==) constraints (parsed but stored as an unenforced 'other_requirements' TODO), observe declarations (accepted but equivalences not applied to conversions), interface defaults/final members (SemanticsTodo), and the impl-lookup termination rule. Template generics are early-stage: 'template T: type' bindings and a deferred-action instantiation mechanism (refine_type_action/access_member_action/splice_inst) exist and simple member access works, but operators, conversions, and associated-constant access on template-dependent values are explicit fail_todo tests, and the templates design doc itself is a self-described placeholder. Definition-checked variadics — an explicit 0.1 milestone bullet — are fully designed (docs/design/variadics.md) but have zero implementation: no 'each' keyword, no pack tokens or parse nodes anywhere in the toolchain. Template-style structural conformance to nominal constraints (the other 0.1 template bullet) has no trace in the codebase. Overall this area is roughly 70-80% of the checked-generics design but clearly short of the 0.1 checklist on variadics and integrated templates; C++ template interop (import of class/function/alias/var templates and concepts, export of Carbon generics as C++ templates) is meanwhile surprisingly far along.

### C++ interop

C++ interop is the most actively developed part of the toolchain and is substantially implemented in both directions: a full Clang instance is embedded in the checker (toolchain/check/cpp/, ~10k lines across import/export/thunk/operators/overload-resolution/type-mapping), with `import Cpp library "..."` and `inline Cpp '''...'''` syntaxes, and "reverse interop" letting C++ code inside inline blocks reference `Carbon::` entities via a lazy external AST source. Importing C++ functions, overload sets (resolved by Clang Sema), classes, fields, enums, unions, constructors, virtual functions, class/alias/variable templates, concepts-as-predicates, object-like macros, and constexpr constants works and is covered by ~125 check-phase and ~38 lower-phase golden file tests, including LLVM-IR-level verification of the bidirectional thunk machinery (documented in toolchain/docs/check/cpp/thunks.md, weak_odr linkage landed July 2026). Bi-directional inheritance largely works: Carbon classes extend C++ bases and override C++ virtuals (with signature-adaptation thunks and C++-side vtable synthesis), and C++ code can derive from exported Carbon classes. Major 0.1-milestone gaps remain: no exception/error-handling interop at all (no -fexceptions configuration, no mapping to Carbon errors or std::expected), no threading/atomics story, C++ templates cannot be instantiated on Carbon class types, no Carbon-predicate-to-C++20-concept export, no operator export to C++, and std-type transparent mapping covers only str<->std::string_view, initializer_list, and Optional(T*)->T* (no span/vector/optional/variant mappings). Test coverage is deep at the SemIR/LLVM-IR golden-test level but execution-level testing is thin — examples (hello_world, socket, re2_playground driving real RE2/LLVM C++ APIs) are build targets, with re2 tagged manual and no run-and-verify interop tests in-repo.

### Lowering and codegen (toolchain/lower/, toolchain/codegen/, driver compile/link/build, platform support)

Carbon programs genuinely compile to working native executables today on Linux and macOS: the driver has a full compile -> lower -> optimize -> codegen -> link pipeline, and `carbon build` produces a runnable hello_world binary in a unit test, while ~40 Advent-of-Code programs plus C++-interop examples (POSIX sockets, re2) build as bazel `carbon_binary` targets. Lowering (SemIR to LLVM IR, ~6,100 lines) is the real thing with 236 golden-IR file tests spanning classes with vtables/virtual dispatch, checked generics with specific coalescing, impls/witness thunks, operators, tuples/structs/arrays/pointers, globals with global_ctors, control flow, and 38 C++-interop lowering tests that merge Clang-generated IR into the same module. The main gaps are: integrated templates hit a hard CARBON_FATAL "Template lowering not implemented yet", `match` statements stop at the check phase (TODO), choice types lower only for construction, and several value-representation edge cases are fatal errors. Codegen itself is a thin, working wrapper over LLVM's addPassesToEmitFile with only 2 dedicated golden tests, though driver tests validate real object files and assembly. Test coverage is IR-golden-heavy but execution-light: almost nothing in CI actually runs a compiled Carbon binary and checks its output (the one bazel `run` integration test runs a pure C++ binary and is gated behind a manual/full flag). Against the 0.1 milestone requirement to "install on Windows, macOS, and Linux and build working programs for those platforms", Windows is explicitly unsupported (runtimes builder returns "Windows runtimes are untested and not yet supported", LLD is wired for ELF and MachO only, no Windows CI), so this area is roughly at a solid Linux/macOS MVP with Windows entirely open.

### Standard library (Core package / prelude)

The Core package is a small but functioning prelude (~25 .carbon files under /home/user/carbon-lang/core/) that covers the language-support layer of the 0.1 checklist: fundamental types (bool, Int(N)/UInt(N)/Float(N), Char, literal types), a broad set of operator interfaces (arithmetic, bitwise, comparison, As/ImplicitAs/UnsafeAs, IndexWith), Copy/Destroy/UnformedInit machinery, Iterate (powering for-loops over arrays and C++ ranges), a placeholder Optional, a minimal non-owning String, and an i32-only Range facility that was just moved into the prelude (commit 31cc20f "move Core//range into prelude (#7524)"). Coverage is real but indirect: 126 toolchain file tests compile against the full production prelude, and ~30 example programs (examples/advent2024) exercise ranges, iteration, arrays, operators, and Core.io end to end; there is no dedicated unit-test suite for core/ itself. Several checklist items are explicitly self-described placeholders (Optional: "We don't have an approved design"; io: "not part of the design"), and two 0.1 library examples — slices and heap allocation — are absent entirely, as are owning strings, string comparison, variadic tuple support, and any Default impls. Net assessment: the "language and syntax support" half of the 0.1 stdlib checklist is largely implemented and tested; the "types with important language support" half (String, Optional, slices) ranges from minimal to missing, consistent with the milestone's stated plan to lean on C++ interop for most library needs.

### Language design documentation completeness (docs/design/) vs Carbon 0.1 milestone requirements

The design docs are highly uneven relative to the 0.1 bar of "documented, cohesive, understandable without placeholders". Checked generics, variadics, pattern-matching syntax/semantics, classes, expressions, and the safety *strategy* are mature, proposal-backed designs. However, several features the 0.1 milestone explicitly requires have no design at all (un-discriminated unions, dedicated error handling and C++ exception interop, C++ threading/atomics interop, if-let/let-else style match declarations, an approved function-overloading design) and others are self-labeled "skeletal... placeholder" docs (templates, metaprogramming, aliases, blocks_and_statements, and the `match` control-flow section itself). The C++ interop design (docs/design/interoperability/README.md) is under active, recent reconstruction — backed by a burst of 2025–2026 accepted proposals — but currently contains at least 10 explicit empty "TODO:" sections covering core topics like overload resolution, constructors, class member access, and pointer/reference/const mapping. The safety strategy was freshly updated (proposal #5914) but the milestone's required "detailed and concrete design for safe Carbon" (temporal/mutation safety mechanics, lifetime/borrow design, Rust interop analysis) does not exist; the README's "Lifetime and move semantics" section is a bare TODO. Proposal momentum (highest-numbered ~p006177–p007493, through 2026-07-13) is heavily concentrated on C++ interop and syntax refinement, with no recent movement on error handling, unions, templates, or metaprogramming.

### Memory safety strategy and design (required 0.1 project feature)

The 0.1 milestone requires two deliverables here: a "detailed safety strategy" and a "detailed and concrete design for safe Carbon" covering type, initialization, spatial, temporal, and mutation safety plus a safe-Rust-interop analysis (implementation explicitly NOT required for 0.1; it is deferred to 0.2). The strategy half is in reasonably good shape: proposal p005914 (2025) replaced the 2020-era strategy with a concrete framework in docs/design/safety/ covering safety modes (Strict vs Permissive Carbon), a per-category enforcement model ("largely match Rust's": temporal and data-race safety via the type system at compile time, spatial at run time, initialization hybrid), build modes, and full terminology. The design half is far behind: the compile-time temporal/mutation safety model — the 2025 roadmap's flagship KR — exists only as an explicitly "directional... provisional" section of p005914 (more pointer types than Rust, safe shared mutation building on Ante's model, Swift-style incremental data-race adoption), with no dedicated design docs, no landed follow-up proposals, no worked C++-migration examples, and multiple "Future work" placeholders (soundness model, safety-mode syntax). In the toolchain the only safety-adjacent implementation is the `unsafe` keyword and a working, tested `unsafe as` conversion operator (Core.UnsafeAs) used mainly for C++ interop pointer casts; there is no borrow/lifetime checking, no safety-mode enforcement, and no runtime bounds checking. Net: strategy ~done, concrete safe-Carbon design is the largest open item and is essentially at the "declared direction" stage.

### Project/toolchain product features for 0.1: drop-in Clang toolchain, build-system integration, install/packaging/releases, evaluator documentation

The drop-in Clang toolchain story is the most mature part of this area: the `carbon` busybox dispatches on argv[0] symlinks (clang, clang++, clang-cl, clang-cpp, ld.lld, ld64.lld, plus LLVM tools), runs Clang in-process via a thread-safe runner, and builds target runtimes (compiler-rt builtins, CRT, libc++/libc++abi, libunwind) on demand with a cache — all covered by substantial unit tests and an end-to-end install integration test that compiles and runs both C++ and Carbon-with-C++-interop programs. Build system integration is Bazel-first and tested (example downstream module, `carbon config --json`, cc_toolchain rules), but the 0.1-required CMake integration and Make documentation are entirely absent. The install story is Linux-x86-64-only for actual releases: a nightly GitHub prerelease tarball is automated, CI tests Linux x86-64/AArch64 and macOS AArch64, but there is no Windows support anywhere (no CI, no packaging targets, no release artifacts for macOS or ARM Linux either). Evaluator documentation is thin: a README getting-started for the nightly tarball and a project FAQ exist, but docs/guides contains only a glossary and the driver doc is a stub. The repo's own version_base.bzl states progress toward 0.1 hasn't warranted moving off 0.0.0, and the roadmap calls shipping 0.1 in 2026 "very ambitious ... may not be possible".

### Build feasibility in this container (4 CPU, 15GB RAM, ~30GB free disk)

Building the Carbon toolchain unavoidably compiles LLVM+Clang+LLD from source: MODULE.bazel pins llvm-project to a specific upstream commit (615644763ffcfc, 2026-07-09) via git_override with 7 Carbon-local patches, and the carbon-busybox binary links Clang and LLD libraries, so no prebuilt or system LLVM can be substituted for the build dependency. A system Clang is required only as the bootstrap host compiler, and it must be >= 19 with libc++; this container has clang 18.1.3 and no libc++, both fixable via apt (clang-19 1:19.1.1 and libc++-19-dev are in noble-updates, and apt mirrors are reachable through the proxy). The mandated bazelisk probe (scripts/run_bazelisk.py --version) failed with HTTP 403: this session's proxy gates GitHub file/API/release downloads per-repository ("GitHub access to this repository is not enabled for this session. Use add_repo to request access"), blocking the bazelisk binary, all ~15 BCR dependency tarballs (abseil, googletest, protobuf, etc. — release-asset and codeload URLs both verified 403), and rules_python's hermetic CPython; bazel 8.6.0 itself IS downloadable from releases.bazel.build (verified HTTP 206) and git-protocol access to github.com/llvm/llvm-project works (ls-remote succeeded), but the BCR tarball gate alone makes any in-container build fetch fail today. Even if networking were solved, a full build is ~7,000-10,000 compile actions (LLVM+Clang+LLD plus 378 Carbon .cpp files plus a monolithic clang-runtimes build action), roughly 4-8+ hours on 4 CPUs, and disk is the binding constraint: llvm git clone (~3-5GB) + externals + fastbuild outputs (25-40GB) + the default-on disk cache duplicating artifacts would exhaust ~30GB free; only a -c opt build with the disk cache disabled might barely fit. The most feasible arbiter is the upstream nightly prebuilt toolchain tarball (carbon_toolchain-0.0.0-0.nightly.YYYY.MM.DD.tar.gz, Linux x86_64 only, a self-contained install tree) — currently 403-gated because the session's enabled repo is the fork jmann345/carbon-lang (forks carry no releases), so it needs one user action (add_repo carbon-language/carbon-lang, or the user supplies the tarball).

### Testing infrastructure — the future "arbiter" (file_test framework, execution tests, fuzzing, tracing, autoupdate)

Carbon's compile-check testing infrastructure is mature and heavily used: a well-documented golden-file framework (testing/file_test/) drives ~1,625 .carbon testdata files across lex/parse/check/lower/codegen/driver/format/language_server through the driver in-process, with autoupdate of CHECK lines, split-file tests, a minimal-prelude include system, and coverage tests that assert every diagnostic kind and parse-node kind appears in testdata. However, essentially all of this validates compiler dumps and diagnostics, not program behavior. A true compile-AND-run mechanism exists only in embryonic form: toolchain/install/install_test.py compiles, links, executes one hardcoded Carbon program (using C++ iostream interop) and asserts its stdout, and an expensive manual bazel integration test runs one example binary. There is no data-driven execution-test harness, no `run` driver subcommand, and the file_test framework never spawns subprocesses. Building a 0.1 conformance suite would require a new harness — the natural paths are a FileTestBase subclass that invokes the driver `build` subcommand then executes the result, or generalizing install_test.py's run_carbon_test into a file-driven suite over carbon_binary-style programs. Explorer (the old semantics interpreter with tracing) has been removed from the repo entirely, so there is no independent reference implementation to arbitrate semantics against; the toolchain's golden SemIR/LLVM-IR dumps are currently the de facto arbiter.

