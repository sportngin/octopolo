require_relative "../scripts"
require_relative "../dated_branch_creator"

module Octopolo
  module Scripts
    class NewStaging
      include CLIWrapper

      def execute
        DatedBranchCreator.perform Git::STAGING_PREFIX
      end
    end
  end
end

