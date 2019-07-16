# frozen_string_literal: true

class Api::V1::EncounterRegistersController < ApplicationController
  def show
    render json: service.find_encounter_register(params[:encounter_id])
  end

  def create
    encounter = Encounter.find(params[:encounter_id])
    register = Register.find(params.require(:register_id))

    binding = service.bind_encounter_to_register(encounter, register)

    if binding.errors.empty?
      render json: register, status: :created
    else
      render json: binding.errors, status: :unprocessable_entity
    end
  end

  def destroy
    encounter = Encounter.find(params[:encounter_id])
    service.unbind_encounter_from_register(encounter)
    render status: :no_content
  end

  private

  def service
    EncounterService.new
  end
end
