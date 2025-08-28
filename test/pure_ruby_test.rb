# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'tests'
require 'plist_lite/pure_ruby'

class PureRubyTest < Minitest::Test
  include Tests
end
