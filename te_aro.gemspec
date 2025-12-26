# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'te_aro/version'

Gem::Specification.new do |spec|
  spec.name          = 'te_aro'
  spec.version       = TeAro::VERSION
  spec.authors       = ['Michael Fowler', 'Paolo Veñegas', 'aj esler']
  spec.email         = ['michael.fowler@powershop.co.nz', 'pvenegas@gmail.com', 'aj@powershop.co.nz']

  spec.summary       = 'ActiveRecord observer'
  spec.description   = 'This tool monitors ActiveRecord changes'
  spec.homepage      = 'https://github.com/pmvenegas/te_aro'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'sqlite3'
end
