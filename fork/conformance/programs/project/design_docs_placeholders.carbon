// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Goal: design docs documented, cohesive, understandable without placeholders
// SKIP: documentation/goal bullet, not an executable language feature — arbitrated by document review of docs/design/, not by a runnable program. The working slice (why gap-analysis marks this PARTIAL, not MISSING): generics (docs/design/generics/: overview.md, terminology.md, details.md plus three appendices), variadics (docs/design/variadics.md), pattern matching in declarations (docs/design/pattern_matching.md), and classes (docs/design/classes.md) are mature proposal-backed designs. The known-missing slice, verified in-tree today: docs/design/templates.md (lines 24-25) and docs/design/metaprogramming.md (lines 20-21) each open with the self-description "This is a skeletal design ... it is a placeholder until we have more time to examine this detail" (docs/design/aliases.md and docs/design/blocks_and_statements.md carry the same boilerplate); the `match` control-flow section of docs/design/pattern_matching.md says of itself "`match` is a skeletal design ... it is a placeholder" (lines 712-714); docs/design/interoperability/README.md has nine "TODO:" section headings plus an inline TODO — several literally empty headings with no body at all (lines 210-218: "TODO: Overload resolution", "TODO: Constructors", "TODO: Struct literals", "TODO: Accessing C++ classes, structs, and members", "TODO: Accessing global variables"); and docs/design/README.md itself warns "This document includes much that is provisional or placeholder" (line 143). No runnable program can distinguish a cohesive design doc from a placeholder one, so this bullet has no executable surface; the features those docs describe are arbitrated separately by the generics/, types/, control_flow/, and interop/ programs in this suite. Re-audit by document review when the skeletal docs and empty interop sections are replaced by accepted proposals.
//
// Body kept trivially valid so this file compiles if ever exercised; the
// design-doc bullet itself has nothing to run.

fn Run() -> i32 {
  return 0;
}
