require_relative "../scripts"
require_relative "../dated_branch_creator"

desc "Create a new qaready branch"
long_desc "Create a new QA-ready branch with today's date and remove the others.

Useful when we have changes in the current deployable branch that we wish to remove."
command 'new-qaready' do |c|
  c.action { Octopolo::Scripts::NewQaready.new.execute }
end

module Octopolo
  module Scripts
    class NewQaready
      include ConfigWrapper
      include CLIWrapper

      def execute
        DatedBranchCreator.perform Git::QAREADY_PREFIX
      end
    end
  end
end

# vim: set ft=ruby: #
