# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/patients', type: :request do
  describe 'GET /patients' do
    let(:person) { create(:person) }
    let(:program) { create(:program) }
    let(:service) { PatientService.new }

    it 'returns all patients in the database' do
      patient = service.create_patient(program, person)

      get api_route('patients')

      expect(response).to have_http_status(:ok)

      parse_response(response) do |json|
        expect(json.size).to eq(1)
        expect(json.first['patient_id']).to eq(patient.id)
      end
    end
  end

  describe 'GET /patients/:patient_id' do
    let(:person) { create(:person) }
    let(:program) { create(:program) }
    let(:service) { PatientService.new }
    let(:national_identifier_type) { PatientIdentifierType.find_by!(name: 'National ID') }

    it 'returns an existing patient by id' do
      patient = service.create_patient(program, person)

      get api_route("patients/#{patient.patient_id}")

      expect(response).to have_http_status(:ok)

      parse_response(response) do |json|
        expect(json['patient_id']).to eq(patient.patient_id)

        identifiers = json['patient_identifiers'].each_with_object([]) do |identifier, array|
          next unless identifier['identifier_type'] == national_identifier_type.id

          array << identifier['identifier']
        end

        expect(identifiers.size).to eq(1)
        expect(identifiers.first).not_to be_nil
      end
    end

    it 'raises 404 for non-existent patients' do
      patient = service.create_patient(program, person)
      patient.void("I don't like this guy")

      get api_route("patients/#{patient.patient_id}")

      expect(response).to have_http_status(404)
    end
  end
end
