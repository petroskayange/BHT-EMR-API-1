class CreateReportingEncounters < ActiveRecord::Migration[5.2]
  def change
    create_table :reporting_encounters, primary_key: :encounter_id do |t|
      t.references    :program, references: :program, null: false 
      t.references    :patient, references: :patient, null: false
      t.date          :encounter_date, null: false
      t.boolean       :voided, default: 0, null: false
      t.integer       :voided_by  
      t.datetime      :date_voided
      t.string        :void_reason

      t.datetime      :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime      :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
  end

  def down
    drop_table :reporting_encounters
  end

end
