desc "Create a pull request from the current branch to the application's designated deploy branch."
command 'pull-request' do |c|
  config = Octopolo::Config.parse

  c.desc "Branch to create the pull request against"
  c.flag [:d, :dest, :destination], :arg_name => "destination_branch", :default_value => config.deploy_branch

  c.action do |global_options, options, args|
    require_relative '../scripts/pull_request'
    options = global_options.merge(options)
    Octopolo::Scripts::PullRequest.execute options[:destination]
  end
end
