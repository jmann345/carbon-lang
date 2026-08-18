// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_LOWER_FILE_CONTEXT_H_
#define CARBON_TOOLCHAIN_LOWER_FILE_CONTEXT_H_

#include <utility>

#include "toolchain/lower/context.h"
#include "toolchain/lower/specific_coalescer.h"
#include "toolchain/lower/type.h"
#include "toolchain/parse/tree_and_subtrees.h"
#include "toolchain/sem_ir/file.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst_namer.h"

namespace clang {
class CodeGenerator;
class FunctionDecl;
}  // namespace clang

namespace Carbon::Lower {

// Information about how a given function declaration is lowered.
struct FunctionInfo {
  // The type of the lowered function.
  llvm::FunctionType* type;

  // The debug info type of the lowered function.
  llvm::DISubroutineType* di_type;

  // The indices of the `Call` parameter patterns that correspond to parameters
  // of the LLVM IR function, in the order of the LLVM IR parameter list. Some
  // `Call` parameters may be omitted (e.g. if they are stateless), and the
  // order may differ from the SemIR `Call` parameter list (e.g. the return
  // parameter, if any, always goes first).
  llvm::SmallVector<SemIR::CallParamIndex> lowered_param_indices;

  // The indices of any `Call` param patterns that aren't present in
  // lowered_param_pattern_ids.
  llvm::SmallVector<SemIR::CallParamIndex> unused_param_indices;

  // The lowered function declaration.
  llvm::Function* llvm_function;

  // Whether the function type information is inexact, because some component
  // type was incomplete. If this is set, the function should not be used to
  // emit a definition or a call.
  bool inexact;
};

class FunctionContext;

// A file-scope `let` binding whose bound value is a runtime value, found by
// `FileContext`'s pre-pass over the file's top instruction block (W-069).
// Such a binding has no constant and no `VarStorage`, so `GetValue` would
// otherwise have nothing to serve references with: the bound value is
// computed inside `__global_init`, and the design licenses modeling the
// acquired value with backing storage as long as no address is ever exposed
// at the language level (docs/design/values.md: value expressions may or may
// not have storage, and copies are permitted under "as-if").
struct GlobalLetBinding {
  // How references to the binding are served.
  enum class Disposition : int8_t {
    // The value representation is a copy of the object representation (the
    // scalar case): the bound value is promoted to a named backing global
    // that `__global_init` stores once, and every reference — same-file
    // cross-function or cross-file — loads from it.
    Promote,
    // The value representation is `None` (e.g. an empty tuple type): no
    // storage is minted, and references produce the empty value.
    NoStorage,
    // Any other value representation (pointer or custom), or an initializer
    // shape the pre-pass could not map to a `__global_init`-resident
    // instruction: not promoted in this slice. References fail loudly with a
    // named message instead of tripping the generic missing-value check.
    Declined,
  };

  // The binding instruction in the file's top instruction block.
  SemIR::InstId binding_id;
  // The binding's bound value (`AnyBinding::value_id`) — the instruction
  // that `NameRef` lowering peeks through the binding to.
  SemIR::InstId value_id;
  // The declared type of the binding.
  SemIR::TypeId type_id;
  Disposition disposition;
  // For `Promote`: the file-top-block conversion wrapper instructions
  // between the `__global_init`-resident initializer and `value_id`, in
  // lowering (operand-first) order. These aren't part of any lowered block,
  // so the ctor-store hook lowers them on demand.
  llvm::SmallVector<SemIR::InstId, 4> chain = {};
  // For `Promote`: the `__global_init`-resident instruction after whose
  // lowering the bound value can be computed and stored.
  SemIR::InstId ctor_key_id = SemIR::InstId::None;
};

// Context and shared functionality for lowering within a SemIR file.
class FileContext {
 public:
  using LoweredConstantStore =
      FixedSizeValueStore<SemIR::InstId, llvm::Constant*,
                          Tag<SemIR::CheckIRId>>;

  explicit FileContext(Context& context, const SemIR::File& sem_ir,
                       const SemIR::InstNamer* inst_namer,
                       llvm::raw_ostream* vlog_stream);

  // Prepares to lower code in this IR, by precomputing needed LLVM types,
  // constants, declarations, etc. Should only be called once, before we lower
  // anything in this file.
  auto PrepareToLower() -> void;

  // Lowers all the definitions provided by the SemIR::File to LLVM IR.
  auto LowerDefinitions() -> void;

  // Perform final cleanup tasks once all lowering has been completed.
  auto Finalize() -> void;

