class CreateFees < ActiveRecord::Migration
  def change
    create_table :fees do |t|
      t.integer :parent_id
      t.string  :parent_type
      t.integer :source_account_id
      t.integer :target_account_id
      t.decimal :amount,           precision: 32, scale: 16, default: 0.0, null: false
      t.timestamps null: false
    end

    add_index :fees, [:parent_type, :parent_id]
  end
end
