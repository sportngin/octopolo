arg :pull_request_id
desc 'Merges PR into the staging branch'
command 'stage-up' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/stage_up'
    Octopolo::Scripts::StageUp.execute args.first
  end
end
