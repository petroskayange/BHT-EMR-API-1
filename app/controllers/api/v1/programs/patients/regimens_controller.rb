# frozen_string_literal: true

class Api::V1::Programs::Patients::RegimensController < ApplicationController
  def index
    permitted = params.permit(:program_patient_id, :date)

    patient = Patient.find(permitted[:program_patient_id])
    date = permitted[:date]&.to_date

    note = service.patient_prescription_note(patient, on: date)

    raise NotFoundError, "Patient ##{patient.id} has no prescription on #{date}" unless note

    render json: note
  end

  private

  def service
    ProgramEngineLoader.load(program, 'prescription')
  end

  def program
    program_id = params.permit(:program_id)[:program_id]

    Program.find(program_id)
  end
end
