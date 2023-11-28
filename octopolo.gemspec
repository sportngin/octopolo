# -*- encoding: utf-8 -*-
require File.expand_path('../lib/octopolo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Patrick Byrne", "Luke Ludwig", "Sport Ngin Platform Operations"]
  gem.email         = ["patrick.byrne@sportngin.com", "luke.ludwig@sportngin.com", "platform-ops@sportngin.com"]
  gem.description   = %q{A set of GitHub workflow scripts.}
  gem.summary       = %q{A set of GitHub workflow scripts to provide a smooth development process for your projects.}
  gem.homepage      = "https://github.com/sportngin/octopolo"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "octopolo"
  gem.license       = "MIT"
  gem.require_paths = ["lib"]
  gem.version       = Octopolo::VERSION

  gem.required_ruby_version = '>= 3.2'

  gem.add_dependency 'gli', '~> 2.13'
  gem.add_dependency 'hashie', '~> 5.0'
  gem.add_dependency 'octokit', '~> 8.0'
  gem.add_dependency 'faraday-retry', '~> 2.0'
  gem.add_dependency 'public_suffix', '~> 5.0'
  gem.add_dependency 'highline', '~> 2.0'
  gem.add_dependency 'semantic', '~> 1.3'
  gem.add_dependency 'nokogiri-happymapper', '~> 0.6'

  gem.add_development_dependency 'rake', '~> 10.1'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'guard-rspec', '~> 4.3'
  gem.add_development_dependency 'hitimes', '~> 1.2.6'
  gem.add_development_dependency 'octopolo-plugin-example', '~> 0'
end
