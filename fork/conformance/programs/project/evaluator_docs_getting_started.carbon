// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-STDOUT:
//   42
//
// The first program of the evaluator documentation: README.md "Getting
// started" and docs/guides/getting_started.md "Your first program" both tell
// an evaluator to write exactly this program with the same command
// (`echo "import Core library \"io\"; fn Run() { Core.Print(42); }" >
// forty_two.carbon`), then `carbon compile` / `carbon link` / run it. This
// file is what that echo writes, verbatim (one line), so the documented first
// step compiles, links and prints 42 on the toolchain under test;
// fork/evaluator/check_samples.py checks that both pages still show the echo
// and that this body is its output. The tutorial's samples are the
// project/evaluator_tutorial_* programs, each transcribed byte for byte from
// docs/guides/tutorial.md.

import Core library "io"; fn Run() { Core.Print(42); }
