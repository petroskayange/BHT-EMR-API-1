# frozen_string_literal: true

# /codes/:program_id/:code_type
#
# Provides a generic API for generating various codes required
# in different programs (eg ARV number in ART)
class Api::V1::CodesController < ApplicationController
  # GET /codes/:program_id/:code_type
  def create
    code_type = params[:code_type]

    args = params.require(:code).permit!
    args = args.to_hash.transform_keys(&:to_sym)

    render json: { code_type => code_generator.generate(code_type, args) }
  end

  private

  def code_generator
    program_id = params.require(:program_id)
    CodeGeneratorService.find_generator(program_id)
  end
end
