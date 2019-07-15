FactoryBot.define do
  factory :register do
    uuid { "MyString" }
    number { "MyString" }
    location_type_id { 1 }
    service_delivery_point_id { 1 }
    location_id { 1 }
    register_type { "MyString" }
    closed { false }
    date_closed { "2019-07-12 13:48:09" }
    closed_by { 1 }
    close_reason { "MyString" }
    date_created { "2019-07-12 13:48:09" }
  end
end
