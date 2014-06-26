desc "View and delete stale branches"
command 'stale-branches' do |c|
  c.desc "Delete the stale branches (default: false)"
  c.switch :delete, :negatable => false

  c.action do |global_options, options, args|
    require_relative '../scripts/stale_branches'
    options = global_options.merge(options)
    Octopolo::Scripts::StaleBranches.new(options[:delete]).execute
  end
end
