class CreateReportingVitals < ActiveRecord::Migration[5.2]
  def change
    create_table :reporting_vitals, primary_key: :vitals_id do |t|
      t.references :encounter, references: :reporting_encounters, null: false
      t.references :concept, references: :concept, null: false
      t.float      :value_numeric, null: false
      t.string     :value_text
      t.boolean    :voided, default: 0, null: false
      t.integer    :voided_by
      t.datetime   :date_voided
      t.string     :void_reason

      t.datetime   :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime   :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
  end

  def down
    drop_table :reporting_vitals
  end
end