  // Gets a callable's function. Returns nullptr for a builtin or a function we
  // have not lowered.
  auto GetFunction(SemIR::FunctionId function_id,
                   SemIR::SpecificId specific_id = SemIR::SpecificId::None)
      -> llvm::Function* {
    const auto& function_info = GetFunctionInfo(function_id, specific_id);
    return function_info ? function_info->llvm_function : nullptr;
  }

  // Returns the FunctionInfo for the given function in the given specific, if
  // it has already been computed.
  auto GetFunctionInfo(SemIR::FunctionId function_id,
                       SemIR::SpecificId specific_id)
      -> std::optional<FunctionInfo>& {
    return specific_id.has_value() ? specific_functions_.Get(specific_id)
                                   : functions_.Get(function_id);
  }

  // Returns the FunctionInfo for the given function in the given specific. If
  // it's not already available, this function will compute it, including
  // creating the `llvm::Function` for it. Returns nullopt for a builtin.
  //
  // The fallback information is used if the specific function has incomplete
  // types.
  auto GetOrCreateFunctionInfo(
      SemIR::FunctionId function_id, SemIR::SpecificId specific_id,
      FileContext* fallback_file = nullptr,
      SemIR::FunctionId fallback_function_id = SemIR::FunctionId::None,
      SemIR::SpecificId fallback_specific_id = SemIR::SpecificId::None)
      -> std::optional<FunctionInfo>&;

  // Returns a lowered type for the given type_id.
  auto GetType(SemIR::TypeId type_id) -> llvm::Type* {
    return GetTypeAndDIType(type_id).llvm_ir_type;
  }

  // Returns the alignment of the given type_id. This adds the alignment to the
  // fingerprint.
  auto GetAlignment(SemIR::TypeId type_id) -> llvm::Align {
    return llvm::Align(sem_ir()
                           .types()
                           .GetCompleteTypeInfo(type_id)
                           .object_layout.alignment.bytes());
  }

  // Returns both the lowered llvm IR type and the lowered llvm IR debug info
  // type for the given type_id.
  auto GetTypeAndDIType(SemIR::TypeId type_id) const -> LoweredTypes {
    CARBON_CHECK(type_id.has_value(), "Should not be called with `None`");
    CARBON_CHECK(type_id.is_concrete(), "Lowering symbolic type {0}: {1}",
                 type_id, sem_ir().types().GetAsInst(type_id));
    auto result = types_.Get(type_id);
    if (!result.llvm_ir_type) {
      result.llvm_ir_type = context_->GetOpaqueType();
    }
    return result;
  }

  // Returns location information for use with DebugInfo.
  auto GetLocForDI(SemIR::InstId inst_id) -> Context::LocForDI;

  // Returns a lowered value to use for a value of type `type`.
  auto GetTypeAsValue() -> llvm::Constant* {
    return context().GetTypeAsValue();
  }

  // Returns a lowered value to use for a value of literal type.
  auto GetLiteralAsValue() -> llvm::Constant* {
    return context().GetLiteralAsValue();
  }

  // Returns a value for the given constant. If specified, `use_inst_id` is the
  // instruction that is using this constant.
  auto GetConstant(SemIR::ConstantId const_id, SemIR::InstId use_inst_id)
      -> llvm::Value*;

  auto GetVtable(SemIR::VtableId vtable_id, SemIR::SpecificId specific_id)
      -> llvm::Constant* {
    if (!specific_id.has_value()) {
      return vtables_.Get(vtable_id);
    }
    auto*& specific_vtable = specific_vtables_.Get(specific_id);
    if (!specific_vtable) {
      specific_vtable =
          BuildVtable(sem_ir().vtables().Get(vtable_id), specific_id);
    }
    return specific_vtable;
  }

  // Returns the empty LLVM struct type used to represent the type `type`.
  auto GetTypeType() -> llvm::StructType* { return context().GetTypeType(); }
  auto GetFormType() -> llvm::StructType* { return context().GetFormType(); }

  auto context() -> Context& { return *context_; }
  auto llvm_context() -> llvm::LLVMContext& { return context().llvm_context(); }
  auto llvm_module() -> llvm::Module& { return context().llvm_module(); }
  auto sem_ir() const -> const SemIR::File& { return *sem_ir_; }
  auto cpp_file() -> const SemIR::CppFile* { return sem_ir().cpp_file(); }
  auto inst_namer() -> const SemIR::InstNamer* { return inst_namer_; }
  auto global_variables() -> const Map<SemIR::InstId, llvm::GlobalVariable*>& {
    return global_variables_;
  }
  auto printf_int_format_string() -> llvm::Value* {
    return context().printf_int_format_string();
  }
  auto SetPrintfIntFormatString(llvm::Value* printf_int_format_string) {
    context().SetPrintfIntFormatString(printf_int_format_string);
  }

