# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/patients', type: :request do
  let(:service) { PatientService.new }
  let(:national_identifier_type) { PatientIdentifierType.find_by!(name: 'National ID') }
  let(:person) { create(:person) }
  let(:program) { create(:program) }

  describe 'GET /patients' do
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
    it 'returns an existing patient by id' do
      patient = service.create_patient(program, person)

      get api_route("patients/#{patient.patient_id}")

      expect(response).to have_http_status(:ok)

      parse_response(response) do |json|
        expect(json['patient_id']).to eq(patient.patient_id)

        identifiers = json['patient_identifiers'].each_with_object([]) do |identifier, array|
          unless identifier['identifier_type'] == national_identifier_type.id
            next
          end

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

  describe 'POST /patients' do
    it 'requires program_id' do
      post api_route('patients'), params: { 'person_id' => person.person_id }

      expect(response).to have_http_status(:bad_request)
    end

    it 'requires person_id' do
      post api_route('patients'), params: { 'program_id' => program.program_id }

      expect(response).to have_http_status(:bad_request)
    end

    it 'requires person_id to exist' do
      post api_route('patients'), params: {
        'program_id' => program.program_id,
        'person_id' => 'non-existent-id'
      }

      expect(response).to have_http_status(:not_found)
    end

    it 'requires program_id to exist' do
      post api_route('patients'), params: {
        'program_id' => 'non-existent-id',
        'person_id' => person.person_id
      }

      expect(response).to have_http_status(:not_found)
    end

    let(:national_identifier_type) { PatientIdentifierType.find_by_name!('National id') }

    it 'registers a new patient' do
      post api_route('patients'), params: {
        'program_id' => program.program_id,
        'person_id' => person.person_id
      }

      expect(response).to have_http_status(:created)

      parse_response(response) do |json|
        national_ids = json['patient_identifiers'].select do |identifier|
          identifier['identifier_type'] == national_identifier_type.id
        end

        expect(national_ids.size).to eq 1
        expect(national_ids.first['identifier']).not_to be_blank
      end
    end

    it 'does not allow duplicate patient creation' do
      service.create_patient(program, person)

      post api_route('patients'), params: {
        'program_id' => program.program_id,
        'person_id' => person.person_id
      }

      expect(response).to have_http_status(:bad_request)
    end
  end
end
