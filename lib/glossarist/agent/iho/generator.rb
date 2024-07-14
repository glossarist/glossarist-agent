require "glossarist"
require_relative "bilingual_table"
require_relative "downloader"

module Glossarist
  module Agent
    module Iho
      class Generator
        attr_accessor :language_tables, :simple_concepts

        def initialize(cache_dir, output_path)
          @cache_dir = cache_dir
          @output_path = output_path
          FileUtils.mkdir_p(@output_path)
        end

        def collection
          return @collection if @collection

          parse_language_tables
          build_simple_concepts
          convert_to_glossarist

          @collection
        end

        def parse_language_tables
          return @language_tables if @language_tables

          @language_tables = {}
          Dir.glob(File.join(@cache_dir, "*.csv")).map do |file|
            lang_code = Downloader.lang_code_by_filename(File.basename(file))

            table = BilingualTable.new(file_path: file, lang_code: lang_code).tap do |table|
              table.process
            end

            @language_tables[lang_code] = table
          end

          @language_tables
        end

        def build_simple_concepts
          return @simple_concepts if @simple_concepts

          @simple_concepts = {}
          build_english_concepts
          build_other_language_concepts
          @simple_concepts
        end

        def convert_to_glossarist
          @collection = ::Glossarist::ManagedConceptCollection.new
          @collection.managed_concepts = create_managed_concepts
        end

        def save_to_files
          collection.save_to_files(@output_path)
          puts "Concepts generated and saved to #{@output_path}"
        end

        private

        private

        def build_english_concepts
          @language_tables[:fra].concepts_eng.each do |concept|
            @simple_concepts[concept.id] = { eng: concept_data(concept) }
          end
        end

        def build_other_language_concepts
          @language_tables.each do |lang_code, table|
            table.concepts_other.each do |concept|
              @simple_concepts[concept.id][lang_code] = concept_data(concept)
            end
          end
        end

        def concept_data(concept)
          {
            term: concept.term,
            definition: concept.definition,
          }
        end

        def create_managed_concepts
          @simple_concepts.map do |id, localized_concepts|
            create_managed_concept(id, localized_concepts)
          end
        end

        def create_managed_concept(id, localized_concepts)
          Glossarist::ManagedConcept.new(id: id).tap do |con|
            localized_concepts.each do |lang_code, data|
              con.add_localization(create_localized_concept(lang_code, data))
            end
          end
        end

        def create_localized_concept(lang_code, data)
          Glossarist::LocalizedConcept.new(
            "language_code" => lang_code.to_s,
            "terms" => [{
              "designation" => data[:term],
              "type" => "expression",
              "normative_status" => "preferred",
            }],
            "definition" => [{ "content" => data[:definition] }],
          )
        end
      end
    end
  end
end
