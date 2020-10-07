# frozen_string_literal: true

module ARTService
  module PrescriptionEngine
    class << self
      def patient_prescription_note(patient, on: nil)
        date = on || patient_recent_prescription_date(patient)

        return nil unless date

        drugs = patient_prescriptions(patient, on: date).map do |prescription|
          format_prescription(prescription)
        end

        return nil if drugs.empty?

        regimen = ARTService::PatientSummary.new(patient, date).current_regimen

        { regimen: regimen, date: date, drugs: drugs }
      end

      def patient_recent_prescription_date(patient, on: nil)
        date = on || Date.today

        Order.where(order_type: OrderType.where(name: 'Drug order'),
                    concept: ConceptSet.find_by_name('Antiretroviral drugs'),
                    patient: patient)
             .where(Order.arel_table[:start_date].lt(date + 1.day))
             .select('MAX(DATE(start_date)) AS start_date')
             .first
             &.start_date
      end

      def patient_prescriptions(patient, on: nil)
        on ||= Date.today

        DrugOrder.joins(:order)
                 .merge(Order.where(patient: patient,
                                    order_type: OrderType.where(name: 'Drug order'),
                                    concept: ConceptSet.find_by_name('Antiretroviral drugs'),
                                    start_date: on...(on + 1.day)))
                 .where(quantity: 0..Float::INFINITY)
                 .includes(:drug)
                 .select('orders.start_date, orders.auto_expire_date, drug_order.*')
      end

      private

      def drug_name(drug)
        drug.alternative_names.first&.name || drug.name
      end

      def format_prescription(prescription)
        {
          id: prescription.drug_inventory_id,
          name: drug_name(prescription.drug),
          quantity: prescription.quantity,
          equivalent_daily_dose: prescription.equivalent_daily_dose,
          start_date: prescription.start_date&.to_date,
          run_out_date: prescription.auto_expire_date&.to_date
        }
      end
    end
  end
end
