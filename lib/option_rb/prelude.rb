# frozen_string_literal: true

require 'option_rb'

# Define some constructors for `Option`s
module OptionRb
  def Some(value) # rubocop:disable Naming/MethodName
    Some.new(value)
  end

  def None # rubocop:disable Naming/MethodName
    None.new
  end
end

# Export the `Option` class and its constructors into the global namespace
include OptionRb # rubocop:disable Style/MixinUsage

def match(option, &block)
  option.match(&block)
end

# "Loose" match (non-exhaustive)
def lmatch(option, &block)
  option.lmatch(&block)
end
