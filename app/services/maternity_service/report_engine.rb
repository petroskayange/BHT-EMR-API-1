
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
      stats[:registrations] = map_stats('registrations')

      stats[:observations] = map_stats('observations')

      stats[:vitals] = map_stats('vitals')

      stats[:diagnosis] = map_stats('diagnosis')

      stats[:update_outcome] = map_stats('update_outcome')

      stats[:births] = map_stats('births')

      stats[:patients_delivered] = map_stats('patients_delivered')

      stats[:referrals_out] = map_stats('referrals_out')

      return stats
    end

    private

    # stats_mapping
    def map_stats(stats_type)
      case stats_type
      when 'registrations'
        stats_by_user = registrations('by_user')
        stats_today = registrations('today')
        stats_this_year = registrations('this_year')
        stats_total_to_date = registrations('total')
      when 'observations'
        stats_by_user = observations('by_user')
        stats_today = observations('today')
        stats_this_year = observations('this_year')
        stats_total_to_date = observations('total')
      when 'vitals'
        stats_by_user = vitals('by_user')
        stats_today = vitals('today')
        stats_this_year = vitals('this_year')
        stats_total_to_date = vitals('total')
      when 'diagnosis'
        stats_by_user = diagnosis('by_user')
        stats_today = diagnosis('today')
        stats_this_year = diagnosis('this_year')
        stats_total_to_date = diagnosis('total')
      when 'update_outcome'
        stats_by_user = update_outcome('by_user')
        stats_today = update_outcome('today')
        stats_this_year = update_outcome('this_year')
        stats_total_to_date = update_outcome('total')
      when 'births'
        stats_by_user = baby_delivered('by_user')
        stats_today = baby_delivered('today')
        stats_this_year = baby_delivered('this_year')
        stats_total_to_date = baby_delivered('total')
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

      {
          stats_by_user: stats_by_user,
          stats_today: stats_today,
          stats_this_year: stats_this_year,
          stats_total_to_date: stats_total_to_date
      }

    end

    # registrations
    def registrations(stats_type)

      type = EncounterType.find_by_name 'Registration'

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
        # ------
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year
        # ------
        #

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

      type = EncounterType.find_by_name 'Registration'

      case stats_type
      when 'by_user'
        count = Observation.select('count(*) AS total')

      when 'today'
        count = Observation.where('obs_datetime BETWEEN ? AND ?', *TimeUtils.day_bounds(@date)).\
        select('count(*) AS total')
      when 'this_year'
        # ------
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year
        # ------
        #

        count = Observation.where('obs_datetime BETWEEN ? AND ? ', start_date, end_date).\
        select('count(*) AS total')
      when 'total'

        count = Observation.select('count(*) AS total')
      end

      return count[0]['total'].to_i
    end

    # vitals
    def vitals(stats_type)

      type = EncounterType.find_by_name 'Vitals'

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
        # ------
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year
        # ------
        #

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

    # diagnosis
    def diagnosis(stats_type)

      type = EncounterType.find_by_name 'Admission Diagnosis'

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
        # ------
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year
        # ------
        #

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

    # update_outcome
    def update_outcome(stats_type)

      type = EncounterType.find_by_name 'Update Outcome'

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
        # ------
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year
        # ------
        #

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

    # baby_delivery
    def baby_delivered(stats_type)

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
        # ------
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year
        # ------
        #

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

    # patients_delivered
    def patients_delivered(stats_type)

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
        # ------
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year
        # ------
        #

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
        # ------
        start_date = Date.today.beginning_of_year
        end_date = Date.today.end_of_year
        # ------
        #

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
