class CreateFeeSplits < ActiveRecord::Migration[5.2]
  def change
    create_table :fee_splits do |t|
      t.integer :referrer_id, null: false, index: true, foreign_key: true
      t.integer :parent_id, null: false, index: true

      t.decimal :percentage, null: false, precision: 4, scale: 2, unsigned: true

      t.integer :state, null: false, limit: 1, unsigned: true, default: 0
      t.timestamps
    end
  end
end
