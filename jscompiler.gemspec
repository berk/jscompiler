# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'jscompiler/version'
 
Gem::Specification.new do |spec|
  spec.name        = "jscompiler"
  spec.version     = Jscompiler::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ["Michael Berkovich"]
  spec.email       = ["theiceberk@gmail.com"]
  spec.homepage    = "https://github.com/berk/jscompiler"
  spec.summary     = "JavaScript Compiler (JSC)"
  spec.description = "Utility that allows you to use various JS compilers to compress and uglify your JavaScript code."
 
  spec.files        = Dir.glob("{bin,lib,vendor}/**/*") + %w(LICENSE README.rdoc)
  spec.executables  = spec.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  spec.test_files   = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_path = ['lib', 'lib/jscompiler']

  spec.add_runtime_dependency 'thor', '~> 0.16.0'
  spec.add_dependency "fssm"
end
