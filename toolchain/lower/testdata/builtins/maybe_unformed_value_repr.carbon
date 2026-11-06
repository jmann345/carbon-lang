// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/builtins/maybe_unformed_value_repr.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/builtins/maybe_unformed_value_repr.carbon

// Fork (OP-2, fork/optional2/plan.md §4, W-171): converting a value between
// `MaybeUnformed(T)` and `T`, whose value representations can differ, loads
// the value when the operand is passed by pointer and the result by copy, and
// stores it to a temporary in the other direction, concretely and in each
// specific of a generic.

// --- concrete.carbon

library "[[@TEST_NAME]]";

fn FromBool(m: Core.MaybeUnformed(bool)) -> bool { return m unsafe as bool; }

fn FromOptionalPointer(m: Core.MaybeUnformed(Core.Optional(i32*)))
    -> Core.Optional(i32*) {
  return m unsafe as Core.Optional(i32*);
}

fn RoundTrip(o: Core.Optional(i32*)) -> Core.Optional(i32*) {
  let m: Core.MaybeUnformed(Core.Optional(i32*)) =
      o unsafe as Core.MaybeUnformed(Core.Optional(i32*));
  return m unsafe as Core.Optional(i32*);
}

// --- generic.carbon

library "[[@TEST_NAME]]";

fn Unwrap[T: Core.Copy & Core.Destroy](m: Core.MaybeUnformed(T)) -> T {
  return m unsafe as T;
}

fn CallBool(m: Core.MaybeUnformed(bool)) -> bool { return Unwrap(m); }

fn CallI32(m: Core.MaybeUnformed(i32)) -> i32 { return Unwrap(m); }

