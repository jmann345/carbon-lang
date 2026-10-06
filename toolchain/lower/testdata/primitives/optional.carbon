// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// This is an integration test for the Core.Optional in the prelude, so use the
// real prelude.
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --target=x86_64-linux-gnu
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/lower/testdata/primitives/optional.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/lower/testdata/primitives/optional.carbon

// --- convert.carbon
library "[[@TEST_NAME]]";

fn Convert(o: Core.Optional(i32*)) -> Core.Optional(i32) {
  if (o.HasValue()) {
    return *o.Get();
  }
  return Core.Optional(i32).None();
}

fn AddOrRemoveConst(a: i32, b: const i32) {
  var _: Core.Optional(i32) = a;
  var _: const Core.Optional(i32) = a;
  var _: Core.Optional(const i32) = a;
  var _: const Core.Optional(const i32) = a;
  var _: Core.Optional(i32) = b;
  var _: const Core.Optional(i32) = b;
  var _: Core.Optional(const i32) = b;
  var _: const Core.Optional(const i32) = b;
}

// --- copy.carbon
library "[[@TEST_NAME]]";

class Copyable {
  impl as Core.Copy {
    fn Op(self) -> Self;
  }
}

fn F(c: Core.Optional(Copyable)) -> Core.Optional(Copyable) {
  // Should only perform one copy.
  return c;
}

// --- copy_pointer.carbon
library "[[@TEST_NAME]]";

class C {}

fn F(c: Core.Optional(C*)) -> Core.Optional(C*) {
  return c;
}

// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'convert.carbon'
// CHECK:STDOUT: source_filename = "convert.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CConvert.Main(ptr sret(<{ i32, i1 }>) %return, ptr %o) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.HasValue.call = call i1 @_CHasValue.Optional.Core.6e9e957697159b53(ptr %o), !dbg !30
// CHECK:STDOUT:   br i1 %Optional.HasValue.call, label %if.then, label %if.else, !dbg !31
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %Optional.Get.call = call ptr @_CGet.Optional.Core.6e9e957697159b53(ptr %o), !dbg !32
// CHECK:STDOUT:   %.loc5_12.2 = load i32, ptr %Optional.Get.call, align 4, !dbg !33
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr %return, i32 %.loc5_12.2), !dbg !34
// CHECK:STDOUT:   ret void, !dbg !34
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CNone.Optional.Core.3530343734a6ea27(ptr %return), !dbg !37
// CHECK:STDOUT:   ret void, !dbg !40
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CAddOrRemoveConst.Main(i32 %a, i32 %b) #0 !dbg !42 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %_.var.loc11 = alloca <{ i32, i1 }>, align 4, !dbg !47
// CHECK:STDOUT:   %_.var.loc12 = alloca <{ i32, i1 }>, align 4, !dbg !50
// CHECK:STDOUT:   %_.var.loc13 = alloca <{ i32, i1 }>, align 4, !dbg !53
// CHECK:STDOUT:   %_.var.loc14 = alloca <{ i32, i1 }>, align 4, !dbg !56
// CHECK:STDOUT:   %_.var.loc15 = alloca <{ i32, i1 }>, align 4, !dbg !59
// CHECK:STDOUT:   %_.var.loc16 = alloca <{ i32, i1 }>, align 4, !dbg !62
// CHECK:STDOUT:   %_.var.loc17 = alloca <{ i32, i1 }>, align 4, !dbg !65
// CHECK:STDOUT:   %_.var.loc18 = alloca <{ i32, i1 }>, align 4, !dbg !68
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc11), !dbg !47
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr %_.var.loc11, i32 %a), !dbg !47
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc12), !dbg !50
// CHECK:STDOUT:   call void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.27a2d1ef6dd68465"(ptr %_.var.loc12, i32 %a), !dbg !50
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc13), !dbg !53
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224"(ptr %_.var.loc13, i32 %a), !dbg !53
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc14), !dbg !56
// CHECK:STDOUT:   call void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.bc0e935618dc3a96"(ptr %_.var.loc14, i32 %a), !dbg !56
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc15), !dbg !59
// CHECK:STDOUT:   call void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.27a2d1ef6dd68465"(ptr %_.var.loc15, i32 %b), !dbg !59
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc16), !dbg !62
// CHECK:STDOUT:   call void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.9f04190beae22821"(ptr %_.var.loc16, i32 %b), !dbg !62
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc17), !dbg !65
// CHECK:STDOUT:   call void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.bc0e935618dc3a96"(ptr %_.var.loc17, i32 %b), !dbg !65
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc18), !dbg !68
// CHECK:STDOUT:   call void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.342679e541375c77"(ptr %_.var.loc18, i32 %b), !dbg !68
// CHECK:STDOUT:   call void @"_CSelfDestruct.b90699303d3716f5:core.Destroy.Core"(ptr %_.var.loc18), !dbg !68
// CHECK:STDOUT:   call void @"_CSelfDestruct.60848ede08716e91:core.Destroy.Core"(ptr %_.var.loc17), !dbg !65
// CHECK:STDOUT:   call void @"_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core"(ptr %_.var.loc16), !dbg !62
// CHECK:STDOUT:   call void @"_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core"(ptr %_.var.loc15), !dbg !59
// CHECK:STDOUT:   call void @"_CSelfDestruct.b90699303d3716f5:core.Destroy.Core"(ptr %_.var.loc14), !dbg !56
// CHECK:STDOUT:   call void @"_CSelfDestruct.60848ede08716e91:core.Destroy.Core"(ptr %_.var.loc13), !dbg !53
// CHECK:STDOUT:   call void @"_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core"(ptr %_.var.loc12), !dbg !50
// CHECK:STDOUT:   call void @"_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core"(ptr %_.var.loc11), !dbg !47
// CHECK:STDOUT:   ret void, !dbg !71
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.6a8d754fe1453eab:core.Destroy.Core"(ptr %self) #0 !dbg !73 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !75
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6a8d754fe1453eab:core.Destroy.Core"(ptr %self) #0 !dbg !77 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.6a8d754fe1453eab:core.Destroy.Core"(ptr %self), !dbg !79
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.96a347e4ca9c10e1:core.Destroy.Core"(ptr %self) #0 !dbg !81 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.96a347e4ca9c10e1:core.Destroy.Core"(ptr %self) #0 !dbg !85 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.96a347e4ca9c10e1:core.Destroy.Core"(ptr %self), !dbg !87
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.ef6922493c513f55:core.Destroy.Core"(ptr %self) #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %self) #0 !dbg !93 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !95
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.6854f843fd23bc45:core.Destroy.Core"(ptr %self) #0 !dbg !97 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_3.1.has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !99
// CHECK:STDOUT:   call void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %.loc18_3.1.has_value), !dbg !99
// CHECK:STDOUT:   %.loc18_3.2.value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !99
// CHECK:STDOUT:   call void @"_CSelfDestruct.ef6922493c513f55:core.Destroy.Core"(ptr %.loc18_3.2.value), !dbg !99
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6854f843fd23bc45:core.Destroy.Core"(ptr %self) #0 !dbg !101 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.6854f843fd23bc45:core.Destroy.Core"(ptr %self), !dbg !103
// CHECK:STDOUT:   ret void, !dbg !103
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.d81dc56afe745c8e:core.Destroy.Core"(ptr %self) #0 !dbg !105 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc18_3.1.has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %.loc18_3.1.has_value), !dbg !107
// CHECK:STDOUT:   %.loc18_3.2.value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !107
// CHECK:STDOUT:   call void @"_CSelfDestruct.ef6922493c513f55:core.Destroy.Core"(ptr %.loc18_3.2.value), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d81dc56afe745c8e:core.Destroy.Core"(ptr %self) #0 !dbg !109 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.d81dc56afe745c8e:core.Destroy.Core"(ptr %self), !dbg !111
// CHECK:STDOUT:   ret void, !dbg !111
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.60848ede08716e91:core.Destroy.Core"(ptr %self) #0 !dbg !113 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b90699303d3716f5:core.Destroy.Core"(ptr %self) #0 !dbg !117 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b90699303d3716f5:core.Destroy.Core"(ptr %self) #0 !dbg !121 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b90699303d3716f5:core.Destroy.Core"(ptr %self), !dbg !123
// CHECK:STDOUT:   ret void, !dbg !123
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.1d6a7672bf2f14c6:core.Destroy.Core"(ptr %self) #0 !dbg !125 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !127
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.1d6a7672bf2f14c6:core.Destroy.Core"(ptr %self) #0 !dbg !129 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.1d6a7672bf2f14c6:core.Destroy.Core"(ptr %self), !dbg !131
// CHECK:STDOUT:   ret void, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.51569357b34b54dc:core.Destroy.Core"(ptr %self) #0 !dbg !133 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !135
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.f6a63055ea5a1824:core.Destroy.Core"(ptr %self) #0 !dbg !137 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_3.1.has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !139
// CHECK:STDOUT:   call void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %.loc16_3.1.has_value), !dbg !139
// CHECK:STDOUT:   %.loc16_3.2.value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !139
// CHECK:STDOUT:   call void @"_CSelfDestruct.51569357b34b54dc:core.Destroy.Core"(ptr %.loc16_3.2.value), !dbg !139
// CHECK:STDOUT:   ret void, !dbg !139
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f6a63055ea5a1824:core.Destroy.Core"(ptr %self) #0 !dbg !141 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.f6a63055ea5a1824:core.Destroy.Core"(ptr %self), !dbg !143
// CHECK:STDOUT:   ret void, !dbg !143
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.9f155f365c9e4267:core.Destroy.Core"(ptr %self) #0 !dbg !145 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %.loc16_3.1.has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !147
// CHECK:STDOUT:   call void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr %.loc16_3.1.has_value), !dbg !147
// CHECK:STDOUT:   %.loc16_3.2.value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !147
// CHECK:STDOUT:   call void @"_CSelfDestruct.51569357b34b54dc:core.Destroy.Core"(ptr %.loc16_3.2.value), !dbg !147
// CHECK:STDOUT:   ret void, !dbg !147
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.9f155f365c9e4267:core.Destroy.Core"(ptr %self) #0 !dbg !149 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.9f155f365c9e4267:core.Destroy.Core"(ptr %self), !dbg !151
// CHECK:STDOUT:   ret void, !dbg !151
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core"(ptr %self) #0 !dbg !153 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !155
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.65ac38c7f841b05c:core.Destroy.Core"(ptr %self) #0 !dbg !157 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !159
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core"(ptr %self) #0 !dbg !161 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.65ac38c7f841b05c:core.Destroy.Core"(ptr %self), !dbg !163
// CHECK:STDOUT:   ret void, !dbg !163
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.6e9e957697159b53(ptr %self) #0 !dbg !166 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %self), !dbg !172
// CHECK:STDOUT:   ret i1 %1, !dbg !173
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CGet.Optional.Core.6e9e957697159b53(ptr %self) #0 !dbg !175 {
// CHECK:STDOUT:   %1 = call ptr @"_CGet.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %self), !dbg !181
// CHECK:STDOUT:   ret ptr %1, !dbg !182
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !184 {
// CHECK:STDOUT:   call void @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.3530343734a6ea27"(ptr %return, i32 %self), !dbg !189
// CHECK:STDOUT:   ret void, !dbg !190
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CNone.Optional.Core.3530343734a6ea27(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !192 {
// CHECK:STDOUT:   call void @"_CNone.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %return), !dbg !195
// CHECK:STDOUT:   ret void, !dbg !196
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.27a2d1ef6dd68465"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !198 {
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr %return, i32 %self), !dbg !203
// CHECK:STDOUT:   ret void, !dbg !204
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !206 {
// CHECK:STDOUT:   call void @"_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.dd5a2a74150e1fc7"(ptr %return, i32 %self), !dbg !211
// CHECK:STDOUT:   ret void, !dbg !212
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.bc0e935618dc3a96"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !214 {
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224"(ptr %return, i32 %self), !dbg !219
// CHECK:STDOUT:   ret void, !dbg !220
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.27a2d1ef6dd68465"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !222 {
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr %return, i32 %self), !dbg !228
// CHECK:STDOUT:   ret void, !dbg !229
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.9f04190beae22821"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !231 {
// CHECK:STDOUT:   call void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.27a2d1ef6dd68465"(ptr %return, i32 %self), !dbg !237
// CHECK:STDOUT:   ret void, !dbg !238
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.bc0e935618dc3a96"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !240 {
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224"(ptr %return, i32 %self), !dbg !246
// CHECK:STDOUT:   ret void, !dbg !247
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.342679e541375c77"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !249 {
// CHECK:STDOUT:   call void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.bc0e935618dc3a96"(ptr %return, i32 %self), !dbg !255
// CHECK:STDOUT:   ret void, !dbg !256
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %value) #0 !dbg !258 {
// CHECK:STDOUT:   %1 = icmp eq ptr %value, null, !dbg !264
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !265
// CHECK:STDOUT:   ret i1 %2, !dbg !266
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CGet.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %value) #0 !dbg !268 {
// CHECK:STDOUT:   ret ptr %value, !dbg !274
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.3530343734a6ea27"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !276 {
// CHECK:STDOUT:   call void @_CSome.Optional.Core.3530343734a6ea27(ptr %return, i32 %self), !dbg !282
// CHECK:STDOUT:   ret void, !dbg !283
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNone.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !285 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !292
// CHECK:STDOUT:   store i8 0, ptr %has_value, align 1, !dbg !292
// CHECK:STDOUT:   ret void, !dbg !293
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.dd5a2a74150e1fc7"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !294 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !299
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !299
// CHECK:STDOUT:   %1 = call i32 @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.ba7abeb9eee545e2"(i32 %self), !dbg !299
// CHECK:STDOUT:   store i32 %1, ptr %temp, align 4, !dbg !299
// CHECK:STDOUT:   %2 = load i32, ptr %temp, align 4, !dbg !299
// CHECK:STDOUT:   call void @_CSome.Optional.Core.00b00ea46fa3b046(ptr %return, i32 %2), !dbg !300
// CHECK:STDOUT:   call void @"_CSelfDestruct.6a8d754fe1453eab:core.Destroy.Core"(ptr %temp), !dbg !299
// CHECK:STDOUT:   ret void, !dbg !301
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Core.3530343734a6ea27(ptr sret(<{ i32, i1 }>) %return, i32 %value) #0 !dbg !303 {
// CHECK:STDOUT:   call void @"_CSome.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %return, i32 %value), !dbg !308
// CHECK:STDOUT:   ret void, !dbg !309
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.ba7abeb9eee545e2"(i32 %self) #0 !dbg !311 {
// CHECK:STDOUT:   %1 = call i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %self), !dbg !316
// CHECK:STDOUT:   ret i32 %1, !dbg !319
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Core.00b00ea46fa3b046(ptr sret(<{ i32, i1 }>) %return, i32 %value) #0 !dbg !321 {
// CHECK:STDOUT:   call void @"_CSome.74becf39533834ee:OptionalStorage.Core.cd77d7fbcb14a7c2"(ptr %return, i32 %value), !dbg !326
// CHECK:STDOUT:   ret void, !dbg !327
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !329 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 0, !dbg !338
// CHECK:STDOUT:   store i32 %self, ptr %value, align 4, !dbg !338
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !340
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !340
// CHECK:STDOUT:   ret void, !dbg !341
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %self) #0 !dbg !344 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !349
// CHECK:STDOUT:   ret i32 %1, !dbg !351
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.74becf39533834ee:OptionalStorage.Core.cd77d7fbcb14a7c2"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !353 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 0, !dbg !362
// CHECK:STDOUT:   %1 = call i32 @"_COp.a7c16f707f533a23:Copy.Core.4d6ceefeb7f772f4"(i32 %self), !dbg !363
// CHECK:STDOUT:   store i32 %1, ptr %value, align 4, !dbg !362
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !364
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !364
// CHECK:STDOUT:   ret void, !dbg !365
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !367 {
// CHECK:STDOUT:   ret i32 %self, !dbg !373
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_COp.a7c16f707f533a23:Copy.Core.4d6ceefeb7f772f4"(i32 %self) #0 !dbg !376 {
// CHECK:STDOUT:   ret i32 %self, !dbg !383
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.60848ede08716e91:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.b90699303d3716f5:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843", { 0, 1, 3, 2 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 8, 7, 6, 5, 4, 3, 2, 1 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!5}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !4 = !DIFile(filename: "convert.carbon", directory: "")
// CHECK:STDOUT: !5 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !4, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !6 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{null, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !10 = !{null, !6}
// CHECK:STDOUT: !11 = !DISubroutineType(types: !10)
// CHECK:STDOUT: !12 = !{!7, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !14 = !{null, !6, !6}
// CHECK:STDOUT: !15 = !DISubroutineType(types: !14)
// CHECK:STDOUT: !16 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !17 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d088c7eb746488be:core.Destroy.Core", scope: null, file: !16, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !20)
// CHECK:STDOUT: !18 = !DILocalVariable(arg: 1, scope: !17, type: !7)
// CHECK:STDOUT: !19 = !DILocation(line: 189, column: 19, scope: !17)
// CHECK:STDOUT: !20 = !{!18}
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 3, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !24)
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !21, type: !6)
// CHECK:STDOUT: !23 = !DILocation(line: 3, column: 39, scope: !21)
// CHECK:STDOUT: !24 = !{!22}
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Main", scope: null, file: !4, line: 3, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !41)
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !25, type: !7)
// CHECK:STDOUT: !30 = !DILocation(line: 4, column: 7, scope: !25)
// CHECK:STDOUT: !31 = !DILocation(line: 4, column: 6, scope: !25)
// CHECK:STDOUT: !32 = !DILocation(line: 5, column: 13, scope: !25)
// CHECK:STDOUT: !33 = !DILocation(line: 5, column: 12, scope: !25)
// CHECK:STDOUT: !34 = !DILocation(line: 5, column: 5, scope: !25)
// CHECK:STDOUT: !35 = !{!7, !6}
// CHECK:STDOUT: !36 = !DISubroutineType(types: !35)
// CHECK:STDOUT: !37 = !DILocation(line: 7, column: 10, scope: !25)
// CHECK:STDOUT: !38 = !{!7}
// CHECK:STDOUT: !39 = !DISubroutineType(types: !38)
// CHECK:STDOUT: !40 = !DILocation(line: 7, column: 3, scope: !25)
// CHECK:STDOUT: !41 = !{!26}
// CHECK:STDOUT: !42 = distinct !DISubprogram(name: "AddOrRemoveConst", linkageName: "_CAddOrRemoveConst.Main", scope: null, file: !4, line: 10, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !72)
// CHECK:STDOUT: !43 = !DILocalVariable(arg: 1, scope: !42, type: !6)
// CHECK:STDOUT: !44 = !DILocalVariable(arg: 2, scope: !42, type: !6)
// CHECK:STDOUT: !47 = !DILocation(line: 11, column: 3, scope: !42)
// CHECK:STDOUT: !50 = !DILocation(line: 12, column: 3, scope: !42)
// CHECK:STDOUT: !53 = !DILocation(line: 13, column: 3, scope: !42)
// CHECK:STDOUT: !56 = !DILocation(line: 14, column: 3, scope: !42)
// CHECK:STDOUT: !59 = !DILocation(line: 15, column: 3, scope: !42)
// CHECK:STDOUT: !62 = !DILocation(line: 16, column: 3, scope: !42)
// CHECK:STDOUT: !65 = !DILocation(line: 17, column: 3, scope: !42)
// CHECK:STDOUT: !68 = !DILocation(line: 18, column: 3, scope: !42)
// CHECK:STDOUT: !71 = !DILocation(line: 10, column: 1, scope: !42)
// CHECK:STDOUT: !72 = !{!43, !44}
// CHECK:STDOUT: !73 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.6a8d754fe1453eab:core.Destroy.Core", scope: null, file: !4, line: 13, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !76)
// CHECK:STDOUT: !74 = !DILocalVariable(arg: 1, scope: !73, type: !7)
// CHECK:STDOUT: !75 = !DILocation(line: 13, column: 10, scope: !73)
// CHECK:STDOUT: !76 = !{!74}
// CHECK:STDOUT: !77 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6a8d754fe1453eab:core.Destroy.Core", scope: null, file: !4, line: 13, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !80)
// CHECK:STDOUT: !78 = !DILocalVariable(arg: 1, scope: !77, type: !7)
// CHECK:STDOUT: !79 = !DILocation(line: 13, column: 10, scope: !77)
// CHECK:STDOUT: !80 = !{!78}
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.96a347e4ca9c10e1:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !84)
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !81, type: !7)
// CHECK:STDOUT: !83 = !DILocation(line: 18, column: 3, scope: !81)
// CHECK:STDOUT: !84 = !{!82}
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.96a347e4ca9c10e1:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !88)
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !85, type: !7)
// CHECK:STDOUT: !87 = !DILocation(line: 18, column: 3, scope: !85)
// CHECK:STDOUT: !88 = !{!86}
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.ef6922493c513f55:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !92)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !89, type: !7)
// CHECK:STDOUT: !91 = !DILocation(line: 18, column: 3, scope: !89)
// CHECK:STDOUT: !92 = !{!90}
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !96)
// CHECK:STDOUT: !94 = !DILocalVariable(arg: 1, scope: !93, type: !7)
// CHECK:STDOUT: !95 = !DILocation(line: 18, column: 3, scope: !93)
// CHECK:STDOUT: !96 = !{!94}
// CHECK:STDOUT: !97 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.6854f843fd23bc45:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !100)
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !97, type: !7)
// CHECK:STDOUT: !99 = !DILocation(line: 18, column: 3, scope: !97)
// CHECK:STDOUT: !100 = !{!98}
// CHECK:STDOUT: !101 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6854f843fd23bc45:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !104)
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 1, scope: !101, type: !7)
// CHECK:STDOUT: !103 = !DILocation(line: 18, column: 3, scope: !101)
// CHECK:STDOUT: !104 = !{!102}
// CHECK:STDOUT: !105 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.d81dc56afe745c8e:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !108)
// CHECK:STDOUT: !106 = !DILocalVariable(arg: 1, scope: !105, type: !7)
// CHECK:STDOUT: !107 = !DILocation(line: 18, column: 3, scope: !105)
// CHECK:STDOUT: !108 = !{!106}
// CHECK:STDOUT: !109 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.d81dc56afe745c8e:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !112)
// CHECK:STDOUT: !110 = !DILocalVariable(arg: 1, scope: !109, type: !7)
// CHECK:STDOUT: !111 = !DILocation(line: 18, column: 3, scope: !109)
// CHECK:STDOUT: !112 = !{!110}
// CHECK:STDOUT: !113 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.60848ede08716e91:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !116)
// CHECK:STDOUT: !114 = !DILocalVariable(arg: 1, scope: !113, type: !7)
// CHECK:STDOUT: !115 = !DILocation(line: 18, column: 3, scope: !113)
// CHECK:STDOUT: !116 = !{!114}
// CHECK:STDOUT: !117 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b90699303d3716f5:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !120)
// CHECK:STDOUT: !118 = !DILocalVariable(arg: 1, scope: !117, type: !7)
// CHECK:STDOUT: !119 = !DILocation(line: 18, column: 3, scope: !117)
// CHECK:STDOUT: !120 = !{!118}
// CHECK:STDOUT: !121 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b90699303d3716f5:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !124)
// CHECK:STDOUT: !122 = !DILocalVariable(arg: 1, scope: !121, type: !7)
// CHECK:STDOUT: !123 = !DILocation(line: 18, column: 3, scope: !121)
// CHECK:STDOUT: !124 = !{!122}
// CHECK:STDOUT: !125 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.1d6a7672bf2f14c6:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !128)
// CHECK:STDOUT: !126 = !DILocalVariable(arg: 1, scope: !125, type: !7)
// CHECK:STDOUT: !127 = !DILocation(line: 16, column: 3, scope: !125)
// CHECK:STDOUT: !128 = !{!126}
// CHECK:STDOUT: !129 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.1d6a7672bf2f14c6:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !132)
// CHECK:STDOUT: !130 = !DILocalVariable(arg: 1, scope: !129, type: !7)
// CHECK:STDOUT: !131 = !DILocation(line: 16, column: 3, scope: !129)
// CHECK:STDOUT: !132 = !{!130}
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.51569357b34b54dc:core.Destroy.Core", scope: null, file: !4, line: 16, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !136)
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !133, type: !6)
// CHECK:STDOUT: !135 = !DILocation(line: 16, column: 3, scope: !133)
// CHECK:STDOUT: !136 = !{!134}
// CHECK:STDOUT: !137 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.f6a63055ea5a1824:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !140)
// CHECK:STDOUT: !138 = !DILocalVariable(arg: 1, scope: !137, type: !7)
// CHECK:STDOUT: !139 = !DILocation(line: 16, column: 3, scope: !137)
// CHECK:STDOUT: !140 = !{!138}
// CHECK:STDOUT: !141 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f6a63055ea5a1824:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !144)
// CHECK:STDOUT: !142 = !DILocalVariable(arg: 1, scope: !141, type: !7)
// CHECK:STDOUT: !143 = !DILocation(line: 16, column: 3, scope: !141)
// CHECK:STDOUT: !144 = !{!142}
// CHECK:STDOUT: !145 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.9f155f365c9e4267:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !148)
// CHECK:STDOUT: !146 = !DILocalVariable(arg: 1, scope: !145, type: !7)
// CHECK:STDOUT: !147 = !DILocation(line: 16, column: 3, scope: !145)
// CHECK:STDOUT: !148 = !{!146}
// CHECK:STDOUT: !149 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.9f155f365c9e4267:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !152)
// CHECK:STDOUT: !150 = !DILocalVariable(arg: 1, scope: !149, type: !7)
// CHECK:STDOUT: !151 = !DILocation(line: 16, column: 3, scope: !149)
// CHECK:STDOUT: !152 = !{!150}
// CHECK:STDOUT: !153 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !156)
// CHECK:STDOUT: !154 = !DILocalVariable(arg: 1, scope: !153, type: !7)
// CHECK:STDOUT: !155 = !DILocation(line: 16, column: 3, scope: !153)
// CHECK:STDOUT: !156 = !{!154}
// CHECK:STDOUT: !157 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.65ac38c7f841b05c:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !160)
// CHECK:STDOUT: !158 = !DILocalVariable(arg: 1, scope: !157, type: !7)
// CHECK:STDOUT: !159 = !DILocation(line: 16, column: 3, scope: !157)
// CHECK:STDOUT: !160 = !{!158}
// CHECK:STDOUT: !161 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !164)
// CHECK:STDOUT: !162 = !DILocalVariable(arg: 1, scope: !161, type: !7)
// CHECK:STDOUT: !163 = !DILocation(line: 16, column: 3, scope: !161)
// CHECK:STDOUT: !164 = !{!162}
// CHECK:STDOUT: !166 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.6e9e957697159b53", scope: null, file: !16, line: 37, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !174)
// CHECK:STDOUT: !167 = !DILocalVariable(arg: 1, scope: !166, type: !7)
// CHECK:STDOUT: !172 = !DILocation(line: 38, column: 12, scope: !166)
// CHECK:STDOUT: !173 = !DILocation(line: 38, column: 5, scope: !166)
// CHECK:STDOUT: !174 = !{!167}
// CHECK:STDOUT: !175 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.6e9e957697159b53", scope: null, file: !16, line: 40, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !183)
// CHECK:STDOUT: !176 = !DILocalVariable(arg: 1, scope: !175, type: !7)
// CHECK:STDOUT: !181 = !DILocation(line: 41, column: 12, scope: !175)
// CHECK:STDOUT: !182 = !DILocation(line: 41, column: 5, scope: !175)
// CHECK:STDOUT: !183 = !{!176}
// CHECK:STDOUT: !184 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843", scope: null, file: !16, line: 130, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !191)
// CHECK:STDOUT: !185 = !DILocalVariable(arg: 1, scope: !184, type: !6)
// CHECK:STDOUT: !189 = !DILocation(line: 131, column: 12, scope: !184)
// CHECK:STDOUT: !190 = !DILocation(line: 131, column: 5, scope: !184)
// CHECK:STDOUT: !191 = !{!185}
// CHECK:STDOUT: !192 = distinct !DISubprogram(name: "None", linkageName: "_CNone.Optional.Core.3530343734a6ea27", scope: null, file: !16, line: 31, type: !39, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !195 = !DILocation(line: 32, column: 12, scope: !192)
// CHECK:STDOUT: !196 = !DILocation(line: 32, column: 5, scope: !192)
// CHECK:STDOUT: !197 = !DIFile(filename: "{{.*}}/prelude/operators/as.carbon", directory: "")
// CHECK:STDOUT: !198 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.27a2d1ef6dd68465", scope: null, file: !197, line: 43, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !205)
// CHECK:STDOUT: !199 = !DILocalVariable(arg: 1, scope: !198, type: !6)
// CHECK:STDOUT: !203 = !DILocation(line: 43, column: 40, scope: !198)
// CHECK:STDOUT: !204 = !DILocation(line: 43, column: 33, scope: !198)
// CHECK:STDOUT: !205 = !{!199}
// CHECK:STDOUT: !206 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224", scope: null, file: !16, line: 130, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !213)
// CHECK:STDOUT: !207 = !DILocalVariable(arg: 1, scope: !206, type: !6)
// CHECK:STDOUT: !211 = !DILocation(line: 131, column: 12, scope: !206)
// CHECK:STDOUT: !212 = !DILocation(line: 131, column: 5, scope: !206)
// CHECK:STDOUT: !213 = !{!207}
// CHECK:STDOUT: !214 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.bc0e935618dc3a96", scope: null, file: !197, line: 43, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !221)
// CHECK:STDOUT: !215 = !DILocalVariable(arg: 1, scope: !214, type: !6)
// CHECK:STDOUT: !219 = !DILocation(line: 43, column: 40, scope: !214)
// CHECK:STDOUT: !220 = !DILocation(line: 43, column: 33, scope: !214)
// CHECK:STDOUT: !221 = !{!215}
// CHECK:STDOUT: !222 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.27a2d1ef6dd68465", scope: null, file: !197, line: 47, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !230)
// CHECK:STDOUT: !223 = !DILocalVariable(arg: 1, scope: !222, type: !6)
// CHECK:STDOUT: !228 = !DILocation(line: 47, column: 34, scope: !222)
// CHECK:STDOUT: !229 = !DILocation(line: 47, column: 27, scope: !222)
// CHECK:STDOUT: !230 = !{!223}
// CHECK:STDOUT: !231 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.9f04190beae22821", scope: null, file: !197, line: 47, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !239)
// CHECK:STDOUT: !232 = !DILocalVariable(arg: 1, scope: !231, type: !6)
// CHECK:STDOUT: !237 = !DILocation(line: 47, column: 34, scope: !231)
// CHECK:STDOUT: !238 = !DILocation(line: 47, column: 27, scope: !231)
// CHECK:STDOUT: !239 = !{!232}
// CHECK:STDOUT: !240 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.bc0e935618dc3a96", scope: null, file: !197, line: 47, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !248)
// CHECK:STDOUT: !241 = !DILocalVariable(arg: 1, scope: !240, type: !6)
// CHECK:STDOUT: !246 = !DILocation(line: 47, column: 34, scope: !240)
// CHECK:STDOUT: !247 = !DILocation(line: 47, column: 27, scope: !240)
// CHECK:STDOUT: !248 = !{!241}
// CHECK:STDOUT: !249 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.342679e541375c77", scope: null, file: !197, line: 47, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !257)
// CHECK:STDOUT: !250 = !DILocalVariable(arg: 1, scope: !249, type: !6)
// CHECK:STDOUT: !255 = !DILocation(line: 47, column: 34, scope: !249)
// CHECK:STDOUT: !256 = !DILocation(line: 47, column: 27, scope: !249)
// CHECK:STDOUT: !257 = !{!250}
// CHECK:STDOUT: !258 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba", scope: null, file: !16, line: 197, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !267)
// CHECK:STDOUT: !259 = !DILocalVariable(arg: 1, scope: !258, type: !7)
// CHECK:STDOUT: !264 = !DILocation(line: 198, column: 16, scope: !258)
// CHECK:STDOUT: !265 = !DILocation(line: 198, column: 12, scope: !258)
// CHECK:STDOUT: !266 = !DILocation(line: 198, column: 5, scope: !258)
// CHECK:STDOUT: !267 = !{!259}
// CHECK:STDOUT: !268 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba", scope: null, file: !16, line: 200, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !275)
// CHECK:STDOUT: !269 = !DILocalVariable(arg: 1, scope: !268, type: !7)
// CHECK:STDOUT: !274 = !DILocation(line: 201, column: 5, scope: !268)
// CHECK:STDOUT: !275 = !{!269}
// CHECK:STDOUT: !276 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.3530343734a6ea27", scope: null, file: !16, line: 105, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !284)
// CHECK:STDOUT: !277 = !DILocalVariable(arg: 1, scope: !276, type: !6)
// CHECK:STDOUT: !282 = !DILocation(line: 106, column: 12, scope: !276)
// CHECK:STDOUT: !283 = !DILocation(line: 106, column: 5, scope: !276)
// CHECK:STDOUT: !284 = !{!277}
// CHECK:STDOUT: !285 = distinct !DISubprogram(name: "None", linkageName: "_CNone.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !16, line: 150, type: !39, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !292 = !DILocation(line: 153, column: 5, scope: !285)
// CHECK:STDOUT: !293 = !DILocation(line: 154, column: 5, scope: !285)
// CHECK:STDOUT: !294 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.dd5a2a74150e1fc7", scope: null, file: !16, line: 112, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !302)
// CHECK:STDOUT: !295 = !DILocalVariable(arg: 1, scope: !294, type: !6)
// CHECK:STDOUT: !299 = !DILocation(line: 113, column: 29, scope: !294)
// CHECK:STDOUT: !300 = !DILocation(line: 113, column: 12, scope: !294)
// CHECK:STDOUT: !301 = !DILocation(line: 113, column: 5, scope: !294)
// CHECK:STDOUT: !302 = !{!295}
// CHECK:STDOUT: !303 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.3530343734a6ea27", scope: null, file: !16, line: 34, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !310)
// CHECK:STDOUT: !304 = !DILocalVariable(arg: 1, scope: !303, type: !6)
// CHECK:STDOUT: !308 = !DILocation(line: 35, column: 12, scope: !303)
// CHECK:STDOUT: !309 = !DILocation(line: 35, column: 5, scope: !303)
// CHECK:STDOUT: !310 = !{!304}
// CHECK:STDOUT: !311 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.ba7abeb9eee545e2", scope: null, file: !197, line: 43, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !320)
// CHECK:STDOUT: !312 = !DILocalVariable(arg: 1, scope: !311, type: !6)
// CHECK:STDOUT: !316 = !DILocation(line: 43, column: 40, scope: !311)
// CHECK:STDOUT: !317 = !{!6, !6}
// CHECK:STDOUT: !318 = !DISubroutineType(types: !317)
// CHECK:STDOUT: !319 = !DILocation(line: 43, column: 33, scope: !311)
// CHECK:STDOUT: !320 = !{!312}
// CHECK:STDOUT: !321 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.00b00ea46fa3b046", scope: null, file: !16, line: 34, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !328)
// CHECK:STDOUT: !322 = !DILocalVariable(arg: 1, scope: !321, type: !6)
// CHECK:STDOUT: !326 = !DILocation(line: 35, column: 12, scope: !321)
// CHECK:STDOUT: !327 = !DILocation(line: 35, column: 5, scope: !321)
// CHECK:STDOUT: !328 = !{!322}
// CHECK:STDOUT: !329 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !16, line: 156, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !342)
// CHECK:STDOUT: !330 = !DILocalVariable(arg: 1, scope: !329, type: !6)
// CHECK:STDOUT: !338 = !DILocation(line: 162, column: 5, scope: !329)
// CHECK:STDOUT: !340 = !DILocation(line: 163, column: 5, scope: !329)
// CHECK:STDOUT: !341 = !DILocation(line: 164, column: 5, scope: !329)
// CHECK:STDOUT: !342 = !{!330}
// CHECK:STDOUT: !343 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !344 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044", scope: null, file: !343, line: 64, type: !318, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !352)
// CHECK:STDOUT: !345 = !DILocalVariable(arg: 1, scope: !344, type: !6)
// CHECK:STDOUT: !349 = !DILocation(line: 66, column: 17, scope: !344)
// CHECK:STDOUT: !351 = !DILocation(line: 66, column: 5, scope: !344)
// CHECK:STDOUT: !352 = !{!345}
// CHECK:STDOUT: !353 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.74becf39533834ee:OptionalStorage.Core.cd77d7fbcb14a7c2", scope: null, file: !16, line: 156, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !366)
// CHECK:STDOUT: !354 = !DILocalVariable(arg: 1, scope: !353, type: !6)
// CHECK:STDOUT: !362 = !DILocation(line: 162, column: 5, scope: !353)
// CHECK:STDOUT: !363 = !DILocation(line: 162, column: 28, scope: !353)
// CHECK:STDOUT: !364 = !DILocation(line: 163, column: 5, scope: !353)
// CHECK:STDOUT: !365 = !DILocation(line: 164, column: 5, scope: !353)
// CHECK:STDOUT: !366 = !{!354}
// CHECK:STDOUT: !367 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !343, line: 59, type: !318, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !374)
// CHECK:STDOUT: !368 = !DILocalVariable(arg: 1, scope: !367, type: !6)
// CHECK:STDOUT: !373 = !DILocation(line: 59, column: 28, scope: !367)
// CHECK:STDOUT: !374 = !{!368}
// CHECK:STDOUT: !375 = !DIFile(filename: "{{.*}}/prelude/copy.carbon", directory: "")
// CHECK:STDOUT: !376 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a7c16f707f533a23:Copy.Core.4d6ceefeb7f772f4", scope: null, file: !375, line: 23, type: !36, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !384)
// CHECK:STDOUT: !377 = !DILocalVariable(arg: 1, scope: !376, type: !6)
// CHECK:STDOUT: !383 = !DILocation(line: 23, column: 25, scope: !376)
// CHECK:STDOUT: !384 = !{!377}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'copy.carbon'
// CHECK:STDOUT: source_filename = "copy.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp.Copyable.Main:Copy.Core"(ptr sret({}), ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cb8adced19392b99:core.Destroy.Core"(ptr %self) #0 !dbg !387 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !389
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bb3dd30fa3a4aa62:core.Destroy.Core"(ptr %self) #0 !dbg !391 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !393
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main(ptr sret({ {}, i1 }) %return, ptr %c) #0 !dbg !395 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.a2b7303f9ef09f31"(ptr %return, ptr %c), !dbg !400
// CHECK:STDOUT:   ret void, !dbg !401
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.a2b7303f9ef09f31"(ptr sret({ {}, i1 }) %return, ptr %self) #0 !dbg !403 {
// CHECK:STDOUT:   call void @"_CCopy.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %return, ptr %self), !dbg !409
// CHECK:STDOUT:   ret void, !dbg !410
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CCopy.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr sret({ {}, i1 }) %return, ptr %value) #0 !dbg !412 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %value), !dbg !418
// CHECK:STDOUT:   br i1 %1, label %2, label %3, !dbg !419
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw { {}, i1 }, ptr %value, i32 0, i32 0, !dbg !420
// CHECK:STDOUT:   call void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %return, ptr %value1), !dbg !421
// CHECK:STDOUT:   ret void, !dbg !422
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   call void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %return), !dbg !423
// CHECK:STDOUT:   ret void, !dbg !424
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %value) #0 !dbg !426 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw { {}, i1 }, ptr %value, i32 0, i32 1, !dbg !431
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !431
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !431
// CHECK:STDOUT:   ret i1 %2, !dbg !432
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr sret({ {}, i1 }) %return, ptr %self) #0 !dbg !434 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw { {}, i1 }, ptr %return, i32 0, i32 0, !dbg !443
// CHECK:STDOUT:   call void @"_COp.Copyable.Main:Copy.Core"(ptr %value, ptr %self), !dbg !444
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw { {}, i1 }, ptr %return, i32 0, i32 1, !dbg !445
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !445
// CHECK:STDOUT:   ret void, !dbg !446
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr sret({ {}, i1 }) %return) #0 !dbg !448 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw { {}, i1 }, ptr %return, i32 0, i32 1, !dbg !455
// CHECK:STDOUT:   store i8 0, ptr %has_value, align 1, !dbg !455
// CHECK:STDOUT:   ret void, !dbg !456
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!386}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{null, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !12 = !{!7, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !16 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !38 = !{!7}
// CHECK:STDOUT: !39 = !DISubroutineType(types: !38)
// CHECK:STDOUT: !385 = !DIFile(filename: "copy.carbon", directory: "")
// CHECK:STDOUT: !386 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !385, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !387 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cb8adced19392b99:core.Destroy.Core", scope: null, file: !385, line: 9, type: !9, spFlags: DISPFlagDefinition, unit: !386, retainedNodes: !390)
// CHECK:STDOUT: !388 = !DILocalVariable(arg: 1, scope: !387, type: !7)
// CHECK:STDOUT: !389 = !DILocation(line: 9, column: 9, scope: !387)
// CHECK:STDOUT: !390 = !{!388}
// CHECK:STDOUT: !391 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bb3dd30fa3a4aa62:core.Destroy.Core", scope: null, file: !385, line: 9, type: !9, spFlags: DISPFlagDefinition, unit: !386, retainedNodes: !394)
// CHECK:STDOUT: !392 = !DILocalVariable(arg: 1, scope: !391, type: !7)
// CHECK:STDOUT: !393 = !DILocation(line: 9, column: 9, scope: !391)
// CHECK:STDOUT: !394 = !{!392}
// CHECK:STDOUT: !395 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !385, line: 9, type: !13, spFlags: DISPFlagDefinition, unit: !386, retainedNodes: !402)
// CHECK:STDOUT: !396 = !DILocalVariable(arg: 1, scope: !395, type: !7)
// CHECK:STDOUT: !400 = !DILocation(line: 11, column: 10, scope: !395)
// CHECK:STDOUT: !401 = !DILocation(line: 11, column: 3, scope: !395)
// CHECK:STDOUT: !402 = !{!396}
// CHECK:STDOUT: !403 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Optional.24b7347a93330e68.Core:Copy.Core.a2b7303f9ef09f31", scope: null, file: !16, line: 51, type: !13, spFlags: DISPFlagDefinition, unit: !386, retainedNodes: !411)
// CHECK:STDOUT: !404 = !DILocalVariable(arg: 1, scope: !403, type: !7)
// CHECK:STDOUT: !409 = !DILocation(line: 52, column: 12, scope: !403)
// CHECK:STDOUT: !410 = !DILocation(line: 52, column: 5, scope: !403)
// CHECK:STDOUT: !411 = !{!404}
// CHECK:STDOUT: !412 = distinct !DISubprogram(name: "Copy", linkageName: "_CCopy.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c", scope: null, file: !16, line: 172, type: !13, spFlags: DISPFlagDefinition, unit: !386, retainedNodes: !425)
// CHECK:STDOUT: !413 = !DILocalVariable(arg: 1, scope: !412, type: !7)
// CHECK:STDOUT: !418 = !DILocation(line: 173, column: 9, scope: !412)
// CHECK:STDOUT: !419 = !DILocation(line: 173, column: 8, scope: !412)
// CHECK:STDOUT: !420 = !DILocation(line: 174, column: 15, scope: !412)
// CHECK:STDOUT: !421 = !DILocation(line: 174, column: 14, scope: !412)
// CHECK:STDOUT: !422 = !DILocation(line: 174, column: 7, scope: !412)
// CHECK:STDOUT: !423 = !DILocation(line: 176, column: 14, scope: !412)
// CHECK:STDOUT: !424 = !DILocation(line: 176, column: 7, scope: !412)
// CHECK:STDOUT: !425 = !{!413}
// CHECK:STDOUT: !426 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c", scope: null, file: !16, line: 166, type: !13, spFlags: DISPFlagDefinition, unit: !386, retainedNodes: !433)
// CHECK:STDOUT: !427 = !DILocalVariable(arg: 1, scope: !426, type: !7)
// CHECK:STDOUT: !431 = !DILocation(line: 167, column: 12, scope: !426)
// CHECK:STDOUT: !432 = !DILocation(line: 167, column: 5, scope: !426)
// CHECK:STDOUT: !433 = !{!427}
// CHECK:STDOUT: !434 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c", scope: null, file: !16, line: 156, type: !13, spFlags: DISPFlagDefinition, unit: !386, retainedNodes: !447)
// CHECK:STDOUT: !435 = !DILocalVariable(arg: 1, scope: !434, type: !7)
// CHECK:STDOUT: !443 = !DILocation(line: 162, column: 5, scope: !434)
// CHECK:STDOUT: !444 = !DILocation(line: 162, column: 28, scope: !434)
// CHECK:STDOUT: !445 = !DILocation(line: 163, column: 5, scope: !434)
// CHECK:STDOUT: !446 = !DILocation(line: 164, column: 5, scope: !434)
// CHECK:STDOUT: !447 = !{!435}
// CHECK:STDOUT: !448 = distinct !DISubprogram(name: "None", linkageName: "_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c", scope: null, file: !16, line: 150, type: !39, spFlags: DISPFlagDefinition, unit: !386)
// CHECK:STDOUT: !455 = !DILocation(line: 153, column: 5, scope: !448)
// CHECK:STDOUT: !456 = !DILocation(line: 154, column: 5, scope: !448)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'copy_pointer.carbon'
// CHECK:STDOUT: source_filename = "copy_pointer.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6b633cf020343e69:core.Destroy.Core"(ptr %self) #0 !dbg !459 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !461
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CF.Main(ptr %c) #0 !dbg !463 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.call = call ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.3e2e92aa38469608"(ptr %c), !dbg !468
// CHECK:STDOUT:   ret ptr %Optional.as.Copy.impl.Op.call, !dbg !469
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.3e2e92aa38469608"(ptr %self) #0 !dbg !471 {
// CHECK:STDOUT:   ret ptr %self, !dbg !478
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!458}
// CHECK:STDOUT: !llvm.module.flags = !{!2, !3}
// CHECK:STDOUT:
// CHECK:STDOUT: !2 = !{i32 7, !"Dwarf Version", i32 5}
// CHECK:STDOUT: !3 = !{i32 2, !"Debug Info Version", i32 3}
// CHECK:STDOUT: !7 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
// CHECK:STDOUT: !8 = !{null, !7}
// CHECK:STDOUT: !9 = !DISubroutineType(types: !8)
// CHECK:STDOUT: !12 = !{!7, !7}
// CHECK:STDOUT: !13 = !DISubroutineType(types: !12)
// CHECK:STDOUT: !16 = !DIFile(filename: "{{.*}}/prelude/types/optional.carbon", directory: "")
// CHECK:STDOUT: !457 = !DIFile(filename: "copy_pointer.carbon", directory: "")
// CHECK:STDOUT: !458 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !457, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !459 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6b633cf020343e69:core.Destroy.Core", scope: null, file: !16, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !458, retainedNodes: !462)
// CHECK:STDOUT: !460 = !DILocalVariable(arg: 1, scope: !459, type: !7)
// CHECK:STDOUT: !461 = !DILocation(line: 189, column: 19, scope: !459)
// CHECK:STDOUT: !462 = !{!460}
// CHECK:STDOUT: !463 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !457, line: 5, type: !13, spFlags: DISPFlagDefinition, unit: !458, retainedNodes: !470)
// CHECK:STDOUT: !464 = !DILocalVariable(arg: 1, scope: !463, type: !7)
// CHECK:STDOUT: !468 = !DILocation(line: 6, column: 10, scope: !463)
// CHECK:STDOUT: !469 = !DILocation(line: 6, column: 3, scope: !463)
// CHECK:STDOUT: !470 = !{!464}
// CHECK:STDOUT: !471 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Optional.24b7347a93330e68.Core:Copy.Core.3e2e92aa38469608", scope: null, file: !16, line: 51, type: !13, spFlags: DISPFlagDefinition, unit: !458, retainedNodes: !479)
// CHECK:STDOUT: !472 = !DILocalVariable(arg: 1, scope: !471, type: !7)
// CHECK:STDOUT: !478 = !DILocation(line: 52, column: 5, scope: !471)
// CHECK:STDOUT: !479 = !{!472}
// CHECK:STDOUT:
