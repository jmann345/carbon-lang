# Mixed-width choice miscompile — diagnosis note

(Reconstructed by the coordinator from the implementer's landed artifacts;
the implementer terminated after finishing the fix + golden but before
this note. AMENDED 2026-08-17 per the strictness review's F1: the
coalescing mechanism below is CANDIDATE W1, not established fact — the
review showed the body fingerprint hashes width-distinct data
(object-repr types via ClassElementAccess lowering, load/store types,
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

1. `CreateTypeFingerprint` now appends the sret pointee's printed type
   to the hash input (specific_coalescer.h:76-79), threaded from
   `FunctionTypeInfo::sret_type` (lower/type.h:48) through
   `HandleReferencedSpecificFunction` (file_context.cpp:330,
   :386-390).
2. `AreFunctionBodiesEquivalent` applies `AreFunctionTypesEquivalent`
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

- Upstream 4ea5ef4 ("Skip ImplWitnessTable::elements_id when generating
  fingerprints", in the pending 2026-08-17 weekly merge) touches the
  SAME fingerprint machinery — the fix must be re-verified against
  post-merge trunk (mechanical re-read; the sret append is orthogonal
  to witness-table element skipping, but the merge may move lines).
- The closure-level gate returns non-equivalence for the WHOLE root pair
  on the first mismatched callee pair (conservative: correctness over
  coalescing coverage). An alternative (skip just that callee pair)
  would coalesce more; rejected for the fix slice — conservative is
  correct, coverage is an optimization question.
- Whether upstream can hit this without fork choices (any generic whose
  instantiations differ only in sret layout with constant-free bodies)
  is UPSTREAMABLE-fix material; not pursued in this slice.
- Strictness F2 (conditional on W1): the gate hashes only the sret
  pointee; INDIRECT-parameter pointees (`ptr %self` for by-ref
  aggregates) stay invisible to the type fingerprint — if a body-hash
  bypass exists (the only way W1's collision is real), the same
  miscompile recurs through a pair differing only in a
  pointer-parameter pointee. If W1 confirms, the gate must be widened
  to all indirect pointees (follow-up in the same fix round).
- Strictness F3: no pre-fix baseline regen exists, so the golden alone
  cannot prove the fix changed anything; the conformance flip is the
  arbiter of record (R9).
