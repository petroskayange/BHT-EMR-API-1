class CreateReportingOutcomes < ActiveRecord::Migration[5.2]
  def change
    create_table :reporting_outcomes, primary_key: :outcome_id do |t|
      t.references :encounter, references: :reporting_encounters, null: false
      t.references :concept, references: :concept, null: false
      t.date       :outcome_date
      t.boolean    :voided, default: 0, null: false
      t.integer    :voided_by
      t.datetime   :date_voided
      t.string     :void_reason

      t.datetime   :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime   :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

  end

  def down
    drop_table :reporting_outcomes
  end
end
