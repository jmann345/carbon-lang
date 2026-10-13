<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Evaluator documentation plan: getting started, tutorial, FAQ, transcribed programs (EV-1: W-062)

**Status:** rev 2, 2026-10-13 — SIGNED OFF FOR IMPLEMENTATION (sign-off at the
end); both plan reviews of R29(c) folded. Review
A (correctness and evaluator fidelity) and review B (strictness, process and
records) each returned APPROVE-WITH-AMENDMENTS with no BLOCKER (A: four MAJOR,
eight MINOR; B: six MAJOR, five MINOR). The fixer reproduced every finding
before folding it and rejected none; each amended passage carries "(amended
2026-10-13, review fold: …)" with the reviews' own ids (A1 to A12, B-1 to B-6, B
m-1 to B m-5), and the section "Review fold record (rev 2, 2026-10-13)" at the
end lists them. Commit 2a folds the two document reviews of D-EV-19 the same
way, marked "(amended 2026-10-13, document-review fold: …)" and listed in the
section "Document-review fold record (commit 2a, 2026-10-13)". Branch
`claude/carbon-fork-0-1-ev` off trunk 80a11e7f0, whose
toolchain sources are identical to 0bdce60a5 (the only later trunk commits are
fork/ORCHESTRATION.md stamps). Trunk's floor is **128 PASS / 0 FAIL / 22 SKIP
over 150 programs**, 48/56 bullets (fork/conformance/out/scoreboard.json
`totals`, generated 2026-10-06); the gap-analysis header is **30 DONE / 21
PARTIAL / 4 MISSING / 1 DESIGN-ONLY** (fork/gap-analysis.md:18). The ledger's
max id is W-125 on trunk, W-150 on the SAFE-1 head (PR 53) and W-151 on the SC-1
head (its renumber of W-144); **the block W-152 to W-159 is reserved for this
workstream**, the block ST-1's rev 1 plan already records for EV-1
(claude/carbon-fork-0-1-st at bff5ba4e8, fork/string/plan.md:35-38, which starts
ST-1 at W-160): W-152 and W-153 are filed at discharge on any base, W-154 only
if EV-1 must merge onto a trunk without PR 52 (D-EV-12), and W-155 to W-159 only
for document-review friction left unfixed (D-EV-19); a reserved id that goes
unused stays unused and is never reused. The orchestrator stamps the reservation
into trunk's fork/ORCHESTRATION.md, as W-151's was (trunk commit 80a11e7f0,
fork/ORCHESTRATION.md:62-65), and the ids are allocated before commit 2, not at
discharge (D-EV-18, §8.6; amended 2026-10-13, review fold: A8, B-2). Three PRs
are open and held against 0bdce60a5 (PR 51 UA-2, PR 52 CM-1, PR 53 SAFE-1;
fork/ORCHESTRATION.md:52-67) and the recorded merge order is PR 53, PR 51, PR
52, then SC-1 (:66-67). EV-1 merges after PR 52: it is implemented on this base
in the interim state T of §1.F and converted to the landing state C by the
integration commit of §3 once trunk holds PR 52 (amended 2026-10-13, review
fold: A2, B-1). Every count below is a DELTA from trunk, and absolutes are
restated for both states (§5). This workstream touches no toolchain C++, no
golden, no BUILD file and nothing under .github/, so it needs no autoupdate. Its
verification is local and enumerated in §8: prek to a fixpoint, `runner.py
--self-test`, the runner on the `project/` filter with the fork busybox, the
sample checker of D-EV-13, the FAQ reproducer script of D-EV-21, the nightly
download block run verbatim, and the by-hand runs of §2 on both toolchains.
GitHub Actions on the repository is disabled (fork/ORCHESTRATION.md:13-18), so
the hosted conformance run that R9 makes the record cannot be dispatched: every
flip below is "expected, not of record". Every decision is an R29(a) auto-adopt
with a break condition (§1.G). Line numbers are against 80a11e7f0 unless a line
names another tree, and were opened for this plan; stale citations are corrected
in §0.2.

**Toolchains, named once.** _F_ is the fork toolchain built in this
container from trunk 0bdce60a5 sources,
`/home/user/carbon-build/carbon-trunk/install/bin/carbon` (busybox
`.../install/lib/carbon/carbon-busybox`); `carbon version` prints "Carbon
Language toolchain version: 0.0.0-0.dev+0bdce60a5". It is the arbiter for
fork features. _N_ is the upstream prebuilt nightly
`/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon`
("0.0.0-0.nightly.2026.10.12+62f1cc6"), fetched from the URL in
/home/user/nightly/url.txt, which has the pattern of README.md:292; it has
none of the fork features. F is not the artifact the guide's Bazel route
produces: it is a CMake and Ninja build (`/home/user/carbon-build/carbon-trunk`,
`build.ninja`) linked against this container's shared LLVM, which was built
from the pinned llvm-project commit 6ec87e7ec (MODULE.bazel:89) without
MODULE.bazel's six Bazel-overlay patches (:92-99;
`/home/user/llvm-build/CONFIGURE.txt`). It arbitrates language and driver
behaviour; the Bazel artifact itself was last built and run by hosted
conformance run 37402970811 (fork_hosted.yaml in conformance mode on
ubuntu-22.04 at 606a99c5a, 2026-10-06: `./scripts/run_bazel.py build -c opt
//toolchain/install:carbon_toolchain_tar` in 9m29.6s with upstream's
read-only remote cache, `carbon version` printing
`0.0.0-0.dev+unknown`, 128 PASS / 0 FAIL / 22 SKIP over 150) (amended
2026-10-13, review fold: A7). The container is Ubuntu 24.04.5 LTS with glibc
2.39, 4 CPUs and 15 GB. Scratch work for this plan lives under the session
scratchpad's `ev1/` directory (rev 2's under `ev1/fix/`), never in the
worktree.

**Item:** W-062 ("W11c: evaluator documentation — getting-started tutorial
and evaluation walkthrough in docs/guides", kind missing-feature, size M,
fork/inventory/work-items.json:1167-1181). **Milestone bullet**
(docs/project/milestones.md:243, verbatim): "Basic documentation for
evaluators from getting started to FAQs." **Gap row** fork/gap-analysis.md:90,
"Project: basic evaluator documentation (getting started to FAQs)": PARTIAL
→ DONE, expected, not of record (§5). **Arbiter**
(fork/gap-analysis.md:270-273, the W11 paragraph): "a docs/guides
getting-started tutorial an evaluator can follow from install to running a
program with interop". **The stub's un-SKIP path**
(fork/conformance/programs/project/evaluator_docs_review.carbon:6):
"Un-SKIP by replacing this file with programs transcribed from a real
docs/guides tutorial's code samples once one is written". The PASSing slice
stays: project/evaluator_docs_getting_started.carbon (the README's
forty_two program, verbatim).

## §0 Audit: what exists, what was measured, and what is stale

### §0.1 Element table (measured in this container on 2026-10-13)

