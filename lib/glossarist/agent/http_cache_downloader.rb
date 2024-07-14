require "faraday"
require "fileutils"
require "json"
require "time"

module Glossarist
  module Agent
    class HttpCacheDownloader
      CACHE_EXPIRY_DAYS = 7

      def initialize(cache_dir, fetch: true)
        @cache_dir = cache_dir
        @fetch = fetch
        FileUtils.mkdir_p(@cache_dir)
        @client = Faraday.new { |faraday| faraday.adapter Faraday.default_adapter }
      end

      def download_files(url_map)
        url_map.each { |filename, url| process_file(filename, url) }
        puts "All files are up to date in the cache."
      end

      private

      def process_file(filename, url)
        cache_path = File.join(@cache_dir, filename)
        metadata_path = "#{cache_path}.metadata.json"

        if cache_exists?(cache_path, metadata_path)
          handle_existing_cache(filename, url, cache_path, metadata_path)
        else
          handle_missing_cache(filename, url, cache_path, metadata_path)
        end
      end

      def cache_exists?(cache_path, metadata_path)
        File.exist?(cache_path) && File.exist?(metadata_path)
      end

      def handle_existing_cache(filename, url, cache_path, metadata_path)
        if !@fetch
          puts "Using cached #{filename} (fetch disabled)"
        elsif should_download?(url, cache_path, metadata_path)
          download_file(url, cache_path, metadata_path)
        else
          puts "Using cached #{filename} (not modified or within #{CACHE_EXPIRY_DAYS}-day period)"
        end
      end

      def handle_missing_cache(filename, url, cache_path, metadata_path)
        if !@fetch
          puts "Cache file or metadata missing for #{filename}. Skipping as fetch is disabled."
        else
          puts "Cache file or metadata missing for #{filename}. Downloading..."
          download_file(url, cache_path, metadata_path)
        end
      end

      def should_download?(url, cache_path, metadata_path)
        return false unless @fetch

        metadata = read_metadata(metadata_path)
        headers = fetch_headers(url)
        server_etag = headers["ETag"]

        if server_etag
          handle_etag(metadata, server_etag)
        else
          handle_no_etag(metadata)
        end
      end

      def handle_etag(metadata, server_etag)
        if metadata["etag"] && server_etag != metadata["etag"]
          puts "ETag mismatch. Stored: #{metadata["etag"]}, Server: #{server_etag}"
          true
        else
          false
        end
      end

      def handle_no_etag(metadata)
        puts "Server did not provide an ETag. Checking file age..."
        file_older_than_days?(metadata["download_time"], CACHE_EXPIRY_DAYS)
      end

      def file_older_than_days?(download_time, days)
        return true unless download_time

        file_age = (Time.now - Time.parse(download_time)) / (24 * 60 * 60)
        if file_age > days
          puts "Cache file is older than #{days} days. Will download."
          true
        else
          puts "Cache file is within #{days} days old. Using cached version."
          false
        end
      end

      def fetch_headers(url)
        @client.head(url).headers
      rescue Faraday::Error => e
        puts "Error fetching headers for #{url}: #{e.message}"
        {}
      end

      def download_file(url, cache_path, metadata_path)
        puts "Downloading #{File.basename(cache_path)}..."
        response = @client.get(url)

        if response.success?
          write_file_and_metadata(response, url, cache_path, metadata_path)
        else
          puts "Error downloading #{url}: HTTP #{response.status}"
        end
      rescue Faraday::Error => e
        puts "Error downloading #{url}: #{e.message}"
      end

      def write_file_and_metadata(response, url, cache_path, metadata_path)
        File.write(cache_path, response.body)

        metadata = {
          "url" => url,
          "download_time" => Time.now.iso8601,
          "etag" => response.headers["ETag"],
        }

        File.write(metadata_path, JSON.pretty_generate(metadata))
        puts "Updated metadata for #{File.basename(cache_path)}"
      end

      def read_metadata(metadata_path)
        File.exist?(metadata_path) ? JSON.parse(File.read(metadata_path)) : {}
      rescue JSON::ParserError
        puts "Error parsing metadata file. Treating as empty."
        {}
      end
    end
  end
end
