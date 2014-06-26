arg :pull_request_id
desc 'Accept pull requests. Merges the given pull request into master and updates the changelog.'
command 'accept-pull' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/accept_pull'
    Octopolo::Scripts::AcceptPull.execute args.first
  end
end
