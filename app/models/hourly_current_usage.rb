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
			sum += usage['usage'].to_d
			bad_states << usage['state'] unless usage['state'] == '+' 
		end
		self.daily_usage = sum
		self.daily_state = (bad_states.present? && bad_states.uniq.join(',')) || '+'
		self.save
	end

	def change_hour_state hour, state
		hourly_usage[hour]['state'] = state
		sum_daily_usage
	end

	def change_daily_state state
		hourly_usage.each do |hour, usage|
			usage['state'] = state
		end
		sum_daily_usage
	end

	def self.create_from_range range
		return false if range['date_start'] >= range['date_end'] || !(['G','C'].include?(range['usage_type']))
		
		date_range = (Date.parse(range['date_start'])..Date.parse(range['date_end']))
		usage_per_hour = range['usage_type'] == 'G' ? range['usage'] : range['usage'].to_d/date_range.count/24
		date_range.each do |date|
			usage = {
				'type' => 'hourly',
				'ppe' => range['ppe'],
				'date' => date,
				'hourlyUsage' => {}
			}
			(0..24).each do |h|
				usage['hourlyUsage'][h.to_s] = {
					'usage' => h < 24 ? usage_per_hour.to_f : 0,
					'state' => range['state']
				}
			end
			create(usage)
		end
	end

end
