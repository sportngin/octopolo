require "yaml"
require "octokit"
require "pry"

module Octopolo
  module GitHub
    class Label
      extend ConfigWrapper

      attr_accessor :name
      attr_accessor :color

      def initialize(args)
        self.name = args[:name]
        self.color = args[:color]
      end

      def == (obj)
        (self.name == obj.name) ? true : false
      end

      # Public: Grabs all labels from either file or github
      #         This is the method to override for labels from files
      def self.all
        all_from_repo
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
        unless all_from_repo.include?(label)
          GitHub.add_label(config.github_repo, label.name, label.color)
        end
      end

      # Public: Finds or creates each of the passed in labels
      #
      # labels - label objects, can be a single label, an array of labels,
      #          or a list of labels
      #
      # returns - an array of labels.
      def self.build_label_array(*labels)
        Array(labels).flatten.each {|label| first_or_create(label)}
      end

      # Private: Gets all the labels from given repository on github
      #
      # returns - an array of labels
      def self.all_from_repo
        all_labels = []
        result = 1
        counter = 1

        while result > 0
          labels = GitHub.labels(config.github_repo, page: counter)
          all_labels.concat(labels)
          result = labels.count
          counter += 1
        end

        all_labels.map{ |label_hash| new(label_hash) }
      end
      private_class_method :all_from_repo
    end
  end
end
