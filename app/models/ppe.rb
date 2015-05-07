class Ppe < ActiveRecord::Base


	attr_accessor :start_date, :end_date

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

	def get_usage start_date, end_date
		case usage_type
		when 'hourly'
			range_usages = self.usages.where("date >= :start_date AND date <= :end_date", :start_date => start_date, :end_date => end_date)
			sum = range_usages.sum(:daily_usage)
			states = range_usages.map{|u| u.daily_state}.join(',').split(',').uniq.join(',')
			return {usages: range_usages, sum: sum, states: states, start_date: start_date, end_date: end_date}
		when 'area'
			
		end
	end

end
