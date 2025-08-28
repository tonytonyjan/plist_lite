# frozen_string_literal: true


task default: %i[test]

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/ext_test.rb']
end
Rake::TestTask.new do |t|
  t.test_files = FileList['test/pure_ruby_test.rb']
end

require 'rubygems/package_task'
spec = Gem::Specification.load(File.expand_path('plist_lite.gemspec', __dir__))
Gem::PackageTask.new(spec).define
java_spec = spec.dup
java_spec.platform = 'java'
java_spec.extensions.clear
java_spec.files.delete 'ext/plist_lite/ext/ext.c'
Gem::PackageTask.new(java_spec).define

require 'rake/extensiontask'
Rake::ExtensionTask.new('plist_lite/ext', spec)
