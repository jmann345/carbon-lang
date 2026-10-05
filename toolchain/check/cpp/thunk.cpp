// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/cpp/thunk.h"

#include "clang/AST/ASTConsumer.h"
#include "clang/AST/DeclCXX.h"
#include "clang/AST/GlobalDecl.h"
#include "clang/AST/Mangle.h"
#include "clang/AST/Stmt.h"
#include "clang/Basic/TargetInfo.h"
#include "clang/Sema/Lookup.h"
#include "clang/Sema/Overload.h"
#include "clang/Sema/Sema.h"
#include "toolchain/check/call.h"
#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/core_identifier.h"
#include "toolchain/check/cpp/context.h"
#include "toolchain/check/cpp/import.h"
#include "toolchain/check/cpp/location.h"
#include "toolchain/check/impl_lookup.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/member_access.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/operator.h"
#include "toolchain/check/type.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/parse/node_kind.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

// Generate and return a function:
// `void* operator new(__SIZE_TYPE__, void*) noexcept`.
static auto GeneratePlacementNewFunctionDecl(clang::ASTContext& context)
    -> clang::FunctionDecl* {
  clang::QualType size_type = context.getSizeType();
  clang::QualType void_ptr_type = context.VoidPtrTy;

  auto ext_info = clang::FunctionProtoType::ExtProtoInfo();
  ext_info.ExceptionSpec.Type = clang::EST_BasicNoexcept;

  clang::QualType function_type = context.getFunctionType(
      void_ptr_type, {size_type, void_ptr_type}, ext_info);

  clang::DeclarationName name =
      context.DeclarationNames.getCXXOperatorName(clang::OO_New);

  clang::FunctionDecl* function_decl = clang::FunctionDecl::Create(
      context, context.getTranslationUnitDecl(), clang::SourceLocation(),
      clang::SourceLocation(), name, function_type,
      /*TInfo=*/nullptr, clang::SC_None);

  clang::ParmVarDecl* size_param = clang::ParmVarDecl::Create(
      context, function_decl, clang::SourceLocation(), clang::SourceLocation(),
      nullptr, size_type, nullptr, clang::SC_None, nullptr);
  clang::ParmVarDecl* ptr_param = clang::ParmVarDecl::Create(
      context, function_decl, clang::SourceLocation(), clang::SourceLocation(),
      nullptr, void_ptr_type, nullptr, clang::SC_None, nullptr);

  function_decl->setParams({size_param, ptr_param});
  CARBON_CHECK(function_decl->isReservedGlobalPlacementOperator());
  return function_decl;
}

// Returns the synthesized declaration
//
//   extern "C" void* __cxa_current_primary_exception() noexcept;
//
// used by catching thunks to capture the in-flight exception object
// (libcxxabi/include/cxxabi.h:170; cxa_exception.cpp:713-729 returns the
// thrown object with its refcount incremented, or NULL for a foreign
// exception). The declaration sits inside a synthesized `extern "C"`
// `LinkageSpecDecl` at TU scope with NO asm label: a synthesized label is
// emitted literally on every target (Mangle.cpp), which on Darwin (user label
// prefix `_`) would name a symbol libc++abi does not define. C linkage lets the
// target's mangler add the prefix, and the declaration matches cxxabi.h's own,
// so a TU that also includes `<cxxabi.h>` sees a compatible redeclaration.
// Cached on `CppContext`.
static auto GetOrCreateCxaCurrentPrimaryExceptionDecl(
    CppContext& cpp_context, clang::Sema& sema, clang::SourceLocation clang_loc)
    -> clang::FunctionDecl* {
  if (auto* decl = cpp_context.cxa_current_primary_exception_decl()) {
    return decl;
  }
  clang::ASTContext& ast_context = sema.getASTContext();
  clang::TranslationUnitDecl* tu_decl = ast_context.getTranslationUnitDecl();

  auto* linkage_spec_decl = clang::LinkageSpecDecl::Create(
      ast_context, tu_decl, clang_loc, clang_loc,
      clang::LinkageSpecLanguageIDs::C, /*HasBraces=*/false);
  tu_decl->addDecl(linkage_spec_decl);

  auto ext_info = clang::FunctionProtoType::ExtProtoInfo();
  ext_info.ExceptionSpec.Type = clang::EST_BasicNoexcept;
  clang::QualType function_type =
      ast_context.getFunctionType(ast_context.VoidPtrTy, {}, ext_info);

  clang::FunctionDecl* function_decl = clang::FunctionDecl::Create(
      ast_context, linkage_spec_decl, clang_loc, clang_loc,
      clang::DeclarationName(
          &ast_context.Idents.get("__cxa_current_primary_exception")),
      function_type, ast_context.getTrivialTypeSourceInfo(function_type),
      clang::SC_Extern);
  function_decl->setParams({});
  linkage_spec_decl->addDecl(function_decl);

  cpp_context.set_cxa_current_primary_exception_decl(function_decl);
  return function_decl;
}

// Returns the synthesized declaration of POSIX `write(2)` used by the fenced
// thunks' boundary diagnostic (docs/design/error_handling.md, "The fenced
// boundary"; fork/eh/plan.md D-EH-5, §1.B.8):
//
//   long __carbon_boundary_write(int, const void*, __SIZE_TYPE__)
//       asm("<user label prefix>write");
//
// The identifier differs from any user-visible `write`, so a header's own
// `<unistd.h>` declaration (with its own `ssize_t` spelling) can never surface
// a redeclaration diagnostic inside a thunk; the asm label names libc's symbol
// and carries the target's user label prefix (`_` on Darwin, empty on ELF)
// because a synthesized label is emitted literally on every target. `write`
// is chosen over `printf` because `abort()` drops buffered stdout, and over a
// Carbon runtime helper because no linkable Carbon runtime object exists.
// Cached on `CppContext`.
static auto GetOrCreateBoundaryWriteDecl(CppContext& cpp_context,
                                         clang::Sema& sema,
                                         clang::SourceLocation clang_loc)
    -> clang::FunctionDecl* {
  if (auto* decl = cpp_context.boundary_write_decl()) {
    return decl;
  }
  clang::ASTContext& ast_context = sema.getASTContext();
  clang::TranslationUnitDecl* tu_decl = ast_context.getTranslationUnitDecl();

  clang::QualType param_types[] = {
      ast_context.IntTy,
      ast_context.getPointerType(ast_context.VoidTy.withConst()),
      ast_context.getSizeType()};
  auto ext_info = clang::FunctionProtoType::ExtProtoInfo();
  ext_info.ExceptionSpec.Type = clang::EST_BasicNoexcept;
  clang::QualType function_type =
      ast_context.getFunctionType(ast_context.LongTy, param_types, ext_info);

  clang::FunctionDecl* function_decl = clang::FunctionDecl::Create(
      ast_context, tu_decl, clang_loc, clang_loc,
      clang::DeclarationName(
          &ast_context.Idents.get("__carbon_boundary_write")),
      function_type, ast_context.getTrivialTypeSourceInfo(function_type),
      clang::SC_Extern);
  llvm::SmallVector<clang::ParmVarDecl*> params;
  for (clang::QualType param_type : param_types) {
    params.push_back(clang::ParmVarDecl::Create(
        ast_context, function_decl, clang_loc, clang_loc, nullptr, param_type,
        nullptr, clang::SC_None, nullptr));
  }
  function_decl->setParams(params);
  tu_decl->addDecl(function_decl);

  std::string label = ast_context.getTargetInfo().getUserLabelPrefix();
  label += "write";
  function_decl->addAttr(
      clang::AsmLabelAttr::CreateImplicit(ast_context, label, clang_loc));

  cpp_context.set_boundary_write_decl(function_decl);
  return function_decl;
}

// Returns the GlobalDecl to use to represent the given function declaration.
// TODO: Refactor with `Lower::CreateGlobalDecl`.
static auto GetGlobalDecl(const clang::FunctionDecl* decl)
    -> clang::GlobalDecl {
  if (const auto* ctor = dyn_cast<clang::CXXConstructorDecl>(decl)) {
    return clang::GlobalDecl(ctor, clang::CXXCtorType::Ctor_Complete);
  }
  if (const auto* dtor = dyn_cast<clang::CXXDestructorDecl>(decl)) {
    return clang::GlobalDecl(dtor, clang::CXXDtorType::Dtor_Complete);
  }
  return clang::GlobalDecl(decl);
}

// Returns the C++ thunk mangled name given the callee function. A catching
// thunk (`BuildCppCatchingThunk`) carries the `_catch` marker so it never
// collides with the fenced thunk of the same callee.
static auto GenerateThunkMangledName(
    clang::MangleContext& mangle_context,
    const clang::FunctionDecl* callee_function_decl,
    const SemIR::ClangDeclSignature& signature, bool is_catching = false)
    -> std::string {
  RawStringOstream mangled_name_stream;
  if (callee_function_decl != nullptr) {
    mangle_context.mangleName(GetGlobalDecl(callee_function_decl),
                              mangled_name_stream);
  }
  switch (signature.kind) {
    case SemIR::ClangDeclSignature::Normal:
      mangled_name_stream << ".carbon_thunk";
      break;
    case SemIR::ClangDeclSignature::TuplePattern:
      mangled_name_stream << ".carbon_thunk_tuple";
      break;
  }
  if (is_catching) {
    mangled_name_stream << "_catch";
  }

  // Append passing modes.
  // TODO: Pick one "likely" set of passing modes for the function and omit the
  // suffix for that signature.
  mangled_name_stream << ".";
  auto append_mode = [&](SemIR::ClangDeclSignature::PassingMode mode) {
    switch (mode) {
      case SemIR::ClangDeclSignature::PassingMode::ByValue:
        mangled_name_stream << "_";
        break;
      case SemIR::ClangDeclSignature::PassingMode::ByVar:
        mangled_name_stream << "v";
        break;
      case SemIR::ClangDeclSignature::PassingMode::ByRef:
        mangled_name_stream << "r";
        break;
    }
  };

  // If there is no decl, the callee is a function pointer, which we treat as
  // the thunk's `self` parameter.
  if (callee_function_decl == nullptr ||
      IsObjectMemberFunction(*callee_function_decl)) {
    append_mode(signature.self_passing_mode);
  }
  for (auto mode : signature.passing_modes) {
    append_mode(mode);
  }

  // Distinguish thunks that embed different constant function arguments: two
  // Carbon functions with the same signature resolve to the same callee (for
  // example one `std::thread` constructor instantiation), but their thunk
  // bodies reference different exported declarations.
  for (auto [i, constant_decl] :
       llvm::enumerate(signature.constant_function_args)) {
    if (!constant_decl) {
      continue;
    }
    RawStringOstream constant_name_stream;
    mangle_context.mangleName(GetGlobalDecl(constant_decl),
                              constant_name_stream);
    std::string constant_name = constant_name_stream.TakeStr();
    llvm::StringRef constant_name_ref = constant_name;
    // An asm-labelled declaration mangles to `\01<label>`; drop the marker.
    constant_name_ref.consume_front("\01");
    mangled_name_stream << ".arg" << i << "." << constant_name_ref;
  }

  return mangled_name_stream.TakeStr();
}

