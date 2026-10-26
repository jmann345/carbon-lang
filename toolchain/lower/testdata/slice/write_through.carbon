// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/slice/write_through.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/slice/write_through.carbon

fn Write(s: Core.Slice(i32), i: i64) {
  s[i] = 5;
}

fn Read(s: Core.Slice(i32)) -> i32 {
  return s[1];
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'write_through.carbon'
// CHECK:STDOUT: source_filename = "write_through.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [53 x i8] c"carbon: Core.Slice index out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @1 = private unnamed_addr constant [62 x i8] c"carbon: Core.Slice.Subslice range out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 52 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CWrite.Main(ptr %s, i64 %i) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.call = call ptr @"_CRef.Slice.b1aeb9ebf60f2c6e.Core:IndirectIndexWith.f249b435619a5146.Core.d4057e3ae48c02cc"(ptr %s, i64 %i), !dbg !24
// CHECK:STDOUT:   store i32 5, ptr %Slice.as.IndirectIndexWith.impl.Ref.call, align 4, !dbg !24
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRead.Main(ptr %s) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Slice.as.IndirectIndexWith.impl.Ref.call = call ptr @"_CRef.Slice.b1aeb9ebf60f2c6e.Core:IndirectIndexWith.f249b435619a5146.Core.d4057e3ae48c02cc"(ptr %s, i64 1), !dbg !35
// CHECK:STDOUT:   %.loc18_13 = load i32, ptr %Slice.as.IndirectIndexWith.impl.Ref.call, align 4, !dbg !35
// CHECK:STDOUT:   ret i32 %.loc18_13, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CRef.Slice.b1aeb9ebf60f2c6e.Core:IndirectIndexWith.f249b435619a5146.Core.d4057e3ae48c02cc"(ptr %self, i64 %subscript) #0 !dbg !40 {
// CHECK:STDOUT:   %1 = icmp slt i64 %subscript, 0, !dbg !47
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !47
// CHECK:STDOUT:   br i1 %2, label %3, label %6, !dbg !47
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %4 = call i64 @_CSize.Slice.Core.d4057e3ae48c02cc(ptr %self), !dbg !49
// CHECK:STDOUT:   %5 = icmp sge i64 %subscript, %4, !dbg !48
// CHECK:STDOUT:   br label %6, !dbg !47
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %3, %0
// CHECK:STDOUT:   %7 = phi i1 [ true, %0 ], [ %5, %3 ]
// CHECK:STDOUT:   br i1 %7, label %8, label %10, !dbg !52
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %6
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !53
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !53
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !53
// CHECK:STDOUT:   %9 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !53
// CHECK:STDOUT:   call void @abort(), !dbg !53
// CHECK:STDOUT:   br label %10, !dbg !54
// CHECK:STDOUT:
// CHECK:STDOUT: 10:                                               ; preds = %8, %6
// CHECK:STDOUT:   %11 = call ptr @_CData.Slice.Core.d4057e3ae48c02cc(ptr %self), !dbg !55
// CHECK:STDOUT:   %ptr.offset = getelementptr inbounds i32, ptr %11, i64 %subscript, !dbg !59
// CHECK:STDOUT:   ret ptr %ptr.offset, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSize.Slice.Core.d4057e3ae48c02cc(ptr %self) #0 !dbg !63 {
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !68
// CHECK:STDOUT:   %1 = load i64, ptr %size, align 8, !dbg !68
// CHECK:STDOUT:   ret i64 %1, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CData.Slice.Core.d4057e3ae48c02cc(ptr %self) #0 !dbg !71 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !76
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !76
// CHECK:STDOUT:   ret ptr %1, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CRef.Slice.b1aeb9ebf60f2c6e.Core:IndirectIndexWith.f249b435619a5146.Core.d4057e3ae48c02cc", { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { noreturn }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "write_through.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{null, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !11 = !{null, !10, !7}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{!6, !10}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 13, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !18)
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !15, type: !6)
// CHECK:STDOUT: !17 = !DILocation(line: 13, column: 13, scope: !15)
// CHECK:STDOUT: !18 = !{!16}
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "Write", linkageName: "_CWrite.Main", scope: null, file: !4, line: 13, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !29)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !10)
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 2, scope: !19, type: !7)
// CHECK:STDOUT: !24 = !DILocation(line: 14, column: 3, scope: !19)
// CHECK:STDOUT: !26 = !{!10, !10, !7}
// CHECK:STDOUT: !27 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !28 = !DILocation(line: 13, column: 1, scope: !19)
// CHECK:STDOUT: !29 = !{!20, !21}
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "Read", linkageName: "_CRead.Main", scope: null, file: !4, line: 17, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !30, type: !10)
// CHECK:STDOUT: !35 = !DILocation(line: 18, column: 10, scope: !30)
// CHECK:STDOUT: !36 = !DILocation(line: 18, column: 3, scope: !30)
// CHECK:STDOUT: !37 = !{!31}
// CHECK:STDOUT: !39 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Ref", linkageName: "_CRef.Slice.b1aeb9ebf60f2c6e.Core:IndirectIndexWith.f249b435619a5146.Core.d4057e3ae48c02cc", scope: null, file: !39, line: 76, type: !27, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !62)
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !40, type: !10)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 2, scope: !40, type: !7)
// CHECK:STDOUT: !47 = !DILocation(line: 77, column: 9, scope: !40)
// CHECK:STDOUT: !48 = !DILocation(line: 77, column: 26, scope: !40)
// CHECK:STDOUT: !49 = !DILocation(line: 77, column: 39, scope: !40)
// CHECK:STDOUT: !50 = !{!7, !10}
// CHECK:STDOUT: !51 = !DISubroutineType(types: !50)
// CHECK:STDOUT: !52 = !DILocation(line: 77, column: 8, scope: !40)
// CHECK:STDOUT: !53 = !DILocation(line: 78, column: 7, scope: !40)
// CHECK:STDOUT: !54 = !DILocation(line: 77, column: 5, scope: !40)
// CHECK:STDOUT: !55 = !DILocation(line: 80, column: 27, scope: !40)
// CHECK:STDOUT: !56 = !{!10, !10}
// CHECK:STDOUT: !57 = !DISubroutineType(types: !56)
// CHECK:STDOUT: !59 = !DILocation(line: 80, column: 13, scope: !40)
// CHECK:STDOUT: !61 = !DILocation(line: 80, column: 5, scope: !40)
// CHECK:STDOUT: !62 = !{!41, !42}
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "Size", linkageName: "_CSize.Slice.Core.d4057e3ae48c02cc", scope: null, file: !39, line: 34, type: !51, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !70)
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !63, type: !10)
// CHECK:STDOUT: !68 = !DILocation(line: 34, column: 33, scope: !63)
// CHECK:STDOUT: !69 = !DILocation(line: 34, column: 26, scope: !63)
// CHECK:STDOUT: !70 = !{!64}
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "Data", linkageName: "_CData.Slice.Core.d4057e3ae48c02cc", scope: null, file: !39, line: 37, type: !57, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !78)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !71, type: !10)
// CHECK:STDOUT: !76 = !DILocation(line: 37, column: 32, scope: !71)
// CHECK:STDOUT: !77 = !DILocation(line: 37, column: 25, scope: !71)
// CHECK:STDOUT: !78 = !{!72}
// CHECK:STDOUT:
