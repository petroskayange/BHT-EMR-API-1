# frozen_string_literal: true

class ConceptSet < ApplicationRecord
  self.table_name = :concept_set
  self.primary_key = :concept_set_id

  belongs_to :set, foreign_key: :concept_set, class_name: 'Concept'
  belongs_to :concept

  def self.find_by_name(name)
    concepts = ConceptName.where(name: name).select(:concept_id)

    where(set: concepts)
      .includes(concept: [:concept_names])
  end
end
