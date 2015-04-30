class String
  def is_json?
    begin
      !!JSON.parse(self)
    rescue
      false
    end
  end
end

class PpesController < ApplicationController

	def index
		@ppes = Ppe.all
	end

	def upload_usage
		redirect_to :back unless params[:file]
		content = params[:file].read
		redirect_to :back unless content.is_json?
		if @new_ppes = Ppe.new_ppes(content)
			File.open(Rails.root.join('tmp', 'tmp.json'), "wb") { |f| f.write(content) }
			render 'confirm'
		else
			Ppe.parse_usages(content)
			redirect_to ppes_path
		end
	end

	def confirm_new_ppes
		file = File.open(Rails.root.join('tmp', 'tmp.json'), 'r')
		Ppe.parse_usages(file.read)
		file.close
		File.delete(Rails.root.join('tmp', 'tmp.json'))
		redirect_to ppes_path
	end

end