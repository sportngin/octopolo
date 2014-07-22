require_relative "../github"
require "yaml"
require "octokit"

module Octopolo
  module GitHub
    class Label
      extend ConfigWrapper

      attr_accessor :name
      attr_accessor :color

      def initialize(name, color)
        self.name = name
        self.color = color
      end

      def == (obj)
        return true if ((self.name == obj.name) && (self.color == obj.color))
      end

      # Public: Grabs all labels from either file or github
      #         This is the method to override for labels from files
      def self.all_labels        
        from_github
      end

      # Public: Checks to see if label exists on remote, if not makes one.
      def self.first_or_create(label)
        if !(all_labels.include? label)
          GitHub.add_label(config.github_repo, label.name, label.color)
        end
      end

      # Public: Adds labels to a pull-request
      #
      # labels: an array of labels
      # pull_number: number of the pull_request to add label to
      def self.add_to_pull(pull_number, labels)
        if !(labels.is_a? Array)
          labels = [labels]
        end

        labels.each {|label| first_or_create(label) }
        GitHub.add_labels_to_pull(config.github_repo, pull_number, labels.map{ |label| label.name } )
      end

      # Private: takes in a hash, out puts a label
      #  
      def self.to_label(label_hash)
        Label.new(label_hash[:name], label_hash[:color])
      end
      private_class_method :to_label

      # Private: Gets all the labels from given repository on github
      def self.from_github
        GitHub.labels(config.github_repo).map{ |label_hash| to_label(label_hash) }
      end
      private_class_method :from_github

    end
  end
end