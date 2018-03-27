# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 's3/version'

Gem::Specification.new do |spec|
  spec.name          = "s3-client"
  spec.version       = S3::VERSION
  spec.authors       = ["hiro-su"]
  spec.email         = ["h.sugipon@gmail.com"]
  spec.description   = %q{It is a simple AWS S3 library for Ruby}
  spec.summary       = %q{Is is a simple AWS S3 library for Ruby}
  spec.homepage      = "http://github.com/hiro-su/s3-client"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/).reject {|item| item =~ /^(sample|doc|README|CHANGELOG|.drone.yml|spec|.rspec)/ }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "httpclient", "~> 2.8.0"
  spec.add_dependency "settingslogic", "~> 2.0.9"
  spec.add_dependency "mime-types", "~> 3.1"
  spec.add_dependency "xml-simple", "~> 1.1.4"
  spec.add_dependency "driver", "~> 0.0.4"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1.0"
end
