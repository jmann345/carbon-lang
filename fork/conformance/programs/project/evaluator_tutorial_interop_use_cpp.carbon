// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

// CONFORMANCE-BULLET: Project: basic evaluator documentation (getting started to FAQs)
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   5
//   15
//   17
//
// Transcribed from docs/guides/tutorial.md, section "Calling C++ from Carbon": the
// code after this comment block is that page's code block byte for
// byte (fork/evaluator/check_samples.py, rulebook R27). Expected output
// derived by hand in fork/evaluator/plan.md section 4 (R16(d)). Runs
// on the upstream nightly and this fork's toolchain.

import Core library "io";
import Cpp library "<cstdlib>";
import Cpp library "<vector>";
import Cpp inline '''c++
class Counter {
 public:
  Counter(int start) : total_(start) {}
  void Add(int n) { total_ += n; }
  int Total() const { return total_; }

 private:
  int total_;
};

inline std::vector<int> FirstPrimes() { return {2, 3, 5, 7}; }
''';

fn Run() -> i32 {
  // A C++ standard library function.
  Core.Print(Cpp.std.abs(-5));

  // A C++ class: constructor, mutating method, const method.
  var c: Cpp.Counter = Cpp.Counter.Counter(10);
  c.Add(5);
  Core.Print(c.Total());

  // A C++ container, iterated with a Carbon `for` loop.
  var primes: Cpp.std.vector(i32) = Cpp.FirstPrimes();
  var sum: i32 = 0;
  for (p: i32 in primes) {
    sum += p;
  }
  Core.Print(sum);
  return 0;
}
