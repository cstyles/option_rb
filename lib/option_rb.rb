# frozen_string_literal: true

module OptionRb
  # A class representing an optional value
  class Option
    # Hide `new` to force users to go through the approved constructors
    private_class_method :new

    def self.from(value)
      if value.nil?
        none
      else
        some(value)
      end
    end

    def self.some(value)
      Some.new(value)
    end

    def self.none
      None.new
    end

    def match(exhaustive: true, &block)
      raise ArgumentError, 'no block given' unless block_given?

      # Clear these in case we matched on this Option earlier.
      # Especially useful if we're matching non-exhaustively now.
      @some_proc = @none_proc = nil

      # Run the match block inside the context of this Option.
      # This gives the block access to the `Some` and `None` methods.
      instance_exec(&block)

      check_exhaustive_patterns! if exhaustive
      evaluate_match(block.binding.receiver)
    end

    # "Loose" match (non-exhaustive)
    def lmatch(&block)
      match(exhaustive: false, &block)
    end

    protected

    attr_reader :value

    def initialize(value = nil); end

    private

    # For use inside a match block
    def Some(&block) # rubocop:disable Naming/MethodName
      raise '`Some` already specified!' unless @some_proc.nil?

      @some_proc = block
    end

    # For use inside a match block
    def None(&block) # rubocop:disable Naming/MethodName
      raise '`None` already specified!' unless @none_proc.nil?

      @none_proc = block
    end

    def check_exhaustive_patterns!
      missing_variants = []
      missing_variants << '`Some`' if @some_proc.nil?
      missing_variants << '`None`' if @none_proc.nil?

      return if missing_variants.empty?

      missing_variants = missing_variants.join(' and ')
      error_message = "Non-exhaustive patterns: #{missing_variants} not covered"

      raise error_message
    end
  end

  # An error that is raised when a None value is unwrapped
  class UnwrapError < StandardError
    DEFAULT_MESSAGE = 'Called `Option#unwrap` on a `None` value'

    def initialize(message = DEFAULT_MESSAGE)
      super(message)
    end
  end

  # The variant of Option expressing the presence of some data
  class Some < Option
    # Re-expose `new` so users can instantiate this Class (but not Option)
    public_class_method :new

    def initialize(value)
      @value = value
      super value
    end

    def some?
      true
    end

    def none?
      false
    end

    def unwrap
      @value
    end

    def expect(_message)
      @value
    end

    def unwrap_or(_default)
      @value
    end

    def unwrap_or_else
      raise ArgumentError, 'no block given' unless block_given?

      @value
    end

    def map
      raise ArgumentError, 'no block given' unless block_given?

      Option.some(yield @value)
    end

    def map_or(_default)
      raise ArgumentError, 'no block given' unless block_given?

      yield @value
    end

    def map_or_else(_default_proc, map_proc)
      map_proc.call(@value)
    end

    def and(other_option)
      other_option
    end

    def and_then
      raise ArgumentError, 'no block given' unless block_given?

      yield @value
    end

    def filter
      raise ArgumentError, 'no block given' unless block_given?

      if yield(@value)
        self
      else
        Option.none
      end
    end

    def or(_other_option)
      self
    end

    def or_else
      raise ArgumentError, 'no block given' unless block_given?

      self
    end

    def xor(other_option)
      if other_option.some?
        Option.none
      else
        self
      end
    end

    def contains?(value)
      @value == value
    end

    def flatten
      @value
    end

    def zip(other_option)
      if other_option.some?
        # TODO: won't work because value is protected? or will it?
        Option.some([@value, other_option.value])
      else
        Option.none
      end
    end

    def to_s
      "Some(#{@value})"
    end

    def ==(other)
      if other.some?
        @value == other.value
      else
        false
      end
    end

    # Evaluates the appropriae match arm in the original contextt
    def evaluate_match(context)
      context.instance_exec(@value, &@some_proc) unless @some_proc.nil?
    end
  end

  # The variant of Option expressing the absence of data
  class None < Option
    # Re-expose `new` so users can instantiate this Class (but not Option)
    public_class_method :new

    def some?
      false
    end

    def none?
      true
    end

    def unwrap
      raise UnwrapError
    end

    def expect(message)
      raise UnwrapError, message
    end

    def unwrap_or(default)
      default
    end

    def unwrap_or_else
      raise ArgumentError, 'no block given' unless block_given?

      yield
    end

    def map
      raise ArgumentError, 'no block given' unless block_given?

      self
    end

    def map_or(default)
      raise ArgumentError, 'no block given' unless block_given?

      default
    end

    def map_or_else(default_proc, _map_proc)
      default_proc.call
    end

    def and(_other_option)
      self
    end

    def and_then
      raise ArgumentError, 'no block given' unless block_given?

      self
    end

    def filter
      raise ArgumentError, 'no block given' unless block_given?

      Option.none
    end

    def or(other_option)
      other_option
    end

    def or_else
      raise ArgumentError, 'no block given' unless block_given?

      yield
    end

    def xor(other_option)
      if other_option.some?
        other_option
      else
        self
      end
    end

    def contains?(_value)
      false
    end

    def flatten
      self
    end

    def zip(_other_option)
      Option.none
    end

    def to_s
      'None'
    end

    def ==(other)
      other.none?
    end

    # Evaluates the appropriae match arm in the original contextt
    def evaluate_match(context)
      context.instance_exec(&@none_proc) unless @none_proc.nil?
    end
  end
end
