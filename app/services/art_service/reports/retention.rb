# frozen_string_literal: true

module ARTService
  module Reports
    # Retrieve patients who are completing their initial n-given months
    # on ART in the reporting period.
    #
    # Example: If n-months is specified as 6, then the report pulls out all
    # patients who are completing their 6th month on ART.
    class Retention
      attr_reader :start_date, :end_date, :months

      def initialize(start_date:, end_date:, months:, **_kwargs)
        @start_date = start_date
        @end_date = end_date
        @months = months.to_i
      end

      def find_report
        {
          retained: retained_patients.map do |patient|
            format_retained_patient(patient)
          end,

          all: all_patients.map do |patient|
            format_patient(patient)
          end
        }
      end

      def format_retained_patient(patient)
        {
          **format_patient(patient),
          end_date: patient.start_date + months.months
        }
      end

      def format_patient(patient)
        {
          patient_id: patient.patient_id,
          arv_number: patient.arv_number,
          gender: patient.gender&.upcase&.first,
          age_group: patient.age_group,
          start_date: patient.start_date
        }
      end

      # Pull all patients are completing their initial n-months of treatment in the current
      # reporting period.
      def retained_patients
        initial_orders_start_date = ActiveRecord::Base.connection.quote(start_date - months.months)
        initial_orders_end_date = ActiveRecord::Base.connection.quote(end_date - months.months)
        last_orders_start_date = ActiveRecord::Base.connection.quote(start_date)
        last_orders_end_date = ActiveRecord::Base.connection.quote(end_date)

        Order.find_by_sql(
          <<~SQL
            SELECT initial_order.patient_id AS patient_id,
                   initial_order.start_date AS start_date,
                   last_order.auto_expire_date AS auto_expire_date,
                   patient_identifier.identifier AS arv_number,
                   cohort_disaggregated_age_group(p.birthdate, DATE('#{@end_date}')) age_group,
                   p.gender gender
            FROM orders initial_order
              INNER JOIN encounter initial_encounter
                ON initial_encounter.encounter_id = initial_order.encounter_id AND initial_encounter.program_id = 1
              INNER JOIN orders last_order ON last_order.patient_id = initial_order.patient_id
              INNER JOIN encounter last_encounter ON last_encounter.encounter_id = last_order.encounter_id
              INNER JOIN person p ON p.person_id = initial_encounter.patient_id
              LEFT JOIN patient_identifier ON patient_identifier.patient_id = initial_order.patient_id
            WHERE initial_order.start_date BETWEEN #{initial_orders_start_date} AND #{initial_orders_end_date}
              AND initial_order.voided = 0
              AND initial_order.auto_expire_date IS NOT NULL
              AND initial_order.order_type_id = #{drug_order_type_id}
              AND last_order.auto_expire_date BETWEEN #{last_orders_start_date} AND #{last_orders_end_date}
              AND last_order.order_type_id = #{drug_order_type_id}
              AND last_order.voided = 0
              AND p.voided = 0
              AND initial_order.start_date = (
                SELECT MIN(start_date) FROM orders
                WHERE patient_id = initial_order.patient_id
                  AND start_date BETWEEN #{initial_orders_start_date} AND #{initial_orders_end_date}
                  AND order_type_id = #{drug_order_type_id}
                  AND voided = 0
              )
              AND initial_order.patient_id NOT IN (
                SELECT orders.patient_id
                FROM orders
                  INNER JOIN encounter
                    ON encounter.encounter_id = orders.encounter_id AND encounter.program_id = 1
                WHERE start_date < #{initial_orders_start_date}
                      AND order_type_id = #{drug_order_type_id}
                      AND orders.voided = 0
              )
            GROUP BY initial_order.patient_id
          SQL
        )
      end

      # Pull all patients who are supposed to be completing their initial n_months
      # of treatment in the current reporting period.
      def all_patients
        initial_order_start_date = ActiveRecord::Base.connection.quote(start_date - months.months)
        initial_order_end_date = ActiveRecord::Base.connection.quote(end_date - months.months)

        Order.find_by_sql(
          <<~SQL
            SELECT initial_order.patient_id AS patient_id,
                   initial_order.start_date AS start_date,
                   patient_identifier.identifier AS arv_number,
                   cohort_disaggregated_age_group(p.birthdate, DATE('#{@end_date}')) age_group,
                   p.gender gender
            FROM orders initial_order
              INNER JOIN encounter initial_encounter
                ON initial_encounter.encounter_id = initial_order.encounter_id
                AND initial_encounter.program_id = 1
              INNER JOIN person p ON p.person_id = initial_encounter.patient_id
              LEFT JOIN patient_identifier ON patient_identifier.patient_id = initial_order.patient_id
            WHERE initial_order.start_date BETWEEN #{initial_order_start_date} AND #{initial_order_end_date}
              AND initial_order.voided = 0
              AND initial_order.auto_expire_date IS NOT NULL
              AND initial_order.order_type_id = #{drug_order_type_id}
              AND p.voided = 0
              AND initial_order.start_date = (
                SELECT MIN(start_date) FROM orders
                WHERE patient_id = initial_order.patient_id
                  AND start_date BETWEEN #{initial_order_start_date} AND #{initial_order_end_date}
                  AND order_type_id = #{drug_order_type_id}
                  AND voided = 0
              )
              AND initial_order.patient_id NOT IN (
                SELECT orders.patient_id
                FROM orders
                  INNER JOIN encounter
                    ON encounter.encounter_id = orders.encounter_id
                    AND encounter.program_id = 1
                WHERE start_date < #{initial_order_start_date}
                  AND order_type_id = #{drug_order_type_id}
                  AND orders.voided = 0
              )
            GROUP BY initial_order.patient_id
          SQL
        )
      end

      def drug_order_type_id
        @drug_order_type_id ||= OrderType.find_by_name('Drug order').order_type_id
      end
    end
  end
end