| # | Element | Status | Evidence and measurement |
| --- | --- | --- | --- |
| 1 | The two toolchains and their layout | PRESENT, measured | Both trees: `bin/carbon` → `../lib/carbon/carbon-busybox`; `lib/carbon/{bazel,core,llvm,runtimes}`; `lib/carbon/llvm/bin` holds clang, clang++, clang-cl, ld.lld, ld64.lld and the LLVM tools. F adds `lib/carbon/include` (the `<carbon/expected.h>` header of EH-B). N's busybox needs only libc.so.6, libm.so.6 and the loader (`ldd`), and its highest versioned glibc symbol is GLIBC_2.34 (25 symbols, `objdump -T`), so N needs glibc 2.34 or newer. F's busybox links this container's own LLVM shared libraries (`/home/user/llvm-build/lib/libLLVM.so.24.0git`, `libclang-cpp.so.24.0git`, `ldd`): it is the container's arbiter, not something an evaluator can download, and it is a CMake and Ninja build rather than the Bazel `carbon_toolchain_tar` the guide teaches (header paragraph (amended 2026-10-13, review fold: A7)) |
| 2 | README forty_two, end to end (README.md:287-315) | WORKS on F and N, measured | The README's echo line verbatim, then `carbon compile --output=forty_two.o forty_two.carbon`, stderr empty; first `carbon link --output=forty_two forty_two.o` against an empty `--runtimes-cache` directory; `./forty_two` prints `42`, exit 0. Repeated with N's `bin` on `PATH` and a bare `carbon`: identical. `carbon build -o=forty_two_b forty_two.carbon`: identical output. Timings depend on machine load, measured three times on this 4-CPU container: compile 0.81 s (F) / 1.02 s (N), cold link 19.3 s / 21.6 s on an idle machine (rev 1); compile 0.28 s / 0.12 s, cold link 31.8 s / 31.7 s at load average 3.8 to 6.4 (fixer, 2026-10-13); cold link 46.6 s / 47.0 s at load average 10.7 (review A). A warm link takes 0.03 to 0.05 s in every run (amended 2026-10-13, review fold: A6). Commit 1 measured cold links of 16.2 s (F) and 16.4 s (N) at load average 2.4 to 3.6, and commit 2a's fixer 33.3 to 34.4 s on N at load average 4.7 to 7.6 (amended 2026-10-13, document-review fold: R2-8) |
| 3 | Runtimes cache | WORKS, measured | Default location `$XDG_CACHE_HOME/carbon_runtimes`, else `$HOME/.cache/carbon_runtimes` (`carbon help`, the `--runtimes-cache` entry); `carbon --no-threads build-runtimes --output-directory=DIR` on F: 63.6 s single-threaded, producing `clang_resource_dir`, `core`, `libcxx`, `libunwind`; `--prebuilt-runtimes=PATH` uses such a tree instead of building. The toolchain creates `carbon_runtimes` but not the directory that holds it: when `$XDG_CACHE_HOME` (used if set and absolute) or else `$HOME/.cache` does not exist, every link builds the runtimes in a temporary directory that it removes (toolchain/driver/runtimes_cache.cpp:140-203). Measured by commit 2a's fixer with N in fresh `HOME` directories: with no `.cache`, two links took 33.7 s and 33.4 s and cached nothing; with `XDG_CACHE_HOME` naming a missing directory, creating `$HOME/.cache` changed nothing (34.0 s); after `mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"` the first link took 33.3 to 34.4 s and the next 0.0 s, with `XDG_CACHE_HOME` set and unset (amended 2026-10-13, document-review fold: MAJOR-1, MINOR-5) |
| 4 | What `carbon link` reads from the system | MEASURED on F | `carbon link --output=x forty_two.o -- -v`: the Clang prefix adds `-rtlib=compiler-rt -unwindlib=libunwind -stdlib=libc++ -fuse-ld=lld` (toolchain/base/clang_invocation.cpp:132-142), link_driver.cpp:68 adds `--driver-mode=g++`, and ld.lld reads from the system only `Scrt1.o`, `crti.o`, `crtn.o`, `-lc`, `-lm` and the loader `/lib64/ld-linux-x86-64.so.2`; `dpkg -S` puts the first five in libc6-dev and the loader in libc6. CRT begin/end, the builtins, libc++ and libunwind come from the runtimes cache. With `-- --gcc-toolchain=/nonexistent` a warm link and a cold link (17.6 s) both still produce a binary printing 42: nothing from a GCC installation is linked. With `-- --sysroot=<empty dir>`: `ld.lld: error: cannot open Scrt1.o: No such file or directory`, then the same for crti.o, `unable to find library -lm`, `-lc`, and crtn.o |
| 5 | The README's `sudo apt install libgcc-11-dev` (README.md:304-307) | WORKS INDIRECTLY, measured on the analogue | apt metadata of the installed analogue libgcc-13-dev: Depends gcc-13-base, libgcc-s1, libgomp1, libitm1, libatomic1, libasan8, liblsan0, libtsan2, libubsan1, libhwasan0, libquadmath0; **Recommends libc6-dev**. So the README line supplies what the link needs (row 4) only through apt's default install of Recommends; its own comment (:304-306) already says gcc or g++ also suffice. libgcc-11-dev's own metadata is not readable here (the container's apt lists are empty; `apt-cache policy` knows only installed packages) |
| 6 | System headers for C++ interop | MEASURED | `carbon config --json` on N: `CLANG_INCLUDE_DIRS` ends with `/usr/local/include`, `/usr/include/x86_64-linux-gnu`, `/usr/include`, and `CLANG_SYSROOT` is `/`: imported C++ headers such as `<iostream>` reach the system C headers, which libc6-dev (and the linux-libc-dev it depends on) provides on Debian and Ubuntu. Measured with an empty directory standing in for a system without libc6-dev (`carbon compile --output=hello.o hello.carbon -- --sysroot=<empty dir>`): §2.B's hello fails at compile on F and on N, first with `<toolchain>/lib/carbon/runtimes/libcxx/include/__mbstate_t.h:55:4: error: "We don't know how to get the definition of mbstate_t on your platform."`, then `'ctype.h' file not found` and 186 lines in all; the pure-Carbon functions sample compiles with no error under the same flag. So the C headers are needed to COMPILE any `import Cpp` program, not only to link (amended 2026-10-13, review fold: A5) |
| 7 | Driver help: the flags the guides teach | MEASURED on F | `carbon help` (subcommands build-runtimes, build, clang, compile, config, format, language-server, link, lld, llvm; global `-v`, `--runtimes-cache=PATH`, `--prebuilt-runtimes=PATH`); `carbon help compile` (178 lines; identical to `carbon compile --help`): `--output=FILE`, `--output-last-input-only` ("Only write output for the last input file"), `--clang-arg=CLANG-ARG` or positional Clang args after `--`, `--phase=check`, `--optimize=(none\|debug\|speed\|size)`, `--target` (default x86_64-unknown-linux-gnu); `carbon help link` (43 lines): `--output=FILE`, positional `OBJECT_FILE...`, extra Clang link args after `--`, and "TODO: Support linking binary libraries, both archives and shared libraries"; `carbon help build` (63 lines): `-o, --output=FILE` ("If none is specified, `build` will use the name of the first provided input file"). Measured: `carbon build -o f1 functions.carbon` fails ("option `-o` (short for `--output`) requires a value to be provided"); `-o=f2` works; with no `-o` the output is named `functions` |
| 8 | `Core.PrintStr` under compile + link | FAILS on F and N, measured | A four-line `Core.PrintStr("Hello, world!\n")` program (the shape of examples/hello_world.carbon) compiles, then `carbon link` fails with `ld.lld: error: undefined symbol: _CPrintStr.Core`; link_driver.cpp:149-151 ("TODO: should also be able to link in the rest of the Core object files"); `carbon build -o=psb printstr.carbon` links it and prints `Hello, world!` (0.32 s on F, warm). The repository's own examples/hello_world.carbon therefore links only under the Bazel `carbon_binary` rule or `carbon build` (W-003) |
| 9 | Fork features on N | REJECTED by N, measured | Choice payloads: `` semantics TODO: `choice alternatives with parameters are not yet supported` ``; `match`: `` semantics TODO: `HandleMatchIntroducer` ``; `Core.Result`: ``member name `Result` not found in `Core` `` (the first diagnostics of §2.B samples 5 and 6 on N). The four other fork features, each with a one-statement program that F compiles and runs: if-let `error: expected expression` (at the `let`); `union` and `overload fn` both `error: unrecognized declaration introducer`; `Core.Slice` ``error: member name `Slice` not found in `Core` `` (amended 2026-10-13, review fold: B m-4) |
| 10 | The tutorial samples, by hand | WORKS, measured | The ten samples of §2.B (rev 2 text) with the three-command compile/link/run of D-EV-6, stderr empty on both toolchains: hello, functions, classes, generics, interop-use-C++, C++-library (with `carbon clang`), call-Carbon and the three-file package print the §4 values and exit 0 on F and on N (nightly 0.0.0-0.nightly.2026.10.12, the only nightly measured); choice/match and errors print the §4 values on F and are rejected by N (row 9). Rev 2 re-ran the eight single-file samples on both toolchains after A11's additions: functions prints `30 3 2 1 0 1`, errors `3 -7 3 0`, call-Carbon `14 100 20`, matching §4's hand derivations (amended 2026-10-13, review fold: A11, A12) |
| 11 | A separately compiled C++ library | WORKS, measured | `carbon clang -- -c rectangle.cpp -o rectangle.o`, `carbon compile --output=main.o main.carbon`, `carbon link --output=main main.o rectangle.o` → `42`, exit 0, on F and on N. An object of the same function (no standard library) compiled by the system `clang++` 21.1.8 or by `g++` 13 also links. A function using `std::string` compiled by `g++` or by the system `clang++` (whose headers are libstdc++'s) fails to link: `ld.lld: error: undefined symbol: std::__cxx11::basic_string<...>`; compiled by `carbon clang` it links and prints `10`. The g++ object links and prints `10` when libstdc++ is passed by path after `--` (`carbon link --output=s main.o strlib.o -- /usr/lib/x86_64-linux-gnu/libstdc++.so.6`, F), the workaround docs/guides/build_systems.md:284-292 documents on PR 52; the two libraries' types are distinct (libstdc++'s `std::__cxx11::` names against libc++'s), so it holds only while no standard-library object crosses between the g++ code and the rest (amended 2026-10-13, review fold: A9, B m-2). Re-measured by commit 2a's fixer on F and on N: the `g++` object of `rectangle.cpp` links with the tutorial's `main.carbon` and prints `42`; the `g++` `std::string` object fails as above, and links and prints `10` with libstdc++ passed by path; the toolchain's own `lib/carbon/llvm/bin/clang++` compiles either C++ file into an object that links (`42`, `10`) (amended 2026-10-13, document-review fold: MAJOR-3, MINOR-6) |
| 12 | Quoted C++ header lookup | MEASURED | `import Cpp library "rectangle.h"` resolves against the working directory, not the importing file's directory: compiling `../main.carbon` from a subdirectory fails with `'rectangle.h' file not found`; `--clang-arg=-I<dir>` and `-- -I<dir>` both fix it and give byte-identical objects (`cmp`) |
| 13 | A multi-file package | WORKS on F and N, measured | `package Geometry;` API file, `impl package Geometry;` implementation file, `import Geometry;` in main: `carbon compile --output=geometry.o geometry.carbon`; `carbon compile --output-last-input-only --output=geometry.impl.o geometry.carbon geometry.impl.carbon`; same for main with `geometry.carbon main.carbon`; `carbon link --output=shapes geometry.o geometry.impl.o main.o` → `12`, `14`. The API object has no symbols (`llvm-nm` prints nothing) and the link also works without it. `carbon build -o=shapes_b main.carbon geometry.carbon geometry.impl.carbon` → same. main alone: `error: imported API 'Geometry' not found`; three inputs with one `--output` and no last-input flag: ``warning: only outputting main.carbon to y.o, skipping output of 2 input files; pass `--output-last-input-only` to silence this warning``. The runner's command shape (each unit compiled with all of its siblings) and the tutorial's (each unit with the API file only) give byte-identical objects for all three units on F and on N (`cmp`) (amended 2026-10-13, review fold: B m-3, A12) |
| 14 | Diagnostics an evaluator meets | MEASURED on F | A `match` with no `default` arm whose arms all `return`, with no return after it, is rejected with ``error: missing `return` at end of function with declared return type``: measured for a choice match covering every alternative and for a match whose last arm is the irrefutable `case x: i32`; the same function whose `match` has a `default` arm compiles without a trailing `return` and runs (exit 1 for `F(0)` returning 1) (amended 2026-10-13, review fold: A3); `package Main;`: ``error: `Main//default` must omit `package` declaration``; `fn Run() -> i32 { return 3; }` exits 3; `fn Run() -> Core.Result((), i32)` returning `.Err` prints ``carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1`` to stderr and exits 1. The first behavior is a toolchain limitation, not the design: docs/design/error_handling.md:350-353 records that the checker's reachability analysis does not consult match exhaustiveness, while pattern_matching.md:590-592 and :612-617 design the code after an exhaustive `match` as unreachable (amended 2026-10-13, document-review fold: R2-1) |
| 15 | Windows | UNSUPPORTED, source and measured | clang_runtimes.cpp:240-242 and :400-402 return "TODO: Windows runtimes are untested and not yet supported."; link_driver.cpp:59-61 (Clang-driver linking "works well on Unix OSes"). Cross-targeting from Linux, measured: `carbon compile --target=x86_64-pc-windows-msvc` fails with `error: unsupported option '-fPIE' for target 'x86_64-pc-windows-msvc'` (exit 1); `carbon link` with that target prints the same error and then a crash stack dump, on F (exit 134) and on N alike — upstream behavior, recorded in W-059's notes at discharge |
| 16 | Platforms in upstream's CI configuration and releases | SOURCED from configuration, not measured (amended 2026-10-13, review fold: A1) | nightly_release.yaml:41 (`runs-on: ubuntu-22.04`), :97-105 (one `//toolchain/install:carbon_toolchain_tar_gz`), :118-127 (one asset `carbon_toolchain-${release_version}.tar.gz`, no OS or CPU in the name), and its header TODO :21-22 ("Build artifacts for all the different OSes ... rather than just x86 Linux"); tests.yaml:29-32 runs `bazel test` on ubuntu-22.04, ubuntu-22.04-arm and macos-14 ("Linux on x86-64 and AArch64, and macOS on AArch64"), which includes toolchain/install/install_test.py:190-202 (`test_carbon_end_to_end`: compile, link and run of `Cpp.std.cout << "Hello from Carbon\n"` from an installed tree; py_test at toolchain/install/BUILD:782-791). No Intel macOS and no Windows runner. On macOS the Clang prefix hard-codes `--sysroot=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk` and `-mlinker-version=705` (toolchain/base/clang_invocation.cpp:148-167): linking there needs Apple's Command Line Tools SDK at that path (source only). This row is configuration: it says upstream's code is in upstream's CI matrix, not that this fork's code passes there; row 26 is the fork's own record |
| 17 | The fork's own GitHub prereleases | STALE, measured | REST listing of the repository's releases: the newest fork toolchain is `fork-toolchain-143-ea02513be` ("Fork toolchain 0.0.0-0.dev @ ea02513be", 2026-09-25, 58 MB), 321 commits behind 0bdce60a5; `core/prelude/types/result.carbon` does not exist at ea02513be (added 2026-09-27 by a27059915, EH-A), and neither does `core/prelude/types/slice.carbon`; `union` and `overload` are not keywords there (toolchain/lex/token_kind.def), and if-let is a SKIP program (control_flow/if_let_let_else.carbon:10; W-012 landed 2026-09-27). Downloaded and run here: the tarball (sha256 `802a4ea5...`) unpacks, but its busybox needs GLIBC_2.44 (`cosh` and `sinh`, `llvm-objdump -T`), so on this Ubuntu 24.04 (glibc 2.39) every command fails with ``/lib/x86_64-linux-gnu/libm.so.6: version `GLIBC_2.44' not found (required by .../bin/carbon)``. Published before R28 (2026-09-26) ended agent use of the owner's runner; nothing has refreshed it since (amended 2026-10-13, review fold: B-6). The same listing, read again on 2026-10-13, has above it `arbiter-v0.0.0-0.nightly.2026.09.28` ("Arbiter: mirrored upstream nightly v0.0.0-0.nightly.2026.09.28", prerelease, published 2026-09-28), whose notes call it a verbatim mirror of upstream's nightly tarball of that date; not run here (amended 2026-10-13, document-review fold: MINOR-7, R2-7) |
| 18 | How the fork toolchain is built from source | SOURCED, not run here | fork_hosted.yaml:106-110 (`./scripts/run_bazel.py build -c opt //toolchain/install:carbon_toolchain_tar`) and :112-120 (unpack `bazel-bin/toolchain/install/carbon_toolchain-*.tar`, then `"$CARBON" version`); the unpacked directory is `carbon_toolchain-0.0.0-0.dev` (the `toolchain` field of fork/conformance/out/scoreboard.json). The user-facing script is `./scripts/run_bazelisk.py` (README.md:349, contribution_tools.md:78), which execs bazelisk; the hosted job's `run_bazel.py` is a retrying wrapper over `scripts_utils.locate_bazel()` (scripts/run_bazel.py) (amended 2026-10-13, review fold: A7, B m-3). Prerequisites docs/project/contribution_tools.md:46-113 (Debian or Ubuntu: Clang 21 or newer with libc++, LLD, bazelisk), :115-167 (macOS: Homebrew llvm, bazelisk), :169-176 (Windows: WSL). There is no Bazel in this container (task environment), so none of this ran here; the target and the unpack step ran on the hosted job of record 37402970811 (header paragraph) |
| 19 | Existing evaluator documentation | PARTIAL | README.md:273-363 "Getting started" (browser link :275-276; nightly walkthrough :278-315 for "a recent Ubuntu Linux or similar (Debian, WSL, etc.)", :281-282; reminder :317-321; build from source :323-355; links :357-362); docs/guides/ holds README.md (12 lines, one list item: the glossary) and glossary.md; docs/project/faq.md is 659 lines (9 H2, 34 H3; §0.3); toolchain/docs/driver.md is a 22-line developer stub |
| 20 | examples/ | CONTEXT | examples/hello_world.carbon uses `Core.PrintStr` (row 8); examples/sieve.carbon uses `returned var` and `Core.UnformedInit`; examples/interop/cpp/hello_world.carbon passes strings to C through `Cpp.std.data("...\0")`; examples/advent2024/README.md:13-17 says those samples "are not reflective of expected Carbon style and idioms". None is written for a reader |
| 21 | Interop shapes the conformance suite already proves | LANDED | `import Cpp library "<cctype>"` (code_org/importing_cpp_header.carbon), `import Cpp inline '''...'''` (code_org/importing_cpp_inline.carbon), `import Cpp;` plus a later `inline Cpp '''...'''` that calls `Carbon::Add` (interop/cpp_export_function.carbon), a C++ constructor as `Cpp.Vec2.Vec2(3, 4)` (interop/cpp_type_import_class_enum.carbon), `Cpp.std.vector(i32)` (interop/cpp_span_view.carbon), `for` over a C++ range (interop/cpp_range_member_begin_end_iterate.carbon). COMPILE-ARGS is used only for flags (`--clang-arg=-std=c++20`, `--cpp-exceptions=`), never for an include path; no program imports a quoted user header or links a C++ object; all 12 export goldens under toolchain/check/testdata/interop/cpp/function/export/ reach Carbon from `inline Cpp` or `import Cpp inline`, and no driver option emits a C++ header (`header` occurs in none of the compile, link or build help texts) |
| 22 | Conformance runner facts | MEASURED | compile command runner.py:516-524 (Carbon units only), link :546-551, `run_cmd` passes no `cwd` (:453-462), multi-unit units are `prog_dir.glob("*.carbon")` (:321). `--self-test` on 80a11e7f0: "150 programs parsed, 56 bullets in table, OK" plus the three self-checks; `--filter project/` with F's busybox and a private `--out`: 6 PASS / 6 SKIP in 2.7 s (bullet rollup: the evaluator bullet PASS through evaluator_docs_getting_started.carbon). On PR 52's head ea573f672 the same code sits at :690-698, :720-725 and :357, `run_cmd` takes `cwd=` (:563) and `--self-test` adds the build-script self-check (:1665, :1767), so every trunk line pin above moves at the integration commit (amended 2026-10-13, review fold: A2) |
| 23 | Prototype of this plan's programs | MEASURED | Two scratch mirrors with §2.E's rev 2 programs, the fixtures of §2.E.2 and the stub removed, each after `--update-readme-table` (ten rows replace one). State T (trunk 80a11e7f0's fork/conformance and gap-analysis.md): "159 programs parsed, 56 bullets in table, OK"; `--filter project/` with F: 15 PASS / 6 SKIP (every new program PASS except the C++-library SKIP); with N and `--filter project/evaluator`: 8 PASS, 2 COMPILE-FAIL (choice_match, errors: row 9's diagnostics), 1 SKIP. State C (PR 52's head ea573f672, with its cmake/ and examples/cmake/): the four self-checks OK and "159 programs parsed, 56 bullets in table, OK"; `--filter project/` with F: 18 PASS / 3 SKIP, all ten new programs PASS; with N and `--filter project/evaluator`: 9 PASS, 2 COMPILE-FAIL. The rev 2 checker passes on a mock page holding the twelve `carbon` blocks, the two `cpp` blocks and one `text` block per section ("14 samples, 0 errors"), and reports each of: a one-space code edit, `7` for `-7` in a `text` block, an indented `carbon` fence, and an edited `cpp` line. Wired into state C's `--self-test` it prints "evaluator-samples self-check: OK" and turns the self-test to ERRORS on the `7` edit (amended 2026-10-13, review fold: A2, A10, A11, B-1, B-3) |
| 24 | prek | AVAILABLE | `uvx prek --version`: prek 0.5.5. Markdown hooks: rumdl twice (`--fix`, upstream's `.rumdl.toml`, MD013 reflow), check-google-doc-style, markdown-toc, check-links, codespell, check-copyright; Python: ruff-check, ruff-format, ty; JSON: prettier. The four bazel-backed hooks are skipped by name (task environment) |
| 25 | The C++-library sample under PR 52's BUILD-SCRIPT channel | WORKS, measured (amended 2026-10-13, review fold: A2, B-1) | Fixture directory fork/evaluator/cpp_library/ (`main.carbon`, `rectangle.h`, `rectangle.cpp`, each with the license header, and `build.sh`, executable, running the section's four commands from its own directory into `$CARBON_BUILD_DIR`, build output on stderr, exit 2 on a compile failure and 3 on a link failure) plus the program of §2.E.2 in its BUILD-SCRIPT form, in the state C mirror of row 23: the build-script self-check OK (the identity rule of /home/user/carbon-cmake fork/conformance/README.md:222-231 holds); PASS with `42` on F and on N; a one-space edit of the fixture's `main.carbon` turns the self-check to ERRORS. Deleting the program's SKIP line and adding the BUILD-SCRIPT line after the bullet line turns the state T program into the state C program byte for byte (`cmp`). The check-header-guards hook (scripts/check_header_guards.py:64-65) rewrites a fixture guard `RECTANGLE_H_` to `CARBON_FORK_EVALUATOR_CPP_LIBRARY_RECTANGLE_H_` (exit 1, then 0); clang-format 21.1.8 leaves both C++ fixtures unchanged. The fixtures also fall under the clangd-tidy gates, which exclude only `**/*.tpl.h` and `fork/conformance/programs/**` (.github/workflows/clangd_tidy.yaml:66-77) and `.tpl.h` and `.diff.cpp` (the fork gate, fork_build_toolchain.yaml:133-151), and the repository's .clang-tidy enables `modernize-*` with `WarningsAsErrors: '*'`: clang-tidy 18.1.3 with that file rejects the leading `int` return type of `RectangleArea` in both fixtures (`modernize-use-trailing-return-type`) and accepts `auto RectangleArea(int width, int height) -> int`, the trailing return syntax of docs/project/cpp_style_guide.md:108, which commit 2a adopts in §2.B and in the fixtures; clangd-tidy itself was not run here (amended 2026-10-13, document-review fold: R2-2) |
| 26 | This fork's own CI record on macOS and Linux arm64 | MEASURED from run records, not run here (amended 2026-10-13, review fold: A1) | Read through the GitHub REST API (no dispatch): tests.yaml on fork PRs. SL-2 PR run 37398447710 at b4416a88e (2026-10-06): ubuntu-22.04-arm Test and Test (Opt) success; macos-14 Test (Opt) FAILURE, `//toolchain/testing:file_test FAILED` on toolchain/check/testdata/interop/cpp/function/export/overload_set.carbon (``call to 'F' is ambiguous`` for `Carbon::F(7L)`: on Darwin Carbon `i64` exports as `long long`, so a `long` converts equally to the `i64` and `bool` members), while `//toolchain/install:install_test PASSED in 58.8s` in the same job; macos-14 Test (Default) cancelled. OV-3 PR run 37359728074 (2026-10-05): the same macos-14 Test (Opt) failure, install_test PASSED in 28.5 s. UA-1 PR run 37406043564: the macos-14 jobs failed in test setup. Trunk push run 37406163455 at 8068151ed: every Test step skipped (no code change). So no run of the current trunk's code reached a test step on any runner; the last arm64 pass is b4416a88e; on macOS the end-to-end install test passed but a fork-only export golden fails since OV-3, and no fork record mentions the failure (filed as W-153) |
| 27 | The nightly download block, run verbatim | WORKS, measured (amended 2026-10-13, review fold: B-4, B-5) | §2.A item 3's block (rev 2, `wget`) in a fresh directory under `env -i` with a `PATH` that has no `carbon`: `date -d yesterday` on 2026-10-13 gives 2026.10.12; the download is 58783647 bytes, sha256 `f85bdd83f35bc6711ee92ab9de5e6be026e55cd8c143979146d93d0953e22f34`; the unpacked tree is identical to N (`diff -rq`); `carbon version` prints `Carbon Language toolchain version: 0.0.0-0.nightly.2026.10.12+62f1cc6`; §2.A item 6's forty_two block then prints `42`. For a date with no release (2001.01.01): `wget` prints `ERROR 404: Not Found.`, exits 8 and writes no file; `curl -LO` exits 0 and saves a 9-byte `Not Found` body, after which `tar -xf` fails with `gzip: stdin: not in gzip format` (exit 2); `curl -fLO` prints `curl: (22) The requested URL returned error: 404`, exits 22 and writes no file |
| 28 | The FAQ's reproducers | MEASURED on F and N (amended 2026-10-13, review fold: A4, A5, B m-4) | The twenty reproducers of §2.C, first run on F and on N by a scratch script (`ev1/fix/faq/run_repro.sh`), then in the one-line form §2.C shows by the prototype of D-EV-21's `check_faq.py` against a mock FAQ page quoting every expected line: "13 reproducers run, 0 errors" on F and "17 reproducers run, 0 errors" on N (each row runs on the toolchains §2.C names); a one-character edit of a quoted line on the page is reported |
| 29 | Toolchain rules that the design states otherwise or not at all | MEASURED on F and N (amended 2026-10-13, document-review fold: R2-3, R2-4) | A guard without parentheses, `case x: i32 if x < 0 =>`, and the design's own guard example (pattern_matching.md:809-816) fail on F with ``error: expected `(` after `if` `` (toolchain/parse/handle_match.cpp:214), and N prints the same parse error for the first, while the design's grammar is `case pattern [if expression]?`; `Core.Print(1 + if ... then 0 else 1)` fails on both with ``error: parentheses are required around this unary `if` operator``, as if.md:41-45 states, while `return if ...` and a parenthesized operand compile and run on both; the interop design's sections on inline C++ import, constructors and member access are TODO headings (interoperability/README.md:156, :240, :244), and no file under docs/design mentions `inline Cpp` (`grep`) |

### §0.2 Stale claims (each corrected at discharge, §8.6)

1.  **W-062 evidence `fork/gap-analysis.md:72` and `:160-166`**
    (work-items.json:1176-1177) point at the C++ exception interop row and
    at the W5 sum-types paragraph; the evaluator row is :90 and the W11
    paragraph is :261-273. Re-pinned at discharge.
2.  **W-062 evidence `evaluator_docs_review.carbon:2`** (:1175) is the
    license header's second line; the bullet line is :5 and the SKIP is :6.
    The file is deleted by this workstream, so the evidence moves to the
    guides and programs.
3.  **W-062 notes and the stub's SKIP** say the README getting-started is
    "Ubuntu-only (apt libgcc-11-dev dependency)" and that "its link step
    depends on `sudo apt install libgcc-11-dev`". The README addresses "a
    recent Ubuntu Linux or similar (Debian, WSL, etc.)" (README.md:281-282),
    and the link's system dependency is glibc's development files (libc6-dev
    on Debian and Ubuntu), which the libgcc line pulls in only through apt's
    Recommends (§0.1 rows 4-5). The correction is carried by the guide, the
    gap row and the decision log; README.md's command is not edited (D-EV-15).
4.  **The task brief and CM-1's plan cite README "Getting started" as
    :273-317.** The section runs :273-363 (§0.1 row 19); :317 is the
    reminder paragraph after the nightly shell block.
5.  **fork/ORCHESTRATION.md:415** quotes "126 PASS / 23 SKIP / 0 FAIL
    programs (149 total); 47/56 bullets green" (the PR 48 run), while the
    file it names as its source, fork/conformance/out/scoreboard.json
    (generated 2026-10-06), reads 128 / 0 / 22 over 150, 48/56. The line is
    re-quoted from the file at discharge unless an earlier landing has
    already done so; that is a quotation fix, not a regeneration (R9).
6.  **fork/ORCHESTRATION.md:446-459** lists
    `/home/user/arbiter/carbon_toolchain-0.0.0-0.nightly.2026.07.19/bin/carbon`
    and `/home/user/trial-tc/carbon_toolchain-0.0.0-0.dev/bin/carbon`; neither
    exists since the container was recreated. The current pair is F and N
    above. Re-listed at discharge.
7.  **Gap row 90's evidence** ("README nightly-tarball getting-started
    (Ubuntu-only) ... docs/guides contains only a glossary") is accurate
    apart from item 3; it is rewritten whole at discharge (§5.3).
8.  **The area summary, fork/gap-analysis.md:535-537** ("Evaluator
    documentation is thin ... docs/guides contains only a glossary and the
    driver doc is a stub"): the driver doc is still a 22-line stub, but it is
    a developer document under toolchain/docs; the sentence is rewritten to
    the landed state at discharge.
9.  **W-002 item (3)** ("no arbitration channel for ... document-review
    bullets (CMake, safety docs, evaluator docs)"): for the evaluator docs
    the channel is now transcription (D-EV-11, D-EV-13); W-002's notes gain
    that sentence and the item stays open for the rest.
10. **The fork's GitHub prereleases look like a fork toolchain download**
    (§0.1 row 17) but predate `Core.Result`, `if let`, unions, `overload fn`
    and slices, and the newest does not start on a glibc older than 2.44.
    No guide links them, and both getting_started.md and the FAQ name them
    and say why not to use them (D-EV-5; amended 2026-10-13, review fold:
    B-6).

### §0.3 What docs/project/faq.md covers, and what an evaluator FAQ adds

docs/project/faq.md answers project questions: what Carbon is and its status
(:60-131: how soon, why public, how complete, people, "Is there a demo?" at
:107-110 which points at the README tip, where to ask questions), why build
it (:133-201), alternatives (:203-301), feature-design rationale (:303-413),
how Carbon will work (:415-498: compiler infrastructure, the interop model,
generics versus templates, memory model, safety, upgrades), how the project
works (:500-579) and contributing (:581-659). It has no question about using
a toolchain: nothing on which toolchain to download, platforms, system
packages, the first-link wait, compile and link commands, include paths,
linking C++ objects, any error message, or the difference between this fork
and upstream. The evaluator FAQ (§2.C) holds exactly those, each keyed to a
measured diagnostic of §0.1, and links to docs/project/faq.md for the project
questions instead of repeating them; faq.md's "Is there a demo?" answer gains
one sentence pointing at the guide.

## §1 Design

### §1.A Shape: three pages, one per stage of the milestone's range

The bullet's range is "from getting started to FAQs". The guides follow it:
**docs/guides/getting_started.md** (choose a toolchain, install it on your
platform, build and run the first program, what the first link does),
**docs/guides/tutorial.md** (ten complete programs from hello world to a
multi-file package with C++ interop in both directions) and
**docs/guides/evaluator_faq.md** (toolchain and troubleshooting questions;
project questions stay in docs/project/faq.md). docs/guides/README.md lists
the three ahead of the glossary. Every tutorial section ends with links to
the FAQ entries for the errors that section can produce, and every FAQ entry
quotes the exact diagnostic text an evaluator will search for.

### §1.B Two toolchains, labelled per step

This repository is a fork. Its language features beyond upstream (choice
payloads, `match`, `Core.Result` and `?`, if-let, unions, `overload fn`,
slices) exist only in a toolchain built from this repository; the upstream
nightly is the only current prebuilt download and has none of them (§0.1 row
9, all seven measured). The fork's own `fork-toolchain-*` prereleases are
stale and the newest does not start here (§0.1 row 17); the guides name them
and say so (amended 2026-10-13, review fold: B-6, B m-4). The guides say so
up front and label every tutorial section with the toolchains it runs on,
measured: eight of the ten samples run on both F and N (nightly 2026.10.12,
the only one measured; D-EV-2 says what happens when a later nightly
differs); choice and match, and errors as values, need F (amended
2026-10-13, review fold: A12). The getting-started page gives both
acquisition paths: the upstream nightly (Linux x86-64, prebuilt; the
download block itself run verbatim, §0.1 row 27) and the fork built from
source with Bazel (the target and unpack step of the fork's hosted job,
which built it in run 37402970811; not run here).

### §1.C Platforms and system libraries

The platform table states, per row, its sources, each labelled as one of:
"measured" (Linux x86-64, this container); "upstream's CI configuration"
(§0.1 row 16: upstream's code is in upstream's test matrix); "this fork's CI
record" (§0.1 row 26: what the fork's own runs on that runner last showed,
with the run id). It never says "works" without a source, and never lets
upstream's configuration stand in for this fork's record (amended
2026-10-13, review fold: A1). The system-packages section states the
measured requirement (glibc's development files, needed both to compile any
program that imports a C++ header and to link; no GCC installation is
linked; N needs glibc 2.34 or newer; amended 2026-10-13, review fold: A5),
names libc6-dev for Debian and Ubuntu as verified by `dpkg -S`, explains the
README's libgcc line, and lists other distributions' package names with the
label "not verified by this project".

### §1.D The sample ladder

Ten programs, in this order, each complete; eight build with the same three
commands (compile, link, run), the C++ library adds one `carbon clang` step
and the package compiles three files. In order: hello world (C++
iostream); values, variables and functions; classes; interfaces and
generics; choice types and `match` (F); errors as values with
`Core.Result`, `?` and if-let (F); calling C++ (a standard function, a C++
class, a `std::vector` in a Carbon `for`); linking your own separately
compiled C++ library; calling Carbon from C++; a multi-file package. The
exact code is in §2.B.

### §1.E The FAQ end of the range

The evaluator FAQ has four groups: choosing and installing a toolchain,
building programs (one entry per measured diagnostic of §0.1 rows 4, 6, 8,
9, 11-14, 17 and 27), language and interop, and a pointer section to
docs/project/faq.md. The tutorial links into it by anchor; the FAQ links back
to the tutorial section that shows the fix. Every diagnostic the FAQ quotes
has a fixed reproducer (§2.C's table: input, command, toolchain, the exact
line), re-run on F and N by fork/evaluator/check_faq.py at commit 2 and in
the land sequence, so the FAQ end of the bullet is held to the same rule as
the tutorial's samples (D-EV-21; amended 2026-10-13, review fold: A4).

### §1.F The conformance mapping, in two states

Every `carbon` fenced block of tutorial.md is a complete program,
transcribed byte for byte into fork/conformance/programs/project/ under the
bullet "Project: basic evaluator documentation (getting started to FAQs)":
nine single-file programs and one three-unit directory, with EXPECT values
hand-derived in §4. The stub evaluator_docs_review.carbon is deleted, as its
own un-SKIP path says; evaluator_docs_getting_started.carbon stays and its
header cites the guide. The two `cpp` blocks of the C++-library section are
fixture files in fork/evaluator/cpp_library/ beside a byte-identical
`main.carbon` and the `build.sh` that runs the section's commands (§2.E.2).
fork/evaluator/check_samples.py diffs every `carbon` block against its
program, every `cpp` block against its fixture, and every section's `text`
block against its program's EXPECT-STDOUT (D-EV-13). The C++-library program
and the checker's enforcement depend on which trunk the branch sits on
(amended 2026-10-13, review fold: A2, B-1, B-3):

-   **State T, trunk without PR 52** (this branch's base, 80a11e7f0, where
    commits 1 to 4 are written): the runner builds Carbon units only, so the
    C++-library program is a SKIP whose text names the fixture script and
    the mechanical un-SKIP (§2.E.2); the checker runs by hand and in
    ORCHESTRATION's land sequence; no link to build_systems.md. Eight
    single-file programs and the directory PASS locally.
-   **State C, trunk with PR 52** (where EV-1 merges, by the recorded merge
    order): the C++-library program carries the BUILD-SCRIPT directive
    naming fork/evaluator/cpp_library/build.sh and PASSes (§0.1 row 25); the
    checker runs inside `runner.py --self-test`, so the R12 hook enforces it
    on every program edit; the guides link build_systems.md and cite PR 52's
    W-131 and W-133. All ten new programs PASS locally.

The integration commit of §3 moves the branch from T to C by merging trunk
into it (never a rebase of submitted commits, AGENTS.md) once trunk holds
PR 52. EV-1 is not merged in state T; if the land sequence must merge it
before PR 52, or PR 52 is abandoned, W-154 is filed then (D-EV-12).

### §1.G Decisions this plan auto-adopts (R29(a); each with a break condition)

-   **D-EV-1 — Three pages under docs/guides/** (§1.A): `getting_started.md`,
    `tutorial.md`, `evaluator_faq.md`, each with an H1, the `<!-- -->` license
    block and a markdown-toc table of contents. Rejected: one long page (the FAQ
    must be linkable on its own, and the getting-started page must stay short
    enough to follow at a terminal); a `docs/guides/tutorial/` directory of
    per-chapter pages (ten short chapters do not justify eleven files). Break
    condition: tutorial.md exceeds about 700 lines, or the evaluator-simulation
    review (D-EV-19) reports a task that needs more than one jump between pages
    — then split the tutorial into per-chapter pages. At commit 2a, document
    review 1 reported two tasks that needed two jumps (its MINOR-1a and
    MINOR-1b), each caused by a missing link rather than by the tutorial's
    length; the fold added the links instead of splitting, after which every
    task the review met needs at most one jump, and the folded tutorial.md is
    700 lines long, so neither condition fires (amended 2026-10-13,
    document-review fold: MINOR-1a, MINOR-1b).
-   **D-EV-2 — The guides target this fork's toolchain and label every step
    with the toolchains it runs on** (§1.B). The tutorial's commands use a
    bare `carbon` on `PATH` (measured to work, §0.1 row 2), so the same
    text serves both toolchains. A section labelled for the nightly says
    "measured with nightly 0.0.0-0.nightly.2026.10.12", because the guide
    downloads a moving nightly and only that one was measured (amended
    2026-10-13, review fold: A12). Break conditions: an upstream nightly
    accepts choice payloads, `match` and `Core.Result` (re-measured at each
    upstream merge with the two fork-only programs under N) — then the
    "fork toolchain only" labels drop; a later nightly fails one of the
    eight both-toolchain samples (re-measured by §8.3's download run at
    commit 1 and by the land sequence's runner pass with the then-current
    nightly) — then that section's label changes to the fork's toolchain,
    or the sample changes and §4 is re-derived (amended 2026-10-13, review
    fold: A12).
-   **D-EV-3 — Platform table with labelled sources per row** (§1.C;
    amended 2026-10-13, review fold: A1). Linux x86-64: upstream nightly
    prebuilt, measured on Ubuntu 24.04 (§0.1 rows 2 and 27). Linux arm64 and
    macOS arm64: no prebuilt toolchain; build this fork from source; two
    sources, labelled apart: (a) upstream's CI configuration runs
    upstream's code there, the end-to-end install test included
    (tests.yaml:29-32, install_test.py:190-202); (b) this fork's CI record
    (§0.1 row 26): the last arm64 run that reached its tests passed (run
    37398447710 at b4416a88e); on macOS the install test passed in the same
    run, but a fork-only export golden has failed there since OV-3 (W-153),
    and no run of the current trunk reached a test step because Actions is
    disabled. macOS is therefore "unverified for this fork's current trunk",
    the wording build_systems.md:463 uses on PR 52, and macOS linking needs
    the Command Line Tools SDK path of clang_invocation.cpp:148-157 (source
    only). Intel macOS: in no CI. Windows: unsupported
    (clang_runtimes.cpp:240-242), with WSL 2 running the Linux instructions
    as the documented route of contribution_tools.md:169-176, labelled not
    measured. Break conditions: nightly_release.yaml publishes another
    platform's artifact, or a Windows runner joins tests.yaml — then that
    row changes source and status; a fork tests.yaml run on macos-14 or
    ubuntu-22.04-arm reaches its test step green on the trunk EV-1 lands
    on — then that row's fork-record cell cites it and "unverified" drops.
-   **D-EV-4 — System packages stated as measured** (§0.1 rows 4-6): "the
    compiler reads glibc's C headers for any program that imports a C++
    header, and the link needs glibc's C runtime start files and the libc
    and libm development links; nothing from GCC is linked" (amended
    2026-10-13, review fold: A5); Debian and Ubuntu: `sudo apt install
    libc6-dev` (verified, `dpkg -S`), with one sentence on why the README's
    `libgcc-11-dev` line also works (Recommends); Fedora and RHEL
    `glibc-devel`, openSUSE `glibc-devel`, Arch `glibc`, each labelled
    "package name not verified by this project"; musl-based distributions
    labelled untested (the default target is x86_64-unknown-linux-gnu, §0.1
    row 7); N needs glibc 2.34 or newer. The page quotes the two failures as
    "measured with an empty sysroot standing in for a system without
    libc6-dev" (the compile-time `mbstate_t` error and the link-time
    `cannot open Scrt1.o`), never as what a missing package produces
    (amended 2026-10-13, review fold: B m-4). The page also says what was
    not tested: a machine with libc6-dev and no GCC packages at all. Break
    condition: a distribution's package metadata shows the headers or start
    files in a different package — correct that name and drop its label.
-   **D-EV-5 — The fork toolchain comes from source.** getting_started.md gives
    the Bazel route of §0.1 row 18 (`./scripts/run_bazelisk.py build -c opt
    //toolchain/install:carbon_toolchain_tar`, unpack into a directory, put its
    `bin` on `PATH`) with the prerequisites linked to contribution_tools.md,
    labelled "not run by this project's container (no Bazel there); the target
    and the unpack step are those of the fork's hosted conformance job, which
    built and ran them in run 37402970811; the script is the README's
    user-facing `run_bazelisk.py`, where that job uses `run_bazel.py`". The
    script substitution is deliberate: README.md:349 and
    contribution_tools.md:78 teach `run_bazelisk.py`, which needs no Bazel
    installed (amended 2026-10-13, review fold: A7, B m-3). No guide links the
    stale prereleases (§0.1 row 17), but the "Two toolchains" section and the
    FAQ entry "Can I download a prebuilt fork toolchain?" name the
    `fork-toolchain-*` prereleases, say they predate `Core.Result`, if-let,
    unions, `overload fn` and slices, quote the GLIBC_2.44 loader error the
    newest one gives on Ubuntu 24.04, and tell the reader not to use them for
    this tutorial (amended 2026-10-13, review fold: B-6). Both places also name
    the newest entry of that releases page,
    `arbiter-v0.0.0-0.nightly.2026.09.28`, a mirror of upstream's nightly of
    2026-09-28 and so not this fork's toolchain (amended 2026-10-13,
    document-review fold: MINOR-7, R2-7). The build block's label also says that
    a build on the reader's machine does not get the hosted job's read-only
    remote cache, which the CI action configures
    (.github/actions/build-setup-common/action.yml:70) and .bazelrc does not
    (:45-51, a local disk cache only), so the job's 9m29.6s is no estimate for
    it (amended 2026-10-13, document-review fold: MAJOR-2). Residue W-152:
    publish a current fork toolchain artifact and retire or relabel the stale
    ones. Break conditions: a current fork toolchain artifact is published —
    then getting_started.md gains its download path ahead of the source build;
    the prereleases are deleted or refreshed — then the warning and the FAQ
    entry are rewritten from the new listing (amended 2026-10-13, review fold:
    B-6).
-   **D-EV-6 — Compile and link are the taught path; `carbon build` is the
    shortcut.** Every sample is built by `carbon compile --output=X.o
    X.carbon`, `carbon link --output=X X.o`, `./X` — the README's commands,
    the runner's commands and the commands a build system issues. `carbon
    build` is taught in one getting_started.md section with its measured
    caveats (the `-o=FILE` spelling, the default output name, that it links
    the Core library objects that `link` omits) and is named again only as
    the one-step alternative in the tutorial's package section and in the
    FAQ. In state C the caveats cite W-133, PR 52's filed item for the same
    driver behaviour (amended 2026-10-13, review fold: A9). Break condition:
    `carbon link` gains the Core objects (link_driver.cpp:149-151) or
    `carbon build` accepts C++ sources — then revisit which path is primary.
-   **D-EV-7 — Output idioms: `Core.Print` for integers, C++ iostream for
    text; no `Core.PrintStr` in any sample.** `Core.PrintStr` does not link
    under compile and link (§0.1 row 8); the hello world prints through
    `Cpp.std.cout`, which is install_test.py's own program shape. The FAQ
    explains the `_CPrintStr.Core` failure and both ways around it; in
    state C it also links build_systems.md's "Core libraries" section, which
    links the Core `io` objects explicitly (amended 2026-10-13, review fold:
    B m-2). Break condition: W-003 lands — then hello world switches to
    `Core.PrintStr` and the FAQ entry is deleted.
-   **D-EV-8 — The ten samples of §2.B are fixed by this plan.** They were
    written from working code (R3: the conformance programs of §0.1 row 21,
    types/classes.carbon, generics/checked_generics.carbon,
    control_flow/match_guard_binding.carbon,
    control_flow/if_let_let_else.carbon,
    error_handling/result_prelude_diff.carbon,
    code_org/library_multifile_export/), compile-verified on F and N (R6;
    §0.1 row 10) and avoid every trap of §0.1 row 14 (each value-returning
    `match` assigns in its arms and returns once). Rev 2 makes three of them
    check both sides of the branch they teach: functions adds a second
    if-expression that takes its `else` arm, errors adds an if-let with an
    `else` on a failing division, and call-Carbon passes Clamp's bounds so
    the three calls reach its value, upper and lower arms (amended
    2026-10-13, review fold: A11). The implementer copies them; any change
    is re-run on both toolchains and recorded. Break condition: a sample
    stops compiling on F after a merge — then fix the sample, re-derive §4
    and record the change in the commit message.
-   **D-EV-9 — FAQ split and linkage** (§1.E): toolchain questions in
    docs/guides/evaluator_faq.md, project questions stay in
    docs/project/faq.md, which gains one pointer sentence in "Is there a
    demo?" (:107-110). Rejected: adding the questions to docs/project/faq.md
    (a 659-line upstream page about the project; mixing fork toolchain
    troubleshooting into it would raise merge conflicts at every upstream
    merge). Break condition: upstream adds a user-facing FAQ under
    docs/guides — then merge into it at the next upstream merge.
-   **D-EV-10 — CM-1's build_systems.md: links and consistency in state C**
    (amended 2026-10-13, review fold: A9, B-1, B m-2). check-links would fail on
    a trunk without the page, and an evaluator must not meet a dead link, so
    commits 1 to 4 (state T) carry no link. The integration commit (§3, state C)
    adds: the link in getting_started.md's "Next steps" and in the FAQ entry "An
    imported package API is not found"; the FAQ's g++ entry gains the W-131
    citation and a link to build_systems.md's "Mixed Carbon and C++" section;
    the PrintStr entry links its "Core libraries" section; the `carbon build`
    caveats cite W-133; W-131's notes gain EV-1's measurement that C-ABI objects
    from g++ link (§0.1 row 11) and W-133's notes a pointer to the FAQ entry.
    The FAQ then states both measurements (C-ABI code links; code using the C++
    standard library needs `carbon clang` or the libstdc++-by-path workaround
    with its caveat) and points at build_systems.md, whose general sentence is
    about objects that use the standard library (its mixed example prints
    through `std::cout` in mixed/twice.cpp); W-131's note is where the two pages
    meet. Nothing is filed for the links. Break condition: PR 52 merges before
    EV-1's commit 1 — then all of this goes into commits 1 to 4 directly and the
    integration commit is only the merge.
-   **D-EV-11 — One program per sample, named
    `project/evaluator_tutorial_<topic>`** (§1.F, §2.E). Each file is the
    license header, a blank line, the directives (bullet verbatim, R7;
    `EXPECT-EXIT: 0`; the hand-derived `EXPECT-STDOUT`), a provenance
    comment naming the tutorial's H2 title exactly (§2.E.1), a blank line
    and the sample byte for byte. The package is the directory
    `project/evaluator_tutorial_package/` (units `geometry.carbon`,
    `geometry.impl.carbon`, `main.carbon`); the runner's own multi-unit
    convention compiles every unit with all of its siblings, one or two
    more files per command than the tutorial passes, and the objects are
    byte-identical to the tutorial's (§0.1 row 13; amended 2026-10-13,
    review fold: B m-3, A12). The stub is deleted; the getting-started
    program stays with a refreshed header. Rejected: one program holding
    every sample (a failure would not name the section), and `.diff.cpp`
    oracles (D-EV-14). Break condition: the runner gains a directive that
    names a documentation source — then the provenance comment becomes that
    directive.
-   **D-EV-12 — The separately compiled C++ library sample lands as a
    BUILD-SCRIPT program; a SKIP is only its state T interim** (amended
    2026-10-13, review fold: A2, A8, B-1). The fixture directory
    fork/evaluator/cpp_library/ (`main.carbon`, `rectangle.h`,
    `rectangle.cpp`, `build.sh`; §2.E.2) is committed in commit 2 in both
    states, so the page's two `cpp` blocks have an instrument and the
    un-SKIP is mechanical. State C: the program carries the BUILD-SCRIPT
    directive naming `build.sh` and PASSes through PR 52's channel (§0.1 row
    25; the channel runs scripts from the repository root, and `build.sh`
    changes to its own directory because quoted headers resolve against the
    working directory, row 12). State T: this trunk's runner builds Carbon
    units only (runner.py:516-524, :546-551, :321) and runs without a `cwd`
    (:453-462), so the program SKIPs with §2.E.2's text, which names the
    fixture script and the two-line un-SKIP. EV-1 merges only in state C
    (§1.F); W-154 is filed only if the land sequence must merge it in state
    T or PR 52 is abandoned, and it then carries the integration commit's
    steps (or, with PR 52 abandoned, a runner channel for C++ units with the
    program directory as the working directory). W-002 item (3) is
    answered for this program by the BUILD-SCRIPT channel in state C.
    Rejected: `COMPILE-ARGS: --clang-arg=-Ifork/conformance/...` (true only
    when the runner starts at the repository root, which nothing enforces)
    and a header-only variant (not the sample the page shows). Break
    condition: PR 52's BUILD-SCRIPT contract changes before EV-1 merges —
    then `build.sh` follows the new contract and §0.1 row 25 is re-measured.
-   **D-EV-13 — The R27 instrument is a checker script, enforced by
    `--self-test` in state C** (amended 2026-10-13, review fold: A2, A10,
    B-1, B-3). fork/evaluator/check_samples.py (§2.E.4, stdlib only) reads
    the fenced blocks of the three pages and checks: the column-0 `carbon`
    blocks equal their programs' bodies in page order (tutorial.md 12, the
    other two pages 0); every H2 section of tutorial.md that holds `carbon`
    blocks holds exactly one `text` block, equal to the EXPECT-STDOUT of the
    program of the section's last `carbon` block; the two `cpp` blocks equal
    the fixtures `rectangle.h` and `rectangle.cpp` after each fixture's
    license comment and with the hook-imposed guard name read as
    `RECTANGLE_H_`; the C++-library program's body equals the fixture
    `main.carbon`'s; an indented `carbon` fence on any of the three pages is
    an error; and the README's forty_two echo line is in README.md and
    getting_started.md, with the getting-started program's body equal to
    what it writes. Every program header names the checker. State T: it runs
    by hand at commit 2 and in ORCHESTRATION's land sequence. State C: the
    integration commit adds `evaluator_samples_self_check()` to
    `runner.py --self-test` beside PR 52's build-script self-check (§2.E.4),
    so the R12 hook runs it on every program edit and the land sequence's
    `--self-test` runs it; no ledger item is filed for it. A page-only edit
    is still caught only when `--self-test` next runs, so the land-sequence
    entry stays in both states. Break condition: the R12 hook gains a
    trigger for docs/guides/ edits — then the land-sequence entry goes.
-   **D-EV-14 — EXPECT values are hand-derived from each sample's arithmetic
    (§4; R16(d)); no differential oracles.** The C++ parts are part of the
    program under test, there is no overload set (R30 does not apply), and
    every value is one line of arithmetic a reviewer re-derives. Break
    condition: a sample gains a value that cannot be derived by hand — then
    it gets a `.diff.cpp` oracle.
-   **D-EV-15 — Upstream-owned text is touched minimally.** README.md gains
    a one-sentence paragraph after :276 (the browser paragraph) pointing at
    docs/guides/getting_started.md and one list item after :362; its shell
    commands, including the libgcc line, are not edited (§0.2 item 3: the
    guide carries the correction). docs/project/faq.md gains one sentence at
    :107-110; docs/guides/README.md gains three list items. CM-1 adds a
    README sentence between :315 and :317, a separate hunk. These lines go
    on the V-3a register in the decision-log entry. Break condition: an
    upstream merge rewrites README "Getting started" — then the pointers
    are re-placed in that merge.
-   **D-EV-16 — Gap row 90 flips PARTIAL → DONE on transcription plus
    document review** (row 88's DONE-on-review precedent; SAFE-1, PR 53,
    makes the same call for row 89). Header delta DONE +1, PARTIAL −1. The
    row says what the new programs are: documentation-sync programs under a
    bullet that was already PASS (bullets unchanged), checked by
    `--self-test`'s evaluator-samples self-check in state C (amended
    2026-10-13, review fold: B-3). The install steps that no review here
    can falsify are listed in the row and the decision log: the fork
    build-from-source block (no Bazel; its target and unpack step ran on
    hosted run 37402970811, not as the guide's commands), any platform but
    Linux x86-64, any distribution but Ubuntu 24.04, and a system without
    libc6-dev (stood in for by an empty sysroot) (amended 2026-10-13,
    review fold: B-4). Break condition: either document review of D-EV-19
    finds a step in the range "getting started to FAQs" the pages do not
    cover, or a step that fails as written, the nightly download included
    — then the row stays PARTIAL until it is fixed.
-   **D-EV-17 — Verification is local, and the plan says what cannot run**
    (§8): prek to a fixpoint, `--self-test`, the runner with F, the checker,
    the FAQ reproducer script on F and N, the nightly download block run
    verbatim, and the C++-library commands by hand on F and N. Not run: the
    fork build-from-source block (no Bazel), any non-Linux or non-x86-64
    platform, a distribution other than Ubuntu 24.04, a system without
    libc6-dev (an empty sysroot stands in) or with libc6-dev and no GCC
    packages, the stale prerelease on a glibc of 2.44 or newer, and any
    hosted workflow (amended 2026-10-13, review fold: B m-3, B-4). Break
    condition: Actions is re-enabled — then the hosted conformance run
    becomes the record and the "not of record" phrases are removed in a
    records commit.
-   **D-EV-18 — Ids are reserved now and allocated before commit 2** (amended
    2026-10-13, review fold: A8, B-2). The block W-152 to W-159 is reserved
    (ST-1's plan at bff5ba4e8, fork/string/plan.md:35-38, records the same block
    and starts at W-160) and stamped into trunk's ORCHESTRATION by the
    orchestrator, as W-151 was: W-152 a current downloadable fork toolchain (and
    the stale prereleases), W-153 the macOS failure of the OV-3 export golden
    (§0.1 row 26), W-154 only for a merge in state T (D-EV-12), W-155 to W-159
    for document-review friction left unfixed (D-EV-19). The allocation grep of
    §8.6 runs at sign-off, again before commit 2 writes any id, and again at
    discharge, over work-items.json, the status header of every live branch's
    `fork/*/plan.md` and trunk's ORCHESTRATION reservations. A reserved id that
    goes unused stays unused and is never reused; the discharge records it as
    "reserved, unused". Break condition: an id of the block is already taken
    when the grep runs — then the block moves to the next free eight ids before
    any program or page carries one, and §8.6 records both greps.
-   **D-EV-19 — Reviews** (amended 2026-10-13, review fold: B m-5, B-4,
    A5): two plan reviews (R29(c); rev 2 folds them). After commit 2, TWO
    fresh-context document reviews, as SAFE-1 chose for a documentation PR
    with no hosted verification (D-SAFE-23): R29(c)'s reduction to one
    review applies "once hosted verification ... is fully green", which
    never happens here while Actions is disabled. Review 1, evaluator
    simulation (process.md north-star guard 2): a skeptical C++ developer
    starts from a `PATH` without `carbon`, performs the nightly download
    itself, follows getting_started.md, then the tutorial, then looks up
    the FAQ for every error met, using only the pages, the downloaded
    nightly and F, and runs the empty-sysroot probe for a system without
    libc6-dev. Review 2, strictness (the rulebook's strictness briefs for
    conformance programs and design docs, fork/rulebook.md:100-101):
    every platform, distribution and toolchain claim carries its source;
    every quoted diagnostic matches §2.C's reproducer output; the programs,
    fixtures and checkers match §2.E; R31 counts and links. A fixer folds
    both (commit 2a) before commit 3. Then one implementation review of
    commits 1 to 3 and its fixer (commit 4). Friction the simulation reports
    that commit 2a does not fix is filed under W-155 to W-159 in commit 3
    (guard 2). Break condition: a document review reports a failing step —
    the fix lands in commit 2a, before commit 3.
-   **D-EV-20 — The download line stays README.md:292's `wget`** (amended
    2026-10-13, review fold: B-5). Rev 1's `curl -LO` saved GitHub's
    "Not Found" page under the tarball's name and exited 0 for a date with
    no release, so the next step failed in `tar` (§0.1 row 27). `wget` exits
    8 with `ERROR 404: Not Found.` and writes no file; it is the README's own
    command, so the guide and the README show one spelling of the step, and
    rev 1's reason for switching ("minimal images lack wget") was never
    measured. One sentence gives the curl form for a machine without wget,
    `curl -fLO URL`, and says why the `-f` matters; the FAQ's download
    entry covers both tools. Break conditions: README.md changes its
    download tool — the guide follows; a report that `wget` is missing on a
    supported image — the block switches to `curl -fLO`.
-   **D-EV-21 — The FAQ's quoted diagnostics are reproducer-backed** (amended
    2026-10-13, review fold: A4). §2.C fixes a reproducer for every
    diagnostic-keyed entry (input of ten lines or fewer, command, toolchain,
    exact line, exit status), measured on F and N (§0.1 row 28).
    fork/evaluator/check_faq.py (stdlib only) runs the reproducers that apply to
    the toolchain it is given and requires each expected line both in the output
    and as a whole line inside a `text` block of evaluator_faq.md, and it
    requires every line of a `text` block of getting_started.md other than
    program output to be such a line of the FAQ, so the guide's repeated
    diagnostics stay the reproducer-backed ones (amended 2026-10-13,
    document-review fold: R2-5, MINOR-9); it needs a toolchain, so it is not
    part of `--self-test`. It runs at commit 2 on F and N, a mismatch blocks the
    commit as a failing tutorial sample would, the result goes in the message,
    and the land sequence runs it with the then-current nightly. Break
    condition: a toolchain changes a quoted diagnostic — the FAQ quote and the
    reproducer change together in one commit.

## §2 Implementation spec, file by file

Every page: H1, then the HTML-comment license block, then a one-paragraph
introduction, then a "Table of contents" H2 between the two markdown-toc
markers (copy them from docs/project/faq.md:9-58; the hook fills the list),
then the H2 sections. Prose wraps at 80 columns by hand; every flag, path
and quoted diagnostic sits in a fenced block or in a code span placed so
that no wrap can start a line with `#`, a dash and a space, `+`, `*` or a
digit and a period (R31); the doc-style word list is avoided in prose and
code alike (R31(d)). Commands run from the directory holding the sample;
`carbon` is the toolchain's `bin/carbon` on `PATH`.

### §2.A docs/guides/getting_started.md (new, about 240 lines)

Title "Getting started with the Carbon toolchain". Sections, each an H2 with
exactly the quoted title (anchors are what the tutorial, the FAQ and
faq.md's pointer target; amended 2026-10-13, review fold: B m-1):

1.  **"Two toolchains"** — a two-row table: the upstream nightly (prebuilt for
    Linux x86-64 only; upstream's language subset) and this fork's toolchain
    (built from this repository; adds choice payloads, `match`, `Core.Result`
    and `?`, if-let, unions, `overload fn`, slices — each measured absent from
    nightly 2026.10.12, §0.1 row 9; amended 2026-10-13, review fold: B m-4). One
    sentence: the tutorial marks the two sections that need the fork's
    toolchain. One paragraph on the fork's GitHub Releases page: its
    `fork-toolchain-*` prereleases (newest `fork-toolchain-143-ea02513be`,
    2026-09-25) predate `Core.Result`, if-let, unions, `overload fn` and slices,
    the newest stops on Ubuntu 24.04 with the GLIBC_2.44 loader error of §0.1
    row 17, and they are not for this tutorial (W-152; amended 2026-10-13,
    review fold: B-6). The nightly's "Linux x86-64 only" cites its source,
    upstream's release configuration, which publishes one tarball built on Linux
    x86-64 (§0.1 row 16) (amended 2026-10-13, document-review fold: MINOR-4);
    the releases paragraph first names the page's newest entry,
    `arbiter-v0.0.0-0.nightly.2026.09.28`, a copy of upstream's nightly of
    2026-09-28 with none of the fork's features (§0.1 row 17) (amended
    2026-10-13, document-review fold: MINOR-7, R2-7); and the first W-152 on the
    page says it is tracked in this fork's work-item ledger, linked as
    /fork/inventory/work-items.json, as does the FAQ's first id (amended
    2026-10-13, document-review fold: MINOR-8). One sentence: the browser link
    of README.md:275-276 runs upstream's toolchain, so presumably none of the
    fork's features, labelled "inferred: not measured by this project" (amended
    2026-10-13, review fold: B m-4).
2.  **"Platforms"** — the table of D-EV-3 with a "Status" column and a "Sources"
    column whose entries say which kind they are (amended 2026-10-13, review
    fold: A1): Linux x86-64 (prebuilt nightly; measured on Ubuntu 24.04 with
    glibc 2.39); Linux arm64 (no prebuilt; build from source; upstream's CI
    configuration runs upstream's code there; this fork's CI record: last
    passing run 37398447710 at b4416a88e, no run of the current trunk); macOS
    arm64 (no prebuilt; build from source; "unverified for this fork's current
    trunk": upstream's CI configuration runs upstream's code there, and this
    fork's record shows the install test passing beside a failing fork-only
    export test, W-153; linking needs the Command Line Tools SDK); Intel macOS
    (in no CI); Windows (unsupported; WSL 2 with the Linux instructions, not
    measured). Each "no prebuilt toolchain" cites upstream's release
    configuration (amended 2026-10-13, document-review fold: MINOR-4); the Linux
    x86-64 sources say that the fork toolchain measured is a CMake build on the
    Ubuntu 24.04 machine that ran the measurements, and that run 37402970811 ran
    at 606a99c5a, whose later trunk commits change only fork records, not the
    toolchain (`git diff --stat 606a99c5a 80a11e7f0`: five fork/ record files)
    (amended 2026-10-13, document-review fold: MINOR-3).
3.  **"Install the upstream nightly on Linux x86-64"** — this block, which is
    the README's own download and unpack lines plus a `PATH` line, run verbatim
    in a fresh directory (§0.1 row 27; D-EV-20; amended 2026-10-13, review fold:
    B-4, B-5):

    ```shell
    VERSION="$(date -d yesterday +0.0.0-0.nightly.%Y.%m.%d)"
    wget "https://github.com/carbon-language/carbon-lang/releases/download/v${VERSION}/carbon_toolchain-${VERSION}.tar.gz"
    tar -xf "carbon_toolchain-${VERSION}.tar.gz"
    export PATH="$PWD/carbon_toolchain-${VERSION}/bin:$PATH"
    carbon version
    ```

    with the expected first line shape `Carbon Language toolchain version:
    0.0.0-0.nightly.YYYY.MM.DD+<commit>`; one sentence: without `wget`, use
    `curl -fLO` with the same URL, because without `-f` curl saves GitHub's "Not
    Found" page under the tarball's name; one sentence: if that date has no
    release, `wget` prints `ERROR 404: Not Found.`, so pick a date from the
    releases page (FAQ "The download fails, or tar says the file is not in gzip
    format").
4.  **"Build this fork's toolchain from source"** — prerequisites by link to
    contribution_tools.md#setup-commands, then:

    ```shell
    git clone https://github.com/jmann345/carbon-lang
    cd carbon-lang
    ./scripts/run_bazelisk.py build -c opt //toolchain/install:carbon_toolchain_tar
    mkdir -p "$HOME/carbon-fork"
    tar -xf bazel-bin/toolchain/install/carbon_toolchain-*.tar -C "$HOME/carbon-fork"
    export PATH="$HOME/carbon-fork/carbon_toolchain-0.0.0-0.dev/bin:$PATH"
    carbon version
    ```

    labelled per D-EV-5 (the target and unpack step are the hosted job's, which
    built and ran them in run 37402970811; the script is the README's
    `run_bazelisk.py`; not run by this project's container), with the expected
    version prefix `0.0.0-0.dev` (the hosted job's build printed
    `0.0.0-0.dev+unknown`) and the hosted job's build time as the only measured
    duration (9m29.6s on a GitHub-hosted ubuntu-22.04 runner with upstream's
    read-only remote cache; amended 2026-10-13, review fold: A7). One sentence:
    the result has the same layout as the nightly, so every later command is
    identical. The repository's default branch is `trunk` (REST, 2026-10-13).
    The section opens by saying that only the tutorial's two fork-only sections
    need this toolchain, and closes by saying that with both toolchains
    installed a bare `carbon` runs the one exported last and how to run the
    other by its full path (amended 2026-10-13, document-review fold: MINOR-2).
    After the 9m29.6s sentence, one paragraph says that a build on the reader's
    machine gets no remote cache (the CI action sets it, not .bazelrc), so it
    compiles LLVM and Clang from source and takes longer, by an amount and with
    a disk use this project did not measure (amended 2026-10-13, document-review
    fold: MAJOR-2).
5.  **"System packages"** (renamed from "System packages for linking";
    amended 2026-10-13, review fold: A5) — D-EV-4's text: the compiler reads
    glibc's C headers for any program that imports a C++ header, and the
    link reads the five files and the loader named in §0.1 row 4; the
    Debian and Ubuntu command `sudo apt install libc6-dev`; why the
    README's `libgcc-11-dev` also works; the unverified names for Fedora
    and RHEL, openSUSE and Arch; glibc 2.34 or newer for the nightly; musl
    untested; and both failures in `text` blocks, labelled "measured with an
    empty sysroot standing in for a system without libc6-dev": the compile
    error `"We don't know how to get the definition of mbstate_t on your
    platform."` and the link error `cannot open Scrt1.o` (§0.1 rows 4 and
    6; amended 2026-10-13, review fold: B m-4).
6.  **"Your first program"** — the README's echo line verbatim (the
    checker of D-EV-13 requires it), then one sentence and this block, so
    that the first link already has a cache directory (§0.1 row 3)
    (amended 2026-10-13, document-review fold: MAJOR-1, R2-8, MINOR-5):

    ```shell
    mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"
    ```

    then:

    ```shell
    carbon compile --output=forty_two.o forty_two.carbon
    carbon link --output=forty_two forty_two.o
    ./forty_two
    ```

    expected output `42`; one paragraph per command (what each produces).
7.  **"The first link takes a while"** — the runtimes cache: "about 20 seconds
    on an idle four-core Linux x86-64 machine, and up to twice that or more on a
    busy one (measured on 2026-10-13: 16 to 22 seconds at load average below 4,
    32 to 34 at load average 4 to 8, 47 at load average 10.7); later links take
    hundredths of a second" (§0.1 row 2; amended 2026-10-13, review fold: A6;
    the measured range (amended 2026-10-13, document-review fold: R2-8)), the
    default location and why item 6 creates it (the same `mkdir` line (amended
    2026-10-13, document-review fold: MAJOR-1, MINOR-5)), and, introduced as
    options the tutorial does not need, each of which builds the runtimes once
    more (amended 2026-10-13, document-review fold: MINOR-11), the global
    `--runtimes-cache=PATH` option and prebuilding with the `build-runtimes`
    subcommand (its `--output-directory=DIR`) and then `--prebuilt-runtimes=DIR`
    (§0.1 row 3).
8.  **"One-step builds"** — `carbon build -o=forty_two forty_two.carbon`,
    the measured `-o=` spelling, the default output name, and that it also
    links the Core library objects (`Core.PrintStr`, FAQ); in state C the
    caveats cite W-133 (amended 2026-10-13, review fold: A9).
9.  **"Next steps"** — the tutorial, the FAQ, `carbon help` and `carbon help
    compile`, docs/design/README.md for the language design; in state C
    also docs/guides/build_systems.md for CMake and Make (D-EV-10).

### §2.B docs/guides/tutorial.md (new, about 450 lines)

Title "Tutorial: Carbon from hello world to C++ interop". The introduction
says: each section is one complete program; save it under the name shown,
build it with the three commands below, compare the output; each section
says which toolchain runs it. The build block, shown once and referred to
after:

```shell
carbon compile --output=hello.o hello.carbon
carbon link --output=hello hello.o
./hello
```

Each section: a "Runs on:" line, the filename, the `carbon` fenced block
(verbatim below, column 0, never inside a list), the expected output in a `text`
fenced block (§4), a short "What to notice" paragraph naming the constructs and
linking the design document that defines them (docs/design/README.md anchors or
the topic pages), and "If it fails" links to FAQ entries.

Page structure, fixed (amended 2026-10-13, review fold: B m-1, A10, A12): the
H1, the license block, the introduction, "Table of contents" (H2, markdown-toc),
"Before you start" (H2: the build block above and the toolchain labels), one H2
per sample with exactly the title below, then "Where next" (H2). A sample
section holds exactly one `text` block, its expected output (the checker
compares it with the program's EXPECT-STDOUT, D-EV-13); diagnostics a section
mentions go inline or in the FAQ, never in a second `text` block. A "Runs on:"
line that names the nightly reads "the upstream nightly (measured with
0.0.0-0.nightly.2026.10.12) and this fork's toolchain" (D-EV-2); a "Runs on:"
line for this fork's toolchain only links "this fork's toolchain" to
getting_started.md's "Build this fork's toolchain from source" (amended
2026-10-13, document-review fold: MINOR-1a). "Before you start" also tells the
reader to give each of the two sections with several files its own directory,
since both have a `main.carbon` (amended 2026-10-13, document-review fold:
MINOR-10). Links are file-level where an anchor is not listed; anchors are the
slugs of the exact H2/H3 titles of §2.C (check-links decides).

| Section (H2 title) | Design links | FAQ entries linked under "If it fails" |
| --- | --- | --- |
| Hello, world | docs/design/README.md#tour-of-the-basics; docs/design/interoperability/README.md | "Compiling a C++ import fails inside libc++"; "Linking fails with an undefined symbol in Core" |
| Values, variables and functions | docs/design/README.md#name-binding-declarations; docs/design/functions.md; docs/design/control_flow/README.md; docs/design/expressions/if.md | "How is the exit code set?" |
| Classes | docs/design/classes.md | "The compiler rejects a fork feature" |
| Interfaces and generics | docs/design/generics/overview.md | "The compiler rejects a fork feature" |
| Choice types and match | docs/design/sum_types.md; docs/design/pattern_matching.md | "The compiler rejects a fork feature"; "A function ending in a match needs a return"; "Which toolchain do I need?" |
| Errors as values | docs/design/error_handling.md | "The compiler rejects a fork feature"; "Which toolchain do I need?"; "How is the exit code set?" |
| Calling C++ from Carbon | docs/design/interoperability/README.md | "Compiling a C++ import fails inside libc++"; "Which C++ standard library does Carbon use?" |
| Linking your own C++ library | docs/design/README.md#importing-and-include | "A C++ header is not found"; "C++ objects built with g++ fail to link" |
| Calling Carbon from C++ | docs/design/interoperability/README.md | "Can separately compiled C++ call my Carbon functions?" |
| A multi-file package | docs/design/code_and_name_organization/README.md | "An imported package API is not found"; "The compiler only outputs one of several files" |

**1. Hello, world** (`hello.carbon`; runs on the nightly and the fork):

```carbon
import Cpp library "<iostream>";

fn Run() {
  Cpp.std.cout << "Hello, world!\n";
}
```

What to notice: `Run` is the entry point; `import Cpp library` brings a C++
header in as the package `Cpp`; text goes through C++'s `std::cout` here
because `Core.PrintStr` needs `carbon build` (FAQ).

**2. Values, variables and functions** (`functions.carbon`; both):

```carbon
import Core library "io";

fn Square(x: i32) -> i32 {
  return x * x;
}

fn SumOfSquares(n: i32) -> i32 {
  var total: i32 = 0;
  for (i: i32 in Core.InclusiveRange(1, n)) {
    total += Square(i);
  }
  return total;
}

fn Run() -> i32 {
  let limit: i32 = 4;
  Core.Print(SumOfSquares(limit));

  var countdown: i32 = 3;
  while (countdown > 0) {
    Core.Print(countdown);
    --countdown;
  }

  let parity: i32 = if limit % 2 == 0 then 0 else 1;
  Core.Print(parity);
  Core.Print(if (limit + 1) % 2 == 0 then 0 else 1);
  return 0;
}
```

What to notice: `let` binds an immutable value, `var` a mutable variable, types
follow names; `for` over a range; `if ... then ... else` is an expression,
usable as an initializer, a call argument or a `return` operand, and as another
operator's operand it needs parentheses (if.md:41-45, row 29 of §0.1) (amended
2026-10-13, document-review fold: R2-3), and the two prints take its two arms;
`Run` may return `i32`, which becomes the exit code. (Rev 2 adds the last print
so the program checks both arms; amended 2026-10-13, review fold: A11.)

