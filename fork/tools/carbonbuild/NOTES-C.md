<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# NOTES-C: the install tree and the harness (author C)

<!-- google-doc-style-ignore -->

Date: 2026-11-09. Repo: /home/user/carbon-trunk at cb726a230 (read-only; `git
status --porcelain`, including ignored files, is empty after everything below).
Everything lives under /home/user/arb. LLVM: /home/user/llvm-project at Carbon's
pin, CMake build /home/user/llvm-build (finished at [3750/3750] before I
started; `LLVM_BUILD_TOOLS=OFF`, `CLANG_BUILD_TOOLS=OFF`, so no `clang` driver
binary, but `clang-tblgen` and `lib/clang/24/include` exist).

## Deliverables

| Path | What |
| --- | --- |
| `/home/user/arb/carbonbuild/paths.sh` | appended my block: `FILE_TEST_BIN`, `BUSYBOX_BIN`, `DIGEST_BIN` (= `$BUILD_DIR/bin/{file_test,carbon-busybox,make-installation-digest}`, the fixed names agreed with author A's build.sh), `RUNFILES_ROOT`, `LOGS`, `CACHE_HOME`, `TEST_TMP`, `CONFORMANCE_OUT`; author B's and author A's blocks untouched |
| `bzl_eval.py` | evaluates Bazel BUILD/.bzl files as Python with stubs; resolves overlay filegroups (compiler-rt.bzl's filtered builtins groups, the lse.S genrule, clang's tblgen headers, libc's `LibcLibraryInfo` header closure) and Carbon's BUILD files |
| `install.py` | the install tree in the packaged layout; `--dry-run`, `--allow-pending`, `--provenance`, `--compare-nightly DIR` |
| `runfiles.py` | builds and verifies the runfiles tree; writes `$BUILD_DIR/file_test_manifest.txt` |
| `gate.sh` | the golden gate; `--filter`, `--threads`, `--check`, `-- ARGS`; prints `GATE <sha>: N passed, M failed` |
| `autoupdate.sh` | `--autoupdate` run + `git -C $REPO status --porcelain`; `--check` |
| `conformance.sh` | the conformance runner; `--filter`, `--background` (nohup + `.done` marker), `--check` |
| `README.md` | usage, acceptance values, provenance table, nightly comparison, the runfiles design |
| `/home/user/arb/install/cb726a230/` | installed now with `--allow-pending`: everything except `lib/carbon/carbon-busybox` and `install_digest.txt` (2073 copied, 132 generated, 36 symlinks; 34 MB) |
| `/home/user/arb/build/cb726a230/{clang_headers_manifest.txt,install_digest_manifest.txt,file_test_manifest.txt,runfiles/,test_tmp/}` | build artifacts of install.py / runfiles.py |

## What I did

1.  Read toolchain/install/BUILD, install_filegroups.bzl, symlink_helpers.bzl,
    pkg_helpers.bzl, toolchain/base/llvm_tools.bzl, install_paths.{h,cpp},
    toolchain/runtimes/BUILD, configure_cmake_file.bzl,
    configure_cmake_file_impl.py, toolchain/base/runtimes_build_info.bzl,
    runtimes_build_vars.tpl.bzl, bazel/manifest/defs.bzl,
    make_installation_digest.cpp, busybox_main.cpp, busybox_info.cpp,
    toolchain/driver/runtimes_cache.cpp (cache dir and digest use),
    testing/file_test/{file_test_base.cpp,test_file.cpp,run_test.cpp,
    rules.bzl,manifest.cpp}, testing/base/file_helpers.cpp,
    toolchain/testing/{file_test.cpp,BUILD}, common/{exe_path.cpp,
    bazel_working_dir.h,filesystem.cpp}, bazel/cc_toolchains/defs.bzl,
    bazel/cc_rules/defs.bzl, core/BUILD, bazel/llvm_project/*.patch,
    fork/conformance/README.md and runner.py's argparse / env / summary code,
    the rules_cc runfiles implementation in $DEPS/runfiles/src/runfiles.cc, and
    the overlay BUILD.bazel files for compiler-rt, libcxx, libcxxabi, libunwind,
    libc (libc_build_rules.bzl) and clang (`builtin_headers`,
    `builtin_headers_gen`).
2.  Found that the pinned overlay has NO libcxx/libcxxabi packages and no
    libunwind source filegroups: Carbon's `bazel/llvm_project/0004_*.patch` and
    `0005_*.patch` add them (0002 the fuzzer target, 0006 more libc-math
    builtins excludes, 0012 libc deps). Author A's `get_llvm_overlay.sh` had
    already produced the patched copy at `$LLVM_OVERLAY`; install.py reads it
    from there (D2).
3.  Wrote bzl_eval.py and validated every overlay-derived file set against the
    nightly's file list (see "Verified").
4.  Wrote install.py, ran `--dry-run` (2243 entries, 2 pending, 0 problems),
    `--compare-nightly`, `--provenance`, then `--allow-pending` to materialize
    the install, and diffed the generated files against the nightly.
5.  Wrote runfiles.py, gate.sh, autoupdate.sh, conformance.sh; ran
    `runfiles.py`, `gate.sh --check`, `autoupdate.sh --check`,
    `conformance.sh --check`.
6.  Wrote README.md (provenance table, differences, design) and these notes.

## Verified (now, without the Carbon binaries)

-   bzl_eval.py resolves all 21 overlay labels Carbon's install BUILD uses, in
    0.4 s. Membership against the nightly
    (`carbon_toolchain-0.0.0-0.nightly.2026.10.12`, same LLVM major, close pin):
    builtins 365 = 365, libc++ headers 1148 + 2 generated = 1150, libc++ sources
    107 = 107, libc++abi 34 = 34, libc internal 127 = 127, libunwind 32 = 32,
    clang headers 326 = 326 (305 builtin + 1 + 1 + 19). Zero paths differ.
    Ordering matches the nightly's `runtimes_build_vars.bzl` for every list
    spot-checked (x86_64 first 7, aarch64 first 8 incl. the generated outline
    atomics, libc first 6 and last 3), except two libc entries (D13).
-   `install.py --dry-run`: every source resolves; `clang builtin headers dir
    /home/user/llvm-build/lib/clang/24/include: 257 entries` (present); PENDING
    only `carbon-busybox` and `install_digest.txt`.
-   `install.py --compare-nightly`: 2236 paths in both; 8 only here, 1 only in
    the nightly, each explained by a source change between the nightly's commit
    and cb726a230 (README).
-   Generated content vs the nightly: `runtimes/libcxx/include/__config_site`
    IDENTICAL, `__assertion_handler` IDENTICAL,
    `bazel/carbon_cc_toolchain_config.bzl` IDENTICAL,
    `core/core_library_manifest.txt` IDENTICAL,
    `runtimes/builtins/aarch64/outline_atomic_cas16_3.S` IDENTICAL (genrule
    recipe), `core/prelude_manifest.txt` identical except the 7 added / 1
    removed prelude files, `bazel/runtimes_build_vars.bzl` identical except
    those prelude lines and the position of
    `src/__support/CPP/{type_traits,utility}.h`.
-   clang-tblgen reproduces CMake's output: `clang-tblgen -gen-arm-neon -I
    clang/include/clang/Basic arm_neon.td` is byte-identical to
    `/home/user/llvm-build/lib/clang/24/include/arm_neon.h`; `riscv_vector.h`
    (19119 bytes) generated the same way (CMake only builds it with the RISCV
    target, which this LLVM build lacks).
-   `install_filegroups.bzl` evaluates to the 36 `_llvm_binaries` names, equal
    to the nightly's `llvm/bin` listing.
-   `runfiles.py`: 25 ok, 4 pending, 0 errors: the marker through
    `$RUNFILES_DIR/carbon/toolchain/install/`, 36 prelude manifest entries, 2
    core library entries, 326 clang header manifest entries, llvm/bin, runtimes,
    include, llvm/lib/clang/24/include, the 9 testdata links (each realpath
    inside REPO), min_prelude, core, **2047 test files** of
    `//toolchain/testing:all_testdata` (the acceptance count) and 12 distinct
    `INCLUDE-FILE` paths resolve from `_main`.
-   `gate.sh --check`, `autoupdate.sh --check` (write-through:
    `_main/toolchain/check/testdata/patterns/underscore.carbon` realpaths to the
    golden in REPO), `conformance.sh --check` (busybox PENDING;
    `llvm/bin/clang++` present; cache writable; `runner.py --self-test`: 241
    programs parsed, 56 bullets in table, OK) all exit 0.
-   REPO untouched: `git -C /home/user/carbon-trunk status --porcelain
    --ignored` empty at the end (the runner's self-test had written two
    gitignored `__pycache__` dirs on the first run; removed, and conformance.sh
    now runs `python3 -I -B`, D11).

## Unverified (needs author A's binaries; the later measurement phase)

-   Running `install.py` to completion (busybox copy with mode 0755, the digest
    via `make-installation-digest`), and the three harness runs end to end: the
    gate's 2047/0, autoupdate leaving `git status` empty, conformance
    228/0/13. Every path was verified by construction and by `--check`, not by
    executing the binaries.
-   gate.sh's summary parsing against real gtest output (`[  PASSED  ] N tests.`
    / `[  FAILED  ] N tests, listed below:` with `--gtest_brief=1`, the binary's
    default set in file_test_base.cpp:635); a run without a PASSED line is
    reported as a failure with the binary's exit code.
-   The runfiles library's discovery at run time: `Runfiles::Create(argv0)`
    reads `RUNFILES_DIR` (runfiles.cc:404-406, PathsFrom checks `IsDirectory`),
    which gate.sh exports; read in code, not executed.
-   Driver tests that subprocess clang through
    `toolchain/install/llvm/bin/clang` (-> `../../carbon-busybox`):
    busybox_info.cpp resolves the symlink chain and `MakeExeRelative` then roots
    the install at the REAL `$INSTALL_DIR/lib/carbon`, not at the runfiles path;
    same files, so no difference is expected.
-   Whether any golden embeds an absolute install path (none expected: the tests
    pass `--exclude-dump-file-prefix=<core_package>`; Bazel's sandbox paths
    differ per machine too).
-   `TEST_TMPDIR`-based `%t` and `MakeTmpDir` (which uses
    `BuildData::BuildTarget` from author A's linkstamp) under the real binary.
-   The libstdc++ vs libc++ and clang-21 choices are authors B/A's (NOTES-B D1,
    NOTES-A D1) and can only be judged by the gate.

## Decisions (reason; break condition)

-   D1 Evaluate the BUILD files instead of hand-copying lists. bzl_eval.py execs
    Starlark as Python (a syntactic subset) with stubs for unmodelled symbols
    and real implementations of `glob`, `filegroup`, `alias`, `genrule`,
    `gentbl_cc_library`, `cc_library`, `select`, `selects.with_or`, `load`,
    compiler-rt.bzl's `make_filtered_builtins_srcs_groups` and
    libc_build_rules.bzl's `libc_*` family. Reason: the sets then follow the
    rules' own globs/excludes/filters (validated 100% against the nightly) and a
    change in the BUILD files is picked up. Starlark-vs-Python differences met:
    `dict.values()/keys()/items()` are lists in Starlark (AST rewrite wraps them
    in `list()`); names are stubbed whenever read. Break: a construct outside
    Python's syntax, an unmodelled rule reaching the file graph, a `select()`
    without a default branch on a path that matters, or a genrule whose `cmd` is
    not the `echo ... >> $(OUTS) && cat $(SRCS)` shape: each raises `BzlError`
    and install.py exits with `ERROR:` lines and nothing installed.
-   D2 Overlay source = `$LLVM_OVERLAY` (author A's patched copy under
    `$DEPS/llvm-overlay`), not `$LLVM_SRC/utils/bazel/llvm-project-overlay`.
    Reason: the pinned overlay lacks libcxx/libcxxabi/libunwind filegroups;
    Carbon adds them by patch (MODULE.bazel git_override patches
    0002/0004/0005/0006/0012). Break: the copy missing -> `no BUILD.bazel/BUILD
    for package libcxx`. The .bzl copts for runtimes_build_vars.bzl are read
    from the same copy.
-   D3 clang builtin headers: Bazel's `builtin_headers` (glob + 17 listed) is
    evaluated from clang/BUILD.bazel; the 9 tblgen-generated headers are taken
    from `$LLVM_BUILD/lib/clang/24/include/` when present (CMake output,
    byte-identical to clang-tblgen) and generated with `clang-tblgen <opt> -I
    clang/include/clang/Basic <td>` otherwise (`riscv_vector.h` always, since
    CMake gates it on the RISCV target). Break: neither the CMake file nor
    `$LLVM_BUILD/bin/clang-tblgen` exists -> dry-run ERROR.
-   D4 Runfiles root: `carbon -> _main` symlink rather than a `_repo_mapping`
    file. install_paths.cpp:23 uses `BazelRoot = "carbon/toolchain/install/"`;
    rules_cc's `Rlocation` without a repo mapping returns `RUNFILES_DIR + "/" +
    path` (runfiles.cc:199-241,243-270), so `carbon/...` must exist. Both names
    therefore resolve. Break: a `_repo_mapping` file appearing in the tree would
    make Rlocation map `carbon` through it instead.
-   D5 cwd = `$RUNFILES_ROOT/_main` with `toolchain/<c>/testdata` and `core`
    symlinks into REPO (as the task specified) rather than cwd = REPO. Reason:
    faithful to `bazel test` and confines the binary's writes to the testdata
    links; test names are read relative to the cwd (test_file.cpp:903) and
    autoupdate writes `std::filesystem::absolute(test_name)` through the link.
    Alternative kept in mind: cwd = REPO works with the same RUNFILES_DIR and
    needs no testdata links. Break: a test reading a repo file outside
    `toolchain/*/testdata`, `toolchain/testing/testdata` or `core/`
    (runfiles.py's INCLUDE-FILE scan would report it).
-   D6 install_digest_manifest.txt order = `all_data_files`' srcs order (each
    `toolchain_files` in its own srcs order), then `carbon-busybox`, absolute
    paths; the digest runs with cwd `lib/carbon` and `BUILD_WORKING_DIRECTORY`
    unset. make_installation_digest.cpp:88-97 takes the install path from the
    components after a `prefix` component, which no path has (in Bazel either),
    so the digest is over contents in manifest order. It only needs to be a
    stable cache key (runtimes_cache.cpp:182,232). Break: none for the
    acceptance; a digest differing from Bazel's is expected.
-   D7 Manifests (`prelude_manifest.txt`, `core_library_manifest.txt`,
    `clang_headers_manifest.txt`) implemented in install.py per
    bazel/manifest/defs.bzl (`strip_package_dir`, one path per line, trailing
    newline). Author A's bazel_graph.py exposes `Graph.manifest_text(label)`,
    not the agreed module-level `manifest` function, and constructing its Graph
    is its own machinery, so install.py does not depend on it. Validated: the
    core library manifest is byte-identical to the nightly's, the prelude
    manifest identical modulo the source changes.
-   D8 The install was materialized now with `--allow-pending` (exit 3 by
    design) to validate the generators and let runfiles.py verify the tree. The
    final `install.py` (no flag) must run after build.sh: it wipes and recreates
    `$INSTALL_DIR/{bin,lib}` and computes the digest over the real busybox.
    Guard: INSTALL_DIR, BUILD_DIR and RUNFILES_ROOT must be under ARB.
-   D9 `gate.sh --filter SUBSTR` becomes `--file_tests=*SUBSTR*`:
    `MaybeApplyFileTestsFlag` (file_test_base.cpp:337-348) turns each entry into
    a `ToolchainFileTest.<entry>` gtest_filter pattern, and gtest patterns
    accept `*`. Break: a SUBSTR containing `:` or `,` (gtest's separators).
-   D10 Environment for the binary: `RUNFILES_DIR=TEST_SRCDIR=$RUNFILES_ROOT`,
    `TEST_WORKSPACE=_main`, `TEST_TMPDIR=$BUILD_DIR/test_tmp` (emptied per run,
    only when under ARB), `XDG_CACHE_HOME=$ARB/cache` (runtimes_cache.cpp:142),
    `BUILD_WORKING_DIRECTORY` and `RUNFILES_MANIFEST_FILE` unset, `env.sh`
    sourced when present (author A's `cc_env()` exports). HOME is left alone.
-   D11 conformance.sh runs `python3 -I -B`: `-I` for the untrusted-input rule,
    `-B` because the runner imports `fork/evaluator/check_samples.py` and
    `fork/designdocs/check_samples.py` and python wrote gitignored `__pycache__`
    dirs into REPO on the first `--check` (removed; `-I` ignores
    `PYTHONDONTWRITEBYTECODE`, hence the flag).
-   D12 conformance `--check` runs the runner's `--self-test` with `--out
    $CONFORMANCE_OUT` (no toolchain needed; validates the 241 program headers
    and 56 bullet names) and probes the busybox, the digest, `llvm/bin/clang++`
    (runner.py `find_clangxx`) and the cache dir.
-   D13 `bazel/runtimes_build_vars.bzl` is generated (cheap once the lists are
    resolved) with runtimes_build_info.bzl's substitutions applied sequentially
    to the template. Two libc header lines sit at different positions than in
    the nightly (Bazel's depset default order vs my deps-then-own flattening);
    membership identical. Accepted: the file is only read by Bazel consumers of
    an installed toolchain, not by the gate or the conformance runner. Break:
    none for the acceptance.
-   D14 The install copies files (not symlinks): the packaged layout the nightly
    has, 34 MB, so the install can be tarred or moved. The runfiles tree
    symlinks into it.
-   D15 `installed_bazel_files` (BUILD.bazel, MODULE.bazel, 20 files under
    bazel/) are installed although the gate and conformance do not need them:
    they cost nothing and keep the layout identical to the nightly.
-   D16 runfiles.py writes `$BUILD_DIR/file_test_manifest.txt`: the 2047 test
    paths of `//toolchain/testing:all_testdata` in Bazel's order (filegroup
    order of toolchain/testing/BUILD, each component's glob sorted), for author
    A's `manifest_as_cpp` (`CarbonFileTestManifest`) and as the gate's expected
    count.

## Notes for authors A and B

-   paths.sh now carries the fixed binary names: `$BUILD_DIR/bin/file_test`,
    `bin/carbon-busybox`, `bin/make-installation-digest` (`FILE_TEST_BIN`,
    `BUSYBOX_BIN`, `DIGEST_BIN`), which build.sh already produces (env.sh's last
    line names the same three paths).
-   `$BUILD_DIR/file_test_manifest.txt` is the test manifest in Bazel order
    (D16); the binary must list exactly these repo-relative names.
-   gate.sh sources `env.sh` when present; its variables must be `export`ed
    (they are).
-   Nothing here reads deps.env.

## How to run (after build.sh)

```
cd /home/user/arb/carbonbuild
python3 -I install.py            # or --dry-run first
./gate.sh                        # GATE cb726a230: 2047 passed, 0 failed
./autoupdate.sh                  # AUTOUPDATE cb726a230: 0 file(s) changed
./conformance.sh --background    # until [ -f /home/user/arb/conformance/cb726a230/.done ]; do sleep 20; done
tail -12 /home/user/arb/logs/conformance-cb726a230.log
```

## Fold after review 1 (2026-11-09, fixer)

-   R1-N3 (MINOR) APPLIED: install.py's `gen_runtimes_build_vars` keeps
    bzl_eval's expansion but returns bazel_graph.py's bytes for
    `//toolchain/install:bazel/runtimes_build_vars.bzl` (`Graph.files_of` +
    `file_bytes`, Bazel's depset order, byte-identical to the nightly apart from
    the prelude list) after checking that the two texts have the same lines; a
    difference beyond line order exits loudly (an evaluator bug), an unavailable
    bazel_graph falls back to bzl_eval's text with a note. `PATH_VARS` gained
    `CARBON_BUILD_MODE` for the Graph constructor. D13 is superseded. Verified:
    the installed `lib/carbon/bazel/runtimes_build_vars.bzl` is `cmp`-identical
    to `python3 -I bazel_graph.py bytes
    //toolchain/install:bazel/runtimes_build_vars.bzl`; `install.py --dry-run`:
    2243 entries (2074 copy, 133 gen, 36 symlink), 0 problems; the real
    `install.py` run with the fixer's binaries: 2074 copied, 133 generated, 36
    symlinked, busybox 0755, digest
    0858677c6bec5fac79a6f18262599cda8a3d90fde8d057a40ae46542dac9658c.
-   R1-N4 (MINOR) RECORDED, no change: the runfiles tree links every entry of
    `lib/carbon` (so also `install_digest.txt`, `llvm/bin/`, `carbon-busybox`)
    and `_main/core`, which Bazel's 4282 runfiles of
    `//toolchain/testing:file_test` do not contain (bazel_graph
    `transitive_runfiles`). Harmless today (`driver/testdata/fail_config.carbon`
    reads the digest through the VFS and passes); restricting the links to
    Bazel's set is possible but gains nothing. Break: a golden that depends on
    one of these being absent. README's gate section says so.
-   R1-N5 (MINOR) APPLIED as documentation (README: an `ARB` override needs the
    deps under it or `DEPS=`); the guarded deletions (install.py's rmtree of
    `$INSTALL_DIR/{bin,lib}`, gate.sh's `find $TEST_TMP -mindepth 1 -delete`,
    both only under `ARB`) are kept.
-   R1-B1 (owner A) touches gate.sh: it now prints the line `gate <sha>: source
    patches in <binary> (SRC_PATCHES=...): <patch> applied|landed <paths>;`
    (from `$BUILD_DIR/src-patches.applied`, written by gen_ninja.py) right after
    the binary runs, for gate and autoupdate alike, so a result measured on
    "REPO at the sha + patches" is labelled; the `GATE <sha>: N passed, M
    failed` and `AUTOUPDATE` lines are unchanged.
-   Verified end to end on the fixer's build and install (patched check.cpp, see
    NOTES-A.md): `gate.sh --threads 4` -> `[  PASSED  ] 2047 tests.`, `GATE
    cb726a230: 2047 passed, 0 failed` (9.5 s wall, 35 s across threads);
    `gate.sh --check` (via `autoupdate.sh --check`): runfiles 28 ok, 0 pending,
    0 errors, write-through into REPO proven; `conformance.sh --background`:
    PASS 228 / COMPILE-FAIL 0 / LINK-FAIL 0 / RUN-FAIL 0 / OUTPUT-MISMATCH 0 /
    DIFF-MISMATCH 0 / SKIP 13, bullets 51 PASS, 0 FAIL, 5 SKIP, 0 NOT-WRITTEN of
    56, marker 0 (log /home/user/arb/logs/conformance-cb726a230.log); `git -C
    /home/user/carbon-trunk status --porcelain --ignored` empty before and
    after. The whole-manifest `autoupdate.sh` run is left to the measurement
    phase (the gate's dry-run reported no autoupdate difference on any golden).

<!-- google-doc-style-resume -->
