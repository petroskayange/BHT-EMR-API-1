# frozen_string_literal: true

# A service for generating various sequences.
class SequencesService
  # Returns next accession number to be used when creating an observation.
  def self.next_accession_number
    last_accn_number = Observation.where('accession_number IS NOT NULL')\
                                  .order(Arel.sql('accession_number + 0'))\
                                  .last\
                                  .accession_number\
                                  .to_s rescue '00' # the rescue is for the initial accession number start up
    last_accn_number_with_no_chk_dgt = last_accn_number.chop.to_i
    new_accn_number_with_no_chk_dgt = last_accn_number_with_no_chk_dgt + 1
    chk_dgt = PatientIdentifier.calculate_checkdigit(new_accn_number_with_no_chk_dgt)
    new_accn_number = "#{new_accn_number_with_no_chk_dgt}#{chk_dgt}"

    new_accn_number.to_i
  end
end
