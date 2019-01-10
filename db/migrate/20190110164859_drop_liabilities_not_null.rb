class DropLiabilitiesNotNull < ActiveRecord::Migration
  def change
    change_column_null(:liabilities, :member_id, true)
  end
end
