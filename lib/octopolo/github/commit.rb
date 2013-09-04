require "automation/github"
require "automation/github/user"

module Automation
  module GitHub
    class Commit
      attr_accessor :commit_data

      # Public: Instantiate a new Commit wrapper object
      #
      # commit_data - The GitHub API data about the commit
      def initialize commit_data
        self.commit_data = commit_data
      end

      # Public: Find commits for a given pull request
      #
      # pull_request - A PullRequest or other object responding to #repo_name
      #   and #number
      #
      # Returns an Array of Commit objects
      def self.for_pull_request pull_request
        GitHub.pull_request_commits(pull_request.repo_name, pull_request.number).map do |c|
          Commit.new c
        end
      end

      # Public: GitHub User that is the author of the commit
      #
      # Returns a Hashie::Mash object of the GitHub User
      def author
        GitHub::User.new(commit_data.author.login)
      rescue NoMethodError
        GitHub::User.new(GitHub::UNKNOWN_USER)
      end

      # Public: The name of the author of the commit
      #
      # Returns a String containing the author's name
      def author_name
        author.author_name
      end
    end
  end
end