**3. Classes** (`classes.carbon`; both):

```carbon
import Core library "io";

class Point {
  fn Origin() -> Point {
    return {.x = 0, .y = 0};
  }

  fn Translate(ref self, dx: i32, dy: i32) {
    self.x += dx;
    self.y += dy;
  }

  fn Sum(self) -> i32 {
    return self.x + self.y;
  }

  var x: i32;
  var y: i32;
}

fn Run() -> i32 {
  var p: Point = Point.Origin();
  p.Translate(3, 4);
  Core.Print(p.x);
  Core.Print(p.Sum());
  p.Translate(-1, 2);
  Core.Print(p.Sum());
  return 0;
}
```

What to notice: a function without `self` is called on the class; `ref
self` methods may modify the object; a struct literal initializes the fields.

**4. Interfaces and generics** (`generics.carbon`; both):

```carbon
import Core library "io";

interface Shape {
  fn Area(self) -> i32;
}

class Square {
  var side: i32;
  extend impl as Shape {
    fn Area(self) -> i32 { return self.side * self.side; }
  }
}

class Rectangle {
  var width: i32;
  var height: i32;
  extend impl as Shape {
    fn Area(self) -> i32 { return self.width * self.height; }
  }
}

fn DoubleArea[T: Shape](s: T) -> i32 {
  return 2 * s.Area();
}

class Pair(T: type) {
  var first: T;
  var second: T;
}

fn Run() -> i32 {
  let sq: Square = {.side = 3};
  let rect: Rectangle = {.width = 2, .height = 5};
  Core.Print(DoubleArea(sq));
  Core.Print(DoubleArea(rect));

  let p: Pair(i32) = {.first = sq.Area(), .second = rect.Area()};
  Core.Print(p.first + p.second);
  return 0;
}
```

