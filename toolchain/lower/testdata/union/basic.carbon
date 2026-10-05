// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/union/basic.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/union/basic.carbon

// Lowering of native unions needs no union-specific code: the
// `custom_layout_type` representation lowers to `[N x i8]`, every field
// access is a byte-offset GEP at offset 0, the designated initializer is a
// plain store, and the synthesized copy witness is a memcpy of all `size(U)`
// bytes (docs/design/unions.md, "Layout"; fork/unions/plan.md §4.A).

// --- unformed_local.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn UnformedLocal() -> i32 {
  var u: IntOrBytes;
  u.word = 5;
  return u.word;
}

// --- designated_init.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn DesignatedInit() -> i32 {
  var v: IntOrBytes = {.word = 5};
  var b: IntOrBytes = {.bytes = (1, 2, 3, 4)};
  return v.word + (b.bytes[3] as i32);
}

// --- copy.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn Copy(v: IntOrBytes) -> i32 {
  var w: IntOrBytes = v;
  w = v;
  return w.word;
}

// --- user_copy_impl_shadowed.carbon
library "[[@TEST_NAME]]";

union Shadowed {
  var a: i32;
  impl as Core.Copy {
    // CHECK:STDERR: user_copy_impl_shadowed.carbon:[[@LINE+4]]:11: warning: binding `self` unused [UnusedBinding]
    // CHECK:STDERR:     fn Op(self) -> Self { return {.a = 0}; }
    // CHECK:STDERR:           ^~~~
    // CHECK:STDERR:
    fn Op(self) -> Self { return {.a = 0}; }
  }
}

fn CopyShadowed(x: Shadowed) -> i32 {
  var y: Shadowed = x;
  return y.a;
}

// --- optional_pointer_field.carbon
library "[[@TEST_NAME]]";

union OptPtr {
  var o: Core.Optional(i32*);
  var n: i64;
}

fn CopyOptPtr(p: OptPtr) -> i64 {
  var q: OptPtr = p;
  return q.n;
}

// --- method.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);

  fn LowHalf(self) -> i32 { return self.bytes[0] as i32; }
  fn Set(ref self, x: i32) { self.word = x; }
}

fn UseMethods(u: IntOrBytes) -> i32 {
  var v: IntOrBytes = u;
  v.Set(3);
  return v.LowHalf();
}

// --- by_pointer.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

fn Read(u: IntOrBytes) -> i32 { return u.word; }

fn Write(p: IntOrBytes*) { p->word = 1; }

// --- file_scope_union.carbon
library "[[@TEST_NAME]]";

union IntOrBytes {
  var word: i32;
  var bytes: array(i8, 4);
}

