# frozen_string_literal: true

# Provides various statistics for today (or the set date)
#
# @see SessionStatsService
class DayStatsService
  attr_accessor :date, :program

  def initialize(date, program: nil)
    @date = date
    @program = program
  end

  # Returns the number of visits on bound date
  def visits_count
    day_bounds = TimeUtils.day_bounds date
    day_start = ActiveRecord::Base.connection.quote(day_bounds[0])
    day_end = ActiveRecord::Base.connection.quote(day_bounds[1])
    program_id = program && ActiveRecord::Base.connection.quote(program.program_id)

    row = ActiveRecord::Base.connection.select_one <<~SQL
      SELECT sum(visitor) as total_visitors FROM
        (SELECT 1 as visitor FROM encounter
         WHERE encounter_datetime BETWEEN #{day_start} AND #{day_end}
               AND voided = 0
               #{program_id ? 'AND program_id = ' + program_id.to_s : ''}
         GROUP BY patient_id) AS visitors
    SQL

    row['total_visitors'] || 0
  end
end