What to notice: `DoubleArea` is checked once against the `Shape` interface,
not per instantiation (a checked generic); `extend impl` makes the interface's
methods members of the class; `Pair(T)` is a generic class.

**5. Choice types and `match`** (`choice_match.carbon`; **the fork's
toolchain only** — the nightly reports `choice alternatives with parameters
are not yet supported` and `HandleMatchIntroducer`):

```carbon
import Core library "io";

choice Figure {
  Circle(radius: i32),
  Rectangle(width: i32, height: i32),
  Empty
}

// Approximates pi as 3 to stay in integer arithmetic.
fn Area(f: Figure) -> i32 {
  var area: i32 = 0;
  match (f) {
    case .Circle(r: i32) => { area = 3 * r * r; }
    case .Rectangle(w: i32, h: i32) => { area = w * h; }
    case .Empty => { area = 0; }
  }
  return area;
}

fn Describe(n: i32) -> i32 {
  var code: i32 = 0;
  match (n) {
    case 0 => { code = 100; }
    case x: i32 if (x < 0) => { code = 200; }
    default => { code = 300; }
  }
  return code;
}

fn Run() -> i32 {
  Core.Print(Area(Figure.Circle(2)));
  Core.Print(Area(Figure.Rectangle(3, 5)));
  Core.Print(Area(Figure.Empty));
  Core.Print(Describe(0));
  Core.Print(Describe(-4));
  Core.Print(Describe(9));
  return 0;
}
```

What to notice: a `choice` is a sum type whose alternatives may carry values;
`match` destructures them, needs no `default` when every alternative is covered,
runs only the first matching case (no fall-through), and a guard is written `if
(...)`, which the toolchain requires and the design's grammar does not (row 29
of §0.1) (amended 2026-10-13, document-review fold: R2-4). The arms assign and
the function returns once because of a current toolchain limitation, not a
language rule: the toolchain does not yet treat an exhaustive `match` as
returning on every path, though the design does, so without a `default` arm a
function whose arms all return still needs a `return` after the `match` (FAQ;
§0.1 row 14; amended 2026-10-13, review fold: A3; reworded as a toolchain
limitation (amended 2026-10-13, document-review fold: R2-1)).

**6. Errors as values: `Core.Result` and `?`** (`errors.carbon`; **the
fork's toolchain only** — the nightly reports ``member name `Result` not
found in `Core` ``):

```carbon
import Core library "io";

// Returns the quotient, or the dividend as the error when dividing by zero.
fn Divide(a: i32, b: i32) -> Core.Result(i32, i32) {
  if (b == 0) {
    return Core.Result(i32, i32).Err(a);
  }
  return Core.Result(i32, i32).Ok(a / b);
}

// `?` returns early with the error; otherwise it unwraps the value.
fn Average(total: i32, count: i32) -> Core.Result(i32, i32) {
  let mean: i32 = Divide(total, count)?;
  return Core.Result(i32, i32).Ok(mean);
}

fn Report(r: Core.Result(i32, i32)) {
  match (r) {
    case .Ok(v: i32) => { Core.Print(v); }
    case .Err(e: i32) => { Core.Print(-e); }
  }
}

fn Run() -> i32 {
  Report(Average(12, 4));
  Report(Average(7, 0));
  if (let .Ok(v: i32) = Divide(9, 3)) {
    Core.Print(v);
  }
  if (let .Ok(v: i32) = Divide(1, 0)) {
    Core.Print(v);
  } else {
    Core.Print(0);
  }
  return 0;
}
```

What to notice: `Core.Result(T, E)` is a `choice` in the prelude; postfix
`?` propagates the error to the caller; `if (let pattern = value)` runs its
block only when the pattern matches, and its `else` block otherwise (rev 2
adds the second if-let so both paths are checked; amended 2026-10-13, review
fold: A11). One sentence: `Run` may itself return
`Core.Result((), E)`; an error then prints a line to stderr and exits with
code 1 (§0.1 row 14).

**7. Calling C++ from Carbon** (`interop_use_cpp.carbon`; both):

```carbon
import Core library "io";
import Cpp library "<cstdlib>";
import Cpp library "<vector>";
import Cpp inline '''c++
class Counter {
 public:
  Counter(int start) : total_(start) {}
  void Add(int n) { total_ += n; }
  int Total() const { return total_; }

 private:
  int total_;
};

inline std::vector<int> FirstPrimes() { return {2, 3, 5, 7}; }
''';

fn Run() -> i32 {
  // A C++ standard library function.
  Core.Print(Cpp.std.abs(-5));

  // A C++ class: constructor, mutating method, const method.
  var c: Cpp.Counter = Cpp.Counter.Counter(10);
  c.Add(5);
  Core.Print(c.Total());

  // A C++ container, iterated with a Carbon `for` loop.
  var primes: Cpp.std.vector(i32) = Cpp.FirstPrimes();
  var sum: i32 = 0;
  for (p: i32 in primes) {
    sum += p;
  }
  Core.Print(sum);
  return 0;
}
```

What to notice: C++ names live under `Cpp`; C++ `int` is Carbon `i32`; a
constructor is called as `Cpp.Counter.Counter(...)`; a C++ class template is
instantiated with a Carbon type argument; `import Cpp inline` compiles C++
source written in the Carbon file; overload resolution for `std::abs` is
C++'s own. The constructor call, C++ method calls and `import Cpp inline` are
labelled toolchain behavior whose design sections are still placeholders
(row 29 of §0.1) (amended 2026-10-13, document-review fold: R2-4).

**8. Linking your own C++ library** (three files; both toolchains). The page
shows `rectangle.h` and `rectangle.cpp` in `cpp` fenced blocks:

```cpp
#ifndef RECTANGLE_H_
#define RECTANGLE_H_

// Returns the area of a `width` by `height` rectangle.
auto RectangleArea(int width, int height) -> int;

#endif  // RECTANGLE_H_
```

```cpp
#include "rectangle.h"

auto RectangleArea(int width, int height) -> int { return width * height; }
```

then `main.carbon`:

```carbon
import Core library "io";
import Cpp library "rectangle.h";

fn Run() -> i32 {
  Core.Print(Cpp.RectangleArea(6, 7));
  return 0;
}
```

and this build block (measured on F and N, §0.1 row 11):

```shell
carbon clang -- -c rectangle.cpp -o rectangle.o
carbon compile --output=main.o main.carbon
carbon link --output=main main.o rectangle.o
./main
```

What to notice: build the C++ files with `carbon clang` (or the toolchain's
`lib/carbon/llvm/bin/clang++`), because `carbon link` links libc++: C++ code
that uses the standard library and was compiled by `g++` or a system `clang++`
against libstdc++ does not link, though code like `rectangle.cpp` that uses none
of it does (FAQ; §0.1 row 11) (amended 2026-10-13, document-review fold:
MAJOR-3); a quoted header is found relative to the directory the compile runs
in, so build from the directory holding the header or pass `--clang-arg=-I<dir>`
(FAQ). The two `cpp` blocks use the trailing return type of
docs/project/cpp_style_guide.md:108, because the fixtures fall under the
clangd-tidy gate, whose `modernize-use-trailing-return-type` rejects a leading
`int` (§0.1 row 25) (amended 2026-10-13, document-review fold: R2-2). The two
`cpp` blocks and `main.carbon` are also the fixture files
fork/evaluator/cpp_library/rectangle.h, rectangle.cpp and main.carbon, which
fork/evaluator/cpp_library/build.sh builds with these commands; the checker
compares them (D-EV-12, D-EV-13; amended 2026-10-13, review fold: A2). The page
says the fixtures add a license comment and, in the header, the guard name the
header-guard check requires, never that they are the page's files byte for byte
(amended 2026-10-13, document-review fold: B1, R2-6).

**9. Calling Carbon from C++** (`interop_call_carbon.carbon`; both):

```carbon
import Core library "io";
import Cpp;

// Carbon functions that the C++ code below calls.
fn Square(n: i32) -> i32 {
  return n * n;
}

fn Clamp(v: i32, lo: i32, hi: i32) -> i32 {
  if (v < lo) { return lo; }
  if (v > hi) { return hi; }
  return v;
}

// C++ code sees the Carbon functions in the `Carbon` namespace.
inline Cpp '''c++
inline int SumOfSquaresClamped(int n, int lo, int hi) {
  int total = 0;
  for (int i = 1; i <= n; ++i) {
    total += Carbon::Square(i);
  }
  return Carbon::Clamp(total, lo, hi);
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.SumOfSquaresClamped(3, 0, 100));
  Core.Print(Cpp.SumOfSquaresClamped(10, 0, 100));
  Core.Print(Cpp.SumOfSquaresClamped(3, 20, 100));
  return 0;
}
```

What to notice: `import Cpp;` with a later `inline Cpp` block exports the
Carbon functions declared above it into C++'s `Carbon` namespace; C++
compiled separately cannot call Carbon yet, because no header is generated
(FAQ). The three calls reach Clamp's three arms: in range, above `hi`, below
`lo` (rev 2; amended 2026-10-13, review fold: A11). The `inline Cpp` block
and its declared-above rule are labelled toolchain behavior that no design
document describes yet (row 29 of §0.1) (amended 2026-10-13, document-review
fold: R2-4).

**10. A multi-file package** (three files; both). `geometry.carbon`:

```carbon
package Geometry;

// The API file: the declarations that importers of `Geometry` can use.

class Rect {
  var width: i32;
  var height: i32;
}

fn Area(r: Rect) -> i32;
fn Perimeter(r: Rect) -> i32;
```

`geometry.impl.carbon`:

```carbon
impl package Geometry;

// The implementation file: it sees the API file's declarations implicitly.

fn Area(r: Rect) -> i32 {
  return r.width * r.height;
}

fn Perimeter(r: Rect) -> i32 {
  return 2 * (r.width + r.height);
}
```

`main.carbon`:

```carbon
import Core library "io";
import Geometry;

fn Run() -> i32 {
  let r: Geometry.Rect = {.width = 3, .height = 4};
  Core.Print(Geometry.Area(r));
  Core.Print(Geometry.Perimeter(r));
  return 0;
}
```

and the build block (measured on F and N, §0.1 row 13):

```shell
carbon compile --output=geometry.o geometry.carbon
carbon compile --output-last-input-only --output=geometry.impl.o geometry.carbon geometry.impl.carbon
carbon compile --output-last-input-only --output=main.o geometry.carbon main.carbon
carbon link --output=shapes geometry.o geometry.impl.o main.o
./shapes
```

What to notice: a file that imports or implements a package is compiled
together with that package's API file, and `--output-last-input-only`
writes only the last file's object (the toolchain does not yet compile
files separately); `carbon build -o=shapes main.carbon geometry.carbon
geometry.impl.carbon` does the same in one step.

**"Where next"** — docs/design/README.md, the evaluator FAQ, and
fork/gap-analysis.md plus fork/conformance/README.md for what this fork
implements and how it is tested.

### §2.C docs/guides/evaluator_faq.md (new, about 300 lines)

Title "Evaluator FAQ and troubleshooting". The introduction names its scope
(using the toolchain) and links docs/project/faq.md for questions about the
project. Every diagnostic-keyed entry quotes the diagnostic in a `text`
fenced block and gives the fix in prose; no `carbon` fenced blocks (the
checker's table has 0 for this page; fixes point at the tutorial's samples).
The heading tree is fixed, H2 groups and H3 entries with exactly these titles,
plain words only (R-4), so the tutorial's links, D-EV-10's state C links and
faq.md's pointer have stable anchors (amended 2026-10-13, review fold: B m-1):

