require_relative "../scripts"
require_relative "../dated_branch_creator"

desc "Create a new staging branch"
long_desc "Create a new staging branch with today's date and remove the others.

Useful when we have changes in the current staging branch that we wish to remove."
command 'new-staging' do |c|
  c.action { Octopolo::Scripts::NewStaging.new.execute }
end

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

