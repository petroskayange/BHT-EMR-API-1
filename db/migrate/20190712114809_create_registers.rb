class CreateRegisters < ActiveRecord::Migration[5.2]
  def change
    create_table :registers do |t|
      t.string :uuid, null: false
      t.string :number, null: false
      t.integer :location_type_id, null: false
      t.integer :service_delivery_point_id, null: false
      t.integer :location_id, null: false
      t.string :register_type, null: false
      t.boolean :closed, default: -> { 'FALSE' }
      t.datetime :date_closed
      t.integer :closed_by
      t.string :close_reason
      t.datetime :date_created, null: false, default: -> { 'CURRENT_TIMESTAMP()' }

      t.timestamps
    end
  end
end
