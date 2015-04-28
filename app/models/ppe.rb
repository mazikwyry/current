class Ppe < ActiveRecord::Base

	def self.parse_usages json
		usages = JSON.parse(json)
		bad_types = []
		usages.each do |usage|
			case usage['type']
			when 'hourly'
				HourlyCurrentUsage.create(usage)
			when 'area'
				AreaCurrentUsage.create(usage)
			else
				bad_types << usage
			end
		end
	end

end
