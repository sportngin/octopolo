require "automation/git"
require "automation/scripts"

module Automation
  module Scripts
    class StaleBranches < Clamp::Command
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      DEFAULT_BRANCHES = %W(HEAD master staging production)

      option "--delete", :flag, "Delete the stale branches (default: false)"

      def execute
        if delete?
          delete_stale_branches
        else
          display_stale_branches
        end
      end

      # Private: Display the stale branches in the project
      def display_stale_branches
        stale_branches.each do |branch_name|
          cli.say "* #{branch_name}"
        end
      end
      private :display_stale_branches

      # Private: Delete the stale branches in the project
      def delete_stale_branches
        stale_branches.each do |branch_name|
          git.delete_branch(branch_name)
        end
      end
      private :delete_stale_branches

      # Private: The list of stale branches for the project
      #
      # Returns an Array of Strings
      def stale_branches
        git.stale_branches(config.deploy_branch, config.branches_to_keep)
      end
      private :stale_branches
    end
  end
end

