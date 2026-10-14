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
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
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
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6789a803c53632c0:core.Destroy.Core"(ptr %self) #0 !dbg !53 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5cf0c9a25f98a429:core.Destroy.Core"(ptr %self) #0 !dbg !57 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !59
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassPtr.Main(ptr %_) #0 !dbg !61 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !64
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CPassNonnullPtr.Main(ptr %p) #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc22_23.2.temp = alloca ptr, align 8, !dbg !69
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.75a9143bcbb84fa5"(ptr %p), !dbg !69
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc22_23.2.temp), !dbg !69
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc22_23.2.temp, align 8, !dbg !69
// CHECK:STDOUT:   %.loc22_23.4 = load ptr, ptr %.loc22_23.2.temp, align 8, !dbg !69
// CHECK:STDOUT:   call void @_Z15TakeNullablePtrP9NullableC.carbon_thunk._(ptr %.loc22_23.4), !dbg !72
// CHECK:STDOUT:   call void @"_CSelfDestruct.574ea10b2e6709a0:core.Destroy.Core"(ptr %.loc22_23.2.temp), !dbg !69
// CHECK:STDOUT:   ret void, !dbg !73
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z15TakeNullablePtrP9NullableC.carbon_thunk._(ptr noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !143
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !143
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
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !143
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !143
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
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.75a9143bcbb84fa5"(ptr %self) #0 !dbg !104 {
// CHECK:STDOUT:   %1 = call ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.e83c25d1d2fd22c2"(ptr %self), !dbg !109
// CHECK:STDOUT:   ret ptr %1, !dbg !110
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.e83c25d1d2fd22c2"(ptr %self) #0 !dbg !112 {
// CHECK:STDOUT:   %1 = call ptr @_CSome.Optional.Core.e83c25d1d2fd22c2(ptr %self), !dbg !118
// CHECK:STDOUT:   ret ptr %1, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CSome.Optional.Core.e83c25d1d2fd22c2(ptr %value) #0 !dbg !121 {
// CHECK:STDOUT:   %1 = call ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.77dd513e5db6ef8d"(ptr %value), !dbg !126
// CHECK:STDOUT:   ret ptr %1, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.77dd513e5db6ef8d"(ptr %self) #0 !dbg !129 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !134
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !134
// CHECK:STDOUT:   store ptr poison, ptr %1, align 8, !dbg !134
// CHECK:STDOUT:   store ptr %self, ptr %1, align 8, !dbg !138
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8, !dbg !136
// CHECK:STDOUT:   call void @"_CSelfDestruct.5cf0c9a25f98a429:core.Destroy.Core"(ptr %1), !dbg !134
// CHECK:STDOUT:   ret ptr %2, !dbg !140
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
// CHECK:STDOUT: !53 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6789a803c53632c0:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !56)
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !53, type: !6)
// CHECK:STDOUT: !55 = !DILocation(line: 189, column: 19, scope: !53)
// CHECK:STDOUT: !56 = !{!54}
// CHECK:STDOUT: !57 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5cf0c9a25f98a429:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !60)
// CHECK:STDOUT: !58 = !DILocalVariable(arg: 1, scope: !57, type: !6)
// CHECK:STDOUT: !59 = !DILocation(line: 189, column: 19, scope: !57)
// CHECK:STDOUT: !60 = !{!58}
// CHECK:STDOUT: !61 = distinct !DISubprogram(name: "PassPtr", linkageName: "_CPassPtr.Main", scope: null, file: !46, line: 14, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !65)
// CHECK:STDOUT: !62 = !DILocalVariable(arg: 1, scope: !61, type: !6)
// CHECK:STDOUT: !64 = !DILocation(line: 14, column: 1, scope: !61)
// CHECK:STDOUT: !65 = !{!62}
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "PassNonnullPtr", linkageName: "_CPassNonnullPtr.Main", scope: null, file: !46, line: 19, type: !8, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !74)
// CHECK:STDOUT: !67 = !DILocalVariable(arg: 1, scope: !66, type: !6)
// CHECK:STDOUT: !69 = !DILocation(line: 22, column: 23, scope: !66)
// CHECK:STDOUT: !70 = !{!6, !6}
// CHECK:STDOUT: !71 = !DISubroutineType(types: !70)
// CHECK:STDOUT: !72 = !DILocation(line: 22, column: 3, scope: !66)
// CHECK:STDOUT: !73 = !DILocation(line: 19, column: 1, scope: !66)
// CHECK:STDOUT: !74 = !{!67}
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
// CHECK:STDOUT: !104 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.75a9143bcbb84fa5", scope: null, file: !48, line: 130, type: !71, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !111)
// CHECK:STDOUT: !105 = !DILocalVariable(arg: 1, scope: !104, type: !6)
// CHECK:STDOUT: !109 = !DILocation(line: 131, column: 12, scope: !104)
// CHECK:STDOUT: !110 = !DILocation(line: 131, column: 5, scope: !104)
// CHECK:STDOUT: !111 = !{!105}
// CHECK:STDOUT: !112 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.e83c25d1d2fd22c2", scope: null, file: !48, line: 105, type: !71, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !120)
// CHECK:STDOUT: !113 = !DILocalVariable(arg: 1, scope: !112, type: !6)
// CHECK:STDOUT: !118 = !DILocation(line: 106, column: 12, scope: !112)
// CHECK:STDOUT: !119 = !DILocation(line: 106, column: 5, scope: !112)
// CHECK:STDOUT: !120 = !{!113}
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.e83c25d1d2fd22c2", scope: null, file: !48, line: 34, type: !71, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !128)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !121, type: !6)
// CHECK:STDOUT: !126 = !DILocation(line: 35, column: 12, scope: !121)
// CHECK:STDOUT: !127 = !DILocation(line: 35, column: 5, scope: !121)
// CHECK:STDOUT: !128 = !{!122}
// CHECK:STDOUT: !129 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.e8f8f92d3d08d149:OptionalStorage.Core.77dd513e5db6ef8d", scope: null, file: !48, line: 191, type: !71, spFlags: DISPFlagDefinition, unit: !47, retainedNodes: !141)
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 1, scope: !129, type: !6)
// CHECK:STDOUT: !134 = !DILocation(line: 192, column: 14, scope: !129)
// CHECK:STDOUT: !136 = !DILocation(line: 192, column: 18, scope: !129)
// CHECK:STDOUT: !138 = !DILocation(line: 194, column: 5, scope: !129)
// CHECK:STDOUT: !140 = !DILocation(line: 195, column: 5, scope: !129)
// CHECK:STDOUT: !141 = !{!130}
// CHECK:STDOUT: !142 = !{!"p1 _ZTS9NullableC", !37, i64 0}
// CHECK:STDOUT: !143 = !{!142, !142, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'add_const.carbon'
// CHECK:STDOUT: source_filename = "add_const.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 57 }
// CHECK:STDOUT: @.str = private unnamed_addr constant [71 x i8] c"carbon: C++ exception escaped into Carbon through `make`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [71 x i8] c"carbon: C++ exception escaped into Carbon through `take`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CConvert.Main() #0 !dbg !148 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc11_21.1.temp = alloca ptr, align 8, !dbg !149
// CHECK:STDOUT:   %.loc11_21.5.temp = alloca ptr, align 8, !dbg !149
// CHECK:STDOUT:   %make__carbon_thunk.call = call ptr @_Z4makev.carbon_thunk.(), !dbg !149
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc11_21.1.temp), !dbg !149
// CHECK:STDOUT:   store ptr %make__carbon_thunk.call, ptr %.loc11_21.1.temp, align 8, !dbg !149
// CHECK:STDOUT:   %.loc11_21.3 = load ptr, ptr %.loc11_21.1.temp, align 8, !dbg !149
// CHECK:STDOUT:   %U.as_type.as.ImplicitAs.impl.Convert.call = call ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.7d29ea9e6f62bf96"(ptr %.loc11_21.3), !dbg !149
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc11_21.5.temp), !dbg !149
// CHECK:STDOUT:   store ptr %U.as_type.as.ImplicitAs.impl.Convert.call, ptr %.loc11_21.5.temp, align 8, !dbg !149
// CHECK:STDOUT:   %.loc11_21.7 = load ptr, ptr %.loc11_21.5.temp, align 8, !dbg !149
// CHECK:STDOUT:   call void @_Z4takePK6ConstC.carbon_thunk._(ptr %.loc11_21.7), !dbg !150
// CHECK:STDOUT:   call void @"_CSelfDestruct.19661d0961df889d:core.Destroy.Core"(ptr %.loc11_21.5.temp), !dbg !149
// CHECK:STDOUT:   call void @"_CSelfDestruct.78fd6ee82eacbbc3:core.Destroy.Core"(ptr %.loc11_21.1.temp), !dbg !149
// CHECK:STDOUT:   ret void, !dbg !151
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.23bb4d554c74e0f1:core.Destroy.Core"(ptr %self) #0 !dbg !152 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !154
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.e3602e7640dfb844:core.Destroy.Core"(ptr %self) #0 !dbg !156 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !158
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bc918cd0012c1190:core.Destroy.Core"(ptr %self) #0 !dbg !160 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !162
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
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #3
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
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.131ece8d9a7a4272:core.Destroy.Core"(ptr %self) #0 !dbg !164 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !166
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bdb5ffe218b7af7d:core.Destroy.Core"(ptr %self) #0 !dbg !168 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !170
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f914f15dcbbdbae9:core.Destroy.Core"(ptr %self) #0 !dbg !172 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !174
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z4takePK6ConstC.carbon_thunk._(ptr noundef %0) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %0, ptr %.addr, align 8, !tbaa !273
// CHECK:STDOUT:   %1 = load ptr, ptr %.addr, align 8, !tbaa !273
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
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #3
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
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.19661d0961df889d:core.Destroy.Core"(ptr %self) #0 !dbg !176 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !178
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.78fd6ee82eacbbc3:core.Destroy.Core"(ptr %self) #0 !dbg !180 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !182
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.7d29ea9e6f62bf96"(ptr %self) #0 !dbg !184 {
// CHECK:STDOUT:   %1 = call ptr @"_CConvert.Optional.c661605f12aa337a.Core:OptionalAs.1dac4564233fecd1.Core.c5881e9a6965c8a5"(ptr %self), !dbg !189
// CHECK:STDOUT:   ret ptr %1, !dbg !190
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CConvert.Optional.c661605f12aa337a.Core:OptionalAs.1dac4564233fecd1.Core.c5881e9a6965c8a5"(ptr %self) #0 !dbg !192 {
// CHECK:STDOUT:   %temp = alloca ptr, align 8, !dbg !199
// CHECK:STDOUT:   %temp1 = alloca ptr, align 8, !dbg !199
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.0c3518913b4fb338(ptr %self), !dbg !197
// CHECK:STDOUT:   br i1 %1, label %2, label %7, !dbg !198
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !199
// CHECK:STDOUT:   %3 = call ptr @_CGet.Optional.Core.0c3518913b4fb338(ptr %self), !dbg !199
// CHECK:STDOUT:   store ptr %3, ptr %temp, align 8, !dbg !199
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp1), !dbg !199
// CHECK:STDOUT:   %4 = load ptr, ptr %temp, align 8, !dbg !199
// CHECK:STDOUT:   store ptr %4, ptr %temp1, align 8, !dbg !199
// CHECK:STDOUT:   %5 = load ptr, ptr %temp1, align 8, !dbg !199
// CHECK:STDOUT:   %6 = call ptr @_CSome.Optional.Core.305e266058820aa4(ptr %5), !dbg !200
// CHECK:STDOUT:   call void @"_CSelfDestruct.131ece8d9a7a4272:core.Destroy.Core"(ptr %temp1), !dbg !199
// CHECK:STDOUT:   call void @"_CSelfDestruct.23bb4d554c74e0f1:core.Destroy.Core"(ptr %temp), !dbg !199
// CHECK:STDOUT:   ret ptr %6, !dbg !201
// CHECK:STDOUT:
// CHECK:STDOUT: 7:                                                ; preds = %0
// CHECK:STDOUT:   %8 = call ptr @_CNone.Optional.Core.305e266058820aa4(), !dbg !202
// CHECK:STDOUT:   ret ptr %8, !dbg !203
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.0c3518913b4fb338(ptr %self) #0 !dbg !205 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4"(ptr %self), !dbg !211
// CHECK:STDOUT:   ret i1 %1, !dbg !212
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CGet.Optional.Core.0c3518913b4fb338(ptr %self) #0 !dbg !214 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.0c3518913b4fb338(ptr %self), !dbg !219
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !220
// CHECK:STDOUT:   br i1 %2, label %3, label %5, !dbg !221
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !222
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !222
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !222
// CHECK:STDOUT:   %4 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !222
// CHECK:STDOUT:   call void @abort(), !dbg !222
// CHECK:STDOUT:   br label %5, !dbg !223
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3, %0
// CHECK:STDOUT:   %6 = call ptr @"_CGet.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4"(ptr %self), !dbg !225
// CHECK:STDOUT:   ret ptr %6, !dbg !226
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CSome.Optional.Core.305e266058820aa4(ptr %value) #0 !dbg !228 {
// CHECK:STDOUT:   %1 = call ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.35c29317da7de352"(ptr %value), !dbg !233
// CHECK:STDOUT:   ret ptr %1, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CNone.Optional.Core.305e266058820aa4() #0 !dbg !236 {
// CHECK:STDOUT:   ret ptr null, !dbg !240
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4"(ptr %value) #0 !dbg !241 {
// CHECK:STDOUT:   %1 = icmp eq ptr %value, null, !dbg !247
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !248
// CHECK:STDOUT:   ret i1 %2, !dbg !249
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CGet.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4"(ptr %value) #0 !dbg !251 {
// CHECK:STDOUT:   ret ptr %value, !dbg !257
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CSome.e8f8f92d3d08d149:OptionalStorage.Core.35c29317da7de352"(ptr %self) #0 !dbg !259 {
// CHECK:STDOUT:   %1 = alloca ptr, align 8, !dbg !264
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %1), !dbg !264
// CHECK:STDOUT:   store ptr poison, ptr %1, align 8, !dbg !264
// CHECK:STDOUT:   store ptr %self, ptr %1, align 8, !dbg !268
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8, !dbg !266
// CHECK:STDOUT:   call void @"_CSelfDestruct.f914f15dcbbdbae9:core.Destroy.Core"(ptr %1), !dbg !264
// CHECK:STDOUT:   ret ptr %2, !dbg !270
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare noundef ptr @_Z4makev() #4
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #0
// CHECK:STDOUT:   call void @_ZSt9terminatev() #6
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z4takePK6ConstC(ptr noundef) #4
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 1, 2, 4, 3 }
// CHECK:STDOUT: uselistorder ptr @write, { 1, 0, 2 }
// CHECK:STDOUT: uselistorder ptr @__gxx_personality_v0, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_begin_catch, { 1, 2, 0 }
// CHECK:STDOUT: uselistorder ptr @__cxa_rethrow, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @__clang_call_terminate, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { noreturn }
// CHECK:STDOUT: attributes #4 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!145}
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
// CHECK:STDOUT: !70 = !{!6, !6}
// CHECK:STDOUT: !71 = !DISubroutineType(types: !70)
// CHECK:STDOUT: !144 = !DIFile(filename: "add_const.carbon", directory: "")
// CHECK:STDOUT: !145 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !144, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !146 = !{null}
// CHECK:STDOUT: !147 = !DISubroutineType(types: !146)
// CHECK:STDOUT: !148 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Main", scope: null, file: !144, line: 10, type: !147, spFlags: DISPFlagDefinition, unit: !145)
// CHECK:STDOUT: !149 = !DILocation(line: 11, column: 12, scope: !148)
// CHECK:STDOUT: !150 = !DILocation(line: 11, column: 3, scope: !148)
// CHECK:STDOUT: !151 = !DILocation(line: 10, column: 1, scope: !148)
// CHECK:STDOUT: !152 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.23bb4d554c74e0f1:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !155)
// CHECK:STDOUT: !153 = !DILocalVariable(arg: 1, scope: !152, type: !6)
// CHECK:STDOUT: !154 = !DILocation(line: 189, column: 19, scope: !152)
// CHECK:STDOUT: !155 = !{!153}
// CHECK:STDOUT: !156 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.e3602e7640dfb844:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !159)
// CHECK:STDOUT: !157 = !DILocalVariable(arg: 1, scope: !156, type: !6)
// CHECK:STDOUT: !158 = !DILocation(line: 189, column: 19, scope: !156)
// CHECK:STDOUT: !159 = !{!157}
// CHECK:STDOUT: !160 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bc918cd0012c1190:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !163)
// CHECK:STDOUT: !161 = !DILocalVariable(arg: 1, scope: !160, type: !6)
// CHECK:STDOUT: !162 = !DILocation(line: 189, column: 19, scope: !160)
// CHECK:STDOUT: !163 = !{!161}
// CHECK:STDOUT: !164 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.131ece8d9a7a4272:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !167)
// CHECK:STDOUT: !165 = !DILocalVariable(arg: 1, scope: !164, type: !6)
// CHECK:STDOUT: !166 = !DILocation(line: 189, column: 19, scope: !164)
// CHECK:STDOUT: !167 = !{!165}
// CHECK:STDOUT: !168 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bdb5ffe218b7af7d:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !171)
// CHECK:STDOUT: !169 = !DILocalVariable(arg: 1, scope: !168, type: !6)
// CHECK:STDOUT: !170 = !DILocation(line: 189, column: 19, scope: !168)
// CHECK:STDOUT: !171 = !{!169}
// CHECK:STDOUT: !172 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f914f15dcbbdbae9:core.Destroy.Core", scope: null, file: !48, line: 189, type: !8, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !175)
// CHECK:STDOUT: !173 = !DILocalVariable(arg: 1, scope: !172, type: !6)
// CHECK:STDOUT: !174 = !DILocation(line: 189, column: 19, scope: !172)
// CHECK:STDOUT: !175 = !{!173}
// CHECK:STDOUT: !176 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.19661d0961df889d:core.Destroy.Core", scope: null, file: !144, line: 11, type: !8, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !179)
// CHECK:STDOUT: !177 = !DILocalVariable(arg: 1, scope: !176, type: !6)
// CHECK:STDOUT: !178 = !DILocation(line: 11, column: 12, scope: !176)
// CHECK:STDOUT: !179 = !{!177}
// CHECK:STDOUT: !180 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.78fd6ee82eacbbc3:core.Destroy.Core", scope: null, file: !144, line: 11, type: !8, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !183)
// CHECK:STDOUT: !181 = !DILocalVariable(arg: 1, scope: !180, type: !6)
// CHECK:STDOUT: !182 = !DILocation(line: 11, column: 12, scope: !180)
// CHECK:STDOUT: !183 = !{!181}
// CHECK:STDOUT: !184 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.7d29ea9e6f62bf96", scope: null, file: !48, line: 130, type: !71, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !191)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 1, scope: !184, type: !6)
// CHECK:STDOUT: !189 = !DILocation(line: 131, column: 12, scope: !184)
// CHECK:STDOUT: !190 = !DILocation(line: 131, column: 5, scope: !184)
// CHECK:STDOUT: !191 = !{!185}
// CHECK:STDOUT: !192 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Optional.c661605f12aa337a.Core:OptionalAs.1dac4564233fecd1.Core.c5881e9a6965c8a5", scope: null, file: !48, line: 120, type: !71, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !204)
// CHECK:STDOUT: !193 = !DILocalVariable(arg: 1, scope: !192, type: !6)
// CHECK:STDOUT: !197 = !DILocation(line: 121, column: 9, scope: !192)
// CHECK:STDOUT: !198 = !DILocation(line: 121, column: 8, scope: !192)
// CHECK:STDOUT: !199 = !DILocation(line: 122, column: 31, scope: !192)
// CHECK:STDOUT: !200 = !DILocation(line: 122, column: 14, scope: !192)
// CHECK:STDOUT: !201 = !DILocation(line: 122, column: 7, scope: !192)
// CHECK:STDOUT: !202 = !DILocation(line: 124, column: 12, scope: !192)
// CHECK:STDOUT: !203 = !DILocation(line: 124, column: 5, scope: !192)
// CHECK:STDOUT: !204 = !{!193}
// CHECK:STDOUT: !205 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.0c3518913b4fb338", scope: null, file: !48, line: 37, type: !71, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !213)
// CHECK:STDOUT: !206 = !DILocalVariable(arg: 1, scope: !205, type: !6)
// CHECK:STDOUT: !211 = !DILocation(line: 38, column: 12, scope: !205)
// CHECK:STDOUT: !212 = !DILocation(line: 38, column: 5, scope: !205)
// CHECK:STDOUT: !213 = !{!206}
// CHECK:STDOUT: !214 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.0c3518913b4fb338", scope: null, file: !48, line: 40, type: !71, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !227)
// CHECK:STDOUT: !215 = !DILocalVariable(arg: 1, scope: !214, type: !6)
// CHECK:STDOUT: !219 = !DILocation(line: 303, column: 11, scope: !214)
// CHECK:STDOUT: !220 = !DILocation(line: 303, column: 7, scope: !214)
// CHECK:STDOUT: !221 = !DILocation(line: 303, column: 6, scope: !214)
// CHECK:STDOUT: !222 = !DILocation(line: 304, column: 5, scope: !214)
// CHECK:STDOUT: !223 = !DILocation(line: 303, column: 3, scope: !214)
// CHECK:STDOUT: !225 = !DILocation(line: 306, column: 10, scope: !214)
// CHECK:STDOUT: !226 = !DILocation(line: 306, column: 3, scope: !214)
// CHECK:STDOUT: !227 = !{!215}
// CHECK:STDOUT: !228 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.305e266058820aa4", scope: null, file: !48, line: 34, type: !71, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !235)
// CHECK:STDOUT: !229 = !DILocalVariable(arg: 1, scope: !228, type: !6)
// CHECK:STDOUT: !233 = !DILocation(line: 35, column: 12, scope: !228)
// CHECK:STDOUT: !234 = !DILocation(line: 35, column: 5, scope: !228)
// CHECK:STDOUT: !235 = !{!229}
// CHECK:STDOUT: !236 = distinct !DISubprogram(name: "None", linkageName: "_CNone.Optional.Core.305e266058820aa4", scope: null, file: !48, line: 31, type: !10, spFlags: DISPFlagDefinition, unit: !145)
// CHECK:STDOUT: !240 = !DILocation(line: 32, column: 5, scope: !236)
// CHECK:STDOUT: !241 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4", scope: null, file: !48, line: 197, type: !71, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !250)
// CHECK:STDOUT: !242 = !DILocalVariable(arg: 1, scope: !241, type: !6)
// CHECK:STDOUT: !247 = !DILocation(line: 198, column: 16, scope: !241)
// CHECK:STDOUT: !248 = !DILocation(line: 198, column: 12, scope: !241)
// CHECK:STDOUT: !249 = !DILocation(line: 198, column: 5, scope: !241)
// CHECK:STDOUT: !250 = !{!242}
// CHECK:STDOUT: !251 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.e8f8f92d3d08d149:OptionalStorage.Core.21c65d90918a10a4", scope: null, file: !48, line: 200, type: !71, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !258)
// CHECK:STDOUT: !252 = !DILocalVariable(arg: 1, scope: !251, type: !6)
// CHECK:STDOUT: !257 = !DILocation(line: 201, column: 5, scope: !251)
// CHECK:STDOUT: !258 = !{!252}
// CHECK:STDOUT: !259 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.e8f8f92d3d08d149:OptionalStorage.Core.35c29317da7de352", scope: null, file: !48, line: 191, type: !71, spFlags: DISPFlagDefinition, unit: !145, retainedNodes: !271)
// CHECK:STDOUT: !260 = !DILocalVariable(arg: 1, scope: !259, type: !6)
// CHECK:STDOUT: !264 = !DILocation(line: 192, column: 14, scope: !259)
// CHECK:STDOUT: !266 = !DILocation(line: 192, column: 18, scope: !259)
// CHECK:STDOUT: !268 = !DILocation(line: 194, column: 5, scope: !259)
// CHECK:STDOUT: !270 = !DILocation(line: 195, column: 5, scope: !259)
// CHECK:STDOUT: !271 = !{!260}
// CHECK:STDOUT: !272 = !{!"p1 _ZTS6ConstC", !37, i64 0}
// CHECK:STDOUT: !273 = !{!272, !272, i64 0}
// CHECK:STDOUT:
