config = Octopolo::Config.parse
long_desc "branch - Which branch to merge into yours (default: #{config.deploy_branch})"

arg :branch
desc "Merge the #{config.deploy_branch} branch into the current working branch"
command 'sync-branch' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/sync_branch'
    Octopolo::Scripts::SyncBranch.execute args.first
  end
end
