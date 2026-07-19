# Unions

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Overview](#overview)
    -   [When to use `choice` vs `union`](#when-to-use-choice-vs-union)
-   [Declaring a union](#declaring-a-union)
    -   [Union members](#union-members)
    -   [The `union` keyword](#the-union-keyword)
-   [Field rules in 0.1](#field-rules-in-01)
    -   [Trivially destructible and trivially copyable types](#trivially-destructible-and-trivially-copyable-types)
    -   [Union fields](#union-fields)
-   [Initialization and assignment](#initialization-and-assignment)
-   [Writing and reading fields](#writing-and-reading-fields)
    -   [Writes](#writes)
    -   [Reads](#reads)
    -   [Aliasing](#aliasing)
    -   [Strict Carbon and future safety hooks](#strict-carbon-and-future-safety-hooks)
-   [Layout](#layout)
-   [Anonymous unions](#anonymous-unions)
-   [C++ interoperability](#c-interoperability)
    -   [Importing C++ unions](#importing-c-unions)
    -   [Exporting Carbon unions to C++](#exporting-carbon-unions-to-c)
    -   [Round-trip guarantee](#round-trip-guarantee)
-   [Relationship to choice types](#relationship-to-choice-types)
-   [Decisions within this design](#decisions-within-this-design)
-   [Alternatives considered](#alternatives-considered)
-   [References](#references)

<!-- tocstop -->

## Overview

A _union_ is a nominal type whose fields all share the same storage. At most one
field's value is meaningfully stored at a time; writing one field replaces the
bytes of every other field. Unlike a [choice type](sum_types.md), a union is
_un-discriminated_: it carries no tag recording which field was written last,
and no hidden state of any kind. Its size is the size of its largest field,
rounded up to the union's alignment (see [Layout](#layout)), in accordance with
Carbon's
[performance goals](/docs/project/goals.md#performance-critical-software) of no
hidden overhead.

Unions exist for three reasons:

-   **C++ interoperability and migration.** C++ codebases use unions pervasively
    — hand-rolled tagged unions, wire and protocol structs, small type puns.
    Carbon code must be able to use imported C++ unions, and migrated C++ unions
    must have an obvious and unsurprising Carbon spelling. Both directions of
    mapping are specified [below](#c-interoperability).
-   **A specified low-level storage primitive.** User-defined
    [sum types](sum_types.md#user-defined-sum-types) and the compiler's own
    lowering of payload-carrying [choice types](#relationship-to-choice-types)
    need overlapping storage with a guaranteed layout. Unions are that
    primitive.
-   **Expressivity parity.** Data structures that are naturally written with a
    union in C++ should be
    [naturally writable in Carbon](/docs/project/goals.md#code-that-is-easy-to-read-understand-and-write).

Unions are the one place in current Carbon where object layout is fully
guaranteed, because interoperability demands it; class layout control remains
[future work](classes.md#memory-layout).

### When to use `choice` vs `union`

**Default to [`choice`](sum_types.md).** A `choice` type is Carbon's type-safe
tagged union — the equivalent of a Rust `enum` — and the recommended way to
express "one of several alternatives": it stores and checks its own
discriminant, is consumed with exhaustive pattern matching, and (unlike a
union's fields) its payloads may be of any type. In ordinary Carbon code,
`union` exists for C++ interoperability and migration only (per the user's
sub-decision F-007b): reach for it when using or migrating C++ code that uses
a union — that is, when the discriminator is external (or intentionally
absent) and layout is part of the type's contract.

Payload-carrying `choice` alternatives are not yet implemented in the
toolchain (fork workstream W5; see
[fork/gap-analysis.md](/fork/gap-analysis.md)). When they land, they lower
onto the overlapping-storage contract this document specifies — see
[Relationship to choice types](#relationship-to-choice-types).

## Declaring a union

A union declaration consists of the `union` keyword introducer, a name, and a
body of member declarations in curly braces:

```carbon
union IntOrBytes {
  var word: u32;
  var bytes: array(u8, 4);
}
```

This declares a nominal type `IntOrBytes` with two fields that occupy the same
four bytes of storage.

Unions may be forward-declared like classes (`union IntOrBytes;`), may be
declared at file scope, in namespaces, or as members of classes, and may be
parameterized like [generic classes](generics/details.md#parameterized-types):

```carbon
union Slot(T: type) {
  var value: T;
  var next_free: Slot(T)*;
}
```

In 0.1, generic unions are supported as they fall out of the general machinery,
but only concrete instantiations are covered by the conformance suite.

### Union members

The body of a union may contain:

-   **Fields**, declared with `var`, subject to the
    [field rules](#field-rules-in-01). Every field is located at offset zero;
    declaration order has no layout effect.
-   **Member functions**, including methods, which declare `self` (or, for
    mutation, `ref self`) as the first parameter in the explicit parameter list,
    exactly as in [classes](classes.md#methods).
-   **`impl` declarations** and `alias` declarations, as in classes.

```carbon
union Bits64 {
  var word: u64;
  var halves: array(u32, 2);

  fn LowHalf(self) -> u32 { return self.halves[0]; }
}
```

A union may not contain:

-   `base class` or `extend base` declarations. Unions do not participate in
    inheritance in either direction — they are implicitly `final`, cannot be
    used as base types, and cannot extend anything. This matches C++, where
    unions cannot be base classes or derive.
-   `abstract`, `base`, or `virtual` modifiers, for the same reason.
-   `adapt` declarations.
-   Nested type declarations in 0.1 (including
    [anonymous unions](#anonymous-unions) authored in Carbon).

A Carbon-authored union must declare at least one field. (Empty _imported_ C++
unions are handled under [Importing C++ unions](#importing-c-unions).)

### The `union` keyword

`union` is a new declaration-introducer keyword. In the toolchain, keywords live
in `toolchain/lex/token_kind.def`, where declaration introducers form a
dedicated alphabetized block of `CARBON_DECL_INTRODUCER_TOKEN` entries. Adding
the keyword is one line in that block, between `Require` and `Var`:

```
CARBON_DECL_INTRODUCER_TOKEN(Union,       "union")
```

That one line updates the lexer's keyword machinery and the check-stage
introducer dispatch (`DeclIntroducerStateStack::IsDeclIntroducer` in
`toolchain/check/decl_introducer_state.h` is generated from the same block). The
_parser's_ introducer dispatch is not generated from the `.def` file: the
`DeclIntroducers` table in `toolchain/parse/handle_decl_scope_loop.cpp` is
hand-populated, so the new keyword additionally needs an explicit entry there
naming the union introducer's parse node kind and state (mirroring the existing
`choice` entry), plus the corresponding case in the statement-context dispatch
in `toolchain/parse/handle_statement.cpp`.

Like `class` and `choice` — and unlike `fn` and `var` — the token does not need
a `CARBON_TOKEN_WITH_VIRTUAL_NODE` wrapper, since a union declaration's parse
tree does not introduce a virtual node at the introducer.

Consequences of `union` becoming a keyword:

-   `union` is no longer a valid plain identifier anywhere. Existing code using
    it as an identifier must spell it as the
    [raw identifier](lexical_conventions/words.md#raw-identifiers) `r#union`.
    (No identifier named `union` exists in `core/`, `examples/`, or the test
    suites, so no migration is needed in this repository. C++ headers cannot
    declare an entity named `union` either, since it is also a C++ keyword, so
    interop never forces the raw spelling.)
-   The lexer's keyword coverage tests update mechanically from the `.def` file.
    The editor and highlighter grammars under `utils/` (the Vim syntax file, the
    TextMate and VS Code grammars, the tree-sitter grammar, and the highlight.js
    definition) hard-code their keyword lists and each need a one-word manual
    update.

## Field rules in 0.1

### Trivially destructible and trivially copyable types

This design defines the following two predicates over Carbon types. They are
defined once, here, and reused by every part of the design that needs them — the
union field rules below, [union export](#exporting-carbon-unions-to-c), and
sibling designs such as the `std::atomic` interop and `Carbon::expected` export
work — rather than restated at each use site:

-   A type is **trivially destructible** if it carries no destruction
    obligation: no [destructor](classes.md#destructors) anywhere in the type or
    its subobjects, so that destroying a value is a no-op.
-   A type is **trivially copyable** if it is trivially destructible and copying
    or assigning a value is exactly copying its object representation — its
    bytes — with no user-provided or otherwise non-trivial copy operation
    anywhere in the type or its subobjects.

Integer, floating-point, `bool`, and `char` types satisfy both, as do pointers,
and arrays, tuples, structs, classes, choice types, and unions whose members
recursively satisfy them. Any type with a user-provided destructor or
non-trivial copy operation satisfies neither predicate.

### Union fields

In 0.1, every field of a Carbon-authored `union` declaration must be of a type
that is both
[trivially destructible and trivially copyable](#trivially-destructible-and-trivially-copyable-types).
Violations are diagnosed at the point where the union type is required to be
complete. These field rules (like the at-least-one-field rule
[above](#union-members)) govern `union` declarations written in Carbon; the
shape of an _imported_ C++ union is governed by C++'s own rules, as specified in
[Importing C++ unions](#importing-c-unions).

Rationale: because a union does not know which field is live, it cannot run the
right destructor or the right copy constructor. Restricting fields to types for
which destruction is a no-op and copying is a byte copy makes the union itself
trivially destructible and trivially copyable, so no operation on a union ever
needs lifetime bookkeeping the type cannot do. This is the same restriction
Rust's `union` shipped with, and it is the restriction under which every union
operation in this document is well-defined.

Imported C++ unions with non-trivial members are still usable: C++ itself
deletes the union's corresponding special member functions in that situation,
and the importer preserves those deletions — see
[Importing C++ unions](#importing-c-unions). Carbon-authored unions with
non-trivial fields (following the C++ deleted-members model, or a
`ManuallyDrop`-style wrapper) are deliberate future work.

## Initialization and assignment

A union variable declared without an initializer is in the
[unformed state](README.md#unformed-state). Support for unformed states is
opt-in in Carbon — a type provides it by implementing a particular interface —
and every union provides it: because every union is
[trivially destructible and trivially copyable](#trivially-destructible-and-trivially-copyable-types)
under the 0.1 [field rules](#field-rules-in-01), any in-memory representation
satisfies the unformed-state requirements (assignment and destruction are
correct, and destruction is optional), exactly as for `i32`. The first write to
a field forms the variable.

```carbon
var u: IntOrBytes;          // Unformed.
u.word = 0x01020304;        // Forms `u`; `word` is now the written field.
```

A union may also be initialized from a struct literal that designates **exactly
one** of its fields:

```carbon
var v: IntOrBytes = {.word = 0x01020304};
```

Struct literals designating zero fields or more than one field do not convert to
a union type; there is no whole-union aggregate initialization, because fields
overlap.

Because of the [field rules](#field-rules-in-01), every union is itself
trivially copyable: copy initialization and assignment from another value of the
same union type copy the union's full object representation — all `size(U)`
bytes — regardless of which field was written last. This matches what C++
guarantees for trivially copyable unions and is what wire-format code depends
on.

> **Implementation note:** initializing class-shaped types that use the
> explicit-layout object representation from struct literals is the one
> conversion path not yet wired in the toolchain (`toolchain/check/convert.cpp`
> currently bails out of builtin conversion for them). Wiring it is part of this
> design's implementation and also completes construction of _imported_ C++
> union values, which use the same representation.

## Writing and reading fields

### Writes

Writing a field of a union is always safe and always permitted:

```carbon
u.word = 0xAABBCCDD;
```

A write to field `f` stores the object representation of the new value into the
first `size(f)` bytes of the union's storage. Bytes of the union beyond
`size(f)`, if any, are unchanged. The write makes `f` the _written field_; no
record of this is kept at runtime.

Given the 0.1 [field rules](#field-rules-in-01), a write never needs to destroy
a previous value (destruction is trivial for every permissible field type), so
there is no operation on a union that can leak or double-destroy.

### Reads

Reading a field of a union is **defined byte reinterpretation**. The exact rule:

> Reading field `f` of type `T` from a union object takes the first `size(T)`
> bytes of the union's storage and interprets them as an object representation
> of `T`.
>
> -   If those bytes are a valid object representation of some value `v` of `T`,
>     the read evaluates to `v`. This holds **regardless of which field was last
>     written**.
> -   Otherwise, the program is erroneous. The behavior of the erroneous read is
>     limited: it either produces an unspecified value of `T` or terminates the
>     program (for example, under the debug
>     [build mode](safety/README.md#build-modes), which gives detectable
>     erroneous behavior fail-stop semantics). It is _not_ undefined behavior:
>     it cannot retroactively alter the meaning of other code, and the
>     implementation may not optimize on the assumption that it does not occur.

Consequences of this rule:

-   For types where every bit pattern is a valid representation — integer types
    of every width, `char`, arrays and structs of such types — every union read
    is defined, including reads that overlap bytes never written (such bytes
    hold unspecified values, and the read yields a correspondingly unspecified
    but valid result).
-   For types with invalid representations — for example `bool`, which is
    represented only by 0 or 1 — a read is defined exactly when the underlying
    bytes happen to form a valid value.
-   Pointer types are in the invalid-representations bucket, not the
    every-pattern-valid one: there are
    [no null pointers in Carbon](README.md#pointer-types), so the null bit
    pattern is not a valid object representation of any `T*`. After writing
    integer zero through an integer field, reading a pointer-type field of the
    same union is erroneous under the rule above, exactly like reading the byte
    `2` through a `bool` field. (This also preserves the layout `Optional(T*)`
    relies on, which uses the null representation for its no-pointer state.)
    Migrated C++ code that puns a pointer against an integer and uses zero as a
    sentinel should declare the field with type `Optional(T*)` — a permitted,
    trivially copyable field type for which the null pattern _is_ a valid
    representation. When a pointer-field read is defined, _dereferencing_ the
    resulting pointer is governed by the ordinary pointer rules, not by this
    one.
-   The C++ _common initial sequence_ guarantee is subsumed: if two struct
    fields of a union share a common initial sequence of members, the common
    part has the same bytes at the same offsets through either field, so reading
    it through the not-last-written field is bytes-valid and therefore defined.
    Migrated C++ code that hand-rolls tagged unions this way keeps working, with
    a stronger guarantee than C++ gave it.

This is deliberately **stronger than C++**, where reading a non-active union
member is undefined behavior outside the common-initial-sequence carve-out, and
matches Rust's union semantics and the de-facto C model that migrated code
silently assumes. The strengthening has no runtime or optimizer cost in this
toolchain: union accesses lower to byte-offset accesses into an untyped byte
array (see [Layout](#layout)), which carry no type-based aliasing claims to
lose.

### Aliasing

An access to any field of a union is an access to the whole union object. Union
field accesses carry no type-based aliasing assumptions: the implementation must
not assume that accesses through different fields of the same union refer to
disjoint storage. A pointer or reference to a union field aliases every field of
that union.

### Strict Carbon and future safety hooks

Under Carbon's [safety strategy](safety/README.md#safety-modes), reading a union
field is an unsafe capability in the narrow sense: it is a type-punning
operation and nothing more. The design commits to the following, in line with
that strategy:

-   In **Strict Carbon**, reading a union field will require the `unsafe`
    marker; writing a field will not. The concrete spelling belongs to the
    safety-mode syntax design and does not exist yet — **0.1 ships the
    Permissive Carbon behavior described above, with no marker**, which is the
    mode intended for C++ interop and migration anyway. This is a documented
    dependency, not a gap in the union semantics: the read rule above is the
    same in both modes; only the required syntax differs.
-   A **debug-build discriminator** — tracking the written field in the debug
    [build mode](safety/README.md#build-modes) (and its specialized extensions)
    and diagnosing mismatched reads that the validity rule alone cannot catch —
    is planned future work, in the spirit of Zig's checked unions and upstream
    discussion
    [#1907](https://github.com/carbon-language/carbon-lang/discussions/1907). It
    is permitted by this design because build modes may change the _behavior_ of
    erroneous operations; it may not change union _storage_: unlike Zig's
    in-object safety tag, the tracked discriminator must live out of band (for
    example in shadow memory), because the [layout](#layout) guarantee holds in
    every build mode — C++ code compiled with no knowledge of the check must
    still agree on size and offsets. The tracking is never present in release
    builds.

## Layout

Union layout is **guaranteed**, not implementation-defined, and is the same in
every [build mode](safety/README.md#build-modes) — see
[above](#strict-carbon-and-future-safety-hooks) for why debug-mode checking must
not change it:

-   Every field is at offset 0.
-   `align(U)` is the maximum alignment of the fields.
-   `size(U)` is the maximum size of the fields, rounded up to a multiple of
    `align(U)`.

This is exactly the C and C++ union layout rule, so a Carbon union and a C++
union with corresponding member types have identical size, alignment, and field
offsets by construction. Note the contrast with classes, where Carbon reserves
the right to reorder and pack fields and layout control is
[future work](classes.md#memory-layout): unions commit to a layout now because
the [interop mapping](#c-interoperability) is only sound if both sides agree on
bytes.

In the toolchain, this guarantee is carried by the explicit-layout object
representation that already exists for imported C++ records:
`SemIR::CustomLayoutType`, which records an explicit size, alignment, and
per-field offset list, and which lowers to an LLVM `[size x i8]` byte array with
field accesses lowered to byte-offset accesses. Imported C++ unions already use
this representation with every field offset 0; a Carbon-authored `union` builds
the _same_ representation, with size and alignment computed by the max rule
above at type completion. Nothing about the representation or its lowering
distinguishes an imported union from a native one — which is the point.

## Anonymous unions

C++ anonymous unions — union members of a struct or class with no name, whose
fields are injected into the enclosing scope — are **supported on import**. The
importer flattens the injected fields to their accumulated byte offsets in the
enclosing record's explicit layout, so Carbon code accesses them exactly as C++
code does:

```carbon
// C++: struct S { int kind; union { int i; float f; }; };
fn UseImported(s: Cpp.S*) -> i32 {
  s->f = 1.5;       // Member of the anonymous union, injected into `S`.
  return s->kind;
}
```

Declaring an anonymous union _in Carbon_ (a fieldless `union { ... }` member
inside a `class` or `union`) is **not part of 0.1**. The workaround is a named
union field, which has identical layout and differs only by one name component.
Migration tooling may rely on this rewrite. Carbon-authored anonymous unions are
future work, pending the general design for unnamed members and name injection.

C++ union members declared as bit-fields are not imported (the importer skips
bit-field members, and Carbon has no bit-field design). This is a documented
limitation of 0.1 interop, not specific to unions.

## C++ interoperability

The mapping is bidirectional, per the
[0.1 milestone](/docs/project/milestones.md#type-system): "C++ interop: mapping
to and from C++ unions."

### Importing C++ unions

An imported C++ union **is** a Carbon union: the same kind of entity a native
`union` declaration produces, not an opaque interop type. Its _shape_, however,
is governed by its C++ definition, not by the declaration rules for
Carbon-authored unions: the [0.1 field rules](#field-rules-in-01) and the
at-least-one-field requirement constrain what a Carbon `union` declaration may
say, while an imported union has exactly the members C++ gave it, with Clang's
determinations preserved as described below.

-   `Cpp.U` names the imported union; imports work at any nesting depth
    (namespaces, member unions of classes).
-   Fields are readable and writable from Carbon under the
    [read](#reads)/[write](#writes) semantics above. Note that Carbon's
    byte-reinterpretation read rule is _stronger_ than the C++ rule that governs
    the same bytes on the C++ side of the program; this is sound because it
    constrains the Carbon compiler, and asks nothing new of the C++ side.
-   Union values pass and return by value and by pointer across the boundary
    unchanged; layout agreement is by construction, since the importer copies
    Clang's computed record layout into the explicit-layout representation.
-   Anonymous union members are flattened and injected as
    [described above](#anonymous-unions).
-   A C++ union with a member that has a non-trivial constructor, destructor, or
    copy operation has the corresponding special members deleted in C++ unless
    user-provided; the import preserves exactly Clang's determination. Carbon
    code is never _more_ permitted than C++ code with such a union.
-   Constructing an imported union value from Carbon uses designated
    single-field initialization, identically to native unions (see the
    [implementation note](#initialization-and-assignment)).
-   An empty C++ union (permitted in C++, not in a Carbon `union` declaration)
    imports as a union with no fields: its values can be created, copied, and
    passed across the boundary, and there is simply nothing to read or write.

### Exporting Carbon unions to C++

An exported Carbon union appears to C++ as a **genuine union**: the export
machinery that creates a `clang::CXXRecordDecl` for exported Carbon classes
creates the record with `TagTypeKind::Union` for a Carbon union. Because
Carbon's union layout rule is C++'s union layout rule, the layout Clang computes
for the exported record and the layout Carbon computed for the original type
agree field-for-field; there is no translation layer and no wrapper.

Given the 0.1 [field rules](#field-rules-in-01), every exportable Carbon union
is trivially copyable and trivially destructible, so C++ sees an ordinary
trivial union with no deleted special members. Carbon methods on the union
export under the same rules as class methods.

### Round-trip guarantee

A union declared in either language and passed across the boundary — by value or
by pointer, in either direction, any number of times — observes the same bytes
at the same offsets. Field writes on one side are visible to field reads on the
other under each language's own read rules. This guarantee is what the
conformance suite tests: execution round-trip programs, not just
declaration-checking, in both directions.

## Relationship to choice types

[Choice types](sum_types.md) are the discriminated counterpart of unions, and
this design fixes the contract between them:

> **The storage of a payload-carrying `choice` type is a discriminant together
> with union storage for the payloads**: all payload tuples overlap at a common
> offset, in storage sized and aligned by the same max-of-fields rule specified
> in [Layout](#layout), using the same explicit-layout object representation.
> `choice` lowering must build on this machinery rather than a private
> overlapping-storage mechanism.

In other words, a choice such as

```carbon
choice Optional(T: type) {
  Some(value: T),
  None
}
```

has the layout of "discriminant plus a union of its payload types", and the
compiler implements it that way. The overlapping-storage design decision is made
once — here — and inherited by choice, by
[user-defined sum types](sum_types.md#user-defined-sum-types), and by the
`std::variant` interop mapping built on choice.

This contract operates at the level of the compiler's layout machinery — the
explicit-layout object representation described in [Layout](#layout) — not at
the level of source `union` declarations, and the source-level
[0.1 field rules](#field-rules-in-01) therefore do not constrain choice
payloads. A payload type that is not trivially copyable or destructible, such as
`String` in the [`IntResult` example](README.md#choice-types), is fine in a
choice: a choice knows its discriminant, so it can run the correct destructor
and copy operation for the live alternative — exactly the knowledge an
un-discriminated union lacks, and the reason the union field rules exist. Such a
choice could not be re-expressed as a tag plus a source-level `union` in 0.1;
the compiler's lowering is under no such restriction, because it only borrows
the union _layout_ rule, never a union _declaration_.

**Dependency, stated plainly:** payload-carrying choice alternatives and the
`match` statement are not yet implemented in this toolchain (`choice` today
supports only payload-free alternatives, and `match` is unimplemented). This
design does not depend on them — unions are complete and testable without any
pattern matching, since unions deliberately do not participate in `match` (they
have no discriminator). The dependency runs the other way: when choice payloads
are implemented, they must lower onto the storage specified here.

## Decisions within this design

These points were open questions in the design sprint; they are decided here as
part of the accepted design (decision
[F-007](/fork/decision-log.md#f-007-unions--native-union-declaration-2026-07-19)),
and every sub-decision below was ratified by the user through the fork's
decision process, recorded in [fork/decision-log.md](/fork/decision-log.md).

1.  **Standalone `union` introducer**, not a `union class` modifier. It mirrors
    the `choice` precedent in both grammar and implementation, matches C++ and
    Rust muscle memory for exactly the audience migrating union-heavy code, and
    avoids implying that class features (inheritance, `adapt`) are available.
2.  **Reads are `unsafe` in Strict Carbon; writes are never marked.** Reading is
    the type-punning capability; marking it satisfies the
    semantically-narrow/syntactically-narrow principles of the
    [safety strategy](safety/README.md#safe-and-unsafe-code). Writes cannot
    violate any invariant under the 0.1 field rules — there is no live
    non-trivial value a write could clobber — so marking them would be noise.
    0.1 ships Permissive-mode behavior; the marker arrives with the safety-mode
    syntax.
3.  **Byte-reinterpretation read semantics**, not C++ active-member undefined
    behavior with a common-initial-sequence carve-out. It is the semantics
    migrated C and C++ code already assumes, it subsumes the
    common-initial-sequence rule instead of special-casing it, it is what Rust
    ships, and it costs nothing in this toolchain's lowering. Adopting C++'s
    undefined behavior would buy no optimization and import a class of
    time-travel bugs Carbon's safety strategy exists to eliminate. The user
    confirmed this choice under their lowest-friction rule, judged against
    the existing imported-union lowering behavior: imported C++ unions
    already lower to byte-offset accesses into an untyped byte array with no
    type-based aliasing claims, so defined reinterpretation is the semantics
    the implementation already exhibits, and ratifying it required no change
    to that behavior.
4.  **Initialization is designated single-field struct literal or
    unformed-then-assign.** Both fall out of existing language machinery
    (struct-literal conversion, unformed state); factory functions remain
    available as a style choice but are not required. No whole-union aggregate
    syntax exists, because fields overlap.
5.  **0.1 fields must be trivially copyable and destructible.** The C++-style
    deleted-special-members propagation model is more expressive but requires
    destructor/copy synthesis interaction that buys nothing for the 0.1 interop
    and migration goals; imported C++ unions with non-trivial members are
    already handled by preserving Clang's deletions. Relaxing the field rules is
    future work and is purely additive.
6.  **Carbon-authored anonymous unions are deferred**; anonymous-union _import_
    is in 0.1 (it already works). Authoring them requires a general
    unnamed-member and name-injection design that no other 0.1 feature needs,
    and the named-field rewrite is layout-identical.
7.  **Debug-build discriminator tracking is committed as future work** in this
    document rather than left unstated, so that programs are written against the
    rule "an invalid-representation read may terminate in checked builds" from
    day one and the check can be added without a semantics change. The tracked
    discriminator must be stored out of band, never in the union object, so
    adding it is also not a layout change — see
    [Strict Carbon and future safety hooks](#strict-carbon-and-future-safety-hooks).
8.  **`union` becomes a keyword**, accepting the `r#union` migration cost for
    identifiers, which is zero in this repository and near-zero elsewhere
    (`union` is also a C++ keyword, so interop never encounters it as an
    identifier).
9.  **A Carbon-authored union must have at least one field.** C++ permits empty
    unions; Carbon has no use for authoring a one-byte type with no readable or
    writable field, and excluding it keeps the unformed-state and initialization
    rules total. Imported empty C++ unions remain fully usable as values — they
    simply have no fields — per [Importing C++ unions](#importing-c-unions).

## Alternatives considered

Two alternatives were considered and rejected at the design fork; the full
analysis is in the [option paper](/fork/design-sprint/unions.md) and the
decision is recorded as
[F-007](/fork/decision-log.md#f-007-unions--native-union-declaration-2026-07-19):

-   **An untyped `Core.Storage(size, align)` primitive only** (the other
    primitive sanctioned by
    [proposal #157](/proposals/p000157-design-direction-for-sum-types.md)):
    rejected for 0.1 because it cannot export as, or be mechanically migrated
    from, a C++ union, leaving the interop bullet open. It remains compatible
    future work: union semantics here are specified as byte reinterpretation
    precisely so a later `Storage` primitive can underlie them.
-   **C++-import-only** (no Carbon union authoring): rejected because migration
    of a C++ file containing a union could then never produce a pure-Carbon
    file, contradicting the migration and expressivity goals.

## References

-   Proposal
    [#157: Design direction for sum types](https://github.com/carbon-language/carbon-lang/pull/157)
-   Upstream discussion
    [#1907: Checked unions in debug builds](https://github.com/carbon-language/carbon-lang/discussions/1907)
-   Fork decision
    [F-007: Unions — native `union` declaration](/fork/decision-log.md#f-007-unions--native-union-declaration-2026-07-19)
    and the [design-sprint option paper](/fork/design-sprint/unions.md)
-   [Sum types](sum_types.md) and [Safety](safety/README.md)
