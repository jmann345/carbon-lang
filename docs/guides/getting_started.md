# Getting started with the Carbon toolchain

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

This guide takes you from a machine without Carbon to a running program: which
toolchain to use, which platforms it runs on, how to install it, which system
packages it needs, and how to compile, link and run a first program. The
[tutorial](tutorial.md) continues from there, and the
[evaluator FAQ](evaluator_faq.md) explains the errors you may meet on the way.

<!-- toc -->

## Table of contents

-   [Two toolchains](#two-toolchains)
-   [Platforms](#platforms)
-   [Install the upstream nightly on Linux x86-64](#install-the-upstream-nightly-on-linux-x86-64)
-   [Build this fork's toolchain from source](#build-this-forks-toolchain-from-source)
-   [System packages](#system-packages)
-   [Your first program](#your-first-program)
-   [The first link takes a while](#the-first-link-takes-a-while)
-   [One-step builds](#one-step-builds)
-   [Next steps](#next-steps)

<!-- tocstop -->

## Two toolchains

This repository is a fork of the Carbon Language project, and two toolchains
can run the programs of these guides:

| Toolchain | Where it comes from | Language |
| --- | --- | --- |
| The upstream nightly | A prebuilt download from the upstream project's releases page, for Linux x86-64 only | Upstream Carbon |
| This fork's toolchain | Built from this repository's source | Upstream Carbon, plus choice types whose alternatives carry values, `match`, `Core.Result` and `?`, if-let, unions, `overload fn` and slices |

Each of the fork's seven additions was measured absent from the nightly
`0.0.0-0.nightly.2026.10.12`: the nightly rejects a program that uses it, with
the errors the FAQ lists under
[The compiler rejects a fork feature](evaluator_faq.md#the-compiler-rejects-a-fork-feature).
The tutorial marks the two sections that need this fork's toolchain; the other
eight ran on both.

This fork's GitHub releases page also lists `fork-toolchain-*` prereleases. Do
not use them for this tutorial. The newest, `fork-toolchain-143-ea02513be`
(2026-09-25), predates `Core.Result`, if-let, unions, `overload fn` and slices,
and on Ubuntu 24.04, whose glibc is version 2.39, it does not start; any
command stops with this loader error (measured):

```text
carbon: /lib/x86_64-linux-gnu/libm.so.6: version `GLIBC_2.44' not found (required by carbon)
```

Publishing a current fork toolchain is tracked as W-152; until then, build it
[from source](#build-this-forks-toolchain-from-source).

The browser toolchain that the README links,
[carbon.compiler-explorer.com](http://carbon.compiler-explorer.com/), runs
upstream's toolchain, so it presumably has none of this fork's features
(inferred: not measured by this project).

## Platforms

Each row of this table names the kind of source behind it: "measured" (this
project ran it), "upstream's CI configuration" (upstream's own test matrix
runs upstream's code on that platform, which says nothing about this fork's
code), "this fork's CI record" (what this fork's own runs on that platform
last showed, with the run id), or "not verified by this project".

| Platform | Status | Sources |
| --- | --- | --- |
| Linux x86-64 | The upstream nightly is prebuilt for it; this fork's toolchain builds from source | Measured on Ubuntu 24.04 with glibc 2.39: the nightly download, every tutorial section on this fork's toolchain (a CMake build in that container, not the Bazel route below), and the eight sections that need no fork feature on the nightly. This fork's CI record: hosted conformance run 37402970811 (2026-10-06) built this fork's toolchain with Bazel on ubuntu-22.04 and ran the conformance programs |
| Linux arm64 | No prebuilt toolchain; build this fork from source | Upstream's CI configuration runs upstream's tests on ubuntu-22.04-arm. This fork's CI record: the last run that reached its tests passed there (run 37398447710 at b4416a88e, 2026-10-06); no run of the current trunk has reached a test step, because GitHub Actions is disabled on this repository |
| macOS arm64 | No prebuilt toolchain; build this fork from source; unverified for this fork's current trunk | Upstream's CI configuration runs upstream's tests on macos-14, the end-to-end install test included. This fork's CI record: in runs 37359728074 and 37398447710 the install test passed beside a failing fork-only export test (W-153), and no run of the current trunk has reached a test step. Linking needs Apple's Command Line Tools SDK at `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`, the path the toolchain's source names (not verified by this project) |
| Intel macOS | No prebuilt toolchain; untested | In neither upstream's CI configuration nor this fork's CI record; not verified by this project |
| Windows | Unsupported | The toolchain's source reports that Windows runtimes are untested and not yet supported, and cross-targeting Windows from Linux fails at compile (measured; see [Which platforms are supported?](evaluator_faq.md#which-platforms-are-supported)). WSL 2 running the Linux instructions is the route the [contribution tools guide](/docs/project/contribution_tools.md#windows) describes; not verified by this project |

## Install the upstream nightly on Linux x86-64

In an empty directory, run the README's download and unpack lines, put the
toolchain's `bin` directory on your `PATH`, and check the version:

```shell
VERSION="$(date -d yesterday +0.0.0-0.nightly.%Y.%m.%d)"
wget "https://github.com/carbon-language/carbon-lang/releases/download/v${VERSION}/carbon_toolchain-${VERSION}.tar.gz"
tar -xf "carbon_toolchain-${VERSION}.tar.gz"
export PATH="$PWD/carbon_toolchain-${VERSION}/bin:$PATH"
carbon version
```

The first line it prints has this shape, with the nightly's date and commit:

```text
Carbon Language toolchain version: 0.0.0-0.nightly.YYYY.MM.DD+<commit>
```

This project ran the block with nightly 0.0.0-0.nightly.2026.10.12, whose
version line ends in `+62f1cc6`; a later nightly was not measured. The `export`
line lasts for the current shell: run it again in a new shell, or add it to
your shell's startup file.

Without `wget`, use `curl -fLO` with the same URL. Keep the `-f`: without it,
curl saves GitHub's "Not Found" page under the tarball's name when the nightly
does not exist, and the `tar` line fails next. If the date has no release,
`wget` prints `ERROR 404: Not Found.` and writes no file; pick a date from the
[releases page](https://github.com/carbon-language/carbon-lang/releases), set
`VERSION` to its `0.0.0-0.nightly.YYYY.MM.DD`, and run the remaining lines. See
[The download fails](evaluator_faq.md#the-download-fails-or-tar-says-the-file-is-not-in-gzip-format)
in the FAQ.

## Build this fork's toolchain from source

Install the prerequisites that the
[contribution tools guide](/docs/project/contribution_tools.md#setup-commands)
lists for your platform, then:

```shell
git clone https://github.com/jmann345/carbon-lang
cd carbon-lang
./scripts/run_bazelisk.py build -c opt //toolchain/install:carbon_toolchain_tar
mkdir -p "$HOME/carbon-fork"
tar -xf bazel-bin/toolchain/install/carbon_toolchain-*.tar -C "$HOME/carbon-fork"
export PATH="$HOME/carbon-fork/carbon_toolchain-0.0.0-0.dev/bin:$PATH"
carbon version
```

The clone checks out the default branch, `trunk`. The version line starts with
`Carbon Language toolchain version: 0.0.0-0.dev`.

This block was not run by this project's container, which has no Bazel. Its
Bazel target and its unpack step are those of this fork's hosted conformance
job, which built and ran them in run 37402970811 (2026-10-06, on a
GitHub-hosted ubuntu-22.04 runner with upstream's read-only remote cache): the
build took 9m29.6s, the only measured duration, and `carbon version` printed
`0.0.0-0.dev+unknown`. That job calls `./scripts/run_bazel.py`, a retrying
wrapper; this page uses the README's `./scripts/run_bazelisk.py`, which fetches
Bazelisk itself.

The unpacked tree has the same layout as the nightly's, so every later command
in these guides is the same for both toolchains.

## System packages

The toolchain ships its own Clang, LLD, libc++ and libunwind, but it uses the
system's C library, which on Linux is glibc. The compiler reads glibc's C
headers for any program that imports a C++ header, as the tutorial's hello
world does, and the link reads glibc's C runtime start files (`Scrt1.o`,
`crti.o` and `crtn.o`), the `libc` and `libm` development links, and the
dynamic loader. Nothing from GCC is linked. On Ubuntu 24.04, `dpkg -S` shows
that libc6-dev provides the headers (with the linux-libc-dev package it
depends on), the start files and the development links, and libc6 the loader.
On Debian and Ubuntu, install it with:

```shell
sudo apt install libc6-dev
```

The README's `sudo apt install libgcc-11-dev` works too, but indirectly: the
libgcc development package recommends libc6-dev, and apt installs recommended
packages by default (read from the package metadata of libgcc-13-dev on
Ubuntu 24.04; libgcc-11-dev's own metadata was not available).

| Distribution | Package | Source |
| --- | --- | --- |
| Debian, Ubuntu | `libc6-dev` | Verified with `dpkg -S` on Ubuntu 24.04 |
| Fedora, RHEL | `glibc-devel` | Package name not verified by this project |
| openSUSE | `glibc-devel` | Package name not verified by this project |
| Arch Linux | `glibc` | Package name not verified by this project |
| musl-based distributions | none known | Untested: the toolchain's default target is `x86_64-unknown-linux-gnu` |

The upstream nightly needs glibc 2.34 or newer, the highest glibc symbol
version its binary references. Not tested: a machine with libc6-dev and no GCC
packages at all.

Measured with an empty sysroot standing in for a system without libc6-dev,
compiling the tutorial's hello world stops first with this error:

```text
error: "We don't know how to get the definition of mbstate_t on your platform."
```

and linking the program of the next section stops with this one:

```text
ld.lld: error: cannot open Scrt1.o: No such file or directory
```

## Your first program

Write the README's one-line program:

```shell
echo "import Core library \"io\"; fn Run() { Core.Print(42); }" > forty_two.carbon
```

Then compile it, link it and run it:

```shell
carbon compile --output=forty_two.o forty_two.carbon
carbon link --output=forty_two forty_two.o
./forty_two
```

It prints:

```text
42
```

`carbon compile` checks the source file and writes the object file
`forty_two.o`. The line `import Core library "io"` makes `Core.Print`
available, which prints an integer and a newline.

`carbon link` links the object file with the runtime libraries (libc++,
libunwind and the compiler builtins) and the system's C library into the
executable `forty_two`. The first link on a machine takes longer; see the next
section.

`./forty_two` runs the program, which starts at `Run`. A `Run` without a return
type exits with status 0.

## The first link takes a while

The first `carbon link` on a machine builds the runtime libraries for the
target and caches them. That takes about 20 seconds on an idle four-core Linux
x86-64 machine, and up to twice that or more on a busy one (measured: 19 to 22
seconds idle, 32 at load average 4 to 6, 47 at load average 10.7); later links
take hundredths of a second.

The cache is the `carbon_runtimes` directory under `$XDG_CACHE_HOME`, or under
`$HOME/.cache` when that is not set. The toolchain creates `carbon_runtimes`
but not the directory that holds it: when that directory does not exist, as in
a new account or container, the toolchain builds the runtimes in a temporary
directory that it removes afterwards, so every link takes as long as the first
(measured). Create the directory before the first link:

```shell
mkdir -p "$HOME/.cache"
```

The global option `--runtimes-cache=PATH`, written before the subcommand, puts
the cache in another directory, which must already exist:

```shell
mkdir -p "$HOME/carbon-runtimes-cache"
carbon --runtimes-cache="$HOME/carbon-runtimes-cache" link --output=forty_two forty_two.o
```

To build the runtimes ahead of time, for example for a machine image, run the
`build-runtimes` subcommand with an output directory, and then pass that
directory to the global option `--prebuilt-runtimes`:

```shell
carbon build-runtimes --output-directory="$HOME/carbon-runtimes"
carbon --prebuilt-runtimes="$HOME/carbon-runtimes" link --output=forty_two forty_two.o
```

## One-step builds

`carbon build` compiles and links in one command:

```shell
carbon build -o=forty_two forty_two.carbon
```

It differs from the compile and link commands in three measured ways:

-   The short output option takes an equals sign: `-o=forty_two` works, and
    `-o forty_two` fails; see
    [The short output flag needs an equals sign](evaluator_faq.md#the-short-output-flag-needs-an-equals-sign).
-   Without an output option, the executable is named after the first input
    file, without its `.carbon` extension.
-   It also links the object files of the Core library that `carbon link`
    leaves out, so a program that prints with `Core.PrintStr` links only this
    way; see
    [Linking fails with an undefined symbol in Core](evaluator_faq.md#linking-fails-with-an-undefined-symbol-in-core).

The tutorial uses `carbon compile` and `carbon link`, the commands a build
system runs, and names `carbon build` as the one-step alternative.

## Next steps

-   The [tutorial](tutorial.md): ten complete programs, from hello world to C++
    interop in both directions and a multi-file package.
-   The [evaluator FAQ](evaluator_faq.md), for the errors you may meet.
-   `carbon help`, which lists the subcommands and the global options, and
    `carbon help compile`, which describes the options of one subcommand.
-   The [language design](/docs/design/README.md), which describes the whole
    language, much of which is not implemented yet.
