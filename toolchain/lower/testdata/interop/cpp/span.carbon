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
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main(ptr %s) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_15.1.temp = alloca { ptr, i64 }, align 8, !dbg !24
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %.loc7_15.1.temp), !dbg !24
// CHECK:STDOUT:   call void @"_CConvert.Slice.b1aeb9ebf60f2c6e.Core:ImplicitAs.199f09b7947680dc.Core.d4057e3ae48c02cc"(ptr %.loc7_15.1.temp, ptr %s), !dbg !24
// CHECK:STDOUT:   call void @_Z7ConsumeNSt3__14spanIKiLm18446744073709551615EEE.carbon_thunk._(ptr %.loc7_15.1.temp), !dbg !27
// CHECK:STDOUT:   call void @"_CSelfDestruct.4bfa33862d0a15b7:core.Destroy.Core"(ptr %.loc7_15.1.temp), !dbg !24
// CHECK:STDOUT:   ret void, !dbg !28
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.6a8d754fe1453eab:core.Destroy.Core"(ptr %self) #0 !dbg !31 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !33
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6a8d754fe1453eab:core.Destroy.Core"(ptr %self) #0 !dbg !35 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.6a8d754fe1453eab:core.Destroy.Core"(ptr %self), !dbg !37
// CHECK:STDOUT:   ret void, !dbg !37
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z7ConsumeNSt3__14spanIKiLm18446744073709551615EEE.carbon_thunk._(ptr noundef %s) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %s.addr = alloca ptr, align 8
// CHECK:STDOUT:   %agg.tmp = alloca %"class.std::__1::span", align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %s, ptr %s.addr, align 8, !tbaa !116
// CHECK:STDOUT:   %0 = load ptr, ptr %s.addr, align 8, !tbaa !116
// CHECK:STDOUT:   call void @llvm.memcpy.p0.p0.i64(ptr align 8 %agg.tmp, ptr align 8 %0, i64 16, i1 false), !tbaa.struct !123
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
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.7742c7b82efb7924:core.Destroy.Core"(ptr %self) #0 !dbg !39 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !41
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %self) #0 !dbg !43 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !45
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.04308374e1dd783a:core.Destroy.Core"(ptr %self) #0 !dbg !47 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_15.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !49
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc7_15.1.size), !dbg !49
// CHECK:STDOUT:   %.loc7_15.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !49
// CHECK:STDOUT:   call void @"_CSelfDestruct.7742c7b82efb7924:core.Destroy.Core"(ptr %.loc7_15.2.ptr), !dbg !49
// CHECK:STDOUT:   ret void, !dbg !49
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.04308374e1dd783a:core.Destroy.Core"(ptr %self) #0 !dbg !51 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.04308374e1dd783a:core.Destroy.Core"(ptr %self), !dbg !53
// CHECK:STDOUT:   ret void, !dbg !53
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.4bfa33862d0a15b7:core.Destroy.Core"(ptr %self) #0 !dbg !55 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc7_15.1.size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !57
// CHECK:STDOUT:   call void @"_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core"(ptr %.loc7_15.1.size), !dbg !57
// CHECK:STDOUT:   %.loc7_15.2.ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !57
// CHECK:STDOUT:   call void @"_CSelfDestruct.7742c7b82efb7924:core.Destroy.Core"(ptr %.loc7_15.2.ptr), !dbg !57
// CHECK:STDOUT:   ret void, !dbg !57
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.4bfa33862d0a15b7:core.Destroy.Core"(ptr %self) #0 !dbg !59 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.4bfa33862d0a15b7:core.Destroy.Core"(ptr %self), !dbg !61
// CHECK:STDOUT:   ret void, !dbg !61
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CG.Main(ptr sret({ ptr, i64 }) %return) #0 !dbg !63 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_Z7Producev.carbon_thunk.(ptr %return), !dbg !66
// CHECK:STDOUT:   ret void, !dbg !67
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: alwaysinline mustprogress nounwind uwtable
// CHECK:STDOUT: define internal void @_Z7Producev.carbon_thunk.(ptr noundef %return) #1 personality ptr @__gxx_personality_v0 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %return.addr = alloca ptr, align 8
// CHECK:STDOUT:   %exn.slot = alloca ptr, align 8
// CHECK:STDOUT:   %ehselector.slot = alloca i32, align 4
// CHECK:STDOUT:   store ptr %return, ptr %return.addr, align 8, !tbaa !125
// CHECK:STDOUT:   %0 = load ptr, ptr %return.addr, align 8, !tbaa !125
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
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.Slice.b1aeb9ebf60f2c6e.Core:ImplicitAs.199f09b7947680dc.Core.d4057e3ae48c02cc"(ptr sret({ ptr, i64 }) %return, ptr %self) #0 !dbg !70 {
// CHECK:STDOUT:   %1 = call ptr @_CData.Slice.Core.d4057e3ae48c02cc(ptr %self), !dbg !75
// CHECK:STDOUT:   %2 = call i64 @_CSize.Slice.Core.d4057e3ae48c02cc(ptr %self), !dbg !76
// CHECK:STDOUT:   call void @_CUnsafeMake.Slice.Core.cd77d7fbcb14a7c2(ptr %return, ptr %1, i64 %2), !dbg !79
// CHECK:STDOUT:   ret void, !dbg !82
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CData.Slice.Core.d4057e3ae48c02cc(ptr %self) #0 !dbg !84 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 0, !dbg !89
// CHECK:STDOUT:   %1 = load ptr, ptr %ptr, align 8, !dbg !89
// CHECK:STDOUT:   ret ptr %1, !dbg !90
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i64 @_CSize.Slice.Core.d4057e3ae48c02cc(ptr %self) #0 !dbg !92 {
// CHECK:STDOUT:   %size = getelementptr inbounds nuw { ptr, i64 }, ptr %self, i32 0, i32 1, !dbg !97
// CHECK:STDOUT:   %1 = load i64, ptr %size, align 8, !dbg !97
// CHECK:STDOUT:   ret i64 %1, !dbg !98
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CUnsafeMake.Slice.Core.cd77d7fbcb14a7c2(ptr sret({ ptr, i64 }) %return, ptr %p, i64 %size) #0 !dbg !100 {
// CHECK:STDOUT:   %ptr = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 0, !dbg !109
// CHECK:STDOUT:   store ptr %p, ptr %ptr, align 8, !dbg !109
// CHECK:STDOUT:   %size1 = getelementptr inbounds nuw { ptr, i64 }, ptr %return, i32 0, i32 1, !dbg !109
// CHECK:STDOUT:   store i64 %size, ptr %size1, align 8, !dbg !109
// CHECK:STDOUT:   ret void, !dbg !110
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
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!127, !128, !129, !2, !3}
// CHECK:STDOUT: !llvm.errno.tbaa = !{!131}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "span.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIBasicType(name: "int", size: 64, encoding: DW_ATE_signed)
// CHECK:STDOUT: !8 = !{null, !6}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !11 = !{null, !10}
// CHECK:STDOUT: !12 = !DISubroutineType(types: !11)
// CHECK:STDOUT: !13 = !{null, !7}
// CHECK:STDOUT: !14 = !DISubroutineType(types: !13)
// CHECK:STDOUT: !15 = !{!10}
// CHECK:STDOUT: !16 = !DISubroutineType(types: !15)
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 6, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !20)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !6)
// CHECK:STDOUT: !19 = !DILocation(line: 6, column: 9, scope: !17)
// CHECK:STDOUT: !20 = !{!18}
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !4, line: 6, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !29)
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !21, type: !10)
// CHECK:STDOUT: !24 = !DILocation(line: 7, column: 15, scope: !21)
// CHECK:STDOUT: !25 = !{!10, !10}
// CHECK:STDOUT: !26 = !DISubroutineType(types: !25)
// CHECK:STDOUT: !27 = !DILocation(line: 7, column: 3, scope: !21)
// CHECK:STDOUT: !28 = !DILocation(line: 6, column: 1, scope: !21)
// CHECK:STDOUT: !29 = !{!22}
// CHECK:STDOUT: !30 = !DIFile(filename: "./span.h", directory: "")
// CHECK:STDOUT: !31 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.6a8d754fe1453eab:core.Destroy.Core", scope: null, file: !30, line: 9, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !34)
// CHECK:STDOUT: !32 = !DILocalVariable(arg: 1, scope: !31, type: !10)
// CHECK:STDOUT: !33 = !DILocation(line: 9, column: 11, scope: !31)
// CHECK:STDOUT: !34 = !{!32}
// CHECK:STDOUT: !35 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6a8d754fe1453eab:core.Destroy.Core", scope: null, file: !30, line: 9, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !38)
// CHECK:STDOUT: !36 = !DILocalVariable(arg: 1, scope: !35, type: !10)
// CHECK:STDOUT: !37 = !DILocation(line: 9, column: 11, scope: !35)
// CHECK:STDOUT: !38 = !{!36}
// CHECK:STDOUT: !39 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.7742c7b82efb7924:core.Destroy.Core", scope: null, file: !4, line: 7, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !42)
// CHECK:STDOUT: !40 = !DILocalVariable(arg: 1, scope: !39, type: !10)
// CHECK:STDOUT: !41 = !DILocation(line: 7, column: 15, scope: !39)
// CHECK:STDOUT: !42 = !{!40}
// CHECK:STDOUT: !43 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.5aacfd7dcc330b17:core.Destroy.Core", scope: null, file: !4, line: 7, type: !14, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !46)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 1, scope: !43, type: !7)
// CHECK:STDOUT: !45 = !DILocation(line: 7, column: 15, scope: !43)
// CHECK:STDOUT: !46 = !{!44}
// CHECK:STDOUT: !47 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.04308374e1dd783a:core.Destroy.Core", scope: null, file: !4, line: 7, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !50)
// CHECK:STDOUT: !48 = !DILocalVariable(arg: 1, scope: !47, type: !10)
// CHECK:STDOUT: !49 = !DILocation(line: 7, column: 15, scope: !47)
// CHECK:STDOUT: !50 = !{!48}
// CHECK:STDOUT: !51 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.04308374e1dd783a:core.Destroy.Core", scope: null, file: !4, line: 7, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !54)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 1, scope: !51, type: !10)
// CHECK:STDOUT: !53 = !DILocation(line: 7, column: 15, scope: !51)
// CHECK:STDOUT: !54 = !{!52}
// CHECK:STDOUT: !55 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.4bfa33862d0a15b7:core.Destroy.Core", scope: null, file: !4, line: 7, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !58)
// CHECK:STDOUT: !56 = !DILocalVariable(arg: 1, scope: !55, type: !10)
// CHECK:STDOUT: !57 = !DILocation(line: 7, column: 15, scope: !55)
// CHECK:STDOUT: !58 = !{!56}
// CHECK:STDOUT: !59 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.4bfa33862d0a15b7:core.Destroy.Core", scope: null, file: !4, line: 7, type: !12, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !62)
// CHECK:STDOUT: !60 = !DILocalVariable(arg: 1, scope: !59, type: !10)
// CHECK:STDOUT: !61 = !DILocation(line: 7, column: 15, scope: !59)
// CHECK:STDOUT: !62 = !{!60}
// CHECK:STDOUT: !63 = distinct !DISubprogram(name: "G", linkageName: "_CG.Main", scope: null, file: !4, line: 10, type: !16, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !66 = !DILocation(line: 11, column: 10, scope: !63)
// CHECK:STDOUT: !67 = !DILocation(line: 11, column: 3, scope: !63)
// CHECK:STDOUT: !69 = !DIFile(filename: "{{.*}}/prelude/types/slice.carbon", directory: "")
// CHECK:STDOUT: !70 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Slice.b1aeb9ebf60f2c6e.Core:ImplicitAs.199f09b7947680dc.Core.d4057e3ae48c02cc", scope: null, file: !69, line: 81, type: !26, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !83)
// CHECK:STDOUT: !71 = !DILocalVariable(arg: 1, scope: !70, type: !10)
// CHECK:STDOUT: !75 = !DILocation(line: 82, column: 38, scope: !70)
// CHECK:STDOUT: !76 = !DILocation(line: 82, column: 63, scope: !70)
// CHECK:STDOUT: !77 = !{!7, !10}
// CHECK:STDOUT: !78 = !DISubroutineType(types: !77)
// CHECK:STDOUT: !79 = !DILocation(line: 82, column: 12, scope: !70)
// CHECK:STDOUT: !80 = !{!10, !10, !7}
// CHECK:STDOUT: !81 = !DISubroutineType(types: !80)
// CHECK:STDOUT: !82 = !DILocation(line: 82, column: 5, scope: !70)
// CHECK:STDOUT: !83 = !{!71}
// CHECK:STDOUT: !84 = distinct !DISubprogram(name: "Data", linkageName: "_CData.Slice.Core.d4057e3ae48c02cc", scope: null, file: !69, line: 37, type: !26, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !91)
// CHECK:STDOUT: !85 = !DILocalVariable(arg: 1, scope: !84, type: !10)
// CHECK:STDOUT: !89 = !DILocation(line: 37, column: 32, scope: !84)
// CHECK:STDOUT: !90 = !DILocation(line: 37, column: 25, scope: !84)
// CHECK:STDOUT: !91 = !{!85}
// CHECK:STDOUT: !92 = distinct !DISubprogram(name: "Size", linkageName: "_CSize.Slice.Core.d4057e3ae48c02cc", scope: null, file: !69, line: 34, type: !78, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !99)
// CHECK:STDOUT: !93 = !DILocalVariable(arg: 1, scope: !92, type: !10)
// CHECK:STDOUT: !97 = !DILocation(line: 34, column: 33, scope: !92)
// CHECK:STDOUT: !98 = !DILocation(line: 34, column: 26, scope: !92)
// CHECK:STDOUT: !99 = !{!93}
// CHECK:STDOUT: !100 = distinct !DISubprogram(name: "UnsafeMake", linkageName: "_CUnsafeMake.Slice.Core.cd77d7fbcb14a7c2", scope: null, file: !69, line: 31, type: !81, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !111)
// CHECK:STDOUT: !101 = !DILocalVariable(arg: 1, scope: !100, type: !10)
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 2, scope: !100, type: !7)
// CHECK:STDOUT: !109 = !DILocation(line: 32, column: 12, scope: !100)
// CHECK:STDOUT: !110 = !DILocation(line: 32, column: 5, scope: !100)
// CHECK:STDOUT: !111 = !{!101, !102}
// CHECK:STDOUT: !112 = !{!"Simple C++ TBAA"}
// CHECK:STDOUT: !113 = !{!"omnipotent char", !112, i64 0}
// CHECK:STDOUT: !114 = !{!"any pointer", !113, i64 0}
// CHECK:STDOUT: !115 = !{!"p1 _ZTSNSt3__14spanIKiLm18446744073709551615EEE", !114, i64 0}
// CHECK:STDOUT: !116 = !{!115, !115, i64 0}
// CHECK:STDOUT: !117 = !{!"int", !113, i64 0}
// CHECK:STDOUT: !118 = !{!"p1 int", !114, i64 0}
// CHECK:STDOUT: !119 = !{!"long", !113, i64 0}
// CHECK:STDOUT: !121 = !{!118, !118, i64 0}
// CHECK:STDOUT: !122 = !{!119, !119, i64 0}
// CHECK:STDOUT: !123 = !{i64 0, i64 8, !121, i64 8, i64 8, !122}
// CHECK:STDOUT: !124 = !{!"p1 _ZTSNSt3__14spanIiLm18446744073709551615EEE", !114, i64 0}
// CHECK:STDOUT: !125 = !{!124, !124, i64 0}
// CHECK:STDOUT: !127 = !{i32 8, !"PIC Level", i32 2}
// CHECK:STDOUT: !128 = !{i32 7, !"PIE Level", i32 2}
// CHECK:STDOUT: !129 = !{i32 7, !"uwtable", i32 2}
// CHECK:STDOUT: !130 = !{!"__libc_errno", !117, i64 0}
// CHECK:STDOUT: !131 = !{!130, !117, i64 0}
// CHECK:STDOUT:
