# -*- encoding: utf-8 -*-
require File.expand_path('../lib/octopolo/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Patrick Byrne", "Luke Ludwig"]
  gem.email         = ["patrick.byrne@sportngin.com", "luke.ludwig@sportngin.com"]
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

  gem.add_dependency 'rake', '~> 10.4'
  gem.add_dependency 'gli', '~> 2.13'
  gem.add_dependency 'hashie', '~> 1.2'
  gem.add_dependency 'octokit', '~> 2.7'
  gem.add_dependency 'highline', '~> 1.6'
  gem.add_dependency 'pivotal-tracker', '~> 0.5'
  gem.add_dependency 'jiralicious', '~> 0.4'
  gem.add_dependency 'semantic', '~> 1.3'

  gem.add_development_dependency 'rspec', '~> 2.99'
  gem.add_development_dependency 'guard', '~> 2.6'
  gem.add_development_dependency 'guard-rspec', '~> 4.3'
  gem.add_development_dependency 'octopolo-plugin-example', '~> 0'
end
