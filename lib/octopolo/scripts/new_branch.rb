require_relative "../scripts"
require_relative "../git"

arg :new_branch_name,    :name => 'new_branch_name'
arg :source_branch_name, :name => 'source_branch_name', :optional => true
desc 'Create a new branch for features, bug fixes, or experimentation.'
command 'new-branch' do |c|
  c.action do |global_options, options, args|
    Octopolo::Scripts::NewBranch.execute args[0], args[1]
  end
end


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
