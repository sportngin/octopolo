require_relative "../git"
require_relative "../github"
require_relative "../github/pull_request"
require_relative "../scripts"

module Octopolo
  module Scripts
    class AcceptPull
      include Base
      include GitWrapper
      include ConfigWrapper
      include CLIWrapper

      attr_accessor :pull_request_id

      def self.execute(pull_request_id)
        pull_request_id ||= Integer(cli.prompt "Pull Request ID: ")
        new(pull_request_id).execute
      end

      def initialize(pull_request_id)
        @pull_request_id = pull_request_id
      end

      # Public: Perform the script
      def execute
        GitHub.connect do
          pull_request = GitHub::PullRequest.new(config.github_repo, pull_request_id)
          merge pull_request
          update_changelog pull_request
        end
      rescue GitHub::PullRequest::NotFound
        cli.say "Unable to find a pull request #{pull_request_id} for #{config.github_repo}. Please verify."
      end

      def merge pull_request
        Git.fetch
        if pull_request.mergeable?
          cli.perform "git merge --no-ff origin/#{pull_request.branch} -m \"Merge pull request ##{pull_request_id} from origin/#{pull_request.branch}\""
        else
          cli.say "There is a merge conflict with this branch and #{config.deploy_branch}."
          cli.say "Please update this branch with #{config.deploy_branch} or perform the merge manually and fix any conflicts"
        end
      end

      def changelog
        @changelog ||= Changelog.new
      end

      def update_changelog pull_request
        title = pull_request.title
        authors = pull_request.author_names
        commenters = pull_request.commenter_names
        url = pull_request.url

        changelog.open do |log|
          log.puts "* #{title}"
          log.puts
          log.puts "  > #{authors.join(", ")}: #{commenters.join(', ')}: #{url}"
          log.puts
        end
      end

    end
  end
end

