require 'jira-ruby'

module Octopolo
  module Jira
    class StoryCommenter
      include ConfigWrapper

      attr_accessor :issue
      attr_accessor :comment

      def initialize(issue_id, comment)
        options = {
          :username     => config.jira_user,
          :password     => config.jira_password,
          :site         => config.jira_url,
          :context_path => '',
          :auth_type    => :basic
        }
        begin
          client = JIRA::Client.new(options)
          self.issue = client.Issue.find(issue_id)
        rescue => e
           puts "Error: Invalid Jira Issue #{issue_id}" 
        end
        self.comment = comment
      end

      def perform
        begin
          comment = self.issue.comments.build
          comment.save!(:body => "#{self.comment}")
        rescue => e
          puts "Error: Failed to comment on Jira Issue. \nException: #{e}"
        end
      end
    end
  end
end
