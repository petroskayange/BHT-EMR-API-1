# frozen_string_literal: true

module MaternityService
  # Provides various summary statistics for an Maternity patient
  class PatientSummary
    NPID_TYPE = 'National id'

    include ModelUtils

    attr_reader :patient
    attr_reader :date

    def initialize(patient, date)
      @patient = patient
      @date = date
    end

    def full_summary
      {
          patient_id: patient.patient_id,
          npid: identifier(NPID_TYPE) || 'N/A',
          current_outcome: current_outcome,
          residence: residence
      }
    end

    def identifier(identifier_type_name)
      identifier_type = PatientIdentifierType.find_by_name(identifier_type_name)

      PatientIdentifier.where(
          identifier_type: identifier_type.patient_identifier_type_id,
          patient_id: patient.patient_id
      ).first&.identifier
    end

    def residence
      address = patient.person.addresses[0]
      return 'N/A' unless address

      district = address.state_province || 'Unknown District'
      village = address.city_village || 'Unknown Village'
      "#{district}, #{village}"
    end

    def current_outcome
      patient_id = ActiveRecord::Base.connection.quote(patient.patient_id)
      quoted_date = ActiveRecord::Base.connection.quote(date)

      ActiveRecord::Base.connection.select_one(
          "SELECT patient_outcome(#{patient_id}, #{quoted_date}) as outcome"
      )['outcome'] || 'UNKNOWN'
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error("Failed tor retrieve patient current outcome: #{e}:")
      'UNKNOWN'
    end

    # Returns the most recent value_datetime for patient's observations of the
    # given concept
    def recent_value_datetime(concept_name)
      concept = ConceptName.find_by_name(concept_name)
      date = Observation.where(concept_id: concept.concept_id,
                               person_id: patient.patient_id)\
                        .order(obs_datetime: :desc)\
                        .first\
                        &.value_datetime
      return nil if date.blank?

      date
    end

  end
end
