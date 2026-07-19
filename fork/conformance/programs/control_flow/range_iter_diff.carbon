// CONFORMANCE-BULLET: Control flow: loops incl. range-based and C/C++ loop equivalents
// EXPECT-EXIT: 0
//
// Differential pair: range_iter_diff.diff.cpp is the equivalent C++17
// program (index for-loops for the integer ranges, range-based for over an
// array); the runner requires byte-identical exit code and stdout, so the
// C++ loops are the oracle for the iteration order and sums — no
// hand-authored EXPECT-STDOUT. Carbon shapes verbatim from
// control_flow/loops.carbon / examples/sieve.carbon (`for (n: i32 in
// Core.Range(...))`, `Core.InclusiveRange(lo, hi)`) and
// toolchain/lower/testdata/array/iterate.carbon (for over an array).

import Core library "io";

fn Run() -> i32 {
  // Half-open [0, 10): C++ `for (int n = 0; n < 10; ++n)`.
  var sum: i32 = 0;
  for (n: i32 in Core.Range(10)) {
    sum += n;
  }
  Core.Print(sum);

  // Inclusive [3, 7]: C++ `for (int n = 3; n <= 7; ++n)`.
  var isum: i32 = 0;
  for (n: i32 in Core.InclusiveRange(3, 7)) {
    isum += n;
  }
  Core.Print(isum);

  // Range-based for over an array, element order observable.
  let a: array(i32, 5) = (2, 4, 8, 16, 32);
  var arr_sum: i32 = 0;
  for (n: i32 in a) {
    Core.Print(n);
    arr_sum += n;
  }
  Core.Print(arr_sum);
  return 0;
}
