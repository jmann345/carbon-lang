// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// INCLUDE-FILE: toolchain/testing/testdata/min_prelude/full.carbon
// EXTRA-ARGS: --dump-sem-ir-ranges=only
//
// AUTOUPDATE
// TIP: To test this file alone, run:
// TIP:   bazel test //toolchain/testing:file_test --test_arg=--file_tests=toolchain/check/testdata/function/overload/import.carbon
// TIP: To dump output, run:
// TIP:   bazel run //toolchain/testing:file_test -- --dump_output --file_tests=toolchain/check/testdata/function/overload/import.carbon
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:69:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.SizeType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Size().(ImplicitAs(u64).Convert)().(As(i64).Convert)());
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:68:9: error: cannot access member of interface `Destroy` in type `C.(CppContiguousRange.DataType)` that does not implement that interface [MissingImplInMemberAccess]
// CHECK:STDERR:         self.Data().(CppDataPointer.Raw)(),
// CHECK:STDERR:         ^~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: {{.*}}/prelude/types/cpp/slice.carbon:64:1: error: orphan `impl` found; something in the self-type or constraint must be defined in the same file [ImplIsOrphan]
// CHECK:STDERR: impl forall [C: CppContiguous where .Element impls Copy & Destroy]
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:

// `overload fn` sets reached through an import (fork/overload/plan.md OV-2,
// §1.B.1-3, §1.B.7). The import resolver localizes a set whole, with its
// member list in the declared order, so a set is never partially imported and
// every member keeps its set-relative index (`:overload<N>`, D-OV-5). A set is
// closed (p000998): the implementation file of its library may only DEFINE
// members, an importing library may only redeclare them (which is how `extern`
// ownership works), and a declaration that matches no member by parameter
// types is `OverloadSetFrozen`. Every member an API file declares must be
// defined by the API file or its implementation file (`MissingDefinitionInImpl`
// at the member's API declaration), which is what makes a marked-signature
// typo across the two files loud (§1.B.7).

// --- lib.carbon

library "[[@TEST_NAME]]";

overload fn F(unused x: i32) -> i32 { return 1; }
overload fn F(unused b: bool) -> i32 { return 2; }

// --- use.carbon

library "[[@TEST_NAME]]";

import library "lib";

// The imported set value is the name lookup result; each call commits to the
// selected imported member, as for a same-file set.
//@dump-sem-ir-begin
fn Use() -> i32 { return F(7) + F(true); }
//@dump-sem-ir-end

// --- api_impl.carbon

library "[[@TEST_NAME]]";

overload fn G(x: i32) -> i32;
overload fn G(b: bool) -> i32;

// --- api_impl.impl.carbon

impl library "[[@TEST_NAME]]";

// Each definition merges into its API-declared member (the `ApiForImpl`
// import); the name stays bound to the set value, so the call resolves over
// the imported set. Both members are defined, so §1.B.7's check is quiet.
//@dump-sem-ir-begin
overload fn G(x: i32) -> i32 { return x; }
overload fn G(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return G(3) + G(true); }
//@dump-sem-ir-end

// --- frozen.carbon

library "[[@TEST_NAME]]";

overload fn H(x: i32) -> i32;
overload fn H(b: bool) -> i32;

// --- fail_frozen.impl.carbon

impl library "[[@TEST_NAME]]";

overload fn H(x: i32) -> i32 { return x; }
overload fn H(b: bool) -> i32 { if (b) { return 1; } return 0; }

// An implementation file may only define members, never add one.
// CHECK:STDERR: fail_frozen.impl.carbon:[[@LINE+8]]:1: error: overload set `H` is closed; new members may only be declared in the API file of its library [OverloadSetFrozen]
// CHECK:STDERR: overload fn H(unused x: i32, unused y: i32) -> i32 { return 3; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_frozen.impl.carbon:[[@LINE-9]]:1: in import [InImport]
// CHECK:STDERR: frozen.carbon:4:1: note: overload set declared here [OverloadSetDeclaredHere]
// CHECK:STDERR: overload fn H(x: i32) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn H(unused x: i32, unused y: i32) -> i32 { return 3; }

// --- fail_cross_library_adds_member.carbon

library "[[@TEST_NAME]]";

import library "lib";

// No library may add a member to another library's set.
// CHECK:STDERR: fail_cross_library_adds_member.carbon:[[@LINE+8]]:1: error: overload set `F` is closed; new members may only be declared in the API file of its library [OverloadSetFrozen]
// CHECK:STDERR: overload fn F(unused x: i32, unused y: i32) -> i32 { return 3; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_cross_library_adds_member.carbon:[[@LINE-6]]:1: in import [InImport]
// CHECK:STDERR: lib.carbon:4:1: note: overload set declared here [OverloadSetDeclaredHere]
// CHECK:STDERR: overload fn F(unused x: i32) -> i32 { return 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
overload fn F(unused x: i32, unused y: i32) -> i32 { return 3; }

// --- unmarked.carbon

library "[[@TEST_NAME]]";

overload fn K(x: i32) -> i32;
overload fn K(b: bool) -> i32;

// --- fail_unmarked.impl.carbon

impl library "[[@TEST_NAME]]";

// The marker is all-or-none across the library too: an unmarked definition
// against the imported set is diagnosed and then recovers as marked, so it
// still defines its member.
// CHECK:STDERR: fail_unmarked.impl.carbon:[[@LINE+8]]:1: error: `overload` must appear on every declaration of `K` or on none [OverloadMarkerMismatch]
// CHECK:STDERR: fn K(x: i32) -> i32 { return x; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_unmarked.impl.carbon:[[@LINE-8]]:1: in import [InImport]
// CHECK:STDERR: unmarked.carbon:4:1: note: previous declaration of `K` here [OverloadMarkerPrevious]
// CHECK:STDERR: overload fn K(x: i32) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
fn K(x: i32) -> i32 { return x; }

overload fn K(b: bool) -> i32 { if (b) { return 1; } return 0; }

// --- extern_lib.carbon

library "[[@TEST_NAME]]";

extern library "extern_owner" overload fn E(x: i32) -> i32;
extern library "extern_owner" overload fn E(b: bool) -> i32;

// --- extern_owner.carbon

library "[[@TEST_NAME]]";

import library "extern_lib";

// The owning library's `extern overload fn` declarations each name an existing
// member of the imported set; the cross-library `extern` rules then apply per
// member (§1.B.3).
extern overload fn E(x: i32) -> i32 { return x; }
extern overload fn E(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return E(1) + E(true); }

// --- fail_extern_non_member.carbon

library "[[@TEST_NAME]]";

import library "extern_lib";

// CHECK:STDERR: fail_extern_non_member.carbon:[[@LINE+8]]:1: error: overload set `E` is closed; new members may only be declared in the API file of its library [OverloadSetFrozen]
// CHECK:STDERR: extern overload fn E(x: i32, y: i32) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_extern_non_member.carbon:[[@LINE-5]]:1: in import [InImport]
// CHECK:STDERR: extern_lib.carbon:4:1: note: overload set declared here [OverloadSetDeclaredHere]
// CHECK:STDERR: extern library "extern_owner" overload fn E(x: i32) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
extern overload fn E(x: i32, y: i32) -> i32;

// --- undefined.carbon

library "[[@TEST_NAME]]";

overload fn M(x: i32) -> i32;
overload fn M(b: bool) -> i32;

// --- fail_undefined.impl.carbon

// CHECK:STDERR: fail_undefined.impl.carbon:[[@LINE+5]]:1: in import [InImport]
// CHECK:STDERR: undefined.carbon:5:1: error: no definition found for declaration in impl file [MissingDefinitionInImpl]
// CHECK:STDERR: overload fn M(b: bool) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
impl library "[[@TEST_NAME]]";

// Only the first member is defined; the second is diagnosed at its API
// declaration when this implementation file is checked (§1.B.7).
overload fn M(x: i32) -> i32 { return x; }

// --- impl_local_set.carbon

library "[[@TEST_NAME]]";

// --- impl_local_set.impl.carbon

impl library "[[@TEST_NAME]]";

// A set declared wholly inside an implementation file involves no import, so
// the same-file path applies.
overload fn L(unused x: i32) -> i32 { return 1; }
overload fn L(unused b: bool) -> i32 { return 2; }

fn Use() -> i32 { return L(true); }

// --- api_imports_set.carbon

library "[[@TEST_NAME]]";

import library "lib";

// An API file that uses another library's set inline. The set is localized
// into this file's store, with placeholder member declarations that carry no
// definition: they are `lib`'s members, declared and defined there.
fn UseBoth(x: i32) -> i32 { return F(x) + F(true); }

// --- api_imports_set.impl.carbon

impl library "[[@TEST_NAME]]";

// Checking the implementation file walks the API file's sets for members
// without a definition (§1.B.7); a set the API file merely imported is
// skipped, so nothing is diagnosed.
fn Use() -> i32 { return UseBoth(3); }

// --- untouched.carbon

library "[[@TEST_NAME]]";

overload fn U(x: i32) -> i32;
overload fn U(b: bool) -> i32;

// --- fail_untouched.impl.carbon

// CHECK:STDERR: fail_untouched.impl.carbon:[[@LINE+10]]:1: in import [InImport]
// CHECK:STDERR: untouched.carbon:4:1: error: no definition found for declaration in impl file [MissingDefinitionInImpl]
// CHECK:STDERR: overload fn U(x: i32) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_untouched.impl.carbon:[[@LINE+5]]:1: in import [InImport]
// CHECK:STDERR: untouched.carbon:5:1: error: no definition found for declaration in impl file [MissingDefinitionInImpl]
// CHECK:STDERR: overload fn U(b: bool) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
impl library "[[@TEST_NAME]]";

