# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "oknok/version"

Gem::Specification.new do |s|
  s.name        = "oknok"
  s.version     = Oknok::VERSION
  s.authors     = ["Dave M"]
  s.email       = ["dmarti21@gmail.com"]
  s.homepage    = "http://github.com/forforf"
  s.summary     = %q{Datastore inventory tool}
  s.description = %q{Allows a collection of datastores to be defined in a config file, and provides the hooks into those datastores. Also has convenient hooks for non-permanent stores such as EC2 instances}

  s.rubyforge_project = "oknok"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  #Test Dependencies
  s.add_development_dependency "rspec"
  s.add_development_dependency "psych"
  
  #Core Dependencies
  s.add_runtime_dependency "uri"
  s.add_runtime_dependency "open-uri"
  s.add_runtime_dependency "json"
  
  #Built-in Library Dependencies
  s.add_runtime_dependency "rest-client"
  s.add_runtime_dependency "fileutils"
  s.add_dependency(%q{couchrest}, ["~> 1.0.2"])
  s.add_dependency(%q{mysql}, ["~> 2.8.1"])
  s.add_dependency(%q{dbi}, ["~> 0.4.5"])
  #s.add_dependency(%q{aws-s3}, ["~> 0.6.2"])
  #s.add_dependency(%q{aws-sdb}, ["~> 0.3.1"])
  s.add_dependency(%q{forforf-aws-sdb}, ["~> 0.5.3"])
end
