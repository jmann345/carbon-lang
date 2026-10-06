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
// CHECK:STDOUT: define i32 @_CUnformedLocal.Main() #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %u.var = alloca [4 x i8], align 4, !dbg !20
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %u.var), !dbg !20
// CHECK:STDOUT:   %.loc10_4.word = getelementptr inbounds nuw [4 x i8], ptr %u.var, i32 0, i32 0, !dbg !22
// CHECK:STDOUT:   store i32 5, ptr %.loc10_4.word, align 4, !dbg !22
// CHECK:STDOUT:   %.loc11_11.1.word = getelementptr inbounds nuw [4 x i8], ptr %u.var, i32 0, i32 0, !dbg !23
// CHECK:STDOUT:   %.loc11_11.2 = load i32, ptr %.loc11_11.1.word, align 4, !dbg !23
// CHECK:STDOUT:   call void @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core"(ptr %u.var), !dbg !20
// CHECK:STDOUT:   ret i32 %.loc11_11.2, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %self) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core"(ptr %self) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 3, !dbg !35
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc9_3.1.array.index), !dbg !35
// CHECK:STDOUT:   %.loc9_3.2.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 2, !dbg !35
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc9_3.2.array.index), !dbg !35
// CHECK:STDOUT:   %.loc9_3.3.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 1, !dbg !35
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc9_3.3.array.index), !dbg !35
// CHECK:STDOUT:   %.loc9_3.4.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 0, !dbg !35
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc9_3.4.array.index), !dbg !35
// CHECK:STDOUT:   ret void, !dbg !35
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core"(ptr %self) #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core"(ptr %self), !dbg !39
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self) #0 !dbg !45 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self), !dbg !47
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.bytes = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !51
// CHECK:STDOUT:   call void @"_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core"(ptr %.loc9_3.1.bytes), !dbg !51
// CHECK:STDOUT:   %.loc9_3.2.word = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !51
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.2.word), !dbg !51
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self), !dbg !55
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "unformed_local.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "UnformedLocal", linkageName: "_CUnformedLocal.Main", scope: null, file: !4, line: 8, type: !9, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !20 = !DILocation(line: 9, column: 3, scope: !17)
// CHECK:STDOUT: !22 = !DILocation(line: 10, column: 3, scope: !17)
// CHECK:STDOUT: !23 = !DILocation(line: 11, column: 10, scope: !17)
// CHECK:STDOUT: !24 = !DILocation(line: 11, column: 3, scope: !17)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 9, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !28)
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !25, type: !6)
// CHECK:STDOUT: !27 = !DILocation(line: 9, column: 3, scope: !25)
// CHECK:STDOUT: !28 = !{!26}
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4954785a8b134801:core.Destroy.Core", scope: null, file: !4, line: 9, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !32)
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 1, scope: !29, type: !7)
// CHECK:STDOUT: !31 = !DILocation(line: 9, column: 3, scope: !29)
// CHECK:STDOUT: !32 = !{!30}
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !36)
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !33, type: !14)
// CHECK:STDOUT: !35 = !DILocation(line: 9, column: 3, scope: !33)
// CHECK:STDOUT: !36 = !{!34}
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !40)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !37, type: !14)
// CHECK:STDOUT: !39 = !DILocation(line: 9, column: 3, scope: !37)
// CHECK:STDOUT: !40 = !{!38}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !44)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !41, type: !14)
// CHECK:STDOUT: !43 = !DILocation(line: 9, column: 3, scope: !41)
// CHECK:STDOUT: !44 = !{!42}
// CHECK:STDOUT: !45 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e9adbe0e23f89f82:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !48)
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !45, type: !14)
// CHECK:STDOUT: !47 = !DILocation(line: 9, column: 3, scope: !45)
// CHECK:STDOUT: !48 = !{!46}
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !52)
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !49, type: !14)
// CHECK:STDOUT: !51 = !DILocation(line: 9, column: 3, scope: !49)
// CHECK:STDOUT: !52 = !{!50}
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core", scope: null, file: !4, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !56)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !14)
// CHECK:STDOUT: !55 = !DILocation(line: 9, column: 3, scope: !53)
// CHECK:STDOUT: !56 = !{!54}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'designated_init.carbon'
// CHECK:STDOUT: source_filename = "designated_init.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @array.loc10_45.3 = internal constant [4 x i8] c"\01\02\03\04"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CDesignatedInit.Main() #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca [4 x i8], align 4, !dbg !62
// CHECK:STDOUT:   %b.var = alloca [4 x i8], align 4, !dbg !65
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !62
// CHECK:STDOUT:   %.loc9_33.3.word = getelementptr inbounds nuw [4 x i8], ptr %v.var, i32 0, i32 0, !dbg !63
// CHECK:STDOUT:   store i32 5, ptr %.loc9_33.3.word, align 4, !dbg !63
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %b.var), !dbg !65
// CHECK:STDOUT:   %.loc10_45.2.bytes = getelementptr inbounds nuw [4 x i8], ptr %b.var, i32 0, i32 0, !dbg !66
// CHECK:STDOUT:   %.loc10_44.3.array.index = getelementptr inbounds [4 x i8], ptr %.loc10_45.2.bytes, i32 0, i64 0, !dbg !67
// CHECK:STDOUT:   %.loc10_44.6.array.index = getelementptr inbounds [4 x i8], ptr %.loc10_45.2.bytes, i32 0, i64 1, !dbg !67
// CHECK:STDOUT:   %.loc10_44.9.array.index = getelementptr inbounds [4 x i8], ptr %.loc10_45.2.bytes, i32 0, i64 2, !dbg !67
// CHECK:STDOUT:   %.loc10_44.12.array.index = getelementptr inbounds [4 x i8], ptr %.loc10_45.2.bytes, i32 0, i64 3, !dbg !67
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %.loc10_45.2.bytes, ptr align 1 @array.loc10_45.3, i64 4, i1 false), !dbg !66
// CHECK:STDOUT:   %.loc11_11.1.word = getelementptr inbounds nuw [4 x i8], ptr %v.var, i32 0, i32 0, !dbg !69
// CHECK:STDOUT:   %.loc11_21.bytes = getelementptr inbounds nuw [4 x i8], ptr %b.var, i32 0, i32 0, !dbg !70
// CHECK:STDOUT:   %.loc11_29.1.array.index = getelementptr inbounds [4 x i8], ptr %.loc11_21.bytes, i32 0, i32 3, !dbg !70
// CHECK:STDOUT:   %.loc11_29.2 = load i8, ptr %.loc11_29.1.array.index, align 1, !dbg !70
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call = sext i8 %.loc11_29.2 to i32, !dbg !70
// CHECK:STDOUT:   %.loc11_11.2 = load i32, ptr %.loc11_11.1.word, align 4, !dbg !69
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc11_11.2, %Int.as.As.impl.Convert.call, !dbg !69
// CHECK:STDOUT:   call void @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core"(ptr %b.var), !dbg !65
// CHECK:STDOUT:   call void @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core"(ptr %v.var), !dbg !62
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !72 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %self) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !78
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core"(ptr %self) #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_3.1.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 3, !dbg !82
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc10_3.1.array.index), !dbg !82
// CHECK:STDOUT:   %.loc10_3.2.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 2, !dbg !82
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc10_3.2.array.index), !dbg !82
// CHECK:STDOUT:   %.loc10_3.3.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 1, !dbg !82
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc10_3.3.array.index), !dbg !82
// CHECK:STDOUT:   %.loc10_3.4.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 0, !dbg !82
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc10_3.4.array.index), !dbg !82
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core"(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core"(ptr %self), !dbg !86
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self) #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self), !dbg !94
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self) #0 !dbg !96 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_3.1.bytes = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   call void @"_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core"(ptr %.loc10_3.1.bytes), !dbg !98
// CHECK:STDOUT:   %.loc10_3.2.word = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !98
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc10_3.2.word), !dbg !98
// CHECK:STDOUT:   ret void, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self) #0 !dbg !100 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self), !dbg !102
// CHECK:STDOUT:   ret void, !dbg !102
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!58}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !57 = !DIFile(filename: "designated_init.carbon", directory: "")
// CHECK:STDOUT: !58 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !57, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "DesignatedInit", linkageName: "_CDesignatedInit.Main", scope: null, file: !57, line: 8, type: !9, spFlags: DISPFlagDefinition, unit: !58)
// CHECK:STDOUT: !62 = !DILocation(line: 9, column: 3, scope: !59)
// CHECK:STDOUT: !63 = !DILocation(line: 9, column: 23, scope: !59)
// CHECK:STDOUT: !65 = !DILocation(line: 10, column: 3, scope: !59)
// CHECK:STDOUT: !66 = !DILocation(line: 10, column: 23, scope: !59)
// CHECK:STDOUT: !67 = !DILocation(line: 10, column: 33, scope: !59)
// CHECK:STDOUT: !69 = !DILocation(line: 11, column: 10, scope: !59)
// CHECK:STDOUT: !70 = !DILocation(line: 11, column: 20, scope: !59)
// CHECK:STDOUT: !71 = !DILocation(line: 11, column: 3, scope: !59)
// CHECK:STDOUT: !72 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !57, line: 10, type: !11, spFlags: DISPFlagDefinition, unit: !58, retainedNodes: !75)
// CHECK:STDOUT: !73 = !DILocalVariable(arg: 1, scope: !72, type: !6)
// CHECK:STDOUT: !74 = !DILocation(line: 10, column: 3, scope: !72)
// CHECK:STDOUT: !75 = !{!73}
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4954785a8b134801:core.Destroy.Core", scope: null, file: !57, line: 10, type: !13, spFlags: DISPFlagDefinition, unit: !58, retainedNodes: !79)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !7)
// CHECK:STDOUT: !78 = !DILocation(line: 10, column: 3, scope: !76)
// CHECK:STDOUT: !79 = !{!77}
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core", scope: null, file: !57, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !58, retainedNodes: !83)
// CHECK:STDOUT: !81 = !DILocalVariable(arg: 1, scope: !80, type: !14)
// CHECK:STDOUT: !82 = !DILocation(line: 10, column: 3, scope: !80)
// CHECK:STDOUT: !83 = !{!81}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core", scope: null, file: !57, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !58, retainedNodes: !87)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !14)
// CHECK:STDOUT: !86 = !DILocation(line: 10, column: 3, scope: !84)
// CHECK:STDOUT: !87 = !{!85}
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core", scope: null, file: !57, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !58, retainedNodes: !91)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !14)
// CHECK:STDOUT: !90 = !DILocation(line: 10, column: 3, scope: !88)
// CHECK:STDOUT: !91 = !{!89}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e9adbe0e23f89f82:core.Destroy.Core", scope: null, file: !57, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !58, retainedNodes: !95)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !14)
// CHECK:STDOUT: !94 = !DILocation(line: 10, column: 3, scope: !92)
// CHECK:STDOUT: !95 = !{!93}
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core", scope: null, file: !57, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !58, retainedNodes: !99)
// CHECK:STDOUT: !97 = !DILocalVariable(arg: 1, scope: !96, type: !14)
// CHECK:STDOUT: !98 = !DILocation(line: 10, column: 3, scope: !96)
// CHECK:STDOUT: !99 = !{!97}
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core", scope: null, file: !57, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !58, retainedNodes: !103)
// CHECK:STDOUT: !101 = !DILocalVariable(arg: 1, scope: !100, type: !14)
// CHECK:STDOUT: !102 = !DILocation(line: 10, column: 3, scope: !100)
// CHECK:STDOUT: !103 = !{!101}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'copy.carbon'
// CHECK:STDOUT: source_filename = "copy.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCopy.Main(ptr %v) #0 !dbg !108 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %w.var = alloca [4 x i8], align 4, !dbg !113
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %w.var), !dbg !113
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %w.var, ptr align 4 %v, i64 4, i1 false), !dbg !114
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %w.var, ptr align 4 %v, i64 4, i1 false), !dbg !117
// CHECK:STDOUT:   %.loc11_11.1.word = getelementptr inbounds nuw [4 x i8], ptr %w.var, i32 0, i32 0, !dbg !118
// CHECK:STDOUT:   %.loc11_11.2 = load i32, ptr %.loc11_11.1.word, align 4, !dbg !118
// CHECK:STDOUT:   call void @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core"(ptr %w.var), !dbg !113
// CHECK:STDOUT:   ret i32 %.loc11_11.2, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !121 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !123
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %self) #0 !dbg !125 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core"(ptr %self) #0 !dbg !129 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 3, !dbg !131
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc9_3.1.array.index), !dbg !131
// CHECK:STDOUT:   %.loc9_3.2.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 2, !dbg !131
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc9_3.2.array.index), !dbg !131
// CHECK:STDOUT:   %.loc9_3.3.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 1, !dbg !131
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc9_3.3.array.index), !dbg !131
// CHECK:STDOUT:   %.loc9_3.4.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 0, !dbg !131
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc9_3.4.array.index), !dbg !131
// CHECK:STDOUT:   ret void, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core"(ptr %self) #0 !dbg !133 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core"(ptr %self), !dbg !135
// CHECK:STDOUT:   ret void, !dbg !135
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self) #0 !dbg !137 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self) #0 !dbg !141 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self), !dbg !143
// CHECK:STDOUT:   ret void, !dbg !143
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self) #0 !dbg !145 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.bytes = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !147
// CHECK:STDOUT:   call void @"_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core"(ptr %.loc9_3.1.bytes), !dbg !147
// CHECK:STDOUT:   %.loc9_3.2.word = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !147
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc9_3.2.word), !dbg !147
// CHECK:STDOUT:   ret void, !dbg !147
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self) #0 !dbg !149 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self), !dbg !151
// CHECK:STDOUT:   ret void, !dbg !151
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!105}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !10 = !{null, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !104 = !DIFile(filename: "copy.carbon", directory: "")
// CHECK:STDOUT: !105 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !104, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !106 = !{!6, !14}
// CHECK:STDOUT: !107 = !DISubroutineType(types: !106)
// CHECK:STDOUT: !108 = distinct !DISubprogram(name: "Copy", linkageName: "_CCopy.Main", scope: null, file: !104, line: 8, type: !107, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !120)
// CHECK:STDOUT: !109 = !DILocalVariable(arg: 1, scope: !108, type: !14)
// CHECK:STDOUT: !113 = !DILocation(line: 9, column: 3, scope: !108)
// CHECK:STDOUT: !114 = !DILocation(line: 9, column: 23, scope: !108)
// CHECK:STDOUT: !117 = !DILocation(line: 10, column: 7, scope: !108)
// CHECK:STDOUT: !118 = !DILocation(line: 11, column: 10, scope: !108)
// CHECK:STDOUT: !119 = !DILocation(line: 11, column: 3, scope: !108)
// CHECK:STDOUT: !120 = !{!109}
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !104, line: 9, type: !11, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !124)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !121, type: !6)
// CHECK:STDOUT: !123 = !DILocation(line: 9, column: 3, scope: !121)
// CHECK:STDOUT: !124 = !{!122}
// CHECK:STDOUT: !125 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4954785a8b134801:core.Destroy.Core", scope: null, file: !104, line: 9, type: !13, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !128)
// CHECK:STDOUT: !126 = !DILocalVariable(arg: 1, scope: !125, type: !7)
// CHECK:STDOUT: !127 = !DILocation(line: 9, column: 3, scope: !125)
// CHECK:STDOUT: !128 = !{!126}
// CHECK:STDOUT: !129 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core", scope: null, file: !104, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !132)
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 1, scope: !129, type: !14)
// CHECK:STDOUT: !131 = !DILocation(line: 9, column: 3, scope: !129)
// CHECK:STDOUT: !132 = !{!130}
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core", scope: null, file: !104, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !136)
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !133, type: !14)
// CHECK:STDOUT: !135 = !DILocation(line: 9, column: 3, scope: !133)
// CHECK:STDOUT: !136 = !{!134}
// CHECK:STDOUT: !137 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core", scope: null, file: !104, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !140)
// CHECK:STDOUT: !138 = !DILocalVariable(arg: 1, scope: !137, type: !14)
// CHECK:STDOUT: !139 = !DILocation(line: 9, column: 3, scope: !137)
// CHECK:STDOUT: !140 = !{!138}
// CHECK:STDOUT: !141 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e9adbe0e23f89f82:core.Destroy.Core", scope: null, file: !104, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !144)
// CHECK:STDOUT: !142 = !DILocalVariable(arg: 1, scope: !141, type: !14)
// CHECK:STDOUT: !143 = !DILocation(line: 9, column: 3, scope: !141)
// CHECK:STDOUT: !144 = !{!142}
// CHECK:STDOUT: !145 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core", scope: null, file: !104, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !148)
// CHECK:STDOUT: !146 = !DILocalVariable(arg: 1, scope: !145, type: !14)
// CHECK:STDOUT: !147 = !DILocation(line: 9, column: 3, scope: !145)
// CHECK:STDOUT: !148 = !{!146}
// CHECK:STDOUT: !149 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core", scope: null, file: !104, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !105, retainedNodes: !152)
// CHECK:STDOUT: !150 = !DILocalVariable(arg: 1, scope: !149, type: !14)
// CHECK:STDOUT: !151 = !DILocation(line: 9, column: 3, scope: !149)
// CHECK:STDOUT: !152 = !{!150}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'user_copy_impl_shadowed.carbon'
// CHECK:STDOUT: source_filename = "user_copy_impl_shadowed.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_COp.Shadowed.Main:Copy.Core"(ptr sret([4 x i8]) %return, ptr %self) #0 !dbg !157 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_41.3.a = getelementptr inbounds nuw [4 x i8], ptr %return, i32 0, i32 0, !dbg !162
// CHECK:STDOUT:   store i32 0, ptr %.loc10_41.3.a, align 4, !dbg !162
// CHECK:STDOUT:   ret void, !dbg !163
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CCopyShadowed.Main(ptr %x) #0 !dbg !165 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %y.var = alloca [4 x i8], align 4, !dbg !170
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %y.var), !dbg !170
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %y.var, ptr align 4 %x, i64 4, i1 false), !dbg !171
// CHECK:STDOUT:   %.loc16_11.1.a = getelementptr inbounds nuw [4 x i8], ptr %y.var, i32 0, i32 0, !dbg !173
// CHECK:STDOUT:   %.loc16_11.2 = load i32, ptr %.loc16_11.1.a, align 4, !dbg !173
// CHECK:STDOUT:   call void @"_CSelfDestruct.5754580338d17f2c:core.Destroy.Core"(ptr %y.var), !dbg !170
// CHECK:STDOUT:   ret i32 %.loc16_11.2, !dbg !174
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !176 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !178
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.7842df52c7037cb5:core.Destroy.Core"(ptr %self) #0 !dbg !180 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !182
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7842df52c7037cb5:core.Destroy.Core"(ptr %self) #0 !dbg !184 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.7842df52c7037cb5:core.Destroy.Core"(ptr %self), !dbg !186
// CHECK:STDOUT:   ret void, !dbg !186
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.5754580338d17f2c:core.Destroy.Core"(ptr %self) #0 !dbg !188 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc15.a = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !190
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc15.a), !dbg !190
// CHECK:STDOUT:   ret void, !dbg !190
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5754580338d17f2c:core.Destroy.Core"(ptr %self) #0 !dbg !192 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.5754580338d17f2c:core.Destroy.Core"(ptr %self), !dbg !194
// CHECK:STDOUT:   ret void, !dbg !194
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!154}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !10 = !{null, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !106 = !{!6, !14}
// CHECK:STDOUT: !107 = !DISubroutineType(types: !106)
// CHECK:STDOUT: !153 = !DIFile(filename: "user_copy_impl_shadowed.carbon", directory: "")
// CHECK:STDOUT: !154 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !153, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !155 = !{!14, !14}
// CHECK:STDOUT: !156 = !DISubroutineType(types: !155)
// CHECK:STDOUT: !157 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Shadowed.Main:Copy.Core", scope: null, file: !153, line: 10, type: !156, spFlags: DISPFlagDefinition, unit: !154, retainedNodes: !164)
// CHECK:STDOUT: !158 = !DILocalVariable(arg: 1, scope: !157, type: !14)
// CHECK:STDOUT: !162 = !DILocation(line: 10, column: 34, scope: !157)
// CHECK:STDOUT: !163 = !DILocation(line: 10, column: 27, scope: !157)
// CHECK:STDOUT: !164 = !{!158}
// CHECK:STDOUT: !165 = distinct !DISubprogram(name: "CopyShadowed", linkageName: "_CCopyShadowed.Main", scope: null, file: !153, line: 14, type: !107, spFlags: DISPFlagDefinition, unit: !154, retainedNodes: !175)
// CHECK:STDOUT: !166 = !DILocalVariable(arg: 1, scope: !165, type: !14)
// CHECK:STDOUT: !170 = !DILocation(line: 15, column: 3, scope: !165)
// CHECK:STDOUT: !171 = !DILocation(line: 15, column: 21, scope: !165)
// CHECK:STDOUT: !173 = !DILocation(line: 16, column: 10, scope: !165)
// CHECK:STDOUT: !174 = !DILocation(line: 16, column: 3, scope: !165)
// CHECK:STDOUT: !175 = !{!166}
// CHECK:STDOUT: !176 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !153, line: 15, type: !11, spFlags: DISPFlagDefinition, unit: !154, retainedNodes: !179)
// CHECK:STDOUT: !177 = !DILocalVariable(arg: 1, scope: !176, type: !6)
// CHECK:STDOUT: !178 = !DILocation(line: 15, column: 3, scope: !176)
// CHECK:STDOUT: !179 = !{!177}
// CHECK:STDOUT: !180 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.7842df52c7037cb5:core.Destroy.Core", scope: null, file: !153, line: 15, type: !16, spFlags: DISPFlagDefinition, unit: !154, retainedNodes: !183)
// CHECK:STDOUT: !181 = !DILocalVariable(arg: 1, scope: !180, type: !14)
// CHECK:STDOUT: !182 = !DILocation(line: 15, column: 3, scope: !180)
// CHECK:STDOUT: !183 = !{!181}
// CHECK:STDOUT: !184 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7842df52c7037cb5:core.Destroy.Core", scope: null, file: !153, line: 15, type: !16, spFlags: DISPFlagDefinition, unit: !154, retainedNodes: !187)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 1, scope: !184, type: !14)
// CHECK:STDOUT: !186 = !DILocation(line: 15, column: 3, scope: !184)
// CHECK:STDOUT: !187 = !{!185}
// CHECK:STDOUT: !188 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.5754580338d17f2c:core.Destroy.Core", scope: null, file: !153, line: 15, type: !16, spFlags: DISPFlagDefinition, unit: !154, retainedNodes: !191)
// CHECK:STDOUT: !189 = !DILocalVariable(arg: 1, scope: !188, type: !14)
// CHECK:STDOUT: !190 = !DILocation(line: 15, column: 3, scope: !188)
// CHECK:STDOUT: !191 = !{!189}
// CHECK:STDOUT: !192 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5754580338d17f2c:core.Destroy.Core", scope: null, file: !153, line: 15, type: !16, spFlags: DISPFlagDefinition, unit: !154, retainedNodes: !195)
// CHECK:STDOUT: !193 = !DILocalVariable(arg: 1, scope: !192, type: !14)
// CHECK:STDOUT: !194 = !DILocation(line: 15, column: 3, scope: !192)
// CHECK:STDOUT: !195 = !{!193}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'optional_pointer_field.carbon'
// CHECK:STDOUT: source_filename = "optional_pointer_field.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !204 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !206
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i64 @_CCopyOptPtr.Main(ptr %p) #0 !dbg !208 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %q.var = alloca [8 x i8], align 8, !dbg !213
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %q.var), !dbg !213
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %q.var, ptr align 8 %p, i64 8, i1 false), !dbg !214
// CHECK:STDOUT:   %.loc10_11.1.n = getelementptr inbounds nuw [8 x i8], ptr %q.var, i32 0, i32 0, !dbg !216
// CHECK:STDOUT:   %.loc10_11.2 = load i64, ptr %.loc10_11.1.n, align 8, !dbg !216
// CHECK:STDOUT:   call void @"_CSelfDestruct.110489c9d47256c3:core.Destroy.Core"(ptr %q.var), !dbg !213
// CHECK:STDOUT:   ret i64 %.loc10_11.2, !dbg !217
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core"(ptr %self) #0 !dbg !219 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !221
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %self) #0 !dbg !223 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !225
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5b309895020f658e:core.Destroy.Core"(ptr %self) #0 !dbg !227 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !229
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !231 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !233
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c2de2b8f8dbae724:core.Destroy.Core"(ptr %self) #0 !dbg !235 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !237
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c2de2b8f8dbae724:core.Destroy.Core"(ptr %self) #0 !dbg !239 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c2de2b8f8dbae724:core.Destroy.Core"(ptr %self), !dbg !241
// CHECK:STDOUT:   ret void, !dbg !241
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.110489c9d47256c3:core.Destroy.Core"(ptr %self) #0 !dbg !243 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_3.1.n = getelementptr inbounds nuw [8 x i8], ptr %self, i32 0, i32 0, !dbg !245
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc9_3.1.n), !dbg !245
// CHECK:STDOUT:   %.loc9_3.2.o = getelementptr inbounds nuw [8 x i8], ptr %self, i32 0, i32 0, !dbg !245
// CHECK:STDOUT:   call void @"_CSelfDestruct.5b309895020f658e:core.Destroy.Core"(ptr %.loc9_3.2.o), !dbg !245
// CHECK:STDOUT:   ret void, !dbg !245
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.110489c9d47256c3:core.Destroy.Core"(ptr %self) #0 !dbg !247 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.110489c9d47256c3:core.Destroy.Core"(ptr %self), !dbg !249
// CHECK:STDOUT:   ret void, !dbg !249
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!197}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !196 = !DIFile(filename: "optional_pointer_field.carbon", directory: "")
// CHECK:STDOUT: !197 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !196, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !198 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !199 = !{!198, !14}
// CHECK:STDOUT: !200 = !DISubroutineType(types: !199)
// CHECK:STDOUT: !201 = !{null, !198}
// CHECK:STDOUT: !202 = !DISubroutineType(types: !201)
// CHECK:STDOUT: !203 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !204 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !203, line: 189, type: !16, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !207)
// CHECK:STDOUT: !205 = !DILocalVariable(arg: 1, scope: !204, type: !14)
// CHECK:STDOUT: !206 = !DILocation(line: 189, column: 19, scope: !204)
// CHECK:STDOUT: !207 = !{!205}
// CHECK:STDOUT: !208 = distinct !DISubprogram(name: "CopyOptPtr", linkageName: "_CCopyOptPtr.Main", scope: null, file: !196, line: 8, type: !200, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !218)
// CHECK:STDOUT: !209 = !DILocalVariable(arg: 1, scope: !208, type: !14)
// CHECK:STDOUT: !213 = !DILocation(line: 9, column: 3, scope: !208)
// CHECK:STDOUT: !214 = !DILocation(line: 9, column: 19, scope: !208)
// CHECK:STDOUT: !216 = !DILocation(line: 10, column: 10, scope: !208)
// CHECK:STDOUT: !217 = !DILocation(line: 10, column: 3, scope: !208)
// CHECK:STDOUT: !218 = !{!209}
// CHECK:STDOUT: !219 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core", scope: null, file: !196, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !222)
// CHECK:STDOUT: !220 = !DILocalVariable(arg: 1, scope: !219, type: !14)
// CHECK:STDOUT: !221 = !DILocation(line: 9, column: 3, scope: !219)
// CHECK:STDOUT: !222 = !{!220}
// CHECK:STDOUT: !223 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.729fca203337f92a:core.Destroy.Core", scope: null, file: !196, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !226)
// CHECK:STDOUT: !224 = !DILocalVariable(arg: 1, scope: !223, type: !14)
// CHECK:STDOUT: !225 = !DILocation(line: 9, column: 3, scope: !223)
// CHECK:STDOUT: !226 = !{!224}
// CHECK:STDOUT: !227 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5b309895020f658e:core.Destroy.Core", scope: null, file: !196, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !230)
// CHECK:STDOUT: !228 = !DILocalVariable(arg: 1, scope: !227, type: !14)
// CHECK:STDOUT: !229 = !DILocation(line: 9, column: 3, scope: !227)
// CHECK:STDOUT: !230 = !{!228}
// CHECK:STDOUT: !231 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !196, line: 9, type: !202, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !234)
// CHECK:STDOUT: !232 = !DILocalVariable(arg: 1, scope: !231, type: !198)
// CHECK:STDOUT: !233 = !DILocation(line: 9, column: 3, scope: !231)
// CHECK:STDOUT: !234 = !{!232}
// CHECK:STDOUT: !235 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c2de2b8f8dbae724:core.Destroy.Core", scope: null, file: !196, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !238)
// CHECK:STDOUT: !236 = !DILocalVariable(arg: 1, scope: !235, type: !14)
// CHECK:STDOUT: !237 = !DILocation(line: 9, column: 3, scope: !235)
// CHECK:STDOUT: !238 = !{!236}
// CHECK:STDOUT: !239 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c2de2b8f8dbae724:core.Destroy.Core", scope: null, file: !196, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !242)
// CHECK:STDOUT: !240 = !DILocalVariable(arg: 1, scope: !239, type: !14)
// CHECK:STDOUT: !241 = !DILocation(line: 9, column: 3, scope: !239)
// CHECK:STDOUT: !242 = !{!240}
// CHECK:STDOUT: !243 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.110489c9d47256c3:core.Destroy.Core", scope: null, file: !196, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !246)
// CHECK:STDOUT: !244 = !DILocalVariable(arg: 1, scope: !243, type: !14)
// CHECK:STDOUT: !245 = !DILocation(line: 9, column: 3, scope: !243)
// CHECK:STDOUT: !246 = !{!244}
// CHECK:STDOUT: !247 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.110489c9d47256c3:core.Destroy.Core", scope: null, file: !196, line: 9, type: !16, spFlags: DISPFlagDefinition, unit: !197, retainedNodes: !250)
// CHECK:STDOUT: !248 = !DILocalVariable(arg: 1, scope: !247, type: !14)
// CHECK:STDOUT: !249 = !DILocation(line: 9, column: 3, scope: !247)
// CHECK:STDOUT: !250 = !{!248}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'method.carbon'
// CHECK:STDOUT: source_filename = "method.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CLowHalf.IntOrBytes.Main(ptr %self) #0 !dbg !255 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_40.1.bytes = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !260
// CHECK:STDOUT:   %.loc7_48.2.array.index = getelementptr inbounds [4 x i8], ptr %.loc7_40.1.bytes, i32 0, i32 0, !dbg !260
// CHECK:STDOUT:   %.loc7_48.3 = load i8, ptr %.loc7_48.2.array.index, align 1, !dbg !260
// CHECK:STDOUT:   %Int.as.As.impl.Convert.call = sext i8 %.loc7_48.3 to i32, !dbg !260
// CHECK:STDOUT:   ret i32 %Int.as.As.impl.Convert.call, !dbg !261
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSet.IntOrBytes.Main(ptr %self, i32 %x) #0 !dbg !263 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8.word = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !268
// CHECK:STDOUT:   store i32 %x, ptr %.loc8.word, align 4, !dbg !268
// CHECK:STDOUT:   ret void, !dbg !270
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUseMethods.Main(ptr %u) #0 !dbg !272 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.var = alloca [4 x i8], align 4, !dbg !277
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %v.var), !dbg !277
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %v.var, ptr align 4 %u, i64 4, i1 false), !dbg !278
// CHECK:STDOUT:   call void @_CSet.IntOrBytes.Main(ptr %v.var, i32 3), !dbg !280
// CHECK:STDOUT:   %IntOrBytes.LowHalf.call = call i32 @_CLowHalf.IntOrBytes.Main(ptr %v.var), !dbg !281
// CHECK:STDOUT:   call void @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core"(ptr %v.var), !dbg !277
// CHECK:STDOUT:   ret i32 %IntOrBytes.LowHalf.call, !dbg !282
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !284 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !286
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %self) #0 !dbg !288 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !290
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core"(ptr %self) #0 !dbg !292 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12_3.1.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 3, !dbg !294
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc12_3.1.array.index), !dbg !294
// CHECK:STDOUT:   %.loc12_3.2.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 2, !dbg !294
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc12_3.2.array.index), !dbg !294
// CHECK:STDOUT:   %.loc12_3.3.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 1, !dbg !294
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc12_3.3.array.index), !dbg !294
// CHECK:STDOUT:   %.loc12_3.4.array.index = getelementptr inbounds [4 x i8], ptr %self, i32 0, i64 0, !dbg !294
// CHECK:STDOUT:   call void @"_CSelfDestruct.4954785a8b134801:core.Destroy.Core"(ptr %.loc12_3.4.array.index), !dbg !294
// CHECK:STDOUT:   ret void, !dbg !294
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core"(ptr %self) #0 !dbg !296 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core"(ptr %self), !dbg !298
// CHECK:STDOUT:   ret void, !dbg !298
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self) #0 !dbg !300 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !302
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self) #0 !dbg !304 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core"(ptr %self), !dbg !306
// CHECK:STDOUT:   ret void, !dbg !306
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self) #0 !dbg !308 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12_3.1.bytes = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !310
// CHECK:STDOUT:   call void @"_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core"(ptr %.loc12_3.1.bytes), !dbg !310
// CHECK:STDOUT:   %.loc12_3.2.word = getelementptr inbounds nuw [4 x i8], ptr %self, i32 0, i32 0, !dbg !310
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %.loc12_3.2.word), !dbg !310
// CHECK:STDOUT:   ret void, !dbg !310
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self) #0 !dbg !312 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core"(ptr %self), !dbg !314
// CHECK:STDOUT:   ret void, !dbg !314
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!252}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 8, encoding: DW_ATE_signed)
// CHECK:STDOUT: !10 = !{null, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{null, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !106 = !{!6, !14}
// CHECK:STDOUT: !107 = !DISubroutineType(types: !106)
// CHECK:STDOUT: !251 = !DIFile(filename: "method.carbon", directory: "")
// CHECK:STDOUT: !252 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !251, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !253 = !{null, !14, !6}
// CHECK:STDOUT: !254 = !DISubroutineType(types: !253)
// CHECK:STDOUT: !255 = distinct !DISubprogram(name: "LowHalf", linkageName: "_CLowHalf.IntOrBytes.Main", scope: null, file: !251, line: 7, type: !107, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !262)
// CHECK:STDOUT: !256 = !DILocalVariable(arg: 1, scope: !255, type: !14)
// CHECK:STDOUT: !260 = !DILocation(line: 7, column: 36, scope: !255)
// CHECK:STDOUT: !261 = !DILocation(line: 7, column: 29, scope: !255)
// CHECK:STDOUT: !262 = !{!256}
// CHECK:STDOUT: !263 = distinct !DISubprogram(name: "Set", linkageName: "_CSet.IntOrBytes.Main", scope: null, file: !251, line: 8, type: !254, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !271)
// CHECK:STDOUT: !264 = !DILocalVariable(arg: 1, scope: !263, type: !14)
// CHECK:STDOUT: !265 = !DILocalVariable(arg: 2, scope: !263, type: !6)
// CHECK:STDOUT: !268 = !DILocation(line: 8, column: 30, scope: !263)
// CHECK:STDOUT: !270 = !DILocation(line: 8, column: 3, scope: !263)
// CHECK:STDOUT: !271 = !{!264, !265}
// CHECK:STDOUT: !272 = distinct !DISubprogram(name: "UseMethods", linkageName: "_CUseMethods.Main", scope: null, file: !251, line: 11, type: !107, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !283)
// CHECK:STDOUT: !273 = !DILocalVariable(arg: 1, scope: !272, type: !14)
// CHECK:STDOUT: !277 = !DILocation(line: 12, column: 3, scope: !272)
// CHECK:STDOUT: !278 = !DILocation(line: 12, column: 23, scope: !272)
// CHECK:STDOUT: !280 = !DILocation(line: 13, column: 3, scope: !272)
// CHECK:STDOUT: !281 = !DILocation(line: 14, column: 10, scope: !272)
// CHECK:STDOUT: !282 = !DILocation(line: 14, column: 3, scope: !272)
// CHECK:STDOUT: !283 = !{!273}
// CHECK:STDOUT: !284 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !251, line: 12, type: !11, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !287)
// CHECK:STDOUT: !285 = !DILocalVariable(arg: 1, scope: !284, type: !6)
// CHECK:STDOUT: !286 = !DILocation(line: 12, column: 3, scope: !284)
// CHECK:STDOUT: !287 = !{!285}
// CHECK:STDOUT: !288 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4954785a8b134801:core.Destroy.Core", scope: null, file: !251, line: 12, type: !13, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !291)
// CHECK:STDOUT: !289 = !DILocalVariable(arg: 1, scope: !288, type: !7)
// CHECK:STDOUT: !290 = !DILocation(line: 12, column: 3, scope: !288)
// CHECK:STDOUT: !291 = !{!289}
// CHECK:STDOUT: !292 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.69de0ffd6a943188:core.Destroy.Core", scope: null, file: !251, line: 12, type: !16, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !295)
// CHECK:STDOUT: !293 = !DILocalVariable(arg: 1, scope: !292, type: !14)
// CHECK:STDOUT: !294 = !DILocation(line: 12, column: 3, scope: !292)
// CHECK:STDOUT: !295 = !{!293}
// CHECK:STDOUT: !296 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.69de0ffd6a943188:core.Destroy.Core", scope: null, file: !251, line: 12, type: !16, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !299)
// CHECK:STDOUT: !297 = !DILocalVariable(arg: 1, scope: !296, type: !14)
// CHECK:STDOUT: !298 = !DILocation(line: 12, column: 3, scope: !296)
// CHECK:STDOUT: !299 = !{!297}
// CHECK:STDOUT: !300 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.e9adbe0e23f89f82:core.Destroy.Core", scope: null, file: !251, line: 12, type: !16, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !303)
// CHECK:STDOUT: !301 = !DILocalVariable(arg: 1, scope: !300, type: !14)
// CHECK:STDOUT: !302 = !DILocation(line: 12, column: 3, scope: !300)
// CHECK:STDOUT: !303 = !{!301}
// CHECK:STDOUT: !304 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e9adbe0e23f89f82:core.Destroy.Core", scope: null, file: !251, line: 12, type: !16, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !307)
// CHECK:STDOUT: !305 = !DILocalVariable(arg: 1, scope: !304, type: !14)
// CHECK:STDOUT: !306 = !DILocation(line: 12, column: 3, scope: !304)
// CHECK:STDOUT: !307 = !{!305}
// CHECK:STDOUT: !308 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.c1f87a415aa3a47b:core.Destroy.Core", scope: null, file: !251, line: 12, type: !16, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !311)
// CHECK:STDOUT: !309 = !DILocalVariable(arg: 1, scope: !308, type: !14)
// CHECK:STDOUT: !310 = !DILocation(line: 12, column: 3, scope: !308)
// CHECK:STDOUT: !311 = !{!309}
// CHECK:STDOUT: !312 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.c1f87a415aa3a47b:core.Destroy.Core", scope: null, file: !251, line: 12, type: !16, spFlags: DISPFlagDefinition, unit: !252, retainedNodes: !315)
// CHECK:STDOUT: !313 = !DILocalVariable(arg: 1, scope: !312, type: !14)
// CHECK:STDOUT: !314 = !DILocation(line: 12, column: 3, scope: !312)
// CHECK:STDOUT: !315 = !{!313}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'by_pointer.carbon'
// CHECK:STDOUT: source_filename = "by_pointer.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CRead.Main(ptr %u) #0 !dbg !318 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8_41.1.word = getelementptr inbounds nuw [4 x i8], ptr %u, i32 0, i32 0, !dbg !323
// CHECK:STDOUT:   %.loc8_41.2 = load i32, ptr %.loc8_41.1.word, align 4, !dbg !323
// CHECK:STDOUT:   ret i32 %.loc8_41.2, !dbg !324
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CWrite.Main(ptr %p) #0 !dbg !326 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_29.2.word = getelementptr inbounds nuw [4 x i8], ptr %p, i32 0, i32 0, !dbg !329
// CHECK:STDOUT:   store i32 1, ptr %.loc10_29.2.word, align 4, !dbg !329
// CHECK:STDOUT:   ret void, !dbg !330
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!317}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !14 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !15 = !{null, !14}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !106 = !{!6, !14}
// CHECK:STDOUT: !107 = !DISubroutineType(types: !106)
// CHECK:STDOUT: !316 = !DIFile(filename: "by_pointer.carbon", directory: "")
// CHECK:STDOUT: !317 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !316, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !318 = distinct !DISubprogram(name: "Read", linkageName: "_CRead.Main", scope: null, file: !316, line: 8, type: !107, spFlags: DISPFlagDefinition, unit: !317, retainedNodes: !325)
// CHECK:STDOUT: !319 = !DILocalVariable(arg: 1, scope: !318, type: !14)
// CHECK:STDOUT: !323 = !DILocation(line: 8, column: 40, scope: !318)
// CHECK:STDOUT: !324 = !DILocation(line: 8, column: 33, scope: !318)
// CHECK:STDOUT: !325 = !{!319}
// CHECK:STDOUT: !326 = distinct !DISubprogram(name: "Write", linkageName: "_CWrite.Main", scope: null, file: !316, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !317, retainedNodes: !331)
// CHECK:STDOUT: !327 = !DILocalVariable(arg: 1, scope: !326, type: !14)
// CHECK:STDOUT: !329 = !DILocation(line: 10, column: 28, scope: !326)
// CHECK:STDOUT: !330 = !DILocation(line: 10, column: 1, scope: !326)
// CHECK:STDOUT: !331 = !{!327}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'file_scope_union.carbon'
// CHECK:STDOUT: source_filename = "file_scope_union.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cg.Main = global [4 x i8] zeroinitializer
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !336 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   store i32 5, ptr @_Cg.Main, align 4, !dbg !337
// CHECK:STDOUT:   ret void, !dbg !339
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!333}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !332 = !DIFile(filename: "file_scope_union.carbon", directory: "")
// CHECK:STDOUT: !333 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !332, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !334 = !{null}
// CHECK:STDOUT: !335 = !DISubroutineType(types: !334)
// CHECK:STDOUT: !336 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !332, type: !335, spFlags: DISPFlagDefinition, unit: !333)
// CHECK:STDOUT: !337 = !DILocation(line: 8, column: 21, scope: !336)
// CHECK:STDOUT: !339 = !DILocation(line: 0, scope: !336)
// CHECK:STDOUT:
