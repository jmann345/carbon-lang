# Error handling

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
-   [Errors are values](#errors-are-values)
-   [The `Core.Result` type](#the-coreresult-type)
    -   [Declaration](#declaration)
    -   [Constructing results](#constructing-results)
    -   [Consuming results with `match`](#consuming-results-with-match)
    -   [Consuming results with `let ... else` and `if (let ...)`](#consuming-results-with-let--else-and-if-let-)
-   [Error propagation: the postfix `?` operator](#error-propagation-the-postfix--operator)
    -   [Syntax and precedence](#syntax-and-precedence)
    -   [Semantics and desugaring](#semantics-and-desugaring)
    -   [The `Core.Try` interface](#the-coretry-interface)
    -   [Error conversion](#error-conversion)
    -   [Where `?` may appear](#where--may-appear)
    -   [`Optional` and user types](#optional-and-user-types)
-   [The program entry point](#the-program-entry-point)
-   [Interoperating with C++ exceptions](#interoperating-with-c-exceptions)
    -   [The `--cpp-exceptions` compile option](#the---cpp-exceptions-compile-option)
    -   [The fenced boundary: terminate semantics](#the-fenced-boundary-terminate-semantics)
    -   [Catching imports: `Result(T, Cpp.Exception)`](#catching-imports-resultt-cppexception)
    -   [`Cpp.Exception`](#cppexception)
    -   [Exporting fallible Carbon functions: `Carbon::expected`](#exporting-fallible-carbon-functions-carbonexpected)
-   [Unrecoverable errors](#unrecoverable-errors)
-   [Implementation staging](#implementation-staging)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [References](#references)

<!-- tocstop -->

## Overview

Carbon reports recoverable failure through values, not exceptions. A fallible
function returns `Core.Result(T, E)` — a [choice type](sum_types.md) holding
either a success value of type `T` or an error value of type `E` — and the
fallibility of a function is visible in its declared return type, nowhere else.
On top of this vocabulary type, Carbon provides exactly one dedicated
control-flow construct for errors: the postfix
[`?` operator](#error-propagation-the-postfix--operator), which unwraps a
success value or returns the error to the caller. `?` is defined by a
library-level desugaring onto the [`Core.Try`](#the-coretry-interface)
interface, so `Optional` and user-defined types participate in propagation the
same way `Result` does.

At the C++ boundary, exceptions are converted to values, in both directions:

-   C++ exceptions never unwind Carbon stack frames. Every crossing point
    where an exception could otherwise escape is either _fenced_ (a defined
    program termination if an exception escapes) or _catching_ (the exception
    is captured and surfaced to Carbon as `Core.Result(T, Cpp.Exception)`);
    where no exception is possible, calls cross the boundary unchanged.
-   Fallible Carbon functions are exported to C++ as functions returning
    `Carbon::expected<T, E>`, a C++17-compatible analog of C++23's
    `std::expected`.
-   The [`--cpp-exceptions`](#the---cpp-exceptions-compile-option) compile
    option configures this boundary for both standard C++ dialects and
    `-fno-exceptions` dialects.

This design was fixed by fork decision
[F-006](/fork/decision-log.md)
and is delivered in stages; see
[Implementation staging](#implementation-staging) for which pieces depend on
unimplemented features.

## Errors are values

The governing principle is
[errors are values](/docs/project/principles/error_handling.md), accepted as
[proposal #301](https://github.com/carbon-language/carbon-lang/pull/301):

-   A recoverable error is an ordinary value, returned through the ordinary
    return channel. There is no separate error channel, no unwinding, and no
    hidden allocation or runtime machinery on the success path.
-   Errors are never propagated implicitly. Every point where a function can
    early-exit because of an error is marked in the source — with `return`,
    `match`, `let ... else`, or `?`.
-   Fallibility is expressed in the return _type_. Carbon has no
    `noexcept`/`throws`-style effect annotations on function declarations.

Everything below is an elaboration of this principle; nothing below introduces
a second error-reporting mechanism.

## The `Core.Result` type

### Declaration

The prelude defines `Result` as a parameterized choice type:

```carbon
// In package Core.
choice Result(T: type, E: type) {
  Success(value: T),
  Failure(error: E)
}
```

`T` is the _success type_ and `E` is the _error type_. Both are ordinary types;
`E` is not constrained to implement any error interface in 0.1. `Result((), E)`
is the conventional shape for operations with no interesting success value.

The alternative names are `Success` and `Failure`. This matches the vocabulary
already used by choice-type examples in the
[language overview](README.md#choice-types), and follows Carbon's convention of
using whole words rather than abbreviations for names; see
[decision D1](#decisions-within-this-design).

`Result` is a choice type with payloads. Choice-alternative payloads and
`match` semantics are not yet implemented in the toolchain (see
[Implementation staging](#implementation-staging)); the semantics specified
here are normative for when they land.

### Constructing results

Results are constructed like any other choice value, including with the
leading-period shorthand when the type is known from context:

```carbon
fn Open(name: str) -> Core.Result(File, IoError) {
  if (not Exists(name)) {
    // Equivalent to `Core.Result(File, IoError).Failure(...)`.
    return .Failure(IoError.NotFound);
  }
  return .Success(OpenExisting(name));
}
```

There is no implicit wrapping: `return the_file;` in the function above is a
type error. The success and failure paths are both spelled explicitly, per
[errors are values](#errors-are-values).

### Consuming results with `match`

The fully general way to consume a `Result` is a
[`match` statement](pattern_matching.md), which can destructure both
alternatives and is checked for exhaustiveness:

```carbon
fn Report(name: str) {
  match (Open(name)) {
    case .Success(f: File) => {
      Print(f.Size());
    }
    case .Failure(e: IoError) => {
      PrintError(e);
    }
  }
}
```

### Consuming results with `let ... else` and `if (let ...)`

When only one alternative is interesting, the combined match control-flow forms
from fork decision
[F-011](/fork/decision-log.md)
apply to `Result` like to any other choice type. The negative form binds in the
enclosing scope and requires the failure arm to diverge:

```carbon
fn Copy(from: str, to: str) -> Core.Result((), IoError) {
  let .Success(f: File) = Open(from) else {
    return .Failure(IoError.NotFound);
  }
  // `f` is in scope here.
  WriteAll(to, f);
  return .Success(());
}
```

and the positive form scopes the binding to the success path:

```carbon
if (let .Success(f: File) = Open(name)) {
  Print(f.Size());
}
```

These forms are fixed by fork decision
[F-011](/fork/decision-log.md), whose grammar and semantics are recorded in
[fork/design-sprint/if-let.md](/fork/design-sprint/if-let.md); their design-doc
write-up — including amending
[pattern matching](pattern_matching.md#refutability-overlap-usefulness-and-exhaustiveness)'s
enumeration of contexts that permit refutable patterns — is a deliverable of
the F-011 workstream, sequenced alongside this document. This document only
fixes that `Result` is consumed through the one shared pattern grammar — there
is no `Result`-specific unwrapping syntax besides `?`.

## Error propagation: the postfix `?` operator

The dominant consumption pattern for a `Result` is "unwrap the success value,
or return the failure to my caller". Spelling that with `match` or
`let ... else` at every call site is exactly the propagation boilerplate that
the [error-handling principle](/docs/project/principles/error_handling.md)
identifies as a readability hazard. Carbon therefore provides a postfix `?`
operator:

```carbon
fn ReadConfig(name: str) -> Core.Result(Config, IoError) {
  // Each `?` unwraps a success value or returns the failure.
  var f: File = Open(name)?;
  var c: Config = Parse(f)?;
  return .Success(c);
}
```

The success path reads linearly; every point that can early-exit is still
marked, satisfying "errors are values" while removing the nesting.

### Syntax and precedence

`?` is a _suffix operator_: it follows a complete operand expression and takes
nothing on its right.

> _suffix-expression_ `?`

In the precedence ordering of
[expressions](expressions/README.md#precedence), `x?` belongs to the highest
(suffix-operator) precedence group, together with `x.y`, `x->y`, `x.(...)`,
`x->(...)`, `x(...)`, and `x[y]`. The group is _repeating_: suffix operators
chain left-to-right without parentheses, so

```carbon
var n: i64 = Open(name)?.ReadHeader()?.entry_count;
```

parses as `((((Open(name))?).ReadHeader())?).entry_count`, and each `?` applies
to the value produced immediately to its left. Because `?` binds tighter than
every prefix and binary operator, `-x?` is `-(x?)` and `x? + y?` needs no
parentheses.

Two deliberate restrictions keep the token unambiguous:

-   `?` is an expression operator only; it never appears in type position.
    `Core.Result(T, E)` and `Core.Optional(T)` are spelled as ordinary
    parameterized types, not with `?` sugar.
-   The lexer has single tokens `->?` and `:?`. Both spellings come from the
    deduced form bindings of pending
    [proposal #5389](https://github.com/carbon-language/carbon-lang/pull/5389),
    and accepted
    [proposal #7254](/proposals/p007254-replace-and-with-keywords-and-contextual-defaults.md)
    replaces them with the `fwd` binding modifier and a corresponding return
    syntax — explicitly to reclaim `?` punctuation for uses such as this
    operator. In either state no conflict arises: in this design `?` always
    immediately follows a complete suffix expression, a position where neither
    `->` nor `:` can appear, and maximal-munch lexing is unaffected.

### Semantics and desugaring

Let `expr` have type `S`, and let `R` be the declared return type of the
innermost enclosing function. Both `S` and `R` must implement
[`Core.Try`](#the-coretry-interface). Then `expr?` behaves as this expansion:

```carbon
// Desugaring of `expr?`; `__v` and `__b` are compiler-internal names.
match (expr.(Core.Try.Branch)()) {
  case .Success(__v: S.(Core.Try.ContinueType)) => {
    // `__v` becomes the value of the whole `expr?` expression, in place in
    // the enclosing statement.
  }
  case .Failure(__b: S.(Core.Try.BreakType)) => {
    // `__b` implicitly converts to `R.(Core.Try.BreakType)`;
    // see "Error conversion".
    return R.(Core.Try.FromBreak)(__b);
  }
}
```

Because Carbon's [`match`](pattern_matching.md#pattern-match-control-flow) is a
statement — there is no match-expression form in the language — and `case`
bindings are scoped to their arms, this expansion is not literally writable as
Carbon source. It specifies the observable behavior: the evaluation order, the
conversions applied, and the early return. The compiler implements it directly
on the same refutable-match core that the
[F-011](/fork/decision-log.md) `if (let ...)` / `let ... else` forms lower
onto — F-011 records that "a future `?` desugars onto this core" — so `?`
introduces no second pattern-matching construct and no value-yielding `match`
form.

Consequences of defining `?` by this desugaring:

-   The type of `expr?` is `S.(Core.Try.ContinueType)`.
-   `expr` is evaluated exactly once.
-   The early exit on the failure path is an ordinary
    [`return`](control_flow/return.md): local cleanup runs exactly as it would
    for a written-out `return` at the same point, and a function containing
    `?` must satisfy the usual rules for its return type.
-   No new semantic machinery exists at runtime: `?` introduces only a branch
    and a return, and adds no cost to the success path beyond inspecting the
    discriminant.

### The `Core.Try` interface

`?` is open to types other than `Result` through a prelude interface, in the
same way arithmetic operators are open through their operator interfaces:

```carbon
// In package Core.
interface Try {
  // The type produced by `expr?` on the success path.
  let ContinueType: type;
  // The type propagated to the caller on the failure path.
  let BreakType: type;

  // Splits `self` into continue-or-break.
  fn Branch(self) -> Result(ContinueType, BreakType);
  // Rebuilds a value of `Self` from a propagated break value. Used on the
  // *return type* of the enclosing function.
  fn FromBreak(b: BreakType) -> Self;
}
```

The prelude provides the implementations:

```carbon
final impl forall [T: type, E: type] Result(T, E) as Try
    where .ContinueType = T and .BreakType = E {
  fn Branch(self) -> Result(T, E) { return self; }
  fn FromBreak(b: E) -> Self { return .Failure(b); }
}

final impl forall [T: type] Optional(T) as Try
    where .ContinueType = T and .BreakType = () {
  fn Branch(self) -> Result(T, ()) {
    match (self) {
      case .Some(v: T) => { return .Success(v); }
      case .None => { return .Failure(()); }
    }
  }
  fn FromBreak(b: ()) -> Self { return .None; }
}
```

The `Optional` impl depends on `Core.Optional` being a payload-carrying choice
type with alternatives `.Some(value: T)` and `.None`. Today's prelude
`Optional` is a self-described placeholder — a class adapting an
`OptionalStorage` type, with a `HasValue()`/`Get()` API and no choice
alternatives to match on (`core/prelude/types/optional.carbon`). Rebuilding
`Core.Optional` as a choice type is part of the choice-payloads work this
design's B1 stage depends on; see
[Implementation staging](#implementation-staging).

An implementation must uphold: `Branch` consumes `self` and returns exactly one
alternative; `FromBreak` produces a value whose own `Branch` takes the failure
path with an equal break value. The compiler does not verify these laws; they
are the documented contract, like the expectations on comparison operators.

### Error conversion

The break value's type at the `?` site (`S.BreakType`) frequently differs from
the enclosing function's break type (`R.BreakType`) — a function returning
`Result(Config, AppError)` propagates an `IoError` from a lower layer. `?`
bridges this with the ordinary
[implicit conversion](expressions/implicit_conversions.md) machinery: in the
desugaring above, the argument to `R.(Core.Try.FromBreak)` undergoes implicit
conversion from `S.BreakType` to `R.BreakType`, exactly as any argument
converts to a parameter type.

```carbon
// Opting in: an `ImplicitAs` impl allows `IoError` to propagate as
// `AppError` through `?`.
impl IoError as Core.ImplicitAs(AppError) {
  fn Convert(self) -> AppError { return AppError.Io(self); }
}

fn Load(name: str) -> Core.Result(Config, AppError) {
  // `Open` fails with `IoError`; `?` converts it via `ImplicitAs(AppError)`.
  var f: File = Open(name)?;
  ...
}
```

If no implicit conversion exists, the `?` expression is a compile error at that
site. No conversion is ever applied on the success path. Because the rule is
"whatever `ImplicitAs` allows, `?` allows — nothing more", error-type authors
control propagation boundaries by choosing which `ImplicitAs` impls to provide,
and no `?`-specific conversion trait exists. See
[decision D3](#decisions-within-this-design).

### Where `?` may appear

`?` may be used in an expression only when:

-   the expression appears in a function body — including inside a `match`
    `case` arm, where it propagates from the enclosing _function_, not from the
    `match`; and
-   the innermost enclosing function has a _declared_ return type that
    implements `Core.Try`. In particular `?` cannot be used in a function whose
    return type is deduced (`auto`), since the desugaring needs `R` before the
    body is checked, and cannot be used in a function returning plain `()` or
    `i32` (those types do not implement `Try`).

`?` is not permitted at file scope or in initializers of global constants and
variables. The [program entry point](#the-program-entry-point) may use `?` by
declaring a `Result` return type.

### `Optional` and user types

Because `Optional(T)` implements `Try` with `BreakType = ()`, `?` propagates
absence through `Optional`-returning functions:

```carbon
fn FirstLine(name: str) -> Core.Optional(str) {
  var f: File = OpenIfExists(name)?;  // `.None` propagates as `.None`.
  return .Some(f.ReadLine());
}
```

Mixing the two families requires an explicit step: using `?` on an
`Optional` inside a `Result`-returning function is a compile error unless `()`
implicitly converts to the function's error type, which the prelude never
provides. Converting between `Optional` and `Result` is a normal, explicit
library operation. User-defined sum types opt into `?` by implementing
`Core.Try` themselves.

## The program entry point

The entry point of a Carbon program is the function named `Run` in the default
library of the `Main` package
([code and name organization](code_and_name_organization/README.md)). The valid
signatures are:

```carbon
fn Run();
fn Run() -> i32;
fn Run() -> Core.Result((), E);
fn Run() -> Core.Result(i32, E);
```

for any type `E`. The parameter list varies independently of the return type:
each form may declare either the empty parameter list `()` shown above or the
command-line parameter list `(argc: i32, argv: Core.Optional(char*)*)`, which
the toolchain accepts today (`toolchain/check/handle_function.cpp`, tracking
upstream issue
[#6735](https://github.com/carbon-language/carbon-lang/issues/6735)). The
process exit code is determined as follows:

-   `fn Run()`: exit code 0.
-   `fn Run() -> i32`: the returned value.
-   `Result` forms, on `.Success(())`: exit code 0; on `.Success(code)`: the
    returned code; on `.Failure(e)`: the runtime writes a diagnostic to
    standard error naming the error's type (and, when `E` is
    [`Cpp.Exception`](#cppexception), its message when available), then exits
    with code 1. The failure value is destroyed normally; nothing unwinds.

The `Result` forms exist so that `?` is usable in `Run` itself; small programs
propagate errors all the way out and get a defined nonzero exit and diagnostic
rather than hand-written plumbing.

## Interoperating with C++ exceptions

The interop philosophy
[does not promise seamless exception interop](interoperability/philosophy_and_goals.md#support-for-c-exceptions-without-bridge-code);
what Carbon promises instead is a _defined_ boundary in both C++ dialects,
with conversion to and from Carbon errors at that boundary. The invariant that
anchors everything in this section:

> **A C++ exception never unwinds a Carbon stack frame.** In `catch` mode,
> every call to a potentially-throwing C++ callee crosses the boundary through
> a compiler-generated thunk on the C++ side, which either terminates the
> program or converts the in-flight exception into a value before returning to
> Carbon. In `none` mode, no callee can throw at all.

Not every cross-language call involves a thunk: the toolchain generates a
thunk only where the boundary requires one — today for ABI bridging
(`toolchain/check/cpp/thunk.cpp`), and under this design additionally for
fencing or catching a potentially-throwing callee. Calls to `noexcept` callees
and all calls in `none` mode cross the boundary as plain calls, exactly as
they do today.

Because Carbon frames are never unwound, Carbon destructor (`Destroy`) logic
can never be skipped by a foreign exception, and no Carbon-frame cleanup ever
depends on unwinding. A Carbon program that never calls potentially-throwing
C++ compiles with no unwinding machinery at all — no landing pads, no
personality functions, no happy-path cost. Where a fenced or catching boundary
exists, its `try`/`catch` is confined to the generated C++-side thunk; after
inlining, that thunk's code — including its landing pad and personality
reference — may physically reside inside a Carbon function's object code, but
it protects only the C++ call, and no Carbon-language semantics depend on it.

### The `--cpp-exceptions` compile option

The `carbon compile` driver option `--cpp-exceptions={auto,none,catch}`
configures how the embedded Clang builds imported C++ code and what happens at
the boundary:

-   **`none`** — models `-fno-exceptions` C++ dialects. Imported C++ is
    compiled with `-fno-exceptions -fno-cxx-exceptions` and diagnosed exactly
    as Clang would. No callee can throw, so no fencing or catching machinery
    exists and calls carry zero added overhead. Requesting a catching import
    (`Result(T, Cpp.Exception)`) is a compile error. `?` on a C++ call is
    governed by the [general rule](#semantics-and-desugaring) alone: when the
    callee's mapped return type implements `Core.Try` — for example, a C++
    function returning
    [`Carbon::expected`](#exporting-fallible-carbon-functions-carbonexpected) —
    `?` applies exactly as it would to a Carbon call; otherwise it is the
    usual compile error for a non-`Try` operand, since the callee cannot fail
    by exception.
-   **`catch`** — models standard C++ dialects. Imported C++ is compiled with
    exceptions enabled. Calls to `noexcept` callees are plain calls; every
    call to a potentially-throwing callee is
    [fenced](#the-fenced-boundary-terminate-semantics) by default and
    [catching](#catching-imports-resultt-cppexception) where the Carbon call
    site consumes the error; see the
    [selection precedence rule](#catching-imports-resultt-cppexception).
-   **`auto`** — the default. Resolves to `none` when the user's other Clang
    arguments (`--clang-arg=...`) disable exceptions, and to `catch`
    otherwise. This makes the default match what the C++ code was going to be
    built as anyway; see [decision D5](#decisions-within-this-design).

### The fenced boundary: terminate semantics

In `catch` mode, when Carbon calls a potentially-throwing C++ function (one
that is not `noexcept`) and the call site does _not_ request the error, the
generated thunk is _fenced_:

```cpp
// Generated C++-side thunk (illustrative).
ReturnT __carbon_thunk__f(Args... args) {
  try {
    return f(args...);
  } catch (...) {
    __carbon_boundary_terminate();  // Reports and calls std::terminate.
  }
}
```

If an exception reaches the fence, the program prints a diagnostic identifying
the boundary and terminates via `std::terminate`. This is a **defined,
documented** behavior — the language-boundary analog of an exception escaping
a `noexcept` C++ function — and replaces the undefined behavior of unwinding
through frames with no unwind support. Termination is not an error-handling
strategy; it is the guarantee that makes the boundary safe by default while
keeping un-annotated calls zero-cost on the success path. Code that wants to
_handle_ the exception uses a catching import instead.

The same fencing applies in the reverse direction where generated code could
otherwise let an exception cross into Carbon (for example, C++ callbacks
invoked from Carbon-owned frames).

### Catching imports: `Result(T, Cpp.Exception)`

In `catch` mode, a call to a potentially-throwing C++ function may instead be
consumed as a `Core.Result`. When the Carbon call site uses the call in a
context expecting `Core.Result(T, Cpp.Exception)` — including applying `?`
directly to the call — the compiler selects the _catching_ thunk for that call
site:

```cpp
// Generated catching thunk (illustrative): the exception is captured,
// never propagated.
} catch (...) {
  *out_error = std::current_exception();
  return /* failure discriminant */;
}
```

On the Carbon side this is automatic in the milestone's sense — no per-call
bridge code is written by the user:

```carbon
import Cpp library "parser.h";

fn ParseAll(input: str) -> Core.Result(i64, Cpp.Exception) {
  // `Cpp.parse` is C++ and may throw. `?` requests the catching thunk;
  // a thrown exception becomes the `.Failure` alternative and propagates.
  let n: i64 = Cpp.parse(input)?;
  return .Success(n);
}
```

The selection is per call site: the same C++ function can be called fenced in
one place and catching in another.

Selection is governed by a precedence rule stated in terms of the callee's
_mapped return type_ `S` (the Carbon type of the call expression under the
ordinary interop type mapping):

-   If `S` itself implements `Core.Try`, the call is an ordinary fallible
    expression of type `S`: `?` and `Result` consumption apply to `S` by the
    [general rule](#semantics-and-desugaring), in every `--cpp-exceptions`
    mode, and no catching thunk is selected. This covers C++ functions
    returning
    [`Carbon::expected<T, E>`](#exporting-fallible-carbon-functions-carbonexpected)
    (imported as `Core.Result(T, E)`), whether or not the callee is also
    potentially-throwing. In `catch` mode such a call is still fenced: its
    declared error channel is the returned value, and an exception thrown
    despite it is a boundary escape like any other.
-   Otherwise, in `catch` mode, consuming the call in a context expecting
    `Core.Result(S, Cpp.Exception)` — including applying `?` directly to the
    call inside a function whose break type accepts `Cpp.Exception` — selects
    the catching thunk, and the call expression has type
    `Core.Result(S, Cpp.Exception)`.
-   `noexcept` callees never get catching thunks in any mode; requesting one
    is a compile error. Their calls follow the first bullet only: `?` applies
    exactly when `S` implements `Core.Try`.

### `Cpp.Exception`

`Cpp.Exception` is the Carbon-side representation of a caught C++ exception.
Its payload is the C++ `std::exception_ptr` that owns the in-flight exception
object.

It is a member of the `Cpp` package, but it is neither imported from a header
nor written in Carbon source — Carbon source cannot declare into the `Cpp`
package at all (the toolchain rejects `package Cpp`;
`toolchain/check/check.cpp`). Instead, the compiler _synthesizes_ the type
into the `Cpp` package scope, alongside the
[built-in, file-less C++ entities](interoperability/README.md#accessing-built-in-c-entities-file-less)
that package already provides without any header. This synthesis is a new
toolchain mechanism delivered by stage B3; see
[Implementation staging](#implementation-staging). The `Cpp.` prefix still
marks origin faithfully: the type exists only as part of the C++ boundary and
wraps a C++ runtime object.

`Exception` is a compiler-reserved name at the top level of the `Cpp` package.
If an imported header declares a global-namespace C++ entity named
`Exception`, `Cpp.Exception` continues to name the synthesized type; the
colliding C++ entity is not reachable under that name, and a use that requires
it is diagnosed, with the standard interop workaround of naming it through a
C++-side alias in bridge code.

The type's Carbon-visible API:

```carbon
// Synthesized into package `Cpp`; shown as it appears to Carbon code.
class Exception {
  // The dynamic type name of the exception object, when the C++ side has
  // run-time type information; otherwise a placeholder.
  fn TypeName(self) -> str;

  // The `what()` message, when the exception derives from `std::exception`;
  // `.None` otherwise. The returned `str` is valid for the lifetime of
  // `self`, which keeps the exception object alive.
  fn Message(self) -> Core.Optional(str);
}
```

Design contract:

-   The exception object is stored, never translated: `Cpp.Exception` holds
    the `exception_ptr` and nothing is eagerly unpacked or copied, so capture
    is cheap and lossless.
-   When a `Cpp.Exception` value crosses back into C++ — by
    [export](#exporting-fallible-carbon-functions-carbonexpected) or by
    passing it to C++ code — the original exception can be rethrown from the
    stored `exception_ptr` with full fidelity (same object, same dynamic
    type).
-   Destroying a `Cpp.Exception` releases the `exception_ptr`, destroying the
    exception object if this was the last reference.
-   Richer accessors (structured message types, formatting) are deliberately
    deferred until Carbon has a full `String` design; `str` views into the
    live exception object are the 0.1 surface. This dependency is stated
    plainly: `Message` returns views only because there is not yet an owning
    string type to return.

### Exporting fallible Carbon functions: `Carbon::expected`

An exported Carbon function returning `Core.Result(T, E)` is visible to C++ as
a function returning `Carbon::expected<T', E'>`, where `T'` and `E'` are the
C++ mappings of `T` and `E`:

```carbon
// Carbon
fn LoadConfig(name: str) -> Core.Result(Config, IoError);
```

```cpp
// Seen from C++
#include <carbon/expected.h>
Carbon::expected<Config, IoError> LoadConfig(std::string_view name);
```

In 0.1, both `T` and `E` must cross the boundary by value inside the
`Carbon::expected` object, which requires each to satisfy the single
trivially-copyable-and-trivially-destructible predicate defined in
[Unions: field rules in 0.1](unions.md#field-rules-in-01) — the same predicate
that governs union fields; it is defined once and reused here, not restated.
The predicate applies to Carbon class types; a type of C++ origin maps to its
C++ self with C++ semantics — in particular `Cpp.Exception` maps to
`std::exception_ptr`, whose copy and destruction are ordinary C++ operations.
Exporting a `Core.Result` whose success or error type is a Carbon class not
satisfying the predicate is diagnosed at the export declaration; such types
cross the boundary by indirection, as elsewhere in interop.

`Carbon::expected<T, E>` is a class template shipped as a support header in
the toolchain install tree. It requires only C++17 — the interop target
dialect, which rules out returning C++23 `std::expected` directly — and
provides the familiar subset of the `std::expected` API: `has_value()`,
`operator bool`, `value()`, `error()`, `value_or()`, and equality. When the
including translation unit is compiled as C++23 or later, implicit conversions
to and from the corresponding `std::expected<T, E>` are provided.

When the error type is `Cpp.Exception`, `error()` exposes the stored
`std::exception_ptr`, so a C++ caller that prefers exception idiom can write
`std::rethrow_exception(r.error().ptr())` and recover the original exception
exactly. The toolchain does not generate per-function throwing wrapper
functions in 0.1; see [decision D8](#decisions-within-this-design).

In `--cpp-exceptions=none` builds the export mapping is unchanged —
`Carbon::expected` involves no exceptions machinery — which is what makes the
same fallible Carbon API usable from both C++ dialects.

## Unrecoverable errors

This document covers _recoverable_ errors only. Unrecoverable failures
(assertion failures, contract violations) are in the domain of the
[safety design](safety/README.md) and are not reported through `Result`. The
boundary contract commits to one rule now: a Carbon-initiated abort terminates
the program without unwinding — C++ frames on the stack are not unwound and
C++ destructors do not run, matching the behavior of `std::terminate`. A
richer panic design must preserve the invariant that no failure mechanism,
Carbon or C++, unwinds frames of the other language.

## Implementation staging

The design lands in four stages, fixed by decision F-006. Dependencies on
unimplemented features are stated here once; the semantics above are normative
for every stage.

| Stage  | Contents                                                                                        | Depends on                                                                                                                                                     |
| ------ | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **B0** | `--cpp-exceptions` option; fenced thunks; boundary terminate semantics                           | Nothing — implementable now; replaces today's undefined behavior                                                                                                |
| **B1** | `Core.Result` in the prelude; consumption via `match` (and F-011 forms when they land)           | `match` semantics and choice-alternative payloads, both currently unimplemented in check; `Core.Optional` rebuilt as a payload-carrying choice type (see below) |
| **B2** | Postfix `?`; `Core.Try`; `ImplicitAs` error conversion; `Run` `Result` signatures                | B1                                                                                                                                                              |
| **B3** | Catching thunks; `Cpp.Exception` synthesis into the `Cpp` package; `Carbon::expected` export and support header | B0-B2                                                                                                                                                           |

Dependency notes, stated plainly:

-   **B0 cost shape.** Today the toolchain generates a C++-side thunk only
    where ABI bridging requires one; simple-ABI callees are called directly.
    Fencing therefore adds thunks (and their `try`/`catch`) to
    potentially-throwing calls that currently cross the boundary without any
    thunk. This is a real B0 implementation cost, not a free re-labeling of
    existing thunks.
-   **`Core.Optional` rebuild.** The prelude `Optional` is today a placeholder
    class, not a choice type. The [`Try` impl for `Optional`](#the-coretry-interface)
    and every `.Some`/`.None` pattern in this document require it to become a
    payload-carrying choice; that rebuild is part of the choice-payloads work
    B1 depends on.
-   **`Cpp.Exception` synthesis.** Carbon source cannot declare into the `Cpp`
    package, so B3 must add a toolchain mechanism that synthesizes the type
    into the `Cpp` scope (as for the built-in file-less C++ entities).

Until B1's dependencies land, `Result` cannot be defined or consumed; until
F-011's implementation lands, the `let ... else` / `if (let ...)` consumption
forms are design-only. Windows support will additionally need the boundary
thunks reworked for MSVC's exception model; that changes the thunk
implementation, not this design.

## Decisions within this design

The option paper for this area
([fork/design-sprint/error-handling.md](/fork/design-sprint/error-handling.md))
left sub-questions open beyond the main F-006 fork. Each is decided here;
these are the reviewable batch for this document.

-   **D1 — Alternative names are `Success`/`Failure`, not `Ok`/`Err`.**
    Matches the choice-type vocabulary already used in the
    [language overview](README.md#choice-types) (`IntResult.Success` /
    `.Failure`), and Carbon's general preference for whole-word names.
    Avoids importing Rust spellings onto a type whose conversion and interop
    behavior differ from Rust's.
-   **D2 — `?` precedence: highest (suffix-operator) group, repeating.**
    Propagation must chain with member access and calls
    (`Open(n)?.Read()?`); any looser binding would force parentheses in the
    dominant use and contradict how every other suffix operator behaves.
-   **D3 — Error conversion in `?` uses `ImplicitAs`, with no `?`-specific
    conversion trait.** Fixed by F-006 itself ("ImplicitAs error
    conversion"). One conversion system keeps the rule predictable:
    `?` converts exactly where an argument or `return` would, and error-type
    authors control propagation by choosing which `ImplicitAs` impls exist.
-   **D4 — `?` requires a declared enclosing return type implementing
    `Core.Try`; it is unavailable in `auto`-return functions, at file scope,
    and in global initializers; in `match` arms it targets the enclosing
    function.** The desugaring needs `R` up front; deduction plus `?` would
    make the return type depend on the body while the body's meaning depends
    on the return type.
-   **D5 — Default `--cpp-exceptions` mode is `auto`, resolving to `catch`
    unless the user's Clang arguments disable exceptions.** The default then
    always agrees with how the C++ code is actually built: standard-dialect
    users get the defined fenced/catching boundary without flags, and
    `-fno-exceptions` codebases get the zero-overhead mode without a
    contradictory exceptions-enabled boundary.
-   **D6 — Boundary behavior without opt-in is fenced terminate.** A compile
    error on every un-annotated call to non-`noexcept` C++ was rejected:
    `noexcept` is rare enough in real headers that the mode would be
    unusable, defeating the interop goal. Silent UB (the status quo) was
    rejected outright. Terminate-at-boundary is defined, cheap, and matches
    the floor the interop philosophy already reserves.
-   **D7 — `Cpp.Exception` stores only the `exception_ptr`; accessors are
    lazy views; rethrow-on-reexport is guaranteed lossless.** Eager
    unpacking would tax every caught exception to benefit only the ones that
    are inspected, and cannot be lossless in general. The full-fidelity
    pointer supports both cheap propagation and exact rethrow.
-   **D8 — Export ships the `Carbon::expected` support header only; no
    generated per-function throwing wrappers in 0.1.** Wrappers double the
    exported surface for one idiom, and C++ callers who want exceptions can
    rethrow from `error().ptr()` in one line. Wrappers remain expressible
    later without changing the core mapping.
-   **D9 — `Optional(T)` implements `Try` with `BreakType = ()`; no implicit
    bridge between `Optional` and `Result`.** Absence is not an error value;
    silently manufacturing an error from `.None` (or discarding an error
    into `.None`) would hide information at exactly the points `?` is
    supposed to mark.
-   **D10 — Entry-point return types are fixed as `()`, `i32`,
    `Core.Result((), E)`, and `Core.Result(i32, E)`, combined with either the
    empty parameter list or the already-implemented command-line parameter
    list `(argc: i32, argv: Core.Optional(char*)*)`; `.Failure` maps to a
    stderr diagnostic and exit code 1.** This resolves the overview's open
    note on entry-point signatures with the minimal set that makes `?` usable
    at top level, without outlawing the parameterized signatures the
    toolchain accepts and tests today.
-   **D11 — `try { }` blocks and `catch`-style unwrap-or-handle expressions
    are deferred past 0.1.** They are sugar over this design's semantics
    (and overlap the F-011 forms); deferring them keeps 0.1's surface at one
    new operator, and they remain forward-compatible additions.
-   **D12 — Carbon aborts do not unwind C++ frames.** Recorded here so the
    boundary contract is total; the full unrecoverable-failure design
    belongs to the safety workstream.

## Alternatives considered

The alternatives for this area — library-only `Result` with no operator,
declared-fallibility signatures (`-> T or E` with `try`/`catch` sugar), and
native exceptions on the C++ unwinder — were researched in
[fork/design-sprint/error-handling.md](/fork/design-sprint/error-handling.md)
and rejected in fork decision
[F-006](/fork/decision-log.md):
library-only fails the milestone's dedicated-control-flow requirement;
declared fallibility costs several times more in signature plumbing and
diverges from upstream's written direction; native exceptions contradict the
accepted errors-are-values principle and would permanently fork code
generation. That decision is final; this document specifies the chosen design
rather than relitigating it.

## References

-   [Principle: Errors are values](/docs/project/principles/error_handling.md)
    / Proposal
    [#301: Principle: Errors are values](https://github.com/carbon-language/carbon-lang/pull/301)
-   [Sum types](sum_types.md) / Proposal
    [#157: Design direction for sum types](https://github.com/carbon-language/carbon-lang/pull/157)
-   [Pattern matching](pattern_matching.md) / Proposal
    [#2188: Pattern matching syntax and semantics](https://github.com/carbon-language/carbon-lang/pull/2188)
-   [Expressions: precedence](expressions/README.md#precedence) / Proposal
    [#555: Operator precedence](https://github.com/carbon-language/carbon-lang/pull/555)
-   [Implicit conversions](expressions/implicit_conversions.md)
-   [Interoperability philosophy and goals](interoperability/philosophy_and_goals.md)
    / Proposal
    [#175: C++ interoperability goals](https://github.com/carbon-language/carbon-lang/pull/175)
-   Fork decision
    [F-006](/fork/decision-log.md)
    and option paper
    [fork/design-sprint/error-handling.md](/fork/design-sprint/error-handling.md)
-   Fork decision
    [F-011](/fork/decision-log.md)
    (combined match control flow)
