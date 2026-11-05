// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/for/break_continue.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/for/break_continue.carbon

fn F() -> bool;
fn G() -> bool;
fn H();

fn For() {
  for (_: i32 in Core.Range(100)) {
    if (F()) { break; }
    if (G()) { continue; }
    H();
  }
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'break_continue.carbon'
// CHECK:STDOUT: source_filename = "break_continue.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 57 }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i1 @_CF.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i1 @_CG.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CH.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CFor.Main() #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_32.1.temp = alloca { i32, i32 }, align 4, !dbg !20
// CHECK:STDOUT:   %var = alloca i32, align 4, !dbg !21
// CHECK:STDOUT:   %.loc18_33.1.temp = alloca <{ i32, i1 }>, align 4, !dbg !21
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc18_32.1.temp), !dbg !20
// CHECK:STDOUT:   call void @_CRange.Core(ptr %.loc18_32.1.temp, i32 100), !dbg !20
// CHECK:STDOUT:   %IntRange.as.Iterate.impl.NewCursor.call = call i32 @"_CNewCursor.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8"(ptr %.loc18_32.1.temp), !dbg !21
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %var), !dbg !21
// CHECK:STDOUT:   store i32 %IntRange.as.Iterate.impl.NewCursor.call, ptr %var, align 4, !dbg !21
// CHECK:STDOUT:   br label %for.next, !dbg !21
// CHECK:STDOUT:
// CHECK:STDOUT: for.next:                                         ; preds = %if.else.loc20, %if.then.loc20, %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc18_33.1.temp), !dbg !21
// CHECK:STDOUT:   call void @"_CNext.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8"(ptr %.loc18_33.1.temp, ptr %.loc18_32.1.temp, ptr %var), !dbg !21
// CHECK:STDOUT:   %Optional.HasValue.call = call i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %.loc18_33.1.temp), !dbg !21
// CHECK:STDOUT:   br i1 %Optional.HasValue.call, label %for.body, label %for.done, !dbg !21
// CHECK:STDOUT:
// CHECK:STDOUT: for.body:                                         ; preds = %for.next
// CHECK:STDOUT:   %Optional.Get.call = call i32 @_CGet.Optional.Core.fc4496a6c25d418b(ptr %.loc18_33.1.temp), !dbg !21
// CHECK:STDOUT:   %F.call = call i1 @_CF.Main(), !dbg !28
// CHECK:STDOUT:   br i1 %F.call, label %if.then.loc19, label %if.else.loc19, !dbg !29
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc19:                                    ; preds = %for.body
// CHECK:STDOUT:   br label %for.done, !dbg !30
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc19:                                    ; preds = %for.body
// CHECK:STDOUT:   %G.call = call i1 @_CG.Main(), !dbg !31
// CHECK:STDOUT:   br i1 %G.call, label %if.then.loc20, label %if.else.loc20, !dbg !32
// CHECK:STDOUT:
// CHECK:STDOUT: if.then.loc20:                                    ; preds = %if.else.loc19
// CHECK:STDOUT:   call void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %.loc18_33.1.temp), !dbg !21
// CHECK:STDOUT:   br label %for.next, !dbg !33
// CHECK:STDOUT:
// CHECK:STDOUT: if.else.loc20:                                    ; preds = %if.else.loc19
// CHECK:STDOUT:   call void @_CH.Main(), !dbg !34
// CHECK:STDOUT:   call void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %.loc18_33.1.temp), !dbg !21
// CHECK:STDOUT:   br label %for.next, !dbg !35
// CHECK:STDOUT:
// CHECK:STDOUT: for.done:                                         ; preds = %if.then.loc19, %for.next
// CHECK:STDOUT:   call void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %.loc18_33.1.temp), !dbg !21
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %var), !dbg !21
// CHECK:STDOUT:   call void @"_CSelfDestruct.c9184c281ed4335d:core.Destroy.Core"(ptr %.loc18_32.1.temp), !dbg !20
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CRange.Core(ptr sret({ i32, i32 }), i32)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %self) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.5f4a25925b904579(ptr %self), !dbg !39
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.a8a4e50b707d8bfe:core.Destroy.Core"(ptr %self), !dbg !43
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e933d5ff8212e171:core.Destroy.Core"(ptr %self) #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_32.1.end = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !47
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc18_32.1.end), !dbg !47
// CHECK:STDOUT:   %.loc18_32.2.start = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !47
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc18_32.2.start), !dbg !47
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e933d5ff8212e171:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e933d5ff8212e171:core.Destroy.Core"(ptr %self), !dbg !51
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c9184c281ed4335d:core.Destroy.Core"(ptr %self) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_32.1.end = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !55
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc18_32.1.end), !dbg !55
// CHECK:STDOUT:   %.loc18_32.2.start = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !55
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc18_32.2.start), !dbg !55
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c9184c281ed4335d:core.Destroy.Core"(ptr %self) #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c9184c281ed4335d:core.Destroy.Core"(ptr %self), !dbg !59
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CNewCursor.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8"(ptr %self) #0 !dbg !64 {
// CHECK:STDOUT:   %start = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !69
// CHECK:STDOUT:   %1 = load i32, ptr %start, align 4, !dbg !69
// CHECK:STDOUT:   ret i32 %1, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNext.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8"(ptr sret(<{ i32, i1 }>) %return, ptr %self, ptr %cursor) #0 !dbg !72 {
// CHECK:STDOUT:   %1 = alloca i32, align 4, !dbg !79
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !79
// CHECK:STDOUT:   %2 = load i32, ptr %cursor, align 4, !dbg !80
// CHECK:STDOUT:   store i32 %2, ptr %1, align 4, !dbg !79
// CHECK:STDOUT:   %end = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !83
// CHECK:STDOUT:   %3 = load i32, ptr %end, align 4, !dbg !83
// CHECK:STDOUT:   %4 = load i32, ptr %1, align 4, !dbg !82
// CHECK:STDOUT:   %5 = icmp slt i32 %4, %3, !dbg !82
// CHECK:STDOUT:   br i1 %5, label %6, label %8, !dbg !84
// CHECK:STDOUT:
// CHECK:STDOUT: 6:                                                ; preds = %0
// CHECK:STDOUT:   call void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8"(ptr %cursor), !dbg !86
// CHECK:STDOUT:   %7 = load i32, ptr %1, align 4, !dbg !87
// CHECK:STDOUT:   call void @_CSome.Optional.Core.fc4496a6c25d418b(ptr %return, i32 %7), !dbg !88
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %1), !dbg !79
// CHECK:STDOUT:   ret void, !dbg !89
// CHECK:STDOUT:
// CHECK:STDOUT: 8:                                                ; preds = %0
// CHECK:STDOUT:   call void @_CNone.Optional.Core.fc4496a6c25d418b(ptr %return), !dbg !90
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %1), !dbg !79
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %self) #0 !dbg !97 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !103
// CHECK:STDOUT:   ret i1 %1, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CGet.Optional.Core.fc4496a6c25d418b(ptr %self) #0 !dbg !106 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.fc4496a6c25d418b(ptr %self), !dbg !111
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !112
// CHECK:STDOUT:   br i1 %2, label %3, label %5, !dbg !113
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !114
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !114
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !114
// CHECK:STDOUT:   %4 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !114
// CHECK:STDOUT:   call void @abort(), !dbg !114
// CHECK:STDOUT:   br label %5, !dbg !115
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3, %0
// CHECK:STDOUT:   %6 = call i32 @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !117
// CHECK:STDOUT:   ret i32 %6, !dbg !118
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.5f4a25925b904579(ptr %self) #0 !dbg !121 {
// CHECK:STDOUT:   call void @"_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f"(ptr %self), !dbg !124
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.5f4a25925b904579(ptr %self), !dbg !125
// CHECK:STDOUT:   ret void, !dbg !126
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CInclusiveRange.Core(ptr sret({ i32, i32 }), i32, i32)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8"(ptr %self) #0 !dbg !129 {
// CHECK:STDOUT:   call void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895"(ptr %self, i32 1), !dbg !132
// CHECK:STDOUT:   ret void, !dbg !135
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Core.fc4496a6c25d418b(ptr sret(<{ i32, i1 }>) %return, i32 %value) #0 !dbg !137 {
// CHECK:STDOUT:   call void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %return, i32 %value), !dbg !142
// CHECK:STDOUT:   ret void, !dbg !143
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CNone.Optional.Core.fc4496a6c25d418b(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !145 {
// CHECK:STDOUT:   call void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %return), !dbg !148
// CHECK:STDOUT:   ret void, !dbg !149
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %value) #0 !dbg !150 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 1, !dbg !155
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !155
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !155
// CHECK:STDOUT:   ret i1 %2, !dbg !156
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr %value) #0 !dbg !158 {
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ i32, i1 }>, ptr %value, i32 0, i32 0, !dbg !163
// CHECK:STDOUT:   %1 = load i32, ptr %value1, align 4, !dbg !163
// CHECK:STDOUT:   ret i32 %1, !dbg !164
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f"(ptr %self) #0 !dbg !166 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !169
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !169
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !169
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !170
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !171
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %value), !dbg !172
// CHECK:STDOUT:   br label %4, !dbg !173
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %3, %0
// CHECK:STDOUT:   ret void, !dbg !174
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.5f4a25925b904579(ptr %self) #0 !dbg !176 {
// CHECK:STDOUT:   ret void, !dbg !179
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895"(ptr %self, i32 %other) #3 !dbg !181 {
// CHECK:STDOUT:   %1 = call i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %other), !dbg !184
// CHECK:STDOUT:   %2 = load i32, ptr %self, align 4, !dbg !185
// CHECK:STDOUT:   %3 = add i32 %2, %1, !dbg !185
// CHECK:STDOUT:   store i32 %3, ptr %self, align 4, !dbg !185
// CHECK:STDOUT:   ret void, !dbg !185
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !189 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 0, !dbg !198
// CHECK:STDOUT:   store i32 %self, ptr %value, align 4, !dbg !198
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !200
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !200
// CHECK:STDOUT:   ret void, !dbg !201
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f"(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !203 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !210
// CHECK:STDOUT:   store i8 0, ptr %has_value, align 1, !dbg !210
// CHECK:STDOUT:   ret void, !dbg !211
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %self) #0 !dbg !212 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !217
// CHECK:STDOUT:   ret i32 %1, !dbg !219
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !221 {
// CHECK:STDOUT:   ret i32 %self, !dbg !227
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core", { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 3, 2, 1 }
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
// CHECK:STDOUT: !4 = !DIFile(filename: "break_continue.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!7, !6}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !6}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !{null, !7}
// CHECK:STDOUT: !17 = !DISubroutineType(types: !16)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "For", linkageName: "_CFor.Main", scope: null, file: !4, line: 17, type: !11, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !20 = !DILocation(line: 18, column: 18, scope: !18)
// CHECK:STDOUT: !21 = !DILocation(line: 18, column: 7, scope: !18)
// CHECK:STDOUT: !22 = !{!6, !7}
// CHECK:STDOUT: !23 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !24 = !{!7, !7, !6}
// CHECK:STDOUT: !25 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !26 = !{!7, !7}
// CHECK:STDOUT: !27 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !28 = !DILocation(line: 19, column: 9, scope: !18)
// CHECK:STDOUT: !29 = !DILocation(line: 19, column: 8, scope: !18)
// CHECK:STDOUT: !30 = !DILocation(line: 19, column: 16, scope: !18)
// CHECK:STDOUT: !31 = !DILocation(line: 20, column: 9, scope: !18)
// CHECK:STDOUT: !32 = !DILocation(line: 20, column: 8, scope: !18)
// CHECK:STDOUT: !33 = !DILocation(line: 20, column: 16, scope: !18)
// CHECK:STDOUT: !34 = !DILocation(line: 21, column: 5, scope: !18)
// CHECK:STDOUT: !35 = !DILocation(line: 18, column: 3, scope: !18)
// CHECK:STDOUT: !36 = !DILocation(line: 17, column: 1, scope: !18)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.a8a4e50b707d8bfe:core.Destroy.Core", scope: null, file: !4, line: 18, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !40)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !7)
// CHECK:STDOUT: !39 = !DILocation(line: 18, column: 7, scope: !37)
// CHECK:STDOUT: !40 = !{!38}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a8a4e50b707d8bfe:core.Destroy.Core", scope: null, file: !4, line: 18, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !7)
// CHECK:STDOUT: !43 = !DILocation(line: 18, column: 7, scope: !41)
// CHECK:STDOUT: !44 = !{!42}
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e933d5ff8212e171:core.Destroy.Core", scope: null, file: !4, line: 18, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !48)
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !45, type: !7)
// CHECK:STDOUT: !47 = !DILocation(line: 18, column: 18, scope: !45)
// CHECK:STDOUT: !48 = !{!46}
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e933d5ff8212e171:core.Destroy.Core", scope: null, file: !4, line: 18, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !52)
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !49, type: !7)
// CHECK:STDOUT: !51 = !DILocation(line: 18, column: 18, scope: !49)
// CHECK:STDOUT: !52 = !{!50}
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c9184c281ed4335d:core.Destroy.Core", scope: null, file: !4, line: 18, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !56)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !7)
// CHECK:STDOUT: !55 = !DILocation(line: 18, column: 18, scope: !53)
// CHECK:STDOUT: !56 = !{!54}
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c9184c281ed4335d:core.Destroy.Core", scope: null, file: !4, line: 18, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !60)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !57, type: !7)
// CHECK:STDOUT: !59 = !DILocation(line: 18, column: 18, scope: !57)
// CHECK:STDOUT: !60 = !{!58}
// CHECK:STDOUT: !63 = !DIFile(filename: "{{.*}}/prelude/range.carbon", directory: "")
// CHECK:STDOUT: !64 = distinct !DISubprogram(name: "NewCursor", linkageName: "_CNewCursor.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8", scope: null, file: !63, line: 19, type: !23, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !71)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 1, scope: !64, type: !7)
// CHECK:STDOUT: !69 = !DILocation(line: 19, column: 43, scope: !64)
// CHECK:STDOUT: !70 = !DILocation(line: 19, column: 36, scope: !64)
// CHECK:STDOUT: !71 = !{!65}
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "Next", linkageName: "_CNext.IntRange.9452f4c51951679b.Core:Iterate.Core.be1e879c1ad406d8", scope: null, file: !63, line: 20, type: !25, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !92)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !7)
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 2, scope: !72, type: !6)
// CHECK:STDOUT: !79 = !DILocation(line: 21, column: 7, scope: !72)
// CHECK:STDOUT: !80 = !DILocation(line: 21, column: 27, scope: !72)
// CHECK:STDOUT: !82 = !DILocation(line: 22, column: 11, scope: !72)
// CHECK:STDOUT: !83 = !DILocation(line: 22, column: 19, scope: !72)
// CHECK:STDOUT: !84 = !DILocation(line: 22, column: 10, scope: !72)
// CHECK:STDOUT: !86 = !DILocation(line: 23, column: 9, scope: !72)
// CHECK:STDOUT: !87 = !DILocation(line: 24, column: 38, scope: !72)
// CHECK:STDOUT: !88 = !DILocation(line: 24, column: 16, scope: !72)
// CHECK:STDOUT: !89 = !DILocation(line: 24, column: 9, scope: !72)
// CHECK:STDOUT: !90 = !DILocation(line: 26, column: 16, scope: !72)
// CHECK:STDOUT: !91 = !DILocation(line: 26, column: 9, scope: !72)
// CHECK:STDOUT: !92 = !{!73, !74}
// CHECK:STDOUT: !96 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !97 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.fc4496a6c25d418b", scope: null, file: !96, line: 37, type: !27, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !105)
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !97, type: !7)
// CHECK:STDOUT: !103 = !DILocation(line: 38, column: 12, scope: !97)
// CHECK:STDOUT: !104 = !DILocation(line: 38, column: 5, scope: !97)
// CHECK:STDOUT: !105 = !{!98}
// CHECK:STDOUT: !106 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.fc4496a6c25d418b", scope: null, file: !96, line: 40, type: !23, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !119)
// CHECK:STDOUT: !107 = !DILocalVariable(arg: 1, scope: !106, type: !7)
// CHECK:STDOUT: !111 = !DILocation(line: 374, column: 11, scope: !106)
// CHECK:STDOUT: !112 = !DILocation(line: 374, column: 7, scope: !106)
// CHECK:STDOUT: !113 = !DILocation(line: 374, column: 6, scope: !106)
// CHECK:STDOUT: !114 = !DILocation(line: 375, column: 5, scope: !106)
// CHECK:STDOUT: !115 = !DILocation(line: 374, column: 3, scope: !106)
// CHECK:STDOUT: !117 = !DILocation(line: 377, column: 10, scope: !106)
// CHECK:STDOUT: !118 = !DILocation(line: 377, column: 3, scope: !106)
// CHECK:STDOUT: !119 = !{!107}
// CHECK:STDOUT: !120 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.5f4a25925b904579", scope: null, file: !120, line: 26, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !127)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !121, type: !7)
// CHECK:STDOUT: !124 = !DILocation(line: 27, column: 5, scope: !121)
// CHECK:STDOUT: !125 = !DILocation(line: 28, column: 5, scope: !121)
// CHECK:STDOUT: !126 = !DILocation(line: 26, column: 3, scope: !121)
// CHECK:STDOUT: !127 = !{!122}
// CHECK:STDOUT: !128 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !129 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Int.9452f4c51951679b.Core:Inc.Core.be1e879c1ad406d8", scope: null, file: !128, line: 396, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !136)
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 1, scope: !129, type: !6)
// CHECK:STDOUT: !132 = !DILocation(line: 398, column: 5, scope: !129)
// CHECK:STDOUT: !133 = !{null, !6, !6}
// CHECK:STDOUT: !134 = !DISubroutineType(types: !133)
// CHECK:STDOUT: !135 = !DILocation(line: 396, column: 3, scope: !129)
// CHECK:STDOUT: !136 = !{!130}
// CHECK:STDOUT: !137 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.fc4496a6c25d418b", scope: null, file: !96, line: 34, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !144)
// CHECK:STDOUT: !138 = !DILocalVariable(arg: 1, scope: !137, type: !6)
// CHECK:STDOUT: !142 = !DILocation(line: 35, column: 12, scope: !137)
// CHECK:STDOUT: !143 = !DILocation(line: 35, column: 5, scope: !137)
// CHECK:STDOUT: !144 = !{!138}
// CHECK:STDOUT: !145 = distinct !DISubprogram(name: "None", linkageName: "_CNone.Optional.Core.fc4496a6c25d418b", scope: null, file: !96, line: 31, type: !9, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !148 = !DILocation(line: 32, column: 12, scope: !145)
// CHECK:STDOUT: !149 = !DILocation(line: 32, column: 5, scope: !145)
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !96, line: 166, type: !27, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !157)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 1, scope: !150, type: !7)
// CHECK:STDOUT: !155 = !DILocation(line: 167, column: 12, scope: !150)
// CHECK:STDOUT: !156 = !DILocation(line: 167, column: 5, scope: !150)
// CHECK:STDOUT: !157 = !{!151}
// CHECK:STDOUT: !158 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !96, line: 169, type: !23, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !165)
// CHECK:STDOUT: !159 = !DILocalVariable(arg: 1, scope: !158, type: !7)
// CHECK:STDOUT: !163 = !DILocation(line: 170, column: 12, scope: !158)
// CHECK:STDOUT: !164 = !DILocation(line: 170, column: 5, scope: !158)
// CHECK:STDOUT: !165 = !{!159}
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "Op", linkageName: "_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.4d9f279dbc2b9f6f", scope: null, file: !96, line: 355, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !175)
// CHECK:STDOUT: !167 = !DILocalVariable(arg: 1, scope: !166, type: !7)
// CHECK:STDOUT: !169 = !DILocation(line: 356, column: 9, scope: !166)
// CHECK:STDOUT: !170 = !DILocation(line: 356, column: 8, scope: !166)
// CHECK:STDOUT: !171 = !DILocation(line: 357, column: 8, scope: !166)
// CHECK:STDOUT: !172 = !DILocation(line: 357, column: 7, scope: !166)
// CHECK:STDOUT: !173 = !DILocation(line: 356, column: 5, scope: !166)
// CHECK:STDOUT: !174 = !DILocation(line: 355, column: 3, scope: !166)
// CHECK:STDOUT: !175 = !{!167}
// CHECK:STDOUT: !176 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.5f4a25925b904579", scope: null, file: !120, line: 19, type: !17, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !180)
// CHECK:STDOUT: !177 = !DILocalVariable(arg: 1, scope: !176, type: !7)
// CHECK:STDOUT: !179 = !DILocation(line: 19, column: 3, scope: !176)
// CHECK:STDOUT: !180 = !{!177}
// CHECK:STDOUT: !181 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:AddAssignWith.39e2e78a3c2e036d.Core:Int.9452f4c51951679b.Core:AddAssignWith.bcc2a64c00f3554f.Core.83481f1872d67895", scope: null, file: !128, line: 331, type: !134, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !188)
// CHECK:STDOUT: !182 = !DILocalVariable(arg: 1, scope: !181, type: !6)
// CHECK:STDOUT: !183 = !DILocalVariable(arg: 2, scope: !181, type: !6)
// CHECK:STDOUT: !184 = !DILocation(line: 0, scope: !181)
// CHECK:STDOUT: !185 = !DILocation(line: 331, column: 3, scope: !181)
// CHECK:STDOUT: !186 = !{!6, !6}
// CHECK:STDOUT: !187 = !DISubroutineType(types: !186)
// CHECK:STDOUT: !188 = !{!182, !183}
// CHECK:STDOUT: !189 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !96, line: 156, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !202)
// CHECK:STDOUT: !190 = !DILocalVariable(arg: 1, scope: !189, type: !6)
// CHECK:STDOUT: !198 = !DILocation(line: 162, column: 5, scope: !189)
// CHECK:STDOUT: !200 = !DILocation(line: 163, column: 5, scope: !189)
// CHECK:STDOUT: !201 = !DILocation(line: 164, column: 5, scope: !189)
// CHECK:STDOUT: !202 = !{!190}
// CHECK:STDOUT: !203 = distinct !DISubprogram(name: "None", linkageName: "_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.4d9f279dbc2b9f6f", scope: null, file: !96, line: 150, type: !9, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !210 = !DILocation(line: 153, column: 5, scope: !203)
// CHECK:STDOUT: !211 = !DILocation(line: 154, column: 5, scope: !203)
// CHECK:STDOUT: !212 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044", scope: null, file: !128, line: 64, type: !187, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !220)
// CHECK:STDOUT: !213 = !DILocalVariable(arg: 1, scope: !212, type: !6)
// CHECK:STDOUT: !217 = !DILocation(line: 66, column: 17, scope: !212)
// CHECK:STDOUT: !219 = !DILocation(line: 66, column: 5, scope: !212)
// CHECK:STDOUT: !220 = !{!213}
// CHECK:STDOUT: !221 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !128, line: 59, type: !187, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !228)
// CHECK:STDOUT: !222 = !DILocalVariable(arg: 1, scope: !221, type: !6)
// CHECK:STDOUT: !227 = !DILocation(line: 59, column: 28, scope: !221)
// CHECK:STDOUT: !228 = !{!222}
// CHECK:STDOUT:
