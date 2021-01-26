# frozen_string_literal: true

module OptionRb
  # A class representing an optional value
  class Option # rubocop:disable Metrics/ClassLength
    def initialize(variant, value = nil)
      @variant = variant
      @value = value
    end

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
      new(:some, value)
    end

    def self.none
      new(:none)
    end

    def some?
      @variant == :some
    end

    def none?
      @variant == :none
    end

    def unwrap
      return @value if some?

      raise UnwrapError
    end

    def expect(message)
      return @value if some?

      raise UnwrapError, message
    end

    def unwrap_or(default)
      if some?
        @value
      else
        default
      end
    end

    def unwrap_or_else
      raise ArgumentError, 'no block given' unless block_given?

      if some?
        @value
      else
        yield
      end
    end

    def map
      raise ArgumentError, 'no block given' unless block_given?

      if some?
        Option.some(yield @value)
      else
        self
      end
    end

    def map_or(default)
      raise ArgumentError, 'no block given' unless block_given?

      if some?
        yield @value
      else
        default
      end
    end

    def map_or_else(default_proc, map_proc)
      if some?
        map_proc.call(@value)
      else
        default_proc.call
      end
    end

    def and(other_option)
      if some?
        other_option
      else
        self
      end
    end

    def and_then
      raise ArgumentError, 'no block given' unless block_given?

      if some?
        yield @value
      else
        self
      end
    end

    def filter
      raise ArgumentError, 'no block given' unless block_given?

      if some? && yield(@value)
        self
      else
        Option.none
      end
    end

    def or(other_option)
      if some?
        self
      else
        other_option
      end
    end

    def or_else
      raise ArgumentError, 'no block given' unless block_given?

      if some?
        self
      else
        yield
      end
    end

    def xor(other_option)
      if some?
        if other_option.some?
          Option.none
        else
          self
        end
      elsif other_option.some?
        other_option
      else
        self # None
      end
    end

    def contains?(value)
      if some?
        @value == value
      else
        false
      end
    end

    def flatten
      if some?
        @value
      else
        self
      end
    end

    def get_or_insert(new_value)
      get_or_insert_with { new_value }
    end

    def get_or_insert_with # rubocop:disable Naming/AccessorMethodName
      return ArgumentError, 'no block given' unless block_given?

      if some?
        @value
      else
        @variant = :some
        @value = yield
      end
    end

    # iter
    def to_enum
      # Create a new object so that the Enumerator doesn't touch the original
      #
      # NOTE: `dup` does a shallow copy so if the user of the Enumerator modifies
      # the internal value during iteration, it will affect the original Option.
      # For example:
      #
      # ```ruby
      # > option = Some('hi')
      # > enumerator = option.to_enum
      # > enumerator.first.map(&:upcase!)
      # ```
      #
      # The final expression will return a Some('HI') which will be a different
      # object than the original `option`. However, the original `option` will
      # now also be `Some('HI')`.
      option = dup

      Enumerator.new do |yielder|
        loop do
          yielder << option.take
        end
      end
    end

    def replace(new_value)
      old = dup
      @variant = :some
      @value = new_value

      old
    end

    def take
      old = dup
      @variant = :none
      @value = nil

      old
    end

    def zip(other_option)
      if some? && other_option.some?
        Option.some([@value, other_option.value])
      else
        Option.none
      end
    end

    # Kinda implements the `Debug` trait
    def to_s
      if some?
        "Some(#{@value})"
      else
        'None'
      end
    end

    # Converts an Option back into "Ruby-land" (where `None` is `nil`)
    # TODO: downcast?
    def to_ruby
      @value
    end

    def ==(other)
      if some?
        if other.some?
          @value == other.value
        else
          false
        end
      else
        other.none?
      end
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

    private

    def Some(&block) # rubocop:disable Naming/MethodName
      raise '`Some` already specified!' unless @some_proc.nil?

      @some_proc = block
    end

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

    # Evaluates the appropriae match arm in the original contextt
    def evaluate_match(context)
      if some? && !@some_proc.nil?
        context.instance_exec(@value, &@some_proc)
      elsif !@none_proc.nil?
        context.instance_exec(&@none_proc)
      end
    end
  end

  # An error that is raised when a None value is unwrapped
  class UnwrapError < StandardError
    DEFAULT_MESSAGE = 'Called `Option#unwrap` on a `None` value'

    def initialize(message = DEFAULT_MESSAGE)
      super(message)
    end
  end
end
