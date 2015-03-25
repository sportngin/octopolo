desc "Create a new deployable branch"
long_desc "Create a new deployable branch with today's date and remove the others.

Useful when we have changes in the current deployable branch that we wish to remove."
command 'new-deployable' do |c|
  c.switch :delete_old_branches, :default_value => false, :desc => "Should old deployable branches be deleted?", :negatable => false

  c.action do |global_options, options, args|
    require_relative '../scripts/new_deployable'
    options = global_options.merge(options)
    Octopolo::Scripts::NewDeployable.new.execute(options[:delete_old_branches])
  end
end
