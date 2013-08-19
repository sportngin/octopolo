module Octopolo
  class UserConfig
    # config values
    attr_accessor :github_user
    attr_accessor :github_token
    attr_accessor :full_name
    attr_accessor :pivotal_token
    attr_accessor :attributes # keep the whole hash

    # Public: Initialize a new UserConfig instance
    def initialize attributes={}
      self.attributes = attributes
      attributes.each do |key, value|
        # e.g., foo: "bar" translates to self.foo = "bar"
        setter = "#{key}="
        send(setter, value) if respond_to? setter
      end
    end

    # Public: Parse the user's config file
    #
    # Returns a UserConfig instance
    def self.parse
      new attributes_from_file
    end

    # Public: Set and store a new configuration value
    def set key, value
      # capture new value in instance
      send("#{key}=", value)
      attributes.merge!(key => value)
      # and store it
      File.write UserConfig.config_path, YAML.dump(attributes)
    end

    # Public: The user's configuration values
    #
    # Returns a Hash
    def self.attributes_from_file
      YAML.load_file config_path
    rescue Errno::ENOENT
      # create the file if it doesn't exist
      touch_config_file
      {}
    end

    # Public: The path to the users's configuration file
    #
    # Returns a String containing the path
    def self.config_path
      File.join(config_parent, "config.yml")
    end

    # Public: The parent directory of the user's configuration file
    #
    # Returns a String containing the path
    def self.config_parent
      File.expand_path("~/.octopolo")
    end

    # Public: Create the user's configuration file
    # NOTE this seems a mite gnarly, and its tests worse, but doesn't seem worth splitting out into "create_config_parent_directory" and "create_config_file" at this stage
    def self.touch_config_file
      unless Dir.exist? config_parent
        Dir.mkdir config_parent
      end

      unless File.exist? config_path
        File.write UserConfig.config_path, YAML.dump({})
      end
    end

    # Public: The user's name
    #
    # Returns a String
    def full_name
      @full_name || ENV["USER"]
    end

    # Public: The GitHub username
    #
    # If none is stored, generate it for the user.
    #
    # Returns a String or raises MissingGitHubAuth
    def github_user
      @github_user || raise(MissingGitHubAuth)
    end

    # Public: The GitHub token
    #
    # If none is stored, generate it for the user.
    #
    # Returns a String or raises MissingGitHubAuth
    def github_token
      @github_token || raise(MissingGitHubAuth)
    end

    # Public: The Pivotal Tracker token
    #
    # If none is stored, prompt them to generate it.
    #
    # Returns a String or raises MissingPivotalAuth
    def pivotal_token
      @pivotal_token || raise(MissingPivotalAuth)
    end

    MissingGitHubAuth = Class.new(StandardError)
    MissingPivotalAuth = Class.new(StandardError)
  end
end
