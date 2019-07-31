# frozen_string_literal: true

class ValidationsService
  VALIDATORS = {
    'HTC PROGRAM' => HtsService::Validator
  }.freeze

  def self.validator(program_id)
    program = Program.find(program_id)
    validator = VALIDATORS[program.name.upcase]
    raise NotFoundError, "Validator for program ##{program_id} not found" unless validator

    validator
  end
end
