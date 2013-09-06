require "octopolo/zapier"
require "json"
require "date" # for Date.today

module Octopolo
  module Zapier
    class PullRequestEncoder
      attr_accessor :pull_request
      attr_accessor :prefix

      # Public: Instantiate a new PullRequestEncoder object
      #
      # pull_request - The Octopolo::GitHub::PullRequest object
      # prefix - A String with the prefix to assign to the encoded JSON
      #
      # Returns an instance of PullRequestEncoder
      def initialize(pull_request, prefix)
        self.pull_request = pull_request
        self.prefix = prefix
      end

      # Public: Perform the encoding
      def perform
        write_json
      end

      # Public: Write the Pull Request details to JSON
      def write_json
        json_file.puts encoded_json
        json_file.close
      end

      # Public: The file for the given Pull Request
      #
      # Returns an instance of File
      def json_file
        @json_file ||= File.open ".#{prefix}-#{pull_request.number}.json", "w"
      end

      # Public: The Pull Request attributes Zapier cares about
      #
      # Returns a String containing JSON of these attributes
      def encoded_json
        {
          appname: pull_request.human_app_name,
          authors: pull_request.author_names.join(", "),
          commenters: pull_request.commenter_names.join(", "),
          title: pull_request.title,
          url: pull_request.url,
          issue_urls: pull_request.issue_urls.join(", "),
          color: trello_color,
          accepted_on: Date.today,
        }.to_json
      end

      # Public: The trello card color for this pull request
      #
      # NOTE It's a little ugly shoving this here. Maybe TrelloColor.new(pull_request) is more appropriate?
      #
      # Returns a String
      def trello_color
        if pull_request.bug?
          "red"
        elsif pull_request.release?
          "green"
        else
          "blue"
        end
      end
    end
  end
end
