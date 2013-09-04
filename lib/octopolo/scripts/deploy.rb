require "automation/scripts"
require "automation/git"

module Automation
  module Scripts
    class Deploy < Clamp::Command
      include CLIWrapper
      include ConfigWrapper

      attr_accessor :environment
      attr_accessor :deploy_method

      parameter "[ENVIRONMENT]", "enviromment to deploy to, e.g. staging"
      parameter "[DEPLOY_METHOD]", "method to deploy with, e.g, fast or rolling"

      banner %Q(
        Deploy the current branch to any staging environment.
      )

      # Public: Perform the script
      def execute
        ask_environment
        ask_method
        deploy
      end

      # Public: Ask which environment to deploy to and store the result
      def ask_environment
        question = "Which #{config.app_name} environment do you want to deploy to?"
        self.environment ||= cli.ask(question, config.deploy_environments)
      end

      # Public: Ask which deploy method to use and store the result
      def ask_method
        question = "Which deploy method to use to deploy to #{environment}?"
        self.deploy_method ||= cli.ask(question, config.deploy_methods)
      end

      # Public: Perform the deploy
      def deploy
        cli.perform_and_exit "env DEPLOY_BRANCH=#{Git.current_branch} bundle exec cap #{environment} deploy:#{deploy_method}"
      end
    end
  end
end
