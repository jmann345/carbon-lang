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
// CHECK:STDOUT: define void @_CPassthrough.Main(ptr sret({ i1 }) %return, ptr %f) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %return, ptr align 1 %f, i64 1, i1 false), !dbg !10
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeOn.Main(ptr sret({ i1 }) %return) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %return, ptr align 1 @Flag.val.cba.loc6_1.10, i64 1, i1 false), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !16
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "copy_rep.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Passthrough", linkageName: "_CPassthrough.Main", scope: null, file: !1, line: 9, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 9, column: 42, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 9, column: 35, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "MakeOn", linkageName: "_CMakeOn.Main", scope: null, file: !1, line: 12, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!7}
// CHECK:STDOUT: !15 = !DILocation(line: 12, column: 30, scope: !12)
// CHECK:STDOUT: !16 = !DILocation(line: 12, column: 23, scope: !12)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'pointer_rep.carbon'
// CHECK:STDOUT: source_filename = "pointer_rep.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @Pair.val.765 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @Pair.val.765.Copy.Op.call = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassthrough.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, ptr %p) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 %p, i64 24, i1 false), !dbg !10
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeNeither.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @Pair.val.765.Copy.Op.call, i64 24, i1 false), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !15
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CRoundTrip.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, ptr %p) #0 !dbg !16 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %q.var = alloca <{ <{ i1, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !19
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %q.var), !dbg !19
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %q.var, ptr align 8 %p, i64 24, i1 false), !dbg !20
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %q.var, ptr align 8 @Pair.val.765.Copy.Op.call, i64 24, i1 false), !dbg !21
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 %q.var, i64 24, i1 false), !dbg !22
// CHECK:STDOUT:   call void @"_COp.2a13650ae73377d1:core.Destroy.Core"(ptr %q.var), !dbg !19
// CHECK:STDOUT:   ret void, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.945345cbed56cb88:core.Destroy.Core"(ptr %self) #0 !dbg !24 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.a0c53c6ec44084d2:core.Destroy.Core"(ptr %self) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.6400f2e0f1944637:core.Destroy.Core"(ptr %self) #0 !dbg !44 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.2624439af566ac2c:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.2a13650ae73377d1:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "pointer_rep.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "Passthrough", linkageName: "_CPassthrough.Main", scope: null, file: !1, line: 10, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 10, column: 52, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 10, column: 45, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "MakeNeither", linkageName: "_CMakeNeither.Main", scope: null, file: !1, line: 14, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!7}
// CHECK:STDOUT: !15 = !DILocation(line: 14, column: 33, scope: !12)
// CHECK:STDOUT: !16 = distinct !DISubprogram(name: "RoundTrip", linkageName: "_CRoundTrip.Main", scope: null, file: !1, line: 18, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !17)
// CHECK:STDOUT: !17 = !{!18}
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !16, type: !7)
// CHECK:STDOUT: !19 = !DILocation(line: 19, column: 3, scope: !16)
// CHECK:STDOUT: !20 = !DILocation(line: 19, column: 22, scope: !16)
// CHECK:STDOUT: !21 = !DILocation(line: 20, column: 3, scope: !16)
// CHECK:STDOUT: !22 = !DILocation(line: 21, column: 10, scope: !16)
// CHECK:STDOUT: !23 = !DILocation(line: 21, column: 3, scope: !16)
// CHECK:STDOUT: !24 = distinct !DISubprogram(name: "Op", linkageName: "_COp.945345cbed56cb88:core.Destroy.Core", scope: null, file: !1, line: 19, type: !25, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !28)
// CHECK:STDOUT: !25 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !26 = !{null, !27}
// CHECK:STDOUT: !27 = !DIBasicType(name: "int", size: 1, encoding: DW_ATE_unsigned)
// CHECK:STDOUT: !28 = !{!29}
// CHECK:STDOUT: !29 = !DILocalVariable(arg: 1, scope: !24, type: !27)
// CHECK:STDOUT: !30 = !DILocation(line: 19, column: 3, scope: !24)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 19, type: !32, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !32 = !DISubroutineType(types: !33)
// CHECK:STDOUT: !33 = !{null, !34}
// CHECK:STDOUT: !34 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !31, type: !34)
// CHECK:STDOUT: !37 = !DILocation(line: 19, column: 3, scope: !31)
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a0c53c6ec44084d2:core.Destroy.Core", scope: null, file: !1, line: 19, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !41)
// CHECK:STDOUT: !39 = !DISubroutineType(types: !40)
// CHECK:STDOUT: !40 = !{null, !7}
// CHECK:STDOUT: !41 = !{!42}
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !38, type: !7)
// CHECK:STDOUT: !43 = !DILocation(line: 19, column: 3, scope: !38)
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "Op", linkageName: "_COp.6400f2e0f1944637:core.Destroy.Core", scope: null, file: !1, line: 19, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !45)
// CHECK:STDOUT: !45 = !{!46}
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !44, type: !7)
// CHECK:STDOUT: !47 = !DILocation(line: 19, column: 3, scope: !44)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Op", linkageName: "_COp.2624439af566ac2c:core.Destroy.Core", scope: null, file: !1, line: 19, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !49)
// CHECK:STDOUT: !49 = !{!50}
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !48, type: !7)
// CHECK:STDOUT: !51 = !DILocation(line: 19, column: 3, scope: !48)
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "Op", linkageName: "_COp.2a13650ae73377d1:core.Destroy.Core", scope: null, file: !1, line: 19, type: !39, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !53 = !{!54}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !52, type: !7)
// CHECK:STDOUT: !55 = !DILocation(line: 19, column: 3, scope: !52)
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
// CHECK:STDOUT: define void @_CDupFlag.Main(ptr sret({ i1 }) %return, ptr %f) #0 !dbg !4 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDup.Main.c58310d07baca4e0(ptr %return, ptr %f), !dbg !10
// CHECK:STDOUT:   ret void, !dbg !11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CDupInt.Main(i32 %n) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Dup.call = call i32 @_CDup.Main.4d6ceefeb7f772f4(i32 %n), !dbg !18
// CHECK:STDOUT:   ret i32 %Dup.call, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CDupPair.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, ptr %p) #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CDup.Main.37db2b9356d6f1dc(ptr %return, ptr %p), !dbg !23
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDup.Main.c58310d07baca4e0(ptr sret({ i1 }) %return, ptr %x) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 1 %return, ptr align 1 %x, i64 1, i1 false), !dbg !28
// CHECK:STDOUT:   ret void, !dbg !29
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @_CDup.Main.4d6ceefeb7f772f4(i32 %x) #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 %x, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CDup.Main.37db2b9356d6f1dc(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, ptr %x) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 %x, i64 24, i1 false), !dbg !37
// CHECK:STDOUT:   ret void, !dbg !38
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "mono_from_generic.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = distinct !DISubprogram(name: "DupFlag", linkageName: "_CDupFlag.Main", scope: null, file: !1, line: 25, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
// CHECK:STDOUT: !5 = !DISubroutineType(types: !6)
// CHECK:STDOUT: !6 = !{!7, !7}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{!9}
// CHECK:STDOUT: !9 = !DILocalVariable(arg: 1, scope: !4, type: !7)
// CHECK:STDOUT: !10 = !DILocation(line: 25, column: 38, scope: !4)
// CHECK:STDOUT: !11 = !DILocation(line: 25, column: 31, scope: !4)
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "DupInt", linkageName: "_CDupInt.Main", scope: null, file: !1, line: 27, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!15, !15}
// CHECK:STDOUT: !15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !12, type: !15)
// CHECK:STDOUT: !18 = !DILocation(line: 27, column: 35, scope: !12)
// CHECK:STDOUT: !19 = !DILocation(line: 27, column: 28, scope: !12)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "DupPair", linkageName: "_CDupPair.Main", scope: null, file: !1, line: 29, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !21)
// CHECK:STDOUT: !21 = !{!22}
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !20, type: !7)
// CHECK:STDOUT: !23 = !DILocation(line: 29, column: 48, scope: !20)
// CHECK:STDOUT: !24 = !DILocation(line: 29, column: 41, scope: !20)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Dup", linkageName: "_CDup.Main.c58310d07baca4e0", scope: null, file: !1, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
// CHECK:STDOUT: !26 = !{!27}
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !25, type: !7)
// CHECK:STDOUT: !28 = !DILocation(line: 22, column: 10, scope: !25)
// CHECK:STDOUT: !29 = !DILocation(line: 22, column: 3, scope: !25)
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "Dup", linkageName: "_CDup.Main.4d6ceefeb7f772f4", scope: null, file: !1, line: 21, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !31)
// CHECK:STDOUT: !31 = !{!32}
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !30, type: !15)
// CHECK:STDOUT: !33 = !DILocation(line: 22, column: 3, scope: !30)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "Dup", linkageName: "_CDup.Main.37db2b9356d6f1dc", scope: null, file: !1, line: 21, type: !5, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !35)
// CHECK:STDOUT: !35 = !{!36}
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !34, type: !7)
// CHECK:STDOUT: !37 = !DILocation(line: 22, column: 10, scope: !34)
// CHECK:STDOUT: !38 = !DILocation(line: 22, column: 3, scope: !34)
// CHECK:STDOUT:
