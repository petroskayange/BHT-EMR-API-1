# frozen_string_literal: true

module HtsService::Validator
  def self.validate_username(username)
    HtsProviderUsername.where(username: username).exists?
  end
end
