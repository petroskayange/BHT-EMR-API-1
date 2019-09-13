# frozen_string_literal: true

class Api::V1::SessionStatsController < ApplicationController
  def show
    render json: service.visits
  end

  private

  def service
    permitted_params = params.permit %i[date user_id program_id]

    date = permitted_params[:date]&.to_date || Date.today
    user = permitted_params[:user_id] ? User.find(permitted_params[:user_id]) : User.current
    program = permitted_params[:program_id] ? Program.find(permitted_params[:program_id]) : nil

    SessionStatsService.new(user, date, program: program)
  end
end
