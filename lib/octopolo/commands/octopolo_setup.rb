desc 'Basic setup for octoplo'
command 'setup' do |c|
  require_relative '../scripts/octopolo_setup'
  c.action { Octopolo::Scripts::OctopoloSetup.invoke }
end
