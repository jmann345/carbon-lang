// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/optional/destroy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/optional/destroy.carbon

// Fork (OP-2, fork/optional2/plan.md §4): destroying a `Core.Optional(T)`
// destroys its value only when it holds one (W-170), `Core.Optional(T*)` has
// no destruction work, `Get()` fails-stop on an empty value (W-173), and
// `Core.Optional(bool)`'s `Get()` loads the `bool` from its storage (W-171).

// --- destroy.carbon

library "[[@TEST_NAME]]";

class Tracked {
  var n: i32;
  impl as Core.Copy {
    fn Op(self) -> Self { return {.n = self.n}; }
  }
  impl as Core.Destroy {
    fn Op(unused ref self) {}
  }
}

fn Hold(t: Tracked) {
  var unused o: Core.Optional(Tracked) = Core.Optional(Tracked).Some(t);
}

fn HoldPointer(p: i32*) {
  var unused o: Core.Optional(i32*) = Core.Optional(i32*).Some(p);
}

// --- get.carbon

library "[[@TEST_NAME]]";

fn GetI32(o: Core.Optional(i32)) -> i32 { return o.Get(); }

fn GetBool(o: Core.Optional(bool)) -> bool { return o.Get(); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'destroy.carbon'
// CHECK:STDOUT: source_filename = "destroy.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.Tracked.Main:Copy.Core"(ptr sret({ i32 }) %return, ptr %self) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_44.1.n = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !17
// CHECK:STDOUT:   %.loc7_44.2 = load i32, ptr %.loc7_44.1.n, align 4, !dbg !17
// CHECK:STDOUT:   %.loc7_46.2.n = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   store i32 %.loc7_44.2, ptr %.loc7_46.2.n, align 4, !dbg !18
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.Tracked.Main:Destroy.Core"(ptr %self) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CHold.Main(ptr %t) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %o.var = alloca <{ { i32 }, i1 }>, align 4, !dbg !29
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %o.var), !dbg !29
// CHECK:STDOUT:   call void @_CSome.Optional.Core.71368b6e5e697e33(ptr %o.var, ptr %t), !dbg !31
// CHECK:STDOUT:   call void @"_CSelfDestruct.82bc4e4b1089b402:core.Destroy.Core"(ptr %o.var), !dbg !29
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.82bc4e4b1089b402:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.f8230bb8a2bfa7e1(ptr %self), !dbg !37
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.82bc4e4b1089b402:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.82bc4e4b1089b402:core.Destroy.Core"(ptr %self), !dbg !41
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CHoldPointer.Main(ptr %p) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %o.var = alloca ptr, align 8, !dbg !46
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %o.var), !dbg !46
// CHECK:STDOUT:   %Optional.Some.call = call ptr @_CSome.Optional.Core.6e9e957697159b53(ptr %p), !dbg !48
// CHECK:STDOUT:   store ptr %Optional.Some.call, ptr %o.var, align 8, !dbg !46
// CHECK:STDOUT:   call void @"_CSelfDestruct.5b309895020f658e:core.Destroy.Core"(ptr %o.var), !dbg !46
// CHECK:STDOUT:   ret void, !dbg !50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core"(ptr %self) #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %self) #0 !dbg !61 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !63
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5b309895020f658e:core.Destroy.Core"(ptr %self) #0 !dbg !65 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Core.71368b6e5e697e33(ptr sret(<{ { i32 }, i1 }>) %return, ptr %value) #0 !dbg !72 {
// CHECK:STDOUT:   call void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.44b23c3927456891"(ptr %return, ptr %value), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.f8230bb8a2bfa7e1(ptr %self) #0 !dbg !81 {
// CHECK:STDOUT:   call void @"_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.44b23c3927456891"(ptr %self), !dbg !84
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.f8230bb8a2bfa7e1(ptr %self), !dbg !85
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CSome.Optional.Core.6e9e957697159b53(ptr %value) #0 !dbg !88 {
// CHECK:STDOUT:   %1 = call ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %value), !dbg !93
// CHECK:STDOUT:   ret ptr %1, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.44b23c3927456891"(ptr sret(<{ { i32 }, i1 }>) %return, ptr %self) #0 !dbg !96 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ { i32 }, i1 }>, ptr %return, i32 0, i32 0, !dbg !105
// CHECK:STDOUT:   call void @"_COp.Tracked.Main:Copy.Core"(ptr %value, ptr %self), !dbg !106
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ { i32 }, i1 }>, ptr %return, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !107
// CHECK:STDOUT:   ret void, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.44b23c3927456891"(ptr %self) #0 !dbg !110 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ { i32 }, i1 }>, ptr %self, i32 0, i32 1, !dbg !113
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !113
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !113
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !114
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ { i32 }, i1 }>, ptr %self, i32 0, i32 0, !dbg !115
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.cb8b1d1041f62806(ptr %value), !dbg !116
// CHECK:STDOUT:   br label %4, !dbg !117
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %3, %0
// CHECK:STDOUT:   ret void, !dbg !118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.f8230bb8a2bfa7e1(ptr %self) #0 !dbg !120 {
// CHECK:STDOUT:   ret void, !dbg !123
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %self) #0 !dbg !125 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !130
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !130
// CHECK:STDOUT:   store ptr poison, ptr %1, align 8, !dbg !130
// CHECK:STDOUT:   store ptr %self, ptr %1, align 8, !dbg !134
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8, !dbg !132
// CHECK:STDOUT:   call void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %1), !dbg !130
// CHECK:STDOUT:   ret ptr %2, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.cb8b1d1041f62806(ptr %self) #0 !dbg !138 {
// CHECK:STDOUT:   call void @"_COp.Tracked.Main:Destroy.Core"(ptr %self), !dbg !141
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.f8230bb8a2bfa7e1(ptr %self), !dbg !142
// CHECK:STDOUT:   ret void, !dbg !143
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 2, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "destroy.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Tracked.Main:Copy.Core", scope: null, file: !4, line: 7, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !20)
// CHECK:STDOUT: !13 = !DILocalVariable(arg: 1, scope: !12, type: !7)
// CHECK:STDOUT: !17 = !DILocation(line: 7, column: 40, scope: !12)
// CHECK:STDOUT: !18 = !DILocation(line: 7, column: 34, scope: !12)
// CHECK:STDOUT: !19 = !DILocation(line: 7, column: 27, scope: !12)
// CHECK:STDOUT: !20 = !{!13}
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Tracked.Main:Destroy.Core", scope: null, file: !4, line: 10, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !25)
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !21, type: !7)
// CHECK:STDOUT: !24 = !DILocation(line: 10, column: 5, scope: !21)
// CHECK:STDOUT: !25 = !{!22}
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "Hold", linkageName: "_CHold.Main", scope: null, file: !4, line: 14, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !34)
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !26, type: !7)
// CHECK:STDOUT: !29 = !DILocation(line: 15, column: 3, scope: !26)
// CHECK:STDOUT: !31 = !DILocation(line: 15, column: 42, scope: !26)
// CHECK:STDOUT: !33 = !DILocation(line: 14, column: 1, scope: !26)
// CHECK:STDOUT: !34 = !{!27}
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.82bc4e4b1089b402:core.Destroy.Core", scope: null, file: !4, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !38)
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !35, type: !7)
// CHECK:STDOUT: !37 = !DILocation(line: 15, column: 3, scope: !35)
// CHECK:STDOUT: !38 = !{!36}
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.82bc4e4b1089b402:core.Destroy.Core", scope: null, file: !4, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !7)
// CHECK:STDOUT: !41 = !DILocation(line: 15, column: 3, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "HoldPointer", linkageName: "_CHoldPointer.Main", scope: null, file: !4, line: 18, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !51)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !7)
// CHECK:STDOUT: !46 = !DILocation(line: 19, column: 3, scope: !43)
// CHECK:STDOUT: !48 = !DILocation(line: 19, column: 39, scope: !43)
// CHECK:STDOUT: !50 = !DILocation(line: 18, column: 1, scope: !43)
// CHECK:STDOUT: !51 = !{!44}
// CHECK:STDOUT: !52 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !52, line: 189, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !56)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !7)
// CHECK:STDOUT: !55 = !DILocation(line: 189, column: 19, scope: !53)
// CHECK:STDOUT: !56 = !{!54}
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core", scope: null, file: !52, line: 189, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !60)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !57, type: !7)
// CHECK:STDOUT: !59 = !DILocation(line: 189, column: 19, scope: !57)
// CHECK:STDOUT: !60 = !{!58}
// CHECK:STDOUT: !61 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.729fca203337f92a:core.Destroy.Core", scope: null, file: !52, line: 189, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !64)
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 1, scope: !61, type: !7)
// CHECK:STDOUT: !63 = !DILocation(line: 189, column: 19, scope: !61)
// CHECK:STDOUT: !64 = !{!62}
// CHECK:STDOUT: !65 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5b309895020f658e:core.Destroy.Core", scope: null, file: !4, line: 19, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !68)
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 1, scope: !65, type: !7)
// CHECK:STDOUT: !67 = !DILocation(line: 19, column: 3, scope: !65)
// CHECK:STDOUT: !68 = !{!66}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.71368b6e5e697e33", scope: null, file: !52, line: 34, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !79)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !7)
// CHECK:STDOUT: !77 = !DILocation(line: 35, column: 12, scope: !72)
// CHECK:STDOUT: !78 = !DILocation(line: 35, column: 5, scope: !72)
// CHECK:STDOUT: !79 = !{!73}
// CHECK:STDOUT: !80 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.f8230bb8a2bfa7e1", scope: null, file: !80, line: 26, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !87)
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !81, type: !7)
// CHECK:STDOUT: !84 = !DILocation(line: 27, column: 5, scope: !81)
// CHECK:STDOUT: !85 = !DILocation(line: 28, column: 5, scope: !81)
// CHECK:STDOUT: !86 = !DILocation(line: 26, column: 3, scope: !81)
// CHECK:STDOUT: !87 = !{!82}
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.6e9e957697159b53", scope: null, file: !52, line: 34, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !95)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !7)
// CHECK:STDOUT: !93 = !DILocation(line: 35, column: 12, scope: !88)
// CHECK:STDOUT: !94 = !DILocation(line: 35, column: 5, scope: !88)
// CHECK:STDOUT: !95 = !{!89}
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.44b23c3927456891", scope: null, file: !52, line: 156, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !109)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !96, type: !7)
// CHECK:STDOUT: !105 = !DILocation(line: 162, column: 5, scope: !96)
// CHECK:STDOUT: !106 = !DILocation(line: 162, column: 28, scope: !96)
// CHECK:STDOUT: !107 = !DILocation(line: 163, column: 5, scope: !96)
// CHECK:STDOUT: !108 = !DILocation(line: 164, column: 5, scope: !96)
// CHECK:STDOUT: !109 = !{!97}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "Op", linkageName: "_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.44b23c3927456891", scope: null, file: !52, line: 284, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !119)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !7)
// CHECK:STDOUT: !113 = !DILocation(line: 285, column: 9, scope: !110)
// CHECK:STDOUT: !114 = !DILocation(line: 285, column: 8, scope: !110)
// CHECK:STDOUT: !115 = !DILocation(line: 286, column: 8, scope: !110)
// CHECK:STDOUT: !116 = !DILocation(line: 286, column: 7, scope: !110)
// CHECK:STDOUT: !117 = !DILocation(line: 285, column: 5, scope: !110)
// CHECK:STDOUT: !118 = !DILocation(line: 284, column: 3, scope: !110)
// CHECK:STDOUT: !119 = !{!111}
// CHECK:STDOUT: !120 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.f8230bb8a2bfa7e1", scope: null, file: !80, line: 19, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !124)
// CHECK:STDOUT: !121 = !DILocalVariable(arg: 1, scope: !120, type: !7)
// CHECK:STDOUT: !123 = !DILocation(line: 19, column: 3, scope: !120)
// CHECK:STDOUT: !124 = !{!121}
// CHECK:STDOUT: !125 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba", scope: null, file: !52, line: 191, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !137)
// CHECK:STDOUT: !126 = !DILocalVariable(arg: 1, scope: !125, type: !7)
// CHECK:STDOUT: !130 = !DILocation(line: 192, column: 14, scope: !125)
// CHECK:STDOUT: !132 = !DILocation(line: 192, column: 18, scope: !125)
// CHECK:STDOUT: !134 = !DILocation(line: 194, column: 5, scope: !125)
// CHECK:STDOUT: !136 = !DILocation(line: 195, column: 5, scope: !125)
// CHECK:STDOUT: !137 = !{!126}
// CHECK:STDOUT: !138 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.cb8b1d1041f62806", scope: null, file: !80, line: 26, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !144)
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !138, type: !7)
// CHECK:STDOUT: !141 = !DILocation(line: 27, column: 5, scope: !138)
// CHECK:STDOUT: !142 = !DILocation(line: 28, column: 5, scope: !138)
// CHECK:STDOUT: !143 = !DILocation(line: 26, column: 3, scope: !138)
// CHECK:STDOUT: !144 = !{!139}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'get.carbon'
// CHECK:STDOUT: source_filename = "get.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 57 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !156 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !158
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGetI32.Main(ptr %o) #0 !dbg !160 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.Get.call = call i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %o), !dbg !165
// CHECK:STDOUT:   ret i32 %Optional.Get.call, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %self) #0 !dbg !168 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !170
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i1 @_CGetBool.Main(ptr %o) #0 !dbg !172 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.Get.call = call i1 @_CGet.Optional.Core.6ef0c29017c0a77f(ptr %o), !dbg !177
// CHECK:STDOUT:   ret i1 %Optional.Get.call, !dbg !178
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Optional.Core.3530343734a6ea27(ptr %self) #0 !dbg !180 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self), !dbg !185
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !186
// CHECK:STDOUT:   br i1 %2, label %3, label %5, !dbg !187
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !188
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !188
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !188
// CHECK:STDOUT:   %4 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !188
// CHECK:STDOUT:   call void @abort(), !dbg !188
// CHECK:STDOUT:   br label %5, !dbg !189
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3, %0
// CHECK:STDOUT:   %6 = call i32 @"_CGet.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %self), !dbg !191
// CHECK:STDOUT:   ret i32 %6, !dbg !192
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CGet.Optional.Core.6ef0c29017c0a77f(ptr %self) #0 !dbg !194 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.6ef0c29017c0a77f(ptr %self), !dbg !199
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !200
// CHECK:STDOUT:   br i1 %2, label %3, label %5, !dbg !201
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !202
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !202
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !202
// CHECK:STDOUT:   %4 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !202
// CHECK:STDOUT:   call void @abort(), !dbg !202
// CHECK:STDOUT:   br label %5, !dbg !203
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3, %0
// CHECK:STDOUT:   %6 = call i1 @"_CGet.74becf39533834ee:OptionalStorage.Core.27639e8ca00f0d64"(ptr %self), !dbg !205
// CHECK:STDOUT:   ret i1 %6, !dbg !206
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.3530343734a6ea27(ptr %self) #0 !dbg !208 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %self), !dbg !214
// CHECK:STDOUT:   ret i1 %1, !dbg !215
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CGet.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %value) #0 !dbg !217 {
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 0, !dbg !222
// CHECK:STDOUT:   %1 = load i32, ptr %value1, align 4, !dbg !222
// CHECK:STDOUT:   ret i32 %1, !dbg !223
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.6ef0c29017c0a77f(ptr %self) #0 !dbg !225 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.27639e8ca00f0d64"(ptr %self), !dbg !231
// CHECK:STDOUT:   ret i1 %1, !dbg !232
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CGet.74becf39533834ee:OptionalStorage.Core.27639e8ca00f0d64"(ptr %value) #0 !dbg !234 {
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw { i1, i1 }, ptr %value, i32 0, i32 0, !dbg !239
// CHECK:STDOUT:   %1 = load i8, ptr %value1, align 1, !dbg !239
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !239
// CHECK:STDOUT:   ret i1 %2, !dbg !240
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %value) #0 !dbg !242 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 1, !dbg !247
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !247
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !247
// CHECK:STDOUT:   ret i1 %2, !dbg !248
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.74becf39533834ee:OptionalStorage.Core.27639e8ca00f0d64"(ptr %value) #0 !dbg !250 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw { i1, i1 }, ptr %value, i32 0, i32 1, !dbg !255
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !255
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !255
// CHECK:STDOUT:   ret i1 %2, !dbg !256
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @abort, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { noreturn }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!151}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !52 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !150 = !DIFile(filename: "get.carbon", directory: "")
// CHECK:STDOUT: !151 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !150, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !152 = !{null, !6}
// CHECK:STDOUT: !153 = !DISubroutineType(types: !152)
// CHECK:STDOUT: !154 = !{!6, !7}
// CHECK:STDOUT: !155 = !DISubroutineType(types: !154)
// CHECK:STDOUT: !156 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !150, line: 4, type: !153, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !159)
// CHECK:STDOUT: !157 = !DILocalVariable(arg: 1, scope: !156, type: !6)
// CHECK:STDOUT: !158 = !DILocation(line: 4, column: 14, scope: !156)
// CHECK:STDOUT: !159 = !{!157}
// CHECK:STDOUT: !160 = distinct !DISubprogram(name: "GetI32", linkageName: "_CGetI32.Main", scope: null, file: !150, line: 4, type: !155, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !167)
// CHECK:STDOUT: !161 = !DILocalVariable(arg: 1, scope: !160, type: !7)
// CHECK:STDOUT: !165 = !DILocation(line: 4, column: 50, scope: !160)
// CHECK:STDOUT: !166 = !DILocation(line: 4, column: 43, scope: !160)
// CHECK:STDOUT: !167 = !{!161}
// CHECK:STDOUT: !168 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core", scope: null, file: !150, line: 6, type: !11, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !171)
// CHECK:STDOUT: !169 = !DILocalVariable(arg: 1, scope: !168, type: !7)
// CHECK:STDOUT: !170 = !DILocation(line: 6, column: 15, scope: !168)
// CHECK:STDOUT: !171 = !{!169}
// CHECK:STDOUT: !172 = distinct !DISubprogram(name: "GetBool", linkageName: "_CGetBool.Main", scope: null, file: !150, line: 6, type: !9, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !179)
// CHECK:STDOUT: !173 = !DILocalVariable(arg: 1, scope: !172, type: !7)
// CHECK:STDOUT: !177 = !DILocation(line: 6, column: 53, scope: !172)
// CHECK:STDOUT: !178 = !DILocation(line: 6, column: 46, scope: !172)
// CHECK:STDOUT: !179 = !{!173}
// CHECK:STDOUT: !180 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.3530343734a6ea27", scope: null, file: !52, line: 40, type: !155, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !193)
// CHECK:STDOUT: !181 = !DILocalVariable(arg: 1, scope: !180, type: !7)
// CHECK:STDOUT: !185 = !DILocation(line: 303, column: 11, scope: !180)
// CHECK:STDOUT: !186 = !DILocation(line: 303, column: 7, scope: !180)
// CHECK:STDOUT: !187 = !DILocation(line: 303, column: 6, scope: !180)
// CHECK:STDOUT: !188 = !DILocation(line: 304, column: 5, scope: !180)
// CHECK:STDOUT: !189 = !DILocation(line: 303, column: 3, scope: !180)
// CHECK:STDOUT: !191 = !DILocation(line: 306, column: 10, scope: !180)
// CHECK:STDOUT: !192 = !DILocation(line: 306, column: 3, scope: !180)
// CHECK:STDOUT: !193 = !{!181}
// CHECK:STDOUT: !194 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.6ef0c29017c0a77f", scope: null, file: !52, line: 40, type: !9, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !207)
// CHECK:STDOUT: !195 = !DILocalVariable(arg: 1, scope: !194, type: !7)
// CHECK:STDOUT: !199 = !DILocation(line: 303, column: 11, scope: !194)
// CHECK:STDOUT: !200 = !DILocation(line: 303, column: 7, scope: !194)
// CHECK:STDOUT: !201 = !DILocation(line: 303, column: 6, scope: !194)
// CHECK:STDOUT: !202 = !DILocation(line: 304, column: 5, scope: !194)
// CHECK:STDOUT: !203 = !DILocation(line: 303, column: 3, scope: !194)
// CHECK:STDOUT: !205 = !DILocation(line: 306, column: 10, scope: !194)
// CHECK:STDOUT: !206 = !DILocation(line: 306, column: 3, scope: !194)
// CHECK:STDOUT: !207 = !{!195}
// CHECK:STDOUT: !208 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.3530343734a6ea27", scope: null, file: !52, line: 37, type: !9, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !216)
// CHECK:STDOUT: !209 = !DILocalVariable(arg: 1, scope: !208, type: !7)
// CHECK:STDOUT: !214 = !DILocation(line: 38, column: 12, scope: !208)
// CHECK:STDOUT: !215 = !DILocation(line: 38, column: 5, scope: !208)
// CHECK:STDOUT: !216 = !{!209}
// CHECK:STDOUT: !217 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !52, line: 169, type: !155, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !224)
// CHECK:STDOUT: !218 = !DILocalVariable(arg: 1, scope: !217, type: !7)
// CHECK:STDOUT: !222 = !DILocation(line: 170, column: 12, scope: !217)
// CHECK:STDOUT: !223 = !DILocation(line: 170, column: 5, scope: !217)
// CHECK:STDOUT: !224 = !{!218}
// CHECK:STDOUT: !225 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.6ef0c29017c0a77f", scope: null, file: !52, line: 37, type: !9, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !233)
// CHECK:STDOUT: !226 = !DILocalVariable(arg: 1, scope: !225, type: !7)
// CHECK:STDOUT: !231 = !DILocation(line: 38, column: 12, scope: !225)
// CHECK:STDOUT: !232 = !DILocation(line: 38, column: 5, scope: !225)
// CHECK:STDOUT: !233 = !{!226}
// CHECK:STDOUT: !234 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.74becf39533834ee:OptionalStorage.Core.27639e8ca00f0d64", scope: null, file: !52, line: 169, type: !9, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !241)
// CHECK:STDOUT: !235 = !DILocalVariable(arg: 1, scope: !234, type: !7)
// CHECK:STDOUT: !239 = !DILocation(line: 170, column: 12, scope: !234)
// CHECK:STDOUT: !240 = !DILocation(line: 170, column: 5, scope: !234)
// CHECK:STDOUT: !241 = !{!235}
// CHECK:STDOUT: !242 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !52, line: 166, type: !9, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !249)
// CHECK:STDOUT: !243 = !DILocalVariable(arg: 1, scope: !242, type: !7)
// CHECK:STDOUT: !247 = !DILocation(line: 167, column: 12, scope: !242)
// CHECK:STDOUT: !248 = !DILocation(line: 167, column: 5, scope: !242)
// CHECK:STDOUT: !249 = !{!243}
// CHECK:STDOUT: !250 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.74becf39533834ee:OptionalStorage.Core.27639e8ca00f0d64", scope: null, file: !52, line: 166, type: !9, spFlags: DISPFlagDefinition, unit: !151, retainedNodes: !257)
// CHECK:STDOUT: !251 = !DILocalVariable(arg: 1, scope: !250, type: !7)
// CHECK:STDOUT: !255 = !DILocation(line: 167, column: 12, scope: !250)
// CHECK:STDOUT: !256 = !DILocation(line: 167, column: 5, scope: !250)
// CHECK:STDOUT: !257 = !{!251}
// CHECK:STDOUT:
