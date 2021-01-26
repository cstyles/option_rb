# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'option_rb/prelude'

require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/minitest'
require 'shoulda-context'

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
