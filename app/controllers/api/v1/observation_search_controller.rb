# frozen_string_literal: true

class Api::V1::ObservationSearchController < ApplicationController
  # Finds sibling observations to an observation that matches
  # query parameters
  def find_sibling_observations
    search_params = params.permit(%i[concept_id value_text value_datetime value_numeric value_drug])
    observations = search_service.find_sibling_observations(search_params)

    render json: paginate(observations)
  end

  private

  def search_service
    ObservationSearchService
  end
end
