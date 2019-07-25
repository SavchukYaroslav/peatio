class CreateJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :jobs do |t|
      t.integer :rows,                   null: false, default: 0
      t.string  :name, limit: 255
      t.string  :state, limit: 30,       null: false, default: 'created'

      t.timestamps
    end
  end
end
