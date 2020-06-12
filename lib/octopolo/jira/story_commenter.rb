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
        begin
          self.issue =  Jiralicious::Issue.find issue_id
        rescue => e
           puts "Error: Invalid Jira Issue #{issue_id}" 
        end
        self.comment = comment
      end

      def perform
        begin
          issue.comments.add(comment)
        rescue => e
          puts "Error: Failed to comment on Jira Issue. \nException: #{e}"
        end
      end
    end
  end
end
