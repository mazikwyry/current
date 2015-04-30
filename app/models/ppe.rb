class Ppe < ActiveRecord::Base

	has_many :hourly_current_usages
	has_many :area_current_usages

	def usages
		usage_type == 'hourly' ? hourly_current_usages : area_current_usages
	end

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

	def self.new_ppes content
		usages = JSON.parse(content)
		new_ppes = []
		usages.each do |u|
			new_ppes << u['ppe'] unless Ppe.exists?(code: u['ppe'])
		end
		new_ppes.present? ? new_ppes : false
	end

end
