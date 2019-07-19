# frozen_string_literal: true

class Api::V1::RegisterServiceDeliveryPointsController < ApplicationController
  def index
    render json: RegisterServiceDeliveryPoint.all
  end
end
