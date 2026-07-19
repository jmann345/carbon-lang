// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-STDOUT:
//   42
//
// The executable slice of the evaluator-documentation bullet: the "Getting
// started" walkthrough in README.md (## Getting started) tells an evaluator
// to download a nightly carbon_toolchain tarball, write exactly this program
// (`echo "import Core library \"io\"; fn Run() { Core.Print(42); }" >
// forty_two.carbon`), then `carbon compile` / `carbon link` / run it. This
// file is that documented program verbatim (one line, as the doc's echo
// writes it), proving the getting-started walkthrough's example really
// compiles, links, and prints 42 on the arbiter toolchain — i.e. the
// documented evaluation path works, not just exists. The rest of the bullet
// (FAQ breadth, missing tutorial/walkthrough in docs/guides) is document
// review; see evaluator_docs_review.carbon.

import Core library "io"; fn Run() { Core.Print(42); }
