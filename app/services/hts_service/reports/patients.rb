# frozen_string_literal: true

class HTSService::Reports::Patients
  ALL_PATIENTS_REPORT_PAGE_SIZE = 3

  def find_report(start_date:, end_date:, **kwargs)
    query = Patient.joins(:encounters)\
                   .where(encounter: { program_id: hts_program.id })\
                   .where('encounter_datetime BETWEEN ? AND ?', start_date, end_date)\
                   .group('patient_id')

    page = kwargs[:page]&.to_i || 0
    page_size = kwargs[:page_size]&.to_i || ALL_PATIENTS_REPORT_PAGE_SIZE

    {
      patients: paginate_query(query, page: page, page_size: page_size),
      page: page,
      page_size: page_size,
      total_pages: page_size.zero? ? 0 : query.count.size / page_size
      # NOTE: query.count returns encounter counts for each patient individually.
      #       This could be somewhat inefficient though, optimise it.
    }
  end

  def build_report(**kwargs)
    find_report(**kwargs)
  end

  private

  include ModelUtils
  include QueryPaginateUtils

  def hts_program
    @hts_program = program('HTC Program')
  end
end
