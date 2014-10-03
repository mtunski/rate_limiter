# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rate_limiter/version'

Gem::Specification.new do |spec|
  spec.name          = 'rate_limiter'
  spec.version       = RateLimiter::VERSION
  spec.authors       = ['Mateusz Tuński']
  spec.email         = ['mateusz@tunski.net']
  spec.summary       = 'PA Workshop: Rack'
  spec.description   = ''
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',   '~> 1.7'
  spec.add_development_dependency 'rake',      '~> 10.0'
  spec.add_development_dependency 'rack-test', '~> 0.6'
  spec.add_development_dependency 'minitest',  '~> 5.4'
end