// Returns whether the Carbon lowering for a parameter or return of this type is
// known to match the C++ lowering.
static auto IsSimpleAbiType(clang::ASTContext& ast_context,
                            clang::QualType type, bool for_parameter) -> bool {
  if (type->isVoidType() || type->isPointerType()) {
    return true;
  }

  if (type->isReferenceType()) {
    if (for_parameter) {
      // A reference parameter has a simple ABI if it's a non-const lvalue
      // reference.  Otherwise, we map it to pass-by-value, and it's only simple
      // if the type uses a pointer value representation.
      //
      // TODO: Check whether the pointee type maps to a Carbon type that uses a
      // pointer value representation, and treat it as simple if so.
      return type->isLValueReferenceType() &&
             !type->getPointeeType().isConstQualified();
    }

    // A reference return type is always mapped to a Carbon pointer, which uses
    // the same ABI rule as a C++ reference.
    return true;
  }

  if (const auto* enum_decl = type->getAsEnumDecl()) {
    // An enum type has a simple ABI if its underlying type does.
    type = enum_decl->getIntegerType();
    if (type.isNull()) {
      return false;
    }
  }

  if (const auto* builtin_type = type->getAs<clang::BuiltinType>()) {
    if (builtin_type->isIntegerType()) {
      uint64_t type_size = ast_context.getIntWidth(type);
      return type_size == 32 || type_size == 64;
    }
  }

  return false;
}

CalleeFunctionInfo::CalleeFunctionInfo(Context& context,
                                       clang::FunctionDecl* decl,
                                       SemIR::ClangDeclSignatureId signature_id)
    : decl(decl),
      decl_name(decl->getDeclName()),
      clang_loc(decl->getLocation()),
      sem_ir_loc(AddImportIRInst(context.sem_ir(), clang_loc)),
      function_type(decl->getType()->getAs<clang::FunctionProtoType>()),
      signature_id(signature_id),
      signature(&context.clang_decl_signatures().Get(signature_id)),
      num_callee_params(signature->num_params +
                        decl->hasCXXExplicitFunctionObjectParameter()) {
  auto& ast_context = decl->getASTContext();
  const auto* method_decl = dyn_cast<clang::CXXMethodDecl>(decl);
  bool is_ctor = isa<clang::CXXConstructorDecl>(decl);
  if (IsObjectMemberFunction(*decl)) {
    self_param_type = method_decl->getFunctionObjectParameterReferenceType();
    if (method_decl->isImplicitObjectMemberFunction()) {
      self_param_kind = SelfParamKind::ImplicitObjectParam;
    } else {
      self_param_kind = SelfParamKind::ExplicitObjectParam;
    }
  } else {
    self_param_kind = SelfParamKind::None;
  }
  effective_return_type =
      is_ctor ? ast_context.getCanonicalTagType(method_decl->getParent())
              : decl->getReturnType();
  has_simple_return_type = IsSimpleAbiType(ast_context, effective_return_type,
                                           /*for_parameter=*/false);
}

CalleeFunctionInfo::CalleeFunctionInfo(Context& context,
                                       const clang::Type* function_pointer_type)
    : self_param_kind(SelfParamKind::FunctionPointer),
      decl(nullptr),
      decl_name(&context.ast_context().Idents.get("__invoke")),
      clang_loc(),
      sem_ir_loc(SemIR::LocId::None),
      function_type(function_pointer_type->getPointeeType()
                        ->getAs<clang::FunctionProtoType>()),
      signature_id(SemIR::ClangDeclSignatureId::None),
      signature(nullptr),
      num_callee_params(function_type->getNumParams()),
      self_param_type(function_pointer_type, 0),
      effective_return_type(function_type->getReturnType()),
      has_simple_return_type(IsSimpleAbiType(context.ast_context(),
                                             effective_return_type,
                                             /*for_parameter=*/false)) {
  SemIR::ClangDeclSignature local_signature;
  local_signature.kind = SemIR::ClangDeclSignature::Normal;
  local_signature.num_params =
      static_cast<int32_t>(function_type->getNumParams());
  local_signature.self_passing_mode =
      SemIR::ClangDeclSignature::PassingMode::ByValue;
  local_signature.passing_modes.assign(
      local_signature.num_params,
      SemIR::ClangDeclSignature::PassingMode::ByValue);
  signature_id =
      context.clang_decl_signatures().Add(std::move(local_signature));
  signature = &context.clang_decl_signatures().Get(signature_id);
}

auto CalleeFunctionInfo::GetCalleeParamIdentifier(int i) const
    -> clang::IdentifierInfo* {
  switch (self_param_kind) {
    case SelfParamKind::FunctionPointer:
      return nullptr;
    default:
      return decl->getParamDecl(i)->getIdentifier();
  }
}

auto CalleeFunctionInfo::GetCalleeParamLocation(int i) const
    -> clang::SourceLocation {
  switch (self_param_kind) {
    case SelfParamKind::FunctionPointer:
      return {};
    default:
      return decl->getParamDecl(i)->getLocation();
  }
}

auto IsCppThunkFenceRequired(Context& context,
                             const clang::FunctionProtoType* function_type,
                             const clang::FunctionDecl* decl_or_null) -> bool {
  if (!context.ast_context().getLangOpts().CXXExceptions) {
    return false;
  }
  const clang::FunctionProtoType* proto = function_type;
  // Implicit and defaulted special members and unannotated destructors carry
  // an unevaluated exception specification, which `canThrow` rejects; resolve
  // it first, mirroring `Sema::MarkFunctionReferenced`. A function pointer
  // type has no declaration to resolve through.
  if (proto && decl_or_null &&
      clang::isUnresolvedExceptionSpec(proto->getExceptionSpecType())) {
    proto = context.clang_sema().ResolveExceptionSpec(
        decl_or_null->getLocation(), proto);
  }
  // A callee whose specification cannot be resolved is conservatively treated
  // as potentially-throwing.
  return !proto ||
         clang::isUnresolvedExceptionSpec(proto->getExceptionSpecType()) ||
         proto->canThrow() != clang::CT_Cannot;
}

auto IsCppThunkFenceRequired(Context& context, const clang::FunctionDecl* decl)
    -> bool {
  return IsCppThunkFenceRequired(
      context, decl->getType()->castAs<clang::FunctionProtoType>(), decl);
}

auto IsCppThunkRequired(Context& context, const CalleeFunctionInfo& callee_info)
    -> bool {
  auto* decl = cast<clang::FunctionDecl>(callee_info.decl);

  // Fork (EH-B, D-UA-7 component 3): with C++ exceptions enabled, every
  // potentially-throwing callee crosses the boundary through a fenced thunk
  // (docs/design/error_handling.md#the-fenced-boundary-terminate-semantics),
  // even when its ABI would not need one.
  if (IsCppThunkFenceRequired(context, callee_info.function_type, decl)) {
    return true;
  }

  if (callee_info.signature->kind != SemIR::ClangDeclSignature::Normal ||
      callee_info.signature->num_params !=
          static_cast<int>(decl->getNumNonObjectParams())) {
    // We require a thunk if the number of parameters we want isn't all of them.
    // This happens if default arguments are in use, or (eventually) when
    // calling a varargs function.
    return true;
  }

  if (!callee_info.has_simple_return_type) {
    return true;
  }

  auto& ast_context = context.ast_context();
  if (!callee_info.self_param_type.isNull() &&
      (!IsSimpleAbiType(ast_context, callee_info.self_param_type,
                        /*for_parameter=*/true) ||
       callee_info.signature->self_passing_mode ==
           SemIR::ClangDeclSignature::PassingMode::ByVar)) {
    return true;
  }

  const auto* function_type =
      decl->getType()->castAs<clang::FunctionProtoType>();
  for (int i : llvm::seq(decl->getNumParams())) {
    if (!IsSimpleAbiType(ast_context, function_type->getParamType(i),
                         /*for_parameter=*/true) ||
        callee_info.signature->GetPassingMode(i) ==
            SemIR::ClangDeclSignature::PassingMode::ByVar) {
      return true;
    }
  }

  return false;
}

// Given a pointer type, returns the corresponding _Nonnull-qualified pointer
// type.
static auto GetNonnullType(clang::ASTContext& ast_context,
                           clang::QualType pointer_type) -> clang::QualType {
  return ast_context.getAttributedType(clang::NullabilityKind::NonNull,
                                       pointer_type, pointer_type);
}

// Given a type, returns the corresponding _Nonnull-qualified pointer type,
// ignoring references.
static auto GetNonNullablePointerType(clang::ASTContext& ast_context,
                                      clang::QualType type) {
  return GetNonnullType(ast_context,
                        ast_context.getPointerType(type.getNonReferenceType()));
}

// Given the type of a callee parameter, returns the type to use for the
// corresponding thunk parameter.
static auto GetThunkParameterType(clang::ASTContext& ast_context,
                                  clang::QualType callee_type)
    -> clang::QualType {
  if (IsSimpleAbiType(ast_context, callee_type, /*for_parameter=*/true)) {
    return callee_type;
  }
  return GetNonNullablePointerType(ast_context, callee_type);
}

// Creates the thunk parameter types given the callee function.
static auto BuildThunkParameterTypes(clang::ASTContext& ast_context,
                                     CalleeFunctionInfo callee_info)
    -> llvm::SmallVector<clang::QualType> {
  llvm::SmallVector<clang::QualType> thunk_param_types;
  thunk_param_types.reserve(callee_info.num_thunk_params());
  if (callee_info.callee_param_to_carbon_param_offset() > 0) {
    thunk_param_types.push_back(callee_info.self_param_type);
  }

  for (int i : llvm::seq(callee_info.num_callee_params)) {
    thunk_param_types.push_back(GetThunkParameterType(
        ast_context, callee_info.function_type->getParamType(i)));
  }

  if (!callee_info.has_simple_return_type) {
    thunk_param_types.push_back(GetNonNullablePointerType(
        ast_context, callee_info.effective_return_type));
  }

  CARBON_CHECK(thunk_param_types.size() == callee_info.num_thunk_params());
  return thunk_param_types;
}

// Returns the thunk parameters using the callee function parameter identifiers.
static auto BuildThunkParameters(clang::ASTContext& ast_context,
                                 CalleeFunctionInfo callee_info,
                                 clang::SourceLocation clang_loc,
                                 clang::FunctionDecl* thunk_function_decl,
                                 bool is_catching = false)
    -> llvm::SmallVector<clang::ParmVarDecl*> {
  const auto* thunk_function_proto_type =
      thunk_function_decl->getType()->castAs<clang::FunctionProtoType>();

  llvm::SmallVector<clang::ParmVarDecl*> thunk_params;
  unsigned num_thunk_params = thunk_function_decl->getNumParams();
  thunk_params.reserve(num_thunk_params);

  if (callee_info.callee_param_to_carbon_param_offset() > 0) {
    clang::ParmVarDecl* thunk_param =
        clang::ParmVarDecl::Create(ast_context, thunk_function_decl, clang_loc,
                                   clang_loc, &ast_context.Idents.get("this"),
                                   thunk_function_proto_type->getParamType(0),
                                   nullptr, clang::SC_None, nullptr);
    thunk_params.push_back(thunk_param);
  }

  for (int i : llvm::seq(callee_info.num_callee_params)) {
    clang::ParmVarDecl* thunk_param = clang::ParmVarDecl::Create(
        ast_context, thunk_function_decl, clang_loc, clang_loc,
        callee_info.GetCalleeParamIdentifier(i),
        thunk_function_proto_type->getParamType(
            i + callee_info.callee_param_to_carbon_param_offset()),
        nullptr, clang::SC_None, nullptr);
    thunk_params.push_back(thunk_param);
  }

  if (!callee_info.has_simple_return_type) {
    int thunk_return_index = callee_info.num_callee_params +
                             callee_info.callee_param_to_carbon_param_offset();
    clang::ParmVarDecl* thunk_param = clang::ParmVarDecl::Create(
        ast_context, thunk_function_decl, clang_loc, clang_loc,
        &ast_context.Idents.get("return"),
        thunk_function_proto_type->getParamType(thunk_return_index), nullptr,
        clang::SC_None, nullptr);
    thunk_params.push_back(thunk_param);
  }

  if (is_catching) {
    // The catching thunk's trailing out-parameter receives the captured
    // primary exception object pointer (`BuildCatchingThunkBody`).
    clang::ParmVarDecl* thunk_param = clang::ParmVarDecl::Create(
        ast_context, thunk_function_decl, clang_loc, clang_loc,
        &ast_context.Idents.get("error"),
        thunk_function_proto_type->getParamType(num_thunk_params - 1), nullptr,
        clang::SC_None, nullptr);
    thunk_params.push_back(thunk_param);
  }

  CARBON_CHECK(thunk_params.size() == num_thunk_params);
  return thunk_params;
}

// Computes a name to use for a thunk, based on the name of the thunk's target.
// The actual name used isn't critical, since it doesn't show up much except in
// AST dumps and SemIR output, but we try to produce a valid C++ identifier.
//
// A catching thunk gets a DISTINCT identifier from the fenced thunk of the same
// callee: this identifier becomes the imported SemIR function's name, and
// reusing the fenced one would form a C++ overload set of the two thunks and
// two SemIR functions with one name.
static auto GetDeclNameForThunk(clang::ASTContext& ast_context,
                                clang::DeclarationName name,
                                bool is_catching = false)
    -> clang::DeclarationName {
  llvm::SmallString<64> thunk_name;
  switch (name.getNameKind()) {
    case clang::DeclarationName::NameKind::Identifier: {
      thunk_name = name.getAsIdentifierInfo()->getName();
      break;
    }
    case clang::DeclarationName::NameKind::CXXOperatorName: {
      thunk_name = "operator_";
      switch (name.getCXXOverloadedOperator()) {
        case clang::OO_None:
        case clang::NUM_OVERLOADED_OPERATORS:
          break;
#define OVERLOADED_OPERATOR(Name, Spelling, Token, Unary, Binary, MemberOnly) \
  case clang::OO_##Name:                                                      \
    thunk_name += #Name;                                                      \
    break;
#include "clang/Basic/OperatorKinds.def"
      }
      break;
    }
    default: {
      break;
    }
  }
  if (auto type = name.getCXXNameType(); !type.isNull()) {
    if (auto* class_decl = type->getAsCXXRecordDecl()) {
      thunk_name += class_decl->getName();
    }
  }
  thunk_name += is_catching ? "__carbon_catching_thunk" : "__carbon_thunk";
  return &ast_context.Idents.get(thunk_name);
}

// Returns the thunk function declaration given the callee function and the
// thunk parameter types. A catching thunk (`is_catching`) returns its `int`
// discriminant directly and carries the distinct catching name and asm label.
static auto CreateThunkFunctionDecl(
    Context& context, CalleeFunctionInfo callee_info,
    clang::SourceLocation clang_loc,
    llvm::ArrayRef<clang::QualType> thunk_param_types, bool is_catching = false)
    -> clang::FunctionDecl* {
  clang::ASTContext& ast_context = context.ast_context();
  clang::DeclarationName name =
      GetDeclNameForThunk(ast_context, callee_info.decl_name, is_catching);

  auto ext_proto_info = clang::FunctionProtoType::ExtProtoInfo();
  if (ast_context.getLangOpts().CXXExceptions) {
    // Fence: an exception escaping the wrapped call reaches this noexcept
    // boundary and terminates deterministically at the thunk.
    ext_proto_info.ExceptionSpec.Type = clang::EST_BasicNoexcept;
  }
  clang::QualType thunk_return_type = is_catching ? ast_context.IntTy
                                      : callee_info.has_simple_return_type
                                          ? callee_info.effective_return_type
                                          : ast_context.VoidTy;
  clang::QualType thunk_function_type = ast_context.getFunctionType(
      thunk_return_type, thunk_param_types, ext_proto_info);

  clang::DeclContext* decl_context = ast_context.getTranslationUnitDecl();
  clang::FunctionDecl* thunk_function_decl = clang::FunctionDecl::Create(
      ast_context, decl_context, clang_loc, clang_loc, name,
      thunk_function_type, /*TInfo=*/nullptr, clang::SC_None,
      /*UsesFPIntrin=*/false, /*isInlineSpecified=*/true);
  decl_context->addDecl(thunk_function_decl);

  thunk_function_decl->setParams(BuildThunkParameters(
      ast_context, callee_info, clang_loc, thunk_function_decl, is_catching));

  // Force the thunk to be inlined and discarded.
  thunk_function_decl->addAttr(
      clang::AlwaysInlineAttr::CreateImplicit(ast_context));
  thunk_function_decl->addAttr(
      clang::InternalLinkageAttr::CreateImplicit(ast_context));

  // Set asm("<callee function mangled name>.carbon_thunk").
  thunk_function_decl->addAttr(clang::AsmLabelAttr::CreateImplicit(
      ast_context,
      GenerateThunkMangledName(context.cpp_context()->clang_mangle_context(),
                               callee_info.decl, *callee_info.signature,
                               is_catching),
      clang_loc));

  // Set function declaration type source info.
  thunk_function_decl->setTypeSourceInfo(ast_context.getTrivialTypeSourceInfo(
      thunk_function_decl->getType(), clang_loc));

  return thunk_function_decl;
}

// Builds a reference to the given parameter thunk. If `type` is specified, that
// is the callee parameter type that's being held by the parameter, and
// conversions will be performed as necessary to recover a value of that type.
static auto BuildThunkParamRef(
    clang::Sema& sema, clang::FunctionDecl* thunk_function_decl,
    unsigned thunk_index, SemIR::ClangDeclSignature::PassingMode passing_mode,
    clang::QualType type = clang::QualType()) -> clang::Expr* {
  clang::ParmVarDecl* thunk_param =
      thunk_function_decl->getParamDecl(thunk_index);
  clang::SourceLocation clang_loc = thunk_param->getLocation();

  clang::Expr* call_arg = sema.BuildDeclRefExpr(
      thunk_param, thunk_param->getType().getNonReferenceType(),
      clang::VK_LValue, clang_loc);
  if (!type.isNull() && thunk_param->getType() != type) {
    clang::ExprResult deref_result =
        sema.BuildUnaryOp(nullptr, clang_loc, clang::UO_Deref, call_arg);
    CARBON_CHECK(deref_result.isUsable());
    call_arg = deref_result.get();
  }

  // Cast to an xvalue when using pass-by-`var` or when initializing an rvalue
  // reference (which might be passed by value if it's const-qualified).
  if (passing_mode == SemIR::ClangDeclSignature::PassingMode::ByVar ||
      (!type.isNull() && type->isRValueReferenceType())) {
    call_arg = clang::ImplicitCastExpr::Create(
        sema.getASTContext(), call_arg->getType(), clang::CK_NoOp, call_arg,
        nullptr, clang::ExprValueKind::VK_XValue, clang::FPOptionsOverride());
  }
  return call_arg;
}

// Builds a reference to the parameter thunk parameter corresponding to the
// given callee parameter index.
static auto BuildParamRefForCalleeArg(clang::Sema& sema,
                                      clang::FunctionDecl* thunk_function_decl,
                                      CalleeFunctionInfo callee_info,
                                      unsigned callee_index) -> clang::Expr* {
  unsigned thunk_index =
      callee_index + callee_info.callee_param_to_carbon_param_offset();
  return BuildThunkParamRef(
      sema, thunk_function_decl, thunk_index,
      callee_info.signature->GetPassingMode(callee_index),
      callee_info.function_type->getParamType(callee_index));
}

// Builds an argument list for the callee function by creating suitable uses of
// the corresponding thunk parameters.
static auto BuildCalleeArgs(clang::Sema& sema,
                            clang::FunctionDecl* thunk_function_decl,
                            CalleeFunctionInfo callee_info)
    -> llvm::SmallVector<clang::Expr*> {
  llvm::SmallVector<clang::Expr*> call_args;
  call_args.reserve(callee_info.num_callee_params -
                    callee_info.callee_arg_to_callee_param_offset());
  for (unsigned callee_index :
       llvm::seq(callee_info.callee_arg_to_callee_param_offset(),
                 callee_info.num_callee_params)) {
    call_args.push_back(BuildParamRefForCalleeArg(sema, thunk_function_decl,
                                                  callee_info, callee_index));
  }
  return call_args;
}

// Builds the expression calling the callee function with the thunk's
// parameters as arguments (or, for a constructor, the corresponding
// construction). Returns an invalid result on failure.
static auto BuildCalleeCallExpr(clang::Sema& sema,
                                clang::SourceLocation clang_loc,
                                clang::FunctionDecl* thunk_function_decl,
                                CalleeFunctionInfo callee_info)
    -> clang::ExprResult {
  // If the callee has an object parameter, build a member access expression as
  // the callee. Otherwise, build a regular reference to the function.
  clang::ExprResult callee;
  switch (callee_info.self_param_kind) {
    case CalleeFunctionInfo::SelfParamKind::ExplicitObjectParam:
    case CalleeFunctionInfo::SelfParamKind::ImplicitObjectParam: {
      clang::QualType object_param_type =
          cast<clang::CXXMethodDecl>(callee_info.decl)
              ->getFunctionObjectParameterReferenceType();
      auto* object_param_ref = BuildThunkParamRef(
          sema, thunk_function_decl, /*thunk_index=*/0,
          callee_info.signature->self_passing_mode, object_param_type);
      constexpr bool IsArrow = false;
      auto object =
          sema.PerformMemberExprBaseConversion(object_param_ref, IsArrow);
      if (object.isInvalid()) {
        return clang::ExprError();
      }
      callee = sema.BuildMemberExpr(
          object.get(), IsArrow, clang_loc, clang::NestedNameSpecifierLoc(),
          clang::SourceLocation(), callee_info.decl,
          clang::DeclAccessPair::make(callee_info.decl, clang::AS_public),
          /*HadMultipleCandidates=*/false,
          clang::DeclarationNameInfo(callee_info.decl->getDeclName(),
                                     clang_loc),
          sema.getASTContext().BoundMemberTy, clang::VK_PRValue,
          clang::OK_Ordinary);
      break;
    }
    case CalleeFunctionInfo::SelfParamKind::FunctionPointer:
      callee = BuildThunkParamRef(sema, thunk_function_decl, 0,
                                  callee_info.signature->self_passing_mode,
                                  callee_info.self_param_type);
      break;
    case CalleeFunctionInfo::SelfParamKind::None:
      if (isa<clang::CXXConstructorDecl>(callee_info.decl)) {
        break;
      }
      callee =
          sema.BuildDeclRefExpr(callee_info.decl, callee_info.decl->getType(),
                                clang::VK_PRValue, clang_loc);
      break;
  }

  if (callee.isInvalid()) {
    return clang::ExprError();
  }

  // Build the argument list.
  llvm::SmallVector<clang::Expr*> call_args =
      BuildCalleeArgs(sema, thunk_function_decl, callee_info);

  clang::ExprResult call;
  if (auto info = callee_info.decl ? clang::getConstructorInfo(callee_info.decl)
                                   : clang::ConstructorInfo{};
      info.Constructor) {
    // In C++, there are no direct calls to constructors, only initialization,
    // so we need to type-check and build the call ourselves.
    auto type = sema.Context.getCanonicalTagType(
        cast<clang::CXXRecordDecl>(callee_info.decl->getParent()));
    llvm::SmallVector<clang::Expr*> converted_args;
    converted_args.reserve(call_args.size());
    if (sema.CompleteConstructorCall(info.Constructor, type, call_args,
                                     clang_loc, converted_args)) {
      return clang::ExprError();
    }
    call = sema.BuildCXXConstructExpr(
        clang_loc, type, callee_info.decl, info.Constructor, converted_args,
        false, false, false, false, clang::CXXConstructionKind::Complete,
        clang_loc);
  } else {
    call = sema.BuildCallExpr(nullptr, callee.get(), clang_loc, call_args,
                              clang_loc);
  }
  return call;
}

// Builds the statement that stores the callee's return value into the object
// the thunk's return out-parameter points at, by placement new:
// `new (return) T(<call>)`.
static auto BuildReturnValueStore(CppContext& cpp_context, clang::Sema& sema,
                                  clang::SourceLocation clang_loc,
                                  clang::FunctionDecl* thunk_function_decl,
                                  CalleeFunctionInfo callee_info,
                                  clang::Expr* call) -> clang::StmtResult {
  int return_thunk_index = callee_info.num_callee_params +
                           callee_info.callee_param_to_carbon_param_offset();
  auto* return_object_addr =
      BuildThunkParamRef(sema, thunk_function_decl, return_thunk_index,
                         SemIR::ClangDeclSignature::PassingMode::ByValue);
  auto return_type = callee_info.effective_return_type.getNonReferenceType();
  auto* return_type_info =
      sema.Context.getTrivialTypeSourceInfo(return_type, clang_loc);

  auto* placement_new_decl = cpp_context.placement_new_decl();
  if (!placement_new_decl) {
    placement_new_decl = GeneratePlacementNewFunctionDecl(sema.getASTContext());
    cpp_context.set_placement_new_decl(placement_new_decl);
  }
  sema.MarkFunctionReferenced(clang_loc, placement_new_decl);
  clang::ImplicitAllocationParameters params(return_type,
                                             clang::TypeAwareAllocationMode::No,
                                             clang::AlignedAllocationMode::No);
  clang::SourceRange range(clang_loc, clang_loc);
  auto* placement_new = clang::CXXNewExpr::Create(
      sema.getASTContext(), /*IsGlobalNew*/ true, placement_new_decl,
      /*OperatorDelete*/ nullptr, params, /*UsualArrayDeleteWantsSize*/ false,
      {return_object_addr},
      /*TypeIdParens=*/clang::SourceRange(), /*ArraySize=*/std::nullopt,
      clang::CXXNewInitializationStyle::Parens, call,
      sema.getASTContext().getPointerType(return_type), return_type_info, range,
      range);
  return sema.ActOnExprStmt(placement_new, /*DiscardedValue=*/true);
}

// Wraps the fenced thunk's statement in the boundary-identifying diagnostic
// (fork/eh/plan.md D-EH-5, SF-1):
//
//   try { <stmt> } catch (...) {
//     __carbon_boundary_write(2, "<message>", <length>);
//     throw;
//   }
//
// The rethrow leaves the handler inside the still-`noexcept` thunk, so it
// reaches the same terminate landing pad as before (B0's contract unchanged;
// libc++abi's verbose terminate additionally names the exception type), and
// the message names the C++ callee. The `CompoundStmt` wrappers are
// load-bearing (`ActOnCXXTryBlock` casts its try block to `CompoundStmt`).
static auto WrapInBoundaryDiagnostic(CppContext& cpp_context, clang::Sema& sema,
                                     clang::SourceLocation clang_loc,
                                     CalleeFunctionInfo callee_info,
                                     clang::Stmt* stmt) -> clang::StmtResult {
  clang::ASTContext& ast_context = sema.getASTContext();
  clang::CompoundStmt* try_block = clang::CompoundStmt::Create(
      ast_context, {stmt}, clang::FPOptionsOverride(), clang_loc, clang_loc);

  // A function pointer callee has no declaration; name its notional
  // `__invoke` method instead.
  std::string callee_name = callee_info.decl
                                ? callee_info.decl->getQualifiedNameAsString()
                                : callee_info.decl_name.getAsString();
  std::string message = "carbon: C++ exception escaped into Carbon through `" +
                        callee_name + "`; terminating\n";
  auto* message_literal = clang::StringLiteral::Create(
      ast_context, message, clang::StringLiteralKind::Ordinary,
      /*Pascal=*/false,
      ast_context.getStringLiteralArrayType(
          ast_context.CharTy, static_cast<unsigned>(message.size())),
      clang_loc);
  clang::FunctionDecl* write_decl =
      GetOrCreateBoundaryWriteDecl(cpp_context, sema, clang_loc);
  clang::Expr* write_ref = sema.BuildDeclRefExpr(
      write_decl, write_decl->getType(), clang::VK_PRValue, clang_loc);
  clang::Expr* write_args[] = {
      sema.ActOnIntegerConstant(clang_loc, 2).get(), message_literal,
      sema.ActOnIntegerConstant(clang_loc, static_cast<int64_t>(message.size()))
          .get()};
  clang::ExprResult write_call =
      sema.BuildCallExpr(nullptr, write_ref, clang_loc, write_args, clang_loc);
  clang::StmtResult write_stmt =
      sema.ActOnExprStmt(write_call, /*DiscardedValue=*/true);
  if (!write_stmt.isUsable()) {
    return clang::StmtError();
  }
  clang::StmtResult rethrow_stmt =
      sema.ActOnExprStmt(sema.BuildCXXThrow(clang_loc, /*Ex=*/nullptr,
                                            /*IsThrownVarInScope=*/false),
                         /*DiscardedValue=*/true);
  if (!rethrow_stmt.isUsable()) {
    return clang::StmtError();
  }
  clang::CompoundStmt* handler_block = clang::CompoundStmt::Create(
      ast_context, {write_stmt.get(), rethrow_stmt.get()},
      clang::FPOptionsOverride(), clang_loc, clang_loc);
  clang::StmtResult catch_stmt =
      sema.ActOnCXXCatchBlock(clang_loc, /*ExDecl=*/nullptr, handler_block);
  if (!catch_stmt.isUsable()) {
    return clang::StmtError();
  }
  return sema.ActOnCXXTryBlock(clang_loc, try_block, {catch_stmt.get()});
}

// Builds the thunk function body which calls the callee function using the call
// args and returns the callee function return value. When `fence_required`,
// the statement is wrapped in the boundary-identifying diagnostic. Returns
// nullptr on failure.
static auto BuildThunkBody(CppContext& cpp_context, clang::Sema& sema,
                           clang::SourceLocation clang_loc,
                           clang::FunctionDecl* thunk_function_decl,
                           CalleeFunctionInfo callee_info, bool fence_required)
    -> clang::StmtResult {
  // TODO: Consider building a CompoundStmt holding our created statement to
  // make our result more closely resemble a real C++ function.
  clang::ExprResult call =
      BuildCalleeCallExpr(sema, clang_loc, thunk_function_decl, callee_info);
  if (!call.isUsable()) {
    return clang::StmtError();
  }

  clang::StmtResult stmt =
      callee_info.has_simple_return_type
          ? sema.BuildReturnStmt(clang_loc, call.get())
          : BuildReturnValueStore(cpp_context, sema, clang_loc,
                                  thunk_function_decl, callee_info, call.get());
  if (!stmt.isUsable() || !fence_required) {
    return stmt;
  }
  return WrapInBoundaryDiagnostic(cpp_context, sema, clang_loc, callee_info,
                                  stmt.get());
}

// Builds the body of a catching thunk (docs/design/error_handling.md,
// "Catching imports"; fork/eh/plan.md §1.B.2):
//
//   try {
//     new (return) T(<call>);   // or `<call>;` for a `void` callee
//     return 0;
//   } catch (...) {
//     *error = __cxa_current_primary_exception();
//     return 1;
//   }
//
// The `CompoundStmt` wrappers are load-bearing: `ActOnCXXTryBlock` casts its
// try block to `CompoundStmt` (SemaStmt.cpp, `CXXTryStmt::Create`), and the
// handler follows the parser's compound-statement convention.
// `__cxa_current_primary_exception` returns NULL for a foreign exception (one
// not thrown by the C++ runtime), which the Carbon side stores as-is; the C++
// support header treats that as "no exception object".
static auto BuildCatchingThunkBody(CppContext& cpp_context, clang::Sema& sema,
                                   clang::SourceLocation clang_loc,
                                   clang::FunctionDecl* thunk_function_decl,
                                   CalleeFunctionInfo callee_info)
    -> clang::StmtResult {
  clang::ASTContext& ast_context = sema.getASTContext();

  clang::ExprResult call =
      BuildCalleeCallExpr(sema, clang_loc, thunk_function_decl, callee_info);
  if (!call.isUsable()) {
    return clang::StmtError();
  }

  // The try block: store the return value (if any) and return 0.
  llvm::SmallVector<clang::Stmt*> try_stmts;
  clang::StmtResult store_stmt =
      callee_info.has_simple_return_type
          ? sema.ActOnExprStmt(call, /*DiscardedValue=*/true)
          : BuildReturnValueStore(cpp_context, sema, clang_loc,
                                  thunk_function_decl, callee_info, call.get());
  if (!store_stmt.isUsable()) {
    return clang::StmtError();
  }
  try_stmts.push_back(store_stmt.get());
  clang::StmtResult return_ok = sema.BuildReturnStmt(
      clang_loc, sema.ActOnIntegerConstant(clang_loc, 0).get());
  if (!return_ok.isUsable()) {
    return clang::StmtError();
  }
  try_stmts.push_back(return_ok.get());
  clang::CompoundStmt* try_block = clang::CompoundStmt::Create(
      ast_context, try_stmts, clang::FPOptionsOverride(), clang_loc, clang_loc);

  // The handler: `*error = __cxa_current_primary_exception(); return 1;`.
  llvm::SmallVector<clang::Stmt*> handler_stmts;
  auto* error_param_ref = BuildThunkParamRef(
      sema, thunk_function_decl, thunk_function_decl->getNumParams() - 1,
      SemIR::ClangDeclSignature::PassingMode::ByValue);
  clang::ExprResult error_deref =
      sema.BuildUnaryOp(nullptr, clang_loc, clang::UO_Deref, error_param_ref);
  if (!error_deref.isUsable()) {
    return clang::StmtError();
  }
  clang::FunctionDecl* cxa_decl =
      GetOrCreateCxaCurrentPrimaryExceptionDecl(cpp_context, sema, clang_loc);
  clang::Expr* cxa_ref = sema.BuildDeclRefExpr(cxa_decl, cxa_decl->getType(),
                                               clang::VK_PRValue, clang_loc);
  clang::ExprResult cxa_call =
      sema.BuildCallExpr(nullptr, cxa_ref, clang_loc, {}, clang_loc);
  if (!cxa_call.isUsable()) {
    return clang::StmtError();
  }
  clang::ExprResult store_error = sema.BuildBinOp(
      nullptr, clang_loc, clang::BO_Assign, error_deref.get(), cxa_call.get());
  clang::StmtResult store_error_stmt =
      sema.ActOnExprStmt(store_error, /*DiscardedValue=*/true);
  if (!store_error_stmt.isUsable()) {
    return clang::StmtError();
  }
  handler_stmts.push_back(store_error_stmt.get());
  clang::StmtResult return_err = sema.BuildReturnStmt(
      clang_loc, sema.ActOnIntegerConstant(clang_loc, 1).get());
  if (!return_err.isUsable()) {
    return clang::StmtError();
  }
  handler_stmts.push_back(return_err.get());
  clang::CompoundStmt* handler_block = clang::CompoundStmt::Create(
      ast_context, handler_stmts, clang::FPOptionsOverride(), clang_loc,
      clang_loc);

  // `catch (...)`: a null exception declaration is the catch-all handler.
  clang::StmtResult catch_stmt =
      sema.ActOnCXXCatchBlock(clang_loc, /*ExDecl=*/nullptr, handler_block);
  if (!catch_stmt.isUsable()) {
    return clang::StmtError();
  }
  return sema.ActOnCXXTryBlock(clang_loc, try_block, {catch_stmt.get()});
}

auto BuildCppThunk(Context& context, const CalleeFunctionInfo& callee_info)
    -> clang::FunctionDecl* {
  // Build the thunk function declaration.
  auto thunk_param_types =
      BuildThunkParameterTypes(context.ast_context(), callee_info);
  clang::FunctionDecl* thunk_function_decl = CreateThunkFunctionDecl(
      context, callee_info, callee_info.clang_loc, thunk_param_types);

  // Build the thunk function body.
  clang::Sema& sema = context.clang_sema();
  clang::Sema::ContextRAII context_raii(sema, thunk_function_decl);
  sema.ActOnStartOfFunctionDef(nullptr, thunk_function_decl);
  clang::StmtResult body =
      BuildThunkBody(*context.cpp_context(), sema, callee_info.clang_loc,
                     thunk_function_decl, callee_info,
                     IsCppThunkFenceRequired(context, callee_info.function_type,
                                             callee_info.decl));
  sema.ActOnFinishFunctionBody(thunk_function_decl, body.get());
  if (body.isInvalid()) {
    return nullptr;
  }

  context.clang_sema().getASTConsumer().HandleTopLevelDecl(
      clang::DeclGroupRef(thunk_function_decl));
  return thunk_function_decl;
}

// Returns the Clang declaration of the C++ function `callee_function` was
// imported from.
static auto GetCalleeClangDecl(Context& context,
                               const SemIR::Function& callee_function)
    -> clang::FunctionDecl* {
  auto* clang_decl =
      context.clang_decls().Lookup(callee_function.first_decl_id());
  CARBON_CHECK(clang_decl);
  clang::FunctionDecl* callee_function_decl =
      clang_decl->key.decl->getAsFunction();
  CARBON_CHECK(callee_function_decl);
  return callee_function_decl;
}

auto BuildCppCatchingThunk(Context& context,
                           const SemIR::Function& callee_function)
    -> clang::FunctionDecl* {
  auto clang_decl_key =
      context.clang_decls().Lookup(callee_function.first_decl_id())->key;
  clang::FunctionDecl* callee_function_decl =
      clang_decl_key.decl->getAsFunction();
  CARBON_CHECK(callee_function_decl);

  CalleeFunctionInfo callee_info(context, callee_function_decl,
                                 clang_decl_key.signature_id);

  // A reference-returning callee would need its referent's ADDRESS stored
  // through the out-parameter, not a placement-new copy; that shape is not
  // built in 0.1 and fails closed (`GetOrBuildCppCatchingThunkDecl`).
  if (callee_info.effective_return_type->isReferenceType()) {
    return nullptr;
  }

  // The return value ALWAYS goes through the out-pointer (uniform shape; the
  // fenced thunk's simple-return split is not reused), except that a `void`
  // callee has no return out-parameter at all.
  callee_info.has_simple_return_type =
      callee_info.effective_return_type->isVoidType();

  clang::SourceLocation clang_loc = callee_function_decl->getLocation();
  CARBON_CHECK(clang_loc.isValid(), "Missing location for function");

  // Build the thunk function declaration: the callee's thunk parameters, the
  // return out-pointer, then `void* _Nonnull* _Nonnull error`.
  clang::ASTContext& ast_context = context.ast_context();
  auto thunk_param_types = BuildThunkParameterTypes(ast_context, callee_info);
  thunk_param_types.push_back(
      GetNonnullType(ast_context, ast_context.getPointerType(GetNonnullType(
                                      ast_context, ast_context.VoidPtrTy))));
  clang::FunctionDecl* thunk_function_decl = CreateThunkFunctionDecl(
      context, callee_info, clang_loc, thunk_param_types, /*is_catching=*/true);

  // Build the thunk function body.
  clang::Sema& sema = context.clang_sema();
  clang::Sema::ContextRAII context_raii(sema, thunk_function_decl);
  sema.ActOnStartOfFunctionDef(nullptr, thunk_function_decl);
  clang::StmtResult body =
      BuildCatchingThunkBody(*context.cpp_context(), sema, clang_loc,
                             thunk_function_decl, callee_info);
  sema.ActOnFinishFunctionBody(thunk_function_decl, body.get());
  if (body.isInvalid()) {
    return nullptr;
  }

  context.clang_sema().getASTConsumer().HandleTopLevelDecl(
      clang::DeclGroupRef(thunk_function_decl));
  return thunk_function_decl;
}

auto GetOrBuildCppCatchingThunkDecl(Context& context, SemIR::LocId loc_id,
                                    SemIR::FunctionId callee_function_id)
    -> SemIR::InstId {
  if (auto cached =
          context.cpp_catching_thunk_decls().Lookup(callee_function_id)) {
    return cached.value();
  }

  // The note anchor shared with the fenced thunk's build. No Clang diagnostic
  // is known to be reachable here from user code — the call expression is the
  // one the fenced thunk already built at import, the store is the same
  // placement new (or a `void` expression statement), and the handler is
  // synthesized — so this is defense in depth, not a pinned lane.
  Diagnostics::AnnotationScope annotate_diagnostics(
      &context.emitter(),
      [&](auto& builder) { NoteInCppThunk(builder, loc_id); });

  auto& callee_function = context.functions().Get(callee_function_id);
  SemIR::InstId thunk_decl_id = SemIR::InstId::None;
  if (clang::FunctionDecl* thunk_clang_decl =
          BuildCppCatchingThunk(context, callee_function)) {
    // Import the thunk exactly as the fenced thunk is imported (import.cpp,
    // `ImportFunctionDecl`): the bare function import over an all-by-value
    // signature. The general `ImportCppFunctionDecl` path must NOT be used:
    // it evaluates `IsCppThunkRequired` on the thunk itself, and a member
    // callee's implicit object parameter (`const C&` for a `const` method) is
    // not a simple ABI type, so it would build a thunk of the thunk and mark
    // this function `HasCppThunk` before `SetCppThunk` below.
    SemIR::ClangDeclSignature thunk_signature;
    thunk_signature.kind = SemIR::ClangDeclSignature::Normal;
    thunk_signature.num_params =
        static_cast<int32_t>(thunk_clang_decl->getNumParams());
    thunk_signature.passing_modes.assign(
        thunk_signature.num_params,
        SemIR::ClangDeclSignature::PassingMode::ByValue);
    SemIR::ClangDeclSignatureId thunk_signature_id =
        context.clang_decl_signatures().Add(std::move(thunk_signature));

    if (auto thunk_function_id = ImportCppThunkFunctionDecl(
            context, loc_id, thunk_clang_decl, thunk_signature_id)) {
      auto& thunk_function = context.functions().Get(*thunk_function_id);
      thunk_function.SetCppThunk(
          context.functions().Get(callee_function_id).first_owning_decl_id);
      thunk_decl_id = thunk_function.first_owning_decl_id;
    }
  }

  if (!thunk_decl_id.has_value()) {
    // Fail closed, the import.cpp fenced-thunk shape: the call falls back to
    // the FENCED thunk, never to an unfenced direct call. Only successes are
    // cached, so every call site reports the failure.
    context.TODO(loc_id,
                 "Unsupported: catching thunk for potentially-throwing C++ "
                 "function could not be built");
    return SemIR::InstId::None;
  }
  context.cpp_catching_thunk_decls().Insert(callee_function_id, thunk_decl_id);
  return thunk_decl_id;
}

// Returns whether the call located at `loc_id` is the direct operand of a
// postfix `?` (docs/design/error_handling.md, "Catching imports"; fork/eh/
// plan.md D-EH-4, §1.B.1). The test is on the parse tree's postorder: a
// `PostfixOperatorQuestion` has exactly one child, so the node following a
// complete `CallExpr` subtree is its parent iff that parent is the `?`. A
// `ParenExpr` also has exactly one expression child (plus its bracket), so the
// walk steps UP through parentheses: `(Cpp.f())?` and `((Cpp.f()))?` select
// the catching thunk — `?` binds to the value, not the spelling. Nested calls
// are safe: an argument's `CallExpr` is followed by more argument nodes, never
// directly by `?`. An import- or desugar-located call has no node.
static auto IsCatchingCallSite(Context& context, SemIR::LocId loc_id) -> bool {
  // A desugared location is still `Kind::NodeId`; only a call the user wrote
  // at that node is a candidate.
  if (loc_id.kind() != SemIR::LocId::Kind::NodeId || loc_id.is_desugared()) {
    return false;
  }
  const auto& tree = context.parse_tree();
  auto node_id = loc_id.node_id();
  if (!node_id.has_value() ||
      tree.node_kind(node_id) != Parse::NodeKind::CallExpr) {
    return false;
  }
  for (int index = node_id.index + 1; index < tree.size(); ++index) {
    auto kind = tree.node_kind(Parse::NodeId(index));
    if (kind == Parse::NodeKind::PostfixOperatorQuestion) {
      return true;
    }
    if (kind != Parse::NodeKind::ParenExpr) {
      return false;
    }
  }
  return false;
}

// Returns whether `type_id` implements `Core.Try`. The lookup runs in a
// discarded scratch block (the handle_question.cpp pre-flight idiom), so it
// emits nothing.
static auto ImplementsCoreTry(Context& context, SemIR::LocId loc_id,
                              SemIR::TypeId type_id) -> bool {
  context.inst_block_stack().Push();
  context.generic_region_stack().Push({.generic_id = SemIR::GenericId::None});
  auto try_interface_id =
      LookupNameInCore(context, loc_id, CoreIdentifier::Try);
  auto try_facet_type =
      ExprAsType(context, loc_id, try_interface_id, /*diagnose=*/false);
  bool implements_try = false;
  if (try_facet_type.type_id != SemIR::ErrorInst::TypeId) {
    auto lookup_result = LookupImplWitness(
        context, loc_id, context.types().GetConstantId(type_id),
        try_facet_type.type_id.AsConstantId(), /*diagnose=*/false);
    implements_try =
        !lookup_result.has_error_value() && lookup_result.has_value();
  }
  context.generic_region_stack().Pop();
  context.inst_block_stack().PopAndDiscard();
  return implements_try;
}

// Returns whether `success_type_id` is admitted as the success payload of a
// catching import's `Core.Result(S, Cpp.Exception)`: the check side's own SF-6
// choice-payload predicate (`IsInSliceChoicePayloadType`, type.cpp — int,
// float, bool, pointer after the adapter walk, and `()`), evaluated BEFORE the
// specific is formed. The type is completed first (without diagnosing) so an
// adapter's foundation walk resolves, mirroring the eval_inst.cpp pre-filter; a
// type that cannot be completed is not classifiable as a scalar.
static auto IsCatchingSuccessTypeAdmitted(Context& context, SemIR::LocId loc_id,
                                          SemIR::TypeId success_type_id)
    -> bool {
  return TryToCompleteType(context, success_type_id, loc_id) &&
         IsInSliceChoicePayloadType(context, success_type_id);
}

// Returns the Carbon type of a call to `callee_function`: its declared return
// type, or `()` for a `void` callee.
static auto GetCalleeResultType(Context& context,
                                const SemIR::Function& callee_function)
    -> SemIR::TypeId {
  auto return_type_id = callee_function.GetDeclaredReturnType(context.sem_ir());
  return return_type_id.has_value() ? return_type_id
                                    : GetTupleType(context, {});
}

// Builds the Carbon side of a catching call (fork/eh/plan.md §1.B.3): the
// value is `Core.Result(S, Cpp.Exception)`, where `S` is the callee's mapped
// return type. Returns `None` when the catching thunk could not be built (the
// caller then falls back to the fenced thunk) and `ErrorInst` after a
// diagnosed error.
static auto PerformCppCatchingThunkCall(
    Context& context, SemIR::LocId loc_id, SemIR::FunctionId callee_function_id,
    llvm::ArrayRef<SemIR::InstId> callee_arg_ids) -> SemIR::InstId {
  auto node_id = loc_id.node_id();
  const auto& callee_function = context.functions().Get(callee_function_id);
  bool is_void =
      !callee_function.GetDeclaredReturnType(context.sem_ir()).has_value();
  auto success_type_id = GetCalleeResultType(context, callee_function);

  // Peel the caller's return slot, if we were given one (the `TemporaryStorage`
  // `PerformCallToFunction` creates when the return type might be initialized
  // in place): it is the `ret` slot, never a second temporary.
  auto callee_function_params =
      context.inst_blocks().Get(callee_function.call_params_id);
  callee_function_params = callee_function_params.drop_back(
      callee_function.call_param_ranges.return_size());
  auto return_slot_id = SemIR::InstId::None;
  if (callee_arg_ids.size() == callee_function_params.size() + 1) {
    return_slot_id = callee_arg_ids.consume_back();
  }
  CARBON_CHECK(callee_arg_ids.size() == callee_function_params.size());

  // The SF-6 bound on the success type (fork/eh/plan.md §1.B.1): a non-scalar
  // `S` — a class, `std::string`, a constructor's class — cannot be a payload
  // of `Core.Result(S, Cpp.Exception)`. It is diagnosed HERE, naming the C++
  // callee, before the specific is formed: forming it would leave a
  // complete-with-error-layout class behind whose every later use (the `?`
  // desugar's `Branch`, the alternative constructors) cascades into
  // monomorphization errors.
  std::string callee_name =
      GetCalleeClangDecl(context, callee_function)->getQualifiedNameAsString();
  if (!IsCatchingSuccessTypeAdmitted(context, loc_id, success_type_id)) {
    CARBON_DIAGNOSTIC(CppCatchingImportNonScalarSuccess, Error,
                      "catching import of `{0}` requires a scalar success "
                      "type in 0.1; {1} is not one",
                      std::string, SemIR::TypeId);
    context.emitter().Emit(loc_id, CppCatchingImportNonScalarSuccess,
                           callee_name, success_type_id);
    return SemIR::ErrorInst::InstId;
  }

  // Form `Core.Result(S, Cpp.Exception)` the way `MakeOptionalType` forms
  // `Core.Optional(T)`, and complete it here. The predicate above IS the
  // specific's own SF-6 admission rule (`ChoicePayloadNotTrivialInSpecific`,
  // eval_inst.cpp, tests `IsInSliceChoicePayloadType` too), so the specific
  // cannot fail to complete; a drift between the two would be a toolchain
  // invariant violation, checked loudly rather than diagnosed (a rejected
  // specific completes with an error-valued layout, so `GetObjectRepr` is
  // tested as well).
  auto exception_type = ExprAsType(
      context, loc_id,
      LookupNameInCore(context, loc_id,
                       {CoreIdentifier::CppCompat, CoreIdentifier::Exception}));
  auto result_generic_id =
      LookupNameInCore(context, loc_id, CoreIdentifier::Result);
  auto result_type =
      ExprAsType(context, loc_id,
                 PerformCall(context, loc_id, result_generic_id,
                             {context.types().GetTypeInstId(success_type_id),
                              exception_type.inst_id}));
  if (result_type.type_id == SemIR::ErrorInst::TypeId ||
      exception_type.type_id == SemIR::ErrorInst::TypeId) {
    return SemIR::ErrorInst::InstId;
  }
  auto no_diagnostic_context =
      [](DiagnosticContextBuilder& /*builder*/) -> void {};
  CARBON_CHECK(RequireCompleteType(context, result_type.type_id, loc_id,
                                   no_diagnostic_context) &&
                   context.types().GetObjectRepr(result_type.type_id) !=
                       SemIR::ErrorInst::TypeId,
               "catching success type {0} passed IsInSliceChoicePayloadType "
               "but Core.Result({0}, Cpp.Exception) did not complete",
               success_type_id);

  // The catching thunk, built lazily and cached per file.
  auto thunk_decl_id =
      GetOrBuildCppCatchingThunkDecl(context, loc_id, callee_function_id);
  if (!thunk_decl_id.has_value()) {
    return SemIR::InstId::None;
  }
  auto thunk_callee = GetCalleeAsFunction(context.sem_ir(), thunk_decl_id);
  const auto& thunk_function =
      context.functions().Get(thunk_callee.function_id);
  auto thunk_function_params =
      context.inst_blocks().Get(thunk_function.call_params_id);
  thunk_function_params = thunk_function_params.drop_back(
      thunk_function.call_param_ranges.return_size());
  // The thunk returns the `int` discriminant: 0 = Ok, 1 = Err.
  auto disc_type_id = thunk_function.GetDeclaredReturnType(context.sem_ir());
  CARBON_CHECK(disc_type_id.has_value());
  CARBON_CHECK(thunk_function_params.size() ==
                   callee_function_params.size() + (is_void ? 1 : 2),
               "{0} != {1} + {2}", thunk_function_params.size(),
               callee_function_params.size(), is_void ? 1 : 2);

  // Build the thunk arguments by converting the callee arguments as needed
  // (the `PerformCppThunkCall` rule).
  llvm::SmallVector<SemIR::InstId> thunk_arg_ids;
  thunk_arg_ids.reserve(thunk_function_params.size());
  for (auto [callee_param_inst_id, thunk_param_inst_id, callee_arg_id] :
       llvm::zip(
           callee_function_params,
           thunk_function_params.take_front(callee_function_params.size()),
           callee_arg_ids)) {
    SemIR::TypeId callee_param_type_id =
        context.insts().GetAs<SemIR::AnyParam>(callee_param_inst_id).type_id;
    SemIR::TypeId thunk_param_type_id =
        context.insts().GetAs<SemIR::AnyParam>(thunk_param_inst_id).type_id;

    SemIR::InstId arg_id = callee_arg_id;
    if (callee_param_type_id != thunk_param_type_id) {
      arg_id = Convert(context, loc_id, arg_id,
                       {.kind = ConversionTarget::CppThunkRef,
                        .type_id = callee_param_type_id});
      arg_id = AddInst<SemIR::AddrOf>(
          context, loc_id,
          {.type_id = GetPointerType(
               context, context.types().GetTypeInstId(callee_param_type_id)),
           .lvalue_id = arg_id});
      arg_id =
          ConvertToValueOfType(context, loc_id, arg_id, thunk_param_type_id);
    }
    thunk_arg_ids.push_back(arg_id);
  }

  // The return out-pointer: the caller's return slot when there is one, else
  // one temporary of type `S` (the by-copy case, where no slot exists).
  if (!is_void) {
    if (!return_slot_id.has_value()) {
      return_slot_id = AddInst<SemIR::TemporaryStorage>(
          context, loc_id, {.type_id = success_type_id});
    }
    auto ret_param_type_id =
        context.insts()
            .GetAs<SemIR::AnyParam>(
                thunk_function_params[callee_function_params.size()])
            .type_id;
    auto ret_addr_id = AddInst<SemIR::AddrOf>(
        context, loc_id,
        {.type_id = GetPointerType(
             context, context.types().GetTypeInstId(
                          context.insts().Get(return_slot_id).type_id())),
         .lvalue_id = return_slot_id});
    thunk_arg_ids.push_back(
        ConvertToValueOfType(context, loc_id, ret_addr_id, ret_param_type_id));
  }

  // The error out-pointer: `err: Core.CppCompat.VoidBase*`, the primary
  // exception object pointer the thunk captures.
  auto err_param_type_id =
      context.insts()
          .GetAs<SemIR::AnyParam>(thunk_function_params.back())
          .type_id;
  auto err_pointee_type_id = context.types().GetTypeIdForTypeInstId(
      context.types().GetAs<SemIR::PointerType>(err_param_type_id).pointee_id);
  auto err_storage_id = AddInst<SemIR::TemporaryStorage>(
      context, loc_id, {.type_id = err_pointee_type_id});
  thunk_arg_ids.push_back(AddInst<SemIR::AddrOf>(
      context, loc_id,
      {.type_id = err_param_type_id, .lvalue_id = err_storage_id}));

  // The call itself.
  auto disc_id = AddInst<SemIR::Call>(
      context, loc_id,
      {.type_id = disc_type_id,
       .callee_id = thunk_decl_id,
       .args_id = context.inst_blocks().Add(thunk_arg_ids)});

  // `disc == 0` (the `EmitChoiceDiscriminantTest` idiom), then branch: the Ok
  // block is the taken edge, the Err block the fall-through.
  auto zero_id = ConvertToValueOfType(
      context, node_id, MakeIntLiteral(context, node_id, context.ints().Add(0)),
      disc_type_id);
  SemIR::InstId eq_args[] = {context.types().GetTypeInstId(disc_type_id)};
  auto eq_id = BuildBinaryOperator(context, node_id,
                                   {.interface_name = CoreIdentifier::EqWith,
                                    .interface_args_ref = eq_args,
                                    .op_name = CoreIdentifier::Equal},
                                   disc_id, zero_id);
  auto cond_id = ConvertToBoolValue(context, node_id, eq_id);

  // ONE shared storage for the `Result`, minted before the branch so it
  // dominates both initializers (fork/eh/plan.md §1.B.3). Each block
  // initializes it in place through `InitializeExisting` — the `var x: T =
  // init;` retargeting path (pattern_match.cpp; convert.cpp's
  // `OverwriteTemporaryStorageArg` makes the alternative constructor's call
  // write this storage instead of its own temporary) — consumed by an `Assign`
  // exactly as that path does (lowering of an `Assign` from an in-place
  // initializer is a no-op). A `Temporary` is NOT used: it consumes exactly one
  // initializer, and here there are two, one per block. The result is read
  // from the storage after the convergence, as `ret` is read from the return
  // slot below. A block-argument convergence of two `Result` VALUES does not
  // lower: a value of a type with a pointer value representation is a `ptr`,
  // while `GetBlockArg` types the `phi` by the object type.
  auto result_storage_id = AddInst<SemIR::TemporaryStorage>(
      context, loc_id, {.type_id = result_type.type_id});
  auto initialize_result = [&](SemIR::InstId init_id) -> bool {
    if (init_id == SemIR::ErrorInst::InstId) {
      return false;
    }
    init_id = InitializeExisting(context, loc_id, result_storage_id, init_id);
    if (init_id == SemIR::ErrorInst::InstId) {
      return false;
    }
    AddInst<SemIR::Assign>(context, loc_id,
                           {.lhs_id = result_storage_id, .rhs_id = init_id});
    return true;
  };

  auto ok_block_id = AddDominatedBlockAndBranchIf(context, node_id, cond_id);
  auto err_block_id = AddDominatedBlockAndBranch(context, node_id);

  auto ok_name_id =
      SemIR::NameId::ForIdentifier(context.identifiers().Add("Ok"));
  auto err_name_id =
      SemIR::NameId::ForIdentifier(context.identifiers().Add("Err"));

  // Ok block: `Core.Result(S, Cpp.Exception).Ok(<ret>)` into the storage.
  context.inst_block_stack().Pop();
  context.inst_block_stack().Push(ok_block_id);
  context.region_stack().AddToRegion(ok_block_id, node_id);
  SemIR::InstId ok_arg_id =
      is_void ? GetOrAddInst<SemIR::TupleValue>(
                    context, loc_id,
                    {.type_id = success_type_id,
                     .elements_id = SemIR::InstBlockId::Empty})
              : ConvertToValueExpr(context, return_slot_id);
  auto ok_ctor_id =
      PerformMemberAccess(context, loc_id, result_type.inst_id, ok_name_id);
  bool ok_initialized = initialize_result(PerformCall(
      context, loc_id, ok_ctor_id, {ok_arg_id}, /*is_desugared=*/true));

  // Err block: `Core.Result(S, Cpp.Exception).Err(err as Cpp.Exception)` into
  // the storage. The `as` is the prelude adapter's conversion from `VoidBase*`.
  context.inst_block_stack().Push(err_block_id);
  context.region_stack().AddToRegion(err_block_id, node_id);
  auto exception_value_id = ConvertForExplicitAs(
      context, node_id, ConvertToValueExpr(context, err_storage_id),
      exception_type.type_id, /*unsafe=*/false);
  auto err_ctor_id =
      PerformMemberAccess(context, loc_id, result_type.inst_id, err_name_id);
  bool err_initialized = initialize_result(
      PerformCall(context, loc_id, err_ctor_id, {exception_value_id},
                  /*is_desugared=*/true));

  // Converge (the Err block is on top), then the initialized storage is the
  // call's value.
  AddConvergenceBlockAndPush(context, node_id, 2);
  if (!ok_initialized || !err_initialized) {
    return SemIR::ErrorInst::InstId;
  }
  auto result_id = ConvertToValueExpr(context, result_storage_id);
  context.cpp_catching_call_results().Insert(result_id, callee_function_id);
  return result_id;
}

auto PerformCppThunkCall(Context& context, SemIR::LocId loc_id,
                         SemIR::FunctionId callee_function_id,
                         llvm::ArrayRef<SemIR::InstId> callee_arg_ids,
                         SemIR::InstId thunk_callee_id) -> SemIR::InstId {
  // Catching selection (docs/design/error_handling.md, "Catching imports";
  // fork/eh/plan.md D-EH-4): `?` applied directly to a call of a
  // fence-required callee whose mapped return type does not itself implement
  // `Core.Try` selects the CATCHING thunk, and the call has type
  // `Core.Result(S, Cpp.Exception)`. A `noexcept` callee, or `none` mode,
  // never reaches this branch, so `?` then diagnoses the usual non-`Try`
  // operand error.
  if (IsCatchingCallSite(context, loc_id)) {
    const auto& callee_function = context.functions().Get(callee_function_id);
    if (IsCppThunkFenceRequired(context,
                                GetCalleeClangDecl(context, callee_function)) &&
        !ImplementsCoreTry(context, loc_id,
                           GetCalleeResultType(context, callee_function))) {
      auto result_id = PerformCppCatchingThunkCall(
          context, loc_id, callee_function_id, callee_arg_ids);
      if (result_id.has_value()) {
        return result_id;
      }
      // The catching thunk could not be built (diagnosed): fall back to the
      // fenced thunk below.
    }
  }

  auto& callee_function = context.functions().Get(callee_function_id);
  auto callee_function_params =
      context.inst_blocks().Get(callee_function.call_params_id);
  auto num_callee_return_params =
      callee_function.call_param_ranges.return_size();

  auto thunk_callee = GetCalleeAsFunction(context.sem_ir(), thunk_callee_id);
  auto& thunk_function = context.functions().Get(thunk_callee.function_id);
  auto thunk_function_params =
      context.inst_blocks().Get(thunk_function.call_params_id);
  auto num_thunk_return_params = thunk_function.call_param_ranges.return_size();

  CARBON_CHECK(
      num_callee_return_params <= 1 && num_thunk_return_params <= 1,
      "TODO: generalize this logic to support multiple return patterns.");

  // Whether we need to pass a return address to the thunk as a final argument.
  bool thunk_takes_return_address =
      num_callee_return_params > 0 && num_thunk_return_params == 0;

  // The number of arguments we should be acquiring in order to call the thunk.
  // This includes the return address parameters, if any.
  unsigned num_thunk_args =
      context.inst_blocks().Get(thunk_function.param_patterns_id).size();

  // The corresponding number of arguments that would be provided in a syntactic
  // call to the callee. This excludes the return slot.
  unsigned num_callee_args = num_thunk_args - thunk_takes_return_address;

  // Grab the return slot argument, if we were given one.
  auto return_slot_id = SemIR::InstId::None;
  if (callee_arg_ids.size() == num_callee_args + 1) {
    return_slot_id = callee_arg_ids.consume_back();
  }

  // If there are return slot patterns, drop the corresponding parameters.
  // TODO: The parameter should probably only be created if the return pattern
  // actually needs a return address to be passed in.
  thunk_function_params =
      thunk_function_params.drop_back(num_thunk_return_params);
  callee_function_params =
      callee_function_params.drop_back(num_callee_return_params);

  // We assume that the call parameters exactly match the parameter patterns for
  // both the thunk and the callee. This is guaranteed even when we generate a
  // tuple pattern wrapping the function parameters.
  CARBON_CHECK(num_callee_args == callee_function_params.size(), "{0} != {1}",
               num_callee_args, callee_function_params.size());
  CARBON_CHECK(num_callee_args == callee_arg_ids.size());
  CARBON_CHECK(num_thunk_args == thunk_function_params.size());

  // Build the thunk arguments by converting the callee arguments as needed.
  llvm::SmallVector<SemIR::InstId> thunk_arg_ids;
  thunk_arg_ids.reserve(num_thunk_args);
  for (auto [callee_param_inst_id, thunk_param_inst_id, callee_arg_id] :
       llvm::zip(callee_function_params, thunk_function_params,
                 callee_arg_ids)) {
    SemIR::TypeId callee_param_type_id =
        context.insts().GetAs<SemIR::AnyParam>(callee_param_inst_id).type_id;
    SemIR::TypeId thunk_param_type_id =
        context.insts().GetAs<SemIR::AnyParam>(thunk_param_inst_id).type_id;

    SemIR::InstId arg_id = callee_arg_id;
    if (callee_param_type_id != thunk_param_type_id) {
      arg_id = Convert(context, loc_id, arg_id,
                       {.kind = ConversionTarget::CppThunkRef,
                        .type_id = callee_param_type_id});
      arg_id = AddInst<SemIR::AddrOf>(
          context, loc_id,
          {.type_id = GetPointerType(
               context, context.types().GetTypeInstId(callee_param_type_id)),
           .lvalue_id = arg_id});
      arg_id =
          ConvertToValueOfType(context, loc_id, arg_id, thunk_param_type_id);
    }
    thunk_arg_ids.push_back(arg_id);
  }

  // Add an argument to hold the result of the call, if necessary.
  auto return_type_id = callee_function.GetDeclaredReturnType(context.sem_ir());
  if (thunk_takes_return_address) {
    // Create a temporary if the caller didn't provide a return slot.
    if (!return_slot_id.has_value()) {
      return_slot_id = AddInst<SemIR::TemporaryStorage>(
          context, loc_id, {.type_id = return_type_id});
    }

    auto arg_id = AddInst<SemIR::AddrOf>(
        context, loc_id,
        {.type_id = GetPointerType(
             context, context.types().GetTypeInstId(
                          context.insts().Get(return_slot_id).type_id())),
         .lvalue_id = return_slot_id});
    thunk_arg_ids.push_back(arg_id);
  } else if (return_slot_id.has_value()) {
    thunk_arg_ids.push_back(return_slot_id);
  }

  // Compute the return type of the call to the thunk.
  auto thunk_return_type_id =
      thunk_function.GetDeclaredReturnType(context.sem_ir());
  if (!thunk_return_type_id.has_value()) {
    CARBON_CHECK(thunk_takes_return_address || !return_type_id.has_value());
    thunk_return_type_id = GetTupleType(context, {});
  } else {
    CARBON_CHECK(thunk_return_type_id == return_type_id);
  }

  auto result_id = GetOrAddInst<SemIR::Call>(
      context, loc_id,
      {.type_id = thunk_return_type_id,
       .callee_id = thunk_callee_id,
       .args_id = context.inst_blocks().Add(thunk_arg_ids)});

  // Produce the result of the call, taking the value from the return storage.
  if (thunk_takes_return_address) {
    result_id = AddInst<SemIR::MarkInPlaceInit>(context, loc_id,
                                                {.type_id = return_type_id,
                                                 .src_id = result_id,
                                                 .dest_id = return_slot_id});
  }

  return result_id;
}

}  // namespace Carbon::Check
