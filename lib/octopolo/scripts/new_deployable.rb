require_relative "../scripts"
require_relative "../dated_branch_creator"

desc "Create a new deployable branch"
long_desc "Create a new deployable branch with today's date and remove the others.

Useful when we have changes in the current deployable branch that we wish to remove."
command 'new-deployable' do |c|
  c.action { Octopolo::Scripts::NewDeployable.new.execute }
end

module Octopolo
  module Scripts
    class NewDeployable

      def execute
        DatedBranchCreator.perform Git::DEPLOYABLE_PREFIX
      end
    end
  end
end

