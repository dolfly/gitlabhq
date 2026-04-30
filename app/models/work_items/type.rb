# frozen_string_literal: true

# DEPRECATED: This ActiveRecord model is retained only for:
# 1. Database seeding via Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter
# 2. GraphQL GlobalID constant resolution (GlobalIDType[::WorkItems::Type])
#
# All type logic now lives in WorkItems::TypesFramework::SystemDefined::Type.
# Use WorkItems::TypesFramework::Provider for type lookups.
#
# TODO: Remove once the work_item_types DB table is dropped and GID
# resolution is migrated. See https://gitlab.com/gitlab-org/gitlab/-/work_items/581931
module WorkItems
  class Type < ApplicationRecord
    self.table_name = 'work_item_types'

    TYPE_NAMES = {
      issue: 'Issue',
      incident: 'Incident',
      test_case: 'Test Case',
      requirement: 'Requirement',
      task: 'Task',
      objective: 'Objective',
      key_result: 'Key Result',
      epic: 'Epic',
      ticket: 'Ticket'
    }.freeze

    # Used by Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter to seed the DB
    BASE_TYPES = {
      issue: { name: TYPE_NAMES[:issue], icon_name: 'work-item-issue', enum_value: 0, id: 1 },
      incident: { name: TYPE_NAMES[:incident], icon_name: 'work-item-incident', enum_value: 1, id: 2 },
      test_case: { name: TYPE_NAMES[:test_case], icon_name: 'work-item-test-case', enum_value: 2, id: 3 },
      requirement: { name: TYPE_NAMES[:requirement], icon_name: 'work-item-requirement', enum_value: 3, id: 4 },
      task: { name: TYPE_NAMES[:task], icon_name: 'work-item-task', enum_value: 4, id: 5 },
      objective: { name: TYPE_NAMES[:objective], icon_name: 'work-item-objective', enum_value: 5, id: 6 },
      key_result: { name: TYPE_NAMES[:key_result], icon_name: 'work-item-keyresult', enum_value: 6, id: 7 },
      epic: { name: TYPE_NAMES[:epic], icon_name: 'work-item-epic', enum_value: 7, id: 8 },
      ticket: { name: TYPE_NAMES[:ticket], icon_name: 'work-item-ticket', enum_value: 8, id: 9 }
    }.freeze

    ignore_column :correct_id, remove_with: '18.1', remove_after: '2025-05-15'

    enum :base_type, BASE_TYPES.transform_values { |value| value[:enum_value] }
  end
end
