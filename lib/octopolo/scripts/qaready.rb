require "octopolo/scripts"
require "octopolo/pull_request_merger"

module Octopolo
  module Scripts
    class Qaready < Clamp::Command
      include CLIWrapper

      parameter "PULL_REQUEST_ID", "The ID of the pull request to mark deployable" do |s|
        Integer(s)
      end

      # Public: Perform the script
      def execute
        PullRequestMerger.perform Git::DEPLOYABLE_PREFIX, pull_request_id, { notify_automation: true }
      end
    end
  end
end
