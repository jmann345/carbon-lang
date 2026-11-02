<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# CMake integration plan: language modules, example project, Make documentation (CM-1: W-060, W-061)

**Status:** rev 2, 2026-10-12 — SIGNED OFF FOR IMPLEMENTATION. The plan review
of R29(c) returned APPROVE-WITH-AMENDMENTS (one BLOCKER, two MAJORs, seven
MINORs; every finding reproduced by the fixer and folded — the review fold
record and the sign-off are at the end). Branch `claude/carbon-fork-0-1-cmake`
off trunk 0bdce60a5 (post-PR 50; PR 51 — the UA-2 reconciliation — is HELD OPEN,
unmerged, because GitHub Actions on the repository is disabled:
fork/decision-log.md:6519-6545, fork/ORCHESTRATION.md:13-46). Trunk's floor is
**128 PASS / 0 FAIL / 22 SKIP over 150**, 48/56 bullets
(fork/conformance/out/scoreboard.json, generated 2026-10-06), gap-analysis
header 30 DONE / 21 PARTIAL / 4 MISSING / 1 DESIGN-ONLY
(fork/gap-analysis.md:18-30), ledger max id W-125 on trunk, W-127 on PR 51.
Every count below is a DELTA from that base; absolutes are restated at rebase
time (§5, §8.3). This workstream touches no toolchain C++ and no golden, so it
needs no autoupdate; its verification is prek plus the example's own arbiter
script run against the upstream nightly 0.0.0-0.nightly.2026.10.12+62f1cc6
(`carbon version`), and the hosted conformance run that cannot be dispatched
today (R28).
Every decision is an R29(a) auto-adopt recorded for after-the-fact veto, each
with a break condition. Line numbers are against trunk 0bdce60a5 and were
re-verified for this plan; stale citations found in the ledger are corrected in
§0.2.

