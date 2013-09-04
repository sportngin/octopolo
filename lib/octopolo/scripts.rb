require "clamp"
require "automation/git"

module Automation
  module Scripts
    module Base
      def self.included(klass)
        class << klass
          attr_accessor :config
          attr_accessor :cli
        end

        klass.config = Automation::Config.parse
        klass.cli = Automation::CLI
      end

      def self.default_option_parser(config)
        OptionParser.new do |opts|
          opts.on("--reload", "Reload the cached Engine Yard API values") do
            config.reload_cached_api_object
          end

          opts.on("--app NAME", "Use NAME as the application name instead of the value in .automation.yml") do |name|
            config.engine_yard_app_name = name
          end
        end
      end
    end
  end
end

