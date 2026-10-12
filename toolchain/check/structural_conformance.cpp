// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include "toolchain/check/structural_conformance.h"

#include <optional>
#include <variant>

#include "clang/AST/Decl.h"
#include "clang/AST/DeclCXX.h"
#include "clang/Basic/Specifiers.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/Sequence.h"
#include "llvm/ADT/SmallVector.h"
#include "toolchain/check/context.h"
#include "toolchain/check/cpp/import.h"
#include "toolchain/check/diagnostic_helpers.h"
#include "toolchain/check/function.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/impl_lookup.h"
#include "toolchain/check/import_ref.h"
#include "toolchain/check/interface.h"
#include "toolchain/check/member_access.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/diagnostics/format_providers.h"
#include "toolchain/sem_ir/clang_decl.h"
#include "toolchain/sem_ir/constant.h"
#include "toolchain/sem_ir/cpp_overload_set.h"
#include "toolchain/sem_ir/function.h"
#include "toolchain/sem_ir/identified_facet_type.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/name_scope.h"
#include "toolchain/sem_ir/named_constraint.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

namespace {

// How one run of the check reports. Check mode has `explain == nullptr` and
// emits only completeness errors, and only when `diagnose`. Explain mode
// (D-SC-9) has `diagnose == false` and attaches notes for the first
// unsatisfied requirement to `*explain`. Both modes are one function so they
// cannot drift.
struct ReportMode {
  bool diagnose;
  DiagnosticBuilder* explain;
};

// Why a member of the self type does not satisfy a requirement.
enum class MemberFailure : uint8_t {
  // No member of the requirement's name.
  Missing,
  // The member is not a single function, or its signature differs.
  Mismatch,
  // The member is private or protected from here.
  Inaccessible,
};

// An unsatisfied requirement `fn`, for explain mode.
struct MemberFailureInfo {
  MemberFailure failure;
  // The declared access of the found member (`Inaccessible`).
  SemIR::AccessKind access_kind = SemIR::AccessKind::Public;
  // The location of the found member's declaration, if it resolved to a
  // function (`Mismatch`); `None` otherwise.
  SemIR::InstId member_decl_id = SemIR::InstId::None;
};

}  // namespace

// D-SC-19: a template-phase self reaches the check only through the `require`
// entry point (`CheckRequireDeclsSatisfied`), where it is deferred.
static auto SelfIsTemplatePhase(Context& context, SemIR::ConstantId self)
    -> bool {
  return context.constant_values().GetDependence(self) ==
         SemIR::ConstantDependence::Template;
}

// D-SC-6: a checked-symbolic self satisfies a structural requirement only if
// its own facet type already lists that same requirement. This is a cascade
// guard: D-SC-8(i) rejects such bindings, and the only input reaching here is
// the error-recovery path after that diagnostic.
static auto SelfFacetCarriesRequirement(
    Context& context, SemIR::LocId loc_id, SemIR::ConstantId self,
    const SemIR::IdentifiedFacetType::StructuralRequirement& requirement)
    -> bool {
  auto self_inst_id = context.constant_values().GetInstId(self);
  auto self_type_id = context.insts().Get(self_inst_id).type_id();
  if (!context.types().IsConstrainedFacetType(self_type_id)) {
    return false;
  }
  auto identified_id = TryToIdentifyFacetType(
      context, loc_id, self, context.types().GetTypeInstId(self_type_id),
      /*allow_partially_identified=*/true);
  if (!identified_id.has_value()) {
    return false;
  }
  return llvm::is_contained(context.identified_facet_types()
                                .Get(identified_id)
                                .structural_requirements(),
                            requirement);
}

// D-SC-5(a): the self type must be complete. In check mode with `diagnose`
// this is an error with a context note; otherwise an incomplete type is
// silently unsatisfied (R-7).
static auto RequirementTargetIsComplete(
    Context& context, SemIR::LocId loc_id, SemIR::TypeId self_type_id,
    const SemIR::NamedConstraint& constraint, ReportMode mode)
    -> StructuralCheckResult {
  if (mode.diagnose) {
    if (!RequireCompleteType(context, self_type_id, loc_id, [&](auto& builder) {
          CARBON_DIAGNOSTIC(StructuralRequirementIncompleteType, Context,
                            "incomplete type {0} cannot satisfy template "
                            "constraint `{1}`",
                            SemIR::TypeId, SemIR::NameId);
          builder.Context(loc_id, StructuralRequirementIncompleteType,
                          self_type_id, constraint.name_id);
        })) {
      return StructuralCheckResult::Error;
    }
    return StructuralCheckResult::Satisfied;
  }
  return TryToCompleteType(context, self_type_id, loc_id)
             ? StructuralCheckResult::Satisfied
             : StructuralCheckResult::Unsatisfied;
}

// D-SC-5(b): finds the self type's own member named `name_id` through the
// member-access lookup path, without diagnostics and without an access check
// (the access decision is applied by the caller). Returns `None` if the type
// has no such member, and the member's `NameRef` otherwise. The lookup uses a
// desugared location so that the `NameRef` does not land in the caller's
// block (review fold A5(i)).
static auto FindStructuralMember(Context& context, SemIR::LocId loc_id,
                                 SemIR::TypeId self_type_id,
                                 SemIR::NameId name_id,
                                 MemberLookupInfo* out_info) -> SemIR::InstId {
  auto self_type_const_id = context.types().GetConstantId(self_type_id);
  llvm::SmallVector<LookupScope> lookup_scopes;
  if (!AppendLookupScopesForConstant(
          context, loc_id, self_type_const_id, self_type_const_id,
          /*extended_scope=*/false, &lookup_scopes)) {
    // Not a name scope: no members at all.
    return SemIR::InstId::None;
  }
  auto member_id = LookupMemberNameInTypeScopes(
      context, context.insts().GetLocIdForDesugaring(loc_id),
      context.types().GetTypeInstId(self_type_id), name_id, self_type_const_id,
      lookup_scopes, /*lookup_in_type_of_base=*/false, /*required=*/false,
      /*access_info=*/std::nullopt, /*diagnose=*/false, out_info);
  if (!out_info->found) {
    return SemIR::InstId::None;
  }
  return member_id;
}

// The Carbon passing mode of a C++ parameter read from its declared type alone
// (there is no call, so no conversion sequence): a reference to `const` is
// pass-by-value, a non-`const` lvalue reference is `ref`, a non-`const` rvalue
// reference is `var`, and anything else is by value -- the declaration-side
// reading of cpp/overload_resolution.cpp's
// `ComputePassingModeForReferenceBinding`.
static auto PassingModeForCppParameterType(clang::QualType type)
    -> SemIR::ClangDeclSignature::PassingMode {
  if (!type->isReferenceType()) {
    return SemIR::ClangDeclSignature::PassingMode::ByValue;
  }
  if (type.getNonReferenceType().isConstQualified()) {
    return SemIR::ClangDeclSignature::PassingMode::ByValue;
  }
  return type->isLValueReferenceType()
             ? SemIR::ClangDeclSignature::PassingMode::ByRef
             : SemIR::ClangDeclSignature::PassingMode::ByVar;
}

// D-SC-5(c), extended at SC-1c (commit-2 review finding 2): an imported C++
// method NAME resolves to a `cpp_overload_set_value`, never to a single
// function, so a C++ overload set whose `candidate_functions` holds exactly
// one member is looked through to that member, imported as a Carbon function
// with the signature its declaration alone determines, and matched under
// D-SC-5(d). A set with two or more candidates stays a mismatch. The `self`
// passing mode mirrors the call-site import: a non-`const` method's object
// parameter is `Self&` (so `ref self`, §0.1 row 19), a `const` method's is
// `const Self&` (so value `self`) -- D-SC-11's spelling rule, refined.
//
// The import is NOT `diagnose`-aware (R-7 residue, ledger W-144):
// `ImportCppFunctionDecl` emits unconditionally -- cpp/import.cpp's
// "Unsupported: Template function" and fenced-thunk TODOs, and the
// parameter/return type-mapping TODOs under `CreateFunctionSignatureInsts` --
// so a check-mode probe (`diagnose = false`) that reaches the import can emit.
// The import is deliberately not gated on `diagnose`: the overload-set shape
// the conformance programs use probes member 1 in check mode and MUST import
// for a C++ class to satisfy at all. Closing the leak means threading
// `diagnose` into `ImportCppDecl`, which touches check/cpp/ (untouched by
// SC-1); pinned by the `fail_todo_probe_import_leak` split of
// interop/cpp/class/import/template_constraint.carbon.
//
// Returns the imported `FunctionDecl` inst, or `None` with `*out_failure` set.
// Cheap shape checks (`self` presence, parameter count) run before the import
// so that a shape that cannot match imports nothing.
static auto ImportSingleCppOverloadCandidate(
    Context& context, SemIR::LocId loc_id,
    const SemIR::CalleeCppOverloadSet& overload,
    const SemIR::Function& requirement_fn, MemberFailureInfo* out_failure)
    -> SemIR::InstId {
  *out_failure = MemberFailureInfo{.failure = MemberFailure::Mismatch};
  const auto& overload_set =
      context.cpp_overload_sets().Get(overload.cpp_overload_set_id);
  if (overload_set.candidate_functions.size() != 1) {
    return SemIR::InstId::None;
  }
  clang::DeclAccessPair candidate = overload_set.candidate_functions[0];
  auto* clang_fn = clang::dyn_cast<clang::FunctionDecl>(
      candidate.getDecl()->getUnderlyingDecl());
  if (!clang_fn || clang_fn->isVariadic() || clang_fn->isDeleted()) {
    return SemIR::InstId::None;
  }

  // The access of the candidate as name lookup found it (D-SC-5(b)): Carbon
  // code is never inside a C++ class, so a non-public member never satisfies.
  switch (candidate.getAccess()) {
    case clang::AS_private:
      *out_failure =
          MemberFailureInfo{.failure = MemberFailure::Inaccessible,
                            .access_kind = SemIR::AccessKind::Private};
      return SemIR::InstId::None;
    case clang::AS_protected:
      *out_failure =
          MemberFailureInfo{.failure = MemberFailure::Inaccessible,
                            .access_kind = SemIR::AccessKind::Protected};
      return SemIR::InstId::None;
    case clang::AS_public:
    case clang::AS_none:
      break;
  }

  // Shape: a method requirement needs an object member function, an
  // associated-function requirement a static member or free function; the
  // explicit parameter counts must agree.
  bool requirement_has_self = requirement_fn.self_param_id.has_value();
  if (IsObjectMemberFunction(*clang_fn) != requirement_has_self) {
    return SemIR::InstId::None;
  }
  int explicit_object_params =
      clang_fn->hasCXXExplicitFunctionObjectParameter();
  int num_cpp_params =
      static_cast<int>(clang_fn->getNumParams()) - explicit_object_params;
  int num_requirement_params =
      static_cast<int>(context.inst_blocks()
                           .GetOrEmpty(requirement_fn.param_patterns_id)
                           .size()) -
      (requirement_has_self ? 1 : 0);
  if (num_cpp_params != num_requirement_params) {
    return SemIR::InstId::None;
  }

  SemIR::ClangDeclSignature signature;
  signature.kind = SemIR::ClangDeclSignature::Normal;
  signature.num_params = num_cpp_params;
  signature.passing_modes.reserve(num_cpp_params);
  for (int i : llvm::seq(num_cpp_params)) {
    signature.passing_modes.push_back(PassingModeForCppParameterType(
        clang_fn->getParamDecl(i + explicit_object_params)->getType()));
  }
  if (requirement_has_self) {
    signature.self_passing_mode = PassingModeForCppParameterType(
        clang::cast<clang::CXXMethodDecl>(clang_fn)
            ->getFunctionObjectParameterReferenceType());
  }
  auto signature_id = context.clang_decl_signatures().Add(std::move(signature));

  auto fn_decl_id =
      ImportCppFunctionDecl(context, loc_id, clang_fn, signature_id);
  if (fn_decl_id == SemIR::ErrorInst::InstId) {
    return SemIR::InstId::None;
  }
  return fn_decl_id;
}

// D-SC-5(d): the member's signature must match the requirement's with `Self`
// bound to the self: the thunk criterion (`CheckFunctionTypeMatches` with
// `check_syntax` false), so parameter names need not agree and no thunk is
// built. The requirement's specific is built exactly as for an interface
// member, with no enclosing specific. The member is read in its own enclosing
// specific (`member_specific_id`, from `GetCallee`): a member of a generic
// class specific such as `Box(i32).Get` declares `self: Box(T)`, and only the
// substituted `Box(i32)` can equal the requirement's `Self := Box(i32)`
// (commit-2 review, MAJOR finding).
static auto RequirementMatches(
    Context& context, SemIR::LocId loc_id,
    const SemIR::IdentifiedFacetType::StructuralRequirement& requirement,
    const SemIR::NamedConstraint& constraint,
    const SemIR::Function& requirement_fn, const SemIR::Function& member_fn,
    SemIR::SpecificId member_specific_id) -> bool {
  auto with_self_specific_id = MakeSpecificWithInnerSelf(
      context, loc_id, constraint.generic_id, constraint.generic_with_self_id,
      requirement.constraint.specific_id, requirement.self_facet_value);
  auto requirement_specific_id = GetSelfSpecificForInterfaceMemberWithSelfType(
      context, loc_id, with_self_specific_id, requirement_fn.generic_id,
      SemIR::SpecificId::None);
  return CheckFunctionTypeMatches(
      context, member_fn, requirement_fn, requirement_specific_id,
      /*check_syntax=*/false, /*diagnose=*/false, member_specific_id);
}

// Explain mode: notes for one unsatisfied requirement of a concrete self. The
// member note is at the conversion (`Missing`, `Inaccessible`) or at the
// member's declaration (`Mismatch`); the requirement note is at the
// requirement `fn`.
static auto NoteMemberFailure(DiagnosticBuilder& builder, SemIR::LocId loc_id,
                              const MemberFailureInfo& info,
                              SemIR::TypeId self_type_id,
                              const SemIR::NamedConstraint& constraint,
                              const SemIR::Function& requirement_fn,
                              SemIR::InstId requirement_decl_id) -> void {
  switch (info.failure) {
    case MemberFailure::Missing: {
      CARBON_DIAGNOSTIC(StructuralMemberMissing, Note,
                        "type {0} has no member named `{1}` required by "
                        "template constraint `{2}`",
                        SemIR::TypeId, SemIR::NameId, SemIR::NameId);
      builder.Note(loc_id, StructuralMemberMissing, self_type_id,
                   requirement_fn.name_id, constraint.name_id);
      break;
    }
    case MemberFailure::Mismatch: {
      CARBON_DIAGNOSTIC(StructuralMemberMismatch, Note,
                        "member `{1}` of type {0} does not match the signature "
                        "required by template constraint `{2}`",
                        SemIR::TypeId, SemIR::NameId, SemIR::NameId);
      builder.Note(info.member_decl_id.has_value()
                       ? SemIR::LocId(info.member_decl_id)
                       : loc_id,
                   StructuralMemberMismatch, self_type_id,
                   requirement_fn.name_id, constraint.name_id);
      break;
    }
    case MemberFailure::Inaccessible: {
      CARBON_DIAGNOSTIC(
          StructuralMemberInaccessible, Note,
          "member `{1}` of type {0} is {2:private|protected} here "
          "and cannot satisfy template constraint `{3}`",
          SemIR::TypeId, SemIR::NameId, Diagnostics::BoolAsSelect,
          SemIR::NameId);
      builder.Note(loc_id, StructuralMemberInaccessible, self_type_id,
                   requirement_fn.name_id,
                   info.access_kind == SemIR::AccessKind::Private,
                   constraint.name_id);
      break;
    }
  }
  CARBON_DIAGNOSTIC(StructuralRequirementHere, Note,
                    "requirement declared here");
  builder.Note(requirement_decl_id, StructuralRequirementHere);
}

