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
			redirect_to ppes_path, notice: 'Odczyty zostały załadowane poprawnie.'
		end
	end

	def confirm_new_ppes
		file = File.open(Rails.root.join('tmp', 'tmp.json'), 'r')
		Ppe.parse_usages(file.read)
		file.close
		File.delete(Rails.root.join('tmp', 'tmp.json'))
		redirect_to ppes_path, notice: 'Odczyty zostały załadowane poprawnie.'
	end

	def usage
		@ppe = Ppe.find(usage_params[:id])
		redirect_to ppes_path, alert: "Wprowadź wszytkie potrzebne atrybuty dla raportu" and return unless @ppe && usage_params[:start_date] && usage_params[:end_date]
		@usages = @ppe.get_usage(usage_params[:start_date], usage_params[:end_date])
		# binding.pry
		redirect_to ppes_path, alert: @usages[:errors].to_s and return if @usages[:errors].present?
	end

	def usages_csv
		@ppe = Ppe.find(params[:id])
		redirect_to ppes_path, alert: "Nie znaleziono podanego PPE" and return unless @ppe && params[:start_date] && params[:end_date]
		csv = Ppe.generate_csv([@ppe], params[:start_date], params[:end_date])
    respond_to do |format|
      format.csv { send_data csv, filename: "zuzycie_#{@ppe.code}_#{Date.today.to_s}.csv" }
    end
	end

	def usages_csv_all
		@ppes = Ppe.all
		redirect_to ppes_path, alert: "Wprowadź wszytkie potrzebne atrybuty dla raportu" and return unless usage_params[:start_date] && usage_params[:end_date]
		redirect_to ppes_path, alert: "Data początkowa powinna być wcześniejsza niż końcowa" and return if usage_params[:start_date] >= usage_params[:end_date]
		csv = Ppe.generate_csv(@ppes, usage_params[:start_date], usage_params[:end_date])
    respond_to do |format|
      format.csv { send_data csv, filename: "zuzycie_wszystkie_ppe_#{Date.today.to_s}.csv" }
    end
	end

	def change_hour_state
		@usage = HourlyCurrentUsage.find(params[:usage_id])
		render 'ajax_error' and return unless @usage
		@usage.change_hour_state(params[:hour], params[:state])
	end

	def change_daily_state
		@usage = HourlyCurrentUsage.find(params[:usage_id])
		render 'ajax_error' and return unless @usage
		@usage.change_daily_state(params[:state])
	end

  def destroy
    @usage = Ppe.find(usage_params[:id])
    @usage.destroy

    respond_to do |format|
      format.html { redirect_to root_path, notice: "Usunięto PPE #{@usage.code} wraz z danymi." }
      format.json { head :ok }
    end
  end


	private

	def usage_params
    params.require(:ppe).permit(:id, :start_date, :end_date)
  end

end