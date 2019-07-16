# frozen_string_literal: true

class Register < ApplicationRecord
  include Voidable

  remap_voidable_interface(voided: :closed,
                           void_reason: :close_reason,
                           date_voided: :date_closed,
                           voided_by: :closed_by)

  belongs_to :service_delivery_point, class_name: 'RegisterServiceDeliveryPoint'
  belongs_to :location_type, class_name: 'RegisterLocationType'

  has_and_belongs_to_many :encounters

  validates_presence_of :register_type, :service_delivery_point_id, :location_type_id
end
