// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/function/export/overload_set.carbon

// Every exported member of a Carbon `overload fn` set is its own C++
// declaration behind its own pair of symbols (fork decision F-009;
// fork/overload/plan.md OV-3, D-OV-5, D-OV-9): the member itself
// (`_CF:overload<N>.Main`) and its per-member Carbon thunk
// (`_CF__carbon_thunk:overload<N>.Main` — the thunk carries the member's
// index, so the mangler keys it as it keys the member — the asm label of the
// C++ declaration the inline C++ `F` calls). The C++ side resolves under C++
// rules and the Carbon side by declaration-order first-match, so a golden
// can show the two sides calling different members of one set.

// --- overload_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

overload fn F(unused x: i64) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

inline Cpp '''
inline int CallBool() { return Carbon::F(true); }
inline int CallWithLong() { return Carbon::F(7L); }
''';

fn Use() -> i32 { return F(7) + F(true) + Cpp.CallBool() + Cpp.CallWithLong(); }

// --- divergence.carbon

library "[[@TEST_NAME]]";

import Cpp;

// Carbon's `Pick(n)` calls member 0 (`i32` widens to `i64`); C++'s
// `Carbon::Pick(v)` calls member 1 (`int` is an exact match).
overload fn Pick(unused x: i64) -> i32 { return 1; }
overload fn Pick(unused x: i32) -> i32 { return 2; }

inline Cpp '''
inline int FromCpp(int v) { return Carbon::Pick(v); }
''';

fn Use(n: i32) -> i32 { return Pick(n) + Cpp.FromCpp(n); }

// --- method_set.carbon

library "[[@TEST_NAME]]";

import Cpp;

// Members in class scope: each `ref self` member is its own lvalue-ref-
// qualified C++ member function of the exported `Acc`, behind its own
// `_CAdd:overload<N>.Acc.Main` and `_CAdd__carbon_thunk:overload<N>.Acc.Main`
// pair; `a.Add(1)` and `a.Add(true)` call different members.
class Acc {
  var total: i32;
  fn Make() -> Acc { return {.total = 0}; }
  overload fn Add(ref self, x: i32) { self.total = self.total + x; }
  overload fn Add(ref self, flag: bool) {
    if (flag) { self.total = self.total + 100; }
  }
  fn Get(self) -> i32 { return self.total; }
}

inline Cpp '''
inline int Drive() {
  auto a = Carbon::Acc::Make();
  a.Add(1);
  a.Add(true);
  return a.Get();
}
''';

