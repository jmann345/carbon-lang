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
// CHECK:STDOUT: define i32 @"_CF:overload0.Main"(i64 %x) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !24
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CF:overload1.Main"(i1 %b) #0 !dbg !26 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CF__carbon_thunk:overload0.Main"(ptr %_, ptr %_1) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc6 = load i64, ptr %_, align 8, !dbg !36
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload0.Main"(i64 %.loc6), !dbg !36
// CHECK:STDOUT:   store i32 %F.call, ptr %_1, align 4, !dbg !36
// CHECK:STDOUT:   ret void, !dbg !36
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CF__carbon_thunk:overload1.Main"(ptr %_, ptr %_1) #0 !dbg !38 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7 = load i8, ptr %_, align 1, !dbg !41
// CHECK:STDOUT:   %.loc72 = trunc i8 %.loc7 to i1, !dbg !41
// CHECK:STDOUT:   %F.call = call i32 @"_CF:overload1.Main"(i1 %.loc72), !dbg !41
// CHECK:STDOUT:   store i32 %F.call, ptr %_1, align 4, !dbg !41
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %F.call.loc14_29 = call i32 @"_CF:overload0.Main"(i64 7), !dbg !46
// CHECK:STDOUT:   %F.call.loc14_39 = call i32 @"_CF:overload1.Main"(i1 true), !dbg !47
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc14_31 = add i32 %F.call.loc14_29, %F.call.loc14_39, !dbg !46
// CHECK:STDOUT:   %CallBool__carbon_thunk.call = call i32 @_Z8CallBoolv.carbon_thunk.(), !dbg !48
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc14_41 = add i32 %Int.as.AddWith.impl.Op.call.loc14_31, %CallBool__carbon_thunk.call, !dbg !46
// CHECK:STDOUT:   %CallWithLong__carbon_thunk.call = call i32 @_Z12CallWithLongv.carbon_thunk.(), !dbg !49
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc14_58 = add i32 %Int.as.AddWith.impl.Op.call.loc14_41, %CallWithLong__carbon_thunk.call, !dbg !46
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call.loc14_58, !dbg !50
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
// CHECK:STDOUT:   store i8 %storedv, ptr %.addr, align 1, !tbaa !54
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
// CHECK:STDOUT:   store i64 %0, ptr %.addr, align 8, !tbaa !57
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!58, !59, !60, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!62}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "overload_set.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!7, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !11 = !{!7, !10}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !6, !7}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{null, !10, !7}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = !{!7}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload0.Main", scope: null, file: !4, line: 6, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !25)
// CHECK:STDOUT: !20 = !DILocalVariable(arg: 1, scope: !19, type: !6)
// CHECK:STDOUT: !24 = !DILocation(line: 6, column: 39, scope: !19)
// CHECK:STDOUT: !25 = !{!20}
// CHECK:STDOUT: !26 = distinct !DISubprogram(name: "F", linkageName: "_CF:overload1.Main", scope: null, file: !4, line: 7, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !32)
// CHECK:STDOUT: !27 = !DILocalVariable(arg: 1, scope: !26, type: !10)
// CHECK:STDOUT: !31 = !DILocation(line: 7, column: 40, scope: !26)
// CHECK:STDOUT: !32 = !{!27}
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "F__carbon_thunk", linkageName: "_CF__carbon_thunk:overload0.Main", scope: null, file: !4, line: 6, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !37)
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !33, type: !6)
// CHECK:STDOUT: !35 = !DILocalVariable(arg: 2, scope: !33, type: !7)
// CHECK:STDOUT: !36 = !DILocation(line: 6, column: 1, scope: !33)
// CHECK:STDOUT: !37 = !{!34, !35}
// CHECK:STDOUT: !38 = distinct !DISubprogram(name: "F__carbon_thunk", linkageName: "_CF__carbon_thunk:overload1.Main", scope: null, file: !4, line: 7, type: !16, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !39 = !DILocalVariable(arg: 1, scope: !38, type: !10)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 2, scope: !38, type: !7)
// CHECK:STDOUT: !41 = !DILocation(line: 7, column: 1, scope: !38)
// CHECK:STDOUT: !42 = !{!39, !40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !4, line: 14, type: !18, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !46 = !DILocation(line: 14, column: 26, scope: !43)
// CHECK:STDOUT: !47 = !DILocation(line: 14, column: 33, scope: !43)
// CHECK:STDOUT: !48 = !DILocation(line: 14, column: 43, scope: !43)
// CHECK:STDOUT: !49 = !DILocation(line: 14, column: 60, scope: !43)
// CHECK:STDOUT: !50 = !DILocation(line: 14, column: 19, scope: !43)
// CHECK:STDOUT: !51 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !52 = !{!"omnipotent char", !51, i64 0}
// CHECK:STDOUT: !53 = !{!"bool", !52, i64 0}
// CHECK:STDOUT: !54 = !{!53, !53, i64 0}
// CHECK:STDOUT: !55 = !{!"int", !52, i64 0}
// CHECK:STDOUT: !56 = !{!"long", !52, i64 0}
// CHECK:STDOUT: !57 = !{!56, !56, i64 0}
// CHECK:STDOUT: !58 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !59 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !60 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !61 = !{!"__libc_errno", !55, i64 0}
// CHECK:STDOUT: !62 = !{!61, !55, i64 0}
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
// CHECK:STDOUT: define i32 @"_CPick:overload0.Main"(i64 %x) #0 !dbg !69 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 1, !dbg !74
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @"_CPick:overload1.Main"(i32 %x) #0 !dbg !76 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret i32 2, !dbg !81
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CPick__carbon_thunk:overload0.Main"(ptr %_, ptr %_1) #0 !dbg !83 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc8 = load i64, ptr %_, align 8, !dbg !86
// CHECK:STDOUT:   %Pick.call = call i32 @"_CPick:overload0.Main"(i64 %.loc8), !dbg !86
// CHECK:STDOUT:   store i32 %Pick.call, ptr %_1, align 4, !dbg !86
// CHECK:STDOUT:   ret void, !dbg !86
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CPick__carbon_thunk:overload1.Main"(ptr %_, ptr %_1) #0 !dbg !88 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc9 = load i32, ptr %_, align 4, !dbg !91
// CHECK:STDOUT:   %Pick.call = call i32 @"_CPick:overload1.Main"(i32 %.loc9), !dbg !91
// CHECK:STDOUT:   store i32 %Pick.call, ptr %_1, align 4, !dbg !91
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main(i32 %n) #0 !dbg !93 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %From.as_type.as.ImplicitAs.impl.Convert.call = call i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %n), !dbg !98
// CHECK:STDOUT:   %Pick.call = call i32 @"_CPick:overload0.Main"(i64 %From.as_type.as.ImplicitAs.impl.Convert.call), !dbg !101
// CHECK:STDOUT:   %FromCpp__carbon_thunk.call = call i32 @_Z7FromCppi.carbon_thunk._(i32 %n), !dbg !103
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %Pick.call, %FromCpp__carbon_thunk.call, !dbg !101
// CHECK:STDOUT:   ret i32 %Int.as.AddWith.impl.Op.call, !dbg !104
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef i32 @_Z7FromCppi.carbon_thunk._(i32 noundef %v) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !124
// CHECK:STDOUT:   %0 = load i32, ptr %v.addr, align 4, !tbaa !124
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
// CHECK:STDOUT: define linkonce_odr i64 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe"(i32 %self) #0 !dbg !107 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !112
// CHECK:STDOUT:   %2 = sext i32 %1 to i64, !dbg !113
// CHECK:STDOUT:   ret i64 %2, !dbg !114
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !116 {
// CHECK:STDOUT:   ret i32 %self, !dbg !122
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: inlinehint mustprogress uwtable
// CHECK:STDOUT: define linkonce_odr dso_local noundef i32 @_Z7FromCppi(i32 noundef %v) #2 comdat {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %v.addr = alloca i32, align 4
// CHECK:STDOUT:   store i32 %v, ptr %v.addr, align 4, !tbaa !124
// CHECK:STDOUT:   %0 = load i32, ptr %v.addr, align 4, !tbaa !124
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
// CHECK:STDOUT:   store i32 %0, ptr %.addr, align 4, !tbaa !124
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!64}
// CHECK:STDOUT: !llvm.module.flags = !{!58, !59, !60, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!62}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{!7, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !13 = !{null, !6, !7}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !51 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !52 = !{!"omnipotent char", !51, i64 0}
// CHECK:STDOUT: !55 = !{!"int", !52, i64 0}
// CHECK:STDOUT: !58 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !59 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !60 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !61 = !{!"__libc_errno", !55, i64 0}
// CHECK:STDOUT: !62 = !{!61, !55, i64 0}
// CHECK:STDOUT: !63 = !DIFile(filename: "divergence.carbon", directory: "")
// CHECK:STDOUT: !64 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !63, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !65 = !{!7, !7}
// CHECK:STDOUT: !66 = !DISubroutineType(types: !65)
// CHECK:STDOUT: !67 = !{null, !7, !7}
// CHECK:STDOUT: !68 = !DISubroutineType(types: !67)
// CHECK:STDOUT: !69 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload0.Main", scope: null, file: !63, line: 8, type: !9, spFlags: DISPFlagDefinition, unit: !64, retainedNodes: !75)
// CHECK:STDOUT: !70 = !DILocalVariable(arg: 1, scope: !69, type: !6)
// CHECK:STDOUT: !74 = !DILocation(line: 8, column: 42, scope: !69)
// CHECK:STDOUT: !75 = !{!70}
// CHECK:STDOUT: !76 = distinct !DISubprogram(name: "Pick", linkageName: "_CPick:overload1.Main", scope: null, file: !63, line: 9, type: !66, spFlags: DISPFlagDefinition, unit: !64, retainedNodes: !82)
// CHECK:STDOUT: !77 = !DILocalVariable(arg: 1, scope: !76, type: !7)
// CHECK:STDOUT: !81 = !DILocation(line: 9, column: 42, scope: !76)
// CHECK:STDOUT: !82 = !{!77}
// CHECK:STDOUT: !83 = distinct !DISubprogram(name: "Pick__carbon_thunk", linkageName: "_CPick__carbon_thunk:overload0.Main", scope: null, file: !63, line: 8, type: !14, spFlags: DISPFlagDefinition, unit: !64, retainedNodes: !87)
// CHECK:STDOUT: !84 = !DILocalVariable(arg: 1, scope: !83, type: !6)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 2, scope: !83, type: !7)
// CHECK:STDOUT: !86 = !DILocation(line: 8, column: 1, scope: !83)
// CHECK:STDOUT: !87 = !{!84, !85}
// CHECK:STDOUT: !88 = distinct !DISubprogram(name: "Pick__carbon_thunk", linkageName: "_CPick__carbon_thunk:overload1.Main", scope: null, file: !63, line: 9, type: !68, spFlags: DISPFlagDefinition, unit: !64, retainedNodes: !92)
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !88, type: !7)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 2, scope: !88, type: !7)
// CHECK:STDOUT: !91 = !DILocation(line: 9, column: 1, scope: !88)
// CHECK:STDOUT: !92 = !{!89, !90}
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !63, line: 15, type: !66, spFlags: DISPFlagDefinition, unit: !64, retainedNodes: !105)
// CHECK:STDOUT: !94 = !DILocalVariable(arg: 1, scope: !93, type: !7)
// CHECK:STDOUT: !98 = !DILocation(line: 15, column: 37, scope: !93)
// CHECK:STDOUT: !99 = !{!6, !7}
// CHECK:STDOUT: !100 = !DISubroutineType(types: !99)
// CHECK:STDOUT: !101 = !DILocation(line: 15, column: 32, scope: !93)
// CHECK:STDOUT: !103 = !DILocation(line: 15, column: 42, scope: !93)
// CHECK:STDOUT: !104 = !DILocation(line: 15, column: 25, scope: !93)
// CHECK:STDOUT: !105 = !{!94}
// CHECK:STDOUT: !106 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !107 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.f4e5d9509bf46ebe", scope: null, file: !106, line: 64, type: !100, spFlags: DISPFlagDefinition, unit: !64, retainedNodes: !115)
// CHECK:STDOUT: !108 = !DILocalVariable(arg: 1, scope: !107, type: !7)
// CHECK:STDOUT: !112 = !DILocation(line: 66, column: 17, scope: !107)
// CHECK:STDOUT: !113 = !DILocation(line: 66, column: 12, scope: !107)
// CHECK:STDOUT: !114 = !DILocation(line: 66, column: 5, scope: !107)
// CHECK:STDOUT: !115 = !{!108}
// CHECK:STDOUT: !116 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !106, line: 59, type: !66, spFlags: DISPFlagDefinition, unit: !64, retainedNodes: !123)
// CHECK:STDOUT: !117 = !DILocalVariable(arg: 1, scope: !116, type: !7)
// CHECK:STDOUT: !122 = !DILocation(line: 59, column: 28, scope: !116)
// CHECK:STDOUT: !123 = !{!117}
// CHECK:STDOUT: !124 = !{!55, !55, i64 0}
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
// CHECK:STDOUT: define void @_CMake.Acc.Main(ptr sret({ i32 }) %return) #0 !dbg !133 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc12_40.3.total = getelementptr inbounds nuw { i32 }, ptr %return, i32 0, i32 0, !dbg !136
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 4 %return, ptr align 4 @Acc.val.loc12_41, i64 4, i1 false), !dbg !137
// CHECK:STDOUT:   ret void, !dbg !137
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd:overload0.Acc.Main"(ptr %self, i32 %x) #0 !dbg !138 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13_43.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !143
// CHECK:STDOUT:   %.loc13_56.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !144
// CHECK:STDOUT:   %.loc13_56.2 = load i32, ptr %.loc13_56.1.total, align 4, !dbg !144
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc13_56.2, %x, !dbg !144
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc13_43.total, align 4, !dbg !143
// CHECK:STDOUT:   ret void, !dbg !146
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd:overload1.Acc.Main"(ptr %self, i1 %flag) #0 !dbg !148 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   br i1 %flag, label %if.then, label %if.else, !dbg !154
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %.loc15_21.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !155
// CHECK:STDOUT:   %.loc15_34.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !156
// CHECK:STDOUT:   %.loc15_34.2 = load i32, ptr %.loc15_34.1.total, align 4, !dbg !156
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call = add i32 %.loc15_34.2, 100, !dbg !156
// CHECK:STDOUT:   store i32 %Int.as.AddWith.impl.Op.call, ptr %.loc15_21.total, align 4, !dbg !155
// CHECK:STDOUT:   br label %if.else, !dbg !157
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %if.then, %entry
// CHECK:STDOUT:   ret void, !dbg !158
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CGet.Acc.Main(ptr %self) #0 !dbg !160 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc17_36.1.total = getelementptr inbounds nuw { i32 }, ptr %self, i32 0, i32 0, !dbg !165
// CHECK:STDOUT:   %.loc17_36.2 = load i32, ptr %.loc17_36.1.total, align 4, !dbg !165
// CHECK:STDOUT:   ret i32 %.loc17_36.2, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMake__carbon_thunk.Acc.Main(ptr %_) #0 !dbg !168 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CMake.Acc.Main(ptr %_), !dbg !170
// CHECK:STDOUT:   ret void, !dbg !170
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd__carbon_thunk:overload0.Acc.Main"(ptr %self, ptr %_) #0 !dbg !172 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc13 = load i32, ptr %_, align 4, !dbg !175
// CHECK:STDOUT:   call void @"_CAdd:overload0.Acc.Main"(ptr %self, i32 %.loc13), !dbg !175
// CHECK:STDOUT:   ret void, !dbg !175
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @"_CAdd__carbon_thunk:overload1.Acc.Main"(ptr %self, ptr %_) #0 !dbg !177 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14 = load i8, ptr %_, align 1, !dbg !180
// CHECK:STDOUT:   %.loc141 = trunc i8 %.loc14 to i1, !dbg !180
// CHECK:STDOUT:   call void @"_CAdd:overload1.Acc.Main"(ptr %self, i1 %.loc141), !dbg !180
// CHECK:STDOUT:   ret void, !dbg !180
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CGet__carbon_thunk.Acc.Main(ptr %self, ptr %_) #0 !dbg !182 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Acc.Get.call = call i32 @_CGet.Acc.Main(ptr %self), !dbg !185
// CHECK:STDOUT:   store i32 %Acc.Get.call, ptr %_, align 4, !dbg !185
// CHECK:STDOUT:   ret void, !dbg !185
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CUse.Main() #0 !dbg !187 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Drive__carbon_thunk.call = call i32 @_Z5Drivev.carbon_thunk.(), !dbg !190
// CHECK:STDOUT:   ret i32 %Drive__carbon_thunk.call, !dbg !191
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
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !195
// CHECK:STDOUT:   store i32 %0, ptr %.addr, align 4, !tbaa !124
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
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !195
// CHECK:STDOUT:   %storedv = zext i1 %0 to i8
// CHECK:STDOUT:   store i8 %storedv, ptr %.addr, align 1, !tbaa !54
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
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !195
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!126}
// CHECK:STDOUT: !llvm.module.flags = !{!58, !59, !60, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!62}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !11 = !{!7, !10}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !15 = !{null, !10, !7}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = !{!7}
// CHECK:STDOUT: !18 = !DISubroutineType(types: !17)
// CHECK:STDOUT: !51 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !52 = !{!"omnipotent char", !51, i64 0}
// CHECK:STDOUT: !53 = !{!"bool", !52, i64 0}
// CHECK:STDOUT: !54 = !{!53, !53, i64 0}
// CHECK:STDOUT: !55 = !{!"int", !52, i64 0}
// CHECK:STDOUT: !58 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !59 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !60 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !61 = !{!"__libc_errno", !55, i64 0}
// CHECK:STDOUT: !62 = !{!61, !55, i64 0}
// CHECK:STDOUT: !124 = !{!55, !55, i64 0}
// CHECK:STDOUT: !125 = !DIFile(filename: "method_set.carbon", directory: "")
// CHECK:STDOUT: !126 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !125, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !127 = !{!10}
// CHECK:STDOUT: !128 = !DISubroutineType(types: !127)
// CHECK:STDOUT: !129 = !{null, !10, !10}
// CHECK:STDOUT: !130 = !DISubroutineType(types: !129)
// CHECK:STDOUT: !131 = !{null, !10}
// CHECK:STDOUT: !132 = !DISubroutineType(types: !131)
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "Make", linkageName: "_CMake.Acc.Main", scope: null, file: !125, line: 12, type: !128, spFlags: DISPFlagDefinition, unit: !126)
// CHECK:STDOUT: !136 = !DILocation(line: 12, column: 29, scope: !133)
// CHECK:STDOUT: !137 = !DILocation(line: 12, column: 22, scope: !133)
// CHECK:STDOUT: !138 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload0.Acc.Main", scope: null, file: !125, line: 13, type: !16, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !147)
// CHECK:STDOUT: !139 = !DILocalVariable(arg: 1, scope: !138, type: !10)
// CHECK:STDOUT: !140 = !DILocalVariable(arg: 2, scope: !138, type: !7)
// CHECK:STDOUT: !143 = !DILocation(line: 13, column: 39, scope: !138)
// CHECK:STDOUT: !144 = !DILocation(line: 13, column: 52, scope: !138)
// CHECK:STDOUT: !146 = !DILocation(line: 13, column: 3, scope: !138)
// CHECK:STDOUT: !147 = !{!139, !140}
// CHECK:STDOUT: !148 = distinct !DISubprogram(name: "Add", linkageName: "_CAdd:overload1.Acc.Main", scope: null, file: !125, line: 14, type: !130, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !159)
// CHECK:STDOUT: !149 = !DILocalVariable(arg: 1, scope: !148, type: !10)
// CHECK:STDOUT: !150 = !DILocalVariable(arg: 2, scope: !148, type: !10)
// CHECK:STDOUT: !154 = !DILocation(line: 15, column: 8, scope: !148)
// CHECK:STDOUT: !155 = !DILocation(line: 15, column: 17, scope: !148)
// CHECK:STDOUT: !156 = !DILocation(line: 15, column: 30, scope: !148)
// CHECK:STDOUT: !157 = !DILocation(line: 15, column: 5, scope: !148)
// CHECK:STDOUT: !158 = !DILocation(line: 14, column: 3, scope: !148)
// CHECK:STDOUT: !159 = !{!149, !150}
// CHECK:STDOUT: !160 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Acc.Main", scope: null, file: !125, line: 17, type: !12, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !167)
// CHECK:STDOUT: !161 = !DILocalVariable(arg: 1, scope: !160, type: !10)
// CHECK:STDOUT: !165 = !DILocation(line: 17, column: 32, scope: !160)
// CHECK:STDOUT: !166 = !DILocation(line: 17, column: 25, scope: !160)
// CHECK:STDOUT: !167 = !{!161}
// CHECK:STDOUT: !168 = distinct !DISubprogram(name: "Make__carbon_thunk", linkageName: "_CMake__carbon_thunk.Acc.Main", scope: null, file: !125, line: 12, type: !132, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !171)
// CHECK:STDOUT: !169 = !DILocalVariable(arg: 1, scope: !168, type: !10)
// CHECK:STDOUT: !170 = !DILocation(line: 12, column: 3, scope: !168)
// CHECK:STDOUT: !171 = !{!169}
// CHECK:STDOUT: !172 = distinct !DISubprogram(name: "Add__carbon_thunk", linkageName: "_CAdd__carbon_thunk:overload0.Acc.Main", scope: null, file: !125, line: 13, type: !16, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !176)
// CHECK:STDOUT: !173 = !DILocalVariable(arg: 1, scope: !172, type: !10)
// CHECK:STDOUT: !174 = !DILocalVariable(arg: 2, scope: !172, type: !7)
// CHECK:STDOUT: !175 = !DILocation(line: 13, column: 3, scope: !172)
// CHECK:STDOUT: !176 = !{!173, !174}
// CHECK:STDOUT: !177 = distinct !DISubprogram(name: "Add__carbon_thunk", linkageName: "_CAdd__carbon_thunk:overload1.Acc.Main", scope: null, file: !125, line: 14, type: !130, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !181)
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 1, scope: !177, type: !10)
// CHECK:STDOUT: !179 = !DILocalVariable(arg: 2, scope: !177, type: !10)
// CHECK:STDOUT: !180 = !DILocation(line: 14, column: 3, scope: !177)
// CHECK:STDOUT: !181 = !{!178, !179}
// CHECK:STDOUT: !182 = distinct !DISubprogram(name: "Get__carbon_thunk", linkageName: "_CGet__carbon_thunk.Acc.Main", scope: null, file: !125, line: 17, type: !16, spFlags: DISPFlagDefinition, unit: !126, retainedNodes: !186)
// CHECK:STDOUT: !183 = !DILocalVariable(arg: 1, scope: !182, type: !10)
// CHECK:STDOUT: !184 = !DILocalVariable(arg: 2, scope: !182, type: !7)
// CHECK:STDOUT: !185 = !DILocation(line: 17, column: 3, scope: !182)
// CHECK:STDOUT: !186 = !{!183, !184}
// CHECK:STDOUT: !187 = distinct !DISubprogram(name: "Use", linkageName: "_CUse.Main", scope: null, file: !125, line: 29, type: !18, spFlags: DISPFlagDefinition, unit: !126)
// CHECK:STDOUT: !190 = !DILocation(line: 29, column: 26, scope: !187)
// CHECK:STDOUT: !191 = !DILocation(line: 29, column: 19, scope: !187)
// CHECK:STDOUT: !193 = !{!"any pointer", !52, i64 0}
// CHECK:STDOUT: !194 = !{!"p1 _ZTSN6Carbon3AccE", !193, i64 0}
// CHECK:STDOUT: !195 = !{!194, !194, i64 0}
// CHECK:STDOUT:
