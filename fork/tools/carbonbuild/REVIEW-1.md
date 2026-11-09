<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# REVIEW-1: adversarial review of the container arbiter scaffold

<!-- google-doc-style-ignore -->

Date: 2026-11-09. Reviewer: adversarial reviewer (no changes made to any
scaffold file or to REPO; everything the review built or ran lives under the
reviewer's scratchpad directory, referred to below as `$S`). REPO
`/home/user/carbon-trunk` at cb726a230; `git -C /home/user/carbon-trunk status
--porcelain --ignored` was empty before, during and after the review.

Verdict: **FIX** (one BLOCKER, one MAJOR). The scaffold itself reproduces
Bazel's build, install, runfiles tree and test environment faithfully: with a
one-line correction to a latent bug in the fork's `toolchain/check/check.cpp`
(built in the reviewer's scratchpad, REPO untouched) the authors' own binaries,
install plan and runfiles tree reach **2047 passed / 0 failed** in both opt and
fastbuild mode, and the conformance harness reaches **PASS 228 / FAIL 0 /
SKIP 13 over 241 programs, 51 of 56 bullets** with the unpatched busybox. With
the sources as they are at cb726a230 the gate cannot print a summary at all.

## 1. Findings

### R1-B1 (BLOCKER, owner A): the file_test binary segfaults on 15 goldens and the gate aborts with no summary

Reproduction (authors' runfiles tree, authors' opt binary, cwd
`$RUNFILES_ROOT/_main`, the environment gate.sh exports):

```
file_test --threads=1 --file_tests=toolchain/check/testdata/packages/fail_cycle.carbon   -> SIGSEGV (139)
```

Every golden whose expected diagnostic is emitted through
`UnitAndImports::NodeEmitter` (check.cpp `TrackImport` /
`BuildApiMapAndDiagnosePackaging`) crashes: the 13 files whose `CHECK:STDERR`
lines carry a check.cpp diagnostic kind (`grep -lE
"\[(CppInteropFuzzing|...|RepeatedImport)\]"` over the testdata:
`check/testdata/packages/{fail_api_not_found,fail_cycle,fail_duplicate_api,fail_extension,fail_import_default,fail_import_inline_not_cpp,fail_import_invalid,fail_import_repeat,fail_modifiers,fail_name_with_import_failure,restricted_package_names}.carbon`,
`check/testdata/interop/cpp/basics/import/fail_fuzzing.carbon`,
`check/testdata/interop/cpp/operators/spaceship.carbon`) plus the two
language-server tests that go through the same path
(`language_server/testdata/text_document/{diagnostics_no_line,multiple_files}.carbon`).
All 15 were reproduced individually (`$S/crashers.txt`, `$S/one.log`). In a
whole-manifest run the first crash makes `FileTestEventListener` call
`std::abort()` after the pool drains, so gtest never prints `[  PASSED  ]`;
gate.sh correctly reports `GATE cb726a230: 0 passed, 0 failed (NO GTEST SUMMARY;
binary exit 134)`. The acceptance (2047/0) is therefore impossible with the
binary build.sh produces, in either `CARBON_BUILD_MODE`.

Root cause (gdb, `$S/gdb_fuzz.log`, `$S/gdb_fb.log`): `#0 0x0 in ??()` called
from `Diagnostics::Emitter<Parse::NodeId>::Emit` at
`toolchain/diagnostics/emitter.h:407`
(`emitter_->consumer_->HandleDiagnostic(...)`), i.e. a virtual call through a
dead object. `toolchain/check/check.cpp:428-432` builds
`llvm::SmallVector<UnitAndImports, 0> unit_infos(llvm::map_range(units, ...))`:
each element is copy-constructed from the temporary the lambda returns, and
`UnitAndImports` is self-referential (`check_unit.h:79-83`:
`emitter(&err_tracker, ...)`), so every element's `emitter.consumer_` points at
the dead temporary's `err_tracker`. This is undefined behaviour in the fork's
source; the identical lines are at upstream HEAD ca18985 (`$S/up/upstream`,
shallow clone), so Bazel/libc++ builds merely happen to leave that stack memory
intact. The scaffold's libstdc++ + clang 21.1.8 build (NOTES-A D1/D2) clobbers
it deterministically: the reviewer's fastbuild build of the same sources
(`$S/fb`, `-Og -gmlt`, all other flags identical) crashes on the same 15 files,
so A's documented fallback `CARBON_BUILD_MODE=fastbuild` does not help.

Verification of the fix: replacing the five lines with in-place construction

```
llvm::SmallVector<UnitAndImports, 0> unit_infos;
unit_infos.reserve(units.size());
for (Unit& unit : units) {
  unit_infos.emplace_back(
      &unit, tree_and_subtrees_getters.Get(unit.sem_ir->check_ir_id()));
}
```

in a scratch copy (`$S/patch/check.cpp`), recompiled with the exact ninja
command of the authors' build (opt: `$S/opt/compile.sh` from
compile_commands.json, relinked with the authors' link response content,
`$S/opt/file_test`; fastbuild: `$S/fb/bin/file_test`) and run through the
authors' runfiles tree gives `Ran 2047 tests`, `[  PASSED  ] 2047 tests.` in
both modes (`$S/full_patched_opt.log`, 20 s wall at 2 threads;
`$S/full_patched_fb.log`, 47 s), with zero "Autoupdate would make changes"
failures, i.e. the autoupdate dry-run is stable for every golden.
Every other golden passes unpatched: the unpatched opt binary passed 450
(driver/format/codegen/lex/parse), 340 (check class/generic/function, lower
class/function) and 135 of the 147 packages/impl/interop files individually.

Fix options: (a) land the in-place construction in the fork's
`toolchain/check/check.cpp` (a genuine bug, also present upstream) and measure
the acceptance on that sha; the scaffold needs no change for this. (b) A
scaffold-only route would have to make the build survive the UB (libc++ like
Bazel: LLVM, deps and Carbon all rebuilt with `-stdlib=libc++`, available in
the LLVM 21.1.8 tarball) -- unverified and luck-based; not recommended.
Owner A because D2's note "no golden depends on standard-library behaviour"
is where the assumption lived; the defect itself is in REPO.

### R1-M1 (MAJOR, owner B; caused by A's paths.sh addition): deps.sh now compiles with the wrong compiler and fails on a fresh container

`deps.sh` sources `paths.sh` first (line 28) and only then sets
`CXX="${CXX:-clang++}"` (line 46). Since author A appended
`CXX="${CXX:-$DEPS/llvm21/bin/clang++}"` to paths.sh, `CXX` is already set when
deps.sh reaches its default: `bash -c '. paths.sh; echo $CXX'` prints
`/home/user/arb/deps/llvm21/bin/clang++` while `CC` stays `clang` (18.1.3).
Consequences: (1) on a fresh container in the documented pipeline order (README
step 1 deps.sh, step 2 get_clang.sh) every `cmake -DCMAKE_CXX_COMPILER=$CXX`
configure fails because the compiler does not exist yet; (2) when llvm21 exists,
C++ is compiled by clang 21 and C by clang 18, and deps.env's recorded
`DEPS_CXX=clang++` no longer describes the build (the reviewer's re-run of
`deps.sh validate smoke` rebuilt the six smoke programs under
`/home/user/arb/deps/smoke` with clang 21; they passed, which incidentally
confirms the clang-21-vs-clang-18 ABI question of NOTES-A D1). Fix: give deps.sh
its own variables (`DEP_CC`/`DEP_CXX`, or read `DEPS_CXX`) independent of
paths.sh's `CXX`, or have build.sh/deps.sh run get_clang.sh first and build the
deps with the same compiler as Carbon. The installed archives are fine as built
(clang 18, libstdc++) and link and run end to end.

### R1-N1 (MINOR, owner A): bazel_graph.py's command line crashes

`python3 -I bazel_graph.py files|manifest|bytes|install-list` all die with
`NameError: name '_SAFE_BUILTINS' is not defined`: the dict is defined after the
`if __name__ == "__main__": sys.exit(_main(...))` block. Imports (gen_ninja.py)
work. NOTES-A "How to run" and "What was verified" cite these commands as run.
Fix: move `_SAFE_BUILTINS` above `_main`/the `__main__` block.

### R1-N2 (MINOR, owner A): build.sh's `[ninja targets...]` cannot be used as documented

Outputs in build.ninja are absolute paths, so `build.sh bin/file_test` (or
`ninja -C $BUILD_DIR bin/file_test`) fails with `unknown target`; only absolute
paths or `all` work. Fix: document absolute targets or emit `build bin/x: phony`
aliases.

### R1-N3 (MINOR, owner C): install.py's `bazel/runtimes_build_vars.bzl` is not Bazel's

install.py generates it with bzl_eval's deps-then-own flattening; two lines
(`runtimes/libc/internal/src/__support/CPP/{type_traits,utility}.h`) sit at
other positions than in bazel_graph.py's output, which is byte-identical to the
nightly (C's D13 acknowledges it). Not read by the gate or conformance. Fix:
take the text from `Graph.file_bytes` of
`//toolchain/install:bazel/runtimes_build_vars.bzl`, or install the whole data
tree from bazel_graph's `all_data_files` (the two evaluators agree on all 2205
paths and on every generated file sampled).

### R1-N4 (MINOR, owner C): the runfiles tree is a superset of Bazel's

Bazel's runfiles for `//toolchain/testing:file_test` (bazel_graph
`transitive_runfiles`, 4282 files) contain no
`toolchain/install/install_digest.txt`, `llvm/bin/*`, `carbon-busybox` or
`core/` source copies; runfiles.py links every top-level entry of `lib/carbon`
plus `_main/core -> REPO/core`. Harmless today (`driver/testdata/fail_config.carbon`
reads the digest through the VFS and passed; nothing reads `_main/core`),
recorded so that a future golden depending on absence is understood.

### R1-N5 (MINOR, owners A, C): overriding `ARB` alone breaks install.py; FORM notes

`LLVM_OVERLAY` and `DEPS` derive from `ARB`, so `ARB=/x install.py` fails with
"LLVM_OVERLAY ... is not a directory" unless `DEPS` is also overridden (the
README documents only `REPO`/`SHA` overrides, which work). install.py
(`shutil.rmtree` of `$INSTALL_DIR/{bin,lib}`) and gate.sh (`find $TEST_TMP
-mindepth 1 -delete`) delete through variables; both are guarded to paths under
`ARB`, which satisfies the intent of the FORM rule, noted for the record.
`file_test --dump_output` prints LLVM's `Warning: request a ThreadPool with 4
threads, but LLVM_ENABLE_THREADS has been turned off` (unconditional in
`SingleThreadExecutor` at this pin, same under Bazel); harmless.

## 2. What was checked and found correct

1.  Closure. An independent AST walk of the BUILD files (`$S/indep_closure.py`,
    no bazel_graph code) gives 150 cc targets +
    `//toolchain/base:llvm_tools_def` (a cc_library macro) = A's 151 Carbon
    labels (+ `@llvm-project//clang-tools-extra/clangd:ClangDaemon` = 152), the
    same 34 externals, and the same 320 compiled Carbon sources (393 objects
    with the 73 LLVM tool/clangd sources); the only `select()` in the closure (`toolchain/base:llvm_tools`
    linkopts, macOS branch) resolves to the default. Generated sources:
    version.cpp/version_nostamp.cpp/version_stamp.cpp run the real gen_tmpl.py
    with `VERSION=0.0.0-0.dev GIT_COMMIT_SHA=unknown GIT_DIRTY_SUFFIX=
    MAKE_WEAK=1|0` (nostamp; `internal_stamp_flag_detect` false); the file_test
    manifest (2047 workspace-relative entries), `clang_headers_manifest.txt`
    (326), prelude (36) and core-library manifests are byte-identical between
    A's bazel_graph and C's bzl_eval; `llvm_tools.def`, `runtimes_build_info.h`
    and the overlay copts lists come from the real rule code. Carbon's Bazel
    LLVM targets are X86 and AArch64 (bazel/llvm_project/llvm_project.bzl),
    exactly the CMake build's; every target triple used by a golden is x86_64 or
    aarch64/arm64; the default triple and
    `LLVM_ENABLE_THREADS/ZLIB/ABI_BREAKING_CHECKS` of llvm-config.h match
    Bazel's opt configuration.
2.  Flags. `carbon_cxxflags`/`external_cxxflags` match the `clang`,
    `clang_warnings`, `project_flags` and opt/fastbuild feature sets of
    bazel/cc_toolchains for linux x86_64; omissions are the documented libc++
    flags, `-rtlib=compiler-rt`, `-DBAZEL_COMPILE_CACHE_KEY`, colour/canonical
    prefixes; `-Wno-ctad-maybe-unsupported` and `-include variant -include
    cmath` are additive. All flags are probed against the compiler actually used
    (clang 21.1.8); the clang-18 question is moot since clang 18 is never used
    for Carbon sources. Link: `-fuse-ld=lld -static-libstdc++ -static-libgcc
    -lpthread -pie`, `--start-lib/--end-lib` per library, alwayslink objects
    plain, 176 LLVM archives in one group, `-lz -llzma -lpthread -ldl -lm -lrt`
    from CMakeCache; the binaries link and run.
3.  Deps. abseil 20260107.1, re2 2025-11-05, googletest 1.17.0, boost 1.90.0,
    rules_cc 0.2.25, Bazel 8.6.0 forwarder = MODULE.bazel/.bazelversion. gtest
    without gtest_main, `-DGTEST_HAS_ABSL=1` propagated to all 7 gtest-including
    TUs, link order gmock gtest re2 absl(91, topological) then LLVM, runfiles
    header at `tools/cpp/runfiles/runfiles.h` over `rules_cc/cc/runfiles`. The
    smoke programs pass; the patched file_test exercises gtest/absl flags, re2
    and the runfiles library end to end.
4.  Install. install.py's 2243 entries = A's `all_data_files` (2205) + busybox +
    digest + 36 `llvm/bin` links; every group of toolchain/install/BUILD is
    present with its prefix/remove_prefix/renames; `__config_site` (22 defines,
    `--defines K V` as configure_cmake_file.bzl passes them),
    `__assertion_handler`, `carbon_cc_toolchain_config.bzl`, outline atomics and
    `arm_neon.h` identical between the two evaluators and the nightly; nightly
    comparison differs only by the 7 added / 1 removed prelude files and
    `include/carbon/expected.h` (source changes). Run for real into a scratch
    root (`ARB=$S/arb DEPS=/home/user/arb/deps ... install.py`): 2074 copied,
    133 generated, 36 symlinks, busybox mode 0755, `bin/carbon ->
    ../lib/carbon/carbon-busybox`, digest 64 hex + newline produced by the real
    `make-installation-digest`; `./bin/carbon version` and
    `lib/carbon/llvm/bin/clang --version` work from that root.
5.  Gate. Paths traced through `install_paths.cpp` (Rlocation of
    `carbon/toolchain/install/carbon_install.txt` with `RUNFILES_DIR`, no
    `_repo_mapping` -> `carbon -> _main` link), the three manifests, the
    `llvm/bin`, `llvm/lib/clang/24`, `runtimes`, `include` dirs, the
    cwd-relative test names and `INCLUDE-FILE`s, `TEST_TMPDIR`;
    `BUILD_WORKING_DIRECTORY` unset;
    `G3_TARGET_NAME="//toolchain/testing:file_test"` equals the goldens' TIP
    lines; gate.sh's summary grep applied to the real 2047-test log yields
    `PASSED=2047 FAILED=0`; the `-###` and `config` goldens'
    `{{.*}}/toolchain/install/...` patterns match the runfiles root. The whole
    gate takes 20-47 s, well inside the 9-minute foreground limit.
6.  Conformance. `conformance.sh --background` from the scratch install
    (unpatched busybox, `XDG_CACHE_HOME=$S/cache`) finished in 55 s:
    `CONFORMANCE cb726a230: PASS 228 / FAIL 0 / SKIP 13 over 241 programs;
    bullets 51 PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN (of 56 ...) (runner exit 0)`;
    flags match runner.py's argparse; the `.done` marker holds 0.
7.  FORM. No interactive prompt: Carbon's patches 0002/0004/0005/0006/0012 touch
    only files under `utils/bazel/llvm-project-overlay`, which the copy
    contains, so `patch -N` never asks "File to patch"; downloads, extraction
    and builds are separate commands; `rm -rf` only on literal paths (variable
    deletions guarded, R1-N5); no loops over git output; python scripts run with
    `-I` (conformance.sh also `-B`). Re-runs: get_clang.sh and
    get_llvm_overlay.sh are no-ops when present; gen_ninja.py + `ninja -n`
    report no work; deps.sh validate/smoke, install.py
    --dry-run/--compare-nightly, runfiles.py --check (26 ok / 3 pending),
    gate.sh/autoupdate.sh/conformance.sh --check all pass.

## 3. Not verified

-   autoupdate.sh end to end (it writes into REPO; only its dry-run through the
    gate -- zero autoupdate differences on 2047 files -- and the write-through
    realpath check were exercised).
-   install.py into the real `/home/user/arb/install/cb726a230` (done in a
    scratch root instead; the authors' install there still lacks the busybox
    and the digest until install.py is run after build.sh).
-   Whether a libc++ build would hide R1-B1 the way Bazel's does.

## 4. Side effects of the review

`deps.sh validate smoke` rebuilt `/home/user/arb/deps/smoke/*` (with clang 21,
see R1-M1) and rewrote RESULTS.txt (6/6 PASS); `conformance.sh --check`
rewrote `/home/user/arb/logs/conformance-cb726a230-selftest.log`; gate.sh
--check re-verified the runfiles tree (no link changed). Nothing else under
`/home/user/arb` and nothing under REPO was written. Scratch artifacts
(fastbuild and patched binaries, logs, scratch install, upstream clone) are
under `$S` and can be deleted.

<!-- google-doc-style-resume -->
