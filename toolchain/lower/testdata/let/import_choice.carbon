// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/let/import_choice.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/let/import_choice.carbon

// The POINTER-value-rep arm of the file-scope runtime `let` promotion
// (W-069 W69b): for classes, choices, and multi-element tuples the backing
// global holds the OBJECT representation, `__global_init` fills it once with
// a memcpy from the bound value's pointer (the as-if copy license,
// docs/design/values.md), and every reference — same-file cross-function or
// cross-file — is served the global's ADDRESS as the value representation
// (the same shape a by-value parameter's pointer takes). The plib subfiles
// are the lower-side pin of the RESTORED W-069 ledger acceptance split
// (check/testdata/match/choice_generic_payload_scrutinee.carbon): the
// importer's `match (g)` reads the discriminant through the external
// object-rep global. The constant-bound sibling `gc` keeps riding the
// constant path (half (b)) — no `_Cgc` global may appear. (A CHECK-less
// golden cannot assert absence: that claim is enforced by the reviewer
// audit over this file's filled content, named here per the W69b fix
// round.)
//
// The `gc` consumptions additionally pin a PRE-EXISTING constant-lowering
// defect this probe surfaced (W69b post-fix crash round): a match on a
// constant-bound choice folds the discriminant `class_element_access` to a
// value-category `[concrete]` constant, and `AcquireValue`'s copy arm used
// to load from that served VALUE as if it were an address (LLVM "Ptr must
// have pointer type" assert). Fixed in handle_expr_category.cpp /
// FunctionContext::GetValueServesConstantValueRep: the folded constant is
// the acquired value, no load. Import-independent — pinned both same-file
// (plib's SameFileConst) and cross-file (imported_global_constant's G).

// --- plib.carbon

library "[[@TEST_NAME]]";

choice P(T: type) {
  Both(x: T, y: T),
  Neither
}

fn MakeRuntime() -> P(i64) { return P(i64).Both(1, 2); }

// Runtime-bound: promoted to an object-rep global + ctor memcpy.
let g: P(i64) = MakeRuntime();

// Constant-bound: imports as the alternative's constant, never promoted.
let gc: P(i64) = P(i64).Neither;

