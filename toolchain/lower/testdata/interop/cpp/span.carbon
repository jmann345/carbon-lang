// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/interop/cpp/span.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/interop/cpp/span.carbon

// Fork (SL-2, fork/slices/plan.md §4.B; D-SL-8, R-6): the IR-level twin of
// check stdlib/span.carbon's `pass_and_return`. Predicted: an import-side
// thunk definition named after the callee's Itanium mangling plus
// `.carbon_thunk._` (thunks.carbon:117 `@_ZN9NeedThunkC1ERKS_.carbon_thunk._`),
// so the name carries `4span` and the all-ones extent 18446744073709551615 of
// the mangled `std::span<const int, dynamic_extent>` parameter; the thunk
// takes `ptr` (the `Slice` storage's address) and calls the real `Consume`
// with a by-value `span` load; `Produce`'s out-pointer thunk writes 16 bytes
// into the Carbon return slot. No `memcpy` between differently sized types
// (the layout premise's IR-level check).

// --- span.h

namespace std {
  using size_t = __SIZE_TYPE__;

  inline namespace __1 {
    inline constexpr size_t dynamic_extent = static_cast<size_t>(-1);

    template <typename T, size_t Extent = dynamic_extent>
    class span {
     public:
      span() = default;
      template <typename U>
      span(const span<U, Extent>& other)
          : data_(other.data()), size_(other.size()) {}
      T* data() const { return data_; }
      size_t size() const { return size_; }

     private:
      T* data_;
      size_t size_;
    };
  }
}

auto Consume(std::span<const int> s) -> void;
auto Produce() -> std::span<int>;

// --- span.carbon

library "[[@TEST_NAME]]";

import Cpp library "span.h";

fn F(s: Core.Slice(i32)) {
  Cpp.Consume(s);
}

fn G() -> Core.Slice(i32) {
  return Cpp.Produce();
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'span.carbon'
// CHECK:STDOUT: source_filename = "span.carbon"
// CHECK:STDOUT: target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
// CHECK:STDOUT: target triple = "x86_64-unknown-linux-gnu"
// CHECK:STDOUT:
// CHECK:STDOUT: %"class.std::__1::span" = type { ptr, i64 }
// CHECK:STDOUT:
// CHECK:STDOUT: $__clang_call_terminate = comdat any
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [53 x i8] c"carbon: Core.Slice index out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @1 = private unnamed_addr constant [62 x i8] c"carbon: Core.Slice.Subslice range out of bounds; terminating\0A\00", align 1
// CHECK:STDOUT: @.str = private unnamed_addr constant [74 x i8] c"carbon: C++ exception escaped into Carbon through `Consume`; terminating\0A\00", align 1
// CHECK:STDOUT: @.str.1 = private unnamed_addr constant [74 x i8] c"carbon: C++ exception escaped into Carbon through `Produce`; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.70db2d92ffddbef7:core.Destroy.Core"(ptr %self) #0 !dbg !12 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !18
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main(ptr %s) #0 !dbg !19 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_15.1.temp = alloca { ptr, i64 }, align 8, !dbg !25
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_15.1.temp), !dbg !25
// CHECK:STDOUT:   call void @"_CConvert.Slice.b1aeb9ebf60f2c6e.Core:ImplicitAs.199f09b7947680dc.Core.694f9f022249e533"(ptr %.loc7_15.1.temp, ptr %s), !dbg !25
// CHECK:STDOUT:   call void @_Z7ConsumeNSt3__14spanIKiLm18446744073709551615EEE.carbon_thunk._(ptr %.loc7_15.1.temp), !dbg !26
// CHECK:STDOUT:   call void @"_COp.439bfd22b436437d:core.Destroy.Core"(ptr %.loc7_15.1.temp), !dbg !25
// CHECK:STDOUT:   ret void, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.d7e4fb3943386363:core.Destroy.Core"(ptr %self) #0 !dbg !28 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !32
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z7ConsumeNSt3__14spanIKiLm18446744073709551615EEE.carbon_thunk._(ptr noundef %s) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %s.addr = alloca ptr, align 8
// CHECK:STDOUT:   %agg.tmp = alloca %"class.std::__1::span", align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %s, ptr %s.addr, align 8, !tbaa !33
// CHECK:STDOUT:   %0 = load ptr, ptr %s.addr, align 8, !tbaa !33
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %agg.tmp, ptr align 8 %0, i64 16, i1 false), !tbaa.struct !36
// CHECK:STDOUT:   %1 = getelementptr inbounds nuw { ptr, i64 }, ptr %agg.tmp, i32 0, i32 0
// CHECK:STDOUT:   %2 = load ptr, ptr %1, align 8
// CHECK:STDOUT:   %3 = getelementptr inbounds nuw { ptr, i64 }, ptr %agg.tmp, i32 0, i32 1
// CHECK:STDOUT:   %4 = load i64, ptr %3, align 8
// CHECK:STDOUT:   invoke void @_Z7ConsumeNSt3__14spanIKiLm18446744073709551615EEE(ptr %2, i64 %4)
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   store ptr %6, ptr %exn.slot, align 8
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %5, 1
// CHECK:STDOUT:   store i32 %7, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %8 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call = call noundef i64 @write(i32 noundef 2, ptr noundef @.str, i64 noundef 73) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %9 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %10 = extractvalue { ptr, i32 } %9, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %10) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.5f42013854821c52:core.Destroy.Core"(ptr %self) #0 !dbg !41 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !47
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.3c5a2e7a6b09f4fd:core.Destroy.Core"(ptr %self) #0 !dbg !48 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !51
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_COp.439bfd22b436437d:core.Destroy.Core"(ptr %self) #0 !dbg !52 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !55
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CG.Main(ptr sret({ ptr, i64 }) %return) #0 !dbg !56 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z7Producev.carbon_thunk.(ptr %return), !dbg !59
// CHECK:STDOUT:   ret void, !dbg !60
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z7Producev.carbon_thunk.(ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !61
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !61
// CHECK:STDOUT:   %call = invoke { ptr, i64 } @_Z7Producev()
// CHECK:STDOUT:           to label %invoke.cont unwind label %lpad
// CHECK:STDOUT:
// CHECK:STDOUT: invoke.cont:                                      ; preds = %entry
// CHECK:STDOUT:   %1 = getelementptr inbounds nuw { ptr, i64 }, ptr %0, i32 0, i32 0
// CHECK:STDOUT:   %2 = extractvalue { ptr, i64 } %call, 0
// CHECK:STDOUT:   store ptr %2, ptr %1, align 8
// CHECK:STDOUT:   %3 = getelementptr inbounds nuw { ptr, i64 }, ptr %0, i32 0, i32 1
// CHECK:STDOUT:   %4 = extractvalue { ptr, i64 } %call, 1
// CHECK:STDOUT:   store i64 %4, ptr %3, align 8
// CHECK:STDOUT:   br label %try.cont
// CHECK:STDOUT:
// CHECK:STDOUT: lpad:                                             ; preds = %entry
// CHECK:STDOUT:   %5 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %6 = extractvalue { ptr, i32 } %5, 0
// CHECK:STDOUT:   store ptr %6, ptr %exn.slot, align 8
// CHECK:STDOUT:   %7 = extractvalue { ptr, i32 } %5, 1
// CHECK:STDOUT:   store i32 %7, ptr %ehselector.slot, align 4
// CHECK:STDOUT:   br label %catch
// CHECK:STDOUT:
// CHECK:STDOUT: catch:                                            ; preds = %lpad
// CHECK:STDOUT:   %exn = load ptr, ptr %exn.slot, align 8
// CHECK:STDOUT:   %8 = call ptr @__cxa_begin_catch(ptr %exn) #0
// CHECK:STDOUT:   %call1 = call noundef i64 @write(i32 noundef 2, ptr noundef @.str.1, i64 noundef 73) #0
// CHECK:STDOUT:   invoke void @__cxa_rethrow() #6
// CHECK:STDOUT:           to label %unreachable unwind label %terminate.lpad
// CHECK:STDOUT:
// CHECK:STDOUT: try.cont:                                         ; preds = %invoke.cont
// CHECK:STDOUT:   ret void
// CHECK:STDOUT:
// CHECK:STDOUT: terminate.lpad:                                   ; preds = %catch
// CHECK:STDOUT:   %9 = landingpad { ptr, i32 }
// CHECK:STDOUT:           catch ptr null
// CHECK:STDOUT:   %10 = extractvalue { ptr, i32 } %9, 0
// CHECK:STDOUT:   call void @__clang_call_terminate(ptr %10) #7
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT:
// CHECK:STDOUT: unreachable:                                      ; preds = %catch
// CHECK:STDOUT:   unreachable
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.Slice.b1aeb9ebf60f2c6e.Core:ImplicitAs.199f09b7947680dc.Core.694f9f022249e533"(ptr sret({ ptr, i64 }) %return, ptr %self) #0 !dbg !63 {
// CHECK:STDOUT:   %1 = call ptr @_CData.Slice.Core.694f9f022249e533(ptr %self), !dbg !69
// CHECK:STDOUT:   %2 = call i64 @_CSize.Slice.Core.694f9f022249e533(ptr %self), !dbg !70
// CHECK:STDOUT:   call void @_CUnsafeMake.Slice.Core.e5790a708f1bcd86(ptr %return, ptr %1, i64 %2), !dbg !71
// CHECK:STDOUT:   ret void, !dbg !72
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CData.Slice.Core.694f9f022249e533(ptr %self) #0 !dbg !73 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !76
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !76
// CHECK:STDOUT:   ret ptr %1, !dbg !77
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSize.Slice.Core.694f9f022249e533(ptr %self) #0 !dbg !78 {
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !83
// CHECK:STDOUT:   %1 = load i64, ptr %size, align 8, !dbg !83
// CHECK:STDOUT:   ret i64 %1, !dbg !84
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CUnsafeMake.Slice.Core.e5790a708f1bcd86(ptr sret({ ptr, i64 }) %return, ptr %p, i64 %size) #0 !dbg !85 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !91
// CHECK:STDOUT:   store ptr %p, ptr %ptr, align 8, !dbg !91
// CHECK:STDOUT:   %size1 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !91
// CHECK:STDOUT:   store i64 %size, ptr %size1, align 8, !dbg !91
// CHECK:STDOUT:   ret void, !dbg !92
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @_Z7ConsumeNSt3__14spanIKiLm18446744073709551615EEE(ptr, i64) #3
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #2
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
// CHECK:STDOUT: declare { ptr, i64 } @_Z7Producev() #3
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
// CHECK:STDOUT: attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #3 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
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
// CHECK:STDOUT: !1 = !DIFile(filename: "span.carbon", directory: "")
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
// CHECK:STDOUT: !12 = distinct !DISubprogram(name: "Op", linkageName: "_COp.70db2d92ffddbef7:core.Destroy.Core", scope: null, file: !1, line: 6, type: !13, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !16)
// CHECK:STDOUT: !13 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !14 = !{null, !15}
// CHECK:STDOUT: !15 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !16 = !{!17}
// CHECK:STDOUT: !17 = !DILocalVariable(arg: 1, scope: !12, type: !15)
// CHECK:STDOUT: !18 = !DILocation(line: 6, column: 9, scope: !12)
// CHECK:STDOUT: !19 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !1, line: 6, type: !20, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
// CHECK:STDOUT: !20 = !DISubroutineType(types: !21)
// CHECK:STDOUT: !21 = !{null, !22}
// CHECK:STDOUT: !22 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !23 = !{!24}
// CHECK:STDOUT: !24 = !DILocalVariable(arg: 1, scope: !19, type: !22)
// CHECK:STDOUT: !25 = !DILocation(line: 7, column: 15, scope: !19)
// CHECK:STDOUT: !26 = !DILocation(line: 7, column: 3, scope: !19)
// CHECK:STDOUT: !27 = !DILocation(line: 6, column: 1, scope: !19)
// CHECK:STDOUT: !28 = distinct !DISubprogram(name: "Op", linkageName: "_COp.d7e4fb3943386363:core.Destroy.Core", scope: null, file: !29, line: 9, type: !20, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !30)
// CHECK:STDOUT: !29 = !DIFile(filename: "./span.h", directory: "")
// CHECK:STDOUT: !30 = !{!31}
// CHECK:STDOUT: !31 = !DILocalVariable(arg: 1, scope: !28, type: !22)
// CHECK:STDOUT: !32 = !DILocation(line: 9, column: 11, scope: !28)
// CHECK:STDOUT: !33 = !{!34, !34, i64 0}
// CHECK:STDOUT: !34 = !{!"p1 _ZTSNSt3__14spanIKiLm18446744073709551615EEE", !35, i64 0}
// CHECK:STDOUT: !35 = !{!"any pointer", !10, i64 0}
// CHECK:STDOUT: !36 = !{i64 0, i64 8, !37, i64 8, i64 8, !39}
// CHECK:STDOUT: !37 = !{!38, !38, i64 0}
// CHECK:STDOUT: !38 = !{!"p1 int", !35, i64 0}
// CHECK:STDOUT: !39 = !{!40, !40, i64 0}
// CHECK:STDOUT: !40 = !{!"long", !10, i64 0}
// CHECK:STDOUT: !41 = distinct !DISubprogram(name: "Op", linkageName: "_COp.5f42013854821c52:core.Destroy.Core", scope: null, file: !1, line: 7, type: !42, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !45)
// CHECK:STDOUT: !42 = !DISubroutineType(types: !43)
// CHECK:STDOUT: !43 = !{null, !44}
// CHECK:STDOUT: !44 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !45 = !{!46}
// CHECK:STDOUT: !46 = !DILocalVariable(arg: 1, scope: !41, type: !44)
// CHECK:STDOUT: !47 = !DILocation(line: 7, column: 15, scope: !41)
// CHECK:STDOUT: !48 = distinct !DISubprogram(name: "Op", linkageName: "_COp.3c5a2e7a6b09f4fd:core.Destroy.Core", scope: null, file: !1, line: 7, type: !20, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !49)
// CHECK:STDOUT: !49 = !{!50}
// CHECK:STDOUT: !50 = !DILocalVariable(arg: 1, scope: !48, type: !22)
// CHECK:STDOUT: !51 = !DILocation(line: 7, column: 15, scope: !48)
// CHECK:STDOUT: !52 = distinct !DISubprogram(name: "Op", linkageName: "_COp.439bfd22b436437d:core.Destroy.Core", scope: null, file: !1, line: 7, type: !20, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !53)
// CHECK:STDOUT: !53 = !{!54}
// CHECK:STDOUT: !54 = !DILocalVariable(arg: 1, scope: !52, type: !22)
// CHECK:STDOUT: !55 = !DILocation(line: 7, column: 15, scope: !52)
// CHECK:STDOUT: !56 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !1, line: 10, type: !57, spFlags: DISPFlagDefinition, unit: !0)
// CHECK:STDOUT: !57 = !DISubroutineType(types: !58)
// CHECK:STDOUT: !58 = !{!22}
// CHECK:STDOUT: !59 = !DILocation(line: 11, column: 10, scope: !56)
// CHECK:STDOUT: !60 = !DILocation(line: 11, column: 3, scope: !56)
// CHECK:STDOUT: !61 = !{!62, !62, i64 0}
// CHECK:STDOUT: !62 = !{!"p1 _ZTSNSt3__14spanIiLm18446744073709551615EEE", !35, i64 0}
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Slice.b1aeb9ebf60f2c6e.Core:ImplicitAs.199f09b7947680dc.Core.694f9f022249e533", scope: null, file: !64, line: 81, type: !65, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !67)
// CHECK:STDOUT: !64 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !65 = !DISubroutineType(types: !66)
// CHECK:STDOUT: !66 = !{!22, !22}
// CHECK:STDOUT: !67 = !{!68}
// CHECK:STDOUT: !68 = !DILocalVariable(arg: 1, scope: !63, type: !22)
// CHECK:STDOUT: !69 = !DILocation(line: 82, column: 38, scope: !63)
// CHECK:STDOUT: !70 = !DILocation(line: 82, column: 63, scope: !63)
// CHECK:STDOUT: !71 = !DILocation(line: 82, column: 12, scope: !63)
// CHECK:STDOUT: !72 = !DILocation(line: 82, column: 5, scope: !63)
// CHECK:STDOUT: !73 = distinct !DISubprogram(name: "Data", linkageName: "_CData.Slice.Core.694f9f022249e533", scope: null, file: !64, line: 37, type: !65, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !74)
// CHECK:STDOUT: !74 = !{!75}
// CHECK:STDOUT: !75 = !DILocalVariable(arg: 1, scope: !73, type: !22)
// CHECK:STDOUT: !76 = !DILocation(line: 37, column: 32, scope: !73)
// CHECK:STDOUT: !77 = !DILocation(line: 37, column: 25, scope: !73)
// CHECK:STDOUT: !78 = distinct !DISubprogram(name: "Size", linkageName: "_CSize.Slice.Core.694f9f022249e533", scope: null, file: !64, line: 34, type: !79, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !81)
// CHECK:STDOUT: !79 = !DISubroutineType(types: !80)
// CHECK:STDOUT: !80 = !{!44, !22}
// CHECK:STDOUT: !81 = !{!82}
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !78, type: !22)
// CHECK:STDOUT: !83 = !DILocation(line: 34, column: 33, scope: !78)
// CHECK:STDOUT: !84 = !DILocation(line: 34, column: 26, scope: !78)
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "UnsafeMake", linkageName: "_CUnsafeMake.Slice.Core.e5790a708f1bcd86", scope: null, file: !64, line: 31, type: !86, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !88)
// CHECK:STDOUT: !86 = !DISubroutineType(types: !87)
// CHECK:STDOUT: !87 = !{!22, !22, !44}
// CHECK:STDOUT: !88 = !{!89, !90}
// CHECK:STDOUT: !89 = !DILocalVariable(arg: 1, scope: !85, type: !22)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 2, scope: !85, type: !44)
// CHECK:STDOUT: !91 = !DILocation(line: 32, column: 12, scope: !85)
// CHECK:STDOUT: !92 = !DILocation(line: 32, column: 5, scope: !85)
// CHECK:STDOUT:
