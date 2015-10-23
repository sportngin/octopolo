arg :pull_request_id
desc 'Merges PR into the staging branch'
command 'stage-up' do |c|


  c.desc "Skip validations."
  c.switch :skip_validations, :negatable => false
  c.action do |global_options, options, args|
    require_relative '../scripts/stage_up'
    options = global_options.merge(options)
    Octopolo::Scripts::StageUp.execute(args.first, options)
  end
end
