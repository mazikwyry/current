class HourlyCurrentUsage < ActiveRecord::Base

	belongs_to :ppe

	# Constants
  HOURLY_USAGE_JSON_SCHEMA = Rails.root.join('config', 'schemas', 'hourly_usage.json_schema').to_s

	validates :ppe_id, :date, presence: true
	validates :hourly_usage, presence: true, json: { schema: HOURLY_USAGE_JSON_SCHEMA }

	def self.create usage
		ppe = Ppe.find_or_create_by(code: usage['ppe'], type: reading['type'])
		hourly = find_or_initialize_by(ppe_id: ppe.id, date: usage['date'])
		hourly.hourly_usage = usage['hourlyUsage']
		hourly.save
		hourly
	end

end
