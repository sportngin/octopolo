require "octokit"
# TODO this needs to get moved out of scripts and into its own new module
require "octopolo/scripts/github_auth"

module Octopolo
  module GitHub
    extend UserConfigWrapper

    # Used as the name of a user if we can't find it on GitHub's API
    UNKNOWN_USER = "Unknown User"

    # Public: Perform the given block if the user has valid GitHub credentials
    #
    # When performing anything that connects to GitHub, wrap with
    # GitHub.connect to ensure that the user's credentials are all set up
    # before running anything.
    #
    # Example:
    #
    #   GitHub.connect do
    #     # PullRequest.create or whatever
    #   end
    def self.connect &block
      GitHub.check_connection

      yield
    rescue GitHub::BadCredentials, GitHub::TryAgain => error
      CLI.say error.message
    end

    # Public: A GitHub client object
    def self.client(options = {})
      Octokit::Client.new(options.merge(login: user_config.github_user, oauth_token: user_config.github_token))
    rescue UserConfig::MissingGitHubAuth
      raise TryAgain, "No GitHub API token stored. Please run `bundle exec github-auth` to generate your token."
    end

    # Public: A GitHub client configured to crawl through pages
    def self.crawling_client
      client(auto_traversal: true)
    end

    # Public: Check that GitHub credentials have been properly set up
    def self.check_connection
      # we don't care about the output, just try to hit the API
      client.user && nil
    rescue Octokit::Unauthorized
      raise BadCredentials, "Your stored credentials were rejected by GitHub. Run `bundle exec github-auth` to generate a new token."
    end

    def self.pull_request *args
      client.pull_request *args
    end

    def self.pull_request_commits *args
      client.pull_request_commits *args
    end

    def self.issue_comments *args
      client.issue_comments *args
    end

    def self.pull_requests *args
      crawling_client.pull_requests *args
    end

    def self.create_pull_request *args
      client.create_pull_request *args
    end

    def self.add_comment *args
      client.add_comment *args
    end

    def self.user username
      client.user(username)
    rescue
      Hashie::Mash.new(name: UNKNOWN_USER)
    end

    def self.org_repos org_name="sportngin"
      crawling_client.organization_repositories org_name
    end

    def self.excluded_users
      ["tst-octopolo"]
    end

    # now that you've set up your credentials, try again
    TryAgain = Class.new(StandardError)
    # the credentials you've entered are bad
    BadCredentials = Class.new(StandardError)
  end
end

