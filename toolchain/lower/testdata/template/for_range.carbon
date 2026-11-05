// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/template/for_range.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/template/for_range.carbon

// --- range_param_called_array.carbon
library "[[@TEST_NAME]]";

fn Sum[template T: type](a: T) -> i32 {
  var s: i32 = 0;
  for (x: i32 in a) {
    s += x;
  }
  return s;
}

fn Use(a: array(i32, 3)) -> i32 {
  return Sum(a);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'range_param_called_array.carbon'
// CHECK:STDOUT: source_filename = "range_param_called_array.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 57 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(ptr %a) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Sum.call = call i32 @_CSum.Main.d38040534c930e1d(ptr %a), !dbg !24
// CHECK:STDOUT:   ret i32 %Sum.call, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CSum.Main.d38040534c930e1d(ptr %a) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %s.var = alloca i32, align 4, !dbg !32
// CHECK:STDOUT:   %var = alloca i32, align 4, !dbg !36
// CHECK:STDOUT:   %.070.temp = alloca <{ i32, i1 }>, align 4, !dbg !36
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %s.var), !dbg !32
// CHECK:STDOUT:   store i32 0, ptr %s.var, align 4, !dbg !32
// CHECK:STDOUT:   %array_type.as.Iterate.impl.NewCursor.call = call i32 @"_CNewCursor.e163a239f9fa927c:Iterate.Core.0f51c0c98f624e62"(ptr %a), !dbg !36
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %var), !dbg !36
// CHECK:STDOUT:   store i32 %array_type.as.Iterate.impl.NewCursor.call, ptr %var, align 4, !dbg !36
// CHECK:STDOUT:   br label %for.next, !dbg !36
// CHECK:STDOUT:
// CHECK:STDOUT: for.next:                                         ; preds = %for.body, %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.070.temp), !dbg !36
// CHECK:STDOUT:   call void @"_CNext.e163a239f9fa927c:Iterate.Core.0f51c0c98f624e62"(ptr %.070.temp, ptr %a, ptr %var), !dbg !36
// CHECK:STDOUT:   %Optional.HasValue.call = call i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %.070.temp), !dbg !36
// CHECK:STDOUT:   br i1 %Optional.HasValue.call, label %for.body, label %for.done, !dbg !36
// CHECK:STDOUT:
// CHECK:STDOUT: for.body:                                         ; preds = %for.next
// CHECK:STDOUT:   %Optional.Get.call = call i32 @_CGet.Optional.Core.fc4496a6c25d418b(ptr %.070.temp), !dbg !36
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.call = load i32, ptr %s.var, align 4, !dbg !41
// CHECK:STDOUT:   %Int.as.AddAssignWith.impl.Op.call1 = add i32 %Int.as.AddAssignWith.impl.Op.call, %Optional.Get.call, !dbg !41
// CHECK:STDOUT:   store i32 %Int.as.AddAssignWith.impl.Op.call1, ptr %s.var, align 4, !dbg !41
// CHECK:STDOUT:   br label %for.next, !dbg !43
// CHECK:STDOUT:
// CHECK:STDOUT: for.done:                                         ; preds = %for.next
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %var), !dbg !36
// CHECK:STDOUT:   %.loc8 = load i32, ptr %s.var, align 4, !dbg !44
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %s.var), !dbg !32
// CHECK:STDOUT:   ret i32 %.loc8, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CNewCursor.e163a239f9fa927c:Iterate.Core.0f51c0c98f624e62"(ptr %self) #0 !dbg !51 {
// CHECK:STDOUT:   ret i32 0, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNext.e163a239f9fa927c:Iterate.Core.0f51c0c98f624e62"(ptr sret(<{ i32, i1 }>) %return, ptr %self, ptr %cursor) #0 !dbg !58 {
// CHECK:STDOUT:   %1 = load i32, ptr %cursor, align 4, !dbg !65
// CHECK:STDOUT:   %2 = icmp slt i32 %1, 3, !dbg !65
// CHECK:STDOUT:   br i1 %2, label %3, label %7, !dbg !66
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   call void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8"(ptr %cursor), !dbg !68
// CHECK:STDOUT:   %4 = load i32, ptr %cursor, align 4, !dbg !70
// CHECK:STDOUT:   %5 = sub i32 %4, 1, !dbg !70
// CHECK:STDOUT:   %array.index = getelementptr inbounds [3 x i32], ptr %self, i32 0, i32 %5, !dbg !69
// CHECK:STDOUT:   %6 = load i32, ptr %array.index, align 4, !dbg !69
// CHECK:STDOUT:   call void @_CSome.Optional.Core.fc4496a6c25d418b(ptr %return, i32 %6), !dbg !71
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %0
// CHECK:STDOUT:   call void @_CNone.Optional.Core.fc4496a6c25d418b(ptr %return), !dbg !75
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %self) #0 !dbg !83 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !89
// CHECK:STDOUT:   ret i1 %1, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Optional.Core.fc4496a6c25d418b(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %self), !dbg !97
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !98
// CHECK:STDOUT:   br i1 %2, label %3, label %5, !dbg !99
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !100
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !100
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !100
// CHECK:STDOUT:   %4 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !100
// CHECK:STDOUT:   call void @abort(), !dbg !100
// CHECK:STDOUT:   br label %5, !dbg !101
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3, %0
// CHECK:STDOUT:   %6 = call i32 @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !103
// CHECK:STDOUT:   ret i32 %6, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8"(ptr %self) #0 !dbg !107 {
// CHECK:STDOUT:   call void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895"(ptr %self, i32 1), !dbg !110
// CHECK:STDOUT:   ret void, !dbg !113
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Core.fc4496a6c25d418b(ptr sret(<{ i32, i1 }>) %return, i32 %value) #0 !dbg !115 {
// CHECK:STDOUT:   call void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %return, i32 %value), !dbg !120
// CHECK:STDOUT:   ret void, !dbg !121
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CNone.Optional.Core.fc4496a6c25d418b(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !123 {
// CHECK:STDOUT:   call void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %return), !dbg !126
// CHECK:STDOUT:   ret void, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %value) #0 !dbg !128 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 1, !dbg !133
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !133
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !133
// CHECK:STDOUT:   ret i1 %2, !dbg !134
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %value) #0 !dbg !136 {
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 0, !dbg !141
// CHECK:STDOUT:   %1 = load i32, ptr %value1, align 4, !dbg !141
// CHECK:STDOUT:   ret i32 %1, !dbg !142
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895"(ptr %self, i32 %other) #3 !dbg !144 {
// CHECK:STDOUT:   %1 = call i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %other), !dbg !147
// CHECK:STDOUT:   %2 = load i32, ptr %self, align 4, !dbg !148
// CHECK:STDOUT:   %3 = add i32 %2, %1, !dbg !148
// CHECK:STDOUT:   store i32 %3, ptr %self, align 4, !dbg !148
// CHECK:STDOUT:   ret void, !dbg !148
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !152 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 0, !dbg !161
// CHECK:STDOUT:   store i32 %self, ptr %value, align 4, !dbg !161
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !163
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !163
// CHECK:STDOUT:   ret void, !dbg !164
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !166 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !173
// CHECK:STDOUT:   store i8 0, ptr %has_value, align 1, !dbg !173
// CHECK:STDOUT:   ret void, !dbg !174
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %self) #0 !dbg !175 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !180
// CHECK:STDOUT:   ret i32 %1, !dbg !182
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !184 {
// CHECK:STDOUT:   ret i32 %self, !dbg !190
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { noreturn }
// CHECK:STDOUT: attributes #3 = { alwaysinline nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "range_param_called_array.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!6, !9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 4, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !17)
// CHECK:STDOUT: !15 = !DILocalVariable(arg: 1, scope: !14, type: !6)
// CHECK:STDOUT: !16 = !DILocation(line: 4, column: 3, scope: !14)
// CHECK:STDOUT: !17 = !{!15}
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 11, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !26)
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !18, type: !9)
// CHECK:STDOUT: !24 = !DILocation(line: 12, column: 10, scope: !18)
// CHECK:STDOUT: !25 = !DILocation(line: 12, column: 3, scope: !18)
// CHECK:STDOUT: !26 = !{!19}
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "Sum", linkageName: "_CSum.Main.d38040534c930e1d", scope: null, file: !4, line: 3, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !28 = !DILocalVariable(arg: 1, scope: !27, type: !9)
// CHECK:STDOUT: !32 = !DILocation(line: 4, column: 3, scope: !27)
// CHECK:STDOUT: !36 = !DILocation(line: 5, column: 7, scope: !27)
// CHECK:STDOUT: !37 = !{!9, !9, !6}
// CHECK:STDOUT: !38 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !39 = !{!9, !9}
// CHECK:STDOUT: !40 = !DISubroutineType(types: !39)
// CHECK:STDOUT: !41 = !DILocation(line: 6, column: 5, scope: !27)
// CHECK:STDOUT: !43 = !DILocation(line: 5, column: 3, scope: !27)
// CHECK:STDOUT: !44 = !DILocation(line: 8, column: 10, scope: !27)
// CHECK:STDOUT: !45 = !DILocation(line: 8, column: 3, scope: !27)
// CHECK:STDOUT: !46 = !{!28}
// CHECK:STDOUT: !50 = !DIFile(filename: "{{.*}}/prelude/iterate.carbon", directory: "")
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "NewCursor", linkageName: "_CNewCursor.e163a239f9fa927c:Iterate.Core.0f51c0c98f624e62", scope: null, file: !50, line: 23, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !9)
// CHECK:STDOUT: !56 = !DILocation(line: 23, column: 38, scope: !51)
// CHECK:STDOUT: !57 = !{!52}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Next", linkageName: "_CNext.e163a239f9fa927c:Iterate.Core.0f51c0c98f624e62", scope: null, file: !50, line: 24, type: !38, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !79)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !9)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 2, scope: !58, type: !6)
// CHECK:STDOUT: !65 = !DILocation(line: 25, column: 9, scope: !58)
// CHECK:STDOUT: !66 = !DILocation(line: 25, column: 8, scope: !58)
// CHECK:STDOUT: !68 = !DILocation(line: 26, column: 7, scope: !58)
// CHECK:STDOUT: !69 = !DILocation(line: 27, column: 31, scope: !58)
// CHECK:STDOUT: !70 = !DILocation(line: 27, column: 36, scope: !58)
// CHECK:STDOUT: !71 = !DILocation(line: 27, column: 14, scope: !58)
// CHECK:STDOUT: !72 = !{!9, !6}
// CHECK:STDOUT: !73 = !DISubroutineType(types: !72)
// CHECK:STDOUT: !74 = !DILocation(line: 27, column: 7, scope: !58)
// CHECK:STDOUT: !75 = !DILocation(line: 29, column: 14, scope: !58)
// CHECK:STDOUT: !76 = !{!9}
// CHECK:STDOUT: !77 = !DISubroutineType(types: !76)
// CHECK:STDOUT: !78 = !DILocation(line: 29, column: 7, scope: !58)
// CHECK:STDOUT: !79 = !{!59, !60}
// CHECK:STDOUT: !82 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.fc4496a6c25d418b", scope: null, file: !82, line: 37, type: !40, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !91)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !9)
// CHECK:STDOUT: !89 = !DILocation(line: 38, column: 12, scope: !83)
// CHECK:STDOUT: !90 = !DILocation(line: 38, column: 5, scope: !83)
// CHECK:STDOUT: !91 = !{!84}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.fc4496a6c25d418b", scope: null, file: !82, line: 40, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !105)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !9)
// CHECK:STDOUT: !97 = !DILocation(line: 374, column: 11, scope: !92)
// CHECK:STDOUT: !98 = !DILocation(line: 374, column: 7, scope: !92)
// CHECK:STDOUT: !99 = !DILocation(line: 374, column: 6, scope: !92)
// CHECK:STDOUT: !100 = !DILocation(line: 375, column: 5, scope: !92)
// CHECK:STDOUT: !101 = !DILocation(line: 374, column: 3, scope: !92)
// CHECK:STDOUT: !103 = !DILocation(line: 377, column: 10, scope: !92)
// CHECK:STDOUT: !104 = !DILocation(line: 377, column: 3, scope: !92)
// CHECK:STDOUT: !105 = !{!93}
// CHECK:STDOUT: !106 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !107 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8", scope: null, file: !106, line: 396, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !114)
// CHECK:STDOUT: !108 = !DILocalVariable(arg: 1, scope: !107, type: !6)
// CHECK:STDOUT: !110 = !DILocation(line: 398, column: 5, scope: !107)
// CHECK:STDOUT: !111 = !{null, !6, !6}
// CHECK:STDOUT: !112 = !DISubroutineType(types: !111)
// CHECK:STDOUT: !113 = !DILocation(line: 396, column: 3, scope: !107)
// CHECK:STDOUT: !114 = !{!108}
// CHECK:STDOUT: !115 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.fc4496a6c25d418b", scope: null, file: !82, line: 34, type: !73, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !122)
// CHECK:STDOUT: !116 = !DILocalVariable(arg: 1, scope: !115, type: !6)
// CHECK:STDOUT: !120 = !DILocation(line: 35, column: 12, scope: !115)
// CHECK:STDOUT: !121 = !DILocation(line: 35, column: 5, scope: !115)
// CHECK:STDOUT: !122 = !{!116}
// CHECK:STDOUT: !123 = distinct !DISubprogram(name: "None", linkageName: "_CNone.Optional.Core.fc4496a6c25d418b", scope: null, file: !82, line: 31, type: !77, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !126 = !DILocation(line: 32, column: 12, scope: !123)
// CHECK:STDOUT: !127 = !DILocation(line: 32, column: 5, scope: !123)
// CHECK:STDOUT: !128 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !82, line: 166, type: !40, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !135)
// CHECK:STDOUT: !129 = !DILocalVariable(arg: 1, scope: !128, type: !9)
// CHECK:STDOUT: !133 = !DILocation(line: 167, column: 12, scope: !128)
// CHECK:STDOUT: !134 = !DILocation(line: 167, column: 5, scope: !128)
// CHECK:STDOUT: !135 = !{!129}
// CHECK:STDOUT: !136 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !82, line: 169, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !143)
// CHECK:STDOUT: !137 = !DILocalVariable(arg: 1, scope: !136, type: !9)
// CHECK:STDOUT: !141 = !DILocation(line: 170, column: 12, scope: !136)
// CHECK:STDOUT: !142 = !DILocation(line: 170, column: 5, scope: !136)
// CHECK:STDOUT: !143 = !{!137}
// CHECK:STDOUT: !144 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895", scope: null, file: !106, line: 331, type: !112, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !151)
// CHECK:STDOUT: !145 = !DILocalVariable(arg: 1, scope: !144, type: !6)
// CHECK:STDOUT: !146 = !DILocalVariable(arg: 2, scope: !144, type: !6)
// CHECK:STDOUT: !147 = !DILocation(line: 0, scope: !144)
// CHECK:STDOUT: !148 = !DILocation(line: 331, column: 3, scope: !144)
// CHECK:STDOUT: !149 = !{!6, !6}
// CHECK:STDOUT: !150 = !DISubroutineType(types: !149)
// CHECK:STDOUT: !151 = !{!145, !146}
// CHECK:STDOUT: !152 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !82, line: 156, type: !73, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !165)
// CHECK:STDOUT: !153 = !DILocalVariable(arg: 1, scope: !152, type: !6)
// CHECK:STDOUT: !161 = !DILocation(line: 162, column: 5, scope: !152)
// CHECK:STDOUT: !163 = !DILocation(line: 163, column: 5, scope: !152)
// CHECK:STDOUT: !164 = !DILocation(line: 164, column: 5, scope: !152)
// CHECK:STDOUT: !165 = !{!153}
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "None", linkageName: "_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !82, line: 150, type: !77, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !173 = !DILocation(line: 153, column: 5, scope: !166)
// CHECK:STDOUT: !174 = !DILocation(line: 154, column: 5, scope: !166)
// CHECK:STDOUT: !175 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044", scope: null, file: !106, line: 64, type: !150, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !183)
// CHECK:STDOUT: !176 = !DILocalVariable(arg: 1, scope: !175, type: !6)
// CHECK:STDOUT: !180 = !DILocation(line: 66, column: 17, scope: !175)
// CHECK:STDOUT: !182 = !DILocation(line: 66, column: 5, scope: !175)
// CHECK:STDOUT: !183 = !{!176}
// CHECK:STDOUT: !184 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !106, line: 59, type: !150, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !191)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 1, scope: !184, type: !6)
// CHECK:STDOUT: !190 = !DILocation(line: 59, column: 28, scope: !184)
// CHECK:STDOUT: !191 = !{!185}
// CHECK:STDOUT:
