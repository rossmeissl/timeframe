# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "timeframe/version"

Gem::Specification.new do |s|
  s.name        = "timeframe"
  s.version     = Timeframe::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Andy Rossmeissl", "Seamus Abshere", "Derek Kastner"]
  s.email       = ["andy@rossmeissl.net"]
  s.homepage    = "http://github.com/rossmeissl/timeframe"
  s.summary     = %Q{Date intervals}
  s.description = %Q{A Ruby class for describing and interacting with timeframes.}

  s.rubyforge_project = "timeframe"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency "rspec", ">= 1.2.9"
  s.add_dependency 'activesupport', '>=2.3.5'
end
