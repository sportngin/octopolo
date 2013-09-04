module Automation
  class EngineYardAPI
    # number of days to keep the engine yard object cached
    CACHE_HOURS = 12
    API_KEY = "1958fd57ea90f787805fdba7a31ef3fe"
    API_ENDPOINT = "https://cloud.engineyard.com"

    attr_accessor :load_old_file
    attr_accessor :cli
    attr_accessor :config

    # Public: Fetch the Engine Yard API object
    #
    # load_old_file - A Boolean determining whether to load the cached file
    #   even if it is old
    #
    # Returns an EngineYard::API object or nil
    def self.fetch load_old_file=nil
      new(load_old_file).fetch
    end

    # Public: Remove the cached API object
    def self.reload_cached_api_object
      new.reload_cached_api_object
    end

    # Public: Instantiate a new Engine Yard API fetcher
    #
    # load_old_file - A Boolean determining whether to load the cached file
    #   even if it is old
    def initialize load_old_file=false
      self.load_old_file = load_old_file
      self.cli = Automation::CLI
      self.config = Automation::Config.parse
    end

    # Public: Fetch the Engine Yard API object
    #
    # load_old_file - A Boolean determining whether to load the cached file
    #   even if it is old
    #
    # Returns an EngineYard::API object or nil
    def fetch
      if cache_valid?
        marshalled_object
      else
        fresh_object
      end
    end

    # Private: The object cached to disk
    #
    # Returns an EngineYard::API object or nil
    def marshalled_object
      Marshal.load File.read cache_path
    rescue => e
      cli.say "Oops. There was a problem loading the cached object (#{e})"
      fresh_object
    end

    # Private: The path to the cached file
    #
    # Returns a String with the path to the file
    def cache_path
      File.expand_path File.join cache_dir, "ey-cache-#{config.app_name}"
    end

    # Private: The parent directory of the cache files
    #
    # Returns a String with the path to the directory
    def cache_dir
      File.expand_path "~/.automation"
    end

    # Private: Write the API object to the cache
    def write_cache data
      create_cache_dir
      File.write cache_path, Marshal.dump(data)
    end

    # Private: Create the cache directory if it doesn't already exist
    def create_cache_dir
      Dir.mkdir cache_dir
    rescue Errno::EEXIST
    end

    # Private: Whether the cached file is valid to load
    #
    # Returns a Boolean
    def cache_valid?
      File.exist?(cache_path) && cache_recent?
    end

    # Private: Whether the cached file is recent enough
    #
    # Returns a Boolean
    def cache_recent?
      File.mtime(cache_path) >= Time.now - 60 * 60 * CACHE_HOURS || load_old_file
    end

    # Private: Retrieve and cache the Engine Yard API object
    #
    # Returns the API object
    def fresh_object
      cli.say "Retrieving server information from Engine Yard..."
      EY::API.new(API_KEY).tap do |api|
        api.apps # fetch the data from engine yard
        write_cache api
      end
    end

    # Public: Remove the cached API object
    def reload_cached_api_object
      File.delete cache_path
    rescue Errno::ENOENT
    end

    # Public: The Engine Yard admin URL for the given environment name
    #
    # environment_name - A String containing the name of the Engine Yard environment
    #
    # Ex:
    #   admin_url_for("ngin_staging")
    #   => "https://cloud.engineyard.com/app_deployments/37724/environment"
    #
    # Returns a String containing the URL
    def admin_url_for(environment_name)
      "https://cloud.engineyard.com/app_deployments/#{environment_id(environment_name)}/environment"
    end

    # Public: Engine Yard's ID of the given environment name
    #
    # environment_name - A String containing the name of the Engine Yard environment
    #
    # Returns an Integer
    def environment_id(environment_name)
      environment(environment_name).deployment_configurations.values.first["id"]
    end

    # Public: Names of the environments for the given named app
    #
    # app_name - A String containing the name of the Engine Yard app
    #
    # Returns an Array of Strings
    def environment_names(app_name)
      app(app_name).environments.map(&:name).sort
    end

    # Public: The app with the given name
    #
    # app_name - A String containing the name of the Engine Yard app
    #
    # Returns an EY::Model::App
    def app(app_name)
      fetch.apps.named(app_name) || raise(AppNotFound)
    end

    # Public: The environment with the given name
    #
    # environment_name - A String containing the name of the Engine yard environment
    #
    # Returns an EY::Model::Environment
    def environment(environment_name)
      fetch.environments.named(environment_name) ||raise(EnvironmentNotFound)
    end

    Error = Class.new(StandardError)
    AppNotFound = Class.new(Error)
    EnvironmentNotFound = Class.new(Error)
  end
end