  // Builds the global for the given instruction, which should then be cached by
  // the caller.
  auto BuildGlobalVariableDecl(SemIR::VarStorage var_storage)
      -> llvm::Constant*;

  // Builds the global for the given instruction which is known to not be
  // imported from C++. Reuses an existing `llvm::GlobalVariable` with the same
  // mangled name if one was already created, so repeated calls for one
  // variable all yield the same object.
  auto BuildNonCppGlobalVariableDecl(SemIR::VarStorage var_storage)
      -> llvm::GlobalVariable*;

  // Returns the registry entry for `inst_id` if it is a file-scope runtime
  // `let` binding of this file or such a binding's bound value, and null
  // otherwise. See `GlobalLetBinding`.
  auto LookupGlobalLetBinding(SemIR::InstId inst_id) const
      -> const GlobalLetBinding*;

  // Returns the named backing global for a promoted file-scope runtime `let`
  // binding, creating a declaration if it doesn't exist yet. Reuses an
  // existing `llvm::GlobalVariable` with the same mangled name, so the
  // defining file's definition pass and every referencing file all yield the
  // same object. The defining file's `PrepareGlobalLetDefinitions` adds the
  // zero initializer that makes it a definition.
  auto GetOrCreateGlobalLetVariable(const GlobalLetBinding& binding)
      -> llvm::GlobalVariable*;

  // Called after each instruction is lowered while building this file's
  // `__global_init`: if `ctor_inst_id` computed the initializer of one or
  // more promoted file-scope `let` bindings, emits the stores of their bound
  // values into the backing globals.
  auto EmitGlobalLetStores(FunctionContext& ctor_context,
                           SemIR::InstId ctor_inst_id) -> void;

  // Builds the definition for the given function. If the function is only a
  // declaration with no definition, does nothing. If this is a generic it'll
  // only be lowered if the specific_id is specified. During this lowering of
  // a generic, more generic functions may be added for lowering.
  auto BuildFunctionDefinition(
      SemIR::FunctionId function_id,
      SemIR::SpecificId specific_id = SemIR::SpecificId::None) -> void;

 private:
  // Lower global variables defined in `inst_block_id`.
  auto LowerGlobalVariables(SemIR::InstBlockId inst_block_id) -> void;

  // Pre-pass over the file's top instruction block registering every
  // file-scope `let` binding whose bound value is a runtime value, with the
  // disposition its type's value representation selects. Pure SemIR
  // analysis, run from `PrepareToLower` so the registry is available both
  // when this file is being lowered and when another file's lowering
  // references this file's bindings.
  auto RegisterGlobalLetBindings() -> void;

  // Converts the promoted bindings' backing globals into zero-initialized
  // definitions and schedules their `__global_init` stores. Only run (from
  // `LowerDefinitions`) when this file itself is being lowered.
  auto PrepareGlobalLetDefinitions() -> void;

  // Notes that a C++ function has been referenced for the first time, so we
  // should ask Clang to generate a definition for it if possible.
  auto HandleReferencedCppFunction(clang::FunctionDecl* cpp_decl)
      -> llvm::Function*;

  // Notes that a specific function has been referenced for the first time.
  // Updates the fingerprint to include the function's type, and adds the
  // function to the list of specific functions whose definitions should be
  // lowered.
  auto HandleReferencedSpecificFunction(SemIR::FunctionId function_id,
                                        SemIR::SpecificId specific_id,
                                        llvm::Type* llvm_type,
                                        llvm::Type* sret_type) -> void;

  // Builds an LLVM function declaration for the given function, or returns an
  // existing one if we've already lowered another declaration of the same
  // function.
  auto GetOrCreateLLVMFunction(const FunctionTypeInfo& function_type_info,
                               SemIR::FunctionId function_id,
                               SemIR::SpecificId specific_id)
      -> llvm::Function*;

  // Builds the declaration for the given function, which should then be cached
  // by the caller.
  auto BuildFunctionDecl(
      SemIR::FunctionId function_id,
      SemIR::SpecificId specific_id = SemIR::SpecificId::None,
      FileContext* fallback_file = nullptr,
      SemIR::FunctionId fallback_function_id = SemIR::FunctionId::None,
      SemIR::SpecificId fallback_specific_id = SemIR::SpecificId::None)
      -> std::optional<FunctionInfo>;

