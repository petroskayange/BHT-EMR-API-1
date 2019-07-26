# frozen_string_literal: true

# /codes/:program_id/:code_type
#
# Provides a generic API for generating various codes required
# in different programs (eg ARV number in ART)
class Api::V1::CodesController < ApplicationController
  # GET /codes/:program_id/:code_type
  def index
    code_type = params.require(:code_type)

    args = request.query_parameters.to_hash.transform_keys(&:to_sym)
    render json: { code_type => code_generator.generate(code_type, args) }
  end

  private

  def code_generator
    program_id = params.require(:program_id)
    CodeGeneratorService.find_generator(program_id)
  end
end
