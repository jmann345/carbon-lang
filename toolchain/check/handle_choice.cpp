// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#include <algorithm>

#include "common/map.h"
#include "toolchain/base/kind_switch.h"
#include "toolchain/check/context.h"
#include "toolchain/check/control_flow.h"
#include "toolchain/check/convert.h"
#include "toolchain/check/decl_name_stack.h"
#include "toolchain/check/eval.h"
#include "toolchain/check/function.h"
#include "toolchain/check/generic.h"
#include "toolchain/check/handle.h"
#include "toolchain/check/inst.h"
#include "toolchain/check/literal.h"
#include "toolchain/check/name_component.h"
#include "toolchain/check/name_lookup.h"
#include "toolchain/check/pattern.h"
#include "toolchain/check/type.h"
#include "toolchain/check/type_completion.h"
#include "toolchain/check/unused.h"
#include "toolchain/diagnostics/diagnostic.h"
#include "toolchain/lex/token_kind.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/name_scope.h"
#include "toolchain/sem_ir/type_info.h"
#include "toolchain/sem_ir/typed_insts.h"

namespace Carbon::Check {

auto HandleParseNode(Context& context, Parse::ChoiceIntroducerId node_id)
    -> bool {
  // This choice is potentially generic.
  StartGenericDecl(context);
  // Create an instruction block to hold the instructions created as part of the
  // choice signature, such as generic parameters.
  context.inst_block_stack().Push();
  // There's no modifiers on a choice, but this informs how to typecheck any
  // generic binding pattern.
  context.decl_introducer_state_stack().Push<Lex::TokenKind::Choice>();
  // Push the bracketing node.
  context.node_stack().Push(node_id);
  // The choice's name follows.
  context.decl_name_stack().PushScopeAndStartName();
  return true;
}

auto HandleParseNode(Context& context, Parse::ChoiceDefinitionStartId node_id)
    -> bool {
  auto name = PopNameComponent(context);
  auto name_context = context.decl_name_stack().FinishName(name);
  context.node_stack()
      .PopAndDiscardSoloNodeId<Parse::NodeKind::ChoiceIntroducer>();
  context.decl_introducer_state_stack().Pop<Lex::TokenKind::Choice>();

  auto decl_block_id = context.inst_block_stack().Pop();

  // Choices create a ClassId, since they ultimately turn into a class with
  // methods and some builtin impls.
  auto class_decl = SemIR::ClassDecl{.type_id = SemIR::TypeType::TypeId,
                                     .class_id = SemIR::ClassId::None,
                                     .decl_block_id = decl_block_id};
  auto class_decl_id = AddPlaceholderInst(context, node_id, class_decl);

  context.decl_name_stack().AddNameOrDiagnose(name_context, class_decl_id,
                                              SemIR::AccessKind::Public);

  // An inst block for the body of the choice.
  context.inst_block_stack().Push();
  auto body_block_id = context.inst_block_stack().PeekOrAdd();

  SemIR::Class class_info = {
      name_context.MakeEntityWithParamsBase(name, class_decl_id,
                                            /*is_extern=*/false,
                                            SemIR::LibraryNameId::None),
      {// `.self_type_id` depends on the ClassType, so is set below.
       .self_type_id = SemIR::TypeId::None,
       .inheritance_kind = SemIR::ClassFields::Final,
       .is_choice = true,
       // TODO: Handle the case where there's control flow in the alternatives.
       // For example:
       //
       //   choice C {
       //     Alt(x: if true then i32 else f64),
       //   }
       //
       // We may need to track a list of instruction blocks here, as we do for a
       // function.
       .body_block_id = body_block_id}};

  // This call finishes the GenericDecl, after which we can use the `Self`
  // specific.
  class_info.generic_id = BuildGenericDecl(context, class_decl_id);
  auto self_specific_id =
      context.generics().GetSelfSpecific(class_info.generic_id);

  class_info.definition_id = class_decl_id;
  class_info.scope_id = context.name_scopes().Add(
      class_decl_id, SemIR::NameId::None, class_info.parent_scope_id);
  class_decl.class_id = context.classes().Add(class_info);
  if (class_info.has_parameters()) {
    class_decl.type_id = GetGenericClassType(
        context, class_decl.class_id, context.scope_stack().PeekSpecificId());
  }

  ReplaceInstBeforeConstantUse(context, class_decl_id, class_decl);

  // We had to construct the `ClassId` from `Class` in order to build the `Self`
  // type below. But it needs to be written back to the `Class` in the
  // ValueStore, not the local variable. This gives a mutable reference to the
  // `Class` in the ValueStore.
  SemIR::Class& mut_class = context.classes().Get(class_decl.class_id);
  // Build the `Self` type using the resulting type constant.
  auto self_type_id =
      GetClassType(context, class_decl.class_id, self_specific_id);
  mut_class.self_type_id = self_type_id;

  // Enter the choice scope.
  context.scope_stack().PushForEntity(class_decl_id, class_info.scope_id,
                                      self_specific_id);
  // Checking the binding pattern for an alternative requires a non-empty stack.
  // We reuse the Choice token even though we're now checking an alternative
  // inside the Choice, since there's no better token to use.
  //
  //  TODO: The token here is _not_ `Choice` though, we shouldn't need to use
  //  that here. Either remove the need for a token or find a token (a new
  //  introducer?) for the alternative to name.
  context.decl_introducer_state_stack().Push<Lex::TokenKind::Choice>();
  StartGenericDefinition(context, class_info.generic_id);

  context.name_scopes().AddRequiredName(
      class_info.scope_id, SemIR::NameId::SelfType,
      context.types().GetTypeInstId(self_type_id));

  // Enter a scope for the first alternative's parameter patterns. Parameter
  // names bind in this scope rather than in the choice's scope — as a function
  // declaration's parameter names bind in the scope pushed by
  // `DeclNameStack::PushScopeAndStartName`, not in the enclosing scope — so
  // different alternatives can reuse a parameter name.
  context.scope_stack().PushForChoiceAlternative(class_decl_id);

  // Mark the beginning of the choice body.
  context.node_stack().Push(node_id, class_decl.class_id);

  CARBON_CHECK(context.choice_deferred_bindings().empty(),
               "Alternatives left behind in choice_deferred_bindings: {0}",
               context.choice_deferred_bindings().size());
  return true;
}

static auto AddChoiceAlternative(
    Context& context, Parse::NodeIdOneOf<Parse::ChoiceAlternativeListCommaId,
                                         Parse::ChoiceDefinitionId>
                          node_id) -> void {
  // Note, there is nothing like a ChoiceAlternativeIntroducer node, so no parse
  // node to pop here.
  //
  // An alternative with a parameter list — including an empty one, per the
  // constant-vs-factory distinction in docs/design/sum_types.md — becomes a
  // function member; an alternative without one becomes a constant member.
  // Both are queued here and built at `ChoiceDefinitionId`, when the object
  // representation is known.
  auto name_component = PopNameComponent(context);
  // Leave the alternative's parameter scope. As with a function declaration's
  // parameters, no unused-name check applies: the names become the generated
  // constructor's parameter names.
  context.scope_stack().Pop();
  context.choice_deferred_bindings().push_back({node_id, name_component});
}

namespace {
// Info about the Choice type, used to construct each alternative member of the
// class representing the Choice.
struct ChoiceInfo {
  // The `ClassDecl` of the class representing the choice.
  SemIR::InstId class_decl_id;
  // The `Self` type.
  SemIR::TypeId self_type_id;
  // The scope of the class for adding the alternatives to.
  SemIR::NameScopeId name_scope_id;
  // A struct type with the same fields as `Self`. Used to construct `Self`.
  SemIR::TypeId self_struct_type_id;
  // The type of the discriminant value.
  SemIR::TypeId discriminant_type_id;
  // The `CustomLayoutType` of the payload region, or `None` if no alternative
  // carries a payload.
  SemIR::TypeId payload_type_id;
  int num_alternative_bits;
};

// Per-alternative info for a function-like (parameterized) alternative.
struct ChoiceAlternativeFunctionInfo {
  // The index of the alternative within the choice declaration.
  int alternative_index;
  // Whether the alternative was rejected with a diagnostic. An error scope
  // entry has already been added for it, so later references diagnose sanely
  // rather than reporting a phantom missing member.
  bool error = false;
  // The declared parameter types.
  llvm::SmallVector<SemIR::TypeId> param_type_ids;
  // The payload tuple type, or `None` for a zero-payload `Alt()` alternative.
  SemIR::TypeId payload_tuple_type_id = SemIR::TypeId::None;
  // The index of this alternative's field within the payload region, or -1 for
  // a zero-payload alternative.
  int payload_field_index = -1;
};
}  // namespace

// Returns whether `type_id` mentions the choice currently being defined
// (`Self`-dependence), looking through qualifiers, pointers, and aggregates.
// Other class types are not recursed into: a completed class cannot contain
// the choice being defined.
static auto TypeContainsChoice(Context& context, SemIR::TypeId type_id,
                               SemIR::ClassId class_id) -> bool {
  // Iterative worklist (upstream bans recursion, misc-no-recursion). The
  // walked constructors cannot form a cycle: only the choice being defined
  // could close one, and finding it terminates the walk.
  llvm::SmallVector<SemIR::TypeId> worklist = {type_id};
  while (!worklist.empty()) {
    auto inst = context.types().GetAsInst(
        context.types().GetUnqualifiedType(worklist.pop_back_val()));
    CARBON_KIND_SWITCH(inst) {
      case CARBON_KIND(SemIR::ClassType class_type): {
        if (class_type.class_id == class_id) {
          return true;
        }
        break;
      }
      case CARBON_KIND(SemIR::PointerType pointer_type): {
        worklist.push_back(
            context.types().GetTypeIdForTypeInstId(pointer_type.pointee_id));
        break;
      }
      case CARBON_KIND(SemIR::ArrayType array_type): {
        worklist.push_back(context.types().GetTypeIdForTypeInstId(
            array_type.element_type_inst_id));
        break;
      }
      case CARBON_KIND(SemIR::StructType struct_type): {
        for (auto field :
             context.struct_type_fields().Get(struct_type.fields_id)) {
          worklist.push_back(
              context.types().GetTypeIdForTypeInstId(field.type_inst_id));
        }
        break;
      }
      case CARBON_KIND(SemIR::TupleType tuple_type): {
        for (auto element_type_id : context.types().GetBlockAsTypeIds(
                 context.inst_blocks().Get(tuple_type.type_elements_id))) {
          worklist.push_back(element_type_id);
        }
        break;
      }
      default:
        break;
    }
  }
  return false;
}

// The slice-1 payload restriction (decision-log W5 SF-6): payload types must
// be trivially copyable and trivially destructible. This accepts the scalar
// types for which that property is structural — integer, float, bool, and
// pointer types, including adapters over them such as `i32` — and rejects
// everything else with a clean diagnostic at the caller. Deliberately
// conservative: relaxing it is recorded post-0.1 work, and the match scrutinee
// gate relies on completed choices having only trivial payloads (a type
// property, not a syntactic test).
//
// Admitted exception, recorded in decision-log W5-S1: a user-declared adapter
// over a scalar with its own `Core.Destroy` impl passes this gate without a
// witness query. Harmless while destroy-op synthesis is a placeholder no-op;
// when it lands, this must become a destroy-witness triviality check (it rides
// SF-6's post-0.1 work item).
static auto IsInSlicePayloadType(Context& context, SemIR::TypeId type_id)
    -> bool {
  auto adapted_type_id = context.types().GetTransitiveAdaptedType(
      context.types().GetUnqualifiedType(type_id));
  auto inst = context.types().GetAsInst(adapted_type_id);
  return inst.Is<SemIR::IntType>() || inst.Is<SemIR::FloatType>() ||
         inst.Is<SemIR::BoolType>() || inst.Is<SemIR::PointerType>();
}

// Builds the literal for the discriminant of the alternative with the given
// index: an integer literal, or an empty tuple literal for choices that need
// no discriminant bits. Callers convert it to the discriminant type as a
// value or an initializer as appropriate. The node id is the deferred
// binding's, whose type subset-converts to `TupleLiteral`'s typed node id.
static auto MakeDiscriminantLiteral(
    Context& context, const ChoiceInfo& choice_info,
    Parse::NodeIdOneOf<Parse::ChoiceAlternativeListCommaId,
                       Parse::ChoiceDefinitionId>
        node_id,
    int alternative_index) -> SemIR::InstId {
  if (choice_info.num_alternative_bits == 0) {
    return AddInst(context, node_id,
                   SemIR::TupleLiteral{
                       .type_id = GetTupleType(context, {}),
                       .elements_id = SemIR::InstBlockId::Empty,
                   });
  } else {
    return MakeIntLiteral(context, node_id,
                          context.ints().Add(alternative_index));
  }
}

// Builds a `let` binding for an alternative without parameters as a member of
// the resulting class for the Choice definition. If the alternative was `Alt`
// then the binding will be like:
// ```
//   let Alt: ChoiceType = <ChoiceType with Alt selected>;
// ```
// When the choice carries a payload region, the conversion fills the payload
// field of the constant with an uninitialized value; see the
// `NameId::ChoicePayload` case in `ConvertStructToStructOrClass`.
static auto MakeLetBinding(Context& context, const ChoiceInfo& choice_info,
                           int alternative_index,
                           const Context::ChoiceDeferredBinding& binding)
    -> void {
  auto discriminant_value_id = ConvertToValueOfType(
      context, binding.node_id,
      MakeDiscriminantLiteral(context, choice_info, binding.node_id,
                              alternative_index),
      choice_info.discriminant_type_id);

  auto self_value_id = ConvertToValueOfType(
      context, binding.node_id,
      AddInst(context, binding.node_id,
              SemIR::StructLiteral{
                  .type_id = choice_info.self_struct_type_id,
                  .elements_id =
                      [&] {
                        context.inst_block_stack().Push();
                        context.inst_block_stack().AddInstId(
                            discriminant_value_id);
                        return context.inst_block_stack().Pop();
                      }(),
              }),
      choice_info.self_type_id);

  auto entity_name_id = context.entity_names().Add(
      {.name_id = binding.name_component.name_id,
       .parent_scope_id = choice_info.name_scope_id});
  auto bind_name_id = AddInst(context, binding.node_id,
                              SemIR::WrapperBinding{
                                  .type_id = choice_info.self_type_id,
                                  .entity_name_id = entity_name_id,
                                  .value_id = self_value_id,
                              });
  context.name_scopes()
      .Get(choice_info.name_scope_id)
      .AddRequired({.name_id = binding.name_component.name_id,
                    .result = SemIR::ScopeLookupResult::MakeFound(
                        bind_name_id, SemIR::AccessKind::Public)});
}

// Converts `value_id` into an in-place initializer of the storage `storage_id`
// for use as an element of the constructor's `ClassInit`. The choice class's
// initializing representation is in-place, so every `ClassInit` element must
// initialize its slot in place — the discipline
// `GetAggregateElementConversionTargetKind` applies when `convert.cpp` builds
// a `ClassInit` for an in-place class: an element that is not itself in-place
// is wrapped in `InPlaceInit`, whose lowering performs the destination store
// and which carries the storage argument `FindStorageArgForInitializer`
// requires when lowering a constant element (`EmitAggregateInitializer`'s
// `InitRepr::InPlace` case). A plain `Initializing` conversion satisfies
// neither: a by-copy element (such as the `UInt(N)` discriminant) would have
// no destination store and no storage argument.
static auto InitializeElementInPlace(Context& context, SemIR::LocId loc_id,
                                     SemIR::InstId storage_id,
                                     SemIR::InstId value_id) -> SemIR::InstId {
  // Parity with `InitializeExisting`'s approximate dominance check: the
  // storage must be created no later than the value initializing it.
  CARBON_CHECK(value_id == SemIR::ErrorInst::InstId ||
                   context.insts().GetRawIndex(storage_id) <=
                       context.insts().GetRawIndex(value_id),
               "Storage might not dominate initializer");
  PendingBlock target_block(&context);
  return Convert(context, loc_id, value_id,
                 {.kind = ConversionTarget::InPlaceInitializing,
                  .type_id = context.insts().Get(storage_id).type_id(),
                  .storage_id = storage_id,
                  .storage_access_block = &target_block});
}

// Builds the constructor function for a function-like alternative, and adds it
// to the choice's scope. For `choice C { Ok(value: i32), ... }` the function
// behaves like:
// ```
//   fn Ok(value: i32) -> C;
// ```
// The body initializes the return slot directly: it stores the alternative's
// index into the `.discriminant` field, and the parameters into this
// alternative's payload tuple field of the overlapping `.payload` region
// (offset zero per the F-007k storage contract in docs/design/unions.md).
static auto BuildAlternativeConstructor(
    Context& context, const ChoiceInfo& choice_info, int alternative_index,
    const ChoiceAlternativeFunctionInfo& alt,
    const Context::ChoiceDeferredBinding& binding) -> void {
  // The constructor is compiler-generated, so there is no function
  // declaration parse node to use as its location: the alternative's own node
  // is a choice node, which `FunctionDecl` (constrained to
  // `Parse::AnyFunctionDeclId`) rejects at location verification. Use an
  // inst-based location naming the choice's class declaration instead — the
  // generated-function precedent set by `BuildDestroyThunk` in
  // `ExportDestructorToCpp` — which still resolves to the choice's source
  // location in diagnostics.
  auto loc_id = SemIR::LocId(choice_info.class_decl_id);
  auto [decl_id, function_id] =
      MakeGeneratedFunctionDecl(context, loc_id,
                                {.parent_scope_id = choice_info.name_scope_id,
                                 .name_id = binding.name_component.name_id,
                                 .param_type_ids = alt.param_type_ids,
                                 .param_kind = ParamPatternKind::Value,
                                 .return_type_id = choice_info.self_type_id});

  context.scope_stack().PushForDeclName();
  StartFunctionDefinition(context, decl_id, function_id);

  const auto& function = context.functions().Get(function_id);
  auto ranges = function.call_param_ranges;
  // Copy: the underlying storage may move when new blocks are added below.
  llvm::SmallVector<SemIR::InstId> call_params(
      context.inst_blocks().Get(function.call_params_id).begin(),
      context.inst_blocks().Get(function.call_params_id).end());

  // A choice is a non-adapter class, so its value representation is a pointer
  // and its initializing representation is in-place: the return slot exists
  // and can be initialized directly.
  CARBON_CHECK(
      ranges.return_size() == 1 &&
          SemIR::InitRepr::ForType(context.sem_ir(), choice_info.self_type_id)
              .MightBeInPlace(),
      "Choice constructor must have an in-place return slot");
  auto return_slot_id = call_params[ranges.return_begin().index];

  llvm::SmallVector<SemIR::InstId> element_init_ids;

  // Store the alternative's index into the discriminant field.
  {
    auto disc_ref_id = AddInst<SemIR::ClassElementAccess>(
        context, loc_id,
        {.type_id = choice_info.discriminant_type_id,
         .base_id = return_slot_id,
         .index = SemIR::ElementIndex(0)});
    // Hand the raw literal to `InitializeElementInPlace`, which converts it to
    // an in-place initializer of the discriminant type; an empty-tuple
    // discriminant then initializes in place without requiring a `Copy` impl.
    auto disc_literal_id = MakeDiscriminantLiteral(
        context, choice_info, binding.node_id, alternative_index);
    element_init_ids.push_back(InitializeElementInPlace(
        context, loc_id, disc_ref_id, disc_literal_id));
  }

  // Store the parameters into this alternative's payload tuple field, at
  // offset zero of the payload region.
  if (alt.payload_field_index >= 0) {
    auto payload_ref_id = AddInst<SemIR::ClassElementAccess>(
        context, loc_id,
        {.type_id = choice_info.payload_type_id,
         .base_id = return_slot_id,
         .index = SemIR::ElementIndex(1)});
    auto field_ref_id = AddInst<SemIR::ClassElementAccess>(
        context, loc_id,
        {.type_id = alt.payload_tuple_type_id,
         .base_id = payload_ref_id,
         .index = SemIR::ElementIndex(alt.payload_field_index)});
    llvm::SmallVector<SemIR::InstId> args;
    for (int i = ranges.explicit_begin().index; i < ranges.explicit_end().index;
         ++i) {
      args.push_back(call_params[i]);
    }
    auto tuple_literal_id = AddInst(
        context, binding.node_id,
        SemIR::TupleLiteral{.type_id = alt.payload_tuple_type_id,
                            .elements_id = context.inst_blocks().Add(args)});
    element_init_ids.push_back(InitializeElementInPlace(
        context, loc_id, field_ref_id, tuple_literal_id));
  } else if (choice_info.payload_type_id.has_value()) {
    // A zero-payload `Alt()` alternative of a payload-carrying choice: cover
    // the payload field with an uninitialized value so the `ClassInit`'s
    // element count matches the object representation's field count — the
    // same fill the `NameId::ChoicePayload` case in
    // `ConvertStructToStructOrClass` performs for parenless constant
    // alternatives.
    auto payload_ref_id = AddInst<SemIR::ClassElementAccess>(
        context, loc_id,
        {.type_id = choice_info.payload_type_id,
         .base_id = return_slot_id,
         .index = SemIR::ElementIndex(1)});
    auto uninit_id = AddInst<SemIR::UninitializedValue>(
        context, loc_id, {.type_id = choice_info.payload_type_id});
    element_init_ids.push_back(
        AddInst<SemIR::InPlaceInit>(context, loc_id,
                                    {.type_id = choice_info.payload_type_id,
                                     .src_id = uninit_id,
                                     .dest_id = payload_ref_id}));
  }

  auto class_init_id = AddInst<SemIR::ClassInit>(
      context, loc_id,
      {.type_id = choice_info.self_type_id,
       .elements_id = context.inst_blocks().Add(element_init_ids),
       .dest_id = return_slot_id});
  AddReturnInstWithCleanups(
      context, loc_id,
      SemIR::ReturnExpr{.expr_id = class_init_id, .dest_id = return_slot_id});

  FinishFunctionDefinition(context, function_id);
  context.scope_stack().Pop();

  context.name_scopes()
      .Get(choice_info.name_scope_id)
      .AddRequired({.name_id = binding.name_component.name_id,
                    .result = SemIR::ScopeLookupResult::MakeFound(
                        decl_id, SemIR::AccessKind::Public)});
}

auto HandleParseNode(Context& context, Parse::ChoiceDefinitionId node_id)
    -> bool {
  // The last alternative may optionally not have a comma after it, in which
  // case we get here after the last alternative.
  if (!context.node_stack().PeekIs(Parse::NodeKind::ChoiceDefinitionStart)) {
    AddChoiceAlternative(context, node_id);
  } else {
    // A trailing comma (or an empty choice) entered a parameter scope for an
    // alternative that never came; leave it.
    context.scope_stack().Pop();
  }

  auto class_id =
      context.node_stack().Pop<Parse::NodeKind::ChoiceDefinitionStart>();

  int num_alternatives = context.choice_deferred_bindings().size();
  int num_alternative_bits = [&] {
    if (num_alternatives > 1) {
      return static_cast<int>(ceil(log2(num_alternatives)));
    } else {
      return 0;
    }
  }();

  SemIR::TypeId discriminant_type_id = [&] {
    if (num_alternative_bits == 0) {
      // Even though there's no bits needed, we add an empty field. We want to
      // prevent constructing the Choice from an empty struct literal instead of
      // going through an alternative. And in the case there is no alternative,
      // then there's no way to construct the Choice (which can be a useful
      // type).
      //
      // TODO: Find a way to produce a better diagnostic, and not require an
      // empty field.
      return GetTupleType(context, {});
    } else {
      return MakeIntType(context, node_id, SemIR::IntKind::Unsigned,
                         context.ints().Add(num_alternative_bits));
    }
  }();

  const bool is_generic_choice =
      context.classes().Get(class_id).generic_id.has_value();
  auto choice_scope_id = context.classes().Get(class_id).scope_id;

  // Diagnose duplicate alternative names before any alternative is registered
  // in the choice's scope: members are added with `NameScope::AddRequired`,
  // which CHECK-fails on a non-poisoned duplicate. A duplicate alternative is
  // dropped after the diagnostic — neither validated, built, nor registered —
  // so a later reference to the name resolves to the first alternative.
  llvm::SmallVector<bool> is_duplicate_alternative(num_alternatives, false);
  {
    Map<SemIR::NameId, Parse::NodeId> alternative_names;
    for (auto [i, deferred_binding] :
         llvm::enumerate(context.choice_deferred_bindings())) {
      const auto& name_component = deferred_binding.name_component;
      auto result = alternative_names.Insert(name_component.name_id,
                                             name_component.name_loc_id);
      if (!result.is_inserted()) {
        DiagnoseDuplicateName(context, name_component.name_id,
                              SemIR::LocId(name_component.name_loc_id),
                              SemIR::LocId(result.value()));
        is_duplicate_alternative[i] = true;
      }
    }
  }

  // Classify and validate the alternatives, and collect the payload region's
  // fields: one field per payload-carrying alternative, holding that
  // alternative's payload tuple type. Per the F-007k storage contract
  // (docs/design/unions.md, "Relationship to choice types"), all payload
  // tuples overlap at a common offset in storage sized and aligned by the
  // max-of-fields rule.
  llvm::SmallVector<ChoiceAlternativeFunctionInfo> function_alternatives;
  llvm::SmallVector<SemIR::StructTypeField> payload_fields;
  auto payload_size = SemIR::ObjectSize::Zero();
  auto payload_align = SemIR::ObjectSize::Bytes(1);
  for (auto [i, deferred_binding] :
       llvm::enumerate(context.choice_deferred_bindings())) {
    if (is_duplicate_alternative[i]) {
      continue;
    }
    const auto& name_component = deferred_binding.name_component;
    if (!name_component.param_patterns_id.has_value()) {
      // A constant alternative; nothing to validate.
      continue;
    }
    ChoiceAlternativeFunctionInfo info = {.alternative_index =
                                              static_cast<int>(i)};

    // Keep a rejected alternative's name diagnosable: enter an error binding
    // so a later reference reports against a diagnostic already produced, not
    // a phantom missing member (silent-dropout hazard, plan risk R-13).
    auto add_error_binding = [&] {
      context.name_scopes()
          .Get(choice_scope_id)
          .AddRequired({.name_id = name_component.name_id,
                        .result = SemIR::ScopeLookupResult::MakeError()});
      info.error = true;
    };
    auto reject = [&](llvm::StringRef todo) {
      context.TODO(name_component.params_loc_id, todo.str());
      add_error_binding();
    };

    if (is_generic_choice) {
      // Payload synthesis in a generic choice is slice 3: the representation
      // depends on the substituted arguments.
      reject("choice alternative payload with generic or Self-dependent type");
    } else {
      for (auto pattern_id :
           context.inst_blocks().Get(name_component.param_patterns_id)) {
        auto pattern_type_id = context.insts().Get(pattern_id).type_id();
        if (pattern_type_id == SemIR::ErrorInst::TypeId) {
          // The parameter's pattern was already diagnosed.
          add_error_binding();
          break;
        }
        auto param_type_id =
            SemIR::ExtractScrutineeType(context.sem_ir(), pattern_type_id);
        if (context.types().GetConstantId(param_type_id).is_symbolic() ||
            TypeContainsChoice(context, param_type_id, class_id)) {
          reject(
              "choice alternative payload with generic or Self-dependent "
              "type");
          break;
        }
        if (!TryToCompleteType(context, param_type_id,
                               SemIR::LocId(name_component.params_loc_id),
                               /*diagnose=*/true)) {
          // The incomplete-type diagnostic was already produced; don't
          // misclassify incompleteness as non-triviality.
          add_error_binding();
          break;
        }
        if (!IsInSlicePayloadType(context, param_type_id)) {
          reject(
              "choice alternative payload that is not trivially copyable and "
              "destructible");
          break;
        }
        info.param_type_ids.push_back(param_type_id);
      }
    }

    if (!info.error && !info.param_type_ids.empty()) {
      llvm::SmallVector<SemIR::InstId> type_inst_ids;
      for (auto param_type_id : info.param_type_ids) {
        type_inst_ids.push_back(context.types().GetTypeInstId(param_type_id));
      }
      info.payload_tuple_type_id = GetTupleType(context, type_inst_ids);
      CompleteTypeOrCheckFail(context, info.payload_tuple_type_id);
      info.payload_field_index = payload_fields.size();
      payload_fields.push_back({.name_id = name_component.name_id,
                                .type_inst_id = context.types().GetTypeInstId(
                                    info.payload_tuple_type_id)});
      auto layout = context.types()
                        .GetCompleteTypeInfo(info.payload_tuple_type_id)
                        .object_layout;
      payload_size = std::max(payload_size, layout.size);
      payload_align = std::max(payload_align, layout.alignment);
    }
    function_alternatives.push_back(std::move(info));
  }

  llvm::SmallVector<SemIR::StructTypeField, 2> struct_type_fields;
  struct_type_fields.push_back({
      .name_id = SemIR::NameId::ChoiceDiscriminant,
      .type_inst_id = context.types().GetTypeInstId(discriminant_type_id),
  });
  SemIR::TypeId payload_type_id = SemIR::TypeId::None;
  if (!payload_fields.empty()) {
    // Build the payload region: an explicit-layout type with every payload
    // tuple at offset zero, sized/aligned by the max-of-fields rule (F-007k).
    // Payload-free choices don't get here, keeping their representation
    // bit-identical to before.
    llvm::SmallVector<SemIR::ObjectSize> layout;
    static_assert(SemIR::CustomLayoutId::SizeIndex == 0);
    layout.push_back(payload_size.AlignedTo(payload_align));
    static_assert(SemIR::CustomLayoutId::AlignIndex == 1);
    layout.push_back(payload_align);
    static_assert(SemIR::CustomLayoutId::FirstFieldIndex == 2);
    layout.append(payload_fields.size(), SemIR::ObjectSize::Zero());

    auto payload_type_inst_id = AddTypeInst(
        context, node_id,
        SemIR::CustomLayoutType{
            .type_id = SemIR::TypeType::TypeId,
            .fields_id = context.struct_type_fields().Add(payload_fields),
            .layout_id = context.custom_layouts().Add(layout)});
    payload_type_id =
        context.types().GetTypeIdForTypeInstId(payload_type_inst_id);
    struct_type_fields.push_back({
        .name_id = SemIR::NameId::ChoicePayload,
        .type_inst_id = payload_type_inst_id,
    });
  }

  auto fields_id =
      context.struct_type_fields().AddCanonical(struct_type_fields);
  auto choice_witness_id = AddInst(
      context, node_id,
      SemIR::CompleteTypeWitness{
          .type_id = GetSingletonType(context, SemIR::WitnessType::TypeInstId),
          .object_repr_type_inst_id = context.types().GetTypeInstId(
              GetStructType(context, fields_id))});
  auto& class_info = context.classes().Get(class_id);
  class_info.complete_type_witness_id = choice_witness_id;

  // The struct type used to build payload-free alternative constants supplies
  // only the discriminant; when the choice carries a payload region, the
  // conversion to `Self` covers the payload field itself (see the
  // `NameId::ChoicePayload` case in `ConvertStructToStructOrClass`).
  auto self_struct_type_id = GetStructType(
      context, context.struct_type_fields().AddCanonical(
                   llvm::ArrayRef(struct_type_fields).take_front(1)));

  const ChoiceInfo choice_info = {.class_decl_id = class_info.first_decl_id(),
                                  .self_type_id = class_info.self_type_id,
                                  .name_scope_id = class_info.scope_id,
                                  .self_struct_type_id = self_struct_type_id,
                                  .discriminant_type_id = discriminant_type_id,
                                  .payload_type_id = payload_type_id,
                                  .num_alternative_bits = num_alternative_bits};

  const auto* next_function_alternative = function_alternatives.begin();
  for (auto [i, deferred_binding] :
       llvm::enumerate(context.choice_deferred_bindings())) {
    if (is_duplicate_alternative[i]) {
      continue;
    }
    if (!deferred_binding.name_component.param_patterns_id.has_value()) {
      // TODO: This requires the class to be complete, but we've not yet called
      // `FinishGenericDefinition`, so we can't use it as a complete type yet.
      // But this also potentially adds things to the generic definition, so we
      // can't call `FinishGenericDefinition` before this call, either.
      MakeLetBinding(context, choice_info, i, deferred_binding);
      continue;
    }
    CARBON_CHECK(next_function_alternative != function_alternatives.end() &&
                 next_function_alternative->alternative_index ==
                     static_cast<int>(i));
    if (!next_function_alternative->error) {
      BuildAlternativeConstructor(context, choice_info, i,
                                  *next_function_alternative, deferred_binding);
    }
    ++next_function_alternative;
  }

  // The scopes and blocks for the choice itself.
  context.inst_block_stack().Pop();
  context.decl_introducer_state_stack().Pop<Lex::TokenKind::Choice>();
  context.scope_stack().Pop(/*check_unused=*/true);
  context.decl_name_stack().PopScope();

  FinishGenericDefinition(context, class_info.generic_id);

  context.choice_deferred_bindings().clear();
  return true;
}

auto HandleParseNode(Context& context,
                     Parse::ChoiceAlternativeListCommaId node_id) -> bool {
  AddChoiceAlternative(context, node_id);
  // Enter the scope for the next alternative's parameter patterns.
  auto class_id =
      context.node_stack().Peek<Parse::NodeKind::ChoiceDefinitionStart>();
  context.scope_stack().PushForChoiceAlternative(
      context.classes().Get(class_id).first_decl_id());
  return true;
}

}  // namespace Carbon::Check
