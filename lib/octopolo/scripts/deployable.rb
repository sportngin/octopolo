require_relative "../scripts"
require_relative "../pull_request_merger"

arg :pull_request_id
desc 'Merges PR into the deployable branch'
command 'deployable' do |c|
  c.action do |global_options, options, args|
    Octopolo::Scripts::Deployable.execute args.first
  end
end

module Octopolo
  module Scripts
    class Deployable
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
        PullRequestMerger.perform Git::DEPLOYABLE_PREFIX, Integer(@pull_request_id), { notify_automation: true }
      end
    end
  end
end
