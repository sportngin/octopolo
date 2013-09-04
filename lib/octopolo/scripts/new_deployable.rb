require "automation/scripts"
require "automation/dated_branch_creator"

module Automation
  module Scripts
    class NewDeployable < Clamp::Command

      banner %Q(Create a new deployable branch with today's date and remove the others. Useful when we have changes in the current deployable branch that we wish to remove.)

      def execute
        DatedBranchCreator.perform Git::DEPLOYABLE_PREFIX
      end
    end
  end
end

