# frozen_string_literal: true

class Api::V1::ProgramReportsController < ApplicationController
  include ModelUtils

  def show
    type, start_date, end_date = parse_report_name(params[:name])

    type ||= params[:id]
    start_date = start_date&.to_date || params.require(:start_date).to_date
    end_date = end_date&.to_date || Date.today

    extra_params = {}
    params.permit!.each do |key, value|
      # Keep only the extra arguments passed by the client
      next if %w[type name start_date end_date action controller program_id id].include?(key)

      extra_params[key.to_sym] = value
    end

    report = service.generate_report(name: name, type: type, start_date: start_date.to_date,
                                     end_date: end_date.to_date, **extra_params)

    if report
      render json: report
    else
      render status: :no_content
    end
  end

  private

  def service
    ReportService.new(program_id: params[:program_id],
                      overwrite_mode: params[:regenerate]&.upcase == 'TRUE')
  end

  def parse_report_name(name)
    return [nil, nil, nil] unless name

    match = name.match(/(?<type>\w+\s+)?Q(?<quarter>[1234])\s+(?<year>\d{4})/)
    return [nil, nil, nil] unless match

    start_date = quarter_to_date(match[:quarter], match[:year])
    end_date = quarter_to_date(match[:quarter].to_i + 1, match[:year]) - 1.days

    [match[:type], start_date, end_date]
  end

  def quarter_to_date(index, year)
    index = index.to_i
    year = year.to_i
    sdate = [
      nil, "#{year}-01-01", "#{year}-04-01", "#{year}-07-01", "#{year}-10-01",
      "#{year + 1}-01-01"
    ][index]

    sdate.to_date
  end
end
