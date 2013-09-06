require "octopolo/zapier"

module Octopolo
  module Zapier
    class PullRequestPoster
      attr_accessor :prefix
      attr_accessor :endpoints

      # Public: Initialize a new PullRequestPoster
      #
      # prefix - A String with the filename prefix to look for
      # endpoints - An Array of Zapier endpoint IDs
      def initialize(prefix, endpoints)
        self.prefix = prefix
        self.endpoints = endpoints
      end

      # Public: Post Pull Requests to Zapier
      def perform
        json_files.each do |file|
          post file
          delete file
        end
      end

      # Public: Find the Zapier-encoded JSON files in the current directory
      #
      # Returns an array of Strings with the file names
      def json_files
        Dir.glob(".#{prefix}-*.json")
      end

      # Public: Post the given JSON file to each Zapier endpoint
      #
      # file - Path to JSON file to post
      def post file
        endpoints.each do |zap_id|
          CLI.perform_quietly "curl -H 'Content-Type: application/json' -X POST -d @#{file} #{Zapier.endpoint zap_id}"
        end
      end

      # Public: Delete the given JSON file
      #
      # file - Path to the JSON file to delete
      #
      # Will not delete the file if not one of the JSON files it knows to look for
      def delete file
        CLI.perform "rm #{file}" if json_files.include? file
      end
    end
  end
end
