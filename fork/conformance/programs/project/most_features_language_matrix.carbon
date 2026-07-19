// CONFORMANCE-BULLET: Project: toolchain implements most 0.1 language features incl. C++ interop without undermining evaluation
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   12
//   26
//   40
//
// Working slice of this PARTIAL bullet, language half: one translation unit
// composing the implemented 0.1 feature families end to end — a user-defined
// class (factory + mutating `ref self` method + reader method), a
// user-defined interface with an impl and a checked-generic function calling
// through the witness, control flow (range-based `for` over an array, `if`
// with `continue`), and tuples with element assignment. Every shape is
// verbatim from an already-PASSing single-feature program in this suite:
// classes from types/classes.carbon (examples/sieve.carbon,
// examples/advent2024/day15_common.carbon), interface/impl/witness-call from
// generics/checked_generics.carbon (examples/advent2024/sort.carbon), loops
// and array iteration from control_flow/loops.carbon
// (toolchain/lower/testdata/array/iterate.carbon), tuples from
// stdlib/tuples_arrays_structs.carbon (day15_common.carbon). The missing
// half of the bullet (match, variadics, template-dependent lowering, error
// handling, unions) is encoded in the sibling SKIP program
// most_features_missing_match.carbon.

import Core library "io";

interface Scalable {
  fn Scale(self, factor: i32) -> Self;
}

impl i32 as Scalable {
  fn Scale(self, factor: i32) -> Self { return self * factor; }
}

fn ScaleTwice[T: Core.Copy & Core.Destroy & Scalable](x: T, factor: i32) -> T {
  let once: T = x.(Scalable.Scale)(factor);
  return once.(Scalable.Scale)(factor);
}

class Accumulator {
  fn Make() -> Accumulator {
    return {.total = 0};
  }

  fn Add(ref self, n: i32) {
    self.total += n;
  }

  fn Get(self) -> i32 {
    return self.total;
  }

  var total: i32;
}

fn Run() -> i32 {
  // Classes + control flow: sum the even array elements into a class.
  var acc: Accumulator = Accumulator.Make();
  let a: array(i32, 4) = (3, 4, 5, 8);
  for (n: i32 in a) {
    if (n % 2 == 1) { continue; }
    acc.Add(n);
  }
  Core.Print(acc.Get());

  // Tuples: element access and element assignment.
  var t: (i32, i32) = (12, 13);
  t.1 += 1;
  Core.Print(t.0 + t.1);

  // Checked generics: call through the interface witness.
  let v: i32 = 10;
  Core.Print(ScaleTwice(v, 2));
  return 0;
}
