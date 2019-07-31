# frozen_string_literal: true

class Api::V1::ValidationsController < ApplicationController
  def validate_username
    username = params.require(:username)
    is_validated = validator.validate_username(username)

    render json: { validated: is_validated }
  end

  private

  def validator
    program_id = params.require(:program_id)
    ValidationsService.validator(program_id)
  end
end
