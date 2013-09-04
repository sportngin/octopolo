require "automation/scripts"
require "automation/pivotal"

module Automation
  module Scripts
    class PivotalAuth < Clamp::Command
      include UserConfigWrapper
      include CLIWrapper

      attr_accessor :email
      attr_accessor :password
      attr_accessor :token

      # review https://github.com/mdub/clamp#declaring-options for how to
      # declare options, flags, and parameters to the script

      banner %Q(
        Generate a Pivotal Tracker auth token for Automation commands to use.
      )

      def execute
        ask_credentials
        request_token
        store_token
      rescue Pivotal::BadCredentials => e
        cli.say e.message
      end

      # Private: Ask the user for their credentials
      def ask_credentials
        self.email = cli.prompt "Your Pivotal Tracker email: "
        self.password = cli.prompt_secret "Your Pivotal Tracker password (never stored): "
      end
      private :ask_credentials

      # Private: Fetch the user's token from the Pivotal API
      def request_token
        self.token = Pivotal::Client.fetch_token(email, password)
      end
      private :request_token

      # Private: Store the returned token from the Pivotal API
      def store_token
        user_config.set :pivotal_token, token
      end
      private :store_token
    end
  end
end

# vim: set ft=ruby: #
