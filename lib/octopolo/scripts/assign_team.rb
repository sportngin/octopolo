require_relative "../scripts"
require_relative "../github"

module Octopolo
  module Scripts
    class AssignTeam
      include CLIWrapper
      include ConfigWrapper

      attr_accessor :options

      # Public: executes the command
      def self.execute
        new.execute
      end

      # Public: makes a new instance of this command
      def initialize(options = nil)
        @options = options
      end

      # Public: executes the command
      def execute
        ask_team
      end

      # Public: asks the user what team they belong to and sets the team in the user's config file
      def ask_team
        if config.config_exists? == false
          team = type_team
        else # Currently set to only look for teams with the format "team-______"
          teams = Octopolo::GitHub::Label.get_names(team_label_choices).find_all {|name| name.start_with?("team-")}
          if teams.empty?
            team = type_team
            label = Octopolo::GitHub::Label.new(:name => team)
            Octopolo::GitHub::Label.first_or_create(label)
          else
            response = cli.ask("Assign yourself to which team?", teams)
            team = Hash[team_label_choices.map{|t| [t.name, t]}][response]
          end
        end
        Octopolo::UserConfig.set(:team, team)
      end

      # Public: gets all of the labels for current repository
      def team_label_choices
        Octopolo::GitHub::Label.all
      end

      # Public: asks to type in the team name and returns that name with the format "team-______"
      def type_team
        team_name = String(cli.prompt "Please type in your team name: ")
        return "team-#{team_name}"
      end
    end
  end
end
