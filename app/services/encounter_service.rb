# frozen_string_literal: true

class EncounterService
  def self.recent_encounter(encounter_type_name:, patient_id:, date: nil,
                            start_date: nil, program_id: nil)
    start_date ||= Date.strptime('1900-01-01')
    date ||= Date.today
    type = EncounterType.find_by(name: encounter_type_name)

    query = Encounter.where(type: type, patient_id: patient_id)\
                     .where('encounter_datetime BETWEEN ? AND ?',
                            start_date.to_date.strftime('%Y-%m-%d 00:00:00'),
                            date.to_date.strftime('%Y-%m-%d 23:59:59'))
    query = query.where(program_id: program_id) if program_id
    query.order(encounter_datetime: :desc).first
  end

  def create(type:, patient:, program:, encounter_datetime: nil, provider: nil)
    encounter_datetime ||= Time.now
    provider ||= User.current.person

    encounter = find_encounter(type: type, patient: patient, provider: provider,
                               encounter_datetime: encounter_datetime, program: program)

    return encounter if encounter

    Encounter.create(
      type: type, patient: patient, provider: provider,
      encounter_datetime: encounter_datetime, program: program,
      location_id: Location.current.id
    )
  end

  def update(encounter, patient: nil, type: nil, encounter_datetime: nil,
             provider: nil, program:)
    updates = {
      patient: patient, type: type, provider: provider,
      program: program, encounter_datetime: encounter_datetime
    }
    updates = updates.keep_if { |_, v| !v.nil? }

    encounter.update(updates)
    encounter
  end

  def find_encounter(type:, patient:, encounter_datetime:, provider:, program:)
    Encounter.where(type: type, patient: patient, program: program)\
             .where('encounter_datetime BETWEEN ? AND ?',
                    *TimeUtils.day_bounds(encounter_datetime))\
             .order(encounter_datetime: :desc)
             .first
  end

  def void(encounter, reason)
    encounter.void(reason)
  end

  # Associate an encounter with a register
  def bind_encounter_to_register(encounter, register)
    if register.closed?
      raise InvalidParameterError, "Can't add encounter to closed register(#{register.id})"
    end

    unbind_encounter_from_register(encounter)

    EncounterRegister.create(encounter: encounter, register: register,
                             creator: User.current.id)
  end

  # Dissociates an encounter from bound register(s)
  def unbind_encounter_from_register(encounter)
    EncounterRegister.where(encounter: encounter).each(&:destroy)
  end

  # Returns register that is bound to encounter with given encounter_id.
  #
  # Raises NotFoundError if no register is bound to the encounter
  def find_encounter_register(encounter_id)
    register = Register.joins('INNER JOIN encounter_registers')
                       .where('encounter_id = ?', encounter_id)
                       .first

    unless register
      raise NotFoundError, "Encounter (##{encounter_id}) is not bound to any register"
    end

    register
  end
end
