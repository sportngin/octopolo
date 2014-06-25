require 'jiralicious'

module Octopolo
  module Jira
    class StoryCommenter
      include ConfigWrapper

      attr_accessor :issue
      attr_accessor :comment

      def initialize(issue_id, comment)
        Jiralicious.configure do |jira_config|
          jira_config.username = config.jira_user
          jira_config.password = config.jira_password
          jira_config.uri = config.jira_url
        end
        self.issue =  Jiralicious::Issue.find issue_id
        self.comment = comment
      end

      def perform
        issue.comments.add(comment)
      end
    end
  end
end
