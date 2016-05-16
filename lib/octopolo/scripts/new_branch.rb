require_relative "../scripts"
require_relative "../git"

module Octopolo
  module Scripts
    class NewBranch
      include ConfigWrapper
      include GitWrapper
      include CLIWrapper

      attr_accessor :new_branch_name
      attr_accessor :source_branch_name

      def self.execute(new_branch_name=nil, source_branch_name=nil)
        new(new_branch_name, source_branch_name).execute
      end

      def initialize(new_branch_name=nil, source_branch_name=nil)
        @new_branch_name    = new_branch_name
        @source_branch_name = source_branch_name || config.deploy_branch
      end

      # Public: Perform the script
      def execute
        raise ArgumentError unless new_branch_name
        if !git.reserved_branch?(new_branch_name) || cli.ask_boolean(Git::RESERVED_BRANCH_CONFIRM_MESSAGE)
          git.new_branch(new_branch_name, source_branch_name)
        else
          message = Git::RESERVED_BRANCH_MESSAGE
          git.alert_reserved_branch message
          exit 1
        end
      end

      # Public: Provide a default value if none is given
      def default_source_branch_name
        config.deploy_branch
      end
    end
  end
end
