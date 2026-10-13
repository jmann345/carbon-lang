# Strings

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
    -   [The API](#the-api)
    -   [Names](#names)
-   [Comparison](#comparison)
-   [Concatenation](#concatenation)
-   [Ownership and lifetime](#ownership-and-lifetime)
-   [Subscripts](#subscripts)
-   [Interoperability](#interoperability)
-   [0.1 limits](#01-limits)
-   [Alternatives considered](#alternatives-considered)
-   [References](#references)

<!-- tocstop -->

## Overview

> **Fork design (F-014, 2026-10-13): the string types as implemented; toolchain
> status: ST-1 landed 2026-10-13.** This page is a fork amendment
> (fork/string/plan.md, decisions D-ST-1..16, recorded in the fork decision log
> under F-014 for after-the-fact veto). Upstream's
> [String types](README.md#string-types) are provisional and no design for
> string types has been through the proposal process; where upstream is silent,
> this page decides for the fork. The [0.1 limits](#01-limits) section lists
> every deviation from this design together with the condition under which it is
> removed.

Carbon has two string types, the split that
[String types](README.md#string-types) describes: an owning byte sequence and a
read-only view of one. Both hold bytes, which are treated as UTF-8 encoded text
but are not validated, compared or iterated as characters (proposal
[p006177](/proposals/p006177-c-interop-mapping-std-string-view-to-core-str.md):
"views over bytes, not Unicode characters").

-   **`str`**, the type of every
    [string literal](lexical_conventions/string_literals.md), is a non-owning
    view: a pointer to the first byte and a size, `{Char*, i64}`. It is
    copyable, and copying it copies the view, not the bytes. It maps to and from
    C++'s `std::string_view`. The `str` keyword names the prelude class
    `Core.String`.
-   **`Core.StringBuf`** is the owning string: the same `{pointer, size}`
    representation over a heap block that it allocates and that its `Destroy`
    impl frees. It is not copyable; `Core.StringBuf.Make(s)` is the explicit
    copy. It converts implicitly to `str`.

The view carries the read API (`Size()`, `s[i]`, comparison), so a
`Core.StringBuf` is read through its view:

```carbon
var s: Core.StringBuf = Core.StringBuf.Make("Carbon");
let v: str = s;
Core.Print(v.Size() as i32);  // 6
Core.PrintChar(v[0]);         // C
```

| `Core.StringBuf` member | Meaning |
| --- | --- |
| `fn Make(s: str) -> Self` | a new string holding a copy of `s`'s bytes; also the explicit deep copy of a `Core.StringBuf`, which converts to `str` at the call |
| `fn Concat(a: str, b: str) -> Self` | a new string holding `a`'s bytes then `b`'s; what every `+` impl calls |
| `fn Size(self) -> i64` | the number of bytes |
| `fn AsStr(self) -> str` | the view; valid until `self` is destroyed or appended to, and for a temporary `self` until the end of its full-expression |
| `impl as Destroy` | frees the block |
| `impl as AddAssignWith(str)`, `impl StringBuf as AddAssignWith(StringBuf)` | `s += t`: join into a new block, free the old one, then update `s` |
| `impl StringBuf as ImplicitAs(str)` | the owning-to-view conversion of [String types](README.md#string-types) |

Not provided, on purpose: `Copy` (a copy would share the block and free it
twice), `UnformedInit` (`Destroy` runs unconditionally on `var` storage, so
`var s: Core.StringBuf;` is an error), an implicit conversion from `str` (it
would hide an allocation; `Core.StringBuf.Make(v)` is the explicit form),
`IndexWith` and `Iterate` on `Core.StringBuf` (read through the view), and UTF-8
validation or character iteration.

### The API

The declarations of core/prelude/types/string.carbon, with function bodies
elided:

```carbon
class String {
  fn Size(self) -> i64;
  impl as Copy;
  fn UnsafeMake(p: Char*, size: i64) -> Self;
}

impl String as UnformedInit {}

impl forall [T: ImplicitAs(i64)] String as IndexWith(T) where .ElementType = Char {
  fn At(self, subscript: i64) -> Char = "string.at";
}

impl String as EqWith(String);
impl String as OrderedWith(String);

class StringBuf {
  fn Make(s: str) -> Self;
  fn Concat(a: str, b: str) -> Self;
  fn Size(self) -> i64;
  fn AsStr(self) -> str;
  impl as Destroy;
  impl as AddAssignWith(str);
}

impl StringBuf as ImplicitAs(str);
impl StringBuf as AddAssignWith(StringBuf);
impl String as AddWith(String) where .Result = StringBuf;
impl String as AddWith(StringBuf) where .Result = StringBuf;
impl StringBuf as AddWith(String) where .Result = StringBuf;
impl StringBuf as AddWith(StringBuf) where .Result = StringBuf;
impl String as EqWith(StringBuf);
impl StringBuf as EqWith(String);
impl StringBuf as EqWith(StringBuf);
impl String as OrderedWith(StringBuf);
impl StringBuf as OrderedWith(String);
impl StringBuf as OrderedWith(StringBuf);
```

`String.UnsafeMake(p, size)` forms a view of `size` bytes at `p`; the caller
guarantees that they stay valid and unchanged for as long as the view is used.
It is public because `Core.StringBuf.AsStr` needs it and Carbon has no `friend`
yet.

### Names

The prelude class that `str` names is called `String`, as upstream's is.
Proposal p006177 calls the view `Core.Str` and reserves `String`-like names for
owning types ("The choice of `Str` over `String` for the non-owning view type is
intentional. It avoids confusion with owning types like C++'s `std::string`"),
but upstream has not renamed the class, and three toolchain sites key on its
name. The fork therefore keeps `Core.String` for the view and names the owning
type `Core.StringBuf`, "the heap buffer of a string", in the vocabulary of
[`Core.Buf(T)`](slices.md). In the terms of
[String types](README.md#string-types), the design's `StringView` is `str` and
its owning `String` is `Core.StringBuf`. When upstream renames the view to `Str`
and names the owning type, `Core.StringBuf` takes that name; the layout does not
change.

## Comparison

`==`, `!=`, `<`, `<=`, `>` and `>=` are implemented for every pair of `str` and
`Core.StringBuf` operands, as explicit `EqWith` and `OrderedWith` impls, because
the `EqWith` overload is selected without considering implicit conversions
([Comparison operators](expressions/comparison_operators.md#equality)).

-   **Equality** is byte-wise: two strings are equal when they have the same
    size and the same bytes.
-   **Ordering** is lexicographic on bytes compared as unsigned values: the
    first differing byte decides, and otherwise the shorter string, a proper
    prefix of the longer, orders first.

This is exactly the order of C++'s `std::string_view` and `std::string`, whose
`char_traits<char>::compare` compares bytes as `unsigned char` (the C++
standard's `[char.traits.specializations.char]`), so a C++ program is a
differential oracle for Carbon's string comparisons. The order is transitive and
consistent under reversal, and equality refines it (equal bytes and sizes
exactly when neither string orders before the other), as
[Comparison operators](expressions/comparison_operators.md#compatibility-of-equality-and-ordering)
asks. Generic code sees `str` as `Core.Eq` and `Core.Ordered`.

```carbon
var joined: Core.StringBuf = "app" + "le";
Core.Print(if joined == "apple" then 1 else 0);   // 1
Core.Print(if "apricot" > joined then 1 else 0);  // 1: 'r' > 'p' at index 2
Core.Print(if "app" < "apple" then 1 else 0);     // 1: a proper prefix first
Core.Print(if "\xC3\xA9" > "z" then 1 else 0);   // 1: 0xC3 > 0x7A unsigned
```

Comparisons are run-time operations; they are not compile-time constants (see
[0.1 limits](#01-limits)).

## Concatenation

`+` on (`str`, `str`), (`str`, `Core.StringBuf`), (`Core.StringBuf`, `str`) and
(`Core.StringBuf`, `Core.StringBuf`) returns a new `Core.StringBuf` holding the
left operand's bytes followed by the right's. Chains associate left to right, so
`a + b + c` allocates one intermediate block and one result. `+=` with a `str`
or `Core.StringBuf` right operand appends in place, and is the spelling for
loops:

```carbon
let piece: str = "abc";
var s: Core.StringBuf = piece + piece + piece;  // a temporary, then s
s += "!";  // one new block; the previous one is freed

let words: array(str, 4) = ("Car", "bon", " ", "0.1");
var acc: Core.StringBuf = Core.StringBuf.Make("");
for (w: str in words) {
  acc += w;
}
```

The append allocates the joined block, copies both parts into it, frees the old
block and only then updates the string, so the right operand is read before
anything is freed. Sizes add in `i64`; a sum past the address space fails-stop
as an allocation failure. There is no `char` operand: `s + 'c'` is an error.

Appending a string to itself is spelled with an explicit copy:

```carbon
s += Core.StringBuf.Make(s);
```

The self-aliasing append `s += s` (or `s += v` where `v` views `s`) is accepted
and memory-safe in today's toolchain, because of the read-before-free order
above, but it is not part of the design. Under the fork's safety design F-013,
which this page adopts as governing, the by-value right operand of
`AddAssignWith(StringBuf).Op` is a shared loan on `s` for the call (T2's
value-binding clause, mutation-safety rule M8), and the `ref self` call
invalidates `s`, so T4 rejects the pair as `StrictSharedBorrowInvalidated` once
the loan checker (W-148) lands, as Rust rejects `s.push_str(&s)`. The explicit
copy is the spelling that stays valid.

## Ownership and lifetime

-   A `Core.StringBuf` that the prelude builds (`Make`, `Concat`, every `+`)
    owns exactly one heap block, never null: a zero-byte string still has a
    one-byte block, and an allocation failure is the fail-stop "carbon: heap
    allocation failed; terminating".
-   Its `Destroy` impl frees the block when a `var` goes out of scope, when a
    temporary is destroyed, and when an enclosing object whose type does not
    declare its own `Destroy` is destroyed.
-   It is never copied implicitly. A function returns a string it builds as
    `Core.StringBuf`, either directly or through `returned var`; `return s;` of
    a plain `var` is a copy, and an error:

    ```carbon
    fn Concat(a: str, b: str) -> Core.StringBuf { return a + b; }

    fn MakeGreeting(who: str) -> Core.StringBuf {
      returned var g: Core.StringBuf = "Hello, " + who;
      g += "!";
      return var;
    }
    ```

-   A `str` view of a `Core.StringBuf` is valid until that string is destroyed
    or appended to. A view of a temporary `Core.StringBuf`, such as the result
    of `+`, is valid until the end of the full-expression that creates the
    temporary. This is the rule of F-013 decision D-SAFE-12 ("A loan on a
    temporary lives until the end of the full-expression"); upstream leaves the
    lifetime of temporaries open
    ([Values](values.md#temporary-materialization): "The lifetimes of
    temporaries is not yet specified"). Code that keeps a view binds a `var`
    owner first:

    ```carbon
    var c: Core.StringBuf = a + b;
    let v: str = c;
    ```

-   Today's toolchain destroys a declaration initializer's temporaries at the
    end of the enclosing block, and an expression statement's at the end of the
    statement. That is toolchain behavior, not design: programs must not rely
    on a view of a temporary outliving its full-expression.
-   **A function returning `str` never returns a `+` result or a local
    `Core.StringBuf`; it returns `Core.StringBuf`.** The returned view would
    read a block that is freed when the function returns, and nothing
    diagnoses it yet (see [0.1 limits](#01-limits)):

    ```carbon
    // Wrong: the `+` result is a temporary destroyed when Join returns, so
    // the caller's view reads freed memory.
    fn Join(a: str, b: str) -> str { return a + b; }

    // Right: return the owner; the caller views it while it lives.
    fn Join(a: str, b: str) -> Core.StringBuf { return a + b; }
    ```

## Subscripts

`s[i]` on a `str` is the [indexing](expressions/indexing.md) rewrite to
`String as IndexWith(T)`, for every subscript type `T` that converts implicitly
to `i64`; its `At` function takes the subscript as `i64`, so the conversion
happens before the `"string.at"` builtin sees it. An integer literal subscript
on a run-time string and a `u8` subscript above 127 therefore read the byte they
name. A constant subscript of a constant string is still checked at compile time
("index `-1` is negative", "string index `4` is out of bounds; string has
length 4"). There is no run-time bounds check (see [0.1 limits](#01-limits)).
A `Core.StringBuf` has no subscript of its own; it is read through its view.

## Interoperability

`str` and C++'s `std::string_view` map to each other in both directions
([`std::string_view` and `str`](interoperability/README.md#stdstring_view-and-str)),
so a `std::string_view` returned by C++ compares with and concatenates to Carbon
strings like any `str`. A `Core.StringBuf` reaches a `std::string_view`
parameter through its view:

```carbon
var s: Core.StringBuf = Core.StringBuf.Make("hello");
Cpp.ViewSize(s.AsStr());
```

C++ overload resolution does not see Carbon's `ImplicitAs(str)` conversion, so
`AsStr()` is required: passing the `Core.StringBuf` itself is diagnosed as a
call argument whose type is not supported. There is no `std::string` mapping in
either direction; the milestone requires only the non-owning string mapping
([Milestones](/docs/project/milestones.md)).

## 0.1 limits

Each limit is a filed fork work item, with the condition under which it is
removed:

-   **W-160: assignment does not destroy the overwritten value.** `s = t;` on a
    `Core.StringBuf` leaks the old block, as it does for a `Core.Buf` or any
    class with a `Destroy`, because `=` neither uses `AssignWith` nor destroys
    the old value. Loops append with `+=`. Removed when assignment destroys the
    value it overwrites, or is routed through `AssignWith`.
-   **W-161: owning-string C++ interop.** `Core.StringBuf` has no
    `std::string` mapping, and a `Core.StringBuf` argument needs `AsStr()`.
    Removed when owning-string interop is designed (a `std::string` mapping or a
    thunk-side conversion, and Carbon conversions in C++ overload resolution).
-   **W-162: no run-time bounds check on `str` subscripts.** `"string.at"`
    lowers to an unchecked byte access, whereas `Core.Slice` and `Core.Buf`
    subscripts fail-stop. Removed when the builtin's lowering emits the
    fail-stop sequence.
-   **W-163: string comparisons are not compile-time constants.** `C("x" ==
    "x")` for a `bool` generic parameter is rejected. Removed by comparison
    builtins with compile-time evaluation, or by compile-time evaluation of
    function bodies.
-   **W-165: an initializing `str` argument to an uninstantiated
    `basic_string_view<char>` parameter crashes Clang.** Only a mock
    `basic_string_view` whose specialization no code instantiates is affected;
    libc++'s `<string_view>` is not. Removed when overload resolution checks
    that the parameter type is complete before querying its move constructor.
-   **W-166: a `str` view of a `Core.StringBuf` can outlive its owner with no
    diagnostic.** A `-> str` function returning a `+` result or a local owner, a
    `str` field initialized from a temporary, and a view held across `+=`
    compile and read freed memory. Removed when the loan checker of F-013
    (W-148) lands and diagnoses them; until then, follow the rules of
    [Ownership and lifetime](#ownership-and-lifetime).
-   **W-167: struct-literal construction of a class bypasses private-field
    access control.** [Classes](classes.md#access-control-for-construction)
    allows construction only with access to every field, but the toolchain does
    not check it, so user code can forge a `Core.StringBuf`, or a `Core.Buf`,
    whose `Destroy` frees a pointer that was never allocated. Removed when
    construction checks field access.
-   **A class that declares its own `Destroy` does not destroy a
    `Core.StringBuf` field** (W-126). Removed when a declared destructor
    destroys the object's fields.
-   **An `if` expression with a `Core.StringBuf` temporary in an arm is a
    semantics TODO** (W-122). Build the string in each branch where it is used.

## Alternatives considered

-   **Rename the view to `Core.Str` and make `Core.String` the owning type.** It
    matches proposal p006177's names, but renames an upstream class that the
    toolchain keys on by name, changes every golden that prints it, and preempts
    the rename upstream will choose.
-   **Keep `str` the only type, with `+` allocating a block that is never
    freed.** Every concatenation in a loop leaks, and it contradicts the
    owning/view split of [String types](README.md#string-types).
-   **Comparison builtins lowered to `memcmp`.** Four toolchain sites and a
    lowering arm for no measured benefit; kept as the mechanism for compile-time
    comparison (W-163).
-   **Blanket impls over `T: ImplicitAs(str)` for the mixed comparisons, as
    `Char` has.** Every `str == str` would choose among several candidate impls
    and instantiate a generic impl per use, for one convertible type.
-   **`Core.StringBuf` as a wrapper of a `Core.Buf(Char)` field.** `+=` must
    replace the block, which a field cannot do without move semantics, and a
    declared `Destroy` on the owner would leave the field undestroyed.
-   **A separate prelude file for `Core.StringBuf`.** The orphan rule keeps
    `String`'s `AddWith` impls with `String`, and they name `Core.StringBuf`, so
    the two files would import each other.
-   **A bounds-checked `str` subscript written in Carbon.** A Carbon `At` body
    is not evaluated at compile time, so `"Test"[4]` would stop being a
    compile-time error.
-   **Fixing literal subscripts in the `"string.at"` lowering.** It needs the
    subscript's signedness and constant in the lowering; the `i64` parameter
    does both through existing conversions, in the spelling `Char`'s impls
    already use.

## References

-   [String types](README.md#string-types) in the design overview
-   [String literals](lexical_conventions/string_literals.md)
-   [Comparison operators](expressions/comparison_operators.md)
-   [Arithmetic: strings](expressions/arithmetic.md#strings) (the `+` question,
    issue 457)
-   [Values: temporary materialization](values.md#temporary-materialization)
-   [Slices](slices.md): `Core.Buf(T)`, the heap builtins and the fail-stop
-   Proposal
    [#6177: C++ Interop: Mapping `std::string_view` to `Core.Str`](/proposals/p006177-c-interop-mapping-std-string-view-to-core-str.md)
-   [Milestones](/docs/project/milestones.md): "String and related types used
    with string literals"
-   Fork: [fork/string/plan.md](/fork/string/plan.md) (decisions D-ST-1..16),
    [fork/decision-log.md](/fork/decision-log.md) (F-014)
