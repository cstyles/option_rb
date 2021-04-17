# frozen_string_literal: true

if ENV['MEASURE_COVERAGE']
  require 'simplecov'

  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'option_rb'

require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/minitest'
require 'shoulda-context'

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new
