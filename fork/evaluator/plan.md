<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

# Evaluator documentation plan: getting started, tutorial, FAQ, transcribed programs (EV-1: W-062)

**Status:** rev 1, 2026-10-13 — PLAN, awaiting the two plan reviews of
R29(c). Branch `claude/carbon-fork-0-1-ev` off trunk 80a11e7f0, whose
toolchain sources are identical to 0bdce60a5 (the only later trunk commits
are fork/ORCHESTRATION.md stamps). Trunk's floor is **128 PASS / 0 FAIL / 22
SKIP over 150 programs**, 48/56 bullets (fork/conformance/out/scoreboard.json
`totals`, generated 2026-10-06); the gap-analysis header is **30 DONE / 21
PARTIAL / 4 MISSING / 1 DESIGN-ONLY** (fork/gap-analysis.md:18); the ledger's
max id is W-125 on trunk and W-150 over every live branch (SAFE-1, PR 53),
with W-151 reserved for SC-1's renumber, so this workstream's residue ids
start at W-152 and are allocated at discharge (§8.6). Three PRs are open and
held against 0bdce60a5 (PR 51 UA-2, PR 52 CM-1, PR 53 SAFE-1;
fork/ORCHESTRATION.md:52-67); every count below is a DELTA from trunk, and
absolutes are restated at rebase (§5). This workstream touches no toolchain
C++, no golden, no BUILD file and nothing under .github/, so it needs no
autoupdate. Its verification is local and enumerated in §8: prek to a
fixpoint, `runner.py --self-test`, the runner on the `project/` filter with
the fork busybox, the sample checker of D-EV-13, and the by-hand runs of §2
on both toolchains. GitHub Actions on the repository is disabled
(fork/ORCHESTRATION.md:13-18), so the hosted conformance run that R9 makes
the record cannot be dispatched: every flip below is "expected, not of
record". Every decision is an R29(a) auto-adopt with a break condition
(§1.G). Line numbers are against 80a11e7f0 and were opened for this plan;
stale citations are corrected in §0.2.

