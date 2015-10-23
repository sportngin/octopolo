require_relative "../scripts"
require_relative "../github"

module Octopolo
  module Scripts
    class Signoff
      include ConfigWrapper
      include CLIWrapper

      attr_accessor :pull_request_id
      attr_accessor :pull_request
      attr_accessor :signoff_type

      TYPES = [
        "code review only",
        "QA only",
        "both code review and QA",
      ]

      def self.execute(pull_request_id=nil)
        new(pull_request_id).execute
      end

      def initialize(pull_request_id=nil)
        @pull_request_id = pull_request_id
        @pull_request_id ||= GitHub::PullRequest.current.try(:number)
        @pull_request_id ||= cli.prompt("Pull Request ID: ")
      end

      def execute
        preamble
        ask_signoff_type
        write_comment
        open_pull_request
      rescue WrongChoice
        retry
      end

      # Private: Display information about the pull request
      def preamble
        cli.say %Q(Please review "#{pull_request.title}":)
        cli.say pull_request.url
        cli.spacer_line
      end
      private :preamble

      # Private: Ask which type of signoff to perform
      def ask_signoff_type
        self.signoff_type = cli.ask "Which type of signoff are you performing?", TYPES
      end
      private :ask_signoff_type

      # Private: Find the pull request to be signed off on
      #
      # Returns a GitHub::PullRequest
      def pull_request
        @pull_request ||= GitHub::PullRequest.new config.github_repo, Integer(pull_request_id)
      end
      private :pull_request
      private :pull_request=

      # Private: The body of the comment for the given signoff
      #
      # Returns a String
      def comment_body
        "Signing off on **#{signoff_type}**."
      end
      private :comment_body

      # Private: Submit a comment to the pull request
      def write_comment
        pull_request.write_comment comment_body
      end
      private :write_comment

      # Private: Open the pull request in the browser
      def open_pull_request
        cli.open pull_request.url
      end

      WrongChoice = Class.new StandardError
    end
  end
end

# vim: set ft=ruby: #
