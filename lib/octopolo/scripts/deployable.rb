require_relative "../scripts"
require_relative "../pull_request_merger"
require_relative "../github/pull_request"
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
        Octopolo::GitHub::Label.new(name: "deployable", color: "428BCA")
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
        pull_request = Octopolo::GitHub::PullRequest.new(config.github_repo, @pull_request_id)
        begin
          pull_request.add_labels(Deployable.deployable_label)
          unless PullRequestMerger.perform Git::DEPLOYABLE_PREFIX, Integer(@pull_request_id), :user_notifications => config.user_notifications
             pull_request.remove_labels(Deployable.deployable_label)
          end
        rescue Octokit::Error

          cli.say("Unable to mark as deployable, please try command again")
        end
      end

    end 
  end
end
