require "octopolo/github"
require "octopolo/scripts"

module Octopolo
  module Scripts
    class OctopoloSetup
      include Base
      extend UserConfigWrapper

      REQUIRED_HUB_VERSION = "1.10.1"
      HUB_VERSION_COMMAND = "hub --version"

      def self.invoke(*args)
        options = parse_options(*args)

        verify_git_extras_setup
        verify_user_setup
      end

      def self.parse_options(*args)
        options = {}

        parser = Base.default_option_parser(config)
        parser.parse!(args)

        options
      end

      def self.verify_git_extras_setup
        install_git_extras unless git_extras_installed?
      end

      def self.git_extras_installed?
        check = cli.perform "which git-extras", false
        check.include? "git-extras"
      end

      def self.install_git_extras
        cli.say "Updating Homebrew to ensure latest git-extras formula."
        cli.perform "brew update"
        cli.say "Installing git-extras"
        cli.perform "brew install git-extras"
      end

      def self.verify_user_setup
        verify_user_full_name
        verify_user_github_credentials
      end

      def self.verify_user_full_name
        # if it's not set, it uses the USER environment variable
        if user_config.full_name == ENV["USER"]
          name = cli.prompt "Your full name:"
          user_config.full_name = name
        else
          cli.say "Full name '#{user_config.full_name}' already configured."
        end
      end

      def self.verify_user_github_credentials
        GitHub.check_connection
        cli.say "Successfully configured API token."
      rescue GitHub::BadCredentials, GitHub::TryAgain => e
        # if any error occurs, generate a new token
        cli.say e.message
      end
    end
  end
end
