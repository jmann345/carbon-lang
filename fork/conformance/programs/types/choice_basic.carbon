// CONFORMANCE-BULLET: Type system: Sum types (discriminated unions)
// EXPECT-EXIT: 0
//
// Parameterless `choice` (the enum substitute) — declaration, alternative
// construction, and global/local `let` bindings, shapes verbatim from
// toolchain/lower/testdata/choice/basic.carbon (the only choice construct
// with a lowering golden).
//
// NOTE: this deliberately arbitrates only the working slice of the bullet
// (gap-analysis marks it PARTIAL). `match` on a choice cannot be used —
// all check handlers in toolchain/check/handle_match.cpp are TODO stubs —
// and choice types have no `==`/Core.EqWith impl, so the observable
// behavior here is just: compiles, links, runs, exits 0. Extend this
// program when W4/W5 (match semantics, choice payloads) land.

choice Direction {
  North,
  East,
  South,
  West
}

let facing: Direction = Direction.East;

fn Run() -> i32 {
  let unused turned: Direction = Direction.West;
  return 0;
}
