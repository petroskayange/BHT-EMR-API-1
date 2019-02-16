# frozen_string_literal: true

module MaternityService
  # Patients sub service.
  #
  # Basically provides Maternity specific patient-centric functionality
  class PatientsEngine
    include ModelUtils

    def initialize(program:)
      @program = program
    end

    # Retrieves given patient's status info.

    def patient(patient_id, date)
      patient_summary(Patient.find(patient_id), date).full_summary
    end

    def all_patients(paginator: nil)
      # TODO: Retrieve all patients
      []
    end

    private

    NPID_TYPE = 'National id'

    include ModelUtils

    def patient_identifier(patient, identifier_type_name)
      identifier_type = PatientIdentifierType.find_by_name(identifier_type_name)
      return 'UNKNOWN' unless identifier_type

      identifiers = patient.patient_identifiers.where(
          identifier_type: identifier_type.patient_identifier_type_id
      )
      identifiers[0] ? identifiers[0].identifier : 'N/A'
    end

    def patient_residence(patient)
      address = patient.person.addresses[0]
      return 'N/A' unless address

      district = address.state_province || 'Unknown District'
      village = address.city_village || 'Unknown Village'
      "#{district}, #{village}"
    end

    def patient_summary(patient, date)
      PatientSummary.new patient, date
    end

  end
end
