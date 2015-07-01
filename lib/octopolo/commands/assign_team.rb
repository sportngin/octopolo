arg :pull_request_id
desc "Assigns a team to .octopolo.yml in user's home directory"
command 'assign-team' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/assign_team'
    Octopolo::Scripts::AssignTeam.execute args.first
  end
end
