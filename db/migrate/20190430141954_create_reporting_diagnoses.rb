class CreateReportingDiagnoses < ActiveRecord::Migration[5.2]
  def change
    create_table :reporting_diagnoses, primary_key: :diagnosis_id do |t|
      t.references :encounter, references: :reporting_encounters, null: false
      t.references :concept, references: :concept, null: false
      t.string     :value_text
      t.integer    :primary_diagnosis, null: false, default: 0
      t.boolean    :voided, default: 0, null: false
      t.integer    :voided_by
      t.datetime   :date_voided
      t.string     :void_reason

      t.datetime   :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime   :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
  end

  def down
    drop_table :reporting_diagnoses
  end
end
