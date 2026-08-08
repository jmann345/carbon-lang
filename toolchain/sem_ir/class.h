// Part of the Carbon Language project, under the Apache License v2.0 with LLVM
// Exceptions. See /LICENSE for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef CARBON_TOOLCHAIN_SEM_IR_CLASS_H_
#define CARBON_TOOLCHAIN_SEM_IR_CLASS_H_

#include <optional>

#include "common/map.h"
#include "llvm/ADT/SmallVector.h"
#include "toolchain/base/value_store.h"
#include "toolchain/sem_ir/entity_with_params_base.h"
#include "toolchain/sem_ir/ids.h"
#include "toolchain/sem_ir/inst.h"
#include "toolchain/sem_ir/struct_type_field.h"

namespace clang {
class TagDecl;
}

namespace Carbon::SemIR {

class File;
class NameScope;

// Name-to-index metadata for one alternative of a `choice`, tracked on the
// choice's `Class`. Resolving an alternative pattern needs the alternative's
// discriminant value and payload location by name, and neither is
// recoverable from the object representation: constant alternatives do not
// appear in it at all, and the discriminant values they were assigned are
// otherwise baked only into constants. Populated at the `}` of the choice
// definition, in declaration order; imported with the class (names
// translated to the local file's `NameId`s).
struct ChoiceAlternative : public Printable<ChoiceAlternative> {
  auto Print(llvm::raw_ostream& out) const -> void {
    out << "{name_id: " << name_id << ", index: " << index
        << ", payload_field_index: " << payload_field_index
        << ", has_parameters: " << has_parameters << "}";
  }

  // The alternative's name.
  NameId name_id;
  // The alternative's discriminant value: its position in the choice's
  // declaration order (counting alternatives dropped as duplicates, which
  // get no entry of their own).
  int32_t index;
  // The index of the alternative's payload tuple field within the payload
  // region (`CustomLayoutType`), or -1 if the alternative stores no payload.
  int32_t payload_field_index = -1;
  // Whether the alternative declares a parameter list, including an empty
  // one. Alternative patterns take parentheses exactly when this is true
  // (proposal p2188's parens-iff-parameter-list rule).
  bool has_parameters = false;
};

// Class-specific fields.
struct ClassFields {
  enum InheritanceKind : int8_t {
    // `abstract class`
    Abstract,
    // `base class`
    Base,
    // `class`
    Final,
  };

  // The following members always have values, and do not change throughout the
  // lifetime of the class.

  // The class type, which is the type of `Self` in the class definition.
  TypeId self_type_id;
  // The kind of inheritance that this class supports.
  // TODO: The rules here are not yet decided. See #3384.
  InheritanceKind inheritance_kind;

  // Whether this class or any base class has at least one virtual function.
  bool is_dynamic = false;

  // Whether this class was declared as a `choice`. Choice alternatives are
  // entries in the class scope, and the object representation carries a
  // compiler-defined discriminant field (and, when any alternative has a
  // payload, a payload field). This is entity-level truth, not inferred from
  // the representation's field names.
  bool is_choice = false;

  // For a `choice`, its alternatives' name-to-index metadata in declaration
  // order; set when the definition completes. Empty for non-choice classes.
  llvm::SmallVector<ChoiceAlternative, 0> choice_alternatives = {};

  // The following members are set at the `{` of the class definition.

  // The class scope.
  NameScopeId scope_id = NameScopeId::None;
  // The first block of the class body.
  // TODO: Handle control flow in the class body, such as if-expressions.
  InstBlockId body_block_id = InstBlockId::None;

  // The following members are accumulated throughout the class definition.

  // The adapted type declaration, if any. `None` if the class is not an
  // adapter. This is an AdaptDecl instruction.
  // TODO: Consider sharing the storage for `adapt_id` and `base_id`. A class
  // can't have both.
  InstId adapt_id = InstId::None;
  // The base class declaration. `None` if the class has no base class. This is
  // a BaseDecl instruction.
  InstId base_id = InstId::None;

