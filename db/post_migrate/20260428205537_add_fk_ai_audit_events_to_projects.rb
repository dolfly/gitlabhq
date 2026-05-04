# frozen_string_literal: true

class AddFkAiAuditEventsToProjects < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '19.0'
  disable_ddl_transaction!

  def up
    add_concurrent_partitioned_foreign_key(
      :ai_audit_events,
      :projects,
      column: :project_id,
      on_delete: :cascade,
      reverse_lock_order: true
    )
  end

  def down
    remove_partitioned_foreign_key :ai_audit_events, column: :project_id, reverse_lock_order: true
  end
end
