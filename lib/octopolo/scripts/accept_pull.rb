require "automation/git"
require "automation/github"
require "automation/github/pull_request"
require "automation/scripts"
require "automation/zapier"

module Automation
  module Scripts
    class AcceptPull < Clamp::Command
      include GitWrapper
      include ConfigWrapper
      include CLIWrapper

      banner "Accept pull requests. Merges the given pull request into master and updates the changelog."

      parameter "PULL_REQUEST_ID", "The ID of the pull request to accept" do |pr_id|
        Integer(pr_id)
      end

      # Public: Perform the script
      def execute
        GitHub.connect do
          pull_request = GitHub::PullRequest.new(config.github_repo, pull_request_id)
          merge pull_request
          update_changelog pull_request
          write_json pull_request
        end
      rescue GitHub::PullRequest::NotFound
        cli.say "Unable to find a pull request #{pull_request_id} for #{config.github_repo}. Please verify."
      end

      def merge pull_request
        Git.fetch
        # TODO i want to use Git.merge here, but I don't want to push at the same time, which Git.merge does
        cli.perform "git merge --no-ff origin/#{pull_request.branch}"
        unless pull_request.mergeable?
          cli.say "\n=====ATTENTION====="
          cli.say "There was a conflict with the merge. Either fix the conflicts and commit, or abort the merge with"
          cli.say "    'git merge --abort'"
          cli.say "and remove this entry from CHANGELOG.markdown\n"
        end
      end

      def changelog_filename
        'CHANGELOG.markdown'
      end

      def update_changelog pull_request
        File.open('new_changelog', 'w') do |changelog|
          FileUtils.touch(changelog_filename) unless File.exists?(changelog_filename)
          File.open(changelog_filename, 'r') do |old_changelog|
            if old_changelog.eof? || !old_changelog.readline.include?(Time.now.strftime('#### %Y-%m-%d'))
              old_changelog.rewind
              changelog.puts Time.now.strftime('#### %Y-%m-%d')
              changelog.puts
            else
              old_changelog.rewind
              changelog.puts old_changelog.readline
              changelog.puts
              old_changelog.readline # get rid of extra blank space
            end
            title = pull_request.title
            authors = pull_request.author_names
            commenters = pull_request.commenter_names
            url = pull_request.url

            changelog.puts "* #{title}"
            changelog.puts
            changelog.puts "  > #{authors.join(", ")}: #{commenters.join(', ')}: #{url}"
            changelog.puts
            old_changelog.each_line { |line| changelog.puts line }
          end
        end
        File.delete('CHANGELOG.markdown')
        File.rename('new_changelog', 'CHANGELOG.markdown')
      end

      def write_json pull_request
        Zapier.encode pull_request
      end

    end
  end
end

