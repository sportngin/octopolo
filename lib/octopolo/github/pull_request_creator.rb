require "octopolo/renderer"

module Octopolo
  module GitHub
    class PullRequestCreator
      # for instantiating the pull request creator
      attr_accessor :repo_name
      attr_accessor :options
      # for caputuring the created pull request information
      attr_accessor :number
      attr_accessor :pull_request_data

      # Public: Create a pull request for the given repo with the given options
      #
      # repo_name - Full name ("account/repo") of the repo in question
      # options - Hash of pull request information
      #   title: Title of the pull request
      #   description: Brief description of the pull request
      #   release: Boolean indicating if the pull request is for Release
      #   destination_branch: Which branch to merge into
      #   source_branch: Which branch to be merged
      def initialize repo_name, options
        self.repo_name = repo_name
        self.options = options
      end

      # Public: Create a pull request for the given repo with the given options
      #
      # repo_name - Full name ("account/repo") of the repo in question
      # options - Hash of pull request information
      #   title: Title of the pull request
      #   description: Brief description of the pull request
      #   release: Boolean indicating if the pull request is for Release
      #   destination_branch: Which branch to merge into
      #   source_branch: Which branch to be merged
      #
      # Returns the PullRequestCreator instance
      def self.perform repo_name, options
        new(repo_name, options).tap do |creator|
          creator.perform
        end
      end

      # Public: Create the pull request
      #
      # Returns an array with the first element being the pull request's
      # number, the second being a Mash of the response from GitHub's API
      def perform
        result = GitHub.create_pull_request(repo_name, destination_branch, source_branch, title, body)
        # capture the information
        self.number = result.number
        self.pull_request_data = result
      rescue => e
        raise CannotCreate, e.message
      end

      # Public: The created pull request's details
      def pull_request_data
        @pull_request_data || raise(NotYetCreated)
      end

      # Public: The created pull request's number
      def number
        @number || raise(NotYetCreated)
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

      # Public: Title of the pull request
      #
      # Returns a String with the title
      def title
        raw_title = options[:title]
        raise MissingAttribute if raw_title.nil?

        if release?
          "Release: #{raw_title}"
        else
          raw_title
        end
      end

      # Public: A brief description of the pull request
      #
      # Returns a String with the description
      def description
        options[:description] || raise(MissingAttribute)
      end

      # Public: The Pivotal Tracker story IDs associated with the pull request
      #
      # Returns an Array of Strings
      def pivotal_ids
        options[:pivotal_ids] || []
      end

      # Public: Whether the pull request is for a Release
      #
      # Returns a Boolean
      def release?
        options[:release]
      end

      # Public: The body (primary copy) of the pull request
      #
      # Returns a String
      def body
        Renderer.render Renderer::PULL_REQUEST_BODY, body_locals
      end

      # Public: The local variables to pass into the template
      def body_locals
        {
          description: description,
          pivotal_ids: pivotal_ids,
        }
      end

      MissingAttribute = Class.new(StandardError)
      NotYetCreated = Class.new(StandardError)
      CannotCreate = Class.new(StandardError)
    end
  end
end
