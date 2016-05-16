desc "Create an issue for the current project."
command 'issue' do |c|
  c.desc "Use $EDITOR to update PR description before creating"
  c.switch [:e, :editor], :default_value => Octopolo.user_config.editor

  c.action do |global_options, options, args|
    require_relative '../scripts/issue'
    options = global_options.merge(options)
    Octopolo::Scripts::Issue.execute options
  end
end
