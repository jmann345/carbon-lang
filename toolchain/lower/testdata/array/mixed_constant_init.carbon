// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/array/mixed_constant_init.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/array/mixed_constant_init.carbon

// Fork (SL-2 round 4): an array initialized from a tuple literal that mixes a
// runtime element with constant ones. The `array_init` is not a constant (its
// first element is a call), so the `var`'s `Assign` copies nothing, and the
// constant elements' `in_place_init`s are skipped by `LowerInst` as constants:
// `HandleInst(ArrayInit)` now finishes them, as `EmitAggregateInitializer`
// does for struct, tuple and class inits. Predicted: a `call @_CF.Main` whose
// result is stored to `a[0]`, then `store i32 2` and `store i32 3` to the
// `array.index` of elements 1 and 2, then the load of `a[1]`. Before the fix,
// the two constant stores were absent and `a[1]` read uninitialized stack
// (the hosted conformance run 37378790657's `cpp_span_roundtrip_diff`
// mismatch). An all-constant initializer is unchanged: array_in_place.carbon
// and the all-runtime `(F(), F())` shape are unaffected.

fn F() -> i32;

fn G() -> i32 {
  var a: array(i32, 3) = (F(), 2, 3);
  return a[1];
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'mixed_constant_init.carbon'
// CHECK:STDOUT: source_filename = "mixed_constant_init.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CF.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CG.Main() #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca [3 x i32], align 4, !dbg !31
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !31
// CHECK:STDOUT:   %F.call = call i32 @_CF.Main(), !dbg !32
// CHECK:STDOUT:   %.loc29_36.2.array.index = getelementptr inbounds [3 x i32], ptr %a.var, i32 0, i64 0, !dbg !33
// CHECK:STDOUT:   store i32 %F.call, ptr %.loc29_36.2.array.index, align 4, !dbg !33
// CHECK:STDOUT:   %.loc29_36.5.array.index = getelementptr inbounds [3 x i32], ptr %a.var, i32 0, i64 1, !dbg !33
// CHECK:STDOUT:   %.loc29_36.8.array.index = getelementptr inbounds [3 x i32], ptr %a.var, i32 0, i64 2, !dbg !33
// CHECK:STDOUT:   store i32 2, ptr %.loc29_36.5.array.index, align 4, !dbg !33
// CHECK:STDOUT:   store i32 3, ptr %.loc29_36.8.array.index, align 4, !dbg !33
// CHECK:STDOUT:   %.loc30_13.1.array.index = getelementptr inbounds [3 x i32], ptr %a.var, i32 0, i32 1, !dbg !35
// CHECK:STDOUT:   %.loc30_13.2 = load i32, ptr %.loc30_13.1.array.index, align 4, !dbg !35
// CHECK:STDOUT:   call void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %a.var), !dbg !31
// CHECK:STDOUT:   ret i32 %.loc30_13.2, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc29_3.1.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 2, !dbg !43
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc29_3.1.array.index), !dbg !43
// CHECK:STDOUT:   %.loc29_3.2.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 1, !dbg !43
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc29_3.2.array.index), !dbg !43
// CHECK:STDOUT:   %.loc29_3.3.array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i64 0, !dbg !43
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc29_3.3.array.index), !dbg !43
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core"(ptr %self) #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core"(ptr %self), !dbg !47
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!19}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !18 = !DIFile(filename: "mixed_constant_init.carbon", directory: "")
// CHECK:STDOUT: !19 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !18, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !21 = !{!20}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !23 = !{null, !20}
// CHECK:STDOUT: !24 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !25 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !26 = !{null, !25}
// CHECK:STDOUT: !27 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !18, line: 28, type: !22, spFlags: DISPFlagDefinition, unit: !19)
// CHECK:STDOUT: !31 = !DILocation(line: 29, column: 3, scope: !28)
// CHECK:STDOUT: !32 = !DILocation(line: 29, column: 27, scope: !28)
// CHECK:STDOUT: !33 = !DILocation(line: 29, column: 26, scope: !28)
// CHECK:STDOUT: !35 = !DILocation(line: 30, column: 10, scope: !28)
// CHECK:STDOUT: !36 = !DILocation(line: 30, column: 3, scope: !28)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !18, line: 29, type: !24, spFlags: DISPFlagDefinition, unit: !19, retainedNodes: !40)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !20)
// CHECK:STDOUT: !39 = !DILocation(line: 29, column: 3, scope: !37)
// CHECK:STDOUT: !40 = !{!38}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !18, line: 29, type: !27, spFlags: DISPFlagDefinition, unit: !19, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !25)
// CHECK:STDOUT: !43 = !DILocation(line: 29, column: 3, scope: !41)
// CHECK:STDOUT: !44 = !{!42}
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.dc7dedd104b837b2:core.Destroy.Core", scope: null, file: !18, line: 29, type: !27, spFlags: DISPFlagDefinition, unit: !19, retainedNodes: !48)
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !45, type: !25)
// CHECK:STDOUT: !47 = !DILocation(line: 29, column: 3, scope: !45)
// CHECK:STDOUT: !48 = !{!46}
// CHECK:STDOUT:
