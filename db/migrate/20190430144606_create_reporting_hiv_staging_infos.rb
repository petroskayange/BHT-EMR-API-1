class CreateReportingHivStagingInfos < ActiveRecord::Migration[5.2]
  def change
    create_table :reporting_hiv_staging_infos, primary_key: :staging_id do |t|
      t.references :encounter, references: :reporting_encounters, null: false
      t.string     :arv_number
      t.date       :start_date, null: false
      t.date       :date_enrolled, null: false
      t.boolean    :transfer_in, default: 0, null: false
      t.boolean    :re_initiated, default: 0, null: false
      t.integer    :age_at_initiation, null: false
      t.integer    :age_in_days_at_initiation, null: false
      t.references :reason_for_starting, references: :concept, null: false
      t.references :who_stage, references: :concept, null: false
      t.boolean    :voided, default: 0, null: false
      t.integer    :voided_by
      t.datetime   :date_voided
      t.string     :void_reason

      t.datetime   :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime   :updated_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    rename_column :reporting_hiv_staging_infos, :reason_for_starting_id, :reason_for_starting
    rename_column :reporting_hiv_staging_infos, :who_stage_id, :who_stage
  end

  def down
    drop_table :reporting_hiv_staging_infos
  end

end
