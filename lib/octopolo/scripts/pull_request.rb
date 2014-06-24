require_relative "../scripts"
require_relative "../github/pull_request"
require_relative "../pivotal/story_commenter"

desc "Create a pull request from the current branch to the application's designated deploy branch."
command 'pull-request' do |c|
  config = Octopolo::Config.parse

  c.desc "Branch to create the pull request against"
  c.flag [:d, :dest, :destination], :arg_name => "destination_branch", :default_value => config.deploy_branch

  c.action do |global_options, options, args|
    options = global_options.merge(options)
    Octopolo::Scripts::AcceptPull.execute options[:destination_branch]
  end
end

module Octopolo
  module Scripts
    class PullRequest
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      attr_accessor :title
      attr_accessor :pull_request
      attr_accessor :pivotal_ids
      attr_accessor :destination_branch

      def self.execute(destination_branch=nil)
        new(destination_branch).execute
      end

      def initialize(destination_branch=nil)
        @destination_branch = destination_branch || default_destination_branch
      end

      def default_destination_branch
        config.deploy_branch
      end

      def execute
        GitHub.connect do
          ask_questionaire
          create_pull_request
          update_pivotal
          open_pull_request
        end
      end

      # Private: Ask questions to create a pull request
      def ask_questionaire
        alert_reserved_and_exit if git.reserved_branch?
        announce
        ask_title
        ask_pivotal_ids
      end
      private :ask_questionaire

      # Private: Announce to the user the branches the pull request will reference
      def announce
        cli.say "Preparing a pull request for #{config.github_repo}/#{git.current_branch} to #{config.github_repo}/#{destination_branch}."
      end
      private :announce

      # Private: Announces that the current branch is reserved and exits with a fail status
      def alert_reserved_and_exit
        cli.say "The current branch #{config.github_repo}/#{git.current_branch} is a reserved branch and can not have pull requests."
        exit 1
      end
      private :alert_reserved_and_exit

      # Private: Ask for a title for the pull request
      def ask_title
        self.title = cli.prompt "Title:"
      end
      private :ask_title

      # Private: Ask for a Pivotal Tracker story IDs
      def ask_pivotal_ids
        self.pivotal_ids = cli.prompt("Pivotal Tracker story ID(s):").split(/[\s,]+/)
      end
      private :ask_pivotal_ids

      # Private: Create the pull request
      #
      # Returns a GitHub::PullRequest object
      def create_pull_request
        self.pull_request = GitHub::PullRequest.create config.github_repo, pull_request_attributes
      end
      private :create_pull_request

      # Private: The attributes to send to create the pull request
      #
      # Returns a Hash
      def pull_request_attributes
        {
          title: title,
          destination_branch: destination_branch,
          source_branch: git.current_branch,
          pivotal_ids: pivotal_ids,
        }
      end
      private :pull_request_attributes

      # Private: Handle the newly created pull request
      def open_pull_request
        cli.copy_to_clipboard pull_request.url
        cli.open pull_request.url
      end
      private :open_pull_request

      def update_pivotal
        pivotal_ids.each do |story_id|
          Pivotal::StoryCommenter.new(story_id, pull_request.url).perform
        end
      end
      private :update_pivotal

    end
  end
end
