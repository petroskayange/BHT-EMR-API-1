module ARTService
  module Reports
    module Pepfar

      class TxRTT
        attr_reader :start_date, :end_date

        def initialize(start_date:, end_date:, **_kwargs)
          @start_date = start_date.to_date
          @end_date = end_date.to_date
        end

        def find_report
          tx_rtt
        end

        def data
          return tx_rtt
        end

        private

        def tx_rtt
          tx_rtt_patients.each_with_object({}) do |patient, data|
            patient_id = patient.patient_id
            age_group = patient.age_group
            gender = patient.gender&.upcase&.first || 'Unknown'

            if data[age_group].blank?
              data[age_group]= {}
              data[age_group][gender] = []
            elsif data[age_group][gender].blank?
              data[age_group][gender] = []
            end

            data[age_group][gender] << patient_id
          end
        end

        # Retrieves all patients who defaulted at some point and returned
        # to care within the reporting period.
        #
        # NOTE: Defaulted is being defined as having a difference of at
        # least 30 days between a drug run out date and the next
        # treatment date.
        def tx_rtt_patients
          patients_who_received_art.keep_if do |patient|
            on_art_date_ranges = parse_str_on_art_periods(patient.on_art_date_ranges)
            pp on_art_date_ranges

            patient_defaulted_and_restarted?(patient.patient_id, on_art_date_ranges)
          end
        end

        # Retrieves all patients who received ART within the reporting period.
        def patients_who_received_art
          Patient.find_by_sql(
            <<~SQL
              SELECT patient.patient_id AS patient_id,
                     person.birthdate AS birthdate,
                     person.gender AS gender,
                     cohort_disaggregated_age_group(person.birthdate, DATE('#{end_date}')) AS age_group,
                     GROUP_CONCAT(CONCAT(orders.start_date,
                                         ' - ',
                                         COALESCE(orders.auto_expire_date,
                                                  (SELECT value_datetime FROM obs
                                                   WHERE person_id = patient.patient_id
                                                     AND DATE(obs_datetime) = DATE(orders.start_date)
                                                     AND concept_id = #{appointment_date_concept_id}
                                                     AND voided = 0
                                                   LIMIT 1),
                                                   DATE_ADD(orders.start_date, INTERVAL drug_order.quantity DAY)))
                                  ORDER BY orders.start_date ASC
                                  SEPARATOR ',') AS on_art_date_ranges,
                     CAST(patient_date_enrolled(patient.patient_id) AS DATE) AS date_enrolled
              FROM patient_program AS patient
              INNER JOIN person ON patient.patient_id = person.person_id
              INNER JOIN orders ON patient.patient_id = orders.patient_id
              INNER JOIN drug_order ON orders.order_id = drug_order.order_id
              WHERE patient.program_id = #{hiv_program_id}
                AND patient.voided = 0
                AND orders.order_type_id = #{drug_order_type_id}
                AND orders.start_date BETWEEN '#{start_date}' AND '#{end_date}'
                AND orders.voided = 0
                AND drug_order.drug_inventory_id IN (#{arv_drugs})
                AND drug_order.quantity > 0
              GROUP BY patient.patient_id
              HAVING date_enrolled < '#{start_date}'
            SQL
          )
        end

        # Parses on treatment periods string returned by #patients_who_received_art
        def parse_str_on_art_periods(str_periods)
          parse_str_period = lambda do |str_period|
            dates = str_period.split(' - ')

            OpenStruct.new(start_date: dates[0].to_date,
                           auto_expire_date: dates[1].to_date)
          end

          return [] unless str_periods

          parsed_periods = str_periods.split(',').map(&parse_str_period)
          Set.new(parsed_periods).to_a.sort_by(&:start_date)
        end

        # Check if patient defaulted in between the on treatment periods
        # or prior to the initial period.
        #
        # Parameters:
        #   patient_id: Is the id of the patient in the database
        #   periods_on_art: A sorted (ascending) list of drug order start and auto_expire_dates.
        def patient_defaulted_and_restarted?(patient_id, periods_on_art)
          return false if periods_on_art.empty?

          return true if patient_defaulted_in_between_treatment?(periods_on_art)

          patient_defaulted_prior_to_treatment?(patient_id, periods_on_art[0].start_date)
        end

        # Check if patient defaulted in between treatment periods.
        #
        # See: patient_defaulted_and_restarted?
        def patient_defaulted_in_between_treatment?(periods_on_art)
          pp periods_on_art

          (0...periods_on_art.size - 1).each do |i|
            if thirty_days_after?(periods_on_art[i].auto_expire_date,
                                  periods_on_art[i + 1].start_date)
              return true
            end
          end

          false
        end

        # Check if there is a gap of more than 30 days between given treatment
        # date and patient's last drug_run_out date.
        def patient_defaulted_prior_to_treatment?(patient_id, treatment_date)
          drug_run_out_date = Order.joins(:drug_order)
                                   .merge(DrugOrder.where(drug_inventory_id: arv_drugs))
                                   .where('patient_id = ? AND auto_expire_date < ?', patient_id, treatment_date)
                                   .order(auto_expire_date: :desc)
                                   .first
                                   &.auto_expire_date
                                   &.to_date

          return false unless drug_run_out_date

          thirty_days_after?(drug_run_out_date, treatment_date)
        end

        # Checks if next date is at least 30 days after the initial date.
        def thirty_days_after?(initial_date, next_date)
          return false unless initial_date && next_date

          (next_date - initial_date) >= 30
        end

        def hiv_program_id
          ARTService::Constants::PROGRAM_ID
        end

        def drug_order_type_id
          OrderType.find_by_name('Drug order').id
        end

        def arv_drugs
          Drug.arv_drugs.select(:drug_id).to_sql
        end

        def appointment_date_concept_id
          ConceptName.find_by_name('Appointment date').concept_id
        end

      #   def get_potential_tx_rtt_clients
      #     return ActiveRecord::Base.connection.select_all <<-SQL
      #     select
      #       `p`.`patient_id` AS `patient_id`, pe.birthdate, pe.gender,
      #        cast(patient_date_enrolled(`p`.`patient_id`) as date) AS `date_enrolled`
      #     from
      #       ((`patient_program` `p`
      #       left join `person` `pe` ON ((`pe`.`person_id` = `p`.`patient_id`))
      #       left join `patient_state` `s` ON ((`p`.`patient_program_id` = `s`.`patient_program_id`)))
      #       left join `person` ON ((`person`.`person_id` = `p`.`patient_id`)))
      #     where
      #       ((`p`.`voided` = 0)
      #           and (`s`.`voided` = 0)
      #           and (`p`.`program_id` = 1)
      #           and (`s`.`state` = 7))
      #           and (pepfar_patient_outcome(p.patient_id, DATE('#{@end_date.to_date}')) = 'Defaulted'
      #           or pepfar_patient_outcome(p.patient_id, DATE('#{(@start_date.to_date - 1.day)}')) = 'Defaulted')
      #     group by `p`.`patient_id`
      #     HAVING date_enrolled IS NOT NULL AND DATE(date_enrolled) < DATE('#{@start_date}');
      #     SQL

      #   end
      end
    end
  end
end
