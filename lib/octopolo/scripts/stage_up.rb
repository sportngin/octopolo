require_relative "../scripts"
require_relative "../pull_request_merger"

module Octopolo
  module Scripts
    class StageUp
      include CLIWrapper

      attr_accessor :pull_request_id

      def self.execute(pull_request_id=nil)
        new(pull_request_id).execute
      end

      def initialize(pull_request_id=nil)
        @pull_request_id = pull_request_id
      end

      # Public: Perform the script
      def execute
        self.pull_request_id ||= cli.prompt("Pull Request ID: ")
        PullRequestMerger.perform Git::STAGING_PREFIX, Integer(pull_request_id)
      end
    end
  end
end
