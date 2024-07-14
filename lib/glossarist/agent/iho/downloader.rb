require_relative "../http_cache_downloader"

module Glossarist
  module Agent
    module Iho
      class Downloader
        LANG_MAPPING = {
          fra: {
            "engFreView.csv" => "http://iho-ohi.net/S32/engFreView.php?operation=ecsv",
          },
          spa: {
            "engEspView.csv" => "http://iho-ohi.net/S32/engEspView.php?operation=ecsv",
          },
          zho: {
            "engChnView.csv" => "http://iho-ohi.net/S32/engChnView.php?operation=ecsv",
          },
          ind: {
            "engIndView.csv" => "http://iho-ohi.net/S32/engIndView.php?operation=ecsv",
          },
        }.freeze

        CSV_URLS = LANG_MAPPING.values.inject({}) do |acc, x|
          acc.merge!(x)
          acc
        end

        def initialize(cache_dir, fetch: true)
          @cache_downloader = HttpCacheDownloader.new(cache_dir, fetch: fetch)
        end

        def download_csv_files
          @cache_downloader.download_files(CSV_URLS)
        end

        def self.lang_code_by_filename(filename)
          LANG_MAPPING.each do |lang_code, files|
            return lang_code if files.key?(filename)
          end
          nil
        end
      end
    end
  end
end
