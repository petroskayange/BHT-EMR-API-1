# frozen_string_literal: true

module ObservationSearchService
  # Search for all observations sharing an encounter with an
  # observation matching given criteria.
  #
  # Example
  #   >>> ObservationSearchService.find_observation_siblings(concept_id: 9757, value_text: 'EC-1234-1')
  #   => Returns all observation belonging to same encounter as that matching the above.
  def self.find_sibling_observations(search_params)
    encounter_ids = Observation.select(:encounter_id).where(search_params).collect(&:encounter_id)
    return [] if encounter_ids.empty?

    Observation.where(encounter_id: encounter_ids).where.not(search_params)
  end
end
