# frozen_string_literal: true

# Calculate checksums using Luhn's algorithm
module Luhn
  def self.checksum(number)
    # This is Luhn's algorithm for checksums
    # http://en.wikipedia.org/wiki/Luhn_algorithm
    # Same algorithm used by PIH (except they allow characters)
    number = number.to_s
    number = number.split(//).collect(&:to_i)
    parity = number.length % 2

    sum = 0
    number.each_with_index do |digit, index|
      digit *= 2 if index % 2 == parity
      digit -= 9 if digit > 9
      sum += digit
    end

    checkdigit = 0
    checkdigit += 1 while ((sum + checkdigit) % 10) != 0
    checkdigit
  end
end