// The same-file cross-function half of the pointer arm: the scrutinee value
// is the global's address.
fn SameFile() -> i32 {
  match (g) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

// The same-file half of the constant-path consumption: `gc`'s discriminant
// access folds `[concrete]`, so the acquired comparison operand is the
// folded constant itself — no load, no promoted global (the crash-round
// defect was import-independent).
fn SameFileConst() -> i32 {
  match (gc) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

// --- imported_global.carbon

library "[[@TEST_NAME]]";

import library "plib";

// The restored ledger acceptance split's importing side: the discriminant
// load rides the external `_Cg.Main` object-rep global's address.
fn F() -> i32 {
  match (g) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

// --- imported_global_constant.carbon

library "[[@TEST_NAME]]";

import library "plib";

// The half-(b) boundary: `gc` imports as a constant and lowers through the
// constant path — no external `_Cgc` symbol.
fn G() -> i32 {
  match (gc) {
    case .Neither => { return 0; }
    default => { return 1; }
  }
}

// --- pt.carbon

library "[[@TEST_NAME]]";

class Pt {
  var x: i32;
  var y: i32;
}

fn MakePt() -> Pt { return {.x = 30, .y = 40}; }

// A class-typed (non-choice) runtime `let`, so the pointer arm is pinned
// independent of choice machinery.
let origin: Pt = MakePt();

// Same-file FIELD READ through the promoted global's address.
fn SameFileX() -> i32 { return origin.x; }

// --- import_pt.carbon

library "[[@TEST_NAME]]";

import library "pt";

// Cross-file FIELD READ consumption of the class-typed binding.
fn ReadX() -> i32 { return origin.x; }

// --- pair.carbon

library "[[@TEST_NAME]]";

fn MakePair() -> (i32, i32) { return (50, 60); }

// P-10, narrowed at the crash round to DECLARATION-ONLY (contrast the
// tuple-PATTERN elementwise promotion in let/global_runtime.carbon): a
// whole-tuple-typed runtime `let` has an aggregate value representation
// that is not a copy of the object representation, so the promotion
// pre-pass DECLINES it per the plan's ValueRepr dispatch — declaration
// stays silent (pinned here: this file lowers with `t` declared), and
// ANY reference FATALs loudly by design ("...which the promotion
// pre-pass declined... is not supported yet (W-069)", pinned by
// autoupdate run 32148462189's crash — un-goldenable in-process, so the
// consuming probe form is recorded as workstream residue in
// fork/w069/plan.md rather than as a golden).
let t: (i32, i32) = MakePair();

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'plib.carbon'
// CHECK:STDOUT: source_filename = "plib.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @P.val.c4c = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @_Cg.Main = global <{ <{ i1, [7 x i8] }>, [16 x i8] }> zeroinitializer
// CHECK:STDOUT: @P.val.c4c.Neither.ref = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT: @P.val.72b.loc4_19.7 = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> zeroinitializer
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakeRuntime.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return) #0 !dbg !14 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CBoth.P.Main.f249b435619a5146(ptr %return, i64 1, i64 2), !dbg !17
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSameFile.Main() #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc21_19.4 = load i8, ptr @_Cg.Main, align 1, !dbg !25
// CHECK:STDOUT:   %.loc21_19.41 = trunc i8 %.loc21_19.4 to i1, !dbg !25
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc21_19.41, !dbg !25
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !25
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !26
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSameFileConst.Main() #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc32_19.4 = load i8, ptr @P.val.c4c.Neither.ref, align 1, !dbg !32
// CHECK:STDOUT:   %.loc32_19.41 = trunc i8 %.loc32_19.4 to i1, !dbg !32
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc32_19.41, !dbg !32
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !32
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !33
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CBoth.P.Main.f249b435619a5146(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>) %return, i64 %_, i64 %_1) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc4_19.1.discriminant = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 0, !dbg !43
// CHECK:STDOUT:   %.loc4_19.4.payload = getelementptr inbounds nuw <{ <{ i1, [7 x i8] }>, [16 x i8] }>, ptr %return, i32 0, i32 1, !dbg !43
// CHECK:STDOUT:   %.loc4_19.5.Both = getelementptr inbounds nuw [16 x i8], ptr %.loc4_19.4.payload, i32 0, i32 0, !dbg !43
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %return, ptr align 8 @P.val.72b.loc4_19.7, i64 24, i1 false), !dbg !43
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc4_19.5.Both, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   store i64 %_, ptr %tuple.elem0.tuple.elem, align 8, !dbg !44
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i64, i64 }, ptr %.loc4_19.5.Both, i32 0, i32 1, !dbg !44
// CHECK:STDOUT:   store i64 %_1, ptr %tuple.elem1.tuple.elem, align 8, !dbg !44
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12.temp = alloca <{ <{ i1, [7 x i8] }>, [16 x i8] }>, align 8, !dbg !38
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc12.temp), !dbg !38
// CHECK:STDOUT:   call void @_CMakeRuntime.Main(ptr %.loc12.temp), !dbg !38
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 @_Cg.Main, ptr align 8 %.loc12.temp, i64 24, i1 false)
// CHECK:STDOUT:   ret void, !dbg !39
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "plib.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!8}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = distinct !DISubprogram(name: "MakeRuntime", linkageName: "_CMakeRuntime.Main", scope: null, file: !4, line: 9, type: !11, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !17 = !DILocation(line: 9, column: 37, scope: !14)
// CHECK:STDOUT: !18 = !{!9, !7, !7}
// CHECK:STDOUT: !19 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !20 = !DILocation(line: 9, column: 30, scope: !14)
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "SameFile", linkageName: "_CSameFile.Main", scope: null, file: !4, line: 19, type: !13, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !25 = !DILocation(line: 21, column: 5, scope: !21)
// CHECK:STDOUT: !26 = !DILocation(line: 21, column: 24, scope: !21)
// CHECK:STDOUT: !27 = !DILocation(line: 22, column: 18, scope: !21)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "SameFileConst", linkageName: "_CSameFileConst.Main", scope: null, file: !4, line: 30, type: !13, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !32 = !DILocation(line: 32, column: 5, scope: !28)
// CHECK:STDOUT: !33 = !DILocation(line: 32, column: 24, scope: !28)
// CHECK:STDOUT: !34 = !DILocation(line: 33, column: 18, scope: !28)
// CHECK:STDOUT: !35 = !{null}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !4, type: !36, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !38 = !DILocation(line: 12, column: 17, scope: !37)
// CHECK:STDOUT: !39 = !DILocation(line: 0, scope: !37)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Both", linkageName: "_CBoth.P.Main.f249b435619a5146", scope: null, file: !4, line: 4, type: !19, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !45)
// CHECK:STDOUT: !41 = !DILocalVariable(arg: 1, scope: !40, type: !7)
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 2, scope: !40, type: !7)
// CHECK:STDOUT: !43 = !DILocation(line: 4, column: 1, scope: !40)
// CHECK:STDOUT: !44 = !DILocation(line: 5, column: 19, scope: !40)
// CHECK:STDOUT: !45 = !{!41, !42}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'imported_global.carbon'
// CHECK:STDOUT: source_filename = "imported_global.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @P.val.c4c = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @const = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT: @_Cg.Main = external global <{ <{ i1, [7 x i8] }>, [16 x i8] }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CF.Main() #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc10_19.4 = load i8, ptr @_Cg.Main, align 1, !dbg !52
// CHECK:STDOUT:   %.loc10_19.41 = trunc i8 %.loc10_19.4 to i1, !dbg !52
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call = icmp eq i1 true, %.loc10_19.41, !dbg !52
// CHECK:STDOUT:   br i1 %UInt.as.EqWith.impl.Equal.call, label %match.case.then, label %match.case.else, !dbg !52
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !53
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !54
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CMakeRuntime.Main(ptr sret(<{ <{ i1, [7 x i8] }>, [16 x i8] }>))
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSameFile.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSameFileConst.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!47}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !12 = !{!8}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !46 = !DIFile(filename: "imported_global.carbon", directory: "")
// CHECK:STDOUT: !47 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !46, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !46, line: 8, type: !13, spFlags: DISPFlagDefinition, unit: !47)
// CHECK:STDOUT: !52 = !DILocation(line: 10, column: 5, scope: !48)
// CHECK:STDOUT: !53 = !DILocation(line: 10, column: 24, scope: !48)
// CHECK:STDOUT: !54 = !DILocation(line: 11, column: 18, scope: !48)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'imported_global_constant.carbon'
// CHECK:STDOUT: source_filename = "imported_global_constant.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @P.val.c4c = internal constant <{ <{ i1, [7 x i8] }>, [16 x i8] }> <{ <{ i1, [7 x i8] }> <{ i1 true, [7 x i8] zeroinitializer }>, [16 x i8] zeroinitializer }>
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CG.Main() #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 true, label %match.case.then, label %match.case.else, !dbg !60
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.then:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 0, !dbg !61
// CHECK:STDOUT:
// CHECK:STDOUT: match.case.else:                                  ; preds = %entry
// CHECK:STDOUT:   ret i32 1, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!56}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !12 = !{!8}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !55 = !DIFile(filename: "imported_global_constant.carbon", directory: "")
// CHECK:STDOUT: !56 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !55, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !55, line: 8, type: !13, spFlags: DISPFlagDefinition, unit: !56)
// CHECK:STDOUT: !60 = !DILocation(line: 10, column: 5, scope: !57)
// CHECK:STDOUT: !61 = !DILocation(line: 10, column: 24, scope: !57)
// CHECK:STDOUT: !62 = !DILocation(line: 11, column: 18, scope: !57)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'pt.carbon'
// CHECK:STDOUT: source_filename = "pt.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Corigin.Main = global { i32, i32 } zeroinitializer
// CHECK:STDOUT: @Pt.val.loc9_46 = internal constant { i32, i32 } { i32 30, i32 40 }
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakePt.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !65 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9_45.3.x = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !68
// CHECK:STDOUT:   %.loc9_45.6.y = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !68
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Pt.val.loc9_46, i64 8, i1 false), !dbg !69
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CSameFileX.Main() #0 !dbg !70 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_38.2 = load i32, ptr @_Corigin.Main, align 4, !dbg !73
// CHECK:STDOUT:   ret i32 %.loc16_38.2, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13.temp = alloca { i32, i32 }, align 4, !dbg !76
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc13.temp), !dbg !76
// CHECK:STDOUT:   call void @_CMakePt.Main(ptr %.loc13.temp), !dbg !76
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 @_Corigin.Main, ptr align 4 %.loc13.temp, i64 8, i1 false)
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!64}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!8}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !35 = !{null}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !63 = !DIFile(filename: "pt.carbon", directory: "")
// CHECK:STDOUT: !64 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !63, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !65 = distinct !DISubprogram(name: "MakePt", linkageName: "_CMakePt.Main", scope: null, file: !63, line: 9, type: !11, spFlags: DISPFlagDefinition, unit: !64)
// CHECK:STDOUT: !68 = !DILocation(line: 9, column: 28, scope: !65)
// CHECK:STDOUT: !69 = !DILocation(line: 9, column: 21, scope: !65)
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "SameFileX", linkageName: "_CSameFileX.Main", scope: null, file: !63, line: 16, type: !13, spFlags: DISPFlagDefinition, unit: !64)
// CHECK:STDOUT: !73 = !DILocation(line: 16, column: 32, scope: !70)
// CHECK:STDOUT: !74 = !DILocation(line: 16, column: 25, scope: !70)
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !63, type: !36, spFlags: DISPFlagDefinition, unit: !64)
// CHECK:STDOUT: !76 = !DILocation(line: 13, column: 18, scope: !75)
// CHECK:STDOUT: !77 = !DILocation(line: 0, scope: !75)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_pt.carbon'
// CHECK:STDOUT: source_filename = "import_pt.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Corigin.Main = external global { i32, i32 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadX.Main() #0 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_34.2 = load i32, ptr @_Corigin.Main, align 4, !dbg !83
// CHECK:STDOUT:   ret i32 %.loc7_34.2, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_CMakePt.Main(ptr sret({ i32, i32 }))
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @_CSameFileX.Main()
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!79}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !8 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !12 = !{!8}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !78 = !DIFile(filename: "import_pt.carbon", directory: "")
// CHECK:STDOUT: !79 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !78, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "ReadX", linkageName: "_CReadX.Main", scope: null, file: !78, line: 7, type: !13, spFlags: DISPFlagDefinition, unit: !79)
// CHECK:STDOUT: !83 = !DILocation(line: 7, column: 28, scope: !80)
// CHECK:STDOUT: !84 = !DILocation(line: 7, column: 21, scope: !80)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'pair.carbon'
// CHECK:STDOUT: source_filename = "pair.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @tuple.c1d.loc4_46 = internal constant { i32, i32 } { i32 50, i32 60 }
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMakePair.Main(ptr sret({ i32, i32 }) %return) #0 !dbg !87 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %tuple.elem0.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 0, !dbg !90
// CHECK:STDOUT:   %tuple.elem1.tuple.elem = getelementptr inbounds nuw { i32, i32 }, ptr %return, i32 0, i32 1, !dbg !90
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @tuple.c1d.loc4_46, i64 8, i1 false), !dbg !91
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #0 !dbg !92 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17.temp = alloca { i32, i32 }, align 4, !dbg !93
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc17.temp), !dbg !93
// CHECK:STDOUT:   call void @_CMakePair.Main(ptr %.loc17.temp), !dbg !93
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!86}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !9 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !10 = !{!9}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !35 = !{null}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !85 = !DIFile(filename: "pair.carbon", directory: "")
// CHECK:STDOUT: !86 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !85, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !87 = distinct !DISubprogram(name: "MakePair", linkageName: "_CMakePair.Main", scope: null, file: !85, line: 4, type: !11, spFlags: DISPFlagDefinition, unit: !86)
// CHECK:STDOUT: !90 = !DILocation(line: 4, column: 38, scope: !87)
// CHECK:STDOUT: !91 = !DILocation(line: 4, column: 31, scope: !87)
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !85, type: !36, spFlags: DISPFlagDefinition, unit: !86)
// CHECK:STDOUT: !93 = !DILocation(line: 17, column: 21, scope: !92)
// CHECK:STDOUT: !94 = !DILocation(line: 0, scope: !92)
// CHECK:STDOUT:
