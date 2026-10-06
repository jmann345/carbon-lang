// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/choice/alternative_copy.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/choice/alternative_copy.carbon

// The synthesized choice `Core.Copy` witness's lowering, both reprs (W-075,
// fork/w075/plan.md §2/§3 P-3): a payload-free choice has a copy value/init
// repr, so its `Copy.Op` lowers by value (`PrimitiveCopy` with no return
// slot); a payload-carrying choice is pointer-rep/in-place
// (sem_ir/type_info.cpp: `ValueRepr::Pointer` -> `InitRepr::InPlace`), so
// its `Copy.Op` call carries a return slot as the trailing arg and the
// handle_call.cpp arm memcpys through `CopyValue` — a wrong arm cannot
// hide (plan §5 R-4: the by-value fallback would visibly miscompile the
// slot shape). Copies of CONSTANT alternatives fold in eval
// (`PrimitiveCopy` constant-forwards), so runtime bindings carry the
// runtime-call pins.
//
// The arm dispatches on the CONCRETE type's init repr, never on call
// arity (fix round 2026-08-18, autoupdate run 32190561198): a call built
// against a symbolic `T: Core.Copy` carries the slot arg even when the
// lowered specific's type is by-copy, so mono_from_generic.carbon pins
// both monomorphizations of one generic body.

// --- copy_rep.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

// A runtime copy: by-value `PrimitiveCopy`, no slot.
fn Passthrough(f: Flag) -> Flag { return f; }

// A constant copy: folds in eval, lowered as the constant.
fn MakeOn() -> Flag { return Flag.On; }

// --- pointer_rep.carbon
library "[[@TEST_NAME]]";

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

// A runtime copy into the return slot: the trailing arg carries the slot,
// and the lowering is a memcpy of the object repr.
fn Passthrough(p: Pair(i64)) -> Pair(i64) { return p; }

// The W-075 minting shape: the payload-free alternative constant of a
// payload-carrying choice, returned by value through the slot.
fn MakeNeither() -> Pair(i64) { return Pair(i64).Neither; }

// var initialization from a runtime binding (slot = the var's storage), then
// re-assignment from the constant alternative.
fn RoundTrip(p: Pair(i64)) -> Pair(i64) {
  var q: Pair(i64) = p;
  q = Pair(i64).Neither;
  return q;
}

// --- mono_from_generic.carbon
library "[[@TEST_NAME]]";

choice Flag {
  Off,
  On
}

choice Pair(T: type) {
  Both(x: T, y: T),
  Neither
}

// The regression class (autoupdate run 32190561198, lower/testdata/class/
// generic.carbon's create_generic subfile): a generic body's copy call is
// built against symbolic `T: Core.Copy`, whose dependent init repr forces a
// return-slot arg — so EVERY monomorphized specific's `PrimitiveCopy` call
// has two args, and the handle_call.cpp arm must dispatch on the concrete
// init repr: by-copy specifics (Flag, i32) lower the call to the source
// VALUE (the consumer stores it), in-place specifics (Pair(i64)) memcpy
// into the slot and forward it.
fn Dup[T: Core.Copy](x: T) -> T {
  return x;
}

fn DupFlag(f: Flag) -> Flag { return Dup(f); }

fn DupInt(n: i32) -> i32 { return Dup(n); }

fn DupPair(p: Pair(i64)) -> Pair(i64) { return Dup(p); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'copy_rep.carbon'
// CHECK:STDOUT: source_filename = "copy_rep.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Flag.val.246 = internal constant { i1 } zeroinitializer
// CHECK:STDOUT: @Flag.val.cba = internal constant { i1 } { i1 true }
// CHECK:STDOUT: @Flag.val.cba.loc6_1.10 = internal constant { i1 } { i1 true }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassthrough.Main(ptr sret({ i1 }) %return, ptr %f) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %return, ptr align 1 %f, i64 1, i1 false), !dbg !17
// CHECK:STDOUT:   ret void, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeOn.Main(ptr sret({ i1 }) %return) #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %return, ptr align 1 @Flag.val.cba.loc6_1.10, i64 1, i1 false), !dbg !23
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "copy_rep.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Passthrough", linkageName: "_CPassthrough.Main", scope: null, file: !4, line: 9, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !19)
// CHECK:STDOUT: !13 = !DILocalVariable(arg: 1, scope: !12, type: !7)
// CHECK:STDOUT: !17 = !DILocation(line: 9, column: 42, scope: !12)
// CHECK:STDOUT: !18 = !DILocation(line: 9, column: 35, scope: !12)
// CHECK:STDOUT: !19 = !{!13}
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "MakeOn", linkageName: "_CMakeOn.Main", scope: null, file: !4, line: 12, type: !11, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !23 = !DILocation(line: 12, column: 30, scope: !20)
// CHECK:STDOUT: !24 = !DILocation(line: 12, column: 23, scope: !20)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'pointer_rep.carbon'
// CHECK:STDOUT: source_filename = "pointer_rep.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Pair.val.765 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.765.Copy.WithSelf.Op.call = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassthrough.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, ptr %p) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 %p, i64 24, i1 false), !dbg !39
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeNeither.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Pair.val.765.Copy.WithSelf.Op.call, i64 24, i1 false), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CRoundTrip.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, ptr %p) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %q.var = alloca <{ <{ i1, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !51
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %q.var), !dbg !51
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %q.var, ptr align 8 %p, i64 24, i1 false), !dbg !52
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %q.var, ptr align 8 @Pair.val.765.Copy.WithSelf.Op.call, i64 24, i1 false), !dbg !54
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 %q.var, i64 24, i1 false), !dbg !55
// CHECK:STDOUT:   call void @"_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %q.var), !dbg !51
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %self) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core"(ptr %self) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %self, i32 0, i32 1, !dbg !68
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem1.tuple.elem), !dbg !68
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %self, i32 0, i32 0, !dbg !68
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %tuple.elem0.tuple.elem), !dbg !68
// CHECK:STDOUT:   ret void, !dbg !68
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1ac55aaed189338e:core.Destroy.Core"(ptr %self) #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core"(ptr %self), !dbg !72
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.58ec237e1038f3e7:core.Destroy.Core"(ptr %self) #0 !dbg !74 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !76
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.58ec237e1038f3e7:core.Destroy.Core"(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.58ec237e1038f3e7:core.Destroy.Core"(ptr %self), !dbg !80
// CHECK:STDOUT:   ret void, !dbg !80
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.8acada488d131cf2:core.Destroy.Core"(ptr %self) #0 !dbg !82 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc19_3.1.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 1, !dbg !84
// CHECK:STDOUT:   call void @"_CSelfDestruct.58ec237e1038f3e7:core.Destroy.Core"(ptr %.loc19_3.1.payload), !dbg !84
// CHECK:STDOUT:   %.loc19_3.2.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %self, i32 0, i32 0, !dbg !84
// CHECK:STDOUT:   call void @"_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core"(ptr %.loc19_3.2.discriminant), !dbg !84
// CHECK:STDOUT:   ret void, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.8acada488d131cf2:core.Destroy.Core"(ptr %self) #0 !dbg !86 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.8acada488d131cf2:core.Destroy.Core"(ptr %self), !dbg !88
// CHECK:STDOUT:   ret void, !dbg !88
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %self) #0 !dbg !90 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %self) #0 !dbg !94 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.01ad5b36ba6d1c53:core.Destroy.Core"(ptr %self), !dbg !96
// CHECK:STDOUT:   ret void, !dbg !96
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.memcpy.p0.p0.i64, { 4, 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!26}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{!7}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !25 = !DIFile(filename: "pointer_rep.carbon", directory: "")
// CHECK:STDOUT: !26 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !25, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !27 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !28 = !{null, !6}
// CHECK:STDOUT: !29 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !30 = !{null, !27}
// CHECK:STDOUT: !31 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !32 = !{null, !7}
// CHECK:STDOUT: !33 = !DISubroutineType(types: !32)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Passthrough", linkageName: "_CPassthrough.Main", scope: null, file: !25, line: 10, type: !9, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !41)
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 1, scope: !34, type: !7)
// CHECK:STDOUT: !39 = !DILocation(line: 10, column: 52, scope: !34)
// CHECK:STDOUT: !40 = !DILocation(line: 10, column: 45, scope: !34)
// CHECK:STDOUT: !41 = !{!35}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "MakeNeither", linkageName: "_CMakeNeither.Main", scope: null, file: !25, line: 14, type: !11, spFlags: DISPFlagDefinition, unit: !26)
// CHECK:STDOUT: !45 = !DILocation(line: 14, column: 33, scope: !42)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "RoundTrip", linkageName: "_CRoundTrip.Main", scope: null, file: !25, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !57)
// CHECK:STDOUT: !47 = !DILocalVariable(arg: 1, scope: !46, type: !7)
// CHECK:STDOUT: !51 = !DILocation(line: 19, column: 3, scope: !46)
// CHECK:STDOUT: !52 = !DILocation(line: 19, column: 22, scope: !46)
// CHECK:STDOUT: !54 = !DILocation(line: 20, column: 3, scope: !46)
// CHECK:STDOUT: !55 = !DILocation(line: 21, column: 10, scope: !46)
// CHECK:STDOUT: !56 = !DILocation(line: 21, column: 3, scope: !46)
// CHECK:STDOUT: !57 = !{!47}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.a968c23fcb066b44:core.Destroy.Core", scope: null, file: !25, line: 19, type: !29, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !61)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !6)
// CHECK:STDOUT: !60 = !DILocation(line: 19, column: 3, scope: !58)
// CHECK:STDOUT: !61 = !{!59}
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !25, line: 19, type: !31, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !65)
// CHECK:STDOUT: !63 = !DILocalVariable(arg: 1, scope: !62, type: !27)
// CHECK:STDOUT: !64 = !DILocation(line: 19, column: 3, scope: !62)
// CHECK:STDOUT: !65 = !{!63}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1ac55aaed189338e:core.Destroy.Core", scope: null, file: !25, line: 19, type: !33, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !69)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !7)
// CHECK:STDOUT: !68 = !DILocation(line: 19, column: 3, scope: !66)
// CHECK:STDOUT: !69 = !{!67}
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1ac55aaed189338e:core.Destroy.Core", scope: null, file: !25, line: 19, type: !33, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !73)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !7)
// CHECK:STDOUT: !72 = !DILocation(line: 19, column: 3, scope: !70)
// CHECK:STDOUT: !73 = !{!71}
// CHECK:STDOUT: !74 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.58ec237e1038f3e7:core.Destroy.Core", scope: null, file: !25, line: 19, type: !33, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !77)
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !74, type: !7)
// CHECK:STDOUT: !76 = !DILocation(line: 19, column: 3, scope: !74)
// CHECK:STDOUT: !77 = !{!75}
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.58ec237e1038f3e7:core.Destroy.Core", scope: null, file: !25, line: 19, type: !33, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !81)
// CHECK:STDOUT: !79 = !DILocalVariable(arg: 1, scope: !78, type: !7)
// CHECK:STDOUT: !80 = !DILocation(line: 19, column: 3, scope: !78)
// CHECK:STDOUT: !81 = !{!79}
// CHECK:STDOUT: !82 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.8acada488d131cf2:core.Destroy.Core", scope: null, file: !25, line: 19, type: !33, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !85)
// CHECK:STDOUT: !83 = !DILocalVariable(arg: 1, scope: !82, type: !7)
// CHECK:STDOUT: !84 = !DILocation(line: 19, column: 3, scope: !82)
// CHECK:STDOUT: !85 = !{!83}
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.8acada488d131cf2:core.Destroy.Core", scope: null, file: !25, line: 19, type: !33, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !89)
// CHECK:STDOUT: !87 = !DILocalVariable(arg: 1, scope: !86, type: !7)
// CHECK:STDOUT: !88 = !DILocation(line: 19, column: 3, scope: !86)
// CHECK:STDOUT: !89 = !{!87}
// CHECK:STDOUT: !90 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.01ad5b36ba6d1c53:core.Destroy.Core", scope: null, file: !25, line: 19, type: !33, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !93)
// CHECK:STDOUT: !91 = !DILocalVariable(arg: 1, scope: !90, type: !7)
// CHECK:STDOUT: !92 = !DILocation(line: 19, column: 3, scope: !90)
// CHECK:STDOUT: !93 = !{!91}
// CHECK:STDOUT: !94 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.01ad5b36ba6d1c53:core.Destroy.Core", scope: null, file: !25, line: 19, type: !33, spFlags: DISPFlagDefinition, unit: !26, retainedNodes: !97)
// CHECK:STDOUT: !95 = !DILocalVariable(arg: 1, scope: !94, type: !7)
// CHECK:STDOUT: !96 = !DILocation(line: 19, column: 3, scope: !94)
// CHECK:STDOUT: !97 = !{!95}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'mono_from_generic.carbon'
// CHECK:STDOUT: source_filename = "mono_from_generic.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Flag.val.246 = internal constant { i1 } zeroinitializer
// CHECK:STDOUT: @Flag.val.cba = internal constant { i1 } { i1 true }
// CHECK:STDOUT: @Pair.val.765 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CDupFlag.Main(ptr sret({ i1 }) %return, ptr %f) #0 !dbg !103 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDup.Main.cb2677857c8370ba(ptr %return, ptr %f), !dbg !109
// CHECK:STDOUT:   ret void, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CDupInt.Main(i32 %n) #0 !dbg !112 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Dup.call = call i32 @_CDup.Main.4d6ceefeb7f772f4(i32 %n), !dbg !118
// CHECK:STDOUT:   ret i32 %Dup.call, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CDupPair.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, ptr %p) #0 !dbg !121 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDup.Main.bcbe9a4a5a533a77(ptr %return, ptr %p), !dbg !127
// CHECK:STDOUT:   ret void, !dbg !128
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDup.Main.cb2677857c8370ba(ptr sret({ i1 }) %return, ptr %x) #0 !dbg !130 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %return, ptr align 1 %x, i64 1, i1 false), !dbg !135
// CHECK:STDOUT:   ret void, !dbg !136
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CDup.Main.4d6ceefeb7f772f4(i32 %x) #0 !dbg !138 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %x, !dbg !144
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDup.Main.bcbe9a4a5a533a77(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, ptr %x) #0 !dbg !146 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 %x, i64 24, i1 false), !dbg !151
// CHECK:STDOUT:   ret void, !dbg !152
// CHECK:STDOUT: }
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!99}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!7, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !98 = !DIFile(filename: "mono_from_generic.carbon", directory: "")
// CHECK:STDOUT: !99 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !98, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !100 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !101 = !{!100, !100}
// CHECK:STDOUT: !102 = !DISubroutineType(types: !101)
// CHECK:STDOUT: !103 = distinct !DISubprogram(name: "DupFlag", linkageName: "_CDupFlag.Main", scope: null, file: !98, line: 25, type: !9, spFlags: DISPFlagDefinition, unit: !99, retainedNodes: !111)
// CHECK:STDOUT: !104 = !DILocalVariable(arg: 1, scope: !103, type: !7)
// CHECK:STDOUT: !109 = !DILocation(line: 25, column: 38, scope: !103)
// CHECK:STDOUT: !110 = !DILocation(line: 25, column: 31, scope: !103)
// CHECK:STDOUT: !111 = !{!104}
// CHECK:STDOUT: !112 = distinct !DISubprogram(name: "DupInt", linkageName: "_CDupInt.Main", scope: null, file: !98, line: 27, type: !102, spFlags: DISPFlagDefinition, unit: !99, retainedNodes: !120)
// CHECK:STDOUT: !113 = !DILocalVariable(arg: 1, scope: !112, type: !100)
// CHECK:STDOUT: !118 = !DILocation(line: 27, column: 35, scope: !112)
// CHECK:STDOUT: !119 = !DILocation(line: 27, column: 28, scope: !112)
// CHECK:STDOUT: !120 = !{!113}
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "DupPair", linkageName: "_CDupPair.Main", scope: null, file: !98, line: 29, type: !9, spFlags: DISPFlagDefinition, unit: !99, retainedNodes: !129)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !121, type: !7)
// CHECK:STDOUT: !127 = !DILocation(line: 29, column: 48, scope: !121)
// CHECK:STDOUT: !128 = !DILocation(line: 29, column: 41, scope: !121)
// CHECK:STDOUT: !129 = !{!122}
// CHECK:STDOUT: !130 = distinct !DISubprogram(name: "Dup", linkageName: "_CDup.Main.cb2677857c8370ba", scope: null, file: !98, line: 21, type: !9, spFlags: DISPFlagDefinition, unit: !99, retainedNodes: !137)
// CHECK:STDOUT: !131 = !DILocalVariable(arg: 1, scope: !130, type: !7)
// CHECK:STDOUT: !135 = !DILocation(line: 22, column: 10, scope: !130)
// CHECK:STDOUT: !136 = !DILocation(line: 22, column: 3, scope: !130)
// CHECK:STDOUT: !137 = !{!131}
// CHECK:STDOUT: !138 = distinct !DISubprogram(name: "Dup", linkageName: "_CDup.Main.4d6ceefeb7f772f4", scope: null, file: !98, line: 21, type: !102, spFlags: DISPFlagDefinition, unit: !99, retainedNodes: !145)
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !138, type: !100)
// CHECK:STDOUT: !144 = !DILocation(line: 22, column: 3, scope: !138)
// CHECK:STDOUT: !145 = !{!139}
// CHECK:STDOUT: !146 = distinct !DISubprogram(name: "Dup", linkageName: "_CDup.Main.bcbe9a4a5a533a77", scope: null, file: !98, line: 21, type: !9, spFlags: DISPFlagDefinition, unit: !99, retainedNodes: !153)
// CHECK:STDOUT: !147 = !DILocalVariable(arg: 1, scope: !146, type: !7)
// CHECK:STDOUT: !151 = !DILocation(line: 22, column: 10, scope: !146)
// CHECK:STDOUT: !152 = !DILocation(line: 22, column: 3, scope: !146)
// CHECK:STDOUT: !153 = !{!147}
// CHECK:STDOUT:
