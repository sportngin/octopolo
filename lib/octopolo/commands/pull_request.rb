desc "Create a pull request from the current branch to the application's designated deploy branch."
command 'pull-request' do |c|
  c.desc "Branch to create the pull request against"
  c.flag [:d, :dest, :destination], :arg_name => "destination_branch", :default_value => Octopolo.config.deploy_branch

  c.desc "Pass -sd to skip creating this pull request as a draft"
  c.switch [:sd, :skip_draft], :arg_name => "skip_draft"

  c.desc "Pass -x to skip the prompt and infer from branch. Expects the branch to be in this format: JIRA-123_describe_pr OR JIRA_123_describe_pr"
  c.switch [:x, :expedite], :arg_name => "expedite"

  c.desc "Use $EDITOR to update PR description before creating"
  c.switch [:e, :editor], :default_value => Octopolo.user_config.editor

  c.action do |global_options, options, args|
    require_relative '../scripts/pull_request'
    options = global_options.merge(options)
    Octopolo::Scripts::PullRequest.execute options[:destination], options
  end
end
