require_relative "../scripts"
require_relative "../dated_branch_creator"

module Octopolo
  module Scripts
    class NewStaging
      include CLIWrapper

      def execute(options={:delete_old_branches => false})
        DatedBranchCreator.perform(Git::STAGING_PREFIX, options[:delete_old_branches])
      end
    end
  end
end