**Toolchains, named once.** _F_ is the fork toolchain built in this
container from trunk 0bdce60a5 sources,
`/home/user/carbon-build/carbon-trunk/install/bin/carbon` (busybox
`.../install/lib/carbon/carbon-busybox`); `carbon version` prints "Carbon
Language toolchain version: 0.0.0-0.dev+0bdce60a5". It is the arbiter for
fork features. _N_ is the upstream prebuilt nightly
`/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/bin/carbon`
("0.0.0-0.nightly.2026.10.12+62f1cc6"), fetched from the URL in
/home/user/nightly/url.txt, which has the pattern of README.md:292; it has
none of the fork features. The container is Ubuntu 24.04.5 LTS with glibc
2.39, 4 CPUs and 15 GB. Scratch work for this plan lives under the session
scratchpad's `ev1/` directory, never in the worktree.

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
| 1 | The two toolchains and their layout | PRESENT, measured | Both trees: `bin/carbon` → `../lib/carbon/carbon-busybox`; `lib/carbon/{bazel,core,llvm,runtimes}`; `lib/carbon/llvm/bin` holds clang, clang++, clang-cl, ld.lld, ld64.lld and the LLVM tools. F adds `lib/carbon/include` (the `<carbon/expected.h>` header of EH-B). N's busybox needs only libc.so.6, libm.so.6 and the loader (`ldd`), and its highest versioned glibc symbol is GLIBC_2.34 (25 symbols, `objdump -T`), so N needs glibc 2.34 or newer. F's busybox links this container's own LLVM shared libraries (`/home/user/llvm-build/lib/libLLVM.so.24.0git`, `libclang-cpp.so.24.0git`, `ldd`): it is the container's arbiter, not something an evaluator can download |
| 2 | README forty_two, end to end (README.md:287-315) | WORKS on F and N, measured | The README's echo line verbatim, then `carbon compile --output=forty_two.o forty_two.carbon`: 1.02 s (N) / 0.81 s (F), stderr empty; first `carbon link --output=forty_two forty_two.o` against an empty `--runtimes-cache` directory: 21.6 s (N) / 19.3 s (F); second link 0.040 s / 0.031 s; `./forty_two` prints `42`, exit 0. Repeated with N's `bin` on `PATH` and a bare `carbon`: identical. `carbon build -o=forty_two_b forty_two.carbon`: identical output |
| 3 | Runtimes cache | WORKS, measured | Default location `$XDG_CACHE_HOME/carbon_runtimes`, else `$HOME/.cache/carbon_runtimes` (`carbon help`, the `--runtimes-cache` entry); `carbon --no-threads build-runtimes --output-directory=DIR` on F: 63.6 s single-threaded, producing `clang_resource_dir`, `core`, `libcxx`, `libunwind`; `--prebuilt-runtimes=PATH` uses such a tree instead of building |
| 4 | What `carbon link` reads from the system | MEASURED on F | `carbon link --output=x forty_two.o -- -v`: the Clang prefix adds `-rtlib=compiler-rt -unwindlib=libunwind -stdlib=libc++ -fuse-ld=lld` (toolchain/base/clang_invocation.cpp:132-142), link_driver.cpp:68 adds `--driver-mode=g++`, and ld.lld reads from the system only `Scrt1.o`, `crti.o`, `crtn.o`, `-lc`, `-lm` and the loader `/lib64/ld-linux-x86-64.so.2`; `dpkg -S` puts the first five in libc6-dev and the loader in libc6. CRT begin/end, the builtins, libc++ and libunwind come from the runtimes cache. With `-- --gcc-toolchain=/nonexistent` a warm link and a cold link (17.6 s) both still produce a binary printing 42: nothing from a GCC installation is linked. With `-- --sysroot=<empty dir>`: `ld.lld: error: cannot open Scrt1.o: No such file or directory`, then the same for crti.o, `unable to find library -lm`, `-lc`, and crtn.o |
| 5 | The README's `sudo apt install libgcc-11-dev` (README.md:304-307) | WORKS INDIRECTLY, measured on the analogue | apt metadata of the installed analogue libgcc-13-dev: Depends gcc-13-base, libgcc-s1, libgomp1, libitm1, libatomic1, libasan8, liblsan0, libtsan2, libubsan1, libhwasan0, libquadmath0; **Recommends libc6-dev**. So the README line supplies what the link needs (row 4) only through apt's default install of Recommends; its own comment (:304-306) already says gcc or g++ also suffice. libgcc-11-dev's own metadata is not readable here (the container's apt lists are empty; `apt-cache policy` knows only installed packages) |
| 6 | System headers for C++ interop | MEASURED | `carbon config --json` on N: `CLANG_INCLUDE_DIRS` ends with `/usr/local/include`, `/usr/include/x86_64-linux-gnu`, `/usr/include`, and `CLANG_SYSROOT` is `/`: imported C++ headers such as `<iostream>` reach the system C headers, which libc6-dev (and the linux-libc-dev it depends on) provides on Debian and Ubuntu |
| 7 | Driver help: the flags the guides teach | MEASURED on F | `carbon help` (subcommands build-runtimes, build, clang, compile, config, format, language-server, link, lld, llvm; global `-v`, `--runtimes-cache=PATH`, `--prebuilt-runtimes=PATH`); `carbon help compile` (178 lines; identical to `carbon compile --help`): `--output=FILE`, `--output-last-input-only` ("Only write output for the last input file"), `--clang-arg=CLANG-ARG` or positional Clang args after `--`, `--phase=check`, `--optimize=(none\|debug\|speed\|size)`, `--target` (default x86_64-unknown-linux-gnu); `carbon help link` (43 lines): `--output=FILE`, positional `OBJECT_FILE...`, extra Clang link args after `--`, and "TODO: Support linking binary libraries, both archives and shared libraries"; `carbon help build` (63 lines): `-o, --output=FILE` ("If none is specified, `build` will use the name of the first provided input file"). Measured: `carbon build -o f1 functions.carbon` fails ("option `-o` (short for `--output`) requires a value to be provided"); `-o=f2` works; with no `-o` the output is named `functions` |
| 8 | `Core.PrintStr` under compile + link | FAILS on F and N, measured | A four-line `Core.PrintStr("Hello, world!\n")` program (the shape of examples/hello_world.carbon) compiles, then `carbon link` fails with `ld.lld: error: undefined symbol: _CPrintStr.Core`; link_driver.cpp:149-151 ("TODO: should also be able to link in the rest of the Core object files"); `carbon build -o=psb printstr.carbon` links it and prints `Hello, world!` (0.32 s on F, warm). The repository's own examples/hello_world.carbon therefore links only under the Bazel `carbon_binary` rule or `carbon build` (W-003) |
| 9 | Fork features on N | REJECTED by N, measured | Choice payloads: `` semantics TODO: `choice alternatives with parameters are not yet supported` ``; `match`: `` semantics TODO: `HandleMatchIntroducer` ``; `Core.Result`: ``member name `Result` not found in `Core` `` (the first diagnostics of §2.B samples 5 and 6 on N) |
| 10 | The tutorial samples, by hand | WORKS, measured | The ten samples of §2.B with the three-command compile/link/run of D-EV-6, stderr empty on both toolchains: hello, functions, classes, generics, interop-use-C++, C++-library (with `carbon clang`), call-Carbon and the three-file package print the §4 values and exit 0 on F and on N; choice/match and errors print the §4 values on F and are rejected by N (row 9) |
| 11 | A separately compiled C++ library | WORKS, measured | `carbon clang -- -c rectangle.cpp -o rectangle.o`, `carbon compile --output=main.o main.carbon`, `carbon link --output=main main.o rectangle.o` → `42`, exit 0, on F and on N. An object of the same function (no standard library) compiled by the system `clang++` 21.1.8 or by `g++` 13 also links. A function using `std::string` compiled by `g++` or by the system `clang++` (whose headers are libstdc++'s) fails to link: `ld.lld: error: undefined symbol: std::__cxx11::basic_string<...>::append(unsigned long, char)`; compiled by `carbon clang` it links and prints `10` |
| 12 | Quoted C++ header lookup | MEASURED | `import Cpp library "rectangle.h"` resolves against the working directory, not the importing file's directory: compiling `../main.carbon` from a subdirectory fails with `'rectangle.h' file not found`; `--clang-arg=-I<dir>` and `-- -I<dir>` both fix it and give byte-identical objects (`cmp`) |
| 13 | A multi-file package | WORKS on F and N, measured | `package Geometry;` API file, `impl package Geometry;` implementation file, `import Geometry;` in main: `carbon compile --output=geometry.o geometry.carbon`; `carbon compile --output-last-input-only --output=geometry.impl.o geometry.carbon geometry.impl.carbon`; same for main with `geometry.carbon main.carbon`; `carbon link --output=shapes geometry.o geometry.impl.o main.o` → `12`, `14`. The API object has no symbols (`llvm-nm` prints nothing) and the link also works without it. `carbon build -o=shapes_b main.carbon geometry.carbon geometry.impl.carbon` → same. main alone: `error: imported API 'Geometry' not found`; three inputs with one `--output` and no last-input flag: ``warning: only outputting main.carbon to y.o, skipping output of 2 input files; pass `--output-last-input-only` to silence this warning`` |
| 14 | Diagnostics an evaluator meets | MEASURED on F | A `match` whose arms all `return`, with no return after it: ``error: missing `return` at end of function with declared return type``; `package Main;`: ``error: `Main//default` must omit `package` declaration``; `fn Run() -> i32 { return 3; }` exits 3; `fn Run() -> Core.Result((), i32)` returning `.Err` prints ``carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1`` to stderr and exits 1 |
| 15 | Windows | UNSUPPORTED, source and measured | clang_runtimes.cpp:240-242 and :400-402 return "TODO: Windows runtimes are untested and not yet supported."; link_driver.cpp:59-61 (Clang-driver linking "works well on Unix OSes"). Cross-targeting from Linux, measured: `carbon compile --target=x86_64-pc-windows-msvc` fails with `error: unsupported option '-fPIE' for target 'x86_64-pc-windows-msvc'` (exit 1); `carbon link` with that target prints the same error and then a crash stack dump, on F (exit 134) and on N alike — upstream behavior, recorded in W-059's notes at discharge |
| 16 | Platforms in the repository's CI and releases | SOURCED, not measured | nightly_release.yaml:41 (`runs-on: ubuntu-22.04`), :97-105 (one `//toolchain/install:carbon_toolchain_tar_gz`), :118-127 (one asset `carbon_toolchain-${release_version}.tar.gz`, no OS or CPU in the name), and its header TODO :21-22 ("Build artifacts for all the different OSes ... rather than just x86 Linux"); tests.yaml:29-32 runs `bazel test` on ubuntu-22.04, ubuntu-22.04-arm and macos-14 ("Linux on x86-64 and AArch64, and macOS on AArch64"), which includes toolchain/install/install_test.py:190-202 (`test_carbon_end_to_end`: compile, link and run of `Cpp.std.cout << "Hello from Carbon\n"` from an installed tree; py_test at toolchain/install/BUILD:782-791). No Intel macOS and no Windows runner. On macOS the Clang prefix hard-codes `--sysroot=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk` and `-mlinker-version=705` (toolchain/base/clang_invocation.cpp:148-167): linking there needs Apple's Command Line Tools SDK at that path (source only) |
| 17 | The fork's own GitHub prereleases | STALE, measured | REST listing of the repository's releases: the newest fork toolchain is `fork-toolchain-143-ea02513be` ("Fork toolchain 0.0.0-0.dev @ ea02513be", 2026-09-25, 58 MB), 321 commits behind 0bdce60a5; `core/prelude/types/result.carbon` does not exist at ea02513be (added 2026-09-27 by a27059915, EH-A), and neither does `core/prelude/types/slice.carbon`. Published before R28 (2026-09-26) ended agent use of the owner's runner; nothing has refreshed it since |
| 18 | How the fork toolchain is built from source | SOURCED, not run here | fork_hosted.yaml:106-110 (`./scripts/run_bazel.py build -c opt //toolchain/install:carbon_toolchain_tar`) and :112-120 (unpack `bazel-bin/toolchain/install/carbon_toolchain-*.tar`, then `"$CARBON" version`); the unpacked directory is `carbon_toolchain-0.0.0-0.dev` (the `toolchain` field of fork/conformance/out/scoreboard.json); prerequisites docs/project/contribution_tools.md:46-113 (Debian or Ubuntu: Clang 21 or newer with libc++, LLD, bazelisk), :115-167 (macOS: Homebrew llvm, bazelisk), :169-176 (Windows: WSL). There is no Bazel in this container (task environment), so none of this ran here |
| 19 | Existing evaluator documentation | PARTIAL | README.md:273-363 "Getting started" (browser link :275-276; nightly walkthrough :278-315 for "a recent Ubuntu Linux or similar (Debian, WSL, etc.)", :281-282; reminder :317-321; build from source :323-355; links :357-362); docs/guides/ holds README.md (12 lines, one list item: the glossary) and glossary.md; docs/project/faq.md is 659 lines (9 H2, 34 H3; §0.3); toolchain/docs/driver.md is a 22-line developer stub |
| 20 | examples/ | CONTEXT | examples/hello_world.carbon uses `Core.PrintStr` (row 8); examples/sieve.carbon uses `returned var` and `Core.UnformedInit`; examples/interop/cpp/hello_world.carbon passes strings to C through `Cpp.std.data("...\0")`; examples/advent2024/README.md:13-17 says those samples "are not reflective of expected Carbon style and idioms". None is written for a reader |
| 21 | Interop shapes the conformance suite already proves | LANDED | `import Cpp library "<cctype>"` (code_org/importing_cpp_header.carbon), `import Cpp inline '''...'''` (code_org/importing_cpp_inline.carbon), `import Cpp;` plus a later `inline Cpp '''...'''` that calls `Carbon::Add` (interop/cpp_export_function.carbon), a C++ constructor as `Cpp.Vec2.Vec2(3, 4)` (interop/cpp_type_import_class_enum.carbon), `Cpp.std.vector(i32)` (interop/cpp_span_view.carbon), `for` over a C++ range (interop/cpp_range_member_begin_end_iterate.carbon). COMPILE-ARGS is used only for flags (`--clang-arg=-std=c++20`, `--cpp-exceptions=`), never for an include path; no program imports a quoted user header or links a C++ object; all 12 export goldens under toolchain/check/testdata/interop/cpp/function/export/ reach Carbon from `inline Cpp` or `import Cpp inline`, and no driver option emits a C++ header (`header` occurs in none of the compile, link or build help texts) |
| 22 | Conformance runner facts | MEASURED | compile command runner.py:516-524 (Carbon units only), link :546-551, `run_cmd` passes no `cwd` (:453-462), multi-unit units are `prog_dir.glob("*.carbon")` (:321). `--self-test` on 80a11e7f0: "150 programs parsed, 56 bullets in table, OK" plus the three self-checks; `--filter project/` with F's busybox and a private `--out`: 6 PASS / 6 SKIP in 2.7 s (bullet rollup: the evaluator bullet PASS through evaluator_docs_getting_started.carbon) |
| 23 | Prototype of this plan's programs | MEASURED | A scratch mirror of fork/conformance plus fork/gap-analysis.md with §2.E's programs added and the stub removed: `--self-test` fails only on the stale README table until `--update-readme-table` (ten rows replace one), then "159 programs parsed, 56 bullets in table, OK"; `--filter project/` with F: 15 PASS / 6 SKIP in 7.0 s (every new program PASS except the C++-library SKIP); with N and `--filter project/evaluator`: 8 PASS, 2 COMPILE-FAIL (choice_match, errors: row 9's diagnostics), 1 SKIP. The checker of D-EV-13 passes on a mock page holding the twelve samples in order and reports a one-space edit as a diff |
| 24 | prek | AVAILABLE | `uvx prek --version`: prek 0.5.5. Markdown hooks: rumdl twice (`--fix`, upstream's `.rumdl.toml`, MD013 reflow), check-google-doc-style, markdown-toc, check-links, codespell, check-copyright; Python: ruff-check, ruff-format, ty; JSON: prettier. The four bazel-backed hooks are skipped by name (task environment) |

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
    and slices. No guide points at them (D-EV-5).

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
nightly is the only prebuilt download and has none of them (§0.1 row 9). The
guides say so up front and label every tutorial section with the toolchains
it runs on, measured: eight of the ten samples run on both F and N; choice
and match, and errors as values, need F. The getting-started page gives both
acquisition paths: the upstream nightly (Linux x86-64, prebuilt, measured
here) and the fork built from source with Bazel (the commands the fork's
hosted job runs, not run here).

### §1.C Platforms and system libraries

The platform table states, per row, its source: "measured" (Linux x86-64,
this container) or "from the repository's CI and release configuration"
(§0.1 row 16) — never "works" without a source. The system-library section
states the measured requirement (glibc's development files; no GCC
installation is linked; N needs glibc 2.34 or newer), names libc6-dev for
Debian and Ubuntu as verified by `dpkg -S`, explains the README's libgcc line,
and lists other distributions' package names with the label "not verified
by this project".

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
building programs (one entry per measured diagnostic of §0.1 rows 4, 8, 9,
11-14), language and interop, and a pointer section to docs/project/faq.md.
The tutorial links into it by anchor; the FAQ links back to the tutorial
section that shows the fix.

### §1.F The conformance mapping

Every `carbon` fenced block of tutorial.md is a complete program,
transcribed byte for byte into fork/conformance/programs/project/ under the
bullet "Project: basic evaluator documentation (getting started to FAQs)":
nine single-file programs and one three-unit directory. Eight single-file
programs and the directory run (EXPECT values hand-derived in §4); the
C++-library program is a SKIP with the exact harness evidence (D-EV-12). The
stub
evaluator_docs_review.carbon is deleted, as its own un-SKIP path says;
evaluator_docs_getting_started.carbon stays and its header cites the guide.
fork/evaluator/check_samples.py diffs every block against its program
(D-EV-13).

### §1.G Decisions this plan auto-adopts (R29(a); each with a break condition)

-   **D-EV-1 — Three pages under docs/guides/** (§1.A):
    `getting_started.md`, `tutorial.md`, `evaluator_faq.md`, each with an
    H1, the `<!-- -->` license block and a markdown-toc table of contents.
    Rejected: one long page (the FAQ must be linkable on its own, and the
    getting-started page must stay short enough to follow at a terminal);
    a `docs/guides/tutorial/` directory of per-chapter pages (ten short
    chapters do not justify eleven files). Break condition: tutorial.md
    exceeds about 700 lines, or the evaluator-simulation review (D-EV-19)
    reports a task that needs more than one jump between pages — then split
    the tutorial into per-chapter pages.
-   **D-EV-2 — The guides target this fork's toolchain and label every step
    with the toolchains it runs on** (§1.B). The tutorial's commands use a
    bare `carbon` on `PATH` (measured to work, §0.1 row 2), so the same
    text serves both toolchains. Break condition: an upstream nightly
    accepts choice payloads, `match` and `Core.Result` (re-measured at each
    upstream merge with the two fork-only programs under N) — then the
    "fork toolchain only" labels drop.
-   **D-EV-3 — Platform table with a source per row** (§1.C): Linux x86-64
    — upstream nightly prebuilt, measured; Linux arm64 and macOS arm64 — no
    prebuilt toolchain, build from source, the end-to-end install test runs
    in upstream CI there (tests.yaml:29-32, install_test.py:190-202), macOS
    linking needs the Command Line Tools SDK path of
    clang_invocation.cpp:148-157, labelled "from the repository's CI
    configuration, not measured by this project"; Intel macOS — not in CI;
    Windows — unsupported (clang_runtimes.cpp:240-242), with WSL 2 running
    the Linux instructions as the documented route of
    contribution_tools.md:169-176, labelled not measured. Break condition:
    nightly_release.yaml publishes another platform's artifact, or a
    Windows runner joins tests.yaml — then that row changes source and
    status.
-   **D-EV-4 — System libraries stated as measured** (§0.1 rows 4-6): "the
    link needs glibc's C runtime start files and the libc and libm
    development links; nothing from GCC is linked"; Debian and Ubuntu:
    `sudo apt install libc6-dev` (verified, `dpkg -S`), with one sentence
    on why the README's `libgcc-11-dev` line also works (Recommends);
    Fedora and RHEL `glibc-devel`, openSUSE `glibc-devel`, Arch `glibc`,
    each labelled "package name not verified by this project"; musl-based
    distributions labelled untested (the default target is
    x86_64-unknown-linux-gnu, §0.1 row 7); N needs glibc 2.34 or newer.
    The page also says what was not tested: a machine with libc6-dev and no
    GCC packages at all. Break condition: a distribution's package metadata
    shows the start files in a different package — correct that name and
    drop its label.
-   **D-EV-5 — The fork toolchain comes from source.** getting_started.md
    gives the Bazel route of §0.1 row 18 (`./scripts/run_bazelisk.py build
    -c opt //toolchain/install:carbon_toolchain_tar`, unpack into a
    directory, put its `bin` on `PATH`) with the prerequisites linked to
    contribution_tools.md, labelled "not run by this project's container
    (no Bazel there); the target and the unpack step are those of the fork's
    hosted conformance job". No guide links the stale prereleases (§0.1 row
    17). Residue W-153: publish a current fork toolchain artifact. Break
    condition: a current fork toolchain artifact is published — then
    getting_started.md gains its download path ahead of the source build.
-   **D-EV-6 — Compile and link are the taught path; `carbon build` is the
    shortcut.** Every sample is built by `carbon compile --output=X.o
    X.carbon`, `carbon link --output=X X.o`, `./X` — the README's commands,
    the runner's commands and the commands a build system issues. `carbon
    build` is taught in one getting_started.md section with its measured
    caveats (the `-o=FILE` spelling, the default output name, that it links
    the Core library objects that `link` omits) and is named again only as
    the one-step alternative in the tutorial's package section and in the
    FAQ. Break condition: `carbon link` gains the Core objects
    (link_driver.cpp:149-151) or `carbon build` accepts C++ sources — then
    revisit which path is primary.
-   **D-EV-7 — Output idioms: `Core.Print` for integers, C++ iostream for
    text; no `Core.PrintStr` in any sample.** `Core.PrintStr` does not link
    under compile and link (§0.1 row 8); the hello world prints through
    `Cpp.std.cout`, which is install_test.py's own program shape. The FAQ
    explains the `_CPrintStr.Core` failure and both ways around it. Break
    condition: W-003 lands — then hello world switches to `Core.PrintStr`
    and the FAQ entry is deleted.
-   **D-EV-8 — The ten samples of §2.B are fixed by this plan.** They were
    written from working code (R3: the conformance programs of §0.1 row 21,
    types/classes.carbon, generics/checked_generics.carbon,
    control_flow/match_guard_binding.carbon,
    error_handling/result_prelude_diff.carbon,
    code_org/library_multifile_export/), compile-verified on F and N (R6;
    §0.1 row 10) and avoid every trap of §0.1 row 14 (each value-returning
    `match` assigns in its arms and returns once). The implementer copies
    them; any change is re-run on both toolchains and recorded. Break
    condition: a sample stops compiling on F after a rebase — then fix the
    sample, re-derive §4 and record the change in the commit message.
-   **D-EV-9 — FAQ split and linkage** (§1.E): toolchain questions in
    docs/guides/evaluator_faq.md, project questions stay in
    docs/project/faq.md, which gains one pointer sentence in "Is there a
    demo?" (:107-110). Rejected: adding the questions to docs/project/faq.md
    (a 659-line upstream page about the project; mixing fork toolchain
    troubleshooting into it would raise merge conflicts at every upstream
    merge). Break condition: upstream adds a user-facing FAQ under
    docs/guides — then merge into it at the next upstream merge.
-   **D-EV-10 — No link to CM-1's docs/guides/build_systems.md while PR 52
    is unmerged.** check-links would fail on a trunk without the page, and
    an evaluator must not meet a dead link. At EV-1's rebase onto the trunk
    it merges into: if build_systems.md is there, the rebase fold adds two
    links (getting_started.md's "Next steps" and the FAQ entry on several
    files) and nothing is filed; if not, W-155 is filed for CM-1's landing
    to add them. Break condition: PR 52 merges before EV-1's commit 1 —
    then the links go into commit 1 directly.
-   **D-EV-11 — One program per sample, named
    `project/evaluator_tutorial_<topic>`** (§1.F, §2.E). Each file is the
    license header, a blank line, the directives (bullet verbatim, R7;
    `EXPECT-EXIT: 0`; the hand-derived `EXPECT-STDOUT`), a provenance
    comment, a blank line and the sample byte for byte. The package is the
    directory `project/evaluator_tutorial_package/` (units `geometry.carbon`,
    `geometry.impl.carbon`, `main.carbon`; the runner's own multi-unit
    convention compiles them exactly as the tutorial's commands do, every
    unit with its siblings). The stub is deleted; the getting-started
    program stays with a refreshed header. Rejected: one program holding
    every sample (a failure would not name the section), and
    `.diff.cpp` oracles (D-EV-14). Break condition: the runner gains a
    directive that names a documentation source — then the provenance
    comment becomes that directive.
-   **D-EV-12 — The separately compiled C++ library sample is a SKIP program
    with the exact harness evidence.** The runner builds Carbon units only
    (runner.py:516-524, :546-551, :321) and runs without a `cwd`
    (:453-462), while the sample needs a `carbon clang` compile and an
    include directory relative to where the build runs (§0.1 rows 11-12).
    Its Carbon file is transcribed (so the checker still diffs it) and SKIPs
    with the text of §2.E.2. Residue W-152: a runner channel for C++ units
    in multi-unit programs, with the program directory as the include path.
    Rejected: `COMPILE-ARGS: --clang-arg=-Ifork/conformance/...` (true only
    when the runner starts at the repository root, which nothing enforces)
    and a header-only variant (not the sample the page shows). Break
    condition: CM-1's BUILD-SCRIPT channel is on trunk before commit 2 —
    then this program is re-planned in a dated plan amendment (a script
    under fork/evaluator/ that builds the three files), not ad hoc.
-   **D-EV-13 — The R27 instrument is a checker script, not a runner change.**
    fork/evaluator/check_samples.py (§2.E.4, stdlib only) extracts the column-0
    `carbon` fenced blocks of the three pages in order, requires the block count
    to equal its table (tutorial.md 12; the other two 0), and compares each
    block with its program's text after the leading comment block; it also
    requires the README's forty_two echo line in README.md and in
    getting_started.md and the getting-started program's body to equal what that
    echo writes. Every program header names it. Rejected for now: wiring it into
    `runner.py --self-test` (the R12 hook would then police drift on every
    program edit) because PR 52 rewrites the self-test path and two concurrent
    runner changes would conflict; filed as W-154. Break condition: PR 52 merges
    — then W-154 is unblocked.
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
    makes the same call for row 89). The remaining SKIP is a harness limit
    named in the row, not a documentation gap. Header delta DONE +1,
    PARTIAL −1. Break condition:
    the evaluator-simulation review (D-EV-19) finds a step in the range
    "getting started to FAQs" the pages do not cover, or a step that fails
    as written — then the row stays PARTIAL until it is fixed.
-   **D-EV-17 — Verification is local, and the plan says what cannot run**
    (§8): prek to a fixpoint, `--self-test`, the runner with F, the checker,
    the C++-library commands by hand on F and N. Not run: anything needing
    Bazel (the fork build-from-source commands), any non-Linux or non-x86-64
    platform, a distribution other than Ubuntu 24.04, any hosted workflow.
    Break condition: Actions is re-enabled — then the hosted conformance run
    becomes the record and the "not of record" phrases are removed in a
    records commit.
-   **D-EV-18 — Ids are allocated at discharge, starting at W-152** by
    `grep -o '"W-[0-9]*"'` over work-items.json on trunk and on the head of
    every live `claude/carbon-fork-0-1-*` branch, max+1, skipping W-151
    (reserved for SC-1). Expected: W-152 runner C++ units, W-153 fork
    toolchain artifact, W-154 checker in `--self-test`, and W-155 only if
    D-EV-10's else-branch applies. Break condition: another branch files ids
    first — the allocation takes the then max+1 and §8.6 records the grep.
-   **D-EV-19 — Reviews:** two plan reviews (R29(c)); after commit 2, one
    fresh-context evaluator-simulation document review (process.md north-star
    guard 2: a skeptical C++ developer follows getting_started.md, then the
    tutorial, then looks up the FAQ for the errors met, using only the pages
    and the two toolchains, and reports every step that fails or misleads);
    then one implementation review; a separate fixer each time (R11).
    Break condition: the simulation reports a failing step — the fix lands
    before commit 3.

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

### §2.A docs/guides/getting_started.md (new, about 220 lines)

Title "Getting started with the Carbon toolchain". Sections:

1.  **"Two toolchains"** — a two-row table: the upstream nightly (prebuilt
    for Linux x86-64 only; upstream's language subset) and this fork's
    toolchain (built from this repository; adds choice payloads, `match`,
    `Core.Result` and `?`, if-let, unions, `overload fn`, slices). One
    sentence: the tutorial marks the two sections that need the fork's
    toolchain. One sentence: the browser link of README.md:275-276 runs
    upstream's toolchain, so it has none of the fork's features.
2.  **"Platforms"** — the table of D-EV-3 with a "Source" column: Linux
    x86-64 (prebuilt nightly; measured on Ubuntu 24.04 with glibc 2.39);
    Linux arm64 and macOS arm64 (no prebuilt; build from source; upstream CI
    runs the end-to-end install test there; macOS linking uses the Command
    Line Tools SDK); Intel macOS (not in CI); Windows (unsupported; WSL 2
    with the Linux instructions, not measured).
3.  **"Install the upstream nightly on Linux x86-64"** — this block (the
    README's URL pattern; `curl -LO` instead of `wget`, which minimal images
    lack; the `PATH` line is new and measured):

    ```shell
    VERSION="$(date -d yesterday +0.0.0-0.nightly.%Y.%m.%d)"
    curl -LO "https://github.com/carbon-language/carbon-lang/releases/download/v${VERSION}/carbon_toolchain-${VERSION}.tar.gz"
    tar -xf "carbon_toolchain-${VERSION}.tar.gz"
    export PATH="$PWD/carbon_toolchain-${VERSION}/bin:$PATH"
    carbon version
    ```

    with the expected first line shape `Carbon Language toolchain version:
    0.0.0-0.nightly.YYYY.MM.DD+<commit>` and one sentence: if that date has no
    release, pick one from the releases page.
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

    labelled per D-EV-5, with the expected version prefix `0.0.0-0.dev`. One
    sentence: the result has the same layout as the nightly, so every later
    command is identical.
5.  **"System packages for linking"** — D-EV-4's text: what the link reads
    (the five files and the loader, by name), the Debian and Ubuntu command
    `sudo apt install libc6-dev`, why the README's `libgcc-11-dev` also works,
    the unverified names for Fedora and RHEL, openSUSE and Arch, glibc 2.34
    or newer for the nightly, musl untested, and the exact error a missing
    package produces (§0.1 row 4, in a `text` block).
6.  **"Your first program"** — the README's echo line verbatim (the
    checker of D-EV-13 requires it), then:

    ```shell
    carbon compile --output=forty_two.o forty_two.carbon
    carbon link --output=forty_two forty_two.o
    ./forty_two
    ```

    expected output `42`; one paragraph per command (what each produces).
7.  **"The first link takes a while"** — the runtimes cache: measured 19 to
    22 seconds on four cores for the first link and a few hundredths of a
    second after (§0.1 row 2), the default location, the global
    `--runtimes-cache=PATH` option, and prebuilding with the
    `build-runtimes` subcommand (its `--output-directory=DIR`) and then
    `--prebuilt-runtimes=DIR` (§0.1 row 3).
8.  **"One-step builds"** — `carbon build -o=forty_two forty_two.carbon`,
    the measured `-o=` spelling, the default output name, and that it also
    links the Core library objects (`Core.PrintStr`, FAQ).
9.  **"Next steps"** — the tutorial, the FAQ, `carbon help` and `carbon help
    compile`, docs/design/README.md for the language design.

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
  return 0;
}
```

What to notice: `let` binds an immutable value, `var` a mutable variable,
types follow names; `for` over a range; `if ... then ... else` is an
expression; `Run` may return `i32`, which becomes the exit code.

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

What to notice: a `choice` is a sum type whose alternatives may carry
values; `match` destructures them, needs no `default` when every alternative
is covered, runs only the first matching case (no fall-through), and a guard
is written `if (...)`. The arms assign and the function returns once: a
function that returns from every arm still needs a `return` after the `match`
(FAQ).

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
  return 0;
}
```

What to notice: `Core.Result(T, E)` is a `choice` in the prelude; postfix
`?` propagates the error to the caller; `if (let pattern = value)` runs its
block only when the pattern matches. One sentence: `Run` may itself return
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
C++'s own.

**8. Linking your own C++ library** (three files; both toolchains). The page
shows `rectangle.h` and `rectangle.cpp` in `cpp` fenced blocks:

```cpp
#ifndef RECTANGLE_H_
#define RECTANGLE_H_

// Returns the area of a `width` by `height` rectangle.
int RectangleArea(int width, int height);

#endif  // RECTANGLE_H_
```

```cpp
#include "rectangle.h"

int RectangleArea(int width, int height) { return width * height; }
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
`lib/carbon/llvm/bin/clang++`), because `carbon link` links libc++ and C++
objects compiled against libstdc++ do not link (FAQ); a quoted header is
found relative to the directory the compile runs in, so build from the
directory holding the header or pass `--clang-arg=-I<dir>` (FAQ).

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
inline int SumOfSquaresClamped(int n, int limit) {
  int total = 0;
  for (int i = 1; i <= n; ++i) {
    total += Carbon::Square(i);
  }
  return Carbon::Clamp(total, 0, limit);
}
''';

fn Run() -> i32 {
  Core.Print(Cpp.SumOfSquaresClamped(3, 100));
  Core.Print(Cpp.SumOfSquaresClamped(10, 100));
  return 0;
}
```

What to notice: `import Cpp;` with a later `inline Cpp` block exports the
Carbon functions declared above it into C++'s `Carbon` namespace; C++
compiled separately cannot call Carbon yet, because no header is generated
(FAQ).

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

### §2.C docs/guides/evaluator_faq.md (new, about 250 lines)

Title "Evaluator FAQ and troubleshooting". The introduction names its scope
(using the toolchain) and links docs/project/faq.md for questions about the
project. Every entry quotes the diagnostic in a `text` fenced block and
gives the fix in prose; no `carbon` fenced blocks (the checker's table has
0 for this page; fixes point at the tutorial's samples). Entries, by group,
with their evidence:

| Group | Question (heading wording is the writer's; check-links must pass) | Answer essentials | Evidence |
| --- | --- | --- | --- |
| Choosing and installing | Which toolchain do I need? | the nightly runs sections 1-4 and 7-10; sections 5-6 need the fork's; the diagnostics the nightly prints for them | §0.1 rows 9-10 |
| Choosing and installing | Which platforms are supported? | the platform table's summary and its sources; Windows unsupported; WSL 2 | §0.1 rows 15-16, D-EV-3 |
| Choosing and installing | What system packages does linking need? | glibc development files; libc6-dev; the README's libgcc line; other distributions unverified; the `cannot open Scrt1.o` text | §0.1 rows 4-6 |
| Choosing and installing | Why is the first link slow, and where is the cache? | runtimes build, measured times, cache location, `--runtimes-cache`, `build-runtimes`, `--prebuilt-runtimes` | §0.1 rows 2-3 |
| Building | Linking fails with `undefined symbol: _CPrintStr.Core` | `link` adds only the prelude objects; use `carbon build`, or print through `Core.Print` or C++ | §0.1 row 8 |
| Building | A C++ header is not found (`'x.h' file not found`) | quoted headers resolve against the working directory; `--clang-arg=-I<dir>` | §0.1 row 12 |
| Building | `imported API '...' not found` | compile each file with its package's API file and `--output-last-input-only`, or `carbon build` | §0.1 row 13 |
| Building | `warning: only outputting ...` | the same flag | §0.1 row 13 |
| Building | C++ objects from g++ fail to link (`undefined symbol: std::__cxx11::...`) | the toolchain links libc++; compile C++ with `carbon clang`; plain C-ABI code from any compiler links | §0.1 row 11 |
| Building | `missing return at end of function` after a `match` | reachability does not consult exhaustiveness; assign in the arms and return once (tutorial section 5) | §0.1 row 14 |
| Building | `semantics TODO: ...` or `member name ... not found in Core` | the feature is unimplemented in the toolchain at hand, or needs the fork's; where to check | §0.1 row 9 |
| Building | `package Main;` is rejected | the main file has no package declaration | §0.1 row 14 |
| Building | How is the exit code set? | `Run` returning `i32`; `Run` returning `Core.Result((), E)` on the fork's toolchain (stderr line, exit 1) | §0.1 row 14 |
| Language and interop | Can separately compiled C++ call my Carbon functions? | not yet: no header is generated; C++ written in the Carbon file (`inline Cpp`) can (tutorial section 9) | §0.1 row 21 |
| Language and interop | Which C++ standard library does Carbon use? | libc++, built into the runtimes cache; `<carbon/expected.h>` in the fork's tree | §0.1 rows 1, 4 |
| Language and interop | What is implemented, and what is only designed? | fork/gap-analysis.md per-bullet table, fork/conformance/README.md program table, the design docs' own placeholder notes | gap-analysis.md:34-91 |
| Language and interop | Can I try Carbon in a browser? | README.md:275-276, upstream's toolchain only | §0.1 row 19 |
| Project questions | (pointer section) | links to docs/project/faq.md anchors: status, interop, generics, where to ask | §0.3 |

### §2.D Index and pointers (three upstream-owned files)

1.  **docs/guides/README.md** — after :10, three list items ahead of the
    glossary: `[Getting started](getting_started.md)`,
    `[Tutorial](tutorial.md)`, `[Evaluator FAQ](evaluator_faq.md)`. Dash
    items 1 → 4.
2.  **README.md** — a new paragraph after :276, and a list item after :362 (dash
    items 75 → 76; headings unchanged):

    ```markdown
    For a step-by-step guide that covers other Linux distributions and
    macOS, the toolchain this fork's features need, and a tutorial through
    C++ interop, see the
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

### §2.E Conformance programs and the sample checker

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

    Names: `evaluator_tutorial_hello`, `_functions`, `_classes`, `_generics`,
    `_choice_match` (fork only), `_errors` (fork only), `_interop_use_cpp`,
    `_cpp_library` (SKIP, item 2), `_interop_call_carbon`, each `.carbon`.
2.  **The C++-library program's SKIP line** (directly after its EXPECT-STDOUT
    `//   42` line):

    ```carbon
    // SKIP: harness limitation, not a documentation gap: this sample links a separately compiled C++ unit (rectangle.cpp, built by `carbon clang -- -c`) beside the Carbon object, and runner.py builds only Carbon units (execute_program issues `carbon compile` at runner.py:516-524 and `carbon link` over those objects at :546-551; a multi-unit directory takes *.carbon only, :321); and `import Cpp library "rectangle.h"` resolves the quoted header against the working directory, not the importing file's directory (measured: the same compile run from another directory fails with `'rectangle.h' file not found`), so no COMPILE-ARGS include path is independent of where the runner is started. The tutorial's commands print 42 and exit 0 by hand on 0.0.0-0.dev+0bdce60a5 and on 0.0.0-0.nightly.2026.10.12+62f1cc6 (fork/evaluator/plan.md section 2). Un-SKIP when the runner can build C++ units (W-152), or through CM-1's BUILD-SCRIPT channel once it is on trunk.
    ```

    The id in it is the one §8.6 allocates.
3.  **The package directory** `project/evaluator_tutorial_package/`:
    `geometry.carbon` and `geometry.impl.carbon` are `<license>` + blank +
    the sample verbatim (no directives: the runner rejects directives
    outside main.carbon); `main.carbon` carries the header of item 1 with
    section "A multi-file package" and EXPECT `12`, `14`. The runner
    compiles each unit with its siblings and `--output-last-input-only`
    (runner.py:516-524) — the tutorial's commands plus one extra sibling
    per line, which changes no object (§0.1 rows 13, 23).
4.  **fork/evaluator/check_samples.py** (new, about 120 lines, stdlib only,
    `__copyright__` block as upstream's Python, not executable, run as `python3
    fork/evaluator/check_samples.py` from the repository root): `SAMPLES` maps
    `docs/guides/tutorial.md` to the twelve program paths in page order (the
    nine files of item 1 with the SKIP one eighth, then the package's
    `geometry.carbon`, `geometry.impl.carbon`, `main.carbon`),
    `getting_started.md` and `evaluator_faq.md` to empty lists;
    `carbon_blocks()` collects the bodies between a line that is exactly three
    backticks and `carbon` and the next line that is exactly three backticks;
    `program_body()` drops leading lines that start with `//` or are blank;
    `main()` compares, prints a unified diff per mismatch, checks the echo line
    in README.md and getting_started.md and the getting-started program's body,
    prints `check_samples: N samples, M errors` and exits 1 on any error. The
    prototype that §0.1 row 23 ran is in the scratchpad
    (`ev1/mirror/fork/evaluator/check_samples.py`, ruff-clean); the implementer
    starts from it.
5.  **project/evaluator_docs_review.carbon** — deleted.
6.  **project/evaluator_docs_getting_started.carbon** — header lines 9-19
    rewritten: the program is the echo line that README.md "Getting
    started" and docs/guides/getting_started.md "Your first program" both
    show (the checker enforces the match); the dangling "see
    evaluator_docs_review.carbon" goes; the tutorial's samples are the
    `project/evaluator_tutorial_*` programs. Directives and body unchanged.
7.  **fork/conformance/README.md** — the program table regenerated by
    `--update-readme-table`: the `evaluator_docs_review.carbon` row goes and
    ten rows come (§0.1 row 23's diff: nine `run` or `SKIP` rows and
    `project/evaluator_tutorial_package` as `multi-unit (3 units)`). No
    prose change.

### §2.F Records (fork/)

1.  **fork/gap-analysis.md** — row 90 per §5.3; header :18-30 per §5.2
    (DONE +1, PARTIAL −1; the parenthetical cites the expected scoreboard
    "stated as expected, not of record (Actions disabled)"; :29's "leaving
    variadics and the build-system/documentation rows as the open back half"
    becomes "leaving variadics and the build-system rows as the open back
    half", or, if CM-1 is on trunk, "leaving variadics and Windows as the
    open back half"); §W11 :265-273: the sentence "Evaluator docs are thin
    (glossary only in docs/guides)." becomes "The evaluator guides landed at
    EV-1 (getting started, tutorial, evaluator FAQ)." and the arbiter's
    tutorial clause gains "(met at EV-1: docs/guides/tutorial.md,
    transcribed into project/evaluator_tutorial_*)", merged with CM-1's
    rewrite of the same paragraph if it has landed; the area summary
    :535-537 becomes "Evaluator documentation landed at EV-1: docs/guides
    holds a getting-started guide, a tutorial whose samples are conformance
    programs, and an evaluator FAQ beside the project FAQ;
    toolchain/docs/driver.md remains a developer stub." Bullet strings
    untouched (R7).
2.  **fork/inventory/work-items.json** — W-062: notes prefixed
    "DISCHARGED (fork/evaluator/plan.md EV-1, 2026-10-DD; branch
    claude/carbon-fork-0-1-ev; commits <shas>): ..." with the §0.2 item 3
    correction; evidence re-pinned to the three pages,
    `fork/gap-analysis.md:90`, `:261-273` and
    `fork/conformance/programs/project/evaluator_tutorial_hello.carbon:5`;
    title unchanged. W-002 notes gain §0.2 item 9's sentence; W-059 notes
    gain §0.1 row 15's cross-target measurement; W-003 notes gain "the
    evaluator guides teach `carbon build` and `Core.Print` around it
    (docs/guides/evaluator_faq.md)". New items per D-EV-18, each with kind,
    subsystem, size, the evaluator bullet, evidence and notes naming its
    break condition: W-152 (infra, fork/conformance, S: C++ units and a
    program-directory include path in multi-unit programs; evidence
    runner.py:321, :516-524, the SKIP program's :9), W-153 (infra,
    ci/releases, S: a current downloadable fork toolchain; evidence §0.1 row
    17; blocked on Actions), W-154 (infra, fork/conformance, S: the checker
    inside `--self-test`; blocked_by PR 52's landing), W-155 only per
    D-EV-10. The `source` field gains "Updated 2026-10-DD by the EV-1
    discharge: ...". No license header (JSON); prettier-clean.
3.  **fork/decision-log.md** — `### EV-1: evaluator documentation: getting
    started, tutorial, FAQ, transcribed programs (2026-10-DD)` inserted
    above the newest workstream entry of the landed region (on 80a11e7f0
    that is "### SL-2: ..." at :2863; above CM-1's or SAFE-1's if either
    has merged). Shape of SL-2 and CM-1: opening paragraph (bullet, row 90,
    header before and after, the expected scoreboard "stated as expected,
    not of record", branch and commits); WHAT LANDED by file group; the
    DECISIONS D-EV-1..19 with break conditions in one sentence each;
    REVIEWS; VERIFICATION (what ran and what could not, D-EV-17);
    RESIDUE (W-152.. with evidence); PLAN §0.2 CORRECTIONS (items 1-10);
    the italic V-3a paragraph (the three guide pages are fork-local in an
    upstream directory; README.md's two pointer lines and faq.md's one
    sentence are the only upstream-owned text touched; rename or merge if
    upstream ships its own guides). Any passage quoting a diagnostic that
    holds a doc-style word sits between the ignore and resume markers.
4.  **fork/ORCHESTRATION.md** — a dated paragraph after :52-67 recording the
    EV-1 branch, its commits, the expected flip and the held PR; a Branches
    row `` | `claude/carbon-fork-0-1-ev` | HELD OPEN as PR NN — EV-1
    evaluator guides at <sha> (gap row 90 expected DONE, W-062 discharged,
    W-152..); verification record in the PR; merge when the land sequence
    runs. | ``; §0.2 item 5's quotation fix and item 6's toolchain list; Next
    actions unchanged except W-153 after the Actions decision.
5.  **fork/evaluator/plan.md** (this file) — review fold records, sign-off,
    landed notes.

## §3 Commit structure

The plan's own commit (rev 1) precedes these; the review fold is rev 2.

1.  **`EV-1 (1/3): evaluator guides — getting started, tutorial, FAQ;
    guides index; README and project FAQ pointers`** — §2.A-§2.D. The
    pages' samples are copied from §2.B; prek to a fixpoint with the R31
    counts in the message.
2.  **`EV-1 (2/3): tutorial programs replace the evaluator_docs_review stub;
    sample checker; program table`** — §2.E. Order inside the commit (the
    R12 hook runs `--self-test` after every program edit, and the table is
    stale until all programs exist): write the twelve program files, delete
    the stub, refresh the getting-started header, run
    `--update-readme-table`, then `--self-test`, the checker and the
    runner. The message carries the local runner result and "stated as
    expected, not of record".
3.  **`EV-1 (3/3): discharge — gap row 90, ledger W-062 and residues,
    decision-log entry, ORCHESTRATION, plan landed notes`** — §2.F.

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
| evaluator_tutorial_functions | `30` `3` `2` `1` `0` | 1 + 4 + 9 + 16 = 30; the loop prints 3, 2, 1 and stops at 0; 4 % 2 == 0, so parity 0 |
| evaluator_tutorial_classes | `3` `7` `8` | origin (0, 0); after (3, 4): x = 3, sum 7; after (−1, 2): (2, 6), sum 8 |
| evaluator_tutorial_generics | `18` `20` `19` | 2 × 3 × 3 = 18; 2 × 2 × 5 = 20; 9 + 10 = 19 |
| evaluator_tutorial_choice_match | `12` `15` `0` `100` `200` `300` | 3 × 2 × 2 = 12; 3 × 5 = 15; Empty 0; n = 0 takes the literal case; −4 fails the literal and passes the guard; 9 fails both and takes `default` |
| evaluator_tutorial_errors | `3` `-7` `3` | 12 / 4 = 3; 7 / 0 is `Err(7)`, `?` returns it from `Average`, `Report` prints −7; 9 / 3 = 3 matches `.Ok` |
| evaluator_tutorial_interop_use_cpp | `5` `15` `17` | abs(−5) = 5; 10 + 5 = 15; 2 + 3 + 5 + 7 = 17 |
| evaluator_tutorial_cpp_library (SKIP) | `42` | 6 × 7 = 42 |
| evaluator_tutorial_interop_call_carbon | `14` `100` | 1 + 4 + 9 = 14 ≤ 100; 1 + 4 + ... + 100 = 385, clamped to 100 |
| evaluator_tutorial_package | `12` `14` | 3 × 4 = 12; 2 × (3 + 4) = 14 |

All exit 0 (`Run` returns 0 or `()`). Runner self-test at commit 2: the
three self-checks OK and `self-test: 159 programs parsed, 56 bullets in
table, OK`. Checker: `check_samples: 12 samples, 0 errors`. Local runner
with F's busybox, `--filter project/`: 15 PASS / 6 SKIP, the ten new lines
being nine PASS and the C++-library SKIP; the per-bullet rollup line for
the evaluator bullet stays PASS with 11 programs.

## §5 Conformance and gap-row effect

1.  **Scoreboard delta (expected, not of record):** PASS +9, SKIP −1 +1,
    programs −1 +10. On trunk's floor: **137 PASS / 0 FAIL / 22 SKIP over
    159**, bullets 48/56 unchanged (the evaluator bullet is already PASS
    through evaluator_docs_getting_started.carbon). On PR 51's base
    (131 / 0 / 19 over 150): 140 / 0 / 19 over 159. With PRs 51, 52 and 53
    all merged first (133 / 0 / 17 over 150, 49/56): 142 / 0 / 17 over
    159, 49/56. The delta rule applies; absolutes are never hard-coded.
2.  **Gap header:** DONE +1, PARTIAL −1. On trunk 30 / 21 / 4 / 1 →
    **31 / 20 / 4 / 1**; with SAFE-1 and CM-1 merged first, from 33 / 20 /
    2 / 1 to 34 / 19 / 2 / 1.
3.  **Row 90** (status and evidence cells; bullet cell untouched; the row
    is one line in the table, the wraps below are this plan's):
    `| Project: basic evaluator documentation (getting started to FAQs) |
    DONE | EV-1 (2026-10-DD, fork/evaluator/plan.md): docs/guides/
    getting_started.md (the two toolchains — the upstream nightly and this
    fork built from source — a platform table sourced to the repository's
    CI and release configuration with Linux x86-64 measured, the glibc
    development files linking needs on any distribution, the first program,
    the runtimes cache), docs/guides/tutorial.md (hello world, functions,
    classes, generics, choice and match and Core.Result with ? on the
    fork's toolchain, C++ interop in both directions, a multi-file package)
    and docs/guides/evaluator_faq.md (toolchain questions keyed to measured
    diagnostics; project questions stay in docs/project/faq.md). Every
    tutorial sample is a conformance program transcribed byte for byte
    (fork/evaluator/check_samples.py): nine PASS locally on
    0.0.0-0.dev+0bdce60a5 beside evaluator_docs_getting_started — not of
    record: the hosted run R9 requires is pending with no dispatch date,
    Actions disabled. Residue, each a filed item: the separately compiled
    C++ library sample is SKIP until the runner builds C++ units (W-152); no
    current downloadable fork toolchain (W-153); the sample check is not
    part of --self-test (W-154). |`
4.  **Honesty guard (R9, R16):** the "not of record" phrase is in the row
    itself, not only in the header; the ORCHESTRATION scoreboard line is
    re-quoted from scoreboard.json only (§0.2 item 5), never moved to the
    expected numbers; if the first hosted run shows anything but the nine
    PASS lines and the one SKIP, the row reverts to PARTIAL in the fix
    commit with the log quoted.

## §6 Churn inventory

-   **New files (17):** three guide pages; nine single-file programs; three
    package units; fork/evaluator/check_samples.py; this plan.
-   **Deleted (1):** project/evaluator_docs_review.carbon.
-   **Modified (9):** docs/guides/README.md (+3 items), README.md (+1
    paragraph, +1 item), docs/project/faq.md (+1 sentence),
    project/evaluator_docs_getting_started.carbon (header comment),
    fork/conformance/README.md (table rows), fork/gap-analysis.md (row 90,
    header, §W11, area summary), fork/inventory/work-items.json (W-062,
    W-002, W-003, W-059, new items, `source`), fork/decision-log.md (+1
    entry), fork/ORCHESTRATION.md (paragraph, row, two corrections).
-   **Toolchain C++, goldens, BUILD, .bzl, MODULE, .github: none.** No
    autoupdate; clang-format, fix-cc-deps, buildifier and check-build-graph
    have nothing to see.
-   **prek hooks that fire:** check-copyright (`<!-- -->` on .md, `//` on
    .carbon, `__copyright__` on .py), rumdl twice, check-google-doc-style,
    markdown-toc (the three pages), check-links (every relative link and
    anchor of the pages), codespell, ruff-check, ruff-format and ty on the
    checker, prettier on work-items.json, end-of-file, trailing-whitespace
    and mixed-line-ending on all.
-   **R12 hook:** polices `fork/*` (license headers; `--self-test` after
    each program edit, which reports the stale table until §3 commit 2 runs
    `--update-readme-table`; the R16(b) SKIP-addition check does not fire
    on a new, untracked file); it does not police docs/ or README.md, so
    prek is their only local check.

## §7 Risks and rejected alternatives (falsifiable)

-   **R-1 — A sample breaks on a future toolchain.** Falsifier: COMPILE-FAIL
    or OUTPUT-MISMATCH for an `evaluator_tutorial_*` program on a later run.
    Contingency: fix the sample in the page and the program together (the
    checker refuses one without the other), re-derive §4, record it; never
    SKIP a PASSing tutorial program (R16(b)).
-   **R-2 — The page and the program drift.** Falsifier:
    `check_samples.py` reports a diff. Contingency: none beyond the check;
    W-154 makes it automatic once the runner change is safe.
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
    behind every scoreboard of record.
-   **R-7 — `date -d yesterday` names a date with no nightly.** Falsifier:
    a 404 from `curl`. Contingency: the page's sentence about picking a date
    from the releases page.
-   **R-8 — Merge conflicts with PR 52 and PR 53.** docs/guides/README.md
    (CM-1 appends one item where EV-1 adds three), gap-analysis.md header,
    :29 and §W11 (CM-1 rewrites them), decision-log.md (all insert above
    SL-2), ORCHESTRATION.md and work-items.json. Falsifier: `git rebase`
    stops. Contingency: the conditional texts of §2.F.1, the delta rule of
    §5, and D-EV-10; resolved in the rebase fold with the R31 counts re-run.
-   **R-9 — The stdout interleaving of hello** (C++ `std::cout` only) and
    of interop_use_cpp (`printf` only) has no mixed-stream ordering risk:
    each program writes through one mechanism. Falsifier: OUTPUT-MISMATCH
    with reordered lines. Contingency: none needed.
-   **R-10 — Overclaiming platforms.** Falsifier: a page sentence says
    "works on macOS" without the CI label. Contingency: the review brief of
    D-EV-19 includes a grep for macOS, arm64, Windows and distribution names,
    each of which must carry its source.
-   **Rejected: transcribing samples as a single program per page** — a
    failure would not name the section. **Rejected: a runner change in this
    workstream** (C++ units, or the checker inside `--self-test`) — it would
    conflict with PR 52's runner changes and widen a documentation PR into
    harness work (W-152, W-154). **Rejected: editing README.md's install
    commands** — upstream-owned, and the libgcc line works (§0.1 row 5).
    **Rejected: linking the fork's prereleases** — stale (§0.1 row 17).
    **Rejected: `Core.PrintStr` in samples** — does not link under the
    taught commands (§0.1 row 8). **Rejected: header-only or
    `-I`-in-COMPILE-ARGS versions of the C++-library sample** (D-EV-12).

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
2.  **Conformance, commit 2** (R5: a private output directory, never
    fork/conformance/out):

    ```shell
    cd /home/user/carbon-ev
    python3 fork/conformance/runner.py --self-test
    python3 fork/evaluator/check_samples.py
    python3 fork/conformance/runner.py \
      --toolchain /home/user/carbon-build/carbon-trunk/install/lib/carbon/carbon-busybox \
      --out <scratchpad>/ev1/runner-c2 --filter project/
    ```

    Expected: §4's self-test and checker lines, then 15 PASS / 6 SKIP.
    Optionally the same runner line with N's busybox
    (`/home/user/nightly/tc/carbon_toolchain-0.0.0-0.nightly.2026.10.12/lib/carbon/carbon-busybox`)
    and the filter `project/evaluator`: 8 PASS, 2 COMPILE-FAIL, 1 SKIP, recorded
    as the two-toolchain evidence of D-EV-2, not as a gate.
3.  **By hand, commit 1:** every §2.B sample and command block run from a
    scratch directory with F and with N (choice_match and errors with F
    only), outputs compared with §4; the C++-library block on both (the
    one sample the runner cannot run); the getting-started blocks on N from
    the unpacked tree with `PATH` set (the download itself and the Bazel
    build are not run: no network fetch of a new nightly is needed and there
    is no Bazel).
4.  **What cannot run here, stated in the PR and the decision log:** Bazel
    (the fork build-from-source block); any hosted workflow (Actions
    disabled; R28 forbids the owner's runner); macOS, Windows, Linux arm64
    and any distribution but Ubuntu 24.04 (the platform rows are sourced to
    the repository's CI and release configuration and labelled so).
5.  **Review gates:** the two plan reviews (rev 2 folds them); the
    evaluator-simulation document review and the implementation review of
    D-EV-19.
6.  **Ledger and ids:** run `grep -o '"W-[0-9]*"'
    fork/inventory/work-items.json | sort -u | tail -1` on trunk and on each
    live `claude/carbon-fork-0-1-*` head (local worktrees and remotes),
    record the results in the discharge message, allocate from max+1 with
    W-151 skipped; `python3 -c "import json;
    json.load(open('fork/inventory/work-items.json'))"` succeeds; §2.F.2's
    edits.
7.  **Reconciliation greps at discharge:** `grep -rn evaluator_docs_review
    fork/conformance fork/inventory fork/gap-analysis.md` hits nothing
    (fork/b1/plan.md:179 and the hosted scoreboard.json stay: history and a
    record only a hosted run rewrites); `grep -rn 'W-152\|W-153\|W-154'`
    hits the ledger, row 90, the SKIP line and the decision log; the
    checker reports 12 tutorial samples.
8.  **Decision-log entry, ORCHESTRATION, landed notes** per §2.F.3-5; the
    PR opened and HELD with "awaiting hosted conformance (Actions
    disabled)" and its dispatch list in ORCHESTRATION.

## Hand-off notes for the implementer

-   `<scratchpad>` in this plan is the planning session's scratch directory,
    `/tmp/claude-0/-home-user-carbon-lang/b7af0e83-599b-5459-ba66-18f10d8e737b/scratchpad`;
    its `ev1/` holds the samples, the program generator, the mirror and the
    checker prototype. If it is gone, §2.B and §2.E are complete on their own.
-   Copy the samples from §2.B (or from the scratchpad's `ev1/samples/`, which
    §0.1 rows 10-13 ran); do not retype them. Every `carbon` fenced block in
    tutorial.md is a whole program at column 0, never inside a list; partial
    snippets use inline code. The FAQ has no `carbon` fenced block.
-   The program generator used for §0.1 row 23 is
    `ev1/tools/gen_programs.py` in the scratchpad: it writes the nine
    headers and the package exactly as §2.E specifies from `ev1/samples/`.
    Re-point it at the worktree's programs directory or reproduce its output
    by hand; either way the checker decides.
-   Write the programs, then delete the stub, then `--update-readme-table`.
    Until then the R12 hook reports the stale table after every program
    edit; that is expected.
-   Keep the C++-library SKIP text on one line and its runner.py line
    numbers current: re-open runner.py before committing.
-   Write "PR 52", never a number with a hash prefix; keep flags, negative
    numbers and diagnostics out of line starts (R31); avoid the doc-style
    word list in prose and in code (no Latin abbreviations, no three-letter
    synonym of "by way of", no short form of "repository").
-   Never link docs/guides/build_systems.md unless it is on the base you are
    committing onto (D-EV-10).
-   Never run bazel; never dispatch a workflow; never touch .github/; the
    fork build-from-source block is quoted, not run.
-   Every platform or distribution claim on a page carries its source:
    "measured on Ubuntu 24.04", "from the repository's CI configuration", or
    "not verified by this project".
