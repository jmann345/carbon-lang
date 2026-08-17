// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/mixed_payload_alternatives.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/mixed_payload_alternatives.carbon

// A zero-parameter function alternative (`None()`) of a payload-carrying
// choice: its constructor's class_init must carry an element for the payload
// region (an uninitialized value, lowered as poison), so the constant folded
// from it has the same field count as the LLVM struct type. Constructing all
// three alternative forms pins the constructor bodies and the constant for
// the parenless alternative.

choice MaybeInt {
  None(),
  Missing,
  Some(x: i64)
}

fn MakeNone() -> MaybeInt {
  return MaybeInt.None();
}

let missing: MaybeInt = MaybeInt.Missing;

fn MakeSome(x: i64) -> MaybeInt {
  return MaybeInt.Some(x);
}

let none: MaybeInt = MakeNone();
let some: MaybeInt = MakeSome(42);

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'mixed_payload_alternatives.carbon'
// CHECK:STDOUT: source_filename = "mixed_payload_alternatives.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @MaybeInt.val.173 = internal constant <{ <{ i2, [7 x i8] }>, [8 x i8] }> <{ <{ i2, [7 x i8] }> <{ i2 1, [7 x i8] poison }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @MaybeInt.val.4b9.loc20_17.6 = internal constant <{ <{ i2, [7 x i8] }>, [8 x i8] }> <{ <{ i2, [7 x i8] }> <{ i2 0, [7 x i8] poison }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @MaybeInt.val.173.loc22_10.12 = internal constant <{ <{ i2, [7 x i8] }>, [8 x i8] }> <{ <{ i2, [7 x i8] }> <{ i2 1, [7 x i8] poison }>, [8 x i8] zeroinitializer }>
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CNone.MaybeInt.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_17.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !8
// CHECK:STDOUT:   %.loc20_17.4.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !8
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @MaybeInt.val.4b9.loc20_17.6, i64 16, i1 false), !dbg !8
// CHECK:STDOUT:   ret void, !dbg !8
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CSome.MaybeInt.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [8 x i8] }>) %return, i64 %_) #0 !dbg !9 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc20_17.1.discriminant = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 0, !dbg !15
// CHECK:STDOUT:   %.loc20_17.4.payload = getelementptr inbounds nuw <{ <{ i2, [7 x i8] }>, [8 x i8] }>, ptr %return, i32 0, i32 1, !dbg !15
// CHECK:STDOUT:   %.loc20_17.5.Some = getelementptr inbounds nuw [8 x i8], ptr %.loc20_17.4.payload, i32 0, i32 0, !dbg !15
// CHECK:STDOUT:   %.loc24_1.2.tuple.init = insertvalue { i64 } poison, i64 %_, 0, !dbg !15
// CHECK:STDOUT:   store { i64 } %.loc24_1.2.tuple.init, ptr %.loc20_17.5.Some, align 8, !dbg !15
// CHECK:STDOUT:   store i8 2, ptr %.loc20_17.1.discriminant, align 1, !dbg !15
// CHECK:STDOUT:   ret void, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeNone.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [8 x i8] }>) %return) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CNone.MaybeInt.Main(ptr %return), !dbg !17
// CHECK:STDOUT:   ret void, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeSome.Main(ptr sret(<{ <{ i2, [7 x i8] }>, [8 x i8] }>) %return, i64 %x) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSome.MaybeInt.Main(ptr %return, i64 %x), !dbg !22
// CHECK:STDOUT:   ret void, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc36.temp = alloca <{ <{ i2, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !27
// CHECK:STDOUT:   %.loc37_33.temp = alloca <{ <{ i2, [7 x i8] }>, [8 x i8] }>, align 8, !dbg !28
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc36.temp), !dbg !27
// CHECK:STDOUT:   call void @_CMakeNone.Main(ptr %.loc36.temp), !dbg !27
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc37_33.temp), !dbg !28
// CHECK:STDOUT:   call void @_CMakeSome.Main(ptr %.loc37_33.temp, i64 42), !dbg !28
// CHECK:STDOUT:   ret void, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "mixed_payload_alternatives.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "None", linkageName: "_CNone.MaybeInt.Main", scope: null, file: !1, line: 20, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !DILocation(line: 20, column: 1, scope: !4)
// CHECK:STDOUT: !9 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.MaybeInt.Main", scope: null, file: !1, line: 20, type: !10, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !13)
// CHECK:STDOUT: !10 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !11 = !{!7, !12}
// CHECK:STDOUT: !12 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !13 = !{!14}
// CHECK:STDOUT: !14 = !DILocalVariable(arg: 1, scope: !9, type: !12)
// CHECK:STDOUT: !15 = !DILocation(line: 20, column: 1, scope: !9)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "MakeNone", linkageName: "_CMakeNone.Main", scope: null, file: !1, line: 26, type: !5, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !17 = !DILocation(line: 27, column: 10, scope: !16)
// CHECK:STDOUT: !18 = !DILocation(line: 27, column: 3, scope: !16)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "MakeSome", linkageName: "_CMakeSome.Main", scope: null, file: !1, line: 32, type: !10, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !20)
// CHECK:STDOUT: !20 = !{!21}
// CHECK:STDOUT: !21 = !DILocalVariable(arg: 1, scope: !19, type: !12)
// CHECK:STDOUT: !22 = !DILocation(line: 33, column: 10, scope: !19)
// CHECK:STDOUT: !23 = !DILocation(line: 33, column: 3, scope: !19)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !25, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !25 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !26 = !{null}
// CHECK:STDOUT: !27 = !DILocation(line: 36, column: 22, scope: !24)
// CHECK:STDOUT: !28 = !DILocation(line: 37, column: 22, scope: !24)
// CHECK:STDOUT: !29 = !DILocation(line: 0, scope: !24)
// CHECK:STDOUT:
