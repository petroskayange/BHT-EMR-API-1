# frozen_string_literal: true

require 'set'

module MaternityService
  class WorkflowEngine
    include ModelUtils

    def initialize(program:, patient:, date:)
      @patient = patient
      @program = program
      @date = date
      @activities = load_user_activities
    end

    # Retrieves the next encounter for bound patient
    def next_encounter
      state = INITIAL_STATE
      loop do
        state = next_state state
        break if state == END_STATE

        LOGGER.debug "Loading encounter type: #{state}"
        encounter_type = EncounterType.find_by(name: state)

        return encounter_type if valid_state?(state)
      end

      nil
    end

    private

    LOGGER = Rails.logger

    # Encounter types
    INITIAL_STATE = 0 # Start terminal for encounters graph
    END_STATE = 1 # End terminal for encounters graph
    UPDATE_OUTCOME = 'UPDATE OUTCOME'
    UPDATE_HIV_STATUS = 'UPDATE HIV STATUS'
    SOCIAL_HISTORY = 'SOCIAL HISTORY'
    VITALS = 'VITALS'
    PATIENT_HISTORY = 'OBSTETRIC HISTORY'
    PMTCT = 'PMTCT HISTORY'
    PHYSICAL_EXAMINATION = 'PHYSICAL EXAMINATION'
    VAGINAL_EXAMINATION = 'VAGINAL EXAMINATION'
    CLINICAL_EXAMINATION = 'MATERNITY EXAMINATION'
    ADMISION_DIAGNOSIS = 'MATERNITY DIAGNOSIS'
    CURRENT_DELIVERY = 'BABY DELIVERY'
    PHYSICAL_EXAMINATION_BABY = 'PHYSICAL EXAMINATION BABY'
    ABDOMINAL_EXAMINATION = 'ABDOMINAL EXAMINATION'
    NOTES = 'NOTES'
    ADMIT_PATIENT = 'ADMIT PATIENT'
    ADMISSION_DETAILS = 'PATIENT ADMISSIONS'
    ADMISSION_DIAGNOSIS = 'ADMISSION DIAGNOSIS'

    # Encounters graph
    ENCOUNTER_SM = {
        INITIAL_STATE => SOCIAL_HISTORY,
        SOCIAL_HISTORY => ADMISSION_DETAILS,
        ADMISSION_DETAILS => VITALS,
        VITALS => PATIENT_HISTORY,
        PATIENT_HISTORY => PMTCT,
        PMTCT => PHYSICAL_EXAMINATION,
        PHYSICAL_EXAMINATION => VAGINAL_EXAMINATION,
        VAGINAL_EXAMINATION => CLINICAL_EXAMINATION,
        CLINICAL_EXAMINATION => ADMISSION_DIAGNOSIS,
        ADMISSION_DIAGNOSIS => END_STATE
    }.freeze

    STATE_CONDITIONS = {
        SOCIAL_HISTORY => %i[social_history_not_collected?],
        ADMISSION_DETAILS => %i[admission_details_not_collected?],
        VITALS => %i[vitals_not_collected?],
        PATIENT_HISTORY => %i[patient_history_not_collected?],
        PMTCT => %i[pmtct_not_collected?],
        PHYSICAL_EXAMINATION => %i[physical_examination_not_collected?],
        VAGINAL_EXAMINATION => %i[vaginal_examination_not_collected?],
        CLINICAL_EXAMINATION => %i[clinical_examination_not_collected?],
        ADMISSION_DIAGNOSIS => %i[admission_diagnosis_not_collected?]
    }.freeze

    def load_user_activities
      activities = user_property('Activities')&.property_value
      encounters = (activities&.split(',') || []).collect do |activity|
        # Re-map activities to encounters
        puts activity
        case activity
        when /Social History/i
          SOCIAL_HISTORY
        when /Admission Diagnosis/i
          ADMISSION_DIAGNOSIS
        when /Vitals/i
          VITALS
        when /Patient Admissions/i
          ADMISSION_DETAILS
        when /PMTCT History/i
          PMTCT
        when /Physical Examination/i
          PHYSICAL_EXAMINATION
        when /Vaginal Examination/i
          VAGINAL_EXAMINATION
        when /Maternity Examination/i
          CLINICAL_EXAMINATION
        when /Obstetric History/i
          PATIENT_HISTORY
        else
          Rails.logger.warn "Invalid Maternity activity in user properties: #{activity}"
        end
      end
     Set.new(encounters)
    end

    def next_state(current_state)
      ENCOUNTER_SM[current_state]
    end

    # Check if a relevant encounter of given type exists for given patient.
    #
    # NOTE: By `relevant` above we mean encounters that matter in deciding
    # what encounter the patient should go for in this present time.
    def encounter_exists?(type)
      Encounter.where(type: type, patient: @patient)\
               .where('encounter_datetime BETWEEN ? AND ?', *TimeUtils.day_bounds(@date))\
               .exists?
    end

    def valid_state?(state)
      return false if encounter_exists?(encounter_type(state))

      (STATE_CONDITIONS[state] || []).reduce(true) do |status, condition|
        status && method(condition).call
      end
    end

    # check if patient has social history
    def social_history_not_collected?
      encounter = Encounter.joins(:type).where(
          'encounter_type.name = ? AND encounter.patient_id = ?',
          SOCIAL_HISTORY, @patient.patient_id)

      encounter.blank?
    end

    # check if patient has admission history
    def admission_details_not_collected?
      encounter = Encounter.joins(:type).where(
          'encounter_type.name = ? AND encounter.patient_id = ?',
          ADMISSION_DETAILS, @patient.patient_id)

      encounter.blank?
    end

    # check if patient has vitals
    def vitals_not_collected?
      encounter = Encounter.joins(:type).where(
          'encounter_type.name = ? AND encounter.patient_id = ?',
          VITALS, @patient.patient_id)

      encounter.blank?
    end

    # Check if patient has patient history
    def patient_history_not_collected?
      encounter = Encounter.joins(:type).where(
          'encounter_type.name = ? AND encounter.patient_id = ?',
          PATIENT_HISTORY, @patient.patient_id)

      encounter.blank?
    end

    # check if patient has pmtct history
    def pmtct_not_collected?
      encounter = Encounter.joins(:type).where(
          'encounter_type.name = ? AND encounter.patient_id = ?',
          PMTCT, @patient.patient_id)

      encounter.blank?
    end

    # check if patient has physical examination
    def physical_examination_not_collected?
      encounter = Encounter.joins(:type).where(
          'encounter_type.name = ? AND encounter.patient_id = ?',
          PHYSICAL_EXAMINATION, @patient.patient_id)

      encounter.blank?
    end

    # check if patient has vaginal examination
    def vaginal_examination_not_collected?
      encounter = Encounter.joins(:type).where(
          'encounter_type.name = ? AND encounter.patient_id = ?',
          VAGINAL_EXAMINATION, @patient.patient_id)

      encounter.blank?
    end

    # check if patient has clinical examination
    def clinical_examination_not_collected?
      encounter = Encounter.joins(:type).where(
          'encounter_type.name = ? AND encounter.patient_id = ?',
          CLINICAL_EXAMINATION, @patient.patient_id)

      encounter.blank?
    end

    # check if patient has admission diagnosis
    def admission_diagnosis_not_collected?
      encounter = Encounter.joins(:type).where(
          'encounter_type.name = ? AND encounter.patient_id = ?',
          ADMISSION_DIAGNOSIS, @patient.patient_id)

      encounter.blank?
    end

  end
end
