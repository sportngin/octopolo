arg :start, :name => 'starting_tag', :optional => true
arg :stop,  :name => 'ending_tag',   :optional => true
desc 'Opens up a link to compare releases'
command 'compare-release' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/compare_release'
    Octopolo::Scripts::CompareRelease.execute args[0], args[1]
  end
end
