# frozen_string_literal: true

require 'securerandom'

FactoryBot.define do
  factory :register do
    uuid { SecureRandom.uuid }
    number { 'Foobar' }
    location_type_id { create(:register_location_type).id }
    service_delivery_point_id { create(:register_service_delivery_point).id }
    location_id { 1 }
    register_type { 'Foobar' }
    closed { false }
    date_created { '2019-07-12 13:48:09' }
  end
end
