require "octopolo/scripts"

module Octopolo
  module Scripts
    class CompareRelease < Clamp::Command
      include ConfigWrapper
      include CLIWrapper
      include GitWrapper

      parameter "[START]", "starting tag"
      parameter "[STOP]", "ending tag"

      def execute
        ask_starting_tag
        ask_stopping_tag
        open_compare_page
      end

      # Public: Ask, if not already set, which tag to start with
      def ask_starting_tag
        self.start ||= cli.ask("Start with which tag?", git.recent_release_tags)
      end

      # Public: Ask, if not already set, which tag to end with
      def ask_stopping_tag
        self.stop ||= cli.ask("Compare from #{start} to which tag?", git.recent_release_tags)
      end

      # Public: Open the GitHub compare URL for the starting and ending branches
      def open_compare_page
        cli.copy_to_clipboard compare_url
        cli.open compare_url
      end

      # Public: The GitHub compare URL for the selected tags
      def compare_url
        "https://github.com/#{config.github_repo}/compare/#{start}...#{stop}?w=1"
      end
    end
  end
end

