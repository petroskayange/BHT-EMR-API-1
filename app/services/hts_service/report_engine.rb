# frozen_string_literal: true

module HTSService
  class ReportEngine
    REPORTS = {
      'user_stats' => HTSService::Reports::UserStats,
      'patients' => HTSService::Reports::Patients
    }.freeze

    def find_report(type:, name:, **kwargs)
      report(type).find_report(name: name, **kwargs)
    end

    def build_report(type:, name:, **kwargs)
      report(type).build_report(name: name, **kwargs)
    end

    private

    def report(type)
      REPORTS[type].new
    end
  end
end
