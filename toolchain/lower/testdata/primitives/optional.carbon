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
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT: @const.anon = internal constant { ptr, i64 } { ptr @0, i64 57 }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.d088c7eb746488be:core.Destroy.Core"(ptr %self) #0 !dbg !17 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !19
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core"(ptr %self) #0 !dbg !21 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !23
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.729fca203337f92a:core.Destroy.Core"(ptr %self) #0 !dbg !25 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !27
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %self) #0 !dbg !29 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !31
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CConvert.Main(ptr sret(<{ i32, i1 }>) %return, ptr %o) #0 !dbg !33 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.HasValue.call = call i1 @_CHasValue.Optional.Core.6e9e957697159b53(ptr %o), !dbg !38
// CHECK:STDOUT:   br i1 %Optional.HasValue.call, label %if.then, label %if.else, !dbg !39
// CHECK:STDOUT:
// CHECK:STDOUT: if.then:                                          ; preds = %entry
// CHECK:STDOUT:   %Optional.Get.call = call ptr @_CGet.Optional.Core.6e9e957697159b53(ptr %o), !dbg !40
// CHECK:STDOUT:   %.loc5_12.2 = load i32, ptr %Optional.Get.call, align 4, !dbg !41
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr %return, i32 %.loc5_12.2), !dbg !42
// CHECK:STDOUT:   ret void, !dbg !42
// CHECK:STDOUT:
// CHECK:STDOUT: if.else:                                          ; preds = %entry
// CHECK:STDOUT:   call void @_CNone.Optional.Core.3530343734a6ea27(ptr %return), !dbg !45
// CHECK:STDOUT:   ret void, !dbg !48
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CAddOrRemoveConst.Main(i32 %a, i32 %b) #0 !dbg !50 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %_.var.loc11 = alloca <{ i32, i1 }>, align 4, !dbg !55
// CHECK:STDOUT:   %_.var.loc12 = alloca <{ i32, i1 }>, align 4, !dbg !58
// CHECK:STDOUT:   %_.var.loc13 = alloca <{ i32, i1 }>, align 4, !dbg !61
// CHECK:STDOUT:   %_.var.loc14 = alloca <{ i32, i1 }>, align 4, !dbg !64
// CHECK:STDOUT:   %_.var.loc15 = alloca <{ i32, i1 }>, align 4, !dbg !67
// CHECK:STDOUT:   %_.var.loc16 = alloca <{ i32, i1 }>, align 4, !dbg !70
// CHECK:STDOUT:   %_.var.loc17 = alloca <{ i32, i1 }>, align 4, !dbg !73
// CHECK:STDOUT:   %_.var.loc18 = alloca <{ i32, i1 }>, align 4, !dbg !76
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc11), !dbg !55
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr %_.var.loc11, i32 %a), !dbg !55
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc12), !dbg !58
// CHECK:STDOUT:   call void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.27a2d1ef6dd68465"(ptr %_.var.loc12, i32 %a), !dbg !58
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc13), !dbg !61
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224"(ptr %_.var.loc13, i32 %a), !dbg !61
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc14), !dbg !64
// CHECK:STDOUT:   call void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.bc0e935618dc3a96"(ptr %_.var.loc14, i32 %a), !dbg !64
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc15), !dbg !67
// CHECK:STDOUT:   call void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.27a2d1ef6dd68465"(ptr %_.var.loc15, i32 %b), !dbg !67
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc16), !dbg !70
// CHECK:STDOUT:   call void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.9f04190beae22821"(ptr %_.var.loc16, i32 %b), !dbg !70
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc17), !dbg !73
// CHECK:STDOUT:   call void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.bc0e935618dc3a96"(ptr %_.var.loc17, i32 %b), !dbg !73
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %_.var.loc18), !dbg !76
// CHECK:STDOUT:   call void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.342679e541375c77"(ptr %_.var.loc18, i32 %b), !dbg !76
// CHECK:STDOUT:   call void @"_CSelfDestruct.b90699303d3716f5:core.Destroy.Core"(ptr %_.var.loc18), !dbg !76
// CHECK:STDOUT:   call void @"_CSelfDestruct.60848ede08716e91:core.Destroy.Core"(ptr %_.var.loc17), !dbg !73
// CHECK:STDOUT:   call void @"_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core"(ptr %_.var.loc16), !dbg !70
// CHECK:STDOUT:   call void @"_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core"(ptr %_.var.loc15), !dbg !67
// CHECK:STDOUT:   call void @"_CSelfDestruct.b90699303d3716f5:core.Destroy.Core"(ptr %_.var.loc14), !dbg !64
// CHECK:STDOUT:   call void @"_CSelfDestruct.60848ede08716e91:core.Destroy.Core"(ptr %_.var.loc13), !dbg !61
// CHECK:STDOUT:   call void @"_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core"(ptr %_.var.loc12), !dbg !58
// CHECK:STDOUT:   call void @"_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core"(ptr %_.var.loc11), !dbg !55
// CHECK:STDOUT:   ret void, !dbg !79
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.6a8d754fe1453eab:core.Destroy.Core"(ptr %self) #0 !dbg !81 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !83
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6a8d754fe1453eab:core.Destroy.Core"(ptr %self) #0 !dbg !85 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.6a8d754fe1453eab:core.Destroy.Core"(ptr %self), !dbg !87
// CHECK:STDOUT:   ret void, !dbg !87
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.60848ede08716e91:core.Destroy.Core"(ptr %self) #0 !dbg !89 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.1e4cbd19640430db(ptr %self), !dbg !91
// CHECK:STDOUT:   ret void, !dbg !91
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.60848ede08716e91:core.Destroy.Core"(ptr %self) #0 !dbg !93 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.60848ede08716e91:core.Destroy.Core"(ptr %self), !dbg !95
// CHECK:STDOUT:   ret void, !dbg !95
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.b90699303d3716f5:core.Destroy.Core"(ptr %self) #0 !dbg !97 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.1e4cbd19640430db(ptr %self), !dbg !99
// CHECK:STDOUT:   ret void, !dbg !99
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.b90699303d3716f5:core.Destroy.Core"(ptr %self) #0 !dbg !101 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.b90699303d3716f5:core.Destroy.Core"(ptr %self), !dbg !103
// CHECK:STDOUT:   ret void, !dbg !103
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.0acefe5e4ad33694:core.Destroy.Core"(ptr %self) #0 !dbg !105 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.a41a0c411b53943e(ptr %self), !dbg !107
// CHECK:STDOUT:   ret void, !dbg !107
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core"(ptr %self) #0 !dbg !109 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.0acefe5e4ad33694:core.Destroy.Core"(ptr %self), !dbg !111
// CHECK:STDOUT:   ret void, !dbg !111
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSubobjectDestroy.65ac38c7f841b05c:core.Destroy.Core"(ptr %self) #0 !dbg !113 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @_CSelfDestruct.Destroy.Core.a41a0c411b53943e(ptr %self), !dbg !115
// CHECK:STDOUT:   ret void, !dbg !115
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core"(ptr %self) #0 !dbg !117 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_CSubobjectDestroy.65ac38c7f841b05c:core.Destroy.Core"(ptr %self), !dbg !119
// CHECK:STDOUT:   ret void, !dbg !119
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @_CHasValue.Optional.Core.6e9e957697159b53(ptr %self) #0 !dbg !124 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %self), !dbg !130
// CHECK:STDOUT:   ret i1 %1, !dbg !131
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @_CGet.Optional.Core.6e9e957697159b53(ptr %self) #0 !dbg !133 {
// CHECK:STDOUT:   %1 = call i1 @_CHasValue.Optional.Core.6e9e957697159b53(ptr %self), !dbg !138
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !139
// CHECK:STDOUT:   br i1 %2, label %3, label %5, !dbg !140
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %fail_stop.load = load { ptr, i64 }, ptr @const.anon, align 8, !dbg !141
// CHECK:STDOUT:   %fail_stop.ptr = extractvalue { ptr, i64 } %fail_stop.load, 0, !dbg !141
// CHECK:STDOUT:   %fail_stop.size = extractvalue { ptr, i64 } %fail_stop.load, 1, !dbg !141
// CHECK:STDOUT:   %4 = call i64 @write(i32 2, ptr %fail_stop.ptr, i64 %fail_stop.size), !dbg !141
// CHECK:STDOUT:   call void @abort(), !dbg !141
// CHECK:STDOUT:   br label %5, !dbg !142
// CHECK:STDOUT:
// CHECK:STDOUT: 5:                                                ; preds = %3, %0
// CHECK:STDOUT:   %6 = call ptr @"_CGet.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %self), !dbg !144
// CHECK:STDOUT:   ret ptr %6, !dbg !145
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !147 {
// CHECK:STDOUT:   call void @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.3530343734a6ea27"(ptr %return, i32 %self), !dbg !152
// CHECK:STDOUT:   ret void, !dbg !153
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CNone.Optional.Core.3530343734a6ea27(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !155 {
// CHECK:STDOUT:   call void @"_CNone.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %return), !dbg !158
// CHECK:STDOUT:   ret void, !dbg !159
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
// CHECK:STDOUT: declare void @llvm.lifetime.start.p0(ptr captures(none)) #1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.27a2d1ef6dd68465"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !161 {
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr %return, i32 %self), !dbg !166
// CHECK:STDOUT:   ret void, !dbg !167
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !169 {
// CHECK:STDOUT:   call void @"_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.dd5a2a74150e1fc7"(ptr %return, i32 %self), !dbg !174
// CHECK:STDOUT:   ret void, !dbg !175
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.bc0e935618dc3a96"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !177 {
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224"(ptr %return, i32 %self), !dbg !182
// CHECK:STDOUT:   ret void, !dbg !183
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.27a2d1ef6dd68465"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !185 {
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843"(ptr %return, i32 %self), !dbg !191
// CHECK:STDOUT:   ret void, !dbg !192
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.9f04190beae22821"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !194 {
// CHECK:STDOUT:   call void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.27a2d1ef6dd68465"(ptr %return, i32 %self), !dbg !200
// CHECK:STDOUT:   ret void, !dbg !201
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.bc0e935618dc3a96"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !203 {
// CHECK:STDOUT:   call void @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224"(ptr %return, i32 %self), !dbg !209
// CHECK:STDOUT:   ret void, !dbg !210
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.342679e541375c77"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !212 {
// CHECK:STDOUT:   call void @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.bc0e935618dc3a96"(ptr %return, i32 %self), !dbg !218
// CHECK:STDOUT:   ret void, !dbg !219
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.1e4cbd19640430db(ptr %self) #0 !dbg !222 {
// CHECK:STDOUT:   call void @"_COp.DefaultOptionalStorage.b1aeb9ebf60f2c6e.Core:Destroy.Core.cd77d7fbcb14a7c2"(ptr %self), !dbg !225
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.1e4cbd19640430db(ptr %self), !dbg !226
// CHECK:STDOUT:   ret void, !dbg !227
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSelfDestruct.Destroy.Core.a41a0c411b53943e(ptr %self) #0 !dbg !229 {
// CHECK:STDOUT:   call void @"_COp.DefaultOptionalStorage.b1aeb9ebf60f2c6e.Core:Destroy.Core.d4057e3ae48c02cc"(ptr %self), !dbg !232
// CHECK:STDOUT:   call void @_CSubobjectDestroy.Destroy.Core.1e4cbd19640430db(ptr %self), !dbg !233
// CHECK:STDOUT:   ret void, !dbg !234
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %value) #0 !dbg !236 {
// CHECK:STDOUT:   %1 = icmp eq ptr %value, null, !dbg !242
// CHECK:STDOUT:   %2 = xor i1 %1, true, !dbg !243
// CHECK:STDOUT:   ret i1 %2, !dbg !244
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare i64 @write(i32, ptr, i64)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: noreturn
// CHECK:STDOUT: declare void @abort() #2
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_CGet.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba"(ptr %value) #0 !dbg !246 {
// CHECK:STDOUT:   ret ptr %value, !dbg !252
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.3530343734a6ea27"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !254 {
// CHECK:STDOUT:   call void @_CSome.Optional.Core.3530343734a6ea27(ptr %return, i32 %self), !dbg !260
// CHECK:STDOUT:   ret void, !dbg !261
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNone.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr sret(<{ i32, i1 }>) %return) #0 !dbg !263 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !270
// CHECK:STDOUT:   store i8 0, ptr %has_value, align 1, !dbg !270
// CHECK:STDOUT:   ret void, !dbg !271
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.dd5a2a74150e1fc7"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !272 {
// CHECK:STDOUT:   %temp = alloca i32, align 4, !dbg !277
// CHECK:STDOUT:   call void @llvm.lifetime.start.p0(ptr %temp), !dbg !277
// CHECK:STDOUT:   %1 = call i32 @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.ba7abeb9eee545e2"(i32 %self), !dbg !277
// CHECK:STDOUT:   store i32 %1, ptr %temp, align 4, !dbg !277
// CHECK:STDOUT:   %2 = load i32, ptr %temp, align 4, !dbg !277
// CHECK:STDOUT:   call void @_CSome.Optional.Core.00b00ea46fa3b046(ptr %return, i32 %2), !dbg !278
// CHECK:STDOUT:   call void @"_CSelfDestruct.6a8d754fe1453eab:core.Destroy.Core"(ptr %temp), !dbg !277
// CHECK:STDOUT:   ret void, !dbg !279
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.DefaultOptionalStorage.b1aeb9ebf60f2c6e.Core:Destroy.Core.cd77d7fbcb14a7c2"(ptr %self) #0 !dbg !281 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !284
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !284
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !284
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !285
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !286
// CHECK:STDOUT:   call void @"_CSelfDestruct.6a8d754fe1453eab:core.Destroy.Core"(ptr %value), !dbg !287
// CHECK:STDOUT:   br label %4, !dbg !288
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %3, %0
// CHECK:STDOUT:   ret void, !dbg !289
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSubobjectDestroy.Destroy.Core.1e4cbd19640430db(ptr %self) #0 !dbg !291 {
// CHECK:STDOUT:   ret void, !dbg !294
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.DefaultOptionalStorage.b1aeb9ebf60f2c6e.Core:Destroy.Core.d4057e3ae48c02cc"(ptr %self) #0 !dbg !296 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 1, !dbg !299
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !299
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !299
// CHECK:STDOUT:   br i1 %2, label %3, label %4, !dbg !300
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %self, i32 0, i32 0, !dbg !301
// CHECK:STDOUT:   call void @"_CSelfDestruct.f58524831c37807e:core.Destroy.Core"(ptr %value), !dbg !302
// CHECK:STDOUT:   br label %4, !dbg !303
// CHECK:STDOUT:
// CHECK:STDOUT: 4:                                                ; preds = %3, %0
// CHECK:STDOUT:   ret void, !dbg !304
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Core.3530343734a6ea27(ptr sret(<{ i32, i1 }>) %return, i32 %value) #0 !dbg !311 {
// CHECK:STDOUT:   call void @"_CSome.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr %return, i32 %value), !dbg !316
// CHECK:STDOUT:   ret void, !dbg !317
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.ba7abeb9eee545e2"(i32 %self) #0 !dbg !319 {
// CHECK:STDOUT:   %1 = call i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %self), !dbg !324
// CHECK:STDOUT:   ret i32 %1, !dbg !327
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @_CSome.Optional.Core.00b00ea46fa3b046(ptr sret(<{ i32, i1 }>) %return, i32 %value) #0 !dbg !329 {
// CHECK:STDOUT:   call void @"_CSome.74becf39533834ee:OptionalStorage.Core.cd77d7fbcb14a7c2"(ptr %return, i32 %value), !dbg !334
// CHECK:STDOUT:   ret void, !dbg !335
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !337 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 0, !dbg !346
// CHECK:STDOUT:   store i32 %self, ptr %value, align 4, !dbg !346
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !348
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !348
// CHECK:STDOUT:   ret void, !dbg !349
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044"(i32 %self) #0 !dbg !352 {
// CHECK:STDOUT:   %1 = call i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self), !dbg !357
// CHECK:STDOUT:   ret i32 %1, !dbg !359
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.74becf39533834ee:OptionalStorage.Core.cd77d7fbcb14a7c2"(ptr sret(<{ i32, i1 }>) %return, i32 %self) #0 !dbg !361 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 0, !dbg !370
// CHECK:STDOUT:   %1 = call i32 @"_COp.a7c16f707f533a23:Copy.Core.4d6ceefeb7f772f4"(i32 %self), !dbg !371
// CHECK:STDOUT:   store i32 %1, ptr %value, align 4, !dbg !370
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw <{ i32, i1 }>, ptr %return, i32 0, i32 1, !dbg !372
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !372
// CHECK:STDOUT:   ret void, !dbg !373
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8"(i32 %self) #0 !dbg !375 {
// CHECK:STDOUT:   ret i32 %self, !dbg !381
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i32 @"_COp.a7c16f707f533a23:Copy.Core.4d6ceefeb7f772f4"(i32 %self) #0 !dbg !384 {
// CHECK:STDOUT:   ret i32 %self, !dbg !391
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; uselistorder directives
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.60848ede08716e91:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.b90699303d3716f5:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core", { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @"_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843", { 0, 1, 3, 2 }
// CHECK:STDOUT: uselistorder ptr @llvm.lifetime.start.p0, { 0, 8, 7, 6, 5, 4, 3, 2, 1 }
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.1e4cbd19640430db, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSelfDestruct.Destroy.Core.a41a0c411b53943e, { 1, 0 }
// CHECK:STDOUT: uselistorder ptr @_CSubobjectDestroy.Destroy.Core.1e4cbd19640430db, { 1, 0 }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT: attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
// CHECK:STDOUT: attributes #2 = { noreturn }
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
// CHECK:STDOUT: !21 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0f866e2c9731ba7d:core.Destroy.Core", scope: null, file: !16, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !24)
// CHECK:STDOUT: !22 = !DILocalVariable(arg: 1, scope: !21, type: !7)
// CHECK:STDOUT: !23 = !DILocation(line: 189, column: 19, scope: !21)
// CHECK:STDOUT: !24 = !{!22}
// CHECK:STDOUT: !25 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.729fca203337f92a:core.Destroy.Core", scope: null, file: !16, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !28)
// CHECK:STDOUT: !26 = !DILocalVariable(arg: 1, scope: !25, type: !7)
// CHECK:STDOUT: !27 = !DILocation(line: 189, column: 19, scope: !25)
// CHECK:STDOUT: !28 = !{!26}
// CHECK:STDOUT: !29 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.f58524831c37807e:core.Destroy.Core", scope: null, file: !4, line: 3, type: !11, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !32)
// CHECK:STDOUT: !30 = !DILocalVariable(arg: 1, scope: !29, type: !6)
// CHECK:STDOUT: !31 = !DILocation(line: 3, column: 39, scope: !29)
// CHECK:STDOUT: !32 = !{!30}
// CHECK:STDOUT: !33 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.Main", scope: null, file: !4, line: 3, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !49)
// CHECK:STDOUT: !34 = !DILocalVariable(arg: 1, scope: !33, type: !7)
// CHECK:STDOUT: !38 = !DILocation(line: 4, column: 7, scope: !33)
// CHECK:STDOUT: !39 = !DILocation(line: 4, column: 6, scope: !33)
// CHECK:STDOUT: !40 = !DILocation(line: 5, column: 13, scope: !33)
// CHECK:STDOUT: !41 = !DILocation(line: 5, column: 12, scope: !33)
// CHECK:STDOUT: !42 = !DILocation(line: 5, column: 5, scope: !33)
// CHECK:STDOUT: !43 = !{!7, !6}
// CHECK:STDOUT: !44 = !DISubroutineType(types: !43)
// CHECK:STDOUT: !45 = !DILocation(line: 7, column: 10, scope: !33)
// CHECK:STDOUT: !46 = !{!7}
// CHECK:STDOUT: !47 = !DISubroutineType(types: !46)
// CHECK:STDOUT: !48 = !DILocation(line: 7, column: 3, scope: !33)
// CHECK:STDOUT: !49 = !{!34}
// CHECK:STDOUT: !50 = distinct !DISubprogram(name: "AddOrRemoveConst", linkageName: "_CAddOrRemoveConst.Main", scope: null, file: !4, line: 10, type: !15, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !80)
// CHECK:STDOUT: !51 = !DILocalVariable(arg: 1, scope: !50, type: !6)
// CHECK:STDOUT: !52 = !DILocalVariable(arg: 2, scope: !50, type: !6)
// CHECK:STDOUT: !55 = !DILocation(line: 11, column: 3, scope: !50)
// CHECK:STDOUT: !58 = !DILocation(line: 12, column: 3, scope: !50)
// CHECK:STDOUT: !61 = !DILocation(line: 13, column: 3, scope: !50)
// CHECK:STDOUT: !64 = !DILocation(line: 14, column: 3, scope: !50)
// CHECK:STDOUT: !67 = !DILocation(line: 15, column: 3, scope: !50)
// CHECK:STDOUT: !70 = !DILocation(line: 16, column: 3, scope: !50)
// CHECK:STDOUT: !73 = !DILocation(line: 17, column: 3, scope: !50)
// CHECK:STDOUT: !76 = !DILocation(line: 18, column: 3, scope: !50)
// CHECK:STDOUT: !79 = !DILocation(line: 10, column: 1, scope: !50)
// CHECK:STDOUT: !80 = !{!51, !52}
// CHECK:STDOUT: !81 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.6a8d754fe1453eab:core.Destroy.Core", scope: null, file: !4, line: 13, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !84)
// CHECK:STDOUT: !82 = !DILocalVariable(arg: 1, scope: !81, type: !7)
// CHECK:STDOUT: !83 = !DILocation(line: 13, column: 10, scope: !81)
// CHECK:STDOUT: !84 = !{!82}
// CHECK:STDOUT: !85 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6a8d754fe1453eab:core.Destroy.Core", scope: null, file: !4, line: 13, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !88)
// CHECK:STDOUT: !86 = !DILocalVariable(arg: 1, scope: !85, type: !7)
// CHECK:STDOUT: !87 = !DILocation(line: 13, column: 10, scope: !85)
// CHECK:STDOUT: !88 = !{!86}
// CHECK:STDOUT: !89 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.60848ede08716e91:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !92)
// CHECK:STDOUT: !90 = !DILocalVariable(arg: 1, scope: !89, type: !7)
// CHECK:STDOUT: !91 = !DILocation(line: 18, column: 3, scope: !89)
// CHECK:STDOUT: !92 = !{!90}
// CHECK:STDOUT: !93 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.60848ede08716e91:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !96)
// CHECK:STDOUT: !94 = !DILocalVariable(arg: 1, scope: !93, type: !7)
// CHECK:STDOUT: !95 = !DILocation(line: 18, column: 3, scope: !93)
// CHECK:STDOUT: !96 = !{!94}
// CHECK:STDOUT: !97 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.b90699303d3716f5:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !100)
// CHECK:STDOUT: !98 = !DILocalVariable(arg: 1, scope: !97, type: !7)
// CHECK:STDOUT: !99 = !DILocation(line: 18, column: 3, scope: !97)
// CHECK:STDOUT: !100 = !{!98}
// CHECK:STDOUT: !101 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.b90699303d3716f5:core.Destroy.Core", scope: null, file: !4, line: 18, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !104)
// CHECK:STDOUT: !102 = !DILocalVariable(arg: 1, scope: !101, type: !7)
// CHECK:STDOUT: !103 = !DILocation(line: 18, column: 3, scope: !101)
// CHECK:STDOUT: !104 = !{!102}
// CHECK:STDOUT: !105 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.0acefe5e4ad33694:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !108)
// CHECK:STDOUT: !106 = !DILocalVariable(arg: 1, scope: !105, type: !7)
// CHECK:STDOUT: !107 = !DILocation(line: 16, column: 3, scope: !105)
// CHECK:STDOUT: !108 = !{!106}
// CHECK:STDOUT: !109 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.0acefe5e4ad33694:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !112)
// CHECK:STDOUT: !110 = !DILocalVariable(arg: 1, scope: !109, type: !7)
// CHECK:STDOUT: !111 = !DILocation(line: 16, column: 3, scope: !109)
// CHECK:STDOUT: !112 = !{!110}
// CHECK:STDOUT: !113 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.65ac38c7f841b05c:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !116)
// CHECK:STDOUT: !114 = !DILocalVariable(arg: 1, scope: !113, type: !7)
// CHECK:STDOUT: !115 = !DILocation(line: 16, column: 3, scope: !113)
// CHECK:STDOUT: !116 = !{!114}
// CHECK:STDOUT: !117 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.65ac38c7f841b05c:core.Destroy.Core", scope: null, file: !4, line: 16, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !120)
// CHECK:STDOUT: !118 = !DILocalVariable(arg: 1, scope: !117, type: !7)
// CHECK:STDOUT: !119 = !DILocation(line: 16, column: 3, scope: !117)
// CHECK:STDOUT: !120 = !{!118}
// CHECK:STDOUT: !124 = distinct !DISubprogram(name: "HasValue", linkageName: "_CHasValue.Optional.Core.6e9e957697159b53", scope: null, file: !16, line: 37, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !132)
// CHECK:STDOUT: !125 = !DILocalVariable(arg: 1, scope: !124, type: !7)
// CHECK:STDOUT: !130 = !DILocation(line: 38, column: 12, scope: !124)
// CHECK:STDOUT: !131 = !DILocation(line: 38, column: 5, scope: !124)
// CHECK:STDOUT: !132 = !{!125}
// CHECK:STDOUT: !133 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.Optional.Core.6e9e957697159b53", scope: null, file: !16, line: 40, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !146)
// CHECK:STDOUT: !134 = !DILocalVariable(arg: 1, scope: !133, type: !7)
// CHECK:STDOUT: !138 = !DILocation(line: 303, column: 11, scope: !133)
// CHECK:STDOUT: !139 = !DILocation(line: 303, column: 7, scope: !133)
// CHECK:STDOUT: !140 = !DILocation(line: 303, column: 6, scope: !133)
// CHECK:STDOUT: !141 = !DILocation(line: 304, column: 5, scope: !133)
// CHECK:STDOUT: !142 = !DILocation(line: 303, column: 3, scope: !133)
// CHECK:STDOUT: !144 = !DILocation(line: 306, column: 10, scope: !133)
// CHECK:STDOUT: !145 = !DILocation(line: 306, column: 3, scope: !133)
// CHECK:STDOUT: !146 = !{!134}
// CHECK:STDOUT: !147 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.9eebcd25770b8843", scope: null, file: !16, line: 130, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !154)
// CHECK:STDOUT: !148 = !DILocalVariable(arg: 1, scope: !147, type: !6)
// CHECK:STDOUT: !152 = !DILocation(line: 131, column: 12, scope: !147)
// CHECK:STDOUT: !153 = !DILocation(line: 131, column: 5, scope: !147)
// CHECK:STDOUT: !154 = !{!148}
// CHECK:STDOUT: !155 = distinct !DISubprogram(name: "None", linkageName: "_CNone.Optional.Core.3530343734a6ea27", scope: null, file: !16, line: 31, type: !47, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !158 = !DILocation(line: 32, column: 12, scope: !155)
// CHECK:STDOUT: !159 = !DILocation(line: 32, column: 5, scope: !155)
// CHECK:STDOUT: !160 = !DIFile(filename: "{{.*}}/prelude/operators/as.carbon", directory: "")
// CHECK:STDOUT: !161 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.27a2d1ef6dd68465", scope: null, file: !160, line: 43, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !168)
// CHECK:STDOUT: !162 = !DILocalVariable(arg: 1, scope: !161, type: !6)
// CHECK:STDOUT: !166 = !DILocation(line: 43, column: 40, scope: !161)
// CHECK:STDOUT: !167 = !DILocation(line: 43, column: 33, scope: !161)
// CHECK:STDOUT: !168 = !{!162}
// CHECK:STDOUT: !169 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.538322f9fda4254f:ImplicitAs.a276ba298c70ba87.Core.5cec6441aa655224", scope: null, file: !16, line: 130, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !176)
// CHECK:STDOUT: !170 = !DILocalVariable(arg: 1, scope: !169, type: !6)
// CHECK:STDOUT: !174 = !DILocation(line: 131, column: 12, scope: !169)
// CHECK:STDOUT: !175 = !DILocation(line: 131, column: 5, scope: !169)
// CHECK:STDOUT: !176 = !{!170}
// CHECK:STDOUT: !177 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.bc0e935618dc3a96", scope: null, file: !160, line: 43, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !184)
// CHECK:STDOUT: !178 = !DILocalVariable(arg: 1, scope: !177, type: !6)
// CHECK:STDOUT: !182 = !DILocation(line: 43, column: 40, scope: !177)
// CHECK:STDOUT: !183 = !DILocation(line: 43, column: 33, scope: !177)
// CHECK:STDOUT: !184 = !{!178}
// CHECK:STDOUT: !185 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.27a2d1ef6dd68465", scope: null, file: !160, line: 47, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !193)
// CHECK:STDOUT: !186 = !DILocalVariable(arg: 1, scope: !185, type: !6)
// CHECK:STDOUT: !191 = !DILocation(line: 47, column: 34, scope: !185)
// CHECK:STDOUT: !192 = !DILocation(line: 47, column: 27, scope: !185)
// CHECK:STDOUT: !193 = !{!186}
// CHECK:STDOUT: !194 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.9f04190beae22821", scope: null, file: !160, line: 47, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !202)
// CHECK:STDOUT: !195 = !DILocalVariable(arg: 1, scope: !194, type: !6)
// CHECK:STDOUT: !200 = !DILocation(line: 47, column: 34, scope: !194)
// CHECK:STDOUT: !201 = !DILocation(line: 47, column: 27, scope: !194)
// CHECK:STDOUT: !202 = !{!195}
// CHECK:STDOUT: !203 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.bc0e935618dc3a96", scope: null, file: !160, line: 47, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !211)
// CHECK:STDOUT: !204 = !DILocalVariable(arg: 1, scope: !203, type: !6)
// CHECK:STDOUT: !209 = !DILocation(line: 47, column: 34, scope: !203)
// CHECK:STDOUT: !210 = !DILocation(line: 47, column: 27, scope: !203)
// CHECK:STDOUT: !211 = !{!204}
// CHECK:STDOUT: !212 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.c18e58a62bf591fb:ImplicitAs.eb057aa32837c84e.Core.342679e541375c77", scope: null, file: !160, line: 47, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !220)
// CHECK:STDOUT: !213 = !DILocalVariable(arg: 1, scope: !212, type: !6)
// CHECK:STDOUT: !218 = !DILocation(line: 47, column: 34, scope: !212)
// CHECK:STDOUT: !219 = !DILocation(line: 47, column: 27, scope: !212)
// CHECK:STDOUT: !220 = !{!213}
// CHECK:STDOUT: !221 = !DIFile(filename: "{{.*}}/prelude/destroy.carbon", directory: "")
// CHECK:STDOUT: !222 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.1e4cbd19640430db", scope: null, file: !221, line: 26, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !228)
// CHECK:STDOUT: !223 = !DILocalVariable(arg: 1, scope: !222, type: !7)
// CHECK:STDOUT: !225 = !DILocation(line: 27, column: 5, scope: !222)
// CHECK:STDOUT: !226 = !DILocation(line: 28, column: 5, scope: !222)
// CHECK:STDOUT: !227 = !DILocation(line: 26, column: 3, scope: !222)
// CHECK:STDOUT: !228 = !{!223}
// CHECK:STDOUT: !229 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.Destroy.Core.a41a0c411b53943e", scope: null, file: !221, line: 26, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !235)
// CHECK:STDOUT: !230 = !DILocalVariable(arg: 1, scope: !229, type: !7)
// CHECK:STDOUT: !232 = !DILocation(line: 27, column: 5, scope: !229)
// CHECK:STDOUT: !233 = !DILocation(line: 28, column: 5, scope: !229)
// CHECK:STDOUT: !234 = !DILocation(line: 26, column: 3, scope: !229)
// CHECK:STDOUT: !235 = !{!230}
// CHECK:STDOUT: !236 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba", scope: null, file: !16, line: 197, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !245)
// CHECK:STDOUT: !237 = !DILocalVariable(arg: 1, scope: !236, type: !7)
// CHECK:STDOUT: !242 = !DILocation(line: 198, column: 16, scope: !236)
// CHECK:STDOUT: !243 = !DILocation(line: 198, column: 12, scope: !236)
// CHECK:STDOUT: !244 = !DILocation(line: 198, column: 5, scope: !236)
// CHECK:STDOUT: !245 = !{!237}
// CHECK:STDOUT: !246 = distinct !DISubprogram(name: "Get", linkageName: "_CGet.e8f8f92d3d08d149:OptionalStorage.Core.84588f41d61dafba", scope: null, file: !16, line: 200, type: !13, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !253)
// CHECK:STDOUT: !247 = !DILocalVariable(arg: 1, scope: !246, type: !7)
// CHECK:STDOUT: !252 = !DILocation(line: 201, column: 5, scope: !246)
// CHECK:STDOUT: !253 = !{!247}
// CHECK:STDOUT: !254 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.9fdaf39d07a1dc4e:OptionalAs.24b7347a93330e68.Core.3530343734a6ea27", scope: null, file: !16, line: 105, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !262)
// CHECK:STDOUT: !255 = !DILocalVariable(arg: 1, scope: !254, type: !6)
// CHECK:STDOUT: !260 = !DILocation(line: 106, column: 12, scope: !254)
// CHECK:STDOUT: !261 = !DILocation(line: 106, column: 5, scope: !254)
// CHECK:STDOUT: !262 = !{!255}
// CHECK:STDOUT: !263 = distinct !DISubprogram(name: "None", linkageName: "_CNone.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !16, line: 150, type: !47, spFlags: DISPFlagDefinition, unit: !5)
// CHECK:STDOUT: !270 = !DILocation(line: 153, column: 5, scope: !263)
// CHECK:STDOUT: !271 = !DILocation(line: 154, column: 5, scope: !263)
// CHECK:STDOUT: !272 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.d62727437df45535:OptionalAs.1dac4564233fecd1.Core.dd5a2a74150e1fc7", scope: null, file: !16, line: 112, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !280)
// CHECK:STDOUT: !273 = !DILocalVariable(arg: 1, scope: !272, type: !6)
// CHECK:STDOUT: !277 = !DILocation(line: 113, column: 29, scope: !272)
// CHECK:STDOUT: !278 = !DILocation(line: 113, column: 12, scope: !272)
// CHECK:STDOUT: !279 = !DILocation(line: 113, column: 5, scope: !272)
// CHECK:STDOUT: !280 = !{!273}
// CHECK:STDOUT: !281 = distinct !DISubprogram(name: "Op", linkageName: "_COp.DefaultOptionalStorage.b1aeb9ebf60f2c6e.Core:Destroy.Core.cd77d7fbcb14a7c2", scope: null, file: !16, line: 284, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !290)
// CHECK:STDOUT: !282 = !DILocalVariable(arg: 1, scope: !281, type: !7)
// CHECK:STDOUT: !284 = !DILocation(line: 285, column: 9, scope: !281)
// CHECK:STDOUT: !285 = !DILocation(line: 285, column: 8, scope: !281)
// CHECK:STDOUT: !286 = !DILocation(line: 286, column: 8, scope: !281)
// CHECK:STDOUT: !287 = !DILocation(line: 286, column: 7, scope: !281)
// CHECK:STDOUT: !288 = !DILocation(line: 285, column: 5, scope: !281)
// CHECK:STDOUT: !289 = !DILocation(line: 284, column: 3, scope: !281)
// CHECK:STDOUT: !290 = !{!282}
// CHECK:STDOUT: !291 = distinct !DISubprogram(name: "SubobjectDestroy", linkageName: "_CSubobjectDestroy.Destroy.Core.1e4cbd19640430db", scope: null, file: !221, line: 19, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !295)
// CHECK:STDOUT: !292 = !DILocalVariable(arg: 1, scope: !291, type: !7)
// CHECK:STDOUT: !294 = !DILocation(line: 19, column: 3, scope: !291)
// CHECK:STDOUT: !295 = !{!292}
// CHECK:STDOUT: !296 = distinct !DISubprogram(name: "Op", linkageName: "_COp.DefaultOptionalStorage.b1aeb9ebf60f2c6e.Core:Destroy.Core.d4057e3ae48c02cc", scope: null, file: !16, line: 284, type: !9, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !305)
// CHECK:STDOUT: !297 = !DILocalVariable(arg: 1, scope: !296, type: !7)
// CHECK:STDOUT: !299 = !DILocation(line: 285, column: 9, scope: !296)
// CHECK:STDOUT: !300 = !DILocation(line: 285, column: 8, scope: !296)
// CHECK:STDOUT: !301 = !DILocation(line: 286, column: 8, scope: !296)
// CHECK:STDOUT: !302 = !DILocation(line: 286, column: 7, scope: !296)
// CHECK:STDOUT: !303 = !DILocation(line: 285, column: 5, scope: !296)
// CHECK:STDOUT: !304 = !DILocation(line: 284, column: 3, scope: !296)
// CHECK:STDOUT: !305 = !{!297}
// CHECK:STDOUT: !311 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.3530343734a6ea27", scope: null, file: !16, line: 34, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !318)
// CHECK:STDOUT: !312 = !DILocalVariable(arg: 1, scope: !311, type: !6)
// CHECK:STDOUT: !316 = !DILocation(line: 35, column: 12, scope: !311)
// CHECK:STDOUT: !317 = !DILocation(line: 35, column: 5, scope: !311)
// CHECK:STDOUT: !318 = !{!312}
// CHECK:STDOUT: !319 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.ef077c075a7e2432:ImplicitAs.ad22d1bbc0605210.Core.ba7abeb9eee545e2", scope: null, file: !160, line: 43, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !328)
// CHECK:STDOUT: !320 = !DILocalVariable(arg: 1, scope: !319, type: !6)
// CHECK:STDOUT: !324 = !DILocation(line: 43, column: 40, scope: !319)
// CHECK:STDOUT: !325 = !{!6, !6}
// CHECK:STDOUT: !326 = !DISubroutineType(types: !325)
// CHECK:STDOUT: !327 = !DILocation(line: 43, column: 33, scope: !319)
// CHECK:STDOUT: !328 = !{!320}
// CHECK:STDOUT: !329 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.Optional.Core.00b00ea46fa3b046", scope: null, file: !16, line: 34, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !336)
// CHECK:STDOUT: !330 = !DILocalVariable(arg: 1, scope: !329, type: !6)
// CHECK:STDOUT: !334 = !DILocation(line: 35, column: 12, scope: !329)
// CHECK:STDOUT: !335 = !DILocation(line: 35, column: 5, scope: !329)
// CHECK:STDOUT: !336 = !{!330}
// CHECK:STDOUT: !337 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.74becf39533834ee:OptionalStorage.Core.d4057e3ae48c02cc", scope: null, file: !16, line: 156, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !350)
// CHECK:STDOUT: !338 = !DILocalVariable(arg: 1, scope: !337, type: !6)
// CHECK:STDOUT: !346 = !DILocation(line: 162, column: 5, scope: !337)
// CHECK:STDOUT: !348 = !DILocation(line: 163, column: 5, scope: !337)
// CHECK:STDOUT: !349 = !DILocation(line: 164, column: 5, scope: !337)
// CHECK:STDOUT: !350 = !{!338}
// CHECK:STDOUT: !351 = !DIFile(filename: "{{.*}}/prelude/types/int.carbon", directory: "")
// CHECK:STDOUT: !352 = distinct !DISubprogram(name: "Convert", linkageName: "_CConvert.45e1f8de18643ddf:ImplicitAs.0bc6489996802dd4.Core.bb469f8924cce044", scope: null, file: !351, line: 64, type: !326, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !360)
// CHECK:STDOUT: !353 = !DILocalVariable(arg: 1, scope: !352, type: !6)
// CHECK:STDOUT: !357 = !DILocation(line: 66, column: 17, scope: !352)
// CHECK:STDOUT: !359 = !DILocation(line: 66, column: 5, scope: !352)
// CHECK:STDOUT: !360 = !{!353}
// CHECK:STDOUT: !361 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.74becf39533834ee:OptionalStorage.Core.cd77d7fbcb14a7c2", scope: null, file: !16, line: 156, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !374)
// CHECK:STDOUT: !362 = !DILocalVariable(arg: 1, scope: !361, type: !6)
// CHECK:STDOUT: !370 = !DILocation(line: 162, column: 5, scope: !361)
// CHECK:STDOUT: !371 = !DILocation(line: 162, column: 28, scope: !361)
// CHECK:STDOUT: !372 = !DILocation(line: 163, column: 5, scope: !361)
// CHECK:STDOUT: !373 = !DILocation(line: 164, column: 5, scope: !361)
// CHECK:STDOUT: !374 = !{!362}
// CHECK:STDOUT: !375 = distinct !DISubprogram(name: "AsInt", linkageName: "_CAsInt.Int.9452f4c51951679b.Core:AnyInt.Core.be1e879c1ad406d8", scope: null, file: !351, line: 59, type: !326, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !382)
// CHECK:STDOUT: !376 = !DILocalVariable(arg: 1, scope: !375, type: !6)
// CHECK:STDOUT: !381 = !DILocation(line: 59, column: 28, scope: !375)
// CHECK:STDOUT: !382 = !{!376}
// CHECK:STDOUT: !383 = !DIFile(filename: "{{.*}}/prelude/copy.carbon", directory: "")
// CHECK:STDOUT: !384 = distinct !DISubprogram(name: "Op", linkageName: "_COp.a7c16f707f533a23:Copy.Core.4d6ceefeb7f772f4", scope: null, file: !383, line: 23, type: !44, spFlags: DISPFlagDefinition, unit: !5, retainedNodes: !392)
// CHECK:STDOUT: !385 = !DILocalVariable(arg: 1, scope: !384, type: !6)
// CHECK:STDOUT: !391 = !DILocation(line: 23, column: 25, scope: !384)
// CHECK:STDOUT: !392 = !{!385}
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'copy.carbon'
// CHECK:STDOUT: source_filename = "copy.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_COp.Copyable.Main:Copy.Core"(ptr sret({}), ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.cb8adced19392b99:core.Destroy.Core"(ptr %self) #0 !dbg !395 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !397
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.bb3dd30fa3a4aa62:core.Destroy.Core"(ptr %self) #0 !dbg !399 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !401
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define void @_CF.Main(ptr sret({ {}, i1 }) %return, ptr %c) #0 !dbg !403 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   call void @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.a2b7303f9ef09f31"(ptr %return, ptr %c), !dbg !408
// CHECK:STDOUT:   ret void, !dbg !409
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.a2b7303f9ef09f31"(ptr sret({ {}, i1 }) %return, ptr %self) #0 !dbg !411 {
// CHECK:STDOUT:   call void @"_CCopy.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %return, ptr %self), !dbg !417
// CHECK:STDOUT:   ret void, !dbg !418
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CCopy.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr sret({ {}, i1 }) %return, ptr %value) #0 !dbg !420 {
// CHECK:STDOUT:   %1 = call i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %value), !dbg !426
// CHECK:STDOUT:   br i1 %1, label %2, label %3, !dbg !427
// CHECK:STDOUT:
// CHECK:STDOUT: 2:                                                ; preds = %0
// CHECK:STDOUT:   %value1 = getelementptr inbounds nuw { {}, i1 }, ptr %value, i32 0, i32 0, !dbg !428
// CHECK:STDOUT:   call void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %return, ptr %value1), !dbg !429
// CHECK:STDOUT:   ret void, !dbg !430
// CHECK:STDOUT:
// CHECK:STDOUT: 3:                                                ; preds = %0
// CHECK:STDOUT:   call void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %return), !dbg !431
// CHECK:STDOUT:   ret void, !dbg !432
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr i1 @"_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr %value) #0 !dbg !434 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw { {}, i1 }, ptr %value, i32 0, i32 1, !dbg !439
// CHECK:STDOUT:   %1 = load i8, ptr %has_value, align 1, !dbg !439
// CHECK:STDOUT:   %2 = trunc i8 %1 to i1, !dbg !439
// CHECK:STDOUT:   ret i1 %2, !dbg !440
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr sret({ {}, i1 }) %return, ptr %self) #0 !dbg !442 {
// CHECK:STDOUT:   %value = getelementptr inbounds nuw { {}, i1 }, ptr %return, i32 0, i32 0, !dbg !451
// CHECK:STDOUT:   call void @"_COp.Copyable.Main:Copy.Core"(ptr %value, ptr %self), !dbg !452
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw { {}, i1 }, ptr %return, i32 0, i32 1, !dbg !453
// CHECK:STDOUT:   store i8 1, ptr %has_value, align 1, !dbg !453
// CHECK:STDOUT:   ret void, !dbg !454
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr void @"_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c"(ptr sret({ {}, i1 }) %return) #0 !dbg !456 {
// CHECK:STDOUT:   %has_value = getelementptr inbounds nuw { {}, i1 }, ptr %return, i32 0, i32 1, !dbg !463
// CHECK:STDOUT:   store i8 0, ptr %has_value, align 1, !dbg !463
// CHECK:STDOUT:   ret void, !dbg !464
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!394}
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
// CHECK:STDOUT: !46 = !{!7}
// CHECK:STDOUT: !47 = !DISubroutineType(types: !46)
// CHECK:STDOUT: !393 = !DIFile(filename: "copy.carbon", directory: "")
// CHECK:STDOUT: !394 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !393, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !395 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.cb8adced19392b99:core.Destroy.Core", scope: null, file: !393, line: 9, type: !9, spFlags: DISPFlagDefinition, unit: !394, retainedNodes: !398)
// CHECK:STDOUT: !396 = !DILocalVariable(arg: 1, scope: !395, type: !7)
// CHECK:STDOUT: !397 = !DILocation(line: 9, column: 9, scope: !395)
// CHECK:STDOUT: !398 = !{!396}
// CHECK:STDOUT: !399 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.bb3dd30fa3a4aa62:core.Destroy.Core", scope: null, file: !393, line: 9, type: !9, spFlags: DISPFlagDefinition, unit: !394, retainedNodes: !402)
// CHECK:STDOUT: !400 = !DILocalVariable(arg: 1, scope: !399, type: !7)
// CHECK:STDOUT: !401 = !DILocation(line: 9, column: 9, scope: !399)
// CHECK:STDOUT: !402 = !{!400}
// CHECK:STDOUT: !403 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !393, line: 9, type: !13, spFlags: DISPFlagDefinition, unit: !394, retainedNodes: !410)
// CHECK:STDOUT: !404 = !DILocalVariable(arg: 1, scope: !403, type: !7)
// CHECK:STDOUT: !408 = !DILocation(line: 11, column: 10, scope: !403)
// CHECK:STDOUT: !409 = !DILocation(line: 11, column: 3, scope: !403)
// CHECK:STDOUT: !410 = !{!404}
// CHECK:STDOUT: !411 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Optional.24b7347a93330e68.Core:Copy.Core.a2b7303f9ef09f31", scope: null, file: !16, line: 51, type: !13, spFlags: DISPFlagDefinition, unit: !394, retainedNodes: !419)
// CHECK:STDOUT: !412 = !DILocalVariable(arg: 1, scope: !411, type: !7)
// CHECK:STDOUT: !417 = !DILocation(line: 52, column: 12, scope: !411)
// CHECK:STDOUT: !418 = !DILocation(line: 52, column: 5, scope: !411)
// CHECK:STDOUT: !419 = !{!412}
// CHECK:STDOUT: !420 = distinct !DISubprogram(name: "Copy", linkageName: "_CCopy.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c", scope: null, file: !16, line: 172, type: !13, spFlags: DISPFlagDefinition, unit: !394, retainedNodes: !433)
// CHECK:STDOUT: !421 = !DILocalVariable(arg: 1, scope: !420, type: !7)
// CHECK:STDOUT: !426 = !DILocation(line: 173, column: 9, scope: !420)
// CHECK:STDOUT: !427 = !DILocation(line: 173, column: 8, scope: !420)
// CHECK:STDOUT: !428 = !DILocation(line: 174, column: 15, scope: !420)
// CHECK:STDOUT: !429 = !DILocation(line: 174, column: 14, scope: !420)
// CHECK:STDOUT: !430 = !DILocation(line: 174, column: 7, scope: !420)
// CHECK:STDOUT: !431 = !DILocation(line: 176, column: 14, scope: !420)
// CHECK:STDOUT: !432 = !DILocation(line: 176, column: 7, scope: !420)
// CHECK:STDOUT: !433 = !{!421}
// CHECK:STDOUT: !434 = distinct !DISubprogram(name: "Has", linkageName: "_CHas.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c", scope: null, file: !16, line: 166, type: !13, spFlags: DISPFlagDefinition, unit: !394, retainedNodes: !441)
// CHECK:STDOUT: !435 = !DILocalVariable(arg: 1, scope: !434, type: !7)
// CHECK:STDOUT: !439 = !DILocation(line: 167, column: 12, scope: !434)
// CHECK:STDOUT: !440 = !DILocation(line: 167, column: 5, scope: !434)
// CHECK:STDOUT: !441 = !{!435}
// CHECK:STDOUT: !442 = distinct !DISubprogram(name: "Some", linkageName: "_CSome.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c", scope: null, file: !16, line: 156, type: !13, spFlags: DISPFlagDefinition, unit: !394, retainedNodes: !455)
// CHECK:STDOUT: !443 = !DILocalVariable(arg: 1, scope: !442, type: !7)
// CHECK:STDOUT: !451 = !DILocation(line: 162, column: 5, scope: !442)
// CHECK:STDOUT: !452 = !DILocation(line: 162, column: 28, scope: !442)
// CHECK:STDOUT: !453 = !DILocation(line: 163, column: 5, scope: !442)
// CHECK:STDOUT: !454 = !DILocation(line: 164, column: 5, scope: !442)
// CHECK:STDOUT: !455 = !{!443}
// CHECK:STDOUT: !456 = distinct !DISubprogram(name: "None", linkageName: "_CNone.5d6f3f3a4b44a8f1:OptionalStorage.Core.d34df0287397e90c", scope: null, file: !16, line: 150, type: !47, spFlags: DISPFlagDefinition, unit: !394)
// CHECK:STDOUT: !463 = !DILocation(line: 153, column: 5, scope: !456)
// CHECK:STDOUT: !464 = !DILocation(line: 154, column: 5, scope: !456)
// CHECK:STDOUT:
// CHECK:STDOUT: ; ---
// CHECK:STDOUT: ; ModuleID = 'copy_pointer.carbon'
// CHECK:STDOUT: source_filename = "copy_pointer.carbon"
// CHECK:STDOUT:
// CHECK:STDOUT: @0 = private unnamed_addr constant [58 x i8] c"carbon: Core.Optional.Get on an empty value; terminating\0A\00", align 1
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.6b633cf020343e69:core.Destroy.Core"(ptr %self) #0 !dbg !467 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !469
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.9e8d469caadb0631:core.Destroy.Core"(ptr %self) #0 !dbg !471 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !473
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define weak_odr void @"_CSelfDestruct.ffad4029e410f0b3:core.Destroy.Core"(ptr %self) #0 !dbg !475 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   ret void, !dbg !477
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define ptr @_CF.Main(ptr %c) #0 !dbg !479 {
// CHECK:STDOUT: entry:
// CHECK:STDOUT:   %Optional.as.Copy.impl.Op.call = call ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.3e2e92aa38469608"(ptr %c), !dbg !484
// CHECK:STDOUT:   ret ptr %Optional.as.Copy.impl.Op.call, !dbg !485
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: ; Function Attrs: nounwind
// CHECK:STDOUT: define linkonce_odr ptr @"_COp.Optional.24b7347a93330e68.Core:Copy.Core.3e2e92aa38469608"(ptr %self) #0 !dbg !487 {
// CHECK:STDOUT:   ret ptr %self, !dbg !494
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: declare void @"_CSelfDestruct.48e0adf639fe7af4:core.Destroy.Core"(ptr)
// CHECK:STDOUT:
// CHECK:STDOUT: attributes #0 = { nounwind }
// CHECK:STDOUT:
// CHECK:STDOUT: !llvm.dbg.cu = !{!466}
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
// CHECK:STDOUT: !465 = !DIFile(filename: "copy_pointer.carbon", directory: "")
// CHECK:STDOUT: !466 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, file: !465, producer: "carbon", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
// CHECK:STDOUT: !467 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.6b633cf020343e69:core.Destroy.Core", scope: null, file: !16, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !466, retainedNodes: !470)
// CHECK:STDOUT: !468 = !DILocalVariable(arg: 1, scope: !467, type: !7)
// CHECK:STDOUT: !469 = !DILocation(line: 189, column: 19, scope: !467)
// CHECK:STDOUT: !470 = !{!468}
// CHECK:STDOUT: !471 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.9e8d469caadb0631:core.Destroy.Core", scope: null, file: !16, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !466, retainedNodes: !474)
// CHECK:STDOUT: !472 = !DILocalVariable(arg: 1, scope: !471, type: !7)
// CHECK:STDOUT: !473 = !DILocation(line: 189, column: 19, scope: !471)
// CHECK:STDOUT: !474 = !{!472}
// CHECK:STDOUT: !475 = distinct !DISubprogram(name: "SelfDestruct", linkageName: "_CSelfDestruct.ffad4029e410f0b3:core.Destroy.Core", scope: null, file: !16, line: 189, type: !9, spFlags: DISPFlagDefinition, unit: !466, retainedNodes: !478)
// CHECK:STDOUT: !476 = !DILocalVariable(arg: 1, scope: !475, type: !7)
// CHECK:STDOUT: !477 = !DILocation(line: 189, column: 19, scope: !475)
// CHECK:STDOUT: !478 = !{!476}
// CHECK:STDOUT: !479 = distinct !DISubprogram(name: "F", linkageName: "_CF.Main", scope: null, file: !465, line: 5, type: !13, spFlags: DISPFlagDefinition, unit: !466, retainedNodes: !486)
// CHECK:STDOUT: !480 = !DILocalVariable(arg: 1, scope: !479, type: !7)
// CHECK:STDOUT: !484 = !DILocation(line: 6, column: 10, scope: !479)
// CHECK:STDOUT: !485 = !DILocation(line: 6, column: 3, scope: !479)
// CHECK:STDOUT: !486 = !{!480}
// CHECK:STDOUT: !487 = distinct !DISubprogram(name: "Op", linkageName: "_COp.Optional.24b7347a93330e68.Core:Copy.Core.3e2e92aa38469608", scope: null, file: !16, line: 51, type: !13, spFlags: DISPFlagDefinition, unit: !466, retainedNodes: !495)
// CHECK:STDOUT: !488 = !DILocalVariable(arg: 1, scope: !487, type: !7)
// CHECK:STDOUT: !494 = !DILocation(line: 52, column: 5, scope: !487)
// CHECK:STDOUT: !495 = !{!488}
// CHECK:STDOUT:
