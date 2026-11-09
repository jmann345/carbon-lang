<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# carbonbuild: the container arbiter (Bazel-free build of the Carbon toolchain)

<!-- google-doc-style-ignore -->

The fork is normally built and tested with Bazel on the owner's machine. This
directory builds the Carbon toolchain and its golden-test runner from the same
sources without Bazel, against an LLVM built from Carbon's pinned commit
(MODULE.bazel `git_override` for `llvm-raw`,
6ec87e7ec4b3ca6f665a02e05d0e5fe9c37cd6cc), installs the toolchain in the
packaged layout the nightly tarball uses, and runs the three acceptance checks:
the golden gate, autoupdate, and the execution-conformance harness. A previous
arbiter of this shape was lost in the 2026-11-09 container reset; this one is
re-created from the BUILD files.

## Pipeline

| Step | Script (author) | Produces |
| --- | --- | --- |
| 0 | `paths.sh` (shared) | the one configuration: `REPO`, `SHA`, `LLVM_SRC`, `LLVM_BUILD`, `LLVM_OVERLAY`, `DEPS`, `BUILD_DIR`, `INSTALL_DIR`, `CB`, `CXX`, `SRC_PATCHES`, `SRC_OVERLAY`, `FILE_TEST_BIN`, `BUSYBOX_BIN`, `DIGEST_BIN`, `RUNFILES_ROOT`, `LOGS`, `CACHE_HOME`, `TEST_TMP`, `CONFORMANCE_OUT`; every script sources it; python reads it through `paths.py` or by running it under bash |
| 1 | `deps.sh` (B) | abseil, re2, googletest (with absl), boost.unordered, Bazel's runfiles library under `$DEPS`, described by `$DEPS/deps.env` (NOTES-B.md). Built with its own `DEPS_CC`/`DEPS_CXX` (default: the system clang 18), never with paths.sh's `CXX`, so it runs before `get_clang.sh` |
| 2 | `get_llvm_overlay.sh`, `get_clang.sh`, `gen_ninja.py`, `build.sh` (A) | `$BUILD_DIR/bin/carbon-busybox`, `bin/file_test`, `bin/make-installation-digest`, `env.sh` (NOTES-A.md); `gen_ninja.py` also applies `$SRC_PATCHES/*.diff` to copies under `$SRC_OVERLAY` (section "Source patches" below) |
| 3 | `install.py` (C) | `$INSTALL_DIR` in the packaged layout; `$BUILD_DIR/clang_headers_manifest.txt`, `install_digest_manifest.txt` |
| 4 | `runfiles.py`, `gate.sh`, `autoupdate.sh`, `conformance.sh` (C) | the gate result, updated goldens, the conformance scoreboard |

Build another worktree or commit by overriding the variables:

```
REPO=/home/user/carbon-ehc SHA=1234567 /home/user/arb/carbonbuild/build.sh
REPO=/home/user/carbon-ehc SHA=1234567 python3 -I /home/user/arb/carbonbuild/install.py
REPO=/home/user/carbon-ehc SHA=1234567 /home/user/arb/carbonbuild/gate.sh
```

No script writes into `REPO` except `autoupdate.sh`, whose documented job is
to update goldens. Everything else lives under `/home/user/arb`.

Overriding `ARB` moves everything under it, the dependencies included:
`DEPS` and `LLVM_OVERLAY` derive from `ARB`, so `ARB=/x install.py` fails with
"LLVM_OVERLAY ... is not a directory" until `deps.sh`, `get_clang.sh` and
`get_llvm_overlay.sh` have populated `/x/deps`, or `DEPS=/home/user/arb/deps`
is passed as well (REVIEW-1 R1-N5). The deletions the scripts make through
variables (`install.py` recreates `$INSTALL_DIR/{bin,lib}`, `gate.sh` empties
`$TEST_TMP`) are guarded to paths under `ARB`.

## Source patches (`src-patches/`, fold after review 1)

The gate cannot pass on cb726a230 as the sources stand:
`toolchain/check/check.cpp` builds
`SmallVector<UnitAndImports, 0> unit_infos(llvm::map_range(...))`, and
`UnitAndImports` is self-referential (`emitter(&err_tracker, ...)`,
check_unit.h:79-83). libstdc++'s `std::uninitialized_copy` goes through
`std::_Construct(p, *first)` (bits/stl_uninitialized.h:120,
bits/stl_construct.h:109), whose forwarding reference materializes the lambda's
prvalue as a temporary and move-constructs the element from it, so every
element's `emitter.consumer_` points at a dead temporary and 15 goldens
crash (REVIEW-1 R1-B1). libc++, which Bazel's build uses, spells the standard's
`::new (p) T(*first)` directly, so C++17 guaranteed elision constructs the
element in place and nothing dangles. The fix (construct in place with
`reserve` + `emplace_back`) belongs in the repository, which the scripts never
write; until it lands, `gen_ninja.py` compiles a patched COPY:

```
src-patches/0001-check-unit-infos-in-place.diff   git-style unified diff (a/<path>, b/<path>)
$SRC_OVERLAY/toolchain/check/check.cpp            = REPO's file + the patch (write-if-changed)
$BUILD_DIR/src-patches.applied                    one line per patch: `applied` or `landed`
```

Rules: only directly compiled sources (`.cpp .cc .cxx .c`) can be patched (a
patched header cannot be made visible to ninja reliably; such a change must land
in REPO); the patched unit gets an extra `-ffile-prefix-map=$SRC_OVERLAY/=` so
`__FILE__` equals the unpatched build's, and no other object's command line
changes; a patch whose change is already in REPO (`patch --forward` reports it
as previously applied) is skipped and recorded as `landed`; one that does not
apply stops `gen_ninja.py` with the hunk output. `gate.sh` and `autoupdate.sh`
print the `src-patches.applied` line before their result, so a measurement of
`REPO at SHA + patches` is never mistaken for one of `REPO at SHA`. To land the
fix: `git -C $REPO apply $CB/src-patches/0001-check-unit-infos-in-place.diff`
(verified with `git apply --check`); the next `gen_ninja.py` then reports it as
`landed` and compiles REPO's file. `SRC_PATCHES=none` disables the mechanism
(the gate then aborts on cb726a230, as REVIEW-1 describes).

## Usage

```
# Install (after build.sh). Re-runnable: wipes and recreates $INSTALL_DIR/{bin,lib}.
python3 -I install.py --dry-run            # list every file with its source; fail on a missing source
python3 -I install.py                      # install; needs $BUSYBOX_BIN and $DIGEST_BIN
python3 -I install.py --allow-pending      # install everything but the busybox and the digest (exit 3)
python3 -I install.py --provenance         # the provenance table below
python3 -I install.py --compare-nightly /home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12

# The golden gate (//toolchain/testing:file_test over its whole manifest).
./gate.sh                                  # prints the gtest summary and `GATE <sha>: N passed, M failed`
./gate.sh --filter check/testdata/class    # --file_tests=*check/testdata/class* (gtest wildcard)
./gate.sh --threads 4
./gate.sh --check                          # build + verify the runfiles tree; run nothing
./gate.sh -- --gtest_brief=0               # extra binary arguments

# Autoupdate (the only script that writes into REPO), then `git status --porcelain`.
./autoupdate.sh [--filter SUBSTR] [--threads N]
./autoupdate.sh --check

# Execution-conformance harness (fork/conformance/runner.py).
./conformance.sh                           # foreground; prints the totals and `CONFORMANCE <sha>: ...`
./conformance.sh --background              # nohup; wait with: until [ -f $CONFORMANCE_OUT/.done ]; do sleep 20; done
./conformance.sh --filter types/
./conformance.sh --check                   # inputs + the runner's --self-test (241 programs, 56 bullets)
```

Logs: `$LOGS` (= `/home/user/arb/logs`): `gate-<sha>-<utc>.log`,
`autoupdate-<sha>-<utc>.log`, `conformance-<sha>.log` (+ `.nohup`,
`-selftest.log`). The conformance marker `$CONFORMANCE_OUT/.done` holds the
runner's exit code.

## Acceptance (measured on cb726a230 in a later phase)

| Check | Command | Expected |
| --- | --- | --- |
| golden gate | `gate.sh` | `[  PASSED  ] 2047 tests.` and `GATE cb726a230: 2047 passed, 0 failed` |
| autoupdate | `autoupdate.sh` | `git -C /home/user/carbon-trunk status --porcelain` stays empty; `AUTOUPDATE cb726a230: 0 file(s) changed` |
| conformance | `conformance.sh` (= `cd $REPO && python3 -I -B fork/conformance/runner.py --toolchain $INSTALL_DIR/lib/carbon/carbon-busybox --out $CONFORMANCE_OUT`) | `PASS 228 / FAIL 0 / SKIP 13` over 241 programs, 51 of 56 bullets |

`runfiles.py --check` already confirms the manifest size without running
anything: 2047 test files of `//toolchain/testing:all_testdata` resolve from
the runfiles cwd (2045 `.carbon` + 2 `.cpp` of `//toolchain/driver:testdata`).

On cb726a230 these numbers are reachable only with the source patch of the
section above compiled in (the binary's `src-patches.applied` line says so);
the fold after review 1 (2026-11-09) ran the whole pipeline with it:
`GATE cb726a230: 2047 passed, 0 failed` (`gate.sh --threads 4`, 9.5 s wall),
`autoupdate.sh --check` ok, `git status --porcelain` empty before and after,
and `conformance.sh --background` on the same install (NOTES-A.md, "Fold after
review 1"). The whole-manifest `autoupdate.sh` run itself is left to the
measurement phase.

## Provenance and acceptance (2026-11-09)

This directory, fork/tools/carbonbuild, is the record of the container
arbiter's scripts; /home/user/arb/carbonbuild is the running instance. The
2026-11-09 container reset destroyed the previous arbiter, whose scripts lived
only in a scratchpad, so the re-created scripts were landed here by the records
commit of ARB-2's close, after PR 69 (the fix of REVIEW-1 R1-B1 with its
records) landed on trunk by merge fca1e9e2f under R33, so that a reset cannot
lose them again. The two copies are kept synchronised by
`diff -r /home/user/arb/carbonbuild fork/tools/carbonbuild`; the expected
differences are the license headers, the formatter output of the repository's
prek hooks (ruff, clang-format, rumdl, trailing whitespace), the hand edits to
the markdown files listed in the messages of the records commit and its fold
(re-wraps where the reflow left lines over 80 columns, a scratchpad path and a
task reference reworded, this section) and the generated files the running
instance holds and the record does not (`env.sh`, written by gen_ninja.py, and
`__pycache__`). paths.sh points at the running instance; the record is not run
from the repository.

The repository's prek hooks run on the record. Two style rules are exempted for
this directory in pyproject.toml, ruff's `ANN` and `E501` for
`fork/tools/carbonbuild/*.py` (type annotations and line length, which the
formatter cannot supply; ty excludes the directory while `ANN` is exempted).
The defects ruff reported at the landing under `F401`, `F841`, `E741` and
`E402` (two unused imports, two unused locals, six `l`/`O` names, one late
import; 11 in all) were fixed in both copies under the orchestrator's ruling of
2026-11-09, not exempted. `crashers` and `sme` are in .codespell_ignore because
each names a real file: REVIEW-1.md's `$S/crashers.txt` (the reviewer's list
of the 15 crashing goldens) and the generated header `arm_sme.h` in the
`clang_builtin_hdrs` row below. The five markdown files are wrapped whole in
the Google-doc-style hook's ignore and resume markers, because `REPO` is a
variable name on nearly every page and the hook rewrites the word.

### The container's layout

The defaults of paths.sh are the container's layout; each is overridable by
exporting the variable before running a script (section "Pipeline" above):

| Variable | Default | What |
| --- | --- | --- |
| `ARB` | `/home/user/arb` | everything the arbiter writes: `deps/`, `build/<sha>/`, `install/<sha>/`, `logs/`, `cache/`, `conformance/<sha>/`, and the running instance `carbonbuild/` |
| `REPO` | `/home/user/carbon-trunk` | the Carbon checkout (a git worktree) to build; read-only for every script but autoupdate.sh |
| `SHA` | `cb726a230` | the commit being built; names the build, install and conformance directories |
| `LLVM_SRC` | `/home/user/llvm-project` | llvm-project at Carbon's pin 6ec87e7ec4b3ca6f665a02e05d0e5fe9c37cd6cc |
| `LLVM_BUILD` | `/home/user/llvm-build` | the CMake build of `LLVM_SRC` with the configuration below |

### The LLVM build

LLVM at Carbon's pin (MODULE.bazel's `git_override` for `llvm-raw`,
6ec87e7ec4b3ca6f665a02e05d0e5fe9c37cd6cc) was built with CMake (generator
Ninja, `$LLVM_SRC/llvm` into `$LLVM_BUILD`) by the system clang 18.1.3 as the
compiler of LLVM; `ninja -j4`, 3750 steps, about 30 minutes on this container.
The configuration:

```
-DCMAKE_BUILD_TYPE=Release
-DLLVM_ENABLE_PROJECTS='clang;lld'
-DLLVM_TARGETS_TO_BUILD='X86;AArch64'
-DLLVM_ENABLE_ASSERTIONS=OFF
-DLLVM_ENABLE_RTTI=OFF
-DLLVM_INCLUDE_TESTS=OFF
-DLLVM_INCLUDE_EXAMPLES=OFF
-DLLVM_INCLUDE_BENCHMARKS=OFF
-DLLVM_INCLUDE_DOCS=OFF
-DCLANG_INCLUDE_TESTS=OFF
-DCLANG_INCLUDE_DOCS=OFF
-DLLVM_ENABLE_ZLIB=ON
-DLLVM_ENABLE_ZSTD=OFF
-DLLVM_ENABLE_LIBXML2=OFF
-DLLVM_ENABLE_LIBEDIT=OFF
-DLLVM_ENABLE_TERMINFO=OFF
-DLLVM_USE_LINKER=lld
-DCMAKE_C_COMPILER=clang
-DCMAKE_CXX_COMPILER=clang++
-DLLVM_PARALLEL_LINK_JOBS=2
-DLLVM_BUILD_TOOLS=OFF
-DLLVM_BUILD_UTILS=ON
-DLLVM_INSTALL_UTILS=OFF
-DCLANG_BUILD_TOOLS=OFF
-DCLANG_ENABLE_ARCMT=OFF
-DCLANG_ENABLE_STATIC_ANALYZER=OFF
-DLLVM_ENABLE_BINDINGS=OFF
-DLLVM_ENABLE_OCAMLDOC=OFF
-DLLVM_ENABLE_Z3_SOLVER=OFF
```

`LLVM_BUILD_TOOLS=OFF` and `CLANG_BUILD_TOOLS=OFF` leave no `clang` driver in
`$LLVM_BUILD/bin` (Carbon links clang's libraries and needs none);
`clang-tblgen` and `llvm-tblgen` are built (`LLVM_BUILD_UTILS=ON`) for the
generated headers and the tool `Opts.inc` files. The host compiler of the Carbon
sources is the LLVM 21.1.8 release clang (get_clang.sh), and the dependencies
are built from source at MODULE.bazel's pins (deps.sh).

### Acceptance on the fix sha

Measured 2026-11-09 on 6de18c1f7 (ARB-2's fix, the first commit of PR 69; its
toolchain sources are the land tree's, trunk fca1e9e2f, because trunk
aee70185c did not move before the merge) with the repository alone, the overlay
reporting `0001-check-unit-infos-in-place.diff landed toolchain/check/check.cpp`
(`/home/user/arb/logs/build-6de18c1f7.log` line 7 and
`/home/user/arb/build/6de18c1f7/src-patches.applied`); opt, clang 21.1.8,
libstdc++. The `GATE`, `AUTOUPDATE` and `CONFORMANCE` lines are the scripts'
stdout (gate.sh, autoupdate.sh and conformance.sh print them; a log holds the
binary's or the runner's output, section "The gate harness" below), so the
table says what each log holds beside them:

| Check | Result (the script's stdout) | Log and what it holds |
| --- | --- | --- |
| golden gate | `GATE 6de18c1f7: 2047 passed, 0 failed` | `/home/user/arb/logs/gate-6de18c1f7-20261109T171409Z.log`: the gtest run, its summary `[  PASSED  ] 2047 tests.` and the source-patches line (`landed`) |
| autoupdate | `AUTOUPDATE 6de18c1f7: 0 file(s) changed (binary exit 0)`, after the script's `git status --porcelain` printout, empty before and after | `/home/user/arb/logs/autoupdate-6de18c1f7-20261109T171419Z.log`: the autoupdate pass's gtest run, `[  PASSED  ] 2047 tests.` and the source-patches line; the porcelain printout and the file count are not in the log (the worktree /home/user/carbon-arb2 is clean at b87f130b2 after both autoupdate passes) |
| conformance | `CONFORMANCE 6de18c1f7: PASS 228 / FAIL 0 / SKIP 13 over 241 programs; bullets 51 PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN (of 56 in the gap-analysis table) (runner exit 0)`, kept with the totals block in `/home/user/arb/logs/conformance-6de18c1f7.log.nohup` (the script's stdout as captured) | `/home/user/arb/logs/conformance-6de18c1f7.log`: the runner's output, one line per program and the totals block (lines 544 to 552: PASS 228, SKIP 13, every failure status 0, the bullets line); scoreboard `/home/user/arb/conformance/6de18c1f7/scoreboard.json` |

These are the values FO-1's stage 17 recorded at PR 66's landing on 2026-11-06
with the previous container arbiter (fork/ORCHESTRATION.md's paragraph dated
2026-11-06 (05:17 UTC): gate 2047 of 2047, conformance 228/0/13 over 241,
51/56 bullets), the same per program and per bullet. Container-measured,
EXPECTED, not of record under R9 (R33 (b)); R21's hosted gate is owed when
Actions returns. `src-patches/0001-check-unit-infos-in-place.diff` stays as
the landed-detector: gen_ninja.py reports it `landed` on every tree that holds
the fix and `applied` on one that does not, so a measurement of a tree without
the fix is never mistaken for one of the tree alone.

### Verification of the landing (the PR head)

The landing's own verification is the measurement of the PR head b87f130b2
itself (the fix with its two records commits; the land tree, trunk aee70185c
not having moved; the merge message's "Container-measured on the head"),
2026-11-09 18:01 to 18:12 UTC, before the merge at 18:14:39 UTC, with
`REPO=/home/user/carbon-arb2 SHA=b87f130b2`, opt, clang 21.1.8, libstdc++, the
overlay reporting `landed`; the same values per check as on 6de18c1f7:

| Check | Log and what it holds |
| --- | --- |
| build | `/home/user/arb/logs/build-b87f130b2.log`: gen_ninja.py's counts (207 targets, 393 objects, 2047 test files) and, line 7, `0001-check-unit-infos-in-place.diff landed (toolchain/check/check.cpp)`; `/home/user/arb/build/b87f130b2/src-patches.applied` the same |
| golden gate | `/home/user/arb/logs/gate-b87f130b2-20261109T181044Z.log`: `Ran 2047 tests`, `[  PASSED  ] 2047 tests.` and the source-patches line (`landed`): gate 2047 of 2047 |
| autoupdate | `/home/user/arb/logs/autoupdate-b87f130b2-20261109T181116Z.log`: the autoupdate pass's `[  PASSED  ] 2047 tests.` and the source-patches line; the worktree's `git status --porcelain` empty after it: autoupdate 0 changed |
| conformance | `/home/user/arb/logs/conformance-b87f130b2.log`: the totals block (lines 544 to 552: PASS 228, SKIP 13, every failure status 0; bullets 51 PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN of 56); `/home/user/arb/conformance/b87f130b2/scoreboard.json` (generated 2026-11-09T18:12:04Z, toolchain `/home/user/arb/install/b87f130b2/lib/carbon/carbon-busybox`) the same totals; the `CONFORMANCE b87f130b2: PASS 228 / FAIL 0 / SKIP 13 over 241 programs; ...` line in `/home/user/arb/logs/conformance-b87f130b2.log.nohup`: 228/0/13 over 241, 51/56 bullets |

## The install layout (`install.py`)

`toolchain/install/BUILD` builds a synthetic install rooted at the package;
`pkg_helpers.bzl` / `install_filegroups.bzl:toolchain_pkg_filegroup` pack it as

```
<prefix>/bin/carbon -> ../lib/carbon/carbon-busybox
<prefix>/lib/carbon/carbon-busybox                (mode 0755)
<prefix>/lib/carbon/<all_data_files> + install_digest.txt
<prefix>/lib/carbon/llvm/bin/<36 tools> -> ../../carbon-busybox
```

`install.py` evaluates the BUILD files themselves (`bzl_eval.py` executes the
Starlark as Python with stubs for unmodelled rules) so the file sets are the
rules' own: `toolchain/install/BUILD` for the targets, prefixes and renames,
`install_filegroups.bzl` for `_llvm_binaries` (from
`toolchain/base/llvm_tools.bzl`), `core/BUILD`'s globs,
`toolchain/runtimes/BUILD`'s `configure_cmake_file` defines,
`bazel/cc_toolchains/BUILD`'s `installed_cc_toolchain_starlark`, and the LLVM
overlay (`$LLVM_OVERLAY`, utils/bazel/llvm-project-overlay with Carbon's
`bazel/llvm_project/*.patch` applied, which add the libcxx/libcxxabi/libunwind
source filegroups) for the runtimes and clang headers. The manifests are
`bazel/manifest/defs.bzl`'s `manifest(strip_package_dir = True)`: one
package-relative path per line.

### Provenance (installed path -> source or generator)

2243 entries under `lib/carbon`: 2073 copied, 132 generated, 36 symlinks, plus
the busybox and the digest. LLVM major 24 (`cmake/Modules/LLVMVersion.cmake`,
what `@llvm-project//:vars.bzl` carries).

| BUILD target (toolchain/install/BUILD) | files | installed under `lib/carbon/` | source / generator |
| --- | --- | --- | --- |
| `install_marker` | 1 | `carbon_install.txt` | `REPO/toolchain/install/carbon_install.txt` |
| `carbon-busybox` | 1 | `carbon-busybox` | `$BUSYBOX_BIN` (build.sh), copied, mode 0755 |
| `llvm_bins` | 36 | `llvm/bin/` | symlinks `-> ../../carbon-busybox`; names = `install_filegroups.bzl _llvm_binaries` (clang, clang++, clang-cl, clang-cpp, ld.lld, ld64.lld, the 20 `LLVM_MAIN_TOOLS` bin names and the 10 `llvm-<alias>` of `LLVM_TOOL_ALIASES`) |
| `core` | 37 | `core/` | `REPO/core/prelude.carbon` + `core/prelude/**/*.carbon` (36, sorted as Bazel's glob) and the generated `prelude_manifest.txt` |
| `core_library` | 3 | `core/` | `REPO/core/**/*.carbon` minus the prelude (`io.carbon`, `io.impl.carbon`) and the generated `core_library_manifest.txt` |
| `support_hdrs` | 1 | `include/carbon/expected.h` | `REPO/toolchain/install/include/carbon/expected.h` (package path stripped) |
| `clang_builtin_hdrs` | 305 | `llvm/lib/clang/24/include/` | `@llvm-project//clang:builtin_headers_gen` = clang/BUILD.bazel `builtin_headers` (glob `lib/Headers/**/*.h` minus `openmp_wrappers/{stdlib,time}.h`, `ppc_wrappers/nmmintrin.h`, plus 17 listed extension-less or generated files): 296 copied from `LLVM_SRC/clang/lib/Headers/`; 9 tblgen-generated (`arm_bf16/cde/fp16/mve/neon/sme/sve/vector_types.h`, `riscv_vector.h`): copied from `LLVM_BUILD/lib/clang/24/include/` when CMake produced them (8; byte-identical to clang-tblgen, checked on arm_neon.h), else generated with `LLVM_BUILD/bin/clang-tblgen <opt> -I clang/include/clang/Basic <td>` (`riscv_vector.h`: CMake only generates it with the RISCV target) |
| `fuzzer_runtime_hdrs`, `profile_runtime_hdrs`, `sanitizer_runtime_hdrs` | 1, 1, 19 | `llvm/lib/clang/24/include/{fuzzer,profile,sanitizer}/` | `LLVM_SRC/compiler-rt/include/<dir>/*.h` (overlay `*_installed_hdrs` filegroups) |
| `builtins_all_srcs` | 365 | `runtimes/builtins/` | union of the 8 `@llvm-project//compiler-rt:builtins_{aarch64,i386,x86_64}_{srcs,textual_srcs}`, `builtins_crtbegin_src`, `builtins_crtend_src` (compiler-rt/BUILD.bazel globs + compiler-rt.bzl's override/textual filtering), `lib/builtins/` stripped: 240 copied from `LLVM_SRC/compiler-rt/lib/builtins/`; 125 `aarch64/outline_atomic_<pat><size>_<model>.S` generated as the genrule does (`#define L_<pat>`, `#define SIZE`, `#define MODEL` lines + `lse.S`) |
| `libcxx_basic_hdrs` | 1148 | `runtimes/libcxx/include/` | `@llvm-project//libcxx:libcxx_hdrs` (`include/*`, `include/experimental/*`, `include/ext/*`, `include/**/*.h` minus `*.in`, `CMakeLists.txt`, `__cxx03/`), copied from `LLVM_SRC/libcxx/include/` |
| `libcxx_gen_hdrs` | 2 | `runtimes/libcxx/include/__config_site`, `__assertion_handler` | `REPO/toolchain/runtimes/configure_cmake_file_impl.py --src LLVM_SRC/libcxx/include/__config_site.in --defines <the 22 of toolchain/runtimes/BUILD>` and `--src LLVM_SRC/libcxx/vendor/llvm/default_assertion_handler.in` |
| `libcxx_all_srcs` | 107 | `runtimes/libcxx/src/` | union of `libcxx_{linux,macos,win32}_srcs` from `LLVM_SRC/libcxx/src/` |
| `libcxxabi_hdrs`, `libcxxabi_srcs`, `libcxxabi_textual_srcs` | 2, 30, 2 | `runtimes/libcxxabi/{include,src}/` | `LLVM_SRC/libcxxabi/{include/*.h, src/**/*.{cpp,h}, src/**/*.{def,inc}}` |
| `libc_internal_libcxx_hdrs` | 127 | `runtimes/libc/internal/` | `@llvm-project//libc:libcxx_shared_headers_hdrs`: the transitive headers of `libcxx_shared_headers` (libc_build_rules.bzl `LibcLibraryInfo` aspect over `libc_support_library` deps), copied from `LLVM_SRC/libc/` keeping `hdr/`, `include/`, `shared/`, `src/` |
| `libunwind_hdrs`, `libunwind_srcs` | 7, 25 | `runtimes/libunwind/{include,src}/` | `LLVM_SRC/libunwind/{include/**/*.h, src/*.{cpp,hpp,c,h,S}}` |
| `installed_bazel_files` | 22 | `BUILD.bazel`, `MODULE.bazel`, `bazel/` | `toolchain/install/bazel/{install.BUILD -> BUILD.bazel, install.MODULE.bazel -> MODULE.bazel, empty.BUILD -> bazel/BUILD.bazel}`; `bazel/carbon_cc_toolchain_config.bzl` = `sed 's|//toolchain/runtimes:carbon_runtimes.bzl|//bazel:carbon_runtimes.bzl|'` of `bazel/cc_toolchains/carbon_cc_toolchain_config.bzl`; the 13 `bazel/cc_toolchains/*.bzl` of `installed_cc_toolchain_starlark`; `toolchain/install/bazel/{carbon_clang_variables,carbon_detected_variables.tpl,carbon_toolchain}.bzl`; `toolchain/runtimes/carbon_runtimes.bzl`; `bazel/runtimes_build_vars.bzl` = `toolchain/base/runtimes_build_vars.tpl.bzl` expanded with `runtimes_build_info.bzl`'s substitutions (copts from compiler-rt.bzl, libcxx_library.bzl, libunwind_library.bzl; the file lists above) |
| `install_digest` | 1 | `install_digest.txt` | `$DIGEST_BIN $BUILD_DIR/install_digest_manifest.txt <out>` (genrule `gen_digest`; the manifest lists every `all_data_files` entry in the filegroup's order, then the busybox) |
| (outside `lib/carbon`) | | `bin/carbon -> ../lib/carbon/carbon-busybox`; `$BUILD_DIR/clang_headers_manifest.txt` (326 lines: the `clang_hdrs` install paths, read through the runfiles by file_test); `$BUILD_DIR/install_digest_manifest.txt` (2206 lines); `$BUILD_DIR/file_test_manifest.txt` (2047 lines, written by runfiles.py) | |

### Comparison with the nightly (`carbon_toolchain-0.0.0-0.nightly.2026.10.12`)

`find .../lib/carbon -maxdepth 2 | sort` differs in one entry:
`lib/carbon/include` (and `include/carbon`) exists only here. The full file
lists share 2236 paths; every difference has a source-level reason:

| Path | Where | Reason |
| --- | --- | --- |
| `lib/carbon/include/carbon/expected.h` | only here | the `support_hdrs` target (`-isystem <root>/include` in toolchain/base/clang_invocation.cpp) was added to toolchain/install/BUILD after the nightly's commit |
| `core/prelude/try.carbon`, `types/{buf,result,slice}.carbon`, `types/cpp/{exception,slice,sum}.carbon` | only here | prelude files added in the fork by cb726a230 (`prelude_manifest.txt` lists them) |
| `core/prelude/types/array.carbon` | only nightly | removed from `core/prelude` by cb726a230 |

Everything else is identical in membership (365 builtins, 1150 libc++ headers,
107 libc++ sources, 34 libc++abi, 127 libc internal, 32 libunwind, 326 clang
headers, 36 llvm/bin links, 22 bazel files). Content: `__config_site`,
`__assertion_handler`, `carbon_cc_toolchain_config.bzl`,
`core_library_manifest.txt` and the `outline_atomic_*.S` files are
byte-identical to the nightly; `runtimes_build_vars.bzl` differs only in the
prelude list (above): since the fold after review 1 (R1-N3) its bytes come from
`bazel_graph.py` (Bazel's depset order, byte-identical to the nightly's apart
from the prelude list), with `bzl_eval.py`'s text checked for the same
membership. `carbon-busybox` and `install_digest.txt` are not expected to match
(different compiler and build).

## The gate harness (`runfiles.py`, `gate.sh`, `autoupdate.sh`)

`bazel test //toolchain/testing:file_test` runs the binary with cwd
`$TEST_SRCDIR/_main` and `RUNFILES_DIR` set; the test locates the install with
`InstallPaths::MakeForBazelRunfiles(exe_path)`
(toolchain/base/install_paths.cpp:46-60), i.e. the runfiles library's
`Rlocation("carbon/toolchain/install/carbon_install.txt")` (`BazelRoot`,
install_paths.cpp:23), reads the test files by their repo-relative manifest
names from the cwd (testing/file_test/test_file.cpp:903,
testing/base/file_helpers.cpp:25) and `INCLUDE-FILE`s the same way
(test_file.cpp:960). `runfiles.py` lays out exactly that:

```
$RUNFILES_ROOT/
  _main/                                   cwd of the binary
    toolchain/install/<entry>           -> $INSTALL_DIR/lib/carbon/<entry>
    toolchain/install/clang_headers_manifest.txt -> $BUILD_DIR/clang_headers_manifest.txt
    toolchain/{check,codegen,driver,format,language_server,lex,lower,parse,testing}/testdata
                                        -> $REPO/toolchain/<c>/testdata   (autoupdate writes through)
    core                                -> $REPO/core
  carbon -> _main                          Rlocation("carbon/...") without a _repo_mapping
                                           resolves to $RUNFILES_DIR/carbon/...
```

and `runfiles.py --check` verifies each path the C++ code opens (the marker;
the prelude, core-library and clang-headers manifests and every entry; the
`llvm/bin`, `llvm/lib/clang/24/include`, `runtimes`, `include` directories; the
nine testdata links into REPO; min_prelude; every test file of
`//toolchain/testing:all_testdata` and every `INCLUDE-FILE` path from the cwd;
`TEST_TMPDIR`), reporting the not-yet-built binaries as PENDING. The script's
docstring cites file:line for each path. The tree is a superset of Bazel's
runfiles for `//toolchain/testing:file_test` (REVIEW-1 R1-N4): it links every
entry of `lib/carbon` (so also `install_digest.txt`, `llvm/bin/`, the busybox)
and `_main/core`, which Bazel's 4282 runfiles do not contain; nothing in the
tests depends on their absence (`driver/testdata/fail_config.carbon` reads the
digest through the VFS and passes either way).

`gate.sh` sets `RUNFILES_DIR=TEST_SRCDIR=$RUNFILES_ROOT`,
`TEST_WORKSPACE=_main`, `TEST_TMPDIR=$TEST_TMP` (fresh per run; `%t` and
`MakeTmpDir`), `XDG_CACHE_HOME=$CACHE_HOME`, unsets `BUILD_WORKING_DIRECTORY`
(common/bazel_working_dir.h would chdir), sources `env.sh` (the `cc_env()`
variables of bazel/cc_toolchains/defs.bzl), runs `$FILE_TEST_BIN
[--file_tests=*SUBSTR*] [--threads=N]` from `_main` and parses gtest's brief
summary (`[  PASSED  ] N tests.`, `[  FAILED  ] N tests, listed below:`).
`autoupdate.sh` runs the same with `--autoupdate` and prints `git -C $REPO
status --porcelain`.

## The conformance harness (`conformance.sh`)

Runs `python3 -I -B fork/conformance/runner.py --toolchain
$INSTALL_DIR/lib/carbon/carbon-busybox --out $CONFORMANCE_OUT` from `$REPO` with
`XDG_CACHE_HOME=$CACHE_HOME`. The busybox finds its install by its own path
(`InstallPaths::MakeExeRelative`, toolchain/install/busybox_main.cpp:37) and
`carbon link` builds the runtimes (builtins, libc++, prelude objects) on demand
into the cache, keyed on `install_digest.txt`
(toolchain/driver/runtimes_cache.cpp:142-163,182): the first link after a fresh
install takes minutes (the runner's `--link-timeout` default is 1800 s). The
runner's `find_clangxx` uses `lib/carbon/llvm/bin/clang++` next to the busybox.
`--background` runs it under nohup; the marker `$CONFORMANCE_OUT/.done` holds
the exit code. `-B` keeps python from writing `__pycache__` into REPO (the
runner imports `fork/evaluator/check_samples.py` and
`fork/designdocs/check_samples.py`).

## Files

| File | Purpose |
| --- | --- |
| `paths.sh`, `paths.py` | shared configuration |
| `bzl_eval.py` | evaluates BUILD/.bzl files as Python; resolves overlay filegroups, compiler-rt's filtered builtins groups, the lse.S genrule, clang's tblgen headers, libc's header closure |
| `install.py` | the install tree, manifests, digest; `--dry-run`, `--provenance`, `--compare-nightly` |
| `runfiles.py` | the runfiles tree and its verification; writes `$BUILD_DIR/file_test_manifest.txt` |
| `gate.sh`, `autoupdate.sh`, `conformance.sh` | the three checks |
| `deps.sh`, `absl_link_order.py`, `deps_smoke/` | the third-party dependencies and their smoke programs (NOTES-B.md) |
| `get_clang.sh`, `get_llvm_overlay.sh`, `bazel_graph.py`, `gen_ninja.py`, `build.sh`, `env.sh` | the compiler, the patched LLVM overlay, the Bazel graph evaluator, the ninja file and the build (NOTES-A.md); `build.sh [all | file_test | carbon-busybox | make-installation-digest | bin/<name>]` |
| `src-patches/*.diff` | source patches `gen_ninja.py` compiles into copies of REPO files (section above) |
| `NOTES-A.md`, `NOTES-B.md`, `NOTES-C.md` | each author's record: what was done, verified, left unverified, and every decision with its reason; each ends with "Fold after review 1" naming the REVIEW-1 findings applied or rejected |
| `REVIEW-1.md` | the adversarial review of the scaffold (verdict FIX; 1 blocker, 1 major, 5 minor) |

<!-- google-doc-style-resume -->
