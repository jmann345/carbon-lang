// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/let/let_else.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/let/let_else.carbon

// `let`-`else` (W-012, fork/design-sprint/if-let.md Option A): the pattern's
// test branches `let.then`/`let.else`; the else block is emitted first and
// must not complete normally (F-011a: its end is unreachable); the bind pass
// runs in the success block, and the bindings are ordinary bindings of the
// ENCLOSING scope.

// --- alternative_payload.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(e: OptInt) -> i32 {
  let .Some(port: i32) = e else { return -1; }
  return port;
}
//@dump-sem-ir-end

// --- alternative_bare.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(e: OptInt) -> i32 {
  let .None = e else { return -1; }
  return 0;
}
//@dump-sem-ir-end

// --- tuple.carbon
library "[[@TEST_NAME]]";

//@dump-sem-ir-begin
fn F(pair: (i32, i32)) -> i32 {
  let (0, n: i32) = pair else { return -1; }
  return n;
}
//@dump-sem-ir-end

// --- var_else.carbon
library "[[@TEST_NAME]]";

// The var-alternative lane: mutable on-demand storage in the success block,
// mutated after the declaration.
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(o: OptInt) -> i32 {
  var .Some(v: i32) = o else { return 0; }
  v = v + 1;
  return v;
}
//@dump-sem-ir-end

// --- break_in_loop.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(o: OptInt) -> i32 {
  var total: i32 = 0;
  while (true) {
    let .Some(n: i32) = o else { break; }
    total = total + n;
    if (total > 10) {
      break;
    }
  }
  return total;
}
//@dump-sem-ir-end

// --- continue_in_loop.carbon
library "[[@TEST_NAME]]";

choice OptInt {
  Some(x: i32),
  None
}
fn Next(n: i32) -> OptInt {
  if (n > 0) {
    return OptInt.Some(n - 1);
  }
  return OptInt.None;
}

//@dump-sem-ir-begin
fn F() -> i32 {
  var i: i32 = 0;
  var total: i32 = 0;
  while (i < 3) {
    i = i + 1;
    let .Some(n: i32) = Next(i) else { continue; }
    total = total + n;
  }
  return total;
}
//@dump-sem-ir-end

// --- nested_all_paths_return.carbon
library "[[@TEST_NAME]]";

// Accepted under F-011a: every path through the else block diverges, so its
// end is unreachable.
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(o: OptInt, c: bool) -> i32 {
  let .Some(n: i32) = o else {
    if (c) {
      return 1;
    } else {
      return 2;
    }
  }
  return n;
}
//@dump-sem-ir-end

// --- let_else_in_match_arm_body.carbon
library "[[@TEST_NAME]]";

// Nested refutable contexts push and pop their own state (LIFO).
choice OptInt {
  Some(x: i32),
  None
}

//@dump-sem-ir-begin
fn F(x: i32, o: OptInt) -> i32 {
  match (x) {
    case 0 => {
      let .Some(n: i32) = o else { return -1; }
      return n;
    }
    default => { return 0; }
  }
  return -2;
}
//@dump-sem-ir-end

// --- two_in_sequence.carbon
library "[[@TEST_NAME]]";

// The second declaration's initializer uses the first's binding.
choice OptInt {
  Some(x: i32),
  None
}

fn Wrap(n: i32) -> OptInt { return OptInt.Some(n); }

//@dump-sem-ir-begin
fn F(o: OptInt) -> i32 {
  let .Some(a: i32) = o else { return -1; }
  let .Some(b: i32) = Wrap(a) else { return -2; }
  return b;
}
//@dump-sem-ir-end

// CHECK:STDOUT: --- alternative_payload.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OptInt: type = class_type @OptInt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %pattern_type.6e3: type = pattern_type %OptInt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %e.param_patt: %pattern_type.6e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %e.patt: %pattern_type.6e3 = wrapper_binding_pattern e, %e.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %port.patt: %pattern_type.6b6 = value_binding_pattern port [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.bf2: %pattern_type.e71 = tuple_pattern (%port.patt) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %e.param_patt: %pattern_type.6e3 = value_param_pattern [concrete = constants.%e.param_patt]
// CHECK:STDOUT:     %e.patt: %pattern_type.6e3 = wrapper_binding_pattern e, %e.param_patt [concrete = constants.%e.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc9 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9: Core.Form = init_form %i32.loc9 [concrete = constants.%.795f]
// CHECK:STDOUT:     %e.param: %OptInt = value_param call_param0
// CHECK:STDOUT:     %OptInt.ref: type = name_ref OptInt, file.%OptInt.decl [concrete = constants.%OptInt]
// CHECK:STDOUT:     %e: %OptInt = wrapper_binding e, %e.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%e.param: %OptInt) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %e.ref: %OptInt = name_ref e, %e
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %port.patt: %pattern_type.6b6 = value_binding_pattern port [concrete = constants.%port.patt]
// CHECK:STDOUT:     %.loc10_17: %pattern_type.e71 = tuple_pattern (%port.patt) [concrete = constants.%.bf2]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc10_28.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc10_28.1: <bound method> = bound_method %int_0, %impl.elem0.loc10_28.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc10_28.1: <specific function> = specific_function %impl.elem0.loc10_28.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc10_28.2: <bound method> = bound_method %int_0, %specific_fn.loc10_28.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_28: init %u1 = call %bound_method.loc10_28.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc10_28.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_28 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc10_28.2: %u1 = converted %int_0, %.loc10_28.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc10_28.3: ref %u1 = class_element_access %e.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc10_28.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc10_28.3: <bound method> = bound_method %.loc10_28.2, %impl.elem0.loc10_28.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc10_28.2: <specific function> = specific_function %impl.elem0.loc10_28.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc10_28.4: <bound method> = bound_method %.loc10_28.2, %specific_fn.loc10_28.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc10_28.4: %u1 = acquire_value %.loc10_28.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc10_28.4(%.loc10_28.2, %.loc10_28.4)
// CHECK:STDOUT:   %.loc10_28.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc10_28.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc10_28.5
// CHECK:STDOUT:   if %.loc10_28.6 br !let.then else br !let.else
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc10_42: <bound method> = bound_method %int_1, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc10_42(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc10_44: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_44.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc10_44 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc10_44: <specific function> = specific_function %impl.elem0.loc10_44, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc10_44.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc10_44 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc10_42.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc10_42.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc10_42.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_44: init %i32 = call %bound_method.loc10_44.2(%.loc10_42.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc10_44: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_44 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc10_44
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then:
// CHECK:STDOUT:   %.loc10_3.1: ref %.e8e = class_element_access %e.ref, element1
// CHECK:STDOUT:   %.loc10_3.2: ref %tuple.type.a8a = class_element_access %.loc10_3.1, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc10_3.2, element0
// CHECK:STDOUT:   %.loc10_3.3: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %port: %i32 = wrapper_binding port, %.loc10_3.3
// CHECK:STDOUT:   %port.ref: %i32 = name_ref port, %port
// CHECK:STDOUT:   %impl.elem0.loc11: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc11_10.1: <bound method> = bound_method %port.ref, %impl.elem0.loc11
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_10.2: <bound method> = bound_method %port.ref, %specific_fn.loc11
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc11_10.2(%port.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- alternative_bare.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OptInt: type = class_type @OptInt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %pattern_type.6e3: type = pattern_type %OptInt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %bound_method.d7a: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_1.233: %u1 = int_value 1 [concrete]
// CHECK:STDOUT:   %e.param_patt: %pattern_type.6e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %e.patt: %pattern_type.6e3 = wrapper_binding_pattern e, %e.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.a82: <bound method> = bound_method %int_1.233, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %e.param_patt: %pattern_type.6e3 = value_param_pattern [concrete = constants.%e.param_patt]
// CHECK:STDOUT:     %e.patt: %pattern_type.6e3 = wrapper_binding_pattern e, %e.param_patt [concrete = constants.%e.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %e.param: %OptInt = value_param call_param0
// CHECK:STDOUT:     %OptInt.ref: type = name_ref OptInt, file.%OptInt.decl [concrete = constants.%OptInt]
// CHECK:STDOUT:     %e: %OptInt = wrapper_binding e, %e.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%e.param: %OptInt) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %e.ref: %OptInt = name_ref e, %e
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     <elided>
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_1.loc10_17: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc10_17.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc10_17.1: <bound method> = bound_method %int_1.loc10_17, %impl.elem0.loc10_17.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.320]
// CHECK:STDOUT:   %specific_fn.loc10_17.1: <specific function> = specific_function %impl.elem0.loc10_17.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc10_17.2: <bound method> = bound_method %int_1.loc10_17, %specific_fn.loc10_17.1 [concrete = constants.%bound_method.d7a]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_17: init %u1 = call %bound_method.loc10_17.2(%int_1.loc10_17) [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc10_17.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_17 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc10_17.2: %u1 = converted %int_1.loc10_17, %.loc10_17.1 [concrete = constants.%int_1.233]
// CHECK:STDOUT:   %.loc10_17.3: ref %u1 = class_element_access %e.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc10_17.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc10_17.3: <bound method> = bound_method %.loc10_17.2, %impl.elem0.loc10_17.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc10_17.2: <specific function> = specific_function %impl.elem0.loc10_17.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc10_17.4: <bound method> = bound_method %.loc10_17.2, %specific_fn.loc10_17.2 [concrete = constants.%bound_method.a82]
// CHECK:STDOUT:   %.loc10_17.4: %u1 = acquire_value %.loc10_17.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc10_17.4(%.loc10_17.2, %.loc10_17.4)
// CHECK:STDOUT:   %.loc10_17.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc10_17.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc10_17.5
// CHECK:STDOUT:   if %.loc10_17.6 br !let.then else br !let.else
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else:
// CHECK:STDOUT:   %int_1.loc10_32: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc10_31: <bound method> = bound_method %int_1.loc10_32, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc10_31(%int_1.loc10_32) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc10_33: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_33.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc10_33 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc10_33: <specific function> = specific_function %impl.elem0.loc10_33, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc10_33.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc10_33 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc10_31.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc10_31.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc10_31.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_33: init %i32 = call %bound_method.loc10_33.2(%.loc10_31.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc10_33: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10_33 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc10_33
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc11: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_11.1: <bound method> = bound_method %int_0, %impl.elem0.loc11 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc11: <specific function> = specific_function %impl.elem0.loc11, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc11_11.2: <bound method> = bound_method %int_0, %specific_fn.loc11 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11: init %i32 = call %bound_method.loc11_11.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc11: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc11 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc11
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- tuple.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %tuple.type.693: type = tuple_type (type, type) [concrete]
// CHECK:STDOUT:   %tuple.94e: %tuple.type.693 = tuple_value (%i32, %i32) [concrete]
// CHECK:STDOUT:   %tuple.type.e55: type = tuple_type (%i32, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.394: type = pattern_type %tuple.type.e55 [concrete]
// CHECK:STDOUT:   %pair.param_patt: %pattern_type.394 = value_param_pattern [concrete]
// CHECK:STDOUT:   %pair.patt: %pattern_type.394 = wrapper_binding_pattern pair, %pair.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %tuple.type.94b: type = tuple_type (Core.IntLiteral, %i32) [concrete]
// CHECK:STDOUT:   %pattern_type.106: type = pattern_type %tuple.type.94b [concrete]
// CHECK:STDOUT:   %.a1f: %pattern_type.106 = tuple_pattern (@F.%expr_patt, %n.patt) [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.e051da.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.b3bca7.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.e051da.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %bound_method.b3bca7.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound: <bound method> = bound_method %int_1, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %pair.param_patt: %pattern_type.394 = value_param_pattern [concrete = constants.%pair.param_patt]
// CHECK:STDOUT:     %pair.patt: %pattern_type.394 = wrapper_binding_pattern pair, %pair.param_patt [concrete = constants.%pair.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc4_27 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc4_27: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc4_27: Core.Form = init_form %i32.loc4_27 [concrete = constants.%.795f]
// CHECK:STDOUT:     %pair.param: %tuple.type.e55 = value_param call_param0
// CHECK:STDOUT:     %.loc4_21.1: type = splice_block %.loc4_21.3 [concrete = constants.%tuple.type.e55] {
// CHECK:STDOUT:       %i32.loc4_13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %i32.loc4_18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:       %.loc4_21.2: %tuple.type.693 = tuple_literal (%i32.loc4_13, %i32.loc4_18) [concrete = constants.%tuple.94e]
// CHECK:STDOUT:       %.loc4_21.3: type = converted %.loc4_21.2, constants.%tuple.type.e55 [concrete = constants.%tuple.type.e55]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %pair: %tuple.type.e55 = wrapper_binding pair, %pair.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%pair.param: %tuple.type.e55) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %pair.ref: %tuple.type.e55 = name_ref pair, %pair
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.dc0 = expr_pattern %int_0 in [concrete] {
// CHECK:STDOUT:       %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     }
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:     %.loc5_17: %pattern_type.106 = tuple_pattern (%expr_patt, %n.patt) [concrete = constants.%.a1f]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %tuple.elem0: %i32 = tuple_access %pair.ref, element0
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc5_26: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc5_26.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_26 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.e051da.1]
// CHECK:STDOUT:   %specific_fn.loc5_26: <specific function> = specific_function %impl.elem0.loc5_26, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc5_26.2: <bound method> = bound_method %int_0, %specific_fn.loc5_26 [concrete = constants.%bound_method.b3bca7.1]
// CHECK:STDOUT:   %.loc5_26.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc5_26.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.e051da.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc5_26.3: <bound method> = bound_method %int_0, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.b3bca7.2]
// CHECK:STDOUT:   %impl.elem0.loc5_8: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc5_8.1: <bound method> = bound_method %int_0, %impl.elem0.loc5_8 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc5_8: <specific function> = specific_function %impl.elem0.loc5_8, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_8.2: <bound method> = bound_method %int_0, %specific_fn.loc5_8 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_8: init %i32 = call %bound_method.loc5_8.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc5_8.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_8 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc5_8.2: %i32 = converted %int_0, %.loc5_8.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc5_26.3(%.loc5_8.2, %tuple.elem0)
// CHECK:STDOUT:   %.loc5_26.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc5_26.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc5_26.2
// CHECK:STDOUT:   if %.loc5_26.3 br !let.then else br !let.else
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc5_40: <bound method> = bound_method %int_1, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc5_40(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc5_42: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc5_42.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc5_42 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc5_42: <specific function> = specific_function %impl.elem0.loc5_42, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc5_42.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc5_42 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc5_40.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc5_40.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc5_40.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_42: init %i32 = call %bound_method.loc5_42.2(%.loc5_40.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc5_42: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc5_42 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc5_42
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then:
// CHECK:STDOUT:   %tuple.elem1: %i32 = tuple_access %pair.ref, element1
// CHECK:STDOUT:   %i32.loc5: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %n: %i32 = wrapper_binding n, %tuple.elem1
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %impl.elem0.loc6: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc6_10.1: <bound method> = bound_method %n.ref, %impl.elem0.loc6
// CHECK:STDOUT:   %specific_fn.loc6: <specific function> = specific_function %impl.elem0.loc6, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc6_10.2: <bound method> = bound_method %n.ref, %specific_fn.loc6
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc6_10.2(%n.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- var_else.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OptInt: type = class_type @OptInt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %pattern_type.6e3: type = pattern_type %OptInt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.00b: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete]
// CHECK:STDOUT:   %.var_patt: %pattern_type.e71 = var_pattern %.00b [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.1: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.1: %Int.as.AddWith.impl.Op.type.1eac76.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.2: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.2: %Int.as.AddWith.impl.Op.type.1eac76.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.aa4: <witness> = impl_witness imports.%AddWith.impl_witness_table.b21, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.1: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.2: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.2: %Int.as.AddWith.impl.Op.type.bddb3c.2 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.3de: %AddWith.type.832 = facet_value %i32, (%AddWith.impl_witness.aa4) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.b60: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(Core.IntLiteral, %AddWith.facet.3de) [concrete]
// CHECK:STDOUT:   %.fbe: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.b60, %AddWith.facet.3de [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.1: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.2, @Int.as.AddWith.impl.Op.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.2: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.1, @Int.as.AddWith.impl.Op.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc12_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12_3.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc12_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc12_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc12_3.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.2 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3a: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.b21 = impl_witness_table (%Core.import_ref.b4fd3a.2, %Core.import_ref.8a3a), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12_3.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc12_3.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc12_3.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc12_3.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc11 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11: Core.Form = init_form %i32.loc11 [concrete = constants.%.795f]
// CHECK:STDOUT:     %o.param: %OptInt = value_param call_param0
// CHECK:STDOUT:     %OptInt.ref: type = name_ref OptInt, file.%OptInt.decl [concrete = constants.%OptInt]
// CHECK:STDOUT:     %o: %OptInt = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%o.param: %OptInt) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.ref: %OptInt = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %v.patt: %pattern_type.6b6 = ref_binding_pattern v [concrete = constants.%v.patt]
// CHECK:STDOUT:     %.loc12_14: %pattern_type.e71 = tuple_pattern (%v.patt) [concrete = constants.%.00b]
// CHECK:STDOUT:     %.var_patt: %pattern_type.e71 = var_pattern %.loc12_14 [concrete = constants.%.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc12_25: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_25.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc12_25.1: <bound method> = bound_method %int_0.loc12_25, %impl.elem0.loc12_25.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc12_25.1: <specific function> = specific_function %impl.elem0.loc12_25.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc12_25.2: <bound method> = bound_method %int_0.loc12_25, %specific_fn.loc12_25.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_25: init %u1 = call %bound_method.loc12_25.2(%int_0.loc12_25) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_25.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_25 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_25.2: %u1 = converted %int_0.loc12_25, %.loc12_25.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_25.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc12_25.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc12_25.3: <bound method> = bound_method %.loc12_25.2, %impl.elem0.loc12_25.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc12_25.2: <specific function> = specific_function %impl.elem0.loc12_25.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc12_25.4: <bound method> = bound_method %.loc12_25.2, %specific_fn.loc12_25.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc12_25.4: %u1 = acquire_value %.loc12_25.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc12_25.4(%.loc12_25.2, %.loc12_25.4)
// CHECK:STDOUT:   %.loc12_25.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc12_25.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc12_25.5
// CHECK:STDOUT:   if %.loc12_25.6 br !let.then else br !let.else
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else:
// CHECK:STDOUT:   %int_0.loc12_39: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_40: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_40.1: <bound method> = bound_method %int_0.loc12_39, %impl.elem0.loc12_40 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc12_40: <specific function> = specific_function %impl.elem0.loc12_40, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc12_40.2: <bound method> = bound_method %int_0.loc12_39, %specific_fn.loc12_40 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_40: init %i32 = call %bound_method.loc12_40.2(%int_0.loc12_39) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc12_40: init %i32 = converted %int_0.loc12_39, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12_40 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc12_40
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then:
// CHECK:STDOUT:   %.loc12_3.1: ref %.e8e = class_element_access %o.ref, element1
// CHECK:STDOUT:   %.loc12_3.2: ref %tuple.type.a8a = class_element_access %.loc12_3.1, element0
// CHECK:STDOUT:   %.var: ref %tuple.type.a8a = var_storage %.var_patt
// CHECK:STDOUT:   %tuple.elem0.loc12_3.1: ref %i32 = tuple_access %.loc12_3.2, element0
// CHECK:STDOUT:   %.loc12_3.3: %i32 = acquire_value %tuple.elem0.loc12_3.1
// CHECK:STDOUT:   %impl.elem0.loc12_3: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc12_3.1: <bound method> = bound_method %.loc12_3.3, %impl.elem0.loc12_3
// CHECK:STDOUT:   %specific_fn.loc12_3: <specific function> = specific_function %impl.elem0.loc12_3, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc12_3.2: <bound method> = bound_method %.loc12_3.3, %specific_fn.loc12_3
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc12: init %i32 = call %bound_method.loc12_3.2(%.loc12_3.3)
// CHECK:STDOUT:   %.loc12_3.4: init %tuple.type.a8a to %.var = tuple_init (%Int.as.Copy.impl.Op.call.loc12)
// CHECK:STDOUT:   %.loc12_3.5: init %tuple.type.a8a = converted %.loc12_3.2, %.loc12_3.4
// CHECK:STDOUT:   assign %.var, %.loc12_3.5
// CHECK:STDOUT:   %tuple.elem0.loc12_3.2: ref %i32 = tuple_access %.var, element0
// CHECK:STDOUT:   %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %v: ref %i32 = wrapper_binding v, %tuple.elem0.loc12_3.2
// CHECK:STDOUT:   %v.ref.loc13_3: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %v.ref.loc13_7: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:   %bound_method.loc13_9.1: <bound method> = bound_method %v.ref.loc13_7, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc13_9: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:   %bound_method.loc13_9.2: <bound method> = bound_method %v.ref.loc13_7, %specific_fn.loc13_9
// CHECK:STDOUT:   %.loc13_7: %i32 = acquire_value %v.ref.loc13_7
// CHECK:STDOUT:   %.loc13_9: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc13_9 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %.loc13_7, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:   %bound_method.loc13_9.3: <bound method> = bound_method %.loc13_7, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc13: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_11.1: <bound method> = bound_method %int_1, %impl.elem0.loc13 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc13_11: <specific function> = specific_function %impl.elem0.loc13, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc13_11.2: <bound method> = bound_method %int_1, %specific_fn.loc13_11 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13: init %i32 = call %bound_method.loc13_11.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc13_11.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc13_11.2: %i32 = converted %int_1, %.loc13_11.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc13_9.3(%.loc13_7, %.loc13_11.2)
// CHECK:STDOUT:   assign %v.ref.loc13_3, %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %v.ref.loc14: ref %i32 = name_ref v, %v
// CHECK:STDOUT:   %.loc14: %i32 = acquire_value %v.ref.loc14
// CHECK:STDOUT:   %impl.elem0.loc14: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_10.1: <bound method> = bound_method %.loc14, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_10.2: <bound method> = bound_method %.loc14, %specific_fn.loc14
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call.loc14: init %i32 = call %bound_method.loc14_10.2(%.loc14)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call.loc14
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_3.1(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_3.1(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc12_3.2(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc12_3.2(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc12_3.2(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- break_in_loop.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OptInt: type = class_type @OptInt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %pattern_type.6e3: type = pattern_type %OptInt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %total.patt: %pattern_type.6b6 = ref_binding_pattern total [concrete]
// CHECK:STDOUT:   %total.var_patt: %pattern_type.6b6 = var_pattern %total.patt [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.4e1: %pattern_type.e71 = tuple_pattern (%n.patt) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.2: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.2 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT:   %int_10.64f: Core.IntLiteral = int_value 10 [concrete]
// CHECK:STDOUT:   %OrderedWith.type.975: type = facet_type <@OrderedWith, @OrderedWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.1: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.1: %Int.as.OrderedWith.impl.Greater.type.18c27f.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.2: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.2: %Int.as.OrderedWith.impl.Greater.type.18c27f.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %OrderedWith.impl_witness.480: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.100, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.1: type = fn_type @Int.as.OrderedWith.impl.Greater.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.1: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.a79f39.2: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.e68ae3.2: %Int.as.OrderedWith.impl.Greater.type.a79f39.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.e90: %OrderedWith.type.975 = facet_value %i32, (%OrderedWith.impl_witness.480) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Greater.type.e1c: type = fn_type @OrderedWith.WithSelf.Greater, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.e90) [concrete]
// CHECK:STDOUT:   %.029: type = fn_type_with_self_type %OrderedWith.WithSelf.Greater.type.e1c, %OrderedWith.facet.e90 [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.2, @Int.as.OrderedWith.impl.Greater.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Greater.e68ae3.1, @Int.as.OrderedWith.impl.Greater.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.1b6: <bound method> = bound_method %int_10.64f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_10.6bf: %i32 = int_value 10 [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfc: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc10 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01: %Destroy.WithSelf.SubobjectDestroy.type.dfc = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef0: type = fn_type @Destroy.WithSelf.Op.loc10 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403: %Destroy.WithSelf.Op.type.ef0 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbc: type = fn_type @Destroy.WithSelf.SelfDestruct.loc10 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3: %Destroy.WithSelf.SelfDestruct.type.fbc = struct_value () [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.0e6 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.f9df = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.100 = impl_witness_table (%Core.import_ref.0e6, %Core.import_ref.f9df, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Greater.28d: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.1 (%Int.as.OrderedWith.impl.Greater.type.18c27f.2) = import_ref Core//prelude/types/int, Greater, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.1 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.2)]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl: %Destroy.WithSelf.SubobjectDestroy.type.dfc = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc10 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl: %Destroy.WithSelf.Op.type.ef0 = fn_decl @Destroy.WithSelf.Op.loc10 [concrete = constants.%Destroy.WithSelf.Op.403] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc9 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9: Core.Form = init_form %i32.loc9 [concrete = constants.%.795f]
// CHECK:STDOUT:     %o.param: %OptInt = value_param call_param0
// CHECK:STDOUT:     %OptInt.ref: type = name_ref OptInt, file.%OptInt.decl [concrete = constants.%OptInt]
// CHECK:STDOUT:     %o: %OptInt = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%o.param: %OptInt) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %total.var: ref %i32 = var_storage %total.var_patt
// CHECK:STDOUT:   %int_0.loc10: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc10: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc10_3.1: <bound method> = bound_method %int_0.loc10, %impl.elem0.loc10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc10: <specific function> = specific_function %impl.elem0.loc10, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc10_3.2: <bound method> = bound_method %int_0.loc10, %specific_fn.loc10 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10: init %i32 = call %bound_method.loc10_3.2(%int_0.loc10) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc10: init %i32 = converted %int_0.loc10, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc10 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   assign %total.var, %.loc10
// CHECK:STDOUT:   %i32.loc10: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %total: ref %i32 = wrapper_binding total, %total.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %total.patt: %pattern_type.6b6 = ref_binding_pattern total [concrete = constants.%total.patt]
// CHECK:STDOUT:     %total.var_patt: %pattern_type.6b6 = var_pattern %total.patt [concrete = constants.%total.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   br !while.cond
// CHECK:STDOUT:
// CHECK:STDOUT: !while.cond:
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   if %true br !while.body else br !while.done
// CHECK:STDOUT:
// CHECK:STDOUT: !while.body:
// CHECK:STDOUT:   %o.ref: %OptInt = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:     %.loc12_16: %pattern_type.e71 = tuple_pattern (%n.patt) [concrete = constants.%.4e1]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc12: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_27.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc12_27.1: <bound method> = bound_method %int_0.loc12, %impl.elem0.loc12_27.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc12_27.1: <specific function> = specific_function %impl.elem0.loc12_27.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc12_27.2: <bound method> = bound_method %int_0.loc12, %specific_fn.loc12_27.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %u1 = call %bound_method.loc12_27.2(%int_0.loc12) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_27.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_27.2: %u1 = converted %int_0.loc12, %.loc12_27.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_27.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc12_27.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc12_27.3: <bound method> = bound_method %.loc12_27.2, %impl.elem0.loc12_27.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc12_27.2: <specific function> = specific_function %impl.elem0.loc12_27.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc12_27.4: <bound method> = bound_method %.loc12_27.2, %specific_fn.loc12_27.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc12_27.4: %u1 = acquire_value %.loc12_27.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc12_27.4(%.loc12_27.2, %.loc12_27.4)
// CHECK:STDOUT:   %.loc12_27.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc12_27.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc12_27.5
// CHECK:STDOUT:   if %.loc12_27.6 br !let.then else br !let.else
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else:
// CHECK:STDOUT:   br !while.done
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then:
// CHECK:STDOUT:   %.loc12_5.1: ref %.e8e = class_element_access %o.ref, element1
// CHECK:STDOUT:   %.loc12_5.2: ref %tuple.type.a8a = class_element_access %.loc12_5.1, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc12_5.2, element0
// CHECK:STDOUT:   %.loc12_5.3: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %n: %i32 = wrapper_binding n, %.loc12_5.3
// CHECK:STDOUT:   %total.ref.loc13_5: ref %i32 = name_ref total, %total
// CHECK:STDOUT:   %total.ref.loc13_13: ref %i32 = name_ref total, %total
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc13_19.1: <bound method> = bound_method %total.ref.loc13_13, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc13: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc13_19.2: <bound method> = bound_method %total.ref.loc13_13, %specific_fn.loc13
// CHECK:STDOUT:   %.loc13: %i32 = acquire_value %total.ref.loc13_13
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc13_19.2(%.loc13, %n.ref)
// CHECK:STDOUT:   assign %total.ref.loc13_5, %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT:   %total.ref.loc14: ref %i32 = name_ref total, %total
// CHECK:STDOUT:   %int_10: Core.IntLiteral = int_value 10 [concrete = constants.%int_10.64f]
// CHECK:STDOUT:   %impl.elem2: %.029 = impl_witness_access constants.%OrderedWith.impl_witness.480, element2 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.2]
// CHECK:STDOUT:   %bound_method.loc14_15.1: <bound method> = bound_method %total.ref.loc14, %impl.elem2
// CHECK:STDOUT:   %specific_fn.loc14_15: <specific function> = specific_function %impl.elem2, @Int.as.OrderedWith.impl.Greater.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.1]
// CHECK:STDOUT:   %bound_method.loc14_15.2: <bound method> = bound_method %total.ref.loc14, %specific_fn.loc14_15
// CHECK:STDOUT:   %.loc14_9: %i32 = acquire_value %total.ref.loc14
// CHECK:STDOUT:   %.loc14_15: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = specific_constant imports.%Core.Greater.28d, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:   %Greater.ref: %Int.as.OrderedWith.impl.Greater.type.a79f39.1 = name_ref Greater, %.loc14_15 [concrete = constants.%Int.as.OrderedWith.impl.Greater.e68ae3.1]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.bound: <bound method> = bound_method %.loc14_9, %Greater.ref
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.specific_fn: <specific function> = specific_function %Greater.ref, @Int.as.OrderedWith.impl.Greater.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Greater.specific_fn.e2f732.2]
// CHECK:STDOUT:   %bound_method.loc14_15.3: <bound method> = bound_method %.loc14_9, %Int.as.OrderedWith.impl.Greater.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_17.1: <bound method> = bound_method %int_10, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.dcb]
// CHECK:STDOUT:   %specific_fn.loc14_17: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_17.2: <bound method> = bound_method %int_10, %specific_fn.loc14_17 [concrete = constants.%bound_method.1b6]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i32 = call %bound_method.loc14_17.2(%int_10) [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:   %.loc14_17.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:   %.loc14_17.2: %i32 = converted %int_10, %.loc14_17.1 [concrete = constants.%int_10.6bf]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.call: init bool = call %bound_method.loc14_15.3(%.loc14_9, %.loc14_17.2)
// CHECK:STDOUT:   %.loc14_19.1: bool = value_of_initializer %Int.as.OrderedWith.impl.Greater.call
// CHECK:STDOUT:   %.loc14_19.2: bool = converted %Int.as.OrderedWith.impl.Greater.call, %.loc14_19.1
// CHECK:STDOUT:   if %.loc14_19.2 br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   br !while.done
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   br !while.cond
// CHECK:STDOUT:
// CHECK:STDOUT: !while.done:
// CHECK:STDOUT:   %total.ref.loc18: ref %i32 = name_ref total, %total
// CHECK:STDOUT:   %.loc18: %i32 = acquire_value %total.ref.loc18
// CHECK:STDOUT:   %impl.elem0.loc18: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc18_10.1: <bound method> = bound_method %.loc18, %impl.elem0.loc18
// CHECK:STDOUT:   %specific_fn.loc18: <specific function> = specific_function %impl.elem0.loc18, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc18_10.2: <bound method> = bound_method %.loc18, %specific_fn.loc18
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc18_10.2(%.loc18)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %total.var, constants.%Destroy.WithSelf.SelfDestruct.db3
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%total.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc10(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc10(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc10(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- continue_in_loop.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OptInt: type = class_type @OptInt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.e99: type = struct_type {.discriminant: %u1, .payload: %.e8e} [concrete]
// CHECK:STDOUT:   %pattern_type.6e3: type = pattern_type %OptInt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %pattern_type.322: type = pattern_type %u1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op.1, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Next.type: type = fn_type @Next [concrete]
// CHECK:STDOUT:   %Next: %Next.type = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.type.975: type = facet_type <@OrderedWith, @OrderedWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.type.18c27f.1: type = fn_type @Int.as.OrderedWith.impl.Greater.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Greater.cbccb6.1: %Int.as.OrderedWith.impl.Greater.type.18c27f.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6605e2.1: type = fn_type @Int.as.OrderedWith.impl.Less.2, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.59643b.1: %Int.as.OrderedWith.impl.Less.type.6605e2.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.6605e2.2: type = fn_type @Int.as.OrderedWith.impl.Less.3, @Int.as.OrderedWith.impl.f36(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.59643b.2: %Int.as.OrderedWith.impl.Less.type.6605e2.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %OrderedWith.impl_witness.480: <witness> = impl_witness imports.%OrderedWith.impl_witness_table.100, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.4f4a1d.1: type = fn_type @Int.as.OrderedWith.impl.Less.3, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.164caf.1: %Int.as.OrderedWith.impl.Less.type.4f4a1d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.type.4f4a1d.2: type = fn_type @Int.as.OrderedWith.impl.Less.2, @Int.as.OrderedWith.impl.f36(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.164caf.2: %Int.as.OrderedWith.impl.Less.type.4f4a1d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %OrderedWith.facet.e90: %OrderedWith.type.975 = facet_value %i32, (%OrderedWith.impl_witness.480) [concrete]
// CHECK:STDOUT:   %OrderedWith.WithSelf.Less.type.3dc: type = fn_type @OrderedWith.WithSelf.Less, @OrderedWith.WithSelf(Core.IntLiteral, %OrderedWith.facet.e90) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %U.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding U, 1 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %i.patt: %pattern_type.6b6 = ref_binding_pattern i [concrete]
// CHECK:STDOUT:   %i.var_patt: %pattern_type.6b6 = var_pattern %i.patt [concrete]
// CHECK:STDOUT:   %total.patt: %pattern_type.6b6 = ref_binding_pattern total [concrete]
// CHECK:STDOUT:   %total.var_patt: %pattern_type.6b6 = var_pattern %total.patt [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %.c7f: type = fn_type_with_self_type %OrderedWith.WithSelf.Less.type.3dc, %OrderedWith.facet.e90 [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn.30cd42.1: <specific function> = specific_function %Int.as.OrderedWith.impl.Less.164caf.2, @Int.as.OrderedWith.impl.Less.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn.30cd42.2: <specific function> = specific_function %Int.as.OrderedWith.impl.Less.164caf.1, @Int.as.OrderedWith.impl.Less.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %AddWith.type.832: type = facet_type <@AddWith, @AddWith(Core.IntLiteral)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.1: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.1: %Int.as.AddWith.impl.Op.type.1eac76.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.1eac76.2: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%N, %U.4e6) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.978dbc.2: %Int.as.AddWith.impl.Op.type.1eac76.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %AddWith.impl_witness.aa4: <witness> = impl_witness imports.%AddWith.impl_witness_table.b21, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.1: type = fn_type @Int.as.AddWith.impl.Op.3, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.1: %Int.as.AddWith.impl.Op.type.bddb3c.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.bddb3c.2: type = fn_type @Int.as.AddWith.impl.Op.2, @Int.as.AddWith.impl.155(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.1fd531.2: %Int.as.AddWith.impl.Op.type.bddb3c.2 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.3de: %AddWith.type.832 = facet_value %i32, (%AddWith.impl_witness.aa4) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.b60: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(Core.IntLiteral, %AddWith.facet.3de) [concrete]
// CHECK:STDOUT:   %.fbe: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.b60, %AddWith.facet.3de [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.1: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.2, @Int.as.AddWith.impl.Op.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.273a3e.2: <specific function> = specific_function %Int.as.AddWith.impl.Op.1fd531.1, @Int.as.AddWith.impl.Op.3(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %n.patt.c48: %pattern_type.6b6 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.4e1: %pattern_type.e71 = tuple_pattern (%n.patt.c48) [concrete]
// CHECK:STDOUT:   %self.param_patt.7c1: %pattern_type.322 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.945: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt.7c1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc20_31.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc20_31.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc20_31.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc20_31.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc20_31.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc20_31.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc20_31.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc20_31.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.409: type = pattern_type %.e8e [concrete]
// CHECK:STDOUT:   %self.param_patt.a48: %pattern_type.409 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.fd2: %pattern_type.409 = wrapper_binding_pattern self, %self.param_patt.a48 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc20_31.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc20_31.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc20_31.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6cf: type = pattern_type %struct_type.discriminant.payload.e99 [concrete]
// CHECK:STDOUT:   %self.param_patt.909: %pattern_type.6cf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.1f0: %pattern_type.6cf = wrapper_binding_pattern self, %self.param_patt.909 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc20_31.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc20_31.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.efd: %pattern_type.6e3 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.b87: %pattern_type.6e3 = wrapper_binding_pattern self, %self.param_patt.efd [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc20_31.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc20_31.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.6: type = fn_type @Destroy.WithSelf.SelfDestruct.loc20_31.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.6: %Destroy.WithSelf.SelfDestruct.type.fbceb5.6 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %AddWith.impl_witness.833: <witness> = impl_witness imports.%AddWith.impl_witness_table.6b4, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.056: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.365: %Int.as.AddWith.impl.Op.type.056 = struct_value () [concrete]
// CHECK:STDOUT:   %AddWith.facet.76a: %AddWith.type.be9 = facet_value %i32, (%AddWith.impl_witness.833) [concrete]
// CHECK:STDOUT:   %AddWith.WithSelf.Op.type.02a: type = fn_type @AddWith.WithSelf.Op, @AddWith.WithSelf(%i32, %AddWith.facet.76a) [concrete]
// CHECK:STDOUT:   %.d47: type = fn_type_with_self_type %AddWith.WithSelf.Op.type.02a, %AddWith.facet.76a [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn.f25: <specific function> = specific_function %Int.as.AddWith.impl.Op.365, @Int.as.AddWith.impl.Op.1(%int_32) [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.1dc: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.type.2 (%Int.as.OrderedWith.impl.Less.type.6605e2.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.2 (constants.%Int.as.OrderedWith.impl.Less.59643b.1)]
// CHECK:STDOUT:   %Core.import_ref.f9df = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.0ab: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.type.2 (%Int.as.OrderedWith.impl.Greater.type.18c27f.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Greater.2 (constants.%Int.as.OrderedWith.impl.Greater.cbccb6.1)]
// CHECK:STDOUT:   %Core.import_ref.b56 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %OrderedWith.impl_witness_table.100 = impl_witness_table (%Core.import_ref.1dc, %Core.import_ref.f9df, %Core.import_ref.0ab, %Core.import_ref.b56), @Int.as.OrderedWith.impl.f36 [concrete]
// CHECK:STDOUT:   %Core.Less.80e: @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.type.1 (%Int.as.OrderedWith.impl.Less.type.6605e2.2) = import_ref Core//prelude/types/int, Less, loaded [symbolic = @Int.as.OrderedWith.impl.f36.%Int.as.OrderedWith.impl.Less.1 (constants.%Int.as.OrderedWith.impl.Less.59643b.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.4 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.4, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.5 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.8a3a: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.2 (%Int.as.AddWith.impl.Op.type.1eac76.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.2 (constants.%Int.as.AddWith.impl.Op.978dbc.1)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.b21 = impl_witness_table (%Core.import_ref.b4fd3a.5, %Core.import_ref.8a3a), @Int.as.AddWith.impl.155 [concrete]
// CHECK:STDOUT:   %Core.Op.410: @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.type.1 (%Int.as.AddWith.impl.Op.type.1eac76.2) = import_ref Core//prelude/types/int, Op, loaded [symbolic = @Int.as.AddWith.impl.155.%Int.as.AddWith.impl.Op.1 (constants.%Int.as.AddWith.impl.Op.978dbc.2)]
// CHECK:STDOUT:   %Core.import_ref.b929: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b929, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc20_31.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc20_31.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc20_31.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc20_31.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc20_31.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc20_31.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc20_31.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.409 = ref_param_pattern [concrete = constants.%self.param_patt.a48]
// CHECK:STDOUT:     %self.patt: %pattern_type.409 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.fd2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e8e = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e8e = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc20_31.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.409 = ref_param_pattern [concrete = constants.%self.param_patt.a48]
// CHECK:STDOUT:     %self.patt: %pattern_type.409 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.fd2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e8e = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e8e = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc20_31.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6cf = ref_param_pattern [concrete = constants.%self.param_patt.909]
// CHECK:STDOUT:     %self.patt: %pattern_type.6cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.1f0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.e99 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.e99 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc20_31.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6cf = ref_param_pattern [concrete = constants.%self.param_patt.909]
// CHECK:STDOUT:     %self.patt: %pattern_type.6cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.1f0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.e99 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.e99 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc20_31.6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6e3 = ref_param_pattern [concrete = constants.%self.param_patt.efd]
// CHECK:STDOUT:     %self.patt: %pattern_type.6e3 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.b87]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %OptInt = ref_param call_param0
// CHECK:STDOUT:     %self: ref %OptInt = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc20_31.6 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6e3 = ref_param_pattern [concrete = constants.%self.param_patt.efd]
// CHECK:STDOUT:     %self.patt: %pattern_type.6e3 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.b87]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %OptInt = ref_param call_param0
// CHECK:STDOUT:     %self: ref %OptInt = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc15 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc15: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc15: Core.Form = init_form %i32.loc15 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %i.var: ref %i32 = var_storage %i.var_patt
// CHECK:STDOUT:   %int_0.loc16: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_3.1: <bound method> = bound_method %int_0.loc16, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_3.2: <bound method> = bound_method %int_0.loc16, %specific_fn.loc16 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_3.2(%int_0.loc16) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16: init %i32 = converted %int_0.loc16, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   assign %i.var, %.loc16
// CHECK:STDOUT:   %i32.loc16: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %i: ref %i32 = wrapper_binding i, %i.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %i.patt: %pattern_type.6b6 = ref_binding_pattern i [concrete = constants.%i.patt]
// CHECK:STDOUT:     %i.var_patt: %pattern_type.6b6 = var_pattern %i.patt [concrete = constants.%i.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %total.var: ref %i32 = var_storage %total.var_patt
// CHECK:STDOUT:   %int_0.loc17: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc17: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc17_3.1: <bound method> = bound_method %int_0.loc17, %impl.elem0.loc17 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc17: <specific function> = specific_function %impl.elem0.loc17, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc17_3.2: <bound method> = bound_method %int_0.loc17, %specific_fn.loc17 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17: init %i32 = call %bound_method.loc17_3.2(%int_0.loc17) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc17: init %i32 = converted %int_0.loc17, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc17 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   assign %total.var, %.loc17
// CHECK:STDOUT:   %i32.loc17: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %total: ref %i32 = wrapper_binding total, %total.var
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %total.patt: %pattern_type.6b6 = ref_binding_pattern total [concrete = constants.%total.patt]
// CHECK:STDOUT:     %total.var_patt: %pattern_type.6b6 = var_pattern %total.patt [concrete = constants.%total.var_patt]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   br !while.cond
// CHECK:STDOUT:
// CHECK:STDOUT: !while.cond:
// CHECK:STDOUT:   %i.ref.loc18: ref %i32 = name_ref i, %i
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %impl.elem0.loc18_12: %.c7f = impl_witness_access constants.%OrderedWith.impl_witness.480, element0 [concrete = constants.%Int.as.OrderedWith.impl.Less.164caf.2]
// CHECK:STDOUT:   %bound_method.loc18_12.1: <bound method> = bound_method %i.ref.loc18, %impl.elem0.loc18_12
// CHECK:STDOUT:   %specific_fn.loc18_12: <specific function> = specific_function %impl.elem0.loc18_12, @Int.as.OrderedWith.impl.Less.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.30cd42.1]
// CHECK:STDOUT:   %bound_method.loc18_12.2: <bound method> = bound_method %i.ref.loc18, %specific_fn.loc18_12
// CHECK:STDOUT:   %.loc18_10: %i32 = acquire_value %i.ref.loc18
// CHECK:STDOUT:   %.loc18_12: %Int.as.OrderedWith.impl.Less.type.4f4a1d.1 = specific_constant imports.%Core.Less.80e, @Int.as.OrderedWith.impl.f36(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Less.164caf.1]
// CHECK:STDOUT:   %Less.ref: %Int.as.OrderedWith.impl.Less.type.4f4a1d.1 = name_ref Less, %.loc18_12 [concrete = constants.%Int.as.OrderedWith.impl.Less.164caf.1]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.bound: <bound method> = bound_method %.loc18_10, %Less.ref
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.specific_fn: <specific function> = specific_function %Less.ref, @Int.as.OrderedWith.impl.Less.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.OrderedWith.impl.Less.specific_fn.30cd42.2]
// CHECK:STDOUT:   %bound_method.loc18_12.3: <bound method> = bound_method %.loc18_10, %Int.as.OrderedWith.impl.Less.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc18_14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc18_14.1: <bound method> = bound_method %int_3, %impl.elem0.loc18_14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc18_14: <specific function> = specific_function %impl.elem0.loc18_14, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc18_14.2: <bound method> = bound_method %int_3, %specific_fn.loc18_14 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18: init %i32 = call %bound_method.loc18_14.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc18_14.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc18 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc18_14.2: %i32 = converted %int_3, %.loc18_14.1 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %Int.as.OrderedWith.impl.Less.call: init bool = call %bound_method.loc18_12.3(%.loc18_10, %.loc18_14.2)
// CHECK:STDOUT:   %.loc18_15.1: bool = value_of_initializer %Int.as.OrderedWith.impl.Less.call
// CHECK:STDOUT:   %.loc18_15.2: bool = converted %Int.as.OrderedWith.impl.Less.call, %.loc18_15.1
// CHECK:STDOUT:   if %.loc18_15.2 br !while.body else br !while.done
// CHECK:STDOUT:
// CHECK:STDOUT: !while.body:
// CHECK:STDOUT:   %i.ref.loc19_5: ref %i32 = name_ref i, %i
// CHECK:STDOUT:   %i.ref.loc19_9: ref %i32 = name_ref i, %i
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc19: %.fbe = impl_witness_access constants.%AddWith.impl_witness.aa4, element1 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.2]
// CHECK:STDOUT:   %bound_method.loc19_11.1: <bound method> = bound_method %i.ref.loc19_9, %impl.elem1.loc19
// CHECK:STDOUT:   %specific_fn.loc19_11: <specific function> = specific_function %impl.elem1.loc19, @Int.as.AddWith.impl.Op.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.1]
// CHECK:STDOUT:   %bound_method.loc19_11.2: <bound method> = bound_method %i.ref.loc19_9, %specific_fn.loc19_11
// CHECK:STDOUT:   %.loc19_9: %i32 = acquire_value %i.ref.loc19_9
// CHECK:STDOUT:   %.loc19_11: %Int.as.AddWith.impl.Op.type.bddb3c.1 = specific_constant imports.%Core.Op.410, @Int.as.AddWith.impl.155(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Op.ref: %Int.as.AddWith.impl.Op.type.bddb3c.1 = name_ref Op, %.loc19_11 [concrete = constants.%Int.as.AddWith.impl.Op.1fd531.1]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.bound: <bound method> = bound_method %.loc19_9, %Op.ref
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.specific_fn: <specific function> = specific_function %Op.ref, @Int.as.AddWith.impl.Op.3(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.273a3e.2]
// CHECK:STDOUT:   %bound_method.loc19_11.3: <bound method> = bound_method %.loc19_9, %Int.as.AddWith.impl.Op.specific_fn
// CHECK:STDOUT:   %impl.elem0.loc19: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc19_13.1: <bound method> = bound_method %int_1, %impl.elem0.loc19 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc19_13: <specific function> = specific_function %impl.elem0.loc19, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc19_13.2: <bound method> = bound_method %int_1, %specific_fn.loc19_13 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19: init %i32 = call %bound_method.loc19_13.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc19_13.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc19 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc19_13.2: %i32 = converted %int_1, %.loc19_13.1 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc19: init %i32 = call %bound_method.loc19_11.3(%.loc19_9, %.loc19_13.2)
// CHECK:STDOUT:   assign %i.ref.loc19_5, %Int.as.AddWith.impl.Op.call.loc19
// CHECK:STDOUT:   %Next.ref: %Next.type = name_ref Next, file.%Next.decl [concrete = constants.%Next]
// CHECK:STDOUT:   %i.ref.loc20: ref %i32 = name_ref i, %i
// CHECK:STDOUT:   %.loc20_31.1: ref %OptInt = temporary_storage
// CHECK:STDOUT:   %.loc20_30: %i32 = acquire_value %i.ref.loc20
// CHECK:STDOUT:   %Next.call: init %OptInt to %.loc20_31.1 = call %Next.ref(%.loc20_30)
// CHECK:STDOUT:   %.loc20_31.2: ref %OptInt = temporary %.loc20_31.1, %Next.call
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc20: <bound method> = bound_method %.loc20_31.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc20: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc20(%.loc20_31.2)
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete = constants.%n.patt.c48]
// CHECK:STDOUT:     %.loc20_16: %pattern_type.e71 = tuple_pattern (%n.patt) [concrete = constants.%.4e1]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc20: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc20_33.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc20_33.1: <bound method> = bound_method %int_0.loc20, %impl.elem0.loc20_33.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc20_33.1: <specific function> = specific_function %impl.elem0.loc20_33.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc20_33.2: <bound method> = bound_method %int_0.loc20, %specific_fn.loc20_33.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20: init %u1 = call %bound_method.loc20_33.2(%int_0.loc20) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc20_33.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc20 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc20_33.2: %u1 = converted %int_0.loc20, %.loc20_33.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc20_33.3: ref %u1 = class_element_access %.loc20_31.2, element0
// CHECK:STDOUT:   %impl.elem0.loc20_33.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc20_33.3: <bound method> = bound_method %.loc20_33.2, %impl.elem0.loc20_33.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc20_33.2: <specific function> = specific_function %impl.elem0.loc20_33.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc20_33.4: <bound method> = bound_method %.loc20_33.2, %specific_fn.loc20_33.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc20_33.4: %u1 = acquire_value %.loc20_33.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc20_33.4(%.loc20_33.2, %.loc20_33.4)
// CHECK:STDOUT:   %.loc20_33.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc20_33.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc20_33.5
// CHECK:STDOUT:   if %.loc20_33.6 br !let.then else br !let.else
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else:
// CHECK:STDOUT:   br !while.cond
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then:
// CHECK:STDOUT:   %.loc20_5.1: ref %.e8e = class_element_access %.loc20_31.2, element1
// CHECK:STDOUT:   %.loc20_5.2: ref %tuple.type.a8a = class_element_access %.loc20_5.1, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc20_5.2, element0
// CHECK:STDOUT:   %.loc20_5.3: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc20: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %n: %i32 = wrapper_binding n, %.loc20_5.3
// CHECK:STDOUT:   %total.ref.loc21_5: ref %i32 = name_ref total, %total
// CHECK:STDOUT:   %total.ref.loc21_13: ref %i32 = name_ref total, %total
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %impl.elem1.loc21: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc21_19.1: <bound method> = bound_method %total.ref.loc21_13, %impl.elem1.loc21
// CHECK:STDOUT:   %specific_fn.loc21: <specific function> = specific_function %impl.elem1.loc21, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc21_19.2: <bound method> = bound_method %total.ref.loc21_13, %specific_fn.loc21
// CHECK:STDOUT:   %.loc21: %i32 = acquire_value %total.ref.loc21_13
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call.loc21: init %i32 = call %bound_method.loc21_19.2(%.loc21, %n.ref)
// CHECK:STDOUT:   assign %total.ref.loc21_5, %Int.as.AddWith.impl.Op.call.loc21
// CHECK:STDOUT:   br !while.cond
// CHECK:STDOUT:
// CHECK:STDOUT: !while.done:
// CHECK:STDOUT:   %total.ref.loc23: ref %i32 = name_ref total, %total
// CHECK:STDOUT:   %.loc23: %i32 = acquire_value %total.ref.loc23
// CHECK:STDOUT:   %impl.elem0.loc23: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc23_10.1: <bound method> = bound_method %.loc23, %impl.elem0.loc23
// CHECK:STDOUT:   %specific_fn.loc23: <specific function> = specific_function %impl.elem0.loc23, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc23_10.2: <bound method> = bound_method %.loc23, %specific_fn.loc23
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc23_10.2(%.loc23)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc17: <bound method> = bound_method %total.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc17: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc17(%total.var)
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc16: <bound method> = bound_method %i.var, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc16: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc16(%i.var)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc20_31.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc20_31.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc20_31.1(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc20_31.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc20_31.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc20_31.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc20_31.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc20_31.3(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc20_31.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc20_31.4(%self.param: ref %.e8e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc20_31.4(%self.param: ref %.e8e) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc20_31.4(%self.param: ref %.e8e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc20_31.5(%self.param: ref %struct_type.discriminant.payload.e99) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc20_31.1: ref %.e8e = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc20_31.1: <bound method> = bound_method %.loc20_31.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc20_31.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc20_31.1(%.loc20_31.1)
// CHECK:STDOUT:   %.loc20_31.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc20_31.2: <bound method> = bound_method %.loc20_31.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc20_31.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc20_31.2(%.loc20_31.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc20_31.5(%self.param: ref %struct_type.discriminant.payload.e99) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc20_31.5(%self.param: ref %struct_type.discriminant.payload.e99) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc20_31.6(%self.param: ref %OptInt) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc20_31.6(%self.param: ref %OptInt) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc20_31.6(%self.param: ref %OptInt) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- nested_all_paths_return.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OptInt: type = class_type @OptInt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %pattern_type.6e3: type = pattern_type %OptInt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %c.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %c.patt: %pattern_type.831 = wrapper_binding_pattern c, %c.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.4e1: %pattern_type.e71 = tuple_pattern (%n.patt) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_2.ecc: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.3cb: <bound method> = bound_method %int_2.ecc, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_2.295: %i32 = int_value 2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %c.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%c.param_patt]
// CHECK:STDOUT:     %c.patt: %pattern_type.831 = wrapper_binding_pattern c, %c.param_patt [concrete = constants.%c.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc11 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc11: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_29: Core.Form = init_form %i32.loc11 [concrete = constants.%.795f]
// CHECK:STDOUT:     %o.param: %OptInt = value_param call_param0
// CHECK:STDOUT:     %OptInt.ref: type = name_ref OptInt, file.%OptInt.decl [concrete = constants.%OptInt]
// CHECK:STDOUT:     %o: %OptInt = wrapper_binding o, %o.param
// CHECK:STDOUT:     %c.param: bool = value_param call_param1
// CHECK:STDOUT:     %.loc11_20: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %c: bool = wrapper_binding c, %c.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%o.param: %OptInt, %c.param: bool) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.ref: %OptInt = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:     %.loc12_14: %pattern_type.e71 = tuple_pattern (%n.patt) [concrete = constants.%.4e1]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_25.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc12_25.1: <bound method> = bound_method %int_0, %impl.elem0.loc12_25.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc12_25.1: <specific function> = specific_function %impl.elem0.loc12_25.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc12_25.2: <bound method> = bound_method %int_0, %specific_fn.loc12_25.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %u1 = call %bound_method.loc12_25.2(%int_0) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_25.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_25.2: %u1 = converted %int_0, %.loc12_25.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc12_25.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc12_25.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc12_25.3: <bound method> = bound_method %.loc12_25.2, %impl.elem0.loc12_25.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc12_25.2: <specific function> = specific_function %impl.elem0.loc12_25.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc12_25.4: <bound method> = bound_method %.loc12_25.2, %specific_fn.loc12_25.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc12_25.4: %u1 = acquire_value %.loc12_25.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc12_25.4(%.loc12_25.2, %.loc12_25.4)
// CHECK:STDOUT:   %.loc12_25.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc12_25.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc12_25.5
// CHECK:STDOUT:   if %.loc12_25.6 br !let.then else br !let.else
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else:
// CHECK:STDOUT:   %c.ref: bool = name_ref c, %c
// CHECK:STDOUT:   if %c.ref br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc14: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_15.1: <bound method> = bound_method %int_1, %impl.elem0.loc14 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_15.2: <bound method> = bound_method %int_1, %specific_fn.loc14 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14: init %i32 = call %bound_method.loc14_15.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc14: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2.ecc]
// CHECK:STDOUT:   %impl.elem0.loc16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_15.1: <bound method> = bound_method %int_2, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.9f3]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_15.2: <bound method> = bound_method %int_2, %specific_fn.loc16 [concrete = constants.%bound_method.3cb]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_15.2(%int_2) [concrete = constants.%int_2.295]
// CHECK:STDOUT:   %.loc16: init %i32 = converted %int_2, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_2.295]
// CHECK:STDOUT:   return %.loc16
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then:
// CHECK:STDOUT:   %.loc12_3.1: ref %.e8e = class_element_access %o.ref, element1
// CHECK:STDOUT:   %.loc12_3.2: ref %tuple.type.a8a = class_element_access %.loc12_3.1, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc12_3.2, element0
// CHECK:STDOUT:   %.loc12_3.3: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %n: %i32 = wrapper_binding n, %.loc12_3.3
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %impl.elem0.loc19: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc19_10.1: <bound method> = bound_method %n.ref, %impl.elem0.loc19
// CHECK:STDOUT:   %specific_fn.loc19: <specific function> = specific_function %impl.elem0.loc19, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc19_10.2: <bound method> = bound_method %n.ref, %specific_fn.loc19
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc19_10.2(%n.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- let_else_in_match_arm_body.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OptInt: type = class_type @OptInt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %Int.67af24.1: type = class_type @Int, @Int(%N) [symbolic]
// CHECK:STDOUT:   %pattern_type.dc0: type = pattern_type Core.IntLiteral [concrete]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %pattern_type.6e3: type = pattern_type %OptInt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.type.8ee: type = facet_type <@EqWith, @EqWith(%i32)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.f7de31.1: type = facet_type <@ImplicitAs, @ImplicitAs(%Int.67af24.1)> [symbolic]
// CHECK:STDOUT:   %T.4e6: %ImplicitAs.type.f7de31.1 = symbolic_binding T, 1 [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl.956(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.1: %T.as_type.as.EqWith.impl.Equal.type.8af025.1 = struct_value () [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.8af025.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl.956(%N, %T.4e6) [symbolic]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.c477d6.2: %T.as_type.as.EqWith.impl.Equal.type.8af025.2 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %EqWith.impl_witness.bde: <witness> = impl_witness imports.%EqWith.impl_witness_table.532, @T.as_type.as.EqWith.impl.956(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1: type = fn_type @T.as_type.as.EqWith.impl.Equal.2, @T.as_type.as.EqWith.impl.956(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = struct_value () [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2: type = fn_type @T.as_type.as.EqWith.impl.Equal.1, @T.as_type.as.EqWith.impl.956(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.57b831.2: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.2 = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.eb2: %EqWith.type.8ee = facet_value Core.IntLiteral, (%EqWith.impl_witness.bde) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.a21: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%i32, %EqWith.facet.eb2) [concrete]
// CHECK:STDOUT:   %.025: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.a21, %EqWith.facet.eb2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.e051da.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.57b831.2 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.2, @T.as_type.as.EqWith.impl.Equal.1(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %bound_method.b3bca7.1: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound.e051da.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.57b831.1 [concrete]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2: <specific function> = specific_function %T.as_type.as.EqWith.impl.Equal.57b831.1, @T.as_type.as.EqWith.impl.Equal.2(%int_32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %bound_method.b3bca7.2: <bound method> = bound_method %int_0.5c6, %T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2 [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.4e1: %pattern_type.e71 = tuple_pattern (%n.patt) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.a9a: @T.as_type.as.EqWith.impl.956.%T.as_type.as.EqWith.impl.Equal.type.2 (%T.as_type.as.EqWith.impl.Equal.type.8af025.1) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @T.as_type.as.EqWith.impl.956.%T.as_type.as.EqWith.impl.Equal.2 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.1)]
// CHECK:STDOUT:   %Core.import_ref.712 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.532 = impl_witness_table (%Core.import_ref.a9a, %Core.import_ref.712), @T.as_type.as.EqWith.impl.956 [concrete]
// CHECK:STDOUT:   %Core.Equal.970: @T.as_type.as.EqWith.impl.956.%T.as_type.as.EqWith.impl.Equal.type.1 (%T.as_type.as.EqWith.impl.Equal.type.8af025.2) = import_ref Core//prelude/types/int, Equal, loaded [symbolic = @T.as_type.as.EqWith.impl.956.%T.as_type.as.EqWith.impl.Equal.1 (constants.%T.as_type.as.EqWith.impl.Equal.c477d6.2)]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc10_28 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc10_28: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc10: Core.Form = init_form %i32.loc10_28 [concrete = constants.%.795f]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc10_9: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %o.param: %OptInt = value_param call_param1
// CHECK:STDOUT:     %OptInt.ref: type = name_ref OptInt, file.%OptInt.decl [concrete = constants.%OptInt]
// CHECK:STDOUT:     %o: %OptInt = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param2
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%x.param: %i32, %o.param: %OptInt) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %expr_patt: %pattern_type.dc0 = expr_pattern %int_0.loc12 in [concrete] {
// CHECK:STDOUT:       %int_0.loc12: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:     }
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc12: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc12_12: %.025 = impl_witness_access constants.%EqWith.impl_witness.bde, element0 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.2]
// CHECK:STDOUT:   %bound_method.loc12_12.1: <bound method> = bound_method %int_0.loc12, %impl.elem0.loc12_12 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.e051da.1]
// CHECK:STDOUT:   %specific_fn.loc12_12: <specific function> = specific_function %impl.elem0.loc12_12, @T.as_type.as.EqWith.impl.Equal.1(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.1]
// CHECK:STDOUT:   %bound_method.loc12_12.2: <bound method> = bound_method %int_0.loc12, %specific_fn.loc12_12 [concrete = constants.%bound_method.b3bca7.1]
// CHECK:STDOUT:   %.loc12_12.1: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = specific_constant imports.%Core.Equal.970, @T.as_type.as.EqWith.impl.956(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %Equal.ref: %T.as_type.as.EqWith.impl.Equal.type.dd8c0d.1 = name_ref Equal, %.loc12_12.1 [concrete = constants.%T.as_type.as.EqWith.impl.Equal.57b831.1]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.loc12, %Equal.ref [concrete = constants.%T.as_type.as.EqWith.impl.Equal.bound.e051da.2]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.specific_fn: <specific function> = specific_function %Equal.ref, @T.as_type.as.EqWith.impl.Equal.2(constants.%int_32, constants.%ImplicitAs.facet.48f) [concrete = constants.%T.as_type.as.EqWith.impl.Equal.specific_fn.684f33.2]
// CHECK:STDOUT:   %bound_method.loc12_12.3: <bound method> = bound_method %int_0.loc12, %T.as_type.as.EqWith.impl.Equal.specific_fn [concrete = constants.%bound_method.b3bca7.2]
// CHECK:STDOUT:   %impl.elem0.loc12_10: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc12_10.1: <bound method> = bound_method %int_0.loc12, %impl.elem0.loc12_10 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc12_10: <specific function> = specific_function %impl.elem0.loc12_10, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc12_10.2: <bound method> = bound_method %int_0.loc12, %specific_fn.loc12_10 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12: init %i32 = call %bound_method.loc12_10.2(%int_0.loc12) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc12_10.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc12 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc12_10.2: %i32 = converted %int_0.loc12, %.loc12_10.1 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %T.as_type.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc12_12.3(%.loc12_10.2, %x.ref)
// CHECK:STDOUT:   %.loc12_12.2: bool = value_of_initializer %T.as_type.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc12_12.3: bool = converted %T.as_type.as.EqWith.impl.Equal.call, %.loc12_12.2
// CHECK:STDOUT:   if %.loc12_12.3 br !match.case.then else br !match.case.else
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.then:
// CHECK:STDOUT:   %o.ref: %OptInt = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %n.patt: %pattern_type.6b6 = value_binding_pattern n [concrete = constants.%n.patt]
// CHECK:STDOUT:     %.loc13_18: %pattern_type.e71 = tuple_pattern (%n.patt) [concrete = constants.%.4e1]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc13: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_29.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_29.1: <bound method> = bound_method %int_0.loc13, %impl.elem0.loc13_29.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc13_29.1: <specific function> = specific_function %impl.elem0.loc13_29.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_29.2: <bound method> = bound_method %int_0.loc13, %specific_fn.loc13_29.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_29: init %u1 = call %bound_method.loc13_29.2(%int_0.loc13) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_29.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_29 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_29.2: %u1 = converted %int_0.loc13, %.loc13_29.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_29.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc13_29.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_29.3: <bound method> = bound_method %.loc13_29.2, %impl.elem0.loc13_29.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc13_29.2: <specific function> = specific_function %impl.elem0.loc13_29.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_29.4: <bound method> = bound_method %.loc13_29.2, %specific_fn.loc13_29.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc13_29.4: %u1 = acquire_value %.loc13_29.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call: init bool = call %bound_method.loc13_29.4(%.loc13_29.2, %.loc13_29.4)
// CHECK:STDOUT:   %.loc13_29.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call
// CHECK:STDOUT:   %.loc13_29.6: bool = converted %UInt.as.EqWith.impl.Equal.call, %.loc13_29.5
// CHECK:STDOUT:   if %.loc13_29.6 br !let.then else br !let.else
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc13_43: <bound method> = bound_method %int_1, %impl.elem1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call: init Core.IntLiteral = call %bound_method.loc13_43(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc13_45: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_45.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %impl.elem0.loc13_45 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc13_45: <specific function> = specific_function %impl.elem0.loc13_45, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc13_45.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call, %specific_fn.loc13_45 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc13_43.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc13_43.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call, %.loc13_43.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_45: init %i32 = call %bound_method.loc13_45.2(%.loc13_43.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc13_45: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_45 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc13_45
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then:
// CHECK:STDOUT:   %.loc13_7.1: ref %.e8e = class_element_access %o.ref, element1
// CHECK:STDOUT:   %.loc13_7.2: ref %tuple.type.a8a = class_element_access %.loc13_7.1, element0
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %.loc13_7.2, element0
// CHECK:STDOUT:   %.loc13_7.3: %i32 = acquire_value %tuple.elem0
// CHECK:STDOUT:   %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %n: %i32 = wrapper_binding n, %.loc13_7.3
// CHECK:STDOUT:   %n.ref: %i32 = name_ref n, %n
// CHECK:STDOUT:   %impl.elem0.loc14: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc14_14.1: <bound method> = bound_method %n.ref, %impl.elem0.loc14
// CHECK:STDOUT:   %specific_fn.loc14: <specific function> = specific_function %impl.elem0.loc14, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc14_14.2: <bound method> = bound_method %n.ref, %specific_fn.loc14
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc14_14.2(%n.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT:
// CHECK:STDOUT: !match.case.else:
// CHECK:STDOUT:   %int_0.loc16: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc16: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc16_26.1: <bound method> = bound_method %int_0.loc16, %impl.elem0.loc16 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc16: <specific function> = specific_function %impl.elem0.loc16, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc16_26.2: <bound method> = bound_method %int_0.loc16, %specific_fn.loc16 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16: init %i32 = call %bound_method.loc16_26.2(%int_0.loc16) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc16: init %i32 = converted %int_0.loc16, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc16 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc16
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- two_in_sequence.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   type: type = facet_type <type> [concrete]
// CHECK:STDOUT:   %OptInt: type = class_type @OptInt [concrete]
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %empty_tuple.type: type = tuple_type () [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %u1: type = class_type @UInt, @UInt(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %tuple.type.a8a: type = tuple_type (%i32) [concrete]
// CHECK:STDOUT:   %.e8e: type = custom_layout_type {size=4, align=4, .Some@0: %tuple.type.a8a} [concrete]
// CHECK:STDOUT:   %struct_type.discriminant.payload.e99: type = struct_type {.discriminant: %u1, .payload: %.e8e} [concrete]
// CHECK:STDOUT:   %pattern_type.6e3: type = pattern_type %OptInt [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.ca1: type = facet_type <@ImplicitAs, @ImplicitAs(%u1)> [concrete]
// CHECK:STDOUT:   %To.fe9: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.170: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.f4c: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.f01, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.1, @Core.IntLiteral.as.ImplicitAs.impl.b68(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ab = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.46b: %ImplicitAs.type.ca1 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.f4c) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.77c: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%u1, %ImplicitAs.facet.46b) [concrete]
// CHECK:STDOUT:   %.e74: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.77c, %ImplicitAs.facet.46b [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a [concrete]
// CHECK:STDOUT:   %pattern_type.322: type = pattern_type %u1 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(%int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.0e8: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93 [concrete]
// CHECK:STDOUT:   %int_0.1a7: %u1 = int_value 0 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %Wrap.type: type = fn_type @Wrap [concrete]
// CHECK:STDOUT:   %Wrap: %Wrap.type = struct_value () [concrete]
// CHECK:STDOUT:   %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete]
// CHECK:STDOUT:   %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %F.type: type = fn_type @F [concrete]
// CHECK:STDOUT:   %F: %F.type = struct_value () [concrete]
// CHECK:STDOUT:   %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete]
// CHECK:STDOUT:   %pattern_type.e71: type = pattern_type %tuple.type.a8a [concrete]
// CHECK:STDOUT:   %.d40: %pattern_type.e71 = tuple_pattern (%a.patt) [concrete]
// CHECK:STDOUT:   %EqWith.type.c25: type = facet_type <@EqWith, @EqWith(%u1)> [concrete]
// CHECK:STDOUT:   %M: Core.IntLiteral = symbolic_binding M, 1 [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.544: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%N, %M) [symbolic]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.c67: %UInt.as.EqWith.impl.Equal.type.544 = struct_value () [symbolic]
// CHECK:STDOUT:   %EqWith.impl_witness.7b3: <witness> = impl_witness imports.%EqWith.impl_witness_table.166, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.type.29b: type = fn_type @UInt.as.EqWith.impl.Equal.1, @UInt.as.EqWith.impl.f13(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.ba4: %UInt.as.EqWith.impl.Equal.type.29b = struct_value () [concrete]
// CHECK:STDOUT:   %EqWith.facet.4d0: %EqWith.type.c25 = facet_value %u1, (%EqWith.impl_witness.7b3) [concrete]
// CHECK:STDOUT:   %EqWith.WithSelf.Equal.type.e3c: type = fn_type @EqWith.WithSelf.Equal, @EqWith.WithSelf(%u1, %EqWith.facet.4d0) [concrete]
// CHECK:STDOUT:   %.9eb: type = fn_type_with_self_type %EqWith.WithSelf.Equal.type.e3c, %EqWith.facet.4d0 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.bound: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.ba4 [concrete]
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.specific_fn.6b6: <specific function> = specific_function %UInt.as.EqWith.impl.Equal.ba4, @UInt.as.EqWith.impl.Equal.1(%int_1.5b8, %int_1.5b8) [concrete]
// CHECK:STDOUT:   %bound_method.53a: <bound method> = bound_method %int_0.1a7, %UInt.as.EqWith.impl.Equal.specific_fn.6b6 [concrete]
// CHECK:STDOUT:   %Negate.type: type = facet_type <@Negate> [concrete]
// CHECK:STDOUT:   %Negate.impl_witness: <witness> = impl_witness imports.%Negate.impl_witness_table [concrete]
// CHECK:STDOUT:   %Negate.facet: %Negate.type = facet_value Core.IntLiteral, (%Negate.impl_witness) [concrete]
// CHECK:STDOUT:   %Negate.WithSelf.Op.type.e85: type = fn_type @Negate.WithSelf.Op, @Negate.WithSelf(%Negate.facet) [concrete]
// CHECK:STDOUT:   %.758: type = fn_type_with_self_type %Negate.WithSelf.Op.type.e85, %Negate.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.type: type = fn_type @Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op: %Core.IntLiteral.as.Negate.impl.Op.type = struct_value () [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.6a0: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-1.638: Core.IntLiteral = int_value -1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To.fe9) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert.2, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet.48f: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet.48f) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet.48f [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.a65: <bound method> = bound_method %int_-1.638, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-1.4ef: %i32 = int_value -1 [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete]
// CHECK:STDOUT:   %.f2a: %pattern_type.e71 = tuple_pattern (%b.patt) [concrete]
// CHECK:STDOUT:   %self.param_patt.7c1: %pattern_type.322 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.945: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt.7c1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_29.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.1: type = fn_type @Destroy.WithSelf.Op.loc14_29.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.1: %Destroy.WithSelf.Op.type.ef016f.1 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.1: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_29.1 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.1: %Destroy.WithSelf.SelfDestruct.type.fbceb5.1 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.705: %pattern_type.6b6 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.70d: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt.705 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_29.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.2: type = fn_type @Destroy.WithSelf.Op.loc14_29.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.2: %Destroy.WithSelf.Op.type.ef016f.2 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.2: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_29.2 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.2: %Destroy.WithSelf.SelfDestruct.type.fbceb5.2 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.bad: %pattern_type.e71 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.216: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt.bad [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_29.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.3: type = fn_type @Destroy.WithSelf.Op.loc14_29.3 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.3: %Destroy.WithSelf.Op.type.ef016f.3 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.409: type = pattern_type %.e8e [concrete]
// CHECK:STDOUT:   %self.param_patt.a48: %pattern_type.409 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.fd2: %pattern_type.409 = wrapper_binding_pattern self, %self.param_patt.a48 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_29.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.4: type = fn_type @Destroy.WithSelf.Op.loc14_29.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.4: %Destroy.WithSelf.Op.type.ef016f.4 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.4: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_29.4 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.4: %Destroy.WithSelf.SelfDestruct.type.fbceb5.4 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.6cf: type = pattern_type %struct_type.discriminant.payload.e99 [concrete]
// CHECK:STDOUT:   %self.param_patt.909: %pattern_type.6cf = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.1f0: %pattern_type.6cf = wrapper_binding_pattern self, %self.param_patt.909 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_29.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.5: type = fn_type @Destroy.WithSelf.Op.loc14_29.5 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.5: %Destroy.WithSelf.Op.type.ef016f.5 = struct_value () [concrete]
// CHECK:STDOUT:   %self.param_patt.efd: %pattern_type.6e3 = ref_param_pattern [concrete]
// CHECK:STDOUT:   %self.patt.b87: %pattern_type.6e3 = wrapper_binding_pattern self, %self.param_patt.efd [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6: type = fn_type @Destroy.WithSelf.SubobjectDestroy.loc14_29.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.d01daf.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.type.ef016f.6: type = fn_type @Destroy.WithSelf.Op.loc14_29.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.Op.403171.6: %Destroy.WithSelf.Op.type.ef016f.6 = struct_value () [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.type.fbceb5.6: type = fn_type @Destroy.WithSelf.SelfDestruct.loc14_29.6 [concrete]
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.db3fdb.6: %Destroy.WithSelf.SelfDestruct.type.fbceb5.6 = struct_value () [concrete]
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.bound.e21: <bound method> = bound_method %int_2, %Core.IntLiteral.as.Negate.impl.Op [concrete]
// CHECK:STDOUT:   %int_-2.962: Core.IntLiteral = int_value -2 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.33f: <bound method> = bound_method %int_-2.962, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571 [concrete]
// CHECK:STDOUT:   %int_-2.c83: %i32 = int_value -2 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: imports {
// CHECK:STDOUT:   %Core.import_ref.aa5: @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.199) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.b68.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.170)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.f01 = impl_witness_table (%Core.import_ref.aa5), @Core.IntLiteral.as.ImplicitAs.impl.b68 [concrete]
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.b92: @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal.type (%UInt.as.EqWith.impl.Equal.type.544) = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, loaded [symbolic = @UInt.as.EqWith.impl.f13.%UInt.as.EqWith.impl.Equal (constants.%UInt.as.EqWith.impl.Equal.c67)]
// CHECK:STDOUT:   %Core.import_ref.b44 = import_ref Core//prelude/types/uint, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %EqWith.impl_witness_table.166 = impl_witness_table (%Core.import_ref.b92, %Core.import_ref.b44), @UInt.as.EqWith.impl.f13 [concrete]
// CHECK:STDOUT:   %Core.import_ref.abd = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.9c3: %Core.IntLiteral.as.Negate.impl.Op.type = import_ref Core//prelude/operators/arithmetic, loc{{\d+_\d+}}, loaded [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %Negate.impl_witness_table = impl_witness_table (%Core.import_ref.abd, %Core.import_ref.9c3), @Core.IntLiteral.as.Negate.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: generated {
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.1: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.1 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_29.1 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.1: %Destroy.WithSelf.Op.type.ef016f.1 = fn_decl @Destroy.WithSelf.Op.loc14_29.1 [concrete = constants.%Destroy.WithSelf.Op.403171.1] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.322 = ref_param_pattern [concrete = constants.%self.param_patt.7c1]
// CHECK:STDOUT:     %self.patt: %pattern_type.322 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.945]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %u1 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %u1 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.2: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.2 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_29.2 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.2: %Destroy.WithSelf.Op.type.ef016f.2 = fn_decl @Destroy.WithSelf.Op.loc14_29.2 [concrete = constants.%Destroy.WithSelf.Op.403171.2] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6b6 = ref_param_pattern [concrete = constants.%self.param_patt.705]
// CHECK:STDOUT:     %self.patt: %pattern_type.6b6 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.70d]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %i32 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %i32 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.3: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.3 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_29.3 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.3: %Destroy.WithSelf.Op.type.ef016f.3 = fn_decl @Destroy.WithSelf.Op.loc14_29.3 [concrete = constants.%Destroy.WithSelf.Op.403171.3] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.e71 = ref_param_pattern [concrete = constants.%self.param_patt.bad]
// CHECK:STDOUT:     %self.patt: %pattern_type.e71 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.216]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %tuple.type.a8a = ref_param call_param0
// CHECK:STDOUT:     %self: ref %tuple.type.a8a = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.4: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.4 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_29.4 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.409 = ref_param_pattern [concrete = constants.%self.param_patt.a48]
// CHECK:STDOUT:     %self.patt: %pattern_type.409 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.fd2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e8e = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e8e = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.4: %Destroy.WithSelf.Op.type.ef016f.4 = fn_decl @Destroy.WithSelf.Op.loc14_29.4 [concrete = constants.%Destroy.WithSelf.Op.403171.4] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.409 = ref_param_pattern [concrete = constants.%self.param_patt.a48]
// CHECK:STDOUT:     %self.patt: %pattern_type.409 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.fd2]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %.e8e = ref_param call_param0
// CHECK:STDOUT:     %self: ref %.e8e = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.5: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.5 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_29.5 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6cf = ref_param_pattern [concrete = constants.%self.param_patt.909]
// CHECK:STDOUT:     %self.patt: %pattern_type.6cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.1f0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.e99 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.e99 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.5: %Destroy.WithSelf.Op.type.ef016f.5 = fn_decl @Destroy.WithSelf.Op.loc14_29.5 [concrete = constants.%Destroy.WithSelf.Op.403171.5] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6cf = ref_param_pattern [concrete = constants.%self.param_patt.909]
// CHECK:STDOUT:     %self.patt: %pattern_type.6cf = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.1f0]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %struct_type.discriminant.payload.e99 = ref_param call_param0
// CHECK:STDOUT:     %self: ref %struct_type.discriminant.payload.e99 = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.decl.763c71.6: %Destroy.WithSelf.SubobjectDestroy.type.dfcbdb.6 = fn_decl @Destroy.WithSelf.SubobjectDestroy.loc14_29.6 [concrete = constants.%Destroy.WithSelf.SubobjectDestroy.d01daf.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6e3 = ref_param_pattern [concrete = constants.%self.param_patt.efd]
// CHECK:STDOUT:     %self.patt: %pattern_type.6e3 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.b87]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %OptInt = ref_param call_param0
// CHECK:STDOUT:     %self: ref %OptInt = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Destroy.WithSelf.Op.decl.5f94cf.6: %Destroy.WithSelf.Op.type.ef016f.6 = fn_decl @Destroy.WithSelf.Op.loc14_29.6 [concrete = constants.%Destroy.WithSelf.Op.403171.6] {
// CHECK:STDOUT:     %self.param_patt: %pattern_type.6e3 = ref_param_pattern [concrete = constants.%self.param_patt.efd]
// CHECK:STDOUT:     %self.patt: %pattern_type.6e3 = wrapper_binding_pattern self, %self.param_patt [concrete = constants.%self.patt.b87]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %self.param: ref %OptInt = ref_param call_param0
// CHECK:STDOUT:     %self: ref %OptInt = wrapper_binding self, %self.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %F.decl: %F.type = fn_decl @F [concrete = constants.%F] {
// CHECK:STDOUT:     %o.param_patt: %pattern_type.6e3 = value_param_pattern [concrete = constants.%o.param_patt]
// CHECK:STDOUT:     %o.patt: %pattern_type.6e3 = wrapper_binding_pattern o, %o.param_patt [concrete = constants.%o.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc12 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc12: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc12: Core.Form = init_form %i32.loc12 [concrete = constants.%.795f]
// CHECK:STDOUT:     %o.param: %OptInt = value_param call_param0
// CHECK:STDOUT:     %OptInt.ref: type = name_ref OptInt, file.%OptInt.decl [concrete = constants.%OptInt]
// CHECK:STDOUT:     %o: %OptInt = wrapper_binding o, %o.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @F(%o.param: %OptInt) -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %o.ref: %OptInt = name_ref o, %o
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %a.patt: %pattern_type.6b6 = value_binding_pattern a [concrete = constants.%a.patt]
// CHECK:STDOUT:     %.loc13_14: %pattern_type.e71 = tuple_pattern (%a.patt) [concrete = constants.%.d40]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc13: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc13_25.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc13_25.1: <bound method> = bound_method %int_0.loc13, %impl.elem0.loc13_25.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc13_25.1: <specific function> = specific_function %impl.elem0.loc13_25.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc13_25.2: <bound method> = bound_method %int_0.loc13, %specific_fn.loc13_25.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_25: init %u1 = call %bound_method.loc13_25.2(%int_0.loc13) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_25.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_25 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_25.2: %u1 = converted %int_0.loc13, %.loc13_25.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc13_25.3: ref %u1 = class_element_access %o.ref, element0
// CHECK:STDOUT:   %impl.elem0.loc13_25.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc13_25.3: <bound method> = bound_method %.loc13_25.2, %impl.elem0.loc13_25.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc13_25.2: <specific function> = specific_function %impl.elem0.loc13_25.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc13_25.4: <bound method> = bound_method %.loc13_25.2, %specific_fn.loc13_25.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc13_25.4: %u1 = acquire_value %.loc13_25.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc13: init bool = call %bound_method.loc13_25.4(%.loc13_25.2, %.loc13_25.4)
// CHECK:STDOUT:   %.loc13_25.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc13
// CHECK:STDOUT:   %.loc13_25.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc13, %.loc13_25.5
// CHECK:STDOUT:   if %.loc13_25.6 br !let.then.loc13 else br !let.else.loc13
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else.loc13:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem1.loc13: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc13_39: <bound method> = bound_method %int_1, %impl.elem1.loc13 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.6a0]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc13: init Core.IntLiteral = call %bound_method.loc13_39(%int_1) [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %impl.elem0.loc13_41: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc13_41.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc13, %impl.elem0.loc13_41 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.65e]
// CHECK:STDOUT:   %specific_fn.loc13_41: <specific function> = specific_function %impl.elem0.loc13_41, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc13_41.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc13, %specific_fn.loc13_41 [concrete = constants.%bound_method.a65]
// CHECK:STDOUT:   %.loc13_39.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc13 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %.loc13_39.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc13, %.loc13_39.1 [concrete = constants.%int_-1.638]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_41: init %i32 = call %bound_method.loc13_41.2(%.loc13_39.2) [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   %.loc13_41: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc13, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc13_41 [concrete = constants.%int_-1.4ef]
// CHECK:STDOUT:   return %.loc13_41
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then.loc13:
// CHECK:STDOUT:   %.loc13_3.1: ref %.e8e = class_element_access %o.ref, element1
// CHECK:STDOUT:   %.loc13_3.2: ref %tuple.type.a8a = class_element_access %.loc13_3.1, element0
// CHECK:STDOUT:   %tuple.elem0.loc13: ref %i32 = tuple_access %.loc13_3.2, element0
// CHECK:STDOUT:   %.loc13_3.3: %i32 = acquire_value %tuple.elem0.loc13
// CHECK:STDOUT:   %i32.loc13: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %a: %i32 = wrapper_binding a, %.loc13_3.3
// CHECK:STDOUT:   %Wrap.ref: %Wrap.type = name_ref Wrap, file.%Wrap.decl [concrete = constants.%Wrap]
// CHECK:STDOUT:   %a.ref: %i32 = name_ref a, %a
// CHECK:STDOUT:   %.loc14_29.1: ref %OptInt = temporary_storage
// CHECK:STDOUT:   %Wrap.call: init %OptInt to %.loc14_29.1 = call %Wrap.ref(%a.ref)
// CHECK:STDOUT:   %.loc14_29.2: ref %OptInt = temporary %.loc14_29.1, %Wrap.call
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %.loc14_29.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.6
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%.loc14_29.2)
// CHECK:STDOUT:   name_binding_decl {
// CHECK:STDOUT:     %b.patt: %pattern_type.6b6 = value_binding_pattern b [concrete = constants.%b.patt]
// CHECK:STDOUT:     %.loc14_14: %pattern_type.e71 = tuple_pattern (%b.patt) [concrete = constants.%.f2a]
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %int_0.loc14: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc14_31.1: %.e74 = impl_witness_access constants.%ImplicitAs.impl_witness.f4c, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e4a]
// CHECK:STDOUT:   %bound_method.loc14_31.1: <bound method> = bound_method %int_0.loc14, %impl.elem0.loc14_31.1 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.219]
// CHECK:STDOUT:   %specific_fn.loc14_31.1: <specific function> = specific_function %impl.elem0.loc14_31.1, @Core.IntLiteral.as.ImplicitAs.impl.Convert.1(constants.%int_1.5b8) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.e93]
// CHECK:STDOUT:   %bound_method.loc14_31.2: <bound method> = bound_method %int_0.loc14, %specific_fn.loc14_31.1 [concrete = constants.%bound_method.0e8]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_31: init %u1 = call %bound_method.loc14_31.2(%int_0.loc14) [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_31.1: %u1 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_31 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_31.2: %u1 = converted %int_0.loc14, %.loc14_31.1 [concrete = constants.%int_0.1a7]
// CHECK:STDOUT:   %.loc14_31.3: ref %u1 = class_element_access %.loc14_29.2, element0
// CHECK:STDOUT:   %impl.elem0.loc14_31.2: %.9eb = impl_witness_access constants.%EqWith.impl_witness.7b3, element0 [concrete = constants.%UInt.as.EqWith.impl.Equal.ba4]
// CHECK:STDOUT:   %bound_method.loc14_31.3: <bound method> = bound_method %.loc14_31.2, %impl.elem0.loc14_31.2 [concrete = constants.%UInt.as.EqWith.impl.Equal.bound]
// CHECK:STDOUT:   %specific_fn.loc14_31.2: <specific function> = specific_function %impl.elem0.loc14_31.2, @UInt.as.EqWith.impl.Equal.1(constants.%int_1.5b8, constants.%int_1.5b8) [concrete = constants.%UInt.as.EqWith.impl.Equal.specific_fn.6b6]
// CHECK:STDOUT:   %bound_method.loc14_31.4: <bound method> = bound_method %.loc14_31.2, %specific_fn.loc14_31.2 [concrete = constants.%bound_method.53a]
// CHECK:STDOUT:   %.loc14_31.4: %u1 = acquire_value %.loc14_31.3
// CHECK:STDOUT:   %UInt.as.EqWith.impl.Equal.call.loc14: init bool = call %bound_method.loc14_31.4(%.loc14_31.2, %.loc14_31.4)
// CHECK:STDOUT:   %.loc14_31.5: bool = value_of_initializer %UInt.as.EqWith.impl.Equal.call.loc14
// CHECK:STDOUT:   %.loc14_31.6: bool = converted %UInt.as.EqWith.impl.Equal.call.loc14, %.loc14_31.5
// CHECK:STDOUT:   if %.loc14_31.6 br !let.then.loc14 else br !let.else.loc14
// CHECK:STDOUT:
// CHECK:STDOUT: !let.else.loc14:
// CHECK:STDOUT:   %int_2: Core.IntLiteral = int_value 2 [concrete = constants.%int_2]
// CHECK:STDOUT:   %impl.elem1.loc14: %.758 = impl_witness_access constants.%Negate.impl_witness, element1 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op]
// CHECK:STDOUT:   %bound_method.loc14_45: <bound method> = bound_method %int_2, %impl.elem1.loc14 [concrete = constants.%Core.IntLiteral.as.Negate.impl.Op.bound.e21]
// CHECK:STDOUT:   %Core.IntLiteral.as.Negate.impl.Op.call.loc14: init Core.IntLiteral = call %bound_method.loc14_45(%int_2) [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %impl.elem0.loc14_47: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc14_47.1: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc14, %impl.elem0.loc14_47 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.2a0]
// CHECK:STDOUT:   %specific_fn.loc14_47: <specific function> = specific_function %impl.elem0.loc14_47, @Core.IntLiteral.as.ImplicitAs.impl.Convert.2(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn.571]
// CHECK:STDOUT:   %bound_method.loc14_47.2: <bound method> = bound_method %Core.IntLiteral.as.Negate.impl.Op.call.loc14, %specific_fn.loc14_47 [concrete = constants.%bound_method.33f]
// CHECK:STDOUT:   %.loc14_45.1: Core.IntLiteral = value_of_initializer %Core.IntLiteral.as.Negate.impl.Op.call.loc14 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %.loc14_45.2: Core.IntLiteral = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc14, %.loc14_45.1 [concrete = constants.%int_-2.962]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_47: init %i32 = call %bound_method.loc14_47.2(%.loc14_45.2) [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   %.loc14_47: init %i32 = converted %Core.IntLiteral.as.Negate.impl.Op.call.loc14, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc14_47 [concrete = constants.%int_-2.c83]
// CHECK:STDOUT:   return %.loc14_47
// CHECK:STDOUT:
// CHECK:STDOUT: !let.then.loc14:
// CHECK:STDOUT:   %.loc14_3.1: ref %.e8e = class_element_access %.loc14_29.2, element1
// CHECK:STDOUT:   %.loc14_3.2: ref %tuple.type.a8a = class_element_access %.loc14_3.1, element0
// CHECK:STDOUT:   %tuple.elem0.loc14: ref %i32 = tuple_access %.loc14_3.2, element0
// CHECK:STDOUT:   %.loc14_3.3: %i32 = acquire_value %tuple.elem0.loc14
// CHECK:STDOUT:   %i32.loc14: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:   %b: %i32 = wrapper_binding b, %.loc14_3.3
// CHECK:STDOUT:   %b.ref: %i32 = name_ref b, %b
// CHECK:STDOUT:   %impl.elem0.loc15: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc15_10.1: <bound method> = bound_method %b.ref, %impl.elem0.loc15
// CHECK:STDOUT:   %specific_fn.loc15: <specific function> = specific_function %impl.elem0.loc15, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc15_10.2: <bound method> = bound_method %b.ref, %specific_fn.loc15
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc15_10.2(%b.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_29.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_29.1(%self.param: ref %u1) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_29.1(%self.param: ref %u1) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.1(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.1(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_29.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_29.2(%self.param: ref %i32) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_29.2(%self.param: ref %i32) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.2(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.2(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_29.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %tuple.elem0: ref %i32 = tuple_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound: <bound method> = bound_method %tuple.elem0, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.2
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound(%tuple.elem0)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_29.3(%self.param: ref %tuple.type.a8a) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_29.3(%self.param: ref %tuple.type.a8a) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.3(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.3(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_29.4(%self.param: ref %.e8e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_29.4(%self.param: ref %.e8e) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_29.4(%self.param: ref %.e8e) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.4(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.4(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_29.5(%self.param: ref %struct_type.discriminant.payload.e99) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %.loc14_29.1: ref %.e8e = struct_access %self.param, element1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_29.1: <bound method> = bound_method %.loc14_29.1, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.4
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_29.1: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_29.1(%.loc14_29.1)
// CHECK:STDOUT:   %.loc14_29.2: ref %u1 = struct_access %self.param, element0
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.bound.loc14_29.2: <bound method> = bound_method %.loc14_29.2, constants.%Destroy.WithSelf.SelfDestruct.db3fdb.1
// CHECK:STDOUT:   %Destroy.WithSelf.SelfDestruct.call.loc14_29.2: init %empty_tuple.type = call %Destroy.WithSelf.SelfDestruct.bound.loc14_29.2(%.loc14_29.2)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_29.5(%self.param: ref %struct_type.discriminant.payload.e99) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_29.5(%self.param: ref %struct_type.discriminant.payload.e99) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.5(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.5(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SubobjectDestroy.loc14_29.6(%self.param: ref %OptInt) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.Op.loc14_29.6(%self.param: ref %OptInt) = "no_op";
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Destroy.WithSelf.SelfDestruct.loc14_29.6(%self.param: ref %OptInt) {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %Destroy.WithSelf.Op.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.Op.decl.5f94cf.6(%self.param)
// CHECK:STDOUT:   %Destroy.WithSelf.SubobjectDestroy.call: init %empty_tuple.type = call generated.%Destroy.WithSelf.SubobjectDestroy.decl.763c71.6(%self.param)
// CHECK:STDOUT:   return
// CHECK:STDOUT: }
// CHECK:STDOUT:
