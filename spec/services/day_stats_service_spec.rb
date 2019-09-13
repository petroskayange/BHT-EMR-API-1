# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DayStatsService do
  describe :visits_count do
    def create_encounters(dates)
      dates.collect { |date| create(:encounter, encounter_datetime: date) }
    end

    it 'counts visits for a given day only' do
      service = DayStatsService.new(Date.today)
      encounters = create_encounters(5.days.ago.to_date..Time.now)

      expect(service.visits_count).not_to eq(encounters.size)
      expect(service.visits_count).to eq(1)
    end

    it 'limits visit counts to a given program if program is specified' do
      encounters = create_encounters(10.days.ago.to_date..10.days.after.to_date)
      service = DayStatsService.new(encounters.last.encounter_datetime.to_date, program: encounters.last.program)

      expect(service.visits_count).not_to eq(encounters.size)
      expect(service.visits_count).to eq(1)
    end
  end
end
