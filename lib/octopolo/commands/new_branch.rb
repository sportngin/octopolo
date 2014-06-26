arg :new_branch_name,    :name => 'new_branch_name'
arg :source_branch_name, :name => 'source_branch_name', :optional => true
desc 'Create a new branch for features, bug fixes, or experimentation.'
command 'new-branch' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/new_branch'
    Octopolo::Scripts::NewBranch.execute args[0], args[1]
  end
end
