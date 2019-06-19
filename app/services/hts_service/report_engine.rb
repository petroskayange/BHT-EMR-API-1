
require 'set'

module HTSService
  class ReportEngine
    include ModelUtils

    def initialize
      # @program = program
      # @date = date
      # @name = name
      # @type = type
      # @start_date = start_date.to_date
      # @end_date = end_date.to_date
    end

    def find_report(name:, **kwargs)
      method(name.to_sym).call(**kwargs)
    end

    def find_all_patients(start_date:, end_date:, **kwargs)
     # day_start, day_end = TimeUtils.day_bounds(start_date)
      Patient.find_by_sql(
        [
          'SELECT patient.* FROM patient INNER JOIN encounter USING (patient_id)
          WHERE encounter.encounter_datetime BETWEEN ? AND ?
            AND encounter.voided = 0 AND patient.voided = 0
          GROUP BY patient.patient_id',
          start_date, end_date
        ]
      )
    end

  end
end
