require_relative "../git"
require_relative "../github"
require_relative "../scripts"
require_relative "../changelog"

module Octopolo
  module Scripts
    class AcceptPull
      include Base
      include GitWrapper
      include ConfigWrapper
      include CLIWrapper

      attr_accessor :pull_request_ids

      def self.execute(pull_request_ids)
        pull_request_ids ||= Integer(cli.prompt "Pull Request ID: ")
        new(pull_request_ids).execute
      end

      def initialize(pull_request_ids)
        self.pull_request_ids = Array(pull_request_ids)
      end

      # Public: Perform the script
      def execute
        GitHub.connect do
          Git.fetch
          pull_request_ids.each do |pull_request_id|
            begin
              pull_request = GitHub::PullRequest.new(config.github_repo, pull_request_id)

              if pull_request.mergeable?
                perform_merge(pull_request)
                update_changelog(pull_request)
              else
                cli.say "There is a merge conflict with this branch and #{config.deploy_branch}"
                cli.say "Please update this branch with #{config.deploy_branch} or perform the merge manually and fix any conflicts"
                exit 1
              end
            rescue GitHub::Issue::NotFound
              cli.say "Unable to find a pull request ##{pull_request_id} for #{config.github_repo}. Please verify."
              exit 1
            end
          end
        end
      end

    private

      def perform_merge(pull_request)
        cli.perform "git merge --no-ff origin/#{pull_request.branch} -m \"Merge pull request ##{pull_request.number} from origin/#{pull_request.branch}\""
      end

      def update_changelog(pull_request)
        title = pull_request.title
        authors = pull_request.author_names
        commenters = pull_request.commenter_names
        url = pull_request.url

        Changelog.open do |log|
          log.puts "* #{title}"
          log.puts
          log.puts "  > #{authors.join(", ")}: #{commenters.join(', ')}: #{url}"
          log.puts
        end
      end
    end
  end
end

