require_relative "../scripts"
require_relative "../pull_request_merger"
require_relative "../github"

module Octopolo
  module Scripts
    class Deployable
      include CLIWrapper
      include ConfigWrapper

      attr_accessor :pull_request_id

      def self.execute(pull_request_id=nil, options={})
          # testing shit
          # more testing

        new(pull_request_id, options).execute
      end

      def self.deployable_label
        Octopolo::GitHub::Label.new(name: "deployable", color: "428BCA")
      end

      def initialize(pull_request_id=nil, options={})
        @pull_request_id = pull_request_id
        @force = options[:force]
      end

      # Public: Perform the script
      def execute
        if (!self.pull_request_id)
          current = GitHub::PullRequest.current
          self.pull_request_id = current.number if current
        end
        self.pull_request_id ||= cli.prompt("Pull Request ID: ")
        GitHub.connect do
          unless deployable? || @force
            CLI.say 'Pull request status checks have not passed. Cannot be marked deployable.'
            exit!
          end
          if config.deployable_label
            with_labelling do
              merge
            end
          else
            merge
          end
        end
      end

      def merge
        r = PullRequestMerger.perform Git::DEPLOYABLE_PREFIX, Integer(@pull_request_id), :user_notifications => config.user_notifications
        if r == true
          puts "\n\n\n\nRESPONSE WAS TRUE\n\n\n\n"
        else
          puts "\n\n\n\nRESPONSE WAS FALSE\n\n\n\n"
        end
        return r
      end
      private :merge

      def with_labelling(&block)
        pull_request.add_labels(Deployable.deployable_label)
        unless yield
          sleep 5
          pull_request.remove_labels(Deployable.deployable_label)
        end
      end
      private :with_labelling

      def deployable?
        pull_request.mergeable? && pull_request.status_checks_passed?
      end
      private :deployable?

      def pull_request
        @pull_request ||= Octopolo::GitHub::PullRequest.new(config.github_repo, @pull_request_id)
      end
      private :pull_request
    end
  end
end
