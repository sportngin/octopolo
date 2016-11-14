arg :pull_request_id
desc 'Merges PR into the deployable branch'
command 'deployable' do |c|
  c.switch [:f, :force], default_value: false, desc: 'Ignore the status checks on the pull request', negatable: false
  c.action do |global_options, options, args|
    require_relative '../scripts/deployable'
    Octopolo::Scripts::Deployable.execute(args.first, options)
  end
end
