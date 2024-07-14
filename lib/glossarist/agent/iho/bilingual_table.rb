require "shale"
require "csv"

require "shale/adapter/csv"
unless Shale.csv_adapter
  Shale.csv_adapter = Shale::Adapter::CSV
end

module Glossarist
  module Agent
    module Iho
      class BilingualRow < Shale::Mapper
        attribute :eng_id, Shale::Type::String
        attribute :other_id, Shale::Type::String
        attribute :eng_term, Shale::Type::String
        attribute :other_term, Shale::Type::String
        attribute :eng_definition, Shale::Type::String
        attribute :other_definition, Shale::Type::String
      end

      class SimpleConcept < Shale::Mapper
        attribute :id, Shale::Type::String
        attribute :lang_code, Shale::Type::String
        attribute :term, Shale::Type::String
        attribute :definition, Shale::Type::String
      end

      class BilingualTable
        attr_accessor :file_path, :rows, :lang_code, :concepts_eng, :concepts_other

        def initialize(file_path:, lang_code:)
          @file_path = file_path
          @lang_code = lang_code
        end

        def process
          # @rows = []
          @rows = BilingualRow.from_csv(IO.read(@file_path))[1..-1]
          @concepts_eng = @rows.map do |bilingual_row|
            SimpleConcept.new(
              lang_code: :eng,
              id: bilingual_row.eng_id.strip,
              term: bilingual_row.eng_term.strip,
              definition: bilingual_row.eng_definition.strip,
            )
          end

          @concepts_other = @rows.map do |bilingual_row|
            SimpleConcept.new(
              lang_code: lang_code,
              id: bilingual_row.other_id.strip,
              term: bilingual_row.other_term.strip,
              definition: bilingual_row.other_definition.strip,
            )
          end
        end
      end
    end
  end
end
