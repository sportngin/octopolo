require "octokit"

module Octopolo
  module GitHub
    class Issue
      attr_accessor :data
      attr_accessor :repo_name
      attr_accessor :number

      def initialize repo_name, number, data = nil
        raise MissingParameter if repo_name.nil? or number.nil?

        self.repo_name = repo_name
        self.number = number
        self.data = data
      end

      # Public: Create a issue for the given repo
      #
      # repo_name - Full name ("account/repo") of the repo in question
      # options - Hash of issue information
      #   title: Title of the issue
      #   description: Brief description of the issue
      #
      # Returns a Issue instance
      def self.create(repo_name, options)
        # create via the API
        creator = IssueCreator.perform(repo_name, options)
        # wrap in our class
        new repo_name, creator.number, creator.data
      end

      def data
        @data ||= GitHub.issue(repo_name, number)
      rescue Octokit::NotFound
        raise NotFound
      end

      def title
        data.title
      end

      def url
        data.html_url
      end

      def commenter_names
        exclude_octopolo_user (comments.map{ |comment| GitHub::User.new(comment.user.login).author_name }.uniq)
      end

      def exclude_octopolo_user(user_list)
        user_list.reject{|u| GitHub.excluded_users.include?(u) }
      end

      def body
        data.body || ""
      end

      def external_urls
        # extract http and https URLs from the body
        URI.extract body, %w(http https)
      end

      def human_app_name
        repo = repo_name.split("/").last
        repo.split("_").map(&:capitalize).join(" ")
      end

      def comments
        @comments ||= GitHub.issue_comments(repo_name, number)
      end

      # Public: Add a comment to the issue
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
        GitHub.add_labels_to_issue(repo_name, number, built_labels.map(&:name) )
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
