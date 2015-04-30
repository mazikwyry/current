class AreaCurrentUsage < ActiveRecord::Base

	belongs_to :ppe
	validates :ppe_id, :date, :usage, :state, :multiplicand, presence: true


	def self.create reading
		ppe = Ppe.find_or_create_by(code: reading['ppe'], usage_type: reading['type'])
		usage = find_or_initialize_by(ppe_id: ppe.id, date: reading['date'], area: reading['area'])
		usage.assign_attributes(usage: reading['usage'], state: reading['state'], multiplicand: reading['multiplicand'])
		usage.save
		usage
	end

end
