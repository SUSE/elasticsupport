# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "elasticsupport/version"

Gem::Specification.new do |s|
  s.name        = "elasticsupport"
  s.version     = Elasticsupport::VERSION
  s.authors     = ["Klaus Kämpf"]
  s.email       = ["kkaempf@suse.de"]
  s.homepage    = "http://github.com/SUSE/elasticsupport"
  s.summary     = %q{Library to import SUSE supportconfig data into Elasticsearch}
  s.description = %q{Library to import SUSE supportconfig data into Elasticsearch}

  s.add_dependency("supportconfig", ["~> 0.0.1"])

  s.rubyforge_project = "elasticsupport"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
