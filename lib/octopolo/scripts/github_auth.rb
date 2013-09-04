require "json"
require "automation/github"
require "automation/scripts"

module Automation
  module Scripts
    class GithubAuth < Clamp::Command
      include CLIWrapper
      include UserConfigWrapper

      attr_accessor :username
      attr_accessor :password
      attr_accessor :auth_response

      banner %Q(
        Generate a GitHub auth token for Automation commands to use.
      )

      def execute
        ask_credentials
        request_token
        store_token
      rescue GitHub::BadCredentials => e
        cli.say e.message
      end

      # Private: Request the user's GitHub usernamd and password
      def ask_credentials
        self.username = cli.prompt "Your GitHub username: "
        self.password = cli.prompt_secret "Your GitHub password (never stored): "
      end
      private :ask_credentials

      # Private: Request an auth token from GitHub
      def request_token
        json = cli.perform_quietly %Q(curl -u '#{username}:#{password}' -d '{"scopes": ["repo"], "notes": "TST Automation"}' https://api.github.com/authorizations)
        self.auth_response = JSON.parse json
      end
      private :request_token

      # Private: Store the token recieved from GitHub
      #
      # If a token is present in the response, store it in the user config.
      # Otherwise indicate that the authorization did not succeed.
      def store_token
        auth_response["token"].tap do |token|
          if token
            user_config.set :github_user, username
            user_config.set :github_token, token
            cli.say "Successfully generated GitHub API token."
          else
            raise GitHub::BadCredentials, "No token received from GitHub. Please check your credentials and try again."
          end
        end
      end
      private :store_token
    end
  end
end

