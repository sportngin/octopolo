require "octopolo/scripts"
require "octopolo/github/pull_request"

module Octopolo
  module Scripts
    class Qaready < Clamp::Command
      include ConfigWrapper
      include CLIWrapper
      include GitWrapper

      attr_accessor :pull_request

      parameter "PULL_REQUEST_ID", "The ID of the pull request to mark QA-ready" do |s|
        Integer(s)
      end

      banner %Q(
        Mark the given pull request QA-ready.
      )

      def execute
        GitHub.connect do
          check_out_qaready
          merge_master
          merge_pull_request
          write_comment
        end
      end

      # Private: Find the pull request to be marked QA-ready
      #
      # Returns a GitHub::PullRequest
      def pull_request
        @pull_request ||= GitHub::PullRequest.new config.github_repo, pull_request_id
      end
      private :pull_request

      # Private: Check out the current QA-ready branch
      def check_out_qaready
        git.check_out git.qaready_branch
      end
      private :check_out_qaready

      # Private: Ensure the latest master code is in the QA-ready branch
      def merge_master
        git.merge config.deploy_branch
      end
      private :merge_master

      # Private: Merge the pull request into the QA-ready branch
      def merge_pull_request
        git.merge pull_request.branch
      end
      private :merge_pull_request

      # Private: Post a comment that the branch was merged into QA-ready
      def write_comment
        pull_request.write_comment "Merged into #{git.qaready_branch}."
      end
      private :write_comment
    end
  end
end

# vim: set ft=ruby: #
