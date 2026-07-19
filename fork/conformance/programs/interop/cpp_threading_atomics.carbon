// CONFORMANCE-BULLET: C++ interop: threading, atomics, memory model, synchronization
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   8
// SKIP: MISSING — no dedicated support, tests, or design doc anywhere in toolchain/ or docs/design/: nothing defines Carbon's memory model, how std::thread/std::mutex/std::atomic map into Carbon, or what synchronization guarantees hold for Carbon code called from C++ threads. Un-SKIP (and uncomment the body) when a threading/atomics interop design lands and Cpp.std.thread/Cpp.std.atomic are usable from Carbon.
//
// Write-tests-first stub. Intended future test: import <thread>/<atomic>
// via `import Cpp inline` (block shape from
// interop/cpp_operator_import_arithmetic.carbon), spawn C++ threads that
// each fetch_add a std::atomic<int> shared with Carbon, join them, and
// print the final count — proving cross-language data-race-free
// synchronization under a defined memory model, not just API import.

import Core library "io";
// import Cpp inline '''c++
// #include <atomic>
// #include <thread>
//
// inline std::atomic<int> counter{0};
//
// inline void BumpFromTwoThreads(int times) {
//   std::thread a([times] { for (int i = 0; i < times; ++i) counter.fetch_add(1); });
//   std::thread b([times] { for (int i = 0; i < times; ++i) counter.fetch_add(1); });
//   a.join();
//   b.join();
// }
// ''';

fn Run() -> i32 {
  // Intended body once the feature lands:
  //   Cpp.BumpFromTwoThreads(4);
  //   Core.Print(Cpp.counter.load());
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // threading/atomics interop exists.
  return 1;
}
