# frozen_string_literal: true

require 'luhn'
require 'monitor'

module HTSService::CodeGenerator
  class << self
    ENTRY_CODE_PREFIX = 'ec'
    ENTRY_CODE_MUTEX = Monitor.new
    HTS_ENTRY_CODE_CONCEPT_ID = ConceptName.find_by_name('HTS Entry Code').concept_id

    def generate(code_type, args)
      generator = method(code_type.to_sym)
      raise NotFoundError, "HTS code generator for #{code_type} not found" unless generator

      begin
        generator.call(**args)
      rescue ArgumentError => e
        raise InvalidParameterError, e.message
      end
    end

    def entry_code(encounter_id:, prefix: ENTRY_CODE_PREFIX)
      ENTRY_CODE_MUTEX.synchronize do
        ActiveRecord::Base.connection.transaction do
          code = find_encounter_entry_code(encounter_id)
          return code if code

          code = generate_entry_code(prefix)
          save_entry_code(code, encounter_id)
          code
        end
      end
    end

    private

    def generate_entry_code(prefix)
      code = next_entry_code_base(prefix)
      checksum = Luhn.checksum(code)
      "#{prefix.upcase}#{code}-#{checksum}"
    end

    def next_entry_code_base(prefix)
      property_name = "#{prefix.downcase}.id.counter"
      property = GlobalProperty.find_by_property(property_name)
      current_code = (property&.property_value&.to_i || 0) + 1

      if property
        property.update(property_value: current_code)
      else
        GlobalProperty.create(property: property_name, property_value: current_code,
                              uuid: SecureRandom.uuid)
      end

      current_code
    end

    def find_encounter_entry_code(encounter_id)
      Observation.where(encounter_id: encounter_id, concept_id: HTS_ENTRY_CODE_CONCEPT_ID)\
                 .where.not(value_text: nil)\
                 .first\
                 &.value_text
    end

    def save_entry_code(code, encounter_id)
      encounter = Encounter.find(encounter_id)
      Observation.create(encounter_id: encounter_id,
                         concept_id: HTS_ENTRY_CODE_CONCEPT_ID,
                         person_id: encounter.patient_id,
                         value_text: code,
                         obs_datetime: Time.now)
    end
  end
end
