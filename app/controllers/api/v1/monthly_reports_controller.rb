class Api::V1::MonthlyReportsController < ApplicationController
	def index
		stats =  service.monthly_report

		if stats
			render json: stats
		else
			render status: :no_content
		end
	end

	private

		def service
			return @service if @service

			program_id, date  = params.require %i[program_id date]

			@service = ReportService.new program_id: program_id,
																	 date: date
			@service
		end
end
