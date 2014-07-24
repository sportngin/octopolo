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
        (self.name == obj.name) ? true : false
      end

      # Public: Grabs all labels from either file or github
      #         This is the method to override for labels from files
      def self.all_labels        
        from_github
      end

      # Public: Gets the names of labels
      #
      # label_array - an array of labels
      #
      # returns - an array of all names from label_array
      def self.get_names(label_array)
        label_array.map{ |label| label.name }
      end

      # Public: Checks to see if label exists on remote, if not makes one.
      #
      # label - a label object
      def self.first_or_create(label)
        unless all_labels.include?(label)
          GitHub.add_label(config.github_repo, label.name, label.color)
        end
      end

      # Public: Adds labels to a pull-request
      #
      # labels - an array of labels
      # pull_number - number of the pull_request to add label to
      def self.add_to_pull(pull_number, *labels)
        built_labels = build_label_array(labels)
        GitHub.add_labels_to_pull(config.github_repo, pull_number, get_names(built_labels) )
      end

      # Private: takes in a hash, out puts a label
      # 
      # label_hash - a hashed label
      #
      # returns - a label object
      def self.to_label(label_hash)
        Label.new(label_hash[:name], label_hash[:color])
      end
      private_class_method :to_label

      # Private: Gets all the labels from given repository on github
      #
      # returns - an array of labels
      def self.from_github
        GitHub.labels(config.github_repo).map{ |label_hash| to_label(label_hash) }
      end
      private_class_method :from_github

      # Private: Finds or creates each of the passed in labels
      #
      # labels - label objects, can be a single label, an array of labels,
      #          or a list of labels
      # 
      # returns - an array of labels.
      def self.build_label_array(*labels)
        Array(labels).flatten.each {|label| first_or_create(label)}
      end
      private_class_method :build_label_array

    end
  end
end