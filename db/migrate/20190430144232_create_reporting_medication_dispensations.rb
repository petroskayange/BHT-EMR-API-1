class CreateReportingMedicationDispensations < ActiveRecord::Migration[5.2]
  def change
    create_table :reporting_medication_dispensations, primary_key: :dispensation_id do |t|
      t.references :encounter, references: :reporting_encounters, null: false
      t.references :prescription, references: :reporting_medication_prescriptions, null: false
      t.float      :quantity
      t.boolean    :voided, default: 0, null: false
      t.integer    :voided_by
      t.datetime   :date_voided
      t.string     :void_reason

      t.datetime   :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime   :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
  end

  def down
    drop_table :reporting_medication_dispensations
  end
end
