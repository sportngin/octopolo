require_relative "../scripts"
require_relative "../dated_branch_creator"

module Octopolo
  module Scripts
    class StageUp < Clamp::Command
      include GitWrapper
      include CLIWrapper

      parameter "[BRANCH]",
        "Name of branch to merge into staging (default: current branch)"

      def execute
        git.if_clean do
          check_out_staging
          merge_given_branch
        end
      end

      # Public: Check out the project's staging branch
      def check_out_staging
        # capturing here, since after we check out staging, we can't trust git.current_branch
        self.branch ||= git.current_branch
        git.check_out git.staging_branch
      rescue Git::NoBranchOfType
        cli.say "No staging branch available. Creating one now."
        git.check_out DatedBranchCreator.perform(Git::STAGING_PREFIX).branch_name
      end

      # Public: Merge the given branch into the checked-out staging branch
      def merge_given_branch
        git.merge branch
      rescue Git::MergeFailed
        cli.say "Merge of #{branch} into #{git.staging_branch} has failed. Please resolve these conflicts."
      end
    end
  end
end

