# frozen_string_literal: true


task default: %i[test]

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
end

require 'rubygems/package_task'
spec = Gem::Specification.load(File.expand_path('plist_lite.gemspec', __dir__))
Gem::PackageTask.new(spec).define

require 'rake/extensiontask'
Rake::ExtensionTask.new('plist_lite/ext', spec)
