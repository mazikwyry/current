class AddAreasToPpe < ActiveRecord::Migration
  def change
    add_column :ppes, :area, :text, array:true, default: [1]
  end
end
