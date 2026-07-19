// CONFORMANCE-BULLET: Code organization: Importing
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
//
// The inline-import form of the import declaration: `import Cpp inline
// '''...'''` compiles the C++ source in the block and exposes its
// declarations under the `Cpp` package, exactly like a header import.
// Syntax verbatim from toolchain/check/testdata/interop/cpp/basics/inline/
// import.carbon (`import Cpp inline '''` + `inline void func() {}` +
// `''';`, called as `Cpp.func()`). The inline C++ function computes a
// value that the Carbon side prints via the imported Core//io library,
// so both import forms are exercised at runtime in one program.

import Core library "io";
import Cpp inline '''

inline auto triple(int n) -> int { return 3 * n; }

''';

fn Run() -> i32 {
  Core.Print(Cpp.triple(14));
  return 0;
}
