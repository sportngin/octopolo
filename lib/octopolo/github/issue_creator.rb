require_relative "../renderer"
require 'tempfile'

module Octopolo
  module GitHub
    class IssueCreator
      include ConfigWrapper
      # for instantiating the issue creator
      attr_accessor :repo_name
      attr_accessor :options
      # for caputuring the created issue information
      attr_accessor :number
      attr_accessor :data

      # Public: Create a issue for the given repo with the given options
      #
      # repo_name - Full name ("account/repo") of the repo in question
      # options - Hash of issue information
      #   title: Title of the issue
      def initialize repo_name, options
        self.repo_name = repo_name
        self.options = options
      end

      # Public: Create a issue for the given repo with the given options
      #
      # repo_name - Full name ("account/repo") of the repo in question
      # options - Hash of issue information
      #   title: Title of the issue
      #
      # Returns the IssueCreator instance
      def self.perform repo_name, options
        new(repo_name, options).tap do |creator|
          creator.perform
        end
      end

      # Public: Create the issue
      #
      # Returns an array with the first element being the issue's
      # number, the second being a Mash of the response from GitHub's API
      def perform
        # labels option cannot be null due to https://github.com/octokit/octokit.rb/pull/538
        result = GitHub.create_issue(repo_name, title, body, labels: [])
        # capture the information
        self.number = result.number
        self.data = result
      rescue => e
        raise CannotCreate, e.message
      end

      # Public: The created resource's details
      def data
        @data || raise(NotYetCreated)
      end

      # Public: The created issue's number
      def number
        @number || raise(NotYetCreated)
      end

      # Public: Title of the issue
      #
      # Returns a String with the title
      def title
        options[:title] || raise(MissingAttribute)
      end

      # Public: The Pivotal Tracker story IDs associated with the issue
      #
      # Returns an Array of Strings
      def pivotal_ids
        options[:pivotal_ids] || []
      end

      # Public: Jira Issue IDs associated with the issue
      #
      # Returns an Array of Strings
      def jira_ids
        options[:jira_ids] || []
      end

      # Public: Jira Url associated with the issue
      #
      # Returns Jira Url
      def jira_url
        config.jira_url
      end

      # Public: Rendering template for body property
      #
      # Returns Name of template file
      def renderer_template
        Renderer::ISSUE_BODY
      end

      # Public: Temporary file for body editing
      #
      # Returns Name of temporary file
      def body_edit_temp_name
        'octopolo_issue'
      end


      # Public: The body (primary copy) of the issue
      #
      # Returns a String
      def body
        output = Renderer.render renderer_template, body_locals
        output = edit_body(output) if options[:editor]
        output
      end

      def edit_body(body)
        return body unless ENV['EDITOR']

        # Open the file, write the contents, and close it
        tempfile = Tempfile.new([body_edit_temp_name, '.md'])
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
