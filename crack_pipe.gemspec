require File.expand_path('lib/crack_pipe/version', __dir__)

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 2.2.0'

  s.name          = 'crack_pipe'
  s.version       = CrackPipe.version
  s.authors       = %w[Joshua Hansen]
  s.email         = %w[joshua@epicbanality.com]

  s.summary       = 'Pipelines... on crack I guess.'
  s.description   = s.summary
  s.homepage      = 'https://github.com/binarypaladin/crack_pipe'
  s.license       = 'MIT'

  s.files         = %w[LICENSE.txt README.md] + Dir['lib/**/*.rb']
  s.require_paths = %w[lib]

  s.add_development_dependency 'bundler',  '~> 1.16'
  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rake',     '~> 10.0'
end
