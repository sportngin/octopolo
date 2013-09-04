require "automation/scripts"
require "automation/dated_branch_creator"

module Automation
  module Scripts
    class NewStaging < Clamp::Command
      include CLIWrapper

      banner %Q(Create a new staging branch with today's date and remove the others. Useful when we have changes in the current staging branch that we wish to remove.)

      def execute
        DatedBranchCreator.perform Git::STAGING_PREFIX
        temporary_code_climate_warning
      end

      # Private: Remind the user to rebuild the project in Code Climate
      #
      # This is a temporary measure until Code Climate has Pull Request
      # support. Until then, we set up the staging branch in Code Climate to
      # get warnings before things get deployed.
      #
      # NOTE: This whole thing can be removed once Pull Request support is available in Code Climate
      def temporary_code_climate_warning
        cli.say "NOTE: This project likely needs to be set up again in Code Climate. Please work with Infrastructure to get this done."
      end
      private :temporary_code_climate_warning
    end
  end
end

