# Design option paper: un-discriminated unions + C++ union mapping

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

Status: **OPEN design fork** (input to `fork/decision-log.md`). Part of
workstream W2 (design authorship) feeding W5 (sum types / unions /
variant interop) per `fork/gap-analysis.md`.

<!-- toc -->

## Table of contents

-   [Problem statement](#problem-statement)
-   [Constraints](#constraints)
    -   [What the milestone actually requires](#what-the-milestone-actually-requires)
    -   [Carbon design principles that bind this design](#carbon-design-principles-that-bind-this-design)
    -   [What upstream has already said](#what-upstream-has-already-said)
    -   [C++ union semantics we must map](#c-union-semantics-we-must-map)
    -   [Prior art](#prior-art)
    -   [Implementation realities in this toolchain](#implementation-realities-in-this-toolchain)
-   [Options](#options)
    -   [Option A: native `union` declaration](#option-a-native-union-declaration)
        -   [Design sketch](#design-sketch)
        -   [C++ interop story](#c-interop-story)
        -   [Implementation cost in this toolchain: **M**](#implementation-cost-in-this-toolchain-m)
        -   [Evolution risk vs upstream: **Medium-low**](#evolution-risk-vs-upstream-medium-low)
    -   [Option B: unsafe storage primitive only](#option-b-unsafe-storage-primitive-only)
        -   [Design sketch](#design-sketch-1)
        -   [C++ interop story](#c-interop-story-1)
        -   [Implementation cost in this toolchain: **M** (and it buys less)](#implementation-cost-in-this-toolchain-m-and-it-buys-less)
        -   [Evolution risk vs upstream: **Medium**](#evolution-risk-vs-upstream-medium)
    -   [Option C: C++-import-only](#option-c-c-import-only)
        -   [Design sketch](#design-sketch-2)
        -   [C++ interop story](#c-interop-story-2)
        -   [Implementation cost in this toolchain: **S**](#implementation-cost-in-this-toolchain-s)
        -   [Evolution risk vs upstream: **Low now, Medium later**](#evolution-risk-vs-upstream-low-now-medium-later)
-   [Recommendation](#recommendation)
-   [Dependencies on other workstreams](#dependencies-on-other-workstreams)
-   [Open questions for the user](#open-questions-for-the-user)

<!-- tocstop -->

## Problem statement

Carbon has **no union design at all**: no `union` token in
`toolchain/lex/token_kind.def` (the decl-introducer list at lines
152-171 goes from `Require` to `Var` with nothing union-shaped), no
parse states, no check support, and no page in `docs/design/`. The only
mention in the entire design tree is one sentence in
`docs/design/sum_types.md:94` admitting that the low-level storage
primitive underlying user-defined sum types "hasn't been designed yet".

The 0.1 milestone (`docs/project/milestones.md:134-135`) requires, under
Type system:

> -   Unions (un-discriminated)
>     -   C++ interop: mapping to and from C++ unions.

This paper closes exactly those two bullets, and materially advances
three others:

-   The 0.1 goal that language design components be "documented,
    cohesive, and understandable by evaluators without placeholders"
    (`milestones.md:55-56`) — a union design page replaces the
    `sum_types.md:94` placeholder sentence.
-   The 0.1 goal that features "be sufficient to translate existing C++
    code ... into obvious and unsurprising Carbon code"
    (`milestones.md:57-61`) — C++ codebases are full of unions
    (hand-rolled tagged unions, protocol/wire structs, `intptr` puns).
-   W5's choice-payload work: payload-carrying `choice` alternatives
    (`toolchain/check/handle_choice.cpp:159` TODO) need overlapping
    storage; whatever primitive we pick here is what `choice` lowers
    onto.

Important scoping note: `milestones.md:102-108` explicitly says a bullet
may be closed either by adding the named design **or** by "a clear
statement that Carbon will _not_ include this design but use some other
language features to address its use cases". Option C below takes that
escape hatch; A and B do not.

## Constraints

### What the milestone actually requires

-   "Mapping to and from C++ unions" — both directions. "From": Carbon
    code can use values of imported C++ union types (read/write members,
    pass/return them). "To": C++ code can use union-shaped types whose
    truth lives in Carbon, or at minimum Carbon can hand union values
    back to C++ unmodified. Interop tests must "build and run"
    (`milestones.md:76-78`), so the conformance harness (W1) needs
    execution tests, not just SemIR goldens.
-   Evaluation-quality gaps only: bit-field members, for example, are
    currently unimported (`toolchain/check/cpp/import.cpp:791-794`
    skips them; `fail_todo_use_bitfields.carbon`), and Carbon has no
    bit-field design. That is a gap we can document rather than close,
    per `milestones.md:79-80` ("gaps ... that don't undermine
    evaluation confidence") — but it must be a _documented_ limitation.

### Carbon design principles that bind this design

-   **Performance / zero hidden overhead** (`docs/project/goals.md:175`
    ff): a union must be exactly max-size/max-align overlapping storage;
    no hidden discriminator in production builds. (A debug-build
    tracking discriminator, as upstream discussion
    [#1907](https://github.com/carbon-language/carbon-lang/discussions/1907)
    proposes and Zig implements, is compatible with this because build
    modes may change unsafe-code behavior — `docs/design/safety/README.md:208-229`.)
-   **Expressivity comparable to C++** (`goals.md:488-490`): "If an
    algorithm or data structure ... can naturally be written in C++, it
    should also be possible to write it naturally in Carbon." Union-based
    data structures are idiomatic C++.
-   **Safety strategy** (p005914, `docs/design/safety/README.md:54-124`):
    unsafe capabilities must be _semantically narrow_ (reading an
    inactive union member is a type-punning capability and nothing
    more) and _syntactically narrow_ (identifiable `unsafe` marking in
    Strict Carbon; Permissive Carbon may omit it for C++-migration
    ergonomics). Type punning is precisely the kind of
    C++-compatibility unsafety Permissive mode exists for.
-   **Migration tooling** (`goals.md:492-501`): a C++ `union` must be
    mechanically translatable. This is the constraint Option C fails.

### What upstream has already said

-   Accepted proposal **p000157** ("Design direction for sum types")
    requires that Carbon have _at least one_ of: a typed `union`
    facility (referencing never-merged PR
    [#139](https://github.com/carbon-language/carbon-lang/pull/139)),
    or an untyped `Storage(size, align)` byte-buffer primitive
    (`proposals/p000157-design-direction-for-sum-types.md:234-241`,
    296-316). Which one (or both) is an explicitly recorded **open
    question**. So a native union is not a divergence from upstream —
    it is answering a question upstream left open.
-   `docs/design/sum_types.md:80-96`: user-defined sum types are meant
    to be buildable from classes plus "untagged unions or some other
    low-level storage primitive which hasn't been designed yet".
-   Upstream discussion #1907 explores debug-build discriminator
    tracking for untagged unions — evidence upstream expects untagged
    unions to exist eventually.
-   p000157's `choice` open question (`p000157:765-770`) about
    exposing/controlling the discriminator is adjacent but separable.

### C++ union semantics we must map

The interop feature must be faithful to what C++ actually guarantees:

-   **Layout**: size = max member size (padded), align = max member
    alignment; all members at offset 0. Clang computes this; the
    importer already consumes it by way of `ASTRecordLayout`
    (`toolchain/check/cpp/import.cpp:674-686`).
-   **Active member**: at most one member is active; writing a member
    starts its lifetime (implicit-lifetime rules); reading a non-active
    member is UB in C++ — _except_ the **common initial sequence**
    rule: if standard-layout struct members share a common initial
    sequence, inspecting that common part through any of them is
    defined while one of them is active (C++ [class.mem.general]).
    This is the rule that makes the classic hand-rolled tagged union
    (`union { struct { int kind; ... } a; struct { int kind; ... } b; }`)
    legal, so migrated code depends on it. C11 is laxer still: union
    type punning is unspecified-value reinterpretation, not UB, and
    real codebases assume the C semantics even in C++.
-   **Anonymous unions**: members are injected into the enclosing
    scope. The importer already flattens these by way of
    `IndirectFieldDecl` chains with accumulated offsets
    (`import.cpp:780-847`; test
    `toolchain/check/testdata/interop/cpp/class/import/field.carbon`
    `use_anon_struct_union.carbon` reads `a.f_4` through nested
    anonymous struct/union).
-   **Special members**: a C++ union member with a non-trivial
    ctor/dtor/copy deletes the union's corresponding special member
    unless user-provided. Any Carbon-side rule must not be _more_
    permissive than this for imported types.
-   **No inheritance**: unions cannot be base classes or derive. The
    importer already models this by treating unions as `final`
    (`import.cpp:611-617`).

### Prior art

-   **Rust** (`union`, RFC 1444/1897): declaration mirrors `struct`;
    fields must not require drop (Copy, `ManuallyDrop<T>`, references);
    writing a field is safe, **reading any field is `unsafe`**;
    semantics are "reinterpret the bytes" — defined whenever the bytes
    are valid at the read type, with no C++-style strict-aliasing UB;
    `#[repr(C)]` gives C-compatible layout; borrowing one field
    borrows the whole union. This is the minimal-safe-surface design
    and the closest fit to Carbon's safety strategy.
-   **Zig**: `extern union` (C ABI), `packed union`, and bare `union`
    which carries a _hidden safety tag in safe build modes only_ —
    exactly the #1907 idea; plus `union(enum)` as the tagged form.
    Validates the "raw union + debug checking" split across build
    modes.
-   **Swift**: no native unions; C unions import as structs with
    computed properties over raw storage. This is the Option C
    precedent — and Swift's experience (ergonomic but write-only-ish,
    no way to _author_ a union) is why Swift is not a systems-migration
    language for union-heavy C.
-   **C++ `std::variant` / Carbon `choice`**: the discriminated case is
    a separate 0.1 bullet (`milestones.md:133`) handled in W5; this
    paper deliberately does not conflate them.

### Implementation realities in this toolchain

The single most important finding of this audit: **the toolchain
already has an overlapping-layout type representation, end to end.**
The gap-analysis row ("C++ unions import only as opaque interop
types") is stale — imported unions are field-addressable today:

-   `SemIR::CustomLayoutType` (`toolchain/sem_ir/inst_kind.def`,
    `typed_insts.h`) carries a field list plus a `CustomLayoutId` of
    explicit sizes/offsets (size, align, then per-field offsets).
-   `toolchain/check/cpp/import.cpp:648-858`
    (`ImportClassObjectRepr`) builds one for every imported C++
    class/struct/union, copying Clang's `ASTRecordLayout`. For a
    union, every field lands at offset 0 — nothing in the
    representation assumes disjointness.
-   `toolchain/lower/type.cpp:633-640` lowers `CustomLayoutType` to
    `[size x i8]`; `toolchain/lower/aggregate.cpp:29-39` turns element
    access into byte-offset GEPs. Offset-0 accesses of distinct types
    therefore already work.
-   Proof in tests: `use_union_fields.carbon` (in
    `toolchain/check/testdata/interop/cpp/class/import/field.carbon`)
    reads `u.a`, `u.b`, `*u.p` from `union Union { int a; int b; int* p; }`;
    `toolchain/check/testdata/interop/cpp/class/import/union.carbon`
    and `.../function/import/union.carbon` cover declaration,
    nesting, namespacing, and pass/return by value and pointer.
-   `choice` is implemented as sugar over a `SemIR::Class`
    (`toolchain/check/handle_choice.cpp:53-56`), demonstrating the
    "new declaration kind reusing class machinery" pattern a native
    `union` would follow. Its parse side
    (`toolchain/parse/handle_choice.cpp`, `node_kind.def:412-415`, 12
    states in `state.def`) is the template for parser cost.
-   Gaps that any option inherits: struct-literal initialization of
    `CustomLayoutType` classes bails out of builtin conversion
    (`toolchain/check/convert.cpp:882-885` — "Builtin conversion does
    not apply"), so _constructing_ imported-union values in Carbon
    (rather than receiving them from C++) is not yet wired; bit-field
    members are skipped at import; `unsafe` exists as a keyword
    (`token_kind.def:230`) and `Core.UnsafeAs` pointer casts exist
    (`core/prelude/operators/as.carbon:63`), but there is no
    statement-level unsafe-marking machinery.
-   Export direction: `toolchain/check/cpp/export.cpp` (1202 lines)
    creates `clang::CXXRecordDecl`s for exported Carbon classes
    (lines 104, 161). Clang represents a union as the same AST node
    with `TagTypeKind::Union`, so union export rides the existing
    class-export machinery.

## Options

### Option A: native `union` declaration

A first-class, deliberately minimal, Rust-shaped union with
C++-compatible layout, designed so `Cpp.U` and a Carbon `union` are the
same kind of entity.

#### Design sketch

```carbon
// A union is a nominal type with overlapping fields.
// Layout: size = max(sizeof fields) padded to align = max(alignof fields).
// All fields at offset zero. Guaranteed C/C++-union-compatible.
union IntOrBytes {
  var word: u32;
  var bytes: array(u8, 4);
}

fn Pun() -> u8 {
  // Designated single-field initialization activates that field.
  var u: IntOrBytes = .{.word = 0x01020304};
  // Writing a field (re)activates it: always allowed.
  u.word = 0xAABBCCDD;
  // Reading a field reinterprets the bytes. In Permissive Carbon this
  // is allowed as written (C++-migration ergonomics); in Strict Carbon
  // it requires an `unsafe` marker (spelling TBD with W3):
  return u.bytes[0];
}

// Unions may have methods and impls, like any class-shaped entity;
// no base classes, no `virtual`, implicitly final (matches C++ and
// the importer's existing rule, import.cpp:611).
union TaggedPayload {
  var as_int: i64;
  var as_ptr: Node*;

  fn IsNullPtr[self: Self]() -> bool { return self.as_int == 0; }
}
```

Core semantic rules (one page in `docs/design/unions.md`):

1.  Fields overlap at offset 0; size/align as above; layout is
    guaranteed, unlike classes (`docs/design/classes.md:2185-2223`
    leaves class layout control as future work — unions are the one
    place we commit now, because interop demands it).
2.  Reads are **byte reinterpretation** (Rust semantics, not C++ UB):
    defined whenever the stored bytes are a valid value of the read
    type; erroneous otherwise, never time-traveling UB in Carbon
    semantics. This is stronger than C++, costs nothing at -O2 (LLVM
    has no union-based TBAA to lose — Clang already treats union
    accesses conservatively), and subsumes the common-initial-sequence
    guarantee migrated code relies on.
3.  0.1 field-type restriction: fields must be trivially destructible
    and trivially copyable (concretely: satisfy `Core.Copy` with the
    trivial impl and have no `Destroy` obligation). This sidesteps the
    entire active-member-destruction problem exactly the way Rust did
    pre-`ManuallyDrop`; C++ unions with non-trivial members import
    with the corresponding operations unavailable (Clang already marks
    them deleted).
4.  Default initialization: none. A `var u: U;` is unformed, matching
    Carbon's unformed-state model; the first field write or designated
    init forms it.
5.  No union inheritance, no `abstract`/`base` modifiers, no virtual
    functions. Generic unions (`union U(T:! type)`) allowed — they fall
    out of the class machinery — but conformance-tested only for
    concrete instantiations in 0.1.

#### C++ interop story

-   **Import ("from")**: `ImportTagDecl` marks the resulting class-like
    entity as a union (new `is_union` bit alongside
    `SemIR::ClassFields::inheritance_kind`) instead of merely `final`.
    Field read/write already works (tests above); the remaining wiring
    is designated-field initialization of `CustomLayoutType` values
    (the `convert.cpp:882` bailout) so Carbon can _construct_ C++
    union values. Anonymous-union flattening already works.
-   **Export ("to")**: exported Carbon unions produce a
    `TagTypeKind::Union` record by way of the existing `CXXRecordDecl`
    creation path in `check/cpp/export.cpp:104/161`; because the layout
    rule is C++'s union layout rule by construction, the Clang-computed
    layout and the Carbon `CustomLayoutType` layout agree, and C++ sees
    a genuine union.
-   Round-trip guarantee (conformance test): a union declared in either
    language, passed by value and by pointer across the boundary,
    observes the same bytes; anonymous-union member access agrees on
    offsets.

#### Implementation cost in this toolchain: **M**

-   Lex: one `CARBON_DECL_INTRODUCER_TOKEN(Union, "union")` in
    `token_kind.def` (+ keyword test churn; `r#union` raw-identifier
    syntax already exists for C++ code using `union` as an identifier —
    ironically impossible, since it's a C++ keyword too). **S**
-   Parse: mirror the `choice` pattern (`parse/handle_choice.cpp`,
    ~4 node kinds, ~12 states) but with a class-style body restricted
    to `var` fields, methods, impls; coverage test forces testdata.
    **S**
-   Check: `check/handle_union.cpp` following
    `check/handle_choice.cpp`'s build-a-`SemIR::Class` pattern; object
    representation is a `CustomLayoutType` with all field offsets 0.
    The one genuinely new piece: computing max-size/max-align at
    type-completion time. Two viable routes: (a) reuse the Clang
    `TargetInfo`/`ASTContext` already linked into check for interop, or
    (b) extend `CustomLayout`/`ObjectSize` with a symbolic
    "max-of-members" that `lower/type.cpp` resolves against LLVM
    `DataLayout`. Route (b) keeps check target-independent and is
    preferred. Plus: designated-init conversion for custom-layout
    types (shared with the import-construction fix), and the
    trivial-field-type enforcement. **M**
-   Lower: nothing new if `CustomLayoutType` is reused
    (`lower/type.cpp:633`, `lower/aggregate.cpp:29` already handle it);
    ~30 lines if route (b) symbolic sizes are added. **S**
-   Interop: `is_union` marking on import (**S**); union export through
    `export.cpp` (**S/M** — the record-creation path exists, field
    export for custom-layout types is the new part).
-   Tests: parse/check/lower goldens + W1 execution tests
    (pun round-trip, C++ round-trip). **S**

#### Evolution risk vs upstream: **Medium-low**

p000157 explicitly names a typed union facility as one of its two
sanctioned primitives, and #1907 assumes untagged unions will exist.
Rust/Zig convergence on this shape is strong evidence the eventual
upstream design lands nearby. Divergence risk concentrates in surface
syntax (introducer keyword vs modifier, init syntax, the strict-mode
`unsafe` spelling) — all mechanical to migrate later — not in the
layout/semantics core, which is forced by C++ compatibility for any
design.

### Option B: unsafe storage primitive only

Adopt p000157's _other_ primitive: no `union` type; instead a library
type `Core.Storage(size:! usize, align:! usize)` — an untyped,
max-aligned byte buffer with unsafe `Create(T, args)` / `Read(T)` /
`Destroy(T)` operations — and let users (and the `choice`
implementation) build overlapping storage manually.

#### Design sketch

```carbon
class IntOrBytes {
  private var storage: Core.Storage(4, 4);

  fn Word[addr self: Self*]() -> u32 { return self->storage.Read(u32); }
  fn SetWord[addr self: Self*](w: u32) { self->storage.Create(u32, w); }
  fn Byte[addr self: Self*](i: u32) -> u8 {
    return self->storage.ReadAt(array(u8, 4), i);
  }
}
```

#### C++ interop story

Weak. Imported C++ unions stay exactly what they are today (custom
layout classes with overlapping fields) — that part is fine — but there
is no Carbon entity that _exports as_ a C++ union, and no mechanical
translation for a migrated C++ `union` declaration: every one becomes a
hand-written class over `Storage` whose layout equivalence is by
convention, not by construction. The "mapping **to** ... C++ unions"
sub-bullet stays open, or gets closed by the Option C escape-hatch
statement anyway.

#### Implementation cost in this toolchain: **M** (and it buys less)

`Storage` needs: an alignment-control mechanism (Carbon classes have
none today — `classes.md:2185` lists layout control as future work), a
placement-construction builtin (Carbon's init model has no user-facing
in-place create; `Core.UnsafeAs` pointer casts exist but object
creation at an address does not), and typed-read builtins. That is new
check+lower surface comparable to Option A's, without closing the
interop bullet. Library work in `core/prelude/`.

#### Evolution risk vs upstream: **Medium**

Equally sanctioned by p000157 (its examples use `Storage`), and
genuinely needed eventually for `std::any`-style dynamic storage
(p000157:301-308). But upstream would _still_ need a union-shaped
answer for the interop bullet, so B alone likely under-shoots what
upstream ends up with.

### Option C: C++-import-only

Take the `milestones.md:102-108` escape hatch: publish a design page
stating Carbon will not have a native union declaration; C++ unions
remain fully usable through interop; new Carbon code uses `choice`;
union-heavy migrated code keeps its unions in C++ headers.

#### Design sketch

No new syntax. Work is (a) documentation — a `docs/design/unions.md`
"clear statement" page with the use-case mapping table (tagged union →
`choice`, type punning → `Core.UnsafeAs` / `bit_cast`, wire formats →
imported C++ union or `array(u8, N)`), and (b) finishing the import
path so evaluation isn't undermined: designated-init construction of
imported union values (the `convert.cpp:882` gap), plus documenting the
bit-field limitation.

#### C++ interop story

"From C++": already substantially working (reads, writes, anonymous
unions, pass/return — see tests cited above); construction fix makes it
complete. "To C++": only in the shallow sense that Carbon can traffic
in C++-declared unions; Carbon cannot author one. Migration of a C++
file containing a union cannot produce a pure-Carbon file — it must
leave a header stub behind, which contradicts `goals.md:492-501`
(high-fidelity source-to-source migration) and `goals.md:488-490`
(expressivity parity).

#### Implementation cost in this toolchain: **S**

The construction fix in `check/convert.cpp` + docs + conformance tests
over the existing import machinery.

#### Evolution risk vs upstream: **Low now, Medium later**

Zero code divergence today. But p000157 already commits upstream to at
least one shareable-storage primitive, so upstream will eventually ship
something native; this fork would then re-do the work with none of it
banked. It also quietly weakens the W5 choice-payload implementation,
which needs overlapping storage machinery regardless — under Option C
that machinery gets built ad hoc inside `choice` lowering with no
user-facing surface.

## Recommendation

**Option A: native `union` declaration** — Rust-shaped safety surface,
C++-union layout guarantee, implemented on the existing
`CustomLayoutType` machinery — with Option C's import-construction fix
absorbed into it (it is the same `convert.cpp` work), and Option B
explicitly deferred (recorded as non-0.1 future work in the design
page, kept compatible by specifying `union` semantics in terms of byte
reinterpretation so a later `Storage` primitive can underlie it).

Rationale:

1.  **It is the only option that closes both bullets as written.**
    A closes "Unions (un-discriminated)" with a real feature and both
    directions of "mapping to and from C++ unions". B and C each leave
    the export/authoring direction open or answered by fiat.
2.  **The expensive half already exists.** The overlapping-layout
    representation, its lowering, and field access are implemented and
    golden-tested for imported unions (`import.cpp:648-858`,
    `lower/type.cpp:633`, `lower/aggregate.cpp:29`,
    `field.carbon:use_union_fields`). Option A is mostly front-end
    surface (one keyword, ~12 parse states, one check handler modeled
    on `handle_choice.cpp`) plus a size-computation rule — a genuine
    **M**, not the XL a from-scratch union would be.
3.  **It is aligned with, not divergent from, upstream.** p000157
    requires at least one of typed-union/`Storage` and left the choice
    open; A answers the open question with the alternative that C++
    interop forces anyway, and matches where Rust and Zig both landed.
    The fork's process (this paper → user decision → decision-log
    entry) is precisely the committee-replacement mechanism for such
    open questions.
4.  **It unblocks W5.** Choice payloads need overlapping storage;
    with A, `choice` alternatives lower onto the same
    all-offsets-zero `CustomLayoutType` shape (discriminant field +
    payload union), so the design decision here is made once, not
    twice.
5.  **Safety story is coherent under p005914.** Writes safe, reads
    byte-reinterpretation (defined-if-valid), Strict-mode marking on
    reads, Permissive-mode ergonomics for migrated code, optional
    debug-build discriminator tracking later (#1907/Zig) under the
    build-modes umbrella — each maps onto an existing accepted
    strategy element.

Suggested 0.1 cut-line within Option A: concrete (non-generic) unions,
trivially-copyable/destructible fields, designated single-field init,
field read/write, methods/impls, import mapping, export mapping,
anonymous-union _import_ (already works). Deferred and documented:
Carbon-authored anonymous unions inside classes, bit-fields, non-trivial
field types, generic-union conformance, debug-mode tracking.

## Dependencies on other workstreams

-   **W1 (conformance harness)** — required first: the round-trip and
    punning tests must _execute_, per `fork/process.md` step 1.
-   **W5 (sum types / choice payloads / variant interop)** — consumer:
    choice payload storage should reuse the union object-representation
    machinery; sequencing is unions-design → choice-payload
    implementation. `std::variant` mapping is W5's, not this paper's.
-   **W2 sibling: safe-Carbon / safety-mode syntax (W3, p005914
    follow-ups)** — the Strict-mode spelling for unsafe union reads
    must come from the safety-mode syntax design; until it lands, 0.1
    ships Permissive-mode behavior with the design page noting the
    Strict-mode hook. No hard block.
-   **W8 (interop frontier)** — union export lands in the same
    `check/cpp/export.cpp` machinery W8 extends for operators/concepts;
    coordinate to avoid conflicting refactors.
-   **Pattern matching (W4)** — explicitly _not_ a dependency: unions do
    not participate in `match` (they have no discriminator). Any
    perceived coupling is by way of `choice`, which is W5.
-   **Upstream merge risk (standing rule 5)** — before implementation
    starts, re-check upstream for movement on p000157's open question
    or a `union` proposal; as of trunk `99cda60` (2026-07) there is
    none (highest proposal ~p007493 is interop/syntax work, per
    `fork/gap-analysis.md`).

## Open questions for the user

Beyond choosing A/B/C, these need decisions (defaults proposed):

1.  **Introducer syntax**: standalone `union U { ... }` introducer
    (proposed, mirrors `choice`) vs a class modifier
    (`union class U`). Standalone matches C++ muscle memory and the
    Rust/Zig precedent; modifier avoids a new introducer token class.
2.  **Strict-mode read marking**: is reading a union field `unsafe` in
    Strict Carbon (Rust rule, proposed) or unmarked-but-erroneous?
    And is the _write_ of a field over a live non-trivial member ever
    reachable given the 0.1 field restriction (proposed: no)?
3.  **Read semantics text**: adopt byte-reinterpretation
    (defined-if-valid, proposed) vs C++ active-member UB with a
    common-initial-sequence carve-out. This is the deepest semantic
    commitment; byte-reinterpretation is simpler, safer, and what
    migrated C code silently assumes, but is a (deliberate)
    strengthening over C++.
4.  **Initialization**: designated single-field init
    `.{.word = 1}` (proposed) vs mandatory factory functions vs
    permitting unformed-then-assign only.
5.  **Field-type restriction for 0.1**: trivially
    copyable+destructible only (proposed), or C++-style
    "deleted special members" propagation from day one?
6.  **Anonymous unions authored in Carbon classes**: 0.1 (adds parse
    and name-injection work) or defer to 0.2 (proposed: defer; import
    side already works).
7.  **Debug-build discriminator tracking** (#1907/Zig-style): commit to
    it in the design page as future work (proposed) or leave unstated?
8.  **Keyword fallout**: `union` becomes a keyword; any Carbon
    identifier named `union` in existing fork code/tests must migrate
    to `r#union` — accept this (proposed; grep shows no conflicts in
    `core/` or `examples/`)?
