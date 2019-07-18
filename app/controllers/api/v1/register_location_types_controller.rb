# frozen_string_literal: true

class Api::V1::RegisterLocationTypesController < ApplicationRecord
  def index
    render json: RegisterLocationType.all
  end
end
