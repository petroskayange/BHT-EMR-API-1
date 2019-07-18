# frozen_string_literal: true

class Api::V1::RegisterServiceDeliveryPointsController < ApplicationController
  def index
    render json: RegisterLocationType.all
  end
end
