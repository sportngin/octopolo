require_relative "../github"
require "octokit"

module Octopolo
  module GitHub
    class Label
      attr_accessor :name
      attr_accessor :color

      # Public: Gets all the labels from given repository
      # repo_name - Full name ("account/repo") of the repo in question
      def self.get_labels repo_name
        labels = GitHub.labels repo_name
        labels.map!{|v| v.delete("url").symbolize_keys}
      end


    end
  end
end

