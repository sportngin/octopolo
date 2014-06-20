require "octopolo/git"
require "octopolo/github"
require "octopolo/github/pull_request"
require "octopolo/scripts"

module Octopolo
  module Scripts
    class AcceptPull < Clamp::Command
      include GitWrapper
      include ConfigWrapper
      include CLIWrapper

      banner "Accept pull requests. Merges the given pull request into master and updates the changelog."

      parameter "PULL_REQUEST_ID", "The ID of the pull request to accept" do |pr_id|
        Integer(pr_id)
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
          cli.perform "git merge --no-ff origin/#{pull_request.branch}"
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