| H2 group | H3 entry (exact title) | Answer essentials | Evidence |
| --- | --- | --- | --- |
| Choosing and installing a toolchain | Which toolchain do I need? | nightly 2026.10.12 ran every tutorial section except "Choice types and match" and "Errors as values" (measured; a later nightly is re-measured by §8.3 and the land sequence, D-EV-2), and those two need the fork's (amended 2026-10-13, review fold: A12); the diagnostics the nightly prints for them; the entry links "this fork's toolchain" to getting_started.md's build section (amended 2026-10-13, document-review fold: MINOR-1a) | §0.1 rows 9-10 |
| Choosing and installing a toolchain | Can I download a prebuilt fork toolchain? | not a current one: the `fork-toolchain-*` prereleases on the fork's releases page predate `Core.Result`, if-let, unions, `overload fn` and slices, and the newest stops on Ubuntu 24.04 with the quoted ``version `GLIBC_2.44' not found`` line; build from source (W-152) (amended 2026-10-13, review fold: B-6); the entry also names the page's newest entry, `arbiter-v0.0.0-0.nightly.2026.09.28`, a mirror of upstream's nightly of 2026-09-28 and not this fork's toolchain (amended 2026-10-13, document-review fold: MINOR-7, R2-7), and says W-152 is tracked in the work-item ledger, linked (amended 2026-10-13, document-review fold: MINOR-8) | §0.1 row 17 |
| Choosing and installing a toolchain | Which platforms are supported? | the platform table's summary with its labelled sources; macOS unverified for this fork's current trunk (W-153); Windows unsupported, with the quoted `-fPIE` line from cross-targeting; WSL 2 (amended 2026-10-13, review fold: A1); the Linux x86-64 sentence says the fork toolchain measured is a CMake build on that machine and the guide's Bazel route was not run (amended 2026-10-13, document-review fold: R2-9), and "no prebuilt toolchain" cites upstream's release configuration (amended 2026-10-13, document-review fold: MINOR-4) | §0.1 rows 15-16, 26; D-EV-3 |
| Choosing and installing a toolchain | What system packages do I need? | glibc development files for compiling C++ imports and for linking; libc6-dev; the README's libgcc line; other distributions unverified; the `mbstate_t` and `cannot open Scrt1.o` texts, labelled as measured with an empty sysroot (amended 2026-10-13, review fold: A5, B m-4); the other distributions' names appear in the entry itself, labelled not verified, beside the link to the table (amended 2026-10-13, document-review fold: MINOR-1b) | §0.1 rows 4-6 |
| Choosing and installing a toolchain | The download fails, or tar says the file is not in gzip format | no release for that date: `wget`'s `ERROR 404: Not Found.`; `curl` without `-f` saves the "Not Found" page and `tar` then reports `gzip: stdin: not in gzip format`; pick a date from the releases page (amended 2026-10-13, review fold: B-5) | §0.1 row 27 |
| Choosing and installing a toolchain | Why is the first link slow, and where is the cache? | runtimes build, about 20 seconds idle and longer under load (§2.A item 7's measured range), cache location, `--runtimes-cache`, `build-runtimes`, `--prebuilt-runtimes` (amended 2026-10-13, review fold: A6); when every link is slow the cache's parent directory is missing, fixed by `mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"` (§0.1 row 3) (amended 2026-10-13, document-review fold: MINOR-5) | §0.1 rows 2-3 |
| Building programs | Linking fails with an undefined symbol in Core | `link` adds only the prelude objects; use `carbon build`, or print through `Core.Print` or C++; state C links build_systems.md's "Core libraries" (D-EV-7) | §0.1 row 8 |
| Building programs | A C++ header is not found | quoted headers resolve against the working directory; `--clang-arg=-I<dir>` | §0.1 row 12 |
| Building programs | An imported package API is not found | compile each file with its package's API file and `--output-last-input-only`, or `carbon build`; state C links build_systems.md | §0.1 row 13 |
| Building programs | The compiler only outputs one of several files | the `warning: only outputting ...` line; the same flag | §0.1 row 13 |
| Building programs | C++ objects built with g++ fail to link | both measurements: C-ABI code from g++ or the system clang++ links; code that uses the C++ standard library does not (`undefined symbol: std::__cxx11::...`), because `carbon link` links libc++; compile it with `carbon clang`, or pass libstdc++ by path after `--` with the caveat that no standard-library object may cross between the two libraries; state C cites W-131 and links build_systems.md's "Mixed Carbon and C++" (amended 2026-10-13, review fold: A9, B m-2); the libstdc++-by-path link and the toolchain's `clang++` are both labelled measured on both toolchains (§0.1 row 11) (amended 2026-10-13, document-review fold: MINOR-6) | §0.1 row 11 |
| Building programs | A function ending in a match needs a return | a `match` with no `default` arm, even an exhaustive one, is not treated as returning on every path; add a `default` arm or a `return` after the `match`, or assign in the arms and return once (tutorial section "Choice types and match") (amended 2026-10-13, review fold: A3); the entry calls this a current toolchain limitation, not a language rule, and links pattern_matching.md's exhaustiveness section, which treats code after an exhaustive match as unreachable, and error_handling.md's `Core.Try` section, which records the limitation (§0.1 row 14) (amended 2026-10-13, document-review fold: R2-1) | §0.1 row 14 |
| Building programs | The compiler rejects a fork feature | the seven measured nightly diagnostics (`semantics TODO: ...`, ``member name `Result` not found in `Core` ``, ``member name `Slice` ...``, `unrecognized declaration introducer`, `expected expression`); the feature needs this fork's toolchain, and a fork toolchain built before a27059915 (2026-09-27) also lacks `Core.Result` (amended 2026-10-13, review fold: B-6, B m-4); "Use this fork's toolchain" links getting_started.md's build section (amended 2026-10-13, document-review fold: MINOR-1a) | §0.1 rows 9, 17 |
| Building programs | Compiling a C++ import fails inside libc++ | the `mbstate_t` line first: the C library headers are missing; install libc6-dev (amended 2026-10-13, review fold: A5) | §0.1 row 6 |
| Building programs | The main file's package declaration is rejected | the main file has no package declaration | §0.1 row 14 |
| Building programs | The short output flag needs an equals sign | `carbon build -o FILE` fails with the quoted line; write `-o=FILE`; state C cites W-133 | §0.1 row 7 |
| Building programs | How is the exit code set? | `Run` returning `i32`; `Run` returning `Core.Result((), E)` on the fork's toolchain (stderr line, exit 1) | §0.1 row 14 |
| Language and interop | Can separately compiled C++ call my Carbon functions? | not yet: no header is generated; C++ written in the Carbon file (`inline Cpp`) can (tutorial section "Calling Carbon from C++") | §0.1 row 21 |
| Language and interop | Which C++ standard library does Carbon use? | libc++, built into the runtimes cache; `<carbon/expected.h>` in the fork's tree | §0.1 rows 1, 4 |
| Language and interop | What is implemented, and what is only designed? | fork/gap-analysis.md per-bullet table, fork/conformance/README.md program table, the design docs' own placeholder notes | gap-analysis.md:34-91 |
| Language and interop | Can I try Carbon in a browser? | README.md:275-276, upstream's toolchain only, so none of the fork's features (inferred, not measured; amended 2026-10-13, review fold: B m-4) | §0.1 row 19 |
| Questions about the project | (H2 only, no H3) | links to docs/project/faq.md anchors: status, interop, generics, where to ask | §0.3 |

**Reproducers** (amended 2026-10-13, review fold: A3, A4, A5). Every quoted
diagnostic has one; fork/evaluator/check_faq.py (D-EV-21) writes the input, runs
the command in a fresh temporary directory with the toolchain it is given
(`{c}`), and requires the expected line as the suffix of an output line (so a
file's `path:line:col:` prefix does not matter), the exit status, and the same
line inside a `text` block of the page, compared as a whole line (amended
2026-10-13, document-review fold: R2-5); it also requires every line of a `text`
block of getting_started.md other than program output to be a line of a `text`
block of the FAQ, so the guide's repeated quotes cannot drift from the FAQ's
(amended 2026-10-13, document-review fold: MINOR-9). `p.carbon` holds the
one-line input shown; "package" is the tutorial's three package files; `empty`
is an empty directory; "both" means F and N. All twenty were measured on
2026-10-13 (§0.1 row 28: 13 run on F, 17 on N, no mismatch).

| Id | FAQ entry | Input | Command | Runs on | Expected line | Exit |
| --- | --- | --- | --- | --- | --- | --- |
| printstr | Linking fails with an undefined symbol in Core | `import Core library "io"; fn Run() { Core.PrintStr("Hello, world!\n"); }` | compile, link, run | both | `ld.lld: error: undefined symbol: _CPrintStr.Core` | 1 |
| header | A C++ header is not found | `sub/seven.h`: `int Seven();`; `sub/main.carbon`: `import Cpp library "seven.h"; fn Run() -> i32 { return Cpp.Seven(); }` | `{c} compile --output=main.o sub/main.carbon` | both | `error: 'seven.h' file not found` | 1 |
| no-api | An imported package API is not found | package | `{c} compile --output=main.o main.carbon` | both | `error: imported API 'Geometry' not found` | 1 |
| one-output | The compiler only outputs one of several files | package | `{c} compile --output=y.o geometry.carbon geometry.impl.carbon main.carbon` | both | ``warning: only outputting main.carbon to y.o, skipping output of 2 input files; pass `--output-last-input-only` to silence this warning`` | 0 |
| gxx-object | C++ objects built with g++ fail to link | `strlib.h`: `int RepeatLength(int n);`; `strlib.cpp`: includes `<string>` and `"strlib.h"`, `RepeatLength` appends `n` characters to a `std::string` and returns its size; `main.carbon`: `import Core library "io"; import Cpp library "strlib.h"; fn Run() { Core.Print(Cpp.RepeatLength(10)); }` | `g++ -c strlib.cpp -o strlib.o`, then compile and link (skipped without g++) | both | `ld.lld: error: undefined symbol: std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char>>::basic_string()` | 1 |
| match-return | A function ending in a match needs a return | `choice Side { Left, Right } fn Sign(s: Side) -> i32 { match (s) { case .Left => { return -1; } case .Right => { return 1; } } } fn Run() -> i32 { return Sign(Side.Right); }` | compile | F | ``error: missing `return` at end of function with declared return type`` | 1 |
| match-default | A function ending in a match needs a return | `fn Pick(n: i32) -> i32 { match (n) { case 0 => { return 1; } default => { return 2; } } } fn Run() -> i32 { return Pick(0); }` | compile, link, run | F | (none: compiles, links, runs) | 1 |
| choice-payload | The compiler rejects a fork feature | `choice C { A(x: i32), B } fn Run() {}` | compile | N | ``error: semantics TODO: `choice alternatives with parameters are not yet supported` `` | 1 |
| match | The compiler rejects a fork feature | `fn Run() -> i32 { match (1) { default => { return 0; } } return 0; }` | compile | N | ``error: semantics TODO: `HandleMatchIntroducer` `` | 1 |
| result | The compiler rejects a fork feature | `fn Run() -> Core.Result((), i32) { return Core.Result((), i32).Ok(()); }` | compile | N | ``error: member name `Result` not found in `Core` `` | 1 |
| if-let | The compiler rejects a fork feature | `fn Run() -> i32 { if (let v: i32 = 3) { return v; } return 0; }` | compile | N | `error: expected expression` | 1 |
| union | The compiler rejects a fork feature | `union U { var a: i32; var b: i32; } fn Run() {}` | compile | N | `error: unrecognized declaration introducer` | 1 |
| overload | The compiler rejects a fork feature | `overload fn F(unused n: i32) -> i32 { return 1; } overload fn F(unused b: bool) -> i32 { return 2; } fn Run() -> i32 { return F(true); }` | compile | N | `error: unrecognized declaration introducer` | 1 |
| slice | The compiler rejects a fork feature | `fn Run() -> i32 { var a: array(i32, 2) = (3, 4); let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a); return s[0]; }` | compile | N | ``error: member name `Slice` not found in `Core` `` | 1 |
| package-main | The main file's package declaration is rejected | `package Main; fn Run() {}` | compile | both | ``error: `Main//default` must omit `package` declaration`` | 1 |
| result-exit | How is the exit code set? | `fn Run() -> Core.Result((), i32) { return Core.Result((), i32).Err(7); }` | compile, link, run | F | ``carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1`` | 1 |
| no-c-headers | Compiling a C++ import fails inside libc++; What system packages do I need? | the tutorial's hello sample | `{c} compile --output=p.o p.carbon -- --sysroot=empty` | both | `error: "We don't know how to get the definition of mbstate_t on your platform."` | 1 |
| no-start-files | What system packages do I need? | the README's forty_two line | compile, then `{c} link --output=p p.o -- --sysroot=empty` | both | `ld.lld: error: cannot open Scrt1.o: No such file or directory` | 1 |
| short-o | The short output flag needs an equals sign | the README's forty_two line | `{c} build -o p p.carbon` | both | ``error: option `-o` (short for `--output`) requires a value to be provided and none was`` | 1 |
| windows-target | Which platforms are supported? | the README's forty_two line | `{c} compile --target=x86_64-pc-windows-msvc --output=p.o p.carbon` | both | `error: unsupported option '-fPIE' for target 'x86_64-pc-windows-msvc'` | 1 |

Two quoted texts have no reproducer in check_faq.py, because they need the
network or a second toolchain, and are re-run by hand at commit 1 (§8.3):
the download failures of §0.1 row 27 and the prerelease's GLIBC_2.44 loader
line of §0.1 row 17.

### §2.D Index and pointers (three upstream-owned files)

1.  **docs/guides/README.md** — after :10, three list items ahead of the
    glossary: `[Getting started](getting_started.md)`,
    `[Tutorial](tutorial.md)`, `[Evaluator FAQ](evaluator_faq.md)`. Dash
    items 1 → 4.
2.  **README.md** — a new paragraph after :276, and a list item after :362 (dash
    items 75 → 76; headings unchanged). The paragraph names no platform the
    guide has not measured; rev 1's "covers other Linux distributions and macOS"
    is withdrawn (amended 2026-10-13, review fold: A1, B m-4):

    ```markdown
    For a step-by-step guide to installing a toolchain on Linux x86-64, the
    status of other platforms, the toolchain this fork's features need, and
    a tutorial through C++ interop, see the
    [getting started guide](/docs/guides/getting_started.md).
    ```

    ```markdown
    -   [Guides: getting started, tutorial, evaluator FAQ](/docs/guides/README.md)
    ```

3.  **docs/project/faq.md** — the answer at :109-110 gains one sentence
    (counts unchanged):

    ```markdown
    For a step-by-step guide and a tutorial, see
    [getting started](/docs/guides/getting_started.md).
    ```

### §2.E Conformance programs, fixtures and the two checkers

1.  **Nine single-file programs** under fork/conformance/programs/project/, each
    `<license>` + blank + this header + blank + the §2.B sample verbatim:

    ```carbon
    // CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
    // EXPECT-EXIT: 0
    // EXPECT-STDOUT:
    //   <the §4 lines, one per line>
    //
    // Transcribed from docs/guides/tutorial.md, section "<section>": the
    // code after this comment block is that page's code block byte for
    // byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
    // derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
    // on <the upstream nightly and this fork's toolchain | this fork's
    // toolchain only (the upstream nightly rejects it)>.
    ```

    `<section>` is the tutorial's H2 title exactly, never a shortened form
    (amended 2026-10-13, review fold: B m-1): `evaluator_tutorial_hello` "Hello,
    world"; `_functions` "Values, variables and functions"; `_classes`
    "Classes"; `_generics` "Interfaces and generics"; `_choice_match` "Choice
    types and match" (fork only); `_errors` "Errors as values" (fork only);
    `_interop_use_cpp` "Calling C++ from Carbon"; `_cpp_library` "Linking your
    own C++ library" (item 2); `_interop_call_carbon` "Calling Carbon from C++";
    each `.carbon`. The package's `main.carbon` takes "A multi-file package"
    (item 3).
2.  **The C++-library sample: fixtures, script and program** (amended
    2026-10-13, review fold: A2, A12, B-1). Commit 2 writes, in both states, the
    directory fork/evaluator/cpp_library/: `rectangle.h` and `rectangle.cpp`
    (the license header, a blank line, then §2.B's two `cpp` blocks, except that
    the header guard is the one the check-header-guards hook imposes,
    `CARBON_FORK_EVALUATOR_CPP_LIBRARY_RECTANGLE_H_`, §0.1 row 25),
    `main.carbon` (the license header, a blank line, then §2.B's `main.carbon`
    block) and this script, executable:

    ```shell
    #!/usr/bin/env bash
    #
    # Part of the Carbon Language project, under the Apache License v2.0 with LLVM
    # Exceptions. See /LICENSE for license information.
    # SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
    #
    # Builds and runs the "Linking your own C++ library" sample of
    # docs/guides/tutorial.md with that section's commands, for the conformance
    # runner's BUILD-SCRIPT channel (fork/conformance/README.md). It runs from
    # this directory, because `import Cpp library "rectangle.h"` resolves the
    # quoted header against the working directory, and writes only into
    # CARBON_BUILD_DIR. stdout is the program's output; build messages go to
    # stderr. Exit codes: 2 compile failed, 3 link failed, otherwise the
    # program's own.

    set -euo pipefail

    cd "$(dirname "${BASH_SOURCE[0]}")"
    carbon="${CARBON:-carbon}"
    out="${CARBON_BUILD_DIR:?CARBON_BUILD_DIR is not set}"
    mkdir -p "$out"

    "$carbon" clang -- -c rectangle.cpp -o "$out/rectangle.o" >&2 || exit 2
    "$carbon" compile --output="$out/main.o" main.carbon >&2 || exit 2
    "$carbon" link --output="$out/main" "$out/main.o" "$out/rectangle.o" >&2 ||
      exit 3
    exec "$out/main"
    ```

    The program `project/evaluator_tutorial_cpp_library.carbon` is item 1's
    header with EXPECT `42` and these four lines after the provenance comment,
    which name the script in both states:

    ```carbon
    // fork/evaluator/cpp_library/build.sh builds this body's
    // byte-identical copy fork/evaluator/cpp_library/main.carbon with
    // rectangle.cpp by the section's commands; the runner never
    // compiles this file itself.
    ```

    **State C** adds `// BUILD-SCRIPT: fork/evaluator/cpp_library/build.sh`
    directly after the bullet line, and the program PASSes (§0.1 row 25).
    **State T** instead carries this SKIP line directly after its `//   42`
    line, which cites §0.1 row 11 for the by-hand run (A12) and names the
    mechanical un-SKIP:

    ```carbon
    // SKIP: harness limitation, not a documentation gap: this sample links a separately compiled C++ unit (rectangle.cpp, built by `carbon clang -- -c`) beside the Carbon object, and this trunk's runner.py builds only Carbon units (execute_program issues `carbon compile` at runner.py:516-524 and `carbon link` over those objects at :546-551; a multi-unit directory takes *.carbon only, :321) and runs every command without a working directory (run_cmd, :453-462); and `import Cpp library "rectangle.h"` resolves the quoted header against the working directory, not the importing file's directory (measured: the same compile run from another directory fails with `'rectangle.h' file not found`), so no COMPILE-ARGS include path is independent of where the runner is started. The tutorial's commands print 42 and exit 0 by hand on 0.0.0-0.dev+0bdce60a5 and on 0.0.0-0.nightly.2026.10.12+62f1cc6 (fork/evaluator/plan.md section 0.1 row 11), and fork/evaluator/cpp_library/build.sh, which runs them, PASSes under CM-1's BUILD-SCRIPT channel (PR 52; plan section 0.1 row 25). Un-SKIP mechanically once PR 52 is on trunk: add `// BUILD-SCRIPT: fork/evaluator/cpp_library/build.sh` under the bullet line and delete this SKIP line (W-154, reserved, is filed only if this program must merge before PR 52).
    ```

    The integration commit's un-SKIP is exactly: delete the SKIP line, add the
    BUILD-SCRIPT line after the bullet line (measured to reproduce the state C
    program byte for byte, §0.1 row 25). Before any state T commit, re-open
    runner.py and re-pin the SKIP text's line numbers; the integration commit
    deletes them with the line.
3.  **The package directory** `project/evaluator_tutorial_package/`:
    `geometry.carbon` and `geometry.impl.carbon` are `<license>` + blank +
    the sample verbatim (no directives: the runner rejects directives
    outside main.carbon); `main.carbon` carries the header of item 1 with
    section "A multi-file package" and EXPECT `12`, `14`. The runner
    compiles each unit with all of its siblings and
    `--output-last-input-only` (runner.py:516-524): the tutorial's commands
    plus the remaining sibling units, two for the API file and one for each
    other unit; the objects are byte-identical to the tutorial's for all
    three units on F and N (`cmp`, §0.1 row 13; amended 2026-10-13, review
    fold: A12, B m-3).
4.  **fork/evaluator/check_samples.py** (new, about 210 lines, stdlib only,
    `__copyright__` block as upstream's Python, not executable, run as
    `python3 fork/evaluator/check_samples.py` from the repository root, and
    importable: `main()` returns the exit status; amended 2026-10-13, review
    fold: A10, B-3, B m-1). `SAMPLES` maps `docs/guides/tutorial.md` to the
    twelve program paths in page order (the nine files of item 1 with the
    C++-library one eighth, then the package's `geometry.carbon`,
    `geometry.impl.carbon`, `main.carbon`) and the two other pages to empty
    lists; `CPP_SAMPLES` is `rectangle.h`, `rectangle.cpp`. `fenced_blocks()`
    returns every fenced block's line, language, body and enclosing H2
    title. `main()` reports, each as an error: an indented fence of any
    language on the three pages; a `carbon` block count other than the
    table's; a `carbon` block that differs from its program after the
    program's leading comment block (a unified diff); a tutorial H2 section
    holding `carbon` blocks without exactly one `text` block, or whose
    `text` block differs from the EXPECT-STDOUT lines of the program of the
    section's last `carbon` block; a `cpp` block count other than two, or a
    `cpp` block that differs from its fixture after the fixture's leading
    comment block, reading `CARBON_FORK_EVALUATOR_CPP_LIBRARY_RECTANGLE_H_`
    as `RECTANGLE_H_`; a C++-library program body that differs from the
    fixture `main.carbon`'s; a missing forty_two echo line in README.md or
    getting_started.md; and a getting-started program body other than what
    the echo writes. The two literals:

    ```python
    FORTY_TWO_ECHO = (
        'echo "import Core library \\"io\\"; fn Run() { Core.Print(42); }"'
        " > forty_two.carbon"
    )
    FORTY_TWO_BODY = 'import Core library "io"; fn Run() { Core.Print(42); }\n'
    ```

    It prints `check_samples: N samples, M errors` (N counts the twelve
    `carbon` and two `cpp` blocks) and exits 1 on any error. **State C**
    adds to runner.py, beside PR 52's build-script self-check in
    `self_test()`, a call `evaluator_samples_self_check()` that loads the
    script with `importlib.util.spec_from_file_location`, runs `main()` and
    prints `evaluator-samples self-check: OK` or `ERRORS`; it runs only
    when `--self-test` has no filter (§0.1 row 23). The prototype is
    `ev1/fix/proto/fork/evaluator/check_samples.py` in the scratchpad
    (ruff-clean); the implementer starts from it.
5.  **fork/evaluator/check_faq.py** (new, about 330 lines, stdlib only, same
    conventions; amended 2026-10-13, review fold: A4). `REPRODUCERS` is §2.C's
    reproducer table; `--toolchain PATH` (the `carbon` binary or busybox) and
    `--which fork|nightly` select the rows to run; each row runs in a fresh
    temporary directory holding an `empty` subdirectory; a row whose command
    starts with `g++` is reported as skipped when `g++` is not on `PATH`. It
    reports a quoted line that is not a whole line of a `text` block of
    evaluator_faq.md (amended 2026-10-13, document-review fold: R2-5), a line of
    a `text` block of getting_started.md that is neither program output
    (`GUIDE_OUTPUT`: `42` and the version-shape line) nor such a FAQ line
    (amended 2026-10-13, document-review fold: MINOR-9), an expected line that
    no output line ends with, and an exit status other than the table's, prints
    `check_faq: N reproducers run, M errors` and exits 1 on any error. The
    prototype is `ev1/fix/proto/fork/evaluator/check_faq.py` (ruff-clean; 13
    rows run on F, 17 on N, no error, §0.1 row 28).
6.  **project/evaluator_docs_review.carbon** — deleted.
7.  **project/evaluator_docs_getting_started.carbon** — header lines 9-19
    rewritten: the program is the echo line that README.md "Getting
    started" and docs/guides/getting_started.md "Your first program" both
    show (the checker enforces the match); the dangling "see
    evaluator_docs_review.carbon" goes; the tutorial's samples are the
    `project/evaluator_tutorial_*` programs. Directives and body unchanged.
8.  **fork/conformance/README.md** — the program table regenerated by
    `--update-readme-table`: the `evaluator_docs_review.carbon` row goes and
    ten rows come (§0.1 row 23: nine single-file rows, the C++-library one
    `SKIP` in state T and `external-build` in state C, and
    `project/evaluator_tutorial_package` as `multi-unit (3 units)`). No
    prose change.

### §2.F Records (fork/)

1.  **fork/gap-analysis.md** — row 90 per §5.3; bullet strings untouched
    (R7). Header and §W11 texts are given for both states (amended
    2026-10-13, review fold: B m-1):
    -   **State T, commit 3** (trunk 80a11e7f0, header :18-30): the first
        line becomes "**31 DONE / 20 PARTIAL / 4 MISSING / 1 DESIGN-ONLY**
        across 56 milestone"; the parenthetical opens "bullets (row 90
        PARTIAL → DONE 2026-10-DD on transcription plus document review,
        EV-1 / W-062, with the expected conformance scoreboard 137 PASS / 0
        FAIL / 22 SKIP over 159 programs, 48/56 bullets PASS, stated as
        expected, not of record (Actions disabled); reconciled 2026-10-05
        against the conformance scoreboard —" and continues unchanged;
        :29-30's "leaving variadics and the build-system/documentation rows
        as the open back half" becomes "leaving variadics and the
        build-system rows as the open back half". §W11 (:265-273): the
        sentence "Evaluator docs are thin (glossary only in docs/guides)."
        becomes "The evaluator guides LANDED with EV-1
        (fork/evaluator/plan.md, 2026-10-DD): docs/guides/getting_started.md,
        docs/guides/tutorial.md and docs/guides/evaluator_faq.md."; the
        arbiter's last sentence gains, before its period, " (met at EV-1:
        docs/guides/tutorial.md, its samples transcribed into
        project/evaluator_tutorial_*, PASS locally, not of record until a
        hosted run; the fork's build-from-source block is quoted from the
        hosted job, not run)".
    -   **State C, integration commit** (a header that already carries PR 53's
        row-89 clause and PR 52's expected-scoreboard parenthetical): counts
        DONE +1 and PARTIAL −1 (33 / 20 / 2 / 1 becomes 34 / 19 / 2 / 1 when PRs
        51, 52 and 53 have all merged); the clause "row 90 PARTIAL → DONE
        2026-10-DD on transcription plus document review, EV-1 / W-062;" goes
        directly after "bullets (", where SAFE-1 put its row-89 clause
        (/home/user/carbon-safe fork/gap-analysis.md:21); the expected
        scoreboard the parenthetical quotes becomes the §5.1 state C figure
        ("143 PASS / 0 FAIL / 16 SKIP over 159 programs, 49/56 bullets PASS,
        stated as expected, not of record (Actions disabled)" on the 133 / 0 /
        17 base); CM-1's "leaving variadics, Windows and the
        evaluator-documentation row as the open back half"
        (/home/user/carbon-cmake fork/gap-analysis.md:30-31) becomes "leaving
        variadics and Windows as the open back half". In CM-1's §W11 (:266-282
        there, the sentence at :273-275), "Evaluator docs remain thin (the
        glossary and the build-systems guide in docs/guides): the
        getting-started tutorial is W-062 and stays open." becomes "The
        evaluator guides LANDED with EV-1 (fork/evaluator/plan.md, 2026-10-DD):
        docs/guides/getting_started.md, tutorial.md and evaluator_faq.md beside
        the build-systems guide; W-062 is discharged." and "(W-062, open)."
        becomes "(met at EV-1, W-062 discharged: docs/guides/tutorial.md, its
        samples transcribed into project/evaluator_tutorial_*, ten PASS locally,
        not of record until a hosted run; the fork's build-from-source block is
        quoted from the hosted job, not run)."
    -   **Both states:** the area summary (:535-537 on trunk) becomes
        "Evaluator documentation landed at EV-1: docs/guides holds a
        getting-started guide, a tutorial whose samples are conformance
        programs, and an evaluator FAQ beside the project FAQ;
        toolchain/docs/driver.md remains a developer stub."
2.  **fork/inventory/work-items.json** — W-062: notes prefixed
    "DISCHARGED (fork/evaluator/plan.md EV-1, 2026-10-DD; branch
    claude/carbon-fork-0-1-ev; commits <shas>): ..." with the §0.2 item 3
    correction; evidence re-pinned to the three pages,
    `fork/gap-analysis.md:90`, `:261-273` and
    `fork/conformance/programs/project/evaluator_tutorial_hello.carbon:5`;
    title unchanged. W-002 notes gain §0.2 item 9's sentence (in state C:
    "answered for the C++-library tutorial program by the BUILD-SCRIPT
    channel"); W-059 notes gain §0.1 row 15's cross-target measurement;
    W-003 notes gain "the evaluator guides teach `carbon build` and
    `Core.Print` around it (docs/guides/evaluator_faq.md)"; W-026 (OV-3)
    notes gain "macOS failure of export/overload_set.carbon filed as
    W-153". In state C, W-131's notes gain EV-1's measurement that C-ABI
    objects from g++ link (§0.1 row 11) and W-133's notes a pointer to the
    FAQ entry "The short output flag needs an equals sign" (amended
    2026-10-13, review fold: A1, A9, B m-2). New items from the reserved
    block (D-EV-18), each with `blocked_by` empty (the field takes W-, F-,
    SF- or upstream-issue ids only, work-items.json `source`; PR and
    Actions dependencies go in the notes) and a note naming its break
    condition (amended 2026-10-13, review fold: B m-1, A8, B-2):
    -   **W-152** — kind infra, subsystem "ci/releases + fork process", size S,
        bullet "Project: basic evaluator documentation (getting started to
        FAQs)", title "EV-1 residue: no current downloadable fork toolchain —
        the fork-toolchain-* prereleases (newest fork-toolchain-143-ea02513be,
        2026-09-25) predate Core.Result, if-let, unions, overload fn and slices,
        and the newest needs glibc 2.44 to start"; evidence §0.1 row 17's facts,
        the mirrored upstream nightly `arbiter-v0.0.0-0.nightly.2026.09.28`
        above the prereleases included (amended 2026-10-13, document-review
        fold: R2-7); notes: a refresh needs a Bazel build of record (Actions
        disabled since 2026-10-08, R28), and retiring or relabelling the stale
        prereleases is part of it.
    -   **W-153** — kind fail-test, subsystem
        "toolchain/check/testdata/interop/cpp/function/export (macOS)",
        size S, bullet "Functions: function overloading (Carbon-native)",
        title "OV-3 residue found by EV-1:
        export/overload_set.carbon fails on macos-14 — Carbon `i64`
        exports as `long long` on Darwin, so `Carbon::F(7L)` is ambiguous
        between the `i64` and `bool` members; the golden encodes the Linux
        LP64 mapping"; evidence runs 37359728074 and 37398447710 (macos-14
        Test (Opt) `file_test` FAILED, `install_test` PASSED) and
        overload_set.carbon:35-41; notes: cross-reference W-026 and the
        platform bullet "Project: installs on Windows, macOS, and Linux and
        builds working programs".
    -   **W-154** — filed only if EV-1 merges in state T (D-EV-12): kind
        infra, subsystem "fork/conformance + docs/guides", size S, title
        "EV-1 residue: merged before PR 52 — the C++-library tutorial
        program stays SKIP, check_samples.py is not in --self-test, and the
        guides do not link build_systems.md (fork/evaluator/plan.md §3's
        integration commit)"; with PR 52 abandoned, the title names a
        runner channel for C++ units run from the program directory
        instead.
    -   **W-155 to W-159** — filed only for document-review friction that
        commit 2a does not fix (D-EV-19), in report order, each titled by
        the failing step. Commit 2a leaves one, so commit 3 files W-155:
        kind missing-feature, subsystem "toolchain/check", size S, bullet
        "Control flow: matching — good switch equivalents", title "EV-1
        residue found by document review 2: function-end reachability does
        not consult match exhaustiveness — a function whose exhaustive
        `match` has no `default` arm and returns in every arm still needs a
        trailing `return`, code that pattern_matching.md:612-617 designs as
        unreachable"; evidence docs/design/error_handling.md:350-353 (the
        design's own record of the gap), §0.1 row 14 and the reproducer
        `match-return` of §2.C; notes: the guides call it a toolchain
        limitation, and W-073's trailing-return idiom is the same gap seen
        from the `Try` sketches. W-156 to W-159 stay reserved and unused
        (amended 2026-10-13, document-review fold: R2-1).

    Reserved ids that go unused are listed in the `source` note as
    "reserved by EV-1, unused". The `source` field gains "Updated
    2026-10-DD by the EV-1 discharge: ...". No license header (JSON);
    prettier-clean.
3.  **fork/decision-log.md** — `### EV-1: evaluator documentation: getting
    started, tutorial, FAQ, transcribed programs (2026-10-DD)` inserted
    above the newest workstream entry of the landed region (on 80a11e7f0
    that is "### SL-2: ..." at :2863; above CM-1's or SAFE-1's if either
    has merged). Shape of SL-2 and CM-1: opening paragraph (bullet, row 90,
    header before and after, the expected scoreboard "stated as expected,
    not of record", what the new programs are — documentation-sync programs
    under a bullet that was already PASS, checked by the evaluator-samples
    self-check in state C — branch and commits; amended 2026-10-13, review
    fold: B-3); WHAT LANDED by file group; the DECISIONS D-EV-1..21 with
    break conditions in one sentence each; REVIEWS (the two plan reviews,
    the two document reviews and the implementation review, each with its
    fold); VERIFICATION (what ran and what could not, D-EV-17, including
    that the fork build-from-source block is quoted from
    fork_hosted.yaml:106-120 and not run; amended 2026-10-13, review fold:
    B-4); RESIDUE (W-152 and W-153, any of W-154 to W-159 filed, the
    reserved-unused ids, and in state C the cross-references to PR 52's
    W-131 and W-133; amended 2026-10-13, review fold: A9); PLAN §0.2
    CORRECTIONS (items 1-10); the italic V-3a paragraph (the three guide
    pages are fork-local in an upstream directory; README.md's two pointer
    lines, faq.md's one sentence and docs/guides/README.md's three list
    items are the only upstream-owned text touched; rename or merge if
    upstream ships its own guides; amended 2026-10-13, review fold: B m-3).
    Any passage quoting a diagnostic that holds a doc-style word sits
    between the ignore and resume markers.
4.  **fork/ORCHESTRATION.md** — a dated paragraph after :52-67 recording the
    EV-1 branch, its commits, the expected flip and the held PR, and that
    EV-1 merges after PR 52 (the merge-order sentence of :66-67 gains it;
    amended 2026-10-13, review fold: B-1); a Branches row `` |
    `claude/carbon-fork-0-1-ev` | HELD OPEN as PR NN — EV-1 evaluator guides
    at <sha> (gap row 90 expected DONE, W-062 discharged, W-152, W-153);
    state T until trunk holds PR 52, then the integration commit;
    verification record in the PR; merge after PR 52. | ``; the land
    sequence's EV-1 steps: the integration commit, `python3
    fork/evaluator/check_samples.py` (kept in both states, D-EV-13), `python3
    fork/evaluator/check_faq.py` with F and with the then-current nightly,
    and the runner with that nightly (D-EV-2) (amended 2026-10-13, review
    fold: B-3, A4, A12); the reservation W-152 to W-159 if the orchestrator
    has not stamped it already; §0.2 item 5's quotation fix and item 6's
    toolchain list; Next actions unchanged except W-152 after the Actions
    decision. Trunk 9d3ca60a3 already holds the reservation paragraph
    (fork/ORCHESTRATION.md:69-76) and an EV-1 Branches row (:412), so
    commit 3 does not re-add the reservation and updates that row in place
    instead of adding one. If `git diff --stat 80a11e7f0 origin/trunk`
    still lists only fork/ORCHESTRATION.md, commit 3 first merges
    origin/trunk into the branch (a merge commit, never a rebase,
    AGENTS.md; the branch stays in state T); otherwise it writes against
    80a11e7f0 and records the expected conflict with the stamped paragraph
    and row for the integration commit's merge (amended 2026-10-13,
    document-review fold: R2-10).
5.  **fork/evaluator/plan.md** (this file) — review fold records, sign-off,
    landed notes.

## §3 Commit structure

The plan's own commits (rev 1, rev 2) precede these. Commits are named by their
titles' numbers (1, 2, 2a, 3, 4), not by the list position below; commits 1 to 4
are written in state T on this branch, and the integration commit moves the
branch to state C once trunk holds PR 52 (amended 2026-10-13, review fold: B
m-5, B-1, A2).

1.  **`EV-1 (1/3): evaluator guides — getting started, tutorial, FAQ;
    guides index; README and project FAQ pointers`** — §2.A-§2.D. The
    pages' samples are copied from §2.B; prek to a fixpoint with the R31
    counts in the message; the by-hand runs of §8.3, the nightly download
    included, recorded in the message.
2.  **`EV-1 (2/3): tutorial programs replace the evaluator_docs_review stub;
    C++-library fixtures; sample and FAQ checkers; program table`** — §2.E,
    in state T form. The §8.6 id grep runs before the first file that names
    an id. Order inside the commit (the R12 hook runs `--self-test` after
    every program edit, and the table is stale until all programs exist):
    write the fixtures and the twelve program files, delete the stub,
    refresh the getting-started header, run `--update-readme-table`, then
    `--self-test`, both checkers (check_faq.py on F and N; a mismatch
    blocks the commit) and the runner. The message carries the local runner
    and checker results and "stated as expected, not of record".
3.  **`EV-1 (2a): document-review fold`** — after commit 2 the two document
    reviews of D-EV-19 run, and a separate fixer folds them here: page,
    program and checker fixes, each re-run as §8 says. Friction not fixed
    here is listed for commit 3 under W-155 to W-159.
4.  **`EV-1 (3/3): discharge — gap row 90, ledger W-062 and residues,
    decision-log entry, ORCHESTRATION, plan landed notes`** — §2.F in its
    state T texts.
5.  **`EV-1 (4): implementation-review fold`** — the implementation review
    of D-EV-19 reads commits 1 to 3 (with 2a); a separate fixer folds it
    here and amends the decision-log REVIEWS section and the plan's landed
    notes to record it. The PR is opened and HELD after this commit.
6.  **`EV-1: integration with PR 52 (state C)`** — once trunk holds PR 52:
    merge trunk into the branch (a merge commit; the PR's submitted commits
    are never rebased, AGENTS.md), resolving gap-analysis.md,
    decision-log.md, ORCHESTRATION.md, work-items.json and
    docs/guides/README.md conflicts per R-8; then one commit with: the
    C++-library program's two-line un-SKIP (§2.E.2), the
    `evaluator_samples_self_check()` hook in runner.py's `--self-test`
    (§2.E.4), the build_systems.md links and W-131 and W-133 citations of
    D-EV-10, row 90 and the header and §W11 in their state C texts (§2.F.1,
    §5.3), W-131's and W-133's notes, and the decision-log and
    ORCHESTRATION updates. Verification as §8.2's state C line, the R31
    counts re-run, all recorded in the message. If PR 52 merged before
    commit 1, this commit is only the merge (D-EV-10's break condition).

Commit convention: `GIT_COMMITTER_NAME=Claude
GIT_COMMITTER_EMAIL=noreply@anthropic.com git commit
--author="jmann345 <jerrymannstan@gmail.com>"`, explicit paths only (R20),
the session's attribution trailers last. Not pushed until R25's prek run;
the PR is opened and HELD like PR 51 (R28(c)).

## §4 Test expectations (hand-derived; R16(d))

Each line is `Core.Print`'s `<int>\n` (core/io.carbon declares
`Print(x: i32)`; the runner README notes the newline) or the literal text a
C++ stream writes. Derived from the code, before and independent of any run;
the runs of §0.1 rows 10 and 23 agreed.

| Program | EXPECT-STDOUT | Derivation |
| --- | --- | --- |
| evaluator_tutorial_hello | `Hello, world!` | the literal, newline from `\n` |
| evaluator_tutorial_functions | `30` `3` `2` `1` `0` `1` | 1 + 4 + 9 + 16 = 30; the loop prints 3, 2, 1 and stops at 0; 4 % 2 == 0, so parity 0 (the `then` arm); (4 + 1) % 2 == 1, so the second if-expression takes its `else` arm, 1 (amended 2026-10-13, review fold: A11) |
| evaluator_tutorial_classes | `3` `7` `8` | origin (0, 0); after (3, 4): x = 3, sum 7; after (−1, 2): (2, 6), sum 8 |
| evaluator_tutorial_generics | `18` `20` `19` | 2 × 3 × 3 = 18; 2 × 2 × 5 = 20; 9 + 10 = 19 |
| evaluator_tutorial_choice_match | `12` `15` `0` `100` `200` `300` | 3 × 2 × 2 = 12; 3 × 5 = 15; Empty 0; n = 0 takes the literal case; −4 fails the literal and passes the guard; 9 fails both and takes `default` |
| evaluator_tutorial_errors | `3` `-7` `3` `0` | 12 / 4 = 3; 7 / 0 is `Err(7)`, `?` returns it from `Average`, `Report` prints −7; 9 / 3 = 3 matches `.Ok`; 1 / 0 is `Err(1)`, which does not match `.Ok`, so the `else` block prints 0 (amended 2026-10-13, review fold: A11) |
| evaluator_tutorial_interop_use_cpp | `5` `15` `17` | abs(−5) = 5; 10 + 5 = 15; 2 + 3 + 5 + 7 = 17 |
| evaluator_tutorial_cpp_library (SKIP in state T, BUILD-SCRIPT in state C) | `42` | 6 × 7 = 42 (amended 2026-10-13, review fold: A2, B-1) |
| evaluator_tutorial_interop_call_carbon | `14` `100` `20` | 1 + 4 + 9 = 14, inside [0, 100], returned as is; 1 + 4 + ... + 100 = 385 > 100, so `hi`, 100; 14 < 20, so `lo`, 20 (amended 2026-10-13, review fold: A11) |
| evaluator_tutorial_package | `12` `14` | 3 × 4 = 12; 2 × (3 + 4) = 14 |

All exit 0 (`Run` returns 0 or `()`). The three rev 2 additions were
derived here before the re-run of §0.1 row 10, which agreed (amended
2026-10-13, review fold: A11). Expected tool output (amended 2026-10-13,
review fold: A2, A4, A10, B-1, B-3):

-   **State T, commit 2:** runner self-test: the three self-checks OK and
    `self-test: 159 programs parsed, 56 bullets in table, OK`; sample
    checker: `check_samples: 14 samples, 0 errors` (twelve `carbon` and two
    `cpp` blocks); FAQ checker: `check_faq: 13 reproducers run, 0 errors`
    with F and `check_faq: 17 reproducers run, 0 errors` with nightly
    2026.10.12; local runner with F's busybox, `--filter project/`: 15 PASS
    / 6 SKIP, the ten new lines being nine PASS and the C++-library SKIP;
    the per-bullet rollup line for the evaluator bullet stays PASS with 11
    programs.
-   **State C, integration commit:** runner self-test: the four PR 52
    self-checks OK, then the checker's line and `evaluator-samples self-check:
    OK`, then `self-test: 159 programs parsed, 56 bullets in table, OK`; local
    runner with F's busybox, `--filter project/` on PR 52's head ea573f672 (§0.1
    row 23; recounted on the real trunk): 18 PASS / 3 SKIP, all ten new programs
    PASS (the C++-library one through `build.sh`); with nightly 2026.10.12 and
    `--filter project/evaluator`: 9 PASS, 2 COMPILE-FAIL (choice_match, errors).

## §5 Conformance and gap-row effect

1.  **Scoreboard delta (expected, not of record), per state** (amended
    2026-10-13, review fold: A2, B-1). State T: PASS +9, SKIP −1 +1,
    programs −1 +10. State C: PASS +10, SKIP −1, programs −1 +10. Bullets
    unchanged in both (the evaluator bullet is already PASS through
    evaluator_docs_getting_started.carbon). On trunk's floor, state T:
    **137 PASS / 0 FAIL / 22 SKIP over 159**, 48/56. On PR 51's base
    (131 / 0 / 19 over 150), state T: 140 / 0 / 19 over 159. With PR 52
    alone on 0bdce60a5 (130 / 0 / 20 over 150, 49/56), state C: 140 / 0 /
    19 over 159. With PRs 51, 52 and 53 all merged first, the expected
    landing (133 / 0 / 17 over 150, 49/56), state C: **143 / 0 / 16 over
    159**, 49/56. The delta rule applies; absolutes are never hard-coded.
2.  **Gap header:** DONE +1, PARTIAL −1. On trunk 30 / 21 / 4 / 1 →
    **31 / 20 / 4 / 1**; with SAFE-1 and CM-1 merged first, from 33 / 20 /
    2 / 1 to 34 / 19 / 2 / 1. The exact header texts are §2.F.1's.
3.  **Row 90** (status and evidence cells; bullet cell untouched; the row is one
    line in the table, the wraps below are this plan's; amended 2026-10-13,
    review fold: A1, A2, B-1, B-3, B-4, B-6). State T text, written at commit 3:
    `| Project: basic evaluator documentation (getting started to FAQs) | DONE |
    EV-1 (2026-10-DD, fork/evaluator/plan.md): docs/guides/ getting_started.md
    (two toolchains: the upstream nightly, whose download block was run
    verbatim, and this fork built from source, a block quoted from the hosted
    conformance job and not run here; the stale fork prereleases named and
    warned against; a platform table whose rows each cite a measurement,
    upstream's CI configuration or this fork's CI record, with Linux x86-64
    measured and macOS unverified for this fork's current trunk; the glibc
    development files that compiling C++ imports and linking need; the first
    program; the runtimes cache), docs/guides/tutorial.md (hello world,
    functions, classes, generics, choice and match and Core.Result with ? on the
    fork's toolchain, C++ interop in both directions, a multi-file package) and
    docs/guides/evaluator_faq.md (toolchain questions; every quoted toolchain
    diagnostic is re-run by fork/evaluator/check_faq.py except the
    download-failure and stale-prerelease loader lines, which were re-run by
    hand at commit 1; project questions stay in docs/project/faq.md). The ten
    tutorial programs are documentation-sync programs under a bullet that was
    already PASS (bullets unchanged), each a tutorial sample transcribed byte
    for byte and checked by fork/evaluator/check_samples.py: nine PASS locally
    on 0.0.0-0.dev+0bdce60a5 beside evaluator_docs_getting_started, and the
    C++-library one SKIPs until PR 52's BUILD-SCRIPT channel is on trunk — not
    of record: the hosted run R9 requires is pending with no dispatch date,
    Actions disabled. Not falsified by any review here: the fork
    build-from-source block (no Bazel), platforms other than Linux x86-64,
    distributions other than Ubuntu 24.04, a system without libc6-dev. Residue,
    each a filed item: no current downloadable fork toolchain (W-152); the macOS
    failure of OV-3's export golden found while sourcing the platform table
    (W-153). |` State C text, written by the integration commit: the same,
    except that "nine PASS locally ... is on trunk" reads "all ten PASS locally
    on 0.0.0-0.dev+0bdce60a5 beside evaluator_docs_getting_started, the
    C++-library one through fork/evaluator/cpp_library/build.sh under the
    BUILD-SCRIPT channel, and the sample check runs in runner.py --self-test".
4.  **Honesty guard (R9, R16):** the "not of record" phrase is in the row
    itself, not only in the header; the ORCHESTRATION scoreboard line is
    re-quoted from scoreboard.json only (§0.2 item 5), never moved to the
    expected numbers; progress reports quote the +9 or +10 PASS as
    documentation-sync programs, never as new bullet coverage (amended
    2026-10-13, review fold: B-3); if the first hosted run shows anything
    but the expected PASS lines (ten in state C), the row reverts to
    PARTIAL in the fix commit with the log quoted.

## §6 Churn inventory

-   **New files (22):** three guide pages; nine single-file programs; three
    package units; four C++-library fixtures in fork/evaluator/cpp_library/
    (`main.carbon`, `rectangle.h`, `rectangle.cpp`, `build.sh`);
    fork/evaluator/check_samples.py and fork/evaluator/check_faq.py; this
    plan (amended 2026-10-13, review fold: A2, A4).
-   **Deleted (1):** project/evaluator_docs_review.carbon.
-   **Modified (9, plus one in state C):** docs/guides/README.md (+3
    items), README.md (+1 paragraph, +1 item), docs/project/faq.md (+1
    sentence), project/evaluator_docs_getting_started.carbon (header
    comment), fork/conformance/README.md (table rows), fork/gap-analysis.md
    (row 90, header, §W11, area summary), fork/inventory/work-items.json
    (W-062, W-002, W-003, W-026, W-059, new items, `source`; W-131 and
    W-133 in state C), fork/decision-log.md (+1 entry), fork/ORCHESTRATION.md
    (paragraph, row, merge order, land-sequence steps, two corrections);
    in state C also fork/conformance/runner.py (the
    `evaluator_samples_self_check()` hook, about 15 lines, §2.E.4; amended
    2026-10-13, review fold: B-1, B-3).
-   **Toolchain C++, goldens, BUILD, .bzl, MODULE, .github: none.** No
    autoupdate; fix-cc-deps, buildifier and check-build-graph have nothing
    to see (the fixtures are not Bazel sources).
-   **prek hooks that fire:** check-copyright (`<!-- -->` on .md, `//` on
    .carbon, .h and .cpp, `#` on build.sh, `__copyright__` on .py), rumdl
    twice, check-google-doc-style, markdown-toc (the three pages),
    check-links (every relative link and anchor of the pages), codespell,
    ruff-check, ruff-format and ty on the two checkers, clang-format and
    check-header-guards on the C++ fixtures (§0.1 row 25; and, outside
    prek, the clangd-tidy gates of R21, which the fixtures pass only in the
    trailing-return form, so commit 2a writes them so, checked here with
    clang-tidy 18.1.3 and the repository's .clang-tidy;
    (amended 2026-10-13, document-review fold: R2-2)),
    check-executables-have-shebangs on build.sh, prettier on
    work-items.json, end-of-file, trailing-whitespace and mixed-line-ending
    on all.
-   **R12 hook:** polices `fork/*` (license headers; clang-format and the
    header-guard check on the fixtures; `--self-test` after each program
    edit, which reports the stale table until §3 commit 2 runs
    `--update-readme-table`, and in state C runs the sample checker; the
    R16(b) SKIP-addition check does not fire on a new, untracked file); it
    does not police docs/ or README.md, so prek, `--self-test` and the land
    sequence's checker run are their local checks (D-EV-13).

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — A sample breaks on a future toolchain.** Falsifier: COMPILE-FAIL
    or OUTPUT-MISMATCH for an `evaluator_tutorial_*` program on a later run.
    Contingency: fix the sample in the page and the program together (the
    checker refuses one without the other), re-derive §4, record it; never
    SKIP a PASSing tutorial program (R16(b)).
-   **R-2 — The page and the program drift.** Falsifier:
    `check_samples.py` reports a diff. Contingency: in state C the check
    runs inside `--self-test`, so the R12 hook catches drift on any program
    edit; a page-only edit is caught at the next `--self-test` or by the
    land sequence's checker run, which stays in both states (D-EV-13;
    amended 2026-10-13, review fold: B-3).
-   **R-3 — R31 damage in the pages.** The pages quote negative numbers,
    flags and diagnostics. Falsifier: a heading or list count of §8.1
    changes, or `git diff | grep -nE '^\+\s*#{1,6} [0-9]|^\+#[0-9]'` hits.
    Contingency: rephrase the sentence; never revert the reflow.
-   **R-4 — check-links rejects an anchor** (headings with code spans
    produce unusual slugs). Falsifier: prek's check-links failure.
    Contingency: plain-word headings, the diagnostic in the body.
-   **R-5 — An unverified package name is wrong.** Falsifier: a user report
    or a distribution's metadata. Contingency: the label already says
    unverified; the fix is one word (D-EV-4's break condition).
-   **R-6 — The fork build-from-source commands fail** (they are sourced, not
    run here). Falsifier: the evaluator-simulation review cannot run Bazel
    either, so the first real run is a user's or a hosted job's. Contingency:
    the label says "not run by this project's container"; the target and
    unpack step are the hosted conformance job's, which built the toolchain
    behind every scoreboard of record, most recently run 37402970811
    (`run_bazel.py`, where the guide uses the README's `run_bazelisk.py`;
    D-EV-5). Row 90 and the decision log say the block was not run (amended
    2026-10-13, review fold: A7, B-4).
-   **R-7 — `date -d yesterday` names a date with no nightly.** Falsifier:
    `wget` prints `ERROR 404: Not Found.` and exits 8 (measured for
    2001.01.01, §0.1 row 27; with curl, `curl: (22) The requested URL
    returned error: 404` needs `-f`). Contingency: the page's sentence about
    picking a date from the releases page and the FAQ's download entry
    (amended 2026-10-13, review fold: B-5).
-   **R-8 — Merge conflicts with PR 52 and PR 53.** docs/guides/README.md
    (CM-1 appends one item where EV-1 adds three), gap-analysis.md header,
    :29 and §W11 (CM-1 rewrites them), decision-log.md (all insert above
    SL-2), ORCHESTRATION.md, work-items.json, and in state C runner.py.
    Falsifier: the merge of trunk into the branch stops on a conflict.
    Contingency: the state C texts of §2.F.1 and §5.3, the delta rule of
    §5, and D-EV-10; resolved in the integration commit with the R31 counts
    re-run, the C++-library program's SKIP line (and its runner.py line
    pins) deleted by the un-SKIP, and every other runner.py line cited in
    the records re-pinned against the merged runner (amended 2026-10-13,
    review fold: A2, B-1). The branch is never rebased once the PR is open
    (AGENTS.md).
-   **R-9 — The stdout interleaving of hello** (C++ `std::cout` only) and
    of interop_use_cpp (`printf` only) has no mixed-stream ordering risk:
    each program writes through one mechanism. Falsifier: OUTPUT-MISMATCH
    with reordered lines. Contingency: none needed.
-   **R-10 — Overclaiming platforms.** Falsifier: a page sentence says
    "works on macOS" without a source label, or cites upstream's CI
    configuration as this fork's record. Contingency: the strictness
    review of D-EV-19 greps the pages and README.md for macOS, arm64,
    Windows and distribution names, each of which must carry its labelled
    source (amended 2026-10-13, review fold: A1).
-   **R-11 — An evaluator downloads the stale fork prerelease.** Falsifier:
    a report of the GLIBC_2.44 loader error, or of section "Errors as
    values" failing with ``member name `Result` not found in `Core` `` on a
    fork toolchain. Contingency: the "Two toolchains" warning and the FAQ
    entry "Can I download a prebuilt fork toolchain?" (D-EV-5); W-152
    (amended 2026-10-13, review fold: B-6).
-   **R-12 — A later nightly regresses a both-toolchain sample.**
    Falsifier: §8.3's download run or the land sequence's runner pass with
    the then-current nightly fails one of the eight. Contingency: D-EV-2's
    break condition (amended 2026-10-13, review fold: A12).
-   **Rejected: transcribing samples as a single program per page** — a
    failure would not name the section. **Rejected: a runner change in
    state T** (C++ units, or the checker inside `--self-test`) — it would
    conflict with PR 52's runner changes and widen a documentation PR into
    harness work; in state C the only runner change is the self-check hook
    of §2.E.4, which reuses PR 52's self-test structure (amended
    2026-10-13, review fold: B-1, B-3). **Rejected: stacking EV-1 on PR
    52's head now** (merging claude/carbon-fork-0-1-cmake into this branch
    before commit 1) — the EV-1 PR would carry CM-1's whole diff while PR 52
    is held, and every PR 52 fix would need another merge; the state T
    interim costs one pre-measured integration commit instead (amended
    2026-10-13, review fold: B-1). **Rejected: `curl -LO`** — a missing
    nightly exits 0 (D-EV-20; amended 2026-10-13, review fold: B-5).
    **Rejected: editing README.md's install commands** — upstream-owned,
    and the libgcc line works (§0.1 row 5). **Rejected: linking the fork's
    prereleases** — stale and, on Ubuntu 24.04, unable to start (§0.1 row
    17). **Rejected: `Core.PrintStr` in samples** — does not link under the
    taught commands (§0.1 row 8). **Rejected: header-only or
    `-I`-in-COMPILE-ARGS versions of the C++-library sample** (D-EV-12).
    **Rejected: extending the R12 hook to docs/guides/ edits** — the hook
    is the agents' own configuration under .claude/, outside this
    workstream's scope; the land-sequence checker run covers page-only
    edits (D-EV-13).

