# frozen_string_literal: true

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
end
