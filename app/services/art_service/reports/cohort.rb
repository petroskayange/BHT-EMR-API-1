# frozen_string_literal: true

class ARTService::Reports::Cohort
  include ModelUtils

  # Methods to be exported as sub reports.
  SUB_REPORTS = Set.new(%i[total_registered_patients
                           patients_reason_for_starting_art
                           patients_outcome
                           patients_with_side_effects
                           re_initiated_on_art
  												 current_episode_of_tb
													 kaposis_sarcoma_patients
													 month_died_in
													 pregnant_females
                           patients_with_tb_in_last_2_years]).freeze

  attr_reader :name, :start_date, :end_date

  def initialize(name:, start_date:, end_date:, **_kwargs)
    @name = name
    @start_date = quote_atom(start_date.strftime('%Y-%m-%d 00:00:00'))
    @end_date = quote_atom(end_date.strftime('%Y-%m-%d 23:59:59'))
    @sub_report = load_sub_report(name)
  end

  def find_report(**kwargs)
    if kwargs[:extras]
      extras = kwargs[:extras]
      if extras.include?(:patient_ids)
        @sub_report.call(extras[:patient_ids])
      else
        @sub_report.call
      end
    else
      @sub_report.call
    end
  end

  private

  def load_sub_report(name)
    name = name.to_sym

    # NOTE: Ensure name has been exported as a method to prevent clients from
    # executing methods on this object that they aren't supposed to.
    unless SUB_REPORTS.include?(name)
      raise InvalidParameterError, "Invalid cohort sub report: #{name}"
    end

    method(name)
  end

  def total_registered_patients(*)
    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT
          `p`.`patient_id` AS `patient_id`,
          CAST(patient_date_enrolled(`p`.`patient_id`) AS DATE) AS `date_enrolled`,
          date_antiretrovirals_started(`p`.`patient_id`, MIN(`s`.`start_date`)) AS `earliest_start_date`,
          `pe`.`birthdate`,
          `pe`.`birthdate_estimated`,
          `person`.`death_date` AS `death_date`,
          `pe`.`gender` AS `gender`,
          (SELECT timestampdiff(year, `pe`.`birthdate`, MIN(`s`.`start_date`))) AS `age_at_initiation`,
          (SELECT timestampdiff(day, `pe`.`birthdate`, MIN(`s`.`start_date`))) AS `age_in_days`
        FROM
          ((`patient_program` `p`
          LEFT JOIN `person` `pe` ON ((`pe`.`person_id` = `p`.`patient_id`))
          LEFT JOIN `patient_state` `s` ON ((`p`.`patient_program_id` = `s`.`patient_program_id`)))
          LEFT JOIN `person` ON ((`person`.`person_id` = `p`.`patient_id`)))
        WHERE
          ((`p`.`voided` = 0)
              AND (`s`.`voided` = 0)
              AND (`p`.`program_id` = 1)
              AND (`s`.`state` = #{on_arvs_state_id}))
              AND (`s`.`start_date` <= #{end_date})
              AND (DATE(`s`.`start_date`) != '0000-00-00')
        GROUP BY `p`.`patient_id`
        HAVING date_enrolled IS NOT NULL;
      SQL
    )
  end

  def patients_reason_for_starting(patient_ids)
    patient_ids = quote_array(patient_ids)

    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT patient_id, patient_reason_for_starting_art(patient_id) AS reason
        FROM patient_program
        WHERE program_id = #{hiv_program_id}
          AND patient_id IN #{patient_ids}
          AND date_enrolled <= #{end_date}
      SQL
    )
  end

  def patients_outcome(patient_ids)
    patient_ids = quote_array(patient_ids)

    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT patient_id, patient_outcome(patient_id, #{@end_date}) AS outcome
        FROM patient_program
        WHERE patient_id IN #{patient_ids}
          AND program_id = #{hiv_program_id}
          AND date_enrolled <= #{@end_date}
      SQL
    )
  end

	def month_died_in(patient_ids)
    patient_ids = quote_array(patient_ids)

    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT patient_id, died_in(patient_id, 'Patient died', date_enrolled) died_in
        FROM patient_program
        WHERE patient_id IN #{patient_ids}
          AND program_id = #{hiv_program_id}
          AND date_enrolled <= #{@end_date}
      SQL
		)
	end

	def pregnant_females(patient_ids)
		# Pregant when registering
    patient_ids = quote_array(patient_ids)

		concept_names = ['Is patient pregnant at initiation?','Is patient pregnant?','PATIENT PREGNANT']
    pregnancy_concept_ids = concept_ids_from_names(concept_names)
    pregnancy_concept_id = concept_ids_from_names('Patient pregnant')

		who_stages_criteria = concept_ids_from_names('Who stages criteria present')

		ActiveRecord::Base.connection.select_all(
			<<~SQL
			SELECT t.patient_id FROM patient_program t
			INNER JOIN obs ON t.patient_id = obs.person_id
			WHERE date_enrolled BETWEEN #{@start_date} AND #{@end_date}
			AND ( (value_coded IN #{pregnancy_concept_id} AND concept_id IN #{who_stages_criteria} )
			OR (concept_id IN #{pregnancy_concept_ids} AND value_coded = #{yes_concept_id}))
			AND obs.voided = 0 AND t.voided = 0 AND DATE(obs_datetime) = DATE(date_enrolled) 
			AND obs.person_id IN #{patient_ids} GROUP BY patient_id;
		 	SQL
		)
	end

  def patients_with_side_effects(patient_ids)
    patient_ids = quote_array(patient_ids)
    malawi_art_side_effects_concept_ids = concept_ids_from_names(['Malawi ART side effects'])

    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT person_id FROM obs
        WHERE person_id IN #{patient_ids}
              AND obs_group_id IN (SELECT obs_id FROM obs
                                   WHERE obs_datetime = (SELECT MAX(obs_datetime) FROM obs
                                                         WHERE person_id = person_id
                                                               AND concept_id IN #{malawi_art_side_effects_concept_ids}
                                                               AND obs_datetime BETWEEN #{start_date} AND #{end_date}
                                                               AND voided = 0
                                                         LIMIT 1)
                                         AND person_id = person_id
                                         AND concept_id IN #{malawi_art_side_effects_concept_ids}
                                         AND voided = 0)
              AND value_coded = #{yes_concept_id}
              AND voided = 0
        GROUP BY person_id
      SQL
    )
  end

  # Stage defining conditions

  CURRENT_EPTB_CONCEPT_NAMES = ['EXTRAPULMONARY TUBERCULOSIS (EPTB)',
                                'PULMONARY TUBERCULOSIS',
                                'PULMONARY TUBERCULOSIS (CURRENT)'].freeze

  RETRO_EPTB_CONCEPT_NAMES = ['Pulmonary tuberculosis within the last 2 years',
                              'Ptb within the past two years'].freeze

  def patients_with_tb_in_last_2_years(patient_ids)
		# patients with current episode of tb
    patient_ids = quote_array(patient_ids)

    eptb_concept_ids = concept_ids_from_names(RETRO_EPTB_CONCEPT_NAMES)
		who_stages_criteria = concept_ids_from_names('Who stages criteria present')

		ActiveRecord::Base.connection.select_all(
			<<~SQL
			SELECT t.patient_id FROM patient_program t
			INNER JOIN obs ON t.patient_id = obs.person_id
			WHERE date_enrolled BETWEEN #{@start_date} AND #{@end_date}
			AND ( (value_coded IN #{eptb_concept_ids} AND concept_id IN #{who_stages_criteria} )
			OR (concept_id IN #{eptb_concept_ids} AND value_coded = #{yes_concept_id}))
			AND obs.voided = 0 AND t.voided = 0 AND DATE(obs_datetime) <= DATE(date_enrolled) 
			AND obs.person_id IN #{patient_ids} GROUP BY patient_id;
			SQL
		)
  end

  def kaposis_sarcoma_patients(patient_ids)
		# Kaposis Sarcoma
    patient_ids = quote_array(patient_ids)

    eptb_concept_ids = concept_ids_from_names('KAPOSIS SARCOMA')
		who_stages_criteria = concept_ids_from_names('Who stages criteria present')

		ActiveRecord::Base.connection.select_all(
			<<~SQL
			SELECT t.patient_id FROM patient_program t
			INNER JOIN obs ON t.patient_id = obs.person_id
			WHERE date_enrolled BETWEEN #{@start_date} AND #{@end_date}
			AND ( (value_coded IN #{eptb_concept_ids} AND concept_id IN #{who_stages_criteria} )
			OR (concept_id IN #{eptb_concept_ids} AND value_coded = #{yes_concept_id}))
			AND obs.voided = 0 AND t.voided = 0 AND DATE(obs_datetime) <= DATE(date_enrolled) 
			AND obs.person_id IN #{patient_ids} GROUP BY patient_id;
			SQL
		)
  end
  
def re_initiated_on_art(patient_ids)
    patient_ids = quote_array(patient_ids)

    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT patient_id, re_initiated_check(patient_id, DATE(date_enrolled)) AS re_initiated
        FROM patient_program
        WHERE patient_id IN #{patient_ids} AND program_id = #{hiv_program_id}
        AND date_enrolled BETWEEN #{@start_date} AND #{@end_date}
      SQL
    )
  end

  def patients_reason_for_starting_art(patient_ids)
    patient_ids = quote_array(patient_ids)

    ActiveRecord::Base.connection.select_all(
      <<~SQL
        SELECT e.patient_id, patient_reason_for_starting_art(e.patient_id) reason_for_starting_concept_id
        FROM patient_program e 
        WHERE e.date_enrolled <= #{@end_date} AND patient_id IN #{patient_ids} 
        AND program_id = #{hiv_program_id} GROUP BY e.patient_id;
      SQL
    )
  end

	def current_episode_of_tb(patient_ids)
		# CURRENT EPISODE OF TB
    patient_ids = quote_array(patient_ids)

    tb_concept_ids = concept_ids_from_names(CURRENT_EPTB_CONCEPT_NAMES)
		who_stages_criteria = concept_ids_from_names('Who stages criteria present')

		ActiveRecord::Base.connection.select_all(
			<<~SQL
			SELECT t.patient_id FROM patient_program t
			INNER JOIN obs ON t.patient_id = obs.person_id
			WHERE date_enrolled BETWEEN #{@start_date} AND #{@end_date}
			AND ( (value_coded IN #{tb_concept_ids} AND concept_id IN #{who_stages_criteria} )
			OR (concept_id IN #{tb_concept_ids} AND value_coded = #{yes_concept_id}))
			AND obs.voided = 0 AND t.voided = 0 AND DATE(obs_datetime) <= DATE(date_enrolled) 
			AND obs.person_id IN #{patient_ids} GROUP BY patient_id;
			SQL
		)
	end






  def quote_atom(atom)
    ActiveRecord::Base.connection.quote(atom)
  end

  def quote_array(array)
    quoted_array = array.map { |item| ActiveRecord::Base.connection.quote(item) }
    "(#{quoted_array.join(', ')})"
  end

  def hiv_program_id
    @hiv_program_id ||= quote_atom(Program.find_by_name('HIV Program').program_id)
  end

  def on_arvs_state_id
    @on_arvs_state_id ||= quote_atom(ProgramWorkflowState.find_by(concept: concept('On ARVs')).id)
  end

  def who_stages_criteria_concept_id
    @who_stages_criteria_concept_id ||= quote_atom(concept('Who stages criteria present').concept_id)
  end

  def yes_concept_id
    @yes_concept_id ||= quote_atom(concept('Yes').concept_id)
  end

  def concept_ids_from_names(names)
    quote_array(ConceptName.where(name: names).collect(&:concept_id))
  end
  
end
