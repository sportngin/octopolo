require_relative "../scripts"
require_relative "../git"

module Octopolo
  module Scripts
    class NewBranch < Clamp::Command
      include ConfigWrapper
      include GitWrapper

      banner "Create a new branch for features, bug fixes, or experimentation."

      parameter "NEW_BRANCH_NAME", "name to use for the new branch"
      parameter "[SOURCE_BRANCH_NAME]", "name of branch to branch from (default: deploy branch)"

      # Public: Perform the script
      def execute
        git.new_branch(new_branch_name, source_branch_name)
      end

      # Public: Provide a default value if none is given
      def default_source_branch_name
        config.deploy_branch
      end
    end
  end
end
