# frozen_string_literal: true

module Glossarist
  module Agent
    class Concept
      attr_reader :managed_concept

      def initialize(data)
        @managed_concept = Glossarist::ManagedConcept.new
        populate_concept(data)
      end

      private

      def populate_concept(data)
        @managed_concept.id = data[:id]
        @managed_concept.groups = data[:groups] || []

        localized_concept = Glossarist::LocalizedConcept.new
        localized_concept.language_code = "eng"
        localized_concept.definition = [Glossarist::DetailedDefinition.new(content: data[:definition])]
        localized_concept.designations = [Glossarist::Designation::Base.from_h({ "type" => "expression", "designation" => data[:term] })]

        @managed_concept.localizations = { "eng" => localized_concept }
      end
    end
  end
end
