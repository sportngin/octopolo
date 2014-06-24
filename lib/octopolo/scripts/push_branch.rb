require_relative "../git"
require_relative "../scripts"

desc "Push current branch to origin and set-upstream"
command 'push-branch' do |c|
  c.action { Octopolo::Scripts::PushBranch.new.execute }
end

module Octopolo
  module Scripts
    class PushBranch
      include GitWrapper

      def execute
        git.perform "push --set-upstream origin #{git.current_branch}"
      end
    end
  end
end
