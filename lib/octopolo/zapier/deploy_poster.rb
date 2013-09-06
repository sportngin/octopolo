#<Encoding:UTF-8>
require "octopolo/zapier"

module Octopolo
  module Zapier
    class DeployPoster
      include UserConfigWrapper
      include CLIWrapper

      attr_accessor :app_name
      attr_accessor :env_name
      attr_accessor :deploy_type

      # Deploy Phases
      START = :start
      FINISH = :finish
      ERROR = :error

      # Public: Instantiate a new DeployPoster
      #
      # app_name - Name of the application being deployed
      # env_name - Name of the environment being deployed to
      # deploy_type - Type of deploy being performed
      def initialize app_name, env_name, deploy_type
        self.app_name = app_name
        self.env_name = env_name
        self.deploy_type = deploy_type
      end

      # Public: Post to Zapier about the current deploy phase
      def perform phase
        post message_for phase
      end

      # Public: Post the given message to Zapier
      def post message
        cli.perform_quietly %Q(curl -H 'Content-Type: application/json' -X POST -d '{"message": "#{message.gsub("'", "")}"}' '#{Zapier.endpoint(Zapier::MESSAGE_TO_DEVO)}')
      end

      # Public: The message to post for the given phase of deploy
      def message_for phase
        case phase
        when START
          "#{environment_emoji}#{type_emoji} #{user_config.full_name} is STARTING a #{deploy_type} deploy to #{app_name} #{env_name}."
        when FINISH
          "#{environment_emoji}#{finished_emoji} #{user_config.full_name} is DONE deploying to #{app_name} #{env_name}."
        when ERROR
          "#{failed_emoji} Something went wrong with #{user_config.full_name}’s deploy to #{app_name} #{env_name}. Please correct the problem and redeploy."
        end
      end

      # Public: The emoji appropriate for the deploy type
      def type_emoji
        case deploy_type
        when "fast", "hot", "soft", "hard"
          ":zap:"
        when "rolling", "rolling_migrations"
          ":turtle:"
        else
          ":grey_question:"
        end
      end

      # Public: The emoji for signifying that the deploy completed
      def finished_emoji
        ":punch:"
      end

      # Public: The emoji for signifying that the deploy failed
      def failed_emoji
        ":poop:"
      end

      # Public: The emoji for signifying production deploys
      def environment_emoji
        if env_name.include? "production"
          ":shipit:"
        else
          ""
        end
      end
    end
  end
end
