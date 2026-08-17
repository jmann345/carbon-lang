# Mixed-width choice miscompile — diagnosis note

(Reconstructed by the coordinator from the implementer's landed artifacts;
the implementer terminated after finishing the fix + golden but before
this note. AMENDED 2026-08-17 per the strictness review's F1: the
coalescing mechanism below is CANDIDATE W1, not established fact — the
review showed the body fingerprint hashes width-distinct data
(object-repr types by way of ClassElementAccess lowering, load/store types,
covering-copy constants: toolchain/lower/handle_aggregates.cpp:37-48,
function_context.h:124-128, function_context.cpp:193-195/:342-373), so
the two bodies should NOT have collided unless a hashing bypass exists.
CANDIDATE W2: per-specific layout resolution inside instantiated
generic bodies reused the FIRST instantiation's narrow layout — making
the i64 body identical-and-wrong, coalescing then a harmless symptom of
legitimately identical bodies, and this fix hardening rather than the
fix. The evidence to date cannot separate them. ADJUDICATION, both
mechanical: (a) the runner autoupdate of question_generic_mixed.carbon —
W2 shows NARROW shapes (4/8-byte payload objects, short covering copies)
inside the i64 specific's define even post-fix; W1 shows two defines
with correct per-width shapes; (b) the conformance re-run — W1 flips
question_generic_diff to PASS; W2 leaves it red and the S3b
CustomLayoutType per-specific recompute becomes the primary suspect.
The sret fingerprint gate is correct hardening in EITHER world — split
classes are strictly more conservative.)

## Root cause — CANDIDATE W1 (as implemented against; see amendment)

The lower-side SPECIFIC COALESCER merges monomorphized generic functions
whose type and body fingerprints match. `CreateTypeFingerprint`
(toolchain/lower/specific_coalescer.h:66) hashed only the LLVM function
type — and under opaque pointers, an sret-returning function prints as
`void (ptr, ...)` regardless of the sret POINTEE's layout. Two
instantiations of the same generic `?` chain returning `MyResult(i32,
i32)` vs `MyResult(i64, i32)` therefore carry IDENTICAL type
fingerprints; their bodies (match-reconstruct Branch, FromBreak, the
desugared `?` body) also fingerprint identically, so the coalescer
resolved both specifics to ONE lowered body. The i64 caller then passes
its 16-byte-layout sret buffer into a body compiled for the i32 layout:
the discriminant offset happens to coincide (correct Err arm), the Err
payload offset does not — the concrete reader loads a slot the shared
body never wrote, observing the stale value the previous frame left
there (the deterministic `44` in the conformance evidence).

Second defect, same family: `AreFunctionBodiesEquivalent`
(specific_coalescer.cpp:237) extends equivalence through CALLEE pairs
discovered in the closure walk without re-applying the type gate that
root pairs get at :57 — so even with the fingerprint fixed, a callee
pair differing only in sret pointee could still be committed as
equivalent through the closure.

## The fix (both halves)

1.  `CreateTypeFingerprint` now appends the sret pointee's printed type
    to the hash input (specific_coalescer.h:76-79), threaded from
    `FunctionTypeInfo::sret_type` (lower/type.h:48) through
    `HandleReferencedSpecificFunction` (file_context.cpp:330,
    :386-390).
2.  `AreFunctionBodiesEquivalent` applies `AreFunctionTypesEquivalent`
    to every callee pair before committing it, recording failures in
    `non_equivalent_specifics_` (specific_coalescer.cpp:240-246).

## Pre-B2a verdict

PREDATES B2a. The coalescer and its fingerprint are upstream machinery;
the fork's S3b per-specific choice layouts created the first specifics
that differ ONLY in sret layout while their bodies fingerprint
identically; B2a's generic `?` chain made it runtime-observable (the
suite's first mixed-width two-variant roundtrip through instantiated
generic bodies). B2a's own changes (destroy-answer clause, gate
deletion) do not feed the fingerprint or the layout.

## Falsifiable pin

toolchain/lower/testdata/operators/question_generic_mixed.carbon (new):
one generic `?` body instantiated at both widths in one module, plus
concrete writer/reader for the wide specific's narrow alternative.
Post-fix regen must show TWO distinct lowered bodies for each function
in the chain (separate sret pointees) and writer/reader addressing the
same 16-byte object; falsification = any chain function's two specifics
resolving to one body, an 8-byte object shape on the i64 Err path, or a
covering copy shorter than the specific's object size. The runtime
arbiter stays fork/conformance/programs/error_handling/question_generic_diff
(expected to flip DIFF-MISMATCH → PASS with no other program moving).

## Residues / review attention

-   Upstream 4ea5ef4 ("Skip ImplWitnessTable::elements_id when generating
    fingerprints", in the pending 2026-08-17 weekly merge) touches the
    SAME fingerprint machinery — the fix must be re-verified against
    post-merge trunk (mechanical re-read; the sret append is orthogonal
    to witness-table element skipping, but the merge may move lines).
-   The closure-level gate returns non-equivalence for the WHOLE root pair
    on the first mismatched callee pair (conservative: correctness over
    coalescing coverage). An alternative (skip just that callee pair)
    would coalesce more; rejected for the fix slice — conservative is
    correct, coverage is an optimization question.
-   Whether upstream can hit this without fork choices (any generic whose
    instantiations differ only in sret layout with constant-free bodies)
    is UPSTREAMABLE-fix material; not pursued in this slice.
-   Strictness F2 (conditional on W1): the gate hashes only the sret
    pointee; INDIRECT-parameter pointees (`ptr %self` for by-ref
    aggregates) stay invisible to the type fingerprint — if a body-hash
    bypass exists (the only way W1's collision is real), the same
    miscompile recurs through a pair differing only in a
    pointer-parameter pointee. If W1 confirms, the gate must be widened
    to all indirect pointees (follow-up in the same fix round).
-   Strictness F3: no pre-fix baseline regen exists, so the golden alone
    cannot prove the fix changed anything; the conformance flip is the
    arbiter of record (R9).

## Round 2 (2026-08-17): W1 and W2 both refuted; H-ZERO

### Arbiter result on the sret gate

The conformance arbiter re-ran on the committed 594bd1e sret-gate fix:
the failure signature is BYTE-IDENTICAL to the pre-fix run (i64 leg: Err
discriminant correct, payload = stale 44 at both depths; i32 leg fully
correct). The gate changed nothing at runtime. Combined with the
regenerated question_generic_mixed.carbon golden — which shows correct
per-width shapes everywhere (two defines per chain function, correct
sret pointees, 16-byte covers, no cross-width redirection) — BOTH round-1
candidates are refuted as root cause: W1 (fingerprint collision between
real fingerprints) cannot merge any payload-moving pair (w2-trace.md §3,
review B1), and W2 (per-specific layout reuse) has no order-dependent
path (w2-trace.md §1-§3) and is contradicted by the correct single-file
golden. The distinguishing facts about the failing program: it IMPORTS
(`import Core library "io"` — multi-file lowering) and its `?` operands
are call-result temporaries.

### Round-2 root cause — H-ZERO (zero-fingerprint coalescing commits)

### code-verified

The coalescer's fingerprint stores are PER-FILE and default-initialized:
`lowered_specifics_type_fingerprint_(specifics, {})` and
`lowered_specific_fingerprint_(specifics, {})`
(lower/specific_coalescer.cpp:13-18). An ABSENT entry therefore reads as
the all-zero default, and the equivalence checks compare raw values with
no presence notion: `AreFunctionTypesEquivalent` is a bare `Get(id1) ==
Get(id2)` (:199-204 pre-fix), and in `AreFunctionBodiesEquivalent` an
absent/absent pair passes the common-fingerprint test and is ACCEPTED by
the specific-fingerprint `continue` with no further verification
(:217-224 pre-fix). Two verified holes produce queried-but-never-written
slots, both exclusive to multi-file lowering:

1.  `GetOrCreateLLVMFunction`'s mangled-name early-return
    (lower/file_context.cpp:371-383 pre-fix) returns a function created
    while lowering a different file WITHOUT `HandleReferencedSpecificFunction`
    — the specific gets neither a type fingerprint nor a scheduled body
    (hence no body fingerprint) in this file's stores, yet
    `HandleInst(Call)` records its id into callers' `calls` lists
    unconditionally (lower/handle_call.cpp:721-723).
2.  `calls` records `callee.file`'s specific id — the file the callee
    constant resolves into, which for calls inside instantiated bodies can
    be a DIFFERENT file (handle_call.cpp:707-723) — and the file identity
    is dropped at `calls.push_back(specific_id)`
    (lower/function_context.cpp:443). The per-file stores are id-TAGGED
    (`Tag<SemIR::CheckIRId>`; toolchain/base/id_tag.h:80-93 XOR-untags with
    THIS file's tag), so a foreign id indexes a garbage slot guarded only
    by DCHECKs — in the common case an unwritten, all-zero slot.

Mechanism: a closure-walk callee pair whose two ids read absent-zero
passes the (pre-fix) type gate and body check, is committed into
`visited_equivalent_specifics`, and `ProcessSpecificEquivalence` then
marks the pair in `equivalent_specifics_` (:113-148). The root loop
treats any marked specific as replaced and `UpdateAndDeleteLLVMFunction`
RAUWs its `llvm::Function` to the "canonical" one and ERASES it
(:172-182) — the wide function's callers are silently redirected to the
narrow body. Narrow Err writes the discriminant at byte 0 (coincides —
Err arm correct) and the tag at byte 4; the wide reader loads byte 8 —
the stale 44 the previous Ok left there. This is import-only (single-file
lowering never leaves absent slots), deterministic (id/tag arithmetic is
fixed per compile), and untouched by the sret gate (zero == zero passes
any equality-based gate) — matching every observed fact.

### The round-2 plan (two commits, pin then fix)

Commit 1 — bug pin:
`toolchain/lower/testdata/operators/question_generic_crossfile.carbon`
(new): the failing shape in file_test form — `// --- lib.carbon` defines
the choice, the forall Try impl, generic Step/Discard/Chain with
call-result-temporary `?` operands, and its own narrow instantiation;
`// --- use.carbon` imports lib and instantiates i32 THEN i64 plus
concrete MakeErr64/ReadErr64. PRE-FIX regen must show the redirect
signature in use.carbon's module: a cross-width pair resolved to ONE
lowered body — a wide call site calling a define with narrow (8-byte)
sret pointee/GEP shapes, or a missing wide define. POST-FIX regen must
show two defines per width with correct per-width shapes and every wide
call site addressing only wide defines.

Commit 2 — the fixes:

1.  The early-return now writes the type fingerprint for the specific in
    this file's store (file_context.cpp; the definition is deliberately
    NOT re-registered — the creating file owns the body, and a second
    registration would attempt to redefine the function, tripping the
    `isDeclaration()` CHECK in `BuildFunctionBody`). The body fingerprint
    stays absent, which the next item makes safe.
2.  Presence tracking in the coalescer (specific_coalescer.{h,cpp}):
    `fingerprinted_types_` / `fingerprinted_bodies_` id-sets written at
    `CreateTypeFingerprint` / `InitializeFingerprintForSpecific`; the root
    type gate and the closure walk refuse any pair with a missing type OR
    body fingerprint (absent = unknown = do not merge). Membership is by
    id value, not store indexing, so foreign-file ids read as absent
    without touching the tagged stores.
3.  Latent, unrelated to this bug: the eval hook now CHECKs
    `object_layout.has_value()` before folding a payload tuple layout into
    max-of-fields (check/eval_inst.cpp) — a dependent layout must not
    contribute size 0 silently.

### W4-candidate-1 ruled out

lower/aggregate.cpp:227-234 (`EmitAggregateInitializer` InPlace)
classifies elements by way of `constant_values().Get(ref_id)` on the GENERIC
body's inst — the attached constant, shared by every specific of that
generic. The classification therefore cannot differ between the i32 and
i64 instantiations of the same body: both widths take the same branch for
each element, and the actual stores resolve per-specific
(`GetValue`/`InitializeStorage` go through the specific's value block).
A width-asymmetric skipped-or-clobbered store is unreachable from this
code for this evidence, and the observed signature (payload at the wrong
OFFSET, one width only) is a redirect/layout signature, not a
missing-store signature. Not live for this bug; no change made.

## ROOT CAUSE — ESTABLISHED (2026-08-17, round 3)

The optimization-level bisect and the post-optimization IR dump close the
case. Evidence chain, all mechanical:

1.  `--optimize=none` produces the ORACLE-EXACT output; `debug`/`default`
    corrupt the i64 Err payloads to the stale seed; `speed` corrupts them
    DIFFERENTLY (`1 1`) — level-dependent corruption of IR that is correct
    at -O0 is optimizer-exploited UB, and the divergence enters in the
    LLVM pass pipeline, after lowering (whose IR the dump shows per-width
    correct — which is also why no file_test golden could ever reproduce
    it: golden dumps never run the optimizer).
2.  The same unoptimized IR compiled with the toolchain's own clang at
    -O1 reproduces the corruption outside `carbon compile` entirely.
3.  The post-opt dump of `ProbeL` shows the exploitation verbatim: the
    discriminants fold to loads FROM THE TEMPLATE GLOBALS and the Err-arm
    payload is `trunc i64 %seed to i32` — the optimizer proved the real
    payload store irrelevant.
4.  The license: the covering-copy template globals are emitted with
    POISON payload filler —
    `@ControlFlow.val.d01.anon = constant <{ <{ i1, [7 x i8] }>, [8 x i8] }>
    <{ <{ i1 true, [7 x i8] poison }>, [8 x i8] poison }>` —
    from `EmitAsConstant(SemIR::UninitializedValue)` returning
    `PoisonValue` (toolchain/lower/constant.cpp:352). The constructor
    protocol memcpys the template (poisoning the payload bytes), then the
    element store covers only a PREFIX of the payload region in a
    mixed-width specific (i32 tag into the 8-byte region sized for the
    i64 alternative). When SROA promotes that region to one scalar, the
    residual poison bytes make the WHOLE value poison (LLVM does not
    track per-bit poison), and every downstream read is substitutable.

Why each symptom: i32 leg — the store covers the whole 4-byte region,
no residue, defined. i64 Ok — the i64 store covers all 8 bytes,
defined. i64 Err — 4 of 8 bytes stored, poison residue, whole scalar
poison; the optimizer wired the phi to the other arm's seed value. The
discriminant byte is fully DEFINED in the template (`i1 true`), so the
arm selection stayed correct at every level. Order-independent,
multi-file-independent — which is why W1 (coalescing), H-ZERO
(fingerprint holes), and W2 (layout reuse) all failed to reproduce:
they were never the mechanism.

THE FIX: `EmitAsConstant(UninitializedValue)` returns zeros
(`Constant::getNullValue`), making every covering-copied byte defined
under any partial overwrite. Golden signature: every `.val` template
global's filler flips `poison` → `zeroinitializer` in the regen; the
runtime arbiter (question_generic_diff) must flip to PASS at the
default optimization level. UPSTREAM-ALIGNMENT NOTE (V-3a): whether
`UninitializedValue`'s lowering is upstream-authored or S3b-era fork
code, upstream's covering-copy TODO in EmitAggregateInitializer
contemplates the same memcpy-then-store protocol, so a poison template
is unsound there too; flagged for the PR as potentially upstreamable.
The prior rounds' artifacts stay landed AS HARDENING (sret fingerprint
gate; the presence-set refuse-absent invariant remains staged), each
labeled for what it is.

## Review round (2026-08-17)

Both adversarial reviews returned NO BLOCKER; the conformance arbiter
confirmed the fix (84/0/30, question_generic_diff PASS). Findings
recorded and applied:

-   Correctness review, precondition refinement: the SROA
    integer-widening exploit needs a SPANNING access — the Ok arm's
    same-offset wide (i64) access is what licenses promoting the whole
    payload region to one scalar. Same-width specifics never present a
    wider same-offset access over the region, which is why ONLY mixed
    widths failed.
-   Correctness review, upstream provenance verified:
    `EmitAsConstant(UninitializedValue)`, the vptr cover, and the
    Cpp.nullptr-as-poison lowering are all upstream-authored at the fork
    root — the zeroing fix is upstreamable, not a fork-local repair of
    fork-local code.
-   Strictness review F1, record honesty: the lifetime-strip experiment
    NEVER RAN — its stripped IR variant failed to compile on a dangling
    `uselistorder`, so the lifetime-marker hypothesis was never tested.
    It was SUPERSEDED by the poison mechanism, not refuted. The poison
    mechanism itself was confirmed causally by the arbiter flip.
-   Residual padding-poison class zeroed in this batch: `PadToType`
    (lower/constant.cpp) emitted poison tail padding INSIDE the same
    covering-copied template globals — same hazard class (a whole-slot
    SROA promotion spanning discriminant+padding reproduces whole-scalar
    poison). Now `Constant::getNullValue`. Regen signature: the remaining
    `.val` poison padding (e.g. `<{ i1 true, [7 x i8] poison }>`) flips
    to zeros/`zeroinitializer`.
-   Design sanction (p000257): zeros are the proposal's "maximally safe
    representation" for unformed objects. Instruction-path poison is
    untouched, so the freedom to detect unformed-local reads is retained;
    the honest blast radius of the constant-path zeroing includes the
    Cpp.nullptr call-arg and vptr-slot golden flips.
-   Scaffolding: the three program-specific diagnostic steps ("Dump
    failing-program LLVM IR", "Optimization-level bisect",
    "Lifetime-strip experiment") are removed from fork_conformance.yaml
    post-confirmation; the referenced workflow-run logs remain the
    archival evidence.
-   R9 acknowledgment: the ROOT CAUSE section above said ESTABLISHED
    while the runtime arbiter was still pending. The falsifiable pin
    (arbiter must flip to PASS) made the claim testable, and it has
    since been confirmed.
