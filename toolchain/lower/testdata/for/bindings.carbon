// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/for/bindings.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/for/bindings.carbon

class EmptyRange(T: Core.Copy & Core.Destroy) {
  impl as Core.Iterate where .CursorType = {} and .ElementType = T {
    fn NewCursor(unused self) -> {} {
      return {};
    }
    fn Next(unused self, _: {}*) -> Core.Optional(T) {
      return Core.Optional(T).None();
    }
  }
}

fn F(m: i32, n: i32*);

fn For() {
  var r: EmptyRange((i32, i32)) = {};

  for ((m: i32, var n: i32) in r) {
    F(m, &n);
  }
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'bindings.carbon'
// CHECK:STDOUT: source_filename = "bindings.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @EmptyRange.val.loc27_3 = internal constant {} zeroinitializer
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 57 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cb8adced19392b99:core.Destroy.Core"(ptr %self) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CF.Main(i32, ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CFor.Main() #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %r.var = alloca {}, align 1, !dbg !21
// CHECK:STDOUT:   %n.var = alloca i32, align 4, !dbg !23
// CHECK:STDOUT:   %var = alloca {}, align 1, !dbg !26
// CHECK:STDOUT:   %.loc29_33.1.temp = alloca <{ { i32, i32 }, i1 }>, align 4, !dbg !26
// CHECK:STDOUT:   %.loc29_33.8.temp = alloca { i32, i32 }, align 4, !dbg !26
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %r.var), !dbg !21
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %r.var, ptr align 1 @EmptyRange.val.loc27_3, i64 0, i1 false), !dbg !21
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %n.var), !dbg !23
// CHECK:STDOUT:   call void @"_CNewCursor.EmptyRange.a081b942542726db.Main:Iterate.Core.2e30d2d7a87a6cd3"(ptr %r.var), !dbg !26
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %var), !dbg !26
// CHECK:STDOUT:   br label %for.next, !dbg !26
// CHECK:STDOUT:
// CHECK:STDOUT: for.next:                                         ; preds = %for.body, %entry
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc29_33.1.temp), !dbg !26
// CHECK:STDOUT:   call void @"_CNext.EmptyRange.a081b942542726db.Main:Iterate.Core.2e30d2d7a87a6cd3"(ptr %.loc29_33.1.temp, ptr %r.var, ptr %var), !dbg !26
// CHECK:STDOUT:   %Optional.HasValue.call = call i1 @_CHasValue.Optional.Core.b20cf0d1c9daa8c2(ptr %.loc29_33.1.temp), !dbg !26
// CHECK:STDOUT:   br i1 %Optional.HasValue.call, label %for.body, label %for.done, !dbg !26
// CHECK:STDOUT:
// CHECK:STDOUT: for.body:                                         ; preds = %for.next
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc29_33.8.temp), !dbg !26
// CHECK:STDOUT:   call void @_CGet.Optional.Core.b20cf0d1c9daa8c2(ptr %.loc29_33.8.temp, ptr %.loc29_33.1.temp), !dbg !26
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc29_33.8.temp, i32 0, i32 0, !dbg !26
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %.loc29_33.8.temp, i32 0, i32 1, !dbg !26
// CHECK:STDOUT:   %.loc29_33.11 = load i32, ptr %tuple.elem0.tuple.elem, align 4, !dbg !26
// CHECK:STDOUT:   %.loc29_33.12 = load i32, ptr %tuple.elem1.tuple.elem, align 4, !dbg !26
// CHECK:STDOUT:   store i32 %.loc29_33.12, ptr %n.var, align 4, !dbg !23
// CHECK:STDOUT:   call void @_CF.Main(i32 %.loc29_33.11, ptr %n.var), !dbg !36
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %.loc29_33.8.temp), !dbg !26
// CHECK:STDOUT:   call void @"_CSelfDestruct.e1dbefa6145042b5:core.Destroy.Core"(ptr %.loc29_33.1.temp), !dbg !26
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %n.var), !dbg !23
// CHECK:STDOUT:   br label %for.next, !dbg !37
// CHECK:STDOUT:
// CHECK:STDOUT: for.done:                                         ; preds = %for.next
// CHECK:STDOUT:   call void @"_CSelfDestruct.e1dbefa6145042b5:core.Destroy.Core"(ptr %.loc29_33.1.temp), !dbg !26
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %n.var), !dbg !23
// CHECK:STDOUT:   call void @"_CSelfDestruct.cb8adced19392b99:core.Destroy.Core"(ptr %var), !dbg !26
// CHECK:STDOUT:   call void @"_CSelfDestruct.454683f3b8639b20:core.Destroy.Core"(ptr %r.var), !dbg !21
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !45
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !45
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !45
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %self) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core"(ptr %self), !dbg !49
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e1dbefa6145042b5:core.Destroy.Core"(ptr %self) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.17c70772d66c7eb2(ptr %self), !dbg !53
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e1dbefa6145042b5:core.Destroy.Core"(ptr %self) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e1dbefa6145042b5:core.Destroy.Core"(ptr %self), !dbg !57
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.454683f3b8639b20:core.Destroy.Core"(ptr %self) #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNewCursor.EmptyRange.a081b942542726db.Main:Iterate.Core.2e30d2d7a87a6cd3"(ptr %self) #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNext.EmptyRange.a081b942542726db.Main:Iterate.Core.2e30d2d7a87a6cd3"(ptr sret(<{ { i32, i32 }, i1 }>) %return, ptr %self, ptr %_) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CNone.Optional.Core.b20cf0d1c9daa8c2(ptr %return), !dbg !77
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.b20cf0d1c9daa8c2(ptr %self) #0 !dbg !86 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.2e30d2d7a87a6cd3"(ptr %self), !dbg !92
// CHECK:STDOUT:   ret i1 %1, !dbg !93
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CGet.Optional.Core.b20cf0d1c9daa8c2(ptr sret({ i32, i32 }) %return, ptr %self) #0 !dbg !95 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.b20cf0d1c9daa8c2(ptr %self), !dbg !100
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
// CHECK:STDOUT:   call void @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.2e30d2d7a87a6cd3"(ptr %return, ptr %self), !dbg !106
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.17c70772d66c7eb2(ptr %self) #0 !dbg !110 {
// CHECK:STDOUT:   call void @"_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.2e30d2d7a87a6cd3"(ptr %self), !dbg !113
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.17c70772d66c7eb2(ptr %self), !dbg !114
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CNone.Optional.Core.b20cf0d1c9daa8c2(ptr sret(<{ { i32, i32 }, i1 }>) %return) #0 !dbg !117 {
// CHECK:STDOUT:   call void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.2e30d2d7a87a6cd3"(ptr %return), !dbg !120
// CHECK:STDOUT:   ret void, !dbg !121
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.2e30d2d7a87a6cd3"(ptr %value) #0 !dbg !122 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ { i32, i32 }, i1 }>, ptr %value, i32 0, i32 1, !dbg !127
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !127
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !127
// CHECK:STDOUT:   ret i1 %2, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.2e30d2d7a87a6cd3"(ptr sret({ i32, i32 }) %return, ptr %value) #0 !dbg !130 {
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw <{ { i32, i32 }, i1 }>, ptr %value, i32 0, i32 0, !dbg !135
// CHECK:STDOUT:   call void @"_COp.4e4edddc7580c79b:Copy.Core.8608f3c6f62d80cb"(ptr %return, ptr %value1), !dbg !135
// CHECK:STDOUT:   ret void, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.2e30d2d7a87a6cd3"(ptr %self) #0 !dbg !138 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ { i32, i32 }, i1 }>, ptr %self, i32 0, i32 1, !dbg !141
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !141
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !141
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !142
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ { i32, i32 }, i1 }>, ptr %self, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   call void @"_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core"(ptr %value), !dbg !144
// CHECK:STDOUT:   br label %4, !dbg !145
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %3, %0
// CHECK:STDOUT:   ret void, !dbg !146
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.17c70772d66c7eb2(ptr %self) #0 !dbg !148 {
// CHECK:STDOUT:   ret void, !dbg !151
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.2e30d2d7a87a6cd3"(ptr sret(<{ { i32, i32 }, i1 }>) %return) #0 !dbg !153 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ { i32, i32 }, i1 }>, ptr %return, i32 0, i32 1, !dbg !160
// CHECK:STDOUT:   store i8 0, ptr %has_value, align 1, !dbg !160
// CHECK:STDOUT:   ret void, !dbg !161
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.4e4edddc7580c79b:Copy.Core.8608f3c6f62d80cb"(ptr sret({ i32, i32 }) %return, ptr %self) #0 !dbg !163 {
// CHECK:STDOUT:   %tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 0, !dbg !168
// CHECK:STDOUT:   %tuple.elem.load = load i32, ptr %tuple.elem, align 4, !dbg !168
// CHECK:STDOUT:   %tuple.elem1 = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !169
// CHECK:STDOUT:   %tuple.elem2 = getelementptr inbounds nuw { i32, i32 }, ptr %self, i32 0, i32 1, !dbg !170
// CHECK:STDOUT:   %tuple.elem.load3 = load i32, ptr %tuple.elem2, align 4, !dbg !170
// CHECK:STDOUT:   %tuple.elem4 = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !169
// CHECK:STDOUT:   store i32 %tuple.elem.load, ptr %tuple.elem1, align 4, !dbg !169
// CHECK:STDOUT:   store i32 %tuple.elem.load3, ptr %tuple.elem4, align 4, !dbg !169
// CHECK:STDOUT:   ret void, !dbg !171
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core", { 0, 1, 3, 2 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.e1dbefa6145042b5:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 4, 3, 2, 1, 0 }
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
// CHECK:STDOUT: !4 = !DIFile(filename: "bindings.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{null, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !12 = !{null}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !6}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cb8adced19392b99:core.Destroy.Core", scope: null, file: !4, line: 14, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !19)
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !16, type: !7)
// CHECK:STDOUT: !18 = !DILocation(line: 14, column: 44, scope: !16)
// CHECK:STDOUT: !19 = !{!17}
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "For", linkageName: "_CFor.Main", scope: null, file: !4, line: 26, type: !13, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !21 = !DILocation(line: 27, column: 3, scope: !20)
// CHECK:STDOUT: !23 = !DILocation(line: 29, column: 17, scope: !20)
// CHECK:STDOUT: !26 = !DILocation(line: 29, column: 7, scope: !20)
// CHECK:STDOUT: !27 = !{!7, !7, !7}
// CHECK:STDOUT: !28 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !29 = !{!7, !7}
// CHECK:STDOUT: !30 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !36 = !DILocation(line: 30, column: 5, scope: !20)
// CHECK:STDOUT: !37 = !DILocation(line: 29, column: 3, scope: !20)
// CHECK:STDOUT: !38 = !DILocation(line: 26, column: 1, scope: !20)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 27, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !6)
// CHECK:STDOUT: !41 = !DILocation(line: 27, column: 10, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !4, line: 27, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 27, column: 10, scope: !43)
// CHECK:STDOUT: !46 = !{!44}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e554695bf635d9c1:core.Destroy.Core", scope: null, file: !4, line: 27, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !50)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !7)
// CHECK:STDOUT: !49 = !DILocation(line: 27, column: 10, scope: !47)
// CHECK:STDOUT: !50 = !{!48}
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e1dbefa6145042b5:core.Destroy.Core", scope: null, file: !4, line: 29, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !54)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !7)
// CHECK:STDOUT: !53 = !DILocation(line: 29, column: 7, scope: !51)
// CHECK:STDOUT: !54 = !{!52}
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e1dbefa6145042b5:core.Destroy.Core", scope: null, file: !4, line: 29, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !55, type: !7)
// CHECK:STDOUT: !57 = !DILocation(line: 29, column: 7, scope: !55)
// CHECK:STDOUT: !58 = !{!56}
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.454683f3b8639b20:core.Destroy.Core", scope: null, file: !4, line: 27, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !62)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !59, type: !7)
// CHECK:STDOUT: !61 = !DILocation(line: 27, column: 3, scope: !59)
// CHECK:STDOUT: !62 = !{!60}
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "NewCursor", linkageName: "_CNewCursor.EmptyRange.a081b942542726db.Main:Iterate.Core.2e30d2d7a87a6cd3", scope: null, file: !4, line: 15, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !69)
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !63, type: !7)
// CHECK:STDOUT: !68 = !DILocation(line: 16, column: 7, scope: !63)
// CHECK:STDOUT: !69 = !{!64}
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "Next", linkageName: "_CNext.EmptyRange.a081b942542726db.Main:Iterate.Core.2e30d2d7a87a6cd3", scope: null, file: !4, line: 18, type: !28, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !81)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !7)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 2, scope: !70, type: !7)
// CHECK:STDOUT: !77 = !DILocation(line: 19, column: 14, scope: !70)
// CHECK:STDOUT: !78 = !{!7}
// CHECK:STDOUT: !79 = !DISubroutineType(types: !78)
// CHECK:STDOUT: !80 = !DILocation(line: 19, column: 7, scope: !70)
// CHECK:STDOUT: !81 = !{!71, !72}
// CHECK:STDOUT: !85 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.b20cf0d1c9daa8c2", scope: null, file: !85, line: 37, type: !30, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !94)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !86, type: !7)
// CHECK:STDOUT: !92 = !DILocation(line: 38, column: 12, scope: !86)
// CHECK:STDOUT: !93 = !DILocation(line: 38, column: 5, scope: !86)
// CHECK:STDOUT: !94 = !{!87}
// CHECK:STDOUT: !95 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.b20cf0d1c9daa8c2", scope: null, file: !85, line: 40, type: !30, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !108)
// CHECK:STDOUT: !96 = !DILocalVariable(arg: 1, scope: !95, type: !7)
// CHECK:STDOUT: !100 = !DILocation(line: 303, column: 11, scope: !95)
// CHECK:STDOUT: !101 = !DILocation(line: 303, column: 7, scope: !95)
// CHECK:STDOUT: !102 = !DILocation(line: 303, column: 6, scope: !95)
// CHECK:STDOUT: !103 = !DILocation(line: 304, column: 5, scope: !95)
// CHECK:STDOUT: !104 = !DILocation(line: 303, column: 3, scope: !95)
// CHECK:STDOUT: !106 = !DILocation(line: 306, column: 10, scope: !95)
// CHECK:STDOUT: !107 = !DILocation(line: 306, column: 3, scope: !95)
// CHECK:STDOUT: !108 = !{!96}
// CHECK:STDOUT: !109 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.17c70772d66c7eb2", scope: null, file: !109, line: 26, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !116)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !7)
// CHECK:STDOUT: !113 = !DILocation(line: 27, column: 5, scope: !110)
// CHECK:STDOUT: !114 = !DILocation(line: 28, column: 5, scope: !110)
// CHECK:STDOUT: !115 = !DILocation(line: 26, column: 3, scope: !110)
// CHECK:STDOUT: !116 = !{!111}
// CHECK:STDOUT: !117 = distinct !DISubprogram(name: "None", linkageName: "_CNone.Optional.Core.b20cf0d1c9daa8c2", scope: null, file: !85, line: 31, type: !79, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !120 = !DILocation(line: 32, column: 12, scope: !117)
// CHECK:STDOUT: !121 = !DILocation(line: 32, column: 5, scope: !117)
// CHECK:STDOUT: !122 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.2e30d2d7a87a6cd3", scope: null, file: !85, line: 166, type: !30, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !129)
// CHECK:STDOUT: !123 = !DILocalVariable(arg: 1, scope: !122, type: !7)
// CHECK:STDOUT: !127 = !DILocation(line: 167, column: 12, scope: !122)
// CHECK:STDOUT: !128 = !DILocation(line: 167, column: 5, scope: !122)
// CHECK:STDOUT: !129 = !{!123}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.5d6f3f3a4b44a8f1:OptionalStorage.Core.2e30d2d7a87a6cd3", scope: null, file: !85, line: 169, type: !30, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !137)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !7)
// CHECK:STDOUT: !135 = !DILocation(line: 170, column: 12, scope: !130)
// CHECK:STDOUT: !136 = !DILocation(line: 170, column: 5, scope: !130)
// CHECK:STDOUT: !137 = !{!131}
// CHECK:STDOUT: !138 = distinct !DISubprogram(name: "Op", linkageName: "_COp.DefaultOptionalStorage.a081b942542726db.Core:Destroy.Core.2e30d2d7a87a6cd3", scope: null, file: !85, line: 284, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !147)
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !138, type: !7)
// CHECK:STDOUT: !141 = !DILocation(line: 285, column: 9, scope: !138)
// CHECK:STDOUT: !142 = !DILocation(line: 285, column: 8, scope: !138)
// CHECK:STDOUT: !143 = !DILocation(line: 286, column: 8, scope: !138)
// CHECK:STDOUT: !144 = !DILocation(line: 286, column: 7, scope: !138)
// CHECK:STDOUT: !145 = !DILocation(line: 285, column: 5, scope: !138)
// CHECK:STDOUT: !146 = !DILocation(line: 284, column: 3, scope: !138)
// CHECK:STDOUT: !147 = !{!139}
// CHECK:STDOUT: !148 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.17c70772d66c7eb2", scope: null, file: !109, line: 19, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !152)
// CHECK:STDOUT: !149 = !DILocalVariable(arg: 1, scope: !148, type: !7)
// CHECK:STDOUT: !151 = !DILocation(line: 19, column: 3, scope: !148)
// CHECK:STDOUT: !152 = !{!149}
// CHECK:STDOUT: !153 = distinct !DISubprogram(name: "None", linkageName: "_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.2e30d2d7a87a6cd3", scope: null, file: !85, line: 150, type: !79, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !160 = !DILocation(line: 153, column: 5, scope: !153)
// CHECK:STDOUT: !161 = !DILocation(line: 154, column: 5, scope: !153)
// CHECK:STDOUT: !162 = !DIFile(filename: "{{.*}}/prelude/copy.carbon", directory: "")
// CHECK:STDOUT: !163 = distinct !DISubprogram(name: "Op", linkageName: "_COp.4e4edddc7580c79b:Copy.Core.8608f3c6f62d80cb", scope: null, file: !162, line: 62, type: !30, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !172)
// CHECK:STDOUT: !164 = !DILocalVariable(arg: 1, scope: !163, type: !7)
// CHECK:STDOUT: !168 = !DILocation(line: 63, column: 13, scope: !163)
// CHECK:STDOUT: !169 = !DILocation(line: 63, column: 12, scope: !163)
// CHECK:STDOUT: !170 = !DILocation(line: 63, column: 26, scope: !163)
// CHECK:STDOUT: !171 = !DILocation(line: 63, column: 5, scope: !163)
// CHECK:STDOUT: !172 = !{!164}
// CHECK:STDOUT:
