class AddDisplayAlertToBranches < ActiveRecord::Migration[5.0]
  def change
    add_column :branches, :displayAlert, :boolean
  end
end
