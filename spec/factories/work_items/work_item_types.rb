# frozen_string_literal: true

FactoryBot.define do
  # DEPRECATED: This factory creates DB-backed WorkItems::Type records.
  # It is only needed for tests that exercise the BaseTypeImporter or
  # the work_item_types DB table directly.
  #
  # For all other tests, use :work_item_system_defined_type instead.
  factory :work_item_type, class: 'WorkItems::Type' do
    name { ::WorkItems::Type::BASE_TYPES[:issue][:name] }
    base_type { ::WorkItems::Type::BASE_TYPES[:issue][:enum_value] }
    icon_name { ::WorkItems::Type::BASE_TYPES[:issue][:icon_name] }

    transient do
      default { true }
    end

    initialize_with do
      next WorkItems::Type.new(attributes) unless default

      type_base_attributes = attributes.with_indifferent_access.slice(:base_type, :name)

      WorkItems::Type.find_or_initialize_by(type_base_attributes)
    end

    trait :non_default do
      default { false }
      sequence(:id, 100) { |n| n }
      icon_name { 'work-item-non-default' }
      sequence(:name) { |n| "Work item type #{n}" }
    end

    ::WorkItems::Type::BASE_TYPES.each do |type_name, attributes|
      trait type_name do
        base_type { attributes[:enum_value] }
        name { attributes[:name] }
      end
    end
  end
end
