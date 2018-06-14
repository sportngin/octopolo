require_relative "../scripts"
require_relative "../pull_request_merger"
require "yaml"

module Octopolo
  module Scripts
    class StageUp
      include CLIWrapper

      attr_accessor :pull_request_id, :options, :travis_config_file

      def self.execute(pull_request_id=nil, options)
        new(pull_request_id, options).execute
      end

      def initialize(pull_request_id=nil, options={})
        @pull_request_id = pull_request_id
        @options = options
      end

      # Public: Perform the script
      def execute
        if follow_travis?
          unless config_file_exists?
            puts "To follow a Travis log, you need to have a ~/.travis.config.yml file set."
            puts "  To do this, please run: gem install travis && travis login"
            exit
          end

          # TODO: check if private/public repo. If private, use https://api.travis-ci.com/ else use ".org"
          options[:travis_token] = @travis_config_file["endpoints"]["https://api.travis-ci.org/"]["access_token"] if follow_travis?
        end

        if (!self.pull_request_id)
          current = GitHub::PullRequest.current
          self.pull_request_id = current.number if current
        end
        self.pull_request_id ||= cli.prompt("Pull Request ID: ")
        PullRequestMerger.perform(Git::STAGING_PREFIX, Integer(pull_request_id), @options)
      end

      def follow_travis?
        @options[:follow_travis]
      end

      def config_file_exists?
        current_dir = Dir.pwd
        Dir.chdir("/" << current_dir.scan(/Users\/[a-zA-Z]*/).first << "/")
        if File.exists?(".travis/config.yml")
          @travis_config_file = YAML::load_file(File.join(Dir.pwd, ".travis/config.yml"))
          return true
        end
        false
      end
    end
  end
end
