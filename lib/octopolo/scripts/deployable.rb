require_relative "../scripts"
require_relative "../pull_request_merger"
require_relative "../github/label"

module Octopolo
  module Scripts
    class Deployable
      include CLIWrapper
      include ConfigWrapper

      attr_accessor :pull_request_id

      def self.execute(pull_request_id=nil)
        new(pull_request_id).execute
      end

      def self.deployable_label
        Octopolo::GitHub::Label.new("deployable", "428BCA")
      end

      def initialize(pull_request_id=nil)
        @pull_request_id = pull_request_id
      end

      # Public: Perform the script
      def execute
        self.pull_request_id ||= cli.prompt("Pull Request ID: ")
        merge_and_label
      end

      def merge_and_label
        if config.deployable_label
          ensure_label_was_created
        else
          PullRequestMerger.perform Git::DEPLOYABLE_PREFIX, Integer(@pull_request_id), :user_notifications => config.user_notifications
        end
      end

      def ensure_label_was_created
        begin
          Octopolo::GitHub::Label.add_to_pull(Integer(@pull_request_id), Deployable.deployable_label)
          unless PullRequestMerger.perform Git::DEPLOYABLE_PREFIX, Integer(@pull_request_id), :user_notifications => config.user_notifications
             Octopolo::GitHub::Label.remove_from_pull(Integer(@pull_request_id), Deployable.deployable_label)
          end
        rescue Octokit::Error
          cli.say("Unable to mark as deployable, please try command again")
        end
      end

    end 
  end
end
