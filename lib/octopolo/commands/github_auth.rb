desc 'Generate a GitHub auth token for octopolo commands to use.'
command 'github-auth' do |c|
  require_relative '../scripts/github_auth'
  c.action { Octopolo::Scripts::GithubAuth.execute }
end
