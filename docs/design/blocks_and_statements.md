# Blocks and statements

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Status](#status)
-   [Overview](#overview)
-   [Statements in the 0.1 toolchain](#statements-in-the-01-toolchain)

<!-- tocstop -->

## Status

> **Fork status (2026-10-14).** The [overview](#overview) below is the
> original sketch, kept unchanged. Its rules are those of accepted proposal 162
> (basic syntax), whose grammar makes a block one kind of statement, and of
> proposal 2665 (semicolons terminate statements); each statement has its own
> accepted proposal, cited in
> [Statements in the 0.1 toolchain](#statements-in-the-01-toolchain), which
> documents what the 0.1 toolchain implements. One difference: the toolchain
> does not accept a block on its own as a statement, so the overview's second
> example is rejected.

## Overview

The body or definition of a function is provided by a block of code containing
statements, much like in C or C++. The body of a function is also a new, nested
scope inside the function's scope (meaning that parameter names are available).
Statements within a block are terminated by a semicolon. Each statement can,
among other things, be an expression. Here is a trivial example of a function
definition using a block of statements:

```
fn Foo() {
  Bar();
  Baz();
}
```

Statements can also themselves be a block of statements, which provide scopes
and nesting:

```
fn Foo() {
  Bar();
  {
    Baz();
  }
}
```

## Statements in the 0.1 toolchain

A function body is a block: statements between `{` and `}`, run in order. In
the 0.1 toolchain a statement is one of:

-   an expression statement, such as a call, ending in `;`;
-   a declaration: `var` (proposal 339), `let`, `returned var` (proposal 257),
    or a local `alias`, `class`, or `fn`;
-   an assignment `=`, a compound assignment such as `+=` or `%=`, or `++` and
    `--` ([Assignment](assignment.md), proposal 2511);
-   `if`, with `else if` and `else` (proposal 285);
-   `while` (proposal 340), and `for` over an array, a range such as
    `Core.Range(4)`, or another type that implements `Core.Iterate` (proposals
    353 and 1885), with `break` and `continue` in either;
-   `return` with or without a value (proposals 415 and 538), and `return var;`
    for a `returned var`;
-   `match`, and the pattern forms `if (let ...)`, `while (let ...)`, and
    `let ... else`, which only the fork's toolchain implements
    ([`match` in the 0.1 toolchain](pattern_matching.md#match-in-the-01-toolchain),
    [Refutable pattern bindings](pattern_matching.md#refutable-pattern-bindings)).

The body of each `if`, `while`, `for`, and `match` arm is a block and a scope:
a name declared in it is visible from its declaration to the end of the block.

```carbon
import Core library "io";

fn Classify(n: i32) -> i32 {
  if (n < 0) {
    return -1;
  } else if (n == 0) {
    return 0;
  } else {
    return 1;
  }
}

fn MakeSix() -> i32 {
  // `returned var` names the object a later `return var;` returns.
  returned var result: i32 = 1;
  result *= 6;
  return var;
}

fn Run() -> i32 {
  // Declarations are statements: `var`, `let`, and local types and functions.
  var total: i32 = 0;
  let limit: i32 = 5;
  class Pair {
    var a: i32;
    var b: i32;
  }
  fn Add(p: Pair) -> i32 { return p.a + p.b; }

  // A `while` loop with `continue` and `break`.
  var i: i32 = 0;
  while (true) {
    i += 1;
    if (i == 2) {
      continue;
    }
    if (i > limit) {
      break;
    }
    total += i;
  }
  // Expression statements, assignment, and increment.
  Core.Print(total);
  total = Classify(-7);
  ++total;
  Core.Print(total);

  // `for` loops over an array and over a range.
  var sum: i32 = 0;
  let values: array(i32, 3) = (1, 2, 3);
  for (v: i32 in values) {
    sum += v;
  }
  for (k: i32 in Core.Range(4)) {
    sum += k;
  }
  Core.Print(sum);
  Core.Print(Add({.a = 2, .b = 3}) + MakeSix());
  return 0;
}
```

This prints `13`, `0`, `12`, and `11`.

A name declared in a nested block is not visible after it:

```carbon
fn F(b: bool) -> i32 {
  if (b) {
    var inner: i32 = 1;
    inner += 1;
  }
  return inner;
}
```

The toolchain reports ``name `inner` not found``. A function with a return
type must not let control reach the end of its body:

```carbon
fn F(b: bool) -> i32 {
  if (b) {
    return 1;
  }
}
```

This is rejected with
``missing `return` at end of function with declared return type``. In 0.1 the
same rule also applies after a `match` that is exhaustive without a `default`
arm (fork work item W-155, on held PR 54).

A block on its own is not accepted as a statement, although the grammar of
proposal 162 includes it and the overview's second example uses it:

```carbon
fn Bar() {}
fn Baz() {}
fn Foo() {
  Bar();
  {
    Baz();
  }
}
```

The parser reads the `{` as the start of a struct literal and reports
``expected `.field: field_type` or `.field = value` `` (fork work item W-185).
Until that is resolved, a nested scope needs a statement that has a block, such
as `if (true) { ... }`.
