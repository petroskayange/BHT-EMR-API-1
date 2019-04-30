class CreateReportingMedicationRegimen < ActiveRecord::Migration[5.2]
  def change
    create_table :reporting_medication_regimen, primary_key: :regimen_id do |t|
      t.references :encounter, references: :reporting_encounters, null: false
      t.string     :regimen, null: false
      t.boolean    :voided, default: 0, null: false
      t.integer    :voided_by
      t.datetime   :date_voided
      t.string     :void_reason

      t.datetime   :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime   :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
  end

  def down
    drop_table :reporting_medication_regimen
  end
end
