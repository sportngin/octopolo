arg :suffix, :desc => "Suffix to apply to to the dated tag"

desc "Create and push a timestamped tag with an optional suffix"
command 'tag-release' do |c|
  c.desc "Create tag even if not on deploy branch"
  c.switch :force, :negatable => false

  c.action do |global_options, options, args|
    require_relative '../scripts/tag_release'
    options = global_options.merge(options)
    Octopolo::Scripts::TagRelease.execute args.first, options[:force]
  end
end
