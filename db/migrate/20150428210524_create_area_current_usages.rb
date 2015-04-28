class CreateAreaCurrentUsages < ActiveRecord::Migration
  def change
    create_table :area_current_usages do |t|
      t.integer :ppe_id
      t.date :date
      t.decimal :usage
      t.string :state
      t.integer :multiplicand
      t.integer :area

      t.timestamps null: false
    end
  end
end
