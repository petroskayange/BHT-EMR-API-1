class CreateEncounterRegisters < ActiveRecord::Migration[5.2]
  def change
    create_table :encounter_registers do |t|
      t.belongs_to :encounter, add_index: true
      t.belongs_to :register, add_index: true

      t.datetime :date_created, null: false, default: -> { 'CURRENT_TIMESTAMP()' }
      t.integer :creator, null: false
    end
  end
end
