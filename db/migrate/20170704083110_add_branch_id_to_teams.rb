class AddBranchIdToTeams < ActiveRecord::Migration[5.0]
  def change
    add_column :teams, :branch_id, :integer
  end
end
