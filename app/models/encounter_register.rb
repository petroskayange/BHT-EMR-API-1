# frozen_string_literal: true

class EncounterRegister < ApplicationRecord
  belongs_to :encounter
  belongs_to :register
end