  // Builds a function's body. Common functionality for all functions.
  //
  // The `function_id` and `specific_id` identify the function within this
  // context's file. If the function was defined in a different file,
  // `definition_context` is a `FileContext` for that other file.
  // `definition_function` is the `Function` object within the file that owns
  // the definition.
  auto BuildFunctionBody(SemIR::FunctionId function_id,
                         SemIR::SpecificId specific_id,
                         const SemIR::Function& declaration_function,
                         FileContext& definition_context,
                         const SemIR::Function& definition_function) -> void;

  // Build the DISubprogram metadata for the given function.
  auto BuildDISubprogram(const SemIR::Function& function,
                         const FunctionInfo& function_info)
      -> llvm::DISubprogram*;

  auto BuildVtable(const SemIR::Vtable& vtable, SemIR::SpecificId specific_id)
      -> llvm::Constant*;

  // Records a specific that was lowered for a generic. These are added one
  // by one while lowering their definitions.
  auto AddLoweredSpecificForGeneric(SemIR::GenericId generic_id,
                                    SemIR::SpecificId specific_id) {
    lowered_specifics_.Get(generic_id).push_back(specific_id);
  }

  // The overall lowering context.
  Context* context_;

  // The input SemIR.
  const SemIR::File* const sem_ir_;

  // The instruction namer, if given.
  const SemIR::InstNamer* const inst_namer_;

  // The optional vlog stream.
  llvm::raw_ostream* vlog_stream_;

  // Maps callables to lowered functions. SemIR treats callables as the
  // canonical form of a function, so lowering needs to do the same.
  using LoweredFunctionStore =
      FixedSizeValueStore<SemIR::FunctionId, std::optional<FunctionInfo>,
                          Tag<SemIR::CheckIRId>>;
  LoweredFunctionStore functions_;

  // Maps specific callables to lowered functions.
  FixedSizeValueStore<SemIR::SpecificId, std::optional<FunctionInfo>,
                      Tag<SemIR::CheckIRId>>
      specific_functions_;

  // Provides lowered versions of types. Entries are non-symbolic types.
  //
  // TypeIds internally are concrete ConstantIds.
  using LoweredTypeStore =
      FixedSizeValueStore<SemIR::TypeId, LoweredTypes, Tag<SemIR::CheckIRId>>;
  LoweredTypeStore types_;

  // Maps constants to their lowered values. Indexes are the `InstId` for
  // constant instructions.
  LoweredConstantStore constants_;

  // Maps global variables to their lowered variant.
  Map<SemIR::InstId, llvm::GlobalVariable*> global_variables_;

  // Registry of file-scope runtime `let` bindings, in top-block order. See
  // `GlobalLetBinding` and `RegisterGlobalLetBindings`.
  llvm::SmallVector<GlobalLetBinding> global_let_bindings_;

  // Maps both a registered binding's instruction id and its bound-value
  // instruction id to the binding's index in `global_let_bindings_`.
  Map<SemIR::InstId, int32_t> global_let_binding_indices_;

  // Pairs of a `__global_init`-resident initializer instruction and the
  // index of a promoted binding whose backing-global store is emitted right
  // after that instruction lowers. Built by `PrepareGlobalLetDefinitions`;
  // one entry per promoted binding.
  llvm::SmallVector<std::pair<SemIR::InstId, int32_t>> global_let_ctor_stores_;

  // The number of entries of `global_let_ctor_stores_` whose stores have
  // been emitted, checked against the schedule after `__global_init` is
  // built so no promoted binding is left as a silently zero-initialized
  // global.
  int global_let_stores_emitted_ = 0;

  // For a generic function, keep track of the specifics for which LLVM
  // function declarations were created. Those can be retrieved then from
  // `specific_functions_`.
  FixedSizeValueStore<SemIR::GenericId, llvm::SmallVector<SemIR::SpecificId>,
                      Tag<SemIR::CheckIRId>>
      lowered_specifics_;

  SpecificCoalescer coalescer_;

  FixedSizeValueStore<SemIR::VtableId, llvm::Constant*, Tag<SemIR::CheckIRId>>
      vtables_;
  FixedSizeValueStore<SemIR::SpecificId, llvm::Constant*, Tag<SemIR::CheckIRId>>
      specific_vtables_;
};

}  // namespace Carbon::Lower

#endif  // CARBON_TOOLCHAIN_LOWER_FILE_CONTEXT_H_
