require "octopolo/scripts"
require "octopolo/git"
require "octopolo/github/pull_request"
require "octopolo/dated_branch_creator"

module Octopolo
  class PullRequestMerger
    include ConfigWrapper
    include CLIWrapper
    include GitWrapper

    attr_accessor :branch_type, :pull_request_id, :options, :pull_request

    # Public: Initialize a new instance of DatedBranchCreator
    #
    # branch_type - Name of the type of branch (e.g., staging or deployable)
    # pull_request_id - The pull request id to use for the merge
    # options - hash of options
    #   - post_comment - whether or not to post a comment on the pull-request
    def initialize(branch_type, pull_request_id, options={})
      self.branch_type = branch_type
      self.pull_request_id = pull_request_id
      self.options = options
    end

    # Public: Create a new branch of the given type for today's date
    #
    # branch_type - Name of the type of branch (e.g., staging or deployable)
    # post_comment - Whether or not to comment on the pull-request
    #
    # Returns a DatedBranchCreator
    def self.perform(branch_type, pull_request_id, options={})
      new(branch_type, pull_request_id, options).tap do |creator|
        creator.perform
      end
    end

    # Public: Create the branch and handle related processing
    def perform
      git.if_clean do
        check_out_branch
        merge_pull_request
        comment_about_merge
      end
    rescue GitHub::PullRequest::NotFound
      cli.say "Unable to find pull request #{pull_request_id}. Please retry with a valid ID."
    rescue Git::MergeFailed
      cli.say "Merge failed. Please identify the source of this merge conflict resolve this conflict in your pull request's branch. NOTE: Merge conflicts resolved in the #{branch_type} branch are NOT used when deploying."
    rescue Git::CheckoutFailed
      cli.say "Checkout of #{branch_to_merge_into} failed. Please contact Infrastructure to determine the cause."
    rescue GitHub::PullRequest::CommentFailed
      cli.say "Unable to write comment. Please navigate to #{pull_request.url} and add the comment, '#{comment_body}'"
    end

   # Public: Check out the branch
    def check_out_branch
      git.check_out branch_to_merge_into
    rescue Git::NoBranchOfType
      cli.say "No #{branch_type} branch available. Creating one now."
      git.check_out DatedBranchCreator.perform(branch_type).branch_name
    end

    # Public: Merge the pull request's branch into the checked-out branch
    def merge_pull_request
      git.merge pull_request.branch
    end

    # Public: Comment that the pull request was merged into the branch
    def comment_about_merge
      pull_request.write_comment comment_body
    end

    # Public: The content of the comment to post when merged
    #
    # Returns a String
    def comment_body
      body = "Merged into #{branch_to_merge_into}."
      if options[:notify_automation]
        body << " /cc @tst-automation"
      end
      body
    end

    # Public: Find the pull request
    #
    # Returns a GitHub::PullRequest
    def pull_request
      @pull_request ||= GitHub::PullRequest.new config.github_repo, pull_request_id
    end

    # Public: Find the branch
    #
    # Returns a String
    def branch_to_merge_into
      @branch_to_merge_into ||= git.latest_branch_for(branch_type)
    end
  end
end

