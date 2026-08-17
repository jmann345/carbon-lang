// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/globals_carbon_defined.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/globals_carbon_defined.carbon

// The F8a mechanism probe for defect TA-D3 (fork/f008/plan.md §2.1/§2.3):
// CARBON-defined file-scope globals of imported C++ class types — the
// SPECIALIZATION-typed shape that was measured to compile but link with
// `undefined symbol: _Cgcount.Main.1` (real `<atomic>`,
// fork/design-sprint/threading-atomics.md:103), next to the plain
// imported-class control that links fine (matrix row 14). The autoupdated
// IR dump shows, in a reviewed diff, whether `g`'s global is one defined
// object, a bare declaration missed by the definition walk, or a duplicate
// `.1`-suffixed pair — distinguishing fix-site hypotheses H1-H3. Dump-only:
// this golden never LINKS, so it cannot adjudicate H0 ("fixed upstream");
// H0 is settled by F8c's first-step runner run of the real-header pair
// cpp_atomic_global_counter_diff (plan §2.3, adjudication D). The imported
// direction (C++-owned globals, no Carbon-side definition emitted) is
// covered by globals.carbon and must not move (plan §5 R-5).
//
// The third split (added at F8c) mirrors the failing pair's full shape —
// member CALLS on the specialization-typed global from more than one
// function — which the field-access split does not exercise; its pin is
// described at the split.

// --- box.h

template <typename T> struct Box {
  T value;
};

struct Plain {
  int n;
};

// --- carbon_defined_globals.carbon

library "[[@TEST_NAME]]";

import Cpp library "box.h";

// The defect shape: a file-scope Carbon var typed by an imported C++
// template specialization.
var g: Cpp.Box(i32);

// The control: a plain imported-class-typed Carbon global.
var m: Cpp.Plain;

fn ReadSpecialized() -> i32 {
  return g.value;
}

fn ReadPlain() -> i32 {
  return m.n;
}

// --- counter.h

template <typename T> struct Counter {
  T value;
  void store(T v) { value = v; }
  T fetch_add(T v) {
    T old = value;
    value += v;
    return old;
  }
  T load() { return value; }
};

// --- carbon_defined_member_calls.carbon

library "[[@TEST_NAME]]";

import Cpp library "counter.h";

// The failing conformance pair's shape (fork/f008/plan.md §2.3;
// cpp_atomic_global_counter_diff): a file-scope Carbon var typed by an
// imported C++ template SPECIALIZATION whose members the Carbon side CALLS,
// from more than one function — the ingredient the field-access split above
// lacks. The measured defect bound each function's thunk-call references to
// a fresh `.N`-renamed duplicate of the global (`undefined symbol:
// _Ctotal.Main.2` / `.3`, adjudication run 2026-08-17) while the definition
// stayed on another object. The pin (plan §5 R-4): the dump must contain the
// DEFINITION `@_Ctotal.Main = global ...` and every reference must use that
// SAME symbol; a reference to a symbol no definition carries, or any
// `.N`-suffixed duplicate of the global, falsifies the fix.
var total: Cpp.Counter(i32);

// Mirrors the pair's `Bump` (there, run on bridge-spawned threads).
fn Bump() { total.fetch_add(1); }

