module Octopolo
  # Provide access to the CLI class into other classes in the application
  module CLIWrapper
    attr_writer :cli

    # Public: Wrapper method around CLI class
    #
    # Returns the CLI class or equivalent
    def cli
      @cli ||= CLI
    end
  end

  # Provide access to the config into other classes in the application
  module ConfigWrapper
    attr_writer :config

    # Public: Wrapper around the user's and app's configuration
    #
    # Returns an instance of Config or equivalent
    def config
      @config ||= Octopolo.config
    end
  end

  # Provide access to user-supplied configuration values
  module UserConfigWrapper
    attr_writer :user_config

    # Returns an instance of UserConfig or equivalent
    def user_config
      @user_config ||= UserConfig.parse
    end
  end

  module GitWrapper
    attr_writer :git

    # Public: Wrapper method around Git class
    #
    # Returns the Git class or equivalent
    def git
      @git ||= Git
    end
  end
end
