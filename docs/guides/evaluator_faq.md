# Evaluator FAQ and troubleshooting

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

This FAQ answers questions about using the Carbon toolchain to evaluate the
language: which toolchain to install, what it needs from the system, and what
the errors you may meet mean and how to get past them. Each entry about an
error quotes the toolchain's text, so you can search this page for it, and
points at the [tutorial](tutorial.md) section that shows the working form.
Questions about the Carbon project itself, such as its status, its goals and
its design choices, are answered in the [project FAQ](/docs/project/faq.md).

<!-- toc -->

## Table of contents

-   [Choosing and installing a toolchain](#choosing-and-installing-a-toolchain)
    -   [Which toolchain do I need?](#which-toolchain-do-i-need)
    -   [Can I download a prebuilt fork toolchain?](#can-i-download-a-prebuilt-fork-toolchain)
    -   [Which platforms are supported?](#which-platforms-are-supported)
    -   [What system packages do I need?](#what-system-packages-do-i-need)
    -   [The download fails, or tar says the file is not in gzip format](#the-download-fails-or-tar-says-the-file-is-not-in-gzip-format)
    -   [Why is the first link slow, and where is the cache?](#why-is-the-first-link-slow-and-where-is-the-cache)
-   [Building programs](#building-programs)
    -   [Linking fails with an undefined symbol in Core](#linking-fails-with-an-undefined-symbol-in-core)
    -   [A C++ header is not found](#a-c-header-is-not-found)
    -   [An imported package API is not found](#an-imported-package-api-is-not-found)
    -   [The compiler only outputs one of several files](#the-compiler-only-outputs-one-of-several-files)
    -   [C++ objects built with g++ fail to link](#c-objects-built-with-g-fail-to-link)
    -   [A function ending in a match needs a return](#a-function-ending-in-a-match-needs-a-return)
    -   [The compiler rejects a fork feature](#the-compiler-rejects-a-fork-feature)
    -   [Compiling a C++ import fails inside libc++](#compiling-a-c-import-fails-inside-libc)
    -   [The main file's package declaration is rejected](#the-main-files-package-declaration-is-rejected)
    -   [The short output flag needs an equals sign](#the-short-output-flag-needs-an-equals-sign)
    -   [How is the exit code set?](#how-is-the-exit-code-set)
-   [Language and interop](#language-and-interop)
    -   [Can separately compiled C++ call my Carbon functions?](#can-separately-compiled-c-call-my-carbon-functions)
    -   [Which C++ standard library does Carbon use?](#which-c-standard-library-does-carbon-use)
    -   [What is implemented, and what is only designed?](#what-is-implemented-and-what-is-only-designed)
    -   [Can I try Carbon in a browser?](#can-i-try-carbon-in-a-browser)
-   [Questions about the project](#questions-about-the-project)

<!-- tocstop -->

## Choosing and installing a toolchain

### Which toolchain do I need?

For eight of the tutorial's ten sections, either toolchain of
[Getting started](getting_started.md#two-toolchains) works: the upstream
nightly 0.0.0-0.nightly.2026.10.12 ran them, and so did this fork's toolchain.
A later nightly was not measured; if one fails a section labelled for both,
use this fork's toolchain. The sections
[Choice types and match](tutorial.md#choice-types-and-match) and
[Errors as values](tutorial.md#errors-as-values) need this fork's toolchain.
The nightly rejects them; their first errors are:

```text
error: semantics TODO: `choice alternatives with parameters are not yet supported`
error: semantics TODO: `HandleMatchIntroducer`
error: member name `Result` not found in `Core`
```

### Can I download a prebuilt fork toolchain?

Not a current one. This fork's GitHub releases page lists `fork-toolchain-*`
prereleases, but the newest, `fork-toolchain-143-ea02513be` (2026-09-25),
predates `Core.Result`, if-let, unions, `overload fn` and slices. On
Ubuntu 24.04, whose glibc is version 2.39, it does not start (measured):

```text
carbon: /lib/x86_64-linux-gnu/libm.so.6: version `GLIBC_2.44' not found (required by carbon)
```

Build this fork's toolchain from source instead, as
[Getting started](getting_started.md#build-this-forks-toolchain-from-source)
describes. Publishing a current one is tracked as W-152.

### Which platforms are supported?

Linux x86-64 is measured, on Ubuntu 24.04, with the prebuilt upstream nightly
and with this fork's toolchain. Linux arm64 and macOS arm64 have no prebuilt
toolchain: build this fork from source. Upstream's CI configuration runs
upstream's tests on both. This fork's CI record shows that its last arm64 run
that reached its tests passed (run 37398447710), and that on macOS the install
test passed beside a failing fork-only export test (W-153), so macOS is
unverified for this fork's current trunk. Intel macOS is in no CI. Windows is
unsupported, and cross-targeting it from Linux fails at compile (measured):

```text
error: unsupported option '-fPIE' for target 'x86_64-pc-windows-msvc'
```

On Windows, WSL 2 running the Linux instructions is the route the
[contribution tools guide](/docs/project/contribution_tools.md#windows)
describes; it is not verified by this project. The
[platform table](getting_started.md#platforms) gives the sources of each row.

### What system packages do I need?

On Linux, glibc's development files. The compiler reads glibc's C headers for
any program that imports a C++ header, and the link needs glibc's C runtime
start files and the `libc` and `libm` development links. On Debian and Ubuntu,
run `sudo apt install libc6-dev` (verified with `dpkg -S` on Ubuntu 24.04). The
README's `sudo apt install libgcc-11-dev` also works, because the libgcc
development package recommends libc6-dev and apt installs recommended packages
by default. Other distributions' package names are listed, unverified, under
[System packages](getting_started.md#system-packages). The upstream nightly
also needs glibc 2.34 or newer.

Measured with an empty sysroot standing in for a system without libc6-dev,
compiling a program that imports a C++ header stops first with the first line
below, and linking any program stops with the second:

```text
error: "We don't know how to get the definition of mbstate_t on your platform."
ld.lld: error: cannot open Scrt1.o: No such file or directory
```

### The download fails, or tar says the file is not in gzip format

There is no nightly for the date in `VERSION`. `wget` then prints this line,
exits with status 8 and writes no file:

```text
ERROR 404: Not Found.
```

`curl -LO`, without `-f`, exits with status 0 and saves GitHub's nine-byte "Not
Found" page under the tarball's name, and the `tar` line then fails with:

```text
gzip: stdin: not in gzip format
```

`curl -fLO` reports the failure instead and writes no file:

```text
curl: (22) The requested URL returned error: 404
```

Pick a date from the
[releases page](https://github.com/carbon-language/carbon-lang/releases), set
`VERSION` to its `0.0.0-0.nightly.YYYY.MM.DD`, delete any file a failed `curl`
saved, and run the download again. Measured with the date 2001.01.01.

### Why is the first link slow, and where is the cache?

The first `carbon link` on a machine builds the runtime libraries (libc++,
libunwind and the compiler builtins) and caches them: about 20 seconds on an
idle four-core machine, and longer under load (the guide linked below lists
the measurements). Later links take hundredths of a second. The cache is
`carbon_runtimes` under `$XDG_CACHE_HOME`, or under `$HOME/.cache`; the global
option `--runtimes-cache=PATH` moves it to a directory that must already
exist, and the `build-runtimes` subcommand with the global option
`--prebuilt-runtimes` builds the runtimes ahead of time.

If every link is that slow, the directory that should hold the cache is
missing: the toolchain does not create `$HOME/.cache` or `$XDG_CACHE_HOME`, and
without it builds the runtimes in a temporary directory each time (measured).
Run `mkdir -p "$HOME/.cache"`. See
[The first link takes a while](getting_started.md#the-first-link-takes-a-while).

## Building programs

### Linking fails with an undefined symbol in Core

```text
ld.lld: error: undefined symbol: _CPrintStr.Core
```

`carbon link` adds only the object files of the Core prelude to the link, and
`Core.PrintStr` is defined in another part of the Core library. Build the
program with `carbon build`, which links the rest of the Core library (see
[One-step builds](getting_started.md#one-step-builds)), or print integers with
`Core.Print` and text through C++, as the tutorial's
[Hello, world](tutorial.md#hello-world) does.

### A C++ header is not found

A quoted header in `import Cpp library "..."` is looked up relative to the
directory the compile runs in, not the directory of the importing file. For
example, if `sub/main.carbon` imports `"seven.h"`, which sits beside it in
`sub/`, then `carbon compile --output=main.o sub/main.carbon` run from the
parent directory fails with:

```text
error: 'seven.h' file not found
```

Run the compile from the directory that holds the header, or name that
directory with `--clang-arg=-I<dir>`, or with `-I<dir>` after a `--` that ends
the Carbon arguments; the two options give the same object file. See
[Linking your own C++ library](tutorial.md#linking-your-own-c-library).

### An imported package API is not found

```text
error: imported API 'Geometry' not found
```

The file that imports a package was compiled without that package's API file.
Pass the API file first, and `--output-last-input-only` so that only the last
file's object file is written:

```shell
carbon compile --output-last-input-only --output=main.o geometry.carbon main.carbon
```

Or build every file in one step with `carbon build`. See
[A multi-file package](tutorial.md#a-multi-file-package).

### The compiler only outputs one of several files

```text
warning: only outputting main.carbon to y.o, skipping output of 2 input files; pass `--output-last-input-only` to silence this warning
```

`carbon compile` with several input files and one `--output` writes the object
file of the last input only. Compile each file of a package in its own command
with the files it needs and `--output-last-input-only`, as
[A multi-file package](tutorial.md#a-multi-file-package) does.

### C++ objects built with g++ fail to link

It depends on the C++ code; both cases were measured. C++ code that uses no
part of the C++ standard library, compiled by `g++` or by the system's
`clang++`, links with `carbon link`. C++ code that uses the standard library
does not, because `carbon link` links libc++, while `g++` and a system
`clang++` that uses libstdc++'s headers compile against libstdc++, whose names
differ:

```text
ld.lld: error: undefined symbol: std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char>>::basic_string()
```

Compile such C++ files with `carbon clang`, or with the toolchain's
`lib/carbon/llvm/bin/clang++`, as
[Linking your own C++ library](tutorial.md#linking-your-own-c-library) does.
Passing libstdc++ by path after `--` also links (measured on this fork's
toolchain):

```shell
carbon link --output=main main.o strlib.o -- /usr/lib/x86_64-linux-gnu/libstdc++.so.6
```

That holds only while no standard-library object crosses between the `g++`
code and the rest of the program, because the two libraries' types are
distinct.

### A function ending in a match needs a return

```text
error: missing `return` at end of function with declared return type
```

A `match` with no `default` arm, even one that covers every alternative of a
choice, is not treated as returning on every path, so a function whose arms
all `return` still needs a `return` after the `match`. Add a `default` arm, or
a `return` after the `match`, or assign a variable in the arms and return it
once, as [Choice types and match](tutorial.md#choice-types-and-match) does.
Measured on this fork's toolchain; the upstream nightly rejects `match` itself.

### The compiler rejects a fork feature

The upstream nightly does not implement this fork's language additions. With
nightly 0.0.0-0.nightly.2026.10.12, the first errors were these lines, in
order for a choice alternative that carries values, `match`, `Core.Result`,
if-let (the error points at the `let`), `union` and `overload fn` (both give
the same line), and `Core.Slice`:

```text
error: semantics TODO: `choice alternatives with parameters are not yet supported`
error: semantics TODO: `HandleMatchIntroducer`
error: member name `Result` not found in `Core`
error: expected expression
error: unrecognized declaration introducer
error: member name `Slice` not found in `Core`
```

Use this fork's toolchain for these features. A fork toolchain built before
commit a27059915 (2026-09-27) also lacks `Core.Result`, and the stale
`fork-toolchain-*` prereleases lack if-let, unions, `overload fn` and slices
too; see
[Can I download a prebuilt fork toolchain?](#can-i-download-a-prebuilt-fork-toolchain).

### Compiling a C++ import fails inside libc++

```text
error: "We don't know how to get the definition of mbstate_t on your platform."
```

The full line starts with the path of libc++'s `__mbstate_t.h` inside the
toolchain, and more errors follow, such as `'ctype.h' file not found`. The C
library's headers are missing: install glibc's development files, which are
`libc6-dev` on Debian and Ubuntu. This was measured with an empty sysroot
standing in for a system without libc6-dev; see
[What system packages do I need?](#what-system-packages-do-i-need).

### The main file's package declaration is rejected

```text
error: `Main//default` must omit `package` declaration
```

The file that defines `Run` has no package declaration: delete its
`package Main;` line. Other packages, such as `Geometry` in
[A multi-file package](tutorial.md#a-multi-file-package), do declare
themselves.

### The short output flag needs an equals sign

```text
error: option `-o` (short for `--output`) requires a value to be provided and none was
```

`carbon build -o forty_two forty_two.carbon` fails with this line; write
`carbon build -o=forty_two forty_two.carbon` instead.

### How is the exit code set?

A `Run` without a return type exits with status 0. A `Run` that returns `i32`
exits with the value it returns: `fn Run() -> i32 { return 3; }` exits with
status 3. On this fork's toolchain, `Run` may also return `Core.Result((), E)`;
an error then prints this line to stderr and exits with status 1:

```text
carbon: `Main.Run` returned `.Err` of type `i32`; exiting with code 1
```

## Language and interop

### Can separately compiled C++ call my Carbon functions?

Not yet: the toolchain generates no C++ header for Carbon code, and none of
`carbon compile`, `carbon link` and `carbon build` has an option for one. C++
written in the Carbon file itself can: after `import Cpp;`, an `inline Cpp`
block sees the Carbon functions declared above it in the `Carbon` namespace,
as [Calling Carbon from C++](tutorial.md#calling-carbon-from-c) shows.

### Which C++ standard library does Carbon use?

LLVM's libc++. The first link builds it, with libunwind and the compiler
builtins, into the runtimes cache, `carbon link` links it into every program,
and C++ code that the toolchain compiles uses its headers. This fork's
toolchain also installs `lib/carbon/include/carbon/expected.h`, which defines
`Carbon::expected`, the C++ view of an exported Carbon function's `Core.Result`
return type; the toolchain adds that directory to the include path of the C++
code it compiles.

### What is implemented, and what is only designed?

Much of the [language design](/docs/design/README.md) is not implemented yet,
and the design documents note their own placeholders. For this fork,
[fork/gap-analysis.md](/fork/gap-analysis.md) holds a table of the 0.1
milestone's bullets with each one's status and evidence, and
[fork/conformance/README.md](/fork/conformance/README.md) lists the conformance
programs that test what is implemented.

### Can I try Carbon in a browser?

Yes, with upstream's toolchain:
[carbon.compiler-explorer.com](http://carbon.compiler-explorer.com/), which the
README links. It runs upstream's toolchain, so it presumably has none of this
fork's features (inferred: not measured by this project).

## Questions about the project

The [project FAQ](/docs/project/faq.md) answers questions about Carbon itself,
including:

-   [What is Carbon's status?](/docs/project/faq.md#what-is-carbons-status)
-   [How will Carbon's bidirectional C++ interoperability work?](/docs/project/faq.md#how-will-carbons-bidirectional-c-interoperability-work)
-   [How do Carbon generics differ from templates?](/docs/project/faq.md#how-do-carbon-generics-differ-from-templates)
-   [Where should I ask questions about Carbon Language?](/docs/project/faq.md#where-should-i-ask-questions-about-carbon-language)
