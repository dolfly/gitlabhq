# frozen_string_literal: true

class AddMemberRoleFkToProtectedBranchMergeAccessLevels < Gitlab::Database::Migration[2.3]
  milestone '19.0'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :protected_branch_merge_access_levels, :member_roles,
      column: :member_role_id, on_delete: :restrict
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :protected_branch_merge_access_levels, column: :member_role_id
    end
  end
end