// Checks one requirement `fn` of `constraint` against the concrete self type.
// Returns the failure, or `nullopt` when satisfied.
static auto CheckRequirementFunction(
    Context& context, SemIR::LocId loc_id,
    const SemIR::IdentifiedFacetType::StructuralRequirement& requirement,
    const SemIR::NamedConstraint& constraint, SemIR::TypeId self_type_id,
    const SemIR::Function& requirement_fn) -> std::optional<MemberFailureInfo> {
  MemberLookupInfo info;
  auto member_id = FindStructuralMember(context, loc_id, self_type_id,
                                        requirement_fn.name_id, &info);
  if (!member_id.has_value()) {
    if (info.found_but_prohibited) {
      // A private member of a base class: lookup through the extended scope
      // prohibits it regardless of the access context, so it is reported as
      // inaccessible, not missing.
      return MemberFailureInfo{.failure = MemberFailure::Inaccessible,
                               .access_kind = info.access_kind};
    }
    return MemberFailureInfo{.failure = MemberFailure::Missing};
  }
  if (member_id == SemIR::ErrorInst::InstId) {
    // The lookup found something it could not resolve (such as an alias of an
    // associated entity with no `impl`); the member is not a function.
    return MemberFailureInfo{.failure = MemberFailure::Mismatch};
  }

  // D-SC-5(b): the access decision, applied to the found member against the
  // access allowed from here. A private member satisfies only from inside its
  // own class.
  auto self_type_const_id = context.types().GetConstantId(self_type_id);
  AccessInfo access_info = {.constant_id = self_type_const_id,
                            .highest_allowed_access = GetHighestAllowedAccess(
                                context, self_type_const_id)};
  if (IsAccessProhibited(context, access_info, info.access_kind,
                         /*is_parent_access=*/false)) {
    return MemberFailureInfo{.failure = MemberFailure::Inaccessible,
                             .access_kind = info.access_kind};
  }

  // D-SC-5(c): the member must be exactly one function. An overload set, a
  // function pointer, a field, a class or a namespace does not satisfy a
  // requirement (review fold A10); a C++ overload set does only when it holds
  // exactly one candidate, which is imported and matched as that function
  // (SC-1c).
  auto callee = SemIR::GetCallee(context.sem_ir(), member_id);
  if (auto* cpp_overload = std::get_if<SemIR::CalleeCppOverloadSet>(&callee)) {
    MemberFailureInfo failure;
    auto cpp_member_id = ImportSingleCppOverloadCandidate(
        context, loc_id, *cpp_overload, requirement_fn, &failure);
    if (!cpp_member_id.has_value()) {
      return failure;
    }
    callee = SemIR::GetCallee(context.sem_ir(), cpp_member_id);
  }
  auto* callee_fn = std::get_if<SemIR::CalleeFunction>(&callee);
  if (!callee_fn) {
    return MemberFailureInfo{.failure = MemberFailure::Mismatch};
  }
  const auto& member_fn = context.functions().Get(callee_fn->function_id);
  if (!RequirementMatches(context, loc_id, requirement, constraint,
                          requirement_fn, member_fn,
                          callee_fn->enclosing_specific_id)) {
    return MemberFailureInfo{.failure = MemberFailure::Mismatch,
                             .member_decl_id = member_fn.latest_decl_id()};
  }
  return std::nullopt;
}

// Both modes of the check (see `ReportMode`).
static auto CheckRequirements(Context& context, SemIR::LocId loc_id,
                              SemIR::IdentifiedFacetTypeId identified_id,
                              ReportMode mode) -> StructuralCheckResult {
  // The identified facet type store can grow during the check (D-SC-6
  // identifies the self's own facet type), so copy the requirements.
  llvm::SmallVector<SemIR::IdentifiedFacetType::StructuralRequirement>
      requirements(context.identified_facet_types()
                       .Get(identified_id)
                       .structural_requirements());

  for (const auto& requirement : requirements) {
    const auto& constraint = context.named_constraints().Get(
        requirement.constraint.named_constraint_id);

    // Canonicalize the self exactly as the interface loop does: look through
    // a `FacetValue` and `facet as type`.
    auto self = GetCanonicalQuerySelfForLookupImplWitness(
        context, requirement.self_facet_value);
    if (self == SemIR::ErrorInst::ConstantId) {
      return StructuralCheckResult::Unsatisfied;
    }

    // D-SC-19: deferred for a template-phase self.
    if (SelfIsTemplatePhase(context, self)) {
      continue;
    }

    // D-SC-6: a checked-symbolic self.
    if (self.is_symbolic()) {
      if (SelfFacetCarriesRequirement(context, loc_id, self, requirement)) {
        continue;
      }
      if (mode.explain) {
        CARBON_DIAGNOSTIC(StructuralRequirementNeedsConcreteType, Note,
                          "template constraint `{0}` can only be satisfied by "
                          "a concrete type; {1} is a checked generic binding",
                          SemIR::NameId, InstIdAsConstant);
        mode.explain->Note(loc_id, StructuralRequirementNeedsConcreteType,
                           constraint.name_id,
                           context.constant_values().GetInstId(self));
      }
      return StructuralCheckResult::Unsatisfied;
    }

    // A concrete self is a type.
    auto self_type_id = context.types().TryGetTypeIdForTypeConstantId(self);
    if (!self_type_id.has_value()) {
      return StructuralCheckResult::Unsatisfied;
    }

    // D-SC-5(a), review fold A11: a constraint still being defined has no
    // members block yet and is treated as incomplete.
    if (!constraint.structural_members_id.has_value()) {
      return StructuralCheckResult::Unsatisfied;
    }
    if (auto result = RequirementTargetIsComplete(context, loc_id, self_type_id,
                                                  constraint, mode);
        result != StructuralCheckResult::Satisfied) {
      return result;
    }

    // Each requirement `fn`, in declaration order (R-8: an imported
    // requirement is an import-ref, loaded before its function is read).
    for (auto requirement_decl_id :
         context.inst_blocks().Get(constraint.structural_members_id)) {
      LoadImportRef(context, requirement_decl_id);
      auto requirement_callee =
          SemIR::GetCallee(context.sem_ir(), requirement_decl_id);
      auto* requirement_callee_fn =
          std::get_if<SemIR::CalleeFunction>(&requirement_callee);
      CARBON_CHECK(requirement_callee_fn,
                   "Structural requirement {0} is not a function",
                   context.insts().Get(requirement_decl_id));
      const auto& requirement_fn =
          context.functions().Get(requirement_callee_fn->function_id);

      auto failure =
          CheckRequirementFunction(context, loc_id, requirement, constraint,
                                   self_type_id, requirement_fn);
      if (!failure) {
        continue;
      }
      if (mode.explain) {
        NoteMemberFailure(*mode.explain, loc_id, *failure, self_type_id,
                          constraint, requirement_fn, requirement_decl_id);
      }
      return StructuralCheckResult::Unsatisfied;
    }
  }
  return StructuralCheckResult::Satisfied;
}

