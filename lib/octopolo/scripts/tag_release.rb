require "date" # necessary to get the Date.today convenience method
require "semantic" # semantic versioning class (parsing, comparing)
require "semantic/core_ext"

require_relative "../scripts"
require_relative "../changelog"

module Octopolo
  module Scripts
    class TagRelease
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      attr_accessor :suffix
      attr_accessor :force
      attr_accessor :major
      attr_accessor :minor
      attr_accessor :patch
      alias_method :force?, :force
      alias_method :major?, :major
      alias_method :minor?, :minor
      alias_method :patch?, :patch

      TIMESTAMP_FORMAT = "%Y.%m.%d.%H.%M"

      def self.execute(suffix=nil, options=nil)
        new(suffix, options).execute
      end

      def initialize(suffix=nil, options=nil)
        @suffix = suffix
        @force = options[:force] if !options.nil?
        @major = options[:major] if !options.nil?
        @minor = options[:minor] if !options.nil?
        @patch = options[:patch] if !options.nil?
      end

      def execute
        if should_create_branch?
          update_changelog
          tag_release
        else
          raise Octopolo::WrongBranch.new("Must perform this script from the deploy branch (#{config.deploy_branch})")
        end
      end

      # Public: Whether to create a new branch
      #
      # Returns a Boolean
      def should_create_branch?
        force? || (git.current_branch == config.deploy_branch)
      end

      # Public: Generate a tag for the current release
      def tag_release
        new_tag = tag_name
        git.new_tag new_tag if !new_tag.nil?
      end

      # Public: The name to apply to the new tag
      def tag_name
        if config.respond_to?(:semantic_versioning) && config.semantic_versioning == true
          @tag_name ||= "#{tag_semver}"
        else
          @tag_name ||= %Q(#{Time.now.strftime(TIMESTAMP_FORMAT)}#{"_#{suffix}" if suffix})
        end
      end

      def tag_semver
        current_version = get_current_version
        if !@major && !@minor && !@patch
          # prompt user
          ask_user_version
        end
        new_version = upgrade_version current_version
        new_version.to_s
      end

      def get_current_version
        tags = git.semver_tags
        tags.map(&:to_version).sort.last || "0.0.0".to_version
      end

      def ask_user_version
        choices = ["Major", "Minor", "Patch"]
        response = cli.ask("Which version section do you want to increment?", choices)
        if response == "Major"
          @major = true
        elsif response == "Minor"
          @minor = true
        elsif response == "Patch"
          @patch = true
        end
      end

      def upgrade_version current_version
        if @major
          current_version.major += 1
          current_version.minor = 0
          current_version.patch = 0
        end
        if @minor
          current_version.minor += 1
          current_version.patch = 0
        end
        if @patch
          current_version.patch+=1
        end
        current_version
      end

      def changelog
        @changelog ||= Changelog.new
      end

      def update_changelog
        changelog.open do |log|
          log.puts "#### #{tag_name}"
        end
        git.perform("add #{changelog.filename}")
        git.perform("commit -m 'Updating Changelog for #{tag_name}'")
      end

    end
  end

  WrongBranch = Class.new(StandardError)
end

