require_relative "../scripts"
require_relative "../pull_request_merger"

module Octopolo
  module Scripts
    class StageUp
      include CLIWrapper

      attr_accessor :pull_request_id, :options

      def self.execute(pull_request_id=nil, options)
        new(pull_request_id, options).execute
      end

      def initialize(pull_request_id=nil, options={})
        @pull_request_id = pull_request_id
        @options = options
      end

      # Public: Perform the script
      def execute
        if (!self.pull_request_id)
          current = GitHub::PullRequest.current
          self.pull_request_id = current.number if current
        end
        self.pull_request_id ||= cli.prompt("Pull Request ID: ")
        PullRequestMerger.perform Git::STAGING_PREFIX, Integer(pull_request_id)
      end
    end
  end
end
