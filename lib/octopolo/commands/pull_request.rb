desc "Create a pull request from the current branch to the application's designated deploy branch."
command 'pull-request' do |c|
  config = Octopolo::Config.parse
  user_config = Octopolo::UserConfig.parse

  c.desc "Branch to create the pull request against"
  c.flag [:d, :dest, :destination], :arg_name => "destination_branch", :default_value => config.deploy_branch

  c.desc "Use $EDITOR to update PR description before creating"
  c.switch [:e, :editor], :default_value => user_config.editor

  c.action do |global_options, options, args|
    require_relative '../scripts/pull_request'
    options = global_options.merge(options)
    Octopolo::Scripts::PullRequest.execute options[:destination], options
  end
end
