# frozen_string_literal: true

require 'set'

module HTSService
  class WorkflowEngine
    include ModelUtils

    def initialize(program:, patient:, date:)
      @patient = patient
      @program = program
      @date = date
      @activities = load_user_activities
    end

    # Retrieves the next encounter for bounvisitd patient
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
    HTS_VISIT = 'HTS Visit'


    # Encounters graph
    ENCOUNTER_SM = {
        INITIAL_STATE => HTS_VISIT,
        HTS_VISIT => END_STATE
    }.freeze


    STATE_CONDITIONS = {
      HTS_VISIT => %i[no_hts_visit?]
  }.freeze


    def load_user_activities
      activities = user_property('Activities')&.property_value
      encounters = (activities&.split(',') || []).collect do |activity|
        # Re-map activities to encounters
        puts activity
        case activity
        when /HTS Visit/i
          HTS_VISIT
        else
          Rails.logger.warn "Invalid HTS activity in user properties: #{activity}"
        end
      end
     Set.new(encounters)
    end

    def next_state(current_state)
      ENCOUNTER_SM[current_state]
    end
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

    def no_hts_visit?
      true
    end

  end
end
