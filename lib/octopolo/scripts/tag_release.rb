require "date" # necessary to get the Date.today convenience method
require_relative "../scripts"
require_relative "../changelog"

arg :suffix, :desc => "Suffix to apply to to the dated tag"

desc "Create and push a timestamped tag with an optional suffix"
command 'tag-release' do |c|
  c.desc "Create tag even if not on deploy branch"
  c.switch :force, :negatable => false

  c.action do |global_options, options, args|
    options = global_options.merge(options)
    Octopolo::Scripts::TagRelease.execute args.first, options[:force]
  end
end

module Octopolo
  module Scripts
    class TagRelease
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      attr_accessor :suffix
      attr_accessor :force
      alias_method :force?, :force

      TIMESTAMP_FORMAT = "%Y.%m.%d.%H.%M"

      def self.execute(suffix=nil, force=false)
        new(suffix, force).execute
      end

      def initialize(suffix=nil, force=false)
        @suffix = suffix
        @force = force
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
        git.new_tag tag_name
      end

      # Public: The name to apply to the new tag
      def tag_name
        @tag_name ||= %Q(#{Time.now.strftime(TIMESTAMP_FORMAT)}#{"_#{suffix}" if suffix})
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

