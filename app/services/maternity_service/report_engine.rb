
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

    def monthly_report
      stats = {}
      stats[:patients_delivered] = map_stats('patients_delivered')
      stats[:referrals_out] = map_stats('referrals_out')
      stats[:baby_delivery] = map_stats('baby_delivery', true)
      stats[:registration] = map_stats('registration', true)
      stats[:number_of_babies] = map_stats('baby_delivery')
      return stats
    end

    private

      # for monthly_report strictly
      # -------------------------------

      # -------------------------------

      # stats_mapping
      def map_stats(stats_type,generic=false)

        if generic == true
          encounter_name = stats_type.titlecase
          stats_by_user = generic_encounter_statistics(encounter_name,'by_user')
          stats_today = generic_encounter_statistics(encounter_name,'today')
          stats_this_year = generic_encounter_statistics(encounter_name,'this_year')
          stats_this_month = generic_encounter_statistics(encounter_name,'this_month')
          stats_total_to_date = generic_encounter_statistics(encounter_name,'total')

        else
          case stats_type
          when 'patients_delivered'
            stats_by_user = patients_delivered('by_user')
            stats_today = patients_delivered('today')
            stats_this_year = patients_delivered('this_year')
            stats_this_month = patients_delivered('this_month')
            stats_total_to_date = patients_delivered('total')
          when 'referrals_out'
            stats_by_user = referrals_out('by_user')
            stats_today = referrals_out('today')
            stats_this_year = referrals_out('this_year')
            stats_this_month = referrals_out('this_month')
            stats_total_to_date = referrals_out('total')
          when 'baby_delivery'
            stats_by_user = ''
            stats_today = ''
            stats_this_year = ''
            stats_this_month = number_of_babies('this_month')
            stats_total_to_date = ''
          end
        end

        {
            stats_by_user: stats_by_user,
            stats_today: stats_today,
            stats_this_year: stats_this_year,
            stats_this_month: stats_this_month,
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
        when 'this_month'
          start_date = Date.today.beginning_of_month
          end_date = Date.today.end_of_month

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
        when 'this_month'

          start_date = Date.today.beginning_of_month
          end_date = Date.today.end_of_month

          count = Observation.where('obs_datetime BETWEEN ? AND ? ', start_date, end_date).\
        select('count(*) AS total')
        when 'total'

          count = Observation.select('count(*) AS total')
        end

        return count[0]['total'].to_i
      end

      # baby delivery
      def number_of_babies(stats_type)

        type = EncounterType.find_by_name 'Baby Delivery'

        outcome_concept_id = ConceptName.find_by_name("OUTCOME").concept_id
        number_of_babies_concept_id = ConceptName.find_by_name("NUMBER OF BABIES").concept_id

        case stats_type
        when 'this_month' # for monthly report (number of babies)
          start_date = Date.today.beginning_of_month
          end_date = Date.today.end_of_month

          count = Encounter.where('encounter_datetime BETWEEN ? AND ?
        AND encounter_type = ? ', start_date, end_date, type.id).\
        joins('INNER JOIN obs USING(encounter_id)').\
        where('obs.concept_id = ?', number_of_babies_concept_id).\
        select('count(*) AS total')
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

        when 'this_month' # for monthly report (mother's status)
          start_date = Date.today.beginning_of_month
          end_date = Date.today.end_of_month

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

        # for patients delivered
        referral_concept_id = ConceptName.find_by_name("OUTCOME").concept_id

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
        when 'this_month'

          start_date = Date.today.beginning_of_month
          end_date = Date.today.end_of_month

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
