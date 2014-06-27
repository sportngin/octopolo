desc "Create a new staging branch"
long_desc "Create a new staging branch with today's date and remove the others.

Useful when we have changes in the current staging branch that we wish to remove."
command 'new-staging' do |c|
  require_relative '../scripts/new_staging'
  c.action { Octopolo::Scripts::NewStaging.new.execute }
end
