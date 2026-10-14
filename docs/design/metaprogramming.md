# Metaprogramming

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Status](#status)
-   [Overview](#overview)
-   [Compile-time evaluation in the 0.1 toolchain](#compile-time-evaluation-in-the-01-toolchain)

<!-- tocstop -->

## Status

> **Fork status (2026-10-14).** No accepted proposal designs Carbon
> metaprogramming. This page used to point to
> [proposal PR 89](https://github.com/carbon-language/carbon-lang/pull/89),
> which has no accepted record in this repository, and the 0.1 milestone
> defers the
> [long tail of metaprogramming features](/docs/project/milestones.md#features-explicitly-deferred-until-at-least-02)
> to at least 0.2. The [overview](#overview) below states the direction,
> unchanged. What the 0.1 toolchain provides is compile-time evaluation,
> documented in
> [Compile-time evaluation in the 0.1 toolchain](#compile-time-evaluation-in-the-01-toolchain);
> [templates](templates.md) are its other compile-time facility.

## Overview

Carbon provides metaprogramming facilities that look similar to regular Carbon
code. These are structured, and do not offer inclusion or arbitrary
preprocessing of source text such as C and C++ do.

## Compile-time evaluation in the 0.1 toolchain

The toolchain evaluates constant expressions during compilation wherever the
language needs a constant, such as an array bound, a type, or a template
argument. Two function modifiers extend this to calls. Accepted proposals 7140
and 7697 and [function types](functions.md#function-types-and-values) use
`musteval fn` in examples, no proposal and no other design page shows
`eval fn` in an example, and no proposal designs either modifier yet:

-   an `eval fn` may be called during compilation when its arguments are
    constants, and may also be called at run time;
-   a `musteval fn` may only be called with constant arguments, so its result is
    always computed during compilation.

Compile-time evaluation runs ordinary function bodies, with control flow and
recursion, and can compute types, so an `eval fn` that returns `type` acts as a
type function:

```carbon
import Core library "io";

// An `eval fn` may be called during compilation, here for an array bound.
eval fn Square(n: i32) -> i32 { return n * n; }

var table: array(i32, Square(2)) = (1, 2, 3, 4);

// Compile-time evaluation can compute types, and may recurse.
eval fn IntOfWidth(wide: bool) -> type {
  if (wide) {
    return i64;
  }
  return i32;
}

eval fn Factorial(n: i32) -> i32 {
  if (n <= 1) {
    return 1;
  }
  return n * Factorial(n - 1);
}

var slots: array(i32, Factorial(3)) = (0, 0, 0, 0, 0, 6);

// A `musteval fn` may only be called with constant arguments.
musteval fn Twice(n: i32) -> i32 { return n * 2; }

fn Run() -> i32 {
  // An `eval fn` can also be called at run time.
  var n: i32 = 5;
  Core.Print(Square(n));
  Core.Print(table[3] + slots[5]);
  var big: IntOfWidth(true) = 1;
  big = big << 40;
  let small: IntOfWidth(false) = Twice(21);
  // `typeof` names the type of an expression.
  let copy: typeof(small) = small;
  Core.Print(copy);
  if (big > 1000) {
    Core.Print(1);
  }
  return 0;
}
```

This prints `25`, `10`, `42`, and `1`. A `musteval fn` with a runtime argument
is rejected:

```carbon
musteval fn Twice(n: i32) -> i32 { return n * 2; }

fn F(x: i32) -> i32 {
  return Twice(x);
}
```

with ``non-constant call to compile-time-only function``. A plain `fn` with a
body is not evaluated during compilation (only `eval` and `musteval`
functions, and builtin functions such as the prelude's operator functions,
are):

```carbon
fn Three() -> i32 { return 3; }

var a: array(i32, Three()) = (0, 1, 2);
```

reports `array bound is not a constant`. A local compile-time binding is not yet
supported:

```carbon
fn F() -> i32 {
  let template N: i32 = 3;
  return N;
}
```

reports ``semantics TODO: `local generic `let` bindings are currently
unsupported` `` (fork work item W-031).

Other limits of the 0.1 toolchain: a `musteval fn` cannot yet pass its own
parameters to another `musteval fn` (pinned by
`toolchain/check/testdata/function/call/eval_musteval.carbon`); compile-time
recursion with no base case is not diagnosed, and the compiler runs out of stack
(fork work item W-184); `if` expressions and `and`/`or` are not supported
outside a function body (W-036). There is no syntax for reflection or code
generation, and no textual macros: the only macros are C++ object-like macros,
imported as constants ([Importing C/C++ macros](interoperability/macros.md)).