// Mirrors the pair's `Run`: a second function calling members on the same
// global — the measured shape diverged per function.
fn Run() -> i32 {
  total.store(20);
  Bump();
  return total.load();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'carbon_defined_globals.carbon'
// CHECK:STDOUT: source_filename = "carbon_defined_globals.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: @_Cg.Main = global [4 x i8] zeroinitializer
// CHECK:STDOUT: @_Cm.Main = global [4 x i8] zeroinitializer
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN3BoxIiEC1Ev.carbon_thunk.(ptr noundef %return) #0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !12
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !12
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Default.9d4aa446d9154817.Core:Box.Cpp"(ptr sret([4 x i8]) %return) #1 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN3BoxIiEC1Ev.carbon_thunk.(ptr %return), !dbg !20
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN5PlainC1Ev.carbon_thunk.(ptr noundef %return) #0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !21
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !21
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Default.c2877a28d52dd366.Core:Plain.Cpp"(ptr sret([4 x i8]) %return) #1 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN5PlainC1Ev.carbon_thunk.(ptr %return), !dbg !24
// CHECK:STDOUT:   ret void, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadSpecialized.Main() #2 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14_11.2 = load i32, ptr @_Cg.Main, align 4, !dbg !29
// CHECK:STDOUT:   ret i32 %.loc14_11.2, !dbg !30
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadPlain.Main() #2 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_11.2 = load i32, ptr @_Cm.Main, align 4, !dbg !32
// CHECK:STDOUT:   ret i32 %.loc18_11.2, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #2 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6"(ptr @_Cg.Main), !dbg !37
// CHECK:STDOUT:   call void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.d0df4221f5d23f36"(ptr @_Cm.Main), !dbg !38
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6"(ptr sret([4 x i8]) %return) #2 !dbg !40 {
// CHECK:STDOUT:   call void @"_COp:thunk:Default.9d4aa446d9154817.Core:Box.Cpp"(ptr %return), !dbg !42
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.d0df4221f5d23f36"(ptr sret([4 x i8]) %return) #2 !dbg !44 {
// CHECK:STDOUT:   call void @"_COp:thunk:Default.c2877a28d52dd366.Core:Plain.Cpp"(ptr %return), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #2 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "carbon_defined_globals.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !3 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !4 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !5 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !6 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !{!8, !9, i64 0}
// CHECK:STDOUT: !8 = !{!"__libc_errno", !9, i64 0}
// CHECK:STDOUT: !9 = !{!"int", !10, i64 0}
// CHECK:STDOUT: !10 = !{!"omnipotent char", !11, i64 0}
// CHECK:STDOUT: !11 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !12 = !{!13, !13, i64 0}
// CHECK:STDOUT: !13 = !{!"p1 _ZTS3BoxIiE", !14, i64 0}
// CHECK:STDOUT: !14 = !{!"any pointer", !10, i64 0}
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Default.9d4aa446d9154817.Core:Box.Cpp", scope: null, file: !16, line: 2, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !16 = !DIFile(filename: "./box.h", directory: "")
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !20 = !DILocation(line: 2, column: 30, scope: !15)
// CHECK:STDOUT: !21 = !{!22, !22, i64 0}
// CHECK:STDOUT: !22 = !{!"p1 _ZTS5Plain", !14, i64 0}
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Default.c2877a28d52dd366.Core:Plain.Cpp", scope: null, file: !16, line: 6, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !24 = !DILocation(line: 6, column: 8, scope: !23)
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "ReadSpecialized", linkageName: "_CReadSpecialized.Main", scope: null, file: !1, line: 13, type: !26, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !26 = !DISubroutineType(types: !27)
// CHECK:STDOUT: !27 = !{!28}
// CHECK:STDOUT: !28 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !29 = !DILocation(line: 14, column: 10, scope: !25)
// CHECK:STDOUT: !30 = !DILocation(line: 14, column: 3, scope: !25)
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "ReadPlain", linkageName: "_CReadPlain.Main", scope: null, file: !1, line: 17, type: !26, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !32 = !DILocation(line: 18, column: 10, scope: !31)
// CHECK:STDOUT: !33 = !DILocation(line: 18, column: 3, scope: !31)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !35, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !35 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !36 = !{null}
// CHECK:STDOUT: !37 = !DILocation(line: 8, column: 1, scope: !34)
// CHECK:STDOUT: !38 = !DILocation(line: 11, column: 1, scope: !34)
// CHECK:STDOUT: !39 = !DILocation(line: 0, scope: !34)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51f3fb62cb986374:DefaultOrUnformed.Core.0e44c8e509b492f6", scope: null, file: !41, line: 9, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !41 = !DIFile(filename: "min_prelude/parts/default.carbon", directory: "")
// CHECK:STDOUT: !42 = !DILocation(line: 9, column: 28, scope: !40)
// CHECK:STDOUT: !43 = !DILocation(line: 9, column: 21, scope: !40)
// CHECK:STDOUT: !44 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51f3fb62cb986374:DefaultOrUnformed.Core.d0df4221f5d23f36", scope: null, file: !41, line: 9, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !45 = !DILocation(line: 9, column: 28, scope: !44)
// CHECK:STDOUT: !46 = !DILocation(line: 9, column: 21, scope: !44)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'carbon_defined_member_calls.carbon'
// CHECK:STDOUT: source_filename = "carbon_defined_member_calls.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.Counter = type { i32 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN7CounterIiE9fetch_addEi = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN7CounterIiE5storeEi = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN7CounterIiE4loadEv = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @_Ctotal.Main = global [4 x i8] zeroinitializer
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 0, ptr @_C__global_init.Main, ptr null }]
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN7CounterIiEC1Ev.carbon_thunk.(ptr noundef %return) #0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !12
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !12
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline nounwind
// CHECK:STDOUT: define weak_odr void @"_COp:thunk:Default.fdb34be5d744818f.Core:Counter.Cpp"(ptr sret([4 x i8]) %return) #1 !dbg !15 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN7CounterIiEC1Ev.carbon_thunk.(ptr %return), !dbg !20
// CHECK:STDOUT:   ret void, !dbg !20
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CBump.Main() #2 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %fetch_add__carbon_thunk.call = call i32 @_ZN7CounterIiE9fetch_addEi.carbon_thunk.r_(ptr @_Ctotal.Main, i32 1), !dbg !24
// CHECK:STDOUT:   ret void, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZN7CounterIiE9fetch_addEi.carbon_thunk.r_(ptr noundef nonnull align 4 dereferenceable(4) %this, i32 noundef %v) #0 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !12
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !26
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !12, !nonnull !27, !align !28
// CHECK:STDOUT:   %1 = load i32, ptr %v.addr, align 4, !tbaa !26
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZN7CounterIiE9fetch_addEi(ptr noundef nonnull align 4 dereferenceable(4) %0, i32 noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %3) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @main() #2 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN7CounterIiE5storeEi.carbon_thunk.r_(ptr @_Ctotal.Main, i32 20), !dbg !33
// CHECK:STDOUT:   call void @_CBump.Main(), !dbg !34
// CHECK:STDOUT:   %load__carbon_thunk.call = call i32 @_ZN7CounterIiE4loadEv.carbon_thunk.r(ptr @_Ctotal.Main), !dbg !35
// CHECK:STDOUT:   ret i32 %load__carbon_thunk.call, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN7CounterIiE5storeEi.carbon_thunk.r_(ptr noundef nonnull align 4 dereferenceable(4) %this, i32 noundef %v) #0 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !12
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !26
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !12, !nonnull !27, !align !28
// CHECK:STDOUT:   %1 = load i32, ptr %v.addr, align 4, !tbaa !26
// CHECK:STDOUT:   invoke void @_ZN7CounterIiE5storeEi(ptr noundef nonnull align 4 dereferenceable(4) %0, i32 noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %3) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZN7CounterIiE4loadEv.carbon_thunk.r(ptr noundef nonnull align 4 dereferenceable(4) %this) #0 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !12
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !12, !nonnull !27, !align !28
// CHECK:STDOUT:   %call = invoke noundef i32 @_ZN7CounterIiE4loadEv(ptr noundef nonnull align 4 dereferenceable(4) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %entry
// CHECK:STDOUT:   %1 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %1, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %2) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define internal void @_C__global_init.Main() #2 !dbg !37 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.ef78727548702947"(ptr @_Ctotal.Main), !dbg !38
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.51f3fb62cb986374:DefaultOrUnformed.Core.ef78727548702947"(ptr sret([4 x i8]) %return) #2 !dbg !40 {
// CHECK:STDOUT:   call void @"_COp:thunk:Default.fdb34be5d744818f.Core:Counter.Cpp"(ptr %return), !dbg !42
// CHECK:STDOUT:   ret void, !dbg !43
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_ZN7CounterIiE9fetch_addEi(ptr noundef nonnull align 4 dereferenceable(4) %this, i32 noundef %v) #3 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   %old = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !12
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !26
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %old) #2
// CHECK:STDOUT:   %value = getelementptr inbounds nuw %struct.Counter, ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   %0 = load i32, ptr %value, align 4, !tbaa !44
// CHECK:STDOUT:   store i32 %0, ptr %old, align 4, !tbaa !26
// CHECK:STDOUT:   %1 = load i32, ptr %v.addr, align 4, !tbaa !26
// CHECK:STDOUT:   %value2 = getelementptr inbounds nuw %struct.Counter, ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   %2 = load i32, ptr %value2, align 4, !tbaa !44
// CHECK:STDOUT:   %add = add nsw i32 %2, %1
// CHECK:STDOUT:   store i32 %add, ptr %value2, align 4, !tbaa !44
// CHECK:STDOUT:   %3 = load i32, ptr %old, align 4, !tbaa !26
// CHECK:STDOUT:   call void @llvm.lifetime.end.p0(ptr %old) #2
// CHECK:STDOUT:   ret i32 %3
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #4 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #2
// CHECK:STDOUT:   call void @_ZSt9terminatev() #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #5
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.end.p0(ptr captures(none)) #5
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local void @_ZN7CounterIiE5storeEi(ptr noundef nonnull align 4 dereferenceable(4) %this, i32 noundef %v) #3 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !12
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !26
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %0 = load i32, ptr %v.addr, align 4, !tbaa !26
// CHECK:STDOUT:   %value = getelementptr inbounds nuw %struct.Counter, ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   store i32 %0, ptr %value, align 4, !tbaa !44
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: mustprogress nounwind uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_ZN7CounterIiE4loadEv(ptr noundef nonnull align 4 dereferenceable(4) %this) #3 comdat align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !12
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   %value = getelementptr inbounds nuw %struct.Counter, ptr %this1, i32 0, i32 0
// CHECK:STDOUT:   %0 = load i32, ptr %value, align 4, !tbaa !44
// CHECK:STDOUT:   ret i32 %0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { alwaysinline nounwind }
// CHECK:STDOUT: attributes #2 = { nounwind }
// CHECK:STDOUT: attributes #3 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "carbon_defined_member_calls.carbon", directory: "")
// CHECK:STDOUT: !2 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !3 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !4 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !5 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !6 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !{!8, !9, i64 0}
// CHECK:STDOUT: !8 = !{!"__libc_errno", !9, i64 0}
// CHECK:STDOUT: !9 = !{!"int", !10, i64 0}
// CHECK:STDOUT: !10 = !{!"omnipotent char", !11, i64 0}
// CHECK:STDOUT: !11 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !12 = !{!13, !13, i64 0}
// CHECK:STDOUT: !13 = !{!"p1 _ZTS7CounterIiE", !14, i64 0}
// CHECK:STDOUT: !14 = !{!"any pointer", !10, i64 0}
// CHECK:STDOUT: !15 = distinct !DISubprogram(name: "Op", linkageName: "_COp:thunk:Default.fdb34be5d744818f.Core:Counter.Cpp", scope: null, file: !16, line: 2, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !16 = !DIFile(filename: "./counter.h", directory: "")
// CHECK:STDOUT: !17 = !DISubroutineType(types: !18)
// CHECK:STDOUT: !18 = !{!19}
// CHECK:STDOUT: !19 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !20 = !DILocation(line: 2, column: 30, scope: !15)
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "Bump", linkageName: "_CBump.Main", scope: null, file: !1, line: 20, type: !22, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !22 = !DISubroutineType(types: !23)
// CHECK:STDOUT: !23 = !{null}
// CHECK:STDOUT: !24 = !DILocation(line: 20, column: 13, scope: !21)
// CHECK:STDOUT: !25 = !DILocation(line: 20, column: 1, scope: !21)
// CHECK:STDOUT: !26 = !{!9, !9, i64 0}
// CHECK:STDOUT: !27 = !{}
// CHECK:STDOUT: !28 = !{i64 4}
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "Run", linkageName: "main", scope: null, file: !1, line: 24, type: !30, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !30 = !DISubroutineType(types: !31)
// CHECK:STDOUT: !31 = !{!32}
// CHECK:STDOUT: !32 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !33 = !DILocation(line: 25, column: 3, scope: !29)
// CHECK:STDOUT: !34 = !DILocation(line: 26, column: 3, scope: !29)
// CHECK:STDOUT: !35 = !DILocation(line: 27, column: 10, scope: !29)
// CHECK:STDOUT: !36 = !DILocation(line: 27, column: 3, scope: !29)
// CHECK:STDOUT: !37 = distinct !DISubprogram(name: "__global_init", linkageName: "_C__global_init.Main", scope: null, file: !1, type: !22, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !38 = !DILocation(line: 17, column: 1, scope: !37)
// CHECK:STDOUT: !39 = !DILocation(line: 0, scope: !37)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Op", linkageName: "_COp.51f3fb62cb986374:DefaultOrUnformed.Core.ef78727548702947", scope: null, file: !41, line: 9, type: !17, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !41 = !DIFile(filename: "min_prelude/parts/default.carbon", directory: "")
// CHECK:STDOUT: !42 = !DILocation(line: 9, column: 28, scope: !40)
// CHECK:STDOUT: !43 = !DILocation(line: 9, column: 21, scope: !40)
// CHECK:STDOUT: !44 = !{!45, !9, i64 0}
// CHECK:STDOUT: !45 = !{!"_ZTS7CounterIiE", !9, i64 0}
// CHECK:STDOUT:
