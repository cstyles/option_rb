#!/usr/bin/env ruby
# frozen_string_literal: true

require 'option_rb/prelude'

def main
  option = Some('hello')
  puts "option = #{option}"

  value = option.q?
  # Equivalent:
  # val = option.unwrap_or_else { return None() }

  puts "value = #{value}"
  puts

  option = None()
  puts "option = #{option}"

  value = option.q?

  puts "this line isn't reached:"
  puts "value = #{value}"

  Some("this return value isn't reached")
end

val = main
puts
puts "main => #{val}"
