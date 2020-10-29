# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ARTService::RegimenEngine do
  let(:regimen_service) { ARTService::RegimenEngine.new program: Program.find_by_name!('HIV Program') }
  let(:patient) { create :patient }
  let(:vitals_encounter) { create :encounter_vitals, patient: patient }
  let(:dtg_ids) { Drug.where(concept_id: ConceptName.where(name: 'Dolutegravir').select(:concept_id)).collect(&:drug_id) }

  def filter_dtgs(drugs)
    drugs.select { |drug| dtg_ids.include?(drug[:drug_id]) }
         .sort_by { |drug| drug[:drug_id] }
  end

  def set_patient_weight(patient, weight)
    Observation.create(
      concept: concept('Weight'),
      encounter: vitals_encounter,
      person: patient.person,
      obs_datetime: Time.now,
      value_numeric: weight
    )
  end

  def concept(name)
    Concept.joins(:concept_names)
           .merge(ConceptName.where(name: name))
           .first
  end

  def create_patient(weight:, age:, gender:)
    new_patient = create :patient
    new_patient.person.gender = gender
    set_patient_weight(new_patient, weight)
    new_patient.person.birthdate = age.years.ago
    new_patient
  end

  def daily_dose(drug)
    drug[:am] + drug[:pm]
  end

  def put_patient_on_tb_treatment(patient)
    tb_status_concept_id = ConceptName.find_by_name('TB Status').concept_id
    rx_concept_id = concept('Rx').concept_id

    encounter = create(:encounter, program_id: 1, patient: patient)

    create(:observation, person_id: patient.id,
                         concept_id: tb_status_concept_id,
                         encounter_id: encounter.encounter_id,
                         obs_datetime: Time.now,
                         value_coded: rx_concept_id)
  end

  def range(start, range_end, step = 0)
    Enumerator.new do |enum|
      while start < range_end
        enum.yield(start)

        start += step
      end
    end
  end

  describe :find_regimens do
    REGIMEN_WEIGHT_RANGES = {
      [3, 3.9, 0.45] => %w[0P 2P 9P 11P 16P],
      [3, 6, 0.45] => %w[0P 2P 9P 11P 16P],
      [6, 10, 0.45] => %w[0P 2P 9P 11P 16P],
      [10, 15, 0.45] => %w[0P 2P 4P 9P 11P 16P 17P],
      [15, 20, 0.45] => %w[0P 2P 4P 9P 11P 16P 17P],
      [20, 25, 0.45] => %w[0P 2P 4P 9P 11P 14P 15P 16P 17P],
      [25, 30, 0.45] => %w[0A 2A 4P 9P 11P 14A 15A 16A 17P],
      [30, 35, 0.45] => %w[0A 2A 4A 6A 7A 8A 9A 10A 11A 13A 14A 15A 16A 17A],
      [40, 300, 20.45] => %w[0A 2A 4A 5A 6A 7A 8A 9A 10A 11A 12A 13A 14A 15A 16A 17A]
    }.freeze

    REGIMEN_WEIGHT_RANGES.each do |weight_range, expected_regimens|
      it "retrieves #{expected_regimens} for weight in [#{weight_range[0]}, #{weight_range[1]})" do
        range(*weight_range).each do |weight|
          regimens = regimen_service.find_regimens(weight)

          expect(regimens.keys.sort).to eq(expected_regimens.sort)
        end
      end
    end

    it 'adds DTG tablets to 13A for patients on TB treatment' do
      non_tb_patient = create_patient(age: 30, weight: 55, gender: 'M')

      tb_patient = create_patient(age: 30, weight: 55, gender: 'M')
      put_patient_on_tb_treatment(tb_patient)

      non_tb_regimen = filter_dtgs(regimen_service.find_regimens_by_patient(non_tb_patient)['13A'])
      tb_regimen = filter_dtgs(regimen_service.find_regimens_by_patient(tb_patient)['13A'])

      expect(non_tb_regimen).to be_empty # Doesn't have standalone DTG
      expect(tb_regimen.size).to eq(1)
    end

    it 'doubles the DTG dose on 14A and 15A for patients on TB treatment' do
      non_tb_patient = create_patient(age: 30, weight: 55, gender: 'M')

      tb_patient = create_patient(age: 30, weight: 55, gender: 'M')
      put_patient_on_tb_treatment(tb_patient)

      %w[14A 15A].each do |regimen_name|
        non_tb_regimen = filter_dtgs(regimen_service.find_regimens_by_patient(non_tb_patient)[regimen_name])
        tb_regimen = filter_dtgs(regimen_service.find_regimens_by_patient(tb_patient)[regimen_name])

        expect(tb_regimen.size).to eq(1)
        expect(non_tb_regimen.size).to eq(1)
        expect(daily_dose(tb_regimen.first)).to eq(2 * daily_dose(non_tb_regimen.first))
      end
    end
  end
end
