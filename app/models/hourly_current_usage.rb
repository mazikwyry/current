class HourlyCurrentUsage < ActiveRecord::Base

	belongs_to :ppe

	# Constants
  HOURLY_USAGE_JSON_SCHEMA = Rails.root.join('config', 'schemas', 'hourly_usage.json_schema').to_s

	validates :ppe_id, :date, presence: true
	validates :hourly_usage, presence: true, json: { schema: HOURLY_USAGE_JSON_SCHEMA }

	def self.create usage
		ppe = Ppe.find_or_create_by(code: usage['ppe'], usage_type: usage['type'])
		hourly = find_or_initialize_by(ppe_id: ppe.id, date: usage['date'])
		hourly.hourly_usage = usage['hourlyUsage']
		hourly.save
		hourly.sum_daily_usage
		hourly
	end

	def sum_daily_usage
		sum = 0
		bad_states = []
		hourly_usage.each do |hour, usage|
			sum += usage['usage']
			bad_states << usage['state'] unless usage['state'] == '+' 
		end
		self.daily_usage = sum
		self.daily_state = (bad_states.present? && bad_states.uniq.join(',')) || '+'
		self.save
	end

end
