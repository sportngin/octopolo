require_relative "../scripts"
require_relative "../github/pull_request"
require_relative "../pivotal/story_commenter"
require_relative "../jira/story_commenter"
require_relative "../github/label"

module Octopolo
  module Scripts
    class PullRequest
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      attr_accessor :title
      attr_accessor :pull_request
      attr_accessor :pivotal_ids
      attr_accessor :jira_ids
      attr_accessor :destination_branch
      attr_accessor :label

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
          update_jira
          update_label
          open_pull_request
        end
      end

      # Private: Ask questions to create a pull request
      def ask_questionaire
        alert_reserved_and_exit if git.reserved_branch?
        announce
        ask_title
        ask_label
        ask_pivotal_ids if config.use_pivotal_tracker
        ask_jira_ids if config.use_jira
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

      # Private: Ask for a label for the pull request
      def ask_label
        choices = Octopolo::GitHub::Label.get_names(Octopolo::GitHub::Label.all).unshift("Don't know yet")
        self.label = cli.ask("Label:", choices)
      end
      private :ask_label

      # Private: Ask for a Pivotal Tracker story IDs
      def ask_pivotal_ids
        self.pivotal_ids = cli.prompt("Pivotal Tracker story ID(s):").split(/[\s,]+/)
      end
      private :ask_pivotal_ids

      # Private: Ask for a Pivotal Tracker story IDs
      def ask_jira_ids
        self.jira_ids = cli.prompt("Jira story ID(s):").split(/[\s,]+/)
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
          jira_ids: jira_ids,
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
        end if pivotal_ids
      end
      private :update_pivotal

      def update_jira
        jira_ids.each do |story_id|
          Jira::StoryCommenter.new(story_id, pull_request.url).perform
        end if jira_ids
      end
      private :update_jira

      def update_label
        Octopolo::GitHub::Label.add_label(config.github_repo, pull_request.id, label)
      end
      private :update_label

    end
  end
end
