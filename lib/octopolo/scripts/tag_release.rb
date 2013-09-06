require "date" # necessary to get the Date.today convenience method
require "octopolo/scripts"

module Octopolo
  module Scripts
    class TagRelease < Clamp::Command
      include CLIWrapper
      include ConfigWrapper
      include GitWrapper

      TIMESTAMP_FORMAT = "%Y.%m.%d.%H.%M"

      banner %Q(
        Create and push a timestamped tag with an optional suffix
      )

      parameter "[SUFFIX]", "Suffix to apply to to the dated tag"
      option "--force", :flag, "Create tag even if not on deploy branch"

      def execute
        if should_create_branch?
          tag_release
        else
          raise Clamp::UsageError.new("Must perform this script from the deploy branch (#{config.deploy_branch})", self)
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
        tag = Time.now.strftime(TIMESTAMP_FORMAT)
        if suffix
          tag = "#{tag}_#{suffix}"
        end
        tag
      end
    end
  end
end

