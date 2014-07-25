require_relative "../github"
require_relative "commit"
require_relative "pull_request_creator"
require_relative "user"
require_relative "../week"
require_relative "label"
require "octokit"

module Octopolo
  module GitHub
    class PullRequest
      attr_accessor :pull_request_data
      attr_accessor :repo_name
      attr_accessor :number

      def initialize repo_name, number, pull_request_data = nil
        raise MissingParameter if repo_name.nil? or number.nil?

        self.repo_name = repo_name
        self.number = number
        self.pull_request_data = pull_request_data
      end

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
        new repo_name, creator.number, creator.pull_request_data
      end

      def pull_request_data
        @pull_request_data ||= GitHub.pull_request(repo_name, number)
      rescue Octokit::NotFound
        raise NotFound
      end

      def title
        pull_request_data.title
      end

      # def number
      #   pull_request_data.number
      # end 

      def url
        pull_request_data.html_url
      end

      def branch
        pull_request_data.head.ref
      end

      def mergeable?
        pull_request_data.mergeable
      end

      def week
        Week.parse pull_request_data.closed_at
      end

      def commenter_names
        exlude_octopolo_user (comments.map{ |comment| GitHub::User.new(comment.user.login).author_name }.uniq - author_names)
      end

      def author_names
        exlude_octopolo_user commits.map(&:author_name).uniq
      end

      def exlude_octopolo_user(user_list)
        user_list.reject{|u| GitHub.excluded_users.include?(u) }
      end

      def body
        pull_request_data.body || ""
      end

      def external_urls
        # extract http and https URLs from the body
        URI.extract body, %w(http https)
      end

      def human_app_name
        repo = repo_name.split("/").last
        repo.split("_").map(&:capitalize).join(" ")
      end

      def commits
        @commits ||= Commit.for_pull_request self
      end

      def comments
        @comments ||= GitHub.issue_comments(repo_name, number)
      end

      # Public: Add a comment to the pull request
      #
      # message - A String containing the desired comment body
      def write_comment(message)
        GitHub.add_comment repo_name, number, ":octocat: #{message}"
      rescue Octokit::UnprocessableEntity => error
        raise CommentFailed, "Unable to write the comment: '#{error.message}'"
      end

      # Public: Adds labels to a pull-request
      #
      # labels - label objects, can be a single label, an array of labels,
      #          or a list of labels
      def add_labels(*labels)
        built_labels = Label.build_label_array(labels)
        GitHub.add_labels_to_pull(repo_name, number, built_labels.map(&:name) )
      end

      # Public: Removes labels from a pull-request, 
      #
      # labels - label objects, can be a single label, an array of labels,
      #          or a list of labels
      def remove_labels(*labels)
        Label.build_label_array(labels).each do |built_label| 
          GitHub.remove_label(repo_name, number, built_label.name)
        end
      end

      MissingParameter = Class.new StandardError
      NotFound = Class.new StandardError
      CommentFailed = Class.new StandardError
    end
  end
end
