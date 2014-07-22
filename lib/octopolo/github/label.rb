require_relative "../github"
require_relative "../support"
require "yaml"
require "octokit"

module Octopolo
  module GitHub
    class Label
      extend ConfigWrapper
      extend Octopolo::Support

      # Public: Gets all the labels from given repository on github
      def self.from_github
        symbolize_array(GitHub.labels(config.github_repo))
          .map{ |label| label.reject{ |key,value| key == :url} }
      end

      # Public: Creates an array of all label names on a repo
      def self.all_names
        from_github().map{ |label| label[:name]}
      end

      # Public: Checks to see if label exists on remote, if not makes one.
      def self.first_or_create(name, color)
        if !(all_names.include? name)
          GitHub.add_label(config.github_repo, name, color)
        end
      end

    end
  end
end