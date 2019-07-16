# frozen_string_literal: true

require 'securerandom'

FactoryBot.define do
  factory :program do
    name { SecureRandom.alphanumeric(20) }
    association :concept
    creator { 1 }
    date_created { Time.now }
  end
end
