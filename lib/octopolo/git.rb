require "semantic" # semantic versioning class (parsing, comparing)

module Octopolo
  # Abstraction around local Git commands
  class Git
    NO_BRANCH = "(no branch)"
    DEFAULT_DIRTY_MESSAGE = "Your Git index is not clean. Commit, stash, or otherwise clean up the index before continuing."
    DIRTY_CONFIRM_MESSAGE = "Your Git index is not clean. Do you want to continue?"
    RESERVED_BRANCH_MESSAGE = "Please choose another name for your new branch."
    RESERVED_BRANCH_CONFIRM_MESSAGE = "Your new branch may be misidentified as a reserved branch based on its name. Do you want to continue?"
    # we use date-based tags, so look for anything starting with a 4-digit year
    RELEASE_TAG_FILTER = /^\d{4}.*/
    RECENT_TAG_LIMIT = 9
    # for semver tags
    SEMVER_TAG_FILTER = Semantic::Version::SemVerRegexp

    # branch prefixes
    DEPLOYABLE_PREFIX = "deployable"
    STAGING_PREFIX = "staging"
    QAREADY_PREFIX = "qaready"

    # To check if the new branch's name starts with one of these
    RESERVED_BRANCH_PREFIXES = [ DEPLOYABLE_PREFIX, STAGING_PREFIX, QAREADY_PREFIX ]

    include CLIWrapper
    extend CLIWrapper # add class-level .cli and .cli= methods

    # Public: Perform the given Git subcommand
    #
    # subcommand - String containing the subcommand and its parameters
    # options - Hash
    #   ignore_non_zero - Ignore exception for non-zero exit status of command.
    #
    # Example:
    #
    #   > Git.perform "status"
    #   # => output of `git status`
    def self.perform(subcommand, options={})
      options[:ignore_non_zero] ||= false
      cli.perform("git #{subcommand}", true, options[:ignore_non_zero])
    end

    # Public: Perform the given Git subcommand without displaying the output
    #
    # subcommand - String containing the subcommand and its parameters
    #
    # Example:
    #
    #   > Git.perform_quietly "status"
    #   # => no output
    def self.perform_quietly(subcommand)
      cli.perform_quietly "git #{subcommand}"
    end

    # Public: The name of the currently check-out branch
    #
    # Returns a String of the branch name
    def self.current_branch
      # cut trims the first three characters (whitespace or "*  " for current branch)
      # the chomp removes the newline from the command output
      name = cli.perform_quietly("git branch | grep '^* ' | cut -c 3-").chomp
      if name == NO_BRANCH
        raise NotOnBranch, "Not currently checked out to a particular branch"
      else
        name
      end
    end

    # Public: Determine if current_branch is reserved
    #
    # Returnsa boolean value
    def self.reserved_branch?
      !(current_branch =~ /^(?:#{Git::STAGING_PREFIX}|#{Git::DEPLOYABLE_PREFIX}|#{Git::QAREADY_PREFIX})/).nil?
    end

    # Public: Check out the given branch name
    #
    # branch_name - The name of the branch to check out
    # do_after_pull - Should a pull be done after checkout?
    def self.check_out(branch_name, do_after_pull=true)
      fetch
      perform "checkout #{branch_name}"
      pull if do_after_pull
      unless current_branch == branch_name
        raise CheckoutFailed, "Failed to check out '#{branch_name}'"
      end
    end

    # Public: Create a new branch from the given source
    #
    # new_branch_name - The name of the branch to create
    # source_branch_name - The name of the branch to branch from
    #
    # Example:
    #
    #   Git.new_branch("bug-123-fix-thing", "master")
    def self.new_branch(new_branch_name, source_branch_name)
      fetch
      perform("branch --no-track #{new_branch_name} origin/#{source_branch_name}")
      check_out(new_branch_name, false)
      perform("push --set-upstream origin #{new_branch_name}")
    end

    # Public: Whether the Git index is clean (has no uncommited changes)
    #
    # Returns a Boolean
    def self.clean?
      # git status --short returns one line for any uncommited changes, if any
      # e.g.,
      # ?? untracked.txt
      # D  deleted.txt
      # M  modified.txt
      cli.perform_quietly("git status --short").empty?
    end

    # Public: Perform the block if the Git index is clean
    def self.if_clean(message=DEFAULT_DIRTY_MESSAGE)
      if clean? || cli.ask_boolean(DIRTY_CONFIRM_MESSAGE)
        yield
      else
        alert_dirty_index message
        exit 1
      end
    end

    # Public: Display the message and show the git status
    def self.alert_dirty_index(message)
      cli.say " "
      cli.say message
      cli.say " "
      perform "status"
      raise DirtyIndex
    end

    def self.alert_reserved_branch(message)
      cli.say " "
      cli.say message
      cli.say " "
      cli.say " "
      cli.say "Here's the list of the reserved branch prefixes:"
      cli.say RESERVED_BRANCH_PREFIXES.join(" ")
      cli.say " "
      raise ReservedBranch
    end    

    # Public: Merge the given remote branch into the current branch
    def self.merge(branch_name)
      Git.if_clean do
        Git.fetch
        perform "merge --no-ff origin/#{branch_name}", :ignore_non_zero => true
        raise MergeFailed unless Git.clean?
        Git.push
      end
    end

    # Public: Fetch the latest changes from GitHub
    def self.fetch
      perform_quietly "fetch --prune"
    end

    # Public: Push the current branch to GitHub
    def self.push
      if_clean do
        perform "push origin #{current_branch}"
      end
    end

    # Public: Pull the latest changes for the checked-out branch
    def self.pull
      if_clean do
        perform "pull"
      end
    end

    # Public: The list of branches on GitHub
    #
    # Returns an Array of Strings containing the branch names
    def self.remote_branches
      Git.fetch
      raw = Git.perform_quietly "branch --remote"
      all_branches = raw.split("\n").map do |raw_name|
        # will come in as "  origin/foo", we want just "foo"
        raw_name.split("/").last
      end

      all_branches.uniq.sort
    end

    # Public: List of branches starting with the given string
    #
    # prefix - String to match branch names against
    #
    # Returns an Array of Strings containing the branch names
    def self.branches_for(prefix)
      remote_branches.select do |branch_name|
        branch_name =~ /^#{prefix}/
      end
    end

    def self.latest_branch_for(branch_prefix)
      branches_for(branch_prefix).last || raise(NoBranchOfType, "No #{branch_prefix} branch")
    end

    # Public: The name of the current deployable branch
    def self.deployable_branch
      latest_branch_for(DEPLOYABLE_PREFIX)
    end

    # Public: The name of the current staging branch
    def self.staging_branch
      latest_branch_for(STAGING_PREFIX)
    end

    # Public: The name of the current QA-ready branch
    def self.qaready_branch
      latest_branch_for(QAREADY_PREFIX)
    end

    # Public: The list of releases which have been tagged
    #
    # Returns an Array of Strings containing the tag names
    def self.release_tags
      Git.perform_quietly("tag").split("\n").select do |tag|
        tag =~ RELEASE_TAG_FILTER
      end
    end

    # Public: Only the most recent release tags
    #
    # Returns an Array of Strings containing the tag names
    def self.recent_release_tags
      release_tags.last(RECENT_TAG_LIMIT)
    end

    # Public: The list of releases with semantic versioning which have been tagged
    #
    # Returns an Array of Strings containing the tag names
    def self.semver_tags
      Git.perform_quietly("tag").split("\n").select do |tag|
        tag.sub(/\Av/i,'') =~ SEMVER_TAG_FILTER
      end
    end

    # Public: Create a new tag with the given name
    #
    # tag_name - The name of the tag to create
    def self.new_tag(tag_name)
      perform "tag #{tag_name}"
      push
      perform "push --tag"
    end

    # Public: Delete the given branch
    #
    # branch_name - The name of the branch to delete
    def self.delete_branch(branch_name)
      perform "push origin :#{branch_name}"
      perform "branch -D #{branch_name}", :ignore_non_zero => true
    end

    # Public: Branches which have been merged into the given branch
    #
    # source_branch_name - The name of the branch to check against
    # branches_to_ignore - An Array of branches to exclude from results
    #
    # Returns an Array of Strings
    def self.stale_branches(source_branch_name="master", branches_to_ignore=[])
      Git.fetch
      command = "branch --remote --merged #{recent_sha(source_branch_name)} | grep -E -v '(#{stale_branches_to_ignore(branches_to_ignore).join("|")})'"
      raw_result = Git.perform_quietly command
      raw_result.split.map { |full_name| full_name.gsub("origin/", "") }
    end

    # Private: The SHA from 1 day ago for the given branch
    #
    # branch_name - The name of the branch to check
    #
    # Returns a String
    def self.recent_sha(branch_name)
      raw = perform_quietly "rev-list `git rev-parse remotes/origin/#{branch_name} --before=1.day.ago` --max-count=1"
      raw.chomp
    end
    private_class_method :recent_sha

    # Private: Branches to ignore when looking for stale branches
    #
    # Returns an Array of Strings
    def self.stale_branches_to_ignore(additional_branches=[])
      %w(HEAD master staging deployable) + Array(additional_branches)
    end
    private_class_method :stale_branches_to_ignore

    # Exceptions
    NotOnBranch = Class.new(StandardError)
    CheckoutFailed = Class.new(StandardError)
    MergeFailed = Class.new(StandardError)
    NoBranchOfType = Class.new(StandardError)
    DirtyIndex = Class.new(StandardError)
    ReservedBranch = Class.new(StandardError)
  end
end
