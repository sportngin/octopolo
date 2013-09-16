require_relative "../git"
require_relative "../zapier"

module Octopolo
  module Zapier
    class BranchPoster
      attr_accessor :application_name
      attr_accessor :branch_name
      attr_accessor :branch_type

      # Public: Instantiate a new BranchPoster
      #
      # application_name - Name of the affected application
      # branch_name - Name of the branch to announce
      # branch_type - Name of the type of branch (e.g., staging or deployable)
      def initialize application_name, branch_name, branch_type
        self.application_name = application_name
        self.branch_name = branch_name
        self.branch_type = branch_type
      end

      # Public: Announce that a new branch is created
      #
      # application_name - Name of the affected application
      # branch_name - Name of the branch to announce
      # branch_type - Name of the type of branch (e.g., staging or deployable)
      #
      # Returns a BranchPoster
      def self.perform application_name, branch_name, branch_type
        new(application_name, branch_name, branch_type).tap do |poster|
          poster.perform
        end
      end

      # Public: Announce that the poster's branch is created
      def perform
        command = %Q(curl -H 'Content-Type: application/json' -X POST -d '{"message": "#{message}"}' '#{Zapier.endpoint Zapier::MESSAGE_TO_DEVO}')
        Octopolo::CLI.perform_quietly command
      end

      # Public: The message to send about the new branch
      #
      # Returns a String containing the message
      def message
        base = "A new #{branch_type} branch (#{branch_name}) has been created for #{application_name}."
        case branch_type
        when Git::STAGING_PREFIX
          "#{base} If you have pending pull requests, please re-merge with the `stage-up` command."
        when Git::DEPLOYABLE_PREFIX
          "#{base} If you have pending pull requests, please re-merge with the `deployable` command."
        end
      end
    end
  end
end
