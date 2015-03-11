desc "Get information about a pull request."
command 'pr-info' do |c|
  config = Octopolo::Config.parse
  user_config = Octopolo::UserConfig.parse

  c.desc "Get pull request information."
  c.flag [:n, :num]
  c.flag [:b, :branch]
  c.switch [:o, :open]
  c.switch [:v, :verbose]

  c.action do |global_options, options, args|
    require_relative '../scripts/pr_info'
    options[:raw_arg] = args[0]
    options = global_options.merge(options)
    Octopolo::Scripts::PrInfo.execute(config.github_repo, options)
  end
end