## §8 Verification and discharge

1.  **prek, per commit, to a fixpoint, with R31 counts.** (a) Before: for every
    touched markdown file, record these counts (heading lines per level, dash
    items including indented ones, numbered items):

    ```shell
    for l in 1 2 3 4 5 6; do
      grep -c "^$(printf '#%.0s' $(seq 1 $l)) " "$f"
    done
    grep -cE '^\s*-   ' "$f"
    grep -cE '^\s*[0-9]+\. ' "$f"
    ```

    The 80a11e7f0 baselines, as H1 to H6, then dash, then numbered: README.md
    15/9/7/0/0/0, 75, 2; docs/guides/README.md 1/0/0/0/0/0, 1, 0;
    docs/project/faq.md 1/9/34/2/0/0, 78, 0; fork/gap-analysis.md 1/5/23/0/0/0,
    0, 0; fork/decision-log.md 1/2/44/1/6/0, 23, 0; fork/ORCHESTRATION.md
    1/1/5/0/0/0, 8, 4; fork/conformance/README.md 6/4/3/0/0/0, 22, 6 (the H1
    counts include the comment lines of fenced shell blocks). (b) Run this until
    a pass changes nothing:

    ```shell
    SKIP=fix-cc-deps,check-build-graph,check-bazel-mod-deps,forbid-llvm-googletest \
      uvx prek run --files <touched files>
    ```

    (c) The diff grep of R-3 is empty. (d) Re-count: README.md dash +1,
    docs/guides/README.md dash +3, decision-log.md H3 +1 (plus the dash items
    the entry adds, counted), every other count unchanged; new pages are counted
    after and recorded. (e) Record (b) to (d) in each commit message.
2.  **Conformance and checkers, commit 2 (state T) and the integration commit
    (state C)** (R5: a private output directory, never fork/conformance/out;
    amended 2026-10-13, review fold: A2, A4, B-1, B-3):

    ```shell
    cd /home/user/carbon-ev
    python3 fork/conformance/runner.py --self-test
    python3 fork/evaluator/check_samples.py
    python3 fork/evaluator/check_faq.py --which fork \
      --toolchain /home/user/carbon-build/carbon-trunk/install/bin/carbon
    python3 fork/evaluator/check_faq.py --which nightly \
      --toolchain <the nightly of §8.3>/bin/carbon
    python3 fork/conformance/runner.py \
      --toolchain /home/user/carbon-build/carbon-trunk/install/lib/carbon/carbon-busybox \
      --out <scratchpad>/ev1/runner-c2 --filter project/
    ```

    Expected: §4's lines for the state. The same runner line with the nightly's
    busybox and the filter `project/evaluator` (state T: 8 PASS, 2 COMPILE-FAIL,
    1 SKIP; state C: 9 PASS, 2 COMPILE-FAIL) is the two-toolchain evidence of
    D-EV-2, a gate for the eight both-toolchain samples' labels (D-EV-2's break
    condition), not for the scoreboard.
3.  **By hand, commit 1** (amended 2026-10-13, review fold: B-4, B-5, B-6,
    A4): §2.A item 3's block run verbatim in a fresh scratch directory from
    a `PATH` without `carbon`, recording the version it prints and the
    tarball's sha256 (2026-10-13's run: §0.1 row 27); then §2.A item 6's
    forty_two block and every §2.B sample and command block from that tree
    and with F (choice_match and errors with F only), outputs compared with
    §4; the C++-library block on both; the download-failure texts of §0.1
    row 27 (a date with no release, `wget` and `curl` without and with
    `-f`); the stale prerelease's loader line of §0.1 row 17 if the release
    still exists. Recorded in the commit message. The Bazel build is not run
    (there is no Bazel).
