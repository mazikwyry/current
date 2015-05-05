class CreateHourlyCurrentUsages < ActiveRecord::Migration
  def change
    create_table :hourly_current_usages do |t|
    	t.integer :ppe_id
    	t.date :date
    	t.json :hourly_usage
    	t.decimal :daily_usage
    	t.string :daily_state
      t.timestamps null: false
    end
  end
end