auto CheckStructuralRequirements(Context& context, SemIR::LocId loc_id,
                                 SemIR::IdentifiedFacetTypeId identified_id,
                                 bool diagnose) -> StructuralCheckResult {
  return CheckRequirements(context, loc_id, identified_id,
                           {.diagnose = diagnose, .explain = nullptr});
}

auto NoteStructuralConformanceFailure(Context& context, SemIR::LocId loc_id,
                                      SemIR::ConstantId query_self_const_id,
                                      SemIR::TypeId facet_type_id,
                                      DiagnosticBuilder& builder) -> void {
  // The conversion already identified this facet type against this self, so
  // this is a cache lookup; an unidentified facet type was diagnosed there.
  auto identified_id =
      TryToIdentifyFacetType(context, loc_id, query_self_const_id,
                             context.types().GetTypeInstId(facet_type_id),
                             /*allow_partially_identified=*/false);
  if (!identified_id.has_value()) {
    return;
  }
  CheckRequirements(context, loc_id, identified_id,
                    {.diagnose = false, .explain = &builder});
}

auto FacetTypeHasStructuralRequirements(Context& context, SemIR::TypeId type_id)
    -> SemIR::NamedConstraintId {
  auto facet_type = context.types().TryGetAs<SemIR::FacetType>(type_id);
  if (!facet_type) {
    return SemIR::NamedConstraintId::None;
  }

  llvm::SmallVector<SemIR::NamedConstraintId> work;
  auto add_constraints = [&](const SemIR::DeclaredFacetType& declared) {
    for (const auto& extend : declared.extend_named_constraints) {
      work.push_back(extend.named_constraint_id);
    }
    for (const auto& impls : declared.self_impls_named_constraints) {
      work.push_back(impls.named_constraint_id);
    }
    for (const auto& type_impls : declared.type_impls_named_constraints) {
      work.push_back(type_impls.specific_named_constraint.named_constraint_id);
    }
  };
  add_constraints(
      context.declared_facet_types().Get(facet_type->declared_facet_type_id));

  llvm::SmallVector<SemIR::NamedConstraintId> visited;
  while (!work.empty()) {
    auto constraint_id = work.pop_back_val();
    if (llvm::is_contained(visited, constraint_id)) {
      continue;
    }
    visited.push_back(constraint_id);
    const auto& constraint = context.named_constraints().Get(constraint_id);
    if (constraint.is_template) {
      return constraint_id;
    }
    // Only a complete constraint's `require` block is walked; an incomplete
    // one is caught at its use (R-5).
    if (!constraint.is_complete()) {
      continue;
    }
    for (auto require_id : context.require_impls_blocks().Get(
             constraint.require_impls_block_id)) {
      const auto& require = context.require_impls().Get(require_id);
      auto facet_type_inst_id = context.constant_values().GetConstantInstId(
          require.facet_type_inst_id);
      if (!facet_type_inst_id.has_value()) {
        continue;
      }
      if (auto required_facet_type =
              context.insts().TryGetAs<SemIR::FacetType>(facet_type_inst_id)) {
        add_constraints(context.declared_facet_types().Get(
            required_facet_type->declared_facet_type_id));
      }
    }
  }
  return SemIR::NamedConstraintId::None;
}

}  // namespace Carbon::Check
