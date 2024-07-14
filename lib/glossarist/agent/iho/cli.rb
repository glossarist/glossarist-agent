require "thor"
require_relative "downloader"
require_relative "generator"

module Glossarist
  module Agent
    module Iho
      class Cli < Thor
        desc "retrieve-concepts", "Download IHO CSV files and generate concepts"
        option :output, type: :string, default: "./output", aliases: "-o", desc: "Directory to output generated files"
        option :cache, type: :string, default: "~/.glossarist-agent/cache", aliases: "-c", desc: "Directory to store cached files"
        option :fetch, type: :boolean, default: true, desc: "Fetch new data (default: true)"

        def retrieve_concepts
          cache_dir = File.expand_path(options[:cache])
          output_dir = File.expand_path(options[:output])
          fetch = options[:fetch]

          downloader = Downloader.new(cache_dir, fetch: fetch)
          downloader.download_csv_files

          generator = Generator.new(cache_dir, output_dir)
          generator.save_to_files
        end
      end
    end
  end
end
