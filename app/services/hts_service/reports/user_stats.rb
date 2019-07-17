# frozen_string_literal: true

class HTSService::Reports::UserStats
  def find_report(name:, start_date:, end_date:, **kwargs)
    case name
    when 'all'
      all_users_stats(start_date, end_date)
    when 'user'
      single_user_stats(start_date, end_date, **kwargs)
    else
      raise NotFoundError, "HTS user stats report `#{name}` not found"
    end
  end

  private

  def hts_program
    @hts_program ||= Program.find_by_name('HTC Program')
  end

  # Statistics for all users
  def all_users_stats(start_date, end_date)
    raw_stats = retrieve_all_users_raw_stats(start_date, end_date)
    group_all_users_raw_stats_by_date_and_user(raw_stats).values
  end

  def single_user_stats(start_date, end_date, user_id: nil)
    user_id ||= User.current.id

    retrieve_user_raw_stats(start_date, end_date, user_id).collect do |stats|
      { patient_id: stats['patient_id'], visit_date: stats['visit_date'] }
    end
  end

  def retrieve_user_raw_stats(start_date, end_date, user_id)
    start_date = ActiveRecord::Base.connection.quote(start_date)
    end_date = ActiveRecord::Base.connection.quote(end_date)
    program_id = ActiveRecord::Base.connection.quote(hts_program.id)
    user_id = ActiveRecord::Base.connection.quote(user_id)

    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT patient_id, DATE(encounter_datetime) AS visit_date FROM encounter
        WHERE #{start_date} <= encounter.encounter_datetime
              AND #{end_date} >= encounter.encounter_datetime
              AND encounter.program_id = #{program_id}
              AND creator = #{user_id}
        GROUP BY encounter.patient_id, encounter.creator, visit_date
      SQL
    )
  end

  # Retrieves aggregate user stats from database.
  #
  # Returns a list of rows comprising of:
  #       [user_id, username, given_name, family_name, patient_id, visit_date]
  #
  #   - NOTE: For each visit a user handles in a day is the row above.
  def retrieve_all_users_raw_stats(start_date, end_date)
    start_date = ActiveRecord::Base.connection.quote(start_date)
    end_date = ActiveRecord::Base.connection.quote(end_date)
    program_id = ActiveRecord::Base.connection.quote(hts_program.id)

    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT encounter.creator AS user_id, users.username AS username,
               person_name.given_name AS given_name, person_name.family_name AS family_name,
               encounter.patient_id AS patient_id, DATE(encounter.encounter_datetime) AS visit_date
        FROM encounter INNER JOIN users ON encounter.creator = users.user_id
                       INNER JOIN person_name ON encounter.creator = person_name.person_id
        WHERE #{start_date} <= encounter.encounter_datetime
              AND #{end_date} >= encounter.encounter_datetime
              AND encounter.program_id = #{program_id}
        GROUP BY encounter.patient_id, encounter.creator, visit_date
      SQL
    )
  end

  # Groups raw aggregate stats (see retrieve_raw_aggregate_stats) per user for each day.
  def group_all_users_raw_stats_by_date_and_user(raw_stats)
    raw_stats.each_with_object({}) do |stats, daily_user_stats|
      key = [stats['username'], stats['visit_date']]

      daily_user_stats[key] ||= {
        date: stats['visit_date'], username: stats['username'],
        given_name: stats['given_name'], family_name: stats['family_name'],
        total_visits: 0, visits: []
      }

      daily_user_stats[key][:total_visits] += 1
      daily_user_stats[key][:visits] << stats
    end
  end
end
