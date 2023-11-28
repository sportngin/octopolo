arg :pull_request_id
desc 'Accept pull requests. Merges the given pull request into main and updates the changelog.'
command 'accept-pull' do |c|
  c.switch [:f, :force], default_value: false, desc: 'Ignore the status checks on the pull request', negatable: false
  c.action do |global_options, options, args|
    require_relative '../scripts/accept_pull'
    Octopolo::Scripts::AcceptPull.execute(args.first, options)
  end
end
