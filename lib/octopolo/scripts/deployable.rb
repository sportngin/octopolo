require_relative "../scripts"
require_relative "../pull_request_merger"
require_relative "../github"

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
        if config.deployable_label
          with_labelling do
            merge
          end
        else
          merge
        end
      end

      def merge
        PullRequestMerger.perform Git::DEPLOYABLE_PREFIX, Integer(@pull_request_id), :user_notifications => config.user_notifications
      end
      private :merge

      def with_labelling(&block)
        pull_request = Octopolo::GitHub::PullRequest.new(config.github_repo, @pull_request_id)
        begin
          pull_request.add_labels(Deployable.deployable_label)
          unless yield
             pull_request.remove_labels(Deployable.deployable_label)
          end
        rescue => e
          case e
          when Octokit::Unauthorized
            cli.say "Your stored credentials were rejected by GitHub. Run `bundle exec github-auth` to generate a new token."
          else
            cli.say "An unknown error occurred:  #{e.class.to_s}"
          end
        end
      end
      private :with_labelling
    end
  end
end
