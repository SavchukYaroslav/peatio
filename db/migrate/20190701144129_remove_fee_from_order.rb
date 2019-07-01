class RemoveFeeFromOrder < ActiveRecord::Migration[5.2]
  def change
    remove_column :orders, :fee if column_exists?(:orders, :fee)
  end
end
