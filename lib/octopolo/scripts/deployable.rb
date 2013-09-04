require "automation/scripts"
require "automation/git"
require "automation/github/pull_request"
require "automation/dated_branch_creator"

module Automation
  module Scripts
    class Deployable < Clamp::Command
      include ConfigWrapper
      include CLIWrapper
      include GitWrapper

      parameter "PULL_REQUEST_ID", "The ID of the pull request to mark deployable" do |s|
        Integer(s)
      end

      attr_accessor :pull_request

      # Public: Perform the script
      def execute
        git.if_clean do
          check_out_deployable
          merge_pull_request
          comment_about_merge
        end
      rescue GitHub::PullRequest::NotFound
        cli.say "Unable to find pull request #{pull_request_id}. Please retry with a valid ID."
      rescue Git::MergeFailed
        cli.say "Merge failed. Please identify the source of this merge conflict resolve this conflict in your pull request's branch. NOTE: Merge conflicts resolved in the deployable branch are NOT used when deploying."
      rescue Git::CheckoutFailed
        cli.say "Checkout of #{git.deployable_branch} failed. Please contact Infrastructure to determine the cause."
      rescue GitHub::PullRequest::CommentFailed
        cli.say "Unable to write comment. Please navigate to #{pull_request.url} and add the comment, '#{comment_body}'"
      end

      # Public: Check out the deployable branch
      def check_out_deployable
        git.check_out git.deployable_branch
      rescue Git::NoBranchOfType
        cli.say "No deployable branch available. Creating one now."
        git.check_out DatedBranchCreator.perform(Git::DEPLOYABLE_PREFIX).branch_name
      end

      # Public: Merge the pull request's branch into the checked-out deployable branch
      def merge_pull_request
        git.merge pull_request.branch
      end

      # Public: Comment that the pull request was merged into the deployable branch
      def comment_about_merge
        pull_request.write_comment comment_body
      end

      # Public: The content of the comment to post when merged
      #
      # Returns a String
      def comment_body
        "Merged into #{git.deployable_branch}. /cc @tst-automation"
      end

      # Public: Find the pull request to be marked deployable
      #
      # Returns a GitHub::PullRequest
      def pull_request
        @pull_request ||= GitHub::PullRequest.new config.github_repo, pull_request_id
      end
    end
  end
end
