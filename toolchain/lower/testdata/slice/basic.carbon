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
// CHECK:STDOUT: define i32 @_CF.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a.var = alloca [4 x i32], align 4, !dbg !8
// CHECK:STDOUT:   %.loc22_56.3.temp = alloca { ptr, i64 }, align 8, !dbg !9
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a.var), !dbg !8
// CHECK:STDOUT:   %.loc21_37.3.array.index = getelementptr inbounds [4 x i32], ptr %a.var, i32 0, i64 0, !dbg !10
// CHECK:STDOUT:   %.loc21_37.6.array.index = getelementptr inbounds [4 x i32], ptr %a.var, i32 0, i64 1, !dbg !10
// CHECK:STDOUT:   %.loc21_37.9.array.index = getelementptr inbounds [4 x i32], ptr %a.var, i32 0, i64 2, !dbg !10
// CHECK:STDOUT:   %.loc21_37.12.array.index = getelementptr inbounds [4 x i32], ptr %a.var, i32 0, i64 3, !dbg !10
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %a.var, ptr align 4 @array.loc21_3, i64 16, i1 false), !dbg !8
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc22_56.3.temp), !dbg !9
// CHECK:STDOUT:   call void @_CFromArray.Slice.Core.20136c51272e6f30(ptr %.loc22_56.3.temp, ptr %a.var), !dbg !9
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.call = call i32 @"_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.553a1f59d1dd8381"(ptr %.loc22_56.3.temp, i64 1), !dbg !11
// CHECK:STDOUT:   call void @"_COp.d227e7aede92ee9e:core.Destroy.Core"(ptr %.loc22_56.3.temp), !dbg !9
// CHECK:STDOUT:   call void @"_COp.eefa3f320d583a8d:core.Destroy.Core"(ptr %a.var), !dbg !8
// CHECK:STDOUT:   ret i32 %Slice.as.IndexWith.impl.At.call, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.600372e286a55e5e:core.Destroy.Core"(ptr %self) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.d227e7aede92ee9e:core.Destroy.Core"(ptr %self) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.eefa3f320d583a8d:core.Destroy.Core"(ptr %self) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CG.Main(ptr %s, i64 %i) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Slice.as.IndexWith.impl.At.call = call i32 @"_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.553a1f59d1dd8381"(ptr %s, i64 %i), !dbg !47
// CHECK:STDOUT:   ret i32 %Slice.as.IndexWith.impl.At.call, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CFromArray.Slice.Core.20136c51272e6f30(ptr sret({ ptr, i64 }) %return, ptr %p) #0 !dbg !49 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !55
// CHECK:STDOUT:   store ptr %p, ptr %ptr, align 8, !dbg !55
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !55
// CHECK:STDOUT:   store i64 4, ptr %size, align 8, !dbg !55
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.553a1f59d1dd8381"(ptr %self, i64 %subscript) #0 !dbg !57 {
// CHECK:STDOUT:   %1 = call i32 @_CGet.Slice.Core.553a1f59d1dd8381(ptr %self, i64 %subscript), !dbg !61
// CHECK:STDOUT:   ret i32 %1, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Slice.Core.553a1f59d1dd8381(ptr %self, i64 %i) #0 !dbg !63 {
// CHECK:STDOUT:   %1 = icmp slt i64 %i, 0, !dbg !67
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !67
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !67
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !68
// CHECK:STDOUT:   %4 = load i64, ptr %size, align 8, !dbg !68
// CHECK:STDOUT:   %5 = icmp sge i64 %i, %4, !dbg !69
// CHECK:STDOUT:   br label %6, !dbg !67
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !70
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !71
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !71
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !71
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !71
// CHECK:STDOUT:   call void @abort(), !dbg !71
// CHECK:STDOUT:   br label %10, !dbg !72
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !73
// CHECK:STDOUT:   %11 = load ptr, ptr %ptr, align 8, !dbg !73
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %i, !dbg !74
// CHECK:STDOUT:   %12 = load i32, ptr %ptr.offset, align 4, !dbg !75
// CHECK:STDOUT:   ret i32 %12, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.553a1f59d1dd8381", { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { noreturn }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "basic.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !1, line: 20, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 21, column: 3, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 22, column: 28, scope: !4)
// CHECK:STDOUT: !10 = !DILocation(line: 21, column: 26, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 23, column: 10, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 23, column: 3, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 22, type: !14, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !14 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !15 = !{null, !7}
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !13, type: !7)
// CHECK:STDOUT: !18 = !DILocation(line: 22, column: 10, scope: !13)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 22, type: !20, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
// CHECK:STDOUT: !20 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !21 = !{null, !22}
// CHECK:STDOUT: !22 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !23 = !{!24}
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !19, type: !22)
// CHECK:STDOUT: !25 = !DILocation(line: 22, column: 28, scope: !19)
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "Op", linkageName: "_COp.600372e286a55e5e:core.Destroy.Core", scope: null, file: !1, line: 22, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !30)
// CHECK:STDOUT: !27 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !28 = !{null, !29}
// CHECK:STDOUT: !29 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !30 = !{!31}
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !26, type: !29)
// CHECK:STDOUT: !32 = !DILocation(line: 22, column: 28, scope: !26)
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "Op", linkageName: "_COp.d227e7aede92ee9e:core.Destroy.Core", scope: null, file: !1, line: 22, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !34)
// CHECK:STDOUT: !34 = !{!35}
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !33, type: !29)
// CHECK:STDOUT: !36 = !DILocation(line: 22, column: 28, scope: !33)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "Op", linkageName: "_COp.eefa3f320d583a8d:core.Destroy.Core", scope: null, file: !1, line: 21, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !38)
// CHECK:STDOUT: !38 = !{!39}
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !37, type: !29)
// CHECK:STDOUT: !40 = !DILocation(line: 21, column: 3, scope: !37)
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !1, line: 26, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DISubroutineType(types: !43)
// CHECK:STDOUT: !43 = !{!7, !29, !22}
// CHECK:STDOUT: !44 = !{!45, !46}
// CHECK:STDOUT: !45 = !DILocalVariable(arg: 1, scope: !41, type: !29)
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 2, scope: !41, type: !22)
// CHECK:STDOUT: !47 = !DILocation(line: 27, column: 10, scope: !41)
// CHECK:STDOUT: !48 = !DILocation(line: 27, column: 3, scope: !41)
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "FromArray", linkageName: "_CFromArray.Slice.Core.20136c51272e6f30", scope: null, file: !50, line: 26, type: !51, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !50 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !51 = !DISubroutineType(types: !52)
// CHECK:STDOUT: !52 = !{!29, !29}
// CHECK:STDOUT: !53 = !{!54}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !49, type: !29)
// CHECK:STDOUT: !55 = !DILocation(line: 27, column: 12, scope: !49)
// CHECK:STDOUT: !56 = !DILocation(line: 27, column: 5, scope: !49)
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "At", linkageName: "_CAt.Slice.a081b942542726db.Core:IndexWith.f249b435619a5146.Core.553a1f59d1dd8381", scope: null, file: !50, line: 76, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !58)
// CHECK:STDOUT: !58 = !{!59, !60}
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !57, type: !29)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 2, scope: !57, type: !22)
// CHECK:STDOUT: !61 = !DILocation(line: 76, column: 45, scope: !57)
// CHECK:STDOUT: !62 = !DILocation(line: 76, column: 38, scope: !57)
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Slice.Core.553a1f59d1dd8381", scope: null, file: !50, line: 39, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !64)
// CHECK:STDOUT: !64 = !{!65, !66}
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !63, type: !29)
// CHECK:STDOUT: !66 = !DILocalVariable(arg: 2, scope: !63, type: !22)
// CHECK:STDOUT: !67 = !DILocation(line: 40, column: 9, scope: !63)
// CHECK:STDOUT: !68 = !DILocation(line: 40, column: 23, scope: !63)
// CHECK:STDOUT: !69 = !DILocation(line: 40, column: 18, scope: !63)
// CHECK:STDOUT: !70 = !DILocation(line: 40, column: 8, scope: !63)
// CHECK:STDOUT: !71 = !DILocation(line: 41, column: 7, scope: !63)
// CHECK:STDOUT: !72 = !DILocation(line: 40, column: 5, scope: !63)
// CHECK:STDOUT: !73 = !DILocation(line: 43, column: 27, scope: !63)
// CHECK:STDOUT: !74 = !DILocation(line: 43, column: 13, scope: !63)
// CHECK:STDOUT: !75 = !DILocation(line: 43, column: 12, scope: !63)
// CHECK:STDOUT: !76 = !DILocation(line: 43, column: 5, scope: !63)
// CHECK:STDOUT:
