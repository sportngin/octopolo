require_relative "../scripts"

module Octopolo
  module Scripts
    class AssignTeam
      include CLIWrapper
      include ConfigWrapper

      attr_accessor :options

      def self.execute
        new.execute
      end

      def initialize(options = nil)
        @options = options
      end

      # Public: Perform the script
      def execute
        ask_team
      end

      def ask_team
        teams = Octopolo::Github::Label.get_names(team_label_choices)
        if teams.nil?
          team_name = String(cli.prompt "Please type in your team name: ")
          team = "Team #{team_name}"
          color = "%06x" % (rand * 0xffffff)
          label = {:name => team, :color => color}
          Octopolo::Github::Label.first_or_create(label)
        else
          cli.ask("Assign yourself to which team?", teams)
          team = Hash[team_label_choices.map{|t| [t.name, t]}][response]
        end
        Octopolo::UserConfig.set(:team, team)
      end

      def team_label_choices
        Octopolo::GitHub::Label.where("label.name.start_with?(Team)")
      end
    end
  end
end
