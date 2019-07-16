class CreateRegisterLocationTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :register_location_types do |t|
      t.string :name
      t.datetime :date_created, null: false, default: -> { 'CURRENT_TIMESTAMP()' }
    end
  end
end
