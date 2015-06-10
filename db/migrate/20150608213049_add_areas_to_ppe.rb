class AddAreasToPpe < ActiveRecord::Migration
  def change
    add_column :ppes, :areas, :text, array:true, default: [1]
    Ppe.reset_column_information
    Ppe.where(usage_type: 'area').each{|p| p.check_areas}
  end
end
