require "automation/git"
require "automation/scripts"

module Automation
  module Scripts
    class PushBranch < Clamp::Command
      include GitWrapper

      def execute
        git.perform "push --set-upstream origin #{git.current_branch}"
      end
    end
  end
end
