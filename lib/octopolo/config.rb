require "date" # necessary to get the Date.today convenience method
require "yaml"
require_relative "user_config"

module Octopolo
  class Config
    FILE_NAMES = %w[.octopolo.yml .automation.yml]

    RECENT_TAG_LIMIT = 9
    # we use date-based tags, so look for anything starting with a 4-digit year
    RECENT_TAG_FILTER = /^\d{4}.*/

    attr_accessor :cli

    def initialize(attributes={})
      self.cli = Octopolo::CLI

      assign attributes
      load_plugins
    end

    # default values for these customizations
    def deploy_branch
      @deploy_branch || "master"
    end

    def branches_to_keep
      @branches_to_keep || []
    end

    def deploy_environments
      @deploy_environments || []
    end

    def deploy_methods
      @deploy_methods || []
    end

    def github_repo
      @github_repo || raise(MissingRequiredAttribute, "GitHub Repo is required")
    end

    def user_notifications
      if [NilClass, Array, String].include?(@user_notifications.class)
        Array(@user_notifications) if @user_notifications
      else
        raise(InvalidAttributeSupplied, "User notifications must be an array or string")
      end
    end

    def plugins
      case @plugins
      when Array, String then Array(@plugins)
      when NilClass then []
      else
        raise(InvalidAttributeSupplied, "Plugins must be an array or string")
      end
    end

    def use_pivotal_tracker
      !!@use_pivotal_tracker
    end

    def use_jira
      !!@use_jira
    end

    def jira_user
      @jira_user || raise(MissingRequiredAttribute, "Jira User is required") if use_jira
    end

    def jira_password
      @jira_password || raise(MissingRequiredAttribute, "Jira Password is required") if use_jira
    end

    def jira_url
      @jira_url || raise(MissingRequiredAttribute, "Jira Url is required") if use_jira
    end

    # end defaults

    def self.parse
      new(attributes_from_file)
    end

    def self.attributes_from_file
      YAML.load_file(octopolo_config_path)
    end

    def self.octopolo_config_path
      if filepath = FILE_NAMES.detect {|filename| File.exists?(filename)}
        File.join(Dir.pwd, filepath)
      else
        old_dir = Dir.pwd
        Dir.chdir('..')
        if old_dir != Dir.pwd
          octopolo_config_path
        else
          Octopolo::CLI.say "Could not find #{FILE_NAMES.join(' or ')}"
          exit
        end
      end
    end

    def load_plugins
      plugins.each do |plugin|
        begin
          require plugin
        rescue LoadError
          puts "Plugin '#{plugin}' failed to load"
        end
      end
    end

    def assign(attributes)
      attributes.each do |key, value|
        self.instance_variable_set("@#{key}", value)
      end
    end

    def basedir
      File.basename File.dirname Config.octopolo_config_path
    end

    def remote_branch_exists?(branch)
      branches = Octopolo::CLI.perform "git branch -r", false
      branch_list = branches.split(/\r?\n/)
      branch_list.each { |x| x.gsub!(/\*|\s/,'') }
      branch_list.include? "origin/#{branch}"
    end

    def app_name
      basedir
    end

    # To be used when attempting to call a Config attribute for which there is
    # a value supplied that is of not the correct type
    InvalidAttributeSupplied = Class.new(StandardError)
    # To be used when attempting to call a Config attribute for which there is
    # no sensible default and one hasn't been supplied by the app
    MissingRequiredAttribute = Class.new(StandardError)
    # To be used when looking for a branch of a given type (like staging or
    # deployable), but none exist.
    NoBranchOfType = Class.new(StandardError)
  end
end
