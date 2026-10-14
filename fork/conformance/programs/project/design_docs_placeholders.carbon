// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Goal: design docs documented, cohesive, understandable without placeholders
// SKIP: documentation/goal bullet, arbitrated by document review of docs/design/ (gap row 91), not by a runnable program, as row 88 is (and row 89 on held PR 53). DD-1 (fork/designdocs/plan.md, W-065) replaced the placeholder self-descriptions of templates.md, metaprogramming.md, aliases.md, blocks_and_statements.md and pattern_matching.md's `match` section with dated status notes and measured sections, wrote the interoperability README's eight former TODO sections and three new ones, added docs/design/interoperability/threads_and_atomics.md, and qualified docs/design/README.md's "provisional or placeholder" disclosure (:143-149) with a dated note. The grep arbiter is `python3 fork/designdocs/check_samples.py`: its W2 rule reports placeholder boilerplate (including "provisional or placeholder"), TODO headings, TODO-only sections and empty sections under docs/design/ that its allowlist and qualified list do not name. The documented samples run as documentation-sync programs under their feature bullets (fork/conformance/programs/project/design_docs_*.carbon). No runnable program can distinguish a cohesive design doc from a placeholder one, so this program stays SKIP; the bullet's status is gap row 91's, set by the two document reviews.
//
// Body kept trivially valid so this file compiles if ever exercised; the
// design-doc bullet itself has nothing to run.

fn Run() -> i32 {
  return 0;
}
