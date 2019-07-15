# frozen_string_literal: true

class Register < ApplicationRecord
  include Voidable

  remap_voidable_interface(voided: :closed,
                           void_reason: :close_reason,
                           date_voided: :date_closed,
                           voided_by: :closed_by)

  has_and_belongs_to_many :encounters
end
