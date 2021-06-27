# frozen_string_literal: true

require 'benchmark'
require 'plist'
require 'plist_lite'
require 'plist_lite/ext'

n = 100_000
obj = {
  'foo' => 'foo', 'bar' => 123,
  'ary' => [1, 2, 3, { 'foo' => 'bar', 'bar' => [4, 5, 6] }]
}

Benchmark.bmbm do |bench|
  bench.report('Plist::Emit.dump') { n.times { Plist::Emit.dump(obj) } }
  bench.report('PlistLite.dump') { n.times { PlistLite.dump(obj) } }
end
