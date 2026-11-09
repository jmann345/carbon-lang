<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# NOTES-B: third-party dependencies for the container arbiter (author B)

<!-- google-doc-style-ignore -->

Date: 2026-11-09. Repo: /home/user/carbon-trunk at cb726a230 (read-only; nothing
under it was touched). Everything here lives under /home/user/arb.

## Deliverables

| Path | What |
| --- | --- |
| `/home/user/arb/carbonbuild/paths.sh` | shared config (REPO, SHA, LLVM_SRC, LLVM_BUILD, DEPS, BUILD_DIR, INSTALL_DIR, CB), created because it did not exist yet; plain `NAME="${NAME:-default}"` lines so python can parse it |
| `/home/user/arb/carbonbuild/deps.sh` | re-runnable fetch+build of every dependency into `$DEPS`; one function per dependency (`dep_absl`, `dep_re2`, `dep_googletest`, `dep_boost`, `dep_runfiles`) plus `write_env`, `validate_env`, `smoke`; `deps.sh [step...]`, no args = all |
| `/home/user/arb/carbonbuild/absl_link_order.py` | derives the abseil static link order from the installed CMake export files (run with `python3 -I`) |
| `/home/user/arb/carbonbuild/deps_smoke/*.cpp` | one smoke program per dependency, compiled and run by `deps.sh smoke` |
| `/home/user/arb/deps/deps.env` | the contract read by gen_ninja.py and the other scripts (generated; see "deps.env contract") |
| `/home/user/arb/deps/absl_libs.rsp`, `test_link_libs.rsp` | linker response files (generated) |
| `/home/user/arb/deps/{absl,re2,googletest,boost,runfiles}` | the installs; `src/` the shallow clones; `build/` CMake build trees; `logs/`; `smoke/RESULTS.txt` |

## What was fetched, from where (MODULE.bazel and .bazelversion of the repo)

| Module (MODULE.bazel) | Source | Tag | Commit |
| --- | --- | --- | --- |
| abseil-cpp 20260107.1 | github.com/abseil/abseil-cpp | 20260107.1 | 255c84dadd029fd8ad25c5efb5933e47beaa00c7 |
| re2 2025-11-05.bcr.1 | github.com/google/re2 | 2025-11-05 | 927f5d53caf8111721e734cf24724686bb745f55 |
| googletest 1.17.0.bcr.2 | github.com/google/googletest | v1.17.0 | 52eb8108c5bdec04579160ae17225d66034bd723 |
| boost.unordered 1.90.0.bcr.1 | github.com/boostorg/{unordered,assert,config,container_hash,core,describe,mp11,predef,throw_exception} | boost-1.90.0 | unordered=11e05a3c4c44 assert=e107bd7b556d config=a7d5a9b05d70 container_hash=060d4aea6b5b core=239953da9f0f describe=ee215421cb33 mp11=fe7447470d96 predef=e1211a4ca467 throw_exception=74bea78a391c |
| rules_cc 0.2.25 | github.com/bazelbuild/rules_cc | 0.2.25 | 77064f0caa37d0fb2232f54feb5fba275aeebbd3 |
| bazel 8.6.0 (.bazelversion) | raw.githubusercontent.com/bazelbuild/bazel/8.6.0/tools/cpp/runfiles/runfiles.h | 8.6.0 | sha256 80cbdbdb3662b12de206f854bb35184396de328620ea3d6a4c1578bde5836900 |

All git fetches are `git clone --depth 1 --branch <tag>`.
raw.githubusercontent.com worked through the proxy (used for the BCR
MODULE.bazel files that gave the boost closure and for the one Bazel header;
`deps.sh` verifies that header's sha256 and writes the identical text itself if
the download fails or differs).

Boost closure: read from bazel-central-registry
`modules/boost.<m>/1.90.0.bcr.1/MODULE.bazel`: unordered -> {assert, config,
container_hash, core, mp11, predef, throw_exception}; container_hash -> {config,
describe, mp11}; core -> {assert, config, throw_exception}; throw_exception ->
{assert, config}; describe -> {mp11}; assert -> {config}. The umbrella module
`boost` (lists every boost library) and `rules_cc` were excluded. The nine
`include/` trees are copied (not symlinked) into one root. `git describe` on
predef prints `boost-1.88.0`: the commit is identical for tags 1.88.0 to 1.90.0
(`git tag --points-at HEAD` lists boost-1.90.0), so the stamp records the
commit, not describe.

## Build flags (and where they come from in the repo)

`bazel/cc_toolchains/cc_toolchain_cpp_features.bzl`, feature `clang` (`enabled =
True`, no `with_features` restriction) puts `-fno-exceptions -fno-rtti
-std=c++20` on every C++ compile action and `-ffunction-sections
-fdata-sections` and `-fPIC` (with `--force_pic`) on every compile action, so
external repositories get them too. `.bazelrc`:
`--per_file_copt=external/.*@-w`, `--dynamic_mode=off`, `--define=absl=1`. Opt
mode is `-O3 -DNDEBUG` (`cc_toolchain_optimization.bzl`).

Every library here was compiled with `clang++ -std=c++20 -fno-exceptions
-fno-rtti -ffunction-sections -fdata-sections -w -O2 -DNDEBUG -fPIC` (CMake:
Release, `CMAKE_CXX_STANDARD=20`, `CMAKE_CXX_EXTENSIONS=OFF`,
`CMAKE_POSITION_INDEPENDENT_CODE=ON`, `BUILD_SHARED_LIBS=OFF`,
`CMAKE_INSTALL_LIBDIR=lib`), static archives only, against the system libstdc++.
`nm` confirms no `__gxx_personality` reference and no `typeinfo` symbol in
libgtest.a, libgmock.a, libre2.a, libabsl_strings.a, libabsl_flags_parse.a,
librunfiles.a.

Per dependency:

-   abseil: `-DABSL_PROPAGATE_CXX_STD=ON -DABSL_ENABLE_INSTALL=ON
    -DABSL_BUILD_TESTING=OFF -DABSL_BUILD_TEST_HELPERS=OFF
    -DABSL_USE_EXTERNAL_GOOGLETEST=OFF`; 91 archives.
-   re2: `-DRE2_BUILD_TESTING=OFF -DRE2_TEST=OFF -DRE2_BENCHMARK=OFF
    -DCMAKE_PREFIX_PATH=$DEPS/absl` (re2 2025-11-05 does `find_package(absl
    REQUIRED)`).
-   googletest: NOT built with its CMake. Compiled directly as the two
    amalgamated units `googletest/src/gtest-all.cc` and
    `googlemock/src/gmock-all.cc` with the flags above plus `-pthread
    -DGTEST_HAS_ABSL=1` and the absl and re2 include roots, archived into
    `libgtest.a` and `libgmock.a`, headers copied. See decision D3.
-   boost: header-only, assembled include root.
-   runfiles: `tools/cpp/runfiles/runfiles.h` (Bazel 8.6.0 forwarder) +
    `rules_cc/cc/runfiles/runfiles.h` + `runfiles.cc` (rules_cc 0.2.25); the .cc
    is also pre-compiled into `librunfiles.a` with the same flags.

## deps.env contract (read it from `/home/user/arb/deps/deps.env`)

-   `ABSL_INCLUDE`, `ABSL_LIB_DIR`, `ABSL_LIBS`: `ABSL_LIBS` is a response file
    (`@$ABSL_LIBS` on the link line), one absolute `libabsl_*.a` per line, all
    91 archives exactly once, in topological order (dependents first) computed
    from `abslTargets.cmake` + `abslTargets-release.cmake`; a single pass
    resolves everything, no `--start-group`. Not a merged archive.
-   `RE2_INCLUDE`, `RE2_LIB` (link before the absl list).
-   `GTEST_INCLUDE`, `GTEST_LIBS="libgmock.a libgtest.a"`,
    `GTEST_DEFINES="-DGTEST_HAS_ABSL=1"`. Every TU that includes gtest/gmock
    headers MUST get `GTEST_DEFINES` (D2). No gtest_main: Carbon has
    `//testing/base:gtest_main` and file_test has its own main
    (`testing/file_test/file_test_base.cpp`, `testing/base/BUILD`).
-   `TEST_LINK_LIBS`: response file with gmock, gtest, re2 and the absl list, in
    order: everything a test binary links beyond LLVM and
    `DEPS_SYS_LIBS="-lpthread -lm"`.
-   `BOOST_INCLUDE`.
-   `RUNFILES_INCLUDE`, `RUNFILES_SRC` (compile into the binary) or
    `RUNFILES_LIB`.
-   `DEPS_CXX`, `DEPS_CXX_STDLIB=libstdc++`, `DEPS_BUILT_WITH_CXX_FLAGS` for
    consistency checks.

## Decisions (reason; break condition)

-   D1 libstdc++, not libc++. Carbon's Bazel build uses `-stdlib=libc++
    -unwindlib=libunwind` (`cc_toolchain_cpp_features.bzl`, feature `libcxx`),
    but libc++ is not installed here (`clang++ -stdlib=libc++` cannot find
    `<vector>`) and the LLVM build has no runtimes. All deps and (necessarily)
    the Carbon build itself use libstdc++. Break: a golden whose output depends
    on standard-library behaviour (none expected; the gate compares Carbon's own
    diagnostics and IR). Recorded in deps.env as `DEPS_CXX_STDLIB`.
-   D2 googletest with abseil (`GTEST_HAS_ABSL=1`). `.bazelrc` has
    `--define=absl=1`, which selects googletest's `:has_absl` (defines
    `GTEST_HAS_ABSL=1`, deps on absl and re2).
    `testing/file_test/file_test_base.cpp` relies on it:
    `absl::SetFlag(&FLAGS_gtest_filter, ...)`,
    `absl::SetFlag(&FLAGS_gtest_brief, 1)` and `absl::ParseCommandLine` after
    `InitGoogleTest` only compile/work when gtest's flags are absl flags. Break:
    a TU compiled without `-DGTEST_HAS_ABSL=1` against these archives (ODR
    mismatch in the flag objects); `gtest_smoke.cpp` has `#error` for that and
    mirrors the file_test main.
-   D3 googletest compiled directly instead of with its CMake. googletest's
    `cmake/internal_utils.cmake` appends `-fexceptions` (`cxx_default`) to every
    target, and clang takes the last flag, so the CMake build silently
    re-enabled exceptions (seen in build.ninja); there is no option to turn it
    off. The direct compile of `gtest-all.cc`/`gmock-all.cc` is what
    googletest's own `BUILD.bazel` target `gtest` amounts to under Carbon's
    toolchain. Break: a googletest version whose amalgamated units change name
    (fetch step still works; compile step dies with a log path).
-   D4 abseil link order as a topologically sorted response file rather than a
    merged archive or `--start-group`: keeps one archive per absl target (like
    Bazel), works with GNU ld and lld, and is verified by three link smoke
    tests. Break: an abseil whose export-file format changes;
    `absl_link_order.py` then warns "not in export files; appended" and the
    smoke links fail (this exact failure was seen and fixed once: the release
    export file closes blocks with an indented `)`).
-   D5 runfiles = Bazel 8.6.0 forwarder + rules_cc 0.2.25 implementation. The
    label is `@bazel_tools//tools/cpp/runfiles` (toolchain/base/BUILD), the
    include is `tools/cpp/runfiles/runfiles.h`, the namespace
    `bazel::tools::cpp::runfiles` (install_paths.cpp). In Bazel 8.6.0
    `tools/cpp/runfiles/BUILD.tools` is `cc_library(hdrs=["runfiles.h"],
    deps=["@rules_cc//cc/runfiles"])` and that header is a typedef over
    `rules_cc::cc::runfiles::Runfiles`; the old `runfiles_src.{h,cc}` no longer
    exist at that tag (404). Break: none for Create(argv0,&err)/Rlocation, which
    the smoke test exercises against a fake
    `<exe>.runfiles/carbon/toolchain/install/` tree. Note for author A/C: the
    runfiles dir Carbon looks for is
    `<exe>.runfiles/carbon/toolchain/install/carbon_install.txt` (BazelRoot in
    install_paths.cpp) or `RUNFILES_DIR`.
