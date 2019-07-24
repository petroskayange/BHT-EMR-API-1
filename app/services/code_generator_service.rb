# frozen_string_literal: true

module CodeGeneratorService
  GENERATORS = {
    'HTC PROGRAM' => HTSService::CodeGenerator
  }.freeze

  def self.find_generator(program_id)
    program = Program.find(program_id)
    GENERATORS[program.name.upcase]
  end
end
