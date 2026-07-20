# Design option paper: Error handling + C++ exception interop

<!--
Part of the Carbon Language project, under the Apache License v2.0 with LLVM
Exceptions. See /LICENSE for license information.
SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
-->

<!-- toc -->

## Table of contents

-   [Problem statement](#problem-statement)
    -   [0.1 milestone bullets this area closes](#01-milestone-bullets-this-area-closes)
    -   [A note on "issue #686"](#a-note-on-issue-686)
-   [Constraints](#constraints)
    -   [Design-principle constraints](#design-principle-constraints)
    -   [Interop constraints from the milestone](#interop-constraints-from-the-milestone)
    -   [Implementation realities in this toolchain](#implementation-realities-in-this-toolchain)
    -   [Syntax space already consumed](#syntax-space-already-consumed)
-   [Shared interop machinery (used by every option)](#shared-interop-machinery-used-by-every-option)
-   [Options](#options)
    -   [Option A: Library-only - `Core.Result` + `match`, no new syntax](#option-a-library-only---coreresult--match-no-new-syntax)
    -   [Option B: `Core.Result` + postfix `?` propagation by way of a `Core.Try` interface](#option-b-coreresult--postfix--propagation-by-way-of-a-coretry-interface)
    -   [Option C: Declared-fallibility signatures with `try`/`catch` sugar over values](#option-c-declared-fallibility-signatures-with-trycatch-sugar-over-values)
    -   [Option D: Native exceptions - Carbon `throw`/`catch` on Itanium unwinding](#option-d-native-exceptions---carbon-throwcatch-on-itanium-unwinding)
-   [Recommendation](#recommendation)
-   [Dependencies on other workstreams](#dependencies-on-other-workstreams)
-   [Open questions for the user (beyond option choice)](#open-questions-for-the-user-beyond-option-choice)
-   [References](#references)

<!-- tocstop -->

## Problem statement

Carbon 0.1 requires dedicated error-handling control flow and a complete C++
exception interop story. Today, upstream (and therefore this fork at trunk
`99cda60`) has **neither a design nor an implementation**:

-   `docs/design/README.md:3831`: "For now, Carbon does not have language
    features dedicated to error handling ... errors are represented using
    choice types like `Result` and `Optional`."
-   No error-handling proposal exists in `proposals/` (verified by grep; the
    only governing artifact is the principle in
    `docs/project/principles/error_handling.md`, accepted as
    [p000301](/proposals/p000301-principle-errors-are-values.md)).
-   The prelude has no `Result` type (`core/prelude/` — verified), and
    `Optional` is a self-described placeholder
    (`core/prelude/types/optional.carbon:27-28`).
-   The toolchain has zero exception-handling configuration: the embedded
    Clang invocation (`toolchain/base/clang_invocation.cpp`) sets no
    `-f[no-]exceptions` state, Carbon lowering emits only `CreateCall` — never
    `invoke`/landingpads (`toolchain/lower/handle_call.cpp`, verified by
    grep for `invoke|landingpad|personality` across `toolchain/lower/*.cpp`),
    and the interop philosophy doc explicitly disclaims seamless exception
    interop
    (`docs/design/interoperability/philosophy_and_goals.md#support-for-c-exceptions-without-bridge-code`).

Practical consequence today: inline/imported C++ is compiled by the embedded
Clang with the platform default (exceptions **on** for C++ on Linux), while
Carbon-generated frames carry no unwind support. A C++ exception escaping into
a Carbon frame is at best `std::terminate`, at worst UB, and Carbon `Destroy`
impls are silently skipped on any unwind path. The language boundary has no
defined behavior at all. This paper is the error-handling slice of workstream
**W2 (design authorship)** feeding **W8 (C++ interop frontier)** in
`fork/gap-analysis.md`; per `fork/process.md`, the user decides.

### 0.1 milestone bullets this area closes

From `docs/project/milestones.md#milestone-01` (lines 178-188):

1.  "Error handling: Any dedicated error handling control flow constructs"
2.  "C++ interop: Mechanisms to configure how exception handling should or
    shouldn't be integrated into C++ interop sufficient to address both
    `-fno-except` C++ dialects and standard C++ dialects"
3.  "Calling C++ functions which throw exceptions from Carbon and
    automatically using Carbon's error handling"
4.  "Export Carbon error handling using some reasonably ergonomic mapping into
    C++ -- `std::expected`, something roughly compatible with `std::expected`,
    C++ exceptions, etc."

It also materially contributes to "Control flow: matching ... Working with
sum-types" (a prelude `Result` is the flagship consumer of W4/W5 pattern
matching) and to the 0.1 goal that design docs be "understandable without
placeholders" (replaces `docs/design/README.md` §Error handling).

### A note on "issue #686"

The task brief referenced "issue #686 leads' direction". In-repository evidence
shows upstream carbon-lang #686 is "Operation order in struct/class
assignment/initialization" (cited in `docs/design/assignment.md:164`) —
unrelated. Web-searchable upstream error-handling discussion consists of
community threads (#1931, #2049 proposing try/catch, not adopted) and
p000301. There is **no** upstream leads decision on error-handling syntax;
the principle doc and design README are the only authoritative direction, and
both point the same way: errors as returned values, plus a future "explicit
but syntactically lightweight means of propagating errors, such as Rust's `?`
operator" (`docs/project/principles/error_handling.md:44-47`).

## Constraints

### Design-principle constraints

From `docs/project/goals.md` and accepted principles:

-   **Errors are values** (p000301): recoverable failure is reported by way of a sum
    type in the return position; no implicit propagation; no
    `noexcept`/`throws`-style effect annotations — fallibility lives in the
    return type. Any option violating this needs the user to knowingly
    overturn an accepted upstream principle.
-   **Performance-critical software** (`goals.md#performance-critical-software`):
    no hidden allocations, no mandatory unwinder machinery on the happy path,
    zero-overhead interop where possible.
-   **Code that is easy to read** + the progressive-disclosure principle
    (p005661): the success path must stay legible; propagation boilerplate is
    explicitly called out as a readability hazard by p000301.
-   **Interop targets C++17**
    (`docs/design/interoperability/philosophy_and_goals.md:177`):
    `std::expected` is C++23, so the export mapping must be "roughly
    compatible with `std::expected`" (the milestone anticipates exactly
    this) rather than depend on it.
-   **Bridge code is acceptable for exceptions**
    (`philosophy_and_goals.md#support-for-c-exceptions-without-bridge-code`):
    upstream reserves the right to require annotations/bridging and to accept
    overhead or information loss at the exception boundary. We may beat that
    floor; we are not required to.

### Interop constraints from the milestone

The three interop bullets impose an asymmetric shape:

-   **Both dialects**: the design must be coherent when the C++ side is built
    `-fno-exceptions` (throwing is impossible; error channels are
    `std::expected`-shaped types, error codes, or abort) _and_ when it is
    standard C++ (any non-`noexcept` function may throw).
-   **Import direction is "automatic"**: calling throwing C++ must land in
    Carbon's error handling without hand-written bridge per call.
-   **Export direction is "reasonably ergonomic"**: C++ callers of fallible
    Carbon functions get an expected-shaped value or exceptions; we choose.

### Implementation realities in this toolchain

Verified against the tree; these drive the cost estimates below:

-   **Choice payloads do not exist (W5 dependency).** `choice` alternatives
    with parameters are rejected with `context.TODO(...)` at
    `toolchain/check/handle_choice.cpp:159-161`; choices lower only as
    discriminant-only structs. **Every option below that stores an error
    payload depends on W5** (which itself depends on W4 match semantics — all
    15 check handlers in `toolchain/check/handle_match.cpp` are
    `context.TODO` stubs).
-   **The lexer already reserves `?` tokens — for a different feature.**
    `toolchain/lex/token_kind.def:62,67,103` defines `->?`
    (`MinusGreaterQuestion`), `:?` (`ColonQuestion`), and bare `?`
    (`Question`). `->?` and `:?` are consumed by the _expression forms_
    feature (p005545, p005434): `fn F() ->? form(...)` return forms
    (`toolchain/parse/handle_function.cpp:28-31`,
    `toolchain/parse/typed_nodes.h:546-553`) and `name:? Form` bindings
    (`toolchain/parse/handle_binding_pattern.cpp:176`). Bare `?` is lexed but
    used by **no** parser state (only a lexer unit test) — postfix `?` is
    available syntax space.
-   **Check can already build control flow from expressions.** Short-circuit
    `and`/`or` create branch/converge SemIR in check
    (`toolchain/check/handle_operator.cpp:407-497`,
    `toolchain/check/control_flow.h`), so a propagation operator can desugar
    entirely in check with **no new SemIR inst kinds and no lowering work**.
-   **Interop calls already route through generated C++-side thunks.**
    `toolchain/check/cpp/thunk.cpp` + `toolchain/docs/check/cpp/thunks.md`:
    cross-language calls use `__carbon_thunk__` wrappers with a simplified
    ABI (pointers, i32/i64, void). A thunk body is the natural single point to
    insert `try { ... } catch` and convert an in-flight exception into a
    returned value — the exception never crosses into a Carbon frame.
    `noexcept`-ness is queryable from the imported
    `clang::FunctionDecl` in `toolchain/check/cpp/import.cpp` (~line 1834,
    `ImportFunction`).
-   **Clang configuration is centralized.** Exception mode is a handful of
    driver args in `toolchain/base/clang_invocation.cpp`
    (`AppendDefaultClangArgs`) plus a user passthrough that already exists:
    `carbon compile --clang-arg=...`
    (`toolchain/driver/compile_options.cpp:33-53`). A first-class
    `--cpp-exceptions=` flag is small.
-   **Export machinery exists.** `toolchain/check/cpp/export.cpp` (1202
    lines) already synthesizes Clang decls + weak_odr thunks so C++ can call
    Carbon functions; mapping a fallible Carbon return type onto an
    expected-shaped C++ type extends this file plus a shipped support header
    (`toolchain/install/`).
-   **Nothing in lowering understands unwinding.** Adding real EH (Option D)
    means `invoke`/landingpad/personality emission in
    `toolchain/lower/function_context.*` and `handle_call.cpp`, _plus_
    modeling destructor cleanups on unwind paths — a concept SemIR does not
    have at all today.

### Syntax space already consumed

Max-munch hazard worth recording: `->?` lexes as one token, so syntax like
`fn F() -> ?i32` is a trap; the options below deliberately never put `?` in
type position. `try`, `throw`, `catch` are not keywords today
(`toolchain/lex/token_kind.def`, verified); adding keywords risks colliding
with identifiers, including imported C++ names.

## Shared interop machinery (used by every option)

All four options share the same three interop deliverables; they differ only
in what the Carbon-side surface looks like. Describing it once:

1.  **Exception-mode configuration (milestone bullet 2).** A first-class
    compile option `--cpp-exceptions={auto,none,catch}` in
    `toolchain/driver/compile_options.cpp`, plumbed to
    `BuildClangInvocation` in `toolchain/base/clang_invocation.cpp`:
    -   `none`: adds `-fno-exceptions -fno-cxx-exceptions`, modeling
        `-fno-except` codebases; imported headers diagnose as Clang would;
        catch-wrapping is disabled and fallible imports are compile errors.
    -   `catch` (default for standard dialects): C++ TUs compile with
        exceptions on; every escape point into Carbon is fenced (next item).
    -   `auto`: infer from other `--clang-arg`s. Size: **S**, independent of
        everything else — can land first.
2.  **Boundary fencing + catch-thunks (milestone bullet 3).** In
    `toolchain/check/cpp/thunk.cpp`, when the callee is potentially-throwing
    (non-`noexcept` per the Clang `FunctionProtoType`) and the mode is
    `catch`, generate the C++-side thunk as either:
    -   _fenced_ (default): thunk body wrapped in
        `try { ... } catch (...) { __carbon_boundary_terminate(); }` — a
        defined, documented terminate at the boundary (this is also what
        upstream's philosophy doc floor permits), or
    -   _catching_ (when the Carbon call-site requests the error): thunk gets
        an extra out-param slot; `catch (...)` captures
        `std::current_exception()` into a `Cpp.Exception` payload and returns
        a discriminant. The Carbon side sees `Result(T, Cpp.Exception)` (or
        the option's equivalent). `Cpp.Exception` owns an `exception_ptr` so
        re-export can rethrow with full fidelity.
3.  **Export mapping (milestone bullet 4).** `toolchain/check/cpp/export.cpp`
    maps an exported fallible Carbon function to C++ as returning
    `Carbon::expected<T, E>` — a C++17-compatible, `std::expected`-shaped
    class template shipped as a support header in the install tree
    (convertible to/from `std::expected` under C++23). Optionally (open
    question) also generate a throwing wrapper per exported function for
    exception-idiom C++ callers.

## Options

### Option A: Library-only - `Core.Result` + `match`, no new syntax

Ship the vocabulary type and pattern matching; add **no** dedicated control
flow. This is upstream's literal status quo direction ("errors are
represented using choice types like `Result`").

Design sketch:

```carbon
// core/prelude/result.carbon (new)
choice Result(T: type, E: type) {
  Success(value: T),
  Failure(error: E)
}

fn ReadConfig(name: str) -> Result(Config, IoError) {
  match (Open(name)) {
    case .Success(f: File) => {
      match (Parse(f)) {
        case .Success(c: Config) => { return .Success(c); }
        case .Failure(e: ParseError) => { return .Failure(e as IoError); }
      }
    }
    case .Failure(e: IoError) => { return .Failure(e); }
  }
}
```

C++ interop story: the shared machinery above, with _catching_ imports
surfaced as an explicit wrapper the user must name (for example
`Cpp.catching(Cpp.f)(args)` yielding `Result(T, Cpp.Exception)`); exports map
`Result` to `Carbon::expected`. Nothing at the call-site is lighter than a
full `match`.

Implementation cost in this toolchain: **S** on top of W4+W5 (one prelude
file; the interop machinery is the same M-sized work every option needs).

Evolution risk vs upstream: **none** — it is upstream's current text. But it
arguably does **not close milestone bullet 1**: nested-match pyramids are
exactly the readability failure p000301 warns about, and an evaluator
comparing against Rust/Swift will notice immediately. The floor, not a
destination.

### Option B: `Core.Result` + postfix `?` propagation by way of a `Core.Try` interface

Option A plus the single control-flow construct upstream's own principle doc
names: a postfix `?` operator that unwraps success or early-returns the
failure, made open by way of an interface so `Optional` and user types participate
(Rust's `Try` trait, adapted to Carbon's interface style).

Design sketch:

```carbon
// Prelude additions (sketch; exact associated-entity shapes are a design
// detail for the proposal itself).
choice Result(T: type, E: type) {
  Success(value: T),
  Failure(error: E)
}

interface Try {
  let ContinueType: type;
  let BreakType: type;
  // Splits `self` into continue-or-break.
  fn Branch(self) -> Result(ContinueType, BreakType);
  // Rebuilds "this function's" failure value from a propagated break value,
  // giving `?` its error-conversion hook.
  fn FromBreak(b: BreakType) -> Self;
}

impl forall [T: type, E: type] Result(T, E) as Try
    where .ContinueType = T and .BreakType = E { ... }
impl forall [T: type] Optional(T) as Try
    where .ContinueType = T and .BreakType = () { ... }
```

Use:

```carbon
fn ReadConfig(name: str) -> Result(Config, IoError) {
  // `Open(name)?` is `Open(name)` unwrapped, or an early
  // `return .Failure(e')` where `e'` converts by way of `FromBreak`/`ImplicitAs`.
  var f: File = Open(name)?;
  var c: Config = Parse(f)?;
  return .Success(c);
}

fn Show(opt: Optional(i32)) -> Optional(str) {
  return .Some(ToString(opt?));
}
```

Desugaring (all in check, no new SemIR inst kinds):

```carbon
// `expr?` ==>
match (expr.(Try.Branch)()) {
  case .Success(v: _) => v,               // value of the `?` expression
  case .Failure(b: _) =>
    return ReturnType.(Try.FromBreak)(b); // early return, converting error
}
```

C++ interop story: the strongest of the four, because `?` gives the
"automatic" call-site the milestone asks for:

-   **Calling throwing C++**: in `catch` mode, applying `?` (or binding into a
    `Result`) at a call to a potentially-throwing C++ function makes check
    request the _catching_ thunk; the call becomes
    `Result(T, Cpp.Exception)` and `?` propagates it like any Carbon error.
    Without `?`/`Result` consumption, the _fenced_ thunk applies —
    exceptions never unwind Carbon frames, so Carbon `Destroy` cleanups are
    never skipped. In `none` mode, `?` on a C++ call is a compile error
    ("callee cannot fail under -fno-exceptions").
-   **Exporting Carbon errors**: `fn F() -> Result(T, E)` exports as
    `Carbon::expected<T, E> F(...)`; `Cpp.Exception` failures rethrow the
    original `exception_ptr` in an optional throwing wrapper.

Implementation cost in this toolchain: **M** overall, layered:

-   lex: none (`Question` token exists, unused —
    `toolchain/lex/token_kind.def:103`).
-   parse: postfix-operator state + node (`toolchain/parse/state.def`,
    `node_kind.def`, `typed_nodes.h`, precedence entry alongside
    `TypePostfix` in `toolchain/parse/precedence.cpp`). **S**.
-   check: one new handler (pattern: `handle_operator.cpp`'s short-circuit
    branching, `control_flow.h` helpers), interface plumbing like existing
    operator interfaces (`toolchain/check/operator.h` +
    `core/prelude/operators/`), error-conversion by way of existing `ImplicitAs`
    machinery in `convert.cpp`. **M**.
-   sem_ir/lower: nothing new — desugars to existing branch/return insts that
    already lower and execute.
-   interop: shared machinery §above — thunk.cpp + import.cpp `noexcept`
    detection + export.cpp mapping + support header. **M**.
-   Hard dependency: W4 match + W5 choice payloads before any of the
    `Result`-shaped parts are real.

Evolution risk vs upstream: **low**. p000301 and `docs/design/README.md:3835`
both explicitly name Rust's `?` as the anticipated shape; a returned-choice
`Result` + `?` is the most probable upstream landing zone. Divergence risks
are spelling-level (upstream might pick `try expr` prefix instead of postfix
`?`; might name the interface differently) — mechanical renames, not
architectural rework. The forms feature already owns `->?`/`:?`, and this
option deliberately leaves type-position `?` alone, so no token conflict.

### Option C: Declared-fallibility signatures with `try`/`catch` sugar over values

A Swift/Zig/Herbceptions-flavored surface: fallibility is declared in the
signature, call sites mark propagation, and the compiler owns the layout —
but the ABI stays "returned value with discriminant" (no unwinding), as in
Herb Sutter's P0709 "static exceptions" and Zig error unions.

Design sketch:

```carbon
// `-> T or E` declares a fallible function. Still a return type — the
// fallibility is in the type, honoring p000301's "no effect annotations".
fn Open(name: str) -> File or IoError;

fn ReadConfig(name: str) -> Config or IoError {
  var f: File = try Open(name);      // propagate: like `?`, prefix spelling
  var c: Config = try Parse(f);
  return c;                          // success needs no wrapper
}

fn Main() -> i32 {
  // Consuming without propagating:
  ReadConfig("app.cfg") catch (e: IoError) => {
    PrintError(e);
    return 1;
  };
  return 0;
}
```

Semantics: `T or E` is compiler-known sugar for (and interconvertible with) a
`choice`-shaped value; `try` desugars as Option B's `?`; `catch` is an
expression-level unwrap-or-handle (subsuming part of the if-let/let-else
area). `return c` auto-wraps success — the main ergonomic delta over B.

C++ interop story: identical machinery to B; arguably a _cleaner_ import
mapping — a potentially-throwing C++ `T f()` imports directly as
`fn f() -> T or Cpp.Exception` in `catch` mode. Export of `-> T or E`
produces the same `Carbon::expected<T, E>`.

Implementation cost in this toolchain: **L**. Everything in B, plus new
keywords (`try`, `catch`; reusing keyword `or` in type position needs parser
disambiguation) across `token_kind.def` and parse states, and — the
expensive part — **function signature plumbing**: `SemIR::Function`
return-info, redeclaration matching (`toolchain/check/function.cpp`),
function types for generics/deduction, `export.cpp`, and the deferred thunk
machinery all learn a second return channel. The forms feature (`->?`
ReturnForm nodes) just paid this exact class of cost across many files.
`catch`-expression checking overlaps the if-let/let-else design area (W2
sibling paper) and must be co-designed.

Evolution risk vs upstream: **medium-high**. Upstream has zero signal toward
signature-level sugar; its written direction is B. `-> T or E` is arguably
still "in the return type" per p000301, but `try`-at-call-site as _required_
syntax is a bigger commitment upstream never discussed. If upstream later
lands `Result`+`?`, migrating C-fork code back is a mechanical but pervasive
rewrite of signatures and call sites.

### Option D: Native exceptions - Carbon `throw`/`catch` on Itanium unwinding

For completeness (the interop-maximalist position): give Carbon real
exceptions sharing the C++ ABI's unwinder, so C++ exceptions propagate
through Carbon frames and Carbon errors are C++ exceptions.

Design sketch:

```carbon
fn Open(name: str) -> File throws { ... throw IoError.NotFound; ... }
fn Use() {
  try {
    var f: File = Open("x");
  } catch (e: IoError) { ... }
}
```

C++ interop story: trivially maximal — both directions are the same runtime
mechanism; `-fno-except` mode simply forbids `throw` and gives every option
the same story.

Implementation cost in this toolchain: **XL** — the only option requiring
new lowering architecture: `invoke`/landingpad/personality emission and
EH-aware block structure in `toolchain/lower/function_context.*` and
`handle_call.cpp`; an unwind-edge concept SemIR has never had; synthesized
cleanup landing pads for every scope with a `Destroy` impl (destructors
currently run only on normal exits); churn across all 236 lowering golden
tests and loss of `nounwind`-based optimization.

Evolution risk vs upstream: **severe — permanent fork divergence**. It
directly contradicts accepted principle p000301 ("Carbon errors ... will not
be propagated implicitly"; no `noexcept`-style annotations) and the
performance goal's zero-overhead-on-happy-path stance is contested at best.
Upstream would not converge; every future upstream merge would collide in
lower/. Recorded here so the decision log shows it was considered, not
because it is viable for this fork's F-002 merge-gating model.

## Recommendation

**Option B, staged, with Option A's artifacts as the first stage.** Rationale:

1.  **It is the only option that closes all four milestone bullets while
    staying inside upstream's written direction.** p000301 and the design
    README literally name this shape (`Result`-style choice, then a
    lightweight `?`-like propagation operator). If upstream later lands its
    own design, the delta is spelling, not architecture — minimal risk under
    F-002's merge discipline.
2.  **It is cheap where this toolchain is strong.** The language surface
    desugars in check onto branch/return SemIR that already lowers and
    executes; the interop surface lands in two focused files
    (`check/cpp/thunk.cpp`, `check/cpp/export.cpp`) plus a driver flag —
    subsystems the audit rates as the most mature and best tested.
3.  **It degrades gracefully around the W4/W5 bottleneck.** Stage order:
    -   **B0 (now, size S, no dependencies):** `--cpp-exceptions` mode flag +
        _fenced_ thunks — defined terminate-at-boundary behavior in both
        dialects. This alone closes milestone bullet 2 and turns today's UB
        into a documented contract; it is also a prerequisite for honest
        conformance tests of everything else.
    -   **B1 (after W4+W5):** `Core.Result` in the prelude + match-based
        consumption + conformance programs (Option A's content).
    -   **B2 (size M):** postfix `?` + `Core.Try` + `ImplicitAs`-based error
        conversion.
    -   **B3 (size M):** catching thunks (`Result(T, Cpp.Exception)` imports)
        and `Carbon::expected<T, E>` export + support header — closes
        bullets 3 and 4.
4.  **Option C's ergonomic wins (auto-wrap on `return`, `catch` expression)
    remain reachable later** as sugar over B's semantics; B is
    forward-compatible with C but not the other way around.

Reject A alone (fails bullet 1 in spirit). Reject C as the _initial_
commitment (2-3x B's cost through signature plumbing, medium-high upstream
divergence, couples to the unfinished if-let/let-else design). Reject D
outright (contradicts an accepted principle, XL lowering cost, permanent
merge-conflict surface).

## Dependencies on other workstreams

-   **W4 (match semantics) — hard prerequisite for B1+.** All 15 check
    handlers in `toolchain/check/handle_match.cpp` are stubs; `Result`
    consumption and the `?` desugar's own match both need it.
-   **W5 (choice payloads) — hard prerequisite for B1+.**
    `toolchain/check/handle_choice.cpp:159` TODO; the storage design in
    `docs/design/sum_types.md:94` ("hasn't been designed yet") gets settled
    by W5, not here. (Stage B0 has no W-dependencies and should not wait.)
-   **W2 sibling: if-let/let-else design.** `Open(x)?` and
    `if let Some(v) = opt` overlap; the papers must agree on pattern syntax
    and where `catch`-style unwrap-or-handle lives.
-   **W1 (execution harness).** Error propagation is behavioral, not
    dump-shaped; exit-code, terminate-at-boundary, and
    `Carbon::expected` round-trip tests need compile-and-run arbitration.
-   **W9 (String / stdlib).** `Cpp.Exception.Message()` (from `what()`) and
    useful prelude error types want a real `String`; until then
    `Cpp.Exception` exposes only the `exception_ptr` and a type-name `str`.
-   **W8 (interop frontier).** B3's catching thunks and export mapping are
    line items inside W8's arbiter (throwing C++ under both `-fexceptions`
    and `-fno-except` "with defined behavior").
-   **Windows (W10).** The boundary machinery assumes Itanium-ABI
    `exception_ptr` semantics; MSVC EH (funclets) changes the thunk
    implementation, not the design — W10 must budget for it.

## Open questions for the user (beyond option choice)

1.  **Naming/shape of the vocabulary type.** `Result(T, E)` with
    `Success`/`Failure` (design README's spelling) vs `Ok`/`Err` (Rust
    familiarity); whether `Optional(T)` stays independent with a `Try` impl.
2.  **Error-conversion policy in `?`.** Apply `ImplicitAs` on the error
    alternative (Rust `From`-style, ergonomic) or require exact type match
    (explicit)? p000301 is silent; performance goals mildly favor explicit.
3.  **Default `--cpp-exceptions` mode.** `catch` (standard-dialect friendly,
    thunk try/catch cost on potentially-throwing imports) vs `none`
    (hermetic, zero cost, standard-dialect users must opt in).
4.  **Boundary behavior without opt-in.** Fenced-terminate (recommended,
    documented) vs compile-error on calling potentially-throwing C++ outside
    a `?`/`Result` context (safer, but `noexcept` is rare enough in real C++
    that it may be unusable) vs silent UB (status quo; rejected).
5.  **`Cpp.Exception` fidelity.** Hold `exception_ptr` only, or eagerly
    unpack `std::exception::what()`/type info? Rethrow-on-reexport
    guarantees?
6.  **Export shape.** `Carbon::expected<T, E>` support header only, or also
    generated throwing wrappers (`T FOrThrow(...)`) per exported function?
    Alias to real `std::expected` under C++23?
7.  **Where may `?` appear?** Only in functions whose return type implements
    `Try` (Rust rule); what that means for `Main` and terse `=>` bodies.
8.  **Deferred sugar.** Take `try { }` blocks / `catch`-expressions now, or
    explicitly defer post-0.1 (recommended: defer; record in decision log).
9.  **Panic vs error split.** Unrecoverable failures are out of scope here,
    but the boundary doc must define what a Carbon abort does with C++
    frames on the stack (and the other way around) — here or in the safety workstream.

## References

-   `docs/project/milestones.md:178-188` — the four 0.1 bullets.
-   `docs/project/principles/error_handling.md` /
    [p000301](/proposals/p000301-principle-errors-are-values.md).
-   `docs/design/README.md:3829-3839` — placeholder error-handling section.
-   `docs/design/sum_types.md` /
    [p000157](/proposals/p000157-design-direction-for-sum-types.md),
    [p002187](/proposals/p002187-update-sum-types-design.md) — choice types;
    storage primitive explicitly undesigned.
-   `docs/design/interoperability/philosophy_and_goals.md` /
    [p000175](/proposals/p000175-c-interoperability-goals.md) — C++17 target;
    exceptions-need-bridge-code non-goal.
-   [p005545](/proposals/p005545-expression-form-basics.md),
    [p005434](/proposals/p005434-ref-parameters-arguments-returns-and-val-returns.md)
    — the forms feature that owns `->?`/`:?` tokens.
-   Toolchain ground truth: `toolchain/lex/token_kind.def`,
    `toolchain/parse/{handle_function,precedence}.cpp`,
    `toolchain/check/{handle_match,handle_choice,handle_operator}.cpp`,
    `toolchain/check/control_flow.h`,
    `toolchain/check/cpp/{thunk,import,export}.cpp`,
    `toolchain/base/clang_invocation.cpp`,
    `toolchain/driver/compile_options.cpp`, `toolchain/lower/handle_call.cpp`,
    `toolchain/docs/check/cpp/thunks.md`, `core/prelude/types/optional.carbon`.
-   Prior art: Rust `Result`/`?`/`Try`; Swift `throws`/typed throws SE-0413;
    Zig error unions `!T`/`try`; C++ `std::expected` (P0323) and
    Herbceptions (P0709); upstream discussions #1931/#2049 (not adopted).
