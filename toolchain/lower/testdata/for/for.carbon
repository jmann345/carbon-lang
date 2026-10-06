// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/for/for.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/for/for.carbon

fn F();
fn G();
fn H();

fn For() {
  F();
  for (_: i32 in Core.Range(100)) {
    G();
  }
  H();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'for.carbon'
// CHECK:STDOUT: source_filename = "for.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CF.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CG.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CH.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CFor.Main() #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_32.1.temp = alloca { i32, i32 }, align 4, !dbg !19
// CHECK:STDOUT:   %var = alloca i32, align 4, !dbg !20
// CHECK:STDOUT:   %.loc19_33.1.temp = alloca <{ i32, i1 }>, align 4, !dbg !20
// CHECK:STDOUT:   call void @_CF.Main(), !dbg !17
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc19_32.1.temp), !dbg !19
// CHECK:STDOUT:   call void @_CRange.Core(ptr %.loc19_32.1.temp, i32 100), !dbg !19
// CHECK:STDOUT:   %IntRange.as.Iterate.impl.NewCursor.call = call i32 @"_CNewCursor.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8"(ptr %.loc19_32.1.temp), !dbg !20
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %var), !dbg !20
// CHECK:STDOUT:   store i32 %IntRange.as.Iterate.impl.NewCursor.call, ptr %var, align 4, !dbg !20
// CHECK:STDOUT:   br label %for.next, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: for.next:                                         ; preds = %for.body, %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc19_33.1.temp), !dbg !20
// CHECK:STDOUT:   call void @"_CNext.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8"(ptr %.loc19_33.1.temp, ptr %.loc19_32.1.temp, ptr %var), !dbg !20
// CHECK:STDOUT:   %Optional.HasValue.call = call i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %.loc19_33.1.temp), !dbg !20
// CHECK:STDOUT:   br i1 %Optional.HasValue.call, label %for.body, label %for.done, !dbg !20
// CHECK:STDOUT:
// CHECK:STDOUT: for.body:                                         ; preds = %for.next
// CHECK:STDOUT:   %Optional.Get.call = call i32 @_CGet.Optional.Core.fc4496a6c25d418b(ptr %.loc19_33.1.temp), !dbg !20
// CHECK:STDOUT:   call void @_CG.Main(), !dbg !27
// CHECK:STDOUT:   call void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %.loc19_33.1.temp), !dbg !20
// CHECK:STDOUT:   br label %for.next, !dbg !28
// CHECK:STDOUT:
// CHECK:STDOUT: for.done:                                         ; preds = %for.next
// CHECK:STDOUT:   call void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %.loc19_33.1.temp), !dbg !20
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %var), !dbg !20
// CHECK:STDOUT:   call void @"_CSelfDestruct.c9184c281ed4335d:core.Destroy.Core"(ptr %.loc19_32.1.temp), !dbg !19
// CHECK:STDOUT:   call void @_CH.Main(), !dbg !29
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CRange.Core(ptr sret({ i32, i32 }), i32)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1d6a7672bf2f14c6:core.Destroy.Core"(ptr %self) #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1d6a7672bf2f14c6:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1d6a7672bf2f14c6:core.Destroy.Core"(ptr %self), !dbg !37
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.51569357b34b54dc:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f6a63055ea5a1824:core.Destroy.Core"(ptr %self) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_33.1.has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !49
// CHECK:STDOUT:   call void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %.loc19_33.1.has_value), !dbg !49
// CHECK:STDOUT:   %.loc19_33.2.value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !49
// CHECK:STDOUT:   call void @"_CSelfDestruct.51569357b34b54dc:core.Destroy.Core"(ptr %.loc19_33.2.value), !dbg !49
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f6a63055ea5a1824:core.Destroy.Core"(ptr %self) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f6a63055ea5a1824:core.Destroy.Core"(ptr %self), !dbg !53
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b7a533f3082ff11b:core.Destroy.Core"(ptr %self) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_33.1.has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !57
// CHECK:STDOUT:   call void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %.loc19_33.1.has_value), !dbg !57
// CHECK:STDOUT:   %.loc19_33.2.value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !57
// CHECK:STDOUT:   call void @"_CSelfDestruct.51569357b34b54dc:core.Destroy.Core"(ptr %.loc19_33.2.value), !dbg !57
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b7a533f3082ff11b:core.Destroy.Core"(ptr %self) #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b7a533f3082ff11b:core.Destroy.Core"(ptr %self), !dbg !61
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %self) #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e933d5ff8212e171:core.Destroy.Core"(ptr %self) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_32.1.end = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !69
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc19_32.1.end), !dbg !69
// CHECK:STDOUT:   %.loc19_32.2.start = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !69
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc19_32.2.start), !dbg !69
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e933d5ff8212e171:core.Destroy.Core"(ptr %self) #0 !dbg !71 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e933d5ff8212e171:core.Destroy.Core"(ptr %self), !dbg !73
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c9184c281ed4335d:core.Destroy.Core"(ptr %self) #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_32.1.end = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !77
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc19_32.1.end), !dbg !77
// CHECK:STDOUT:   %.loc19_32.2.start = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !77
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc19_32.2.start), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c9184c281ed4335d:core.Destroy.Core"(ptr %self) #0 !dbg !79 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c9184c281ed4335d:core.Destroy.Core"(ptr %self), !dbg !81
// CHECK:STDOUT:   ret void, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CNewCursor.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8"(ptr %self) #0 !dbg !86 {
// CHECK:STDOUT:   %start = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !91
// CHECK:STDOUT:   %1 = load i32, ptr %start, align 4, !dbg !91
// CHECK:STDOUT:   ret i32 %1, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNext.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8"(ptr sret(<{ i32, i1 }>) %return, ptr %self, ptr %cursor) #0 !dbg !94 {
// CHECK:STDOUT:   %1 = alloca i32, align 4, !dbg !101
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !101
// CHECK:STDOUT:   %2 = load i32, ptr %cursor, align 4, !dbg !103
// CHECK:STDOUT:   store i32 %2, ptr %1, align 4, !dbg !101
// CHECK:STDOUT:   %end = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !106
// CHECK:STDOUT:   %3 = load i32, ptr %end, align 4, !dbg !106
// CHECK:STDOUT:   %4 = load i32, ptr %1, align 4, !dbg !105
// CHECK:STDOUT:   %5 = icmp slt i32 %4, %3, !dbg !105
// CHECK:STDOUT:   br i1 %5, label %6, label %8, !dbg !107
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   call void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8"(ptr %cursor), !dbg !110
// CHECK:STDOUT:   %7 = load i32, ptr %1, align 4, !dbg !111
// CHECK:STDOUT:   call void @_CSome.Optional.Core.fc4496a6c25d418b(ptr %return, i32 %7), !dbg !112
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %1), !dbg !101
// CHECK:STDOUT:   ret void, !dbg !113
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %0
// CHECK:STDOUT:   call void @_CNone.Optional.Core.fc4496a6c25d418b(ptr %return), !dbg !114
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %1), !dbg !101
// CHECK:STDOUT:   ret void, !dbg !117
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %self) #0 !dbg !121 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !127
// CHECK:STDOUT:   ret i1 %1, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Optional.Core.fc4496a6c25d418b(ptr %self) #0 !dbg !130 {
// CHECK:STDOUT:   %1 = call i32 @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !136
// CHECK:STDOUT:   ret i32 %1, !dbg !137
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CInclusiveRange.Core(ptr sret({ i32, i32 }), i32, i32)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8"(ptr %self) #0 !dbg !140 {
// CHECK:STDOUT:   call void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895"(ptr %self, i32 1), !dbg !143
// CHECK:STDOUT:   ret void, !dbg !146
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Core.fc4496a6c25d418b(ptr sret(<{ i32, i1 }>) %return, i32 %value) #0 !dbg !148 {
// CHECK:STDOUT:   call void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %return, i32 %value), !dbg !153
// CHECK:STDOUT:   ret void, !dbg !154
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CNone.Optional.Core.fc4496a6c25d418b(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !156 {
// CHECK:STDOUT:   call void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %return), !dbg !159
// CHECK:STDOUT:   ret void, !dbg !160
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %value) #0 !dbg !161 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 1, !dbg !166
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !166
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !166
// CHECK:STDOUT:   ret i1 %2, !dbg !167
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %value) #0 !dbg !169 {
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 0, !dbg !174
// CHECK:STDOUT:   %1 = load i32, ptr %value1, align 4, !dbg !174
// CHECK:STDOUT:   ret i32 %1, !dbg !175
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895"(ptr %self, i32 %other) #2 !dbg !177 {
// CHECK:STDOUT:   %1 = call i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %other), !dbg !180
// CHECK:STDOUT:   %2 = load i32, ptr %self, align 4, !dbg !181
// CHECK:STDOUT:   %3 = add i32 %2, %1, !dbg !181
// CHECK:STDOUT:   store i32 %3, ptr %self, align 4, !dbg !181
// CHECK:STDOUT:   ret void, !dbg !181
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !185 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 0, !dbg !194
// CHECK:STDOUT:   store i32 %self, ptr %value, align 4, !dbg !194
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !196
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !196
// CHECK:STDOUT:   ret void, !dbg !197
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !199 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !206
// CHECK:STDOUT:   store i8 0, ptr %has_value, align 1, !dbg !206
// CHECK:STDOUT:   ret void, !dbg !207
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %self) #0 !dbg !208 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !213
// CHECK:STDOUT:   ret i32 %1, !dbg !215
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !217 {
// CHECK:STDOUT:   ret i32 %self, !dbg !223
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 3, 2, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { alwaysinline nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "for.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !{null}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !9}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "For", linkageName: "_CFor.Main", scope: null, file: !4, line: 17, type: !8, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !17 = !DILocation(line: 18, column: 3, scope: !16)
// CHECK:STDOUT: !19 = !DILocation(line: 19, column: 18, scope: !16)
// CHECK:STDOUT: !20 = !DILocation(line: 19, column: 7, scope: !16)
// CHECK:STDOUT: !21 = !{!6, !9}
// CHECK:STDOUT: !22 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !23 = !{!9, !9, !9}
// CHECK:STDOUT: !24 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !25 = !{!9, !9}
// CHECK:STDOUT: !26 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !27 = !DILocation(line: 20, column: 5, scope: !16)
// CHECK:STDOUT: !28 = !DILocation(line: 19, column: 3, scope: !16)
// CHECK:STDOUT: !29 = !DILocation(line: 22, column: 3, scope: !16)
// CHECK:STDOUT: !30 = !DILocation(line: 17, column: 1, scope: !16)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1d6a7672bf2f14c6:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !34)
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !31, type: !9)
// CHECK:STDOUT: !33 = !DILocation(line: 19, column: 7, scope: !31)
// CHECK:STDOUT: !34 = !{!32}
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1d6a7672bf2f14c6:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !38)
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !35, type: !9)
// CHECK:STDOUT: !37 = !DILocation(line: 19, column: 7, scope: !35)
// CHECK:STDOUT: !38 = !{!36}
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.51569357b34b54dc:core.Destroy.Core", scope: null, file: !4, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !6)
// CHECK:STDOUT: !41 = !DILocation(line: 19, column: 7, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !9)
// CHECK:STDOUT: !45 = !DILocation(line: 19, column: 7, scope: !43)
// CHECK:STDOUT: !46 = !{!44}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f6a63055ea5a1824:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !50)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !9)
// CHECK:STDOUT: !49 = !DILocation(line: 19, column: 7, scope: !47)
// CHECK:STDOUT: !50 = !{!48}
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f6a63055ea5a1824:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !54)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !9)
// CHECK:STDOUT: !53 = !DILocation(line: 19, column: 7, scope: !51)
// CHECK:STDOUT: !54 = !{!52}
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b7a533f3082ff11b:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !55, type: !9)
// CHECK:STDOUT: !57 = !DILocation(line: 19, column: 7, scope: !55)
// CHECK:STDOUT: !58 = !{!56}
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b7a533f3082ff11b:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !62)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !59, type: !9)
// CHECK:STDOUT: !61 = !DILocation(line: 19, column: 7, scope: !59)
// CHECK:STDOUT: !62 = !{!60}
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !66)
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !63, type: !9)
// CHECK:STDOUT: !65 = !DILocation(line: 19, column: 7, scope: !63)
// CHECK:STDOUT: !66 = !{!64}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e933d5ff8212e171:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !70)
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !67, type: !9)
// CHECK:STDOUT: !69 = !DILocation(line: 19, column: 18, scope: !67)
// CHECK:STDOUT: !70 = !{!68}
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e933d5ff8212e171:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !74)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !71, type: !9)
// CHECK:STDOUT: !73 = !DILocation(line: 19, column: 18, scope: !71)
// CHECK:STDOUT: !74 = !{!72}
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c9184c281ed4335d:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !78)
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !75, type: !9)
// CHECK:STDOUT: !77 = !DILocation(line: 19, column: 18, scope: !75)
// CHECK:STDOUT: !78 = !{!76}
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c9184c281ed4335d:core.Destroy.Core", scope: null, file: !4, line: 19, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !82)
// CHECK:STDOUT: !80 = !DILocalVariable(arg: 1, scope: !79, type: !9)
// CHECK:STDOUT: !81 = !DILocation(line: 19, column: 18, scope: !79)
// CHECK:STDOUT: !82 = !{!80}
// CHECK:STDOUT: !85 = !DIFile(filename: "{{.*}}/prelude/range.carbon", directory: "")
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "NewCursor", linkageName: "_CNewCursor.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8", scope: null, file: !85, line: 19, type: !22, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !93)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !86, type: !9)
// CHECK:STDOUT: !91 = !DILocation(line: 19, column: 43, scope: !86)
// CHECK:STDOUT: !92 = !DILocation(line: 19, column: 36, scope: !86)
// CHECK:STDOUT: !93 = !{!87}
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "Next", linkageName: "_CNext.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8", scope: null, file: !85, line: 20, type: !24, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !118)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !94, type: !9)
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 2, scope: !94, type: !9)
// CHECK:STDOUT: !101 = !DILocation(line: 21, column: 7, scope: !94)
// CHECK:STDOUT: !103 = !DILocation(line: 21, column: 27, scope: !94)
// CHECK:STDOUT: !105 = !DILocation(line: 22, column: 11, scope: !94)
// CHECK:STDOUT: !106 = !DILocation(line: 22, column: 19, scope: !94)
// CHECK:STDOUT: !107 = !DILocation(line: 22, column: 10, scope: !94)
// CHECK:STDOUT: !110 = !DILocation(line: 23, column: 9, scope: !94)
// CHECK:STDOUT: !111 = !DILocation(line: 24, column: 38, scope: !94)
// CHECK:STDOUT: !112 = !DILocation(line: 24, column: 16, scope: !94)
// CHECK:STDOUT: !113 = !DILocation(line: 24, column: 9, scope: !94)
// CHECK:STDOUT: !114 = !DILocation(line: 26, column: 16, scope: !94)
// CHECK:STDOUT: !115 = !{!9}
// CHECK:STDOUT: !116 = !DISubroutineType(types: !115)
// CHECK:STDOUT: !117 = !DILocation(line: 26, column: 9, scope: !94)
// CHECK:STDOUT: !118 = !{!95, !96}
// CHECK:STDOUT: !120 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.fc4496a6c25d418b", scope: null, file: !120, line: 37, type: !26, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !129)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !121, type: !9)
// CHECK:STDOUT: !127 = !DILocation(line: 38, column: 12, scope: !121)
// CHECK:STDOUT: !128 = !DILocation(line: 38, column: 5, scope: !121)
// CHECK:STDOUT: !129 = !{!122}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.fc4496a6c25d418b", scope: null, file: !120, line: 40, type: !22, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !138)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !9)
// CHECK:STDOUT: !136 = !DILocation(line: 41, column: 12, scope: !130)
// CHECK:STDOUT: !137 = !DILocation(line: 41, column: 5, scope: !130)
// CHECK:STDOUT: !138 = !{!131}
// CHECK:STDOUT: !139 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !140 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8", scope: null, file: !139, line: 396, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !147)
// CHECK:STDOUT: !141 = !DILocalVariable(arg: 1, scope: !140, type: !6)
// CHECK:STDOUT: !143 = !DILocation(line: 398, column: 5, scope: !140)
// CHECK:STDOUT: !144 = !{null, !6, !6}
// CHECK:STDOUT: !145 = !DISubroutineType(types: !144)
// CHECK:STDOUT: !146 = !DILocation(line: 396, column: 3, scope: !140)
// CHECK:STDOUT: !147 = !{!141}
// CHECK:STDOUT: !148 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.fc4496a6c25d418b", scope: null, file: !120, line: 34, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !155)
// CHECK:STDOUT: !149 = !DILocalVariable(arg: 1, scope: !148, type: !6)
// CHECK:STDOUT: !153 = !DILocation(line: 35, column: 12, scope: !148)
// CHECK:STDOUT: !154 = !DILocation(line: 35, column: 5, scope: !148)
// CHECK:STDOUT: !155 = !{!149}
// CHECK:STDOUT: !156 = distinct !DISubprogram(name: "None", linkageName: "_CNone.Optional.Core.fc4496a6c25d418b", scope: null, file: !120, line: 31, type: !116, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !159 = !DILocation(line: 32, column: 12, scope: !156)
// CHECK:STDOUT: !160 = !DILocation(line: 32, column: 5, scope: !156)
// CHECK:STDOUT: !161 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !120, line: 166, type: !26, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !168)
// CHECK:STDOUT: !162 = !DILocalVariable(arg: 1, scope: !161, type: !9)
// CHECK:STDOUT: !166 = !DILocation(line: 167, column: 12, scope: !161)
// CHECK:STDOUT: !167 = !DILocation(line: 167, column: 5, scope: !161)
// CHECK:STDOUT: !168 = !{!162}
// CHECK:STDOUT: !169 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !120, line: 169, type: !22, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !176)
// CHECK:STDOUT: !170 = !DILocalVariable(arg: 1, scope: !169, type: !9)
// CHECK:STDOUT: !174 = !DILocation(line: 170, column: 12, scope: !169)
// CHECK:STDOUT: !175 = !DILocation(line: 170, column: 5, scope: !169)
// CHECK:STDOUT: !176 = !{!170}
// CHECK:STDOUT: !177 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895", scope: null, file: !139, line: 331, type: !145, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !184)
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 1, scope: !177, type: !6)
// CHECK:STDOUT: !179 = !DILocalVariable(arg: 2, scope: !177, type: !6)
// CHECK:STDOUT: !180 = !DILocation(line: 0, scope: !177)
// CHECK:STDOUT: !181 = !DILocation(line: 331, column: 3, scope: !177)
// CHECK:STDOUT: !182 = !{!6, !6}
// CHECK:STDOUT: !183 = !DISubroutineType(types: !182)
// CHECK:STDOUT: !184 = !{!178, !179}
// CHECK:STDOUT: !185 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !120, line: 156, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !198)
// CHECK:STDOUT: !186 = !DILocalVariable(arg: 1, scope: !185, type: !6)
// CHECK:STDOUT: !194 = !DILocation(line: 162, column: 5, scope: !185)
// CHECK:STDOUT: !196 = !DILocation(line: 163, column: 5, scope: !185)
// CHECK:STDOUT: !197 = !DILocation(line: 164, column: 5, scope: !185)
// CHECK:STDOUT: !198 = !{!186}
// CHECK:STDOUT: !199 = distinct !DISubprogram(name: "None", linkageName: "_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !120, line: 150, type: !116, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !206 = !DILocation(line: 153, column: 5, scope: !199)
// CHECK:STDOUT: !207 = !DILocation(line: 154, column: 5, scope: !199)
// CHECK:STDOUT: !208 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044", scope: null, file: !139, line: 64, type: !183, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !216)
// CHECK:STDOUT: !209 = !DILocalVariable(arg: 1, scope: !208, type: !6)
// CHECK:STDOUT: !213 = !DILocation(line: 66, column: 17, scope: !208)
// CHECK:STDOUT: !215 = !DILocation(line: 66, column: 5, scope: !208)
// CHECK:STDOUT: !216 = !{!209}
// CHECK:STDOUT: !217 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !139, line: 59, type: !183, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !224)
// CHECK:STDOUT: !218 = !DILocalVariable(arg: 1, scope: !217, type: !6)
// CHECK:STDOUT: !223 = !DILocation(line: 59, column: 28, scope: !217)
// CHECK:STDOUT: !224 = !{!218}
// CHECK:STDOUT:
