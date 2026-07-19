// CONFORMANCE-BULLET: Control flow: loops incl. range-based and C/C++ loop equivalents
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   30
//   20
//   26
//
// while with break/continue (C loop equivalent), range-based for over
// Core.Range / Core.InclusiveRange, and range-based for over an array.
// Shapes verbatim from examples/sieve.carbon (`for (n: i32 in
// Core.Range(1000))`, `Core.InclusiveRange(2, 999)`, while), examples/
// advent2024/day15_common.carbon (`while (true)`), day2/day5 (`break;`),
// and toolchain/lower/testdata/array/iterate.carbon (for over an array).

import Core library "io";

fn Run() -> i32 {
  var sum: i32 = 0;
  var i: i32 = 0;
  while (true) {
    ++i;
    if (i > 10) { break; }
    if (i % 2 == 1) { continue; }
    sum += i;
  }
  Core.Print(sum);

  var total: i32 = 0;
  for (n: i32 in Core.Range(5)) {
    total += n;
  }
  for (n: i32 in Core.InclusiveRange(1, 4)) {
    total += n;
  }
  Core.Print(total);

  let a: array(i32, 4) = (5, 6, 7, 8);
  var arr_sum: i32 = 0;
  for (n: i32 in a) {
    arr_sum += n;
  }
  Core.Print(arr_sum);
  return 0;
}
