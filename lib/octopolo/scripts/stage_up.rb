require "octopolo/scripts"
require "octopolo/pull_request_merger"

module Octopolo
  module Scripts
    class StageUp < Clamp::Command
      include CLIWrapper

      parameter "PULL_REQUEST_ID", "The ID of the pull request to merge into staging" do |s|
        Integer(s)
      end

      # Public: Perform the script
      def execute
        PullRequestMerger.perform Git::STAGING_PREFIX, pull_request_id
      end
    end
  end
end
