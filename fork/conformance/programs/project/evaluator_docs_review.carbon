// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// SKIP: documentation bullet — beyond its one runnable example (see evaluator_docs_getting_started.carbon, which PASSes), it is arbitrated by document review, not by a runnable program. What exists (the working PARTIAL slice): README.md "## Getting started" gives a concrete nightly-tarball evaluation walkthrough — download carbon_toolchain-<version>.tar.gz from the releases page, unpack, write forty_two.carbon, `carbon compile` / `carbon link`, run — but it is Ubuntu/Debian-only (its link step depends on `sudo apt install libgcc-11-dev`) and it points browser evaluators at carbon.compiler-explorer.com; docs/project/faq.md is a comprehensive 659-line project FAQ (What is Carbon? / status / why build it / alternatives considered / feature-design rationale / how interop and generics work). What is missing (why the bullet is PARTIAL, per fork/gap-analysis.md): docs/guides/ — the directory the bullet's "getting started to FAQs" range should span — contains only glossary.md plus a 12-line README index; there is no language tutorial, no step-by-step evaluation walkthrough beyond the README shell snippet, and no getting-started doc for non-Ubuntu platforms. None of that missing prose has an executable arbiter: a tutorial's absence cannot make a program fail, so this half stays document-review. Un-SKIP by replacing this file with programs transcribed from a real docs/guides tutorial's code samples once one is written (workstream W11 in fork/gap-analysis.md).
//
// Body kept trivially valid so this file stays promotable: once docs/guides
// gains a tutorial, this should morph into that tutorial's first example.

fn Run() -> i32 {
  return 0;
}
