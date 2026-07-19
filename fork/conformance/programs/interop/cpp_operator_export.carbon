// CONFORMANCE-BULLET: Type system: C++ interop — exporting Carbon operator overloads into C++
// EXPECT-EXIT: 0
// EXPECT-STDOUT:
//   42
// SKIP: exporting Carbon operator impls for use from C++ is MISSING — no evidence anywhere in the toolchain (audit: "operator interop is one-directional"): interop testdata covers importing C++ operators and synthesizing Carbon overloads for imported types, but nothing maps a Carbon `impl as Core.AddWith` back to a C++ `operator+` on the exported `Carbon::` type. Un-SKIP (and uncomment the body) when the export direction lands.
//
// Write-tests-first stub. Intended future test: a Carbon class with an
// operator impl (shape verbatim from types/operator_overloading.carbon /
// toolchain/check/testdata/operators/overloaded/add.carbon), exported to an
// `inline Cpp` block where C++ applies the operator symbolically; Carbon then
// reads the result back through `Cpp.` so the round trip is observable at
// runtime (mirroring interop/cpp_export_function.carbon).

import Core library "io";
// import Cpp;
//
// class Meters {
//   var value: i32;
//   fn Make(n: i32) -> Meters { return {.value = n}; }
// }
//
// impl Meters as Core.AddWith(Meters) where .Result = Meters {
//   fn Op(self, other: Meters) -> Meters {
//     return Meters.Make(self.value + other.value);
//   }
// }
//
// inline Cpp '''
// inline int AddMetersInCpp() {
//   Carbon::Meters a = Carbon::Meters::Make(30);
//   Carbon::Meters b = Carbon::Meters::Make(12);
//   // The exported Carbon Core.AddWith impl must surface as operator+ here.
//   return (a + b).value;
// }
// ''';

fn Run() -> i32 {
  // Intended body once the feature lands:
  //   Core.Print(Cpp.AddMetersInCpp());
  //   return 0;
  // Guard: fails loudly (exit 1 vs EXPECT-EXIT 0) if un-SKIPped before
  // Carbon operator overloads are exported into C++.
  return 1;
}