-   D6 `-O2 -DNDEBUG` as the task specified (Carbon's opt mode is `-O3`):
    optimisation level does not affect ABI; `-ffunction-sections -fdata-sections
    -w` added to match the toolchain and `.bazelrc`.
-   D7 Parallelism: `JOBS` defaults to 2 while a process matching `ninja -j4`
    runs, else nproc. The LLVM ninja had finished when the builds ran (log at
    [3750/3750], no FAILED lines, process gone), so they ran at -j4.
-   D8 Not provided (not needed for the gate, autoupdate or conformance):
    `tcmalloc` (`.bazelrc --custom_malloc=//bazel/malloc:tcmalloc_if_linux_opt`,
    a malloc replacement in opt builds; system malloc is behaviourally
    equivalent), `google_benchmark` + `libpfm` (benchmarks only: common/BUILD,
    toolchain/benchmarking, toolchain/lex, toolchain/sem_ir,
    testing/base:benchmark_main), `tree-sitter` (utils/tree_sitter grammar
    tests), `bazel_skylib`, `rules_pkg`, `rules_shell`, `rules_python` (Bazel
    plumbing). LLVM's Bazel deps (zlib-ng, zstd, xz, libxml2, protobuf) are the
    LLVM CMake build's concern (zlib ON, the rest OFF). Break: if gen_ninja.py
    meets a `cc_*` target depending on one of these, it is a benchmark or
    tree-sitter target and should be excluded.
-   D9 `paths.sh` was written by me because `/home/user/arb/carbonbuild/` was
    empty; it only sets defaults with `${VAR:-}` so overriding REPO/SHA/DEPS
    works and author A's scripts can extend it. If a different paths.sh lands,
    deps.sh needs only `DEPS` and `CB`.
-   D10 Install markers: `<prefix>/.deps-installed` holds "name tag commit [on
    deps]"; a step is skipped only when the text matches exactly, so bumping a
    tag or rebuilding absl invalidates re2 and googletest automatically.

## Verification

-   `deps.sh validate`: every path in deps.env exists (91 absl archives, re2,
    gmock, gtest, boost header, both runfiles headers, runfiles .cc and .a).
-   `deps.sh smoke` (all PASS, `/home/user/arb/deps/smoke/RESULTS.txt`), each
    compiled with `clang++ -std=c++20 -fno-exceptions -fno-rtti -O2 -DNDEBUG
    -fPIC` against the install: `absl_smoke` (flat_hash_map, flat_hash_set,
    StrCat, StrSplit, HashOf, BitGen, ABSL_FLAG + ParseCommandLine), `re2_smoke`
    (FullMatch with captures, PartialMatch), `gtest_smoke` (TEST with
    ElementsAre/StartsWith, own main with absl::SetFlag on FLAGS_gtest_brief /
    FLAGS_gtest_filter and absl::ParseCommandLine, linked via
    `@test_link_libs.rsp`), `boost_smoke` (unordered_flat_map emplace/find),
    `runfiles_smoke` (RUNFILES_SRC) and `runfiles_lib_smoke` (RUNFILES_LIB):
    Runfiles::Create(argv0) + Rlocation resolves a marker in a fake runfiles
    tree.
-   A TU including every `boost/unordered/*.hpp` compiles (`-fsyntax-only`; one
    deprecation pragma message from hash_traits.hpp, no error).
-   Idempotence: a second `deps.sh` with no arguments skipped all five installs
    and re-ran env/validate/smoke (PASS).
-   Fresh-clone path: `DEPS=<scratch> deps.sh boost runfiles` cloned, assembled
    and produced byte-identical stamps.
-   nm: no exception personality or typeinfo symbols in the archives (see
    above).

## Unverified (for the later phases)

-   Linking the real `//toolchain/testing:file_test` and the toolchain against
    these archives together with the LLVM static libraries (author A's
    gen_ninja.py); in particular whether `-lpthread -lm` suffices and whether
    lld or GNU ld is used (smoke used `/usr/bin/ld`).
-   The libstdc++/libc++ divergence (D1) has no effect on any golden.
-   Behaviour of googletest's absl-flag parsing with file_test's real argument
    set (`--file_tests=...`, `--autoupdate`, `--threads`); only the
    SetFlag/ParseCommandLine shape was exercised.
