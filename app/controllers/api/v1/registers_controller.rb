# frozen_string_literal: true

class Api::V1::RegistersController < ApplicationController
  before_action :set_register, only: %i[show update destroy]

  # GET /registers
  def index
    @registers = Register.unscoped.all

    render json: paginate(@registers)
  end

  # GET /registers/1
  def show
    render json: @register
  end

  # POST /registers
  def create
    permitted_params = register_params
    permitted_params[:location_id] ||= Location.current.id

    @register = Register.create(permitted_params)

    if @register.errors.empty?
      render json: @register, status: :created
    else
      render json: @register.errors, status: :bad_request
    end
  end

  # PATCH/PUT /registers/1
  def update
    if @register.update(register_params)
      render json: @register
    else
      render json: @register.errors, status: :bad_request
    end
  end

  # DELETE /registers/1
  def destroy
    reason = params[:reason] || "Voided by #{User.current.username}"
    if @register.void(reason)
      render status: :no_content
    else
      render json: { errors: ['Could not void register', @register.errors] },
             status: :bad_request
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_register
    @register = Register.unscoped.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def register_params
    params.require(:register)
          .permit(:uuid, :number, :location_type_id, :service_delivery_point_id,
                  :location_id, :register_type, :closed, :date_closed, :closed_by,
                  :close_reason, :date_created)
  end
end
