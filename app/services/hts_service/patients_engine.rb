# frozen_string_literal: true

module HTSService
  class PatientsEngine
    attr_reader :program

    def initialize(program:)
      @program = program
    end

    def all_patients(cut_off_date = nil)
      cut_off_date ||= Date.today

      Patient.joins(:patient_programs)
             .where('patient.date_created <= ?', cut_off_date.strftime('%Y-%m-%d 23:59:59'))
             .merge(PatientProgram.where(program: program))
             .order(date_created: :desc)
    end
  end
end
