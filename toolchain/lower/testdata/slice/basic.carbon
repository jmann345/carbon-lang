// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/slice/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/slice/basic.carbon

// Fork (SL-1, fork/slices/plan.md §4.A): the D-SL-4 arbiter at the IR level.
// Predicted in the `Get` specific: `icmp slt i64 %i, 0`, `icmp sge i64 %i,
// %size`, an `or i1`, `br i1`, the `write` + `abort` calls in the fail block,
// and `getelementptr inbounds i32` + `load i32` on the success path; in `F`
// the `FromArray` specific stores the array address and `i64 4` into the
// slice's `{ptr, i64}` storage.

fn F() -> i32 {
  var a: array(i32, 4) = (1, 2, 3, 4);
  let s: Core.Slice(i32) = Core.Slice(i32).FromArray(&a);
  return s[1];
}

fn G(s: Core.Slice(i32), i: i64) -> i32 {
  return s[i];
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'basic.carbon'
// CHECK:STDOUT: source_filename = "basic.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @array.loc21_3 = internal constant [4 x i32] [i32 1, i32 2, i32 3, i32 4]
// CHECK:STDOUT: @0 = private unnamed_addr constant [53 x i8] c"carbon: Core.Slice index out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @1 = private unnamed_addr constant [62 x i8] c"carbon: Core.Slice.Subslice range out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 52 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main() #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca [4 x i32], align 4, !dbg !22
// CHECK:STDOUT:   %.loc22_56.3.temp = alloca { ptr, i64 }, align 8, !dbg !27
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !22
// CHECK:STDOUT:   %.loc21_37.3.array.index = getelementptr inbounds [4 x i32], ptr %a.var, i32 0, i64 0, !dbg !23
// CHECK:STDOUT:   %.loc21_37.6.array.index = getelementptr inbounds [4 x i32], ptr %a.var, i32 0, i64 1, !dbg !23
// CHECK:STDOUT:   %.loc21_37.9.array.index = getelementptr inbounds [4 x i32], ptr %a.var, i32 0, i64 2, !dbg !23
// CHECK:STDOUT:   %.loc21_37.12.array.index = getelementptr inbounds [4 x i32], ptr %a.var, i32 0, i64 3, !dbg !23
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %a.var, ptr align 4 @array.loc21_3, i64 16, i1 false), !dbg !22
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc22_56.3.temp), !dbg !27
// CHECK:STDOUT:   call void @_CFromArray.Slice.Core.751a3c1d2a013038(ptr %.loc22_56.3.temp, ptr %a.var), !dbg !27
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.call = call ptr @"_CRef.Slice.a081b942542726db.Core:IndirectIndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f"(ptr %.loc22_56.3.temp, i64 1), !dbg !32
// CHECK:STDOUT:   %.loc23_13 = load i32, ptr %Slice.as.IndirectIndexWith.impl.Ref.call, align 4, !dbg !32
// CHECK:STDOUT:   call void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %.loc22_56.3.temp), !dbg !27
// CHECK:STDOUT:   call void @"_CSelfDestruct.88cc3346b7991af5:core.Destroy.Core"(ptr %a.var), !dbg !22
// CHECK:STDOUT:   ret i32 %.loc23_13, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc22_56.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !50
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc22_56.1.size), !dbg !50
// CHECK:STDOUT:   %.loc22_56.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !50
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.loc22_56.2.ptr), !dbg !50
// CHECK:STDOUT:   ret void, !dbg !50
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self), !dbg !54
// CHECK:STDOUT:   ret void, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc22_56.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc22_56.1.size), !dbg !58
// CHECK:STDOUT:   %.loc22_56.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.loc22_56.2.ptr), !dbg !58
// CHECK:STDOUT:   ret void, !dbg !58
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !60 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self), !dbg !62
// CHECK:STDOUT:   ret void, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.88cc3346b7991af5:core.Destroy.Core"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_3.1.array.index = getelementptr inbounds [4 x i32], ptr %self, i32 0, i64 3, !dbg !66
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc21_3.1.array.index), !dbg !66
// CHECK:STDOUT:   %.loc21_3.2.array.index = getelementptr inbounds [4 x i32], ptr %self, i32 0, i64 2, !dbg !66
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc21_3.2.array.index), !dbg !66
// CHECK:STDOUT:   %.loc21_3.3.array.index = getelementptr inbounds [4 x i32], ptr %self, i32 0, i64 1, !dbg !66
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc21_3.3.array.index), !dbg !66
// CHECK:STDOUT:   %.loc21_3.4.array.index = getelementptr inbounds [4 x i32], ptr %self, i32 0, i64 0, !dbg !66
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc21_3.4.array.index), !dbg !66
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.88cc3346b7991af5:core.Destroy.Core"(ptr %self) #0 !dbg !68 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.88cc3346b7991af5:core.Destroy.Core"(ptr %self), !dbg !70
// CHECK:STDOUT:   ret void, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CG.Main(ptr %s, i64 %i) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.call = call ptr @"_CRef.Slice.a081b942542726db.Core:IndirectIndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f"(ptr %s, i64 %i), !dbg !79
// CHECK:STDOUT:   %.loc27 = load i32, ptr %Slice.as.IndirectIndexWith.impl.Ref.call, align 4, !dbg !79
// CHECK:STDOUT:   ret i32 %.loc27, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CFromArray.Slice.Core.751a3c1d2a013038(ptr sret({ ptr, i64 }) %return, ptr %p) #0 !dbg !85 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !92
// CHECK:STDOUT:   store ptr %p, ptr %ptr, align 8, !dbg !92
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !92
// CHECK:STDOUT:   store i64 4, ptr %size, align 8, !dbg !92
// CHECK:STDOUT:   ret void, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CRef.Slice.a081b942542726db.Core:IndirectIndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f"(ptr %self, i64 %subscript) #0 !dbg !95 {
// CHECK:STDOUT:   %1 = icmp slt i64 %subscript, 0, !dbg !102
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !102
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !102
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %4 = call i64 @_CSize.Slice.Core.4d9f279dbc2b9f6f(ptr %self), !dbg !104
// CHECK:STDOUT:   %5 = icmp sge i64 %subscript, %4, !dbg !103
// CHECK:STDOUT:   br label %6, !dbg !102
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !107
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !108
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !108
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !108
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !108
// CHECK:STDOUT:   call void @abort(), !dbg !108
// CHECK:STDOUT:   br label %10, !dbg !109
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %11 = call ptr @_CData.Slice.Core.4d9f279dbc2b9f6f(ptr %self), !dbg !110
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %subscript, !dbg !112
// CHECK:STDOUT:   ret ptr %ptr.offset, !dbg !114
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSize.Slice.Core.4d9f279dbc2b9f6f(ptr %self) #0 !dbg !116 {
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !121
// CHECK:STDOUT:   %1 = load i64, ptr %size, align 8, !dbg !121
// CHECK:STDOUT:   ret i64 %1, !dbg !122
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CData.Slice.Core.4d9f279dbc2b9f6f(ptr %self) #0 !dbg !124 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !129
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !129
// CHECK:STDOUT:   ret ptr %1, !dbg !130
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CRef.Slice.a081b942542726db.Core:IndirectIndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f", { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { noreturn }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "basic.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !13 = !{null, !12}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !7}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = !{!6, !12, !7}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 20, type: !9, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !22 = !DILocation(line: 21, column: 3, scope: !19)
// CHECK:STDOUT: !23 = !DILocation(line: 21, column: 26, scope: !19)
// CHECK:STDOUT: !27 = !DILocation(line: 22, column: 28, scope: !19)
// CHECK:STDOUT: !28 = !{!12, !12}
// CHECK:STDOUT: !29 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !32 = !DILocation(line: 23, column: 10, scope: !19)
// CHECK:STDOUT: !33 = !{!12, !12, !7}
// CHECK:STDOUT: !34 = !DISubroutineType(types: !33)
// CHECK:STDOUT: !35 = !DILocation(line: 23, column: 3, scope: !19)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 22, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !39)
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !36, type: !6)
// CHECK:STDOUT: !38 = !DILocation(line: 22, column: 10, scope: !36)
// CHECK:STDOUT: !39 = !{!37}
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !43)
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !40, type: !12)
// CHECK:STDOUT: !42 = !DILocation(line: 22, column: 28, scope: !40)
// CHECK:STDOUT: !43 = !{!41}
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 22, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !47)
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !44, type: !7)
// CHECK:STDOUT: !46 = !DILocation(line: 22, column: 28, scope: !44)
// CHECK:STDOUT: !47 = !{!45}
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !51)
// CHECK:STDOUT: !49 = !DILocalVariable(arg: 1, scope: !48, type: !12)
// CHECK:STDOUT: !50 = !DILocation(line: 22, column: 28, scope: !48)
// CHECK:STDOUT: !51 = !{!49}
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !55)
// CHECK:STDOUT: !53 = !DILocalVariable(arg: 1, scope: !52, type: !12)
// CHECK:STDOUT: !54 = !DILocation(line: 22, column: 28, scope: !52)
// CHECK:STDOUT: !55 = !{!53}
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !59)
// CHECK:STDOUT: !57 = !DILocalVariable(arg: 1, scope: !56, type: !12)
// CHECK:STDOUT: !58 = !DILocation(line: 22, column: 28, scope: !56)
// CHECK:STDOUT: !59 = !{!57}
// CHECK:STDOUT: !60 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !63)
// CHECK:STDOUT: !61 = !DILocalVariable(arg: 1, scope: !60, type: !12)
// CHECK:STDOUT: !62 = !DILocation(line: 22, column: 28, scope: !60)
// CHECK:STDOUT: !63 = !{!61}
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.88cc3346b7991af5:core.Destroy.Core", scope: null, file: !4, line: 21, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !67)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !12)
// CHECK:STDOUT: !66 = !DILocation(line: 21, column: 3, scope: !64)
// CHECK:STDOUT: !67 = !{!65}
// CHECK:STDOUT: !68 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.88cc3346b7991af5:core.Destroy.Core", scope: null, file: !4, line: 21, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !69 = !DILocalVariable(arg: 1, scope: !68, type: !12)
// CHECK:STDOUT: !70 = !DILocation(line: 21, column: 3, scope: !68)
// CHECK:STDOUT: !71 = !{!69}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !4, line: 26, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !82)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !12)
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 2, scope: !72, type: !7)
// CHECK:STDOUT: !79 = !DILocation(line: 27, column: 10, scope: !72)
// CHECK:STDOUT: !81 = !DILocation(line: 27, column: 3, scope: !72)
// CHECK:STDOUT: !82 = !{!73, !74}
// CHECK:STDOUT: !84 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "FromArray", linkageName: "_CFromArray.Slice.Core.751a3c1d2a013038", scope: null, file: !84, line: 26, type: !29, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !94)
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !85, type: !12)
// CHECK:STDOUT: !92 = !DILocation(line: 27, column: 12, scope: !85)
// CHECK:STDOUT: !93 = !DILocation(line: 27, column: 5, scope: !85)
// CHECK:STDOUT: !94 = !{!86}
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "Ref", linkageName: "_CRef.Slice.a081b942542726db.Core:IndirectIndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f", scope: null, file: !84, line: 76, type: !34, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !115)
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 1, scope: !95, type: !12)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 2, scope: !95, type: !7)
// CHECK:STDOUT: !102 = !DILocation(line: 77, column: 9, scope: !95)
// CHECK:STDOUT: !103 = !DILocation(line: 77, column: 26, scope: !95)
// CHECK:STDOUT: !104 = !DILocation(line: 77, column: 39, scope: !95)
// CHECK:STDOUT: !105 = !{!7, !12}
// CHECK:STDOUT: !106 = !DISubroutineType(types: !105)
// CHECK:STDOUT: !107 = !DILocation(line: 77, column: 8, scope: !95)
// CHECK:STDOUT: !108 = !DILocation(line: 78, column: 7, scope: !95)
// CHECK:STDOUT: !109 = !DILocation(line: 77, column: 5, scope: !95)
// CHECK:STDOUT: !110 = !DILocation(line: 80, column: 27, scope: !95)
// CHECK:STDOUT: !112 = !DILocation(line: 80, column: 13, scope: !95)
// CHECK:STDOUT: !114 = !DILocation(line: 80, column: 5, scope: !95)
// CHECK:STDOUT: !115 = !{!96, !97}
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "Size", linkageName: "_CSize.Slice.Core.4d9f279dbc2b9f6f", scope: null, file: !84, line: 34, type: !106, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !123)
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !116, type: !12)
// CHECK:STDOUT: !121 = !DILocation(line: 34, column: 33, scope: !116)
// CHECK:STDOUT: !122 = !DILocation(line: 34, column: 26, scope: !116)
// CHECK:STDOUT: !123 = !{!117}
// CHECK:STDOUT: !124 = distinct !DISubprogram(name: "Data", linkageName: "_CData.Slice.Core.4d9f279dbc2b9f6f", scope: null, file: !84, line: 37, type: !29, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !131)
// CHECK:STDOUT: !125 = !DILocalVariable(arg: 1, scope: !124, type: !12)
// CHECK:STDOUT: !129 = !DILocation(line: 37, column: 32, scope: !124)
// CHECK:STDOUT: !130 = !DILocation(line: 37, column: 25, scope: !124)
// CHECK:STDOUT: !131 = !{!125}
// CHECK:STDOUT:
