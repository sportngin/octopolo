require_relative "../scripts"
require_relative "../github"
require_relative "../pivotal/story_commenter"
require_relative "../jira/story_commenter"

module Octopolo
  module Scripts
    class Issue
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      attr_accessor :title
      attr_accessor :issue
      attr_accessor :pivotal_ids
      attr_accessor :jira_ids
      attr_accessor :label
      attr_accessor :options

      def self.execute(options={})
        new(options).execute
      end

      def initialize(options={})
        @options = options
      end

      def execute
        GitHub.connect do
          ask_questionaire
          create_issue
          update_pivotal
          update_jira
          update_label
          open_issue
        end
      end

      # Private: Ask questions to create an issue
      def ask_questionaire
        announce
        ask_title
        ask_label
        ask_pivotal_ids if config.use_pivotal_tracker
        ask_jira_ids if config.use_jira
      end
      private :ask_questionaire

      # Private: Announce to the user the branches the issue will reference
      def announce
        cli.say "Preparing an issue for #{config.github_repo}."
      end
      private :announce

      # Private: Ask for a title for the issue
      def ask_title
        self.title = cli.prompt "Title:"
      end
      private :ask_title

      # Private: Ask for a label for the issue
      def ask_label
        choices = Octopolo::GitHub::Label.get_names(label_choices).concat(["None"])
        response = cli.ask(label_prompt, choices)
        self.label = Hash[label_choices.map{|l| [l.name,l]}][response]
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

      # Private: Create the issue
      #
      # Returns a GitHub::Issue object
      def create_issue
        self.issue = GitHub::Issue.create config.github_repo, issue_attributes
      end
      private :create_issue

      # Private: The attributes to send to create the issue
      #
      # Returns a Hash
      def issue_attributes
        {
          title: title,
          pivotal_ids: pivotal_ids,
          jira_ids: jira_ids,
          editor: options[:editor]
        }
      end
      private :issue_attributes

      # Private: Handle the newly created issue
      def open_issue
        cli.copy_to_clipboard issue.url
        cli.open issue.url
      end
      private :open_issue

      def label_prompt
        'Label:'
      end

      def label_choices
        Octopolo::GitHub::Label.all
      end

      def update_pivotal
        pivotal_ids.each do |story_id|
          Pivotal::StoryCommenter.new(story_id, issue.url).perform
        end if pivotal_ids
      end
      private :update_pivotal

      def update_jira
        jira_ids.each do |story_id|
          Jira::StoryCommenter.new(story_id, issue.url).perform
        end if jira_ids
      end
      private :update_jira

      def update_label
        issue.add_labels(label) if label
      end
      private :update_label

    end
  end
end
