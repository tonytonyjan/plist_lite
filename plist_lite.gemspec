# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 2.7'
  spec.name = 'plist_lite'
  spec.version = '1.1.0'
  spec.author = 'Weihang Jian'
  spec.email = 'tonytonyjan@gmail.com'
  spec.summary = 'plist_lite is the fastest plist processor for Ruby written in C.'
  spec.description =
    'plist_lite is the fastest plist processor for Ruby written in C.' \
    'It can convert Ruby object to XML plist (a.k.a. property list), vice versa.'
  spec.platform = Gem::Platform::RUBY
  spec.files = Dir['lib/**/*', 'ext/plist_lite/ext/ext.c']
  spec.extensions = ['ext/plist_lite/ext/extconf.rb']
  spec.homepage = 'https://github.com/tonytonyjan/plist_lite'
  spec.license = 'MIT'
  spec.add_runtime_dependency 'nokogiri', '~> 1.0'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rake-compiler', '~> 1.0'
end
