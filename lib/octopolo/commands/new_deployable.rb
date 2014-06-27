desc "Create a new deployable branch"
long_desc "Create a new deployable branch with today's date and remove the others.

Useful when we have changes in the current deployable branch that we wish to remove."
command 'new-deployable' do |c|
  require_relative '../scripts/new_deployable'
  c.action { Octopolo::Scripts::NewDeployable.new.execute }
end
