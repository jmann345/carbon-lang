# Slices

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
    -   [Forming a view](#forming-a-view)
-   [The API](#the-api)
    -   [`Core.Slice(T)`](#coreslicet)
    -   [`Core.Buf(T)`](#corebuft)
    -   [The builtins behind them](#the-builtins-behind-them)
-   [Bounds behavior](#bounds-behavior)
-   [Heap buffers](#heap-buffers)
-   [Iteration](#iteration)
-   [Interop](#interop)
-   [0.1 limits](#01-limits)
-   [Alternatives considered](#alternatives-considered)
-   [References](#references)

<!-- tocstop -->

## Overview

> **Fork amendment 2026-09-28 (F-012; fork/slices/plan.md, decisions
> D-SL-1..14, and the decision-log entry "SL-1: Core.Slice, Core.Buf, heap
> allocation, fail-stop (2026-10-05)" for D-SL-15..20).** `Core.Slice(T)` and
> `Core.Buf(T)` as implemented. Toolchain status: SL-1 (the two prelude types,
> the runtime bounds fail-stop and the four builtins behind them) landed
> 2026-10-05; SL-2 (W-056: the `std::span` mapping and owning-container views,
> the [Interop](#interop) section) landed 2026-10-05 (the decision-log entry
> "SL-2: std::span ↔ Core.Slice mapping, owning-container views (2026-10-05)"
> for D-SL-21..27). The
> [0.1 limits](#01-limits) section lists every deviation from the target
> design together with the condition under which it is removed.

A _slice_ is a non-owning view of a contiguous region of `N` values of type
`T`: a pointer to the first element and a count. It is Carbon's answer to the
request in [Values](values.md#pointers) that pointers cannot be indexed or
advanced, but that "slice or view style types are expected to provide access to
indexable regions". The prelude type is `Core.Slice(T)`, spelled in full; there
is no keyword shorthand (the provisional `[T]` "sized pointer" spelling of
[proposal #4682](/proposals/p004682-the-core-array-type-for-direct-storage-immutably-sized-buffers.md)
never reached the design and is not adopted).

A slice does not own what it views. The storage it names must outlive it, and
every write to that storage is visible through every slice of it:

```carbon
var a: array(i32, 4) = (1, 2, 3, 4);
// A view of a[1..3): {2, 3}.
let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a).Subslice(1, 3);
Core.Print(s.Size() as i32);  // 2
Core.Print(s[1]);             // 3, read through to `a`
a[2] = 30;
Core.Print(s[1]);             // 30: no copy was made
```

The element type is constrained to `Copy & Destroy`, the constraint `Iterate`
and `Optional` already impose, so that an element can be read out of a view by
value. `const T` satisfies it, so `Core.Slice(const i32)` — the mapping of
`std::span<const int>` — is well-formed, and a `Core.Slice(T)` implicitly
converts to `Core.Slice(const T)`.

### Forming a view

Views are formed from four sources, each an explicit operation:

-   From a **pointer to an array**: `Core.Slice(T).FromArray(&a)`, where `a` has
    type `array(T, N)`; `N` is deduced. There is deliberately **no** implicit
    conversion from an array _value_: a value binding of array type may be
    implemented by a copy (see
    [Parameters](README.md#parameters)), so a view of such a value could alias
    a temporary and dangle. The `&a` is the design's syntactic marker that
    `a`'s storage is being aliased.
-   From a **heap buffer**: `b.AsSlice()` on a [`Core.Buf(T)`](#corebuft).
-   From **another slice**: `s.Subslice(start, end)` is the half-open sub-view
    `[start, end)`, bounds-checked.
-   From a **raw pointer and size**: `Core.Slice(T).UnsafeMake(p, size)`. The
    caller guarantees that `p` names at least `size` valid elements that
    outlive the view. This is the escape hatch the other constructors are
    built on, and the one the interop mapping uses.

## The API

### `Core.Slice(T)`

Declared in `core/prelude/types/slice.carbon`:

```carbon
class Slice(T: Copy & Destroy) {
  fn FromArray[N: IntLiteral](p: array(T, N)*) -> Self;
  fn UnsafeMake(p: T*, size: i64) -> Self;
  fn Size(self) -> i64;
  // The raw pointer to element 0 (the twin of `std::span::data()`); no
  // arithmetic on it is possible from user code.
  fn Data(self) -> T*;
  // Bounds-checked read; a violation fails-stop.
  fn Get(self, i: i64) -> T;
  // The half-open sub-view `[start, end)`; `0 <= start <= end <= Size()`.
  fn Subslice(self, start: i64, end: i64) -> Self;

  impl as Copy;
}

impl forall [T: Copy & Destroy] Slice(T) as UnformedInit {}

final impl forall [T: Copy & Destroy] Slice(T) as IndexWith(i64)
    where .ElementType = T;

impl forall [T: Copy & Destroy] Slice(T) as ImplicitAs(Slice(const T));
```

`s[i]` is `IndexWith.At`, so it is a _value expression_: it reads the element
out by value through its `Copy` witness, after the bounds check of `Get`. The
subscript type is `i64`. An integer literal subscript converts to `i64` first
(fork rule, SL-1): the index expression applies that conversion when the
container implements `IndexWith(i64)` and has no `IndexWith(Core.IntLiteral)`
impl — the array indexing rule's hardcoded subscript conversion, decided by impl
lookup instead — so `s[1]` and `s[i]` with `i: i64` work, while an `i32`
subscript must be written `s[i as i64]` (see [0.1 limits](#01-limits)). A
container with its own `IndexWith(Core.IntLiteral)` impl, such as `Core.String`,
is dispatched as written. The `IndexWith(i64)` impls of `Slice` and `Buf` are
`final`, so in a generic body `s[i]` on a `Core.Slice(T)` has type `T`: a
symbolic impl lookup resolves only final impls, and through a non-final impl the
element type would stay the abstract
`Core.Slice(T).(Core.IndexWith(i64).ElementType)`. `Slice` deliberately does not
copy `String`'s blanket `IndexWith(U: ImplicitAs(i64))` impl: for `U =
Core.IntLiteral` its `At` would apply a compile-time-only conversion to a
runtime `subscript`, which cannot be lowered; `String`'s works only because its
`At` is itself a builtin, lowered at the call site. A `Core.Slice(T)` is `Copy`
(two words) and `UnformedInit`: `var s: Core.Slice(i32);` is accepted and must
be assigned before use, as for `Core.String`, whose `{ptr, size}` layout
`Core.Slice(T)` shares.

### `Core.Buf(T)`

Declared in `core/prelude/types/buf.carbon`:

```carbon
// An owning, heap-allocated buffer of `size` values of `T`. Not copyable.
class Buf(T: Copy & Destroy) {
  // Allocates `size` elements, each initialized to a copy of `fill`.
  fn Make(size: i64, fill: T) -> Self;
  fn Size(self) -> i64;
  fn Get(self, i: i64) -> T;
  // Bounds-checked write. `self` is by value: the storage is the heap
  // block, not the `Buf` object.
  fn Set(self, i: i64, value: T);
  fn AsSlice(self) -> Slice(T);

  impl as Destroy;  // frees the block
}

final impl forall [T: Copy & Destroy] Buf(T) as IndexWith(i64)
    where .ElementType = T;
```

See [Heap buffers](#heap-buffers) for the ownership rules.

### The builtins behind them

Both classes are ordinary Carbon source. The four operations Carbon source
cannot express are private prelude builtins, each runtime-only (never
constant-evaluated) and each a "specialized construct" in the sense of
[Values](values.md#pointers):

| Builtin           | Declaration                                                           | Lowering                                                            |
| ----------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `"pointer.offset"` | `fn PointerOffset[T: type](p: T*, n: i64) -> T*`                     | `getelementptr inbounds T, p, n`                                    |
| `"fail_stop"`     | `fn FailStop(message: str)`                                           | `write(2, message, size)` then `abort()`, declared `noreturn`       |
| `"heap.allocate"` | `fn HeapAllocate(generic T: type, count: i64) -> MaybeUnformed(T*)`  | `malloc(count * sizeof(T))`, never a zero-byte request; null on failure |
| `"heap.free"`     | `fn HeapFree[T: type](p: T*)`                                         | `free(p)`                                                           |

A builtin body `= "name"` is accepted in any file, exactly as for the existing
`"pointer.unsafe_convert"`, so these add no new surface class; users get no `+`
on pointers. A call to `pointer.offset` or `heap.allocate` requires the pointee
type to be complete (`IncompleteTypeInBuiltinCall`): both lowerings need its
size, and a pointer type is complete without its pointee, so the call is where
the requirement is checked — per specific, for a symbolic pointee.

## Bounds behavior

Every read through a slice and every write through a buffer is
bounds-checked, and a violation is a **fail-stop**: one line on stderr naming
the operation, then `abort()`. The process dies with `SIGABRT`; nothing is
unwound and no further program logic runs
([Safety terminology](safety/terminology.md#fail-stop)).

```text
carbon: Core.Slice index out of bounds; terminating
carbon: Core.Slice.Subslice range out of bounds; terminating
carbon: Core.Buf index out of bounds; terminating
carbon: Core.Buf size is negative; terminating
carbon: heap allocation failed; terminating
```

The attribution matters. [Safety: build modes](safety/README.md#build-modes)
says of the _release_ build that "bounds checking is enabled in the release
build" and that Carbon "will provide ways to write unsafe code that disables
the run-time enforcement"; the fail-stop-with-diagnostics sentence belongs to
the _debug_ build, which "will change the actual behavior ... to have
fail-stop behavior and provide detailed diagnostics". The toolchain has no
notion of build modes, so 0.1 has exactly one mode, and this design adopts the
debug build's promise as that mode: the check is always on and always
fails-stop. The release paragraph's enforcement opt-out — an _unchecked_ read
— is not implemented (`UnsafeMake` and `Data()` form views; they do not read
without a check) and is listed under [0.1 limits](#01-limits). The message
names the operation, not the index: there is no runtime diagnostics facility
to format an integer from a generic prelude body yet.

The check lives in Carbon source (`Slice.Get` tests `i < 0 or i >= self.size`
and calls `fail_stop`), not in the compiler, so every semantic line is
readable in `core/prelude/types/slice.carbon`.

## Heap buffers

`Core.Buf(T)` is the name the [arrays and buffers](README.md#arrays-and-buffers)
section gives to "a heap-allocated dynamically sized array". Proposal #4682
calls `Buf` a placeholder — "Carbon does not have proposed names for
heap-allocated storage" — but it is the only heap-storage spelling the design
carries, so it is used as is. The `buf(T)` shorthand is not implemented (a
lexer and parser change for a placeholder name).

A `Core.Buf(T)` owns one `malloc` block of `Size()` elements:

-   `Make(size, fill)` allocates and initializes **every** element from `fill`;
    no element is ever unformed. A negative size or a failed allocation
    fails-stop.
-   `Set(self, i, value)` writes through the shared heap block, so it takes
    `self` by value: the storage being mutated is the block, not the `Buf`
    object. Writes to owned storage go through `Set`; `Core.Slice(T)` has no
    `Set` (see [0.1 limits](#01-limits)).
-   `AsSlice()` views the block; the view is valid while the `Buf` lives.
-   The in-class `impl as Destroy` frees the block when the `Buf` goes out of
    scope: the toolchain's destroy lookup selects a class's own declared
    `Destroy` impl over the synthesized destructor it would otherwise build,
    so a `Buf` local variable or temporary is freed exactly once at scope
    exit. Element destructors are **not** run (the element types are `Copy &
    Destroy`; this mirrors what `Optional(T)` and `MaybeUnformed(T)` already
    do). A `Buf` held **inside** another object is not freed in 0.1 (see
    [0.1 limits](#01-limits)).
-   `Buf` is **not** `Copy`: `var c: Core.Buf(i32) = b;` is a compile-time
    error (`CopyOfUncopyableType`), never a double free. Passing a `Buf` to a
    by-value parameter does not copy it (value bindings of a non-`Copy` class
    are references), so a callee can `Set` through it.
-   `Buf` is **not** `UnformedInit`: `var b: Core.Buf(i32);` is a compile-time
    error. The toolchain runs `Destroy` on every `var` unconditionally, so an
    unformed `Buf` would free an uninitialized pointer at scope exit. `Slice`
    keeps `UnformedInit` because it has no user `Destroy` and its fields are
    trivially destroyed.

## Iteration

`Core.Slice(T)` implements `Iterate` with `.ElementType = T` and
`.CursorType = i64` (the array impl's shape with a 64-bit cursor), so

```carbon
var total: i32 = 0;
for (x: i32 in s) {
  total += x;
}
```

reads each element by value in order. The impl is `final`, like the
`IndexWith(i64)` impl, so `for (x: T in s)` in a generic body binds `T`.
`Core.Buf(T)` has no `Iterate` impl of
its own: `for (x: T in b.AsSlice())` is the idiom. The impl lives in
`core/prelude/iterate.carbon`, next to the array and C++ range impls.

## Interop

> SL-2 (W-056, 2026-10-05; fork/slices/plan.md §1.B, decisions D-SL-8, D-SL-9,
> D-SL-10, D-SL-14, and D-SL-21..27 of the decision-log entry "SL-2: std::span
> ↔ Core.Slice mapping, owning-container views (2026-10-05)" for the landed
> prelude layout, the constraint bounds, the size conversion, the element
> bound, nullable `data()` and static extents). The C++ side of this section
> is also recorded in
> [Interoperability: `std::span` and `Core.Slice`](interoperability/README.md#stdspan-and-coreslice).

**`std::span` ↔ `Core.Slice` (D-SL-8).** The dynamic-extent
`std::span<T, std::dynamic_extent>` maps to `Core.Slice(T')` in both directions
on the premise that both are a pointer followed by a size — `Core.Slice(T)` is
`{T*, i64}` and a dynamic-extent span is `{T*, size_t}`, 16 bytes on the
supported 64-bit targets — so the mapping is a reinterpretation, with no
conversion at the boundary (the `str` ↔ `std::string_view` rule). The element
type maps recursively: `std::span<const int>` ↔ `Core.Slice(const i32)`. On
import, a C++ function taking or returning `std::span<T>` takes or returns
`Core.Slice(T')`; on export, a Carbon function whose signature names
`Core.Slice(T)` is declared to C++ with `std::span<T'>` in that position, found
by name in the translation unit, which must therefore `#include <span>` (a
translation unit without it diagnoses the signature as unmappable). A
static-extent `std::span<T, N>` is a pointer only, so it is not mapped and
imports as an ordinary class. The element must satisfy `Core.Slice`'s
`Copy & Destroy` bound: a `std::span<T>` whose `T` is a Carbon class with no
`Copy` impl imports as an ordinary class too, while a C++ `T` whose copy
constructor is deleted (`std::span<std::unique_ptr<int>>`) does satisfy it —
the deleted constructor is imported as the `Copy` witness — and maps to a
`Core.Slice(T')` whose elements cannot be copied, so `s[i]` fails at the use
site, not at the header.

**Views are explicit on the Carbon side (D-SL-2).** A Carbon array reaches a
`std::span<const int>` parameter as
`Cpp.SumSpan(Core.Slice(i32).FromArray(&a))`, never as `Cpp.SumSpan(a)`: the
view is formed from a pointer to the array. A `Core.Slice(T)` argument converts
to a `Core.Slice(const T)` parameter implicitly (D-SL-10), as `std::span<T>`
converts to `std::span<const T>`.

**Owning containers form views implicitly (D-SL-9).** A C++ class with `data()`
and `size()` member functions — `std::vector<T>`, `std::array<T, N>`,
`std::string` — implements the prelude's `Core.CppContiguousRange` interface
through a witness the toolchain synthesizes from those two members (the
`CppRangeForIterate` mechanism behind `for` over C++ ranges), and the
prelude's blanket impl beside `Slice` in `core/prelude/types/slice.carbon`
(its helpers — `CppContiguousRange`, `CppDataPointer`, `CppSizeToI64`, the
`CppContiguous` constraint — are `core/prelude/types/cpp/slice.carbon`'s) makes
such a container implicitly convertible to `Core.Slice(Element)`, where
`Element` is the pointee of `data()`'s result. When the container has both a
`const` and a non-`const` `data()`, the `const` one is selected, so a
`std::vector<int>` views as `Core.Slice(const i32)` — exactly the type a
`std::span<const int>` parameter imports as. The size converts in two steps,
`ImplicitAs(u64)` then `As(i64)`, so that `size_t` is accepted both where it
imports as `u64` (LP64 Linux and LLP64 Windows, where it is `uint64_t`) and
where it imports as `Core.CppCompat.ULong64` (Darwin, whose `unsigned long` is
not `uint64_t`; `ULong64` has `ImplicitAs(u64)` but no `As(i64)`); a signed
`size()` has no `ImplicitAs(u64)` and forms no view. So, for a
`std::vector<int>` `v` made in C++:

```carbon
let view: Core.Slice(const i32) = v;   // owning -> view, no copy
Core.Print(view[2]);
Core.Print(Cpp.SumSpan(v));            // the vector passes as std::span<const int>
```

The view owns nothing and is valid while the container is; an empty
container yields a zero-size view whose pointer is never dereferenced. Only
member `data()`/`size()` are consulted; free (ADL) `data`/`size` functions are
not (a 0.1 limit below).

**`-std=c++20`.** `<span>` is a C++20 header and the toolchain's embedded Clang
defaults to C++17, so a translation unit that uses the mapping compiles with
`--clang-arg=-std=c++20` (the fork's conformance programs
`interop/cpp_span_view.carbon` and `interop/cpp_span_roundtrip_diff.carbon`
carry it as `COMPILE-ARGS`). Toolchain tests mock `std::span` with the
pointer-then-size layout so they stay hermetic (D-SL-14).

## 0.1 limits

Each limit is a deviation from the target design, with the condition under
which it is removed:

-   **Slices are read-only; `s[i] = v` is an error.**
    [Indexing](expressions/indexing.md) specifies a `Span` that implements
    `IndirectIndexWith` with a `Ref` method returning `ref T`. The toolchain has
    neither `IndirectIndexWith` nor `ref`-returning methods, and the prelude's
    `IndexWith` has only `At`, so `s[i]` is a value expression and a write
    through it diagnoses `AssignmentToNonAssignable`. There is also no
    `Slice.Set`: a `Core.Slice(const T)` over C++ read-only memory would compile
    its store against the unqualified symbolic `T` and fault at runtime. Removed
    when `IndirectIndexWith` and `ref` returns land; `Core.Slice` then takes the
    `Span` shape.
-   **`i32` subscripts need `as i64`.** Only an integer literal converts to the
    `i64` subscript type implicitly. Removed when integer subscript widening is
    specified (an `IndexWith(i32)` impl, or a subscript rule for all integer
    types).
-   **No array-value to slice conversion.** Views are formed from `&a`. Removed
    only if an upstream indexing or slices design specifies the conversion.
-   **Unchecked slice access.** The release build's enforcement opt-out
    ([Safety: build modes](safety/README.md#build-modes)) has no spelling.
    Removed when build modes land (the check becomes mode-gated).
-   **The fail-stop message names the operation, not the index.** Removed when
    a runtime diagnostics facility exists.
-   **No `buf(T)` keyword shorthand.** Removed if the name stops being a
    placeholder.
-   **`Core.Buf` runs no element destructors and takes no `Allocator`.** The
    `Allocator` interface of [Classes](classes.md) needs `Deletable` and
    `Destructible` facets the toolchain lacks. Removed when explicit destroy
    calls or a `TrivialDestructor` facet, and an `Allocator` design, land;
    `Buf` then gains an allocator parameter defaulting to the global one.
-   **A `Core.Buf` stored in a field is not freed.** A class, struct, tuple,
    choice payload or array that holds a `Buf` destroys it through the
    toolchain's synthesized destructor for aggregates, whose body is still a
    placeholder that runs no member destructors; only a `Buf` that is itself a
    local variable or a temporary runs `impl as Destroy` and frees its block
    (W-108). Removed when destroy-op synthesis destroys members.
-   **Over-aligned element types** (alignment above `max_align_t`) are not
    supported: `malloc` guarantees 16 bytes.
-   **A byte count that overflows fails-stop.** `Make(size, fill)` computes
    `size * sizeof(T)` with overflow detection (`llvm.umul.with.overflow`); a
    count whose byte size does not fit in 64 bits takes the failed-allocation
    path ("heap allocation failed") rather than allocating a wrapped size.
-   **`var b: Core.Buf(i32);` is an error.** Removed when destroy becomes
    unformed-state-aware.
-   **`Buf.Resize`/`Push` do not exist.** The design's "mutable size" names the
    storage class, not an API.
-   **No compile-time evaluation of slice reads.** All four builtins are
    runtime-only; a constant `Core.Slice` never forms because `&a` of a local
    is not constant.
-   **Static-extent `std::span<T, N>` is not mapped** (W-119). Its object
    representation is a pointer only, so it imports as an ordinary class and
    no Carbon type exports to it. Removed if a static-extent view type is
    specified, or by a thunk-side conversion in the `std::initializer_list`
    style.
-   **Owning -> view consults member `data()`/`size()` only** (W-120). A
    container whose contiguous access comes only from free `data(x)`/`size(x)`
    functions gets no view conversion. Removed by adding the ADL stage the
    `for`-over-C++-ranges synthesis already has.

## Alternatives considered

-   A whole-operation `"slice.at"` builtin, like `"string.at"`: it would push
    the bounds check, the message and a by-value copy of an arbitrary `T` into
    the compiler; the composable `pointer.offset` + `fail_stop` form keeps every
    semantic line in Carbon source.
-   An implicit array-value to slice conversion: rejected for the dangling
    hazard described under [Forming a view](#forming-a-view).
-   `llvm.trap` instead of `abort`: the signal differs by architecture and no
    message can be written.
-   `exit(1)` instead of `abort`: not a fail-stop — it runs `atexit` handlers
    and flushes buffers.
-   A `Slice.Set`: the `const` element hazard above.
-   Running element destructors in `Buf`'s `Destroy` with an explicit
    `Destroy.Op` loop: no precedent for an explicit destroy call in Carbon
    source; left as a limit.
-   A `buf(T)` keyword: lexer churn for a placeholder name.
-   Placing the `Iterate` impl in `slice.carbon` (an import cycle with the
    iterate library) or mid-file in `iterate.carbon` (it would move every
    later method's source lines).

## References

-   [Arrays and buffers](README.md#arrays-and-buffers) and
    [Slices](README.md#slices) in the design overview
-   [Indexing](expressions/indexing.md): the `IndexWith` / `IndirectIndexWith`
    rewrite rules and the `Span` example
-   [Values: pointers](values.md#pointers): no indexing or arithmetic on
    pointers; "slice or view style types"
-   [Safety: build modes](safety/README.md#build-modes) and
    [Safety terminology: fail-stop](safety/terminology.md#fail-stop)
-   [Classes: destructors and the `Allocator` interface](classes.md)
-   Proposal
    [#2274: Subscript syntax and semantics](/proposals/p002274-subscript-syntax-and-semantics.md)
-   Proposal
    [#4682: The Core.Array type for direct-storage immutably-sized buffers](/proposals/p004682-the-core-array-type-for-direct-storage-immutably-sized-buffers.md)
    (the owning-buffer vocabulary table naming `Core.Buf(T)`)
-   [Milestones: the 0.1 standard library](/docs/project/milestones.md)
-   Fork: [fork/slices/plan.md](/fork/slices/plan.md) (decisions D-SL-1..14),
    [fork/decision-log.md](/fork/decision-log.md) (F-012)