4.  **What cannot run here, stated in the PR, row 90 and the decision log**
    (amended 2026-10-13, review fold: B m-3, B-4): Bazel (the fork
    build-from-source block; its target and unpack step ran on hosted run
    37402970811); any hosted workflow (Actions disabled; R28 forbids the
    owner's runner); macOS, Windows, Linux arm64 and any distribution but
    Ubuntu 24.04 (the platform rows cite upstream's CI configuration or
    this fork's CI record and are labelled so); a system without libc6-dev
    (an empty sysroot stands in) or with libc6-dev and no GCC packages; the
    stale prerelease on a glibc of 2.44 or newer.
5.  **Review gates** (amended 2026-10-13, review fold: B m-5): the two plan
    reviews (rev 2 folds them); the two document reviews of D-EV-19 after
    commit 2, folded in commit 2a; the implementation review after commit 3,
    folded in commit 4; a separate fixer each time (R11).
6.  **Ledger and ids** (amended 2026-10-13, review fold: A8, B-2): at
    sign-off, again before commit 2 writes any id, and again at discharge,
    run from the worktree:

    ```shell
    for b in $(git for-each-ref --format='%(refname:short)' refs/heads/trunk \
        'refs/heads/claude/carbon-fork-0-1-*' \
        'refs/remotes/origin/claude/carbon-fork-0-1-*'); do
      m=$( (git show "$b:fork/inventory/work-items.json" 2>/dev/null;
            git grep -h -o 'W-[0-9]\{3\}' "$b" -- 'fork/*/plan.md' \
              fork/ORCHESTRATION.md 2>/dev/null) |
           grep -o 'W-[0-9]\{3\}' | sort -u | tail -1)
      echo "$m $b"
    done | sort | tail -3
    ```

    which reports the highest id any live head files, plans or reserves (ids
    are three digits, so the text sort is numeric). Run at rev 1's head
    (2026-10-13) it reported
    W-164 on claude/carbon-fork-0-1-st (ST-1's planned W-160 to W-164, past
    this block), W-155 on this branch (rev 1's text) and W-151 on trunk and
    the SC-1 head: W-152 to W-159 is free of filings and agrees with ST-1's
    record of the reservation. Record each result in the commit that
    follows it; `python3 -c "import json;
    json.load(open('fork/inventory/work-items.json'))"` succeeds; §2.F.2's
    edits.
7.  **Reconciliation greps at discharge** (amended 2026-10-13, review fold: B
    m-3): `grep -rn --exclude-dir=out evaluator_docs_review fork/conformance
    fork/gap-analysis.md` hits nothing, and in fork/inventory/work-items.json
    only W-062's discharge note naming the deleted stub (fork/b1/plan.md:179 and
    the hosted scoreboard.json under fork/conformance/out stay: history, and a
    record only a hosted run rewrites); `grep -rn 'W-152\|W-153'` hits the
    ledger, row 90 and the decision log (and W-154 only where §2.F.2 filed it);
    the sample checker reports 14 samples. Beyond this plan and
    fork/ORCHESTRATION.md, the expected extra hits are getting_started.md and
    evaluator_faq.md, which name W-152 and W-153 since commit 1, and for W-154
    the C++-library program's SKIP line, which names it as reserved and filed
    only if the program must merge before PR 52 (§2.E.2); W-155 hits the ledger,
    the decision log and this plan only (amended 2026-10-13, document-review
    fold: R2-10).
8.  **Decision-log entry, ORCHESTRATION, landed notes** per §2.F.3-5; the
    PR opened and HELD after commit 4 with "awaiting hosted conformance
    (Actions disabled); merges after PR 52, through the integration commit"
    and its dispatch list in ORCHESTRATION.

## Hand-off notes for the implementer

-   `<scratchpad>` in this plan is the planning session's scratch directory,
    `/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad`.
    Rev 2's material is under `ev1/fix/`: `samples/` (the rev 2 samples and the
    two C++ files, byte-identical to §2.B), `tools/gen_rev2.py` (writes §2.E's
    programs for state T or state C), `mcm/` and `mtr/` (the state C and state T
    mirrors of §0.1 rows 23 and 25, the fixtures under
    `mcm/fork/evaluator/cpp_library/`), `proto/fork/evaluator/` (the two checker
    prototypes) and `faq/run_repro.sh`. Rev 1's `ev1/samples/` and
    `ev1/tools/gen_programs.py` are superseded. If the scratchpad is gone, §2.B,
    §2.C and §2.E are complete on their own (amended 2026-10-13, review fold: B
    m-1).
-   Copy the samples from §2.B (or from `ev1/fix/samples/`, which §0.1 rows
    10-13 and 25 ran); do not retype them. Every `carbon` fenced block in
    tutorial.md is a whole program at column 0, never inside a list (the
    checker rejects an indented fence); partial snippets use inline code.
    Each sample section holds exactly one `text` block. The FAQ has no
    `carbon` fenced block.
-   Run `gen_rev2.py <samples> <programs/project> skip "<SKIP line>"` for
    state T, or with `build-script` for state C, or reproduce its output by
    hand; either way the checker and `--self-test` decide.
-   Commits 1 to 4 are state T. Do not link build_systems.md, cite W-131 or
    W-133, or touch runner.py before the integration commit; that commit is
    a merge of trunk into the branch plus one commit, never a rebase of the
    PR's commits (AGENTS.md; §3).
-   Write the programs, then delete the stub, then `--update-readme-table`.
    Until then the R12 hook reports the stale table after every program
    edit; that is expected.
-   Keep the C++-library SKIP text on one line and its runner.py line
    numbers current: re-open runner.py before committing. The un-SKIP is
    the two-line edit of §2.E.2, nothing else.
-   The fixture `rectangle.h` carries the guard
    `CARBON_FORK_EVALUATOR_CPP_LIBRARY_RECTANGLE_H_` (the hook rewrites any
    other); the page shows `RECTANGLE_H_`, and the checker reads one as the
    other. `build.sh` must be executable and keep every build message on
    stderr (PR 52's BUILD-SCRIPT contract).
-   Run `check_faq.py` with F and with the nightly you downloaded in §8.3;
    a quoted line on the FAQ page changes only with its reproducer.
-   Write "PR 52", never a number with a hash prefix; keep flags, negative
    numbers and diagnostics out of line starts (R31); avoid the doc-style
    word list in prose and in code (no Latin abbreviations, no three-letter
    synonym of "by way of", no short form of "repository").
-   Never link docs/guides/build_systems.md unless it is on the base you are
    committing onto (D-EV-10).
-   Never run bazel; never dispatch a workflow; never touch .github/; the
    fork build-from-source block is quoted, not run.
-   Every platform or distribution claim on a page carries its labelled
    source: "measured on Ubuntu 24.04", "upstream's CI configuration", "this
    fork's CI record" with the run id, or "not verified by this project";
    upstream's configuration never stands in for this fork's record (amended
    2026-10-13, review fold: A1).

## Review fold record (rev 2, 2026-10-13)

Reviews of rev 1 (dd24df3a7): A (correctness and evaluator fidelity) —
**APPROVE-WITH-AMENDMENTS**, four MAJOR and eight MINOR; B (strictness,
process and records) — **APPROVE-WITH-AMENDMENTS**, six MAJOR and five
MINOR. Neither found a BLOCKER. A separate fixer (R11) re-opened every cited
location, re-ran every measurement a finding is about (scratch under the
session scratchpad's `ev1/fix/`), and folded each finding in place with the
mark "(amended 2026-10-13, review fold: …)"; the date is the day the fold
ran, the same day as rev 1. **All twenty-three findings are accepted and
folded; none is rejected.** Three are folded as a variant of the reviewer's
fix, with the evidence for the variant in the row: A8/B-2 (the reservation
is ST-1's recorded block, and unused ids are kept unused rather than
released), B-2's ORCHESTRATION line (a trunk stamp by the orchestrator, not
a line on this branch) and B-5 (the README's `wget`, not `curl -fLO`).

| Finding | Grade | Fixer's reproduction | Disposition and where folded |
| --- | --- | --- | --- |
| A1 macOS and arm64 rows rest on upstream's CI configuration; the fork's own partly red record is omitted; the README pointer overclaims | MAJOR | CONFIRMED: REST reads of runs 37398447710 (macos-14 Test (Opt) failure; job log: `//toolchain/testing:file_test FAILED`, ``call to 'F' is ambiguous`` for `Carbon::F(7L)` in export/overload_set.carbon, `//toolchain/install:install_test PASSED in 58.8s`; ubuntu-22.04-arm success), 37359728074 (same failure, install_test PASSED in 28.5 s), 37406043564 (macos-14 failed in test setup), 37406163455 (every Test step skipped); `grep` finds no fork record of the failure; build_systems.md:463 on PR 52 says "macOS is unverified" | FOLDED: §0.1 row 16 relabelled as upstream configuration and new row 26 (the fork's record); §1.C and D-EV-3 rewritten with two labelled sources and "unverified for this fork's current trunk"; §2.A item 2; §2.D item 2's README sentence rewritten without "other Linux distributions and macOS"; W-153 filed for the darwin failure (§2.F.2, W-026 cross-reference); §2.C platforms entry; R-10; hand-off label rule |
| A2 C++-library SKIP and its residue go stale on the landing trunk; the C++ half is never transcribed | MAJOR | CONFIRMED: fork/ORCHESTRATION.md:66-67 order; CM-1's runner.py moves the pins to :357, :690-698, :720-725 and takes `cwd=` at :563; the BUILD-SCRIPT form prototyped independently (fixtures and `build.sh` in a mirror of PR 52's head): build-script self-check OK, PASS `42` on F and N, the identity rule trips on a one-space fixture edit, and the state T to state C edit is byte-exact (`cmp`) | FOLDED: §1.F's two states; D-EV-12 rewritten (BUILD-SCRIPT is the landing form, SKIP the state T interim, fixtures committed in both); §2.E.2 with the fixtures, the exact `build.sh` and both program texts; the checker diffs the `cpp` blocks (D-EV-13); §0.1 rows 22, 23, 25; §3's integration commit re-pins or deletes every runner.py line (R-8); the C++-units residue is dropped from the expected path (W-154 only for a state T merge) |
| A3 "missing return after match" is false for a match with a `default` arm | MAJOR | CONFIRMED on F: `match` with `default` and returning arms, no trailing return: compiles, exits 1; no `default` (exhaustive choice match, or irrefutable last arm): ``missing `return` at end of function with declared return type`` | FOLDED: §0.1 row 14 records both shapes; §2.B section 5's text and the FAQ entry "A function ending in a match needs a return" reworded; reproducers `match-return` and `match-default` in §2.C |
| A4 the FAQ end has no fixed reproducers and no verification step | MAJOR | CONFIRMED: rev 1 §2.C and §8.3 fix no FAQ inputs; the fixer wrote twenty reproducers and a prototype `check_faq.py` (13 rows on F, 17 on N, 0 errors; a one-character page edit is reported) | FOLDED: §2.C reproducer table; D-EV-21; §2.E.5 (`check_faq.py`); §1.E; §8.2 and §8.3; a mismatch blocks commit 2 (§3); §0.1 row 28 |
| A5 C++ interop needs libc6-dev's headers at compile time | MINOR | CONFIRMED on F and N: `-- --sysroot=<empty dir>` makes hello fail at compile with the `mbstate_t` line (then `'ctype.h' file not found`, 186 lines); the pure-Carbon sample compiles | FOLDED: §0.1 row 6; §1.C; D-EV-4; §2.A item 5 retitled "System packages"; FAQ entry "Compiling a C++ import fails inside libc++"; reproducer `no-c-headers`; D-EV-19's simulation brief runs the probe |
| A6 first-link timing quoted as fixed | MINOR | CONFIRMED: cold link 31.8 s (F) and 31.7 s (N) at load average 3.8 to 6.4 against rev 1's 19.3 s and 21.6 s; warm 0.041 s and 0.048 s; compile 0.28 s and 0.12 s | FOLDED: §0.1 row 2 lists the three measurements with their load; §2.A item 7's sentence gives the range and conditions; FAQ entry keeps R4's framing |
| A7 build-from-source block names a different script than its source; F is not the Bazel artifact | MINOR | CONFIRMED: fork_hosted.yaml:110 `run_bazel.py`, plan `run_bazelisk.py`; F links /home/user/llvm-build's libLLVM.so.24.0git built from 6ec87e7ec without MODULE.bazel's patches (CONFIGURE.txt); run 37402970811's log shows the Bazel build (9m29.6s), `0.0.0-0.dev+unknown`, 128 / 0 / 22 | FOLDED: header paragraph and §0.1 rows 1 and 18 state F's provenance and cite run 37402970811; D-EV-5 records `run_bazelisk.py` as deliberate (README.md:349, contribution_tools.md:78) with the substitution in the label; §2.A item 4; R-6 |
| A8 W-152 embedded at commit 2 but allocated at commit 3; parallel allocation race | MINOR | CONFIRMED: rev 1 D-EV-18 and §2.E.2; the W-144 collision at fork/ORCHESTRATION.md:62-65; and since rev 1, ST-1's plan (bff5ba4e8) already records W-152 to W-159 for EV-1 and starts at W-160 | FOLDED with a variant: the reserved block is ST-1's recorded W-152 to W-159 (not W-152 to W-155); the grep runs at sign-off, before commit 2 and at discharge over ledgers, plans and ORCHESTRATION of every live head (§8.6, run once at rev 1's head); unused ids stay unused instead of being released, because a released id is the collision path of W-144 and the brief forbids reuse. Status header, D-EV-18, §2.F.2, §8.6 |
| A9 FAQ and records restate PR 52's W-131 and W-133 and omit its g++ workaround | MINOR | CONFIRMED: build_systems.md:284-292 and :461-462 on PR 52; the fixer measured the workaround on F (`-- /usr/lib/x86_64-linux-gnu/libstdc++.so.6` links the g++ object, prints `10`) and the C-ABI case (links, prints `42`) | FOLDED: §0.1 row 11; D-EV-6 and D-EV-10 (state C citations and links); FAQ g++ entry gives both measurements and the caveat; §2.F.2 (W-131, W-133 notes); §2.F.3 RESIDUE |
| A10 the checker skips expected-output blocks and ignores indented fences | MINOR | CONFIRMED in rev 1's prototype; the rev 2 prototype pairs each section's `text` block with EXPECT-STDOUT and rejects indented fences, and reports a `7` for `-7` edit and an indented `carbon` fence on a mock page | FOLDED: D-EV-13; §2.B page structure (one `text` block per sample section); §2.E.4; §0.1 row 23 |
| A11 three programs check one side of their branch | MINOR | CONFIRMED by reading the samples; the fixer derived the additions by hand first (functions `1`, errors `0`, call-Carbon `20`), then ran all eight single-file samples on F and N with the §4 output | FOLDED: §2.B samples 2, 6 and 9; §4 rows and derivations; D-EV-8; §0.1 row 10 |
| A12 sibling wording, nightly-specific labels, SKIP citation | MINOR | CONFIRMED: runner.py:516-524 passes all other units; the measured objects are byte-identical (`cmp`, F and N); only nightly 2026.10.12 was measured | FOLDED: §2.E.3 and D-EV-11 wording; "measured with nightly 2026.10.12" labels (§1.B, §2.B, §2.C); D-EV-2's second break condition and R-12; the SKIP text cites §0.1 row 11 |
| B-1 D-EV-10/12/13 keyed to EV-1's time, not the recorded land order | MAJOR | CONFIRMED (as A2), and the merge-commit precedent for integrating trunk into a branch (b51094c44) | FOLDED: §1.F's states; D-EV-10, D-EV-12, D-EV-13; §3's integration commit (a merge, never a rebase, AGENTS.md); §2.F.4 adds EV-1 after PR 52 to the merge order; stacking on PR 52 now is a rejected alternative (§7) |
| B-2 ids used before allocation; race with ST-1 | MAJOR | CONFIRMED (as A8); W-151's reservation is a trunk ORCHESTRATION stamp (80a11e7f0) | FOLDED with a variant: the plan's status header and D-EV-18 record the block, and the trunk ORCHESTRATION stamp is the orchestrator's (a line on this branch is not read by ST-1's worktree at 80a11e7f0), with §2.F.4 adding it at discharge if still missing; ST-1 starts at W-160 by its own record |
| B-3 the sync check is enforced by nothing automatic | MAJOR | CONFIRMED: .claude/hooks/post_edit_invariants.sh:23 and :93-96; the fixer wired the prototype into a mirror of PR 52's `--self-test` (`evaluator-samples self-check: OK`, ERRORS on a `7` edit) | FOLDED: D-EV-13 (self-check in state C, land-sequence run in both); §2.E.4; §2.F.4; R-2; row 90 and the decision log call the new programs documentation-sync programs under an already-PASS bullet (D-EV-16, §5.3, §5.4, §2.F.3); W-154's checker purpose is dropped |
| B-4 the install step is never measured | MAJOR | CONFIRMED and measured: the block run verbatim under `env -i` with no `carbon` on `PATH` downloaded 58783647 bytes (sha256 `f85bdd83…`), unpacked to a tree identical to N, printed the version, and the forty_two block printed `42` | FOLDED: §0.1 row 27; §8.3 runs it at commit 1; D-EV-19's simulation starts with the download; D-EV-16 lists the steps no review can falsify; row 90 and the decision log say the build-from-source block was quoted, not run (§5.3, §2.F.3, §8.4) |
| B-5 `curl -LO` without `--fail` | MAJOR | CONFIRMED: `curl -LO` for 2001.01.01 exits 0 with a 9-byte `Not Found` file and `tar` then fails with `gzip: stdin: not in gzip format`; `curl -fLO` exits 22; `wget` exits 8 with `ERROR 404: Not Found.` and writes no file | FOLDED with a variant: the block returns to README.md:292's `wget` (D-EV-20, with the reason and break conditions), and the page gives `curl -fLO` as the alternative; R-7's falsifier rewritten; FAQ entry "The download fails, or tar says the file is not in gzip format" |
| B-6 stale fork prereleases unaddressed; FAQ would misdiagnose | MAJOR | CONFIRMED and measured further: the fixer downloaded fork-toolchain-143-ea02513be; its busybox needs GLIBC_2.44 (`cosh`, `sinh`) and does not start on Ubuntu 24.04; at ea02513be there is no `union` or `overload` keyword, no result.carbon or slice.carbon, and if-let is a SKIP program | FOLDED: §0.1 row 17; §0.2 item 10; §1.B; D-EV-5 (warning, extended break condition); §2.A item 1; FAQ entries "Can I download a prebuilt fork toolchain?" and "The compiler rejects a fork feature" (before a27059915); R-11 |
| B m-1 judgment calls left to the implementer | MINOR | CONFIRMED: rev 1 §2.C "heading wording is the writer's"; the generator's truncated section strings; ledger items without titles; W-154 `blocked_by` not an allowed kind (work-items.json `source`) | FOLDED: §2.A H2 titles; §2.B page structure and link map; §2.C heading tree; §2.E.1 provenance strings; §2.E.4 literals; §2.F.1 header and §W11 texts for both states; §2.F.2 titles with `blocked_by` empty; hand-off notes point at `ev1/fix/` and say what stands without it |
| B m-2 FAQ inconsistent with PR 52's guide | MINOR | CONFIRMED (as A9), and build_systems.md:201-211's Core-libraries route | FOLDED: D-EV-7 and D-EV-10; FAQ g++ and PrintStr entries; §2.F.2 |
| B m-3 internal contradictions and wrong citations | MINOR | CONFIRMED: (a) the grep hits fork/conformance/out/scoreboard.json on trunk; (b) the V-3a sentence omits docs/guides/README.md; (c) objects measured byte-identical with `cmp`; (d) script substitution unrecorded; (e) SKIP cites "section 2"; (f) §8.4 incomplete | FOLDED: (a) §8.7 `--exclude-dir=out` and the expected work-items hit; (b) §2.F.3; (c) §0.1 row 13, D-EV-11, §2.E.3; (d) D-EV-5, §0.1 row 18; (e) §2.E.2; (f) §8.4 and D-EV-17 |
| B m-4 unmeasured page claims; README overclaim | MINOR | CONFIRMED and measured: if-let (`expected expression`), `union` and `overload fn` (`unrecognized declaration introducer`) and `Core.Slice` (``member name `Slice` not found in `Core` ``) are all rejected by N | FOLDED: §0.1 row 9; §2.A item 1 (all seven measured; browser claim labelled inferred); D-EV-4 and §2.A item 5 (empty-sysroot label); §2.D item 2; reproducers `if-let`, `union`, `overload`, `slice` |
| B m-5 commit structure and review placement; review count under R29(c) | MINOR | CONFIRMED: rev 1 §3 has no fold commits; D-SAFE-23 (/home/user/carbon-safe fork/safe/plan.md:1058-1066) chose two document reviews | FOLDED: §3 commits 2a, 4 and the integration commit; D-EV-19 (two document reviews with briefs, one implementation review, the R29(c) and D-SAFE-23 justification, friction filed under W-155 to W-159); §8.5 |

R31 count check for this fold (fork/evaluator/plan.md; counts by the commands of
§8.1(a)). Rev 1 as committed: headings H1 one, H2 ten, H3 sixteen, H4 to H6
none; dash items forty-six; numbered items forty-nine. Rev 2 before prek: H1
one, H2 eleven, H3 sixteen; dash items sixty-four; numbered items fifty-three.
The deliberate changes: one H2 (this record); four H3 headings renamed, none
added (§1.F, §2.A, §2.C, §2.E); eighteen dash items (two §1.F states, D-EV-20
and D-EV-21, three §2.F.1 and four §2.F.2 sub-items, two §4 states, R-11 and
R-12, three hand-off notes); four numbered items (§2.E item 8 and §3's commits
2a, 4 and the integration commit). Prek runs: the first reflowed eleven
paragraphs (rumdl MD013; no fenced block touched) and the second changed
nothing; after the last edits one run reflowed two more paragraphs and reported
one line it cannot break (D-EV-10's bold title), which was shortened by hand,
and the final run passed with no change. Every count after the fixpoint equals
the pre-prek count, the heading set is unchanged by prek, and the R-3 grep of
the diff for manufactured headings is empty. The counts are spelled in words
here so that no wrap can start a line with a number and a period.

## Sign-off

Signed off for implementation on 2026-10-13 at rev 2 by the orchestrator under
R29(a): the two plan reviews of R29(c) (A: correctness and evaluator fidelity,
APPROVE-WITH-AMENDMENTS, four MAJOR and eight MINOR; B: strictness, process and
records, APPROVE-WITH-AMENDMENTS, six MAJOR and five MINOR) found no BLOCKER,
so no focused re-review is owed; all twenty-three findings are folded in rev 2
(f0e1ab70b) and none is rejected. The id block W-152 to W-159 is reserved for
this workstream on trunk's fork/ORCHESTRATION.md at the sign-off stamp, beside
ST-1's start at W-160. Implementation proceeds in state T per §3; the
integration commit to state C waits for PR 52 on trunk.

## Document-review fold record (commit 2a, 2026-10-13)

The two document reviews of D-EV-19 read commits 751102ee1 and 21c4a0565.
Review 1, the evaluator simulation, returned **REJECT** on one BLOCKER, graded
so under the rubric's clause that a false assertion on a page is one (B1),
with three MAJOR and twelve MINOR findings; review 2, strictness, returned
**APPROVE-WITH-AMENDMENTS** with two MAJOR and eight MINOR. Neither reported a
step that fails as written, so D-EV-16's break condition does not fire, and
D-EV-1's does not either (D-EV-1). A separate fixer (R11) reproduced every
finding before folding it, with scratch under the session scratchpad's
`ev1-impl/fixer2a/`, and rejected none. Three findings of review 1 are the
same defects as three of review 2 (B1 and R2-6, MAJOR-1 and R2-8(a), MINOR-7
and R2-7). Each passage this fold changed carries "(amended 2026-10-13,
document-review fold: …)" with the reviews' own ids. MINOR-3 is folded as a
variant of the reviewer's text, with the evidence in its row, and R2-10 as
amendments that commit 3 carries out.

| Finding | Grade | Fixer's reproduction | Disposition and where folded |
| --- | --- | --- | --- |
| B1 the tutorial calls the fixtures the page's files "byte for byte" | BLOCKER | CONFIRMED: a `diff` of the page's blocks with the fixtures shows the four-line license comment in all three and `CARBON_FORK_EVALUATOR_CPP_LIBRARY_RECTANGLE_H_` in the three guard lines of rectangle.h; check_samples.py equates them only after dropping the comment and reading the guard back | FOLDED: the sentence says the fixtures add a license comment and, in the header, the guard name the header-guard check requires; §2.B sample 8. Same defect as R2-6 |
| MAJOR-1 the cache directory is created only after the first link | MAJOR | CONFIRMED with N in fresh `HOME` directories: with no `.cache`, two links of forty_two took 33.7 s and 33.4 s and kept nothing; after the `mkdir` the first link took 33.3 to 34.4 s and the next 0.0 s (§0.1 row 3) | FOLDED: "Your first program" creates the directory before its compile block, and "The first link takes a while" keeps the explanation and shows the same command; the download block is unchanged; §0.1 row 3, §2.A items 6 and 7 |
| MAJOR-2 the only build duration used a remote cache a local build lacks | MAJOR | CONFIRMED: .bazelrc:45-51 sets only a disk cache; the remote cache is written into user.bazelrc by .github/actions/build-setup-common/action.yml:62-71, which fork_hosted.yaml uses | FOLDED: a paragraph after the 9m29.6s sentence (local build: no remote cache, LLVM and Clang from source, duration and disk use not measured); D-EV-5, §2.A item 4 |
| MAJOR-3 the tutorial says g++-compiled C++ does not link | MAJOR | CONFIRMED on F and N: `g++ -c rectangle.cpp` links with the section's main.carbon and prints `42`; the `g++` `std::string` object fails with the FAQ's quoted line | FOLDED: the sentence separates code that uses the standard library (does not link) from code that does not (links), as the FAQ does; §0.1 row 11, §2.B sample 8 |
| MINOR-1a fork-only sections do not link the fork build | MINOR | CONFIRMED by reading: the two "Runs on" lines and the FAQ's "need this fork's toolchain" and "Use this fork's toolchain" had no link | FOLDED: all four link getting_started.md's "Build this fork's toolchain from source"; D-EV-1, §2.B page structure, §2.C rows |
| MINOR-1b a non-Debian reader needs two jumps for a package name | MINOR | CONFIRMED by reading the FAQ's system-packages entry | FOLDED: the entry names `glibc-devel` (Fedora, RHEL, openSUSE) and `glibc` (Arch), labelled not verified, beside the table link; D-EV-1, §2.C row |
| MINOR-2 the build section does not say who needs it, or which `carbon` runs | MINOR | CONFIRMED by reading; with both `bin` directories exported, `carbon version` printed the toolchain exported last | FOLDED: the section opens with its two-section scope and closes with which `carbon` runs and how to run the other; §2.A item 4 |
| MINOR-3 "that container" is undefined; the CI run predates trunk | MINOR | CONFIRMED: no antecedent for "that container"; run 37402970811 ran at 606a99c5a, eight commits before 80a11e7f0, and `git diff --stat 606a99c5a 80a11e7f0` lists only five fork records (ORCHESTRATION.md, scoreboard.json, decision-log.md, work-items.json, upstream/plan.md) | FOLDED as a variant: "a CMake build on the Ubuntu 24.04 machine that ran these measurements", and the run's commit with "the later trunk commits change only this fork's records, not the toolchain" instead of "before the current trunk", which would suggest a different toolchain; §2.A item 2 |
| MINOR-4 "Linux x86-64 only" has no source label | MINOR | CONFIRMED: nightly_release.yaml:41, :97-105 and :118-127 build and publish one tarball on ubuntu-22.04; the page cited none of it | FOLDED: the "Two toolchains" cell and every "No prebuilt toolchain" status cell, Intel macOS included, cite upstream's release configuration, as does the FAQ's platform entry; §2.A items 1 and 2, §2.C row |
| MINOR-5 the `mkdir` ignores `$XDG_CACHE_HOME` | MINOR | CONFIRMED with N: with `XDG_CACHE_HOME` naming a missing directory and `$HOME/.cache` present, the link still used a temporary cache (34.0 s, nothing kept); runtimes_cache.cpp:142-149 prefers an absolute `$XDG_CACHE_HOME` | FOLDED: `mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"` on both pages; §0.1 row 3, §2.A items 6 and 7, §2.C row |
| MINOR-6 the libstdc++-by-path link is labelled fork-only | MINOR | CONFIRMED on N: the link prints `10`, as on F | FOLDED: "measured on both toolchains", and the toolchain's `clang++`, measured too (`42` and `10` on both); §0.1 row 11, §2.C row |
| MINOR-7 the newest releases-page entry is not mentioned | MINOR | CONFIRMED: REST listing of 2026-10-13, newest entry `arbiter-v0.0.0-0.nightly.2026.09.28` (prerelease, 2026-09-28), notes "Verbatim mirror of the upstream ... toolchain tarball", one asset `carbon_toolchain-0.0.0-0.nightly.2026.09.28.tar.gz` | FOLDED on both pages, labelled not run; D-EV-5, §0.1 row 17, §2.A item 1, §2.C row, W-152's evidence (§2.F.2). Same as R2-7 |
| MINOR-8 W-152 and W-153 are cited bare | MINOR | CONFIRMED: neither id is in fork/inventory/work-items.json on the branch | FOLDED: the first id on each page links the work-item ledger; commit 3 still files both before the PR opens (§2.F.2, §3); §2.A item 1, §2.C row |
| MINOR-9 no checker covers the guide's quoted diagnostics | MINOR | CONFIRMED: check_faq.py read only evaluator_faq.md; with getting_started.md's `mbstate_t` line edited, the committed checker printed "13 reproducers run, 0 errors" and exited 0 | FOLDED with the reviewer's first option: every guide `text`-block line other than program output (`GUIDE_OUTPUT`) must be a FAQ `text`-block line; that edit and a `GLIBC_2.45` edit now exit 1; D-EV-21, §2.C, §2.E.5 |
| MINOR-10 two sections share `main.carbon` | MINOR | CONFIRMED: both sections save `main.carbon`; compiling the package's alone is reproducer `no-api` (`error: imported API 'Geometry' not found`) | FOLDED: "Before you start" gives each of the two sections its own directory; §2.B page structure |
| MINOR-11 the optional cache blocks read as steps | MINOR | CONFIRMED by reading; each block builds the runtimes again (a new cache directory, or `build-runtimes`) | FOLDED: introduced as options the tutorial does not need, each building the runtimes once more; §2.A item 7 |
| R2-1 the match limitation is taught as a language rule | MAJOR | CONFIRMED: pattern_matching.md:590-592 and :612-617, code_and_name_organization/README.md:121-127 (ColorName, no trailing return), error_handling.md:350-353 (the checker's reachability analysis does not consult match exhaustiveness); no ledger item files it | FOLDED: the tutorial and the FAQ call it a current toolchain limitation, and the FAQ links both design passages; §0.1 row 14, §2.B sample 5, §2.C row. The limitation stays: W-155 at commit 3 (below) |
| R2-2 the fixtures fail clangd-tidy's trailing-return check | MAJOR | CONFIRMED: clang-tidy 18.1.3 with the repository's .clang-tidy reports `modernize-use-trailing-return-type` as an error in both fixtures; neither gate excludes fork/evaluator/ (clangd_tidy.yaml:66-77, fork_build_toolchain.yaml:133-151) | FOLDED with the preferred fix: `auto RectangleArea(int width, int height) -> int` on the page, in §2.B and in both fixtures, clang-tidy clean; the section re-run by hand from the page's blocks and build.sh run, on F and on N (`42`, exit 0, empty stderr); §0.1 row 25, §2.B sample 8, §6. No .github/ change |
| R2-3 "usable anywhere a value is" | MINOR | CONFIRMED on F and N: `1 + if ...` fails with ``parentheses are required around this unary `if` operator``, while `return if ...` and `1 + (if ...)` run | FOLDED: the sentence names the permitted positions and the parentheses; §0.1 row 29, §2.B sample 2 |
| R2-4 toolchain-only rules under "Design:" links | MINOR | CONFIRMED: interoperability/README.md:156, :240, :244 are TODO headings; no docs/design file mentions `inline Cpp`; `case x: i32 if x < 0` and the design's guard example fail on F with ``expected `(` after `if` ``, and N prints the same parse error (upstream's parser, handle_match.cpp:214) | FOLDED: the three passages are labelled toolchain behavior, and the guard sentence says the toolchain requires the parentheses and the design's grammar does not; §0.1 row 29, §2.B samples 5, 7 and 9. The optional FAQ entry is not added: it would change §2.C's fixed heading tree and need a reproducer for a parse error the tutorial already explains |
| R2-5 check_faq.py matches quoted lines as substrings | MINOR | CONFIRMED: with the FAQ's `error: expected expression` lengthened to `... or a pattern here`, the committed checker printed "13 reproducers run, 0 errors" and exited 0 | FOLDED: quoted lines are compared as whole `text`-block lines; that edit and a suffix on the `_CPrintStr.Core` line now exit 1; D-EV-21, §2.C, §2.E.5 |
| R2-6 the "byte for byte" fixture sentence | MINOR | as B1 | FOLDED with B1 |
| R2-7 the mirrored upstream nightly on the releases page | MINOR | as MINOR-7 | FOLDED with MINOR-7 |
| R2-8 the cache step's place; the idle timing range | MINOR | (a) as MAJOR-1; (b) CONFIRMED: commit 1's message records cold links of 16.2 s and 16.4 s at load average 2.4 to 3.6, under the quoted "19 to 22 seconds idle" | FOLDED: (a) with MAJOR-1; (b) the range reads "16 to 22 seconds at load average below 4, 32 to 34 at load average 4 to 8, 47 at load average 10.7", and "about 20 seconds" stays; §0.1 row 2, §2.A item 7 |
| R2-9 the FAQ drops "CMake build" from the platform summary | MINOR | CONFIRMED by reading the FAQ's platform entry against the table | FOLDED: the entry says the fork toolchain measured is a CMake build and the Bazel route was not run; §2.C row |
| R2-10 discharge readiness: §8.7, row 90, the trunk stamp | MINOR | CONFIRMED: (a) §8.7's grep, read literally, misses the two pages and the SKIP line; (b) four quoted lines are re-run by hand only (§2.C); (c) origin/trunk 9d3ca60a3 holds the reservation (fork/ORCHESTRATION.md:69-76) and an EV-1 Branches row (:412), and `git diff --stat 80a11e7f0 origin/trunk` lists only fork/ORCHESTRATION.md | FOLDED as amendments commit 3 carries out: §8.7 lists the expected extra hits, §5.3's row text excepts the by-hand lines, and §2.F.4 drops the re-stamp, updates the existing row and merges origin/trunk first while trunk has moved only by ORCHESTRATION stamps (otherwise it records the conflict) |

Not fixed in commit 2a, for commit 3 (D-EV-19, §2.F.2):

| Id | Finding | Why commit 2a does not fix it |
| --- | --- | --- |
| W-155 | R2-1: function-end reachability does not consult match exhaustiveness | It is a change to toolchain/check, outside this documentation workstream, which touches no toolchain C++ (§6); the pages now describe it as a current limitation, and §2.F.2 gives the item's fields |

W-156 to W-159 stay reserved and unused. The fold's verification and its R31
counts are in the commit 2a message; the counts of this file are spelled in
words there, as in the rev 2 record, so that no wrap can start a line with a
number and a period.
