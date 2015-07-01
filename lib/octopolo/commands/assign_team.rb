desc "Save team assignment to octopolo user config"
command 'assign-team' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/assign_team'
    Octopolo::Scripts::AssignTeam.execute
  end
end
