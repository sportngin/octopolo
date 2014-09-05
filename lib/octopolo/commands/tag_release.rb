desc "Create and push a tag (timestamped tag with an optional suffix or semantic version tag)"
command 'tag-release' do |c|
  c.flag :prefix, :desc => "Prefix to apply to to the tag"
  c.flag :suffix, :desc => "Suffix to apply to to the tag"

  c.desc "Create tag even if not on deploy branch"
  c.switch :force, :negatable => false
  c.desc "Increment major version (if semantic_versioning enabled)"
  c.switch :major, :negatable => false
  c.desc "Increment minor version (if semantic_versioning enabled)"
  c.switch :minor, :negatable => false
  c.desc "Increment patch version (if semantic_versioning enabled)"
  c.switch :patch, :negatable => false

  c.action do |global_options, options, args|
    require_relative '../scripts/tag_release'
    options = global_options.merge(options)
    Octopolo::Scripts::TagRelease.execute args.first, options
  end
end
