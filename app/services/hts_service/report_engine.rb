# frozen_string_literal: true

module HTSService
  class ReportEngine
    include ModelUtils
    include QueryPaginateUtils

    ALL_PATIENTS_REPORT_PAGE_SIZE = 3

    def find_report(type:, name:, start_date:, end_date:, **kwargs)
      method(type.to_sym).call(name, start_date, end_date, kwargs)
    end

    def patients(_name, start_date, end_date, kwargs)
      query = Patient.joins(:encounters)\
                     .where(encounter: { program_id: hts_program.id })\
                     .where('encounter_datetime BETWEEN ? AND ?', start_date, end_date)\
                     .group('patient_id')

      params = kwargs[:request_params]
      page = params[:page] || 0
      page_size = params[:page_size] || ALL_PATIENTS_REPORT_PAGE_SIZE

      {
        patients: paginate_query(query, page: page, page_size: page_size),
        count: Patient.joins(:encounters)\
                      .where(encounter: { program_id: hts_program.id })\
                      .where('encounter_datetime BETWEEN ? AND ?', start_date, end_date)\
                      .group('patient_id')\
                      .size
      }
    end

    private

    def hts_program
      @hts_program = program('HTC Program')
    end
  end
end
