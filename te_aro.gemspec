# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'te_aro/version'

Gem::Specification.new do |spec|
  spec.name          = "te_aro"
  spec.version       = TeAro::VERSION
  spec.authors       = ["Michael Fowler", "Van Veñegas", "aj esler"]
  spec.email         = ["michael.fowler@powershop.co.nz", "van.venegas@powershop.co.nz", "aj@powershop.co.nz"]

  spec.summary       = %q{Observe ActiveRecord's actions}
  spec.description   = %q{See which objects have changed, what new objects were created, and which callbacks were triggered}
  spec.homepage      = "https://git.powershop.co.nz/powershop/te_aro"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 0"
end
