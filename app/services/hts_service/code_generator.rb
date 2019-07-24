# frozen_string_literal: true

module HTSService::CodeGenerator
  GENERATOR_METHODS = {
    entry_code: -> { SecureRandom.alphanumeric }
  }.freeze

  def self.generate(code_type)
    method = GENERATOR_METHODS[code_type.to_sym]
    raise NotFoundError, "HTS code generator for #{code_type} not found" unless method

    method.call
  end
end
