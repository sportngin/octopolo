module Automation
  # Provide access to the CLI class into other classes in the application
  module CLIWrapper
    attr_accessor :cli

    # Public: Wrapper method around CLI class
    #
    # Returns the CLI class or equivalent
    def cli
      @cli ||= CLI
    end
  end

  # Provide access to the config into other classes in the application
  module ConfigWrapper
    attr_accessor :config

    # Public: Wrapper around the user's and app's configuration
    #
    # Returns an instance of Config or equivalent
    def config
      @config ||= Config.parse
    end
  end

  # Provide access to user-supplied configuration values
  module UserConfigWrapper
    attr_accessor :user_config

    # Returns an instance of UserConfig or equivalent
    def user_config
      @user_config ||= UserConfig.parse
    end
  end

  # Provide access to the EngineYardAPI wrapper class
  module EngineYardAPIWrapper
    attr_accessor :engine_yard

    # Public: Wrapper method around the Engine Yard API
    #
    # Retruns an instance of EngineYardAPI or equivalent
    def engine_yard
      @engine_yard ||= EngineYardAPI.new
    end
  end

  module GitWrapper
    attr_accessor :git

    # Public: Wrapper method around Git class
    #
    # Returns the Git class or equivalent
    def git
      @git ||= Git
    end
  end
end
