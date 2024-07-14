# frozen_string_literal: true

module Glossarist
  module Agent
    class Collection
      attr_reader :collection

      def initialize
        @collection = Glossarist::ManagedConceptCollection.new
      end

      def add_concept(data)
        concept = Concept.new(data)
        @collection << concept.managed_concept
      end

      def save_to_files(output_path)
        @collection.save_to_files(output_path)
      end
    end
  end
end
