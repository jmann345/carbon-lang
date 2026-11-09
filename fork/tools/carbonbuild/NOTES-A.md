<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# NOTES-A: the C++ build graph of the container arbiter (author A)

<!-- google-doc-style-ignore -->

Date: 2026-11-09. Repo: /home/user/carbon-trunk at cb726a230 (read-only; nothing
under it was written or touched by git). Everything lives under /home/user/arb.

## Deliverables

| Path | What |
| --- | --- |
| `/home/user/arb/carbonbuild/paths.sh` | shared config (author B created it; I appended `LLVM_OVERLAY`, `CXX`, `CARBON_BUILD_MODE`, `GEN_DIR`; author C appended the binary and runfiles paths) |
| `/home/user/arb/carbonbuild/paths.py` | `paths.load()` runs paths.sh under bash and returns the variables; `paths.load_env()` parses deps.env |
| `/home/user/arb/carbonbuild/bazel_graph.py` | the Bazel-free evaluator of the BUILD graph (shared with install.py; API documented at its top; stdlib only) |
| `/home/user/arb/carbonbuild/gen_ninja.py` | walks the cc closure of the three binaries and writes `$BUILD_DIR/build.ninja`, the analysis-time generated files under `$BUILD_DIR/gen`, `compile_commands.json`, and `carbonbuild/env.sh` |
| `/home/user/arb/carbonbuild/build.sh` | `source paths.sh; get_clang.sh; get_llvm_overlay.sh; gen_ninja.py; ninja -C $BUILD_DIR -j$JOBS`, log in `$ARB/logs/build-$SHA.log` |
| `/home/user/arb/carbonbuild/get_clang.sh` | fetches the LLVM 21.1.8 release tarball and extracts clang/lld/llvm-ar/llvm-symbolizer + the clang resource dir into `$DEPS/llvm21` (decision D1) |
| `/home/user/arb/carbonbuild/get_llvm_overlay.sh` | copies LLVM's Bazel overlay to `$DEPS/llvm-overlay` and applies Carbon's bazel/llvm_project patches 0002 0004 0005 0006 0012 (0001 is a source patch) |
| `/home/user/arb/carbonbuild/env.sh` | generated: the `cc_env()` variables (`LLVM_SYMBOLIZER_PATH`, `ASAN_SYMBOLIZER_PATH`, `UBSAN_SYMBOLIZER_PATH`, `UBSAN_OPTIONS=print_stacktrace=1`) for gate.sh |
| `/home/user/arb/build/cb726a230/{build.ninja,gen/,obj/,bin/}` | the build directory; binaries at `bin/carbon-busybox`, `bin/file_test`, `bin/make-installation-digest` (the names in author C's paths.sh additions) |
| `/home/user/arb/deps/llvm21/` | clang 21.1.8 (release tarball subset, ~500 MB); tarball kept at `/home/user/arb/deps/llvm21-dl/` (2 GB, may be deleted) |
| `/home/user/arb/deps/llvm-overlay/` | the patched overlay copy |
| `/home/user/arb/deps/bazel-src-ref/` | Bazel 8.6.0 Java sources fetched from raw.githubusercontent.com to confirm depset/attribute ordering semantics (reference only, see D8) |

## How to run

```
/home/user/arb/carbonbuild/build.sh            # all three binaries, log in $ARB/logs/build-$SHA.log
REPO=/path/to/worktree SHA=abc1234 /home/user/arb/carbonbuild/build.sh   # another sha
python3 -I /home/user/arb/carbonbuild/gen_ninja.py     # only (re)write build.ninja + gen/ (seconds)
python3 -I /home/user/arb/carbonbuild/bazel_graph.py manifest //core:prelude_manifest.txt
python3 -I /home/user/arb/carbonbuild/bazel_graph.py install-list   # every install file -> source
ninja -C /home/user/arb/build/cb726a230 -n              # dry run
```

`JOBS` defaults to 2 while a `ninja -j4` process (the LLVM build) is running,
else nproc. `CARBON_BUILD_MODE=fastbuild` builds -Og -gmlt without NDEBUG (D5).

## Method: evaluating BUILD files as Python

`bazel_graph.py` execs each BUILD file and the .bzl files it loads with Python's
`exec` after two AST rewrites (`load(...)` statements become assignments from a
loader; Starlark's `d.values()/keys()/items()` return lists, so they are wrapped
in `list(...)`). The namespace provides `glob` (Bazel semantics: patterns
relative to the package, `**` crosses directories, results sorted, files in
subpackages excluded, `exclude`, `allow_empty`), `select` (lazy; resolved at
analysis time for the fixed configuration, see below), `Label` (bound per module
so relative labels in .bzl files resolve against the .bzl's package),
`rule`/`attr`/`aspect`/`provider`/`depset`/`struct`/`native`, and stub modules
for `@rules_cc`, `@bazel_skylib`, `@rules_python`, `@rules_shell`, `@rules_pkg`,
`@bazel_tools`, `@bazel_cc_toolchain//:clang_detected_variables.bzl` and
`@llvm-project//:vars.bzl` (synthesized from `cmake/Modules/LLVMVersion.cmake`:
MAJOR 24, values are strings as `llvm_configure` writes them). Custom rules are
reproduced by running their real implementation functions against a fake `ctx`
(File with `.path`, `.short_path`, `.root.path`, `.owner`, `.extension`;
`depset` with Bazel's ordering; `ctx.actions.write`, `symlink`,
`expand_template` (sequential literal replacement in dict order, as Bazel's
TemplateExpansionAction), `run` (recorded as an Action, replayed with the real
python tool)).

Fixed configuration (`Graph.condition_true`): `@platforms//os:linux` and
`@platforms//cpu:x86_64` hold; a `config_setting` is evaluated from its
`constraint_values`, `flag_values` (compared with the flag's
`build_setting_default`: `//:runtimes_build` False, `//:bootstrap_stage` 0,
`//bazel/version:release` False, `pre_release` "dev", libc's `:full_build` off),
`values` (`compilation_mode` = the build mode, `stamp` never "1", `define`
absl=1/pfm=1) and `define_values`; `selects.config_setting_group` is evaluated
from its members. `//bazel/cc_toolchains:macos_asan` is reached through the real
bazel/cc_toolchains BUILD. Three Carbon .bzl files are stubbed because they are
pure Bazel toolchain plumbing (transitions, cc_common):
`bazel/cc_toolchains/carbon_bootstrapping.bzl`,
`carbon_cc_toolchain_config.bzl`, `clang_configuration.bzl`, plus
`bazel/carbon_rules/defs.bzl` and `toolchain/runtimes/carbon_runtimes.bzl`;
their rules are recorded generically and nothing in the closure of the three
binaries or of the install data depends on their analysis.

Packages of `@llvm-project` are the patched overlay's BUILD.bazel files
evaluated against the source tree `$LLVM_SRC/<package>` (compiler-rt, libcxx,
libcxxabi, libunwind, libc (19k lines, evaluates in ~0.3 s),
clang-tools-extra/clangd). `//llvm`, `//clang`, `//lld` are not evaluated: their
labels map to the CMake archives (D3), except the tool libraries (D4) and
`//clang:builtin_headers_gen`, whose `builtin_headers` list is extracted from
the overlay's clang/BUILD.bazel by `ast` and evaluated with the same `glob`.

## The closure (gen_ninja.py output for cb726a230)

```
targets in closure: 207 (152 Carbon cc targets, 34 external, 21 LLVM tool libs)
source files compiled: 393; generated files: 7 (4 written now, 3 ninja rules); objects: 393
file_test manifest: 2047 test files
LLVM archives: 176; external groups: absl, gtest, llvm, re2, runfiles
```

The file_test manifest has exactly 2047 entries
("toolchain/check/testdata/alias/basics.carbon" ...
"toolchain/parse/testdata/while/while_let.carbon"): the eight `testdata`
filegroups (`glob(["testdata/**/*.carbon"])`, driver also `testdata/**/*.cpp`):
2045 .carbon + 2 .cpp, in the order of `//toolchain/testing:all_testdata`'s srcs
(check, codegen, driver, format, language_server, lex, lower, parse), each glob
sorted.

## Generated sources and how each is reproduced

1.  `common/version.cpp`, `version_nostamp.cpp`, `version_stamp.cpp` (`expand_version_build_info`
    in common/BUILD, bazel/version/rules.bzl): ninja rules that run the real
    tool, `python3 -I $REPO/bazel/version/gen_tmpl.py --template=...
    --output=... --substitution=K=V ...` with the exact argument list the rule
    computes under `--nostamp`: `VERSION=0.0.0-0.dev` (compute_version.bzl:
    version_base "0.0.0", pre_release flag default "dev"),
    `GIT_COMMIT_SHA=unknown`, `GIT_DIRTY_SUFFIX=` (empty), `BUILD_*=unknown`,
    `MAKE_WEAK=0` (1 for version_nostamp.cpp); `stamp = -1` resolves to 0
    because `//bazel/version:internal_stamp_flag_detect` (`values = {"stamp":
    "1"}`) is false. Result: `Version::String == "0.0.0-0.dev+unknown"`,
    identical in the weak and strong definitions, so which one the linker picks
    is irrelevant. Golden dependence: none. `grep -rn "0\.0\.0\|+unknown"
    toolchain/*/testdata` finds nothing; `toolchain/driver/testdata/
    fail_llvm_fuzzing.carbon` passes `--version` to `llvm ar` but the golden
    only checks the fuzzing refusal; `Version::String` is printed by `carbon
    version` (no golden) and used in the runtimes cache directory name
    (toolchain/driver/runtimes_cache.cpp, "runtimes-0.0.0-0.dev+unknown-...").
2.  `toolchain/base/llvm_tools.def` (`generate_llvm_tools_def`,
    toolchain/base/llvm_tools.bzl): the rule's implementation is executed;
    written at gen time (3938 bytes; `Addr2Line` etc. come from Starlark's
    `title()`, whose word splitting at digits matches Python's).
3.  Manifests (bazel/manifest/defs.bzl): `manifest` for
    `//core:prelude_manifest.txt` (36 lines, strip_package_dir),
    `//core:core_library_manifest.txt` (io.carbon, io.impl.carbon),
    `//toolchain/install:clang_headers_manifest.txt` (326 lines,
    `llvm/lib/clang/24/include/...`),
    `//toolchain/install:install_digest_manifest.txt` (2206 lines of
    `bazel-out/k8-opt/bin/ toolchain/install/...` plus the busybox),
    `install_data_manifest.txt` (2243), and `manifest_as_cpp` for
    `//toolchain/testing:file_test_autogen_manifest.cpp` (2047 entries,
    workspace-relative source paths). All by running `_manifest`/`_manifest_as_cpp`
    against the fake ctx; `Graph.manifest_text(label)` returns the text for
    install.py.
4.  `toolchain/base/runtimes_build_info.h`
    (generate_runtimes_build_info_cc_library) and
    `toolchain/install/bazel/runtimes_build_vars.bzl`
    (generate_runtimes_build_vars): the real `_get_substitutions` runs over the
    evaluated compiler-rt/libcxx/libcxxabi/libunwind/libc/core filegroups,
    `builtins_copts`, `crt_copts`, `libcxx_and_abi_copts`, `libunwind_copts`
    from the patched overlay .bzl files, and LLVM_VERSION_MAJOR "24". Verified
    against the nightly 2026.10.12 tarball's
    `lib/carbon/bazel/runtimes_build_vars.bzl`: byte-identical except the
    `carbon_core_srcs` list, which differs exactly by the prelude files
    added/removed in the repo since that nightly (my list equals `find
    core/prelude -name '*.carbon' | sort` with prelude.carbon first). This
    exercised: filegroup order = srcs order with globs sorted;
    `filtered_builtins_srcs` (generic files overridden by arch files, textual
    .inc/.def split); the aarch64 `outline_atomic_*.S` genrule outputs; the libc
    `_libc_srcs_filegroup` aspect (see D8 for the ordering subtleties it
    exposed); `file.owner.name` for `_runtimes_path`.
5.  `@llvm-project//clang-tools-extra/clangd:Features.inc` (genrule of echo
    lines): interpreted, written at gen time; needed by `ClangDaemon` (D4).
6.  LLVM tool `Opts.inc` tablegen outputs (D4): ninja `tblgen_opts` rules with
    `$LLVM_BUILD/bin/llvm-tblgen -gen-opt-parser-defs`, derived from each tool's
    CMakeLists.txt (`set(LLVM_TARGET_DEFINITIONS X.td)` + `tablegen(LLVM X.inc
    -gen-opt-parser-defs)`): 19 tools have one or more (objcopy 4, objdump 2, rc
    2; llvm-ar none).
7.  Other genrules / custom rules in the closure of the three binaries or the
    install data, and how `Graph.file_bytes` reproduces them: compiler-rt
    `builtins_aarch64_outline_atomic_*` (echo defines + cat lse.S);
    `//toolchain/install:carbon_cc_toolchain_config_for_install` (sed
    replacement, interpreted); `//toolchain/runtimes:libcxx_site_config_gen` and
    `libcxx_assertion_handler_gen` (`configure_cmake_file`: `ctx.actions.run`
    replayed with the real `configure_cmake_file_impl.py` and its `--defines`
    list); `toolchain_files`/`filtered_files` (install_filegroups.bzl, symlinks:
    `File.symlink_target`, `Graph.symlink_chain_end`); `toolchain_llvm_binaries`
    (llvm/bin symlinks to the busybox); `//clang:builtin_headers_gen` (copies of
    `clang/lib/Headers/**/*.h` minus three, plus 16 clang-tblgen outputs taken
    from `$LLVM_BUILD/lib/clang/24/include`); `//toolchain/install:gen_digest`
    (runs make-installation-digest: NOT interpreted, install.py runs the built
    tool). Linkstamp: `//common:build_data` has `linkstamp =
    "build_data_linkstamp.cpp"`; it is compiled once per binary with Bazel's
    linkstamp defines `G3_TARGET_NAME="//toolchain/testing:file_test"`
    (file_test's autoupdate writes it into every golden's `TIP:` lines, so it
    must be exactly the label without `@@`, as the goldens show),
    `G3_VERSION_INFO`, `G3_BUILD_TARGET="bin/file_test"` (only its filename is
    used, for the tmpdir), `GPLATFORM="local_linux_x86_64"`,
    `BUILD_COVERAGE_ENABLED=0`.

## External dependencies (labels -> link inputs)

-   `@llvm-project//llvm:*`, `//clang:*`, `//lld:*` -> every
    `$LLVM_BUILD/lib/lib{LLVM,clang,lld}*.a` (176 archives; `*Testing*`,
    `*gtest*`, `*TableGen*` excluded) inside one `-Wl,--start-group ...
    --end-group`, then `-lz -lpthread -ldl -lm -lrt` (zlib ON, zstd/libxml2/
    terminfo/curl OFF in the CMake cache). Static archives only pull referenced
    members, so no label-to-archive table is needed (D3).
-   Tool libraries (D4): `@llvm-project//llvm:<tool>-lib` for the 20 tools of
    `LLVM_MAIN_TOOLS` (toolchain/base/llvm_tools.bzl) and
    `@llvm-project//clang:clang-driver` are compiled from
    `$LLVM_SRC/llvm/tools/<tool>/*.cpp` and `clang/tools/driver/*.cpp` (no
    `main` there: `clang_main`, `llvm_ar_main`, ... are the entry points the
    busybox calls), with `-w`, LLVM's `-D_GNU_SOURCE -D__STDC_*_MACROS`, the
    LLVM include dirs and the tablegen'd `Opts.inc`.
    `@llvm-project//clang-tools-extra/clangd:ClangDaemon` (14 clangd sources;
    the overlay's small library, not clangd proper) is compiled from the
    overlay's cc_library definition with `-w`.
-   `@abseil-cpp//absl/...` -> `ABSL_INCLUDE`, `@$ABSL_LIBS` (B's topologically
    ordered response file, inlined); `@re2` -> `RE2_LIB`; `@googletest//:gtest`
    -> `GTEST_LIBS` with `GTEST_DEFINES` (`GTEST_HAS_ABSL=1`) attached as the
    target's `defines`, so they propagate to every transitive dependent exactly
    as Bazel's `--define=absl=1` does; `@boost.unordered` header-only;
    `@bazel_tools//tools/cpp/runfiles` -> `RUNFILES_SRC` compiled as an object
    with `RUNFILES_INCLUDE`. Archives are included per binary only when the
    group is in its closure (busybox: llvm + runfiles; file_test: all; digest:
    llvm + runfiles).

## Compiler flags (mirroring bazel/cc_toolchains for linux clang `-c opt`)

Compile: `-fno-exceptions -fno-rtti -std=c++20 -ffunction-sections
-fdata-sections -fPIC -Wno-builtin-macro-redefined -D__DATE__="redacted"
-D__TIMESTAMP__="redacted" -D__TIME__="redacted"` (feature `clang`), `-DNDEBUG
-O3` (`default_optimization_flags`, opt), `-march=x86-64-v2`
(`aarch64_cpu_flags`, x86_64 branch), the warning set `-Werror -Wall -Wextra
-Wthread-safety -Wself-assign -Wimplicit-fallthrough -Wctad-maybe-unsupported
-Wextra-semi -Wmissing-prototypes -Wzero-as-null-pointer-constant
-Wdelete-non-virtual-dtor -Wno-missing-designated-field-initializers` (all
accepted by clang 21; gen_ninja.py probes each and prints a note for any it
drops), the twelve `--system-header-prefix=` entries of `project_flags`,
`-iquote $REPO -iquote $GEN -iquote $LLVM_SRC -iquote
$GEN/external/+llvm_project+llvm-project` (Bazel's quote include roots),
`-isystem` for llvm/clang/lld source and build include dirs and the deps'
include roots, per-target `-D` (transitive `defines`, own `local_defines`),
`-isystem` for transitive `includes`, `copts` with `$(BINDIR)`/`$(GENDIR)` ->
`$GEN`, `-frandom-seed=<object>`, `-MD -MF` depfiles (`deps = gcc`),
`-ffile-prefix-map=$REPO/= -ffile-prefix-map=$GEN/=` so `__FILE__` is
workspace-relative like Bazel's. Not reproduced, on purpose: `-stdlib=libc++`,
`-D_LIBCPP_HARDENING_MODE=...`, `-unwindlib=libunwind`, `-l:libc++abi.a`,
`-rtlib=compiler-rt` (D2), `-DBAZEL_COMPILE_CACHE_KEY` (cache key only),
`-fcolor-diagnostics`, `-no-canonical-prefixes`, LLVM's Bazel
`llvm_config_defines` (the CMake-generated `llvm-config.h`/`config.h` are the
authoritative configuration for the CMake archives), tcmalloc
(`--custom_malloc`, performance only).

Link: `clang++ -o <bin> @<bin>.rsp` with `-march=x86-64-v2 -fuse-ld=lld
-static-libstdc++ -static-libgcc -lpthread -pie`, the binary's own objects, the
linkstamp object, then every library of the closure in Bazel's link order
(dependents first) as `-Wl,--start-lib <objects> -Wl,--end-lib` (Bazel's
`supports_start_end_lib`), `alwayslink = 1` libraries
(`//common:all_llvm_targets`, check/lex/parse/sem_ir registration libraries) as
plain objects, transitive `linkopts`, the runfiles object, the archive group,
the system libraries. Objects live at `obj/<package>/<target>/<source path>.o` (`gen/...`
for generated sources, `external/llvm-project/...` for LLVM sources).

## Decisions (reason; break condition)

-   D1 Compiler: clang 21.1.8 from the LLVM GitHub release tarball
    (`get_clang.sh`), not the system clang 18.1.3. Carbon's documented minimum
    is clang 21 (docs/project/contribution_tools.md), and a smoke compile of
    toolchain/lex/lex.cpp with clang 18 fails on `toolchain/base/kind_switch.h`
    ("non-static data member cannot be constexpr") and
    `-Wmissing-field-initializers` on designated initializers (`-Wno-missing-designated-field-
    initializers` only exists since clang 19). The CMake LLVM build cannot
    supply a compiler: `CLANG_BUILD_TOOLS=OFF`. The release clang uses the
    system libstdc++ (GCC 13) and lld 21 (also extracted). paths.sh: `CXX`
    defaults to `$DEPS/llvm21/bin/clang++`; gen_ninja.py refuses a clang < 21
    unless `CARBON_ALLOW_OLD_CLANG=1`. Break: a release tarball URL change (edit
    `LLVM_RELEASE`/URL in get_clang.sh; any clang >= 21 works). Compatibility
    with author B's deps (built with clang 18 against the same libstdc++): same
    Itanium ABI and standard library, no issue expected; break: an ABI mismatch
    would show as link errors or crashes in absl/gtest code, in which case
    deps.sh should be re-run with `DEPS_CXX=$DEPS/llvm21/bin/clang++`.
-   D2 libstdc++, not libc++, and the default runtime library (libgcc). The
    CMake LLVM archives were built with the default standard library
    (`LLVM_ENABLE_LIBCXX=OFF`), so everything linked with them must use
    libstdc++; libc++ is not installed anyway (author B's D1). Break: a golden
    depending on standard-library behaviour (none expected: the gate compares
    Carbon's own output). SUPERSEDED 2026-11-09: one did (REVIEW-1 R1-B1,
    libstdc++ vs libc++ `std::uninitialized_copy`); see "Fold after review 1"
    below.
-   D3 All LLVM/clang/lld archives in one `--start-group`, no label-to-archive
    mapping; the group is harmless for lld (which resolves archive members
    regardless of order). Break: a CMake lib that needs an extra system library
    (none: zstd/xml2/curl/terminfo/libedit OFF; libpfm ON but only used by
    llvm-exegesis which is not linked).
-   D4 LLVM tool libraries and clangd compiled from source. The CMake build has
    no `llvm-ar-lib`-style libraries (tools are executables, and
    `LLVM_BUILD_TOOLS=OFF` here) and no clang-tools-extra; the busybox needs
    `llvm_ar_main` & co. and `ClangDaemon`. The sources are compiled with the
    external (-w) flags against the CMake-generated headers; `Opts.inc` files
    are regenerated with the just-built `llvm-tblgen` from the same .td files
    CMake uses. Break: a tool whose CMakeLists uses another tablegen generator
    or whose sources are not `*.cpp` in its dir (gen_ninja.py would then fail at
    link time with undefined symbols; add the pattern in `Graph._tool_lib`).
-   D5 opt (`-O3 -DNDEBUG`), not fastbuild. Carbon's CI runs the goldens in both
    modes; opt makes the 2047-file gate several times faster. Fallback
    `CARBON_BUILD_MODE=fastbuild` (`-Og -gmlt -gz -fno-omit-frame-pointer
    -mno-omit-leaf-frame-pointer -fno-optimize-sibling-calls`, no NDEBUG) if the
    gate shows a DCHECK-dependent golden. Break: a golden whose output differs
    between NDEBUG and !NDEBUG (CARBON_DCHECK side effects); switch the mode and
    rebuild.
-   D6 Compiler invocations use absolute paths and `-ffile-prefix-map` rather
    than running from the repo with relative paths (Bazel's cwd is the
    execroot): ninja's depfiles stay consistent and `__FILE__` is still
    workspace-relative. Break: none known.
-   D7 Generated files that Bazel writes at analysis time are written by
    gen_ninja.py (only when their content changes, so ninja does not rebuild
    needlessly); files that Bazel produces with an action (gen_tmpl.py,
    tablegen) are ninja rules. Every compile has an order-only dependency on the
    written files (`gen_headers` phony) and depfiles take over afterwards.
-   D8 Bazel ordering semantics implemented after reading Bazel 8.6.0's sources
    (fetched into `$DEPS/bazel-src-ref`): (a) `depset` "default" order =
    transitive sets first (in order, singleton sets hoisted as leaves), then
    direct elements; flattening is a depth-first walk with first-occurrence
    de-duplication (NestedSet.java constructor + `toList`). (b) rules_cc 0.2.25
    declares `cc_library.hdrs`, `textual_hdrs`, `additional_*_inputs` with
    `flags = ["ORDER_INDEPENDENT"]`, and Bazel sorts such label lists at loading
    (BuildType.convertFromBuildLangType); `srcs`, `deps`, `data` and all
    attributes of Starlark rules (filegroup, toolchain_files, ...) keep their
    written order. This is what makes `libc_internal_libcxx_hdrs` list
    `CPP/type_traits.h` before `CPP/type_traits/*.h` although the BUILD writes
    `glob([...]) + ["...type_traits.h", ...]`. (c) A filegroup's default
    runfiles are its deps' default runfiles (empty for source files), so
    `_get_paths` in runtimes_build_info.bzl adds nothing twice. All three
    confirmed by the byte-identical nightly comparison. Break: a Bazel upgrade
    changing these (compare again with a nightly).
-   D9 `select()` is resolved from `config_setting` definitions rather than a
    hard-coded list, with one override list for labels we never load; an
    unmatched select without default or an ambiguous match fails loudly. Break:
    a new config_setting kind (e.g. `define_values` other than absl/pfm) — add
    it to `Graph._condition_true`.
-   D10 The LLVM Bazel overlay is used from a patched copy under `$DEPS`, never
    by writing into `$LLVM_SRC` (which the LLVM build reads).
-   D11 `-Wno-ctad-maybe-unsupported` is appended after Carbon's warning set:
    with libstdc++ (D2) clang 21 reports `std::scoped_lock lock(obj_dirs_mu_)`
    (toolchain/driver/clang_runtimes.cpp:135) under
    `-Werror,-Wctad-maybe-unsupported` because libstdc++ 13's headers lack the
    explicit deduction guides libc++ marks; a warning flag cannot change the
    generated code. Break: none.
-   D12 `-include variant -include cmath` on every Carbon compile (not on
    LLVM/clangd sources). Four Carbon headers use `std::variant`/`std::get_if`
    without `#include <variant>` (toolchain/sem_ir/inst_kind.h:139,
    toolchain/base/kind_switch.h:145, toolchain/check/require_impls_stack.h:18,
    toolchain/sem_ir/declared_facet_type.h:23) and two sources use
    `log2`/`std::log2f`/`std::ceil` without `<cmath>` (toolchain/check/
    handle_choice.cpp:624, toolchain/check/eval.cpp:2338); libc++ includes these
    transitively through headers they do include, libstdc++ 13 does not, and the
    repo is read-only for this build. The first full build attempt failed in 114
    translation units, every error cascading from the missing `<variant>`; the
    next in the two `<cmath>` users. Forcing standard headers first only adds
    declarations and cannot change code generation. Break: harmless once the
    includes are added upstream; another missing transitive include shows up the
    same way.

## What was verified

-   gen_ninja.py runs in under a second and prints the counts above; `ninja -C
    $BUILD_DIR -n` succeeds (428 steps, no missing input) with the finished LLVM
    build (3750/3750).
-   `python3 -I bazel_graph.py` reproduces: the file_test manifest (2047
    entries), the prelude and core manifests, llvm_tools.def,
    runtimes_build_vars.bzl byte-identical to the nightly except the prelude
    list (which equals the repo), `clang_headers_manifest.txt` (326 entries =
    305 builtin headers + 21 compiler-rt installed headers; the nightly also has
    326 files under lib/clang), `all_data_files` (2205 files), the version.cpp
    actions (exact argument lists), the `__config_site` configure_cmake_file
    action (2890 bytes), the outline_atomic genrule bytes,
    `transitive_runfiles(file_test)` (4282 files).
-   Smoke compiles through the generated ninja file with clang 21:
    common/hashing.cpp, toolchain/lex/lex.cpp (the full warning set), the
    generated manifest .cpp, the three gen_tmpl.py-generated version sources,
    llvm-symbolizer.cpp (after its tablegen), clangd's Feature.cpp; all succeed.
    The full build was started (see "Full build" below).
-   The built binaries run: `make-installation-digest` prints its usage;
    `file_test --help` prints gtest's help (gtest + absl flags link and
    initialise); `carbon-busybox version` next to a `carbon_install.txt` marker
    prints `Carbon version: 0.0.0-0.dev+unknown`, and `carbon-busybox llvm ar --
    --version` prints `LLVM version 24.0.0git`, `carbon-busybox clang --
    --version` prints `clang version 24.0.0git (...
    6ec87e7ec4b3ca6f665a02e05d0e5fe9c37cd6cc)` (the pinned commit) and `llvm
    objcopy -- --version` works: the tool libraries compiled from source (D4)
    are reached. `ldd` shows only libz, liblzma, libm, libc (libstdc++/libgcc
    static).
-   The nightly reference install layout was compared with the toolchain_files
    outputs (`lib/carbon/{core,llvm/bin,llvm/lib/clang/24/include,
    runtimes/{builtins,libc,libcxx,libcxxabi,libunwind},bazel,
    carbon_install.txt,install_digest.txt}` all present in the computed
    `all_data_files`).

## Full build

`JOBS=4 build.sh` on this container (after the LLVM build had finished): 393
objects compile in about 9 minutes at -O3; the three binaries link with lld in
seconds: `bin/carbon-busybox` (157 MB), `bin/file_test` (158 MB),
`bin/make-installation-digest` (3 MB). Iterations that led there: (1) `#include
"clang-tools-extra/clangd/LSPBinder.h"` needs the external repository root as a
quote include dir (fixed in gen_ninja.py); (2) `-Wctad-maybe-unsupported` on
`std::scoped_lock` with libstdc++ (D11); (3) 114 TUs failing on `std::variant`
without `<variant>` (D12); (4) two TUs failing on `<cmath>` (D12); (5)
`libLLVMSupport.a` references liblzma because the CMake build has
`LLVM_ENABLE_LZMA=ON` (D13). A second `build.sh` run is a no-op (`ninja: no work
to do`).

-   D13 System libraries are derived from the LLVM build's CMakeCache.txt
    (`LLVM_ENABLE_{ZLIB,ZSTD,LZMA,LIBXML2,TERMINFO,LIBEDIT,CURL,FFI}`): here
    `-lz -llzma`, plus `-lpthread -ldl -lm -lrt`. Break: an LLVM build with
    another optional dependency (add it to `CMAKE_OPTIONAL_LIBS`).

## What remains unverified / for later phases

-   The gate numbers (2047/0), autoupdate stability and conformance are measured
    by the orchestrator after author C's install and runfiles tree exist.
-   The exact `G3_*` linkstamp values beyond `G3_TARGET_NAME`; only `TargetName`
    reaches goldens (TIP lines) and `BuildTarget`'s filename reaches a tmpdir
    name.
-   `-march=x86-64-v2` assumes the test machine supports it (any x86-64 since
    2009 does).
-   The libc `libcxx_shared_headers_hdrs` list is only needed by install.py; its
    order was verified against the nightly, the set against the aspect's
    dependency closure.

## Notes for author C (install.py / gate.sh)

-   Install files: `g.files_of("//toolchain/install:all_data_files")`; each
    File's install path is `g.install_relative_path(f)` (e.g.
    `core/prelude.carbon`, `llvm/lib/clang/24/include/ stddef.h`,
    `runtimes/libcxx/include/__config_site`), its bytes `g.file_bytes(f)`;
    `python3 -I bazel_graph.py install-list` prints the table. Manifests:
    `g.manifest_text(label)` for `//core:prelude_manifest.txt`,
    `//core:core_library_manifest.txt`,
    `//toolchain/install:clang_headers_manifest.txt`,
    `//toolchain/install:install_digest_manifest.txt` (paths as Bazel would list
    them: `bazel-out/k8-opt/bin/toolchain/install/...`; the digest tool reads
    each line as a path to open, so write the manifest with real paths or run
    the tool from a directory where `bazel-out/k8-opt/bin/toolchain/install` is
    a symlink to the install root). `llvm/bin/*` are symlinks to
    `../../carbon-busybox` (toolchain_llvm_binaries), the nightly layout has
    `bin/carbon -> ../lib/carbon/carbon-busybox`.
-   file_test locates the install through Bazel runfiles:
    `Runfiles::Create(argv0)` then
    `Rlocation("carbon/toolchain/install/carbon_install.txt")`
    (toolchain/base/install_paths.cpp); the runfiles library honours
    `RUNFILES_DIR`/`RUNFILES_MANIFEST_FILE` or `<exe>.runfiles`. The test's data
    (`g.transitive_runfiles("//toolchain/testing:file_test")`) is the install
    data plus `//toolchain/testing:min_prelude` and `clang_headers_manifest.txt`
    under `carbon/toolchain/install/`; the manifest paths inside the binary are
    workspace-relative (`toolchain/check/testdata/...`), so the test must run
    with cwd = the workspace root in the runfiles tree (Bazel runs tests in
    `$RUNFILES_DIR/_main`), and autoupdate writes the goldens through those
    paths, so the workspace in the runfiles tree must be the real repo (symlink)
    for autoupdate to update `$REPO`.
-   Environment: `source /home/user/arb/carbonbuild/env.sh` (cc_env);
    `TEST_TMPDIR` is honoured by common/filesystem.cpp.

## Fold after review 1 (2026-11-09, fixer)

The findings of REVIEW-1.md that touch A's deliverables, each re-checked against
the repository and applied or rejected. Nothing under REPO was written
(`git -C /home/user/carbon-trunk status --porcelain --ignored` empty before and
after); all changes are under /home/user/arb.

-   R1-B1 (BLOCKER) APPLIED, scaffold-side, as a source-patch overlay.
    Re-checked: toolchain/check/check.cpp:428-432 builds
    `SmallVector<UnitAndImports, 0> unit_infos(llvm::map_range(units, ...))` and
    check_unit.h:79-83 initialises `emitter(&err_tracker, ...)`, as the reviewer
    says. The mechanism is sharper than "Bazel/libc++ builds happen to leave the
    stack intact": LLVM's `SmallVector(const iterator_range&)` calls `append` ->
    `std::uninitialized_copy` (SmallVector.h:1275-1278, 366). libstdc++ 13
    implements that as `std::_Construct(std::__addressof(*__cur), *__first)`
    (bits/stl_uninitialized.h:120) with `_Construct(_Tp* __p, _Args&&...
    __args)` (bits/stl_construct.h:109): the lambda's prvalue binds to
    `_Args&&`, i.e. is materialized as a temporary, and the element is
    MOVE-constructed from it, so `emitter.consumer_` points at the temporary's
    `err_tracker`, which dies at the end of the full expression. The dangling
    pointer is deterministic under libstdc++; whether it crashes depends on
    stack reuse (15 goldens on this build, opt and fastbuild alike). libc++
    spells the standard's own Effects clause, `::new (voidify(*result))
    T(*first)`, so C++17 guaranteed elision constructs the element in place and
    nothing dangles: Bazel's build is correct by construction, not by luck. The
    source is still fragile (it relies on an implementation detail of the
    algorithm) and the in-place construction is the right fix in the repository.
    Decision: REPO is read-only for every script, and the libc++ route is out
    (the CMake LLVM archives are libstdc++, a second LLVM build is forbidden,
    the kept clang 21 subset has no libc++ at all). The scaffold therefore
    compiles a patched COPY, visibly:
    `src-patches/0001-check-unit-infos-in-place.diff` (the reviewer's reserve +
    emplace_back, git-style a/ b/ names; `patch --dry-run` and `git apply
    --check` both accept it); paths.sh `SRC_PATCHES` (default `$CB/src-patches`,
    `none` disables) and `SRC_OVERLAY` (default `$BUILD_DIR/src`); gen_ninja.py
    `apply_source_patches` copies each touched REPO file into
    `$SRC_OVERLAY/.staging`, runs `patch -p1 --forward --batch` per patch in
    name order, writes the files that differ from REPO's into `$SRC_OVERLAY`
    (write-if- changed; stale overlay files removed one by one, never rm -rf),
    compiles those paths instead of REPO's (`Gen.real` maps through
    `src_overrides`) with one extra per-object
    `-ffile-prefix-map=$SRC_OVERLAY/=` so `__FILE__`/debug info equal the
    unpatched build's and NO other object's command line changes (first attempt
    with a global `-iquote $SRC_OVERLAY` made ninja want all 393 objects;
    dropped), and writes `$BUILD_DIR/src-patches.applied` (`<patch>
    applied|landed <paths>`), which gate.sh/autoupdate.sh print before their
    result line (GATE line format unchanged). A patch already present in REPO
    (`patch --forward` says "Reversed (or previously applied)") is `landed` and
    skipped;
    one that does not apply stops gen_ninja with the hunk output; only directly
    compiled sources (.cpp/.cc/.cxx/.c) may be patched: a patched header would
    need an extra include root on every compile and ninja cannot see such a file
    appear or disappear, so a header fix must land in REPO (refused loudly).
    Verified: gen_ninja counts unchanged (207/393/7/393/2047) plus the line
    `source patches ...: 0001-check-unit-infos-in-place.diff applied
    (toolchain/check/check.cpp)`; `ninja -n` after regeneration: 1 CXX for
    check.cpp (+3 units whose gtest/runfiles headers deps.sh had re-copied) and
    2 links, not a rebuild; build.sh (JOBS=4, 2 min) relinked file_test and
    carbon-busybox; install.py; `gate.sh --threads 4`:
    `[  PASSED  ] 2047 tests.`, `GATE cb726a230: 2047 passed, 0 failed` (9.5 s
    wall); conformance.sh on the same install: PASS 228 / FAIL 0 / SKIP 13 over
    241 programs, 51 of 56 bullets. The landed, header-refusal, non-applying and
    `SRC_PATCHES=none` paths were exercised in a scratch BUILD_DIR
    (`/home/user/arb/build/fold-test`, removed). Break condition: the acceptance
    on cb726a230 is "REPO at the sha + this patch", and every GATE/AUTOUPDATE
    output says so; the orchestrator's task 6 lands the fix in the fork, after
    which gen_ninja reports the patch as `landed` and the measurement is of REPO
    alone. A new sha where the lines changed but the fix is absent fails
    gen_ninja loudly (delete or refresh the patch). Rejected part of the
    reviewer's text: "fastbuild is no fallback" is right, but "luck-based" for
    libc++ is not; recorded above.
-   R1-M1 (MAJOR, owner B; caused by the `CXX=` line I appended to paths.sh)
    APPLIED in deps.sh (NOTES-B.md). paths.sh's `CXX` stays as gen_ninja's
    compiler; deps.sh no longer reads it. D1's sentence "re-run deps.sh with
    `DEPS_CXX=$DEPS/llvm21/bin/clang++`" is now true (DEPS_CC too).
-   R1-N1 (MINOR) APPLIED: `_SAFE_BUILTINS` moved above the `__main__` block (it
    was defined after it, so the command line raised NameError while imports
    worked). Re-run: `install-list` 2205 lines, `manifest
    //core:prelude_manifest.txt` 36 lines, `files
    //toolchain/install:all_data_files` 2205, `bytes
    //toolchain/install:bazel/runtimes_build_vars.bzl` 123533 bytes.
-   R1-N2 (MINOR) APPLIED: build.ninja now has phony aliases `<name>` and
    `bin/<name>` for the three binaries (`ninja -n bin/file_test`, `file_test`,
    `make-installation-digest` all resolve); build.sh's header documents the
    accepted targets.
-   R1-N5 (MINOR, A part) APPLIED as documentation in README.md (an `ARB`
    override moves the deps too; pass `DEPS=` or populate them). Observation
    while testing: gen_ninja writes `$CB/env.sh` whatever BUILD_DIR is, and its
    "Binaries:" comment names that BUILD_DIR (the exports do not depend on it);
    a run with another BUILD_DIR rewrites the comment until the next real run.
    Left as is; recorded.
-   D2 is marked SUPERSEDED in place: one golden set did depend on
    standard-library behaviour, through the UB above.
-   Side effects of this fold: deps.sh rebuilt libgtest.a, libgmock.a and
    librunfiles.a with the same system clang 18 (absl/re2 were ninja no-ops and
    cmake's install left their archives untouched); ninja recompiled check.cpp,
    file_helpers.cpp, install_paths.cpp and runfiles.cc (new header mtimes) and
    relinked file_test and carbon-busybox (make-installation-digest unchanged);
    install.py re-run into /home/user/arb/install/cb726a230 (busybox 0755,
    digest 0858677c6bec5fac79a6f18262599cda8a3d90fde8d057a40ae46542dac9658c);
    the conformance output and cache under /home/user/arb were (re)written.

<!-- google-doc-style-resume -->
