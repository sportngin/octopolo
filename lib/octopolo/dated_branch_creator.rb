require "automation/git"
require "automation/scripts/new_branch"
require "automation/zapier/branch_poster"
require "date"

module Automation
  class DatedBranchCreator
    include ConfigWrapper
    include CLIWrapper
    include GitWrapper

    attr_accessor :branch_type

    # Public: Initialize a new instance of DatedBranchCreator
    #
    # branch_type - Name of the type of branch (e.g., staging or deployable)
    def initialize(branch_type)
      self.branch_type = branch_type
    end

    # Public: Create a new branch of the given type for today's date
    #
    # branch_type - Name of the type of branch (e.g., staging or deployable)
    #
    # Returns a DatedBranchCreator
    def self.perform(branch_type)
      new(branch_type).tap do |creator|
        creator.perform
      end
    end

    # Public: Create the branch and handle related processing
    def perform
      create_branch
      delete_old_branches
      post_about_branch
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

    # Public: If necessary, and if user opts to, delete old branches of its type
    def delete_old_branches
      if extra_branches.any? && cli.ask_boolean("Do you want to delete the old #{branch_type} branch(es)? (#{extra_branches.join(", ")})")
        extra_branches.each do |extra|
          cli.perform "git delete-branch #{extra}"
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

    # Public: Post to Campfire about the newly created branch
    def post_about_branch
      case branch_type
      when Git::STAGING_PREFIX, Git::DEPLOYABLE_PREFIX, Git::QAREADY_PREFIX
        Zapier::BranchPoster.perform config.app_name, branch_name, branch_type
      else
        raise InvalidBranchType, "'#{branch_type}' is not a valid branch type"
      end
    end

    InvalidBranchType = Class.new(StandardError)
  end
end

