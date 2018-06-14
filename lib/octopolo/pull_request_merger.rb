require "travis"
require "travis/pro"
require_relative "scripts"
require_relative "git"
require_relative "github"
require_relative "dated_branch_creator"

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
      # git.if_clean do
        # check_out_branch
        # merge_pull_request
        # comment_about_merge
        if @options[:follow_travis]
          travis_state = follow_travis

          if %w[errored failed unsuccessful].include?(travis_state)
            cli.say "Your Travis build has not finished successfully. Your stage-up is cancelled."
          end
        end
      # end
    rescue => e
      case e
      # TODO: potentially add message for if Travis fails
      when GitHub::PullRequest::NotFound
        cli.say "Unable to find pull request #{pull_request_id}. Please retry with a valid ID."
      when Git::MergeFailed
        cli.say "Merge failed. Please identify the source of this merge conflict resolve this conflict in your pull request's branch. NOTE: Merge conflicts resolved in the #{branch_type} branch are NOT used when deploying."
      when Git::CheckoutFailed
        cli.say "Checkout of #{branch_to_merge_into} failed. Please contact Infrastructure to determine the cause."
      when GitHub::PullRequest::CommentFailed
        cli.say "Unable to write comment. Please navigate to #{pull_request.url} and add the comment, '#{comment_body}'"
      else
        cli.say "An unknown error occurred: #{e.inspect}"
      end
      false
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

    def get_travis_build(repo)
      repo.last_build
    end

    def follow_travis
      repo_name = "emmasax1/LearningComputerScience"

      # TODO: check if private/public repo. If private, use PRO, if not, don't use PRO

      # if private repo
        # Travis::Pro.access_token = @options[:travis_token]
        # user = Travis::Pro::User.current
        # repo = Travis::Pro::Repository.find(repo_name)
      # else
        Travis.access_token = @options[:travis_token]
        user = Travis::User.current
        repo = Travis::Repository.find(repo_name)
      # end

      build = get_travis_build(repo)
      existing_build_number = build.number
      new_build_number = build.number

      if build.finished?
        puts "Waiting for a new Travis build..."

        while existing_build_number == new_build_number
          print "."
          sleep(3)
          repo.reload
          build = get_travis_build(repo)
          new_build_number = build.number
        end

        existing_build_number = new_build_number
      end

      if build.created? && !build.running?
        puts "\nTravis build ##{build.number}: #{build.state}"
        until build.running?
          print "."
          sleep(3)
          repo.reload
          build = get_travis_build(repo)
        end
      end

      puts "\nTravis build ##{build.number}: #{build.state}"

      while build.running?
        print "."
        sleep(3)
        repo.reload
        build = get_travis_build(repo)
      end

      puts "\nTravis build ##{build.number}: #{build.state}"

      # TODO: change log link to check for private/public repository
      puts "To view #{build.state} log, visit: https://travis-ci.org/#{repo_name}/builds/#{build.id}"

      # to write the entire log to stdout:
      # job  = build.jobs.first
      # puts job.log.body

      return build.state
    end

    # Public: The content of the comment to post when merged
    #
    # Returns a String
    def comment_body
      body = "Merged into #{branch_to_merge_into}."
      if options[:user_notifications]
        body << " /cc #{options[:user_notifications].map {|name| "@#{name}"}.join(' ')}"
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
