desc 'Generate a Pivotal Tracker auth token for Octopolo commands to use.'
command 'pivotal-auth' do |c|
  require_relative '../scripts/pivotal_auth'
  c.action { Octopolo::Scripts::PivotalAuth.execute }
end
