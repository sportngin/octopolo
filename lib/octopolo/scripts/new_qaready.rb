require "automation/scripts"
require "automation/dated_branch_creator"

module Automation
  module Scripts
    class NewQaready < Clamp::Command
      include ConfigWrapper
      include CLIWrapper

      banner %Q(Create a new QA-ready branch with today's date and remove the others. Useful when we have changes in the current deployable branch that we wish to remove.)

      def execute
        DatedBranchCreator.perform Git::QAREADY_PREFIX
      end
    end
  end
end

# vim: set ft=ruby: #
