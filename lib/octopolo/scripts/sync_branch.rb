require "octopolo/scripts"

module Octopolo
  module Scripts
    class SyncBranch < Clamp::Command
      include ConfigWrapper
      include CLIWrapper
      include GitWrapper

      parameter "[BRANCH]", "Which branch to merge into yours (default: deploy branch)"

      # Public: Default value of branch if none given
      def default_branch
        config.deploy_branch
      end

      def execute
        merge_branch
      end

      # Public: Merge the specified remote branch into your local
      def merge_branch
        git.merge branch
      rescue Git::MergeFailed
        cli.say "Merge failed. Please resolve these conflicts."
      end
    end
  end
end
