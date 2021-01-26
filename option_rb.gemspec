# frozen_string_literal: true

require_relative 'lib/option_rb/version'

Gem::Specification.new do |spec|
  spec.name          = 'option_rb'
  spec.version       = OptionRb::VERSION
  spec.authors       = ['Collin Styles']
  spec.email         = ['collin.styles@mycase.com']

  spec.summary       = "A port of Rust's `Option` type to Ruby."
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/mycase/option_rb'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = `git ls-files lib`.split("\n")

  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-reporters', '~> 1.4'
  spec.add_development_dependency 'mocha', '~> 1.11'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.8'
  spec.add_development_dependency 'rubocop-minitest', '~> 0.10.3'
  spec.add_development_dependency 'rubocop-rake', '~> 0.5.1'
  spec.add_development_dependency 'shoulda-context', '~> 2.0'
  spec.add_development_dependency 'simplecov', '~> 0.20.0'
end
