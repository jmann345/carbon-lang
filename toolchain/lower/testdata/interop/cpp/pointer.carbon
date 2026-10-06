// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/pointer.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/pointer.carbon

// ============================================================================
// Non-null pointers
// ============================================================================

// --- nonnull.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class NonnullC {};

auto TakeNonnullPtr(NonnullC* _Nonnull) -> void;
auto ReturnNonnullPtr() -> NonnullC* _Nonnull;

auto TakeNonnullPtrWithThunk(NonnullC* _Nonnull, int = 0) -> void;
auto ReturnNonnullPtrWithThunk(int = 0) -> NonnullC* _Nonnull;
''';

fn PassPtr(p: Cpp.NonnullC*) {
  Cpp.TakeNonnullPtr(p);
}

fn ReturnPtr() -> Cpp.NonnullC* {
  return Cpp.ReturnNonnullPtr();
}

fn PassPtrWithThunk(p: Cpp.NonnullC*) {
  Cpp.TakeNonnullPtrWithThunk(p);
}

fn ReturnPtrWithThunk() -> Cpp.NonnullC* {
  return Cpp.ReturnNonnullPtrWithThunk();
}

// ============================================================================
// Nullable pointers
// ============================================================================

// --- nullable.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class NullableC {};

auto TakeNullablePtr(NullableC*) -> void;
auto ReturnNullablePtr() -> NullableC*;

auto TakeNullablePtrWithThunk(NullableC*, int = 0) -> void;
auto ReturnNullablePtrWithThunk(int = 0) -> NullableC*;
''';

fn PassPtr(_: Core.Optional(Cpp.NullableC*)) {
  // TODO: Add support for passing an optional here.
  // Cpp.TakeNullablePtr(p);
}

fn PassNonnullPtr(p: Cpp.NullableC*) {
  // TODO: The `value_of_initializer` optimization doesn't get used here, so we
  // unnecessarily round-trip this value through memory.
  Cpp.TakeNullablePtr(p);
}

fn ReturnPtr() -> Core.Optional(Cpp.NullableC*) {
  return Cpp.ReturnNullablePtr();
}

fn PassPtrWithThunk(_: Core.Optional(Cpp.NullableC*)) {
  // TODO: Add support for passing an optional here.
  // Cpp.TakeNullablePtrWithThunk(p);
}

fn PassNonnullPtrWithThunk(p: Cpp.NullableC*) {
  Cpp.TakeNullablePtrWithThunk(p);
}

fn ReturnPtrWithThunk() -> Core.Optional(Cpp.NullableC*) {
  return Cpp.ReturnNullablePtrWithThunk();
}

// --- add_const.carbon

library "[[@TEST_NAME]]";

import Cpp inline '''
class ConstC {};
ConstC *make();
void take(const ConstC*);
''';

fn Convert() {
  Cpp.take(Cpp.make());
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'nonnull.carbon'
// CHECK:STDOUT: source_filename = "nonnull.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [81 x i8] c"carbon: C++ exception escaped into Carbon through `TakeNonnullPtr`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [83 x i8] c"carbon: C++ exception escaped into Carbon through `ReturnNonnullPtr`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.2 = private unnamed_addr constant [90 x i8] c"carbon: C++ exception escaped into Carbon through `TakeNonnullPtrWithThunk`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.3 = private unnamed_addr constant [92 x i8] c"carbon: C++ exception escaped into Carbon through `ReturnNonnullPtrWithThunk`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassPtr.Main(ptr %p) #0 !dbg !11 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z14TakeNonnullPtrP8NonnullC.carbon_thunk._(ptr %p), !dbg !15
// CHECK:STDOUT:   ret void, !dbg !16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z14TakeNonnullPtrP8NonnullC.carbon_thunk._(ptr noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !39
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !39
// CHECK:STDOUT:   invoke void @_Z14TakeNonnullPtrP8NonnullC(ptr noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 80) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CReturnPtr.Main() #0 !dbg !18 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %ReturnNonnullPtr__carbon_thunk.call = call ptr @_Z16ReturnNonnullPtrv.carbon_thunk.(), !dbg !21
// CHECK:STDOUT:   ret ptr %ReturnNonnullPtr__carbon_thunk.call, !dbg !22
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef ptr @_Z16ReturnNonnullPtrv.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef ptr @_Z16ReturnNonnullPtrv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 82) #0
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
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassPtrWithThunk.Main(ptr %p) #0 !dbg !23 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z23TakeNonnullPtrWithThunkP8NonnullCi.carbon_thunk._(ptr %p), !dbg !27
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z23TakeNonnullPtrWithThunkP8NonnullCi.carbon_thunk._(ptr noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !39
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !39
// CHECK:STDOUT:   invoke void @_Z23TakeNonnullPtrWithThunkP8NonnullCi(ptr noundef %1, i32 noundef 0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.2, i64 noundef 89) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #5
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CReturnPtrWithThunk.Main() #0 !dbg !30 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %ReturnNonnullPtrWithThunk__carbon_thunk.call = call ptr @_Z25ReturnNonnullPtrWithThunki.carbon_thunk.(), !dbg !33
// CHECK:STDOUT:   ret ptr %ReturnNonnullPtrWithThunk__carbon_thunk.call, !dbg !34
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef ptr @_Z25ReturnNonnullPtrWithThunki.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef ptr @_Z25ReturnNonnullPtrWithThunki(i32 noundef 0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.3, i64 noundef 91) #0
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
// CHECK:STDOUT: declare void @_Z14TakeNonnullPtrP8NonnullC(ptr noundef) #2
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
// CHECK:STDOUT: declare noundef ptr @_Z16ReturnNonnullPtrv() #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z23TakeNonnullPtrWithThunkP8NonnullCi(ptr noundef, i32 noundef) #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare noundef ptr @_Z25ReturnNonnullPtrWithThunki(i32 noundef) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 3, 4, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noreturn }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!40, !41, !42, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!45}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "nonnull.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{!6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !11 = distinct !DISubprogram(name: "PassPtr", linkageName: "_CPassPtr.Main", scope: null, file: !4, line: 14, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !17)
// CHECK:STDOUT: !12 = !DILocalVariable(arg: 1, scope: !11, type: !6)
// CHECK:STDOUT: !15 = !DILocation(line: 15, column: 3, scope: !11)
// CHECK:STDOUT: !16 = !DILocation(line: 14, column: 1, scope: !11)
// CHECK:STDOUT: !17 = !{!12}
// CHECK:STDOUT: !18 = distinct !DISubprogram(name: "ReturnPtr", linkageName: "_CReturnPtr.Main", scope: null, file: !4, line: 18, type: !10, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !21 = !DILocation(line: 19, column: 10, scope: !18)
// CHECK:STDOUT: !22 = !DILocation(line: 19, column: 3, scope: !18)
// CHECK:STDOUT: !23 = distinct !DISubprogram(name: "PassPtrWithThunk", linkageName: "_CPassPtrWithThunk.Main", scope: null, file: !4, line: 22, type: !8, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !29)
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !23, type: !6)
// CHECK:STDOUT: !27 = !DILocation(line: 23, column: 3, scope: !23)
// CHECK:STDOUT: !28 = !DILocation(line: 22, column: 1, scope: !23)
// CHECK:STDOUT: !29 = !{!24}
// CHECK:STDOUT: !30 = distinct !DISubprogram(name: "ReturnPtrWithThunk", linkageName: "_CReturnPtrWithThunk.Main", scope: null, file: !4, line: 26, type: !10, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !33 = !DILocation(line: 27, column: 10, scope: !30)
// CHECK:STDOUT: !34 = !DILocation(line: 27, column: 3, scope: !30)
// CHECK:STDOUT: !35 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !36 = !{!"omnipotent char", !35, i64 0}
// CHECK:STDOUT: !37 = !{!"any pointer", !36, i64 0}
// CHECK:STDOUT: !38 = !{!"p1 _ZTS8NonnullC", !37, i64 0}
// CHECK:STDOUT: !39 = !{!38, !38, i64 0}
// CHECK:STDOUT: !40 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !41 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !42 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !43 = !{!"int", !36, i64 0}
// CHECK:STDOUT: !44 = !{!"__libc_errno", !43, i64 0}
// CHECK:STDOUT: !45 = !{!44, !43, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'nullable.carbon'
// CHECK:STDOUT: source_filename = "nullable.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [82 x i8] c"carbon: C++ exception escaped into Carbon through `TakeNullablePtr`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [84 x i8] c"carbon: C++ exception escaped into Carbon through `ReturnNullablePtr`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.2 = private unnamed_addr constant [91 x i8] c"carbon: C++ exception escaped into Carbon through `TakeNullablePtrWithThunk`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.3 = private unnamed_addr constant [93 x i8] c"carbon: C++ exception escaped into Carbon through `ReturnNullablePtrWithThunk`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.51fa064adaeb8681:core.Destroy.Core"(ptr %self) #0 !dbg !49 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassPtr.Main(ptr %_) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !56
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassNonnullPtr.Main(ptr %p) #0 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc22_23.2.temp = alloca ptr, align 8, !dbg !61
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.75a9143bcbb84fa5"(ptr %p), !dbg !61
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc22_23.2.temp), !dbg !61
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc22_23.2.temp, align 8, !dbg !61
// CHECK:STDOUT:   %.loc22_23.4 = load ptr, ptr %.loc22_23.2.temp, align 8, !dbg !61
// CHECK:STDOUT:   call void @_Z15TakeNullablePtrP9NullableC.carbon_thunk._(ptr %.loc22_23.4), !dbg !64
// CHECK:STDOUT:   call void @"_CSelfDestruct.574ea10b2e6709a0:core.Destroy.Core"(ptr %.loc22_23.2.temp), !dbg !61
// CHECK:STDOUT:   ret void, !dbg !65
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z15TakeNullablePtrP9NullableC.carbon_thunk._(ptr noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !141
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !141
// CHECK:STDOUT:   invoke void @_Z15TakeNullablePtrP9NullableC(ptr noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 81) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6789a803c53632c0:core.Destroy.Core"(ptr %self) #0 !dbg !67 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !69
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5cf0c9a25f98a429:core.Destroy.Core"(ptr %self) #0 !dbg !71 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.574ea10b2e6709a0:core.Destroy.Core"(ptr %self) #0 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CReturnPtr.Main() #0 !dbg !79 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %ReturnNullablePtr__carbon_thunk.call = call ptr @_Z17ReturnNullablePtrv.carbon_thunk.(), !dbg !82
// CHECK:STDOUT:   ret ptr %ReturnNullablePtr__carbon_thunk.call, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef ptr @_Z17ReturnNullablePtrv.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef ptr @_Z17ReturnNullablePtrv()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 83) #0
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
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassPtrWithThunk.Main(ptr %_) #0 !dbg !84 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassNonnullPtrWithThunk.Main(ptr %p) #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc35_32.2.temp = alloca ptr, align 8, !dbg !92
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.75a9143bcbb84fa5"(ptr %p), !dbg !92
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc35_32.2.temp), !dbg !92
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc35_32.2.temp, align 8, !dbg !92
// CHECK:STDOUT:   %.loc35_32.4 = load ptr, ptr %.loc35_32.2.temp, align 8, !dbg !92
// CHECK:STDOUT:   call void @_Z24TakeNullablePtrWithThunkP9NullableCi.carbon_thunk._(ptr %.loc35_32.4), !dbg !93
// CHECK:STDOUT:   call void @"_CSelfDestruct.574ea10b2e6709a0:core.Destroy.Core"(ptr %.loc35_32.2.temp), !dbg !92
// CHECK:STDOUT:   ret void, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z24TakeNullablePtrWithThunkP9NullableCi.carbon_thunk._(ptr noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !141
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !141
// CHECK:STDOUT:   invoke void @_Z24TakeNullablePtrWithThunkP9NullableCi(ptr noundef %1, i32 noundef 0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.2, i64 noundef 90) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CReturnPtrWithThunk.Main() #0 !dbg !96 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %ReturnNullablePtrWithThunk__carbon_thunk.call = call ptr @_Z26ReturnNullablePtrWithThunki.carbon_thunk.(), !dbg !99
// CHECK:STDOUT:   ret ptr %ReturnNullablePtrWithThunk__carbon_thunk.call, !dbg !100
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef ptr @_Z26ReturnNullablePtrWithThunki.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef ptr @_Z26ReturnNullablePtrWithThunki(i32 noundef 0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.3, i64 noundef 92) #0
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
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.75a9143bcbb84fa5"(ptr %self) #0 !dbg !102 {
// CHECK:STDOUT:   %1 = call ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.e83c25d1d2fd22c2"(ptr %self), !dbg !107
// CHECK:STDOUT:   ret ptr %1, !dbg !108
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.e83c25d1d2fd22c2"(ptr %self) #0 !dbg !110 {
// CHECK:STDOUT:   %1 = call ptr @_CSome.Optional.Core.e83c25d1d2fd22c2(ptr %self), !dbg !116
// CHECK:STDOUT:   ret ptr %1, !dbg !117
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CSome.Optional.Core.e83c25d1d2fd22c2(ptr %value) #0 !dbg !119 {
// CHECK:STDOUT:   %1 = call ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.77dd513e5db6ef8d"(ptr %value), !dbg !124
// CHECK:STDOUT:   ret ptr %1, !dbg !125
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.77dd513e5db6ef8d"(ptr %self) #0 !dbg !127 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !132
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !132
// CHECK:STDOUT:   store ptr poison, ptr %1, align 8, !dbg !132
// CHECK:STDOUT:   store ptr %self, ptr %1, align 8, !dbg !136
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8, !dbg !134
// CHECK:STDOUT:   call void @"_CSelfDestruct.5cf0c9a25f98a429:core.Destroy.Core"(ptr %1), !dbg !132
// CHECK:STDOUT:   ret ptr %2, !dbg !138
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z15TakeNullablePtrP9NullableC(ptr noundef) #3
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
// CHECK:STDOUT: declare noundef ptr @_Z17ReturnNullablePtrv() #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z24TakeNullablePtrWithThunkP9NullableCi(ptr noundef, i32 noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare noundef ptr @_Z26ReturnNullablePtrWithThunki(i32 noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.75a9143bcbb84fa5", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 3, 4, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 3, 2, 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 3, 2, 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!47}
// CHECK:STDOUT: !llvm.module.flags = !{!40, !41, !42, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!45}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{!6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !35 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !36 = !{!"omnipotent char", !35, i64 0}
// CHECK:STDOUT: !37 = !{!"any pointer", !36, i64 0}
// CHECK:STDOUT: !40 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !41 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !42 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !43 = !{!"int", !36, i64 0}
// CHECK:STDOUT: !44 = !{!"__libc_errno", !43, i64 0}
// CHECK:STDOUT: !45 = !{!44, !43, i64 0}
// CHECK:STDOUT: !46 = !DIFile(filename: "nullable.carbon", directory: "")
// CHECK:STDOUT: !47 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !46, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !48 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !49 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.51fa064adaeb8681:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !52)
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !49, type: !6)
// CHECK:STDOUT: !51 = !DILocation(line: 189, column: 19, scope: !49)
// CHECK:STDOUT: !52 = !{!50}
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "PassPtr", linkageName: "_CPassPtr.Main", scope: null, file: !46, line: 14, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !57)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !6)
// CHECK:STDOUT: !56 = !DILocation(line: 14, column: 1, scope: !53)
// CHECK:STDOUT: !57 = !{!54}
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "PassNonnullPtr", linkageName: "_CPassNonnullPtr.Main", scope: null, file: !46, line: 19, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !66)
// CHECK:STDOUT: !59 = !DILocalVariable(arg: 1, scope: !58, type: !6)
// CHECK:STDOUT: !61 = !DILocation(line: 22, column: 23, scope: !58)
// CHECK:STDOUT: !62 = !{!6, !6}
// CHECK:STDOUT: !63 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !64 = !DILocation(line: 22, column: 3, scope: !58)
// CHECK:STDOUT: !65 = !DILocation(line: 19, column: 1, scope: !58)
// CHECK:STDOUT: !66 = !{!59}
// CHECK:STDOUT: !67 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6789a803c53632c0:core.Destroy.Core", scope: null, file: !46, line: 22, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !70)
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !67, type: !6)
// CHECK:STDOUT: !69 = !DILocation(line: 22, column: 23, scope: !67)
// CHECK:STDOUT: !70 = !{!68}
// CHECK:STDOUT: !71 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5cf0c9a25f98a429:core.Destroy.Core", scope: null, file: !46, line: 22, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !74)
// CHECK:STDOUT: !72 = !DILocalVariable(arg: 1, scope: !71, type: !6)
// CHECK:STDOUT: !73 = !DILocation(line: 22, column: 23, scope: !71)
// CHECK:STDOUT: !74 = !{!72}
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.574ea10b2e6709a0:core.Destroy.Core", scope: null, file: !46, line: 22, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !78)
// CHECK:STDOUT: !76 = !DILocalVariable(arg: 1, scope: !75, type: !6)
// CHECK:STDOUT: !77 = !DILocation(line: 22, column: 23, scope: !75)
// CHECK:STDOUT: !78 = !{!76}
// CHECK:STDOUT: !79 = distinct !DISubprogram(name: "ReturnPtr", linkageName: "_CReturnPtr.Main", scope: null, file: !46, line: 25, type: !10, spFlags: DISPFlagDefinition, unit: !47)
// CHECK:STDOUT: !82 = !DILocation(line: 26, column: 10, scope: !79)
// CHECK:STDOUT: !83 = !DILocation(line: 26, column: 3, scope: !79)
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "PassPtrWithThunk", linkageName: "_CPassPtrWithThunk.Main", scope: null, file: !46, line: 29, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !88)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !6)
// CHECK:STDOUT: !87 = !DILocation(line: 29, column: 1, scope: !84)
// CHECK:STDOUT: !88 = !{!85}
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "PassNonnullPtrWithThunk", linkageName: "_CPassNonnullPtrWithThunk.Main", scope: null, file: !46, line: 34, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !95)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !89, type: !6)
// CHECK:STDOUT: !92 = !DILocation(line: 35, column: 32, scope: !89)
// CHECK:STDOUT: !93 = !DILocation(line: 35, column: 3, scope: !89)
// CHECK:STDOUT: !94 = !DILocation(line: 34, column: 1, scope: !89)
// CHECK:STDOUT: !95 = !{!90}
// CHECK:STDOUT: !96 = distinct !DISubprogram(name: "ReturnPtrWithThunk", linkageName: "_CReturnPtrWithThunk.Main", scope: null, file: !46, line: 38, type: !10, spFlags: DISPFlagDefinition, unit: !47)
// CHECK:STDOUT: !99 = !DILocation(line: 39, column: 10, scope: !96)
// CHECK:STDOUT: !100 = !DILocation(line: 39, column: 3, scope: !96)
// CHECK:STDOUT: !102 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.75a9143bcbb84fa5", scope: null, file: !48, line: 130, type: !63, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !109)
// CHECK:STDOUT: !103 = !DILocalVariable(arg: 1, scope: !102, type: !6)
// CHECK:STDOUT: !107 = !DILocation(line: 131, column: 12, scope: !102)
// CHECK:STDOUT: !108 = !DILocation(line: 131, column: 5, scope: !102)
// CHECK:STDOUT: !109 = !{!103}
// CHECK:STDOUT: !110 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.e83c25d1d2fd22c2", scope: null, file: !48, line: 105, type: !63, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !118)
// CHECK:STDOUT: !111 = !DILocalVariable(arg: 1, scope: !110, type: !6)
// CHECK:STDOUT: !116 = !DILocation(line: 106, column: 12, scope: !110)
// CHECK:STDOUT: !117 = !DILocation(line: 106, column: 5, scope: !110)
// CHECK:STDOUT: !118 = !{!111}
// CHECK:STDOUT: !119 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.e83c25d1d2fd22c2", scope: null, file: !48, line: 34, type: !63, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !126)
// CHECK:STDOUT: !120 = !DILocalVariable(arg: 1, scope: !119, type: !6)
// CHECK:STDOUT: !124 = !DILocation(line: 35, column: 12, scope: !119)
// CHECK:STDOUT: !125 = !DILocation(line: 35, column: 5, scope: !119)
// CHECK:STDOUT: !126 = !{!120}
// CHECK:STDOUT: !127 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.e8f8f92d3d08d149:OptionalStorage.Core.77dd513e5db6ef8d", scope: null, file: !48, line: 191, type: !63, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !139)
// CHECK:STDOUT: !128 = !DILocalVariable(arg: 1, scope: !127, type: !6)
// CHECK:STDOUT: !132 = !DILocation(line: 192, column: 14, scope: !127)
// CHECK:STDOUT: !134 = !DILocation(line: 192, column: 18, scope: !127)
// CHECK:STDOUT: !136 = !DILocation(line: 194, column: 5, scope: !127)
// CHECK:STDOUT: !138 = !DILocation(line: 195, column: 5, scope: !127)
// CHECK:STDOUT: !139 = !{!128}
// CHECK:STDOUT: !140 = !{!"p1 _ZTS9NullableC", !37, i64 0}
// CHECK:STDOUT: !141 = !{!140, !140, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'add_const.carbon'
// CHECK:STDOUT: source_filename = "add_const.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @.str = private unnamed_addr constant [71 x i8] c"carbon: C++ exception escaped into Carbon through `make`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [71 x i8] c"carbon: C++ exception escaped into Carbon through `take`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CConvert.Main() #0 !dbg !146 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_21.1.temp = alloca ptr, align 8, !dbg !147
// CHECK:STDOUT:   %.loc11_21.5.temp = alloca ptr, align 8, !dbg !147
// CHECK:STDOUT:   %make__carbon_thunk.call = call ptr @_Z4makev.carbon_thunk.(), !dbg !147
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc11_21.1.temp), !dbg !147
// CHECK:STDOUT:   store ptr %make__carbon_thunk.call, ptr %.loc11_21.1.temp, align 8, !dbg !147
// CHECK:STDOUT:   %.loc11_21.3 = load ptr, ptr %.loc11_21.1.temp, align 8, !dbg !147
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.7d29ea9e6f62bf96"(ptr %.loc11_21.3), !dbg !147
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc11_21.5.temp), !dbg !147
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc11_21.5.temp, align 8, !dbg !147
// CHECK:STDOUT:   %.loc11_21.7 = load ptr, ptr %.loc11_21.5.temp, align 8, !dbg !147
// CHECK:STDOUT:   call void @_Z4takePK6ConstC.carbon_thunk._(ptr %.loc11_21.7), !dbg !148
// CHECK:STDOUT:   call void @"_CSelfDestruct.19661d0961df889d:core.Destroy.Core"(ptr %.loc11_21.5.temp), !dbg !147
// CHECK:STDOUT:   call void @"_CSelfDestruct.78fd6ee82eacbbc3:core.Destroy.Core"(ptr %.loc11_21.1.temp), !dbg !147
// CHECK:STDOUT:   ret void, !dbg !149
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.23bb4d554c74e0f1:core.Destroy.Core"(ptr %self) #0 !dbg !150 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !152
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal noundef ptr @_Z4makev.carbon_thunk.() #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %call = invoke noundef ptr @_Z4makev()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   ret ptr %call
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
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 70) #0
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
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.131ece8d9a7a4272:core.Destroy.Core"(ptr %self) #0 !dbg !154 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !156
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z4takePK6ConstC.carbon_thunk._(ptr noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !266
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !266
// CHECK:STDOUT:   invoke void @_Z4takePK6ConstC(ptr noundef %1)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %2 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %3 = extractvalue { ptr, i32 } %2, 0
// CHECK:STDOUT:   store ptr %3, ptr %exn.slot, align 8
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %2, 1
// CHECK:STDOUT:   store i32 %4, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 70) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %6 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %6, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %7) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bdb5ffe218b7af7d:core.Destroy.Core"(ptr %self) #0 !dbg !158 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !160
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f914f15dcbbdbae9:core.Destroy.Core"(ptr %self) #0 !dbg !162 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !164
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.19661d0961df889d:core.Destroy.Core"(ptr %self) #0 !dbg !166 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !168
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e3602e7640dfb844:core.Destroy.Core"(ptr %self) #0 !dbg !170 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !172
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bc918cd0012c1190:core.Destroy.Core"(ptr %self) #0 !dbg !174 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !176
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.78fd6ee82eacbbc3:core.Destroy.Core"(ptr %self) #0 !dbg !178 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !180
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.7d29ea9e6f62bf96"(ptr %self) #0 !dbg !182 {
// CHECK:STDOUT:   %1 = call ptr @"_CConvert.Optional.c661605f12aa337a.Core:OptionalAs.1dac4564233fecd1.Core.c5881e9a6965c8a5"(ptr %self), !dbg !187
// CHECK:STDOUT:   ret ptr %1, !dbg !188
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.Optional.c661605f12aa337a.Core:OptionalAs.1dac4564233fecd1.Core.c5881e9a6965c8a5"(ptr %self) #0 !dbg !190 {
// CHECK:STDOUT:   %temp = alloca ptr, align 8, !dbg !197
// CHECK:STDOUT:   %temp1 = alloca ptr, align 8, !dbg !197
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.0c3518913b4fb338(ptr %self), !dbg !195
// CHECK:STDOUT:   br i1 %1, label %2, label %7, !dbg !196
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !197
// CHECK:STDOUT:   %3 = call ptr @_CGet.Optional.Core.0c3518913b4fb338(ptr %self), !dbg !197
// CHECK:STDOUT:   store ptr %3, ptr %temp, align 8, !dbg !197
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !197
// CHECK:STDOUT:   %4 = load ptr, ptr %temp, align 8, !dbg !197
// CHECK:STDOUT:   store ptr %4, ptr %temp1, align 8, !dbg !197
// CHECK:STDOUT:   %5 = load ptr, ptr %temp1, align 8, !dbg !197
// CHECK:STDOUT:   %6 = call ptr @_CSome.Optional.Core.305e266058820aa4(ptr %5), !dbg !198
// CHECK:STDOUT:   call void @"_CSelfDestruct.131ece8d9a7a4272:core.Destroy.Core"(ptr %temp1), !dbg !197
// CHECK:STDOUT:   call void @"_CSelfDestruct.23bb4d554c74e0f1:core.Destroy.Core"(ptr %temp), !dbg !197
// CHECK:STDOUT:   ret ptr %6, !dbg !199
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %0
// CHECK:STDOUT:   %8 = call ptr @_CNone.Optional.Core.305e266058820aa4(), !dbg !200
// CHECK:STDOUT:   ret ptr %8, !dbg !201
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.0c3518913b4fb338(ptr %self) #0 !dbg !203 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4"(ptr %self), !dbg !209
// CHECK:STDOUT:   ret i1 %1, !dbg !210
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CGet.Optional.Core.0c3518913b4fb338(ptr %self) #0 !dbg !212 {
// CHECK:STDOUT:   %1 = call ptr @"_CGet.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4"(ptr %self), !dbg !218
// CHECK:STDOUT:   ret ptr %1, !dbg !219
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CSome.Optional.Core.305e266058820aa4(ptr %value) #0 !dbg !221 {
// CHECK:STDOUT:   %1 = call ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.35c29317da7de352"(ptr %value), !dbg !226
// CHECK:STDOUT:   ret ptr %1, !dbg !227
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CNone.Optional.Core.305e266058820aa4() #0 !dbg !229 {
// CHECK:STDOUT:   ret ptr null, !dbg !233
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4"(ptr %value) #0 !dbg !234 {
// CHECK:STDOUT:   %1 = icmp eq ptr %value, null, !dbg !240
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !241
// CHECK:STDOUT:   ret i1 %2, !dbg !242
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CGet.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4"(ptr %value) #0 !dbg !244 {
// CHECK:STDOUT:   ret ptr %value, !dbg !250
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.35c29317da7de352"(ptr %self) #0 !dbg !252 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !257
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !257
// CHECK:STDOUT:   store ptr poison, ptr %1, align 8, !dbg !257
// CHECK:STDOUT:   store ptr %self, ptr %1, align 8, !dbg !261
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8, !dbg !259
// CHECK:STDOUT:   call void @"_CSelfDestruct.f914f15dcbbdbae9:core.Destroy.Core"(ptr %1), !dbg !257
// CHECK:STDOUT:   ret ptr %2, !dbg !263
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare noundef ptr @_Z4makev() #3
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
// CHECK:STDOUT: declare void @_Z4takePK6ConstC(ptr noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 1, 2, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!143}
// CHECK:STDOUT: !llvm.module.flags = !{!40, !41, !42, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!45}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !6 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !7 = !{null, !6}
// CHECK:STDOUT: !8 = !DISubroutineType(types: !7)
// CHECK:STDOUT: !9 = !{!6}
// CHECK:STDOUT: !10 = !DISubroutineType(types: !9)
// CHECK:STDOUT: !35 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !36 = !{!"omnipotent char", !35, i64 0}
// CHECK:STDOUT: !37 = !{!"any pointer", !36, i64 0}
// CHECK:STDOUT: !40 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !41 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !42 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !43 = !{!"int", !36, i64 0}
// CHECK:STDOUT: !44 = !{!"__libc_errno", !43, i64 0}
// CHECK:STDOUT: !45 = !{!44, !43, i64 0}
// CHECK:STDOUT: !48 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !62 = !{!6, !6}
// CHECK:STDOUT: !63 = !DISubroutineType(types: !62)
// CHECK:STDOUT: !142 = !DIFile(filename: "add_const.carbon", directory: "")
// CHECK:STDOUT: !143 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !142, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !144 = !{null}
// CHECK:STDOUT: !145 = !DISubroutineType(types: !144)
// CHECK:STDOUT: !146 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Main", scope: null, file: !142, line: 10, type: !145, spFlags: DISPFlagDefinition, unit: !143)
// CHECK:STDOUT: !147 = !DILocation(line: 11, column: 12, scope: !146)
// CHECK:STDOUT: !148 = !DILocation(line: 11, column: 3, scope: !146)
// CHECK:STDOUT: !149 = !DILocation(line: 10, column: 1, scope: !146)
// CHECK:STDOUT: !150 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.23bb4d554c74e0f1:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !153)
// CHECK:STDOUT: !151 = !DILocalVariable(arg: 1, scope: !150, type: !6)
// CHECK:STDOUT: !152 = !DILocation(line: 189, column: 19, scope: !150)
// CHECK:STDOUT: !153 = !{!151}
// CHECK:STDOUT: !154 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.131ece8d9a7a4272:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !157)
// CHECK:STDOUT: !155 = !DILocalVariable(arg: 1, scope: !154, type: !6)
// CHECK:STDOUT: !156 = !DILocation(line: 189, column: 19, scope: !154)
// CHECK:STDOUT: !157 = !{!155}
// CHECK:STDOUT: !158 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bdb5ffe218b7af7d:core.Destroy.Core", scope: null, file: !142, line: 11, type: !8, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !161)
// CHECK:STDOUT: !159 = !DILocalVariable(arg: 1, scope: !158, type: !6)
// CHECK:STDOUT: !160 = !DILocation(line: 11, column: 12, scope: !158)
// CHECK:STDOUT: !161 = !{!159}
// CHECK:STDOUT: !162 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f914f15dcbbdbae9:core.Destroy.Core", scope: null, file: !142, line: 11, type: !8, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !165)
// CHECK:STDOUT: !163 = !DILocalVariable(arg: 1, scope: !162, type: !6)
// CHECK:STDOUT: !164 = !DILocation(line: 11, column: 12, scope: !162)
// CHECK:STDOUT: !165 = !{!163}
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.19661d0961df889d:core.Destroy.Core", scope: null, file: !142, line: 11, type: !8, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !169)
// CHECK:STDOUT: !167 = !DILocalVariable(arg: 1, scope: !166, type: !6)
// CHECK:STDOUT: !168 = !DILocation(line: 11, column: 12, scope: !166)
// CHECK:STDOUT: !169 = !{!167}
// CHECK:STDOUT: !170 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e3602e7640dfb844:core.Destroy.Core", scope: null, file: !142, line: 11, type: !8, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !173)
// CHECK:STDOUT: !171 = !DILocalVariable(arg: 1, scope: !170, type: !6)
// CHECK:STDOUT: !172 = !DILocation(line: 11, column: 12, scope: !170)
// CHECK:STDOUT: !173 = !{!171}
// CHECK:STDOUT: !174 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bc918cd0012c1190:core.Destroy.Core", scope: null, file: !142, line: 11, type: !8, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !177)
// CHECK:STDOUT: !175 = !DILocalVariable(arg: 1, scope: !174, type: !6)
// CHECK:STDOUT: !176 = !DILocation(line: 11, column: 12, scope: !174)
// CHECK:STDOUT: !177 = !{!175}
// CHECK:STDOUT: !178 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.78fd6ee82eacbbc3:core.Destroy.Core", scope: null, file: !142, line: 11, type: !8, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !181)
// CHECK:STDOUT: !179 = !DILocalVariable(arg: 1, scope: !178, type: !6)
// CHECK:STDOUT: !180 = !DILocation(line: 11, column: 12, scope: !178)
// CHECK:STDOUT: !181 = !{!179}
// CHECK:STDOUT: !182 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.7d29ea9e6f62bf96", scope: null, file: !48, line: 130, type: !63, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !189)
// CHECK:STDOUT: !183 = !DILocalVariable(arg: 1, scope: !182, type: !6)
// CHECK:STDOUT: !187 = !DILocation(line: 131, column: 12, scope: !182)
// CHECK:STDOUT: !188 = !DILocation(line: 131, column: 5, scope: !182)
// CHECK:STDOUT: !189 = !{!183}
// CHECK:STDOUT: !190 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Optional.c661605f12aa337a.Core:OptionalAs.1dac4564233fecd1.Core.c5881e9a6965c8a5", scope: null, file: !48, line: 120, type: !63, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !202)
// CHECK:STDOUT: !191 = !DILocalVariable(arg: 1, scope: !190, type: !6)
// CHECK:STDOUT: !195 = !DILocation(line: 121, column: 9, scope: !190)
// CHECK:STDOUT: !196 = !DILocation(line: 121, column: 8, scope: !190)
// CHECK:STDOUT: !197 = !DILocation(line: 122, column: 31, scope: !190)
// CHECK:STDOUT: !198 = !DILocation(line: 122, column: 14, scope: !190)
// CHECK:STDOUT: !199 = !DILocation(line: 122, column: 7, scope: !190)
// CHECK:STDOUT: !200 = !DILocation(line: 124, column: 12, scope: !190)
// CHECK:STDOUT: !201 = !DILocation(line: 124, column: 5, scope: !190)
// CHECK:STDOUT: !202 = !{!191}
// CHECK:STDOUT: !203 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.0c3518913b4fb338", scope: null, file: !48, line: 37, type: !63, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !211)
// CHECK:STDOUT: !204 = !DILocalVariable(arg: 1, scope: !203, type: !6)
// CHECK:STDOUT: !209 = !DILocation(line: 38, column: 12, scope: !203)
// CHECK:STDOUT: !210 = !DILocation(line: 38, column: 5, scope: !203)
// CHECK:STDOUT: !211 = !{!204}
// CHECK:STDOUT: !212 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.0c3518913b4fb338", scope: null, file: !48, line: 40, type: !63, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !220)
// CHECK:STDOUT: !213 = !DILocalVariable(arg: 1, scope: !212, type: !6)
// CHECK:STDOUT: !218 = !DILocation(line: 41, column: 12, scope: !212)
// CHECK:STDOUT: !219 = !DILocation(line: 41, column: 5, scope: !212)
// CHECK:STDOUT: !220 = !{!213}
// CHECK:STDOUT: !221 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.305e266058820aa4", scope: null, file: !48, line: 34, type: !63, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !228)
// CHECK:STDOUT: !222 = !DILocalVariable(arg: 1, scope: !221, type: !6)
// CHECK:STDOUT: !226 = !DILocation(line: 35, column: 12, scope: !221)
// CHECK:STDOUT: !227 = !DILocation(line: 35, column: 5, scope: !221)
// CHECK:STDOUT: !228 = !{!222}
// CHECK:STDOUT: !229 = distinct !DISubprogram(name: "None", linkageName: "_CNone.Optional.Core.305e266058820aa4", scope: null, file: !48, line: 31, type: !10, spFlags: DISPFlagDefinition, unit: !143)
// CHECK:STDOUT: !233 = !DILocation(line: 32, column: 5, scope: !229)
// CHECK:STDOUT: !234 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4", scope: null, file: !48, line: 197, type: !63, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !243)
// CHECK:STDOUT: !235 = !DILocalVariable(arg: 1, scope: !234, type: !6)
// CHECK:STDOUT: !240 = !DILocation(line: 198, column: 16, scope: !234)
// CHECK:STDOUT: !241 = !DILocation(line: 198, column: 12, scope: !234)
// CHECK:STDOUT: !242 = !DILocation(line: 198, column: 5, scope: !234)
// CHECK:STDOUT: !243 = !{!235}
// CHECK:STDOUT: !244 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4", scope: null, file: !48, line: 200, type: !63, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !251)
// CHECK:STDOUT: !245 = !DILocalVariable(arg: 1, scope: !244, type: !6)
// CHECK:STDOUT: !250 = !DILocation(line: 201, column: 5, scope: !244)
// CHECK:STDOUT: !251 = !{!245}
// CHECK:STDOUT: !252 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.e8f8f92d3d08d149:OptionalStorage.Core.35c29317da7de352", scope: null, file: !48, line: 191, type: !63, spFlags: DISPFlagDefinition, unit: !143, retainedNodes: !264)
// CHECK:STDOUT: !253 = !DILocalVariable(arg: 1, scope: !252, type: !6)
// CHECK:STDOUT: !257 = !DILocation(line: 192, column: 14, scope: !252)
// CHECK:STDOUT: !259 = !DILocation(line: 192, column: 18, scope: !252)
// CHECK:STDOUT: !261 = !DILocation(line: 194, column: 5, scope: !252)
// CHECK:STDOUT: !263 = !DILocation(line: 195, column: 5, scope: !252)
// CHECK:STDOUT: !264 = !{!253}
// CHECK:STDOUT: !265 = !{!"p1 _ZTS6ConstC", !37, i64 0}
// CHECK:STDOUT: !266 = !{!265, !265, i64 0}
// CHECK:STDOUT:
