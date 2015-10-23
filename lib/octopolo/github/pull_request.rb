require_relative "issue"
require_relative "../week"
require "octokit"

module Octopolo
  module GitHub
    class PullRequest < Issue

      include CLIWrapper

      # Public: All closed pull requests for a given repo
      #
      # repo_name - Full name ("account/repo") of the repo in question
      #
      # Returns an Array of PullRequest objects
      def self.closed repo_name
        GitHub.pull_requests(repo_name, "closed").map do |data|
          new repo_name, data.number, data
        end
      end

      # Public: Create a pull request for the given repo
      #
      # repo_name - Full name ("account/repo") of the repo in question
      # options - Hash of pull request information
      #   title: Title of the pull request
      #   description: Brief description of the pull request
      #   release: Boolean indicating if the pull request is for Release
      #   destination_branch: Which branch to merge into
      #   source_branch: Which branch to be merged
      #
      # Returns a PullRequest instance
      def self.create repo_name, options
        # create via the API
        creator = PullRequestCreator.perform(repo_name, options)
        # wrap in our class
        new repo_name, creator.number, creator.data
      end

      def data
        @data ||= GitHub.pull_request(repo_name, number)
      rescue Octokit::NotFound
        raise NotFound
      end

      def branch
        data.head.ref
      end

      def mergeable?
        data.mergeable
      end

      def week
        Week.parse data.closed_at
      end

      def commenter_names
        exclude_octopolo_user (comments.map{ |comment| GitHub::User.new(comment.user.login).author_name }.uniq - author_names)
      end

      def author_names
        exclude_octopolo_user commits.map(&:author_name).uniq
      end

      def commits
        @commits ||= Commit.for_pull_request self
      end

      def self.current
        pulls = GitHub.pull_requests(repo_name, :head => Git.current_branch)
        if pulls.length != 1
          cli.say "Multiple pull requests found for branch #{Git.current_branch}" if pulls.length > 1
          cli.say "No pull request found for branch #{Git.current_branch}" if pulls.length < 1
          return nil
        else
          pulls.first
        end
      end

    end
  end
end
