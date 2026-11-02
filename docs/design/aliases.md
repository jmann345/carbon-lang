# Aliases

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Status](#status)
-   [Overview](#overview)
    -   [Alternatives](#alternatives)
-   [Aliases in the 0.1 toolchain](#aliases-in-the-01-toolchain)

<!-- tocstop -->

## Status

> **Fork status (2026-10-14).** No accepted proposal specifies `alias` yet:
> the [overview](#overview) below is the original sketch, kept unchanged, and
> proposal 3938 records that `alias` "is not fully designed". The syntax that
> the [language overview](README.md#aliases) uses comes from proposal 107 and
> question-for-leads issue 749. What the 0.1 toolchain implements is
> documented, with examples that compile, in
> [Aliases in the 0.1 toolchain](#aliases-in-the-01-toolchain).

## Overview

Naming is one of the things that most often requires careful management over
time -- things tend to get renamed and moved around.

Carbon provides a fully general name aliasing facility to declare a new name as
an alias for a value; everything is a value in Carbon. This is a fully general
facility because everything is a value in Carbon, including types.

For example:

```
alias MyInt = Int;
```

This creates an alias called `MyInt` for whatever `Int` resolves to. Code
textually after this can refer to `MyInt`, and it will transparently refer to
`Int`.

### Alternatives

The syntax here is not at all in a good state yet. We've considered a few
alternatives, but they all end up being confusing in some way. We need to figure
out a good and clean syntax that can be used here.

## Aliases in the 0.1 toolchain

An `alias` declaration gives a second name to something that already has one:
`alias` _name_ `=` _expression_ `;`. The toolchain accepts it at file scope, in
a namespace (`alias NS.Name = ...;`), in a class, and in a function body. The
expression may name a type, a specific of a generic type, a namespace, a
function, a class member (a field, a method, or an interface member), a
file-scope variable, or, unlike the language overview's rule (below), a
constant value. Every use of the alias is a use of the
original entity: a member alias of a field reads and writes that field, and an
alias of a variable names the same storage.

```carbon
import Core library "io";

namespace Geometry;
fn Geometry.Scale() -> i32 { return 10; }

interface Printable {
  fn Print(self);
}

class Point {
  var x: i32;
  var y: i32;
  // A member alias: `p.horizontal` names the field `p.x`.
  alias horizontal = x;
  fn Sum(self) -> i32 { return self.x + self.y; }
  alias Total = Sum;
  // An alias can surface an interface member under a class-member name.
  impl as Printable {
    fn Print(self) { Core.Print(self.x * 100 + self.y); }
  }
  alias PrintToScreen = Printable.Print;
}

// File-scope aliases of a type, a namespace, a function, a constant value,
// and a specific of a generic class.
alias Coord = Point;
alias Geo = Geometry;
alias Scale = Geometry.Scale;
alias Limit = 4;

class Box(T: type) {
  var item: T;
}
alias IntBox = Box(i32);

var calls: i32 = 0;

fn Run() -> i32 {
  // A local alias of a file-scope variable names the same storage.
  alias count = calls;
  count += 1;
  let p: Coord = {.x = 3, .y = Limit};
  Core.Print(p.horizontal);
  Core.Print(p.Total());
  p.PrintToScreen();
  Core.Print(Geo.Scale() + Scale());
  let b: IntBox = {.item = 5};
  Core.Print(b.item + calls);
  return 0;
}
```

This prints `3`, `7`, `304`, `20`, and `6`.

Unlike the [language overview](README.md#aliases)'s rule that the right-hand
side is a name and not a value, the toolchain accepts an alias of a constant
value, such as `alias Limit = 4;` above (pinned by
`toolchain/check/testdata/alias/builtins.carbon`). An alias of a runtime value
is rejected:

```carbon
fn Run() -> i32 {
  var a: i32 = 1;
  alias b = a;
  return b;
}
```

The toolchain reports `alias refers to a runtime value`. An alias has no
parameters, so it cannot stand for a family of types:

```carbon
alias Ptr(T: type) = T*;
```

This is rejected with `` `alias` declaration cannot have parameters ``.

An alias of a namespace names the namespace's members, as `Geo.Scale()` does
above, but cannot be used to declare new members:

```carbon
namespace Timezones;
alias TZ = Timezones;
fn TZ.Offset() -> i32 { return 0; }
```

This is rejected with
`name qualifiers are only allowed for entities that provide a scope` (pinned by
`toolchain/check/testdata/namespace/fail_decl_in_alias.carbon`), so the
declaration through an alias in
[Code and name organization](code_and_name_organization/README.md#aliasing) is
not accepted in 0.1; declare members through the namespace's own name.

Aliases follow the access and export rules of other declarations: a
`private alias` is visible only where a `private` member would be, an alias is
exported from its library like any other name and can be re-exported with
`export`, and a diagnostic names a type by the alias that spelled it (testdata
in `toolchain/check/testdata/alias/`: `import_access.carbon`,
`export_name.carbon`, `import.carbon`, `preserve_in_type_printing.carbon`).
