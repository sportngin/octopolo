require_relative "../scripts"
require_relative "../pull_request_merger"

module Octopolo
  module Scripts
    class ViewPr
      include CLIWrapper

      attr_accessor :pull_request_id

      def self.execute
        new.execute
      end

      # Public: Perform the script
      def execute
        current = GitHub::PullRequest.current

        if current
          cli.say "Opening Pull Request #{current.number}"
          cli.open current.url
        end
      end
    end
  end
end