var g: IntOrBytes = {.word = 5};

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'unformed_local.carbon'
// CHECK:STDOUT: source_filename = "unformed_local.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUnformedLocal.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %u.var = alloca [4 x i8], align 4, !dbg !8
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %u.var), !dbg !8
// CHECK:STDOUT:   %.loc10_4.word = getelementptr inbounds nuw [4 x i8], ptr %u.var, i32 0, i32 0, !dbg !9
// CHECK:STDOUT:   store i32 5, ptr %.loc10_4.word, align 4, !dbg !9
// CHECK:STDOUT:   %.loc11_11.1.word = getelementptr inbounds nuw [4 x i8], ptr %u.var, i32 0, i32 0, !dbg !10
// CHECK:STDOUT:   %.loc11_11.2 = load i32, ptr %.loc11_11.1.word, align 4, !dbg !10
// CHECK:STDOUT:   call void @"_COp.e2e991cf29b775ca:core.Destroy.Core"(ptr %u.var), !dbg !8
// CHECK:STDOUT:   ret i32 %.loc11_11.2, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.136cbc434fe80552:core.Destroy.Core"(ptr %self) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.d53db3d156fa3ea4:core.Destroy.Core"(ptr %self) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.928e9c0682a9e341:core.Destroy.Core"(ptr %self) #0 !dbg !32 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.e2e991cf29b775ca:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "unformed_local.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "UnformedLocal", linkageName: "_CUnformedLocal.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 9, column: 3, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 10, column: 3, scope: !4)
// CHECK:STDOUT: !10 = !DILocation(line: 11, column: 10, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 11, column: 3, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 9, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !15)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{null, !7}
// CHECK:STDOUT: !15 = !{!16}
// CHECK:STDOUT: !16 = !DILocalVariable(arg: 1, scope: !12, type: !7)
// CHECK:STDOUT: !17 = !DILocation(line: 9, column: 3, scope: !12)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Op", linkageName: "_COp.136cbc434fe80552:core.Destroy.Core", scope: null, file: !1, line: 9, type: !19, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !22)
// CHECK:STDOUT: !19 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !20 = !{null, !21}
// CHECK:STDOUT: !21 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !22 = !{!23}
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 1, scope: !18, type: !21)
// CHECK:STDOUT: !24 = !DILocation(line: 9, column: 3, scope: !18)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Op", linkageName: "_COp.d53db3d156fa3ea4:core.Destroy.Core", scope: null, file: !1, line: 9, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !29)
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{null, !28}
// CHECK:STDOUT: !28 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !29 = !{!30}
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 1, scope: !25, type: !28)
// CHECK:STDOUT: !31 = !DILocation(line: 9, column: 3, scope: !25)
// CHECK:STDOUT: !32 = distinct !DISubprogram(name: "Op", linkageName: "_COp.928e9c0682a9e341:core.Destroy.Core", scope: null, file: !1, line: 9, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !33)
// CHECK:STDOUT: !33 = !{!34}
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !32, type: !28)
// CHECK:STDOUT: !35 = !DILocation(line: 9, column: 3, scope: !32)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e2e991cf29b775ca:core.Destroy.Core", scope: null, file: !1, line: 9, type: !26, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !37)
// CHECK:STDOUT: !37 = !{!38}
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !36, type: !28)
// CHECK:STDOUT: !39 = !DILocation(line: 9, column: 3, scope: !36)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'designated_init.carbon'
// CHECK:STDOUT: source_filename = "designated_init.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @array.loc10_45.3 = internal constant [4 x i8] c"\01\02\03\04"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CDesignatedInit.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca [4 x i8], align 4, !dbg !8
// CHECK:STDOUT:   %b.var = alloca [4 x i8], align 4, !dbg !9
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !8
// CHECK:STDOUT:   %.loc9_33.3.word = getelementptr inbounds nuw [4 x i8], ptr %v.var, i32 0, i32 0, !dbg !10
// CHECK:STDOUT:   store i32 5, ptr %.loc9_33.3.word, align 4, !dbg !10
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !9
// CHECK:STDOUT:   %.loc10_45.2.bytes = getelementptr inbounds nuw [4 x i8], ptr %b.var, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc10_44.3.array.index = getelementptr inbounds [4 x i8], ptr %.loc10_45.2.bytes, i32 0, i64 0, !dbg !12
// CHECK:STDOUT:   %.loc10_44.6.array.index = getelementptr inbounds [4 x i8], ptr %.loc10_45.2.bytes, i32 0, i64 1, !dbg !12
// CHECK:STDOUT:   %.loc10_44.9.array.index = getelementptr inbounds [4 x i8], ptr %.loc10_45.2.bytes, i32 0, i64 2, !dbg !12
// CHECK:STDOUT:   %.loc10_44.12.array.index = getelementptr inbounds [4 x i8], ptr %.loc10_45.2.bytes, i32 0, i64 3, !dbg !12
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %.loc10_45.2.bytes, ptr align 1 @array.loc10_45.3, i64 4, i1 false), !dbg !11
// CHECK:STDOUT:   %.loc11_11.1.word = getelementptr inbounds nuw [4 x i8], ptr %v.var, i32 0, i32 0, !dbg !13
// CHECK:STDOUT:   %.loc11_21.bytes = getelementptr inbounds nuw [4 x i8], ptr %b.var, i32 0, i32 0, !dbg !14
// CHECK:STDOUT:   %.loc11_29.1.array.index = getelementptr inbounds [4 x i8], ptr %.loc11_21.bytes, i32 0, i32 3, !dbg !14
// CHECK:STDOUT:   %.loc11_29.2 = load i8, ptr %.loc11_29.1.array.index, align 1, !dbg !14
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call = sext i8 %.loc11_29.2 to i32, !dbg !14
// CHECK:STDOUT:   %.loc11_11.2 = load i32, ptr %.loc11_11.1.word, align 4, !dbg !13
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc11_11.2, %Int.as.As.impl.Convert.call, !dbg !13
// CHECK:STDOUT:   call void @"_COp.e2e991cf29b775ca:core.Destroy.Core"(ptr %b.var), !dbg !9
// CHECK:STDOUT:   call void @"_COp.e2e991cf29b775ca:core.Destroy.Core"(ptr %v.var), !dbg !8
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.136cbc434fe80552:core.Destroy.Core"(ptr %self) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.d53db3d156fa3ea4:core.Destroy.Core"(ptr %self) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.928e9c0682a9e341:core.Destroy.Core"(ptr %self) #0 !dbg !36 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.e2e991cf29b775ca:core.Destroy.Core"(ptr %self) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_COp.e2e991cf29b775ca:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "designated_init.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "DesignatedInit", linkageName: "_CDesignatedInit.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DILocation(line: 9, column: 3, scope: !4)
// CHECK:STDOUT: !9 = !DILocation(line: 10, column: 3, scope: !4)
// CHECK:STDOUT: !10 = !DILocation(line: 9, column: 23, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 10, column: 23, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 10, column: 33, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 11, column: 10, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 11, column: 20, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 11, column: 3, scope: !4)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 10, type: !17, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !19)
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{null, !7}
// CHECK:STDOUT: !19 = !{!20}
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !16, type: !7)
// CHECK:STDOUT: !21 = !DILocation(line: 10, column: 3, scope: !16)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "Op", linkageName: "_COp.136cbc434fe80552:core.Destroy.Core", scope: null, file: !1, line: 10, type: !23, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
// CHECK:STDOUT: !23 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !24 = !{null, !25}
// CHECK:STDOUT: !25 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !26 = !{!27}
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !22, type: !25)
// CHECK:STDOUT: !28 = !DILocation(line: 10, column: 3, scope: !22)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Op", linkageName: "_COp.d53db3d156fa3ea4:core.Destroy.Core", scope: null, file: !1, line: 10, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !33)
// CHECK:STDOUT: !30 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !31 = !{null, !32}
// CHECK:STDOUT: !32 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !33 = !{!34}
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !29, type: !32)
// CHECK:STDOUT: !35 = !DILocation(line: 10, column: 3, scope: !29)
// CHECK:STDOUT: !36 = distinct !DISubprogram(name: "Op", linkageName: "_COp.928e9c0682a9e341:core.Destroy.Core", scope: null, file: !1, line: 10, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !37)
// CHECK:STDOUT: !37 = !{!38}
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !36, type: !32)
// CHECK:STDOUT: !39 = !DILocation(line: 10, column: 3, scope: !36)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e2e991cf29b775ca:core.Destroy.Core", scope: null, file: !1, line: 10, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !41)
// CHECK:STDOUT: !41 = !{!42}
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !40, type: !32)
// CHECK:STDOUT: !43 = !DILocation(line: 10, column: 3, scope: !40)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'copy.carbon'
// CHECK:STDOUT: source_filename = "copy.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCopy.Main(ptr %v) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %w.var = alloca [4 x i8], align 4, !dbg !11
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %w.var), !dbg !11
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %w.var, ptr align 4 %v, i64 4, i1 false), !dbg !12
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %w.var, ptr align 4 %v, i64 4, i1 false), !dbg !13
// CHECK:STDOUT:   %.loc11_11.1.word = getelementptr inbounds nuw [4 x i8], ptr %w.var, i32 0, i32 0, !dbg !14
// CHECK:STDOUT:   %.loc11_11.2 = load i32, ptr %.loc11_11.1.word, align 4, !dbg !14
// CHECK:STDOUT:   call void @"_COp.e2e991cf29b775ca:core.Destroy.Core"(ptr %w.var), !dbg !11
// CHECK:STDOUT:   ret i32 %.loc11_11.2, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.136cbc434fe80552:core.Destroy.Core"(ptr %self) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.d53db3d156fa3ea4:core.Destroy.Core"(ptr %self) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.928e9c0682a9e341:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.e2e991cf29b775ca:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "copy.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Copy", linkageName: "_CCopy.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 9, column: 3, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 9, column: 23, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 10, column: 7, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 11, column: 10, scope: !4)
// CHECK:STDOUT: !15 = !DILocation(line: 11, column: 3, scope: !4)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 9, type: !17, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !19)
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{null, !7}
// CHECK:STDOUT: !19 = !{!20}
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !16, type: !7)
// CHECK:STDOUT: !21 = !DILocation(line: 9, column: 3, scope: !16)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "Op", linkageName: "_COp.136cbc434fe80552:core.Destroy.Core", scope: null, file: !1, line: 9, type: !23, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
// CHECK:STDOUT: !23 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !24 = !{null, !25}
// CHECK:STDOUT: !25 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !26 = !{!27}
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !22, type: !25)
// CHECK:STDOUT: !28 = !DILocation(line: 9, column: 3, scope: !22)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Op", linkageName: "_COp.d53db3d156fa3ea4:core.Destroy.Core", scope: null, file: !1, line: 9, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !32)
// CHECK:STDOUT: !30 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !31 = !{null, !8}
// CHECK:STDOUT: !32 = !{!33}
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !29, type: !8)
// CHECK:STDOUT: !34 = !DILocation(line: 9, column: 3, scope: !29)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.928e9c0682a9e341:core.Destroy.Core", scope: null, file: !1, line: 9, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !36)
// CHECK:STDOUT: !36 = !{!37}
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !35, type: !8)
// CHECK:STDOUT: !38 = !DILocation(line: 9, column: 3, scope: !35)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e2e991cf29b775ca:core.Destroy.Core", scope: null, file: !1, line: 9, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !40)
// CHECK:STDOUT: !40 = !{!41}
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !39, type: !8)
// CHECK:STDOUT: !42 = !DILocation(line: 9, column: 3, scope: !39)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'user_copy_impl_shadowed.carbon'
// CHECK:STDOUT: source_filename = "user_copy_impl_shadowed.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.Shadowed.Main:Copy.Core"(ptr sret([4 x i8]) %return, ptr %self) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_41.3.a = getelementptr inbounds nuw [4 x i8], ptr %return, i32 0, i32 0, !dbg !10
// CHECK:STDOUT:   store i32 0, ptr %.loc10_41.3.a, align 4, !dbg !10
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCopyShadowed.Main(ptr %x) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %y.var = alloca [4 x i8], align 4, !dbg !18
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %y.var), !dbg !18
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %y.var, ptr align 4 %x, i64 4, i1 false), !dbg !19
// CHECK:STDOUT:   %.loc16_11.1.a = getelementptr inbounds nuw [4 x i8], ptr %y.var, i32 0, i32 0, !dbg !20
// CHECK:STDOUT:   %.loc16_11.2 = load i32, ptr %.loc16_11.1.a, align 4, !dbg !20
// CHECK:STDOUT:   call void @"_COp.2910d0fa7b6c08b7:core.Destroy.Core"(ptr %y.var), !dbg !18
// CHECK:STDOUT:   ret i32 %.loc16_11.2, !dbg !21
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !22 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.8876f5884a3b4c95:core.Destroy.Core"(ptr %self) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.2910d0fa7b6c08b7:core.Destroy.Core"(ptr %self) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "user_copy_impl_shadowed.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Shadowed.Main:Copy.Core", scope: null, file: !1, line: 10, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 10, column: 34, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 10, column: 27, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "CopyShadowed", linkageName: "_CCopyShadowed.Main", scope: null, file: !1, line: 14, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!15, !7}
// CHECK:STDOUT: !15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !12, type: !7)
// CHECK:STDOUT: !18 = !DILocation(line: 15, column: 3, scope: !12)
// CHECK:STDOUT: !19 = !DILocation(line: 15, column: 21, scope: !12)
// CHECK:STDOUT: !20 = !DILocation(line: 16, column: 10, scope: !12)
// CHECK:STDOUT: !21 = !DILocation(line: 16, column: 3, scope: !12)
// CHECK:STDOUT: !22 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 15, type: !23, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
// CHECK:STDOUT: !23 = !DISubroutineType(types: !24)
// CHECK:STDOUT: !24 = !{null, !15}
// CHECK:STDOUT: !25 = !{!26}
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !22, type: !15)
// CHECK:STDOUT: !27 = !DILocation(line: 15, column: 3, scope: !22)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Op", linkageName: "_COp.8876f5884a3b4c95:core.Destroy.Core", scope: null, file: !1, line: 15, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !31)
// CHECK:STDOUT: !29 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !30 = !{null, !7}
// CHECK:STDOUT: !31 = !{!32}
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !28, type: !7)
// CHECK:STDOUT: !33 = !DILocation(line: 15, column: 3, scope: !28)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Op", linkageName: "_COp.2910d0fa7b6c08b7:core.Destroy.Core", scope: null, file: !1, line: 15, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !34, type: !7)
// CHECK:STDOUT: !37 = !DILocation(line: 15, column: 3, scope: !34)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'optional_pointer_field.carbon'
// CHECK:STDOUT: source_filename = "optional_pointer_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCopyOptPtr.Main(ptr %p) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %q.var = alloca [8 x i8], align 8, !dbg !11
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %q.var), !dbg !11
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %q.var, ptr align 8 %p, i64 8, i1 false), !dbg !12
// CHECK:STDOUT:   %.loc10_11.1.n = getelementptr inbounds nuw [8 x i8], ptr %q.var, i32 0, i32 0, !dbg !13
// CHECK:STDOUT:   %.loc10_11.2 = load i64, ptr %.loc10_11.1.n, align 8, !dbg !13
// CHECK:STDOUT:   call void @"_COp.4409554a32d15e06:core.Destroy.Core"(ptr %q.var), !dbg !11
// CHECK:STDOUT:   ret i64 %.loc10_11.2, !dbg !14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.8da6098981b7fee3:core.Destroy.Core"(ptr %self) #0 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.59abebc75eab0036:core.Destroy.Core"(ptr %self) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.77d64100f3a87f7e:core.Destroy.Core"(ptr %self) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.77b277584f162e02:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.4409554a32d15e06:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "optional_pointer_field.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "CopyOptPtr", linkageName: "_CCopyOptPtr.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 9, column: 3, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 9, column: 19, scope: !4)
// CHECK:STDOUT: !13 = !DILocation(line: 10, column: 10, scope: !4)
// CHECK:STDOUT: !14 = !DILocation(line: 10, column: 3, scope: !4)
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Op", linkageName: "_COp.8da6098981b7fee3:core.Destroy.Core", scope: null, file: !1, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !18)
// CHECK:STDOUT: !16 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !17 = !{null, !8}
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DILocalVariable(arg: 1, scope: !15, type: !8)
// CHECK:STDOUT: !20 = !DILocation(line: 9, column: 3, scope: !15)
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Op", linkageName: "_COp.59abebc75eab0036:core.Destroy.Core", scope: null, file: !1, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !22)
// CHECK:STDOUT: !22 = !{!23}
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 1, scope: !21, type: !8)
// CHECK:STDOUT: !24 = !DILocation(line: 9, column: 3, scope: !21)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Op", linkageName: "_COp.77d64100f3a87f7e:core.Destroy.Core", scope: null, file: !1, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
// CHECK:STDOUT: !26 = !{!27}
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !25, type: !8)
// CHECK:STDOUT: !28 = !DILocation(line: 9, column: 3, scope: !25)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 9, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !32)
// CHECK:STDOUT: !30 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !31 = !{null, !7}
// CHECK:STDOUT: !32 = !{!33}
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !29, type: !7)
// CHECK:STDOUT: !34 = !DILocation(line: 9, column: 3, scope: !29)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.77b277584f162e02:core.Destroy.Core", scope: null, file: !1, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !36)
// CHECK:STDOUT: !36 = !{!37}
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !35, type: !8)
// CHECK:STDOUT: !38 = !DILocation(line: 9, column: 3, scope: !35)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Op", linkageName: "_COp.4409554a32d15e06:core.Destroy.Core", scope: null, file: !1, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !40)
// CHECK:STDOUT: !40 = !{!41}
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !39, type: !8)
// CHECK:STDOUT: !42 = !DILocation(line: 9, column: 3, scope: !39)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'method.carbon'
// CHECK:STDOUT: source_filename = "method.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CLowHalf.IntOrBytes.Main(ptr %self) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_40.1.bytes = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc7_48.2.array.index = getelementptr inbounds [4 x i8], ptr %.loc7_40.1.bytes, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc7_48.3 = load i8, ptr %.loc7_48.2.array.index, align 1, !dbg !11
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call = sext i8 %.loc7_48.3 to i32, !dbg !11
// CHECK:STDOUT:   ret i32 %Int.as.As.impl.Convert.call, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSet.IntOrBytes.Main(ptr %self, i32 %x) #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8.word = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !19
// CHECK:STDOUT:   store i32 %x, ptr %.loc8.word, align 4, !dbg !19
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseMethods.Main(ptr %u) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca [4 x i8], align 4, !dbg !24
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !24
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %v.var, ptr align 4 %u, i64 4, i1 false), !dbg !25
// CHECK:STDOUT:   call void @_CSet.IntOrBytes.Main(ptr %v.var, i32 3), !dbg !26
// CHECK:STDOUT:   %IntOrBytes.LowHalf.call = call i32 @_CLowHalf.IntOrBytes.Main(ptr %v.var), !dbg !27
// CHECK:STDOUT:   call void @"_COp.e2e991cf29b775ca:core.Destroy.Core"(ptr %v.var), !dbg !24
// CHECK:STDOUT:   ret i32 %IntOrBytes.LowHalf.call, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.136cbc434fe80552:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.d53db3d156fa3ea4:core.Destroy.Core"(ptr %self) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.928e9c0682a9e341:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.e2e991cf29b775ca:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "method.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "LowHalf", linkageName: "_CLowHalf.IntOrBytes.Main", scope: null, file: !1, line: 7, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 7, column: 36, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 7, column: 29, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "Set", linkageName: "_CSet.IntOrBytes.Main", scope: null, file: !1, line: 8, type: !14, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !14 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !15 = !{null, !8, !7}
// CHECK:STDOUT: !16 = !{!17, !18}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !13, type: !8)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 2, scope: !13, type: !7)
// CHECK:STDOUT: !19 = !DILocation(line: 8, column: 30, scope: !13)
// CHECK:STDOUT: !20 = !DILocation(line: 8, column: 3, scope: !13)
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "UseMethods", linkageName: "_CUseMethods.Main", scope: null, file: !1, line: 11, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !22)
// CHECK:STDOUT: !22 = !{!23}
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 1, scope: !21, type: !8)
// CHECK:STDOUT: !24 = !DILocation(line: 12, column: 3, scope: !21)
// CHECK:STDOUT: !25 = !DILocation(line: 12, column: 23, scope: !21)
// CHECK:STDOUT: !26 = !DILocation(line: 13, column: 3, scope: !21)
// CHECK:STDOUT: !27 = !DILocation(line: 14, column: 10, scope: !21)
// CHECK:STDOUT: !28 = !DILocation(line: 14, column: 3, scope: !21)
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 12, type: !30, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !32)
// CHECK:STDOUT: !30 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !31 = !{null, !7}
// CHECK:STDOUT: !32 = !{!33}
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 1, scope: !29, type: !7)
// CHECK:STDOUT: !34 = !DILocation(line: 12, column: 3, scope: !29)
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "Op", linkageName: "_COp.136cbc434fe80552:core.Destroy.Core", scope: null, file: !1, line: 12, type: !36, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !39)
// CHECK:STDOUT: !36 = !DISubroutineType(types: !37)
// CHECK:STDOUT: !37 = !{null, !38}
// CHECK:STDOUT: !38 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !39 = !{!40}
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !35, type: !38)
// CHECK:STDOUT: !41 = !DILocation(line: 12, column: 3, scope: !35)
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "Op", linkageName: "_COp.d53db3d156fa3ea4:core.Destroy.Core", scope: null, file: !1, line: 12, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !45)
// CHECK:STDOUT: !43 = !DISubroutineType(types: !44)
// CHECK:STDOUT: !44 = !{null, !8}
// CHECK:STDOUT: !45 = !{!46}
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !42, type: !8)
// CHECK:STDOUT: !47 = !DILocation(line: 12, column: 3, scope: !42)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Op", linkageName: "_COp.928e9c0682a9e341:core.Destroy.Core", scope: null, file: !1, line: 12, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !49)
// CHECK:STDOUT: !49 = !{!50}
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !48, type: !8)
// CHECK:STDOUT: !51 = !DILocation(line: 12, column: 3, scope: !48)
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "Op", linkageName: "_COp.e2e991cf29b775ca:core.Destroy.Core", scope: null, file: !1, line: 12, type: !43, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !53 = !{!54}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !52, type: !8)
// CHECK:STDOUT: !55 = !DILocation(line: 12, column: 3, scope: !52)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'by_pointer.carbon'
// CHECK:STDOUT: source_filename = "by_pointer.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRead.Main(ptr %u) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_41.1.word = getelementptr inbounds nuw [4 x i8], ptr %u, i32 0, i32 0, !dbg !11
// CHECK:STDOUT:   %.loc8_41.2 = load i32, ptr %.loc8_41.1.word, align 4, !dbg !11
// CHECK:STDOUT:   ret i32 %.loc8_41.2, !dbg !12
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CWrite.Main(ptr %p) #0 !dbg !13 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_29.2.word = getelementptr inbounds nuw [4 x i8], ptr %p, i32 0, i32 0, !dbg !18
// CHECK:STDOUT:   store i32 1, ptr %.loc10_29.2.word, align 4, !dbg !18
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "by_pointer.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Read", linkageName: "_CRead.Main", scope: null, file: !1, line: 8, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !9)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !8}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !9 = !{!10}
// CHECK:STDOUT: !10 = !DILocalVariable(arg: 1, scope: !4, type: !8)
// CHECK:STDOUT: !11 = !DILocation(line: 8, column: 40, scope: !4)
// CHECK:STDOUT: !12 = !DILocation(line: 8, column: 33, scope: !4)
// CHECK:STDOUT: !13 = distinct !DISubprogram(name: "Write", linkageName: "_CWrite.Main", scope: null, file: !1, line: 10, type: !14, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !14 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !15 = !{null, !8}
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !13, type: !8)
// CHECK:STDOUT: !18 = !DILocation(line: 10, column: 28, scope: !13)
// CHECK:STDOUT: !19 = !DILocation(line: 10, column: 1, scope: !13)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'file_scope_union.carbon'
// CHECK:STDOUT: source_filename = "file_scope_union.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cg.Main = global [4 x i8] zeroinitializer
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   store i32 5, ptr @_Cg.Main, align 4, !dbg !7
// CHECK:STDOUT:   ret void, !dbg !8
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "file_scope_union.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{null}
// CHECK:STDOUT: !7 = !DILocation(line: 8, column: 21, scope: !4)
// CHECK:STDOUT: !8 = !DILocation(line: 0, scope: !4)
// CHECK:STDOUT:
