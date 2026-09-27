// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/cpp/thunk.h"

#include "clang/AST/ASTConsumer.h"
#include "clang/AST/DeclCXX.h"
#include "clang/AST/GlobalDecl.h"
#include "clang/AST/Mangle.h"
#include "clang/AST/Stmt.h"
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
    const clang::FunctionDecl& callee_function_decl,
    const SemIR::ClangDeclSignature& signature, bool is_catching = false)
    -> std::string {
  RawStringOstream mangled_name_stream;
  mangle_context.mangleName(GetGlobalDecl(&callee_function_decl),
                            mangled_name_stream);
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

  if (IsObjectMemberFunction(callee_function_decl)) {
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

namespace {
// Information about the callee of a thunk.
struct CalleeFunctionInfo {
  explicit CalleeFunctionInfo(clang::FunctionDecl* decl,
                              const SemIR::ClangDeclSignature* signature)
      : decl(decl),
        signature(signature),
        num_params(signature->num_params +
                   decl->hasCXXExplicitFunctionObjectParameter()) {
    for (int i : llvm::seq(num_params)) {
      num_constant_params += signature->GetConstantFunctionArg(i) != nullptr;
    }
    auto& ast_context = decl->getASTContext();
    const auto* method_decl = dyn_cast<clang::CXXMethodDecl>(decl);
    bool is_ctor = isa<clang::CXXConstructorDecl>(decl);
    has_object_parameter = IsObjectMemberFunction(*decl);
    if (has_object_parameter && method_decl->isImplicitObjectMemberFunction()) {
      implicit_object_parameter_type =
          method_decl->getFunctionObjectParameterReferenceType();
    }
    effective_return_type =
        is_ctor ? ast_context.getCanonicalTagType(method_decl->getParent())
                : decl->getReturnType();
    has_simple_return_type = IsSimpleAbiType(ast_context, effective_return_type,
                                             /*for_parameter=*/false);
  }

  // Returns whether this callee has an implicit `this` parameter.
  auto has_implicit_object_parameter() const -> bool {
    return !implicit_object_parameter_type.isNull();
  }

  // Returns whether this callee has an explicit `this` parameter.
  auto has_explicit_object_parameter() const -> bool {
    return has_object_parameter && !has_implicit_object_parameter();
  }

  // Returns whether the given callee parameter is satisfied by a constant
  // function argument embedded into the thunk body rather than by a runtime
  // thunk parameter.
  auto is_constant_param(unsigned callee_param_index) const -> bool {
    return signature->GetConstantFunctionArg(callee_param_index) != nullptr;
  }

  // Returns the number of parameters the thunk should have. Constant function
  // arguments are embedded into the thunk body, not passed at runtime.
  auto num_thunk_params() const -> unsigned {
    return has_implicit_object_parameter() + num_params - num_constant_params +
           !has_simple_return_type;
  }

  // Returns the thunk parameter index corresponding to a given callee parameter
  // index.
  auto GetThunkParamIndex(unsigned callee_param_index) const -> unsigned {
    CARBON_CHECK(!is_constant_param(callee_param_index));
    unsigned num_constant_before = 0;
    for (unsigned i : llvm::seq(callee_param_index)) {
      num_constant_before += is_constant_param(i);
    }
    return has_implicit_object_parameter() + callee_param_index -
           num_constant_before;
  }

  // Returns the thunk parameter index corresponding to the parameter that holds
  // the address of the return value.
  auto GetThunkReturnParamIndex() const -> unsigned {
    CARBON_CHECK(!has_simple_return_type);
    return has_implicit_object_parameter() + num_params - num_constant_params;
  }

  // The callee function.
  clang::FunctionDecl* decl;

  // The signature of the function being imported.
  const SemIR::ClangDeclSignature* signature;

  // The number of explicit parameters to import. This may be less than the
  // number of parameters that the function has if default arguments are being
  // used.
  int num_params;

  // The number of parameters that are satisfied by constant function
  // arguments embedded into the thunk body (see
  // `ClangDeclSignature::constant_function_args`).
  int num_constant_params = 0;

  // Whether the callee has an object parameter, which might be explicit or
  // implicit.
  bool has_object_parameter;

  // If the callee has an implicit object parameter, the type of that parameter,
  // which will always be a reference type. Otherwise a null type.
  clang::QualType implicit_object_parameter_type;

  // The return type that the callee has when viewed from Carbon. This is the
  // C++ return type, except that constructors return the class type in Carbon
  // and return void in Clang's AST.
  clang::QualType effective_return_type;

  // Whether the callee has a simple return type, that we can return directly.
  // If not, we'll return through an out parameter instead.
  bool has_simple_return_type;
};
}  // namespace

auto IsCppThunkFenceRequired(Context& context, const clang::FunctionDecl* decl)
    -> bool {
  if (!context.ast_context().getLangOpts().CXXExceptions) {
    return false;
  }
  const auto* proto = decl->getType()->castAs<clang::FunctionProtoType>();
  // Implicit and defaulted special members and unannotated destructors carry
  // an unevaluated exception specification, which `canThrow` rejects; resolve
  // it first, mirroring `Sema::MarkFunctionReferenced`.
  if (clang::isUnresolvedExceptionSpec(proto->getExceptionSpecType())) {
    proto =
        context.clang_sema().ResolveExceptionSpec(decl->getLocation(), proto);
  }
  // A callee whose specification cannot be resolved is conservatively treated
  // as potentially-throwing.
  return !proto ||
         clang::isUnresolvedExceptionSpec(proto->getExceptionSpecType()) ||
         proto->canThrow() != clang::CT_Cannot;
}

auto IsCppThunkRequired(Context& context, const SemIR::Function& function)
    -> bool {
  const auto* clang_decl =
      context.clang_decls().Lookup(function.first_decl_id());
  if (!clang_decl) {
    return false;
  }

  if (!clang_decl->is_imported) {
    return false;
  }

  const auto& signature =
      context.clang_decl_signatures().Get(clang_decl->key.signature_id);
  auto* decl = cast<clang::FunctionDecl>(clang_decl->decl());

  // With C++ exceptions enabled, every potentially-throwing callee crosses
  // the boundary through a fenced thunk
  // (docs/design/error_handling.md#the-fenced-boundary-terminate-semantics).
  if (IsCppThunkFenceRequired(context, decl)) {
    return true;
  }

  // A constant function argument must be embedded into a thunk body; the
  // callee can't be called directly without it.
  if (signature.HasConstantFunctionArgs()) {
    return true;
  }

  if (signature.kind != SemIR::ClangDeclSignature::Normal ||
      signature.num_params != static_cast<int>(decl->getNumNonObjectParams())) {
    // We require a thunk if the number of parameters we want isn't all of them.
    // This happens if default arguments are in use, or (eventually) when
    // calling a varargs function.
    return true;
  }

  CalleeFunctionInfo callee_info(decl, &signature);
  if (!callee_info.has_simple_return_type) {
    return true;
  }

  auto& ast_context = context.ast_context();
  if (callee_info.has_implicit_object_parameter() &&
      (!IsSimpleAbiType(ast_context, callee_info.implicit_object_parameter_type,
                        /*for_parameter=*/true) ||
       signature.self_passing_mode ==
           SemIR::ClangDeclSignature::PassingMode::ByVar)) {
    return true;
  }

  const auto* function_type =
      decl->getType()->castAs<clang::FunctionProtoType>();
  for (int i : llvm::seq(decl->getNumParams())) {
    if (!IsSimpleAbiType(ast_context, function_type->getParamType(i),
                         /*for_parameter=*/true) ||
        signature.GetPassingMode(i) ==
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
  if (callee_info.has_implicit_object_parameter()) {
    thunk_param_types.push_back(callee_info.implicit_object_parameter_type);
  }

  const auto* function_type =
      callee_info.decl->getType()->castAs<clang::FunctionProtoType>();
  for (int i : llvm::seq(callee_info.num_params)) {
    // Constant function arguments are embedded into the thunk body, not
    // passed at runtime.
    if (callee_info.is_constant_param(i)) {
      continue;
    }
    thunk_param_types.push_back(
        GetThunkParameterType(ast_context, function_type->getParamType(i)));
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

  if (callee_info.has_implicit_object_parameter()) {
    clang::ParmVarDecl* thunk_param =
        clang::ParmVarDecl::Create(ast_context, thunk_function_decl, clang_loc,
                                   clang_loc, &ast_context.Idents.get("this"),
                                   thunk_function_proto_type->getParamType(0),
                                   nullptr, clang::SC_None, nullptr);
    thunk_params.push_back(thunk_param);
  }

  for (int i : llvm::seq(callee_info.num_params)) {
    if (callee_info.is_constant_param(i)) {
      continue;
    }
    clang::ParmVarDecl* thunk_param = clang::ParmVarDecl::Create(
        ast_context, thunk_function_decl, clang_loc, clang_loc,
        callee_info.decl->getParamDecl(i)->getIdentifier(),
        thunk_function_proto_type->getParamType(
            callee_info.GetThunkParamIndex(i)),
        nullptr, clang::SC_None, nullptr);
    thunk_params.push_back(thunk_param);
  }

  if (!callee_info.has_simple_return_type) {
    clang::ParmVarDecl* thunk_param =
        clang::ParmVarDecl::Create(ast_context, thunk_function_decl, clang_loc,
                                   clang_loc, &ast_context.Idents.get("return"),
                                   thunk_function_proto_type->getParamType(
                                       callee_info.GetThunkReturnParamIndex()),
                                   nullptr, clang::SC_None, nullptr);
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
  clang::DeclarationName name = GetDeclNameForThunk(
      ast_context, callee_info.decl->getDeclName(), is_catching);

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
                               *callee_info.decl, *callee_info.signature,
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
  unsigned thunk_index = callee_info.GetThunkParamIndex(callee_index);
  return BuildThunkParamRef(
      sema, thunk_function_decl, thunk_index,
      callee_info.signature->GetPassingMode(callee_index),
      callee_info.decl->getParamDecl(callee_index)->getType());
}

// Builds an argument list for the callee function by creating suitable uses of
// the corresponding thunk parameters.
static auto BuildCalleeArgs(clang::Sema& sema,
                            clang::FunctionDecl* thunk_function_decl,
                            CalleeFunctionInfo callee_info)
    -> llvm::SmallVector<clang::Expr*> {
  llvm::SmallVector<clang::Expr*> call_args;
  // The object parameter is always passed as `self`, not in the callee argument
  // list, so the first argument corresponds to the second parameter if there is
  // an explicit object parameter and the first parameter otherwise.
  int first_param = callee_info.has_explicit_object_parameter();
  call_args.reserve(callee_info.num_params - first_param);
  for (unsigned callee_index : llvm::seq(first_param, callee_info.num_params)) {
    if (auto* constant_decl =
            callee_info.signature->GetConstantFunctionArg(callee_index)) {
      // A constant function argument: reference the embedded declaration
      // directly instead of a thunk parameter. Sema decays the reference to
      // the callee parameter's function pointer type.
      call_args.push_back(sema.BuildDeclRefExpr(
          constant_decl, constant_decl->getType(), clang::VK_LValue,
          thunk_function_decl->getLocation()));
      continue;
    }
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
  if (callee_info.has_object_parameter) {
    clang::QualType object_param_type =
        cast<clang::CXXMethodDecl>(callee_info.decl)
            ->getFunctionObjectParameterReferenceType();
    auto* object_param_ref = BuildThunkParamRef(
        sema, thunk_function_decl, 0, callee_info.signature->self_passing_mode,
        object_param_type);
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
        clang::DeclarationNameInfo(callee_info.decl->getDeclName(), clang_loc),
        sema.getASTContext().BoundMemberTy, clang::VK_PRValue,
        clang::OK_Ordinary);
  } else if (!isa<clang::CXXConstructorDecl>(callee_info.decl)) {
    callee =
        sema.BuildDeclRefExpr(callee_info.decl, callee_info.decl->getType(),
                              clang::VK_PRValue, clang_loc);
  }

  if (callee.isInvalid()) {
    return clang::ExprError();
  }

  // Build the argument list.
  llvm::SmallVector<clang::Expr*> call_args =
      BuildCalleeArgs(sema, thunk_function_decl, callee_info);

  clang::ExprResult call;
  if (auto info = clang::getConstructorInfo(callee_info.decl);
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
  auto* return_object_addr = BuildThunkParamRef(
      sema, thunk_function_decl, callee_info.GetThunkReturnParamIndex(),
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

// Builds the thunk function body which calls the callee function using the call
// args and returns the callee function return value. Returns nullptr on
// failure.
static auto BuildThunkBody(CppContext& cpp_context, clang::Sema& sema,
                           clang::SourceLocation clang_loc,
                           clang::FunctionDecl* thunk_function_decl,
                           CalleeFunctionInfo callee_info)
    -> clang::StmtResult {
  // TODO: Consider building a CompoundStmt holding our created statement to
  // make our result more closely resemble a real C++ function.
  clang::ExprResult call =
      BuildCalleeCallExpr(sema, clang_loc, thunk_function_decl, callee_info);
  if (!call.isUsable()) {
    return clang::StmtError();
  }

  if (callee_info.has_simple_return_type) {
    return sema.BuildReturnStmt(clang_loc, call.get());
  }

  return BuildReturnValueStore(cpp_context, sema, clang_loc,
                               thunk_function_decl, callee_info, call.get());
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

auto BuildCppThunk(Context& context, const SemIR::Function& callee_function)
    -> clang::FunctionDecl* {
  auto clang_decl_key =
      context.clang_decls().Lookup(callee_function.first_decl_id())->key;
  clang::FunctionDecl* callee_function_decl =
      clang_decl_key.decl->getAsFunction();
  CARBON_CHECK(callee_function_decl);

  // TODO: The signature kind doesn't affect the thunk that we build, so we
  // shouldn't consider it here. However, to do that, we would need to cache the
  // thunks we build so that we don't build the same thunk multiple times if
  // it's used with multiple different signature kinds.
  const auto& signature =
      context.clang_decl_signatures().Get(clang_decl_key.signature_id);
  CalleeFunctionInfo callee_info(callee_function_decl, &signature);

  clang::SourceLocation clang_loc = callee_function_decl->getLocation();
  CARBON_CHECK(clang_loc.isValid(), "Missing location for function");

  // Build the thunk function declaration.
  auto thunk_param_types =
      BuildThunkParameterTypes(context.ast_context(), callee_info);
  clang::FunctionDecl* thunk_function_decl = CreateThunkFunctionDecl(
      context, callee_info, clang_loc, thunk_param_types);

  // Build the thunk function body.
  clang::Sema& sema = context.clang_sema();
  clang::Sema::ContextRAII context_raii(sema, thunk_function_decl);
  sema.ActOnStartOfFunctionDef(nullptr, thunk_function_decl);
  clang::StmtResult body =
      BuildThunkBody(*context.cpp_context(), sema, clang_loc,
                     thunk_function_decl, callee_info);
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

  const auto& signature =
      context.clang_decl_signatures().Get(clang_decl_key.signature_id);
  CalleeFunctionInfo callee_info(callee_function_decl, &signature);

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

  Diagnostics::AnnotationScope annotate_diagnostics(
      &context.emitter(), [&](auto& builder) {
        CARBON_DIAGNOSTIC(InCppCatchingThunk, Note,
                          "in catching thunk for C++ function used here");
        builder.Note(loc_id, InCppCatchingThunk);
      });

  auto& callee_function = context.functions().Get(callee_function_id);
  SemIR::InstId thunk_decl_id = SemIR::InstId::None;
  if (clang::FunctionDecl* thunk_clang_decl =
          BuildCppCatchingThunk(context, callee_function)) {
    // Import the thunk exactly as the fenced thunk is imported (import.cpp,
    // `ImportFunctionDecl`): an all-by-value signature over its own
    // parameters.
    SemIR::ClangDeclSignature thunk_signature;
    thunk_signature.kind = SemIR::ClangDeclSignature::Normal;
    thunk_signature.num_params =
        static_cast<int32_t>(thunk_clang_decl->getNumParams());
    thunk_signature.passing_modes.assign(
        thunk_signature.num_params,
        SemIR::ClangDeclSignature::PassingMode::ByValue);
    SemIR::ClangDeclSignatureId thunk_signature_id =
        context.clang_decl_signatures().Add(std::move(thunk_signature));

    auto imported_decl_id = ImportCppFunctionDecl(
        context, loc_id, thunk_clang_decl, thunk_signature_id);
    if (imported_decl_id != SemIR::ErrorInst::InstId &&
        imported_decl_id.has_value()) {
      auto& thunk_function = context.functions().Get(
          GetCalleeAsFunction(context.sem_ir(), imported_decl_id).function_id);
      thunk_function.SetCppThunk(
          context.functions().Get(callee_function_id).first_owning_decl_id);
      thunk_decl_id = imported_decl_id;
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
  if (loc_id.kind() != SemIR::LocId::Kind::NodeId) {
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

  // Form `Core.Result(S, Cpp.Exception)` the way `MakeOptionalType` forms
  // `Core.Optional(T)`, and force its completion here, under the catching
  // context: a non-scalar `S` (a class, `std::string`, a constructor's class)
  // fails the SF-6 payload bound at the specific's resolution
  // (`ChoicePayloadNotTrivialInSpecific`, eval_inst.cpp), and this context
  // names the C++ callee.
  std::string callee_name =
      GetCalleeClangDecl(context, callee_function)->getQualifiedNameAsString();
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
  if (!RequireCompleteType(
          context, result_type.type_id, loc_id, [&](auto& builder) {
            CARBON_DIAGNOSTIC(CppCatchingImportPayloadNote, Context,
                              "catching import of `{0}` requires a scalar "
                              "success type in 0.1; {1} is not one",
                              std::string, SemIR::TypeId);
            builder.Context(loc_id, CppCatchingImportPayloadNote, callee_name,
                            success_type_id);
          })) {
    return SemIR::ErrorInst::InstId;
  }

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
  auto ok_block_id = AddDominatedBlockAndBranchIf(context, node_id, cond_id);
  auto err_block_id = AddDominatedBlockAndBranch(context, node_id);

  auto ok_name_id =
      SemIR::NameId::ForIdentifier(context.identifiers().Add("Ok"));
  auto err_name_id =
      SemIR::NameId::ForIdentifier(context.identifiers().Add("Err"));

  // Ok block: `Core.Result(S, Cpp.Exception).Ok(<ret>)`, as a value.
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
  auto ok_value_id =
      ConvertToValueOfType(context, loc_id,
                           PerformCall(context, loc_id, ok_ctor_id, {ok_arg_id},
                                       /*is_desugared=*/true),
                           result_type.type_id);

  // Err block: `Core.Result(S, Cpp.Exception).Err(err as Cpp.Exception)`, as a
  // value. The `as` is the prelude adapter's conversion from `VoidBase*`.
  context.inst_block_stack().Push(err_block_id);
  context.region_stack().AddToRegion(err_block_id, node_id);
  auto exception_value_id = ConvertForExplicitAs(
      context, node_id, ConvertToValueExpr(context, err_storage_id),
      exception_type.type_id, /*unsafe=*/false);
  auto err_ctor_id =
      PerformMemberAccess(context, loc_id, result_type.inst_id, err_name_id);
  auto err_value_id = ConvertToValueOfType(
      context, loc_id,
      PerformCall(context, loc_id, err_ctor_id, {exception_value_id},
                  /*is_desugared=*/true),
      result_type.type_id);

  // Converge: the `if`-expression shape, with the Err block on top.
  if (ok_value_id == SemIR::ErrorInst::InstId ||
      err_value_id == SemIR::ErrorInst::InstId) {
    AddConvergenceBlockAndPush(context, node_id, 2);
    return SemIR::ErrorInst::InstId;
  }
  auto result_id = AddConvergenceBlockWithArgAndPush(
      context, node_id, {err_value_id, ok_value_id});
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
