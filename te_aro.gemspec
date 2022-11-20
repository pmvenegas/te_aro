# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'te_aro/version'

Gem::Specification.new do |spec|
  spec.name          = 'te_aro'
  spec.version       = TeAro::VERSION
  spec.authors       = ['Michael Fowler', 'Paolo Veñegas', 'aj esler']
  spec.email         = ['michael.fowler@powershop.co.nz', 'pvenegas@gmail.com', 'aj@powershop.co.nz']

  spec.summary       = %q{Observe ActiveRecord runtime behaviour}
  spec.description   = %q{See which objects have changed, what new objects were created, and which callbacks were triggered}
  spec.homepage      = 'https://github.com/pmvenegas/te_aro'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'activerecord' # TODO: specify version
  spec.add_development_dependency 'sqlite3', '~> 1.3'
  spec.add_development_dependency 'bundler', '~> 2'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 0'
end
