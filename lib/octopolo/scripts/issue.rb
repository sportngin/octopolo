require_relative "../scripts"
require_relative "../github"
require_relative "../github/issue"
require_relative "../github/issue_creator"
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
      attr_accessor :labels
      attr_accessor :options

      OPTIONAL_REQUIREMENTS = {ops_required: "ops-required", ux_required: "ux-required"}

      def self.execute(options={})
        new(options).execute
      end

      def initialize(options={})
        @options = options
        @labels = []
      end

      def execute
        GitHub.connect do
          ask_questionaire
          create_issue
          update_pivotal
          update_jira
          update_label
          open_in_browser
        end
      end

      # Protected: Ask questions to create an issue
      def ask_questionaire
        announce
        ask_title
        ask_label
        ask_ops_approval("issue")
        ask_ux_approval("issue")
        ask_pivotal_ids if config.use_pivotal_tracker
        ask_jira_ids if config.use_jira
      end
      protected :ask_questionaire

      # Protected: Announce to the user the branches the issue will reference
      def announce
        cli.say "Preparing an issue for #{config.github_repo}."
      end
      protected :announce

      # Protected: Ask for a title for the issue
      def ask_title
        self.title = cli.prompt "Title:"
      end
      protected :ask_title

      # Protected: Ask for a label for the issue
      def ask_label
        choices = Octopolo::GitHub::Label.get_names(label_choices).concat(["None"])
        response = cli.ask(label_prompt, choices)
        self.labels << label_hash[response]
      end
      protected :ask_label

      # Protected: Ask if this issue needs Ops approval
      def ask_ops_approval(item)
        response = cli.ask("Does this #{item} require Operations approval?", ["Yes", "No"])
        self.labels << label_hash[OPTIONAL_REQUIREMENTS[ops_required]] if response == "Yes"
      end
      protected :ask_ops_approval

      # Protected: Ask if this issue needs UX approval
      def ask_ux_approval(item)
        response = cli.ask("Does this #{item} require UX approval?", ["Yes", "No"])
        self.labels << label_hash[OPTIONAL_REQUIREMENTS[ux_required]] if response == "Yes"
      end
      protected :ask_ux_approval

      # Protected: Ask for a Pivotal Tracker story IDs
      def ask_pivotal_ids
        self.pivotal_ids = cli.prompt("Pivotal Tracker story ID(s):").split(/[\s,]+/)
      end
      protected :ask_pivotal_ids

      # Protected: Ask for a Pivotal Tracker story IDs
      def ask_jira_ids
        self.jira_ids = cli.prompt("Jira story ID(s):").split(/[\s,]+/)
      end
      protected :ask_pivotal_ids

      # Protected: Create the issue
      #
      # Returns a GitHub::Issue object
      def create_issue
        self.issue = GitHub::Issue.create config.github_repo, issue_attributes
      end
      protected :create_issue

      # Protected: The attributes to send to create the issue
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
      protected :issue_attributes

      # Protected: Handle the newly created issue
      def open_in_browser
        cli.copy_to_clipboard issue.url
        cli.open issue.url
      end
      protected :open_in_browser

      def label_prompt
        'Label:'
      end

      def label_choices
        Octopolo::GitHub::Label.all
      end

      def label_hash
        Hash[label_choices.map{ |l| [l.name, l] }]
      end

      def update_pivotal
        pivotal_ids.each do |story_id|
          Pivotal::StoryCommenter.new(story_id, issue.url).perform
        end if pivotal_ids
      end
      protected :update_pivotal

      def update_jira
        jira_ids.each do |story_id|
          Jira::StoryCommenter.new(story_id, issue.url).perform
        end if jira_ids
      end
      protected :update_jira

      def update_label
        issue.add_labels(labels)
      end
      protected :update_label

    end
  end
end
