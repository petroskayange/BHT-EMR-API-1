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
    PATIENT_HISTORY = 'MEDICAL HISTORY'
    PMTCT = 'PMTCT HISTORY'
    PHYSICAL_EXAMINATION = 'PHYSICAL EXAMINATION'
    VAGINAL_EXAMINATION = 'VAGINAL EXAMINATION'
    CLINICAL_EXAMINATION = 'MATERNITY EXAMINATION'
    ADMISION_DIAGNOSIS = 'MATERNITY DIAGNOSIS'
    CURRENT_DELIVERY = 'CURRENT BBA DELIVERY'
    PHYSICAL_EXAMINATION_BABY = 'PHYSICAL EXAMINATION BABY'
    ABDOMINAL_EXAMINATION = 'ABDOMINAL EXAMINATION'
    NOTES = 'NOTES'
    ADMIT_PATIENT = 'ADMIT PATIENT'
    ADMISSION_DETAILS = 'OBSTETRIC HISTORY'
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
        # PATIENT_REGISTRATION => %i[patient_not_registered?],
        # VITALS => %i[patient_checked_in?
        #            patient_not_on_fast_track?
        #            patient_has_not_completed_fast_track_visit?]
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
        when /Medical History/i
          PATIENT_HISTORY
        when /PMTCT History/i
          PMTCT
        when /Physical Examination/i
          PHYSICAL_EXAMINATION
        when /Vaginal Examination/i
          VAGINAL_EXAMINATION
        when /Maternity Examination/i
          CLINICAL_EXAMINATION
        when /Obstetric History/i
          ADMISSION_DETAILS
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

     # Check if patient is not registered

    # Checks if patient has checked in today

    # Check if patient is not registere

  end
end