fn CallOptionalPointer(m: Core.MaybeUnformed(Core.Optional(i32*)))
    -> Core.Optional(i32*) {
  return Unwrap(m);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'concrete.carbon'
// CHECK:STDOUT: source_filename = "concrete.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %self) #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !13
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CFromBool.Main(ptr %m) #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc4_68.3 = load i8, ptr %m, align 1, !dbg !20
// CHECK:STDOUT:   %.loc4_68.31 = trunc i8 %.loc4_68.3 to i1, !dbg !20
// CHECK:STDOUT:   ret i1 %.loc4_68.31, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core"(ptr %self) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %self) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5b309895020f658e:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CFromOptionalPointer.Main(ptr %m) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_19.1 = load ptr, ptr %m, align 8, !dbg !45
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.call = call ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.6e9e957697159b53"(ptr %.loc8_19.1), !dbg !45
// CHECK:STDOUT:   ret ptr %Optional.as.Copy.impl.Op.call, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CRoundTrip.Main(ptr %o) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13_16.1 = alloca ptr, align 8, !dbg !53
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc13_16.1), !dbg !53
// CHECK:STDOUT:   store ptr %o, ptr %.loc13_16.1, align 8, !dbg !53
// CHECK:STDOUT:   %.loc14_19.1 = load ptr, ptr %.loc13_16.1, align 8, !dbg !56
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.call = call ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.6e9e957697159b53"(ptr %.loc14_19.1), !dbg !56
// CHECK:STDOUT:   ret ptr %Optional.as.Copy.impl.Op.call, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.6e9e957697159b53"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT:   ret ptr %self, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.6e9e957697159b53", { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "concrete.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{!6, !6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core", scope: null, file: !4, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !14)
// CHECK:STDOUT: !12 = !DILocalVariable(arg: 1, scope: !11, type: !6)
// CHECK:STDOUT: !13 = !DILocation(line: 4, column: 16, scope: !11)
// CHECK:STDOUT: !14 = !{!12}
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "FromBool", linkageName: "_CFromBool.Main", scope: null, file: !4, line: 4, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !22)
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !15, type: !6)
// CHECK:STDOUT: !20 = !DILocation(line: 4, column: 59, scope: !15)
// CHECK:STDOUT: !21 = !DILocation(line: 4, column: 52, scope: !15)
// CHECK:STDOUT: !22 = !{!16}
// CHECK:STDOUT: !23 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !23, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !27)
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !24, type: !6)
// CHECK:STDOUT: !26 = !DILocation(line: 189, column: 19, scope: !24)
// CHECK:STDOUT: !27 = !{!25}
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core", scope: null, file: !23, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !31)
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !28, type: !6)
// CHECK:STDOUT: !30 = !DILocation(line: 189, column: 19, scope: !28)
// CHECK:STDOUT: !31 = !{!29}
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.729fca203337f92a:core.Destroy.Core", scope: null, file: !23, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !35)
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !32, type: !6)
// CHECK:STDOUT: !34 = !DILocation(line: 189, column: 19, scope: !32)
// CHECK:STDOUT: !35 = !{!33}
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5b309895020f658e:core.Destroy.Core", scope: null, file: !4, line: 6, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !39)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !6)
// CHECK:STDOUT: !38 = !DILocation(line: 6, column: 27, scope: !36)
// CHECK:STDOUT: !39 = !{!37}
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "FromOptionalPointer", linkageName: "_CFromOptionalPointer.Main", scope: null, file: !4, line: 6, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !47)
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !40, type: !6)
// CHECK:STDOUT: !45 = !DILocation(line: 8, column: 10, scope: !40)
// CHECK:STDOUT: !46 = !DILocation(line: 8, column: 3, scope: !40)
// CHECK:STDOUT: !47 = !{!41}
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "RoundTrip", linkageName: "_CRoundTrip.Main", scope: null, file: !4, line: 11, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !6)
// CHECK:STDOUT: !53 = !DILocation(line: 13, column: 7, scope: !48)
// CHECK:STDOUT: !56 = !DILocation(line: 14, column: 10, scope: !48)
// CHECK:STDOUT: !57 = !DILocation(line: 14, column: 3, scope: !48)
// CHECK:STDOUT: !58 = !{!49}
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Optional.24b7347a93330e68.Core:Copy.Core.6e9e957697159b53", scope: null, file: !23, line: 51, type: !10, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !70)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !62, type: !6)
// CHECK:STDOUT: !69 = !DILocation(line: 52, column: 5, scope: !62)
// CHECK:STDOUT: !70 = !{!63}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'generic.carbon'
// CHECK:STDOUT: source_filename = "generic.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CCallBool.Main(ptr %m) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Unwrap.call = call i1 @_CUnwrap.Main.8ae0339be4ca7eba(ptr %m), !dbg !88
// CHECK:STDOUT:   ret i1 %Unwrap.call, !dbg !89
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !91 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCallI32.Main(i32 %m) #0 !dbg !95 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Unwrap.call = call i32 @_CUnwrap.Main.4d9f279dbc2b9f6f(i32 %m), !dbg !101
// CHECK:STDOUT:   ret i32 %Unwrap.call, !dbg !102
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !104 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !106
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core"(ptr %self) #0 !dbg !108 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %self) #0 !dbg !112 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !114
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5b309895020f658e:core.Destroy.Core"(ptr %self) #0 !dbg !116 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CCallOptionalPointer.Main(ptr %m) #0 !dbg !120 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Unwrap.call = call ptr @_CUnwrap.Main.efadc3baa5285868(ptr %m), !dbg !126
// CHECK:STDOUT:   ret ptr %Unwrap.call, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CUnwrap.Main.8ae0339be4ca7eba(ptr %m) #0 !dbg !129 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_19.1 = load i8, ptr %m, align 1, !dbg !134
// CHECK:STDOUT:   %.loc5_19.11 = trunc i8 %.loc5_19.1 to i1, !dbg !134
// CHECK:STDOUT:   ret i1 %.loc5_19.11, !dbg !135
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CUnwrap.Main.4d9f279dbc2b9f6f(i32 %m) #0 !dbg !137 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %m, !dbg !143
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CUnwrap.Main.efadc3baa5285868(ptr %m) #0 !dbg !145 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc5_19.1 = load ptr, ptr %m, align 8, !dbg !150
// CHECK:STDOUT:   %Copy.WithSelf.Op.call = call ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.6e9e957697159b53"(ptr %.loc5_19.1), !dbg !150
// CHECK:STDOUT:   ret ptr %Copy.WithSelf.Op.call, !dbg !151
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.6e9e957697159b53"(ptr %self) #0 !dbg !153 {
// CHECK:STDOUT:   ret ptr %self, !dbg !160
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!72}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{!6, !6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !23 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !71 = !DIFile(filename: "generic.carbon", directory: "")
// CHECK:STDOUT: !72 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !71, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !73 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !74 = !{null, !73}
// CHECK:STDOUT: !75 = !DISubroutineType(types: !74)
// CHECK:STDOUT: !76 = !{!73, !73}
// CHECK:STDOUT: !77 = !DISubroutineType(types: !76)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core", scope: null, file: !71, line: 8, type: !8, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !81)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !78, type: !6)
// CHECK:STDOUT: !80 = !DILocation(line: 8, column: 16, scope: !78)
// CHECK:STDOUT: !81 = !{!79}
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "CallBool", linkageName: "_CCallBool.Main", scope: null, file: !71, line: 8, type: !10, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !90)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !82, type: !6)
// CHECK:STDOUT: !88 = !DILocation(line: 8, column: 59, scope: !82)
// CHECK:STDOUT: !89 = !DILocation(line: 8, column: 52, scope: !82)
// CHECK:STDOUT: !90 = !{!83}
// CHECK:STDOUT: !91 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !71, line: 10, type: !75, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !94)
// CHECK:STDOUT: !92 = !DILocalVariable(arg: 1, scope: !91, type: !73)
// CHECK:STDOUT: !93 = !DILocation(line: 10, column: 15, scope: !91)
// CHECK:STDOUT: !94 = !{!92}
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "CallI32", linkageName: "_CCallI32.Main", scope: null, file: !71, line: 10, type: !77, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !103)
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 1, scope: !95, type: !73)
// CHECK:STDOUT: !101 = !DILocation(line: 10, column: 56, scope: !95)
// CHECK:STDOUT: !102 = !DILocation(line: 10, column: 49, scope: !95)
// CHECK:STDOUT: !103 = !{!96}
// CHECK:STDOUT: !104 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !23, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !107)
// CHECK:STDOUT: !105 = !DILocalVariable(arg: 1, scope: !104, type: !6)
// CHECK:STDOUT: !106 = !DILocation(line: 189, column: 19, scope: !104)
// CHECK:STDOUT: !107 = !{!105}
// CHECK:STDOUT: !108 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core", scope: null, file: !23, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !111)
// CHECK:STDOUT: !109 = !DILocalVariable(arg: 1, scope: !108, type: !6)
// CHECK:STDOUT: !110 = !DILocation(line: 189, column: 19, scope: !108)
// CHECK:STDOUT: !111 = !{!109}
// CHECK:STDOUT: !112 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.729fca203337f92a:core.Destroy.Core", scope: null, file: !23, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !115)
// CHECK:STDOUT: !113 = !DILocalVariable(arg: 1, scope: !112, type: !6)
// CHECK:STDOUT: !114 = !DILocation(line: 189, column: 19, scope: !112)
// CHECK:STDOUT: !115 = !{!113}
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5b309895020f658e:core.Destroy.Core", scope: null, file: !71, line: 12, type: !8, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !119)
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !116, type: !6)
// CHECK:STDOUT: !118 = !DILocation(line: 12, column: 27, scope: !116)
// CHECK:STDOUT: !119 = !{!117}
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "CallOptionalPointer", linkageName: "_CCallOptionalPointer.Main", scope: null, file: !71, line: 12, type: !10, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !128)
// CHECK:STDOUT: !121 = !DILocalVariable(arg: 1, scope: !120, type: !6)
// CHECK:STDOUT: !126 = !DILocation(line: 14, column: 10, scope: !120)
// CHECK:STDOUT: !127 = !DILocation(line: 14, column: 3, scope: !120)
// CHECK:STDOUT: !128 = !{!121}
// CHECK:STDOUT: !129 = distinct !DISubprogram(name: "Unwrap", linkageName: "_CUnwrap.Main.8ae0339be4ca7eba", scope: null, file: !71, line: 4, type: !10, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !136)
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 1, scope: !129, type: !6)
// CHECK:STDOUT: !134 = !DILocation(line: 5, column: 10, scope: !129)
// CHECK:STDOUT: !135 = !DILocation(line: 5, column: 3, scope: !129)
// CHECK:STDOUT: !136 = !{!130}
// CHECK:STDOUT: !137 = distinct !DISubprogram(name: "Unwrap", linkageName: "_CUnwrap.Main.4d9f279dbc2b9f6f", scope: null, file: !71, line: 4, type: !77, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !144)
// CHECK:STDOUT: !138 = !DILocalVariable(arg: 1, scope: !137, type: !73)
// CHECK:STDOUT: !143 = !DILocation(line: 5, column: 3, scope: !137)
// CHECK:STDOUT: !144 = !{!138}
// CHECK:STDOUT: !145 = distinct !DISubprogram(name: "Unwrap", linkageName: "_CUnwrap.Main.efadc3baa5285868", scope: null, file: !71, line: 4, type: !10, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !152)
// CHECK:STDOUT: !146 = !DILocalVariable(arg: 1, scope: !145, type: !6)
// CHECK:STDOUT: !150 = !DILocation(line: 5, column: 10, scope: !145)
// CHECK:STDOUT: !151 = !DILocation(line: 5, column: 3, scope: !145)
// CHECK:STDOUT: !152 = !{!146}
// CHECK:STDOUT: !153 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Optional.24b7347a93330e68.Core:Copy.Core.6e9e957697159b53", scope: null, file: !23, line: 51, type: !10, spFlags: DISPFlagDefinition, unit: !72, retainedNodes: !161)
// CHECK:STDOUT: !154 = !DILocalVariable(arg: 1, scope: !153, type: !6)
// CHECK:STDOUT: !160 = !DILocation(line: 52, column: 5, scope: !153)
// CHECK:STDOUT: !161 = !{!154}
// CHECK:STDOUT:
