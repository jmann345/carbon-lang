// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/int.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/globals.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/globals.carbon

// ============================================================================
// Global variables
// ============================================================================

// --- global.h

class C {};
C global;

// --- import_global.carbon

library "[[@TEST_NAME]]";

import Cpp library "global.h";

fn MyF() {
  let _: Cpp.C = Cpp.global;
}

// ============================================================================
// Inline variable
// ============================================================================

// --- inline.h

struct InlineC {
  InlineC();
  ~InlineC();
  void f();
};
inline InlineC inline_global;

// --- import_inline.carbon

library "[[@TEST_NAME]]";

import Cpp library "inline.h";

fn CallF() {
  Cpp.inline_global.f();
}

// ============================================================================
// Thread-local variable
// ============================================================================

// --- thread_local.h

thread_local int thread_local_global;

int init();
thread_local int thread_local_global_with_init = init();

// --- todo_import_thread_local.carbon

library "[[@TEST_NAME]]";

import Cpp library "thread_local.h";

// TODO: We should call the C++ thread wrapper function here instead of directly
// accessing the global. We fail to trigger the initialization of the global.

fn ThreadLocalStore() {
  Cpp.thread_local_global = 42;
}

fn ThreadLocalTriggerInit() -> i32 {
  return Cpp.thread_local_global_with_init;
}

// ============================================================================
// Static data members
// ============================================================================

// --- static.h

struct X {
  static inline int n = 42;
};

// --- import_static.carbon

library "[[@TEST_NAME]]";

import Cpp library "static.h";

fn ReadStatic() -> i32 {
  return Cpp.X.n;
}

// ============================================================================
// Variable templates
// ============================================================================

// --- var_template.h

template<typename T> T tmpl = T();

struct Y {
  Y();
};

// --- import_var_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "var_template.h";

fn ReadVarTemplate() -> i32 {
  return Cpp.tmpl(i32);
}

fn ReadVarTemplateWithConstructor() -> Cpp.Y* {
  return &Cpp.tmpl(Cpp.Y);
}

// ============================================================================
// Static data member templates
// ============================================================================

// --- static_template.h

struct StaticTmplX {
  template<typename T> static inline T static_tmpl = T();
};

struct Y {
  Y();
};

// --- import_static_template.carbon

library "[[@TEST_NAME]]";

import Cpp library "static_template.h";

fn ReadStaticVarTemplate() -> i32 {
  return Cpp.StaticTmplX.static_tmpl(i32);
}

fn ReadStaticVarTemplateWithConstructor() -> Cpp.Y* {
  return &Cpp.StaticTmplX.static_tmpl(Cpp.Y);
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_global.carbon'
// CHECK:STDOUT: source_filename = "import_global.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %class.C = type { i8 }
// CHECK:STDOUT:
// CHECK:STDOUT: @global = dso_local global %class.C zeroinitializer, align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CMyF.Main() #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!25}
// CHECK:STDOUT: !llvm.module.flags = !{!33, !34, !35, !8, !9}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!37}
// CHECK:STDOUT:
// CHECK:STDOUT: !1 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !2 = !{!"omnipotent char", !1, i64 0}
// CHECK:STDOUT: !3 = !{!"int", !2, i64 0}
// CHECK:STDOUT: !8 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !9 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !24 = !DIFile(filename: "import_global.carbon", directory: "")
// CHECK:STDOUT: !25 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !24, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !26 = !{null}
// CHECK:STDOUT: !27 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "MyF", linkageName: "_CMyF.Main", scope: null, file: !24, line: 6, type: !27, spFlags: DISPFlagDefinition, unit: !25)
// CHECK:STDOUT: !32 = !DILocation(line: 6, column: 1, scope: !28)
// CHECK:STDOUT: !33 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !34 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !35 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !36 = !{!"__libc_errno", !3, i64 0}
// CHECK:STDOUT: !37 = !{!36, !3, i64 0}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_inline.carbon'
// CHECK:STDOUT: source_filename = "import_inline.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.InlineC = type { i8 }
// CHECK:STDOUT:
// CHECK:STDOUT: $inline_global = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @inline_global = linkonce_odr dso_local global %struct.InlineC zeroinitializer, comdat, align 1
// CHECK:STDOUT: @_ZGV13inline_global = linkonce_odr dso_local global i64 0, comdat($inline_global), align 8
// CHECK:STDOUT: @__dso_handle = external hidden global i8
// CHECK:STDOUT: @.str = private unnamed_addr constant [77 x i8] c"carbon: C++ exception escaped into Carbon through `InlineC::f`; terminating\0A\00", align 1
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cxx_global_var_init, ptr @inline_global }]
// CHECK:STDOUT: @llvm.used = appending global [1 x ptr] [ptr @inline_global], section "llvm.metadata"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: uwtable
// CHECK:STDOUT: define internal void @__cxx_global_var_init() #0 section ".text.startup" comdat($inline_global) personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   %0 = load atomic i8, ptr @_ZGV13inline_global acquire, align 8
// CHECK:STDOUT:   %guard.uninitialized = icmp eq i8 %0, 0
// CHECK:STDOUT:   br i1 %guard.uninitialized, label %init.check, label %init.end
// CHECK:STDOUT:
// CHECK:STDOUT: init.check:                                       ; preds = %entry
// CHECK:STDOUT:   %1 = call i32 @__cxa_guard_acquire(ptr @_ZGV13inline_global) #1
// CHECK:STDOUT:   %tobool = icmp ne i32 %1, 0
// CHECK:STDOUT:   br i1 %tobool, label %init, label %init.end
// CHECK:STDOUT:
// CHECK:STDOUT: init:                                             ; preds = %init.check
// CHECK:STDOUT:   invoke void @_ZN7InlineCC1Ev(ptr noundef nonnull align 1 dereferenceable(1) @inline_global)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %init
// CHECK:STDOUT:   %2 = call i32 @__cxa_atexit(ptr @_ZN7InlineCD1Ev, ptr @inline_global, ptr @__dso_handle) #1
// CHECK:STDOUT:   call void @__cxa_guard_release(ptr @_ZGV13inline_global) #1
// CHECK:STDOUT:   br label %init.end
// CHECK:STDOUT:
// CHECK:STDOUT: init.end:                                         ; preds = %invoke.cont, %init.check, %entry
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %init
// CHECK:STDOUT:   %3 = landingpad { ptr, i32 }
// CHECK:STDOUT:           cleanup
// CHECK:STDOUT:   %4 = extractvalue { ptr, i32 } %3, 0
// CHECK:STDOUT:   store ptr %4, ptr %exn.slot, align 8
// CHECK:STDOUT:   %5 = extractvalue { ptr, i32 } %3, 1
// CHECK:STDOUT:   store i32 %5, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   call void @__cxa_guard_abort(ptr @_ZGV13inline_global) #1
// CHECK:STDOUT:   br label %eh.resume
// CHECK:STDOUT:
// CHECK:STDOUT: eh.resume:                                        ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %sel = load i32, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   %lpad.val = insertvalue { ptr, i32 } poison, ptr %exn, 0
// CHECK:STDOUT:   %lpad.val1 = insertvalue { ptr, i32 } %lpad.val, i32 %sel, 1
// CHECK:STDOUT:   resume { ptr, i32 } %lpad.val1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare i32 @__cxa_guard_acquire(ptr) #1
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN7InlineCC1Ev(ptr noundef nonnull align 1 dereferenceable(1)) unnamed_addr #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare i32 @__gxx_personality_v0(...)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare void @_ZN7InlineCD1Ev(ptr noundef nonnull align 1 dereferenceable(1)) unnamed_addr #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare i32 @__cxa_atexit(ptr, ptr, ptr) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare void @__cxa_guard_abort(ptr) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare void @__cxa_guard_release(ptr) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CCallF.Main() #1 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_ZN7InlineC1fEv.carbon_thunk.r(ptr @inline_global), !dbg !44
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_ZN7InlineC1fEv.carbon_thunk.r(ptr noundef nonnull align 1 dereferenceable(1) %this) #4 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %this.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %this, ptr %this.addr, align 8, !tbaa !48
// CHECK:STDOUT:   %0 = load ptr, ptr %this.addr, align 8, !tbaa !48, !nonnull !49
// CHECK:STDOUT:   invoke void @_ZN7InlineC1fEv(ptr noundef nonnull align 1 dereferenceable(1) %0)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
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
// CHECK:STDOUT:   %4 = call ptr @__cxa_begin_catch(ptr %exn) #1
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 76) #1
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %6) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN7InlineC1fEv(ptr noundef nonnull align 1 dereferenceable(1)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: declare ptr @__cxa_begin_catch(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: declare noundef i64 @write(i32 noundef, ptr noundef, i64 noundef) #3
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @__cxa_rethrow()
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noinline noreturn nounwind uwtable
// CHECK:STDOUT: define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #5 comdat {
// CHECK:STDOUT:   %2 = call ptr @__cxa_begin_catch(ptr %0) #1
// CHECK:STDOUT:   call void @_ZSt9terminatev() #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZSt9terminatev()
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @inline_global, { 2, 3, 4, 0, 1 }
// CHECK:STDOUT: uselistorder ptr @_ZGV13inline_global, { 1, 0, 2, 3 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { nounwind }
// CHECK:STDOUT: attributes #2 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #3 = { nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #4 = { alwaysinline mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #5 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #6 = { noreturn }
// CHECK:STDOUT: attributes #7 = { noreturn nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!39}
// CHECK:STDOUT: !llvm.module.flags = !{!33, !34, !35, !8, !9}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!37}
// CHECK:STDOUT:
// CHECK:STDOUT: !1 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !2 = !{!"omnipotent char", !1, i64 0}
// CHECK:STDOUT: !3 = !{!"int", !2, i64 0}
// CHECK:STDOUT: !8 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !9 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !26 = !{null}
// CHECK:STDOUT: !27 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !33 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !34 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !35 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !36 = !{!"__libc_errno", !3, i64 0}
// CHECK:STDOUT: !37 = !{!36, !3, i64 0}
// CHECK:STDOUT: !38 = !DIFile(filename: "import_inline.carbon", directory: "")
// CHECK:STDOUT: !39 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !38, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "CallF", linkageName: "_CCallF.Main", scope: null, file: !38, line: 6, type: !27, spFlags: DISPFlagDefinition, unit: !39)
// CHECK:STDOUT: !44 = !DILocation(line: 7, column: 3, scope: !43)
// CHECK:STDOUT: !45 = !DILocation(line: 6, column: 1, scope: !43)
// CHECK:STDOUT: !46 = !{!"any pointer", !2, i64 0}
// CHECK:STDOUT: !47 = !{!"p1 _ZTS7InlineC", !46, i64 0}
// CHECK:STDOUT: !48 = !{!47, !47, i64 0}
// CHECK:STDOUT: !49 = !{}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'todo_import_thread_local.carbon'
// CHECK:STDOUT: source_filename = "todo_import_thread_local.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZTW19thread_local_global = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZTW29thread_local_global_with_init = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @thread_local_global = dso_local thread_local global i32 0, align 4
// CHECK:STDOUT: @thread_local_global_with_init = dso_local thread_local global i32 0, align 4
// CHECK:STDOUT: @__tls_guard = internal thread_local global i8 0, align 1
// CHECK:STDOUT:
// CHECK:STDOUT: @_ZTH29thread_local_global_with_init = dso_local alias void (), ptr @__tls_init
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: uwtable
// CHECK:STDOUT: define internal void @__cxx_global_var_init() #0 section ".text.startup" {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %call = call noundef i32 @_Z4initv()
// CHECK:STDOUT:   %0 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @thread_local_global_with_init)
// CHECK:STDOUT:   store i32 %call, ptr %0, align 4, !tbaa !4
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare noundef i32 @_Z4initv() #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
// CHECK:STDOUT: declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CThreadLocalStore.Main() #3 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   store i32 42, ptr @thread_local_global, align 4, !dbg !56
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CThreadLocalTriggerInit.Main() #3 !dbg !58 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc14 = load i32, ptr @thread_local_global_with_init, align 4, !dbg !61
// CHECK:STDOUT:   ret i32 %.loc14, !dbg !62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: uwtable
// CHECK:STDOUT: define internal void @__tls_init() #0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %0 = load i8, ptr @__tls_guard, align 1
// CHECK:STDOUT:   %guard.uninitialized = icmp eq i8 %0, 0
// CHECK:STDOUT:   br i1 %guard.uninitialized, label %init, label %exit, !prof !63
// CHECK:STDOUT:
// CHECK:STDOUT: init:                                             ; preds = %entry
// CHECK:STDOUT:   store i8 1, ptr @__tls_guard, align 1
// CHECK:STDOUT:   %1 = call ptr @llvm.invariant.start.p0(i64 1, ptr @__tls_guard)
// CHECK:STDOUT:   call void @__cxx_global_var_init()
// CHECK:STDOUT:   br label %exit
// CHECK:STDOUT:
// CHECK:STDOUT: exit:                                             ; preds = %init, %entry
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare ptr @llvm.invariant.start.p0(i64 immarg, ptr captures(none)) #4
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: uwtable
// CHECK:STDOUT: define weak_odr hidden noundef ptr @_ZTW19thread_local_global() #5 comdat {
// CHECK:STDOUT:   %1 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @thread_local_global)
// CHECK:STDOUT:   ret ptr %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: uwtable
// CHECK:STDOUT: define weak_odr hidden noundef ptr @_ZTW29thread_local_global_with_init() #5 comdat {
// CHECK:STDOUT:   call void @_ZTH29thread_local_global_with_init()
// CHECK:STDOUT:   %1 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @thread_local_global_with_init)
// CHECK:STDOUT:   ret ptr %1
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
// CHECK:STDOUT: attributes #3 = { nounwind }
// CHECK:STDOUT: attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #5 = { uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!51}
// CHECK:STDOUT: !llvm.module.flags = !{!33, !34, !35, !8, !9}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!37}
// CHECK:STDOUT:
// CHECK:STDOUT: !1 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !2 = !{!"omnipotent char", !1, i64 0}
// CHECK:STDOUT: !3 = !{!"int", !2, i64 0}
// CHECK:STDOUT: !4 = !{!3, !3, i64 0}
// CHECK:STDOUT: !8 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !9 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !26 = !{null}
// CHECK:STDOUT: !27 = !DISubroutineType(types: !26)
// CHECK:STDOUT: !33 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !34 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !35 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !36 = !{!"__libc_errno", !3, i64 0}
// CHECK:STDOUT: !37 = !{!36, !3, i64 0}
// CHECK:STDOUT: !50 = !DIFile(filename: "todo_import_thread_local.carbon", directory: "")
// CHECK:STDOUT: !51 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !50, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !52 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !53 = !{!52}
// CHECK:STDOUT: !54 = !DISubroutineType(types: !53)
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "ThreadLocalStore", linkageName: "_CThreadLocalStore.Main", scope: null, file: !50, line: 9, type: !27, spFlags: DISPFlagDefinition, unit: !51)
// CHECK:STDOUT: !56 = !DILocation(line: 10, column: 3, scope: !55)
// CHECK:STDOUT: !57 = !DILocation(line: 9, column: 1, scope: !55)
// CHECK:STDOUT: !58 = distinct !DISubprogram(name: "ThreadLocalTriggerInit", linkageName: "_CThreadLocalTriggerInit.Main", scope: null, file: !50, line: 13, type: !54, spFlags: DISPFlagDefinition, unit: !51)
// CHECK:STDOUT: !61 = !DILocation(line: 14, column: 10, scope: !58)
// CHECK:STDOUT: !62 = !DILocation(line: 14, column: 3, scope: !58)
// CHECK:STDOUT: !63 = !{!"branch_weights", i32 1, i32 1023}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_static.carbon'
// CHECK:STDOUT: source_filename = "import_static.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN1X1nE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @_ZN1X1nE = linkonce_odr dso_local global i32 42, comdat, align 4
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadStatic.Main() #0 !dbg !66 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7 = load i32, ptr @_ZN1X1nE, align 4, !dbg !69
// CHECK:STDOUT:   ret i32 %.loc7, !dbg !70
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!65}
// CHECK:STDOUT: !llvm.module.flags = !{!33, !34, !35, !8, !9}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!37}
// CHECK:STDOUT:
// CHECK:STDOUT: !1 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !2 = !{!"omnipotent char", !1, i64 0}
// CHECK:STDOUT: !3 = !{!"int", !2, i64 0}
// CHECK:STDOUT: !8 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !9 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !33 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !34 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !35 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !36 = !{!"__libc_errno", !3, i64 0}
// CHECK:STDOUT: !37 = !{!36, !3, i64 0}
// CHECK:STDOUT: !52 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !53 = !{!52}
// CHECK:STDOUT: !54 = !DISubroutineType(types: !53)
// CHECK:STDOUT: !64 = !DIFile(filename: "import_static.carbon", directory: "")
// CHECK:STDOUT: !65 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !64, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !66 = distinct !DISubprogram(name: "ReadStatic", linkageName: "_CReadStatic.Main", scope: null, file: !64, line: 6, type: !54, spFlags: DISPFlagDefinition, unit: !65)
// CHECK:STDOUT: !69 = !DILocation(line: 7, column: 10, scope: !66)
// CHECK:STDOUT: !70 = !DILocation(line: 7, column: 3, scope: !66)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_var_template.carbon'
// CHECK:STDOUT: source_filename = "import_var_template.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.Y = type { i8 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z4tmplI1YE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_Z4tmplIiE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @_Z4tmplI1YE = linkonce_odr dso_local global %struct.Y zeroinitializer, comdat, align 1
// CHECK:STDOUT: @_ZGV4tmplI1YE = linkonce_odr dso_local global i64 0, comdat($_Z4tmplI1YE), align 8
// CHECK:STDOUT: @_Z4tmplIiE = linkonce_odr dso_local global i32 0, comdat, align 4
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cxx_global_var_init, ptr @_Z4tmplI1YE }]
// CHECK:STDOUT: @llvm.used = appending global [1 x ptr] [ptr @_Z4tmplI1YE], section "llvm.metadata"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: uwtable
// CHECK:STDOUT: define internal void @__cxx_global_var_init() #0 section ".text.startup" comdat($_Z4tmplI1YE) {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %0 = load i8, ptr @_ZGV4tmplI1YE, align 8
// CHECK:STDOUT:   %guard.uninitialized = icmp eq i8 %0, 0
// CHECK:STDOUT:   br i1 %guard.uninitialized, label %init.check, label %init.end
// CHECK:STDOUT:
// CHECK:STDOUT: init.check:                                       ; preds = %entry
// CHECK:STDOUT:   store i8 1, ptr @_ZGV4tmplI1YE, align 8
// CHECK:STDOUT:   call void @_ZN1YC1Ev(ptr noundef nonnull align 1 dereferenceable(1) @_Z4tmplI1YE)
// CHECK:STDOUT:   br label %init.end
// CHECK:STDOUT:
// CHECK:STDOUT: init.end:                                         ; preds = %init.check, %entry
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN1YC1Ev(ptr noundef nonnull align 1 dereferenceable(1)) unnamed_addr #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadVarTemplate.Main() #2 !dbg !75 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7 = load i32, ptr @_Z4tmplIiE, align 4, !dbg !78
// CHECK:STDOUT:   ret i32 %.loc7, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CReadVarTemplateWithConstructor.Main() #2 !dbg !80 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret ptr @_Z4tmplI1YE, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_Z4tmplI1YE, { 2, 3, 0, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!72}
// CHECK:STDOUT: !llvm.module.flags = !{!33, !34, !35, !8, !9}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!37}
// CHECK:STDOUT:
// CHECK:STDOUT: !1 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !2 = !{!"omnipotent char", !1, i64 0}
// CHECK:STDOUT: !3 = !{!"int", !2, i64 0}
// CHECK:STDOUT: !8 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !9 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !33 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !34 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !35 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !36 = !{!"__libc_errno", !3, i64 0}
// CHECK:STDOUT: !37 = !{!36, !3, i64 0}
// CHECK:STDOUT: !40 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !52 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !53 = !{!52}
// CHECK:STDOUT: !54 = !DISubroutineType(types: !53)
// CHECK:STDOUT: !71 = !DIFile(filename: "import_var_template.carbon", directory: "")
// CHECK:STDOUT: !72 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !71, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !73 = !{!40}
// CHECK:STDOUT: !74 = !DISubroutineType(types: !73)
// CHECK:STDOUT: !75 = distinct !DISubprogram(name: "ReadVarTemplate", linkageName: "_CReadVarTemplate.Main", scope: null, file: !71, line: 6, type: !54, spFlags: DISPFlagDefinition, unit: !72)
// CHECK:STDOUT: !78 = !DILocation(line: 7, column: 10, scope: !75)
// CHECK:STDOUT: !79 = !DILocation(line: 7, column: 3, scope: !75)
// CHECK:STDOUT: !80 = distinct !DISubprogram(name: "ReadVarTemplateWithConstructor", linkageName: "_CReadVarTemplateWithConstructor.Main", scope: null, file: !71, line: 10, type: !74, spFlags: DISPFlagDefinition, unit: !72)
// CHECK:STDOUT: !83 = !DILocation(line: 11, column: 3, scope: !80)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'import_static_template.carbon'
// CHECK:STDOUT: source_filename = "import_static_template.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %struct.Y.0 = type { i8 }
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN11StaticTmplX11static_tmplI1YEE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: $_ZN11StaticTmplX11static_tmplIiEE = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @_ZN11StaticTmplX11static_tmplI1YEE = linkonce_odr dso_local global %struct.Y.0 zeroinitializer, comdat, align 1
// CHECK:STDOUT: @_ZGVN11StaticTmplX11static_tmplI1YEE = linkonce_odr dso_local global i64 0, comdat($_ZN11StaticTmplX11static_tmplI1YEE), align 8
// CHECK:STDOUT: @_ZN11StaticTmplX11static_tmplIiEE = linkonce_odr dso_local global i32 0, comdat, align 4
// CHECK:STDOUT: @llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cxx_global_var_init, ptr @_ZN11StaticTmplX11static_tmplI1YEE }]
// CHECK:STDOUT: @llvm.used = appending global [1 x ptr] [ptr @_ZN11StaticTmplX11static_tmplI1YEE], section "llvm.metadata"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: uwtable
// CHECK:STDOUT: define internal void @__cxx_global_var_init() #0 section ".text.startup" comdat($_ZN11StaticTmplX11static_tmplI1YEE) {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %0 = load i8, ptr @_ZGVN11StaticTmplX11static_tmplI1YEE, align 8
// CHECK:STDOUT:   %guard.uninitialized = icmp eq i8 %0, 0
// CHECK:STDOUT:   br i1 %guard.uninitialized, label %init.check, label %init.end
// CHECK:STDOUT:
// CHECK:STDOUT: init.check:                                       ; preds = %entry
// CHECK:STDOUT:   store i8 1, ptr @_ZGVN11StaticTmplX11static_tmplI1YEE, align 8
// CHECK:STDOUT:   call void @_ZN1YC1Ev(ptr noundef nonnull align 1 dereferenceable(1) @_ZN11StaticTmplX11static_tmplI1YEE)
// CHECK:STDOUT:   br label %init.end
// CHECK:STDOUT:
// CHECK:STDOUT: init.end:                                         ; preds = %init.check, %entry
// CHECK:STDOUT:   ret void
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_ZN1YC1Ev(ptr noundef nonnull align 1 dereferenceable(1)) unnamed_addr #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define i32 @_CReadStaticVarTemplate.Main() #2 !dbg !86 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7 = load i32, ptr @_ZN11StaticTmplX11static_tmplIiEE, align 4, !dbg !89
// CHECK:STDOUT:   ret i32 %.loc7, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CReadStaticVarTemplateWithConstructor.Main() #2 !dbg !91 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret ptr @_ZN11StaticTmplX11static_tmplI1YEE, !dbg !94
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @_ZN11StaticTmplX11static_tmplI1YEE, { 2, 3, 0, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #1 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
// CHECK:STDOUT: attributes #2 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!85}
// CHECK:STDOUT: !llvm.module.flags = !{!33, !34, !35, !8, !9}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!37}
// CHECK:STDOUT:
// CHECK:STDOUT: !1 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !2 = !{!"omnipotent char", !1, i64 0}
// CHECK:STDOUT: !3 = !{!"int", !2, i64 0}
// CHECK:STDOUT: !8 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !9 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !33 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !34 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !35 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !36 = !{!"__libc_errno", !3, i64 0}
// CHECK:STDOUT: !37 = !{!36, !3, i64 0}
// CHECK:STDOUT: !40 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !52 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !53 = !{!52}
// CHECK:STDOUT: !54 = !DISubroutineType(types: !53)
// CHECK:STDOUT: !73 = !{!40}
// CHECK:STDOUT: !74 = !DISubroutineType(types: !73)
// CHECK:STDOUT: !84 = !DIFile(filename: "import_static_template.carbon", directory: "")
// CHECK:STDOUT: !85 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !84, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !86 = distinct !DISubprogram(name: "ReadStaticVarTemplate", linkageName: "_CReadStaticVarTemplate.Main", scope: null, file: !84, line: 6, type: !54, spFlags: DISPFlagDefinition, unit: !85)
// CHECK:STDOUT: !89 = !DILocation(line: 7, column: 10, scope: !86)
// CHECK:STDOUT: !90 = !DILocation(line: 7, column: 3, scope: !86)
// CHECK:STDOUT: !91 = distinct !DISubprogram(name: "ReadStaticVarTemplateWithConstructor", linkageName: "_CReadStaticVarTemplateWithConstructor.Main", scope: null, file: !84, line: 10, type: !74, spFlags: DISPFlagDefinition, unit: !85)
// CHECK:STDOUT: !94 = !DILocation(line: 11, column: 3, scope: !91)
// CHECK:STDOUT:
