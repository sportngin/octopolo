desc 'Opens the Pull Request in your default browser'
command 'view-pr' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/view_pr'
    Octopolo::Scripts::ViewPr.execute
  end
end