// The implementation file never names the set, so no member is loaded here
// and both are diagnosed at their API declarations.
fn Other() -> i32 { return 0; }

// --- extern_two_file_lib.carbon

library "[[@TEST_NAME]]";

extern library "extern_two_file" overload fn D(x: i32) -> i32;
extern library "extern_two_file" overload fn D(b: bool) -> i32;

// --- extern_two_file.carbon

library "[[@TEST_NAME]]";

import library "extern_two_file_lib";

// The owning library's API file redeclares each member without a definition;
// the definitions are in its implementation file (the two-file shape of
// function/definition/extern_library.carbon's `two_file`). The name stays
// bound to the imported set value, so the implementation file finds these
// owning declarations through the API file's localized set, member by member.
extern overload fn D(x: i32) -> i32;
extern overload fn D(b: bool) -> i32;

// --- extern_two_file.impl.carbon

impl library "[[@TEST_NAME]]";

extern overload fn D(x: i32) -> i32 { return x; }
extern overload fn D(b: bool) -> i32 { if (b) { return 1; } return 0; }

fn Use() -> i32 { return D(1) + D(true); }

// --- extern_unowned_lib.carbon

library "[[@TEST_NAME]]";

extern library "extern_unowned" overload fn N(x: i32) -> i32;

// --- fail_extern_unowned.carbon

library "[[@TEST_NAME]]";

// The owning library's API file imports the set but declares no member. As
// for a plain function, the non-owning member is loaded at the import and its
// missing owning declaration is diagnosed.
// CHECK:STDERR: fail_extern_unowned.carbon:[[@LINE+5]]:1: in import [InImport]
// CHECK:STDERR: extern_unowned_lib.carbon:4:1: error: owning declaration required for non-owning declaration [MissingOwningDeclarationInApi]
// CHECK:STDERR: extern library "extern_unowned" overload fn N(x: i32) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "extern_unowned_lib";

// --- fail_extern_unowned.impl.carbon

impl library "[[@TEST_NAME]]";

// Without an owning declaration in the API file, the implementation file
// cannot define the member of another library's set: the API file imported
// the set, but this redeclaration is checked against the set's own library.
// CHECK:STDERR: fail_extern_unowned.impl.carbon:[[@LINE+4]]:1: error: `extern` entities must have a declaration in the API file [ExternRequiresDeclInApiFile]
// CHECK:STDERR: extern overload fn N(x: i32) -> i32 { return x; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
extern overload fn N(x: i32) -> i32 { return x; }

// --- extern_partial_lib.carbon

library "[[@TEST_NAME]]";

extern library "extern_partial" overload fn P(x: i32) -> i32;
extern library "extern_partial" overload fn P(b: bool) -> i32;

// --- fail_extern_partial.carbon

library "[[@TEST_NAME]]";

// Only the first member gets an owning declaration here; the second's is
// missing, diagnosed at the import as for a plain function.
// CHECK:STDERR: fail_extern_partial.carbon:[[@LINE+5]]:1: in import [InImport]
// CHECK:STDERR: extern_partial_lib.carbon:5:1: error: owning declaration required for non-owning declaration [MissingOwningDeclarationInApi]
// CHECK:STDERR: extern library "extern_partial" overload fn P(b: bool) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
import library "extern_partial_lib";

extern overload fn P(x: i32) -> i32;

// --- fail_extern_partial.impl.carbon

impl library "[[@TEST_NAME]]";

// Where a member was previously declared is decided per member: the first
// member's definition merges with its API declaration, the second has no
// declaration in the API file.
extern overload fn P(x: i32) -> i32 { return x; }
// CHECK:STDERR: fail_extern_partial.impl.carbon:[[@LINE+4]]:1: error: `extern` entities must have a declaration in the API file [ExternRequiresDeclInApiFile]
// CHECK:STDERR: extern overload fn P(b: bool) -> i32 { if (b) { return 1; } return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
extern overload fn P(b: bool) -> i32 { if (b) { return 1; } return 0; }

// --- extern_api_defined_lib.carbon

library "[[@TEST_NAME]]";

extern library "extern_api_defined" overload fn A(x: i32) -> i32;
extern library "extern_api_defined" overload fn A(b: bool) -> i32;

// --- extern_api_defined.carbon

library "[[@TEST_NAME]]";

import library "extern_api_defined_lib";

// The owning library's API file defines both members inline (the one-file
// shape of `extern_owner`), and also has an implementation file.
extern overload fn A(x: i32) -> i32 { return x; }
extern overload fn A(b: bool) -> i32 { if (b) { return 1; } return 0; }

// --- fail_extern_api_defined.impl.carbon

impl library "[[@TEST_NAME]]";

// The api/impl rules are applied to the API file's declaration of each member,
// not to the member as localized from the set's library (which has no body):
// a definition here is a redefinition, and a declaration is redundant, as for
// a plain function defined in the API file (function/definition/
// implicit_import.carbon's `fail_redef_after_def` and `fail_redecl_after_def`).
// CHECK:STDERR: fail_extern_api_defined.impl.carbon:[[@LINE+12]]:1: error: redefinition of `fn A` [RedeclRedef]
// CHECK:STDERR: extern overload fn A(x: i32) -> i32 { return x + 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_extern_api_defined.impl.carbon:[[@LINE-10]]:1: in import [InImport]
// CHECK:STDERR: extern_api_defined.carbon:8:1: note: previously defined here [RedeclPrevDef]
// CHECK:STDERR: extern overload fn A(x: i32) -> i32 { return x; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
// CHECK:STDERR: fail_extern_api_defined.impl.carbon:[[@LINE+4]]:1: error: `extern` entities must have a declaration in the API file [ExternRequiresDeclInApiFile]
// CHECK:STDERR: extern overload fn A(x: i32) -> i32 { return x + 1; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
extern overload fn A(x: i32) -> i32 { return x + 1; }
// CHECK:STDERR: fail_extern_api_defined.impl.carbon:[[@LINE+8]]:1: error: redeclaration of `fn A` is redundant [RedeclRedundant]
// CHECK:STDERR: extern overload fn A(b: bool) -> i32;
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR: fail_extern_api_defined.impl.carbon:[[@LINE-23]]:1: in import [InImport]
// CHECK:STDERR: extern_api_defined.carbon:9:1: note: previously declared here [RedeclPrevDecl]
// CHECK:STDERR: extern overload fn A(b: bool) -> i32 { if (b) { return 1; } return 0; }
// CHECK:STDERR: ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// CHECK:STDERR:
extern overload fn A(b: bool) -> i32;

// CHECK:STDOUT: --- use.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %F.type.eb3ec9.1: type = fn_type @F.1 [concrete]
// CHECK:STDOUT:   %F.7088cc.1: %F.type.eb3ec9.1 = struct_value () [concrete]
// CHECK:STDOUT:   %F.type.eb3ec9.2: type = fn_type @F.2 [concrete]
// CHECK:STDOUT:   %F.7088cc.2: %F.type.eb3ec9.2 = struct_value () [concrete]
// CHECK:STDOUT:   %F.overload_set.type: type = overload_set_type @F.overload_set [concrete]
// CHECK:STDOUT:   %F.overload_set.value: %F.overload_set.type = overload_set_value @F.overload_set [concrete]
// CHECK:STDOUT:   %int_7.29f: Core.IntLiteral = int_value 7 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method: <bound method> = bound_method %int_7.29f, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_7.690: %i32 = int_value 7 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
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
// CHECK:STDOUT:   %Main.F: %F.overload_set.type = import_ref Main//lib, F, loaded [concrete = constants.%F.overload_set.value]
// CHECK:STDOUT:   %F.decl.e70bc1.1: %F.type.eb3ec9.1 = fn_decl @F.1 [concrete = constants.%F.7088cc.1] {} {}
// CHECK:STDOUT:   %F.decl.e70bc1.2: %F.type.eb3ec9.2 = fn_decl @F.2 [concrete = constants.%F.7088cc.2] {} {}
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %F.ref.loc9_26: %F.overload_set.type = name_ref F, imports.%Main.F [concrete = constants.%F.overload_set.value]
// CHECK:STDOUT:   %int_7: Core.IntLiteral = int_value 7 [concrete = constants.%int_7.29f]
// CHECK:STDOUT:   %F.ref.loc9_29: %F.type.eb3ec9.2 = name_ref F, imports.%F.decl.e70bc1.2 [concrete = constants.%F.7088cc.2]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_28.1: <bound method> = bound_method %int_7, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound]
// CHECK:STDOUT:   %specific_fn.loc9_28: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_28.2: <bound method> = bound_method %int_7, %specific_fn.loc9_28 [concrete = constants.%bound_method]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc9_28.2(%int_7) [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc9_28.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %.loc9_28.2: %i32 = converted %int_7, %.loc9_28.1 [concrete = constants.%int_7.690]
// CHECK:STDOUT:   %F.call.loc9_29: init %i32 = call %F.ref.loc9_29(%.loc9_28.2)
// CHECK:STDOUT:   %F.ref.loc9_33: %F.overload_set.type = name_ref F, imports.%Main.F [concrete = constants.%F.overload_set.value]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %F.ref.loc9_39: %F.type.eb3ec9.1 = name_ref F, imports.%F.decl.e70bc1.1 [concrete = constants.%F.7088cc.1]
// CHECK:STDOUT:   %F.call.loc9_39: init %i32 = call %F.ref.loc9_39(%true)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc9_31.1: <bound method> = bound_method %F.call.loc9_29, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc9_31: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc9_31.2: <bound method> = bound_method %F.call.loc9_29, %specific_fn.loc9_31
// CHECK:STDOUT:   %.loc9_29.1: %i32 = value_of_initializer %F.call.loc9_29
// CHECK:STDOUT:   %.loc9_29.2: %i32 = converted %F.call.loc9_29, %.loc9_29.1
// CHECK:STDOUT:   %.loc9_39.1: %i32 = value_of_initializer %F.call.loc9_39
// CHECK:STDOUT:   %.loc9_39.2: %i32 = converted %F.call.loc9_39, %.loc9_39.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc9_31.2(%.loc9_29.2, %.loc9_39.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: --- api_impl.impl.carbon
// CHECK:STDOUT:
// CHECK:STDOUT: constants {
// CHECK:STDOUT:   %int_32: Core.IntLiteral = int_value 32 [concrete]
// CHECK:STDOUT:   %N: Core.IntLiteral = symbolic_binding N, 0 [symbolic]
// CHECK:STDOUT:   %i32: type = class_type @Int, @Int(%int_32) [concrete]
// CHECK:STDOUT:   %pattern_type.6b6: type = pattern_type %i32 [concrete]
// CHECK:STDOUT:   %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete]
// CHECK:STDOUT:   %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete]
// CHECK:STDOUT:   %.795f: Core.Form = init_form %i32 [concrete]
// CHECK:STDOUT:   %return.param_patt.a9a: %pattern_type.6b6 = out_param_pattern [concrete]
// CHECK:STDOUT:   %return.patt.e1b: %pattern_type.6b6 = return_slot_pattern %return.param_patt.a9a, %i32 [concrete]
// CHECK:STDOUT:   %G.type.f42045.1: type = fn_type @G.loc9 [concrete]
// CHECK:STDOUT:   %G.4228ed.1: %G.type.f42045.1 = struct_value () [concrete]
// CHECK:STDOUT:   %pattern_type.831: type = pattern_type bool [concrete]
// CHECK:STDOUT:   %b.param_patt: %pattern_type.831 = value_param_pattern [concrete]
// CHECK:STDOUT:   %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete]
// CHECK:STDOUT:   %G.type.f42045.2: type = fn_type @G.loc8 [concrete]
// CHECK:STDOUT:   %G.4228ed.2: %G.type.f42045.2 = struct_value () [concrete]
// CHECK:STDOUT:   %G.overload_set.type: type = overload_set_type @G.overload_set [concrete]
// CHECK:STDOUT:   %G.overload_set.value: %G.overload_set.type = overload_set_value @G.overload_set [concrete]
// CHECK:STDOUT:   %Copy.type: type = facet_type <@Copy> [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.ac8: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.5e0: %Int.as.Copy.impl.Op.type.ac8 = struct_value () [symbolic]
// CHECK:STDOUT:   %Copy.impl_witness.b51: <witness> = impl_witness imports.%Copy.impl_witness_table.8d2, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.type.3f6: type = fn_type @Int.as.Copy.impl.Op, @Int.as.Copy.impl(%int_32) [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.4f6: %Int.as.Copy.impl.Op.type.3f6 = struct_value () [concrete]
// CHECK:STDOUT:   %Copy.facet.1e1: %Copy.type = facet_value %i32, (%Copy.impl_witness.b51) [concrete]
// CHECK:STDOUT:   %Copy.WithSelf.Op.type.381: type = fn_type @Copy.WithSelf.Op, @Copy.WithSelf(%Copy.facet.1e1) [concrete]
// CHECK:STDOUT:   %.737: type = fn_type_with_self_type %Copy.WithSelf.Op.type.381, %Copy.facet.1e1 [concrete]
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.specific_fn: <specific function> = specific_function %Int.as.Copy.impl.Op.4f6, @Int.as.Copy.impl.Op(%int_32) [concrete]
// CHECK:STDOUT:   %int_1.5b8: Core.IntLiteral = int_value 1 [concrete]
// CHECK:STDOUT:   %ImplicitAs.type.914: type = facet_type <@ImplicitAs, @ImplicitAs(%i32)> [concrete]
// CHECK:STDOUT:   %To: Core.IntLiteral = symbolic_binding To, 0 [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%To) [symbolic]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.845: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74 = struct_value () [symbolic]
// CHECK:STDOUT:   %ImplicitAs.impl_witness.a2a: <witness> = impl_witness imports.%ImplicitAs.impl_witness_table.1aa, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba: type = fn_type @Core.IntLiteral.as.ImplicitAs.impl.Convert, @Core.IntLiteral.as.ImplicitAs.impl.0e9(%int_32) [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39: %Core.IntLiteral.as.ImplicitAs.impl.Convert.type.2ba = struct_value () [concrete]
// CHECK:STDOUT:   %ImplicitAs.facet: %ImplicitAs.type.914 = facet_value Core.IntLiteral, (%ImplicitAs.impl_witness.a2a) [concrete]
// CHECK:STDOUT:   %ImplicitAs.WithSelf.Convert.type.8eb: type = fn_type @ImplicitAs.WithSelf.Convert, @ImplicitAs.WithSelf(%i32, %ImplicitAs.facet) [concrete]
// CHECK:STDOUT:   %.b7a: type = fn_type_with_self_type %ImplicitAs.WithSelf.Convert.type.8eb, %ImplicitAs.facet [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn: <specific function> = specific_function %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39, @Core.IntLiteral.as.ImplicitAs.impl.Convert(%int_32) [concrete]
// CHECK:STDOUT:   %bound_method.953: <bound method> = bound_method %int_1.5b8, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_1.0c6: %i32 = int_value 1 [concrete]
// CHECK:STDOUT:   %int_0.5c6: Core.IntLiteral = int_value 0 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.6e0: <bound method> = bound_method %int_0.5c6, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_0.3c0: %i32 = int_value 0 [concrete]
// CHECK:STDOUT:   %Use.type: type = fn_type @Use [concrete]
// CHECK:STDOUT:   %Use: %Use.type = struct_value () [concrete]
// CHECK:STDOUT:   %int_3.1ba: Core.IntLiteral = int_value 3 [concrete]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.e39 [concrete]
// CHECK:STDOUT:   %bound_method.763: <bound method> = bound_method %int_3.1ba, %Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn [concrete]
// CHECK:STDOUT:   %int_3.410: %i32 = int_value 3 [concrete]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete]
// CHECK:STDOUT:   %AddWith.type.be9: type = facet_type <@AddWith, @AddWith(%i32)> [concrete]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.type.610: type = fn_type @Int.as.AddWith.impl.Op.1, @Int.as.AddWith.impl.3af(%N) [symbolic]
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.732: %Int.as.AddWith.impl.Op.type.610 = struct_value () [symbolic]
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
// CHECK:STDOUT:   %Main.G: %G.overload_set.type = import_ref Main//api_impl, G, loaded [concrete = constants.%G.overload_set.value]
// CHECK:STDOUT:   %G.decl.1f85e1.1: %G.type.f42045.1 = fn_decl @G.loc9 [concrete = constants.%G.4228ed.1] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {}
// CHECK:STDOUT:   %G.decl.1f85e1.2: %G.type.f42045.2 = fn_decl @G.loc8 [concrete = constants.%G.4228ed.2] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_26 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {}
// CHECK:STDOUT:   %Core.import_ref.cd6: @Int.as.Copy.impl.%Int.as.Copy.impl.Op.type (%Int.as.Copy.impl.Op.type.ac8) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.Copy.impl.%Int.as.Copy.impl.Op (constants.%Int.as.Copy.impl.Op.5e0)]
// CHECK:STDOUT:   %Copy.impl_witness_table.8d2 = impl_witness_table (%Core.import_ref.cd6), @Int.as.Copy.impl [concrete]
// CHECK:STDOUT:   %Core.import_ref.edf: @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert.type (%Core.IntLiteral.as.ImplicitAs.impl.Convert.type.e74) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Core.IntLiteral.as.ImplicitAs.impl.0e9.%Core.IntLiteral.as.ImplicitAs.impl.Convert (constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.845)]
// CHECK:STDOUT:   %ImplicitAs.impl_witness_table.1aa = impl_witness_table (%Core.import_ref.edf), @Core.IntLiteral.as.ImplicitAs.impl.0e9 [concrete]
// CHECK:STDOUT:   %Core.import_ref.b4fd3a.1 = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, unloaded
// CHECK:STDOUT:   %Core.import_ref.684: @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op.type (%Int.as.AddWith.impl.Op.type.610) = import_ref Core//prelude/types/int, loc{{\d+_\d+}}, loaded [symbolic = @Int.as.AddWith.impl.3af.%Int.as.AddWith.impl.Op (constants.%Int.as.AddWith.impl.Op.732)]
// CHECK:STDOUT:   %AddWith.impl_witness_table.6b4 = impl_witness_table (%Core.import_ref.b4fd3a.1, %Core.import_ref.684), @Int.as.AddWith.impl.3af [concrete]
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: file {
// CHECK:STDOUT:   %G.decl.loc8: %G.type.f42045.2 = fn_decl @G.loc8 [concrete = constants.%G.4228ed.2] {
// CHECK:STDOUT:     %x.param_patt: %pattern_type.6b6 = value_param_pattern [concrete = constants.%x.param_patt]
// CHECK:STDOUT:     %x.patt: %pattern_type.6b6 = wrapper_binding_pattern x, %x.param_patt [concrete = constants.%x.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32.loc8_26 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32.loc8_26: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc8: Core.Form = init_form %i32.loc8_26 [concrete = constants.%.795f]
// CHECK:STDOUT:     %x.param: %i32 = value_param call_param0
// CHECK:STDOUT:     %i32.loc8_18: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %x: %i32 = wrapper_binding x, %x.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %G.decl.loc9: %G.type.f42045.1 = fn_decl @G.loc9 [concrete = constants.%G.4228ed.1] {
// CHECK:STDOUT:     %b.param_patt: %pattern_type.831 = value_param_pattern [concrete = constants.%b.param_patt]
// CHECK:STDOUT:     %b.patt: %pattern_type.831 = wrapper_binding_pattern b, %b.param_patt [concrete = constants.%b.patt]
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc9_27: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %b.param: bool = value_param call_param0
// CHECK:STDOUT:     %.loc9_18: type = type_literal bool [concrete = bool]
// CHECK:STDOUT:     %b: bool = wrapper_binding b, %b.param
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param1
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT:   %Use.decl: %Use.type = fn_decl @Use [concrete = constants.%Use] {
// CHECK:STDOUT:     %return.param_patt: %pattern_type.6b6 = out_param_pattern [concrete = constants.%return.param_patt.a9a]
// CHECK:STDOUT:     %return.patt: %pattern_type.6b6 = return_slot_pattern %return.param_patt, %i32 [concrete = constants.%return.patt.e1b]
// CHECK:STDOUT:   } {
// CHECK:STDOUT:     %i32: type = type_literal constants.%i32 [concrete = constants.%i32]
// CHECK:STDOUT:     %.loc11_13: Core.Form = init_form %i32 [concrete = constants.%.795f]
// CHECK:STDOUT:     %return.param: ref %i32 = out_param call_param0
// CHECK:STDOUT:     %return: ref %i32 = return_slot %return.param
// CHECK:STDOUT:   }
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G.loc9(%b.param: bool) -> out %return.param: %i32 [from "api_impl.carbon"] {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %b.ref: bool = name_ref b, %b
// CHECK:STDOUT:   if %b.ref br !if.then else br !if.else
// CHECK:STDOUT:
// CHECK:STDOUT: !if.then:
// CHECK:STDOUT:   %int_1: Core.IntLiteral = int_value 1 [concrete = constants.%int_1.5b8]
// CHECK:STDOUT:   %impl.elem0.loc9_50: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_50.1: <bound method> = bound_method %int_1, %impl.elem0.loc9_50 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.094]
// CHECK:STDOUT:   %specific_fn.loc9_50: <specific function> = specific_function %impl.elem0.loc9_50, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_50.2: <bound method> = bound_method %int_1, %specific_fn.loc9_50 [concrete = constants.%bound_method.953]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_50: init %i32 = call %bound_method.loc9_50.2(%int_1) [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   %.loc9_50: init %i32 = converted %int_1, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_50 [concrete = constants.%int_1.0c6]
// CHECK:STDOUT:   return %.loc9_50
// CHECK:STDOUT:
// CHECK:STDOUT: !if.else:
// CHECK:STDOUT:   %int_0: Core.IntLiteral = int_value 0 [concrete = constants.%int_0.5c6]
// CHECK:STDOUT:   %impl.elem0.loc9_62: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc9_62.1: <bound method> = bound_method %int_0, %impl.elem0.loc9_62 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.7b4]
// CHECK:STDOUT:   %specific_fn.loc9_62: <specific function> = specific_function %impl.elem0.loc9_62, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc9_62.2: <bound method> = bound_method %int_0, %specific_fn.loc9_62 [concrete = constants.%bound_method.6e0]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_62: init %i32 = call %bound_method.loc9_62.2(%int_0) [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   %.loc9_62: init %i32 = converted %int_0, %Core.IntLiteral.as.ImplicitAs.impl.Convert.call.loc9_62 [concrete = constants.%int_0.3c0]
// CHECK:STDOUT:   return %.loc9_62
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @G.loc8(%x.param: %i32) -> out %return.param: %i32 [from "api_impl.carbon"] {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %x.ref: %i32 = name_ref x, %x
// CHECK:STDOUT:   %impl.elem0: %.737 = impl_witness_access constants.%Copy.impl_witness.b51, element0 [concrete = constants.%Int.as.Copy.impl.Op.4f6]
// CHECK:STDOUT:   %bound_method.loc8_39.1: <bound method> = bound_method %x.ref, %impl.elem0
// CHECK:STDOUT:   %specific_fn: <specific function> = specific_function %impl.elem0, @Int.as.Copy.impl.Op(constants.%int_32) [concrete = constants.%Int.as.Copy.impl.Op.specific_fn]
// CHECK:STDOUT:   %bound_method.loc8_39.2: <bound method> = bound_method %x.ref, %specific_fn
// CHECK:STDOUT:   %Int.as.Copy.impl.Op.call: init %i32 = call %bound_method.loc8_39.2(%x.ref)
// CHECK:STDOUT:   return %Int.as.Copy.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
// CHECK:STDOUT: fn @Use() -> out %return.param: %i32 {
// CHECK:STDOUT: !entry:
// CHECK:STDOUT:   %G.ref.loc11_26: %G.overload_set.type = name_ref G, imports.%Main.G [concrete = constants.%G.overload_set.value]
// CHECK:STDOUT:   %int_3: Core.IntLiteral = int_value 3 [concrete = constants.%int_3.1ba]
// CHECK:STDOUT:   %G.ref.loc11_29: %G.type.f42045.2 = name_ref G, imports.%G.decl.1f85e1.2 [concrete = constants.%G.4228ed.2]
// CHECK:STDOUT:   %impl.elem0: %.b7a = impl_witness_access constants.%ImplicitAs.impl_witness.a2a, element0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.e39]
// CHECK:STDOUT:   %bound_method.loc11_28.1: <bound method> = bound_method %int_3, %impl.elem0 [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.bound.485]
// CHECK:STDOUT:   %specific_fn.loc11_28: <specific function> = specific_function %impl.elem0, @Core.IntLiteral.as.ImplicitAs.impl.Convert(constants.%int_32) [concrete = constants.%Core.IntLiteral.as.ImplicitAs.impl.Convert.specific_fn]
// CHECK:STDOUT:   %bound_method.loc11_28.2: <bound method> = bound_method %int_3, %specific_fn.loc11_28 [concrete = constants.%bound_method.763]
// CHECK:STDOUT:   %Core.IntLiteral.as.ImplicitAs.impl.Convert.call: init %i32 = call %bound_method.loc11_28.2(%int_3) [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc11_28.1: %i32 = value_of_initializer %Core.IntLiteral.as.ImplicitAs.impl.Convert.call [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %.loc11_28.2: %i32 = converted %int_3, %.loc11_28.1 [concrete = constants.%int_3.410]
// CHECK:STDOUT:   %G.call.loc11_29: init %i32 = call %G.ref.loc11_29(%.loc11_28.2)
// CHECK:STDOUT:   %G.ref.loc11_33: %G.overload_set.type = name_ref G, imports.%Main.G [concrete = constants.%G.overload_set.value]
// CHECK:STDOUT:   %true: bool = bool_literal true [concrete = constants.%true]
// CHECK:STDOUT:   %G.ref.loc11_39: %G.type.f42045.1 = name_ref G, imports.%G.decl.1f85e1.1 [concrete = constants.%G.4228ed.1]
// CHECK:STDOUT:   %G.call.loc11_39: init %i32 = call %G.ref.loc11_39(%true)
// CHECK:STDOUT:   %impl.elem1: %.d47 = impl_witness_access constants.%AddWith.impl_witness.833, element1 [concrete = constants.%Int.as.AddWith.impl.Op.365]
// CHECK:STDOUT:   %bound_method.loc11_31.1: <bound method> = bound_method %G.call.loc11_29, %impl.elem1
// CHECK:STDOUT:   %specific_fn.loc11_31: <specific function> = specific_function %impl.elem1, @Int.as.AddWith.impl.Op.1(constants.%int_32) [concrete = constants.%Int.as.AddWith.impl.Op.specific_fn.f25]
// CHECK:STDOUT:   %bound_method.loc11_31.2: <bound method> = bound_method %G.call.loc11_29, %specific_fn.loc11_31
// CHECK:STDOUT:   %.loc11_29.1: %i32 = value_of_initializer %G.call.loc11_29
// CHECK:STDOUT:   %.loc11_29.2: %i32 = converted %G.call.loc11_29, %.loc11_29.1
// CHECK:STDOUT:   %.loc11_39.1: %i32 = value_of_initializer %G.call.loc11_39
// CHECK:STDOUT:   %.loc11_39.2: %i32 = converted %G.call.loc11_39, %.loc11_39.1
// CHECK:STDOUT:   %Int.as.AddWith.impl.Op.call: init %i32 = call %bound_method.loc11_31.2(%.loc11_29.2, %.loc11_39.2)
// CHECK:STDOUT:   return %Int.as.AddWith.impl.Op.call
// CHECK:STDOUT: }
// CHECK:STDOUT:
