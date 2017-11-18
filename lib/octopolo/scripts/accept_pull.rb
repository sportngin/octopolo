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

      attr_accessor :pull_request_id

      def self.execute(pull_request_id, options)
        pull_request_id ||= Integer(cli.prompt "Pull Request ID: ")
        new(pull_request_id, options).execute
      end

      def initialize(pull_request_id, options={})
        @pull_request_id = pull_request_id
        @force = options[:force]
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
          if pull_request.status_checks_passed? || @force
            cli.perform "OVERCOMMIT_DISABLE=1 git merge --no-ff origin/#{pull_request.branch} -m \"Merge pull request ##{pull_request_id} from origin/#{pull_request.branch}\""
          else
            cli.say 'Status checks have not passed on this pull request.'
            exit!
          end
        else
          cli.say "There is a merge conflict with this branch and #{config.deploy_branch}."
          cli.say "Please update this branch with #{config.deploy_branch} or perform the merge manually and fix any conflicts"
          exit!
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

