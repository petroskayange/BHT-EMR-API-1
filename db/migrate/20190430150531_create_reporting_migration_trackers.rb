class CreateReportingMigrationTrackers < ActiveRecord::Migration[5.2]
  def change
    create_table :reporting_migration_trackers do |t|
      t.datetime    :updated_at, null: false
    end
  end

  def down
    drop_table :reporting_migration_trackers
  end
end
