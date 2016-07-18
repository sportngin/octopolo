require_relative "../scripts"
require_relative "../scripts/issue"
require_relative "../github"
require_relative "../pivotal/story_commenter"
require_relative "../jira/story_commenter"

module Octopolo
  module Scripts
    class PullRequest < Issue
      attr_accessor :pull_request
      attr_accessor :destination_branch

      alias_method :issue, :pull_request

      def self.execute(destination_branch=nil, options={})
        new(destination_branch, options).execute
      end

      def initialize(destination_branch=nil, options={})
        @destination_branch = destination_branch || default_destination_branch
        @options = options
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
          update_github_labels_from_jira
          open_in_browser
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
          editor: options[:editor]
        }
      end
      private :pull_request_attributes

      def update_github_labels_from_jira
        matching_labels = []
        Octopolo::GitHub::Label.all.each do |github_label|
          matching_labels << github_label if jira_issue_labels.include?(github_label.name)
        end
        issue.add_labels(matching_labels)
      end
      protected :update_github_labels_from_jira

      def jira_issue_labels
        @labels ||= jira_issues.map(&:labels).flatten
      end
      protected :jira_issue_labels

      def jira_issues
        jira_ids.each_with_object([]) do |id, issues|
          issues << Jiralicious::Issue.find(id)
        end
      end
      protected :jira_issues

    end
  end
end
