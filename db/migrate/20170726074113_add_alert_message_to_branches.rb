class AddAlertMessageToBranches < ActiveRecord::Migration[5.0]
  def change
    add_column :branches, :alertMessage, :string
  end
end