  // The following members are set at the `}` of the class definition.

  // A `CompleteTypeWitness` instruction witnessing that this class type is
  // complete, and tracking its object representation. This has a value once the
  // class is defined. For an adapter, the object representation is the
  // non-adapter type that this class directly or transitively adapts.
  InstId complete_type_witness_id = InstId::None;

  // The virtual function table. `None` if the class has no (direct or
  // inherited) virtual functions.
  InstId vtable_decl_id = InstId::None;

  auto PrintClassFields(llvm::raw_ostream& out) const -> void {
    out << "self_type_id: " << self_type_id << ", inheritance_kind: ";
    switch (inheritance_kind) {
      case Abstract:
        out << "Abstract";
        break;
      case Base:
        out << "Base";
        break;
      case Final:
        out << "Final";
        break;
    }
    out << ", is_dynamic: " << is_dynamic << ", scope_id: " << scope_id
        << ", body_block_id: " << body_block_id << ", adapt_id: " << adapt_id
        << ", base_id: " << base_id
        << ", complete_type_witness_id: " << complete_type_witness_id
        << ", vtable_decl_id: " << vtable_decl_id << "}";
  }
};

// A class. See EntityWithParamsBase regarding the inheritance here.
struct Class : public EntityWithParamsBase,
               public ClassFields,
               public Printable<Class> {
  auto Print(llvm::raw_ostream& out) const -> void {
    out << "{";
    PrintBaseFields(out);
    out << ", ";
    PrintClassFields(out);
    out << "}";
  }

  // This is false until we reach the `}` of the class definition.
  auto is_complete() const -> bool {
    return complete_type_witness_id.has_value();
  }

  // When merging a declaration and definition, prefer things which would point
  // at the definition for diagnostics.
  auto MergeDefinition(const Class& definition) -> void {
    EntityWithParamsBase::MergeBaseDefinition(definition);
    scope_id = definition.scope_id;
    body_block_id = definition.body_block_id;
    adapt_id = definition.adapt_id;
    base_id = definition.base_id;
    complete_type_witness_id = definition.complete_type_witness_id;
    choice_alternatives = definition.choice_alternatives;
  }

  // Gets the type that this class type adapts. Returns `None` if there is no
  // such type, or if the class is not yet defined.
  auto GetAdaptedType(const File& file, SpecificId specific_id) const -> TypeId;

  // Gets the base class for this class type. Returns `None` if there is no
  // such type, or if the class is not yet defined.
  auto GetBaseType(const File& file, SpecificId specific_id) const -> TypeId;

  // Gets the object representation for this class. Returns `None` if the class
  // is not yet defined.
  auto GetObjectRepr(const File& file, SpecificId specific_id) const -> TypeId;

  // Get the `StructTypeField`s from a class's object repr.
  auto GetStructTypeFields(const File& sem_ir, SpecificId specific_id) const
      -> llvm::ArrayRef<SemIR::StructTypeField>;
};

using ClassStore = ValueStore<ClassId, Class, Tag<CheckIRId>>;

// If this declaration declares a class type that is "owned" by Carbon, and not
// imported from C++, returns the corresponding type ID and `ClassType`.
// Otherwise returns `nullopt`.
auto GetAsCarbonOwnedClass(const File& sem_ir, const clang::TagDecl* tag_decl)
    -> std::optional<std::pair<SemIR::TypeId, SemIR::ClassType>>;

auto LookupClassFieldByStructField(const File& sem_ir,
                                   const NameScope& class_scope,
                                   const StructTypeField& struct_field)
    -> std::optional<InstStore::GetAsWithIdResult<SemIR::FieldDecl>>;

}  // namespace Carbon::SemIR

namespace Carbon {
extern template class ValueStore<SemIR::ClassId, SemIR::Class,
                                 Tag<SemIR::CheckIRId>>;
}  // namespace Carbon

#endif  // CARBON_TOOLCHAIN_SEM_IR_CLASS_H_
