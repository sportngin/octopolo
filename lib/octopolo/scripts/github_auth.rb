require "json"
require_relative "../github"
require_relative "../scripts"

module Octopolo
  module Scripts
    class GithubAuth
      include CLIWrapper
      include UserConfigWrapper

      attr_accessor :username
      attr_accessor :password
      attr_accessor :auth_response
      attr_accessor :user_defined_token

      def execute
        case ask_auth_method
        when "Generate an API token with my credentials"
          ask_credentials
          request_token
        when "I'll enter an access token manually"
          ask_token
          verify_token
        end
        store_token
      rescue GitHub::BadCredentials => e
        cli.say e.message
      end

      # Private: Give option to manually get token from GitHub and use it instead of using creds (For people that use 2FA)
      def ask_auth_method
        question = "Would you like to generate an GitHub API token with your credentials or enter one manually?\n"\
                   "You *must* enter a token manually if you are using GitHub's Two Factor Authentication.\n"\
                   "For more information, see https://help.github.com/articles/creating-an-access-token-for-command-line-use\n\n"
        choices = ["Generate an API token with my credentials", "I'll enter an access token manually"]
        selected = cli.ask(question, choices)
      end
      private :ask_auth_method

      # Private: Request the user's GitHub username and password
      def ask_credentials
        self.username = cli.prompt "Your GitHub username: "
        self.password = cli.prompt_secret "Your GitHub password (never stored): "
      end
      private :ask_credentials

      # Private: Request an auth token from GitHub
      def request_token
        json = cli.perform_quietly %Q(curl -u '#{username}:#{password}' -d '{"scopes": ["repo"], "notes": "Octopolo"}' https://api.github.com/authorizations)
        self.auth_response = JSON.parse json
      end
      private :request_token

      # Private: Verify a user_defined_token with GitHub
      def verify_token
        json = cli.perform_quietly %Q(curl -u #{user_defined_token}:x-oauth-basic https://api.github.com/user)
        self.auth_response = JSON.parse json
      end
      private :verify_token

      # Private: Request the user to give a token to be set manually (required for 2FA)
      def ask_token
        self.username = cli.prompt "Your GitHub username: "
        self.user_defined_token = cli.prompt_secret "Your GitHub API token: "
      end
      private :ask_token

      # Private: Store the token recieved from GitHub
      #
      # If a token is present in the response, store it in the user config.
      # Otherwise indicate that the authorization did not succeed.
      def store_token
        token = auth_response["login"] ? user_defined_token : auth_response["token"]
        if token
          user_config.set :github_user, username
          user_config.set :github_token, token
          cli.say "Successfully stored GitHub API token."
        else
          raise GitHub::BadCredentials, "Uh oh, your access token couldn't be generated/verified. Please check your credentials and try again."
        end
      end
      private :store_token

    end
  end
end

