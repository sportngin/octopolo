arg :pull_request_id

desc 'Provide standardized signoff message to a pull request.'
long_desc "pull_request_id - The ID of the pull request to sign off on"
command 'signoff' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/signoff'
    Octopolo::Scripts::Signoff.execute args.first
  end
end