fn Use() -> i32 { return Cpp.Drive(); }

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'overload_set.carbon'
// CHECK:STDOUT: source_filename = "overload_set.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z8CallBoolv = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z12CallWithLongv = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [75 x i8] c"carbon: C++ exception escaped into Carbon through `CallBool`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [79 x i8] c"carbon: C++ exception escaped into Carbon through `CallWithLong`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i64 %x) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(i1 %b) #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !26
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CF__carbon_thunk:overload0.Main"(ptr %_, ptr %_1) #0 !dbg !27 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6 = load i64, ptr %_, align 8, !dbg !33
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload0.Main"(i64 %.loc6), !dbg !33
// CHECK:STDOUT:   store i32 %F.call, ptr %_1, align 4, !dbg !33
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CF__carbon_thunk:overload1.Main"(ptr %_, ptr %_1) #0 !dbg !34 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7 = load i8, ptr %_, align 1, !dbg !40
// CHECK:STDOUT:   %.loc72 = trunc i8 %.loc7 to i1, !dbg !40
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload1.Main"(i1 %.loc72), !dbg !40
// CHECK:STDOUT:   store i32 %F.call, ptr %_1, align 4, !dbg !40
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %F.call.loc14_29 = call i32 @"_CF:overload0.Main"(i64 7), !dbg !44
// CHECK:STDOUT:   %F.call.loc14_39 = call i32 @"_CF:overload1.Main"(i1 true), !dbg !45
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc14_31 = add i32 %F.call.loc14_29, %F.call.loc14_39, !dbg !44
// CHECK:STDOUT:   %CallBool__carbon_thunk.call = call i32 @_Z8CallBoolv.carbon_thunk.(), !dbg !46
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc14_41 = add i32 %Int.as.AddWith.impl.Op.call.loc14_31, %CallBool__carbon_thunk.call, !dbg !44
// CHECK:STDOUT:   %CallWithLong__carbon_thunk.call = call i32 @_Z12CallWithLongv.carbon_thunk.(), !dbg !47
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc14_58 = add i32 %Int.as.AddWith.impl.Op.call.loc14_41, %CallWithLong__carbon_thunk.call, !dbg !44
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call.loc14_58, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z8CallBoolv.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z8CallBoolv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %0 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %1 = extractvalue { ptr, i32 } %0, 0
// CHECK:STDOUT:   store ptr %1, ptr %exn.slot, align 8
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %0, 1
// CHECK:STDOUT:   store i32 %2, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 74) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %5) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z12CallWithLongv.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z12CallWithLongv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %0 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %1 = extractvalue { ptr, i32 } %0, 0
// CHECK:STDOUT:   store ptr %1, ptr %exn.slot, align 8
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %0, 1
// CHECK:STDOUT:   store i32 %2, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 78) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %5) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z8CallBoolv() #2 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %call = call noundef i32 @_ZN6CarbonL1FEb(i1 noundef zeroext true)
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #4 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZN6CarbonL1FEb(i1 noundef zeroext %0) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %.addr = alloca i8, align 1
// CHECK:STDOUT:   %storedv = zext i1 %0 to i8
// CHECK:STDOUT:   store i8 %storedv, ptr %.addr, align 1, !tbaa !49
// CHECK:STDOUT:   call void @"_CF__carbon_thunk:overload1.Main"(ptr noundef nonnull align 1 dereferenceable(1) %.addr, ptr noundef nonnull align 4 dereferenceable(4) %retval)
// CHECK:STDOUT:   %1 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z12CallWithLongv() #2 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %call = call noundef i32 @_ZN6CarbonL1FEl(i64 noundef 7)
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZN6CarbonL1FEl(i64 noundef %0) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %.addr = alloca i64, align 8
// CHECK:STDOUT:   store i64 %0, ptr %.addr, align 8, !tbaa !51
// CHECK:STDOUT:   call void @"_CF__carbon_thunk:overload0.Main"(ptr noundef nonnull align 8 dereferenceable(8) %.addr, ptr noundef nonnull align 4 dereferenceable(4) %retval)
// CHECK:STDOUT:   %1 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { inlinehint mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "overload_set.carbon", directory: "")
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
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !1, line: 6, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !17)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!15, !16}
// CHECK:STDOUT: !15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !16 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !17 = !{!18}
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !12, type: !16)
// CHECK:STDOUT: !19 = !DILocation(line: 6, column: 39, scope: !12)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !1, line: 7, type: !21, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !24)
// CHECK:STDOUT: !21 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !22 = !{!15, !23}
// CHECK:STDOUT: !23 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !24 = !{!25}
// CHECK:STDOUT: !25 = !DILocalVariable(arg: 1, scope: !20, type: !23)
// CHECK:STDOUT: !26 = !DILocation(line: 7, column: 40, scope: !20)
// CHECK:STDOUT: !27 = distinct !DISubprogram(name: "F__carbon_thunk", linkageName: "_CF__carbon_thunk:overload0.Main", scope: null, file: !1, line: 6, type: !28, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !30)
// CHECK:STDOUT: !28 = !DISubroutineType(types: !29)
// CHECK:STDOUT: !29 = !{null, !16, !15}
// CHECK:STDOUT: !30 = !{!31, !32}
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !27, type: !16)
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 2, scope: !27, type: !15)
// CHECK:STDOUT: !33 = !DILocation(line: 6, column: 1, scope: !27)
// CHECK:STDOUT: !34 = distinct !DISubprogram(name: "F__carbon_thunk", linkageName: "_CF__carbon_thunk:overload1.Main", scope: null, file: !1, line: 7, type: !35, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !37)
// CHECK:STDOUT: !35 = !DISubroutineType(types: !36)
// CHECK:STDOUT: !36 = !{null, !23, !15}
// CHECK:STDOUT: !37 = !{!38, !39}
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 1, scope: !34, type: !23)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 2, scope: !34, type: !15)
// CHECK:STDOUT: !40 = !DILocation(line: 7, column: 1, scope: !34)
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 14, type: !42, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !42 = !DISubroutineType(types: !43)
// CHECK:STDOUT: !43 = !{!15}
// CHECK:STDOUT: !44 = !DILocation(line: 14, column: 26, scope: !41)
// CHECK:STDOUT: !45 = !DILocation(line: 14, column: 33, scope: !41)
// CHECK:STDOUT: !46 = !DILocation(line: 14, column: 43, scope: !41)
// CHECK:STDOUT: !47 = !DILocation(line: 14, column: 60, scope: !41)
// CHECK:STDOUT: !48 = !DILocation(line: 14, column: 19, scope: !41)
// CHECK:STDOUT: !49 = !{!50, !50, i64 0}
// CHECK:STDOUT: !50 = !{!"bool", !10, i64 0}
// CHECK:STDOUT: !51 = !{!52, !52, i64 0}
// CHECK:STDOUT: !52 = !{!"long", !10, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'divergence.carbon'
// CHECK:STDOUT: source_filename = "divergence.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z7FromCppi = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [74 x i8] c"carbon: C++ exception escaped into Carbon through `FromCpp`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CPick:overload0.Main"(i64 %x) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CPick:overload1.Main"(i32 %x) #0 !dbg !20 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !25
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CPick__carbon_thunk:overload0.Main"(ptr %_, ptr %_1) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8 = load i64, ptr %_, align 8, !dbg !32
// CHECK:STDOUT:   %Pick.call = call i32 @"_CPick:overload0.Main"(i64 %.loc8), !dbg !32
// CHECK:STDOUT:   store i32 %Pick.call, ptr %_1, align 4, !dbg !32
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CPick__carbon_thunk:overload1.Main"(ptr %_, ptr %_1) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9 = load i32, ptr %_, align 4, !dbg !39
// CHECK:STDOUT:   %Pick.call = call i32 @"_CPick:overload1.Main"(i32 %.loc9), !dbg !39
// CHECK:STDOUT:   store i32 %Pick.call, ptr %_1, align 4, !dbg !39
// CHECK:STDOUT:   ret void, !dbg !39
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(i32 %n) #0 !dbg !40 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call = call i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %n), !dbg !43
// CHECK:STDOUT:   %Pick.call = call i32 @"_CPick:overload0.Main"(i64 %From.as_type.as.ImplicitAs.impl.Convert.call), !dbg !44
// CHECK:STDOUT:   %FromCpp__carbon_thunk.call = call i32 @_Z7FromCppi.carbon_thunk._(i32 %n), !dbg !45
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Pick.call, %FromCpp__carbon_thunk.call, !dbg !44
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !46
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z7FromCppi.carbon_thunk._(i32 noundef %v) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !47
// CHECK:STDOUT:   %0 = load i32, ptr %v.addr, align 4, !tbaa !47
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z7FromCppi(i32 noundef %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %1 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %1, 0
// CHECK:STDOUT:   store ptr %2, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %1, 1
// CHECK:STDOUT:   store i32 %3, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 73) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %self) #0 !dbg !48 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !54
// CHECK:STDOUT:   %2 = sext i32 %1 to i64, !dbg !55
// CHECK:STDOUT:   ret i64 %2, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !57 {
// CHECK:STDOUT:   ret i32 %self, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z7FromCppi(i32 noundef %v) #2 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !47
// CHECK:STDOUT:   %0 = load i32, ptr %v.addr, align 4, !tbaa !47
// CHECK:STDOUT:   %call = call noundef i32 @_ZN6CarbonL4PickEi(i32 noundef %0)
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #4 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZN6CarbonL4PickEi(i32 noundef %0) #1 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %.addr = alloca i32, align 4
// CHECK:STDOUT:   store i32 %0, ptr %.addr, align 4, !tbaa !47
// CHECK:STDOUT:   call void @"_CPick__carbon_thunk:overload1.Main"(ptr noundef nonnull align 4 dereferenceable(4) %.addr, ptr noundef nonnull align 4 dereferenceable(4) %retval)
// CHECK:STDOUT:   %1 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { inlinehint mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "divergence.carbon", directory: "")
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
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload0.Main", scope: null, file: !1, line: 8, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !17)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!15, !16}
// CHECK:STDOUT: !15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !16 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !17 = !{!18}
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !12, type: !16)
// CHECK:STDOUT: !19 = !DILocation(line: 8, column: 42, scope: !12)
// CHECK:STDOUT: !20 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload1.Main", scope: null, file: !1, line: 9, type: !21, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
// CHECK:STDOUT: !21 = !DISubroutineType(types: !22)
// CHECK:STDOUT: !22 = !{!15, !15}
// CHECK:STDOUT: !23 = !{!24}
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !20, type: !15)
// CHECK:STDOUT: !25 = !DILocation(line: 9, column: 42, scope: !20)
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "Pick__carbon_thunk", linkageName: "_CPick__carbon_thunk:overload0.Main", scope: null, file: !1, line: 8, type: !27, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !29)
// CHECK:STDOUT: !27 = !DISubroutineType(types: !28)
// CHECK:STDOUT: !28 = !{null, !16, !15}
// CHECK:STDOUT: !29 = !{!30, !31}
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 1, scope: !26, type: !16)
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 2, scope: !26, type: !15)
// CHECK:STDOUT: !32 = !DILocation(line: 8, column: 1, scope: !26)
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "Pick__carbon_thunk", linkageName: "_CPick__carbon_thunk:overload1.Main", scope: null, file: !1, line: 9, type: !34, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !36)
// CHECK:STDOUT: !34 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !35 = !{null, !15, !15}
// CHECK:STDOUT: !36 = !{!37, !38}
// CHECK:STDOUT: !37 = !DILocalVariable(arg: 1, scope: !33, type: !15)
// CHECK:STDOUT: !38 = !DILocalVariable(arg: 2, scope: !33, type: !15)
// CHECK:STDOUT: !39 = !DILocation(line: 9, column: 1, scope: !33)
// CHECK:STDOUT: !40 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 15, type: !21, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !41)
// CHECK:STDOUT: !41 = !{!42}
// CHECK:STDOUT: !42 = !DILocalVariable(arg: 1, scope: !40, type: !15)
// CHECK:STDOUT: !43 = !DILocation(line: 15, column: 37, scope: !40)
// CHECK:STDOUT: !44 = !DILocation(line: 15, column: 32, scope: !40)
// CHECK:STDOUT: !45 = !DILocation(line: 15, column: 42, scope: !40)
// CHECK:STDOUT: !46 = !DILocation(line: 15, column: 25, scope: !40)
// CHECK:STDOUT: !47 = !{!9, !9, i64 0}
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe", scope: null, file: !49, line: 64, type: !50, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !52)
// CHECK:STDOUT: !49 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !50 = !DISubroutineType(types: !51)
// CHECK:STDOUT: !51 = !{!16, !15}
// CHECK:STDOUT: !52 = !{!53}
// CHECK:STDOUT: !53 = !DILocalVariable(arg: 1, scope: !48, type: !15)
// CHECK:STDOUT: !54 = !DILocation(line: 66, column: 17, scope: !48)
// CHECK:STDOUT: !55 = !DILocation(line: 66, column: 12, scope: !48)
// CHECK:STDOUT: !56 = !DILocation(line: 66, column: 5, scope: !48)
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !49, line: 59, type: !21, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !58)
// CHECK:STDOUT: !58 = !{!59}
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !57, type: !15)
// CHECK:STDOUT: !60 = !DILocation(line: 59, column: 28, scope: !57)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'method_set.carbon'
// CHECK:STDOUT: source_filename = "method_set.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %"class.Carbon::Acc" = type { i32 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z5Drivev = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @Acc.val.loc12_41 = internal constant { i32 } zeroinitializer
// CHECK:STDOUT: @.str = private unnamed_addr constant [72 x i8] c"carbon: C++ exception escaped into Carbon through `Drive`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMake.Acc.Main(ptr sret({ i32 }) %return) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12_40.3.total = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !16
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Acc.val.loc12_41, i64 4, i1 false), !dbg !17
// CHECK:STDOUT:   ret void, !dbg !17
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd:overload0.Acc.Main"(ptr %self, i32 %x) #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13_43.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !25
// CHECK:STDOUT:   %.loc13_56.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !26
// CHECK:STDOUT:   %.loc13_56.2 = load i32, ptr %.loc13_56.1.total, align 4, !dbg !26
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc13_56.2, %x, !dbg !26
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc13_43.total, align 4, !dbg !25
// CHECK:STDOUT:   ret void, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd:overload1.Acc.Main"(ptr %self, i1 %flag) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %flag, label %if.then, label %if.else, !dbg !34
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc15_21.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !35
// CHECK:STDOUT:   %.loc15_34.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !36
// CHECK:STDOUT:   %.loc15_34.2 = load i32, ptr %.loc15_34.1.total, align 4, !dbg !36
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc15_34.2, 100, !dbg !36
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc15_21.total, align 4, !dbg !35
// CHECK:STDOUT:   br label %if.else, !dbg !37
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   ret void, !dbg !38
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.Acc.Main(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_36.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !44
// CHECK:STDOUT:   %.loc17_36.2 = load i32, ptr %.loc17_36.1.total, align 4, !dbg !44
// CHECK:STDOUT:   ret i32 %.loc17_36.2, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMake__carbon_thunk.Acc.Main(ptr %_) #0 !dbg !46 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMake.Acc.Main(ptr %_), !dbg !51
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd__carbon_thunk:overload0.Acc.Main"(ptr %self, ptr %_) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13 = load i32, ptr %_, align 4, !dbg !56
// CHECK:STDOUT:   call void @"_CAdd:overload0.Acc.Main"(ptr %self, i32 %.loc13), !dbg !56
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd__carbon_thunk:overload1.Acc.Main"(ptr %self, ptr %_) #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14 = load i8, ptr %_, align 1, !dbg !61
// CHECK:STDOUT:   %.loc141 = trunc i8 %.loc14 to i1, !dbg !61
// CHECK:STDOUT:   call void @"_CAdd:overload1.Acc.Main"(ptr %self, i1 %.loc141), !dbg !61
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CGet__carbon_thunk.Acc.Main(ptr %self, ptr %_) #0 !dbg !62 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Acc.Get.call = call i32 @_CGet.Acc.Main(ptr %self), !dbg !66
// CHECK:STDOUT:   store i32 %Acc.Get.call, ptr %_, align 4, !dbg !66
// CHECK:STDOUT:   ret void, !dbg !66
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Drive__carbon_thunk.call = call i32 @_Z5Drivev.carbon_thunk.(), !dbg !70
// CHECK:STDOUT:   ret i32 %Drive__carbon_thunk.call, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z5Drivev.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef i32 @_Z5Drivev()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret i32 %call
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %0 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %1 = extractvalue { ptr, i32 } %0, 0
// CHECK:STDOUT:   store ptr %1, ptr %exn.slot, align 8
// CHECK:STDOUT:   %2 = extractvalue { ptr, i32 } %0, 1
// CHECK:STDOUT:   store i32 %2, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %3 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 71) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; No predecessors!
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %4 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %4, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %5) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z5Drivev() #3 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %a = alloca %"class.Carbon::Acc", align 4
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %a) #0
// CHECK:STDOUT:   %call = call i32 @_ZN6Carbon3Acc4MakeEv()
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %"class.Carbon::Acc", ptr %a, i32 0, i32 0
// CHECK:STDOUT:   store i32 %call, ptr %coerce.dive, align 4
// CHECK:STDOUT:   call void @_ZNR6Carbon3Acc3AddEi(ptr noundef nonnull align 4 dereferenceable(4) %a, i32 noundef 1)
// CHECK:STDOUT:   call void @_ZNR6Carbon3Acc3AddEb(ptr noundef nonnull align 4 dereferenceable(4) %a, i1 noundef zeroext true)
// CHECK:STDOUT:   %call1 = call noundef i32 @_ZNK6Carbon3Acc3GetEv(ptr noundef nonnull align 4 dereferenceable(4) %a)
// CHECK:STDOUT:   call void @llvm.lifetime.end.p0(ptr %a) #0
// CHECK:STDOUT:   ret i32 %call1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal i32 @_ZN6Carbon3Acc4MakeEv() #1 align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca %"class.Carbon::Acc", align 4
// CHECK:STDOUT:   call void @_CMake__carbon_thunk.Acc.Main(ptr noundef nonnull align 4 dereferenceable(4) %retval)
// CHECK:STDOUT:   %coerce.dive = getelementptr inbounds nuw %"class.Carbon::Acc", ptr %retval, i32 0, i32 0
// CHECK:STDOUT:   %0 = load i32, ptr %coerce.dive, align 4
// CHECK:STDOUT:   ret i32 %0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZNR6Carbon3Acc3AddEi(ptr noundef nonnull align 4 dereferenceable(4) %this, i32 noundef %0) #1 align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %.addr = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !72
// CHECK:STDOUT:   store i32 %0, ptr %.addr, align 4, !tbaa !75
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   call void @"_CAdd__carbon_thunk:overload0.Acc.Main"(ptr noundef nonnull align 4 dereferenceable(4) %this1, ptr noundef nonnull align 4 dereferenceable(4) %.addr)
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZNR6Carbon3Acc3AddEb(ptr noundef nonnull align 4 dereferenceable(4) %this, i1 noundef zeroext %0) #1 align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %.addr = alloca i8, align 1
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !72
// CHECK:STDOUT:   %storedv = zext i1 %0 to i8
// CHECK:STDOUT:   store i8 %storedv, ptr %.addr, align 1, !tbaa !76
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   call void @"_CAdd__carbon_thunk:overload1.Acc.Main"(ptr noundef nonnull align 4 dereferenceable(4) %this1, ptr noundef nonnull align 1 dereferenceable(1) %.addr)
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_ZNK6Carbon3Acc3GetEv(ptr noundef nonnull align 4 dereferenceable(4) %this) #1 align 2 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %retval = alloca i32, align 4
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !72
// CHECK:STDOUT:   %this1 = load ptr, ptr %this.addr, align 8
// CHECK:STDOUT:   call void @_CGet__carbon_thunk.Acc.Main(ptr noundef nonnull align 4 dereferenceable(4) %this1, ptr noundef nonnull align 4 dereferenceable(4) %retval)
// CHECK:STDOUT:   %0 = load i32, ptr %retval, align 4
// CHECK:STDOUT:   ret i32 %0
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.end.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { inlinehint mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!0}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3, !4, !5, !6}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!7}
// CHECK:STDOUT:
// CHECK:STDOUT: !0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !1, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !1 = !DIFile(filename: "method_set.carbon", directory: "")
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
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Acc.Main", scope: null, file: !1, line: 12, type: !13, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{!15}
// CHECK:STDOUT: !15 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !16 = !DILocation(line: 12, column: 29, scope: !12)
// CHECK:STDOUT: !17 = !DILocation(line: 12, column: 22, scope: !12)
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload0.Acc.Main", scope: null, file: !1, line: 13, type: !19, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !22)
// CHECK:STDOUT: !19 = !DISubroutineType(types: !20)
// CHECK:STDOUT: !20 = !{null, !15, !21}
// CHECK:STDOUT: !21 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !22 = !{!23, !24}
// CHECK:STDOUT: !23 = !DILocalVariable(arg: 1, scope: !18, type: !15)
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 2, scope: !18, type: !21)
// CHECK:STDOUT: !25 = !DILocation(line: 13, column: 39, scope: !18)
// CHECK:STDOUT: !26 = !DILocation(line: 13, column: 52, scope: !18)
// CHECK:STDOUT: !27 = !DILocation(line: 13, column: 3, scope: !18)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload1.Acc.Main", scope: null, file: !1, line: 14, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !31)
// CHECK:STDOUT: !29 = !DISubroutineType(types: !30)
// CHECK:STDOUT: !30 = !{null, !15, !15}
// CHECK:STDOUT: !31 = !{!32, !33}
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !28, type: !15)
// CHECK:STDOUT: !33 = !DILocalVariable(arg: 2, scope: !28, type: !15)
// CHECK:STDOUT: !34 = !DILocation(line: 15, column: 8, scope: !28)
// CHECK:STDOUT: !35 = !DILocation(line: 15, column: 17, scope: !28)
// CHECK:STDOUT: !36 = !DILocation(line: 15, column: 30, scope: !28)
// CHECK:STDOUT: !37 = !DILocation(line: 15, column: 5, scope: !28)
// CHECK:STDOUT: !38 = !DILocation(line: 14, column: 3, scope: !28)
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Acc.Main", scope: null, file: !1, line: 17, type: !40, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DISubroutineType(types: !41)
// CHECK:STDOUT: !41 = !{!21, !15}
// CHECK:STDOUT: !42 = !{!43}
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !39, type: !15)
// CHECK:STDOUT: !44 = !DILocation(line: 17, column: 32, scope: !39)
// CHECK:STDOUT: !45 = !DILocation(line: 17, column: 25, scope: !39)
// CHECK:STDOUT: !46 = distinct !DISubprogram(name: "Make__carbon_thunk", linkageName: "_CMake__carbon_thunk.Acc.Main", scope: null, file: !1, line: 12, type: !47, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !49)
// CHECK:STDOUT: !47 = !DISubroutineType(types: !48)
// CHECK:STDOUT: !48 = !{null, !15}
// CHECK:STDOUT: !49 = !{!50}
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !46, type: !15)
// CHECK:STDOUT: !51 = !DILocation(line: 12, column: 3, scope: !46)
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "Add__carbon_thunk", linkageName: "_CAdd__carbon_thunk:overload0.Acc.Main", scope: null, file: !1, line: 13, type: !19, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !53 = !{!54, !55}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !52, type: !15)
// CHECK:STDOUT: !55 = !DILocalVariable(arg: 2, scope: !52, type: !21)
// CHECK:STDOUT: !56 = !DILocation(line: 13, column: 3, scope: !52)
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "Add__carbon_thunk", linkageName: "_CAdd__carbon_thunk:overload1.Acc.Main", scope: null, file: !1, line: 14, type: !29, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !58)
// CHECK:STDOUT: !58 = !{!59, !60}
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !57, type: !15)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 2, scope: !57, type: !15)
// CHECK:STDOUT: !61 = !DILocation(line: 14, column: 3, scope: !57)
// CHECK:STDOUT: !62 = distinct !DISubprogram(name: "Get__carbon_thunk", linkageName: "_CGet__carbon_thunk.Acc.Main", scope: null, file: !1, line: 17, type: !19, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !63)
// CHECK:STDOUT: !63 = !{!64, !65}
// CHECK:STDOUT: !64 = !DILocalVariable(arg: 1, scope: !62, type: !15)
// CHECK:STDOUT: !65 = !DILocalVariable(arg: 2, scope: !62, type: !21)
// CHECK:STDOUT: !66 = !DILocation(line: 17, column: 3, scope: !62)
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !1, line: 29, type: !68, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !68 = !DISubroutineType(types: !69)
// CHECK:STDOUT: !69 = !{!21}
// CHECK:STDOUT: !70 = !DILocation(line: 29, column: 26, scope: !67)
// CHECK:STDOUT: !71 = !DILocation(line: 29, column: 19, scope: !67)
// CHECK:STDOUT: !72 = !{!73, !73, i64 0}
// CHECK:STDOUT: !73 = !{!"p1 _ZTSN6Carbon3AccE", !74, i64 0}
// CHECK:STDOUT: !74 = !{!"any pointer", !10, i64 0}
// CHECK:STDOUT: !75 = !{!9, !9, i64 0}
// CHECK:STDOUT: !76 = !{!77, !77, i64 0}
// CHECK:STDOUT: !77 = !{!"bool", !10, i64 0}
// CHECK:STDOUT:
