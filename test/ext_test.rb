# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'tests'
require 'plist_lite/pure_ruby'
require 'plist_lite/ext'

class ExtTest < Minitest::Test
  include Tests
end
