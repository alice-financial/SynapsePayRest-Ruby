lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'synapse_pay_rest'
  s.version     = '0.0.12'
  s.date        = %q{2015-10-03}
  s.summary     = "SynapsePay v3 Rest API Wrapper"
  s.description = "A simple ruby wrapper for the SynapsePay v3 Rest API"
  s.authors     = ["Thomas Hipps"]
  s.email       = 'thomas@synapsepay.com'
  s.homepage    = 'https://rubygems.org/gems/synapse_pay_rest'
  s.license     = 'MIT'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.10"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "minitest"
  s.add_development_dependency "minitest-reporters"

  s.add_dependency "rest-client"
end
