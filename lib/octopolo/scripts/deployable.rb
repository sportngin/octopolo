require_relative "../scripts"
require_relative "../pull_request_merger"

module Octopolo
  module Scripts
    class Deployable
      include CLIWrapper
      include ConfigWrapper

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
        PullRequestMerger.perform Git::DEPLOYABLE_PREFIX, Integer(@pull_request_id), :user_notifications => config.user_notifications
      end
    end
  end
end
