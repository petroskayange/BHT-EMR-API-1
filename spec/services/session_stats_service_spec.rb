# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionStatsService do
  describe :visits_count do
    let(:user) { create(:user) }
    let(:program) { create(:program) }

    def service(program = nil)
      SessionStatsService.new(user, Date.today, program: program)
    end

    it 'counts visits handled by selected user only' do
      create(:encounter, encounter_datetime: Date.today, creator: user.id)
      create(:encounter, encounter_datetime: Date.today)

      expect(service.visits_count).to eq(1)
    end

    it "counts specified day's visits only" do
      encounters = (5.days.ago.to_date..Date.today).collect do |date|
        create(:encounter, encounter_datetime: date, creator: user.id)
      end

      expect(service.visits_count).not_to eq(encounters.size)
      expect(service.visits_count).to eq(1)
    end

    it 'limits visit counts to a given program if program is specified' do
      program = create(:program)

      create(:encounter, encounter_datetime: Date.today, creator: user.id)
      create(:encounter, encounter_datetime: Date.today, creator: user.id)
      create(:encounter, encounter_datetime: Date.today, creator: user.id, program: program)

      expect(service(program).visits_count).not_to eq(3)
      expect(service(program).visits_count).to eq(1)
    end
  end
end
