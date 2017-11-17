require_relative "git"
require_relative "scripts/new_branch"
require_relative "deployed_branch_merger"
require "date"

module Octopolo
  class DatedBranchCreator
    include ConfigWrapper
    include CLIWrapper
    include GitWrapper

    attr_accessor :branch_type, :should_delete_old_branches, :should_remerge_branches

    # Public: Initialize a new instance of DatedBranchCreator
    #
    # branch_type - Name of the type of branch (e.g., staging or deployable)
    # should_delete_old_branches - Flag to delete old branches of the given type.
    # should_remerge_branches - Flag to merge branches that have been deployed to the branch.
    def initialize(branch_type, should_delete_old_branches = false, should_remerge_branches = false)
      self.branch_type = branch_type
      self.should_delete_old_branches = should_delete_old_branches
      self.should_remerge_branches = should_remerge_branches
    end

    # Public: Create a new branch of the given type for today's date
    #
    # branch_type - Name of the type of branch (e.g., staging or deployable)
    # should_delete_old_branches - Flag to delete old branches of the given type.
    # should_remerge_branches - Flag to merge branches that have been deployed to the branch.
    #
    # Returns a DatedBranchCreator
    def self.perform(branch_type, should_delete_old_branches = false, should_remerge_branches = false)
      new(branch_type, should_delete_old_branches, should_remerge_branches).tap(&:perform)
    end

    # Public: Create the branch and handle related processing
    def perform
      create_branch
      remerge_branches
      delete_old_branches
    end

    # Public: Create the desired branch
    def create_branch
      git.new_branch(branch_name, config.deploy_branch)
    end

    # Public: The date suffix to append to the branch name
    def date_suffix
      Date.today.strftime("%Y.%m.%d")
    end

    # Public: The name of the branch to create
    def branch_name
      case branch_type
      when Git::DEPLOYABLE_PREFIX, Git::STAGING_PREFIX, Git::QAREADY_PREFIX
        "#{branch_type}.#{date_suffix}"
      else
        raise InvalidBranchType, "'#{branch_type}' is not a valid branch type"
      end
    end

    def remerge_branches
      Octopolo::DeployedBranchMerger.new(branch_type, should_remerge_branches).merge
    end

    # Public: If necessary, and if user opts to, delete old branches of its type
    def delete_old_branches
      return unless extra_branches.any?
      should_delete = should_delete_old_branches || cli.ask_boolean("Do you want to delete the old #{branch_type} branch(es)? (#{extra_branches.join(", ")})")

      if should_delete
        extra_branches.each do |extra|
          Git.delete_branch(extra)
        end
      end
    end

    # Public: The list of extra branches that exist after creating the new branch
    #
    # Returns an Array of Strings of the branch names
    def extra_branches
      case branch_type
      when Git::DEPLOYABLE_PREFIX, Git::STAGING_PREFIX, Git::QAREADY_PREFIX
        Git.branches_for(branch_type) - [branch_name]
      else
        raise InvalidBranchType, "'#{branch_type}' is not a valid branch type"
      end
    end

    InvalidBranchType = Class.new(StandardError)
  end
end

