require_relative "../renderer"
require 'tempfile'

module Octopolo
  module GitHub
    class PullRequestCreator
      include ConfigWrapper
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
        options[:title] || raise(MissingAttribute)
      end

      # Public: The Pivotal Tracker story IDs associated with the pull request
      #
      # Returns an Array of Strings
      def pivotal_ids
        options[:pivotal_ids] || []
      end

      # Public: Jira Issue IDs associated with the pull request
      #
      # Returns an Array of Strings
      def jira_ids
        options[:jira_ids] || []
      end

      # Public: Jira Url associated with the pull request
      #
      # Returns Jira Url
      def jira_url
        config.jira_url
      end

      # Public: The body (primary copy) of the pull request
      #
      # Returns a String
      def body
        output = Renderer.render Renderer::PULL_REQUEST_BODY, body_locals
        output = edit_body(output) if options[:editor]
        output
      end

      def edit_body(body)
        return body unless ENV['EDITOR']

        # Open the file, write the contents, and close it
        tempfile = Tempfile.new('octopolo_pull_request')
        tempfile.write(body)
        tempfile.close

        # Allow the user to edit the file
        system "#{ENV['EDITOR']} #{tempfile.path}"

        # Reopen the file, read the contents, and delete it
        tempfile.open
        output = tempfile.read
        tempfile.unlink

        output
      end

      # Public: The local variables to pass into the template
      def body_locals
        {
          pivotal_ids: pivotal_ids,
          jira_ids: jira_ids,
          jira_url: jira_url,
        }
      end

      MissingAttribute = Class.new(StandardError)
      NotYetCreated = Class.new(StandardError)
      CannotCreate = Class.new(StandardError)
    end
  end
end