-   The LLVM build state: at 14:47 `/home/user/llvm-build/bin` had lld but no
    `clang` driver; Carbon links clang's libraries, not the driver, so this may
    be intended.

## Disk

`du -sh /home/user/arb/deps`: 92M (src 61M, build 11M, absl 8.0M, boost 3.3M,
smoke 2.7M, googletest 2.2M, re2 904K, runfiles 236K). `src/` and `build/` can
be deleted after the install; deps.sh re-clones/rebuilds only what is missing.

## How to run

```
/home/user/arb/carbonbuild/deps.sh            # everything; skips installed deps
/home/user/arb/carbonbuild/deps.sh env smoke  # regenerate deps.env, re-run smoke
DEPS=/elsewhere /home/user/arb/carbonbuild/deps.sh   # another root
rm /home/user/arb/deps/absl/.deps-installed && deps.sh absl re2 googletest env  # force
```

Logs: `/home/user/arb/deps/logs/<dep>.log`, smoke logs
`/home/user/arb/deps/smoke/<name>.log`.

## Fold after review 1 (2026-11-09, fixer)

-   R1-M1 (MAJOR) APPLIED. Re-checked: deps.sh sourced paths.sh (line 29) before
    its own `CXX="${CXX:-clang++}"`, and paths.sh (author A) sets
    `CXX="${CXX:-$DEPS/llvm21/bin/clang++}"`, so `bash -c '. paths.sh; echo
    $CXX'` prints the llvm21 path: on a fresh container in the README order
    (deps.sh before get_clang.sh) every cmake configure would fail on a missing
    compiler, and on re-runs C++ was compiled by clang 21 while C stayed clang
    18, with deps.env claiming `DEPS_CXX=clang++`. Fix: deps.sh-private
    `DEPS_CC` / `DEPS_CXX` (defaults `clang` / `clang++`, the system 18.1.3),
    used for cmake, the direct googletest and runfiles compiles and the smoke
    programs; CC/CXX are never read. Every compiled dependency's stamp now ends
    with `cxx=<first line of $DEPS_CXX --version>` (absl, re2 — whose stamp
    embeds absl's —, googletest, runfiles), so a different compiler rebuilds it;
    deps.env records `DEPS_CC`, `DEPS_CXX`, `DEPS_CXX_VERSION` and names the
    compiler in its flags comment; the smoke step logs the compiler it uses (the
    one deps.env records, since it sources deps.env). Decision: the default
    stays the system clang 18 so deps.sh works before get_clang.sh; the
    reviewer's clang-21 smoke run and the 2047/0 gate (clang-21 Carbon objects
    against these clang-18 archives, same libstdc++ 13 and Itanium ABI) settle
    the ABI question. To build the deps with Carbon's compiler after
    get_clang.sh: `DEPS_CXX=$DEPS/llvm21/bin/clang++
    DEPS_CC=$DEPS/llvm21/bin/clang deps.sh` (the stamps then rebuild everything
    compiled). Break: a compiler whose `--version` first line changes between
    runs rebuilds the deps once. Verified: full `deps.sh` re-run with the new
    stamps (absl and re2 reconfigured with `-DCMAKE_CXX_COMPILER=clang++`, ninja
    "no work", cmake's install left the archives byte- and mtime-unchanged;
    libgtest.a, libgmock.a and librunfiles.a recompiled with clang 18), `env`,
    `validate` (all paths exist) and `smoke` 6/6 PASS, log
    /home/user/arb/logs/deps-fold.log; `.deps-installed` files show `cxx=Ubuntu
    clang version 18.1.3 (1ubuntu1)`; paths.sh's `CXX` is untouched.
-   D1 (libstdc++) and the unverified item "libstdc++ vs libc++ has no effect on
    any golden" are superseded by REVIEW-1 R1-B1: it did have an effect, through
    undefined behaviour in toolchain/check/check.cpp that libc++'s
    `std::uninitialized_copy` hides (NOTES-A.md, fold section). Nothing to
    change in the deps.
-   D10 (paths.sh with only `${VAR:-default}` lines) still holds; the fixer
    added `SRC_PATCHES` and `SRC_OVERLAY` in the same form.

<!-- google-doc-style-resume -->
