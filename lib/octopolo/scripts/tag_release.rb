require "date" # necessary to get the Date.today convenience method
require "semantic" # semantic versioning class (parsing, comparing)
require "semantic/core_ext"
require "octopolo/semver_tag_scrubber"

require_relative "../scripts"
require_relative "../changelog"

module Octopolo
  module Scripts
    class TagRelease
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      attr_accessor :prefix
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
      SEMVER_CHOICES   = %w[Major Minor Patch]

      def self.execute(options=nil)
        new(options).execute
      end

      def initialize(options={})
        @prefix = options[:prefix]
        @suffix = options[:suffix]
        @force = options[:force]
        @major = options[:major]
        @minor = options[:minor]
        @patch = options[:patch]
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

      def update_changelog
        changelog.open do |log|
          log.puts "#### #{tag_name}"
        end
        git.perform("add #{changelog.filename}")
        git.perform("commit -m 'Updating Changelog for #{tag_name}'")
      end

      # Public: Generate a tag for the current release
      def tag_release
        git.new_tag tag_name
      end

      # Public: The name to apply to the new tag
      def tag_name
        if config.semantic_versioning
          @tag_name ||= tag_semver
        else
          @tag_name ||= %Q(#{Time.now.strftime(TIMESTAMP_FORMAT)}#{"_#{suffix}" if suffix})
        end
      end

      def tag_semver
        current_version = get_current_version
        set_prefix
        ask_user_version  unless @major || @minor || @patch
        new_version = upgrade_version current_version
        "#{prefix}#{new_version.to_s}"
      end

      def get_current_version
        tags = git.semver_tags
        tags.map{|tag| Octopolo::SemverTagScrubber.scrub_prefix(tag); tag.to_version }.sort.last || "0.0.0".to_version
      end

      def ask_user_version
        response = cli.ask("Which version section do you want to increment?", SEMVER_CHOICES)
        send("#{response.downcase}=", true)
      end

      def upgrade_version current_version
        if @major
          current_version.major += 1
          current_version.minor = 0
          current_version.patch = 0
        elsif @minor
          current_version.minor += 1
          current_version.patch = 0
        elsif @patch
          current_version.patch+=1
        end
        current_version
      end

      # Private: the changelog file
      def changelog
        @changelog ||= Changelog.new
      end

      # Private: sets/removes the prefix from the tag
      #
      # Allows the tag to play nice with the semantic gem
      def set_prefix
        @prefix ||= Octopolo::SemverTagScrubber.scrub_prefix(git.semver_tags.last)
      end
    end
  end

  WrongBranch = Class.new(StandardError)
end