**Items:** W-060 ("W11a: CMake integration for building Carbon code, plus
Make documentation", size L, fork/inventory/work-items.json:1140-1153) and
W-061 (W11b, the in-tree Make/CMake drop-in-Clang example project, CI coverage
and docs, size M, :1155-1166). W-062 (the evaluator tutorial, :1168-1180) is
NOT this workstream's. W-002 item (3) — "no arbitration channel for
external-build-system or document-review bullets" (:22-38) — is answered for
external builds here (§1.C D-CM-14).

**Milestone bullets this plan flips** (fork/gap-analysis.md:87 and :84; R7:
bullet strings are copied character-for-character into the conformance
headers): "Project: CMake build-system integration plus Make documentation" —
MISSING → DONE (expected, not of record: §5); "Project: toolchain drop-in usage
as Clang C++ toolchain with common Make/CMake build systems" — PARTIAL → DONE
(same caveat). The milestone text is docs/project/milestones.md:221-231:
"Supports drop-in usage as a Clang C++ toolchain with the most common Make-
and CMake-derived build systems" and "Build system integration for CMake, and
documentation for integrating with Make or similar build systems".

## §0 Audit: what already exists, and where the ledger is stale

### §0.1 Element table (verified in-tree at 0bdce60a5 and against the nightly)

| # | Element | Status | Evidence and measurement |
| --- | --- | --- | --- |
| 1 | Any CMake support in the tree | MISSING | `grep -rli cmake` outside fork/, .git/, third_party/ and testdata/ hits 13 files, all Bazel-internal (bazel/cc_toolchains/*.bzl, toolchain/runtimes/configure_cmake_file*.{py,bzl} and BUILD, toolchain/install/install_filegroups.bzl, two fork workflows, .bazelrc, one llvm patch); no CMakeLists.txt, no `*.cmake`, no `cmake/` or `examples/cmake/` directory, no docs/guides/build_systems.md (`ls` of all three fails) |
| 2 | Make documentation | MISSING | docs/guides/README.md:9-12 lists only the glossary; README.md:273-317 "Getting started" shows one explicit compile + link + run of a single file and is the only Make-shaped text in the tree |
| 3 | Downstream build-system example precedent | LANDED for Bazel | examples/bazel/ is "its own _distinct_ example Bazel project" not built by `bazel build //examples/bazel/...` (examples/bazel/BUILD:5-11); examples/BUILD:35-41 lists its files explicitly (no glob) for `bazel_integration_tests` — a BUILD-less sibling directory is invisible to Bazel |
| 4 | Whole-package compile rule precedent | LANDED in Bazel | bazel/carbon_rules/defs.bzl:64-92 and :173-204: one `compile --output=X --output-last-input-only --no-include-carbon-core <dep APIs> <other srcs> <src>` per source ("This is a hack; replace with something better once the toolchain supports doing so"); `//core:io` is a default dep of `carbon_binary` (:284) |
| 5 | Driver: one object per invocation | LIMIT, measured | compile_subcommand.cpp:43-63 (warning `CompileMultipleInputsWithOutput` unless the last-input-only flag), :71-91 (output only for explicit inputs; a single output goes to the LAST input), :93-116 (no output option → `<stem>.o` beside each source). Measured on the nightly: three-input compile with one output writes only the last object and warns; the flag silences it; a single input plus the flag is silent (exit 0); an output ending in `/` is rejected ("Is a directory") |
| 6 | Driver: package members must share one invocation | LIMIT, measured | `main.carbon` alone: "imported API 'Main//widget' not found" (exit 1); `widget.impl.carbon` alone: "corresponding API for 'Main//widget' not found" (exit 1); all three together exit 0. Separate compilation is only planned (docs/design/code_and_name_organization/README.md:452-454) |
| 7 | Driver: `link` adds prelude objects only | LIMIT, measured | link_driver.cpp:140-151 ("TODO: should also be able to link in the rest of the Core object files"); the runtimes cache holds exactly 30 objects, all `core/prelude*.o`, none defining `_CEOF.Core` or `_CPrintStr.Core`; `core_library_manifest.txt` lists io.carbon and io.impl.carbon; a `Core.PrintStr` program fails under `link` with `undefined symbol: _CPrintStr.Core` and links after adding an object compiled from `<tc>/lib/carbon/core/io.impl.carbon` (W-003's item, :40-54) |
| 8 | Driver: `build` | WORKS for Carbon-only inputs, measured | build_subcommand.cpp:90-98 (hashed temp objects for every unit incl. the 32 Core units), :108-126 (default output = first input's stem); `-o FILE` fails ("requires a value"), `-o=FILE` and `--output=FILE` work; a `.cpp` positional is parsed as Carbon ("unrecognized declaration introducer") despite the help text, C++ objects go after the second `--` |
| 9 | Driver: dependency output | MISSING, measured | `-MD` is "unknown short option"; `-- -MD -MF f.d` and `-- -MMD -MF f.d` exit 0 and write nothing (the C++ import is a `-fsyntax-only` job on a synthesized buffer); `-- -MJ f.json` does write a compile-commands fragment; `carbon clang -- -x c++ -MM` over a synthesized include list works as a side scan |
| 10 | Driver: runtimes cache | WORKS, measured | first `link` on a cold cache 16.9 s wall (builds `$HOME/.cache/carbon_runtimes/runtimes-<ver>-<sha>/{clang_resource_dir,core,libcxx,libunwind}`), warm 0.033 s; `--runtimes-cache=DIR` needs DIR to exist; `build-runtimes --output-directory=DIR` then `--prebuilt-runtimes=DIR` links in 0.041 s (driver.cpp:89-101) |
| 11 | Mixed Carbon/C++ by hand | WORKS, measured | `carbon clang -- -c twice.cpp`, `carbon compile --output=main.o src/main.carbon -- -Iinclude` (byte-identical object with `--clang-arg=-Iinclude`), `carbon link --output=mixed main.o adder.o` → prints 42; archives work both positionally and as `-- -L. -ladder`; `-- -Wl,--gc-sections` passes through |
| 12 | Entry point and exit code | WORKS | `package Main;` is rejected ("`Main//default` must omit `package` declaration", docs/design/README.md:2364-2366); `fn Run() -> i32` with no package line is `main`; `return 3` exits 3 |
| 13 | CMake 3.28 custom-language mechanism | WORKS, prototype measured | Determine/Information/Test modules on `CMAKE_MODULE_PATH` are loaded by `enable_language` in the documented order (Help/command/include.rst:18-22; the trace in scratch build-ninja-trace.txt); the inner `try_compile` project re-reads the outer tree's `CMakeFiles/3.28.3/CMakeCarbonCompiler.cmake` and does not re-run Determine; vendor-regex identification (`CMAKE_DETERMINE_COMPILER_ID_VENDOR`, CMakeDetermineCompilerId.cmake:1096-1155) identifies "Carbon 0.0.0-0.nightly.2026.10.12+62f1cc6" with no CompilerId source. Fresh configure + build of the prototype's hello/geo/mixed: 18.1 s wall under Unix Makefiles, 20.9 s under Ninja (warm runtimes cache; `CARBON=<tc>/bin/carbon` in the environment, `carbon` NOT on PATH), all three run and print `Hello world!`, `12`, `42` |
| 14 | CMake linker-language selection | TRAP, measured | without `CMAKE_Carbon_LINKER_PREFERENCE 40` + `_PROPAGATES 1` a mixed target was linked by clang++ (prototype probe E) — it ran only because that program's Carbon object needed no prelude bodies; with them `carbon link --output=<TARGET> <OBJECTS> -- <LINK_LIBRARIES>` runs (CMAKE_LANG_LINKER_PREFERENCE.rst:8-13; prop_tgt/LINKER_LANGUAGE.rst:6-13) |
| 15 | CMake dependency scanning for an unknown language | ABSENT, measured | Ninja emits `depfile = $DEP_FILE` / `deps = gcc` on the Carbon rule but nothing writes it (`ninja -t deps` shows `#deps 0` for Carbon objects, 63 for the CXX object); Makefiles leave depend.make and compiler_depend.make empty; `OBJECT_DEPENDS` is honoured by both generators (prop_sf/OBJECT_DEPENDS.rst:6-11) and is the only mechanism |
| 16 | System g++ objects under `carbon link` | FAILS, measured | with system g++ as CXX compiler CMake injects `-lstdc++ -lm -lgcc_s -lgcc -lc`, the Clang driver rewrites `-lstdc++` to `-lc++`, `std::__throw_length_error` stays undefined; with the toolchain's clang++ as CXX compiler (`CMAKE_CXX_IMPLICIT_LINK_LIBRARIES "c++;m;unwind;c;unwind"`) the same target links and runs |
| 17 | Conformance stubs | SKIP | project/cmake_build_integration.carbon:5-9 (bullet, EXPECT-EXIT 0, EXPECT-STDOUT `built by CMake-integrated Carbon`, SKIP: "runner.py only runs single .carbon files and cannot drive an external build system ... arbitration must move to the example project's own CI; un-SKIP then"), 35 lines; project/dropin_clang_make_cmake.carbon:5-9 (EXPECT-STDOUT `built by a drop-in Clang build-system example`, SKIP: "Un-SKIP (and move the arbitration to that example's CI) when the CMake example project and Make docs land"), 21 lines; dropin_clang_cpp_toolchain.carbon is the PASSing slice of row 84 |
| 18 | Runner: external-build channel | MISSING | `execute_program` (runner.py:485-610) always issues its own compile/link/run; DIRECTIVE_PREFIXES (:140-146) has five entries; `directive_sync_self_check` (:999-1057) fails on any prefix without an effect-map entry; `generate_program_table` (:753-779) knows the kinds SKIP / multi-unit / differential; `--self-test` is rc 0 today ("150 programs parsed, 56 bullets in table, OK"); timeouts default compile 300 s, link 1800 s, run 30 s (:1536, :1542, :1549) |
| 19 | Hosted runner for the conformance mode | ubuntu-22.04 | .github/workflows/fork_hosted.yaml:38 and :47; the conformance step (:107-160) untars the freshly built toolchain and runs `runner.py --toolchain`; the image ships cmake, GNU make and ninja (GitHub-hosted image contents, not verifiable from here: §7 R-1) |
| 20 | prek hooks on the new file types | KNOWN | check-copyright (.pre-commit-config.yaml:207-266): `.carbon/.cpp/.h` take the `//` block, `.md` the `<!-- -->` block, and CMakeLists.txt, `*.cmake`, `*.cmake.in`, `Makefile`, `*.sh` fall to the builtin hash-comment default (`#` lines, as the config's own header); fix-cc-deps (:61-66) fires on any `.h`/`.cpp` with `pass_filenames: false` and runs `bazel query //...` — skipped locally (`SKIP=fix-cc-deps`), the CI prek is the authority (R22/R23); clang-format 21.1.8 on `.cpp/.h` (R18); rumdl twice + check-google-doc-style + check-links on markdown (R31) |

### §0.2 Ledger and stub claims found stale (each corrected at §8.5 discharge)

1.  **W-060 evidence `fork/gap-analysis.md:69` and `:160-166`** (:1147-1148)
    point at the if-let row and the matching-area workstream paragraph; the
    CMake row is :87 and the §W11 paragraph is :261-273. The stub citation
    `cmake_build_integration.carbon:5` is the bullet line; the SKIP line is :9.
2.  **W-061 evidence `dropin_clang_make_cmake.carbon:5`** (:1161) is likewise
    the bullet line; the SKIP is :9.
3.  **W-002 evidence `runner.py:503-524`** (:28) now spans the per-unit compile
    loop's comment plus the first half of the loop (:508-535); re-pinned to the
    `execute_program` entry at discharge.
4.  **Both SKIP lines say the arbitration "must move to the example project's
    own CI".** There is no separate CI for examples (Actions is disabled and
    the fork never had an examples workflow); the honest channel is the
    conformance runner driving the example's script (D-CM-14), so the
    scoreboard — not a workflow badge — stays the single arbiter (R9).
5.  **The CMake stub's EXPECT-STDOUT names one marker line** for "the
    program such an example would build". The example builds three programs
    (D-CM-11); the EXPECT block grows to their five hand-derived lines (§5).
    The bullet line is untouched (R7).
6.  **The drop-in stub's body** (`Cpp.std.cout <<` from Carbon through
    `import Cpp library "<iostream>"`) is replaced by the example's mixed main
    unit (C++ prints the marker; Carbon prints 42), so the un-SKIPped program
    is byte-identical to a file the script builds (D-CM-14's identity rule).
    Disclosed in the program header per R6's F8d template.
7.  **W-003's note** says the Bazel rule and `carbon build` link the Core
    objects and "extending link_driver.cpp's object search flips the SKIP";
    still true, and CMake now has its own measured workaround
    (`Carbon::core_io`, D-CM-7) — W-003's notes gain that sentence; it stays
    OPEN (toolchain item).
8.  **The W11 arbiter paragraph** (:261-273) bundles the evaluator tutorial
    ("a docs/guides getting-started tutorial an evaluator can follow") with the
    CMake/Make deliverables; the tutorial is W-062 and stays open; the
    paragraph is rewritten to say which halves landed.
9.  **The house hand-off note placed the modules at `examples/cmake/cmake/`.**
    This plan places them at a top-level `cmake/` directory (D-CM-2) — the
    task's wording and the install analogy with `bazel/` (toolchain/install
    ships `bazel/*.bzl` under lib/carbon/, toolchain/install/BUILD:321-375) —
    and records the deviation here.

## §1 Design

**Terms used throughout (amended 2026-10-12, review fold: rev 2 F5).** The
_toolchain directory_ is the unpacked tarball directory, the parent of
`bin/carbon`; it is what `CARBON_TOOLCHAIN` names in the example's CMakeLists,
the Makefile, test.sh and the runner's environment. The _install root_ is
`INSTALL_ROOT` from `carbon config --json`, which on the nightly is `<toolchain
directory>/lib/carbon/` (measured: `"INSTALL_ROOT":
".../carbon_toolchain-0.0.0-0.nightly.2026.10.12/lib/carbon/"`); it is what
`CMAKE_Carbon_INSTALL_ROOT` holds, so `core/io.carbon` is
`${CMAKE_Carbon_INSTALL_ROOT}/core/io.carbon` and NOT `<toolchain
directory>/core/io.carbon`. `bin/carbon` is a symlink to
`../lib/carbon/carbon-busybox`, so a REALPATH of it lands inside the install
root and needs three `PATH` steps, not two, to reach the toolchain directory.

### §1.A The shape: genuine language support plus a package helper layer

**Chosen: genuine CMake language support (four modules reached through
`CMAKE_MODULE_PATH`) PLUS a small helper file (`CarbonTargets.cmake`) with
`carbon_add_executable`, `carbon_add_library` and `carbon_add_core_library`.**
Rejected: a functions-only layer over `add_custom_command` (`carbon build`),
and language support with no helpers.

Why language support: `project(... LANGUAGES Carbon)` makes `.carbon` sources
first-class — per-config flags, `target_include_directories` and
`target_compile_definitions` reaching the embedded Clang, `OBJECT`/`STATIC`
libraries, `target_link_libraries`, `$<TARGET_OBJECTS:...>`, `LINKER_LANGUAGE`,
install/export — all without any generator-specific code (§0.1 row 13; Swift
and Fortran are the only languages with generator-specific support,
Help/generator/Ninja.rst:51-60, and their placeholders are compiled into
CMake, so a custom language cannot have whole-module rules). The custom-command
route produces no objects a library target can own (the driver writes one
object per invocation, §0.1 row 5), tracks only what `DEPENDS` lists, and
cannot express a library consumed by another target.

Why helpers are needed: the driver demands every file of a package on one
command line (§0.1 row 6) while CMake compiles one `<SOURCE>` per rule. The
helper reconciles them exactly as Bazel does (§0.1 row 4): each source's
command line carries all sibling package files and the API files of the
packages it depends on, the object is the LAST input, and `OBJECT_DEPENDS`
makes the object rebuild when any of them changes. The rule keeps `<FLAGS>`
before `--output=<OBJECT> <SOURCE>` so per-source `COMPILE_OPTIONS` land
before the source (positional inputs before options are accepted; sibling
order is immaterial — Check orders units by import dependency, runner.py:35-40).

### §1.B Objects and linking, by target kind (all measured in §0.1)

1.  **A Carbon executable** (`add_executable(hello hello/hello.carbon)` or
    `carbon_add_executable(name SOURCES ...)`): each unit → one object by
    `carbon compile <DEFINES> <INCLUDES> <FLAGS> --output-last-input-only
    --output=<obj> [siblings...] <unit>`; link by `carbon link
    --output=<TARGET> <objects> -- <LINK_FLAGS> <LINK_LIBRARIES>`, which adds
    the 30 prelude objects and the toolchain runtimes itself. `Core.PrintStr`
    and `Core.EOF` live in io.impl.carbon and are NOT added by `link` (row 7),
    so an executable using them links `Carbon::core_io` (D-CM-7).
2.  **A Carbon library consumed by another target**
    (`carbon_add_library(widget STATIC SOURCES widget.carbon
    widget.impl.carbon)`): the two objects (`widget.carbon.o` — API only, no
    symbols; `widget.impl.carbon.o` defining `_CGet.Main`) are archived by
    `<CMAKE_AR> qc` + `<CMAKE_RANLIB>` (plain ELF objects; the system `ar`
    and `llvm-ar` both work). A consumer declares `DEPS widget`, which (a)
    puts the library's API files (every non-`.impl.carbon` source, published
    through the target property `CARBON_API_FILES`) on the consumer's compile
    lines and in its `OBJECT_DEPENDS`, and (b) `target_link_libraries` the
    archive, which reaches `carbon link` positionally after `--`. `OBJECT`
    libraries work the same way with `$<TARGET_OBJECTS:widget>`. Shared
    libraries are NOT supported: `carbon link` says "TODO: Support linking
    binary libraries, both archives and shared libraries", and
    `CMAKE_Carbon_CREATE_SHARED_LIBRARY` and `_CREATE_SHARED_MODULE` are set
    to the failing command `<CMAKE_COMMAND> -E false`, so `add_library(x
    SHARED a.carbon)` configures but fails at build time under both
    generators with no file produced (W-132). Leaving the variable undefined
    is NOT enough: only the Makefiles generator reports "required internal
    CMake variable not set" at generate time, while Ninja generates a
    `Carbon_SHARED_LIBRARY_LINKER` rule whose command is `$PRE_LINK &&
    $POST_BUILD` (`: && :`), prints "Linking Carbon shared library
    libbad.so" and exits 0 without writing it (measured; amended
    2026-10-12, review fold: rev 2 F2).
3.  **A mixed Carbon + C++ target** — `add_executable(mixed
    mixed/main.carbon)` with `target_link_libraries(mixed PRIVATE twice)`,
    where `twice` is a C++ STATIC library: C++ is compiled by CMake's CXX
    compiler, which the example pins to the toolchain's drop-in
    `lib/carbon/llvm/bin/clang++` (identified as Clang 24; D-CM-8); the Carbon
    unit's `import Cpp library "twice.h"` resolves because
    `CMAKE_INCLUDE_FLAG_Carbon` is `--clang-arg=-I` and the C++ library's
    PUBLIC include directory propagates; the linker language is Carbon by
    preference (40 > CXX's 30, propagating through the static library), so
    `carbon link` links Carbon objects, the C++ archive and the CXX implicit
    libraries (`c++;m;unwind;c;unwind`, tolerated). Objects built by a system
    g++ do NOT link this way (row 16) — a documented 0.1 limit (W-131), with
    the measured by-path workaround in the docs.

### §1.C Decisions this plan auto-adopts (R29(a); each with a break condition)

-   **D-CM-1 — Shape: language modules + `CarbonTargets.cmake` helpers
    (§1.A).** Break condition: the driver gains multi-output or separate
    compilation (compile_subcommand.cpp:45-46 TODO) — then the helper's
    sibling wiring is deleted and `carbon_add_library` becomes a thin alias;
    or the hosted runner's CMake refuses the module set (the configure log is
    the evidence) — then §7 R-2's contingency.
-   **D-CM-2 — Module home is a top-level `cmake/` directory:**
    `cmake/CMakeDetermineCarbonCompiler.cmake`,
    `cmake/CMakeCarbonCompiler.cmake.in`, `cmake/CMakeCarbonInformation.cmake`,
    `cmake/CMakeTestCarbonCompiler.cmake`, `cmake/CarbonTargets.cmake`,
    `cmake/README.md`. Reached by `list(APPEND CMAKE_MODULE_PATH
    <checkout>/cmake)`; the example does so relative to itself. Upstream has no
    `cmake/` directory (row 1), so the weekly merge sees no conflict (V-3a).
    Installing them into the toolchain tree (`lib/carbon/cmake/` beside the
    Bazel files, with a `CarbonConfig.cmake` for `find_package(Carbon CONFIG)` —
    the scratch `fp/` probe verified both `<prefix>/lib/carbon/cmake/` and
    `<prefix>/lib/cmake/Carbon/` are found) needs a toolchain/install/BUILD
    change that cannot be built or tested here: filed as W-128, not landed.
    Break condition: W-128 lands — the example switches to `find_package(Carbon
    CONFIG)` and the relative module path goes.
-   **D-CM-3 — Compiler discovery and identification.** Order: the
    `CMAKE_Carbon_COMPILER` cache entry (list form splits into compiler +
    `CMAKE_Carbon_COMPILER_ARG1`, `_cmake_find_compiler_path`,
    CMakeDetermineCompiler.cmake:115-153), the `CARBON` environment variable
    (`CMAKE_Carbon_COMPILER_ENV_VAR "CARBON"`, so CMake's own not-found
    message names it), then `find_program` over `carbon;carbon-busybox`
    (`_cmake_find_compiler`, :5-113).
    Identification by `CMAKE_DETERMINE_COMPILER_ID_VENDOR(Carbon "")` with
    vendor `Carbon`, flag `version`, regex `Carbon Language toolchain version:
    ([0-9][^ \r\n]*)`; the match becomes `CMAKE_Carbon_COMPILER_VERSION`. No
    CompilerId source file. `carbon config --json` is parsed with `string(JSON
    ...)` for `CMAKE_Carbon_INSTALL_ROOT` and `CMAKE_Carbon_LLVM_BINDIR`, which
    the template persists; `llvm-ar` and `llvm-ranlib` from that bindir are
    recorded as `CMAKE_Carbon_COMPILER_AR/RANLIB` (advanced, informational), and
    the generic `CMakeFindBinUtils` pass sets `CMAKE_AR/RANLIB/LINKER`. The
    example's CMakeLists additionally honours a `CARBON_TOOLCHAIN` cache entry
    or environment variable (the toolchain directory, §1 terms) BEFORE
    `project()` and seeds both `CMAKE_Carbon_COMPILER` (`<dir>/bin/carbon`) and
    `CMAKE_CXX_COMPILER` (`<dir>/lib/carbon/llvm/bin/clang++`) unless the user
    set them; with neither, it resolves `carbon` from PATH through its symlink
    (REALPATH, then three `PATH` steps: busybox → `lib/carbon` → `lib` → the
    toolchain directory; amended 2026-10-12, review fold: rev 2 F4, F5).
    `CMAKE_Carbon_INSTALL_ROOT` is the install root (`<dir>/lib/carbon/`), a
    different directory. Break condition: the version line's format changes
    (then the regex) or `carbon config --json` loses a key (then the configure
    error names it).
-   **D-CM-4 — Compile rule.** `CMAKE_Carbon_COMPILE_OBJECT` is
    `<CMAKE_Carbon_COMPILER> compile <DEFINES> <INCLUDES> <FLAGS>
    --output-last-input-only --output=<OBJECT> <SOURCE>`; the last-input-only
    flag is in the rule itself (silent for one input, row 5) so that
    hand-written `COMPILE_OPTIONS` sibling lists work without the helper.
    `CMAKE_INCLUDE_FLAG_Carbon "--clang-arg=-I"`, `CMAKE_Carbon_DEFINE_FLAG
    "--clang-arg=-D"`, `CMAKE_Carbon_OUTPUT_EXTENSION .o`,
    `CMAKE_Carbon_SOURCE_FILE_EXTENSIONS carbon` (CMake keys on the last
    extension, so `.impl.carbon` is "carbon"), ignore extensions
    `h;H;o;O;obj;OBJ;def;DEF;rc;RC`. Break condition: the driver removes the
    flag (its help calls it a "temporary workaround"); then the rule drops it
    and the helper's `COMPILE_OPTIONS` become the only multi-input shape.
-   **D-CM-5 — Link rules.** `CMAKE_Carbon_LINK_EXECUTABLE` is
    `<CMAKE_Carbon_COMPILER> link <CMAKE_Carbon_LINK_FLAGS> --output=<TARGET>
    <OBJECTS> -- <LINK_FLAGS> <LINK_LIBRARIES>`; `<FLAGS>` is deliberately
    omitted because `CMAKE_Carbon_FLAGS` are compile options
    (`--optimize=...` is not a `link` option; CMAKE_LANG_FLAGS.rst:4-7 says
    the flags reach link lines too). Everything after `--` is Clang-driver
    syntax, so `CMAKE_Carbon_LIBRARY_PATH_FLAG "-L"`,
    `CMAKE_Carbon_LINK_LIBRARY_FLAG "-l"`, wrapper flag `-Wl,` with separator
    `,`, rpath flags `-Wl,-rpath,` / `-Wl,-rpath-link,`. Archives:
    `CMAKE_Carbon_ARCHIVE_CREATE "<CMAKE_AR> qc <TARGET> <LINK_FLAGS>
    <OBJECTS>"`, `_APPEND "<CMAKE_AR> q ..."`, `_FINISH "<CMAKE_RANLIB>
    <TARGET>"` (CMakeCInformation.cmake:173-181 shape). Linker preference 40
    with `_PROPAGATES 1` (row 14). `CMAKE_Carbon_CREATE_SHARED_LIBRARY` and
    `CMAKE_Carbon_CREATE_SHARED_MODULE` are `<CMAKE_COMMAND> -E false`
    (`cmake -E false` exists in 3.28 and exits 1, measured), so a shared
    target fails at build time under both generators instead of succeeding
    silently under Ninja (W-132; amended 2026-10-12, review fold: rev 2 F2).
    Break condition: `carbon link` learns shared libraries
    (the help text's TODO goes) — then the C reference rule with
    `<SONAME_FLAG><TARGET_SONAME>` routed through `carbon clang -- -shared`.
-   **D-CM-6 — Whole-package helpers.** `carbon_add_executable(<name> SOURCES
    <files...> [DEPS <carbon libs...>])`, `carbon_add_library(<name>
    [STATIC|OBJECT] SOURCES <files...> [DEPS ...] [NO_CORE])`. The private
    `_carbon_wire_package` sets, per source, `COMPILE_OPTIONS` = the dep API
    files + the other sources of the package, and `OBJECT_DEPENDS` = the same
    list (absolute paths; `TARGET_DIRECTORY <target>` scope); API files are
    the sources not ending in `.impl.carbon`; the target property
    `CARBON_API_FILES` publishes the package's own API files plus its deps'
    (transitive); `DEPS` also `target_link_libraries` them (PUBLIC for
    libraries, PRIVATE for executables). `NO_CORE` adds
    `--no-include-carbon-core` (for Core's own sources only). Documented
    limits, each filed: every unit of a package re-parses the whole package
    (O(N²), W-130); source-file properties are per directory, so one `.carbon`
    file shared by two packages in one CMakeLists directory gets both sibling
    lists appended — the helper FATAL_ERRORs when a source already carries a
    `CARBON_PACKAGE` source property from another target (W-130's note).
    Break condition: same as D-CM-1.
-   **D-CM-7 — Core io through `Carbon::core_io`.**
    `carbon_add_core_library(io)` builds the STATIC target `carbon_core_io`
    (alias `Carbon::core_io`) from `${CMAKE_Carbon_INSTALL_ROOT}/core/io.carbon`
    and `io.impl.carbon` (the install root is `<toolchain
    directory>/lib/carbon/`, §1 terms) with `NO_CORE` (without it: "library's
    API previously provided by .../io.carbon"); the function reads
    `core_library_manifest.txt` to learn the library's files and errors if the
    library is not listed. Executables that call `Core.PrintStr`/`Core.EOF` link
    it explicitly (mirrors Bazel's default `//core:io` dep, defs.bzl:284, made
    explicit because a module cannot add link inputs to targets it does not
    own). W-003 is the toolchain fix; its notes gain this workaround. Break
    condition: `carbon link` of an object that references `_CPrintStr.Core`
    succeeds without the archive on a nightly — then the helper becomes a no-op
    that warns, and the example's `target_link_libraries(... Carbon::core_io)`
    lines go.
-   **D-CM-8 — Mixed targets default to the drop-in toolchain: Route A.** The
    C++ half is compiled by `<root>/lib/carbon/llvm/bin/clang++` (set by the
    example before `project()`, overridable), the link is `carbon link`.
    Route B (system g++ drives the link with the prelude objects passed
    explicitly from `carbon build-runtimes --output-directory`, prototype
    `Carbon::prelude`, 32 s at configure) is NOT landed: it adds a 32 s
    configure step and an untested path to the module; filed as W-131 with the
    measured failure mode of g++ objects under `carbon link` (row 16) and the
    by-path workaround (`-- /usr/lib/x86_64-linux-gnu/libstdc++.so.6`)
    documented. Break condition: an evaluator needs g++-built objects — W-131
    lands `Carbon::prelude` as an opt-in function.
-   **D-CM-9 — No depfile; header dependencies are explicit.** No
    `CMAKE_DEPFILE_FLAGS_Carbon`, no `CMAKE_Carbon_DEPFILE_FORMAT` (row 9, row
    15). The example lists `mixed/twice.h` in `OBJECT_DEPENDS` of
    `mixed/main.carbon` and the docs say so; filed as W-129 (toolchain:
    `-MD`-style output for `import Cpp` headers; the `carbon clang -- -x c++
    -MM` side-scan is the measured interim). Break condition: the driver
    writes a `.d` file for `--clang-arg=-MD --clang-arg=-MF` — then
    `CMAKE_DEPFILE_FLAGS_Carbon "--clang-arg=-MD --clang-arg=-MT
    --clang-arg=<DEP_TARGET> --clang-arg=-MF --clang-arg=<DEP_FILE>"` plus
    `CMAKE_Carbon_DEPFILE_FORMAT gcc` and `CMAKE_Carbon_DEPENDS_USE_COMPILER
    TRUE` (the NASM wiring, CMakeASM_NASMInformation.cmake:41-50).
-   **D-CM-10 — Flags and configurations.** `CMAKE_Carbon_FLAGS_INIT` seeded
    from `$ENV{CARBONFLAGS}`; `_DEBUG_INIT "--optimize=none"`,
    `_RELEASE_INIT "--optimize=speed --no-debug-info"`, `_RELWITHDEBINFO_INIT
    "--optimize=speed"`, `_MINSIZEREL_INIT "--optimize=size --no-debug-info"`
    (`carbon help compile`: optimize none|debug|speed|size; `--no-debug-info`);
    `cmake_initialize_per_config_variable` creates the cache entries;
    `include(CMakeCommonLanguageInclude)` seeds the linker-flag variables from
    `LDFLAGS`. Break condition: an optimize level is renamed — the flag table
    is one place.
-   **D-CM-11 — The example project** `examples/cmake/`: `README.md`,
    `CMakeLists.txt`, `Makefile`, `test.sh`, `hello/hello.carbon`,
    `widget/widget.carbon`, `widget/widget.impl.carbon`, `widget/main.carbon`,
    `mixed/main.carbon`, `mixed/twice.h`, `mixed/twice.cpp`. No BUILD file
    (row 3: invisible to Bazel, so buildifier/check-bazel-mod-deps/
    check-build-graph stay quiet; a Bazel-side integration test of the example
    is part of W-128's residue). Markers, hand-derived (R16(d)): `hello`
    prints `built by CMake-integrated Carbon` (`Core.PrintStr`); `widget_main`
    prints `widget package built by CMake-integrated Carbon` then `7`
    (`Core.Print(Get())`, `Get` returns the literal 7 from the impl file);
    `mixed` prints `built by a drop-in Clang build-system example` from C++
    (`std::cout`, compiled by the drop-in clang++) then `42` (`Core.Print
    (Cpp.Twice(21))`, `Twice` returns `2 * n`). Both stub markers survive
    verbatim. Break condition: none needed — the file set is the plan's
    deliverable; a reviewer rename is a mechanical edit.
-   **D-CM-12 — `examples/cmake/test.sh` is the arbiter script.** Contract:
    `test.sh [--build-dir DIR] [--only TARGET]... [--no-ninja] [--no-make]`;
    toolchain from `CARBON_TOOLCHAIN` (the toolchain directory, §1 terms), else
    `CARBON` (a path to `bin/carbon`; the directory is its parent's parent, as
    the Makefile derives it), else `carbon` on PATH (amended 2026-10-12, review
    fold: rev 2 F5, F7); build dir from `--build-dir`, else `CARBON_BUILD_DIR`,
    else a fresh `mktemp -d`. It configures and builds `examples/cmake` with the
    `Unix Makefiles` generator (always), with `Ninja` when `ninja` is on PATH (a
    one-line stderr note when it is not; `--no-ninja` skips it), and the
    checked-in `Makefile` with GNU make (`make CARBON_TOOLCHAIN=<dir> O=<build
    dir>/make all`; the Makefile assigns `CXX :=` itself, F1; `--no-make` skips
    it); it runs the selected programs (default: hello, widget_main, mixed, in
    that order) from each build, checks every exit code is 0, requires the three
    builds' outputs to be byte-identical, and prints the Unix-Makefiles build's
    concatenated run output — nothing else — on stdout; all configure/build
    chatter goes to stderr. Exit codes: 0 success, 2 configure or compile
    failed, 3 link failed (the CMake `--build` step cannot tell compile from
    link, so a failed `cmake --build` is 2 unless its log contains `ld.lld:
    error` or `linker command failed`, then 3; the plain-Makefile build uses
    separate `objects` and `link` make targets, so the stage is known), 4 a
    program exited non-zero or did not run, 5 the variants' outputs differ, 64
    usage, 66 toolchain not found. The hosted runner has no `ninja` guarantee;
    stdout is the same with or without it. Break condition: a reviewer shows a
    deterministic-stdout violation (then the script prints each variant's output
    under a `--verbose` flag to stderr only).
-   **D-CM-13 — Make documentation lives at `docs/guides/build_systems.md`**
    (docs/guides is "end-user documentation on how to use Carbon",
    docs/guides/README.md:9-12), listed in docs/guides/README.md, with a
    one-sentence pointer appended to README.md's "Getting started" (:273-317 —
    the only upstream-owned file this plan touches; a one-line hunk). The Make
    section shows the explicit rules for the same three programs
    (`compile --output-last-input-only`, the `io.impl.carbon` object, `clang++
    -c`, `link --output`) and the checked-in `examples/cmake/Makefile` is
    those rules verbatim — including the variable block (`CXX :=`, not
    `?=`: `CXX`, `CC` and `AR` are GNU make builtins with origin `default`,
    which `?=` treats as already set; `make -p -f /dev/null` prints `CXX =
    g++`), the `$(O)` directory rule and the order-only prerequisites
    (amended 2026-10-12, review fold: rev 2 F1, F3, F7); test.sh builds it;
    drift fails the arbiter. The
    `carbon build` alternative is shown with its two caveats (row 8; W-133).
    Break condition: upstream ships a build-systems guide — the fork page is
    merged into it at the weekly merge.
-   **D-CM-14 — Arbitration: a `// BUILD-SCRIPT:` directive in runner.py
    (Option A), never a fake un-SKIP.** The directive names a repository-root-
    relative script and optional arguments (whitespace-split, like
    `COMPILE-ARGS`). For such a program the runner issues no compile/link/run
    of its own: it runs the script from the repository root with
    `CARBON_TOOLCHAIN=<toolchain directory>` (derived from the `--toolchain`
    path by the same two layouts `find_clangxx` probes, runner.py:431-451,
    falling back to the binary's own directory when neither layout has
    `lib/carbon` — the stub-toolchain fixtures; amended 2026-10-12, review
    fold: rev 2 F5, F8), `CARBON=<the --toolchain path>` and
    `CARBON_BUILD_DIR=<out>/build/<name>`, under the link timeout (R4: the
    first `carbon link` builds the runtimes), then applies `EXPECT-EXIT` to
    the script's exit code and `EXPECT-STDOUT` to its stdout unchanged. Status
    mapping uses existing classes only (the W69h precedent): exit 2 →
    COMPILE-FAIL, 3 → LINK-FAIL, any other non-zero → RUN-FAIL (detail: "build
    script exited with N"), timeout → RUN-FAIL, stdout mismatch →
    OUTPUT-MISMATCH. Guard rails (DirectiveError): `BUILD-SCRIPT` with
    `COMPILE-ARGS`, in a multi-unit program, or with a `.diff.cpp` sibling;
    the script must exist and be executable. `--self-test` additionally
    enforces the identity rule: the program's body (everything after the
    leading comment block) must be byte-identical to the body of exactly one
    `.carbon` file under the script's directory tree — so the promoted program
    IS a file the script builds, and drift fails the self-test. Both stubs
    un-SKIP through this channel; the bullet lines stay byte-identical (R7).
    Fallback (Option B) if the channel is refuted by review or by the hosted
    runner lacking cmake: keep the SKIP, rewrite its reason per R10 to name
    `examples/cmake/test.sh`, the nightly version, the command and the
    observed output; the rows then read PARTIAL ("arbitration channel open,
    W-002 (3)") — never DONE under R9. Break condition: the hosted conformance
    run reports COMPILE-FAIL with "cmake: command not found" in the log — that
    is the Option B trigger, recorded in the decision log.
-   **D-CM-15 — Row 84 flips in the same PR.** `dropin_clang_make_cmake.carbon`
    un-SKIPs on exactly this landing (its SKIP line says so, §0.1 row 17); the
    example's C++ half is built by the drop-in clang++ under CMake
    (`CMAKE_CXX_COMPILER`) and under the Makefile (its `CXX :=` assignment —
    a `?=` would be a no-op against make's builtin `g++`, F1), which is the
    row's missing evidence ("nothing exercises or documents them under CMake or
    Make", :84). R29(b)'s one-PR-per-feature is honoured: this is one feature
    (build-system integration) with two bullets, and the drop-in hunk is a
    separable part of commit 2 if vetoed. Header counts 30/21/4/1 →
    32/20/3/1, stated as expected; each flipped row's evidence cell carries
    the literal phrase "not of record" and the decision-log entry says
    R9's record is outstanding with no dispatch date (§5; amended
    2026-10-12, review fold: rev 2 F9). Break condition: owner veto —
    commit 2's drop-in hunk is reverted and W-061 stays OPEN.
-   **D-CM-16 — Ledger ids W-128.. on the recorded ASSUMPTION that PR 51
    (W-126/W-127) merges first**, verified at merge (the `source` precedent).
    Filed: W-128 modules not installed in the toolchain tree / no
    `find_package(Carbon)` / no Bazel-side test of the example; W-129 no
    dependency output from `carbon compile`; W-130 whole-package compile model
    (O(N²) re-parsing, per-directory source properties, single-output
    compile); W-131 system-g++-built objects under `carbon link` (Route B not
    landed); W-132 no shared libraries / binary-library linking in `carbon
    link`; W-133 `carbon build` help claims `.cpp` inputs but rejects them,
    its short `-o` works only as `-o=FILE`, and `carbon help link` says
    EXTRA_CLANG_LINK_ARGS may carry object files intermingled with linker
    flags while `carbon link --output=x -- a.o b.o -lc++` fails with
    `error: no such file or directory: '-lc++'` (measured on the nightly;
    the positional form `carbon link --output=x a.o b.o -- -lc++` links,
    and every Make and CMake rule of this plan uses it; amended
    2026-10-12, review fold: rev 2 F10). W-060 and W-061 → DISCHARGED
    (evidence re-pinned); W-002 notes gain "(3) answered for external builds";
    W-003 notes gain the CMake workaround. Break condition: PR 51 is closed
    unmerged — the ids renumber from W-126 at this PR's merge.
-   **D-CM-17 — Out of scope, disclosed:** `CMAKE_Carbon_COMPILER_TARGET` /
    cross-compiling (only `--target=aarch64-unknown-linux-gnu` object
    generation was measured, not linking), `CMAKE_Carbon_COMPILER_LAUNCHER`
    (CMake applies it only to its listed languages,
    CMAKE_LANG_COMPILER_LAUNCHER.rst:6-9), Windows (V-1; the toolchain's own
    runtimes are "untested and not yet supported" there), and macOS
    verification (no macOS host here; the modules contain nothing
    Linux-specific except the rpath flags guarded by `CMAKE_SYSTEM_NAME`).
    Each is named in the docs' limits table and in W-128's or W-130's notes
    rather than as its own item. Break condition: a reviewer asks for an
    item — allocate the next id.

## §2 Implementation spec, file by file

### §2.A `cmake/` (new, five files + README)

1.  **cmake/CMakeDetermineCarbonCompiler.cmake** — the scratch prototype
    `Modules/CMakeDetermineCarbonCompiler.cmake` with the `#` license header
    added, plus: a comment block naming the CMake modules it mirrors
    (CMakeDetermineASMCompiler.cmake:9-19, :42, :49-51, :54-131, :216-221,
    :264-265); the not-found FATAL_ERROR text lists the three ways
    (`CMAKE_Carbon_COMPILER`, `CARBON`, PATH); `string(JSON ...)` reads are
    guarded (`ERROR_VARIABLE` → empty values, no fatal) so a future nightly
    without a key still configures; `mark_as_advanced` on the AR/RANLIB
    records.
2.  **cmake/CMakeCarbonCompiler.cmake.in** — the prototype template verbatim
    (compiler, ARG1, ID, VERSION, INSTALL_ROOT, LLVM_BINDIR, COMPILER_AR/RANLIB,
    CMAKE_AR/RANLIB/LINKER, `COMPILER_LOADED 1`, `COMPILER_WORKS`,
    `COMPILER_ENV_VAR "CARBON"`, `COMPILER_ID_RUN 1`, source/ignore
    extensions, `LINKER_PREFERENCE 40`, `_PROPAGATES 1`) with the header.
3.  **cmake/CMakeCarbonInformation.cmake** — the prototype plus D-CM-4's
    rule change (the last-input-only flag moves into the rule) and D-CM-10's
    flag table; `CMAKE_Carbon_CREATE_SHARED_LIBRARY` and
    `CMAKE_Carbon_CREATE_SHARED_MODULE` set to `"<CMAKE_COMMAND> -E false"`
    with a comment citing W-132 and the Ninja silent-success measurement
    (F2); `set(CMAKE_Carbon_INFORMATION_LOADED 1)` last.
4.  **cmake/CMakeTestCarbonCompiler.cmake** — the prototype verbatim
    (`CMAKE_Carbon_COMPILER_FORCED` early return; `try_compile` with
    `SOURCE_FROM_VAR testCarbonCompiler.carbon` of `fn Run() -> i32 { return
    0; }`; FATAL_ERROR with the output; re-`configure_file` + `include` to
    record `COMPILER_WORKS`).
5.  **cmake/CarbonTargets.cmake** — `include_guard(GLOBAL)`;
    `_carbon_wire_package` (D-CM-6, with the `CARBON_PACKAGE` source-property
    collision check and absolute-path normalization),
    `carbon_add_library`, `carbon_add_executable`, `carbon_add_core_library`
    (D-CM-7, manifest-driven); no prelude-target function (D-CM-8). The
    sibling `COMPILE_OPTIONS` no longer carry the last-input-only flag
    (D-CM-4).
6.  **cmake/README.md** — what the directory is, how to use it
    (`CMAKE_MODULE_PATH`, `project(... LANGUAGES Carbon)`), a pointer to
    docs/guides/build_systems.md and examples/cmake/, and the W-128 install
    note. Links are relative and resolve (check-links).

### §2.B `examples/cmake/` (new, eleven files)

1.  **CMakeLists.txt** — `cmake_minimum_required(VERSION 3.28)`; the
    toolchain-location block of D-CM-3 (cache `CARBON_TOOLCHAIN` → env →
    `find_program(carbon)` resolved with `get_filename_component(... REALPATH)`
    to `<dir>/lib/carbon/carbon-busybox` and THREE `PATH` steps up — two
    yield `<dir>/lib`; measured with only `PATH=<dir>/bin` set, three steps
    resolve `CMAKE_Carbon_COMPILER` to `<dir>/bin/carbon` and
    `CMAKE_CXX_COMPILER` to `<dir>/lib/carbon/llvm/bin/clang++`; amended
    2026-10-12, review fold: rev 2 F4); `list(APPEND
    CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake")`;
    `project(carbon_cmake_example LANGUAGES Carbon CXX)`;
    `include(CarbonTargets)`; `carbon_add_core_library(io)`; `add_executable
    (hello hello/hello.carbon)` + `target_link_libraries(hello PRIVATE
    Carbon::core_io)`; `carbon_add_library(widget STATIC SOURCES
    widget/widget.carbon widget/widget.impl.carbon)`; `carbon_add_executable
    (widget_main SOURCES widget/main.carbon DEPS widget)` +
    `target_link_libraries(widget_main PRIVATE Carbon::core_io)`;
    `add_library(twice STATIC mixed/twice.cpp)` + `target_include_directories
    (twice PUBLIC mixed)`; `add_executable(mixed mixed/main.carbon)`;
    `set_source_files_properties(mixed/main.carbon PROPERTIES OBJECT_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/mixed/twice.h")`; `target_link_libraries(mixed
    PRIVATE twice)`. Every line is one the docs quote.
2.  **hello/hello.carbon** — license header, then:

    ```carbon
    import Core library "io";

    fn Run() -> i32 {
      Core.PrintStr("built by CMake-integrated Carbon\n");
      return 0;
    }
    ```

3.  **widget/widget.carbon** — `library "widget";` then `fn Get() -> i32;`
    (the Main package's `widget` library; measured in scratch pkg/).
    **widget/widget.impl.carbon** — `impl library "widget";` then `fn Get()
    -> i32 { return 7; }`. **widget/main.carbon** — `import Core library
    "io"; import library "widget";` and a `Run` that calls
    `Core.PrintStr("widget package built by CMake-integrated Carbon\n")` then
    `Core.Print(Get())` and returns 0.
4.  **mixed/twice.h** — `int Twice(int n);` and `void PrintMarker();` with
    include guards. **mixed/twice.cpp** — `#include "twice.h"` and
    `<iostream>`; `Twice` returns `2 * n`; `PrintMarker` writes `built by a
    drop-in Clang build-system example\n` to `std::cout` (formatted by
    clang-format 21.1.8, R18). **mixed/main.carbon** — `import Core library
    "io"; import Cpp library "twice.h";` and a `Run` that calls
    `Cpp.PrintMarker()` then `Core.Print(Cpp.Twice(21))` and returns 0 (the
    scratch probe/main.carbon shape, measured).
5.  **Makefile** — GNU make, `#` header; variable block (amended 2026-10-12,
    review fold: rev 2 F1, F3, F7): `CARBON_TOOLCHAIN` is the toolchain
    directory (§1 terms); when it is not given it is derived from `CARBON` (`$(abspath
    $(dir $(CARBON))..)`), and when neither is given the Makefile stops with
    `$(error ...)`; `CARBON := $(CARBON_TOOLCHAIN)/bin/carbon` in the `else`
    branch (implementation review fold, CM-1 F1: `?=` let an exported `CARBON`
    override the explicit directory); `CXX :=
    $(CARBON_TOOLCHAIN)/lib/carbon/llvm/bin/clang++` — `:=`, never `?=`, because
    `CXX`, `CC` and `AR` are GNU make builtins (origin `default`; `make -p -f
    /dev/null` prints `CXX = g++`), so a `?=` never assigns them and the mixed
    link then fails with `ld.lld: error: undefined symbol: std::cout` (the rev 1
    text reproduced exactly that); a command-line `make CXX=...` still overrides
    a `:=`; `CORE := $(CARBON_TOOLCHAIN)/lib/carbon/core`; `O ?= build-make`
    (all outputs under `$(O)`, which the `$(O)` rule creates and every object
    rule lists as an order-only prerequisite, so a fresh `O=` keeps the source
    tree clean; the default `build-make/` is git-ignored); targets `all` (the
    three programs), `objects`, `link`, `run`, `clean`; the variable block and
    the explicit rules, verbatim (measured at the rev 2 fold: §4.5):

    ```make
    # Toolchain directory: the unpacked tarball, the parent of bin/carbon. An
    # explicit CARBON_TOOLCHAIN wins over an exported CARBON, so every tool comes
    # from one toolchain; `:=` still yields to a command-line `make CARBON=...`.
    ifeq ($(origin CARBON_TOOLCHAIN),undefined)
      ifeq ($(origin CARBON),undefined)
        $(error set CARBON_TOOLCHAIN=<toolchain directory> or CARBON=<path to bin/carbon>)
      endif
      CARBON_TOOLCHAIN := $(abspath $(dir $(CARBON))..)
    else
      CARBON := $(CARBON_TOOLCHAIN)/bin/carbon
    endif
    # CXX, CC and AR are GNU make builtins (origin "default"), so `?=` would
    # keep g++; `:=` still yields to a command-line `make CXX=...`.
    CXX := $(CARBON_TOOLCHAIN)/lib/carbon/llvm/bin/clang++
    CORE := $(CARBON_TOOLCHAIN)/lib/carbon/core
    O ?= build-make

    all: $(O)/hello $(O)/widget_main $(O)/mixed

    $(O):
            mkdir -p $@
    $(O)/io.impl.o: $(CORE)/io.carbon $(CORE)/io.impl.carbon | $(O)
            $(CARBON) compile --no-include-carbon-core --output-last-input-only \
              --output=$@ $(CORE)/io.carbon $(CORE)/io.impl.carbon
    $(O)/hello.o: hello/hello.carbon | $(O)
            $(CARBON) compile --output-last-input-only --output=$@ $<
    $(O)/hello: $(O)/hello.o $(O)/io.impl.o
            $(CARBON) link --output=$@ $^
    $(O)/widget.impl.o: widget/widget.carbon widget/widget.impl.carbon | $(O)
            $(CARBON) compile --output-last-input-only --output=$@ \
              widget/widget.carbon widget/widget.impl.carbon
    $(O)/widget_main.o: widget/widget.carbon widget/widget.impl.carbon widget/main.carbon | $(O)
            $(CARBON) compile --output-last-input-only --output=$@ \
              widget/widget.carbon widget/widget.impl.carbon widget/main.carbon
    $(O)/widget_main: $(O)/widget_main.o $(O)/widget.impl.o $(O)/io.impl.o
            $(CARBON) link --output=$@ $^
    $(O)/twice.o: mixed/twice.cpp mixed/twice.h | $(O)
            $(CXX) -std=c++17 -c -o $@ mixed/twice.cpp
    $(O)/mixed.o: mixed/main.carbon mixed/twice.h | $(O)
            $(CARBON) compile --clang-arg=-Imixed --output-last-input-only --output=$@ mixed/main.carbon
    $(O)/mixed: $(O)/mixed.o $(O)/twice.o
            $(CARBON) link --output=$@ $^
    ```

    (The `io.impl.o` recipe compiles the api file too but keeps only the impl's
    object — the last input — which is the one with the bodies; the api object
    of a Core library is empty, as `widget.o` is.) Under Make the sibling rule
    is explicit: an object's prerequisites are the whole package. Objects stay
    positional before `--`; the intermingled form `carbon help link` describes
    fails (W-133, F10).
6.  **test.sh** — bash, `#!/usr/bin/env bash`, `set -euo pipefail`, executable
    (git mode 100755; `check-executables-have-shebangs`), `#` header;
    D-CM-12's contract; it never writes inside `examples/cmake/` (CMake build
    dirs and the Makefile's `O=` both point into the build dir); on exit it
    leaves the build dir in place (the runner's out dir is private, R5).
7.  **README.md** — what the three programs show, the two commands to run
    (`test.sh`, and `cmake -S examples/cmake -B build` with
    `CARBON_TOOLCHAIN` in a fenced block), the Makefile, pointers to
    docs/guides/build_systems.md and `cmake/README.md`, and the limits list
    with W-ids. (A directory link from the docs resolves to this README —
    check-links.)

### §2.C Docs (one new page, two touched)

1.  **docs/guides/build_systems.md** (new; `<!-- -->` header; H1 "Build
    systems: CMake and Make"). Sections: "Toolchain layout" (`bin/carbon`,
    `lib/carbon/llvm/bin/clang++`, `lib/carbon/core`, `carbon config --json`);
    "CMake" — enabling the language (module path, `project`), finding the
    compiler (D-CM-3's three ways and the example's `CARBON_TOOLCHAIN`),
    flags and configurations (D-CM-10), a single-file executable, Core
    libraries (`Carbon::core_io` and why: link_driver.cpp's TODO), a multi-file
    package (`carbon_add_library`/`carbon_add_executable`, what each generated
    command line looks like under Ninja and Makefiles, quoted from the
    generated `rules.ninja`/`build.make`), mixed Carbon and C++ (the drop-in
    clang++ default, include propagation, `OBJECT_DEPENDS` for headers, Route
    B's failure mode and workaround, and one sentence that CMake appends the
    CXX compiler's implicit link entries — `CMAKE_CXX_IMPLICIT_LINK_LIBRARIES`
    and `_DIRECTORIES`, including a `-L` of the user's
    `$HOME/.cache/carbon_runtimes/...` baked into the build tree — after
    `--`, which is harmless; F6); "Make" — the explicit rules of §2.B.5
    verbatim (variable block, `$(O)` rule, order-only prerequisites) with
    one paragraph per rule, the note that `CXX`, `CC` and `AR` are make
    builtins and take `:=` (F1), the warning that objects go before `--`
    and the intermingled form fails (W-133, F10), the `carbon build`
    one-liner with its caveats;
    "Limits in 0.1" — a table: no depfile (W-129), whole-package recompiles
    and per-directory source properties (W-130), no Core io in `link` (W-003),
    no shared libraries (W-132), modules not installed / no `find_package`
    (W-128), g++-built objects (W-131), `carbon build` caveats (W-133),
    cross-compiling and launcher unwired, Linux/macOS only. R31 discipline:
    every command, flag and quoted driver message is in a fenced block or at
    least never begins an inline span with `-`, `#`, `*`, `+` or a digit-dot;
    the doc-style word list is avoided in prose and code alike (no
    abbreviations of "for example"/"that is", no three-letter synonym of "by
    way of", "versus" spelled out), so no ignore/resume pair is needed unless
    a quoted driver message contains one (none measured does).
2.  **docs/guides/README.md** — one list entry: `[Build systems: CMake and
    Make](build_systems.md)` after the glossary.
3.  **README.md** — one sentence after the "Getting started" shell block
    (:317): a pointer to `/docs/guides/build_systems.md` for CMake projects
    and Make rules. The only upstream-owned text touched; disclosed in the
    decision log's V-3a paragraph.

### §2.D Conformance runner and programs

1.  **fork/conformance/runner.py** (D-CM-14):
    -   header comment (:14-40): a paragraph on BUILD-SCRIPT programs after
        the multi-unit paragraph;
    -   `DIRECTIVE_PREFIXES` (:140-146): add `"// BUILD-SCRIPT:"`;
    -   `Program` (:151-170): `self.build_script = None` (list: path then
        args);
    -   `parse_directives` (:173-243): an `elif` branch mirroring
        `COMPILE-ARGS` (empty value → DirectiveError), docstring line added;
    -   a new `validate_build_script(prog, root)` called from
        `discover_programs` (:377-...) for every program with the directive:
        DirectiveErrors for `COMPILE-ARGS`, multi-unit, `.diff.cpp`, missing
        or non-executable script; it resolves `root / prog.build_script[0]`;
    -   `toolchain_root(toolchain)` beside `find_clangxx` (:431-451): the two
        layouts (`<root>/bin/carbon` → `parent.parent`;
        `<root>/lib/carbon/carbon-busybox` → `parent.parent.parent`); when
        neither candidate has `lib/carbon` it falls back to the resolved
        binary's own directory (`toolchain.resolve().parent`), so the stub
        fixtures' `<tmp>/stub/carbon` (no `lib/carbon`,
        `_write_stub_toolchain`, runner.py:1059-1127) yields `<tmp>/stub`,
        and a real mislaid toolchain fails inside the script as exit 66 →
        RUN-FAIL, a named failure (amended 2026-10-12, review fold: rev 2
        F8); a module constant `REPO_ROOT = SCRIPT_DIR.parent.parent` is
        added beside `SCRIPT_DIR` (:123);
    -   `execute_program` (:485-610): an early branch `if prog.build_script:`
        → `run_build_script(prog, toolchain, out_dir, timeouts)` which runs
        `[root/script, *args]` with `cwd=REPO_ROOT`, env +
        `CARBON_TOOLCHAIN` (the resolved directory), `CARBON` (the
        `--toolchain` path), `CARBON_BUILD_DIR=<out>/build/<name>`, timeout
        `timeouts["link"]`, writes the log on failure with the same
        `write_log` shape, and maps statuses per D-CM-14; `EXPECT-EXIT`
        compares the script's exit, `EXPECT-STDOUT` its stdout;
    -   `generate_program_table` (:753-779): kind `external-build`;
    -   `directive_sync_self_check` (:999-1057): fixture line `// BUILD-SCRIPT:
        examples/x/test.sh --only y`, effect `prog.build_script ==
        ["examples/x/test.sh", "--only", "y"]` (the combination guard lives in
        discovery, so the fixture with `COMPILE-ARGS` still parses);
    -   `execution_self_check` (the stub-toolchain fixtures, :1060-1130 and
        its caller): three BUILD-SCRIPT fixtures against a temp root — a
        script printing `hi` (PASS; also asserts `CARBON_TOOLCHAIN` equals the
        stub's directory — the fallback above, since the stub has no
        `lib/carbon` — and `CARBON` equals the stub path), a script exiting
        2 (COMPILE-FAIL), a script printing
        `bye` (OUTPUT-MISMATCH);
    -   `self_test` (:1350-1420): `build_script_self_check(programs)` — the
        identity rule (body after the leading comment block equals the body of
        exactly one `.carbon` under the script's directory tree, both compared
        after stripping each file's own leading comment block) and the
        existence/executability check;
    -   the scoreboard entry (:1640) gains `"external_build": prog.build_script
        is not None`; the per-program listing (:1430-1433) marks `[build:
        <script>]`.
2.  **fork/conformance/README.md**: "Program format" (:81-117) gains the
    directive line and a bullet; a new subsection "External-build programs
    (BUILD-SCRIPT)" after "Multi-unit (split-file) programs" (:118-176) with
    the contract, the status mapping and the identity rule; the program table
    is regenerated (`--update-readme-table`; the two project rows change kind
    SKIP → external-build, :342 and :345).
3.  **fork/conformance/programs/project/cmake_build_integration.carbon**:
    header keeps the bullet line verbatim; `// BUILD-SCRIPT:
    examples/cmake/test.sh`; `EXPECT-EXIT: 0`; `EXPECT-STDOUT:` the five
    lines of §5; the SKIP line and the "intended future arbitration" sketch
    are deleted; a short comment records the un-SKIP (which commit, the
    nightly, that the body is `examples/cmake/hello/hello.carbon` verbatim and
    is not compiled by the runner); body = hello.carbon's code (§2.B.2).
4.  **fork/conformance/programs/project/dropin_clang_make_cmake.carbon**:
    bullet line verbatim; `// BUILD-SCRIPT: examples/cmake/test.sh --only
    mixed`; `EXPECT-STDOUT:` the two lines of §5; SKIP deleted; comment
    records the body replacement (§0.2 item 6); body =
    `examples/cmake/mixed/main.carbon`'s code.

### §2.E Records (fork/)

1.  **fork/gap-analysis.md**: row 87 → DONE and row 84 → DONE with the texts
    of §5.3; header :18-30 → `32 DONE / 20 PARTIAL / 3 MISSING / 1
    DESIGN-ONLY`, the parenthetical reconciled "against the expected
    conformance scoreboard — 130 PASS / 0 FAIL / 20 SKIP over 150 programs,
    49/56 bullets PASS, stated as expected, not of record (Actions disabled)
    —"; the summary sentence's "leaving variadics and the build-system/
    documentation rows as the open back half" → "leaving variadics, Windows
    and the evaluator-documentation row as the open back half"; §W11
    (:261-273) rewritten: the CMake integration and Make docs landed (CM-1),
    the tutorial (W-062) remains, arbiter sentence split accordingly; the area
    summary's "but the 0.1-required CMake integration and Make documentation
    are entirely absent" (:528-530) → the landed state with the limits
    pointer. Bullet strings untouched (R7).
2.  **fork/inventory/work-items.json**: per D-CM-16; `source` gains "Updated
    2026-10-DD by the CM-1 discharge: W-060 and W-061 DISCHARGED (CMake
    language modules under cmake/, examples/cmake with test.sh, docs/guides/
    build_systems.md; both project stubs un-SKIPped through the runner's new
    BUILD-SCRIPT channel); W-002 (3) answered for external builds; W-003 notes
    carry the CMake workaround; W-128..W-133 filed on the assumption that PR
    51 takes W-126/W-127, verified at merge." No license header (JSON).
3.  **fork/decision-log.md**: `### CM-1: CMake language modules, example
    project, Make documentation (2026-10-DD)` inserted above the SL-2 entry
    (:2863) with the SL-2 shape: opening paragraph (both bullets, rows 84/87,
    header before/after, "expected, not of record — Actions disabled", branch,
    the three commits), WHAT LANDED by mechanism (modules; helpers; example;
    script; docs; runner channel), DECISIONS D-CM-1..17, REVIEWS (the two plan
    reviews; the one implementation review, R29(c): hosted verification not
    green), FILL-CAUGHT MISSES "none — no hosted round possible", VERIFICATION
    (local prek with `fix-cc-deps` skipped and why; `--self-test`; the local
    runner run `--filter project/` with its two PASS lines and the nightly;
    `test.sh` under both generators; hosted pending — stated as not of
    record: R9's scoreboard record is outstanding with no dispatch date,
    Actions disabled; F9), RESIDUE (W-128..W-133
    with evidence), PLAN §0.2 CORRECTIONS (items 1-9), and the italic V-3a
    paragraph (upstream has no CMake integration; module and helper names are
    fork-local and rename if upstream ships one; README.md's one-line pointer
    is the only upstream-owned text touched; the `BUILD-SCRIPT` directive is
    fork-harness-local). No model identifiers anywhere.
4.  **fork/ORCHESTRATION.md**: the "Last updated:" paragraph (:13-46)
    rewritten in the post-PR style of 8068151ed with the CM-1 state (landed
    on the branch, PR opened and HELD like PR 51, the dispatch list:
    conformance → gate → merge; the local verification named); a Branches row
    `| \`claude/carbon-fork-0-1-cmake\` | HELD OPEN as PR NN — CM-1 ... |`
    (:379-392); the Scoreboard line (:394-407) UNCHANGED (it quotes
    scoreboard.json only, which only a hosted run regenerates); Next actions
    (:442-460) gain the W-128 install step and drop nothing.
5.  **fork/cmake/plan.md** (this file): review fold record, sign-off, landed
    notes at discharge.

## §3 Commit structure (three implementation commits; this plan's own commit precedes them)

1.  **`CM-1 (1/3): CMake language modules (cmake/) and examples/cmake (hello,
    widget package, mixed C++) with test.sh and Makefile`** — §2.A and §2.B.
    Self-contained: `examples/cmake/test.sh` passes against the nightly under
    both generators and the Makefile at this commit. prek on every file
    (`SKIP=fix-cc-deps`; the skip and its reason in the message).
2.  **`CM-1 (2/3): runner BUILD-SCRIPT channel; project stubs un-SKIP; build
    systems guide; gap rows 84/87; ledger`** — §2.C, §2.D, §2.E.1-2. The
    order inside the commit matters for the R12 hook (it runs `--self-test`
    on every program edit, post_edit_invariants.sh:60-72): runner.py and
    README first, then the programs, then `--update-readme-table`. Message
    carries the expected delta (§5) "stated as expected, not of record" (the
    677d0e4b2 precedent) and the local run's two PASS lines.
3.  **`CM-1 (3/3): discharge — decision-log entry, ORCHESTRATION stamp, plan
    landed notes`** — §2.E.3-5.

Commit convention: `GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com
git commit --author="jmann345 <jerrymannstan@gmail.com>"`, body ending with
the two attribution lines; not pushed until R25's `--all-files` prek run;
the PR is opened and HELD (R28(c), D-CM-15).

## §4 Test expectations (hand-derived; R16(d))

1.  **test.sh stdout (Unix Makefiles build, programs in order):**

    ```text
    built by CMake-integrated Carbon
    widget package built by CMake-integrated Carbon
    7
    built by a drop-in Clang build-system example
    42
    ```

    Derivation: the two `Core.PrintStr` literals; `Get()` returns the literal
    `7` and `Core.Print` prints `<int>\n` (core/io.carbon:12, the runner
    README's note); `PrintMarker` writes the literal; `Twice(21)` is
    `2 * 21 = 42`. Ordering between `std::cout` and `printf` inside `mixed`
    under a pipe relies on libc++'s default `sync_with_stdio(true)` (§7 R-6).
    The Ninja build and the Makefile build must print the same five lines;
    `--only mixed` prints the last two.
2.  **test.sh exit codes** per D-CM-12; the runner maps them per D-CM-14.
3.  **Runner self-test** at commit 2: `multi-unit discovery self-check: OK`,
    `directive-prefix sync self-check: OK`, `execution-path self-check: OK`
    (now six fixtures: the three existing plus the three BUILD-SCRIPT ones),
    `build-script self-check: OK`, `self-test: 150 programs parsed, 56
    bullets in table, OK`.
4.  **Local conformance run** (`runner.py --toolchain <tc>/bin/carbon
    --filter project/ --out <scratch>/out`): `project/cmake_build_integration
    .carbon PASS`, `project/dropin_clang_make_cmake.carbon PASS`, the other
    project/ programs unchanged (SKIPs stay SKIP: design_docs_placeholders,
    evaluator_docs_review, safe_carbon_design, safety_strategy_doc).
5.  **Generated command lines** (quoted in the docs; what `cmake --build -v`
    must show at commit 1): compile `carbon compile <defines> <includes>
    <flags> --output-last-input-only --output=CMakeFiles/<t>.dir/<unit>.o
    [siblings] <unit>`; the mixed unit carries `--clang-arg=-I<abs>/mixed`;
    link `carbon link --output=<t> <objects> -- <link flags> <archives and
    implicit libs>`; the widget archive `ar qc libwidget.a ... && ranlib
    libwidget.a`. Makefile variant, re-measured at the rev 2 fold with the
    §2.B.5 rules verbatim against the nightly (scratch `review/mk/`): `make
    CARBON_TOOLCHAIN=<dir> O=<new dir> all` on a clean tree runs `mkdir -p
    <O>`, then `<dir>/lib/carbon/llvm/bin/clang++ -std=c++17 -c -o
    <O>/twice.o mixed/twice.cpp` and `carbon link --output=<O>/mixed
    <O>/mixed.o <O>/twice.o`; the three programs print the five lines of
    §4.1; a second `make` is `Nothing to be done for 'all'`; `make
    CARBON=<dir>/bin/carbon O=... all` (no `CARBON_TOOLCHAIN`) builds the
    same; `make O=...` alone stops at the `$(error)`; `make CXX=g++ ...`
    on the command line overrides the `:=` and reproduces §0.1 row 16's
    `undefined symbol: std::cout` — the rev 1 `?=` text did that with NO
    override, because make's builtin `CXX = g++` already counted as set
    (F1, F3, F7).
6.  **Negative checks the implementer runs once, not committed as tests:**
    `add_library(bad SHARED hello/hello.carbon)` → configures under BOTH
    generators and `cmake --build` fails with no `libbad.so` (`FAILED:
    libbad.so` / `: && cmake -E false && :` under Ninja; `Error 1` under
    Makefiles) — checked under both, because the undefined-variable form
    only fails under Makefiles and succeeds silently under Ninja (F2); a
    configure with only `PATH=<dir>/bin` set (no `CARBON_TOOLCHAIN`, no
    `CARBON`) resolves `CMAKE_Carbon_COMPILER` to `<dir>/bin/carbon` and
    `CMAKE_CXX_COMPILER` to `<dir>/lib/carbon/llvm/bin/clang++` (F4); a
    `widget/main.carbon` compiled
    without the sibling wiring → "imported API 'Main//widget' not found"
    (proves `OBJECT_DEPENDS`/`COMPILE_OPTIONS` are load-bearing); editing
    `twice.h` → `mixed/main.carbon` rebuilds under both generators (proves the
    explicit header dependency).

## §5 Conformance and gap-row effect

1.  **Scoreboard delta (expected, not of record):** PASS +2, SKIP −2, total
    unchanged → **130 PASS / 0 FAIL / 20 SKIP over 150**, bullets 48 → 49/56
    (the CMake bullet newly PASS; the drop-in bullet was already PASS through
    dropin_clang_cpp_toolchain.carbon). On top of PR 51's base (131/0/19) the
    merged expectation is 133/0/17 — the delta rule, never hard-coded.
    Program names, bullets and the file paths stay; kinds become
    `external-build`.
2.  **Program headers** (bullet lines byte-identical; R7):

    ```carbon
    // CONFORMANCE-BULLET: Project: CMake build-system integration plus Make documentation
    // BUILD-SCRIPT: examples/cmake/test.sh
    // EXPECT-EXIT: 0
    // EXPECT-STDOUT:
    //   built by CMake-integrated Carbon
    //   widget package built by CMake-integrated Carbon
    //   7
    //   built by a drop-in Clang build-system example
    //   42
    ```

    ```carbon
    // CONFORMANCE-BULLET: Project: toolchain drop-in usage as Clang C++ toolchain with common Make/CMake build systems
    // BUILD-SCRIPT: examples/cmake/test.sh --only mixed
    // EXPECT-EXIT: 0
    // EXPECT-STDOUT:
    //   built by a drop-in Clang build-system example
    //   42
    ```

3.  **Gap rows** (text, status cell and evidence cell; bullet cell untouched):
    -   Row 87: `| ... | DONE | CM-1 (2026-10-DD, fork/cmake/plan.md):
        first-class CMake language support under cmake/
        (CMakeDetermineCarbonCompiler, CMakeCarbonInformation,
        CMakeTestCarbonCompiler, CarbonTargets with carbon_add_library /
        carbon_add_executable for whole-package compilation and Carbon::core_io)
        and examples/cmake building hello, a two-file package and a mixed
        Carbon/C++ program under Unix Makefiles, Ninja and a plain Makefile,
        arbitrated by examples/cmake/test.sh through the runner's BUILD-SCRIPT
        channel (project/cmake_build_integration PASS locally on nightly
        2026.10.12 — not of record: the hosted run R9 requires is pending
        with no dispatch date, Actions disabled); Make
        documentation in docs/guides/build_systems.md. 0.1 limits, each a
        filed item: no depfile (W-129), whole-package recompiles (W-130),
        `carbon link` adds no Core io objects (W-003), no shared libraries
        (W-132), modules not installed in the toolchain tree (W-128). |`
    -   Row 84: `| ... | DONE | clang/clang++/clang-cl/lld busybox symlinks
        with on-demand runtimes are implemented and integration-tested
        (dropin_clang_cpp_toolchain PASS), and CM-1 exercises and documents
        them under CMake (examples/cmake: CMAKE_CXX_COMPILER = the install
        tree's lib/carbon/llvm/bin/clang++ compiles the C++ half of a mixed
        program) and Make (examples/cmake/Makefile assigns CXX := the same
        symlink; the measured compile line is in fork/cmake/plan.md §4.5),
        arbitrated by examples/cmake/test.sh through the BUILD-SCRIPT channel
        (project/dropin_clang_make_cmake PASS locally on nightly 2026.10.12 —
        not of record: the hosted run R9 requires is pending with no
        dispatch date, Actions disabled); docs/guides/build_systems.md.
        System-g++-built
        objects under `carbon link` remain a filed limit (W-131). |`
4.  **Honesty guard (R9, R16):** both rows' evidence cells say "PASS locally
    ... not of record ... no dispatch date" (the literal phrase is in each
    cell, not only in the header; F9); the header parenthetical says
    "expected, not of record"; the
    ORCHESTRATION scoreboard line is not touched; if the first hosted run
    shows anything but the two PASS lines, the rows revert to PARTIAL/MISSING
    in the fix commit with the log quoted (D-CM-14's fallback).

## §6 Churn inventory

-   **New files (18):** `cmake/` ×6 (§2.A), `examples/cmake/` ×11 (§2.B),
    `docs/guides/build_systems.md`. Expected sizes: the four language modules
    ~70 + 25 + 75 + 45 lines, CarbonTargets ~110, the guide ~350, test.sh
    ~140, CMakeLists ~45, Makefile ~60, Carbon/C++ sources <20 each.
-   **Modified files (9):** docs/guides/README.md (+1 line), README.md (+1
    sentence), fork/conformance/runner.py (~+170 lines: one directive, one
    validator, one executor branch, one root resolver, three fixtures, one
    self-check), fork/conformance/README.md (+~40, table rows ×2),
    the two programs (rewritten headers and bodies), fork/gap-analysis.md
    (rows 84, 87, header, §W11, area summary), fork/inventory/work-items.json
    (W-002, W-003, W-060, W-061 notes/evidence; W-128..W-133; `source`),
    fork/decision-log.md (+1 entry), fork/ORCHESTRATION.md (stamp, row, next
    actions), this plan.
-   **Toolchain C++, goldens, BUILD, .bzl, MODULE, .github: NONE.** No
    autoupdate; no buildifier/check-build-graph/check-bazel-mod-deps trigger;
    Actions untouched.
-   **prek hooks that fire and their disposition:** check-copyright on every
    new file (headers per §0.1 row 20); clang-format on twice.{h,cpp};
    fix-cc-deps on twice.{h,cpp} — cannot run (no bazel) → `SKIP=fix-cc-deps`
    locally, recorded; it is a global `bazel query` + BUILD-dependency fixer
    and examples/cmake has no BUILD file, so its CI pass is a no-op by
    construction; rumdl ×2 + check-google-doc-style + check-links + codespell
    on the five markdown files (R31 counts before/after, §8.1);
    check-executables-have-shebangs on test.sh; ruff/ty on runner.py;
    end-of-file-fixer/trailing-whitespace/mixed-line-ending on all.
-   **R12 hook:** polices `fork/*` under this worktree (license headers on
    `.md/.py/.carbon`; `--self-test` after each program edit; the R16b
    SKIP-addition check is inert — we remove SKIPs); it does not police
    examples/ or docs/ (post_edit_invariants.sh:22-27), so prek is their only
    local check.

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — the hosted runner lacks cmake, make or the Makefiles generator.**
    Falsifier: the hosted conformance log for `cmake_build_integration` shows
    `cmake: command not found` (script exit 66/2 → COMPILE-FAIL). Contingency:
    D-CM-14's Option B (SKIP naming the script and the local result; rows
    PARTIAL) in the fix commit; never an apt step in the workflow (.github is
    not touched by this workstream).
-   **R-2 — a newer CMake on the hosted image changes custom-language
    behaviour** (for example rejecting a Ninja `deps = gcc` rule without a
    depfile, or a stricter `try_compile`). Falsifier: configure or build
    failure in the hosted log with a CMake policy or generator message.
    Contingency: pin the behaviour by `cmake_policy`/`CMAKE_Carbon_DEPFILE_
    FORMAT` in the Information module; CMake 3.28.3 locally is the floor
    (`cmake_minimum_required(VERSION 3.28)`), not the ceiling.
-   **R-3 — cold runtimes cache on the hosted runner.** The first `carbon
    link` builds the runtimes (16.9 s here, 32 s in the earlier probe; R4);
    the runner's link timeout is 1800 s and the earlier programs of the suite
    warm the cache before project/ runs. Falsifier: `RUN-FAIL: build script
    timed out`. Contingency: none needed; the budget is 50× the measurement.
-   **R-4 — the CXX compiler is not the toolchain's clang++** (a user or the
    hosted environment pre-sets `CMAKE_CXX_COMPILER` or `CXX`): the mixed link
    fails with the `-lstdc++` → `-lc++` rewrite (row 16). The example seeds
    `CMAKE_CXX_COMPILER` only when unset; test.sh passes it explicitly, so the
    arbiter is immune. Falsifier: `undefined symbol: std::__throw_length_error`
    in a user's log. Contingency: the docs' Route B paragraph and W-131.
-   **R-5 — CMake appends CXX implicit link directories and libraries to the
    `carbon link` line.** Tolerated when CXX is the toolchain's clang++
    (`c++;m;unwind;c;unwind`, measured). Falsifier: a Clang driver error for
    a duplicated `-lc++`/`-lunwind` on a future nightly. Contingency: reset
    `CMAKE_CXX_IMPLICIT_LINK_LIBRARIES` and
    `CMAKE_CXX_IMPLICIT_LINK_DIRECTORIES` to empty after `project()` in the
    example — the entries (`-lc++ -lm -lunwind -lc -lunwind`, the
    `-L$HOME/.cache/carbon_runtimes/...` and `-L/usr/lib/gcc/...`
    directories) come from the CXX compiler's ABI detection
    (`CMakeCXXCompiler.cmake` lines 83-84 of the prototype build; visible
    as `LINK_PATH = -L...` in build.ninja), not from any Carbon-language
    variable, so a `CMAKE_Carbon_IMPLICIT_LINK_LIBRARIES` scrub would change
    nothing. The same detection bakes the user's `$HOME` runtimes-cache path
    into the build tree; the docs' mixed-targets section says so (amended
    2026-10-12, review fold: rev 2 F6).
-   **R-6 — stdout interleaving in `mixed`:** `std::cout` (C++) then `printf`
    (Carbon's `Core.Print`) into one pipe. libc++'s `sync_with_stdio` default
    is true, so both go through stdio in order. Falsifier: OUTPUT-MISMATCH
    with `42` before the marker. Contingency: `PrintMarker` uses `std::puts`;
    the EXPECT lines do not change.
-   **R-7 — a `.carbon` file shared by two targets in one directory** gets
    both sibling lists (per-directory source properties). The helper's
    `CARBON_PACKAGE` collision check turns it into a configure-time
    FATAL_ERROR naming both targets. Falsifier: a configure that succeeds with
    a doubled `COMPILE_OPTIONS` list (visible in `flags.make`). Contingency:
    none beyond the check; W-130 documents the OBJECT-library-per-package
    idiom.
-   **R-8 — the identity rule is too strict or too loose.** Too strict: a
    harmless whitespace difference between the program body and the example
    unit fails `--self-test` — intended; the body is copied, not retyped. Too
    loose: two example units with identical bodies make "exactly one"
    ambiguous — the example has no two identical units. Falsifier: a
    self-test failure message naming zero or two matches. Contingency: the
    message names the candidates; the implementer fixes the body.
-   **R-9 — R31 damage in the five markdown files.** The guide quotes dozens
    of flags; every one sits in a fenced block or inside a sentence where the
    span cannot be the first token of a wrapped line (the plan's own text
    obeys the same rule). Falsifier: the heading/list count diff of §8.1
    changes, or the `^\+\s*#{1,6} [0-9]|^\+#[0-9]` grep hits. Contingency:
    rephrase the sentence, never revert the reflow.
-   **R-10 — GNU make portability** (macOS ships make 3.81): the Makefile uses
    `?=` (never for `CXX`, `CC` or `AR`: those are make builtins with origin
    `default`, which `?=` treats as already set — F1), `:=`, `$(origin
    ...)`, `$(abspath ...)`, `$(error ...)`, `$@`, `$<`, `$^`, pattern-free
    explicit rules and a `$(O)` rule listed as a `| $(O)` order-only
    prerequisite on every object rule (shown in §2.B.5; F3) — all 3.81
    features; no `$(file ...)`, no `.RECIPEPREFIX`. Falsifier: a macOS
    reviewer's make error. Contingency: the offending construct is replaced;
    the arbiter does not run on macOS.
-   **R-11 — test.sh's exit-code mapping misclassifies a CMake build
    failure** (compile versus link under `cmake --build`). The script greps
    the build log for the linker's own signatures (`ld.lld: error`, `linker
    command failed`); a compile failure is 2 otherwise. Falsifier: a
    LINK-FAIL whose log is a compile diagnostic. Contingency: the mapping is
    advisory; both are failures and the log carries the truth.
-   **R-12 — fix-cc-deps cannot run locally** (no bazel; §0.1 row 20). It is
    skipped by name in every local prek invocation and the skip is recorded in
    each commit message and the decision log; the CI prek run is the authority
    when Actions returns (R22/R23). Falsifier: the CI prek run modifies a
    BUILD file because of examples/cmake — impossible by construction (no
    BUILD file there, no `cc_*` target lists its sources).
-   **R-13 — nightly drift in the toolchain's layout:** `carbon config
    --json` keys, `core_library_manifest.txt`, the `version` line format, the
    prelude-only `link` behaviour. Each is read at configure time and the
    failure is a named configure error, not a silent miscompile. Falsifier:
    the first configure error on a newer nightly. Contingency: the module is
    the single place for each.
-   **R-14 — the Ninja rule's missing depfile.** Ninja 1.11.1 treats a missing
    depfile as no extra deps (`#deps 0` measured). Falsifier: `ninja: error:
    ... depfile` on the hosted image. Contingency: `CMAKE_Carbon_DEPFILE_FORMAT`
    unset is the documented state; if a Ninja version objects, set
    `CMAKE_NINJA_DEP_TYPE_Carbon` empty / `CMAKE_Carbon_DEPFILE_FORMAT ""`.
-   **Rejected: a `carbon build` custom-command route as the primary shape**
    — no library targets, no objects, no dependency tracking beyond
    `DEPENDS`, cannot take `.cpp` sources (row 8). Kept in the docs as a
    one-liner for throwaway builds. **Rejected: Route B as the default** —
    32 s configure step and an untested module path (D-CM-8). **Rejected: a
    separate examples workflow as "the example project's own CI"** — Actions
    is disabled, .github is out of bounds, and a second arbiter would split
    the scoreboard's authority (R9). **Rejected: un-SKIP by rewriting the
    stubs' bodies to print the markers through `carbon compile`/`link`
    alone** — that would prove the driver, not CMake (the stub's own words,
    :29-33 of cmake_build_integration.carbon).

## §8 Verification and discharge

1.  **Local, before each commit (R22/R25/R31):** `SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest
    uvx prek run --files <touched files>` to a fixpoint (two consecutive
    clean passes; rumdl runs twice per pass); for every touched `.md`, the
    counts `grep -c '^## '`, `grep -c '^### '`, `grep -cE '^\s*-   '`,
    `grep -cE '^\s*[0-9]+\. '` recorded before and after and diffed (only this
    plan's and the guide's own additions may change them, by exactly the
    sections added); `git diff | grep -nE '^\+\s*#{1,6} [0-9]|^\+#[0-9]'`
    empty; `python3 fork/conformance/runner.py --self-test` rc 0 (commit 2);
    `--update-readme-table` clean. Baseline counts at 0bdce60a5:
    gap-analysis 5/23/0/0, decision-log 2/44/23/0, ORCHESTRATION 1/5/8/4,
    docs/guides/README 0/0/1/0, README 9/7/75/2, conformance README
    4/3/22/6 (H2/H3/dash items/numbered items).
2.  **Local arbiter run (commit 1 and commit 2):** `CARBON_TOOLCHAIN=<tc>
    examples/cmake/test.sh --build-dir <scratch>/t1` → the five lines, exit 0,
    with the stderr log kept in the scratchpad; `python3
    fork/conformance/runner.py --toolchain <tc>/bin/carbon --filter project/
    --out <scratch>/out` → the two PASS lines (§4.4); both results quoted in
    the commit messages and the decision log as LOCAL, with the nightly
    version, never as of record.
3.  **Hosted (pending; R28):** when Actions returns, dispatch `Fork: hosted
    verification` mode `conformance` on the PR head (the only mode this
    workstream needs; `gate` is prek + `bazel test //toolchain/...`, which
    this PR does not change but runs anyway as the merge gate, R21). Expected:
    130/0/20 over 150, 49/56 (or the delta on whatever trunk then holds).
    Any other movement is a §5 miss — stop and reconcile; a cmake-not-found
    log is the Option B trigger (D-CM-14).
4.  **Reconciliation greps at discharge:** `grep -rn 'BUILD-SCRIPT'
    fork/conformance` hits runner.py (prefix list, parser, validator,
    executor, fixtures, self-check), README.md (format + subsection) and the
    two programs only; `grep -rn 'SKIP:' fork/conformance/programs/project`
    no longer hits the two files; `grep -rn 'entirely absent' fork/gap-analysis.md`
    is empty; `grep -rn 'W-128\|W-129\|W-130\|W-131\|W-132\|W-133'` hits the
    ledger, the gap rows, the guide's limits table and the decision log;
    `grep -rn 'output-last-input-only' cmake examples/cmake` hits the rule
    (once) and the Makefile (five recipes) and nothing in CarbonTargets.
5.  **Ledger edits** per D-CM-16, including the §0.2 corrections 1-3 and 7.
6.  **Decision-log entry, ORCHESTRATION stamp, plan landed notes** per
    §2.E.3-5; the PR is opened with the label text "awaiting hosted
    conformance + gate (Actions disabled)", HELD like PR 51, and the exact
    dispatch list is in ORCHESTRATION.
7.  **Reviews (R29(c)):** two plan reviews before commit 1 (adversarial;
    briefs: the driver facts of §0.1 against the modules' assumptions, the
    arbitration channel against R9/R16, the R31/doc-style hazards of the
    guide); one implementation review after commit 3 (hosted verification
    cannot be green, so the review runs the local arbiter itself and diffs
    the generated command lines against §4.5).

## Hand-off notes for the implementer

-   Start from the scratch prototype
    (`<scratchpad>/cmake/Modules/*`, `proj/CMakeLists.txt`,
    `probe/{main.carbon,twice.cpp,twice.h,Makefile}`, `probe/lang2/`): every
    module is already measured under both generators; the changes are the
    license headers, the rule-level last-input-only flag (D-CM-4), the
    manifest-driven `carbon_add_core_library` (D-CM-7), the `CARBON_PACKAGE`
    collision check (D-CM-6), and dropping `carbon_add_prelude_target`
    (D-CM-8). Do not re-derive the CMake mechanics; the trace is in
    `build-ninja-trace.txt`.
-   The example's `CARBON_TOOLCHAIN` block MUST run before `project()`; after
    it, `CMAKE_CXX_COMPILER` cannot change. test.sh passes
    `-DCARBON_TOOLCHAIN=<root>` explicitly so the arbiter never depends on
    PATH.
-   `--output-last-input-only` lives in the compile RULE now; if you find
    yourself appending it per source in CarbonTargets, you are rebuilding the
    prototype, not the plan.
-   Core io: `--no-include-carbon-core` ONLY for Core's own sources. Pass it
    to a user package and `import Core library "io"` fails ("imported API
    'Core//io' not found", measured).
-   Edit runner.py and its README BEFORE touching the two programs; the R12
    hook runs `--self-test` on every program edit and the new directive must
    already parse. Then regenerate the table.
-   The program bodies are COPIES of `examples/cmake/hello/hello.carbon` and
    `examples/cmake/mixed/main.carbon` after their license headers; the
    identity self-check compares after stripping each file's leading comment
    block, so the programs' directive headers do not count.
-   Write "PR 51", never a hash-prefixed number; keep every flag inside fenced
    blocks in the guide; avoid the doc-style word list even in code; run the
    count diff of §8.1 after every prek pass.
-   fix-cc-deps cannot run here; skip it by name and say so in the commit
    message. Nothing else is skipped except the three bazel-requiring hooks the
    task names.
-   The Makefile's `CXX` is `:=`, not `?=` — make predefines `CXX = g++`
    (origin `default`), so `?=` is a no-op and the mixed link fails exactly
    as §0.1 row 16. Every object rule carries `| $(O)`. Keep the two terms
    apart: `CARBON_TOOLCHAIN` is the toolchain directory (parent of `bin/`);
    `CMAKE_Carbon_INSTALL_ROOT` is `<dir>/lib/carbon/`.
-   Never run bazel; never dispatch a workflow; never touch .github/.

## Review fold record (rev 2, 2026-10-12)

Every finding of the rev 1 plan review (APPROVE-WITH-AMENDMENTS: one
BLOCKER, two MAJORs, seven MINORs, all marked confirmed by the reviewer),
where it was folded, and the evidence the fold rests on. The fixer
reproduced every finding against the nightly in the scratch space before
folding (`review/shared/`, `review/sharedfix/`, `review/mk/`,
`review/pathsteps.cmake`); nothing was rejected. Each amended passage is
marked "(amended 2026-10-12, review fold: rev 2 Fn)". The verdict was not
REJECT, so no decision reverses direction: the BLOCKER is a wrong
assignment operator in the Makefile's variable block, the MAJORs are a
silent Ninja success and a missing directory rule, and the MINORs are
wording, counts and contracts.

| Finding | Disposition |
| --- | --- |
| F1 (BLOCKER): `CXX ?= ...` (rev 1 §2.B.5) never assigns, because GNU make predefines `CXX = g++`; the documented rules build `twice.o` with g++ and the mixed link fails with `undefined symbol: std::cout` | **folded.** Reproduced: `make -p -f /dev/null` prints `CXX = g++`, `CC = cc`, `AR = ar`, all with `$(origin ...)` = `default`; the rev 1 rules verbatim in `review/mk/` compiled `twice.o` with `/usr/bin/g++` and `carbon link` failed with `ld.lld: error: undefined symbol: std::cout`. §2.B.5 is rewritten with `CXX :=` and the builtin note (a command-line `make CXX=g++` still overrides it — measured); D-CM-13, D-CM-15, R-10, §2.C.1 and the hand-off say `CXX`, `CC`, `AR` are builtins; §4.5 quotes the re-measured clang++ compile line; §5.3 row 84 says "assigns CXX :=" and points at §4.5 |
| F2 (MAJOR): with `CMAKE_Carbon_CREATE_SHARED_LIBRARY` undefined, `add_library(x SHARED a.carbon)` fails at generate time only under Makefiles; under Ninja it configures, generates a `$PRE_LINK && $POST_BUILD` rule, reports "Linking Carbon shared library libbad.so" and exits 0 with no file | **folded.** Reproduced with the prototype modules under Ninja (configure rc 0, build rc 0, no `libbad.so`, rule command `$PRE_LINK && $POST_BUILD`) and Makefiles (configure rc 1 naming the variable). The fix was measured too: with `CMAKE_Carbon_CREATE_SHARED_LIBRARY` and `_CREATE_SHARED_MODULE` set to `<CMAKE_COMMAND> -E false`, both generators configure and `cmake --build` fails (`FAILED: libbad.so` / `: && /usr/bin/cmake -E false && :`; `Error 1`) with no file. §1.B.2, D-CM-5, §2.A.3 and §4.6 rewritten; §4.6's negative check now runs under both generators |
| F3 (MAJOR): no rule creates `$(O)`; on a fresh tree the first recipe fails with `could not open output file .../hello.o` | **folded.** Reproduced (`make ... O=<new dir> all` → `error: could not open output file ...hello.o: No such file or directory`). §2.B.5 adds the `$(O):` rule (`mkdir -p $@`) and `\| $(O)` on all six object rules; R-10's claim now matches the rules shown; §2.C.1 quotes the same. Measured: a fresh `O=` builds and a second `make` is `Nothing to be done for 'all'` |
| F4 (MINOR): two `PATH` steps from the REALPATH'd busybox give `<dir>/lib`, not the toolchain directory; three are needed | **folded.** Reproduced with `cmake -P` and only `PATH=<dir>/bin` set: two steps = `<dir>/lib` (no `bin/carbon` there), three = `<dir>` with `bin/carbon` and `lib/carbon/llvm/bin/clang++` present. §2.B.1 and D-CM-3 say three steps; §4.6 adds the PATH-only configure check |
| F5 (MINOR): "install root" named two directories — `CARBON_TOOLCHAIN` (the tarball directory) and `CMAKE_Carbon_INSTALL_ROOT` (`carbon config`'s `INSTALL_ROOT`, which is `<dir>/lib/carbon/`) | **folded.** Measured `carbon config --json`: `"INSTALL_ROOT": ".../carbon_toolchain-0.0.0-0.nightly.2026.10.12/lib/carbon/"`. §1 opens with a terms paragraph (toolchain directory; install root); D-CM-3, D-CM-7, D-CM-12, D-CM-14, §2.D.1 and the hand-off use them; the test.sh and runner contracts name `CARBON_TOOLCHAIN` as the toolchain directory throughout |
| F6 (MINOR): R-5's contingency names `CMAKE_Carbon_IMPLICIT_LINK_LIBRARIES`, but the appended `-l`/`-L` entries come from the CXX compiler's ABI detection (`CMAKE_CXX_IMPLICIT_LINK_LIBRARIES`/`_DIRECTORIES`), and a `$HOME` runtimes-cache `-L` is baked into the build tree | **folded.** Confirmed in the prototype build: `CMakeCXXCompiler.cmake:83-84` holds the lists and build.ninja's `LINK_PATH` carries them; the Carbon compiler file has no implicit-link entries. R-5's contingency now resets the two CXX variables after `project()`; §2.C.1's mixed-targets section gains the one-sentence disclosure including the `$HOME` path |
| F7 (MINOR): `CARBON_TOOLCHAIN ?=` "required unless `CARBON` is given", but `CORE` and `CXX` derive from `CARBON_TOOLCHAIN` only, so `make CARBON=...` alone breaks | **folded.** Reproduced (`make CARBON=<tc>/bin/carbon ... io.impl.o` → `No rule to make target '/lib/carbon/core/io.carbon'`). §2.B.5 derives `CARBON_TOOLCHAIN := $(abspath $(dir $(CARBON))..)` when only `CARBON` is given and `$(error ...)`s when neither is; measured: `CARBON=` alone builds and runs `mixed`, no variables stops at the error. D-CM-12's test.sh contract gains the same `CARBON` fallback for consistency |
| F8 (MINOR): `toolchain_root` returning None without `lib/carbon` contradicts the PASS fixture (the stub is `<tmp>/stub/carbon`, no `lib/carbon`); `REPO_ROOT` is not a runner.py constant | **folded.** Confirmed: `_write_stub_toolchain` writes `stub_dir / "carbon"` only (runner.py:1059-1127) and the only root constant is `SCRIPT_DIR` (:123). §2.D.1 specifies the fallback (the resolved binary's own directory when neither layout has `lib/carbon`; a real mislaid toolchain then fails inside the script as exit 66 → RUN-FAIL), defines `REPO_ROOT = SCRIPT_DIR.parent.parent`, exports `CARBON` beside `CARBON_TOOLCHAIN`, and the fixture asserts both; D-CM-14 records the fallback |
| F9 (MINOR): rows 84/87 flip to DONE while R9's record (a hosted run) is indefinitely unavailable; the "not of record" phrase sat only in the header | **folded** as a disclosure fix, the flip itself unchanged (the reviewer found the un-SKIP honest and the mitigations present). §5.3: both evidence cells carry the literal "not of record: the hosted run R9 requires is pending with no dispatch date, Actions disabled"; §5.4 says the phrase is in each cell; D-CM-15 and §2.E.3's decision-log entry state that R9's record is outstanding with no dispatch date |
| F10 (MINOR): `carbon help link` says EXTRA_CLANG_LINK_ARGS may carry object files intermingled with flags, but `carbon link --output=x -- a.o b.o -lc++` fails with `error: no such file or directory: '-lc++'` | **folded.** Reproduced on the nightly (intermingled form rc 1 with that message; positional `a.o b.o -- -lc++` rc 0). W-133's description in D-CM-16 gains the measured command and error; §2.B.5 and §2.C.1 keep every rule on the positional form and the docs warn against the intermingled one |
| Verified clean by the reviewer (no finding; recorded so the implementer does not re-open them) | D-CM-1/4/6 shape under both generators with the five §4.1 lines and the §4.5 command lines; rebuild semantics (no-op re-run, `twice.h` → `mixed/main.carbon.o` relink, impl edit → widget objects only, API edit → consumer rebuild); `-j8` clean build (configure's CXX ABI detection warms the runtimes cache, so first links do not race); Ninja `deps = gcc` with `#deps 0 (VALID)` and R-14's `CMAKE_NINJA_DEP_TYPE_<LANG>` spelling (Windows-Clang.cmake:153); the mixed link by `carbon link` with `-stdlib=libc++ -unwindlib=libunwind` and the static runtimes, an OBJECT-library variant too; per-config flags on compile lines only; §0.1's driver facts re-measured (rows 6, 8, 9, 16; the 30 prelude objects plus 2 clang_rt objects in the cache); vendor-regex identification on the nightly and on the fork-built template (common/version_stamp.tmpl.cpp:20); check-copyright's match-all `#` format; the scoreboard/gap arithmetic (130/0/20, 48 → 49, 32/20/3/1); every citation listed in the review; test.sh's link-failure signatures; the Makefiles-generator SHARED failure; D-CM-14's arbitration honesty (R7, R9, R10) |

## Sign-off

**SIGNED OFF FOR IMPLEMENTATION, 2026-10-12 (rev 2).** The plan review of
R29(c) returned APPROVE-WITH-AMENDMENTS; rev 2 folds all ten findings,
each reproduced by the fixer before folding, and rejects none. The
BLOCKER (F1) and the MAJORs (F2, F3) are repaired inside the existing
decisions — D-CM-13's Makefile gains `CXX :=`, a `$(O)` rule and the
`CARBON` derivation; D-CM-5 pins `CMAKE_Carbon_CREATE_SHARED_LIBRARY` to a
failing command — and reverse no decision's direction, so no focused
re-review is required. One review ran against this plan rather than the
two the rev 1 header anticipated; the sign-off rests on that review plus
the fixer's own reproductions, and the implementation review of §8.7
remains. Verification is as §8: local prek to a fixpoint with the named
skips, the runner's `--self-test`, the local arbiter run under both
generators and the Makefile, and the local `--filter project/` run — all
quoted as LOCAL, never as of record — with the hosted conformance and
gate runs outstanding until Actions returns (R28); the PR is opened and
HELD with its dispatch list in ORCHESTRATION (R28(c), D-CM-15). Landed
notes are appended at discharge (§2.E.5).

## Landed notes (discharge, 2026-10-12)

Implemented as §3 fixed, on claude/carbon-fork-0-1-cmake off trunk
0bdce60a5: a88077854 (1/3, §2.A and §2.B), 10af323a2 (2/3, §2.C, §2.D,
§2.E.1-2) and the discharge commit carrying §2.E.3-5 (this section, the
decision-log entry, the ORCHESTRATION stamp). Not pushed at discharge; the
push, the HELD PR and its dispatch list are the next action in ORCHESTRATION.
The measured outputs of §4 are quoted in the commit messages and the
decision-log entry; every §4.5 and §4.6 check held. Gap rows 84 and 87 are
lines 85 and 88 after the header grew by one line.

Deviations from the plan text, each small:

<!-- google-doc-style-ignore -->
-   Commit 1's two READMEs referred to docs/guides/build_systems.md by path
    and commit 2 turned both into links, because check-links rejects a link
    to a file that does not exist yet and the guide is commit 2's (§3).
-   The runner gained `--repo-root` (default `REPO_ROOT`) so the
    execution-path fixtures can use a temporary root through the public
    interface instead of absolute paths in the directive; `discover_programs`
    and `execute_program` take the root as a parameter (§2.D.1).
-   The gap-analysis summary sentence also names the CMake landing in its
    "have since landed" list beside the "leaving ..." change §2.E.1
    specified.
-   `grep -rn 'output-last-input-only' cmake examples/cmake` (§8.4) hits the
    rule once, a comment in the same module, a comment in CarbonTargets that
    says the flag lives in the rule, and the Makefile's five recipes; no code
    in CarbonTargets appends it.
-   The Makefile's stage targets `objects`, `link`, `run` and `clean` sit
    below the verbatim rule block of §2.B.5; test.sh builds `objects` then
    `link` so the stage of a failure is known (D-CM-12).
-   On the UPSTREAM nightly the local `--filter project/` run also shows
    project/most_features_missing_match as COMPILE-FAIL (`match` is a fork
    feature); §4.4's "unchanged" holds for the fork-built toolchain of record.
<!-- google-doc-style-resume -->

### Landed notes (CM-1): implementation review fold (2026-10-12)

The §8.7 implementation review returned APPROVE-WITH-AMENDMENTS with five
findings; each is folded below with its verdict, re-measured on the upstream
nightly 2026.10.12 with CMake 3.28.3, GNU make 4.3 and ninja.

<!-- google-doc-style-ignore -->
-   **F1 (MAJOR, fixed).** An exported `CARBON` overrode an explicit
    `CARBON_TOOLCHAIN` in the Makefile (`CARBON ?=` never assigns over origin
    `environment`), and test.sh's make variant inherited it. The Makefile now
    sets `CARBON := $(CARBON_TOOLCHAIN)/bin/carbon` in the `else` branch of
    the `origin` test (a command-line `make CARBON=...` still wins); test.sh
    passes `CARBON=$toolchain/bin/carbon` beside `CARBON_TOOLCHAIN=` and says
    so in its header; the guide's verbatim block, its "variable block" bullet
    and §2.B.5 above mirror the change. Proof: `CARBON=/nonexistent/bin/carbon`
    exported with `CARBON_TOOLCHAIN` set, `test.sh` rc 0 (rc 2 before) and
    `make CARBON_TOOLCHAIN=<tc> O=<new> all` builds.
-   **F2 (MAJOR, fixed).** A reused build directory kept its first toolchain
    (the seeded compilers are not cache entries, so CMake's compiler-change
    detection never fires). test.sh now configures with `cmake --fresh` (CMake
    >= 3.24; the floor is 3.28) and says so in its header; examples/cmake's
    `CMakeLists.txt` caches `_CARBON_TOOLCHAIN_CONFIGURED` (INTERNAL) and stops
    with `FATAL_ERROR` ("use a fresh build directory") when `CARBON_TOOLCHAIN`
    differs from it; the examples README and the conformance README's
    BUILD-SCRIPT contract carry the reuse rule (the runner only creates
    `CARBON_BUILD_DIR`; the script owns reuse). Proof: a second configure of
    the same directory with a different `-DCARBON_TOOLCHAIN` stops at the
    guard; test.sh run twice into one `--build-dir` rc 0 both times.
-   **F3 (MINOR, fixed with a correction).** The `.cpp`-input diagnostic was
    quoted incompletely, not wrongly: on this nightly `carbon build
    --output=x mixed/twice.cpp` prints `error: file extension of `.carbon`
    required for api` first and then `unrecognized declaration introducer` at
    each declaration (twice.cpp:9:1, :11:1); the one-line
    `int f() { return 1; }` file prints the extension error and then the
    introducer error at 1:1 — the review's "prints only the extension error"
    did not reproduce. The guide and W-133 now quote both messages in that
    order; §0.1 row 8 stands as the measured record, corrected here.
-   **F4 (MINOR, fixed).** The guide's quoted mixed link line named
    `-L<tc>/lib/carbon/llvm/lib`, which the generated link.txt does not carry;
    replaced with the measured `-L/usr/lib/gcc/x86_64-linux-gnu/13` and the
    elision dropped, so the line matches `cmake --build -v`.
-   **F5 (MINOR, fixed).** The documented `make ... run` left an untracked
    `examples/cmake/build-make/`. `.gitignore` gains `/examples/cmake/build-make/`
    (one line, upstream-owned text; disclosed beside README.md's pointer in
    the decision log's V-3a paragraph, so D-CM-13's "only upstream-owned file"
    is now two files), §2.B.5's claim reads "a fresh `O=` keeps the source
    tree clean", and the examples README says the default is git-ignored.
<!-- google-doc-style-resume -->

Outstanding: the hosted conformance run R9 requires (no dispatch date,
Actions disabled); W-128's install step.
