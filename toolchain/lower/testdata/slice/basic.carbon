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
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.call = call i32 @"_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f"(ptr %.loc22_56.3.temp, i64 1), !dbg !32
// CHECK:STDOUT:   call void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %.loc22_56.3.temp), !dbg !27
// CHECK:STDOUT:   call void @"_CSelfDestruct.88cc3346b7991af5:core.Destroy.Core"(ptr %a.var), !dbg !22
// CHECK:STDOUT:   ret i32 %Slice.as.IndexWith.impl.At.call, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !44
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc22_56.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !48
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc22_56.1.size), !dbg !48
// CHECK:STDOUT:   %.loc22_56.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !48
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.loc22_56.2.ptr), !dbg !48
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core"(ptr %self), !dbg !52
// CHECK:STDOUT:   ret void, !dbg !52
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !54 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc22_56.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !56
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc22_56.1.size), !dbg !56
// CHECK:STDOUT:   %.loc22_56.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !56
// CHECK:STDOUT:   call void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %.loc22_56.2.ptr), !dbg !56
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core"(ptr %self), !dbg !60
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.88cc3346b7991af5:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_3.1.array.index = getelementptr inbounds [4 x i32], ptr %self, i32 0, i64 3, !dbg !64
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc21_3.1.array.index), !dbg !64
// CHECK:STDOUT:   %.loc21_3.2.array.index = getelementptr inbounds [4 x i32], ptr %self, i32 0, i64 2, !dbg !64
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc21_3.2.array.index), !dbg !64
// CHECK:STDOUT:   %.loc21_3.3.array.index = getelementptr inbounds [4 x i32], ptr %self, i32 0, i64 1, !dbg !64
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc21_3.3.array.index), !dbg !64
// CHECK:STDOUT:   %.loc21_3.4.array.index = getelementptr inbounds [4 x i32], ptr %self, i32 0, i64 0, !dbg !64
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc21_3.4.array.index), !dbg !64
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.88cc3346b7991af5:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.88cc3346b7991af5:core.Destroy.Core"(ptr %self), !dbg !68
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CG.Main(ptr %s, i64 %i) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.call = call i32 @"_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f"(ptr %s, i64 %i), !dbg !77
// CHECK:STDOUT:   ret i32 %Slice.as.IndexWith.impl.At.call, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CFromArray.Slice.Core.751a3c1d2a013038(ptr sret({ ptr, i64 }) %return, ptr %p) #0 !dbg !83 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   store ptr %p, ptr %ptr, align 8, !dbg !90
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !90
// CHECK:STDOUT:   store i64 4, ptr %size, align 8, !dbg !90
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f"(ptr %self, i64 %subscript) #0 !dbg !93 {
// CHECK:STDOUT:   %1 = call i32 @_CGet.Slice.Core.4d9f279dbc2b9f6f(ptr %self, i64 %subscript), !dbg !100
// CHECK:STDOUT:   ret i32 %1, !dbg !102
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Slice.Core.4d9f279dbc2b9f6f(ptr %self, i64 %i) #0 !dbg !104 {
// CHECK:STDOUT:   %1 = icmp slt i64 %i, 0, !dbg !111
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !111
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !111
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !113
// CHECK:STDOUT:   %4 = load i64, ptr %size, align 8, !dbg !113
// CHECK:STDOUT:   %5 = icmp sge i64 %i, %4, !dbg !112
// CHECK:STDOUT:   br label %6, !dbg !111
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !114
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !115
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !115
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !115
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !115
// CHECK:STDOUT:   call void @abort(), !dbg !115
// CHECK:STDOUT:   br label %10, !dbg !116
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !117
// CHECK:STDOUT:   %11 = load ptr, ptr %ptr, align 8, !dbg !117
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %i, !dbg !119
// CHECK:STDOUT:   %12 = load i32, ptr %ptr.offset, align 4, !dbg !120
// CHECK:STDOUT:   ret i32 %12, !dbg !121
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f", { 1, 0 }
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
// CHECK:STDOUT: !33 = !DILocation(line: 23, column: 3, scope: !19)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 22, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !34, type: !6)
// CHECK:STDOUT: !36 = !DILocation(line: 22, column: 10, scope: !34)
// CHECK:STDOUT: !37 = !{!35}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !12)
// CHECK:STDOUT: !40 = !DILocation(line: 22, column: 28, scope: !38)
// CHECK:STDOUT: !41 = !{!39}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 22, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !7)
// CHECK:STDOUT: !44 = !DILocation(line: 22, column: 28, scope: !42)
// CHECK:STDOUT: !45 = !{!43}
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !12)
// CHECK:STDOUT: !48 = !DILocation(line: 22, column: 28, scope: !46)
// CHECK:STDOUT: !49 = !{!47}
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0cc0bac3871fce6b:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !53)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !12)
// CHECK:STDOUT: !52 = !DILocation(line: 22, column: 28, scope: !50)
// CHECK:STDOUT: !53 = !{!51}
// CHECK:STDOUT: !54 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 1, scope: !54, type: !12)
// CHECK:STDOUT: !56 = !DILocation(line: 22, column: 28, scope: !54)
// CHECK:STDOUT: !57 = !{!55}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.079d89ca1000ddb5:core.Destroy.Core", scope: null, file: !4, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !61)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !12)
// CHECK:STDOUT: !60 = !DILocation(line: 22, column: 28, scope: !58)
// CHECK:STDOUT: !61 = !{!59}
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.88cc3346b7991af5:core.Destroy.Core", scope: null, file: !4, line: 21, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !65)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !62, type: !12)
// CHECK:STDOUT: !64 = !DILocation(line: 21, column: 3, scope: !62)
// CHECK:STDOUT: !65 = !{!63}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.88cc3346b7991af5:core.Destroy.Core", scope: null, file: !4, line: 21, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !12)
// CHECK:STDOUT: !68 = !DILocation(line: 21, column: 3, scope: !66)
// CHECK:STDOUT: !69 = !{!67}
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !4, line: 26, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !80)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !12)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 2, scope: !70, type: !7)
// CHECK:STDOUT: !77 = !DILocation(line: 27, column: 10, scope: !70)
// CHECK:STDOUT: !79 = !DILocation(line: 27, column: 3, scope: !70)
// CHECK:STDOUT: !80 = !{!71, !72}
// CHECK:STDOUT: !82 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "FromArray", linkageName: "_CFromArray.Slice.Core.751a3c1d2a013038", scope: null, file: !82, line: 26, type: !29, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !92)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !12)
// CHECK:STDOUT: !90 = !DILocation(line: 27, column: 12, scope: !83)
// CHECK:STDOUT: !91 = !DILocation(line: 27, column: 5, scope: !83)
// CHECK:STDOUT: !92 = !{!84}
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "At", linkageName: "_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.4d9f279dbc2b9f6f", scope: null, file: !82, line: 76, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !103)
// CHECK:STDOUT: !94 = !DILocalVariable(arg: 1, scope: !93, type: !12)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 2, scope: !93, type: !7)
// CHECK:STDOUT: !100 = !DILocation(line: 76, column: 45, scope: !93)
// CHECK:STDOUT: !102 = !DILocation(line: 76, column: 38, scope: !93)
// CHECK:STDOUT: !103 = !{!94, !95}
// CHECK:STDOUT: !104 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Slice.Core.4d9f279dbc2b9f6f", scope: null, file: !82, line: 39, type: !18, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !122)
// CHECK:STDOUT: !105 = !DILocalVariable(arg: 1, scope: !104, type: !12)
// CHECK:STDOUT: !106 = !DILocalVariable(arg: 2, scope: !104, type: !7)
// CHECK:STDOUT: !111 = !DILocation(line: 40, column: 9, scope: !104)
// CHECK:STDOUT: !112 = !DILocation(line: 40, column: 18, scope: !104)
// CHECK:STDOUT: !113 = !DILocation(line: 40, column: 23, scope: !104)
// CHECK:STDOUT: !114 = !DILocation(line: 40, column: 8, scope: !104)
// CHECK:STDOUT: !115 = !DILocation(line: 41, column: 7, scope: !104)
// CHECK:STDOUT: !116 = !DILocation(line: 40, column: 5, scope: !104)
// CHECK:STDOUT: !117 = !DILocation(line: 43, column: 27, scope: !104)
// CHECK:STDOUT: !119 = !DILocation(line: 43, column: 13, scope: !104)
// CHECK:STDOUT: !120 = !DILocation(line: 43, column: 12, scope: !104)
// CHECK:STDOUT: !121 = !DILocation(line: 43, column: 5, scope: !104)
// CHECK:STDOUT: !122 = !{!105, !106}
// CHECK:STDOUT:
