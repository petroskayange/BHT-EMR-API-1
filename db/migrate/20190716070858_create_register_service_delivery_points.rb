class CreateRegisterServiceDeliveryPoints < ActiveRecord::Migration[5.2]
  def change
    create_table :register_service_delivery_points do |t|
      t.string :name
      t.datetime :date_created, null: false, default: -> { 'CURRENT_TIMESTAMP()' }
    end
  end
end
