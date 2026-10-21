// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/array/iterate.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/array/iterate.carbon

fn G(n: i32);

fn F() {
  let a: array(i32, 6) = (1, 2, 3, 4, 5, 6);
  for (n: i32 in a) {
    G(n);
  }
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'iterate.carbon'
// CHECK:STDOUT: source_filename = "iterate.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @array = internal constant [6 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6]
// CHECK:STDOUT: @array.loc16_43.24 = internal constant [6 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6]
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 57 }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CG.Main(i32)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main() #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_43.3.temp = alloca [6 x i32], align 4, !dbg !15
// CHECK:STDOUT:   %var = alloca i32, align 4, !dbg !20
// CHECK:STDOUT:   %.loc17_19.5.temp = alloca <{ i32, i1 }>, align 4, !dbg !20
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc16_43.3.temp), !dbg !15
// CHECK:STDOUT:   %.loc16_43.4.array.index = getelementptr inbounds [6 x i32], ptr %.loc16_43.3.temp, i32 0, i64 0, !dbg !15
// CHECK:STDOUT:   %.loc16_43.7.array.index = getelementptr inbounds [6 x i32], ptr %.loc16_43.3.temp, i32 0, i64 1, !dbg !15
// CHECK:STDOUT:   %.loc16_43.10.array.index = getelementptr inbounds [6 x i32], ptr %.loc16_43.3.temp, i32 0, i64 2, !dbg !15
// CHECK:STDOUT:   %.loc16_43.13.array.index = getelementptr inbounds [6 x i32], ptr %.loc16_43.3.temp, i32 0, i64 3, !dbg !15
// CHECK:STDOUT:   %.loc16_43.16.array.index = getelementptr inbounds [6 x i32], ptr %.loc16_43.3.temp, i32 0, i64 4, !dbg !15
// CHECK:STDOUT:   %.loc16_43.19.array.index = getelementptr inbounds [6 x i32], ptr %.loc16_43.3.temp, i32 0, i64 5, !dbg !15
// CHECK:STDOUT:   %array_type.as.Iterate.impl.NewCursor.call = call i32 @"_CNewCursor.e163a239f9fa927c:Iterate.Core.64c6854216281bef"(ptr @array.loc16_43.24), !dbg !20
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %var), !dbg !20
// CHECK:STDOUT:   store i32 %array_type.as.Iterate.impl.NewCursor.call, ptr %var, align 4, !dbg !20
// CHECK:STDOUT:   br label %for.next, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: for.next:                                         ; preds = %for.body, %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc17_19.5.temp), !dbg !20
// CHECK:STDOUT:   call void @"_CNext.e163a239f9fa927c:Iterate.Core.64c6854216281bef"(ptr %.loc17_19.5.temp, ptr @array.loc16_43.24, ptr %var), !dbg !20
// CHECK:STDOUT:   %Optional.HasValue.call = call i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %.loc17_19.5.temp), !dbg !20
// CHECK:STDOUT:   br i1 %Optional.HasValue.call, label %for.body, label %for.done, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: for.body:                                         ; preds = %for.next
// CHECK:STDOUT:   %Optional.Get.call = call i32 @_CGet.Optional.Core.fc4496a6c25d418b(ptr %.loc17_19.5.temp), !dbg !20
// CHECK:STDOUT:   call void @_CG.Main(i32 %Optional.Get.call), !dbg !28
// CHECK:STDOUT:   call void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %.loc17_19.5.temp), !dbg !20
// CHECK:STDOUT:   br label %for.next, !dbg !29
// CHECK:STDOUT:
// CHECK:STDOUT: for.done:                                         ; preds = %for.next
// CHECK:STDOUT:   call void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %.loc17_19.5.temp), !dbg !20
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %var), !dbg !20
// CHECK:STDOUT:   call void @"_CSelfDestruct.1366a4d5330239bd:core.Destroy.Core"(ptr @array), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %self) #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.5f4a25925b904579(ptr %self), !dbg !33
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %self), !dbg !37
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1366a4d5330239bd:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_43.1.array.index = getelementptr inbounds [6 x i32], ptr %self, i32 0, i64 5, !dbg !41
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc16_43.1.array.index), !dbg !41
// CHECK:STDOUT:   %.loc16_43.2.array.index = getelementptr inbounds [6 x i32], ptr %self, i32 0, i64 4, !dbg !41
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc16_43.2.array.index), !dbg !41
// CHECK:STDOUT:   %.loc16_43.3.array.index = getelementptr inbounds [6 x i32], ptr %self, i32 0, i64 3, !dbg !41
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc16_43.3.array.index), !dbg !41
// CHECK:STDOUT:   %.loc16_43.4.array.index = getelementptr inbounds [6 x i32], ptr %self, i32 0, i64 2, !dbg !41
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc16_43.4.array.index), !dbg !41
// CHECK:STDOUT:   %.loc16_43.5.array.index = getelementptr inbounds [6 x i32], ptr %self, i32 0, i64 1, !dbg !41
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc16_43.5.array.index), !dbg !41
// CHECK:STDOUT:   %.loc16_43.6.array.index = getelementptr inbounds [6 x i32], ptr %self, i32 0, i64 0, !dbg !41
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc16_43.6.array.index), !dbg !41
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1366a4d5330239bd:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1366a4d5330239bd:core.Destroy.Core"(ptr %self), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CNewCursor.e163a239f9fa927c:Iterate.Core.64c6854216281bef"(ptr %self) #0 !dbg !51 {
// CHECK:STDOUT:   ret i32 0, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNext.e163a239f9fa927c:Iterate.Core.64c6854216281bef"(ptr sret(<{ i32, i1 }>) %return, ptr %self, ptr %cursor) #0 !dbg !58 {
// CHECK:STDOUT:   %1 = load i32, ptr %cursor, align 4, !dbg !66
// CHECK:STDOUT:   %2 = icmp slt i32 %1, 6, !dbg !66
// CHECK:STDOUT:   br i1 %2, label %3, label %7, !dbg !67
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   call void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8"(ptr %cursor), !dbg !70
// CHECK:STDOUT:   %4 = load i32, ptr %cursor, align 4, !dbg !73
// CHECK:STDOUT:   %5 = sub i32 %4, 1, !dbg !73
// CHECK:STDOUT:   %array.index = getelementptr inbounds [6 x i32], ptr %self, i32 0, i32 %5, !dbg !71
// CHECK:STDOUT:   %6 = load i32, ptr %array.index, align 4, !dbg !71
// CHECK:STDOUT:   call void @_CSome.Optional.Core.fc4496a6c25d418b(ptr %return, i32 %6), !dbg !74
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %0
// CHECK:STDOUT:   call void @_CNone.Optional.Core.fc4496a6c25d418b(ptr %return), !dbg !78
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %self) #0 !dbg !86 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !92
// CHECK:STDOUT:   ret i1 %1, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Optional.Core.fc4496a6c25d418b(ptr %self) #0 !dbg !95 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %self), !dbg !100
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !101
// CHECK:STDOUT:   br i1 %2, label %3, label %5, !dbg !102
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !103
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !103
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !103
// CHECK:STDOUT:   %4 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !103
// CHECK:STDOUT:   call void @abort(), !dbg !103
// CHECK:STDOUT:   br label %5, !dbg !104
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3, %0
// CHECK:STDOUT:   %6 = call i32 @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !106
// CHECK:STDOUT:   ret i32 %6, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.5f4a25925b904579(ptr %self) #0 !dbg !110 {
// CHECK:STDOUT:   call void @"_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !113
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.5f4a25925b904579(ptr %self), !dbg !114
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8"(ptr %self) #0 !dbg !118 {
// CHECK:STDOUT:   call void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895"(ptr %self, i32 1), !dbg !121
// CHECK:STDOUT:   ret void, !dbg !124
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Core.fc4496a6c25d418b(ptr sret(<{ i32, i1 }>) %return, i32 %value) #0 !dbg !126 {
// CHECK:STDOUT:   call void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %return, i32 %value), !dbg !131
// CHECK:STDOUT:   ret void, !dbg !132
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CNone.Optional.Core.fc4496a6c25d418b(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !134 {
// CHECK:STDOUT:   call void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %return), !dbg !137
// CHECK:STDOUT:   ret void, !dbg !138
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %value) #0 !dbg !139 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 1, !dbg !144
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !144
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !144
// CHECK:STDOUT:   ret i1 %2, !dbg !145
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %value) #0 !dbg !147 {
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 0, !dbg !152
// CHECK:STDOUT:   %1 = load i32, ptr %value1, align 4, !dbg !152
// CHECK:STDOUT:   ret i32 %1, !dbg !153
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f"(ptr %self) #0 !dbg !155 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !158
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !158
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !158
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !159
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !160
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %value), !dbg !161
// CHECK:STDOUT:   br label %4, !dbg !162
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %3, %0
// CHECK:STDOUT:   ret void, !dbg !163
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.5f4a25925b904579(ptr %self) #0 !dbg !165 {
// CHECK:STDOUT:   ret void, !dbg !168
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895"(ptr %self, i32 %other) #3 !dbg !170 {
// CHECK:STDOUT:   %1 = call i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %other), !dbg !173
// CHECK:STDOUT:   %2 = load i32, ptr %self, align 4, !dbg !174
// CHECK:STDOUT:   %3 = add i32 %2, %1, !dbg !174
// CHECK:STDOUT:   store i32 %3, ptr %self, align 4, !dbg !174
// CHECK:STDOUT:   ret void, !dbg !174
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !178 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 0, !dbg !187
// CHECK:STDOUT:   store i32 %self, ptr %value, align 4, !dbg !187
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !189
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !189
// CHECK:STDOUT:   ret void, !dbg !190
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !192 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !199
// CHECK:STDOUT:   store i8 0, ptr %has_value, align 1, !dbg !199
// CHECK:STDOUT:   ret void, !dbg !200
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %self) #0 !dbg !201 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !206
// CHECK:STDOUT:   ret i32 %1, !dbg !208
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !210 {
// CHECK:STDOUT:   ret i32 %self, !dbg !216
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core", { 1, 0 }
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
// CHECK:STDOUT: !4 = !DIFile(filename: "iterate.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{null}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !12 = !{null, !11}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 15, type: !10, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !15 = !DILocation(line: 16, column: 26, scope: !14)
// CHECK:STDOUT: !20 = !DILocation(line: 17, column: 7, scope: !14)
// CHECK:STDOUT: !21 = !{!6, !11}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !23 = !{!11, !11, !11}
// CHECK:STDOUT: !24 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !25 = !{!11, !11}
// CHECK:STDOUT: !26 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !28 = !DILocation(line: 18, column: 5, scope: !14)
// CHECK:STDOUT: !29 = !DILocation(line: 17, column: 3, scope: !14)
// CHECK:STDOUT: !30 = !DILocation(line: 15, column: 1, scope: !14)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a4e50b707d8bfe:core.Destroy.Core", scope: null, file: !4, line: 17, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !34)
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !31, type: !11)
// CHECK:STDOUT: !33 = !DILocation(line: 17, column: 7, scope: !31)
// CHECK:STDOUT: !34 = !{!32}
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core", scope: null, file: !4, line: 17, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !38)
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !35, type: !11)
// CHECK:STDOUT: !37 = !DILocation(line: 17, column: 7, scope: !35)
// CHECK:STDOUT: !38 = !{!36}
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1366a4d5330239bd:core.Destroy.Core", scope: null, file: !4, line: 16, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !11)
// CHECK:STDOUT: !41 = !DILocation(line: 16, column: 26, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1366a4d5330239bd:core.Destroy.Core", scope: null, file: !4, line: 16, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !11)
// CHECK:STDOUT: !45 = !DILocation(line: 16, column: 26, scope: !43)
// CHECK:STDOUT: !46 = !{!44}
// CHECK:STDOUT: !50 = !DIFile(filename: "{{.*}}/prelude/iterate.carbon", directory: "")
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "NewCursor", linkageName: "_CNewCursor.e163a239f9fa927c:Iterate.Core.64c6854216281bef", scope: null, file: !50, line: 23, type: !22, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !57)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !11)
// CHECK:STDOUT: !56 = !DILocation(line: 23, column: 38, scope: !51)
// CHECK:STDOUT: !57 = !{!52}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "Next", linkageName: "_CNext.e163a239f9fa927c:Iterate.Core.64c6854216281bef", scope: null, file: !50, line: 24, type: !24, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !82)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !11)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 2, scope: !58, type: !11)
// CHECK:STDOUT: !66 = !DILocation(line: 25, column: 9, scope: !58)
// CHECK:STDOUT: !67 = !DILocation(line: 25, column: 8, scope: !58)
// CHECK:STDOUT: !70 = !DILocation(line: 26, column: 7, scope: !58)
// CHECK:STDOUT: !71 = !DILocation(line: 27, column: 31, scope: !58)
// CHECK:STDOUT: !73 = !DILocation(line: 27, column: 36, scope: !58)
// CHECK:STDOUT: !74 = !DILocation(line: 27, column: 14, scope: !58)
// CHECK:STDOUT: !75 = !{!11, !6}
// CHECK:STDOUT: !76 = !DISubroutineType(types: !75)
// CHECK:STDOUT: !77 = !DILocation(line: 27, column: 7, scope: !58)
// CHECK:STDOUT: !78 = !DILocation(line: 29, column: 14, scope: !58)
// CHECK:STDOUT: !79 = !{!11}
// CHECK:STDOUT: !80 = !DISubroutineType(types: !79)
// CHECK:STDOUT: !81 = !DILocation(line: 29, column: 7, scope: !58)
// CHECK:STDOUT: !82 = !{!59, !60}
// CHECK:STDOUT: !85 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.fc4496a6c25d418b", scope: null, file: !85, line: 37, type: !26, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !94)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !86, type: !11)
// CHECK:STDOUT: !92 = !DILocation(line: 38, column: 12, scope: !86)
// CHECK:STDOUT: !93 = !DILocation(line: 38, column: 5, scope: !86)
// CHECK:STDOUT: !94 = !{!87}
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.fc4496a6c25d418b", scope: null, file: !85, line: 40, type: !22, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !108)
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 1, scope: !95, type: !11)
// CHECK:STDOUT: !100 = !DILocation(line: 303, column: 11, scope: !95)
// CHECK:STDOUT: !101 = !DILocation(line: 303, column: 7, scope: !95)
// CHECK:STDOUT: !102 = !DILocation(line: 303, column: 6, scope: !95)
// CHECK:STDOUT: !103 = !DILocation(line: 304, column: 5, scope: !95)
// CHECK:STDOUT: !104 = !DILocation(line: 303, column: 3, scope: !95)
// CHECK:STDOUT: !106 = !DILocation(line: 306, column: 10, scope: !95)
// CHECK:STDOUT: !107 = !DILocation(line: 306, column: 3, scope: !95)
// CHECK:STDOUT: !108 = !{!96}
// CHECK:STDOUT: !109 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.5f4a25925b904579", scope: null, file: !109, line: 26, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !116)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !11)
// CHECK:STDOUT: !113 = !DILocation(line: 27, column: 5, scope: !110)
// CHECK:STDOUT: !114 = !DILocation(line: 28, column: 5, scope: !110)
// CHECK:STDOUT: !115 = !DILocation(line: 26, column: 3, scope: !110)
// CHECK:STDOUT: !116 = !{!111}
// CHECK:STDOUT: !117 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !118 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8", scope: null, file: !117, line: 396, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !125)
// CHECK:STDOUT: !119 = !DILocalVariable(arg: 1, scope: !118, type: !6)
// CHECK:STDOUT: !121 = !DILocation(line: 398, column: 5, scope: !118)
// CHECK:STDOUT: !122 = !{null, !6, !6}
// CHECK:STDOUT: !123 = !DISubroutineType(types: !122)
// CHECK:STDOUT: !124 = !DILocation(line: 396, column: 3, scope: !118)
// CHECK:STDOUT: !125 = !{!119}
// CHECK:STDOUT: !126 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.fc4496a6c25d418b", scope: null, file: !85, line: 34, type: !76, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !133)
// CHECK:STDOUT: !127 = !DILocalVariable(arg: 1, scope: !126, type: !6)
// CHECK:STDOUT: !131 = !DILocation(line: 35, column: 12, scope: !126)
// CHECK:STDOUT: !132 = !DILocation(line: 35, column: 5, scope: !126)
// CHECK:STDOUT: !133 = !{!127}
// CHECK:STDOUT: !134 = distinct !DISubprogram(name: "None", linkageName: "_CNone.Optional.Core.fc4496a6c25d418b", scope: null, file: !85, line: 31, type: !80, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !137 = !DILocation(line: 32, column: 12, scope: !134)
// CHECK:STDOUT: !138 = !DILocation(line: 32, column: 5, scope: !134)
// CHECK:STDOUT: !139 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !85, line: 166, type: !26, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !146)
// CHECK:STDOUT: !140 = !DILocalVariable(arg: 1, scope: !139, type: !11)
// CHECK:STDOUT: !144 = !DILocation(line: 167, column: 12, scope: !139)
// CHECK:STDOUT: !145 = !DILocation(line: 167, column: 5, scope: !139)
// CHECK:STDOUT: !146 = !{!140}
// CHECK:STDOUT: !147 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !85, line: 169, type: !22, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !154)
// CHECK:STDOUT: !148 = !DILocalVariable(arg: 1, scope: !147, type: !11)
// CHECK:STDOUT: !152 = !DILocation(line: 170, column: 12, scope: !147)
// CHECK:STDOUT: !153 = !DILocation(line: 170, column: 5, scope: !147)
// CHECK:STDOUT: !154 = !{!148}
// CHECK:STDOUT: !155 = distinct !DISubprogram(name: "Op", linkageName: "_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f", scope: null, file: !85, line: 284, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !164)
// CHECK:STDOUT: !156 = !DILocalVariable(arg: 1, scope: !155, type: !11)
// CHECK:STDOUT: !158 = !DILocation(line: 285, column: 9, scope: !155)
// CHECK:STDOUT: !159 = !DILocation(line: 285, column: 8, scope: !155)
// CHECK:STDOUT: !160 = !DILocation(line: 286, column: 8, scope: !155)
// CHECK:STDOUT: !161 = !DILocation(line: 286, column: 7, scope: !155)
// CHECK:STDOUT: !162 = !DILocation(line: 285, column: 5, scope: !155)
// CHECK:STDOUT: !163 = !DILocation(line: 284, column: 3, scope: !155)
// CHECK:STDOUT: !164 = !{!156}
// CHECK:STDOUT: !165 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.5f4a25925b904579", scope: null, file: !109, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !169)
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 1, scope: !165, type: !11)
// CHECK:STDOUT: !168 = !DILocation(line: 19, column: 3, scope: !165)
// CHECK:STDOUT: !169 = !{!166}
// CHECK:STDOUT: !170 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895", scope: null, file: !117, line: 331, type: !123, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !177)
// CHECK:STDOUT: !171 = !DILocalVariable(arg: 1, scope: !170, type: !6)
// CHECK:STDOUT: !172 = !DILocalVariable(arg: 2, scope: !170, type: !6)
// CHECK:STDOUT: !173 = !DILocation(line: 0, scope: !170)
// CHECK:STDOUT: !174 = !DILocation(line: 331, column: 3, scope: !170)
// CHECK:STDOUT: !175 = !{!6, !6}
// CHECK:STDOUT: !176 = !DISubroutineType(types: !175)
// CHECK:STDOUT: !177 = !{!171, !172}
// CHECK:STDOUT: !178 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !85, line: 156, type: !76, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !191)
// CHECK:STDOUT: !179 = !DILocalVariable(arg: 1, scope: !178, type: !6)
// CHECK:STDOUT: !187 = !DILocation(line: 162, column: 5, scope: !178)
// CHECK:STDOUT: !189 = !DILocation(line: 163, column: 5, scope: !178)
// CHECK:STDOUT: !190 = !DILocation(line: 164, column: 5, scope: !178)
// CHECK:STDOUT: !191 = !{!179}
// CHECK:STDOUT: !192 = distinct !DISubprogram(name: "None", linkageName: "_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !85, line: 150, type: !80, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !199 = !DILocation(line: 153, column: 5, scope: !192)
// CHECK:STDOUT: !200 = !DILocation(line: 154, column: 5, scope: !192)
// CHECK:STDOUT: !201 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044", scope: null, file: !117, line: 64, type: !176, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !209)
// CHECK:STDOUT: !202 = !DILocalVariable(arg: 1, scope: !201, type: !6)
// CHECK:STDOUT: !206 = !DILocation(line: 66, column: 17, scope: !201)
// CHECK:STDOUT: !208 = !DILocation(line: 66, column: 5, scope: !201)
// CHECK:STDOUT: !209 = !{!202}
// CHECK:STDOUT: !210 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !117, line: 59, type: !176, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !217)
// CHECK:STDOUT: !211 = !DILocalVariable(arg: 1, scope: !210, type: !6)
// CHECK:STDOUT: !216 = !DILocation(line: 59, column: 28, scope: !210)
// CHECK:STDOUT: !217 = !{!211}
// CHECK:STDOUT:
