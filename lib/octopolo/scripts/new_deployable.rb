require_relative "../scripts"
require_relative "../dated_branch_creator"

module Octopolo
  module Scripts
    class NewDeployable

      def execute
        DatedBranchCreator.perform Git::DEPLOYABLE_PREFIX
      end
    end
  end
end

