require_relative "../scripts"
require_relative "../github"

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

      def execute
        ask_team
      end

      def ask_team
        if config.config_exists? == false
          team = type_team
          Octopolo::UserConfig.set(:team, team)
        else
          teams = Octopolo::GitHub::Label.get_names(team_label_choices).find_all {|name| name.start_with?("Team")}
          if teams.empty?
            team = type_team
            color = "%06x" % (rand * 0xffffff)
            label = {:name => team, :color => color}
            Octopolo::GitHub::Label.first_or_create(label)
          else
            response = cli.ask("Assign yourself to which team?", teams)
            team = Hash[team_label_choices.map{|t| [t.name, t]}][response]
          end
          Octopolo::UserConfig.set(:team, team)
        end
      end

      def team_label_choices
        Octopolo::GitHub::Label.all
      end

      def type_team
        team_name = String(cli.prompt "Please type in your team name: ")
        return "Team #{team_name}"
      end
    end
  end
end
