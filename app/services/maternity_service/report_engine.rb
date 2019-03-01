
require 'set'

module MaternityService
  class ReportEngine
    include ModelUtils

    def initialize(program:, date:)
      @program = program
      @date = date
    end

    def dashboard_stats

      stats = {}

      generic_encounters = ['registration','vitals','admission_diagnosis','baby_delivery']

      (generic_encounters || []).each do |encounter|
        stats[encounter] = map_stats(encounter,true)
      end

      stats[:patients_delivered] = map_stats('patients_delivered')

      stats[:referrals_out] = map_stats('referrals_out')

      return stats
    end

    private

    # stats_mapping
    def map_stats(stats_type,generic=false)

      if generic == true
            encounter_name = stats_type.titlecase
            stats_by_user = generic_encounter_statistics(encounter_name,'by_user')
            stats_today = generic_encounter_statistics(encounter_name,'today')
            stats_this_year = generic_encounter_statistics(encounter_name,'this_year')
            stats_total_to_date = generic_encounter_statistics(encounter_name,'total')

      else
        case stats_type
        when 'patients_delivered'
          stats_by_user = patients_delivered('by_user')
          stats_today = patients_delivered('today')
          stats_this_year = patients_delivered('this_year')
          stats_total_to_date = patients_delivered('total')
        when 'referrals_out'
          stats_by_user = referrals_out('by_user')
          stats_today = referrals_out('today')
          stats_this_year = referrals_out('this_year')
          stats_total_to_date = referrals_out('total')
        end
      end

      {
          stats_by_user: stats_by_user,
          stats_today: stats_today,
          stats_this_year: stats_this_year,
          stats_total_to_date: stats_total_to_date
      }

    end

    def generic_encounter_statistics(encounter_name, stats_type)

      type = EncounterType.find_by_name encounter_name

      case stats_type
      when 'by_user'
        creator = User.current.user_id

        count = Encounter.where('encounter_type = ? AND encounter.creator = ?', type.id, creator).\
        joins('INNER JOIN obs USING(encounter_id)').\
        select('count(*) AS total')
      when 'today'
        count = Encounter.where('encounter_datetime BETWEEN ? AND ?
        AND encounter_type = ? ', *TimeUtils.day_bounds(@date), type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        select('count(*) AS total')
      when 'this_year'

        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year

        count = Encounter.where('encounter_datetime BETWEEN ? AND ?
        AND encounter_type = ? ', start_date, end_date, type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        select('count(*) AS total')
      when 'total'

        count = Encounter.where('encounter_type = ? ', type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        select('count(*) AS total')
      end

      return count[0]['total'].to_i
    end

    # -- To be refactored from here down --//
    # observations
    def observations(stats_type)
      case stats_type
      when 'by_user'
        count = Observation.select('count(*) AS total')

      when 'today'
        count = Observation.where('obs_datetime BETWEEN ? AND ?', *TimeUtils.day_bounds(@date)).\
        select('count(*) AS total')
      when 'this_year'

        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year

        count = Observation.where('obs_datetime BETWEEN ? AND ? ', start_date, end_date).\
        select('count(*) AS total')
      when 'total'

        count = Observation.select('count(*) AS total')
      end

      return count[0]['total'].to_i
    end

    # patients_delivered
    def patients_delivered(stats_type)

      type = EncounterType.find_by_name 'Update Outcome'

      # for patients delivered
      outcome_concept_id = ConceptName.find_by_name("OUTCOME").concept_id
      delivered_concept_id = ConceptName.find_by_name("DELIVERED").concept_id

      case stats_type
      when 'by_user'
        count = Encounter.where('encounter_type = ?', type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        where('obs.concept_id = ? AND obs.value_coded = ?', outcome_concept_id, delivered_concept_id).\
        select('count(*) AS total')
      when 'today'
        count = Encounter.where('encounter_datetime BETWEEN ? AND ?
        AND encounter_type = ? ', *TimeUtils.day_bounds(@date), type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        where('obs.concept_id = ? AND obs.value_coded = ?', outcome_concept_id, delivered_concept_id).\
        select('count(*) AS total')
      when 'this_year'

        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year

        count = Encounter.where('encounter_datetime BETWEEN ? AND ?
        AND encounter_type = ? ', start_date, end_date, type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        where('obs.concept_id = ? AND obs.value_coded = ?', outcome_concept_id, delivered_concept_id).\
        select('count(*) AS total')
      when 'total'

        count = Encounter.where('encounter_type = ? ', type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        where('obs.concept_id = ? AND obs.value_coded = ?', outcome_concept_id, delivered_concept_id).\
        select('count(*) AS total')
      end

      return count[0]['total'].to_i
    end

    # referrals_out
    def referrals_out(stats_type)

      type = EncounterType.find_by_name 'Baby Delivery'

      case stats_type
      when 'by_user'
        count = Encounter.where('encounter_type = ?', type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        select('count(*) AS total')
      when 'today'
        count = Encounter.where('encounter_datetime BETWEEN ? AND ?
        AND encounter_type = ? ', *TimeUtils.day_bounds(@date), type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        select('count(*) AS total')
      when 'this_year'

        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year

        count = Encounter.where('encounter_datetime BETWEEN ? AND ?
        AND encounter_type = ? ', start_date, end_date, type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        select('count(*) AS total')
      when 'total'

        count = Encounter.where('encounter_type = ? ', type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        select('count(*) AS total')
      end

      return count[0]['total'].to_i
    end
  end
end
