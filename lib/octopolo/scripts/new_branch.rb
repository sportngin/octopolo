require_relative "../scripts"
require_relative "../git"

module Octopolo
  module Scripts
    class NewBranch
      include ConfigWrapper
      include GitWrapper

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
        git.new_branch(new_branch_name, source_branch_name)
      end

      # Public: Provide a default value if none is given
      def default_source_branch_name
        config.deploy_branch
      end
    end
  end
end
