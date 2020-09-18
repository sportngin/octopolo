require_relative "issue_creator"
require_relative "../renderer"
require 'tempfile'

module Octopolo
  module GitHub
    class PullRequestCreator < IssueCreator

      # Public: Create a pull request for the given repo with the given options
      #
      # repo_name - Full name ("account/repo") of the repo in question
      # options - Hash of pull request information
      #   title: Title of the pull request
      #   destination_branch: Which branch to merge into
      #   source_branch: Which branch to be merged
      def initialize repo_name, options
        super(repo_name, options)
      end

      # Public: Create the pull request
      #
      # Returns an array with the first element being the pull request's
      # number, the second being a Mash of the response from GitHub's API
      def perform
        result = GitHub.create_pull_request(
          repo_name,
          destination_branch,
          source_branch,
          title,
          body,
          {draft: draft}
        )
        # capture the information
        self.number = result.number
        self.data = result
      rescue => e
        raise CannotCreate, e.message
      end

      # Public: Draft Pull request
      #
      # Returns a boolean that marks the PR a draft PR
      def draft
        !!options[:draft]
      end

      # Public: Branch to merge the pull request into
      #
      # Returns a String with the branch name
      def destination_branch
        options[:destination_branch] || raise(MissingAttribute)
      end

      # Public: Branch to merge into the destination branch
      #
      # Returns a String with the branch name
      def source_branch
        options[:source_branch] || raise(MissingAttribute)
      end

      # Public: Rendering template for body property
      #
      # Returns Name of template file
      def renderer_template
        Renderer::PULL_REQUEST_BODY
      end

      # Public: Temporary file for body editing
      #
      # Returns Name of temporary file
      def body_edit_temp_name
        'octopolo_pull_request'
      end

    end
  end
end
