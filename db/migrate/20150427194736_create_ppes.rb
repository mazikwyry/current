class CreatePpes < ActiveRecord::Migration
  def change
    create_table :ppes do |t|
      t.string :code
      t.string :type

      t.timestamps null: false
    end
  end
end
