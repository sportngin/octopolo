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

  gem.add_dependency 'gli', '~> 2.19.0'
  gem.add_dependency 'hashie', '~> 4.1.0'
  gem.add_dependency 'octokit', '~> 4.17.0'
  gem.add_dependency 'public_suffix', '~> 4.0.3'
  gem.add_dependency 'highline', '~> 2.0.3'
  gem.add_dependency 'jiralicious', '~> 0.5'
  gem.add_dependency 'semantic', '~> 1.6.1'

  gem.add_development_dependency 'rake', '~> 13.0.1'
  gem.add_development_dependency 'bundler', '~> 1.17'
  gem.add_development_dependency 'rspec', '~> 3.9.0'
  gem.add_development_dependency 'guard', '~> 2.16.0'
  gem.add_development_dependency 'guard-rspec', '~> 4.7.3'
  gem.add_development_dependency 'hitimes', '~> 2.0.0'
  gem.add_development_dependency 'octopolo-plugin-example', '~> 0'
end
